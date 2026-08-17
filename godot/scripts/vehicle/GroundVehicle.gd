extends CharacterBody3D
class_name GroundVehicle
const _Facing = preload("res://scripts/player/SurfaceFacing.gd")
## Surface rover — radial gravity drive, nose = −Z, board/exit F.

@export var class_id: String = "rover"
@export var display_name: String = "Rover"
@export var speed: float = 14.0
@export var reverse_mult: float = 0.45
@export var turn_speed: float = 1.9
@export var accel: float = 18.0
@export var brake: float = 28.0
@export var volume_m3: float = 8.0
@export var mass_t: float = 2.0

var pilot: Node3D = null
var _provider: Node = null
var _up: Vector3 = Vector3.UP
var _ref_fwd: Vector3 = Vector3(0, 0, -1)
var _yaw: float = 0.0
var _cam: Camera3D
var _speed_along: float = 0.0
var _cam_pitch: float = -0.18


func _ready() -> void:
	add_to_group("ground_vehicle")
	collision_layer = 2
	collision_mask = 1
	motion_mode = MOTION_MODE_GROUNDED
	floor_snap_length = 0.4
	_build_proxy()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.0, 3.4)
	col.shape = box
	col.position.y = 0.5
	add_child(col)


func _build_proxy() -> void:
	if DisplayServer.get_name() == "headless":
		_cam = Camera3D.new()
		_cam.position = Vector3(0, 2.2, 5.5)
		_cam.look_at_from_position(_cam.position, Vector3(0, 1.0, 0), Vector3.UP)
		add_child(_cam)
		_cam.current = false
		return
	if _try_load_chassis():
		pass
	else:
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
	_cam.look_at_from_position(_cam.position, Vector3(0, 1.0, 0), Vector3.UP)
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
		# Park the walker: otherwise WASD drives the rover AND walks the hidden
		# body away, Space jumps it, and its abilities still fire.
		if actor is CharacterBody3D:
			(actor as CharacterBody3D).velocity = Vector3.ZERO
		actor.set_physics_process(false)
		actor.set_process_input(false)
		actor.set_process_unhandled_input(false)
	if _cam:
		_cam.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process_unhandled_input(true)


func unboard() -> Node3D:
	var a := pilot
	pilot = null
	_speed_along = 0.0
	set_process_unhandled_input(false)
	if a and is_instance_valid(a):
		a.visible = true
		a.global_position = global_position + _up * 1.6 + global_transform.basis.x * 2.2
		if a is CollisionObject3D:
			(a as CollisionObject3D).collision_layer = 2
		if a is CharacterBody3D:
			(a as CharacterBody3D).velocity = Vector3.ZERO
		a.set_physics_process(true)
		a.set_process_input(true)
		a.set_process_unhandled_input(true)
		# Hand the view back explicitly — clearing _cam.current promotes a random camera.
		var pc := a.get_node_or_null("CamPivot/Camera3D") as Camera3D
		if pc == null:
			pc = a.get_node_or_null("CameraPivot/Camera3D") as Camera3D
		if pc:
			pc.current = true
		elif _cam:
			_cam.current = false
	elif _cam:
		_cam.current = false
	return a


func as_storage_entry() -> Dictionary:
	return {
		"id": str(get_instance_id()),
		"class_id": class_id,
		"volume": volume_m3,
		"mass": mass_t,
		"health": 100.0,
	}


