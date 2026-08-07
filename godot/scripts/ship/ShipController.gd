extends CharacterBody3D
const _MeshOrient = preload("res://scripts/assets/MeshOrient.gd")
const _AP = preload("res://scripts/assets/AssetPaths.gd")

## Semi-Newtonian ship with SCM / NAV / HOVER modes + seamless landing (no scene swap).

signal module_attached(module: ShipModule)
signal landed()
signal launched()
signal flight_mode_changed(mode: int)

enum FlightMode { SCM, NAV, HOVER }

@export var base_thrust: float = 22.0
@export var base_torque: float = 2.8
@export var linear_damp_custom: float = 0.35
@export var angular_damp_custom: float = 2.0
@export var max_speed_scm: float = 55.0
@export var max_speed_nav: float = 180.0
@export var max_speed_hover: float = 22.0
@export var mouse_sensitivity: float = 0.0025
@export var faction: String = "Cybernex"
@export var land_pad_snap_distance: float = 55.0
@export var surface_land_alt: float = 35.0

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
var _roll: float = 0.0
var _fire_cd: float = 0.0
var is_landed: bool = false
var flight_mode: int = FlightMode.SCM
var pilot_active: bool = true
var _open_space: Node = null
var _landed_pad: Node3D = null
var _landing_gear: Node3D = null
var _thruster_fx: GPUParticles3D = null
var _engine_pulse_t: float = 0.0

func _ready() -> void:
	add_to_group("ship")
	attach_module(ShipModule.make_engine())
	attach_module(ShipModule.make_weapon())
	attach_module(ShipModule.make_shield())
	_recompute_stats()
	_apply_faction_skin()
	call_deferred("try_load_hull")
	call_deferred("_ensure_landing_gear")
	call_deferred("_ensure_thruster_fx")
	if pilot_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("[Ship] Ready modules=", modules.size())

func set_open_space_context(ctx: Node) -> void:
	_open_space = ctx

func set_pilot_active(active: bool) -> void:
	pilot_active = active
	if camera and is_instance_valid(camera):
		camera.current = active
	if active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		# Keep ship frozen while on foot
		velocity = Vector3.ZERO

func flight_mode_name() -> String:
	match flight_mode:
		FlightMode.SCM: return "SCM"
		FlightMode.NAV: return "NAV"
		FlightMode.HOVER: return "HOVER"
	return "?"

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
	_MeshOrient.face_neg_z(root as Node3D, true)
	print("[Ship] Loaded hull ", path)

func _asset_path(rel: String) -> String:
	return _AP.resolve(rel)

func _input(event: InputEvent) -> void:
	if not pilot_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			if is_landed:
				_claim_nearby_pad()
			else:
				attach_module(ShipModule.make_cargo())
			return
		if event.keycode == KEY_1:
			_set_mode(FlightMode.SCM)
		elif event.keycode == KEY_2:
			_set_mode(FlightMode.NAV)
		elif event.keycode == KEY_3:
			_set_mode(FlightMode.HOVER)
	if is_landed:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity  # mouse right → look right (RH basis)
		_pitch -= event.relative.y * mouse_sensitivity
		# Full 3D flight plane: ship body pitches + yaws (not camera-only)
		_pitch = clamp(_pitch, deg_to_rad(-89), deg_to_rad(89))
		_apply_attitude()
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

func _set_mode(m: int) -> void:
	flight_mode = m
	flight_mode_changed.emit(m)
	print("[Ship] Flight mode ", flight_mode_name())

func _max_speed() -> float:
	match flight_mode:
		FlightMode.NAV: return max_speed_nav
		FlightMode.HOVER: return max_speed_hover
		_: return max_speed_scm

func _thrust_mult() -> float:
	match flight_mode:
		FlightMode.NAV: return 1.55
		FlightMode.HOVER: return 0.55
		_: return 1.0

func _damp_mult() -> float:
	match flight_mode:
		FlightMode.NAV: return 0.45
		FlightMode.HOVER: return 2.4
		_: return 1.0

func _ship_axis() -> Vector3:
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
		if not (InputMap.has_action("move_forward") and Input.is_action_pressed("move_forward")) \
			and not (Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W)):
			thrust = -0.45
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A):
		strafe = -1.0 if strafe == 0.0 else strafe
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D):
		strafe = 1.0 if strafe == 0.0 else strafe
	if (InputMap.has_action("jump") and Input.is_action_pressed("jump")) or Input.is_physical_key_pressed(KEY_SPACE):
		lift += 1.0
	if (InputMap.has_action("sprint") and Input.is_action_pressed("sprint")) or Input.is_physical_key_pressed(KEY_SHIFT):
		lift -= 1.0
	return Vector3(strafe, lift, thrust)


