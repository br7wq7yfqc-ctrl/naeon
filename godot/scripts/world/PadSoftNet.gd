extends Node3D
class_name PadSoftNet
## SN-A: second local viewer sees host SurfaceWalker pose on the occupied unnamed pad.
## SoftNet pose only — same bind_visual_puppet path as IN-F / MC-A.
## Host keeps Pulse / occupy. No second physical walker. Not ENet cluster. G5 closed.

const VIEWER_NAME := "PadSoftViewer"
const PUPPET_NAME := "PadWalkerPuppet"

var _traffic: Node = null
var _viewer: Node3D = null
var _puppet: Node3D = null
var _pose: Dictionary = {}


func _ready() -> void:
	name = "PadSoftNet"
	set_meta("site_pin", "")
	set_meta("mobile_site", false)
	set_meta("softnet_visual", true)
	set_meta("combat_authority", "host")
	set_meta("occupy_authority", "host")
	if not is_in_group("pad_softnet"):
		add_to_group("pad_softnet")
	_ensure_viewer()
	_ensure_puppet()
	sync_from_host()


func _process(_delta: float) -> void:
	_follow_host_walker()


func bind(traffic: Node) -> void:
	if traffic == null or not is_instance_valid(traffic):
		return
	_traffic = traffic
	set_meta("site_pin", "")
	_ensure_viewer()
	_ensure_puppet()
	sync_from_host()


func viewer() -> Node3D:
	_ensure_viewer()
	return _viewer if _viewer != null and is_instance_valid(_viewer) else null


func walker_puppet() -> Node3D:
	_ensure_puppet()
	return _puppet if _puppet != null and is_instance_valid(_puppet) else null


func combat_authority() -> String:
	return "host"


func occupy_authority() -> String:
	return "host"


func is_host_authority() -> bool:
	return true


func has_second_physical_walker() -> bool:
	return physical_walker_count() > 1


func observed_pose() -> Dictionary:
	if _pose.is_empty():
		sync_from_host()
	return _pose.duplicate()


func viewer_sees_walker_puppet() -> bool:
	var p := walker_puppet()
	return p != null and p.visible and bool(p.get_meta("softnet_visual", false))


func physical_walker_count() -> int:
	var tree := get_tree()
	if tree == null:
		return 0
	var n := 0
	for node in tree.get_nodes_in_group("player"):
		if node == null or not is_instance_valid(node):
			continue
		if bool(node.get_meta("softnet_visual", false)):
			continue
		if bool(node.get_meta("pad_walker_puppet", false)):
			continue
		if node is CharacterBody3D:
			n += 1
	return n


func host_walker() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var os: Node = tree.get_first_node_in_group("open_space")
	if os != null:
		var p: Variant = os.get("player")
		if p is CharacterBody3D and is_instance_valid(p) and not bool(p.get_meta("softnet_visual", false)):
			return p as Node3D
	for node in tree.get_nodes_in_group("player"):
		if node is CharacterBody3D and is_instance_valid(node) and not bool(node.get_meta("softnet_visual", false)):
			return node as Node3D
	return null


func rival_visual() -> Node3D:
	if _traffic == null or not is_instance_valid(_traffic):
		return null
	var r: Node3D = null
	if _traffic.has_method("get_rival"):
		r = _traffic.get_rival()
	if r != null and is_instance_valid(r) and bool(r.get_meta("softnet_visual", false)):
		return r
	return null


func is_g5_closed() -> bool:
	if _traffic != null and is_instance_valid(_traffic) and _traffic.has_method("is_g5_closed"):
		return bool(_traffic.is_g5_closed())
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
	var walker := host_walker()
	var rival := rival_visual()
	if walker != null:
		_show_walker_puppet(walker)
	else:
		_hide_puppet()
	_pose = {
		"walker_mode": "world" if walker != null else "none",
		"walker_pos": walker.global_position if walker != null else Vector3.ZERO,
		"authority": "host",
		"occupy_authority": "host",
		"physical_walkers": physical_walker_count(),
		"rival_visual": rival != null,
		"g5_closed": is_g5_closed(),
	}
	_bind_soft_visuals()


func _follow_host_walker() -> void:
	var walker := host_walker()
	if walker == null:
		return
	if _puppet == null or not is_instance_valid(_puppet):
		return
	_puppet.global_transform = walker.global_transform
	_puppet.visible = true
	if not _pose.is_empty():
		_pose["walker_mode"] = "world"
		_pose["walker_pos"] = walker.global_position
		_pose["physical_walkers"] = physical_walker_count()


func _ensure_viewer() -> void:
	if _viewer != null and is_instance_valid(_viewer):
		return
	var existing: Node = get_node_or_null(VIEWER_NAME)
	if existing is Node3D:
		_viewer = existing as Node3D
		_tag_visual(_viewer, "pad_soft_viewer")
		return
	_viewer = Node3D.new()
	_viewer.name = VIEWER_NAME
	_tag_visual(_viewer, "pad_soft_viewer")
	_viewer.set_meta("site_pin", "")
	add_child(_viewer)
	_viewer.position = Vector3(-3.2, 1.6, 5.4)
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
		lab.text = "PAD VIEWER (soft net)"
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
		_tag_visual(_puppet, "pad_walker_puppet")
		return
	_puppet = Node3D.new()
	_puppet.name = PUPPET_NAME
	_tag_visual(_puppet, "pad_walker_puppet")
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
		lab.text = "WALKER PUPPET (soft net)"
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
	n.set_meta(kind, true)
	if not n.is_in_group(kind):
		n.add_to_group(kind)


func _show_walker_puppet(walker: Node3D) -> void:
	if _puppet == null or not is_instance_valid(_puppet):
		return
	_puppet.global_transform = walker.global_transform
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
	var rival := rival_visual()
	if rival != null:
		SoftNetSession.bind_visual_puppet(rival)
