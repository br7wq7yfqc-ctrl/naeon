extends Node3D
class_name PlanetTerrainEdit
## Near-surface editable heightfield (NMS-like, hard limits) + undo + brush FX.
## Procedural base noise + player deltas. Far sphere unchanged. 0 Tripo.

signal edit_applied(raised: bool, cost: float)
signal budget_exhausted(reason: String)
signal undo_done()

const RES := 33
const WORLD_SIZE := 72.0
const MAX_DELTA := 8.0
const MAX_VOLUME := 4000.0
const BRUSH_RADIUS := 4.5
const BRUSH_STRENGTH := 1.8
const UNDO_DEPTH := 12

var planet: Node3D
var planet_id: String = "planet"
var radius: float = 1200.0
var surface_color: Color = Color(0.12, 0.2, 0.16)
var _seed: int = 1

var _mesh_inst: MeshInstance3D
var _body: StaticBody3D
var _col: CollisionShape3D
var _base: PackedFloat32Array
var _delta: PackedFloat32Array
var _volume_used: float = 0.0
var _observer: Node3D
var _plate_up: Vector3 = Vector3.UP
var _plate_origin: Vector3 = Vector3.ZERO
var _dirty: bool = true
var _accum: float = 0.0
var _edit_accum: float = 0.0
var _mat: StandardMaterial3D
var _undo: Array = []  # {delta: PackedFloat32Array, volume: float}
var _stroke_active: bool = false
var _fx: MeshInstance3D
var _fx_ttl: float = 0.0
var _dust: GPUParticles3D
var _dust_mat: ParticleProcessMaterial

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
	for i in n:
		var x := float(i % RES)
		var z := float(i / RES)
		_base[i] = _fbm(x * 0.35, z * 0.35) * 2.4
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
	# Brush FX ring
	_fx = MeshInstance3D.new()
	_fx.name = "BrushFX"
	var tm := TorusMesh.new()
	tm.inner_radius = BRUSH_RADIUS * 0.85
	tm.outer_radius = BRUSH_RADIUS
	tm.rings = 8
	tm.ring_segments = 16
	_fx.mesh = tm
	var fm := StandardMaterial3D.new()
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(0.3, 0.95, 0.7, 0.55)
	fm.emission_enabled = true
	fm.emission = Color(0.2, 1.0, 0.6)
	fm.emission_energy_multiplier = 2.0
	_fx.material_override = fm
	_fx.visible = false
	add_child(_fx)
	# Soil dust particles on terra stroke (code-first, 0 Tripo)
	_dust = GPUParticles3D.new()
	_dust.name = "TerraDust"
	_dust.amount = 48
	_dust.lifetime = 0.7
	_dust.one_shot = false
	_dust.explosiveness = 0.15
	_dust.visibility_aabb = AABB(Vector3(-12, -2, -12), Vector3(24, 10, 24))
	_dust.emitting = false
	_dust_mat = ParticleProcessMaterial.new()
	_dust_mat.direction = Vector3(0, 1, 0)
	_dust_mat.spread = 55.0
	_dust_mat.initial_velocity_min = 1.2
	_dust_mat.initial_velocity_max = 3.5
	_dust_mat.gravity = Vector3(0, -6.0, 0)
	_dust_mat.damping_min = 1.0
	_dust_mat.damping_max = 3.0
	_dust_mat.scale_min = 0.05
	_dust_mat.scale_max = 0.18
	_dust_mat.color = Color(0.45, 0.55, 0.4, 0.85)
	_dust.process_material = _dust_mat
	var dmesh := SphereMesh.new()
	dmesh.radius = 0.08
	dmesh.height = 0.16
	dmesh.radial_segments = 6
	dmesh.rings = 3
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(0.5, 0.45, 0.3)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmesh.material = dm
	_dust.draw_pass_1 = dmesh
	add_child(_dust)

