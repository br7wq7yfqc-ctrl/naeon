extends Node
class_name VisitorBT
## BT-B: tiny 3-state visitor BT. No plugin. Not Clash waves. Not 10k CCU.
## approach unnamed pad → hold (occupy/harvest still legal) → leave.
## Host authority. Pulse DPS stays 11. NP-A flight / NP-B harvest numbers stay.
## Pad-guard BT-A stays. Knowledge labels only.

const PULSE_DPS := 11.0
const HOLD_ARRIVE := 28.0

const ST_APPROACH := "approach"
const ST_HOLD := "hold"
const ST_LEAVE := "leave"

var _pilot: Node = null
var _ship: Node3D = null
var _pad: Node3D = null
var _pad_up: Vector3 = Vector3.UP
var _state: String = ST_APPROACH
var _leave_req: bool = false


func _ready() -> void:
	name = "VisitorBT"
	set_meta("site_pin", "")
	set_meta("combat_authority", "host")
	set_meta("visitor_bt", true)
	if not is_in_group("visitor_bt"):
		add_to_group("visitor_bt")
	set_physics_process(false)


func bind(pilot: Node, ship: Node3D = null, pad: Node3D = null) -> void:
	_pilot = pilot
	_ship = ship
	if _ship == null and _pilot != null and _pilot.has_method("hull"):
		var hull: Node3D = _pilot.hull()
		if hull != null:
			_ship = hull
	_pad = pad
	if _pad != null and _pad.has_meta("pad_up"):
		var up: Variant = _pad.get_meta("pad_up")
		if up is Vector3 and (up as Vector3).length_squared() > 0.01:
			_pad_up = (up as Vector3).normalized()
	if _ship != null:
		_ship.set_meta("combat_authority", "host")
		_ship.set_meta("visitor_bt", true)
		_ship.set_meta("site_pin", "")
	if _pilot != null:
		_pilot.set_meta("combat_authority", "host")
		_pilot.set_meta("visitor_bt", true)
		_pilot.set_meta("site_pin", "")
	_leave_req = false
	_state = ST_APPROACH
	print("[VisitorBT] bind approach/hold/leave Pulse=", PULSE_DPS, " G5=closed")


func bt_state() -> String:
	return _state


func pulse_dps() -> float:
	return PULSE_DPS


func combat_authority() -> String:
	return "host"


func is_host_authority() -> bool:
	return true


func request_leave() -> void:
	_leave_req = true
	_state = ST_LEAVE


func request_approach() -> void:
	_leave_req = false
	_state = ST_APPROACH


func request_hold() -> void:
	_leave_req = false
	_state = ST_HOLD


func is_g5_closed() -> bool:
	if ResourceLoader.exists("res://scenes/world/ClashBeacon.tscn"):
		return false
	if ResourceLoader.exists("res://scripts/world/ClashFromWorld.gd"):
		return false
	if ResourceLoader.exists("res://scripts/world/ClashBeacon.gd"):
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


func tick(delta: float = 0.1, hint: String = "") -> String:
	var want := str(hint)
	if want == ST_LEAVE or _leave_req:
		_state = ST_LEAVE
		return _state
	if want == ST_HOLD:
		_leave_req = false
		_state = ST_HOLD
		return _state
	if want == ST_APPROACH:
		_leave_req = false
		_state = ST_APPROACH
		return _state
	if _is_leaving():
		_state = ST_LEAVE
	elif _is_holding():
		_state = ST_HOLD
	else:
		_state = ST_APPROACH
	return _state


func physics_tick(delta: float) -> void:
	## Observe NP-A/NP-B. Do not start a second flight loop.
	tick(delta)


func try_hold_harvest() -> bool:
	tick(0.0, ST_HOLD)
	if _state != ST_HOLD:
		return false
	if _pilot == null or not is_instance_valid(_pilot):
		return false
	if _pilot.has_method("start_harvest"):
		_pilot.start_harvest()
		return true
	return false


func _is_holding() -> bool:
	if _leave_req:
		return false
	if _ship == null or not is_instance_valid(_ship):
		return false
	if not bool(_ship.get("is_landed")):
		return false
	return _pad_dist() <= HOLD_ARRIVE


func _is_leaving() -> bool:
	if _leave_req:
		return true
	if _pilot == null or not is_instance_valid(_pilot):
		return false
	if "_phase" in _pilot:
		var phase: int = int(_pilot.get("_phase"))
		## NpcPilot.Phase: TAKEOFF=1, CLIMB=2, TRANSIT=3 — departing the plate.
		if phase >= 1 and phase <= 3:
			return true
	return false


func _pad_dist() -> float:
	if _ship == null or _pad == null:
		return 999.0
	var d: Vector3 = _ship.global_position - _pad.global_position
	d = d - _pad_up * d.dot(_pad_up)
	return d.length()
