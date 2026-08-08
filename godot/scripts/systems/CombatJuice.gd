extends Node
## Combat readability: floating dmg, flash, hit marker, impact ring, soft hitstop.
## Presentation only — no combat power.

var _layer: CanvasLayer
var _flash: ColorRect
var _flash_t: float = 0.0
var _flash_col: Color = Color(1, 0.2, 0.15, 0)
var _hitstop_left: float = 0.0
var _marker: Control
var _marker_t: float = 0.0
var _impact_budget: int = 0
var _hurt_t: float = 0.0
var _hurt_flash: ColorRect

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 80
	add_child(_layer)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 0.2, 0.15, 0)
	_layer.add_child(_flash)
	_marker = Control.new()
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.set_anchors_preset(Control.PRESET_CENTER)
	_marker.visible = false
	_layer.add_child(_marker)
	for ang in [0.0, 90.0, 180.0, 270.0]:
		var tick := ColorRect.new()
		tick.color = Color(1.0, 0.9, 0.3, 0.95)
		tick.size = Vector2(3, 12)
		tick.position = Vector2(-1.5, -22).rotated(deg_to_rad(ang)) + Vector2(-1.5, -6)
		# simple cross: four ticks around center
		_marker.add_child(tick)
	# rebuild marker as + shape
	for c in _marker.get_children():
		c.queue_free()
	var h := ColorRect.new()
	h.color = Color(1.0, 0.92, 0.35, 0.95)
	h.size = Vector2(18, 3)
	h.position = Vector2(-9, -1.5)
	_marker.add_child(h)
	var v := ColorRect.new()
	v.color = Color(1.0, 0.92, 0.35, 0.95)
	v.size = Vector2(3, 18)
	v.position = Vector2(-1.5, -9)
	_marker.add_child(v)
	_hurt_flash = ColorRect.new()
	_hurt_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hurt_flash.color = Color(0.7, 0.05, 0.08, 0)
	_layer.add_child(_hurt_flash)
	set_process(true)

func _process(delta: float) -> void:
	if _hurt_t > 0.0:
		_hurt_t = maxf(0.0, _hurt_t - delta)
		if _hurt_flash:
			_hurt_flash.color.a = clampf(_hurt_t * 0.55, 0.0, 0.35)
	if _flash_t <= 0.0 and _marker_t <= 0.0 and _hurt_t <= 0.0:
		return
	if _flash_t > 0.0:
		_flash_t = maxf(0.0, _flash_t - delta)
		_flash.color = _flash_col
		_flash.color.a = _flash_t * 0.4
	if _marker_t > 0.0:
		_marker_t = maxf(0.0, _marker_t - delta)
		_marker.visible = _marker_t > 0.0
		_marker.modulate.a = clampf(_marker_t * 4.0, 0.0, 1.0)

func hit_feedback(amount: float, world_pos: Vector3, crit: bool = false) -> void:
	_flash_col = Color(1.0, 0.85, 0.2, 0) if crit else Color(1.0, 0.25, 0.18, 0)
	_flash_t = 0.16 if crit else 0.08
	_marker_t = 0.18 if crit else 0.12
	_marker.visible = true
	if AudioDirector:
		AudioDirector.play_hit(crit)
	_spawn_number(amount, world_pos, crit)
	_spawn_impact(world_pos, crit)
	_spawn_hit_ring(world_pos, crit)
	# Hitstop disabled — was tanking Arena FPS with time_scale thrash


