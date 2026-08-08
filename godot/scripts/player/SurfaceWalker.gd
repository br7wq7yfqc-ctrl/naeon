extends CharacterBody3D
const _HeroForms = preload("res://scripts/player/HeroFormCatalog.gd")
const _MeshOrient = preload("res://scripts/assets/MeshOrient.gd")
const _FormAnim = preload("res://scripts/player/FormAnimator.gd")
const _FormFX = preload("res://scripts/player/FormSwitchFX.gd")
## Planet-surface TPS walker: radial gravity, floor snap, procedural anim.
## Used for OpenSpace exit (not flat-world PlayerController).

const _AP = preload("res://scripts/assets/AssetPaths.gd")

@export var speed: float = 6.5
@export var sprint_mult: float = 1.75
@export var jump_velocity: float = 7.0
@export var mouse_sensitivity: float = 0.0025
@export var faction: String = "Cybernex"
@export var form_name: String = "Canine"

var _yaw: float = 0.0
var _pitch: float = 0.0
var _provider: Node = null
var _visual: Node3D
var _body_mesh: MeshInstance3D
var _anim_time: float = 0.0
var _step_t: float = 0.0
var _leg_l: MeshInstance3D
var _leg_r: MeshInstance3D
var _arm_l: MeshInstance3D
var _arm_r: MeshInstance3D
var _limb_rig: Node3D
var _form_skel: Skeleton3D = null
var _move_amount: float = 0.0
var eva_mode: bool = false
var thruster_accel: float = 14.0
var mag_boot: bool = false
var eva_time: float = 0.0
var energy: float = 100.0
var max_energy: float = 100.0
var energy_regen: float = 12.0  # EnergyEconomy.REGEN_WALKER
var health: float = 100.0
var max_health: float = 100.0
var _up: Vector3 = Vector3.UP
var cam_pivot: Node3D
var camera: Camera3D

func set_planet_gravity_provider(p: Node) -> void:
	_provider = p


func set_eva_profile(enabled: bool) -> void:
	eva_mode = enabled
	if enabled:
		speed = 5.5
		sprint_mult = 1.2
		jump_velocity = 0.0
		print("[SurfaceWalker] EVA thruster suit")
		if _body_mesh and _body_mesh.material_override is StandardMaterial3D:
			var m: StandardMaterial3D = _body_mesh.material_override
			m.emission_enabled = true
			m.emission = Color(0.3, 0.8, 1.0)
			m.emission_energy_multiplier = 0.8
	else:
		speed = 6.5
		sprint_mult = 1.75
		jump_velocity = 7.0
		print("[SurfaceWalker] surface profile")


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.25
	floor_max_angle = deg_to_rad(60.0)
	up_direction = Vector3.UP
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	_ensure_rig()
	_ensure_limb_rig()
	_load_form_visual()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Snap to floor next frame
	call_deferred("snap_to_surface")
	_ensure_combat_nodes()
	print("[SurfaceWalker] ready form=", form_name)
	if SoftNetSession:
		SoftNetSession.bind_player(self)
	if SoftSession:
		SoftSession.apply_to_player(self)

