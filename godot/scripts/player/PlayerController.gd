extends CharacterBody3D
const _AP = preload("res://scripts/assets/AssetPaths.gd")
const _HeroForms = preload("res://scripts/player/HeroFormCatalog.gd")
const _MeshOrient = preload("res://scripts/assets/MeshOrient.gd")
const _FormAnim = preload("res://scripts/player/FormAnimator.gd")
const _FormFX = preload("res://scripts/player/FormSwitchFX.gd")
var _form_skel: Skeleton3D = null
const _ProcLoco = preload("res://scripts/player/ProceduralLocomotion.gd")
const _ProcSil = preload("res://scripts/player/ProceduralHeroSilhouette.gd")

## TPS controller — robust WASD (InputMap + physical/keycode fallback).

const FORMS := ["Canine", "Feline", "Avian", "Human"]

@export var move_speed: float = 8.0
@export var sprint_multiplier: float = 1.6
@export var jump_velocity: float = 6.5
@export var mouse_sensitivity: float = 0.0028
@export var max_health: float = 100.0
@export var max_energy: float = 100.0
@export var energy_regen: float = 8.0
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
var last_move_input: Vector2 = Vector2.ZERO
var _loco = null
var _coyote_t: float = 0.0
var _jump_buf_t: float = 0.0
var _jump_cut: bool = false
var _jumped: bool = false
var _down_t: float = 0.0
var _spawn_pos: Vector3 = Vector3(0, 1.2, 6)

func _ready() -> void:
	health = max_health
	energy = max_energy
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1  # world only — don't jam on enemy layer oddities
	floor_snap_length = 0.2
	# Capture mouse so look + window focus work on first click too
	call_deferred("_ensure_input_ready")
	call_deferred("_capture_spawn")
	_body_mat = StandardMaterial3D.new()
	_body_mat.albedo_color = Color(0.08, 0.12, 0.18)
	_body_mat.metallic = 0.6
	_body_mat.roughness = 0.3
	_body_mat.emission_enabled = true
	if body_mesh:
		body_mesh.material_override = _body_mat
	if ability_system:
		ability_system.setup_default_loadout(faction)
		if not ability_system.ability_activated.is_connected(_on_ability_activated):
			ability_system.ability_activated.connect(_on_ability_activated)
	_apply_form_stats()
	_ensure_infection()
	call_deferred("_ensure_channel_hooks")
	_ensure_hud()
	print("[Player] Ready form=", current_form, " faction=", faction)
	if SoftSession:
		SoftSession.apply_to_player(self)
	_loco = _ProcLoco.new()
	if SoftNetSession:
		SoftNetSession.bind_player(self)
	print("[Player] InputMap move_forward=", InputMap.has_action("move_forward"))


func hurtbox_center() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)


func hurtbox_radius() -> float:
	return 0.9

func _ensure_input_ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Re-assert focus for exported .app on macOS
	if get_viewport():
		get_viewport().gui_release_focus()

