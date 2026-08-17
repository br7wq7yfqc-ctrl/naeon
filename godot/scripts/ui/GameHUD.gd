extends CanvasLayer
class_name GameHUD
const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
const _AllianceRanks = preload("res://scripts/systems/AllianceRanks.gd")
## Readable dark-neon HUD: abilities, infection, contested banner, mastery, toasts.
## Threat colours universal; faction skin does not hide red/green meaning.

@export var show_ability_bar: bool = true

var _root: Control
var _ability_label: Label
var _status_label: Label
var _infection_label: Label
var _owner_label: Label
var _channel_label: Label
var _channel_bar: ProgressBar
var _contest_banner: PanelContainer
var _contest_label: Label
var _mastery_label: Label
var _econ_label: Label
var _econ_bar: ProgressBar
var _econ_flash: float = 0.0
var _econ_last: float = -1.0
var _econ_delta: float = 0.0
var _layer_label: Label
var _terrain_label: Label
var _interior_label: Label
var _lead_pip: ColorRect
var _ctx_label: Label
var _edu_label: Label
var _edu_quest: Node = null
var _toast_label: Label
var _claim_bar: ProgressBar
var _player: Node
var _obj_label: Label
var _cross: Label
var _hud_accum: float = 0.0
var _host_hint_cache: String = ""
var _host_hint_t: float = 999.0
var _terrain_cache: String = ""
var _terrain_t: float = 999.0
var _ability_sys: Node
var _toast_ttl: float = 0.0
var _toast_queue: Array = []
var _radar: Control
var _radar_dots: Array = []
var _debug_overlay: bool = false
var _hp_bar: ProgressBar
var _en_bar: ProgressBar
var _hp_tag: Label
var _en_tag: Label
var _slot_row: HBoxContainer
var _slots: Array = []
var _pip_row: HBoxContainer
var _pips: Array = []
var _chrome_built: bool = false
var _gfx_name: String = "?"
var _gfx_mem_mb: int = 0

func _ready() -> void:
	layer = 20
	add_to_group("game_hud")
	_build()
	set_process(true)
	if GameManager and GameManager.has_signal("toast_requested"):
		if not GameManager.toast_requested.is_connected(_on_gm_toast):
			GameManager.toast_requested.connect(_on_gm_toast)
	if GameManager:
		if GameManager.has_signal("contribution_changed") and not GameManager.contribution_changed.is_connected(_on_econ_tick):
			GameManager.contribution_changed.connect(_on_econ_tick)
		if GameManager.has_signal("biomass_changed") and not GameManager.biomass_changed.is_connected(_on_econ_tick):
			GameManager.biomass_changed.connect(_on_econ_tick)

func bind_player(p: Node) -> void:
	_player = p if p != null and is_instance_valid(p) else null
	_ability_sys = null
	if _player:
		_ability_sys = _player.get_node_or_null("AbilitySystem")
		if _ability_sys == null and _player.get_child_count() > 0:
			for c in _player.get_children():
				if c is AbilitySystem or (c.get_script() and "AbilitySystem" in str(c.get_script().resource_path)):
					_ability_sys = c
					break

func push_toast(msg: String, ttl: float = 3.0) -> void:
	_toast_queue.append({"msg": msg, "ttl": ttl})
	if _toast_ttl <= 0.0:
		_pop_toast()

func _pop_toast() -> void:
	if _toast_queue.is_empty():
		if _toast_label:
			_toast_label.visible = false
		return
	var t: Dictionary = _toast_queue.pop_front()
	_toast_ttl = float(t.get("ttl", 3.0))
	if _toast_label:
		_toast_label.text = str(t.get("msg", ""))
		_toast_label.visible = true

