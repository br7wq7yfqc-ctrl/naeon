extends Node3D
class_name ContestedRing
## Contested ownership ring — amber threat always readable from any angle/camera.
## Never skinned away; min-spec safe (few meshes, no particles storm).

const CLAIM_NEED := 1.75
const SPOKE_COUNT := 6

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _label: Label3D
var _sub_label: Label3D
var progress: float = 0.0
var active: bool = false
var _fill: MeshInstance3D
var _fill_mat: StandardMaterial3D
var _light: OmniLight3D
var _pulse_boost: float = 0.0
var _spokes: Array[MeshInstance3D] = []
var _pillars: Array[MeshInstance3D] = []
var _beacon: MeshInstance3D
var _beacon_mat: StandardMaterial3D
var _meter: MeshInstance3D
var _meter_mat: StandardMaterial3D


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
	_label.font_size = 42
	_label.outline_size = 10
	_label.position = Vector3(0, 8.5, 0)
	_label.modulate = Color(1.0, 0.75, 0.3)
	_label.text = "CONTESTED"
	_label.no_depth_test = true
	add_child(_label)

	_sub_label = Label3D.new()
	_sub_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sub_label.font_size = 26
	_sub_label.outline_size = 6
	_sub_label.position = Vector3(0, 7.2, 0)
	_sub_label.modulate = Color(1.0, 0.9, 0.55)
	_sub_label.text = "C to pulse claim"
	_sub_label.no_depth_test = true
	add_child(_sub_label)

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
	_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fill)

	# Vertical claim meter (camera-readable height bar)
	_meter = MeshInstance3D.new()
	var mb := BoxMesh.new()
	mb.size = Vector3(0.35, 6.0, 0.35)
	_meter.mesh = mb
	_meter_mat = StandardMaterial3D.new()
	_meter_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_meter_mat.albedo_color = Color(1.0, 0.7, 0.2, 0.9)
	_meter_mat.emission_enabled = true
	_meter_mat.emission = Color(1.0, 0.65, 0.15)
	_meter_mat.emission_energy_multiplier = 2.5
	_meter.material_override = _meter_mat
	_meter.position = Vector3(0, 3.0, 0)
	_meter.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_meter)

	# Beacon sphere at apex
	_beacon = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.55
	sm.height = 1.1
	_beacon.mesh = sm
	_beacon_mat = StandardMaterial3D.new()
	_beacon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beacon_mat.albedo_color = Color(1.0, 0.6, 0.15)
	_beacon_mat.emission_enabled = true
	_beacon_mat.emission = Color(1.0, 0.55, 0.1)
	_beacon_mat.emission_energy_multiplier = 3.0
	_beacon.material_override = _beacon_mat
	_beacon.position = Vector3(0, 7.0, 0)
	_beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beacon)

	_build_spokes()
	_build_pillars()

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.55, 0.2)
	_light.light_energy = 0.0
	_light.omni_range = 32.0
	_light.position = Vector3(0, 4, 0)
	_light.shadow_enabled = false
	add_child(_light)
	add_to_group("contested_ring")
	set_process(true)
	visible = false


func _build_spokes() -> void:
	_spokes.clear()
	for i in SPOKE_COUNT:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.18, 0.12, 10.5)
		mi.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.5, 0.12, 0.65)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.45, 0.1)
		mat.emission_energy_multiplier = 1.6
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(0, 0.2, 0)
		mi.rotation.y = float(i) * TAU / float(SPOKE_COUNT)
		add_child(mi)
		_spokes.append(mi)


func _build_pillars() -> void:
	## Four compass pillars — readable silhouette at distance / low angle.
	_pillars.clear()
	for i in 4:
		var ang := float(i) * TAU * 0.25 + PI * 0.25
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.45, 5.5, 0.45)
		mi.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.18, 0.12, 0.06)
		mat.metallic = 0.4
		mat.roughness = 0.5
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.45, 0.1)
		mat.emission_energy_multiplier = 1.2
		mi.material_override = mat
		mi.position = Vector3(cos(ang) * 11.8, 2.75, sin(ang) * 11.8)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_pillars.append(mi)
		# Cap light bar
		var cap := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.55, 0.12, 0.55)
		cap.mesh = cb
		var cm2 := StandardMaterial3D.new()
		cm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cm2.albedo_color = Color(1.0, 0.7, 0.2)
		cm2.emission_enabled = true
		cm2.emission = Color(1.0, 0.65, 0.15)
		cm2.emission_energy_multiplier = 2.8
		cap.material_override = cm2
		cap.position = Vector3(0, 2.85, 0)
		cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_child(cap)


