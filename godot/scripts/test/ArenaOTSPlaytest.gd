extends Node
## Headless AR-A + AR-B + AR-C + AR-D + AR-E + river + jump pads: OTS, structures, waves, camp, kits/module, river, short hop.
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
	print("[Playtest] arena AR-A/AR-B/AR-C/AR-D/AR-E + river + jump pads driver on")
	call_deferred("_go")


func _go() -> void:
	await get_tree().create_timer(0.7).timeout
	var fails: PackedStringArray = PackedStringArray()
	var arena: Node = get_parent()
	if arena == null or str(arena.name) != "TestArena":
		_finish(["no TestArena parent"], PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), PackedStringArray(), 1)
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
	var pad_fails: PackedStringArray = await _check_jump_pads(arena, player)
	fails.append_array(ar_c_fails)
	fails.append_array(ar_b_fails)
	fails.append_array(ar_d_fails)
	fails.append_array(ar_e_fails)
	fails.append_array(river_fails)
	fails.append_array(pad_fails)

	_finish(ar_a_fails, ar_b_fails, ar_c_fails, ar_d_fails, ar_e_fails, river_fails, pad_fails, 0 if fails.is_empty() else 1)


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
	if ids.size() < 4 or ids.size() > 8:
		fails.append("kit count not 4–8")
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


func _finish(ar_a: PackedStringArray, ar_b: PackedStringArray, ar_c: PackedStringArray, ar_d: PackedStringArray, ar_e: PackedStringArray, river: PackedStringArray, pads: PackedStringArray, code: int) -> void:
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
	if AutoUpdater and AutoUpdater.has_method("abort_pending"):
		AutoUpdater.abort_pending()
	var tree := get_tree()
	if tree:
		tree.quit(code)
	OS.kill(OS.get_process_id())
