extends Node
## Mac GPU 10-min OpenSpace soak for the FPS half of rules/25.
## SESSION_CONTRACT §17. GUI Godot only — headless TIME_FPS is dummy.
## godot --path godot --scene res://scenes/world/OpenSpace.tscn -- --playtest-soak
## Never prints [Playtest] PASS. Honest TIME_FPS / MEMORY_STATIC / OBJECT_NODE_COUNT.
## Mac GUI Godot often does not attach stdout — also append logs/soak_mac_gpu.log.

const DURATION_SEC := 600.0
const SAMPLE_SEC := 15.0
const BOOT_SEC := 2.4


func _ready() -> void:
	var wanted := false
	for a in OS.get_cmdline_user_args():
		if str(a) == "--playtest-soak":
			wanted = true
			break
	if not wanted:
		queue_free()
		return
	_log("[Soak] OpenSpace GPU driver on")
	call_deferred("_go")


func _go() -> void:
	var display := str(DisplayServer.get_name())
	var adapter := str(RenderingServer.get_video_adapter_name())
	var ad_l := adapter.to_lower()
	_log("[Soak] display=%s adapter=%s" % [display, adapter])
	if display == "headless":
		_log("[Soak] FAIL headless dummy renderer (not Mac GPU)")
		_quit(2)
		return
	if adapter == "" or "llvmpipe" in ad_l or "softpipe" in ad_l or "swiftshader" in ad_l:
		_log("[Soak] FAIL software adapter (%s)" % adapter)
		_quit(2)
		return
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and gq.has_method("apply_tier"):
		gq.apply_tier(0)
	var tier_name := "LOW"
	if gq and gq.has_method("tier_name"):
		tier_name = str(gq.tier_name())
	_log("[Soak] min preset tier=%s duration=%ds sample=%ds" % [tier_name, int(DURATION_SEC), int(SAMPLE_SEC)])
	await get_tree().create_timer(BOOT_SEC).timeout
	var t0 := Time.get_ticks_msec()
	var fps_min := 9999.0
	var fps_max := 0.0
	var fps_sum := 0.0
	var n := 0
	var ram0 := -1.0
	var ram_prev := -1.0
	var climb_steps := 0
	var nodes0 := -1
	var last_fps := 0.0
	var last_ram := 0.0
	var last_nodes := 0
	var last_objs := 0
	while true:
		var elapsed := float(Time.get_ticks_msec() - t0) / 1000.0
		var fps := float(Performance.get_monitor(Performance.TIME_FPS))
		var ram := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
		var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var objs := int(Performance.get_monitor(Performance.OBJECT_COUNT))
		last_fps = fps
		last_ram = ram
		last_nodes = nodes
		last_objs = objs
		if ram0 < 0.0:
			ram0 = ram
			nodes0 = nodes
		if fps < fps_min:
			fps_min = fps
		if fps > fps_max:
			fps_max = fps
		fps_sum += fps
		n += 1
		if ram_prev >= 0.0 and ram > ram_prev + 0.5:
			climb_steps += 1
		ram_prev = ram
		_log("[Soak] t=%.0fs fps=%.1f ram_mb=%.1f nodes=%d objects=%d" % [
			elapsed, fps, ram, nodes, objs
		])
		if elapsed + 0.05 >= DURATION_SEC:
			break
		await get_tree().create_timer(SAMPLE_SEC).timeout
	var fps_avg := (fps_sum / float(n)) if n > 0 else 0.0
	var ram_delta := last_ram - ram0
	_log("[Soak] DONE adapter=%s display=%s tier=%s samples=%d fps_min=%.1f fps_avg=%.1f fps_max=%.1f ram0=%.1f ramN=%.1f ram_delta=%.1f climb_steps=%d nodes0=%d nodesN=%d objectsN=%d" % [
		adapter, display, tier_name, n, fps_min, fps_avg, fps_max, ram0, last_ram, ram_delta, climb_steps, nodes0, last_nodes, last_objs
	])
	_log("[Soak] honest TIME_FPS (not clamped). rules/25 target ~60 sustained on min preset; memory must not climb monotonically.")
	_quit(0)


func _log(line: String) -> void:
	print(line)
	var godot_root := ProjectSettings.globalize_path("res://").rstrip("/")
	var path := godot_root.get_base_dir().path_join("logs/soak_mac_gpu.log")
	DirAccess.make_dir_recursive_absolute(godot_root.get_base_dir().path_join("logs"))
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(line)
		f.flush()
		f.close()


func _quit(code: int) -> void:
	var tree := get_tree()
	if tree:
		tree.quit(code)
	else:
		OS.kill(OS.get_process_id())
