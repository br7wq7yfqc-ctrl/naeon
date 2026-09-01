extends Node3D
class_name PadPvp
## PV-A: one host-authority rival CombatDummy on the occupied unnamed pad.
## Pulse 11 both ways. Win = rival HP → 0. No permadeath. Infection cap 5.
## SoftNet visual only. G5 stays closed. No SITE_*. Knowledge labels only.

const _DUMMY := preload("res://scenes/combat/CombatDummy.tscn")
const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
const PULSE_DPS := 11.0

var _traffic: Node = null
var _rival: Node3D = null
var _won: bool = false
var _viewer: Node3D = null


func _ready() -> void:
	name = "PadPvp"
	set_meta("site_pin", "")
	set_meta("mobile_site", false)
	set_meta("combat_authority", "host")
	set_meta("softnet_visual", true)
	set_meta("p2w_hp", false)
	if not is_in_group("pad_pvp"):
		add_to_group("pad_pvp")


func bind(traffic: Node) -> void:
	_traffic = traffic
	set_meta("site_pin", "")
	_spawn_rival()
	_ensure_viewer()
	_bind_soft_visuals()


func get_rival() -> Node3D:
	if _rival != null and is_instance_valid(_rival):
		return _rival
	return get_node_or_null("PadRivalDummy") as Node3D


func rival_label() -> String:
	return _SoftK.rival_label()


func combat_authority() -> String:
	return "host"


func is_host_authority() -> bool:
	return true


func has_p2w_hp() -> bool:
	return false


func pulse_dps() -> float:
	return PULSE_DPS


func win_reached() -> bool:
	var r := get_rival()
	if r == null:
		return _won
	if r.has_method("is_alive") and not bool(r.is_alive()):
		_won = true
	elif "health" in r and float(r.health) <= 0.0:
		_won = true
	return _won


func try_rival_pulse(target: Node = null) -> bool:
	_arm_rival()
	var r := get_rival()
	if r == null or not r.has_method("try_pulse"):
		return false
	return bool(r.try_pulse(target))


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


func viewer() -> Node3D:
	_ensure_viewer()
	return _viewer if _viewer != null and is_instance_valid(_viewer) else null


func refresh_label() -> void:
	var r := get_rival()
	if r == null:
		return
	r.set("intel_name", rival_label())
	if r.has_method("_update_labels"):
		r._update_labels()


func _spawn_rival() -> void:
	if _rival != null and is_instance_valid(_rival):
		return
	var existing: Node = get_node_or_null("PadRivalDummy")
	if existing is Node3D:
		_rival = existing as Node3D
		_tag_rival(_rival)
		return
	if _DUMMY == null:
		return
	var d: Node = _DUMMY.instantiate()
	d.name = "PadRivalDummy"
	d.set("faction", "gROT")
	d.set("can_move", false)
	## Quiet until the walker Pulse-hits — keeps EVA-snap / HF-A off this dummy.
	d.set("aggro_range", 0.0)
	d.set("attack_range", 0.0)
	d.set("attack_damage", PULSE_DPS)
	d.set("attack_cooldown", 1.4)
	d.set("grant_economy", false)
	d.set("one_shot", false)
	d.set("intel_name", rival_label())
	d.set_meta("pad_traffic_role", "rival")
	d.set_meta("site_pin", "")
	_tag_rival(d)
	add_child(d)
	if d is Node3D:
		(d as Node3D).position = Vector3(4.0, 1.2, -8.0)
		d.set("_spawn_pos", (d as Node3D).global_position)
		_rival = d as Node3D
	if d.has_signal("died") and not d.died.is_connected(_on_rival_down):
		d.died.connect(_on_rival_down)
	if d.has_signal("damaged") and not d.damaged.is_connected(_on_rival_hit):
		d.damaged.connect(_on_rival_hit)
	print("[PadPvp] rival host-authority Pulse=", PULSE_DPS, " G5=closed")


func _on_rival_hit(_amount: float, _health_left: float) -> void:
	_arm_rival()


func _arm_rival() -> void:
	var r := get_rival()
	if r == null:
		return
	r.set("aggro_range", 20.0)
	r.set("attack_range", 16.0)
	r.set("attack_damage", PULSE_DPS)


func _on_rival_down() -> void:
	_won = true
	print("[PadPvp] win rival HP 0 · no permadeath")


func _tag_rival(n: Node) -> void:
	n.set_meta("softnet_visual", true)
	n.set_meta("combat_authority", "host")
	n.set_meta("p2w_hp", false)
	n.set_meta("site_pin", "")
	if not n.is_in_group("pad_pvp_rival"):
		n.add_to_group("pad_pvp_rival")


func _ensure_viewer() -> void:
	if _viewer != null and is_instance_valid(_viewer):
		return
	var existing: Node = get_node_or_null("PadPvpViewer")
	if existing is Node3D:
		_viewer = existing as Node3D
		_tag_visual(_viewer)
		return
	_viewer = Node3D.new()
	_viewer.name = "PadPvpViewer"
	_tag_visual(_viewer)
	_viewer.set_meta("site_pin", "")
	add_child(_viewer)
	_viewer.position = Vector3(-2.0, 1.6, -6.0)
	if SoftNetSession and SoftNetSession.has_method("bind_visual_puppet"):
		SoftNetSession.bind_visual_puppet(_viewer)


func _tag_visual(n: Node3D) -> void:
	n.set_meta("softnet_visual", true)
	n.set_meta("combat_authority", "host")
	n.set_meta("pad_pvp_viewer", true)


func _bind_soft_visuals() -> void:
	if SoftNetSession == null or not SoftNetSession.has_method("bind_visual_puppet"):
		return
	var r := get_rival()
	if r != null:
		SoftNetSession.bind_visual_puppet(r)
	if _viewer != null and is_instance_valid(_viewer):
		SoftNetSession.bind_visual_puppet(_viewer)
