extends Node3D
class_name PlanetBody
## Optimized spherical planet: multi-LOD surface, cheap atmosphere, pad streaming.
## Targets: RTX 1060 3GB (LOW) → 3060 (HIGH) → 4060 (ULTRA).

const _Cache = preload("res://scripts/world/PlanetMeshCache.gd")
const _ATMO_SHADER = preload("res://shaders/planet_atmosphere.gdshader")
const _SURFACE_SHADER = preload("res://shaders/planet_surface.gdshader")
const _ATMO_INNER_SHADER = preload("res://shaders/planet_atmosphere_inner.gdshader")
const _BaseBuilder = preload("res://scripts/world/BaseBuilder.gd")
const _SurfaceDetail = preload("res://scripts/world/SurfaceDetail.gd")
const _TerrainEdit = preload("res://scripts/world/PlanetTerrainEdit.gd")

@export var planet_name: String = "Aexion-III"
@export var radius: float = 1200.0
@export var atmosphere_height: float = 280.0
@export var gravity: float = 9.2
@export var surface_color: Color = Color(0.12, 0.22, 0.16)
@export var atmosphere_color: Color = Color(0.35, 0.55, 0.95, 0.12)
@export var faction_base: String = "Cybernex"
@export var has_base: bool = true
## Distances are from planet center. LOD switches use camera/ship position.
@export var lod_near: float = 0.0  # filled in _ready from radius
@export var lod_mid: float = 0.0
@export var lod_far: float = 0.0
@export var lod_impostor: float = 0.0
@export var atmo_max_dist: float = 0.0
@export var pad_stream_dist: float = 0.0

var _mesh: MeshInstance3D
var _atmo: MeshInstance3D
var _impostor: MeshInstance3D
var _body: StaticBody3D
var _pads_root: Node3D
var _pads: Array[Node3D] = []
var _surface_mat: StandardMaterial3D
var _surface_shader_mat: ShaderMaterial
var _impostor_mat: ShaderMaterial
var _atmo_mat: ShaderMaterial
var _atmo_inner: MeshInstance3D
var _atmo_inner_mat: ShaderMaterial
var _sun_dir: Vector3 = Vector3(0.55, 0.75, 0.35)
var _current_lod: int = -1  # 0 near, 1 mid, 2 far, 3 impostor
var _pads_built: bool = false
var _glb_loaded: bool = false
var _observer: Node3D = null
var _update_accum: float = 0.0
var _lod_hold: float = 0.0
var _pending_lod: int = -1
var _segs_near: int = 64
var _segs_mid: int = 32
var _segs_far: int = 16
var _collision_enabled: bool = true
var _surface_detail: Node3D = null
var _pad_build_stage: int = 0
var _pad_build_pending: bool = false
var _terrain_edit: Node3D = null

func _ready() -> void:
	add_to_group("planets")
	_configure_from_quality()
	_build_shell()
	# Pads deferred until approach
	set_process(true)
	# React to quality changes
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and gq.has_signal("tier_changed"):
		gq.tier_changed.connect(_on_quality_changed)

func _configure_from_quality() -> void:
	var gq := get_node_or_null("/root/GraphicsQuality")
	var base_segs := 64
	var bias := 1.0
	if gq:
		base_segs = int(gq.planet_segments)
		bias = float(gq.prop_lod_bias)
	_segs_near = base_segs
	_segs_mid = max(12, int(base_segs * 0.5 / bias))
	_segs_far = max(8, int(base_segs * 0.25 / bias))
	# Distance bands scale with planet size
	lod_near = radius * 2.2 * bias
	lod_mid = radius * 5.0 * bias
	lod_far = radius * 10.0 * bias
	lod_impostor = radius * 18.0 * bias
	atmo_max_dist = (radius + atmosphere_height) * 4.5 * bias
	pad_stream_dist = radius + 400.0 * bias

func _on_quality_changed(_t: int) -> void:
	_configure_from_quality()
	_current_lod = -1  # force rebuild LOD mesh
	_apply_atmo_uniforms()
	_apply_lod(0)  # will re-evaluate next frame via process

