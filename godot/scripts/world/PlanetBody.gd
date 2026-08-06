extends Node3D
class_name PlanetBody
## Spherical planet with atmosphere shell + surface gravity + optional base pads.
## Playable free flight around + surface walk with radial gravity.

@export var planet_name: String = "Aexion-III"
@export var radius: float = 1200.0
@export var atmosphere_height: float = 280.0
@export var gravity: float = 9.2
@export var surface_color: Color = Color(0.12, 0.22, 0.16)
@export var atmosphere_color: Color = Color(0.35, 0.55, 0.95, 0.12)
@export var faction_base: String = "Cybernex"
@export var has_base: bool = true

var _mesh: MeshInstance3D
var _atmo: MeshInstance3D
var _body: StaticBody3D
var _pads: Array[Node3D] = []

func _ready() -> void:
	_build()

func _build() -> void:
	var segs := 64
	if Engine.has_singleton("GraphicsQuality") or get_node_or_null("/root/GraphicsQuality"):
		var gq = get_node_or_null("/root/GraphicsQuality")
		if gq:
			segs = gq.planet_segments
	# Core sphere
	_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = segs
	sm.rings = int(segs / 2)
	_mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = surface_color
	mat.roughness = 0.92
	mat.metallic = 0.05
	# Cheap "terrain" via triplanar-ish: just vertex-ish color noise via emission low
	mat.emission_enabled = true
	mat.emission = surface_color * 0.08
	mat.emission_energy_multiplier = 0.35
	_mesh.material_override = mat
	add_child(_mesh)
	# Collision
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	var col := CollisionShape3D.new()
	var ss := SphereShape3D.new()
	ss.radius = radius
	col.shape = ss
	_body.add_child(col)
	add_child(_body)
	# Atmosphere shell (transparent)
	_atmo = MeshInstance3D.new()
	var am := SphereMesh.new()
	am.radius = radius + atmosphere_height
	am.height = (radius + atmosphere_height) * 2.0
	am.radial_segments = max(24, segs / 2)
	am.rings = max(12, segs / 4)
	_atmo.mesh = am
	var amat := StandardMaterial3D.new()
	amat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	amat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	amat.albedo_color = atmosphere_color
	amat.cull_mode = BaseMaterial3D.CULL_FRONT  # inner face from outside
	amat.no_depth_test = false
	_atmo.material_override = amat
	add_child(_atmo)
	# Pads on surface (north-ish + equator)
	if has_base:
		_spawn_pad("Pad_North", Vector3.UP)
		_spawn_pad("Pad_Eq", Vector3(1, 0.15, 0).normalized())
		_spawn_pad("Pad_Far", Vector3(-0.7, 0.2, 0.7).normalized())

func _spawn_pad(pad_name: String, dir: Vector3) -> void:
	dir = dir.normalized()
	var pad_root := Node3D.new()
	pad_root.name = pad_name
	add_child(pad_root)
	# Position slightly above surface
	var pos: Vector3 = dir * (radius + 2.0)
	# Orient pad so +Y faces outward (local up = radial)
	var y := dir
	var x := y.cross(Vector3(0, 0, 1))
	if x.length() < 0.05:
		x = y.cross(Vector3(1, 0, 0))
	x = x.normalized()
	var z := x.cross(y).normalized()
	# Local transform: position in parent (planet) space
	pad_root.transform = Transform3D(Basis(x, y, z), dir * (radius + 2.0))

	# Visual pad plate
	var plate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(28, 1.2, 28)
	plate.mesh = box
	var pmat := StandardMaterial3D.new()
	pmat.metallic = 0.65
	pmat.roughness = 0.35
	pmat.emission_enabled = true
	if faction_base == "gROT":
		pmat.albedo_color = Color(0.2, 0.05, 0.08)
		pmat.emission = Color(0.9, 0.15, 0.3)
	else:
		pmat.albedo_color = Color(0.06, 0.1, 0.14)
		pmat.emission = Color(0.2, 0.8, 1.0)
	pmat.emission_energy_multiplier = 1.4
	plate.material_override = pmat
	pad_root.add_child(plate)
	# Collision for pad
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(28, 1.2, 28)
	cs.shape = bs
	sb.add_child(cs)
	pad_root.add_child(sb)
	# Marker for ship land snap
	pad_root.set_meta("landing_pad", true)
	pad_root.set_meta("planet", self)
	pad_root.set_meta("pad_up", dir)
	_pads.append(pad_root)
	# Try HQ GLB pad if available
	call_deferred("_try_glb_pad", pad_root)

func _try_glb_pad(pad_root: Node3D) -> void:
	var ap = load("res://scripts/assets/AssetPaths.gd")
	if ap == null:
		return
	var rel := "environments/landing_pad/landing_pad_cybernex_lod1.glb"
	if faction_base == "gROT":
		rel = "environments/landing_pad/landing_pad_grot_lod1.glb"
	var path: String = ap.resolve(rel)
	if path == "" or not FileAccess.file_exists(path):
		return
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

func altitude_of(global_pos: Vector3) -> float:
	return global_pos.distance_to(global_position) - radius

func gravity_at(global_pos: Vector3) -> Vector3:
	var to_c: Vector3 = global_position - global_pos
	var dist: float = to_c.length()
	if dist < 0.001:
		return Vector3.ZERO
	var alt: float = dist - radius
	# Only pull inside atmosphere + a bit above
	if alt > atmosphere_height * 1.8:
		return Vector3.ZERO
	var strength: float = gravity
	if alt > 0.0:
		# Fade gravity in upper atmosphere
		var t: float = clamp(1.0 - alt / (atmosphere_height * 1.8), 0.0, 1.0)
		strength *= t * t
	return to_c.normalized() * strength

func nearest_pad(global_pos: Vector3) -> Node3D:
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
