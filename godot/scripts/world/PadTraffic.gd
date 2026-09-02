extends Node3D
## SC pillar 13 / NP-A: one pad-guard dummy + one visitor ShipController on a loaded pad.
## Pillar 6: one gROT CombatDummy near the plate for surface Pulse (no new weapon).
## Visitor flies the existing SCM/HOVER/LAND loop and occupy/harvest (NP-B).
## NP-D may invite that pilot into a local squad. NP-F: short offline pad/follow.
## NP-E: guard + visitor share AllianceRanks and a visible raid/logistics intent.
## NP-C: visitor may place one habitat on an empty unnamed pad. Not siege. Not pay-to-rank.
## NP-G: after NP-B harvest, visitor spends at PadPrintBench §6(a) (same ST-C path).
## NP-H: after NP-B harvest, visitor queues one catalog module on the ST-D hangar.
## NP-I: after NP-B harvest, visitor spends at player-cluster factory bench (c) (same ST-G path).
## Q-D: visitor offers the same Q-A ContractBoard id. Player accepts from this NPC.
## PV-A / PV-B: one host-authority rival CombatDummy on this occupied unnamed pad.
## TPS walker and seated hull share that rival. Pulse 11 both ways.
## Win = rival HP → 0. No permadeath. G5 stays closed.
## BT-A: the existing pad-guard walks a tiny 3-state BT (patrol / engage / return).
## Distinct from the PV-A rival. Host authority. Pulse 11. Not Clash waves.
## BT-B: the visitor NpcPilot walks a sibling 3-state BT (approach / hold / leave).
## Hold keeps NP-B occupy/harvest. Host authority. Pulse 11. Not Clash waves.
## BT-C: one gROT swarm of 3 CombatDummy (gather / pulse-engage / scatter-return-to-pad).
## Host authority. Pulse 11 both ways. Infection cap 5. No permadeath. Not Clash waves.
## Distinct from BT-A pad-guard, BT-B visitor, PV-A rival, and the surface dummy.
## BT-D: one Cybernex animal-robot pack of 3 CombatDummy (same 3-state BT). Mirror of BT-C.
## Distinct from BT-C swarm. Host authority. Pulse 11 both ways. Cap 5. No permadeath.
## SN-A: second local viewer sees a SoftNet visual SurfaceWalker puppet.
## Host keeps Pulse / occupy. No second physical walker. Not ENet cluster.
## Knowledge labels only — never yield.

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
const _DUMMY := preload("res://scenes/combat/CombatDummy.tscn")
const _SHIP := preload("res://scenes/ship/Ship.tscn")
const _Pilot := preload("res://scripts/world/NpcPilot.gd")
const _Pvp := preload("res://scripts/world/PadPvp.gd")
const _SoftNet := preload("res://scripts/world/PadSoftNet.gd")
const _GuardBT := preload("res://scripts/combat/PadGuardBT.gd")
const _VisitorBT := preload("res://scripts/world/VisitorBT.gd")
const _SwarmBT := preload("res://scripts/combat/GrotSwarmBT.gd")
const _PackBT := preload("res://scripts/combat/CybernexPackBT.gd")

var _host_name: String = ""
var _guard: Node3D = null
var _surface_dummy: Node3D = null
var _visitor: Node3D = null
var _visitor_base: Vector3 = Vector3(16.0, 6.5, -12.0)
var _life_accum: float = 0.0
var _alliance: Node = null
var _pvp: Node = null
var _softnet: Node = null
var _swarm: Node3D = null
var _pack: Node3D = null


func setup(host_pad: Node3D) -> void:
	if host_pad != null:
		_host_name = str(host_pad.name)
	set_meta("site_pin", "")
	set_meta("pad_traffic", true)
	add_to_group("pad_traffic")
	_spawn_guard()
	_spawn_surface_dummy()
	_spawn_visitor()
	_setup_alliance()
	_setup_pvp()
	_setup_softnet()
	_spawn_swarm()
	_spawn_pack()
	_offer_player_contract()
	refresh_labels()
	set_process(true)
	print("[PadTraffic] host=", _host_name, " guard=1 visitor=1 surface=1 rival=1 softnet=1 swarm=3 pack=3")


func host_pad_name() -> String:
	return _host_name


func get_guard() -> Node3D:
	if _guard != null and is_instance_valid(_guard):
		return _guard
	return null


func get_guard_bt() -> Node:
	var g := get_guard()
	if g == null:
		return null
	return g.get_node_or_null("PadGuardBT")


