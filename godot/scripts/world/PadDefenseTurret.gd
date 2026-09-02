extends Node3D
class_name PadDefenseTurret
## ST-H: one player-pad defense module. Not Clash Turret.gd / OUTER 160.
## Occupied unnamed pad only. Host-authority Pulse (11). Knowledge labels only.
## Destroyed turret ≠ permadeath. No P2W repair. No SITE_*.

const _Prop := preload("res://scripts/assets/GlbProp.gd")
const _SoftK := preload("res://scripts/systems/SoftKnowledge.gd")
const _Pool := preload("res://scripts/combat/ProjectilePool.gd")

const PULSE_DPS := 11.0
const PULSE_RANGE := 16.0
const MAX_HP := 120.0

var faction: String = "Cybernex"
var max_health: float = MAX_HP
var health: float = MAX_HP
var _alive: bool = true
var _label: Label3D = null


func setup(fac: String) -> void:
	faction = fac if fac != "" else "Cybernex"
	name = "PadDefenseTurret"
	health = max_health
	_alive = true
	set_meta("site_pin", "")
	set_meta("module_type", "turret")
	set_meta("pad_turret", true)
	set_meta("player_module", false)
	set_meta("npc_module", false)
	set_meta("printed_module", false)
	set_meta("combat_authority", "host")
	set_meta("p2w_repair", false)
	set_meta("clash_turret", false)
	if not is_in_group("pad_defense_turrets"):
		add_to_group("pad_defense_turrets")
	_spawn_marker()
	_spawn_mesh()
	_ensure_label()
	print("[PadDefenseTurret] ST-H on pad fac=", faction, " hp=", max_health, " pulse=", PULSE_DPS)


func module_type() -> String:
	return "turret"


func combat_stats() -> int:
	## Explicit defense (unlike ST-A habitat 0). Numbers stay Pulse 11 / HP 120.
	return 1


func pulse_dps() -> float:
	return PULSE_DPS


func combat_authority() -> String:
	return "host"


func is_host_authority() -> bool:
	return true


func has_p2w_repair() -> bool:
	return false


func try_cash_repair_skip(_amount: float = 0.0) -> bool:
	return false


func get_faction() -> String:
	return faction


func is_alive() -> bool:
	return _alive


func turret_label() -> String:
	return _SoftK.turret_label()


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


func reload_for_faction(faction_name: String) -> void:
	## ST-F theme only. Does not change Pulse / HP / repair.
	if faction_name == "" or faction_name == "Contested" or faction_name == "Neutral":
		return
	faction = faction_name
	var mesh: Node = get_node_or_null("Turret/TurretMesh")
	if mesh != null and mesh.has_method("reload_for_faction"):
		mesh.reload_for_faction(faction_name)
	_refresh_label()


func take_damage(amount: float, _source_faction: String = "") -> void:
	if not _alive:
		return
	health = maxf(0.0, health - amount)
	_refresh_label()
	if health <= 0.0:
		_die()


func try_pulse(target = null) -> bool:
	if not _alive:
		return false
	var t: Node = target as Node if target != null else _find_hostile()
	if t == null or not is_instance_valid(t):
		return false
	if not _is_hostile(t):
		return false
	if global_position.distance_to((t as Node3D).global_position) > PULSE_RANGE:
		return false
	if t.has_method("take_damage"):
		t.take_damage(PULSE_DPS, faction)
	var aim_pt: Vector3 = (t as Node3D).global_position
	if t.has_method("hurtbox_center"):
		aim_pt = t.hurtbox_center()
	var origin: Vector3 = global_position + Vector3.UP * 1.4
	var dir: Vector3 = (aim_pt - origin).normalized()
	var col := Color(1.0, 0.2, 0.4) if faction == "gROT" else Color(0.3, 0.95, 1.0)
	_Pool.spawn(get_tree(), origin, dir, 18.0, 0.0, faction, col, 0.7, [self])
	return true


func _die() -> void:
	if not _alive:
		return
	_alive = false
	_refresh_label()
	visible = false
	print("[PadDefenseTurret] destroyed · no permadeath")


func _spawn_marker() -> void:
	var n := Node3D.new()
	n.name = "Turret"
	n.set_meta("site_pin", "")
	n.set_meta("outpost_part", "pad_turret")
	add_child(n)


func _spawn_mesh() -> void:
	var n: Node3D = get_node_or_null("Turret") as Node3D
	if n == null:
		return
	var fx := "cybernex" if faction != "gROT" else "grot"
	var prop := Node3D.new()
	prop.set_script(_Prop)
	prop.set("relative_path", "props/turret_emplacement/turret_emplacement_%s_lod1.glb" % fx)
	prop.set("scale_factor", 1.3)
	prop.set("add_static_collision", true)
	prop.name = "TurretMesh"
	n.add_child(prop)


func _ensure_label() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 20
	_label.position = Vector3(0, 2.4, 0)
	add_child(_label)
	_refresh_label()


func _refresh_label() -> void:
	if _label == null:
		return
	var lab := turret_label()
	if not _alive:
		_label.text = "%s DESTROYED" % lab
	else:
		_label.text = "%s %s\nHP %.0f" % [lab, faction, health]


func _find_hostile() -> Node3D:
	var best: Node3D = null
	var best_d: float = PULSE_RANGE
	var tree := get_tree()
	var cands: Array = []
	if tree:
		cands.append_array(tree.get_nodes_in_group("pad_pvp_rival"))
		cands.append_array(tree.get_nodes_in_group("enemy"))
	for n in cands:
		if not _is_hostile(n):
			continue
		if not (n is Node3D):
			continue
		var d: float = global_position.distance_to((n as Node3D).global_position)
		if d < best_d:
			best = n as Node3D
			best_d = d
	return best


func _is_hostile(n: Node) -> bool:
	if n == null or not is_instance_valid(n) or n == self:
		return false
	if n.is_in_group("clash_camp") or n.is_in_group("clash_structure"):
		return false
	if n.has_meta("pad_guard_bt") and bool(n.get_meta("pad_guard_bt")):
		return false
	if n.has_meta("pad_traffic_role") and str(n.get_meta("pad_traffic_role")) == "guard":
		return false
	if n.get_script() != null and str(n.get_script().resource_path).ends_with("Turret.gd"):
		return false
	if n.has_method("is_alive") and not bool(n.is_alive()):
		return false
	if n.has_method("is_downed") and bool(n.is_downed()):
		return false
	if "_alive" in n and not bool(n._alive):
		return false
	if n.has_method("get_faction") and str(n.get_faction()) == faction:
		return false
	if "faction" in n and str(n.faction) == faction:
		return false
	if n.has_method("set_eva_profile") or n.has_method("set_pilot_active"):
		return false
	if n.is_in_group("pad_pvp_rival"):
		if "aggro_range" in n and float(n.get("aggro_range")) <= 0.0:
			return false
		return true
	return true