func set_contested(on: bool, claim_strength: float = 0.0) -> void:
	var was := active
	active = on
	visible = on
	progress = clampf(claim_strength / CLAIM_NEED, 0.0, 1.0)
	if on and (not was or claim_strength > 0.01):
		_pulse_boost = 1.0
		if not was and AudioDirector and AudioDirector.has_method("play_contest"):
			AudioDirector.play_contest()
	if not on:
		_pulse_boost = 0.0
		if _light:
			_light.light_energy = 0.0


func pulse() -> void:
	_pulse_boost = 1.25


func get_progress() -> float:
	return progress


func _process(delta: float) -> void:
	if not active:
		return
	_pulse_boost = maxf(0.0, _pulse_boost - delta * 1.8)
	rotate_y(delta * (0.55 + progress * 0.4))
	var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.01) + _pulse_boost
	if _mat:
		var a := Color(0.2, 0.85, 1.0)
		var b := Color(0.95, 0.15, 0.4)
		var mix := a.lerp(b, 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006))
		_mat.emission = Color(1.0, 0.45, 0.1).lerp(mix, 0.35)
		_mat.emission_energy_multiplier = 1.8 + pulse * 2.2
		_mat.albedo_color = Color(_mat.emission.r, _mat.emission.g, _mat.emission.b, 0.55 + pulse * 0.25)
	if _label:
		_label.text = "CONTESTED  %d%%" % int(progress * 100.0)
		_label.modulate = Color(1.0, 0.75, 0.3).lerp(Color(1.0, 1.0, 0.65), _pulse_boost)
		_label.position.y = 8.5 + sin(Time.get_ticks_msec() * 0.004) * 0.15
	if _sub_label:
		_sub_label.text = "C pulse · need %.0f%% more" % maxf(0.0, (1.0 - progress) * 100.0)
	if _fill:
		var s := 0.12 + progress * 0.88
		_fill.scale = Vector3(s, 1.0, s)
	if _fill_mat:
		_fill_mat.emission_energy_multiplier = 1.0 + progress * 2.5 + _pulse_boost
		_fill_mat.albedo_color.a = 0.12 + progress * 0.4
	# Vertical meter height = progress (always camera-readable)
	if _meter:
		var h := 0.8 + progress * 6.5
		_meter.scale = Vector3(1.0, h / 6.0, 1.0)
		_meter.position.y = h * 0.5
	if _meter_mat:
		_meter_mat.emission_energy_multiplier = 1.8 + progress * 2.0 + _pulse_boost * 1.5
	if _beacon:
		_beacon.position.y = 6.5 + progress * 2.0 + sin(Time.get_ticks_msec() * 0.008) * 0.2
		_beacon.scale = Vector3.ONE * (0.85 + pulse * 0.25)
	if _beacon_mat:
		_beacon_mat.emission_energy_multiplier = 2.5 + pulse * 2.5
	for i in _spokes.size():
		var sp := _spokes[i]
		if is_instance_valid(sp):
			var on := float(i) / float(SPOKE_COUNT) <= progress + 0.01
			sp.visible = true
			var mat2 := sp.material_override as StandardMaterial3D
			if mat2:
				mat2.emission_energy_multiplier = (2.8 if on else 0.6) + _pulse_boost
				mat2.albedo_color.a = 0.85 if on else 0.25
	for p in _pillars:
		if is_instance_valid(p) and p.material_override is StandardMaterial3D:
			(p.material_override as StandardMaterial3D).emission_energy_multiplier = 0.8 + progress * 1.8 + pulse * 0.5
	if _light:
		_light.light_energy = 1.0 + progress * 2.8 + _pulse_boost * 3.0
