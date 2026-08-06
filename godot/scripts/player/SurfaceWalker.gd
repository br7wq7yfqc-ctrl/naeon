extends CharacterBody3D
const _HeroForms = preload("res://scripts/player/HeroFormCatalog.gd")
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
var _leg_l: MeshInstance3D
var _leg_r: MeshInstance3D
var _arm_l: MeshInstance3D
var _arm_r: MeshInstance3D
var _limb_rig: Node3D
var _move_amount: float = 0.0
var _up: Vector3 = Vector3.UP
var cam_pivot: Node3D
var camera: Camera3D

func set_planet_gravity_provider(p: Node) -> void:
	_provider = p

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.45
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
	return 100.0

func on_hacked(caster: Node, amount: float = 1.0) -> void:
	var inf = get_node_or_null("InfectionStatus")
	if inf and inf.has_method("add_stacks"):
		inf.add_stacks(2)

func snap_to_surface() -> void:
	_update_up()
	# Raycast along gravity to find ground
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	var origin := global_position + _up * 8.0
	var end := global_position - _up * 40.0
	var q := PhysicsRayQueryParameters3D.create(origin, end)
	q.collision_mask = 1
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit:
		global_position = hit.position + _up * 1.05
		velocity = Vector3.ZERO
		print("[SurfaceWalker] snapped to ", hit.position)
	else:
		# Fallback: push up along pad
		global_position += _up * 2.0
		print("[SurfaceWalker] no hit — boost along up")

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
		elif event.keycode == KEY_R:
			_try_ability(2)
		# G/B terrain edit handled by PlanetTerrainEdit while in player group
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

func _physics_process(delta: float) -> void:
	_update_up()
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

	# Movement plane = perpendicular to planet up; yaw around planet up
	var forward := (-_basis_from_up().z)
	var right := _basis_from_up().x
	forward = (forward - _up * forward.dot(_up)).normalized()
	right = (right - _up * right.dot(_up)).normalized()
	var wish := right * input.x + forward * (-input.y)
	var sp := speed * (sprint_mult if Input.is_physical_key_pressed(KEY_SHIFT) else 1.0) * _infection_move_mult()
	var planar := wish * sp
	_move_amount = planar.length() / maxf(speed, 0.01)

	# Gravity integrate along up
	var v_up := velocity.dot(_up)
	if not is_on_floor():
		v_up += g_vec.dot(_up) * delta  # g_vec points down (to center)
	else:
		v_up = minf(v_up, 0.0)
		if Input.is_physical_key_pressed(KEY_SPACE):
			v_up = jump_velocity
			_spawn_jump_fx()

	velocity = planar + _up * v_up
	_apply_body_basis()
	move_and_slide()
	# Stick to floor
	if is_on_floor():
		apply_floor_snap()

	_update_anim(delta)

func _basis_from_up() -> Basis:
	var up := _up.normalized()
	# yaw around up
	var f0 := Vector3.FORWARD
	if absf(up.dot(f0)) > 0.95:
		f0 = Vector3.RIGHT
	var right := up.cross(f0).normalized()
	var forward := right.cross(up).normalized()
	# rotate by yaw around up
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