func _build() -> void:
	_root = Control.new()
	_obj_label = Label.new()
	_cross = Label.new()
	_cross.text = "+"
	_cross.add_theme_font_size_override("font_size", 28)
	_cross.modulate = Color(0.7, 0.95, 1.0, 0.75)
	_cross.set_anchors_preset(Control.PRESET_CENTER)
	_cross.offset_left = -10
	_cross.offset_right = 10
	_cross.offset_top = -16
	_cross.offset_bottom = 16
	_cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_obj_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_obj_label.offset_top = 6
	_obj_label.offset_left = 16
	_obj_label.offset_right = -16
	_obj_label.offset_bottom = 36
	_obj_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_obj_label.add_theme_font_size_override("font_size", 16)
	_obj_label.modulate = Color(0.85, 0.95, 1.0, 0.95)
	_obj_label.text = ""
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_status_label = Label.new()
	_status_label.position = Vector2(14, 12)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
	_status_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_status_label.add_theme_constant_override("outline_size", 4)
	_root.add_child(_status_label)
	_root.add_child(_obj_label)
	_root.add_child(_cross)

	_infection_label = Label.new()
	_infection_label.position = Vector2(14, 70)
	_infection_label.add_theme_font_size_override("font_size", 16)
	_infection_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.55))
	_infection_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_infection_label.add_theme_constant_override("outline_size", 5)
	_root.add_child(_infection_label)

	_mastery_label = Label.new()
	_mastery_label.position = Vector2(14, 96)
	_mastery_label.add_theme_font_size_override("font_size", 12)
	_mastery_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.95, 0.9))
	_mastery_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_mastery_label.add_theme_constant_override("outline_size", 3)
	_root.add_child(_mastery_label)

	_econ_label = Label.new()
	_econ_label.position = Vector2(14, 128)
	_econ_label.add_theme_font_size_override("font_size", 13)
	_econ_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.75))
	_econ_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_econ_label.add_theme_constant_override("outline_size", 4)
	_econ_label.text = "ECON —"
	_root.add_child(_econ_label)
	_econ_bar = ProgressBar.new()
	_econ_bar.position = Vector2(14, 148)
	_econ_bar.size = Vector2(220, 10)
	_econ_bar.max_value = 1.0
	_econ_bar.value = 0.0
	_econ_bar.show_percentage = false
	_econ_bar.modulate = Color(0.4, 0.95, 0.7)
	_root.add_child(_econ_bar)

	_layer_label = Label.new()
	_layer_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_layer_label.offset_left = -280
	_layer_label.offset_right = -12
	_layer_label.offset_top = 8
	_layer_label.offset_bottom = 78
	_layer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_layer_label.add_theme_font_size_override("font_size", 14)
	_layer_label.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0))
	_layer_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_layer_label.add_theme_constant_override("outline_size", 5)
	_layer_label.text = "LAYER · SPACE"
	_root.add_child(_layer_label)
	_terrain_label = Label.new()
	_terrain_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_terrain_label.offset_left = 12
	_terrain_label.offset_right = 420
	_terrain_label.offset_top = -72
	_terrain_label.offset_bottom = -36
	_terrain_label.add_theme_font_size_override("font_size", 15)
	_terrain_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.65))
	_terrain_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_terrain_label.add_theme_constant_override("outline_size", 4)
	_terrain_label.text = ""
	_root.add_child(_terrain_label)
	_interior_label = Label.new()
	_interior_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_interior_label.offset_left = 12
	_interior_label.offset_right = 360
	_interior_label.offset_top = 48
	_interior_label.offset_bottom = 100
	_interior_label.add_theme_font_size_override("font_size", 16)
	_interior_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	_interior_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_interior_label.add_theme_constant_override("outline_size", 5)
	_interior_label.text = ""
	_root.add_child(_interior_label)

	_ctx_label = Label.new()
	_ctx_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_ctx_label.offset_left = -280
	_ctx_label.offset_right = -12
	_ctx_label.offset_top = 80
	_ctx_label.offset_bottom = 114
	_ctx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ctx_label.add_theme_font_size_override("font_size", 11)
	_ctx_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85, 0.9))
	_ctx_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_ctx_label.add_theme_constant_override("outline_size", 3)
	_root.add_child(_ctx_label)

	# Soft physics lead pip (center-ish, QoL only — never auto-aim)
	_lead_pip = ColorRect.new()
	_lead_pip.size = Vector2(10, 10)
	_lead_pip.color = Color(0.4, 0.95, 1.0, 0.55)
	_lead_pip.visible = false
	_root.add_child(_lead_pip)

	_edu_label = Label.new()
	_edu_label.position = Vector2(14, 114)
	_edu_label.add_theme_font_size_override("font_size", 13)
	_edu_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.4))
	_edu_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_edu_label.add_theme_constant_override("outline_size", 4)
	_edu_label.visible = false
	_root.add_child(_edu_label)

	_ability_label = Label.new()
	_ability_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_ability_label.offset_left = -320
	_ability_label.offset_right = 320
	_ability_label.offset_top = -90
	_ability_label.offset_bottom = -20
	_ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability_label.add_theme_font_size_override("font_size", 15)
	_ability_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_ability_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_ability_label.add_theme_constant_override("outline_size", 4)
	_root.add_child(_ability_label)

	_owner_label = Label.new()
	_owner_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_owner_label.offset_left = -280
	_owner_label.offset_right = -14
	_owner_label.offset_top = 118
	_owner_label.offset_bottom = 220
	_owner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_owner_label.add_theme_font_size_override("font_size", 13)
	_owner_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.55))
	_owner_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_owner_label.add_theme_constant_override("outline_size", 4)
	_root.add_child(_owner_label)

	# Contested full-width amber banner (threat-readable, not faction-skinned)
	_contest_banner = PanelContainer.new()
	_contest_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_contest_banner.offset_top = 0
	_contest_banner.offset_bottom = 36
	_contest_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.55, 0.22, 0.05, 0.82)
	style.border_color = Color(1.0, 0.55, 0.15, 0.95)
	style.set_border_width_all(2)
	_contest_banner.add_theme_stylebox_override("panel", style)
	_contest_label = Label.new()
	_contest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contest_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_contest_label.add_theme_font_size_override("font_size", 16)
	_contest_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_contest_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_contest_label.add_theme_constant_override("outline_size", 4)
	_contest_label.text = "CONTESTED ZONE"
	_contest_banner.add_child(_contest_label)
	_contest_banner.visible = false
	_root.add_child(_contest_banner)

	_claim_bar = ProgressBar.new()
	_claim_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_claim_bar.offset_top = 36
	_claim_bar.offset_bottom = 44
	_claim_bar.min_value = 0.0
	_claim_bar.max_value = 1.0
	_claim_bar.show_percentage = false
	_claim_bar.visible = false
	_root.add_child(_claim_bar)

	_channel_label = Label.new()
	_channel_label.set_anchors_preset(Control.PRESET_CENTER)
	_channel_label.offset_left = -120
	_channel_label.offset_right = 120
	_channel_label.offset_top = 40
	_channel_label.offset_bottom = 70
	_channel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_channel_label.add_theme_font_size_override("font_size", 18)
	_channel_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.65))
	_channel_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_channel_label.add_theme_constant_override("outline_size", 5)
	_channel_label.visible = false
	_root.add_child(_channel_label)

	_channel_bar = ProgressBar.new()
	_channel_bar.set_anchors_preset(Control.PRESET_CENTER)
	_channel_bar.offset_left = -140
	_channel_bar.offset_right = 140
	_channel_bar.offset_top = 72
	_channel_bar.offset_bottom = 88
	_channel_bar.min_value = 0.0
	_channel_bar.max_value = 1.0
	_channel_bar.show_percentage = false
	_channel_bar.visible = false
	_root.add_child(_channel_bar)

	_toast_label = Label.new()
	_toast_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast_label.offset_left = -280
	_toast_label.offset_right = 280
	_toast_label.offset_top = -140
	_toast_label.offset_bottom = -100
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 15)
	_toast_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	_toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_toast_label.add_theme_constant_override("outline_size", 5)
	_toast_label.visible = false
	_root.add_child(_toast_label)

	# Mini pad radar (bottom-left, above the vitals block at y=-118..-18)
	_radar = Control.new()
	_radar.position = Vector2(14, -300)
	_radar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_radar.offset_left = 14
	_radar.offset_top = -300
	_radar.offset_right = 150
	_radar.offset_bottom = -164
	_radar.custom_minimum_size = Vector2(136, 136)
	_radar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rpanel := Panel.new()
	rpanel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0.02, 0.06, 0.1, 0.72)
	rs.border_color = Color(0.3, 0.75, 0.95, 0.65)
	rs.set_border_width_all(1)
	rs.corner_radius_top_left = 68
	rs.corner_radius_top_right = 68
	rs.corner_radius_bottom_left = 68
	rs.corner_radius_bottom_right = 68
	rpanel.add_theme_stylebox_override("panel", rs)
	rpanel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radar.add_child(rpanel)
	var rtitle := Label.new()
	rtitle.text = "PADS"
	rtitle.name = "PadTitle"
	rtitle.position = Vector2(40, 4)
	rtitle.add_theme_font_size_override("font_size", 11)
	rtitle.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0, 0.85))
	_radar.add_child(rtitle)
	# player center pip
	var self_pip := ColorRect.new()
	self_pip.size = Vector2(6, 6)
	self_pip.position = Vector2(65, 65)
	self_pip.color = Color(0.95, 0.95, 1.0)
	_radar.add_child(self_pip)
	for i in 12:
		var d := ColorRect.new()
		d.size = Vector2(5, 5)
		d.color = Color(0.2, 0.9, 1.0)
		d.visible = false
		_radar.add_child(d)
		_radar_dots.append(d)
	_root.add_child(_radar)
	_build_play_chrome()

