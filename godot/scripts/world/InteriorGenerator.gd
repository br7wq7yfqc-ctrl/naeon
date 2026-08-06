extends RefCounted
class_name InteriorGenerator
## Procedural station/ship interiors — modular neon rooms (0 Tripo).
## Local pocket geometry; no full station mesh required.

const _NEON_CX := Color(0.15, 0.85, 1.0)
const _NEON_GR := Color(0.95, 0.12, 0.42)

static func build_station(faction: String = "Cybernex") -> Node3D:
	var root := Node3D.new()
	root.name = "StationInterior"
	var neon := _NEON_GR if faction == "gROT" else _NEON_CX
	# Rooms along +Z
	_room(root, Vector3(0, 0, 0), Vector3(12, 4, 10), "Foyer", neon)
	_room(root, Vector3(0, 0, 14), Vector3(6, 3.5, 16), "Corridor", neon.darkened(0.1))
	_room(root, Vector3(0, 0, 30), Vector3(14, 5, 12), "OpsBay", neon)
	_room(root, Vector3(10, 0, 14), Vector3(8, 3.5, 8), "Quarters", neon.lightened(0.05))
	_room(root, Vector3(-10, 0, 14), Vector3(8, 3.5, 8), "Storage", neon.darkened(0.15))
	# Floor lights strip
	_strip_light(root, Vector3(0, 0.05, 14), Vector3(0.4, 0.08, 28), neon)
	# Exit marker at foyer back
	var exit := Area3D.new()
	exit.name = "ExitVolume"
	exit.collision_layer = 0
	exit.collision_mask = 2  # player
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 2)
	cs.shape = box
	exit.add_child(cs)
	exit.position = Vector3(0, 1.5, -6)
	root.add_child(exit)
	var elabel := Label3D.new()
	elabel.text = "EXIT  [I]"
	elabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	elabel.font_size = 48
	elabel.position = Vector3(0, 2.5, -6)
	elabel.modulate = neon
	root.add_child(elabel)
	# Spawn point
	var spawn := Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = Vector3(0, 1.0, 2)
	root.add_child(spawn)
	return root

static func build_ship(faction: String = "Cybernex") -> Node3D:
	var root := Node3D.new()
	root.name = "ShipInterior"
	var neon := _NEON_GR if faction == "gROT" else _NEON_CX
	_room(root, Vector3(0, 0, 0), Vector3(5, 2.8, 8), "Cockpit", neon)
	_room(root, Vector3(0, 0, 8), Vector3(4, 2.6, 6), "MidDeck", neon.darkened(0.08))
	_room(root, Vector3(0, 0, 14), Vector3(5, 2.8, 5), "Cargo", neon.darkened(0.2))
	_strip_light(root, Vector3(0, 2.4, 7), Vector3(0.25, 0.06, 16), neon)
	var exit := Area3D.new()
	exit.name = "ExitVolume"
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.2, 1.5)
	cs.shape = box
	exit.add_child(cs)
	exit.position = Vector3(0, 1.2, -4.2)
	root.add_child(exit)
	var spawn := Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = Vector3(0, 0.9, 1)
	root.add_child(spawn)
	var elabel := Label3D.new()
	elabel.text = "HATCH  [I]"
	elabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	elabel.font_size = 36
	elabel.position = Vector3(0, 2.0, -4.2)
	elabel.modulate = neon
	root.add_child(elabel)
	return root

static func _room(parent: Node3D, pos: Vector3, size: Vector3, rname: String, neon: Color) -> void:
	var room := Node3D.new()
	room.name = rname
	room.position = pos
	parent.add_child(room)
	# Floor
	_box_mesh(room, Vector3(0, 0, 0), Vector3(size.x, 0.2, size.z), Color(0.06, 0.07, 0.09), true)
	# Ceiling
	_box_mesh(room, Vector3(0, size.y, 0), Vector3(size.x, 0.15, size.z), Color(0.05, 0.06, 0.08), true)
	# Walls (open on -Z/+Z for corridor flow — leave gaps)
	var wall_c := Color(0.08, 0.09, 0.12)
	_box_mesh(room, Vector3(-size.x * 0.5, size.y * 0.5, 0), Vector3(0.2, size.y, size.z), wall_c, true)
	_box_mesh(room, Vector3(size.x * 0.5, size.y * 0.5, 0), Vector3(0.2, size.y, size.z), wall_c, true)
	# Neon edge trim
	_box_mesh(room, Vector3(0, 0.15, -size.z * 0.48), Vector3(size.x * 0.9, 0.06, 0.08), neon, false, true)
	_box_mesh(room, Vector3(0, size.y - 0.2, 0), Vector3(size.x * 0.5, 0.05, size.z * 0.5), neon, false, true)

static func _strip_light(parent: Node3D, pos: Vector3, size: Vector3, neon: Color) -> void:
	_box_mesh(parent, pos, size, neon, false, true)

static func _box_mesh(parent: Node3D, pos: Vector3, size: Vector3, color: Color, collision: bool, emit: bool = false) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mat.metallic = 0.35
	if emit:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.2
	mi.material_override = mat
	parent.add_child(mi)
	if collision:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
