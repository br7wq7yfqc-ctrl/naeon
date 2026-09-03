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
const _Relief = preload("res://scripts/world/PlanetRelief.gd")
const _P0 = preload("res://scripts/world/P0Slice.gd")
const _MeshSafe = preload("res://scripts/world/MeshSafe.gd")
const _Filler = preload("res://scripts/world/FillerProp.gd")
const _FlightModel = preload("res://scripts/ship/ShipFlightModel.gd")

@export var planet_name: String = "Aexion-III"
@export var radius: float = 1200.0
@export var atmosphere_height: float = 280.0
## Thin OS-B shell for density / fog / ceiling. 0 = derive from height*1.6.
@export var atmosphere_envelope: float = 0.0
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
var _far_shell_hidden: bool = false
var _pad_build_stage: int = 0
var _pad_build_pending: bool = false
var _bases_built: bool = false
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
	_segs_far = max(12, int(base_segs * 0.25 / bias))
	# Distance bands scale with planet size. OS-C: 5–15 km AGL stays on the
	# far mesh + limb (not the 8-seg impostor). Near/mid unchanged for 770 m.
	lod_near = radius * 2.2 * bias
	lod_mid = radius * 5.0 * bias
	lod_far = (radius + 16000.0) * bias
	lod_impostor = (radius + 28000.0) * bias
	atmo_max_dist = (radius + 18000.0) * bias
	# OS-D: unnamed plates + sparse scatter must stream from ~2 km AGL.
	# OS-G: the one outpost cluster must already be up at the 8 km spawn.
	# Quality only delays GLB / bases, not the plate / mast silhouette.
	if _P0.OS_G_OUTPOST:
		pad_stream_dist = radius + 9200.0
	else:
		pad_stream_dist = radius + 2400.0

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
	# Dummy renderer cannot RID a 1400 m SphereMesh — BoxMesh keeps the
	# ShaderMaterial (seed uniforms) without mesh_get_surface_count spam.
	_MeshSafe.assign(_mesh, _Cache.sphere(radius, maxi(8, _segs_far)), Vector3(2, 2, 2))
	add_child(_mesh)

	# Atmosphere outer shell — fresnel limb shader (space view)
	_atmo = MeshInstance3D.new()
	_atmo.name = "Atmosphere"
	_atmo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_atmo.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_MeshSafe.assign(_atmo, _Cache.sphere(radius + atmosphere_height, max(12, _segs_far + 4)), Vector3(2.2, 2.2, 2.2))
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
	_MeshSafe.assign(_atmo_inner, _Cache.sphere(radius + atmosphere_height * 0.92, max(10, _segs_far)), Vector3(2.1, 2.1, 2.1))
	_atmo_inner_mat = ShaderMaterial.new()
	_atmo_inner_mat.shader = _ATMO_INNER_SHADER
	_atmo_inner_mat.set_shader_parameter("haze_color", atmosphere_color)
	_atmo_inner_mat.set_shader_parameter("sun_direction", _sun_dir)
	_atmo_inner.material_override = _atmo_inner_mat
	_atmo_inner.visible = false
	add_child(_atmo_inner)

	# Far impostor — same Relief paint as the far mesh, extra segs so a 15 km
	# disc still reads land/sea instead of an 8-tri ball.
	_impostor = MeshInstance3D.new()
	_impostor.name = "Impostor"
	_impostor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_impostor.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_MeshSafe.assign(_impostor, _Cache.sphere(radius * 1.02, maxi(12, _segs_far)), Vector3(2.05, 2.05, 2.05))
	_impostor_mat = ShaderMaterial.new()
	_impostor_mat.shader = _SURFACE_SHADER
	_apply_surface_uniforms(_impostor_mat)
	_impostor_mat.set_shader_parameter("emission_strength", 0.28)
	_impostor.material_override = _impostor_mat
	_impostor.visible = false
	add_child(_impostor)

	# Collision always simple SphereShape (cheap, independent of visual LOD)
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	var col := CollisionShape3D.new()
	var ss := SphereShape3D.new()
	# Catch-all under canyons/sea. Land collision is SurfaceDetail trimesh.
	ss.radius = maxf(radius - 8.0, radius * 0.99)
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
		_surface_detail.setup(self, radius, surface_color, body_seed())
	if _P0.FILL_STREAMERS:
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
			_terrain_edit.setup(self, radius, surface_color, body_seed(), planet_name)
	else:
		print("[PlanetBody] P0 fill streamers cut on ", planet_name)


	_apply_lod_visual(1)  # start mid until first observer update

