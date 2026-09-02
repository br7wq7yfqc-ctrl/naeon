extends RefCounted
class_name InteriorGenerator
## Procedural station/ship interiors — modular neon rooms (0 Tripo).
## Local pocket geometry; no full station mesh required.

const _NEON_CX := Color(0.15, 0.85, 1.0)
const _NEON_GR := Color(0.95, 0.12, 0.42)
static var _glb_cache: Dictionary = {}  # abs path -> PackedScene

static func _try_glb(parent: Node3D, rel: String, pos: Vector3, scl: float = 1.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var ap = load("res://scripts/assets/AssetPaths.gd")
	if ap == null:
		return
	var path: String = ap.resolve(rel)
	if path == "" or not FileAccess.file_exists(path):
		return
	var packed: PackedScene = null
	if _glb_cache.has(path):
		packed = _glb_cache[path]
	else:
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(path, state) != OK:
			return
		var built := doc.generate_scene(state)
		if built == null:
			return
		packed = PackedScene.new()
		var err := packed.pack(built)
		if err != OK:
			# Fallback: use built node once, no cache
			parent.add_child(built)
			built.position = pos
			built.scale = Vector3.ONE * scl
			return
		if _glb_cache.size() > 24:
			_glb_cache.clear()
		_glb_cache[path] = packed
	var inst: Node = packed.instantiate()
	if inst == null:
		return
	parent.add_child(inst)
	if inst is Node3D:
		(inst as Node3D).position = pos
		(inst as Node3D).scale = Vector3.ONE * scl

static func build_station(faction: String = "Cybernex", hatch_to: String = "pad") -> Node3D:
	var root := Node3D.new()
	root.name = "StationInterior"
	root.set_meta("interior_kind", "station")
	root.set_meta("site_pin", "")
	var dest := hatch_to if hatch_to == "dock" else "pad"
	var neon := _NEON_GR if faction == "gROT" else _NEON_CX
	# Rooms along +Z — foyer / corridor / ops. Not a ship cockpit.
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
	exit.set_meta("leads_to", dest)
	exit.collision_layer = 0
	exit.collision_mask = 2  # player
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 2)
	cs.shape = box
	exit.add_child(cs)
	exit.position = Vector3(0, 1.5, -6)
	root.add_child(exit)
	if DisplayServer.get_name() != "headless":
		var elabel := Label3D.new()
		elabel.name = "HatchLabel"
		elabel.text = "HATCH  [F/I]"
		elabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		elabel.font_size = 48
		elabel.position = Vector3(0, 2.5, -6)
		elabel.modulate = neon
		root.add_child(elabel)
	# Spawn point
	var spawn := Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = Vector3(0, 1.35, 2)
	root.add_child(spawn)
	_add_neon_strips(root, faction)
	_door_portal(root, Vector3(0, 0, 7), neon, 6.0, "pocket")
	_door_portal(root, Vector3(0, 0, 22), neon, 6.0, "pocket")
	_door_portal(root, Vector3(5, 0, 14), neon, 8.0, "pocket")
	_door_portal(root, Vector3(0, 0, -6), neon, 6.0, dest)
	_console_volume(root, Vector3(0, 0, 30), neon, "OPS")
	_legal_seat(root, Vector3(-3.4, 0.2, 28.5), neon, "OpsSeat", "OpsSeatVolume", "OpsSeatLabel", "OPS SEAT", "ops")
	_attach_ambient(root, "station", neon)
	return root


static func build_hangar_bay(faction: String = "Cybernex") -> Node3D:
	## IN-A: catalog carrier bay pocket. Not a SITE_*. Not a ship cockpit.
	var root := Node3D.new()
	root.name = "HangarBayInterior"
	root.set_meta("interior_kind", "hangar_bay")
	root.set_meta("site_pin", "")
	var neon := _NEON_GR if faction == "gROT" else _NEON_CX
	var rooms: Array = [
		{"name": "HangarBay", "pos": Vector3(0, 0, 0), "size": Vector3(16, 6, 18)},
		{"name": "Airlock", "pos": Vector3(0, 0, 13), "size": Vector3(6, 3.4, 6)},
	]
	for room in rooms:
		_room(root, room["pos"], room["size"], str(room["name"]), neon)
	_strip_light(root, Vector3(0, 0.06, 6), Vector3(0.45, 0.08, 22), neon)
	_interior_point_lights(root, neon)
	var hatch_pos := Vector3(0, 1.2, 16.2)
	var exit := Area3D.new()
	exit.name = "ExitVolume"
	exit.set_meta("leads_to", "dock")
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.2, 2.4, 1.6)
	cs.shape = box
	exit.add_child(cs)
	exit.position = hatch_pos
	root.add_child(exit)
	var spawn := Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = Vector3(0, 1.35, -2)
	root.add_child(spawn)
	if DisplayServer.get_name() != "headless":
		var elabel := Label3D.new()
		elabel.name = "HatchLabel"
		elabel.text = "HATCH  [F/I]"
		elabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		elabel.font_size = 40
		elabel.position = hatch_pos + Vector3(0, 1.1, 0)
		elabel.modulate = neon
		root.add_child(elabel)
	_add_neon_strips(root, faction)
	_link_ship_rooms(root, rooms, neon)
	_door_portal(root, Vector3(hatch_pos.x, 0.0, hatch_pos.z), neon, 5.0, "dock")
	_console_volume(root, Vector3(4.5, 0, -2), neon, "BAY")
	_legal_seat(root, Vector3(-4.5, 0.2, -2.0), neon, "HangarSeat", "HangarSeatVolume", "HangarSeatLabel", "CARRIER PILOT", "carrier_pilot")
	_attach_ambient(root, "hangar_bay", neon)
	return root

