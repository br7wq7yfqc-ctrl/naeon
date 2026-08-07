extends Node3D
class_name ShipHullMorph
## Procedural / path-based hull morph for operational modes (Siege, Scan, Cargo).
## L1: tweens child plates. No Tripo required.

enum OpMode { CRUISE, SIEGE, SCAN, CARGO_OPEN, DOCK_CLAMP }

var op_mode: int = OpMode.CRUISE
var morph_t: float = 0.0  # 0 cruise .. 1 fully transformed
var _plates: Array = []  # {node, base: Transform3D, siege: Transform3D}
var _tween: Tween

func _ready() -> void:
	name = ShipHullMorph
	if get_child_count() == 0:
		_build_proxy_plates()


func _build_proxy_plates() -> void:
	## Visible non-hero geometry so Siege is readable without assets.
	_plates.clear()
	var specs := [
		{name: Barrel, pos: Vector3(0, 0.1, -1.2), size: Vector3(0.15, 0.15, 1.4),
			siege_pos: Vector3(0, 0.1, -2.2)},
		{name: RadiatorL, pos: Vector3(-1.1, 0.2, 0.3), size: Vector3(0.08, 0.6, 0.9),
			siege_rot: Vector3(0.6, 0, 0)},
		{name: RadiatorR, pos: Vector3(1.1, 0.2, 0.3), size: Vector3(0.08, 0.6, 0.9),
			siege_rot: Vector3(-0.6, 0, 0)},
		{name: Outrigger, pos: Vector3(0, -0.4, 0.5), size: Vector3(1.8, 0.08, 0.3),
			siege_scale: Vector3(1.5, 1.0, 1.2)},
	]
	for s in specs:
		var mi := MeshInstance3D.new()
		mi.name = str(s[name])
		var box := BoxMesh.new()
		box.size = s[size]
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.55, 0.75, 0.9)
		mat.metallic = 0.7
		mat.roughness = 0.35
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.6, 0.9)
		mat.emission_energy_multiplier = 0.4
		mi.material_override = mat
		add_child(mi)
		mi.position = s[pos]
		var base := mi.transform
		var siege_xf := base
		if s.has(siege_pos):
			siege_xf.origin = s[siege_pos]
		if s.has(siege_rot):
			var e: Vector3 = s[siege_rot]
			siege_xf.basis = Basis.from_euler(e) * base.basis
		if s.has(siege_scale):
			siege_xf.basis = siege_xf.basis.scaled(s[siege_scale])
		_plates.append({node: mi, base: base, siege: siege_xf})


func set_op_mode(mode: int, enter_sec: float = 1.0) -> void:
	if mode == op_mode:
		return
	op_mode = mode
	var target := 1.0 if mode == OpMode.SIEGE or mode == OpMode.CARGO_OPEN or mode == OpMode.SCAN else 0.0
	if mode == OpMode.SCAN:
		target = 0.55
	if mode == OpMode.CARGO_OPEN:
		target = 0.85
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_apply_morph_t, morph_t, target, maxf(enter_sec, 0.05))


func _apply_morph_t(t: float) -> void:
	morph_t = clampf(t, 0.0, 1.0)
	for p in _plates:
		var n: Node3D = p[node]
		if n == null or not is_instance_valid(n):
			continue
		var a: Transform3D = p[base]
		var b: Transform3D = p[siege]
		n.transform = a.interpolate_with(b, morph_t)


func op_mode_name() -> String:
	match op_mode:
		OpMode.SIEGE: return SIEGE
		OpMode.SCAN: return SCAN
		OpMode.CARGO_OPEN: return CARGO
		OpMode.DOCK_CLAMP: return DOCK
		_: return CRUISE
