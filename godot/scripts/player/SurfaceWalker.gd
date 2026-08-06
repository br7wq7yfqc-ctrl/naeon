extends CharacterBody3D
## Simple TPS walker with optional planetary gravity from OpenSpace.

@export var speed: float = 6.5
@export var sprint_mult: float = 1.7
@export var jump_velocity: float = 6.5
@export var mouse_sensitivity: float = 0.0025

var _yaw: float = 0.0
var _pitch: float = 0.0
var _provider: Node = null  # OpenSpace
@onready var cam_pivot: Node3D = $CamPivot

func set_planet_gravity_provider(p: Node) -> void:
	_provider = p

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-75), deg_to_rad(75))
		rotation.y = _yaw
		if cam_pivot:
			cam_pivot.rotation.x = _pitch
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

func _physics_process(delta: float) -> void:
	var g := Vector3(0, -9.8, 0)
	if _provider and _provider.has_method("gravity_at"):
		var pg: Vector3 = _provider.gravity_at(global_position)
		if pg.length() > 0.1:
			g = pg
	# Orient feet toward gravity (soft)
	var up := -g.normalized()
	# Movement in local XZ relative to camera yaw
	var input := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		input.y += 1
	if Input.is_physical_key_pressed(KEY_A):
		input.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		input.x += 1
	input = input.normalized()
	var basis_yaw := Basis(up, _yaw)
	var forward: Vector3 = -basis_yaw.z
	var right: Vector3 = basis_yaw.x
	# Project onto plane perpendicular to gravity
	forward = (forward - up * forward.dot(up)).normalized()
	right = (right - up * right.dot(up)).normalized()
	var wish: Vector3 = (right * input.x + forward * (-input.y))
	var sp := speed
	if Input.is_physical_key_pressed(KEY_SHIFT):
		sp *= sprint_mult
	var planar := wish * sp
	# Integrate gravity
	velocity += g * delta
	# Replace planar components
	var v_up: float = velocity.dot(up)
	velocity = planar + up * v_up
	if is_on_floor() and Input.is_physical_key_pressed(KEY_SPACE):
		velocity += up * jump_velocity
	# Align body up roughly
	global_transform = _look_up(global_position, up, _yaw)
	move_and_slide()

func _look_up(pos: Vector3, up: Vector3, yaw: float) -> Transform3D:
	up = up.normalized()
	var fwd := Basis(up, yaw).z * -1.0
	fwd = (fwd - up * fwd.dot(up)).normalized()
	var right := up.cross(fwd).normalized()
	fwd = right.cross(up).normalized()
	return Transform3D(Basis(right, up, fwd), pos)
