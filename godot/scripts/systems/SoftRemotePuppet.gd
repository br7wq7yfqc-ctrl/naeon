extends Node3D
class_name SoftRemotePuppet
## Visual-only remote peer — soft multiplayer. No combat power, no authority.

var peer_id: int = 0
var form: String = "Canine"
var faction: String = "Cybernex"
var _target: Vector3 = Vector3.ZERO
var _target_yaw: float = 0.0
var _body: MeshInstance3D
var _label: Label3D
var _mat: StandardMaterial3D

func setup(id: int) -> void:
	peer_id = id
	name = "RemotePuppet_%d" % id
	_body = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.38
	cap.height = 1.15
	_body.mesh = cap
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.95, 0.55, 0.2, 0.75)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.45, 0.15)
	_mat.emission_energy_multiplier = 1.4
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_body.material_override = _mat
	_body.position = Vector3(0, 0.9, 0)
	add_child(_body)
	_label = Label3D.new()
	_label.font_size = 26
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 2.05, 0)
	_label.modulate = Color(1.0, 0.85, 0.55, 0.9)
	add_child(_label)
	_refresh_label()

func apply_state(pos: Vector3, yaw: float, f: String, fac: String) -> void:
	_target = pos
	_target_yaw = yaw
	var changed := form != f or faction != fac
	form = f
	faction = fac
	if changed:
		_refresh_visual()
	_refresh_label()

func _refresh_visual() -> void:
	if _mat == null:
		return
	if faction == "gROT":
		_mat.emission = Color(0.95, 0.15, 0.45)
		_mat.albedo_color = Color(0.9, 0.2, 0.4, 0.75)
	else:
		_mat.emission = Color(0.25, 0.85, 1.0)
		_mat.albedo_color = Color(0.25, 0.75, 0.95, 0.75)
	# Form scale flavor (soft readability only)
	var s := 1.0
	match form:
		"Feline":
			s = 0.92
		"Avian":
			s = 0.88
		"Human":
			s = 1.05
		"Infector":
			s = 1.1
		_:
			s = 1.0
	if _body:
		_body.scale = Vector3.ONE * s

func _refresh_label() -> void:
	if _label:
		_label.text = "P%d · %s · %s" % [peer_id, form, faction]

func _process(delta: float) -> void:
	global_position = global_position.lerp(_target, clampf(delta * 12.0, 0.0, 1.0))
	rotation.y = lerp_angle(rotation.y, _target_yaw, clampf(delta * 10.0, 0.0, 1.0))
