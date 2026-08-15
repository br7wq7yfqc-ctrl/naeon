extends Node
## Headless mechanics playtest: interior enter/exit, occupy contest, stall math.
## Enabled with: godot --path godot --scene res://scenes/world/OpenSpace.tscn -- --playtest-mechanics

const _Flight = preload("res://scripts/ship/ShipFlightModel.gd")


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
			var before := 0.0
			if pad.has_method("get_occupy_strength"):
				before = float(pad.get_occupy_strength())
			if walker2 and is_instance_valid(walker2) and pad is Node3D:
				walker2.global_position = (pad as Node3D).global_position + Vector3(0, 4.0, 0)
				await get_tree().create_timer(1.15).timeout
				var after := before
				if pad.has_method("get_occupy_strength"):
					after = float(pad.get_occupy_strength())
				print("[Playtest] occupy presence meter ", snapped(before, 0.01), " -> ", snapped(after, 0.01))
				if is_equal_approx(after, before):
					fails.append("occupy presence did not move the contest meter")
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
			if pad.has_method("claim"):
				pad.claim("Cybernex", 2.0)
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

	_finish(fails, 0 if fails.is_empty() else 1)


func _finish(fails: PackedStringArray, code: int) -> void:
	if fails.is_empty():
		print("[Playtest] PASS")
	else:
		print("[Playtest] FAIL")
		for f in fails:
			print("[Playtest]  - ", f)
	if AutoUpdater and AutoUpdater.has_method("abort_pending"):
		AutoUpdater.abort_pending()
	var tree := get_tree()
	if tree:
		tree.quit(code)
	# Godot 4.3 dummy renderer keeps iterating after quit() (mesh_get_surface_count).
	OS.kill(OS.get_process_id())
