extends CharacterBody3D
class_name GroundVehicle
const _Facing = preload("res://scripts/player/SurfaceFacing.gd")
const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
const _Relief = preload("res://scripts/world/PlanetRelief.gd")
## Surface rover — radial gravity drive, nose = −Z, board/exit F.
## Knowledge may relabel. It never writes speed / HP.

@export var class_id: String = "rover"
@export var display_name: String = "Rover"
@export var speed: float = 14.0
@export var reverse_mult: float = 0.45
@export var turn_speed: float = 1.9
@export var accel: float = 18.0
@export var brake: float = 28.0
@export var volume_m3: float = 8.0
@export var mass_t: float = 2.0
@export var health: float = 100.0

var pilot: Node3D = null
var _provider: Node = null
var _up: Vector3 = Vector3.UP
var _ref_fwd: Vector3 = Vector3(0, 0, -1)
var _yaw: float = 0.0
var _cam: Camera3D
var _speed_along: float = 0.0
var _cam_pitch: float = -0.18
var _label: Label3D = null
var _cmd_throttle: float = 0.0
var _cmd_turn: float = 0.0
var _cmd_brake: bool = false
var _use_cmd: bool = false
var _pad_deck: Node3D = null
var _hangar_ramp: Node3D = null
var last_slope_ang: float = 0.0


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
	_ensure_label()


func set_planet_provider(p: Node) -> void:
	_provider = p
	align_to_surface()


func set_pad_deck(p: Node3D) -> void:
	## Stay on the unnamed pad deck — do not snap to PlanetRelief.
	_pad_deck = p


func set_hangar_ramp(r: Node3D) -> void:
	## Drive the IN-C plates hangar_bay → pad. Not a SITE_*.
	_hangar_ramp = r


func face_along(world_dir: Vector3) -> void:
	var d: Vector3 = world_dir - _up * world_dir.dot(_up)
	if d.length_squared() < 1e-6:
		return
	_ref_fwd = d.normalized()
	_yaw = 0.0
	_apply_basis()


func label_text() -> String:
	return _SoftK.rover_label()


func refresh_label() -> void:
	if _label == null:
		return
	_label.text = label_text()


func set_drive_command(throttle: float, turn: float, braking: bool = false) -> void:
	## Headless / playtest steer. Keyboard still wins when a pilot is aboard.
	_use_cmd = true
	_cmd_throttle = clampf(throttle, -1.0, 1.0)
	_cmd_turn = clampf(turn, -1.0, 1.0)
	_cmd_brake = braking


func clear_drive_command() -> void:
	_use_cmd = false
	_cmd_throttle = 0.0
	_cmd_turn = 0.0
	_cmd_brake = false


func align_to_surface() -> void:
	if _provider and _provider.has_method("gravity_at"):
		var g: Vector3 = _provider.gravity_at(global_position)
		if g.length() > 0.2:
			_up = (-g).normalized()
	up_direction = _up
	_apply_basis()


func snap_to_relief() -> bool:
	var pl: Node3D = _nearest_planet()
	if pl == null or not ("radius" in pl):
		return false
	var dir: Vector3 = (global_position - pl.global_position)
	if dir.length_squared() < 1e-6:
		return false
	dir = dir.normalized()
	var h: float = _visual_relief_metres(pl)
	global_position = pl.global_position + dir * (float(pl.radius) + h + 0.55)
	velocity = Vector3.ZERO
	_up = dir
	up_direction = _up
	_apply_basis()
	return true


