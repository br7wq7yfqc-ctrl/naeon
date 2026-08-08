extends RefCounted
class_name SurfaceFacing
## Pure facing math (no autoloads) for selftest + runtime parity.

static func compute_wish(input: Vector2, up: Vector3, yaw: float) -> Vector3:
	var u := up.normalized()
	var f0 := Vector3(0, 0, -1)
	if absf(u.dot(f0)) > 0.95:
		f0 = Vector3(1, 0, 0)
	f0 = (f0 - u * f0.dot(u)).normalized()
	var right0 := f0.cross(u).normalized()
	var forward0 := u.cross(right0).normalized()
	var b0 := Basis(right0, u, -forward0)
	var b := Basis(u, yaw) * b0
	var forward := (-b.z)
	forward = (forward - u * forward.dot(u))
	if forward.length_squared() < 1e-8:
		return Vector3.ZERO
	forward = forward.normalized()
	var right := forward.cross(u).normalized()
	if input.length_squared() < 1e-8:
		return Vector3.ZERO
	return (right * input.x + forward * (-input.y)).normalized()


static func basis_from_up(up: Vector3, yaw: float) -> Basis:
	var u := up.normalized()
	var f0 := Vector3(0, 0, -1)
	if absf(u.dot(f0)) > 0.95:
		f0 = Vector3(1, 0, 0)
	f0 = (f0 - u * f0.dot(u)).normalized()
	var right0 := f0.cross(u).normalized()
	var forward0 := u.cross(right0).normalized()
	var b0 := Basis(right0, u, -forward0)
	return (Basis(u, yaw) * b0).orthonormalized()