static func build_ship(faction: String = "Cybernex") -> Node3D:
	var root := Node3D.new()
	root.name = "ShipInterior"
	root.set_meta("interior_kind", "ship")
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

	var hatch_pos := Vector3(0, 1.2, 16.4)
	var exit := Area3D.new()
	exit.name = "ExitVolume"
	exit.set_meta("leads_to", "eva")
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.2, 1.5)
	cs.shape = box
	exit.add_child(cs)
	exit.position = hatch_pos
	root.add_child(exit)
	var spawn := Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = Vector3(0, 1.25, 1)
	root.add_child(spawn)
	if DisplayServer.get_name() != "headless":
		var elabel := Label3D.new()
		elabel.name = "HatchLabel"
		elabel.text = "HATCH  [F/I]"
		elabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		elabel.font_size = 36
		elabel.position = hatch_pos + Vector3(0, 1.0, 0)
		elabel.modulate = neon
		root.add_child(elabel)
	_add_neon_strips(root, faction)
	_attach_ambient(root, "ship", neon)
	_ensure_seat_markers(root)
	_ensure_crew_seat(root, Vector3(-1.4, 0.2, 1.0), neon)
	_ensure_engineer_seat(root, Vector3(1.4, 0.2, 1.0), neon)
	_ensure_scanner_seat(root, Vector3(0.0, 0.2, 2.4), neon)
	_link_ship_rooms(root, [
		{"pos": Vector3(0, 0, 0), "size": Vector3(5, 2.8, 8)},
		{"pos": Vector3(0, 0, 8), "size": Vector3(4, 2.6, 6)},
		{"pos": Vector3(0, 0, 14), "size": Vector3(5, 2.8, 5)},
	], neon)
	_airlock_stub(root, hatch_pos, neon)
	_console_volume(root, Vector3(0, 0, 0.2), neon, "COCKPIT")
	return root

static func _room(parent: Node3D, pos: Vector3, size: Vector3, rname: String, neon: Color) -> void:
	var room := Node3D.new()
	room.name = rname
	room.position = pos
	parent.add_child(room)
	# Floor
	_box_mesh(room, Vector3(0, 0, 0), Vector3(size.x, 0.55, size.z), Color(0.22, 0.26, 0.32), true)
	_box_mesh(room, Vector3(0, -0.8, 0), Vector3(size.x + 1.0, 1.0, size.z + 1.0), Color(0.12, 0.13, 0.16), true)
	# Ceiling
	_box_mesh(room, Vector3(0, size.y, 0), Vector3(size.x, 0.15, size.z), Color(0.16, 0.18, 0.22), true)
	# Walls (open on -Z/+Z for corridor flow — leave gaps)
	var wall_c := Color(0.32, 0.36, 0.42)
	_box_mesh(room, Vector3(-size.x * 0.5, size.y * 0.5, 0), Vector3(0.2, size.y, size.z), wall_c, true)
	_box_mesh(room, Vector3(size.x * 0.5, size.y * 0.5, 0), Vector3(0.2, size.y, size.z), wall_c, true)
	# Neon edge trim
	_box_mesh(room, Vector3(0, 0.15, -size.z * 0.48), Vector3(size.x * 0.9, 0.06, 0.08), neon, false, true)
	_box_mesh(room, Vector3(0, size.y - 0.2, 0), Vector3(size.x * 0.5, 0.05, size.z * 0.5), neon, false, true)
	# Wall vent / panel detail
	_box_mesh(room, Vector3(-size.x * 0.48, size.y * 0.65, 0), Vector3(0.08, 0.35, size.z * 0.35), Color(0.12, 0.13, 0.15), false)
	_box_mesh(room, Vector3(size.x * 0.48, size.y * 0.65, 0), Vector3(0.08, 0.35, size.z * 0.35), Color(0.12, 0.13, 0.15), false)
	_box_mesh(room, Vector3(0, size.y * 0.55, -size.z * 0.48), Vector3(size.x * 0.25, 0.3, 0.06), neon.darkened(0.3), false, true)

