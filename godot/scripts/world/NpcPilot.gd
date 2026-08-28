extends Node
## NP-A: one local visitor flies the existing SCM / HOVER / LAND loop.
## NP-B: after LAND, same PadBaseController occupy / harvest as the player.
## NP-D: player may invite this pilot into a local squad — follow or seat.
## NP-E: this hull + pad-guard share AllianceRanks and a visible raid/logistics intent.
## NP-F: after the player leaves, one short pad occupy/harvest or follow cycle.
## NP-C: after ST-A, place one habitat on an empty unnamed pad (same BaseBuilder).
## Not a second IFCS, not G1, not a private yield table, not a damage aura.


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
var _squad: Node = null
var _squad_follow: bool = false
var _squad_seated: bool = false
var _companion: Node3D = null
var _offline_ran: bool = false
var _placed_mod: Node3D = null
var _offline_step: String = ""
var _offline_busy: bool = false


func setup(ship: CharacterBody3D, pad: Node3D) -> void:
	_ship = ship
	_pad = pad
	_auto = not _cmdline_playtest()
	_seat_on_pad()
	_ensure_infection()
	_bind_offline()
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


func seen_contract_id() -> String:
	## Q-B: same alliance-shared ContractBoard id as the pad-guard. Not DPS.
	if has_meta("alliance_contract_id"):
		return str(get_meta("alliance_contract_id"))
	var hull := get_parent()
	if hull != null and hull.has_meta("alliance_contract_id"):
		return str(hull.get_meta("alliance_contract_id"))
	return ""


func is_harvesting() -> bool:
	return _harvesting


func saw_harvest() -> bool:
	return _saw_harvest


func harvest_amount() -> float:
	return _harvest_got


func placed_module() -> Node3D:
	if _placed_mod != null and is_instance_valid(_placed_mod):
		return _placed_mod
	return null


func saw_place_module() -> bool:
	return placed_module() != null


func place_one_module() -> Node3D:
	## NP-C: one habitat, empty unnamed pad, same BaseBuilder as ST-A.
	## This hull places at most one. No SITE_*. No cash skip.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var pad: Node3D = null
	var fac: String = ""
	var mod: Node3D = null
	if P0 == null or not bool(P0.NP_C_MODULE):
		return null
	if placed_module() != null:
		return null
	pad = _empty_unnamed_pad()
	if pad == null:
		print("[NpcPilot] NP-C no empty unnamed pad")
		return null
	fac = _hull_faction()
	mod = BaseBuilder.place_npc_habitat(pad, fac)
	if mod == null:
		return null
	if str(mod.get_meta("site_pin", "x")) != "":
		push_error("[NpcPilot] NP-C minted a site_pin")
		mod.queue_free()
		return null
	_placed_mod = mod
	print("[NpcPilot] NP-C habitat on ", pad.name, " fac=", fac)
	return mod


func _empty_unnamed_pad() -> Node3D:
	var legal: Array = ["Pad_North", "Pad_Approach", "Pad_Flank"]
	var cands: Array = []
	if _pad != null and is_instance_valid(_pad) and str(_pad.name) in legal:
		cands.append(_pad)
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("landing_pads"):
			if n is Node3D and str(n.name) in legal and n not in cands:
				cands.append(n)
	for n in cands:
		var pad: Node3D = n as Node3D
		if pad == null:
			continue
		if BaseBuilder.pad_has_module(pad):
			continue
		return pad
	return null


func _hull_faction() -> String:
	if _ship != null and is_instance_valid(_ship):
		if _ship.has_method("get_faction"):
			return str(_ship.get_faction())
		if "faction" in _ship:
			return str(_ship.get("faction"))
	if GameManager and GameManager.has_method("get_faction_name"):
		return str(GameManager.get_faction_name())
	return "Cybernex"


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


func accept_squad_invite(squad: Node) -> void:
	## SoftNet stays visual. Invite does not grant combat authority.
	_squad = squad
	stop_harvest()
	_auto = false
	_phase = Phase.IDLE
	_phase_t = 0.0
	_squad_seated = false
	_squad_follow = true
	_ensure_companion()
	print("[NpcPilot] squad invite follow")


func is_squad_following() -> bool:
	return _squad_follow and not _squad_seated


func is_squad_seated() -> bool:
	return _squad_seated


func squad_body() -> Node3D:
	return _companion if _companion != null and is_instance_valid(_companion) else null


func offline_cycle_ran() -> bool:
	return _offline_ran


func offline_step() -> String:
	return _offline_step


