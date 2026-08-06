extends CharacterBody3D

## TPS controller for NAEON — forms, abilities, energy, ownership claims.

const FORMS := ["Canine", "Feline", "Avian", "Human"]

@export var move_speed: float = 8.0
@export var sprint_multiplier: float = 1.6
@export var jump_velocity: float = 6.5
@export var mouse_sensitivity: float = 0.0028
@export var max_health: float = 100.0
@export var max_energy: float = 100.0
@export var energy_regen: float = 12.0
@export var faction: String = "Cybernex"

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var ability_system: AbilitySystem = $AbilitySystem
@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var form_label: Label3D = $FormLabel

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_form: String = "Canine"
var health: float = 100.0
var energy: float = 100.0
var biomass: float = 0.0
var firewall_timer: float = 0.0
var _form_index: int = 0
var _body_mat: StandardMaterial3D

func _ready() -> void:
	health = max_health
	energy = max_energy
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_body_mat = StandardMaterial3D.new()
	_body_mat.albedo_color = Color(0.08, 0.12, 0.18)
	_body_mat.metallic = 0.6
	_body_mat.roughness = 0.3
	_body_mat.emission_enabled = true
	if body_mesh:
		body_mesh.material_override = _body_mat
	ability_system.setup_default_loadout(faction)
	ability_system.ability_activated.connect(_on_ability_activated)
	_apply_form_stats()
	add_to_group("player")
	print("[Player] Ready form=", current_form, " faction=", faction)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	if firewall_timer > 0.0:
		firewall_timer = max(0.0, firewall_timer - delta)
	energy = min(max_energy, energy + energy_regen * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed: float = move_speed
	if Input.is_action_pressed("sprint"):
		speed *= sprint_multiplier
	if current_form == "Avian" and not is_on_floor():
		velocity.y += 2.5 * delta
		speed *= 1.1

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	move_and_slide()

	if Input.is_action_just_pressed("ability_1"):
		ability_system.try_activate(0)
	if Input.is_action_just_pressed("ability_2"):
		ability_system.try_activate(1)
	if Input.is_action_just_pressed("ability_3"):
		ability_system.try_activate(2)
	if Input.is_action_just_pressed("ability_4"):
		cycle_form()

func cycle_form() -> void:
	_form_index = (_form_index + 1) % FORMS.size()
	switch_form(FORMS[_form_index])

func switch_form(new_form: String) -> void:
	current_form = new_form
	_apply_form_stats()
	print("[Player] Form → ", current_form)

func _apply_form_stats() -> void:
	match current_form:
		"Canine":
			move_speed = 8.5
			jump_velocity = 6.5
			sprint_multiplier = 1.7
		"Feline":
			move_speed = 9.5
			jump_velocity = 7.5
			sprint_multiplier = 1.5
		"Avian":
			move_speed = 7.5
			jump_velocity = 9.0
			sprint_multiplier = 1.4
		"Human":
			move_speed = 7.0
			jump_velocity = 6.0
			sprint_multiplier = 1.5
	if _body_mat:
		match current_form:
			"Canine":
				_body_mat.emission = Color(0.2, 0.85, 1.0)
			"Feline":
				_body_mat.emission = Color(0.9, 0.5, 0.15)
			"Avian":
				_body_mat.emission = Color(0.55, 0.35, 1.0)
			"Human":
				_body_mat.emission = Color(0.4, 0.9, 0.55)
		_body_mat.emission_energy_multiplier = 1.6
	if form_label:
		form_label.text = "%s | %s" % [current_form, faction]

func get_energy() -> float:
	return energy

func get_biomass() -> float:
	return biomass

func spend_energy(amount: float) -> void:
	energy = max(0.0, energy - amount)

func spend_biomass(amount: float) -> void:
	biomass = max(0.0, biomass - amount)

func get_faction() -> String:
	return faction

func heal(amount: float) -> void:
	health = min(max_health, health + amount)

func take_damage(amount: float) -> void:
	if firewall_timer > 0.0:
		amount *= 0.35
	health = max(0.0, health - amount)
	if health <= 0.0:
		_respawn()

func apply_firewall(duration: float, heal_amount: float = 0.0) -> void:
	firewall_timer = max(firewall_timer, duration)
	if heal_amount > 0.0:
		heal(heal_amount)

func _respawn() -> void:
	health = max_health
	energy = max_energy
	global_position = Vector3(0, 2, 0)
	velocity = Vector3.ZERO
	print("[Player] Respawned")

func _on_ability_activated(ability: Ability) -> void:
	if ability and ability.ability_name == "Form Cycle":
		cycle_form()