func _spawn_number(amount: float, world_pos: Vector3, crit: bool) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	if cam.is_position_behind(world_pos):
		return
	var sp: Vector2 = cam.unproject_position(world_pos)
	var lab := Label.new()
	var txt := ("%d" % int(round(amount))) if amount >= 1.0 else ("%.1f" % amount)
	if crit:
		txt = "CRIT " + txt
	lab.text = txt
	lab.add_theme_font_size_override("font_size", 34 if crit else 22)
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lab.add_theme_constant_override("outline_size", 6 if crit else 4)
	lab.modulate = Color(1.0, 0.9, 0.25) if crit else Color(1.0, 0.5, 0.35)
	lab.position = sp + Vector2(randf_range(-18, 18), -28)
	lab.z_index = 20
	_layer.add_child(lab)
	var tw := get_tree().create_tween()
	tw.set_parallel(true)
	var rise := 70.0 if crit else 48.0
	tw.tween_property(lab, "position", lab.position + Vector2(randf_range(-8, 8), -rise), 0.65)
	tw.tween_property(lab, "modulate:a", 0.0, 0.65)
	if crit:
		tw.tween_property(lab, "scale", Vector2(1.35, 1.35), 0.12)
	tw.chain().tween_callback(lab.queue_free)


func _spawn_impact(world_pos: Vector3, crit: bool) -> void:
	if _impact_budget >= 4:
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	_impact_budget += 1
	var p := GPUParticles3D.new()
	p.amount = 10 if crit else 6
	p.lifetime = 0.35
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = true
	p.global_position = world_pos
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 9.0 if crit else 5.0
	pm.gravity = Vector3(0, -2, 0)
	pm.scale_min = 0.05
	pm.scale_max = 0.14 if crit else 0.1
	pm.color = Color(1.0, 0.85, 0.3, 0.9) if crit else Color(1.0, 0.4, 0.25, 0.85)
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	p.draw_pass_1 = sm
	tree.current_scene.add_child(p)
	tree.create_timer(0.35).timeout.connect(func():
		_impact_budget = maxi(0, _impact_budget - 1)
		if is_instance_valid(p):
			p.queue_free()
	)


func _spawn_hit_ring(world_pos: Vector3, crit: bool) -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.08 if not crit else 0.12
	tm.outer_radius = 0.55 if not crit else 0.95
	tm.rings = 8
	tm.ring_segments = 12
	mi.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.25, 0.85) if crit else Color(1.0, 0.4, 0.25, 0.7)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 2.2 if crit else 1.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tree.current_scene.add_child(mi)
	mi.global_position = world_pos
	# Face camera soft
	var cam := get_viewport().get_camera_3d()
	if cam:
		mi.look_at(cam.global_position, Vector3.UP)
	var tw := tree.create_tween()
	tw.set_parallel(true)
	var s0 := 0.4 if not crit else 0.55
	mi.scale = Vector3.ONE * s0
	tw.tween_property(mi, "scale", Vector3.ONE * (1.6 if crit else 1.2), 0.28)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.28)
	tw.chain().tween_callback(mi.queue_free)



func damage_taken(amount: float = 5.0) -> void:
	## Red edge when local player is hit.
	_hurt_t = clampf(0.12 + amount * 0.008, 0.12, 0.35)
	if AudioDirector:
		AudioDirector.play_hit(false)


func kill_pop(world_pos: Vector3) -> void:
	_flash_col = Color(1.0, 0.9, 0.3, 0)
	_flash_t = 0.2
	_marker_t = 0.25
	_marker.visible = true
	if AudioDirector:
		AudioDirector.play_hit(true)
	_spawn_impact(world_pos, true)
	_spawn_hit_ring(world_pos, true)
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	if cam.is_position_behind(world_pos):
		return
	var sp: Vector2 = cam.unproject_position(world_pos)
	var lab := Label.new()
	lab.text = "DOWN"
	lab.add_theme_font_size_override("font_size", 28)
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lab.add_theme_constant_override("outline_size", 6)
	lab.modulate = Color(1.0, 0.85, 0.3)
	lab.position = sp + Vector2(-20, -40)
	_layer.add_child(lab)
	var tw := get_tree().create_tween()
	tw.set_parallel(true)
	tw.tween_property(lab, "position", lab.position + Vector2(0, -50), 0.7)
	tw.tween_property(lab, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(lab.queue_free)
