extends RefCounted
class_name SurfaceChunkMath
## Shared planet-surface cell math for streaming (stable, no swim).

static func cell_of(planet_pos: Vector3, radius: float, global_pos: Vector3, cell_m: float) -> Vector2i:
	var local: Vector3 = (global_pos - planet_pos).normalized()
	var lat := asin(clampf(local.y, -1.0, 1.0))
	var lon := atan2(local.x, local.z)
	var cell_ang := cell_m / maxf(radius, 1.0)
	return Vector2i(int(floor(lon / cell_ang)), int(floor(lat / cell_ang)))


static func cell_center_dir(cell: Vector2i, radius: float, cell_m: float) -> Vector3:
	var cell_ang := cell_m / maxf(radius, 1.0)
	var lon := (float(cell.x) + 0.5) * cell_ang
	var lat := (float(cell.y) + 0.5) * cell_ang
	var clat := cos(lat)
	return Vector3(sin(lon) * clat, sin(lat), cos(lon) * clat).normalized()


static func stable_tangent(up: Vector3) -> Array:
	up = up.normalized()
	var ref := Vector3.UP
	if absf(up.dot(ref)) > 0.92:
		ref = Vector3.RIGHT
	var east := ref.cross(up).normalized()
	var north := up.cross(east).normalized()
	return [east, north]


static func vertex_dir(radius: float, cell: Vector2i, cell_m: float, px: float, pz: float) -> Vector3:
	## Direction of a patch vertex before height is applied. Matches
	## cell_transform basis (east, radial, -north) so Relief and the mesh agree.
	var dir: Vector3 = cell_center_dir(cell, radius, cell_m)
	var t: Array = stable_tangent(dir)
	var east: Vector3 = t[0]
	var north: Vector3 = t[1]
	var raw: Vector3 = dir * maxf(radius, 1.0) + east * px - north * pz
	if raw.length_squared() < 1e-8:
		return dir
	return raw.normalized()


static func cell_transform(planet_pos: Vector3, radius: float, cell: Vector2i, cell_m: float, lift: float = 0.35) -> Transform3D:
	var dir := cell_center_dir(cell, radius, cell_m)
	var t := stable_tangent(dir)
	var east: Vector3 = t[0]
	var north: Vector3 = t[1]
	var pos: Vector3 = planet_pos + dir * (radius + lift)
	return Transform3D(Basis(east, dir, -north), pos)


static func ring_cells(center: Vector2i, ring: int) -> Array[Vector2i]:
	## Chebyshev ring: all cells with max(|dx|,|dy|) <= ring
	var out: Array[Vector2i] = []
	for dy in range(-ring, ring + 1):
		for dx in range(-ring, ring + 1):
			out.append(Vector2i(center.x + dx, center.y + dy))
	return out


static func chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))
