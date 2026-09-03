extends Node
class_name ClashWaves
## AR-C: timed minion waves on existing ClashLanes (Predecessor bar).
## AR-T: first host-authority lane-wave seed — same CombatDummy, Pulse 11,
## SoftKnowledge WAVE / MINION only. Not a 13th kit. No shop / P2W.
## AR-U XP from a last-hit is a SoftKnowledge label only — never Pulse.

signal wave_spawned(wave_index: int, count: int)

const WAVE_INTERVAL := 16.0
const FIRST_WAVE_DELAY := 0.2
const STAGGER := 0.28
const PULSE_DAMAGE := 11.0

var wave_index: int = 0
var last_wave_count: int = 0
var _arena: Node = null
var _lanes: Node = null
var _dummy_scene: PackedScene = null
var _timer: float = 0.0
var _started: bool = false
var _spawn_q: Array = []
var _stagger_t: float = 0.0

func _ready() -> void:
	name = "ClashWaves"
	add_to_group("clash_waves")
	set_process(true)


func bind(arena: Node, lanes: Node, dummy_scene: PackedScene) -> void:
	_arena = arena
	_lanes = lanes
	_dummy_scene = dummy_scene
	_started = true
	print("[ClashWaves] bound lanes=", lanes != null, " dummy=", dummy_scene != null)
	_queue_wave()
	if not _spawn_q.is_empty():
		var e = _spawn_q.pop_front()
		_spawn_minion(str(e[0]), str(e[1]), int(e[2]))
	_timer = WAVE_INTERVAL


func living_minions() -> Array:
	var out: Array = []
	var tree := get_tree()
	if tree == null:
		return out
	for n in tree.get_nodes_in_group("clash_minion"):
		if n == null or not is_instance_valid(n):
			continue
		if n.get("_alive") == false:
			continue
		out.append(n)
	return out


func _process(delta: float) -> void:
	if not _started or _dummy_scene == null or _lanes == null:
		return
	_drain_queue(delta)
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = WAVE_INTERVAL
	_queue_wave()


func _queue_wave() -> void:
	var live := living_minions().size()
	var cap := _live_cap()
	if live >= cap:
		print("[ClashWaves] skip wave live=", live, " cap=", cap)
		return
	var lanes: PackedStringArray = _wave_lanes()
	var per := _per_side()
	var room := cap - live
	var planned: Array = []
	for lane in lanes:
		for fac in ["Cybernex", "gROT"]:
			for i in per:
				if planned.size() >= room:
					break
				planned.append([str(lane), str(fac), i])
			if planned.size() >= room:
				break
		if planned.size() >= room:
			break
	if planned.is_empty():
		return
	for e in planned:
		_spawn_q.append(e)
	_stagger_t = 0.0
	wave_index += 1
	last_wave_count = planned.size()
	wave_spawned.emit(wave_index, last_wave_count)
	print("[ClashWaves] wave ", wave_index, " queued n=", last_wave_count, " lanes=", ",".join(lanes))
	if wave_index == 1 and GameManager:
		GameManager.toast_requested.emit(
			"%s — CombatDummy %s · Pulse 11 · host · no shop · no P2W" % [
				wave_soft_label(), minion_soft_label(),
			]
		)


func _drain_queue(delta: float) -> void:
	if _spawn_q.is_empty():
		return
	_stagger_t -= delta
	if _stagger_t > 0.0:
		return
	_stagger_t = STAGGER
	var e = _spawn_q.pop_front()
	_spawn_minion(str(e[0]), str(e[1]), int(e[2]))


func _spawn_minion(lane: String, fac: String, idx: int) -> void:
	if _dummy_scene == null or _lanes == null:
		return
	var d: Node = _dummy_scene.instantiate()
	d.set("faction", fac)
	d.set("can_move", true)
	d.set("lane_march", true)
	d.set("one_shot", true)
	d.set("grant_economy", false)
	d.set("max_health", 40.0)
	d.set("move_speed", 3.4)
	d.set("attack_damage", PULSE_DAMAGE)
	d.set("attack_range", 8.0)
	d.set("aggro_range", 10.0)
	d.set("attack_cooldown", 1.35)
	d.set("respawn_time", 0.0)
	d.set("intel_name", minion_soft_label())
	add_child(d)
	var origin: Vector3 = _lane_origin(lane, fac)
	origin.z += float(idx) * (1.15 if fac == "Cybernex" else -1.15)
	d.global_position = origin
	d.set_meta("lane", lane)
	d.set_meta("clash_wave", true)
	d.set_meta("combat_authority", "host")
	d.add_to_group("clash_minion")
	if d.has_method("set_lane_path"):
		d.set_lane_path(_lane_path(lane, fac))
	if d.has_signal("died"):
		d.died.connect(_on_minion_died.bind(lane, fac))
	if SoftScanCache:
		SoftScanCache.invalidate_enemies()


func _on_minion_died(lane: String, _fac: String) -> void:
	if SoftScanCache:
		SoftScanCache.invalidate_enemies()
	var tree := get_tree()
	if tree == null:
		return
	var clash: Node = tree.get_first_node_in_group("aexion_clash")
	if clash and clash.has_method("register_minion_down"):
		clash.register_minion_down(lane)
	elif tree.get_first_node_in_group("clash_local_match"):
		var local: Node = tree.get_first_node_in_group("clash_local_match")
		if local != null and local.has_method("register_minion_xp"):
			local.register_minion_xp()


func _wave_lanes() -> PackedStringArray:
	var gq := get_node_or_null("/root/GraphicsQuality")
	var tier := 1
	if gq:
		tier = int(gq.tier)
	if tier <= 0:
		return PackedStringArray(["MID"])
	return PackedStringArray(["TOP", "MID", "BOT"])


func _per_side() -> int:
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and int(gq.tier) >= 2:
		return 3
	return 2


func _live_cap() -> int:
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and "max_enemies" in gq:
		return maxi(4, int(gq.max_enemies))
	return 8


func pulse_damage() -> float:
	return PULSE_DAMAGE


func is_host_authority() -> bool:
	return true


func wave_soft_label() -> String:
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if SoftK and SoftK.has_method("wave_label"):
		return str(SoftK.wave_label())
	return "WAVE"


func minion_soft_label() -> String:
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if SoftK and SoftK.has_method("minion_label"):
		return str(SoftK.minion_label())
	return "MINION"


func _lane_origin(lane: String, fac: String) -> Vector3:
	if _lanes != null and _lanes.has_method("lane_spawn_origin"):
		return _lanes.lane_spawn_origin(lane, fac)
	var x := 0.0
	if lane == "TOP":
		x = 14.0
	elif lane == "BOT":
		x = -14.0
	if fac == "Cybernex":
		return Vector3(x, 0.1, 12.4)
	return Vector3(x, 0.1, -5.4)


func _lane_path(lane: String, fac: String) -> Array:
	if _lanes != null and _lanes.has_method("lane_march_path"):
		return _lanes.lane_march_path(lane, fac)
	var x := 0.0
	if lane == "TOP":
		x = 14.0
	elif lane == "BOT":
		x = -14.0
	if fac == "Cybernex":
		return [
			Vector3(x, 0.1, 8.0),
			Vector3(x, 0.1, 0.0),
			Vector3(x, 0.1, -8.0),
			Vector3(x, 0.1, -16.0),
			Vector3(x, 0.1, -23.0),
		]
	return [
		Vector3(x, 0.1, -2.0),
		Vector3(x, 0.1, 6.0),
		Vector3(x, 0.1, 16.0),
		Vector3(x, 0.1, 20.5),
		Vector3(x, 0.1, 23.5),
	]