func _ensure_rig() -> void:
	if get_node_or_null("CollisionShape3D") == null:
		var col := CollisionShape3D.new()
		var sh := CapsuleShape3D.new()
		sh.radius = 0.4
		sh.height = 1.5
		col.shape = sh
		col.position = Vector3(0, 0.95, 0)
		add_child(col)
	_visual = get_node_or_null("Visual") as Node3D
	if _visual == null:
		_visual = Node3D.new()
		_visual.name = "Visual"
		add_child(_visual)
	_body_mesh = _visual.get_node_or_null("BodyMesh") as MeshInstance3D
	if _body_mesh == null:
		_body_mesh = MeshInstance3D.new()
		_body_mesh.name = "BodyMesh"
		var cm := CapsuleMesh.new()
		cm.radius = 0.38
		cm.height = 1.4
		_body_mesh.mesh = cm
		_body_mesh.position = Vector3(0, 0.95, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.08, 0.14, 0.2)
		mat.metallic = 0.55
		mat.roughness = 0.35
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.85, 1.0) if faction != "gROT" else Color(0.95, 0.15, 0.4)
		mat.emission_energy_multiplier = 1.2
		_body_mesh.material_override = mat
		_visual.add_child(_body_mesh)
	cam_pivot = get_node_or_null("CamPivot") as Node3D
	if cam_pivot == null:
		cam_pivot = Node3D.new()
		cam_pivot.name = "CamPivot"
		cam_pivot.position = Vector3(0, 1.55, 0)
		add_child(cam_pivot)
	camera = cam_pivot.get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera.position = Vector3(0, 0.35, 4.2)
		camera.current = true
		camera.fov = 70.0
		cam_pivot.add_child(camera)
	else:
		camera.current = true

func _load_form_visual() -> void:
	var path := ""
	for rel in _HeroForms.mesh_candidates(form_name, faction):
		var p: String = _AP.resolve(rel)
		if p != "" and FileAccess.file_exists(p):
			path = p
			break
	if path == "":
		return
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return
	var root := doc.generate_scene(state)
	if root == null:
		return
	if _body_mesh:
		_body_mesh.visible = false
	# Strip rigid bodies from form mesh
	_strip_colliders(root)
	_visual.add_child(root)
	root.name = "FormGLB"
	_MeshOrient.face_neg_z(root as Node3D, true)
	_form_skel = _FormAnim.find_skeleton(root)
	root.scale = Vector3.ONE * 1.1
	root.position = Vector3(0, 0, 0)
	print("[SurfaceWalker] form mesh ", path)

func _strip_colliders(n: Node) -> void:
	for c in n.get_children():
		_strip_colliders(c)
	if n is CollisionObject3D:
		(n as CollisionObject3D).collision_layer = 0
		(n as CollisionObject3D).collision_mask = 0


func _ensure_combat_nodes() -> void:
	if get_node_or_null("InfectionStatus") == null:
		var n := Node.new()
		n.set_script(preload("res://scripts/abilities/InfectionStatus.gd"))
		n.name = "InfectionStatus"
		add_child(n)
	# Ability system lightweight for surface
	if get_node_or_null("AbilitySystem") == null:
		var ab := Node.new()
		ab.set_script(preload("res://scripts/abilities/AbilitySystem.gd"))
		ab.name = "AbilitySystem"
		add_child(ab)
		if ab.has_method("setup_default_loadout"):
			ab.setup_default_loadout(faction)
	call_deferred("_bind_hud")

func _bind_hud() -> void:
	if get_tree() == null:
		return
	var existing = get_tree().get_first_node_in_group("game_hud")
	if existing == null:
		var hud := CanvasLayer.new()
		hud.set_script(preload("res://scripts/ui/GameHUD.gd"))
		hud.name = "GameHUD"
		hud.add_to_group("game_hud")
		get_tree().current_scene.add_child(hud)
		existing = hud
	if existing.has_method("bind_player"):
		existing.bind_player(self)

func get_faction() -> String:
	return faction

func get_energy() -> float:
	return energy


func spend_energy(amount: float) -> void:
	energy = maxf(0.0, energy - amount)


func heal(amount: float) -> void:
	health = minf(max_health, health + amount)


func on_hacked(caster: Node, amount: float = 1.0) -> void:
	var inf = get_node_or_null("InfectionStatus")
	if inf and inf.has_method("add_stacks"):
		inf.add_stacks(2)

func snap_to_surface() -> void:
	_update_up()
	var space := get_world_3d().direct_space_state if get_world_3d() else null
	if space == null:
		global_position += _up * 3.0
		return
	var origin := global_position + _up * 25.0
	var end := global_position - _up * 80.0
	var q := PhysicsRayQueryParameters3D.create(origin, end)
	q.collision_mask = 1
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit:
		global_position = hit.position + _up * 1.85
		velocity = Vector3.ZERO
		print("[SurfaceWalker] snapped to ", hit.position)
		return
	if _relief_snap_fallback():
		return
	global_position += _up * 4.0
	print("[SurfaceWalker] no hit — boost along up")


