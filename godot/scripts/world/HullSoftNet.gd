extends Node3D
class_name HullSoftNet
## SN-B: second local viewer seated on the player hull sees a SoftNet visual
## puppet of the host hull / pilot (or crew-seat pose).
## SoftNet pose only — same bind_visual_puppet path as SN-A / MC-A / PV-B.
## Host keeps Pulse / occupy / thrust. No second physical hull. Not ENet. G5 closed.

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")

const VIEWER_NAME := "HullSoftViewer"
const PUPPET_NAME := "HullPilotPuppet"

var _space: Node = null
var _viewer: Node3D = null
var _puppet: Node3D = null
var _pose: Dictionary = {}


func _ready() -> void:
	name = "HullSoftNet"
	set_meta("site_pin", "")
	set_meta("mobile_site", false)
	set_meta("softnet_visual", true)
	set_meta("combat_authority", "host")
	set_meta("occupy_authority", "host")
	set_meta("thrust_authority", "host")
	if not is_in_group("hull_softnet"):
		add_to_group("hull_softnet")
	_ensure_viewer()
	_ensure_puppet()
	sync_from_host()


func _process(_delta: float) -> void:
	_follow_host_hull()


func bind(space: Node) -> void:
	if space == null or not is_instance_valid(space):
		return
	_space = space
	set_meta("site_pin", "")
	_ensure_viewer()
	_ensure_puppet()
	sync_from_host()


func viewer() -> Node3D:
	_ensure_viewer()
	return _viewer if _viewer != null and is_instance_valid(_viewer) else null


func hull_puppet() -> Node3D:
	_ensure_puppet()
	return _puppet if _puppet != null and is_instance_valid(_puppet) else null


func combat_authority() -> String:
	return "host"


func occupy_authority() -> String:
	return "host"


func thrust_authority() -> String:
	return "host"


func is_host_authority() -> bool:
	return true


func knowledge_label() -> String:
	## SoftKnowledge / HUD word only. Never DPS / yield / thrust.
	return _SoftK.net_visual_label()


func has_second_physical_hull() -> bool:
	## SN-B never instantiates a ship. Leftover playtest hulls elsewhere
	## are not a second player hull spawned by this node.
	if _puppet is CharacterBody3D:
		return true
	for c in get_children():
		if c is CharacterBody3D and not bool(c.get_meta("softnet_visual", false)):
			return true
	return false


func observed_pose() -> Dictionary:
	if _pose.is_empty():
		sync_from_host()
	return _pose.duplicate()


func viewer_sees_hull_puppet() -> bool:
	var p := hull_puppet()
	return p != null and p.visible and bool(p.get_meta("softnet_visual", false))


func physical_hull_count() -> int:
	var tree := get_tree()
	if tree == null:
		return 0
	var n := 0
	for node in tree.get_nodes_in_group("ship"):
		if node == null or not is_instance_valid(node):
			continue
		if bool(node.get_meta("softnet_visual", false)):
			continue
		if bool(node.get_meta("hull_pilot_puppet", false)):
			continue
		if node is CharacterBody3D:
			n += 1
	return n


func host_hull() -> Node3D:
	var os := _open_space()
	if os != null:
		var s: Variant = os.get("ship")
		if s is CharacterBody3D and is_instance_valid(s) and not bool(s.get_meta("softnet_visual", false)):
			return s as Node3D
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("ship"):
		if node is CharacterBody3D and is_instance_valid(node) \
				and not bool(node.get_meta("softnet_visual", false)) \
				and not (node.has_method("is_npc_pilot") and bool(node.is_npc_pilot())):
			return node as Node3D
	return null


func host_pose_node() -> Node3D:
	## Crew-seat pose when the host is boarded there; otherwise the hull.
	var seat := _host_crew_seat()
	if seat != null:
		return seat
	return host_hull()


