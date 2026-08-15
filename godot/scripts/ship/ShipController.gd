extends CharacterBody3D
const _MeshOrient = preload("res://scripts/assets/MeshOrient.gd")
const _Flight = preload("res://scripts/ship/ShipFlightModel.gd")
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
@export var land_pad_snap_distance: float = 90.0
@export var surface_land_alt: float = 120.0

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
var _land_lock_t: float = 0.0
var _land_hold_h: float = 3.5
var flight_mode: int = FlightMode.SCM
var pilot_active: bool = true
var _open_space: Node = null
var _landed_pad: Node3D = null
var _land_hint_cd: float = 0.0
var _hover_hold_alt: float = -1.0
var _stall: float = 0.0
var _stall_toast_t: float = 0.0
var _landing_gear: Node3D = null
var _thruster_fx: GPUParticles3D = null
var _cargo_hold: Node = null
var _cargo_ramp: Node3D = null
var _hull_morph: Node3D = null
var _role = null
var op_mode: int = 0
var _palette_accum: float = 0.0
var _scan_pulse_t: float = 0.0
var _scan_last_report: String = ""
var _deployed_rover: Node3D = null
var _engine_pulse_t: float = 0.0
var _hull_crit_t: float = 0.0
var _shield_hold_t: float = 0.0
var _burn_on: bool = false
var _hull_ambient: Node3D = null

const _SHIELD_REGEN := 4.0
const _SHIELD_HOLD := 2.4
const _HULL_CRIT_T := 1.8
const _HULL_CRIT_THRUST := 0.45
const _HULL_CRIT_ENERGY := 0.35
const _HULL_CRIT_HP := 0.35

func _ready() -> void:
	add_to_group("ship")
	_ensure_living_fx()
	_ensure_nose_marker()
	_ensure_shield_bubble()
	_ensure_scan_ring()
	_ensure_soft_systems()
	attach_module(ShipModule.make_engine())
	attach_module(ShipModule.make_weapon())
	attach_module(ShipModule.make_shield())
	_recompute_stats()
	_apply_faction_skin()
	call_deferred("try_load_hull")
	call_deferred("_ensure_landing_gear")
	call_deferred("_ensure_thruster_fx")
	call_deferred("_ensure_cargo_systems")
	call_deferred("_ensure_morph_and_hatch")
	call_deferred("_ensure_hull_ambient")
	_role = _load_role_sniper()
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
	# Headless dummy renderer cannot host glTF mesh RIDs (Parameter m is null flood)
	if DisplayServer.get_name() == "headless":
		print("[Ship] Hull GLB skipped (headless)")
		return
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
	# Align GLB nose to Godot −Z (thrust / camera forward)
	_MeshOrient.face_neg_z(root as Node3D, true)
	# Pick yaw maximizing length on Z (nose along −Z after MeshOrient)
	var best_y: float = root.rotation.y
	var best_len: float = -1.0
	for y in [0.0, PI * 0.5, PI, PI * 1.5]:
		root.rotation.y = y
		var sz: Vector3 = _hull_local_size(root)
		if sz.z > best_len:
			best_len = sz.z
			best_y = y
	root.rotation.y = best_y
	root.position = Vector3(0, 0.15, 0)
	if hull_mesh:
		hull_mesh.visible = false
	# Hide any leftover placeholder dark hull collision mesh
	var ph := get_node_or_null("HullMesh")
	if ph:
		ph.visible = false
	print("[Ship] Loaded hull ", path, " yaw=", rad_to_deg(best_y), " lenZ=", best_len)

func _asset_path(rel: String) -> String:
	return _AP.resolve(rel)

func _input(event: InputEvent) -> void:
	if not pilot_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
		if k == KEY_NONE:
			k = event.physical_keycode
		if k == KEY_C:
			if is_landed:
				_claim_nearby_pad()
			else:
				attach_module(ShipModule.make_cargo())
			return
		if k == KEY_1:
			_set_mode(FlightMode.SCM)
		elif k == KEY_2:
			_set_mode(FlightMode.NAV)
		elif k == KEY_3:
			_set_mode(FlightMode.HOVER)
		elif k == KEY_4:
			_toggle_siege()
		elif k == KEY_5:
			_toggle_cargo_ramp()
		elif k == KEY_6:
			_try_deploy_rover()
		elif k == KEY_8:
			_toggle_scan()
	if is_landed:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = mouse_sensitivity
		if flight_mode == FlightMode.NAV:
			sens *= 0.55
		elif flight_mode == FlightMode.HOVER:
			sens *= 0.85
		sens *= (1.0 - _atmo_now() * 0.42)
		if op_mode == 1 and _role:
			sens *= float(_role.siege_turn_mult)
		_yaw -= event.relative.x * sens
		_pitch -= event.relative.y * sens
		_pitch = clamp(_pitch, deg_to_rad(-89), deg_to_rad(89))
		_apply_attitude()
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

func _set_mode(m: int) -> void:
	if m == FlightMode.NAV and _atmo_now() > 0.45:
		_toast_ship("NAV locked in atmosphere — SCM / HOVER")
		m = FlightMode.SCM
	var prev: int = flight_mode
	flight_mode = m
	if m == FlightMode.HOVER:
		_hover_hold_alt = _altitude_now()
	elif prev == FlightMode.HOVER:
		_hover_hold_alt = -1.0
	flight_mode_changed.emit(m)
	print("[Ship] Flight mode ", flight_mode_name())

func _max_speed() -> float:
	var s: float = _Flight.max_speed(flight_mode, max_speed_scm, max_speed_nav, max_speed_hover)
	if _burn_on:
		s *= 1.18
	return s

func _thrust_mult() -> float:
	var m: float = _Flight.thrust_mult(flight_mode)
	if op_mode == 1 and _role:
		m *= float(_role.siege_thrust_mult)
	elif op_mode == 2:
		m *= 0.7
	if _hull_crit_t > 0.0:
		m *= _HULL_CRIT_THRUST
	if _burn_on:
		m *= 1.55
	return m

