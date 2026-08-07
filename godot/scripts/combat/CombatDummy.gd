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
var _spawn_pos: Vector3
var _mat: StandardMaterial3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

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
	_cd = max(0.0, _cd - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta

	var player := _find_player()
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
	_flash()
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

func _die() -> void:
	if CombatJuice:
		CombatJuice.hit_feedback(max_health, global_position + Vector3(0, 1.2, 0), true)
	_alive = false
	died.emit()
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
	print("[CombatDummy] Respawned")

func _fire_at(player: Node) -> void:
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)
	# Simple muzzle flash
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.24
	ball.mesh = sm
	var m := StandardMaterial3D.new()
	m.emission_enabled = true
	m.emission = Color(1.0, 0.2, 0.4)
	m.emission_energy_multiplier = 3.0
	ball.material_override = m
	get_tree().current_scene.add_child(ball)
	ball.global_position = global_position + Vector3.UP * 1.2
	var target_pos: Vector3 = player.global_position + Vector3.UP * 1.2
	var dir: Vector3 = (target_pos - ball.global_position).normalized()
	var t := 0.0
	var runner := Node.new()
	ball.add_child(runner)
	runner.set_script(load("res://scripts/abilities/ProjectileRunner.gd"))
	ball.set_meta("direction", dir)
	ball.set_meta("speed", 18.0)
	# Damage on proximity via Area is overkill; already applied hit-scan style once

func _find_player() -> Node:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		return nodes[0]
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

