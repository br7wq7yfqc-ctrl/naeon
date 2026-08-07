extends Node
## Screen-space combat feedback: floating damage, hit flash.
## No combat power — presentation only.

var _layer: CanvasLayer
var _flash: ColorRect
var _flash_t: float = 0.0

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 80
	add_child(_layer)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 0.2, 0.15, 0)
	_layer.add_child(_flash)
	set_process(true)

func _process(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t = maxf(0.0, _flash_t - delta)
		_flash.color.a = _flash_t * 0.35

func hit_feedback(amount: float, world_pos: Vector3, crit: bool = false) -> void:
	_flash_t = 0.12 if crit else 0.07
	if AudioDirector:
		AudioDirector.play_hit(crit)
	_spawn_number(amount, world_pos, crit)

func _spawn_number(amount: float, world_pos: Vector3, crit: bool) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	if cam.is_position_behind(world_pos):
		return
	var sp: Vector2 = cam.unproject_position(world_pos)
	var lab := Label.new()
	lab.text = ("%d" % int(amount)) if amount >= 1.0 else ("%.1f" % amount)
	lab.add_theme_font_size_override("font_size", 28 if crit else 20)
	lab.modulate = Color(1.0, 0.85, 0.2) if crit else Color(1.0, 0.45, 0.35)
	lab.position = sp + Vector2(randf_range(-12, 12), -20)
	lab.z_index = 20
	_layer.add_child(lab)
	var tw := get_tree().create_tween()
	tw.set_parallel(true)
	tw.tween_property(lab, "position", lab.position + Vector2(0, -48), 0.55)
	tw.tween_property(lab, "modulate:a", 0.0, 0.55)
	tw.chain().tween_callback(lab.queue_free)