func force_surface_collision_at(world_pos: Vector3) -> void:
	## OS-I: warm dirt trimesh under an actor before snap/EVA.
	if _surface_detail != null and is_instance_valid(_surface_detail) and _surface_detail.has_method("force_ground_at"):
		_surface_detail.force_ground_at(world_pos)


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
	var fa := get_node_or_null("SurfaceFauna")
	if fa and fa.has_method("set_observer"):
		fa.set_observer(node)
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

func refresh_approach_lod() -> void:
	## Immediate LOD/limb for the current observer — no 0.48 s hysteresis.
	## Used at OPEN SPACE boot so the 5–15 km start is not a mid-mesh flash.
	var obs := _resolve_observer()
	if obs == null:
		return
	var dist: float = global_position.distance_to(obs.global_position)
	var lod := _lod_for_distance(dist)
	_apply_lod_visual(lod)
	_pending_lod = -1
	_lod_hold = 0.0
	_update_atmosphere(dist, lod, obs)
	_update_pads(dist)
	_sync_surface_visibility(dist)


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
		# Outer limb stays with _update_atmosphere so a 5–15 km approach
		# still reads as a body, not a bare ball.
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
	_MeshSafe.assign(_mesh, _Cache.sphere(radius, segs), Vector3(2, 2, 2))
	# Surface land/ocean via ShaderMaterial (R4) — no per-LOD mat swap
	if _surface_shader_mat:
		# Far disc needs a touch more emission so continents read at 5–15 km.
		_surface_shader_mat.set_shader_parameter("emission_strength", 0.14 if lod == 2 else 0.06)

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
				glb_d = radius + 90.0
				base_d = radius + 110.0
			1:
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
		if dist < base_d and _pads_built and not _bases_built:
			# bases once; BaseBuilder is heavy — defer
			_bases_built = true
			call_deferred("_stream_bases")
	else:
		if _pads_root:
			_pads_root.visible = false
		# Hiding alone leaked every visited planet's pads, GLB, base clusters,
		# contested rings and guards for the rest of the session (rules/25 §2).
		# Unload well past the build radius so orbiting the edge cannot thrash.
		if _pads_built and dist > stream_d * 1.35:
			# P0 one-pad slice: free is dummy m-is-null + hitch. Hide only.
			if not (_P0.ACTIVE and _P0.ONE_PAD):
				_unload_pads()

