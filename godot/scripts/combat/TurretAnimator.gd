extends Node
class_name TurretAnimator
## Living turret: yaw track, barrel pitch, neon muzzle, recoil.

var yaw: float = 0.0
var pitch: float = 0.0
var _recoil: float = 0.0
var _spin: float = 0.0
var base: Node3D
var head: Node3D
var barrel: Node3D
var _muzzle: GPUParticles3D
var faction: String = "Cybernex"


func setup(root: Node3D, fac: String = "Cybernex") -> void:
	faction = fac
	base = root
	head = root.get_node_or_null("Head") as Node3D
	barrel = root.get_node_or_null("Barrel") as Node3D
	if head == null:
		head = Node3D.new()
		head.name = "Head"
		root.add_child(head)
	if barrel == null:
		barrel = MeshInstance3D.new()
		barrel.name = "Barrel"
		var bm := BoxMesh.new()
		bm.size = Vector3(0.12, 0.12, 0.9)
		(barrel as MeshInstance3D).mesh = bm
		var mat := StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = Color(0.95, 0.2, 0.4) if fac == "gROT" else Color(0.2, 0.85, 1.0)
		mat.emission_energy_multiplier = 1.2
		(barrel as MeshInstance3D).material_override = mat
		head.add_child(barrel)
		barrel.position = Vector3(0, 0.2, -0.4)
	var NP = load("res://scripts/fx/NeonParticles.gd")
	if NP:
		_muzzle = NP.trail_attach(barrel, NP.faction_color(fac), Vector3(0, 0, -0.5))
		if _muzzle:
			_muzzle.emitting = false
	set_process(true)


func aim_at(global_target: Vector3, delta: float) -> void:
	if base == null:
		return
	var to := global_target - base.global_position
	var want_yaw := atan2(-to.x, -to.z)
	yaw = lerp_angle(yaw, want_yaw, clampf(delta * 4.0, 0.0, 1.0))
	var horiz := Vector3(to.x, 0, to.z).length()
	var want_pitch := -atan2(to.y, maxf(horiz, 0.01))
	want_pitch = clampf(want_pitch, -0.6, 0.45)
	pitch = lerpf(pitch, want_pitch, clampf(delta * 3.5, 0.0, 1.0))
	if head:
		head.rotation.y = yaw
	if barrel:
		barrel.rotation.x = pitch + _recoil


func fire_kick() -> void:
	_recoil = -0.25
	_spin = 1.0
	if _muzzle:
		_muzzle.emitting = true
	var NP = load("res://scripts/fx/NeonParticles.gd")
	if NP and base and base.is_inside_tree():
		var col = NP.faction_color(faction)
		var origin = barrel.global_position if barrel else base.global_position
		var dir = -barrel.global_transform.basis.z if barrel else Vector3(0, 0, -1)
		NP.muzzle_flash(origin, dir, col, base.get_tree())


func _process(delta: float) -> void:
	_recoil = lerpf(_recoil, 0.0, clampf(delta * 8.0, 0.0, 1.0))
	_spin = maxf(0.0, _spin - delta)
	if _muzzle and _spin <= 0.0:
		_muzzle.emitting = false
	if barrel and _spin > 0.0:
		barrel.rotate_z(delta * 12.0)
