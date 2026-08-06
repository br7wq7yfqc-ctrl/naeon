extends Node
class_name WarScoreTracker
## Aexion Clash soft War Score — temporary world influence only.
## Canon: daily cap 60, never permanent planet flip from Arena alone (skill §4.4).

signal score_changed(daily: float, match_ws: float)
signal influence_emitted(amount: float, target_claim: String)

const DAILY_CAP := 60.0
const MATCH_WIN_WS := 8.0
const KILL_WS := 1.5
const ASSIST_WS := 0.5

var daily_earned: float = 0.0
var match_ws: float = 0.0
var day_key: String = ""

func _ready() -> void:
	_roll_day()
	add_to_group("war_score")

func _roll_day() -> void:
	var d := Time.get_date_dict_from_system()
	day_key = "%04d-%02d-%02d" % [d.year, d.month, d.day]

func _ensure_day() -> void:
	var d := Time.get_date_dict_from_system()
	var k := "%04d-%02d-%02d" % [d.year, d.month, d.day]
	if k != day_key:
		day_key = k
		daily_earned = 0.0
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
	score_changed.emit(daily_earned, match_ws)
	return got

func on_kill() -> float:
	return add_match_points(KILL_WS)

func on_match_win() -> float:
	return add_match_points(MATCH_WIN_WS)

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
	# Soft claim_strength nudge only (never flips faction alone)
	var tree := Engine.get_main_loop()
	if tree and tree is SceneTree:
		for n in (tree as SceneTree).get_nodes_in_group("pad_bases"):
			if claim != "" and str(n.name) != claim and str(n.get("name")) != claim:
				continue
			if "ownership" in n and n.ownership:
				n.ownership.claim_strength = minf(float(n.ownership.claim_strength) + soft * 0.05, 3.0)
				print("[WarScore] soft claim nudge ", n.name, " -> ", n.ownership.claim_strength)
				break
	if GameManager:
		GameManager.add_mastery("combat", 0.3)
	return soft

func hud_line() -> String:
	return "WS match %.1f | daily %.0f/%.0f" % [match_ws, daily_earned, DAILY_CAP]
