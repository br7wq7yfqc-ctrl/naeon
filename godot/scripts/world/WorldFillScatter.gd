extends Node3D
class_name WorldFillScatter
## Unnamed rock/crate/debris/pad-prop proxies. Same body seed as Relief.
## Uses ledger slugs already on the shelf (debris_cluster, t1_resource_extractor,
## utility_bay) plus existing filler IDs. Channel offset is placement RNG only.
## Code-first until CC0 GLB is on s3://neon. Not SITE_*. Not a streamer.

const _Relief = preload("res://scripts/world/PlanetRelief.gd")
const _Filler = preload("res://scripts/world/FillerProp.gd")

const CHANNEL := 41
const ROCK_N := 8
const CRATE_N := 4
const DEBRIS_N := 3

var _seed: int = 1
var _planet_id: String = ""
var _placed: int = 0
var _slugs: PackedStringArray = PackedStringArray()


func setup(planet: Node3D, radius: float, seed_i: int) -> void:
	_seed = seed_i
	if planet != null and "planet_name" in planet:
		_planet_id = str(planet.planet_name)
	set_meta("site_pin", "")
	set_meta("worldfill_scatter", true)
	add_to_group("worldfill_scatter")
	_place(planet, radius)


func body_seed() -> int:
	return _seed


func prop_count() -> int:
	return _placed


func ledger_slugs_used() -> PackedStringArray:
	return _slugs


func _place(planet: Node3D, radius: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + CHANNEL
	var profile: Dictionary = _Relief.profile_for_planet(_planet_id)
	var dirs: Array[Vector3] = _host_dirs(planet)
	var rock_dirs: Array[Vector3] = []
	var crate_dirs: Array[Vector3] = []
	var debris_dirs: Array[Vector3] = []
	var guard := 0
	var need := ROCK_N + CRATE_N + DEBRIS_N
	while (rock_dirs.size() + crate_dirs.size() + debris_dirs.size()) < need and guard < 96:
		guard += 1
		var base: Vector3 = dirs[guard % dirs.size()]
		var yaw := rng.randf_range(-0.22, 0.22)
		var pit := rng.randf_range(-0.10, 0.12)
		var east := base.cross(Vector3.UP)
		if east.length_squared() < 0.01:
			east = base.cross(Vector3.RIGHT)
		east = east.normalized()
		var north := east.cross(base).normalized()
		var dir: Vector3 = (base + east * yaw + north * pit).normalized()
		var h: float = float(_Relief.height_at_dir(dir, _seed, profile))
		# Prefer land; after a few misses still place so 2 km read is not empty.
		if _Relief.is_sea(h, profile) and guard < 24:
			continue
		if rock_dirs.size() < ROCK_N:
			rock_dirs.append(dir)
		elif crate_dirs.size() < CRATE_N:
			crate_dirs.append(dir)
		elif debris_dirs.size() < DEBRIS_N:
			debris_dirs.append(dir)
	if rock_dirs.size() < 2:
		rock_dirs.append(Vector3(0.18, 0.16, 0.97).normalized())
		rock_dirs.append(Vector3(-0.40, 0.20, 0.89).normalized())
	if crate_dirs.is_empty() and not dirs.is_empty():
		crate_dirs.append(dirs[0])
	if debris_dirs.is_empty() and dirs.size() > 1:
		debris_dirs.append(dirs[1])
	elif debris_dirs.is_empty() and not dirs.is_empty():
		debris_dirs.append(dirs[0])
	_spawn_rocks(radius, profile, rock_dirs, rng)
	_spawn_crates(radius, profile, crate_dirs)
	_spawn_debris(radius, profile, debris_dirs)
	_spawn_pad_clutter(planet)
	print("[WorldFillScatter] props=", _placed, " seed=", _seed, " body=", _planet_id, " slugs=", ",".join(_slugs))


func _host_dirs(planet: Node3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if planet != null and "_pads" in planet:
		for p in planet._pads:
			if p is Node3D and is_instance_valid(p):
				var d: Vector3 = ((p as Node3D).global_position - planet.global_position)
				if d.length_squared() > 0.01:
					out.append(d.normalized())
	if out.is_empty():
		out.append(Vector3(0.20, 0.16, 0.97).normalized())
		out.append(Vector3(-0.44, 0.20, 0.88).normalized())
	return out


func _spawn_rocks(radius: float, profile: Dictionary, dirs: Array[Vector3], rng: RandomNumberGenerator) -> void:
	var root := Node3D.new()
	root.name = "Rocks"
	root.set_meta("site_pin", "")
	add_child(root)
	if DisplayServer.get_name() == "headless":
		for i in dirs.size():
			var m := Node3D.new()
			m.name = "Rock_%d" % i
			m.set_meta("filler_prop", true)
			m.set_meta("filler_id", "scatter_rock_cc0")
			m.set_meta("site_pin", "")
			root.add_child(m)
			m.position = _surface_pos(dirs[i], radius, profile)
			_placed += 1
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1, 1, 1)
	mm.mesh = mesh
	mm.instance_count = dirs.size()
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "RockBatch"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mmi.visibility_range_end = 3200.0
	mmi.visibility_range_end_margin = 240.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.38, 0.34, 0.28)
	mat.emission_enabled = true
	mat.emission = Color(0.22, 0.20, 0.16)
	mat.emission_energy_multiplier = 0.55
	mmi.material_override = mat
	root.add_child(mmi)
	for i in dirs.size():
		var dir: Vector3 = dirs[i]
		var pos: Vector3 = _surface_pos(dir, radius, profile)
		var s := rng.randf_range(12.0, 22.0)
		if i < 2:
			s = rng.randf_range(18.0, 26.0)
		var basis := _align_up(dir).scaled(Vector3(s, s * rng.randf_range(0.45, 0.75), s * rng.randf_range(0.7, 1.1)))
		mm.set_instance_transform(i, Transform3D(basis, pos))
		_placed += 1