func _unhandled_input(event: InputEvent) -> void:
	if pilot == null or not is_instance_valid(pilot):
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * 0.0022
		_cam_pitch = clampf(_cam_pitch - event.relative.y * 0.0020, deg_to_rad(-28.0), deg_to_rad(10.0))
		if _cam:
			_cam.rotation.x = _cam_pitch
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	# Radial up
	if _provider and _provider.has_method("gravity_at"):
		var g: Vector3 = _provider.gravity_at(global_position)
		if g.length() > 0.2:
			_up = (-g).normalized()
	up_direction = _up

	if pilot == null or not is_instance_valid(pilot):
		_speed_along = move_toward(_speed_along, 0.0, brake * delta)
		_apply_velocity(delta)
		return

	# Turn only when moving a bit (tank-ish)
	var turn := 0.0
	if Input.is_physical_key_pressed(KEY_A):
		turn += 1.0
	if Input.is_physical_key_pressed(KEY_D):
		turn -= 1.0
	var turn_scale := clampf(absf(_speed_along) / maxf(speed * 0.35, 0.01), 0.25, 1.0)
	_yaw += turn * turn_speed * turn_scale * delta

	var grip := 1.0
	if is_on_floor():
		# Radial up, not world +Y — otherwise flat ground pins grip at the floor.
		grip = clampf(1.0 - get_floor_angle(_up) / deg_to_rad(52.0), 0.38, 1.0)
	var max_spd := speed * grip

	# Space = brake (rover envelope)
	if Input.is_physical_key_pressed(KEY_SPACE):
		_speed_along = move_toward(_speed_along, 0.0, brake * 1.85 * delta)
	else:
		var throttle := 0.0
		if Input.is_physical_key_pressed(KEY_W):
			throttle += 1.0
		if Input.is_physical_key_pressed(KEY_S):
			throttle -= reverse_mult
		var target := throttle * max_spd
		if absf(throttle) > 0.01:
			_speed_along = move_toward(_speed_along, target, accel * grip * delta)
		else:
			_speed_along = move_toward(_speed_along, 0.0, brake * 0.55 * delta)

	_apply_basis()
	_apply_velocity(delta)


func _apply_basis() -> void:
	# Transported reference instead of a world axis: switching the seed axis
	# snapped the chassis — and therefore the drive direction — 90 degrees.
	_ref_fwd = _Facing.transport_ref(_up, _ref_fwd)
	var b := _Facing.basis_from_up_ref(_up, _yaw, _ref_fwd)
	global_transform = Transform3D(b.orthonormalized(), global_position)


func _apply_velocity(delta: float) -> void:
	_apply_basis()
	var forward := -global_transform.basis.z
	# Project to tangent
	forward = (forward - _up * forward.dot(_up)).normalized()
	var planar := forward * _speed_along
	var v_up := velocity.dot(_up)
	var g_mag := 14.0
	if _provider and _provider.has_method("gravity_at"):
		var gv: Vector3 = _provider.gravity_at(global_position)
		if gv.length() > 0.2:
			g_mag = clampf(gv.length(), 6.0, 22.0)
	if not is_on_floor():
		v_up -= g_mag * delta
	else:
		v_up = minf(v_up, -0.5)
	velocity = planar + _up * v_up
	move_and_slide()



func _try_load_chassis() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	var AP = load("res://scripts/assets/AssetPaths.gd")
	var fac := "cybernex"
	if pilot and pilot.has_method("get_faction"):
		var f := str(pilot.get_faction()).to_lower()
		if f == "grot":
			fac = "grot"
	elif GameManager:
		var g := str(GameManager.get_faction_name()).to_lower()
		if g == "grot":
			fac = "grot"
	var rel := "vehicles/ground_rover_chassis/ground_rover_chassis_%s_lod1.glb" % fac
	var path := ""
	if AP and AP.has_method("resolve"):
		path = str(AP.resolve(rel))
	if path == "" or not FileAccess.file_exists(path):
		return false
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(path, st) != OK:
		return false
	var scn := doc.generate_scene(st)
	if scn == null:
		return false
	add_child(scn)
	scn.name = "ChassisGLB"
	scn.scale = Vector3.ONE * 1.35
	scn.position = Vector3(0, 0.35, 0)
	var MO = load("res://scripts/assets/MeshOrient.gd")
	if MO and MO.has_method("face_neg_z"):
		MO.face_neg_z(scn as Node3D, true)
	print("[Rover] chassis ", path)
	return true