func _process(d: float) -> void:
	_econ_flash = maxf(0.0, _econ_flash - d)
	if _toast_ttl > 0.0:
		_toast_ttl -= d
		if _toast_ttl <= 0.0:
			_pop_toast()
	_hud_accum += d
	# Full HUD refresh ~8 Hz (was every frame — FileAccess + group scans)
	if _hud_accum < 0.12:
		return
	_hud_accum = 0.0
	_refresh()

func _alive_player() -> Node:
	if _player != null and is_instance_valid(_player):
		return _player
	_player = null
	_ability_sys = null
	return null


func _interior_director() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("interior_director"):
		if n != null and is_instance_valid(n) and n.has_method("is_inside") and bool(n.is_inside()):
			return n
	return null


func _in_interior_pocket() -> bool:
	if _interior_director() != null:
		return true
	if LayerContext:
		var ly := str(LayerContext.current_layer).to_lower()
		if ly in ["ship_int", "station", "interior"]:
			return true
	return false


func _apply_interior_chrome(pocket: bool) -> void:
	## Pocket: keep HP/EN, infection pips, ability chips, life-support, toasts, channel.
	## Hide planet/space chrome that still thinks the walker is on the pad.
	if not pocket:
		if _owner_label:
			_owner_label.visible = true
		if _layer_label:
			_layer_label.visible = true
		return
	if _radar:
		_radar.visible = false
	if _owner_label:
		_owner_label.visible = false
	if _terrain_label:
		_terrain_label.visible = false
	if _econ_label:
		_econ_label.visible = false
	if _econ_bar:
		_econ_bar.visible = false
	if _contest_banner:
		_contest_banner.visible = false
	if _claim_bar:
		_claim_bar.visible = false
	if _obj_label:
		_obj_label.visible = false
	if _layer_label:
		_layer_label.visible = false
	if _lead_pip:
		_lead_pip.visible = false
	if _edu_label:
		_edu_label.visible = false
	if _ctx_label:
		_ctx_label.visible = false


func _in_clash_arena() -> bool:
	var tree := get_tree()
	return tree != null and tree.current_scene != null and str(tree.current_scene.name) == "TestArena"


func _apply_clash_chrome() -> void:
	if not _in_clash_arena():
		return
	if _debug_overlay:
		# ClashMatchDirector owns the top-right ScoreLine and TestArena owns the
		# top-left lane line. Give the F3 dump one deterministic left column so
		# nothing lands on top of anything else.
		if _infection_label:
			_infection_label.position = Vector2(14, 70)
		if _status_label:
			_status_label.position = Vector2(14, 100)
		if _mastery_label:
			_mastery_label.position = Vector2(14, 148)
		if _econ_label:
			_econ_label.visible = true
			_econ_label.position = Vector2(14, 172)
		if _econ_bar:
			_econ_bar.visible = true
			_econ_bar.position = Vector2(14, 194)
		if _obj_label:
			_obj_label.visible = false
		if _layer_label:
			_layer_label.visible = false
		if _ctx_label:
			_ctx_label.offset_top = 138
			_ctx_label.offset_bottom = 170
		return
	if _obj_label:
		_obj_label.visible = false
	if _layer_label:
		_layer_label.visible = false
	if _terrain_label:
		_terrain_label.visible = false
	if _econ_label:
		_econ_label.visible = false
	if _econ_bar:
		_econ_bar.visible = false


