extends CharacterBody3D
class_name CombatDummy
const _AP = preload("res://scripts/assets/AssetPaths.gd")

## Trainable combat target for TestArena. Takes damage, optional aggro fire.

signal died
signal damaged(amount: float, health_left: float)

@export var max_health: float = 80.0
@export var move_speed: float = 2.2
@export var aggro_range: float = 16.0
@export var attack_range: float = 12.0
@export var attack_damage: float = 6.0
@export var attack_cooldown: float = 1.4
@export var faction: String = "gROT"
@export var respawn_time: float = 4.0
@export var can_move: bool = true

@onready var mesh: MeshInstance3D = $Mesh
@onready var label: Label3D = $Label
@onready var health_bar: Label3D = $HealthBar

var health: float = 80.0
var _cd: float = 0.0
var _alive: bool = true
var _player_cache: Node3D = null
var _ai_accum: float = 0.0
var _spawn_pos: Vector3
var _mat: StandardMaterial3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _stagger: float = 0.0

func _ready() -> void:
	health = max_health
	_spawn_pos = global_position
	collision_layer = 4  # Enemy
	collision_mask = 3   # World + Player
	add_to_group("enemy")
	add_to_group("hackable")
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.35, 0.08, 0.14)
	_mat.metallic = 0.45
	_mat.roughness = 0.4
	_mat.emission_enabled = true
	_mat.emission = Color(0.9, 0.1, 0.35)
	_mat.emission_energy_multiplier = 1.2
	if mesh:
		mesh.material_override = _mat
	_update_labels()
	call_deferred("try_load_drone")

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_stagger = maxf(0.0, _stagger - delta)
	_cd = max(0.0, _cd - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta

	_ai_accum += delta
	var ai_need := 0.1
	if not can_move:
		ai_need = 0.28  # static lane holds — rare retarget
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and int(gq.tier) == 0:
		ai_need *= 1.6
	var do_ai := _ai_accum >= ai_need
	if do_ai:
		_ai_accum = 0.0
	var player := _find_player() if do_ai or _player_cache == null else _player_cache
	# Far culling: no move/look when far from player (still take damage)
	if player and global_position.distance_squared_to(player.global_position) > 55.0 * 55.0:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	if player and can_move:
		var to_p: Vector3 = player.global_position - global_position
		to_p.y = 0.0
		var dist: float = to_p.length()
		if dist < aggro_range and dist > 1.6:
			var dir: Vector3 = to_p.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			look_at(global_position + dir, Vector3.UP)
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed)
			velocity.z = move_toward(velocity.z, 0.0, move_speed)
		if dist <= attack_range and _cd <= 0.0:
			_fire_at(player)
			_cd = attack_cooldown
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()

func take_damage(amount: float) -> void:
	if CombatJuice:
		var crit := amount >= max_health * 0.35 or amount >= 25.0
		CombatJuice.hit_feedback(float(amount), global_position + Vector3(0, 1.2, 0), crit)
	if not _alive:
		return
	health = max(0.0, health - amount)
	damaged.emit(amount, health)
	_stagger = maxf(_stagger, 0.18 + minf(amount * 0.012, 0.35))
	_flash()
	_hit_pop(amount)
	_update_labels()
	if health <= 0.0:
		_die()

func on_hacked(caster: Node, amount: float = 1.0) -> void:
	take_damage(amount * 1.5)
	# Partial claim visual toward caster faction
	if _mat and caster and caster.has_method("get_faction"):
		var f: String = caster.get_faction()
		if f == "Cybernex":
			_mat.emission = _mat.emission.lerp(Color(0.15, 0.85, 1.0), 0.35)
		else:
			_mat.emission = _mat.emission.lerp(Color(0.95, 0.12, 0.42), 0.35)

func get_faction() -> String:
	return faction


func hurtbox_center() -> Vector3:
	return global_position + Vector3(0, 0.85, 0)


func hurtbox_radius() -> float:
	return 0.95

