extends Node
## Predecessor-lite match presentation for TestArena — soft objectives, no P2W.

signal match_event(msg: String)

var _tick_accum: float = 0.0

var _t: float = 0.0
var _lane_pressure: Array = [0.35, 0.5, 0.4]  # TOP MID BOT 0..1 toward enemy
var _kills: int = 0
var _deaths: int = 0
var _obj_score: float = 0.0
var _match_xp: float = 0.0
var _match_level: int = 1
var _banner: String = "CLASH — TOP cyan · MID gold · BOT magenta · occupy beacons"
var _hud: CanvasLayer
var _result_locked: bool = false

func _ready() -> void:
	name = "ClashMatchDirector"
	add_to_group("clash_match")
	_build_hud()
	_ensure_clash_softnet()
	if SessionObjectives:
		SessionObjectives.on_entered_mode("clash")
	if GameManager:
		GameManager.toast_requested.emit("Aexion Clash — 3 lanes · soft WS · no P2W")
	set_process(true)
	_tick_accum = 0.0


func _ensure_clash_softnet() -> void:
	## SN-D: visual Clash viewer/puppet lives on the arena root, not this HUD node.
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.SN_D_CLASH):
		return
	var host: Node = get_parent()
	if host == null:
		host = self
	var existing: Node = host.get_node_or_null("ClashSoftNet")
	if existing != null:
		if existing.has_method("bind"):
			existing.bind(self)
		if existing.has_method("sync_from_host"):
			existing.sync_from_host()
		return
	var n: Node3D = Node3D.new()
	n.set_script(load("res://scripts/world/ClashSoftNet.gd"))
	n.name = "ClashSoftNet"
	host.add_child(n)
	if n.has_method("bind"):
		n.bind(self)


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
	_lbl_banner = top
	_lbl_lanes = lanes
	_lbl_score = score

func register_kill() -> void:
	_kills += 1
	_obj_score += 8.0
	_grant_kill_xp()
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


## AR-U: minion last-hit XP is a label only. Never Pulse / kit unlock.
func register_minion_xp() -> float:
	var local := _local_match()
	if local != null and local.has_method("register_minion_xp"):
		var got := float(local.register_minion_xp())
		_sync_xp_from_local(local)
		return got
	return _grant_own_xp(25.0)


func match_xp() -> float:
	var local := _local_match()
	if local != null and "match_xp" in local:
		return float(local.match_xp)
	return _match_xp


func match_level() -> int:
	var local := _local_match()
	if local != null and "match_level" in local:
		return int(local.match_level)
	return _match_level


func xp_soft_label() -> String:
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if SoftK and SoftK.has_method("xp_label"):
		return str(SoftK.xp_label())
	return "XP"


func level_soft_label() -> String:
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if SoftK and SoftK.has_method("level_label"):
		return str(SoftK.level_label(match_level()))
	return "LEVEL"


func xp_hud_line() -> String:
	return "%s %.0f  ·  %s %d" % [xp_soft_label(), match_xp(), level_soft_label(), match_level()]


func score_hud_line() -> String:
	var eco := 0.0
	if GameManager:
		eco = GameManager.biomass if GameManager.player_faction == GameManager.Faction.GROT else GameManager.contribution
	return "K %d  D %d  ·  OBJ %.0f  ·  ECO %.0f  ·  %s" % [_kills, _deaths, _obj_score, eco, xp_hud_line()]

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


func register_camp_contest(role: String = "") -> void:
	# Soft announce only — Knowledge may label the pit, never unique DPS.
	if str(role) == "prime":
		_flash("PRIME CONTESTED — soft · no unique weapon")
	elif str(role) == "small" or str(role) == "jungle":
		_flash("CAMP CONTESTED — soft · no unique weapon")
	else:
		_flash("CAMP CONTESTED — soft · no unique weapon")


func camp_soft_label() -> String:
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if SoftK and SoftK.has_method("camp_label"):
		return str(SoftK.camp_label("small"))
	return "CAMP"


func jungle_soft_label() -> String:
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if SoftK and SoftK.has_method("jungle_label"):
		return str(SoftK.jungle_label())
	return "JUNGLE"

