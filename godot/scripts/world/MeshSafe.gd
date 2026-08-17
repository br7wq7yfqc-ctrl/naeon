extends RefCounted
class_name MeshSafe
## Godot 4.3 dummy mesh_storage:
## - Sphere/Torus/Prism/fat Cylinder/ArrayMesh often have a null RID.
## - SceneTree.quit() / --quit-after walks those RIDs → Parameter m is null.
## - Live MeshInstance add/free (pad plate, interior pocket, chunk park)
##   hits the same mesh_get_surface_count path. Skip visuals on dummy;
##   keep collision / groups / cache counts.
## - Label3D glyph rebuild and material_override tint do the same while live.
## BoxMesh stand-in on GPU-less runs. Never a reason to put GLB in git.
## Do not SceneTree.quit() on headless — OS.kill after the probe prints.

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