func guard_bt_state() -> String:
	var bt := get_guard_bt()
	if bt != null and bt.has_method("bt_state"):
		return str(bt.bt_state())
	return ""


func try_guard_pulse(target: Node = null) -> bool:
	var bt := get_guard_bt()
	if bt != null and bt.has_method("try_engage_pulse"):
		return bool(bt.try_engage_pulse(target))
	var g := get_guard()
	if g != null and g.has_method("try_pulse_walker"):
		return bool(g.try_pulse_walker(target))
	return false


func get_visitor() -> Node3D:
	if _visitor != null and is_instance_valid(_visitor):
		return _visitor
	return null


func get_npc_pilot() -> Node:
	var v := get_visitor()
	if v == null:
		return null
	return v.get_node_or_null("NpcPilot")


func get_visitor_bt() -> Node:
	var p := get_npc_pilot()
	if p == null:
		return null
	return p.get_node_or_null("VisitorBT")


func visitor_bt_state() -> String:
	var bt := get_visitor_bt()
	if bt != null and bt.has_method("bt_state"):
		return str(bt.bt_state())
	return ""


func get_surface_dummy() -> Node3D:
	if _surface_dummy != null and is_instance_valid(_surface_dummy):
		return _surface_dummy
	return null


func get_alliance() -> Node:
	if _alliance != null and is_instance_valid(_alliance):
		return _alliance
	return get_node_or_null("SoftAlliance")


func get_pvp() -> Node:
	if _pvp != null and is_instance_valid(_pvp):
		return _pvp
	return get_node_or_null("PadPvp")


func get_rival() -> Node3D:
	var p := get_pvp()
	if p != null and p.has_method("get_rival"):
		return p.get_rival()
	return null


func get_softnet() -> Node:
	if _softnet != null and is_instance_valid(_softnet):
		return _softnet
	return get_node_or_null("PadSoftNet")


func pad_softnet() -> Node:
	return get_softnet()


func combat_authority() -> String:
	var p := get_pvp()
	if p != null and p.has_method("combat_authority"):
		return str(p.combat_authority())
	return "host"


func is_g5_closed() -> bool:
	var p := get_pvp()
	if p != null and p.has_method("is_g5_closed"):
		return bool(p.is_g5_closed())
	return true


func pulse_target() -> Node3D:
	## Hostile dummy for surface Pulse. Pad-guard stays host-faction traffic.
	var d := get_surface_dummy()
	if d != null:
		return d
	return get_guard()


func actor_count() -> int:
	var n := 0
	if get_guard() != null:
		n += 1
	if get_visitor() != null:
		n += 1
	return n


func guard_label() -> String:
	return _SoftK.traffic_label("guard")


func visitor_label() -> String:
	return _SoftK.traffic_label("visitor")


func surface_dummy_label() -> String:
	return _SoftK.surface_dummy_label()


func rival_label() -> String:
	var p := get_pvp()
	if p != null and p.has_method("rival_label"):
		return str(p.rival_label())
	return _SoftK.rival_label()


func swarm_label() -> String:
	return _SoftK.swarm_label()


func get_swarm() -> Node3D:
	if _swarm != null and is_instance_valid(_swarm):
		return _swarm
	return get_node_or_null("GrotSwarm") as Node3D


func get_swarm_bt() -> Node:
	var s := get_swarm()
	if s == null:
		return null
	return s.get_node_or_null("GrotSwarmBT")


func swarm_bt_state() -> String:
	var bt := get_swarm_bt()
	if bt != null and bt.has_method("bt_state"):
		return str(bt.bt_state())
	return ""


func get_swarm_members() -> Array:
	var out: Array = []
	var s := get_swarm()
	if s == null:
		return out
	for c in s.get_children():
		if c != null and is_instance_valid(c) and c is CharacterBody3D \
				and str(c.get_meta("pad_traffic_role", "")) == "swarm":
			out.append(c)
	return out


func swarm_count() -> int:
	return get_swarm_members().size()


func try_swarm_pulse(target: Node = null) -> bool:
	var bt := get_swarm_bt()
	if bt != null and bt.has_method("try_engage_pulse"):
		return bool(bt.try_engage_pulse(target))
	var members := get_swarm_members()
	if members.is_empty():
		return false
	var d: Node = members[0]
	if d != null and d.has_method("try_pulse_walker"):
		return bool(d.try_pulse_walker(target))
	if d != null and d.has_method("try_pulse"):
		return bool(d.try_pulse(target))
	return false