func _damp_mult() -> float:
	var m: float = _Flight.base_damp(flight_mode)
	if op_mode == 1:
		m *= 1.8
	elif op_mode == 2:
		m *= 1.25
	return m


func _atmo_now() -> float:
	if _open_space and _open_space.has_method("atmosphere_density_at"):
		return float(_open_space.atmosphere_density_at(global_position))
	return 0.0


func _altitude_now() -> float:
	if _open_space and _open_space.has_method("nearest_planet"):
		var pl: Node3D = _open_space.nearest_planet(global_position)
		if pl and pl.has_method("altitude_of"):
			return float(pl.altitude_of(global_position))
	return 0.0

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
	var shift := (InputMap.has_action("sprint") and Input.is_action_pressed("sprint")) or Input.is_physical_key_pressed(KEY_SHIFT)
	if shift:
		if thrust > 0.55 and not is_landed:
			pass
		else:
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
		# Gentle auto-level + slight bank from A/D for readable turn feel
		var bank_t := 0.0
		if Input.is_physical_key_pressed(KEY_A):
			bank_t += 0.35
		if Input.is_physical_key_pressed(KEY_D):
			bank_t -= 0.35
		_roll = lerpf(_roll, bank_t, 2.4 * delta)

func _physics_process(delta: float) -> void:
	_palette_accum += delta
	if _palette_accum > 1.5:
		_palette_accum = 0.0
		_sync_planet_palette()
	_tick_scan_pulse(delta)
	if not pilot_active:
		# Soft coast while EVA (was hard-stop → awkward relative reboard)
		velocity = velocity.lerp(Vector3.ZERO, clampf(0.55 * delta, 0.0, 0.35))
		if velocity.length() < 0.15:
			velocity = Vector3.ZERO
		# Still stick if landed
		if is_landed:
			velocity = Vector3.ZERO
			_stick_to_pad()
		return
	if is_landed:
		_burn_on = false
		# Sticky pad: kill ALL motion, no thruster integrate, short launch lock
		_land_lock_t = maxf(0.0, _land_lock_t - delta)
		velocity = Vector3.ZERO
		_stick_to_pad()
		if _thruster_fx and is_instance_valid(_thruster_fx):
			_thruster_fx.emitting = false
		# Ignore accidental launch for lock window (prevents "lift on land")
		if _land_lock_t <= 0.0 and Input.is_action_just_pressed("ability_2"):
			_do_launch()
		_tick_combat(delta)
		_update_status()
		return

	_update_roll_input(delta)
	_apply_attitude()

	var axes: Vector3 = _ship_axis()
	var want_burn := (not is_landed) and axes.z > 0.55 and (
		Input.is_physical_key_pressed(KEY_SHIFT)
		or (InputMap.has_action("sprint") and Input.is_action_pressed("sprint"))
	)
	_tick_afterburn(delta, want_burn)
	var thrust: float = (base_thrust + _module_thrust()) * _thrust_mult()
	var forward: Vector3 = -global_transform.basis.z
	var right: Vector3 = global_transform.basis.x
	var up: Vector3 = global_transform.basis.y
	# Strafe weaker than main; lift medium — readable flight envelope
	var accel: Vector3 = forward * axes.z * thrust \
		+ right * axes.x * thrust * 0.5 \
		+ up * axes.y * thrust * 0.55

	var atmo := 0.0
	var g := Vector3.ZERO
	if _open_space:
		if _open_space.has_method("atmosphere_density_at"):
			atmo = float(_open_space.atmosphere_density_at(global_position))
		if _open_space.has_method("gravity_at"):
			g = _open_space.gravity_at(global_position)

	# Gravity by mode (g toward planet)
	if g.length() > 0.01:
		if flight_mode == FlightMode.NAV and atmo > 0.5:
			_set_mode(FlightMode.SCM)
		if flight_mode == FlightMode.HOVER:
			var hh: Array = _Flight.hover_hold(velocity, g, accel, delta, 1.0)
			accel = hh[0]
			velocity = hh[1]
			# Vertical stick trims hold altitude; PD holds it
			if _hover_hold_alt < 0.0:
				_hover_hold_alt = _altitude_now()
			if absf(axes.y) > 0.12:
				_hover_hold_alt = maxf(4.0, _hover_hold_alt + axes.y * 22.0 * delta)
			# Strip raw lift so HOVER is an altitude hold, not a second SCM
			var lift_axis: Vector3 = global_transform.basis.y
			accel -= lift_axis * accel.dot(lift_axis)
			var v_up: float = velocity.dot((-g).normalized())
			accel += _Flight.hover_alt_accel(g, _altitude_now(), _hover_hold_alt, v_up)
			var pad_d := 999.0
			if _open_space and _open_space.has_method("nearest_pad"):
				var hpad: Node3D = _open_space.nearest_pad(global_position)
				if hpad and is_instance_valid(hpad):
					pad_d = hpad.global_position.distance_to(global_position)
					if pad_d < 52.0 and _open_space.has_method("nearest_planet"):
						var plp: Node3D = _open_space.nearest_planet(hpad.global_position)
						if plp and plp.has_method("altitude_of"):
							var deck: float = float(plp.altitude_of(hpad.global_position)) + 8.0
							if _hover_hold_alt < deck:
								_hover_hold_alt = move_toward(_hover_hold_alt, deck, delta * 10.0)
			accel += _Flight.ground_effect_accel(g, _altitude_now(), pad_d, v_up)
		elif flight_mode == FlightMode.SCM:
			# Partial gravity in atmo; almost free in vacuum
			accel += g * lerpf(0.08, 0.45, atmo)
		else:
			# NAV: light gravity bias only near surface
			accel += g * lerpf(0.02, 0.2, atmo)

	_stall = _Flight.stall_amount(atmo, velocity.length(), _Flight.stall_speed(flight_mode))
	if _stall > 0.01 and g.length() > 0.01:
		accel += _Flight.stall_sink_accel(g, _stall)
		# Wash out lateral authority when the wing is stalled
		if _stall > 0.35:
			var fwd: Vector3 = -global_transform.basis.z
			var along: float = accel.dot(fwd)
			accel = accel.lerp(fwd * along + g * _stall, clampf(_stall, 0.0, 0.85))
		if flight_mode == FlightMode.NAV and _stall > 0.55:
			_set_mode(FlightMode.SCM)
			_toast_ship("STALL — dropped to SCM")
		_stall_toast_t -= delta
		if _stall > 0.4 and _stall_toast_t <= 0.0:
			_stall_toast_t = 2.4
			_toast_ship("STALL %.0f%% — add speed or HOVER" % (_stall * 100.0))
	else:
		_stall_toast_t = maxf(0.0, _stall_toast_t - delta)

	# Soft pad approach brake (assist, not autopilot)
	if _open_space and _open_space.has_method("nearest_pad"):
		var pad: Node3D = _open_space.nearest_pad(global_position)
		if pad and is_instance_valid(pad):
			var dpad: float = pad.global_position.distance_to(global_position)
			velocity = _Flight.approach_assist(velocity, pad.global_position - global_position, dpad, land_pad_snap_distance)

	velocity = _Flight.integrate(velocity, accel, delta, linear_damp_custom, _damp_mult(), atmo, _max_speed())

	# CharacterBody free-flight — do not stick to floors mid-air
	floor_stop_on_slope = false
	floor_block_on_wall = false
	move_and_slide()
	_update_thruster_fx(axes, delta)
	_tick_hull_ambient(axes, delta)
	if velocity.length() > 5.0 and SessionObjectives:
		SessionObjectives.on_moved()

	_tick_combat(delta)
	if Input.is_action_just_pressed("ability_2"):
		_toggle_landing()
	_auto_land_assist(delta)
	if Input.is_action_just_pressed("ability_3"):
		attach_module(ShipModule.make_extractor())
	_recompute_stats()
	_update_status()

