extends Node
## NP-A: one local visitor flies the existing SCM / HOVER / LAND loop.
## NP-B: after LAND, same PadBaseController occupy / harvest as the player.
## NP-D: player may invite this pilot into a local squad — follow or seat.
## NP-E: this hull + pad-guard share AllianceRanks and a visible raid/logistics intent.
## NP-F: after the player leaves, one short pad occupy/harvest or follow cycle.
## NP-C: after ST-A, place one habitat on an empty unnamed pad (same BaseBuilder).
## NP-G: after NP-B harvest, spend at PadPrintBench §6(a) (same ST-C path).
## NP-H: after NP-B harvest, queue one catalog module on the ST-D hangar (same enqueue).
## NP-I: after NP-B harvest, spend at player-cluster factory bench (c) (same ST-G path).
## Q-D: offer the same Q-A ContractBoard id. Player accepts from this visitor.
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
var _printed_mod: Node3D = null
var _queued_hangar: Node3D = null
var _factory_printed: Node3D = null
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


func offered_player_contract_id() -> String:
	## Q-D: same Q-A ContractBoard id the ops console uses. Not a second board.
	if has_meta("player_contract_id"):
		return str(get_meta("player_contract_id"))
	var hull := get_parent()
	if hull != null and hull.has_meta("player_contract_id"):
		return str(hull.get_meta("player_contract_id"))
	return ""


func offer_player_contract() -> Dictionary:
	## Q-D: same offer_one as the IN-B ops console. Not a campaign. Not Q-B.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var Board = load("res://scripts/systems/ContractBoard.gd")
	var host := _contract_host_id()
	var offer: Dictionary = {}
	var cid := ""
	if P0 == null or not bool(P0.Q_D_GIVER) or not bool(P0.Q_A_CONTRACT):
		return {}
	if Board == null or not Board.has_method("offer_one"):
		return {}
	offer = Board.offer_one(host, "Nex-Prime")
	if offer.is_empty():
		return {}
	cid = str(offer.get("id", ""))
	if cid == "" or cid.begins_with("SITE_") or not cid.begins_with("QA-"):
		return {}
	if str(offer.get("body", "")) != "Nex-Prime":
		return {}
	set_meta("player_contract_id", cid)
	set_meta("quest_role", "CX_PILOT_LIAISON")
	if _ship != null and is_instance_valid(_ship):
		_ship.set_meta("player_contract_id", cid)
		_ship.set_meta("quest_role", "CX_PILOT_LIAISON")
	_sign_giver_label()
	print("[NpcPilot] Q-D offered ", cid, " template=", offer.get("template", ""))
	return offer.duplicate(true)


func accept_player_contract(cash: float = 0.0) -> Dictionary:
	## Player accepts the offered Q-A board from this NPC. Same ContractBoard.accept.
	var Board = load("res://scripts/systems/ContractBoard.gd")
	var cur: Dictionary = {}
	if cash > 0.0:
		print("[NpcPilot] Q-D pay-to-complete refused")
		return {}
	if Board == null or not Board.has_method("accept"):
		return {}
	if offered_player_contract_id() == "":
		offer_player_contract()
	cur = Board.accept()
	if not cur.is_empty():
		print("[NpcPilot] Q-D accepted ", cur.get("id", ""))
	return cur.duplicate(true)


func try_complete_player_contract(cash: float = 0.0) -> Dictionary:
	## Same Q-A complete. SoftKnowledge quest_intel only.
	var Board = load("res://scripts/systems/ContractBoard.gd")
	if cash > 0.0:
		print("[NpcPilot] Q-D pay-to-complete refused")
		return {}
	if Board == null or not Board.has_method("try_complete"):
		return {}
	return Board.try_complete()


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


func printed_catalog_module() -> Node3D:
	if _printed_mod != null and is_instance_valid(_printed_mod):
		return _printed_mod
	return null


func saw_print_module() -> bool:
	return printed_catalog_module() != null


