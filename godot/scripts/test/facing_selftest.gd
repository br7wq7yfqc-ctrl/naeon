extends SceneTree

func _init() -> void:
	var ok := true
	var SF = load("res://scripts/player/SurfaceFacing.gd")
	if SF == null:
		print("FAIL load SurfaceFacing")
		quit(1)
		return
	var up := Vector3.UP
	var wish_w: Vector3 = SF.compute_wish(Vector2(0, -1), up, 0.0)
	if wish_w.dot(Vector3(0, 0, -1)) < 0.9:
		print("FAIL W@yaw0 want -Z got ", wish_w)
		ok = false
	else:
		print("OK W@yaw0 → ", wish_w)
	var wish_d: Vector3 = SF.compute_wish(Vector2(1, 0), up, 0.0)
	if wish_d.dot(Vector3.RIGHT) < 0.9:
		print("FAIL D@yaw0 want +X got ", wish_d)
		ok = false
	else:
		print("OK D@yaw0 → ", wish_d)
	var wish_w90: Vector3 = SF.compute_wish(Vector2(0, -1), up, PI * 0.5)
	print("INFO W@yaw90 → ", wish_w90)
	if wish_w90.length() < 0.5:
		print("FAIL W@yaw90 zero")
		ok = false
	var b: Basis = SF.basis_from_up(up, 0.0)
	if b.determinant() < 0.5:
		print("FAIL basis det ", b.determinant())
		ok = false
	else:
		print("OK basis det ", b.determinant())
	print("FACING_SELFTEST ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
