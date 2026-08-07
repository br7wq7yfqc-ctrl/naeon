extends RefCounted
class_name FormAnimator
## Sprint C: if FormGLB has Skeleton3D, drive simple walk/idle bone poses.
## Else returns false so caller keeps procedural limb/bob path.
## No combat power — visual locomotion only.

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
	# Soft procedural bone sway by name heuristics (works without AnimationPlayer clips)
	var amp := clampf(move_amount, 0.0, 1.5)
	var phase := anim_time * TAU
	for i in n:
		var bname := skel.get_bone_name(i).to_lower()
		var base: Transform3D = skel.get_bone_rest(i)
		var extra := Transform3D.IDENTITY
		if "leg" in bname or "thigh" in bname or "calf" in bname or "shin" in bname or "foot" in bname:
			var side := 1.0 if ("r" in bname or "right" in bname) else -1.0
			if "l" in bname or "left" in bname:
				side = -1.0
			if "r" in bname or "right" in bname:
				side = 1.0
			var swing := sin(phase + (0.0 if side > 0.0 else PI)) * 0.45 * amp
			if not grounded:
				swing *= 0.25
			extra = Transform3D(Basis.from_euler(Vector3(swing, 0, 0)), Vector3.ZERO)
		elif "arm" in bname or "hand" in bname or "fore" in bname or "upper_arm" in bname:
			var side2 := 1.0 if ("r" in bname or "right" in bname) else -1.0
			if "l" in bname or "left" in bname:
				side2 = -1.0
			var swing2 := sin(phase + (PI if side2 > 0.0 else 0.0)) * 0.35 * amp
			extra = Transform3D(Basis.from_euler(Vector3(swing2, 0, 0)), Vector3.ZERO)
		elif "spine" in bname or "chest" in bname or "torso" in bname or "hip" in bname or "pelvis" in bname:
			var bob := sin(phase * 2.0) * 0.03 * amp
			extra = Transform3D(Basis.from_euler(Vector3(bob, 0, 0)), Vector3(0, bob * 0.02, 0))
		elif "head" in bname or "neck" in bname:
			var breathe := sin(Time.get_ticks_msec() * 0.003) * 0.02
			extra = Transform3D(Basis.from_euler(Vector3(breathe, 0, 0)), Vector3.ZERO)
		skel.set_bone_pose_rotation(i, (base * extra).basis.get_rotation_quaternion())
	return true
