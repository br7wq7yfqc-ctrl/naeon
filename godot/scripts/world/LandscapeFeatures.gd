extends Node3D
class_name LandscapeFeatures
## Procedural landscape accents (mesa pillars, dune ridges) — pool + cell stream.

const _Math = preload("res://scripts/world/SurfaceChunkMath.gd")
const _Relief = preload("res://scripts/world/PlanetRelief.gd")
const CELL_M := 48.0
const STREAM_HZ := 0.55
const MAX_PROPS := 10

var _planet: Node3D
var _radius: float = 1200.0
var _observer: Node3D
var _seed: int = 1
var _planet_id: String = "Nex-Prime"
var _profile: Dictionary = {}
var _props: Array = []
var _accum: float = 0.0
var _last_cell: Vector2i = Vector2i(999999, 999999)


func setup(planet: Node3D, radius: float, planet_id: String, seed_i: int = 11) -> void:
	_planet = planet
	_radius = radius
	_planet_id = planet_id
	_seed = seed_i
	_profile = _Relief.profile_for_planet(planet_id)
	if _props.is_empty():
		_build_pool()


func set_observer(n: Node3D) -> void:
	_observer = n
	_last_cell = Vector2i(999999, 999999)


func _ready() -> void:
	set_process(true)
	if _props.is_empty() and _planet != null:
		_build_pool()


func _build_pool() -> void:
	var gq := get_node_or_null("/root/GraphicsQuality")
	var n: int = MAX_PROPS
	if gq and int(gq.tier) == 0:
		n = 6
	for i in n:
		var root := Node3D.new()
		root.name = "LF_%d" % i
		var mi := MeshInstance3D.new()
		var kind := i % 3
		if kind == 0:
			var box := BoxMesh.new()
			box.size = Vector3(2.2, 5.5, 2.2)
			mi.mesh = box
		elif kind == 1:
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.6
			cyl.bottom_radius = 1.4
			cyl.height = 3.5
			mi.mesh = cyl
		else:
			var pr := PrismMesh.new()
			pr.size = Vector3(2.5, 1.2, 4.0)
			mi.mesh = pr
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.35, 0.25)
		mat.roughness = 0.95
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		root.visible = false
		add_child(root)
		_props.append(root)
	print("[LandscapeFeatures] pool=", n, " planet=", _planet_id)


func _process(delta: float) -> void:
	_accum += delta
	if _accum < STREAM_HZ:
		return
	_accum = 0.0
	if _planet == null or _observer == null or not is_instance_valid(_observer):
		return
	var dist: float = _observer.global_position.distance_to(_planet.global_position)
	var alt: float = dist - _radius
	if alt > 140.0 or alt < -10.0:
		for p in _props:
			if p:
				p.visible = false
		return
	var cell: Vector2i = _Math.cell_of(_planet.global_position, _radius, _observer.global_position, CELL_M)
	if cell == _last_cell:
		return
	_last_cell = cell
	_place(cell)


func _place(cell: Vector2i) -> void:
	var ring: Array = _Math.ring_cells(cell, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 19 + cell.x * 7 + cell.y
	var placed := 0
	for c in ring:
		if placed >= _props.size():
			break
		var wx: float = float(c.x) * CELL_M + rng.randf_range(-8.0, 8.0)
		var wz: float = float(c.y) * CELL_M + rng.randf_range(-8.0, 8.0)
		var h: float = float(_Relief.height_at(wx, wz, _seed, _profile))
		var biome: String = str(_Relief.biome_hint(wx, wz, h, _seed, _profile))
		if biome not in ["mesa", "dunes", "crater", "alpine", "canyon"]:
			continue
		var xform: Transform3D = _Math.cell_transform(_planet.global_position, _radius, c, CELL_M, h)
		var p: Node3D = _props[placed]
		p.global_transform = xform
		p.scale = Vector3.ONE * rng.randf_range(0.7, 1.4)
		var mi = p.get_child(0) as MeshInstance3D
		if mi and mi.material_override is StandardMaterial3D:
			var mat := mi.material_override as StandardMaterial3D
			match biome:
				"mesa":
					mat.albedo_color = Color(0.55, 0.38, 0.22)
				"dunes":
					mat.albedo_color = Color(0.75, 0.65, 0.35)
				"crater":
					mat.albedo_color = Color(0.3, 0.28, 0.26)
				"canyon":
					mat.albedo_color = Color(0.4, 0.25, 0.15)
				_:
					mat.albedo_color = Color(0.5, 0.5, 0.52)
		p.visible = true
		placed += 1
	for i in range(placed, _props.size()):
		_props[i].visible = false