func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F10 or event.physical_keycode == KEY_F10:
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
	# Click to re-capture (exported Mac apps often start without focus)
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		if camera_pivot:
			camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
			camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		# Consume it: TestArena also listens for Esc and would abandon the match.
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if firewall_timer > 0.0:
		firewall_timer = max(0.0, firewall_timer - delta)
	energy = min(max_energy, energy + energy_regen * _infection_energy_mult() * delta)

	if _down_t > 0.0:
		_down_t = maxf(0.0, _down_t - delta)
		if not is_on_floor():
			velocity.y -= gravity * delta
		velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)
		move_and_slide()
		if _down_t <= 0.0:
			_respawn()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
		_coyote_t = maxf(0.0, _coyote_t - delta)
	else:
		_coyote_t = 0.12
		_jump_cut = false
		_jumped = false
	if _pressed_jump():
		_jump_buf_t = 0.1
	else:
		_jump_buf_t = maxf(0.0, _jump_buf_t - delta)
	if _jump_buf_t > 0.0 and _coyote_t > 0.0:
		velocity.y = jump_velocity
		_jump_buf_t = 0.0
		_coyote_t = 0.0
		_jump_cut = false
		_jumped = true
	var jump_held := (InputMap.has_action("jump") and Input.is_action_pressed("jump")) \
		or Input.is_physical_key_pressed(KEY_SPACE)
	# Variable height — only for a jump the player asked for, never for knockback.
	if _jumped and not is_on_floor() and not jump_held and not _jump_cut and velocity.y > 2.2:
		velocity.y *= 0.42
		_jump_cut = true

	var input_dir: Vector2 = _read_move_vector()
	last_move_input = input_dir
	# Local space: -Z forward (Godot default)
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y))
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
	else:
		direction = Vector3.ZERO

	var speed: float = move_speed
	if _pressed_sprint():
		speed *= sprint_multiplier
	if current_form == "Avian" and not is_on_floor():
		velocity.y += 2.5 * delta
		speed *= 1.1

	var accel := 28.0 if is_on_floor() else 12.0
	var decel := 36.0 if is_on_floor() else 6.0
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * speed, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
		velocity.z = move_toward(velocity.z, 0.0, decel * delta)

	move_and_slide()
	if last_move_input.length_squared() > 0.01 and SessionObjectives:
		SessionObjectives.on_moved()
	if _form_skel:
		var ma := velocity.length() / maxf(speed, 0.01) if "speed" in self else velocity.length() * 0.1
		_FormAnim.apply_locomotion(_form_skel, ma, Time.get_ticks_msec() * 0.001, is_on_floor())
	_update_locomotion(delta)

	if _just_ability(1):
		if ability_system and _down_t <= 0.0:
			ability_system.try_activate(0)
	if _just_ability(2):
		if ability_system and _down_t <= 0.0:
			ability_system.try_activate(1)
	if _just_ability(3):
		if ability_system and _down_t <= 0.0:
			ability_system.try_activate(2)
	if _just_ability(4):
		if _down_t <= 0.0:
			cycle_form()


## Robust WASD: InputMap first, then physical keys + keycodes + arrows.
func _read_move_vector() -> Vector2:
	var v := Vector2.ZERO
	if InputMap.has_action("move_left") and InputMap.has_action("move_right") \
			and InputMap.has_action("move_forward") and InputMap.has_action("move_back"):
		v = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Fallback if InputMap silent (export / focus issues)
	if v.length_squared() < 0.0001:
		if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A):
			v.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D):
			v.x += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W):
			v.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S):
			v.y += 1.0
		if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_LEFT):
			v.x -= 1.0
		if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_RIGHT):
			v.x += 1.0
		if Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_UP):
			v.y -= 1.0
		if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_DOWN):
			v.y += 1.0
	if v.length_squared() > 1.0:
		v = v.normalized()
	return v

func _pressed_jump() -> bool:
	if InputMap.has_action("jump") and Input.is_action_just_pressed("jump"):
		return true
	return false

func _pressed_sprint() -> bool:
	if InputMap.has_action("sprint") and Input.is_action_pressed("sprint"):
		return true
	return Input.is_physical_key_pressed(KEY_SHIFT)

func _just_ability(n: int) -> bool:
	var action := "ability_%d" % n
	if InputMap.has_action(action) and Input.is_action_just_pressed(action):
		return true
	return false

func cycle_form() -> void:
	var forms: PackedStringArray = _HeroForms.forms_for_faction(faction)
	_form_index = (_form_index + 1) % forms.size()
	switch_form(forms[_form_index])
	_form_switch_fx()

func switch_form(new_form: String) -> void:
	current_form = new_form
	_apply_form_stats()
	print("[Player] Form → ", current_form)