func is_g5_closed() -> bool:
	if ResourceLoader.exists("res://scenes/world/ClashBeacon.tscn"):
		return false
	if ResourceLoader.exists("res://scripts/world/ClashBeacon.gd"):
		return false
	if ResourceLoader.exists("res://scripts/world/ClashFromWorld.gd"):
		return false
	var tree := get_tree()
	if tree:
		if tree.get_first_node_in_group("clash_beacon") != null:
			return false
		if tree.get_first_node_in_group("g5_clash") != null:
			return false
		var scene: Node = tree.current_scene
		if scene != null and str(scene.name).begins_with("TestArena"):
			return false
	return true


func sync_from_host() -> void:
	_ensure_viewer()
	_ensure_puppet()
	var hull := host_hull()
	var pose_n := host_pose_node()
	if pose_n != null:
		_show_hull_puppet(pose_n)
	elif hull != null:
		_show_hull_puppet(hull)
	else:
		_hide_puppet()
	_seat_viewer(hull)
	var seated := _host_is_seated()
	_pose = {
		"hull_mode": "seated" if seated else ("hull" if hull != null else "none"),
		"hull_pos": hull.global_position if hull != null else Vector3.ZERO,
		"authority": "host",
		"occupy_authority": "host",
		"thrust_authority": "host",
		"physical_hulls": physical_hull_count(),
		"crew_seat_pose": _host_crew_seat() != null,
		"knowledge": knowledge_label(),
		"g5_closed": is_g5_closed(),
	}
	_bind_soft_visuals()


func _follow_host_hull() -> void:
	var pose_n := host_pose_node()
	if pose_n == null:
		return
	if _puppet == null or not is_instance_valid(_puppet):
		return
	_puppet.global_transform = pose_n.global_transform
	_puppet.visible = true
	_seat_viewer(host_hull())
	if not _pose.is_empty():
		_pose["hull_mode"] = "seated" if _host_is_seated() else "hull"
		_pose["hull_pos"] = pose_n.global_position
		_pose["physical_hulls"] = physical_hull_count()


func _seat_viewer(hull: Node3D) -> void:
	if _viewer == null or not is_instance_valid(_viewer):
		return
	if hull == null or not is_instance_valid(hull):
		return
	var basis: Basis = hull.global_transform.basis
	_viewer.global_position = hull.global_position + basis * Vector3(-1.6, 1.15, 1.4)
	_viewer.global_transform.basis = basis


func _open_space() -> Node:
	if _space != null and is_instance_valid(_space):
		return _space
	var tree := get_tree()
	if tree == null:
		return null
	var os: Node = tree.get_first_node_in_group("open_space")
	if os != null:
		_space = os
	return os


func _host_is_seated() -> bool:
	var os := _open_space()
	if os != null and bool(os.get("_in_ship")):
		return true
	var d := _interior()
	if d != null and d.has_method("is_seated") and bool(d.is_seated()):
		return true
	return false


func _interior() -> Node:
	var os := _open_space()
	if os == null:
		return null
	var d: Variant = os.get("_interior")
	if d is Node and is_instance_valid(d):
		return d
	var tree := get_tree()
	if tree:
		return tree.get_first_node_in_group("interior_director")
	return null


func _host_crew_seat() -> Node3D:
	var d := _interior()
	if d == null or not is_instance_valid(d):
		return null
	if not d.has_method("is_seated") or not bool(d.is_seated()):
		return null
	var role := ""
	if d.has_method("get_seat_role"):
		role = str(d.get_seat_role())
	if role != "crew":
		return null
	var pocket: Node = null
	if d.has_method("get_active_interior"):
		pocket = d.get_active_interior()
	if pocket == null or not is_instance_valid(pocket):
		return null
	var named := ""
	if d.has_method("boarded_station_role"):
		named = str(d.boarded_station_role())
	var seat_name := "EngineerSeat" if named == "engineer" else "CrewSeat"
	var n: Node = pocket.get_node_or_null(seat_name)
	if n is Node3D:
		return n as Node3D
	return null


