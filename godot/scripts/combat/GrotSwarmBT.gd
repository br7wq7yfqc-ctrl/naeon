extends Node
class_name GrotSwarmBT
## BT-C: tiny 3-state gROT swarm BT. No plugin. Not Clash waves. Not 10k CCU.
## gather on the pad → pulse-engage SurfaceWalker in Pulse range → scatter-return-to-pad.
## Three CombatDummy actors. Host authority. Pulse DPS stays 11. Infection cap 5.
## No permadeath. Knowledge labels only. BT-A pad-guard and BT-B visitor stay distinct.
## PV-A rival stays distinct. Not TestArena. Not AR leftover 5v5.

const PULSE_DPS := 11.0
const PULSE_RANGE := 16.0
const LEAVE_RANGE := 22.0
const GATHER_RADIUS := 3.6
const ARRIVE := 1.2
const HOME_ARRIVE := 2.8
const LEASH := 14.0
const SIZE := 3

const ST_GATHER := "gather"
const ST_ENGAGE := "pulse-engage"
const ST_SCATTER := "scatter-return-to-pad"

var _members: Array[CharacterBody3D] = []
var _homes: Array[Vector3] = []
var _homes_local: Array[Vector3] = []
var _pad_up: Vector3 = Vector3.UP
var _anchor: Vector3 = Vector3.ZERO
var _state: String = ST_GATHER
var _pulse_cd: float = 0.0
var _gather_i: int = 0
var _gather_pts: Array[Vector3] = []


func _ready() -> void:
	name = "GrotSwarmBT"
	set_meta("site_pin", "")
	set_meta("combat_authority", "host")
	set_meta("grot_swarm_bt", true)
	if not is_in_group("grot_swarm_bt"):
		add_to_group("grot_swarm_bt")
	set_physics_process(false)


func bind(members: Array, pad: Node3D = null) -> void:
	_members.clear()
	_homes.clear()
	_homes_local.clear()
	if pad != null and pad.has_meta("pad_up"):
		var up: Variant = pad.get_meta("pad_up")
		if up is Vector3 and (up as Vector3).length_squared() > 0.01:
			_pad_up = (up as Vector3).normalized()
	for item in members:
		if item == null or not is_instance_valid(item) or not (item is CharacterBody3D):
			continue
		var d: CharacterBody3D = item as CharacterBody3D
		_members.append(d)
		_homes.append(d.global_position)
		_homes_local.append(d.position)
		d.set("bt_driven", true)
		d.set("can_move", true)
		d.set("lane_march", false)
		d.set("one_shot", false)
		d.set("grant_economy", false)
		d.set("faction", "gROT")
		d.set("attack_damage", PULSE_DPS)
		d.set("attack_range", PULSE_RANGE)
		d.set("aggro_range", PULSE_RANGE)
		d.set_meta("combat_authority", "host")
		d.set_meta("grot_swarm", true)
		d.set_meta("site_pin", "")
		if d.is_in_group("clash_minion"):
			d.remove_from_group("clash_minion")
		if _members.size() >= SIZE:
			break
	_anchor = _centroid(_homes) if not _homes.is_empty() else Vector3.ZERO
	_build_gather()
	_state = ST_GATHER
	_gather_i = 0
	_pulse_cd = 0.0
	set_physics_process(true)
	print("[GrotSwarmBT] bind gather/pulse-engage/scatter-return n=", _members.size(),
		" Pulse=", PULSE_DPS, " cap=5 G5=closed")


func bt_state() -> String:
	return _state


func pulse_dps() -> float:
	return PULSE_DPS


func swarm_size() -> int:
	return _members.size()


func combat_authority() -> String:
	return "host"


func is_host_authority() -> bool:
	return true


func infection_cap() -> int:
	return 5


