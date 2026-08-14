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
	var ai_dt := 0.12
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq:
		match int(gq.tier):
			0: ai_dt = 0.22
			1: ai_dt = 0.16
			_: ai_dt = 0.12
	if _ai_accum < ai_dt:
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
	var candidates: Array = []
	if target_player and faction == "gROT":
		var p: Node = SoftScanCache.get_player() if SoftScanCache else get_tree().get_first_node_in_group("player")
		if p:
			candidates.append(p)
	else:
		candidates = SoftScanCache.get_enemies() if SoftScanCache else get_tree().get_nodes_in_group("enemy")
	for n in candidates:
		if n == self or not is_instance_valid(n) or not (n is Node3D):
			continue
		if n.has_method("get_faction") and str(n.get_faction()) == faction:
			continue
		var d: float = global_position.distance_to((n as Node3D).global_position)
		if d < best_d:
			best = n as Node3D
			best_d = d
	return best

func _fire(target: Node3D) -> void:
	_living_fire()
	var dir: Vector3 = (target.global_position + Vector3(0, 1.0, 0) - global_position).normalized()
	var col := Color(1.0, 0.2, 0.35) if faction == "gROT" else Color(0.2, 0.8, 1.0)
	var _Pool = load("res://scripts/combat/ProjectilePool.gd")
	var spd: float = 40.0
	if "projectile_speed" in self:
		spd = float(projectile_speed)
	_Pool.spawn(get_tree(), global_position + Vector3(0, 1.4, 0) + dir * 0.8, dir, spd, damage, faction, col, 3.2)


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


func hurtbox_center() -> Vector3:
	return global_position + Vector3(0, 1.1, 0)


func hurtbox_radius() -> float:
	return 1.15

func _die() -> void:
	_alive = false
	_update_label()
	visible = false
	if SoftScanCache:
		SoftScanCache.invalidate_enemies()
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
	var fac := "grot" if faction == "gROT" else "cybernex"
	# Prefer rotating barrel HQ; fallback emplacement
	var candidates: Array = [
		"props/turret_rotating_barrel/turret_rotating_barrel_%s_lod1.glb" % fac,
		"props/turret_emplacement/turret_emplacement_%s_lod1.glb" % fac,
	]
	var path: String = ""
	for rel in candidates:
		var p: String = _AP.resolve(str(rel))
		if p != "" and FileAccess.file_exists(p):
			path = p
			break
	if path == "":
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
	var root_n := doc.generate_scene(state)
	if root_n:
		add_child(root_n)
		root_n.scale = Vector3.ONE * 0.9



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
