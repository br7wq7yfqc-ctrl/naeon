extends Node
## NP-A: one local visitor flies the existing SCM / HOVER / LAND loop.
## NP-B: after LAND, same PadBaseController occupy / harvest as the player.
## Not a second IFCS, not G1, not a private yield table.

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")

enum Phase { IDLE, TAKEOFF, CLIMB, TRANSIT, APPROACH, LAND }

var _ship: CharacterBody3D = null
var _pad: Node3D = null
var _phase: int = Phase.IDLE
var _phase_t: float = 0.0
var _auto: bool = true
var _fast: bool = false
var _saw_takeoff: bool = false
var _saw_land: bool = false
var _loop_done: bool = false
var _gear_at_land: bool = false
var _modes: Dictionary = {}
var _land_pad_name: String = ""
var _harvesting: bool = false
var _saw_harvest: bool = false
var _harvest_got: float = 0.0


func setup(ship: CharacterBody3D, pad: Node3D) -> void:
	_ship = ship
	_pad = pad
	_auto = not _cmdline_playtest()
	_seat_on_pad()
	set_physics_process(true)
	print("[NpcPilot] seated on ", pad.name if pad else "?", " auto=", _auto)
	if _auto:
		start_harvest()


func _cmdline_playtest() -> bool:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--playtest"):
			return true
	return false


func loop_done() -> bool:
	return _loop_done


func saw_takeoff() -> bool:
	return _saw_takeoff


func saw_land() -> bool:
	return _saw_land


func gear_down_at_land() -> bool:
	return _gear_at_land


func used_scm() -> bool:
	return bool(_modes.get("SCM", false))


func used_hover() -> bool:
	return bool(_modes.get("HOVER", false))


func land_pad_name() -> String:
	return _land_pad_name


func is_harvesting() -> bool:
	return _harvesting


func saw_harvest() -> bool:
	return _saw_harvest


func harvest_amount() -> float:
	return _harvest_got


func start_harvest() -> void:
	## Same occupy/harvest path as the player. Knowledge labels only.
	_harvesting = true
	_saw_harvest = false
	_harvest_got = 0.0
	if _ship != null and is_instance_valid(_ship):
		_ship.set_meta("npc_harvest", true)
		if not bool(_ship.get("is_landed")):
			_seat_on_pad()
	_bind_pad_harvest()
	_sign_harvest_label()
	print("[NpcPilot] occupy/harvest on ", _pad.name if _pad else "?")


func stop_harvest() -> void:
	_harvesting = false
	if _ship != null and is_instance_valid(_ship):
		_ship.set_meta("npc_harvest", false)


func start_loop(fast: bool = false) -> void:
	stop_harvest()
	_fast = fast
	_loop_done = false
	_saw_takeoff = false
	_saw_land = false
	_gear_at_land = false
	_modes.clear()
	_land_pad_name = ""
	_phase = Phase.TAKEOFF
	_phase_t = 0.0


func _seat_on_pad() -> void:
	if _ship == null or _pad == null:
		return
	if _ship.has_method("set_npc_driven"):
		_ship.set_npc_driven(true)
	if _ship.has_method("set_npc_axes"):
		_ship.set_npc_axes(Vector3.ZERO)
	var os := _open_space()
	if os != null and _ship.has_method("set_open_space_context"):
		_ship.set_open_space_context(os)
	_ship.global_position = _pad.global_position + _pad_up() * 4.0
	if "velocity" in _ship:
		_ship.velocity = Vector3.ZERO
	_ship.set("_gear_down", true)
	if _ship.has_method("_sync_landing_gear"):
		_ship._sync_landing_gear()
	if _ship.has_method("_set_mode"):
		_ship._set_mode(2)
	if _ship.has_method("_commit_land"):
		_ship._commit_land(_pad)
	elif _ship.has_method("_do_land"):
		_ship._do_land()


func _open_space() -> Node:
	var tree := get_tree()
	if tree:
		return tree.get_first_node_in_group("open_space")
	return null


func _pad_up() -> Vector3:
	if _pad != null and _pad.has_meta("pad_up"):
		return (_pad.get_meta("pad_up") as Vector3).normalized()
	return Vector3.UP


func _physics_process(delta: float) -> void:
	if _ship == null or not is_instance_valid(_ship) or _pad == null:
		return
	_note_mode()
	if _phase == Phase.IDLE:
		if _ship.has_method("set_npc_axes"):
			_ship.set_npc_axes(Vector3.ZERO)
		if _auto:
			_phase_t += delta
			if _phase_t >= 5.0:
				start_loop(false)
		return
	_phase_t += delta
	match _phase:
		Phase.TAKEOFF:
			_do_takeoff()
		Phase.CLIMB:
			_do_climb()
		Phase.TRANSIT:
			_do_transit()
		Phase.APPROACH:
			_do_approach()
		Phase.LAND:
			_try_land()


func _do_takeoff() -> void:
	if bool(_ship.get("is_landed")):
		_ship.set("_land_lock_t", 0.0)
		if _ship.has_method("_do_launch"):
			_ship._do_launch()
		return
	_saw_takeoff = true
	if _ship.has_method("_set_mode"):
		_ship._set_mode(2)
	_go(Phase.CLIMB)