func _apply_attitude() -> void:
	# Right-handed free-flight attitude: yaw around ref-up, pitch around local right, roll around nose.
	# Must keep det(+1). Old up.cross(f0) flipped the X axis → ship flew "sideways" + inverted mouse.
	var up_ref := _reference_up()
	# Level forward from yaw (Godot nose = −Z)
	var yaw_b := Basis(up_ref, _yaw)
	var level_fwd: Vector3 = yaw_b * Vector3(0, 0, -1)
	level_fwd = (level_fwd - up_ref * level_fwd.dot(up_ref))
	if level_fwd.length_squared() < 1e-8:
		level_fwd = yaw_b * Vector3(1, 0, 0)
		level_fwd = (level_fwd - up_ref * level_fwd.dot(up_ref))
	level_fwd = level_fwd.normalized()
	# forward × up = right
	var right: Vector3 = level_fwd.cross(up_ref).normalized()
	var up1: Vector3 = up_ref.normalized()
	# Pitch around right
	var pitched_fwd: Vector3 = level_fwd.rotated(right, _pitch)
	var pitched_up: Vector3 = up1.rotated(right, _pitch)
	# Re-orthonormalize
	right = pitched_fwd.cross(pitched_up).normalized()
	pitched_up = right.cross(pitched_fwd).normalized()
	# Roll around nose (forward)
	right = right.rotated(pitched_fwd, _roll)
	pitched_up = pitched_up.rotated(pitched_fwd, _roll)
	var b := Basis(right, pitched_up, -pitched_fwd)
	global_transform = Transform3D(b.orthonormalized(), global_position)
	if camera_pivot:
		camera_pivot.rotation = Vector3.ZERO

func _reference_up() -> Vector3:
	# Free space: world Y. Near planet/pad: blend to radial/pad up so landing feels natural
	var up := Vector3.UP
	if _open_space and _open_space.has_method("gravity_at"):
		var g: Vector3 = _open_space.gravity_at(global_position)
		if g.length() > 0.5:
			up = (-g).normalized()
	if _landed_pad and is_instance_valid(_landed_pad) and _landed_pad.has_meta("pad_up"):
		up = _landed_pad.get_meta("pad_up")
	return up.normalized()

func _update_roll_input(delta: float) -> void:
	var roll_in := 0.0
	if Input.is_physical_key_pressed(KEY_Z):
		roll_in += 1.0
	if Input.is_physical_key_pressed(KEY_X):
		roll_in -= 1.0
	if roll_in != 0.0:
		_roll = clampf(_roll + roll_in * 1.8 * delta, -deg_to_rad(80), deg_to_rad(80))
	else:
		# Auto-level roll gently in free flight
		_roll = lerpf(_roll, 0.0, 2.0 * delta)

func _physics_process(delta: float) -> void:
	if not pilot_active:
		velocity = Vector3.ZERO
		return
	if is_landed:
		velocity = Vector3.ZERO
		_update_status()
		return

	_update_roll_input(delta)
	_apply_attitude()

	_fire_cd = max(0.0, _fire_cd - delta)
	shields = min(max_shields, shields + 4.0 * delta)
	energy = min(max_energy, energy + 8.0 * delta)

	var axes: Vector3 = _ship_axis()
	var thrust: float = (base_thrust + _module_thrust()) * _thrust_mult()
	var forward: Vector3 = -global_transform.basis.z
	var right: Vector3 = global_transform.basis.x
	var up: Vector3 = global_transform.basis.y
	var accel: Vector3 = forward * axes.z * thrust \
		+ right * axes.x * thrust * 0.55 \
		+ up * axes.y * thrust * 0.5

	# Planetary gravity when near atmosphere (seamless continuum)
	if _open_space and _open_space.has_method("gravity_at"):
		var g: Vector3 = _open_space.gravity_at(global_position)
		if flight_mode == FlightMode.HOVER:
			# Counter gravity softly for hover pads
			accel -= g * 0.85
		elif flight_mode == FlightMode.SCM:
			accel += g * 0.35
		else:
			accel += g * 0.15

	velocity += accel * delta
	velocity = velocity.lerp(Vector3.ZERO, linear_damp_custom * _damp_mult() * delta)
	var ms := _max_speed()
	if velocity.length() > ms:
		velocity = velocity.normalized() * ms
	move_and_slide()
	_update_thruster_fx(axes, delta)
	if velocity.length() > 5.0 and SessionObjectives:
		SessionObjectives.on_moved()

	if Input.is_action_pressed("ability_1") and _fire_cd <= 0.0:
		_fire_weapon()
	if Input.is_action_just_pressed("ability_2"):
		_toggle_landing()
	if Input.is_action_just_pressed("ability_3"):
		attach_module(ShipModule.make_extractor())
	_recompute_stats()
	_update_status()

