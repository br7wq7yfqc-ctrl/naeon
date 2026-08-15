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
		if d.has_method("try_use_console"):
			d.try_use_console()
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

	_finish(fails, 0 if fails.is_empty() else 1)


func _finish(fails: PackedStringArray, code: int) -> void:
	if fails.is_empty():
		print("[Playtest] PASS")
	else:
		print("[Playtest] FAIL")
		for f in fails:
			print("[Playtest]  - ", f)
	get_tree().quit(code)