func _refresh() -> void:
	var director: Node = _interior_director()
	var pocket: bool = director != null
	if not pocket and LayerContext:
		var ly := str(LayerContext.current_layer).to_lower()
		pocket = ly in ["ship_int", "station", "interior"]
	if not pocket:
		_refresh_economy()
	var actor: Node = _alive_player()
	_refresh_ability_bar()
	_apply_debug_vis()
	_refresh_play_chrome()
	if _obj_label and SessionObjectives:
		_obj_label.visible = not pocket
		if _obj_label.visible:
			_obj_label.text = SessionObjectives.briefing()
	var hp := "?"
	var en := "?"
	var fac := "?"
	var form := ""
	if actor:
		if "health" in actor:
			hp = str(int(actor.health))
		if "energy" in actor:
			en = str(int(actor.energy))
		if actor.has_method("get_faction"):
			fac = str(actor.get_faction())
		if "current_form" in actor:
			form = str(actor.current_form)
		elif "form_name" in actor:
			form = str(actor.form_name)
	var contrib := 0.0
	if GameManager:
		contrib = GameManager.contribution
		if fac == "?":
			fac = GameManager.get_faction_name()
	var net := ""
	if SoftENet and SoftENet.has_method("status_line"):
		net = "  |  " + str(SoftENet.status_line())
	var host_hint := _host_hint_cache
	_host_hint_t += 0.12
	if SoftENet and SoftENet.is_host and _host_hint_t >= 2.0:
		_host_hint_t = 0.0
		host_hint = SoftScanCache.host_hint() if SoftScanCache else ""
		_host_hint_cache = host_hint
	elif not (SoftENet and SoftENet.is_host):
		_host_hint_cache = ""
		host_hint = ""
	var eva_line := ""
	if _player and is_instance_valid(_player) and "eva_mode" in _player and bool(_player.eva_mode):
		var mag_s := ""
		if "mag_boot" in _player:
			if "_mag_latched" in _player and bool(_player._mag_latched):
				mag_s = " MAG:LATCH"
			elif bool(_player.mag_boot):
				mag_s = " MAG:ARM"
			else:
				mag_s = " MAG:off"
		var tether_s := ""
		var tree_e := get_tree()
		if tree_e:
			var osp = tree_e.get_first_node_in_group("open_space")
			if osp and osp.has_method("eva_tether_distance"):
				var td: float = float(osp.eva_tether_distance())
				if td >= 0.0:
					tether_s = "  tether %.0fm" % td
		var zg_s := ""
		if _player.has_method("is_zero_g") and bool(_player.is_zero_g()):
			zg_s = " 0G"
		eva_line = "  |  EVA%s%s%s" % [zg_s, mag_s, tether_s]
	var sys_line := ""
	if not pocket and LayerContext and str(LayerContext.current_layer) in ["Space", "space"]:
		var tree_s := get_tree()
		if tree_s:
			for sh in tree_s.get_nodes_in_group("ship"):
				if sh.has_method("get_soft_systems_line"):
					var sl := str(sh.get_soft_systems_line()) if sh.has_method("get_soft_systems_line") else ""
					var fl := str(sh.get_flight_status_line()) if sh.has_method("get_flight_status_line") else ""
					if fl != "" or sl != "":
						sys_line = "\nSHIP  " + fl
						if sl != "":
							sys_line += "  ·  " + sl
						break
	# Debug-only block: skip the string build when it is not on screen.
	if _status_label.visible:
		_status_label.text = "HP %s  EN %s  |  %s %s%s%s%s\nCONTRIB %.0f  ·  V=form F9=fac F10=host F11=join  (no P2W)%s" % [hp, en, fac, form, net, host_hint, eva_line, contrib, sys_line]

	# Terrain budget + interior status (soft info only)
	if _terrain_label:
		if pocket:
			_terrain_label.visible = false
		else:
			_terrain_t += 0.12
			if _terrain_t >= 0.5:
				_terrain_t = 0.0
				var tline := ""
				var tree_t := get_tree()
				if tree_t and _player:
					for n in (SoftScanCache.get_terrain_edits() if SoftScanCache else tree_t.get_nodes_in_group("terrain_edit")):
						if n.has_method("get_budget_ratio") and n.has_method("remaining_volume"):
							var pct := int(clampf(float(n.get_budget_ratio()), 0.0, 1.0) * 100.0)
							var rem := float(n.remaining_volume())
							tline = "TERRAIN  used %d%%  rem %.0f m³  ·  G raise B dig U undo" % [pct, rem]
							break
				_terrain_cache = tline
			_terrain_label.text = _terrain_cache
			_terrain_label.visible = _terrain_cache != ""
	if _interior_label:
		var iline := ""
		if director:
			var k := "pocket"
			if director.has_method("get_kind"):
				k = str(director.get_kind())
			var ctx := "I"
			if director.has_method("is_near_seat") and _player and director.is_near_seat(_player):
				ctx = "F seat · I"
			elif director.has_method("is_near_console") and _player and director.is_near_console(_player):
				ctx = "E ops · I"
			var ls := ""
			if director.has_method("life_support_line"):
				ls = str(director.life_support_line())
			iline = "%s · %s" % [k, ctx]
			if ls != "":
				iline += "\n" + ls
		elif pocket:
			iline = "pocket · I"
		_interior_label.text = iline
		_interior_label.visible = iline != ""

	# The contested banner is written once, from the pad_bases pass further down.

	# Layer chip + GFX/FPS stacked (do not sit on OpenSpace Mode)
	if _layer_label:
		var ly := "SPACE"
		var st := ""
		if LayerContext:
			ly = str(LayerContext.current_layer).to_upper()
			st = str(LayerContext.seamless_stage)
		var fps := Engine.get_frames_per_second()
		_layer_label.text = "LAYER · %s%s\nGFX %s · %d FPS · %dMB" % [
			ly,
			("  [%s]" % st) if st != "" else "",
			_gfx_name,
			fps,
			_gfx_mem_mb,
		]
	if _ctx_label and LayerContext:
		var q := LayerContext.active_quest_id if LayerContext.active_quest_id != "" else "—"
		var c := LayerContext.active_claim_id if LayerContext.active_claim_id != "" else "—"
		var pin := LayerContext.site_pin_id if LayerContext.site_pin_id != "" else "—"
		var risk := int(LayerContext.cargo_risk * 100.0)
		_ctx_label.text = "quest %s | claim %s | pin %s | cargo risk %d%%" % [q, c, pin, risk]

	# Soft physics lead marker (mastery ≥20) — visual aid only
	if _lead_pip:
		var show_lead := _SoftK.lead_marker_visible()
		_lead_pip.visible = show_lead and _player != null
		if _lead_pip.visible:
			var sc: float = _SoftK.lead_marker_scale()
			_lead_pip.size = Vector2(8, 8) * sc
			# Place slightly above crosshair center (prediction hint, not lock)
			var vp := get_viewport().get_visible_rect().size
			_lead_pip.position = Vector2(vp.x * 0.5 - _lead_pip.size.x * 0.5, vp.y * 0.48 - 12.0 * sc)

	# Soft Knowledge mastery line (informational only — never combat power)
	if GameManager and _mastery_label:
		var m: Dictionary = GameManager.subject_mastery
		var ops_key := "biomass_ops" if GameManager.get_faction_name() == "gROT" else "colony_ops"
		var colony: float = float(m.get(ops_key, 0.0))
		var bio: float = float(m.get("biology", 0.0))
		var rank: int = int(GameManager.knowledge_rank)
		var soft: float = float(GameManager.knowledge_insight_bonus()) * 100.0
		var ar := GameManager.get_alliance_rank_name() if GameManager.has_method("get_alliance_rank_name") else ""
		_mastery_label.text = "KNOWLEDGE r%d | %s %.1f | bio %.0f | insight +%.1f%% | %s | rank %s" % [rank, ops_key, colony, bio, soft, GameManager.economy_label(), ar]

	# Infection pips — always visible (shape + number, max 5)
	var stacks := 0
	var glitch := false
	if _player:
		var inf = _player.get_node_or_null("InfectionStatus")
		if inf:
			stacks = int(inf.stacks)
			glitch = float(inf.glitch_timer) > 0.0
	var pips := ""
	for i in 5:
		pips += "●" if i < stacks else "○"
	var stage: String = _SoftK.infection_label(stacks)
	if stage == "":
		stage = "INF %s  %d/5" % [pips, stacks]
	else:
		stage = "%s  %s %d/5" % [stage, pips, stacks]
	_infection_label.text = "%s%s" % [stage, "  GLITCH" if glitch else ""]
	# Visibility is owned by _apply_debug_vis — do not fight it here.

	# Ability chips and the channel bar are written by _refresh_ability_bar /
	# _update_channel_hud, which _refresh already called.

	# Nearest pad ownership + contested banner
	var nearest := ""
	var contested_near := false
	var claim_ratio := 0.0
	var tree := get_tree()
	if not pocket and tree and _player and _player is Node3D:
		var best_d := 80.0
		var best_txt := ""
		for n in (SoftScanCache.get_pads() if SoftScanCache else tree.get_nodes_in_group("pad_bases")):
			if n is Node3D and n.has_method("get_faction"):
				var d: float = (_player as Node3D).global_position.distance_to((n as Node3D).global_position)
				if d < best_d:
					best_d = d
					var need := 1.75
					if n.has_method("get_claim_need"):
						need = float(n.get_claim_need())
					var st := ""
					if n.has_method("get_claim_status"):
						st = str(n.get_claim_status())
					elif "_status" in n:
						st = str(n.get("_status"))
					var cs := 0.0
					if "ownership" in n and n.ownership:
						cs = float(n.ownership.claim_strength)
					claim_ratio = clampf(cs / maxf(need, 0.01), 0.0, 1.0)
					var side := ""
					if n.has_method("get_contest_side"):
						side = str(n.get_contest_side())
					if side != "" and st == "contested":
						best_txt = "PAD %s  occupy→%s %d%%  (%.0fm)" % [n.get_faction(), side, int(claim_ratio * 100.0), d]
					elif st == "extracting" and n.has_method("harvest_hud_line"):
						var hl := str(n.harvest_hud_line())
						best_txt = "PAD %s  %s  (%.0fm)" % [n.get_faction(), hl, d] if hl != "" else "PAD %s  extracting  (%.0fm)" % [n.get_faction(), d]
					elif n.has_method("pad_repair_hud_line"):
						var rl := str(n.pad_repair_hud_line())
						if rl != "":
							best_txt = "PAD %s  %s  (%.0fm)" % [n.get_faction(), rl, d]
						else:
							best_txt = "PAD %s  %s  claim %.0f%%  (%.0fm)" % [n.get_faction(), st, claim_ratio * 100.0, d]
					else:
						best_txt = "PAD %s  %s  claim %.0f%%  (%.0fm)" % [n.get_faction(), st, claim_ratio * 100.0, d]
					if st == "contested" or str(n.get_faction()) == "Contested":
						contested_near = true
		nearest = best_txt

	# Terrain budget
	var terra := ""
	if not pocket and _player and _player is Node3D and get_tree():
		for n in (SoftScanCache.get_terrain_edits() if SoftScanCache else get_tree().get_nodes_in_group("terrain_edit")):
			if n.has_method("get_budget_ratio") and n.visible:
				terra = "TERRA %.0f%% used  G/B edit  U undo" % (float(n.get_budget_ratio()) * 100.0)
				break
	if terra != "":
		nearest = (nearest + "\n" + terra) if nearest else terra
	if _owner_label:
		_owner_label.text = nearest

	if _contest_banner:
		_contest_banner.visible = contested_near
		if contested_near:
			var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.01)
			_contest_label.text = "CONTESTED — occupy to hold · C pulse · Hack  ·  %d%%" % int(claim_ratio * 100.0)
			var st := _contest_banner.get_theme_stylebox("panel") as StyleBoxFlat
			if st:
				st.bg_color = Color(0.55, 0.18, 0.04, 0.55 + pulse * 0.35)
	if _claim_bar:
		_claim_bar.visible = contested_near
		_claim_bar.value = claim_ratio

	# Edu quest prompt
	if _edu_label:
		var eq = _edu_quest
		if eq == null and _player:
			eq = _player.get_node_or_null("EduQuestStub")
			_edu_quest = eq
		if eq and eq.has_method("is_active") and eq.is_active():
			_edu_label.visible = true
			_edu_label.text = "EDU [T] %s  |  type answer via T cycle · Y skip" % eq.get_prompt()
		else:
			_edu_label.visible = false

	# Channel bar is owned by _update_channel_hud (called above).

	if contested_near:
		_owner_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
	elif _owner_label:
		_owner_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.55))

	# Pad radar — skip in pocket (no pads at y=9200)
	if not pocket and _radar and _radar.visible and _player and _player is Node3D and get_tree():
		var origin: Vector3 = (_player as Node3D).global_position
		var pads: Array = []
		for n in (SoftScanCache.get_pads() if SoftScanCache else get_tree().get_nodes_in_group("pad_bases")):
			if n is Node3D and n.is_inside_tree():
				pads.append(n)
		# One distance per pad, then sort — the old O(n^2) swap recomputed two
		# distances per comparison, eight times a second.
		pads.sort_custom(func(a, b): return a.global_position.distance_squared_to(origin) \
			< b.global_position.distance_squared_to(origin))
		var title_n := _radar.get_node_or_null("PadTitle") as Label
		if title_n:
			title_n.text = "PADS %d" % pads.size()
		var range_m := 400.0
		for i in _radar_dots.size():
			var dot: ColorRect = _radar_dots[i]
			if i >= pads.size():
				dot.visible = false
				continue
			var p: Node3D = pads[i]
			var off: Vector3 = p.global_position - origin
			var up := Vector3.UP
			var up_val = _player.get("_up")
			if up_val != null and typeof(up_val) == TYPE_VECTOR3:
				up = up_val
			elif p.has_meta("pad_up"):
				up = p.get_meta("pad_up")
			var flat: Vector3 = off - up * off.dot(up)
			var dist := flat.length()
			if dist > range_m:
				dot.visible = false
				continue
			var east := up.cross(Vector3.FORWARD)
			if east.length_squared() < 0.05:
				east = up.cross(Vector3.RIGHT)
			east = east.normalized()
			var north := east.cross(up).normalized()
			var nx := flat.dot(east)
			var nz := flat.dot(north)
			var sc := 60.0 / range_m
			var pip := Vector2(nx * sc, nz * sc)
			# One nearby pad sat on the center pip and looked like an empty radar.
			if pip.length() < 16.0:
				if pip.length_squared() < 0.01:
					pip = Vector2(0, -18)
				else:
					pip = pip.normalized() * 18.0
			dot.position = Vector2(65.0 + pip.x - 3.0, 65.0 + pip.y - 3.0)
			dot.size = Vector2(7, 7)
			var pad_fac := "Neutral"
			if p.has_method("get_faction"):
				pad_fac = str(p.get_faction())
			match pad_fac:
				"Cybernex":
					dot.color = Color(0.2, 0.85, 1.0)
				"gROT":
					dot.color = Color(0.95, 0.2, 0.45)
				"Contested":
					dot.color = Color(1.0, 0.6, 0.15)
				_:
					dot.color = Color(0.7, 0.7, 0.75)
			dot.visible = true
	_apply_interior_chrome(pocket)
	_apply_clash_chrome()