func _update_status() -> void:
	if status_label:
		status_label.text = "%s  SPD %d  SHD %d  E %d  %s" % [
			flight_mode_name(), int(velocity.length()), int(shields), int(energy),
			("LANDED" if is_landed else "FLIGHT")
		]

func _toggle_landing() -> void:
	if is_landed:
		_do_launch()
	else:
		_do_land()

func _do_land() -> void:
	# Prefer pad snap within range; else surface land if altitude low
	var pad: Node3D = null
	if _open_space and _open_space.has_method("nearest_pad"):
		pad = _open_space.nearest_pad(global_position)
	if pad and pad.global_position.distance_to(global_position) <= land_pad_snap_distance:
		_landed_pad = pad
		# Snap above pad
		var up: Vector3 = Vector3.UP
		if pad.has_meta("pad_up"):
			up = pad.get_meta("pad_up")
		global_position = pad.global_position + up * 4.0
		# Face roughly along pad
		velocity = Vector3.ZERO
		is_landed = true
	if AudioDirector:
		AudioDirector.play_land()
	if SessionObjectives:
		SessionObjectives.on_landed_or_lane()
		_sync_landing_gear()
		_spawn_land_fx()
		_set_mode(FlightMode.HOVER)
		# Align flight plane to pad surface
		_pitch = 0.0
		_roll = 0.0
		_apply_attitude()
		landed.emit()
		print("[Ship] Landed on pad ", pad.name)
		_claim_nearby_pad()
		return
	# Surface land near planet
	if _open_space and _open_space.has_method("nearest_planet"):
		var pl: Node3D = _open_space.nearest_planet(global_position)
		if pl and pl.has_method("altitude_of") and pl.altitude_of(global_position) < surface_land_alt:
			velocity = Vector3.ZERO
			is_landed = true
			_landed_pad = null
			_sync_landing_gear()
			_set_mode(FlightMode.HOVER)
			landed.emit()
			print("[Ship] Surface land near ", pl.get("planet_name"))
			_claim_nearby_pad()
			return
	print("[Ship] Land denied — approach a pad (<", land_pad_snap_distance, "m) or surface")

func _do_launch() -> void:
	is_landed = false
	_landed_pad = null
	_sync_landing_gear()
	if flight_mode == FlightMode.HOVER:
		_set_mode(FlightMode.SCM)
	# Boost off pad
	velocity = global_transform.basis.y * 12.0 - global_transform.basis.z * 8.0
	launched.emit()
	print("[Ship] Launched")

func detach_module(index: int) -> void:
	if index < 0 or index >= modules.size():
		return
	modules.remove_at(index)
	_recompute_stats()
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

	# Soft muzzle flash (presentation)
	var flash := OmniLight3D.new()
	flash.light_energy = 6.0
	flash.omni_range = 8.0
	flash.light_color = Color(0.5, 0.85, 1.0) if faction != "gROT" else Color(1.0, 0.3, 0.4)
	flash.position = Vector3(0, 0, -2.0)
	add_child(flash)
	get_tree().create_timer(0.07).timeout.connect(func():
		if is_instance_valid(flash):
			flash.queue_free()
	)
	if AudioDirector:
		AudioDirector.play_hit(false)
	if CombatJuice:
		CombatJuice.hit_feedback(2.0, global_position - global_transform.basis.z * 3.0)
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
	bolt.set_meta("speed", 90.0 if flight_mode == FlightMode.NAV else 70.0)
	var scene := get_tree().current_scene
	if scene:
		scene.add_child(bolt)
	else:
		get_parent().add_child(bolt)
	bolt.global_position = global_position - global_transform.basis.z * 2.0
	var runner := Node.new()
	runner.set_script(preload("res://scripts/abilities/ProjectileRunner.gd"))
	bolt.add_child(runner)

func _spawn_module_visual(module: ShipModule) -> void:
	if module_root == null:
		return
	var pos := Vector3.ZERO
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


func _claim_nearby_pad() -> void:
	var best: Node = null
	var best_d := 60.0
	for n in get_tree().get_nodes_in_group("pad_bases"):
		if n is Node3D:
			var d: float = global_position.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n
	if best and best.has_method("claim"):
		best.claim(faction, 1.25)
		print("[Ship] Pad claim pulse → ", faction)

func get_faction() -> String:
	return faction

func take_damage(amount: float) -> void:
	var rest: float = amount
	if shields > 0.0:
		var absorbed: float = min(shields, rest)
		shields -= absorbed
		rest -= absorbed
	health = max(0.0, health - rest)

