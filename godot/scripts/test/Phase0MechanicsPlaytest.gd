extends Node
## Headless mechanics playtest: interior enter/exit, occupy contest, stall math.
## Enabled with: godot --path godot --scene res://scenes/world/OpenSpace.tscn -- --playtest-mechanics

const _Flight = preload("res://scripts/ship/ShipFlightModel.gd")
const _Hits = preload("res://scripts/combat/CombatHits.gd")


func _ready() -> void:
	var wanted := false
	for a in OS.get_cmdline_user_args():
		if str(a) == "--playtest-mechanics":
			wanted = true
			break
	if not wanted:
		queue_free()
		return
	print("[Playtest] mechanics driver on")
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

	# --- stall math (no scene) ---
	if _Flight.stall_amount(0.0, 4.0, 20.0) > 0.01:
		fails.append("stall in vacuum")
	if _Flight.stall_amount(1.0, 2.0, 20.0) < 0.5:
		fails.append("low-speed dense atmo should stall")
	if _Flight.stall_amount(1.0, 80.0, 20.0) > 0.01:
		fails.append("fast flight should not stall")
	if _Flight.stall_speed(_Flight.Mode.HOVER) > 0.01:
		fails.append("HOVER must not stall")

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
			if pocket:
				var door: Node3D = pocket.get_node_or_null("DoorPortal_0") as Node3D
				if door == null:
					fails.append("no DoorPortal in ship pocket")
				else:
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
		if d.has_method("exit_interior"):
			d.exit_interior()
		await get_tree().create_timer(0.35).timeout
		if d.has_method("is_inside") and bool(d.is_inside()):
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
			var c0: float = float(GameManager.contribution) if GameManager else 0.0
			await get_tree().create_timer(0.7).timeout
			var c1: float = float(GameManager.contribution) if GameManager else 0.0
			print("[Playtest] harvest in-zone ", snapped(c0, 0.01), " -> ", snapped(c1, 0.01), " status=", pad.get_claim_status() if pad.has_method("get_claim_status") else "?")
			if c1 <= c0 + 0.001:
				fails.append("no harvest while owner in ring")
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
					var c4: float = float(GameManager.contribution) if GameManager else 0.0
					await get_tree().create_timer(0.7).timeout
					var c5: float = float(GameManager.contribution) if GameManager else 0.0
					print("[Playtest] harvest landed-ship ", snapped(c4, 0.01), " -> ", snapped(c5, 0.01), " status=", pad.get_claim_status() if pad.has_method("get_claim_status") else "?")
					if c5 <= c4 + 0.001:
						fails.append("no harvest while owning ship is landed")
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

	# --- rover deploy / store on a landed pad ---
	var sh_r: Node = os.get("ship")
	if sh_r == null or pad_deck == null or not bool(sh_r.has_method("_try_deploy_rover")):
		fails.append("no ship/pad for rover deploy")
	else:
		var up_r: Vector3 = pad_deck.get_meta("pad_up") if pad_deck.has_meta("pad_up") else Vector3.UP
		if "velocity" in sh_r:
			sh_r.velocity = Vector3.ZERO
		sh_r.global_position = pad_deck.global_position + up_r * 6.0
		if sh_r.has_method("_set_mode"):
			sh_r._set_mode(2)
		if sh_r.has_method("_do_land"):
			sh_r._do_land()
		if not bool(sh_r.get("is_landed")):
			fails.append("ship not landed for rover deploy")
		else:
			sh_r._try_deploy_rover()
			await get_tree().process_frame
			var rov: Node3D = sh_r.get_deployed_rover() if sh_r.has_method("get_deployed_rover") else null
			print("[Playtest] rover deployed=", rov != null)
			if rov == null or not is_instance_valid(rov):
				fails.append("rover did not deploy on landed pad")
			elif not rov.has_method("board"):
				fails.append("rover script missing board (parse)")
			else:
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

	_osa_same_body(fails)
	_osb_atmosphere_shell(fails)
	_osc_scale_ladder(fails, osc_spawn_agl)
	_finish(fails, 0 if fails.is_empty() else 1)


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
