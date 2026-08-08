extends Node3D
class_name LivingConfig
## Dynamic configuration morph for Cybernex / gROT modules.
## Plates, actuators, neon strips shift by mode — visual identity, no P2W.

enum FactionStyle { CYBERNEX, GROT }
enum ConfigMode { IDLE, COMBAT, SIEGE, SCAN, DOCK, EVA }

@export var faction_style: int = FactionStyle.CYBERNEX
var mode: int = ConfigMode.IDLE
var morph: float = 0.0
var _parts: Array = []  # {node, idle:Transform3D, combat, siege, scan}
var _neon: Array[MeshInstance3D] = []
var _tween: Tween
var _pulse_t: float = 0.0


func setup_from_faction(fac: String) -> void:
	call_deferred("_try_actuator_glb")
	faction_style = FactionStyle.GROT if fac == "gROT" else FactionStyle.CYBERNEX
	_ensure_proxy_if_empty()
	_apply_faction_materials()
	set_process(true)


func _ready() -> void:
	if get_child_count() == 0:
		_ensure_proxy_if_empty()
	set_process(true)


func _ensure_proxy_if_empty() -> void:
	if not _parts.is_empty():
		return
	_parts.clear()
	_neon.clear()
	var specs: Array = [
		{"n": "PlateA", "pos": Vector3(-0.6, 0.2, 0.0), "sz": Vector3(0.5, 0.08, 0.7),
			"combat": Vector3(-0.85, 0.25, 0.0), "siege": Vector3(-1.1, 0.1, 0.2)},
		{"n": "PlateB", "pos": Vector3(0.6, 0.2, 0.0), "sz": Vector3(0.5, 0.08, 0.7),
			"combat": Vector3(0.85, 0.25, 0.0), "siege": Vector3(1.1, 0.1, 0.2)},
		{"n": "Spine", "pos": Vector3(0, 0.35, 0.2), "sz": Vector3(0.2, 0.5, 0.9),
			"combat": Vector3(0, 0.45, 0.1), "siege": Vector3(0, 0.55, -0.1)},
		{"n": "Actuator", "pos": Vector3(0, -0.1, 0.4), "sz": Vector3(0.15, 0.15, 0.5),
			"combat": Vector3(0, -0.15, 0.55), "siege": Vector3(0, -0.2, 0.8)},
	]
	for s in specs:
		var mi := MeshInstance3D.new()
		mi.name = str(s["n"])
		var box := BoxMesh.new()
		box.size = s["sz"]
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.metallic = 0.7
		mat.roughness = 0.35
		mat.emission_enabled = true
		mi.material_override = mat
		add_child(mi)
		mi.position = s["pos"]
		var idle := mi.transform
		var combat := idle
		combat.origin = s["combat"]
		var siege := idle
		siege.origin = s["siege"]
		if str(s["n"]) == "PlateA":
			siege.basis = Basis.from_euler(Vector3(0, 0, 0.45)) * idle.basis
		elif str(s["n"]) == "PlateB":
			siege.basis = Basis.from_euler(Vector3(0, 0, -0.45)) * idle.basis
		_parts.append({"node": mi, "idle": idle, "combat": combat, "siege": siege, "scan": combat.interpolate_with(idle, 0.4)})
	# Neon strip ring
	for i in 3:
		var n := MeshInstance3D.new()
		n.name = "Neon_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(0.06, 0.06, 0.9)
		n.mesh = bm
		var mat2 := StandardMaterial3D.new()
		mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat2.emission_enabled = true
		mat2.emission_energy_multiplier = 2.5
		n.material_override = mat2
		n.position = Vector3(cos(float(i) * TAU / 3.0) * 0.5, 0.15, sin(float(i) * TAU / 3.0) * 0.5)
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(n)
		_neon.append(n)
	_apply_faction_materials()


func _apply_faction_materials() -> void:
	var col := Color(0.2, 0.75, 1.0) if faction_style == FactionStyle.CYBERNEX else Color(0.95, 0.15, 0.42)
	var body := Color(0.15, 0.22, 0.3) if faction_style == FactionStyle.CYBERNEX else Color(0.28, 0.1, 0.16)
	for p in _parts:
		var n: MeshInstance3D = p["node"]
		if n and n.material_override is StandardMaterial3D:
			var m: StandardMaterial3D = n.material_override
			m.albedo_color = body
			m.emission = col
			m.emission_energy_multiplier = 0.55
	for n in _neon:
		if n and n.material_override is StandardMaterial3D:
			var m2: StandardMaterial3D = n.material_override
			m2.albedo_color = col
			m2.emission = col


func set_mode(m: int, sec: float = 0.85) -> void:
	if m == mode and absf(morph - _mode_target(m)) < 0.01:
		return
	mode = m
	var target := _mode_target(m)
	if _tween and is_instance_valid(_tween):
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_apply_morph, morph, target, maxf(sec, 0.05))


func _mode_target(m: int) -> float:
	match m:
		ConfigMode.SIEGE:
			return 1.0
		ConfigMode.COMBAT:
			return 0.65
		ConfigMode.SCAN:
			return 0.4
		ConfigMode.DOCK:
			return 0.25
		ConfigMode.EVA:
			return 0.5
		_:
			return 0.0


func _apply_morph(t: float) -> void:
	morph = clampf(t, 0.0, 1.0)
	for p in _parts:
		var n: Node3D = p["node"]
		if n == null or not is_instance_valid(n):
			continue
		var idle: Transform3D = p["idle"]
		var combat: Transform3D = p["combat"]
		var siege: Transform3D = p["siege"]
		var mid: Transform3D = idle.interpolate_with(combat, clampf(morph / 0.65, 0.0, 1.0))
		if morph > 0.65:
			var u := (morph - 0.65) / 0.35
			n.transform = mid.interpolate_with(siege, u)
		else:
			n.transform = mid


func _process(delta: float) -> void:
	_pulse_t += delta
	var col := Color(0.25, 0.9, 1.0) if faction_style == FactionStyle.CYBERNEX else Color(0.95, 0.2, 0.45)
	var pulse := 1.8 + 1.2 * sin(_pulse_t * 3.5) + morph * 1.5
	for n in _neon:
		if n and n.material_override is StandardMaterial3D:
			var m: StandardMaterial3D = n.material_override
			m.emission = col
			m.emission_energy_multiplier = pulse
			n.rotate_y(delta * (1.2 + morph))



func _try_actuator_glb() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var AP = load("res://scripts/assets/AssetPaths.gd")
	if AP == null or not AP.has_method("resolve"):
		return
	var fac := "grot" if faction_style == FactionStyle.GROT else "cybernex"
	var rel := "ships/living_config_actuator/living_config_actuator_%s_lod2.glb" % fac
	var path: String = str(AP.resolve(rel))
	if path == "" or not FileAccess.file_exists(path):
		return
	var doc := GLTFDocument.new()
	var st2 := GLTFState.new()
	if doc.append_from_file(path, st2) != OK:
		return
	var scn := doc.generate_scene(st2)
	if scn == null:
		return
	add_child(scn)
	scn.position = Vector3(0, 0.2, 0.5)
	scn.scale = Vector3.ONE * 0.35
	_parts.append({"node": scn, "idle": scn.transform, "combat": scn.transform.translated(Vector3(0, 0.1, 0.15)), "siege": scn.transform.translated(Vector3(0, 0.2, 0.35)), "scan": scn.transform})