func pack_label() -> String:
	return _SoftK.pack_label()


func get_pack() -> Node3D:
	if _pack != null and is_instance_valid(_pack):
		return _pack
	return get_node_or_null("CybernexPack") as Node3D


func get_pack_bt() -> Node:
	var p := get_pack()
	if p == null:
		return null
	return p.get_node_or_null("CybernexPackBT")


func pack_bt_state() -> String:
	var bt := get_pack_bt()
	if bt != null and bt.has_method("bt_state"):
		return str(bt.bt_state())
	return ""


func get_pack_members() -> Array:
	var out: Array = []
	var p := get_pack()
	if p == null:
		return out
	for c in p.get_children():
		if c != null and is_instance_valid(c) and c is CharacterBody3D \
				and str(c.get_meta("pad_traffic_role", "")) == "pack":
			out.append(c)
	return out


func pack_count() -> int:
	return get_pack_members().size()


func try_pack_pulse(target: Node = null) -> bool:
	var bt := get_pack_bt()
	if bt != null and bt.has_method("try_engage_pulse"):
		return bool(bt.try_engage_pulse(target))
	var members := get_pack_members()
	if members.is_empty():
		return false
	var d: Node = members[0]
	if d != null and d.has_method("try_pulse_walker"):
		return bool(d.try_pulse_walker(target))
	if d != null and d.has_method("try_pulse"):
		return bool(d.try_pulse(target))
	return false


func refresh_labels() -> void:
	var extra := _alliance_tag()
	var gname := guard_label()
	if extra != "":
		gname = "%s · %s" % [gname, extra]
	if _guard != null and is_instance_valid(_guard):
		_guard.set("intel_name", gname)
		if _guard.has_method("_update_labels"):
			_guard._update_labels()
	var dname := surface_dummy_label()
	if _surface_dummy != null and is_instance_valid(_surface_dummy):
		_surface_dummy.set("intel_name", dname)
		if _surface_dummy.has_method("_update_labels"):
			_surface_dummy._update_labels()
	var pvp := get_pvp()
	if pvp != null and pvp.has_method("refresh_label"):
		pvp.refresh_label()
	var sname := swarm_label()
	for d in get_swarm_members():
		if d == null or not is_instance_valid(d):
			continue
		d.set("intel_name", sname)
		if d.has_method("_update_labels"):
			d._update_labels()
	var pname := pack_label()
	for d in get_pack_members():
		if d == null or not is_instance_valid(d):
			continue
		d.set("intel_name", pname)
		if d.has_method("_update_labels"):
			d._update_labels()
	var vname := visitor_label()
	if extra != "":
		vname = "%s · %s" % [vname, extra]
	if _visitor != null and is_instance_valid(_visitor):
		var lab: Label3D = _visitor.get_node_or_null("Label") as Label3D
		if lab == null:
			lab = _visitor.get_node_or_null("StatusLabel") as Label3D
		if lab:
			lab.text = vname


func _setup_alliance() -> void:
	## Guard + visitor: ranks/perms only. Intent is raid or logistics, not siege.
	var a := Node.new()
	a.set_script(preload("res://scripts/systems/SoftAlliance.gd"))
	a.name = "SoftAlliance"
	add_child(a)
	_alliance = a
	var g: Node = get_guard()
	var p: Node = get_npc_pilot()
	if p == null:
		p = get_visitor()
	if a.has_method("bind"):
		a.bind(g, 1, "harvest_share", p, 2, "constructor_pin", "raid")
	_offer_alliance_contract(a)


func _offer_alliance_contract(ally: Node) -> void:
	## Q-B: one shared occupy/logistics contract on this unnamed pad. Same id for both NPCs.
	var Board = load("res://scripts/systems/ContractBoard.gd")
	var host := _host_name
	var intent := ""
	var offer: Dictionary = {}
	if ally == null or Board == null:
		return
	if host == "":
		var pad := get_parent()
		host = str(pad.name) if pad != null else "unnamed_pad"
	if ally.has_method("intent"):
		intent = str(ally.intent())
	offer = Board.offer_alliance_one(host, "Nex-Prime", intent)
	if offer.is_empty():
		return
	if ally.has_method("see_contract"):
		ally.see_contract(str(offer.get("id", "")))
	refresh_labels()