func _spawn_land_fx() -> void:
	# Brief dust ring on pad touchdown
	var p := GPUParticles3D.new()
	p.amount = 40
	p.lifetime = 0.9
	p.one_shot = true
	p.explosiveness = 0.9
	p.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 80.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 6.0
	pm.gravity = Vector3(0, -4, 0)
	pm.scale_min = 0.08
	pm.scale_max = 0.25
	pm.color = Color(0.7, 0.75, 0.8, 0.8)
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.1
	sm.height = 0.2
	sm.radial_segments = 4
	sm.rings = 2
	p.draw_pass_1 = sm
	add_child(p)
	p.position = Vector3(0, 0.2, 0)
	var tree := get_tree()
	if tree:
		tree.create_timer(1.2).timeout.connect(p.queue_free)


func apply_faction_modules(faction: String) -> void:
	# Dual-theme fantasy names (CONCEPT asymmetry) — stats stay non-P2W fair
	modules.clear()
	if module_root:
		for c in module_root.get_children():
			c.queue_free()
	if faction == "gROT":
		attach_module(ShipModule.make_engine("Rot Thruster", 18.0))
		attach_module(ShipModule.make_weapon("Spore Lance", 14.0))
		attach_module(ShipModule.make_shield("Biomass Shell", 40.0))
	else:
		attach_module(ShipModule.make_engine("Ion Drive", 18.0))
		attach_module(ShipModule.make_weapon("Pulse Cannon", 14.0))
		attach_module(ShipModule.make_shield("Nex Barrier", 40.0))
	for m in modules:
		m.faction_skin = faction
	print("[Ship] faction modules → ", faction, " count=", modules.size())

func _unhandled_input(event: InputEvent) -> void:
	if not pilot_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F10 or event.physical_keycode == KEY_F10:
			if SoftENet:
				SoftENet.host()
				SoftENet.bind_player(self)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F11 or event.physical_keycode == KEY_F11:
			if SoftENet:
				var addr := "127.0.0.1"
				if FileAccess.file_exists("user://softnet_join.txt"):
					var f := FileAccess.open("user://softnet_join.txt", FileAccess.READ)
					if f:
						var line := f.get_line().strip_edges()
						if line != "":
							addr = line
				SoftENet.join(addr)
				SoftENet.bind_player(self)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F12 or event.physical_keycode == KEY_F12:
			if SoftENet:
				SoftENet.leave()
			get_viewport().set_input_as_handled()


func _ensure_landing_gear() -> void:
	if _landing_gear and is_instance_valid(_landing_gear):
		return
	_landing_gear = Node3D.new()
	_landing_gear.set_script(preload("res://scripts/ship/ShipLandingGear.gd"))
	add_child(_landing_gear)
	if _landing_gear.has_method("set_deployed"):
		_landing_gear.call("set_deployed", is_landed)


func _sync_landing_gear() -> void:
	if _landing_gear == null or not is_instance_valid(_landing_gear):
		_ensure_landing_gear()
	if _landing_gear and _landing_gear.has_method("set_deployed"):
		_landing_gear.call("set_deployed", is_landed)


func _ensure_thruster_fx() -> void:
	if _thruster_fx and is_instance_valid(_thruster_fx):
		return
	_thruster_fx = GPUParticles3D.new()
	_thruster_fx.name = "ThrusterFX"
	_thruster_fx.amount = 48
	_thruster_fx.lifetime = 0.35
	_thruster_fx.emitting = false
	_thruster_fx.position = Vector3(0, 0, 2.2)  # behind hull (+Z = aft if nose −Z)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, 1)
	pm.spread = 12.0
	pm.initial_velocity_min = 6.0
	pm.initial_velocity_max = 14.0
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.06
	pm.scale_max = 0.18
	pm.color = Color(0.35, 0.75, 1.0, 0.85)
	_thruster_fx.process_material = pm
	var dm := SphereMesh.new()
	dm.radius = 0.08
	dm.height = 0.16
	_thruster_fx.draw_pass_1 = dm
	add_child(_thruster_fx)


func _update_thruster_fx(axes: Vector3, delta: float) -> void:
	if _thruster_fx == null or not is_instance_valid(_thruster_fx):
		return
	var power: float = clampf(absf(axes.z) + absf(axes.x) * 0.4 + absf(axes.y) * 0.3, 0.0, 1.5)
	_thruster_fx.emitting = power > 0.08 and pilot_active and not is_landed
	if _thruster_fx.emitting:
		_thruster_fx.amount = int(32 + power * 40)
		var pm := _thruster_fx.process_material as ParticleProcessMaterial
		if pm:
			pm.initial_velocity_min = 5.0 + power * 8.0
			pm.initial_velocity_max = 10.0 + power * 16.0
			var fac_col := Color(0.95, 0.25, 0.4) if faction == "gROT" else Color(0.3, 0.8, 1.0)
			pm.color = fac_col
		_engine_pulse_t += delta
		if _engine_pulse_t > 0.35 and AudioDirector and power > 0.5:
			_engine_pulse_t = 0.0
			AudioDirector.play_engine_pulse()
