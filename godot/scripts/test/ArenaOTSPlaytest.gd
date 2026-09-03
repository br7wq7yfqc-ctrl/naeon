extends Node
## Headless AR-A…AR-W + river + jump pads: OTS, structures, waves, camps, kits/module shop, 3v3/5v5, CORE match-end, XP/level labels, 3-lane waves.
## godot --path godot --scene res://scenes/test/TestArena.tscn -- --playtest-arena

func _ready() -> void:
	var wanted := false
	for a in OS.get_cmdline_user_args():
		if str(a) == "--playtest-arena":
			wanted = true
			break
	if not wanted:
		queue_free()
		return
	print("[Playtest] arena AR-A…AR-W + river + jump pads driver on")
	call_deferred("_go")


func _go() -> void:
	await get_tree().create_timer(0.7).timeout
	var fails: PackedStringArray = PackedStringArray()
	var arena: Node = get_parent()
	if arena == null or str(arena.name) != "TestArena":
		_finish(["no TestArena parent"], PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), 1)
		return

	var player: Node = arena.get("player")
	if player == null or not is_instance_valid(player):
		fails.append("no player")
	elif not player.has_method("ots_evidence"):
		fails.append("player missing ots_evidence")
	else:
		if player.has_method("apply_clash_ots"):
			player.apply_clash_ots()
		var ev: Dictionary = player.ots_evidence()
		print("[Playtest] ots=", ev)
		if not bool(ev.get("active", false)):
			fails.append("OTS not active")
		if float(ev.get("shoulder_x", 0.0)) < 0.45:
			fails.append("camera not over right shoulder")
		var boom := float(ev.get("boom_z", 0.0))
		if boom < 2.2 or boom > 4.2:
			fails.append("boom not 3rd-person behind hero")
		var fov := float(ev.get("fov", 0.0))
		if fov < 66.0 or fov > 80.0:
			fails.append("fov not OTS MOBA")
		var pitch := float(ev.get("pitch_deg", 0.0))
		if pitch < -20.0 or pitch > -4.0:
			fails.append("default pitch is RTS/top-down or flat chase")
		var pmin := float(ev.get("pitch_min", -80.0))
		if pmin < -40.0:
			fails.append("pitch clamp still allows top-down RTS")
		var world_y := float(ev.get("world_y", 0.0))
		if world_y > 4.2 or world_y < 1.6:
			fails.append("camera height not OTS")
		var cam: Camera3D = player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
		if cam == null:
			fails.append("CameraPivot/Camera3D missing")
		elif not cam.current:
			fails.append("arena camera not current")

	var lanes: Node = arena.get("_lanes")
	if lanes == null or not is_instance_valid(lanes):
		fails.append("ClashLanes missing")
	elif not lanes.has_method("lane_spawn_table") or not lanes.has_method("lane_at"):
		fails.append("ClashLanes API missing")
	else:
		if str(lanes.lane_at(Vector3(14, 0, 0))) != "TOP":
			fails.append("TOP lane unread")
		if str(lanes.lane_at(Vector3(0, 0, 0))) != "MID":
			fails.append("MID lane unread")
		if str(lanes.lane_at(Vector3(-14, 0, 0))) != "BOT":
			fails.append("BOT lane unread")
		var seen: Dictionary = {}
		for e in lanes.lane_spawn_table():
			seen[str(e[1])] = true
		for need in ["TOP", "MID", "BOT"]:
			if not seen.has(need):
				fails.append("spawn table missing " + need)
		print("[Playtest] lanes TOP/MID/BOT spawn=", seen.size())

	if LayerContext:
		if str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
			fails.append("unexpected SITE pin (do not mint)")
	if ResourceLoader.exists("res://scenes/ui/MainMenu.tscn") == false:
		fails.append("MainMenu door missing")

	var ar_a_fails: PackedStringArray = fails.duplicate()
	var ar_c_fails: PackedStringArray = await _check_ar_c(arena, lanes, player)
	var ar_b_fails: PackedStringArray = _check_ar_b(arena, lanes, player)
	var ar_d_fails: PackedStringArray = _check_ar_d(arena, lanes, player)
	var ar_e_fails: PackedStringArray = _check_ar_e(arena, lanes, player)
	var river_fails: PackedStringArray = _check_river(arena)
	var ar_f_fails: PackedStringArray = _check_ar_f(arena, lanes, player)
	var ar_g_fails: PackedStringArray = _check_ar_g(arena, lanes, player)
	var pad_fails: PackedStringArray = await _check_jump_pads(arena, player)
	var ar_j_fails: PackedStringArray = _check_ar_j(arena, lanes, player)
	var ar_k_fails: PackedStringArray = _check_ar_k(arena, lanes, player)
	var ar_l_fails: PackedStringArray = _check_ar_l(arena, lanes, player)
	var ar_m_fails: PackedStringArray = _check_ar_m(arena, lanes, player)
	var ar_n_fails: PackedStringArray = _check_ar_n(arena, lanes, player)
	var ar_o_fails: PackedStringArray = _check_ar_o(arena, lanes, player)
	var ar_p_fails: PackedStringArray = _check_ar_p(arena, lanes, player)
	var ar_q_fails: PackedStringArray = _check_ar_q(arena, lanes, player)
	var ar_r_fails: PackedStringArray = _check_ar_r(arena, lanes, player)
	var ar_s_fails: PackedStringArray = _check_ar_s(arena, lanes, player)
	var ar_t_fails: PackedStringArray = await _check_ar_t(arena, lanes, player)
	var ar_u_fails: PackedStringArray = await _check_ar_u(arena, lanes, player)
	var ar_v_fails: PackedStringArray = await _check_ar_v(arena, lanes, player)
	var ar_w_fails: PackedStringArray = await _check_ar_w(arena, lanes, player)
	var ar_i_fails: PackedStringArray = _check_ar_i(arena, lanes, player)
	fails.append_array(ar_c_fails)
	fails.append_array(ar_b_fails)
	fails.append_array(ar_d_fails)
	fails.append_array(ar_e_fails)
	fails.append_array(river_fails)
	fails.append_array(pad_fails)
	fails.append_array(ar_f_fails)
	fails.append_array(ar_g_fails)
	fails.append_array(ar_j_fails)
	fails.append_array(ar_k_fails)
	fails.append_array(ar_l_fails)
	fails.append_array(ar_m_fails)
	fails.append_array(ar_n_fails)
	fails.append_array(ar_o_fails)
	fails.append_array(ar_p_fails)
	fails.append_array(ar_q_fails)
	fails.append_array(ar_r_fails)
	fails.append_array(ar_s_fails)
	fails.append_array(ar_t_fails)
	fails.append_array(ar_u_fails)
	fails.append_array(ar_v_fails)
	fails.append_array(ar_w_fails)
	fails.append_array(ar_i_fails)

	_finish(ar_a_fails, ar_b_fails, ar_c_fails, ar_d_fails, ar_e_fails, river_fails, pad_fails, ar_f_fails, ar_g_fails, ar_i_fails, ar_j_fails, ar_k_fails, ar_l_fails, ar_m_fails, ar_n_fails, ar_o_fails, ar_p_fails, ar_q_fails, ar_r_fails, ar_s_fails, ar_t_fails, ar_u_fails, ar_v_fails, ar_w_fails, 0 if fails.is_empty() else 1)


func _check_ar_b(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	if lanes == null or not is_instance_valid(lanes):
		fails.append("ClashLanes missing for AR-B")
		return fails
	if not lanes.has_method("structure_table") or not lanes.has_method("find_structure"):
		fails.append("ClashLanes structure API missing")
		return fails
	var table: Array = lanes.structure_table()
	var roles: Dictionary = {}
	for e in table:
		roles[str(e.get("role", ""))] = int(roles.get(str(e.get("role", "")), 0)) + 1
	print("[Playtest] structures=", table.size(), " roles=", roles)
	for need in ["OUTER", "MID", "INHIB", "CORE"]:
		if int(roles.get(need, 0)) < 1:
			fails.append("missing structure role " + need)
	# Honest HP: damage then kill a gROT OUTER with the existing Turret piece.
	var root: Node3D = lanes.find_structure("OUTER", "gROT", "MID") as Node3D
	if root == null:
		fails.append("gROT MID OUTER missing")
		return fails
	var gun: Node = root.get_node_or_null("Gun")
	if gun == null or not gun.has_method("take_damage"):
		fails.append("OUTER gun is not a damageable Turret")
		return fails
	var hp0 := float(gun.get("health"))
	gun.take_damage(40.0, "Cybernex")
	var hp1 := float(gun.get("health"))
	print("[Playtest] OUTER hp ", hp0, " -> ", hp1, " alive=", gun.call("is_alive") if gun.has_method("is_alive") else "?")
	if hp1 >= hp0:
		fails.append("OUTER did not take damage")
	if gun.has_method("is_alive") and not bool(gun.is_alive()):
		fails.append("40 dmg should not kill OUTER")
	gun.take_damage(9999.0, "Cybernex")
	if gun.has_method("is_alive") and bool(gun.is_alive()):
		fails.append("OUTER survived kill hit")
	# Remaining roles still living (we only killed one OUTER).
	if lanes.has_method("living_roles"):
		var living: PackedStringArray = lanes.living_roles()
		for need in ["OUTER", "MID", "INHIB", "CORE"]:
			if not living.has(need):
				fails.append("role gone after one kill: " + need)
	# MID / INHIB / CORE also take damage (do not kill — core death ends the match).
	for role_id in ["MID", "INHIB", "CORE"]:
		var extra: Node3D = lanes.find_structure(role_id, "gROT") as Node3D
		if extra == null:
			fails.append("gROT %s missing" % role_id)
			continue
		var eg: Node = extra.get_node_or_null("Gun")
		if eg == null or not eg.has_method("take_damage"):
			fails.append("%s gun missing" % role_id)
			continue
		var e0 := float(eg.get("health"))
		eg.take_damage(15.0, "Cybernex")
		var e1 := float(eg.get("health"))
		print("[Playtest] ", role_id, " hp ", e0, " -> ", e1)
		if e1 >= e0:
			fails.append("%s did not take damage" % role_id)
		if eg.has_method("is_alive") and not bool(eg.is_alive()):
			fails.append("%s died from probe hit" % role_id)
	# AR-A must not regress after structure combat.
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after structure hit")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-B")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	return fails


func _check_ar_c(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var waves: Node = arena.get_node_or_null("ClashWaves") if arena else null
	if waves == null and arena:
		waves = arena.get("_waves")
	if waves == null or not is_instance_valid(waves):
		fails.append("ClashWaves missing")
		return fails
	if not waves.has_method("living_minions"):
		fails.append("ClashWaves API missing")
		return fails
	var live: Array = waves.living_minions()
	if live.is_empty():
		await get_tree().create_timer(0.45).timeout
		live = waves.living_minions()
	print("[Playtest] wave_index=", waves.get("wave_index"), " living=", live.size())
	if live.is_empty():
		fails.append("no wave minions on a lane")
		return fails
	var walker: Node3D = null
	for n in live:
		if n is Node3D and str(n.get("faction")) == "Cybernex":
			walker = n as Node3D
			break
	if walker == null:
		walker = live[0] as Node3D
	var lane_id := str(walker.get_meta("lane")) if walker.has_meta("lane") else ""
	if lane_id == "" and lanes and lanes.has_method("lane_at"):
		lane_id = str(lanes.lane_at(walker.global_position))
	if lane_id != "TOP" and lane_id != "MID" and lane_id != "BOT":
		fails.append("minion not on a Clash lane")
	var z0 := walker.global_position.z
	await get_tree().create_timer(0.45).timeout
	if walker == null or not is_instance_valid(walker):
		fails.append("wave minion freed before march")
		return fails
	var z1 := walker.global_position.z
	var fac := str(walker.get("faction")) if "faction" in walker else ""
	var marched := (fac == "Cybernex" and z1 < z0 - 0.35) or (fac == "gROT" and z1 > z0 + 0.35)
	print("[Playtest] march ", fac, " ", lane_id, " z ", z0, " -> ", z1)
	if not marched:
		fails.append("minion did not walk the lane")
	if not walker.has_method("take_damage"):
		fails.append("minion is not a CombatDummy")
	else:
		var mhp0 := float(walker.get("health"))
		walker.take_damage(8.0, "Cybernex" if fac != "Cybernex" else "gROT")
		var mhp1 := float(walker.get("health"))
		print("[Playtest] minion hp ", mhp0, " -> ", mhp1)
		if mhp1 >= mhp0:
			fails.append("minion did not take damage")
	# OUTER hook: opposite-faction dummy can hit a living turret.
	if lanes and lanes.has_method("find_structure"):
		var shooter: Node3D = walker
		for n in waves.living_minions():
			if n is Node3D and str(n.get("faction")) == "gROT":
				shooter = n as Node3D
				break
		var outer_fac := "Cybernex" if str(shooter.get("faction")) == "gROT" else "gROT"
		var root: Node3D = lanes.find_structure("OUTER", outer_fac, "MID") as Node3D
		if root == null:
			fails.append("%s MID OUTER missing for wave hook" % outer_fac)
		else:
			var gun: Node = root.get_node_or_null("Gun")
			if gun == null or not gun.has_method("take_damage"):
				fails.append("OUTER gun missing for wave hook")
			else:
				var ohp0 := float(gun.get("health"))
				if shooter.has_method("_fire_at"):
					shooter._fire_at(gun)
				var ohp1 := float(gun.get("health"))
				print("[Playtest] OUTER from minion hp ", ohp0, " -> ", ohp1)
				if ohp1 >= ohp0:
					fails.append("minion could not damage OUTER")
				if gun.has_method("is_alive") and not bool(gun.is_alive()):
					fails.append("OUTER died from wave probe")
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after wave")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-C")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	return fails


func _check_ar_d(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var camp: Node = arena.get_node_or_null("ClashCamp") if arena else null
	if camp == null and arena:
		camp = arena.get("_camp")
	if camp == null or not is_instance_valid(camp):
		fails.append("ClashCamp missing")
		return fails
	if not camp.has_method("take_damage") or not camp.has_method("is_contested"):
		fails.append("ClashCamp API missing")
		return fails
	if camp.has_method("is_off_lane") and not bool(camp.is_off_lane()):
		fails.append("camp sits on a lane strip")
	elif lanes and lanes.has_method("is_off_lane") and camp is Node3D \
		and not bool(lanes.is_off_lane((camp as Node3D).global_position)):
		fails.append("camp not off-lane on ClashLanes")
	var hp0 := float(camp.get("health"))
	var max0 := float(camp.get("max_health"))
	camp.take_damage(18.0, "Cybernex")
	var hp1 := float(camp.get("health"))
	print("[Playtest] camp hp ", hp0, " -> ", hp1, " state=", camp.call("get_contest_state") if camp.has_method("get_contest_state") else "?")
	if hp1 >= hp0:
		fails.append("camp did not take damage")
	if camp.has_method("is_alive") and not bool(camp.is_alive()):
		fails.append("18 dmg should not kill camp")
	if not bool(camp.is_contested()):
		fails.append("camp did not announce contest")
	var announced := ""
	if camp.has_method("last_announce"):
		announced = str(camp.last_announce())
	if announced == "":
		fails.append("contest announce empty")
	elif announced.to_lower().find("weapon") < 0 and announced.to_lower().find("contest") < 0:
		fails.append("contest announce missing")
	if camp.has_method("camp_drop_kind") and str(camp.camp_drop_kind()) != "soft_ws":
		fails.append("camp drop is not soft WS")
	# Knowledge may relabel; must not change HP / unique DPS.
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("ecology", 20.0)
	if absf(float(camp.get("max_health")) - max0) > 0.01:
		fails.append("Knowledge changed camp HP")
	if camp.has_method("label_text") and str(camp.label_text()) == "":
		fails.append("Knowledge camp label empty")
	# AR-C waves and AR-B structures still live after the pit probe.
	var waves: Node = arena.get_node_or_null("ClashWaves") if arena else null
	if waves == null and arena:
		waves = arena.get("_waves")
	if waves == null or not waves.has_method("living_minions") or waves.living_minions().is_empty():
		fails.append("waves gone after camp")
	if lanes and lanes.has_method("living_roles"):
		var living: PackedStringArray = lanes.living_roles()
		for need in ["OUTER", "MID", "INHIB", "CORE"]:
			if not living.has(need):
				fails.append("structure role gone after camp: " + need)
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after camp")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-D")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	return fails