func _unload_pads() -> void:
	## Free the whole pad subtree and reset every flag the builder reads, so a
	## later approach rebuilds from scratch instead of half-restoring.
	if _pads_root and is_instance_valid(_pads_root):
		for c in _pads_root.get_children():
			_pads_root.remove_child(c)
			c.queue_free()
	_pads.clear()
	_pads_built = false
	_glb_loaded = false
	_bases_built = false
	_pad_build_stage = 0
	_pad_build_pending = false
	if SoftScanCache:
		# The cache hands out pad nodes; it must not keep the freed ones.
		SoftScanCache.invalidate()
	print("[PlanetBody] pads unloaded ", planet_name)


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
			if _P0.ONE_PAD and not _P0.OS_D_FILL:
				_spawn_filler_on_first_pad()
				_spawn_pad_traffic()
				_pad_build_stage = 4
				_pads_built = true
				_pad_build_pending = false
				print("[PlanetBody] P0 one pad + filler")
			elif _P0.OS_D_FILL:
				_spawn_pad("Pad_Approach", _osd_pad_dir(0))
				_pad_build_stage = 2
			else:
				_spawn_pad("Pad_Eq", Vector3(1, 0.15, 0).normalized())
				_pad_build_stage = 2
		2:
			if _P0.OS_D_FILL:
				_spawn_pad("Pad_Flank", _osd_pad_dir(1))
			else:
				_spawn_pad("Pad_Far", Vector3(-0.7, 0.2, 0.7).normalized())
			_pad_build_stage = 3
		3:
			if _P0.OS_D_FILL:
				_spawn_filler_on_first_pad()
				_spawn_worldfill_scatter()
				_spawn_outpost_silhouette()
				_spawn_pad_traffic()
				print("[PlanetBody] OS-D unnamed pads n=", _pads.size())
			else:
				_spawn_pad_density()
				_spawn_pad_traffic()
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
		_spawn_pad_traffic()
		return
	if _pads.is_empty():
		_spawn_pad("Pad_North", Vector3.UP)
	_pads_built = true
	_pad_build_stage = 4
	_pad_build_pending = false
	if _P0.ONE_PAD and not _P0.OS_D_FILL:
		_spawn_filler_on_first_pad()
		_spawn_pad_traffic()
		return
	if _P0.OS_D_FILL:
		if _pad_named("Pad_Approach") == null:
			_spawn_pad("Pad_Approach", _osd_pad_dir(0))
		if _pad_named("Pad_Flank") == null:
			_spawn_pad("Pad_Flank", _osd_pad_dir(1))
		_spawn_filler_on_first_pad()
		_spawn_worldfill_scatter()
		_spawn_outpost_silhouette()
		_spawn_pad_traffic()
		print("[PlanetBody] OS-D unnamed pads n=", _pads.size())
		return
	_spawn_pad("Pad_Eq", Vector3(1, 0.15, 0).normalized())
	_spawn_pad("Pad_Far", Vector3(-0.7, 0.2, 0.7).normalized())
	_spawn_pad_density()
	_spawn_pad_traffic()


func ensure_pad_plates() -> void:
	## Plates + unnamed silhouette for OS-C radar / pip / far read.
	## Does not stream BaseBuilder (claim controllers still wait ~220 m AGL).
	## Not SITE_*.
	if not has_base:
		return
	if not _pads_built or _pads.is_empty():
		_build_pads()
	if _pads_root:
		_pads_root.visible = true


func ensure_pad_bases() -> void:
	## Force pad plates + claim controllers even when the ship is still
	## outside LOW-tier stream distance (headless / orbit spawn).
	if not has_base:
		return
	if not _pads_built or _pads.is_empty():
		_build_pads()
	_stream_bases()
	if SoftSession and SoftSession.has_method("restore_colony"):
		SoftSession.restore_colony()
	if SoftSession and SoftSession.has_method("restore_crate"):
		SoftSession.restore_crate()


func _spawn_pad(pad_name: String, dir: Vector3) -> void:
	if _pad_named(pad_name) != null:
		return
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

	# Dummy mesh_storage errors on MeshInstance add/free. P0.2 still
	# counts the pad by group + collision, not the plate RID.
	if DisplayServer.get_name() != "headless":
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
		_add_pad_far_read(pad_root)

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
	pad_root.set_meta("site_pin", "")
	# Radar / pip contacts use this group. PadBaseController (pad_bases)
	# still waits for ~220 m AGL — without this, OS-C spawn is PADS 0.
	if not pad_root.is_in_group("landing_pads"):
		pad_root.add_to_group("landing_pads")
	_pads.append(pad_root)