func _build_shell() -> void:
	# Surface mesh (LOD swapped)
	_mesh = MeshInstance3D.new()
	_mesh.name = "Surface"
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# Land/ocean procedural albedo (R4) — far & mid sphere readable
	var smat := ShaderMaterial.new()
	smat.shader = _SURFACE_SHADER
	_apply_surface_uniforms(smat)
	_mesh.material_override = smat
	_surface_shader_mat = smat
	# Always have a mesh RID (avoid Parameter m is null before first LOD)
	_mesh.mesh = _Cache.sphere(radius, maxi(8, _segs_far))
	add_child(_mesh)

	# Atmosphere outer shell — fresnel limb shader (space view)
	_atmo = MeshInstance3D.new()
	_atmo.name = "Atmosphere"
	_atmo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_atmo.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_atmo.mesh = _Cache.sphere(radius + atmosphere_height, max(12, _segs_far + 4))
	_atmo_mat = ShaderMaterial.new()
	_atmo_mat.shader = _ATMO_SHADER
	_apply_atmo_uniforms()
	_atmo.material_override = _atmo_mat
	add_child(_atmo)
	# Inner haze (enabled only inside atmosphere)
	_atmo_inner = MeshInstance3D.new()
	_atmo_inner.name = "AtmosphereInner"
	_atmo_inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_atmo_inner.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_atmo_inner.mesh = _Cache.sphere(radius + atmosphere_height * 0.92, max(10, _segs_far))
	_atmo_inner_mat = ShaderMaterial.new()
	_atmo_inner_mat.shader = _ATMO_INNER_SHADER
	_atmo_inner_mat.set_shader_parameter("haze_color", atmosphere_color)
	_atmo_inner_mat.set_shader_parameter("sun_direction", _sun_dir)
	_atmo_inner.material_override = _atmo_inner_mat
	_atmo_inner.visible = false
	add_child(_atmo_inner)

	# Far impostor — single low poly unshaded billboard-ish sphere (very cheap)
	_impostor = MeshInstance3D.new()
	_impostor.name = "Impostor"
	_impostor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_impostor.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_impostor.mesh = _Cache.sphere(radius * 1.02, 8)
	_impostor_mat = ShaderMaterial.new()
	_impostor_mat.shader = _SURFACE_SHADER
	_apply_surface_uniforms(_impostor_mat)
	_impostor_mat.set_shader_parameter("emission_strength", 0.18)
	_impostor.material_override = _impostor_mat
	_impostor.visible = false
	add_child(_impostor)

	# Collision always simple SphereShape (cheap, independent of visual LOD)
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	var col := CollisionShape3D.new()
	var ss := SphereShape3D.new()
	ss.radius = radius
	col.shape = ss
	_body.add_child(col)
	add_child(_body)

	_pads_root = Node3D.new()
	_pads_root.name = "Pads"
	add_child(_pads_root)

	_surface_detail = Node3D.new()
	_surface_detail.set_script(_SurfaceDetail)
	_surface_detail.name = "SurfaceDetail"
	add_child(_surface_detail)
	if _surface_detail.has_method("setup"):
		_surface_detail.setup(self, radius, surface_color, planet_name.hash() % 10000)
	call_deferred("_ensure_surface_fauna")
	call_deferred("_ensure_surface_flora")
	call_deferred("_ensure_surface_water")
	call_deferred("_ensure_cave_mouths")
	call_deferred("_ensure_cave_interior")
	call_deferred("_ensure_landscape_features")

	_terrain_edit = Node3D.new()
	_terrain_edit.set_script(_TerrainEdit)
	_terrain_edit.name = "TerrainEdit"
	add_child(_terrain_edit)
	if _terrain_edit.has_method("setup"):
		_terrain_edit.setup(self, radius, surface_color, planet_name.hash() % 10000, planet_name)


	_apply_lod_visual(1)  # start mid until first observer update

func set_observer(node: Node3D) -> void:
	var w = get_node_or_null("SurfaceWater")
	if w and w.has_method("set_observer"):
		w.set_observer(node)
	var cv = get_node_or_null("CaveMouthField")
	if cv and cv.has_method("set_observer"):
		cv.set_observer(node)
	var ci = get_node_or_null("CaveInterior")
	if ci and ci.has_method("set_observer"):
		ci.set_observer(node)
	var lf = get_node_or_null("LandscapeFeatures")
	if lf and lf.has_method("set_observer"):
		lf.set_observer(node)
	var _fl := get_node_or_null("SurfaceFlora")
	if _fl and _fl.has_method("set_observer"):
		_fl.set_observer(node)
	_observer = node
	if _surface_detail and _surface_detail.has_method("set_observer"):
		_surface_detail.set_observer(node)
	if _terrain_edit and _terrain_edit.has_method("set_observer"):
		_terrain_edit.set_observer(node)

