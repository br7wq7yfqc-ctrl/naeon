extends CanvasLayer
class_name GameHUD
const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
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
var _layer_label: Label
var _lead_pip: ColorRect
var _ctx_label: Label
var _edu_label: Label
var _edu_quest: Node = null
var _toast_label: Label
var _claim_bar: ProgressBar
var _player: Node
var _ability_sys: Node
var _toast_ttl: float = 0.0
var _toast_queue: Array = []
var _radar: Control
var _radar_dots: Array = []

func _ready() -> void:
	layer = 20
	add_to_group("game_hud")
	_build()
	set_process(true)
	if GameManager and GameManager.has_signal("toast_requested"):
		if not GameManager.toast_requested.is_connected(_on_gm_toast):
			GameManager.toast_requested.connect(_on_gm_toast)

func bind_player(p: Node) -> void:
	_player = p
	if p:
		_ability_sys = p.get_node_or_null("AbilitySystem")
		if _ability_sys == null and p.get_child_count() > 0:
			for c in p.get_children():
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

	_layer_label = Label.new()
	_layer_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_layer_label.offset_left = -220
	_layer_label.offset_right = -12
	_layer_label.offset_top = 10
	_layer_label.offset_bottom = 36
	_layer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_layer_label.add_theme_font_size_override("font_size", 16)
	_layer_label.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0))
	_layer_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_layer_label.add_theme_constant_override("outline_size", 5)
	_layer_label.text = "LAYER · SPACE"
	_root.add_child(_layer_label)

	_ctx_label = Label.new()
	_ctx_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_ctx_label.offset_left = -280
	_ctx_label.offset_right = -12
	_ctx_label.offset_top = 36
	_ctx_label.offset_bottom = 70
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
	_owner_label.offset_top = 12
	_owner_label.offset_bottom = 120
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

	# Mini pad radar (bottom-left)
	_radar = Control.new()
	_radar.position = Vector2(14, -170)
	_radar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_radar.offset_left = 14
	_radar.offset_top = -170
	_radar.offset_right = 150
	_radar.offset_bottom = -34
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
	rtitle.position = Vector2(48, 4)
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

func _process(d: float) -> void:
	if _toast_ttl > 0.0:
		_toast_ttl -= d
		if _toast_ttl <= 0.0:
			_pop_toast()
	_refresh()

