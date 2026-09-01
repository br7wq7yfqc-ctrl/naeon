extends Node
class_name PadGuardBT
## BT-A: tiny 3-state pad-guard BT. No plugin. Not Clash waves. Not 10k CCU.
## patrol near the pad → engage SurfaceWalker in Pulse range → return when they leave.
## Host authority. Pulse DPS stays 11. Knowledge labels only. PV-A rival stays distinct.

const PULSE_DPS := 11.0
const PULSE_RANGE := 16.0
const LEAVE_RANGE := 22.0
const PATROL_RADIUS := 5.5
const ARRIVE := 1.2
const HOME_ARRIVE := 1.6
const LEASH := 12.0

const ST_PATROL := "patrol"
const ST_ENGAGE := "engage"
const ST_RETURN := "return"

var _guard: CharacterBody3D = null
var _home: Vector3 = Vector3.ZERO
var _home_local: Vector3 = Vector3.ZERO
var _pad_up: Vector3 = Vector3.UP
var _state: String = ST_PATROL
var _pts: Array[Vector3] = []
var _pt_i: int = 0
var _pulse_cd: float = 0.0


func _ready() -> void:
	name = "PadGuardBT"
	set_meta("site_pin", "")
	set_meta("combat_authority", "host")
	set_meta("pad_guard_bt", true)
	if not is_in_group("pad_guard_bt"):
		add_to_group("pad_guard_bt")
	set_physics_process(false)


func bind(guard: CharacterBody3D, pad: Node3D = null) -> void:
	_guard = guard
	if pad != null and pad.has_meta("pad_up"):
		var up: Variant = pad.get_meta("pad_up")
		if up is Vector3 and (up as Vector3).length_squared() > 0.01:
			_pad_up = (up as Vector3).normalized()
	if guard != null:
		_home = guard.global_position
		_home_local = guard.position
		guard.set("bt_driven", true)
		guard.set("can_move", true)
		guard.set("attack_damage", PULSE_DPS)
		guard.set("attack_range", PULSE_RANGE)
		guard.set("aggro_range", PULSE_RANGE)
		guard.set_meta("combat_authority", "host")
		guard.set_meta("pad_guard_bt", true)
		guard.set_meta("site_pin", "")
		_build_patrol(guard)
	_state = ST_PATROL
	_pt_i = 0
	print("[PadGuardBT] bind patrol/engage/return Pulse=", PULSE_DPS, " G5=closed")


func bt_state() -> String:
	return _state


func pulse_dps() -> float:
	return PULSE_DPS


func combat_authority() -> String:
	return "host"


func is_host_authority() -> bool:
	return true


func home_position() -> Vector3:
	return _home


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


func tick(delta: float = 0.1, target: Node = null) -> String:
	_pulse_cd = maxf(0.0, _pulse_cd - delta)
	var walker: Node3D = target as Node3D if target != null else _find_walker()
	if walker != null and not _is_walker(walker):
		walker = _find_walker()
	var dist := 999.0
	var from_home := _planar_dist(_guard_pos(), _home)
	var near_home := from_home <= HOME_ARRIVE
	var leashed := from_home > LEASH
	if walker != null:
		dist = _planar_dist(_guard_pos(), walker.global_position)
	var in_pulse := walker != null and dist <= PULSE_RANGE and not _walker_downed(walker)
	var hold_engage := _state == ST_ENGAGE and walker != null \
			and dist <= LEAVE_RANGE and not _walker_downed(walker)
	if leashed:
		_state = ST_RETURN
	elif in_pulse or hold_engage:
		_state = ST_ENGAGE
	elif near_home:
		_state = ST_PATROL
	else:
		_state = ST_RETURN
	return _state


func physics_tick(delta: float) -> void:
	if _guard == null or not is_instance_valid(_guard):
		return
	if not bool(_guard.get("_alive")):
		return
	tick(delta)
	match _state:
		ST_ENGAGE:
			_drive_engage(delta)
		ST_RETURN:
			_drive_toward(_home, delta)
		_:
			_drive_patrol(delta)
	_guard.move_and_slide()
	_stick_to_pad()


func try_engage_pulse(target: Node = null) -> bool:
	var walker: Node = target
	if walker == null:
		walker = _find_walker()
	if walker != null and is_instance_valid(walker) \
			and _planar_dist(_guard_pos(), walker.global_position) <= PULSE_RANGE \
			and not _walker_downed(walker):
		_state = ST_ENGAGE
	else:
		tick(0.0)
	if _state != ST_ENGAGE:
		return false
	if walker == null or not is_instance_valid(walker):
		return false
	if _guard == null or not is_instance_valid(_guard):
		return false
	if _pulse_cd > 0.0:
		return false
	var fired := false
	if _guard.has_method("try_pulse_walker"):
		fired = bool(_guard.try_pulse_walker(walker))
	elif _guard.has_method("try_pulse"):
		fired = bool(_guard.try_pulse(walker))
	if fired:
		_pulse_cd = 1.4
	return fired


