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
	return basis_from_up_ref(up, yaw, Vector3(0, 0, -1))


static func basis_from_up_ref(up: Vector3, yaw: float, ref_fwd: Vector3) -> Basis:
	## `ref_fwd` is a tangent reference the caller carries between frames. Deriving
	## it from a fixed world axis snapped the frame 90 degrees when `up` crossed
	## the band where the seed axis had to change.
	var u := up.normalized()
	var f0 := ref_fwd
	if f0.length_squared() < 1e-8 or absf(u.dot(f0.normalized())) > 0.999:
		f0 = Vector3(0, 0, -1)
		if absf(u.dot(f0)) > 0.95:
			f0 = Vector3(1, 0, 0)
	f0 = (f0 - u * f0.dot(u))
	if f0.length_squared() < 1e-8:
		f0 = Vector3(1, 0, 0)
		f0 = (f0 - u * f0.dot(u))
	f0 = f0.normalized()
	var right0 := f0.cross(u).normalized()
	var forward0 := u.cross(right0).normalized()
	var b0 := Basis(right0, u, -forward0)
	return (Basis(u, yaw) * b0).orthonormalized()


static func transport_ref(up: Vector3, ref_fwd: Vector3) -> Vector3:
	## Re-project the reference onto the new tangent plane (parallel transport).
	var u := up.normalized()
	var f := ref_fwd - u * ref_fwd.dot(u)
	if f.length_squared() < 1e-8:
		f = Vector3(0, 0, -1)
		if absf(u.dot(f)) > 0.95:
			f = Vector3(1, 0, 0)
		f = f - u * f.dot(u)
	if f.length_squared() < 1e-8:
		return Vector3(0, 0, -1)
	return f.normalized()


static func tangent_nose(up: Vector3, nose: Vector3) -> Vector3:
	## Hull/camera forward on a pad: project world nose onto the plate.
	## World-XZ yaw (atan2) is the wrong frame once pad_up ≠ +Y.
	return transport_ref(up, nose)
