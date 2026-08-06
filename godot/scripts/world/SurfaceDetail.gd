extends Node3D
class_name SurfaceDetail
## Procedural surface height patches around observer when near planet.
## Cheap ArrayMesh displacement — no Tripo. Optimized for 1060+.

const PATCH_COUNT := 8
const PATCH_RES := 12  # verts per side
const PATCH_SIZE := 48.0

var _planet: Node3D
var _radius: float = 1200.0
var _surface_color: Color = Color(0.12, 0.2, 0.16)
var _patches: Array[MeshInstance3D] = []
var _observer: Node3D
var _built: bool = false
var _accum: float = 0.0
var _seed: int = 1

func setup(planet: Node3D, radius: float, color: Color, seed_i: int = 1) -> void:
	_planet = planet
	_radius = radius
	_surface_color = color
	_seed = seed_i

func set_observer(n: Node3D) -> void:
	_observer = n

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.35:
		return
	_accum = 0.0
	if _planet == null or _observer == null or not is_instance_valid(_observer):
		return
	var alt: float = _observer.global_position.distance_to(_planet.global_position) - _radius
	if alt > 180.0 or alt < -5.0:
		_set_patches_visible(false)
		return
	_set_patches_visible(true)
	if not _built:
		_build_patches()
	_update_patch_positions()

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
				res = 16
				count = 10
	for i in count:
		var mi := MeshInstance3D.new()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mi.mesh = _make_patch_mesh(res, i)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = _surface_color.lightened(0.05 + 0.03 * (i % 3))
		mat.roughness = 0.95
		mat.metallic = 0.0
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		# Vertex shading cheaper on LOW
		if gq and int(gq.tier) <= 0:
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mi.material_override = mat
		add_child(mi)
		_patches.append(mi)
	print("[SurfaceDetail] patches=", _patches.size(), " planet=", _planet.name if _planet else "?")

func _make_patch_mesh(res: int, patch_i: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 997 + patch_i * 31
	var half := PATCH_SIZE * 0.5
	var step := PATCH_SIZE / float(res - 1)
	# Build grid in local XZ, Y = noise height
	var verts: Array[Vector3] = []
	for z in res:
		for x in res:
			var px := -half + x * step
			var pz := -half + z * step
			var n := _fbm(px * 0.08 + patch_i * 3.1, pz * 0.08 + patch_i * 1.7, rng)
			var py := n * 3.2  # height meters
			verts.append(Vector3(px, py, pz))
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
	st.set_normal(Vector3.UP)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)

func _fbm(x: float, z: float, rng: RandomNumberGenerator) -> float:
	# Deterministic-ish value noise via sin hash (no texture)
	var v := 0.0
	var amp := 1.0
	var freq := 1.0
	for _o in 3:
		v += amp * sin(x * freq * 1.7 + z * freq * 1.3) * cos(z * freq * 0.9 - x * freq * 0.6)
		amp *= 0.5
		freq *= 2.1
	return v * 0.5

func _update_patch_positions() -> void:
	if _planet == null or _observer == null:
		return
	var to_obs: Vector3 = _observer.global_position - _planet.global_position
	var up: Vector3 = to_obs.normalized()
	# Place patches in a ring around observer projected on surface
	var n := _patches.size()
	for i in n:
		var ang := TAU * float(i) / float(n) + Time.get_ticks_msec() * 0.00001
		var right := up.cross(Vector3.FORWARD)
		if right.length_squared() < 0.01:
			right = up.cross(Vector3.RIGHT)
		right = right.normalized()
		var forward := right.cross(up).normalized()
		var offset := (right * cos(ang) + forward * sin(ang)) * (28.0 + float(i % 3) * 18.0)
		var center: Vector3 = up * (_radius + 0.4) + offset
		# Orient patch: Y = radial out
		var y := up
		var x := y.cross(forward)
		if x.length_squared() < 0.01:
			x = y.cross(right)
		x = x.normalized()
		var z := x.cross(y).normalized()
		var xf := Transform3D(Basis(x, y, z), _planet.global_position + center)
		_patches[i].global_transform = xf