func _do_climb() -> void:
	if _ship.has_method("_set_mode"):
		_ship._set_mode(2)
	if _ship.has_method("set_npc_axes"):
		_ship.set_npc_axes(Vector3(0.0, 1.0, 0.12))
	var need := 16.0 if _fast else 26.0
	if _height_over_pad() >= need or _phase_t > (1.1 if _fast else 3.2):
		_go(Phase.TRANSIT)


func _do_transit() -> void:
	if _ship.has_method("_set_mode"):
		_ship._set_mode(0)
	if _ship.has_method("set_npc_axes"):
		_ship.set_npc_axes(Vector3(0.45, 0.1, 0.3))
	if _phase_t > (0.4 if _fast else 1.2):
		_go(Phase.APPROACH)


func _do_approach() -> void:
	if _ship.has_method("_set_mode"):
		_ship._set_mode(2)
	_drop_gear()
	var hold: Vector3 = _pad.global_position + _pad_up() * 10.0
	var to_pad: Vector3 = hold - _ship.global_position
	var b: Basis = _ship.global_transform.basis
	var axes := Vector3(
		clampf(to_pad.dot(b.x), -1.0, 1.0),
		clampf(to_pad.dot(b.y), -1.0, 1.0),
		clampf(to_pad.dot(-b.z), -1.0, 1.0)
	)
	if to_pad.length() < 22.0:
		axes.y = -0.4
		axes.z *= 0.3
	if _ship.has_method("set_npc_axes"):
		_ship.set_npc_axes(axes)
	var spd: float = _ship.velocity.length() if "velocity" in _ship else 0.0
	var d: float = _ship.global_position.distance_to(_pad.global_position)
	if (d < 64.0 and spd < 11.0) or _phase_t > (2.2 if _fast else 5.5):
		_go(Phase.LAND)


func _try_land() -> void:
	if _ship.has_method("set_npc_axes"):
		_ship.set_npc_axes(Vector3.ZERO)
	if "velocity" in _ship:
		_ship.velocity = _ship.velocity.move_toward(Vector3.ZERO, 22.0)
	_drop_gear()
	if _ship.has_method("_set_mode"):
		_ship._set_mode(2)
	var d: float = _ship.global_position.distance_to(_pad.global_position)
	var snap: float = float(_ship.get("land_pad_snap_distance")) if "land_pad_snap_distance" in _ship else 90.0
	if d > snap * 0.92:
		_ship.global_position = _ship.global_position.lerp(_pad.global_position + _pad_up() * 8.0, 0.28)
	if not bool(_ship.get("is_landed")) and _ship.has_method("_do_land"):
		_ship._do_land()
	if bool(_ship.get("is_landed")):
		_saw_land = true
		_gear_at_land = bool(_ship.is_gear_down()) if _ship.has_method("is_gear_down") else bool(_ship.get("_gear_down"))
		var deck: Node = _ship.get_landed_pad() if _ship.has_method("get_landed_pad") else _pad
		_land_pad_name = str(deck.name) if deck != null else str(_pad.name)
		_loop_done = true
		_go(Phase.IDLE)
		_phase_t = 0.0
		if _ship.has_method("set_npc_axes"):
			_ship.set_npc_axes(Vector3.ZERO)
		if _auto:
			start_harvest()


func _drop_gear() -> void:
	_ship.set("_gear_down", true)
	if _ship.has_method("_sync_landing_gear"):
		_ship._sync_landing_gear()


func _go(p: int) -> void:
	_phase = p
	_phase_t = 0.0


func _height_over_pad() -> float:
	return (_ship.global_position - _pad.global_position).dot(_pad_up())


func _note_mode() -> void:
	if _ship != null and _ship.has_method("flight_mode_name"):
		_modes[str(_ship.flight_mode_name())] = true


func _pad_controller() -> Node:
	if _pad == null or not is_instance_valid(_pad):
		return null
	var named: Node = _pad.get_node_or_null("BaseCluster/PadBaseController")
	if named != null:
		return named
	return _pad.find_child("PadBaseController", true, false)


func _bind_pad_harvest() -> void:
	var ctrl := _pad_controller()
	if ctrl == null or not ctrl.has_signal("harvested"):
		return
	if not ctrl.harvested.is_connected(_on_pad_harvested):
		ctrl.harvested.connect(_on_pad_harvested)


func _on_pad_harvested(amount: float, _total: float) -> void:
	if not _harvesting or amount <= 0.0:
		return
	_saw_harvest = true
	_harvest_got += amount


func _sign_harvest_label() -> void:
	if _ship == null or not is_instance_valid(_ship):
		return
	var grot := false
	if _ship.has_method("get_faction"):
		grot = str(_ship.get_faction()) == "gROT"
	var lab: Label3D = _ship.get_node_or_null("Label") as Label3D
	if lab == null:
		lab = _ship.get_node_or_null("StatusLabel") as Label3D
	if lab:
		lab.text = "%s · %s" % [_SoftK.traffic_label("visitor"), _SoftK.yield_label(grot)]