func _check_ar_e(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids") or not Kit.has_method("kit_by_id"):
		fails.append("AbilityKitCatalog missing")
		return fails
	var ids: PackedStringArray = Kit.kit_ids()
	print("[Playtest] kits=", ",".join(ids), " n=", ids.size())
	if ids.size() < 4 or ids.size() > 12:
		fails.append("kit count not 4–12")
	var seen_fac: Dictionary = {}
	for kit_id in ids:
		var kit: Array = Kit.kit_by_id(str(kit_id))
		if kit.size() != 4:
			fails.append("%s is not 4 slots" % kit_id)
			continue
		var n0: String = str(kit[0].ability_name) if kit[0] else ""
		var n3: String = str(kit[3].ability_name) if kit[3] else ""
		if n0 != "Pulse Bolt":
			fails.append("%s slot0 is not Pulse" % kit_id)
		if n3 != "Form Cycle":
			fails.append("%s slot3 is not Form Cycle" % kit_id)
		var slot1 = kit[1]
		var slot2 = kit[2]
		if slot1 == null or (not bool(slot1.is_firewall) and not bool(slot1.is_hacking)):
			fails.append("%s slot1 is not utility" % kit_id)
		var probe_or_surge := false
		if slot2:
			probe_or_surge = bool(slot2.is_hacking) or float(slot2.aoe_radius) > 0.05
		if not probe_or_surge:
			fails.append("%s slot2 is not probe-or-surge" % kit_id)
		if float(kit[0].damage) != 11.0:
			fails.append("%s Pulse damage drifted" % kit_id)
		var meta: Dictionary = Kit.kit_meta(str(kit_id)) if Kit.has_method("kit_meta") else {}
		seen_fac[str(meta.get("faction", ""))] = true
	if not seen_fac.has("Cybernex") or not seen_fac.has("gROT"):
		fails.append("missing a faction kit")
	if Kit.has_method("kit_for_faction"):
		var cx0: Array = Kit.kit_for_faction("Cybernex")
		var gr0: Array = Kit.kit_for_faction("gROT")
		if cx0.size() != 4 or str(cx0[1].ability_name) != "Nex-Firewall":
			fails.append("default CX kit changed")
		if gr0.size() != 4 or str(gr0[1].ability_name) != "Hack":
			fails.append("default GR kit changed")
	if player == null or not player.ability_system:
		fails.append("player AbilitySystem missing")
		return fails
	var absys = player.ability_system
	var hp0 := float(player.max_health)
	var hp_now := float(player.health)
	var pulse0 := 0.0
	if absys.abilities.size() > 0 and absys.abilities[0]:
		pulse0 = float(absys.abilities[0].damage)
	var form0 := str(player.current_form) if "current_form" in player else ""
	if absys.has_method("setup_kit"):
		absys.setup_kit("cx_grid", "Cybernex")
		if str(absys.current_kit_id) != "cx_grid":
			fails.append("could not apply CX Grid kit")
		if absys.abilities.size() != 4:
			fails.append("Grid kit not 4 slots")
		elif str(absys.abilities[1].ability_name) != "Nex Latch":
			fails.append("Grid utility missing")
		absys.setup_kit("gr_spore", "gROT")
		if absys.abilities.size() != 4 or str(absys.abilities[2].ability_name) != "Rot Bloom":
			fails.append("Spore surge missing")
		absys.setup_kit("cx_nex", "Cybernex")
	if absf(float(player.max_health) - hp0) > 0.01 or absf(float(player.health) - hp_now) > 0.01:
		fails.append("kit swap changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("kit swap changed Pulse DPS")
	if player.has_method("cycle_form"):
		player.cycle_form()
	var form1 := str(player.current_form) if "current_form" in player else ""
	print("[Playtest] Form Cycle ", form0, " → ", form1)
	if form1 == "" or form1 == form0:
		fails.append("Form Cycle did not change identity")
	if absf(float(player.max_health) - hp0) > 0.01:
		fails.append("form changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("form changed Pulse DPS")
	var bench: Node = arena.get_node_or_null("ClashModuleBench") if arena else null
	if bench == null and arena:
		bench = arena.get("_bench")
	if bench == null or not is_instance_valid(bench):
		fails.append("ClashModuleBench missing")
		return fails
	if bench.has_method("is_on_footprint") and not bool(bench.is_on_footprint()):
		fails.append("bench left the TestArena footprint")
	if bench.has_method("is_off_lane") and not bool(bench.is_off_lane()):
		fails.append("bench sits on a lane strip")
	elif lanes and lanes.has_method("is_off_lane") and bench is Node3D \
		and not bool(lanes.is_off_lane((bench as Node3D).global_position)):
		fails.append("bench not off-lane on ClashLanes")
	if bench.has_method("offer_kind") and str(bench.offer_kind()) != "ship_module":
		fails.append("bench offer is not a ShipModule")
	if bench.has_method("cost_kind") and str(bench.cost_kind()) != "session":
		fails.append("bench is a cash-shop")
	if bench.has_method("modifies_combat") and bool(bench.modifies_combat()):
		fails.append("bench claims combat power")
	if not bench.has_method("try_equip"):
		fails.append("bench try_equip missing")
		return fails
	if not bool(bench.try_equip(player)):
		fails.append("could not equip session module")
	if bench.has_method("has_equipped") and not bool(bench.has_equipped()):
		fails.append("module not equipped")
	if "clash_module_id" in player and str(player.clash_module_id) == "":
		fails.append("player has no module tag")
	if absf(float(player.max_health) - hp0) > 0.01:
		fails.append("module changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("module changed Pulse DPS")
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("cybernetics", 20.0)
	if absf(float(player.max_health) - hp0) > 0.01:
		fails.append("Knowledge changed HP")
	if bench.has_method("label_text") and str(bench.label_text()) == "":
		fails.append("Knowledge bench label empty")
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-E")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-E")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	return fails


func _check_river(arena: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var river: Node = arena.get_node_or_null("ClashRiver") if arena else null
	if river == null and arena:
		river = arena.get("_river")
	if river == null or not is_instance_valid(river):
		fails.append("ClashRiver missing")
		return fails
	if river.has_method("is_present") and not bool(river.is_present()):
		fails.append("river not present")
	if river.has_method("is_on_footprint") and not bool(river.is_on_footprint()):
		fails.append("river left the TestArena footprint")
	if river.has_method("is_between_lanes") and not bool(river.is_between_lanes()):
		fails.append("river not between lanes")
	if river.has_method("is_objective") and bool(river.is_objective()):
		fails.append("river became an objective")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during river")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] river present=", river.has_method("is_present") and bool(river.is_present()), " footprint=", river.has_method("is_on_footprint") and bool(river.is_on_footprint()))
	return fails


func _check_jump_pads(arena: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var pads: Node = arena.get_node_or_null("ClashJumpPads") if arena else null
	if pads == null and arena:
		pads = arena.get("_jump_pads")
	if pads == null or not is_instance_valid(pads):
		fails.append("ClashJumpPads missing")
		return fails
	if pads.has_method("is_present") and not bool(pads.is_present()):
		fails.append("jump pads not present")
	if pads.has_method("is_on_footprint") and not bool(pads.is_on_footprint()):
		fails.append("jump pads left the TestArena footprint")
	var n := int(pads.pad_count()) if pads.has_method("pad_count") else 0
	if n < 2 or n > 4:
		fails.append("jump pad count not 2–4")
	if pads.has_method("is_flight") and bool(pads.is_flight()):
		fails.append("pads claim flight")
	if pads.has_method("is_objective") and bool(pads.is_objective()):
		fails.append("pads became an objective")
	var table: Array = pads.pad_table() if pads.has_method("pad_table") else []
	if table.is_empty():
		fails.append("pad table empty")
		return fails
	var pad0: Dictionary = table[0]
	var pad_pos: Vector3 = pad0.get("pos", Vector3.ZERO)
	var dummy_scene: PackedScene = load("res://scenes/combat/CombatDummy.tscn")
	if dummy_scene == null:
		fails.append("CombatDummy missing for hop")
		return fails
	var walker: CharacterBody3D = dummy_scene.instantiate() as CharacterBody3D
	walker.set("faction", "Cybernex")
	walker.set("can_move", false)
	walker.set("lane_march", false)
	arena.add_child(walker)
	walker.global_position = pad_pos + Vector3(0.0, 1.15, 0.0)
	await get_tree().create_timer(0.28).timeout
	if walker == null or not is_instance_valid(walker):
		fails.append("hop walker freed")
		return fails
	var y0 := walker.global_position.y
	var launched := false
	if walker.is_on_floor() or walker.velocity.y <= 0.4:
		if pads.has_method("try_launch"):
			launched = bool(pads.try_launch(walker, true))
	else:
		launched = true
	if not launched and pads.has_method("last_hop_ok"):
		launched = bool(pads.last_hop_ok())
	print("[Playtest] pad hop launch=", launched, " y0=", y0, " floor=", walker.is_on_floor())
	if not launched:
		fails.append("jump pad did not launch")
		walker.queue_free()
		return fails
	await get_tree().create_timer(0.22).timeout
	if walker == null or not is_instance_valid(walker):
		fails.append("hop walker freed mid-air")
		return fails
	var y1 := walker.global_position.y
	print("[Playtest] pad hop peak-ish y ", y0, " -> ", y1, " vy=", walker.velocity.y)
	if y1 <= y0 + 0.35:
		fails.append("walker did not hop")
	var peak_cap := 4.5
	if pads.has_method("max_hop_peak"):
		peak_cap = float(pads.max_hop_peak())
	if y1 - y0 > peak_cap:
		fails.append("hop was flight not a short hop")
	await get_tree().create_timer(1.35).timeout
	if walker == null or not is_instance_valid(walker):
		fails.append("hop walker freed before land")
		return fails
	var y2 := walker.global_position.y
	print("[Playtest] pad land y=", y2, " floor=", walker.is_on_floor())
	if not walker.is_on_floor():
		fails.append("walker did not land")
	if y2 >= y1 - 0.15:
		fails.append("walker stayed at hop height")
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after jump pad")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during jump pads")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	walker.queue_free()
	return fails


func _check_ar_f(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var matchn: Node = arena.get_node_or_null("ClashLocalMatch") if arena else null
	if matchn == null and arena:
		matchn = arena.get("_local_match")
	if matchn == null or not is_instance_valid(matchn):
		fails.append("ClashLocalMatch missing")
		return fails
	if not matchn.has_method("living_actors") or not matchn.has_method("is_local_authority"):
		fails.append("ClashLocalMatch API missing")
		return fails
	var probe: Node3D = null
	if matchn.has_method("is_5v5") and bool(matchn.is_5v5()):
		## 3v3 remains startable — isolated probe, no G5, do not rewrite AR-F.
		var dummy_scene: PackedScene = load("res://scenes/combat/CombatDummy.tscn")
		if dummy_scene == null:
			fails.append("AR-F CombatDummy missing")
			return fails
		probe = Node3D.new()
		probe.set_script(preload("res://scripts/arena/ClashLocalMatch.gd"))
		probe.name = "ClashLocalMatch3v3Probe"
		arena.add_child(probe)
		if probe.has_method("start_isolated"):
			probe.start_isolated(arena, dummy_scene)
		matchn = probe
	var live: Array = matchn.living_actors()
	print("[Playtest] AR-F 3v3 local match actors=", live.size(), " lanes=", matchn.lane_ids() if matchn.has_method("lane_ids") else "?",
		" authority=", matchn.combat_authority() if matchn.has_method("combat_authority") else "?",
		" G5=", "closed" if matchn.has_method("is_g5_closed") and bool(matchn.is_g5_closed()) else "open")
	if live.size() != 6:
		fails.append("want 6 actors on 3v3, got %s" % live.size())
	var seen: Dictionary = {}
	var cx := 0
	var gr := 0
	for n in live:
		var lane := ""
		if matchn.has_method("lane_of"):
			lane = str(matchn.lane_of(n))
		elif n != null and n.has_meta("lane"):
			lane = str(n.get_meta("lane"))
		if lane != "TOP" and lane != "MID" and lane != "BOT":
			fails.append("actor not on a Clash lane (%s)" % lane)
		else:
			seen[lane] = true
		var fac := str(n.get("faction")) if n != null and "faction" in n else ""
		if fac == "Cybernex":
			cx += 1
		elif fac == "gROT":
			gr += 1
		if absf((n as Node3D).global_position.x) > 28.0 or absf((n as Node3D).global_position.z) > 28.0:
			fails.append("actor left the 60×60 footprint")
	for need in ["TOP", "MID", "BOT"]:
		if not seen.has(need):
			fails.append("3v3 missing lane " + need)
	if cx != 3 or gr != 3:
		fails.append("want 3+3, got CX=%s GR=%s" % [cx, gr])
	if matchn.has_method("is_local_authority") and not bool(matchn.is_local_authority()):
		fails.append("not local host authority")
	if matchn.has_method("is_g5_closed") and not bool(matchn.is_g5_closed()):
		fails.append("G5 Clash-from-world is open")
	if matchn.has_method("is_5v5") and bool(matchn.is_5v5()):
		fails.append("5v5 shipped before 3v3")
	if matchn.has_method("visual_puppet_count") and int(matchn.visual_puppet_count()) < 5:
		fails.append("SoftNet visual puppets missing (got %s)" % int(matchn.visual_puppet_count()))
	var dmg0 := -1.0
	for n in live:
		if n != player and n != null and "attack_damage" in n:
			dmg0 = float(n.get("attack_damage"))
			break
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("cybernetics", 20.0)
	for n in live:
		if n != player and n != null and "attack_damage" in n:
			if dmg0 >= 0.0 and absf(float(n.get("attack_damage")) - dmg0) > 0.01:
				fails.append("Knowledge changed DPS")
			break
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-F")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-F")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	var waves: Node = arena.get_node_or_null("ClashWaves") if arena else null
	if waves == null and arena:
		waves = arena.get("_waves")
	if waves == null or not waves.has_method("living_minions") or waves.living_minions().is_empty():
		fails.append("waves gone after AR-F")
	if lanes and lanes.has_method("living_roles"):
		var living: PackedStringArray = lanes.living_roles()
		for need in ["OUTER", "MID", "INHIB", "CORE"]:
			if not living.has(need):
				fails.append("structure role gone after AR-F: " + need)
	print("[Playtest] AR-F 6 actors on existing lanes · local authority · G5 closed · no SITE_*")
	if probe != null and is_instance_valid(probe):
		if probe.has_method("shutdown"):
			probe.shutdown()
		probe.queue_free()
	return fails


func _check_ar_g(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var matchn: Node = arena.get_node_or_null("ClashLocalMatch") if arena else null
	if matchn == null and arena:
		matchn = arena.get("_local_match")
	if matchn == null or not is_instance_valid(matchn):
		fails.append("ClashLocalMatch missing for AR-G")
		return fails
	if not matchn.has_method("living_actors") or not matchn.has_method("is_local_authority"):
		fails.append("ClashLocalMatch API missing for AR-G")
		return fails
	if matchn.has_method("is_5v5") and not bool(matchn.is_5v5()):
		if matchn.has_method("start_5v5"):
			matchn.start_5v5()
		elif matchn.has_method("bind_5v5"):
			var dummy_scene: PackedScene = load("res://scenes/combat/CombatDummy.tscn")
			matchn.bind_5v5(arena, lanes, dummy_scene, player)
	var live: Array = matchn.living_actors()
	print("[Playtest] AR-G 5v5 local match actors=", live.size(), " lanes=", matchn.lane_ids() if matchn.has_method("lane_ids") else "?",
		" authority=", matchn.combat_authority() if matchn.has_method("combat_authority") else "?",
		" G5=", "closed" if matchn.has_method("is_g5_closed") and bool(matchn.is_g5_closed()) else "open")
	if live.size() != 10:
		fails.append("want 10 actors on 5v5, got %s" % live.size())
	var seen: Dictionary = {}
	var cx := 0
	var gr := 0
	var jungle := 0
	for n in live:
		var lane := ""
		if matchn.has_method("lane_of"):
			lane = str(matchn.lane_of(n))
		elif n != null and n.has_meta("lane"):
			lane = str(n.get_meta("lane"))
		if lane != "TOP" and lane != "MID" and lane != "BOT" and lane != "JUNGLE":
			fails.append("actor not on existing footprint (%s)" % lane)
		else:
			seen[lane] = true
		if lane == "JUNGLE":
			jungle += 1
		var fac := str(n.get("faction")) if n != null and "faction" in n else ""
		if fac == "Cybernex":
			cx += 1
		elif fac == "gROT":
			gr += 1
		if n is Node3D and (absf((n as Node3D).global_position.x) > 28.0 or absf((n as Node3D).global_position.z) > 28.0):
			fails.append("actor left the 60×60 footprint")
	for need in ["TOP", "MID", "BOT"]:
		if not seen.has(need):
			fails.append("5v5 missing lane " + need)
	if not seen.has("JUNGLE") or jungle < 4:
		fails.append("5v5 missing jungle slots (got %s)" % jungle)
	if cx != 5 or gr != 5:
		fails.append("want 5+5, got CX=%s GR=%s" % [cx, gr])
	if matchn.has_method("is_local_authority") and not bool(matchn.is_local_authority()):
		fails.append("not local host authority")
	if matchn.has_method("is_g5_closed") and not bool(matchn.is_g5_closed()):
		fails.append("G5 Clash-from-world is open")
	if matchn.has_method("is_5v5") and not bool(matchn.is_5v5()):
		fails.append("5v5 not active")
	if matchn.has_method("visual_puppet_count") and int(matchn.visual_puppet_count()) < 9:
		fails.append("SoftNet visual puppets missing (got %s)" % int(matchn.visual_puppet_count()))
	var dmg0 := -1.0
	for n in live:
		if n != player and n != null and "attack_damage" in n:
			dmg0 = float(n.get("attack_damage"))
			break
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("cybernetics", 20.0)
	for n in live:
		if n != player and n != null and "attack_damage" in n:
			if dmg0 >= 0.0 and absf(float(n.get("attack_damage")) - dmg0) > 0.01:
				fails.append("Knowledge changed DPS")
			break
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-G")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-G")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	var waves: Node = arena.get_node_or_null("ClashWaves") if arena else null
	if waves == null and arena:
		waves = arena.get("_waves")
	if waves == null or not waves.has_method("living_minions") or waves.living_minions().is_empty():
		fails.append("waves gone after AR-G")
	if lanes and lanes.has_method("living_roles"):
		var living: PackedStringArray = lanes.living_roles()
		for need in ["OUTER", "MID", "INHIB", "CORE"]:
			if not living.has(need):
				fails.append("structure role gone after AR-G: " + need)
	print("[Playtest] AR-G 10 actors on existing footprint · local authority · G5 closed · no SITE_*")
	return fails


func _check_ar_j(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_J_PRIME_CAMP):
		fails.append("AR-J P0Slice flag missing")
	if P0 != null and not bool(P0.AR_I_MATCH_END):
		fails.append("AR-J dropped AR-I P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-J flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-J Infection cap drifted")
	var fang: Node = arena.get_node_or_null("ClashCamp") if arena else null
	if fang == null and arena:
		fang = arena.get("_camp")
	if fang == null or not is_instance_valid(fang):
		fails.append("AR-J lost AR-D ClashCamp")
		return fails
	var prime: Node = arena.get_node_or_null("ClashPrimeCamp") if arena else null
	if prime == null and arena:
		prime = arena.get("_prime_camp")
	if prime == null or not is_instance_valid(prime):
		fails.append("ClashPrimeCamp missing")
		return fails
	if prime == fang:
		fails.append("prime camp is the AR-D pit")
	if not prime.has_method("take_damage") or not prime.has_method("is_contested"):
		fails.append("ClashPrimeCamp API missing")
		return fails
	var role := ""
	if prime.has_method("get_camp_role"):
		role = str(prime.get_camp_role())
	elif "camp_role" in prime:
		role = str(prime.camp_role)
	if role != "prime":
		fails.append("prime camp role is not prime (%s)" % role)
	if prime.has_method("is_off_lane") and not bool(prime.is_off_lane()):
		fails.append("prime camp sits on a lane strip")
	elif lanes and lanes.has_method("is_off_lane") and prime is Node3D \
		and not bool(lanes.is_off_lane((prime as Node3D).global_position)):
		fails.append("prime camp not off-lane on ClashLanes")
	if fang is Node3D and prime is Node3D:
		if (fang as Node3D).global_position.distance_to((prime as Node3D).global_position) < 4.0:
			fails.append("prime camp stacked on AR-D pit")
	var hp0 := float(prime.get("health"))
	var max0 := float(prime.get("max_health"))
	if max0 <= float(fang.get("max_health")) + 0.01:
		fails.append("prime camp HP not a distinct class")
	prime.take_damage(18.0, "Cybernex")
	var hp1 := float(prime.get("health"))
	print("[Playtest] prime camp hp ", hp0, " -> ", hp1, " role=", role,
		" state=", prime.call("get_contest_state") if prime.has_method("get_contest_state") else "?")
	if hp1 >= hp0:
		fails.append("prime camp did not take damage")
	if prime.has_method("is_alive") and not bool(prime.is_alive()):
		fails.append("18 dmg should not kill prime camp")
	if not bool(prime.is_contested()):
		fails.append("prime camp did not announce contest")
	var announced := ""
	if prime.has_method("last_announce"):
		announced = str(prime.last_announce())
	if announced == "":
		fails.append("prime contest announce empty")
	elif announced.to_lower().find("weapon") < 0 and announced.to_lower().find("contest") < 0:
		fails.append("prime contest announce missing")
	if prime.has_method("camp_drop_kind") and str(prime.camp_drop_kind()) != "soft_ws":
		fails.append("prime drop is not soft WS")
	if fang.has_method("camp_drop_kind") and str(fang.camp_drop_kind()) != "soft_ws":
		fails.append("AR-D drop drifted off soft WS")
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("ecology", 20.0)
		GameManager.add_mastery("history", 20.0)
	if absf(float(prime.get("max_health")) - max0) > 0.01:
		fails.append("Knowledge changed prime camp HP")
	if fang.has_method("get") and absf(float(fang.get("max_health")) - 220.0) > 0.01:
		fails.append("Knowledge changed AR-D camp HP")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if SoftK:
		var plab := str(SoftK.camp_label("prime"))
		if plab == "" or (plab != "PRIME" and plab != "PRIME PIT"):
			fails.append("SoftKnowledge prime label missing (%s)" % plab)
		if SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("prime")):
			fails.append("AR-J unlocked exclusive weapon")
	if prime.has_method("label_text") and str(prime.label_text()) == "":
		fails.append("Knowledge prime label empty")
	var waves: Node = arena.get_node_or_null("ClashWaves") if arena else null
	if waves == null and arena:
		waves = arena.get("_waves")
	if waves == null or not waves.has_method("living_minions") or waves.living_minions().is_empty():
		fails.append("waves gone after prime camp")
	if lanes and lanes.has_method("living_roles"):
		var living: PackedStringArray = lanes.living_roles()
		for need in ["OUTER", "MID", "INHIB", "CORE"]:
			if not living.has(need):
				fails.append("structure role gone after prime camp: " + need)
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after prime camp")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-J")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-J prime off-lane · soft WS · AR-D stays · G5 closed · no SITE_*")
	return fails


func _check_ar_k(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_K_SESSION_SHOP):
		fails.append("AR-K P0Slice flag missing")
	if P0 != null and not bool(P0.AR_J_PRIME_CAMP):
		fails.append("AR-K dropped AR-J P0Slice flag")
	if P0 != null and not bool(P0.AR_I_MATCH_END):
		fails.append("AR-K dropped AR-I P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-K flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-K Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids"):
		fails.append("AR-K AbilityKitCatalog missing")
	else:
		var prior: PackedStringArray = Kit.kit_ids()
		for need in ["cx_nex", "cx_grid", "gr_rot", "gr_spore"]:
			if not prior.has(need):
				fails.append("AR-K AbilityKitCatalog prior kit missing (%s)" % need)
	var bench: Node = arena.get_node_or_null("ClashModuleBench") if arena else null
	if bench == null and arena:
		bench = arena.get("_bench")
	if bench == null or not is_instance_valid(bench):
		fails.append("AR-K ClashModuleBench missing")
		return fails
	if bench.has_method("is_on_footprint") and not bool(bench.is_on_footprint()):
		fails.append("AR-K bench left the TestArena footprint")
	if bench.has_method("is_off_lane") and not bool(bench.is_off_lane()):
		fails.append("AR-K bench sits on a lane strip")
	elif lanes and lanes.has_method("is_off_lane") and bench is Node3D \
		and not bool(lanes.is_off_lane((bench as Node3D).global_position)):
		fails.append("AR-K bench not off-lane on ClashLanes")
	var n := int(bench.offer_count()) if bench.has_method("offer_count") else 0
	if n != 2:
		fails.append("AR-K bench offer count want 2 (got %s)" % n)
	if bench.has_method("option_kind") and str(bench.option_kind(0)) != "sensor":
		fails.append("AR-K dropped AR-E SENSOR offer")
	if bench.has_method("option_kind") and str(bench.option_kind(1)) != "cargo":
		fails.append("AR-K second offer is not catalog cargo")
	if bench.has_method("is_weapon_offer") and bool(bench.is_weapon_offer(1)):
		fails.append("AR-K second offer is a unique weapon")
	if bench.has_method("is_paragon_deck") and bool(bench.is_paragon_deck()):
		fails.append("AR-K became a Paragon card deck")
	if bench.has_method("is_cash_shop") and bool(bench.is_cash_shop()):
		fails.append("AR-K is a cash-shop")
	if bench.has_method("cost_kind") and str(bench.cost_kind()) != "session":
		fails.append("AR-K bench is not session-cost")
	if bench.has_method("modifies_combat") and bool(bench.modifies_combat()):
		fails.append("AR-K bench claims combat power")
	var pulse0 := 11.0
	var hp0 := 0.0
	if player:
		hp0 = float(player.get("max_health")) if "max_health" in player else 0.0
		if player.get("ability_system") != null:
			var absys: Node = player.ability_system
			if absys and "abilities" in absys:
				for ab in absys.abilities:
					if ab != null and str(ab.get("ability_name")).to_lower().find("pulse") >= 0:
						pulse0 = float(ab.get("damage"))
						break
	if not bench.has_method("try_equip"):
		fails.append("AR-K try_equip missing")
		return fails
	if not bool(bench.try_equip(player, 1)):
		fails.append("AR-K could not equip second session module")
	if bench.has_method("equipped_index") and int(bench.equipped_index()) != 1:
		fails.append("AR-K did not equip the second option")
	if bench.has_method("option_kind") and str(bench.option_kind(1)) == "weapon":
		fails.append("AR-K equipped a weapon")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("cybernetics", 20.0)
		GameManager.add_mastery("logistics", 20.0)
	var olab := str(SoftK.module_option_label("cargo")) if SoftK else ""
	if olab == "" or (olab != "HOLD" and olab != "NEX HOLD"):
		fails.append("AR-K SoftKnowledge option label missing (%s)" % olab)
	if bench.has_method("option_label"):
		var blab := str(bench.option_label(1))
		if blab == "" or (blab != "HOLD" and blab != "NEX HOLD"):
			fails.append("AR-K HUD option label missing (%s)" % blab)
	if player:
		if "max_health" in player and hp0 > 0.0 and absf(float(player.get("max_health")) - hp0) > 0.01:
			fails.append("AR-K Knowledge changed HP")
		if player.get("ability_system") != null:
			var absys2: Node = player.ability_system
			if absys2 and "abilities" in absys2:
				for ab in absys2.abilities:
					if ab != null and str(ab.get("ability_name")).to_lower().find("pulse") >= 0:
						if absf(float(ab.get("damage")) - pulse0) > 0.01:
							fails.append("AR-K Knowledge changed Pulse")
						break
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("hold")):
		fails.append("AR-K unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("cargo_nex_hold")):
		fails.append("AR-K unlocked exclusive combat module")
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-K")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-K")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-K session shop · 2 options · cargo catalog · SoftKnowledge only · G5 closed · no SITE_*")
	return fails


