extends Node3D
class_name ClashLocalMatch
## AR-F: 3v3 local authority on the existing Clash 60×60 footprint.
## AR-G: 5v5 on the same lanes + AR-D jungle pockets. 3v3 stays startable.
## Host process owns combat. SoftNet visual puppets for bot slots.
## G5 Clash-from-world stays CLOSED. No SITE_* mint. No P2W.

signal match_started(mode: String, actors: int)

const MODE_3V3 := "3v3"
const MODE_5V5 := "5v5"
const TEAM_SIZE := 3
const TEAM_SIZE_5V5 := 5
const LANES := ["TOP", "MID", "BOT"]
const LANE_JUNGLE := "JUNGLE"
const HOST_LANE := "MID"
const HOST_FACTION := "Cybernex"
const FOOTPRINT_HALF := 28.0
const JUNGLE_X := [7.2, -7.2]

var mode: String = MODE_3V3
var host_authority: bool = true
var _arena: Node = null
var _lanes: Node = null
var _dummy_scene: PackedScene = null
var _host: Node3D = null
var _actors: Array = []
var _started: bool = false
var _isolated: bool = false
var _match_over: bool = false
var _cores: Array = []
var last_result: String = ""
var last_player_won: bool = false
var last_ws_granted: float = 0.0
var last_cosmetic: bool = false


func _ready() -> void:
	name = "ClashLocalMatch"
	add_to_group("clash_local_match")


func bind(arena: Node, lanes: Node, dummy_scene: PackedScene, host_player: Node3D = null) -> void:
	_arena = arena
	_lanes = lanes
	_dummy_scene = dummy_scene
	_host = host_player if host_player != null and is_instance_valid(host_player) else null
	_isolated = false
	_started = true
	mode = MODE_3V3
	_fill_3v3()
	_wire_lane_cores()
	match_started.emit(mode, actor_count())
	print("[ClashLocalMatch] 3v3 local authority actors=", actor_count(), " G5=closed")


func bind_5v5(arena: Node, lanes: Node, dummy_scene: PackedScene, host_player: Node3D = null) -> void:
	_arena = arena
	_lanes = lanes
	_dummy_scene = dummy_scene
	_host = host_player if host_player != null and is_instance_valid(host_player) else null
	_isolated = false
	_started = true
	mode = MODE_5V5
	_fill_5v5()
	_wire_lane_cores()
	match_started.emit(mode, actor_count())
	print("[ClashLocalMatch] 5v5 local authority actors=", actor_count(), " G5=closed")


func start_isolated(parent: Node, dummy_scene: PackedScene) -> void:
	## Headless OpenSpace probe: 6 local bots, no TestArena scene change, no G5.
	_dummy_scene = dummy_scene
	_arena = parent
	_lanes = null
	_host = null
	_isolated = true
	_started = true
	mode = MODE_3V3
	if parent != null and get_parent() != parent:
		parent.add_child(self)
	position = Vector3(0.0, 80000.0, 0.0)
	_fill_3v3()
	_spawn_isolated_cores()
	match_started.emit(mode, actor_count())
	print("[ClashLocalMatch] isolated 3v3 local authority actors=", actor_count(), " G5=closed")


func start_isolated_5v5(parent: Node, dummy_scene: PackedScene) -> void:
	## Headless OpenSpace probe: 10 local bots on the same footprint, no G5.
	_dummy_scene = dummy_scene
	_arena = parent
	_lanes = null
	_host = null
	_isolated = true
	_started = true
	mode = MODE_5V5
	if parent != null and get_parent() != parent:
		parent.add_child(self)
	position = Vector3(0.0, 80000.0, 0.0)
	_fill_5v5()
	_spawn_isolated_cores()
	match_started.emit(mode, actor_count())
	print("[ClashLocalMatch] isolated 5v5 local authority actors=", actor_count(), " G5=closed")


func start_3v3() -> void:
	mode = MODE_3V3
	_started = true
	_fill_3v3()
	match_started.emit(mode, actor_count())
	print("[ClashLocalMatch] 3v3 local authority actors=", actor_count(), " G5=closed")