func _on_gm_toast(msg: String) -> void:
	push_toast(msg, 3.0)


func _soft_infection_text(stacks: int) -> String:
	# CONCEPT §7.3 Biology mastery — stage labels only
	return _SoftK.infection_label(stacks)


func _refresh_ability_bar() -> void:
	if _ability_label == null:
		return
	var actor: Node = _alive_player()
	if _ability_sys != null and not is_instance_valid(_ability_sys):
		_ability_sys = null
	if _ability_sys == null and actor:
		_ability_sys = actor.get_node_or_null("AbilitySystem")
	if _ability_sys == null or not is_instance_valid(_ability_sys):
		_ability_sys = null
		_ability_label.text = ""
		return
	var keys := ["Q", "E", "R", "F"]
	var parts: PackedStringArray = []
	for i in range(4):
		var nm := "—"
		var cd_r := 0.0
		if _ability_sys.has_method("get_slot_label"):
			nm = str(_ability_sys.get_slot_label(i))
		if _ability_sys.has_method("get_cooldown_ratio"):
			cd_r = float(_ability_sys.get_cooldown_ratio(i))
		if cd_r > 0.05:
			parts.append("%s[%s]" % [keys[i], nm])
		else:
			parts.append("%s %s" % [keys[i], nm])
	_ability_label.text = "  ·  ".join(parts)



