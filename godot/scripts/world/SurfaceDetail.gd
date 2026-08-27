extends Node3D
class_name SurfaceDetail
## Grid-chunk heightfield streamer.
## - Stable lat/lon cells (no orbit / swim)
## - Object pool + mesh cache
## - Per-tick load budget
## - Load ring + hysteresis unload ring
## OS-E: PBR near shader (CC0 albedo/rough/normal) on these meshes.
## Height stays Relief. Binaries never in git.

const _Math = preload("res://scripts/world/SurfaceChunkMath.gd")
const _Relief = preload("res://scripts/world/PlanetRelief.gd")
const _P0 = preload("res://scripts/world/P0Slice.gd")
const _AP = preload("res://scripts/assets/AssetPaths.gd")
const _NEAR_SHADER = preload("res://shaders/planet_surface_near.gdshader")

const CELL_M := 40.0
const PATCH_SIZE := 40.8
const DEFAULT_RES := 8
const LOAD_BUDGET := 1          ## new meshes per stream tick (global park shares this)
const STREAM_HZ := 0.28         ## ~3.5 Hz default; LOW slower
const MESH_CACHE_MAX := 48
const POOL_MAX := 8
const ACTIVATE_ALT := 300.0
const PARK_ALT := 380.0         ## hysteresis: probe retreat is 400 m — still parks

var _planet: Node3D
var _radius: float = 1200.0
var _surface_color: Color = Color(0.12, 0.2, 0.16)
var _seed: int = 1
var _planet_id: String = "Nex-Prime"
var _relief_profile: Dictionary = {}
var _observer: Node3D

var _accum: float = 0.0
var _center_cell: Vector2i = Vector2i(999999, 999999)
var _load_ring: int = 1         ## chebyshev radius to keep loaded
var _unload_ring: int = 2       ## hysteresis: keep until outside this
var _res: int = DEFAULT_RES

## cell -> Node3D currently in world (MeshInstance3D on GPU)
var _live: Dictionary = {}
## free Node3D pool
var _pool: Array = []
## cell key "x,y" -> Mesh on GPU, true on dummy (count only)
var _mesh_cache: Dictionary = {}
## Same key -> ConcavePolygonShape3D (OS-I: do not rebuild trimesh every spawn)
var _shape_cache: Dictionary = {}
## FIFO keys for cache eviction
var _mesh_cache_order: Array = []
## cells waiting to build this tick
var _queue: Array = []
var _active: bool = false
var _warm_t: float = 0.0
var _warm_cells: int = 0
var _xform_accum: float = 0.0
## Shared near-read material. One ShaderMaterial for the whole ring.
var _near_mat: ShaderMaterial
var _pbr_src: String = "none"
var _albedo_tex: Texture2D
var _rock_tex: Texture2D
var _normal_tex: Texture2D
var _rough_tex: Texture2D


func setup(planet: Node3D, radius: float, color: Color, seed_i: int = 1) -> void:
	_planet = planet
	_radius = radius
	_surface_color = color
	if planet != null and "planet_name" in planet:
		_planet_id = str(planet.planet_name)
	_seed = _Relief.body_seed(_planet_id) if _planet_id != "" else seed_i
	_relief_profile = _Relief.profile_for_planet(_planet_id)
	_apply_quality()
	_ensure_near_mat()


func set_observer(n: Node3D) -> void:
	_observer = n
	## Do not drop live / cache. Re-bind only forces the next tick to
	## re-evaluate the ring so a retreat/reapproach can restore.


func _ready() -> void:
	set_process(true)
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and gq.has_signal("tier_changed"):
		gq.tier_changed.connect(func(_t): _apply_quality())


