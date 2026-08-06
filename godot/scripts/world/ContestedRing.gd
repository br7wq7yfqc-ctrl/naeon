extends Node3D
class_name ContestedRing
## Bidirectional contested ownership ring — readable amber threat (not faction-skinned away).

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _label: Label3D
var progress: float = 0.5  # 0 = faction A, 1 = faction B (display only)
var active: bool = false

func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 11.0
	tm.outer_radius = 12.5
	tm.rings = 8
	tm.ring_segments = 24
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
	set_process(true)
	visible = false

func set_contested(on: bool, claim_strength: float = 0.0) -> void:
	active = on
	visible = on
	progress = clampf(claim_strength / 2.0, 0.0, 1.0)

func _process(delta: float) -> void:
	if not active:
		return
	rotate_y(delta * 0.9)
	var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.01)
	if _mat:
		# Amber danger stays readable; mix cyan/magenta only as ornament
		var a := Color(0.2, 0.85, 1.0)
		var b := Color(0.95, 0.15, 0.4)
		var mix := a.lerp(b, 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006))
		_mat.emission = Color(1.0, 0.45, 0.1).lerp(mix, 0.35)
		_mat.emission_energy_multiplier = 1.8 + pulse * 1.5
		_mat.albedo_color = Color(_mat.emission.r, _mat.emission.g, _mat.emission.b, 0.55 + pulse * 0.3)
	if _label:
		_label.text = "CONTESTED  %d%%" % int(progress * 100.0)