func _update_status() -> void:
	if status_label:
		var opn := "SIEGE" if op_mode == 1 else ("SCAN" if op_mode == 2 else "CRUISE")
		status_label.text = "%s  OP:%s  SPD %d  SHD %d  E %d  %s%s%s%s" % [
			flight_mode_name(), opn, int(velocity.length()), int(shields), int(energy),
			("LANDED" if is_landed else "FLIGHT"),
			("  STALL" if _stall > 0.35 else ""),
			("  HULL CRIT" if _hull_crit_t > 0.0 else ""),
			("  BURN" if _burn_on else ""),
		]

func _toggle_landing() -> void:
	if is_landed:
		_do_launch()
	else:
		_do_land()

func _do_land() -> void:
	## Honest speed/sink gate. No secret 0.35 brake. Claim is C after touchdown.
	var spd := velocity.length()
	var v_rad := 0.0
	if _open_space and _open_space.has_method("gravity_at"):
		var gg: Vector3 = _open_space.gravity_at(global_position)
		if gg.length() > 0.01:
			v_rad = velocity.dot(gg.normalized())
	var max_spd := 18.0
	var max_sink := 12.0
	if flight_mode == FlightMode.HOVER:
		max_spd = 24.0
		max_sink = 16.0
	elif flight_mode == FlightMode.NAV:
		max_spd = 12.0
		max_sink = 8.0
	if not _Flight.land_ok(spd, v_rad, max_spd, max_sink):
		_toast_ship("Land denied — spd %d sink %d  (3 HOVER, slow)" % [int(spd), int(v_rad)])
		print("[Ship] Land denied spd=", int(spd), " sink=", int(v_rad), " mode=", flight_mode_name())
		return
	var pad: Node3D = null
	if _open_space and _open_space.has_method("nearest_pad"):
		pad = _open_space.nearest_pad(global_position)
	if pad and is_instance_valid(pad) and pad.global_position.distance_to(global_position) <= land_pad_snap_distance:
		_commit_land(pad)
		return
	if _open_space and _open_space.has_method("nearest_planet"):
		var pl: Node3D = _open_space.nearest_planet(global_position)
		if pl and pl.has_method("altitude_of") and float(pl.altitude_of(global_position)) < surface_land_alt:
			_commit_land(null)
			print("[Ship] Surface land near ", pl.get("planet_name"))
			return
	_toast_ship("Approach a pad (<%dm) or low surface" % int(land_pad_snap_distance))
	print("[Ship] Land denied — no pad/surface in envelope")


func _commit_land(pad: Node3D) -> void:
	velocity = Vector3.ZERO
	is_landed = true
	_land_lock_t = 1.25
	_landed_pad = pad
	if pad:
		var up: Vector3 = Vector3.UP
		if pad.has_meta("pad_up"):
			up = pad.get_meta("pad_up")
		global_position = pad.global_position + up * 4.0
	if _thruster_fx and is_instance_valid(_thruster_fx):
		_thruster_fx.emitting = false
	if AudioDirector:
		AudioDirector.play_land()
	if SessionObjectives:
		SessionObjectives.on_landed_or_lane()
	_sync_landing_gear()
	_spawn_land_fx()
	_set_mode(FlightMode.HOVER)
	_pitch = 0.0
	_roll = 0.0
	_apply_attitude()
	landed.emit()
	if pad:
		print("[Ship] Landed on pad ", pad.name)
		_toast_ship("Landed — C to claim (soft ownership, no combat power)")
	else:
		_toast_ship("Surface land — C near a pad to claim")

func _do_launch() -> void:
	if not is_landed:
		return
	if _land_lock_t > 0.0:
		print("[Ship] Launch lock ", "%.2f" % _land_lock_t, "s")
		_toast_ship("Launch lock %.1fs" % _land_lock_t)
		return
	var up_boost: Vector3 = _reference_up()
	var nose: Vector3 = -global_transform.basis.z
	is_landed = false
	_landed_pad = null
	_sync_landing_gear()
	if flight_mode == FlightMode.HOVER:
		_set_mode(FlightMode.SCM)
	# Gentle lift — user then applies thrust (no sky rocket)
	velocity = up_boost * 3.5 + nose * 1.5
	launched.emit()
	print("[Ship] Launched")
	_toast_ship("Launched")

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

