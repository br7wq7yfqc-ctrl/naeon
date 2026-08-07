extends Node3D
class_name ContestedRing
## Contested ownership ring — amber threat always readable (never skinned away).

const CLAIM_NEED := 1.75

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _label: Label3D
var progress: float = 0.0
var active: bool = false
var _fill: MeshInstance3D
var _fill_mat: StandardMaterial3D
var _light: OmniLight3D
var _pulse_boost: float = 0.0


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 11.0
	tm.outer_radius = 12.5
	tm.rings = 10
	tm.ring_segments = 28
	_mesh.mesh = tm
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = Color(1.0, 0.55, 0.15, 0.75)
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.5, 0.1)
	_mat.emission_energy_multiplier = 2.5
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh.material_override = _mat
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 36
	_label.outline_size = 8
	_label.position = Vector3(0, 6, 0)
	_label.modulate = Color(1.0, 0.7, 0.25)
	_label.text = "CONTESTED"
	add_child(_label)
	_fill = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 10.5
	cm.bottom_radius = 10.5
	cm.height = 0.08
	cm.radial_segments = 28
	_fill.mesh = cm
	_fill_mat = StandardMaterial3D.new()
	_fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fill_mat.albedo_color = Color(1.0, 0.5, 0.1, 0.25)
	_fill_mat.emission_enabled = true
	_fill_mat.emission = Color(1.0, 0.45, 0.1)
	_fill_mat.emission_energy_multiplier = 1.2
	_fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fill.material_override = _fill_mat
	_fill.position = Vector3(0, 0.05, 0)
	add_child(_fill)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.55, 0.2)
	_light.light_energy = 0.0
	_light.omni_range = 28.0
	_light.position = Vector3(0, 3, 0)
	add_child(_light)
	set_process(true)
	visible = false


func set_contested(on: bool, claim_strength: float = 0.0) -> void:
	var was := active
	active = on
	visible = on
	progress = clampf(claim_strength / CLAIM_NEED, 0.0, 1.0)
	if on and (not was or claim_strength > 0.01):
		_pulse_boost = 1.0
	if not on:
		_pulse_boost = 0.0
		if _light:
			_light.light_energy = 0.0


func pulse() -> void:
	_pulse_boost = 1.25


func _process(delta: float) -> void:
	if not active:
		return
	_pulse_boost = maxf(0.0, _pulse_boost - delta * 1.8)
	rotate_y(delta * (0.9 + progress * 0.6))
	var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.01) + _pulse_boost
	if _mat:
		var a := Color(0.2, 0.85, 1.0)
		var b := Color(0.95, 0.15, 0.4)
		var mix := a.lerp(b, 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006))
		# Amber threat stays primary
		_mat.emission = Color(1.0, 0.45, 0.1).lerp(mix, 0.35)
		_mat.emission_energy_multiplier = 1.8 + pulse * 2.2
		_mat.albedo_color = Color(_mat.emission.r, _mat.emission.g, _mat.emission.b, 0.55 + pulse * 0.25)
	if _label:
		_label.text = "CONTESTED  %d%%  ·  C pulse" % int(progress * 100.0)
		_label.modulate = Color(1.0, 0.75, 0.3).lerp(Color(1.0, 1.0, 0.6), _pulse_boost)
	if _fill:
		var s := 0.12 + progress * 0.88
		_fill.scale = Vector3(s, 1.0, s)
	if _fill_mat:
		_fill_mat.emission_energy_multiplier = 1.0 + progress * 2.5 + _pulse_boost
		_fill_mat.albedo_color.a = 0.12 + progress * 0.4
	if _light:
		_light.light_energy = 0.8 + progress * 2.5 + _pulse_boost * 3.0