func safe_unground() -> void:
	## If embedded in geometry after spawn, push out along up.
	_update_up()
	if test_move(global_transform, -_up * 0.05):
		# stuck — rise until free or cap
		for i in 12:
			global_position += _up * 0.45
			if not test_move(global_transform, -_up * 0.05):
				break
		velocity = Vector3.ZERO
		print("[SurfaceWalker] safe_unground lifted")


func set_spawn_basis(up: Vector3, yaw: float) -> void:
	_up = up.normalized()
	_yaw = yaw
	up_direction = _up
	_apply_body_basis()

func _update_up() -> void:
	if _provider and _provider.has_method("gravity_at"):
		var g: Vector3 = _provider.gravity_at(global_position)
		if g.length() > 0.2:
			_up = (-g).normalized()
			up_direction = _up

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, deg_to_rad(-70), deg_to_rad(70))
		if cam_pivot:
			cam_pivot.rotation.x = _pitch
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V:
			_cycle_form()
		elif event.keycode == KEY_Q:
			_try_ability(0)
		elif event.keycode == KEY_E:
			if eva_mode:
				mag_boot = not mag_boot
				print("[SurfaceWalker] mag-boot ", mag_boot)
			else:
				_try_ability(1)
		elif event.keycode == KEY_R:
			_try_ability(2)
		elif event.keycode == KEY_F:
			_try_ability(3)
		# G/B terrain edit handled by PlanetTerrainEdit while in player group
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

func _physics_process(delta: float) -> void:
	_terrain_hint_tick(delta)
	_update_up()
	energy = minf(max_energy, energy + energy_regen * delta)
	var g_vec := -_up * 14.0
	if _provider and _provider.has_method("gravity_at"):
		var pg: Vector3 = _provider.gravity_at(global_position)
		if pg.length() > 0.2:
			g_vec = pg

	var input := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W):
		input.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S):
		input.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D):
		input.x += 1.0
	if input.length_squared() > 1.0:
		input = input.normalized()

	# Movement relative to look: W = body forward (−Z), D = body right (+X)
	var blook := _basis_from_up()
	var forward := (-blook.z)
	var right := blook.x
	forward = (forward - _up * forward.dot(_up))
	right = (right - _up * right.dot(_up))
	if forward.length_squared() < 1e-6:
		forward = Vector3(0, 0, -1)
	else:
		forward = forward.normalized()
	if right.length_squared() < 1e-6:
		right = forward.cross(_up).normalized()
	else:
		right = right.normalized()
	# input.y: W=-1 S=+1  →  wish along forward when W
	var wish := right * input.x + forward * (-input.y)
	if eva_mode:
		# Zero-G thruster: WASD plane + Space/Shift vertical, light damp
		var lift := 0.0
		if Input.is_physical_key_pressed(KEY_SPACE):
			lift += 1.0
		if Input.is_physical_key_pressed(KEY_SHIFT):
			lift -= 1.0
		var wish3 := wish * thruster_accel + _up * lift * thruster_accel
		velocity += wish3 * delta
		velocity = velocity.lerp(Vector3.ZERO, 0.65 * delta)
		if velocity.length() > 18.0:
			velocity = velocity.normalized() * 18.0
		eva_time += delta
		if mag_boot:
			velocity = velocity.lerp(Vector3.ZERO, 4.0 * delta)
		_move_amount = velocity.length() / 12.0
		_apply_body_basis()
		move_and_slide()
		_update_anim(delta)
		return
	var sp := speed * (sprint_mult if Input.is_physical_key_pressed(KEY_SHIFT) else 1.0) * _infection_move_mult()
	var target_planar := wish * sp
	# Smooth accel on ground, weaker air control (not ice-skating)
	var planar := velocity - _up * velocity.dot(_up)
	var accel_rate := 28.0 if is_on_floor() else 8.0
	var decel_rate := 32.0 if is_on_floor() else 4.0
	if target_planar.length_squared() > 0.01:
		planar = planar.move_toward(target_planar, accel_rate * delta)
	else:
		planar = planar.move_toward(Vector3.ZERO, decel_rate * delta)
	_move_amount = planar.length() / maxf(speed, 0.01)

	# Gravity integrate along radial up
	var v_up := velocity.dot(_up)
	if not is_on_floor():
		v_up += g_vec.dot(_up) * delta
	else:
		# stick: small downward bias helps floor contact on spheres
		v_up = minf(v_up, -0.4)
	if Input.is_physical_key_pressed(KEY_SPACE) and (is_on_floor() or eva_mode):
		v_up = jump_velocity
		_spawn_jump_fx()

	velocity = planar + _up * v_up
	up_direction = _up
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(55.0)
	# Canyon/steep assist: stickier steps on high slopes
	if is_on_floor() and get_floor_angle() > deg_to_rad(40.0):
		floor_snap_length = 0.55
		floor_max_angle = deg_to_rad(70.0)
		if _move_amount > 0.2:
			velocity += _up * 2.5 * delta  # soft climb boost
	_apply_body_basis()
	move_and_slide()
	if is_on_floor():
		apply_floor_snap()

	_update_anim(delta)

