extends RefCounted
class_name ProceduralLocomotion
## Code-first walk bob / sway for FormGLB (no skeleton required).
## Soft readability only — not combat power.

var time: float = 0.0
var move_amount: float = 0.0
var base_y: float = 0.0
var has_base: bool = false

func tick(delta: float, speed_xz: float, grounded: bool) -> void:
	var target := clampf(speed_xz / 8.0, 0.0, 1.6) if grounded else 0.0
	move_amount = lerpf(move_amount, target, clampf(delta * 8.0, 0.0, 1.0))
	time += delta * (1.0 + move_amount * 6.0)

func apply_to(visual: Node3D) -> void:
	if visual == null or not is_instance_valid(visual):
		return
	if not has_base:
		base_y = visual.position.y
		has_base = true
	var bob := sin(time * TAU) * 0.055 * clampf(move_amount, 0.0, 1.5)
	var sway := sin(time * TAU * 0.5) * 0.035 * clampf(move_amount, 0.0, 1.2)
	visual.position.y = base_y + bob
	visual.rotation.z = sway
	visual.rotation.x = -absf(sin(time * TAU)) * 0.04 * move_amount

func reset_base() -> void:
	has_base = false
