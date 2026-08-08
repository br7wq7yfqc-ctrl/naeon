extends Node3D
class_name CaveMouthField
## Prototype cave mouths near canyons — dark portals (interiors later).

const _Math = preload("res://scripts/world/SurfaceChunkMath.gd")
const _Relief = preload("res://scripts/world/PlanetRelief.gd")

const CELL_M := 56.0
const STREAM_HZ := 0.6
const MAX_MOUTHS := 5

var _planet: Node3D
var _radius: float = 1200.0
var _observer: Node3D
var _seed: int = 1
var _planet_id: String = "Nex-Prime"
var _profile: Dictionary = {}
var _accum: float = 0.0
var _mouths: Array = []


func setup(planet: Node3D, radius: float, planet_id: String, seed_i: int = 5) -> void:
	_planet = planet
	_radius = radius
	_planet_id = planet_id
	_seed = seed_i
	_profile = _Relief.profile_for_planet(planet_id)
	if _mouths.is_empty():
		_build_mouths()


func set_observer(n: Node3D) -> void:
	_observer = n


func _ready() -> void:
	set_process(true)
	if _mouths.is_empty() and _planet != null:
		_build_mouths()


func _build_mouths() -> void:
	for i in MAX_MOUTHS:
		var root := Node3D.new()
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.4
		cm.bottom_radius = 1.8
		cm.height = 0.35
		cm.radial_segments = 12
		mi.mesh = cm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.02, 0.02, 0.04, 0.95)
		mat.emission_enabled = true
		mat.emission = Color(0.05, 0.08, 0.12)
		mat.emission_energy_multiplier = 0.4
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		var lab := Label3D.new()
		lab.text = "CAVE"
		lab.font_size = 22
		lab.position = Vector3(0, 1.2, 0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.modulate = Color(0.6, 0.7, 0.8, 0.7)
		root.add_child(lab)
		root.visible = false
		add_child(root)
		_mouths.append(root)
	print("[CaveMouthField] prototype n=", MAX_MOUTHS, " planet=", _planet_id)


func _process(delta: float) -> void:
	_accum += delta
	if _accum < STREAM_HZ:
		return
	_accum = 0.0
	if _planet == null or _observer == null or not is_instance_valid(_observer):
		return
	if not bool(_profile.get("caves", true)):
		return
	var dist: float = _observer.global_position.distance_to(_planet.global_position)
	var alt: float = dist - _radius
	if alt > 90.0 or alt < -15.0:
		for m in _mouths:
			if m:
				m.visible = false
		return
	var cell: Vector2i = _Math.cell_of(_planet.global_position, _radius, _observer.global_position, CELL_M)
	var ring: Array = _Math.ring_cells(cell, 2)
	var placed := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 31 + cell.x * 17 + cell.y
	for c in ring:
		if placed >= _mouths.size():
			break
		var wx: float = float(c.x) * CELL_M + rng.randf_range(-8.0, 8.0)
		var wz: float = float(c.y) * CELL_M + rng.randf_range(-8.0, 8.0)
		if not bool(_Relief.is_canyon(wx, wz, _seed)):
			continue
		var open: float = float(_Relief.cave_openness(wx, wz, -1.0, _seed, _profile))
		if open < 0.35:
			continue
		var h: float = float(_Relief.height_at(wx, wz, _seed, _profile))
		var xform: Transform3D = _Math.cell_transform(_planet.global_position, _radius, c, CELL_M, h + 0.4)
		var mouth: Node3D = _mouths[placed]
		mouth.global_transform = xform
		mouth.scale = Vector3.ONE * (0.9 + open * 0.6)
		mouth.visible = true
		placed += 1
	for i in range(placed, _mouths.size()):
		_mouths[i].visible = false
