extends Node3D
class_name ShipLandingGear
## Procedural landing gear (code-first, 0 Tripo). Soft visual only.

var deployed: float = 0.0
var _legs: Array[Node3D] = []
var _target: float = 0.0

func _ready() -> void:
	name = "LandingGear"
	_build()
	set_process(true)

func _build() -> void:
	for c in get_children():
		c.queue_free()
	_legs.clear()
	var offsets := [
		Vector3(-1.1, -0.15, 0.9),
		Vector3(1.1, -0.15, 0.9),
		Vector3(0.0, -0.15, -1.2),
	]
	for o in offsets:
		var leg := Node3D.new()
		leg.position = o
		add_child(leg)
		var strut := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.12, 0.85, 0.12)
		strut.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.28, 0.32)
		mat.metallic = 0.7
		mat.roughness = 0.4
		strut.material_override = mat
		strut.position = Vector3(0, -0.2, 0)
		leg.add_child(strut)
		var pad := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.22
		cyl.bottom_radius = 0.28
		cyl.height = 0.08
		pad.mesh = cyl
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = Color(0.15, 0.16, 0.18)
		pmat.emission_enabled = true
		pmat.emission = Color(0.2, 0.55, 0.9)
		pmat.emission_energy_multiplier = 0.4
		pad.material_override = pmat
		pad.position = Vector3(0, -0.7, 0)
		leg.add_child(pad)
		_legs.append(leg)
	_apply_visual(0.0)

func set_deployed(want: bool) -> void:
	_target = 1.0 if want else 0.0

func _process(delta: float) -> void:
	deployed = move_toward(deployed, _target, delta * 2.2)
	_apply_visual(deployed)

func _apply_visual(t: float) -> void:
	for leg in _legs:
		if not is_instance_valid(leg):
			continue
		var fold := lerpf(-1.2, 0.15, t)
		leg.rotation.x = fold
		leg.scale = Vector3.ONE * lerpf(0.55, 1.0, t)
		leg.visible = t > 0.02
