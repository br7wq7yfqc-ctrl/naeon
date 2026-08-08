extends SceneTree
## godot --headless --script res://../scripts/facing_selftest.gd
## Run from godot/ via: godot --headless --path godot -s res://../scripts/facing_selftest.gd

func _init() -> void:
	var ok := true
	var SW = load("res://scripts/player/SurfaceWalker.gd")
	if SW == null:
		print("FAIL load walker")
		quit(1)
		return
	# Flat ground up
	var up := Vector3.UP
	var wish_w: Vector3 = SW.compute_wish(Vector2(0, -1), up, 0.0)
	# yaw 0, forward should be ~ −Z
	if wish_w.dot(Vector3(0, 0, -1)) < 0.9:
		print("FAIL W@yaw0 want -Z got ", wish_w)
		ok = false
	else:
		print("OK W@yaw0 → ", wish_w)
	var wish_d: Vector3 = SW.compute_wish(Vector2(1, 0), up, 0.0)
	if wish_d.dot(Vector3.RIGHT) < 0.9:
		print("FAIL D@yaw0 want +X got ", wish_d)
		ok = false
	else:
		print("OK D@yaw0 → ", wish_d)
	# yaw 90° (PI/2): W should go roughly −X or +X depending convention
	var wish_w90: Vector3 = SW.compute_wish(Vector2(0, -1), up, PI * 0.5)
	print("INFO W@yaw90 → ", wish_w90, " len=", wish_w90.length())
	if wish_w90.length() < 0.5:
		print("FAIL W@yaw90 zero")
		ok = false
	# det of basis via walker instance not needed
	print("FACING_SELFTEST ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
