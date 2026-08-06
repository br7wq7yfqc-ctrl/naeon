extends CharacterBody3D
const _AP = preload("res://scripts/assets/AssetPaths.gd")

## Semi-Newtonian space ship controller with modular hardpoints.

signal module_attached(module: ShipModule)
signal landed()
signal launched()

@export var base_thrust: float = 22.0
@export var base_torque: float = 2.8
@export var linear_damp_custom: float = 0.35
@export var angular_damp_custom: float = 2.0
@export var max_speed: float = 55.0
@export var mouse_sensitivity: float = 0.0025
@export var faction: String = "Cybernex"

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var hull_mesh: MeshInstance3D = $HullMesh
@onready var module_root: Node3D = $Modules
@onready var status_label: Label3D = $StatusLabel

var modules: Array[ShipModule] = []
var health: float = 120.0
var max_health: float = 120.0
var shields: float = 40.0
var max_shields: float = 40.0
var energy: float = 100.0
var max_energy: float = 100.0
var cargo: float = 0.0
var max_cargo: float = 20.0
var _pitch: float = 0.0
var _yaw: float = 0.0
var _fire_cd: float = 0.0
var is_landed: bool = false

func _ready() -> void:
	add_to_group("ship")
	# Default loadout
	attach_module(ShipModule.make_engine())
	attach_module(ShipModule.make_weapon())
	attach_module(ShipModule.make_shield())
	_recompute_stats()
	_apply_faction_skin()
	call_deferred("try_load_hull")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("[Ship] Ready modules=", modules.size())

func try_load_hull() -> void:
	var rel := "ships/ship_hull_scout/ship_hull_scout_cybernex_lod0.glb"
	if faction == "gROT":
		rel = "ships/ship_hull_scout/ship_hull_scout_grot_lod0.glb"
	var path := _asset_path(rel)
	if path == "" or not FileAccess.file_exists(path):
		print("[Ship] Hull asset not ready yet: ", rel)
		return
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return
	var root := doc.generate_scene(state)
	if root == null:
		return
	if hull_mesh:
		hull_mesh.visible = false
	add_child(root)
	root.name = "HullGLB"
	root.scale = Vector3.ONE * 1.2
	print("[Ship] Loaded hull ", path)

func _asset_path(rel: String) -> String:
	return _AP.resolve(rel)
	var home := OS.get_environment("HOME")
	if home != "":
		var c2 := home.path_join("Documents/naeon/assets").path_join(rel)
		if FileAccess.file_exists(c2):
			return c2
	return c

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		attach_module(ShipModule.make_cargo())
		return
	if is_landed:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-80), deg_to_rad(80))
		rotation.y = _yaw
		camera_pivot.rotation.x = _pitch
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)


func _ship_axis() -> Vector3:
	# x=strafe, y=lift, z=thrust (forward +)
	var thrust := 0.0
	var strafe := 0.0
	var lift := 0.0
	if InputMap.has_action("move_forward") and Input.is_action_pressed("move_forward"):
		thrust += 1.0
	if InputMap.has_action("move_back") and Input.is_action_pressed("move_back"):
		thrust -= 0.45
	if InputMap.has_action("move_left") and Input.is_action_pressed("move_left"):
		strafe -= 1.0
	if InputMap.has_action("move_right") and Input.is_action_pressed("move_right"):
		strafe += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W):
		thrust = max(thrust, 1.0)
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S):
		thrust = min(thrust, -0.45) if thrust <= 0.0 else thrust
		if not (InputMap.has_action("move_forward") and Input.is_action_pressed("move_forward")):
			thrust = -0.45 if thrust == 0.0 else thrust
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A):
		strafe = -1.0 if strafe == 0.0 else strafe
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D):
		strafe = 1.0 if strafe == 0.0 else strafe
	if (InputMap.has_action("jump") and Input.is_action_pressed("jump")) or Input.is_physical_key_pressed(KEY_SPACE):
		lift += 1.0
	if (InputMap.has_action("sprint") and Input.is_action_pressed("sprint")) or Input.is_physical_key_pressed(KEY_SHIFT):
		lift -= 1.0
	return Vector3(strafe, lift, thrust)

func _physics_process(delta: float) -> void:
	if is_landed:
		return
	_fire_cd = max(0.0, _fire_cd - delta)
	shields = min(max_shields, shields + 4.0 * delta)
	energy = min(max_energy, energy + 8.0 * delta)

	var axes: Vector3 = _ship_axis()
	var thrust_input: float = axes.z
	var strafe: float = axes.x
	var lift: float = axes.y

	var thrust: float = base_thrust + _module_thrust()
	var forward: Vector3 = -global_transform.basis.z
	var right: Vector3 = global_transform.basis.x
	var up: Vector3 = global_transform.basis.y
	var accel: Vector3 = forward * thrust_input * thrust \
		+ right * strafe * thrust * 0.55 \
		+ up * lift * thrust * 0.5
	velocity += accel * delta
	# Custom damping (semi-Newtonian)
	velocity = velocity.lerp(Vector3.ZERO, linear_damp_custom * delta)
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	move_and_slide()

	if Input.is_action_pressed("ability_1") and _fire_cd <= 0.0:
		_fire_weapon()
	if Input.is_action_just_pressed("ability_2"):
		_toggle_landing()
	if Input.is_action_just_pressed("ability_3"):
		# Quick attach demo module
		attach_module(ShipModule.make_extractor())
	if Input.is_physical_key_pressed(KEY_C) and modules.size() < 8:
		pass
		_recompute_stats()
	if status_label:
		status_label.text = "SHIP  SPD %d  SHD %d  E %d  MOD %d" % [
			int(velocity.length()), int(shields), int(energy), modules.size()
		]

