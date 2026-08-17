extends Node
## Headless AR-A check: OTS camera + 3 live lanes on TestArena.
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
	print("[Playtest] arena AR-A driver on")
	call_deferred("_go")


func _go() -> void:
	await get_tree().create_timer(0.7).timeout
	var fails: PackedStringArray = PackedStringArray()
	var arena: Node = get_parent()
	if arena == null or str(arena.name) != "TestArena":
		_finish(["no TestArena parent"], 1)
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

	_finish(fails, 0 if fails.is_empty() else 1)


func _finish(fails: PackedStringArray, code: int) -> void:
	if fails.is_empty():
		print("[Playtest] PASS arena AR-A")
	else:
		print("[Playtest] FAIL arena AR-A")
		for f in fails:
			print("[Playtest]  - ", f)
	if AutoUpdater and AutoUpdater.has_method("abort_pending"):
		AutoUpdater.abort_pending()
	var tree := get_tree()
	if tree:
		tree.quit(code)
	OS.kill(OS.get_process_id())