func board(actor: Node3D) -> void:
	## Same hardened park as the ship seat: freeze the walker, do not free it.
	if actor == null or not is_instance_valid(actor):
		return
	if pilot != null and is_instance_valid(pilot):
		return
	pilot = actor
	actor.visible = false
	if actor is CollisionObject3D:
		(actor as CollisionObject3D).collision_layer = 0
		(actor as CollisionObject3D).collision_mask = 0
	if actor is CharacterBody3D:
		(actor as CharacterBody3D).velocity = Vector3.ZERO
	actor.set_process(false)
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
			(a as CollisionObject3D).collision_mask = 1 | 2
		if a is CharacterBody3D:
			(a as CharacterBody3D).velocity = Vector3.ZERO
		a.set_process(true)
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
		"health": health,
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

	if (pilot == null or not is_instance_valid(pilot)) and not _use_cmd:
		_speed_along = move_toward(_speed_along, 0.0, brake * delta)
		_apply_velocity(delta)
		_relief_floor_assist(delta)
		return

	# Turn only when moving a bit (tank-ish)
	var turn := 0.0
	if _use_cmd:
		turn = _cmd_turn
	else:
		if Input.is_physical_key_pressed(KEY_A):
			turn += 1.0
		if Input.is_physical_key_pressed(KEY_D):
			turn -= 1.0
	var turn_scale := clampf(absf(_speed_along) / maxf(speed * 0.35, 0.01), 0.25, 1.0)
	_yaw += turn * turn_speed * turn_scale * delta

	var grip := 1.0
	var slope_ang := 0.0
	if is_on_floor():
		# Radial up, not world +Y — otherwise flat ground pins grip at the floor.
		slope_ang = get_floor_angle(_up)
	if not _on_pad_plate() and not _on_ramp_span():
		var rel_s: float = _relief_slope_rad()
		if rel_s > slope_ang:
			slope_ang = rel_s
	last_slope_ang = slope_ang
	if slope_ang > 0.01:
		grip = clampf(1.0 - slope_ang / deg_to_rad(52.0), 0.38, 1.0)
		floor_snap_length = 0.55 if slope_ang > deg_to_rad(38.0) else 0.4
		floor_max_angle = deg_to_rad(68.0) if slope_ang > deg_to_rad(38.0) else deg_to_rad(55.0)
	var max_spd := speed * grip

	# Space = brake (rover envelope). Playtest uses set_drive_command(..., true).
	var braking := _cmd_brake if _use_cmd else Input.is_physical_key_pressed(KEY_SPACE)
	if braking:
		_speed_along = move_toward(_speed_along, 0.0, brake * 1.85 * delta)
	else:
		var throttle := 0.0
		if _use_cmd:
			throttle = _cmd_throttle
			if throttle < 0.0:
				throttle *= reverse_mult
		else:
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
	_relief_floor_assist(delta)


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