func members() -> Array[CharacterBody3D]:
	var out: Array[CharacterBody3D] = []
	for d in _members:
		if d != null and is_instance_valid(d):
			out.append(d)
	return out


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
	_prune()
	var walker: Node3D = target as Node3D if target != null else _find_walker()
	if walker != null and not _is_walker(walker):
		walker = _find_walker()
	var from_home := _planar_dist(_live_centroid(), _anchor)
	var near_home := from_home <= HOME_ARRIVE
	var leashed := from_home > LEASH
	var dist := 999.0
	if walker != null:
		dist = _planar_dist(_live_centroid(), walker.global_position)
	var in_pulse := walker != null and dist <= PULSE_RANGE and not _walker_downed(walker)
	var hold_engage := _state == ST_ENGAGE and walker != null \
			and dist <= LEAVE_RANGE and not _walker_downed(walker)
	if leashed:
		_state = ST_SCATTER
	elif in_pulse or hold_engage:
		_state = ST_ENGAGE
	elif near_home:
		_state = ST_GATHER
	else:
		_state = ST_SCATTER
	return _state


func _physics_process(delta: float) -> void:
	physics_tick(delta)


func physics_tick(delta: float) -> void:
	_prune()
	if _members.is_empty():
		return
	tick(delta)
	match _state:
		ST_ENGAGE:
			_drive_engage(delta)
		ST_SCATTER:
			_drive_scatter(delta)
		_:
			_drive_gather(delta)
	for d in _members:
		if d == null or not is_instance_valid(d):
			continue
		if not bool(d.get("_alive")):
			continue
		d.move_and_slide()
		_stick_to_pad(d)


func try_engage_pulse(target: Node = null) -> bool:
	var walker: Node = target
	if walker == null:
		walker = _find_walker()
	tick(0.0, walker)
	if _state != ST_ENGAGE:
		return false
	if walker == null or not is_instance_valid(walker):
		return false
	if _pulse_cd > 0.0:
		return false
	var shooter := _nearest_member(walker as Node3D)
	if shooter == null:
		return false
	var fired := false
	if shooter.has_method("try_pulse_walker"):
		fired = bool(shooter.try_pulse_walker(walker))
	elif shooter.has_method("try_pulse"):
		fired = bool(shooter.try_pulse(walker))
	if fired:
		_pulse_cd = 1.4
	return fired


func _drive_engage(_delta: float) -> void:
	if _planar_dist(_live_centroid(), _anchor) >= LEASH:
		_drive_scatter(_delta)
		return
	var walker := _find_walker()
	if walker == null:
		_halt_all()
		return
	for d in _members:
		if d == null or not is_instance_valid(d) or not bool(d.get("_alive")):
			continue
		var to := _planar_to(d.global_position, walker.global_position)
		var dist := to.length()
		if dist > 0.0001:
			_look(d, to.normalized())
		var next: Vector3 = d.global_position + to.normalized() * minf(dist, 1.0)
		if dist > 3.4 and _planar_dist(next, _anchor) <= LEASH:
			var dir := to.normalized()
			var spd: float = float(d.move_speed)
			d.velocity.x = dir.x * spd
			d.velocity.z = dir.z * spd
		else:
			d.velocity.x = 0.0
			d.velocity.z = 0.0
	if _pulse_cd <= 0.0:
		try_engage_pulse(walker)


func _drive_gather(_delta: float) -> void:
	if _gather_pts.is_empty() or _members.is_empty():
		_halt_all()
		return
	if _gather_i >= _gather_pts.size():
		_gather_i = 0
	var dest: Vector3 = _gather_pts[_gather_i]
	if _planar_dist(_live_centroid(), dest) <= ARRIVE:
		_gather_i = (_gather_i + 1) % _gather_pts.size()
		dest = _gather_pts[_gather_i]
	for i in range(_members.size()):
		var d: CharacterBody3D = _members[i]
		if d == null or not is_instance_valid(d) or not bool(d.get("_alive")):
			continue
		var offset: Vector3 = _homes[i] - _anchor if i < _homes.size() else Vector3.ZERO
		_drive_member_toward(d, dest + offset, _delta)


func _drive_scatter(_delta: float) -> void:
	for i in range(_members.size()):
		var d: CharacterBody3D = _members[i]
		if d == null or not is_instance_valid(d) or not bool(d.get("_alive")):
			continue
		var home: Vector3 = _homes[i] if i < _homes.size() else _anchor
		_drive_member_toward(d, home, _delta)


