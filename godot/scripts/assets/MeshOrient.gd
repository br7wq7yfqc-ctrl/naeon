extends RefCounted
class_name MeshOrient
## Align imported GLB so long axis → Z and nose/face → Godot −Z.

static func face_neg_z(root: Node3D, for_ship: bool = true) -> void:
	if root == null:
		return
	root.rotation = Vector3.ZERO
	# Unrotated mesh AABB in root-local (children only)
	var base := _aabb_children(root)
	if base.size.length_squared() < 1e-8:
		return
	var best_y: float = 0.0
	var best_score: float = -1.0e12
	for y in [0.0, PI * 0.5, PI, PI * 1.5]:
		var a := _rotate_aabb_y(base, y)
		var score: float = a.size.z - a.size.x
		if for_ship:
			score += a.size.z * 0.5
		# Prefer mass / center toward −Z (nose ahead of pivot)
		score += -a.get_center().z * 0.5
		if score > best_score:
			best_score = score
			best_y = y
	root.rotation.y = best_y


static func _aabb_in_root(root: Node3D) -> AABB:
	## Public helper: children AABB rotated by root.yaw into root-aligned space.
	var base := _aabb_children(root)
	return _rotate_aabb_y(base, root.rotation.y)


static func _aabb_children(root: Node3D) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array = [[root, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var cur: Node = item[0]
		var xf: Transform3D = item[1]
		if cur is Node3D and cur != root:
			xf = xf * (cur as Node3D).transform
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh:
				var local_a: AABB = mi.mesh.get_aabb()
				for i in 8:
					var corner: Vector3 = xf * local_a.get_endpoint(i)
					if first:
						out = AABB(corner, Vector3.ZERO)
						first = false
					else:
						out = out.expand(corner)
		for c in cur.get_children():
			stack.append([c, xf])
	return out


static func _rotate_aabb_y(a: AABB, yaw: float) -> AABB:
	if a.size.length_squared() < 1e-12:
		return a
	var b := Basis(Vector3.UP, yaw)
	var out := AABB()
	var first := true
	for i in 8:
		var p: Vector3 = b * a.get_endpoint(i)
		if first:
			out = AABB(p, Vector3.ZERO)
			first = false
		else:
			out = out.expand(p)
	return out