func _apply_quality() -> void:
	var gq := get_node_or_null("/root/GraphicsQuality")
	var tier := 1
	if gq:
		tier = int(gq.tier)
	match tier:
		0:
			_load_ring = 1
			_unload_ring = 2
			_res = 8
		1:
			_load_ring = 2
			_unload_ring = 3
			_res = 16
		2:
			_load_ring = 2
			_unload_ring = 3
			_res = 16
		3:
			_load_ring = 2
			_unload_ring = 3
			_res = 14
		_:
			_load_ring = 1
			_unload_ring = 2
			_res = DEFAULT_RES
	# Quality change: drop mesh cache (res may differ). Live cells keep
	# their current mesh until recycled; next spawn rebuilds at new res.
	_mesh_cache.clear()
	_shape_cache.clear()
	_mesh_cache_order.clear()
	_tune_near_quality(tier)


func _process(delta: float) -> void:
	_accum += delta
	var hz := STREAM_HZ
	var gq := get_node_or_null("/root/GraphicsQuality")
	var tier := int(gq.tier) if gq else 1
	match tier:
		0:
			hz = 0.55
		1:
			hz = 0.40
		2:
			hz = 0.32
		_:
			hz = 0.28
	if _warm_t < 4.0:
		hz = maxf(hz, 0.5)
	if _accum < hz:
		return
	_accum = 0.0
	if _planet == null or _observer == null or not is_instance_valid(_observer):
		return
	var alt: float = _observer.global_position.distance_to(_planet.global_position) - _radius
	if alt < -10.0 or (_active and alt > PARK_ALT) or (not _active and alt > ACTIVATE_ALT):
		if _active:
			_park_all()
			_active = false
			_warm_t = 0.0
			_warm_cells = 0
		return
	if not _active:
		_active = true
		_warm_t = 0.0
		_warm_cells = 0
		_queue.clear()
	_warm_t += hz
	var cell: Vector2i = _Math.cell_of(_planet.global_position, _radius, _observer.global_position, CELL_M)
	# Enqueue every tick — standing still used to freeze the ring at 1 cell
	# because expansion was gated on cell change.
	if cell != _center_cell:
		_center_cell = cell
		_unload_far(cell)
	# Cached cells restore the full load ring; only new meshes warm up.
	_restore_ring(cell, _load_ring)
	_enqueue_ring(cell, _desired_ring())
	_xform_accum += hz
	var xneed := 1.6 if tier <= 1 else 1.1
	if _xform_accum >= xneed:
		_xform_accum = 0.0
		_sync_near_origin()
		var n := 0
		for c in _live.keys():
			_refresh_xform(c)
			n += 1
			if n >= 6:
				break
	while not _queue.is_empty():
		var c: Vector2i = _queue.pop_front()
		if _live.has(c):
			continue
		if _Math.chebyshev(c, _center_cell) > _load_ring:
			continue
		var cached := _mesh_cache.has(_cache_key(c))
		if cached:
			if not _P0.take_restore():
				_queue.push_front(c)
				break
		else:
			if not _P0.take_build():
				_queue.push_front(c)
				break
		_spawn_cell(c)
		_warm_cells += 1


func _enqueue_ring(center: Vector2i, ring: int) -> void:
	var want: Array[Vector2i] = _Math.ring_cells(center, ring)
	want.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _Math.chebyshev(a, center) < _Math.chebyshev(b, center)
	)
	for c in want:
		if _live.has(c):
			continue
		if c in _queue:
			continue
		_queue.append(c)
	# Cap queue depth — never backlog 50+ meshes
	while _queue.size() > 12:
		_queue.pop_back()


func _enqueue_needed(center: Vector2i) -> void:
	var want: Array[Vector2i] = _Math.ring_cells(center, _load_ring)
	# Prioritize center first, then nearest
	want.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _Math.chebyshev(a, center) < _Math.chebyshev(b, center)
	)
	for c in want:
		if _live.has(c):
			# refresh transform only (planet may have floating-origin shifted)
			_refresh_xform(c)
			continue
		if c in _queue:
			continue
		_queue.append(c)


func _unload_far(center: Vector2i) -> void:
	var to_drop: Array = []
	for k in _live.keys():
		var c: Vector2i = k
		if _Math.chebyshev(c, center) > _unload_ring:
			to_drop.append(c)
	for c in to_drop:
		_recycle(c)


