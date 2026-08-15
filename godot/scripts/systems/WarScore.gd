extends Node
class_name WarScoreTracker
## Aexion Clash soft War Score — temporary world influence only.
## Canon: daily cap 60, never permanent planet flip from Arena alone (skill §4.4).

signal score_changed(daily: float, match_ws: float)
signal influence_emitted(amount: float, target_claim: String)

const DAILY_CAP := 60.0
const MATCH_WIN_WS := 15.0  # rules/13
const LOSS_WS := 3.0        # rules/13 participation
const KILL_WS := 1.5
const ASSIST_WS := 0.5
const SAVE_PATH := "user://war_score.cfg"

var daily_earned: float = 0.0
var match_ws: float = 0.0
var day_key: String = ""

func _ready() -> void:
	_roll_day()
	_load_daily()
	add_to_group("war_score")

func _roll_day() -> void:
	var d := Time.get_date_dict_from_system()
	day_key = "%04d-%02d-%02d" % [d.year, d.month, d.day]

func _load_daily() -> void:
	## The tracker is rebuilt on every arena load, so the cap has to live on
	## disk or re-entering the scene would hand out unlimited War Score.
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var saved_day := str(cfg.get_value("ws", "day", ""))
	if saved_day == day_key:
		daily_earned = clampf(float(cfg.get_value("ws", "daily", 0.0)), 0.0, DAILY_CAP)
		print("[WarScore] restored daily ", daily_earned, "/", DAILY_CAP)

func _save_daily() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ws", "day", day_key)
	cfg.set_value("ws", "daily", daily_earned)
	cfg.save(SAVE_PATH)

func _ensure_day() -> void:
	var d := Time.get_date_dict_from_system()
	var k := "%04d-%02d-%02d" % [d.year, d.month, d.day]
	if k != day_key:
		day_key = k
		daily_earned = 0.0
		_save_daily()
		print("[WarScore] new day reset")

func remaining_daily() -> float:
	_ensure_day()
	return maxf(0.0, DAILY_CAP - daily_earned)

func add_match_points(amount: float) -> float:
	_ensure_day()
	if amount <= 0.0:
		return 0.0
	var room := remaining_daily()
	var got := minf(amount, room)
	if got <= 0.0:
		if GameManager:
			GameManager.toast_requested.emit("War Score daily cap (%.0f) reached — soft only" % DAILY_CAP)
		return 0.0
	daily_earned += got
	match_ws += got
	_save_daily()
	score_changed.emit(daily_earned, match_ws)
	return got

func on_kill() -> float:
	return add_match_points(KILL_WS)

func on_match_win() -> float:
	return add_match_points(MATCH_WIN_WS)

func on_match_loss() -> float:
	return add_match_points(LOSS_WS)

## Soft claim pressure only — capped, temporary, never permanent flip alone
func emit_soft_influence(target_claim: String = "") -> float:
	_ensure_day()
	# At most 20% of match WS can soft-touch claim_strength elsewhere
	var soft := clampf(match_ws * 0.2, 0.0, 4.0)
	if soft <= 0.0:
		return 0.0
	var claim := target_claim
	if claim == "" and LayerContext:
		claim = LayerContext.active_claim_id
	influence_emitted.emit(soft, claim)
	if GameManager:
		GameManager.toast_requested.emit(
			"Soft Arena influence +%.1f on claim (temp, capped) — not planet flip" % soft
		)
	# Temporary, decaying nudge (rules/13) — writing claim_strength directly was
	# permanent and bypassed the contest state machine.
	var tree := Engine.get_main_loop()
	if tree and tree is SceneTree:
		for n in (tree as SceneTree).get_nodes_in_group("pad_bases"):
			if claim != "" and str(n.name) != claim:
				continue
			if n.has_method("apply_arena_influence"):
				n.apply_arena_influence(soft * 0.05)
				print("[WarScore] soft arena influence ", n.name, " +", soft * 0.05)
			break
	if GameManager:
		GameManager.add_mastery("combat", 0.3)
	return soft

func hud_line() -> String:
	return "WS match %.1f | daily %.0f/%.0f" % [match_ws, daily_earned, DAILY_CAP]
