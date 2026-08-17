extends Node
## Headless AR-A + AR-B + AR-C: OTS, structures, timed lane waves.
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
	print("[Playtest] arena AR-A/AR-B/AR-C driver on")
	call_deferred("_go")


func _go() -> void:
	await get_tree().create_timer(0.7).timeout
	var fails: PackedStringArray = PackedStringArray()
	var arena: Node = get_parent()
	if arena == null or str(arena.name) != "TestArena":
		_finish(["no TestArena parent"], PackedStringArray(), 1)
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
	fails.append_array(ar_c_fails)
	fails.append_array(ar_b_fails)

	_finish(ar_a_fails, ar_b_fails, ar_c_fails, 0 if fails.is_empty() else 1)


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


func _finish(ar_a: PackedStringArray, ar_b: PackedStringArray, ar_c: PackedStringArray, code: int) -> void:
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
	if AutoUpdater and AutoUpdater.has_method("abort_pending"):
		AutoUpdater.abort_pending()
	var tree := get_tree()
	if tree:
		tree.quit(code)
	OS.kill(OS.get_process_id())