func _setup_pvp() -> void:
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.PV_A_PVP):
		return
	var existing: Node = get_node_or_null("PadPvp")
	if existing != null:
		_pvp = existing
		if _pvp.has_method("bind"):
			_pvp.bind(self)
		return
	var p: Node3D = Node3D.new()
	p.set_script(_Pvp)
	p.name = "PadPvp"
	add_child(p)
	_pvp = p
	if p.has_method("bind"):
		p.bind(self)


func _setup_softnet() -> void:
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.SN_A_PAD):
		return
	var existing: Node = get_node_or_null("PadSoftNet")
	if existing != null:
		_softnet = existing
		if _softnet.has_method("bind"):
			_softnet.bind(self)
		return
	var n: Node3D = Node3D.new()
	n.set_script(_SoftNet)
	n.name = "PadSoftNet"
	add_child(n)
	_softnet = n
	if n.has_method("bind"):
		n.bind(self)


func _offer_player_contract() -> void:
	## Q-D: same Q-A board the ops console uses. Not a second quest system.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var p: Node = get_npc_pilot()
	if P0 == null or not bool(P0.Q_D_GIVER) or not bool(P0.Q_A_CONTRACT):
		return
	if p != null and p.has_method("offer_player_contract"):
		p.offer_player_contract()


func _alliance_tag() -> String:
	var a := get_alliance()
	if a == null or not a.has_method("intent"):
		return ""
	var kind := str(a.intent()).to_upper()
	if kind != "RAID" and kind != "LOGISTICS":
		return ""
	return kind


func _spawn_guard() -> void:
	if _DUMMY == null:
		return
	var d: Node = _DUMMY.instantiate()
	d.name = "PadGuardDummy"
	d.set("faction", _host_faction())
	d.set("can_move", true)
	d.set("bt_driven", true)
	d.set("aggro_range", 16.0)
	d.set("attack_range", 16.0)
	d.set("attack_damage", 11.0)
	d.set("grant_economy", false)
	d.set("intel_name", guard_label())
	d.set_meta("pad_traffic_role", "guard")
	d.set_meta("combat_authority", "host")
	d.set_meta("site_pin", "")
	add_child(d)
	if d is Node3D:
		(d as Node3D).position = Vector3(-8.0, 1.2, 8.0)
		d.set("_spawn_pos", (d as Node3D).global_position)
		_guard = d as Node3D
	_bind_guard_bt(d)


func _bind_guard_bt(d: Node) -> void:
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 != null and not bool(P0.BT_A_GUARD):
		return
	if d == null or _GuardBT == null:
		return
	var existing: Node = d.get_node_or_null("PadGuardBT")
	var bt: Node = existing
	if bt == null:
		bt = Node.new()
		bt.set_script(_GuardBT)
		bt.name = "PadGuardBT"
		d.add_child(bt)
	var pad: Node3D = get_parent() as Node3D
	if bt.has_method("bind"):
		bt.bind(d, pad)


func _bind_visitor_bt(pilot: Node, ship: Node, pad: Node3D) -> void:
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 != null and not bool(P0.BT_B_VISITOR):
		return
	if pilot == null or _VisitorBT == null:
		return
	var existing: Node = pilot.get_node_or_null("VisitorBT")
	var bt: Node = existing
	if bt == null:
		bt = Node.new()
		bt.set_script(_VisitorBT)
		bt.name = "VisitorBT"
		pilot.add_child(bt)
	if bt.has_method("bind"):
		bt.bind(pilot, ship as Node3D, pad)


func _spawn_swarm() -> void:
	## BT-C: three gROT CombatDummy on this occupied unnamed pad. Not Clash waves.
	## Distinct from pad-guard, surface dummy, PV-A rival, and visitor hull.
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 != null and not bool(P0.BT_C_SWARM):
		return
	if _DUMMY == null:
		return
	var existing: Node = get_node_or_null("GrotSwarm")
	var root: Node3D = existing as Node3D if existing is Node3D else null
	if root == null:
		root = Node3D.new()
		root.name = "GrotSwarm"
		root.set_meta("site_pin", "")
		root.set_meta("pad_traffic_role", "swarm")
		root.set_meta("combat_authority", "host")
		add_child(root)
	_swarm = root
	var spots: Array[Vector3] = [
		Vector3(-6.0, 1.2, -6.0),
		Vector3(-10.0, 1.2, -2.0),
		Vector3(-2.0, 1.2, -10.0),
	]
	var members: Array = []
	for i in range(spots.size()):
		var kid: Node = root.get_node_or_null("SwarmDummy%d" % i)
		var d: Node = kid
		if d == null:
			d = _DUMMY.instantiate()
			d.name = "SwarmDummy%d" % i
			root.add_child(d)
		d.set("faction", "gROT")
		d.set("can_move", true)
		d.set("bt_driven", true)
		d.set("lane_march", false)
		d.set("one_shot", false)
		d.set("aggro_range", 16.0)
		d.set("attack_range", 16.0)
		d.set("attack_damage", 11.0)
		d.set("grant_economy", false)
		d.set("intel_name", swarm_label())
		d.set_meta("pad_traffic_role", "swarm")
		d.set_meta("combat_authority", "host")
		d.set_meta("grot_swarm", true)
		d.set_meta("site_pin", "")
		if d.is_in_group("clash_minion"):
			d.remove_from_group("clash_minion")
		if d is Node3D:
			(d as Node3D).position = spots[i]
			d.set("_spawn_pos", (d as Node3D).global_position)
		members.append(d)
	_bind_swarm_bt(root, members)


