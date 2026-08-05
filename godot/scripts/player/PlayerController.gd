extends CharacterBody3D

## Basic TPS controller for NAEON
## Supports form switching skeleton and Ability System

@export var move_speed: float = 8.0
@export var sprint_multiplier: float = 1.6
@export var jump_velocity: float = 6.5
@export var mouse_sensitivity: float = 0.003

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var ability_system: AbilitySystem = $AbilitySystem

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_form: String = "Canine"  # Canine, Feline, Avian, Human, GrotBrute...

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("[Player] Ready. Current form: ", current_form)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var speed = move_speed
	if Input.is_action_pressed("sprint"):
		speed *= sprint_multiplier
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
	
	# Abilities
	if Input.is_action_just_pressed("ability_1"):
		ability_system.try_activate(0)
	if Input.is_action_just_pressed("ability_2"):
		ability_system.try_activate(1)
	if Input.is_action_just_pressed("ability_3"):
		ability_system.try_activate(2)
	if Input.is_action_just_pressed("ability_4"):
		ability_system.try_activate(3)

func switch_form(new_form: String) -> void:
	current_form = new_form
	print("[Player] Switched to form: ", current_form)
	# TODO: Change mesh, animations, stats, available abilities
