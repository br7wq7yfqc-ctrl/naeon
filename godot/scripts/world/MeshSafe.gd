extends RefCounted
class_name MeshSafe
## Dummy / headless mesh_storage cannot RID some PrimitiveMeshes
## (Sphere/Torus/Prism/fat Cylinder). BoxMesh is the safe stand-in.
## Real GPU keeps the authored mesh. Never a reason to put GLB in git.

static func dummy() -> bool:
	return DisplayServer.get_name() == "headless"


static func box(size: Vector3 = Vector3.ONE) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func visual(mesh: Mesh, fallback_size: Vector3 = Vector3.ONE) -> Mesh:
	if dummy():
		return box(fallback_size)
	return mesh


static func assign(mi: MeshInstance3D, mesh: Mesh, fallback_size: Vector3 = Vector3.ONE) -> void:
	if mi == null:
		return
	mi.mesh = visual(mesh, fallback_size)