func show_soft_result(result_label: String, cosmetic_label: String = "") -> void:
	## AR-I: SoftKnowledge WIN / LOSS (title if daily WS cap). Never DPS.
	var line := str(result_label)
	if cosmetic_label != "":
		line = "%s · %s" % [result_label, cosmetic_label]
	_banner = line
	_result_locked = true
	if _lbl_banner:
		_lbl_banner.visible = true
		_lbl_banner.text = line
	if _lbl_score:
		_lbl_score.text = line
	match_event.emit(line)


func _flash(msg: String) -> void:
	_banner = msg
	match_event.emit(msg)
	if GameManager:
		GameManager.toast_requested.emit(msg)

var _lbl_banner: Label
var _lbl_lanes: Label
var _lbl_score: Label

func _process(delta: float) -> void:
	_tick_accum += delta
	var tick_need := 0.25
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and int(gq.tier) == 0:
		tick_need = 0.4
	if _tick_accum < tick_need:
		return
	_tick_accum = 0.0
	_t += tick_need
	_sync_lanes_from_clash()
	var top := _lbl_banner
	var lanes := _lbl_lanes
	var score := _lbl_score
	if top:
		if _result_locked:
			top.visible = true
			top.text = _banner
		elif _t < 4.0:
			top.visible = true
			top.text = "CLASH — TOP cyan · MID gold · BOT magenta · occupy beacons"
		else:
			top.visible = false
	if lanes:
		# Bottom lane-pressure bar: the array was computed and thrown away.
		lanes.visible = true
		lanes.text = _lane_bar_line()
	if score and not _result_locked:
		score.text = score_hud_line()

func _sync_lanes_from_clash() -> void:
	var clash: Node = null
	if get_parent():
		clash = get_parent().get_node_or_null("AexionClash")
	if clash == null and get_tree():
		clash = get_tree().get_first_node_in_group("aexion_clash")
	if clash == null:
		return
	# _kills is owned by register_kill — overwriting it here discarded the
	# director's own reward path.
	if "lane_pressure" in clash:
		var lp: Dictionary = clash.lane_pressure
		_lane_pressure[0] = clampf(float(lp.get("TOP", 0.0)) / 100.0, 0.0, 1.0)
		_lane_pressure[1] = clampf(float(lp.get("MID", 0.0)) / 100.0, 0.0, 1.0)
		_lane_pressure[2] = clampf(float(lp.get("BOT", 0.0)) / 100.0, 0.0, 1.0)


func _lane_bar_line() -> String:
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	var wave := "WAVE"
	var minion := "MINION"
	if SoftK:
		if SoftK.has_method("wave_label"):
			wave = str(SoftK.wave_label())
		if SoftK.has_method("minion_label"):
			minion = str(SoftK.minion_label())
	var camp := "CAMP"
	var jungle := "JUNGLE"
	if SoftK:
		if SoftK.has_method("camp_label"):
			camp = str(SoftK.camp_label("small"))
		if SoftK.has_method("jungle_label"):
			jungle = str(SoftK.jungle_label())
	if camp == jungle:
		if camp == "JUNGLE":
			camp = "CAMP"
		else:
			jungle = "JUNGLE"
	return "TOP %.0f   MID %.0f   BOT %.0f   /100  (soft)  ·  %s  ·  %s  ·  %s  ·  %s" % [
		_lane_pressure[0] * 100.0, _lane_pressure[1] * 100.0, _lane_pressure[2] * 100.0,
		wave, minion, camp, jungle,
	]


func _local_match() -> Node:
	var host: Node = get_parent()
	if host:
		var n: Node = host.get_node_or_null("ClashLocalMatch")
		if n != null:
			return n
	var tree := get_tree()
	if tree:
		return tree.get_first_node_in_group("clash_local_match")
	return null


func _grant_kill_xp() -> void:
	var local := _local_match()
	if local != null and local.has_method("register_kill_xp"):
		local.register_kill_xp()
		_sync_xp_from_local(local)
		return
	_grant_own_xp(50.0)


func _sync_xp_from_local(local: Node) -> void:
	if local == null:
		return
	if "match_xp" in local:
		_match_xp = float(local.match_xp)
	if "match_level" in local:
		_match_level = int(local.match_level)


func _grant_own_xp(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	_match_xp += amount
	_match_level = clampi(1 + int(floor(_match_xp / 100.0)), 1, 18)
	return amount
