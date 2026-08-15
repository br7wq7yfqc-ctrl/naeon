extends RefCounted
class_name ProceduralHeroSilhouette
## Code-first Cybernex / gROT silhouettes when Tripo GLB is absent.
## Identity + readability only — never combat power. Dual-theme. No shadows.

const CYAN := Color(0.18, 0.82, 1.0)
const MAGENTA := Color(0.95, 0.14, 0.42)
const STEEL := Color(0.12, 0.16, 0.22)
const FLESH := Color(0.22, 0.07, 0.12)


static func attach(host: Node3D, form: String, faction: String, hostile: bool = false) -> Node3D:
	if host == null or not is_instance_valid(host):
		return null
	if DisplayServer.get_name() == "headless":
		return null
	clear(host)
	var root := Node3D.new()
	root.name = "FormGLB"
	host.add_child(root)
	var grot := faction == "gROT" or faction == "grot"
	if hostile:
		_build_hostile(root, grot)
	else:
		match form:
			"Feline":
				_build_feline(root, grot)
			"Avian":
				_build_avian(root, grot)
			"Human":
				_build_human(root, grot)
			"Infector":
				_build_infector(root, grot)
			_:
				_build_canine(root, grot)
	return root


static func clear(host: Node3D) -> void:
	if host == null:
		return
	var old := host.get_node_or_null("FormGLB")
	if old:
		old.name = "_FormGLBDead"
		old.queue_free()


static func _emit(grot: bool) -> Color:
	return MAGENTA if grot else CYAN


static func _body(grot: bool) -> Color:
	return FLESH if grot else STEEL