func _tick_afterburn(delta: float, want: bool) -> void:
	_burn_on = false
	if not want or is_landed or _hull_crit_t > 0.0:
		return
	var cost: float = 16.0 * delta
	if energy < cost:
		return
	energy -= cost
	_burn_on = true

func _tick_combat(delta: float) -> void:
	_fire_cd = max(0.0, _fire_cd - delta)
	if _hull_crit_t > 0.0:
		_hull_crit_t = maxf(0.0, _hull_crit_t - delta)
	if _shield_hold_t > 0.0:
		_shield_hold_t = maxf(0.0, _shield_hold_t - delta)
	if _hull_crit_t <= 0.0 and _shield_hold_t <= 0.0:
		shields = min(max_shields, shields + _SHIELD_REGEN * delta)
	var e_rate: float = 8.0
	if _hull_crit_t > 0.0:
		e_rate *= _HULL_CRIT_ENERGY
	energy = min(max_energy, energy + e_rate * delta)
	if Input.is_action_pressed("ability_1") and _fire_cd <= 0.0:
		_fire_weapon()


func _fire_weapon() -> void:
	var e_cost: float = 5.0
	var EE = load("res://scripts/systems/EnergyEconomy.gd")
	if EE:
		e_cost = float(EE.ship_bolt_cost(int(flight_mode), op_mode))
	else:
		e_cost = 5.5 if flight_mode == FlightMode.NAV else 5.0
		if op_mode == 1:
			e_cost *= 1.35
	if energy < e_cost:
		if AudioDirector and AudioDirector.has_method("play_ui_deny"):
			AudioDirector.play_ui_deny()
		return
	energy -= e_cost
	_fire_cd = 0.22 if op_mode == 1 else (0.14 if flight_mode == FlightMode.NAV else 0.18)
	var dps: float = 8.0
	for m in modules:
		dps += m.weapon_dps
	if op_mode == 1 and _role:
		dps *= float(_role.siege_dps_mult) if "siege_dps_mult" in _role else 1.35
	var dir: Vector3 = -global_transform.basis.z
	var origin: Vector3 = global_position + dir * 2.2
	var Hits = load("res://scripts/combat/CombatHits.gd")
	if Hits:
		var aim: Array = Hits.aim_from(self)
		origin = aim[0]
		dir = aim[1]
	var spd: float = 95.0 if flight_mode == FlightMode.NAV else (55.0 if flight_mode == FlightMode.HOVER else 72.0)
	var life: float = 1.6 if flight_mode == FlightMode.NAV else 1.25
	var col := Color(0.3, 0.95, 1.0) if faction == "Cybernex" else Color(1.0, 0.2, 0.4)
	var _Pool = load("res://scripts/combat/ProjectilePool.gd")
	if _Pool:
		_Pool.spawn(get_tree(), origin, dir, spd, dps * 0.55, str(faction), col, life, [self])
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq == null or int(gq.tier) > 0:
		var flash := OmniLight3D.new()
		flash.light_energy = 6.0
		flash.omni_range = 8.0
		flash.light_color = Color(0.5, 0.85, 1.0) if faction != "gROT" else Color(1.0, 0.3, 0.4)
		flash.shadow_enabled = false
		add_child(flash)
		flash.position = Vector3(0, 0, -2.0)
		var flash_ref = flash
		var tree := get_tree()
		if tree:
			tree.create_timer(0.07).timeout.connect(func():
				if is_instance_valid(flash_ref):
					flash_ref.queue_free()
			)
	if AudioDirector:
		AudioDirector.play_hit(false)
	var NP = load("res://scripts/fx/NeonParticles.gd")
	if NP:
		NP.muzzle_flash(origin, dir, NP.faction_color(str(faction)), get_tree())

func _spawn_module_visual(module: ShipModule) -> void:
	if module_root == null:
		return
	var pos := Vector3.ZERO
	var scale_v: float = 0.4
	var rel := ""
	match module.module_type:
		ShipModule.ModuleType.ENGINE:
			pos = Vector3(0, 0, 1.25)
			rel = "ships/thruster_cluster_neon/thruster_cluster_neon_cybernex_lod1.glb"
			scale_v = 0.5
		ShipModule.ModuleType.WEAPON:
			pos = Vector3(0.75, 0.05, -0.35)
			# HQ weapons: siege uses organic/rail heavies; cruise pulse/biomass
			if faction == "gROT":
				if op_mode == 1:
					rel = "props/grot_organic_cannon/grot_organic_cannon_grot_lod1.glb"
				else:
					rel = "props/weapon_biomass_spitter/weapon_biomass_spitter_grot_lod1.glb"
			else:
				if op_mode == 1:
					rel = "props/cybernex_rail_slug/cybernex_rail_slug_cybernex_lod1.glb"
				else:
					rel = "props/weapon_pulse_cannon/weapon_pulse_cannon_cybernex_lod1.glb"
			scale_v = 0.55 if op_mode != 1 else 0.7
		ShipModule.ModuleType.SHIELD:
			pos = Vector3(-0.75, 0.15, 0.1)
			rel = "props/shield_bubble_emitter/shield_bubble_emitter_cybernex_lod1.glb"
			scale_v = 0.45
		ShipModule.ModuleType.EXTRACTOR:
			pos = Vector3(0, -0.4, 0.15)
			rel = "colony/extractor_unit/extractor_unit_cybernex_lod1.glb"
			scale_v = 0.35
		_:
			pos = Vector3(randf_range(-0.4, 0.4), 0.35, 0)
	if faction == "gROT" and rel != "" and "_cybernex_" in rel:
		rel = rel.replace("_cybernex_", "_grot_")
	if rel != "" and DisplayServer.get_name() != "headless":
		var path: String = _asset_path(rel)
		if path == "" or not FileAccess.file_exists(path):
			# fallbacks
			if module.module_type == ShipModule.ModuleType.WEAPON:
				rel = "ships/ship_module_weapon/ship_module_weapon_%s_lod1.glb" % ("grot" if faction == "gROT" else "cybernex")
				path = _asset_path(rel)
			elif module.module_type == ShipModule.ModuleType.ENGINE:
				rel = "ships/ship_module_engine/ship_module_engine_%s_lod1.glb" % ("grot" if faction == "gROT" else "cybernex")
				path = _asset_path(rel)
			elif module.module_type == ShipModule.ModuleType.SHIELD:
				rel = "ships/shield_module/shield_module_%s_lod1.glb" % ("grot" if faction == "gROT" else "cybernex")
				path = _asset_path(rel)
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
	if _hull_ambient and is_instance_valid(_hull_ambient) and _hull_ambient.has_method("set_faction"):
		_hull_ambient.call("set_faction", faction)


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
		best.claim(faction, 0.5)
		print("[Ship] Pad claim pulse → ", faction)

