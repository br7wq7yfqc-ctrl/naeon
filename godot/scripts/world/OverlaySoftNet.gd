extends Node3D
class_name OverlaySoftNet
## SN-C: second local viewer on ST-A Strategy overlay (key B) sees a SoftNet
## visual puppet of the host pad / strategy actor (habitat / extractor / modules).
## SoftNet pose only — same bind_visual_puppet path as SN-A / SN-B.
## Host keeps Pulse / occupy / Hack. No second physical pad modules. Not ENet. G5 closed.

const _Builder = preload("res://scripts/world/BaseBuilder.gd")
const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")

const VIEWER_NAME := "OverlaySoftViewer"
const PUPPET_NAME := "OverlayStrategyPuppet"
const LEGAL_PADS := ["Pad_North", "Pad_Approach", "Pad_Flank"]

var _overlay: Node = null
var _viewer: Node3D = null
var _puppet: Node3D = null
var _pose: Dictionary = {}


func _ready() -> void:
	name = "OverlaySoftNet"
	set_meta("site_pin", "")
	set_meta("mobile_site", false)
	set_meta("softnet_visual", true)
	set_meta("combat_authority", "host")
	set_meta("occupy_authority", "host")
	set_meta("hack_authority", "host")
	if not is_in_group("overlay_softnet"):
		add_to_group("overlay_softnet")
	_ensure_viewer()
	_ensure_puppet()
	sync_from_host()


func _process(_delta: float) -> void:
	_follow_host_actor()


func bind(overlay: Node) -> void:
	if overlay == null or not is_instance_valid(overlay):
		return
	_overlay = overlay
	set_meta("site_pin", "")
	_ensure_viewer()
	_ensure_puppet()
	sync_from_host()


func viewer() -> Node3D:
	_ensure_viewer()
	return _viewer if _viewer != null and is_instance_valid(_viewer) else null


func strategy_puppet() -> Node3D:
	_ensure_puppet()
	return _puppet if _puppet != null and is_instance_valid(_puppet) else null


func combat_authority() -> String:
	return "host"


func occupy_authority() -> String:
	return "host"


func hack_authority() -> String:
	return "host"


func is_host_authority() -> bool:
	return true


func knowledge_label() -> String:
	## SoftKnowledge / HUD word only. Never DPS / yield / Pulse / Hack.
	return _SoftK.net_visual_label()


func has_second_physical_module() -> bool:
	## SN-C never instantiates a pad habitat / extractor / module.
	if _is_physical_module(_puppet):
		return true
	for c in get_children():
		if _is_physical_module(c) and not bool(c.get_meta("softnet_visual", false)):
			return true
	return false


func observed_pose() -> Dictionary:
	if _pose.is_empty():
		sync_from_host()
	return _pose.duplicate()


func viewer_sees_strategy_puppet() -> bool:
	var p := strategy_puppet()
	return p != null and p.visible and bool(p.get_meta("softnet_visual", false))


func physical_module_count() -> int:
	var pad := host_pad()
	if pad == null:
		return 0
	var n := 0
	var seen: Dictionary = {}
	for a in _pad_strategy_actors(pad):
		if a == null or not is_instance_valid(a):
			continue
		if seen.has(a):
			continue
		seen[a] = true
		if bool(a.get_meta("softnet_visual", false)):
			continue
		if bool(a.get_meta("overlay_strategy_puppet", false)):
			continue
		n += 1
	return n


func host_pad() -> Node3D:
	var ov := _strategy_overlay()
	if ov != null:
		if ov.has_method("active_pad"):
			var p: Node3D = ov.active_pad()
			if _is_legal_pad(p):
				return p
		if ov.has_method("_pick_pad"):
			var q: Node3D = ov._pick_pad()
			if _is_legal_pad(q):
				return q
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("landing_pads"):
		if _is_legal_pad(n):
			return n as Node3D
	return null


func host_strategy_actor() -> Node3D:
	var pad := host_pad()
	if pad == null:
		return null
	var actors := _pad_strategy_actors(pad)
	for a in actors:
		if a != null and is_instance_valid(a) and not bool(a.get_meta("softnet_visual", false)):
			return a
	return null


func actor_kind(n: Node3D = null) -> String:
	var src: Node3D = n if n != null else host_strategy_actor()
	if src == null or not is_instance_valid(src):
		return "none"
	var mt := str(src.get_meta("module_type", ""))
	if mt == "habitat" or str(src.name).find("Habitat") >= 0:
		return "habitat"
	if mt == "extractor" or str(src.name).find("Extractor") >= 0:
		return "extractor"
	if mt != "":
		return "module"
	if src.has_meta("pad_turret") or src.has_meta("pad_storage") or src.has_meta("pad_hangar_stub"):
		return "module"
	if src.has_meta("printed_module") or src.has_meta("player_module") or src.has_meta("npc_module"):
		return "module"
	return "module"


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
	var actor := host_strategy_actor()
	if actor != null:
		_show_strategy_puppet(actor)
	else:
		_hide_puppet()
	_seat_viewer(actor)
	var kind := actor_kind(actor)
	_pose = {
		"overlay_mode": kind,
		"actor_pos": actor.global_position if actor != null else Vector3.ZERO,
		"authority": "host",
		"occupy_authority": "host",
		"hack_authority": "host",
		"physical_modules": physical_module_count(),
		"knowledge": knowledge_label(),
		"g5_closed": is_g5_closed(),
	}
	_bind_soft_visuals()


