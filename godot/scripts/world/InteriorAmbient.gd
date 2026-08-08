extends Node3D
class_name InteriorAmbient
## Runtime interior atmosphere: light pulse, hum, console flicker, status readouts.
## Presentation only — no combat power. RTX 1060 friendly (few lights).

var _neon: Color = Color(0.2, 0.85, 1.0)
var _kind: String = "ship"
var _t: float = 0.0
var _lights: Array[OmniLight3D] = []
var _panels: Array[Label3D] = []
var _hum_t: float = 0.0
var _env: WorldEnvironment = null
var _prev_env: Environment = null


func setup(kind: String, neon: Color) -> void:
	_kind = kind
	_neon = neon
	name = "InteriorAmbient"
	_collect_lights()
	_spawn_status_panels()
	_spawn_floor_grid_decals()
	_apply_env()
	set_process(true)
	if AudioDirector and AudioDirector.has_method("play_interior_enter"):
		AudioDirector.play_interior_enter()
	print("[InteriorAmbient] ", kind)


func _collect_lights() -> void:
	_lights.clear()
	var parent := get_parent()
	if parent == null:
		return
	for n in parent.find_children("*", "OmniLight3D", true, false):
		if n is OmniLight3D:
			_lights.append(n as OmniLight3D)


func _spawn_status_panels() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var spots: Array[Vector3] = [
		Vector3(2.2, 1.6, 0.5),
		Vector3(-2.2, 1.6, 2.0),
		Vector3(0.0, 1.8, 5.0),
	]
	if _kind == "station":
		spots = [
			Vector3(3.0, 2.0, 0.0),
			Vector3(-3.0, 2.0, 14.0),
			Vector3(0.0, 2.2, 28.0),
			Vector3(5.0, 1.8, 14.0),
		]
	var lines := [
		"LIFE SUPPORT  OK",
		"HULL SEAL  STABLE",
		"POWER BUS  %.0f%%" % randf_range(78, 99),
		"ATMO  1.00 bar",
		"COMMS  SOFT-NET",
	]
	for i in spots.size():
		var lab := Label3D.new()
		lab.name = "StatusPanel_%d" % i
		lab.text = lines[i % lines.size()]
		lab.font_size = 22
		lab.modulate = _neon
		lab.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lab.position = spots[i]
		lab.outline_modulate = Color(0, 0, 0, 0.8)
		lab.outline_size = 4
		parent.add_child(lab)
		_panels.append(lab)
		# Backplate
		var plate := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.4, 0.55, 0.04)
		plate.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.04, 0.05, 0.07)
		mat.emission_enabled = true
		mat.emission = _neon.darkened(0.5)
		mat.emission_energy_multiplier = 0.35
		plate.material_override = mat
		plate.position = spots[i] + Vector3(0, 0, 0.03)
		plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(plate)


func _spawn_floor_grid_decals() -> void:
	## Soft emissive floor runners (cheap boxes).
	var parent := get_parent() as Node3D
	if parent == null:
		return
	for i in 3:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.12, 0.02, 8.0 + float(i) * 2.0)
		mi.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(_neon.r, _neon.g, _neon.b, 0.55)
		mat.emission_enabled = true
		mat.emission = _neon
		mat.emission_energy_multiplier = 1.1
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = mat
		mi.position = Vector3(float(i - 1) * 1.1, 0.12, 4.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)


func _apply_env() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	# Soft local fog feel via ambient light only (no heavy WorldEnvironment thrash)
	pass


func _process(delta: float) -> void:
	_t += delta
	_hum_t += delta
	# Light breathing
	var pulse := 0.85 + 0.15 * sin(_t * 1.7)
	for i in _lights.size():
		var L := _lights[i]
		if not is_instance_valid(L):
			continue
		var base := 1.6 if _kind == "ship" else 1.8
		L.light_energy = base * pulse * (1.0 + 0.05 * sin(_t * 2.3 + float(i)))
	# Panel flicker / cycle text
	if int(_t * 2.0) % 5 == 0:
		for i in _panels.size():
			var lab := _panels[i]
			if is_instance_valid(lab):
				lab.modulate = _neon.lerp(Color.WHITE, 0.15 * (0.5 + 0.5 * sin(_t * 3.0 + float(i))))
	# Soft hum every ~4s
	if _hum_t > 4.0:
		_hum_t = 0.0
		if AudioDirector and AudioDirector.has_method("play_interior_hum"):
			AudioDirector.play_interior_hum()


func teardown() -> void:
	if AudioDirector and AudioDirector.has_method("play_interior_exit"):
		AudioDirector.play_interior_exit()