func _process(delta: float) -> void:
	_update_accum += delta
	# Throttle: slower when far (impostor) — saves CPU with many planets
	var tick := 0.12
	if _current_lod >= 3:
		tick = 0.35
	elif _current_lod == 2:
		tick = 0.2
	var gq0 := get_node_or_null("/root/GraphicsQuality")
	if gq0 and int(gq0.tier) == 0:
		tick *= 1.35
	if _update_accum < tick:
		return
	_update_accum = 0.0
	var obs := _resolve_observer()
	if obs == null:
		return
	var dist: float = global_position.distance_to(obs.global_position)
	var lod := _lod_for_distance(dist)
	# Hysteresis: require stable LOD for ~0.5s before swapping mesh (stops sphere "morph dance")
	if lod != _current_lod:
		if lod != _pending_lod:
			_pending_lod = lod
			_lod_hold = 0.0
		else:
			_lod_hold += 0.12  # matches process tick
			if _lod_hold >= 0.48:
				_apply_lod_visual(lod)
				_pending_lod = -1
				_lod_hold = 0.0
	else:
		_pending_lod = -1
		_lod_hold = 0.0
	# Atmosphere LOD + shader params
	_update_atmosphere(dist, lod, obs)
	# Pad streaming
	_update_pads(dist)
	_sync_surface_visibility(dist)
	# Disable collision when very far (saves broadphase) — re-enable near
	var need_col := dist < radius + 800.0
	if need_col != _collision_enabled:
		_collision_enabled = need_col
		_body.set_collision_layer_value(1, need_col)

func _resolve_observer() -> Node3D:
	if _observer != null:
		if is_instance_valid(_observer):
			return _observer
		_observer = null
	var cam := get_viewport().get_camera_3d()
	if cam:
		return cam
	return null

func _lod_for_distance(dist: float) -> int:
	if dist < lod_near:
		return 0
	if dist < lod_mid:
		return 1
	if dist < lod_far:
		return 2
	return 3

func _apply_lod_visual(lod: int) -> void:
	_current_lod = lod
	if lod >= 3:
		_mesh.visible = false
		_impostor.visible = true
		if _atmo:
			_atmo.visible = false
		if _atmo_inner:
			_atmo_inner.visible = false
		return
	_impostor.visible = false
	_mesh.visible = true
	var segs := _segs_mid
	match lod:
		0:
			segs = _segs_near
		1:
			segs = _segs_mid
		2:
			segs = _segs_far
	_mesh.mesh = _Cache.sphere(radius, segs)
	# Surface land/ocean via ShaderMaterial (R4) — no per-LOD mat swap

func _apply_lod(lod: int) -> void:
	_apply_lod_visual(lod)

func _update_pads(dist: float) -> void:
	if not has_base:
		return
	var gq := get_node_or_null("/root/GraphicsQuality")
	var stream_d := pad_stream_dist
	var glb_d := radius + 180.0
	var base_d := radius + 220.0
	if gq:
		match int(gq.tier):
			0:
				stream_d = radius + 220.0
				glb_d = radius + 90.0
				base_d = radius + 110.0
			1:
				stream_d = radius + 320.0
				glb_d = radius + 140.0
				base_d = radius + 170.0
	if dist < stream_d:
		# Stagger pad build across frames — full 3-pad+density in one frame freezes 10–15s
		if not _pads_built:
			_pad_build_pending = true
			_step_pad_build()
		elif _pad_build_pending:
			_step_pad_build()
		if _pads_root:
			_pads_root.visible = true
		if dist < glb_d and not _glb_loaded and _pads_built:
			call_deferred("_load_glb_pads")
		if dist < base_d and _pads_built:
			# bases once; BaseBuilder is heavy — defer
			call_deferred("_stream_bases")
	else:
		if _pads_root:
			_pads_root.visible = false

func _step_pad_build() -> void:
	## One pad (or density) per call — spreads hitch.
	match _pad_build_stage:
		0:
			if _pads_root == null:
				_pads_root = Node3D.new()
				_pads_root.name = "Pads"
				add_child(_pads_root)
			_spawn_pad("Pad_North", Vector3.UP)
			_pad_build_stage = 1
		1:
			_spawn_pad("Pad_Eq", Vector3(1, 0.15, 0).normalized())
			_pad_build_stage = 2
		2:
			_spawn_pad("Pad_Far", Vector3(-0.7, 0.2, 0.7).normalized())
			_pad_build_stage = 3
		3:
			_spawn_pad_density()
			_pad_build_stage = 4
			_pads_built = true
			_pad_build_pending = false
			print("[PlanetBody] pads staggered build complete")
		_:
			_pads_built = true
			_pad_build_pending = false