func print_one_catalog_module(kind: String = "", cash: float = 0.0) -> Node3D:
	## NP-G: ST-C §6(a) spend at PadPrintBench. Not NP-C habitat. Not factory. Not hangar.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var pad: Node3D = null
	var bench: Node = null
	var mod: Node3D = null
	if P0 == null or not bool(P0.NP_G_PRINT) or not bool(P0.ST_C_PRINT):
		return null
	if cash > 0.0:
		print("[NpcPilot] NP-G cash-shop skip refused")
		return null
	if printed_catalog_module() != null:
		print("[NpcPilot] NP-G already printed one catalog module")
		return null
	pad = _print_target_pad()
	bench = _print_bench_on(pad)
	if bench == null or not bench.has_method("print_one_module"):
		print("[NpcPilot] NP-G no PadPrintBench")
		return null
	if bench.has_method("cash_shop_skip_possible") and bool(bench.cash_shop_skip_possible()):
		return null
	mod = bench.print_one_module(kind, 0.0)
	if mod == null or not is_instance_valid(mod):
		return null
	if str(mod.get_meta("site_pin", "x")) != "":
		push_error("[NpcPilot] NP-G minted a site_pin")
		mod.queue_free()
		return null
	if bool(mod.get_meta("npc_module", false)):
		push_error("[NpcPilot] NP-G used habitat hack")
		mod.queue_free()
		return null
	if bool(mod.get_meta("factory_printed", false)) or bool(mod.get_meta("hangar_queued", false)):
		push_error("[NpcPilot] NP-G used factory/hangar")
		mod.queue_free()
		return null
	if not bool(mod.get_meta("printed_module", false)):
		push_error("[NpcPilot] NP-G module not marked printed_module")
		mod.queue_free()
		return null
	_printed_mod = mod
	_sign_print_label()
	print("[NpcPilot] NP-G printed ", mod.name, " on ", pad.name if pad else "?", " cash_skip=false")
	return mod


func queued_hangar_module() -> Node3D:
	if _queued_hangar != null and is_instance_valid(_queued_hangar):
		return _queued_hangar
	return null


func saw_hangar_queue() -> bool:
	return queued_hangar_module() != null


func hangar_last_refuse() -> String:
	var q := _hangar_queue()
	if q != null and q.has_method("last_refuse"):
		return str(q.last_refuse())
	return ""


func queue_one_hangar_module(kind: String = "", cash: float = 0.0) -> Node3D:
	## NP-H: ST-D §6(b) enqueue on catalog carrier. Not NP-C habitat. Not factory. Not bench (a).
	var P0 = load("res://scripts/world/P0Slice.gd")
	var queue: Node = null
	var mod: Node3D = null
	if P0 == null or not bool(P0.NP_H_HANGAR) or not bool(P0.ST_D_HANGAR):
		return null
	queue = _hangar_queue()
	if queue == null or not queue.has_method("enqueue_module"):
		print("[NpcPilot] NP-H no CarrierHangarQueue")
		return null
	if cash > 0.0:
		print("[NpcPilot] NP-H cash-shop skip refused")
		return queue.enqueue_module(kind, cash)
	if queued_hangar_module() != null:
		print("[NpcPilot] NP-H already queued one hangar module")
		return null
	if queue.has_method("cash_shop_skip_possible") and bool(queue.cash_shop_skip_possible()):
		return null
	mod = queue.enqueue_module(kind, 0.0)
	if mod == null or not is_instance_valid(mod):
		return null
	if str(mod.get_meta("site_pin", "x")) != "":
		push_error("[NpcPilot] NP-H minted a site_pin")
		mod.queue_free()
		return null
	if bool(mod.get_meta("npc_module", false)):
		push_error("[NpcPilot] NP-H used habitat hack")
		mod.queue_free()
		return null
	if bool(mod.get_meta("factory_printed", false)) or bool(mod.get_meta("printed_module", false)):
		push_error("[NpcPilot] NP-H used factory/bench")
		mod.queue_free()
		return null
	if not bool(mod.get_meta("hangar_queued", false)):
		push_error("[NpcPilot] NP-H module not marked hangar_queued")
		mod.queue_free()
		return null
	_queued_hangar = mod
	_sign_hangar_label()
	print("[NpcPilot] NP-H queued ", mod.name, " hull hangar cash_skip=false")
	return mod


func printed_factory_module() -> Node3D:
	if _factory_printed != null and is_instance_valid(_factory_printed):
		return _factory_printed
	return null


func saw_factory_print() -> bool:
	return printed_factory_module() != null