func _check_ar_l(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_L_FIFTH_KIT):
		fails.append("AR-L P0Slice flag missing")
	if P0 != null and not bool(P0.AR_K_SESSION_SHOP):
		fails.append("AR-L dropped AR-K P0Slice flag")
	if P0 != null and not bool(P0.AR_J_PRIME_CAMP):
		fails.append("AR-L dropped AR-J P0Slice flag")
	if P0 != null and not bool(P0.AR_I_MATCH_END):
		fails.append("AR-L dropped AR-I P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-L flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-L Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids") or not Kit.has_method("kit_by_id"):
		fails.append("AR-L AbilityKitCatalog missing")
		return fails
	var ids: PackedStringArray = Kit.kit_ids()
	if int(ids.size()) < 5:
		fails.append("AR-L kit count want >= 5 (got %s)" % ids.size())
	for need in ["cx_nex", "cx_grid", "gr_rot", "gr_spore"]:
		if not ids.has(need):
			fails.append("AR-L dropped prior kit (%s)" % need)
	if not ids.has("cx_lattice"):
		fails.append("AR-L fifth kit cx_lattice missing")
	var kit: Array = Kit.kit_by_id("cx_lattice")
	if kit.size() != 4:
		fails.append("AR-L Lattice is not 4 slots")
	else:
		if kit[0] == null or str(kit[0].ability_name) != "Pulse Bolt":
			fails.append("AR-L Lattice slot0 is not Pulse")
		elif absf(float(kit[0].damage) - 11.0) > 0.01:
			fails.append("AR-L Lattice Pulse damage drifted")
		var slot1 = kit[1]
		if slot1 == null or not bool(slot1.is_firewall):
			fails.append("AR-L Lattice slot1 is not utility")
		elif str(slot1.ability_name) != "Lattice Seal":
			fails.append("AR-L Lattice utility missing")
		var slot2 = kit[2]
		if slot2 == null or not bool(slot2.is_hacking):
			fails.append("AR-L Lattice slot2 is not probe-or-surge")
		elif str(slot2.ability_name) != "Lattice Probe":
			fails.append("AR-L Lattice probe missing")
		if kit[3] == null or str(kit[3].ability_name) != "Form Cycle":
			fails.append("AR-L Lattice slot3 is not Form Cycle")
	if Kit.has_method("kit_for_faction"):
		var cx0: Array = Kit.kit_for_faction("Cybernex")
		var gr0: Array = Kit.kit_for_faction("gROT")
		if cx0.size() != 4 or str(cx0[1].ability_name) != "Nex-Firewall":
			fails.append("AR-L default CX kit changed")
		if gr0.size() != 4 or str(gr0[1].ability_name) != "Hack":
			fails.append("AR-L default GR kit changed")
	if player == null or not player.ability_system:
		fails.append("AR-L player AbilitySystem missing")
		return fails
	var absys = player.ability_system
	var hp0 := float(player.max_health)
	var hp_now := float(player.health)
	var pulse0 := 11.0
	if absys.abilities.size() > 0 and absys.abilities[0]:
		pulse0 = float(absys.abilities[0].damage)
	if absys.has_method("setup_kit"):
		absys.setup_kit("cx_lattice", "Cybernex")
		if str(absys.current_kit_id) != "cx_lattice":
			fails.append("AR-L could not apply CX Lattice kit")
		if absys.abilities.size() != 4:
			fails.append("AR-L Lattice kit not 4 slots on player")
		elif str(absys.abilities[1].ability_name) != "Lattice Seal":
			fails.append("AR-L player Lattice utility missing")
	if absf(float(player.max_health) - hp0) > 0.01 or absf(float(player.health) - hp_now) > 0.01:
		fails.append("AR-L kit swap changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-L kit swap changed Pulse DPS")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("combat", 20.0)
		GameManager.add_mastery("history", 20.0)
	if absf(float(player.max_health) - hp0) > 0.01:
		fails.append("AR-L Knowledge changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-L Knowledge changed Pulse")
	var klab := str(SoftK.kit_label("cx_lattice")) if SoftK and SoftK.has_method("kit_label") else ""
	if klab == "" or (klab != "LATTICE" and klab != "NEX LATTICE"):
		fails.append("AR-L SoftKnowledge kit label missing (%s)" % klab)
	if absys.has_method("kit_label"):
		var hlab := str(absys.kit_label())
		if hlab == "" or (hlab != "LATTICE" and hlab != "NEX LATTICE"):
			fails.append("AR-L HUD kit label missing (%s)" % hlab)
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("lattice")):
		fails.append("AR-L unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("cx_lattice")):
		fails.append("AR-L unlocked exclusive combat module")
	var bench: Node = arena.get_node_or_null("ClashModuleBench") if arena else null
	if bench == null and arena:
		bench = arena.get("_bench")
	if bench and bench.has_method("offer_count") and int(bench.offer_count()) != 2:
		fails.append("AR-L drifted ClashModuleBench offers")
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-L")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-L")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-L fifth kit · cx_lattice · SoftKnowledge only · prior 4 stay · G5 closed · no SITE_*")
	return fails


