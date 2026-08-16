extends Node
## Honest sandbox probe: terrain live-rebuild, two seeds, memory, hitches.
## godot --path godot --scene res://scenes/world/OpenSpace.tscn -- --sandbox-playtest
## Never prints [Playtest] PASS. Human-unfit is the expected verdict on this slice.


func _ready() -> void:
	var wanted := false
	for a in OS.get_cmdline_user_args():
		if str(a) == "--sandbox-playtest":
			wanted = true
			break
	if not wanted:
		queue_free()
		return
	print("[Sandbox] probe on")
	call_deferred("_go")


func _go() -> void:
	var lines: PackedStringArray = PackedStringArray()
	var t0 := Time.get_ticks_msec()
	await get_tree().create_timer(1.8).timeout
	var os: Node = get_parent()
	if os == null:
		_finish(["no OpenSpace parent"], lines, t0)
		return

	_snap("boot", os, lines)
	_seeds(os, lines)

	var ship: Node3D = os.get("ship") as Node3D
	var planets: Array = os.get("planets") if os.get("planets") != null else []
	if ship == null or planets.is_empty():
		lines.append("FAIL no ship/planets")
		_finish(["no ship/planets"], lines, t0)
		return

	var pl: Node3D = planets[0] as Node3D
	var radius: float = float(pl.get("radius")) if pl.get("radius") != null else 1400.0
	var up: Vector3 = (ship.global_position - pl.global_position).normalized()
	if up.length_squared() < 0.01:
		up = Vector3(0, 0, 1)

	# Approach: inside SurfaceDetail activate band (<140 m AGL).
	var t_ap := Time.get_ticks_msec()
	ship.global_position = pl.global_position + up * (radius + 80.0)
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	if pl.has_method("set_observer"):
		pl.set_observer(ship)
	await get_tree().create_timer(3.2).timeout
	var hitch_ap := Time.get_ticks_msec() - t_ap
	lines.append("approach_wait_ms=%d (includes 3.2s sleep)" % hitch_ap)
	_snap("approach_80m", os, lines)
	_detail(pl, lines, "approach")

	# Lateral step → new cell → more live builds.
	var east: Vector3 = up.cross(Vector3.UP)
	if east.length_squared() < 0.01:
		east = up.cross(Vector3.RIGHT)
	east = east.normalized()
	var t_lat := Time.get_ticks_msec()
	ship.global_position = pl.global_position + (up * (radius + 80.0) + east * 90.0)
	await get_tree().create_timer(2.4).timeout
	lines.append("lateral_wait_ms=%d (includes 2.4s sleep)" % (Time.get_ticks_msec() - t_lat))
	_detail(pl, lines, "lateral")
	_snap("lateral", os, lines)

	# Retreat past park band, then re-enter — must not be a cache-only path today.
	var t_ret := Time.get_ticks_msec()
	ship.global_position = pl.global_position + up * (radius + 400.0)
	await get_tree().create_timer(1.6).timeout
	_detail(pl, lines, "retreat_400m")
	ship.global_position = pl.global_position + up * (radius + 75.0)
	await get_tree().create_timer(3.0).timeout
	lines.append("reapproach_wait_ms=%d (includes sleeps)" % (Time.get_ticks_msec() - t_ret))
	_detail(pl, lines, "reapproach")
	_snap("reapproach", os, lines)

	if pl.has_method("ensure_pad_bases"):
		pl.ensure_pad_bases()
		await get_tree().create_timer(0.6).timeout
	var pads: Array = get_tree().get_nodes_in_group("pad_bases")
	lines.append("pads=%d" % pads.size())

	lines.append("input_M_TAB=change_scene TestArena (inert galaxy map)")
	lines.append("gates=authored_not_spawned")
	lines.append("galaxy_G2_G6=404_in_repo")
	lines.append("VERDICT=HUMAN_UNFIT")
	lines.append("REASON=live terrain rebuild + two samplers + no 5min human soak on GPU")

	_write(lines)
	_finish([], lines, t0)


func _seeds(os: Node, lines: PackedStringArray) -> void:
	var planets: Array = os.get("planets") if os.get("planets") != null else []
	for p in planets:
		if p == null or not (p is Node3D):
			continue
		var n: String = str(p.get("planet_name")) if p.get("planet_name") != null else p.name
		var h: int = n.hash()
		var shader_seed: int = int(absi(h) % 97)
		var relief_seed: int = int(absi(h) % 10000)
		lines.append("seed %s shader=%%97=%d relief=%%10000=%d SAME=%s" % [
			n, shader_seed, relief_seed, str(shader_seed == relief_seed)
		])
		var fl: Node = (p as Node).get_node_or_null("SurfaceFlora")
		if fl:
			lines.append("flora_on %s (setup uses hash(node.name) in PlanetBody)" % n)


func _detail(pl: Node, lines: PackedStringArray, tag: String) -> void:
	var sd: Node = pl.get_node_or_null("SurfaceDetail")
	var live := -1
	var q := -1
	if sd and sd.has_method("live_count"):
		live = int(sd.live_count())
	if sd and sd.has_method("queue_depth"):
		q = int(sd.queue_depth())
	var alt := -1.0
	var ship: Node3D = get_parent().get("ship") as Node3D if get_parent() else null
	if ship and pl is Node3D and pl.has_method("altitude_of"):
		alt = float(pl.altitude_of(ship.global_position))
	lines.append("detail[%s] live=%d queue=%d alt=%.1f" % [tag, live, q, alt])
	for nm in ["SurfaceFlora", "SurfaceFauna", "SurfaceWater", "CaveMouthField", "LandscapeFeatures", "CaveInterior", "TerrainEdit"]:
		var n: Node = pl.get_node_or_null(nm)
		if n:
			lines.append("stream[%s] %s proc=%s vis=%s" % [tag, nm, str(n.is_processing()), str(n.visible)])


func _snap(tag: String, _os: Node, lines: PackedStringArray) -> void:
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var objs := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var ram := int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	lines.append("snap[%s] nodes=%d objs=%d ram_mb=%d" % [tag, nodes, objs, ram])


func _write(lines: PackedStringArray) -> void:
	var path := "user://sandbox_playtest.txt"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines) + "\n")
		f.close()
		print("[Sandbox] wrote ", path)


func _finish(_fails: PackedStringArray, lines: PackedStringArray, t0: int) -> void:
	print("[Sandbox] elapsed_ms=", Time.get_ticks_msec() - t0)
	for ln in lines:
		print("[Sandbox] ", ln)
	print("[Sandbox] HUMAN_UNFIT")
	if AutoUpdater and AutoUpdater.has_method("abort_pending"):
		AutoUpdater.abort_pending()
	var tree := get_tree()
	if tree:
		tree.quit(2)
	OS.kill(OS.get_process_id())