func _basis_from_up() -> Basis:
	# Right-handed: X=right, Y=up, Z=back (−forward). Previous up.cross(f0) flipped X (det=-1)
	# which made WASD feel sideways and inverted horizontal look.
	var up := _up.normalized()
	var f0 := Vector3(0, 0, -1)  # Godot forward
	if absf(up.dot(f0)) > 0.95:
		f0 = Vector3(1, 0, 0)
	# Project preferred forward onto tangent plane
	f0 = (f0 - up * f0.dot(up)).normalized()
	# forward × up = right (right-handed)
	var right := f0.cross(up).normalized()
	var forward := up.cross(right).normalized()
	var b := Basis(right, up, -forward)
	return Basis(up, _yaw) * b

func _apply_body_basis() -> void:
	var b := _basis_from_up()
	global_transform = Transform3D(b.orthonormalized(), global_position)
	# Camera yaw is body; pitch on pivot
	if cam_pivot:
		cam_pivot.position = _up * 1.55  # local after transform? pivot is child so local Y
		# After parent basis applied, local +Y is planet up
		cam_pivot.position = Vector3(0, 1.55, 0)
		cam_pivot.rotation.x = _pitch

func _update_anim(delta: float) -> void:
	if _move_amount > 0.25:
		_step_t += delta * (2.2 + _move_amount * 2.0)
		if _step_t >= 1.0:
			_step_t = 0.0
			if AudioDirector:
				AudioDirector.play_ui()
	if _visual == null:
		return
	_anim_time += delta * (1.0 + _move_amount * 6.0)
	var bob := sin(_anim_time * TAU) * 0.06 * clampf(_move_amount, 0.0, 1.5)
	var sway := sin(_anim_time * TAU * 0.5) * 0.04
	var lean := clampf(_move_amount, 0.0, 1.0) * 0.12
	_visual.position = Vector3(sway * 0.15, bob, 0.0)
	_visual.rotation = Vector3(-lean, 0.0, sway * 0.5)
	# Idle breathe when still
	if _move_amount < 0.08:
		var breathe := sin(Time.get_ticks_msec() * 0.004) * 0.02
		_visual.scale = Vector3(1.0 + breathe * 0.15, 1.0 + breathe, 1.0 + breathe * 0.15)
	else:
		var stomp := absf(sin(_anim_time * TAU)) * 0.04
		_visual.scale = Vector3(1.0 + stomp * 0.1, 1.0 - stomp * 0.08, 1.0 + stomp * 0.1)
	_update_limbs()