func _ensure_viewer() -> void:
	if _viewer != null and is_instance_valid(_viewer):
		return
	var existing: Node = get_node_or_null(VIEWER_NAME)
	if existing is Node3D:
		_viewer = existing as Node3D
		_tag_visual(_viewer, "hull_soft_viewer")
		return
	_viewer = Node3D.new()
	_viewer.name = VIEWER_NAME
	_tag_visual(_viewer, "hull_soft_viewer")
	_viewer.set_meta("site_pin", "")
	add_child(_viewer)
	_viewer.position = Vector3(-1.6, 1.15, 1.4)
	if DisplayServer.get_name() != "headless":
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.28
		cap.height = 1.05
		mi.mesh = cap
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.85, 1.0, 0.3)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.25, 0.7, 1.0)
		mat.emission_energy_multiplier = 0.9
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = mat
		mi.position = Vector3(0, 0.8, 0)
		_viewer.add_child(mi)
		var lab := Label3D.new()
		lab.text = "%s VIEWER (soft net)" % knowledge_label()
		lab.font_size = 20
		lab.modulate = Color(0.7, 0.95, 1.0, 0.8)
		lab.position = Vector3(0, 1.9, 0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_viewer.add_child(lab)
	if SoftNetSession and SoftNetSession.has_method("bind_visual_puppet"):
		SoftNetSession.bind_visual_puppet(_viewer)


func _ensure_puppet() -> void:
	if _puppet != null and is_instance_valid(_puppet):
		return
	var existing: Node = get_node_or_null(PUPPET_NAME)
	if existing is Node3D:
		_puppet = existing as Node3D
		_tag_visual(_puppet, "hull_pilot_puppet")
		return
	_puppet = Node3D.new()
	_puppet.name = PUPPET_NAME
	_tag_visual(_puppet, "hull_pilot_puppet")
	_puppet.set_meta("site_pin", "")
	add_child(_puppet)
	_puppet.visible = false
	if DisplayServer.get_name() != "headless":
		var body := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.3
		cap.height = 1.1
		body.mesh = cap
		body.position.y = 0.85
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.75, 0.9, 0.28)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.6, 0.85)
		mat.emission_energy_multiplier = 0.85
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		body.material_override = mat
		_puppet.add_child(body)
		var lab := Label3D.new()
		lab.name = "PuppetLabel"
		lab.text = "%s HULL (soft net)" % knowledge_label()
		lab.font_size = 18
		lab.modulate = Color(0.65, 0.95, 1.0, 0.75)
		lab.position = Vector3(0, 2.0, 0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_puppet.add_child(lab)
	if SoftNetSession and SoftNetSession.has_method("bind_visual_puppet"):
		SoftNetSession.bind_visual_puppet(_puppet)


func _tag_visual(n: Node3D, kind: String) -> void:
	n.set_meta("softnet_visual", true)
	n.set_meta("combat_authority", "host")
	n.set_meta("occupy_authority", "host")
	n.set_meta("thrust_authority", "host")
	n.set_meta(kind, true)
	if not n.is_in_group(kind):
		n.add_to_group(kind)


func _show_hull_puppet(src: Node3D) -> void:
	if _puppet == null or not is_instance_valid(_puppet):
		return
	_puppet.global_transform = src.global_transform
	_puppet.visible = true


func _hide_puppet() -> void:
	if _puppet == null or not is_instance_valid(_puppet):
		return
	_puppet.visible = false


func _bind_soft_visuals() -> void:
	if SoftNetSession == null or not SoftNetSession.has_method("bind_visual_puppet"):
		return
	if _viewer != null and is_instance_valid(_viewer):
		SoftNetSession.bind_visual_puppet(_viewer)
	if _puppet != null and is_instance_valid(_puppet) and _puppet.visible:
		SoftNetSession.bind_visual_puppet(_puppet)