func _apply_form_stats() -> void:
	var prof: Dictionary = _HeroForms.apply_soft_mobility(current_form)
	move_speed = float(prof.get("move", 8.0))
	jump_velocity = float(prof.get("jump", 6.5))
	sprint_multiplier = float(prof.get("sprint", 1.5))
	if _body_mat:
		_body_mat.emission = prof.get("emit", Color(0.5, 0.7, 0.9))
		_body_mat.emission_energy_multiplier = 1.6
	if form_label:
		form_label.text = "%s | %s" % [current_form, faction]
		form_label.visible = false
	call_deferred("try_load_form_mesh")

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
	if _down_t > 0.0:
		return
	if firewall_timer > 0.0:
		amount *= 0.35
	# Feedback after mitigation — else Firewall looks like it does nothing.
	if CombatJuice:
		CombatJuice.hit_feedback(float(amount), global_position)
	health = max(0.0, health - amount)
	if CombatJuice:
		CombatJuice.damage_taken(amount)
	# Interrupt own channel on any damage (Hack is fully interruptible)
	var ch = get_node_or_null("ChannelController")
	if ch and ch.has_method("notify_damage"):
		ch.notify_damage()
	if health <= 0.0:
		_begin_down()

func apply_firewall(duration: float, heal_amount: float = 0.0) -> void:
	firewall_timer = max(firewall_timer, duration)
	var inf = get_node_or_null("InfectionStatus")
	if inf and inf.has_method("cleanse"):
		# rules/04: Nex Barrier removes all Infection stacks (up to 5)
		inf.cleanse(5)
	if heal_amount > 0.0:
		heal(heal_amount)
	_firewall_break_nearby_channels()

func _firewall_break_nearby_channels() -> void:
	# Soft interrupt: Firewall pulse breaks nearby enemy channels (readability counterplay)
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("channel_controllers"):
		if n == null or not is_instance_valid(n):
			continue
		if n.has_method("interrupt"):
			var owner_n = n.get_parent()
			if owner_n is Node3D and global_position.distance_to((owner_n as Node3D).global_position) < 18.0:
				n.interrupt("firewall")
		elif n.has_method("cancel"):
			n.cancel()

func _capture_spawn() -> void:
	_spawn_pos = global_position


func is_downed() -> bool:
	return _down_t > 0.0


func _begin_down() -> void:
	if _down_t > 0.0:
		return
	_down_t = 0.7
	health = 0.0
	velocity *= 0.35
	var ch = get_node_or_null("ChannelController")
	if ch and ch.has_method("interrupt"):
		ch.interrupt("downed")
	var tree := get_tree()
	if tree:
		var md = tree.get_first_node_in_group("clash_match")
		if md and md.has_method("register_death"):
			md.register_death()
	if GameManager:
		GameManager.toast_requested.emit("DOWN — returning to nexus")
	print("[Player] Down")


func _respawn() -> void:
	health = max_health
	energy = max_energy
	_down_t = 0.0
	global_position = _spawn_pos
	velocity = Vector3.ZERO
	print("[Player] Respawned")

func _on_ability_activated(ability: Ability) -> void:
	if ability and ability.ability_name == "Form Cycle":
		cycle_form()


func _infection_energy_mult() -> float:
	var inf = get_node_or_null("InfectionStatus")
	if inf and inf.has_method("energy_regen_mult"):
		return float(inf.energy_regen_mult())
	return 1.0

func _ensure_channel_hooks() -> void:
	var ch = get_node_or_null("ChannelController")
	if ch == null:
		return
	if ch.has_signal("channel_interrupted") and not ch.channel_interrupted.is_connected(_on_channel_interrupted):
		ch.channel_interrupted.connect(_on_channel_interrupted)

func _on_channel_interrupted(reason: String) -> void:
	# Soft feedback — partial energy already spent (design: interruptible cost risk)
	print("[Player] channel interrupted: ", reason)

func _ensure_infection() -> void:
	if get_node_or_null("InfectionStatus") == null:
		var n := Node.new()
		n.set_script(preload("res://scripts/abilities/InfectionStatus.gd"))
		n.name = "InfectionStatus"
		add_child.call_deferred(n)

