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
## Knowledge labels only — never yield.

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
const _DUMMY := preload("res://scenes/combat/CombatDummy.tscn")
const _SHIP := preload("res://scenes/ship/Ship.tscn")
const _Pilot := preload("res://scripts/world/NpcPilot.gd")

var _host_name: String = ""
var _guard: Node3D = null
var _surface_dummy: Node3D = null
var _visitor: Node3D = null
var _visitor_base: Vector3 = Vector3(16.0, 6.5, -12.0)
var _life_accum: float = 0.0
var _alliance: Node = null


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
	_offer_player_contract()
	refresh_labels()
	set_process(true)
	print("[PadTraffic] host=", _host_name, " guard=1 visitor=1 surface=1")


func host_pad_name() -> String:
	return _host_name


func get_guard() -> Node3D:
	if _guard != null and is_instance_valid(_guard):
		return _guard
	return null


func get_visitor() -> Node3D:
	if _visitor != null and is_instance_valid(_visitor):
		return _visitor
	return null


func get_npc_pilot() -> Node:
	var v := get_visitor()
	if v == null:
		return null
	return v.get_node_or_null("NpcPilot")


func get_surface_dummy() -> Node3D:
	if _surface_dummy != null and is_instance_valid(_surface_dummy):
		return _surface_dummy
	return null


func get_alliance() -> Node:
	if _alliance != null and is_instance_valid(_alliance):
		return _alliance
	return get_node_or_null("SoftAlliance")


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
	d.set("can_move", false)
	d.set("aggro_range", 0.0)
	d.set("attack_range", 0.0)
	d.set("grant_economy", false)
	d.set("intel_name", guard_label())
	d.set_meta("pad_traffic_role", "guard")
	d.set_meta("site_pin", "")
	add_child(d)
	if d is Node3D:
		(d as Node3D).position = Vector3(-8.0, 1.2, 8.0)
		d.set("_spawn_pos", (d as Node3D).global_position)
		_guard = d as Node3D


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
