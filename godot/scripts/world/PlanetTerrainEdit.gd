extends Node3D
class_name PlanetTerrainEdit
## Near-surface editable heightfield (NMS-like, hard limits).
## Procedural base noise + player deltas. Far sphere unchanged.
## No Tripo. Optimized for min RTX 1060 / rec 3060.

signal edit_applied(raised: bool, cost: float)
signal budget_exhausted(reason: String)

const RES := 33  # verts per side
const WORLD_SIZE := 72.0  # meters across plate
const MAX_DELTA := 8.0  # max |height| change per cell (m)
const MAX_VOLUME := 4000.0  # total abs m³ of edits per planet (soft hard-cap)
const BRUSH_RADIUS := 4.5
const BRUSH_STRENGTH := 1.8  # m/s at full hold

var planet: Node3D
var planet_id: String = "planet"
var radius: float = 1200.0
var surface_color: Color = Color(0.12, 0.2, 0.16)
var _seed: int = 1

var _mesh_inst: MeshInstance3D
var _body: StaticBody3D
var _col: CollisionShape3D
var _base: PackedFloat32Array  # base noise
var _delta: PackedFloat32Array  # edits
var _volume_used: float = 0.0
var _observer: Node3D
var _plate_up: Vector3 = Vector3.UP
var _plate_origin: Vector3 = Vector3.ZERO
var _dirty: bool = true
var _accum: float = 0.0
var _edit_accum: float = 0.0
var _mat: StandardMaterial3D

func setup(p: Node3D, r: float, color: Color, seed_i: int, id: String) -> void:
	add_to_group("terrain_edit")
	planet = p
	radius = r
	surface_color = color
	_seed = seed_i
	planet_id = id
	_init_heights()
	_load_edits()
	_ensure_nodes()
	_rebuild_mesh()
	set_process(true)

func set_observer(n: Node3D) -> void:
	_observer = n

func get_budget_ratio() -> float:
	return clampf(_volume_used / MAX_VOLUME, 0.0, 1.0)

func remaining_volume() -> float:
	return maxf(0.0, MAX_VOLUME - _volume_used)

func _init_heights() -> void:
	var n := RES * RES
	_base = PackedFloat32Array()
	_base.resize(n)
	_delta = PackedFloat32Array()
	_delta.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for i in n:
		var x := float(i % RES)
		var z := float(i / RES)
		var h := _fbm(x * 0.35, z * 0.35) * 2.4
		_base[i] = h
		_delta[i] = 0.0

func _fbm(x: float, z: float) -> float:
	var v := 0.0
	var a := 1.0
	var f := 1.0
	for _o in 4:
		v += a * sin(x * f * 1.71 + z * f * 1.13 + float(_seed) * 0.01) * cos(z * f * 0.97 - x * f * 0.61)
		a *= 0.5
		f *= 2.05
	return v * 0.45

func _ensure_nodes() -> void:
	if _mesh_inst:
		return
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.name = "EditPlate"
	_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh_inst.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = surface_color.lightened(0.08)
	_mat.roughness = 0.92
	_mat.metallic = 0.0
	_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and int(gq.tier) <= 0:
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	_mesh_inst.material_override = _mat
	add_child(_mesh_inst)

	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	_col = CollisionShape3D.new()
	_body.add_child(_col)
	add_child(_body)

func _process(delta: float) -> void:
	_accum += delta
	if _observer == null or planet == null or not is_instance_valid(_observer):
		visible = false
		return
	var alt: float = _observer.global_position.distance_to(planet.global_position) - radius
	if alt > 120.0 or alt < -8.0:
		visible = false
		return
	visible = true
	if _accum >= 0.2:
		_accum = 0.0
		_reposition_plate()
	_try_edit(delta)
	if _dirty:
		_rebuild_mesh()
		_dirty = false

func _reposition_plate() -> void:
	var to_obs: Vector3 = _observer.global_position - planet.global_position
	_plate_up = to_obs.normalized()
	_plate_origin = planet.global_position + _plate_up * (radius + 0.15)
	# Basis: Y = radial up
	var f0 := Vector3.FORWARD
	if absf(_plate_up.dot(f0)) > 0.9:
		f0 = Vector3.RIGHT
	var right := _plate_up.cross(f0).normalized()
	var forward := right.cross(_plate_up).normalized()
	global_transform = Transform3D(Basis(right, _plate_up, -forward), _plate_origin)

