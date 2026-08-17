extends Node
## Honest sandbox probe: one seed, ring restore, shared park, no FPS PASS.
## godot --path godot --scene res://scenes/world/OpenSpace.tscn -- --sandbox-playtest
## Never prints [Playtest] PASS. llvmpipe does not close rules/25.

const _Relief = preload("res://scripts/world/PlanetRelief.gd")
const _Stars = preload("res://scripts/world/StarSystemCatalog.gd")


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
	lines.append("bodies_spawned=%d" % planets.size())
	if ship == null or planets.is_empty():
		lines.append("FAIL no ship/planets")
		_finish(["no ship/planets"], lines, t0)
		return

	var pl: Node3D = planets[0] as Node3D
	var radius: float = float(pl.get("radius")) if pl.get("radius") != null else 1400.0
	var up: Vector3 = (ship.global_position - pl.global_position).normalized()
	if up.length_squared() < 0.01:
		up = Vector3(0, 0, 1)

	var t_ap := Time.get_ticks_msec()
	ship.global_position = pl.global_position + up * (radius + 80.0)
	if "velocity" in ship:
		ship.velocity = Vector3.ZERO
	if pl.has_method("set_observer"):
		pl.set_observer(ship)
	await get_tree().create_timer(3.2).timeout
	lines.append("approach_wait_ms=%d (includes 3.2s sleep)" % (Time.get_ticks_msec() - t_ap))
	_snap("approach_80m", os, lines)
	_detail(pl, lines, "approach")

	var east: Vector3 = up.cross(Vector3.UP)
	if east.length_squared() < 0.01:
		east = up.cross(Vector3.RIGHT)
	east = east.normalized()
	var t_lat := Time.get_ticks_msec()
	ship.global_position = pl.global_position + (up * (radius + 80.0) + east * 90.0)
	await get_tree().create_timer(2.8).timeout
	lines.append("lateral_wait_ms=%d (includes 2.8s sleep)" % (Time.get_ticks_msec() - t_lat))
	_detail(pl, lines, "lateral")
	_snap("lateral", os, lines)
	var live_lat := _live_of(pl)

	var t_ret := Time.get_ticks_msec()
	ship.global_position = pl.global_position + up * (radius + 400.0)
	await get_tree().create_timer(1.6).timeout
	_detail(pl, lines, "retreat_400m")
	ship.global_position = pl.global_position + up * (radius + 75.0)
	if pl.has_method("set_observer"):
		pl.set_observer(ship)
	await get_tree().create_timer(2.4).timeout
	lines.append("reapproach_wait_ms=%d (includes sleeps)" % (Time.get_ticks_msec() - t_ret))
	_detail(pl, lines, "reapproach")
	_snap("reapproach", os, lines)
	var live_re := _live_of(pl)
	var cache_re := _cache_of(pl)
	var ring_ok := live_re >= maxi(live_lat, 3) and cache_re >= live_re
	lines.append("RING_RESTORE=%s live_lat=%d live_re=%d cache=%d" % [
		str(ring_ok), live_lat, live_re, cache_re
	])

	if pl.has_method("ensure_pad_bases"):
		pl.ensure_pad_bases()
		await get_tree().create_timer(0.6).timeout
	var pads: Array = get_tree().get_nodes_in_group("pad_bases")
	lines.append("pads=%d" % pads.size())

	lines.append("input_M=toast G2 locked (not a map)")
	lines.append("input_TAB=Clash sandbox (not a galaxy map)")
	lines.append("gates=authored_not_spawned")
	lines.append("galaxy_G2_G6=404_in_repo")
	lines.append("FPS=not_scored_llvmpipe")

	var unfit: PackedStringArray = PackedStringArray()
	if not _seed_one(os):
		unfit.append("two seeds still disagree")
	if not ring_ok:
		unfit.append("ring did not restore after retreat")
	if _fill_live(pl):
		unfit.append("fill streamers still processing")
	if planets.size() != 1:
		unfit.append("P0 slice still spawned extra bodies")
	unfit.append("no 5min human soak on owner GPU")
	unfit.append("rules/25 FPS not scored on llvmpipe")
	lines.append("P0_1_RUNTIME=%s" % str(unfit.size() <= 2))
	lines.append("VERDICT=HUMAN_UNFIT")
	lines.append("REASON=" + "; ".join(unfit))

	_write(lines)
	_finish([], lines, t0)