func _follow_host_actor() -> void:
	var actor := host_strategy_actor()
	if actor == null:
		return
	if _puppet == null or not is_instance_valid(_puppet):
		return
	_puppet.global_transform = actor.global_transform
	_puppet.visible = true
	_seat_viewer(actor)
	if not _pose.is_empty():
		_pose["overlay_mode"] = actor_kind(actor)
		_pose["actor_pos"] = actor.global_position
		_pose["physical_modules"] = physical_module_count()


func _seat_viewer(actor: Node3D) -> void:
	if _viewer == null or not is_instance_valid(_viewer):
		return
	var pad := host_pad()
	var origin: Node3D = actor if actor != null and is_instance_valid(actor) else pad
	if origin == null or not is_instance_valid(origin):
		return
	var up := Vector3.UP
	if pad != null and pad.has_meta("pad_up"):
		up = (pad.get_meta("pad_up") as Vector3).normalized()
	_viewer.global_position = origin.global_position + up * 14.0 + Vector3(-6.0, 0.0, 8.0)
	_viewer.look_at(origin.global_position, up)


func _strategy_overlay() -> Node:
	if _overlay != null and is_instance_valid(_overlay):
		return _overlay
	var tree := get_tree()
	if tree == null:
		return null
	var ov: Node = tree.get_first_node_in_group("strategy_overlay")
	if ov != null:
		_overlay = ov
	return ov


func _pad_strategy_actors(pad: Node3D) -> Array:
	var out: Array = []
	if pad == null or not is_instance_valid(pad):
		return out
	var hab: Node3D = _Builder.player_module_on(pad)
	if hab != null:
		out.append(hab)
	var ext: Node = pad.get_node_or_null("PadHarvestExtractor")
	if ext is Node3D:
		out.append(ext)
	var printed: Node3D = _Builder.printed_module_on(pad)
	if printed != null:
		out.append(printed)
	var turret: Node3D = _Builder.pad_turret_on(pad)
	if turret != null:
		out.append(turret)
	var storage: Node3D = _Builder.pad_storage_on(pad)
	if storage != null:
		out.append(storage)
	var hangar: Node3D = _Builder.pad_hangar_stub_on(pad)
	if hangar != null:
		out.append(hangar)
	var npc: Node3D = _Builder.npc_module_on(pad)
	if npc != null:
		out.append(npc)
	return out


func _is_legal_pad(n: Node) -> bool:
	if n == null or not is_instance_valid(n):
		return false
	return str(n.name) in LEGAL_PADS


func _is_physical_module(n: Node) -> bool:
	if n == null or not is_instance_valid(n):
		return false
	if bool(n.get_meta("softnet_visual", false)):
		return false
	if n.has_method("combat_stats") and n.has_method("module_type"):
		return true
	if n.has_method("bind_pad") and str(n.name).find("Extractor") >= 0:
		return true
	if n.has_meta("player_module") or n.has_meta("printed_module") or n.has_meta("npc_module"):
		return true
	if n.has_meta("pad_turret") or n.has_meta("pad_storage") or n.has_meta("pad_hangar_stub"):
		return true
	return false


func _ensure_viewer() -> void:
	if _viewer != null and is_instance_valid(_viewer):
		return
	var existing: Node = get_node_or_null(VIEWER_NAME)
	if existing is Node3D:
		_viewer = existing as Node3D
		_tag_visual(_viewer, "overlay_soft_viewer")
		return
	_viewer = Node3D.new()
	_viewer.name = VIEWER_NAME
	_tag_visual(_viewer, "overlay_soft_viewer")
	_viewer.set_meta("site_pin", "")
	add_child(_viewer)
	_viewer.position = Vector3(-6.0, 14.0, 8.0)
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
		lab.text = "%s OVERLAY VIEWER (soft net)" % knowledge_label()
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
		_tag_visual(_puppet, "overlay_strategy_puppet")
		return
	_puppet = Node3D.new()
	_puppet.name = PUPPET_NAME
	_tag_visual(_puppet, "overlay_strategy_puppet")
	_puppet.set_meta("site_pin", "")
	add_child(_puppet)
	_puppet.visible = false
	if DisplayServer.get_name() != "headless":
		var body := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.4, 1.6, 2.4)
		body.mesh = box
		body.position.y = 0.8
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
		lab.text = "%s STRATEGY (soft net)" % knowledge_label()
		lab.font_size = 18
		lab.modulate = Color(0.65, 0.95, 1.0, 0.75)
		lab.position = Vector3(0, 2.4, 0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_puppet.add_child(lab)
	if SoftNetSession and SoftNetSession.has_method("bind_visual_puppet"):
		SoftNetSession.bind_visual_puppet(_puppet)


func _tag_visual(n: Node3D, kind: String) -> void:
	n.set_meta("softnet_visual", true)
	n.set_meta("combat_authority", "host")
	n.set_meta("occupy_authority", "host")
	n.set_meta("hack_authority", "host")
	n.set_meta(kind, true)
	if not n.is_in_group(kind):
		n.add_to_group(kind)


func _show_strategy_puppet(src: Node3D) -> void:
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