func _process(delta: float) -> void:
	_accum += delta
	if _fx_ttl > 0.0:
		_fx_ttl -= delta
		if _fx:
			_fx.visible = _fx_ttl > 0.0
			var s := 1.0 + (1.0 - clampf(_fx_ttl, 0.0, 1.0)) * 0.3
			_fx.scale = Vector3(s, 0.2, s)
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
	# Undo: U key
	if _observer.is_in_group("player") and Input.is_physical_key_pressed(KEY_U):
		# edge via timer
		if not has_meta("_u_latched"):
			set_meta("_u_latched", true)
			undo_last()
	else:
		if has_meta("_u_latched"):
			remove_meta("_u_latched")
	_try_edit(delta)
	if _dirty:
		_rebuild_mesh()
		_dirty = false

func _reposition_plate() -> void:
	var to_obs: Vector3 = _observer.global_position - planet.global_position
	_plate_up = to_obs.normalized()
	_plate_origin = planet.global_position + _plate_up * (radius + 0.15)
	var f0 := Vector3.FORWARD
	if absf(_plate_up.dot(f0)) > 0.9:
		f0 = Vector3.RIGHT
	var right := _plate_up.cross(f0).normalized()
	var forward := right.cross(_plate_up).normalized()
	global_transform = Transform3D(Basis(right, _plate_up, -forward), _plate_origin)

func _snapshot() -> void:
	var snap := PackedFloat32Array()
	snap.resize(_delta.size())
	for i in _delta.size():
		snap[i] = _delta[i]
	_undo.append({"delta": snap, "volume": _volume_used})
	while _undo.size() > UNDO_DEPTH:
		_undo.pop_front()

func undo_last() -> void:
	if _undo.is_empty():
		return
	var s: Dictionary = _undo.pop_back()
	_delta = s["delta"]
	_volume_used = float(s["volume"])
	_dirty = true
	_save_edits()
	undo_done.emit()
	print("[TerrainEdit] undo remaining=", _undo.size())

func _try_edit(delta: float) -> void:
	if _observer == null or not _observer.is_in_group("player"):
		_stroke_active = false
		return
	var raise := Input.is_physical_key_pressed(KEY_G)
	var lower := Input.is_physical_key_pressed(KEY_B)
	if not raise and not lower:
		_stroke_active = false
		if _dust:
			_dust.emitting = false
		return
	if remaining_volume() <= 0.01:
		budget_exhausted.emit("planet_volume_cap")
		return
	if not _stroke_active:
		_snapshot()
		_stroke_active = true
	var local: Vector3 = global_transform.affine_inverse() * _observer.global_position
	var half := WORLD_SIZE * 0.5
	var u := (local.x + half) / WORLD_SIZE
	var v := (local.z + half) / WORLD_SIZE
	if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
		return
	# FX under player
	if _fx:
		_fx.visible = true
		_fx_ttl = 0.25
		_fx.position = Vector3(local.x, 0.4, local.z)
		var fm := _fx.material_override as StandardMaterial3D
		if fm:
			fm.emission = Color(0.2, 1.0, 0.55) if raise else Color(1.0, 0.45, 0.15)
			fm.albedo_color = Color(fm.emission.r, fm.emission.g, fm.emission.b, 0.5)
	if _dust:
		_dust.position = Vector3(local.x, 0.5, local.z)
		_dust.emitting = true
		if _dust_mat:
			_dust_mat.color = Color(0.35, 0.75, 0.45, 0.9) if raise else Color(0.75, 0.4, 0.2, 0.9)
			_dust_mat.direction = Vector3(0, 1 if raise else -0.2, 0)
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
			w = w * w
			var idx := j * RES + i
			var before: float = _delta[idx]
			var after: float = clampf(before + amount * w, -MAX_DELTA, MAX_DELTA)
			var diff: float = after - before
			if absf(diff) < 1e-5:
				continue
			var dvol: float = absf(diff) * cell * cell
			if _volume_used + dvol > MAX_VOLUME:
				budget_exhausted.emit("planet_volume_cap")
				return vol
			_delta[idx] = after
			_volume_used += dvol
			vol += dvol
	return vol

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
			verts[idx] = Vector3(px, _base[idx] + _delta[idx], pz)
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
	if mesh:
		_col.shape = mesh.create_trimesh_shape()

func _save_path() -> String:
	return "user://terrain_%s.dat" % planet_id

func _save_edits() -> void:
	var f := FileAccess.open(_save_path(), FileAccess.WRITE)
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
	f.get_32()
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