func _build_pads() -> void:
	if _pads_root == null:
		_pads_root = Node3D.new()
		_pads_root.name = "Pads"
		add_child(_pads_root)
	if _pads_built and not _pads.is_empty():
		return
	_pads_built = true
	_spawn_pad("Pad_North", Vector3.UP)
	_spawn_pad("Pad_Eq", Vector3(1, 0.15, 0).normalized())
	_spawn_pad("Pad_Far", Vector3(-0.7, 0.2, 0.7).normalized())
	_spawn_pad_density()


func ensure_pad_bases() -> void:
	## Force pad plates + claim controllers even when the ship is still
	## outside LOW-tier stream distance (headless / orbit spawn).
	if not has_base:
		return
	if not _pads_built or _pads.is_empty():
		_build_pads()
	_stream_bases()


func _spawn_pad(pad_name: String, dir: Vector3) -> void:
	dir = dir.normalized()
	var pad_root := Node3D.new()
	pad_root.name = pad_name
	_pads_root.add_child(pad_root)
	var y := dir
	var x := y.cross(Vector3(0, 0, 1))
	if x.length() < 0.05:
		x = y.cross(Vector3(1, 0, 0))
	x = x.normalized()
	var z := x.cross(y).normalized()
	pad_root.transform = Transform3D(Basis(x, y, z), dir * (radius + 2.0))

	var plate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(28, 1.2, 28)
	plate.mesh = box
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pmat := StandardMaterial3D.new()
	pmat.metallic = 0.55
	pmat.roughness = 0.4
	pmat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	pmat.emission_enabled = true
	if faction_base == "gROT":
		pmat.albedo_color = Color(0.2, 0.05, 0.08)
		pmat.emission = Color(0.9, 0.15, 0.3)
	else:
		pmat.albedo_color = Color(0.06, 0.1, 0.14)
		pmat.emission = Color(0.2, 0.8, 1.0)
	pmat.emission_energy_multiplier = 1.2
	plate.material_override = pmat
	pad_root.add_child(plate)

	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(28, 1.2, 28)
	cs.shape = bs
	sb.add_child(cs)
	pad_root.add_child(sb)

	pad_root.set_meta("landing_pad", true)
	pad_root.set_meta("planet", self)
	pad_root.set_meta("pad_up", dir)
	_pads.append(pad_root)

func _load_glb_pads() -> void:
	_glb_loaded = true
	if DisplayServer.get_name() == "headless":
		return
	var ap = load("res://scripts/assets/AssetPaths.gd")
	if ap == null:
		return
	var rel := "environments/landing_pad/landing_pad_cybernex_lod1.glb"
	if faction_base == "gROT":
		rel = "environments/landing_pad/landing_pad_grot_lod1.glb"
	var path: String = ap.resolve(rel)
	if path == "" or not FileAccess.file_exists(path):
		return
	# Only decorate first pad with full GLB to save draw calls
	if _pads.is_empty():
		return
	var pad_root: Node3D = _pads[0]
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return
	var root := doc.generate_scene(state)
	if root == null:
		return
	pad_root.add_child(root)
	root.scale = Vector3.ONE * 3.5
	root.position = Vector3(0, 0.8, 0)
	# Disable shadows on imported meshes
	_disable_shadows_recursive(root)