func _refresh() -> void:
	var hp := "?"
	var en := "?"
	var fac := "?"
	var form := ""
	if _player:
		if "health" in _player:
			hp = str(int(_player.health))
		if "energy" in _player:
			en = str(int(_player.energy))
		if _player.has_method("get_faction"):
			fac = str(_player.get_faction())
		if "current_form" in _player:
			form = str(_player.current_form)
		elif "form_name" in _player:
			form = str(_player.form_name)
	var contrib := 0.0
	if GameManager:
		contrib = GameManager.contribution
		if fac == "?":
			fac = GameManager.get_faction_name()
	_status_label.text = "HP %s  EN %s  |  %s %s\nCONTRIB %.0f  ·  4=form F9=faction  (no P2W)" % [hp, en, fac, form, contrib]

	# Layer chip + context (S1 seamless)
	if _layer_label and LayerContext:
		_layer_label.text = "LAYER · %s  [%s]" % [LayerContext.current_layer.to_upper(), LayerContext.seamless_stage]
	if _ctx_label and LayerContext:
		var q := LayerContext.active_quest_id if LayerContext.active_quest_id != "" else "—"
		var c := LayerContext.active_claim_id if LayerContext.active_claim_id != "" else "—"
		var risk := int(LayerContext.cargo_risk * 100.0)
		_ctx_label.text = "quest %s | claim %s | cargo risk %d%%" % [q, c, risk]

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

	# Infection pips — always visible danger colour
	var stacks := 0
	var glitch := false
	if _player:
		var inf = _player.get_node_or_null("InfectionStatus")
		if inf:
			stacks = int(inf.stacks)
			glitch = float(inf.glitch_timer) > 0.0
	if stacks > 0:
		var pips := ""
		for i in 5:
			pips += "●" if i < stacks else "○"
		var stage: String = _SoftK.infection_label(stacks)
		if stage == "":
			stage = "INFECTION %s" % pips
		_infection_label.text = "%s%s" % [stage, "  GLITCH" if glitch else ""]
		_infection_label.visible = true
	else:
		_infection_label.visible = false

	# Ability bar
	if show_ability_bar and _ability_sys and _ability_sys.get("abilities") != null:
		var lines: PackedStringArray = PackedStringArray()
		var keys := ["Q", "E", "R", "F"]
		var abs = _ability_sys.abilities
		for i in mini(abs.size(), 4):
			var ab = abs[i]
			if ab == null:
				continue
			var cd: float = _ability_sys.get_cooldown_remaining(i)
			var name: String = ab.ability_name
			if cd > 0.05:
				lines.append("%s %s [%.1fs]" % [keys[i], name, cd])
			else:
				lines.append("%s %s  ready" % [keys[i], name])
		_ability_label.text = "  ·  ".join(lines)
	else:
		_ability_label.text = ""

	# Nearest pad ownership + contested banner
	var nearest := ""
	var contested_near := false
	var claim_ratio := 0.0
	var tree := get_tree()
	if tree and _player and _player is Node3D:
		var best_d := 80.0
		var best_txt := ""
		for n in tree.get_nodes_in_group("pad_bases"):
			if n is Node3D and n.has_method("get_faction"):
				var d: float = (_player as Node3D).global_position.distance_to((n as Node3D).global_position)
				if d < best_d:
					best_d = d
					var st := str(n.get("_status")) if "_status" in n else ""
					var cs := 0.0
					if "ownership" in n and n.ownership:
						cs = float(n.ownership.claim_strength)
					claim_ratio = clampf(cs / 2.0, 0.0, 1.0)
					best_txt = "PAD %s  %s  claim %.0f%%  (%.0fm)" % [n.get_faction(), st, claim_ratio * 100.0, d]
					if st == "contested" or str(n.get_faction()) == "Contested":
						contested_near = true
		nearest = best_txt

	# Terrain budget
	var terra := ""
	if _player and _player is Node3D and get_tree():
		for n in get_tree().get_nodes_in_group("terrain_edit"):
			if n.has_method("get_budget_ratio") and n.visible:
				terra = "TERRA %.0f%% used  G/B edit  U undo" % (float(n.get_budget_ratio()) * 100.0)
				break
	if terra != "":
		nearest = (nearest + "\n" + terra) if nearest else terra
	_owner_label.text = nearest

	if _contest_banner:
		_contest_banner.visible = contested_near
		if contested_near:
			var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.01)
			_contest_label.text = "CONTESTED OWNERSHIP  —  press C to contest  ·  claim %d%%" % int(claim_ratio * 100.0)
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

	# Channel bar
	var ch_ratio := 0.0
	var channeling := false
	var ch_name := ""
	if _player:
		var ch = _player.get_node_or_null("ChannelController")
		if ch and ch.has_method("is_channeling") and ch.is_channeling():
			channeling = true
			ch_ratio = float(ch.get_ratio())
			ch_name = str(ch.ability_name)
	if _channel_bar and _channel_label:
		_channel_bar.visible = channeling
		_channel_label.visible = channeling
		if channeling:
			_channel_bar.value = ch_ratio
			_channel_label.text = "CHANNEL %s  %d%%" % [ch_name, int(ch_ratio * 100)]
			_channel_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.6))

	if contested_near:
		_owner_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
	else:
		_owner_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.55))

	# Pad radar
	if _radar and _player and _player is Node3D and get_tree():
		var origin: Vector3 = (_player as Node3D).global_position
		var pads: Array = []
		for n in get_tree().get_nodes_in_group("pad_bases"):
			if n is Node3D:
				pads.append(n)
		for a in range(pads.size()):
			for b in range(a + 1, pads.size()):
				if pads[a].global_position.distance_to(origin) > pads[b].global_position.distance_to(origin):
					var tmp = pads[a]
					pads[a] = pads[b]
					pads[b] = tmp
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
			var flat: Vector3 = off - up * off.dot(up)
			var dist := flat.length()
			if dist > range_m:
				dot.visible = false
				continue
			var nx := flat.x
			var nz := flat.z
			if absf(up.y) <= 0.7:
				nx = flat.dot(Vector3.RIGHT)
				nz = flat.dot(Vector3.FORWARD)
			var sc := 60.0 / range_m
			dot.position = Vector2(65.0 + nx * sc - 2.5, 65.0 + nz * sc - 2.5)
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

func _on_gm_toast(msg: String) -> void:
	push_toast(msg, 3.0)


func _soft_infection_text(stacks: int) -> String:
	# CONCEPT §7.3 Biology mastery — stage labels only
	return _SoftK.infection_label(stacks)