func _on_econ_tick(_v: float = 0.0) -> void:
	if GameManager == null:
		return
	var cur := GameManager.biomass if GameManager.get_faction_name() == "gROT" else GameManager.contribution
	if _econ_last >= 0.0:
		_econ_delta = cur - _econ_last
		if absf(_econ_delta) > 0.01:
			_econ_flash = 1.2
	_econ_last = cur
	_refresh_economy()


func _refresh_economy() -> void:
	if _econ_label == null or GameManager == null:
		return
	var fac := GameManager.get_faction_name()
	var cur: float = GameManager.biomass if fac == "gROT" else GameManager.contribution
	var label_n := "BIOMASS" if fac == "gROT" else "CONTRIB"
	var rank: int = int(GameManager.alliance_rank) if "alliance_rank" in GameManager else 0
	var next_cost: float = float(GameManager.next_alliance_cost()) if GameManager.has_method("next_alliance_cost") else float(_AllianceRanks.next_rank_cost_contribution(rank))
	var rname: String = str(_AllianceRanks.rank_name(rank))
	var ratio := 1.0
	if next_cost > 0.0:
		ratio = clampf(cur / next_cost, 0.0, 1.0)
	var delta_s := ""
	if _econ_flash > 0.0 and absf(_econ_delta) > 0.01:
		delta_s = "  %+0.1f" % _econ_delta
	_econ_label.text = "%s %.1f%s  ·  %s  → next %.0f  ·  soft only (no P2W)" % [
		label_n, cur, delta_s, rname, next_cost
	]
	if _econ_flash > 0.0:
		var pulse := 0.5 + 0.5 * (_econ_flash / 1.2)
		_econ_label.modulate = Color(0.55, 1.0, 0.75).lerp(Color(1.0, 1.0, 0.5), pulse)
	else:
		_econ_label.modulate = Color(0.55, 1.0, 0.75) if fac != "gROT" else Color(1.0, 0.55, 0.7)
	if _econ_bar:
		_econ_bar.value = ratio
		_econ_bar.modulate = Color(0.35, 0.95, 0.65) if fac != "gROT" else Color(0.95, 0.35, 0.55)