func get_faction() -> String:
	return faction


func get_landed_pad() -> Node3D:
	return _landed_pad if is_landed else null

func take_damage(amount: float) -> void:
	if CombatJuice:
		CombatJuice.hit_feedback(float(amount), global_position, amount >= 40.0)
	_shield_hold_t = _SHIELD_HOLD
	var rest: float = amount
	if shields > 0.0:
		var absorbed: float = min(shields, rest)
		shields -= absorbed
		rest -= absorbed
	health = max(0.0, health - rest)
	if health <= 0.0:
		_hull_critical()


func _hull_critical() -> void:
	health = max_health * _HULL_CRIT_HP
	shields = 0.0
	_hull_crit_t = _HULL_CRIT_T
	_shield_hold_t = maxf(_shield_hold_t, _SHIELD_HOLD)
	velocity *= 0.4
	if flight_mode == FlightMode.NAV:
		_set_mode(FlightMode.SCM)
	if GameManager:
		GameManager.toast_requested.emit("HULL CRITICAL — thrust cut, no permadeath")
	print("[Ship] hull critical recover")


func hurtbox_center() -> Vector3:
	return global_position


func hurtbox_radius() -> float:
	return 2.4

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
	# Prefer shared NeonParticles plume (quad + additive shader)
	var NP = load("res://scripts/fx/NeonParticles.gd")
	var fac_col := Color(0.95, 0.25, 0.4) if faction == "gROT" else Color(0.3, 0.8, 1.0)
	if NP:
		_thruster_fx = NP.thruster_plume(self, fac_col, Vector3(0, 0, 2.2))
		if _thruster_fx:
			return
	_thruster_fx = GPUParticles3D.new()
	_thruster_fx.name = "ThrusterFX"
	var amt := 12
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq:
		match int(gq.tier):
			0: amt = 8
			2, 3: amt = 18
	_thruster_fx.amount = amt
	_thruster_fx.lifetime = 0.24
	_thruster_fx.emitting = false
	_thruster_fx.fixed_fps = 24
	_thruster_fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_thruster_fx.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_thruster_fx.visibility_aabb = AABB(Vector3(-2, -2, -1), Vector3(4, 4, 10))
	_thruster_fx.position = Vector3(0, 0, 2.2)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, 1)
	pm.spread = 10.0
	pm.initial_velocity_min = 5.0
	pm.initial_velocity_max = 12.0
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	pm.color = fac_col
	_thruster_fx.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.2, 0.2)
	_thruster_fx.draw_pass_1 = qm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_color = fac_col
	mat.emission_enabled = true
	mat.emission = fac_col
	mat.emission_energy_multiplier = 1.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_thruster_fx.material_override = mat
	add_child(_thruster_fx)


func _update_thruster_fx(axes: Vector3, delta: float) -> void:
	_process_scan_ring(delta)
	if _thruster_fx == null or not is_instance_valid(_thruster_fx):
		return
	var power: float = clampf(absf(axes.z) + absf(axes.x) * 0.4 + absf(axes.y) * 0.3, 0.0, 1.5)
	_thruster_fx.emitting = power > 0.08 and pilot_active and not is_landed
	if _thruster_fx.emitting:
		# Velocity only — never reallocate particle buffer via amount thrash
		var pm := _thruster_fx.process_material as ParticleProcessMaterial
		if pm:
			pm.initial_velocity_min = 4.0 + power * 5.0
			pm.initial_velocity_max = 8.0 + power * 10.0
		_engine_pulse_t += delta
		if _engine_pulse_t > 0.35 and AudioDirector and power > 0.5:
			_engine_pulse_t = 0.0
			AudioDirector.play_engine_pulse()


func _ensure_cargo_systems() -> void:
	if _cargo_hold != null:
		return
	# Every hull can fold one rover. Belly ramp is hangar-only (scout had a black monolith).
	_cargo_hold = Node.new()
	_cargo_hold.set_script(load("res://scripts/ship/CargoHold.gd"))
	_cargo_hold.name = "CargoHold"
	add_child(_cargo_hold)
	_cargo_hold.set("max_vehicle_slots", 2)
	_cargo_hold.set("volume_m3", 120.0)
	_cargo_hold.set("mass_t", 40.0)
	var want_ramp := false
	if _role != null:
		want_ramp = bool(_role.has_cargo_ramp) or bool(_role.allows_cargo_open)
	if not want_ramp:
		print("[Ship] CargoHold only (no hangar ramp)")
		return
	_cargo_ramp = Node3D.new()
	_cargo_ramp.set_script(load("res://scripts/ship/CargoRamp.gd"))
	_cargo_ramp.name = "CargoRamp"
	_cargo_ramp.position = Vector3(0, -0.5, 3.5)
	add_child(_cargo_ramp)
	print("[Ship] CargoHold + Ramp scaffold")


func _ensure_morph_and_hatch() -> void:
	if get_node_or_null("HatchPoint") == null:
		var h := Marker3D.new()
		h.name = "HatchPoint"
		# Side hatch slightly aft — marker only (no giant plate)
		h.position = Vector3(2.4, 0.6, 0.8)
		add_child(h)
	if _hull_morph == null or not is_instance_valid(_hull_morph):
		_hull_morph = Node3D.new()
		_hull_morph.set_script(load("res://scripts/ship/ShipHullMorph.gd"))
		_hull_morph.name = "HullMorph"
		add_child(_hull_morph)
	# Small hatch plate — HIDDEN by default (was blue monolith on +X)
	var hp = get_node_or_null("HatchPoint")
	if hp and hp.get_node_or_null("HatchDoor") == null:
		var door := MeshInstance3D.new()
		door.name = "HatchDoor"
		var db := BoxMesh.new()
		db.size = Vector3(0.35, 0.55, 0.04)
		door.mesh = db
		var dm := StandardMaterial3D.new()
		dm.albedo_color = Color(0.15, 0.2, 0.25, 0.35)
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dm.emission_enabled = true
		dm.emission = Color(0.2, 0.7, 1.0)
		dm.emission_energy_multiplier = 0.25
		door.material_override = dm
		door.visible = false  # only show during EVA / open
		door.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hp.add_child(door)
	print("[Ship] Hatch + HullMorph")


