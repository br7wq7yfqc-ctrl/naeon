extends Node3D
class_name Turret
const _AP = preload("res://scripts/assets/AssetPaths.gd")

## Hostile / friendly turret using generated emplacement mesh.

signal killed_target

var _ai_accum: float = 0.0
var faction: String = "gROT"
@export var aggro_range: float = 18.0
@export var fire_rate: float = 1.1
@export var damage: float = 8.0
@export var projectile_speed: float = 42.0
@export var max_health: float = 120.0
@export var target_player: bool = true

var health: float = 120.0
var _cd: float = 0.0
var _alive: bool = true
var _label: Label3D
var _barrel: Node3D

func _ready() -> void:
	_ensure_animator()
	health = max_health
	add_to_group("enemy" if faction == "gROT" else "ally")
	add_to_group("hackable")
	_load_mesh()
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 22
	_label.position = Vector3(0, 2.2, 0)
	add_child(_label)
	_update_label()
	set_process(true)

func _process(delta: float) -> void:
	_ai_accum += delta
	if _ai_accum < 0.12:
		return
	_ai_accum = 0.0
	if not _alive:
		return
	_cd = max(0.0, _cd - delta)
	var target := _find_target()
	if target == null:
		return
	# yaw toward target
	var to: Vector3 = target.global_position - global_position
	to.y = 0.0
	if to.length() > 0.1:
		_living_aim(target.global_position, 0.12)
		look_at(global_position + to.normalized(), Vector3.UP)
	if _cd <= 0.0 and global_position.distance_to(target.global_position) <= aggro_range:
		_fire(target)
		_cd = fire_rate

func _find_target() -> Node3D:
	var best: Node3D = null
	var best_d: float = aggro_range
	var groups: Array = ["player"] if target_player and faction == "gROT" else ["enemy"]
	if faction == "Cybernex":
		groups = ["enemy"]
	for g in groups:
		for n in get_tree().get_nodes_in_group(g):
			if n == self or not is_instance_valid(n):
				continue
			if n is Node3D:
				var d: float = global_position.distance_to((n as Node3D).global_position)
				if d < best_d:
					# faction filter
					if n.has_method("get_faction") and str(n.get_faction()) == faction:
						continue
					best = n as Node3D
					best_d = d
	# also CharacterBody3D player without group
	if best == null and target_player and faction == "gROT":
		var p := get_tree().get_first_node_in_group("player")
		if p is Node3D:
			var d2: float = global_position.distance_to((p as Node3D).global_position)
			if d2 <= aggro_range:
				best = p as Node3D
	return best

func _fire(target: Node3D) -> void:
	_living_fire()
	var bolt := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	bolt.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.35) if faction == "gROT" else Color(0.2, 0.8, 1.0)
	mat.emission_energy_multiplier = 3.0
	bolt.material_override = mat
	var dir: Vector3 = (target.global_position + Vector3(0, 1.0, 0) - global_position).normalized()
	get_tree().current_scene.add_child(bolt)
	bolt.global_position = global_position + Vector3(0, 1.4, 0) + dir * 0.8
	bolt.set_meta("direction", dir)
	bolt.set_meta("speed", projectile_speed)
	bolt.set_meta("damage", damage)
	bolt.set_meta("faction", faction)
	var runner := Node.new()
	runner.set_script(preload("res://scripts/abilities/ProjectileRunner.gd"))
	# Prefer enemy-aware runner if available
	if ResourceLoader.exists("res://scripts/combat/TurretProjectile.gd"):
		runner.set_script(load("res://scripts/combat/TurretProjectile.gd"))
	bolt.add_child(runner)

func take_damage(amount: float) -> void:
	if not _alive:
		return
	health = max(0.0, health - amount)
	_update_label()
	if health <= 0.0:
		_die()

func on_hacked(caster: Node, amount: float = 1.0) -> void:
	take_damage(amount * 8.0)
	if caster and caster.has_method("get_faction"):
		faction = str(caster.get_faction())
		target_player = faction == "gROT"
		_update_label()

func get_faction() -> String:
	return faction

func _die() -> void:
	_alive = false
	_update_label()
	visible = false
	await get_tree().create_timer(5.0).timeout
	health = max_health
	_alive = true
	visible = true
	_update_label()

func _update_label() -> void:
	if _label:
		if not _alive:
			_label.text = "TURRET DESTROYED"
		else:
			_label.text = "TURRET %s\nHP %.0f" % [faction, health]

func _load_mesh() -> void:
	var rel := "props/turret_emplacement/turret_emplacement_grot_lod1.glb"
	if faction == "Cybernex":
		rel = "props/turret_emplacement/turret_emplacement_cybernex_lod1.glb"
	var path: String = _AP.resolve(rel)
	if not FileAccess.file_exists(path):
		# placeholder
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 1.0, 1.2)
		mi.mesh = box
		add_child(mi)
		return
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return
	var root := doc.generate_scene(state)
	if root:
		add_child(root)
		root.scale = Vector3.ONE * 0.9



var _anim: Node = null


func _ensure_animator() -> void:
	if _anim:
		return
	_anim = Node.new()
	_anim.set_script(load("res://scripts/combat/TurretAnimator.gd"))
	_anim.name = "TurretAnimator"
	add_child(_anim)
	var fac := str(faction) if "faction" in self else "Cybernex"
	if _anim.has_method("setup"):
		_anim.setup(self, fac)


func _living_aim(target: Vector3, delta: float) -> void:
	if _anim and _anim.has_method("aim_at"):
		_anim.aim_at(target, delta)


func _living_fire() -> void:
	if _anim and _anim.has_method("fire_kick"):
		_anim.fire_kick()