func _desired_ring() -> int:
	## Cache hits restore the full load ring immediately. New meshes still
	## warm up so the first visit cannot freeze a frame.
	if _mesh_cache.size() > 0 and _warm_cells >= 1:
		return _load_ring
	if _warm_cells < 1:
		return 0
	if _warm_t < 2.5:
		return mini(1, _load_ring)
	return _load_ring


func _cache_key(cell: Vector2i) -> String:
	return "%d:%d:r%d:v7" % [cell.x, cell.y, _res]


func _restore_ring(center: Vector2i, ring: int) -> void:
	var want: Array[Vector2i] = _Math.ring_cells(center, ring)
	for c in want:
		if _live.has(c):
			continue
		if not _mesh_cache.has(_cache_key(c)):
			continue
		if c in _queue:
			continue
		_queue.push_front(c)


func _park_all() -> void:
	## Hide live instances. Keep the mesh cache so a return restores the ring
	## instead of calling _build_height_mesh again.
	_queue.clear()
	var keys: Array = _live.keys()
	for k in keys:
		_recycle(k)
	for n in _pool:
		if n != null and is_instance_valid(n):
			n.visible = false
			_set_chunk_collision_enabled(n, false)
	_trim_pool()


func _spawn_cell(cell: Vector2i) -> void:
	## Dummy cannot RID a MeshInstance. Keep a Node3D marker so live/cache
	## counts still restore the ring (P0.1) without mesh_get_surface_count.
	if DisplayServer.get_name() == "headless":
		var marker: Node3D
		if not _pool.is_empty():
			marker = _pool.pop_back()
		else:
			marker = Node3D.new()
			marker.name = "Chunk"
			add_child(marker)
		_mesh_for_cell(cell)
		marker.visible = true
		_live[cell] = marker
		_refresh_xform(cell)
		return
	var mi: MeshInstance3D
	if not _pool.is_empty():
		mi = _pool.pop_back()
	else:
		mi = MeshInstance3D.new()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		_ensure_near_mat()
		mi.material_override = _near_mat
		# Placeholder mesh so RID never null when entering tree
		var ph := BoxMesh.new()
		ph.size = Vector3(0.01, 0.01, 0.01)
		mi.mesh = ph
		add_child(mi)
	mi.mesh = _mesh_for_cell(cell)
	mi.set_meta("chunk_key", _cache_key(cell))
	_ensure_vertex_mat(mi)
	_ensure_chunk_collision(mi)
	_set_chunk_collision_enabled(mi, true)
	mi.visible = true
	_live[cell] = mi
	_refresh_xform(cell)



func force_ground_at(world_pos: Vector3) -> void:
	## EVA / hatch / land: build the cell under the actor NOW so snap raycast
	## hits dirt trimesh, not the catch-sphere (fall-through after F/I).
	if _planet == null:
		return
	_active = true
	var cell: Vector2i = _Math.cell_of(_planet.global_position, _radius, world_pos, CELL_M)
	_center_cell = cell
	var ring: int = mini(1, _load_ring)
	var want: Array[Vector2i] = _Math.ring_cells(cell, ring)
	for c in want:
		if _live.has(c):
			_refresh_xform(c)
			var n: Node3D = _live[c]
			if n is MeshInstance3D:
				_ensure_chunk_collision(n as MeshInstance3D)
				_set_chunk_collision_enabled(n, true)
			continue
		_spawn_cell(c)