func infection_stacks() -> int:
	var inf := get_node_or_null("InfectionStatus")
	return int(inf.stacks) if inf else 0


func infection_cap() -> int:
	return 5


func run_offline_cycle() -> String:
	## Player gone. One short legal step: pad occupy/harvest or follow.
	## Last player actions pick the step. They do not change combat stats.
	if _offline_busy:
		return _offline_step
	_offline_busy = true
	var step := "pad"
	if SoftSession and SoftSession.has_method("next_legal_step"):
		step = str(SoftSession.next_legal_step())
	if step != "follow":
		step = "pad"
	_offline_step = step
	_phase = Phase.IDLE
	_phase_t = 0.0
	_auto = false
	if step == "follow":
		_run_offline_follow()
	else:
		_run_offline_pad()
	_offline_ran = true
	_offline_busy = false
	print("[NpcPilot] NP-F offline cycle=", step)
	return step


func try_squad_seat(director: Node) -> bool:
	if director == null or not director.has_method("seat_companion"):
		return false
	var body := _ensure_companion()
	if body == null:
		return false
	if not bool(director.seat_companion(body)):
		return false
	_squad_follow = false
	_squad_seated = true
	print("[NpcPilot] squad seated")
	return true


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
		if _squad_follow and not _squad_seated:
			_tick_squad_follow(delta)
		elif _auto:
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


func _ensure_companion() -> Node3D:
	if _companion != null and is_instance_valid(_companion):
		return _companion
	var body := Node3D.new()
	body.name = "SquadCompanion"
	body.set_meta("squad_npc", true)
	body.set_meta("squad_id", "npc_visitor")
	body.set_meta("site_pin", "")
	var host: Node = _open_space()
	if host == null:
		host = _ship
	if host == null:
		return null
	host.add_child(body)
	var origin: Vector3 = _ship.global_position if _ship != null else Vector3.ZERO
	body.global_position = origin + Vector3(2.2, 1.0, 1.4)
	_companion = body
	if DisplayServer.get_name() != "headless":
		_build_companion_visual(body)
	return _companion


func _follow_anchor() -> Node3D:
	var os := _open_space()
	if os == null:
		return null
	var walker: Node3D = os.get("player") as Node3D
	if walker != null and is_instance_valid(walker):
		return walker
	var pship: Node3D = os.get("ship") as Node3D
	if pship != null and is_instance_valid(pship) and pship != _ship:
		return pship
	return pship


func _tick_squad_follow(delta: float) -> void:
	var body := _ensure_companion()
	var tgt := _follow_anchor()
	if body == null or tgt == null:
		return
	var dest: Vector3 = tgt.global_position + tgt.global_transform.basis.x * 2.4 + Vector3(0.0, 0.9, 0.0)
	body.global_position = body.global_position.lerp(dest, clampf(delta * 7.0, 0.0, 1.0))


func _build_companion_visual(host: Node3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	var cap := CapsuleMesh.new()
	cap.radius = 0.32
	cap.height = 1.05
	mi.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.55, 0.85, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.7, 1.0)
	mat.emission_energy_multiplier = 1.2
	mi.material_override = mat
	mi.position = Vector3(0, 0.7, 0)
	host.add_child(mi)
	var lab := Label3D.new()
	lab.name = "Label"
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 20
	lab.outline_size = 4
	lab.position = Vector3(0, 1.9, 0)
	lab.text = "SQUAD"
	lab.modulate = Color(0.75, 0.9, 1.0)
	host.add_child(lab)


func _bind_offline() -> void:
	if SoftSession == null or not SoftSession.has_signal("offline_changed"):
		return
	if SoftSession.offline_changed.is_connected(_on_offline_changed):
		return
	SoftSession.offline_changed.connect(_on_offline_changed)


func _on_offline_changed(offline: bool) -> void:
	if not offline:
		return
	if _cmdline_playtest():
		return
	run_offline_cycle()


func _ensure_infection() -> void:
	## Same InfectionStatus as the player. Cap 5. Influence never writes stacks.
	if get_node_or_null("InfectionStatus") != null:
		return
	var n := Node.new()
	n.set_script(preload("res://scripts/abilities/InfectionStatus.gd"))
	n.name = "InfectionStatus"
	add_child(n)


func _run_offline_pad() -> void:
	_squad_follow = false
	_squad_seated = false
	if _ship != null and is_instance_valid(_ship) and not bool(_ship.get("is_landed")):
		_seat_on_pad()
	start_harvest()


func _run_offline_follow() -> void:
	stop_harvest()
	_squad_seated = false
	_squad_follow = true
	_ensure_companion()


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