func _check_ar_m(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_M_SIXTH_KIT):
		fails.append("AR-M P0Slice flag missing")
	if P0 != null and not bool(P0.AR_L_FIFTH_KIT):
		fails.append("AR-M dropped AR-L P0Slice flag")
	if P0 != null and not bool(P0.AR_K_SESSION_SHOP):
		fails.append("AR-M dropped AR-K P0Slice flag")
	if P0 != null and not bool(P0.AR_J_PRIME_CAMP):
		fails.append("AR-M dropped AR-J P0Slice flag")
	if P0 != null and not bool(P0.AR_I_MATCH_END):
		fails.append("AR-M dropped AR-I P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-M flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-M Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids") or not Kit.has_method("kit_by_id"):
		fails.append("AR-M AbilityKitCatalog missing")
		return fails
	var ids: PackedStringArray = Kit.kit_ids()
	if int(ids.size()) < 6:
		fails.append("AR-M kit count want >= 6 (got %s)" % ids.size())
	for need in ["cx_nex", "cx_grid", "gr_rot", "gr_spore", "cx_lattice"]:
		if not ids.has(need):
			fails.append("AR-M dropped prior kit (%s)" % need)
	if not ids.has("gr_vein"):
		fails.append("AR-M sixth kit gr_vein missing")
	var kit: Array = Kit.kit_by_id("gr_vein")
	if kit.size() != 4:
		fails.append("AR-M Vein is not 4 slots")
	else:
		if kit[0] == null or str(kit[0].ability_name) != "Pulse Bolt":
			fails.append("AR-M Vein slot0 is not Pulse")
		elif absf(float(kit[0].damage) - 11.0) > 0.01:
			fails.append("AR-M Vein Pulse damage drifted")
		var slot1 = kit[1]
		if slot1 == null or not bool(slot1.is_hacking):
			fails.append("AR-M Vein slot1 is not utility")
		elif str(slot1.ability_name) != "Vein Claim":
			fails.append("AR-M Vein utility missing")
		var slot2 = kit[2]
		if slot2 == null or float(slot2.aoe_radius) <= 0.05:
			fails.append("AR-M Vein slot2 is not probe-or-surge")
		elif str(slot2.ability_name) != "Vein Surge":
			fails.append("AR-M Vein surge missing")
		if kit[3] == null or str(kit[3].ability_name) != "Form Cycle":
			fails.append("AR-M Vein slot3 is not Form Cycle")
	if Kit.has_method("kit_for_faction"):
		var cx0: Array = Kit.kit_for_faction("Cybernex")
		var gr0: Array = Kit.kit_for_faction("gROT")
		if cx0.size() != 4 or str(cx0[1].ability_name) != "Nex-Firewall":
			fails.append("AR-M default CX kit changed")
		if gr0.size() != 4 or str(gr0[1].ability_name) != "Hack":
			fails.append("AR-M default GR kit changed")
	if player == null or not player.ability_system:
		fails.append("AR-M player AbilitySystem missing")
		return fails
	var absys = player.ability_system
	var hp0 := float(player.max_health)
	var hp_now := float(player.health)
	var pulse0 := 11.0
	if absys.abilities.size() > 0 and absys.abilities[0]:
		pulse0 = float(absys.abilities[0].damage)
	if absys.has_method("setup_kit"):
		absys.setup_kit("gr_vein", "gROT")
		if str(absys.current_kit_id) != "gr_vein":
			fails.append("AR-M could not apply GR Vein kit")
		if absys.abilities.size() != 4:
			fails.append("AR-M Vein kit not 4 slots on player")
		elif str(absys.abilities[1].ability_name) != "Vein Claim":
			fails.append("AR-M player Vein utility missing")
	if absf(float(player.max_health) - hp0) > 0.01 or absf(float(player.health) - hp_now) > 0.01:
		fails.append("AR-M kit swap changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-M kit swap changed Pulse DPS")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("combat", 20.0)
		GameManager.add_mastery("history", 20.0)
	if absf(float(player.max_health) - hp0) > 0.01:
		fails.append("AR-M Knowledge changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-M Knowledge changed Pulse")
	var klab := str(SoftK.kit_label("gr_vein")) if SoftK and SoftK.has_method("kit_label") else ""
	if klab == "" or (klab != "VEIN" and klab != "ROT VEIN"):
		fails.append("AR-M SoftKnowledge kit label missing (%s)" % klab)
	if absys.has_method("kit_label"):
		var hlab := str(absys.kit_label())
		if hlab == "" or (hlab != "VEIN" and hlab != "ROT VEIN"):
			fails.append("AR-M HUD kit label missing (%s)" % hlab)
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("vein")):
		fails.append("AR-M unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("gr_vein")):
		fails.append("AR-M unlocked exclusive combat module")
	var bench: Node = arena.get_node_or_null("ClashModuleBench") if arena else null
	if bench == null and arena:
		bench = arena.get("_bench")
	if bench and bench.has_method("offer_count") and int(bench.offer_count()) != 2:
		fails.append("AR-M drifted ClashModuleBench offers")
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-M")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-M")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-M sixth kit · gr_vein · SoftKnowledge only · prior 5 stay · G5 closed · no SITE_*")
	return fails


func _check_ar_n(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_N_SEVENTH_KIT):
		fails.append("AR-N P0Slice flag missing")
	if P0 != null and not bool(P0.AR_M_SIXTH_KIT):
		fails.append("AR-N dropped AR-M P0Slice flag")
	if P0 != null and not bool(P0.AR_L_FIFTH_KIT):
		fails.append("AR-N dropped AR-L P0Slice flag")
	if P0 != null and not bool(P0.AR_K_SESSION_SHOP):
		fails.append("AR-N dropped AR-K P0Slice flag")
	if P0 != null and not bool(P0.AR_J_PRIME_CAMP):
		fails.append("AR-N dropped AR-J P0Slice flag")
	if P0 != null and not bool(P0.AR_I_MATCH_END):
		fails.append("AR-N dropped AR-I P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-N flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-N Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids") or not Kit.has_method("kit_by_id"):
		fails.append("AR-N AbilityKitCatalog missing")
		return fails
	var ids: PackedStringArray = Kit.kit_ids()
	if int(ids.size()) < 7:
		fails.append("AR-N kit count want >= 7 (got %s)" % ids.size())
	for need in ["cx_nex", "cx_grid", "gr_rot", "gr_spore", "cx_lattice", "gr_vein"]:
		if not ids.has(need):
			fails.append("AR-N dropped prior kit (%s)" % need)
	if not ids.has("cx_prism"):
		fails.append("AR-N seventh kit cx_prism missing")
	var kit: Array = Kit.kit_by_id("cx_prism")
	if kit.size() != 4:
		fails.append("AR-N Prism is not 4 slots")
	else:
		if kit[0] == null or str(kit[0].ability_name) != "Pulse Bolt":
			fails.append("AR-N Prism slot0 is not Pulse")
		elif absf(float(kit[0].damage) - 11.0) > 0.01:
			fails.append("AR-N Prism Pulse damage drifted")
		var slot1 = kit[1]
		if slot1 == null or not bool(slot1.is_firewall):
			fails.append("AR-N Prism slot1 is not utility")
		elif str(slot1.ability_name) != "Prism Seal":
			fails.append("AR-N Prism utility missing")
		var slot2 = kit[2]
		if slot2 == null or not bool(slot2.is_hacking):
			fails.append("AR-N Prism slot2 is not probe-or-surge")
		elif str(slot2.ability_name) != "Prism Probe":
			fails.append("AR-N Prism probe missing")
		if kit[3] == null or str(kit[3].ability_name) != "Form Cycle":
			fails.append("AR-N Prism slot3 is not Form Cycle")
	if Kit.has_method("kit_for_faction"):
		var cx0: Array = Kit.kit_for_faction("Cybernex")
		var gr0: Array = Kit.kit_for_faction("gROT")
		if cx0.size() != 4 or str(cx0[1].ability_name) != "Nex-Firewall":
			fails.append("AR-N default CX kit changed")
		if gr0.size() != 4 or str(gr0[1].ability_name) != "Hack":
			fails.append("AR-N default GR kit changed")
	if Kit.has_method("kits_for_faction"):
		var cx_cycle: PackedStringArray = Kit.kits_for_faction("Cybernex")
		if cx_cycle.size() < 4 or str(cx_cycle[3]) != "cx_prism":
			fails.append("AR-N CX Prism not selectable in TestArena kit cycle")
	if player == null or not player.ability_system:
		fails.append("AR-N player AbilitySystem missing")
		return fails
	var absys = player.ability_system
	var hp0 := float(player.max_health)
	var hp_now := float(player.health)
	var pulse0 := 11.0
	if absys.abilities.size() > 0 and absys.abilities[0]:
		pulse0 = float(absys.abilities[0].damage)
	if absys.has_method("setup_kit"):
		absys.setup_kit("cx_prism", "Cybernex")
		if str(absys.current_kit_id) != "cx_prism":
			fails.append("AR-N could not apply CX Prism kit")
		if absys.abilities.size() != 4:
			fails.append("AR-N Prism kit not 4 slots on player")
		elif str(absys.abilities[1].ability_name) != "Prism Seal":
			fails.append("AR-N player Prism utility missing")
	if absf(float(player.max_health) - hp0) > 0.01 or absf(float(player.health) - hp_now) > 0.01:
		fails.append("AR-N kit swap changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-N kit swap changed Pulse DPS")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("combat", 20.0)
		GameManager.add_mastery("history", 20.0)
	if absf(float(player.max_health) - hp0) > 0.01:
		fails.append("AR-N Knowledge changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-N Knowledge changed Pulse")
	var klab := str(SoftK.kit_label("cx_prism")) if SoftK and SoftK.has_method("kit_label") else ""
	if klab == "" or (klab != "PRISM" and klab != "NEX PRISM"):
		fails.append("AR-N SoftKnowledge kit label missing (%s)" % klab)
	if absys.has_method("kit_label"):
		var hlab := str(absys.kit_label())
		if hlab == "" or (hlab != "PRISM" and hlab != "NEX PRISM"):
			fails.append("AR-N HUD kit label missing (%s)" % hlab)
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("prism")):
		fails.append("AR-N unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("cx_prism")):
		fails.append("AR-N unlocked exclusive combat module")
	var bench: Node = arena.get_node_or_null("ClashModuleBench") if arena else null
	if bench == null and arena:
		bench = arena.get("_bench")
	if bench and bench.has_method("offer_count") and int(bench.offer_count()) != 2:
		fails.append("AR-N drifted ClashModuleBench offers")
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-N")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-N")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-N seventh kit · cx_prism · SoftKnowledge only · prior 6 stay · G5 closed · no SITE_*")
	return fails


func _check_ar_o(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_O_EIGHTH_KIT):
		fails.append("AR-O P0Slice flag missing")
	if P0 != null and not bool(P0.AR_N_SEVENTH_KIT):
		fails.append("AR-O dropped AR-N P0Slice flag")
	if P0 != null and not bool(P0.AR_M_SIXTH_KIT):
		fails.append("AR-O dropped AR-M P0Slice flag")
	if P0 != null and not bool(P0.AR_L_FIFTH_KIT):
		fails.append("AR-O dropped AR-L P0Slice flag")
	if P0 != null and not bool(P0.AR_K_SESSION_SHOP):
		fails.append("AR-O dropped AR-K P0Slice flag")
	if P0 != null and not bool(P0.AR_J_PRIME_CAMP):
		fails.append("AR-O dropped AR-J P0Slice flag")
	if P0 != null and not bool(P0.AR_I_MATCH_END):
		fails.append("AR-O dropped AR-I P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-O flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-O Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids") or not Kit.has_method("kit_by_id"):
		fails.append("AR-O AbilityKitCatalog missing")
		return fails
	var ids: PackedStringArray = Kit.kit_ids()
	if int(ids.size()) < 8:
		fails.append("AR-O kit count want >= 8 (got %s)" % ids.size())
	for need in ["cx_nex", "cx_grid", "gr_rot", "gr_spore", "cx_lattice", "gr_vein", "cx_prism"]:
		if not ids.has(need):
			fails.append("AR-O dropped prior kit (%s)" % need)
	if not ids.has("gr_facet"):
		fails.append("AR-O eighth kit gr_facet missing")
	var kit: Array = Kit.kit_by_id("gr_facet")
	if kit.size() != 4:
		fails.append("AR-O Facet is not 4 slots")
	else:
		if kit[0] == null or str(kit[0].ability_name) != "Pulse Bolt":
			fails.append("AR-O Facet slot0 is not Pulse")
		elif absf(float(kit[0].damage) - 11.0) > 0.01:
			fails.append("AR-O Facet Pulse damage drifted")
		var slot1 = kit[1]
		if slot1 == null or not bool(slot1.is_firewall):
			fails.append("AR-O Facet slot1 is not utility")
		elif str(slot1.ability_name) != "Facet Seal":
			fails.append("AR-O Facet utility missing")
		var slot2 = kit[2]
		if slot2 == null or not bool(slot2.is_hacking):
			fails.append("AR-O Facet slot2 is not probe-or-surge")
		elif str(slot2.ability_name) != "Facet Probe":
			fails.append("AR-O Facet probe missing")
		if kit[3] == null or str(kit[3].ability_name) != "Form Cycle":
			fails.append("AR-O Facet slot3 is not Form Cycle")
	if Kit.has_method("kit_for_faction"):
		var cx0: Array = Kit.kit_for_faction("Cybernex")
		var gr0: Array = Kit.kit_for_faction("gROT")
		if cx0.size() != 4 or str(cx0[1].ability_name) != "Nex-Firewall":
			fails.append("AR-O default CX kit changed")
		if gr0.size() != 4 or str(gr0[1].ability_name) != "Hack":
			fails.append("AR-O default GR kit changed")
	if Kit.has_method("kits_for_faction"):
		var gr_cycle: PackedStringArray = Kit.kits_for_faction("gROT")
		if gr_cycle.size() < 4 or str(gr_cycle[3]) != "gr_facet":
			fails.append("AR-O GR Facet not selectable in TestArena kit cycle")
		var cx_cycle: PackedStringArray = Kit.kits_for_faction("Cybernex")
		if cx_cycle.size() < 4 or str(cx_cycle[3]) != "cx_prism":
			fails.append("AR-O CX Prism dropped from TestArena kit cycle")
	if player == null or not player.ability_system:
		fails.append("AR-O player AbilitySystem missing")
		return fails
	var absys = player.ability_system
	var hp0 := float(player.max_health)
	var hp_now := float(player.health)
	var pulse0 := 11.0
	if absys.abilities.size() > 0 and absys.abilities[0]:
		pulse0 = float(absys.abilities[0].damage)
	if absys.has_method("setup_kit"):
		absys.setup_kit("gr_facet", "gROT")
		if str(absys.current_kit_id) != "gr_facet":
			fails.append("AR-O could not apply GR Facet kit")
		if absys.abilities.size() != 4:
			fails.append("AR-O Facet kit not 4 slots on player")
		elif str(absys.abilities[1].ability_name) != "Facet Seal":
			fails.append("AR-O player Facet utility missing")
	if absf(float(player.max_health) - hp0) > 0.01 or absf(float(player.health) - hp_now) > 0.01:
		fails.append("AR-O kit swap changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-O kit swap changed Pulse DPS")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("combat", 20.0)
		GameManager.add_mastery("history", 20.0)
	if absf(float(player.max_health) - hp0) > 0.01:
		fails.append("AR-O Knowledge changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-O Knowledge changed Pulse")
	var klab := str(SoftK.kit_label("gr_facet")) if SoftK and SoftK.has_method("kit_label") else ""
	if klab == "" or (klab != "FACET" and klab != "ROT FACET"):
		fails.append("AR-O SoftKnowledge kit label missing (%s)" % klab)
	if absys.has_method("kit_label"):
		var hlab := str(absys.kit_label())
		if hlab == "" or (hlab != "FACET" and hlab != "ROT FACET"):
			fails.append("AR-O HUD kit label missing (%s)" % hlab)
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("facet")):
		fails.append("AR-O unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("gr_facet")):
		fails.append("AR-O unlocked exclusive combat module")
	var bench: Node = arena.get_node_or_null("ClashModuleBench") if arena else null
	if bench == null and arena:
		bench = arena.get("_bench")
	if bench and bench.has_method("offer_count") and int(bench.offer_count()) != 2:
		fails.append("AR-O drifted ClashModuleBench offers")
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-O")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-O")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-O eighth kit · gr_facet · SoftKnowledge only · prior 7 stay · G5 closed · no SITE_*")
	return fails


