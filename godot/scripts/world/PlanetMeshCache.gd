extends RefCounted
class_name PlanetMeshCache
## Shared SphereMesh instances by (radius_key, segments) to avoid rebuild cost.

static var _spheres: Dictionary = {}  # String -> Mesh

static func sphere(radius: float, segments: int) -> Mesh:
	## Dummy mesh_storage cannot RID a SphereMesh (Parameter m is null).
	## Do not even construct one on headless — creating it is enough.
	if DisplayServer.get_name() == "headless":
		var bkey := "box_%d" % int(radius * 10.0)
		if _spheres.has(bkey):
			return _spheres[bkey]
		var b := BoxMesh.new()
		b.size = Vector3.ONE * 2.0
		_spheres[bkey] = b
		return b
	var key := "%d_%d" % [int(radius * 10.0), segments]
	if _spheres.has(key):
		return _spheres[key]
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = max(8, segments)
	sm.rings = max(4, int(segments / 2))
	_spheres[key] = sm
	return sm

static func clear() -> void:
	_spheres.clear()
