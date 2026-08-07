extends Node
## Predecessor-lite match presentation for TestArena — soft objectives, no P2W.

signal match_event(msg: String)

var _tick_accum: float = 0.0

var _t: float = 0.0
var _lane_pressure: Array = [0.35, 0.5, 0.4]  # TOP MID BOT 0..1 toward enemy
var _kills: int = 0
var _deaths: int = 0
var _obj_score: float = 0.0
var _banner: String = "CLASH — secure lanes · claim beacons · soft economy only"
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
	score.offset_left = -280
	score.offset_right = -16
	score.offset_top = 56
	score.offset_bottom = 120
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score.add_theme_font_size_override("font_size", 14)
	score.modulate = Color(0.85, 0.95, 1.0)
	root.add_child(score)

func register_kill() -> void:
	_kills += 1
	_obj_score += 8.0
	_nudge_lanes(0.04)
	if AudioDirector:
		AudioDirector.play_hit(true)
	if GameManager:
		GameManager.deposit_economy(3.0)
	if SessionObjectives:
		SessionObjectives.on_landed_or_lane()
	_flash("KILL + soft Contribution")

func register_objective() -> void:
	_obj_score += 15.0
	_nudge_lanes(0.08)
	if SessionObjectives:
		SessionObjectives.on_claim_or_obj()
	if AudioDirector:
		AudioDirector.play_claim()
	_flash("OBJECTIVE secured")

func _nudge_lanes(amt: float) -> void:
	for i in 3:
		_lane_pressure[i] = clampf(float(_lane_pressure[i]) + amt * (0.7 + 0.3 * randf()), 0.05, 0.95)

func _flash(msg: String) -> void:
	_banner = msg
	match_event.emit(msg)
	if GameManager:
		GameManager.toast_requested.emit(msg)

func _process(delta: float) -> void:
	_tick_accum += delta
	if _tick_accum < 0.15:
		return
	_tick_accum = 0.0
	_t += delta
	# Soft passive lane drift (alive match feel)
	if int(_t) % 7 == 0 and fmod(_t, 1.0) < delta:
		for i in 3:
			_lane_pressure[i] = clampf(float(_lane_pressure[i]) + randf_range(-0.02, 0.015), 0.08, 0.92)
	var top := _hud.get_node_or_null("Control/MatchBanner") as Label
	# path may differ — search
	if top == null:
		top = _find_label("MatchBanner")
	var lanes := _find_label("LaneBar")
	var score := _find_label("ScoreLine")
	if top:
		top.text = _banner if _t < 4.0 or int(_t) % 12 < 3 else "AEXION CLASH  ·  TOP / MID / BOT  ·  soft War Score only"
	if lanes:
		lanes.text = "TOP %d%%   ·   MID %d%%   ·   BOT %d%%" % [
			int(float(_lane_pressure[0]) * 100.0),
			int(float(_lane_pressure[1]) * 100.0),
			int(float(_lane_pressure[2]) * 100.0),
		]
	if score:
		var fac := GameManager.get_faction_name() if GameManager else "?"
		var eco := 0.0
		if GameManager:
			eco = GameManager.biomass if GameManager.player_faction == GameManager.Faction.GROT else GameManager.contribution
		score.text = "%s\nK %d  D %d  OBJ %.0f\nECO %.0f (soft)" % [fac, _kills, _deaths, _obj_score, eco]

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
