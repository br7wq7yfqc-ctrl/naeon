extends Node
## Moves parent projectile; lifetime + pool-aware cleanup.

const _Pool = preload("res://scripts/combat/ProjectilePool.gd")

var direction: Vector3 = Vector3.FORWARD
var speed: float = 28.0
var life: float = 1.4
var damage: float = 8.0
var faction: String = "Cybernex"
var _hit: bool = false


func _ready() -> void:
	reset()


func reset() -> void:
	_hit = false
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
	p.global_position += direction.normalized() * speed * delta
	life -= delta
	if life <= 0.0:
		_expire(p)
		return
	if damage <= 0.0:
		return
	_proximity(p)


func _proximity(p: Node) -> void:
	var tree := get_tree()
	if tree == null or not (p is Node3D):
		return
	var pos: Vector3 = (p as Node3D).global_position
	var player: Node = SoftScanCache.get_player() if SoftScanCache else tree.get_first_node_in_group("player")
	if player is Node3D:
		var same := false
		if "faction" in player and str(player.faction) == faction:
			same = true
		elif player.has_method("get_faction") and str(player.get_faction()) == faction:
			same = true
		if not same and SoftScanCache.overlaps_hurtbox(pos, player, 1.15):
			_try_hit(player)
			return
	var enemies: Array = SoftScanCache.get_enemies() if SoftScanCache else tree.get_nodes_in_group("enemy")
	for e in enemies:
		if e is Node3D and is_instance_valid(e) and SoftScanCache.overlaps_hurtbox(pos, e, 1.2):
			_try_hit(e)
			return


func _try_hit(target: Node) -> void:
	if _hit or target == null:
		return
	if "faction" in target and str(target.faction) == faction:
		return
	if target.has_method("get_faction") and str(target.get_faction()) == faction:
		return
	if target.has_method("take_damage"):
		target.take_damage(damage)
		_hit = true
		if CombatJuice:
			CombatJuice.hit_feedback(damage, (target as Node3D).global_position if target is Node3D else Vector3.ZERO, damage >= 20.0)
		if AudioDirector:
			AudioDirector.play_hit(damage >= 20.0)
		_expire(get_parent())


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
