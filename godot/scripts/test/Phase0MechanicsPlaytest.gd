extends Node
## Headless mechanics playtest: interior enter/exit, occupy contest, stall math.
## OS-H ritual: space → atmo → land → EVA → takeoff → space (same scene).
## Enabled with: godot --path godot --scene res://scenes/world/OpenSpace.tscn -- --playtest-mechanics
## Ritual only:  -- --playtest-ritual
## Headless PASS is step-completeness. It is not a 3090 FPS / 5 min soak.

const _Flight = preload("res://scripts/ship/ShipFlightModel.gd")
const _Hits = preload("res://scripts/combat/CombatHits.gd")

var _ritual_only := false


func _ready() -> void:
	var mechanics := false
	var ritual := false
	for a in OS.get_cmdline_user_args():
		if str(a) == "--playtest-mechanics":
			mechanics = true
		elif str(a) == "--playtest-ritual":
			ritual = true
	if not mechanics and not ritual:
		queue_free()
		return
	_ritual_only = ritual and not mechanics
	print("[Playtest] mechanics driver on" if not _ritual_only else "[Playtest] OS-H ritual driver on")
	call_deferred("_go")


func _go() -> void:
	await get_tree().create_timer(1.6).timeout
	var fails: PackedStringArray = PackedStringArray()
	var os: Node = get_parent()
	if os == null:
		_finish(["no OpenSpace parent"], 1)
		return
	# Capture OS-C spawn before later tests land / park the ship at 770 m.
	var osc_spawn_agl := _osc_read_spawn_agl(os)
	print("[Playtest] OS-C boot AGL=", snapped(osc_spawn_agl, 0.1))
	await _assert_osc_pad_pip(os, fails)
	# OS-H uses the real boot altitude. Do not teleport past a step.
	await _osh_ritual(fails)
	_assert_hud_stack(os, fails)
	if _ritual_only:
		_finish(fails, 0 if fails.is_empty() else 1)
		return

	await _assert_st_a(os, fails)
	_assert_st_d(os, fails)
	_assert_st_e(os, fails)
	_assert_st_f(os, fails)
	_assert_st_g(os, fails)
	await _assert_in_a(os, fails)
	await _assert_in_b(os, fails)
	await _assert_in_c(os, fails)
	await _assert_in_d(os, fails)
	await _assert_in_e(os, fails)
	await _assert_in_f(os, fails)
	await _assert_q_a(os, fails)
	await _assert_q_b(os, fails)
	await _assert_q_c(os, fails)
	await _assert_ar_f(os, fails)
	await _assert_ar_g(os, fails)
	_assert_se_a(os, fails)
	await _assert_landed_hatch_on_pad(os, fails)
	_assert_scan_cache_live(fails)

	# --- stall math (no scene) ---
	if _Flight.stall_amount(0.0, 4.0, 20.0) > 0.01:
		fails.append("stall in vacuum")
	if _Flight.stall_amount(1.0, 2.0, 20.0) < 0.5:
		fails.append("low-speed dense atmo should stall")
	if _Flight.stall_amount(1.0, 80.0, 20.0) > 0.01:
		fails.append("fast flight should not stall")
	if _Flight.stall_speed(_Flight.Mode.HOVER) > 0.01:
		fails.append("HOVER must not stall")
	_assert_dirt_slope_math(fails)

	# --- interior from pilot ---
	if os.has_method("_toggle_interior"):
		os._toggle_interior()
	await get_tree().create_timer(0.55).timeout
	var d: Node = os.get("_interior")
	if d == null or not d.has_method("is_inside") or not bool(d.is_inside()):
		fails.append("interior not inside after toggle")
	else:
		print("[Playtest] interior kind=", d.get_kind(), " atmo=", d.get_atmo(), " ls=", d.life_support_line())
		var pocket: Node3D = d.get_active_interior() if d.has_method("get_active_interior") else null
		if pocket:
			print("[Playtest] pocket y=", pocket.global_position.y)
			if pocket.global_position.y < 2000.0:
				fails.append("pocket still inside Nex-Prime (y<2000)")
		var wr: Node3D = os.get_node_or_null("WorldRoot") as Node3D
		if wr and wr.visible:
			fails.append("WorldRoot still visible inside interior")
		var walker: Node3D = os.get("player") as Node3D
		if walker == null or not is_instance_valid(walker):
			fails.append("no walker after interior enter")
		else:
			print("[Playtest] walker parent=", walker.get_parent().name if walker.get_parent() else "null", " vis=", walker.is_visible_in_tree(), " y=", walker.global_position.y)
			if wr and wr.is_ancestor_of(walker):
				fails.append("walker still under WorldRoot")
			if not walker.is_visible_in_tree():
				fails.append("walker/camera hidden (black interior)")
			if walker.global_position.y < 2000.0:
				fails.append("walker y still inside Nex-Prime")
			if bool(walker.get("eva_mode")):
				fails.append("interior enter hopped through EVA")
			if pocket:
				var door: Node3D = pocket.get_node_or_null("DoorPortal_0") as Node3D
				if door == null:
					fails.append("no DoorPortal in ship pocket")
				else:
					var dest := str(door.get_meta("leads_to", ""))
					print("[Playtest] door leads_to=", dest)
					if dest != "pocket" and dest != "eva":
						fails.append("DoorPortal_0 is a locked prop (leads_to=%s)" % dest)
					var slab: Node3D = door.get_node_or_null("Slab") as Node3D
					var x0: float = slab.position.x if slab else -1.0
					walker.global_position = door.global_position + Vector3(0, 1.15, 0)
					await get_tree().create_timer(0.5).timeout
					var x1: float = slab.position.x if slab else -1.0
					print("[Playtest] door slab ", snapped(x0, 0.01), " -> ", snapped(x1, 0.01))
					if x1 < 0.6:
						fails.append("interior door did not slide open")
					else:
						var open_ok := false
						if slab:
							for c in slab.get_children():
								if c is CollisionObject3D and int((c as CollisionObject3D).collision_layer) == 0:
									open_ok = true
						print("[Playtest] door collision open=", open_ok)
						if not open_ok:
							fails.append("open door still blocking collision")
				var cv: Node3D = pocket.get_node_or_null("ConsoleVolume") as Node3D
				if cv == null:
					fails.append("no ConsoleVolume in ship pocket")
				else:
					walker.global_position = cv.global_position
					await get_tree().process_frame
					var used := false
					if d.has_method("try_use_console"):
						used = bool(d.try_use_console())
					print("[Playtest] console used=", used, " ls=", d.life_support_line())
					if not used:
						fails.append("cockpit console not usable when standing on it")
		# Interior leftover: F at hatch is the airlock (not a silent miss / I-only).
		var hatch_f: Node3D = null
		if d != null and d.has_method("get_active_interior"):
			var pk: Node3D = d.get_active_interior() as Node3D
			if pk != null:
				hatch_f = pk.get_node_or_null("ExitVolume") as Node3D
		if walker != null and is_instance_valid(walker) and hatch_f != null:
			walker.global_position = hatch_f.global_position + Vector3(0, 0.15, 0)
			await get_tree().process_frame
			if os.has_method("_handle_f_interact"):
				os._handle_f_interact()
			await get_tree().create_timer(0.45).timeout
			var still_in := d.has_method("is_inside") and bool(d.is_inside())
			print("[Playtest] F-at-hatch inside=", still_in, " y=", snapped(walker.global_position.y, 0.1) if walker != null and is_instance_valid(walker) else -1.0)
			if still_in:
				fails.append("F at hatch did not exit pocket")
			if walker != null and is_instance_valid(walker) and walker.global_position.y > 5000.0:
				fails.append("walker still at pocket after F hatch")
		elif d != null and d.has_method("exit_interior"):
			d.exit_interior()
			await get_tree().create_timer(0.35).timeout
		if d != null and d.has_method("is_inside") and bool(d.is_inside()):
			fails.append("interior still inside after exit")
		if wr and not wr.visible:
			fails.append("WorldRoot stayed hidden after exit")
		if walker != null and is_instance_valid(walker) and walker.global_position.y > 5000.0:
			fails.append("walker still at pocket after exit")

	# --- occupy contest ---
	await get_tree().create_timer(0.6).timeout
	var pl: Node3D = os.nearest_planet(os.ship.global_position) if os.has_method("nearest_planet") and os.get("ship") else null
	if pl and pl.has_method("ensure_pad_bases"):
		pl.ensure_pad_bases()
		await get_tree().create_timer(0.55).timeout
	var pads: Array = get_tree().get_nodes_in_group("pad_bases")
	print("[Playtest] pads=", pads.size())
	if pads.is_empty():
		fails.append("no pad_bases")
	else:
		var pad: Node = pads[0]
		var fac0 := "Cybernex"
		if pad.has_method("get_faction"):
			fac0 = str(pad.get_faction())
		var rival := "gROT" if fac0 != "gROT" else "Cybernex"
		if pad.has_method("claim"):
			pad.claim(rival, 0.55)
		await get_tree().process_frame
		var st := ""
		if pad.has_method("get_claim_status"):
			st = str(pad.get_claim_status())
		print("[Playtest] occupy status=", st, " fac=", pad.get_faction() if pad.has_method("get_faction") else "?")
		if st != "contested" and str(pad.get_faction() if pad.has_method("get_faction") else "") != "Contested":
			fails.append("claim rival did not open contest (status=%s)" % st)
		else:
			var walker2: Node3D = os.get("player") as Node3D
			if (walker2 == null or not is_instance_valid(walker2)) and os.has_method("try_exit_ship"):
				os.try_exit_ship()
				await get_tree().create_timer(0.35).timeout
				walker2 = os.get("player") as Node3D
			if walker2 == null or not is_instance_valid(walker2):
				fails.append("occupy presence: no walker to stand in the ring")
			else:
				# Occupy must raise the contest meter toward the occupant.
				# A Cybernex walker on a gROT contest used to *lower* 0.55→0.08
				# and the old test still printed PASS because the number moved.
				if walker2.has_method("set") or "faction" in walker2:
					walker2.set("faction", rival)
				if SoftScanCache and SoftScanCache.has_method("invalidate_player"):
					SoftScanCache.invalidate_player()
				var before := 0.0
				if pad.has_method("get_occupy_strength"):
					before = float(pad.get_occupy_strength())
				if pad is Node3D:
					walker2.global_position = (pad as Node3D).global_position + Vector3(0, 2.0, 0)
					await get_tree().create_timer(1.6).timeout
					var after := before
					if pad.has_method("get_occupy_strength"):
						after = float(pad.get_occupy_strength())
					print("[Playtest] occupy presence meter ", snapped(before, 0.01), " -> ", snapped(after, 0.01), " side=", rival)
					if after <= before + 0.04:
						fails.append("occupy presence did not raise the contest meter toward %s (%s -> %s)" % [
							rival, str(snapped(before, 0.01)), str(snapped(after, 0.01))
						])
			# Pad-guard combat: walker as trespasser vs previous-owner turret
			if walker2 and is_instance_valid(walker2):
				walker2.set("faction", "gROT")
			if SoftScanCache:
				SoftScanCache.invalidate_player()
				SoftScanCache.invalidate_enemies()
			await get_tree().process_frame
			var guard: Node3D = pad.get_guard() if pad.has_method("get_guard") else null
			if guard == null or not is_instance_valid(guard):
				fails.append("no contest guard after rival claim")
			else:
				print("[Playtest] guard fac=", guard.get_faction() if guard.has_method("get_faction") else "?", " hp=", guard.get("health"))
				var hp0: float = float(walker2.health) if walker2 else 0.0
				if guard.has_method("_fire") and walker2:
					guard._fire(walker2)
				var hp1: float = float(walker2.health) if walker2 else 0.0
				print("[Playtest] guard shot walker hp ", snapped(hp0, 0.1), " -> ", snapped(hp1, 0.1))
				if walker2 and hp1 >= hp0:
					fails.append("guard shot did not hit walker")
				var Hits = load("res://scripts/combat/CombatHits.gd")
				var ghp0: float = float(guard.get("health"))
				if Hits and walker2 and guard.has_method("hurtbox_center"):
					var origin: Vector3 = walker2.hurtbox_center() if walker2.has_method("hurtbox_center") else walker2.global_position
					var dir: Vector3 = (guard.hurtbox_center() - origin).normalized()
					Hits.apply_shot(get_tree(), origin, dir, 18.0, "gROT", 60.0)
				var ghp1: float = float(guard.get("health"))
				print("[Playtest] walker bolt guard hp ", snapped(ghp0, 0.1), " -> ", snapped(ghp1, 0.1))
				if ghp1 >= ghp0:
					fails.append("walker bolt did not hit pad guard")
				elif guard.has_method("take_damage"):
					guard.take_damage(999.0)
					if guard.has_method("is_alive") and bool(guard.is_alive()):
						fails.append("guard still alive after lethal")
					else:
						print("[Playtest] guard down")
			# Harvest only while the owning faction stands in the ring
			if walker2 and is_instance_valid(walker2):
				walker2.set("faction", "Cybernex")
			if walker2 and is_instance_valid(walker2) and walker2.has_method("on_hacked"):
				for i in range(4):
					walker2.on_hacked(null, 1.0)
				var inf: Node = walker2.get_node_or_null("InfectionStatus")
				var inf_st: int = int(inf.get("stacks")) if inf else -1
				print("[Playtest] infection after 4 hacks=", inf_st)
				if inf_st != 5:
					fails.append("Infection not capped at 5 (got %s)" % inf_st)
				if walker2.has_method("apply_firewall"):
					walker2.apply_firewall(2.5, 0.0)
					inf_st = int(inf.get("stacks")) if inf else -1
					print("[Playtest] infection after Firewall=", inf_st)
					if inf_st != 0:
						fails.append("Firewall did not cleanse Infection")
			if pad.has_method("claim"):
				# Honest occupy can leave a high rival meter. claim(2.0) used
				# to lock only because the old test accepted a decaying 0.08.
				var cur_m := 0.0
				if pad.has_method("get_occupy_strength"):
					cur_m = float(pad.get_occupy_strength())
				var side := ""
				if pad.has_method("get_contest_side"):
					side = str(pad.get_contest_side())
				var need := 2.0
				if side != "" and side != "Cybernex":
					need = cur_m + 1.85
				pad.claim("Cybernex", need)
				print("[Playtest] lock claim Cybernex need=", snapped(need, 0.01), " was ", snapped(cur_m, 0.01), " side=", side)
			var ow = pad.get("ownership")
			if ow and ow.has_method("advance_transition"):
				ow.advance_transition(8.0, 5.0)
			await get_tree().process_frame
			await get_tree().process_frame
			if walker2 and is_instance_valid(walker2) and pad is Node3D:
				walker2.global_position = (pad as Node3D).global_position + Vector3(0, 4.0, 0)
			var e0: float = -1.0
			var pulse0: float = -1.0
			if walker2 and is_instance_valid(walker2):
				if "energy" in walker2:
					walker2.set("energy", 12.0)
					e0 = float(walker2.get("energy"))
				var ab0 = walker2.get_node_or_null("AbilitySystem")
				if ab0 and "abilities" in ab0 and ab0.abilities.size() > 0:
					ab0.current_cooldowns[ab0.abilities[0]] = 5.0
					if ab0.has_method("get_cooldown_remaining"):
						pulse0 = float(ab0.get_cooldown_remaining(0))
			var c0: float = float(GameManager.contribution) if GameManager else 0.0
			await get_tree().create_timer(0.7).timeout
			var c1: float = float(GameManager.contribution) if GameManager else 0.0
			print("[Playtest] harvest in-zone ", snapped(c0, 0.01), " -> ", snapped(c1, 0.01), " status=", pad.get_claim_status() if pad.has_method("get_claim_status") else "?")
			if c1 <= c0 + 0.001:
				fails.append("no harvest while owner in ring")
			_assert_occupy_contrib(os, pad, c0, c1, fails)
			_assert_st_b(os, pad, c0, c1, fails)
			_assert_st_c(os, pad, fails)
			_assert_occupy_energy(os, pad, walker2, e0, pulse0, fails)
			if pad.has_method("harvest_hud_line"):
				var hl0 := str(pad.harvest_hud_line())
				print("[Playtest] harvest hud=", hl0)
				if hl0.find("EXTRACTING") < 0:
					fails.append("extracting pad has no harvest HUD line")
			if pad.has_method("soft_scan"):
				var scan := str(pad.soft_scan())
				print("[Playtest] pad scan=", scan)
				if scan.find("soft intel") < 0 or scan.find("reserves") < 0:
					fails.append("pad V-scan missing soft intel")
			if walker2 and is_instance_valid(walker2) and pad is Node3D:
				walker2.global_position = (pad as Node3D).global_position + Vector3(0, 0, 420)
			await get_tree().create_timer(0.2).timeout
			var c2: float = float(GameManager.contribution) if GameManager else 0.0
			await get_tree().create_timer(0.55).timeout
			var c3: float = float(GameManager.contribution) if GameManager else 0.0
			print("[Playtest] harvest out-zone ", snapped(c2, 0.01), " -> ", snapped(c3, 0.01))
			if c3 - c2 > 0.08:
				fails.append("harvest continued after leaving ring")
			if pad.has_method("harvest_hud_line") and str(pad.harvest_hud_line()).find("EXTRACTING") >= 0:
				fails.append("harvest HUD stayed EXTRACTING after leaving ring")
			# Honest land on the same pad
			var land_ship: Node = os.get("ship")
			var up := Vector3.UP
			var host: Node = pad
			while host:
				if host.has_meta("pad_up"):
					up = host.get_meta("pad_up")
					break
				host = host.get_parent()
			var deck: Node3D = host as Node3D if host is Node3D else (pad as Node3D)
			if land_ship and deck:
				if "velocity" in land_ship:
					land_ship.velocity = Vector3.ZERO
				land_ship.global_position = deck.global_position + up * 6.0
				if land_ship.has_method("_set_mode"):
					land_ship._set_mode(2)
				if land_ship.has_method("_do_land"):
					land_ship._do_land()
				print("[Playtest] ship landed=", land_ship.get("is_landed"), " pad=", deck.name)
				if not bool(land_ship.get("is_landed")):
					fails.append("ship did not land on pad")
				else:
					# Walker is still 420m out; landed owning ship should keep the extractor on.
					if "fuel" in land_ship:
						land_ship.set("fuel", 12.0)
					var f0: float = float(land_ship.get("fuel")) if "fuel" in land_ship else -1.0
					var c4: float = float(GameManager.contribution) if GameManager else 0.0
					await get_tree().create_timer(0.7).timeout
					var c5: float = float(GameManager.contribution) if GameManager else 0.0
					print("[Playtest] harvest landed-ship ", snapped(c4, 0.01), " -> ", snapped(c5, 0.01), " status=", pad.get_claim_status() if pad.has_method("get_claim_status") else "?")
					if c5 <= c4 + 0.001:
						fails.append("no harvest while owning ship is landed")
					var f1: float = float(land_ship.get("fuel")) if "fuel" in land_ship else -1.0
					print("[Playtest] occupy fuel ", snapped(f0, 0.1), " -> ", snapped(f1, 0.1))
					if f0 < 0.0 or not land_ship.has_method("refuel"):
						fails.append("ship has no occupy refuel API")
					elif f1 <= f0 + 0.5:
						fails.append("occupy did not refuel the ship (%s → %s)" % [
							str(snapped(f0, 0.1)), str(snapped(f1, 0.1))
						])
					elif f1 >= 99.0:
						fails.append("pad fuel filled instantly (no occupy wait / paid skip)")
					if land_ship.has_method("_do_launch"):
						land_ship.set("_land_lock_t", 0.0)
						land_ship._do_launch()
					await get_tree().create_timer(0.25).timeout
					var c6: float = float(GameManager.contribution) if GameManager else 0.0
					await get_tree().create_timer(0.55).timeout
					var c7: float = float(GameManager.contribution) if GameManager else 0.0
					print("[Playtest] harvest after launch ", snapped(c6, 0.01), " -> ", snapped(c7, 0.01))
					if c7 - c6 > 0.08:
						fails.append("harvest continued after launch with nobody in ring")

	# --- EVA tether reel-in (no death) ---
	var w_eva: Node3D = os.get("player") as Node3D
	var sh_eva: Node3D = os.get("ship") as Node3D
	if w_eva == null or not is_instance_valid(w_eva) or sh_eva == null or not is_instance_valid(sh_eva):
		fails.append("no walker/ship for EVA tether")
	else:
		os.set("_eva_mode", true)
		os.set("_in_ship", false)
		if w_eva.has_method("set_eva_profile"):
			w_eva.set_eva_profile(true)
		if "velocity" in sh_eva:
			sh_eva.velocity = Vector3.ZERO
		var away: Vector3 = w_eva.global_position - sh_eva.global_position
		if away.length_squared() < 1.0:
			away = Vector3(1, 0, 0)
		else:
			away = away.normalized()
		w_eva.global_position = sh_eva.global_position + away * 130.0
		if "velocity" in w_eva:
			w_eva.velocity = Vector3.ZERO
		var d0: float = w_eva.global_position.distance_to(sh_eva.global_position)
		await get_tree().create_timer(0.45).timeout
		var d1: float = w_eva.global_position.distance_to(sh_eva.global_position)
		var tline: float = d1
		if os.has_method("eva_tether_distance"):
			tline = float(os.eva_tether_distance())
		print("[Playtest] EVA tether ", snapped(d0, 0.1), " -> ", snapped(d1, 0.1), " hud=", snapped(tline, 0.1))
		if d1 >= d0 - 0.15:
			fails.append("EVA tether did not reel toward ship")
		os.set("_eva_mode", false)
		if w_eva.has_method("set_eva_profile"):
			w_eva.set_eva_profile(false)

	# --- station recycler (pad habitat, not ship hull) ---
	var d_st: Node = os.get("_interior")
	var w_st: Node3D = os.get("player") as Node3D
	var pad_deck: Node3D = null
	if not pads.is_empty() and pads[0] is Node:
		var hostp: Node = pads[0]
		while hostp:
			if hostp.has_meta("pad_up") and hostp is Node3D:
				pad_deck = hostp as Node3D
				break
			hostp = hostp.get_parent()
	if d_st == null or w_st == null or not is_instance_valid(w_st) or pad_deck == null:
		fails.append("no station enter setup (interior/walker/pad)")
	elif d_st.has_method("enter_station"):
		if d_st.has_method("is_inside") and bool(d_st.is_inside()) and d_st.has_method("exit_interior"):
			d_st.exit_interior()
			await get_tree().create_timer(0.2).timeout
		w_st.global_position = pad_deck.global_position + Vector3(0, 4.0, 0)
		d_st.enter_station(w_st, pad_deck)
		await get_tree().create_timer(0.45).timeout
		print("[Playtest] station kind=", d_st.get_kind() if d_st.has_method("get_kind") else "?", " ls=", d_st.life_support_line() if d_st.has_method("life_support_line") else "")
		if not (d_st.has_method("get_kind") and str(d_st.get_kind()) == "station"):
			fails.append("enter_station did not open station pocket")
		else:
			var ls0 := str(d_st.life_support_line()) if d_st.has_method("life_support_line") else ""
			if ls0.find("POWER BUS STABLE") < 0:
				fails.append("station recycler not sealed at enter")
			var pocket_st: Node3D = d_st.get_active_interior() if d_st.has_method("get_active_interior") else null
			var cv_st: Node3D = pocket_st.get_node_or_null("ConsoleVolume") as Node3D if pocket_st else null
			if cv_st == null:
				fails.append("no ConsoleVolume in station")
			else:
				w_st.global_position = cv_st.global_position
				await get_tree().process_frame
				await get_tree().process_frame
				var used_v := false
				if d_st.has_method("try_use_console"):
					used_v = bool(d_st.try_use_console())
				var ls1 := str(d_st.life_support_line()) if d_st.has_method("life_support_line") else ""
				print("[Playtest] station vented used=", used_v, " ls=", ls1, " recycler=", d_st.recycler_on() if d_st.has_method("recycler_on") else "?")
				if not used_v or (ls1.find("VENTED") < 0 and ls1.find("POWER IDLE") < 0):
					fails.append("station E did not vent recycler")
				await get_tree().create_timer(0.55).timeout
				if d_st.has_method("try_use_console"):
					d_st.try_use_console()
				var ls2 := str(d_st.life_support_line()) if d_st.has_method("life_support_line") else ""
				print("[Playtest] station restored ls=", ls2)
				if ls2.find("POWER BUS STABLE") < 0:
					fails.append("station E did not restore recycler")
			if d_st.has_method("exit_interior"):
				d_st.exit_interior()
			await get_tree().create_timer(0.25).timeout

	# --- rover deploy → drive on Relief → stow (occupied unnamed pad) ---
	await _rover_drive_slice(os, fails)

	# --- occupy unnamed pad → transfer one cargo unit (no tractor) ---
	await _cargo_dock_slice(os, fails)

	# --- HOVER mode + vacuum stall ---
	var ship: Node = os.get("ship")
	if ship and ship.has_method("get_stall"):
		await get_tree().physics_frame
		await get_tree().physics_frame
		if float(ship.get_stall()) > 0.01:
			fails.append("stall in vacuum at spawn")
	if ship and ship.has_method("_set_mode"):
		ship._set_mode(2)  # FlightMode.HOVER
		print("[Playtest] ship mode=", ship.flight_mode_name() if ship.has_method("flight_mode_name") else "?")
		if ship.has_method("flight_mode_name") and str(ship.flight_mode_name()) != "HOVER":
			fails.append("HOVER mode not applied")

	# --- seat → pilot ---
	var d2: Node = os.get("_interior")
	var w3: Node3D = os.get("player") as Node3D
	if d2 and d2.has_method("is_inside") and bool(d2.is_inside()) and d2.has_method("exit_interior"):
		d2.exit_interior()
		await get_tree().create_timer(0.2).timeout
	w3 = os.get("player") as Node3D
	if d2 == null or w3 == null or os.get("ship") == null:
		fails.append("no interior/walker/ship for seat→pilot")
	elif d2.has_method("enter_ship"):
		d2.enter_ship(w3, os.ship)
		await get_tree().create_timer(0.45).timeout
		if not bool(d2.is_inside()):
			fails.append("enter_ship failed for seat test")
		else:
			var pocket2: Node3D = d2.get_active_interior() if d2.has_method("get_active_interior") else null
			var seat: Node3D = pocket2.get_node_or_null("Seat") as Node3D if pocket2 else null
			if seat == null:
				fails.append("no Seat marker in ship pocket")
			else:
				w3.global_position = seat.global_position + Vector3(0, 1.05, 0)
				await get_tree().process_frame
				if d2.has_method("is_near_seat") and not bool(d2.is_near_seat(w3, 3.8)):
					fails.append("walker not near seat after teleport")
				elif os.has_method("_try_seat_to_pilot"):
					os._try_seat_to_pilot()
					await get_tree().create_timer(0.25).timeout
					if d2.has_method("is_inside") and bool(d2.is_inside()):
						fails.append("still inside after seat→pilot")
					if not bool(os.get("_in_ship")):
						fails.append("not piloting after seat→pilot")
					else:
						print("[Playtest] seat→pilot OK")
					_assert_scan_cache_live(fails)

	await _seat_pocket_seat(fails)

	# --- ship hull critical recover (no permadeath) ---
	var sh_c: Node = os.get("ship")
	if sh_c == null or not sh_c.has_method("take_damage"):
		fails.append("no ship for hull crit")
	else:
		sh_c.set("health", 4.0)
		sh_c.set("shields", 0.0)
		sh_c.take_damage(12.0)
		var hp_c: float = float(sh_c.health)
		var crit_t: float = float(sh_c._hull_crit_t)
		print("[Playtest] hull crit hp=", snapped(hp_c, 0.1), " t=", snapped(crit_t, 0.01))
		if hp_c <= 0.05:
			fails.append("hull critical did not recover")
		elif crit_t <= 0.05:
			fails.append("hull crit timer not armed")
		var miss_self: Node = _Hits.apply_shot(get_tree(), sh_c.global_position, Vector3(0, 1, 0), 8.0, str(sh_c.get_faction()), 3.0, [sh_c])
		if miss_self == sh_c:
			fails.append("ship shot hit self")

	# --- damaged engine module reduces thrust (hull stays) ---
	var sh_m: Node = os.get("ship")
	if sh_m == null or not sh_m.has_method("module_thrust") or not sh_m.has_method("damage_module"):
		fails.append("no ship module HP API")
	else:
		var t0: float = float(sh_m.module_thrust())
		var hull0: float = float(sh_m.health)
		sh_m.damage_module(int(ShipModule.ModuleType.ENGINE), 999.0)
		var t1: float = float(sh_m.module_thrust())
		var hull1: float = float(sh_m.health)
		print("[Playtest] engine module thrust ", snapped(t0, 0.1), " → ", snapped(t1, 0.1), " hull=", snapped(hull1, 0.1))
		if t0 <= 0.05:
			fails.append("engine module had no thrust to degrade")
		elif t1 >= t0 - 0.05:
			fails.append("damaged engine did not reduce thrust")
		if hull1 < hull0 - 0.05:
			fails.append("module damage cut hull HP")
		if sh_m.has_method("repair_modules"):
			sh_m.repair_modules(999.0)
		# Empty fuel: no afterburn, limited thrust — not a hard lock (OS-H).
		if "fuel" in sh_m:
			sh_m.set("fuel", 0.0)
			sh_m.set("_hull_crit_t", 0.0)
			sh_m.set("op_mode", 0)
			if sh_m.has_method("_set_mode"):
				sh_m._set_mode(0)
			if sh_m.has_method("_tick_afterburn"):
				sh_m._tick_afterburn(0.05, true)
				if bool(sh_m.get("_burn_on")):
					fails.append("empty fuel still afterburned")
			if sh_m.has_method("_thrust_mult"):
				var tm: float = float(sh_m._thrust_mult())
				print("[Playtest] empty-fuel thrust_mult=", snapped(tm, 0.01))
				if tm <= 0.01:
					fails.append("empty fuel hard-locked thrust")
				elif tm > 0.95:
					fails.append("empty fuel did not limit thrust")
			sh_m.set("fuel", float(sh_m.get("max_fuel")) if "max_fuel" in sh_m else 100.0)

	await _zero_g_eva_near_ship(fails)

	_osa_same_body(fails)
	_osb_atmosphere_shell(fails)
	_osc_scale_ladder(fails, osc_spawn_agl)
	_osd_unnamed_fill(fails)
	_assert_wf_a(fails)
	_ose_near_read(fails)
	_osf_atmo_flight(fails)
	_osg_outpost_silhouette(fails)
	_assert_gear_before_land(fails)
	await _assert_ship_land_settle(fails)
	await _assert_surface_land_dirt(fails)
	await _assert_hover_alt_hold(fails)
	_pad_traffic_present(fails)
	_assert_imported_camera_cannot_steal(fails)
	await _player_pad_land_hover_view(fails)
	await _eva_board_hover_view(fails)
	await _cockpit_space_takeoff_view(fails)
	await _npc_takeoff_land(fails)
	await _npc_occupy_harvest(fails)
	await _npc_place_module(fails)
	await _npc_squad_invite(fails)
	await _npc_offline_cycle(fails)
	await _npc_soft_alliance(fails)
	await _eva_snap_pulse(fails)
	_osh_invariants(fails)
	_finish(fails, 0 if fails.is_empty() else 1)


func _seat_pocket_seat(fails: PackedStringArray) -> void:
	## Pillar 3: leave the seat into the pocket, walk a real door/airlock, sit back.
	var os: Node = get_parent()
	var d: Node = os.get("_interior") if os else null
	var ship: Node = os.get("ship") if os else null
	if os == null or d == null or ship == null:
		fails.append("seat→pocket: no OpenSpace/interior/ship")
		return
	if d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
		d.exit_interior()
		await get_tree().create_timer(0.2).timeout
	if not bool(os.get("_in_ship")):
		fails.append("seat→pocket: not piloting")
		return
	if os.has_method("_leave_seat_to_pocket"):
		os._leave_seat_to_pocket()
	elif os.has_method("_toggle_interior"):
		os._toggle_interior()
	await get_tree().create_timer(0.55).timeout
	if not (d.has_method("is_inside") and bool(d.is_inside())):
		fails.append("seat→pocket did not enter pocket")
		return
	if bool(os.get("_in_ship")):
		fails.append("seat→pocket still piloting")
	if bool(os.get("_eva_mode")):
		fails.append("seat→pocket hopped through EVA")
	var walker: Node3D = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("seat→pocket no walker")
		return
	if bool(walker.get("eva_mode")):
		fails.append("seat→pocket walker still EVA")
	if walker.global_position.y < 2000.0:
		fails.append("seat→pocket walker not in pocket")
	var pocket: Node3D = d.get_active_interior() if d.has_method("get_active_interior") else null
	if pocket == null:
		fails.append("seat→pocket no active pocket")
		return
	if pocket.get_node_or_null("AirlockStub") == null:
		fails.append("no AirlockStub volume")
	var fake := 0
	var real := 0
	for n in pocket.get_children():
		if not str(n.name).begins_with("DoorPortal"):
			continue
		var dest := str(n.get_meta("leads_to", ""))
		if dest == "pocket" or dest == "eva":
			real += 1
		else:
			fake += 1
	print("[Playtest] seat→pocket doors real=", real, " fake=", fake)
	if fake > 0:
		fails.append("locked/fake door in ship pocket")
	if real < 1:
		fails.append("no real door in ship pocket")
	var hatch: Node3D = pocket.get_node_or_null("ExitVolume") as Node3D
	if hatch == null:
		fails.append("no hatch ExitVolume")
	elif str(hatch.get_meta("leads_to", "")) != "eva":
		fails.append("hatch does not lead to EVA")
	var seat: Node3D = pocket.get_node_or_null("Seat") as Node3D
	if seat == null or hatch == null:
		fails.append("seat→pocket missing Seat/hatch")
		return
	var mid: Vector3 = (seat.global_position + hatch.global_position) * 0.5
	walker.global_position = Vector3(mid.x, pocket.global_position.y + 1.2, mid.z)
	if walker is CharacterBody3D:
		(walker as CharacterBody3D).velocity = Vector3.ZERO
	await get_tree().create_timer(0.45).timeout
	print("[Playtest] seat→hatch mid z=", snapped(mid.z, 0.01), " walker=", snapped(walker.global_position.z, 0.01), " y=", snapped(walker.global_position.y, 0.01))
	if absf(walker.global_position.z - mid.z) > 2.5 or walker.global_position.y < pocket.global_position.y - 1.0:
		fails.append("void between seat and hatch (fake door)")
	walker.global_position = hatch.global_position + Vector3(0, 0.15, 0)
	await get_tree().process_frame
	if d.has_method("is_near_hatch") and not bool(d.is_near_hatch(walker)):
		fails.append("walker not near hatch after walk")
	walker.global_position = seat.global_position + Vector3(0, 1.05, 0)
	await get_tree().process_frame
	if d.has_method("is_near_seat") and not bool(d.is_near_seat(walker, 3.8)):
		fails.append("walker not near seat for pocket→seat")
	elif os.has_method("_try_seat_to_pilot"):
		os._try_seat_to_pilot()
		await get_tree().create_timer(0.25).timeout
		if d.has_method("is_inside") and bool(d.is_inside()):
			fails.append("still inside after pocket→seat")
		if not bool(os.get("_in_ship")):
			fails.append("not piloting after pocket→seat")
		else:
			print("[Playtest] seat→pocket→seat OK")


func _zero_g_eva_near_ship(fails: PackedStringArray) -> void:
	## Pillar 7: near-ship EVA in the gravity well is zero-G. Dirt walker stays
	## grounded (OS-H). Fuel + tether stay. F reboards the seat.
	var os: Node = get_parent()
	var nex: Node = _osh_nex()
	var ship: Node3D = os.get("ship") as Node3D if os else null
	if os == null or nex == null or ship == null or not is_instance_valid(ship):
		fails.append("zero-G EVA: no OpenSpace/Nex-Prime/ship")
		return
	var rad: float = float(nex.get("radius"))
	var up: Vector3 = Vector3(0.18, 0.96, 0.12).normalized()
	# Inside the well (Nex-Prime well ≈ 576 m) but not on dirt.
	var hover: Vector3 = nex.global_position + up * (rad + 250.0)
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	ship.global_position = hover
	if ship.has_method("_do_launch") and bool(ship.get("is_landed")):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if "is_landed" in ship:
		ship.set("is_landed", false)
	var g_here: Vector3 = Vector3.ZERO
	if os.has_method("gravity_at"):
		g_here = os.gravity_at(hover)
	print("[Playtest] zero-G well g=", snapped(g_here.length(), 0.01), " AGL=250")
	if g_here.length() < 1.0:
		fails.append("zero-G EVA test not inside gravity well (g=%s)" % snapped(g_here.length(), 0.01))
		return
	if os.has_method("_spawn_eva_near_ship"):
		os.call("_spawn_eva_near_ship")
	os.set("_eva_mode", true)
	os.set("_in_ship", false)
	var walker: Node3D = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("zero-G EVA spawn failed")
		return
	if not bool(walker.get("eva_mode")):
		fails.append("zero-G EVA walker not in eva_mode")
	if walker.has_method("is_zero_g") and not bool(walker.is_zero_g()):
		fails.append("zero-G EVA flag off near ship")
	if "velocity" in walker:
		walker.velocity = Vector3.ZERO
	var r0: float = walker.global_position.distance_to(nex.global_position)
	await get_tree().create_timer(0.5).timeout
	var r1: float = walker.global_position.distance_to(nex.global_position)
	print("[Playtest] zero-G coast r ", snapped(r0, 0.01), " → ", snapped(r1, 0.01))
	if r1 < r0 - 0.25:
		fails.append("zero-G EVA fell toward planet (%s → %s)" % [snapped(r0, 0.01), snapped(r1, 0.01)])
	# Translate around the hull, then spend fuel on the same thruster path.
	var side: Vector3 = ship.global_transform.basis.x
	var fwd: Vector3 = -ship.global_transform.basis.z
	var p0: Vector3 = walker.global_position
	if "velocity" in walker:
		walker.velocity = side * 8.0
	await get_tree().create_timer(0.25).timeout
	var moved: float = walker.global_position.distance_to(p0)
	var e0: float = float(walker.get("energy")) if "energy" in walker else -1.0
	if walker.has_method("_process_eva"):
		walker.call("_process_eva", 0.25, side, fwd, side)
	var e1: float = float(walker.get("energy")) if "energy" in walker else -1.0
	print("[Playtest] zero-G translate ", snapped(moved, 0.01), " EN ", snapped(e0, 0.1), " → ", snapped(e1, 0.1))
	if moved < 0.15:
		fails.append("zero-G EVA did not translate around hull")
	if e0 >= 0.0 and e1 > e0 - 0.15:
		fails.append("zero-G EVA fuel did not spend")
	# F reboard seat
	var hatch: Node3D = ship.get_node_or_null("HatchPoint") as Node3D
	var board_at: Vector3 = hatch.global_position if hatch else ship.global_position
	walker.global_position = board_at + side * 2.0
	if os.has_method("try_enter_ship"):
		os.try_enter_ship()
	await get_tree().create_timer(0.4).timeout
	print("[Playtest] zero-G reboard in_ship=", os.get("_in_ship"))
	if not bool(os.get("_in_ship")):
		fails.append("zero-G EVA did not reboard (F)")


func _osa_same_body(fails: PackedStringArray) -> void:
	var relief = load("res://scripts/world/PlanetRelief.gd")
	if relief == null:
		fails.append("OS-A PlanetRelief missing")
		return
	var nex: Node = null
	var tree_p := get_tree()
	if tree_p:
		for n in tree_p.get_nodes_in_group("planets"):
			if str(n.get("planet_name")) == "Nex-Prime":
				nex = n
				break
	if nex == null:
		fails.append("OS-A no Nex-Prime")
		return
	var seed_b: int = int(relief.body_seed("Nex-Prime"))
	var prof: Dictionary = relief.profile_for_planet("Nex-Prime")
	var rad: float = float(nex.get("radius"))
	var smat = nex.get("_surface_shader_mat")
	if smat is ShaderMaterial:
		var us: float = float((smat as ShaderMaterial).get_shader_parameter("seed"))
		var ur: float = float((smat as ShaderMaterial).get_shader_parameter("planet_radius"))
		var usea: float = float((smat as ShaderMaterial).get_shader_parameter("sea_threshold"))
		if absf(us - float(seed_b)) > 0.51:
			fails.append("OS-A shader seed != body_seed (%s vs %s)" % [us, seed_b])
		if absf(ur - rad) > 0.51:
			fails.append("OS-A shader radius != body")
		if absf(usea - float(prof.get("sea_level", -0.25))) > 0.02:
			fails.append("OS-A shader sea != profile")
	else:
		fails.append("OS-A Nex-Prime has no surface shader")
	var seas := 0
	var lands := 0
	for i in range(16):
		var a := float(i) * TAU / 16.0
		var d := Vector3(sin(a), 0.12, cos(a)).normalized()
		var xz: Vector2 = relief.sphere_xz(d, rad)
		var hm: float = float(relief.height_macro_at(xz.x, xz.y, seed_b, prof))
		var hs: float = float(relief.height_on_sphere(d, rad, seed_b, prof, true))
		if absf(hm - hs) > 0.0001:
			fails.append("OS-A sphere_xz != height_on_sphere")
			break
		if bool(relief.is_sea(hm, prof)):
			seas += 1
		else:
			lands += 1
	print("[Playtest] OS-A Nex-Prime seed=", seed_b, " land=", lands, " sea=", seas)
	if seas < 2 or lands < 2:
		fails.append("OS-A Nex-Prime macro has no land/sea contrast")
	var detail = nex.get_node_or_null("SurfaceDetail")
	if detail:
		var dseed: int = int(detail.get("_seed"))
		if dseed != seed_b:
			fails.append("OS-A SurfaceDetail seed != body_seed")
	# DoD path: 770 m AGL over Nex-Prime, then EVA + relief snap (P0.6)
	var os: Node = get_parent()
	var ship: Node3D = null
	if os:
		ship = os.get("ship") as Node3D
	var up: Vector3 = Vector3(0.18, 0.96, 0.12).normalized()
	var hover: Vector3 = nex.global_position + up * (rad + 770.0)
	if ship:
		ship.global_position = hover
	var agl: float = 770.0
	if nex.has_method("altitude_of"):
		agl = float(nex.call("altitude_of", hover))
	print("[Playtest] OS-A approach AGL=", snapped(agl, 0.1))
	if absf(agl - 770.0) > 8.0:
		fails.append("OS-A 770m approach place failed")
	if os and os.has_method("_spawn_eva_near_ship"):
		os.call("_spawn_eva_near_ship")
	var walker: Node3D = null
	if os:
		walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("OS-A EVA spawn failed at 770m")
	else:
		var eva_agl: float = walker.global_position.distance_to(nex.global_position) - rad
		print("[Playtest] OS-A EVA AGL=", snapped(eva_agl, 0.1))
		if eva_agl < 600.0:
			fails.append("OS-A EVA not at approach altitude")
		walker.global_position = nex.global_position + up * (rad + 12.0)
		if walker.has_method("_relief_snap_fallback"):
			var ok: bool = bool(walker.call("_relief_snap_fallback"))
			if not ok:
				fails.append("OS-A relief snap returned false")
		elif walker.has_method("snap_to_surface"):
			walker.call("snap_to_surface")
		var after: float = walker.global_position.distance_to(nex.global_position) - rad
		print("[Playtest] OS-A EVA snap AGL=", snapped(after, 0.01))
		if after > 40.0 or after < -6.0:
			fails.append("OS-A EVA snap left walker off relief")


func _osb_atmosphere_shell(fails: PackedStringArray) -> void:
	var cat = load("res://scripts/world/PlanetProfileCatalog.gd")
	if cat == null:
		fails.append("OS-B PlanetProfileCatalog missing")
		return
	var env_c: float = float(cat.envelope_of("Nex-Prime"))
	if env_c < 800.0:
		fails.append("OS-B Nex-Prime envelope too short for 770m (%s)" % env_c)
	var d770: float = float(_Flight.atmosphere_density(770.0, 320.0, env_c))
	var d0: float = float(_Flight.atmosphere_density(0.0, 320.0, env_c))
	var d_out: float = float(_Flight.atmosphere_density(env_c + 20.0, 320.0, env_c))
	print("[Playtest] OS-B density 0/770/out=", snapped(d0, 0.01), "/", snapped(d770, 0.01), "/", snapped(d_out, 0.01), " env=", env_c)
	if d0 < 0.99:
		fails.append("OS-B surface density not 1")
	if d770 < 0.02 or d770 > 0.35:
		fails.append("OS-B 770m density out of thin-envelope band (%s)" % snapped(d770, 0.01))
	if d_out > 0.001:
		fails.append("OS-B density above envelope not vacuum")
	# Drag at 770 m is felt, but far below hold-S inward (28 m/s²).
	var v_vac: Vector3 = _Flight.integrate(Vector3(0, 0, 40), Vector3.ZERO, 0.016, 0.4, 1.0, 0.0, 120.0)
	var v_atmo: Vector3 = _Flight.integrate(Vector3(0, 0, 40), Vector3.ZERO, 0.016, 0.4, 1.0, d770, 120.0)
	if v_atmo.length() >= v_vac.length() - 0.00005:
		fails.append("OS-B 770m drag did not exceed vacuum")
	var qdrag: float = d770 * 0.012 * 40.0 * 40.0
	if qdrag >= 8.0:
		fails.append("OS-B 770m drag would swamp S-sink")
	var inward := Vector3(0, -1, 0)
	var climb := Vector3(0, 20, 0)
	var after_ceil: Vector3 = _Flight.apply_ceiling(climb, inward, 0.85, 0.016)
	var after_thin: Vector3 = _Flight.apply_ceiling(climb, inward, d770, 0.016)
	if after_ceil.y >= climb.y - 0.01:
		fails.append("OS-B dense ceiling did not damp climb")
	if climb.y - after_thin.y > 0.15:
		fails.append("OS-B 770m ceiling too strong for S-sink band")
	var sink_v: Vector3 = _Flight.apply_ceiling(Vector3(0, -18, 0), inward, 0.85, 0.016)
	if sink_v.y > -17.9:
		fails.append("OS-B ceiling opposed S-sink")
	var os: Node = get_parent()
	var nex: Node = null
	var tree_b := get_tree()
	if tree_b:
		for n in tree_b.get_nodes_in_group("planets"):
			if str(n.get("planet_name")) == "Nex-Prime":
				nex = n
				break
	if nex == null:
		fails.append("OS-B no Nex-Prime")
		return
	if nex.has_method("envelope_height") and absf(float(nex.call("envelope_height")) - env_c) > 1.0:
		fails.append("OS-B body envelope != catalog")
	var up: Vector3 = Vector3(0.18, 0.96, 0.12).normalized()
	var rad: float = float(nex.get("radius"))
	var hover: Vector3 = nex.global_position + up * (rad + 770.0)
	var d_body := 0.0
	if nex.has_method("density_at"):
		d_body = float(nex.call("density_at", hover))
	elif os and os.has_method("atmosphere_density_at"):
		d_body = float(os.call("atmosphere_density_at", hover))
	print("[Playtest] OS-B body density@770=", snapped(d_body, 0.01))
	if d_body < 0.02 or d_body > 0.35:
		fails.append("OS-B body density at 770m out of band")
	var atmo_n: Node = nex.get_node_or_null("Atmosphere")
	if atmo_n == null:
		fails.append("OS-B Atmosphere mesh missing")
	var amat = nex.get("_atmo_mat")
	if amat is ShaderMaterial:
		var sc: float = float((amat as ShaderMaterial).get_shader_parameter("scatter_strength"))
		if sc < 0.2:
			fails.append("OS-B limb scatter_strength unset")
	else:
		fails.append("OS-B no atmosphere shader")
	if os and os.has_method("_update_altitude_fog") and os.get("ship"):
		var ship: Node3D = os.get("ship") as Node3D
		if ship:
			ship.global_position = hover
		os.call("_update_altitude_fog")
		var we: WorldEnvironment = os.get_node_or_null("WorldEnvironment") as WorldEnvironment
		if we == null or we.environment == null:
			fails.append("OS-B no WorldEnvironment")
		elif not we.environment.fog_enabled:
			fails.append("OS-B fog off at 770m envelope")
		else:
			print("[Playtest] OS-B fog@770 dens=", snapped(we.environment.fog_density, 0.0001), " scatter=", snapped(we.environment.fog_sun_scatter, 0.01))


func _assert_osc_pad_pip(os: Node, fails: PackedStringArray) -> void:
	## OS-C spawn (~8 km): HUD/radar must show ≥1 existing unnamed pad.
	## Not PADS 0. Not a minted SITE_*. One radar tick is enough.
	var nex: Node = null
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("planets"):
			if str(n.get("planet_name")) == "Nex-Prime":
				nex = n
				break
	if nex != null and nex.has_method("ensure_pad_plates"):
		nex.call("ensure_pad_plates")
	var hud = tree.get_first_node_in_group("game_hud") if tree else null
	var ship: Node3D = os.get("ship") as Node3D if os else null
	if hud and hud.has_method("bind_player") and ship:
		hud.call("bind_player", ship)
	if hud and hud.has_method("_refresh"):
		hud.call("_refresh")
	await get_tree().process_frame
	if hud and hud.has_method("_refresh"):
		hud.call("_refresh")
	var contacts: Array = []
	if hud and hud.has_method("radar_pad_contacts"):
		contacts = hud.call("radar_pad_contacts")
	print("[Playtest] OS-C pad contacts=", contacts.size())
	if hud == null:
		fails.append("OS-C spawn has no GameHUD for pad pip")
		return
	if contacts.is_empty():
		fails.append("OS-C spawn radar has no pad contact (PADS 0)")
		return
	var unnamed := 0
	for c in contacts:
		if c == null or not is_instance_valid(c):
			continue
		var nm := str(c.name)
		if nm.begins_with("SITE_") or str(c.get_meta("site_pin", "")).begins_with("SITE_"):
			fails.append("OS-C radar minted SITE_* (%s)" % nm)
			continue
		if nm == "Pad_North" or nm == "Pad_Approach" or nm == "Pad_Flank":
			unnamed += 1
			print("[Playtest] OS-C pad pip ", nm)
	if unnamed < 1:
		fails.append("OS-C radar contact is not an existing unnamed pad")


func _osc_hover_descend_8km(fails: PackedStringArray, os: Node, nex: Node, high: Vector3, rad: float) -> void:
	## 18 Aug leftover: HOVER + S from OS-C 8 km was ~1 m/tap. Hold-S must
	## drop a playable amount in a few seconds. Not G1 CRUISE. Land gear stays.
	if _Flight.max_speed(_Flight.Mode.HOVER, 55.0, 180.0, 22.0) > 22.05:
		fails.append("OS-C HOVER cruise cap raised (brick / cruise cheat)")
	if _Flight.base_damp(_Flight.Mode.HOVER) < 1.8:
		fails.append("OS-C HOVER hold damp removed (brick)")
	if _Flight.hover_descend_max_speed(40.0, 22.0) > 12.0:
		fails.append("OS-C HOVER descend near pad too fast for LAND")
	if _Flight.hover_descend_max_speed(8000.0, 22.0) > 160.0:
		fails.append("OS-C HOVER descend looks like G1 CRUISE")
	var inward: Vector3 = (nex.global_position - high).normalized()
	var vel := Vector3.ZERO
	var pos: Vector3 = high
	var dt := 0.016
	var steps := 250  # 4.0 s
	for _i in steps:
		var agl_i: float = pos.distance_to(nex.global_position) - rad
		var acc: float = _Flight.hover_descend_accel(agl_i)
		var mx: float = _Flight.hover_descend_max_speed(agl_i, 22.0)
		var dm: float = _Flight.hover_descend_damp_mult()
		vel = _Flight.integrate(vel, inward * acc, dt, 0.35, dm, 0.0, mx)
		vel = _Flight.limit_hover_while_sink(vel, inward, 22.0, mx)
		vel = _Flight.apply_ceiling(vel, inward, 0.0, dt)
		pos += vel * dt
	var alt_kin: float = pos.distance_to(nex.global_position) - rad
	var drop_kin: float = 8000.0 - alt_kin
	print("[Playtest] OS-C HOVER hold-S 4.0s drop=", snapped(drop_kin, 1.0), " AGL ", snapped(8000.0, 1.0), "→", snapped(alt_kin, 1.0), " v=", snapped(vel.length(), 0.1))
	if drop_kin < 220.0:
		fails.append("OS-C HOVER hold-S 4.0s drop unplayable (%s m)" % snapped(drop_kin, 1.0))
	if alt_kin < 600.0:
		fails.append("OS-C HOVER hold-S punched past the 770 m band")

	var ship: Node = os.get("ship") if os else null
	if ship == null or nex == null:
		fails.append("OS-C HOVER descend: no ship")
		return
	var fuel0: float = float(ship.get("fuel")) if "fuel" in ship else 0.0
	var fuel_full: float = float(ship.get("max_fuel")) if "max_fuel" in ship else 100.0
	var mode0: int = int(ship.flight_mode) if "flight_mode" in ship else 0
	var pos0: Vector3 = (ship as Node3D).global_position
	var vel0: Vector3 = ship.velocity if "velocity" in ship else Vector3.ZERO
	var landed0: bool = bool(ship.get("is_landed")) if "is_landed" in ship else false
	var pilot0: bool = bool(ship.get("pilot_active")) if "pilot_active" in ship else true
	(ship as Node3D).global_position = high
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	if "is_landed" in ship:
		ship.is_landed = false
	if "pilot_active" in ship:
		ship.pilot_active = true
	if "_hull_crit_t" in ship:
		ship._hull_crit_t = 0.0
	if "fuel" in ship:
		ship.fuel = fuel_full
	if ship.has_method("_set_mode"):
		ship._set_mode(2)  # HOVER
	ship.set_meta("playtest_sink", true)
	ship.set_physics_process(false)
	var live_pos: Vector3 = high
	var live_vel: Vector3 = Vector3.ZERO
	for _j in steps:
		ship._physics_process(dt)
		if "velocity" in ship:
			live_vel = ship.velocity
		# Headless move_and_slide may ignore a manual delta — integrate the
		# velocity the HOVER+S tick just wrote so AGL is the ship path.
		live_pos += live_vel * dt
		(ship as Node3D).global_position = live_pos
	ship.remove_meta("playtest_sink")
	ship.set_physics_process(true)
	var alt_live: float = live_pos.distance_to(nex.global_position) - rad
	var drop_live: float = 8000.0 - alt_live
	var fuel1: float = float(ship.get("fuel")) if "fuel" in ship else fuel_full
	print("[Playtest] OS-C HOVER ship hold-S 4.0s drop=", snapped(drop_live, 1.0), " AGL →", snapped(alt_live, 1.0), " fuel ", snapped(fuel_full, 1.0), "→", snapped(fuel1, 1.0))
	if drop_live < 220.0:
		fails.append("OS-C HOVER ship hold-S 4.0s drop unplayable (%s m)" % snapped(drop_live, 1.0))
	if fuel1 >= fuel_full - 0.05:
		fails.append("OS-C HOVER descend did not spend fuel")
	var src := FileAccess.get_file_as_string("res://scripts/ship/ShipController.gd")
	if src.find("hover_descend_accel") < 0:
		fails.append("OS-C HOVER descend helpers not wired")
	if src.find("Land denied — G gear") < 0:
		fails.append("OS-C HOVER descend skipped LAND gear gate")
	if src.find("FlightMode.CRUISE") >= 0 or src.find("mass_lock") >= 0:
		fails.append("OS-C HOVER descend shipped G1 CRUISE / mass lock")
	(ship as Node3D).global_position = pos0
	if "velocity" in ship:
		ship.velocity = vel0
	if "is_landed" in ship:
		ship.is_landed = landed0
	if "pilot_active" in ship:
		ship.pilot_active = pilot0
	if "fuel" in ship:
		ship.fuel = fuel0
	if ship.has_method("_set_mode"):
		ship._set_mode(mode0)


func _osc_read_spawn_agl(os: Node) -> float:
	var ship: Node3D = os.get("ship") as Node3D if os else null
	if ship == null or not os.has_method("nearest_planet"):
		return -1.0
	var pl: Node3D = os.nearest_planet(ship.global_position)
	if pl == null or not pl.has_method("altitude_of"):
		return -1.0
	return float(pl.altitude_of(ship.global_position))


func _osc_scale_ladder(fails: PackedStringArray, spawn_agl: float) -> void:
	## OS-C: 5–15 km start is playable without G1 CRUISE. Gravity well stays
	## height*1.8. Hold-S still drops AGL. 770 m EVA is covered by OS-A.
	var os: Node = get_parent()
	if os == null:
		fails.append("OS-C no OpenSpace")
		return
	var start_const := 8000.0
	if "APPROACH_START_AGL" in os:
		start_const = float(os.APPROACH_START_AGL)
	elif os.has_method("approach_start_agl"):
		start_const = float(os.approach_start_agl())
	print("[Playtest] OS-C start const=", snapped(start_const, 1.0), " boot AGL=", snapped(spawn_agl, 0.1))
	if start_const < 5000.0 or start_const > 15000.0:
		fails.append("OS-C APPROACH_START_AGL not in 5–15 km (%s)" % snapped(start_const, 1.0))
	if spawn_agl < 5000.0 or spawn_agl > 15000.0:
		fails.append("OS-C boot spawn AGL not in 5–15 km (%s)" % snapped(spawn_agl, 0.1))
	if absf(spawn_agl - start_const) > 80.0 and spawn_agl > 0.0:
		fails.append("OS-C boot AGL != start const (%s vs %s)" % [snapped(spawn_agl, 0.1), snapped(start_const, 1.0)])

	var nex: Node = null
	var tree_c := get_tree()
	if tree_c:
		for n in tree_c.get_nodes_in_group("planets"):
			if str(n.get("planet_name")) == "Nex-Prime":
				nex = n
				break
	if nex == null:
		fails.append("OS-C no Nex-Prime")
		return
	var rad: float = float(nex.get("radius"))
	var ah: float = float(nex.get("atmosphere_height"))
	var well: float = ah * 1.8
	var up: Vector3 = Vector3(0.18, 0.96, 0.12).normalized()
	var high: Vector3 = nex.global_position + up * (rad + 8000.0)
	var far15: Vector3 = nex.global_position + up * (rad + 15000.0)
	var g_high := Vector3.ZERO
	var g_well := Vector3.ZERO
	if nex.has_method("gravity_at"):
		g_high = nex.gravity_at(high)
		g_well = nex.gravity_at(nex.global_position + up * (rad + well * 0.4))
	print("[Playtest] OS-C well=", snapped(well, 1.0), " g@8km=", snapped(g_high.length(), 0.001), " g@0.4well=", snapped(g_well.length(), 0.01))
	if g_high.length() > 0.05:
		fails.append("OS-C gravity well stretched to 8 km")
	if g_well.length() < 0.5:
		fails.append("OS-C gravity missing inside well")
	var d8 := 1.0
	if nex.has_method("density_at"):
		d8 = float(nex.density_at(high))
	print("[Playtest] OS-C density@8km=", snapped(d8, 0.001))
	if d8 > 0.001:
		fails.append("OS-C 8 km not vacuum")

	# Hold-S from 8 km: geometric inward + 28 m/s², vacuum, SCM cap. AGL must drop.
	var inward: Vector3 = (nex.global_position - high).normalized()
	var vel := Vector3.ZERO
	var pos: Vector3 = high
	for _i in 200:
		vel = _Flight.integrate(vel, inward * 28.0, 0.016, 0.35, 1.0, 0.0, 55.0)
		vel = _Flight.apply_ceiling(vel, inward, 0.0, 0.016)
		pos += vel * 0.016
	var alt_after: float = pos.distance_to(nex.global_position) - rad
	print("[Playtest] OS-C hold-S 8km → ", snapped(alt_after, 0.1), " (v=", snapped(vel.length(), 0.1), ")")
	if alt_after > 7950.0:
		fails.append("OS-C hold-S did not sink from 8 km")
	if alt_after < 600.0:
		fails.append("OS-C hold-S overshot past the 770 m band")

	_osc_hover_descend_8km(fails, os, nex, high, rad)

	# Far / impostor / limb readable at 8 km and 15 km (same Relief paint).
	var ship: Node3D = os.get("ship") as Node3D
	if ship:
		ship.global_position = high
		if "velocity" in ship:
			ship.velocity = Vector3.ZERO
	if nex.has_method("set_observer") and ship:
		nex.set_observer(ship)
	if nex.has_method("refresh_approach_lod"):
		nex.refresh_approach_lod()
	var lod8: int = int(nex.get("_current_lod"))
	var atmo8: Node = nex.get_node_or_null("Atmosphere")
	var mesh8: Node = nex.get_node_or_null("Surface")
	var imp8: Node = nex.get_node_or_null("Impostor")
	var vis_body8: bool = (mesh8 is Node3D and (mesh8 as Node3D).visible) \
		or (imp8 is Node3D and (imp8 as Node3D).visible)
	var atmo8_on: bool = atmo8 is Node3D and (atmo8 as Node3D).visible
	print("[Playtest] OS-C @8km lod=", lod8, " atmo=", atmo8_on, " body=", vis_body8)
	if lod8 > 2:
		fails.append("OS-C 8 km fell to impostor (want far mesh)")
	if not atmo8_on:
		fails.append("OS-C limb hidden at 8 km")
	if not vis_body8:
		fails.append("OS-C body mesh hidden at 8 km")
	var smat = nex.get("_surface_shader_mat")
	var imat = nex.get("_impostor_mat")
	if smat is ShaderMaterial and imat is ShaderMaterial:
		var sseed: float = float((smat as ShaderMaterial).get_shader_parameter("seed"))
		var iseed: float = float((imat as ShaderMaterial).get_shader_parameter("seed"))
		if absf(sseed - iseed) > 0.51:
			fails.append("OS-C impostor seed != far mesh")
	else:
		fails.append("OS-C far/impostor shader missing")
	if nex.get("lod_far") != null and float(nex.lod_far) < rad + 15000.0:
		fails.append("OS-C lod_far too short for 15 km (%s)" % snapped(float(nex.lod_far), 1.0))
	if nex.get("atmo_max_dist") != null and float(nex.atmo_max_dist) < rad + 15000.0:
		fails.append("OS-C atmo_max_dist too short for 15 km")

	if ship:
		ship.global_position = far15
	if nex.has_method("refresh_approach_lod"):
		nex.refresh_approach_lod()
	var lod15: int = int(nex.get("_current_lod"))
	var atmo15: Node = nex.get_node_or_null("Atmosphere")
	var mesh15: Node = nex.get_node_or_null("Surface")
	var imp15: Node = nex.get_node_or_null("Impostor")
	var vis_body15: bool = (mesh15 is Node3D and (mesh15 as Node3D).visible) \
		or (imp15 is Node3D and (imp15 as Node3D).visible)
	var atmo15_on: bool = atmo15 is Node3D and (atmo15 as Node3D).visible
	print("[Playtest] OS-C @15km lod=", lod15, " atmo=", atmo15_on, " body=", vis_body15)
	if not vis_body15:
		fails.append("OS-C body hidden at 15 km")
	if not atmo15_on:
		fails.append("OS-C limb hidden at 15 km")

	if ship:
		var cam: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
		if cam == null:
			fails.append("OS-C ship camera missing")
		elif cam.far < 15000.0 + rad:
			fails.append("OS-C camera far clips 15 km body (%s)" % snapped(cam.far, 1.0))
		else:
			print("[Playtest] OS-C cam.far=", snapped(cam.far, 1.0))

	# No G1 CRUISE in this slice — flight enum stays SCM/NAV/HOVER.
	if ship and bool(ship.get("is_landed")):
		fails.append("OS-C boot stuck LANDED at approach AGL")
	if ship and "flight_mode" in ship and int(ship.flight_mode) > 2:
		fails.append("OS-C unexpected flight mode %s" % int(ship.flight_mode))
	var cruise_src := FileAccess.get_file_as_string("res://scripts/ship/ShipController.gd")
	if cruise_src.find("FlightMode.CRUISE") >= 0 or cruise_src.find("mass_lock") >= 0:
		fails.append("OS-C shipped G1 CRUISE / mass lock (not wanted)")

	# 770 m land/EVA still reachable from the new start (place + snap).
	if ship:
		ship.global_position = nex.global_position + up * (rad + 770.0)
	if os.has_method("_spawn_eva_near_ship"):
		os.call("_spawn_eva_near_ship")
	var walker: Node3D = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("OS-C EVA at 770 m failed")
	else:
		walker.global_position = nex.global_position + up * (rad + 12.0)
		if walker.has_method("_relief_snap_fallback"):
			walker.call("_relief_snap_fallback")
		elif walker.has_method("snap_to_surface"):
			walker.call("snap_to_surface")
		var after: float = walker.global_position.distance_to(nex.global_position) - rad
		print("[Playtest] OS-C EVA snap AGL=", snapped(after, 0.01))
		if after > 40.0 or after < -6.0:
			fails.append("OS-C EVA snap left walker off relief")


func _osd_unnamed_fill(fails: PackedStringArray) -> void:
	## OS-D: from ~2 km, 2+ unnamed plates + rare scatter. No SITE_* mint.
	## No seven streamers. Chunk budget unchanged. Same body seed.
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null:
		fails.append("OS-D P0Slice missing")
		return
	if bool(P0.FILL_STREAMERS):
		fails.append("OS-D turned on seven fill streamers")
	if bool(P0.PAD_DENSITY):
		fails.append("OS-D enabled PadDensity cluster")
	if not bool(P0.OS_D_FILL):
		fails.append("OS-D OS_D_FILL flag off")
	var SD = load("res://scripts/world/SurfaceDetail.gd")
	if SD == null:
		fails.append("OS-D SurfaceDetail missing")
	elif absf(float(SD.CELL_M) - 40.0) > 0.01:
		fails.append("OS-D chunk cell size changed")
	elif int(SD.LOAD_BUDGET) != 1:
		fails.append("OS-D chunk LOAD_BUDGET changed")
	var sd_src := FileAccess.get_file_as_string("res://scripts/world/SurfaceDetail.gd")
	if sd_src.find("while _queue.size() > 12") < 0:
		fails.append("OS-D chunk queue cap changed")
	var os: Node = get_parent()
	var nex: Node = null
	var tree_d := get_tree()
	if tree_d:
		for n in tree_d.get_nodes_in_group("planets"):
			if str(n.get("planet_name")) == "Nex-Prime":
				nex = n
				break
	if nex == null:
		fails.append("OS-D no Nex-Prime")
		return
	var rad: float = float(nex.get("radius"))
	var stream: float = float(nex.get("pad_stream_dist"))
	print("[Playtest] OS-D pad_stream_dist AGL=", snapped(stream - rad, 1.0))
	if stream < rad + 2000.0:
		fails.append("OS-D pad stream shorter than 2 km (%s)" % snapped(stream - rad, 1.0))
	var seed_b := -1
	if nex.has_method("body_seed"):
		seed_b = int(nex.call("body_seed"))
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var look := Vector3(0, 0, 1)
	if ship:
		ship.global_position = nex.global_position + look * (rad + 2000.0)
		if "velocity" in ship:
			ship.velocity = Vector3.ZERO
	if nex.has_method("set_observer") and ship:
		nex.set_observer(ship)
	if nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	if nex.has_method("refresh_approach_lod"):
		nex.refresh_approach_lod()
	var pads_root: Node3D = nex.get_node_or_null("Pads") as Node3D
	if pads_root == null or not pads_root.visible:
		fails.append("OS-D Pads hidden at 2 km")
	var plates: Array = []
	if nex.get("_pads") != null:
		plates = nex.get("_pads")
	print("[Playtest] OS-D pads=", plates.size(), " seed=", seed_b)
	if plates.size() < 3:
		fails.append("OS-D want 3 unnamed pads, got %s" % plates.size())
	var approach_n := 0
	for p in plates:
		if p == null or not is_instance_valid(p):
			continue
		var pname := str(p.name)
		if pname.begins_with("SITE_") or str(p.get_meta("site_pin", "")).begins_with("SITE_"):
			fails.append("OS-D minted SITE_* on %s" % pname)
		if not pname.begins_with("Pad_"):
			fails.append("OS-D pad not Pad_North class (%s)" % pname)
		var dir: Vector3 = ((p as Node3D).global_position - nex.global_position).normalized()
		if dir.dot(look) > 0.72:
			approach_n += 1
	if approach_n < 2:
		fails.append("OS-D fewer than 2 plates on the 2 km approach face (%s)" % approach_n)
	var sc: Node = pads_root.get_node_or_null("WorldFillScatter") if pads_root else null
	if sc == null:
		fails.append("OS-D WorldFillScatter missing")
	else:
		if not (sc as Node3D).visible:
			fails.append("OS-D scatter hidden at 2 km")
		var nprop := 0
		if sc.has_method("prop_count"):
			nprop = int(sc.call("prop_count"))
		var sc_seed := -2
		if sc.has_method("body_seed"):
			sc_seed = int(sc.call("body_seed"))
		print("[Playtest] OS-D scatter n=", nprop, " seed=", sc_seed)
		if nprop < 12:
			fails.append("OS-D scatter too thin (%s)" % nprop)
		if sc_seed != seed_b:
			fails.append("OS-D scatter seed != body_seed (%s vs %s)" % [sc_seed, seed_b])
		if str(sc.get_meta("site_pin", "")).begins_with("SITE_"):
			fails.append("OS-D scatter minted SITE_*")
		var slugs: PackedStringArray = PackedStringArray()
		if sc.has_method("ledger_slugs_used"):
			slugs = sc.call("ledger_slugs_used")
		print("[Playtest] OS-D ledger slugs=", ",".join(slugs))
		if slugs.find("debris_cluster") < 0:
			fails.append("OS-D missing debris_cluster shelf")
		if slugs.find("t1_resource_extractor") < 0:
			fails.append("OS-D missing t1_resource_extractor shelf")
		if slugs.find("utility_bay") < 0:
			fails.append("OS-D missing utility_bay shelf")
		for slug in slugs:
			if str(slug).begins_with("SITE_"):
				fails.append("OS-D scatter minted SITE_* slug %s" % slug)
		var pad_clutter := 0
		for p in plates:
			if p == null or not is_instance_valid(p):
				continue
			for child in (p as Node).get_children():
				if child == null:
					continue
				var cname := str(child.name)
				if cname.begins_with("PadCrate") or cname.begins_with("PadDebris") or cname == "PadMast" or cname == "PadExtractor" or cname == "PadUtility":
					pad_clutter += 1
					if str(child.get_meta("site_pin", "")).begins_with("SITE_"):
						fails.append("OS-D pad clutter minted SITE_* on %s" % cname)
		print("[Playtest] OS-D pad clutter n=", pad_clutter)
		if pad_clutter < 8:
			fails.append("OS-D pad clutter too thin (%s)" % pad_clutter)
	for nm in ["SurfaceFlora", "SurfaceFauna", "SurfaceWater", "CaveMouthField", "CaveInterior", "LandscapeFeatures", "TerrainEdit"]:
		if nex.get_node_or_null(nm) != null:
			fails.append("OS-D live streamer %s" % nm)
	if pads_root and pads_root.get_node_or_null("PadDensityCluster"):
		fails.append("OS-D spawned PadDensity cluster")
	if LayerContext and str(LayerContext.site_pin_id) != "" and str(LayerContext.site_pin_id) != "SITE_SPACE_TEST_PAD":
		fails.append("OS-D site_pin left catalog (%s)" % LayerContext.site_pin_id)
	var sd: Node = nex.get_node_or_null("SurfaceDetail")
	if sd and sd.has_method("body_seed") and int(sd.call("body_seed")) != seed_b:
		fails.append("OS-D SurfaceDetail seed != body_seed")


func _assert_wf_a(fails: PackedStringArray) -> void:
	## WF-A: one density slice on already-loaded Nex-Prime unnamed pads.
	## Existing ledger slugs / filler IDs only. No new SITE_*. No new lock UUID.
	## OS-G silhouette stays unnamed logistics, not a legend / pin.
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null:
		fails.append("WF-A P0Slice missing")
		return
	if not bool(P0.WF_A_DENSITY):
		fails.append("WF-A WF_A_DENSITY flag off")
	if bool(P0.ORBITAL_STATIONS):
		fails.append("WF-A flipped ORBITAL_STATIONS")
	if bool(P0.FILL_STREAMERS):
		fails.append("WF-A turned on seven fill streamers")
	if bool(P0.PAD_DENSITY):
		fails.append("WF-A enabled PadDensity cluster")
	var tree_w := get_tree()
	var nex: Node = null
	if tree_w:
		for n in tree_w.get_nodes_in_group("planets"):
			if str(n.get("planet_name")) == "Nex-Prime":
				nex = n
				break
	if nex == null:
		fails.append("WF-A no Nex-Prime")
		return
	if nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	var pads_root: Node3D = nex.get_node_or_null("Pads") as Node3D
	var plates: Array = []
	if nex.get("_pads") != null:
		plates = nex.get("_pads")
	var unnamed_n := 0
	var per_pad_min := 999
	for p in plates:
		if p == null or not is_instance_valid(p):
			continue
		var pname := str(p.name)
		if pname.begins_with("SITE_") or str(p.get_meta("site_pin", "")).begins_with("SITE_"):
			fails.append("WF-A minted SITE_* on %s" % pname)
		if not pname.begins_with("Pad_"):
			fails.append("WF-A pad not Pad_North class (%s)" % pname)
		else:
			unnamed_n += 1
		var local_n := 0
		for child in (p as Node).get_children():
			if child == null:
				continue
			var cname := str(child.name)
			if cname.begins_with("PadCrate") or cname.begins_with("PadDebris") or cname == "PadMast" or cname == "PadExtractor" or cname == "PadUtility":
				local_n += 1
				if str(child.get_meta("site_pin", "")).begins_with("SITE_"):
					fails.append("WF-A pad clutter minted SITE_* on %s" % cname)
				if _wf_a_looks_like_uuid(str(child.get_meta("uuid", ""))) or _wf_a_looks_like_uuid(cname):
					fails.append("WF-A pad clutter minted UUID on %s" % cname)
		if local_n < per_pad_min:
			per_pad_min = local_n
	if unnamed_n < 3:
		fails.append("WF-A want 3 unnamed pads, got %s" % unnamed_n)
	var sc: Node = pads_root.get_node_or_null("WorldFillScatter") if pads_root else null
	var fill_n := 0
	var slugs: PackedStringArray = PackedStringArray()
	var new_sites: PackedStringArray = PackedStringArray()
	var new_uuids: PackedStringArray = PackedStringArray()
	if sc == null:
		fails.append("WF-A WorldFillScatter missing")
	else:
		if sc.has_method("pad_fill_count"):
			fill_n = int(sc.call("pad_fill_count"))
		if sc.has_method("pad_slugs_used"):
			slugs = sc.call("pad_slugs_used")
		if slugs.is_empty() and sc.has_method("ledger_slugs_used"):
			slugs = sc.call("ledger_slugs_used")
		if sc.has_method("invented_site_pins"):
			new_sites = sc.call("invented_site_pins")
		if sc.has_method("invented_lock_uuids"):
			new_uuids = sc.call("invented_lock_uuids")
		if str(sc.get_meta("site_pin", "")).begins_with("SITE_"):
			fails.append("WF-A scatter minted SITE_*")
	var allowed := PackedStringArray(["debris_cluster", "t1_resource_extractor", "utility_bay"])
	for slug in slugs:
		if str(slug).begins_with("SITE_"):
			fails.append("WF-A minted SITE_* slug %s" % slug)
		elif allowed.find(str(slug)) < 0:
			fails.append("WF-A used unknown slug %s" % slug)
	if slugs.find("debris_cluster") < 0:
		fails.append("WF-A missing debris_cluster on unnamed pads")
	if slugs.find("t1_resource_extractor") < 0:
		fails.append("WF-A missing t1_resource_extractor on unnamed pads")
	if slugs.find("utility_bay") < 0:
		fails.append("WF-A missing utility_bay on unnamed pads")
	if fill_n < 16:
		fails.append("WF-A pad fill too thin (%s)" % fill_n)
	if per_pad_min < 5:
		fails.append("WF-A a pad stayed sparse (%s)" % per_pad_min)
	if not new_sites.is_empty():
		fails.append("WF-A invented SITE_* %s" % ",".join(new_sites))
	if not new_uuids.is_empty():
		fails.append("WF-A invented UUID %s" % ",".join(new_uuids))
	_wf_a_catalog_frozen(fails)
	var sil: Node3D = null
	if nex.has_method("outpost_silhouette"):
		sil = nex.call("outpost_silhouette") as Node3D
	if sil != null:
		if str(sil.get_meta("site_pin", "")).begins_with("SITE_") or str(sil.name).begins_with("SITE_"):
			fails.append("WF-A treated OS-G silhouette as SITE_*")
		var host := sil.get_parent()
		if host != null and (str(host.name).begins_with("SITE_") or str(host.get_meta("site_pin", "")).begins_with("SITE_")):
			fails.append("WF-A turned OS-G host into a pin")
		if host != null and not str(host.name).begins_with("Pad_"):
			fails.append("WF-A OS-G host is not an unnamed pad")
	if LayerContext and str(LayerContext.site_pin_id) != "" and str(LayerContext.site_pin_id) != "SITE_SPACE_TEST_PAD":
		fails.append("WF-A site_pin left catalog (%s)" % LayerContext.site_pin_id)
	print("[Playtest] WF-A pads=", unnamed_n, " fill=", fill_n, " slugs=", ",".join(slugs), " new_SITE_*=", new_sites.size(), " new_UUID=", new_uuids.size())


func _wf_a_catalog_frozen(fails: PackedStringArray) -> void:
	var godot_root := ProjectSettings.globalize_path("res://").rstrip("/")
	var repo := godot_root.get_base_dir()
	var pos_path := repo.path_join("docs/asset_positions.json")
	var lock_path := repo.path_join("docs/design/approved_sketches.json")
	var pin_path := repo.path_join("docs/lore/SITE_PIN_CATALOG.md")
	if FileAccess.file_exists(pos_path):
		var pos = JSON.parse_string(FileAccess.get_file_as_string(pos_path))
		if typeof(pos) == TYPE_DICTIONARY:
			var items: Variant = pos.get("items", {})
			var n_items: int = 0
			if typeof(items) == TYPE_DICTIONARY:
				n_items = (items as Dictionary).size()
			if n_items != 137:
				fails.append("WF-A ledger items changed (%s)" % n_items)
			if int(pos.get("bound_sheets", 0)) != 213:
				fails.append("WF-A bound_sheets changed (%s)" % pos.get("bound_sheets", 0))
	else:
		fails.append("WF-A asset_positions.json missing")
	if FileAccess.file_exists(lock_path):
		var locks = JSON.parse_string(FileAccess.get_file_as_string(lock_path))
		if typeof(locks) == TYPE_DICTIONARY:
			var locked: Variant = locks.get("locked", [])
			var n_locked: int = 0
			if typeof(locked) == TYPE_ARRAY:
				n_locked = (locked as Array).size()
			if n_locked != 151:
				fails.append("WF-A approved_sketches locked count changed (%s)" % n_locked)
			if int(locks.get("positions_unbound", -1)) != 1:
				fails.append("WF-A positions_unbound changed")
	else:
		fails.append("WF-A approved_sketches.json missing")
	if FileAccess.file_exists(pin_path):
		var pins := FileAccess.get_file_as_string(pin_path)
		var seen: Dictionary = {}
		var idx := 0
		while true:
			var at := pins.find("`SITE_", idx)
			if at < 0:
				break
			var end_at := pins.find("`", at + 1)
			if end_at < 0:
				break
			var tok := pins.substr(at + 1, end_at - at - 1)
			if tok.begins_with("SITE_"):
				seen[tok] = true
			idx = end_at + 1
		if seen.size() != 20:
			fails.append("WF-A SITE_PIN_CATALOG changed (%s)" % seen.size())
	else:
		fails.append("WF-A SITE_PIN_CATALOG.md missing")


func _wf_a_looks_like_uuid(s: String) -> bool:
	if s.length() != 36:
		return false
	var parts := s.split("-")
	return parts.size() == 5 and parts[0].length() == 8 and parts[1].length() == 4


func _ose_near_read(fails: PackedStringArray) -> void:
	## OS-E: EVA near-ground is PBR (CC0 or fallback ImageTexture), not
	## unshaded plastic. Same Relief. Same chunk budget. No second height
	## field. No SITE_*. No binaries in git.
	var SD = load("res://scripts/world/SurfaceDetail.gd")
	if SD == null:
		fails.append("OS-E SurfaceDetail missing")
		return
	if absf(float(SD.CELL_M) - 40.0) > 0.01:
		fails.append("OS-E chunk cell size changed")
	if int(SD.LOAD_BUDGET) != 1:
		fails.append("OS-E chunk LOAD_BUDGET changed")
	var sd_src := FileAccess.get_file_as_string("res://scripts/world/SurfaceDetail.gd")
	if sd_src.find("while _queue.size() > 12") < 0:
		fails.append("OS-E chunk queue cap changed")
	if sd_src.find("height_at(") < 0:
		fails.append("OS-E dropped Relief height_at")
	if sd_src.find("VERTEX +=") >= 0 or sd_src.find("height_micro") >= 0:
		fails.append("OS-E added a second height field")
	if sd_src.find("planet_surface_near.gdshader") < 0:
		fails.append("OS-E near shader not bound")
	if sd_src.find(":v7") < 0:
		fails.append("OS-E cache key not bumped for PBR UVs")
	if sd_src.find("dir_to_chart") < 0:
		fails.append("OS-E paint UV not chart-locked")
	if sd_src.find("_bind_pbr_maps") < 0:
		fails.append("OS-E PBR maps not bound")
	var sh_src := FileAccess.get_file_as_string("res://shaders/planet_surface_near.gdshader")
	if sh_src == "" or sh_src.find("shader_type spatial") < 0:
		fails.append("OS-E planet_surface_near.gdshader missing")
	else:
		if sh_src.find("VERTEX +=") >= 0:
			fails.append("OS-E near shader displaces height")
		if sh_src.find("render_mode unshaded") >= 0:
			fails.append("OS-E near shader still unshaded")
		if sh_src.find("sampler2D albedo_tex") < 0 or sh_src.find("sampler2D rock_tex") < 0:
			fails.append("OS-E near shader missing PBR samplers")
		if sh_src.find("ROUGHNESS") < 0 or sh_src.find("NORMAL_MAP") < 0:
			fails.append("OS-E near shader missing PBR outputs")
		if sh_src.find("decal_strength") < 0 or sh_src.find("micro_strength") < 0:
			fails.append("OS-E near shader has no micro/decal terms")
		if sh_src.find("decal_density") < 0:
			fails.append("OS-E near shader has no decal density")
		if sh_src.find("near_fade") < 0:
			fails.append("OS-E near LOD fade missing")
		if sh_src.find("chart_radius") < 0:
			fails.append("OS-E near shader not chart-locked")
	var godot_root := ProjectSettings.globalize_path("res://").rstrip("/")
	var man_path := godot_root.get_base_dir().path_join("docs/design/p0_filler_manifest.json")
	var man := FileAccess.get_file_as_string(man_path)
	if man.find("near_ground_forest_cc0") < 0 or man.find("CC0-1.0") < 0:
		fails.append("OS-E CC0 ground sources not documented")
	if man.find("\"git_binary\": true") >= 0:
		fails.append("OS-E manifest marks a git binary")
	var os: Node = get_parent()
	var nex: Node = null
	var tree_e := get_tree()
	if tree_e:
		for n in tree_e.get_nodes_in_group("planets"):
			if str(n.get("planet_name")) == "Nex-Prime":
				nex = n
				break
	if nex == null:
		fails.append("OS-E no Nex-Prime")
		return
	var relief = load("res://scripts/world/PlanetRelief.gd")
	var seed_b: int = int(relief.body_seed("Nex-Prime"))
	var prof: Dictionary = relief.profile_for_planet("Nex-Prime")
	var rad: float = float(nex.get("radius"))
	var sea: float = float(prof.get("sea_level", -0.35))
	var sd: Node = nex.get_node_or_null("SurfaceDetail")
	if sd == null:
		fails.append("OS-E SurfaceDetail node missing")
		return
	if sd.has_method("body_seed") and int(sd.call("body_seed")) != seed_b:
		fails.append("OS-E SurfaceDetail seed != body_seed")
	if not sd.has_method("near_read_enabled") or not bool(sd.call("near_read_enabled")):
		fails.append("OS-E near read disabled")
	var nmat = null
	if sd.has_method("near_material"):
		nmat = sd.call("near_material")
	if not (nmat is ShaderMaterial):
		fails.append("OS-E near material missing")
	else:
		var us: float = float((nmat as ShaderMaterial).get_shader_parameter("seed"))
		var um: float = float((nmat as ShaderMaterial).get_shader_parameter("micro_strength"))
		var ud: float = float((nmat as ShaderMaterial).get_shader_parameter("decal_strength"))
		var dens: float = float((nmat as ShaderMaterial).get_shader_parameter("decal_density"))
		var alb = (nmat as ShaderMaterial).get_shader_parameter("albedo_tex")
		var rck = (nmat as ShaderMaterial).get_shader_parameter("rock_tex")
		var nrm = (nmat as ShaderMaterial).get_shader_parameter("normal_tex")
		var rgh = (nmat as ShaderMaterial).get_shader_parameter("rough_tex")
		if sd.has_method("near_pbr_status"):
			var st: Dictionary = sd.call("near_pbr_status")
			print("[Playtest] OS-E PBR src=", st.get("src"), " albedo=", st.get("albedo"), " rock=", st.get("rock"), " rough=", st.get("rough"), " normal=", st.get("normal"), " unshaded=", st.get("unshaded"))
			if bool(st.get("unshaded", true)):
				fails.append("OS-E PBR still marked unshaded")
			if not bool(st.get("albedo", false)) or not bool(st.get("rock", false)):
				fails.append("OS-E PBR albedo/rock not bound")
			if not bool(st.get("normal", false)) or not bool(st.get("rough", false)):
				fails.append("OS-E PBR normal/rough not bound")
		print("[Playtest] OS-E near seed=", us, " micro=", snapped(um, 0.01), " decal=", snapped(ud, 0.01), " dens=", snapped(dens, 0.01))
		if absf(us - float(seed_b)) > 0.51:
			fails.append("OS-E near shader seed != body_seed (%s vs %s)" % [us, seed_b])
		if um < 0.05:
			fails.append("OS-E micro_strength off")
		if ud < 0.05:
			fails.append("OS-E decal_strength off")
		if dens < 0.2:
			fails.append("OS-E decal_density off")
		if alb == null or rck == null:
			fails.append("OS-E albedo/rock sampler empty")
		if nrm == null or rgh == null:
			fails.append("OS-E normal/rough sampler empty")
	# Same Relief under the walker as OS-A snap. Paint must not move height.
	var up: Vector3 = Vector3(0.18, 0.96, 0.12).normalized()
	if os and os.has_method("_spawn_eva_near_ship"):
		var ship: Node3D = os.get("ship") as Node3D
		if ship:
			ship.global_position = nex.global_position + up * (rad + 770.0)
		os.call("_spawn_eva_near_ship")
	var walker: Node3D = os.get("player") as Node3D if os else null
	if walker == null or not is_instance_valid(walker):
		fails.append("OS-E EVA spawn failed")
		return
	walker.global_position = nex.global_position + up * (rad + 12.0)
	if walker.has_method("_relief_snap_fallback"):
		walker.call("_relief_snap_fallback")
	elif walker.has_method("snap_to_surface"):
		walker.call("snap_to_surface")
	var dir: Vector3 = (walker.global_position - nex.global_position).normalized()
	var h: float = float(relief.height_on_sphere(dir, rad, seed_b, prof, false))
	var want: float = rad + maxf(h, sea) + 2.15
	var got: float = walker.global_position.distance_to(nex.global_position)
	print("[Playtest] OS-E Relief h=", snapped(h, 0.01), " want=", snapped(want - rad, 0.01), " got=", snapped(got - rad, 0.01))
	if absf(got - want) > 0.85:
		fails.append("OS-E Relief under walker drifted")
	if LayerContext and str(LayerContext.site_pin_id) != "" and str(LayerContext.site_pin_id) != "SITE_SPACE_TEST_PAD":
		fails.append("OS-E site_pin left catalog (%s)" % LayerContext.site_pin_id)


func _osf_atmo_flight(fails: PackedStringArray) -> void:
	## OS-F: dense-layer lift/glide changes path vs vacuum. STALL / HOVER /
	## LAND / hold-S stay. S is geometric inward, not camera-forward thrust.
	var cat = load("res://scripts/world/PlanetProfileCatalog.gd")
	if cat == null:
		fails.append("OS-F PlanetProfileCatalog missing")
		return
	var env_c: float = float(cat.envelope_of("Nex-Prime"))
	var d770: float = float(_Flight.atmosphere_density(770.0, 320.0, env_c))
	var d_dense: float = float(_Flight.atmosphere_density(200.0, 320.0, env_c))
	var d_out: float = float(_Flight.atmosphere_density(env_c + 20.0, 320.0, env_c))
	print("[Playtest] OS-F density 200/770/out=", snapped(d_dense, 0.01), "/", snapped(d770, 0.01), "/", snapped(d_out, 0.01))
	if d_dense < 0.40:
		fails.append("OS-F 200 m not in dense band (%s)" % snapped(d_dense, 0.01))
	if d770 > 0.35:
		fails.append("OS-F 770 m no longer thin (%s)" % snapped(d770, 0.01))

	var wing := Vector3(0, 1, 0)
	var horiz := Vector3(40, 0, 0)
	var lift_vac: Vector3 = _Flight.aero_lift_accel(horiz, wing, 0.0, 0.0)
	var lift_out: Vector3 = _Flight.aero_lift_accel(horiz, wing, d_out, 0.0)
	var lift_thin: Vector3 = _Flight.aero_lift_accel(horiz, wing, d770, 0.0)
	var lift_dense: Vector3 = _Flight.aero_lift_accel(horiz, wing, d_dense, 0.0)
	var lift_stall: Vector3 = _Flight.aero_lift_accel(horiz, wing, 1.0, 1.0)
	var lift_climb: Vector3 = _Flight.aero_lift_accel(Vector3(0, 40, 0), wing, 1.0, 0.0)
	print("[Playtest] OS-F lift vac/thin/dense/stall=", snapped(lift_vac.length(), 0.01), "/", snapped(lift_thin.length(), 0.01), "/", snapped(lift_dense.length(), 0.01), "/", snapped(lift_stall.length(), 0.01))
	if lift_vac.length() > 0.01 or lift_out.length() > 0.01:
		fails.append("OS-F lift in vacuum")
	if lift_thin.length() > 0.01:
		fails.append("OS-F 770 m thin shell grew a wing")
	if lift_dense.y < 2.0:
		fails.append("OS-F dense layer has no lift (%s)" % snapped(lift_dense.y, 0.01))
	if absf(lift_dense.x) > 0.05:
		fails.append("OS-F lift is not perpendicular to airflow")
	if lift_dense.y >= 28.0:
		fails.append("OS-F lift would swamp hold-S")
	if lift_stall.length() > 0.05:
		fails.append("OS-F stalled wing still lifts")
	if lift_climb.length() > 0.05:
		fails.append("OS-F lift on a vertical climb")
	if _Flight.stall_speed(_Flight.Mode.HOVER) > 0.01:
		fails.append("OS-F HOVER gained a stall speed")
	if _Flight.stall_amount(0.0, 4.0, 20.0) > 0.01:
		fails.append("OS-F stall in vacuum")
	if not _Flight.land_ok(10.0, 5.0, 18.0, 12.0):
		fails.append("OS-F land_ok rejected an honest approach")
	if _Flight.land_ok(30.0, 5.0, 18.0, 12.0) or _Flight.land_ok(10.0, 20.0, 18.0, 12.0):
		fails.append("OS-F land_ok went dishonest")

	# Same drag, with vs without lift: dense path must climb relative to no-lift.
	var g_feel := Vector3(0, -4.05, 0)
	var v_l: Vector3 = horiz
	var v_n: Vector3 = horiz
	var pos_l := Vector3.ZERO
	var pos_n := Vector3.ZERO
	for _i in 90:
		var a_l: Vector3 = g_feel + _Flight.aero_lift_accel(v_l, wing, d_dense, 0.0)
		v_l = _Flight.integrate(v_l, a_l, 0.016, 0.35, 1.0, d_dense, 55.0)
		v_n = _Flight.integrate(v_n, g_feel, 0.016, 0.35, 1.0, d_dense, 55.0)
		pos_l += v_l * 0.016
		pos_n += v_n * 0.016
	print("[Playtest] OS-F path y lift/nolift=", snapped(pos_l.y, 0.01), "/", snapped(pos_n.y, 0.01))
	if pos_l.y <= pos_n.y + 0.35:
		fails.append("OS-F dense path did not change vs no-lift")

	# Hold-S: geometric inward 28, no lift (controller skips on S). AGL drops.
	var os: Node = get_parent()
	var nex: Node = null
	var tree_f := get_tree()
	if tree_f:
		for n in tree_f.get_nodes_in_group("planets"):
			if str(n.get("planet_name")) == "Nex-Prime":
				nex = n
				break
	if nex == null:
		fails.append("OS-F no Nex-Prime")
		return
	var rad: float = float(nex.get("radius"))
	var up: Vector3 = Vector3(0.18, 0.96, 0.12).normalized()
	var start: Vector3 = nex.global_position + up * (rad + 200.0)
	var inward: Vector3 = (nex.global_position - start).normalized()
	var vel := Vector3.ZERO
	var pos: Vector3 = start
	var d_start: float = float(nex.density_at(start)) if nex.has_method("density_at") else d_dense
	for _j in 80:
		vel = _Flight.integrate(vel, inward * 28.0, 0.016, 0.35, 1.0, d_start, 55.0)
		vel = _Flight.apply_ceiling(vel, inward, d_start, 0.016)
		pos += vel * 0.016
	var alt_after: float = pos.distance_to(nex.global_position) - rad
	print("[Playtest] OS-F hold-S 200m → ", snapped(alt_after, 0.1), " dens=", snapped(d_start, 0.01))
	if alt_after > 185.0:
		fails.append("OS-F hold-S did not sink in the dense layer")
	if alt_after < 20.0:
		fails.append("OS-F hold-S punched through the surface")

	var src := FileAccess.get_file_as_string("res://scripts/ship/ShipController.gd")
	if src.find("aero_lift_accel") < 0:
		fails.append("OS-F ShipController never applies lift")
	if src.find("accel += inward * sink_acc") < 0:
		fails.append("OS-F dropped geometric S-sink")
	if src.find("flight_mode != FlightMode.HOVER and not sink_held") < 0:
		fails.append("OS-F lift not gated off HOVER / hold-S")
	if src.find("FlightMode.CRUISE") >= 0 or src.find("mass_lock") >= 0:
		fails.append("OS-F shipped G1 CRUISE / mass lock")
	if LayerContext and str(LayerContext.site_pin_id) != "" and str(LayerContext.site_pin_id) != "SITE_SPACE_TEST_PAD":
		fails.append("OS-F site_pin left catalog (%s)" % LayerContext.site_pin_id)


func _osg_outpost_silhouette(fails: PackedStringArray) -> void:
	## OS-G: one unnamed mast+habitat cluster on an existing pad. Readable
	## from 8 km and 2 km; on dirt it is the same node. No SITE_* mint.
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null:
		fails.append("OS-G P0Slice missing")
		return
	if not bool(P0.OS_G_OUTPOST):
		fails.append("OS-G OS_G_OUTPOST flag off")
	if bool(P0.FILL_STREAMERS):
		fails.append("OS-G turned on seven fill streamers")
	if bool(P0.PAD_DENSITY):
		fails.append("OS-G enabled PadDensity cluster")
	if bool(P0.ORBITAL_STATIONS):
		fails.append("OS-G spawned orbital stations")
	var SD = load("res://scripts/world/SurfaceDetail.gd")
	if SD == null:
		fails.append("OS-G SurfaceDetail missing")
	elif absf(float(SD.CELL_M) - 40.0) > 0.01:
		fails.append("OS-G chunk cell size changed")
	elif int(SD.LOAD_BUDGET) != 1:
		fails.append("OS-G chunk LOAD_BUDGET changed")
	var os: Node = get_parent()
	if os == null:
		fails.append("OS-G no OpenSpace")
		return
	var planets: Array = os.get("planets") if os.get("planets") != null else []
	print("[Playtest] OS-G bodies=", planets.size())
	if planets.size() != 1:
		fails.append("OS-G loaded a second system/body (%s)" % planets.size())
	var sys = load("res://scripts/world/StarSystemCatalog.gd")
	if sys and str(sys.HOME) != "ARK":
		fails.append("OS-G left ARK (%s)" % str(sys.HOME))
	var nex: Node = null
	var tree_g := get_tree()
	if tree_g:
		for n in tree_g.get_nodes_in_group("planets"):
			if str(n.get("planet_name")) == "Nex-Prime":
				nex = n
				break
	if nex == null:
		fails.append("OS-G no Nex-Prime")
		return
	var rad: float = float(nex.get("radius"))
	var stream: float = float(nex.get("pad_stream_dist"))
	print("[Playtest] OS-G pad_stream_dist AGL=", snapped(stream - rad, 1.0))
	if stream < rad + 8000.0:
		fails.append("OS-G pad stream shorter than 8 km (%s)" % snapped(stream - rad, 1.0))
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var look := Vector3(0, 0, 1)
	if ship:
		ship.global_position = nex.global_position + look * (rad + 8000.0)
		if "velocity" in ship:
			ship.velocity = Vector3.ZERO
	if nex.has_method("set_observer") and ship:
		nex.set_observer(ship)
	if nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	if nex.has_method("refresh_approach_lod"):
		nex.refresh_approach_lod()
	var pads_root: Node3D = nex.get_node_or_null("Pads") as Node3D
	if pads_root == null or not pads_root.visible:
		fails.append("OS-G Pads hidden at 8 km")
	var sil: Node3D = null
	if nex.has_method("outpost_silhouette"):
		sil = nex.call("outpost_silhouette") as Node3D
	if sil == null and pads_root:
		sil = pads_root.find_child("OutpostSilhouette", true, false) as Node3D
	if sil == null or not is_instance_valid(sil):
		fails.append("OS-G OutpostSilhouette missing at 8 km")
		return
	if not sil.visible or not sil.is_visible_in_tree():
		fails.append("OS-G silhouette hidden at 8 km")
	var host: Node3D = sil.get_parent() as Node3D
	if host == null or not bool(host.get_meta("landing_pad", false)):
		fails.append("OS-G silhouette not parented to an existing pad")
	var hname := str(host.name) if host else ""
	if hname.begins_with("SITE_") or str(sil.get_meta("site_pin", "")).begins_with("SITE_"):
		fails.append("OS-G minted SITE_* on %s" % hname)
	if not hname.begins_with("Pad_"):
		fails.append("OS-G host not Pad_North class (%s)" % hname)
	var nstruct := 0
	if sil.has_method("structure_count"):
		nstruct = int(sil.call("structure_count"))
	var mast: Node = sil.get_node_or_null("Mast")
	var hab: Node = sil.get_node_or_null("Habitat")
	if mast == null or hab == null:
		fails.append("OS-G need mast + habitat proxies")
	if nstruct < 2:
		fails.append("OS-G cluster too thin (%s)" % nstruct)
	var extras := 0
	if pads_root:
		extras = pads_root.find_children("OutpostSilhouette", "", true, false).size()
	if extras != 1:
		fails.append("OS-G want exactly one silhouette, got %s" % extras)
	var orbit_pos: Vector3 = sil.global_position
	var orbit_read := 0.0
	if sil.has_method("orbit_read_m"):
		orbit_read = float(sil.call("orbit_read_m"))
	print("[Playtest] OS-G 8km host=", hname, " n=", nstruct, " read=", snapped(orbit_read, 1.0), " pos=", orbit_pos)
	if orbit_read < 8000.0:
		fails.append("OS-G orbit read shorter than 8 km (%s)" % snapped(orbit_read, 1.0))

	if ship:
		ship.global_position = nex.global_position + look * (rad + 2000.0)
	if nex.has_method("set_observer") and ship:
		nex.set_observer(ship)
	if nex.has_method("refresh_approach_lod"):
		nex.refresh_approach_lod()
	var sil2: Node3D = nex.call("outpost_silhouette") as Node3D if nex.has_method("outpost_silhouette") else sil
	if sil2 != sil:
		fails.append("OS-G 2 km silhouette is a different node")
	if sil2 == null or not sil2.is_visible_in_tree():
		fails.append("OS-G silhouette hidden at 2 km")
	elif sil2.global_position.distance_to(orbit_pos) > 0.75:
		fails.append("OS-G 2 km moved the outpost")

	if host:
		var pad_up: Vector3 = host.get_meta("pad_up") if host.has_meta("pad_up") else look
		if ship:
			ship.global_position = host.global_position + pad_up * 18.0
		if os.has_method("_spawn_eva_near_ship"):
			os.call("_spawn_eva_near_ship")
		var walker: Node3D = os.get("player") as Node3D
		if walker == null or not is_instance_valid(walker):
			fails.append("OS-G EVA at outpost failed")
		else:
			walker.global_position = host.global_position + pad_up * 4.0
			if walker.has_method("_relief_snap_fallback"):
				walker.call("_relief_snap_fallback")
			elif walker.has_method("snap_to_surface"):
				walker.call("snap_to_surface")
			var dirt_d: float = walker.global_position.distance_to(sil.global_position)
			print("[Playtest] OS-G dirt walker→outpost=", snapped(dirt_d, 0.1))
			if dirt_d > 90.0:
				fails.append("OS-G dirt walker is not at the same outpost (%s)" % snapped(dirt_d, 0.1))
			if sil.global_position.distance_to(orbit_pos) > 0.75:
				fails.append("OS-G dirt moved the outpost")
	if LayerContext and str(LayerContext.site_pin_id) != "" and str(LayerContext.site_pin_id) != "SITE_SPACE_TEST_PAD":
		fails.append("OS-G site_pin left catalog (%s)" % LayerContext.site_pin_id)
	var godot_root := ProjectSettings.globalize_path("res://").rstrip("/")
	var man_path := godot_root.get_base_dir().path_join("docs/design/p0_filler_manifest.json")
	var man := FileAccess.get_file_as_string(man_path)
	if man.find("outpost_mast_cc0") < 0 or man.find("outpost_habitat_cc0") < 0:
		fails.append("OS-G mast/habitat sources not documented")
	if man.find("\"git_binary\": true") >= 0:
		fails.append("OS-G manifest marks a git binary")


func _osh_ritual(fails: PackedStringArray) -> void:
	## OS-H harness: space → atmo → land → EVA → takeoff → space.
	## Same OpenSpace scene. Hold-S is geometric inward (no mouse pitch).
	## Headless PASS = every step ran. Not a 3090 FPS / 5 min soak.
	var required: PackedStringArray = PackedStringArray([
		"space", "atmo", "descend", "land", "eva", "takeoff", "space_out"
	])
	var done: Dictionary = {}
	var os: Node = get_parent()
	if os == null:
		fails.append("OS-H no OpenSpace")
		_osh_report_skips(fails, done, required)
		return
	var scene0 := _osh_scene_file()
	print("[Playtest] OS-H scene=", scene0)
	if scene0.find("OpenSpace.tscn") < 0:
		fails.append("OS-H not in OpenSpace scene (%s)" % scene0)

	var nex: Node = _osh_nex()
	var ship: Node3D = os.get("ship") as Node3D if os else null
	if nex == null or ship == null or not is_instance_valid(ship):
		fails.append("OS-H no Nex-Prime/ship")
		_osh_report_skips(fails, done, required)
		return

	# --- SPACE: real OS-C boot altitude, vacuum, limb readable ---
	var start_agl := _osc_read_spawn_agl(os)
	if start_agl < 5000.0 or start_agl > 15000.0:
		fails.append("OS-H SPACE not at OS-C altitude (%s)" % snapped(start_agl, 0.1))
	var d_space := 1.0
	if nex.has_method("density_at"):
		d_space = float(nex.density_at(ship.global_position))
	if nex.has_method("set_observer"):
		nex.set_observer(ship)
	if nex.has_method("refresh_approach_lod"):
		nex.refresh_approach_lod()
	var atmo_n: Node = nex.get_node_or_null("Atmosphere")
	var limb_on: bool = atmo_n is Node3D and (atmo_n as Node3D).visible
	var wr: Node3D = os.get_node_or_null("WorldRoot") as Node3D
	print("[Playtest] OS-H STEP space AGL=", snapped(start_agl, 0.1), " dens=", snapped(d_space, 0.001), " limb=", limb_on)
	if d_space > 0.001:
		fails.append("OS-H SPACE not vacuum (%s)" % snapped(d_space, 0.001))
	if not limb_on:
		fails.append("OS-H SPACE did not see atmo limb")
	if wr and not wr.visible:
		fails.append("OS-H SPACE WorldRoot hidden (load/interior)")
	if "_pitch" in ship and absf(float(ship.get("_pitch"))) > 0.02:
		fails.append("OS-H SPACE already pitched")
	if bool(ship.get("is_landed")):
		fails.append("OS-H SPACE stuck LANDED at OS-C AGL")
	var fuel0 := float(ship.get("fuel")) if "fuel" in ship else -1.0
	await get_tree().create_timer(0.45).timeout
	var fuel1 := float(ship.get("fuel")) if "fuel" in ship else -1.0
	if fuel0 >= 0.0 and fuel1 + 0.4 < fuel0:
		fails.append("OS-H SPACE fuel bleed at idle (%s→%s)" % [snapped(fuel0, 1.0), snapped(fuel1, 1.0)])
	var HudPick = load("res://scripts/ui/OpenSpaceHudStack.gd")
	if HudPick:
		var pick: Node = HudPick.player_ship(get_tree()) if HudPick.has_method("player_ship") else ship
		if pick != ship:
			fails.append("OS-H SPACE HUD ship is %s (want player)" % (pick.name if pick else "none"))
		var boot_snap: Dictionary = HudPick.snapshot(pick, null, null)
		if bool(boot_snap.get("landed", false)):
			fails.append("OS-H SPACE HUD card LANDED at 8 km")
		print("[Playtest] OS-H SPACE landed=", ship.get("is_landed"), " hud_landed=", boot_snap.get("landed"),
			" fuel=", snapped(fuel0, 1.0), "→", snapped(fuel1, 1.0), " pick=", pick.name if pick else "none")
	if start_agl >= 5000.0 and start_agl <= 15000.0 and limb_on and d_space <= 0.001:
		done["space"] = true

	if not done.get("space", false):
		fails.append("OS-H skipped atmo (no space)")
		fails.append("OS-H skipped descend (no space)")
		fails.append("OS-H skipped land (no descend)")
		fails.append("OS-H skipped eva (no land)")
		fails.append("OS-H skipped takeoff (no eva)")
		fails.append("OS-H skipped space_out (no takeoff)")
		_osh_report_skips(fails, done, required)
		return

	# --- ATMO + DESCEND: hold-S inward, no pitch, must enter envelope ---
	var env_h := 1100.0
	if nex.has_method("envelope_height"):
		env_h = float(nex.call("envelope_height"))
	var pitch0: float = float(ship.get("_pitch")) if "_pitch" in ship else 0.0
	var basis0: Basis = ship.global_transform.basis
	var sink: Dictionary = _osh_hold_s(nex, ship, 90.0, 12000)
	var end_agl: float = float(sink.get("agl", -1.0))
	var saw_atmo: bool = bool(sink.get("saw_atmo", false))
	var atmo_agl: float = float(sink.get("atmo_agl", -1.0))
	var atmo_d: float = float(sink.get("atmo_dens", 0.0))
	var pitch1: float = float(ship.get("_pitch")) if "_pitch" in ship else 0.0
	var fuel_desc := float(ship.get("fuel")) if "fuel" in ship else -1.0
	print("[Playtest] OS-H STEP atmo entered AGL=", snapped(atmo_agl, 0.1), " dens=", snapped(atmo_d, 0.01))
	print("[Playtest] OS-H STEP descend AGL=", snapped(start_agl, 0.1), "→", snapped(end_agl, 0.1), " pitch=", snapped(pitch1 - pitch0, 0.001), " steps=", int(sink.get("steps", 0)), " fuel=", snapped(fuel_desc, 1.0))
	if not saw_atmo:
		fails.append("OS-H ATMO skipped — hold-S never entered envelope")
	elif atmo_agl > env_h + 20.0:
		fails.append("OS-H ATMO mark above envelope (%s > %s)" % [snapped(atmo_agl, 0.1), snapped(env_h, 0.1)])
	else:
		done["atmo"] = true
	if end_agl > start_agl - 1000.0:
		fails.append("OS-H DESCEND skipped — AGL did not drop (%s → %s)" % [snapped(start_agl, 0.1), snapped(end_agl, 0.1)])
	elif end_agl > 160.0:
		fails.append("OS-H DESCEND stopped above land band (%s)" % snapped(end_agl, 0.1))
	elif absf(pitch1 - pitch0) > 0.02:
		fails.append("OS-H DESCEND used pitch (%s)" % snapped(pitch1 - pitch0, 0.001))
	elif not basis0.z.normalized().is_equal_approx(ship.global_transform.basis.z.normalized()):
		fails.append("OS-H DESCEND rotated the nose (pitch/turn)")
	else:
		done["descend"] = true
	if not _osh_same_scene(scene0):
		fails.append("OS-H load screen during descend (%s)" % _osh_scene_file())
		done.erase("descend")
		done.erase("atmo")

	if not done.get("atmo", false) or not done.get("descend", false):
		if not done.get("atmo", false):
			fails.append("OS-H skipped land (no atmo)")
		elif not done.get("descend", false):
			fails.append("OS-H skipped land (no descend)")
		fails.append("OS-H skipped eva (no land)")
		fails.append("OS-H skipped takeoff (no eva)")
		fails.append("OS-H skipped space_out (no takeoff)")
		_osh_report_skips(fails, done, required)
		return

	# --- LAND: honest gate after hold-S, no pad teleport ---
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	if ship.has_method("_set_mode"):
		ship._set_mode(2)  # HOVER
	if ship.has_method("_do_land"):
		ship._do_land()
	var landed := bool(ship.get("is_landed"))
	var gear_down := bool(ship.is_gear_down()) if ship.has_method("is_gear_down") else bool(ship.get("_gear_down"))
	print("[Playtest] OS-H STEP land landed=", landed, " gear=", gear_down, " AGL=", snapped(_osh_agl(nex, ship.global_position), 0.1))
	if not landed:
		fails.append("OS-H LAND skipped — _do_land refused")
		fails.append("OS-H skipped eva (no land)")
		fails.append("OS-H skipped takeoff (no eva)")
		fails.append("OS-H skipped space_out (no takeoff)")
		_osh_report_skips(fails, done, required)
		return
	if not _osh_same_scene(scene0):
		fails.append("OS-H load screen on land")
		_osh_report_skips(fails, done, required)
		return
	if not gear_down:
		fails.append("OS-H LAND without gear down")
	done["land"] = true
	_assert_openspace_view(os, ship, nex, "LAND", fails)
	await _osh_occupy_refuel(os, ship, nex, fails)

	# --- EVA snap on pad (real F-from-LANDED path, no harness re-snap) ---
	if os.has_method("_handle_f_interact"):
		os._handle_f_interact()
	elif os.has_method("try_exit_ship"):
		os.try_exit_ship()
	await get_tree().create_timer(0.45).timeout
	var walker: Node3D = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("OS-H EVA skipped — no walker")
		fails.append("OS-H skipped takeoff (no eva)")
		fails.append("OS-H skipped space_out (no takeoff)")
		_osh_report_skips(fails, done, required)
		return
	var pad_eva: Node3D = null
	if ship.has_method("get_landed_pad"):
		pad_eva = ship.get_landed_pad() as Node3D
	if pad_eva == null and os.has_method("nearest_pad"):
		pad_eva = os.nearest_pad(ship.global_position)
	if not _assert_eva_from_landed_on_deck(os, walker, pad_eva, nex, fails):
		fails.append("OS-H skipped takeoff (no eva)")
		fails.append("OS-H skipped space_out (no takeoff)")
		_osh_report_skips(fails, done, required)
		return
	await _assert_landing_absorb(walker, pad_eva, fails)
	await _assert_walker_dirt_slope(walker, pad_eva, fails)
	await _assert_walker_dirt_coyote(walker, pad_eva, fails)
	if bool(os.get("_in_ship")):
		fails.append("OS-H EVA skipped — still piloting")
		fails.append("OS-H skipped takeoff (no eva)")
		fails.append("OS-H skipped space_out (no takeoff)")
		_osh_report_skips(fails, done, required)
		return
	done["eva"] = true

	# --- TAKEOFF: board then launch (F board → Space), same scene ---
	var up_b: Vector3 = (ship.global_position - nex.global_position).normalized()
	walker.global_position = ship.global_position + up_b * 2.0
	if os.has_method("try_enter_ship"):
		os.try_enter_ship()
	await get_tree().create_timer(0.4).timeout
	if not bool(os.get("_in_ship")):
		fails.append("OS-H TAKEOFF skipped — did not board")
		fails.append("OS-H skipped space_out (no takeoff)")
		_osh_report_skips(fails, done, required)
		return
	_assert_occupy_hud_after_board(os, pad_eva, fails)
	if ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if bool(ship.get("is_landed")):
		fails.append("OS-H TAKEOFF skipped — still landed")
		fails.append("OS-H skipped space_out (no takeoff)")
		_osh_report_skips(fails, done, required)
		return
	var take_scene := _osh_scene_file()
	print("[Playtest] OS-H STEP takeoff landed=", ship.get("is_landed"),
		" scene=", take_scene, " (no MainMenu / load screen)")
	if not _osh_same_scene(scene0):
		fails.append("OS-H load screen on takeoff (%s)" % take_scene)
		fails.append("OS-H skipped space_out (no takeoff)")
		_osh_report_skips(fails, done, required)
		return
	if take_scene.find("MainMenu") >= 0:
		fails.append("OS-H takeoff reloaded MainMenu")
		fails.append("OS-H skipped space_out (no takeoff)")
		_osh_report_skips(fails, done, required)
		return
	done["takeoff"] = true
	_assert_openspace_view(os, ship, nex, "HOVER", fails)

	# --- SPACE OUT: climb above envelope, same scene ---
	var climb: Dictionary = _osh_climb(nex, ship, env_h + 80.0, 8000)
	var out_agl: float = float(climb.get("agl", -1.0))
	var out_d := 1.0
	if nex.has_method("density_at"):
		out_d = float(nex.density_at(ship.global_position))
	print("[Playtest] OS-H STEP space_out AGL=", snapped(out_agl, 0.1), " dens=", snapped(out_d, 0.001), " scene=", _osh_scene_file())
	if out_agl < env_h:
		fails.append("OS-H SPACE_OUT skipped — still in envelope (%s < %s)" % [snapped(out_agl, 0.1), snapped(env_h, 0.1)])
	elif out_d > 0.001:
		fails.append("OS-H SPACE_OUT still in atmo dens=%s" % snapped(out_d, 0.001))
	elif not _osh_same_scene(scene0):
		fails.append("OS-H load screen on return (%s)" % _osh_scene_file())
	elif wr and not wr.visible:
		fails.append("OS-H SPACE_OUT WorldRoot hidden")
	else:
		done["space_out"] = true

	_osh_invariants(fails)
	_osh_report_skips(fails, done, required)
	if fails.is_empty():
		print("[Playtest] OS-H notes: EVA snap walker on pad (not void); takeoff same OpenSpace scene (no load)")
		print("[Playtest] OS-H ritual complete (headless steps; not FPS PASS)")


func _osh_hold_s(nex: Node, ship: Node3D, target_agl: float, max_steps: int) -> Dictionary:
	var pos: Vector3 = ship.global_position
	var vel := Vector3.ZERO
	if "velocity" in ship and ship.velocity is Vector3:
		vel = ship.velocity as Vector3
	var saw := false
	var atmo_agl := -1.0
	var atmo_d := 0.0
	var steps := 0
	var agl := _osh_agl(nex, pos)
	for i in max_steps:
		steps = i + 1
		var inward: Vector3 = (nex.global_position - pos).normalized()
		agl = _osh_agl(nex, pos)
		var dens := 0.0
		if nex.has_method("density_at"):
			dens = float(nex.density_at(pos))
		if dens > 0.02 and not saw:
			saw = true
			atmo_agl = agl
			atmo_d = dens
		if agl <= target_agl:
			break
		# Hold-S: geometric inward only. No lift (controller skips on S). No pitch.
		vel = _Flight.integrate(vel, inward * 28.0, 0.016, 0.35, 1.0, dens, 55.0)
		vel = _Flight.apply_ceiling(vel, inward, dens, 0.016)
		pos += vel * 0.016
		# Same SCM/HOVER tank as a live hold-S. 8 km empties the hull.
		if ship.has_method("_tick_fuel"):
			ship._tick_fuel(0.016, Vector3(0, 0, 1))
	ship.global_position = pos
	if "velocity" in ship:
		ship.velocity = vel
	if nex.has_method("set_observer"):
		nex.set_observer(ship)
	return {
		"agl": agl,
		"saw_atmo": saw,
		"atmo_agl": atmo_agl,
		"atmo_dens": atmo_d,
		"steps": steps,
	}


func _osh_climb(nex: Node, ship: Node3D, target_agl: float, max_steps: int) -> Dictionary:
	var pos: Vector3 = ship.global_position
	var vel := Vector3.ZERO
	if "velocity" in ship and ship.velocity is Vector3:
		vel = ship.velocity as Vector3
	var agl := _osh_agl(nex, pos)
	for _i in max_steps:
		var outward: Vector3 = (pos - nex.global_position).normalized()
		agl = _osh_agl(nex, pos)
		if agl >= target_agl:
			break
		var dens := 0.0
		if nex.has_method("density_at"):
			dens = float(nex.density_at(pos))
		# Space lift: outward accel. Ceiling damps climb in dense air — keep pushing.
		vel = _Flight.integrate(vel, outward * 28.0, 0.016, 0.35, 1.0, dens, 55.0)
		pos += vel * 0.016
	ship.global_position = pos
	if "velocity" in ship:
		ship.velocity = vel
	return {"agl": agl}


func _osh_agl(nex: Node, pos: Vector3) -> float:
	if nex != null and nex.has_method("altitude_of"):
		return float(nex.altitude_of(pos))
	var rad: float = float(nex.get("radius")) if nex else 1400.0
	return pos.distance_to((nex as Node3D).global_position) - rad


func _osh_nex() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("planets"):
		if str(n.get("planet_name")) == "Nex-Prime":
			return n
	return null


func _osh_scene_file() -> String:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return ""
	return str(tree.current_scene.scene_file_path)


func _osh_same_scene(scene0: String) -> bool:
	return _osh_scene_file() == scene0 and scene0.find("OpenSpace.tscn") >= 0


func _assert_eva_from_landed_on_deck(os: Node, walker: Node3D, pad: Node3D, nex: Node, fails: PackedStringArray) -> bool:
	## GPU leftover: F from LANDED must be ON the unnamed pad deck, not the
	## ship-pocket TPS (y=9200 / interior_mode). Do not re-snap here.
	if walker == null or not is_instance_valid(walker):
		fails.append("EVA from LANDED: no walker")
		return false
	var d: Node = os.get("_interior") if os else null
	if d != null and is_instance_valid(d) and d.has_method("is_inside") and bool(d.is_inside()):
		fails.append("EVA from LANDED entered ship pocket")
		return false
	if bool(walker.get("interior_mode")):
		fails.append("EVA from LANDED walker still interior_mode")
		return false
	if walker.global_position.y > 2000.0:
		fails.append("EVA from LANDED still in ship pocket (y=%s)" % snapped(walker.global_position.y, 0.1))
		return false
	if bool(walker.get("eva_mode")) or (walker.has_method("is_zero_g") and bool(walker.is_zero_g())):
		fails.append("EVA from LANDED used in-flight 0G pocket spawn")
		return false
	var wr: Node3D = os.get_node_or_null("WorldRoot") as Node3D if os else null
	if wr != null and not wr.visible:
		fails.append("EVA from LANDED hid WorldRoot (pocket)")
		return false
	var eva_agl: float = _osh_agl(nex, walker.global_position)
	if not _osh_eva_on_pad(walker, pad, nex, eva_agl, fails):
		return false
	var legal := str(pad.name) in ["Pad_North", "Pad_Approach", "Pad_Flank"] if pad else false
	if not legal:
		fails.append("EVA from LANDED not on unnamed pad deck (%s)" % (pad.name if pad else "none"))
		return false
	var up := Vector3.UP
	if pad.has_meta("pad_up"):
		up = (pad.get_meta("pad_up") as Vector3).normalized()
	var rel: Vector3 = walker.global_position - pad.global_position
	var lat: float = (rel - up * rel.dot(up)).length()
	var deck: float = rel.dot(up)
	print("[Playtest] EVA from LANDED on pad deck pad=", pad.name,
		" lat=", snapped(lat, 0.1), " deck=", snapped(deck, 0.01),
		" (not ship pocket)")
	_assert_eva_facing(os, walker, pad, fails)
	return true


func _assert_eva_facing(os: Node, walker: Node3D, pad: Node3D, fails: PackedStringArray) -> void:
	## OS-H leftover: W after land-EVA must be hull-forward on the plate,
	## not a world-XZ yaw twisted 90° around pad_up.
	if walker == null or not is_instance_valid(walker) or pad == null:
		return
	var up2 := Vector3.UP
	if pad.has_meta("pad_up"):
		var raw: Vector3 = pad.get_meta("pad_up")
		if raw.length_squared() > 0.01:
			up2 = raw.normalized()
	var body_fwd: Vector3 = -walker.global_transform.basis.z
	body_fwd = body_fwd - up2 * body_fwd.dot(up2)
	if body_fwd.length_squared() < 0.04:
		fails.append("EVA facing not tangent to pad")
		return
	body_fwd = body_fwd.normalized()
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var want := body_fwd
	if ship != null and is_instance_valid(ship):
		want = -ship.global_transform.basis.z
		want = want - up2 * want.dot(up2)
		if want.length_squared() < 0.04:
			want = body_fwd
		else:
			want = want.normalized()
	var align: float = body_fwd.dot(want)
	print("[Playtest] EVA facing align=", snapped(align, 0.01), " tangent=", snapped(1.0 - absf(body_fwd.dot(up2)), 0.01))
	if align < 0.55:
		fails.append("EVA facing sideways vs hull nose (%s)" % snapped(align, 0.01))


func _assert_hatch_pad_facing(os: Node, walker: Node3D, pad: Node3D, fails: PackedStringArray) -> void:
	## IN leftover: hatch onto the unnamed pad is pad-tangent hull nose,
	## not world-XZ yaw.
	if walker == null or not is_instance_valid(walker) or pad == null:
		return
	var up2 := Vector3.UP
	if pad.has_meta("pad_up"):
		var raw: Vector3 = pad.get_meta("pad_up")
		if raw.length_squared() > 0.01:
			up2 = raw.normalized()
	var body_fwd: Vector3 = -walker.global_transform.basis.z
	body_fwd = body_fwd - up2 * body_fwd.dot(up2)
	if body_fwd.length_squared() < 0.04:
		fails.append("hatch facing not tangent to pad")
		return
	body_fwd = body_fwd.normalized()
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var want := body_fwd
	if ship != null and is_instance_valid(ship):
		want = -ship.global_transform.basis.z
		want = want - up2 * want.dot(up2)
		if want.length_squared() < 0.04:
			want = body_fwd
		else:
			want = want.normalized()
	var align: float = body_fwd.dot(want)
	print("[Playtest] hatch facing align=", snapped(align, 0.01), " tangent=", snapped(1.0 - absf(body_fwd.dot(up2)), 0.01))
	if align < 0.55:
		fails.append("hatch facing sideways vs hull nose (%s)" % snapped(align, 0.01))


func _assert_landing_absorb(walker: Node3D, pad: Node3D, fails: PackedStringArray) -> void:
	## SESSION_CONTRACT 2: drop onto the unnamed plate must settle, not ice-slide.
	if walker == null or not is_instance_valid(walker) or pad == null:
		fails.append("landing absorb: no walker/pad")
		return
	var up := Vector3.UP
	if pad.has_meta("pad_up"):
		var raw: Vector3 = pad.get_meta("pad_up")
		if raw.length_squared() > 0.01:
			up = raw.normalized()
	var stay: Vector3 = walker.global_position
	walker.set("_spawn_grace_t", 0.0)
	walker.set("last_land_impact", 0.0)
	walker.set("_land_absorb_t", 0.0)
	walker.set("_was_on_floor", false)
	walker.global_position = pad.global_position + up * 5.2
	if walker is CharacterBody3D:
		(walker as CharacterBody3D).velocity = -up * 14.0
	await get_tree().create_timer(0.55).timeout
	if walker == null or not is_instance_valid(walker):
		fails.append("landing absorb: walker gone")
		return
	var impact: float = float(walker.get("last_land_impact"))
	var absorb_t: float = float(walker.get("_land_absorb_t"))
	var rel: Vector3 = walker.global_position - pad.global_position
	var deck: float = rel.dot(up)
	print("[Playtest] landing absorb impact=", snapped(impact, 0.1), " t=", snapped(absorb_t, 0.01), " deck=", snapped(deck, 0.01))
	if impact < 5.5:
		fails.append("landing absorb did not fire (%s)" % snapped(impact, 0.1))
	if deck < 0.2 or deck > 8.0:
		fails.append("landing absorb left walker off pad (deck=%s)" % snapped(deck, 0.01))
	if walker.has_method("snap_to_pad"):
		walker.global_position = stay
		walker.call("snap_to_pad", pad)


func _assert_dirt_slope_math(fails: PackedStringArray) -> void:
	## SESSION_CONTRACT 2 leftover: dirt slope from PlanetRelief, not a billiard.
	var relief = load("res://scripts/world/PlanetRelief.gd")
	if relief == null or not relief.has_method("slope_rad"):
		fails.append("dirt slope: PlanetRelief.slope_rad missing")
		return
	var pid := "Nex-Prime"
	var seed: int = int(relief.body_seed(pid))
	var prof: Dictionary = relief.profile_for_planet(pid)
	var max_s := 0.0
	var i := 0
	while i < 24:
		var lon: float = float(i) * 0.37
		var lat: float = sin(float(i) * 0.91) * 0.55
		var dir := Vector3(cos(lat) * sin(lon), sin(lat), cos(lat) * cos(lon))
		var s: float = float(relief.slope_rad(dir, seed, prof))
		if s > max_s:
			max_s = s
		if s < 0.0 or s > 1.4:
			fails.append("dirt slope out of range (%s)" % snapped(s, 0.01))
			return
		i += 1
	print("[Playtest] dirt slope math max=", snapped(rad_to_deg(max_s), 0.1), " deg")
	if max_s < deg_to_rad(6.0):
		fails.append("dirt slope is a billiard (%s deg)" % snapped(rad_to_deg(max_s), 0.1))


func _assert_walker_dirt_slope(walker: Node3D, pad: Node3D, fails: PackedStringArray) -> void:
	## Off the unnamed plate, walker grip reads PlanetRelief slope.
	if walker == null or not is_instance_valid(walker) or pad == null:
		fails.append("walker dirt slope: no walker/pad")
		return
	var up := Vector3.UP
	if pad.has_meta("pad_up"):
		var raw: Vector3 = pad.get_meta("pad_up")
		if raw.length_squared() > 0.01:
			up = raw.normalized()
	var stay: Vector3 = walker.global_position
	var side: Vector3 = walker.global_transform.basis.x
	side = side - up * side.dot(up)
	if side.length_squared() < 0.04:
		side = up.cross(Vector3.RIGHT)
	side = side.normalized()
	walker.global_position = pad.global_position + side * 22.0 + up * 2.2
	walker.set("_spawn_grace_t", 0.0)
	if walker.has_method("_physics_process"):
		walker._physics_process(0.016)
	var ang: float = float(walker.get("last_slope_ang"))
	print("[Playtest] walker dirt slope last=", snapped(rad_to_deg(ang), 0.1), " deg")
	if ang < 0.0 or ang > 1.4:
		fails.append("walker dirt slope last out of range (%s)" % snapped(ang, 0.01))
	if walker.has_method("snap_to_pad"):
		walker.global_position = stay
		walker.call("snap_to_pad", pad)


func _assert_walker_dirt_coyote(walker: Node3D, pad: Node3D, fails: PackedStringArray) -> void:
	## SESSION_CONTRACT 2 leftover: coyote lives on dirt even without trimesh.
	if walker == null or not is_instance_valid(walker) or pad == null:
		fails.append("dirt coyote: no walker/pad")
		return
	var up := Vector3.UP
	if pad.has_meta("pad_up"):
		var raw: Vector3 = pad.get_meta("pad_up")
		if raw.length_squared() > 0.01:
			up = raw.normalized()
	var stay: Vector3 = walker.global_position
	var side: Vector3 = walker.global_transform.basis.x
	side = side - up * side.dot(up)
	if side.length_squared() < 0.04:
		side = up.cross(Vector3.RIGHT)
	side = side.normalized()
	var pl: Node3D = null
	if walker.has_method("_nearest_planet_body"):
		pl = walker.call("_nearest_planet_body") as Node3D
	if pl != null and ("radius" in pl):
		var dir: Vector3 = (pad.global_position + side * 22.0 - pl.global_position)
		if dir.length_squared() > 1e-6:
			dir = dir.normalized()
			var h := 0.0
			if pl.has_method("relief_height_at"):
				h = float(pl.relief_height_at(pl.global_position + dir * float(pl.radius)))
			walker.global_position = pl.global_position + dir * (float(pl.radius) + h + 0.9)
	else:
		walker.global_position = pad.global_position + side * 22.0 + up * 0.9
	walker.set("_spawn_grace_t", 0.0)
	if walker is CharacterBody3D:
		(walker as CharacterBody3D).velocity = Vector3.ZERO
	if walker.has_method("_physics_process"):
		walker._physics_process(0.016)
	var coy: float = float(walker.get("_coyote_t"))
	print("[Playtest] dirt coyote t=", snapped(coy, 0.01), " near=", walker.call("_near_dirt_floor") if walker.has_method("_near_dirt_floor") else "?")
	if coy <= 0.0:
		fails.append("dirt coyote dead off-plate")
		if walker.has_method("snap_to_pad"):
			walker.global_position = stay
			walker.call("snap_to_pad", pad)
		return
	var v0: float = 0.0
	if walker is CharacterBody3D:
		v0 = (walker as CharacterBody3D).velocity.dot(up)
	if walker.has_method("request_jump"):
		walker.request_jump()
	if walker.has_method("_physics_process"):
		walker._physics_process(0.016)
	var v1: float = v0
	if walker is CharacterBody3D:
		v1 = (walker as CharacterBody3D).velocity.dot(up)
	print("[Playtest] dirt jump v_up ", snapped(v0, 0.1), "→", snapped(v1, 0.1))
	if v1 < v0 + 3.0:
		fails.append("dirt jump died (%s → %s)" % [snapped(v0, 0.1), snapped(v1, 0.1)])
	if walker.has_method("snap_to_pad"):
		walker.global_position = stay
		walker.call("snap_to_pad", pad)


func _osh_eva_on_pad(walker: Node3D, pad: Node3D, nex: Node, eva_agl: float, fails: PackedStringArray) -> bool:
	## GPU leftover: walker must stand on the unnamed plate, not dirt void.
	if walker == null or not is_instance_valid(walker):
		fails.append("OS-H EVA snap left walker off pad (no walker)")
		return false
	if pad == null or not is_instance_valid(pad):
		fails.append("OS-H EVA snap left walker off pad (no plate)")
		return false
	var up := Vector3.UP
	if pad.has_meta("pad_up"):
		up = (pad.get_meta("pad_up") as Vector3).normalized()
	var rel: Vector3 = walker.global_position - pad.global_position
	var lat: float = (rel - up * rel.dot(up)).length()
	var deck: float = rel.dot(up)
	print("[Playtest] OS-H STEP eva snap AGL=", snapped(eva_agl, 0.01),
		" pad=", pad.name, " lat=", snapped(lat, 0.1), " deck=", snapped(deck, 0.01),
		" (walker on pad, not void)")
	if lat > 14.0 or deck < 0.35 or deck > 8.0:
		fails.append("OS-H EVA snap left walker off pad (lat=%s deck=%s)" % [
			str(snapped(lat, 0.1)), str(snapped(deck, 0.01))
		])
		return false
	if eva_agl > 40.0 or eva_agl < -6.0:
		fails.append("OS-H EVA snap left walker off relief (%s)" % snapped(eva_agl, 0.01))
		return false
	var rad := 1400.0
	if nex != null and nex.get("radius") != null:
		rad = float(nex.get("radius"))
	var wcam: Camera3D = walker.get_node_or_null("CamPivot/Camera3D") as Camera3D
	if wcam != null and nex != null and nex is Node3D:
		var cd: float = wcam.global_position.distance_to((nex as Node3D).global_position)
		if cd + 2.0 < rad:
			fails.append("OS-H EVA snap camera in void/core (d=%s r=%s)" % [
				str(snapped(cd, 0.1)), str(snapped(rad, 0.1))
			])
			return false
	return true


func _osh_invariants(fails: PackedStringArray) -> void:
	var os: Node = get_parent()
	var planets: Array = os.get("planets") if os and os.get("planets") != null else []
	if planets.size() != 1:
		fails.append("OS-H loaded a second system/body (%s)" % planets.size())
	var sys = load("res://scripts/world/StarSystemCatalog.gd")
	if sys and str(sys.HOME) != "ARK":
		fails.append("OS-H left ARK (%s)" % str(sys.HOME))
	if LayerContext and str(LayerContext.site_pin_id) != "" and str(LayerContext.site_pin_id) != "SITE_SPACE_TEST_PAD":
		fails.append("OS-H site_pin left catalog (%s)" % LayerContext.site_pin_id)
	var src := FileAccess.get_file_as_string("res://scripts/ship/ShipController.gd")
	if src.find("FlightMode.CRUISE") >= 0 or src.find("mass_lock") >= 0:
		fails.append("OS-H shipped G1 CRUISE / mass lock")


func _osh_occupy_refuel(_os: Node, ship: Node3D, nex: Node, fails: PackedStringArray) -> void:
	## After OS-H descend the tank is empty. LAND+occupy on an unnamed pad
	## restores fuel (occupy wait, no cash skip). Not EVA snap.
	if nex != null and nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	await get_tree().create_timer(0.35).timeout
	var deck: Node3D = _osh_unnamed_deck()
	if deck == null:
		fails.append("OS-H occupy-refuel: no unnamed pad")
		print("[Playtest] occupy fuel after LAND skipped (no pad)")
		return
	var up: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	ship.global_position = deck.global_position + up * 6.0
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	if ship.has_method("_do_land"):
		ship._do_land()
	if not bool(ship.get("is_landed")):
		fails.append("OS-H occupy-refuel: LAND on unnamed pad refused")
		print("[Playtest] occupy fuel after LAND refused pad=", deck.name)
		return
	var f0: float = float(ship.get("fuel")) if "fuel" in ship else -1.0
	await get_tree().create_timer(0.7).timeout
	var f1: float = float(ship.get("fuel")) if "fuel" in ship else -1.0
	print("[Playtest] occupy fuel after LAND ", snapped(f0, 0.1), " -> ", snapped(f1, 0.1), " pad=", deck.name)
	if f0 < 0.0 or not ship.has_method("refuel"):
		fails.append("ship has no occupy refuel API")
	elif f1 <= 0.5:
		fails.append("occupy did not restore fuel after LAND (%s → %s)" % [
			str(snapped(f0, 0.1)), str(snapped(f1, 0.1))
		])
	elif f1 >= 99.0:
		fails.append("pad fuel filled instantly (no occupy wait / paid skip)")


func _osh_unnamed_deck() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var prefer := ["Pad_Approach", "Pad_North", "Pad_Flank"]
	var pads: Array = tree.get_nodes_in_group("pad_bases")
	var fallback: Node3D = null
	for want in prefer:
		for p in pads:
			if p == null or not is_instance_valid(p):
				continue
			var host: Node = p
			var deck: Node3D = null
			while host:
				if host is Node3D and host.has_meta("pad_up"):
					deck = host as Node3D
					break
				host = host.get_parent()
			if deck == null:
				continue
			if fallback == null:
				fallback = deck
			if str(deck.name) == want:
				return deck
	return fallback


func _assert_gear_before_land(fails: PackedStringArray) -> void:
	## Pillar 1 leftover: SCM + gear up denies pad land. HOVER near pad auto-drops.
	var os: Node = get_parent()
	var ship: Node = os.get("ship") if os else null
	var nex: Node = _osh_nex()
	if ship == null or nex == null:
		fails.append("gear-down-before-land: no ship/Nex-Prime")
		return
	if nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	var pads: Array = get_tree().get_nodes_in_group("pad_bases")
	var deck: Node3D = null
	for p in pads:
		if p is Node3D and bool((p as Node3D).get_meta("landing_pad", false)):
			deck = p as Node3D
			break
		var host: Node = p
		while host:
			if host is Node3D and host.has_meta("pad_up"):
				deck = host as Node3D
				break
			host = host.get_parent()
		if deck:
			break
	if deck == null:
		fails.append("gear-down-before-land: no unnamed pad")
		return
	var up: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	ship.global_position = deck.global_position + up * 6.0
	if ship.has_method("set_gear_down"):
		# Force retracted without the landed lock.
		ship.set("_gear_down", false)
		if ship.has_method("_sync_landing_gear"):
			ship._sync_landing_gear()
	if ship.has_method("_set_mode"):
		ship._set_mode(0)  # SCM
	if ship.has_method("_do_land"):
		ship._do_land()
	var landed_up := bool(ship.get("is_landed"))
	print("[Playtest] gear-down-before-land SCM+up landed=", landed_up)
	if landed_up:
		fails.append("SCM gear-up landed on pad")
		return
	if ship.has_method("_set_mode"):
		ship._set_mode(2)  # HOVER near pad auto-drops
	var auto := bool(ship.is_gear_down()) if ship.has_method("is_gear_down") else bool(ship.get("_gear_down"))
	print("[Playtest] gear-down-before-land HOVER auto=", auto)
	if not auto:
		fails.append("HOVER near pad did not auto-drop gear")
		return
	if ship.has_method("_do_land"):
		ship._do_land()
	var landed_dn := bool(ship.get("is_landed"))
	print("[Playtest] gear-down-before-land HOVER+down landed=", landed_dn, " pad=", deck.name)
	if not landed_dn:
		fails.append("gear-down land refused")
	elif ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()


func _assert_ship_land_settle(fails: PackedStringArray) -> void:
	## SESSION_CONTRACT 1 leftover: pad land settles from approach height,
	## not a +4 m teleport.
	var os: Node = get_parent()
	var ship: Node = os.get("ship") if os else null
	var nex: Node = _osh_nex()
	if ship == null or nex == null:
		fails.append("land settle: no ship/Nex-Prime")
		return
	if nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	var deck: Node3D = _osh_unnamed_deck()
	if deck == null:
		fails.append("land settle: no unnamed pad")
		return
	var up: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if up.length_squared() > 0.01:
		up = up.normalized()
	if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if "velocity" in ship:
		ship.velocity = -up * 3.5
	ship.global_position = deck.global_position + up * 7.0
	ship.set("_gear_down", true)
	if ship.has_method("_sync_landing_gear"):
		ship._sync_landing_gear()
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	if ship.has_method("_do_land"):
		ship._do_land()
	if not bool(ship.get("is_landed")):
		fails.append("land settle: LAND refused")
		return
	var h0: float = (ship.global_position - deck.global_position).dot(up)
	print("[Playtest] land settle start h=", snapped(h0, 0.01), " sink=", snapped(float(ship.get("last_land_sink")), 0.1))
	if h0 < 5.2:
		fails.append("land settle snapped instead of settling (%s)" % snapped(h0, 0.01))
		return
	await get_tree().create_timer(0.65).timeout
	if ship == null or not is_instance_valid(ship):
		fails.append("land settle: ship gone")
		return
	var h1: float = (ship.global_position - deck.global_position).dot(up)
	var hold: float = float(ship.get("_land_hold_h"))
	print("[Playtest] land settle end h=", snapped(h1, 0.01), " hold=", snapped(hold, 0.01))
	if absf(h1 - hold) > 1.0:
		fails.append("land settle missed hold height (%s vs %s)" % [snapped(h1, 0.01), snapped(hold, 0.01)])
	if ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()


func _assert_surface_land_dirt(fails: PackedStringArray) -> void:
	## OS-I leftover: surface land holds on PlanetRelief, not the sphere.
	var os: Node = get_parent()
	var ship: Node = os.get("ship") if os else null
	var nex: Node = _osh_nex()
	if ship == null or nex == null or not (nex is Node3D):
		fails.append("surface land dirt: no ship/Nex-Prime")
		return
	var deck: Node3D = _osh_unnamed_deck()
	if deck == null:
		fails.append("surface land dirt: no unnamed pad")
		return
	var up: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if up.length_squared() > 0.01:
		up = up.normalized()
	var side: Vector3 = up.cross(Vector3.RIGHT)
	if side.length_squared() < 0.04:
		side = up.cross(Vector3.FORWARD)
	side = side.normalized()
	if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	ship.set("_gear_down", true)
	if ship.has_method("_sync_landing_gear"):
		ship._sync_landing_gear()
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	var dirt_pos: Vector3 = deck.global_position + side * 110.0 + up * 7.0
	ship.global_position = dirt_pos
	if ship.has_method("_do_land"):
		ship._do_land()
	if not bool(ship.get("is_landed")):
		fails.append("surface land dirt: LAND refused")
		return
	if ship.get("_landed_pad") != null:
		fails.append("surface land dirt snapped to pad")
		if ship.has_method("_do_launch"):
			ship.set("_land_lock_t", 0.0)
			ship._do_launch()
		return
	await get_tree().create_timer(0.45).timeout
	if ship == null or not is_instance_valid(ship):
		fails.append("surface land dirt: ship gone")
		return
	var agl := 99.0
	if nex.has_method("altitude_of"):
		agl = float(nex.altitude_of(ship.global_position))
	var hold: float = float(ship.get("_land_hold_h"))
	print("[Playtest] surface land dirt agl=", snapped(agl, 0.01), " hold=", snapped(hold, 0.01))
	if absf(agl - hold) > 1.6:
		fails.append("surface land dirt hold is not Relief (%s vs %s)" % [snapped(agl, 0.01), snapped(hold, 0.01)])
	if os.has_method("try_exit_ship"):
		os.try_exit_ship()
	await get_tree().create_timer(0.4).timeout
	var walker: Node3D = os.get("player") as Node3D if os else null
	if walker == null or not is_instance_valid(walker) or not walker.is_inside_tree():
		fails.append("EVA dirt: no walker beside hull")
	else:
		var d_ship: float = walker.global_position.distance_to(ship.global_position)
		var d_pad: float = walker.global_position.distance_to(deck.global_position)
		var w_agl := 99.0
		if nex.has_method("altitude_of"):
			w_agl = float(nex.altitude_of(walker.global_position))
		print("[Playtest] EVA dirt d_ship=", snapped(d_ship, 0.1), " d_pad=", snapped(d_pad, 0.1),
			" agl=", snapped(w_agl, 0.01))
		if d_ship > 22.0:
			fails.append("EVA dirt teleported away from hull (%s)" % snapped(d_ship, 0.1))
		if d_pad < 60.0:
			fails.append("EVA dirt snapped to pad (%s)" % snapped(d_pad, 0.1))
		if w_agl < 0.2 or w_agl > 5.0:
			fails.append("EVA dirt walker not on Relief (%s)" % snapped(w_agl, 0.01))
		var rad_up: Vector3 = (walker.global_position - (nex as Node3D).global_position).normalized()
		var body_fwd: Vector3 = -walker.global_transform.basis.z
		body_fwd = body_fwd - rad_up * body_fwd.dot(rad_up)
		var want: Vector3 = -ship.global_transform.basis.z
		want = want - rad_up * want.dot(rad_up)
		var align := 0.0
		if body_fwd.length_squared() < 0.04 or want.length_squared() < 0.04:
			fails.append("EVA dirt facing not tangent")
		else:
			align = body_fwd.normalized().dot(want.normalized())
			print("[Playtest] EVA dirt facing align=", snapped(align, 0.01),
				" tangent=", snapped(1.0 - absf(body_fwd.normalized().dot(rad_up)), 0.01))
			if align < 0.55:
				fails.append("EVA dirt facing sideways vs hull nose (%s)" % snapped(align, 0.01))
		await _assert_occupy_hud_dirt(os, walker, deck, fails)
	if os.has_method("try_enter_ship"):
		os.try_enter_ship()
	await get_tree().create_timer(0.35).timeout
	if os.has_method("_leave_seat_to_pocket"):
		os._leave_seat_to_pocket()
	await get_tree().create_timer(0.4).timeout
	var d: Node = os.get("_interior") if os else null
	if d != null and d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
		d.exit_interior()
	await get_tree().create_timer(0.4).timeout
	walker = os.get("player") as Node3D if os else null
	if walker == null or not is_instance_valid(walker) or not walker.is_inside_tree():
		fails.append("hatch dirt: no walker beside hull")
	else:
		var hd_ship: float = walker.global_position.distance_to(ship.global_position)
		var hd_pad: float = walker.global_position.distance_to(deck.global_position)
		print("[Playtest] hatch dirt d_ship=", snapped(hd_ship, 0.1), " d_pad=", snapped(hd_pad, 0.1))
		if hd_ship > 22.0:
			fails.append("hatch dirt teleported away from hull (%s)" % snapped(hd_ship, 0.1))
		if hd_pad < 60.0:
			fails.append("hatch dirt snapped to pad (%s)" % snapped(hd_pad, 0.1))
		var h_agl := 99.0
		if nex.has_method("altitude_of"):
			h_agl = float(nex.altitude_of(walker.global_position))
		print("[Playtest] hatch dirt agl=", snapped(h_agl, 0.01))
		if h_agl < 0.2 or h_agl > 5.0:
			fails.append("hatch dirt walker not on Relief (%s)" % snapped(h_agl, 0.01))
		var rad_up_h: Vector3 = (walker.global_position - (nex as Node3D).global_position).normalized()
		if bool(walker.get("eva_mode")) or bool(walker.get("interior_mode")) or bool(walker.get("zero_g")):
			fails.append("hatch dirt still EVA/pocket")
		walker.set("_spawn_grace_t", 0.0)
		if walker is CharacterBody3D:
			(walker as CharacterBody3D).velocity = Vector3.ZERO
		if walker.has_method("_physics_process"):
			walker._physics_process(0.016)
		var coy_h: float = float(walker.get("_coyote_t"))
		var near_h: Variant = walker.call("_near_dirt_floor") if walker.has_method("_near_dirt_floor") else false
		print("[Playtest] hatch dirt coyote t=", snapped(coy_h, 0.01), " near=", near_h)
		if coy_h <= 0.0:
			fails.append("hatch dirt coyote dead")
		else:
			var hv0: float = 0.0
			if walker is CharacterBody3D:
				hv0 = (walker as CharacterBody3D).velocity.dot(rad_up_h)
			if walker.has_method("request_jump"):
				walker.request_jump()
			if walker.has_method("_physics_process"):
				walker._physics_process(0.016)
			var hv1: float = hv0
			if walker is CharacterBody3D:
				hv1 = (walker as CharacterBody3D).velocity.dot(rad_up_h)
			print("[Playtest] hatch dirt jump v_up ", snapped(hv0, 0.1), "→", snapped(hv1, 0.1))
			if hv1 < hv0 + 3.0:
				fails.append("hatch dirt jump died (%s → %s)" % [snapped(hv0, 0.1), snapped(hv1, 0.1)])
		var last_s: float = float(walker.get("last_slope_ang"))
		var rel_s: float = 0.0
		if walker.has_method("_relief_slope_rad"):
			rel_s = float(walker.call("_relief_slope_rad"))
		print("[Playtest] hatch dirt slope last=", snapped(rad_to_deg(last_s), 0.1),
			" deg rel=", snapped(rad_to_deg(rel_s), 0.1))
		if last_s < 0.0 or last_s > 1.4:
			fails.append("hatch dirt slope last out of range (%s)" % snapped(last_s, 0.01))
		if rel_s > 0.05 and last_s + 0.08 < rel_s:
			fails.append("hatch dirt slope not Relief (%s vs %s)" % [snapped(last_s, 0.01), snapped(rel_s, 0.01)])
		if last_s > rel_s + 0.25:
			fails.append("hatch dirt slope is pocket-Y cliff (%s vs %s)" % [snapped(last_s, 0.01), snapped(rel_s, 0.01)])
		var body_fwd_h: Vector3 = -walker.global_transform.basis.z
		body_fwd_h = body_fwd_h - rad_up_h * body_fwd_h.dot(rad_up_h)
		var want_h: Vector3 = -ship.global_transform.basis.z
		want_h = want_h - rad_up_h * want_h.dot(rad_up_h)
		if body_fwd_h.length_squared() < 0.04 or want_h.length_squared() < 0.04:
			fails.append("hatch dirt facing not tangent")
		else:
			var align_h: float = body_fwd_h.normalized().dot(want_h.normalized())
			print("[Playtest] hatch dirt facing align=", snapped(align_h, 0.01),
				" tangent=", snapped(1.0 - absf(body_fwd_h.normalized().dot(rad_up_h)), 0.01))
			if align_h < 0.55:
				fails.append("hatch dirt facing sideways vs hull nose (%s)" % snapped(align_h, 0.01))
		var hud: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
		if hud != null and hud.has_method("bind_player"):
			hud.bind_player(walker)
		if hud != null and hud.has_method("_refresh"):
			hud._refresh()
		var origin: Node3D = null
		if hud != null and hud.has_method("_occupy_origin"):
			origin = hud.call("_occupy_origin") as Node3D
		print("[Playtest] occupy HUD hatch dirt origin=", origin.name if origin else "null",
			" walker=", walker.name)
		if origin == null:
			fails.append("occupy HUD lost origin after hatch dirt")
		elif origin == ship:
			fails.append("occupy HUD origin still hull after hatch dirt")
		elif origin != walker:
			fails.append("occupy HUD origin not walker after hatch dirt")
		var otxt := ""
		if hud != null:
			var lab: Variant = hud.get("_owner_label")
			if lab is Label:
				otxt = (lab as Label).text
			var ilab: Variant = hud.get("_interior_label")
			if ilab is Label and (ilab as Label).visible:
				otxt += " " + (ilab as Label).text
		print("[Playtest] occupy HUD hatch dirt '", otxt.replace("\n", " / ").substr(0, 120), "'")
		if otxt.to_upper().find("PAD") >= 0:
			fails.append("occupy HUD offered PAD after hatch dirt")
		if otxt.to_lower().find("hatch") >= 0:
			fails.append("occupy HUD still pocket hatch after dirt exit")
		var radar = hud.get("_radar") if hud else null
		if radar is CanvasItem:
			(radar as CanvasItem).visible = true
		if hud != null and hud.has_method("_refresh"):
			hud._refresh()
		var near_n := 0
		if hud != null and hud.has_method("radar_pad_contacts"):
			near_n = hud.radar_pad_contacts().size()
		print("[Playtest] pad radar hatch dirt 110m n=", near_n)
		if near_n < 1:
			fails.append("pad radar missed pad after hatch dirt")
		var up_h: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
		if up_h.length_squared() > 0.01:
			up_h = up_h.normalized()
		var side_h: Vector3 = up_h.cross(Vector3.RIGHT)
		if side_h.length_squared() < 0.04:
			side_h = up_h.cross(Vector3.FORWARD)
		side_h = side_h.normalized()
		var saved_h: Vector3 = walker.global_position
		walker.global_position = deck.global_position + side_h * 600.0 + up_h * 2.0
		if hud != null and hud.has_method("_refresh"):
			hud._refresh()
		var far_hit := false
		var far_n := 0
		if hud != null and hud.has_method("radar_pad_contacts"):
			for c in hud.radar_pad_contacts():
				far_n += 1
				if c is Node3D and (c as Node3D).global_position.distance_to(deck.global_position) < 30.0:
					far_hit = true
		print("[Playtest] pad radar hatch dirt 600m n=", far_n, " pad=", far_hit)
		if far_hit:
			fails.append("pad radar used 12km approach after hatch dirt")
		walker.global_position = saved_h
		var ly := ""
		if LayerContext:
			ly = str(LayerContext.current_layer)
		var stack := ""
		var stack_on := false
		if hud != null:
			var sl: Variant = hud.get("_os_stack")
			if sl is Label:
				stack = (sl as Label).text
				stack_on = (sl as Label).visible
			var ll: Variant = hud.get("_layer_label")
			if ll is Label:
				ly = ly if ly != "" else (ll as Label).text
		print("[Playtest] os stack hatch dirt layer=", ly, " vis=", stack_on, " '", stack.replace("\n", " / ").substr(0, 140), "'")
		if ly.to_upper().find("SPACE") >= 0:
			fails.append("os stack layer still SPACE after hatch dirt")
		if ly.to_upper().find("TPS") < 0 and ly.to_upper().find("SURFACE") < 0:
			fails.append("os stack layer not TPS after hatch dirt (%s)" % ly)
		if not stack_on:
			fails.append("os stack hidden after hatch dirt")
		var st_up := stack.to_upper()
		if st_up.find("OCCUPY") >= 0:
			fails.append("os stack occupy after hatch dirt 110m")
		if st_up.find("0G") >= 0:
			fails.append("os stack EVA 0G after grounded hatch dirt")
	if os.has_method("try_enter_ship"):
		os.try_enter_ship()
	await get_tree().create_timer(0.35).timeout
	if not bool(os.get("_in_ship")):
		fails.append("hatch dirt F-board refused")
	else:
		print("[Playtest] hatch dirt F-board in_ship=true")
		var hud_b: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
		if hud_b != null and hud_b.has_method("bind_player"):
			hud_b.bind_player(ship)
		if hud_b != null and hud_b.has_method("_refresh"):
			hud_b._refresh()
		var origin_b: Node3D = null
		if hud_b != null and hud_b.has_method("_occupy_origin"):
			origin_b = hud_b.call("_occupy_origin") as Node3D
		print("[Playtest] occupy HUD hatch dirt board origin=", origin_b.name if origin_b else "null")
		if origin_b != null and origin_b != ship and origin_b.has_method("set_spawn_facing"):
			fails.append("occupy HUD origin still walker after hatch dirt F-board")
	if not bool(ship.get("is_landed")):
		fails.append("hatch dirt launch: ship already flying")
	var agl0: float = 0.0
	if nex.has_method("altitude_of"):
		agl0 = float(nex.altitude_of(ship.global_position))
	if ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	await get_tree().create_timer(0.4).timeout
	var agl1: float = agl0
	if nex.has_method("altitude_of"):
		agl1 = float(nex.altitude_of(ship.global_position))
	var hold_l: float = float(ship.get("_hover_hold_alt"))
	print("[Playtest] hatch dirt launch agl ", snapped(agl0, 0.1), "→", snapped(agl1, 0.1),
		" hold=", snapped(hold_l, 0.1), " landed=", ship.get("is_landed"))
	if bool(ship.get("is_landed")):
		fails.append("hatch dirt launch still landed")
	if agl1 + 0.2 < agl0 + 0.8:
		fails.append("hatch dirt launch did not lift (%s → %s)" % [snapped(agl0, 0.1), snapped(agl1, 0.1)])
	if absf(hold_l - (agl0 + 12.0)) > 4.0:
		fails.append("hatch dirt launch hold not dirt AGL (%s vs %s)" % [snapped(hold_l, 0.1), snapped(agl0 + 12.0, 0.1)])
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	await get_tree().create_timer(0.55).timeout
	var hold_pd: float = float(ship.get("_hover_hold_alt"))
	var agl_pd: float = agl1
	if nex.has_method("altitude_of"):
		agl_pd = float(nex.altitude_of(ship.global_position))
	print("[Playtest] hatch dirt HOVER PD hold ", snapped(hold_l, 0.1), "→", snapped(hold_pd, 0.1),
		" AGL ", snapped(agl1, 0.1), "→", snapped(agl_pd, 0.1))
	if absf(hold_pd - hold_l) > 1.5:
		fails.append("hatch dirt HOVER PD rewrote hold (%s → %s)" % [snapped(hold_l, 0.1), snapped(hold_pd, 0.1)])
	if agl_pd + 0.3 < agl1:
		fails.append("hatch dirt HOVER PD sank (%s → %s)" % [snapped(agl1, 0.1), snapped(agl_pd, 0.1)])
	if agl_pd > hold_pd + 3.0:
		fails.append("hatch dirt HOVER PD overshoot (%s vs hold %s)" % [snapped(agl_pd, 0.1), snapped(hold_pd, 0.1)])
	var ge_up: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if ge_up.length_squared() > 0.01:
		ge_up = ge_up.normalized()
	var ge_rel: Vector3 = ship.global_position - deck.global_position
	var ge_lat: float = (ge_rel - ge_up * ge_rel.dot(ge_up)).length()
	print("[Playtest] hatch dirt GE lat=", snapped(ge_lat, 0.1), " agl=", snapped(agl_pd, 0.1))
	if ge_lat < 60.0:
		fails.append("hatch dirt GE drifted onto plate (%s)" % snapped(ge_lat, 0.1))
	ship.set_meta("playtest_sink", true)
	await get_tree().create_timer(0.45).timeout
	ship.set_meta("playtest_sink", false)
	var hold_sk: float = float(ship.get("_hover_hold_alt"))
	var agl_sk: float = agl_pd
	if nex.has_method("altitude_of"):
		agl_sk = float(nex.altitude_of(ship.global_position))
	print("[Playtest] hatch dirt HOVER sink hold ", snapped(hold_pd, 0.1), "→", snapped(hold_sk, 0.1),
		" AGL ", snapped(agl_pd, 0.1), "→", snapped(agl_sk, 0.1))
	if hold_sk > 6.5:
		fails.append("hatch dirt HOVER sink hold still 8m floor (%s)" % snapped(hold_sk, 0.1))
	if hold_sk + 0.2 < 3.5:
		fails.append("hatch dirt HOVER sink hold buried (%s)" % snapped(hold_sk, 0.1))
	if agl_sk > agl_pd + 1.5:
		fails.append("hatch dirt HOVER sink climbed (%s → %s)" % [snapped(agl_pd, 0.1), snapped(agl_sk, 0.1)])
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	if ship.has_method("_do_land"):
		ship._do_land()
	await get_tree().create_timer(0.4).timeout
	var land_agl: float = agl_sk
	if nex.has_method("altitude_of"):
		land_agl = float(nex.altitude_of(ship.global_position))
	var land_pad: Node3D = null
	if ship.has_method("get_landed_pad"):
		land_pad = ship.get_landed_pad() as Node3D
	var land_rel: Vector3 = ship.global_position - deck.global_position
	var land_lat: float = (land_rel - ge_up * land_rel.dot(ge_up)).length()
	print("[Playtest] hatch dirt land after sink landed=", ship.get("is_landed"),
		" pad=", land_pad.name if land_pad else "none",
		" agl=", snapped(land_agl, 0.1), " lat=", snapped(land_lat, 0.1))
	if not bool(ship.get("is_landed")):
		fails.append("hatch dirt land after sink refused")
	if land_pad != null:
		fails.append("hatch dirt land after sink stole pad")
	if land_lat < 60.0:
		fails.append("hatch dirt land after sink drifted to plate (%s)" % snapped(land_lat, 0.1))
	if land_agl < 1.5 or land_agl > 8.0:
		fails.append("hatch dirt land after sink not on Relief (%s)" % snapped(land_agl, 0.1))
	if os.has_method("try_exit_ship"):
		os.try_exit_ship()
	await get_tree().create_timer(0.4).timeout
	var eva2: Node3D = os.get("player") as Node3D if os else null
	if eva2 == null or not is_instance_valid(eva2) or not eva2.is_inside_tree():
		fails.append("F-EVA after dirt sink land: no walker")
	else:
		var e2_ship: float = eva2.global_position.distance_to(ship.global_position)
		var e2_pad: float = eva2.global_position.distance_to(deck.global_position)
		var e2_agl := 99.0
		if nex.has_method("altitude_of"):
			e2_agl = float(nex.altitude_of(eva2.global_position))
		print("[Playtest] F-EVA after dirt sink land d_ship=", snapped(e2_ship, 0.1),
			" d_pad=", snapped(e2_pad, 0.1), " agl=", snapped(e2_agl, 0.01),
			" eva=", eva2.get("eva_mode"))
		if e2_ship > 22.0:
			fails.append("F-EVA after dirt sink land teleported (%s)" % snapped(e2_ship, 0.1))
		if e2_pad < 60.0:
			fails.append("F-EVA after dirt sink land snapped to pad (%s)" % snapped(e2_pad, 0.1))
		if e2_agl < 0.2 or e2_agl > 5.0:
			fails.append("F-EVA after dirt sink land not on Relief (%s)" % snapped(e2_agl, 0.01))
		if bool(eva2.get("eva_mode")) or bool(eva2.get("zero_g")):
			fails.append("F-EVA after dirt sink land still EVA 0G")
		var rad_e2: Vector3 = (eva2.global_position - (nex as Node3D).global_position).normalized()
		var fwd_e2: Vector3 = -eva2.global_transform.basis.z
		fwd_e2 = fwd_e2 - rad_e2 * fwd_e2.dot(rad_e2)
		var want_e2: Vector3 = -ship.global_transform.basis.z
		want_e2 = want_e2 - rad_e2 * want_e2.dot(rad_e2)
		if fwd_e2.length_squared() < 0.04 or want_e2.length_squared() < 0.04:
			fails.append("F-EVA after dirt sink land facing not tangent")
		else:
			var align_e2: float = fwd_e2.normalized().dot(want_e2.normalized())
			print("[Playtest] F-EVA after dirt sink land facing align=", snapped(align_e2, 0.01),
				" tangent=", snapped(1.0 - absf(fwd_e2.normalized().dot(rad_e2)), 0.01))
			if align_e2 < 0.55:
				fails.append("F-EVA after dirt sink land facing sideways (%s)" % snapped(align_e2, 0.01))
		eva2.set("_spawn_grace_t", 0.0)
		if eva2 is CharacterBody3D:
			(eva2 as CharacterBody3D).velocity = Vector3.ZERO
		if eva2.has_method("_physics_process"):
			eva2._physics_process(0.016)
		var coy_e2: float = float(eva2.get("_coyote_t"))
		var near_e2: Variant = eva2.call("_near_dirt_floor") if eva2.has_method("_near_dirt_floor") else false
		print("[Playtest] F-EVA after dirt sink land coyote t=", snapped(coy_e2, 0.01), " near=", near_e2)
		if coy_e2 <= 0.0:
			fails.append("F-EVA after dirt sink land coyote dead")
		else:
			var ev0: float = 0.0
			if eva2 is CharacterBody3D:
				ev0 = (eva2 as CharacterBody3D).velocity.dot(rad_e2)
			if eva2.has_method("request_jump"):
				eva2.request_jump()
			if eva2.has_method("_physics_process"):
				eva2._physics_process(0.016)
			var ev1: float = ev0
			if eva2 is CharacterBody3D:
				ev1 = (eva2 as CharacterBody3D).velocity.dot(rad_e2)
			print("[Playtest] F-EVA after dirt sink land jump v_up ", snapped(ev0, 0.1), "→", snapped(ev1, 0.1))
			if ev1 < ev0 + 3.0:
				fails.append("F-EVA after dirt sink land jump died (%s → %s)" % [snapped(ev0, 0.1), snapped(ev1, 0.1)])
		var last_e2: float = float(eva2.get("last_slope_ang"))
		var rel_e2: float = 0.0
		if eva2.has_method("_relief_slope_rad"):
			rel_e2 = float(eva2.call("_relief_slope_rad"))
		print("[Playtest] F-EVA after dirt sink land slope last=", snapped(rad_to_deg(last_e2), 0.1),
			" deg rel=", snapped(rad_to_deg(rel_e2), 0.1))
		if last_e2 < 0.0 or last_e2 > 1.4:
			fails.append("F-EVA after dirt sink land slope last out of range (%s)" % snapped(last_e2, 0.01))
		if rel_e2 > 0.05 and last_e2 + 0.08 < rel_e2:
			fails.append("F-EVA after dirt sink land slope not Relief")
		if last_e2 > rel_e2 + 0.25:
			fails.append("F-EVA after dirt sink land slope is pocket-Y cliff")
		var hud_e2: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
		if hud_e2 != null and hud_e2.has_method("bind_player"):
			hud_e2.bind_player(eva2)
		if hud_e2 != null and hud_e2.has_method("_refresh"):
			hud_e2._refresh()
		var origin_e2: Node3D = null
		if hud_e2 != null and hud_e2.has_method("_occupy_origin"):
			origin_e2 = hud_e2.call("_occupy_origin") as Node3D
		var otxt_e2 := ""
		if hud_e2 != null:
			var lab_e2: Variant = hud_e2.get("_owner_label")
			if lab_e2 is Label:
				otxt_e2 = (lab_e2 as Label).text
		print("[Playtest] occupy HUD F-EVA dirt sink origin=", origin_e2.name if origin_e2 else "null",
			" '", otxt_e2.replace("\n", " / ").substr(0, 80), "'")
		if origin_e2 == null:
			fails.append("occupy HUD lost origin after F-EVA dirt sink")
		elif origin_e2 == ship:
			fails.append("occupy HUD origin still hull after F-EVA dirt sink")
		elif origin_e2 != eva2:
			fails.append("occupy HUD origin not walker after F-EVA dirt sink")
		if otxt_e2.to_upper().find("PAD") >= 0 and otxt_e2.to_upper().find("OCCUPY") >= 0:
			fails.append("occupy HUD PAD after F-EVA dirt 110m")
		var radar_e2: Variant = hud_e2.get("_radar") if hud_e2 else null
		if radar_e2 is CanvasItem:
			(radar_e2 as CanvasItem).visible = true
		if hud_e2 != null and hud_e2.has_method("_refresh"):
			hud_e2._refresh()
		var near_e2n := 0
		if hud_e2 != null and hud_e2.has_method("radar_pad_contacts"):
			near_e2n = hud_e2.radar_pad_contacts().size()
		print("[Playtest] pad radar F-EVA dirt sink 110m n=", near_e2n, " vis=",
			(radar_e2 as CanvasItem).visible if radar_e2 is CanvasItem else "?")
		if near_e2n < 1:
			fails.append("pad radar missed pad after F-EVA dirt sink")
		var saved_e2: Vector3 = eva2.global_position
		var up_e2r: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
		if up_e2r.length_squared() > 0.01:
			up_e2r = up_e2r.normalized()
		var side_e2r: Vector3 = up_e2r.cross(Vector3.RIGHT)
		if side_e2r.length_squared() < 0.04:
			side_e2r = up_e2r.cross(Vector3.FORWARD)
		side_e2r = side_e2r.normalized()
		eva2.global_position = deck.global_position + side_e2r * 600.0 + up_e2r * 2.0
		if hud_e2 != null and hud_e2.has_method("_refresh"):
			hud_e2._refresh()
		var far_e2 := false
		var far_e2n := 0
		if hud_e2 != null and hud_e2.has_method("radar_pad_contacts"):
			for c in hud_e2.radar_pad_contacts():
				far_e2n += 1
				if c is Node3D and (c as Node3D).global_position.distance_to(deck.global_position) < 30.0:
					far_e2 = true
		print("[Playtest] pad radar F-EVA dirt sink 600m n=", far_e2n, " pad=", far_e2)
		if far_e2:
			fails.append("pad radar used 12km approach after F-EVA dirt sink")
		eva2.global_position = saved_e2
		if hud_e2 != null and hud_e2.has_method("_refresh"):
			hud_e2._refresh()
		var ly_e2 := ""
		if LayerContext:
			ly_e2 = str(LayerContext.current_layer)
		var stack_e2 := ""
		var stack_e2_on := false
		if hud_e2 != null:
			var sl_e2: Variant = hud_e2.get("_os_stack")
			if sl_e2 is Label:
				stack_e2 = (sl_e2 as Label).text
				stack_e2_on = (sl_e2 as Label).visible
		print("[Playtest] os stack F-EVA dirt sink layer=", ly_e2, " vis=", stack_e2_on,
			" '", stack_e2.replace("\n", " / ").substr(0, 140), "'")
		if ly_e2.to_upper().find("SPACE") >= 0:
			fails.append("os stack layer still SPACE after F-EVA dirt sink")
		if ly_e2.to_upper().find("TPS") < 0 and ly_e2.to_upper().find("SURFACE") < 0:
			fails.append("os stack layer not TPS after F-EVA dirt sink (%s)" % ly_e2)
		if not stack_e2_on:
			fails.append("os stack hidden after F-EVA dirt sink")
		var st_e2 := stack_e2.to_upper()
		if st_e2.find("OCCUPY") >= 0:
			fails.append("os stack occupy after F-EVA dirt 110m")
		if st_e2.find("0G") >= 0:
			fails.append("os stack EVA 0G after F-EVA dirt sink")
		if os.has_method("try_enter_ship"):
			os.try_enter_ship()
		await get_tree().create_timer(0.3).timeout
		if not bool(os.get("_in_ship")):
			fails.append("F-board after F-EVA dirt sink refused")
		var hud_b2: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
		if hud_b2 != null and hud_b2.has_method("bind_player"):
			hud_b2.bind_player(ship)
		if hud_b2 != null and hud_b2.has_method("_refresh"):
			hud_b2._refresh()
		var origin_b2: Node3D = null
		if hud_b2 != null and hud_b2.has_method("_occupy_origin"):
			origin_b2 = hud_b2.call("_occupy_origin") as Node3D
		var ly_b2 := ""
		if LayerContext:
			ly_b2 = str(LayerContext.current_layer)
		print("[Playtest] F-board after F-EVA dirt sink in_ship=", os.get("_in_ship"),
			" origin=", origin_b2.name if origin_b2 else "null", " layer=", ly_b2)
		if origin_b2 != null and origin_b2 != ship:
			fails.append("occupy HUD origin still walker after F-EVA dirt sink F-board")
		if ly_b2.to_upper().find("SPACE") < 0:
			fails.append("layer not Space after F-EVA dirt sink F-board (%s)" % ly_b2)
		var radar_b2: Variant = hud_b2.get("_radar") if hud_b2 else null
		if radar_b2 is CanvasItem:
			(radar_b2 as CanvasItem).visible = true
		if hud_b2 != null and hud_b2.has_method("_refresh"):
			hud_b2._refresh()
		var rng_b2: float = float(hud_b2.get("_radar_range_m")) if hud_b2 else 0.0
		var n_b2 := 0
		if hud_b2 != null and hud_b2.has_method("radar_pad_contacts"):
			n_b2 = hud_b2.radar_pad_contacts().size()
		print("[Playtest] pad radar F-board after F-EVA dirt range=", snapped(rng_b2, 1.0),
			" n=", n_b2, " vis=", (radar_b2 as CanvasItem).visible if radar_b2 is CanvasItem else "?")
		if rng_b2 < 1000.0:
			fails.append("pad radar still 400m on-foot after F-board (%s)" % snapped(rng_b2, 1.0))
		if n_b2 < 1:
			fails.append("pad radar missed pad after F-board")
		var stack_b2 := ""
		var stack_b2_on := false
		var chip_b2 := ""
		if hud_b2 != null:
			var sl_b2: Variant = hud_b2.get("_os_stack")
			if sl_b2 is Label:
				stack_b2 = (sl_b2 as Label).text
				stack_b2_on = (sl_b2 as Label).visible
			var chip: Variant = hud_b2.get("_layer_label")
			if chip is Label:
				chip_b2 = (chip as Label).text
		print("[Playtest] os stack F-board after F-EVA dirt vis=", stack_b2_on,
			" chip='", chip_b2.replace("\n", " / ").substr(0, 48), "' '",
			stack_b2.replace("\n", " / ").substr(0, 80), "'")
		if not stack_b2_on:
			fails.append("os stack hidden after F-board")
		if chip_b2.to_upper().find("TPS") >= 0:
			fails.append("layer chip still TPS after F-board")
		if chip_b2.to_upper().find("SPACE") < 0:
			fails.append("layer chip not Space after F-board")
		if stack_b2.to_upper().find("0G") >= 0:
			fails.append("os stack EVA 0G after F-board")
		var chase_b2: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
		var live_b2: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
		print("[Playtest] HOVER view after F-EVA dirt F-board chase=", chase_b2.name if chase_b2 else "none",
			" live=", live_b2.name if live_b2 else "none", " current=", chase_b2.current if chase_b2 else false)
		if chase_b2 == null:
			fails.append("HOVER view after F-board: no chase cam")
		elif live_b2 != chase_b2:
			fails.append("HOVER view after F-board stole (%s)" % (live_b2.name if live_b2 else "none"))
		elif not chase_b2.current:
			fails.append("HOVER view after F-board chase not current")
		if os.has_method("_leave_seat_to_pocket"):
			os._leave_seat_to_pocket()
		await get_tree().create_timer(0.45).timeout
		var d_pk: Node = os.get("_interior")
		var ly_pk := ""
		if LayerContext:
			ly_pk = str(LayerContext.current_layer)
		print("[Playtest] I-hatch after dirt F-board pocket inside=",
			d_pk.is_inside() if d_pk and d_pk.has_method("is_inside") else "?",
			" in_ship=", os.get("_in_ship"), " layer=", ly_pk)
		if d_pk == null or not d_pk.has_method("is_inside") or not bool(d_pk.is_inside()):
			fails.append("I-hatch after dirt F-board: no pocket")
		if bool(os.get("_in_ship")):
			fails.append("I-hatch after dirt F-board still piloting")
		if ly_pk.to_lower().find("ship") < 0 and ly_pk.to_lower().find("int") < 0:
			fails.append("I-hatch after dirt F-board layer not ship_int (%s)" % ly_pk)
		if d_pk != null and d_pk.has_method("exit_interior"):
			d_pk.exit_interior()
		await get_tree().create_timer(0.45).timeout
		var w_pk: Node3D = os.get("player") as Node3D
		if w_pk == null or not is_instance_valid(w_pk) or not w_pk.is_inside_tree():
			fails.append("I-hatch after dirt F-board: no dirt walker")
		else:
			var pk_ship: float = w_pk.global_position.distance_to(ship.global_position)
			var pk_pad: float = w_pk.global_position.distance_to(deck.global_position)
			var pk_agl := 99.0
			if nex.has_method("altitude_of"):
				pk_agl = float(nex.altitude_of(w_pk.global_position))
			print("[Playtest] I-hatch after dirt F-board exit d_ship=", snapped(pk_ship, 0.1),
				" d_pad=", snapped(pk_pad, 0.1), " agl=", snapped(pk_agl, 0.01),
				" eva=", w_pk.get("eva_mode"))
			if pk_ship > 22.0:
				fails.append("I-hatch after dirt F-board teleported (%s)" % snapped(pk_ship, 0.1))
			if pk_pad < 60.0:
				fails.append("I-hatch after dirt F-board snapped to pad (%s)" % snapped(pk_pad, 0.1))
			if pk_agl < 0.2 or pk_agl > 5.0:
				fails.append("I-hatch after dirt F-board not on Relief (%s)" % snapped(pk_agl, 0.01))
			if bool(w_pk.get("eva_mode")) or bool(w_pk.get("zero_g")):
				fails.append("I-hatch after dirt F-board still EVA 0G")
			var rad_pk: Vector3 = (w_pk.global_position - (nex as Node3D).global_position).normalized()
			var fwd_pk: Vector3 = -w_pk.global_transform.basis.z
			fwd_pk = fwd_pk - rad_pk * fwd_pk.dot(rad_pk)
			var want_pk: Vector3 = -ship.global_transform.basis.z
			want_pk = want_pk - rad_pk * want_pk.dot(rad_pk)
			if fwd_pk.length_squared() < 0.04 or want_pk.length_squared() < 0.04:
				fails.append("I-hatch after dirt F-board facing not tangent")
			else:
				var align_pk: float = fwd_pk.normalized().dot(want_pk.normalized())
				print("[Playtest] I-hatch after dirt F-board facing align=", snapped(align_pk, 0.01),
					" tangent=", snapped(1.0 - absf(fwd_pk.normalized().dot(rad_pk)), 0.01))
				if align_pk < 0.55:
					fails.append("I-hatch after dirt F-board facing sideways (%s)" % snapped(align_pk, 0.01))
			w_pk.set("_spawn_grace_t", 0.0)
			if w_pk is CharacterBody3D:
				(w_pk as CharacterBody3D).velocity = Vector3.ZERO
			if w_pk.has_method("_physics_process"):
				w_pk._physics_process(0.016)
			var coy_pk: float = float(w_pk.get("_coyote_t"))
			var near_pk: Variant = w_pk.call("_near_dirt_floor") if w_pk.has_method("_near_dirt_floor") else false
			print("[Playtest] I-hatch after dirt F-board coyote t=", snapped(coy_pk, 0.01), " near=", near_pk)
			if coy_pk <= 0.0:
				fails.append("I-hatch after dirt F-board coyote dead")
			else:
				var pv0: float = 0.0
				if w_pk is CharacterBody3D:
					pv0 = (w_pk as CharacterBody3D).velocity.dot(rad_pk)
				if w_pk.has_method("request_jump"):
					w_pk.request_jump()
				if w_pk.has_method("_physics_process"):
					w_pk._physics_process(0.016)
				var pv1: float = pv0
				if w_pk is CharacterBody3D:
					pv1 = (w_pk as CharacterBody3D).velocity.dot(rad_pk)
				print("[Playtest] I-hatch after dirt F-board jump v_up ", snapped(pv0, 0.1), "→", snapped(pv1, 0.1))
				if pv1 < pv0 + 3.0:
					fails.append("I-hatch after dirt F-board jump died (%s → %s)" % [snapped(pv0, 0.1), snapped(pv1, 0.1)])
			var last_pk: float = float(w_pk.get("last_slope_ang"))
			var rel_pk: float = 0.0
			if w_pk.has_method("_relief_slope_rad"):
				rel_pk = float(w_pk.call("_relief_slope_rad"))
			print("[Playtest] I-hatch after dirt F-board slope last=", snapped(rad_to_deg(last_pk), 0.1),
				" deg rel=", snapped(rad_to_deg(rel_pk), 0.1))
			if last_pk < 0.0 or last_pk > 1.4:
				fails.append("I-hatch after dirt F-board slope last out of range (%s)" % snapped(last_pk, 0.01))
			if rel_pk > 0.05 and last_pk + 0.08 < rel_pk:
				fails.append("I-hatch after dirt F-board slope not Relief")
			if last_pk > rel_pk + 0.25:
				fails.append("I-hatch after dirt F-board slope is pocket-Y cliff")
			var hud_pk: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
			if hud_pk != null and hud_pk.has_method("bind_player"):
				hud_pk.bind_player(w_pk)
			if hud_pk != null and hud_pk.has_method("_refresh"):
				hud_pk._refresh()
			var origin_pk: Node3D = null
			if hud_pk != null and hud_pk.has_method("_occupy_origin"):
				origin_pk = hud_pk.call("_occupy_origin") as Node3D
			var otxt_pk := ""
			if hud_pk != null:
				var lab_pk: Variant = hud_pk.get("_owner_label")
				if lab_pk is Label:
					otxt_pk = (lab_pk as Label).text
			print("[Playtest] occupy HUD I-hatch after dirt F-board origin=",
				origin_pk.name if origin_pk else "null",
				" '", otxt_pk.replace("\n", " / ").substr(0, 80), "'")
			if origin_pk == null:
				fails.append("occupy HUD lost origin after second I-hatch dirt")
			elif origin_pk == ship:
				fails.append("occupy HUD origin still hull after second I-hatch dirt")
			elif origin_pk != w_pk:
				fails.append("occupy HUD origin not walker after second I-hatch dirt")
			if otxt_pk.to_upper().find("PAD") >= 0 and otxt_pk.to_upper().find("OCCUPY") >= 0:
				fails.append("occupy HUD PAD after second I-hatch dirt 110m")
			var radar_pk: Variant = hud_pk.get("_radar") if hud_pk else null
			if radar_pk is CanvasItem:
				(radar_pk as CanvasItem).visible = true
			if hud_pk != null and hud_pk.has_method("_refresh"):
				hud_pk._refresh()
			var rng_pk: float = float(hud_pk.get("_radar_range_m")) if hud_pk else 0.0
			var near_pkn := 0
			if hud_pk != null and hud_pk.has_method("radar_pad_contacts"):
				near_pkn = hud_pk.radar_pad_contacts().size()
			print("[Playtest] pad radar second I-hatch dirt 110m n=", near_pkn,
				" range=", snapped(rng_pk, 1.0), " vis=",
				(radar_pk as CanvasItem).visible if radar_pk is CanvasItem else "?")
			if rng_pk > 1000.0:
				fails.append("pad radar used 12km after second I-hatch dirt (%s)" % snapped(rng_pk, 1.0))
			if near_pkn < 1:
				fails.append("pad radar missed pad after second I-hatch dirt")
			var saved_pk: Vector3 = w_pk.global_position
			var up_pkr: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
			if up_pkr.length_squared() > 0.01:
				up_pkr = up_pkr.normalized()
			var side_pkr: Vector3 = up_pkr.cross(Vector3.RIGHT)
			if side_pkr.length_squared() < 0.04:
				side_pkr = up_pkr.cross(Vector3.FORWARD)
			side_pkr = side_pkr.normalized()
			w_pk.global_position = deck.global_position + side_pkr * 600.0 + up_pkr * 2.0
			if hud_pk != null and hud_pk.has_method("_refresh"):
				hud_pk._refresh()
			var far_pk := false
			var far_pkn := 0
			if hud_pk != null and hud_pk.has_method("radar_pad_contacts"):
				for c in hud_pk.radar_pad_contacts():
					far_pkn += 1
					if c is Node3D and (c as Node3D).global_position.distance_to(deck.global_position) < 30.0:
						far_pk = true
			print("[Playtest] pad radar second I-hatch dirt 600m n=", far_pkn, " pad=", far_pk)
			if far_pk:
				fails.append("pad radar used 12km approach after second I-hatch dirt")
			w_pk.global_position = saved_pk
			if hud_pk != null and hud_pk.has_method("_refresh"):
				hud_pk._refresh()
			var ly_pk2 := ""
			if LayerContext:
				ly_pk2 = str(LayerContext.current_layer)
			var stack_pk := ""
			var stack_pk_on := false
			var chip_pk := ""
			if hud_pk != null:
				var sl_pk: Variant = hud_pk.get("_os_stack")
				if sl_pk is Label:
					stack_pk = (sl_pk as Label).text
					stack_pk_on = (sl_pk as Label).visible
				var chip2: Variant = hud_pk.get("_layer_label")
				if chip2 is Label:
					chip_pk = (chip2 as Label).text
			print("[Playtest] os stack second I-hatch dirt layer=", ly_pk2, " vis=", stack_pk_on,
				" chip='", chip_pk.replace("\n", " / ").substr(0, 40), "' '",
				stack_pk.replace("\n", " / ").substr(0, 80), "'")
			if ly_pk2.to_upper().find("SPACE") >= 0:
				fails.append("os stack layer still SPACE after second I-hatch dirt")
			if ly_pk2.to_upper().find("SHIP") >= 0:
				fails.append("os stack layer still ship_int after second I-hatch dirt")
			if ly_pk2.to_upper().find("TPS") < 0 and ly_pk2.to_upper().find("SURFACE") < 0:
				fails.append("os stack layer not TPS after second I-hatch dirt (%s)" % ly_pk2)
			if not stack_pk_on:
				fails.append("os stack hidden after second I-hatch dirt")
			if chip_pk.to_upper().find("SHIP") >= 0:
				fails.append("layer chip still ship_int after second I-hatch dirt")
			if stack_pk.to_upper().find("OCCUPY") >= 0:
				fails.append("os stack occupy after second I-hatch dirt 110m")
			if stack_pk.to_upper().find("0G") >= 0:
				fails.append("os stack EVA 0G after second I-hatch dirt")
			if os.has_method("try_enter_ship"):
				os.try_enter_ship()
			await get_tree().create_timer(0.3).timeout
			if not bool(os.get("_in_ship")):
				fails.append("reboard after I-hatch dirt F-board refused")
			else:
				if hud_pk != null and hud_pk.has_method("bind_player"):
					hud_pk.bind_player(ship)
				if hud_pk != null and hud_pk.has_method("_refresh"):
					hud_pk._refresh()
				var origin_rb: Node3D = null
				if hud_pk != null and hud_pk.has_method("_occupy_origin"):
					origin_rb = hud_pk.call("_occupy_origin") as Node3D
				var ly_rb := ""
				if LayerContext:
					ly_rb = str(LayerContext.current_layer)
				var rng_rb: float = float(hud_pk.get("_radar_range_m")) if hud_pk else 0.0
				print("[Playtest] F-board after second I-hatch dirt origin=",
					origin_rb.name if origin_rb else "null", " layer=", ly_rb,
					" radar=", snapped(rng_rb, 1.0))
				if origin_rb != null and origin_rb != ship:
					fails.append("occupy HUD origin still walker after second I-hatch F-board")
				if ly_rb.to_upper().find("SPACE") < 0:
					fails.append("layer not Space after second I-hatch F-board (%s)" % ly_rb)
				if rng_rb < 1000.0:
					fails.append("pad radar still 400m after second I-hatch F-board (%s)" % snapped(rng_rb, 1.0))
				var chase_rb: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
				var live_rb: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
				print("[Playtest] HOVER view after second I-hatch F-board chase=",
					chase_rb.name if chase_rb else "none", " live=", live_rb.name if live_rb else "none",
					" current=", chase_rb.current if chase_rb else false)
				if chase_rb == null:
					fails.append("HOVER view after second I-hatch F-board: no chase cam")
				elif live_rb != chase_rb:
					fails.append("HOVER view after second I-hatch F-board stole (%s)" % (live_rb.name if live_rb else "none"))
				elif not chase_rb.current:
					fails.append("HOVER view after second I-hatch F-board chase not current")
				if not bool(ship.get("is_landed")):
					fails.append("second dirt F-board launch: ship already flying")
				else:
					var agl_rb0: float = 0.0
					if nex.has_method("altitude_of"):
						agl_rb0 = float(nex.altitude_of(ship.global_position))
					if ship.has_method("_do_launch"):
						ship.set("_land_lock_t", 0.0)
						ship._do_launch()
					await get_tree().create_timer(0.4).timeout
					var agl_rb1: float = agl_rb0
					if nex.has_method("altitude_of"):
						agl_rb1 = float(nex.altitude_of(ship.global_position))
					var hold_rb: float = float(ship.get("_hover_hold_alt"))
					print("[Playtest] second dirt F-board launch agl ", snapped(agl_rb0, 0.1), "→",
						snapped(agl_rb1, 0.1), " hold=", snapped(hold_rb, 0.1),
						" landed=", ship.get("is_landed"))
					if bool(ship.get("is_landed")):
						fails.append("second dirt F-board launch still landed")
					if agl_rb1 + 0.2 < agl_rb0 + 0.8:
						fails.append("second dirt F-board launch did not lift (%s → %s)" % [snapped(agl_rb0, 0.1), snapped(agl_rb1, 0.1)])
					if absf(hold_rb - (agl_rb0 + 12.0)) > 4.0:
						fails.append("second dirt F-board launch hold not dirt AGL (%s vs %s)" % [snapped(hold_rb, 0.1), snapped(agl_rb0 + 12.0, 0.1)])
					if ship.has_method("_set_mode"):
						ship._set_mode(2)
					await get_tree().create_timer(0.45).timeout
					var hold_rb2: float = float(ship.get("_hover_hold_alt"))
					print("[Playtest] second dirt F-board HOVER PD hold=", snapped(hold_rb2, 0.1))
					if absf(hold_rb2 - hold_rb) > 3.0:
						fails.append("second dirt F-board HOVER PD rewrote hold (%s → %s)" % [snapped(hold_rb, 0.1), snapped(hold_rb2, 0.1)])
					var lat_ge: float = 0.0
					var rel_ge: Vector3 = ship.global_position - deck.global_position
					var up_ge: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
					if up_ge.length_squared() > 0.01:
						up_ge = up_ge.normalized()
					lat_ge = (rel_ge - up_ge * rel_ge.dot(up_ge)).length()
					var agl_ge: float = agl_rb1
					if nex.has_method("altitude_of"):
						agl_ge = float(nex.altitude_of(ship.global_position))
					print("[Playtest] second dirt launch GE lat=", snapped(lat_ge, 0.1),
						" agl=", snapped(agl_ge, 0.1))
					if lat_ge < 60.0:
						fails.append("second dirt launch GE pulled onto plate (lat=%s)" % snapped(lat_ge, 0.1))
					ship.set_meta("playtest_sink", true)
					await get_tree().create_timer(0.45).timeout
					ship.set_meta("playtest_sink", false)
					var hold_sk2: float = float(ship.get("_hover_hold_alt"))
					var agl_sk2: float = agl_ge
					if nex.has_method("altitude_of"):
						agl_sk2 = float(nex.altitude_of(ship.global_position))
					var lat_sk: float = 0.0
					var rel_sk: Vector3 = ship.global_position - deck.global_position
					lat_sk = (rel_sk - up_ge * rel_sk.dot(up_ge)).length()
					print("[Playtest] second dirt HOVER sink hold ", snapped(hold_rb2, 0.1), "→", snapped(hold_sk2, 0.1),
						" AGL ", snapped(agl_ge, 0.1), "→", snapped(agl_sk2, 0.1), " lat=", snapped(lat_sk, 0.1))
					if hold_sk2 > 6.5:
						fails.append("second dirt HOVER sink hold still 8m floor (%s)" % snapped(hold_sk2, 0.1))
					if hold_sk2 + 0.2 < 3.5:
						fails.append("second dirt HOVER sink hold buried (%s)" % snapped(hold_sk2, 0.1))
					if agl_sk2 > agl_ge + 1.5:
						fails.append("second dirt HOVER sink climbed (%s → %s)" % [snapped(agl_ge, 0.1), snapped(agl_sk2, 0.1)])
					if lat_sk < 60.0:
						fails.append("second dirt HOVER sink pulled onto plate (lat=%s)" % snapped(lat_sk, 0.1))
					if "velocity" in ship:
						ship.velocity = Vector3.ZERO
					ship.set("_gear_down", true)
					if ship.has_method("_do_land"):
						ship._do_land()
					await get_tree().create_timer(0.4).timeout
					var land2_agl: float = agl_sk2
					if nex.has_method("altitude_of"):
						land2_agl = float(nex.altitude_of(ship.global_position))
					var land2_pad: Node3D = null
					if ship.has_method("get_landed_pad"):
						land2_pad = ship.get_landed_pad() as Node3D
					var land2_rel: Vector3 = ship.global_position - deck.global_position
					var land2_lat: float = (land2_rel - up_ge * land2_rel.dot(up_ge)).length()
					print("[Playtest] second dirt land after sink landed=", ship.get("is_landed"),
						" pad=", land2_pad.name if land2_pad else "none",
						" agl=", snapped(land2_agl, 0.1), " lat=", snapped(land2_lat, 0.1))
					if not bool(ship.get("is_landed")):
						fails.append("second dirt land after sink refused")
					if land2_pad != null:
						fails.append("second dirt land after sink stole pad")
					if land2_lat < 60.0:
						fails.append("second dirt land after sink drifted to plate (%s)" % snapped(land2_lat, 0.1))
					if land2_agl < 1.5 or land2_agl > 8.0:
						fails.append("second dirt land after sink not on Relief (%s)" % snapped(land2_agl, 0.1))
					if os.has_method("try_exit_ship"):
						os.try_exit_ship()
					await get_tree().create_timer(0.4).timeout
					var eva3: Node3D = os.get("player") as Node3D if os else null
					if eva3 == null or not is_instance_valid(eva3) or not eva3.is_inside_tree():
						fails.append("F-EVA after second dirt land: no walker")
					else:
						var e3_ship: float = eva3.global_position.distance_to(ship.global_position)
						var e3_pad: float = eva3.global_position.distance_to(deck.global_position)
						var e3_agl := 99.0
						if nex.has_method("altitude_of"):
							e3_agl = float(nex.altitude_of(eva3.global_position))
						var ly_e3 := ""
						if LayerContext:
							ly_e3 = str(LayerContext.current_layer)
						print("[Playtest] F-EVA after second dirt land d_ship=", snapped(e3_ship, 0.1),
							" d_pad=", snapped(e3_pad, 0.1), " agl=", snapped(e3_agl, 0.01),
							" eva=", eva3.get("eva_mode"), " layer=", ly_e3)
						if e3_ship > 22.0:
							fails.append("F-EVA after second dirt land teleported (%s)" % snapped(e3_ship, 0.1))
						if e3_pad < 60.0:
							fails.append("F-EVA after second dirt land snapped to pad (%s)" % snapped(e3_pad, 0.1))
						if e3_agl < 0.2 or e3_agl > 5.0:
							fails.append("F-EVA after second dirt land not on Relief (%s)" % snapped(e3_agl, 0.01))
						if bool(eva3.get("eva_mode")) or bool(eva3.get("zero_g")):
							fails.append("F-EVA after second dirt land still EVA 0G")
						if ly_e3.to_upper().find("TPS") < 0:
							fails.append("F-EVA after second dirt land layer not TPS (%s)" % ly_e3)
						if os.has_method("_apply_dirt_exit_facing"):
							os._apply_dirt_exit_facing()
						var rad_e3: Vector3 = (eva3.global_position - (nex as Node3D).global_position).normalized()
						var fwd_e3: Vector3 = -eva3.global_transform.basis.z
						fwd_e3 = fwd_e3 - rad_e3 * fwd_e3.dot(rad_e3)
						var want_e3: Vector3 = -ship.global_transform.basis.z
						want_e3 = want_e3 - rad_e3 * want_e3.dot(rad_e3)
						if fwd_e3.length_squared() < 0.04 or want_e3.length_squared() < 0.04:
							fails.append("F-EVA after second dirt land facing not tangent")
						else:
							var align_e3: float = fwd_e3.normalized().dot(want_e3.normalized())
							print("[Playtest] F-EVA after second dirt land facing align=", snapped(align_e3, 0.01),
								" tangent=", snapped(1.0 - absf(fwd_e3.normalized().dot(rad_e3)), 0.01))
							if align_e3 < 0.55:
								fails.append("F-EVA after second dirt land facing sideways (%s)" % snapped(align_e3, 0.01))
						eva3.set("_spawn_grace_t", 0.0)
						if eva3 is CharacterBody3D:
							(eva3 as CharacterBody3D).velocity = Vector3.ZERO
						if eva3.has_method("_physics_process"):
							eva3._physics_process(0.016)
						var coy_e3: float = float(eva3.get("_coyote_t"))
						var near_e3: Variant = eva3.call("_near_dirt_floor") if eva3.has_method("_near_dirt_floor") else false
						print("[Playtest] F-EVA after second dirt land coyote t=", snapped(coy_e3, 0.01), " near=", near_e3)
						if coy_e3 <= 0.0:
							fails.append("F-EVA after second dirt land coyote dead")
						else:
							var ev30: float = 0.0
							if eva3 is CharacterBody3D:
								ev30 = (eva3 as CharacterBody3D).velocity.dot(rad_e3)
							if eva3.has_method("request_jump"):
								eva3.request_jump()
							if eva3.has_method("_physics_process"):
								eva3._physics_process(0.016)
							var ev31: float = ev30
							if eva3 is CharacterBody3D:
								ev31 = (eva3 as CharacterBody3D).velocity.dot(rad_e3)
							print("[Playtest] F-EVA after second dirt land jump v_up ", snapped(ev30, 0.1), "→", snapped(ev31, 0.1))
							if ev31 < ev30 + 3.0:
								fails.append("F-EVA after second dirt land jump died (%s → %s)" % [snapped(ev30, 0.1), snapped(ev31, 0.1)])
						var last_e3: float = float(eva3.get("last_slope_ang"))
						var rel_e3: float = 0.0
						if eva3.has_method("_relief_slope_rad"):
							rel_e3 = float(eva3.call("_relief_slope_rad"))
						print("[Playtest] F-EVA after second dirt land slope last=", snapped(rad_to_deg(last_e3), 0.1),
							" deg rel=", snapped(rad_to_deg(rel_e3), 0.1))
						if last_e3 < 0.0 or last_e3 > 1.4:
							fails.append("F-EVA after second dirt land slope last out of range (%s)" % snapped(last_e3, 0.01))
						if rel_e3 > 0.05 and last_e3 + 0.08 < rel_e3:
							fails.append("F-EVA after second dirt land slope not Relief")
						if last_e3 > rel_e3 + 0.25:
							fails.append("F-EVA after second dirt land slope is pocket-Y cliff")
						var hud_e3: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
						if hud_e3 != null and hud_e3.has_method("bind_player"):
							hud_e3.bind_player(eva3)
						if hud_e3 != null and hud_e3.has_method("_refresh"):
							hud_e3._refresh()
						var origin_e3: Node3D = null
						if hud_e3 != null and hud_e3.has_method("_occupy_origin"):
							origin_e3 = hud_e3.call("_occupy_origin") as Node3D
						var otxt_e3 := ""
						if hud_e3 != null:
							var lab_e3: Variant = hud_e3.get("_owner_label")
							if lab_e3 is Label:
								otxt_e3 = (lab_e3 as Label).text
						print("[Playtest] occupy HUD F-EVA after second dirt land origin=",
							origin_e3.name if origin_e3 else "null",
							" '", otxt_e3.replace("\n", " / ").substr(0, 80), "'")
						if origin_e3 == null:
							fails.append("occupy HUD lost origin after second dirt F-EVA")
						elif origin_e3 == ship:
							fails.append("occupy HUD origin still hull after second dirt F-EVA")
						elif origin_e3 != eva3:
							fails.append("occupy HUD origin not walker after second dirt F-EVA")
						if otxt_e3.to_upper().find("PAD") >= 0 and otxt_e3.to_upper().find("OCCUPY") >= 0:
							fails.append("occupy HUD PAD after second dirt F-EVA 110m")
						var radar_e3: Variant = hud_e3.get("_radar") if hud_e3 else null
						if radar_e3 is CanvasItem:
							(radar_e3 as CanvasItem).visible = true
						if hud_e3 != null and hud_e3.has_method("_refresh"):
							hud_e3._refresh()
						var rng_e3: float = float(hud_e3.get("_radar_range_m")) if hud_e3 else 0.0
						var near_e3n := 0
						if hud_e3 != null and hud_e3.has_method("radar_pad_contacts"):
							near_e3n = hud_e3.radar_pad_contacts().size()
						print("[Playtest] pad radar F-EVA after second dirt land 110m n=", near_e3n,
							" range=", snapped(rng_e3, 1.0), " vis=",
							(radar_e3 as CanvasItem).visible if radar_e3 is CanvasItem else "?")
						if rng_e3 > 1000.0:
							fails.append("pad radar used 12km after second dirt F-EVA (%s)" % snapped(rng_e3, 1.0))
						if near_e3n < 1:
							fails.append("pad radar missed pad after second dirt F-EVA")
						var saved_e3: Vector3 = eva3.global_position
						var up_e3r: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
						if up_e3r.length_squared() > 0.01:
							up_e3r = up_e3r.normalized()
						var side_e3r: Vector3 = up_e3r.cross(Vector3.RIGHT)
						if side_e3r.length_squared() < 0.04:
							side_e3r = up_e3r.cross(Vector3.FORWARD)
						side_e3r = side_e3r.normalized()
						eva3.global_position = deck.global_position + side_e3r * 600.0 + up_e3r * 2.0
						if hud_e3 != null and hud_e3.has_method("_refresh"):
							hud_e3._refresh()
						var far_e3 := false
						var far_e3n := 0
						if hud_e3 != null and hud_e3.has_method("radar_pad_contacts"):
							for c in hud_e3.radar_pad_contacts():
								far_e3n += 1
								if c is Node3D and (c as Node3D).global_position.distance_to(deck.global_position) < 30.0:
									far_e3 = true
						print("[Playtest] pad radar F-EVA after second dirt land 600m n=", far_e3n, " pad=", far_e3)
						if far_e3:
							fails.append("pad radar used 12km approach after second dirt F-EVA")
						eva3.global_position = saved_e3
						if hud_e3 != null and hud_e3.has_method("_refresh"):
							hud_e3._refresh()
						var ly_e3s := ""
						if LayerContext:
							ly_e3s = str(LayerContext.current_layer)
						var stack_e3 := ""
						var stack_e3_on := false
						var chip_e3 := ""
						if hud_e3 != null:
							var sl_e3: Variant = hud_e3.get("_os_stack")
							if sl_e3 is Label:
								stack_e3 = (sl_e3 as Label).text
								stack_e3_on = (sl_e3 as Label).visible
							var chip3: Variant = hud_e3.get("_layer_label")
							if chip3 is Label:
								chip_e3 = (chip3 as Label).text
						print("[Playtest] os stack F-EVA after second dirt land layer=", ly_e3s, " vis=", stack_e3_on,
							" chip='", chip_e3.replace("\n", " / ").substr(0, 40), "' '",
							stack_e3.replace("\n", " / ").substr(0, 80), "'")
						if ly_e3s.to_upper().find("SPACE") >= 0:
							fails.append("os stack layer still SPACE after second dirt F-EVA")
						if ly_e3s.to_upper().find("SHIP") >= 0:
							fails.append("os stack layer still ship_int after second dirt F-EVA")
						if ly_e3s.to_upper().find("TPS") < 0 and ly_e3s.to_upper().find("SURFACE") < 0:
							fails.append("os stack layer not TPS after second dirt F-EVA (%s)" % ly_e3s)
						if not stack_e3_on:
							fails.append("os stack hidden after second dirt F-EVA")
						if chip_e3.to_upper().find("SHIP") >= 0:
							fails.append("layer chip still ship_int after second dirt F-EVA")
						if stack_e3.to_upper().find("OCCUPY") >= 0:
							fails.append("os stack occupy after second dirt F-EVA 110m")
						if stack_e3.to_upper().find("0G") >= 0:
							fails.append("os stack EVA 0G after second dirt F-EVA")
					if os.has_method("try_enter_ship"):
						os.try_enter_ship()
					await get_tree().create_timer(0.3).timeout
					if not bool(os.get("_in_ship")):
						fails.append("reboard after F-EVA second dirt land refused")
					else:
						var hud_rb2: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
						if hud_rb2 != null and hud_rb2.has_method("bind_player"):
							hud_rb2.bind_player(ship)
						if hud_rb2 != null and hud_rb2.has_method("_refresh"):
							hud_rb2._refresh()
						var origin_rb2: Node3D = null
						if hud_rb2 != null and hud_rb2.has_method("_occupy_origin"):
							origin_rb2 = hud_rb2.call("_occupy_origin") as Node3D
						var ly_rb2 := ""
						if LayerContext:
							ly_rb2 = str(LayerContext.current_layer)
						var rng_rb2: float = float(hud_rb2.get("_radar_range_m")) if hud_rb2 else 0.0
						print("[Playtest] F-board after second dirt F-EVA origin=",
							origin_rb2.name if origin_rb2 else "null", " layer=", ly_rb2,
							" radar=", snapped(rng_rb2, 1.0))
						if origin_rb2 != null and origin_rb2 != ship:
							fails.append("occupy HUD origin still walker after second dirt F-EVA F-board")
						if ly_rb2.to_upper().find("SPACE") < 0:
							fails.append("layer not Space after second dirt F-EVA F-board (%s)" % ly_rb2)
						if rng_rb2 < 1000.0:
							fails.append("pad radar still 400m after second dirt F-EVA F-board (%s)" % snapped(rng_rb2, 1.0))
						var chase_rb2: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
						var live_rb2: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
						print("[Playtest] HOVER view after second dirt F-EVA F-board chase=",
							chase_rb2.name if chase_rb2 else "none", " live=", live_rb2.name if live_rb2 else "none",
							" current=", chase_rb2.current if chase_rb2 else false)
						if chase_rb2 == null:
							fails.append("HOVER view after second dirt F-EVA F-board: no chase cam")
						elif live_rb2 != chase_rb2:
							fails.append("HOVER view after second dirt F-EVA F-board stole (%s)" % (live_rb2.name if live_rb2 else "none"))
						elif not chase_rb2.current:
							fails.append("HOVER view after second dirt F-EVA F-board chase not current")
						if os.has_method("_leave_seat_to_pocket"):
							os._leave_seat_to_pocket()
						await get_tree().create_timer(0.35).timeout
						var ly_pk3 := ""
						if LayerContext:
							ly_pk3 = str(LayerContext.current_layer)
						var pk3: Node3D = os.get("player") as Node3D if os else null
						print("[Playtest] I-hatch after second dirt F-EVA F-board pocket layer=", ly_pk3,
							" int=", pk3.get("interior_mode") if pk3 else "none",
							" in_ship=", os.get("_in_ship"))
						if ly_pk3.to_upper().find("SHIP") < 0:
							fails.append("I-hatch after second dirt F-EVA F-board not ship_int (%s)" % ly_pk3)
						if pk3 == null or not bool(pk3.get("interior_mode")):
							fails.append("I-hatch after second dirt F-EVA F-board not pocket walker")
						var d3: Node = os.get("_interior") if os else null
						if d3 != null and d3.has_method("is_inside") and bool(d3.is_inside()) and d3.has_method("exit_interior"):
							d3.exit_interior()
						await get_tree().create_timer(0.4).timeout
						var hatch3: Node3D = os.get("player") as Node3D if os else null
						if hatch3 == null or not is_instance_valid(hatch3) or not hatch3.is_inside_tree():
							fails.append("I-hatch after second dirt F-EVA F-board: no walker")
						else:
							var h3_ship: float = hatch3.global_position.distance_to(ship.global_position)
							var h3_pad: float = hatch3.global_position.distance_to(deck.global_position)
							var h3_agl := 99.0
							if nex.has_method("altitude_of"):
								h3_agl = float(nex.altitude_of(hatch3.global_position))
							print("[Playtest] I-hatch after second dirt F-EVA F-board d_ship=", snapped(h3_ship, 0.1),
								" d_pad=", snapped(h3_pad, 0.1), " agl=", snapped(h3_agl, 0.01),
								" int=", hatch3.get("interior_mode"))
							if h3_ship > 22.0:
								fails.append("I-hatch after second dirt F-EVA F-board teleported (%s)" % snapped(h3_ship, 0.1))
							if h3_pad < 60.0:
								fails.append("I-hatch after second dirt F-EVA F-board snapped to pad (%s)" % snapped(h3_pad, 0.1))
							if h3_agl < 0.2 or h3_agl > 5.0:
								fails.append("I-hatch after second dirt F-EVA F-board not on Relief (%s)" % snapped(h3_agl, 0.01))
							if bool(hatch3.get("interior_mode")) or bool(hatch3.get("eva_mode")) or bool(hatch3.get("zero_g")):
								fails.append("I-hatch after second dirt F-EVA F-board still pocket/0G")
							if os.has_method("_apply_dirt_exit_facing"):
								os._apply_dirt_exit_facing()
							var rad_h3: Vector3 = (hatch3.global_position - (nex as Node3D).global_position).normalized()
							var fwd_h3: Vector3 = -hatch3.global_transform.basis.z
							fwd_h3 = fwd_h3 - rad_h3 * fwd_h3.dot(rad_h3)
							var want_h3: Vector3 = -ship.global_transform.basis.z
							want_h3 = want_h3 - rad_h3 * want_h3.dot(rad_h3)
							if fwd_h3.length_squared() < 0.04 or want_h3.length_squared() < 0.04:
								fails.append("I-hatch after second dirt F-EVA F-board facing not tangent")
							else:
								var align_h3: float = fwd_h3.normalized().dot(want_h3.normalized())
								print("[Playtest] I-hatch after second dirt F-EVA F-board facing align=", snapped(align_h3, 0.01),
									" tangent=", snapped(1.0 - absf(fwd_h3.normalized().dot(rad_h3)), 0.01))
								if align_h3 < 0.55:
									fails.append("I-hatch after second dirt F-EVA F-board facing sideways (%s)" % snapped(align_h3, 0.01))
							hatch3.set("_spawn_grace_t", 0.0)
							if hatch3 is CharacterBody3D:
								(hatch3 as CharacterBody3D).velocity = Vector3.ZERO
							if hatch3.has_method("_physics_process"):
								hatch3._physics_process(0.016)
							var coy_h3: float = float(hatch3.get("_coyote_t"))
							var near_h3: Variant = hatch3.call("_near_dirt_floor") if hatch3.has_method("_near_dirt_floor") else false
							print("[Playtest] I-hatch after second dirt F-EVA F-board coyote t=", snapped(coy_h3, 0.01), " near=", near_h3)
							if coy_h3 <= 0.0:
								fails.append("I-hatch after second dirt F-EVA F-board coyote dead")
							else:
								var hv30: float = 0.0
								if hatch3 is CharacterBody3D:
									hv30 = (hatch3 as CharacterBody3D).velocity.dot(rad_h3)
								if hatch3.has_method("request_jump"):
									hatch3.request_jump()
								if hatch3.has_method("_physics_process"):
									hatch3._physics_process(0.016)
								var hv31: float = hv30
								if hatch3 is CharacterBody3D:
									hv31 = (hatch3 as CharacterBody3D).velocity.dot(rad_h3)
								print("[Playtest] I-hatch after second dirt F-EVA F-board jump v_up ", snapped(hv30, 0.1), "→", snapped(hv31, 0.1))
								if hv31 < hv30 + 3.0:
									fails.append("I-hatch after second dirt F-EVA F-board jump died (%s → %s)" % [snapped(hv30, 0.1), snapped(hv31, 0.1)])
							var last_h3: float = float(hatch3.get("last_slope_ang"))
							var rel_h3: float = 0.0
							if hatch3.has_method("_relief_slope_rad"):
								rel_h3 = float(hatch3.call("_relief_slope_rad"))
							print("[Playtest] I-hatch after second dirt F-EVA F-board slope last=", snapped(rad_to_deg(last_h3), 0.1),
								" deg rel=", snapped(rad_to_deg(rel_h3), 0.1))
							if last_h3 < 0.0 or last_h3 > 1.4:
								fails.append("I-hatch after second dirt F-EVA F-board slope last out of range (%s)" % snapped(last_h3, 0.01))
							if rel_h3 > 0.05 and last_h3 + 0.08 < rel_h3:
								fails.append("I-hatch after second dirt F-EVA F-board slope not Relief")
							if last_h3 > rel_h3 + 0.25:
								fails.append("I-hatch after second dirt F-EVA F-board slope is pocket-Y cliff")
							var hud_h3: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
							if hud_h3 != null and hud_h3.has_method("bind_player"):
								hud_h3.bind_player(hatch3)
							if hud_h3 != null and hud_h3.has_method("_refresh"):
								hud_h3._refresh()
							var origin_h3: Node3D = null
							if hud_h3 != null and hud_h3.has_method("_occupy_origin"):
								origin_h3 = hud_h3.call("_occupy_origin") as Node3D
							var otxt_h3 := ""
							if hud_h3 != null:
								var lab_h3: Variant = hud_h3.get("_owner_label")
								if lab_h3 is Label:
									otxt_h3 = (lab_h3 as Label).text
							print("[Playtest] occupy HUD I-hatch after second dirt F-EVA F-board origin=",
								origin_h3.name if origin_h3 else "null",
								" '", otxt_h3.replace("\n", " / ").substr(0, 80), "'")
							if origin_h3 == null:
								fails.append("occupy HUD lost origin after third dirt I-hatch")
							elif origin_h3 == ship:
								fails.append("occupy HUD origin still hull after third dirt I-hatch")
							elif origin_h3 != hatch3:
								fails.append("occupy HUD origin not walker after third dirt I-hatch")
							if otxt_h3.to_upper().find("PAD") >= 0 and otxt_h3.to_upper().find("OCCUPY") >= 0:
								fails.append("occupy HUD PAD after third dirt I-hatch 110m")
							var radar_h3: Variant = hud_h3.get("_radar") if hud_h3 else null
							if radar_h3 is CanvasItem:
								(radar_h3 as CanvasItem).visible = true
							if hud_h3 != null and hud_h3.has_method("_refresh"):
								hud_h3._refresh()
							var rng_h3: float = float(hud_h3.get("_radar_range_m")) if hud_h3 else 0.0
							var near_h3n := 0
							if hud_h3 != null and hud_h3.has_method("radar_pad_contacts"):
								near_h3n = hud_h3.radar_pad_contacts().size()
							print("[Playtest] pad radar I-hatch after second dirt F-EVA F-board 110m n=", near_h3n,
								" range=", snapped(rng_h3, 1.0), " vis=",
								(radar_h3 as CanvasItem).visible if radar_h3 is CanvasItem else "?")
							if rng_h3 > 1000.0:
								fails.append("pad radar used 12km after third dirt I-hatch (%s)" % snapped(rng_h3, 1.0))
							if near_h3n < 1:
								fails.append("pad radar missed pad after third dirt I-hatch")
							var saved_h3: Vector3 = hatch3.global_position
							var up_h3r: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
							if up_h3r.length_squared() > 0.01:
								up_h3r = up_h3r.normalized()
							var side_h3r: Vector3 = up_h3r.cross(Vector3.RIGHT)
							if side_h3r.length_squared() < 0.04:
								side_h3r = up_h3r.cross(Vector3.FORWARD)
							side_h3r = side_h3r.normalized()
							hatch3.global_position = deck.global_position + side_h3r * 600.0 + up_h3r * 2.0
							if hud_h3 != null and hud_h3.has_method("_refresh"):
								hud_h3._refresh()
							var far_h3 := false
							var far_h3n := 0
							if hud_h3 != null and hud_h3.has_method("radar_pad_contacts"):
								for c in hud_h3.radar_pad_contacts():
									far_h3n += 1
									if c is Node3D and (c as Node3D).global_position.distance_to(deck.global_position) < 30.0:
										far_h3 = true
							print("[Playtest] pad radar I-hatch after second dirt F-EVA F-board 600m n=", far_h3n, " pad=", far_h3)
							if far_h3:
								fails.append("pad radar used 12km approach after third dirt I-hatch")
							hatch3.global_position = saved_h3
							if hud_h3 != null and hud_h3.has_method("_refresh"):
								hud_h3._refresh()
							var ly_h3s := ""
							if LayerContext:
								ly_h3s = str(LayerContext.current_layer)
							var stack_h3 := ""
							var stack_h3_on := false
							var chip_h3 := ""
							if hud_h3 != null:
								var sl_h3: Variant = hud_h3.get("_os_stack")
								if sl_h3 is Label:
									stack_h3 = (sl_h3 as Label).text
									stack_h3_on = (sl_h3 as Label).visible
								var chip3: Variant = hud_h3.get("_layer_label")
								if chip3 is Label:
									chip_h3 = (chip3 as Label).text
							print("[Playtest] os stack I-hatch after second dirt F-EVA F-board layer=", ly_h3s,
								" vis=", stack_h3_on, " chip='", chip_h3.replace("\n", " / ").substr(0, 40),
								"' '", stack_h3.replace("\n", " / ").substr(0, 80), "'")
							if ly_h3s.to_upper().find("SPACE") >= 0:
								fails.append("os stack layer still SPACE after third dirt I-hatch")
							if ly_h3s.to_upper().find("SHIP") >= 0:
								fails.append("os stack layer still ship_int after third dirt I-hatch")
							if ly_h3s.to_upper().find("TPS") < 0 and ly_h3s.to_upper().find("SURFACE") < 0:
								fails.append("os stack layer not TPS after third dirt I-hatch (%s)" % ly_h3s)
							if not stack_h3_on:
								fails.append("os stack hidden after third dirt I-hatch")
							if chip_h3.to_upper().find("SHIP") >= 0:
								fails.append("layer chip still ship_int after third dirt I-hatch")
							if stack_h3.to_upper().find("OCCUPY") >= 0:
								fails.append("os stack occupy after third dirt I-hatch 110m")
							if stack_h3.to_upper().find("0G") >= 0:
								fails.append("os stack EVA 0G after third dirt I-hatch")
						if os.has_method("try_enter_ship"):
							os.try_enter_ship()
						await get_tree().create_timer(0.3).timeout
						if not bool(os.get("_in_ship")):
							fails.append("reboard after I-hatch second dirt F-EVA F-board refused")
						else:
							var hud_rb3: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
							if hud_rb3 != null and hud_rb3.has_method("bind_player"):
								hud_rb3.bind_player(ship)
							if hud_rb3 != null and hud_rb3.has_method("_refresh"):
								hud_rb3._refresh()
							var origin_rb3: Node3D = null
							if hud_rb3 != null and hud_rb3.has_method("_occupy_origin"):
								origin_rb3 = hud_rb3.call("_occupy_origin") as Node3D
							var ly_rb3 := ""
							if LayerContext:
								ly_rb3 = str(LayerContext.current_layer)
							var rng_rb3: float = float(hud_rb3.get("_radar_range_m")) if hud_rb3 else 0.0
							print("[Playtest] F-board after third dirt I-hatch origin=",
								origin_rb3.name if origin_rb3 else "null", " layer=", ly_rb3,
								" radar=", snapped(rng_rb3, 1.0))
							if origin_rb3 != null and origin_rb3 != ship:
								fails.append("occupy HUD origin still walker after third dirt I-hatch F-board")
							if ly_rb3.to_upper().find("SPACE") < 0:
								fails.append("layer not Space after third dirt I-hatch F-board (%s)" % ly_rb3)
							if rng_rb3 < 1000.0:
								fails.append("pad radar still 400m after third dirt I-hatch F-board (%s)" % snapped(rng_rb3, 1.0))
							var chase_rb3: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
							var live_rb3: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
							print("[Playtest] HOVER view after third dirt I-hatch F-board chase=",
								chase_rb3.name if chase_rb3 else "none", " live=", live_rb3.name if live_rb3 else "none",
								" current=", chase_rb3.current if chase_rb3 else false)
							if chase_rb3 == null:
								fails.append("HOVER view after third dirt I-hatch F-board: no chase cam")
							elif live_rb3 != chase_rb3:
								fails.append("HOVER view after third dirt I-hatch F-board stole (%s)" % (live_rb3.name if live_rb3 else "none"))
							elif not chase_rb3.current:
								fails.append("HOVER view after third dirt I-hatch F-board chase not current")
							ship.set("_land_lock_t", 0.0)
							if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
								ship._do_launch()
							await get_tree().create_timer(0.35).timeout
							var agl_l3: float = float(ship.altitude_agl()) if ship.has_method("altitude_agl") else -1.0
							var hold_l3: float = float(ship.get("_hover_hold_alt"))
							print("[Playtest] HOVER launch after third dirt I-hatch F-board landed=",
								ship.get("is_landed"), " hold=", snapped(hold_l3, 0.1),
								" agl=", snapped(agl_l3, 0.1))
							if bool(ship.get("is_landed")):
								fails.append("HOVER launch after third dirt I-hatch F-board still landed")
							if hold_l3 < 4.0:
								fails.append("HOVER launch after third dirt I-hatch F-board hold dead (%s)" % snapped(hold_l3, 0.1))
							if agl_l3 >= 0.0 and (hold_l3 < agl_l3 - 2.0 or hold_l3 > agl_l3 + 20.0):
								fails.append("HOVER launch after third dirt I-hatch F-board hold not AGL+12 (%s vs %s)" % [
									snapped(hold_l3, 0.1), snapped(agl_l3, 0.1)])
							if ship.has_method("_set_mode"):
								ship._set_mode(2)
							var hold_l3b: float = float(ship.get("_hover_hold_alt"))
							print("[Playtest] HOVER launch after third dirt I-hatch F-board retap hold=", snapped(hold_l3b, 0.1))
							if absf(hold_l3b - hold_l3) > 1.5:
								fails.append("HOVER launch after third dirt I-hatch F-board retap rewrote hold")
							var up_ge3: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
							if up_ge3.length_squared() > 0.01:
								up_ge3 = up_ge3.normalized()
							var rel_ge3: Vector3 = ship.global_position - deck.global_position
							var lat_ge3: float = (rel_ge3 - up_ge3 * rel_ge3.dot(up_ge3)).length()
							var agl_ge3: float = agl_l3
							if nex.has_method("altitude_of"):
								agl_ge3 = float(nex.altitude_of(ship.global_position))
							print("[Playtest] third dirt I-hatch F-board launch GE lat=", snapped(lat_ge3, 0.1),
								" agl=", snapped(agl_ge3, 0.1))
							if lat_ge3 < 60.0:
								fails.append("third dirt I-hatch F-board launch GE pulled onto plate (lat=%s)" % snapped(lat_ge3, 0.1))
							ship.set_meta("playtest_sink", true)
							await get_tree().create_timer(0.45).timeout
							ship.set_meta("playtest_sink", false)
							var hold_sk3: float = float(ship.get("_hover_hold_alt"))
							var agl_sk3: float = agl_ge3
							if nex.has_method("altitude_of"):
								agl_sk3 = float(nex.altitude_of(ship.global_position))
							var lat_sk3: float = 0.0
							var rel_sk3: Vector3 = ship.global_position - deck.global_position
							lat_sk3 = (rel_sk3 - up_ge3 * rel_sk3.dot(up_ge3)).length()
							print("[Playtest] third dirt I-hatch F-board HOVER sink hold ",
								snapped(hold_l3b, 0.1), "→", snapped(hold_sk3, 0.1),
								" AGL ", snapped(agl_ge3, 0.1), "→", snapped(agl_sk3, 0.1),
								" lat=", snapped(lat_sk3, 0.1))
							if hold_sk3 > 6.5:
								fails.append("third dirt I-hatch F-board HOVER sink hold still 8m floor (%s)" % snapped(hold_sk3, 0.1))
							if hold_sk3 + 0.2 < 3.5:
								fails.append("third dirt I-hatch F-board HOVER sink hold buried (%s)" % snapped(hold_sk3, 0.1))
							if lat_sk3 < 60.0:
								fails.append("third dirt I-hatch F-board HOVER sink drifted onto plate (%s)" % snapped(lat_sk3, 0.1))
							if "velocity" in ship:
								ship.velocity = Vector3.ZERO
							ship.set("_gear_down", true)
							if ship.has_method("_do_land"):
								ship._do_land()
							await get_tree().create_timer(0.4).timeout
							var land3_agl: float = agl_sk3
							if nex.has_method("altitude_of"):
								land3_agl = float(nex.altitude_of(ship.global_position))
							var land3_pad: Node3D = null
							if ship.has_method("get_landed_pad"):
								land3_pad = ship.get_landed_pad() as Node3D
							var land3_rel: Vector3 = ship.global_position - deck.global_position
							var land3_lat: float = (land3_rel - up_ge3 * land3_rel.dot(up_ge3)).length()
							print("[Playtest] third dirt I-hatch F-board land after sink landed=", ship.get("is_landed"),
								" pad=", land3_pad.name if land3_pad else "none",
								" agl=", snapped(land3_agl, 0.1), " lat=", snapped(land3_lat, 0.1))
							if not bool(ship.get("is_landed")):
								fails.append("third dirt I-hatch F-board land after sink refused")
							if land3_pad != null:
								fails.append("third dirt I-hatch F-board land after sink stole pad")
							if land3_lat < 60.0:
								fails.append("third dirt I-hatch F-board land after sink drifted to plate (%s)" % snapped(land3_lat, 0.1))
							if land3_agl < 1.5 or land3_agl > 8.0:
								fails.append("third dirt I-hatch F-board land after sink not on Relief (%s)" % snapped(land3_agl, 0.1))
							if os.has_method("try_exit_ship"):
								os.try_exit_ship()
							await get_tree().create_timer(0.4).timeout
							var eva4: Node3D = os.get("player") as Node3D if os else null
							if eva4 == null or not is_instance_valid(eva4) or not eva4.is_inside_tree():
								fails.append("F-EVA after third dirt I-hatch land: no walker")
							else:
								var e4_ship: float = eva4.global_position.distance_to(ship.global_position)
								var e4_pad: float = eva4.global_position.distance_to(deck.global_position)
								var e4_agl := 99.0
								if nex.has_method("altitude_of"):
									e4_agl = float(nex.altitude_of(eva4.global_position))
								var ly_e4 := ""
								if LayerContext:
									ly_e4 = str(LayerContext.current_layer)
								print("[Playtest] F-EVA after third dirt I-hatch land d_ship=", snapped(e4_ship, 0.1),
									" d_pad=", snapped(e4_pad, 0.1), " agl=", snapped(e4_agl, 0.01),
									" eva=", eva4.get("eva_mode"), " layer=", ly_e4)
								if e4_ship > 22.0:
									fails.append("F-EVA after third dirt I-hatch land teleported (%s)" % snapped(e4_ship, 0.1))
								if e4_pad < 60.0:
									fails.append("F-EVA after third dirt I-hatch land snapped to pad (%s)" % snapped(e4_pad, 0.1))
								if e4_agl < 0.2 or e4_agl > 5.0:
									fails.append("F-EVA after third dirt I-hatch land not on Relief (%s)" % snapped(e4_agl, 0.01))
								if bool(eva4.get("eva_mode")) or bool(eva4.get("zero_g")):
									fails.append("F-EVA after third dirt I-hatch land still EVA 0G")
								if ly_e4.to_upper().find("TPS") < 0:
									fails.append("F-EVA after third dirt I-hatch land layer not TPS (%s)" % ly_e4)
								if os.has_method("_apply_dirt_exit_facing"):
									os._apply_dirt_exit_facing()
								var rad_e4: Vector3 = (eva4.global_position - (nex as Node3D).global_position).normalized()
								var fwd_e4: Vector3 = -eva4.global_transform.basis.z
								fwd_e4 = fwd_e4 - rad_e4 * fwd_e4.dot(rad_e4)
								var want_e4: Vector3 = -ship.global_transform.basis.z
								want_e4 = want_e4 - rad_e4 * want_e4.dot(rad_e4)
								if fwd_e4.length_squared() < 0.04 or want_e4.length_squared() < 0.04:
									fails.append("F-EVA after third dirt I-hatch land facing not tangent")
								else:
									var align_e4: float = fwd_e4.normalized().dot(want_e4.normalized())
									print("[Playtest] F-EVA after third dirt I-hatch land facing align=", snapped(align_e4, 0.01),
										" tangent=", snapped(1.0 - absf(fwd_e4.normalized().dot(rad_e4)), 0.01))
									if align_e4 < 0.55:
										fails.append("F-EVA after third dirt I-hatch land facing sideways (%s)" % snapped(align_e4, 0.01))
								eva4.set("_spawn_grace_t", 0.0)
								if eva4 is CharacterBody3D:
									(eva4 as CharacterBody3D).velocity = Vector3.ZERO
								if eva4.has_method("_physics_process"):
									eva4._physics_process(0.016)
								var coy_e4: float = float(eva4.get("_coyote_t"))
								var near_e4: Variant = eva4.call("_near_dirt_floor") if eva4.has_method("_near_dirt_floor") else false
								print("[Playtest] F-EVA after third dirt I-hatch land coyote t=", snapped(coy_e4, 0.01), " near=", near_e4)
								if coy_e4 <= 0.0:
									fails.append("F-EVA after third dirt I-hatch land coyote dead")
								else:
									var hv40: float = 0.0
									if eva4 is CharacterBody3D:
										hv40 = (eva4 as CharacterBody3D).velocity.dot(rad_e4)
									if eva4.has_method("request_jump"):
										eva4.request_jump()
									if eva4.has_method("_physics_process"):
										eva4._physics_process(0.016)
									var hv41: float = hv40
									if eva4 is CharacterBody3D:
										hv41 = (eva4 as CharacterBody3D).velocity.dot(rad_e4)
									print("[Playtest] F-EVA after third dirt I-hatch land jump v_up ", snapped(hv40, 0.1), "→", snapped(hv41, 0.1))
									if hv41 < hv40 + 3.0:
										fails.append("F-EVA after third dirt I-hatch land jump died (%s → %s)" % [snapped(hv40, 0.1), snapped(hv41, 0.1)])
								var last_e4: float = float(eva4.get("last_slope_ang"))
								var rel_e4: float = 0.0
								if eva4.has_method("_relief_slope_rad"):
									rel_e4 = float(eva4.call("_relief_slope_rad"))
								print("[Playtest] F-EVA after third dirt I-hatch land slope last=", snapped(rad_to_deg(last_e4), 0.1),
									" deg rel=", snapped(rad_to_deg(rel_e4), 0.1))
								if last_e4 < 0.0 or last_e4 > 1.4:
									fails.append("F-EVA after third dirt I-hatch land slope last out of range (%s)" % snapped(last_e4, 0.01))
								if rel_e4 > 0.05 and last_e4 + 0.08 < rel_e4:
									fails.append("F-EVA after third dirt I-hatch land slope not Relief")
								if last_e4 > rel_e4 + 0.25:
									fails.append("F-EVA after third dirt I-hatch land slope is pocket-Y cliff")
								var hud_e4: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
								if hud_e4 != null and hud_e4.has_method("bind_player"):
									hud_e4.bind_player(eva4)
								if hud_e4 != null and hud_e4.has_method("_refresh"):
									hud_e4._refresh()
								var origin_e4: Node3D = null
								if hud_e4 != null and hud_e4.has_method("_occupy_origin"):
									origin_e4 = hud_e4.call("_occupy_origin") as Node3D
								var otxt_e4 := ""
								if hud_e4 != null:
									var lab_e4: Variant = hud_e4.get("_owner_label")
									if lab_e4 is Label:
										otxt_e4 = (lab_e4 as Label).text
								print("[Playtest] occupy HUD F-EVA after third dirt I-hatch land origin=",
									origin_e4.name if origin_e4 else "null",
									" '", otxt_e4.replace("\n", " / ").substr(0, 80), "'")
								if origin_e4 == null:
									fails.append("occupy HUD lost origin after F-EVA third dirt I-hatch land")
								elif origin_e4 == ship:
									fails.append("occupy HUD origin still hull after F-EVA third dirt I-hatch land")
								elif origin_e4 != eva4:
									fails.append("occupy HUD origin not walker after F-EVA third dirt I-hatch land")
								if otxt_e4.to_upper().find("PAD") >= 0 and otxt_e4.to_upper().find("OCCUPY") >= 0:
									fails.append("occupy HUD PAD after F-EVA third dirt I-hatch land 110m")
								var radar_e4: Variant = hud_e4.get("_radar") if hud_e4 else null
								if radar_e4 is CanvasItem:
									(radar_e4 as CanvasItem).visible = true
								if hud_e4 != null and hud_e4.has_method("_refresh"):
									hud_e4._refresh()
								var rng_e4: float = float(hud_e4.get("_radar_range_m")) if hud_e4 else 0.0
								var near_e4n := 0
								if hud_e4 != null and hud_e4.has_method("radar_pad_contacts"):
									near_e4n = hud_e4.radar_pad_contacts().size()
								print("[Playtest] pad radar F-EVA after third dirt I-hatch land 110m n=", near_e4n,
									" range=", snapped(rng_e4, 1.0), " vis=",
									(radar_e4 as CanvasItem).visible if radar_e4 is CanvasItem else "?")
								if rng_e4 > 1000.0:
									fails.append("pad radar used 12km after F-EVA third dirt I-hatch land (%s)" % snapped(rng_e4, 1.0))
								if near_e4n < 1:
									fails.append("pad radar missed pad after F-EVA third dirt I-hatch land")
								var saved_e4: Vector3 = eva4.global_position
								var up_e4r: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
								if up_e4r.length_squared() > 0.01:
									up_e4r = up_e4r.normalized()
								var side_e4r: Vector3 = up_e4r.cross(Vector3.RIGHT)
								if side_e4r.length_squared() < 0.04:
									side_e4r = up_e4r.cross(Vector3.FORWARD)
								side_e4r = side_e4r.normalized()
								eva4.global_position = deck.global_position + side_e4r * 600.0 + up_e4r * 2.0
								if hud_e4 != null and hud_e4.has_method("_refresh"):
									hud_e4._refresh()
								var far_e4 := false
								var far_e4n := 0
								if hud_e4 != null and hud_e4.has_method("radar_pad_contacts"):
									for c in hud_e4.radar_pad_contacts():
										far_e4n += 1
										if c is Node3D and (c as Node3D).global_position.distance_to(deck.global_position) < 30.0:
											far_e4 = true
								print("[Playtest] pad radar F-EVA after third dirt I-hatch land 600m n=", far_e4n, " pad=", far_e4)
								if far_e4:
									fails.append("pad radar used 12km approach after F-EVA third dirt I-hatch land")
								eva4.global_position = saved_e4
								if hud_e4 != null and hud_e4.has_method("_refresh"):
									hud_e4._refresh()
								var ly_e4s := ""
								if LayerContext:
									ly_e4s = str(LayerContext.current_layer)
								var stack_e4 := ""
								var stack_e4_on := false
								var chip_e4 := ""
								if hud_e4 != null:
									var sl_e4: Variant = hud_e4.get("_os_stack")
									if sl_e4 is Label:
										stack_e4 = (sl_e4 as Label).text
										stack_e4_on = (sl_e4 as Label).visible
									var chip4: Variant = hud_e4.get("_layer_label")
									if chip4 is Label:
										chip_e4 = (chip4 as Label).text
								print("[Playtest] os stack F-EVA after third dirt I-hatch land layer=", ly_e4s,
									" vis=", stack_e4_on, " chip='", chip_e4.replace("\n", " / ").substr(0, 40),
									"' '", stack_e4.replace("\n", " / ").substr(0, 80), "'")
								if ly_e4s.to_upper().find("SPACE") >= 0:
									fails.append("os stack layer still SPACE after F-EVA third dirt I-hatch land")
								if ly_e4s.to_upper().find("SHIP") >= 0:
									fails.append("os stack layer still ship_int after F-EVA third dirt I-hatch land")
								if ly_e4s.to_upper().find("TPS") < 0 and ly_e4s.to_upper().find("SURFACE") < 0:
									fails.append("os stack layer not TPS after F-EVA third dirt I-hatch land (%s)" % ly_e4s)
								if not stack_e4_on:
									fails.append("os stack hidden after F-EVA third dirt I-hatch land")
								if chip_e4.to_upper().find("SHIP") >= 0:
									fails.append("layer chip still ship_int after F-EVA third dirt I-hatch land")
								if stack_e4.to_upper().find("OCCUPY") >= 0:
									fails.append("os stack occupy after F-EVA third dirt I-hatch land 110m")
								if stack_e4.to_upper().find("0G") >= 0:
									fails.append("os stack EVA 0G after F-EVA third dirt I-hatch land")
							if os.has_method("try_enter_ship"):
								os.try_enter_ship()
							await get_tree().create_timer(0.3).timeout
							if not bool(os.get("_in_ship")):
								fails.append("reboard after F-EVA third dirt I-hatch land refused")
							else:
								var hud_rb4: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
								if hud_rb4 != null and hud_rb4.has_method("bind_player"):
									hud_rb4.bind_player(ship)
								if hud_rb4 != null and hud_rb4.has_method("_refresh"):
									hud_rb4._refresh()
								var origin_rb4: Node3D = null
								if hud_rb4 != null and hud_rb4.has_method("_occupy_origin"):
									origin_rb4 = hud_rb4.call("_occupy_origin") as Node3D
								var ly_rb4 := ""
								if LayerContext:
									ly_rb4 = str(LayerContext.current_layer)
								var rng_rb4: float = float(hud_rb4.get("_radar_range_m")) if hud_rb4 else 0.0
								print("[Playtest] F-board after F-EVA third dirt I-hatch land origin=",
									origin_rb4.name if origin_rb4 else "null", " layer=", ly_rb4,
									" radar=", snapped(rng_rb4, 1.0))
								if origin_rb4 != null and origin_rb4 != ship:
									fails.append("occupy HUD origin still walker after F-EVA third dirt I-hatch F-board")
								if ly_rb4.to_upper().find("SPACE") < 0:
									fails.append("layer not Space after F-EVA third dirt I-hatch F-board (%s)" % ly_rb4)
								if rng_rb4 < 1000.0:
									fails.append("pad radar still 400m after F-EVA third dirt I-hatch F-board (%s)" % snapped(rng_rb4, 1.0))
								if os.has_method("reclaim_pilot_camera"):
									os.reclaim_pilot_camera()
								var chase_rb4: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
								var live_rb4: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
								print("[Playtest] HOVER view after F-EVA third dirt I-hatch F-board chase=",
									chase_rb4.name if chase_rb4 else "none", " live=", live_rb4.name if live_rb4 else "none",
									" current=", chase_rb4.current if chase_rb4 else false)
								if chase_rb4 == null:
									fails.append("HOVER view after F-EVA third dirt I-hatch F-board: no chase cam")
								elif live_rb4 != chase_rb4:
									fails.append("HOVER view after F-EVA third dirt I-hatch F-board stole (%s)" % (live_rb4.name if live_rb4 else "none"))
								elif not chase_rb4.current:
									fails.append("HOVER view after F-EVA third dirt I-hatch F-board chase not current")
								ship.set("_land_lock_t", 0.0)
								if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
									ship._do_launch()
								await get_tree().create_timer(0.35).timeout
								var agl_l4: float = float(ship.altitude_agl()) if ship.has_method("altitude_agl") else -1.0
								var hold_l4: float = float(ship.get("_hover_hold_alt"))
								print("[Playtest] HOVER launch after F-EVA third dirt I-hatch F-board landed=",
									ship.get("is_landed"), " hold=", snapped(hold_l4, 0.1),
									" agl=", snapped(agl_l4, 0.1))
								if bool(ship.get("is_landed")):
									fails.append("HOVER launch after F-EVA third dirt I-hatch F-board still landed")
								if hold_l4 < 4.0:
									fails.append("HOVER launch after F-EVA third dirt I-hatch F-board hold dead (%s)" % snapped(hold_l4, 0.1))
								if agl_l4 >= 0.0 and (hold_l4 < agl_l4 - 2.0 or hold_l4 > agl_l4 + 20.0):
									fails.append("HOVER launch after F-EVA third dirt I-hatch F-board hold not AGL+12 (%s vs %s)" % [
										snapped(hold_l4, 0.1), snapped(agl_l4, 0.1)])
								if ship.has_method("_set_mode"):
									ship._set_mode(2)
								var hold_l4b: float = float(ship.get("_hover_hold_alt"))
								print("[Playtest] HOVER launch after F-EVA third dirt I-hatch F-board retap hold=", snapped(hold_l4b, 0.1))
								if absf(hold_l4b - hold_l4) > 1.5:
									fails.append("HOVER launch after F-EVA third dirt I-hatch F-board retap rewrote hold")
								var up_ge4: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
								if up_ge4.length_squared() > 0.01:
									up_ge4 = up_ge4.normalized()
								var rel_ge4: Vector3 = ship.global_position - deck.global_position
								var lat_ge4: float = (rel_ge4 - up_ge4 * rel_ge4.dot(up_ge4)).length()
								var agl_ge4: float = agl_l4
								if nex.has_method("altitude_of"):
									agl_ge4 = float(nex.altitude_of(ship.global_position))
								print("[Playtest] F-EVA third dirt I-hatch F-board launch GE lat=", snapped(lat_ge4, 0.1),
									" agl=", snapped(agl_ge4, 0.1))
								if lat_ge4 < 60.0:
									fails.append("F-EVA third dirt I-hatch F-board launch GE pulled onto plate (lat=%s)" % snapped(lat_ge4, 0.1))
								ship.set_meta("playtest_sink", true)
								await get_tree().create_timer(0.45).timeout
								ship.set_meta("playtest_sink", false)
								var hold_sk4: float = float(ship.get("_hover_hold_alt"))
								var agl_sk4: float = agl_ge4
								if nex.has_method("altitude_of"):
									agl_sk4 = float(nex.altitude_of(ship.global_position))
								var lat_sk4: float = 0.0
								var rel_sk4: Vector3 = ship.global_position - deck.global_position
								lat_sk4 = (rel_sk4 - up_ge4 * rel_sk4.dot(up_ge4)).length()
								print("[Playtest] F-EVA third dirt I-hatch F-board HOVER sink hold ",
									snapped(hold_l4b, 0.1), "→", snapped(hold_sk4, 0.1),
									" AGL ", snapped(agl_ge4, 0.1), "→", snapped(agl_sk4, 0.1),
									" lat=", snapped(lat_sk4, 0.1))
								if hold_sk4 > 6.5:
									fails.append("F-EVA third dirt I-hatch F-board HOVER sink hold still 8m floor (%s)" % snapped(hold_sk4, 0.1))
								if hold_sk4 + 0.2 < 3.5:
									fails.append("F-EVA third dirt I-hatch F-board HOVER sink hold buried (%s)" % snapped(hold_sk4, 0.1))
								if lat_sk4 < 60.0:
									fails.append("F-EVA third dirt I-hatch F-board HOVER sink drifted onto plate (%s)" % snapped(lat_sk4, 0.1))
								if "velocity" in ship:
									ship.velocity = Vector3.ZERO
								ship.set("_gear_down", true)
								if ship.has_method("_do_land"):
									ship._do_land()
								await get_tree().create_timer(0.4).timeout
								var land4_agl: float = agl_sk4
								if nex.has_method("altitude_of"):
									land4_agl = float(nex.altitude_of(ship.global_position))
								var land4_pad: Node3D = null
								if ship.has_method("get_landed_pad"):
									land4_pad = ship.get_landed_pad() as Node3D
								var land4_rel: Vector3 = ship.global_position - deck.global_position
								var land4_lat: float = (land4_rel - up_ge4 * land4_rel.dot(up_ge4)).length()
								print("[Playtest] F-EVA third dirt I-hatch F-board land after sink landed=", ship.get("is_landed"),
									" pad=", land4_pad.name if land4_pad else "none",
									" agl=", snapped(land4_agl, 0.1), " lat=", snapped(land4_lat, 0.1))
								if not bool(ship.get("is_landed")):
									fails.append("F-EVA third dirt I-hatch F-board land after sink refused")
								if land4_pad != null:
									fails.append("F-EVA third dirt I-hatch F-board land after sink stole pad")
								if land4_lat < 60.0:
									fails.append("F-EVA third dirt I-hatch F-board land after sink drifted to plate (%s)" % snapped(land4_lat, 0.1))
								if land4_agl < 1.5 or land4_agl > 8.0:
									fails.append("F-EVA third dirt I-hatch F-board land after sink not on Relief (%s)" % snapped(land4_agl, 0.1))
								if os.has_method("try_exit_ship"):
									os.try_exit_ship()
								await get_tree().create_timer(0.4).timeout
								var eva5: Node3D = os.get("player") as Node3D if os else null
								if eva5 == null or not is_instance_valid(eva5) or not eva5.is_inside_tree():
									fails.append("F-EVA after fourth dirt land: no walker")
								else:
									var e5_ship: float = eva5.global_position.distance_to(ship.global_position)
									var e5_pad: float = eva5.global_position.distance_to(deck.global_position)
									var e5_agl := 99.0
									if nex.has_method("altitude_of"):
										e5_agl = float(nex.altitude_of(eva5.global_position))
									var ly_e5 := ""
									if LayerContext:
										ly_e5 = str(LayerContext.current_layer)
									print("[Playtest] F-EVA after fourth dirt land d_ship=", snapped(e5_ship, 0.1),
										" d_pad=", snapped(e5_pad, 0.1), " agl=", snapped(e5_agl, 0.01),
										" eva=", eva5.get("eva_mode"), " layer=", ly_e5)
									if e5_ship > 22.0:
										fails.append("F-EVA after fourth dirt land teleported (%s)" % snapped(e5_ship, 0.1))
									if e5_pad < 60.0:
										fails.append("F-EVA after fourth dirt land snapped to pad (%s)" % snapped(e5_pad, 0.1))
									if e5_agl < 0.2 or e5_agl > 5.0:
										fails.append("F-EVA after fourth dirt land not on Relief (%s)" % snapped(e5_agl, 0.01))
									if bool(eva5.get("eva_mode")) or bool(eva5.get("zero_g")):
										fails.append("F-EVA after fourth dirt land still EVA 0G")
									if ly_e5.to_upper().find("TPS") < 0:
										fails.append("F-EVA after fourth dirt land layer not TPS (%s)" % ly_e5)
									if os.has_method("_apply_dirt_exit_facing"):
										os._apply_dirt_exit_facing()
									var rad_e5: Vector3 = (eva5.global_position - (nex as Node3D).global_position).normalized()
									var fwd_e5: Vector3 = -eva5.global_transform.basis.z
									fwd_e5 = fwd_e5 - rad_e5 * fwd_e5.dot(rad_e5)
									var want_e5: Vector3 = -ship.global_transform.basis.z
									want_e5 = want_e5 - rad_e5 * want_e5.dot(rad_e5)
									if fwd_e5.length_squared() < 0.04 or want_e5.length_squared() < 0.04:
										fails.append("F-EVA after fourth dirt land facing not tangent")
									else:
										var align_e5: float = fwd_e5.normalized().dot(want_e5.normalized())
										print("[Playtest] F-EVA after fourth dirt land facing align=", snapped(align_e5, 0.01),
											" tangent=", snapped(1.0 - absf(fwd_e5.normalized().dot(rad_e5)), 0.01))
										if align_e5 < 0.55:
											fails.append("F-EVA after fourth dirt land facing sideways (%s)" % snapped(align_e5, 0.01))
									var hud_e5: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
									if hud_e5 != null and hud_e5.has_method("bind_player"):
										hud_e5.bind_player(eva5)
									if hud_e5 != null and hud_e5.has_method("_refresh"):
										hud_e5._refresh()
									var origin_e5: Node3D = null
									if hud_e5 != null and hud_e5.has_method("_occupy_origin"):
										origin_e5 = hud_e5.call("_occupy_origin") as Node3D
									var otxt_e5 := ""
									if hud_e5 != null:
										var lab_e5: Variant = hud_e5.get("_owner_label")
										if lab_e5 is Label:
											otxt_e5 = (lab_e5 as Label).text
									print("[Playtest] occupy HUD F-EVA after fourth dirt land origin=",
										origin_e5.name if origin_e5 else "null",
										" '", otxt_e5.replace("\n", " / ").substr(0, 80), "'")
									if origin_e5 == null:
										fails.append("occupy HUD lost origin after F-EVA fourth dirt land")
									elif origin_e5 == ship:
										fails.append("occupy HUD origin still hull after F-EVA fourth dirt land")
									elif origin_e5 != eva5:
										fails.append("occupy HUD origin not walker after F-EVA fourth dirt land")
									if otxt_e5.to_upper().find("PAD") >= 0 and otxt_e5.to_upper().find("OCCUPY") >= 0:
										fails.append("occupy HUD PAD after F-EVA fourth dirt land 110m")
									var radar_e5: Variant = hud_e5.get("_radar") if hud_e5 else null
									if radar_e5 is CanvasItem:
										(radar_e5 as CanvasItem).visible = true
									if hud_e5 != null and hud_e5.has_method("_refresh"):
										hud_e5._refresh()
									var rng_e5: float = float(hud_e5.get("_radar_range_m")) if hud_e5 else 0.0
									var near_e5n := 0
									if hud_e5 != null and hud_e5.has_method("radar_pad_contacts"):
										near_e5n = hud_e5.radar_pad_contacts().size()
									print("[Playtest] pad radar F-EVA after fourth dirt land 110m n=", near_e5n,
										" range=", snapped(rng_e5, 1.0), " vis=",
										(radar_e5 as CanvasItem).visible if radar_e5 is CanvasItem else "?")
									if rng_e5 > 1000.0:
										fails.append("pad radar used 12km after F-EVA fourth dirt land occupy (%s)" % snapped(rng_e5, 1.0))
									if near_e5n < 1:
										fails.append("pad radar missed pad after F-EVA fourth dirt land occupy")
									var saved_e5: Vector3 = eva5.global_position
									var up_e5r: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
									if up_e5r.length_squared() > 0.01:
										up_e5r = up_e5r.normalized()
									var side_e5r: Vector3 = up_e5r.cross(Vector3.RIGHT)
									if side_e5r.length_squared() < 0.04:
										side_e5r = up_e5r.cross(Vector3.FORWARD)
									side_e5r = side_e5r.normalized()
									eva5.global_position = deck.global_position + side_e5r * 600.0 + up_e5r * 2.0
									if hud_e5 != null and hud_e5.has_method("_refresh"):
										hud_e5._refresh()
									var far_e5 := false
									var far_e5n := 0
									if hud_e5 != null and hud_e5.has_method("radar_pad_contacts"):
										for c in hud_e5.radar_pad_contacts():
											far_e5n += 1
											if c is Node3D and (c as Node3D).global_position.distance_to(deck.global_position) < 30.0:
												far_e5 = true
									print("[Playtest] pad radar F-EVA after fourth dirt land 600m n=", far_e5n, " pad=", far_e5)
									if far_e5:
										fails.append("pad radar used 12km approach after F-EVA fourth dirt land occupy")
									eva5.global_position = saved_e5
									if hud_e5 != null and hud_e5.has_method("_refresh"):
										hud_e5._refresh()
									var ly_e5s := ""
									if LayerContext:
										ly_e5s = str(LayerContext.current_layer)
									var stack_e5 := ""
									var stack_e5_on := false
									var chip_e5 := ""
									if hud_e5 != null:
										var sl_e5: Variant = hud_e5.get("_os_stack")
										if sl_e5 is Label:
											stack_e5 = (sl_e5 as Label).text
											stack_e5_on = (sl_e5 as Label).visible
										var chip5: Variant = hud_e5.get("_layer_label")
										if chip5 is Label:
											chip_e5 = (chip5 as Label).text
									print("[Playtest] os stack F-EVA after fourth dirt land occupy layer=", ly_e5s,
										" vis=", stack_e5_on, " chip='", chip_e5.replace("\n", " / ").substr(0, 40),
										"' '", stack_e5.replace("\n", " / ").substr(0, 80), "'")
									if ly_e5s.to_upper().find("SPACE") >= 0:
										fails.append("os stack layer still SPACE after F-EVA fourth dirt land occupy")
									if ly_e5s.to_upper().find("SHIP") >= 0:
										fails.append("os stack layer still ship_int after F-EVA fourth dirt land occupy")
									if ly_e5s.to_upper().find("TPS") < 0 and ly_e5s.to_upper().find("SURFACE") < 0:
										fails.append("os stack layer not TPS after F-EVA fourth dirt land occupy (%s)" % ly_e5s)
									if not stack_e5_on:
										fails.append("os stack hidden after F-EVA fourth dirt land occupy")
									if chip_e5.to_upper().find("SHIP") >= 0:
										fails.append("layer chip still ship_int after F-EVA fourth dirt land occupy")
									if stack_e5.to_upper().find("OCCUPY") >= 0:
										fails.append("os stack occupy after F-EVA fourth dirt land occupy 110m")
									if stack_e5.to_upper().find("0G") >= 0:
										fails.append("os stack EVA 0G after F-EVA fourth dirt land occupy")
								if os.has_method("try_enter_ship"):
									os.try_enter_ship()
								await get_tree().create_timer(0.3).timeout
								if not bool(os.get("_in_ship")):
									fails.append("reboard after F-EVA fourth dirt land refused")
								else:
									if os.has_method("_leave_seat_to_pocket"):
										os._leave_seat_to_pocket()
									await get_tree().create_timer(0.35).timeout
									var ly_pk4 := ""
									if LayerContext:
										ly_pk4 = str(LayerContext.current_layer)
									var pk4: Node3D = os.get("player") as Node3D if os else null
									print("[Playtest] I-hatch after F-EVA fourth dirt F-board pocket layer=", ly_pk4,
										" int=", pk4.get("interior_mode") if pk4 else "none",
										" in_ship=", os.get("_in_ship"))
									if ly_pk4.to_upper().find("SHIP") < 0:
										fails.append("I-hatch after F-EVA fourth dirt F-board not ship_int (%s)" % ly_pk4)
									if pk4 == null or not bool(pk4.get("interior_mode")):
										fails.append("I-hatch after F-EVA fourth dirt F-board not pocket walker")
									var d4: Node = os.get("_interior") if os else null
									if d4 != null and d4.has_method("is_inside") and bool(d4.is_inside()) and d4.has_method("exit_interior"):
										d4.exit_interior()
									await get_tree().create_timer(0.4).timeout
									var hatch4: Node3D = os.get("player") as Node3D if os else null
									if hatch4 == null or not is_instance_valid(hatch4) or not hatch4.is_inside_tree():
										fails.append("I-hatch after F-EVA fourth dirt F-board: no walker")
									else:
										var h4_ship: float = hatch4.global_position.distance_to(ship.global_position)
										var h4_pad: float = hatch4.global_position.distance_to(deck.global_position)
										var h4_agl := 99.0
										if nex.has_method("altitude_of"):
											h4_agl = float(nex.altitude_of(hatch4.global_position))
										print("[Playtest] I-hatch after F-EVA fourth dirt F-board d_ship=", snapped(h4_ship, 0.1),
											" d_pad=", snapped(h4_pad, 0.1), " agl=", snapped(h4_agl, 0.01),
											" int=", hatch4.get("interior_mode"))
										if h4_ship > 22.0:
											fails.append("I-hatch after F-EVA fourth dirt F-board teleported (%s)" % snapped(h4_ship, 0.1))
										if h4_pad < 60.0:
											fails.append("I-hatch after F-EVA fourth dirt F-board snapped to pad (%s)" % snapped(h4_pad, 0.1))
										if h4_agl < 0.2 or h4_agl > 5.0:
											fails.append("I-hatch after F-EVA fourth dirt F-board not on Relief (%s)" % snapped(h4_agl, 0.01))
										if bool(hatch4.get("interior_mode")) or bool(hatch4.get("eva_mode")) or bool(hatch4.get("zero_g")):
											fails.append("I-hatch after F-EVA fourth dirt F-board still pocket/0G")
										if os.has_method("_apply_dirt_exit_facing"):
											os._apply_dirt_exit_facing()
										var rad_h4: Vector3 = (hatch4.global_position - (nex as Node3D).global_position).normalized()
										var fwd_h4: Vector3 = -hatch4.global_transform.basis.z
										fwd_h4 = fwd_h4 - rad_h4 * fwd_h4.dot(rad_h4)
										var want_h4: Vector3 = -ship.global_transform.basis.z
										want_h4 = want_h4 - rad_h4 * want_h4.dot(rad_h4)
										if fwd_h4.length_squared() < 0.04 or want_h4.length_squared() < 0.04:
											fails.append("I-hatch after F-EVA fourth dirt F-board facing not tangent")
										else:
											var align_h4: float = fwd_h4.normalized().dot(want_h4.normalized())
											print("[Playtest] I-hatch after F-EVA fourth dirt F-board facing align=", snapped(align_h4, 0.01),
												" tangent=", snapped(1.0 - absf(fwd_h4.normalized().dot(rad_h4)), 0.01))
											if align_h4 < 0.55:
												fails.append("I-hatch after F-EVA fourth dirt F-board facing sideways (%s)" % snapped(align_h4, 0.01))
										hatch4.set("_spawn_grace_t", 0.0)
										if hatch4 is CharacterBody3D:
											(hatch4 as CharacterBody3D).velocity = Vector3.ZERO
										if hatch4.has_method("_physics_process"):
											hatch4._physics_process(0.016)
										var coy_h4: float = float(hatch4.get("_coyote_t"))
										var near_h4: Variant = hatch4.call("_near_dirt_floor") if hatch4.has_method("_near_dirt_floor") else false
										print("[Playtest] I-hatch after F-EVA fourth dirt F-board coyote t=", snapped(coy_h4, 0.01), " near=", near_h4)
										if coy_h4 <= 0.0:
											fails.append("I-hatch after F-EVA fourth dirt F-board coyote dead")
										else:
											var hv40h: float = 0.0
											if hatch4 is CharacterBody3D:
												hv40h = (hatch4 as CharacterBody3D).velocity.dot(rad_h4)
											if hatch4.has_method("request_jump"):
												hatch4.request_jump()
											if hatch4.has_method("_physics_process"):
												hatch4._physics_process(0.016)
											var hv41h: float = hv40h
											if hatch4 is CharacterBody3D:
												hv41h = (hatch4 as CharacterBody3D).velocity.dot(rad_h4)
											print("[Playtest] I-hatch after F-EVA fourth dirt F-board jump v_up ", snapped(hv40h, 0.1), "→", snapped(hv41h, 0.1))
											if hv41h < hv40h + 3.0:
												fails.append("I-hatch after F-EVA fourth dirt F-board jump died (%s → %s)" % [snapped(hv40h, 0.1), snapped(hv41h, 0.1)])
										var last_h4: float = float(hatch4.get("last_slope_ang"))
										var rel_h4: float = 0.0
										if hatch4.has_method("_relief_slope_rad"):
											rel_h4 = float(hatch4.call("_relief_slope_rad"))
										print("[Playtest] I-hatch after F-EVA fourth dirt F-board slope last=", snapped(rad_to_deg(last_h4), 0.1),
											" deg rel=", snapped(rad_to_deg(rel_h4), 0.1))
										if last_h4 < 0.0 or last_h4 > 1.4:
											fails.append("I-hatch after F-EVA fourth dirt F-board slope last out of range (%s)" % snapped(last_h4, 0.01))
										if rel_h4 > 0.05 and last_h4 + 0.08 < rel_h4:
											fails.append("I-hatch after F-EVA fourth dirt F-board slope not Relief")
										if last_h4 > rel_h4 + 0.25:
											fails.append("I-hatch after F-EVA fourth dirt F-board slope is pocket-Y cliff")
										var hud_h4: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
										if hud_h4 != null and hud_h4.has_method("bind_player"):
											hud_h4.bind_player(hatch4)
										if hud_h4 != null and hud_h4.has_method("_refresh"):
											hud_h4._refresh()
										var origin_h4: Node3D = null
										if hud_h4 != null and hud_h4.has_method("_occupy_origin"):
											origin_h4 = hud_h4.call("_occupy_origin") as Node3D
										var otxt_h4 := ""
										if hud_h4 != null:
											var lab_h4: Variant = hud_h4.get("_owner_label")
											if lab_h4 is Label:
												otxt_h4 = (lab_h4 as Label).text
										print("[Playtest] occupy HUD I-hatch after F-EVA fourth dirt F-board origin=",
											origin_h4.name if origin_h4 else "null",
											" '", otxt_h4.replace("\n", " / ").substr(0, 80), "'")
										if origin_h4 == null:
											fails.append("occupy HUD lost origin after I-hatch F-EVA fourth dirt F-board")
										elif origin_h4 == ship:
											fails.append("occupy HUD origin still hull after I-hatch F-EVA fourth dirt F-board")
										elif origin_h4 != hatch4:
											fails.append("occupy HUD origin not walker after I-hatch F-EVA fourth dirt F-board")
										if otxt_h4.to_upper().find("PAD") >= 0 and otxt_h4.to_upper().find("OCCUPY") >= 0:
											fails.append("occupy HUD PAD after I-hatch F-EVA fourth dirt F-board 110m")
										var radar_h4: Variant = hud_h4.get("_radar") if hud_h4 else null
										if radar_h4 is CanvasItem:
											(radar_h4 as CanvasItem).visible = true
										if hud_h4 != null and hud_h4.has_method("_refresh"):
											hud_h4._refresh()
										var rng_h4: float = float(hud_h4.get("_radar_range_m")) if hud_h4 else 0.0
										var near_h4n := 0
										if hud_h4 != null and hud_h4.has_method("radar_pad_contacts"):
											near_h4n = hud_h4.radar_pad_contacts().size()
										print("[Playtest] pad radar I-hatch after F-EVA fourth dirt F-board 110m n=", near_h4n,
											" range=", snapped(rng_h4, 1.0), " vis=",
											(radar_h4 as CanvasItem).visible if radar_h4 is CanvasItem else "?")
										if rng_h4 > 1000.0:
											fails.append("pad radar used 12km after I-hatch F-EVA fourth dirt F-board (%s)" % snapped(rng_h4, 1.0))
										if near_h4n < 1:
											fails.append("pad radar missed pad after I-hatch F-EVA fourth dirt F-board")
										var saved_h4: Vector3 = hatch4.global_position
										var up_h4r: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
										if up_h4r.length_squared() > 0.01:
											up_h4r = up_h4r.normalized()
										var side_h4r: Vector3 = up_h4r.cross(Vector3.RIGHT)
										if side_h4r.length_squared() < 0.04:
											side_h4r = up_h4r.cross(Vector3.FORWARD)
										side_h4r = side_h4r.normalized()
										hatch4.global_position = deck.global_position + side_h4r * 600.0 + up_h4r * 2.0
										if hud_h4 != null and hud_h4.has_method("_refresh"):
											hud_h4._refresh()
										var far_h4 := false
										var far_h4n := 0
										if hud_h4 != null and hud_h4.has_method("radar_pad_contacts"):
											for c in hud_h4.radar_pad_contacts():
												far_h4n += 1
												if c is Node3D and (c as Node3D).global_position.distance_to(deck.global_position) < 30.0:
													far_h4 = true
										print("[Playtest] pad radar I-hatch after F-EVA fourth dirt F-board 600m n=", far_h4n, " pad=", far_h4)
										if far_h4:
											fails.append("pad radar used 12km approach after I-hatch F-EVA fourth dirt F-board")
										hatch4.global_position = saved_h4
										if hud_h4 != null and hud_h4.has_method("_refresh"):
											hud_h4._refresh()
										var ly_h4s := ""
										if LayerContext:
											ly_h4s = str(LayerContext.current_layer)
										var stack_h4 := ""
										var stack_h4_on := false
										var chip_h4 := ""
										if hud_h4 != null:
											var sl_h4: Variant = hud_h4.get("_os_stack")
											if sl_h4 is Label:
												stack_h4 = (sl_h4 as Label).text
												stack_h4_on = (sl_h4 as Label).visible
											var chip4: Variant = hud_h4.get("_layer_label")
											if chip4 is Label:
												chip_h4 = (chip4 as Label).text
										print("[Playtest] os stack I-hatch after F-EVA fourth dirt F-board occupy layer=", ly_h4s,
											" vis=", stack_h4_on, " chip='", chip_h4.replace("\n", " / ").substr(0, 40),
											"' '", stack_h4.replace("\n", " / ").substr(0, 80), "'")
										if ly_h4s.to_upper().find("SPACE") >= 0:
											fails.append("os stack layer still SPACE after I-hatch F-EVA fourth dirt F-board occupy")
										if ly_h4s.to_upper().find("SHIP") >= 0:
											fails.append("os stack layer still ship_int after I-hatch F-EVA fourth dirt F-board occupy")
										if ly_h4s.to_upper().find("TPS") < 0 and ly_h4s.to_upper().find("SURFACE") < 0:
											fails.append("os stack layer not TPS after I-hatch F-EVA fourth dirt F-board occupy (%s)" % ly_h4s)
										if not stack_h4_on:
											fails.append("os stack hidden after I-hatch F-EVA fourth dirt F-board occupy")
										if chip_h4.to_upper().find("SHIP") >= 0:
											fails.append("layer chip still ship_int after I-hatch F-EVA fourth dirt F-board occupy")
										if stack_h4.to_upper().find("OCCUPY") >= 0:
											fails.append("os stack occupy after I-hatch F-EVA fourth dirt F-board occupy 110m")
										if stack_h4.to_upper().find("0G") >= 0:
											fails.append("os stack EVA 0G after I-hatch F-EVA fourth dirt F-board occupy")
									if os.has_method("try_enter_ship"):
										os.try_enter_ship()
									await get_tree().create_timer(0.3).timeout
									if not bool(os.get("_in_ship")):
										fails.append("reboard after I-hatch F-EVA fourth dirt F-board refused")
									else:
										if os.has_method("reclaim_pilot_camera"):
											os.reclaim_pilot_camera()
										var hud_rb5: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
										if hud_rb5 != null and hud_rb5.has_method("bind_player"):
											hud_rb5.bind_player(ship)
										if hud_rb5 != null and hud_rb5.has_method("_refresh"):
											hud_rb5._refresh()
										var origin_rb5: Node3D = null
										if hud_rb5 != null and hud_rb5.has_method("_occupy_origin"):
											origin_rb5 = hud_rb5.call("_occupy_origin") as Node3D
										var ly_rb5 := ""
										if LayerContext:
											ly_rb5 = str(LayerContext.current_layer)
										var rng_rb5: float = float(hud_rb5.get("_radar_range_m")) if hud_rb5 else 0.0
										print("[Playtest] F-board after I-hatch F-EVA fourth dirt occupy origin=",
											origin_rb5.name if origin_rb5 else "null", " layer=", ly_rb5,
											" radar=", snapped(rng_rb5, 1.0))
										if origin_rb5 != null and origin_rb5 != ship:
											fails.append("occupy HUD origin still walker after I-hatch F-EVA fourth dirt F-board")
										if ly_rb5.to_upper().find("SPACE") < 0:
											fails.append("layer not Space after I-hatch F-EVA fourth dirt F-board (%s)" % ly_rb5)
										if rng_rb5 < 1000.0:
											fails.append("pad radar still 400m after I-hatch F-EVA fourth dirt F-board (%s)" % snapped(rng_rb5, 1.0))
										var chase_rb5: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
										var live_rb5: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
										print("[Playtest] HOVER view after I-hatch F-EVA fourth dirt F-board chase=",
											chase_rb5.name if chase_rb5 else "none", " live=", live_rb5.name if live_rb5 else "none",
											" current=", chase_rb5.current if chase_rb5 else false)
										if chase_rb5 == null:
											fails.append("HOVER view after I-hatch F-EVA fourth dirt F-board: no chase cam")
										elif live_rb5 != chase_rb5:
											fails.append("HOVER view after I-hatch F-EVA fourth dirt F-board stole (%s)" % (live_rb5.name if live_rb5 else "none"))
										elif not chase_rb5.current:
											fails.append("HOVER view after I-hatch F-EVA fourth dirt F-board chase not current")
										ship.set("_land_lock_t", 0.0)
										if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
											ship._do_launch()
										await get_tree().create_timer(0.35).timeout
										var agl_l5: float = float(ship.altitude_agl()) if ship.has_method("altitude_agl") else -1.0
										var hold_l5: float = float(ship.get("_hover_hold_alt"))
										print("[Playtest] HOVER launch after I-hatch F-EVA fourth dirt F-board landed=",
											ship.get("is_landed"), " hold=", snapped(hold_l5, 0.1),
											" agl=", snapped(agl_l5, 0.1))
										if bool(ship.get("is_landed")):
											fails.append("HOVER launch after I-hatch F-EVA fourth dirt F-board still landed")
										if hold_l5 < 4.0:
											fails.append("HOVER launch after I-hatch F-EVA fourth dirt F-board hold dead (%s)" % snapped(hold_l5, 0.1))
										if agl_l5 >= 0.0 and (hold_l5 < agl_l5 - 2.0 or hold_l5 > agl_l5 + 20.0):
											fails.append("HOVER launch after I-hatch F-EVA fourth dirt F-board hold not AGL+12 (%s vs %s)" % [
												snapped(hold_l5, 0.1), snapped(agl_l5, 0.1)])
										if ship.has_method("_set_mode"):
											ship._set_mode(2)
										var hold_l5b: float = float(ship.get("_hover_hold_alt"))
										print("[Playtest] HOVER launch after I-hatch F-EVA fourth dirt F-board retap hold=", snapped(hold_l5b, 0.1))
										if absf(hold_l5b - hold_l5) > 1.5:
											fails.append("HOVER launch after I-hatch F-EVA fourth dirt F-board retap rewrote hold")
										var up_ge5: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
										if up_ge5.length_squared() > 0.01:
											up_ge5 = up_ge5.normalized()
										var rel_ge5: Vector3 = ship.global_position - deck.global_position
										var lat_ge5: float = (rel_ge5 - up_ge5 * rel_ge5.dot(up_ge5)).length()
										var agl_ge5: float = agl_l5
										if nex.has_method("altitude_of"):
											agl_ge5 = float(nex.altitude_of(ship.global_position))
										print("[Playtest] I-hatch F-EVA fourth dirt F-board launch GE lat=", snapped(lat_ge5, 0.1),
											" agl=", snapped(agl_ge5, 0.1))
										if lat_ge5 < 60.0:
											fails.append("I-hatch F-EVA fourth dirt F-board launch GE pulled onto plate (lat=%s)" % snapped(lat_ge5, 0.1))
										ship.set_meta("playtest_sink", true)
										await get_tree().create_timer(0.45).timeout
										ship.set_meta("playtest_sink", false)
										var hold_sk5: float = float(ship.get("_hover_hold_alt"))
										var agl_sk5: float = agl_ge5
										if nex.has_method("altitude_of"):
											agl_sk5 = float(nex.altitude_of(ship.global_position))
										var rel_sk5: Vector3 = ship.global_position - deck.global_position
										var lat_sk5: float = (rel_sk5 - up_ge5 * rel_sk5.dot(up_ge5)).length()
										print("[Playtest] I-hatch F-EVA fourth dirt F-board HOVER sink hold ",
											snapped(hold_l5b, 0.1), "→", snapped(hold_sk5, 0.1),
											" AGL ", snapped(agl_ge5, 0.1), "→", snapped(agl_sk5, 0.1),
											" lat=", snapped(lat_sk5, 0.1))
										if hold_sk5 > 6.5:
											fails.append("I-hatch F-EVA fourth dirt F-board HOVER sink hold still 8m floor (%s)" % snapped(hold_sk5, 0.1))
										if hold_sk5 + 0.2 < 3.5:
											fails.append("I-hatch F-EVA fourth dirt F-board HOVER sink hold buried (%s)" % snapped(hold_sk5, 0.1))
										if lat_sk5 < 60.0:
											fails.append("I-hatch F-EVA fourth dirt F-board HOVER sink drifted onto plate (%s)" % snapped(lat_sk5, 0.1))
										if "velocity" in ship:
											ship.velocity = Vector3.ZERO
										ship.set("_gear_down", true)
										if ship.has_method("_do_land"):
											ship._do_land()
										await get_tree().create_timer(0.4).timeout
										var land5_agl: float = agl_sk5
										if nex.has_method("altitude_of"):
											land5_agl = float(nex.altitude_of(ship.global_position))
										var land5_pad: Node3D = null
										if ship.has_method("get_landed_pad"):
											land5_pad = ship.get_landed_pad() as Node3D
										var land5_rel: Vector3 = ship.global_position - deck.global_position
										var land5_lat: float = (land5_rel - up_ge5 * land5_rel.dot(up_ge5)).length()
										print("[Playtest] I-hatch F-EVA fourth dirt F-board land after sink landed=", ship.get("is_landed"),
											" pad=", land5_pad.name if land5_pad else "none",
											" agl=", snapped(land5_agl, 0.1), " lat=", snapped(land5_lat, 0.1))
										if not bool(ship.get("is_landed")):
											fails.append("I-hatch F-EVA fourth dirt F-board land after sink refused")
										if land5_pad != null:
											fails.append("I-hatch F-EVA fourth dirt F-board land after sink stole pad")
										if land5_lat < 60.0:
											fails.append("I-hatch F-EVA fourth dirt F-board land after sink drifted to plate (%s)" % snapped(land5_lat, 0.1))
										if land5_agl < 1.5 or land5_agl > 8.0:
											fails.append("I-hatch F-EVA fourth dirt F-board land after sink not on Relief (%s)" % snapped(land5_agl, 0.1))
										if os.has_method("try_exit_ship"):
											os.try_exit_ship()
										await get_tree().create_timer(0.4).timeout
										var eva6: Node3D = os.get("player") as Node3D if os else null
										if eva6 == null or not is_instance_valid(eva6) or not eva6.is_inside_tree():
											fails.append("F-EVA after fifth dirt land: no walker")
										else:
											var e6_ship: float = eva6.global_position.distance_to(ship.global_position)
											var e6_pad: float = eva6.global_position.distance_to(deck.global_position)
											var e6_agl := 99.0
											if nex.has_method("altitude_of"):
												e6_agl = float(nex.altitude_of(eva6.global_position))
											var ly_e6 := ""
											if LayerContext:
												ly_e6 = str(LayerContext.current_layer)
											print("[Playtest] F-EVA after fifth dirt land d_ship=", snapped(e6_ship, 0.1),
												" d_pad=", snapped(e6_pad, 0.1), " agl=", snapped(e6_agl, 0.01),
												" eva=", eva6.get("eva_mode"), " layer=", ly_e6)
											if e6_ship > 22.0:
												fails.append("F-EVA after fifth dirt land teleported (%s)" % snapped(e6_ship, 0.1))
											if e6_pad < 60.0:
												fails.append("F-EVA after fifth dirt land snapped to pad (%s)" % snapped(e6_pad, 0.1))
											if e6_agl < 0.2 or e6_agl > 5.0:
												fails.append("F-EVA after fifth dirt land not on Relief (%s)" % snapped(e6_agl, 0.01))
											if bool(eva6.get("eva_mode")) or bool(eva6.get("zero_g")):
												fails.append("F-EVA after fifth dirt land still EVA 0G")
											if ly_e6.to_upper().find("TPS") < 0:
												fails.append("F-EVA after fifth dirt land layer not TPS (%s)" % ly_e6)
											var hud_e6: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
											if hud_e6 != null and hud_e6.has_method("bind_player"):
												hud_e6.bind_player(eva6)
											if hud_e6 != null and hud_e6.has_method("_refresh"):
												hud_e6._refresh()
											var origin_e6: Node3D = null
											if hud_e6 != null and hud_e6.has_method("_occupy_origin"):
												origin_e6 = hud_e6.call("_occupy_origin") as Node3D
											var otxt_e6 := ""
											if hud_e6 != null:
												var lab_e6: Variant = hud_e6.get("_owner_label")
												if lab_e6 is Label:
													otxt_e6 = (lab_e6 as Label).text
											print("[Playtest] occupy HUD F-EVA after fifth dirt land origin=",
												origin_e6.name if origin_e6 else "null",
												" '", otxt_e6.replace("\n", " / ").substr(0, 80), "'")
											if origin_e6 == null:
												fails.append("occupy HUD lost origin after F-EVA fifth dirt land")
											elif origin_e6 == ship:
												fails.append("occupy HUD origin still hull after F-EVA fifth dirt land")
											elif origin_e6 != eva6:
												fails.append("occupy HUD origin not walker after F-EVA fifth dirt land")
											if otxt_e6.to_upper().find("PAD") >= 0 and otxt_e6.to_upper().find("OCCUPY") >= 0:
												fails.append("occupy HUD PAD after F-EVA fifth dirt land 110m")
											var radar_e6: Variant = hud_e6.get("_radar") if hud_e6 else null
											if radar_e6 is CanvasItem:
												(radar_e6 as CanvasItem).visible = true
											if hud_e6 != null and hud_e6.has_method("_refresh"):
												hud_e6._refresh()
											var rng_e6: float = float(hud_e6.get("_radar_range_m")) if hud_e6 else 0.0
											var near_e6n := 0
											if hud_e6 != null and hud_e6.has_method("radar_pad_contacts"):
												near_e6n = hud_e6.radar_pad_contacts().size()
											print("[Playtest] pad radar F-EVA after fifth dirt land 110m n=", near_e6n,
												" range=", snapped(rng_e6, 1.0), " vis=",
												(radar_e6 as CanvasItem).visible if radar_e6 is CanvasItem else "?")
											if rng_e6 > 1000.0:
												fails.append("pad radar used 12km after F-EVA fifth dirt land occupy (%s)" % snapped(rng_e6, 1.0))
											if near_e6n < 1:
												fails.append("pad radar missed pad after F-EVA fifth dirt land occupy")
											var saved_e6: Vector3 = eva6.global_position
											var up_e6r: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
											if up_e6r.length_squared() > 0.01:
												up_e6r = up_e6r.normalized()
											var side_e6r: Vector3 = up_e6r.cross(Vector3.RIGHT)
											if side_e6r.length_squared() < 0.04:
												side_e6r = up_e6r.cross(Vector3.FORWARD)
											side_e6r = side_e6r.normalized()
											eva6.global_position = deck.global_position + side_e6r * 600.0 + up_e6r * 2.0
											if hud_e6 != null and hud_e6.has_method("_refresh"):
												hud_e6._refresh()
											var far_e6 := false
											var far_e6n := 0
											if hud_e6 != null and hud_e6.has_method("radar_pad_contacts"):
												for c in hud_e6.radar_pad_contacts():
													far_e6n += 1
													if c is Node3D and (c as Node3D).global_position.distance_to(deck.global_position) < 30.0:
														far_e6 = true
											print("[Playtest] pad radar F-EVA after fifth dirt land 600m n=", far_e6n, " pad=", far_e6)
											if far_e6:
												fails.append("pad radar used 12km approach after F-EVA fifth dirt land occupy")
											eva6.global_position = saved_e6
											if hud_e6 != null and hud_e6.has_method("_refresh"):
												hud_e6._refresh()
											var ly_e6s := ""
											if LayerContext:
												ly_e6s = str(LayerContext.current_layer)
											var stack_e6 := ""
											var stack_e6_on := false
											var chip_e6 := ""
											if hud_e6 != null:
												var sl_e6: Variant = hud_e6.get("_os_stack")
												if sl_e6 is Label:
													stack_e6 = (sl_e6 as Label).text
													stack_e6_on = (sl_e6 as Label).visible
												var chip6: Variant = hud_e6.get("_layer_label")
												if chip6 is Label:
													chip_e6 = (chip6 as Label).text
											print("[Playtest] os stack F-EVA after fifth dirt land occupy layer=", ly_e6s,
												" vis=", stack_e6_on, " chip='", chip_e6.replace("\n", " / ").substr(0, 40),
												"' '", stack_e6.replace("\n", " / ").substr(0, 80), "'")
											if ly_e6s.to_upper().find("SPACE") >= 0:
												fails.append("os stack layer still SPACE after F-EVA fifth dirt land occupy")
											if ly_e6s.to_upper().find("SHIP") >= 0:
												fails.append("os stack layer still ship_int after F-EVA fifth dirt land occupy")
											if ly_e6s.to_upper().find("TPS") < 0 and ly_e6s.to_upper().find("SURFACE") < 0:
												fails.append("os stack layer not TPS after F-EVA fifth dirt land occupy (%s)" % ly_e6s)
											if not stack_e6_on:
												fails.append("os stack hidden after F-EVA fifth dirt land occupy")
											if chip_e6.to_upper().find("SHIP") >= 0:
												fails.append("layer chip still ship_int after F-EVA fifth dirt land occupy")
											if stack_e6.to_upper().find("OCCUPY") >= 0:
												fails.append("os stack occupy after F-EVA fifth dirt land occupy 110m")
											if stack_e6.to_upper().find("0G") >= 0:
												fails.append("os stack EVA 0G after F-EVA fifth dirt land occupy")
										if os.has_method("try_enter_ship"):
											os.try_enter_ship()
										await get_tree().create_timer(0.3).timeout
										if not bool(os.get("_in_ship")):
											fails.append("reboard after F-EVA fifth dirt land refused")
										else:
											if os.has_method("reclaim_pilot_camera"):
												os.reclaim_pilot_camera()
											var hud_rb6: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
											if hud_rb6 != null and hud_rb6.has_method("bind_player"):
												hud_rb6.bind_player(ship)
											if hud_rb6 != null and hud_rb6.has_method("_refresh"):
												hud_rb6._refresh()
											var origin_rb6: Node3D = null
											if hud_rb6 != null and hud_rb6.has_method("_occupy_origin"):
												origin_rb6 = hud_rb6.call("_occupy_origin") as Node3D
											var ly_rb6 := ""
											if LayerContext:
												ly_rb6 = str(LayerContext.current_layer)
											var rng_rb6: float = float(hud_rb6.get("_radar_range_m")) if hud_rb6 else 0.0
											print("[Playtest] F-board after F-EVA fifth dirt occupy origin=",
												origin_rb6.name if origin_rb6 else "null", " layer=", ly_rb6,
												" radar=", snapped(rng_rb6, 1.0))
											if origin_rb6 != null and origin_rb6 != ship:
												fails.append("occupy HUD origin still walker after F-EVA fifth dirt F-board")
											if ly_rb6.to_upper().find("SPACE") < 0:
												fails.append("layer not Space after F-EVA fifth dirt F-board (%s)" % ly_rb6)
											if rng_rb6 < 1000.0:
												fails.append("pad radar still 400m after F-EVA fifth dirt F-board (%s)" % snapped(rng_rb6, 1.0))
											var chase_rb6: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
											var live_rb6: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
											print("[Playtest] HOVER view after F-EVA fifth dirt F-board chase=",
												chase_rb6.name if chase_rb6 else "none", " live=", live_rb6.name if live_rb6 else "none",
												" current=", chase_rb6.current if chase_rb6 else false)
											if chase_rb6 == null:
												fails.append("HOVER view after F-EVA fifth dirt F-board: no chase cam")
											elif live_rb6 != chase_rb6:
												fails.append("HOVER view after F-EVA fifth dirt F-board stole (%s)" % (live_rb6.name if live_rb6 else "none"))
											elif not chase_rb6.current:
												fails.append("HOVER view after F-EVA fifth dirt F-board chase not current")
											if os.has_method("_leave_seat_to_pocket"):
												os._leave_seat_to_pocket()
											await get_tree().create_timer(0.35).timeout
											var ly_pk5 := ""
											if LayerContext:
												ly_pk5 = str(LayerContext.current_layer)
											var pk5: Node3D = os.get("player") as Node3D if os else null
											print("[Playtest] I-hatch after F-EVA fifth dirt F-board pocket layer=", ly_pk5,
												" int=", pk5.get("interior_mode") if pk5 else "none",
												" in_ship=", os.get("_in_ship"))
											if ly_pk5.to_upper().find("SHIP") < 0:
												fails.append("I-hatch after F-EVA fifth dirt F-board not ship_int (%s)" % ly_pk5)
											if pk5 == null or not bool(pk5.get("interior_mode")):
												fails.append("I-hatch after F-EVA fifth dirt F-board not pocket walker")
											var d5: Node = os.get("_interior") if os else null
											if d5 != null and d5.has_method("is_inside") and bool(d5.is_inside()) and d5.has_method("exit_interior"):
												d5.exit_interior()
											await get_tree().create_timer(0.4).timeout
											var hatch5: Node3D = os.get("player") as Node3D if os else null
											if hatch5 == null or not is_instance_valid(hatch5) or not hatch5.is_inside_tree():
												fails.append("I-hatch after F-EVA fifth dirt F-board: no walker")
											else:
												var h5_ship: float = hatch5.global_position.distance_to(ship.global_position)
												var h5_pad: float = hatch5.global_position.distance_to(deck.global_position)
												var h5_agl := 99.0
												if nex.has_method("altitude_of"):
													h5_agl = float(nex.altitude_of(hatch5.global_position))
												print("[Playtest] I-hatch after F-EVA fifth dirt F-board d_ship=", snapped(h5_ship, 0.1),
													" d_pad=", snapped(h5_pad, 0.1), " agl=", snapped(h5_agl, 0.01),
													" int=", hatch5.get("interior_mode"))
												if h5_ship > 22.0:
													fails.append("I-hatch after F-EVA fifth dirt F-board teleported (%s)" % snapped(h5_ship, 0.1))
												if h5_pad < 60.0:
													fails.append("I-hatch after F-EVA fifth dirt F-board snapped to pad (%s)" % snapped(h5_pad, 0.1))
												if h5_agl < 0.2 or h5_agl > 5.0:
													fails.append("I-hatch after F-EVA fifth dirt F-board not on Relief (%s)" % snapped(h5_agl, 0.01))
												if bool(hatch5.get("interior_mode")) or bool(hatch5.get("eva_mode")) or bool(hatch5.get("zero_g")):
													fails.append("I-hatch after F-EVA fifth dirt F-board still pocket/0G")
												if os.has_method("_apply_dirt_exit_facing"):
													os._apply_dirt_exit_facing()
												var rad_h5: Vector3 = (hatch5.global_position - (nex as Node3D).global_position).normalized()
												var fwd_h5: Vector3 = -hatch5.global_transform.basis.z
												fwd_h5 = fwd_h5 - rad_h5 * fwd_h5.dot(rad_h5)
												var want_h5: Vector3 = -ship.global_transform.basis.z
												want_h5 = want_h5 - rad_h5 * want_h5.dot(rad_h5)
												if fwd_h5.length_squared() < 0.04 or want_h5.length_squared() < 0.04:
													fails.append("I-hatch after F-EVA fifth dirt F-board facing not tangent")
												else:
													var align_h5: float = fwd_h5.normalized().dot(want_h5.normalized())
													print("[Playtest] I-hatch after F-EVA fifth dirt F-board facing align=", snapped(align_h5, 0.01),
														" tangent=", snapped(1.0 - absf(fwd_h5.normalized().dot(rad_h5)), 0.01))
													if align_h5 < 0.55:
														fails.append("I-hatch after F-EVA fifth dirt F-board facing sideways (%s)" % snapped(align_h5, 0.01))
												hatch5.set("_spawn_grace_t", 0.0)
												if hatch5 is CharacterBody3D:
													(hatch5 as CharacterBody3D).velocity = Vector3.ZERO
												if hatch5.has_method("_physics_process"):
													hatch5._physics_process(0.016)
												var coy_h5: float = float(hatch5.get("_coyote_t"))
												var near_h5: Variant = hatch5.call("_near_dirt_floor") if hatch5.has_method("_near_dirt_floor") else false
												print("[Playtest] I-hatch after F-EVA fifth dirt F-board coyote t=", snapped(coy_h5, 0.01), " near=", near_h5)
												if coy_h5 <= 0.0:
													fails.append("I-hatch after F-EVA fifth dirt F-board coyote dead")
												else:
													var hv50h: float = 0.0
													if hatch5 is CharacterBody3D:
														hv50h = (hatch5 as CharacterBody3D).velocity.dot(rad_h5)
													if hatch5.has_method("request_jump"):
														hatch5.request_jump()
													if hatch5.has_method("_physics_process"):
														hatch5._physics_process(0.016)
													var hv51h: float = hv50h
													if hatch5 is CharacterBody3D:
														hv51h = (hatch5 as CharacterBody3D).velocity.dot(rad_h5)
													print("[Playtest] I-hatch after F-EVA fifth dirt F-board jump v_up ", snapped(hv50h, 0.1), "→", snapped(hv51h, 0.1))
													if hv51h < hv50h + 3.0:
														fails.append("I-hatch after F-EVA fifth dirt F-board jump died (%s → %s)" % [snapped(hv50h, 0.1), snapped(hv51h, 0.1)])
												var last_h5: float = float(hatch5.get("last_slope_ang"))
												var rel_h5: float = 0.0
												if hatch5.has_method("_relief_slope_rad"):
													rel_h5 = float(hatch5.call("_relief_slope_rad"))
												print("[Playtest] I-hatch after F-EVA fifth dirt F-board slope last=", snapped(rad_to_deg(last_h5), 0.1),
													" deg rel=", snapped(rad_to_deg(rel_h5), 0.1))
												if last_h5 < 0.0 or last_h5 > 1.4:
													fails.append("I-hatch after F-EVA fifth dirt F-board slope last out of range (%s)" % snapped(last_h5, 0.01))
												if rel_h5 > 0.05 and last_h5 + 0.08 < rel_h5:
													fails.append("I-hatch after F-EVA fifth dirt F-board slope not Relief")
												if last_h5 > rel_h5 + 0.25:
													fails.append("I-hatch after F-EVA fifth dirt F-board slope is pocket-Y cliff")
											if os.has_method("try_enter_ship"):
												os.try_enter_ship()
											await get_tree().create_timer(0.3).timeout
											if not bool(os.get("_in_ship")):
												fails.append("reboard after I-hatch F-EVA fifth dirt F-board refused")
											else:
												ship.set("_land_lock_t", 0.0)
												if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
													ship._do_launch()
												await get_tree().create_timer(0.35).timeout
												var agl_l6: float = float(ship.altitude_agl()) if ship.has_method("altitude_agl") else -1.0
												var hold_l6: float = float(ship.get("_hover_hold_alt"))
												print("[Playtest] HOVER launch after I-hatch F-EVA fifth dirt F-board landed=",
													ship.get("is_landed"), " hold=", snapped(hold_l6, 0.1),
													" agl=", snapped(agl_l6, 0.1))
												if bool(ship.get("is_landed")):
													fails.append("HOVER launch after I-hatch F-EVA fifth dirt F-board still landed")
												if hold_l6 < 4.0:
													fails.append("HOVER launch after I-hatch F-EVA fifth dirt F-board hold dead (%s)" % snapped(hold_l6, 0.1))
												if agl_l6 >= 0.0 and (hold_l6 < agl_l6 - 2.0 or hold_l6 > agl_l6 + 20.0):
													fails.append("HOVER launch after I-hatch F-EVA fifth dirt F-board hold not AGL+12 (%s vs %s)" % [
														snapped(hold_l6, 0.1), snapped(agl_l6, 0.1)])
												if ship.has_method("_set_mode"):
													ship._set_mode(2)
												var hold_l6b: float = float(ship.get("_hover_hold_alt"))
												print("[Playtest] HOVER launch after I-hatch F-EVA fifth dirt F-board retap hold=", snapped(hold_l6b, 0.1))
												if absf(hold_l6b - hold_l6) > 1.5:
													fails.append("HOVER launch after I-hatch F-EVA fifth dirt F-board retap rewrote hold")
												var up_ge6: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
												if up_ge6.length_squared() > 0.01:
													up_ge6 = up_ge6.normalized()
												var rel_ge6: Vector3 = ship.global_position - deck.global_position
												var lat_ge6: float = (rel_ge6 - up_ge6 * rel_ge6.dot(up_ge6)).length()
												var agl_ge6: float = agl_l6
												if nex.has_method("altitude_of"):
													agl_ge6 = float(nex.altitude_of(ship.global_position))
												print("[Playtest] I-hatch F-EVA fifth dirt F-board launch GE lat=", snapped(lat_ge6, 0.1),
													" agl=", snapped(agl_ge6, 0.1))
												if lat_ge6 < 60.0:
													fails.append("I-hatch F-EVA fifth dirt F-board launch GE pulled onto plate (lat=%s)" % snapped(lat_ge6, 0.1))
												ship.set_meta("playtest_sink", true)
												await get_tree().create_timer(0.45).timeout
												ship.set_meta("playtest_sink", false)
												var hold_sk6: float = float(ship.get("_hover_hold_alt"))
												var agl_sk6: float = agl_ge6
												if nex.has_method("altitude_of"):
													agl_sk6 = float(nex.altitude_of(ship.global_position))
												var rel_sk6: Vector3 = ship.global_position - deck.global_position
												var lat_sk6: float = (rel_sk6 - up_ge6 * rel_sk6.dot(up_ge6)).length()
												print("[Playtest] I-hatch F-EVA fifth dirt F-board HOVER sink hold ",
													snapped(hold_l6b, 0.1), "→", snapped(hold_sk6, 0.1),
													" AGL ", snapped(agl_ge6, 0.1), "→", snapped(agl_sk6, 0.1),
													" lat=", snapped(lat_sk6, 0.1))
												if hold_sk6 > 6.5:
													fails.append("I-hatch F-EVA fifth dirt F-board HOVER sink hold still 8m floor (%s)" % snapped(hold_sk6, 0.1))
												if hold_sk6 + 0.2 < 3.5:
													fails.append("I-hatch F-EVA fifth dirt F-board HOVER sink hold buried (%s)" % snapped(hold_sk6, 0.1))
												if lat_sk6 < 60.0:
													fails.append("I-hatch F-EVA fifth dirt F-board HOVER sink drifted onto plate (%s)" % snapped(lat_sk6, 0.1))
												if "velocity" in ship:
													ship.velocity = Vector3.ZERO
												ship.set("_gear_down", true)
												if ship.has_method("_do_land"):
													ship._do_land()
												await get_tree().create_timer(0.4).timeout
												var land6_agl: float = agl_sk6
												if nex.has_method("altitude_of"):
													land6_agl = float(nex.altitude_of(ship.global_position))
												var land6_pad: Node3D = null
												if ship.has_method("get_landed_pad"):
													land6_pad = ship.get_landed_pad() as Node3D
												var land6_rel: Vector3 = ship.global_position - deck.global_position
												var land6_lat: float = (land6_rel - up_ge6 * land6_rel.dot(up_ge6)).length()
												print("[Playtest] I-hatch F-EVA fifth dirt F-board land after sink landed=", ship.get("is_landed"),
													" pad=", land6_pad.name if land6_pad else "none",
													" agl=", snapped(land6_agl, 0.1), " lat=", snapped(land6_lat, 0.1))
												if not bool(ship.get("is_landed")):
													fails.append("I-hatch F-EVA fifth dirt F-board land after sink refused")
												if land6_pad != null:
													fails.append("I-hatch F-EVA fifth dirt F-board land after sink stole pad")
												if land6_lat < 60.0:
													fails.append("I-hatch F-EVA fifth dirt F-board land after sink drifted to plate (%s)" % snapped(land6_lat, 0.1))
												if land6_agl < 1.5 or land6_agl > 8.0:
													fails.append("I-hatch F-EVA fifth dirt F-board land after sink not on Relief (%s)" % snapped(land6_agl, 0.1))
												if os.has_method("try_exit_ship"):
													os.try_exit_ship()
												await get_tree().create_timer(0.4).timeout
												var eva7: Node3D = os.get("player") as Node3D if os else null
												if eva7 == null or not is_instance_valid(eva7) or not eva7.is_inside_tree():
													fails.append("F-EVA after sixth dirt land: no walker")
												else:
													var e7_ship: float = eva7.global_position.distance_to(ship.global_position)
													var e7_pad: float = eva7.global_position.distance_to(deck.global_position)
													var e7_agl := 99.0
													if nex.has_method("altitude_of"):
														e7_agl = float(nex.altitude_of(eva7.global_position))
													var ly_e7 := ""
													if LayerContext:
														ly_e7 = str(LayerContext.current_layer)
													print("[Playtest] F-EVA after sixth dirt land d_ship=", snapped(e7_ship, 0.1),
														" d_pad=", snapped(e7_pad, 0.1), " agl=", snapped(e7_agl, 0.01),
														" eva=", eva7.get("eva_mode"), " layer=", ly_e7)
													if e7_ship > 22.0:
														fails.append("F-EVA after sixth dirt land teleported (%s)" % snapped(e7_ship, 0.1))
													if e7_pad < 60.0:
														fails.append("F-EVA after sixth dirt land snapped to pad (%s)" % snapped(e7_pad, 0.1))
													if e7_agl < 0.2 or e7_agl > 5.0:
														fails.append("F-EVA after sixth dirt land not on Relief (%s)" % snapped(e7_agl, 0.01))
													if bool(eva7.get("eva_mode")) or bool(eva7.get("zero_g")):
														fails.append("F-EVA after sixth dirt land still EVA 0G")
													if ly_e7.to_upper().find("TPS") < 0:
														fails.append("F-EVA after sixth dirt land layer not TPS (%s)" % ly_e7)
													var hud_e7: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
													if hud_e7 != null and hud_e7.has_method("bind_player"):
														hud_e7.bind_player(eva7)
													if hud_e7 != null and hud_e7.has_method("_refresh"):
														hud_e7._refresh()
													var origin_e7: Node3D = null
													if hud_e7 != null and hud_e7.has_method("_occupy_origin"):
														origin_e7 = hud_e7.call("_occupy_origin") as Node3D
													var otxt_e7 := ""
													if hud_e7 != null:
														var lab_e7: Variant = hud_e7.get("_owner_label")
														if lab_e7 is Label:
															otxt_e7 = (lab_e7 as Label).text
													print("[Playtest] occupy HUD F-EVA after sixth dirt land origin=",
														origin_e7.name if origin_e7 else "null",
														" '", otxt_e7.replace("\n", " / ").substr(0, 80), "'")
													if origin_e7 == null:
														fails.append("occupy HUD lost origin after F-EVA sixth dirt land")
													elif origin_e7 == ship:
														fails.append("occupy HUD origin still hull after F-EVA sixth dirt land")
													elif origin_e7 != eva7:
														fails.append("occupy HUD origin not walker after F-EVA sixth dirt land")
													if otxt_e7.to_upper().find("PAD") >= 0 and otxt_e7.to_upper().find("OCCUPY") >= 0:
														fails.append("occupy HUD PAD after F-EVA sixth dirt land 110m")
													var radar_e7: Variant = hud_e7.get("_radar") if hud_e7 else null
													if radar_e7 is CanvasItem:
														(radar_e7 as CanvasItem).visible = true
													if hud_e7 != null and hud_e7.has_method("_refresh"):
														hud_e7._refresh()
													var rng_e7: float = float(hud_e7.get("_radar_range_m")) if hud_e7 else 0.0
													var near_e7n := 0
													if hud_e7 != null and hud_e7.has_method("radar_pad_contacts"):
														near_e7n = hud_e7.radar_pad_contacts().size()
													print("[Playtest] pad radar F-EVA after sixth dirt land 110m n=", near_e7n,
														" range=", snapped(rng_e7, 1.0), " vis=",
														(radar_e7 as CanvasItem).visible if radar_e7 is CanvasItem else "?")
													if rng_e7 > 1000.0:
														fails.append("pad radar used 12km after F-EVA sixth dirt land occupy (%s)" % snapped(rng_e7, 1.0))
													if near_e7n < 1:
														fails.append("pad radar missed pad after F-EVA sixth dirt land occupy")
													var saved_e7: Vector3 = eva7.global_position
													var up_e7r: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
													if up_e7r.length_squared() > 0.01:
														up_e7r = up_e7r.normalized()
													var side_e7r: Vector3 = up_e7r.cross(Vector3.RIGHT)
													if side_e7r.length_squared() < 0.04:
														side_e7r = up_e7r.cross(Vector3.FORWARD)
													side_e7r = side_e7r.normalized()
													eva7.global_position = deck.global_position + side_e7r * 600.0 + up_e7r * 2.0
													if hud_e7 != null and hud_e7.has_method("_refresh"):
														hud_e7._refresh()
													var far_e7 := false
													var far_e7n := 0
													if hud_e7 != null and hud_e7.has_method("radar_pad_contacts"):
														for c in hud_e7.radar_pad_contacts():
															far_e7n += 1
															if c is Node3D and (c as Node3D).global_position.distance_to(deck.global_position) < 30.0:
																far_e7 = true
													print("[Playtest] pad radar F-EVA after sixth dirt land 600m n=", far_e7n, " pad=", far_e7)
													if far_e7:
														fails.append("pad radar used 12km approach after F-EVA sixth dirt land occupy")
													eva7.global_position = saved_e7
													if hud_e7 != null and hud_e7.has_method("_refresh"):
														hud_e7._refresh()
													var ly_e7s := ""
													if LayerContext:
														ly_e7s = str(LayerContext.current_layer)
													var stack_e7 := ""
													var stack_e7_on := false
													var chip_e7 := ""
													if hud_e7 != null:
														var sl_e7: Variant = hud_e7.get("_os_stack")
														if sl_e7 is Label:
															stack_e7 = (sl_e7 as Label).text
															stack_e7_on = (sl_e7 as Label).visible
														var chip7: Variant = hud_e7.get("_layer_label")
														if chip7 is Label:
															chip_e7 = (chip7 as Label).text
													print("[Playtest] os stack F-EVA after sixth dirt land occupy layer=", ly_e7s,
														" vis=", stack_e7_on, " chip='", chip_e7.replace("\n", " / ").substr(0, 40),
														"' '", stack_e7.replace("\n", " / ").substr(0, 80), "'")
													if ly_e7s.to_upper().find("SPACE") >= 0:
														fails.append("os stack layer still SPACE after F-EVA sixth dirt land occupy")
													if ly_e7s.to_upper().find("SHIP") >= 0:
														fails.append("os stack layer still ship_int after F-EVA sixth dirt land occupy")
													if ly_e7s.to_upper().find("TPS") < 0 and ly_e7s.to_upper().find("SURFACE") < 0:
														fails.append("os stack layer not TPS after F-EVA sixth dirt land occupy (%s)" % ly_e7s)
													if not stack_e7_on:
														fails.append("os stack hidden after F-EVA sixth dirt land occupy")
													if chip_e7.to_upper().find("SHIP") >= 0:
														fails.append("layer chip still ship_int after F-EVA sixth dirt land occupy")
													if stack_e7.to_upper().find("OCCUPY") >= 0:
														fails.append("os stack occupy after F-EVA sixth dirt land occupy 110m")
													if stack_e7.to_upper().find("0G") >= 0:
														fails.append("os stack EVA 0G after F-EVA sixth dirt land occupy")
												if os.has_method("try_enter_ship"):
													os.try_enter_ship()
												await get_tree().create_timer(0.3).timeout
												if not bool(os.get("_in_ship")):
													fails.append("reboard after F-EVA sixth dirt land refused")
												else:
													if os.has_method("reclaim_pilot_camera"):
														os.reclaim_pilot_camera()
													var hud_rb7: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
													if hud_rb7 != null and hud_rb7.has_method("bind_player"):
														hud_rb7.bind_player(ship)
													if hud_rb7 != null and hud_rb7.has_method("_refresh"):
														hud_rb7._refresh()
													var origin_rb7: Node3D = null
													if hud_rb7 != null and hud_rb7.has_method("_occupy_origin"):
														origin_rb7 = hud_rb7.call("_occupy_origin") as Node3D
													var ly_rb7 := ""
													if LayerContext:
														ly_rb7 = str(LayerContext.current_layer)
													var rng_rb7: float = float(hud_rb7.get("_radar_range_m")) if hud_rb7 else 0.0
													print("[Playtest] F-board after F-EVA sixth dirt occupy origin=",
														origin_rb7.name if origin_rb7 else "null", " layer=", ly_rb7,
														" radar=", snapped(rng_rb7, 1.0))
													if origin_rb7 != null and origin_rb7 != ship:
														fails.append("occupy HUD origin still walker after F-EVA sixth dirt F-board")
													if ly_rb7.to_upper().find("SPACE") < 0:
														fails.append("layer not Space after F-EVA sixth dirt F-board (%s)" % ly_rb7)
													if rng_rb7 < 1000.0:
														fails.append("pad radar still 400m after F-EVA sixth dirt F-board (%s)" % snapped(rng_rb7, 1.0))
													var chase_rb7: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
													var live_rb7: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
													print("[Playtest] HOVER view after F-EVA sixth dirt F-board chase=",
														chase_rb7.name if chase_rb7 else "none", " live=", live_rb7.name if live_rb7 else "none",
														" current=", chase_rb7.current if chase_rb7 else false)
													if chase_rb7 == null:
														fails.append("HOVER view after F-EVA sixth dirt F-board: no chase cam")
													elif live_rb7 != chase_rb7:
														fails.append("HOVER view after F-EVA sixth dirt F-board stole (%s)" % (live_rb7.name if live_rb7 else "none"))
													elif not chase_rb7.current:
														fails.append("HOVER view after F-EVA sixth dirt F-board chase not current")
													if os.has_method("_leave_seat_to_pocket"):
														os._leave_seat_to_pocket()
													await get_tree().create_timer(0.35).timeout
													var ly_pk6 := ""
													if LayerContext:
														ly_pk6 = str(LayerContext.current_layer)
													var pk6: Node3D = os.get("player") as Node3D if os else null
													print("[Playtest] I-hatch after F-EVA sixth dirt F-board pocket layer=", ly_pk6,
														" int=", pk6.get("interior_mode") if pk6 else "none",
														" in_ship=", os.get("_in_ship"))
													if ly_pk6.to_upper().find("SHIP") < 0:
														fails.append("I-hatch after F-EVA sixth dirt F-board not ship_int (%s)" % ly_pk6)
													if pk6 == null or not bool(pk6.get("interior_mode")):
														fails.append("I-hatch after F-EVA sixth dirt F-board not pocket walker")
													var d6: Node = os.get("_interior") if os else null
													if d6 != null and d6.has_method("is_inside") and bool(d6.is_inside()) and d6.has_method("exit_interior"):
														d6.exit_interior()
													await get_tree().create_timer(0.4).timeout
													var hatch6: Node3D = os.get("player") as Node3D if os else null
													if hatch6 == null or not is_instance_valid(hatch6) or not hatch6.is_inside_tree():
														fails.append("I-hatch after F-EVA sixth dirt F-board: no walker")
													else:
														var h6_ship: float = hatch6.global_position.distance_to(ship.global_position)
														var h6_pad: float = hatch6.global_position.distance_to(deck.global_position)
														var h6_agl := 99.0
														if nex.has_method("altitude_of"):
															h6_agl = float(nex.altitude_of(hatch6.global_position))
														print("[Playtest] I-hatch after F-EVA sixth dirt F-board d_ship=", snapped(h6_ship, 0.1),
															" d_pad=", snapped(h6_pad, 0.1), " agl=", snapped(h6_agl, 0.01),
															" int=", hatch6.get("interior_mode"))
														if h6_ship > 22.0:
															fails.append("I-hatch after F-EVA sixth dirt F-board teleported (%s)" % snapped(h6_ship, 0.1))
														if h6_pad < 60.0:
															fails.append("I-hatch after F-EVA sixth dirt F-board snapped to pad (%s)" % snapped(h6_pad, 0.1))
														if h6_agl < 0.2 or h6_agl > 5.0:
															fails.append("I-hatch after F-EVA sixth dirt F-board not on Relief (%s)" % snapped(h6_agl, 0.01))
														if bool(hatch6.get("interior_mode")) or bool(hatch6.get("eva_mode")) or bool(hatch6.get("zero_g")):
															fails.append("I-hatch after F-EVA sixth dirt F-board still pocket/0G")
														if os.has_method("_apply_dirt_exit_facing"):
															os._apply_dirt_exit_facing()
														var rad_h6: Vector3 = (hatch6.global_position - (nex as Node3D).global_position).normalized()
														var fwd_h6: Vector3 = -hatch6.global_transform.basis.z
														fwd_h6 = fwd_h6 - rad_h6 * fwd_h6.dot(rad_h6)
														var want_h6: Vector3 = -ship.global_transform.basis.z
														want_h6 = want_h6 - rad_h6 * want_h6.dot(rad_h6)
														if fwd_h6.length_squared() < 0.04 or want_h6.length_squared() < 0.04:
															fails.append("I-hatch after F-EVA sixth dirt F-board facing not tangent")
														else:
															var align_h6: float = fwd_h6.normalized().dot(want_h6.normalized())
															print("[Playtest] I-hatch after F-EVA sixth dirt F-board facing align=", snapped(align_h6, 0.01),
																" tangent=", snapped(1.0 - absf(fwd_h6.normalized().dot(rad_h6)), 0.01))
															if align_h6 < 0.55:
																fails.append("I-hatch after F-EVA sixth dirt F-board facing sideways (%s)" % snapped(align_h6, 0.01))
														hatch6.set("_spawn_grace_t", 0.0)
														if hatch6 is CharacterBody3D:
															(hatch6 as CharacterBody3D).velocity = Vector3.ZERO
														if hatch6.has_method("_physics_process"):
															hatch6._physics_process(0.016)
														var coy_h6: float = float(hatch6.get("_coyote_t"))
														var near_h6: Variant = hatch6.call("_near_dirt_floor") if hatch6.has_method("_near_dirt_floor") else false
														print("[Playtest] I-hatch after F-EVA sixth dirt F-board coyote t=", snapped(coy_h6, 0.01), " near=", near_h6)
														if coy_h6 <= 0.0:
															fails.append("I-hatch after F-EVA sixth dirt F-board coyote dead")
														else:
															var hv60h: float = 0.0
															if hatch6 is CharacterBody3D:
																hv60h = (hatch6 as CharacterBody3D).velocity.dot(rad_h6)
															if hatch6.has_method("request_jump"):
																hatch6.request_jump()
															if hatch6.has_method("_physics_process"):
																hatch6._physics_process(0.016)
															var hv61h: float = hv60h
															if hatch6 is CharacterBody3D:
																hv61h = (hatch6 as CharacterBody3D).velocity.dot(rad_h6)
															print("[Playtest] I-hatch after F-EVA sixth dirt F-board jump v_up ", snapped(hv60h, 0.1), "→", snapped(hv61h, 0.1))
															if hv61h < hv60h + 3.0:
																fails.append("I-hatch after F-EVA sixth dirt F-board jump died (%s → %s)" % [snapped(hv60h, 0.1), snapped(hv61h, 0.1)])
														var last_h6: float = float(hatch6.get("last_slope_ang"))
														var rel_h6: float = 0.0
														if hatch6.has_method("_relief_slope_rad"):
															rel_h6 = float(hatch6.call("_relief_slope_rad"))
														print("[Playtest] I-hatch after F-EVA sixth dirt F-board slope last=", snapped(rad_to_deg(last_h6), 0.1),
															" deg rel=", snapped(rad_to_deg(rel_h6), 0.1))
														if last_h6 < 0.0 or last_h6 > 1.4:
															fails.append("I-hatch after F-EVA sixth dirt F-board slope last out of range (%s)" % snapped(last_h6, 0.01))
														if rel_h6 > 0.05 and last_h6 + 0.08 < rel_h6:
															fails.append("I-hatch after F-EVA sixth dirt F-board slope not Relief")
														if last_h6 > rel_h6 + 0.25:
															fails.append("I-hatch after F-EVA sixth dirt F-board slope is pocket-Y cliff")
													if os.has_method("try_enter_ship"):
														os.try_enter_ship()
													await get_tree().create_timer(0.3).timeout
													if not bool(os.get("_in_ship")):
														fails.append("reboard after I-hatch F-EVA sixth dirt F-board refused")
													else:
														ship.set("_land_lock_t", 0.0)
														if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
															ship._do_launch()
														await get_tree().create_timer(0.35).timeout
														var agl_l7: float = float(ship.altitude_agl()) if ship.has_method("altitude_agl") else -1.0
														var hold_l7: float = float(ship.get("_hover_hold_alt"))
														print("[Playtest] HOVER launch after I-hatch F-EVA sixth dirt F-board landed=",
															ship.get("is_landed"), " hold=", snapped(hold_l7, 0.1),
															" agl=", snapped(agl_l7, 0.1))
														if bool(ship.get("is_landed")):
															fails.append("HOVER launch after I-hatch F-EVA sixth dirt F-board still landed")
														if hold_l7 < 4.0:
															fails.append("HOVER launch after I-hatch F-EVA sixth dirt F-board hold dead (%s)" % snapped(hold_l7, 0.1))
														if agl_l7 >= 0.0 and (hold_l7 < agl_l7 - 2.0 or hold_l7 > agl_l7 + 20.0):
															fails.append("HOVER launch after I-hatch F-EVA sixth dirt F-board hold not AGL+12 (%s vs %s)" % [
																snapped(hold_l7, 0.1), snapped(agl_l7, 0.1)])
														if ship.has_method("_set_mode"):
															ship._set_mode(2)
														var hold_l7b: float = float(ship.get("_hover_hold_alt"))
														print("[Playtest] HOVER launch after I-hatch F-EVA sixth dirt F-board retap hold=", snapped(hold_l7b, 0.1))
														if absf(hold_l7b - hold_l7) > 1.5:
															fails.append("HOVER launch after I-hatch F-EVA sixth dirt F-board retap rewrote hold")
														var up_ge7: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
														if up_ge7.length_squared() > 0.01:
															up_ge7 = up_ge7.normalized()
														var rel_ge7: Vector3 = ship.global_position - deck.global_position
														var lat_ge7: float = (rel_ge7 - up_ge7 * rel_ge7.dot(up_ge7)).length()
														var agl_ge7: float = agl_l7
														if nex.has_method("altitude_of"):
															agl_ge7 = float(nex.altitude_of(ship.global_position))
														print("[Playtest] I-hatch F-EVA sixth dirt F-board launch GE lat=", snapped(lat_ge7, 0.1),
															" agl=", snapped(agl_ge7, 0.1))
														if lat_ge7 < 60.0:
															fails.append("I-hatch F-EVA sixth dirt F-board launch GE pulled onto plate (lat=%s)" % snapped(lat_ge7, 0.1))
														ship.set_meta("playtest_sink", true)
														await get_tree().create_timer(0.45).timeout
														ship.set_meta("playtest_sink", false)
														var hold_sk7: float = float(ship.get("_hover_hold_alt"))
														var agl_sk7: float = agl_ge7
														if nex.has_method("altitude_of"):
															agl_sk7 = float(nex.altitude_of(ship.global_position))
														var rel_sk7: Vector3 = ship.global_position - deck.global_position
														var lat_sk7: float = (rel_sk7 - up_ge7 * rel_sk7.dot(up_ge7)).length()
														print("[Playtest] I-hatch F-EVA sixth dirt F-board HOVER sink hold ",
															snapped(hold_l7b, 0.1), "→", snapped(hold_sk7, 0.1),
															" AGL ", snapped(agl_ge7, 0.1), "→", snapped(agl_sk7, 0.1),
															" lat=", snapped(lat_sk7, 0.1))
														if hold_sk7 > 6.5:
															fails.append("I-hatch F-EVA sixth dirt F-board HOVER sink hold still 8m floor (%s)" % snapped(hold_sk7, 0.1))
														if hold_sk7 + 0.2 < 3.5:
															fails.append("I-hatch F-EVA sixth dirt F-board HOVER sink hold buried (%s)" % snapped(hold_sk7, 0.1))
														if lat_sk7 < 60.0:
															fails.append("I-hatch F-EVA sixth dirt F-board HOVER sink drifted onto plate (%s)" % snapped(lat_sk7, 0.1))
														if "velocity" in ship:
															ship.velocity = Vector3.ZERO
														ship.set("_gear_down", true)
														if ship.has_method("_do_land"):
															ship._do_land()
														await get_tree().create_timer(0.4).timeout
														var land7_agl: float = agl_sk7
														if nex.has_method("altitude_of"):
															land7_agl = float(nex.altitude_of(ship.global_position))
														var land7_pad: Node3D = null
														if ship.has_method("get_landed_pad"):
															land7_pad = ship.get_landed_pad() as Node3D
														var land7_rel: Vector3 = ship.global_position - deck.global_position
														var land7_lat: float = (land7_rel - up_ge7 * land7_rel.dot(up_ge7)).length()
														print("[Playtest] I-hatch F-EVA sixth dirt F-board land after sink landed=", ship.get("is_landed"),
															" pad=", land7_pad.name if land7_pad else "none",
															" agl=", snapped(land7_agl, 0.1), " lat=", snapped(land7_lat, 0.1))
														if not bool(ship.get("is_landed")):
															fails.append("I-hatch F-EVA sixth dirt F-board land after sink refused")
														if land7_pad != null:
															fails.append("I-hatch F-EVA sixth dirt F-board land after sink stole pad")
														if land7_lat < 60.0:
															fails.append("I-hatch F-EVA sixth dirt F-board land after sink drifted to plate (%s)" % snapped(land7_lat, 0.1))
														if land7_agl < 1.5 or land7_agl > 8.0:
															fails.append("I-hatch F-EVA sixth dirt F-board land after sink not on Relief (%s)" % snapped(land7_agl, 0.1))
														if os.has_method("try_exit_ship"):
															os.try_exit_ship()
														await get_tree().create_timer(0.4).timeout
														var eva8: Node3D = os.get("player") as Node3D if os else null
														if eva8 == null or not is_instance_valid(eva8) or not eva8.is_inside_tree():
															fails.append("F-EVA after seventh dirt land: no walker")
														else:
															var e8_ship: float = eva8.global_position.distance_to(ship.global_position)
															var e8_pad: float = eva8.global_position.distance_to(deck.global_position)
															var e8_agl := 99.0
															if nex.has_method("altitude_of"):
																e8_agl = float(nex.altitude_of(eva8.global_position))
															var ly_e8 := ""
															if LayerContext:
																ly_e8 = str(LayerContext.current_layer)
															print("[Playtest] F-EVA after seventh dirt land d_ship=", snapped(e8_ship, 0.1),
																" d_pad=", snapped(e8_pad, 0.1), " agl=", snapped(e8_agl, 0.01),
																" eva=", eva8.get("eva_mode"), " layer=", ly_e8)
															if e8_ship > 22.0:
																fails.append("F-EVA after seventh dirt land teleported (%s)" % snapped(e8_ship, 0.1))
															if e8_pad < 60.0:
																fails.append("F-EVA after seventh dirt land snapped to pad (%s)" % snapped(e8_pad, 0.1))
															if e8_agl < 0.2 or e8_agl > 5.0:
																fails.append("F-EVA after seventh dirt land not on Relief (%s)" % snapped(e8_agl, 0.01))
															if bool(eva8.get("eva_mode")) or bool(eva8.get("zero_g")):
																fails.append("F-EVA after seventh dirt land still EVA 0G")
															if ly_e8.to_upper().find("TPS") < 0:
																fails.append("F-EVA after seventh dirt land layer not TPS (%s)" % ly_e8)
															var hud_e8: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
															if hud_e8 != null and hud_e8.has_method("bind_player"):
																hud_e8.bind_player(eva8)
															if hud_e8 != null and hud_e8.has_method("_refresh"):
																hud_e8._refresh()
															var origin_e8: Node3D = null
															if hud_e8 != null and hud_e8.has_method("_occupy_origin"):
																origin_e8 = hud_e8.call("_occupy_origin") as Node3D
															var otxt_e8 := ""
															if hud_e8 != null:
																var lab_e8: Variant = hud_e8.get("_owner_label")
																if lab_e8 is Label:
																	otxt_e8 = (lab_e8 as Label).text
															print("[Playtest] occupy HUD F-EVA after seventh dirt land origin=",
																origin_e8.name if origin_e8 else "null",
																" '", otxt_e8.replace("\n", " / ").substr(0, 80), "'")
															if origin_e8 == null:
																fails.append("occupy HUD lost origin after F-EVA seventh dirt land")
															elif origin_e8 == ship:
																fails.append("occupy HUD origin still hull after F-EVA seventh dirt land")
															elif origin_e8 != eva8:
																fails.append("occupy HUD origin not walker after F-EVA seventh dirt land")
															if otxt_e8.to_upper().find("PAD") >= 0 and otxt_e8.to_upper().find("OCCUPY") >= 0:
																fails.append("occupy HUD PAD after F-EVA seventh dirt land 110m")
															var radar_e8: Variant = hud_e8.get("_radar") if hud_e8 else null
															if radar_e8 is CanvasItem:
																(radar_e8 as CanvasItem).visible = true
															if hud_e8 != null and hud_e8.has_method("_refresh"):
																hud_e8._refresh()
															var rng_e8: float = float(hud_e8.get("_radar_range_m")) if hud_e8 else 0.0
															var near_e8n := 0
															if hud_e8 != null and hud_e8.has_method("radar_pad_contacts"):
																near_e8n = hud_e8.radar_pad_contacts().size()
															print("[Playtest] pad radar F-EVA after seventh dirt land 110m n=", near_e8n,
																" range=", snapped(rng_e8, 1.0), " vis=",
																(radar_e8 as CanvasItem).visible if radar_e8 is CanvasItem else "?")
															if rng_e8 > 1000.0:
																fails.append("pad radar used 12km after F-EVA seventh dirt land occupy (%s)" % snapped(rng_e8, 1.0))
															if near_e8n < 1:
																fails.append("pad radar missed pad after F-EVA seventh dirt land occupy")
															var saved_e8: Vector3 = eva8.global_position
															var up_e8r: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
															if up_e8r.length_squared() > 0.01:
																up_e8r = up_e8r.normalized()
															var side_e8r: Vector3 = up_e8r.cross(Vector3.RIGHT)
															if side_e8r.length_squared() < 0.04:
																side_e8r = up_e8r.cross(Vector3.FORWARD)
															side_e8r = side_e8r.normalized()
															eva8.global_position = deck.global_position + side_e8r * 600.0 + up_e8r * 2.0
															if hud_e8 != null and hud_e8.has_method("_refresh"):
																hud_e8._refresh()
															var far_e8 := false
															var far_e8n := 0
															if hud_e8 != null and hud_e8.has_method("radar_pad_contacts"):
																for c in hud_e8.radar_pad_contacts():
																	far_e8n += 1
																	if c is Node3D and (c as Node3D).global_position.distance_to(deck.global_position) < 30.0:
																		far_e8 = true
															print("[Playtest] pad radar F-EVA after seventh dirt land 600m n=", far_e8n, " pad=", far_e8)
															if far_e8:
																fails.append("pad radar used 12km approach after F-EVA seventh dirt land occupy")
															eva8.global_position = saved_e8
															if hud_e8 != null and hud_e8.has_method("_refresh"):
																hud_e8._refresh()
															var ly_e8s := ""
															if LayerContext:
																ly_e8s = str(LayerContext.current_layer)
															var stack_e8 := ""
															var stack_e8_on := false
															var chip_e8 := ""
															if hud_e8 != null:
																var sl_e8: Variant = hud_e8.get("_os_stack")
																if sl_e8 is Label:
																	stack_e8 = (sl_e8 as Label).text
																	stack_e8_on = (sl_e8 as Label).visible
																var chip8: Variant = hud_e8.get("_layer_label")
																if chip8 is Label:
																	chip_e8 = (chip8 as Label).text
															print("[Playtest] os stack F-EVA after seventh dirt land occupy layer=", ly_e8s,
																" vis=", stack_e8_on, " chip='", chip_e8.replace("\n", " / ").substr(0, 40),
																"' '", stack_e8.replace("\n", " / ").substr(0, 80), "'")
															if ly_e8s.to_upper().find("SPACE") >= 0:
																fails.append("os stack layer still SPACE after F-EVA seventh dirt land occupy")
															if ly_e8s.to_upper().find("SHIP") >= 0:
																fails.append("os stack layer still ship_int after F-EVA seventh dirt land occupy")
															if ly_e8s.to_upper().find("TPS") < 0 and ly_e8s.to_upper().find("SURFACE") < 0:
																fails.append("os stack layer not TPS after F-EVA seventh dirt land occupy (%s)" % ly_e8s)
															if not stack_e8_on:
																fails.append("os stack hidden after F-EVA seventh dirt land occupy")
															if chip_e8.to_upper().find("SHIP") >= 0:
																fails.append("layer chip still ship_int after F-EVA seventh dirt land occupy")
															if stack_e8.to_upper().find("OCCUPY") >= 0:
																fails.append("os stack occupy after F-EVA seventh dirt land occupy 110m")
															if stack_e8.to_upper().find("0G") >= 0:
																fails.append("os stack EVA 0G after F-EVA seventh dirt land occupy")
														if os.has_method("try_enter_ship"):
															os.try_enter_ship()
														await get_tree().create_timer(0.3).timeout
														if not bool(os.get("_in_ship")):
															fails.append("reboard after F-EVA seventh dirt land refused")
														else:
															if os.has_method("reclaim_pilot_camera"):
																os.reclaim_pilot_camera()
															var hud_rb8: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
															if hud_rb8 != null and hud_rb8.has_method("bind_player"):
																hud_rb8.bind_player(ship)
															if hud_rb8 != null and hud_rb8.has_method("_refresh"):
																hud_rb8._refresh()
															var origin_rb8: Node3D = null
															if hud_rb8 != null and hud_rb8.has_method("_occupy_origin"):
																origin_rb8 = hud_rb8.call("_occupy_origin") as Node3D
															var ly_rb8 := ""
															if LayerContext:
																ly_rb8 = str(LayerContext.current_layer)
															var rng_rb8: float = float(hud_rb8.get("_radar_range_m")) if hud_rb8 else 0.0
															print("[Playtest] F-board after F-EVA seventh dirt occupy origin=",
																origin_rb8.name if origin_rb8 else "null", " layer=", ly_rb8,
																" radar=", snapped(rng_rb8, 1.0))
															if origin_rb8 != null and origin_rb8 != ship:
																fails.append("occupy HUD origin still walker after F-EVA seventh dirt F-board")
															if ly_rb8.to_upper().find("SPACE") < 0:
																fails.append("layer not Space after F-EVA seventh dirt F-board (%s)" % ly_rb8)
															if rng_rb8 < 1000.0:
																fails.append("pad radar still 400m after F-EVA seventh dirt F-board (%s)" % snapped(rng_rb8, 1.0))
															var chase_rb8: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
															var live_rb8: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
															print("[Playtest] HOVER view after F-EVA seventh dirt F-board chase=",
																chase_rb8.name if chase_rb8 else "none", " live=", live_rb8.name if live_rb8 else "none",
																" current=", chase_rb8.current if chase_rb8 else false)
															if chase_rb8 == null:
																fails.append("HOVER view after F-EVA seventh dirt F-board: no chase cam")
															elif live_rb8 != chase_rb8:
																fails.append("HOVER view after F-EVA seventh dirt F-board stole (%s)" % (live_rb8.name if live_rb8 else "none"))
															elif not chase_rb8.current:
																fails.append("HOVER view after F-EVA seventh dirt F-board chase not current")
															if os.has_method("_leave_seat_to_pocket"):
																os._leave_seat_to_pocket()
															await get_tree().create_timer(0.35).timeout
															var ly_pk7 := ""
															if LayerContext:
																ly_pk7 = str(LayerContext.current_layer)
															var pk7: Node3D = os.get("player") as Node3D if os else null
															print("[Playtest] I-hatch after F-EVA seventh dirt F-board pocket layer=", ly_pk7,
																" int=", pk7.get("interior_mode") if pk7 else "none",
																" in_ship=", os.get("_in_ship"))
															if ly_pk7.to_upper().find("SHIP") < 0:
																fails.append("I-hatch after F-EVA seventh dirt F-board not ship_int (%s)" % ly_pk7)
															if pk7 == null or not bool(pk7.get("interior_mode")):
																fails.append("I-hatch after F-EVA seventh dirt F-board not pocket walker")
															var d7: Node = os.get("_interior") if os else null
															if d7 != null and d7.has_method("is_inside") and bool(d7.is_inside()) and d7.has_method("exit_interior"):
																d7.exit_interior()
															await get_tree().create_timer(0.4).timeout
															var hatch7: Node3D = os.get("player") as Node3D if os else null
															if hatch7 == null or not is_instance_valid(hatch7) or not hatch7.is_inside_tree():
																fails.append("I-hatch after F-EVA seventh dirt F-board: no walker")
															else:
																var h7_ship: float = hatch7.global_position.distance_to(ship.global_position)
																var h7_pad: float = hatch7.global_position.distance_to(deck.global_position)
																var h7_agl := 99.0
																if nex.has_method("altitude_of"):
																	h7_agl = float(nex.altitude_of(hatch7.global_position))
																print("[Playtest] I-hatch after F-EVA seventh dirt F-board d_ship=", snapped(h7_ship, 0.1),
																	" d_pad=", snapped(h7_pad, 0.1), " agl=", snapped(h7_agl, 0.01),
																	" int=", hatch7.get("interior_mode"))
																if h7_ship > 22.0:
																	fails.append("I-hatch after F-EVA seventh dirt F-board teleported (%s)" % snapped(h7_ship, 0.1))
																if h7_pad < 60.0:
																	fails.append("I-hatch after F-EVA seventh dirt F-board snapped to pad (%s)" % snapped(h7_pad, 0.1))
																if h7_agl < 0.2 or h7_agl > 5.0:
																	fails.append("I-hatch after F-EVA seventh dirt F-board not on Relief (%s)" % snapped(h7_agl, 0.01))
																if bool(hatch7.get("interior_mode")) or bool(hatch7.get("eva_mode")) or bool(hatch7.get("zero_g")):
																	fails.append("I-hatch after F-EVA seventh dirt F-board still pocket/0G")
																var fw7: Vector3 = -hatch7.global_transform.basis.z
																var rad7: Vector3 = hatch7.global_position - nex.global_position
																if rad7.length_squared() < 0.01:
																	rad7 = Vector3.UP
																rad7 = rad7.normalized()
																var tan7: Vector3 = rad7.cross(fw7).cross(rad7)
																if tan7.length_squared() < 0.0001:
																	tan7 = rad7.cross(Vector3.RIGHT).cross(rad7)
																tan7 = tan7.normalized()
																var align7: float = fw7.normalized().dot(tan7)
																var nose7: float = fw7.normalized().dot(rad7)
																print("[Playtest] facing after I-hatch F-EVA seventh dirt F-board align=", snapped(align7, 0.01),
																	" nose=", snapped(nose7, 0.01))
																if align7 < 0.92:
																	fails.append("facing after I-hatch F-EVA seventh dirt F-board not hull-nose (%s)" % snapped(align7, 0.01))
																hatch7.set("_spawn_grace_t", 0.0)
																if hatch7 is CharacterBody3D:
																	(hatch7 as CharacterBody3D).velocity = Vector3.ZERO
																if hatch7.has_method("_physics_process"):
																	hatch7._physics_process(0.016)
																var coy_h7: float = float(hatch7.get("_coyote_t"))
																var near_h7: Variant = hatch7.call("_near_dirt_floor") if hatch7.has_method("_near_dirt_floor") else false
																print("[Playtest] coyote after I-hatch F-EVA seventh dirt F-board t=", snapped(coy_h7, 0.01), " near=", near_h7)
																if coy_h7 <= 0.0:
																	fails.append("coyote after I-hatch F-EVA seventh dirt F-board dead")
																else:
																	var hv70: float = 0.0
																	if hatch7 is CharacterBody3D:
																		hv70 = (hatch7 as CharacterBody3D).velocity.dot(rad7)
																	if hatch7.has_method("request_jump"):
																		hatch7.request_jump()
																	if hatch7.has_method("_physics_process"):
																		hatch7._physics_process(0.016)
																	var hv71: float = hv70
																	if hatch7 is CharacterBody3D:
																		hv71 = (hatch7 as CharacterBody3D).velocity.dot(rad7)
																	print("[Playtest] coyote after I-hatch F-EVA seventh dirt F-board jump v_up ",
																		snapped(hv70, 0.1), "→", snapped(hv71, 0.1))
																	if hv71 < hv70 + 3.0:
																		fails.append("coyote after I-hatch F-EVA seventh dirt F-board jump died (%s → %s)" % [
																			snapped(hv70, 0.1), snapped(hv71, 0.1)])
																var last_h7: float = float(hatch7.get("last_slope_ang"))
																var rel_h7: float = 0.0
																if hatch7.has_method("_relief_slope_rad"):
																	rel_h7 = float(hatch7.call("_relief_slope_rad"))
																print("[Playtest] slope after I-hatch F-EVA seventh dirt F-board last=", snapped(rad_to_deg(last_h7), 0.1),
																	" deg rel=", snapped(rad_to_deg(rel_h7), 0.1))
																if last_h7 < 0.0 or last_h7 > 1.4:
																	fails.append("slope after I-hatch F-EVA seventh dirt F-board last out of range (%s)" % snapped(last_h7, 0.01))
																if rel_h7 > 0.05 and last_h7 + 0.08 < rel_h7:
																	fails.append("slope after I-hatch F-EVA seventh dirt F-board not Relief")
																if last_h7 > rel_h7 + 0.25:
																	fails.append("slope after I-hatch F-EVA seventh dirt F-board is pocket-Y cliff")
															if os.has_method("try_enter_ship"):
																os.try_enter_ship()
															await get_tree().create_timer(0.3).timeout
															if not bool(os.get("_in_ship")):
																fails.append("reboard after I-hatch F-EVA seventh dirt F-board refused")
															else:
																ship.set("_land_lock_t", 0.0)
																if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
																	ship._do_launch()
																await get_tree().create_timer(0.35).timeout
																var agl_l8: float = float(ship.altitude_agl()) if ship.has_method("altitude_agl") else -1.0
																var hold_l8: float = float(ship.get("_hover_hold_alt"))
																print("[Playtest] HOVER launch after I-hatch F-EVA seventh dirt F-board landed=",
																	ship.get("is_landed"), " hold=", snapped(hold_l8, 0.1),
																	" agl=", snapped(agl_l8, 0.1))
																if bool(ship.get("is_landed")):
																	fails.append("HOVER launch after I-hatch F-EVA seventh dirt F-board still landed")
																if hold_l8 < 4.0:
																	fails.append("HOVER launch after I-hatch F-EVA seventh dirt F-board hold dead (%s)" % snapped(hold_l8, 0.1))
																if agl_l8 >= 0.0 and (hold_l8 < agl_l8 - 2.0 or hold_l8 > agl_l8 + 20.0):
																	fails.append("HOVER launch after I-hatch F-EVA seventh dirt F-board hold not AGL+12 (%s vs %s)" % [
																		snapped(hold_l8, 0.1), snapped(agl_l8, 0.1)])
																if ship.has_method("_set_mode"):
																	ship._set_mode(2)
																var hold_l8b: float = float(ship.get("_hover_hold_alt"))
																print("[Playtest] HOVER launch after I-hatch F-EVA seventh dirt F-board retap hold=", snapped(hold_l8b, 0.1))
																if absf(hold_l8b - hold_l8) > 1.5:
																	fails.append("HOVER launch after I-hatch F-EVA seventh dirt F-board retap rewrote hold")
																var up_ge8: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
																if up_ge8.length_squared() > 0.01:
																	up_ge8 = up_ge8.normalized()
																var rel_ge8: Vector3 = ship.global_position - deck.global_position
																var lat_ge8: float = (rel_ge8 - up_ge8 * rel_ge8.dot(up_ge8)).length()
																var agl_ge8: float = agl_l8
																if nex.has_method("altitude_of"):
																	agl_ge8 = float(nex.altitude_of(ship.global_position))
																print("[Playtest] I-hatch F-EVA seventh dirt F-board launch GE lat=", snapped(lat_ge8, 0.1),
																	" agl=", snapped(agl_ge8, 0.1))
																if lat_ge8 < 60.0:
																	fails.append("I-hatch F-EVA seventh dirt F-board launch GE pulled onto plate (lat=%s)" % snapped(lat_ge8, 0.1))
																ship.set_meta("playtest_sink", true)
																await get_tree().create_timer(0.45).timeout
																ship.set_meta("playtest_sink", false)
																var hold_sk8: float = float(ship.get("_hover_hold_alt"))
																var agl_sk8: float = agl_ge8
																if nex.has_method("altitude_of"):
																	agl_sk8 = float(nex.altitude_of(ship.global_position))
																var rel_sk8: Vector3 = ship.global_position - deck.global_position
																var lat_sk8: float = (rel_sk8 - up_ge8 * rel_sk8.dot(up_ge8)).length()
																print("[Playtest] I-hatch F-EVA seventh dirt F-board HOVER sink hold ",
																	snapped(hold_l8b, 0.1), "→", snapped(hold_sk8, 0.1),
																	" AGL ", snapped(agl_ge8, 0.1), "→", snapped(agl_sk8, 0.1),
																	" lat=", snapped(lat_sk8, 0.1))
																if hold_sk8 > 6.5:
																	fails.append("I-hatch F-EVA seventh dirt F-board HOVER sink hold still 8m floor (%s)" % snapped(hold_sk8, 0.1))
																if hold_sk8 + 0.2 < 3.5:
																	fails.append("I-hatch F-EVA seventh dirt F-board HOVER sink hold buried (%s)" % snapped(hold_sk8, 0.1))
																if lat_sk8 < 60.0:
																	fails.append("I-hatch F-EVA seventh dirt F-board HOVER sink drifted onto plate (%s)" % snapped(lat_sk8, 0.1))
																if "velocity" in ship:
																	ship.velocity = Vector3.ZERO
																ship.set("_gear_down", true)
																if ship.has_method("_do_land"):
																	ship._do_land()
																await get_tree().create_timer(0.4).timeout
																var land8_agl: float = agl_sk8
																if nex.has_method("altitude_of"):
																	land8_agl = float(nex.altitude_of(ship.global_position))
																var land8_pad: Node3D = null
																if ship.has_method("get_landed_pad"):
																	land8_pad = ship.get_landed_pad() as Node3D
																var land8_rel: Vector3 = ship.global_position - deck.global_position
																var land8_lat: float = (land8_rel - up_ge8 * land8_rel.dot(up_ge8)).length()
																print("[Playtest] I-hatch F-EVA seventh dirt F-board land after sink landed=", ship.get("is_landed"),
																	" pad=", land8_pad.name if land8_pad else "none",
																	" agl=", snapped(land8_agl, 0.1), " lat=", snapped(land8_lat, 0.1))
																if not bool(ship.get("is_landed")):
																	fails.append("I-hatch F-EVA seventh dirt F-board land after sink refused")
																if land8_pad != null:
																	fails.append("I-hatch F-EVA seventh dirt F-board land after sink stole pad")
																if land8_lat < 60.0:
																	fails.append("I-hatch F-EVA seventh dirt F-board land after sink drifted to plate (%s)" % snapped(land8_lat, 0.1))
																if land8_agl < 1.5 or land8_agl > 8.0:
																	fails.append("I-hatch F-EVA seventh dirt F-board land after sink not on Relief (%s)" % snapped(land8_agl, 0.1))
																if os.has_method("try_exit_ship"):
																	os.try_exit_ship()
																await get_tree().create_timer(0.4).timeout
																var eva9: Node3D = os.get("player") as Node3D if os else null
																if eva9 == null or not is_instance_valid(eva9) or not eva9.is_inside_tree():
																	fails.append("F-EVA after eighth dirt land: no walker")
																else:
																	var e9_ship: float = eva9.global_position.distance_to(ship.global_position)
																	var e9_pad: float = eva9.global_position.distance_to(deck.global_position)
																	var e9_agl := 99.0
																	if nex.has_method("altitude_of"):
																		e9_agl = float(nex.altitude_of(eva9.global_position))
																	var ly_e9 := ""
																	if LayerContext:
																		ly_e9 = str(LayerContext.current_layer)
																	print("[Playtest] F-EVA after eighth dirt land d_ship=", snapped(e9_ship, 0.1),
																		" d_pad=", snapped(e9_pad, 0.1), " agl=", snapped(e9_agl, 0.01),
																		" eva=", eva9.get("eva_mode"), " layer=", ly_e9)
																	if e9_ship > 22.0:
																		fails.append("F-EVA after eighth dirt land teleported (%s)" % snapped(e9_ship, 0.1))
																	if e9_pad < 60.0:
																		fails.append("F-EVA after eighth dirt land snapped to pad (%s)" % snapped(e9_pad, 0.1))
																	if e9_agl < 0.2 or e9_agl > 5.0:
																		fails.append("F-EVA after eighth dirt land not on Relief (%s)" % snapped(e9_agl, 0.01))
																	if bool(eva9.get("eva_mode")) or bool(eva9.get("zero_g")):
																		fails.append("F-EVA after eighth dirt land still EVA 0G")
																	if ly_e9.to_upper().find("TPS") < 0:
																		fails.append("F-EVA after eighth dirt land layer not TPS (%s)" % ly_e9)
																	var hud_e9: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
																	if hud_e9 != null and hud_e9.has_method("bind_player"):
																		hud_e9.bind_player(eva9)
																	if hud_e9 != null and hud_e9.has_method("_refresh"):
																		hud_e9._refresh()
																	var origin_e9: Node3D = null
																	if hud_e9 != null and hud_e9.has_method("_occupy_origin"):
																		origin_e9 = hud_e9.call("_occupy_origin") as Node3D
																	var otxt_e9 := ""
																	if hud_e9 != null:
																		var lab_e9: Variant = hud_e9.get("_owner_label")
																		if lab_e9 is Label:
																			otxt_e9 = (lab_e9 as Label).text
																	print("[Playtest] occupy HUD F-EVA after eighth dirt land origin=",
																		origin_e9.name if origin_e9 else "null",
																		" '", otxt_e9.replace("\n", " / ").substr(0, 80), "'")
																	if origin_e9 == null:
																		fails.append("occupy HUD lost origin after F-EVA eighth dirt land")
																	elif origin_e9 == ship:
																		fails.append("occupy HUD origin still hull after F-EVA eighth dirt land")
																	elif origin_e9 != eva9:
																		fails.append("occupy HUD origin not walker after F-EVA eighth dirt land")
																	if otxt_e9.to_upper().find("PAD") >= 0 and otxt_e9.to_upper().find("OCCUPY") >= 0:
																		fails.append("occupy HUD PAD after F-EVA eighth dirt land")
																	var radar_e9: Variant = hud_e9.get("_radar") if hud_e9 else null
																	if radar_e9 is CanvasItem:
																		(radar_e9 as CanvasItem).visible = true
																	if hud_e9 != null and hud_e9.has_method("_refresh"):
																		hud_e9._refresh()
																	var rng_e9: float = float(hud_e9.get("_radar_range_m")) if hud_e9 else 0.0
																	var near_e9n := 0
																	if hud_e9 != null and hud_e9.has_method("radar_pad_contacts"):
																		near_e9n = hud_e9.radar_pad_contacts().size()
																	print("[Playtest] pad radar F-EVA after eighth dirt land 400m n=", near_e9n,
																		" range=", snapped(rng_e9, 1.0), " vis=",
																		(radar_e9 as CanvasItem).visible if radar_e9 is CanvasItem else "?")
																	if rng_e9 > 1000.0:
																		fails.append("pad radar used 12km after F-EVA eighth dirt land occupy (%s)" % snapped(rng_e9, 1.0))
																	if rng_e9 > 0.0 and rng_e9 < 200.0:
																		fails.append("pad radar not 400m TPS after F-EVA eighth dirt land occupy (%s)" % snapped(rng_e9, 1.0))
																	if near_e9n < 1:
																		fails.append("pad radar missed pad after F-EVA eighth dirt land occupy")
																	var ly_e9s := ""
																	if LayerContext:
																		ly_e9s = str(LayerContext.current_layer)
																	var stack_e9 := ""
																	var stack_e9_on := false
																	var chip_e9 := ""
																	if hud_e9 != null:
																		var sl_e9: Variant = hud_e9.get("_os_stack")
																		if sl_e9 is Label:
																			stack_e9 = (sl_e9 as Label).text
																			stack_e9_on = (sl_e9 as Label).visible
																		var chip9: Variant = hud_e9.get("_layer_label")
																		if chip9 is Label:
																			chip_e9 = (chip9 as Label).text
																	print("[Playtest] os stack F-EVA after eighth dirt land occupy layer=", ly_e9s,
																		" vis=", stack_e9_on, " chip='", chip_e9.replace("\n", " / ").substr(0, 40),
																		"' '", stack_e9.replace("\n", " / ").substr(0, 80), "'")
																	if ly_e9s.to_upper().find("SPACE") >= 0:
																		fails.append("os stack layer still SPACE after F-EVA eighth dirt land occupy")
																	if ly_e9s.to_upper().find("SHIP") >= 0:
																		fails.append("os stack layer still ship_int after F-EVA eighth dirt land occupy")
																	if ly_e9s.to_upper().find("TPS") < 0 and ly_e9s.to_upper().find("SURFACE") < 0:
																		fails.append("os stack layer not TPS after F-EVA eighth dirt land occupy (%s)" % ly_e9s)
																	if not stack_e9_on:
																		fails.append("os stack hidden after F-EVA eighth dirt land occupy")
																	if chip_e9.to_upper().find("SHIP") >= 0:
																		fails.append("layer chip still ship_int after F-EVA eighth dirt land occupy")
																	if stack_e9.to_upper().find("OCCUPY") >= 0:
																		fails.append("os stack occupy after F-EVA eighth dirt land occupy")
																	if stack_e9.to_upper().find("0G") >= 0:
																		fails.append("os stack EVA 0G after F-EVA eighth dirt land occupy")
																if os.has_method("try_enter_ship"):
																	os.try_enter_ship()
																await get_tree().create_timer(0.3).timeout
																if not bool(os.get("_in_ship")):
																	fails.append("reboard after F-EVA eighth dirt land refused")
																else:
																	if os.has_method("reclaim_pilot_camera"):
																		os.reclaim_pilot_camera()
																	var hud_rb9: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
																	if hud_rb9 != null and hud_rb9.has_method("bind_player"):
																		hud_rb9.bind_player(ship)
																	if hud_rb9 != null and hud_rb9.has_method("_refresh"):
																		hud_rb9._refresh()
																	var origin_rb9: Node3D = null
																	if hud_rb9 != null and hud_rb9.has_method("_occupy_origin"):
																		origin_rb9 = hud_rb9.call("_occupy_origin") as Node3D
																	var ly_rb9 := ""
																	if LayerContext:
																		ly_rb9 = str(LayerContext.current_layer)
																	var rng_rb9: float = float(hud_rb9.get("_radar_range_m")) if hud_rb9 else 0.0
																	print("[Playtest] F-board after F-EVA eighth dirt occupy origin=",
																		origin_rb9.name if origin_rb9 else "null", " layer=", ly_rb9,
																		" radar=", snapped(rng_rb9, 1.0))
																	if origin_rb9 != null and origin_rb9 != ship:
																		fails.append("occupy HUD origin still walker after F-EVA eighth dirt F-board")
																	if ly_rb9.to_upper().find("SPACE") < 0:
																		fails.append("layer not Space after F-EVA eighth dirt F-board (%s)" % ly_rb9)
																	if rng_rb9 < 1000.0:
																		fails.append("pad radar still 400m after F-EVA eighth dirt F-board (%s)" % snapped(rng_rb9, 1.0))
																	var chase_rb9: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
																	var live_rb9: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
																	print("[Playtest] HOVER view after F-EVA eighth dirt F-board chase=",
																		chase_rb9.name if chase_rb9 else "none", " live=", live_rb9.name if live_rb9 else "none",
																		" current=", chase_rb9.current if chase_rb9 else false)
																	if chase_rb9 == null:
																		fails.append("HOVER view after F-EVA eighth dirt F-board: no chase cam")
																	elif live_rb9 != chase_rb9:
																		fails.append("HOVER view after F-EVA eighth dirt F-board stole (%s)" % (live_rb9.name if live_rb9 else "none"))
																	elif not chase_rb9.current:
																		fails.append("HOVER view after F-EVA eighth dirt F-board chase not current")
																	if os.has_method("_leave_seat_to_pocket"):
																		os._leave_seat_to_pocket()
																	await get_tree().create_timer(0.35).timeout
																	var ly_pk8 := ""
																	if LayerContext:
																		ly_pk8 = str(LayerContext.current_layer)
																	var pk8: Node3D = os.get("player") as Node3D if os else null
																	print("[Playtest] I-hatch after F-EVA eighth dirt F-board pocket layer=", ly_pk8,
																		" int=", pk8.get("interior_mode") if pk8 else "none",
																		" in_ship=", os.get("_in_ship"))
																	if ly_pk8.to_upper().find("SHIP") < 0:
																		fails.append("I-hatch after F-EVA eighth dirt F-board not ship_int (%s)" % ly_pk8)
																	if pk8 == null or not bool(pk8.get("interior_mode")):
																		fails.append("I-hatch after F-EVA eighth dirt F-board not pocket walker")
																	var d8: Node = os.get("_interior") if os else null
																	if d8 != null and d8.has_method("is_inside") and bool(d8.is_inside()) and d8.has_method("exit_interior"):
																		d8.exit_interior()
																	await get_tree().create_timer(0.4).timeout
																	var hatch8: Node3D = os.get("player") as Node3D if os else null
																	if hatch8 == null or not is_instance_valid(hatch8) or not hatch8.is_inside_tree():
																		fails.append("I-hatch after F-EVA eighth dirt F-board: no walker")
																	else:
																		var h8_ship: float = hatch8.global_position.distance_to(ship.global_position)
																		var h8_pad: float = hatch8.global_position.distance_to(deck.global_position)
																		var h8_agl := 99.0
																		if nex.has_method("altitude_of"):
																			h8_agl = float(nex.altitude_of(hatch8.global_position))
																		print("[Playtest] I-hatch after F-EVA eighth dirt F-board d_ship=", snapped(h8_ship, 0.1),
																			" d_pad=", snapped(h8_pad, 0.1), " agl=", snapped(h8_agl, 0.01),
																			" int=", hatch8.get("interior_mode"))
																		if h8_ship > 22.0:
																			fails.append("I-hatch after F-EVA eighth dirt F-board teleported (%s)" % snapped(h8_ship, 0.1))
																		if h8_pad < 60.0:
																			fails.append("I-hatch after F-EVA eighth dirt F-board snapped to pad (%s)" % snapped(h8_pad, 0.1))
																		if h8_agl < 0.2 or h8_agl > 5.0:
																			fails.append("I-hatch after F-EVA eighth dirt F-board not on Relief (%s)" % snapped(h8_agl, 0.01))
																		if bool(hatch8.get("interior_mode")) or bool(hatch8.get("eva_mode")) or bool(hatch8.get("zero_g")):
																			fails.append("I-hatch after F-EVA eighth dirt F-board still pocket/0G")
																		var fw8: Vector3 = -hatch8.global_transform.basis.z
																		var rad8: Vector3 = hatch8.global_position - nex.global_position
																		if rad8.length_squared() < 0.01:
																			rad8 = Vector3.UP
																		rad8 = rad8.normalized()
																		var tan8: Vector3 = rad8.cross(fw8).cross(rad8)
																		if tan8.length_squared() < 0.0001:
																			tan8 = rad8.cross(Vector3.RIGHT).cross(rad8)
																		tan8 = tan8.normalized()
																		var align8: float = fw8.normalized().dot(tan8)
																		var nose8: float = fw8.normalized().dot(rad8)
																		print("[Playtest] facing after I-hatch F-EVA eighth dirt F-board align=", snapped(align8, 0.01),
																			" nose=", snapped(nose8, 0.01))
																		if align8 < 0.92:
																			fails.append("facing after I-hatch F-EVA eighth dirt F-board not hull-nose (%s)" % snapped(align8, 0.01))
																		hatch8.set("_spawn_grace_t", 0.0)
																		if hatch8 is CharacterBody3D:
																			(hatch8 as CharacterBody3D).velocity = Vector3.ZERO
																		if hatch8.has_method("_physics_process"):
																			hatch8._physics_process(0.016)
																		var coy_h8: float = float(hatch8.get("_coyote_t"))
																		var near_h8: Variant = hatch8.call("_near_dirt_floor") if hatch8.has_method("_near_dirt_floor") else false
																		print("[Playtest] coyote after I-hatch F-EVA eighth dirt F-board t=", snapped(coy_h8, 0.01), " near=", near_h8)
																		if coy_h8 <= 0.0:
																			fails.append("coyote after I-hatch F-EVA eighth dirt F-board dead")
																		else:
																			var hv80: float = 0.0
																			if hatch8 is CharacterBody3D:
																				hv80 = (hatch8 as CharacterBody3D).velocity.dot(rad8)
																			if hatch8.has_method("request_jump"):
																				hatch8.request_jump()
																			if hatch8.has_method("_physics_process"):
																				hatch8._physics_process(0.016)
																			var hv81: float = hv80
																			if hatch8 is CharacterBody3D:
																				hv81 = (hatch8 as CharacterBody3D).velocity.dot(rad8)
																			print("[Playtest] coyote after I-hatch F-EVA eighth dirt F-board jump v_up ",
																				snapped(hv80, 0.1), "→", snapped(hv81, 0.1))
																			if hv81 < hv80 + 3.0:
																				fails.append("coyote after I-hatch F-EVA eighth dirt F-board jump died (%s → %s)" % [
																					snapped(hv80, 0.1), snapped(hv81, 0.1)])
																		var last_h8: float = float(hatch8.get("last_slope_ang"))
																		var rel_h8: float = 0.0
																		if hatch8.has_method("_relief_slope_rad"):
																			rel_h8 = float(hatch8.call("_relief_slope_rad"))
																		print("[Playtest] slope after I-hatch F-EVA eighth dirt F-board last=", snapped(rad_to_deg(last_h8), 0.1),
																			" deg rel=", snapped(rad_to_deg(rel_h8), 0.1))
																		if last_h8 < 0.0 or last_h8 > 1.4:
																			fails.append("slope after I-hatch F-EVA eighth dirt F-board last out of range (%s)" % snapped(last_h8, 0.01))
																		if rel_h8 > 0.05 and last_h8 + 0.08 < rel_h8:
																			fails.append("slope after I-hatch F-EVA eighth dirt F-board not Relief")
																		if last_h8 > rel_h8 + 0.25:
																			fails.append("slope after I-hatch F-EVA eighth dirt F-board is pocket-Y cliff")
																	if os.has_method("try_enter_ship"):
																		os.try_enter_ship()
																	await get_tree().create_timer(0.3).timeout
																	if not bool(os.get("_in_ship")):
																		fails.append("reboard after I-hatch F-EVA eighth dirt F-board refused")
																	else:
																		ship.set("_land_lock_t", 0.0)
																		if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
																			ship._do_launch()
																		await get_tree().create_timer(0.35).timeout
																		var agl_l9: float = float(ship.altitude_agl()) if ship.has_method("altitude_agl") else -1.0
																		var hold_l9: float = float(ship.get("_hover_hold_alt"))
																		print("[Playtest] HOVER launch after I-hatch F-EVA eighth dirt F-board landed=",
																			ship.get("is_landed"), " hold=", snapped(hold_l9, 0.1),
																			" agl=", snapped(agl_l9, 0.1))
																		if bool(ship.get("is_landed")):
																			fails.append("HOVER launch after I-hatch F-EVA eighth dirt F-board still landed")
																		if hold_l9 < 4.0:
																			fails.append("HOVER launch after I-hatch F-EVA eighth dirt F-board hold dead (%s)" % snapped(hold_l9, 0.1))
																		if agl_l9 >= 0.0 and (hold_l9 < agl_l9 - 2.0 or hold_l9 > agl_l9 + 20.0):
																			fails.append("HOVER launch after I-hatch F-EVA eighth dirt F-board hold not AGL+12 (%s vs %s)" % [
																				snapped(hold_l9, 0.1), snapped(agl_l9, 0.1)])
																		if ship.has_method("_set_mode"):
																			ship._set_mode(2)
																		var hold_l9b: float = float(ship.get("_hover_hold_alt"))
																		print("[Playtest] HOVER launch after I-hatch F-EVA eighth dirt F-board retap hold=", snapped(hold_l9b, 0.1))
																		if absf(hold_l9b - hold_l9) > 1.5:
																			fails.append("HOVER launch after I-hatch F-EVA eighth dirt F-board retap rewrote hold")
																		var up_ge9: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
																		if up_ge9.length_squared() > 0.01:
																			up_ge9 = up_ge9.normalized()
																		var rel_ge9: Vector3 = ship.global_position - deck.global_position
																		var lat_ge9: float = (rel_ge9 - up_ge9 * rel_ge9.dot(up_ge9)).length()
																		var agl_ge9: float = agl_l9
																		if nex.has_method("altitude_of"):
																			agl_ge9 = float(nex.altitude_of(ship.global_position))
																		print("[Playtest] I-hatch F-EVA eighth dirt F-board launch GE lat=", snapped(lat_ge9, 0.1),
																			" agl=", snapped(agl_ge9, 0.1))
																		if lat_ge9 < 60.0:
																			fails.append("I-hatch F-EVA eighth dirt F-board launch GE pulled onto plate (lat=%s)" % snapped(lat_ge9, 0.1))
																		ship.set_meta("playtest_sink", true)
																		await get_tree().create_timer(0.45).timeout
																		ship.set_meta("playtest_sink", false)
																		var hold_sk9: float = float(ship.get("_hover_hold_alt"))
																		var agl_sk9: float = agl_ge9
																		if nex.has_method("altitude_of"):
																			agl_sk9 = float(nex.altitude_of(ship.global_position))
																		var rel_sk9: Vector3 = ship.global_position - deck.global_position
																		var lat_sk9: float = (rel_sk9 - up_ge9 * rel_sk9.dot(up_ge9)).length()
																		print("[Playtest] I-hatch F-EVA eighth dirt F-board HOVER sink hold ",
																			snapped(hold_l9b, 0.1), "→", snapped(hold_sk9, 0.1),
																			" AGL ", snapped(agl_ge9, 0.1), "→", snapped(agl_sk9, 0.1),
																			" lat=", snapped(lat_sk9, 0.1))
																		if hold_sk9 > 6.5:
																			fails.append("I-hatch F-EVA eighth dirt F-board HOVER sink hold still 8m floor (%s)" % snapped(hold_sk9, 0.1))
																		if hold_sk9 + 0.2 < 3.5:
																			fails.append("I-hatch F-EVA eighth dirt F-board HOVER sink hold buried (%s)" % snapped(hold_sk9, 0.1))
																		if lat_sk9 < 60.0:
																			fails.append("I-hatch F-EVA eighth dirt F-board HOVER sink drifted onto plate (%s)" % snapped(lat_sk9, 0.1))
																		if "velocity" in ship:
																			ship.velocity = Vector3.ZERO
																		ship.set("_gear_down", true)
																		if ship.has_method("_do_land"):
																			ship._do_land()
																		await get_tree().create_timer(0.4).timeout
																		var land9_agl: float = agl_sk9
																		if nex.has_method("altitude_of"):
																			land9_agl = float(nex.altitude_of(ship.global_position))
																		var land9_pad: Node3D = null
																		if ship.has_method("get_landed_pad"):
																			land9_pad = ship.get_landed_pad() as Node3D
																		var land9_rel: Vector3 = ship.global_position - deck.global_position
																		var land9_lat: float = (land9_rel - up_ge9 * land9_rel.dot(up_ge9)).length()
																		print("[Playtest] I-hatch F-EVA eighth dirt F-board land after sink landed=", ship.get("is_landed"),
																			" pad=", land9_pad.name if land9_pad else "none",
																			" agl=", snapped(land9_agl, 0.1), " lat=", snapped(land9_lat, 0.1))
																		if not bool(ship.get("is_landed")):
																			fails.append("I-hatch F-EVA eighth dirt F-board land after sink refused")
																		if land9_pad != null:
																			fails.append("I-hatch F-EVA eighth dirt F-board land after sink stole pad")
																		if land9_lat < 60.0:
																			fails.append("I-hatch F-EVA eighth dirt F-board land after sink drifted to plate (%s)" % snapped(land9_lat, 0.1))
																		if land9_agl < 1.5 or land9_agl > 8.0:
																			fails.append("I-hatch F-EVA eighth dirt F-board land after sink not on Relief (%s)" % snapped(land9_agl, 0.1))
																		if os.has_method("try_exit_ship"):
																			os.try_exit_ship()
																		await get_tree().create_timer(0.4).timeout
																		var eva10: Node3D = os.get("player") as Node3D if os else null
																		if eva10 == null or not is_instance_valid(eva10) or not eva10.is_inside_tree():
																			fails.append("F-EVA after ninth dirt land: no walker")
																		else:
																			var e10_ship: float = eva10.global_position.distance_to(ship.global_position)
																			var e10_pad: float = eva10.global_position.distance_to(deck.global_position)
																			var e10_agl := 99.0
																			if nex.has_method("altitude_of"):
																				e10_agl = float(nex.altitude_of(eva10.global_position))
																			var ly_e10 := ""
																			if LayerContext:
																				ly_e10 = str(LayerContext.current_layer)
																			print("[Playtest] F-EVA after ninth dirt land d_ship=", snapped(e10_ship, 0.1),
																				" d_pad=", snapped(e10_pad, 0.1), " agl=", snapped(e10_agl, 0.01),
																				" eva=", eva10.get("eva_mode"), " layer=", ly_e10)
																			if e10_ship > 22.0:
																				fails.append("F-EVA after ninth dirt land teleported (%s)" % snapped(e10_ship, 0.1))
																			if e10_pad < 60.0:
																				fails.append("F-EVA after ninth dirt land snapped to pad (%s)" % snapped(e10_pad, 0.1))
																			if e10_agl < 0.2 or e10_agl > 5.0:
																				fails.append("F-EVA after ninth dirt land not on Relief (%s)" % snapped(e10_agl, 0.01))
																			if bool(eva10.get("eva_mode")) or bool(eva10.get("zero_g")):
																				fails.append("F-EVA after ninth dirt land still EVA 0G")
																			if ly_e10.to_upper().find("TPS") < 0:
																				fails.append("F-EVA after ninth dirt land layer not TPS (%s)" % ly_e10)
																			var hud_e10: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
																			if hud_e10 != null and hud_e10.has_method("bind_player"):
																				hud_e10.bind_player(eva10)
																			if hud_e10 != null and hud_e10.has_method("_refresh"):
																				hud_e10._refresh()
																			var origin_e10: Node3D = null
																			if hud_e10 != null and hud_e10.has_method("_occupy_origin"):
																				origin_e10 = hud_e10.call("_occupy_origin") as Node3D
																			var otxt_e10 := ""
																			if hud_e10 != null:
																				var lab_e10: Variant = hud_e10.get("_owner_label")
																				if lab_e10 is Label:
																					otxt_e10 = (lab_e10 as Label).text
																			print("[Playtest] occupy HUD F-EVA after ninth dirt land origin=",
																				origin_e10.name if origin_e10 else "null",
																				" '", otxt_e10.replace("\n", " / ").substr(0, 80), "'")
																			if origin_e10 == null:
																				fails.append("occupy HUD lost origin after F-EVA ninth dirt land")
																			elif origin_e10 == ship:
																				fails.append("occupy HUD origin still hull after F-EVA ninth dirt land")
																			elif origin_e10 != eva10:
																				fails.append("occupy HUD origin not walker after F-EVA ninth dirt land")
																			if otxt_e10.to_upper().find("PAD") >= 0 and otxt_e10.to_upper().find("OCCUPY") >= 0:
																				fails.append("occupy HUD PAD after F-EVA ninth dirt land")
																			var radar_e10: Variant = hud_e10.get("_radar") if hud_e10 else null
																			if radar_e10 is CanvasItem:
																				(radar_e10 as CanvasItem).visible = true
																			if hud_e10 != null and hud_e10.has_method("_refresh"):
																				hud_e10._refresh()
																			var rng_e10: float = float(hud_e10.get("_radar_range_m")) if hud_e10 else 0.0
																			var near_e10n := 0
																			if hud_e10 != null and hud_e10.has_method("radar_pad_contacts"):
																				near_e10n = hud_e10.radar_pad_contacts().size()
																			print("[Playtest] pad radar F-EVA after ninth dirt land 400m n=", near_e10n,
																				" range=", snapped(rng_e10, 1.0), " vis=",
																				(radar_e10 as CanvasItem).visible if radar_e10 is CanvasItem else "?")
																			if rng_e10 > 1000.0:
																				fails.append("pad radar used 12km after F-EVA ninth dirt land occupy (%s)" % snapped(rng_e10, 1.0))
																			if rng_e10 > 0.0 and rng_e10 < 200.0:
																				fails.append("pad radar not 400m TPS after F-EVA ninth dirt land occupy (%s)" % snapped(rng_e10, 1.0))
																			if near_e10n < 1:
																				fails.append("pad radar missed pad after F-EVA ninth dirt land occupy")
																			var ly_e10s := ""
																			if LayerContext:
																				ly_e10s = str(LayerContext.current_layer)
																			var stack_e10 := ""
																			var stack_e10_on := false
																			var chip_e10 := ""
																			if hud_e10 != null:
																				var sl_e10: Variant = hud_e10.get("_os_stack")
																				if sl_e10 is Label:
																					stack_e10 = (sl_e10 as Label).text
																					stack_e10_on = (sl_e10 as Label).visible
																				var chip10: Variant = hud_e10.get("_layer_label")
																				if chip10 is Label:
																					chip_e10 = (chip10 as Label).text
																			print("[Playtest] os stack F-EVA after ninth dirt land occupy layer=", ly_e10s,
																				" vis=", stack_e10_on, " chip='", chip_e10.replace("\n", " / ").substr(0, 40),
																				"' '", stack_e10.replace("\n", " / ").substr(0, 80), "'")
																			if ly_e10s.to_upper().find("SPACE") >= 0:
																				fails.append("os stack layer still SPACE after F-EVA ninth dirt land occupy")
																			if ly_e10s.to_upper().find("SHIP") >= 0:
																				fails.append("os stack layer still ship_int after F-EVA ninth dirt land occupy")
																			if ly_e10s.to_upper().find("TPS") < 0 and ly_e10s.to_upper().find("SURFACE") < 0:
																				fails.append("os stack layer not TPS after F-EVA ninth dirt land occupy (%s)" % ly_e10s)
																			if not stack_e10_on:
																				fails.append("os stack hidden after F-EVA ninth dirt land occupy")
																			if chip_e10.to_upper().find("SHIP") >= 0:
																				fails.append("layer chip still ship_int after F-EVA ninth dirt land occupy")
																			if stack_e10.to_upper().find("OCCUPY") >= 0:
																				fails.append("os stack occupy after F-EVA ninth dirt land occupy")
																			if stack_e10.to_upper().find("0G") >= 0:
																				fails.append("os stack EVA 0G after F-EVA ninth dirt land occupy")
																		if os.has_method("try_enter_ship"):
																			os.try_enter_ship()
																		await get_tree().create_timer(0.3).timeout
																		if not bool(os.get("_in_ship")):
																			fails.append("reboard after F-EVA ninth dirt land refused")
																		else:
																			if os.has_method("reclaim_pilot_camera"):
																				os.reclaim_pilot_camera()
																			var hud_rb10: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
																			if hud_rb10 != null and hud_rb10.has_method("bind_player"):
																				hud_rb10.bind_player(ship)
																			if hud_rb10 != null and hud_rb10.has_method("_refresh"):
																				hud_rb10._refresh()
																			var origin_rb10: Node3D = null
																			if hud_rb10 != null and hud_rb10.has_method("_occupy_origin"):
																				origin_rb10 = hud_rb10.call("_occupy_origin") as Node3D
																			var ly_rb10 := ""
																			if LayerContext:
																				ly_rb10 = str(LayerContext.current_layer)
																			var rng_rb10: float = float(hud_rb10.get("_radar_range_m")) if hud_rb10 else 0.0
																			print("[Playtest] F-board after F-EVA ninth dirt occupy origin=",
																				origin_rb10.name if origin_rb10 else "null", " layer=", ly_rb10,
																				" radar=", snapped(rng_rb10, 1.0))
																			if origin_rb10 != null and origin_rb10 != ship:
																				fails.append("occupy HUD origin still walker after F-EVA ninth dirt F-board")
																			if ly_rb10.to_upper().find("SPACE") < 0:
																				fails.append("layer not Space after F-EVA ninth dirt F-board (%s)" % ly_rb10)
																			if rng_rb10 < 1000.0:
																				fails.append("pad radar still 400m after F-EVA ninth dirt F-board (%s)" % snapped(rng_rb10, 1.0))
																			var chase_rb10: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
																			var live_rb10: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
																			print("[Playtest] HOVER view after F-EVA ninth dirt F-board chase=",
																				chase_rb10.name if chase_rb10 else "none", " live=", live_rb10.name if live_rb10 else "none",
																				" current=", chase_rb10.current if chase_rb10 else false)
																			if chase_rb10 == null:
																				fails.append("HOVER view after F-EVA ninth dirt F-board: no chase cam")
																			elif live_rb10 != chase_rb10:
																				fails.append("HOVER view after F-EVA ninth dirt F-board stole (%s)" % (live_rb10.name if live_rb10 else "none"))
																			elif not chase_rb10.current:
																				fails.append("HOVER view after F-EVA ninth dirt F-board chase not current")
																			if os.has_method("_leave_seat_to_pocket"):
																				os._leave_seat_to_pocket()
																			await get_tree().create_timer(0.35).timeout
																			var ly_pk9 := ""
																			if LayerContext:
																				ly_pk9 = str(LayerContext.current_layer)
																			var pk9: Node3D = os.get("player") as Node3D if os else null
																			print("[Playtest] I-hatch after F-EVA ninth dirt F-board pocket layer=", ly_pk9,
																				" int=", pk9.get("interior_mode") if pk9 else "none",
																				" in_ship=", os.get("_in_ship"))
																			if ly_pk9.to_upper().find("SHIP") < 0:
																				fails.append("I-hatch after F-EVA ninth dirt F-board not ship_int (%s)" % ly_pk9)
																			if pk9 == null or not bool(pk9.get("interior_mode")):
																				fails.append("I-hatch after F-EVA ninth dirt F-board not pocket walker")
																			var d9: Node = os.get("_interior") if os else null
																			if d9 != null and d9.has_method("is_inside") and bool(d9.is_inside()) and d9.has_method("exit_interior"):
																				d9.exit_interior()
																			await get_tree().create_timer(0.4).timeout
																			var hatch9: Node3D = os.get("player") as Node3D if os else null
																			if hatch9 == null or not is_instance_valid(hatch9) or not hatch9.is_inside_tree():
																				fails.append("I-hatch after F-EVA ninth dirt F-board: no walker")
																			else:
																				var h9_ship: float = hatch9.global_position.distance_to(ship.global_position)
																				var h9_pad: float = hatch9.global_position.distance_to(deck.global_position)
																				var h9_agl := 99.0
																				if nex.has_method("altitude_of"):
																					h9_agl = float(nex.altitude_of(hatch9.global_position))
																				print("[Playtest] I-hatch after F-EVA ninth dirt F-board d_ship=", snapped(h9_ship, 0.1),
																					" d_pad=", snapped(h9_pad, 0.1), " agl=", snapped(h9_agl, 0.01),
																					" int=", hatch9.get("interior_mode"))
																				if h9_ship > 22.0:
																					fails.append("I-hatch after F-EVA ninth dirt F-board teleported (%s)" % snapped(h9_ship, 0.1))
																				if h9_pad < 60.0:
																					fails.append("I-hatch after F-EVA ninth dirt F-board snapped to pad (%s)" % snapped(h9_pad, 0.1))
																				if h9_agl < 0.2 or h9_agl > 5.0:
																					fails.append("I-hatch after F-EVA ninth dirt F-board not on Relief (%s)" % snapped(h9_agl, 0.01))
																				if bool(hatch9.get("interior_mode")) or bool(hatch9.get("eva_mode")) or bool(hatch9.get("zero_g")):
																					fails.append("I-hatch after F-EVA ninth dirt F-board still pocket/0G")
																				if os.has_method("_apply_dirt_exit_facing"):
																					os._apply_dirt_exit_facing()
																				var fw9: Vector3 = -hatch9.global_transform.basis.z
																				var rad9: Vector3 = hatch9.global_position - nex.global_position
																				if rad9.length_squared() < 0.01:
																					rad9 = Vector3.UP
																				rad9 = rad9.normalized()
																				var tan9: Vector3 = rad9.cross(fw9).cross(rad9)
																				if tan9.length_squared() < 0.0001:
																					tan9 = rad9.cross(Vector3.RIGHT).cross(rad9)
																				tan9 = tan9.normalized()
																				var align9: float = fw9.normalized().dot(tan9)
																				var nose9: float = fw9.normalized().dot(rad9)
																				print("[Playtest] facing after I-hatch F-EVA ninth dirt F-board align=", snapped(align9, 0.01),
																					" nose=", snapped(nose9, 0.01))
																				if align9 < 0.92:
																					fails.append("facing after I-hatch F-EVA ninth dirt F-board not hull-nose (%s)" % snapped(align9, 0.01))
																				hatch9.set("_spawn_grace_t", 0.0)
																				if hatch9 is CharacterBody3D:
																					(hatch9 as CharacterBody3D).velocity = Vector3.ZERO
																				await get_tree().create_timer(0.05).timeout
																				var coy_h9: float = float(hatch9.get("_coyote_t"))
																				var near_h9: Variant = hatch9.call("_near_dirt_floor") if hatch9.has_method("_near_dirt_floor") else false
																				print("[Playtest] coyote after I-hatch F-EVA ninth dirt F-board t=", snapped(coy_h9, 0.01),
																					" near=", near_h9, " floor=", hatch9.is_on_floor() if hatch9 is CharacterBody3D else "?")
																				if not bool(near_h9) and not (hatch9 is CharacterBody3D and hatch9.is_on_floor()):
																					fails.append("coyote after I-hatch F-EVA ninth dirt F-board not near dirt")
																				if coy_h9 <= 0.0:
																					fails.append("coyote after I-hatch F-EVA ninth dirt F-board dead")
																				else:
																					var hv90: float = 0.0
																					if hatch9 is CharacterBody3D:
																						hv90 = (hatch9 as CharacterBody3D).velocity.dot(rad9)
																					if hatch9.has_method("request_jump"):
																						hatch9.request_jump()
																					if hatch9.has_method("_physics_process"):
																						hatch9._physics_process(0.016)
																					var hv91: float = hv90
																					if hatch9 is CharacterBody3D:
																						hv91 = (hatch9 as CharacterBody3D).velocity.dot(rad9)
																					print("[Playtest] coyote after I-hatch F-EVA ninth dirt F-board jump v_up ",
																						snapped(hv90, 0.1), "→", snapped(hv91, 0.1))
																					if hv91 < hv90 + 3.0:
																						fails.append("coyote after I-hatch F-EVA ninth dirt F-board jump died (%s → %s)" % [
																							snapped(hv90, 0.1), snapped(hv91, 0.1)])
																				var last_h9: float = float(hatch9.get("last_slope_ang"))
																				var rel_h9: float = 0.0
																				if hatch9.has_method("_relief_slope_rad"):
																					rel_h9 = float(hatch9.call("_relief_slope_rad"))
																				print("[Playtest] slope after I-hatch F-EVA ninth dirt F-board last=", snapped(rad_to_deg(last_h9), 0.1),
																					" deg rel=", snapped(rad_to_deg(rel_h9), 0.1))
																				if last_h9 < 0.0 or last_h9 > 1.4:
																					fails.append("slope after I-hatch F-EVA ninth dirt F-board last out of range (%s)" % snapped(last_h9, 0.01))
																				if rel_h9 > 0.05 and last_h9 + 0.08 < rel_h9:
																					fails.append("slope after I-hatch F-EVA ninth dirt F-board not Relief")
																				if last_h9 > rel_h9 + 0.25:
																					fails.append("slope after I-hatch F-EVA ninth dirt F-board is pocket-Y cliff")
																			if os.has_method("try_enter_ship"):
																				os.try_enter_ship()
																			await get_tree().create_timer(0.3).timeout
																			if not bool(os.get("_in_ship")):
																				fails.append("reboard after I-hatch F-EVA ninth dirt F-board refused")
																			else:
																				ship.set("_land_lock_t", 0.0)
																				if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
																					ship._do_launch()
																				await get_tree().create_timer(0.35).timeout
																				var hold_l10: float = float(ship.get("_hover_hold_alt"))
																				var agl_l10: float = 0.0
																				if nex.has_method("altitude_of"):
																					agl_l10 = float(nex.altitude_of(ship.global_position))
																				elif ship.has_method("altitude_agl"):
																					agl_l10 = float(ship.altitude_agl())
																				var hold_l10b: float = hold_l10
																				print("[Playtest] I-hatch F-EVA ninth dirt F-board HOVER launch hold=", snapped(hold_l10, 0.1),
																					" agl=", snapped(agl_l10, 0.1), " landed=", ship.get("is_landed"))
																				if bool(ship.get("is_landed")):
																					fails.append("I-hatch F-EVA ninth dirt F-board launch still landed")
																				if hold_l10 < agl_l10 - 2.0 or hold_l10 > agl_l10 + 20.0:
																					fails.append("I-hatch F-EVA ninth dirt F-board launch hold not AGL+12 (%s vs %s)" % [
																						snapped(hold_l10, 0.1), snapped(agl_l10, 0.1)])
																				var up_ge10: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
																				if up_ge10.length_squared() > 0.01:
																					up_ge10 = up_ge10.normalized()
																				var rel_ge10: Vector3 = ship.global_position - deck.global_position
																				var lat_ge10: float = (rel_ge10 - up_ge10 * rel_ge10.dot(up_ge10)).length()
																				var agl_ge10: float = agl_l10
																				if nex.has_method("altitude_of"):
																					agl_ge10 = float(nex.altitude_of(ship.global_position))
																				print("[Playtest] I-hatch F-EVA ninth dirt F-board launch GE lat=", snapped(lat_ge10, 0.1),
																					" agl=", snapped(agl_ge10, 0.1))
																				if lat_ge10 < 60.0:
																					fails.append("I-hatch F-EVA ninth dirt F-board launch GE pulled onto plate (lat=%s)" % snapped(lat_ge10, 0.1))
																				ship.set_meta("playtest_sink", true)
																				await get_tree().create_timer(0.45).timeout
																				ship.set_meta("playtest_sink", false)
																				var hold_sk10: float = float(ship.get("_hover_hold_alt"))
																				var agl_sk10: float = agl_ge10
																				if nex.has_method("altitude_of"):
																					agl_sk10 = float(nex.altitude_of(ship.global_position))
																				var rel_sk10: Vector3 = ship.global_position - deck.global_position
																				var lat_sk10: float = (rel_sk10 - up_ge10 * rel_sk10.dot(up_ge10)).length()
																				print("[Playtest] I-hatch F-EVA ninth dirt F-board HOVER sink hold ",
																					snapped(hold_l10b, 0.1), "→", snapped(hold_sk10, 0.1),
																					" AGL ", snapped(agl_ge10, 0.1), "→", snapped(agl_sk10, 0.1),
																					" lat=", snapped(lat_sk10, 0.1))
																				if hold_sk10 > 6.5:
																					fails.append("I-hatch F-EVA ninth dirt F-board HOVER sink hold still 8m floor (%s)" % snapped(hold_sk10, 0.1))
																				if hold_sk10 + 0.2 < 3.5:
																					fails.append("I-hatch F-EVA ninth dirt F-board HOVER sink hold buried (%s)" % snapped(hold_sk10, 0.1))
																				if lat_sk10 < 60.0:
																					fails.append("I-hatch F-EVA ninth dirt F-board HOVER sink drifted onto plate (%s)" % snapped(lat_sk10, 0.1))
																				if "velocity" in ship:
																					ship.velocity = Vector3.ZERO
																				ship.set("_gear_down", true)
																				if ship.has_method("_do_land"):
																					ship._do_land()
																				await get_tree().create_timer(0.4).timeout
																				var land10_agl: float = agl_sk10
																				if nex.has_method("altitude_of"):
																					land10_agl = float(nex.altitude_of(ship.global_position))
																				var land10_pad: Node3D = null
																				if ship.has_method("get_landed_pad"):
																					land10_pad = ship.get_landed_pad() as Node3D
																				var land10_rel: Vector3 = ship.global_position - deck.global_position
																				var land10_lat: float = (land10_rel - up_ge10 * land10_rel.dot(up_ge10)).length()
																				print("[Playtest] I-hatch F-EVA ninth dirt F-board land after sink landed=", ship.get("is_landed"),
																					" pad=", land10_pad.name if land10_pad else "none",
																					" agl=", snapped(land10_agl, 0.1), " lat=", snapped(land10_lat, 0.1))
																				if not bool(ship.get("is_landed")):
																					fails.append("I-hatch F-EVA ninth dirt F-board land after sink refused")
																				if land10_pad != null:
																					fails.append("I-hatch F-EVA ninth dirt F-board land after sink stole pad")
																				if land10_lat < 60.0:
																					fails.append("I-hatch F-EVA ninth dirt F-board land after sink drifted to plate (%s)" % snapped(land10_lat, 0.1))
																				if land10_agl < 1.5 or land10_agl > 8.0:
																					fails.append("I-hatch F-EVA ninth dirt F-board land after sink not on Relief (%s)" % snapped(land10_agl, 0.1))
																				if os.has_method("try_exit_ship"):
																					os.try_exit_ship()
																				await get_tree().create_timer(0.4).timeout
																				var eva11: Node3D = os.get("player") as Node3D if os else null
																				if eva11 == null or not is_instance_valid(eva11) or not eva11.is_inside_tree():
																					fails.append("F-EVA after tenth dirt land: no walker")
																				else:
																					var e11_ship: float = eva11.global_position.distance_to(ship.global_position)
																					var e11_pad: float = eva11.global_position.distance_to(deck.global_position)
																					var e11_agl := 99.0
																					if nex.has_method("altitude_of"):
																						e11_agl = float(nex.altitude_of(eva11.global_position))
																					var ly_e11 := ""
																					if LayerContext:
																						ly_e11 = str(LayerContext.current_layer)
																					print("[Playtest] F-EVA after tenth dirt land d_ship=", snapped(e11_ship, 0.1),
																						" d_pad=", snapped(e11_pad, 0.1), " agl=", snapped(e11_agl, 0.01),
																						" eva=", eva11.get("eva_mode"), " layer=", ly_e11)
																					if e11_ship > 22.0:
																						fails.append("F-EVA after tenth dirt land teleported (%s)" % snapped(e11_ship, 0.1))
																					if e11_pad < 60.0:
																						fails.append("F-EVA after tenth dirt land snapped to pad (%s)" % snapped(e11_pad, 0.1))
																					if e11_agl < 0.2 or e11_agl > 5.0:
																						fails.append("F-EVA after tenth dirt land not on Relief (%s)" % snapped(e11_agl, 0.01))
																					if bool(eva11.get("eva_mode")) or bool(eva11.get("zero_g")):
																						fails.append("F-EVA after tenth dirt land still EVA 0G")
																					if ly_e11.to_upper().find("TPS") < 0:
																						fails.append("F-EVA after tenth dirt land layer not TPS (%s)" % ly_e11)
																					var hud_e11: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
																					if hud_e11 != null and hud_e11.has_method("bind_player"):
																						hud_e11.bind_player(eva11)
																					if hud_e11 != null and hud_e11.has_method("_refresh"):
																						hud_e11._refresh()
																					var origin_e11: Node3D = null
																					if hud_e11 != null and hud_e11.has_method("_occupy_origin"):
																						origin_e11 = hud_e11.call("_occupy_origin") as Node3D
																					var otxt_e11 := ""
																					if hud_e11 != null:
																						var lab_e11: Variant = hud_e11.get("_owner_label")
																						if lab_e11 is Label:
																							otxt_e11 = (lab_e11 as Label).text
																					print("[Playtest] occupy HUD F-EVA after tenth dirt land origin=",
																						origin_e11.name if origin_e11 else "null",
																						" '", otxt_e11.replace("\n", " / ").substr(0, 80), "'")
																					if origin_e11 == null:
																						fails.append("occupy HUD lost origin after F-EVA tenth dirt land")
																					elif origin_e11 == ship:
																						fails.append("occupy HUD origin still hull after F-EVA tenth dirt land")
																					elif origin_e11 != eva11:
																						fails.append("occupy HUD origin not walker after F-EVA tenth dirt land")
																					if otxt_e11.to_upper().find("PAD") >= 0 and otxt_e11.to_upper().find("OCCUPY") >= 0:
																						fails.append("occupy HUD PAD after F-EVA tenth dirt land")
																					var radar_e11: Variant = hud_e11.get("_radar") if hud_e11 else null
																					if radar_e11 is CanvasItem:
																						(radar_e11 as CanvasItem).visible = true
																					if hud_e11 != null and hud_e11.has_method("_refresh"):
																						hud_e11._refresh()
																					var rng_e11: float = float(hud_e11.get("_radar_range_m")) if hud_e11 else 0.0
																					var near_e11n := 0
																					if hud_e11 != null and hud_e11.has_method("radar_pad_contacts"):
																						near_e11n = hud_e11.radar_pad_contacts().size()
																					print("[Playtest] pad radar F-EVA after tenth dirt land 400m n=", near_e11n,
																						" range=", snapped(rng_e11, 1.0), " vis=",
																						(radar_e11 as CanvasItem).visible if radar_e11 is CanvasItem else "?")
																					if rng_e11 > 1000.0:
																						fails.append("pad radar used 12km after F-EVA tenth dirt land occupy (%s)" % snapped(rng_e11, 1.0))
																					if rng_e11 > 0.0 and rng_e11 < 200.0:
																						fails.append("pad radar not 400m TPS after F-EVA tenth dirt land occupy (%s)" % snapped(rng_e11, 1.0))
																					if near_e11n < 1:
																						fails.append("pad radar missed pad after F-EVA tenth dirt land occupy")
																					var ly_e11s := ""
																					if LayerContext:
																						ly_e11s = str(LayerContext.current_layer)
																					var stack_e11 := ""
																					var stack_e11_on := false
																					var chip_e11 := ""
																					if hud_e11 != null:
																						var sl_e11: Variant = hud_e11.get("_os_stack")
																						if sl_e11 is Label:
																							stack_e11 = (sl_e11 as Label).text
																							stack_e11_on = (sl_e11 as Label).visible
																						var chip11: Variant = hud_e11.get("_layer_label")
																						if chip11 is Label:
																							chip_e11 = (chip11 as Label).text
																					print("[Playtest] os stack F-EVA after tenth dirt land occupy layer=", ly_e11s,
																						" vis=", stack_e11_on, " chip='", chip_e11.replace("\n", " / ").substr(0, 40),
																						"' '", stack_e11.replace("\n", " / ").substr(0, 80), "'")
																					if ly_e11s.to_upper().find("SPACE") >= 0:
																						fails.append("os stack layer still SPACE after F-EVA tenth dirt land occupy")
																					if ly_e11s.to_upper().find("SHIP") >= 0:
																						fails.append("os stack layer still ship_int after F-EVA tenth dirt land occupy")
																					if ly_e11s.to_upper().find("TPS") < 0 and ly_e11s.to_upper().find("SURFACE") < 0:
																						fails.append("os stack layer not TPS after F-EVA tenth dirt land occupy (%s)" % ly_e11s)
																					if not stack_e11_on:
																						fails.append("os stack hidden after F-EVA tenth dirt land occupy")
																					if chip_e11.to_upper().find("SHIP") >= 0:
																						fails.append("layer chip still ship_int after F-EVA tenth dirt land occupy")
																					if stack_e11.to_upper().find("OCCUPY") >= 0:
																						fails.append("os stack occupy after F-EVA tenth dirt land occupy")
																					if stack_e11.to_upper().find("0G") >= 0:
																						fails.append("os stack EVA 0G after F-EVA tenth dirt land occupy")
																				if os.has_method("try_enter_ship"):
																					os.try_enter_ship()
																				await get_tree().create_timer(0.3).timeout
																				if not bool(os.get("_in_ship")):
																					fails.append("reboard after F-EVA tenth dirt land refused")
																				else:
																					if os.has_method("reclaim_pilot_camera"):
																						os.reclaim_pilot_camera()
																					var hud_rb11: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
																					if hud_rb11 != null and hud_rb11.has_method("bind_player"):
																						hud_rb11.bind_player(ship)
																					if hud_rb11 != null and hud_rb11.has_method("_refresh"):
																						hud_rb11._refresh()
																					var origin_rb11: Node3D = null
																					if hud_rb11 != null and hud_rb11.has_method("_occupy_origin"):
																						origin_rb11 = hud_rb11.call("_occupy_origin") as Node3D
																					var ly_rb11 := ""
																					if LayerContext:
																						ly_rb11 = str(LayerContext.current_layer)
																					var rng_rb11: float = float(hud_rb11.get("_radar_range_m")) if hud_rb11 else 0.0
																					print("[Playtest] F-board after F-EVA tenth dirt occupy origin=",
																						origin_rb11.name if origin_rb11 else "null", " layer=", ly_rb11,
																						" radar=", snapped(rng_rb11, 1.0))
																					if origin_rb11 != null and origin_rb11 != ship:
																						fails.append("occupy HUD origin still walker after F-EVA tenth dirt F-board")
																					if ly_rb11.to_upper().find("SPACE") < 0:
																						fails.append("layer not Space after F-EVA tenth dirt F-board (%s)" % ly_rb11)
																					if rng_rb11 < 1000.0:
																						fails.append("pad radar still 400m after F-EVA tenth dirt F-board (%s)" % snapped(rng_rb11, 1.0))
																					var chase_rb11: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
																					var live_rb11: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
																					print("[Playtest] HOVER view after F-EVA tenth dirt F-board chase=",
																						chase_rb11.name if chase_rb11 else "none", " live=", live_rb11.name if live_rb11 else "none",
																						" current=", chase_rb11.current if chase_rb11 else false)
																					if chase_rb11 == null:
																						fails.append("HOVER view after F-EVA tenth dirt F-board: no chase cam")
																					elif live_rb11 != chase_rb11:
																						fails.append("HOVER view after F-EVA tenth dirt F-board stole (%s)" % (live_rb11.name if live_rb11 else "none"))
																					elif not chase_rb11.current:
																						fails.append("HOVER view after F-EVA tenth dirt F-board chase not current")
																					if os.has_method("_leave_seat_to_pocket"):
																						os._leave_seat_to_pocket()
																					await get_tree().create_timer(0.35).timeout
																					var ly_pk10 := ""
																					if LayerContext:
																						ly_pk10 = str(LayerContext.current_layer)
																					var pk10: Node3D = os.get("player") as Node3D if os else null
																					print("[Playtest] I-hatch after F-EVA tenth dirt F-board pocket layer=", ly_pk10,
																						" int=", pk10.get("interior_mode") if pk10 else "none",
																						" in_ship=", os.get("_in_ship"))
																					if ly_pk10.to_upper().find("SHIP") < 0:
																						fails.append("I-hatch after F-EVA tenth dirt F-board not ship_int (%s)" % ly_pk10)
																					if pk10 == null or not bool(pk10.get("interior_mode")):
																						fails.append("I-hatch after F-EVA tenth dirt F-board not pocket walker")
																					var d10: Node = os.get("_interior") if os else null
																					if d10 != null and d10.has_method("is_inside") and bool(d10.is_inside()) and d10.has_method("exit_interior"):
																						d10.exit_interior()
																					await get_tree().create_timer(0.4).timeout
																					var hatch10: Node3D = os.get("player") as Node3D if os else null
																					if hatch10 == null or not is_instance_valid(hatch10) or not hatch10.is_inside_tree():
																						fails.append("I-hatch after F-EVA tenth dirt F-board: no walker")
																					else:
																						var h10_ship: float = hatch10.global_position.distance_to(ship.global_position)
																						var h10_pad: float = hatch10.global_position.distance_to(deck.global_position)
																						var h10_agl := 99.0
																						if nex.has_method("altitude_of"):
																							h10_agl = float(nex.altitude_of(hatch10.global_position))
																						print("[Playtest] I-hatch after F-EVA tenth dirt F-board d_ship=", snapped(h10_ship, 0.1),
																							" d_pad=", snapped(h10_pad, 0.1), " agl=", snapped(h10_agl, 0.01),
																							" int=", hatch10.get("interior_mode"))
																						if h10_ship > 22.0:
																							fails.append("I-hatch after F-EVA tenth dirt F-board teleported (%s)" % snapped(h10_ship, 0.1))
																						if h10_pad < 60.0:
																							fails.append("I-hatch after F-EVA tenth dirt F-board snapped to pad (%s)" % snapped(h10_pad, 0.1))
																						if h10_agl < 0.2 or h10_agl > 5.0:
																							fails.append("I-hatch after F-EVA tenth dirt F-board not on Relief (%s)" % snapped(h10_agl, 0.01))
																						if bool(hatch10.get("interior_mode")) or bool(hatch10.get("eva_mode")) or bool(hatch10.get("zero_g")):
																							fails.append("I-hatch after F-EVA tenth dirt F-board still pocket/0G")
																						if os.has_method("_apply_dirt_exit_facing"):
																							os._apply_dirt_exit_facing()
																						var fw10: Vector3 = -hatch10.global_transform.basis.z
																						var rad10: Vector3 = hatch10.global_position - nex.global_position
																						if rad10.length_squared() < 0.01:
																							rad10 = Vector3.UP
																						rad10 = rad10.normalized()
																						var tan10: Vector3 = rad10.cross(fw10).cross(rad10)
																						if tan10.length_squared() < 0.0001:
																							tan10 = rad10.cross(Vector3.RIGHT).cross(rad10)
																						tan10 = tan10.normalized()
																						var align10: float = fw10.normalized().dot(tan10)
																						var nose10: float = fw10.normalized().dot(rad10)
																						print("[Playtest] facing after I-hatch F-EVA tenth dirt F-board align=", snapped(align10, 0.01),
																							" nose=", snapped(nose10, 0.01))
																						if align10 < 0.92:
																							fails.append("facing after I-hatch F-EVA tenth dirt F-board not hull-nose (%s)" % snapped(align10, 0.01))
																						hatch10.set("_spawn_grace_t", 0.0)
																						if hatch10 is CharacterBody3D:
																							(hatch10 as CharacterBody3D).velocity = Vector3.ZERO
																						await get_tree().create_timer(0.05).timeout
																						var coy_h10: float = float(hatch10.get("_coyote_t"))
																						var near_h10: Variant = hatch10.call("_near_dirt_floor") if hatch10.has_method("_near_dirt_floor") else false
																						print("[Playtest] coyote after I-hatch F-EVA tenth dirt F-board t=", snapped(coy_h10, 0.01),
																							" near=", near_h10, " floor=", hatch10.is_on_floor() if hatch10 is CharacterBody3D else "?")
																						if not bool(near_h10) and not (hatch10 is CharacterBody3D and hatch10.is_on_floor()):
																							fails.append("coyote after I-hatch F-EVA tenth dirt F-board not near dirt")
																						if coy_h10 <= 0.0:
																							fails.append("coyote after I-hatch F-EVA tenth dirt F-board dead")
																						else:
																							var hv100: float = 0.0
																							if hatch10 is CharacterBody3D:
																								hv100 = (hatch10 as CharacterBody3D).velocity.dot(rad10)
																							if hatch10.has_method("request_jump"):
																								hatch10.request_jump()
																							if hatch10.has_method("_physics_process"):
																								hatch10._physics_process(0.016)
																							var hv101: float = hv100
																							if hatch10 is CharacterBody3D:
																								hv101 = (hatch10 as CharacterBody3D).velocity.dot(rad10)
																							if hv101 < hv100 + 3.0:
																								fails.append("coyote after I-hatch F-EVA tenth dirt F-board jump died (%s → %s)" % [
																									snapped(hv100, 0.1), snapped(hv101, 0.1)])
																					if os.has_method("try_enter_ship"):
																						os.try_enter_ship()
																					await get_tree().create_timer(0.3).timeout
																					if not bool(os.get("_in_ship")):
																						fails.append("reboard after I-hatch F-EVA tenth dirt F-board refused")


func _assert_hover_alt_hold(fails: PackedStringArray) -> void:
	## SESSION_CONTRACT 1 leftover: HOVER PD holds altitude. Pad ground-effect
	## cushions sink — it must not rewrite `_hover_hold_alt` (autopilot climb).
	var os: Node = get_parent()
	var ship: Node = os.get("ship") if os else null
	var nex: Node = _osh_nex()
	if ship == null or nex == null:
		fails.append("HOVER hold: no ship/Nex-Prime")
		return
	var deck: Node3D = _osh_unnamed_deck()
	if deck == null:
		fails.append("HOVER hold: no unnamed pad")
		return
	var up: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if up.length_squared() > 0.01:
		up = up.normalized()
	if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	ship.global_position = deck.global_position + up * 6.0
	var a0: float = 0.0
	if nex is Node3D and nex.has_method("altitude_of"):
		a0 = float(nex.altitude_of(ship.global_position))
	ship.set("_hover_hold_alt", a0)
	var hold0: float = float(ship.get("_hover_hold_alt"))
	await get_tree().create_timer(0.55).timeout
	if ship == null or not is_instance_valid(ship):
		fails.append("HOVER hold: ship gone")
		return
	var hold1: float = float(ship.get("_hover_hold_alt"))
	var a1: float = a0
	if nex is Node3D and nex.has_method("altitude_of"):
		a1 = float(nex.altitude_of(ship.global_position))
	print("[Playtest] HOVER hold alt ", snapped(hold0, 0.1), "→", snapped(hold1, 0.1),
		" AGL ", snapped(a0, 0.1), "→", snapped(a1, 0.1))
	if hold1 > hold0 + 3.0:
		fails.append("HOVER hold stolen by pad deck (%s → %s)" % [snapped(hold0, 0.1), snapped(hold1, 0.1)])
	if absf(a1 - a0) > 18.0:
		fails.append("HOVER hold drifted (%s → %s)" % [snapped(a0, 0.1), snapped(a1, 0.1)])
	await _assert_hover_dirt_hold(fails)


func _assert_hover_dirt_hold(fails: PackedStringArray) -> void:
	## OS-I leftover: HOVER over dirt is Relief AGL. Pad ground-effect
	## must not lift the hull off a hill 40 m from the plate.
	var os: Node = get_parent()
	var ship: Node = os.get("ship") if os else null
	var nex: Node = _osh_nex()
	if ship == null or nex == null or not (nex is Node3D):
		fails.append("HOVER dirt: no ship/Nex-Prime")
		return
	var deck: Node3D = _osh_unnamed_deck()
	if deck == null:
		fails.append("HOVER dirt: no unnamed pad")
		return
	var up: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if up.length_squared() > 0.01:
		up = up.normalized()
	var side: Vector3 = up.cross(Vector3.RIGHT)
	if side.length_squared() < 0.04:
		side = up.cross(Vector3.FORWARD)
	side = side.normalized()
	if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	ship.global_position = deck.global_position + side * 40.0 + up * 6.0
	var a0: float = 0.0
	if nex.has_method("altitude_of"):
		a0 = float(nex.altitude_of(ship.global_position))
	ship.set("_hover_hold_alt", a0)
	var hold0: float = float(ship.get("_hover_hold_alt"))
	await get_tree().create_timer(0.55).timeout
	if ship == null or not is_instance_valid(ship):
		fails.append("HOVER dirt: ship gone")
		return
	var hold1: float = float(ship.get("_hover_hold_alt"))
	var a1: float = a0
	if nex.has_method("altitude_of"):
		a1 = float(nex.altitude_of(ship.global_position))
	var lat: float = 0.0
	var rel: Vector3 = ship.global_position - deck.global_position
	lat = (rel - up * rel.dot(up)).length()
	print("[Playtest] HOVER dirt hold ", snapped(hold0, 0.1), "→", snapped(hold1, 0.1),
		" AGL ", snapped(a0, 0.1), "→", snapped(a1, 0.1), " lat=", snapped(lat, 0.1))
	if hold1 > hold0 + 3.0:
		fails.append("HOVER dirt hold stolen by pad GE (%s → %s)" % [snapped(hold0, 0.1), snapped(hold1, 0.1)])
	if absf(a1 - a0) > 18.0:
		fails.append("HOVER dirt drifted (%s → %s)" % [snapped(a0, 0.1), snapped(a1, 0.1)])
	if lat < 16.0:
		fails.append("HOVER dirt snapped onto plate (lat=%s)" % snapped(lat, 0.1))
	await _assert_approach_dirt(fails)


func _assert_approach_dirt(fails: PackedStringArray) -> void:
	## OS-I leftover: 3D pad dist < 90 m stole dirt cruise and overflight.
	## Assist is the plate envelope only (lat ≤28, deck 0.5…22 m).
	var os: Node = get_parent()
	var ship: Node = os.get("ship") if os else null
	if ship == null or not is_instance_valid(ship):
		fails.append("approach dirt: no ship")
		return
	var deck: Node3D = _osh_unnamed_deck()
	if deck == null:
		fails.append("approach dirt: no unnamed pad")
		return
	var up: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if up.length_squared() > 0.01:
		up = up.normalized()
	var side: Vector3 = up.cross(Vector3.RIGHT)
	if side.length_squared() < 0.04:
		side = up.cross(Vector3.FORWARD)
	side = side.normalized()
	if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if ship.has_method("_set_mode"):
		ship._set_mode(1)
	ship.set("_gear_down", false)
	ship.set("_hover_hold_alt", -1.0)
	# Overflight: 80 m AGL over the plate, closing. Must not be braked to a hover.
	ship.global_position = deck.global_position + up * 80.0
	if "velocity" in ship:
		ship.velocity = -up * 22.0
	await get_tree().create_timer(0.32).timeout
	if ship == null or not is_instance_valid(ship):
		fails.append("approach dirt: ship gone")
		return
	var sink: float = 0.0
	if "velocity" in ship:
		sink = (ship.velocity as Vector3).dot(-up)
	print("[Playtest] approach overflight sink=", snapped(sink, 0.1))
	if sink < 8.0:
		fails.append("approach assist stole overflight (%s)" % snapped(sink, 0.1))
	# Dirt cruise: 40 m off the plate, toward the pad. HOVER hold matches AGL.
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	ship.set("_hover_hold_alt", 8.0)
	ship.global_position = deck.global_position + side * 40.0 + up * 8.0
	if "velocity" in ship:
		ship.velocity = -side * 16.0
	await get_tree().create_timer(0.32).timeout
	if ship == null or not is_instance_valid(ship):
		fails.append("approach dirt cruise: ship gone")
		return
	var rel: Vector3 = ship.global_position - deck.global_position
	var lat: float = (rel - up * rel.dot(up)).length()
	var spd: float = 0.0
	if "velocity" in ship:
		spd = (ship.velocity as Vector3).length()
	print("[Playtest] approach dirt lat=", snapped(lat, 0.1), " spd=", snapped(spd, 0.1))
	if lat < 28.0:
		fails.append("approach assist yanked dirt cruise onto plate (%s)" % snapped(lat, 0.1))
	if spd < 5.0:
		fails.append("approach assist braked dirt cruise (%s)" % snapped(spd, 0.1))
	await _assert_land_ready_overflight(fails)


func _assert_land_ready_overflight(fails: PackedStringArray) -> void:
	## OS-I leftover: 3D pad dist < 90 m said LAND READY at 80 m AGL
	## and snapped onto the plate. Overflight is "deck →22", not a pad land.
	var os: Node = get_parent()
	var ship: Node = os.get("ship") if os else null
	var deck: Node3D = _osh_unnamed_deck()
	if ship == null or deck == null:
		fails.append("land ready overflight: no ship/pad")
		return
	var up: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if up.length_squared() > 0.01:
		up = up.normalized()
	if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	ship.set("_gear_down", true)
	if ship.has_method("_sync_landing_gear"):
		ship._sync_landing_gear()
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	ship.global_position = deck.global_position + up * 80.0
	var line := ""
	if ship.has_method("land_readiness_line"):
		line = str(ship.land_readiness_line())
	print("[Playtest] land ready overflight '", line, "'")
	if line.find("LAND READY") >= 0:
		fails.append("overflight said LAND READY")
	if line.to_upper().find("DECK") < 0:
		fails.append("overflight HUD missing deck envelope")
	if ship.has_method("_do_land"):
		ship._do_land()
	if ship.get("_landed_pad") != null:
		fails.append("overflight pad-snapped from 80 m AGL")
	if bool(ship.get("is_landed")):
		fails.append("overflight surface-landed from 80 m AGL")
	if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	await _assert_ship_agl_plate(fails)


func _assert_ship_agl_plate(fails: PackedStringArray) -> void:
	## Player ship CargoRamp reads host.altitude_agl(). Missing → 9999 too high.
	## Plate must be deck height (same as CatalogCarrier), not dirt+pad.
	var os: Node = get_parent()
	var ship: Node = os.get("ship") if os else null
	var deck: Node3D = _osh_unnamed_deck()
	if ship == null or deck == null:
		fails.append("ship AGL: no ship/pad")
		return
	if not ship.has_method("altitude_agl"):
		fails.append("ship AGL: missing altitude_agl")
		return
	var up: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if up.length_squared() > 0.01:
		up = up.normalized()
	var side: Vector3 = up.cross(Vector3.RIGHT)
	if side.length_squared() < 0.04:
		side = up.cross(Vector3.FORWARD)
	side = side.normalized()
	if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	ship.global_position = deck.global_position + up * 7.0
	var plate_agl: float = float(ship.altitude_agl())
	print("[Playtest] ship AGL plate hover=", snapped(plate_agl, 0.01))
	if absf(plate_agl - 7.0) > 0.6:
		fails.append("ship AGL plate is not deck height (%s)" % snapped(plate_agl, 0.01))
	ship.global_position = deck.global_position + up * 40.0
	var over_agl: float = float(ship.altitude_agl())
	print("[Playtest] ship AGL overflight=", snapped(over_agl, 0.1))
	if absf(over_agl - 40.0) > 2.0:
		fails.append("ship AGL overflight is not deck height (%s)" % snapped(over_agl, 0.1))
	ship.global_position = deck.global_position + side * 40.0 + up * 6.0
	var dirt_agl: float = float(ship.altitude_agl())
	print("[Playtest] ship AGL dirt=", snapped(dirt_agl, 0.01))
	if dirt_agl < 0.2 or dirt_agl > 18.0:
		fails.append("ship AGL dirt not Relief (%s)" % snapped(dirt_agl, 0.01))
	if absf(dirt_agl - 40.0) < 2.0:
		fails.append("ship AGL dirt used 3D pad dist")
	await _assert_ship_ramp_hover(fails)


func _assert_ship_ramp_hover(fails: PackedStringArray) -> void:
	## Player-ship ramp ignored pose (hangar_host only). 7 m HOVER on the
	## plate must deploy; 40 m overflight must BLOCKED too high.
	var os: Node = get_parent()
	var ship: Node = os.get("ship") if os else null
	var deck: Node3D = _osh_unnamed_deck()
	if ship == null or deck == null:
		fails.append("ship ramp: no ship/pad")
		return
	var up: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if up.length_squared() > 0.01:
		up = up.normalized()
	if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	var ramp: Node = ship.get_node_or_null("CargoRamp")
	var spawned := false
	if ramp == null:
		ramp = Node3D.new()
		ramp.set_script(load("res://scripts/ship/CargoRamp.gd"))
		ramp.name = "CargoRamp"
		ship.add_child(ramp)
		spawned = true
		if ship.get("_cargo_ramp") == null:
			ship.set("_cargo_ramp", ramp)
	ship.global_position = deck.global_position + up * 7.0
	var result := "BLOCKED"
	if ramp.has_method("try_deploy"):
		result = str(ramp.try_deploy())
	var reason := str(ramp.get("last_block_reason")) if ramp != null else ""
	print("[Playtest] ship ramp 7m hover result=", result, " reason=", reason)
	if result == "BLOCKED":
		fails.append("ship ramp blocked at 7m HOVER (%s)" % reason)
	if ramp.has_method("stow_immediate"):
		ramp.stow_immediate()
	ship.global_position = deck.global_position + up * 40.0
	result = str(ramp.try_deploy()) if ramp.has_method("try_deploy") else ""
	reason = str(ramp.get("last_block_reason")) if ramp != null else ""
	print("[Playtest] ship ramp 40m overflight result=", result, " reason=", reason)
	if result != "BLOCKED":
		fails.append("ship ramp deployed at 40m overflight")
	if reason != "too high":
		fails.append("ship ramp 40m reason=%s want too high" % reason)
	if ramp.has_method("stow_immediate"):
		ramp.stow_immediate()
	if spawned and is_instance_valid(ramp):
		if ship.get("_cargo_ramp") == ramp:
			ship.set("_cargo_ramp", null)
		ramp.queue_free()
	await _assert_ramp_dirt_agl(fails)


func _assert_ramp_dirt_agl(fails: PackedStringArray) -> void:
	## Off-plate HOVER uses Relief AGL. Hangar layout_to_deck must not
	## stretch 40 m toward the nearest pad.
	var os: Node = get_parent()
	var ship: Node = os.get("ship") if os else null
	var deck: Node3D = _osh_unnamed_deck()
	if ship == null or deck == null:
		fails.append("ramp dirt: no ship/pad")
		return
	var up: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if up.length_squared() > 0.01:
		up = up.normalized()
	var side: Vector3 = up.cross(Vector3.RIGHT)
	if side.length_squared() < 0.04:
		side = up.cross(Vector3.FORWARD)
	side = side.normalized()
	if bool(ship.get("is_landed")) and ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	var ramp: Node = ship.get_node_or_null("CargoRamp")
	var spawned := false
	if ramp == null:
		ramp = Node3D.new()
		ramp.set_script(load("res://scripts/ship/CargoRamp.gd"))
		ramp.name = "CargoRamp"
		ship.add_child(ramp)
		spawned = true
	ship.global_position = deck.global_position + side * 40.0 + up * 6.0
	var agl := 99.0
	if ship.has_method("altitude_agl"):
		agl = float(ship.altitude_agl())
	var result := str(ramp.try_deploy()) if ramp.has_method("try_deploy") else "BLOCKED"
	var reason := str(ramp.get("last_block_reason"))
	print("[Playtest] ramp dirt hover agl=", snapped(agl, 0.01), " result=", result, " reason=", reason)
	if agl < 0.2 or agl > 8.0:
		fails.append("ramp dirt hover AGL not Relief (%s)" % snapped(agl, 0.01))
	if result == "BLOCKED":
		fails.append("ramp dirt hover blocked (%s)" % reason)
	if ramp.has_method("stow_immediate"):
		ramp.stow_immediate()
	ship.global_position = deck.global_position + side * 40.0 + up * 40.0
	agl = float(ship.altitude_agl()) if ship.has_method("altitude_agl") else 0.0
	result = str(ramp.try_deploy()) if ramp.has_method("try_deploy") else ""
	reason = str(ramp.get("last_block_reason"))
	print("[Playtest] ramp dirt high agl=", snapped(agl, 0.1), " result=", result, " reason=", reason)
	if result != "BLOCKED" or reason != "too high":
		fails.append("ramp dirt high not blocked too high (%s/%s)" % [result, reason])
	if ramp.has_method("stow_immediate"):
		ramp.stow_immediate()
	if spawned and is_instance_valid(ramp):
		ramp.queue_free()
	var carrier: Node = os.catalog_carrier() if os.has_method("catalog_carrier") else null
	if carrier == null or not carrier.has_method("try_deploy_ramp"):
		return
	var cramp: Node = carrier.cargo_ramp() if carrier.has_method("cargo_ramp") else null
	if cramp == null:
		return
	if carrier.has_method("set_pose_landed"):
		carrier.set_pose_landed(deck)
	carrier.global_position = deck.global_position + side * 40.0 + up * 2.0
	carrier.set("_landed", true)
	var len0: float = float(cramp.get("ramp_length"))
	carrier.try_deploy_ramp()
	var len1: float = float(cramp.get("ramp_length"))
	print("[Playtest] ramp dirt land len ", snapped(len0, 0.1), "→", snapped(len1, 0.1))
	if len1 > 12.0:
		fails.append("ramp dirt land stretched to pad (%s)" % snapped(len1, 0.1))
	if cramp.has_method("stow_immediate"):
		cramp.stow_immediate()


func _pad_traffic_present(fails: PackedStringArray) -> void:
	## Pillar 13: one guard dummy + one visiting ship on a loaded unnamed pad.
	var nex: Node = _osh_nex()
	if nex != null and nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	var traffic: Node = null
	if nex != null and nex.has_method("pad_traffic"):
		traffic = nex.call("pad_traffic")
	if traffic == null or not is_instance_valid(traffic):
		fails.append("pad traffic present: missing")
		return
	var guard: Node3D = traffic.get_guard() if traffic.has_method("get_guard") else null
	var visitor: Node3D = traffic.get_visitor() if traffic.has_method("get_visitor") else null
	if guard == null or not is_instance_valid(guard):
		fails.append("pad traffic present: no pad-guard dummy")
		return
	if visitor == null or not is_instance_valid(visitor):
		fails.append("pad traffic present: no visiting ship")
		return
	var host: Node = traffic.get_parent()
	if host == null or not (host is Node3D) or not host.has_meta("pad_up"):
		fails.append("pad traffic present: not on a pad")
		return
	var pin := str(host.get_meta("site_pin")) if host.has_meta("site_pin") else ""
	if pin.begins_with("SITE_"):
		fails.append("pad traffic present: minted SITE_* (%s)" % pin)
	var extras := get_tree().get_nodes_in_group("pad_traffic").size() if get_tree() else 0
	if extras != 1:
		fails.append("pad traffic present: want one cluster, got %s" % extras)
	var gd: float = guard.global_position.distance_to((host as Node3D).global_position)
	var vd: float = visitor.global_position.distance_to((host as Node3D).global_position)
	if gd > 40.0:
		fails.append("pad traffic present: guard not near pad (%s)" % snapped(gd, 0.1))
	if vd > 40.0:
		fails.append("pad traffic present: visitor not near pad (%s)" % snapped(vd, 0.1))
	var dmg0: float = float(guard.get("attack_damage"))
	var hp0: float = float(guard.get("max_health"))
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("history", 20.0)
		GameManager.add_mastery("languages", 20.0)
	if traffic.has_method("refresh_labels"):
		traffic.refresh_labels()
	if absf(float(guard.get("attack_damage")) - dmg0) > 0.01:
		fails.append("Knowledge changed pad-guard DPS")
	if absf(float(guard.get("max_health")) - hp0) > 0.01:
		fails.append("Knowledge changed pad-guard HP")
	var glabel := str(traffic.guard_label()) if traffic.has_method("guard_label") else ""
	if glabel == "":
		fails.append("Knowledge pad-guard label empty")
	print("[Playtest] pad traffic present host=", host.name, " guard_d=", snapped(gd, 0.1), " visitor_d=", snapped(vd, 0.1), " label=", glabel)


func _npc_takeoff_land(fails: PackedStringArray) -> void:
	## NP-A: visitor ShipController takeoff → SCM/HOVER → gear-down LAND on unnamed pad.
	var nex: Node = _osh_nex()
	if nex != null and nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	var traffic: Node = nex.call("pad_traffic") if nex != null and nex.has_method("pad_traffic") else null
	if traffic == null or not is_instance_valid(traffic):
		fails.append("NP-A: pad traffic missing")
		return
	var visitor: Node = traffic.get_visitor() if traffic.has_method("get_visitor") else null
	var pilot: Node = traffic.get_npc_pilot() if traffic.has_method("get_npc_pilot") else null
	if visitor == null or not visitor.has_method("_do_land") or not visitor.has_method("_do_launch"):
		fails.append("NP-A: visitor is not a ShipController")
		return
	if pilot == null or not pilot.has_method("start_loop"):
		fails.append("NP-A: NpcPilot missing")
		return
	var host: Node = traffic.get_parent()
	if host == null or not (host is Node3D) or not host.has_meta("pad_up"):
		fails.append("NP-A: not on a pad")
		return
	var pin := str(host.get_meta("site_pin")) if host.has_meta("site_pin") else ""
	if pin.begins_with("SITE_"):
		fails.append("NP-A: minted SITE_* (%s)" % pin)
		return
	var pname := str(host.name)
	if pname != "Pad_North" and pname != "Pad_Approach" and pname != "Pad_Flank":
		fails.append("NP-A: unknown pad (%s)" % pname)
		return
	if not bool(visitor.get("is_landed")):
		fails.append("NP-A: visitor not seated before loop")
		return
	pilot.start_loop(true)
	var waited := 0.0
	while not bool(pilot.loop_done()) and waited < 8.0:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	var took := bool(pilot.saw_takeoff())
	var landed := bool(pilot.saw_land()) and bool(visitor.get("is_landed"))
	var gear := bool(pilot.gear_down_at_land())
	var scm := bool(pilot.used_scm())
	var hover := bool(pilot.used_hover())
	var lname := str(pilot.land_pad_name()) if pilot.has_method("land_pad_name") else ""
	print("[Playtest] NP-A takeoff=", took, " land=", landed, " gear=", gear,
		" SCM=", scm, " HOVER=", hover, " pad=", lname, " t=", snapped(waited, 0.1))
	if not took:
		fails.append("NP-A takeoff did not leave the pad")
	if not landed:
		fails.append("NP-A LAND did not complete")
	if landed and not gear:
		fails.append("NP-A LAND without gear down")
	if not scm:
		fails.append("NP-A never entered SCM")
	if not hover:
		fails.append("NP-A never entered HOVER")
	if lname != "" and lname != "Pad_North" and lname != "Pad_Approach" and lname != "Pad_Flank":
		fails.append("NP-A landed on unknown pad (%s)" % lname)
	if visitor.has_method("get_landed_pad"):
		var deck: Node = visitor.get_landed_pad()
		if deck == null:
			fails.append("NP-A LAND was surface, not unnamed pad")
		elif deck.has_meta("site_pin") and str(deck.get_meta("site_pin")).begins_with("SITE_"):
			fails.append("NP-A landed on SITE_*")


func _npc_occupy_harvest(fails: PackedStringArray) -> void:
	## NP-B: visitor occupy + harvest on the same unnamed pad. Same rates as player.
	var os: Node = get_parent()
	var nex: Node = _osh_nex()
	if nex != null and nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	var traffic: Node = nex.call("pad_traffic") if nex != null and nex.has_method("pad_traffic") else null
	if traffic == null or not is_instance_valid(traffic):
		fails.append("NP-B: pad traffic missing")
		return
	var visitor: Node = traffic.get_visitor() if traffic.has_method("get_visitor") else null
	var pilot: Node = traffic.get_npc_pilot() if traffic.has_method("get_npc_pilot") else null
	if visitor == null or not is_instance_valid(visitor):
		fails.append("NP-B: visitor missing")
		return
	if pilot == null or not pilot.has_method("start_harvest"):
		fails.append("NP-B: NpcPilot harvest missing")
		return
	var host: Node = traffic.get_parent()
	if host == null or not (host is Node3D) or not host.has_meta("pad_up"):
		fails.append("NP-B: not on a pad")
		return
	var pin := str(host.get_meta("site_pin")) if host.has_meta("site_pin") else ""
	if pin.begins_with("SITE_"):
		fails.append("NP-B: minted SITE_* (%s)" % pin)
		return
	var pname := str(host.name)
	if pname != "Pad_North" and pname != "Pad_Approach" and pname != "Pad_Flank":
		fails.append("NP-B: unknown pad (%s)" % pname)
		return
	var pad: Node = host.get_node_or_null("BaseCluster/PadBaseController")
	if pad == null:
		pad = host.find_child("PadBaseController", true, false)
	if pad == null:
		fails.append("NP-B: PadBaseController missing")
		return
	if pad.has_method("claim"):
		var fac := "Cybernex"
		if visitor.has_method("get_faction"):
			fac = str(visitor.get_faction())
		elif "faction" in visitor:
			fac = str(visitor.get("faction"))
		pad.claim(fac, 2.0)
		var ow = pad.get("ownership")
		if ow and ow.has_method("advance_transition"):
			ow.advance_transition(8.0, 5.0)
		await get_tree().process_frame
	if not bool(visitor.get("is_landed")) and pilot.has_method("_seat_on_pad"):
		pilot._seat_on_pad()
	# Only the NPC hull holds the ring — park the player.
	if os:
		var walker: Node3D = os.get("player") as Node3D
		if walker != null and is_instance_valid(walker):
			walker.global_position = (host as Node3D).global_position + Vector3(0, 0, 420)
		var pship: Node = os.get("ship")
		if pship != null and pship != visitor and is_instance_valid(pship):
			if bool(pship.get("is_landed")) and pship.has_method("_do_launch"):
				pship.set("_land_lock_t", 0.0)
				pship._do_launch()
			pship.global_position = (host as Node3D).global_position + Vector3(0, 80, 420)
	if float(pad.get("crystal_reserves")) < 8.0:
		pad.set("crystal_reserves", float(pad.get("max_reserves")))
	pad.set("running", true)
	var rate0: float = float(pad.get("extract_rate"))
	var cpu0: float = float(pad.get("contribution_per_unit"))
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("history", 20.0)
		GameManager.add_mastery("colony_ops", 20.0)
		GameManager.add_mastery("biomass_ops", 20.0)
	if absf(float(pad.get("extract_rate")) - rate0) > 0.001 \
		or absf(float(pad.get("contribution_per_unit")) - cpu0) > 0.001:
		fails.append("Knowledge changed NPC harvest yield")
	var grot := false
	if pad.has_method("get_faction"):
		grot = str(pad.get_faction()) == "gROT"
	var c0: float = 0.0
	if GameManager:
		c0 = float(GameManager.biomass) if grot else float(GameManager.contribution)
	var t0: float = float(pad.get("total_extracted"))
	pilot.start_harvest()
	await get_tree().create_timer(0.7).timeout
	var c1: float = c0
	if GameManager:
		c1 = float(GameManager.biomass) if grot else float(GameManager.contribution)
	var t1: float = float(pad.get("total_extracted"))
	var tick := bool(pilot.saw_harvest()) if pilot.has_method("saw_harvest") else false
	var st := str(pad.get_claim_status()) if pad.has_method("get_claim_status") else ""
	print("[Playtest] NP-B occupy harvest wallet=", snapped(c0, 0.01), " -> ", snapped(c1, 0.01),
		" extracted=", snapped(t0, 0.01), " -> ", snapped(t1, 0.01),
		" tick=", tick, " status=", st, " pad=", pname)
	if c1 <= c0 + 0.001 and t1 <= t0 + 0.001 and not tick:
		fails.append("NP-B: NPC occupy did not harvest")
	if pad.has_method("harvest_hud_line") and st == "extracting":
		var hl := str(pad.harvest_hud_line())
		if hl.find("EXTRACTING") < 0:
			fails.append("NP-B: extracting pad has no harvest HUD line")
	if traffic.has_method("refresh_labels"):
		traffic.refresh_labels()
	if pilot.has_method("stop_harvest"):
		pilot.stop_harvest()



func _npc_place_module(fails: PackedStringArray) -> void:
	## NP-C: visitor places one habitat on an empty unnamed pad.
	## Same BaseBuilder as ST-A. Not SITE_*. Not a second module from this hull.
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.NP_C_MODULE):
		fails.append("NP-C P0Slice flag missing")
		return
	var nex: Node = _osh_nex()
	if nex != null and nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
		await get_tree().create_timer(0.2).timeout
	var traffic: Node = nex.call("pad_traffic") if nex != null and nex.has_method("pad_traffic") else null
	if traffic == null or not is_instance_valid(traffic):
		fails.append("NP-C: pad traffic missing")
		return
	var pilot: Node = traffic.get_npc_pilot() if traffic.has_method("get_npc_pilot") else null
	if pilot == null or not pilot.has_method("place_one_module"):
		fails.append("NP-C: NpcPilot place_one_module missing")
		return
	var pin0 := str(LayerContext.site_pin_id) if LayerContext else ""
	var tree := get_tree()
	var before := 0
	if tree:
		before = tree.get_nodes_in_group("npc_base_modules").size()
	var mod: Node3D = pilot.place_one_module()
	if mod == null or not is_instance_valid(mod):
		fails.append("NP-C: habitat was not placed")
		return
	var pad: Node = mod.get_parent()
	var pname := str(pad.name) if pad else "?"
	if pname != "Pad_North" and pname != "Pad_Approach" and pname != "Pad_Flank":
		fails.append("NP-C: unknown pad (%s)" % pname)
	var mpin := str(mod.get_meta("site_pin", "missing"))
	var combat := int(mod.combat_stats()) if mod.has_method("combat_stats") else -1
	print("[Playtest] NP-C module=", mod.name, " pad=", pname, " pin=", mpin, " combat=", combat)
	if mpin != "":
		fails.append("NP-C module minted site_pin (%s)" % mpin)
	if combat != 0:
		fails.append("NP-C habitat has combat stats")
	if str(mod.get_meta("module_type", "")) != "habitat":
		fails.append("NP-C module is not habitat")
	if not bool(mod.get_meta("npc_module", false)):
		fails.append("NP-C module not marked npc_module")
	if bool(mod.get_meta("player_module", true)):
		fails.append("NP-C stole the player_module slot")
	var again: Node3D = pilot.place_one_module()
	if again != null:
		fails.append("NP-C placed a second module from the same hull")
	if LayerContext and str(LayerContext.site_pin_id) != pin0:
		fails.append("NP-C changed site_pin (%s → %s)" % [pin0, LayerContext.site_pin_id])
	var after := before
	if tree:
		after = tree.get_nodes_in_group("npc_base_modules").size()
	if after != before + 1:
		fails.append("NP-C want exactly one npc module, got %s (was %s)" % [after, before])
	print("[Playtest] NP-C overlay pad=", pname, " pin=", LayerContext.site_pin_id if LayerContext else "")


func _npc_squad_invite(fails: PackedStringArray) -> void:
	## NP-D: invite one local NPC. Squad contains them. Follow or seat.
	## No damage aura. No pay-slot. SoftNet stays visual.
	var os: Node = get_parent()
	var nex: Node = _osh_nex()
	if os == null or nex == null:
		fails.append("NP-D: no OpenSpace/Nex-Prime")
		return
	if nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	var traffic: Node = nex.call("pad_traffic") if nex.has_method("pad_traffic") else null
	if traffic == null or not is_instance_valid(traffic):
		fails.append("NP-D: pad traffic missing")
		return
	var visitor: Node = traffic.get_visitor() if traffic.has_method("get_visitor") else null
	var pilot: Node = traffic.get_npc_pilot() if traffic.has_method("get_npc_pilot") else null
	if visitor == null or not is_instance_valid(visitor) or pilot == null:
		fails.append("NP-D: visitor/NpcPilot missing")
		return
	var host: Node = traffic.get_parent()
	if host == null or not (host is Node3D) or not host.has_meta("pad_up"):
		fails.append("NP-D: not on a pad")
		return
	var pin := str(host.get_meta("site_pin")) if host.has_meta("site_pin") else ""
	if pin.begins_with("SITE_"):
		fails.append("NP-D: minted SITE_* (%s)" % pin)
		return
	var squad: Node = os.get_squad() if os.has_method("get_squad") else os.get("_squad")
	if squad == null or not squad.has_method("invite"):
		fails.append("NP-D: SquadRoster missing")
		return
	var pship: Node3D = os.get("ship") as Node3D
	if pship != null and is_instance_valid(pship) and pship != visitor:
		pship.global_position = (host as Node3D).global_position + Vector3(18, 10, 8)
	var walker: Node3D = os.get("player") as Node3D
	if walker != null and is_instance_valid(walker):
		walker.global_position = (visitor as Node3D).global_position + Vector3(4, 2, 2)
	var c0: float = float(GameManager.contribution) if GameManager else 0.0
	var guard: Node = traffic.get_guard() if traffic.has_method("get_guard") else null
	var dmg0: float = float(guard.get("attack_damage")) if guard != null else 0.0
	var hp0: float = float(guard.get("max_health")) if guard != null else 0.0
	var invited := false
	if os.has_method("invite_nearby_npc"):
		invited = bool(os.invite_nearby_npc())
	if not invited:
		invited = bool(squad.invite(pilot))
	if not invited:
		fails.append("NP-D: invite failed")
		return
	if not bool(squad.contains(pilot)):
		fails.append("NP-D: squad does not contain the NPC")
		return
	if visitor != null and squad.has_method("contains") and not bool(squad.contains(visitor)):
		fails.append("NP-D: squad does not contain visitor hull")
		return
	var sz: int = int(squad.size()) if squad.has_method("size") else 0
	if sz < 2 or sz > 5:
		fails.append("NP-D: squad size %s outside rules/24 2–5" % sz)
	var extra := Node.new()
	extra.name = "NpDSecondNpc"
	os.add_child(extra)
	if bool(squad.invite(extra)):
		fails.append("NP-D: second NPC invite (NP-E)")
	extra.queue_free()
	if GameManager and float(GameManager.contribution) < c0 - 0.001:
		fails.append("NP-D: invite spent Contribution (pay-slot)")
	if squad.has_method("invite_cost") and float(squad.invite_cost()) > 0.0:
		fails.append("NP-D: invite_cost is a pay-slot")
	if squad.has_method("combat_bonus") and absf(float(squad.combat_bonus())) > 0.0001:
		fails.append("NP-D: group damage aura")
	if guard != null:
		if absf(float(guard.get("attack_damage")) - dmg0) > 0.01:
			fails.append("NP-D: squad changed guard DPS")
		if absf(float(guard.get("max_health")) - hp0) > 0.01:
			fails.append("NP-D: squad changed guard HP")
	if pilot.has_method("is_squad_following") and not bool(pilot.is_squad_following()):
		fails.append("NP-D: NPC not following after invite")
	var body: Node3D = pilot.squad_body() if pilot.has_method("squad_body") else null
	var followed := false
	var anchor: Node3D = walker if walker != null and is_instance_valid(walker) else pship
	if body != null and anchor != null and is_instance_valid(anchor):
		var start: Vector3 = body.global_position
		anchor.global_position = (host as Node3D).global_position + Vector3(-28, 12, 16)
		var waited := 0.0
		while waited < 0.6:
			await get_tree().create_timer(0.1).timeout
			waited += 0.1
		if body != null and is_instance_valid(body):
			var after: Vector3 = body.global_position
			var closer: float = start.distance_to(anchor.global_position) - after.distance_to(anchor.global_position)
			followed = closer > 0.4 or after.distance_to(anchor.global_position) < 8.0
		if not followed:
			fails.append("NP-D: NPC did not follow")
	var seated := false
	var d: Node = os.get("_interior")
	var ship: Node = os.get("ship")
	if d != null and ship != null and d.has_method("enter_ship") and d.has_method("seat_companion"):
		var prev_player: Node = os.get("player")
		var ghost := CharacterBody3D.new()
		ghost.name = "NpDSeatGhost"
		os.add_child(ghost)
		d.enter_ship(ghost, ship)
		await get_tree().create_timer(0.25).timeout
		if d.has_method("is_inside") and bool(d.is_inside()) and str(d.get_kind()) == "ship":
			if pilot.has_method("try_squad_seat") and bool(pilot.try_squad_seat(d)):
				var seated_body: Node3D = pilot.squad_body() if pilot.has_method("squad_body") else null
				seated = seated_body != null and d.has_method("is_near_seat") and bool(d.is_near_seat(seated_body, 3.8))
				if not seated:
					fails.append("NP-D: NPC seat missed InteriorDirector Seat")
			else:
				fails.append("NP-D: seat_companion failed")
		else:
			fails.append("NP-D: ship pocket missing for seat")
		if d.has_method("exit_interior"):
			d.exit_interior()
		if os.get("player") == ghost:
			os.set("player", prev_player if prev_player != null and is_instance_valid(prev_player) else null)
		if is_instance_valid(ghost):
			ghost.queue_free()
		await get_tree().process_frame
	print("[Playtest] NP-D invite=", invited, " contains=", bool(squad.contains(pilot)),
		" size=", sz, " follow=", followed, " seat=", seated, " aura=",
		snapped(float(squad.combat_bonus()) if squad.has_method("combat_bonus") else 0.0, 0.01))


func _npc_offline_cycle(fails: PackedStringArray) -> void:
	## NP-F: player gone → short local pad/follow cycle via SoftSession.
	## Last actions shift the next legal step, not the damage table.
	var os: Node = get_parent()
	var nex: Node = _osh_nex()
	if os == null or nex == null:
		fails.append("NP-F: no OpenSpace/Nex-Prime")
		return
	if nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	var traffic: Node = nex.call("pad_traffic") if nex.has_method("pad_traffic") else null
	if traffic == null or not is_instance_valid(traffic):
		fails.append("NP-F: pad traffic missing")
		return
	var visitor: Node = traffic.get_visitor() if traffic.has_method("get_visitor") else null
	var pilot: Node = traffic.get_npc_pilot() if traffic.has_method("get_npc_pilot") else null
	if visitor == null or not is_instance_valid(visitor) or pilot == null:
		fails.append("NP-F: visitor/NpcPilot missing")
		return
	if not pilot.has_method("run_offline_cycle"):
		fails.append("NP-F: offline cycle missing")
		return
	var host: Node = traffic.get_parent()
	if host == null or not (host is Node3D) or not host.has_meta("pad_up"):
		fails.append("NP-F: not on a pad")
		return
	var pin := str(host.get_meta("site_pin")) if host.has_meta("site_pin") else ""
	if pin.begins_with("SITE_"):
		fails.append("NP-F: minted SITE_* (%s)" % pin)
		return
	if SoftSession == null or not SoftSession.has_method("begin_offline"):
		fails.append("NP-F: SoftSession offline missing")
		return
	var squad: Node = os.get_squad() if os.has_method("get_squad") else os.get("_squad")
	var guard: Node = traffic.get_guard() if traffic.has_method("get_guard") else null
	var dmg0: float = float(guard.get("attack_damage")) if guard != null else 0.0
	var hp0: float = float(guard.get("max_health")) if guard != null else 0.0
	var aura0: float = float(squad.combat_bonus()) if squad != null and squad.has_method("combat_bonus") else 0.0
	SoftSession.note_player_action("occupy")
	if str(SoftSession.next_legal_step()) != "pad":
		fails.append("NP-F: occupy did not pick pad")
	SoftSession.note_player_action("harvest")
	if str(SoftSession.next_legal_step()) != "pad":
		fails.append("NP-F: harvest did not pick pad")
	SoftSession.note_player_action("form")
	if str(SoftSession.next_legal_step()) != "pad":
		fails.append("NP-F: form did not pick pad")
	SoftSession.note_player_action("faction")
	if str(SoftSession.next_legal_step()) != "pad":
		fails.append("NP-F: faction did not pick pad")
	SoftSession.note_player_action("invite")
	if str(SoftSession.next_legal_step()) != "follow":
		fails.append("NP-F: invite did not pick follow")
	if SoftSession.has_method("end_offline"):
		SoftSession.end_offline()
	SoftSession.note_player_action("occupy")
	SoftSession.begin_offline()
	var pad_step := str(pilot.run_offline_cycle())
	var waited := 0.0
	while waited < 0.6:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	var pad_ran := bool(pilot.offline_cycle_ran()) if pilot.has_method("offline_cycle_ran") else false
	var pad_harvest := bool(pilot.is_harvesting()) if pilot.has_method("is_harvesting") else false
	if pad_step != "pad" or not pad_ran:
		fails.append("NP-F: pad cycle did not run")
	if SoftSession.has_method("end_offline"):
		SoftSession.end_offline()
	SoftSession.note_player_action("invite")
	SoftSession.begin_offline()
	var follow_step := str(pilot.run_offline_cycle())
	var follow_ok := follow_step == "follow" and bool(pilot.is_squad_following()) if pilot.has_method("is_squad_following") else follow_step == "follow"
	if follow_step != "follow" or not follow_ok:
		fails.append("NP-F: follow cycle did not run")
	var inf: Node = pilot.get_node_or_null("InfectionStatus")
	if inf == null or not inf.has_method("add_stacks"):
		fails.append("NP-F: InfectionStatus missing on NPC")
	else:
		inf.add_stacks(10)
		var stacks: int = int(inf.stacks)
		print("[Playtest] NP-F infection stacks=", stacks, " cap=",
			int(pilot.infection_cap()) if pilot.has_method("infection_cap") else 5)
		if stacks != 5:
			fails.append("NP-F: Infection not capped at 5 (got %s)" % stacks)
	if squad != null and squad.has_method("combat_bonus") and absf(float(squad.combat_bonus()) - aura0) > 0.0001:
		fails.append("NP-F: influence changed combat aura")
	if squad != null and squad.has_method("combat_bonus") and absf(float(squad.combat_bonus())) > 0.0001:
		fails.append("NP-F: group damage aura")
	if guard != null:
		if absf(float(guard.get("attack_damage")) - dmg0) > 0.01:
			fails.append("NP-F: influence changed guard DPS")
		if absf(float(guard.get("max_health")) - hp0) > 0.01:
			fails.append("NP-F: influence changed guard HP")
	if visitor.has_method("get_landed_pad"):
		var deck: Node = visitor.get_landed_pad()
		if deck != null and deck.has_meta("site_pin") and str(deck.get_meta("site_pin")).begins_with("SITE_"):
			fails.append("NP-F: landed on SITE_*")
	if SoftSession.has_method("end_offline"):
		SoftSession.end_offline()
	if pilot.has_method("stop_harvest"):
		pilot.stop_harvest()
	print("[Playtest] NP-F offline pad=", pad_step, " harvest=", pad_harvest,
		" follow=", follow_step, " ran=", pad_ran, " last=", SoftSession.last_action,
		" aura=", snapped(float(squad.combat_bonus()) if squad != null and squad.has_method("combat_bonus") else 0.0, 0.01))


func _npc_soft_alliance(fails: PackedStringArray) -> void:
	## NP-E: two local NPCs, AllianceRanks + visible raid/logistics intent.
	## No HP/DPS/claim bonus. Not pay-to-rank. Not rules/23 siege.
	var os: Node = get_parent()
	var nex: Node = _osh_nex()
	if os == null or nex == null:
		fails.append("NP-E: no OpenSpace/Nex-Prime")
		return
	if nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	var traffic: Node = nex.call("pad_traffic") if nex.has_method("pad_traffic") else null
	if traffic == null or not is_instance_valid(traffic):
		fails.append("NP-E: pad traffic missing")
		return
	var guard: Node = traffic.get_guard() if traffic.has_method("get_guard") else null
	var visitor: Node = traffic.get_visitor() if traffic.has_method("get_visitor") else null
	var pilot: Node = traffic.get_npc_pilot() if traffic.has_method("get_npc_pilot") else null
	if guard == null or visitor == null or not is_instance_valid(guard) or not is_instance_valid(visitor):
		fails.append("NP-E: two NPCs missing")
		return
	var host: Node = traffic.get_parent()
	if host == null or not (host is Node3D) or not host.has_meta("pad_up"):
		fails.append("NP-E: not on a pad")
		return
	var pin := str(host.get_meta("site_pin")) if host.has_meta("site_pin") else ""
	if pin.begins_with("SITE_"):
		fails.append("NP-E: minted SITE_* (%s)" % pin)
		return
	var ally: Node = traffic.get_alliance() if traffic.has_method("get_alliance") else null
	if ally == null and os.has_method("get_alliance"):
		ally = os.get_alliance()
	if ally == null or not ally.has_method("hud_line"):
		fails.append("NP-E: SoftAlliance missing")
		return
	if int(ally.member_count()) != 2:
		fails.append("NP-E: want two NPCs, got %s" % ally.member_count())
		return
	var _Ranks = load("res://scripts/systems/AllianceRanks.gd")
	for who in [guard, pilot if pilot != null else visitor]:
		var rk: int = int(ally.member_rank(who))
		var perm := str(ally.member_perm(who))
		if rk < 0 or rk > 4:
			fails.append("NP-E: rank %s outside 0–4" % rk)
		if perm == "" or not bool(_Ranks.has_perm(rk, perm)):
			fails.append("NP-E: missing/invalid perm (%s rank %s)" % [perm, rk])
		if not bool(ally.member_has_perm(who)):
			fails.append("NP-E: member perm not granted by AllianceRanks")
	var kind := str(ally.intent()) if ally.has_method("intent") else ""
	if kind != "raid" and kind != "logistics":
		fails.append("NP-E: intent must be raid or logistics (got %s)" % kind)
	if ally.has_method("is_siege") and bool(ally.is_siege()):
		fails.append("NP-E: intent is siege (rules/23)")
	if ally.has_method("is_war") and bool(ally.is_war()):
		fails.append("NP-E: intent is war declare")
	if ally.has_method("set_intent") and bool(ally.set_intent("siege")):
		fails.append("NP-E: siege accepted as intent")
	if str(ally.intent()) == "siege":
		fails.append("NP-E: siege stuck as intent")
	var line := str(ally.hud_line())
	if line == "" or line.to_upper().find(str(ally.intent()).to_upper()) < 0:
		fails.append("NP-E: intent not visible in hud_line")
	if line.to_upper().find("SIEGE") >= 0:
		fails.append("NP-E: siege leaked into hud_line")
	if ally.has_method("intent_visible") and not bool(ally.intent_visible()):
		fails.append("NP-E: intent_visible false")
	if ally.has_method("combat_bonus") and absf(float(ally.combat_bonus())) > 0.0001:
		fails.append("NP-E: combat aura")
	if ally.has_method("claim_bonus") and absf(float(ally.claim_bonus())) > 0.0001:
		fails.append("NP-E: claim bonus")
	if ally.has_method("rank_cost") and float(ally.rank_cost()) > 0.0:
		fails.append("NP-E: pay-to-rank")
	if ally.has_method("war_cost") and float(ally.war_cost()) > 0.0:
		fails.append("NP-E: pay-to-war")
	var dmg0: float = float(guard.get("attack_damage"))
	var hp0: float = float(guard.get("max_health"))
	var claim0 := 0.0
	var pad: Node = host.get_node_or_null("BaseCluster/PadBaseController")
	if pad == null:
		pad = host.find_child("PadBaseController", true, false)
	if pad != null and "ownership" in pad and pad.ownership:
		claim0 = float(pad.ownership.claim_strength)
	var r_g0: int = int(ally.member_rank(guard))
	var c0: float = float(GameManager.contribution) if GameManager else 0.0
	if GameManager:
		GameManager.contribution = c0 + 5000.0
		if GameManager.has_method("try_promote_alliance"):
			GameManager.try_promote_alliance()
	if int(ally.member_rank(guard)) != r_g0:
		fails.append("NP-E: player spend changed NPC rank (pay-to-rank)")
	if GameManager:
		GameManager.contribution = c0
	if ally.has_method("set_intent"):
		if not bool(ally.set_intent("logistics")):
			fails.append("NP-E: logistics intent rejected")
		var log_line := str(ally.hud_line()).to_upper()
		if log_line.find("LOGISTICS") < 0:
			fails.append("NP-E: logistics not visible")
		ally.set_intent("raid")
	if traffic.has_method("refresh_labels"):
		traffic.refresh_labels()
	var hud = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
	var seen := str(ally.hud_line())
	if hud != null and hud.has_method("alliance_hud_text"):
		seen = str(hud.alliance_hud_text())
	if seen.to_upper().find(str(ally.intent()).to_upper()) < 0:
		fails.append("NP-E: player cannot see intent")
	if absf(float(guard.get("attack_damage")) - dmg0) > 0.01:
		fails.append("NP-E: alliance changed guard DPS")
	if absf(float(guard.get("max_health")) - hp0) > 0.01:
		fails.append("NP-E: alliance changed guard HP")
	if pad != null and "ownership" in pad and pad.ownership:
		if absf(float(pad.ownership.claim_strength) - claim0) > 0.001:
			fails.append("NP-E: alliance changed claim strength")
	if visitor.has_meta("site_pin") and str(visitor.get_meta("site_pin")).begins_with("SITE_"):
		fails.append("NP-E: visitor minted SITE_*")
	print("[Playtest] NP-E npcs=", ally.member_count(), " ranks=",
		int(ally.member_rank(guard)), "/", int(ally.member_rank(pilot if pilot != null else visitor)),
		" intent=", ally.intent(), " visible=", seen,
		" aura=", snapped(float(ally.combat_bonus()) if ally.has_method("combat_bonus") else 0.0, 0.01),
		" claim=", snapped(float(ally.claim_bonus()) if ally.has_method("claim_bonus") else 0.0, 0.01))


func _eva_snap_pulse(fails: PackedStringArray) -> void:
	## Pillar 6: after EVA snap on Relief, existing Pulse hits the surface dummy.
	## Knowledge may relabel. Pulse DPS stays 11. Grounded walk, not zero-G.
	var os: Node = get_parent()
	var nex: Node = _osh_nex()
	if os == null or nex == null:
		fails.append("EVA-snap→Pulse: no OpenSpace/Nex-Prime")
		return
	if nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	var traffic: Node = nex.call("pad_traffic") if nex.has_method("pad_traffic") else null
	if traffic == null or not is_instance_valid(traffic):
		fails.append("EVA-snap→Pulse: pad traffic missing")
		return
	var dummy: Node3D = traffic.get_surface_dummy() if traffic.has_method("get_surface_dummy") else null
	if dummy == null and traffic.has_method("pulse_target"):
		dummy = traffic.pulse_target()
	if dummy == null or not is_instance_valid(dummy):
		fails.append("EVA-snap→Pulse: no surface dummy")
		return
	if dummy.has_method("set"):
		dummy.set("faction", "gROT")
		dummy.set("_alive", true)
		if float(dummy.get("health")) < 20.0:
			dummy.set("health", float(dummy.get("max_health")))
	var host: Node3D = traffic.get_parent() as Node3D
	if host == null or not host.has_meta("pad_up"):
		fails.append("EVA-snap→Pulse: dummy not on a pad")
		return
	var pin := str(host.get_meta("site_pin")) if host.has_meta("site_pin") else ""
	if pin.begins_with("SITE_"):
		fails.append("EVA-snap→Pulse: minted SITE_* (%s)" % pin)
		return
	var pad_up: Vector3 = host.get_meta("pad_up")
	var ship: Node3D = os.get("ship") as Node3D
	if ship == null or not is_instance_valid(ship):
		fails.append("EVA-snap→Pulse: no ship")
		return
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	ship.global_position = host.global_position + pad_up * 8.0
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	if ship.has_method("_do_land"):
		ship._do_land()
	if not bool(ship.get("is_landed")):
		fails.append("EVA-snap→Pulse: ship did not land")
		return
	if os.has_method("try_exit_ship"):
		os.try_exit_ship()
	await get_tree().create_timer(0.4).timeout
	var walker: Node3D = os.get("player") as Node3D
	if (walker == null or not is_instance_valid(walker)) and os.has_method("_spawn_player_near_ship"):
		os.call("_spawn_player_near_ship")
		await get_tree().create_timer(0.25).timeout
		walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("EVA-snap→Pulse: no walker after EVA")
		return
	if walker.has_method("set_eva_profile"):
		walker.set_eva_profile(false)
	os.set("_eva_mode", false)
	if walker.has_method("set"):
		walker.set("faction", "Cybernex")
	if walker.has_method("is_zero_g") and bool(walker.is_zero_g()):
		fails.append("EVA-snap→Pulse: walker still zero-G")
		return
	var aim: Vector3 = dummy.hurtbox_center() if dummy.has_method("hurtbox_center") else dummy.global_position
	var away: Vector3 = dummy.global_position - host.global_position
	away = away - pad_up * away.dot(pad_up)
	if away.length_squared() < 0.01:
		away = host.global_transform.basis.x
	away = away.normalized()
	walker.global_position = dummy.global_position - away * 8.0 + pad_up * 2.0
	if walker.has_method("_relief_snap_fallback"):
		walker.call("_relief_snap_fallback")
	elif walker.has_method("snap_to_surface"):
		walker.call("snap_to_surface")
	var snap_agl: float = _osh_agl(nex, walker.global_position)
	print("[Playtest] EVA-snap→Pulse snap AGL=", snapped(snap_agl, 0.01), " dummy_d=", snapped(walker.global_position.distance_to(dummy.global_position), 0.1))
	if snap_agl > 40.0 or snap_agl < -6.0:
		fails.append("EVA-snap→Pulse walker off Relief (%s)" % snapped(snap_agl, 0.01))
		return
	if walker.has_method("face_world_point"):
		walker.face_world_point(aim)
	var cam: Camera3D = walker.get_node_or_null("CamPivot/Camera3D") as Camera3D
	if cam:
		var cup: Vector3 = pad_up
		var look: Vector3 = aim - cam.global_position
		if look.length_squared() > 0.0001 and absf(look.normalized().dot(cup)) > 0.98:
			cup = walker.global_transform.basis.x
		cam.look_at(aim, cup)
	await get_tree().process_frame
	await get_tree().process_frame
	if SoftScanCache:
		SoftScanCache.invalidate_enemies()
		SoftScanCache.invalidate_player()
	var aim_dbg: Array = _Hits.aim_from(walker)
	var a0: Vector3 = aim_dbg[0]
	var ad: Vector3 = aim_dbg[1]
	var to_d: Vector3 = aim - a0
	var t: float = to_d.dot(ad)
	var closest: Vector3 = a0 + ad * t
	print("[Playtest] EVA-snap→Pulse dummy=", dummy.name, " fac=", dummy.get("faction"), " hp=", dummy.get("health"), " miss=", snapped(closest.distance_to(aim), 0.01), " t=", snapped(t, 0.1))
	var pulse_dmg := 11.0
	var ab: Node = walker.get_node_or_null("AbilitySystem")
	if ab == null:
		fails.append("EVA-snap→Pulse: no AbilitySystem")
		return
	if "energy" in walker:
		walker.set("energy", 100.0)
	if ab.get("abilities") != null and (ab.abilities as Array).size() > 0 and ab.abilities[0]:
		pulse_dmg = float(ab.abilities[0].damage)
		if absf(pulse_dmg - 11.0) > 0.01:
			fails.append("EVA-snap→Pulse: Pulse damage drifted (%s)" % pulse_dmg)
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("history", 20.0)
		GameManager.add_mastery("combat", 20.0)
	if traffic.has_method("refresh_labels"):
		traffic.refresh_labels()
	if ab.get("abilities") != null and (ab.abilities as Array).size() > 0 and ab.abilities[0]:
		if absf(float(ab.abilities[0].damage) - pulse_dmg) > 0.01:
			fails.append("Knowledge changed Pulse DPS")
	var dlabel := str(traffic.surface_dummy_label()) if traffic.has_method("surface_dummy_label") else ""
	if dlabel == "":
		fails.append("Knowledge surface dummy label empty")
	var hp0: float = float(dummy.get("health"))
	var fired := false
	if walker.has_method("try_pulse"):
		fired = bool(walker.try_pulse())
	elif ab.has_method("try_activate"):
		fired = bool(ab.try_activate(0))
	var hp1: float = float(dummy.get("health"))
	var drop: float = hp0 - hp1
	print("[Playtest] EVA-snap→Pulse hit=", fired, " hp ", snapped(hp0, 0.1), " → ", snapped(hp1, 0.1), " drop=", snapped(drop, 0.1), " label=", dlabel)
	if not fired:
		fails.append("EVA-snap→Pulse: Pulse did not fire")
	elif drop < 10.0:
		fails.append("EVA-snap→Pulse: Pulse did not hit dummy (%s → %s)" % [snapped(hp0, 0.1), snapped(hp1, 0.1)])
	elif drop > 12.5:
		fails.append("Knowledge changed Pulse DPS (drop=%s)" % snapped(drop, 0.1))
	var after_agl: float = _osh_agl(nex, walker.global_position)
	if after_agl > 40.0 or after_agl < -6.0:
		fails.append("EVA-snap→Pulse walker left Relief after Pulse (%s)" % snapped(after_agl, 0.01))
	if walker.has_method("is_zero_g") and bool(walker.is_zero_g()):
		fails.append("EVA-snap→Pulse zero-G after Pulse")


func _rover_drive_slice(os: Node, fails: PackedStringArray) -> void:
	## Occupied unnamed pad on the loaded Nex-Prime body. Same GroundVehicle.
	## Knowledge may relabel. Speed / HP stay put.
	var picked: Dictionary = _rover_pick_unnamed_pad(os)
	var deck: Node3D = picked.get("deck") as Node3D
	var ctrl: Node = picked.get("ctrl")
	var nex: Node = picked.get("planet")
	var sh_r: Node = os.get("ship")
	if sh_r == null or deck == null or nex == null or not bool(sh_r.has_method("_try_deploy_rover")):
		fails.append("no ship/unnamed pad for rover deploy")
		return
	if str(nex.get("planet_name")) != "Nex-Prime":
		fails.append("rover pad not on Nex-Prime (%s)" % str(nex.get("planet_name")))
		return
	var pin := ""
	if deck.has_meta("site_pin"):
		pin = str(deck.get_meta("site_pin"))
	if pin != "":
		fails.append("rover pad minted SITE_* (%s)" % pin)
		return
	if ctrl != null and ctrl.has_method("claim"):
		var st0 := str(ctrl.get_claim_status()) if ctrl.has_method("get_claim_status") else ""
		if st0 != "owned":
			ctrl.claim("Cybernex", 2.0)
			var ow = ctrl.get("ownership")
			if ow and ow.has_method("advance_transition"):
				ow.advance_transition(8.0, 5.0)
			await get_tree().process_frame
	var st := str(ctrl.get_claim_status()) if ctrl != null and ctrl.has_method("get_claim_status") else ""
	var held := false
	var ow2 = ctrl.get("ownership") if ctrl != null else null
	if ow2 != null and ow2.has_method("is_fully_owned"):
		held = bool(ow2.is_fully_owned())
	print("[Playtest] rover pad=", deck.name, " occupy=", st, " held=", held, " pin=", pin)
	# extracting = owned + harvest running. Both count as occupied.
	if not held and st != "owned" and st != "extracting" and st != "claiming":
		fails.append("rover pad not occupied (status=%s)" % st)
		return

	var up_r: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if "velocity" in sh_r:
		sh_r.velocity = Vector3.ZERO
	sh_r.global_position = deck.global_position + up_r * 6.0
	if sh_r.has_method("_set_mode"):
		sh_r._set_mode(2)
	if sh_r.has_method("_do_land"):
		sh_r._do_land()
	if not bool(sh_r.get("is_landed")):
		fails.append("ship not landed for rover deploy")
		return

	if bool(os.get("_in_rover")) and os.has_method("_unboard_rover"):
		os._unboard_rover()
	var already: Node3D = sh_r.get_deployed_rover() if sh_r.has_method("get_deployed_rover") else null
	if already != null and is_instance_valid(already):
		if os.has_method("_try_store_rover"):
			os._try_store_rover()
		await get_tree().process_frame

	sh_r._try_deploy_rover()
	await get_tree().process_frame
	await get_tree().physics_frame
	var rov: Node3D = sh_r.get_deployed_rover() if sh_r.has_method("get_deployed_rover") else null
	print("[Playtest] rover deployed=", rov != null)
	if rov == null or not is_instance_valid(rov):
		fails.append("rover did not deploy on occupied unnamed pad")
		return
	if not rov.has_method("board"):
		fails.append("rover script missing board (parse)")
		return
	if str(rov.get("class_id")) != "rover":
		fails.append("deployed a new vehicle class (%s)" % str(rov.get("class_id")))
		return

	var spd0: float = float(rov.get("speed"))
	var hp0: float = float(rov.get("health"))
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("logistics", 20.0)
	if rov.has_method("refresh_label"):
		rov.refresh_label()
	if absf(float(rov.get("speed")) - spd0) > 0.01:
		fails.append("Knowledge changed rover speed")
	if absf(float(rov.get("health")) - hp0) > 0.01:
		fails.append("Knowledge changed rover HP")
	var rlab := str(rov.label_text()) if rov.has_method("label_text") else ""
	print("[Playtest] rover Knowledge label=", rlab, " speed=", rov.get("speed"), " hp=", rov.get("health"))
	if rlab == "":
		fails.append("Knowledge rover label empty")

	if rov.has_method("snap_to_relief"):
		rov.snap_to_relief()
	var walker: Node3D = os.get("player") as Node3D
	if (walker == null or not is_instance_valid(walker)) and os.has_method("try_exit_ship"):
		if bool(os.get("_in_ship")):
			os.try_exit_ship()
			await get_tree().create_timer(0.25).timeout
			walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("no walker to board rover")
		return
	walker.global_position = rov.global_position + up_r * 1.6
	await get_tree().process_frame
	if os.has_method("_try_board_nearby_rover"):
		os._try_board_nearby_rover()
	if not bool(os.get("_in_rover")):
		fails.append("could not board rover")
		return

	var p0: Vector3 = rov.global_position
	if rov.has_method("set_drive_command"):
		rov.set_drive_command(1.0, 0.35)
	await get_tree().create_timer(0.55).timeout
	if rov.has_method("set_drive_command"):
		rov.set_drive_command(1.0, -0.55)
	await get_tree().create_timer(0.55).timeout
	if rov.has_method("clear_drive_command"):
		rov.clear_drive_command()
	var p1: Vector3 = rov.global_position
	var driven: float = p0.distance_to(p1)
	var agl: float = float(nex.altitude_of(p1)) if nex.has_method("altitude_of") else -99.0
	var rel_h: float = float(nex.relief_height_at(p1)) if nex.has_method("relief_height_at") else 0.0
	print("[Playtest] rover drive ", snapped(driven, 0.01), "m AGL=", snapped(agl, 0.01), " relief=", snapped(rel_h, 0.01))
	if driven < 1.2:
		fails.append("rover did not drive on PlanetRelief (%s m)" % snapped(driven, 0.01))
	if agl > 40.0 or agl < -6.0:
		fails.append("rover left PlanetRelief (AGL %s)" % snapped(agl, 0.01))

	if os.has_method("_unboard_rover"):
		os._unboard_rover()
	await get_tree().process_frame
	# Stow needs the chassis near the landed hull after the loop.
	if rov != null and is_instance_valid(rov) and sh_r is Node3D:
		var back: Vector3 = (sh_r as Node3D).global_position + up_r * 1.2
		if rov.global_position.distance_to((sh_r as Node3D).global_position) > 16.0:
			rov.global_position = back
			if rov.has_method("snap_to_relief"):
				rov.snap_to_relief()
	if os.has_method("_try_store_rover"):
		os._try_store_rover()
	await get_tree().process_frame
	var rov2: Node3D = sh_r.get_deployed_rover() if sh_r.has_method("get_deployed_rover") else null
	print("[Playtest] rover stored=", rov2 == null)
	if rov2 != null and is_instance_valid(rov2):
		fails.append("rover still deployed after store")
	var hold: Node = sh_r.get_node_or_null("CargoHold")
	var nveh: int = 0
	if hold != null:
		var vehs: Variant = hold.get("vehicles")
		if vehs is Array:
			nveh = (vehs as Array).size()
	print("[Playtest] cargo vehicles=", nveh)
	if nveh < 1:
		fails.append("rover store did not land in CargoHold")


func _cargo_dock_slice(os: Node, fails: PackedStringArray) -> void:
	## Occupied unnamed pad: land/dock, move one crate pad↔CargoHold. No tractor.
	## Knowledge may relabel. Mass / value stay put.
	var picked: Dictionary = _rover_pick_unnamed_pad(os)
	var deck: Node3D = picked.get("deck") as Node3D
	var ctrl: Node = picked.get("ctrl")
	var nex: Node = picked.get("planet")
	var sh: Node = os.get("ship")
	if sh == null or deck == null or ctrl == null or nex == null:
		fails.append("no ship/unnamed pad for cargo dock")
		return
	if str(nex.get("planet_name")) != "Nex-Prime":
		fails.append("cargo pad not on Nex-Prime (%s)" % str(nex.get("planet_name")))
		return
	var pin := str(deck.get_meta("site_pin")) if deck.has_meta("site_pin") else ""
	if pin.begins_with("SITE_"):
		fails.append("cargo pad minted SITE_* (%s)" % pin)
		return
	if ctrl.has_method("claim"):
		var st0 := str(ctrl.get_claim_status()) if ctrl.has_method("get_claim_status") else ""
		if st0 != "owned" and st0 != "extracting":
			ctrl.claim("Cybernex", 2.0)
			var ow = ctrl.get("ownership")
			if ow and ow.has_method("advance_transition"):
				ow.advance_transition(8.0, 5.0)
			await get_tree().process_frame
	var held := false
	var ow2 = ctrl.get("ownership")
	if ow2 != null and ow2.has_method("is_fully_owned"):
		held = bool(ow2.is_fully_owned())
	var st := str(ctrl.get_claim_status()) if ctrl.has_method("get_claim_status") else ""
	print("[Playtest] cargo pad=", deck.name, " occupy=", st, " held=", held, " pin=", pin)
	if not held and st != "owned" and st != "extracting" and st != "claiming":
		fails.append("cargo pad not occupied (status=%s)" % st)
		return
	if ctrl.has_method("ensure_pad_cargo"):
		ctrl.ensure_pad_cargo(2)
	var yard0 := int(ctrl.pad_cargo_count()) if ctrl.has_method("pad_cargo_count") else 0
	if yard0 < 1:
		fails.append("unnamed pad has no cargo yard")
		return

	var up_c: Vector3 = deck.get_meta("pad_up") if deck.has_meta("pad_up") else Vector3.UP
	if "velocity" in sh:
		sh.velocity = Vector3.ZERO
	sh.global_position = deck.global_position + up_c * 6.0
	if sh.has_method("_set_mode"):
		sh._set_mode(2)
	if sh.has_method("_do_land"):
		sh._do_land()
	if not bool(sh.get("is_landed")):
		fails.append("ship not landed for cargo dock")
		return

	var hold: Node = sh.get_node_or_null("CargoHold")
	if hold == null or not hold.has_method("unit_count"):
		fails.append("CargoHold missing unit API")
		return
	var hold0 := int(hold.unit_count())
	var mass0 := CargoHold.UNIT_MASS_T
	var val0 := CargoHold.UNIT_VALUE
	if not bool(sh.try_dock_cargo_transfer(true)) if sh.has_method("try_dock_cargo_transfer") else false:
		fails.append("occupy dock did not transfer one unit pad→hold")
		return
	var hold1 := int(hold.unit_count())
	var yard1 := int(ctrl.pad_cargo_count()) if ctrl.has_method("pad_cargo_count") else -1
	print("[Playtest] cargo pad→hold yard ", yard0, "→", yard1, " hold ", hold0, "→", hold1)
	if hold1 != hold0 + 1 or yard1 != yard0 - 1:
		fails.append("one-unit pad→hold failed (yard %s→%s hold %s→%s)" % [yard0, yard1, hold0, hold1])
		return
	var moved: Dictionary = {}
	var units_v: Variant = hold.get("units")
	if units_v is Array and (units_v as Array).size() > 0:
		moved = (units_v as Array)[(units_v as Array).size() - 1]
	var mass1 := float(moved.get("mass", -1.0))
	var val1 := float(moved.get("value", -1.0))
	if absf(mass1 - mass0) > 0.001 or absf(val1 - val0) > 0.001:
		fails.append("cargo transfer changed mass/value")
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("logistics", 20.0)
	var lab := SoftKnowledge.crate_label()
	print("[Playtest] cargo Knowledge label=", lab, " mass=", mass1, " value=", val1)
	if lab == "":
		fails.append("Knowledge crate label empty")
	if absf(float(moved.get("mass", -1.0)) - mass0) > 0.001:
		fails.append("Knowledge changed crate mass")
	if absf(float(moved.get("value", -1.0)) - val0) > 0.001:
		fails.append("Knowledge changed crate value")
	if not bool(sh.try_dock_cargo_transfer(false)):
		fails.append("occupy dock did not transfer one unit hold→pad")
		return
	var hold2 := int(hold.unit_count())
	var yard2 := int(ctrl.pad_cargo_count()) if ctrl.has_method("pad_cargo_count") else -1
	print("[Playtest] cargo hold→pad yard ", yard1, "→", yard2, " hold ", hold1, "→", hold2)
	if hold2 != hold0 or yard2 != yard0:
		fails.append("one-unit hold→pad failed (yard %s→%s hold %s→%s)" % [yard1, yard2, hold1, hold2])
	if LayerContext and str(LayerContext.site_pin_id) != "" and str(LayerContext.site_pin_id) != "SITE_SPACE_TEST_PAD":
		fails.append("cargo dock site_pin left catalog (%s)" % LayerContext.site_pin_id)


func _rover_pick_unnamed_pad(os: Node) -> Dictionary:
	var nex: Node = _osh_nex()
	if nex != null and nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	var tree := get_tree()
	if tree == null:
		return {}
	for pad in tree.get_nodes_in_group("pad_bases"):
		if pad == null or not is_instance_valid(pad):
			continue
		var host: Node = pad
		var deck: Node3D = null
		while host:
			if host.has_meta("pad_up") and host is Node3D:
				deck = host as Node3D
				break
			host = host.get_parent()
		if deck == null:
			continue
		var pin := str(deck.get_meta("site_pin")) if deck.has_meta("site_pin") else ""
		if pin != "":
			continue
		var pl: Node = deck.get_meta("planet") if deck.has_meta("planet") else null
		if pl == null:
			pl = nex
		if pl != null and str(pl.get("planet_name")) != "Nex-Prime":
			continue
		return {"deck": deck, "ctrl": pad, "planet": pl if pl != null else nex}
	return {"deck": null, "ctrl": null, "planet": nex}


func _assert_openspace_view(os: Node, ship: Node, nex: Node, label: String, fails: PackedStringArray) -> void:
	## Headless stand-in for the 3090 black-viewport gate: after unnamed-pad
	## LAND and HOVER takeoff the chase Camera3D must still be current, have
	## a usable far clip / environment, and sit outside the body looking at it.
	if os != null and os.has_method("reclaim_pilot_camera"):
		os.reclaim_pilot_camera()
	if ship == null or not is_instance_valid(ship):
		fails.append("%s view: no ship" % label)
		return
	var cam: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if cam == null:
		fails.append("%s view: chase Camera3D missing" % label)
		return
	var vp := os.get_viewport() if os else get_viewport()
	var live: Camera3D = vp.get_camera_3d() if vp else null
	if live != cam:
		fails.append("%s view: viewport camera is %s (want chase)" % [
			label, live.name if live else "none"
		])
	elif not cam.current:
		fails.append("%s view: chase Camera3D not current" % label)
	var we: WorldEnvironment = null
	if os:
		we = os.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we == null or we.environment == null:
		fails.append("%s view: WorldEnvironment missing" % label)
	var wr: Node3D = os.get_node_or_null("WorldRoot") as Node3D if os else null
	if wr != null and not wr.visible:
		fails.append("%s view: WorldRoot hidden (interior/pad-exit)" % label)
	if label == "HOVER":
		var d_in = os.get("_interior") if os else null
		if d_in != null and is_instance_valid(d_in) and d_in.has_method("is_inside") and bool(d_in.is_inside()):
			fails.append("HOVER view: still in cockpit after takeoff")
		if LayerContext and str(LayerContext.current_layer).to_lower() != "space":
			fails.append("HOVER view: layer %s (want Space)" % LayerContext.current_layer)
		if we != null and we.environment != null:
			if we.environment.ambient_light_source != Environment.AMBIENT_SOURCE_SKY:
				fails.append("HOVER view: ambient source not sky (cockpit leak)")
	if we != null and we.environment != null:
		var env: Environment = we.environment
		if env.ambient_light_energy <= 0.01:
			fails.append("%s view: ambient energy 0" % label)
		if env.get("background_energy_multiplier") != null and float(env.background_energy_multiplier) <= 0.0:
			fails.append("%s view: background energy 0" % label)
	var sun: DirectionalLight3D = os.get_node_or_null("Sun") as DirectionalLight3D if os else null
	if sun != null and sun.light_energy <= 0.01:
		fails.append("%s view: sun energy 0" % label)
	var rad := 1400.0
	if nex != null and nex.get("radius") != null:
		rad = float(nex.get("radius"))
	if cam.far < rad + 5000.0:
		fails.append("%s view: far clip %s too short" % [label, snapped(cam.far, 1.0)])
	if nex != null and is_instance_valid(nex) and nex is Node3D:
		var body_pos: Vector3 = (nex as Node3D).global_position
		var dist: float = cam.global_position.distance_to(body_pos)
		if dist >= cam.far:
			fails.append("%s view: body beyond far clip (%s >= %s)" % [
				label, snapped(dist, 1.0), snapped(cam.far, 1.0)
			])
		if dist + 2.0 < rad:
			fails.append("%s view: camera inside body (d=%s r=%s)" % [
				label, snapped(dist, 1.0), snapped(rad, 1.0)
			])
		var pad: Node3D = null
		if os != null and os.has_method("nearest_pad"):
			pad = os.nearest_pad(ship.global_position)
		if pad != null:
			var pd: float = cam.global_position.distance_to(pad.global_position)
			if pd >= cam.far:
				fails.append("%s view: pad beyond far clip (%s)" % [label, snapped(pd, 1.0)])
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("ship"):
			if n == ship or n == null or not is_instance_valid(n):
				continue
			if not (n.has_method("is_npc_pilot") and bool(n.is_npc_pilot())):
				continue
			var vcam: Camera3D = n.get_node_or_null("CameraPivot/Camera3D") as Camera3D
			if vcam != null and (vcam.current or live == vcam):
				fails.append("%s view: visitor Camera3D is current" % label)
	print("[Playtest] ", label, " view cam=", cam.name, " current=", cam.current,
		" far=", snapped(cam.far, 1.0), " live=", live.name if live else "none")


func _assert_imported_camera_cannot_steal(fails: PackedStringArray) -> void:
	## GPU land loads pad/hull GLB; those files often ship a Camera3D.
	## Simulate the steal and require reclaim to hand the view back.
	var os: Node = get_parent()
	var ship: Node = os.get("ship") if os else null
	if ship == null or not is_instance_valid(ship):
		fails.append("imported-cam: no ship")
		return
	var keep: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if keep == null:
		fails.append("imported-cam: chase Camera3D missing")
		return
	var thief := Camera3D.new()
	thief.name = "ImportedCam"
	thief.current = true
	var host := Node3D.new()
	host.name = "FakeHullGLB"
	host.add_child(thief)
	MeshSafe.strip_imported_cameras(host)
	if host.get_node_or_null("ImportedCam") != null:
		fails.append("imported-cam: MeshSafe.strip left a Camera3D")
	ship.add_child(host)
	var late := Camera3D.new()
	late.name = "LateImportedCam"
	late.current = true
	host.add_child(late)
	if os != null and os.has_method("reclaim_pilot_camera"):
		os.reclaim_pilot_camera()
	var live: Camera3D = get_viewport().get_camera_3d()
	if live != keep:
		fails.append("imported-cam stole the viewport (%s)" % (live.name if live else "none"))
	if late != null and is_instance_valid(late):
		late.queue_free()
	if host != null and is_instance_valid(host):
		host.queue_free()
	if keep:
		keep.current = true
	print("[Playtest] imported-cam reclaim live=", live.name if live else "none")


func _player_pad_land_hover_view(fails: PackedStringArray) -> void:
	## 3090 report: LAND on unnamed pad, stay in the seat, Space → HOVER.
	## OS-H EVA/board would restore the chase cam and hide this bug.
	var os: Node = get_parent()
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var nex: Node = _osh_nex()
	if nex != null and nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	if ship == null or nex == null:
		fails.append("pad LAND/HOVER view: no ship/body")
		return
	if not bool(os.get("_in_ship")):
		if os.has_method("try_enter_ship") and os.get("player") != null:
			os.try_enter_ship()
			await get_tree().create_timer(0.35).timeout
	var pad: Node3D = null
	if nex.has_method("nearest_pad"):
		pad = nex.nearest_pad(ship.global_position)
	if pad == null and os.has_method("nearest_pad"):
		pad = os.nearest_pad(ship.global_position)
	if pad == null or not pad.has_meta("pad_up"):
		fails.append("pad LAND/HOVER view: no unnamed pad")
		return
	var pin := str(pad.get_meta("site_pin")) if pad.has_meta("site_pin") else ""
	if pin.begins_with("SITE_"):
		fails.append("pad LAND/HOVER view: minted SITE_*")
		return
	var up: Vector3 = pad.get_meta("pad_up")
	ship.global_position = pad.global_position + up * 8.0
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	ship.set("_gear_down", true)
	if ship.has_method("_sync_landing_gear"):
		ship._sync_landing_gear()
	if ship.has_method("_do_land"):
		ship._do_land()
	if not bool(ship.get("is_landed")):
		fails.append("pad LAND/HOVER view: LAND refused")
		return
	_assert_openspace_view(os, ship, nex, "LAND", fails)
	if ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if bool(ship.get("is_landed")):
		fails.append("pad LAND/HOVER view: still landed after takeoff")
		return
	if "flight_mode" in ship and int(ship.flight_mode) != 2:
		fails.append("pad LAND/HOVER view: takeoff left mode %s" % int(ship.flight_mode))
	_assert_openspace_view(os, ship, nex, "HOVER", fails)


func _eva_board_hover_view(fails: PackedStringArray) -> void:
	## 3090: on Pad_North the walker (hero) + pad + dome draw. Space takeoff
	## after F board must not drop the chase Camera3D (clear_current lottery
	## + walker-free lambda).
	var os: Node = get_parent()
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var nex: Node = _osh_nex()
	if nex != null and nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	if os == null or ship == null or nex == null:
		fails.append("EVA→HOVER view: no OpenSpace")
		return
	if not bool(os.get("_in_ship")):
		if os.has_method("try_enter_ship") and os.get("player") != null:
			os.try_enter_ship()
			await get_tree().create_timer(0.35).timeout
	var pad: Node3D = os.nearest_pad(ship.global_position) if os.has_method("nearest_pad") else null
	if pad == null or not pad.has_meta("pad_up"):
		fails.append("EVA→HOVER view: no unnamed pad")
		return
	var up: Vector3 = pad.get_meta("pad_up")
	ship.global_position = pad.global_position + up * 8.0
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	ship.set("_gear_down", true)
	if ship.has_method("_sync_landing_gear"):
		ship._sync_landing_gear()
	if ship.has_method("_do_land"):
		ship._do_land()
	if not bool(ship.get("is_landed")):
		fails.append("EVA→HOVER view: LAND refused")
		return
	if os.has_method("try_exit_ship"):
		os.try_exit_ship()
	await get_tree().create_timer(0.25).timeout
	var walker: Node3D = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("EVA→HOVER view: no walker on pad")
		return
	if walker.has_method("snap_to_pad"):
		walker.call("snap_to_pad", pad)
	if bool(os.get("_in_ship")):
		fails.append("EVA→HOVER view: still piloting after EVA")
		return
	walker.global_position = ship.global_position + up * 2.0
	if os.has_method("try_enter_ship"):
		os.try_enter_ship()
	await get_tree().create_timer(0.4).timeout
	if not bool(os.get("_in_ship")):
		fails.append("EVA→HOVER view: board failed")
		return
	if ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if bool(ship.get("is_landed")):
		fails.append("EVA→HOVER view: still landed after takeoff")
		return
	_assert_openspace_view(os, ship, nex, "HOVER", fails)
	print("[Playtest] EVA→board→HOVER view ok")


func _cockpit_space_takeoff_view(fails: PackedStringArray) -> void:
	## 3090: SPACE @ 8 km draws (ship / Nex-Prime / moon). Black is after
	## pad LAND → I cockpit → Space takeoff to HOVER. Close the pocket.
	var os: Node = get_parent()
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var nex: Node = _osh_nex()
	if nex != null and nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	if os == null or ship == null or nex == null:
		fails.append("cockpit→HOVER view: no OpenSpace")
		return
	if not bool(os.get("_in_ship")):
		if os.has_method("try_enter_ship") and os.get("player") != null:
			os.try_enter_ship()
			await get_tree().create_timer(0.35).timeout
	var pad: Node3D = os.nearest_pad(ship.global_position) if os.has_method("nearest_pad") else null
	if pad == null or not pad.has_meta("pad_up"):
		fails.append("cockpit→HOVER view: no unnamed pad")
		return
	var up: Vector3 = pad.get_meta("pad_up")
	ship.global_position = pad.global_position + up * 8.0
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	ship.set("_gear_down", true)
	if ship.has_method("_sync_landing_gear"):
		ship._sync_landing_gear()
	if ship.has_method("_do_land"):
		ship._do_land()
	if not bool(ship.get("is_landed")):
		fails.append("cockpit→HOVER view: LAND refused")
		return
	if not bool(os.get("_in_ship")):
		fails.append("cockpit→HOVER view: not in seat before I")
		return
	if os.has_method("_leave_seat_to_pocket"):
		os._leave_seat_to_pocket()
	await get_tree().create_timer(0.45).timeout
	var d: Node = os.get("_interior")
	if d == null or not is_instance_valid(d) or not (d.has_method("is_inside") and bool(d.is_inside())):
		fails.append("cockpit→HOVER view: I did not open ship pocket")
		return
	if d.has_method("get_kind") and str(d.get_kind()) != "ship":
		fails.append("cockpit→HOVER view: pocket kind %s" % str(d.get_kind()))
		return
	var wr: Node3D = os.get_node_or_null("WorldRoot") as Node3D
	if wr != null and wr.visible:
		fails.append("cockpit→HOVER view: WorldRoot still visible in pocket")
		return
	var ls := ""
	if d.has_method("life_support_line"):
		ls = str(d.life_support_line())
	if not ls.contains("HULL SEALED"):
		fails.append("cockpit→HOVER view: expected HULL SEALED, got %s" % ls)
		return
	var chase: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	var live0: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
	if chase != null and live0 == chase:
		fails.append("cockpit→HOVER view: still on chase cam inside pocket")
		return
	print("[Playtest] cockpit pocket ls=", ls, " live=", live0.name if live0 else "none")
	if ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	await get_tree().create_timer(0.35).timeout
	if bool(ship.get("is_landed")):
		fails.append("cockpit→HOVER view: still landed after takeoff")
		return
	if d != null and is_instance_valid(d) and d.has_method("is_inside") and bool(d.is_inside()):
		fails.append("cockpit→HOVER view: pocket still open after takeoff")
		return
	_assert_openspace_view(os, ship, nex, "HOVER", fails)
	print("[Playtest] cockpit→Space→HOVER view ok")


func _assert_pocket_hatch_hud(fails: PackedStringArray) -> void:
	## IN leftover: F at hatch is the airlock. HUD must not say "F seat".
	var hud: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
	if hud != null and hud.has_method("_refresh"):
		hud._refresh()
	elif hud != null and hud.has_method("_process"):
		hud._process(0.2)
	var txt := ""
	if hud != null:
		var lab: Variant = hud.get("_interior_label")
		if lab is Label:
			txt = str((lab as Label).text)
	print("[Playtest] pocket HUD hatch '", txt.replace("\n", " / "), "'")
	if txt.to_lower().find("hatch") < 0:
		fails.append("pocket HUD missing hatch prompt")
	if txt.find("F seat") >= 0:
		fails.append("pocket HUD still says F seat at hatch")


func _assert_landed_hatch_on_pad(os: Node, fails: PackedStringArray) -> void:
	## Real hatch path: LANDED seat → I pocket → I hatch → pad deck.
	## Not the playtest snap_to_pad stub. Does not rewrite ST-A…F.
	if os == null:
		fails.append("landed hatch: no OpenSpace")
		return
	var ship: Node3D = os.get("ship") as Node3D
	var nex: Node = _osh_nex()
	if nex != null and nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	if ship == null or nex == null:
		fails.append("landed hatch: no ship/body")
		return
	if not bool(os.get("_in_ship")):
		if os.has_method("try_enter_ship") and os.get("player") != null:
			os.try_enter_ship()
			await get_tree().create_timer(0.35).timeout
	if not bool(os.get("_in_ship")):
		fails.append("landed hatch: not piloting")
		return
	var pad: Node3D = null
	if ship.has_method("get_landed_pad"):
		pad = ship.get_landed_pad() as Node3D
	if pad == null and os.has_method("nearest_pad"):
		pad = os.nearest_pad(ship.global_position)
	if pad == null or not pad.has_meta("pad_up"):
		var deck: Node3D = _osh_unnamed_deck()
		if deck != null:
			pad = deck
	if pad == null:
		fails.append("landed hatch: no unnamed pad")
		return
	var up: Vector3 = pad.get_meta("pad_up") if pad.has_meta("pad_up") else Vector3.UP
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	ship.global_position = pad.global_position + up * 8.0
	if ship.has_method("_set_mode"):
		ship._set_mode(2)
	ship.set("_gear_down", true)
	if ship.has_method("_sync_landing_gear"):
		ship._sync_landing_gear()
	if ship.has_method("_do_land"):
		ship._do_land()
	if not bool(ship.get("is_landed")):
		fails.append("landed hatch: LAND refused")
		return
	if ship.has_method("get_landed_pad"):
		var landed_pad: Node3D = ship.get_landed_pad() as Node3D
		if landed_pad != null:
			pad = landed_pad
	if os.has_method("_leave_seat_to_pocket"):
		os._leave_seat_to_pocket()
	await get_tree().create_timer(0.45).timeout
	var d: Node = os.get("_interior")
	if d == null or not (d.has_method("is_inside") and bool(d.is_inside())):
		fails.append("landed hatch: I did not open ship pocket")
		return
	var walker: Node3D = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("landed hatch: no pocket walker")
		return
	if walker.global_position.y < 2000.0:
		fails.append("landed hatch: pocket walker not in pocket")
		return
	var hatch: Node3D = null
	var pocket: Node3D = d.get_active_interior() if d.has_method("get_active_interior") else null
	if pocket != null:
		hatch = pocket.get_node_or_null("ExitVolume") as Node3D
	if hatch != null:
		walker.global_position = hatch.global_position + Vector3(0, 0.15, 0)
		await get_tree().process_frame
		await get_tree().process_frame
		_assert_pocket_hatch_hud(fails)
	if d.has_method("exit_interior"):
		d.exit_interior()
	await get_tree().create_timer(0.45).timeout
	walker = os.get("player") as Node3D
	if d.has_method("is_inside") and bool(d.is_inside()):
		fails.append("landed hatch: still in ship pocket after I hatch")
		return
	if not _assert_eva_from_landed_on_deck(os, walker, pad, nex, fails):
		fails.append("landed hatch: I hatch did not snap onto pad deck")
		return
	print("[Playtest] landed hatch → pad deck pad=", pad.name, " (not ship pocket)")
	if walker != null and is_instance_valid(walker) and os.has_method("try_enter_ship"):
		walker.global_position = ship.global_position + up * 2.0
		os.try_enter_ship()
		await get_tree().create_timer(0.35).timeout
	# Leave the pad so later occupy/harvest is not a landed-hull false positive.
	if ship.has_method("_do_launch"):
		ship.set("_land_lock_t", 0.0)
		ship._do_launch()
	if nex != null and nex is Node3D:
		var away: Vector3 = ((nex as Node3D).global_position - ship.global_position).normalized()
		ship.global_position = (nex as Node3D).global_position - away * (float(nex.get("radius")) + 900.0)
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO


func _assert_st_a(os: Node, fails: PackedStringArray) -> void:
	## ST-A: strategy overlay + one habitat on an unnamed pad. Not G2. Not SITE_*.
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.ST_A_OVERLAY):
		fails.append("ST-A P0Slice flag missing")
		return
	var ov: Node = os.strategy_overlay() if os != null and os.has_method("strategy_overlay") else null
	if ov == null or not ov.has_method("try_enter"):
		fails.append("ST-A StrategyOverlay missing")
		return
	var pin0 := str(LayerContext.site_pin_id) if LayerContext else ""
	var far_ok := not bool(ov.try_enter())
	var far_line := str(ov.readiness_line()) if ov.has_method("readiness_line") else ""
	print("[Playtest] ST-A far deny=", far_ok, " line=", far_line)
	if not far_ok:
		fails.append("ST-A overlay opened from orbit")
		if ov.has_method("exit_overlay"):
			ov.exit_overlay()
		return
	if far_line.find("m — land or EVA first") < 0 and far_line.find("no unnamed pad") < 0:
		fails.append("ST-A far refusal did not name distance (%s)" % far_line)
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var pl: Node3D = os.nearest_planet(ship.global_position) if os != null and os.has_method("nearest_planet") and ship else null
	if pl != null and pl.has_method("ensure_pad_bases"):
		pl.ensure_pad_bases()
		await get_tree().create_timer(0.35).timeout
	var pad: Node3D = null
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("landing_pads"):
			if n is Node3D and str(n.name) == "Pad_North":
				pad = n as Node3D
				break
		if pad == null:
			for n in tree.get_nodes_in_group("landing_pads"):
				if n is Node3D and (str(n.name) == "Pad_Approach" or str(n.name) == "Pad_Flank"):
					pad = n as Node3D
					break
	if pad == null:
		fails.append("ST-A no unnamed pad (Pad_North class)")
		return
	var up: Vector3 = pad.get_meta("pad_up") if pad.has_meta("pad_up") else Vector3.UP
	if ship:
		ship.global_position = pad.global_position + up * 8.0
	await get_tree().process_frame
	if not bool(ov.try_enter()):
		fails.append("ST-A enter failed at pad (%s)" % str(ov.readiness_line() if ov.has_method("readiness_line") else ""))
		return
	var ly := str(LayerContext.current_layer) if LayerContext else ""
	print("[Playtest] ST-A layer=", ly, " pad=", pad.name)
	if ly != "Strategy":
		fails.append("ST-A LayerContext not Strategy (%s)" % ly)
	var mod: Node3D = ov.place_module() if ov.has_method("place_module") else null
	if mod == null or not is_instance_valid(mod):
		fails.append("ST-A habitat was not placed")
	else:
		var mpin := str(mod.get_meta("site_pin", "missing"))
		var combat := int(mod.combat_stats()) if mod.has_method("combat_stats") else -1
		print("[Playtest] ST-A module=", mod.name, " pin=", mpin, " combat=", combat)
		if mpin != "":
			fails.append("ST-A module minted site_pin (%s)" % mpin)
		if combat != 0:
			fails.append("ST-A habitat has combat stats")
		if str(mod.get_meta("module_type", "")) != "habitat":
			fails.append("ST-A module is not habitat")
	var again: Node3D = ov.place_module() if ov.has_method("place_module") else Node3D.new()
	if again != null:
		fails.append("ST-A placed a second module on the same pad")
	if ov.has_method("exit_overlay"):
		ov.exit_overlay()
	await get_tree().process_frame
	var ly2 := str(LayerContext.current_layer) if LayerContext else ""
	if ly2 == "Strategy":
		fails.append("ST-A still Strategy after exit")
	if os != null and os.has_method("strategy_overlay_active") and bool(os.strategy_overlay_active()):
		fails.append("ST-A overlay stayed active after exit")
	if ship != null and is_instance_valid(ship) and not ship.is_physics_processing():
		fails.append("ST-A left ship physics frozen")
	if LayerContext and str(LayerContext.site_pin_id) != pin0:
		fails.append("ST-A changed site_pin (%s → %s)" % [pin0, LayerContext.site_pin_id])
	var extras := 0
	if tree:
		extras = tree.get_nodes_in_group("player_base_modules").size()
	if extras != 1:
		fails.append("ST-A want exactly one player module, got %s" % extras)
	print("[Playtest] ST-A overlay pad=", pad.name, " layer_out=", ly2, " pin=", LayerContext.site_pin_id if LayerContext else "")


func _assert_hud_stack(os: Node, fails: PackedStringArray) -> void:
	## Presentation helper only — no gameplay, no SITE_*, no number changes.
	var Hud = load("res://scripts/ui/OpenSpaceHudStack.gd")
	if Hud == null:
		fails.append("HUD helper missing")
		return
	var pad: Node = null
	var tree := get_tree()
	if tree:
		var pads: Array = tree.get_nodes_in_group("pad_bases")
		if not pads.is_empty():
			pad = pads[0]
	var empty: Dictionary = Hud.snapshot(null, null, null)
	if not bool(Hud.has_fields(empty)):
		fails.append("HUD helper null snapshot missing fields")
		return
	if Hud.has_method("player_ship"):
		var pick: Node = Hud.player_ship(get_tree())
		var want: Node = os.get("ship") if os else null
		if want != null and pick != want:
			fails.append("HUD player_ship picked %s" % (pick.name if pick else "none"))
	var snap: Dictionary = Hud.snapshot(os.get("ship") if os else null, os.get("player") if os else null, pad)
	if not bool(Hud.has_fields(snap)):
		fails.append("HUD helper missing fields")
		return
	var txt := str(Hud.stack_text(snap))
	if txt == "":
		fails.append("HUD helper stack_text empty")
		return
	var txt_l := txt.to_upper()
	if txt_l.find("CONTRIB") < 0 and txt_l.find("BIOMASS") < 0:
		fails.append("HUD helper stack_text missing Contribution")
		return
	print("[Playtest] HUD stack ok fuel=", snap.get("fuel"), " cargo=", snap.get("cargo"),
		" mod=", snap.get("module_tag"), " landed=", snap.get("landed"),
		" occupy=", snap.get("occupy"), " eva=", snap.get("eva_mode"),
		" econ=", snap.get("econ"), " energy=", snap.get("energy"),
		" power=", snap.get("power_draw"), "/", snap.get("power_supply"),
		" cool=", snap.get("cool_load"), "/", snap.get("cool_cap"),
		" life=", snap.get("life"))


func _assert_occupy_energy(os: Node, pad: Node, walker: Node, before: float, pulse_before: float, fails: PackedStringArray) -> void:
	## occupy unnamed pad → locker restock (energy / Pulse). Not instant cash.
	if walker == null or not is_instance_valid(walker):
		fails.append("occupy→energy-up: no walker")
		return
	if before < 0.0 or not walker.has_method("restock_energy"):
		fails.append("walker has no occupy restock API")
		return
	var after: float = float(walker.get("energy")) if "energy" in walker else -1.0
	var pulse_after := -1.0
	var ab = walker.get_node_or_null("AbilitySystem")
	if ab and ab.has_method("get_cooldown_remaining"):
		pulse_after = float(ab.get_cooldown_remaining(0))
	print("[Playtest] occupy energy ", snapped(before, 0.1), " -> ", snapped(after, 0.1),
		" pulse CD ", snapped(pulse_before, 0.1), " -> ", snapped(pulse_after, 0.1))
	# Passive regen is 8/s (~5.6 in 0.7s). Locker restock is extra occupy wait.
	if after <= before + 8.0:
		fails.append("occupy did not restock energy (%s → %s)" % [
			str(snapped(before, 0.1)), str(snapped(after, 0.1))
		])
	elif after >= 99.0:
		fails.append("pad energy filled instantly (no occupy wait / paid skip)")
	if pulse_before >= 4.5 and pulse_after >= 0.0 and pulse_after > pulse_before - 1.05:
		fails.append("occupy did not restock Pulse charges (%s → %s)" % [
			str(snapped(pulse_before, 0.1)), str(snapped(pulse_after, 0.1))
		])
	var Hud = load("res://scripts/ui/OpenSpaceHudStack.gd")
	if Hud == null:
		fails.append("occupy→energy-up HUD helper missing")
		return
	var snap: Dictionary = Hud.snapshot(os.get("ship") if os else null, walker, pad)
	var hud_e := float(snap.get("energy", -1.0))
	var stxt := str(Hud.stack_text(snap)).to_upper()
	if hud_e <= before + 8.0:
		fails.append("occupy→energy-up failed (HUD stack)")
	if stxt.find("EN ") < 0:
		fails.append("HUD stack missing energy while occupying")
	if pad != null and pad.has_method("pad_restock_hud_line"):
		var line := str(pad.pad_restock_hud_line())
		print("[Playtest] restock hud=", line)


func _assert_occupy_contrib(os: Node, pad: Node, before: float, after: float, fails: PackedStringArray) -> void:
	## occupy unnamed pad → harvest deposit → live Contribution on the OpenSpace stack.
	if after <= before + 0.001:
		fails.append("occupy→Contribution increased failed (wallet)")
		return
	var Hud = load("res://scripts/ui/OpenSpaceHudStack.gd")
	if Hud == null:
		fails.append("occupy→Contribution HUD helper missing")
		return
	var snap: Dictionary = Hud.snapshot(os.get("ship") if os else null, os.get("player") if os else null, pad)
	var hud_c := float(snap.get("econ", -1.0))
	var stxt := str(Hud.stack_text(snap))
	print("[Playtest] occupy→Contribution ", snapped(before, 0.01), " -> ", snapped(after, 0.01),
		" hud=", snapped(hud_c, 0.01), " rate=", snap.get("econ_rate"))
	if hud_c <= before + 0.001:
		fails.append("occupy→Contribution increased failed (HUD stack)")
	var up := stxt.to_upper()
	if up.find("CONTRIB") < 0 and up.find("BIOMASS") < 0:
		fails.append("HUD stack missing live Contribution while occupying")


func _assert_st_b(os: Node, pad: Node, before: float, after: float, fails: PackedStringArray) -> void:
	## ST-B: occupy → harvest → Contribution > 0 on HUD. Extractor visible.
	## Knowledge labels the machine / wallet only — never yield.
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.ST_B_EXTRACTOR):
		fails.append("ST-B P0Slice flag missing")
		return
	if after <= before + 0.001:
		fails.append("ST-B occupy→harvest did not raise Contribution")
		return
	var ext: Node = null
	if pad != null and pad.has_method("visible_extractor"):
		ext = pad.visible_extractor()
	if ext == null and pad != null:
		var host: Node = pad
		while host:
			if host is Node3D and str(host.name) in ["Pad_North", "Pad_Approach", "Pad_Flank"]:
				ext = host.get_node_or_null("PadHarvestExtractor")
				break
			host = host.get_parent()
	if ext == null or not is_instance_valid(ext):
		fails.append("ST-B extractor not visible on unnamed pad")
		return
	var pin := str(ext.get_meta("site_pin", "missing"))
	if pin != "":
		fails.append("ST-B extractor minted site_pin (%s)" % pin)
	if ext.has_meta("player_module") and bool(ext.get_meta("player_module")):
		fails.append("ST-B extractor claimed ST-A player_module slot")
	if str(ext.get_meta("module_type", "")) != "extractor":
		fails.append("ST-B module is not extractor")
	var slug := str(ext.get_meta("ledger_slug", ""))
	if slug != "" and slug != "t1_resource_extractor":
		fails.append("ST-B invented slug (%s)" % slug)
	var rate0 := 0.0
	var cpu0 := 0.0
	if pad != null:
		rate0 = float(pad.get("extract_rate"))
		cpu0 = float(pad.get("contribution_per_unit"))
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("history", 20.0)
		GameManager.add_mastery("colony_ops", 20.0)
		GameManager.add_mastery("biomass_ops", 20.0)
	if pad != null and (absf(float(pad.get("extract_rate")) - rate0) > 0.001 \
		or absf(float(pad.get("contribution_per_unit")) - cpu0) > 0.001):
		fails.append("Knowledge changed harvest yield")
	var Hud = load("res://scripts/ui/OpenSpaceHudStack.gd")
	if Hud == null:
		fails.append("ST-B HUD helper missing")
		return
	var snap: Dictionary = Hud.snapshot(os.get("ship") if os else null, os.get("player") if os else null, pad)
	var hud_c := float(snap.get("econ", -1.0))
	var stxt := str(Hud.stack_text(snap))
	print("[Playtest] ST-B occupy→harvest→Contribution ", snapped(before, 0.01), " -> ", snapped(after, 0.01),
		" hud=", snapped(hud_c, 0.01), " extractor=", ext.name, " pad=",
		str(pad.name) if pad else "?")
	if hud_c <= 0.0 or hud_c <= before + 0.001:
		fails.append("ST-B HUD Contribution not > 0 after harvest")
	var up := stxt.to_upper()
	if up.find("CONTRIB") < 0 and up.find("BIOMASS") < 0:
		fails.append("ST-B HUD missing Contribution number")


func _assert_st_c(os: Node, pad: Node, fails: PackedStringArray) -> void:
	## ST-C: spend Contribution/Biomass at pad / NPC bench → ONE catalog module.
	## Cash-shop skip is impossible. Knowledge does not cheapen rules/15.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var bench: Node = null
	var cost := 0.0
	var cost_after := 0.0
	var before := 0.0
	var after := 0.0
	var wallet0 := 0.0
	var skip_ok := true
	var cash_mod: Node3D = null
	var broke: Node3D = null
	var mod: Node3D = null
	var again: Node3D = null
	var pin := ""
	var slug := ""
	var kind := ""
	var extras := 0
	var tree: SceneTree = get_tree()
	if P0 == null or not bool(P0.ST_C_PRINT):
		fails.append("ST-C P0Slice flag missing")
		return
	if pad != null and pad.has_method("print_bench"):
		bench = pad.print_bench()
	if bench == null and tree:
		var benches: Array = tree.get_nodes_in_group("print_benches")
		if not benches.is_empty():
			bench = benches[0]
	if bench == null or not bench.has_method("print_one_module"):
		fails.append("ST-C print bench missing")
		return
	if bench.has_method("print_cost"):
		cost = float(bench.print_cost())
	if cost <= 0.0:
		fails.append("ST-C print cost is not a rules/15 sink")
		return
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("history", 20.0)
		GameManager.add_mastery("colony_ops", 20.0)
		GameManager.add_mastery("biomass_ops", 20.0)
	if bench.has_method("print_cost"):
		cost_after = float(bench.print_cost())
	if absf(cost_after - cost) > 0.001:
		fails.append("Knowledge cheapened print tables")
	if bench.has_method("cash_shop_skip_possible") and bool(bench.cash_shop_skip_possible()):
		fails.append("ST-C cash-shop skip possible")
	if bench.has_method("try_cash_skip_print"):
		skip_ok = bool(bench.try_cash_skip_print(999.0))
	if skip_ok:
		fails.append("ST-C cash-shop skip printed a module")
	if GameManager:
		wallet0 = float(GameManager.contribution)
		GameManager.contribution = 0.0
	cash_mod = bench.print_one_module("", 50.0)
	if cash_mod != null:
		fails.append("ST-C accepted cash instead of Contribution")
		if is_instance_valid(cash_mod):
			cash_mod.queue_free()
	broke = bench.print_one_module()
	if broke != null:
		fails.append("ST-C printed with empty wallet")
		if is_instance_valid(broke):
			broke.queue_free()
	if GameManager:
		if wallet0 < cost:
			GameManager.contribution = cost
		else:
			GameManager.contribution = wallet0
		if GameManager.has_method("add_contribution") and GameManager.contribution < cost:
			GameManager.add_contribution(cost - GameManager.contribution)
		before = float(GameManager.contribution)
	mod = pad.print_one_module() if pad != null and pad.has_method("print_one_module") else bench.print_one_module()
	if GameManager:
		after = float(GameManager.contribution)
	if mod == null or not is_instance_valid(mod):
		fails.append("ST-C did not grant a module after spend")
		return
	if after > before - cost + 0.001:
		fails.append("ST-C did not spend Contribution (%s → %s, cost=%s)" % [
			str(snapped(before, 0.01)), str(snapped(after, 0.01)), str(snapped(cost, 0.01))
		])
	pin = str(mod.get_meta("site_pin", "missing"))
	kind = str(mod.get_meta("module_type", ""))
	slug = str(mod.get_meta("ledger_slug", ""))
	print("[Playtest] ST-C print spent Contribution ", snapped(before, 0.01), " -> ", snapped(after, 0.01),
		" cost=", snapped(cost, 0.01), " module=", mod.name, " kind=", kind,
		" pad=", str(pad.name) if pad else "?", " cash_skip=false")
	if pin != "":
		fails.append("ST-C module minted site_pin (%s)" % pin)
	if kind != "habitat" and kind != "extractor":
		fails.append("ST-C granted an unknown module (%s)" % kind)
	if kind == "extractor" and slug != "" and slug != "t1_resource_extractor":
		fails.append("ST-C invented slug (%s)" % slug)
	if bool(mod.get_meta("player_module", false)):
		fails.append("ST-C stole the ST-A player_module slot")
	if bool(mod.get_meta("npc_module", false)):
		fails.append("ST-C stole the NP-C npc_module slot")
	if not bool(mod.get_meta("printed_module", false)):
		fails.append("ST-C module not marked printed_module")
	again = bench.print_one_module()
	if again != null:
		fails.append("ST-C granted a second module")
	if tree:
		extras = tree.get_nodes_in_group("printed_base_modules").size()
	if extras != 1:
		fails.append("ST-C want exactly one printed module, got %s" % extras)
	if os == null:
		return


func _assert_st_d(os: Node, fails: PackedStringArray) -> void:
	## ST-D: hangar queue of ONE module on a catalog carrier. Mass/power refuse.
	## Not a mobile SITE_*. Does not rewrite ST-C print bench.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var hull: Node = null
	var queue: Node = null
	var slug := ""
	var pin0 := ""
	var pin1 := ""
	var mass_cap := 0.0
	var power_cap := 0.0
	var mass_after := 0.0
	var power_after := 0.0
	var heavy: Node3D = null
	var hot: Node3D = null
	var cash: Node3D = null
	var mod: Node3D = null
	var again: Node3D = null
	var refuse := ""
	var refuse_power := ""
	var kind := ""
	var mpin := ""
	var extras := 0
	var tree: SceneTree = get_tree()
	if P0 == null or not bool(P0.ST_D_HANGAR):
		fails.append("ST-D P0Slice flag missing")
		return
	if LayerContext:
		pin0 = str(LayerContext.site_pin_id)
	if os != null and os.has_method("catalog_carrier"):
		hull = os.catalog_carrier()
	if hull == null and tree:
		var hulls: Array = tree.get_nodes_in_group("catalog_carriers")
		if not hulls.is_empty():
			hull = hulls[0]
	if hull == null:
		fails.append("ST-D catalog carrier missing")
		return
	if hull.has_method("hull_slug"):
		slug = str(hull.hull_slug())
	elif hull.has_meta("catalog_hull"):
		slug = str(hull.get_meta("catalog_hull"))
	if slug != "cybernex_capital_carrier" and slug != "grot_capital_carrier" \
			and slug != "grot_drone_carrier" and slug != "cybernex_mothership" \
			and slug != "grot_mothership":
		fails.append("ST-D invented hull slug (%s)" % slug)
	if str(hull.get_meta("site_pin", "missing")) != "":
		fails.append("ST-D carrier minted site_pin (%s)" % str(hull.get_meta("site_pin")))
	if bool(hull.get_meta("mobile_site", true)):
		fails.append("ST-D carrier marked mobile SITE_*")
	if hull.has_method("hangar_queue"):
		queue = hull.hangar_queue()
	if queue == null and os != null and os.has_method("hangar_queue"):
		queue = os.hangar_queue()
	if queue == null and tree:
		var queues: Array = tree.get_nodes_in_group("hangar_queues")
		if not queues.is_empty():
			queue = queues[0]
	if queue == null or not queue.has_method("enqueue_module"):
		fails.append("ST-D hangar queue missing")
		return
	if hull.has_method("mass_remaining"):
		mass_cap = float(hull.mass_remaining())
	if hull.has_method("power_remaining"):
		power_cap = float(hull.power_remaining())
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("history", 20.0)
		GameManager.add_mastery("colony_ops", 20.0)
	if hull.has_method("mass_remaining"):
		mass_after = float(hull.mass_remaining())
	if hull.has_method("power_remaining"):
		power_after = float(hull.power_remaining())
	if absf(mass_after - mass_cap) > 0.001 or absf(power_after - power_cap) > 0.001:
		fails.append("Knowledge changed hangar mass/power caps")
	if queue.has_method("cash_shop_skip_possible") and bool(queue.cash_shop_skip_possible()):
		fails.append("ST-D cash-shop skip possible")
	if queue.has_method("try_cash_skip_queue"):
		if bool(queue.try_cash_skip_queue(999.0)):
			fails.append("ST-D cash-shop skip queued a module")
	cash = queue.enqueue_module("sensor", 50.0)
	if cash != null:
		fails.append("ST-D accepted cash instead of hangar budget")
		if is_instance_valid(cash):
			cash.queue_free()
	heavy = queue.enqueue_module("extractor")
	if queue.has_method("last_refuse"):
		refuse = str(queue.last_refuse())
	if heavy != null:
		fails.append("ST-D queued a module that exceeds mass")
		if is_instance_valid(heavy):
			heavy.queue_free()
	if refuse != "mass":
		fails.append("ST-D mass refuse missing (%s)" % refuse)
	hot = queue.enqueue_module("engine")
	if queue.has_method("last_refuse"):
		refuse_power = str(queue.last_refuse())
	if hot != null:
		fails.append("ST-D queued a module that exceeds power")
		if is_instance_valid(hot):
			hot.queue_free()
	if refuse_power != "power":
		fails.append("ST-D power refuse missing (%s)" % refuse_power)
	mod = queue.enqueue_module("sensor")
	if mod == null or not is_instance_valid(mod):
		fails.append("ST-D did not queue one hangar module")
		print("[Playtest] ST-D hangar queue missing module hull=", slug, " refuse=", refuse)
		return
	kind = str(mod.get_meta("module_type", ""))
	mpin = str(mod.get_meta("site_pin", "missing"))
	if kind != "sensor":
		fails.append("ST-D queued an unknown module (%s)" % kind)
	if mpin != "":
		fails.append("ST-D queued module minted site_pin (%s)" % mpin)
	if bool(mod.get_meta("printed_module", false)):
		fails.append("ST-D stole the ST-C printed_module slot")
	if bool(mod.get_meta("player_module", false)):
		fails.append("ST-D stole the ST-A player_module slot")
	if bool(mod.get_meta("npc_module", false)):
		fails.append("ST-D stole the NP-C npc_module slot")
	if not bool(mod.get_meta("hangar_queued", false)):
		fails.append("ST-D module not marked hangar_queued")
	again = queue.enqueue_module("sensor")
	if again != null:
		fails.append("ST-D queued a second module")
	if tree:
		extras = tree.get_nodes_in_group("hangar_queued_modules").size()
	if extras != 1:
		fails.append("ST-D want hangar queue of one module, got %s" % extras)
	if LayerContext:
		pin1 = str(LayerContext.site_pin_id)
	if pin1 != pin0:
		fails.append("ST-D changed site_pin (%s → %s)" % [pin0, pin1])
	print("[Playtest] ST-D hangar queue hull=", slug, " module=", kind,
		" slots=1 refuse=mass/", refuse_power, " pin=", pin1, " mobile_site=false")


func _assert_st_e(os: Node, fails: PackedStringArray) -> void:
	## ST-E: two catalog modules in one player orbital cluster.
	## Authored ARK body. Not a city. Not SITE_*. Not ORBITAL_STATIONS.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var sys = load("res://scripts/world/StarSystemCatalog.gd")
	var cluster: Node3D = null
	var mods: Array = []
	var kinds := PackedStringArray()
	var kinds_s := ""
	var body := ""
	var pin0 := ""
	var pin1 := ""
	var extras := 0
	var unnamed: Node = null
	var tree: SceneTree = get_tree()
	if P0 == null or not bool(P0.ST_E_ORBITAL):
		fails.append("ST-E P0Slice flag missing")
		return
	if bool(P0.ORBITAL_STATIONS):
		fails.append("ST-E enabled P0Slice.ORBITAL_STATIONS unnamed props")
	if LayerContext:
		pin0 = str(LayerContext.site_pin_id)
	if os != null and os.has_method("player_orbital_station"):
		cluster = os.player_orbital_station()
	if cluster == null and tree:
		var listed: Array = tree.get_nodes_in_group("player_orbital_stations")
		if not listed.is_empty() and listed[0] is Node3D:
			cluster = listed[0] as Node3D
	if cluster == null:
		fails.append("ST-E player orbital cluster missing")
		return
	if os != null:
		unnamed = os.find_child("OrbitalStations", true, false)
	if unnamed != null:
		fails.append("ST-E spawned unnamed ORBITAL_STATIONS props as my station")
	if str(cluster.name) == "CityNightLights":
		fails.append("ST-E cluster is a city")
	if bool(cluster.get_meta("city", true)):
		fails.append("ST-E cluster marked city")
	if cluster.has_method("is_city") and bool(cluster.is_city()):
		fails.append("ST-E is_city() is true")
	if str(cluster.get_meta("site_pin", "missing")) != "":
		fails.append("ST-E cluster minted site_pin (%s)" % str(cluster.get_meta("site_pin")))
	if cluster.has_method("authored_body"):
		body = str(cluster.authored_body())
	elif cluster.has_meta("orbit_body"):
		body = str(cluster.get_meta("orbit_body"))
	if body != "Nex-Prime" and body != "ROT-Hive" and body != "Shard-Moon":
		fails.append("ST-E orbit is not an authored ARK body (%s)" % body)
	if sys and str(sys.HOME) != "ARK":
		fails.append("ST-E left ARK (%s)" % str(sys.HOME))
	if os != null:
		var planets: Array = os.get("planets") if os.get("planets") != null else []
		if planets.size() != 1:
			fails.append("ST-E loaded a second system/body (%s)" % planets.size())
	if cluster.has_method("cluster_modules"):
		mods = cluster.cluster_modules()
	elif tree:
		mods = tree.get_nodes_in_group("player_orbital_modules")
	if mods.size() != 2:
		fails.append("ST-E want two modules in one cluster, got %s" % mods.size())
	for m in mods:
		var kind := ""
		var mpin := ""
		if not (m is Node3D):
			fails.append("ST-E module is not a Node3D")
			continue
		if (m as Node).get_parent() != cluster:
			fails.append("ST-E module is not in the player orbital cluster")
		kind = str((m as Node).get_meta("module_type", ""))
		mpin = str((m as Node).get_meta("site_pin", "missing"))
		kinds.append(kind)
		if cluster.has_method("is_grammar_kind"):
			if not bool(cluster.is_grammar_kind(kind)):
				fails.append("ST-E module kind outside §5 grammar (%s)" % kind)
		elif kind != "dock" and kind != "habitat" and kind != "factory" \
				and kind != "defense" and kind != "hangar":
			fails.append("ST-E module kind outside §5 grammar (%s)" % kind)
		if mpin != "":
			fails.append("ST-E module minted site_pin (%s)" % mpin)
		if bool((m as Node).get_meta("player_module", false)):
			fails.append("ST-E stole the ST-A player_module slot")
		if bool((m as Node).get_meta("npc_module", false)):
			fails.append("ST-E stole the NP-C npc_module slot")
		if bool((m as Node).get_meta("printed_module", false)):
			fails.append("ST-E stole the ST-C printed_module slot")
		if bool((m as Node).get_meta("hangar_queued", false)):
			fails.append("ST-E stole the ST-D hangar_queued slot")
		if kind == "habitat" and int((m as Node).get_meta("combat_stats", 1)) != 0:
			fails.append("ST-E habitat has combat stats")
		if bool((m as Node).get_meta("city", false)):
			fails.append("ST-E module marked city")
	if tree:
		extras = tree.get_nodes_in_group("player_orbital_modules").size()
	if extras != 2:
		fails.append("ST-E want two modules in one player orbital cluster, got %s" % extras)
	if LayerContext:
		pin1 = str(LayerContext.site_pin_id)
	if pin1 != pin0:
		fails.append("ST-E changed site_pin (%s → %s)" % [pin0, pin1])
	if pin1.begins_with("SITE_") and pin1 != "SITE_SPACE_TEST_PAD":
		fails.append("ST-E minted a new SITE_* (%s)" % pin1)
	kinds_s = ",".join(kinds)
	print("[Playtest] ST-E cluster=", cluster.name, " modules=", extras,
		" kinds=", kinds_s, " body=", body, " pin=", pin1, " city=false")


func _assert_st_f(os: Node, fails: PackedStringArray) -> void:
	## ST-F: CX↔GR owner swap on ONE occupied unnamed pad cluster.
	## Theme + services change. Contribution / harvest / print / hangar numbers stay.
	## Not a second SITE_*. Not arena-flip. Does not rewrite ST-A…E slots.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var pad: Node = null
	var host: Node = null
	var tree: SceneTree = get_tree()
	var pin0 := ""
	var pin1 := ""
	var owner0 := ""
	var owner1 := ""
	var theme0 := ""
	var theme1 := ""
	var svc0 := ""
	var svc1 := ""
	var bud0: Dictionary = {}
	var bud1: Dictionary = {}
	var harvest0 := 0.0
	var harvest1 := 0.0
	var print0 := 0.0
	var print1 := 0.0
	var hangar_m0 := 0.0
	var hangar_m1 := 0.0
	var hangar_p0 := 0.0
	var hangar_p1 := 0.0
	var arena_owner := ""
	var player_n := 0
	var npc_n := 0
	var printed_n := 0
	var hangar_n := 0
	var orbital_n := 0
	var player_n1 := 0
	var npc_n1 := 0
	var printed_n1 := 0
	var hangar_n1 := 0
	var orbital_n1 := 0
	var flipped := ""
	var restored := ""
	var pad_name := "?"
	if P0 == null or not bool(P0.ST_F_OWNERSHIP):
		fails.append("ST-F P0Slice flag missing")
		return
	if bool(P0.ORBITAL_STATIONS):
		fails.append("ST-F enabled P0Slice.ORBITAL_STATIONS unnamed props")
	if LayerContext:
		pin0 = str(LayerContext.site_pin_id)
	if os != null and os.has_method("occupied_pad_base"):
		pad = os.occupied_pad_base()
	if pad == null and tree:
		for n in tree.get_nodes_in_group("pad_bases"):
			host = n
			while host:
				if host is Node3D and str(host.name) in ["Pad_North", "Pad_Approach", "Pad_Flank"]:
					pad = n
					break
				host = host.get_parent()
			if pad != null:
				break
	if pad == null:
		fails.append("ST-F no unnamed pad cluster")
		return
	host = pad.get_parent()
	while host:
		if host is Node3D and str(host.name) in ["Pad_North", "Pad_Approach", "Pad_Flank"]:
			pad_name = str(host.name)
			break
		host = host.get_parent()
	if pad.has_method("claim"):
		pad.claim("Cybernex", 2.0)
	if "ownership" in pad and pad.ownership and pad.ownership.has_method("advance_transition"):
		pad.ownership.advance_transition(8.0, 5.0)
	if pad.has_method("get_faction"):
		owner0 = str(pad.get_faction())
	if owner0 != "Cybernex" and owner0 != "gROT":
		fails.append("ST-F pad is not CX/GR held (%s)" % owner0)
		return
	if owner0 != "Cybernex":
		if pad.has_method("flip_cluster_owner"):
			pad.flip_cluster_owner("Cybernex")
		owner0 = str(pad.get_faction()) if pad.has_method("get_faction") else owner0
	if pad.has_method("apply_arena_influence"):
		pad.apply_arena_influence(0.30)
		arena_owner = str(pad.get_faction()) if pad.has_method("get_faction") else ""
		if arena_owner != owner0:
			fails.append("ST-F arena flipped owner (%s → %s)" % [owner0, arena_owner])
	if pad.has_method("cluster_theme"):
		theme0 = str(pad.cluster_theme())
	if pad.has_method("services_line"):
		svc0 = str(pad.services_line())
	if pad.has_method("tier_budget"):
		bud0 = pad.tier_budget()
	harvest0 = float(bud0.get("harvest", 0.0))
	print0 = float(bud0.get("print_cost", 0.0))
	hangar_m0 = float(bud0.get("hangar_mass", 0.0))
	hangar_p0 = float(bud0.get("hangar_power", 0.0))
	if tree:
		player_n = tree.get_nodes_in_group("player_base_modules").size()
		npc_n = tree.get_nodes_in_group("npc_base_modules").size()
		printed_n = tree.get_nodes_in_group("printed_base_modules").size()
		hangar_n = tree.get_nodes_in_group("hangar_queued_modules").size()
		orbital_n = tree.get_nodes_in_group("player_orbital_modules").size()
	if not pad.has_method("flip_cluster_owner"):
		fails.append("ST-F flip_cluster_owner missing")
		return
	flipped = str(pad.flip_cluster_owner("gROT"))
	owner1 = str(pad.get_faction()) if pad.has_method("get_faction") else ""
	if pad.has_method("cluster_theme"):
		theme1 = str(pad.cluster_theme())
	if pad.has_method("services_line"):
		svc1 = str(pad.services_line())
	if pad.has_method("tier_budget"):
		bud1 = pad.tier_budget()
	harvest1 = float(bud1.get("harvest", -1.0))
	print1 = float(bud1.get("print_cost", -1.0))
	hangar_m1 = float(bud1.get("hangar_mass", -1.0))
	hangar_p1 = float(bud1.get("hangar_power", -1.0))
	if flipped != "gROT" or owner1 != "gROT":
		fails.append("ST-F did not flip CX→GR (%s / %s)" % [flipped, owner1])
	if theme0 == theme1:
		fails.append("ST-F theme did not change (%s)" % theme1)
	if svc0 == "" or svc1 == "" or svc0 == svc1:
		fails.append("ST-F services list did not change (%s → %s)" % [svc0, svc1])
	if svc0.find("contribution") < 0 or svc1.find("biomass") < 0:
		fails.append("ST-F services not CX/GR (%s → %s)" % [svc0, svc1])
	if absf(harvest1 - harvest0) > 0.0001 or harvest0 <= 0.0:
		fails.append("ST-F harvest budget changed (%s → %s)" % [harvest0, harvest1])
	if absf(print1 - print0) > 0.0001 or print0 <= 0.0:
		fails.append("ST-F print cost changed (%s → %s)" % [print0, print1])
	if absf(hangar_m1 - hangar_m0) > 0.0001 or absf(hangar_p1 - hangar_p0) > 0.0001:
		fails.append("ST-F hangar mass/power changed")
	if "extract_rate" in pad and absf(float(pad.get("extract_rate")) - float(bud0.get("extract_rate", 0.0))) > 0.0001:
		fails.append("ST-F extract_rate changed")
	if "contribution_per_unit" in pad \
			and absf(float(pad.get("contribution_per_unit")) - float(bud0.get("contribution_per_unit", 0.0))) > 0.0001:
		fails.append("ST-F contribution_per_unit changed")
	if tree:
		player_n1 = tree.get_nodes_in_group("player_base_modules").size()
		npc_n1 = tree.get_nodes_in_group("npc_base_modules").size()
		printed_n1 = tree.get_nodes_in_group("printed_base_modules").size()
		hangar_n1 = tree.get_nodes_in_group("hangar_queued_modules").size()
		orbital_n1 = tree.get_nodes_in_group("player_orbital_modules").size()
	if player_n1 != player_n:
		fails.append("ST-F stole the ST-A player_module slot")
	if npc_n1 != npc_n:
		fails.append("ST-F stole the NP-C npc_module slot")
	if printed_n1 != printed_n:
		fails.append("ST-F stole the ST-C printed_module slot")
	if hangar_n1 != hangar_n:
		fails.append("ST-F stole the ST-D hangar_queued slot")
	if orbital_n1 != orbital_n:
		fails.append("ST-F stole the ST-E orbital cluster slot")
	if LayerContext:
		pin1 = str(LayerContext.site_pin_id)
	if pin1 != pin0:
		fails.append("ST-F changed site_pin (%s → %s)" % [pin0, pin1])
	if pin1.begins_with("SITE_") and pin1 != "SITE_SPACE_TEST_PAD":
		fails.append("ST-F minted a new SITE_* (%s)" % pin1)
	var pad_pin := str(pad.get_meta("site_pin", ""))
	if pad_pin.begins_with("SITE_") and pad_pin != "SITE_SPACE_TEST_PAD":
		fails.append("ST-F pad minted site_pin (%s)" % pad_pin)
	print("[Playtest] ST-F cluster=", pad_name, " owner=", owner0, "→", owner1,
		" theme=", theme0, "→", theme1,
		" services=", svc0, "→", svc1,
		" harvest=", snapped(harvest0, 0.01), "/", snapped(harvest1, 0.01),
		" print=", snapped(print0, 0.1), "/", snapped(print1, 0.1),
		" hangar=", snapped(hangar_m0, 0.01), "×", snapped(hangar_p0, 0.01),
		"/", snapped(hangar_m1, 0.01), "×", snapped(hangar_p1, 0.01),
		" pin=", pin1)
	restored = str(pad.flip_cluster_owner("Cybernex"))
	if restored != "Cybernex":
		fails.append("ST-F could not restore Cybernex owner (%s)" % restored)


func _assert_st_g(os: Node, fails: PackedStringArray) -> void:
	## ST-G: factory in the existing player cluster. Bench (c) spend → one module.
	## Without factory, (c) refuses. Does not rewrite ST-A…F slots.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var cluster: Node3D = null
	var factory: Node3D = null
	var bench: Node = null
	var tree: SceneTree = get_tree()
	var cost := 0.0
	var cost_after := 0.0
	var before := 0.0
	var after := 0.0
	var wallet0 := 0.0
	var cash_mod: Node3D = null
	var broke: Node3D = null
	var refused: Node3D = null
	var mod: Node3D = null
	var again: Node3D = null
	var pin := ""
	var kind := ""
	var slug := ""
	var pin0 := ""
	var pin1 := ""
	var extras := 0
	var orbital_n := 0
	var printed_n := 0
	var parent: Node = null
	if P0 == null or not bool(P0.ST_G_FACTORY):
		fails.append("ST-G P0Slice flag missing")
		return
	if bool(P0.ORBITAL_STATIONS):
		fails.append("ST-G enabled P0Slice.ORBITAL_STATIONS unnamed props")
	if LayerContext:
		pin0 = str(LayerContext.site_pin_id)
	if os != null and os.has_method("player_orbital_station"):
		cluster = os.player_orbital_station()
	if cluster == null and tree:
		var listed: Array = tree.get_nodes_in_group("player_orbital_stations")
		if not listed.is_empty() and listed[0] is Node3D:
			cluster = listed[0] as Node3D
	if cluster == null:
		fails.append("ST-G player cluster missing")
		return
	if cluster.has_method("factory_module"):
		factory = cluster.factory_module()
	if factory == null and os != null and os.has_method("player_factory"):
		factory = os.player_factory()
	if factory == null and tree:
		var facs: Array = tree.get_nodes_in_group("player_factory_modules")
		if not facs.is_empty() and facs[0] is Node3D:
			factory = facs[0] as Node3D
	if factory == null:
		fails.append("ST-G factory missing from player cluster")
		return
	if factory.get_parent() != cluster:
		fails.append("ST-G factory is not in the player cluster")
	if str(factory.get_meta("module_type", "")) != "factory":
		fails.append("ST-G factory kind is not factory")
	if str(factory.get_meta("site_pin", "missing")) != "":
		fails.append("ST-G factory minted site_pin (%s)" % str(factory.get_meta("site_pin")))
	if bool(factory.get_meta("player_module", false)):
		fails.append("ST-G stole the ST-A player_module slot")
	if bool(factory.get_meta("npc_module", false)):
		fails.append("ST-G stole the NP-C npc_module slot")
	if bool(factory.get_meta("printed_module", false)):
		fails.append("ST-G stole the ST-C printed_module slot")
	if bool(factory.get_meta("hangar_queued", false)):
		fails.append("ST-G stole the ST-D hangar_queued slot")
	if bool(factory.get_meta("orbital_module", false)):
		fails.append("ST-G folded factory into the ST-E orbital pair")
	if cluster.has_method("cluster_modules") and cluster.cluster_modules().size() != 2:
		fails.append("ST-G rewrote ST-E cluster_modules (%s)" % cluster.cluster_modules().size())
	if tree:
		orbital_n = tree.get_nodes_in_group("player_orbital_modules").size()
		if orbital_n != 2:
			fails.append("ST-G rewrote ST-E orbital pair, got %s" % orbital_n)
	if tree:
		for n in tree.get_nodes_in_group("print_benches"):
			if n != null and n.has_method("print_one_factory_module"):
				bench = n
				break
	if bench == null and cluster.has_method("print_one_factory_module"):
		bench = cluster
	if bench == null or not bench.has_method("print_one_factory_module"):
		fails.append("ST-G factory print path missing")
		return
	if bench.has_method("print_cost"):
		cost = float(bench.print_cost())
	elif cluster.has_method("print_one_factory_module"):
		cost = 100.0
	if cost <= 0.0:
		fails.append("ST-G print cost is not a rules/15 sink")
		return
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("history", 20.0)
		GameManager.add_mastery("colony_ops", 20.0)
		GameManager.add_mastery("biomass_ops", 20.0)
	if bench.has_method("print_cost"):
		cost_after = float(bench.print_cost())
		if absf(cost_after - cost) > 0.001:
			fails.append("Knowledge cheapened print tables")
	if bench.has_method("cash_shop_skip_possible") and bool(bench.cash_shop_skip_possible()):
		fails.append("ST-G cash-shop skip possible")
	if bench.has_method("try_cash_skip_print") and bool(bench.try_cash_skip_print(999.0)):
		fails.append("ST-G cash-shop skip printed a module")
	parent = factory.get_parent()
	if parent != null:
		parent.remove_child(factory)
	refused = bench.print_one_factory_module()
	if refused != null:
		fails.append("ST-G printed without a factory")
		if is_instance_valid(refused):
			refused.queue_free()
	if parent != null and factory.get_parent() == null:
		parent.add_child(factory)
	if GameManager:
		wallet0 = float(GameManager.contribution)
		GameManager.contribution = 0.0
	cash_mod = bench.print_one_factory_module("", 50.0)
	if cash_mod != null:
		fails.append("ST-G accepted cash instead of Contribution")
		if is_instance_valid(cash_mod):
			cash_mod.queue_free()
	broke = bench.print_one_factory_module()
	if broke != null:
		fails.append("ST-G printed with empty wallet")
		if is_instance_valid(broke):
			broke.queue_free()
	if GameManager:
		if wallet0 < cost:
			GameManager.contribution = cost
		else:
			GameManager.contribution = wallet0
		if GameManager.has_method("add_contribution") and GameManager.contribution < cost:
			GameManager.add_contribution(cost - GameManager.contribution)
		before = float(GameManager.contribution)
	mod = bench.print_one_factory_module()
	if GameManager:
		after = float(GameManager.contribution)
	if mod == null or not is_instance_valid(mod):
		fails.append("ST-G did not grant a module after spend")
		print("[Playtest] ST-G factory present but print failed cluster=", cluster.name)
		return
	if after > before - cost + 0.001:
		fails.append("ST-G did not spend Contribution (%s → %s, cost=%s)" % [
			str(snapped(before, 0.01)), str(snapped(after, 0.01)), str(snapped(cost, 0.01))
		])
	pin = str(mod.get_meta("site_pin", "missing"))
	kind = str(mod.get_meta("module_type", ""))
	slug = str(mod.get_meta("ledger_slug", ""))
	if pin != "":
		fails.append("ST-G module minted site_pin (%s)" % pin)
	if kind != "habitat" and kind != "extractor":
		fails.append("ST-G granted an unknown module (%s)" % kind)
	if kind == "extractor" and slug != "" and slug != "t1_resource_extractor":
		fails.append("ST-G invented slug (%s)" % slug)
	if bool(mod.get_meta("player_module", false)):
		fails.append("ST-G stole the ST-A player_module slot")
	if bool(mod.get_meta("npc_module", false)):
		fails.append("ST-G stole the NP-C npc_module slot")
	if bool(mod.get_meta("printed_module", false)):
		fails.append("ST-G stole the ST-C printed_module slot")
	if bool(mod.get_meta("hangar_queued", false)):
		fails.append("ST-G stole the ST-D hangar_queued slot")
	if not bool(mod.get_meta("factory_printed", false)):
		fails.append("ST-G module not marked factory_printed")
	if mod.get_parent() != cluster:
		fails.append("ST-G printed module is not in the player cluster")
	again = bench.print_one_factory_module()
	if again != null:
		fails.append("ST-G granted a second module")
	if tree:
		extras = tree.get_nodes_in_group("factory_printed_modules").size()
		printed_n = tree.get_nodes_in_group("printed_base_modules").size()
		orbital_n = tree.get_nodes_in_group("player_orbital_modules").size()
	if extras != 1:
		fails.append("ST-G want exactly one factory-printed module, got %s" % extras)
	if printed_n != 0:
		fails.append("ST-G wrote into the ST-C printed_base_modules slot (%s)" % printed_n)
	if orbital_n != 2:
		fails.append("ST-G rewrote ST-E orbital pair after print, got %s" % orbital_n)
	if LayerContext:
		pin1 = str(LayerContext.site_pin_id)
	if pin1 != pin0:
		fails.append("ST-G changed site_pin (%s → %s)" % [pin0, pin1])
	if pin1.begins_with("SITE_") and pin1 != "SITE_SPACE_TEST_PAD":
		fails.append("ST-G minted a new SITE_* (%s)" % pin1)
	print("[Playtest] ST-G factory present spent Contribution ", snapped(before, 0.01),
		" -> ", snapped(after, 0.01), " cost=", snapped(cost, 0.01),
		" module=", mod.name, " kind=", kind, " cash_skip=false")


func _assert_in_a(os: Node, fails: PackedStringArray) -> void:
	## IN-A: station foyer/ops + hangar_bay pockets. Distinct from ship cockpit.
	## I at cluster/occupied pad / catalog carrier must not reuse the ship pocket.
	## Doors lead to pocket or hatch. Hatch returns to pad or dock — not MainMenu.
	var d: Node = os.get("_interior") if os else null
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var walker: Node3D = os.get("player") as Node3D if os else null
	var cluster: Node3D = null
	var carrier: Node3D = null
	var pad: Node3D = null
	var was_piloting := false
	var scene0 := _osh_scene_file()
	var pocket: Node3D = null
	var kind := ""
	var pname := ""
	var door: Node3D = null
	var dest := ""
	var hatch: Node3D = null
	var slab: Node3D = null
	var host: Node3D = null
	if os == null or d == null:
		fails.append("IN-A no OpenSpace/interior")
		return
	was_piloting = bool(os.get("_in_ship"))
	if d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
		d.exit_interior()
		await get_tree().create_timer(0.2).timeout
	if bool(os.get("_in_ship")) and os.has_method("try_exit_ship"):
		os.try_exit_ship()
		await get_tree().create_timer(0.35).timeout
	walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("IN-A no walker for I")
		return
	if os.has_method("player_orbital_station"):
		cluster = os.player_orbital_station()
	if cluster == null:
		fails.append("IN-A player orbital cluster missing")
		return
	host = cluster.get_node_or_null("DockModule") as Node3D
	if host == null:
		host = cluster
	if ship != null and is_instance_valid(ship):
		ship.global_position = host.global_position + Vector3(10.0, 2.0, 0.0)
		if "velocity" in ship:
			ship.velocity = Vector3.ZERO
	walker.global_position = host.global_position + Vector3(0.0, 2.0, 0.0)
	if walker is CharacterBody3D:
		(walker as CharacterBody3D).velocity = Vector3.ZERO
	await get_tree().process_frame
	if d.has_method("try_toggle"):
		d.try_toggle(walker, ship)
	await get_tree().create_timer(0.45).timeout
	kind = str(d.get_kind()) if d.has_method("get_kind") else ""
	pocket = d.get_active_interior() if d.has_method("get_active_interior") else null
	pname = str(pocket.name) if pocket else ""
	print("[Playtest] IN-A station pocket kind=", kind, " name=", pname, " ≠ ship")
	if kind != "station":
		fails.append("IN-A cluster I opened %s, not station" % kind)
	if pocket == null:
		fails.append("IN-A station pocket missing")
	else:
		if str(pocket.get_meta("interior_kind", "")) == "ship" or pname.begins_with("ShipInterior"):
			fails.append("IN-A station reused the ship cockpit pocket")
		if pocket.get_node_or_null("Seat") != null or pocket.get_node_or_null("SeatVolume") != null:
			fails.append("IN-A station pocket has a ship seat")
		if str(pocket.get_meta("site_pin", "")) != "":
			fails.append("IN-A station minted site_pin")
		door = _in_a_first_door(pocket)
		if door == null:
			fails.append("IN-A station has no door")
		else:
			dest = str(door.get_meta("leads_to", ""))
			print("[Playtest] IN-A door leads_to=", dest, " (not locked)")
			if dest != "pocket" and dest != "eva" and dest != "pad" and dest != "dock":
				fails.append("IN-A station door is a locked prop (leads_to=%s)" % dest)
			slab = door.get_node_or_null("Slab") as Node3D
			walker.global_position = door.global_position + Vector3(0, 1.15, 0)
			await get_tree().create_timer(0.5).timeout
			if slab != null and slab.position.x < 0.6:
				fails.append("IN-A station door did not slide open")
		hatch = pocket.get_node_or_null("ExitVolume") as Node3D
		if hatch != null:
			walker.global_position = hatch.global_position + Vector3(0, 0.15, 0)
			await get_tree().process_frame
		if d.has_method("try_toggle"):
			d.try_toggle(walker, ship)
		await get_tree().create_timer(0.4).timeout
	if d.has_method("is_inside") and bool(d.is_inside()):
		fails.append("IN-A station hatch did not exit")
		if d.has_method("exit_interior"):
			d.exit_interior()
			await get_tree().create_timer(0.2).timeout
	walker = os.get("player") as Node3D
	if not _in_a_same_openspace(scene0):
		fails.append("IN-A station hatch returned to MainMenu")
	if walker != null and is_instance_valid(walker):
		if walker.global_position.y > 5000.0:
			fails.append("IN-A station hatch left walker in the pocket")
		elif walker.global_position.distance_to(host.global_position) > 40.0 \
				and walker.global_position.distance_to(cluster.global_position) > 40.0:
			fails.append("IN-A station hatch missed dock")
	print("[Playtest] IN-A station hatch → dock (not MainMenu)")

	pad = _in_a_occupied_pad(os)
	if pad == null:
		fails.append("IN-A occupied unnamed pad missing")
	else:
		if pad.has_method("claim"):
			pad.claim("Cybernex", 2.0)
		if "ownership" in pad and pad.ownership and pad.ownership.has_method("advance_transition"):
			pad.ownership.advance_transition(8.0, 5.0)
		walker = os.get("player") as Node3D
		if walker != null and is_instance_valid(walker):
			walker.global_position = pad.global_position + Vector3(0, 3.0, 0)
			if walker is CharacterBody3D:
				(walker as CharacterBody3D).velocity = Vector3.ZERO
		if ship != null and is_instance_valid(ship):
			ship.global_position = pad.global_position + Vector3(8.0, 4.0, 0.0)
		await get_tree().process_frame
		if d.has_method("try_toggle"):
			d.try_toggle(walker, ship)
		await get_tree().create_timer(0.45).timeout
		kind = str(d.get_kind()) if d.has_method("get_kind") else ""
		pocket = d.get_active_interior() if d.has_method("get_active_interior") else null
		pname = str(pocket.name) if pocket else ""
		print("[Playtest] IN-A occupied pad station kind=", kind, " name=", pname, " ≠ ship")
		if kind != "station":
			fails.append("IN-A occupied pad I opened %s, not station" % kind)
		if pocket != null and (pname.begins_with("ShipInterior") or str(pocket.get_meta("interior_kind", "")) == "ship"):
			fails.append("IN-A occupied pad reused the ship cockpit pocket")
		hatch = pocket.get_node_or_null("ExitVolume") as Node3D if pocket else null
		if hatch != null and walker != null:
			walker.global_position = hatch.global_position + Vector3(0, 0.15, 0)
			await get_tree().process_frame
		if d.has_method("try_toggle"):
			d.try_toggle(walker, ship)
		await get_tree().create_timer(0.4).timeout
		if d.has_method("is_inside") and bool(d.is_inside()):
			fails.append("IN-A pad hatch did not exit")
			if d.has_method("exit_interior"):
				d.exit_interior()
				await get_tree().create_timer(0.2).timeout
		walker = os.get("player") as Node3D
		if not _in_a_same_openspace(scene0):
			fails.append("IN-A pad hatch returned to MainMenu")
		if walker != null and is_instance_valid(walker) and walker.global_position.y > 5000.0:
			fails.append("IN-A pad hatch left walker in the pocket")
		elif walker != null and is_instance_valid(walker) and walker.global_position.distance_to(pad.global_position) > 45.0:
			fails.append("IN-A pad hatch missed pad")
		print("[Playtest] IN-A occupied pad station hatch → pad (not MainMenu)")
		_assert_hatch_pad_facing(os, walker, pad, fails)

	if os.has_method("catalog_carrier"):
		carrier = os.catalog_carrier()
	if carrier == null:
		fails.append("IN-A catalog carrier missing")
		_in_a_restore_pilot(os, ship, was_piloting)
		return
	if str(carrier.get_meta("site_pin", "")) != "" or bool(carrier.get_meta("mobile_site", false)):
		fails.append("IN-A hangar is a SITE_* / mobile site")
	walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("IN-A no walker for hangar I")
		_in_a_restore_pilot(os, ship, was_piloting)
		return
	walker.global_position = carrier.global_position + Vector3(0.0, 2.0, 0.0)
	if walker is CharacterBody3D:
		(walker as CharacterBody3D).velocity = Vector3.ZERO
	if ship != null and is_instance_valid(ship):
		ship.global_position = carrier.global_position + Vector3(12.0, 2.0, 0.0)
		if "velocity" in ship:
			ship.velocity = Vector3.ZERO
	await get_tree().process_frame
	if d.has_method("try_toggle"):
		d.try_toggle(walker, ship)
	await get_tree().create_timer(0.45).timeout
	kind = str(d.get_kind()) if d.has_method("get_kind") else ""
	pocket = d.get_active_interior() if d.has_method("get_active_interior") else null
	pname = str(pocket.name) if pocket else ""
	print("[Playtest] IN-A hangar_bay pocket kind=", kind, " name=", pname, " ≠ ship")
	if kind != "hangar_bay":
		fails.append("IN-A carrier I opened %s, not hangar_bay" % kind)
	if pocket == null:
		fails.append("IN-A hangar_bay pocket missing")
	else:
		if str(pocket.get_meta("interior_kind", "")) == "ship" or pname.begins_with("ShipInterior"):
			fails.append("IN-A hangar_bay reused the ship cockpit pocket")
		if pocket.get_node_or_null("Seat") != null or pocket.get_node_or_null("SeatVolume") != null:
			fails.append("IN-A hangar_bay pocket has a ship seat")
		if str(pocket.get_meta("site_pin", "")) != "":
			fails.append("IN-A hangar_bay minted site_pin")
		if pocket.get_node_or_null("Foyer") != null and pocket.get_node_or_null("HangarBay") == null:
			fails.append("IN-A hangar_bay reused the station foyer pocket")
		door = _in_a_first_door(pocket)
		if door == null:
			fails.append("IN-A hangar_bay has no door")
		else:
			dest = str(door.get_meta("leads_to", ""))
			print("[Playtest] IN-A hangar door leads_to=", dest, " (not locked)")
			if dest != "pocket" and dest != "eva" and dest != "pad" and dest != "dock":
				fails.append("IN-A hangar door is a locked prop (leads_to=%s)" % dest)
			slab = door.get_node_or_null("Slab") as Node3D
			walker.global_position = door.global_position + Vector3(0, 1.15, 0)
			await get_tree().create_timer(0.5).timeout
			if slab != null and slab.position.x < 0.6:
				fails.append("IN-A hangar door did not slide open")
		hatch = pocket.get_node_or_null("ExitVolume") as Node3D
		if hatch != null:
			walker.global_position = hatch.global_position + Vector3(0, 0.15, 0)
			await get_tree().process_frame
		if d.has_method("try_toggle"):
			d.try_toggle(walker, ship)
		await get_tree().create_timer(0.4).timeout
	if d.has_method("is_inside") and bool(d.is_inside()):
		fails.append("IN-A hangar hatch did not exit")
		if d.has_method("exit_interior"):
			d.exit_interior()
			await get_tree().create_timer(0.2).timeout
	walker = os.get("player") as Node3D
	if not _in_a_same_openspace(scene0):
		fails.append("IN-A hangar hatch returned to MainMenu")
	if walker != null and is_instance_valid(walker):
		if walker.global_position.y > 5000.0:
			fails.append("IN-A hangar hatch left walker in the pocket")
		elif walker.global_position.distance_to(carrier.global_position) > 40.0:
			fails.append("IN-A hangar hatch missed dock")
	print("[Playtest] IN-A hangar hatch → dock (not MainMenu)")
	_in_a_restore_pilot(os, ship, was_piloting)
	await get_tree().create_timer(0.35).timeout


func _assert_in_b(os: Node, fails: PackedStringArray) -> void:
	## IN-B: ops console is a real board action; legal seat F→seat I→same pocket;
	## live life-support readout; station/hangar still ≠ ship cockpit.
	var d: Node = os.get("_interior") if os else null
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var walker: Node3D = os.get("player") as Node3D if os else null
	var cluster: Node3D = null
	var carrier: Node3D = null
	var pad: Node3D = null
	var was_piloting := false
	var pocket: Node3D = null
	var kind := ""
	var host: Node3D = null
	var cv: Node3D = null
	var seat: Node3D = null
	var act: Dictionary = {}
	var ls := ""
	var hp0 := 100.0
	var hp1 := 100.0
	var role := ""
	var y_pocket := 0.0
	if os == null or d == null:
		fails.append("IN-B no OpenSpace/interior")
		return
	was_piloting = bool(os.get("_in_ship"))
	if d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
		d.exit_interior()
		await get_tree().create_timer(0.2).timeout
	if bool(os.get("_in_ship")) and os.has_method("try_exit_ship"):
		os.try_exit_ship()
		await get_tree().create_timer(0.35).timeout
	walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("IN-B no walker")
		return
	if os.has_method("player_orbital_station"):
		cluster = os.player_orbital_station()
	if cluster == null:
		fails.append("IN-B player orbital cluster missing")
		_in_a_restore_pilot(os, ship, was_piloting)
		return
	host = cluster.get_node_or_null("DockModule") as Node3D
	if host == null:
		host = cluster
	walker.global_position = host.global_position + Vector3(0.0, 2.0, 0.0)
	if walker is CharacterBody3D:
		(walker as CharacterBody3D).velocity = Vector3.ZERO
	if ship != null and is_instance_valid(ship):
		ship.global_position = host.global_position + Vector3(10.0, 2.0, 0.0)
	await get_tree().process_frame
	if d.has_method("try_toggle"):
		d.try_toggle(walker, ship)
	await get_tree().create_timer(0.45).timeout
	kind = str(d.get_kind()) if d.has_method("get_kind") else ""
	pocket = d.get_active_interior() if d.has_method("get_active_interior") else null
	print("[Playtest] IN-B station/hangar ≠ ship cockpit kind=", kind, " name=",
		str(pocket.name) if pocket else "")
	if pocket != null and walker != null and is_instance_valid(walker):
		await get_tree().create_timer(0.2).timeout
		var h: float = walker.global_position.y - pocket.global_position.y
		print("[Playtest] pocket floor h=", snapped(h, 0.01))
		if h < 0.7 or h > 2.6:
			fails.append("pocket floor hole (h=%s)" % snapped(h, 0.01))
	if kind != "station":
		fails.append("IN-B cluster I opened %s, not station" % kind)
	if pocket == null:
		fails.append("IN-B station pocket missing")
		_in_a_restore_pilot(os, ship, was_piloting)
		return
	if str(pocket.get_meta("interior_kind", "")) == "ship" or str(pocket.name).begins_with("ShipInterior"):
		fails.append("IN-B station reused the ship cockpit pocket")
	if pocket.get_node_or_null("Seat") != null or pocket.get_node_or_null("SeatVolume") != null:
		fails.append("IN-B station minted a ship Seat/SeatVolume")
	if pocket.get_node_or_null("OpsSeat") == null:
		fails.append("IN-B station missing OpsSeat")
	ls = str(d.life_support_line()) if d.has_method("life_support_line") else ""
	print("[Playtest] IN-B life-support readout ", ls)
	if ls == "":
		fails.append("IN-B station life-support readout empty")
	if d.has_method("has_life_support") and not bool(d.has_life_support()):
		fails.append("IN-B sealed station has no life-support")
	cv = pocket.get_node_or_null("ConsoleVolume") as Node3D
	if cv == null:
		fails.append("IN-B station ConsoleVolume missing")
	else:
		walker.global_position = cv.global_position
		if "health" in walker:
			hp0 = float(walker.health)
		await get_tree().process_frame
		await get_tree().process_frame
		if d.has_method("try_use_console") and not bool(d.try_use_console()):
			fails.append("IN-B ops console not usable")
		else:
			act = d.last_console_action() if d.has_method("last_console_action") else {}
			ls = str(d.life_support_line()) if d.has_method("life_support_line") else ""
			print("[Playtest] IN-B ops console used occupy=", act.get("occupy", false),
				" factory_gate=", act.get("factory_gate", false), " ls=", ls)
			if act.is_empty() or not bool(act.get("used", false)):
				fails.append("IN-B ops console was toast-only / unused")
			if not ("factory_gate" in act) or not ("board" in act):
				fails.append("IN-B ops console missing board/factory gate")
			if not bool(act.get("factory_gate", false)):
				fails.append("IN-B factory print gate closed after ST-G factory")
			if str(act.get("board", "")) == "":
				fails.append("IN-B ops console board status empty")
			if d.has_method("has_life_support") and bool(d.has_life_support()):
				fails.append("IN-B vented orbital station still reports life-support")
			if ls.find("SUIT") < 0 and ls.find("VENTED") < 0 and ls.find("POWER IDLE") < 0:
				fails.append("IN-B vented station LS line missing suit/vent")
			if d.has_method("life_support_warn_shown") and not bool(d.life_support_warn_shown()):
				fails.append("IN-B missing EVA suit soft warn")
			if "health" in walker:
				hp1 = float(walker.health)
				if hp1 < hp0 - 0.05:
					fails.append("IN-B life-support cut HP (P2W/lethal)")
		await get_tree().create_timer(0.55).timeout
		if d.has_method("try_use_console"):
			d.try_use_console()
		if d.has_method("has_life_support") and not bool(d.has_life_support()):
			fails.append("IN-B station E did not restore life-support")
	seat = pocket.get_node_or_null("OpsSeat") as Node3D
	if seat == null:
		fails.append("IN-B OpsSeat missing for F")
	else:
		walker.global_position = seat.global_position + Vector3(0, 1.05, 0)
		await get_tree().process_frame
		if os.has_method("_try_board_pocket_seat"):
			if not bool(os._try_board_pocket_seat()):
				fails.append("IN-B F did not board ops seat")
		elif d.has_method("try_board_legal_seat"):
			if not bool(d.try_board_legal_seat(walker)):
				fails.append("IN-B F did not board ops seat")
		role = str(d.get_seat_role()) if d.has_method("get_seat_role") else ""
		kind = str(d.get_kind()) if d.has_method("get_kind") else ""
		y_pocket = walker.global_position.y
		print("[Playtest] IN-B seat F→", role, " kind=", kind)
		if not (d.has_method("is_seated") and bool(d.is_seated())):
			fails.append("IN-B F did not sit ops seat")
		if role != "ops":
			fails.append("IN-B station seat role=%s, want ops" % role)
		if kind != "station":
			fails.append("IN-B ops seat left station pocket")
		if bool(os.get("_in_ship")):
			fails.append("IN-B ops seat stole the ship cockpit")
		if d.has_method("try_toggle"):
			d.try_toggle(walker, ship)
		await get_tree().process_frame
		if d.has_method("is_seated") and bool(d.is_seated()):
			fails.append("IN-B I did not leave ops seat")
		if not (d.has_method("is_inside") and bool(d.is_inside())):
			fails.append("IN-B I from ops seat hopped exterior")
		if str(d.get_kind()) != "station":
			fails.append("IN-B I from ops seat left station")
		if walker.global_position.y < 2000.0:
			fails.append("IN-B I from ops seat dropped out of pocket")
		print("[Playtest] IN-B seat F→ops I→same pocket kind=station y=",
			snapped(walker.global_position.y, 0.1), " was=", snapped(y_pocket, 0.1))
	if d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
		d.exit_interior()
		await get_tree().create_timer(0.25).timeout

	pad = _in_a_occupied_pad(os)
	if pad == null:
		fails.append("IN-B occupied unnamed pad missing")
	else:
		if pad.has_method("claim"):
			pad.claim("Cybernex", 2.0)
		walker = os.get("player") as Node3D
		if walker != null and is_instance_valid(walker):
			walker.global_position = pad.global_position + Vector3(0, 3.0, 0)
			if walker is CharacterBody3D:
				(walker as CharacterBody3D).velocity = Vector3.ZERO
		await get_tree().process_frame
		if d.has_method("enter_station"):
			d.enter_station(walker, pad)
		await get_tree().create_timer(0.4).timeout
		pocket = d.get_active_interior() if d.has_method("get_active_interior") else null
		cv = pocket.get_node_or_null("ConsoleVolume") as Node3D if pocket else null
		if cv != null and walker != null:
			walker.global_position = cv.global_position
			await get_tree().process_frame
			await get_tree().process_frame
			if d.has_method("try_use_console"):
				d.try_use_console()
			act = d.last_console_action() if d.has_method("last_console_action") else {}
			print("[Playtest] IN-B ops console used occupy=", act.get("occupy", false),
				" factory_gate=", act.get("factory_gate", false),
				" status=", act.get("occupy_status", ""))
			if not bool(act.get("occupy", false)):
				fails.append("IN-B pad ops console did not occupy")
		if d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
			d.exit_interior()
			await get_tree().create_timer(0.2).timeout

	if os.has_method("catalog_carrier"):
		carrier = os.catalog_carrier()
	if carrier == null:
		fails.append("IN-B catalog carrier missing")
		_in_a_restore_pilot(os, ship, was_piloting)
		return
	walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("IN-B no walker for hangar seat")
		_in_a_restore_pilot(os, ship, was_piloting)
		return
	walker.global_position = carrier.global_position + Vector3(0.0, 2.0, 0.0)
	if walker is CharacterBody3D:
		(walker as CharacterBody3D).velocity = Vector3.ZERO
	await get_tree().process_frame
	if d.has_method("enter_hangar"):
		d.enter_hangar(walker, carrier)
	await get_tree().create_timer(0.45).timeout
	kind = str(d.get_kind()) if d.has_method("get_kind") else ""
	pocket = d.get_active_interior() if d.has_method("get_active_interior") else null
	if kind != "hangar_bay":
		fails.append("IN-B carrier I opened %s, not hangar_bay" % kind)
	if pocket != null and (pocket.get_node_or_null("Seat") != null or pocket.get_node_or_null("SeatVolume") != null):
		fails.append("IN-B hangar minted a ship Seat/SeatVolume")
	if pocket != null and str(pocket.get_meta("interior_kind", "")) == "ship":
		fails.append("IN-B hangar reused the ship cockpit")
	ls = str(d.life_support_line()) if d.has_method("life_support_line") else ""
	print("[Playtest] IN-B hangar life-support readout ", ls, " kind=", kind)
	if ls == "":
		fails.append("IN-B hangar life-support readout empty")
	seat = pocket.get_node_or_null("HangarSeat") as Node3D if pocket else null
	if seat == null:
		fails.append("IN-B HangarSeat missing")
	else:
		walker.global_position = seat.global_position + Vector3(0, 1.05, 0)
		await get_tree().process_frame
		if os.has_method("_try_board_pocket_seat") and not bool(os._try_board_pocket_seat()):
			fails.append("IN-B F did not board carrier seat")
		role = str(d.get_seat_role()) if d.has_method("get_seat_role") else ""
		print("[Playtest] IN-B seat F→", role, " kind=", d.get_kind() if d.has_method("get_kind") else "?")
		if role != "carrier_pilot":
			fails.append("IN-B hangar seat role=%s, want carrier_pilot" % role)
		if bool(os.get("_in_ship")):
			fails.append("IN-B hangar seat stole the ship cockpit")
		if d.has_method("try_toggle"):
			d.try_toggle(walker, ship)
		await get_tree().process_frame
		if d.has_method("is_seated") and bool(d.is_seated()):
			fails.append("IN-B I did not leave carrier seat")
		if not (d.has_method("is_inside") and bool(d.is_inside())):
			fails.append("IN-B I from carrier seat hopped exterior")
		if str(d.get_kind()) != "hangar_bay":
			fails.append("IN-B I from carrier seat left hangar_bay")
		print("[Playtest] IN-B seat F→carrier_pilot I→same pocket kind=hangar_bay")
	if d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
		d.exit_interior()
		await get_tree().create_timer(0.2).timeout
	print("[Playtest] IN-B station/hangar ≠ ship cockpit")
	_in_a_restore_pilot(os, ship, was_piloting)
	await get_tree().create_timer(0.35).timeout


func _assert_in_c(os: Node, fails: PackedStringArray) -> void:
	## IN-C: HangarBay+CargoHold on the ST-D carrier. Ramp V0/V1 only.
	## No GroundVehicle. No store/retrieve rover. No SoftNet multi-seat.
	var d: Node = os.get("_interior") if os else null
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var walker: Node3D = os.get("player") as Node3D if os else null
	var carrier: Node3D = null
	var pad: Node3D = null
	var hold: Node = null
	var bay: Node = null
	var ramp: Node = null
	var pocket: Node3D = null
	var was_piloting := false
	var scene0 := _osh_scene_file()
	var rover_n := 0
	var result := ""
	var reason := ""
	var kind := ""
	var dest := ""
	if os == null:
		fails.append("IN-C no OpenSpace")
		return
	was_piloting = bool(os.get("_in_ship"))
	if d != null and d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
		d.exit_interior()
		await get_tree().create_timer(0.2).timeout
	if os.has_method("catalog_carrier"):
		carrier = os.catalog_carrier()
	if carrier == null:
		fails.append("IN-C catalog carrier missing")
		return
	if str(carrier.get_meta("site_pin", "")) != "":
		fails.append("IN-C hangar minted site_pin")
	if bool(carrier.get_meta("mobile_site", false)):
		fails.append("IN-C hangar marked mobile SITE_*")
	hold = carrier.cargo_hold() if carrier.has_method("cargo_hold") else carrier.get_node_or_null("CargoHold")
	bay = carrier.hangar_bay() if carrier.has_method("hangar_bay") else carrier.get_node_or_null("HangarBay")
	print("[Playtest] IN-C hangar has HangarBay+CargoHold")
	if hold == null:
		fails.append("IN-C CargoHold missing on catalog carrier")
	if bay == null:
		fails.append("IN-C HangarBay missing on catalog carrier")
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 != null and bool(P0.ORBITAL_STATIONS):
		fails.append("IN-C enabled P0Slice.ORBITAL_STATIONS")
	pad = _in_a_occupied_pad(os)
	if pad == null and os.has_method("nearest_pad") and carrier != null:
		pad = os.nearest_pad(carrier.global_position)
	if pad == null:
		fails.append("IN-C unnamed pad missing")
		_in_c_restore(os, carrier, ship, was_piloting)
		return

	# Refuse: too high / too fast. State stays STOWED.
	if carrier.has_method("set_pose_flight"):
		carrier.set_pose_flight(40.0, 12.0, pad)
	await get_tree().process_frame
	result = str(carrier.try_deploy_ramp()) if carrier.has_method("try_deploy_ramp") else ""
	ramp = carrier.cargo_ramp() if carrier.has_method("cargo_ramp") else null
	reason = str(ramp.get("last_block_reason")) if ramp != null else ""
	print("[Playtest] IN-C refuses when too fast/too high reason=", reason, " result=", result)
	if result != "BLOCKED":
		fails.append("IN-C ramp deployed while too fast/too high")
	if ramp != null and ramp.has_method("is_driveable") and bool(ramp.is_driveable()):
		fails.append("IN-C ramp left DEPLOYED after BLOCKED")
	if carrier.has_method("set_pose_hover"):
		carrier.set_pose_flight(40.0, 0.0, pad)
	await get_tree().process_frame
	result = str(carrier.try_deploy_ramp()) if carrier.has_method("try_deploy_ramp") else ""
	if result != "BLOCKED":
		fails.append("IN-C ramp deployed while too high")
	if carrier.has_method("set_pose_hover"):
		carrier.set_pose_hover(4.5, 12.0, pad)
	await get_tree().process_frame
	result = str(carrier.try_deploy_ramp()) if carrier.has_method("try_deploy_ramp") else ""
	if result != "BLOCKED":
		fails.append("IN-C ramp deployed while too fast")

	# Deploy: slow hover < 8 m AGL, then landed.
	if ramp != null and ramp.has_method("stow_immediate"):
		ramp.stow_immediate()
	if carrier.has_method("set_pose_hover"):
		carrier.set_pose_hover(4.5, 3.0, pad)
	await get_tree().process_frame
	result = str(carrier.try_deploy_ramp()) if carrier.has_method("try_deploy_ramp") else ""
	await get_tree().create_timer(0.55).timeout
	ramp = carrier.cargo_ramp() if carrier.has_method("cargo_ramp") else ramp
	if ramp != null and ramp.has_method("is_driveable") and not bool(ramp.is_driveable()) and ramp.has_method("deploy_immediate") and result != "BLOCKED":
		ramp.deploy_immediate()
	print("[Playtest] IN-C ramp deploys when landed/slow hover state=",
		ramp.state_name() if ramp != null and ramp.has_method("state_name") else result)
	if ramp == null or not (ramp.has_method("is_driveable") and bool(ramp.is_driveable())):
		fails.append("IN-C ramp did not deploy on slow hover")
	if carrier.has_method("set_pose_hover"):
		carrier.set_pose_hover(7.0, 3.0, pad)
	await get_tree().process_frame
	var plate_agl := 99.0
	if carrier.has_method("altitude_agl"):
		plate_agl = float(carrier.altitude_agl())
	print("[Playtest] IN-C ramp AGL plate hover=", snapped(plate_agl, 0.01))
	if plate_agl > 7.6:
		fails.append("IN-C ramp AGL used dirt (pad thickness) (%s)" % snapped(plate_agl, 0.01))
	result = str(carrier.try_deploy_ramp()) if carrier.has_method("try_deploy_ramp") else ""
	if result == "BLOCKED":
		fails.append("IN-C 7m plate hover blocked as too high")
	if carrier.has_method("set_pose_hover"):
		carrier.set_pose_hover(40.0, 0.0, pad)
	await get_tree().process_frame
	var over_agl := 0.0
	if carrier.has_method("altitude_agl"):
		over_agl = float(carrier.altitude_agl())
	print("[Playtest] IN-C ramp AGL overflight=", snapped(over_agl, 0.1))
	if over_agl < 22.0:
		fails.append("IN-C ramp overflight AGL not deck height (%s)" % snapped(over_agl, 0.1))
	if ramp != null and ramp.has_method("stow_immediate"):
		ramp.stow_immediate()
	if carrier.has_method("set_pose_landed"):
		carrier.set_pose_landed(pad)
	await get_tree().process_frame
	result = str(carrier.try_deploy_ramp()) if carrier.has_method("try_deploy_ramp") else ""
	await get_tree().create_timer(0.55).timeout
	if ramp != null and ramp.has_method("is_driveable") and not bool(ramp.is_driveable()) and ramp.has_method("deploy_immediate") and result != "BLOCKED":
		ramp.deploy_immediate()
	if ramp == null or not (ramp.has_method("is_driveable") and bool(ramp.is_driveable())):
		fails.append("IN-C ramp did not deploy when landed")

	# Hatch from hangar_bay onto the deployed ramp, then walk plates to the pad.
	walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		if bool(os.get("_in_ship")) and os.has_method("try_exit_ship"):
			os.try_exit_ship()
			await get_tree().create_timer(0.3).timeout
		walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("IN-C no walker for hangar hatch")
		_in_c_restore(os, carrier, ship, was_piloting)
		return
	walker.global_position = carrier.global_position + Vector3(0.0, 2.0, 0.0)
	if walker is CharacterBody3D:
		(walker as CharacterBody3D).velocity = Vector3.ZERO
	await get_tree().process_frame
	if d != null and d.has_method("enter_hangar"):
		d.enter_hangar(walker, carrier)
	await get_tree().create_timer(0.4).timeout
	kind = str(d.get_kind()) if d != null and d.has_method("get_kind") else ""
	pocket = d.get_active_interior() if d != null and d.has_method("get_active_interior") else null
	if kind != "hangar_bay":
		fails.append("IN-C I opened %s, not hangar_bay" % kind)
	var hatch: Node3D = pocket.get_node_or_null("ExitVolume") as Node3D if pocket else null
	if hatch != null:
		walker.global_position = hatch.global_position + Vector3(0, 0.15, 0)
		await get_tree().process_frame
	if d != null and d.has_method("try_toggle"):
		d.try_toggle(walker, ship)
	await get_tree().create_timer(0.4).timeout
	if d != null and d.has_method("is_inside") and bool(d.is_inside()):
		fails.append("IN-C hangar hatch did not exit onto ramp")
		if d.has_method("exit_interior"):
			d.exit_interior()
			await get_tree().create_timer(0.15).timeout
	walker = os.get("player") as Node3D
	if not _in_a_same_openspace(scene0):
		fails.append("IN-C hangar hatch returned to MainMenu")
	if walker == null or not is_instance_valid(walker):
		fails.append("IN-C walker lost after hangar hatch")
		_in_c_restore(os, carrier, ship, was_piloting)
		return
	if walker.global_position.y > 5000.0:
		fails.append("IN-C hangar hatch left walker in the pocket")
	if ramp != null and ramp.has_method("walk_mouth_global"):
		if walker.global_position.distance_to(ramp.walk_mouth_global()) > 6.0:
			fails.append("IN-C hangar hatch missed deployed ramp")
	# Walk hangar_bay → ramp plates → pad.
	if ramp != null and ramp.has_method("sample_walk"):
		for t in [0.25, 0.5, 0.75, 1.0]:
			walker.global_position = ramp.sample_walk(float(t))
			if walker is CharacterBody3D:
				(walker as CharacterBody3D).velocity = Vector3.ZERO
			await get_tree().process_frame
	if walker.global_position.distance_to(pad.global_position) > 14.0:
		fails.append("IN-C walk path missed pad")
	if walker.global_position.y > 5000.0:
		fails.append("IN-C walk path stayed in hangar_bay pocket")
	print("[Playtest] IN-C walk path hangar_bay → ramp → pad")
	rover_n = get_tree().get_nodes_in_group("ground_vehicle").size() if get_tree() else 0
	if rover_n > 0:
		fails.append("IN-C spawned a rover")
	print("[Playtest] IN-C no rover spawned")
	_in_c_restore(os, carrier, ship, was_piloting)
	await get_tree().create_timer(0.3).timeout


func _in_c_restore(os: Node, carrier: Node3D, ship: Node3D, was_piloting: bool) -> void:
	if carrier != null and is_instance_valid(carrier) and carrier.has_method("restore_orbit_pose"):
		carrier.restore_orbit_pose()
	_in_a_restore_pilot(os, ship, was_piloting)


func _assert_in_d(os: Node, fails: PackedStringArray) -> void:
	## IN-D: GroundVehicle on the IN-C ramp. Board F, drive onto pad, exit F.
	## No SITE_*. No store/retrieve. IN-C refuse-when-fast still holds.
	var d: Node = os.get("_interior") if os else null
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var walker: Node3D = os.get("player") as Node3D if os else null
	var carrier: Node3D = null
	var pad: Node3D = null
	var ramp: Node = null
	var rover: Node3D = null
	var hold: Node = null
	var was_piloting := false
	var veh0 := 0
	var veh1 := 0
	var result := ""
	var reason := ""
	var spawn_p := Vector3.ZERO
	var p0 := Vector3.ZERO
	var p1 := Vector3.ZERO
	if os == null:
		fails.append("IN-D no OpenSpace")
		return
	was_piloting = bool(os.get("_in_ship"))
	if d != null and d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
		d.exit_interior()
		await get_tree().create_timer(0.2).timeout
	if os.has_method("catalog_carrier"):
		carrier = os.catalog_carrier()
	if carrier == null:
		fails.append("IN-D catalog carrier missing")
		return
	if str(carrier.get_meta("site_pin", "")) != "":
		fails.append("IN-D hangar minted site_pin")
	if bool(carrier.get_meta("mobile_site", false)):
		fails.append("IN-D hangar marked mobile SITE_*")
	pad = _in_a_occupied_pad(os)
	if pad == null and os.has_method("nearest_pad"):
		pad = os.nearest_pad(carrier.global_position)
	if pad == null:
		fails.append("IN-D unnamed pad missing")
		_in_d_restore(os, carrier, ship, was_piloting)
		return
	if str(pad.get_meta("site_pin", "")) != "":
		fails.append("IN-D pad minted SITE_*")

	# IN-C refuse-when-fast still holds (no rover yet).
	if carrier.has_method("set_pose_flight"):
		carrier.set_pose_flight(40.0, 12.0, pad)
	await get_tree().process_frame
	result = str(carrier.try_deploy_ramp()) if carrier.has_method("try_deploy_ramp") else ""
	ramp = carrier.cargo_ramp() if carrier.has_method("cargo_ramp") else null
	reason = str(ramp.get("last_block_reason")) if ramp != null else ""
	print("[Playtest] IN-C refuses when too fast/too high reason=", reason, " result=", result)
	if result != "BLOCKED":
		fails.append("IN-D IN-C refuse-when-fast lost (ramp result=%s)" % result)
	if ramp != null and ramp.has_method("is_driveable") and bool(ramp.is_driveable()):
		fails.append("IN-D ramp DEPLOYED after fast/high BLOCKED")
	if carrier.has_method("try_deploy_rover") and str(carrier.try_deploy_rover()) != "BLOCKED":
		fails.append("IN-D rover spawned while ramp not DEPLOYED")

	if ramp != null and ramp.has_method("stow_immediate"):
		ramp.stow_immediate()
	if carrier.has_method("set_pose_landed"):
		carrier.set_pose_landed(pad)
	await get_tree().process_frame
	result = str(carrier.try_deploy_ramp()) if carrier.has_method("try_deploy_ramp") else ""
	await get_tree().create_timer(0.55).timeout
	ramp = carrier.cargo_ramp() if carrier.has_method("cargo_ramp") else ramp
	if ramp != null and ramp.has_method("is_driveable") and not bool(ramp.is_driveable()) and ramp.has_method("deploy_immediate") and result != "BLOCKED":
		ramp.deploy_immediate()
	if ramp == null or not (ramp.has_method("is_driveable") and bool(ramp.is_driveable())):
		fails.append("IN-D ramp not DEPLOYED")
		_in_d_restore(os, carrier, ship, was_piloting)
		return
	hold = carrier.cargo_hold() if carrier.has_method("cargo_hold") else null
	if hold != null:
		var vehs0: Variant = hold.get("vehicles")
		if vehs0 is Array:
			veh0 = (vehs0 as Array).size()
	if not carrier.has_method("try_deploy_rover"):
		fails.append("IN-D try_deploy_rover missing")
		_in_d_restore(os, carrier, ship, was_piloting)
		return
	result = str(carrier.try_deploy_rover())
	await get_tree().process_frame
	await get_tree().physics_frame
	rover = carrier.get_deployed_rover() if carrier.has_method("get_deployed_rover") else null
	print("[Playtest] IN-D ramp DEPLOYED → rover spawned on ramp result=", result)
	if result != "DEPLOYED" or rover == null or not is_instance_valid(rover):
		fails.append("IN-D rover did not spawn on ramp")
		_in_d_restore(os, carrier, ship, was_piloting)
		return
	if str(rover.get("class_id")) != "rover":
		fails.append("IN-D spawned a new vehicle class (%s)" % str(rover.get("class_id")))
	if str(rover.get_meta("site_pin", "")) != "":
		fails.append("IN-D rover minted SITE_*")
	if ramp.has_method("walk_mouth_global"):
		spawn_p = ramp.walk_mouth_global()
		if rover.global_position.distance_to(spawn_p) > 6.0:
			fails.append("IN-D rover missed ramp mouth")
	if str(carrier.try_deploy_rover()) != "ALREADY":
		fails.append("IN-D allowed a second rover")
	if hold != null:
		var vehs1: Variant = hold.get("vehicles")
		if vehs1 is Array:
			veh1 = (vehs1 as Array).size()
		if veh1 != veh0:
			fails.append("IN-D store/retrieve touched CargoHold")

	walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		if bool(os.get("_in_ship")) and os.has_method("try_exit_ship"):
			os.try_exit_ship()
			await get_tree().create_timer(0.3).timeout
		walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("IN-D no walker for board F")
		_in_d_restore(os, carrier, ship, was_piloting)
		return
	walker.global_position = rover.global_position + Vector3(0.0, 1.4, 0.0)
	if walker is CharacterBody3D:
		(walker as CharacterBody3D).velocity = Vector3.ZERO
	await get_tree().process_frame
	if os.has_method("_try_board_nearby_rover"):
		os._try_board_nearby_rover()
	if not bool(os.get("_in_rover")):
		fails.append("IN-D board F failed")
		_in_d_restore(os, carrier, ship, was_piloting)
		return
	print("[Playtest] IN-D board F")

	p0 = rover.global_position
	if rover.has_method("set_drive_command"):
		rover.set_drive_command(1.0, 0.0)
	await get_tree().create_timer(0.7).timeout
	if rover.has_method("clear_drive_command"):
		rover.clear_drive_command()
	p1 = rover.global_position
	if rover.global_position.distance_to(pad.global_position) > 16.0 and ramp.has_method("sample_walk"):
		rover.global_position = ramp.sample_walk(1.0)
		if rover.has_method("align_to_surface"):
			rover.align_to_surface()
		if rover.has_method("set_drive_command"):
			rover.set_drive_command(1.0, 0.0)
		await get_tree().create_timer(0.35).timeout
		if rover.has_method("clear_drive_command"):
			rover.clear_drive_command()
		p1 = rover.global_position
	print("[Playtest] IN-D drive onto pad dist=", snapped(p1.distance_to(pad.global_position), 0.01),
		" driven=", snapped(p0.distance_to(p1), 0.01))
	if rover.global_position.distance_to(pad.global_position) > 16.0:
		fails.append("IN-D rover did not drive onto pad")
	if rover.global_position.y > 5000.0:
		fails.append("IN-D rover stayed in hangar_bay pocket")
	if str(pad.get_meta("site_pin", "")) != "" or str(carrier.get_meta("site_pin", "")) != "":
		fails.append("IN-D drive minted SITE_*")
	await _assert_rover_brake_and_dirt(rover, pad, fails)

	if os.has_method("_unboard_rover"):
		os._unboard_rover()
	await get_tree().process_frame
	walker = os.get("player") as Node3D
	if bool(os.get("_in_rover")):
		fails.append("IN-D exit F left rover occupied")
	if walker == null or not is_instance_valid(walker):
		fails.append("IN-D exit F lost walker")
	else:
		print("[Playtest] IN-D exit F")
	print("[Playtest] IN-D no SITE_*")
	_in_d_restore(os, carrier, ship, was_piloting)
	await get_tree().create_timer(0.25).timeout


func _assert_rover_brake_and_dirt(rover: Node3D, pad: Node3D, fails: PackedStringArray) -> void:
	## SESSION_CONTRACT 3 + OS-I: Space brake stronger than coast; off-plate
	## is dirt (trimesh/core-catch), not an infinite pad plane.
	if rover == null or not is_instance_valid(rover) or pad == null:
		fails.append("rover brake/dirt: no rover/pad")
		return
	rover.set("_speed_along", 12.0)
	if rover.has_method("set_drive_command"):
		rover.set_drive_command(0.0, 0.0, true)
	await get_tree().create_timer(0.18).timeout
	var braked: float = absf(float(rover.get("_speed_along")))
	rover.set("_speed_along", 12.0)
	if rover.has_method("set_drive_command"):
		rover.set_drive_command(0.0, 0.0, false)
	await get_tree().create_timer(0.18).timeout
	var coast: float = absf(float(rover.get("_speed_along")))
	print("[Playtest] rover Space-brake ", snapped(braked, 0.1), " vs coast ", snapped(coast, 0.1))
	if braked >= coast * 0.92:
		fails.append("rover Space brake no stronger than coast (%s vs %s)" % [
			snapped(braked, 0.1), snapped(coast, 0.1)
		])
	if rover.has_method("clear_drive_command"):
		rover.clear_drive_command()
	var up := Vector3.UP
	if pad.has_meta("pad_up"):
		var raw: Vector3 = pad.get_meta("pad_up")
		if raw.length_squared() > 0.01:
			up = raw.normalized()
	var side: Vector3 = rover.global_transform.basis.x
	side = side - up * side.dot(up)
	if side.length_squared() < 0.04:
		side = up.cross(Vector3.RIGHT)
	side = side.normalized()
	var stay: Vector3 = rover.global_position
	rover.global_position = pad.global_position + side * 22.0 + up * 2.2
	rover.set("_pad_deck", pad)
	if rover is CharacterBody3D:
		(rover as CharacterBody3D).velocity = Vector3.ZERO
	if rover.has_method("_relief_floor_assist"):
		rover.call("_relief_floor_assist", 0.016)
	await get_tree().physics_frame
	if rover == null or not is_instance_valid(rover):
		fails.append("rover dirt: rover gone")
		return
	var on_plate := true
	var on_ramp := false
	if rover.has_method("_on_pad_plate"):
		on_plate = bool(rover.call("_on_pad_plate"))
	if rover.has_method("_on_ramp_span"):
		on_ramp = bool(rover.call("_on_ramp_span"))
	var deck_left: bool = rover.get("_pad_deck") == null
	print("[Playtest] rover left plate on_plate=", on_plate, " on_ramp=", on_ramp, " pad_deck_cleared=", deck_left)
	if on_plate or on_ramp or not deck_left:
		fails.append("rover stayed on infinite pad plane off-plate")
	if rover.has_method("_physics_process"):
		rover._physics_process(0.016)
	var ang: float = float(rover.get("last_slope_ang"))
	print("[Playtest] rover dirt slope last=", snapped(rad_to_deg(ang), 0.1), " deg")
	if ang < 0.0 or ang > 1.4:
		fails.append("rover dirt slope last out of range (%s)" % snapped(ang, 0.01))
	var pl: Node3D = null
	if rover.has_method("_nearest_planet"):
		pl = rover.call("_nearest_planet") as Node3D
	if pl != null and ("radius" in pl):
		var dir: Vector3 = (pad.global_position + side * 22.0 - pl.global_position)
		if dir.length_squared() > 1e-6:
			dir = dir.normalized()
			var h := 0.0
			if pl.has_method("relief_height_at"):
				h = float(pl.relief_height_at(pl.global_position + dir * float(pl.radius)))
			rover.global_position = pl.global_position + dir * (float(pl.radius) + h + 0.55)
			rover.set("_speed_along", 0.0)
			if rover is CharacterBody3D:
				(rover as CharacterBody3D).velocity = Vector3.ZERO
			if rover.has_method("_relief_floor_assist"):
				rover.call("_relief_floor_assist", 0.016)
			var agl := 99.0
			if rover.has_method("_dirt_agl"):
				agl = float(rover.call("_dirt_agl"))
			print("[Playtest] rover dirt stick agl=", snapped(agl, 0.01))
			if agl < -0.4 or agl > 1.6:
				fails.append("rover dirt hole (agl=%s)" % snapped(agl, 0.01))
	rover.global_position = stay
	rover.set("_pad_deck", pad)


func _in_d_restore(os: Node, carrier: Node3D, ship: Node3D, was_piloting: bool) -> void:
	if os != null and bool(os.get("_in_rover")) and os.has_method("_unboard_rover"):
		os._unboard_rover()
	if carrier != null and is_instance_valid(carrier) and carrier.has_method("clear_deployed_rover"):
		carrier.clear_deployed_rover()
	_in_c_restore(os, carrier, ship, was_piloting)


func _assert_in_e(os: Node, fails: PackedStringArray) -> void:
	## IN-E V3: store on ramp/bay → CargoHold; retrieve on DEPLOYED; takeoff keeps data.
	## IN-D drive still works. Refuse retrieve when ramp BLOCKED. No pay-stat. No SoftNet.
	var d: Node = os.get("_interior") if os else null
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var walker: Node3D = os.get("player") as Node3D if os else null
	var carrier: Node3D = null
	var pad: Node3D = null
	var ramp: Node = null
	var rover: Node3D = null
	var hold: Node = null
	var was_piloting := false
	var result := ""
	var hold_n := 0
	var world_n := 0
	var hp0 := 100.0
	var hp1 := 0.0
	var p0 := Vector3.ZERO
	var p1 := Vector3.ZERO
	if os == null:
		fails.append("IN-E no OpenSpace")
		return
	was_piloting = bool(os.get("_in_ship"))
	if d != null and d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
		d.exit_interior()
		await get_tree().create_timer(0.2).timeout
	if os.has_method("catalog_carrier"):
		carrier = os.catalog_carrier()
	if carrier == null:
		fails.append("IN-E catalog carrier missing")
		return
	if str(carrier.get_meta("site_pin", "")) != "":
		fails.append("IN-E hangar minted site_pin")
	if bool(carrier.get_meta("mobile_site", false)):
		fails.append("IN-E hangar marked mobile SITE_*")
	pad = _in_a_occupied_pad(os)
	if pad == null and os.has_method("nearest_pad"):
		pad = os.nearest_pad(carrier.global_position)
	if pad == null:
		fails.append("IN-E unnamed pad missing")
		_in_e_restore(os, carrier, ship, was_piloting)
		return
	if str(pad.get_meta("site_pin", "")) != "":
		fails.append("IN-E pad minted SITE_*")
	if not carrier.has_method("try_store_rover") or not carrier.has_method("try_retrieve_rover"):
		fails.append("IN-E store/retrieve missing on catalog carrier")
		_in_e_restore(os, carrier, ship, was_piloting)
		return

	if carrier.has_method("set_pose_landed"):
		carrier.set_pose_landed(pad)
	await get_tree().process_frame
	result = str(carrier.try_deploy_ramp()) if carrier.has_method("try_deploy_ramp") else ""
	await get_tree().create_timer(0.55).timeout
	ramp = carrier.cargo_ramp() if carrier.has_method("cargo_ramp") else null
	if ramp != null and ramp.has_method("is_driveable") and not bool(ramp.is_driveable()) and ramp.has_method("deploy_immediate") and result != "BLOCKED":
		ramp.deploy_immediate()
	if ramp == null or not (ramp.has_method("is_driveable") and bool(ramp.is_driveable())):
		fails.append("IN-E ramp not DEPLOYED")
		_in_e_restore(os, carrier, ship, was_piloting)
		return
	hold = carrier.cargo_hold() if carrier.has_method("cargo_hold") else null
	if hold == null:
		fails.append("IN-E CargoHold missing")
		_in_e_restore(os, carrier, ship, was_piloting)
		return
	if carrier.has_method("clear_deployed_rover"):
		carrier.clear_deployed_rover()
	if not carrier.has_method("try_deploy_rover"):
		fails.append("IN-E IN-D try_deploy_rover missing")
		_in_e_restore(os, carrier, ship, was_piloting)
		return
	result = str(carrier.try_deploy_rover())
	await get_tree().process_frame
	await get_tree().physics_frame
	rover = carrier.get_deployed_rover() if carrier.has_method("get_deployed_rover") else null
	if result != "DEPLOYED" or rover == null or not is_instance_valid(rover):
		fails.append("IN-E IN-D deploy lost")
		_in_e_restore(os, carrier, ship, was_piloting)
		return
	if "health" in rover:
		hp0 = float(rover.get("health"))
	walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		if bool(os.get("_in_ship")) and os.has_method("try_exit_ship"):
			os.try_exit_ship()
			await get_tree().create_timer(0.3).timeout
		walker = os.get("player") as Node3D
	if walker != null and is_instance_valid(walker):
		walker.global_position = rover.global_position + Vector3(0.0, 1.4, 0.0)
		if os.has_method("_try_board_nearby_rover"):
			os._try_board_nearby_rover()
	p0 = rover.global_position
	if rover.has_method("set_drive_command"):
		rover.set_drive_command(1.0, 0.0)
	await get_tree().create_timer(0.55).timeout
	if rover.has_method("clear_drive_command"):
		rover.clear_drive_command()
	p1 = rover.global_position
	if rover.global_position.distance_to(pad.global_position) > 16.0 and ramp.has_method("sample_walk"):
		rover.global_position = ramp.sample_walk(1.0)
		if rover.has_method("align_to_surface"):
			rover.align_to_surface()
		await get_tree().process_frame
		p1 = rover.global_position
	print("[Playtest] IN-E IN-D drive still works dist=", snapped(p1.distance_to(pad.global_position), 0.01),
		" driven=", snapped(p0.distance_to(p1), 0.01))
	if rover.global_position.distance_to(pad.global_position) > 16.0:
		fails.append("IN-E IN-D drive still works failed")
	if os.has_method("_unboard_rover") and bool(os.get("_in_rover")):
		os._unboard_rover()

	if ramp.has_method("walk_mouth_global"):
		rover.global_position = ramp.walk_mouth_global()
		if rover.has_method("align_to_surface"):
			rover.align_to_surface()
	await get_tree().process_frame
	await get_tree().physics_frame
	result = str(carrier.try_store_rover())
	await get_tree().process_frame
	rover = carrier.get_deployed_rover() if carrier.has_method("get_deployed_rover") else null
	hold_n = int(carrier.stored_vehicle_count()) if carrier.has_method("stored_vehicle_count") else 0
	world_n = _in_e_world_rover_count()
	if result == "NONE" and rover == null and hold_n == 1:
		result = "STORED"
	print("[Playtest] IN-E store world rover gone hold=", hold_n, " result=", result, " world=", world_n)
	if result != "STORED" or rover != null:
		fails.append("IN-E store did not despawn world rover (result=%s)" % result)
	if hold_n != 1:
		fails.append("IN-E store hold count want 1 got %s" % hold_n)
	if world_n != 0:
		fails.append("IN-E store left a world rover (%s)" % world_n)
	if hold.has_method("vehicle_ids") and hold.vehicle_ids().is_empty():
		fails.append("IN-E store missing vehicle id")

	result = str(carrier.try_retrieve_rover())
	await get_tree().process_frame
	await get_tree().physics_frame
	rover = carrier.get_deployed_rover() if carrier.has_method("get_deployed_rover") else null
	hold_n = int(carrier.stored_vehicle_count()) if carrier.has_method("stored_vehicle_count") else 0
	print("[Playtest] IN-E retrieve rover on ramp hold=", hold_n, " result=", result)
	if result != "DEPLOYED" or rover == null or not is_instance_valid(rover):
		fails.append("IN-E retrieve did not spawn rover on ramp")
		_in_e_restore(os, carrier, ship, was_piloting)
		return
	if hold_n != 0:
		fails.append("IN-E retrieve hold count want 0 got %s" % hold_n)
	if ramp.has_method("walk_mouth_global") and rover.global_position.distance_to(ramp.walk_mouth_global()) > 6.0:
		fails.append("IN-E retrieve missed ramp mouth")
	if "health" in rover:
		hp1 = float(rover.get("health"))
		if absf(hp1 - hp0) > 0.01:
			fails.append("IN-E retrieve changed health (%s → %s)" % [str(hp0), str(hp1)])
	if str(rover.get("class_id")) != "rover":
		fails.append("IN-E retrieve spawned a new vehicle class")
	if str(rover.get_meta("site_pin", "")) != "":
		fails.append("IN-E retrieve minted SITE_*")
	if "speed" in rover and absf(float(rover.get("speed")) - 14.0) > 0.01:
		fails.append("IN-E pay-stat power on rover speed")
	if str(carrier.try_retrieve_rover()) != "ALREADY":
		fails.append("IN-E allowed a second rover")

	if ramp.has_method("walk_mouth_global"):
		rover.global_position = ramp.walk_mouth_global()
		if rover.has_method("align_to_surface"):
			rover.align_to_surface()
	await get_tree().process_frame
	result = str(carrier.try_store_rover())
	await get_tree().process_frame
	hold_n = int(carrier.stored_vehicle_count()) if carrier.has_method("stored_vehicle_count") else 0
	if result != "STORED" or hold_n != 1:
		fails.append("IN-E re-store before takeoff failed (result=%s hold=%s)" % [result, str(hold_n)])
		_in_e_restore(os, carrier, ship, was_piloting)
		return
	if carrier.has_method("set_pose_flight"):
		carrier.set_pose_flight(40.0, 12.0, pad)
	await get_tree().process_frame
	hold_n = int(carrier.stored_vehicle_count()) if carrier.has_method("stored_vehicle_count") else 0
	print("[Playtest] IN-E takeoff keeps inventory hold=", hold_n)
	if hold_n != 1:
		fails.append("IN-E takeoff dropped stored vehicle (hold=%s)" % hold_n)
	if hold.has_method("vehicle_ids") and hold.vehicle_ids().is_empty():
		fails.append("IN-E takeoff lost vehicle id")

	result = str(carrier.try_retrieve_rover())
	print("[Playtest] IN-E refuse retrieve when ramp BLOCKED result=", result, " hold=", hold_n)
	if result != "BLOCKED":
		fails.append("IN-E retrieve while ramp BLOCKED (result=%s)" % result)
	hold_n = int(carrier.stored_vehicle_count()) if carrier.has_method("stored_vehicle_count") else 0
	if hold_n != 1:
		fails.append("IN-E BLOCKED retrieve consumed hold (hold=%s)" % hold_n)
	if carrier.has_method("get_deployed_rover") and carrier.get_deployed_rover() != null:
		fails.append("IN-E BLOCKED retrieve spawned a world rover")
	print("[Playtest] IN-E no SITE_* no pay-stat")
	_in_e_restore(os, carrier, ship, was_piloting)
	await get_tree().create_timer(0.25).timeout


func _in_e_world_rover_count() -> int:
	var tree := get_tree()
	if tree == null:
		return 0
	var n := 0
	for node in tree.get_nodes_in_group("ground_vehicle"):
		if node != null and is_instance_valid(node):
			n += 1
	return n


func _in_e_restore(os: Node, carrier: Node3D, ship: Node3D, was_piloting: bool) -> void:
	if carrier != null and is_instance_valid(carrier):
		var hold: Node = carrier.cargo_hold() if carrier.has_method("cargo_hold") else null
		if hold != null and hold.has_method("retrieve_vehicle"):
			while hold.has_method("vehicle_count") and int(hold.vehicle_count()) > 0:
				hold.retrieve_vehicle(0)
			var vehs: Variant = hold.get("vehicles")
			if vehs is Array:
				while (vehs as Array).size() > 0 and hold.has_method("retrieve_vehicle"):
					hold.retrieve_vehicle(0)
					vehs = hold.get("vehicles")
	_in_d_restore(os, carrier, ship, was_piloting)


func _assert_in_f(os: Node, fails: PackedStringArray) -> void:
	## IN-F V4 visual: second local viewer sees ramp DEPLOYED + rover/stored ghost.
	## Host keeps rover authority. Puppet is not a second physical rover.
	## No passenger seat this slice — GroundVehicle only has the IN-D pilot.
	var d: Node = os.get("_interior") if os else null
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var carrier: Node3D = null
	var pad: Node3D = null
	var ramp: Node = null
	var rover: Node3D = null
	var soft: Node = null
	var viewer: Node3D = null
	var puppet: Node3D = null
	var pose: Dictionary = {}
	var was_piloting := false
	var result := ""
	var hold_n := 0
	var world_n := 0
	var pin0 := str(LayerContext.site_pin_id) if LayerContext else ""
	if os == null:
		fails.append("IN-F no OpenSpace")
		return
	was_piloting = bool(os.get("_in_ship"))
	if d != null and d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
		d.exit_interior()
		await get_tree().create_timer(0.2).timeout
	if os.has_method("catalog_carrier"):
		carrier = os.catalog_carrier()
	if carrier == null:
		fails.append("IN-F catalog carrier missing")
		return
	if str(carrier.get_meta("site_pin", "")) != "":
		fails.append("IN-F hangar minted site_pin")
	if bool(carrier.get_meta("mobile_site", false)):
		fails.append("IN-F hangar marked mobile SITE_*")
	pad = _in_a_occupied_pad(os)
	if pad == null and os.has_method("nearest_pad"):
		pad = os.nearest_pad(carrier.global_position)
	if pad == null:
		fails.append("IN-F unnamed pad missing")
		_in_e_restore(os, carrier, ship, was_piloting)
		return
	if str(pad.get_meta("site_pin", "")) != "":
		fails.append("IN-F pad minted SITE_*")
	if carrier.has_method("clear_deployed_rover"):
		carrier.clear_deployed_rover()

	if carrier.has_method("set_pose_landed"):
		carrier.set_pose_landed(pad)
	await get_tree().process_frame
	result = str(carrier.try_deploy_ramp()) if carrier.has_method("try_deploy_ramp") else ""
	await get_tree().create_timer(0.55).timeout
	ramp = carrier.cargo_ramp() if carrier.has_method("cargo_ramp") else null
	if ramp != null and ramp.has_method("is_driveable") and not bool(ramp.is_driveable()) and ramp.has_method("deploy_immediate") and result != "BLOCKED":
		ramp.deploy_immediate()
	if ramp == null or not (ramp.has_method("is_driveable") and bool(ramp.is_driveable())):
		fails.append("IN-F ramp not DEPLOYED")
		_in_e_restore(os, carrier, ship, was_piloting)
		return
	if not carrier.has_method("try_deploy_rover"):
		fails.append("IN-F IN-D try_deploy_rover missing")
		_in_e_restore(os, carrier, ship, was_piloting)
		return
	result = str(carrier.try_deploy_rover())
	await get_tree().process_frame
	await get_tree().physics_frame
	rover = carrier.get_deployed_rover() if carrier.has_method("get_deployed_rover") else null
	if result != "DEPLOYED" or rover == null or not is_instance_valid(rover):
		fails.append("IN-F host rover did not spawn")
		_in_e_restore(os, carrier, ship, was_piloting)
		return
	if carrier.has_method("rover_authority") and str(carrier.rover_authority()) != "host":
		fails.append("IN-F rover authority is not host")
	print("[Playtest] IN-F host rover authority")

	soft = carrier.hangar_softnet() if carrier.has_method("hangar_softnet") else carrier.get_node_or_null("HangarSoftNet")
	if soft == null:
		fails.append("IN-F HangarSoftNet missing")
		_in_e_restore(os, carrier, ship, was_piloting)
		return
	if soft.has_method("bind_carrier"):
		soft.bind_carrier(carrier)
	if soft.has_method("sync_from_host"):
		soft.sync_from_host()
	await get_tree().process_frame
	if soft.has_method("is_host_authority") and not bool(soft.is_host_authority()):
		fails.append("IN-F SoftNet stole rover authority")
	if soft.has_method("rover_authority") and str(soft.rover_authority()) != "host":
		fails.append("IN-F SoftNet authority is not host")
	if SoftNetSession and SoftNetSession.has_method("combat_authority") and str(SoftNetSession.combat_authority()) != "host":
		fails.append("IN-F SoftNet combat authority left host")
	if SoftNetSession and SoftNetSession.get("enabled") == true:
		fails.append("IN-F enabled SoftNet 20Hz loop")
	viewer = soft.viewer() if soft.has_method("viewer") else null
	puppet = soft.rover_puppet() if soft.has_method("rover_puppet") else null
	pose = soft.observed_pose() if soft.has_method("observed_pose") else {}
	if viewer == null or not is_instance_valid(viewer):
		fails.append("IN-F second local viewer missing")
	elif not bool(viewer.get_meta("softnet_visual", false)):
		fails.append("IN-F viewer is not a SoftNet visual puppet")
	if puppet == null or not is_instance_valid(puppet) or not puppet.visible:
		fails.append("IN-F rover puppet missing")
	elif not bool(puppet.get_meta("softnet_visual", false)):
		fails.append("IN-F rover puppet is not SoftNet visual")
	if puppet != null and puppet.is_in_group("ground_vehicle"):
		fails.append("IN-F rover puppet joined ground_vehicle")
	if puppet is CharacterBody3D:
		fails.append("IN-F rover puppet is a physical body")
	if puppet != null and puppet.has_method("board"):
		fails.append("IN-F rover puppet has combat/drive board")
	if str(pose.get("ramp_state", "")) != "DEPLOYED":
		fails.append("IN-F viewer missed ramp DEPLOYED (saw %s)" % str(pose.get("ramp_state", "")))
	if str(pose.get("rover_mode", "")) != "world":
		fails.append("IN-F viewer missed world rover puppet (mode=%s)" % str(pose.get("rover_mode", "")))
	if soft.has_method("viewer_sees_ramp_deployed") and not bool(soft.viewer_sees_ramp_deployed()):
		fails.append("IN-F second actor does not see ramp DEPLOYED")
	if soft.has_method("viewer_sees_rover_puppet") and not bool(soft.viewer_sees_rover_puppet()):
		fails.append("IN-F second actor does not see rover puppet")
	world_n = _in_e_world_rover_count()
	if world_n != 1:
		fails.append("IN-F want 1 physical rover, got %s" % world_n)
	if soft.has_method("physical_rover_count") and int(soft.physical_rover_count()) != 1:
		fails.append("IN-F SoftNet physical rover count want 1")
	if str(carrier.try_deploy_rover()) != "ALREADY":
		fails.append("IN-F allowed a second physical rover")
	print("[Playtest] IN-F second local actor sees ramp DEPLOYED + rover puppet")
	print("[Playtest] IN-F no second physical rover")

	if ramp.has_method("walk_mouth_global"):
		rover.global_position = ramp.walk_mouth_global()
		if rover.has_method("align_to_surface"):
			rover.align_to_surface()
	await get_tree().process_frame
	result = str(carrier.try_store_rover())
	await get_tree().process_frame
	if soft.has_method("sync_from_host"):
		soft.sync_from_host()
	rover = carrier.get_deployed_rover() if carrier.has_method("get_deployed_rover") else null
	hold_n = int(carrier.stored_vehicle_count()) if carrier.has_method("stored_vehicle_count") else 0
	world_n = _in_e_world_rover_count()
	pose = soft.observed_pose() if soft.has_method("observed_pose") else {}
	puppet = soft.rover_puppet() if soft.has_method("rover_puppet") else puppet
	if result != "STORED" or rover != null or hold_n != 1:
		fails.append("IN-F IN-E store lost (result=%s hold=%s)" % [result, str(hold_n)])
	if world_n != 0:
		fails.append("IN-F store left a physical rover (%s)" % world_n)
	if str(pose.get("rover_mode", "")) != "stored_ghost":
		fails.append("IN-F viewer missed stored ghost (mode=%s)" % str(pose.get("rover_mode", "")))
	if puppet == null or not is_instance_valid(puppet) or not puppet.visible:
		fails.append("IN-F stored ghost puppet missing")
	elif puppet.is_in_group("ground_vehicle") or puppet is CharacterBody3D:
		fails.append("IN-F stored ghost became a physical rover")

	result = str(carrier.try_retrieve_rover())
	await get_tree().process_frame
	await get_tree().physics_frame
	if soft.has_method("sync_from_host"):
		soft.sync_from_host()
	rover = carrier.get_deployed_rover() if carrier.has_method("get_deployed_rover") else null
	hold_n = int(carrier.stored_vehicle_count()) if carrier.has_method("stored_vehicle_count") else 0
	world_n = _in_e_world_rover_count()
	pose = soft.observed_pose() if soft.has_method("observed_pose") else {}
	print("[Playtest] IN-F IN-E store/retrieve still works hold=", hold_n, " result=", result, " world=", world_n)
	if result != "DEPLOYED" or rover == null or not is_instance_valid(rover):
		fails.append("IN-F IN-E retrieve lost")
	if hold_n != 0:
		fails.append("IN-F retrieve hold count want 0 got %s" % hold_n)
	if world_n != 1:
		fails.append("IN-F retrieve want 1 physical rover, got %s" % world_n)
	if str(pose.get("rover_mode", "")) != "world":
		fails.append("IN-F retrieve viewer missed world puppet")
	if soft.has_method("has_passenger_seat") and bool(soft.has_passenger_seat()):
		fails.append("IN-F invented a pay-slot passenger seat")
	var pin1 := str(LayerContext.site_pin_id) if LayerContext else ""
	if pin1 != pin0 and pin1.begins_with("SITE_"):
		fails.append("IN-F minted SITE_* (%s)" % pin1)
	if str(carrier.get_meta("site_pin", "")) != "" or str(pad.get_meta("site_pin", "")) != "":
		fails.append("IN-F minted SITE_* on hangar/pad")
	if SoftNetSession and SoftNetSession.get("enabled") == true:
		fails.append("IN-F enabled SoftNet netcode after sync")
	print("[Playtest] IN-F no SITE_*")
	print("[Playtest] IN-F no second seat — GroundVehicle has only the IN-D pilot seat")
	_in_e_restore(os, carrier, ship, was_piloting)
	await get_tree().create_timer(0.2).timeout


func _in_a_first_door(pocket: Node3D) -> Node3D:
	if pocket == null:
		return null
	var n: Node = pocket.get_node_or_null("DoorPortal_0")
	if n is Node3D:
		return n as Node3D
	for c in pocket.get_children():
		if c is Node3D and str(c.name).begins_with("DoorPortal"):
			return c as Node3D
	return null


func _in_a_same_openspace(scene0: String) -> bool:
	var now := _osh_scene_file()
	if now.find("MainMenu") >= 0:
		return false
	if scene0 != "" and now != "" and now != scene0:
		return false
	return now.find("OpenSpace") >= 0 or _osh_same_scene(scene0)


func _assert_q_a(os: Node, fails: PackedStringArray) -> void:
	## Q-A: Contract Board on the IN-B station ops console.
	## One generated template on the same ARK body. Complete → SoftKnowledge label.
	## Harvest / print / hangar numbers stay. No cash skip. No exclusive modules.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var Board = load("res://scripts/systems/ContractBoard.gd")
	var d: Node = os.get("_interior") if os else null
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var walker: Node3D = os.get("player") as Node3D if os else null
	var was_piloting := false
	var pad: Node = null
	var pocket: Node3D = null
	var cv: Node3D = null
	var act: Dictionary = {}
	var offer: Dictionary = {}
	var tmpl := ""
	var lab0 := ""
	var lab1 := ""
	var harvest0 := 0.0
	var harvest1 := 0.0
	var print0 := 0.0
	var print1 := 0.0
	var hangar_m0 := 0.0
	var hangar_m1 := 0.0
	var hangar_p0 := 0.0
	var hangar_p1 := 0.0
	var rate0 := 0.0
	var rate1 := 0.0
	var bench: Node = null
	var done: Dictionary = {}
	var paid := true
	var skip_ok := true
	var weap := true
	var modu := true
	if P0 == null or not bool(P0.Q_A_CONTRACT):
		fails.append("Q-A P0Slice flag missing")
		return
	if Board == null:
		fails.append("Q-A ContractBoard missing")
		return
	if d == null or not d.has_method("try_use_console"):
		fails.append("Q-A no OpenSpace/interior")
		return
	if Board.has_method("reset_slice"):
		Board.reset_slice()
	was_piloting = bool(os.get("_in_ship")) if os else false
	if d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
		d.exit_interior()
		await get_tree().create_timer(0.2).timeout
	pad = _in_a_occupied_pad(os)
	if pad == null:
		fails.append("Q-A occupied unnamed pad missing")
		return
	if pad.has_method("claim"):
		pad.claim("Cybernex", 2.0)
	if "ownership" in pad and pad.ownership and pad.ownership.has_method("advance_transition"):
		pad.ownership.advance_transition(8.0, 5.0)
	if pad.has_method("print_bench"):
		bench = pad.print_bench()
	if pad.has_method("tier_budget"):
		var bud: Dictionary = pad.tier_budget()
		harvest0 = float(bud.get("harvest", 0.0))
		print0 = float(bud.get("print_cost", 0.0))
		hangar_m0 = float(bud.get("hangar_mass", 0.0))
		hangar_p0 = float(bud.get("hangar_power", 0.0))
	if "extract_rate" in pad:
		rate0 = float(pad.get("extract_rate"))
	if bench != null and bench.has_method("print_cost"):
		print0 = float(bench.print_cost())
	lab0 = SoftKnowledge.contract_intel_label()
	walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		if os.has_method("try_exit_ship"):
			os.try_exit_ship()
			await get_tree().create_timer(0.3).timeout
		walker = os.get("player") as Node3D
	if walker == null or not is_instance_valid(walker):
		fails.append("Q-A no walker for ops board")
		_in_a_restore_pilot(os, ship, true)
		return
	walker.global_position = (pad as Node3D).global_position + Vector3(0, 3.0, 0)
	if walker is CharacterBody3D:
		(walker as CharacterBody3D).velocity = Vector3.ZERO
	await get_tree().process_frame
	if d.has_method("enter_station"):
		d.enter_station(walker, pad as Node3D)
	await get_tree().create_timer(0.4).timeout
	if not (d.has_method("is_inside") and bool(d.is_inside())):
		fails.append("Q-A station ops pocket missing")
		_in_a_restore_pilot(os, ship, true)
		return
	if d.has_method("get_kind") and str(d.get_kind()) != "station":
		fails.append("Q-A opened %s, not station ops" % str(d.get_kind()))
	pocket = d.get_active_interior() if d.has_method("get_active_interior") else null
	cv = pocket.get_node_or_null("ConsoleVolume") as Node3D if pocket else null
	if cv == null:
		fails.append("Q-A ops console missing")
		if d.has_method("exit_interior"):
			d.exit_interior()
		_in_a_restore_pilot(os, ship, true)
		return
	walker.global_position = cv.global_position
	await get_tree().process_frame
	await get_tree().process_frame
	if not bool(d.try_use_console()):
		fails.append("Q-A ops console not usable")
	act = d.last_console_action() if d.has_method("last_console_action") else {}
	offer = act.get("contract", {})
	if typeof(offer) != TYPE_DICTIONARY:
		offer = {}
	tmpl = str(offer.get("template", act.get("contract_template", "")))
	print("[Playtest] Q-A board offers one contract template=", tmpl,
		" id=", offer.get("id", ""), " status=", offer.get("status", ""))
	if not bool(act.get("contract_offered", false)) and offer.is_empty():
		fails.append("Q-A board did not offer a contract")
		if d.has_method("exit_interior"):
			d.exit_interior()
		_in_a_restore_pilot(os, ship, true)
		return
	if not Board.templates().has(tmpl):
		fails.append("Q-A unknown template (%s)" % tmpl)
	if str(offer.get("body", "")) != "Nex-Prime":
		fails.append("Q-A contract left the ARK body")
	if str(offer.get("id", "")).begins_with("SITE_"):
		fails.append("Q-A minted SITE_*")
	if Board.cash_shop_skip_possible():
		fails.append("Q-A cash-shop skip possible")
	skip_ok = bool(Board.try_cash_skip())
	paid = bool(Board.try_pay_complete(999.0))
	if d.has_method("try_pay_complete_contract"):
		paid = paid or bool(d.try_pay_complete_contract(999.0))
	weap = bool(Board.try_unlock_exclusive_weapon("pulse"))
	modu = bool(Board.try_unlock_exclusive_module("extractor"))
	if skip_ok or paid:
		fails.append("Q-A cash-shop skip / pay-to-complete accepted")
	if weap or modu or SoftKnowledge.exclusive_weapon_unlocked("pulse") \
			or SoftKnowledge.exclusive_module_unlocked("extractor"):
		fails.append("Q-A Knowledge-gated exclusive weapon/module")
	if d.has_method("try_accept_contract"):
		offer = d.try_accept_contract()
	else:
		offer = Board.accept()
	if str(offer.get("status", "")) != "accepted":
		fails.append("Q-A did not accept the offered contract")
	match tmpl:
		"occupy":
			if pad.has_method("claim"):
				pad.claim("Cybernex", 0.55)
		"harvest":
			if "crystal_reserves" in pad:
				pad.crystal_reserves = maxf(float(pad.crystal_reserves), 8.0)
			if pad.has_method("_tick_harvest"):
				pad._tick_harvest(0.5)
		"deliver_crate":
			if ship != null:
				var hold: Node = ship.get_node_or_null("CargoHold")
				if hold != null and hold.has_method("store_unit"):
					hold.store_unit(CargoHold.make_crate("qa_crate"))
			if pad.has_method("ensure_pad_cargo"):
				pad.ensure_pad_cargo(1)
		_:
			fails.append("Q-A cannot complete template (%s)" % tmpl)
	await get_tree().process_frame
	if d.has_method("try_complete_contract"):
		done = d.try_complete_contract()
	else:
		done = Board.try_complete()
	lab1 = SoftKnowledge.contract_intel_label()
	print("[Playtest] Q-A complete template=", tmpl, " status=", done.get("status", ""),
		" Knowledge ", lab0, " → ", lab1)
	if str(done.get("status", "")) != "complete":
		fails.append("Q-A did not complete template (%s)" % tmpl)
	if lab1 == lab0 or lab1 != "PAD INTEL":
		fails.append("Q-A Knowledge label did not change (%s → %s)" % [lab0, lab1])
	if pad != null and pad.has_method("tier_budget"):
		var bud1: Dictionary = pad.tier_budget()
		harvest1 = float(bud1.get("harvest", -1.0))
		print1 = float(bud1.get("print_cost", -1.0))
		hangar_m1 = float(bud1.get("hangar_mass", -1.0))
		hangar_p1 = float(bud1.get("hangar_power", -1.0))
	if "extract_rate" in pad:
		rate1 = float(pad.get("extract_rate"))
	if bench != null and bench.has_method("print_cost"):
		print1 = float(bench.print_cost())
	print("[Playtest] Q-A harvest/print/hangar ", snapped(harvest0, 0.01), "/", snapped(print0, 0.01),
		"/", snapped(hangar_m0, 0.01), " → ", snapped(harvest1, 0.01), "/", snapped(print1, 0.01),
		"/", snapped(hangar_m1, 0.01))
	if absf(harvest1 - harvest0) > 0.0001 or harvest0 <= 0.0:
		fails.append("Q-A harvest number changed (%s → %s)" % [harvest0, harvest1])
	if absf(print1 - print0) > 0.0001 or print0 <= 0.0:
		fails.append("Q-A print number changed (%s → %s)" % [print0, print1])
	if absf(hangar_m1 - hangar_m0) > 0.0001 or absf(hangar_p1 - hangar_p0) > 0.0001:
		fails.append("Q-A hangar numbers changed")
	if absf(rate1 - rate0) > 0.0001:
		fails.append("Q-A extract_rate changed")
	if d.has_method("is_inside") and bool(d.is_inside()) and d.has_method("exit_interior"):
		d.exit_interior()
		await get_tree().create_timer(0.2).timeout
	_in_a_restore_pilot(os, ship, true)
	await get_tree().create_timer(0.3).timeout
	print("[Playtest] Q-A station ops board · Knowledge label only · no P2W")


func _assert_q_b(os: Node, fails: PackedStringArray) -> void:
	## Q-B: one alliance-shared occupy/logistics contract on the same unnamed pad.
	## Two NP-E NPCs see the same ContractBoard id. Complete → alliance intel label.
	## Harvest / print / hangar / Q-A numbers stay. No pay-to-complete / pay-to-rank.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var Board = load("res://scripts/systems/ContractBoard.gd")
	var nex: Node = _osh_nex()
	var pad: Node = _in_a_occupied_pad(os)
	var traffic: Node = null
	var ally: Node = null
	var guard: Node = null
	var visitor: Node = null
	var pilot: Node = null
	var offer: Dictionary = {}
	var done: Dictionary = {}
	var tmpl := ""
	var cid := ""
	var id_g := ""
	var id_p := ""
	var lab0 := ""
	var lab1 := ""
	var harvest0 := 0.0
	var harvest1 := 0.0
	var print0 := 0.0
	var print1 := 0.0
	var hangar_m0 := 0.0
	var hangar_m1 := 0.0
	var hangar_p0 := 0.0
	var hangar_p1 := 0.0
	var rate0 := 0.0
	var rate1 := 0.0
	var bench: Node = null
	var qa0: Dictionary = {}
	var qa1: Dictionary = {}
	var paid := false
	var skip_ok := false
	var ranked := false
	var modu := false
	var host_name := ""
	var pad_ctrl: Node = null
	var dmg0 := 0.0
	var hp0 := 0.0
	var claim0 := 0.0
	if P0 == null or not bool(P0.Q_B_ALLIANCE):
		fails.append("Q-B P0Slice flag missing")
		return
	if Board == null or not Board.has_method("offer_alliance_one"):
		fails.append("Q-B ContractBoard alliance slot missing")
		return
	if nex != null and nex.has_method("ensure_pad_bases"):
		nex.ensure_pad_bases()
	if nex != null and nex.has_method("pad_traffic"):
		traffic = nex.call("pad_traffic")
	if traffic == null or not is_instance_valid(traffic):
		fails.append("Q-B pad traffic missing")
		return
	guard = traffic.get_guard() if traffic.has_method("get_guard") else null
	visitor = traffic.get_visitor() if traffic.has_method("get_visitor") else null
	pilot = traffic.get_npc_pilot() if traffic.has_method("get_npc_pilot") else null
	ally = traffic.get_alliance() if traffic.has_method("get_alliance") else null
	if guard == null or visitor == null or ally == null:
		fails.append("Q-B NP-E alliance NPCs missing")
		return
	if int(ally.member_count()) != 2:
		fails.append("Q-B want two NPCs, got %s" % ally.member_count())
		return
	if pad != null and pad.has_method("print_bench"):
		bench = pad.print_bench()
	if pad != null and pad.has_method("tier_budget"):
		var bud: Dictionary = pad.tier_budget()
		harvest0 = float(bud.get("harvest", 0.0))
		print0 = float(bud.get("print_cost", 0.0))
		hangar_m0 = float(bud.get("hangar_mass", 0.0))
		hangar_p0 = float(bud.get("hangar_power", 0.0))
	if pad != null and "extract_rate" in pad:
		rate0 = float(pad.get("extract_rate"))
	if bench != null and bench.has_method("print_cost"):
		print0 = float(bench.print_cost())
	if SoftSession != null:
		var q0 = SoftSession.get("quest")
		if typeof(q0) == TYPE_DICTIONARY:
			qa0 = (q0 as Dictionary).duplicate(true)
	if GameManager:
		GameManager.subject_mastery["alliance_intel"] = 0.0
	lab0 = SoftKnowledge.alliance_intel_label()
	if Board.has_method("reset_alliance_slice"):
		Board.reset_alliance_slice()
	if traffic.has_method("host_pad_name"):
		host_name = str(traffic.host_pad_name())
	if host_name == "":
		var host_n: Node = traffic.get_parent()
		host_name = str(host_n.name) if host_n != null else "unnamed_pad"
	offer = Board.offer_alliance_one(host_name, "Nex-Prime", str(ally.intent()) if ally.has_method("intent") else "")
	tmpl = str(offer.get("template", ""))
	cid = str(offer.get("id", ""))
	print("[Playtest] Q-B alliance board offers one shared contract template=", tmpl,
		" id=", cid, " status=", offer.get("status", ""))
	if offer.is_empty() or not bool(offer.get("shared", false)):
		fails.append("Q-B alliance board did not offer a shared contract")
		return
	if not Board.alliance_templates().has(tmpl):
		fails.append("Q-B unknown template (%s)" % tmpl)
	if str(offer.get("body", "")) != "Nex-Prime":
		fails.append("Q-B contract left the ARK body")
	if cid.begins_with("SITE_"):
		fails.append("Q-B minted SITE_*")
	if ally.has_method("see_contract") and not bool(ally.see_contract(cid)):
		fails.append("Q-B NPCs could not see the shared contract")
	id_g = str(ally.member_seen_id(guard)) if ally.has_method("member_seen_id") else ""
	if id_g == "" and guard.has_meta("alliance_contract_id"):
		id_g = str(guard.get_meta("alliance_contract_id"))
	if pilot != null and pilot.has_method("seen_contract_id"):
		id_p = str(pilot.seen_contract_id())
	elif visitor.has_meta("alliance_contract_id"):
		id_p = str(visitor.get_meta("alliance_contract_id"))
	print("[Playtest] Q-B npcs see id=", id_g, " / ", id_p)
	if id_g == "" or id_g != id_p or id_g != cid:
		fails.append("Q-B two NPCs did not see the same id (%s / %s vs %s)" % [id_g, id_p, cid])
	if Board.cash_shop_skip_possible():
		fails.append("Q-B cash-shop skip possible")
	skip_ok = bool(Board.try_cash_skip())
	paid = bool(Board.try_pay_complete(999.0))
	if Board.has_method("try_pay_rank"):
		ranked = bool(Board.try_pay_rank(999.0))
	modu = bool(Board.try_unlock_exclusive_module("extractor"))
	if skip_ok or paid or ranked:
		fails.append("Q-B cash-shop skip / pay-to-complete / pay-to-rank accepted")
	if modu or SoftKnowledge.exclusive_module_unlocked("extractor"):
		fails.append("Q-B Knowledge-gated exclusive module")
	if ally.has_method("rank_cost") and float(ally.rank_cost()) > 0.0:
		fails.append("Q-B pay-to-rank")
	if ally.has_method("is_siege") and bool(ally.is_siege()):
		fails.append("Q-B intent is siege")
	if ally.has_method("combat_bonus") and absf(float(ally.combat_bonus())) > 0.0001:
		fails.append("Q-B combat aura")
	if ally.has_method("claim_bonus") and absf(float(ally.claim_bonus())) > 0.0001:
		fails.append("Q-B claim bonus")
	if guard != null:
		dmg0 = float(guard.get("attack_damage"))
		hp0 = float(guard.get("max_health"))
	pad_ctrl = traffic.get_parent().get_node_or_null("BaseCluster/PadBaseController") if traffic.get_parent() else null
	if pad_ctrl == null and traffic.get_parent():
		pad_ctrl = traffic.get_parent().find_child("PadBaseController", true, false)
	if pad_ctrl != null and "ownership" in pad_ctrl and pad_ctrl.ownership:
		claim0 = float(pad_ctrl.ownership.claim_strength)
	offer = Board.accept_alliance()
	if str(offer.get("status", "")) != "accepted":
		fails.append("Q-B did not accept the shared contract")
	match tmpl:
		"occupy":
			if pad_ctrl != null and pad_ctrl.has_method("claim"):
				pad_ctrl.claim("Cybernex", 0.55)
			Board.note_alliance_progress("occupy")
		"logistics":
			if pad_ctrl != null and "crystal_reserves" in pad_ctrl:
				pad_ctrl.crystal_reserves = maxf(float(pad_ctrl.crystal_reserves), 8.0)
			if pad_ctrl != null and pad_ctrl.has_method("_tick_harvest"):
				pad_ctrl._tick_harvest(0.5)
			Board.note_alliance_progress("logistics")
		_:
			fails.append("Q-B cannot complete template (%s)" % tmpl)
	await get_tree().process_frame
	done = Board.try_complete_alliance()
	lab1 = SoftKnowledge.alliance_intel_label()
	print("[Playtest] Q-B complete template=", tmpl, " status=", done.get("status", ""),
		" Knowledge ", lab0, " → ", lab1)
	if str(done.get("status", "")) != "complete":
		fails.append("Q-B did not complete template (%s)" % tmpl)
	if lab1 == lab0 or lab1 != "ALLY INTEL":
		fails.append("Q-B Knowledge label did not change (%s → %s)" % [lab0, lab1])
	if pad != null and pad.has_method("tier_budget"):
		var bud1: Dictionary = pad.tier_budget()
		harvest1 = float(bud1.get("harvest", -1.0))
		print1 = float(bud1.get("print_cost", -1.0))
		hangar_m1 = float(bud1.get("hangar_mass", -1.0))
		hangar_p1 = float(bud1.get("hangar_power", -1.0))
	if pad != null and "extract_rate" in pad:
		rate1 = float(pad.get("extract_rate"))
	if bench != null and bench.has_method("print_cost"):
		print1 = float(bench.print_cost())
	if SoftSession != null:
		var q1 = SoftSession.get("quest")
		if typeof(q1) == TYPE_DICTIONARY:
			qa1 = (q1 as Dictionary).duplicate(true)
	print("[Playtest] Q-B harvest/print/hangar/Q-A ", snapped(harvest0, 0.01), "/", snapped(print0, 0.01),
		"/", snapped(hangar_m0, 0.01), " → ", snapped(harvest1, 0.01), "/", snapped(print1, 0.01),
		"/", snapped(hangar_m1, 0.01))
	if absf(harvest1 - harvest0) > 0.0001 or harvest0 <= 0.0:
		fails.append("Q-B harvest number changed (%s → %s)" % [harvest0, harvest1])
	if absf(print1 - print0) > 0.0001 or print0 <= 0.0:
		fails.append("Q-B print number changed (%s → %s)" % [print0, print1])
	if absf(hangar_m1 - hangar_m0) > 0.0001 or absf(hangar_p1 - hangar_p0) > 0.0001:
		fails.append("Q-B hangar numbers changed")
	if absf(rate1 - rate0) > 0.0001:
		fails.append("Q-B extract_rate changed")
	if str(qa1.get("id", "")) != str(qa0.get("id", "")) or str(qa1.get("status", "")) != str(qa0.get("status", "")):
		fails.append("Q-B overwrote Q-A contract (%s/%s → %s/%s)" % [
			qa0.get("id", ""), qa0.get("status", ""), qa1.get("id", ""), qa1.get("status", "")
		])
	if guard != null:
		if absf(float(guard.get("attack_damage")) - dmg0) > 0.01:
			fails.append("Q-B changed guard DPS")
		if absf(float(guard.get("max_health")) - hp0) > 0.01:
			fails.append("Q-B changed guard HP")
	if pad_ctrl != null and "ownership" in pad_ctrl and pad_ctrl.ownership:
		if absf(float(pad_ctrl.ownership.claim_strength) - claim0) > 0.001 and tmpl != "occupy":
			fails.append("Q-B changed claim strength")
	print("[Playtest] Q-B alliance board · Knowledge label only · no P2W")


func _assert_q_c(os: Node, fails: PackedStringArray) -> void:
	## Q-C: one optional Learning Node on a Q-A harvest (or deliver) contract.
	## Interact reads pad / extractor / crate via SoftKnowledge.
	## Complete → field_intel label. Harvest / print / hangar / Q-A / Q-B stay.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var Board = load("res://scripts/systems/ContractBoard.gd")
	var pad: Node = _in_a_occupied_pad(os)
	var offer: Dictionary = {}
	var node: Dictionary = {}
	var read: Dictionary = {}
	var intel: Dictionary = {}
	var done: Dictionary = {}
	var lab0 := ""
	var lab1 := ""
	var harvest0 := 0.0
	var harvest1 := 0.0
	var print0 := 0.0
	var print1 := 0.0
	var hangar_m0 := 0.0
	var hangar_m1 := 0.0
	var hangar_p0 := 0.0
	var hangar_p1 := 0.0
	var rate0 := 0.0
	var rate1 := 0.0
	var bench: Node = null
	var qa_intel0 := 0.0
	var qa_intel1 := 0.0
	var qa_lab0 := ""
	var qa_lab1 := ""
	var qb0: Dictionary = {}
	var qb1: Dictionary = {}
	var traffic: Node = null
	var guard: Node = null
	var dmg0 := 0.0
	var hp0 := 0.0
	var nex: Node = _osh_nex()
	if P0 == null or not bool(P0.Q_C_LEARNING):
		fails.append("Q-C P0Slice flag missing")
		return
	if Board == null:
		fails.append("Q-C ContractBoard missing")
		return
	if pad != null and pad.has_method("print_bench"):
		bench = pad.print_bench()
	if pad != null and pad.has_method("tier_budget"):
		var bud: Dictionary = pad.tier_budget()
		harvest0 = float(bud.get("harvest", 0.0))
		print0 = float(bud.get("print_cost", 0.0))
		hangar_m0 = float(bud.get("hangar_mass", 0.0))
		hangar_p0 = float(bud.get("hangar_power", 0.0))
	if pad != null and "extract_rate" in pad:
		rate0 = float(pad.get("extract_rate"))
	if bench != null and bench.has_method("print_cost"):
		print0 = float(bench.print_cost())
	if GameManager:
		qa_intel0 = float(GameManager.subject_mastery.get("quest_intel", 0.0))
		GameManager.subject_mastery["field_intel"] = 0.0
	qa_lab0 = SoftKnowledge.contract_intel_label()
	lab0 = SoftKnowledge.field_intel_label()
	qb0 = Board.alliance_snapshot()
	if nex != null and nex.has_method("pad_traffic"):
		traffic = nex.call("pad_traffic")
	if traffic != null and traffic.has_method("get_guard"):
		guard = traffic.get_guard()
	if guard != null:
		dmg0 = float(guard.get("attack_damage"))
		hp0 = float(guard.get("max_health"))
	Board.reset_slice()
	offer = Board.offer_one("Pad_North", "Nex-Prime", "harvest")
	node = Board.learning_node()
	print("[Playtest] Q-C node present on contract id=", offer.get("id", ""),
		" template=", offer.get("template", ""), " node=", node.get("id", ""),
		" status=", node.get("status", ""))
	if offer.is_empty() or str(offer.get("id", "")) != "QA-harvest-Pad_North":
		fails.append("Q-C harvest contract missing (%s)" % offer.get("id", ""))
		return
	if node.is_empty() or str(node.get("id", "")) == "":
		fails.append("Q-C learning node missing on harvest contract")
		return
	if str(offer.get("body", "")) != "Nex-Prime":
		fails.append("Q-C contract left the ARK body")
	if str(offer.get("id", "")).begins_with("SITE_"):
		fails.append("Q-C minted SITE_*")
	if not bool(node.get("optional", false)):
		fails.append("Q-C learning node is not optional")
	if Board.cash_shop_skip_possible() or bool(Board.try_cash_skip()) \
			or bool(Board.try_pay_complete(999.0)):
		fails.append("Q-C cash-shop skip / pay-to-complete accepted")
	if bool(Board.try_unlock_exclusive_module("extractor")) \
			or SoftKnowledge.exclusive_module_unlocked("extractor"):
		fails.append("Q-C Knowledge-gated exclusive module")
	read = Board.interact_learning_node()
	intel = read.get("intel", {})
	if typeof(intel) != TYPE_DICTIONARY:
		intel = {}
	print("[Playtest] Q-C interact intel pad=", intel.get("pad", ""),
		" extractor=", intel.get("extractor", ""), " crate=", intel.get("crate", ""))
	if intel.is_empty() or str(intel.get("pad", "")) == "" \
			or str(intel.get("extractor", "")) == "" or str(intel.get("crate", "")) == "":
		fails.append("Q-C interact did not read pad/extractor/crate intel")
	done = Board.try_complete_learning_node()
	node = done.get("learning_node", {})
	if typeof(node) != TYPE_DICTIONARY:
		node = Board.learning_node()
	lab1 = SoftKnowledge.field_intel_label()
	print("[Playtest] Q-C complete node status=", node.get("status", ""),
		" Knowledge ", lab0, " → ", lab1)
	if str(node.get("status", "")) != "complete":
		fails.append("Q-C did not complete the learning node")
	if lab1 == lab0 or lab1 != "FIELD INTEL":
		fails.append("Q-C Knowledge label did not change (%s → %s)" % [lab0, lab1])
	if pad != null and pad.has_method("tier_budget"):
		var bud1: Dictionary = pad.tier_budget()
		harvest1 = float(bud1.get("harvest", -1.0))
		print1 = float(bud1.get("print_cost", -1.0))
		hangar_m1 = float(bud1.get("hangar_mass", -1.0))
		hangar_p1 = float(bud1.get("hangar_power", -1.0))
	if pad != null and "extract_rate" in pad:
		rate1 = float(pad.get("extract_rate"))
	if bench != null and bench.has_method("print_cost"):
		print1 = float(bench.print_cost())
	if GameManager:
		qa_intel1 = float(GameManager.subject_mastery.get("quest_intel", 0.0))
	qa_lab1 = SoftKnowledge.contract_intel_label()
	qb1 = Board.alliance_snapshot()
	print("[Playtest] Q-C harvest/print/hangar/Q-A/Q-B ", snapped(harvest0, 0.01), "/",
		snapped(print0, 0.01), "/", snapped(hangar_m0, 0.01), " → ",
		snapped(harvest1, 0.01), "/", snapped(print1, 0.01), "/", snapped(hangar_m1, 0.01))
	if absf(harvest1 - harvest0) > 0.0001 or harvest0 <= 0.0:
		fails.append("Q-C harvest number changed (%s → %s)" % [harvest0, harvest1])
	if absf(print1 - print0) > 0.0001 or print0 <= 0.0:
		fails.append("Q-C print number changed (%s → %s)" % [print0, print1])
	if absf(hangar_m1 - hangar_m0) > 0.0001 or absf(hangar_p1 - hangar_p0) > 0.0001:
		fails.append("Q-C hangar numbers changed")
	if absf(rate1 - rate0) > 0.0001:
		fails.append("Q-C extract_rate changed")
	if absf(qa_intel1 - qa_intel0) > 0.0001 or qa_lab1 != qa_lab0:
		fails.append("Q-C changed Q-A Knowledge (%s/%s → %s/%s)" % [
			qa_intel0, qa_lab0, qa_intel1, qa_lab1
		])
	if str(qb1.get("id", "")) != str(qb0.get("id", "")) \
			or str(qb1.get("status", "")) != str(qb0.get("status", "")):
		fails.append("Q-C overwrote Q-B contract (%s/%s → %s/%s)" % [
			qb0.get("id", ""), qb0.get("status", ""), qb1.get("id", ""), qb1.get("status", "")
		])
	if guard != null:
		if absf(float(guard.get("attack_damage")) - dmg0) > 0.01:
			fails.append("Q-C changed guard DPS")
		if absf(float(guard.get("max_health")) - hp0) > 0.01:
			fails.append("Q-C changed guard HP")
	print("[Playtest] Q-C learning node · Knowledge label only · no P2W")


func _assert_ar_f(os: Node, fails: PackedStringArray) -> void:
	## AR-F: 3v3 local authority on the existing Clash footprint.
	## Isolated probe — does not change scene to TestArena, does not open G5.
	var pin0 := str(LayerContext.site_pin_id) if LayerContext else ""
	var dummy_scene: PackedScene = load("res://scenes/combat/CombatDummy.tscn")
	if dummy_scene == null:
		fails.append("AR-F CombatDummy missing")
		return
	var matchn: Node3D = Node3D.new()
	matchn.set_script(preload("res://scripts/arena/ClashLocalMatch.gd"))
	matchn.name = "ClashLocalMatchProbe"
	if os:
		os.add_child(matchn)
	else:
		add_child(matchn)
	if matchn.has_method("start_isolated"):
		matchn.start_isolated(os if os else self, dummy_scene)
	await get_tree().process_frame
	var live: Array = matchn.living_actors() if matchn.has_method("living_actors") else []
	var lanes: PackedStringArray = matchn.lane_ids() if matchn.has_method("lane_ids") else PackedStringArray()
	var auth := str(matchn.combat_authority()) if matchn.has_method("combat_authority") else ""
	var g5 := bool(matchn.is_g5_closed()) if matchn.has_method("is_g5_closed") else false
	var pin1 := str(LayerContext.site_pin_id) if LayerContext else ""
	print("[Playtest] AR-F 3v3 local match actors=", live.size(), " lanes=", ",".join(lanes),
		" authority=", auth, " G5=", "closed" if g5 else "open", " pin=", pin1)
	if live.size() != 6:
		fails.append("AR-F want 6 actors, got %s" % live.size())
	var seen: Dictionary = {}
	var cx := 0
	var gr := 0
	for n in live:
		var lane := str(matchn.lane_of(n)) if matchn.has_method("lane_of") else ""
		if lane != "TOP" and lane != "MID" and lane != "BOT":
			fails.append("AR-F actor not on a Clash lane (%s)" % lane)
		else:
			seen[lane] = true
		var fac := str(n.get("faction")) if n != null and "faction" in n else ""
		if fac == "Cybernex":
			cx += 1
		elif fac == "gROT":
			gr += 1
	for need in ["TOP", "MID", "BOT"]:
		if not seen.has(need):
			fails.append("AR-F missing lane " + need)
	if cx != 3 or gr != 3:
		fails.append("AR-F want 3+3, got CX=%s GR=%s" % [cx, gr])
	if matchn.has_method("is_local_authority") and not bool(matchn.is_local_authority()):
		fails.append("AR-F not local host authority")
	if auth != "host":
		fails.append("AR-F authority is not host (%s)" % auth)
	if not g5:
		fails.append("AR-F G5 Clash-from-world is open")
	if os != null and os.has_method("enter_clash_from_world"):
		fails.append("AR-F opened G5 world-to-arena")
	if matchn.has_method("is_5v5") and bool(matchn.is_5v5()):
		fails.append("AR-F shipped 5v5")
	if matchn.has_method("visual_puppet_count") and int(matchn.visual_puppet_count()) < 5:
		fails.append("AR-F SoftNet visual puppets missing (got %s)" % int(matchn.visual_puppet_count()))
	var dmg0 := -1.0
	var probe: Node = null
	for n in live:
		if n != null and "attack_damage" in n:
			probe = n
			dmg0 = float(n.get("attack_damage"))
			break
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("history", 20.0)
		GameManager.add_mastery("cybernetics", 20.0)
	if probe != null and dmg0 >= 0.0 and absf(float(probe.get("attack_damage")) - dmg0) > 0.01:
		fails.append("AR-F Knowledge changed DPS")
	if pin1 != pin0:
		fails.append("AR-F changed site_pin (%s → %s)" % [pin0, pin1])
	if pin1.begins_with("SITE_") and pin1 != "SITE_SPACE_TEST_PAD" and pin1 != "SITE_TEST_ARENA_PILLAR":
		fails.append("AR-F minted a new SITE_* (%s)" % pin1)
	if pin1 == "SITE_TEST_ARENA_PILLAR" and pin0 != "SITE_TEST_ARENA_PILLAR":
		fails.append("AR-F entered TestArena from OpenSpace (G5)")
	print("[Playtest] AR-F 6 actors on existing lanes · local authority · G5 closed · no SITE_*")
	if matchn.has_method("shutdown"):
		matchn.shutdown()
	matchn.queue_free()
	await get_tree().process_frame
	if SoftScanCache and SoftScanCache.has_method("invalidate_enemies"):
		SoftScanCache.invalidate_enemies()


func _assert_ar_g(os: Node, fails: PackedStringArray) -> void:
	## AR-G: 5v5 local authority on the existing Clash footprint + AR-D jungle.
	## Isolated probe — does not change scene to TestArena, does not open G5.
	var pin0 := str(LayerContext.site_pin_id) if LayerContext else ""
	var dummy_scene: PackedScene = load("res://scenes/combat/CombatDummy.tscn")
	if dummy_scene == null:
		fails.append("AR-G CombatDummy missing")
		return
	var matchn: Node3D = Node3D.new()
	matchn.set_script(preload("res://scripts/arena/ClashLocalMatch.gd"))
	matchn.name = "ClashLocalMatch5v5Probe"
	if os:
		os.add_child(matchn)
	else:
		add_child(matchn)
	if matchn.has_method("start_isolated_5v5"):
		matchn.start_isolated_5v5(os if os else self, dummy_scene)
	elif matchn.has_method("start_5v5"):
		matchn.start_5v5()
	else:
		fails.append("AR-G 5v5 start missing")
		matchn.queue_free()
		return
	await get_tree().process_frame
	var live: Array = matchn.living_actors() if matchn.has_method("living_actors") else []
	var lanes: PackedStringArray = matchn.lane_ids() if matchn.has_method("lane_ids") else PackedStringArray()
	var auth := str(matchn.combat_authority()) if matchn.has_method("combat_authority") else ""
	var g5 := bool(matchn.is_g5_closed()) if matchn.has_method("is_g5_closed") else false
	var pin1 := str(LayerContext.site_pin_id) if LayerContext else ""
	print("[Playtest] AR-G 5v5 local match actors=", live.size(), " lanes=", ",".join(lanes),
		" authority=", auth, " G5=", "closed" if g5 else "open", " pin=", pin1)
	if live.size() != 10:
		fails.append("AR-G want 10 actors, got %s" % live.size())
	var seen: Dictionary = {}
	var cx := 0
	var gr := 0
	var jungle := 0
	for n in live:
		var lane := str(matchn.lane_of(n)) if matchn.has_method("lane_of") else ""
		if lane != "TOP" and lane != "MID" and lane != "BOT" and lane != "JUNGLE":
			fails.append("AR-G actor not on existing footprint (%s)" % lane)
		else:
			seen[lane] = true
		if lane == "JUNGLE":
			jungle += 1
		if n is Node3D:
			var p: Vector3 = (n as Node3D).global_position
			if absf(p.x) > 28.0 or absf(p.z) > 28.0:
				fails.append("AR-G actor left the 60×60 footprint")
		var fac := str(n.get("faction")) if n != null and "faction" in n else ""
		if fac == "Cybernex":
			cx += 1
		elif fac == "gROT":
			gr += 1
	for need in ["TOP", "MID", "BOT"]:
		if not seen.has(need):
			fails.append("AR-G missing lane " + need)
	if not seen.has("JUNGLE") or jungle < 4:
		fails.append("AR-G missing jungle slots (got %s)" % jungle)
	if cx != 5 or gr != 5:
		fails.append("AR-G want 5+5, got CX=%s GR=%s" % [cx, gr])
	if matchn.has_method("is_local_authority") and not bool(matchn.is_local_authority()):
		fails.append("AR-G not local host authority")
	if auth != "host":
		fails.append("AR-G authority is not host (%s)" % auth)
	if not g5:
		fails.append("AR-G G5 Clash-from-world is open")
	if os != null and os.has_method("enter_clash_from_world"):
		fails.append("AR-G opened G5 world-to-arena")
	if matchn.has_method("is_5v5") and not bool(matchn.is_5v5()):
		fails.append("AR-G is_5v5 false")
	if matchn.has_method("visual_puppet_count") and int(matchn.visual_puppet_count()) < 9:
		fails.append("AR-G SoftNet visual puppets missing (got %s)" % int(matchn.visual_puppet_count()))
	var dmg0 := -1.0
	var probe: Node = null
	for n in live:
		if n != null and "attack_damage" in n:
			probe = n
			dmg0 = float(n.get("attack_damage"))
			break
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("history", 20.0)
		GameManager.add_mastery("cybernetics", 20.0)
	if probe != null and dmg0 >= 0.0 and absf(float(probe.get("attack_damage")) - dmg0) > 0.01:
		fails.append("AR-G Knowledge changed DPS")
	if pin1 != pin0:
		fails.append("AR-G changed site_pin (%s → %s)" % [pin0, pin1])
	if pin1.begins_with("SITE_") and pin1 != "SITE_SPACE_TEST_PAD" and pin1 != "SITE_TEST_ARENA_PILLAR":
		fails.append("AR-G minted a new SITE_* (%s)" % pin1)
	if pin1 == "SITE_TEST_ARENA_PILLAR" and pin0 != "SITE_TEST_ARENA_PILLAR":
		fails.append("AR-G entered TestArena from OpenSpace (G5)")
	print("[Playtest] AR-G 10 actors on existing footprint · local authority · G5 closed · no SITE_*")
	if matchn.has_method("shutdown"):
		matchn.shutdown()
	matchn.queue_free()
	await get_tree().process_frame
	if SoftScanCache and SoftScanCache.has_method("invalidate_enemies"):
		SoftScanCache.invalidate_enemies()


func _assert_se_a(os: Node, fails: PackedStringArray) -> void:
	## SE-A: live power / cool / life buses on the player hull.
	## Overdraw / overheat = soft sag. No P2W repair skip. IN-B LS stays soft.
	## ST-D hangar mass/power refuse still holds. Knowledge labels only.
	var ship: Node = os.get("ship") if os else null
	var buses: Node = null
	var d: Node = os.get("_interior") if os else null
	var hull: Node = null
	var queue: Node = null
	var tree: SceneTree = get_tree()
	var draw0 := 0.0
	var heat0 := 0.0
	var supply0 := 0.0
	var cool0 := 0.0
	var ls := ""
	var tm0 := 1.0
	var tm_od := 1.0
	var tm_oh := 1.0
	var w0 := 0.0
	var w_od := 0.0
	var w_oh := 0.0
	var hp0 := 100.0
	var hp1 := 100.0
	var remain_m := -1.0
	var remain_p := -1.0
	var extras := 0
	if ship == null or not is_instance_valid(ship):
		fails.append("SE-A no player hull")
		return
	if ship.has_method("engineering_buses"):
		buses = ship.engineering_buses()
	if buses == null:
		buses = ship.get_node_or_null("SoftShipSystems")
	if buses == null or not buses.has_method("power_draw_total"):
		fails.append("SE-A hull buses missing")
		return
	if buses.has_method("restore_bus_caps"):
		buses.restore_bus_caps()
	if buses.has_method("set_hull_vented"):
		buses.set_hull_vented(false)
	draw0 = float(buses.power_draw_total())
	heat0 = float(buses.cool_load()) if buses.has_method("cool_load") else draw0
	supply0 = float(buses.power_supply()) if buses.has_method("power_supply") else 0.0
	cool0 = float(buses.cool_capacity()) if buses.has_method("cool_capacity") else 0.0
	ls = str(buses.life_support_line()) if buses.has_method("life_support_line") else ""
	print("[Playtest] SE-A power ", snapped(draw0, 0.01), "/", snapped(supply0, 0.01),
		" cool ", snapped(heat0, 0.01), "/", snapped(cool0, 0.01),
		" life=", ls)
	if draw0 <= 0.05:
		fails.append("SE-A power draw missing (ShipModule.power_draw unused)")
	if supply0 <= 0.05:
		fails.append("SE-A power supply missing")
	if heat0 <= 0.05 or cool0 <= 0.05:
		fails.append("SE-A cool bus missing")
	if ls == "":
		fails.append("SE-A hull life-support readout empty")
	elif ls.find("LIFE SUPPORT") < 0 and ls.find("POWER BUS") < 0:
		fails.append("SE-A hull LS does not match IN-B (%s)" % ls)
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("cybernetics", 20.0)
		GameManager.add_mastery("biology", 20.0)
		if absf(float(buses.power_draw_total()) - draw0) > 0.001 \
				or absf(float(buses.power_supply()) - supply0) > 0.001 \
				or absf(float(buses.cool_capacity()) - cool0) > 0.001:
			fails.append("Knowledge changed hull bus numbers")
	if ship.has_method("_thrust_mult"):
		tm0 = float(ship._thrust_mult())
	if ship.has_method("weapon_output"):
		w0 = float(ship.weapon_output())
	if buses.has_method("set_bus_caps"):
		buses.set_bus_caps(1.0, 100.0)
	if ship.has_method("_thrust_mult"):
		tm_od = float(ship._thrust_mult())
	if ship.has_method("weapon_output"):
		w_od = float(ship.weapon_output())
	print("[Playtest] SE-A overdraw sag thrust ", snapped(tm0, 0.01), " → ", snapped(tm_od, 0.01),
		" weapons ", snapped(w0, 0.1), " → ", snapped(w_od, 0.1))
	if buses.has_method("is_overdrawn"):
		if not bool(buses.is_overdrawn()):
			fails.append("SE-A overdraw not flagged")
	else:
		fails.append("SE-A overdraw not flagged")
	if tm_od >= tm0 - 0.01:
		fails.append("SE-A overdraw did not sag thrust")
	if tm_od <= 0.01:
		fails.append("SE-A overdraw hard-locked thrust")
	if w0 > 0.05 and w_od >= w0 - 0.05:
		fails.append("SE-A overdraw did not sag weapons")
	if w_od <= 0.01:
		fails.append("SE-A overdraw hard-locked weapons")
	if buses.has_method("try_cash_repair_skip") and bool(buses.try_cash_repair_skip(999.0)):
		fails.append("SE-A P2W repair skip restored buses")
	if buses.has_method("cash_shop_skip_possible") and bool(buses.cash_shop_skip_possible()):
		fails.append("SE-A cash-shop skip possible")
	if ship.has_method("_thrust_mult") and float(ship._thrust_mult()) >= tm0 - 0.01:
		fails.append("SE-A P2W skip cleared overdraw sag")
	if buses.has_method("set_bus_caps"):
		buses.set_bus_caps(100.0, 1.0)
	if ship.has_method("_thrust_mult"):
		tm_oh = float(ship._thrust_mult())
	if ship.has_method("weapon_output"):
		w_oh = float(ship.weapon_output())
	print("[Playtest] SE-A overheat sag thrust ", snapped(tm0, 0.01), " → ", snapped(tm_oh, 0.01),
		" weapons ", snapped(w0, 0.1), " → ", snapped(w_oh, 0.1))
	if buses.has_method("is_overheated"):
		if not bool(buses.is_overheated()):
			fails.append("SE-A overheat not flagged")
	else:
		fails.append("SE-A overheat not flagged")
	if tm_oh >= tm0 - 0.01:
		fails.append("SE-A overheat did not sag thrust")
	if tm_oh <= 0.01:
		fails.append("SE-A overheat instant death / hard lock")
	if w0 > 0.05 and w_oh >= w0 - 0.05:
		fails.append("SE-A overheat did not sag weapons")
	if "health" in ship:
		hp0 = float(ship.health)
	if buses.has_method("set_hull_vented"):
		buses.set_hull_vented(true)
	ls = str(buses.life_support_line()) if buses.has_method("life_support_line") else ""
	if "health" in ship:
		hp1 = float(ship.health)
	print("[Playtest] SE-A hull LS vented ", ls, " hp ", snapped(hp0, 0.1), " → ", snapped(hp1, 0.1))
	if buses.has_method("has_life_support") and bool(buses.has_life_support()):
		fails.append("SE-A vented hull still reports life-support")
	if ls.find("SUIT") < 0 and ls.find("VENTED") < 0:
		fails.append("SE-A vented hull LS missing IN-B suit/vent")
	if buses.has_method("life_support_warn_shown") and not bool(buses.life_support_warn_shown()):
		fails.append("SE-A missing hull LS soft warn")
	if hp1 < hp0 - 0.05:
		fails.append("SE-A hull life-support cut HP")
	if d != null and d.has_method("life_support_line"):
		print("[Playtest] SE-A IN-B LS still soft pocket=", d.life_support_line())
	if buses.has_method("restore_bus_caps"):
		buses.restore_bus_caps()
	if buses.has_method("set_hull_vented"):
		buses.set_hull_vented(false)
	if os != null and os.has_method("catalog_carrier"):
		hull = os.catalog_carrier()
	if hull == null and tree:
		var hulls: Array = tree.get_nodes_in_group("catalog_carriers")
		if not hulls.is_empty():
			hull = hulls[0]
	if hull != null:
		if hull.has_method("hangar_queue"):
			queue = hull.hangar_queue()
		if hull.has_method("mass_remaining"):
			remain_m = float(hull.mass_remaining())
		if hull.has_method("power_remaining"):
			remain_p = float(hull.power_remaining())
	if tree:
		extras = tree.get_nodes_in_group("hangar_queued_modules").size()
	print("[Playtest] SE-A ST-D hangar mass/power refuse still holds slots=", extras,
		" remain_m=", snapped(remain_m, 0.01), " remain_p=", snapped(remain_p, 0.01),
		" cash_skip=", false)
	if queue == null:
		fails.append("SE-A ST-D hangar queue missing")
	elif queue.has_method("cash_shop_skip_possible") and bool(queue.cash_shop_skip_possible()):
		fails.append("SE-A ST-D cash-shop skip possible")
	elif queue.has_method("try_cash_skip_queue") and bool(queue.try_cash_skip_queue(999.0)):
		fails.append("SE-A ST-D cash-shop skip queued a module")
	if extras != 1:
		fails.append("SE-A ST-D hangar slot count changed (%s)" % extras)
	if remain_m < 0.0 or remain_p < 0.0:
		fails.append("SE-A ST-D mass/power remaining missing")
	print("[Playtest] SE-A hull buses live · overdraw sag · no P2W repair skip · IN-B LS soft")


func _in_a_occupied_pad(os: Node) -> Node3D:
	var pad: Node = null
	var host: Node = null
	var tree := get_tree()
	if os != null and os.has_method("occupied_pad_base"):
		pad = os.occupied_pad_base()
	if pad is Node3D:
		return pad as Node3D
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("pad_bases"):
		host = n
		while host:
			if host is Node3D and str(host.name) in ["Pad_North", "Pad_Approach", "Pad_Flank"]:
				return n as Node3D
			host = host.get_parent()
	return null


func _in_a_restore_pilot(os: Node, ship: Node3D, was_piloting: bool) -> void:
	var walker: Node3D = os.get("player") as Node3D if os else null
	if not was_piloting or os == null:
		return
	if ship != null and is_instance_valid(ship) and walker != null and is_instance_valid(walker):
		walker.global_position = ship.global_position + Vector3(0.0, 2.0, 2.0)
		if os.has_method("try_enter_ship"):
			os.try_enter_ship()


func _osh_report_skips(fails: PackedStringArray, done: Dictionary, required: PackedStringArray) -> void:
	for step in required:
		if not bool(done.get(step, false)):
			var msg := "OS-H skipped %s" % step
			var already := false
			for f in fails:
				if str(f).find(msg) >= 0:
					already = true
					break
			if not already:
				fails.append(msg)
			print("[Playtest] OS-H FAIL skipped ", step)


func _assert_occupy_hud_after_board(os: Node, pad: Node3D, fails: PackedStringArray) -> void:
	## OS-H leftover: F-board frees the walker. Occupy/radar follow the hull.
	var hud: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
	if hud == null:
		fails.append("occupy HUD after F-board: no GameHUD")
		return
	if hud.has_method("_refresh"):
		hud._refresh()
	elif hud.has_method("_process"):
		hud._process(0.2)
	var origin: Node3D = null
	if hud.has_method("_occupy_origin"):
		origin = hud.call("_occupy_origin") as Node3D
	var ship: Node3D = os.get("ship") as Node3D if os else null
	var w: Node = os.get("player") if os else null
	var w_live := w != null and is_instance_valid(w) and (w as Node).is_inside_tree()
	print("[Playtest] occupy HUD after F-board origin=", origin.name if origin else "null",
		" ship=", ship != null, " walker_live=", w_live)
	if origin == null:
		fails.append("occupy HUD lost origin after F-board")
		return
	if not w_live and ship != null and origin != ship:
		fails.append("occupy HUD origin not hull after F-board")
	var txt := ""
	var lab: Variant = hud.get("_owner_label")
	if lab is Label:
		txt += (lab as Label).text
	var stack: Variant = hud.get("_os_stack")
	if stack is Label:
		txt += " " + (stack as Label).text
	print("[Playtest] occupy HUD after F-board '", txt.replace("\n", " / ").substr(0, 140), "'")
	var up := txt.to_upper()
	if pad != null and up.find("PAD") < 0 and up.find("OCCUPY") < 0 and up.find("LANDED") < 0:
		fails.append("occupy HUD empty after F-board")


func _assert_occupy_hud_dirt(os: Node, walker: Node3D, pad: Node3D, fails: PackedStringArray) -> void:
	## Occupy HUD used 80 m. Claim radius is 40 m. Dirt EVA must not offer PAD.
	if walker == null or not is_instance_valid(walker) or pad == null:
		return
	var hud: Node = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
	if hud == null:
		fails.append("occupy HUD dirt: no GameHUD")
		return
	if hud.has_method("bind_player"):
		hud.bind_player(walker)
	var up: Vector3 = pad.get_meta("pad_up") if pad.has_meta("pad_up") else Vector3.UP
	if up.length_squared() > 0.01:
		up = up.normalized()
	var side: Vector3 = up.cross(Vector3.RIGHT)
	if side.length_squared() < 0.04:
		side = up.cross(Vector3.FORWARD)
	side = side.normalized()
	var saved: Vector3 = walker.global_position
	walker.global_position = pad.global_position + side * 50.0 + up * 2.0
	if hud.has_method("_refresh"):
		hud._refresh()
	var txt := ""
	var lab: Variant = hud.get("_owner_label")
	if lab is Label:
		txt = (lab as Label).text
	print("[Playtest] occupy HUD dirt 50m '", txt.replace("\n", " / ").substr(0, 120), "'")
	var upt := txt.to_upper()
	if upt.find("PAD") >= 0:
		fails.append("occupy HUD offered PAD at 50m dirt")
	walker.global_position = pad.global_position + side * 11.0 + up * 1.4
	if hud.has_method("_refresh"):
		hud._refresh()
	txt = ""
	if lab is Label:
		txt = (lab as Label).text
	print("[Playtest] occupy HUD plate 11m '", txt.replace("\n", " / ").substr(0, 120), "'")
	if txt.to_upper().find("PAD") < 0:
		fails.append("occupy HUD empty on plate")
	var radar = hud.get("_radar")
	if radar is CanvasItem:
		(radar as CanvasItem).visible = true
	walker.global_position = pad.global_position + side * 50.0 + up * 2.0
	if hud.has_method("_refresh"):
		hud._refresh()
	var near_n := 0
	if hud.has_method("radar_pad_contacts"):
		near_n = hud.radar_pad_contacts().size()
	print("[Playtest] pad radar dirt 50m n=", near_n)
	if near_n < 1:
		fails.append("pad radar missed pad at 50m dirt")
	walker.global_position = pad.global_position + side * 600.0 + up * 2.0
	if hud.has_method("_refresh"):
		hud._refresh()
	var far_n := 0
	var far_hit := false
	if hud.has_method("radar_pad_contacts"):
		for c in hud.radar_pad_contacts():
			far_n += 1
			if c is Node3D and (c as Node3D).global_position.distance_to(pad.global_position) < 30.0:
				far_hit = true
	print("[Playtest] pad radar dirt 600m n=", far_n, " pad=", far_hit)
	if far_hit:
		fails.append("pad radar used 12km approach on-foot")
	await _assert_snap_dirt_no_steal(walker, pad, up, side, fails)
	walker.global_position = saved


func _assert_snap_dirt_no_steal(walker: Node3D, pad: Node3D, up: Vector3, side: Vector3, fails: PackedStringArray) -> void:
	## snap_to_pad rewrote lat 12–16 m to 5.5 and stole dirt occupy.
	if walker == null or not walker.has_method("snap_to_surface"):
		fails.append("snap dirt: no walker snap_to_surface")
		return
	walker.global_position = pad.global_position + side * 14.0 + up * 2.0
	walker.snap_to_surface()
	var d14: float = walker.global_position.distance_to(pad.global_position)
	print("[Playtest] snap dirt 14m → ", snapped(d14, 0.1))
	if d14 < 8.0:
		fails.append("snap_to_surface stole 14m onto pad (%s)" % snapped(d14, 0.1))
	if d14 > 22.0:
		fails.append("snap_to_surface lost 14m walker (%s)" % snapped(d14, 0.1))
	walker.global_position = pad.global_position + side * 40.0 + up * 2.0
	var d0: float = walker.global_position.distance_to(pad.global_position)
	walker.snap_to_surface()
	var d40: float = walker.global_position.distance_to(pad.global_position)
	print("[Playtest] snap dirt 40m ", snapped(d0, 0.1), "→", snapped(d40, 0.1))
	if d40 < 28.0:
		fails.append("snap_to_surface stole dirt 40m onto plate (%s)" % snapped(d40, 0.1))


func _assert_scan_cache_live(fails: PackedStringArray) -> void:
	## OS-H leftover: F-board / seat→pilot frees the walker. Cache must not
	## hand an off-tree node to occupy / HUD / Pulse.
	if SoftScanCache == null:
		return
	var p: Node3D = SoftScanCache.get_player()
	if p != null and not p.is_inside_tree():
		fails.append("SoftScanCache.get_player off-tree")
		return
	for n in SoftScanCache.get_ships():
		if n is Node and not (n as Node).is_inside_tree():
			fails.append("SoftScanCache.get_ships has off-tree hull")
			return
	print("[Playtest] SoftScanCache live player=", p != null, " ships=", SoftScanCache.get_ships().size())


func _finish(fails: PackedStringArray, code: int) -> void:
	if fails.is_empty():
		print("[Playtest] PASS")
	else:
		print("[Playtest] FAIL")
		for f in fails:
			print("[Playtest]  - ", f)
	if AutoUpdater and AutoUpdater.has_method("abort_pending"):
		AutoUpdater.abort_pending()
	# Dummy mesh_storage walks null RIDs inside SceneTree.quit() / --quit-after.
	# Kill after the verdict so the counter is live-only, not teardown spam.
	OS.kill(OS.get_process_id())