func print_one_factory_module(kind: String = "", cash: float = 0.0) -> Node3D:
	## NP-I: ST-G §6(c) spend at player-cluster factory. Not NP-C habitat. Not bench (a). Not hangar (b).
	var P0 = load("res://scripts/world/P0Slice.gd")
	var bench: Node = null
	var factory: Node3D = null
	var mod: Node3D = null
	if P0 == null or not bool(P0.NP_I_FACTORY) or not bool(P0.ST_G_FACTORY):
		return null
	if cash > 0.0:
		print("[NpcPilot] NP-I cash-shop skip refused")
		return null
	if printed_factory_module() != null:
		print("[NpcPilot] NP-I already printed one factory module")
		return null
	factory = _factory_in_cluster()
	if factory == null:
		print("[NpcPilot] NP-I refuse: no factory")
		return null
	bench = _factory_bench()
	if bench == null or not bench.has_method("print_one_factory_module"):
		print("[NpcPilot] NP-I no factory bench (c)")
		return null
	if bench.has_method("cash_shop_skip_possible") and bool(bench.cash_shop_skip_possible()):
		return null
	mod = bench.print_one_factory_module(kind, 0.0)
	if mod == null or not is_instance_valid(mod):
		return null
	if str(mod.get_meta("site_pin", "x")) != "":
		push_error("[NpcPilot] NP-I minted a site_pin")
		mod.queue_free()
		return null
	if bool(mod.get_meta("npc_module", false)):
		push_error("[NpcPilot] NP-I used habitat hack")
		mod.queue_free()
		return null
	if bool(mod.get_meta("printed_module", false)) or bool(mod.get_meta("hangar_queued", false)):
		push_error("[NpcPilot] NP-I used bench/hangar")
		mod.queue_free()
		return null
	if not bool(mod.get_meta("factory_printed", false)):
		push_error("[NpcPilot] NP-I module not marked factory_printed")
		mod.queue_free()
		return null
	_factory_printed = mod
	_sign_factory_label()
	print("[NpcPilot] NP-I printed ", mod.name, " factory=", factory.name, " cash_skip=false")
	return mod


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


func hull() -> Node3D:
	## Visiting hull in OpenSpace. Ability range is measured here, not on this Node.
	if _ship != null and is_instance_valid(_ship):
		return _ship
	var p := get_parent()
	return p as Node3D if p is Node3D else null


## HF-B: +1 Infection on the visitor. Cap 5 named refuse. Knowledge never writes this.
func apply_infection(_n: int = 1) -> String:
	_ensure_infection()
	var inf := get_node_or_null("InfectionStatus")
	if inf == null:
		return "No InfectionStatus"
	if inf.has_method("try_add_one"):
		return str(inf.try_add_one())
	if infection_stacks() >= infection_cap():
		return "Infection cap 5"
	if inf.has_method("add_stacks"):
		inf.add_stacks(1)
	return ""


## HF-B: Firewall −1. Never below 0. No cash-shop cleanse.
func purge_infection(_n: int = 1) -> int:
	var inf := get_node_or_null("InfectionStatus")
	if inf != null:
		if inf.has_method("remove_one"):
			inf.remove_one()
		elif inf.has_method("remove_stacks"):
			inf.remove_stacks(1)
	return infection_stacks()


func try_cash_cleanse(_paid: float = 0.0) -> bool:
	var inf := get_node_or_null("InfectionStatus")
	if inf != null and inf.has_method("try_cash_cleanse"):
		return bool(inf.try_cash_cleanse(_paid))
	return false


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
	if _auto:
		_try_auto_print()
		_try_auto_queue()
		_try_auto_factory()


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


func _print_target_pad() -> Node3D:
	## Prefer the harvest pad. If that bench already granted (player ST-C), next unnamed.
	## ONE_PAD streams one controller; other unnamed plates still take a §6(a) bench.
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
		if BaseBuilder.printed_module_on(pad) != null:
			continue
		var bench := _ensure_print_bench_on(pad)
		if bench == null:
			continue
		if bench.has_method("granted_module") and bench.granted_module() != null:
			continue
		return pad
	return null


func _ensure_print_bench_on(pad: Node3D) -> Node:
	## Same PadPrintBench as ST-C. Does not add a PadBaseController or habitat.
	var bench := _print_bench_on(pad)
	var n: Node3D = null
	if bench != null:
		return bench
	if pad == null or not is_instance_valid(pad):
		return null
	n = Node3D.new()
	n.set_script(preload("res://scripts/world/PadPrintBench.gd"))
	n.name = "PadPrintBench"
	n.set_meta("site_pin", "")
	pad.add_child(n)
	n.position = Vector3(0.0, 0.35, 12.0)
	return n


func _print_bench_on(pad: Node3D) -> Node:
	var ctrl: Node = null
	if pad == null or not is_instance_valid(pad):
		return null
	var named: Node = pad.get_node_or_null("PadPrintBench")
	if named != null:
		return named
	ctrl = pad.get_node_or_null("BaseCluster/PadBaseController")
	if ctrl == null:
		ctrl = pad.find_child("PadBaseController", true, false)
	if ctrl != null and ctrl.has_method("print_bench"):
		return ctrl.print_bench()
	return pad.find_child("PadPrintBench", true, false)


