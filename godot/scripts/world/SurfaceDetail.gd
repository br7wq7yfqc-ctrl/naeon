extends Node3D
class_name SurfaceDetail
## Grid-chunk heightfield streamer.
## - Stable lat/lon cells (no orbit / swim)
## - Object pool + mesh cache
## - Per-tick load budget
## - Load ring + hysteresis unload ring

const _Math = preload("res://scripts/world/SurfaceChunkMath.gd")
const _Relief = preload("res://scripts/world/PlanetRelief.gd")

const CELL_M := 40.0
const PATCH_SIZE := 38.0
const DEFAULT_RES := 10
const LOAD_BUDGET := 2          ## meshes built per stream tick
const STREAM_HZ := 0.2          ## 5 Hz stream tick
const MESH_CACHE_MAX := 48

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

## cell -> MeshInstance3D currently in world
var _live: Dictionary = {}
## free MeshInstance3D pool
var _pool: Array = []
## cell key "x,y" -> ArrayMesh cache
var _mesh_cache: Dictionary = {}
## FIFO keys for cache eviction
var _mesh_cache_order: Array = []
## cells waiting to build this tick
var _queue: Array = []
var _active: bool = false
var _xform_accum: float = 0.0


func setup(planet: Node3D, radius: float, color: Color, seed_i: int = 1) -> void:
	_planet = planet
	_radius = radius
	_surface_color = color
	_seed = seed_i
	if planet != null and "planet_name" in planet:
		_planet_id = str(planet.planet_name)
	_relief_profile = _Relief.profile_for_planet(_planet_id)
	_apply_quality()


func set_observer(n: Node3D) -> void:
	_observer = n
	_center_cell = Vector2i(999999, 999999)
	_queue.clear()


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
		2:
			_load_ring = 2
			_unload_ring = 3
			_res = 12
		3:
			_load_ring = 2
			_unload_ring = 3
			_res = 14
		_:
			_load_ring = 1
			_unload_ring = 2
			_res = DEFAULT_RES
	# Quality change: drop mesh cache (res may differ)
	_mesh_cache.clear()
	_mesh_cache_order.clear()


func _process(delta: float) -> void:
	_accum += delta
	if _accum < STREAM_HZ:
		return
	_accum = 0.0
	if _planet == null or _observer == null or not is_instance_valid(_observer):
		return
	var alt: float = _observer.global_position.distance_to(_planet.global_position) - _radius
	if alt > 160.0 or alt < -10.0:
		if _active:
			_park_all()
			_active = false
		return
	_active = true
	var cell: Vector2i = _Math.cell_of(_planet.global_position, _radius, _observer.global_position, CELL_M)
	if cell != _center_cell:
		_center_cell = cell
		_enqueue_needed(cell)
		_unload_far(cell)
	# FloatingOrigin may shift planet — cheap refresh of live xforms
	_xform_accum += STREAM_HZ
	if _xform_accum >= 1.0:
		_xform_accum = 0.0
		for c in _live.keys():
			_refresh_xform(c)
	# Budgeted builds
	var built := 0
	while built < LOAD_BUDGET and not _queue.is_empty():
		var c: Vector2i = _queue.pop_front()
		if _live.has(c):
			continue
		if _Math.chebyshev(c, _center_cell) > _load_ring:
			continue
		_spawn_cell(c)
		built += 1


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


func _park_all() -> void:
	_queue.clear()
	var keys: Array = _live.keys()
	for k in keys:
		_recycle(k)


func _spawn_cell(cell: Vector2i) -> void:
	var mi: MeshInstance3D
	if not _pool.is_empty():
		mi = _pool.pop_back()
	else:
		mi = MeshInstance3D.new()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.albedo_color = _surface_color.lightened(0.04)
		mat.roughness = 0.96
		mat.metallic = 0.0
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		mat.emission_enabled = false
		var gq := get_node_or_null("/root/GraphicsQuality")
		if gq and int(gq.tier) <= 0:
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mi.material_override = mat
		add_child(mi)
	mi.mesh = _mesh_for_cell(cell)
	_ensure_vertex_mat(mi)
	mi.visible = true
	_live[cell] = mi
	_refresh_xform(cell)


