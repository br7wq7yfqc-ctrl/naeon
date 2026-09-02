extends Node3D
class_name ClashSoftNet
## SN-D: second local viewer in Clash (TestArena / ClashDirector) sees a
## SoftNet visual puppet of the host (arena / Clash pose).
## SoftNet pose only — same bind_visual_puppet path as SN-A / SN-B / SN-C.
## Host keeps Pulse / Hack / form. No second physical Clash dummy. Not ENet.
## G5 cluster stays closed. AR-H pad door stays as the legal Clash entry.

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")

const VIEWER_NAME := "ClashSoftViewer"
const PUPPET_NAME := "ClashHostPuppet"

var _director: Node = null
var _viewer: Node3D = null
var _puppet: Node3D = null
var _pose: Dictionary = {}


func _ready() -> void:
	name = "ClashSoftNet"
	set_meta("site_pin", "")
	set_meta("mobile_site", false)
	set_meta("softnet_visual", true)
	set_meta("combat_authority", "host")
	set_meta("hack_authority", "host")
	set_meta("form_authority", "host")
	if not is_in_group("clash_softnet"):
		add_to_group("clash_softnet")
	_ensure_viewer()
	_ensure_puppet()
	sync_from_host()


func _process(_delta: float) -> void:
	_follow_host_actor()


func bind(director: Node) -> void:
	if director == null or not is_instance_valid(director):
		return
	_director = director
	set_meta("site_pin", "")
	_ensure_viewer()
	_ensure_puppet()
	sync_from_host()


func viewer() -> Node3D:
	_ensure_viewer()
	return _viewer if _viewer != null and is_instance_valid(_viewer) else null


func clash_puppet() -> Node3D:
	_ensure_puppet()
	return _puppet if _puppet != null and is_instance_valid(_puppet) else null


func combat_authority() -> String:
	return "host"


func hack_authority() -> String:
	return "host"


func form_authority() -> String:
	return "host"


func is_host_authority() -> bool:
	return true


func knowledge_label() -> String:
	## SoftKnowledge / HUD word only. Never DPS / yield / Pulse / Hack / form.
	return _SoftK.net_visual_label()


func has_second_physical_dummy() -> bool:
	## SN-D never instantiates a CombatDummy. Puppet is pose-only Node3D.
	if _is_physical_dummy(_puppet):
		return true
	for c in get_children():
		if _is_physical_dummy(c) and not bool(c.get_meta("softnet_visual", false)):
			return true
	return false


func observed_pose() -> Dictionary:
	if _pose.is_empty():
		sync_from_host()
	return _pose.duplicate()


func viewer_sees_clash_puppet() -> bool:
	var p := clash_puppet()
	return p != null and p.visible and bool(p.get_meta("softnet_visual", false))


func physical_dummy_count() -> int:
	var tree := get_tree()
	if tree == null:
		return 0
	var n := 0
	for node in tree.get_nodes_in_group("enemy"):
		if node == null or not is_instance_valid(node):
			continue
		if bool(node.get_meta("softnet_visual", false)):
			continue
		if bool(node.get_meta("clash_host_puppet", false)):
			continue
		if node is CharacterBody3D:
			n += 1
	return n


func host_actor() -> Node3D:
	var arena := _arena_root()
	if arena != null:
		var p: Variant = arena.get("player")
		if p is CharacterBody3D and is_instance_valid(p) and not bool(p.get_meta("softnet_visual", false)):
			return p as Node3D
	var os := _open_space()
	if os != null:
		var q: Variant = os.get("player")
		if q is CharacterBody3D and is_instance_valid(q) and not bool(q.get_meta("softnet_visual", false)):
			return q as Node3D
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("player"):
		if node is CharacterBody3D and is_instance_valid(node) and not bool(node.get_meta("softnet_visual", false)):
			return node as Node3D
	return null


func host_form() -> String:
	if SoftSession:
		return str(SoftSession.form)
	return ""