func _hangar_queue() -> Node:
	## Same CarrierHangarQueue as ST-D. Does not mint a hull or SITE_*.
	var os := _open_space()
	var hull: Node = null
	var q: Node = null
	var tree := get_tree()
	if os != null and os.has_method("hangar_queue"):
		q = os.hangar_queue()
		if q != null:
			return q
	if os != null and os.has_method("catalog_carrier"):
		hull = os.catalog_carrier()
	if hull != null and hull.has_method("hangar_queue"):
		return hull.hangar_queue()
	if tree:
		var queues: Array = tree.get_nodes_in_group("hangar_queues")
		if not queues.is_empty():
			return queues[0]
	return null


func _try_auto_print() -> void:
	if printed_catalog_module() != null:
		return
	print_one_catalog_module()


func _try_auto_queue() -> void:
	## NP-H after harvest. Does not replace NP-G bench print.
	if queued_hangar_module() != null:
		return
	queue_one_hangar_module()


func _try_auto_factory() -> void:
	## NP-I after harvest. Does not replace NP-G bench or NP-H hangar.
	if printed_factory_module() != null:
		return
	print_one_factory_module()


func _factory_in_cluster() -> Node3D:
	## Same ST-G factory. Must already sit in the player cluster.
	var os := _open_space()
	var n: Node3D = null
	var tree := get_tree()
	if os != null and os.has_method("player_factory"):
		n = os.player_factory()
		if n != null and is_instance_valid(n) and n.is_inside_tree():
			return n
	if os != null and os.has_method("player_orbital_station"):
		var cluster: Node = os.player_orbital_station()
		if cluster != null and cluster.has_method("factory_module"):
			n = cluster.factory_module()
			if n != null and is_instance_valid(n) and n.is_inside_tree():
				return n
	if tree:
		for m in tree.get_nodes_in_group("player_factory_modules"):
			if m is Node3D and (m as Node3D).is_inside_tree():
				if str(m.get_meta("module_type", "")) == "factory":
					return m as Node3D
	return null


func _factory_bench() -> Node:
	## Cluster bench (c): PlayerOrbitalStation or PadPrintBench.print_one_factory_module.
	## Not pad print_one_module (a). Not hangar enqueue (b).
	var os := _open_space()
	var cluster: Node = null
	var tree := get_tree()
	if os != null and os.has_method("player_orbital_station"):
		cluster = os.player_orbital_station()
	if cluster != null and cluster.has_method("print_one_factory_module"):
		return cluster
	if tree:
		for b in tree.get_nodes_in_group("print_benches"):
			if b != null and b.has_method("print_one_factory_module"):
				return b
	return null


func _sign_factory_label() -> void:
	## Knowledge names the factory only. Does not cheapen rules/15.
	if _ship == null or not is_instance_valid(_ship):
		return
	var lab: Label3D = _ship.get_node_or_null("Label") as Label3D
	if lab == null:
		lab = _ship.get_node_or_null("StatusLabel") as Label3D
	if lab:
		lab.text = "%s · %s" % [_SoftK.traffic_label("visitor"), _SoftK.factory_label()]


func _sign_hangar_label() -> void:
	## Knowledge names the hangar only. Does not change mass/power caps.
	if _ship == null or not is_instance_valid(_ship):
		return
	var lab: Label3D = _ship.get_node_or_null("Label") as Label3D
	if lab == null:
		lab = _ship.get_node_or_null("StatusLabel") as Label3D
	if lab:
		lab.text = "%s · %s" % [_SoftK.traffic_label("visitor"), _SoftK.hangar_queue_label()]


func _sign_print_label() -> void:
	## Knowledge names the bench only. Does not cheapen rules/15.
	if _ship == null or not is_instance_valid(_ship):
		return
	var lab: Label3D = _ship.get_node_or_null("Label") as Label3D
	if lab == null:
		lab = _ship.get_node_or_null("StatusLabel") as Label3D
	if lab:
		lab.text = "%s · %s" % [_SoftK.traffic_label("visitor"), _SoftK.print_bench_label()]


func _contract_host_id() -> String:
	var n: Node = _pad
	while n:
		if n is Node3D and str(n.name) in ["Pad_North", "Pad_Approach", "Pad_Flank"]:
			return str(n.name)
		n = n.get_parent()
	if _pad != null and is_instance_valid(_pad):
		return str(_pad.name)
	return "unnamed_pad"


func _sign_giver_label() -> void:
	## Knowledge names the giver only. Does not change yield / DPS / modules.
	if _ship == null or not is_instance_valid(_ship):
		return
	var lab: Label3D = _ship.get_node_or_null("Label") as Label3D
	if lab == null:
		lab = _ship.get_node_or_null("StatusLabel") as Label3D
	if lab:
		lab.text = "%s · %s" % [_SoftK.traffic_label("visitor"), _SoftK.quest_giver_label()]


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