func _update_channel_hud() -> void:
	if _channel_bar == null and _channel_label == null:
		return
	var ratio := 0.0
	var name := ""
	var ch: Node = null
	var actor: Node = _alive_player()
	if actor:
		ch = actor.get_node_or_null("ChannelController")
	if _ability_sys != null and not is_instance_valid(_ability_sys):
		_ability_sys = null
	if ch and is_instance_valid(ch) and ch.has_method("is_channeling") and ch.is_channeling():
		ratio = float(ch.get_ratio()) if ch.has_method("get_ratio") else 0.0
		name = str(ch.ability_name) if "ability_name" in ch else "Channel"
	elif _ability_sys and is_instance_valid(_ability_sys) and _ability_sys.has_method("get_channel_ratio"):
		ratio = float(_ability_sys.get_channel_ratio())
		if ratio > 0.01:
			name = "Channel"
	if _channel_bar:
		_channel_bar.visible = ratio > 0.0
		_channel_bar.value = ratio
	if _channel_label:
		_channel_label.visible = ratio > 0.0
		if ratio > 0.0:
			_channel_label.text = "%s  %d%%" % [name, int(ratio * 100.0)]


func set_gfx_line(tier_name: String, mem_mb: int) -> void:
	_gfx_name = tier_name
	_gfx_mem_mb = mem_mb


func is_debug_overlay() -> bool:
	return _debug_overlay


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: int = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
	if k == KEY_F3 or event.physical_keycode == KEY_F3:
		_debug_overlay = not _debug_overlay
		_apply_debug_vis()
		_apply_interior_chrome(_in_interior_pocket())
		_apply_clash_chrome()
		if GameManager:
			GameManager.toast_requested.emit("HUD debug %s" % ("ON" if _debug_overlay else "OFF"))
		get_viewport().set_input_as_handled()


func _flat(col: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0, radius: int = 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.border_color = border
	s.set_border_width_all(bw)
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


func _style_bar(bar: ProgressBar, fill: Color, bg: Color) -> void:
	bar.add_theme_stylebox_override("fill", _flat(fill, Color(0, 0, 0, 0), 0, 3))
	bar.add_theme_stylebox_override("background", _flat(bg, Color(0.2, 0.3, 0.4, 0.5), 1, 3))
	bar.show_percentage = false


func _build_play_chrome() -> void:
	if _chrome_built or _root == null:
		return
	_chrome_built = true
	var vitals := Control.new()
	vitals.name = "PlayVitals"
	vitals.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	vitals.offset_left = 18
	vitals.offset_top = -118
	vitals.offset_right = 280
	vitals.offset_bottom = -18
	vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(vitals)
	_hp_tag = Label.new()
	_hp_tag.text = "HP"
	_hp_tag.position = Vector2(0, 0)
	_hp_tag.add_theme_font_size_override("font_size", 12)
	_hp_tag.add_theme_color_override("font_color", Color(1.0, 0.45, 0.48))
	_hp_tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hp_tag.add_theme_constant_override("outline_size", 3)
	vitals.add_child(_hp_tag)
	_hp_bar = ProgressBar.new()
	_hp_bar.position = Vector2(28, 2)
	_hp_bar.size = Vector2(210, 16)
	_hp_bar.max_value = 100
	_hp_bar.value = 100
	_style_bar(_hp_bar, Color(0.82, 0.18, 0.28, 0.95), Color(0.06, 0.04, 0.05, 0.82))
	vitals.add_child(_hp_bar)
	_en_tag = Label.new()
	_en_tag.text = "EN"
	_en_tag.position = Vector2(0, 22)
	_en_tag.add_theme_font_size_override("font_size", 12)
	_en_tag.add_theme_color_override("font_color", Color(0.45, 0.9, 1.0))
	_en_tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_en_tag.add_theme_constant_override("outline_size", 3)
	vitals.add_child(_en_tag)
	_en_bar = ProgressBar.new()
	_en_bar.position = Vector2(28, 24)
	_en_bar.size = Vector2(210, 14)
	_en_bar.max_value = 100
	_en_bar.value = 100
	_style_bar(_en_bar, Color(0.15, 0.75, 0.95, 0.95), Color(0.04, 0.07, 0.1, 0.82))
	vitals.add_child(_en_bar)
	_pip_row = HBoxContainer.new()
	_pip_row.position = Vector2(28, 44)
	_pip_row.add_theme_constant_override("separation", 5)
	vitals.add_child(_pip_row)
	var inf_tag := Label.new()
	inf_tag.text = "INF"
	inf_tag.add_theme_font_size_override("font_size", 11)
	inf_tag.add_theme_color_override("font_color", Color(1.0, 0.4, 0.55))
	inf_tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	inf_tag.add_theme_constant_override("outline_size", 3)
	_pip_row.add_child(inf_tag)
	for i in 5:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(12, 12)
		pip.color = Color(0.25, 0.12, 0.16, 0.85)
		_pip_row.add_child(pip)
		_pips.append(pip)
	_slot_row = HBoxContainer.new()
	_slot_row.name = "AbilitySlots"
	_slot_row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_slot_row.offset_left = -300
	_slot_row.offset_right = 300
	_slot_row.offset_top = -78
	_slot_row.offset_bottom = -14
	_slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_slot_row.add_theme_constant_override("separation", 8)
	_slot_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_slot_row)
	var keys := ["Q", "E", "R", "F"]
	for i in 4:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(118, 56)
		panel.add_theme_stylebox_override("panel", _flat(Color(0.05, 0.09, 0.14, 0.82), Color(0.25, 0.75, 0.95, 0.55), 1, 6))
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 0)
		var key_l := Label.new()
		key_l.text = keys[i]
		key_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_l.add_theme_font_size_override("font_size", 11)
		key_l.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
		var name_l := Label.new()
		name_l.text = "—"
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.add_theme_font_size_override("font_size", 13)
		name_l.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
		name_l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		name_l.add_theme_constant_override("outline_size", 3)
		var cd_l := Label.new()
		cd_l.text = "ready"
		cd_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_l.add_theme_font_size_override("font_size", 11)
		cd_l.add_theme_color_override("font_color", Color(0.45, 0.95, 0.65))
		vbox.add_child(key_l)
		vbox.add_child(name_l)
		vbox.add_child(cd_l)
		panel.add_child(vbox)
		_slot_row.add_child(panel)
		_slots.append({"panel": panel, "name": name_l, "cd": cd_l})
	if _obj_label:
		_obj_label.add_theme_font_size_override("font_size", 15)
		_obj_label.offset_top = 6
		_obj_label.offset_bottom = 36
	_apply_debug_vis()


