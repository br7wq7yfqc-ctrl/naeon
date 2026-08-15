extends Node
## Predecessor-lite match presentation for TestArena — soft objectives, no P2W.

signal match_event(msg: String)

var _tick_accum: float = 0.0

var _t: float = 0.0
var _lane_pressure: Array = [0.35, 0.5, 0.4]  # TOP MID BOT 0..1 toward enemy
var _kills: int = 0
var _deaths: int = 0
var _obj_score: float = 0.0
var _banner: String = "CLASH — TOP cyan · MID gold · BOT magenta · occupy beacons"
var _hud: CanvasLayer

func _ready() -> void:
	name = "ClashMatchDirector"
	add_to_group("clash_match")
	_build_hud()
	if SessionObjectives:
		SessionObjectives.on_entered_mode("clash")
	if GameManager:
		GameManager.toast_requested.emit("Aexion Clash — 3 lanes · soft WS · no P2W")
	set_process(true)
	_tick_accum = 0.0

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 25
	add_child(_hud)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(root)
	var top := Label.new()
	top.name = "MatchBanner"
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 52
	top.offset_left = 12
	top.offset_right = -12
	top.offset_bottom = 88
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_theme_font_size_override("font_size", 18)
	top.modulate = Color(0.95, 0.85, 0.45)
	top.text = _banner
	root.add_child(top)
	var lanes := Label.new()
	lanes.name = "LaneBar"
	lanes.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lanes.offset_top = -72
	lanes.offset_bottom = -36
	lanes.offset_left = 16
	lanes.offset_right = -16
	lanes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lanes.add_theme_font_size_override("font_size", 15)
	lanes.modulate = Color(0.7, 0.9, 1.0)
	root.add_child(lanes)
	var score := Label.new()
	score.name = "ScoreLine"
	score.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	score.offset_left = -420
	score.offset_right = -16
	score.offset_top = 102
	score.offset_bottom = 128
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score.add_theme_font_size_override("font_size", 15)
	score.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	score.add_theme_constant_override("outline_size", 4)
	score.modulate = Color(0.85, 0.95, 1.0)
	root.add_child(score)

func register_kill() -> void:
	_kills += 1
	_obj_score += 8.0
	if AudioDirector:
		AudioDirector.play_hit(true)
	if GameManager:
		if GameManager.player_faction == GameManager.Faction.GROT:
			GameManager.add_biomass(3.0)
		else:
			GameManager.add_contribution(3.0)
		GameManager.add_mastery("combat", 1.0)
	if SessionObjectives:
		SessionObjectives.on_moved()
	_flash("KILL + soft Contribution")

func register_death() -> void:
	_deaths += 1
	_flash("DOWN — returning to nexus")

func register_objective() -> void:
	_obj_score += 15.0
	if SessionObjectives:
		SessionObjectives.on_claim_or_obj()
	if AudioDirector:
		AudioDirector.play_claim()
	_flash("OBJECTIVE secured")

func _flash(msg: String) -> void:
	_banner = msg
	match_event.emit(msg)
	if GameManager:
		GameManager.toast_requested.emit(msg)

var _lbl_banner: Label
var _lbl_lanes: Label
var _lbl_score: Label
var _lbl_cache_t: float = 0.0

func _process(delta: float) -> void:
	_tick_accum += delta
	var tick_need := 0.25
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and int(gq.tier) == 0:
		tick_need = 0.4
	if _tick_accum < tick_need:
		return
	_tick_accum = 0.0
	_lbl_cache_t += tick_need
	if _lbl_banner == null or _lbl_cache_t > 2.0:
		_lbl_cache_t = 0.0
		_lbl_banner = _find_label("MatchBanner")
		_lbl_lanes = _find_label("LaneBar")
		_lbl_score = _find_label("ScoreLine")
	_t += tick_need
	_sync_lanes_from_clash()
	var top := _lbl_banner
	var lanes := _lbl_lanes
	var score := _lbl_score
	if top:
		if _t < 4.0:
			top.visible = true
			top.text = "CLASH — TOP cyan · MID gold · BOT magenta · occupy beacons"
		else:
			top.visible = false
	if lanes:
		lanes.visible = false
	if score:
		var eco := 0.0
		if GameManager:
			eco = GameManager.biomass if GameManager.player_faction == GameManager.Faction.GROT else GameManager.contribution
		score.text = "K %d  D %d  ·  OBJ %.0f  ·  ECO %.0f" % [_kills, _deaths, _obj_score, eco]

func _sync_lanes_from_clash() -> void:
	var clash: Node = null
	if get_parent():
		clash = get_parent().get_node_or_null("AexionClash")
	if clash == null and get_tree():
		clash = get_tree().get_first_node_in_group("aexion_clash")
	if clash == null:
		return
	if "kills" in clash:
		_kills = int(clash.kills)
	if "lane_pressure" in clash:
		var lp: Dictionary = clash.lane_pressure
		_lane_pressure[0] = clampf(float(lp.get("TOP", 0.0)) / 100.0, 0.0, 1.0)
		_lane_pressure[1] = clampf(float(lp.get("MID", 0.0)) / 100.0, 0.0, 1.0)
		_lane_pressure[2] = clampf(float(lp.get("BOT", 0.0)) / 100.0, 0.0, 1.0)


func _find_label(n: String) -> Label:
	if _hud == null:
		return null
	var stack: Array = [_hud]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		if c.name == n and c is Label:
			return c as Label
		for ch in c.get_children():
			stack.append(ch)
	return null
