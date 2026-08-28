extends Node3D
class_name HangarSoftNet
## IN-F V4 visual: second local viewer sees CargoRamp pose + rover / stored ghost.
## SoftNet pose only — same bind_visual_puppet path as AR-F / NP-D.
## Host keeps rover authority (IN-D/E). No second physical rover. No combat.
## GroundVehicle has only the IN-D pilot seat — no pay-slot passenger this slice.

const VIEWER_NAME := "HangarSoftViewer"
const PUPPET_NAME := "HangarRoverPuppet"

var _carrier: Node = null
var _viewer: Node3D = null
var _rover_puppet: Node3D = null
var _pose: Dictionary = {}


func _ready() -> void:
	name = "HangarSoftNet"
	set_meta("site_pin", "")
	set_meta("mobile_site", false)
	set_meta("softnet_visual", true)
	set_meta("combat_authority", "host")
	if not is_in_group("hangar_softnet"):
		add_to_group("hangar_softnet")
	if _carrier == null:
		var p: Node = get_parent()
		if p != null and p.has_method("cargo_ramp") and p.has_method("get_deployed_rover"):
			bind_carrier(p)


func _process(_delta: float) -> void:
	if _carrier == null or not is_instance_valid(_carrier):
		return
	_follow_authority_rover()


func bind_carrier(c: Node) -> void:
	if c == null or not is_instance_valid(c):
		return
	_carrier = c
	_ensure_viewer()
	_ensure_rover_puppet()
	sync_from_host()


func hangar_softnet() -> Node:
	return self


func viewer() -> Node3D:
	_ensure_viewer()
	return _viewer if _viewer != null and is_instance_valid(_viewer) else null


func rover_puppet() -> Node3D:
	_ensure_rover_puppet()
	return _rover_puppet if _rover_puppet != null and is_instance_valid(_rover_puppet) else null


func rover_authority() -> String:
	return "host"


func combat_authority() -> String:
	return "host"


func is_host_authority() -> bool:
	return rover_authority() == "host"


func has_passenger_seat() -> bool:
	## Dishonest to invent a second seat: GroundVehicle only has `pilot`.
	return false


func observed_pose() -> Dictionary:
	if _pose.is_empty():
		sync_from_host()
	return _pose.duplicate()


func viewer_sees_ramp_deployed() -> bool:
	return str(observed_pose().get("ramp_state", "")) == "DEPLOYED"


func viewer_sees_rover_puppet() -> bool:
	var mode := str(observed_pose().get("rover_mode", "none"))
	return mode == "world" or mode == "stored_ghost"


func visual_puppet_count() -> int:
	var n := 0
	var v := viewer()
	if v != null and bool(v.get_meta("softnet_visual", false)):
		n += 1
	var p := rover_puppet()
	if p != null and bool(p.get_meta("softnet_visual", false)) and p.visible:
		n += 1
	return n


func physical_rover_count() -> int:
	var tree := get_tree()
	if tree == null:
		return 0
	var n := 0
	for node in tree.get_nodes_in_group("ground_vehicle"):
		if node == null or not is_instance_valid(node):
			continue
		if bool(node.get_meta("softnet_visual", false)):
			continue
		if bool(node.get_meta("hangar_rover_puppet", false)):
			continue
		n += 1
	return n


func sync_from_host() -> void:
	if _carrier == null or not is_instance_valid(_carrier):
		_pose = {
			"ramp_state": "STOWED",
			"rover_mode": "none",
			"rover_pos": Vector3.ZERO,
			"authority": "host",
			"physical_rovers": 0,
			"passenger_seat": false,
		}
		return
	_ensure_viewer()
	_ensure_rover_puppet()
	var ramp: Node = _carrier.cargo_ramp() if _carrier.has_method("cargo_ramp") else null
	var ramp_state := "STOWED"
	if ramp != null and ramp.has_method("state_name"):
		ramp_state = str(ramp.state_name())
	elif ramp != null and ramp.has_method("is_driveable") and bool(ramp.is_driveable()):
		ramp_state = "DEPLOYED"
	var rover: Node3D = null
	if _carrier.has_method("get_deployed_rover"):
		rover = _carrier.get_deployed_rover()
	var stored := 0
	if _carrier.has_method("stored_vehicle_count"):
		stored = int(_carrier.stored_vehicle_count())
	var mode := "none"
	var pos := global_position
	if rover != null and is_instance_valid(rover):
		mode = "world"
		pos = rover.global_position
		_show_world_puppet(rover)
	elif stored > 0:
		mode = "stored_ghost"
		pos = _stored_ghost_pos()
		_show_stored_ghost(pos)
	else:
		_hide_puppet()
	_pose = {
		"ramp_state": ramp_state,
		"rover_mode": mode,
		"rover_pos": pos,
		"authority": "host",
		"physical_rovers": physical_rover_count(),
		"passenger_seat": false,
	}
	_bind_soft_visuals()


func _follow_authority_rover() -> void:
	if _carrier == null or not is_instance_valid(_carrier):
		return
	if not _carrier.has_method("get_deployed_rover"):
		return
	var rover: Node3D = _carrier.get_deployed_rover()
	if rover == null or not is_instance_valid(rover):
		return
	if _rover_puppet == null or not is_instance_valid(_rover_puppet):
		return
	_rover_puppet.global_transform = rover.global_transform
	_rover_puppet.visible = true
	_rover_puppet.set_meta("stored_ghost", false)
	if not _pose.is_empty():
		_pose["rover_mode"] = "world"
		_pose["rover_pos"] = rover.global_position
		_pose["physical_rovers"] = physical_rover_count()