func start_5v5() -> void:
	mode = MODE_5V5
	_started = true
	_fill_5v5()
	match_started.emit(mode, actor_count())
	print("[ClashLocalMatch] 5v5 local authority actors=", actor_count(), " G5=closed")


func living_actors() -> Array:
	var out: Array = []
	for n in _actors:
		if n == null or not is_instance_valid(n):
			continue
		if n.get("_alive") == false:
			continue
		if n.has_method("is_alive") and not bool(n.is_alive()):
			continue
		out.append(n)
	return out


func actor_count() -> int:
	return living_actors().size()


func lane_ids() -> PackedStringArray:
	var seen: PackedStringArray = PackedStringArray()
	for n in living_actors():
		var lane := lane_of(n)
		if lane != "" and not seen.has(lane):
			seen.append(lane)
	return seen


func lane_of(n: Node) -> String:
	if n != null and n.has_meta("lane") and str(n.get_meta("lane")) != "":
		return str(n.get_meta("lane"))
	if n is Node3D and _lanes != null and _lanes.has_method("lane_at"):
		return str(_lanes.lane_at((n as Node3D).global_position))
	if n is Node3D:
		var x: float = (n as Node3D).position.x if _isolated else (n as Node3D).global_position.x
		if x > 7.0:
			return "TOP"
		if x < -7.0:
			return "BOT"
		return "MID"
	return ""


func is_local_authority() -> bool:
	return host_authority and combat_authority() == "host"


func combat_authority() -> String:
	return "host"


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
	return true


func is_5v5() -> bool:
	return mode == MODE_5V5


func is_3v3() -> bool:
	return mode == MODE_3V3


func footprint_half() -> float:
	return FOOTPRINT_HALF


func visual_puppet_count() -> int:
	var n := 0
	for a in living_actors():
		if bool(a.get_meta("softnet_visual", false)):
			n += 1
	return n


func evidence() -> Dictionary:
	return {
		"mode": mode,
		"actors": actor_count(),
		"lanes": ",".join(lane_ids()),
		"authority": combat_authority(),
		"g5": "closed" if is_g5_closed() else "open",
		"puppets": visual_puppet_count(),
		"isolated": _isolated,
		"ended": _match_over,
		"result": last_result,
		"ws": last_ws_granted,
		"cosmetic": last_cosmetic,
	}


func is_match_over() -> bool:
	return _match_over


func find_core(fac: String) -> Node:
	for c in _cores:
		if c == null or not is_instance_valid(c):
			continue
		if str(c.get_meta("clash_faction", c.get("faction"))) == fac:
			return c
	if _lanes != null and _lanes.has_method("find_structure"):
		var root: Node3D = _lanes.find_structure("CORE", fac) as Node3D
		if root != null:
			var gun: Node = root.get_node_or_null("Gun")
			if gun != null:
				return gun
	return null


func destroy_core(fac: String) -> void:
	var core: Node = find_core(fac)
	if core == null:
		return
	if core.has_method("take_damage"):
		core.take_damage(9999.0, "AR-I")
	elif core.has_method("_die"):
		core.call("_die")


func on_core_destroyed(fac: String) -> void:
	if _match_over:
		return
	var clash := _find_clash()
	if clash != null and clash.has_method("register_structure_down"):
		if clash.has_method("is_match_over") and bool(clash.is_match_over()):
			_sync_from_clash(clash)
			return
		clash.register_structure_down("CORE", "MID", fac)
		_sync_from_clash(clash)
		if clash.has_method("is_match_over") and bool(clash.is_match_over()):
			return
	_resolve_local(fac)


func shutdown() -> void:
	_clear_bots()
	_clear_cores()
	_actors.clear()
	_started = false
	_match_over = false


func _fill_3v3() -> void:
	_clear_bots()
	_actors.clear()
	for lane in LANES:
		for fac in ["Cybernex", "gROT"]:
			if _host != null and fac == HOST_FACTION and lane == HOST_LANE:
				_register_host(_host, lane, fac)
			else:
				_spawn_bot(lane, fac)


