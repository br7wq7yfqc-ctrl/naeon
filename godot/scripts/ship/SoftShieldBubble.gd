extends Node3D
class_name SoftShieldBubble
## Soft shield dome presentation — pulses with shield energy. No combat power.

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _ship: Node = null
var _t: float = 0.0


func setup(ship: Node) -> void:
	_ship = ship
	name = "SoftShieldBubble"
	_mesh = MeshInstance3D.new()
	if DisplayServer.get_name() == "headless":
		var b := BoxMesh.new()
		b.size = Vector3(4.8, 4.8, 4.8)
		_mesh.mesh = b
	else:
		var sm := SphereMesh.new()
		sm.radius = 2.4
		sm.height = 4.8
		sm.radial_segments = 16
		sm.rings = 8
		_mesh.mesh = sm
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.albedo_color = Color(0.25, 0.85, 1.0, 0.08)
	_mat.emission_enabled = true
	_mat.emission = Color(0.25, 0.85, 1.0)
	_mat.emission_energy_multiplier = 0.6
	_mesh.material_override = _mat
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(_mesh)
	if ship and "faction" in ship and str(ship.faction) == "gROT":
		_mat.albedo_color = Color(0.95, 0.2, 0.45, 0.08)
		_mat.emission = Color(0.95, 0.2, 0.45)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	if _ship == null or not is_instance_valid(_ship) or _mat == null:
		return
	var sh := 50.0
	var msh := 100.0
	if "shields" in _ship:
		sh = float(_ship.shields)
	if "max_shields" in _ship:
		msh = maxf(1.0, float(_ship.max_shields))
	var ratio := clampf(sh / msh, 0.0, 1.0)
	var pulse := 0.05 + 0.06 * sin(_t * 2.2) * ratio
	_mat.albedo_color.a = pulse
	_mat.emission_energy_multiplier = 0.4 + ratio * 1.2
	visible = ratio > 0.05
	# Siege brighten
	if "op_mode" in _ship and int(_ship.op_mode) == 1:
		_mat.emission_energy_multiplier += 0.5