static func _strip_light(parent: Node3D, pos: Vector3, size: Vector3, neon: Color) -> void:
	_box_mesh(parent, pos, size, neon, false, true)

static func _box_mesh(parent: Node3D, pos: Vector3, size: Vector3, color: Color, collision: bool, emit: bool = false) -> void:
	## Dummy mesh_storage errors on MeshInstance free (interior exit). Keep
	## collision/markers so mechanics still run; skip visual RIDs on headless.
	if DisplayServer.get_name() == "headless":
		if collision:
			var holder := Node3D.new()
			holder.position = pos
			parent.add_child(holder)
			var sb0 := StaticBody3D.new()
			sb0.collision_layer = 1
			var cs0 := CollisionShape3D.new()
			var sh0 := BoxShape3D.new()
			sh0.size = size
			cs0.shape = sh0
			sb0.add_child(cs0)
			holder.add_child(sb0)
		return
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
	# Compatibility / llvmpipe: shaded interiors read as black without IBL.
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = color
	if emit:
		mat.emission_energy_multiplier = 2.2
	else:
		mat.emission_energy_multiplier = 0.85
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
	if DisplayServer.get_name() == "headless":
		return
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
		o.light_energy = 4.2
		o.omni_range = 16.0
		o.omni_attenuation = 1.15
		o.shadow_enabled = false
		o.position = pos
		root.add_child(o)



static func _ensure_seat_markers(root: Node3D) -> void:
	if root == null:
		return
	if root.get_node_or_null("SeatVolume") == null:
		var sv := Marker3D.new()
		sv.name = "SeatVolume"
		sv.position = Vector3(0, 0.2, -1.2)
		root.add_child(sv)
	if root.get_node_or_null("SeatLabel") == null and DisplayServer.get_name() != "headless":
		var lab := Label3D.new()
		lab.name = "SeatLabel"
		lab.text = "PILOT SEAT"
		lab.font_size = 42
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.position = Vector3(0, 1.6, -1.2)
		lab.modulate = Color(0.3, 0.9, 1.0)
		root.add_child(lab)
	if root.get_node_or_null("SeatGlow") == null and DisplayServer.get_name() != "headless":
		var g := MeshInstance3D.new()
		g.name = "SeatGlow"
		if DisplayServer.get_name() == "headless":
			var glow_box := BoxMesh.new()
			glow_box.size = Vector3(0.7, 0.08, 0.7)
			g.mesh = glow_box
		else:
			var cm := CylinderMesh.new()
			cm.top_radius = 0.35
			cm.bottom_radius = 0.35
			cm.height = 0.08
			g.mesh = cm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.2, 0.85, 1.0, 0.7)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.85, 1.0)
		mat.emission_energy_multiplier = 2.0
		g.material_override = mat
		g.position = Vector3(0, 0.05, -1.2)
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.visible = false
		root.add_child(g)


static func build_from_profile(profile_id: String, faction: String = "Cybernex") -> Node3D:
	var cat = load("res://scripts/ship/ShipInteriorProfiles.gd")
	var prof: Dictionary = cat.profile(profile_id)
	var root := Node3D.new()
	root.name = "ShipInterior_%s" % str(prof.get("id", profile_id))
	root.set_meta("interior_kind", "ship")
	var neon := _NEON_GR if faction == "gROT" else _NEON_CX
	var fx := "grot" if faction == "gROT" else "cybernex"
	for room in prof.get("rooms", []):
		_room(root, room["pos"], room["size"], str(room["name"]), neon)
	for pr in prof.get("props", []):
		var tmpl: String = str(pr["rel"])
		var rel: String = tmpl % fx if "%s" in tmpl else tmpl.replace("cybernex", fx)
		_try_glb(root, rel, pr["pos"], float(pr.get("s", 1.0)))
	var seat_pos: Vector3 = prof.get("seat", Vector3(0, 1, 0))
	var crew_pos: Vector3 = prof.get("crew_seat", seat_pos + Vector3(-1.35, 0.0, 1.3))
	var eng_pos: Vector3 = prof.get("engineer_seat", seat_pos + Vector3(1.35, 0.0, 1.3))
	var scan_pos: Vector3 = prof.get("scanner_seat", seat_pos + Vector3(0.0, 0.0, 2.7))
	var hatch_pos: Vector3 = prof.get("hatch", Vector3(0, 1, 6))
	var seat := Marker3D.new()
	seat.name = "Seat"
	seat.position = seat_pos
	root.add_child(seat)
	var seat_area := Area3D.new()
	seat_area.name = "SeatVolume"
	seat_area.monitoring = false
	seat_area.monitorable = false
	var scs := CollisionShape3D.new()
	var sbox := BoxShape3D.new()
	sbox.size = Vector3(1.6, 2.0, 1.6)
	scs.shape = sbox
	seat_area.add_child(scs)
	seat_area.position = seat_pos
	root.add_child(seat_area)
	var exit := Area3D.new()
	exit.name = "ExitVolume"
	exit.set_meta("leads_to", "eva")
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.2, 1.5)
	cs.shape = box
	exit.add_child(cs)
	exit.position = hatch_pos
	root.add_child(exit)
	var spawn := Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = seat_pos + Vector3(0, 0.4, 1.2)
	root.add_child(spawn)
	if DisplayServer.get_name() != "headless":
		var elabel := Label3D.new()
		elabel.name = "HatchLabel"
		elabel.text = "AIRLOCK · HATCH [F/I]"
		elabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		elabel.font_size = 36
		elabel.position = hatch_pos + Vector3(0, 1.2, 0)
		elabel.modulate = neon
		root.add_child(elabel)
	_add_neon_strips(root, faction)
	_interior_point_lights(root, neon)
	
	_strip_light(root, Vector3(0, 2.3, 3.5), Vector3(0.22, 0.05, 10), neon)
	_ship_bulkheads(root, prof.get("rooms", []), neon)
	_hatch_arch(root, hatch_pos, neon)
	_seat_glow(root, seat_pos, neon)
	_ensure_crew_seat(root, crew_pos, neon)
	_ensure_engineer_seat(root, eng_pos, neon)
	_ensure_scanner_seat(root, scan_pos, neon)
	_interior_point_lights(root, neon)
	_add_neon_strips(root, faction)
	_attach_ambient(root, "ship", neon)
	_console_volume(root, seat_pos + Vector3(1.4, 0, 0.2), neon, "COCKPIT")
	_link_ship_rooms(root, prof.get("rooms", []), neon)
	_airlock_stub(root, hatch_pos, neon)
	return root