func _spawn_crates(radius: float, profile: Dictionary, dirs: Array[Vector3]) -> void:
	for i in dirs.size():
		_add_field_prop(
			"Crate_%d" % i,
			"scatter_crate_cc0",
			"",
			_surface_pos(dirs[i], radius, profile),
			_align_up(dirs[i]),
			8.0,
			true
		)


func _spawn_debris(radius: float, profile: Dictionary, dirs: Array[Vector3]) -> void:
	for i in dirs.size():
		_add_field_prop(
			"Debris_%d" % i,
			"pad_debris_cluster",
			"debris_cluster",
			_surface_pos(dirs[i], radius, profile),
			_align_up(dirs[i]),
			6.5,
			true
		)


func _spawn_pad_clutter(planet: Node3D) -> void:
	if planet == null or not ("_pads" in planet):
		return
	var pads: Array = planet._pads
	for p in pads:
		if p == null or not (p is Node3D) or not is_instance_valid(p):
			continue
		var pad: Node3D = p
		var pname := str(pad.name)
		_add_pad_prop(pad, "PadCrate_0", "pad_crate_cc0", "", Vector3(10.0, 1.15, -8.0), 4.2)
		_add_pad_prop(pad, "PadCrate_1", "pad_crate_cc0", "", Vector3(-9.0, 1.15, 7.0), 3.8)
		_add_pad_prop(pad, "PadDebris", "pad_debris_cluster", "debris_cluster", Vector3(16.0, 1.4, 12.0), 3.2)
		# Extra mast on the plates that are not the OS-G silhouette host.
		if pname != "Pad_Approach":
			_add_pad_prop(pad, "PadMast", "outpost_mast_cc0", "", Vector3(-14.0, 0.0, 10.0), 1.6)
		if pname == "Pad_North":
			_add_pad_prop(pad, "PadExtractor", "pad_extractor_t1", "t1_resource_extractor", Vector3(0.0, 0.0, -16.0), 1.8)
		elif pname == "Pad_Flank":
			_add_pad_prop(pad, "PadUtility", "pad_utility_bay", "utility_bay", Vector3(12.0, 0.0, 14.0), 1.7)


func _add_field_prop(nm: String, filler_id: String, slug: String, pos: Vector3, basis: Basis, scale_f: float, far: bool) -> void:
	var fp := Node3D.new()
	fp.set_script(_Filler)
	fp.name = nm
	fp.set("prop_id", filler_id)
	fp.set("scale_factor", scale_f)
	fp.set("far_read", far)
	add_child(fp)
	if fp.has_method("setup"):
		fp.call("setup", filler_id)
	fp.position = pos
	fp.transform.basis = basis
	_note_prop(fp, slug)
	_placed += 1


func _add_pad_prop(pad: Node3D, nm: String, filler_id: String, slug: String, local_pos: Vector3, scale_f: float) -> void:
	if pad.has_node(nm):
		return
	var fp := Node3D.new()
	fp.set_script(_Filler)
	fp.name = nm
	fp.set("prop_id", filler_id)
	fp.set("scale_factor", scale_f)
	fp.set("far_read", true)
	pad.add_child(fp)
	if fp.has_method("setup"):
		fp.call("setup", filler_id)
	fp.position = local_pos
	_note_prop(fp, slug)
	_placed += 1


func _note_prop(fp: Node, slug: String) -> void:
	if slug != "":
		fp.set_meta("ledger_slug", slug)
		if not _slugs.has(slug):
			_slugs.append(slug)


func _surface_pos(dir: Vector3, radius: float, profile: Dictionary) -> Vector3:
	var h: float = float(_Relief.height_at_dir(dir, _seed, profile))
	return dir.normalized() * (radius + maxf(h, 0.4) + 1.2)


func _align_up(up: Vector3) -> Basis:
	up = up.normalized()
	var x := up.cross(Vector3(0, 0, 1))
	if x.length() < 0.05:
		x = up.cross(Vector3(1, 0, 0))
	x = x.normalized()
	var z := x.cross(up).normalized()
	return Basis(x, up, z)