func set_hatch_open(open: bool) -> void:
	var door = get_node_or_null("HatchPoint/HatchDoor")
	if not (door is MeshInstance3D):
		return
	(door as MeshInstance3D).visible = true
	var target_y := deg_to_rad(85.0) if open else 0.0
	var tree := get_tree()
	if tree:
		var tw := tree.create_tween()
		tw.tween_property(door, "rotation:y", target_y, 0.28)
		if not open:
			tw.tween_callback(func():
				if is_instance_valid(door):
					(door as MeshInstance3D).visible = false
			)
	else:
		(door as MeshInstance3D).rotation.y = target_y
		(door as MeshInstance3D).visible = open
	if AudioDirector and AudioDirector.has_method("play_door"):
		AudioDirector.play_door(open)


func _toggle_siege() -> void:
	if _role == null or not bool(_role.allows_siege):
		_role = _load_role_sniper()
	if op_mode == 1:
		op_mode = 0
		var exit_s := 0.8
		if _role:
			exit_s = float(_role.siege_exit_sec)
		if _hull_morph and is_instance_valid(_hull_morph) and _hull_morph.has_method("set_op_mode"):
			_hull_morph.set_op_mode(0, exit_s)
		_on_op_mode_changed(0)
		print("[Ship] CRUISE mode")
	else:
		op_mode = 1
		var enter_s := 1.2
		if _role:
			enter_s = float(_role.siege_enter_sec)
		if _hull_morph and is_instance_valid(_hull_morph) and _hull_morph.has_method("set_op_mode"):
			_hull_morph.set_op_mode(1, enter_s)
		_on_op_mode_changed(1)
		print("[Ship] SIEGE mode — mobility down, main gun up")



func _toggle_cargo_ramp() -> void:
	if _cargo_ramp == null or not is_instance_valid(_cargo_ramp):
		return
	if not is_landed and velocity.length() > 6.0:
		print("[Ship] Ramp needs land/slow hover")
		return
	if _cargo_ramp.has_method("toggle"):
		_cargo_ramp.toggle()
		print("[Ship] Cargo ramp toggled")


func _try_deploy_rover() -> void:
	if not is_landed:
		print("[Ship] Land before deploying rover")
		return
	if _deployed_rover and is_instance_valid(_deployed_rover):
		print("[Ship] Rover already out — board with F near it later")
		return
	if _cargo_ramp and _cargo_ramp.has_method("deploy"):
		_cargo_ramp.deploy()
	var hold = _cargo_hold
	var entry := {"class_id": "rover", "volume": 8.0, "mass": 2.0, "health": 100.0}
	if hold and hold.has_method("store_vehicle"):
		# ensure one stored then retrieve
		if hold.vehicles.is_empty():
			hold.store_vehicle(entry)
		entry = hold.retrieve_vehicle(0)
	var rover: Node3D = CharacterBody3D.new()
	rover.set_script(load("res://scripts/vehicle/GroundVehicle.gd"))
	var parent_n: Node = get_parent()
	if parent_n:
		parent_n.add_child(rover)
	else:
		add_child(rover)
	var up := global_transform.basis.y
	var aft := global_transform.basis.z
	rover.global_position = global_position + aft * 6.0 + up * 1.0
	if rover.has_method("set_planet_provider") and _open_space:
		rover.set_planet_provider(_open_space)
	_deployed_rover = rover
	print("[Ship] Rover deployed")


func get_interior_profile_id() -> String:
	if _role:
		return str(_role.interior_profile_id)
	return "scout_single"


func _load_role_sniper():
	var scr = load("res://scripts/ship/ShipRoleProfile.gd")
	if scr and scr.has_method("make_sniper"):
		return scr.make_sniper()
	return null


func _toggle_scan() -> void:
	if op_mode == 2:
		op_mode = 0
		if _hull_morph and is_instance_valid(_hull_morph) and _hull_morph.has_method("set_op_mode"):
			_hull_morph.set_op_mode(0, 0.6)
		_on_op_mode_changed(0)
		print("[Ship] CRUISE (left SCAN)")
	else:
		op_mode = 2
		if _hull_morph and is_instance_valid(_hull_morph) and _hull_morph.has_method("set_op_mode"):
			_hull_morph.set_op_mode(2, 0.7)
		_on_op_mode_changed(2)
		print("[Ship] SCAN mode — sensors fantasy, mobility soft down")


func get_deployed_rover() -> Node3D:
	return _deployed_rover if _deployed_rover and is_instance_valid(_deployed_rover) else null


func clear_deployed_rover() -> void:
	_deployed_rover = null