static func _mat(kind: String, grot: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.emission_enabled = true
	m.cull_mode = BaseMaterial3D.CULL_BACK
	match kind:
		"emit":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = _emit(grot)
			m.emission = _emit(grot)
			m.emission_energy_multiplier = 2.4
		"visor":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(0.7, 0.95, 1.0) if not grot else Color(1.0, 0.35, 0.55)
			m.emission = m.albedo_color
			m.emission_energy_multiplier = 3.2
		"joint":
			m.albedo_color = _emit(grot) * 0.45
			m.metallic = 0.8
			m.roughness = 0.25
			m.emission = _emit(grot)
			m.emission_energy_multiplier = 1.1
		_:
			m.albedo_color = _body(grot)
			m.metallic = 0.72 if not grot else 0.25
			m.roughness = 0.32 if not grot else 0.62
			m.emission = _emit(grot)
			m.emission_energy_multiplier = 0.55 if not grot else 0.85
	return m


static func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, n: String = "", scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n if n != "" else "Part"
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(mi)
	return mi


static func _box(sx: float, sy: float, sz: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(sx, sy, sz)
	return b


static func _cap(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 8
	c.rings = 4
	return c


static func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 10
	s.rings = 6
	return s


static func _cyl(rt: float, rb: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = 8
	return c


static func _detail() -> int:
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		var gq = (tree as SceneTree).root.get_node_or_null("/root/GraphicsQuality")
		if gq and "tier" in gq:
			return int(gq.tier)
	return 1


static func _build_canine(root: Node3D, grot: bool) -> void:
	var armor := _mat("armor", grot)
	var emit := _mat("emit", grot)
	var visor := _mat("visor", grot)
	var joint := _mat("joint", grot)
	# Torso along Z, head toward −Z (camera sits at +Z)
	_part(root, _box(0.42, 0.36, 0.78), armor, Vector3(0, 0.78, 0.04), "Torso")
	_part(root, _box(0.48, 0.08, 0.55), emit, Vector3(0, 0.98, 0.02), "Spine")
	_part(root, _box(0.22, 0.22, 0.28), armor, Vector3(0, 0.92, -0.48), "Neck")
	_part(root, _box(0.32, 0.28, 0.34), armor, Vector3(0, 1.08, -0.68), "Head")
	_part(root, _box(0.18, 0.12, 0.26), armor, Vector3(0, 0.98, -0.92), "Snout")
	_part(root, _box(0.22, 0.06, 0.08), visor, Vector3(0, 1.12, -0.84), "Visor")
	_part(root, _box(0.08, 0.22, 0.12), emit, Vector3(-0.12, 1.28, -0.62), "EarL", Vector3.ONE, Vector3(0.15, 0, 0.35))
	_part(root, _box(0.08, 0.22, 0.12), emit, Vector3(0.12, 1.28, -0.62), "EarR", Vector3.ONE, Vector3(0.15, 0, -0.35))
	# Legs as direct children so ProceduralLocomotion phases them
	_part(root, _cyl(0.07, 0.09, 0.62), armor, Vector3(-0.16, 0.32, -0.22), "LegFL")
	_part(root, _cyl(0.07, 0.09, 0.62), armor, Vector3(0.16, 0.32, -0.22), "LegFR")
	_part(root, _cyl(0.07, 0.10, 0.62), armor, Vector3(-0.16, 0.32, 0.28), "LegBL")
	_part(root, _cyl(0.07, 0.10, 0.62), armor, Vector3(0.16, 0.32, 0.28), "LegBR")
	_part(root, _sph(0.08), joint, Vector3(-0.16, 0.58, -0.22), "JFL")
	_part(root, _sph(0.08), joint, Vector3(0.16, 0.58, -0.22), "JFR")
	_part(root, _cyl(0.04, 0.07, 0.55), emit, Vector3(0, 0.92, 0.48), "Tail", Vector3.ONE, Vector3(0.85, 0, 0))
	if _detail() >= 1:
		_part(root, _box(0.18, 0.22, 0.28), armor, Vector3(-0.28, 0.88, -0.08), "ShoulderL")
		_part(root, _box(0.18, 0.22, 0.28), armor, Vector3(0.28, 0.88, -0.08), "ShoulderR")
	if grot:
		_part(root, _cap(0.05, 0.42), emit, Vector3(-0.12, 1.05, 0.22), "TendrilL", Vector3.ONE, Vector3(0.6, 0, 0.4))
		_part(root, _cap(0.05, 0.42), emit, Vector3(0.12, 1.05, 0.22), "TendrilR", Vector3.ONE, Vector3(0.6, 0, -0.4))


static func _build_feline(root: Node3D, grot: bool) -> void:
	var armor := _mat("armor", grot)
	var emit := _mat("emit", grot)
	var visor := _mat("visor", grot)
	_part(root, _box(0.34, 0.30, 0.72), armor, Vector3(0, 0.70, 0.02), "Torso")
	_part(root, _box(0.12, 0.06, 0.50), emit, Vector3(0, 0.88, 0.0), "Spine")
	_part(root, _box(0.26, 0.24, 0.28), armor, Vector3(0, 0.92, -0.58), "Head")
	_part(root, _box(0.12, 0.08, 0.18), armor, Vector3(0, 0.86, -0.78), "Snout")
	_part(root, _box(0.18, 0.05, 0.06), visor, Vector3(0, 0.98, -0.70), "Visor")
	_part(root, _box(0.07, 0.20, 0.10), emit, Vector3(-0.10, 1.12, -0.52), "EarL")
	_part(root, _box(0.07, 0.20, 0.10), emit, Vector3(0.10, 1.12, -0.52), "EarR")
	_part(root, _cyl(0.055, 0.07, 0.58), armor, Vector3(-0.13, 0.28, -0.20), "LegFL")
	_part(root, _cyl(0.055, 0.07, 0.58), armor, Vector3(0.13, 0.28, -0.20), "LegFR")
	_part(root, _cyl(0.055, 0.07, 0.58), armor, Vector3(-0.13, 0.28, 0.24), "LegBL")
	_part(root, _cyl(0.055, 0.07, 0.58), armor, Vector3(0.13, 0.28, 0.24), "LegBR")
	_part(root, _cyl(0.03, 0.05, 0.72), emit, Vector3(0, 0.82, 0.52), "Tail", Vector3.ONE, Vector3(0.55, 0, 0))


static func _build_avian(root: Node3D, grot: bool) -> void:
	var armor := _mat("armor", grot)
	var emit := _mat("emit", grot)
	var visor := _mat("visor", grot)
	_part(root, _cap(0.22, 0.70), armor, Vector3(0, 0.95, 0.04), "Torso")
	_part(root, _sph(0.20), armor, Vector3(0, 1.42, -0.12), "Head")
	_part(root, _box(0.08, 0.08, 0.22), visor, Vector3(0, 1.38, -0.28), "Beak")
	_part(root, _box(0.16, 0.04, 0.06), emit, Vector3(0, 1.50, -0.18), "Crest")
	_part(root, _cyl(0.06, 0.08, 0.70), armor, Vector3(-0.10, 0.38, 0.04), "LegL")
	_part(root, _cyl(0.06, 0.08, 0.70), armor, Vector3(0.10, 0.38, 0.04), "LegR")
	# Wings — loco phases these as child meshes
	_part(root, _box(0.85, 0.05, 0.38), emit, Vector3(-0.55, 1.10, 0.05), "WingL", Vector3.ONE, Vector3(0.1, 0.35, 0.25))
	_part(root, _box(0.85, 0.05, 0.38), emit, Vector3(0.55, 1.10, 0.05), "WingR", Vector3.ONE, Vector3(0.1, -0.35, -0.25))
	_part(root, _box(0.10, 0.28, 0.08), armor, Vector3(0, 1.05, 0.32), "TailFan")


static func _build_human(root: Node3D, grot: bool) -> void:
	var armor := _mat("armor", grot)
	var emit := _mat("emit", grot)
	var visor := _mat("visor", grot)
	_part(root, _box(0.38, 0.48, 0.22), armor, Vector3(0, 1.15, 0.0), "Torso")
	_part(root, _box(0.42, 0.08, 0.10), emit, Vector3(0, 1.38, 0.12), "ChestBar")
	_part(root, _sph(0.16), armor, Vector3(0, 1.62, 0.0), "Head")
	_part(root, _box(0.22, 0.06, 0.04), visor, Vector3(0, 1.64, -0.14), "Visor")
	_part(root, _cyl(0.07, 0.08, 0.70), armor, Vector3(-0.12, 0.42, 0.0), "LegL")
	_part(root, _cyl(0.07, 0.08, 0.70), armor, Vector3(0.12, 0.42, 0.0), "LegR")
	_part(root, _cyl(0.055, 0.06, 0.55), armor, Vector3(-0.32, 1.12, 0.0), "ArmL", Vector3.ONE, Vector3(0, 0, 0.25))
	_part(root, _cyl(0.055, 0.06, 0.55), armor, Vector3(0.32, 1.12, 0.0), "ArmR", Vector3.ONE, Vector3(0, 0, -0.25))
	if grot:
		_part(root, _cap(0.04, 0.36), emit, Vector3(0.18, 1.40, 0.12), "Tendril")


static func _build_infector(root: Node3D, grot: bool) -> void:
	var armor := _mat("armor", true)
	var emit := _mat("emit", true)
	_part(root, _cap(0.28, 0.85), armor, Vector3(0, 0.85, 0.08), "Torso")
	_part(root, _sph(0.22), armor, Vector3(0, 1.28, -0.18), "Head")
	_part(root, _box(0.18, 0.08, 0.06), emit, Vector3(0, 1.32, -0.36), "Maw")
	_part(root, _cyl(0.08, 0.10, 0.62), armor, Vector3(-0.16, 0.34, 0.06), "LegL")
	_part(root, _cyl(0.08, 0.10, 0.62), armor, Vector3(0.16, 0.34, 0.10), "LegR")
	_part(root, _cap(0.06, 0.55), emit, Vector3(-0.28, 1.05, 0.12), "ArmL", Vector3.ONE, Vector3(0.4, 0, 0.5))
	_part(root, _cap(0.06, 0.55), emit, Vector3(0.28, 1.05, 0.12), "ArmR", Vector3.ONE, Vector3(0.4, 0, -0.5))
	_part(root, _cap(0.05, 0.48), emit, Vector3(0, 1.15, 0.28), "SpineTendril", Vector3.ONE, Vector3(0.9, 0, 0))
	_part(root, _cap(0.04, 0.40), emit, Vector3(-0.10, 1.40, -0.05), "HornL", Vector3.ONE, Vector3(-0.4, 0, 0.2))
	_part(root, _cap(0.04, 0.40), emit, Vector3(0.10, 1.40, -0.05), "HornR", Vector3.ONE, Vector3(-0.4, 0, -0.2))


static func _build_hostile(root: Node3D, grot: bool) -> void:
	var armor := _mat("armor", grot)
	var emit := _mat("emit", grot)
	var visor := _mat("visor", grot)
	if grot:
		_build_infector(root, true)
		return
	# Cybernex drone chassis
	_part(root, _box(0.55, 0.32, 0.55), armor, Vector3(0, 0.95, 0.0), "Core")
	_part(root, _sph(0.18), visor, Vector3(0, 1.12, -0.28), "Optic")
	_part(root, _cyl(0.04, 0.06, 0.45), emit, Vector3(0, 1.35, 0.05), "Antenna")
	_part(root, _cyl(0.06, 0.08, 0.70), armor, Vector3(-0.22, 0.38, -0.12), "LegFL")
	_part(root, _cyl(0.06, 0.08, 0.70), armor, Vector3(0.22, 0.38, -0.12), "LegFR")
	_part(root, _cyl(0.06, 0.08, 0.70), armor, Vector3(0.0, 0.38, 0.22), "LegB")
	_part(root, _box(0.12, 0.22, 0.08), emit, Vector3(-0.32, 1.05, 0.0), "PlateL")
	_part(root, _box(0.12, 0.22, 0.08), emit, Vector3(0.32, 1.05, 0.0), "PlateR")
