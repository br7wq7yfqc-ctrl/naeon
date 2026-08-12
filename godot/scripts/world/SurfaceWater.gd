extends Node3D
class_name SurfaceWater
## Near-surface sea planes + shore foam. Samples PlanetRelief.

const _Math = preload("res://scripts/world/SurfaceChunkMath.gd")
const _Relief = preload("res://scripts/world/PlanetRelief.gd")

const CELL_M := 48.0
const STREAM_HZ := 0.55
const POOL_N := 10

var _planet: Node3D
var _radius: float = 1200.0
var _observer: Node3D
var _seed: int = 1
var _planet_id: String = "Nex-Prime"
var _profile: Dictionary = {}
var _accum: float = 0.0
var _last_cell: Vector2i = Vector2i(999999, 999999)
var _planes: Array = []
var _foams: Array = []


func setup(planet: Node3D, radius: float, planet_id: String, seed_i: int = 3) -> void:
	_planet = planet
	_radius = radius
	_planet_id = planet_id
	_seed = seed_i
	_profile = _Relief.profile_for_planet(planet_id)
	if _planes.is_empty():
		_spawn_pool()


func set_observer(n: Node3D) -> void:
	_observer = n
	_last_cell = Vector2i(999999, 999999)


func _ready() -> void:
	set_process(true)
	if _planet != null and _planes.is_empty():
		_spawn_pool()


func _spawn_pool() -> void:
	var gq := get_node_or_null("/root/GraphicsQuality")
	var n: int = POOL_N
	if gq != null:
		match int(gq.tier):
			0:
				n = 4
			2, 3:
				n = 10
	for i in n:
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(CELL_M * 0.95, CELL_M * 0.95)
		pm.subdivide_width = 3
		pm.subdivide_depth = 3
		mi.mesh = pm
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.08, 0.32, 0.52, 0.55)
		mat.emission_enabled = true
		mat.emission = Color(0.05, 0.25, 0.45)
		mat.emission_energy_multiplier = 0.6
		mat.roughness = 0.15
		mat.metallic = 0.35
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_planes.append(mi)
		var foam := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = CELL_M * 0.28
		tm.outer_radius = CELL_M * 0.34
		tm.rings = 6
		tm.ring_segments = 12
		foam.mesh = tm
		var fm := StandardMaterial3D.new()
		fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fm.albedo_color = Color(0.85, 0.92, 1.0, 0.35)
		fm.emission_enabled = true
		fm.emission = Color(0.7, 0.85, 1.0)
		fm.emission_energy_multiplier = 1.2
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.cull_mode = BaseMaterial3D.CULL_DISABLED
		foam.material_override = fm
		foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		foam.visible = false
		add_child(foam)
		_foams.append(foam)
	print("[SurfaceWater] pool=", n, " planet=", _planet_id)


func _process(delta: float) -> void:
	_accum += delta
	var hz := STREAM_HZ
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and int(gq.tier) == 0:
		hz = 0.8
	elif gq and int(gq.tier) == 1:
		hz = STREAM_HZ * 1.25
	if _accum < hz:
		return
	_accum = 0.0
	_wave(0.0)
	if _planet == null or _observer == null or not is_instance_valid(_observer):
		return
	var dist: float = _observer.global_position.distance_to(_planet.global_position)
	var alt: float = dist - _radius
	if alt > 180.0 or alt < -20.0:
		_hide_all()
		return
	var cell: Vector2i = _Math.cell_of(_planet.global_position, _radius, _observer.global_position, CELL_M)
	if cell != _last_cell:
		_last_cell = cell
		_place_around(cell)


func _hide_all() -> void:
	for mi in _planes:
		if mi and is_instance_valid(mi):
			mi.visible = false
	for f in _foams:
		if f and is_instance_valid(f):
			f.visible = false


func _place_around(center: Vector2i) -> void:
	var sea: float = float(_profile.get("sea_level", -0.35))
	if sea < -1.2:
		_hide_all()
		return
	var cells: Array = _Math.ring_cells(center, 2)
	var used := 0
	# Score wet cells: shore band preferred for readability
	var scored: Array = []
	for c in cells:
		var cell: Vector2i = c
		var wx: float = float(cell.x) * CELL_M
		var wz: float = float(cell.y) * CELL_M
		var h: float = float(_Relief.height_at(wx, wz, _seed, _profile))
		var river: bool = bool(_Relief.is_river(wx, wz, _seed, _profile))
		var wet: bool = h <= sea + 0.25 or river
		if not wet:
			continue
		var shore: float = 1.0 - clampf(absf(h - sea) / 1.2, 0.0, 1.0)
		scored.append({"cell": cell, "wx": wx, "wz": wz, "h": h, "river": river, "score": shore + (0.3 if river else 0.0)})
	scored.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))
	for item in scored:
		if used >= _planes.size():
			break
		var cell: Vector2i = item["cell"]
		var wx: float = float(item["wx"])
		var wz: float = float(item["wz"])
		var h: float = float(item["h"])
		var xform: Transform3D = _Math.cell_transform(_planet.global_position, _radius, cell, CELL_M, sea + 0.08)
		var mi: MeshInstance3D = _planes[used]
		mi.global_transform = xform
		mi.visible = true
		var mat := mi.material_override as StandardMaterial3D
		if mat:
			if bool(item.get("river", false)) and h > sea:
				mat.albedo_color = Color(0.12, 0.38, 0.48, 0.45)
				mi.scale = Vector3(0.45, 1.0, 0.45)
			else:
				mat.albedo_color = Color(0.08, 0.32, 0.52, 0.55)
				mi.scale = Vector3.ONE
		var foam: MeshInstance3D = _foams[used]
		if h > sea - 0.2 and h < sea + 0.7:
			foam.global_transform = xform
			foam.visible = true
		else:
			foam.visible = false
		used += 1
	for i in range(used, _planes.size()):
		_planes[i].visible = false
		_foams[i].visible = false


func _wave(_delta: float) -> void:
	## Emission/alpha only — never mutate position after global_transform (terrain "dance").
	var t: float = Time.get_ticks_msec() * 0.001
	for mi in _planes:
		if mi == null or not is_instance_valid(mi) or not mi.visible:
			continue
		var mat := mi.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 0.4 + 0.3 * sin(t * 1.1 + float(mi.get_instance_id() % 97) * 0.1)
			var c := mat.albedo_color
			c.a = 0.5 + 0.08 * sin(t * 0.85)
			mat.albedo_color = c
	for foam in _foams:
		if foam == null or not is_instance_valid(foam) or not foam.visible:
			continue
		var fm := foam.material_override as StandardMaterial3D
		if fm:
			fm.emission_energy_multiplier = 0.9 + 0.6 * sin(t * 2.2 + float(foam.get_instance_id() % 13))
			var fc := fm.albedo_color
			fc.a = 0.28 + 0.12 * sin(t * 1.7)
			fm.albedo_color = fc
		# Soft scale pulse only (local scale — OK)
		var s := 1.0 + 0.04 * sin(t * 1.5)
		foam.scale = Vector3(s, 1.0, s)


func _park_all() -> void:
	set_process(false)
	visible = false

