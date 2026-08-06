extends Node

## Moves parent Area3D projectile along its forward meta.

var direction: Vector3 = Vector3.FORWARD
var speed: float = 28.0
var life: float = 1.2

func _ready() -> void:
	var p := get_parent()
	if p and p.has_meta("direction"):
		direction = p.get_meta("direction")
	if p and p.has_meta("speed"):
		speed = p.get_meta("speed")

func _process(delta: float) -> void:
	var p := get_parent()
	if p == null:
		queue_free()
		return
	p.global_position += direction * speed * delta
	life -= delta
	if life <= 0.0:
		p.queue_free()