func _set_chunk_collision_enabled(n: Node, on: bool) -> void:
	if n == null or not is_instance_valid(n):
		return
	var sb: StaticBody3D = n.get_node_or_null("Col") as StaticBody3D
	if sb == null:
		return
	sb.collision_layer = 1 if on else 0
	sb.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func _ensure_chunk_collision(mi: MeshInstance3D) -> void:
	## Visual Relief mesh IS the physics proxy (SC: no sphere-as-ground).
	if mi == null or mi.mesh == null:
		return
	if DisplayServer.get_name() == "headless":
		return
	if not (mi.mesh is ArrayMesh):
		return
	var sb: StaticBody3D = mi.get_node_or_null("Col") as StaticBody3D
	if sb == null:
		sb = StaticBody3D.new()
		sb.name = "Col"
		sb.collision_layer = 1
		sb.collision_mask = 0
		var cs := CollisionShape3D.new()
		cs.name = "Shape"
		sb.add_child(cs)
		mi.add_child(sb)
	var cs2: CollisionShape3D = sb.get_node_or_null("Shape") as CollisionShape3D
	if cs2 == null:
		return
	var key := str(mi.get_meta("chunk_key", ""))
	var shape: Shape3D = null
	if key != "" and _shape_cache.has(key):
		shape = _shape_cache[key]
	else:
		shape = (mi.mesh as ArrayMesh).create_trimesh_shape()
		if key != "":
			_shape_cache[key] = shape
	cs2.shape = shape
	sb.collision_layer = 1
	sb.process_mode = Node.PROCESS_MODE_INHERIT


func _recycle(cell: Vector2i) -> void:
	if not _live.has(cell):
		return
	var n: Node3D = _live[cell]
	_live.erase(cell)
	if n == null or not is_instance_valid(n):
		return
	n.visible = false
	_set_chunk_collision_enabled(n, false)
	# Cap pool — excess MeshInstance3D + mats were a soft leak
	if _pool.size() < POOL_MAX:
		_pool.append(n)
	else:
		n.queue_free()


func _trim_pool() -> void:
	while _pool.size() > POOL_MAX:
		var extra = _pool.pop_back()
		if extra != null and is_instance_valid(extra):
			extra.queue_free()


func _refresh_xform(cell: Vector2i) -> void:
	if not _live.has(cell) or _planet == null:
		return
	var n: Node3D = _live[cell]
	n.global_transform = _Math.cell_transform(_planet.global_position, _radius, cell, CELL_M, 0.02)


func _mesh_for_cell(cell: Vector2i) -> Variant:
	var key := _cache_key(cell)
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var mesh
	if DisplayServer.get_name() == "headless":
		## Dummy cannot RID SurfaceTool ArrayMesh. Cache a sentinel so
		## restore still hits; heightfield stays on GPU / visible.
		mesh = true
	else:
		mesh = _build_height_mesh(cell)
	_mesh_cache[key] = mesh
	_mesh_cache_order.append(key)
	while _mesh_cache_order.size() > MESH_CACHE_MAX:
		var old: String = _mesh_cache_order.pop_front()
		_mesh_cache.erase(old)
		_shape_cache.erase(old)
	return mesh