func _ensure_hud() -> void:
	if get_tree() == null:
		return
	var existing = get_tree().get_first_node_in_group("game_hud")
	if existing:
		if existing.has_method("bind_player"):
			existing.bind_player(self)
		return
	var hud := CanvasLayer.new()
	hud.set_script(preload("res://scripts/ui/GameHUD.gd"))
	hud.name = "GameHUD"
	hud.add_to_group("game_hud")
	get_tree().current_scene.add_child.call_deferred(hud)
	if hud.has_method("bind_player"):
		hud.bind_player(self)

func on_hacked(caster: Node, amount: float = 1.0) -> void:
	var inf = get_node_or_null("InfectionStatus")
	if inf and inf.has_method("add_stacks"):
		inf.add_stacks(2 if amount >= 1.0 else 1)
	# minor damage
	take_damage(amount * 2.0)

func try_load_form_mesh() -> void:
	# Wave C: dual-theme GLB by faction + LOD/clean fallbacks (HeroFormCatalog)
	var path := ""
	for rel in _HeroForms.mesh_candidates(current_form, faction):
		var p: String = _AP.resolve(rel)
		if p != "" and FileAccess.file_exists(p):
			path = p
			break
	if path == "":
		_clear_form_glb()
		if DisplayServer.get_name() != "headless":
			_ProcSil.attach(self, current_form, faction, false)
			if body_mesh:
				body_mesh.visible = false
		elif body_mesh:
			body_mesh.visible = true
		if _loco:
			_loco.reset_base()
		return
	_clear_form_glb()
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		if DisplayServer.get_name() != "headless":
			_ProcSil.attach(self, current_form, faction, false)
			if body_mesh:
				body_mesh.visible = false
		elif body_mesh:
			body_mesh.visible = true
		if _loco:
			_loco.reset_base()
		return
	var root := doc.generate_scene(state)
	if root == null:
		return
	_strip_colliders(root)
	if body_mesh:
		body_mesh.visible = false
	root.name = "FormGLB"
	_MeshOrient.face_neg_z(root as Node3D, true)
	add_child.call_deferred(root)
	root.scale = Vector3.ONE * 0.85
	root.position = Vector3(0, 0, 0)
	print("[Player] form mesh ", current_form, "/", faction, " -> ", path)
	if _loco:
		_loco.reset_base()


func _update_locomotion(delta: float) -> void:
	if _loco == null:
		return
	var spd := Vector2(velocity.x, velocity.z).length()
	_loco.tick(delta, spd, is_on_floor())
	var visual: Node3D = get_node_or_null("FormGLB") as Node3D
	if visual == null and body_mesh:
		visual = body_mesh
	_loco.apply_to(visual)


func _form_switch_fx() -> void:
	# Soft VFX pulse + ring — readable form change, no combat power
	if _body_mat:
		_body_mat.emission_energy_multiplier = 4.0
	_FormFX.play_at(self, faction, current_form)
	if GameManager:
		GameManager.toast_requested.emit("Hero form → %s (%s) · soft mobility only" % [current_form, faction])
	if SoftSession:
		SoftSession.remember_player(self)
	var tw := get_tree().create_timer(0.35)
	tw.timeout.connect(func():
		if _body_mat:
			_body_mat.emission_energy_multiplier = 1.6
	)

func _strip_colliders(n: Node) -> void:
	# Remove StaticBody/CollisionShape so form mesh never freezes CharacterBody3D
	for c in n.get_children():
		_strip_colliders(c)
	if n is CollisionShape3D or n is CollisionPolygon3D:
		n.queue_free()
	elif n is StaticBody3D or n is RigidBody3D or n is CharacterBody3D or n is AnimatableBody3D:
		# keep mesh children, free body itself after reparent meshes? simpler: disable
		n.set("collision_layer", 0)
		n.set("collision_mask", 0)
		if n is RigidBody3D:
			(n as RigidBody3D).freeze = true

func _clear_form_glb() -> void:
	var old := get_node_or_null("FormGLB")
	if old:
		old.name = "_FormGLBDead"
		old.queue_free()