const FORMS := ["Canine", "Feline", "Avian", "Human"]
const _Relief = preload("res://scripts/world/PlanetRelief.gd")

func _infection_move_mult() -> float:
	var inf = get_node_or_null("InfectionStatus")
	if inf and inf.has_method("move_speed_mult"):
		return float(inf.move_speed_mult())
	return 1.0

func _cycle_form() -> void:
	var forms: PackedStringArray = _HeroForms.forms_for_faction(faction)
	var i := forms.find(form_name)
	if i < 0:
		i = 0
	i = (i + 1) % forms.size()
	form_name = forms[i]
	if GameManager:
		GameManager.toast_requested.emit("Hero form → %s · dual-theme %s" % [form_name, faction])
	if SoftSession:
		SoftSession.remember_player(self)
	_FormFX.play_at(self, faction, form_name)
	# reload visual
	var old = _visual.get_node_or_null("FormGLB") if _visual else null
	if old:
		old.queue_free()
	if _body_mesh:
		_body_mesh.visible = true
	_load_form_visual()
	print("[SurfaceWalker] form → ", form_name)

func _try_ability(idx: int) -> void:
	var ab = get_node_or_null("AbilitySystem")
	if ab and ab.has_method("try_activate"):
		ab.try_activate(idx)

func _ensure_limb_rig() -> void:
	# Lightweight procedural limbs when GLB has no skeleton (code-first).
	if _visual == null:
		return
	if _limb_rig and is_instance_valid(_limb_rig):
		return
	# Hide limbs if form GLB loaded with real mesh
	var glb = _visual.get_node_or_null("FormGLB")
	if glb:
		return
	_limb_rig = Node3D.new()
	_limb_rig.name = "LimbRig"
	_visual.add_child(_limb_rig)
	_leg_l = _make_limb(Color(0.2, 0.25, 0.3), Vector3(-0.18, -0.35, 0.05), Vector3(0.12, 0.55, 0.12))
	_leg_r = _make_limb(Color(0.2, 0.25, 0.3), Vector3(0.18, -0.35, 0.05), Vector3(0.12, 0.55, 0.12))
	_arm_l = _make_limb(Color(0.25, 0.3, 0.35), Vector3(-0.38, 0.25, 0.0), Vector3(0.1, 0.45, 0.1))
	_arm_r = _make_limb(Color(0.25, 0.3, 0.35), Vector3(0.38, 0.25, 0.0), Vector3(0.1, 0.45, 0.1))
	_limb_rig.add_child(_leg_l)
	_limb_rig.add_child(_leg_r)
	_limb_rig.add_child(_arm_l)
	_limb_rig.add_child(_arm_r)