func _stick_to_pad() -> void:
	velocity = Vector3.ZERO
	if _landed_pad and is_instance_valid(_landed_pad):
		var up: Vector3 = Vector3.UP
		if _landed_pad.has_meta("pad_up"):
			up = (_landed_pad.get_meta("pad_up") as Vector3).normalized()
		var target: Vector3 = _landed_pad.global_position + up * _land_hold_h
		# Soft correct only if drifted — hard teleport every frame felt like "climbing"
		var d: float = global_position.distance_to(target)
		if d > 0.15:
			global_position = global_position.lerp(target, 0.55 if d > 1.5 else 0.25)
		# Hard ceiling: never rise above hold height + slack
		var h: float = (global_position - _landed_pad.global_position).dot(up)
		if h > _land_hold_h + 0.4:
			global_position = target
		# Keep level to pad
		_pitch = lerpf(_pitch, 0.0, 0.35)
		_roll = lerpf(_roll, 0.0, 0.35)
		_apply_attitude()
		return
	# Surface land: freeze + soft altitude hold vs nearest planet
	velocity = Vector3.ZERO
	if _open_space and _open_space.has_method("nearest_planet"):
		var pl: Node3D = _open_space.nearest_planet(global_position)
		if pl and is_instance_valid(pl) and "radius" in pl:
			var up2: Vector3 = (global_position - pl.global_position).normalized()
			var hold: Vector3 = pl.global_position + up2 * (float(pl.radius) + 3.5)
			var dh: float = global_position.distance_to(hold)
			if dh > 0.4:
				global_position = global_position.lerp(hold, 0.2)
			_pitch = lerpf(_pitch, 0.0, 0.3)
			_roll = lerpf(_roll, 0.0, 0.3)
			_apply_attitude()


func _hull_local_size(n: Node3D) -> Vector3:
	var a: AABB = _MeshOrient._aabb_in_root(n)
	if a.size.length_squared() < 1e-6:
		return Vector3.ONE
	return a.size


func _sync_planet_palette() -> void:
	var best: Node3D = SoftScanCache.nearest_planet(global_position) if SoftScanCache else null
	if best == null:
		var tree := get_tree()
		if tree == null:
			return
		var best_d := 1.0e12
		for n in tree.get_nodes_in_group("planets"):
			if n is Node3D:
				var d: float = global_position.distance_to((n as Node3D).global_position)
				if d < best_d:
					best_d = d
					best = n as Node3D
	if best == null:
		return
	# Only near-surface influence
	if best.has_method("altitude_of"):
		if float(best.altitude_of(global_position)) > 400.0:
			return
	var col := Color(0.5, 0.7, 1.0)
	if "surface_color" in best:
		col = best.surface_color
	# Soft emission on first MeshInstance3D child named Hull or any mesh
	for c in find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if mi == null:
			continue
		var mat = mi.material_override
		if mat is StandardMaterial3D:
			var sm := mat as StandardMaterial3D
			sm.emission_enabled = true
			sm.emission = col * 0.15
			sm.emission_energy_multiplier = 0.25
			break


func _tick_scan_pulse(delta: float) -> void:
	if op_mode != 2:
		return
	_scan_pulse_t += delta
	if _scan_pulse_t < 0.55:
		return
	_scan_pulse_t = 0.0
	# Soft intel only — cached pads/planets, no full tree walk
	var pad: Node3D = SoftScanCache.nearest_pad(global_position, 350.0) if SoftScanCache else null
	var planet: Node3D = SoftScanCache.nearest_planet(global_position) if SoftScanCache else null
	var bits: PackedStringArray = PackedStringArray()
	if planet and "planet_name" in planet:
		var alt := global_position.distance_to(planet.global_position) - float(planet.radius) if "radius" in planet else 0.0
		bits.append("%s alt=%.0f" % [str(planet.planet_name), alt])
	if pad:
		var fac := "?"
		if "ownership" in pad and pad.ownership:
			fac = str(pad.ownership.faction_name()) if pad.ownership != null and is_instance_valid(pad.ownership) and pad.ownership.has_method("faction_name") else "?"
		bits.append("pad@%.0fm %s" % [global_position.distance_to(pad.global_position), fac])
	var report := "SCAN · " + (" · ".join(bits) if bits.size() > 0 else "no contacts")
	if report == _scan_last_report:
		return
	_scan_last_report = report
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("game_hud"):
			if n.has_method("push_toast"):
				n.push_toast(report, 1.6)
				break


func _ensure_hull_ambient() -> void:
	if _hull_ambient and is_instance_valid(_hull_ambient):
		return
	_hull_ambient = Node3D.new()
	_hull_ambient.set_script(load("res://scripts/ship/ShipHullAmbient.gd"))
	_hull_ambient.name = "HullAmbient"
	add_child(_hull_ambient)
	if _hull_ambient.has_method("setup"):
		_hull_ambient.call("setup", self)
	if _hull_ambient.has_method("set_faction"):
		_hull_ambient.call("set_faction", faction)
	print("[Ship] HullAmbient")


func _tick_hull_ambient(axes: Vector3, _delta: float) -> void:
	if _hull_ambient == null or not is_instance_valid(_hull_ambient):
		return
	var power: float = clampf(absf(axes.z) + absf(axes.x) * 0.4 + absf(axes.y) * 0.3, 0.0, 1.5)
	if _burn_on:
		power = maxf(power, 1.35)
	if not pilot_active:
		power = 0.0
	if _hull_ambient.has_method("set_engine_power"):
		_hull_ambient.call("set_engine_power", power)
	if _hull_ambient.has_method("set_op_mode"):
		_hull_ambient.call("set_op_mode", op_mode)
	if _hull_ambient.has_method("set_landed"):
		_hull_ambient.call("set_landed", is_landed)


func get_energy() -> float:
	return energy


func spend_energy(amount: float) -> void:
	energy = maxf(0.0, energy - amount)



func _ensure_soft_systems() -> void:
	if get_node_or_null("SoftShipSystems"):
		return
	var n := Node.new()
	n.set_script(load("res://scripts/ship/SoftShipSystems.gd"))
	add_child(n)
	if n.has_method("setup"):
		n.setup(self)


func get_soft_systems_line() -> String:
	var n = get_node_or_null("SoftShipSystems")
	if n and n.has_method("status_line"):
		return str(n.status_line())
	return ""


var _living: Node = null


func _ensure_living_fx() -> void:
	if get_node_or_null("LivingConfig") != null:
		return
	var fac := str(faction) if "faction" in self else "Cybernex"
	_living = Node3D.new()
	_living.set_script(load("res://scripts/ship/LivingConfig.gd"))
	_living.name = "LivingConfig"
	add_child(_living)
	if _living.has_method("setup_from_faction"):
		_living.setup_from_faction(fac)
	# Neon boost existing thruster
	var NP = load("res://scripts/fx/NeonParticles.gd")
	if NP and _thruster_fx and is_instance_valid(_thruster_fx):
		var pm := _thruster_fx.process_material as ParticleProcessMaterial
		if pm:
			pm.color = NP.faction_color(fac)