func _ensure_viewer() -> void:
	if _viewer != null and is_instance_valid(_viewer):
		return
	var existing: Node = get_node_or_null(VIEWER_NAME)
	if existing is Node3D:
		_viewer = existing as Node3D
		_tag_visual(_viewer, "hangar_soft_viewer")
		return
	_viewer = Node3D.new()
	_viewer.name = VIEWER_NAME
	_tag_visual(_viewer, "hangar_soft_viewer")
	_viewer.set_meta("site_pin", "")
	_viewer.set_meta("mobile_site", false)
	add_child(_viewer)
	_viewer.position = Vector3(3.6, 1.4, 6.2)
	if DisplayServer.get_name() != "headless":
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.32
		cap.height = 1.15
		mi.mesh = cap
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.82, 1.0, 0.32)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.65, 1.0)
		mat.emission_energy_multiplier = 1.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = mat
		mi.position = Vector3(0, 0.85, 0)
		_viewer.add_child(mi)
		var lab := Label3D.new()
		lab.text = "HANGAR VIEWER (soft net)"
		lab.font_size = 22
		lab.modulate = Color(0.65, 0.95, 1.0, 0.8)
		lab.position = Vector3(0, 2.0, 0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_viewer.add_child(lab)
	if SoftNetSession and SoftNetSession.has_method("bind_visual_puppet"):
		SoftNetSession.bind_visual_puppet(_viewer)


func _ensure_rover_puppet() -> void:
	if _rover_puppet != null and is_instance_valid(_rover_puppet):
		return
	var existing: Node = get_node_or_null(PUPPET_NAME)
	if existing is Node3D:
		_rover_puppet = existing as Node3D
		_tag_rover_puppet(_rover_puppet)
		return
	_rover_puppet = Node3D.new()
	_rover_puppet.name = PUPPET_NAME
	_tag_rover_puppet(_rover_puppet)
	add_child(_rover_puppet)
	_rover_puppet.visible = false
	if DisplayServer.get_name() != "headless":
		var body := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.0, 0.7, 3.0)
		body.mesh = box
		body.position.y = 0.55
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.7, 0.85, 0.28)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.15, 0.55, 0.75)
		mat.emission_energy_multiplier = 0.9
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		body.material_override = mat
		_rover_puppet.add_child(body)
		var lab := Label3D.new()
		lab.name = "PuppetLabel"
		lab.text = "ROVER PUPPET (soft net)"
		lab.font_size = 20
		lab.modulate = Color(0.6, 0.95, 0.9, 0.75)
		lab.position = Vector3(0, 2.1, 0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_rover_puppet.add_child(lab)
	if SoftNetSession and SoftNetSession.has_method("bind_visual_puppet"):
		SoftNetSession.bind_visual_puppet(_rover_puppet)


func _tag_visual(n: Node3D, kind: String) -> void:
	n.set_meta("softnet_visual", true)
	n.set_meta("combat_authority", "host")
	n.set_meta(kind, true)
	if not n.is_in_group(kind):
		n.add_to_group(kind)


func _tag_rover_puppet(n: Node3D) -> void:
	_tag_visual(n, "hangar_rover_puppet")
	n.set_meta("site_pin", "")
	n.set_meta("mobile_site", false)
	n.set_meta("stored_ghost", false)
	## Never a physical GroundVehicle — no group, no CharacterBody3D, no board.


func _show_world_puppet(rover: Node3D) -> void:
	if _rover_puppet == null or not is_instance_valid(_rover_puppet):
		return
	_rover_puppet.global_transform = rover.global_transform
	_rover_puppet.visible = true
	_rover_puppet.set_meta("stored_ghost", false)
	_set_puppet_label("ROVER PUPPET (soft net)")


func _show_stored_ghost(pos: Vector3) -> void:
	if _rover_puppet == null or not is_instance_valid(_rover_puppet):
		return
	_rover_puppet.global_position = pos
	_rover_puppet.visible = true
	_rover_puppet.set_meta("stored_ghost", true)
	_set_puppet_label("STORED GHOST (soft net)")


func _hide_puppet() -> void:
	if _rover_puppet == null or not is_instance_valid(_rover_puppet):
		return
	_rover_puppet.visible = false
	_rover_puppet.set_meta("stored_ghost", false)


func _stored_ghost_pos() -> Vector3:
	var bay: Node = _carrier.hangar_bay() if _carrier != null and _carrier.has_method("hangar_bay") else null
	if bay is Node3D:
		return (bay as Node3D).global_position + Vector3(0.0, 0.8, 0.0)
	var ramp: Node = _carrier.cargo_ramp() if _carrier != null and _carrier.has_method("cargo_ramp") else null
	if ramp != null and ramp.has_method("walk_mouth_global"):
		return ramp.walk_mouth_global()
	return global_position + Vector3(0.0, 1.0, 2.0)


func _set_puppet_label(text: String) -> void:
	if _rover_puppet == null or not is_instance_valid(_rover_puppet):
		return
	var lab: Node = _rover_puppet.get_node_or_null("PuppetLabel")
	if lab is Label3D:
		(lab as Label3D).text = text


func _bind_soft_visuals() -> void:
	if SoftNetSession == null:
		return
	if SoftNetSession.has_method("bind_visual_puppet"):
		if _viewer != null and is_instance_valid(_viewer):
			SoftNetSession.bind_visual_puppet(_viewer)
		if _rover_puppet != null and is_instance_valid(_rover_puppet) and _rover_puppet.visible:
			SoftNetSession.bind_visual_puppet(_rover_puppet)
