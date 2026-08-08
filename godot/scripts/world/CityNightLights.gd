extends Node3D
class_name CityNightLights
## Pad-cluster night city — density scales with claim. Quality-scaled.

var _built: bool = false
var _faction: String = "Cybernex"
var _towers: Array = []
var _lights: Array = []
var _wins: Array = []
var _radius: float = 28.0
var _base_count: int = 10
var _density: float = 1.0  # 0.4 unclaimed … 1.4 strong claim


func build(faction: String = "Cybernex", radius: float = 28.0, count: int = 10) -> void:
	_faction = faction
	_radius = radius
	_base_count = count
	if _built:
		set_density(_density, faction)
		return
	_rebuild(count)
	_built = true
	set_process(true)
	print("[CityNightLights] towers=", _towers.size(), " faction=", faction)


func set_density(d: float, faction: String = "") -> void:
	_density = clampf(d, 0.25, 1.6)
	if faction != "":
		_faction = faction
	if not _built:
		return
	# Show/hide towers by density; boost emission
	var col := _faction_color()
	var n_show: int = int(ceil(float(_towers.size()) * _density / 1.2))
	for i in _towers.size():
		var t: MeshInstance3D = _towers[i]
		if t == null or not is_instance_valid(t):
			continue
		t.visible = i < n_show
		var mat := t.material_override as StandardMaterial3D
		if mat:
			mat.emission = col
			mat.emission_energy_multiplier = (1.4 + _density * 1.2) * (1.0 if i % 2 == 0 else 0.7)
			mat.albedo_color = col * 0.35
	for i in _wins.size():
		var w: MeshInstance3D = _wins[i]
		if w and is_instance_valid(w):
			w.visible = i < n_show
			var wm := w.material_override as StandardMaterial3D
			if wm:
				wm.emission_energy_multiplier = 1.8 + _density * 1.5
	for L in _lights:
		if L and is_instance_valid(L):
			L.light_color = col
			L.light_energy = 0.45 * _density
			L.shadow_enabled = false
			L.visible = _density > 0.55


func _faction_color() -> Color:
	if _faction == "gROT":
		return Color(1.0, 0.25, 0.45)
	if _faction == "Contested":
		return Color(1.0, 0.65, 0.2)
	return Color(0.35, 0.85, 1.0)


func _rebuild(count: int) -> void:
	for c in get_children():
		c.queue_free()
	_towers.clear()
	_lights.clear()
	_wins.clear()
	var gq := get_node_or_null("/root/GraphicsQuality")
	var n: int = count
	if gq != null:
		match int(gq.tier):
			0:
				n = mini(count, 6)
			2, 3:
				n = count
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_faction) * 17 + 99
	var col := _faction_color()
	for i in n:
		var ang := float(i) / float(maxi(n, 1)) * TAU + rng.randf() * 0.3
		var r := _radius * rng.randf_range(0.35, 1.0)
		var pos := Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		var h := rng.randf_range(3.5, 11.0)
		var tower := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(rng.randf_range(0.6, 1.4), h, rng.randf_range(0.6, 1.4))
		tower.mesh = box
		tower.position = pos + Vector3(0, h * 0.5, 0)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = col * 0.35
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.8 + rng.randf() * 1.5
		tower.material_override = mat
		tower.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tower)
		_towers.append(tower)
		var win := MeshInstance3D.new()
		var wb := BoxMesh.new()
		wb.size = Vector3(box.size.x * 1.05, h * 0.7, 0.08)
		win.mesh = wb
		win.position = pos + Vector3(0, h * 0.55, box.size.z * 0.5)
		var wm := StandardMaterial3D.new()
		wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		wm.albedo_color = Color(1.0, 0.9, 0.55)
		wm.emission_enabled = true
		wm.emission = Color(1.0, 0.85, 0.4)
		wm.emission_energy_multiplier = 2.5
		win.material_override = wm
		win.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(win)
		_wins.append(win)
		if i % 3 == 0 and not (gq != null and int(gq.tier) == 0):
			var light := OmniLight3D.new()
			light.light_color = col
			light.light_energy = 1.2
			light.omni_range = 18.0
			light.position = pos + Vector3(0, h + 0.5, 0)
			light.shadow_enabled = false
			add_child(light)
			_lights.append(light)


var _pulse_accum: float = 0.0
func _process(delta: float) -> void:
	# Pulse lights ~5Hz — not every frame
	_pulse_accum += delta
	if _pulse_accum < 0.2:
		return
	_pulse_accum = 0.0
	var t := Time.get_ticks_msec() * 0.001
	for i in _lights.size():
		var L: OmniLight3D = _lights[i]
		if L and is_instance_valid(L) and L.visible:
			L.light_energy = (0.45 + 0.25 * sin(t * 1.7 + float(i))) * _density