static func _ship_bulkheads(root: Node3D, rooms: Array, neon: Color) -> void:
	## Door-frame bulkheads between sequential rooms along +Z.
	if rooms.size() < 2:
		return
	for i in range(rooms.size() - 1):
		var a: Dictionary = rooms[i]
		var b: Dictionary = rooms[i + 1]
		var az: float = float(a["pos"].z) + float(a["size"].z) * 0.5
		var bz: float = float(b["pos"].z) - float(b["size"].z) * 0.5
		var mid_z: float = (az + bz) * 0.5
		var frame := Node3D.new()
		frame.name = "Bulkhead_%d" % i
		frame.position = Vector3(0, 0, mid_z)
		root.add_child(frame)
		# Left/right pillars + top lintel (walk-through center)
		_box_mesh(frame, Vector3(-1.35, 1.2, 0), Vector3(0.25, 2.4, 0.35), Color(0.1, 0.11, 0.14), true)
		_box_mesh(frame, Vector3(1.35, 1.2, 0), Vector3(0.25, 2.4, 0.35), Color(0.1, 0.11, 0.14), true)
		_box_mesh(frame, Vector3(0, 2.35, 0), Vector3(2.9, 0.2, 0.35), Color(0.1, 0.11, 0.14), true)
		_box_mesh(frame, Vector3(0, 2.2, 0), Vector3(2.4, 0.06, 0.12), neon, false, true)


static func _hatch_arch(root: Node3D, hatch_pos: Vector3, neon: Color) -> void:
	var arch := Node3D.new()
	arch.name = "HatchArch"
	arch.position = hatch_pos
	root.add_child(arch)
	_box_mesh(arch, Vector3(-1.1, 1.1, 0), Vector3(0.2, 2.2, 0.25), Color(0.09, 0.1, 0.12), true)
	_box_mesh(arch, Vector3(1.1, 1.1, 0), Vector3(0.2, 2.2, 0.25), Color(0.09, 0.1, 0.12), true)
	_box_mesh(arch, Vector3(0, 2.2, 0), Vector3(2.4, 0.18, 0.25), Color(0.09, 0.1, 0.12), true)
	_box_mesh(arch, Vector3(0, 0.08, 0), Vector3(2.0, 0.08, 0.5), neon, false, true)
	var ol := OmniLight3D.new()
	ol.light_color = neon
	ol.light_energy = 2.4
	ol.omni_range = 6.0
	ol.position = Vector3(0, 1.8, 0.3)
	ol.shadow_enabled = false
	arch.add_child(ol)


