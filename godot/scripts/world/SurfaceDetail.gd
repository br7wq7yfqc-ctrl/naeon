extends Node3D
class_name SurfaceDetail
## Procedural height patches snapped to a FIXED planet surface grid.
## Never orbits the player (that caused "dancing/swimming" terrain).

const PATCH_COUNT := 9
const PATCH_RES := 10
const PATCH_SIZE := 40.0
## Cell size on sphere (meters along surface) — only stream when crossing cell
const CELL_M := 36.0

var _planet: Node3D
var _radius: float = 1200.0
var _surface_color: Color = Color(0.12, 0.2, 0.16)
var _patches: Array[MeshInstance3D] = []
var _observer: Node3D
var _built: bool = false
var _accum: float = 0.0
var _seed: int = 1
var _last_cell: Vector2i = Vector2i(999999, 999999)
var _active: bool = false

func setup(planet: Node3D, radius: float, color: Color, seed_i: int = 1) -> void:
	_planet = planet
	_radius = radius
	_surface_color = color
	_seed = seed_i


func set_observer(n: Node3D) -> void:
	_observer = n
	_last_cell = Vector2i(999999, 999999)


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.4:
		return
	_accum = 0.0
	if _planet == null or _observer == null or not is_instance_valid(_observer):
		return
	var alt: float = _observer.global_position.distance_to(_planet.global_position) - _radius
	if alt > 160.0 or alt < -8.0:
		if _active:
			_set_patches_visible(false)
			_active = false
		return
	if not _built:
		_build_patches()
	_set_patches_visible(true)
	_active = true
	var cell := _surface_cell(_observer.global_position)
	if cell != _last_cell:
		_last_cell = cell
		_place_grid(cell)


func _surface_cell(global_pos: Vector3) -> Vector2i:
	## Stable UV-ish grid on sphere from lat/lon quantized by CELL_M.
	var local: Vector3 = (global_pos - _planet.global_position).normalized()
	var lat := asin(clampf(local.y, -1.0, 1.0))
	var lon := atan2(local.x, local.z)
	var meters_per_rad := _radius
	var cell_ang := CELL_M / maxf(meters_per_rad, 1.0)
	return Vector2i(int(floor(lon / cell_ang)), int(floor(lat / cell_ang)))


func _set_patches_visible(v: bool) -> void:
	for p in _patches:
		if p:
			p.visible = v


func _build_patches() -> void:
	_built = true
	var gq := get_node_or_null("/root/GraphicsQuality")
	var res := PATCH_RES
	var count := PATCH_COUNT
	if gq:
		match int(gq.tier):
			0:
				res = 8
				count = 5
			2, 3:
				res = 12
				count = 9
	for i in count:
		var mi := MeshInstance3D.new()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mi.mesh = _make_patch_mesh(res, i)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = _surface_color.lightened(0.04 + 0.02 * (i % 3))
		mat.roughness = 0.96
		mat.metallic = 0.0
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		mat.emission_enabled = false
		if gq and int(gq.tier) <= 0:
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mi.material_override = mat
		add_child(mi)
		_patches.append(mi)
	print("[SurfaceDetail] grid patches=", _patches.size())


func _make_patch_mesh(res: int, patch_i: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := PATCH_SIZE * 0.5
	var step := PATCH_SIZE / float(res - 1)
	var verts: Array[Vector3] = []
	for z in res:
		for x in res:
			var px := -half + x * step
			var pz := -half + z * step
			# Deterministic height from world seed + patch index (no Time)
			var n := _fbm(px * 0.08 + float(patch_i) * 3.1 + float(_seed) * 0.01, pz * 0.08 + float(patch_i) * 1.7)
			verts.append(Vector3(px, n * 2.6, pz))
	for z in res - 1:
		for x in res - 1:
			var i00 := z * res + x
			var i10 := i00 + 1
			var i01 := i00 + res
			var i11 := i01 + 1
			_add_tri(st, verts[i00], verts[i10], verts[i11])
			_add_tri(st, verts[i00], verts[i11], verts[i01])
	st.generate_normals()
	return st.commit()


func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _fbm(x: float, z: float) -> float:
	var v := 0.0
	var amp := 1.0
	var freq := 1.0
	for _o in 3:
		v += amp * sin(x * freq * 1.7 + z * freq * 1.3) * cos(z * freq * 0.9 - x * freq * 0.6)
		amp *= 0.5
		freq *= 2.1
	return v * 0.5


func _stable_tangent(up: Vector3) -> Array:
	## Fixed reference → no basis flip near poles (was a big "dance" source).
	up = up.normalized()
	var ref := Vector3.UP
	if absf(up.dot(ref)) > 0.92:
		ref = Vector3.RIGHT
	var east := ref.cross(up).normalized()
	var north := up.cross(east).normalized()
	return [east, north]


func _place_grid(cell: Vector2i) -> void:
	if _planet == null or _patches.is_empty():
		return
	# Center of current cell on sphere
	var meters_per_rad := _radius
	var cell_ang := CELL_M / maxf(meters_per_rad, 1.0)
	var lon := (float(cell.x) + 0.5) * cell_ang
	var lat := (float(cell.y) + 0.5) * cell_ang
	var clat := cos(lat)
	var center_dir := Vector3(sin(lon) * clat, sin(lat), cos(lon) * clat).normalized()
	var up := center_dir
	var t := _stable_tangent(up)
	var east: Vector3 = t[0]
	var north: Vector3 = t[1]
	# 3x3 grid of patches around cell center — FIXED offsets in meters (planet space)
	var n := _patches.size()
	var idx := 0
	for gz in range(-1, 2):
		for gx in range(-1, 2):
			if idx >= n:
				return
			var offset := east * (float(gx) * PATCH_SIZE * 0.95) + north * (float(gz) * PATCH_SIZE * 0.95)
			var dir := (center_dir * _radius + offset).normalized()
			var pos: Vector3 = _planet.global_position + dir * (_radius + 0.35)
			var pup := dir
			var tt := _stable_tangent(pup)
			var e: Vector3 = tt[0]
			var nr: Vector3 = tt[1]
			# Basis: X=east, Y=up, Z=-north so local patch +Y is radial
			var xf := Transform3D(Basis(e, pup, -nr), pos)
			_patches[idx].global_transform = xf
			idx += 1
	# Hide extras
	while idx < n:
		_patches[idx].visible = false
		idx += 1
