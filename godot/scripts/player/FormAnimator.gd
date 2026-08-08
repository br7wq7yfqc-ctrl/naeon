extends RefCounted
class_name FormAnimator
## Full soft locomotion: walk/run/idle/jump/air for Skeleton3D forms.
## Name-heuristic bones — works without AnimationPlayer clips. Visual only.

static func find_skeleton(root: Node) -> Skeleton3D:
	if root == null:
		return null
	if root is Skeleton3D:
		return root as Skeleton3D
	for c in root.get_children():
		var s := find_skeleton(c)
		if s:
			return s
	return null


static func apply_locomotion(skel: Skeleton3D, move_amount: float, anim_time: float, grounded: bool) -> bool:
	if skel == null or not is_instance_valid(skel):
		return false
	var n := skel.get_bone_count()
	if n < 3:
		return false
	var amp := clampf(move_amount, 0.0, 1.8)
	var phase := anim_time * TAU
	var run := clampf((amp - 0.55) / 0.9, 0.0, 1.0)
	var idle_breathe := sin(Time.get_ticks_msec() * 0.0025) * 0.025
	for i in n:
		var bname := skel.get_bone_name(i).to_lower()
		var base: Transform3D = skel.get_bone_rest(i)
		var extra := Transform3D.IDENTITY
		var side := _side(bname)
		if _is_leg(bname):
			var swing := sin(phase + (0.0 if side > 0.0 else PI)) * (0.5 + run * 0.35) * amp
			var knee := maxf(0.0, -sin(phase + (0.0 if side > 0.0 else PI))) * 0.35 * amp
			if not grounded:
				swing *= 0.2
				knee = 0.4
			if "calf" in bname or "shin" in bname or "lower" in bname:
				extra = Transform3D(Basis.from_euler(Vector3(knee, 0, 0)), Vector3.ZERO)
			elif "foot" in bname or "toe" in bname:
				extra = Transform3D(Basis.from_euler(Vector3(-swing * 0.3, 0, 0)), Vector3.ZERO)
			else:
				extra = Transform3D(Basis.from_euler(Vector3(swing, 0, side * 0.05 * amp)), Vector3.ZERO)
		elif _is_arm(bname):
			var swing2 := sin(phase + (PI if side > 0.0 else 0.0)) * (0.4 + run * 0.2) * amp
			if not grounded:
				swing2 = -0.6
			if "hand" in bname or "wrist" in bname:
				extra = Transform3D(Basis.from_euler(Vector3(swing2 * 0.3, 0, 0)), Vector3.ZERO)
			else:
				extra = Transform3D(Basis.from_euler(Vector3(swing2, 0, -side * 0.08)), Vector3.ZERO)
		elif "spine" in bname or "chest" in bname or "torso" in bname or "hip" in bname or "pelvis" in bname or "root" in bname:
			var bob := sin(phase * 2.0) * 0.04 * amp + idle_breathe
			var lean := -0.06 * amp - run * 0.08
			extra = Transform3D(Basis.from_euler(Vector3(lean + bob, 0, sin(phase) * 0.03 * amp)), Vector3(0, bob * 0.03, 0))
		elif "head" in bname or "neck" in bname:
			var look := idle_breathe + sin(phase * 0.5) * 0.02 * amp
			extra = Transform3D(Basis.from_euler(Vector3(look, sin(Time.get_ticks_msec() * 0.001) * 0.03, 0)), Vector3.ZERO)
		elif "wing" in bname or "tail" in bname or "ear" in bname:
			var flap := sin(phase * (2.0 if "wing" in bname else 1.2) + side) * (0.4 + amp * 0.5)
			extra = Transform3D(Basis.from_euler(Vector3(flap * 0.3, 0, flap)), Vector3.ZERO)
		skel.set_bone_pose_rotation(i, (base * extra).basis.get_rotation_quaternion())
	return true


static func apply_idle(skel: Skeleton3D, anim_time: float) -> bool:
	return apply_locomotion(skel, 0.0, anim_time, true)


static func _side(bname: String) -> float:
	if "right" in bname or bname.begins_with("r_") or "_r" in bname or bname.ends_with(".r") or bname.ends_with("_r"):
		return 1.0
	if "left" in bname or bname.begins_with("l_") or "_l" in bname or bname.ends_with(".l") or bname.ends_with("_l"):
		return -1.0
	if " r" in bname:
		return 1.0
	if " l" in bname:
		return -1.0
	return 1.0


static func _is_leg(bname: String) -> bool:
	for k in ["leg", "thigh", "calf", "shin", "foot", "toe", "hip", "upperleg", "lowerleg"]:
		if k in bname:
			return true
	return false


static func _is_arm(bname: String) -> bool:
	for k in ["arm", "hand", "fore", "upper_arm", "lower_arm", "wrist", "finger", "shoulder"]:
		if k in bname:
			return true
	return false
