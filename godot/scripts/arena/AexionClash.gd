extends Node
class_name AexionClash

const _WarScore = preload("res://scripts/systems/WarScore.gd")
## Aexion Clash vertical slice on TestArena.
## Predecessor/Paragon bar: readable TPS MOBA kits; soft world influence only.

signal match_ended(winner: String)

var war: Node
var kills: int = 0
var target_kills: int = 5
var active: bool = true
var _ended: bool = false

func _ready() -> void:
	war = _WarScore.new()
	war.name = "WarScore"
	add_child(war)
	if LayerContext:
		LayerContext.set_layer("Arena")
		LayerContext.seamless_stage = "S1"
		if LayerContext.active_quest_id == "":
			LayerContext.set_quest("clash_slice_v0")
	if GameManager:
		GameManager.toast_requested.emit("Aexion Clash — first to %d · soft WS only (cap 60/day)" % target_kills)
	print("[AexionClash] arena layer S1")

func register_kill() -> void:
	if _ended or not active:
		return
	kills += 1
	if war:
		war.on_kill()
	if GameManager:
		GameManager.add_mastery("combat", 0.8)
	if kills >= target_kills:
		_end_match("player")

func _end_match(winner: String) -> void:
	if _ended:
		return
	_ended = true
	active = false
	if war:
		war.on_match_win()
		war.emit_soft_influence()
	match_ended.emit(winner)
	if GameManager:
		GameManager.toast_requested.emit(
			"Clash complete (%s) — soft influence only, no permanent flip" % winner
		)
	print("[AexionClash] match end → ", winner)

func status_line() -> String:
	var ws: String = war.hud_line() if war else "WS —"
	return "CLASH %d/%d  |  %s" % [kills, target_kills, ws]