func is_clash_layer() -> bool:
	if LayerContext and str(LayerContext.current_layer) == "Arena":
		return true
	var tree := get_tree()
	if tree == null:
		return false
	var scene: Node = tree.current_scene
	if scene != null and str(scene.name).begins_with("TestArena"):
		return true
	return false


func is_g5_closed() -> bool:
	## TestArena itself is the legal AR-H Clash entry. G5 = Clash-from-world cluster.
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
		var os: Node = tree.get_first_node_in_group("open_space")
		if os != null and os.has_method("enter_clash_from_world"):
			return false
	return true


func sync_from_host() -> void:
	_ensure_viewer()
	_ensure_puppet()
	var actor := host_actor()
	if is_clash_layer() and actor != null:
		_show_clash_puppet(actor)
		_seat_viewer(actor)
	else:
		_hide_puppet()
	var kind := "arena" if is_clash_layer() and actor != null else "none"
	_pose = {
		"clash_mode": kind,
		"actor_pos": actor.global_position if actor != null else Vector3.ZERO,
		"authority": "host",
		"hack_authority": "host",
		"form_authority": "host",
		"form": host_form(),
		"physical_dummies": physical_dummy_count(),
		"knowledge": knowledge_label(),
		"g5_closed": is_g5_closed(),
	}
	_bind_soft_visuals()


func _follow_host_actor() -> void:
	if not is_clash_layer():
		_hide_puppet()
		return
	var actor := host_actor()
	if actor == null:
		return
	if _puppet == null or not is_instance_valid(_puppet):
		return
	_puppet.global_transform = actor.global_transform
	_puppet.visible = true
	_seat_viewer(actor)
	if not _pose.is_empty():
		_pose["clash_mode"] = "arena"
		_pose["actor_pos"] = actor.global_position
		_pose["physical_dummies"] = physical_dummy_count()
		_pose["form"] = host_form()


func _seat_viewer(actor: Node3D) -> void:
	if _viewer == null or not is_instance_valid(_viewer):
		return
	if actor == null or not is_instance_valid(actor):
		return
	var up := Vector3.UP
	_viewer.global_position = actor.global_position + up * 2.4 + Vector3(-3.2, 0.0, 4.6)
	if _viewer.global_position.distance_to(actor.global_position) > 0.05:
		_viewer.look_at(actor.global_position, up)


func _arena_root() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var scene: Node = tree.current_scene
	if scene != null and str(scene.name).begins_with("TestArena"):
		return scene
	var parent: Node = get_parent()
	if parent != null and str(parent.name).begins_with("TestArena"):
		return parent
	return null


func _open_space() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("open_space")


func _is_physical_dummy(n: Node) -> bool:
	if n == null or not is_instance_valid(n):
		return false
	if bool(n.get_meta("softnet_visual", false)):
		return false
	if n is CharacterBody3D and n.has_method("infection_cap"):
		return true
	return false


func _ensure_viewer() -> void:
	if _viewer != null and is_instance_valid(_viewer):
		return
	var existing: Node = get_node_or_null(VIEWER_NAME)
	if existing is Node3D:
		_viewer = existing as Node3D
		_tag_visual(_viewer, "clash_soft_viewer")
		return
	_viewer = Node3D.new()
	_viewer.name = VIEWER_NAME
	_tag_visual(_viewer, "clash_soft_viewer")
	_viewer.set_meta("site_pin", "")
	add_child(_viewer)
	_viewer.position = Vector3(-3.2, 2.4, 4.6)
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
		lab.text = "%s CLASH VIEWER (soft net)" % knowledge_label()
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
		_tag_visual(_puppet, "clash_host_puppet")
		return
	_puppet = Node3D.new()
	_puppet.name = PUPPET_NAME
	_tag_visual(_puppet, "clash_host_puppet")
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
		lab.text = "%s CLASH HOST (soft net)" % knowledge_label()
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
	n.set_meta("hack_authority", "host")
	n.set_meta("form_authority", "host")
	n.set_meta(kind, true)
	if not n.is_in_group(kind):
		n.add_to_group(kind)


func _show_clash_puppet(src: Node3D) -> void:
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