func _nearest_planet() -> Node3D:
	if _provider != null and is_instance_valid(_provider) and _provider.has_method("nearest_planet"):
		var n: Node3D = _provider.nearest_planet(global_position)
		if n != null:
			return n
	var tree := get_tree()
	if tree == null:
		return null
	var best: Node3D = null
	var best_d := 1.0e12
	for node in tree.get_nodes_in_group("planets"):
		if node is Node3D:
			var d: float = global_position.distance_to((node as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = node as Node3D
	return best


func _visual_relief_metres(pl: Node3D) -> float:
	if pl == null:
		return 0.0
	var h := 0.0
	if pl.has_method("relief_height_at"):
		h = float(pl.relief_height_at(global_position))
	return h


func _relief_slope_rad() -> float:
	var pl: Node3D = _nearest_planet()
	if pl == null:
		return 0.0
	var dir: Vector3 = global_position - pl.global_position
	if dir.length_squared() < 1e-8:
		return 0.0
	var pid: String = str(pl.get("planet_name")) if "planet_name" in pl else "Nex-Prime"
	var seed: int = int(pl.body_seed()) if pl.has_method("body_seed") else int(absi(pid.hash()) % 10000)
	return float(_Relief.slope_rad(dir.normalized(), seed, _Relief.profile_for_planet(pid)))


func _relief_floor_assist(delta: float) -> void:
	## Pad plate wins. Ramp only while on the IN-C span. Else dirt (OS-I).
	if _pad_deck != null and is_instance_valid(_pad_deck) and _on_pad_plate():
		_pad_floor_assist(delta)
		return
	if _hangar_ramp != null and is_instance_valid(_hangar_ramp) and _on_ramp_span():
		_ramp_floor_assist(delta)
		return
	if _pad_deck != null:
		_pad_deck = null
		_force_dirt_chunks()
	if _hangar_ramp != null:
		_hangar_ramp = null
	## OS-I: trimesh is the floor. Analytic lift only as a core-fall catch.
	var pl: Node3D = _nearest_planet()
	if pl == null or not ("radius" in pl):
		return
	var dir: Vector3 = (global_position - pl.global_position)
	if dir.length_squared() < 1e-6:
		return
	dir = dir.normalized()
	var target_r: float = float(pl.radius) + _visual_relief_metres(pl) + 0.55
	var cur_r: float = global_position.distance_to(pl.global_position)
	var err: float = target_r - cur_r
	if err > 3.0:
		global_position += dir * err
		velocity = Vector3.ZERO


func _on_pad_plate() -> bool:
	if _pad_deck == null or not is_instance_valid(_pad_deck):
		return false
	var up := _pad_up()
	var rel: Vector3 = global_position - _pad_deck.global_position
	var lat: float = (rel - up * rel.dot(up)).length()
	return lat <= 14.0


func _on_ramp_span() -> bool:
	if _hangar_ramp == null or not is_instance_valid(_hangar_ramp):
		return false
	if not _hangar_ramp.has_method("walk_mouth_global") or not _hangar_ramp.has_method("walk_foot_global"):
		return false
	var mouth: Vector3 = _hangar_ramp.walk_mouth_global()
	var foot: Vector3 = _hangar_ramp.walk_foot_global()
	var along: Vector3 = foot - mouth
	var span: float = along.length()
	if span < 0.2:
		return false
	var nalong: Vector3 = along / span
	var t: float = (global_position - mouth).dot(nalong) / span
	if t < -0.2 or t > 1.2:
		return false
	var closest: Vector3 = mouth + nalong * clampf((global_position - mouth).dot(nalong), 0.0, span)
	return global_position.distance_to(closest) <= 4.0


func _force_dirt_chunks() -> void:
	var pl: Node3D = _nearest_planet()
	if pl == null:
		return
	if pl.has_method("force_surface_collision_at"):
		pl.force_surface_collision_at(global_position)


func _ramp_floor_assist(delta: float) -> void:
	var mouth: Vector3 = _hangar_ramp.walk_mouth_global() if _hangar_ramp.has_method("walk_mouth_global") else global_position
	var foot: Vector3 = _hangar_ramp.walk_foot_global() if _hangar_ramp.has_method("walk_foot_global") else mouth
	var along: Vector3 = foot - mouth
	var span: float = maxf(along.length(), 0.01)
	var nalong: Vector3 = along / span
	var t: float = (global_position - mouth).dot(nalong) / span
	var path: Vector3
	if t <= 1.02:
		path = mouth.lerp(foot, clampf(t, 0.0, 1.0))
	elif _pad_deck != null and is_instance_valid(_pad_deck):
		path = _pad_deck.global_position + _pad_up() * 0.55
	else:
		path = foot
	var corr: Vector3 = path - global_position
	var vert: Vector3 = _up * corr.dot(_up)
	if vert.length() > 0.12:
		global_position += vert * clampf(delta * 8.0, 0.0, 1.0)


func _pad_floor_assist(delta: float) -> void:
	var up := _pad_up()
	var h: float = (global_position - _pad_deck.global_position).dot(up)
	if h < 0.35:
		global_position += up * (0.55 - h) * clampf(delta * 8.0, 0.0, 1.0)


func _pad_up() -> Vector3:
	if _pad_deck != null and _pad_deck.has_meta("pad_up"):
		var raw: Vector3 = _pad_deck.get_meta("pad_up")
		if raw.length_squared() > 0.01:
			return raw.normalized()
	return _up


func _ensure_label() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _label != null and is_instance_valid(_label):
		refresh_label()
		return
	_label = Label3D.new()
	_label.name = "RoverLabel"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 22
	_label.outline_size = 10
	_label.outline_modulate = Color(0, 0, 0, 0.9)
	_label.position = Vector3(0, 2.4, 0)
	_label.modulate = Color(0.55, 0.9, 0.75)
	add_child(_label)
	refresh_label()


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