func _seeds(os: Node, lines: PackedStringArray) -> void:
	for id in _Stars.body_ids():
		var s: int = _Relief.body_seed(str(id))
		lines.append("seed_formula %s body_seed=%d" % [id, s])
	var planets: Array = os.get("planets") if os.get("planets") != null else []
	for p in planets:
		if p == null or not (p is Node3D):
			continue
		var n: String = str(p.get("planet_name")) if p.get("planet_name") != null else p.name
		var body_s := -1
		var sh_s := -1
		if p.has_method("body_seed"):
			body_s = int(p.body_seed())
		if p.has_method("shader_seed"):
			sh_s = int(p.shader_seed())
		var sd: Node = (p as Node).get_node_or_null("SurfaceDetail")
		var det_s := -1
		if sd != null and sd.has_method("body_seed"):
			det_s = int(sd.body_seed())
		var same := body_s == sh_s and body_s == det_s and body_s >= 0
		lines.append("seed %s body=%d shader=%d detail=%d SAME=%s" % [
			n, body_s, sh_s, det_s, str(same)
		])
		for nm in ["SurfaceFlora", "SurfaceFauna", "SurfaceWater", "CaveMouthField", "LandscapeFeatures", "CaveInterior", "TerrainEdit"]:
			if (p as Node).get_node_or_null(nm):
				lines.append("fill_present %s %s" % [n, nm])


func _seed_one(os: Node) -> bool:
	var planets: Array = os.get("planets") if os.get("planets") != null else []
	for p in planets:
		if p == null or not p.has_method("body_seed") or not p.has_method("shader_seed"):
			return false
		if int(p.body_seed()) != int(p.shader_seed()):
			return false
		var sd: Node = p.get_node_or_null("SurfaceDetail")
		if sd == null or not sd.has_method("body_seed"):
			return false
		if int(sd.body_seed()) != int(p.body_seed()):
			return false
	return not planets.is_empty()


func _fill_live(pl: Node) -> bool:
	for nm in ["SurfaceFlora", "SurfaceFauna", "SurfaceWater", "CaveMouthField", "LandscapeFeatures", "CaveInterior", "TerrainEdit"]:
		var n: Node = pl.get_node_or_null(nm)
		if n != null and n.is_processing():
			return true
	return false


func _live_of(pl: Node) -> int:
	var sd: Node = pl.get_node_or_null("SurfaceDetail")
	if sd and sd.has_method("live_count"):
		return int(sd.live_count())
	return -1


func _cache_of(pl: Node) -> int:
	var sd: Node = pl.get_node_or_null("SurfaceDetail")
	if sd and sd.has_method("cache_count"):
		return int(sd.cache_count())
	return -1


func _detail(pl: Node, lines: PackedStringArray, tag: String) -> void:
	var sd: Node = pl.get_node_or_null("SurfaceDetail")
	var live := -1
	var q := -1
	var cache := -1
	var parked := false
	if sd and sd.has_method("live_count"):
		live = int(sd.live_count())
	if sd and sd.has_method("queue_depth"):
		q = int(sd.queue_depth())
	if sd and sd.has_method("cache_count"):
		cache = int(sd.cache_count())
	if sd and sd.has_method("is_parked"):
		parked = bool(sd.is_parked())
	var alt := -1.0
	var ship: Node3D = get_parent().get("ship") as Node3D if get_parent() else null
	if ship and pl is Node3D and pl.has_method("altitude_of"):
		alt = float(pl.altitude_of(ship.global_position))
	lines.append("detail[%s] live=%d queue=%d cache=%d parked=%s alt=%.1f" % [
		tag, live, q, cache, str(parked), alt
	])
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