func _build_height_mesh(cell: Vector2i) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := PATCH_SIZE * 0.5
	var step := PATCH_SIZE / float(_res - 1)
	var dir_c: Vector3 = _Math.cell_center_dir(cell, _radius, CELL_M)
	var tang: Array = _Math.stable_tangent(dir_c)
	var east: Vector3 = tang[0]
	var north: Vector3 = tang[1]
	var origin: Vector3 = dir_c * (_radius + 0.02)
	var verts: Array[Vector3] = []
	var colors: PackedColorArray = PackedColorArray()
	var uvs: PackedVector2Array = PackedVector2Array()
	var uv2s: PackedVector2Array = PackedVector2Array()
	verts.resize(_res * _res)
	colors.resize(_res * _res)
	uvs.resize(_res * _res)
	uv2s.resize(_res * _res)
	var sea: float = float(_relief_profile.get("sea_level", -0.35))
	for z in _res:
		for x in _res:
			var px := -half + float(x) * step
			var pz := -half + float(z) * step
			var dir: Vector3 = _Math.vertex_dir(_radius, cell, CELL_M, px, pz)
			var xz: Vector2 = _Relief.dir_to_chart(dir)
			var wx: float = xz.x
			var wz: float = xz.y
			var h: float = float(_Relief.height_at(wx, wz, _seed, _relief_profile))
			var col: Color = _surface_color.lightened(0.12)
			var biome: String = str(_Relief.biome_hint(wx, wz, h, _seed, _relief_profile))
			if h < sea or biome == "ocean":
				h = sea
				col = Color(0.18, 0.38, 0.58).lerp(Color(0.12, 0.48, 0.62), 0.4)
			elif biome == "shore" or h < sea + 0.55:
				col = Color(0.55, 0.48, 0.32).lerp(_surface_color, 0.35)
			elif biome == "mesa":
				col = Color(0.62, 0.44, 0.28).lerp(_surface_color, 0.3)
			elif biome == "dunes":
				col = Color(0.78, 0.68, 0.4).lerp(_surface_color, 0.25)
			elif biome == "crater":
				col = Color(0.38, 0.34, 0.3).lerp(_surface_color, 0.35)
			elif biome == "alpine" or h > 5.0:
				col = Color(0.62, 0.62, 0.66).lerp(_surface_color, 0.25)
			elif biome == "canyon" or bool(_Relief.is_canyon(wx, wz, _seed)):
				col = Color(0.45, 0.3, 0.2).lerp(_surface_color, 0.4)
			elif biome == "river" or bool(_Relief.is_river(wx, wz, _seed, _relief_profile)):
				col = Color(0.22, 0.42, 0.58).lerp(_surface_color, 0.3)
			# Radial placement: tangent-plane (px,h,pz) left cliffs + floating quads.
			var world: Vector3 = dir * (_radius + h)
			var rel: Vector3 = world - origin
			var i := z * _res + x
			verts[i] = Vector3(rel.dot(east), rel.dot(dir_c), -rel.dot(north))
			colors[i] = Color(col.r, col.g, col.b, _biome_pack(biome, h, sea))
			uvs[i] = Vector2((px + half) / PATCH_SIZE, (pz + half) / PATCH_SIZE)
			## Paint UV is CHART_RADIUS so dirt/rock don't retile per body radius.
			uv2s[i] = _Relief.dir_to_chart(dir)
	for z in _res - 1:
		for x in _res - 1:
			var i00 := z * _res + x
			var i10 := i00 + 1
			var i01 := i00 + _res
			var i11 := i01 + 1
			for idx in [i00, i10, i11, i00, i11, i01]:
				st.set_color(colors[idx])
				st.set_uv(uvs[idx])
				st.set_uv2(uv2s[idx])
				st.add_vertex(verts[idx])
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


func live_count() -> int:
	return _live.size()


func queue_depth() -> int:
	return _queue.size()


func cache_count() -> int:
	return _mesh_cache.size()


func is_parked() -> bool:
	return not _active


func body_seed() -> int:
	return _seed


func refresh_all_xforms() -> void:
	for c in _live.keys():
		_refresh_xform(c)


func _biome_pack(biome: String, h: float, sea: float) -> float:
	## COLOR.a class for the near shader. Does not change height.
	if h < sea or biome == "ocean":
		return 0.06
	if biome == "shore" or h < sea + 0.55:
		return 0.18
	if biome == "dunes":
		return 0.30
	if biome == "mesa":
		return 0.42
	if biome == "crater":
		return 0.54
	if biome == "alpine" or h > 5.0:
		return 0.66
	if biome == "canyon":
		return 0.78
	if biome == "river":
		return 0.90
	return 1.0