func _disable_shadows_recursive(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_disable_shadows_recursive(c)


func _apply_atmo_uniforms() -> void:
	if _atmo_mat == null:
		return
	var gq := get_node_or_null("/root/GraphicsQuality")
	var rim := 3.8
	var dens := 0.95
	var intens := 1.35
	if gq:
		match int(gq.tier):
			0:  # LOW — thinner, cheaper look
				rim = 4.5
				dens = 0.75
				intens = 1.1
			1:
				rim = 3.8
				dens = 0.95
				intens = 1.35
			2:
				rim = 3.2
				dens = 1.05
				intens = 1.5
			3:
				rim = 2.8
				dens = 1.15
				intens = 1.65
	_atmo_mat.set_shader_parameter("atmosphere_color", atmosphere_color)
	_atmo_mat.set_shader_parameter("rim_power", rim)
	_atmo_mat.set_shader_parameter("density", dens)
	_atmo_mat.set_shader_parameter("intensity", intens)
	_atmo_mat.set_shader_parameter("sun_direction", _sun_dir)
	if _atmo_inner_mat:
		_atmo_inner_mat.set_shader_parameter("haze_color", atmosphere_color)
		_atmo_inner_mat.set_shader_parameter("sun_direction", _sun_dir)

func set_sun_direction(dir: Vector3) -> void:
	if _surface_shader_mat:
		_surface_shader_mat.set_shader_parameter("sun_direction", dir)
	if _impostor_mat:
		_impostor_mat.set_shader_parameter("sun_direction", dir)
	_sun_dir = dir.normalized()
	_apply_atmo_uniforms()

func _update_atmosphere(dist: float, lod: int, obs: Node3D) -> void:
	if _atmo == null:
		return
	var show_outer := dist < atmo_max_dist and lod < 3
	_atmo.visible = show_outer
	var alt: float = dist - radius
	# Horizon boost as we approach (limb brightens)
	if show_outer and _atmo_mat:
		var approach := 0.0
		if alt < atmosphere_height * 3.0:
			approach = clamp(1.0 - alt / (atmosphere_height * 3.0), 0.0, 1.0)
		_atmo_mat.set_shader_parameter("horizon_boost", approach * 0.9)
		# Soft distance fade of overall intensity
		var fade: float = clamp(1.0 - dist / atmo_max_dist, 0.0, 1.0)
		var base_i := 1.35
		var gq := get_node_or_null("/root/GraphicsQuality")
		if gq:
			match int(gq.tier):
				0: base_i = 1.1
				2: base_i = 1.5
				3: base_i = 1.65
		_atmo_mat.set_shader_parameter("intensity", base_i * (0.4 + 0.6 * fade))
	# Inner haze when inside / skimming atmosphere
	if _atmo_inner:
		var inside := alt < atmosphere_height * 1.05 and lod <= 1
		_atmo_inner.visible = inside
		if inside and _atmo_inner_mat:
			var depth: float = clamp(1.0 - max(alt, 0.0) / max(atmosphere_height, 1.0), 0.0, 1.0)
			_atmo_inner_mat.set_shader_parameter("intensity", 0.5 + depth * 0.9)
			_atmo_inner_mat.set_shader_parameter("density", 0.45 + depth * 0.5)

func _stream_bases() -> void:
	if not has_base or _pads.is_empty():
		return
	var n := mini(2, _pads.size())
	for i in n:
		_BaseBuilder.build_on_pad(_pads[i], faction_base)

func altitude_of(global_pos: Vector3) -> float:
	return global_pos.distance_to(global_position) - radius

func gravity_at(global_pos: Vector3) -> Vector3:
	var to_c: Vector3 = global_position - global_pos
	var dist: float = to_c.length()
	if dist < 0.001:
		return Vector3.ZERO
	var alt: float = dist - radius
	if alt > atmosphere_height * 1.8:
		return Vector3.ZERO
	var strength: float = gravity
	if alt > 0.0:
		var t: float = clamp(1.0 - alt / (atmosphere_height * 1.8), 0.0, 1.0)
		strength *= t * t
	return to_c.normalized() * strength

func nearest_pad(global_pos: Vector3) -> Node3D:
	# Ensure pads exist if player is trying to land nearby
	if has_base and not _pads_built and altitude_of(global_pos) < 500.0:
		_build_pads()
	var best: Node3D = null
	var best_d := INF
	for p in _pads:
		var d: float = p.global_position.distance_to(global_pos)
		if d < best_d:
			best_d = d
			best = p
	return best

func is_near_surface(global_pos: Vector3, margin: float = 80.0) -> bool:
	return altitude_of(global_pos) < margin

func current_lod_name() -> String:
	match _current_lod:
		0: return "NEAR"
		1: return "MID"
		2: return "FAR"
		3: return "IMPOSTOR"
	return "?"
	

func _spawn_pad_density() -> void:
	_ensure_surface_flora()
	_ensure_surface_fauna()
	if _pads_root == null:
		return
	if _pads_root.has_node("PadDensityCluster"):
		return
	var d := Node3D.new()
	d.set_script(load("res://scripts/world/PadDensity.gd"))
	d.name = "PadDensityCluster"
	_pads_root.add_child(d)
	var fac := "Cybernex"
	if "faction_base" in self:
		fac = str(faction_base)
	var dens_n := 14
	var life_n := 6
	var city_n := 10
	var gqp := get_node_or_null("/root/GraphicsQuality")
	if gqp:
		match int(gqp.tier):
			0:
				dens_n = 5
				life_n = 2
				city_n = 4
			1:
				dens_n = 9
				life_n = 4
				city_n = 7
			2:
				dens_n = 12
				life_n = 5
				city_n = 9
	if d.has_method("build"):
		d.build(fac, 22.0, dens_n)
	if not _pads_root.has_node("PadAmbientLife"):
		var life := Node3D.new()
		life.set_script(load("res://scripts/world/PadAmbientLife.gd"))
		life.name = "PadAmbientLife"
		_pads_root.add_child(life)
		if life.has_method("build"):
			life.build(life_n, fac)
	if not _pads_root.has_node("CityNightLights"):
		var city := Node3D.new()
		var cscr: Script = load("res://scripts/world/CityNightLights.gd") as Script
		city.set_script(cscr)
		city.name = "CityNightLights"
		_pads_root.add_child(city)
		if city.has_method("build"):
			city.call("build", fac, 26.0, city_n)



func _ensure_surface_fauna() -> void:
	if has_node("SurfaceFauna"):
		return
	var f := Node3D.new()
	var scr: Script = load("res://scripts/world/SurfaceFauna.gd") as Script
	f.set_script(scr)
	f.name = "SurfaceFauna"
	add_child(f)
	var pid: String = str(planet_name)
	var atm: float = float(atmosphere_height)
	var seed_i: int = int(absi(pid.hash()) % 10000)
	if f.has_method("setup"):
		f.call("setup", self, radius, atm, pid, seed_i)
	var obs: Node3D = null
	var tree := get_tree()
	if tree:
		var pnode = tree.get_first_node_in_group("player")
		if pnode is Node3D:
			obs = pnode as Node3D
		if obs == null:
			var ships: Array = tree.get_nodes_in_group("ship")
			if ships.size() > 0 and ships[0] is Node3D:
				obs = ships[0] as Node3D
	if obs != null and f.has_method("set_observer"):
		f.call("set_observer", obs)
	print("[PlanetBody] SurfaceFauna ", pid)




func _ensure_surface_water() -> void:
	if has_node("SurfaceWater"):
		return
	var w := Node3D.new()
	var scr: Script = load("res://scripts/world/SurfaceWater.gd") as Script
	w.set_script(scr)
	w.name = "SurfaceWater"
	add_child(w)
	var pid: String = str(planet_name)
	if w.has_method("setup"):
		w.call("setup", self, radius, pid, int(absi(pid.hash()) % 10000))
	var obs: Node3D = null
	if has_method("_resolve_observer"):
		obs = _resolve_observer()
	if obs and w.has_method("set_observer"):
		w.call("set_observer", obs)
	print("[PlanetBody] SurfaceWater ", pid)






func _ensure_landscape_features() -> void:
	if has_node("LandscapeFeatures"):
		return
	var n := Node3D.new()
	var scr: Script = load("res://scripts/world/LandscapeFeatures.gd") as Script
	n.set_script(scr)
	n.name = "LandscapeFeatures"
	add_child(n)
	var pid: String = str(planet_name)
	if n.has_method("setup"):
		n.call("setup", self, radius, pid, int(absi(pid.hash()) % 10000) + 3)
	var obs: Node3D = null
	if has_method("_resolve_observer"):
		obs = _resolve_observer()
	if obs and n.has_method("set_observer"):
		n.call("set_observer", obs)
	print("[PlanetBody] LandscapeFeatures ", pid)


func _ensure_cave_interior() -> void:
	if has_node("CaveInterior"):
		return
	var c := Node3D.new()
	var scr: Script = load("res://scripts/world/CaveInterior.gd") as Script
	c.set_script(scr)
	c.name = "CaveInterior"
	add_child(c)
	var pid: String = str(planet_name)
	if c.has_method("setup"):
		c.call("setup", self, radius, pid, int(absi(pid.hash()) % 10000) + 9)
	var obs: Node3D = null
	if has_method("_resolve_observer"):
		obs = _resolve_observer()
	if obs and c.has_method("set_observer"):
		c.call("set_observer", obs)
	print("[PlanetBody] CaveInterior ", pid)

func _ensure_cave_mouths() -> void:
	if has_node("CaveMouthField"):
		return
	var c := Node3D.new()
	var scr: Script = load("res://scripts/world/CaveMouthField.gd") as Script
	c.set_script(scr)
	c.name = "CaveMouthField"
	add_child(c)
	var pid: String = str(planet_name)
	if c.has_method("setup"):
		c.call("setup", self, radius, pid, int(absi(pid.hash()) % 10000) + 3)
	var obs: Node3D = null
	if has_method("_resolve_observer"):
		obs = _resolve_observer()
	if obs and c.has_method("set_observer"):
		c.call("set_observer", obs)
	print("[PlanetBody] CaveMouthField ", pid)

func _ensure_surface_flora() -> void:
	if has_node("SurfaceFlora"):
		return
	var fl := Node3D.new()
	fl.set_script(load("res://scripts/world/SurfaceFlora.gd"))
	fl.name = "SurfaceFlora"
	add_child(fl)
	var rad := 1200.0
	if "radius" in self:
		rad = float(radius)
	if fl.has_method("setup"):
		fl.setup(self, rad, int(abs(hash(name)) % 10000))
	if fl.has_method("set_observer"):
		var obs = null
		if has_method("_resolve_observer"):
			obs = _resolve_observer()
		elif "_observer" in self:
			obs = _observer
		if obs:
			fl.set_observer(obs)
	print("[PlanetBody] SurfaceFlora")



func _apply_surface_uniforms(mat: ShaderMaterial) -> void:
	if mat == null:
		return
	mat.set_shader_parameter("land_color", surface_color)
	var ocean := Color(0.05, 0.18, 0.38)
	if str(planet_name) == "ROT-Hive":
		ocean = Color(0.25, 0.05, 0.12)
	elif str(planet_name) == "Shard-Moon":
		ocean = Color(0.12, 0.14, 0.18)
		mat.set_shader_parameter("sea_threshold", -0.15)
		mat.set_shader_parameter("ice_lat", 0.55)
	mat.set_shader_parameter("ocean_color", ocean)
	mat.set_shader_parameter("shore_color", Color(0.42, 0.38, 0.22))
	mat.set_shader_parameter("seed", float(absi(str(planet_name).hash()) % 97))
	mat.set_shader_parameter("sun_direction", _sun_dir)
	mat.set_shader_parameter("emission_strength", 0.06)
	mat.set_shader_parameter("city_intensity", 1.4)
	mat.set_shader_parameter("city_density", 0.55)
	if str(planet_name) == "Shard-Moon":
		mat.set_shader_parameter("city_intensity", 0.35)
	elif str(planet_name) == "ROT-Hive":
		mat.set_shader_parameter("city_light_color", Color(1.0, 0.35, 0.5))


func relief_height_at(world_pos: Vector3) -> float:
	var _R = load("res://scripts/world/PlanetRelief.gd")
	if _R == null:
		return 0.0
	var prof: Dictionary = _R.profile_for_planet(str(planet_name))
	var dir: Vector3 = (world_pos - global_position).normalized()
	var east: Vector3 = dir.cross(Vector3.UP)
	if east.length_squared() < 1e-6:
		east = dir.cross(Vector3.RIGHT)
	east = east.normalized()
	var north: Vector3 = east.cross(dir).normalized()
	var to: Vector3 = world_pos - global_position
	return float(_R.height_at(to.dot(east), to.dot(north), int(absi(str(planet_name).hash()) % 10000), prof))



func _sync_surface_visibility(dist: float) -> void:
	## Park expensive surface streams when not near planet.
	var near_surf := dist < radius + 160.0
	var mid_surf := dist < radius + 280.0
	for nm in ["SurfaceDetail", "SurfaceFlora", "SurfaceFauna", "SurfaceWater", "CaveMouthField", "LandscapeFeatures", "CaveInterior"]:
		var n := get_node_or_null(nm)
		if n == null:
			continue
		var want := near_surf
		if nm in ["SurfaceFlora", "SurfaceFauna", "CaveMouthField", "LandscapeFeatures"]:
			want = near_surf
		elif nm == "SurfaceWater":
			want = mid_surf
		elif nm == "SurfaceDetail":
			want = mid_surf
		n.visible = want
		n.set_process(want)
