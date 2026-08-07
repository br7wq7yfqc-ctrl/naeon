extends RefCounted
class_name MeshOrient
## Align imported GLB so the long axis is Z and the nose/face points Godot −Z.

static func face_neg_z(root: Node3D, for_ship: bool = true) -> void:
	if root == null:
		return
	root.rotation = Vector3.ZERO
	var best_y := 0.0
	var best_score := -1.0e12
	for y in [0.0, PI * 0.5, PI, PI * 1.5]:
		root.rotation.y = y
		var a := _aabb_in_root(root)
		if a.size.length_squared() < 1e-8:
			continue
		# Prefer length along Z (flight / walk forward axis)
		var score := a.size.z - a.size.x
		if for_ship:
			score += a.size.z * 0.5
		# Prefer geometric center slightly toward −Z (nose ahead of pivot)
		score += -a.get_center().z * 0.35
		if score > best_score:
			best_score = score
			best_y = y
	root.rotation.y = best_y
	# Final safety: if still wider than long, force ±90°
	var a2 := _aabb_in_root(root)
	if a2.size.x > a2.size.z * 1.12:
		root.rotation.y = best_y + PI * 0.5
		var a3 := _aabb_in_root(root)
		if a3.size.x > a3.size.z:
			root.rotation.y = best_y - PI * 0.5


static func _aabb_in_root(root: Node3D) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array = [[root, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var item = stack.pop_back()
		var cur: Node = item[0]
		var xf: Transform3D = item[1]
		if cur is Node3D and cur != root:
			xf = xf * (cur as Node3D).transform
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh:
				var local_a: AABB = mi.mesh.get_aabb()
				# transform 8 corners into root space
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
