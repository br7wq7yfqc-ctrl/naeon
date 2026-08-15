extends Node
## Moves parent projectile; lifetime + pool-aware cleanup.

const _Pool = preload("res://scripts/combat/ProjectilePool.gd")
const _Hits = preload("res://scripts/combat/CombatHits.gd")

var direction: Vector3 = Vector3.FORWARD
var speed: float = 28.0
var life: float = 1.4
var damage: float = 8.0
var faction: String = "Cybernex"
var _hit: bool = false
var _exclude: Array = []


func _ready() -> void:
	reset()


func reset() -> void:
	_hit = false
	_exclude = []
	var p := get_parent()
	if p == null:
		return
	if p.has_meta("direction"):
		direction = p.get_meta("direction")
	if p.has_meta("speed"):
		speed = float(p.get_meta("speed"))
	if p.has_meta("damage"):
		damage = float(p.get_meta("damage"))
	if p.has_meta("life"):
		life = float(p.get_meta("life"))
	else:
		life = 1.4
	if p.has_meta("faction"):
		faction = str(p.get_meta("faction"))
	if p.has_meta("exclude"):
		var ex = p.get_meta("exclude")
		if ex is Array:
			_exclude = ex
	set_process(true)


func _process(delta: float) -> void:
	if _hit:
		return
	var p := get_parent()
	if p == null or not is_instance_valid(p):
		queue_free()
		return
	if p is Node3D and not (p as Node3D).visible:
		return
	var dir: Vector3 = direction.normalized() if direction.length_squared() > 0.0001 else Vector3(0, 0, -1)
	var step: float = speed * delta
	if damage > 0.0:
		var hit: Node = _Hits.apply_shot(get_tree(), (p as Node3D).global_position, dir, damage, faction, step + 1.4, _exclude)
		if hit != null:
			_hit = true
			if AudioDirector:
				AudioDirector.play_hit(damage >= 20.0)
			_expire(p)
			return
	p.global_position += dir * step
	life -= delta
	if life <= 0.0:
		_expire(p)


func _expire(p: Node) -> void:
	_neon_pop()
	set_process(false)
	if p != null and is_instance_valid(p) and bool(p.get_meta("pooled", false)):
		_Pool.release(p)
	elif p != null and is_instance_valid(p):
		p.queue_free()
	else:
		queue_free()


func _neon_pop() -> void:
	var NP = load("res://scripts/fx/NeonParticles.gd")
	if NP == null or not is_inside_tree():
		return
	var host := get_parent() as Node3D
	if host == null or not host.visible:
		return
	var col := Color(0.3, 0.9, 1.0, 0.9)
	if host.has_meta("faction") and str(host.get_meta("faction")) == "gROT":
		col = Color(0.95, 0.2, 0.45, 0.9)
	NP.burst(host.global_position, col, get_tree(), 6, 5.0)