func detach_module(index: int) -> void:
	if index < 0 or index >= modules.size():
		return
	var m: ShipModule = modules[index]
	modules.remove_at(index)
	_recompute_stats()
	print("[Ship] Detached ", m.display_name if m else str(index))
	if module_root:
		for c in module_root.get_children():
			c.queue_free()
		for mod in modules:
			_spawn_module_visual(mod)

func attach_module(module: ShipModule) -> void:
	if module == null:
		return
	modules.append(module)
	_spawn_module_visual(module)
	module_attached.emit(module)
	_recompute_stats()
	print("[Ship] Attached ", module.display_name)

func _module_thrust() -> float:
	var t: float = 0.0
	for m in modules:
		t += m.thrust
	return t

func _recompute_stats() -> void:
	max_shields = 40.0
	max_cargo = 20.0
	for m in modules:
		max_shields += m.shield_bonus
		max_cargo += m.cargo_bonus
	shields = min(shields, max_shields)

func _fire_weapon() -> void:
	var dps: float = 8.0
	for m in modules:
		dps += m.weapon_dps
	if energy < 4.0:
		return
	energy -= 4.0
	_fire_cd = 0.18
	var bolt := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	bolt.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.95, 1.0) if faction == "Cybernex" else Color(1.0, 0.2, 0.4)
	mat.emission_energy_multiplier = 3.0
	mat.albedo_color = mat.emission
	bolt.material_override = mat
	var dir: Vector3 = -global_transform.basis.z
	bolt.set_meta("direction", dir)
	bolt.set_meta("speed", 70.0)
	get_tree().current_scene.add_child(bolt)
	bolt.global_position = global_position - global_transform.basis.z * 2.0
	var runner := Node.new()
	runner.set_script(preload("res://scripts/abilities/ProjectileRunner.gd"))
	bolt.add_child(runner)

func _toggle_landing() -> void:
	if is_landed:
		is_landed = false
		launched.emit()
		print("[Ship] Launched")
	else:
		# Placeholder "land" → load TPS arena if present
		is_landed = true
		velocity = Vector3.ZERO
		landed.emit()
		print("[Ship] Landing sequence…")
		if ResourceLoader.exists("res://scenes/test/TestArena.tscn"):
			await get_tree().create_timer(0.6).timeout
			get_tree().change_scene_to_file("res://scenes/test/TestArena.tscn")

func _spawn_module_visual(module: ShipModule) -> void:
	if module_root == null:
		return
	# Hardpoint slots by type (local offsets relative to hull)
	var pos := Vector3.ZERO
	var rot_y: float = 0.0
	var scale_v: float = 0.4
	var rel := ""
	match module.module_type:
		ShipModule.ModuleType.ENGINE:
			pos = Vector3(0, 0, 1.25)
			rel = "ships/ship_module_engine/ship_module_engine_cybernex_lod1.glb"
			scale_v = 0.5
		ShipModule.ModuleType.WEAPON:
			pos = Vector3(0.75, 0.05, -0.35)
			rel = "ships/ship_module_weapon/ship_module_weapon_cybernex_lod1.glb"
			scale_v = 0.45
		ShipModule.ModuleType.SHIELD:
			pos = Vector3(-0.75, 0.15, 0.1)
			rel = "ships/shield_module/shield_module_cybernex_lod1.glb"
			scale_v = 0.4
		ShipModule.ModuleType.EXTRACTOR:
			pos = Vector3(0, -0.4, 0.15)
			rel = "colony/extractor_unit/extractor_unit_cybernex_lod1.glb"
			scale_v = 0.35
		_:
			pos = Vector3(randf_range(-0.4, 0.4), 0.35, 0)
	if faction == "gROT" and rel != "":
		rel = rel.replace("_cybernex_", "_grot_")
	if rel != "":
		var path: String = _asset_path(rel)
		if path != "" and FileAccess.file_exists(path):
			var doc := GLTFDocument.new()
			var state := GLTFState.new()
			if doc.append_from_file(path, state) == OK:
				var root := doc.generate_scene(state)
				if root:
					module_root.add_child(root)
					root.position = pos
					root.scale = Vector3.ONE * scale_v
					root.rotation.y = rot_y
					return
	var node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 0.25, 0.55)
	node.mesh = box
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.8, 1.0)
	mat.emission_energy_multiplier = 1.8
	node.material_override = mat
	node.position = pos
	module_root.add_child(node)


func _apply_faction_skin() -> void:
	if hull_mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.metallic = 0.7
	mat.roughness = 0.25
	mat.emission_enabled = true
	if faction == "gROT":
		mat.albedo_color = Color(0.25, 0.05, 0.1)
		mat.emission = Color(0.9, 0.1, 0.35)
	else:
		mat.albedo_color = Color(0.05, 0.12, 0.18)
		mat.emission = Color(0.15, 0.75, 1.0)
	mat.emission_energy_multiplier = 1.2
	hull_mesh.material_override = mat

func get_faction() -> String:
	return faction

func take_damage(amount: float) -> void:
	var rest: float = amount
	if shields > 0.0:
		var absorbed: float = min(shields, rest)
		shields -= absorbed
		rest -= absorbed
	health = max(0.0, health - rest)