func _try_edit(delta: float) -> void:
	# Only on foot (player group), not ship pilot
	if _observer == null or not _observer.is_in_group("player"):
		return
	var raise := Input.is_physical_key_pressed(KEY_G)
	var lower := Input.is_physical_key_pressed(KEY_B)
	if not raise and not lower:
		return
	if remaining_volume() <= 0.01:
		budget_exhausted.emit("planet_volume_cap")
		return
	# Brush center = under player projected on plate
	var local: Vector3 = global_transform.affine_inverse() * _observer.global_position
	var half := WORLD_SIZE * 0.5
	var u := (local.x + half) / WORLD_SIZE
	var v := (local.z + half) / WORLD_SIZE
	if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
		return
	var sign := 1.0 if raise else -1.0
	var applied := _apply_brush(u, v, sign * BRUSH_STRENGTH * delta)
	if applied > 0.0:
		_dirty = true
		_edit_accum += applied
		if _edit_accum > 2.0:
			_edit_accum = 0.0
			_save_edits()
		edit_applied.emit(raise, applied)

func _apply_brush(u: float, v: float, amount: float) -> float:
	var cx := u * float(RES - 1)
	var cz := v * float(RES - 1)
	var cell := WORLD_SIZE / float(RES - 1)
	var r_cells := BRUSH_RADIUS / cell
	var vol := 0.0
	var i0 := maxi(0, int(cx - r_cells) - 1)
	var i1 := mini(RES - 1, int(cx + r_cells) + 1)
	var j0 := maxi(0, int(cz - r_cells) - 1)
	var j1 := mini(RES - 1, int(cz + r_cells) + 1)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var dx := float(i) - cx
			var dz := float(j) - cz
			var d := sqrt(dx * dx + dz * dz)
			if d > r_cells:
				continue
			var w := 1.0 - d / r_cells
			w = w * w  # smooth falloff
			var idx := j * RES + i
			var before: float = _delta[idx]
			var after: float = clampf(before + amount * w, -MAX_DELTA, MAX_DELTA)
			var diff: float = after - before
			if absf(diff) < 1e-5:
				continue
			# Volume ≈ |diff| * cell²
			var dvol: float = absf(diff) * cell * cell
			if _volume_used + dvol > MAX_VOLUME:
				budget_exhausted.emit("planet_volume_cap")
				return vol
			_delta[idx] = after
			_volume_used += dvol
			vol += dvol
	return vol

func height_at_local(x: float, z: float) -> float:
	# Bilinear sample
	var half := WORLD_SIZE * 0.5
	var u := (x + half) / WORLD_SIZE * float(RES - 1)
	var v := (z + half) / WORLD_SIZE * float(RES - 1)
	var i0 := clampi(int(u), 0, RES - 2)
	var j0 := clampi(int(v), 0, RES - 2)
	var fu := u - float(i0)
	var fv := v - float(j0)
	var h00 := _base[j0 * RES + i0] + _delta[j0 * RES + i0]
	var h10 := _base[j0 * RES + i0 + 1] + _delta[j0 * RES + i0 + 1]
	var h01 := _base[(j0 + 1) * RES + i0] + _delta[(j0 + 1) * RES + i0]
	var h11 := _base[(j0 + 1) * RES + i0 + 1] + _delta[(j0 + 1) * RES + i0 + 1]
	var h0 := lerpf(h00, h10, fu)
	var h1 := lerpf(h01, h11, fu)
	return lerpf(h0, h1, fv)

func _rebuild_mesh() -> void:
	_ensure_nodes()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := WORLD_SIZE * 0.5
	var step := WORLD_SIZE / float(RES - 1)
	var verts: Array[Vector3] = []
	verts.resize(RES * RES)
	for z in RES:
		for x in RES:
			var px := -half + float(x) * step
			var pz := -half + float(z) * step
			var idx := z * RES + x
			var py: float = _base[idx] + _delta[idx]
			verts[idx] = Vector3(px, py, pz)
	for z in RES - 1:
		for x in RES - 1:
			var i00 := z * RES + x
			var i10 := i00 + 1
			var i01 := i00 + RES
			var i11 := i01 + 1
			st.add_vertex(verts[i00])
			st.add_vertex(verts[i10])
			st.add_vertex(verts[i11])
			st.add_vertex(verts[i00])
			st.add_vertex(verts[i11])
			st.add_vertex(verts[i01])
	st.generate_normals()
	var mesh := st.commit()
	_mesh_inst.mesh = mesh
	# Collision: convex is wrong for terrain — use trimesh
	if mesh:
		var shape := mesh.create_trimesh_shape()
		_col.shape = shape

func _save_path() -> String:
	return "user://terrain_%s.dat" % planet_id

func _save_edits() -> void:
	var path := _save_path()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_32(_seed)
	f.store_float(_volume_used)
	f.store_32(RES)
	for i in _delta.size():
		f.store_float(_delta[i])
	f.close()

func _load_edits() -> void:
	var path := _save_path()
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var s := f.get_32()
	_volume_used = f.get_float()
	var res := f.get_32()
	if res != RES:
		f.close()
		return
	for i in RES * RES:
		if f.eof_reached():
			break
		_delta[i] = clampf(f.get_float(), -MAX_DELTA, MAX_DELTA)
	f.close()
	_dirty = true
	print("[TerrainEdit] loaded ", path, " volume=", _volume_used)
