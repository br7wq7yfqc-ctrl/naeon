extends RefCounted
class_name MeshOrient
## Align imported GLB so front matches Godot −Z (walk / thrust).

static func face_neg_z(root: Node3D, prefer_long_axis_as_length: bool = true) -> void:
	if root == null:
		return
	root.rotation = Vector3.ZERO
	var aabb := _combined_aabb(root)
	var sx := absf(aabb.size.x)
	var sz := absf(aabb.size.z)
	if prefer_long_axis_as_length and sx > sz * 1.15:
		# Long on X → authored as +X forward → yaw −90° so length on Z, nose −Z after flip
		root.rotation.y = -PI * 0.5
	else:
		# Typical Tripo faces +Z toward camera; we need −Z nose/face for COW third-person
		root.rotation.y = PI


static func _combined_aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array = [n]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh:
				var a: AABB = mi.get_aabb()
				if first:
					out = a
					first = false
				else:
					out = out.merge(a)
		for c in cur.get_children():
			stack.append(c)
	return out