func _add_pad_far_read(pad_root: Node3D) -> void:
	## Unshaded silhouette so a 28 m collision plate still reads from OS-C (~8 km).
	if DisplayServer.get_name() == "headless" or pad_root == null:
		return
	var col := Color(0.95, 0.18, 0.38) if faction_base == "gROT" else Color(0.25, 0.85, 1.0)
	var far := MeshInstance3D.new()
	far.name = "FarPlate"
	var box := BoxMesh.new()
	box.size = Vector3(96, 2.2, 96)
	far.mesh = box
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.8
	far.material_override = mat
	far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	far.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# Hide when close — 96 m unshaded plate was the blue monolith next to the ship.
	far.visibility_range_begin = 420.0
	far.visibility_range_begin_margin = 80.0
	far.visibility_range_end = 12000.0
	far.visibility_range_end_margin = 400.0
	far.position = Vector3(0, 0.4, 0)
	pad_root.add_child(far)
	var mast := MeshInstance3D.new()
	mast.name = "FarMast"
	var shaft := BoxMesh.new()
	shaft.size = Vector3(2.4, 22.0, 2.4)
	mast.mesh = shaft
	mast.material_override = mat
	mast.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mast.visibility_range_begin = 420.0
	mast.visibility_range_begin_margin = 80.0
	mast.visibility_range_end = 12000.0
	mast.position = Vector3(0, 12.0, 0)
	pad_root.add_child(mast)


func _osd_pad_dir(i: int) -> Vector3:
	## Stable from body seed + local dir. Channel offset is placement only.
	var s: int = body_seed()
	var yaw := (0.22 if i == 0 else -0.48) + float((s + i * 13) % 11) * 0.012
	var pit := (0.14 if i == 0 else 0.20) + float((int(s / 5) + i) % 7) * 0.008
	var dir := Vector3(sin(yaw), pit, cos(yaw)).normalized()
	var prof: Dictionary = _Relief.profile_for_planet(str(planet_name))
	var h: float = float(_Relief.height_at_dir(dir, s, prof))
	if _Relief.is_sea(h, prof):
		dir = Vector3(sin(yaw * 0.65), pit + 0.22, cos(yaw * 0.65)).normalized()
	return dir


func _pad_named(pad_name: String) -> Node3D:
	for p in _pads:
		if p != null and is_instance_valid(p) and str(p.name) == pad_name:
			return p
	return null


func _spawn_worldfill_scatter() -> void:
	if _pads_root == null:
		return
	if _pads_root.has_node("WorldFillScatter"):
		return
	var sc := Node3D.new()
	sc.set_script(preload("res://scripts/world/WorldFillScatter.gd"))
	sc.name = "WorldFillScatter"
	_pads_root.add_child(sc)
	if sc.has_method("setup"):
		sc.call("setup", self, radius, body_seed())


func unnamed_pad_count() -> int:
	return _pads.size()


func worldfill_scatter_count() -> int:
	if _pads_root == null:
		return 0
	var sc: Node = _pads_root.get_node_or_null("WorldFillScatter")
	if sc != null and sc.has_method("prop_count"):
		return int(sc.call("prop_count"))
	return 0


func _outpost_host_pad() -> Node3D:
	## Approach-face plate (OS-D) so 8 km / 2 km +Z spawn sees the same spot.
	var approach: Node3D = _pad_named("Pad_Approach")
	if approach != null:
		return approach
	if not _pads.is_empty() and _pads[0] is Node3D:
		return _pads[0]
	return null


func _spawn_outpost_silhouette() -> void:
	if not _P0.OS_G_OUTPOST:
		return
	var host: Node3D = _outpost_host_pad()
	if host == null or not is_instance_valid(host):
		return
	if host.has_node("OutpostSilhouette"):
		return
	var sil := Node3D.new()
	sil.set_script(preload("res://scripts/world/OutpostSilhouette.gd"))
	sil.name = "OutpostSilhouette"
	host.add_child(sil)
	if sil.has_method("setup"):
		sil.call("setup", host)


