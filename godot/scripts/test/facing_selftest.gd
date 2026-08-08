extends SceneTree

func _init() -> void:
	var ok := true
	var SW = load("res://scripts/player/SurfaceWalker.gd")
	if SW == null:
		print("FAIL load walker")
		quit(1)
		return
	var up := Vector3.UP
	var wish_w: Vector3 = SW.compute_wish(Vector2(0, -1), up, 0.0)
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
	var wish_w90: Vector3 = SW.compute_wish(Vector2(0, -1), up, PI * 0.5)
	print("INFO W@yaw90 → ", wish_w90)
	if wish_w90.length() < 0.5:
		print("FAIL W@yaw90 zero")
		ok = false
	print("FACING_SELFTEST ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