func _ensure_near_mat() -> void:
	if _near_mat != null and _near_mat.shader != null:
		_near_mat.set_shader_parameter("seed", float(_seed))
		_bind_pbr_maps()
		_sync_near_origin()
		return
	_near_mat = ShaderMaterial.new()
	_near_mat.shader = _NEAR_SHADER
	_near_mat.set_shader_parameter("seed", float(_seed))
	_near_mat.set_shader_parameter("chart_radius", float(_Relief.CHART_RADIUS))
	_near_mat.set_shader_parameter("micro_strength", 0.22)
	_near_mat.set_shader_parameter("decal_strength", 0.55)
	_near_mat.set_shader_parameter("decal_density", 1.0)
	_near_mat.set_shader_parameter("tile_meters", 4.0)
	_near_mat.set_shader_parameter("near_fade_start", 8.0)
	_near_mat.set_shader_parameter("near_fade_end", 52.0)
	_near_mat.set_shader_parameter("emission_strength", 0.06)
	_near_mat.set_shader_parameter("roughness_var", 0.55)
	_near_mat.set_shader_parameter("normal_depth", 0.85)
	_bind_pbr_maps()
	_sync_near_origin()
	var gq := get_node_or_null("/root/GraphicsQuality")
	_tune_near_quality(int(gq.tier) if gq else 1)


func _tune_near_quality(tier: int) -> void:
	if _near_mat == null:
		return
	match tier:
		0:
			_near_mat.set_shader_parameter("micro_strength", 0.12)
			_near_mat.set_shader_parameter("decal_strength", 0.35)
			_near_mat.set_shader_parameter("decal_density", 0.7)
			_near_mat.set_shader_parameter("tile_meters", 5.5)
			_near_mat.set_shader_parameter("normal_depth", 0.45)
		1:
			_near_mat.set_shader_parameter("micro_strength", 0.22)
			_near_mat.set_shader_parameter("decal_strength", 0.55)
			_near_mat.set_shader_parameter("decal_density", 1.0)
			_near_mat.set_shader_parameter("tile_meters", 4.0)
			_near_mat.set_shader_parameter("normal_depth", 0.85)
		_:
			_near_mat.set_shader_parameter("micro_strength", 0.26)
			_near_mat.set_shader_parameter("decal_strength", 0.62)
			_near_mat.set_shader_parameter("decal_density", 1.25)
			_near_mat.set_shader_parameter("tile_meters", 3.2)
			_near_mat.set_shader_parameter("normal_depth", 1.05)


func _sync_near_origin() -> void:
	if _near_mat == null or _planet == null:
		return
	_near_mat.set_shader_parameter("planet_origin", _planet.global_position)
	if "_sun_dir" in _planet:
		_near_mat.set_shader_parameter("sun_direction", _planet._sun_dir)


func near_material() -> ShaderMaterial:
	_ensure_near_mat()
	return _near_mat


func near_read_enabled() -> bool:
	_ensure_near_mat()
	return _near_mat != null and _near_mat.shader != null


func near_pbr_status() -> Dictionary:
	_ensure_near_mat()
	return {
		"src": _pbr_src,
		"albedo": _albedo_tex != null,
		"rock": _rock_tex != null,
		"normal": _normal_tex != null,
		"rough": _rough_tex != null,
		"unshaded": false,
	}


func _ensure_vertex_mat(mi: MeshInstance3D) -> void:
	if mi == null:
		return
	_ensure_near_mat()
	mi.material_override = _near_mat