func _apply_debug_vis() -> void:
	var dbg := _debug_overlay
	if _status_label:
		_status_label.visible = dbg
	if _mastery_label:
		_mastery_label.visible = dbg
	if _ctx_label:
		_ctx_label.visible = dbg
	if _ability_label:
		_ability_label.visible = dbg
	if _infection_label:
		_infection_label.visible = dbg
	if _econ_label:
		_econ_label.visible = true
		# Own row above OpenSpace Hint (y=80). y=52 sat on the flight line
		# and read as "(no P2W)HOVER · Nex-Prime…".
		_econ_label.position = Vector2(14, 40) if not dbg else Vector2(14, 128)
	if _econ_bar:
		_econ_bar.visible = true
		_econ_bar.position = Vector2(14, 58) if not dbg else Vector2(14, 148)
	if _slot_row:
		_slot_row.visible = not dbg
	if _radar:
		var clash := false
		var tree := get_tree()
		if tree and tree.current_scene:
			clash = str(tree.current_scene.name) == "TestArena"
		_radar.visible = (not clash) or dbg


func _refresh_play_chrome() -> void:
	if not _chrome_built:
		return
	if _player and is_instance_valid(_player):
		if "health" in _player and "max_health" in _player and _hp_bar:
			var hp_now := float(_player.health)
			var hp_max := float(_player.max_health)
			if "shields" in _player and "max_shields" in _player:
				hp_now += float(_player.shields)
				hp_max += float(_player.max_shields)
			_hp_bar.max_value = maxf(1.0, hp_max)
			_hp_bar.value = hp_now
			if _hp_tag:
				if "shields" in _player:
					_hp_tag.text = "%d +%d" % [int(_player.health), int(_player.shields)]
				else:
					_hp_tag.text = "%d" % int(_player.health)
		if "energy" in _player and "max_energy" in _player and _en_bar:
			_en_bar.max_value = maxf(1.0, float(_player.max_energy))
			_en_bar.value = float(_player.energy)
			if _en_tag:
				_en_tag.text = "%d" % int(_player.energy)
		var stacks := 0
		var inf = _player.get_node_or_null("InfectionStatus")
		if inf:
			stacks = int(inf.stacks)
		for i in _pips.size():
			var pip: ColorRect = _pips[i]
			if i < stacks:
				pip.color = Color(0.95, 0.2, 0.42, 0.95)
			else:
				pip.color = Color(0.22, 0.1, 0.14, 0.75)
	if _ability_sys != null and not is_instance_valid(_ability_sys):
		_ability_sys = null
	if _ability_sys == null and _player != null and is_instance_valid(_player):
		_ability_sys = _player.get_node_or_null("AbilitySystem")
	var keys := ["Q", "E", "R", "F"]
	for i in _slots.size():
		var slot: Dictionary = _slots[i]
		var nm := "—"
		var cd := 0.0
		if _ability_sys != null and is_instance_valid(_ability_sys):
			if _ability_sys.has_method("get_slot_label"):
				nm = str(_ability_sys.get_slot_label(i))
			elif "abilities" in _ability_sys and i < _ability_sys.abilities.size() and _ability_sys.abilities[i]:
				nm = str(_ability_sys.abilities[i].ability_name)
			if _ability_sys.has_method("get_cooldown_remaining"):
				cd = float(_ability_sys.get_cooldown_remaining(i))
		var short := nm
		if short.length() > 12:
			short = short.substr(0, 11)
		(slot["name"] as Label).text = short
		var cd_l: Label = slot["cd"]
		var panel: PanelContainer = slot["panel"]
		if cd > 0.05:
			cd_l.text = "%.1fs" % cd
			cd_l.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
			panel.modulate = Color(0.7, 0.75, 0.8, 0.95)
		else:
			cd_l.text = keys[i] + " ready"
			cd_l.add_theme_color_override("font_color", Color(0.45, 0.95, 0.65))
			panel.modulate = Color.WHITE
