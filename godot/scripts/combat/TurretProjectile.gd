extends Node

## Moves parent mesh as projectile; damages player/enemies by faction.

var lifetime: float = 3.5
var _t: float = 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	var p: Node3D = get_parent() as Node3D
	if p == null:
		queue_free()
		return
	_t += delta
	if _t > lifetime:
		p.queue_free()
		return
	var dir: Vector3 = p.get_meta("direction", Vector3.FORWARD)
	var speed: float = float(p.get_meta("speed", 40.0))
	p.global_position += dir * speed * delta
	var dmg: float = float(p.get_meta("damage", 5.0))
	var fac: String = str(p.get_meta("faction", "gROT"))
	# hit player
	var player := get_tree().get_first_node_in_group("player")
	if player is Node3D and fac == "gROT":
		if p.global_position.distance_to((player as Node3D).global_position) < 1.1:
			if player.has_method("take_damage"):
				player.take_damage(dmg)
			p.queue_free()
			return
	# hit enemies for Cybernex turrets
	if fac == "Cybernex":
		for e in get_tree().get_nodes_in_group("enemy"):
			if e is Node3D and p.global_position.distance_to((e as Node3D).global_position) < 1.2:
				if e.has_method("take_damage"):
					e.take_damage(dmg)
				p.queue_free()
				return
