extends Node3D
class_name CityNightLights
## Pad-cluster night city glow — emissive towers + omnis. Quality-scaled.

const MAX_TOWERS := 12

var _built: bool = false
var _faction: String = "Cybernex"
var _towers: Array = []
var _lights: Array = []


func build(faction: String = "Cybernex", radius: float = 28.0, count: int = 10) -> void:
	_faction = faction
	if _built:
		_restyle()
		return
	var gq := get_node_or_null("/root/GraphicsQuality")
	var n: int = count
	if gq != null:
		match int(gq.tier):
			0:
				n = mini(count, 6)
			2, 3:
				n = count
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(faction) * 17 + 99
	var col := Color(0.35, 0.85, 1.0) if faction != "gROT" else Color(1.0, 0.25, 0.45)
	for i in n:
		var ang := float(i) / float(maxi(n, 1)) * TAU + rng.randf() * 0.3
		var r := radius * rng.randf_range(0.35, 1.0)
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
		# Window spark strip
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
		_towers.append(win)
		if i % 3 == 0 and not (gq != null and int(gq.tier) == 0):
			var light := OmniLight3D.new()
			light.light_color = col
			light.light_energy = 1.2
			light.omni_range = 18.0
			light.position = pos + Vector3(0, h + 0.5, 0)
			light.shadow_enabled = false
			add_child(light)
			_lights.append(light)
	_built = true
	print("[CityNightLights] towers=", n, " faction=", faction)
	set_process(true)


func _restyle() -> void:
	var col := Color(0.35, 0.85, 1.0) if _faction != "gROT" else Color(1.0, 0.25, 0.45)
	for t in _towers:
		if t is MeshInstance3D:
			var mat := (t as MeshInstance3D).material_override as StandardMaterial3D
			if mat and mat.emission.b > 0.5 or (mat and mat.emission.r < 0.5):
				pass


func _process(_delta: float) -> void:
	# Pulse city energy slightly
	var t := Time.get_ticks_msec() * 0.001
	for i in _lights.size():
		var L: OmniLight3D = _lights[i]
		if L and is_instance_valid(L):
			L.light_energy = 0.9 + 0.4 * sin(t * 1.7 + float(i))