func _make_limb(col: Color, pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.4
	mat.roughness = 0.55
	mat.emission_enabled = true
	mat.emission = col * 0.35
	mat.emission_energy_multiplier = 0.6
	mi.material_override = mat
	mi.position = pos
	return mi

func _update_limbs() -> void:
	if _form_skel and _FormAnim.apply_locomotion(_form_skel, _move_amount, _anim_time, is_on_floor()):
		if _limb_rig:
			_limb_rig.visible = false
		return
	if _limb_rig == null or not is_instance_valid(_limb_rig):
		return
	var a := _anim_time * TAU
	var amp := clampf(_move_amount, 0.0, 1.2)
	if _leg_l:
		_leg_l.rotation.x = sin(a) * 0.55 * amp
	if _leg_r:
		_leg_r.rotation.x = sin(a + PI) * 0.55 * amp
	if _arm_l:
		_arm_l.rotation.x = sin(a + PI) * 0.4 * amp
	if _arm_r:
		_arm_r.rotation.x = sin(a) * 0.4 * amp

func _spawn_jump_fx() -> void:
	var p := GPUParticles3D.new()
	p.amount = 18
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 3.5
	pm.gravity = Vector3(0, -8, 0)
	pm.scale_min = 0.04
	pm.scale_max = 0.12
	pm.color = Color(0.65, 0.7, 0.6, 0.85)
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	sm.radial_segments = 4
	sm.rings = 2
	p.draw_pass_1 = sm
	add_child(p)
	p.position = Vector3(0, 0.05, 0)
	var tree := get_tree()
	if tree:
		tree.create_timer(0.6).timeout.connect(p.queue_free)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F9 or event.physical_keycode == KEY_F9:
			toggle_faction()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F10 or event.physical_keycode == KEY_F10:
			if SoftENet:
				SoftENet.host()
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
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F12 or event.physical_keycode == KEY_F12:
			if SoftENet:
				SoftENet.leave()
			get_viewport().set_input_as_handled()

		elif event.keycode == KEY_I or event.physical_keycode == KEY_I:
			var os := get_tree().get_first_node_in_group("open_space") if get_tree() else null
			if os == null and get_parent():
				os = get_tree().current_scene if get_tree() else null
			if os and os.has_node("InteriorDirector"):
				var idir = os.get_node("InteriorDirector")
				if idir.has_method("try_toggle"):
					var ship = os.get("ship") if "ship" in os else null
					idir.try_toggle(self, ship)
			elif os and os.get_node_or_null("InteriorDirector"):
				pass
			get_viewport().set_input_as_handled()


func toggle_faction() -> void:
	faction = "gROT" if faction != "gROT" else "Cybernex"
	var ab = get_node_or_null("AbilitySystem")
	if ab and ab.has_method("setup_default_loadout"):
		ab.setup_default_loadout(faction)
	var old = _visual.get_node_or_null("FormGLB") if _visual else null
	if old:
		old.queue_free()
	if _body_mesh:
		_body_mesh.visible = true
	_load_form_visual()
	_FormFX.play_at(self, faction, form_name)
	if SoftSession:
		SoftSession.remember_player(self)
	if GameManager:
		GameManager.toast_requested.emit("Faction → %s (surface dual-theme)" % faction)


func _relief_snap_fallback() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var best: Node3D = null
	var best_d := 1.0e12
	for n in tree.get_nodes_in_group("planets"):
		if n is Node3D:
			var d: float = global_position.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n as Node3D
	if best == null:
		var root = tree.current_scene
		if root:
			for n in root.get_children():
				if n is Node3D and n.has_method("altitude_of"):
					var d2: float = global_position.distance_to((n as Node3D).global_position)
					if d2 < best_d:
						best_d = d2
						best = n as Node3D
	if best == null or not ("radius" in best):
		return false
	var rad: float = float(best.radius)
	var pid: String = str(best.planet_name) if "planet_name" in best else "Nex-Prime"
	var seed_i: int = int(absi(pid.hash()) % 10000)
	var prof: Dictionary = _Relief.profile_for_planet(pid)
	var dir: Vector3 = (global_position - best.global_position).normalized()
	var east: Vector3 = dir.cross(Vector3.UP)
	if east.length_squared() < 1e-6:
		east = dir.cross(Vector3.RIGHT)
	east = east.normalized()
	var north: Vector3 = east.cross(dir).normalized()
	var to: Vector3 = global_position - best.global_position
	var h: float = float(_Relief.height_at(to.dot(east), to.dot(north), seed_i, prof))
	var sea: float = float(prof.get("sea_level", -0.35))
	if h < sea:
		h = sea
	var surf: Vector3 = best.global_position + dir * (rad + h)
	global_position = surf + dir * 1.85
	velocity = Vector3.ZERO
	print("[SurfaceWalker] relief snap h=", h, " planet=", pid)
	return true


func _relief_floor_assist(delta: float) -> void:
	if eva_mode or _provider == null:
		return
	if not ("radius" in _provider):
		return
	var rad: float = float(_provider.radius)
	var pid: String = str(_provider.planet_name) if "planet_name" in _provider else "Nex-Prime"
	var seed_i: int = int(absi(pid.hash()) % 10000)
	var prof: Dictionary = _Relief.profile_for_planet(pid)
	var dir: Vector3 = (global_position - _provider.global_position).normalized()
	var east: Vector3 = dir.cross(Vector3.UP)
	if east.length_squared() < 1e-6:
		east = dir.cross(Vector3.RIGHT)
	east = east.normalized()
	var north: Vector3 = east.cross(dir).normalized()
	var to: Vector3 = global_position - _provider.global_position
	var h: float = float(_Relief.height_at(to.dot(east), to.dot(north), seed_i, prof))
	var sea: float = float(prof.get("sea_level", -0.35))
	if h < sea:
		h = sea
	var target_r: float = rad + h + 1.0
	var cur_r: float = to.length()
	var err: float = target_r - cur_r
	if not is_on_floor() and err < -0.3 and err > -4.0:
		global_position += dir * err * clampf(delta * 6.0, 0.0, 1.0)


var _wade_cd: float = 0.0

func _wade_splash(delta: float) -> void:
	_wade_cd = maxf(0.0, _wade_cd - delta)
	if eva_mode or _provider == null or not ("radius" in _provider):
		return
	if _wade_cd > 0.0:
		return
	var pid: String = str(_provider.planet_name) if "planet_name" in _provider else "Nex-Prime"
	var prof: Dictionary = _Relief.profile_for_planet(pid)
	var sea: float = float(prof.get("sea_level", -0.35))
	var rad: float = float(_provider.radius)
	var dir: Vector3 = (global_position - _provider.global_position).normalized()
	var east: Vector3 = dir.cross(Vector3.UP)
	if east.length_squared() < 1e-6:
		east = dir.cross(Vector3.RIGHT)
	east = east.normalized()
	var north: Vector3 = east.cross(dir).normalized()
	var to: Vector3 = global_position - _provider.global_position
	var h: float = float(_Relief.height_at(to.dot(east), to.dot(north), int(absi(pid.hash()) % 10000), prof))
	var alt_r: float = to.length() - rad
	# Near sea surface band
	if h <= sea + 0.4 and alt_r < sea + 2.5 and _move_amount > 0.15:
		_wade_cd = 0.35
		_spawn_wade_fx(dir)
		if AudioDirector and AudioDirector.has_method("play_ui"):
			AudioDirector.play_ui()


func _spawn_wade_fx(up: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.amount = 10
	p.lifetime = 0.4
	p.one_shot = true
	p.explosiveness = 0.9
	p.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.direction = up
	pm.spread = 60.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 3.5
	pm.gravity = -up * 6.0
	pm.color = Color(0.55, 0.75, 0.95, 0.7)
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	p.draw_pass_1 = sm
	add_child(p)
	p.position = Vector3(0, 0.2, 0)
	var tree := get_tree()
	if tree:
		tree.create_timer(0.55).timeout.connect(func():
			if is_instance_valid(p):
				p.queue_free()
		)


var _terrain_hint_cd: float = 0.0

func _terrain_hint_tick(delta: float) -> void:
	_terrain_hint_cd = maxf(0.0, _terrain_hint_cd - delta)
	if _terrain_hint_cd > 0.0:
		return
	if not (Input.is_physical_key_pressed(KEY_G) or Input.is_physical_key_pressed(KEY_B)):
		return
	_terrain_hint_cd = 4.0
	var tree := get_tree()
	if tree == null:
		return
	for te_node in tree.get_nodes_in_group("terrain_edit"):
		if te_node.has_method("remaining_volume"):
			var left: float = float(te_node.remaining_volume())
			for n in tree.get_nodes_in_group("game_hud"):
				if n.has_method("push_toast"):
					n.push_toast("Terrain budget left: %.0f  (G raise / B lower / U undo)" % left, 2.8)
					return