func outpost_silhouette() -> Node3D:
	var host: Node3D = _outpost_host_pad()
	if host == null:
		return null
	return host.get_node_or_null("OutpostSilhouette") as Node3D


func outpost_structure_count() -> int:
	var sil: Node3D = outpost_silhouette()
	if sil != null and sil.has_method("structure_count"):
		return int(sil.call("structure_count"))
	return 0


func _traffic_host_pad() -> Node3D:
	## Occupied north plate: world +Y so CombatDummy gravity stands.
	var north: Node3D = _pad_named("Pad_North")
	if north != null:
		return north
	if not _pads.is_empty() and _pads[0] is Node3D:
		return _pads[0]
	return null


func _spawn_pad_traffic() -> void:
	var host: Node3D = _traffic_host_pad()
	if host == null or not is_instance_valid(host):
		return
	if host.has_node("PadTraffic"):
		return
	var traffic := Node3D.new()
	traffic.set_script(preload("res://scripts/world/PadTraffic.gd"))
	traffic.name = "PadTraffic"
	host.add_child(traffic)
	if traffic.has_method("setup"):
		traffic.call("setup", host)


func pad_traffic() -> Node3D:
	var host: Node3D = _traffic_host_pad()
	if host == null:
		return null
	return host.get_node_or_null("PadTraffic") as Node3D

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
	_MeshSafe.strip_imported_cameras(root)
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
	_atmo_mat.set_shader_parameter("scatter_strength", 0.85 if gq == null or int(gq.tier) > 0 else 0.55)
	if _atmo_inner_mat:
		_atmo_inner_mat.set_shader_parameter("haze_color", atmosphere_color)
		_atmo_inner_mat.set_shader_parameter("sun_direction", _sun_dir)
		_atmo_inner_mat.set_shader_parameter("scatter_strength", 0.7)

func set_sun_direction(dir: Vector3) -> void:
	if _surface_shader_mat:
		_surface_shader_mat.set_shader_parameter("sun_direction", dir)
	if _impostor_mat:
		_impostor_mat.set_shader_parameter("sun_direction", dir)
	_sun_dir = dir.normalized()
	_apply_atmo_uniforms()

func envelope_height() -> float:
	if atmosphere_envelope > 1.0:
		return atmosphere_envelope
	return maxf(atmosphere_height * 1.6, atmosphere_height)


func density_at(global_pos: Vector3) -> float:
	return float(_FlightModel.atmosphere_density(altitude_of(global_pos), atmosphere_height, envelope_height()))


func _update_atmosphere(dist: float, lod: int, obs: Node3D) -> void:
	if _atmo == null:
		return
	var show_outer := dist < atmo_max_dist
	_atmo.visible = show_outer
	var alt: float = dist - radius
	var env_h: float = envelope_height()
	# Horizon boost as we approach (limb brightens across the envelope)
	if show_outer and _atmo_mat:
		var approach := 0.0
		if alt < env_h:
			approach = clamp(1.0 - alt / maxf(env_h, 1.0), 0.0, 1.0)
		_atmo_mat.set_shader_parameter("horizon_boost", approach * 1.05)
		# Soft distance fade of overall intensity
		var fade: float = clamp(1.0 - dist / atmo_max_dist, 0.0, 1.0)
		var base_i := 1.35
		var gq := get_node_or_null("/root/GraphicsQuality")
		if gq:
			match int(gq.tier):
				0: base_i = 1.1
				2: base_i = 1.5
				3: base_i = 1.65
		# Floor keeps the limb readable at 15 km (fade near 0 must not go black).
		_atmo_mat.set_shader_parameter("intensity", base_i * (0.62 + 0.38 * fade))
	# Inner haze when inside the envelope (readable on the 770 m approach)
	if _atmo_inner:
		var inside := alt < env_h * 0.98 and lod <= 1
		_atmo_inner.visible = inside
		if inside and _atmo_inner_mat:
			var depth: float = clamp(1.0 - max(alt, 0.0) / max(env_h, 1.0), 0.0, 1.0)
			_atmo_inner_mat.set_shader_parameter("intensity", 0.35 + depth * 0.95)
			_atmo_inner_mat.set_shader_parameter("density", 0.32 + depth * 0.55)