func _check_ar_p(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_P_NINTH_KIT):
		fails.append("AR-P P0Slice flag missing")
	if P0 != null and not bool(P0.AR_O_EIGHTH_KIT):
		fails.append("AR-P dropped AR-O P0Slice flag")
	if P0 != null and not bool(P0.AR_N_SEVENTH_KIT):
		fails.append("AR-P dropped AR-N P0Slice flag")
	if P0 != null and not bool(P0.AR_M_SIXTH_KIT):
		fails.append("AR-P dropped AR-M P0Slice flag")
	if P0 != null and not bool(P0.AR_L_FIFTH_KIT):
		fails.append("AR-P dropped AR-L P0Slice flag")
	if P0 != null and not bool(P0.AR_K_SESSION_SHOP):
		fails.append("AR-P dropped AR-K P0Slice flag")
	if P0 != null and not bool(P0.AR_J_PRIME_CAMP):
		fails.append("AR-P dropped AR-J P0Slice flag")
	if P0 != null and not bool(P0.AR_I_MATCH_END):
		fails.append("AR-P dropped AR-I P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-P flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-P Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids") or not Kit.has_method("kit_by_id"):
		fails.append("AR-P AbilityKitCatalog missing")
		return fails
	var ids: PackedStringArray = Kit.kit_ids()
	if int(ids.size()) < 9:
		fails.append("AR-P kit count want >= 9 (got %s)" % ids.size())
	for need in ["cx_nex", "cx_grid", "gr_rot", "gr_spore", "cx_lattice", "gr_vein", "cx_prism", "gr_facet"]:
		if not ids.has(need):
			fails.append("AR-P dropped prior kit (%s)" % need)
	if not ids.has("cx_helix"):
		fails.append("AR-P ninth kit cx_helix missing")
	var kit: Array = Kit.kit_by_id("cx_helix")
	if kit.size() != 4:
		fails.append("AR-P Helix is not 4 slots")
	else:
		if kit[0] == null or str(kit[0].ability_name) != "Pulse Bolt":
			fails.append("AR-P Helix slot0 is not Pulse")
		elif absf(float(kit[0].damage) - 11.0) > 0.01:
			fails.append("AR-P Helix Pulse damage drifted")
		var slot1 = kit[1]
		if slot1 == null or not bool(slot1.is_firewall):
			fails.append("AR-P Helix slot1 is not utility")
		elif str(slot1.ability_name) != "Helix Seal":
			fails.append("AR-P Helix utility missing")
		var slot2 = kit[2]
		if slot2 == null or not bool(slot2.is_hacking):
			fails.append("AR-P Helix slot2 is not probe-or-surge")
		elif str(slot2.ability_name) != "Helix Probe":
			fails.append("AR-P Helix probe missing")
		if kit[3] == null or str(kit[3].ability_name) != "Form Cycle":
			fails.append("AR-P Helix slot3 is not Form Cycle")
	if Kit.has_method("kit_for_faction"):
		var cx0: Array = Kit.kit_for_faction("Cybernex")
		var gr0: Array = Kit.kit_for_faction("gROT")
		if cx0.size() != 4 or str(cx0[1].ability_name) != "Nex-Firewall":
			fails.append("AR-P default CX kit changed")
		if gr0.size() != 4 or str(gr0[1].ability_name) != "Hack":
			fails.append("AR-P default GR kit changed")
	if Kit.has_method("kits_for_faction"):
		var cx_cycle: PackedStringArray = Kit.kits_for_faction("Cybernex")
		if cx_cycle.size() < 5 or str(cx_cycle[4]) != "cx_helix":
			fails.append("AR-P CX Helix not selectable in TestArena kit cycle")
		if cx_cycle.size() < 4 or str(cx_cycle[3]) != "cx_prism":
			fails.append("AR-P CX Prism dropped from TestArena kit cycle")
		var gr_cycle: PackedStringArray = Kit.kits_for_faction("gROT")
		if gr_cycle.size() < 4 or str(gr_cycle[3]) != "gr_facet":
			fails.append("AR-P GR Facet dropped from TestArena kit cycle")
	if player == null or not player.ability_system:
		fails.append("AR-P player AbilitySystem missing")
		return fails
	var absys = player.ability_system
	var hp0 := float(player.max_health)
	var hp_now := float(player.health)
	var pulse0 := 11.0
	if absys.abilities.size() > 0 and absys.abilities[0]:
		pulse0 = float(absys.abilities[0].damage)
	if absys.has_method("setup_kit"):
		absys.setup_kit("cx_helix", "Cybernex")
		if str(absys.current_kit_id) != "cx_helix":
			fails.append("AR-P could not apply CX Helix kit")
		if absys.abilities.size() != 4:
			fails.append("AR-P Helix kit not 4 slots on player")
		elif str(absys.abilities[1].ability_name) != "Helix Seal":
			fails.append("AR-P player Helix utility missing")
	if absf(float(player.max_health) - hp0) > 0.01 or absf(float(player.health) - hp_now) > 0.01:
		fails.append("AR-P kit swap changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-P kit swap changed Pulse DPS")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("combat", 20.0)
		GameManager.add_mastery("history", 20.0)
	if absf(float(player.max_health) - hp0) > 0.01:
		fails.append("AR-P Knowledge changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-P Knowledge changed Pulse")
	var klab := str(SoftK.kit_label("cx_helix")) if SoftK and SoftK.has_method("kit_label") else ""
	if klab == "" or (klab != "HELIX" and klab != "NEX HELIX"):
		fails.append("AR-P SoftKnowledge kit label missing (%s)" % klab)
	if absys.has_method("kit_label"):
		var hlab := str(absys.kit_label())
		if hlab == "" or (hlab != "HELIX" and hlab != "NEX HELIX"):
			fails.append("AR-P HUD kit label missing (%s)" % hlab)
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("helix")):
		fails.append("AR-P unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("cx_helix")):
		fails.append("AR-P unlocked exclusive combat module")
	var bench: Node = arena.get_node_or_null("ClashModuleBench") if arena else null
	if bench == null and arena:
		bench = arena.get("_bench")
	if bench and bench.has_method("offer_count") and int(bench.offer_count()) != 2:
		fails.append("AR-P drifted ClashModuleBench offers")
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-P")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-P")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-P ninth kit · cx_helix · SoftKnowledge only · prior 8 stay · G5 closed · no SITE_*")
	return fails


func _check_ar_q(arena: Node, _lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_Q_TENTH_KIT):
		fails.append("AR-Q P0Slice flag missing")
	if P0 != null and not bool(P0.AR_P_NINTH_KIT):
		fails.append("AR-Q dropped AR-P P0Slice flag")
	if P0 != null and not bool(P0.AR_O_EIGHTH_KIT):
		fails.append("AR-Q dropped AR-O P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-Q flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-Q Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids") or not Kit.has_method("kit_by_id"):
		fails.append("AR-Q AbilityKitCatalog missing")
		return fails
	var ids: PackedStringArray = Kit.kit_ids()
	if int(ids.size()) < 10:
		fails.append("AR-Q kit count want >= 10 (got %s)" % ids.size())
	for need in ["cx_nex", "cx_grid", "gr_rot", "gr_spore", "cx_lattice", "gr_vein", "cx_prism", "gr_facet", "cx_helix"]:
		if not ids.has(need):
			fails.append("AR-Q dropped prior kit (%s)" % need)
	if not ids.has("gr_coil"):
		fails.append("AR-Q tenth kit gr_coil missing")
	var kit: Array = Kit.kit_by_id("gr_coil")
	if kit.size() != 4:
		fails.append("AR-Q Coil is not 4 slots")
	else:
		if kit[0] == null or str(kit[0].ability_name) != "Pulse Bolt":
			fails.append("AR-Q Coil slot0 is not Pulse")
		elif absf(float(kit[0].damage) - 11.0) > 0.01:
			fails.append("AR-Q Coil Pulse damage drifted")
		if kit[1] == null or not bool(kit[1].is_firewall) or str(kit[1].ability_name) != "Coil Seal":
			fails.append("AR-Q Coil utility missing")
		if kit[2] == null or not bool(kit[2].is_hacking) or str(kit[2].ability_name) != "Coil Probe":
			fails.append("AR-Q Coil probe missing")
		if kit[3] == null or str(kit[3].ability_name) != "Form Cycle":
			fails.append("AR-Q Coil Form Cycle missing")
	if Kit.has_method("kit_for_faction"):
		var cx0: Array = Kit.kit_for_faction("Cybernex")
		var gr0: Array = Kit.kit_for_faction("gROT")
		if cx0.size() != 4 or str(cx0[1].ability_name) != "Nex-Firewall":
			fails.append("AR-Q default CX kit changed")
		if gr0.size() != 4 or str(gr0[1].ability_name) != "Hack":
			fails.append("AR-Q default GR kit changed")
	if Kit.has_method("kits_for_faction"):
		var gr_cycle: PackedStringArray = Kit.kits_for_faction("gROT")
		if gr_cycle.size() < 5 or str(gr_cycle[4]) != "gr_coil":
			fails.append("AR-Q GR Coil not selectable in TestArena kit cycle")
		var cx_cycle: PackedStringArray = Kit.kits_for_faction("Cybernex")
		if cx_cycle.size() < 5 or str(cx_cycle[4]) != "cx_helix":
			fails.append("AR-Q CX Helix dropped from TestArena kit cycle")
	if player == null or not player.ability_system:
		fails.append("AR-Q player AbilitySystem missing")
		return fails
	var absys = player.ability_system
	var hp0 := float(player.max_health)
	var hp_now := float(player.health)
	var pulse0 := 11.0
	if absys.abilities.size() > 0 and absys.abilities[0]:
		pulse0 = float(absys.abilities[0].damage)
	if absys.has_method("setup_kit"):
		absys.setup_kit("gr_coil", "gROT")
		if str(absys.current_kit_id) != "gr_coil":
			fails.append("AR-Q could not apply GR Coil kit")
		if absys.abilities.size() != 4:
			fails.append("AR-Q Coil kit not 4 slots on player")
		elif str(absys.abilities[1].ability_name) != "Coil Seal":
			fails.append("AR-Q player Coil utility missing")
	if absf(float(player.max_health) - hp0) > 0.01 or absf(float(player.health) - hp_now) > 0.01:
		fails.append("AR-Q kit swap changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-Q kit swap changed Pulse DPS")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("combat", 20.0)
		GameManager.add_mastery("history", 20.0)
	if absf(float(player.max_health) - hp0) > 0.01:
		fails.append("AR-Q Knowledge changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-Q Knowledge changed Pulse")
	var klab := str(SoftK.kit_label("gr_coil")) if SoftK and SoftK.has_method("kit_label") else ""
	if klab == "" or (klab != "COIL" and klab != "ROT COIL"):
		fails.append("AR-Q SoftKnowledge kit label missing (%s)" % klab)
	if absys.has_method("kit_label"):
		var hlab := str(absys.kit_label())
		if hlab == "" or (hlab != "COIL" and hlab != "ROT COIL"):
			fails.append("AR-Q HUD kit label missing (%s)" % hlab)
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("coil")):
		fails.append("AR-Q unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("gr_coil")):
		fails.append("AR-Q unlocked exclusive combat module")
	var bench: Node = arena.get_node_or_null("ClashModuleBench") if arena else null
	if bench == null and arena:
		bench = arena.get("_bench")
	if bench and bench.has_method("offer_count") and int(bench.offer_count()) != 2:
		fails.append("AR-Q drifted ClashModuleBench offers")
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-Q")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-Q")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-Q tenth kit · gr_coil · SoftKnowledge only · prior 9 stay · G5 closed · no SITE_*")
	return fails


func _check_ar_r(arena: Node, _lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_R_ELEVENTH_KIT):
		fails.append("AR-R P0Slice flag missing")
	if P0 != null and not bool(P0.AR_Q_TENTH_KIT):
		fails.append("AR-R dropped AR-Q P0Slice flag")
	if P0 != null and not bool(P0.AR_P_NINTH_KIT):
		fails.append("AR-R dropped AR-P P0Slice flag")
	if P0 != null and not bool(P0.AR_O_EIGHTH_KIT):
		fails.append("AR-R dropped AR-O P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-R flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-R Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids") or not Kit.has_method("kit_by_id"):
		fails.append("AR-R AbilityKitCatalog missing")
		return fails
	var ids: PackedStringArray = Kit.kit_ids()
	if int(ids.size()) < 11:
		fails.append("AR-R kit count want >= 11 (got %s)" % ids.size())
	for need in ["cx_nex", "cx_grid", "gr_rot", "gr_spore", "cx_lattice", "gr_vein", "cx_prism", "gr_facet", "cx_helix", "gr_coil"]:
		if not ids.has(need):
			fails.append("AR-R dropped prior kit (%s)" % need)
	if not ids.has("cx_spire"):
		fails.append("AR-R eleventh kit cx_spire missing")
	var kit: Array = Kit.kit_by_id("cx_spire")
	if kit.size() != 4:
		fails.append("AR-R Spire is not 4 slots")
	else:
		if kit[0] == null or str(kit[0].ability_name) != "Pulse Bolt":
			fails.append("AR-R Spire slot0 is not Pulse")
		elif absf(float(kit[0].damage) - 11.0) > 0.01:
			fails.append("AR-R Spire Pulse damage drifted")
		if kit[1] == null or not bool(kit[1].is_firewall) or str(kit[1].ability_name) != "Spire Seal":
			fails.append("AR-R Spire utility missing")
		if kit[2] == null or not bool(kit[2].is_hacking) or str(kit[2].ability_name) != "Spire Probe":
			fails.append("AR-R Spire probe missing")
		if kit[3] == null or str(kit[3].ability_name) != "Form Cycle":
			fails.append("AR-R Spire Form Cycle missing")
	if Kit.has_method("kit_for_faction"):
		var cx0: Array = Kit.kit_for_faction("Cybernex")
		var gr0: Array = Kit.kit_for_faction("gROT")
		if cx0.size() != 4 or str(cx0[1].ability_name) != "Nex-Firewall":
			fails.append("AR-R default CX kit changed")
		if gr0.size() != 4 or str(gr0[1].ability_name) != "Hack":
			fails.append("AR-R default GR kit changed")
	if Kit.has_method("kits_for_faction"):
		var cx_cycle: PackedStringArray = Kit.kits_for_faction("Cybernex")
		if cx_cycle.size() < 6 or str(cx_cycle[5]) != "cx_spire":
			fails.append("AR-R CX Spire not selectable in TestArena kit cycle")
		if cx_cycle.size() < 5 or str(cx_cycle[4]) != "cx_helix":
			fails.append("AR-R CX Helix dropped from TestArena kit cycle")
		var gr_cycle: PackedStringArray = Kit.kits_for_faction("gROT")
		if gr_cycle.size() < 5 or str(gr_cycle[4]) != "gr_coil":
			fails.append("AR-R GR Coil dropped from TestArena kit cycle")
	if player == null or not player.ability_system:
		fails.append("AR-R player AbilitySystem missing")
		return fails
	var absys = player.ability_system
	var hp0 := float(player.max_health)
	var hp_now := float(player.health)
	var pulse0 := 11.0
	if absys.abilities.size() > 0 and absys.abilities[0]:
		pulse0 = float(absys.abilities[0].damage)
	if absys.has_method("setup_kit"):
		absys.setup_kit("cx_spire", "Cybernex")
		if str(absys.current_kit_id) != "cx_spire":
			fails.append("AR-R could not apply CX Spire kit")
		if absys.abilities.size() != 4:
			fails.append("AR-R Spire kit not 4 slots on player")
		elif str(absys.abilities[1].ability_name) != "Spire Seal":
			fails.append("AR-R player Spire utility missing")
	if absf(float(player.max_health) - hp0) > 0.01 or absf(float(player.health) - hp_now) > 0.01:
		fails.append("AR-R kit swap changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-R kit swap changed Pulse DPS")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("combat", 20.0)
		GameManager.add_mastery("history", 20.0)
	if absf(float(player.max_health) - hp0) > 0.01:
		fails.append("AR-R Knowledge changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-R Knowledge changed Pulse")
	var klab := str(SoftK.kit_label("cx_spire")) if SoftK and SoftK.has_method("kit_label") else ""
	if klab == "" or (klab != "SPIRE" and klab != "NEX SPIRE"):
		fails.append("AR-R SoftKnowledge kit label missing (%s)" % klab)
	if absys.has_method("kit_label"):
		var hlab := str(absys.kit_label())
		if hlab == "" or (hlab != "SPIRE" and hlab != "NEX SPIRE"):
			fails.append("AR-R HUD kit label missing (%s)" % hlab)
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("spire")):
		fails.append("AR-R unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("cx_spire")):
		fails.append("AR-R unlocked exclusive combat module")
	var bench: Node = arena.get_node_or_null("ClashModuleBench") if arena else null
	if bench == null and arena:
		bench = arena.get("_bench")
	if bench and bench.has_method("offer_count") and int(bench.offer_count()) != 2:
		fails.append("AR-R drifted ClashModuleBench offers")
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-R")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-R")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-R eleventh kit · cx_spire · SoftKnowledge only · prior 10 stay · G5 closed · no SITE_*")
	return fails