func _die() -> void:
	if CombatJuice:
		CombatJuice.hit_feedback(max_health, global_position + Vector3(0, 1.2, 0), true)
	_alive = false
	died.emit()
	if SoftScanCache:
		SoftScanCache.invalidate_enemies()
	if CombatJuice:
		CombatJuice.kill_pop(global_position)
	visible = false
	collision_layer = 0
	velocity = Vector3.ZERO
	if GameManager:
		GameManager.add_contribution(2.5)
		GameManager.add_mastery("combat", 1.5)
	print("[CombatDummy] Downed")
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn() -> void:
	health = max_health
	_alive = true
	visible = true
	collision_layer = 4
	global_position = _spawn_pos
	velocity = Vector3.ZERO
	if _mat:
		_mat.emission = Color(0.9, 0.1, 0.35)
	_update_labels()
	if SoftScanCache:
		SoftScanCache.invalidate_enemies()
	print("[CombatDummy] Respawned")

func _fire_at(player: Node) -> void:
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)
	var target_pos: Vector3 = player.global_position + Vector3.UP * 1.2
	var origin: Vector3 = global_position + Vector3.UP * 1.2
	var dir: Vector3 = (target_pos - origin).normalized()
	var _Pool = load("res://scripts/combat/ProjectilePool.gd")
	_Pool.spawn(get_tree(), origin, dir, 18.0, 0.0, "gROT", Color(1.0, 0.2, 0.4), 0.7)


func _find_player() -> Node3D:
	if _player_cache != null and is_instance_valid(_player_cache):
		return _player_cache
	var tree := get_tree()
	if tree == null:
		return null
	# Prefer group once
	if SoftScanCache:
		var sp = SoftScanCache.get_player()
		if sp is Node3D:
			_player_cache = sp as Node3D
			return _player_cache
	var nodes := tree.get_nodes_in_group("player")
	if nodes.size() > 0 and nodes[0] is Node3D:
		_player_cache = nodes[0]
		return _player_cache
	for n in tree.get_nodes_in_group("players"):
		if n is Node3D:
			_player_cache = n
			return _player_cache
	# Fallback once expensive scan
	var scene := tree.current_scene
	if scene:
		for c in scene.get_children():
			if c is CharacterBody3D and c != self and c.has_method("take_damage"):
				_player_cache = c
				return _player_cache
	return null


func _flash() -> void:
	if _mat == null:
		return
	var orig: Color = _mat.albedo_color
	_mat.albedo_color = Color(1, 1, 1)
	get_tree().create_timer(0.07).timeout.connect(func():
		if is_instance_valid(self) and _mat:
			_mat.albedo_color = orig
	)

func _update_labels() -> void:
	if label:
		label.text = "Dummy | %s" % faction
	if health_bar:
		health_bar.text = "HP %d/%d" % [int(health), int(max_health)]

func try_load_drone() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var path: String = _AP.resolve("characters/grot_infector/grot_infector_grot_lod0.glb")
	if not FileAccess.file_exists(path):
		path = _AP.resolve("characters/grot_thrall/grot_thrall_grot_lod0.glb")
	if not FileAccess.file_exists(path):
		return
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return
	var root := doc.generate_scene(state)
	if root == null:
		return
	if mesh:
		mesh.visible = false
	add_child(root)
	root.name = "DroneGLB"
	root.scale = Vector3.ONE * 0.9
	print("[CombatDummy] drone mesh loaded")



func _hit_pop(amount: float) -> void:
	if mesh == null or not is_instance_valid(mesh):
		return
	var base := mesh.scale
	var tw := get_tree().create_tween()
	tw.tween_property(mesh, "scale", base * 1.12, 0.05)
	tw.tween_property(mesh, "scale", base, 0.12)
	if _mat:
		_mat.emission_energy_multiplier = 2.8 if amount >= 20.0 else 1.8
		get_tree().create_timer(0.1).timeout.connect(func():
			if is_instance_valid(self) and _mat:
				_mat.emission_energy_multiplier = 1.2
		)