static func _seat_glow(root: Node3D, seat_pos: Vector3, neon: Color) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var seat_v := root.get_node_or_null("SeatVolume")
	# Pillar + ring + label — high readability for F pilot
	var pillar := MeshInstance3D.new()
	pillar.name = "SeatPillar"
	if DisplayServer.get_name() == "headless":
		var pillar_box := BoxMesh.new()
		pillar_box.size = Vector3(0.2, 1.8, 0.2)
		pillar.mesh = pillar_box
	else:
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.12
		cyl.height = 1.8
		pillar.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = neon
	mat.emission_enabled = true
	mat.emission = neon
	mat.emission_energy_multiplier = 2.2
	pillar.material_override = mat
	pillar.position = seat_pos + Vector3(0, 0.9, 0)
	pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(pillar)
	var ring := MeshInstance3D.new()
	ring.name = "SeatRing"
	if DisplayServer.get_name() == "headless":
		var ring_box := BoxMesh.new()
		ring_box.size = Vector3(1.44, 0.12, 1.44)
		ring.mesh = ring_box
	else:
		var tm := TorusMesh.new()
		tm.inner_radius = 0.55
		tm.outer_radius = 0.72
		tm.rings = 6
		tm.ring_segments = 16
		ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(neon.r, neon.g, neon.b, 0.55)
	rm.emission_enabled = true
	rm.emission = neon
	rm.emission_energy_multiplier = 1.8
	ring.material_override = rm
	ring.position = seat_pos + Vector3(0, 0.05, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	if DisplayServer.get_name() != "headless":
		var lab := Label3D.new()
		lab.name = "SeatLabel"
		lab.text = "PILOT SEAT  [F]"
		lab.font_size = 48
		lab.modulate = neon
		lab.position = seat_pos + Vector3(0, 2.1, 0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.no_depth_test = true
		root.add_child(lab)
	if seat_v is Node3D:
		pass

static func _ensure_crew_seat(root: Node3D, pos: Vector3, neon: Color) -> void:
	## MC-A: one extra legal seat in the ship pocket. Never named Seat/SeatVolume.
	## MC-B: that seat is named gunner — label only. F/I role stays crew.
	if root == null:
		return
	if root.get_node_or_null("CrewSeat") == null:
		_legal_seat(root, pos, neon, "CrewSeat", "CrewSeatVolume", "CrewSeatLabel", "CREW SEAT · GUNNER", "crew")
	var occ: Node = root.get_node_or_null("CrewSeatOccupied")
	if occ == null:
		occ = Marker3D.new()
		occ.name = "CrewSeatOccupied"
		(occ as Node3D).position = pos + Vector3(0.0, 1.1, 0.0)
		occ.set_meta("occupied", false)
		occ.set_meta("legal_seat", true)
		occ.visible = false
		root.add_child(occ)
	_stamp_crew_gunner(root)
	if DisplayServer.get_name() == "headless":
		return
	if root.get_node_or_null("CrewSeatPillar") != null:
		return
	var pillar := MeshInstance3D.new()
	pillar.name = "CrewSeatPillar"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.07
	cyl.bottom_radius = 0.1
	cyl.height = 1.6
	pillar.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = neon.lerp(Color(0.95, 0.75, 0.2), 0.35)
	mat.emission_enabled = true
	mat.emission = neon
	mat.emission_energy_multiplier = 1.8
	pillar.material_override = mat
	pillar.position = pos + Vector3(0, 0.8, 0)
	pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(pillar)
	var ring := MeshInstance3D.new()
	ring.name = "CrewSeatRing"
	var tm := TorusMesh.new()
	tm.inner_radius = 0.45
	tm.outer_radius = 0.62
	tm.rings = 6
	tm.ring_segments = 14
	ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(neon.r, neon.g, neon.b, 0.5)
	rm.emission_enabled = true
	rm.emission = neon
	rm.emission_energy_multiplier = 1.5
	ring.material_override = rm
	ring.position = pos + Vector3(0, 0.05, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)


static func _stamp_crew_gunner(root: Node3D) -> void:
	## MC-B: station_role is a SoftKnowledge / HUD name. Does not change F/I.
	if root == null:
		return
	for nm in ["CrewSeat", "CrewSeatVolume", "CrewSeatOccupied"]:
		var n: Node = root.get_node_or_null(nm)
		if n == null:
			continue
		n.set_meta("station_role", "gunner")
		n.set_meta("crew_role", "gunner")
	var lab: Node = root.get_node_or_null("CrewSeatLabel")
	if lab is Label3D and str((lab as Label3D).text).find("GUNNER") < 0:
		(lab as Label3D).text = "CREW SEAT · GUNNER"


static func _ensure_engineer_seat(root: Node3D, pos: Vector3, neon: Color) -> void:
	## MC-C: third legal seat in the ship pocket. Distinct offset from CrewSeat.
	## station_role engineer is a SoftKnowledge / HUD name. F/I role stays crew.
	if root == null:
		return
	if root.get_node_or_null("EngineerSeat") == null:
		_legal_seat(root, pos, neon, "EngineerSeat", "EngineerSeatVolume", "EngineerSeatLabel", "CREW SEAT · ENGINEER", "crew")
	var occ: Node = root.get_node_or_null("EngineerSeatOccupied")
	if occ == null:
		occ = Marker3D.new()
		occ.name = "EngineerSeatOccupied"
		(occ as Node3D).position = pos + Vector3(0.0, 1.1, 0.0)
		occ.set_meta("occupied", false)
		occ.set_meta("legal_seat", true)
		occ.visible = false
		root.add_child(occ)
	_stamp_crew_engineer(root)
	if DisplayServer.get_name() == "headless":
		return
	if root.get_node_or_null("EngineerSeatPillar") != null:
		return
	var pillar := MeshInstance3D.new()
	pillar.name = "EngineerSeatPillar"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.07
	cyl.bottom_radius = 0.1
	cyl.height = 1.6
	pillar.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = neon.lerp(Color(0.35, 0.95, 0.55), 0.4)
	mat.emission_enabled = true
	mat.emission = neon
	mat.emission_energy_multiplier = 1.8
	pillar.material_override = mat
	pillar.position = pos + Vector3(0, 0.8, 0)
	pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(pillar)
	var ring := MeshInstance3D.new()
	ring.name = "EngineerSeatRing"
	var tm := TorusMesh.new()
	tm.inner_radius = 0.45
	tm.outer_radius = 0.62
	tm.rings = 6
	tm.ring_segments = 14
	ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(neon.r, neon.g, neon.b, 0.5)
	rm.emission_enabled = true
	rm.emission = neon
	rm.emission_energy_multiplier = 1.5
	ring.material_override = rm
	ring.position = pos + Vector3(0, 0.05, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)


static func _stamp_crew_engineer(root: Node3D) -> void:
	## MC-C: station_role is a SoftKnowledge / HUD name. Does not change F/I.
	if root == null:
		return
	for nm in ["EngineerSeat", "EngineerSeatVolume", "EngineerSeatOccupied"]:
		var n: Node = root.get_node_or_null(nm)
		if n == null:
			continue
		n.set_meta("station_role", "engineer")
		n.set_meta("crew_role", "engineer")
	var lab: Node = root.get_node_or_null("EngineerSeatLabel")
	if lab is Label3D and str((lab as Label3D).text).find("ENGINEER") < 0:
		(lab as Label3D).text = "CREW SEAT · ENGINEER"


static func _ensure_scanner_seat(root: Node3D, pos: Vector3, neon: Color) -> void:
	## MC-D: fourth legal seat in the ship pocket. Distinct offset from CrewSeat / EngineerSeat.
	## station_role scanner is a SoftKnowledge / HUD name. F/I role stays crew.
	if root == null:
		return
	if root.get_node_or_null("ScannerSeat") == null:
		_legal_seat(root, pos, neon, "ScannerSeat", "ScannerSeatVolume", "ScannerSeatLabel", "CREW SEAT · SCANNER", "crew")
	var occ: Node = root.get_node_or_null("ScannerSeatOccupied")
	if occ == null:
		occ = Marker3D.new()
		occ.name = "ScannerSeatOccupied"
		(occ as Node3D).position = pos + Vector3(0.0, 1.1, 0.0)
		occ.set_meta("occupied", false)
		occ.set_meta("legal_seat", true)
		occ.visible = false
		root.add_child(occ)
	_stamp_crew_scanner(root)
	if DisplayServer.get_name() == "headless":
		return
	if root.get_node_or_null("ScannerSeatPillar") != null:
		return
	var pillar := MeshInstance3D.new()
	pillar.name = "ScannerSeatPillar"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.07
	cyl.bottom_radius = 0.1
	cyl.height = 1.6
	pillar.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = neon.lerp(Color(0.55, 0.75, 1.0), 0.4)
	mat.emission_enabled = true
	mat.emission = neon
	mat.emission_energy_multiplier = 1.8
	pillar.material_override = mat
	pillar.position = pos + Vector3(0, 0.8, 0)
	pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(pillar)
	var ring := MeshInstance3D.new()
	ring.name = "ScannerSeatRing"
	var tm := TorusMesh.new()
	tm.inner_radius = 0.45
	tm.outer_radius = 0.62
	tm.rings = 6
	tm.ring_segments = 14
	ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(neon.r, neon.g, neon.b, 0.5)
	rm.emission_enabled = true
	rm.emission = neon
	rm.emission_energy_multiplier = 1.5
	ring.material_override = rm
	ring.position = pos + Vector3(0, 0.05, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)


static func _stamp_crew_scanner(root: Node3D) -> void:
	## MC-D: station_role is a SoftKnowledge / HUD name. Does not change F/I.
	if root == null:
		return
	for nm in ["ScannerSeat", "ScannerSeatVolume", "ScannerSeatOccupied"]:
		var n: Node = root.get_node_or_null(nm)
		if n == null:
			continue
		n.set_meta("station_role", "scanner")
		n.set_meta("crew_role", "scanner")
	var lab: Node = root.get_node_or_null("ScannerSeatLabel")
	if lab is Label3D and str((lab as Label3D).text).find("SCANNER") < 0:
		(lab as Label3D).text = "CREW SEAT · SCANNER"


static func _legal_seat(root: Node3D, pos: Vector3, neon: Color, seat_name: String, vol_name: String, label_name: String, label: String, role: String) -> void:
	## Station ops / hangar carrier seats. Never named Seat or SeatVolume (IN-A).
	var seat := Marker3D.new()
	seat.name = seat_name
	seat.set_meta("legal_seat", true)
	seat.set_meta("seat_role", role)
	seat.position = pos
	root.add_child(seat)
	var vol := Marker3D.new()
	vol.name = vol_name
	vol.set_meta("legal_seat", true)
	vol.set_meta("seat_role", role)
	vol.position = pos
	root.add_child(vol)
	if DisplayServer.get_name() != "headless":
		var lab := Label3D.new()
		lab.name = label_name
		lab.text = "%s  [F]" % label
		lab.font_size = 36
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.modulate = neon
		lab.position = pos + Vector3(0, 1.85, 0)
		root.add_child(lab)


static func _console_volume(root: Node3D, pos: Vector3, neon: Color, tag: String = "OPS") -> void:
	var vol := Marker3D.new()
	vol.name = "ConsoleVolume"
	vol.position = pos + Vector3(0, 1.0, 0)
	root.add_child(vol)
	if DisplayServer.get_name() != "headless":
		var lab := Label3D.new()
		lab.name = "ConsoleLabel"
		lab.text = "%s CONSOLE  [E]" % tag
		lab.font_size = 36
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.modulate = neon
		lab.position = pos + Vector3(0, 2.15, 0)
		root.add_child(lab)
	_box_mesh(root, pos + Vector3(0, 0.55, 0), Vector3(1.4, 1.1, 0.7), Color(0.08, 0.09, 0.11), true)
	_box_mesh(root, pos + Vector3(0, 1.05, 0.28), Vector3(1.1, 0.08, 0.08), neon, false, true)


static func _link_ship_rooms(root: Node3D, rooms: Array, neon: Color) -> void:
	## Hall floor + a door that opens into the next room. No locked props.
	if rooms.size() < 2:
		return
	for i in range(rooms.size() - 1):
		var a: Dictionary = rooms[i]
		var b: Dictionary = rooms[i + 1]
		var az: float = float(a["pos"].z) + float(a["size"].z) * 0.5
		var bz: float = float(b["pos"].z) - float(b["size"].z) * 0.5
		var mid_z: float = (az + bz) * 0.5
		var gap: float = maxf(absf(bz - az), 0.85)
		var hw: float = minf(float(a["size"].x), float(b["size"].x))
		hw = clampf(hw, 2.6, 4.2)
		_hall_volume(root, Vector3(0, 0, mid_z), Vector3(hw, 2.4, gap + 0.55), neon, i)
		_door_portal(root, Vector3(0, 0, mid_z), neon, hw, "pocket")


static func _hall_volume(root: Node3D, pos: Vector3, size: Vector3, neon: Color, idx: int) -> void:
	var hall := Node3D.new()
	hall.name = "Hall_%d" % idx
	hall.position = pos
	hall.set_meta("leads_to", "pocket")
	root.add_child(hall)
	_box_mesh(hall, Vector3(0, 0, 0), Vector3(size.x, 0.55, size.z), Color(0.2, 0.24, 0.3), true)
	_box_mesh(hall, Vector3(0, size.y, 0), Vector3(size.x, 0.12, size.z), Color(0.15, 0.17, 0.2), true)
	_box_mesh(hall, Vector3(-size.x * 0.5, size.y * 0.5, 0), Vector3(0.16, size.y, size.z), Color(0.3, 0.34, 0.4), true)
	_box_mesh(hall, Vector3(size.x * 0.5, size.y * 0.5, 0), Vector3(0.16, size.y, size.z), Color(0.3, 0.34, 0.4), true)
	_box_mesh(hall, Vector3(0, 0.08, 0), Vector3(0.28, 0.04, size.z * 0.9), neon, false, true)


static func _airlock_stub(root: Node3D, hatch_pos: Vector3, neon: Color) -> void:
	## One readable volume: airlock deck + locker proxies + hull hatch. Code-first.
	var air := Node3D.new()
	air.name = "AirlockStub"
	air.position = Vector3(hatch_pos.x, 0.0, hatch_pos.z)
	air.set_meta("leads_to", "eva")
	root.add_child(air)
	_box_mesh(air, Vector3(0, 0.04, 0), Vector3(2.5, 0.08, 2.1), Color(0.16, 0.18, 0.22), true)
	_box_mesh(air, Vector3(0, 0.09, 0), Vector3(2.2, 0.03, 0.14), Color(0.9, 0.55, 0.12), false, true)
	_box_mesh(air, Vector3(-1.42, 0.85, -0.4), Vector3(0.28, 1.6, 0.45), Color(0.11, 0.13, 0.16), true)
	_box_mesh(air, Vector3(1.42, 0.85, -0.4), Vector3(0.28, 1.6, 0.45), Color(0.11, 0.13, 0.16), true)
	_box_mesh(air, Vector3(-1.42, 1.35, -0.16), Vector3(0.16, 0.08, 0.08), neon, false, true)
	_box_mesh(air, Vector3(1.42, 1.35, -0.16), Vector3(0.16, 0.08, 0.08), neon, false, true)
	# Outer hull skin beyond the hatch (+Z). Door opens; I is EVA. Not a void.
	_box_mesh(air, Vector3(0, 1.15, 0.72), Vector3(2.2, 2.2, 0.1), Color(0.08, 0.09, 0.11), true)
	_box_mesh(air, Vector3(0, 1.15, 0.66), Vector3(1.35, 1.7, 0.05), neon, false, true)
	_door_portal(root, Vector3(hatch_pos.x, 0.0, hatch_pos.z), neon, 3.2, "eva")
	if DisplayServer.get_name() != "headless" and root.get_node_or_null("HatchLabel") == null:
		var lab := Label3D.new()
		lab.name = "HatchLabel"
		lab.text = "AIRLOCK · HATCH [F/I]"
		lab.font_size = 40
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.modulate = neon
		lab.position = hatch_pos + Vector3(0, 1.15, 0)
		root.add_child(lab)


static func _door_portal(root: Node3D, pos: Vector3, neon: Color, hall_w: float = 6.0, leads_to: String = "pocket") -> void:
	## Sliding slab + side fills so the opening is the only walk path.
	var door := Node3D.new()
	var idx := 0
	while root.get_node_or_null("DoorPortal_%d" % idx) != null:
		idx += 1
	door.name = "DoorPortal_%d" % idx
	door.set_meta("leads_to", leads_to)
	door.position = pos
	root.add_child(door)
	var half := hall_w * 0.5
	var gap := 2.2
	var fill_w: float = maxf(0.4, half - gap * 0.5)
	var fill_c: float = half - fill_w * 0.5
	var wall_c := Color(0.3, 0.34, 0.4)
	_box_mesh(door, Vector3(-fill_c, 1.2, 0), Vector3(fill_w, 2.4, 0.32), wall_c, true)
	_box_mesh(door, Vector3(fill_c, 1.2, 0), Vector3(fill_w, 2.4, 0.32), wall_c, true)
	_box_mesh(door, Vector3(0, 2.4, 0), Vector3(hall_w * 0.92, 0.22, 0.32), wall_c, true)
	_box_mesh(door, Vector3(0, 2.28, 0), Vector3(gap + 0.2, 0.05, 0.12), neon, false, true)
	var slab: Node3D
	if DisplayServer.get_name() == "headless":
		slab = Node3D.new()
		slab.name = "Slab"
		slab.position = Vector3(0, 1.1, 0)
		door.add_child(slab)
	else:
		var mi := MeshInstance3D.new()
		mi.name = "Slab"
		var bm := BoxMesh.new()
		bm.size = Vector3(gap, 2.15, 0.1)
		mi.mesh = bm
		mi.position = Vector3(0, 1.1, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.07, 0.1, 0.13)
		mat.metallic = 0.55
		mat.roughness = 0.35
		mat.emission_enabled = true
		mat.emission = neon
		mat.emission_energy_multiplier = 0.55
		mi.material_override = mat
		door.add_child(mi)
		slab = mi
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(gap, 2.15, 0.1)
	cs.shape = sh
	sb.add_child(cs)
	slab.add_child(sb)


static func _attach_ambient(root: Node3D, kind: String, neon: Color) -> void:
	_try_neon_props(root, kind)
	var amb := Node3D.new()
	amb.set_script(load("res://scripts/world/InteriorAmbient.gd"))
	root.add_child(amb)
	if amb.has_method("setup"):
		amb.setup(kind, neon)



static func _try_neon_props(root: Node3D, kind: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var AP = load("res://scripts/assets/AssetPaths.gd")
	if AP == null or not AP.has_method("resolve"):
		return
	var fac := "cybernex"
	var vents := [
		["props/neon_vent_module/neon_vent_module_%s_lod2.glb", Vector3(2.1, 1.4, 1.0), 0.7],
		["props/neon_holo_emitter/neon_holo_emitter_%s_lod2.glb", Vector3(-2.0, 0.9, 3.0), 0.55],
	]
	for e in vents:
		var rel: String = str(e[0]) % fac
		var path: String = str(AP.resolve(rel))
		if path == "" or not FileAccess.file_exists(path):
			continue
		var doc := GLTFDocument.new()
		var st2 := GLTFState.new()
		if doc.append_from_file(path, st2) != OK:
			continue
		var scn := doc.generate_scene(st2)
		if scn == null:
			continue
		root.add_child(scn)
		scn.position = e[1]
		scn.scale = Vector3.ONE * float(e[2])