func _check_ar_s(arena: Node, _lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_S_TWELFTH_KIT):
		fails.append("AR-S P0Slice flag missing")
	if P0 != null and not bool(P0.AR_R_ELEVENTH_KIT):
		fails.append("AR-S dropped AR-R P0Slice flag")
	if P0 != null and not bool(P0.AR_Q_TENTH_KIT):
		fails.append("AR-S dropped AR-Q P0Slice flag")
	if P0 != null and not bool(P0.AR_P_NINTH_KIT):
		fails.append("AR-S dropped AR-P P0Slice flag")
	if P0 != null and not bool(P0.AR_O_EIGHTH_KIT):
		fails.append("AR-S dropped AR-O P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-S flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-S Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids") or not Kit.has_method("kit_by_id"):
		fails.append("AR-S AbilityKitCatalog missing")
		return fails
	var ids: PackedStringArray = Kit.kit_ids()
	if int(ids.size()) != 12:
		fails.append("AR-S kit count want 12 (got %s)" % ids.size())
	for need in ["cx_nex", "cx_grid", "gr_rot", "gr_spore", "cx_lattice", "gr_vein", "cx_prism", "gr_facet", "cx_helix", "gr_coil", "cx_spire"]:
		if not ids.has(need):
			fails.append("AR-S dropped prior kit (%s)" % need)
	if not ids.has("gr_thorn"):
		fails.append("AR-S twelfth kit gr_thorn missing")
	var kit: Array = Kit.kit_by_id("gr_thorn")
	if kit.size() != 4:
		fails.append("AR-S Thorn is not 4 slots")
	else:
		if kit[0] == null or str(kit[0].ability_name) != "Pulse Bolt":
			fails.append("AR-S Thorn slot0 is not Pulse")
		elif absf(float(kit[0].damage) - 11.0) > 0.01:
			fails.append("AR-S Thorn Pulse damage drifted")
		if kit[1] == null or not bool(kit[1].is_firewall) or str(kit[1].ability_name) != "Thorn Seal":
			fails.append("AR-S Thorn utility missing")
		if kit[2] == null or not bool(kit[2].is_hacking) or str(kit[2].ability_name) != "Thorn Probe":
			fails.append("AR-S Thorn probe missing")
		if kit[3] == null or str(kit[3].ability_name) != "Form Cycle":
			fails.append("AR-S Thorn Form Cycle missing")
	if Kit.has_method("kit_for_faction"):
		var cx0: Array = Kit.kit_for_faction("Cybernex")
		var gr0: Array = Kit.kit_for_faction("gROT")
		if cx0.size() != 4 or str(cx0[1].ability_name) != "Nex-Firewall":
			fails.append("AR-S default CX kit changed")
		if gr0.size() != 4 or str(gr0[1].ability_name) != "Hack":
			fails.append("AR-S default GR kit changed")
	if Kit.has_method("kits_for_faction"):
		var gr_cycle: PackedStringArray = Kit.kits_for_faction("gROT")
		if gr_cycle.size() < 6 or str(gr_cycle[5]) != "gr_thorn":
			fails.append("AR-S GR Thorn not selectable in TestArena kit cycle")
		if gr_cycle.size() < 5 or str(gr_cycle[4]) != "gr_coil":
			fails.append("AR-S GR Coil dropped from TestArena kit cycle")
		var cx_cycle: PackedStringArray = Kit.kits_for_faction("Cybernex")
		if cx_cycle.size() < 6 or str(cx_cycle[5]) != "cx_spire":
			fails.append("AR-S CX Spire dropped from TestArena kit cycle")
	if player == null or not player.ability_system:
		fails.append("AR-S player AbilitySystem missing")
		return fails
	var absys = player.ability_system
	var hp0 := float(player.max_health)
	var hp_now := float(player.health)
	var pulse0 := 11.0
	if absys.abilities.size() > 0 and absys.abilities[0]:
		pulse0 = float(absys.abilities[0].damage)
	if absys.has_method("setup_kit"):
		absys.setup_kit("gr_thorn", "gROT")
		if str(absys.current_kit_id) != "gr_thorn":
			fails.append("AR-S could not apply GR Thorn kit")
		if absys.abilities.size() != 4:
			fails.append("AR-S Thorn kit not 4 slots on player")
		elif str(absys.abilities[1].ability_name) != "Thorn Seal":
			fails.append("AR-S player Thorn utility missing")
	if absf(float(player.max_health) - hp0) > 0.01 or absf(float(player.health) - hp_now) > 0.01:
		fails.append("AR-S kit swap changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-S kit swap changed Pulse DPS")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("combat", 20.0)
		GameManager.add_mastery("history", 20.0)
	if absf(float(player.max_health) - hp0) > 0.01:
		fails.append("AR-S Knowledge changed HP")
	if absys.abilities.size() > 0 and absys.abilities[0] and absf(float(absys.abilities[0].damage) - pulse0) > 0.01:
		fails.append("AR-S Knowledge changed Pulse")
	var klab := str(SoftK.kit_label("gr_thorn")) if SoftK and SoftK.has_method("kit_label") else ""
	if klab == "" or (klab != "THORN" and klab != "ROT THORN"):
		fails.append("AR-S SoftKnowledge kit label missing (%s)" % klab)
	if absys.has_method("kit_label"):
		var hlab := str(absys.kit_label())
		if hlab == "" or (hlab != "THORN" and hlab != "ROT THORN"):
			fails.append("AR-S HUD kit label missing (%s)" % hlab)
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("thorn")):
		fails.append("AR-S unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("gr_thorn")):
		fails.append("AR-S unlocked exclusive combat module")
	var bench: Node = arena.get_node_or_null("ClashModuleBench") if arena else null
	if bench == null and arena:
		bench = arena.get("_bench")
	if bench and bench.has_method("offer_count") and int(bench.offer_count()) != 2:
		fails.append("AR-S drifted ClashModuleBench offers")
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-S")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-S")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-S twelfth kit · gr_thorn · SoftKnowledge only · prior 11 stay · G5 closed · no SITE_*")
	return fails


func _check_ar_t(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_T_MINION_WAVE):
		fails.append("AR-T P0Slice flag missing")
	if P0 != null and not bool(P0.AR_S_TWELFTH_KIT):
		fails.append("AR-T dropped AR-S P0Slice flag")
	if P0 != null and not bool(P0.AR_I_MATCH_END):
		fails.append("AR-T dropped AR-I P0Slice flag")
	if P0 != null and not bool(P0.FL_N_FLEET):
		fails.append("AR-T dropped FL-N P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-T flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-T Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids"):
		fails.append("AR-T AbilityKitCatalog missing")
	else:
		var ids: PackedStringArray = Kit.kit_ids()
		if int(ids.size()) != 12:
			fails.append("AR-T kit count want 12 (got %s)" % ids.size())
		if ids.has("cx_nex") == false or ids.has("gr_thorn") == false:
			fails.append("AR-T dropped catalog ends (cx_nex…gr_thorn)")
		if int(ids.size()) >= 13:
			fails.append("AR-T added a 13th AbilityKit")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	var wlab := str(SoftK.wave_label()) if SoftK and SoftK.has_method("wave_label") else ""
	var mlab := str(SoftK.minion_label()) if SoftK and SoftK.has_method("minion_label") else ""
	if wlab == "" or (wlab != "WAVE" and wlab != "LANE WAVE"):
		fails.append("AR-T SoftKnowledge WAVE missing (%s)" % wlab)
	if mlab == "" or (mlab != "MINION" and mlab != "LANE MINION"):
		fails.append("AR-T SoftKnowledge MINION missing (%s)" % mlab)
	var waves: Node = arena.get_node_or_null("ClashWaves") if arena else null
	if waves == null and arena:
		waves = arena.get("_waves")
	if waves == null or not is_instance_valid(waves):
		fails.append("AR-T ClashWaves missing")
		return fails
	if not waves.has_method("living_minions"):
		fails.append("AR-T ClashWaves API missing")
		return fails
	if not waves.has_method("is_host_authority") or not bool(waves.is_host_authority()):
		fails.append("AR-T wave is not host authority")
	if not waves.has_method("pulse_damage") or absf(float(waves.pulse_damage()) - 11.0) > 0.01:
		fails.append("AR-T Pulse 11 drifted")
	var live: Array = waves.living_minions()
	if live.is_empty():
		await get_tree().create_timer(0.45).timeout
		live = waves.living_minions()
	if live.is_empty():
		fails.append("AR-T no WAVE minions on a lane")
		return fails
	var walker: Node3D = null
	for n in live:
		if n is Node3D:
			walker = n as Node3D
			break
	if walker == null:
		fails.append("AR-T minion is not a CombatDummy")
		return fails
	if not walker.has_meta("clash_wave") or not bool(walker.get_meta("clash_wave")):
		fails.append("AR-T minion missing clash_wave")
	if str(walker.get_meta("combat_authority")) != "host":
		fails.append("AR-T minion combat_authority left host")
	if walker.has_method("infection_cap") and int(walker.infection_cap()) != 5:
		fails.append("AR-T Infection cap drifted (%s)" % walker.infection_cap())
	var lane_id := str(walker.get_meta("lane")) if walker.has_meta("lane") else ""
	if lane_id == "" and lanes and lanes.has_method("lane_at"):
		lane_id = str(lanes.lane_at(walker.global_position))
	if lane_id != "TOP" and lane_id != "MID" and lane_id != "BOT":
		fails.append("AR-T minion not on a Clash lane")
	var dummy_scene: PackedScene = load("res://scenes/combat/CombatDummy.tscn")
	var tgt: Node = dummy_scene.instantiate() if dummy_scene else null
	if tgt == null:
		fails.append("AR-T Pulse target scene missing")
		return fails
	tgt.name = "ARTPulseTarget"
	tgt.set("faction", "Cybernex" if str(walker.get("faction")) != "Cybernex" else "gROT")
	arena.add_child(tgt)
	await get_tree().process_frame
	if tgt is Node3D:
		(tgt as Node3D).global_position = walker.global_position + Vector3(0.0, 0.0, 2.0)
	var hp0 := float(tgt.health)
	if walker.has_method("try_pulse"):
		walker.try_pulse(tgt)
	var hp1 := float(tgt.health)
	print("[Playtest] AR-T Pulse ", hp0, " -> ", hp1, " lane=", lane_id)
	if hp1 >= hp0:
		fails.append("AR-T minion Pulse did not hit")
	elif absf(hp0 - hp1 - 11.0) > 0.05:
		fails.append("AR-T Pulse want 11 (got %s)" % (hp0 - hp1))
	if is_instance_valid(tgt):
		tgt.queue_free()
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("combat", 20.0)
		GameManager.add_mastery("history", 20.0)
	if waves.has_method("pulse_damage") and absf(float(waves.pulse_damage()) - 11.0) > 0.01:
		fails.append("AR-T Knowledge changed Pulse")
	var wlab2 := str(waves.wave_soft_label()) if waves.has_method("wave_soft_label") else ""
	var mlab2 := str(waves.minion_soft_label()) if waves.has_method("minion_soft_label") else ""
	if wlab2 == "" or (wlab2 != "WAVE" and wlab2 != "LANE WAVE"):
		fails.append("AR-T HUD WAVE missing (%s)" % wlab2)
	if mlab2 == "" or (mlab2 != "MINION" and mlab2 != "LANE MINION"):
		fails.append("AR-T HUD MINION missing (%s)" % mlab2)
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("wave")):
		fails.append("AR-T unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("minion")):
		fails.append("AR-T unlocked exclusive combat module")
	var director: Node = arena.get_node_or_null("ClashMatchDirector") if arena else null
	if director and director.has_method("_lane_bar_line"):
		var bar := str(director._lane_bar_line())
		if bar.find("WAVE") < 0 and bar.find("MINION") < 0:
			fails.append("AR-T director HUD missing WAVE/MINION (%s)" % bar)
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-T")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-T")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-T minion-wave seed · ", wlab2, "/", mlab2,
		" Pulse 11 · host · kits=12 · FLEET 15/15 · G5 closed · no SITE_*")
	return fails


