extends RefCounted
class_name InteriorGenerator
## Procedural station/ship interiors — modular neon rooms (0 Tripo).
## Local pocket geometry; no full station mesh required.

const _NEON_CX := Color(0.15, 0.85, 1.0)
const _NEON_GR := Color(0.95, 0.12, 0.42)

static func _try_glb(parent: Node3D, rel: String, pos: Vector3, scl: float = 1.0) -> void:
	var ap = load("res://scripts/assets/AssetPaths.gd")
	if ap == null:
		return
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
	parent.add_child(root)
	root.position = pos
	root.scale = Vector3.ONE * scl

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
	var fx := "grot" if faction == "gROT" else "cybernex"
	_try_glb(root, "props/control_console/control_console_%s_lod1.glb" % fx, Vector3(0, 0, 30), 1.2)
	_try_glb(root, "props/med_station/med_station_%s_lod1.glb" % fx, Vector3(8, 0, 2), 1.0)
	_try_glb(root, "colony/resource_crystal/resource_crystal_%s_lod2.glb" % fx, Vector3(-6, 0, 28), 0.8)
	_try_glb(root, "props/ship_cockpit_console/ship_cockpit_console_%s_lod1.glb" % fx, Vector3(-4, 0, 30), 1.0)
	_try_glb(root, "colony/surface_crystal_spire/surface_crystal_spire_%s_lod2.glb" % fx, Vector3(5, 0, 32), 0.9)
	_try_glb(root, "props/holo_projector/holo_projector_%s_lod2.glb" % fx, Vector3(0, 0, 28), 1.1)
	_interior_point_lights(root, neon)
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
	_add_neon_strips(root, faction)
	return root

static func build_ship(faction: String = "Cybernex") -> Node3D:
	var root := Node3D.new()
	root.name = "ShipInterior"
	var neon := _NEON_GR if faction == "gROT" else _NEON_CX
	_room(root, Vector3(0, 0, 0), Vector3(5, 2.8, 8), "Cockpit", neon)
	_room(root, Vector3(0, 0, 8), Vector3(4, 2.6, 6), "MidDeck", neon.darkened(0.08))
	_room(root, Vector3(0, 0, 14), Vector3(5, 2.8, 5), "Cargo", neon.darkened(0.2))
	_strip_light(root, Vector3(0, 2.4, 7), Vector3(0.25, 0.06, 16), neon)
	# ship decorate
	var fx2 := "grot" if faction == "gROT" else "cybernex"
	_try_glb(root, "props/storage_barrel/storage_barrel_%s_lod2.glb" % fx2, Vector3(1.2, 0, 14), 0.6)
	_try_glb(root, "props/control_console/control_console_%s_lod2.glb" % fx2, Vector3(0, 0, 0.5), 0.7)
	_try_glb(root, "props/ship_cockpit_console/ship_cockpit_console_%s_lod1.glb" % fx2, Vector3(0, 0, -0.2), 0.85)
	_try_glb(root, "props/sci_fi_crate/sci_fi_crate_%s_lod2.glb" % fx2, Vector3(-1.4, 0, 13), 0.55)
	_interior_point_lights(root, neon)

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
	_add_neon_strips(root, faction)
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

static func _add_neon_strips(root: Node3D, fac: String) -> void:
	var col := Color(0.2, 0.85, 1.0) if fac == "Cybernex" else Color(0.95, 0.2, 0.45)
	for i in 4:
		var mi := MeshInstance3D.new()
		mi.name = "neon_strip_%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(0.08, 0.08, 6.0)
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 3.5
		mi.material_override = mat
		var ang := float(i) * TAU / 4.0
		mi.position = Vector3(cos(ang) * 3.5, 2.2, sin(ang) * 3.5)
		mi.rotation.y = -ang
		root.add_child(mi)
	var light := OmniLight3D.new()
	light.light_color = col
	light.light_energy = 1.8
	light.omni_range = 18.0
	light.position = Vector3(0, 3.0, 0)
	root.add_child(light)


static func _interior_point_lights(root: Node3D, neon: Color) -> void:
	## Soft readable interiors (RTX 1060 friendly — few omnis).
	var spots := [
		Vector3(0, 2.6, 0),
		Vector3(0, 2.8, 14),
		Vector3(0, 3.0, 30),
		Vector3(8, 2.4, 14),
		Vector3(-8, 2.4, 14),
	]
	for pos in spots:
		var o := OmniLight3D.new()
		o.light_color = neon.lerp(Color(1, 0.95, 0.85), 0.35)
		o.light_energy = 1.8
		o.omni_range = 11.0
		o.omni_attenuation = 1.6
		o.shadow_enabled = false
		o.position = pos
		root.add_child(o)