func _fill_5v5() -> void:
	_clear_bots()
	_actors.clear()
	for lane in LANES:
		for fac in ["Cybernex", "gROT"]:
			if _host != null and fac == HOST_FACTION and lane == HOST_LANE:
				_register_host(_host, lane, fac)
			else:
				_spawn_bot(lane, fac)
	for fac in ["Cybernex", "gROT"]:
		_spawn_bot(LANE_JUNGLE, fac, 0)
		_spawn_bot(LANE_JUNGLE, fac, 1)


func _register_host(p: Node3D, lane: String, fac: String) -> void:
	p.set_meta("lane", lane)
	p.set_meta("clash_hero", true)
	p.set_meta("clash_slot", "%s_%s" % [fac, lane])
	p.set_meta("combat_authority", "host")
	if not p.is_in_group("clash_hero"):
		p.add_to_group("clash_hero")
	_actors.append(p)


func _spawn_bot(lane: String, fac: String, jungle_slot: int = 0) -> void:
	if _dummy_scene == null:
		return
	var d: Node = _dummy_scene.instantiate()
	d.set("faction", fac)
	d.set("can_move", not _isolated)
	d.set("lane_march", false)
	d.set("one_shot", false)
	d.set("grant_economy", false)
	d.set("max_health", 80.0)
	d.set("move_speed", 3.2)
	d.set("attack_damage", 6.0)
	d.set("attack_range", 10.0)
	d.set("aggro_range", 14.0)
	d.set("attack_cooldown", 1.4)
	d.set("respawn_time", 0.0)
	add_child(d)
	var origin: Vector3 = _slot_origin(lane, fac, jungle_slot)
	if _isolated:
		d.position = origin
		d.set_process(false)
		d.set_physics_process(false)
	else:
		d.global_position = origin
	d.set_meta("lane", lane)
	d.set_meta("clash_hero", true)
	if lane == LANE_JUNGLE:
		d.set_meta("clash_slot", "%s_%s_%d" % [fac, lane, jungle_slot])
		d.set_meta("jungle_slot", jungle_slot)
	else:
		d.set_meta("clash_slot", "%s_%s" % [fac, lane])
	d.set_meta("softnet_visual", true)
	d.set_meta("combat_authority", "host")
	d.add_to_group("clash_hero")
	if d.is_in_group("clash_minion"):
		d.remove_from_group("clash_minion")
	if not _isolated and d.has_method("set_lane_path"):
		var path: Array = []
		if lane == LANE_JUNGLE:
			path = _jungle_march(fac, jungle_slot)
		elif _lanes != null and _lanes.has_method("lane_march_path"):
			path = _lanes.lane_march_path(lane, fac)
		else:
			path = _default_march(lane, fac)
		d.set_lane_path(path)
	if SoftNetSession and SoftNetSession.has_method("bind_visual_puppet"):
		SoftNetSession.bind_visual_puppet(d)
	_actors.append(d)


func _slot_origin(lane: String, fac: String, jungle_slot: int = 0) -> Vector3:
	if lane == LANE_JUNGLE:
		return _jungle_origin(fac, jungle_slot)
	if _lanes != null and _lanes.has_method("lane_spawn_origin"):
		var p: Vector3 = _lanes.lane_spawn_origin(lane, fac)
		p.z += 0.55 if fac == "Cybernex" else -0.55
		return p
	var x := _lane_x(lane)
	if fac == "Cybernex":
		return Vector3(x, 0.1, 12.4)
	return Vector3(x, 0.1, -5.4)


func _jungle_origin(fac: String, slot: int) -> Vector3:
	var x: float = float(JUNGLE_X[clampi(slot, 0, JUNGLE_X.size() - 1)])
	if fac == "Cybernex":
		return Vector3(x, 0.1, 9.0)
	return Vector3(x, 0.1, -3.5)


func _jungle_march(fac: String, slot: int) -> Array:
	var x: float = float(JUNGLE_X[clampi(slot, 0, JUNGLE_X.size() - 1)])
	if fac == "Cybernex":
		return [
			Vector3(x, 0.1, 8.0),
			Vector3(x, 0.1, 2.0),
			Vector3(x, 0.1, -1.2),
		]
	return [
		Vector3(x, 0.1, -2.5),
		Vector3(x, 0.1, 2.0),
		Vector3(x, 0.1, 6.0),
	]