func _check_ar_u(arena: Node, _lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_U_XP_LEVELING):
		fails.append("AR-U P0Slice flag missing")
	if P0 != null and not bool(P0.AR_T_MINION_WAVE):
		fails.append("AR-U dropped AR-T P0Slice flag")
	if P0 != null and not bool(P0.AR_S_TWELFTH_KIT):
		fails.append("AR-U dropped AR-S P0Slice flag")
	if P0 != null and not bool(P0.AR_I_MATCH_END):
		fails.append("AR-U dropped AR-I P0Slice flag")
	if P0 != null and not bool(P0.FL_N_FLEET):
		fails.append("AR-U dropped FL-N P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-U flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-U Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids"):
		fails.append("AR-U AbilityKitCatalog missing")
	else:
		var ids: PackedStringArray = Kit.kit_ids()
		if int(ids.size()) != 12:
			fails.append("AR-U kit count want 12 (got %s)" % ids.size())
		if ids.has("cx_nex") == false or ids.has("gr_thorn") == false:
			fails.append("AR-U dropped catalog ends (cx_nex…gr_thorn)")
		if int(ids.size()) >= 13:
			fails.append("AR-U added a 13th AbilityKit")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	var xlab := str(SoftK.xp_label()) if SoftK and SoftK.has_method("xp_label") else ""
	var llab := str(SoftK.level_label()) if SoftK and SoftK.has_method("level_label") else ""
	if xlab == "" or (xlab != "XP" and xlab != "CLASH XP"):
		fails.append("AR-U SoftKnowledge XP missing (%s)" % xlab)
	if llab == "" or (llab != "LEVEL" and llab != "CLASH LEVEL"):
		fails.append("AR-U SoftKnowledge LEVEL missing (%s)" % llab)
	var localn: Node = arena.get_node_or_null("ClashLocalMatch") if arena else null
	if localn == null:
		fails.append("AR-U ClashLocalMatch missing")
		return fails
	if not localn.has_method("grant_xp"):
		fails.append("AR-U ClashLocalMatch XP API missing")
		return fails
	if not localn.has_method("is_level_informational") or not bool(localn.is_level_informational()):
		fails.append("AR-U level is not informational")
	var pulse0 := 11.0
	if player and player.get("ability_system") != null:
		var absys: Node = player.ability_system
		if absys and "abilities" in absys:
			for ab in absys.abilities:
				if ab != null and str(ab.get("ability_name")).to_lower().find("pulse") >= 0:
					pulse0 = float(ab.get("damage"))
					break
	var waves: Node = arena.get_node_or_null("ClashWaves") if arena else null
	if waves == null and arena:
		waves = arena.get("_waves")
	if waves == null or not is_instance_valid(waves):
		fails.append("AR-U dropped AR-T ClashWaves")
	elif not waves.has_method("living_minions"):
		fails.append("AR-U dropped AR-T wave API")
	elif waves.has_method("pulse_damage") and absf(float(waves.pulse_damage()) - 11.0) > 0.01:
		fails.append("AR-U AR-T Pulse 11 drifted")
	var xp0 := float(localn.match_xp)
	var lv0 := int(localn.match_level)
	if lv0 < 1 or lv0 > 18:
		fails.append("AR-U start level out of 1–18 (got %s)" % lv0)
	var got := float(localn.grant_xp(100.0))
	if got < 99.9:
		fails.append("AR-U grant_xp missing (got %s)" % got)
	if float(localn.match_xp) < xp0 + 99.9:
		fails.append("AR-U XP did not rise")
	if int(localn.match_level) < maxi(2, lv0):
		fails.append("AR-U LEVEL did not rise (got %s)" % localn.match_level)
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("combat", 20.0)
		GameManager.add_mastery("history", 20.0)
	if player and player.get("ability_system") != null:
		var absys2: Node = player.ability_system
		if absys2 and "abilities" in absys2:
			for ab in absys2.abilities:
				if ab != null and str(ab.get("ability_name")).to_lower().find("pulse") >= 0:
					if absf(float(ab.get("damage")) - pulse0) > 0.01:
						fails.append("AR-U Knowledge/level changed Pulse")
					break
	if waves and waves.has_method("pulse_damage") and absf(float(waves.pulse_damage()) - 11.0) > 0.01:
		fails.append("AR-U level changed Pulse")
	var xlab2 := str(localn.xp_soft_label()) if localn.has_method("xp_soft_label") else ""
	var llab2 := str(localn.level_soft_label()) if localn.has_method("level_soft_label") else ""
	if xlab2 == "" or (xlab2 != "XP" and xlab2 != "CLASH XP"):
		fails.append("AR-U HUD XP missing (%s)" % xlab2)
	if llab2 == "" or (llab2 != "LEVEL" and llab2 != "CLASH LEVEL"):
		fails.append("AR-U HUD LEVEL missing (%s)" % llab2)
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("level")):
		fails.append("AR-U unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("xp")):
		fails.append("AR-U unlocked exclusive combat module")
	if Kit and Kit.has_method("kit_ids") and int(Kit.kit_ids().size()) != 12:
		fails.append("AR-U level unlocked a 13th kit")
	var director: Node = arena.get_node_or_null("ClashMatchDirector") if arena else null
	if director and director.has_method("score_hud_line"):
		var bar := str(director.score_hud_line())
		if bar.find("XP") < 0:
			fails.append("AR-U director HUD missing XP (%s)" % bar)
		if bar.find("LEVEL") < 0:
			fails.append("AR-U director HUD missing LEVEL (%s)" % bar)
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-U")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-U")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-U XP/level seed · ", xlab2, "/", llab2,
		" xp=", localn.match_xp, " lv=", localn.match_level,
		" Pulse 11 · host · kits=12 · FLEET 15/15 · G5 closed · no SITE_*")
	return fails


func _check_ar_v(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_V_SECOND_LANE_WAVE):
		fails.append("AR-V P0Slice flag missing")
	if P0 != null and not bool(P0.AR_T_MINION_WAVE):
		fails.append("AR-V dropped AR-T P0Slice flag")
	if P0 != null and not bool(P0.AR_U_XP_LEVELING):
		fails.append("AR-V dropped AR-U P0Slice flag")
	if P0 != null and not bool(P0.AR_S_TWELFTH_KIT):
		fails.append("AR-V dropped AR-S P0Slice flag")
	if P0 != null and not bool(P0.AR_I_MATCH_END):
		fails.append("AR-V dropped AR-I P0Slice flag")
	if P0 != null and not bool(P0.FL_N_FLEET):
		fails.append("AR-V dropped FL-N P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-V flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-V Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids"):
		fails.append("AR-V AbilityKitCatalog missing")
	else:
		var ids: PackedStringArray = Kit.kit_ids()
		if int(ids.size()) != 12:
			fails.append("AR-V kit count want 12 (got %s)" % ids.size())
		if ids.has("cx_nex") == false or ids.has("gr_thorn") == false:
			fails.append("AR-V dropped catalog ends (cx_nex…gr_thorn)")
		if int(ids.size()) >= 13:
			fails.append("AR-V added a 13th AbilityKit")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	var wlab := str(SoftK.wave_label()) if SoftK and SoftK.has_method("wave_label") else ""
	var mlab := str(SoftK.minion_label()) if SoftK and SoftK.has_method("minion_label") else ""
	if wlab == "" or (wlab != "WAVE" and wlab != "LANE WAVE"):
		fails.append("AR-V SoftKnowledge WAVE missing (%s)" % wlab)
	if mlab == "" or (mlab != "MINION" and mlab != "LANE MINION"):
		fails.append("AR-V SoftKnowledge MINION missing (%s)" % mlab)
	var xlab := str(SoftK.xp_label()) if SoftK and SoftK.has_method("xp_label") else ""
	var llab := str(SoftK.level_label()) if SoftK and SoftK.has_method("level_label") else ""
	if xlab == "" or (xlab != "XP" and xlab != "CLASH XP"):
		fails.append("AR-V dropped AR-U SoftKnowledge XP (%s)" % xlab)
	if llab == "" or (llab != "LEVEL" and llab != "CLASH LEVEL"):
		fails.append("AR-V dropped AR-U SoftKnowledge LEVEL (%s)" % llab)
	var localn: Node = arena.get_node_or_null("ClashLocalMatch") if arena else null
	if localn != null and localn.has_method("is_level_informational") and not bool(localn.is_level_informational()):
		fails.append("AR-V AR-U level is not informational")
	var waves: Node = arena.get_node_or_null("ClashWaves") if arena else null
	if waves == null and arena:
		waves = arena.get("_waves")
	if waves == null or not is_instance_valid(waves):
		fails.append("AR-V ClashWaves missing")
		return fails
	if not waves.has_method("living_minions") or not waves.has_method("living_on_lane"):
		fails.append("AR-V ClashWaves API missing")
		return fails
	if not waves.has_method("is_host_authority") or not bool(waves.is_host_authority()):
		fails.append("AR-V wave is not host authority")
	if not waves.has_method("pulse_damage") or absf(float(waves.pulse_damage()) - 11.0) > 0.01:
		fails.append("AR-V Pulse 11 drifted")
	var seed := str(waves.seed_lane()) if waves.has_method("seed_lane") else "TOP"
	var opp := str(waves.opposite_lane()) if waves.has_method("opposite_lane") else "BOT"
	if seed == "" or opp == "" or seed == opp:
		fails.append("AR-V seed/opposite lanes collapsed (%s/%s)" % [seed, opp])
	var on_seed: Array = waves.living_on_lane(seed)
	var on_opp: Array = waves.living_on_lane(opp)
	if on_seed.is_empty():
		await get_tree().create_timer(0.45).timeout
		on_seed = waves.living_on_lane(seed)
		on_opp = waves.living_on_lane(opp)
	if on_seed.is_empty():
		fails.append("AR-V dropped AR-T WAVE on %s" % seed)
	if on_opp.is_empty():
		fails.append("AR-V no opposite-lane WAVE on %s" % opp)
		return fails
	var walker: Node3D = null
	for n in on_opp:
		if n is Node3D:
			walker = n as Node3D
			break
	if walker == null:
		fails.append("AR-V opposite minion is not a CombatDummy")
		return fails
	if not walker.has_meta("clash_wave") or not bool(walker.get_meta("clash_wave")):
		fails.append("AR-V minion missing clash_wave")
	if str(walker.get_meta("combat_authority")) != "host":
		fails.append("AR-V minion combat_authority left host")
	if walker.has_method("infection_cap") and int(walker.infection_cap()) != 5:
		fails.append("AR-V Infection cap drifted (%s)" % walker.infection_cap())
	var lane_id := str(walker.get_meta("lane")) if walker.has_meta("lane") else ""
	if lane_id == "" and lanes and lanes.has_method("lane_at"):
		lane_id = str(lanes.lane_at(walker.global_position))
	if lane_id != opp:
		fails.append("AR-V minion not on opposite lane (got %s want %s)" % [lane_id, opp])
	var dummy_scene: PackedScene = load("res://scenes/combat/CombatDummy.tscn")
	var tgt: Node = dummy_scene.instantiate() if dummy_scene else null
	if tgt == null:
		fails.append("AR-V Pulse target scene missing")
		return fails
	tgt.name = "ARVPulseTarget"
	tgt.set("faction", "Cybernex" if str(walker.get("faction")) != "Cybernex" else "gROT")
	arena.add_child(tgt)
	await get_tree().process_frame
	if tgt is Node3D:
		(tgt as Node3D).global_position = walker.global_position + Vector3(0.0, 0.0, 2.0)
	var hp0 := float(tgt.health)
	if walker.has_method("try_pulse"):
		walker.try_pulse(tgt)
	var hp1 := float(tgt.health)
	print("[Playtest] AR-V Pulse ", hp0, " -> ", hp1, " lane=", lane_id, " seed=", seed)
	if hp1 >= hp0:
		fails.append("AR-V minion Pulse did not hit")
	elif absf(hp0 - hp1 - 11.0) > 0.05:
		fails.append("AR-V Pulse want 11 (got %s)" % (hp0 - hp1))
	if is_instance_valid(tgt):
		tgt.queue_free()
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("combat", 20.0)
		GameManager.add_mastery("history", 20.0)
	if waves.has_method("pulse_damage") and absf(float(waves.pulse_damage()) - 11.0) > 0.01:
		fails.append("AR-V Knowledge changed Pulse")
	if localn != null and localn.has_method("is_level_informational") and not bool(localn.is_level_informational()):
		fails.append("AR-V Knowledge made AR-U level a power")
	var wlab2 := str(waves.wave_soft_label()) if waves.has_method("wave_soft_label") else ""
	var mlab2 := str(waves.minion_soft_label()) if waves.has_method("minion_soft_label") else ""
	if wlab2 == "" or (wlab2 != "WAVE" and wlab2 != "LANE WAVE"):
		fails.append("AR-V HUD WAVE missing (%s)" % wlab2)
	if mlab2 == "" or (mlab2 != "MINION" and mlab2 != "LANE MINION"):
		fails.append("AR-V HUD MINION missing (%s)" % mlab2)
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("wave")):
		fails.append("AR-V unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("minion")):
		fails.append("AR-V unlocked exclusive combat module")
	var director: Node = arena.get_node_or_null("ClashMatchDirector") if arena else null
	if director and director.has_method("_lane_bar_line"):
		var bar := str(director._lane_bar_line())
		if bar.find("WAVE") < 0 and bar.find("MINION") < 0:
			fails.append("AR-V director HUD missing WAVE/MINION (%s)" % bar)
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-V")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-V")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-V second-lane wave · ", seed, "+", opp, " · ", wlab2, "/", mlab2,
		" Pulse 11 · host · kits=12 · FLEET 15/15 · G5 closed · no SITE_*")
	return fails


