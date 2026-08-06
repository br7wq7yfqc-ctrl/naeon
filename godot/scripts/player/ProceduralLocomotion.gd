extends RefCounted
class_name ProceduralLocomotion
## Code-first locomotion for static GLBs (no skins/animations in Tripo exports).
## Soft readability only — not combat power.

var time: float = 0.0
var move_amount: float = 0.0
var base_y: float = 0.0
var has_base: bool = false
var idle_amp: float = 0.012

func tick(delta: float, speed_xz: float, grounded: bool) -> void:
	var target := 0.0
	if grounded:
		target = clampf(speed_xz / 8.0, 0.0, 1.6)
	move_amount = lerpf(move_amount, target, clampf(delta * 8.0, 0.0, 1.0))
	var rate := 1.0 + move_amount * 6.0
	if move_amount < 0.05:
		rate = 0.85
	time += delta * rate

func apply_to(visual: Node3D) -> void:
	if visual == null or not is_instance_valid(visual):
		return
	if not has_base:
		base_y = visual.position.y
		has_base = true
	var walk := clampf(move_amount, 0.0, 1.5)
	var bob: float
	var sway: float
	var lean: float
	if walk < 0.08:
		bob = sin(time * TAU * 0.35) * idle_amp
		sway = sin(time * TAU * 0.2) * 0.008
		lean = 0.0
	else:
		bob = sin(time * TAU) * 0.055 * walk
		sway = sin(time * TAU * 0.5) * 0.04 * walk
		lean = -absf(sin(time * TAU)) * 0.05 * walk
	visual.position.y = base_y + bob
	visual.rotation.z = sway
	visual.rotation.x = lean
	_apply_child_phase(visual, walk)

func _apply_child_phase(visual: Node3D, walk: float) -> void:
	if walk < 0.05:
		return
	var i := 0
	for c in visual.get_children():
		if c is MeshInstance3D:
			_phase_mesh(c as MeshInstance3D, i, walk)
			i += 1
		elif c is Node3D:
			for c2 in c.get_children():
				if c2 is MeshInstance3D:
					_phase_mesh(c2 as MeshInstance3D, i, walk)
					i += 1
		if i > 6:
			break

func _phase_mesh(mi: MeshInstance3D, idx: int, walk: float) -> void:
	var phase := time * TAU + float(idx) * 0.7
	var sign := 1.0 if idx % 2 == 0 else -1.0
	mi.rotation.x = sin(phase) * 0.06 * walk * sign

func reset_base() -> void:
	has_base = false
