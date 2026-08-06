extends RefCounted
class_name PlanetMeshCache
## Shared SphereMesh instances by (radius_key, segments) to avoid rebuild cost.

static var _spheres: Dictionary = {}  # String -> SphereMesh

static func sphere(radius: float, segments: int) -> SphereMesh:
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