func _default_march(lane: String, fac: String) -> Array:
	var x := _lane_x(lane)
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


func _lane_x(lane: String) -> float:
	if lane == "TOP":
		return 14.0
	if lane == "BOT":
		return -14.0
	return 0.0


func _clear_bots() -> void:
	for n in _actors:
		if n == null or not is_instance_valid(n):
			continue
		if n == _host:
			continue
		if bool(n.get_meta("clash_hero", false)):
			n.queue_free()
	if SoftScanCache and SoftScanCache.has_method("invalidate_enemies"):
		SoftScanCache.invalidate_enemies()


func _wire_lane_cores() -> void:
	_cores.clear()
	if _lanes == null or not _lanes.has_method("find_structure"):
		return
	for fac in ["Cybernex", "gROT"]:
		var root: Node3D = _lanes.find_structure("CORE", fac) as Node3D
		if root == null:
			continue
		var gun: Node = root.get_node_or_null("Gun")
		if gun == null:
			continue
		gun.set_meta("clash_role", "CORE")
		gun.set_meta("clash_faction", fac)
		if gun.has_signal("died") and not gun.died.is_connected(_on_isolated_core_died):
			gun.died.connect(_on_isolated_core_died.bind(fac))
		_cores.append(gun)


func _spawn_isolated_cores() -> void:
	_clear_cores()
	var script := preload("res://scripts/combat/Turret.gd")
	for fac in ["Cybernex", "gROT"]:
		var t := Node3D.new()
		t.set_script(script)
		t.name = "Core_%s" % fac
		t.set("faction", fac)
		t.set("max_health", 360.0)
		t.set("target_player", false)
		t.set("skip_visual", true)
		t.set("display_name", "CORE")
		t.set_meta("clash_role", "CORE")
		t.set_meta("clash_faction", fac)
		add_child(t)
		t.position = Vector3(0.0, 2.0, 18.0 if fac == "Cybernex" else -18.0)
		t.set_process(false)
		t.set_physics_process(false)
		if t.has_signal("died"):
			t.died.connect(_on_isolated_core_died.bind(fac))
		_cores.append(t)


func _on_isolated_core_died(fac: String) -> void:
	on_core_destroyed(fac)


func _find_clash() -> Node:
	if _arena != null:
		var n: Node = _arena.get_node_or_null("AexionClash")
		if n != null:
			return n
	var tree := get_tree()
	if tree:
		return tree.get_first_node_in_group("aexion_clash")
	return null


func _sync_from_clash(clash: Node) -> void:
	_match_over = true
	if "last_result" in clash:
		last_result = str(clash.last_result)
	if "last_player_won" in clash:
		last_player_won = bool(clash.last_player_won)
	if "last_ws_granted" in clash:
		last_ws_granted = float(clash.last_ws_granted)
	if "last_cosmetic" in clash:
		last_cosmetic = bool(clash.last_cosmetic)


func _resolve_local(fac: String) -> void:
	if _match_over and last_result != "":
		return
	_match_over = true
	var player_fac := "Cybernex"
	if GameManager and GameManager.has_method("get_faction_name"):
		player_fac = str(GameManager.get_faction_name())
	last_player_won = fac != player_fac
	last_result = "WIN" if last_player_won else "LOSS"
	var wanted := 15.0 if last_player_won else 3.0
	var granted := 0.0
	if SoftSession and SoftSession.has_method("grant_war_score"):
		granted = float(SoftSession.grant_war_score(wanted))
	last_ws_granted = granted
	last_cosmetic = last_player_won and granted <= 0.0
	if SoftSession and SoftSession.has_method("remember_clash_result"):
		SoftSession.remember_clash_result(last_player_won, granted)
	print("[ClashLocalMatch] CORE down fac=", fac, " result=", last_result,
		" ws=", granted, " cosmetic=", last_cosmetic)


func _clear_cores() -> void:
	for c in _cores:
		if c == null or not is_instance_valid(c):
			continue
		if c.get_parent() == self:
			c.queue_free()
	_cores.clear()
