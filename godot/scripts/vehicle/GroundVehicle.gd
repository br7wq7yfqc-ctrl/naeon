extends CharacterBody3D
class_name GroundVehicle
## Surface rover stub — full drive loop in sprint V2.
## Board/exit F; gravity along planet up when provider set.

@export var class_id: String = "rover"
@export var display_name: String = "Rover"
@export var speed: float = 12.0
@export var turn_speed: float = 1.8
@export var volume_m3: float = 8.0
@export var mass_t: float = 2.0

var pilot: Node3D = null
var _provider: Node = null
var _up: Vector3 = Vector3.UP
var _yaw: float = 0.0
var _cam: Camera3D

func _ready() -> void:
	add_to_group("ground_vehicle")
	collision_layer = 2
	collision_mask = 1
	_build_proxy()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.0, 3.4)
	col.shape = box
	col.position.y = 0.5
	add_child(col)

func _build_proxy() -> void:
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.0, 0.7, 3.0)
	body.mesh = box
	body.position.y = 0.55
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.45, 0.35)
	mat.metallic = 0.5
	body.material_override = mat
	add_child(body)
	for x in [-0.8, 0.8]:
		for z in [-1.0, 1.0]:
			var w := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.35
			cyl.bottom_radius = 0.35
			cyl.height = 0.3
			w.mesh = cyl
			w.rotation_degrees.z = 90
			w.position = Vector3(x, 0.35, z)
			add_child(w)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 2.2, 5.5)
	add_child(_cam)
	_cam.current = false

func set_planet_provider(p: Node) -> void:
	_provider = p

func board(actor: Node3D) -> void:
	pilot = actor
	if actor:
		actor.visible = false
		if actor is CollisionObject3D:
			(actor as CollisionObject3D).collision_layer = 0
	if _cam:
		_cam.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func unboard() -> Node3D:
	var a := pilot
	pilot = null
	if _cam:
		_cam.current = false
	if a and is_instance_valid(a):
		a.visible = true
		a.global_position = global_position + _up * 1.5 + global_transform.basis.x * 2.0
		if a is CollisionObject3D:
			(a as CollisionObject3D).collision_layer = 2
	return a

func as_storage_entry() -> Dictionary:
	return {
		"id": str(get_instance_id()),
		"class_id": class_id,
		"volume": volume_m3,
		"mass": mass_t,
		"health": 100.0,
	}

func _physics_process(delta: float) -> void:
	if pilot == null or not is_instance_valid(pilot):
		velocity = velocity.lerp(Vector3.ZERO, 4.0 * delta)
		move_and_slide()
		return
	if _provider and _provider.has_method("gravity_at"):
		var g: Vector3 = _provider.gravity_at(global_position)
		if g.length() > 0.2:
			_up = (-g).normalized()
	if Input.is_physical_key_pressed(KEY_A):
		_yaw += turn_speed * delta
	if Input.is_physical_key_pressed(KEY_D):
		_yaw -= turn_speed * delta
	var right := _up.cross(Vector3(0, 0, -1))
	if right.length_squared() < 0.01:
		right = _up.cross(Vector3.RIGHT)
	right = right.normalized()
	var fwd := right.cross(_up).normalized()
	var b := Basis(right, _up, -fwd)
	b = Basis(_up, _yaw) * b
	global_transform = Transform3D(b.orthonormalized(), global_position)
	var input_v := 0.0
	if Input.is_physical_key_pressed(KEY_W):
		input_v -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_v += 1.0
	var wish := (-global_transform.basis.z) * (-input_v) * speed
	velocity = wish + _up * velocity.dot(_up)
	if not is_on_floor():
		velocity += -_up * 12.0 * delta
	move_and_slide()
