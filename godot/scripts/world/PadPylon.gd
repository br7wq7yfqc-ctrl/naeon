extends Node3D
class_name PadPylon
## ST-O: one player-pad Firewall node (CX) / Spore pylon (gROT).
## Occupied unnamed pad via BaseBuilder. Not Clash Turret. Not occupy ClaimBeaconVis.
## Structure Hack resist / Infection pressure. Same fortify budget both factions.
## Host authority. Infection cap 5. Knowledge labels only. No SITE_*. No P2W.

const _SoftK := preload("res://scripts/systems/SoftKnowledge.gd")

const FORTIFY_RANGE := 16.0
const TICK_SEC := 1.5
const MAX_HP := 120.0
const REFUSE_CAP := "Infection cap 5"

var faction: String = "Cybernex"
var max_health: float = MAX_HP
var health: float = MAX_HP
var _alive: bool = true
var _tick: float = 0.0
var _label: Label3D = null


func setup(fac: String) -> void:
	_bind_pylon(fac)


func _bind_pylon(fac: String) -> void:
	faction = fac if fac != "" else "Cybernex"
	name = "PadPylon"
	health = max_health
	_alive = true
	_tick = 0.0
	set_meta("site_pin", "")
	set_meta("module_type", "pylon")
	set_meta("pad_pylon", true)
	set_meta("occupy_pylon", false)
	set_meta("player_module", false)
	set_meta("npc_module", false)
	set_meta("printed_module", false)
	set_meta("combat_authority", "host")
	set_meta("p2w_repair", false)
	set_meta("clash_turret", false)
	set_meta("pad_turret", false)
	if not is_in_group("pad_pylons"):
		add_to_group("pad_pylons")
	_spawn_marker()
	_spawn_mesh()
	_ensure_label()
	set_process(true)
	print("[PadPylon] ST-O on pad fac=", faction, " hp=", max_health, " range=", FORTIFY_RANGE)


func _process(delta: float) -> void:
	if not _alive:
		return
	_tick += delta
	if _tick < TICK_SEC:
		return
	_tick = 0.0
	try_fortify()


func module_type() -> String:
	return "pylon"


func combat_stats() -> int:
	## Structure fortify (unlike ST-A habitat 0). Numbers stay ±1 stack / HP 120.
	return 1


func pulse_dps() -> float:
	## Not ST-H turret. Infection / Firewall only.
	return 0.0


func combat_authority() -> String:
	return "host"


func is_host_authority() -> bool:
	return true


func has_p2w_repair() -> bool:
	return false


func try_cash_repair_skip(_amount: float = 0.0) -> bool:
	return false


func try_cash_cleanse(_paid: float = 0.0) -> bool:
	## No cash-shop cleanse. story ≠ power.
	return false


func get_faction() -> String:
	return faction


func is_alive() -> bool:
	return _alive


func is_occupy_beacon() -> bool:
	return false


func pylon_label() -> String:
	return _SoftK.pylon_label(faction == "gROT")


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
	## ST-F theme only. Does not change range / HP / ±1 budget.
	if faction_name == "" or faction_name == "Contested" or faction_name == "Neutral":
		return
	faction = faction_name
	_paint_mesh()
	_refresh_label()


func take_damage(amount: float, _source_faction: String = "") -> void:
	if not _alive:
		return
	health = maxf(0.0, health - amount)
	_refresh_label()
	if health <= 0.0:
		_die()


func try_fortify(target = null) -> String:
	if faction == "gROT":
		return try_spore(target)
	return try_firewall(target)


func try_firewall(target = null) -> String:
	## CX: Firewall −1 Infection on a hostile in range. Same HF-A grammar.
	if not _alive:
		return "destroyed"
	var t: Node = target as Node if target != null else _find_hostile()
	if t == null or not is_instance_valid(t):
		return "no target"
	if not _in_range(t):
		return "out of range"
	if t.has_method("purge_infection"):
		t.purge_infection(1)
		return ""
	if t.has_method("remove_one"):
		t.remove_one()
		return ""
	var inf: Node = t.get_node_or_null("InfectionStatus")
	if inf != null and inf.has_method("remove_one"):
		inf.remove_one()
		return ""
	return "no InfectionStatus"


func try_spore(target = null) -> String:
	## gROT: +1 Infection on a hostile in range. Cap 5 refuse.
	if not _alive:
		return "destroyed"
	var t: Node = target as Node if target != null else _find_hostile()
	if t == null or not is_instance_valid(t):
		return "no target"
	if not _in_range(t):
		return "out of range"
	if t.has_method("apply_infection"):
		var why := str(t.apply_infection(1))
		if why != "":
			return why
		return ""
	var inf: Node = t.get_node_or_null("InfectionStatus")
	if inf != null and inf.has_method("try_add_one"):
		return str(inf.try_add_one())
	return "no InfectionStatus"


func _die() -> void:
	if not _alive:
		return
	_alive = false
	_refresh_label()
	visible = false
	print("[PadPylon] destroyed · no permadeath")


func _spawn_marker() -> void:
	var n := Node3D.new()
	n.name = "Pylon"
	n.set_meta("site_pin", "")
	n.set_meta("outpost_part", "pad_pylon")
	add_child(n)


func _spawn_mesh() -> void:
	var n: Node3D = get_node_or_null("Pylon") as Node3D
	if n == null:
		return
	var shaft := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.55
	cyl.height = 3.4
	shaft.mesh = cyl
	shaft.name = "PylonMesh"
	shaft.position = Vector3(0.0, 1.7, 0.0)
	n.add_child(shaft)
	var cap := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.42
	sph.height = 0.84
	cap.mesh = sph
	cap.name = "PylonCap"
	cap.position = Vector3(0.0, 3.5, 0.0)
	n.add_child(cap)
	_paint_mesh()


func _paint_mesh() -> void:
	var col := _faction_color()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.45
	var n: Node = get_node_or_null("Pylon")
	if n == null:
		return
	for c in n.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).material_override = mat


func _faction_color() -> Color:
	return Color(0.92, 0.18, 0.38) if faction == "gROT" else Color(0.22, 0.78, 0.95)


func _ensure_label() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 20
	_label.position = Vector3(0, 4.2, 0)
	add_child(_label)
	_refresh_label()


func _refresh_label() -> void:
	if _label == null:
		return
	var lab := pylon_label()
	if not _alive:
		_label.text = "%s DESTROYED" % lab
	else:
		_label.text = "%s %s" % [lab, faction]


func _in_range(n: Node) -> bool:
	if not (n is Node3D):
		return false
	return global_position.distance_to((n as Node3D).global_position) <= FORTIFY_RANGE


func _find_hostile() -> Node3D:
	var best: Node3D = null
	var best_d: float = FORTIFY_RANGE
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