func _recycle(cell: Vector2i) -> void:
	if not _live.has(cell):
		return
	var mi: MeshInstance3D = _live[cell]
	_live.erase(cell)
	if mi and is_instance_valid(mi):
		mi.visible = false
		mi.mesh = null  # drop RID ref; mesh may stay in cache
		_pool.append(mi)


func _refresh_xform(cell: Vector2i) -> void:
	if not _live.has(cell) or _planet == null:
		return
	var mi: MeshInstance3D = _live[cell]
	mi.global_transform = _Math.cell_transform(_planet.global_position, _radius, cell, CELL_M, 0.35)


func _mesh_for_cell(cell: Vector2i) -> ArrayMesh:
	var key := "%d:%d:r%d" % [cell.x, cell.y, _res]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var mesh := _build_height_mesh(cell)
	_mesh_cache[key] = mesh
	_mesh_cache_order.append(key)
	while _mesh_cache_order.size() > MESH_CACHE_MAX:
		var old: String = _mesh_cache_order.pop_front()
		_mesh_cache.erase(old)
	return mesh


func _build_height_mesh(cell: Vector2i) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := PATCH_SIZE * 0.5
	var step := PATCH_SIZE / float(_res - 1)
	var ox := float(cell.x) * PATCH_SIZE
	var oz := float(cell.y) * PATCH_SIZE
	var verts: Array[Vector3] = []
	var colors: PackedColorArray = PackedColorArray()
	verts.resize(_res * _res)
	colors.resize(_res * _res)
	var sea: float = float(_relief_profile.get("sea_level", -0.35))
	for z in _res:
		for x in _res:
			var px := -half + float(x) * step
			var pz := -half + float(z) * step
			var wx := px + ox
			var wz := pz + oz
			var h: float = float(_Relief.height_at(wx, wz, _seed, _relief_profile))
			var col: Color = _surface_color
			if h < sea:
				h = sea
				col = Color(0.12, 0.28, 0.48).lerp(Color(0.08, 0.4, 0.55), 0.4)
			elif h < sea + 0.55:
				col = Color(0.45, 0.4, 0.28).lerp(_surface_color, 0.35)
			elif h > 5.0:
				col = Color(0.55, 0.55, 0.58).lerp(_surface_color, 0.25)
			elif bool(_Relief.is_canyon(wx, wz, _seed)):
				col = Color(0.35, 0.22, 0.15).lerp(_surface_color, 0.4)
			elif bool(_Relief.is_river(wx, wz, _seed, _relief_profile)):
				col = Color(0.15, 0.35, 0.5).lerp(_surface_color, 0.3)
			verts[z * _res + x] = Vector3(px, h, pz)
			colors[z * _res + x] = col
	for z in _res - 1:
		for x in _res - 1:
			var i00 := z * _res + x
			var i10 := i00 + 1
			var i01 := i00 + _res
			var i11 := i01 + 1
			for idx in [i00, i10, i11, i00, i11, i01]:
				st.set_color(colors[idx])
				st.add_vertex(verts[idx])
	st.generate_normals()
	return st.commit()


func live_count() -> int:
	return _live.size()


func queue_depth() -> int:
	return _queue.size()


func _ensure_vertex_mat(mi: MeshInstance3D) -> void:
	if mi == null:
		return
	if mi.material_override != null:
		var ex = mi.material_override
		if ex is StandardMaterial3D:
			(ex as StandardMaterial3D).vertex_color_use_as_albedo = true
		return
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	mat.metallic = 0.02
	mat.albedo_color = _surface_color
	mi.material_override = mat