func _bind_swarm_bt(root: Node, members: Array) -> void:
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 != null and not bool(P0.BT_C_SWARM):
		return
	if root == null or _SwarmBT == null:
		return
	var existing: Node = root.get_node_or_null("GrotSwarmBT")
	var bt: Node = existing
	if bt == null:
		bt = Node.new()
		bt.set_script(_SwarmBT)
		bt.name = "GrotSwarmBT"
		root.add_child(bt)
	var pad: Node3D = get_parent() as Node3D
	if bt.has_method("bind"):
		bt.bind(members, pad)


func _spawn_pack() -> void:
	## BT-D: three Cybernex CombatDummy on this occupied unnamed pad. Mirror of BT-C.
	## Distinct from pad-guard, surface dummy, PV-A rival, visitor hull, and gROT swarm.
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 != null and not bool(P0.BT_D_PACK):
		return
	if _DUMMY == null:
		return
	var existing: Node = get_node_or_null("CybernexPack")
	var root: Node3D = existing as Node3D if existing is Node3D else null
	if root == null:
		root = Node3D.new()
		root.name = "CybernexPack"
		root.set_meta("site_pin", "")
		root.set_meta("pad_traffic_role", "pack")
		root.set_meta("combat_authority", "host")
		add_child(root)
	_pack = root
	var spots: Array[Vector3] = [
		Vector3(6.0, 1.2, 10.0),
		Vector3(10.0, 1.2, 12.0),
		Vector3(12.0, 1.2, 8.0),
	]
	var members: Array = []
	for i in range(spots.size()):
		var kid: Node = root.get_node_or_null("PackDummy%d" % i)
		var d: Node = kid
		if d == null:
			d = _DUMMY.instantiate()
			d.name = "PackDummy%d" % i
			root.add_child(d)
		d.set("faction", "Cybernex")
		d.set("can_move", true)
		d.set("bt_driven", true)
		d.set("lane_march", false)
		d.set("one_shot", false)
		d.set("aggro_range", 16.0)
		d.set("attack_range", 16.0)
		d.set("attack_damage", 11.0)
		d.set("grant_economy", false)
		d.set("intel_name", pack_label())
		d.set_meta("pad_traffic_role", "pack")
		d.set_meta("combat_authority", "host")
		d.set_meta("cybernex_pack", true)
		d.set_meta("grot_swarm", false)
		d.set_meta("site_pin", "")
		if d.is_in_group("clash_minion"):
			d.remove_from_group("clash_minion")
		if d is Node3D:
			(d as Node3D).position = spots[i]
			d.set("_spawn_pos", (d as Node3D).global_position)
		members.append(d)
	_bind_pack_bt(root, members)


func _bind_pack_bt(root: Node, members: Array) -> void:
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 != null and not bool(P0.BT_D_PACK):
		return
	if root == null or _PackBT == null:
		return
	var existing: Node = root.get_node_or_null("CybernexPackBT")
	var bt: Node = existing
	if bt == null:
		bt = Node.new()
		bt.set_script(_PackBT)
		bt.name = "CybernexPackBT"
		root.add_child(bt)
	var pad: Node3D = get_parent() as Node3D
	if bt.has_method("bind"):
		bt.bind(members, pad)