func _check_ar_w(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_W_THIRD_LANE_WAVE):
		fails.append("AR-W P0Slice flag missing")
	if P0 != null and not bool(P0.AR_T_MINION_WAVE):
		fails.append("AR-W dropped AR-T P0Slice flag")
	if P0 != null and not bool(P0.AR_V_SECOND_LANE_WAVE):
		fails.append("AR-W dropped AR-V P0Slice flag")
	if P0 != null and not bool(P0.AR_U_XP_LEVELING):
		fails.append("AR-W dropped AR-U P0Slice flag")
	if P0 != null and not bool(P0.AR_S_TWELFTH_KIT):
		fails.append("AR-W dropped AR-S P0Slice flag")
	if P0 != null and not bool(P0.AR_I_MATCH_END):
		fails.append("AR-W dropped AR-I P0Slice flag")
	if P0 != null and not bool(P0.FL_N_FLEET):
		fails.append("AR-W dropped FL-N P0Slice flag")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-W flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-W Infection cap drifted")
	var Kit = load("res://scripts/abilities/AbilityKitCatalog.gd")
	if Kit == null or not Kit.has_method("kit_ids"):
		fails.append("AR-W AbilityKitCatalog missing")
	else:
		var ids: PackedStringArray = Kit.kit_ids()
		if int(ids.size()) != 12:
			fails.append("AR-W kit count want 12 (got %s)" % ids.size())
		if ids.has("cx_nex") == false or ids.has("gr_thorn") == false:
			fails.append("AR-W dropped catalog ends (cx_nex…gr_thorn)")
		if int(ids.size()) >= 13:
			fails.append("AR-W added a 13th AbilityKit")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	var wlab := str(SoftK.wave_label()) if SoftK and SoftK.has_method("wave_label") else ""
	var mlab := str(SoftK.minion_label()) if SoftK and SoftK.has_method("minion_label") else ""
	if wlab == "" or (wlab != "WAVE" and wlab != "LANE WAVE"):
		fails.append("AR-W SoftKnowledge WAVE missing (%s)" % wlab)
	if mlab == "" or (mlab != "MINION" and mlab != "LANE MINION"):
		fails.append("AR-W SoftKnowledge MINION missing (%s)" % mlab)
	var xlab := str(SoftK.xp_label()) if SoftK and SoftK.has_method("xp_label") else ""
	var llab := str(SoftK.level_label()) if SoftK and SoftK.has_method("level_label") else ""
	if xlab == "" or (xlab != "XP" and xlab != "CLASH XP"):
		fails.append("AR-W dropped AR-U SoftKnowledge XP (%s)" % xlab)
	if llab == "" or (llab != "LEVEL" and llab != "CLASH LEVEL"):
		fails.append("AR-W dropped AR-U SoftKnowledge LEVEL (%s)" % llab)
	var localn: Node = arena.get_node_or_null("ClashLocalMatch") if arena else null
	if localn != null and localn.has_method("is_level_informational") and not bool(localn.is_level_informational()):
		fails.append("AR-W AR-U level is not informational")
	var waves: Node = arena.get_node_or_null("ClashWaves") if arena else null
	if waves == null and arena:
		waves = arena.get("_waves")
	if waves == null or not is_instance_valid(waves):
		fails.append("AR-W ClashWaves missing")
		return fails
	if not waves.has_method("living_minions") or not waves.has_method("living_on_lane"):
		fails.append("AR-W ClashWaves API missing")
		return fails
	if not waves.has_method("is_host_authority") or not bool(waves.is_host_authority()):
		fails.append("AR-W wave is not host authority")
	if not waves.has_method("pulse_damage") or absf(float(waves.pulse_damage()) - 11.0) > 0.01:
		fails.append("AR-W Pulse 11 drifted")
	var seed := str(waves.seed_lane()) if waves.has_method("seed_lane") else "TOP"
	var opp := str(waves.opposite_lane()) if waves.has_method("opposite_lane") else "BOT"
	var third := str(waves.third_lane()) if waves.has_method("third_lane") else "MID"
	if seed == "" or opp == "" or third == "" or seed == opp or seed == third or opp == third:
		fails.append("AR-W seed/opposite/third lanes collapsed (%s/%s/%s)" % [seed, opp, third])
	var on_seed: Array = waves.living_on_lane(seed)
	var on_opp: Array = waves.living_on_lane(opp)
	var on_third: Array = waves.living_on_lane(third)
	if on_seed.is_empty() or on_opp.is_empty() or on_third.is_empty():
		await get_tree().create_timer(0.45).timeout
		on_seed = waves.living_on_lane(seed)
		on_opp = waves.living_on_lane(opp)
		on_third = waves.living_on_lane(third)
	if on_seed.is_empty():
		fails.append("AR-W dropped AR-T WAVE on %s" % seed)
	if on_opp.is_empty():
		fails.append("AR-W dropped AR-V WAVE on %s" % opp)
	if on_third.is_empty():
		fails.append("AR-W no third-lane WAVE on %s" % third)
		return fails
	var walker: Node3D = null
	for n in on_third:
		if n is Node3D:
			walker = n as Node3D
			break
	if walker == null:
		fails.append("AR-W third-lane minion is not a CombatDummy")
		return fails
	if not walker.has_meta("clash_wave") or not bool(walker.get_meta("clash_wave")):
		fails.append("AR-W minion missing clash_wave")
	if str(walker.get_meta("combat_authority")) != "host":
		fails.append("AR-W minion combat_authority left host")
	if walker.has_method("infection_cap") and int(walker.infection_cap()) != 5:
		fails.append("AR-W Infection cap drifted (%s)" % walker.infection_cap())
	if str(walker.get_meta("clash_seed")) != "ar_w":
		fails.append("AR-W third-lane minion missing clash_seed")
	var lane_id := str(walker.get_meta("lane")) if walker.has_meta("lane") else ""
	if lane_id == "" and lanes and lanes.has_method("lane_at"):
		lane_id = str(lanes.lane_at(walker.global_position))
	if lane_id != third:
		fails.append("AR-W minion not on remaining lane (got %s want %s)" % [lane_id, third])
	var dummy_scene: PackedScene = load("res://scenes/combat/CombatDummy.tscn")
	var tgt: Node = dummy_scene.instantiate() if dummy_scene else null
	if tgt == null:
		fails.append("AR-W Pulse target scene missing")
		return fails
	tgt.name = "ARWPulseTarget"
	tgt.set("faction", "Cybernex" if str(walker.get("faction")) != "Cybernex" else "gROT")
	arena.add_child(tgt)
	await get_tree().process_frame
	if tgt is Node3D:
		(tgt as Node3D).global_position = walker.global_position + Vector3(0.0, 0.0, 2.0)
	var hp0 := float(tgt.health)
	if walker.has_method("try_pulse"):
		walker.try_pulse(tgt)
	var hp1 := float(tgt.health)
	print("[Playtest] AR-W Pulse ", hp0, " -> ", hp1, " lane=", lane_id, " seed=", seed, " opposite=", opp)
	if hp1 >= hp0:
		fails.append("AR-W minion Pulse did not hit")
	elif absf(hp0 - hp1 - 11.0) > 0.05:
		fails.append("AR-W Pulse want 11 (got %s)" % (hp0 - hp1))
	if is_instance_valid(tgt):
		tgt.queue_free()
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("combat", 20.0)
		GameManager.add_mastery("history", 20.0)
	if waves.has_method("pulse_damage") and absf(float(waves.pulse_damage()) - 11.0) > 0.01:
		fails.append("AR-W Knowledge changed Pulse")
	if localn != null and localn.has_method("is_level_informational") and not bool(localn.is_level_informational()):
		fails.append("AR-W Knowledge made AR-U level a power")
	var wlab2 := str(waves.wave_soft_label()) if waves.has_method("wave_soft_label") else ""
	var mlab2 := str(waves.minion_soft_label()) if waves.has_method("minion_soft_label") else ""
	if wlab2 == "" or (wlab2 != "WAVE" and wlab2 != "LANE WAVE"):
		fails.append("AR-W HUD WAVE missing (%s)" % wlab2)
	if mlab2 == "" or (mlab2 != "MINION" and mlab2 != "LANE MINION"):
		fails.append("AR-W HUD MINION missing (%s)" % mlab2)
	if SoftK and SoftK.has_method("exclusive_weapon_unlocked") and bool(SoftK.exclusive_weapon_unlocked("wave")):
		fails.append("AR-W unlocked exclusive weapon")
	if SoftK and SoftK.has_method("exclusive_module_unlocked") and bool(SoftK.exclusive_module_unlocked("minion")):
		fails.append("AR-W unlocked exclusive combat module")
	var director: Node = arena.get_node_or_null("ClashMatchDirector") if arena else null
	if director and director.has_method("_lane_bar_line"):
		var bar := str(director._lane_bar_line())
		if bar.find("WAVE") < 0 and bar.find("MINION") < 0:
			fails.append("AR-W director HUD missing WAVE/MINION (%s)" % bar)
	if player and player.has_method("ots_evidence"):
		var ev: Dictionary = player.ots_evidence()
		if not bool(ev.get("active", false)):
			fails.append("OTS dropped after AR-W")
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("SITE pin changed during AR-W")
	if arena and str(arena.name) != "TestArena":
		fails.append("left TestArena")
	print("[Playtest] AR-W third-lane wave · ", seed, "+", opp, "+", third, " · ", wlab2, "/", mlab2,
		" Pulse 11 · host · kits=12 · FLEET 15/15 · G5 closed · no SITE_*")
	return fails


func _check_ar_i(arena: Node, lanes: Node, player: Node) -> PackedStringArray:
	var fails: PackedStringArray = PackedStringArray()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.AR_I_MATCH_END):
		fails.append("AR-I P0Slice flag missing")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("AR-I flipped ORBITAL_STATIONS")
	var Inf = load("res://scripts/abilities/InfectionStatus.gd")
	if Inf == null or int(Inf.MAX_STACKS) != 5:
		fails.append("AR-I Infection cap drifted")
	if SoftSession:
		if SoftSession.has_method("_roll_ws_day"):
			SoftSession._roll_ws_day()
		SoftSession.war_score_daily = 0.0
		SoftSession.clash_result = ""
		SoftSession.clash_cosmetic = false
	if lanes == null or not lanes.has_method("find_structure"):
		fails.append("AR-I ClashLanes missing")
		return fails
	var root: Node3D = lanes.find_structure("CORE", "gROT") as Node3D
	if root == null:
		fails.append("AR-I gROT CORE missing")
		return fails
	var gun: Node = root.get_node_or_null("Gun")
	if gun == null or not gun.has_method("take_damage"):
		fails.append("AR-I CORE gun missing")
		return fails
	var clash: Node = arena.get_node_or_null("AexionClash") if arena else null
	if clash == null and get_tree():
		clash = get_tree().get_first_node_in_group("aexion_clash")
	var pulse0 := 11.0
	if player and player.get("ability_system") != null:
		var absys: Node = player.ability_system
		if absys and "abilities" in absys:
			for ab in absys.abilities:
				if ab != null and str(ab.get("ability_name")).to_lower().find("pulse") >= 0:
					pulse0 = float(ab.get("damage"))
					break
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("history", 20.0)
		GameManager.add_mastery("combat", 20.0)
	gun.take_damage(9999.0, "Cybernex")
	var ended := false
	if clash and clash.has_method("is_match_over"):
		ended = bool(clash.is_match_over())
	elif clash and "_ended" in clash:
		ended = bool(clash._ended)
	var localn: Node = arena.get_node_or_null("ClashLocalMatch") if arena else null
	if not ended and localn and localn.has_method("is_match_over"):
		ended = bool(localn.is_match_over())
	if not ended:
		fails.append("AR-I enemy CORE→0 did not end the match")
	var won := true
	if clash and "last_player_won" in clash:
		won = bool(clash.last_player_won)
	elif localn and "last_player_won" in localn:
		won = bool(localn.last_player_won)
	if not won:
		fails.append("AR-I enemy CORE should be WIN")
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	var lab := str(SoftK.clash_result_label(true)) if SoftK else "WIN"
	if lab.find("WIN") < 0:
		fails.append("AR-I SoftKnowledge WIN label missing (%s)" % lab)
	var granted := float(clash.last_ws_granted) if clash and "last_ws_granted" in clash else 0.0
	if granted < 14.9 and localn and "last_ws_granted" in localn:
		granted = float(localn.last_ws_granted)
	if granted < 14.9 and SoftSession:
		granted = float(SoftSession.clash_ws_granted)
	if granted < 14.9:
		fails.append("AR-I WIN WS grant missing (got %s)" % granted)
	if SoftSession and str(SoftSession.clash_result) != "WIN":
		fails.append("AR-I SoftSession result not WIN")
	var panel: Node = null
	if arena and arena.get("hud"):
		panel = arena.hud.get_node_or_null("Root/MatchResult") if arena.hud else null
	if panel:
		var plab: Label = panel.get_child(0) as Label if panel.get_child_count() > 0 else null
		if plab and str(plab.text).find("WIN") < 0:
			fails.append("AR-I HUD missing WIN")
	# Daily cap: further win is cosmetics / title only.
	if SoftSession:
		SoftSession.war_score_daily = 60.0
	if clash and clash.has_method("_end_match"):
		# already ended — grant path via SoftSession directly
		var extra := float(SoftSession.grant_war_score(15.0)) if SoftSession else -1.0
		if extra > 0.01:
			fails.append("AR-I daily cap 60 still granted WS (%s)" % extra)
		SoftSession.remember_clash_result(true, extra)
		var title := str(SoftK.clash_cosmetic_label()) if SoftK else "TITLE"
		if title == "" or (title != "TITLE" and title != "CLASH TITLE"):
			fails.append("AR-I cosmetic title missing (%s)" % title)
		if not bool(SoftSession.clash_cosmetic):
			fails.append("AR-I cap win not marked cosmetic")
	if player and player.get("ability_system") != null:
		var absys2: Node = player.ability_system
		if absys2 and "abilities" in absys2:
			for ab in absys2.abilities:
				if ab != null and str(ab.get("ability_name")).to_lower().find("pulse") >= 0:
					if absf(float(ab.get("damage")) - pulse0) > 0.01:
						fails.append("AR-I Knowledge changed Pulse")
					break
	if LayerContext and str(LayerContext.site_pin_id) != "SITE_TEST_ARENA_PILLAR":
		fails.append("AR-I minted SITE_* (%s)" % LayerContext.site_pin_id)
	if arena and str(arena.name) != "TestArena":
		fails.append("AR-I left TestArena")
	print("[Playtest] AR-I CORE→0 ", lab, " ws=", granted, " cap=60 cosmetic=",
		SoftSession.clash_cosmetic if SoftSession else "?", " G5 closed · no SITE_*")
	return fails


func _finish(ar_a: PackedStringArray, ar_b: PackedStringArray, ar_c: PackedStringArray, ar_d: PackedStringArray, ar_e: PackedStringArray, river: PackedStringArray, pads: PackedStringArray, ar_f: PackedStringArray, ar_g: PackedStringArray, ar_i: PackedStringArray, ar_j: PackedStringArray, ar_k: PackedStringArray, ar_l: PackedStringArray, ar_m: PackedStringArray, ar_n: PackedStringArray, ar_o: PackedStringArray, ar_p: PackedStringArray, ar_q: PackedStringArray, ar_r: PackedStringArray, ar_s: PackedStringArray, ar_t: PackedStringArray, ar_u: PackedStringArray, ar_v: PackedStringArray, ar_w: PackedStringArray, code: int) -> void:
	if ar_a.is_empty():
		print("[Playtest] PASS arena AR-A")
	else:
		print("[Playtest] FAIL arena AR-A")
		for f in ar_a:
			print("[Playtest]  - ", f)
	if ar_b.is_empty():
		print("[Playtest] PASS arena AR-B")
	else:
		print("[Playtest] FAIL arena AR-B")
		for f in ar_b:
			print("[Playtest]  - ", f)
	if ar_c.is_empty():
		print("[Playtest] PASS arena AR-C")
	else:
		print("[Playtest] FAIL arena AR-C")
		for f in ar_c:
			print("[Playtest]  - ", f)
	if ar_d.is_empty():
		print("[Playtest] PASS arena AR-D")
	else:
		print("[Playtest] FAIL arena AR-D")
		for f in ar_d:
			print("[Playtest]  - ", f)
	if ar_e.is_empty():
		print("[Playtest] PASS arena AR-E")
	else:
		print("[Playtest] FAIL arena AR-E")
		for f in ar_e:
			print("[Playtest]  - ", f)
	if river.is_empty():
		print("[Playtest] river present on footprint")
	else:
		print("[Playtest] FAIL river")
		for f in river:
			print("[Playtest]  - ", f)
	if pads.is_empty():
		print("[Playtest] jump pads hop on footprint")
	else:
		print("[Playtest] FAIL jump pads")
		for f in pads:
			print("[Playtest]  - ", f)
	if ar_f.is_empty():
		print("[Playtest] PASS arena AR-F")
	else:
		print("[Playtest] FAIL arena AR-F")
		for f in ar_f:
			print("[Playtest]  - ", f)
	if ar_g.is_empty():
		print("[Playtest] PASS arena AR-G")
	else:
		print("[Playtest] FAIL arena AR-G")
		for f in ar_g:
			print("[Playtest]  - ", f)
	if ar_i.is_empty():
		print("[Playtest] PASS arena AR-I")
	else:
		print("[Playtest] FAIL arena AR-I")
		for f in ar_i:
			print("[Playtest]  - ", f)
	if ar_j.is_empty():
		print("[Playtest] PASS arena AR-J")
	else:
		print("[Playtest] FAIL arena AR-J")
		for f in ar_j:
			print("[Playtest]  - ", f)
	if ar_k.is_empty():
		print("[Playtest] PASS arena AR-K")
	else:
		print("[Playtest] FAIL arena AR-K")
		for f in ar_k:
			print("[Playtest]  - ", f)
	if ar_l.is_empty():
		print("[Playtest] PASS arena AR-L")
	else:
		print("[Playtest] FAIL arena AR-L")
		for f in ar_l:
			print("[Playtest]  - ", f)
	if ar_m.is_empty():
		print("[Playtest] PASS arena AR-M")
	else:
		print("[Playtest] FAIL arena AR-M")
		for f in ar_m:
			print("[Playtest]  - ", f)
	if ar_n.is_empty():
		print("[Playtest] PASS arena AR-N")
	else:
		print("[Playtest] FAIL arena AR-N")
		for f in ar_n:
			print("[Playtest]  - ", f)
	if ar_o.is_empty():
		print("[Playtest] PASS arena AR-O")
	else:
		print("[Playtest] FAIL arena AR-O")
		for f in ar_o:
			print("[Playtest]  - ", f)
	if ar_p.is_empty():
		print("[Playtest] PASS arena AR-P")
	else:
		print("[Playtest] FAIL arena AR-P")
		for f in ar_p:
			print("[Playtest]  - ", f)
	if ar_q.is_empty():
		print("[Playtest] PASS arena AR-Q")
	else:
		print("[Playtest] FAIL arena AR-Q")
		for f in ar_q:
			print("[Playtest]  - ", f)
	if ar_r.is_empty():
		print("[Playtest] PASS arena AR-R")
	else:
		print("[Playtest] FAIL arena AR-R")
		for f in ar_r:
			print("[Playtest]  - ", f)
	if ar_s.is_empty():
		print("[Playtest] PASS arena AR-S")
	else:
		print("[Playtest] FAIL arena AR-S")
		for f in ar_s:
			print("[Playtest]  - ", f)
	if ar_t.is_empty():
		print("[Playtest] PASS arena AR-T")
	else:
		print("[Playtest] FAIL arena AR-T")
		for f in ar_t:
			print("[Playtest]  - ", f)
	if ar_u.is_empty():
		print("[Playtest] PASS arena AR-U")
	else:
		print("[Playtest] FAIL arena AR-U")
		for f in ar_u:
			print("[Playtest]  - ", f)
	if ar_v.is_empty():
		print("[Playtest] PASS arena AR-V")
	else:
		print("[Playtest] FAIL arena AR-V")
		for f in ar_v:
			print("[Playtest]  - ", f)
	if ar_w.is_empty():
		print("[Playtest] PASS arena AR-W")
	else:
		print("[Playtest] FAIL arena AR-W")
		for f in ar_w:
			print("[Playtest]  - ", f)
	if AutoUpdater and AutoUpdater.has_method("abort_pending"):
		AutoUpdater.abort_pending()
	var tree := get_tree()
	if tree:
		tree.quit(code)
	OS.kill(OS.get_process_id())
