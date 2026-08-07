extends Node3D
class_name CargoRamp
## Deployable cargo ramp for hangars / hauler holds. Procedural mesh.

signal state_changed(state: String)

enum State { STOWED, DEPLOYING, DEPLOYED, STOWING }

var state: int = State.STOWED
var _mesh: MeshInstance3D
var _body: StaticBody3D
var _angle: float = 0.0  # 0 stowed (up), 1 deployed
var _tween: Tween

@export var deploy_sec: float = 1.1
@export var ramp_length: float = 8.0
@export var ramp_width: float = 4.0

func _ready() -> void:
	_build()
	_apply_angle(0.0)

func _build() -> void:
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(ramp_width, 0.15, ramp_length)
	_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.2, 0.24)
	mat.metallic = 0.65
	mat.roughness = 0.4
	_mesh.material_override = mat
	add_child(_mesh)
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = box.size
	cs.shape = sh
	_body.add_child(cs)
	_mesh.add_child(_body)
	# hinge at ship end (local -Z half)
	_mesh.position = Vector3(0, 0, ramp_length * 0.5)

func toggle() -> void:
	if state == State.STOWED or state == State.STOWING:
		deploy()
	else:
		stow()

func deploy() -> void:
	if state == State.DEPLOYED or state == State.DEPLOYING:
		return
	state = State.DEPLOYING
	state_changed.emit("DEPLOYING")
	_animate_to(1.0, deploy_sec, State.DEPLOYED)

func stow() -> void:
	if state == State.STOWED or state == State.STOWING:
		return
	state = State.STOWING
	state_changed.emit("STOWING")
	_animate_to(0.0, deploy_sec * 0.85, State.STOWED)

func _animate_to(target: float, sec: float, end_state: int) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_apply_angle, _angle, target, maxf(sec, 0.05))
	_tween.tween_callback(func():
		state = end_state
		state_changed.emit("DEPLOYED" if end_state == State.DEPLOYED else "STOWED")
	)

func _apply_angle(t: float) -> void:
	_angle = clampf(t, 0.0, 1.0)
	# 0 = vertical stowed against hull, 1 = ~30° down
	var deg := lerpf(95.0, 28.0, _angle)
	rotation_degrees.x = deg
	if _body:
		_body.collision_layer = 1 if _angle > 0.2 else 0

func is_driveable() -> bool:
	return state == State.DEPLOYED