func _stream_bases() -> void:
	if not has_base or _pads.is_empty():
		return
	# OS-D extra plates stay unnamed logistics pads. ONE_PAD keeps one controller.
	var n := 1 if _P0.ONE_PAD else mini(2, _pads.size())
	for i in n:
		_BaseBuilder.build_on_pad(_pads[i], faction_base)

func altitude_of(global_pos: Vector3) -> float:
	## AGL vs local dirt, not the collision sphere. Ship/walker land on Relief.
	var dist: float = global_pos.distance_to(global_position)
	var h: float = relief_height_at(global_pos)
	var pid := str(planet_name)
	var sea: float = float(_Relief.profile_for_planet(pid).get("sea_level", -0.35))
	return dist - (radius + maxf(h, sea))

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
	# Queue the staggered build instead of forcing the whole pad complex in one
	# frame: ShipController calls this every physics frame, so the synchronous
	# path froze the game each time a ship crossed 500 m AGL.
	if has_base and not _pads_built and altitude_of(global_pos) < 500.0:
		_pad_build_pending = true
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
	

func _spawn_filler_on_first_pad() -> void:
	if _pads.is_empty():
		return
	var host: Node3D = _pads[0]
	if host == null or not is_instance_valid(host):
		return
	if host.has_node("FillerProp"):
		return
	var fp := Node3D.new()
	fp.set_script(_Filler)
	fp.name = "FillerProp"
	host.add_child(fp)
	if fp.has_method("setup"):
		fp.call("setup", _P0.FILLER_PROP_ID)
	fp.position = Vector3(8.0, 1.1, 6.0)


func _spawn_pad_density() -> void:
	if _P0.ONE_PAD or not _P0.PAD_DENSITY:
		_spawn_filler_on_first_pad()
		return
	if _P0.FILL_STREAMERS:
		_ensure_surface_flora()
		_ensure_surface_fauna()
	if _pads_root == null:
		return
	# Parent to a real pad, not the pads root: the root sits at the planet
	# centre, so props / ambient life / city towers were built underground.
	var host: Node3D = _pads_root
	for p in _pads:
		if p != null and is_instance_valid(p):
			host = p
			break
	if host.has_node("PadDensityCluster"):
		return
	var d := Node3D.new()
	d.set_script(load("res://scripts/world/PadDensity.gd"))
	d.name = "PadDensityCluster"
	host.add_child(d)
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
	if not host.has_node("PadAmbientLife"):
		var life := Node3D.new()
		life.set_script(load("res://scripts/world/PadAmbientLife.gd"))
		life.name = "PadAmbientLife"
		host.add_child(life)
		if life.has_method("build"):
			life.build(life_n, fac)
	if not host.has_node("CityNightLights"):
		var city := Node3D.new()
		var cscr: Script = load("res://scripts/world/CityNightLights.gd") as Script
		city.set_script(cscr)
		city.name = "CityNightLights"
		host.add_child(city)
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
	var seed_i: int = body_seed()
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
		w.call("setup", self, radius, pid, body_seed())
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
		n.call("setup", self, radius, pid, body_seed() + 3)
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
		c.call("setup", self, radius, pid, body_seed() + 9)
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
		c.call("setup", self, radius, pid, body_seed() + 3)
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
		fl.setup(self, rad, body_seed() + 1)
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
	var pid := str(planet_name)
	var prof: Dictionary = _Relief.profile_for_planet(pid)
	mat.set_shader_parameter("land_color", surface_color)
	var ocean := Color(0.05, 0.18, 0.38)
	if pid == "ROT-Hive":
		ocean = Color(0.25, 0.05, 0.12)
	elif pid == "Shard-Moon":
		ocean = Color(0.12, 0.14, 0.18)
		mat.set_shader_parameter("ice_lat", 0.55)
	mat.set_shader_parameter("ocean_color", ocean)
	mat.set_shader_parameter("shore_color", Color(0.42, 0.38, 0.22))
	mat.set_shader_parameter("seed", float(body_seed()))
	mat.set_shader_parameter("chart_radius", float(_Relief.CHART_RADIUS))
	mat.set_shader_parameter("planet_radius", radius)
	mat.set_shader_parameter("sea_level", float(prof.get("sea_level", -0.35)))
	mat.set_shader_parameter("sea_threshold", float(prof.get("sea_level", -0.35)))
	mat.set_shader_parameter("hill_amp", float(prof.get("hill_amp", 1.8)))
	mat.set_shader_parameter("mountain_amp", float(prof.get("mountain_amp", 6.5)))
	mat.set_shader_parameter("sun_direction", _sun_dir)
	mat.set_shader_parameter("emission_strength", 0.06)
	mat.set_shader_parameter("city_intensity", 1.4)
	mat.set_shader_parameter("city_density", 0.55)
	if pid == "Shard-Moon":
		mat.set_shader_parameter("city_intensity", 0.35)
	elif pid == "ROT-Hive":
		mat.set_shader_parameter("city_light_color", Color(1.0, 0.35, 0.5))