func _drive_engage(_delta: float) -> void:
	if _planar_dist(_guard_pos(), _home) >= LEASH:
		_drive_toward(_home, _delta)
		return
	var walker := _find_walker()
	if walker == null:
		_halt_xz()
		return
	var to := _planar_to(walker.global_position)
	var dist := to.length()
	if dist > 0.0001:
		_look(to.normalized())
	var next: Vector3 = _guard_pos() + to.normalized() * minf(dist, 1.0)
	if dist > 3.4 and _planar_dist(next, _home) <= LEASH:
		var dir := to.normalized()
		var spd: float = float(_guard.move_speed)
		_guard.velocity.x = dir.x * spd
		_guard.velocity.z = dir.z * spd
	else:
		_halt_xz()
	if dist <= PULSE_RANGE and _pulse_cd <= 0.0:
		try_engage_pulse(walker)


func _drive_patrol(delta: float) -> void:
	if _pts.is_empty():
		_halt_xz()
		return
	if _pt_i >= _pts.size():
		_pt_i = 0
	var dest: Vector3 = _pts[_pt_i]
	if _planar_dist(_guard_pos(), dest) <= ARRIVE:
		_pt_i = (_pt_i + 1) % _pts.size()
		dest = _pts[_pt_i]
	_drive_toward(dest, delta)


func _drive_toward(dest: Vector3, _delta: float) -> void:
	var to := _planar_to(dest)
	if to.length() <= ARRIVE:
		_halt_xz()
		return
	var dir := to.normalized()
	var spd: float = float(_guard.move_speed)
	_guard.velocity.x = dir.x * spd
	_guard.velocity.z = dir.z * spd
	_look(dir)


func _stick_to_pad() -> void:
	## Stay on the plate (parent-local). Gravity must not drop the dummy into dirt.
	if _guard == null or not is_instance_valid(_guard):
		return
	var local: Vector3 = _guard.position
	var planar: Vector3 = Vector3(local.x - _home_local.x, 0.0, local.z - _home_local.z)
	if planar.length() > LEASH:
		planar = planar.normalized() * LEASH
	_guard.position = Vector3(_home_local.x + planar.x, _home_local.y, _home_local.z + planar.z)
	_guard.velocity.y = 0.0


func _halt_xz() -> void:
	_guard.velocity.x = 0.0
	_guard.velocity.z = 0.0


func _look(dir: Vector3) -> void:
	if dir.length_squared() < 0.0001:
		return
	var up := _pad_up
	if absf(dir.normalized().dot(up)) > 0.98:
		up = Vector3.UP
	_guard.look_at(_guard.global_position + dir, up)


func _build_patrol(guard: CharacterBody3D) -> void:
	var basis: Basis = guard.global_transform.basis
	var right: Vector3 = _planar_vec(basis.x)
	var fwd: Vector3 = _planar_vec(basis.z)
	if right.length_squared() < 0.01:
		right = _planar_vec(Vector3.RIGHT)
	if fwd.length_squared() < 0.01:
		fwd = _planar_vec(Vector3.FORWARD)
	right = right.normalized()
	fwd = fwd.normalized()
	_pts = [
		_home,
		_home + right * PATROL_RADIUS,
		_home + fwd * PATROL_RADIUS,
		_home - right * (PATROL_RADIUS * 0.6)
	]


func _find_walker() -> Node3D:
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("player"):
			if _is_walker(n):
				return n as Node3D
	if SoftScanCache and SoftScanCache.has_method("get_player"):
		var sp = SoftScanCache.get_player()
		if _is_walker(sp):
			return sp as Node3D
	return null


func _is_walker(n: Node) -> bool:
	if n == null or not is_instance_valid(n) or not n.is_inside_tree():
		return false
	if n == _guard:
		return false
	## Hulls also have try_pulse — BT-A is the SurfaceWalker only.
	if n.has_method("set_pilot_active") or n.has_method("set_npc_driven"):
		return false
	if n is CharacterBody3D and n.has_method("try_pulse") and n.has_method("set_eva_profile"):
		return true
	return false


func _walker_downed(w: Node) -> bool:
	if w == null or not is_instance_valid(w):
		return true
	if w.has_method("is_downed"):
		return bool(w.is_downed())
	if "_down_t" in w:
		return float(w._down_t) > 0.0
	if "health" in w and float(w.health) <= 0.0:
		return true
	return false


func _guard_pos() -> Vector3:
	if _guard == null:
		return _home
	return _guard.global_position


func _planar_to(dest: Vector3) -> Vector3:
	var to: Vector3 = dest - _guard_pos()
	to = to - _pad_up * to.dot(_pad_up)
	return to


func _planar_dist(a: Vector3, b: Vector3) -> float:
	var d: Vector3 = b - a
	d = d - _pad_up * d.dot(_pad_up)
	return d.length()


func _planar_vec(v: Vector3) -> Vector3:
	return v - _pad_up * v.dot(_pad_up)