func sync_living_mode() -> void:
	if _living == null:
		_living = get_node_or_null("LivingConfig")
	if _living == null or not _living.has_method("set_mode"):
		return
	var m := 0
	if "op_mode" in self:
		var om = int(op_mode)
		if om == 1:
			m = 2
		elif om == 2:
			m = 1
	_living.set_mode(m, 0.7)



func _on_op_mode_changed(mode: int) -> void:
	## Sync living config, ambient, neon feedback, weapon hardpoint refresh.
	sync_living_mode()
	if _hull_ambient and is_instance_valid(_hull_ambient) and _hull_ambient.has_method("set_op_mode"):
		_hull_ambient.call("set_op_mode", mode)
	_refresh_weapon_visual()
	_toast_op(mode)
	if DisplayServer.get_name() == "headless":
		return
	var NP = load("res://scripts/fx/NeonParticles.gd")
	if NP and is_inside_tree():
		var col = NP.faction_color(str(faction))
		if mode == 1:
			col = Color(1.0, 0.45, 0.15, 0.9)  # amber siege
		elif mode == 2:
			col = Color(0.4, 1.0, 0.7, 0.9)  # scan green-cyan
		NP.burst(global_position, col, get_tree(), 8, 4.0)


func _toast_op(mode: int) -> void:
	var msg := "CRUISE"
	if mode == 1:
		msg = "SIEGE — thrusters damped · main gun charged"
	elif mode == 2:
		msg = "SCAN — sensors open · soft mobility cut"
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("game_hud"):
		if n.has_method("push_toast"):
			n.push_toast(msg, 2.2)
			return


func _refresh_weapon_visual() -> void:
	## Rebuild weapon hardpoint for siege/cruise skin (visual only).
	if module_root == null or DisplayServer.get_name() == "headless":
		return
	for c in module_root.get_children():
		var nm := str(c.name).to_lower()
		if "weapon" in nm or "cannon" in nm or "rail" in nm or "biomass" in nm or "organic" in nm or "spitter" in nm or "slug" in nm or "pulse" in nm or "wep" in nm:
			c.queue_free()
	var dps := 14.0
	if op_mode == 1:
		dps = 22.0
	var w := ShipModule.make_weapon("Siege Lance" if op_mode == 1 else "Pulse Cannon", dps)
	_spawn_module_visual(w)


func get_op_mode_name() -> String:
	if op_mode == 1:
		return "SIEGE"
	if op_mode == 2:
		return "SCAN"
	return "CRUISE"


func get_flight_status_line() -> String:
	var st := "%s · %s · SPD %d" % [flight_mode_name(), get_op_mode_name(), int(velocity.length())]
	if _stall > 0.28:
		st += " · STALL %.0f%%" % (_stall * 100.0)
	return st


func get_stall() -> float:
	return _stall



func _ensure_shield_bubble() -> void:
	if get_node_or_null("SoftShieldBubble"):
		return
	if DisplayServer.get_name() == "headless":
		return
	var n := Node3D.new()
	n.set_script(load("res://scripts/ship/SoftShieldBubble.gd"))
	add_child(n)
	if n.has_method("setup"):
		n.setup(self)


var _scan_ring: MeshInstance3D = null


func _ensure_scan_ring() -> void:
	if _scan_ring and is_instance_valid(_scan_ring):
		return
	if DisplayServer.get_name() == "headless":
		return
	_scan_ring = MeshInstance3D.new()
	_scan_ring.name = "SoftScanRing"
	var tm := TorusMesh.new()
	tm.inner_radius = 3.2
	tm.outer_radius = 3.5
	tm.rings = 8
	tm.ring_segments = 20
	_scan_ring.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.35, 1.0, 0.75, 0.0)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 1.0, 0.75)
	mat.emission_energy_multiplier = 1.8
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_scan_ring.material_override = mat
	_scan_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_scan_ring.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_scan_ring.visible = false
	add_child(_scan_ring)


func _process_scan_ring(delta: float) -> void:
	if _scan_ring == null or not is_instance_valid(_scan_ring):
		return
	var on := op_mode == 2 and pilot_active
	_scan_ring.visible = on
	if not on:
		return
	_scan_ring.rotate_y(delta * 1.4)
	var mat := _scan_ring.material_override as StandardMaterial3D
	if mat:
		var a := 0.25 + 0.2 * sin(Time.get_ticks_msec() * 0.006)
		mat.albedo_color.a = a
		mat.emission_energy_multiplier = 1.4 + a * 2.0



func _ensure_nose_marker() -> void:
	if get_node_or_null("NoseMarker"):
		return
	if DisplayServer.get_name() == "headless":
		return
	var n := MeshInstance3D.new()
	n.name = "NoseMarker"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.06, 0.06, 0.9)
	n.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.15, 0.95, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.95, 1.0)
	mat.emission_energy_multiplier = 2.5
	n.material_override = mat
	n.position = Vector3(0, 0.4, -2.2)  # local −Z = thrust nose
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(n)



func _toast_ship(msg: String) -> void:
	if GameManager and GameManager.has_signal("toast_requested"):
		GameManager.toast_requested.emit(msg)
	print("[Ship] ", msg)


func _auto_land_assist(delta: float) -> void:
	## Hint only — E still commits. No auto-land (honest speed gate).
	_land_hint_cd = maxf(0.0, _land_hint_cd - delta)
	if is_landed or not pilot_active:
		return
	if velocity.length() > 8.0:
		return
	if flight_mode != FlightMode.HOVER:
		return
	if _open_space == null or not _open_space.has_method("nearest_pad"):
		return
	var pad: Node3D = _open_space.nearest_pad(global_position)
	if pad == null or not is_instance_valid(pad):
		return
	var d: float = pad.global_position.distance_to(global_position)
	if d > 28.0:
		return
	_sync_landing_gear()
	if _land_hint_cd <= 0.0:
		_land_hint_cd = 3.5
		_toast_ship("Pad %.0fm — E land (then C claim)" % d)


