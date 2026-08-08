extends Node
## Moves parent projectile; optional Area3D damage; lifetime + layer-safe cleanup.

var direction: Vector3 = Vector3.FORWARD
var speed: float = 28.0
var life: float = 1.4
var damage: float = 8.0
var faction: String = "Cybernex"
var _hit: bool = false


func _ready() -> void:
	var p := get_parent()
	if p == null:
		queue_free()
		return
	if p.has_meta("direction"):
		direction = p.get_meta("direction")
	if p.has_meta("speed"):
		speed = float(p.get_meta("speed"))
	if p.has_meta("damage"):
		damage = float(p.get_meta("damage"))
	if p.has_meta("life"):
		life = float(p.get_meta("life"))
	if p.has_meta("faction"):
		faction = str(p.get_meta("faction"))
	# Ensure damage volume
	if p is Area3D:
		var a := p as Area3D
		a.monitoring = true
		a.monitorable = false
		a.collision_layer = 0
		a.collision_mask = 1 | 2 | 4  # world + actors + enemies
		if not a.body_entered.is_connected(_on_body):
			a.body_entered.connect(_on_body)
		if not a.area_entered.is_connected(_on_area):
			a.area_entered.connect(_on_area)
		if a.get_node_or_null("HitShape") == null:
			var cs := CollisionShape3D.new()
			cs.name = "HitShape"
			var sh := SphereShape3D.new()
			sh.radius = 0.35
			cs.shape = sh
			a.add_child(cs)


func _process(delta: float) -> void:
	if _hit:
		return
	var p := get_parent()
	if p == null or not is_instance_valid(p):
		queue_free()
		return
	p.global_position += direction.normalized() * speed * delta
	life -= delta
	if life <= 0.0:
		_expire(p)


func _on_body(body: Node) -> void:
	_try_hit(body)


func _on_area(area: Node) -> void:
	_try_hit(area)


func _try_hit(target: Node) -> void:
	if _hit or target == null:
		return
	# Skip same faction ships/players
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
		var p := get_parent()
		_expire(p)


func _expire(p: Node) -> void:
	if p and is_instance_valid(p):
		p.queue_free()
	else:
		queue_free()


func _neon_pop() -> void:
	var NP = load("res://scripts/fx/NeonParticles.gd")
	if NP == null or not is_inside_tree():
		return
	var host := get_parent() as Node3D
	if host == null:
		return
	var col := Color(0.3, 0.9, 1.0, 0.9)
	if host.has_meta("faction") and str(host.get_meta("faction")) == "gROT":
		col = Color(0.95, 0.2, 0.45, 0.9)
	NP.burst(host.global_position, col, get_tree(), 6, 5.0)