func _bind_pbr_maps() -> void:
	if _near_mat == null:
		return
	if _albedo_tex == null:
		var dirt_paths: PackedStringArray = PackedStringArray([
			"filler/forest_ground_04/forest_ground_04_diff_1k.png",
			"filler/forest_ground_04/forest_ground_04_diff_1k.jpg",
			"filler/ground037/Ground037_1K-JPG_Color.jpg",
			"filler/ground037/Ground037_1K-PNG_Color.png",
		])
		var rock_paths: PackedStringArray = PackedStringArray([
			"filler/rock_face/rock_face_diff_1k.png",
			"filler/rock_face/rock_face_diff_1k.jpg",
			"filler/rock023/Rock023_1K-JPG_Color.jpg",
			"filler/rock023/Rock023_1K-PNG_Color.png",
		])
		var nrm_paths: PackedStringArray = PackedStringArray([
			"filler/forest_ground_04/forest_ground_04_nor_gl_1k.png",
			"filler/forest_ground_04/forest_ground_04_nor_gl_1k.jpg",
			"filler/ground037/Ground037_1K-JPG_NormalGL.jpg",
		])
		var rgh_paths: PackedStringArray = PackedStringArray([
			"filler/forest_ground_04/forest_ground_04_rough_1k.png",
			"filler/forest_ground_04/forest_ground_04_rough_1k.jpg",
			"filler/ground037/Ground037_1K-JPG_Roughness.jpg",
		])
		_albedo_tex = _load_cc0_tex(dirt_paths)
		_rock_tex = _load_cc0_tex(rock_paths)
		_normal_tex = _load_cc0_tex(nrm_paths)
		_rough_tex = _load_cc0_tex(rgh_paths)
		var loaded := _albedo_tex != null or _rock_tex != null
		if _albedo_tex == null:
			_albedo_tex = _fallback_albedo(Color(0.32, 0.24, 0.16))
		if _rock_tex == null:
			_rock_tex = _fallback_albedo(Color(0.44, 0.41, 0.38))
		if _normal_tex == null:
			_normal_tex = _fallback_normal()
		if _rough_tex == null:
			_rough_tex = _fallback_rough()
		_pbr_src = "cc0" if loaded else "fallback"
	_near_mat.set_shader_parameter("albedo_tex", _albedo_tex)
	_near_mat.set_shader_parameter("rock_tex", _rock_tex)
	_near_mat.set_shader_parameter("normal_tex", _normal_tex)
	_near_mat.set_shader_parameter("rough_tex", _rough_tex)


func _load_cc0_tex(rels: PackedStringArray) -> Texture2D:
	for rel in rels:
		var path := _cc0_path(str(rel))
		if path == "" or not FileAccess.file_exists(path):
			continue
		var img := Image.new()
		if img.load(path) != OK:
			continue
		if img.is_compressed():
			img.decompress()
		if img.get_width() > 1024 or img.get_height() > 1024:
			img.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
		img.generate_mipmaps()
		print("[SurfaceDetail] CC0 ", rel, " <- ", path)
		return ImageTexture.create_from_image(img)
	return null


func _cc0_path(rel: String) -> String:
	var hits: PackedStringArray = PackedStringArray()
	var resolved: String = str(_AP.resolve(rel))
	if resolved != "":
		hits.append(resolved)
	var user_p := ProjectSettings.globalize_path("user://filler/%s" % rel)
	hits.append(user_p)
	var user_bare := ProjectSettings.globalize_path("user://%s" % rel)
	hits.append(user_bare)
	var res_base: String = ProjectSettings.globalize_path("res://")
	hits.append(res_base.get_base_dir().path_join("assets").path_join(rel))
	hits.append(res_base.path_join("bundled_assets").path_join(rel))
	var home: String = OS.get_environment("HOME")
	if home != "":
		hits.append(home.path_join("Documents/naeon/assets").path_join(rel))
		hits.append(home.path_join("Library/Application Support/NAEON/assets").path_join(rel))
	for c in hits:
		if c != "" and FileAccess.file_exists(c):
			return c
	return ""


func _fallback_albedo(base: Color) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var n := sin(float(x) * 0.37 + float(_seed) * 0.01) * cos(float(y) * 0.29)
			n += 0.35 * sin(float(x) * 1.1 - float(y) * 0.8)
			n *= 0.07
			var c := Color(
				clampf(base.r + n, 0.0, 1.0),
				clampf(base.g + n * 0.7, 0.0, 1.0),
				clampf(base.b + n * 0.45, 0.0, 1.0)
			)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _fallback_normal() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var nx := 0.5 + 0.08 * sin(float(x) * 0.41 + float(y) * 0.17)
			var ny := 0.5 + 0.08 * cos(float(y) * 0.37 - float(x) * 0.13)
			img.set_pixel(x, y, Color(nx, ny, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _fallback_rough() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var r := 0.62 + 0.18 * sin(float(x) * 0.22) * cos(float(y) * 0.19)
			img.set_pixel(x, y, Color(r, r, r))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
