extends Node
class_name AexionClash

const _WarScore = preload("res://scripts/systems/WarScore.gd")
## Aexion Clash vertical slice on TestArena.
## Soft lane objectives + War Score only — never permanent planet flip / P2W.

signal match_ended(winner: String)
signal lane_pressure_changed(pressures: Dictionary)

var war: Node
var kills: int = 0
var target_kills: int = 5
var active: bool = true
var _ended: bool = false

## Soft lane pressure 0..100 (info / WS only — not DPS)
var lane_pressure: Dictionary = {"TOP": 0.0, "MID": 0.0, "BOT": 0.0}
const PRESSURE_MAX := 100.0
const OBJECTIVE_WS := 2.0  ## soft WS when a lane hits 100
var _lane_objective_claimed: Dictionary = {"TOP": false, "MID": false, "BOT": false}
var _player_ref: Node3D = null
var _tick: float = 0.0

func _ready() -> void:
	war = _WarScore.new()
	war.name = "WarScore"
	add_child(war)
	if LayerContext:
		LayerContext.set_layer("Arena")
		LayerContext.seamless_stage = "S1"
		if LayerContext.active_quest_id == "":
			LayerContext.set_quest("clash_slice_v0")
	if GameManager:
		GameManager.toast_requested.emit(
			"Aexion Clash — kills + soft lane pressure · WS cap 60/day · no planet flip"
		)
	set_process(true)
	print("[AexionClash] arena layer S1 + lane objectives")

func bind_player(p: Node3D) -> void:
	_player_ref = p

func register_kill(lane: String = "MID") -> void:
	if _ended or not active:
		return
	kills += 1
	if war:
		war.on_kill()
	# Soft lane pressure from kills on that lane
	_add_pressure(lane, 12.0)
	if GameManager:
		GameManager.add_mastery("combat", 0.8)
	if kills >= target_kills:
		_end_match("player")

func _process(delta: float) -> void:
	if _ended or not active or _player_ref == null or not is_instance_valid(_player_ref):
		return
	_tick += delta
	if _tick < 0.25:
		return
	_tick = 0.0
	_tick_objectives()

func _tick_objectives() -> void:
	var pos: Vector3 = _player_ref.global_position
	var lane := _lane_at(pos)
	# Near enemy nexus (north -Z) — contest pressure
	var dist_gr: float = pos.distance_to(Vector3(0, 0, -24))
	var dist_cx: float = pos.distance_to(Vector3(0, 0, 24))
	if dist_gr < 8.0:
		_add_pressure(lane, 3.5)
	elif dist_gr < 14.0:
		_add_pressure(lane, 1.2)
	# Standing on lane strip far forward (z < -10) soft pressure
	if pos.z < -10.0:
		_add_pressure(lane, 0.8)
	# Defend home nexus presence (no combat power — tiny regen of friendly "hold")
	if dist_cx < 10.0:
		# decay enemy-side pressure slightly when holding home (soft only)
		for k in lane_pressure.keys():
			lane_pressure[k] = maxf(0.0, float(lane_pressure[k]) - 0.15)
		lane_pressure_changed.emit(lane_pressure.duplicate())

func _lane_at(pos: Vector3) -> String:
	if pos.x > 7.0:
		return "TOP"
	if pos.x < -7.0:
		return "BOT"
	return "MID"

func _add_pressure(lane: String, amount: float) -> void:
	if not lane_pressure.has(lane):
		lane = "MID"
	var prev: float = float(lane_pressure[lane])
	var nxt: float = clampf(prev + amount, 0.0, PRESSURE_MAX)
	lane_pressure[lane] = nxt
	if nxt >= PRESSURE_MAX and not bool(_lane_objective_claimed.get(lane, false)):
		_lane_objective_claimed[lane] = true
		if war:
			war.add_match_points(OBJECTIVE_WS)
		if GameManager:
			GameManager.toast_requested.emit(
				"Lane objective %s secured (+%.0f soft WS) — not permanent map control" % [lane, OBJECTIVE_WS]
			)
			GameManager.add_mastery("logistics", 1.0)
		# Win condition alternate: all 3 lanes soft-secured
		var all_done := true
		for k in _lane_objective_claimed.keys():
			if not bool(_lane_objective_claimed[k]):
				all_done = false
				break
		if all_done:
			_end_match("player_lanes")
	lane_pressure_changed.emit(lane_pressure.duplicate())

func _end_match(winner: String) -> void:
	if _ended:
		return
	_ended = true
	active = false
	if war:
		war.on_match_win()
		war.emit_soft_influence()
	match_ended.emit(winner)
	if GameManager:
		GameManager.toast_requested.emit(
			"Clash complete (%s) — soft influence only, no permanent flip" % winner
		)
	print("[AexionClash] match end → ", winner)

func status_line() -> String:
	var ws: String = war.hud_line() if war else "WS —"
	return "CLASH %d/%d  |  %s" % [kills, target_kills, ws]

func lane_hud_line() -> String:
	return "PRESSURE T%.0f M%.0f B%.0f /100" % [
		float(lane_pressure.get("TOP", 0.0)),
		float(lane_pressure.get("MID", 0.0)),
		float(lane_pressure.get("BOT", 0.0)),
	]

func objectives_secured() -> int:
	var n := 0
	for k in _lane_objective_claimed.keys():
		if bool(_lane_objective_claimed[k]):
			n += 1
	return n