func _drive_member_toward(d: CharacterBody3D, dest: Vector3, _delta: float) -> void:
	var to := _planar_to(d.global_position, dest)
	if to.length() <= ARRIVE:
		d.velocity.x = 0.0
		d.velocity.z = 0.0
		return
	var dir := to.normalized()
	var spd: float = float(d.move_speed)
	d.velocity.x = dir.x * spd
	d.velocity.z = dir.z * spd
	_look(d, dir)


func _stick_to_pad(d: CharacterBody3D) -> void:
	## Stay on the plate (parent-local). Gravity must not drop the dummy into dirt.
	var idx := _members.find(d)
	if idx < 0 or idx >= _homes_local.size():
		return
	var home_local: Vector3 = _homes_local[idx]
	var local: Vector3 = d.position
	var planar: Vector3 = Vector3(local.x - home_local.x, 0.0, local.z - home_local.z)
	if planar.length() > LEASH:
		planar = planar.normalized() * LEASH
	d.position = Vector3(home_local.x + planar.x, home_local.y, home_local.z + planar.z)
	d.velocity.y = 0.0


func _halt_all() -> void:
	for d in _members:
		if d == null or not is_instance_valid(d):
			continue
		d.velocity.x = 0.0
		d.velocity.z = 0.0


func _look(d: CharacterBody3D, dir: Vector3) -> void:
	if dir.length_squared() < 0.0001:
		return
	var up := _pad_up
	if absf(dir.normalized().dot(up)) > 0.98:
		up = Vector3.UP
	d.look_at(d.global_position + dir, up)


func _build_gather() -> void:
	var right := _planar_vec(Vector3.RIGHT)
	var fwd := _planar_vec(Vector3.FORWARD)
	if right.length_squared() < 0.01:
		right = Vector3.RIGHT
	if fwd.length_squared() < 0.01:
		fwd = Vector3.FORWARD
	right = right.normalized()
	fwd = fwd.normalized()
	_gather_pts = [
		_anchor,
		_anchor + right * GATHER_RADIUS,
		_anchor + fwd * GATHER_RADIUS,
		_anchor - right * (GATHER_RADIUS * 0.6)
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
	if n.has_meta("grot_swarm"):
		return false
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


func _nearest_member(target: Node3D) -> CharacterBody3D:
	var best: CharacterBody3D = null
	var best_d := 1.0e9
	var origin: Vector3 = target.global_position if target != null else _anchor
	for d in _members:
		if d == null or not is_instance_valid(d) or not bool(d.get("_alive")):
			continue
		var dist := _planar_dist(d.global_position, origin)
		if dist < best_d:
			best = d
			best_d = dist
	return best


func _live_centroid() -> Vector3:
	var pts: Array[Vector3] = []
	for d in _members:
		if d != null and is_instance_valid(d):
			pts.append(d.global_position)
	if pts.is_empty():
		return _anchor
	return _centroid(pts)


func _centroid(pts: Array[Vector3]) -> Vector3:
	if pts.is_empty():
		return Vector3.ZERO
	var acc := Vector3.ZERO
	for p in pts:
		acc += p
	return acc / float(pts.size())


func _prune() -> void:
	var keep: Array[CharacterBody3D] = []
	var homes: Array[Vector3] = []
	var locals: Array[Vector3] = []
	for i in range(_members.size()):
		var d: CharacterBody3D = _members[i]
		if d == null or not is_instance_valid(d):
			continue
		keep.append(d)
		if i < _homes.size():
			homes.append(_homes[i])
		else:
			homes.append(d.global_position)
		if i < _homes_local.size():
			locals.append(_homes_local[i])
		else:
			locals.append(d.position)
	_members = keep
	_homes = homes
	_homes_local = locals


func _planar_to(from: Vector3, dest: Vector3) -> Vector3:
	var to: Vector3 = dest - from
	to = to - _pad_up * to.dot(_pad_up)
	return to


func _planar_dist(a: Vector3, b: Vector3) -> float:
	var d: Vector3 = b - a
	d = d - _pad_up * d.dot(_pad_up)
	return d.length()


func _planar_vec(v: Vector3) -> Vector3:
	return v - _pad_up * v.dot(_pad_up)
