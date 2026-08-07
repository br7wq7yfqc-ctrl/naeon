extends Control
## Phase 0 boot — intentional entry, not raw spawn into void.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build()
	if AudioDirector:
		AudioDirector.play_ui()
	if SessionObjectives:
		SessionObjectives.current = "boot"
		SessionObjectives._emit()

func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.06, 1)
	add_child(bg)
	# vignette accent bars
	var top := ColorRect.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size.y = 4
	top.color = Color(0.15, 0.75, 1.0, 0.85)
	add_child(top)
	var bot := ColorRect.new()
	bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_top = -4
	bot.color = Color(0.85, 0.15, 0.35, 0.75)
	add_child(bot)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -220
	center.offset_right = 220
	center.offset_top = -180
	center.offset_bottom = 200
	center.add_theme_constant_override("separation", 14)
	add_child(center)

	var title := Label.new()
	title.text = "NAEON"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.modulate = Color(0.75, 0.95, 1.0)
	center.add_child(title)

	var sub := Label.new()
	sub.text = "Aexion continuum  ·  Cybernex vs gROT\nPhase 0 vertical slice — soft economy, dual-theme ownership"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 15)
	sub.modulate = Color(0.55, 0.65, 0.75)
	center.add_child(sub)

	center.add_child(HSeparator.new())

	_btn(center, "OPEN SPACE  —  free flight · land · claim", _goto_space, Color(0.15, 0.55, 0.85))
	_btn(center, "AEXION CLASH  —  3-lane TPS stub", _goto_clash, Color(0.75, 0.2, 0.35))
	_btn(center, "Quit", func(): get_tree().quit(), Color(0.25, 0.25, 0.3))

	var foot := Label.new()
	foot.text = "Benchmarks: SC/NMS continuum · EVE/Stellaris soft meta · Predecessor lanes\nNo P2W  ·  WASD + mouse  ·  F10 host / F11 join soft net"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 12)
	foot.modulate = Color(0.4, 0.48, 0.55)
	center.add_child(foot)

func _btn(parent: Node, text: String, cb: Callable, accent: Color) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(420, 44)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	sb.border_color = accent
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	b.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate()
	sb_h.bg_color = accent.darkened(0.55)
	b.add_theme_stylebox_override("hover", sb_h)
	b.pressed.connect(func():
		if AudioDirector:
			AudioDirector.play_ui()
		cb.call()
	)
	parent.add_child(b)

func _goto_space() -> void:
	if SessionObjectives:
		SessionObjectives.on_entered_mode("space")
	get_tree().change_scene_to_file("res://scenes/world/OpenSpace.tscn")

func _goto_clash() -> void:
	if SessionObjectives:
		SessionObjectives.on_entered_mode("clash")
	get_tree().change_scene_to_file("res://scenes/test/TestArena.tscn")