func _spawn_surface_dummy() -> void:
	## Pillar 6: existing CombatDummy, gROT so Cybernex Pulse can hit. No new weapon.
	if _DUMMY == null:
		return
	var d: Node = _DUMMY.instantiate()
	d.name = "SurfaceCombatDummy"
	d.set("faction", "gROT")
	d.set("can_move", false)
	d.set("aggro_range", 0.0)
	d.set("attack_range", 0.0)
	d.set("grant_economy", false)
	d.set("intel_name", surface_dummy_label())
	d.set_meta("pad_traffic_role", "surface_dummy")
	d.set_meta("site_pin", "")
	add_child(d)
	if d is Node3D:
		(d as Node3D).position = Vector3(8.0, 1.2, 4.0)
		d.set("_spawn_pos", (d as Node3D).global_position)
		_surface_dummy = d as Node3D


func _spawn_visitor() -> void:
	if _SHIP == null:
		_spawn_visitor_hold()
		return
	var s: Node = _SHIP.instantiate()
	s.name = "VisitorShip"
	s.set("pilot_active", false)
	s.set_meta("pad_traffic_role", "visitor")
	s.set_meta("npc_pilot", true)
	s.set_meta("site_pin", "")
	var keep: Camera3D = null
	var vp := get_viewport()
	if vp:
		keep = vp.get_camera_3d()
	var cam: Camera3D = s.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if cam:
		cam.current = false
	add_child(s)
	_visitor = s as Node3D
	if s.has_method("set_npc_driven"):
		s.set_npc_driven(true)
	if keep != null and is_instance_valid(keep) and vp != null and vp.get_camera_3d() != keep:
		keep.current = true
	var pilot := Node.new()
	pilot.set_script(_Pilot)
	pilot.name = "NpcPilot"
	s.add_child(pilot)
	var host := get_parent() as Node3D
	if pilot.has_method("setup"):
		pilot.call("setup", s, host)
	_bind_visitor_bt(pilot, s, host)
	if DisplayServer.get_name() == "headless":
		return
	var lab := Label3D.new()
	lab.name = "Label"
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 22
	lab.outline_size = 5
	lab.position = Vector3(0, 2.4, 0)
	lab.text = visitor_label()
	lab.modulate = Color(0.75, 0.9, 1.0)
	s.add_child(lab)


func _spawn_visitor_hold() -> void:
	var v := Node3D.new()
	v.name = "VisitorHold"
	v.set_meta("pad_traffic_role", "visitor")
	v.set_meta("site_pin", "")
	v.position = _visitor_base
	add_child(v)
	_visitor = v
	_add_marker(v, "Hull")
	if DisplayServer.get_name() == "headless":
		return
	_build_visitor_hull(v)
	var lab := Label3D.new()
	lab.name = "Label"
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 22
	lab.outline_size = 5
	lab.position = Vector3(0, 2.4, 0)
	lab.text = visitor_label()
	lab.modulate = Color(0.75, 0.9, 1.0)
	v.add_child(lab)


func _add_marker(host: Node3D, id: String) -> void:
	var n := Node3D.new()
	n.name = id
	n.set_meta("site_pin", "")
	n.set_meta("pad_traffic_part", id.to_lower())
	host.add_child(n)


func _build_visitor_hull(v: Node3D) -> void:
	var col := Color(0.28, 0.82, 1.0)
	if _host_faction() == "gROT":
		col = Color(0.95, 0.2, 0.4)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.6
	_box(v, "Body", Vector3(2.4, 0.9, 5.2), Vector3.ZERO, mat)
	_box(v, "Wing", Vector3(5.4, 0.16, 1.6), Vector3(0, -0.1, 0.4), mat)
	_box(v, "Nacelle", Vector3(0.7, 0.45, 2.2), Vector3(0, 0.55, 1.1), mat)


func _box(host: Node3D, id: String, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = id + "Mesh"
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.position = pos
	host.add_child(mi)


func _host_faction() -> String:
	var host := get_parent()
	var planet: Node = null
	if host != null and host.has_meta("planet"):
		planet = host.get_meta("planet")
	if planet != null and "faction_base" in planet:
		return str(planet.faction_base)
	return "Cybernex"


func _process(delta: float) -> void:
	_life_accum += delta
	if _life_accum < 0.2:
		return
	_life_accum = 0.0
	if get_npc_pilot() != null:
		return
	if _visitor == null or not is_instance_valid(_visitor):
		return
	var t := Time.get_ticks_msec() * 0.001
	_visitor.position = _visitor_base + Vector3(0.0, sin(t * 0.9) * 0.35, 0.0)
	_visitor.rotation.y = t * 0.08
