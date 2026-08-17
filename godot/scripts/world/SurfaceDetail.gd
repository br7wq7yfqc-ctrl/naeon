extends Node3D
class_name SurfaceDetail
## Grid-chunk heightfield streamer.
## - Stable lat/lon cells (no orbit / swim)
## - Object pool + mesh cache
## - Per-tick load budget
## - Load ring + hysteresis unload ring

const _Math = preload("res://scripts/world/SurfaceChunkMath.gd")
const _Relief = preload("res://scripts/world/PlanetRelief.gd")
const _P0 = preload("res://scripts/world/P0Slice.gd")

const CELL_M := 40.0
const PATCH_SIZE := 38.0
const DEFAULT_RES := 8
const LOAD_BUDGET := 1          ## new meshes per stream tick (global park shares this)
const STREAM_HZ := 0.28         ## ~3.5 Hz default; LOW slower
const MESH_CACHE_MAX := 48
const POOL_MAX := 8
const ACTIVATE_ALT := 140.0
const PARK_ALT := 220.0         ## hysteresis: do not thrash the ring at 140 m

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
## FIFO keys for cache eviction
var _mesh_cache_order: Array = []
## cells waiting to build this tick
var _queue: Array = []
var _active: bool = false
var _warm_t: float = 0.0
var _warm_cells: int = 0
var _xform_accum: float = 0.0


func setup(planet: Node3D, radius: float, color: Color, seed_i: int = 1) -> void:
	_planet = planet
	_radius = radius
	_surface_color = color
	if planet != null and "planet_name" in planet:
		_planet_id = str(planet.planet_name)
	_seed = _Relief.body_seed(_planet_id) if _planet_id != "" else seed_i
	_relief_profile = _Relief.profile_for_planet(_planet_id)
	_apply_quality()


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
	# Quality change: drop mesh cache (res may differ). Live cells keep
	# their current mesh until recycled; next spawn rebuilds at new res.
	_mesh_cache.clear()
	_mesh_cache_order.clear()


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
	return "%d:%d:r%d:v3" % [cell.x, cell.y, _res]


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
		# Placeholder mesh so RID never null when entering tree
		var ph := BoxMesh.new()
		ph.size = Vector3(0.01, 0.01, 0.01)
		mi.mesh = ph
		add_child(mi)
	mi.mesh = _mesh_for_cell(cell)
	_ensure_vertex_mat(mi)
	mi.visible = true
	_live[cell] = mi
	_refresh_xform(cell)


func _recycle(cell: Vector2i) -> void:
	if not _live.has(cell):
		return
	var n: Node3D = _live[cell]
	_live.erase(cell)
	if n == null or not is_instance_valid(n):
		return
	n.visible = false
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
	n.global_transform = _Math.cell_transform(_planet.global_position, _radius, cell, CELL_M, 0.35)


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
	return mesh


func _build_height_mesh(cell: Vector2i) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := PATCH_SIZE * 0.5
	var step := PATCH_SIZE / float(_res - 1)
	var verts: Array[Vector3] = []
	var colors: PackedColorArray = PackedColorArray()
	verts.resize(_res * _res)
	colors.resize(_res * _res)
	var sea: float = float(_relief_profile.get("sea_level", -0.35))
	for z in _res:
		for x in _res:
			var px := -half + float(x) * step
			var pz := -half + float(z) * step
			var dir: Vector3 = _Math.vertex_dir(_radius, cell, CELL_M, px, pz)
			var chart: Vector2 = _Relief.dir_to_chart(dir)
			var wx: float = chart.x
			var wz: float = chart.y
			var h: float = float(_Relief.height_at_dir(dir, _seed, _relief_profile))
			var col: Color = _surface_color
			var biome: String = str(_Relief.biome_hint(wx, wz, h, _seed, _relief_profile))
			if h < sea or biome == "ocean":
				h = sea
				col = Color(0.12, 0.28, 0.48).lerp(Color(0.08, 0.4, 0.55), 0.4)
			elif biome == "shore" or h < sea + 0.55:
				col = Color(0.45, 0.4, 0.28).lerp(_surface_color, 0.35)
			elif biome == "mesa":
				col = Color(0.55, 0.38, 0.22).lerp(_surface_color, 0.3)
			elif biome == "dunes":
				col = Color(0.72, 0.62, 0.35).lerp(_surface_color, 0.25)
			elif biome == "crater":
				col = Color(0.25, 0.22, 0.2).lerp(_surface_color, 0.35)
			elif biome == "alpine" or h > 5.0:
				col = Color(0.55, 0.55, 0.58).lerp(_surface_color, 0.25)
			elif biome == "canyon" or bool(_Relief.is_canyon(wx, wz, _seed)):
				col = Color(0.35, 0.22, 0.15).lerp(_surface_color, 0.4)
			elif biome == "river" or bool(_Relief.is_river(wx, wz, _seed, _relief_profile)):
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


func cache_count() -> int:
	return _mesh_cache.size()


func is_parked() -> bool:
	return not _active


func body_seed() -> int:
	return _seed


func refresh_all_xforms() -> void:
	for c in _live.keys():
		_refresh_xform(c)


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