func body_seed() -> int:
	return int(_Relief.body_seed(str(planet_name)))


func shader_seed() -> int:
	if _surface_shader_mat:
		return int(_surface_shader_mat.get_shader_parameter("seed"))
	return -1


func relief_height_at(world_pos: Vector3) -> float:
	var prof: Dictionary = _Relief.profile_for_planet(str(planet_name))
	var dir: Vector3 = (world_pos - global_position)
	if dir.length_squared() < 1e-8:
		return 0.0
	return float(_Relief.height_on_sphere(dir.normalized(), radius, body_seed(), prof, false))



func _sync_surface_visibility(dist: float) -> void:
	## Shared park: fill streamers stay off in P0. SurfaceDetail owns its
	## own hysteresis and must keep processing so a return can restore cache.
	var near_surf := dist < radius + 160.0
	var mid_surf := dist < radius + 280.0
	for nm in ["SurfaceFlora", "SurfaceFauna", "SurfaceWater", "CaveMouthField", "LandscapeFeatures", "CaveInterior", "TerrainEdit"]:
		var n := get_node_or_null(nm)
		if n == null:
			continue
		var want := near_surf and _P0.FILL_STREAMERS
		if nm == "SurfaceWater":
			want = mid_surf and _P0.FILL_STREAMERS
		n.visible = want
		n.set_process(want)
	if _surface_detail:
		_surface_detail.visible = true
		_surface_detail.set_process(true)
		# Far sphere under live chunks reads as dark floating LOD quads.
		# Also hide in the mid-alt band (190–250 m) before chunks stream in.
		# Collision stays on the body; only the visual shell hides.
		# Show again only when parked AND high (hysteresis) — do not bring
		# back the far-sphere garbage from P0.3 under live chunks.
		var detail_on := _surface_detail.has_method("is_parked") and not bool(_surface_detail.is_parked())
		var alt := dist - radius
		# OS-C: 5–15 km must show the far/impostor disc even if chunks are
		# still unparked from a 770 m pass. Hide the shell only in the
		# near band (P0.3 dark LOD quads under live chunks).
		if alt > 500.0:
			_far_shell_hidden = false
		elif detail_on or alt < 300.0:
			_far_shell_hidden = true
		elif alt > 360.0:
			_far_shell_hidden = false
		if _mesh and _current_lod < 3:
			_mesh.visible = not _far_shell_hidden
		if _impostor:
			if _far_shell_hidden:
				_impostor.visible = false
			elif _current_lod >= 3:
				_impostor.visible = true
