extends Node

## Global game manager for NAEON.

enum Faction { CYBERNEX, GROT, NEUTRAL }

signal contribution_changed(value: float)
signal knowledge_changed(rank: int)
signal faction_changed(faction: Faction)

var player_faction: Faction = Faction.CYBERNEX
var contribution: float = 0.0
var knowledge_rank: int = 0
var subject_mastery: Dictionary = {}
var session_started_at: int = 0

func _ready() -> void:
	session_started_at = int(Time.get_unix_time_from_system())
	print("[GameManager] NAEON initialized")

func get_faction_name() -> String:
	match player_faction:
		Faction.CYBERNEX:
			return "Cybernex"
		Faction.GROT:
			return "gROT"
		_:
			return "Neutral"

func set_faction(f: Faction) -> void:
	player_faction = f
	faction_changed.emit(f)

func add_contribution(amount: float) -> void:
	contribution += amount
	contribution_changed.emit(contribution)

func add_mastery(subject: String, amount: float) -> void:
	var cur: float = subject_mastery.get(subject, 0.0)
	subject_mastery[subject] = clampf(cur + amount, 0.0, 100.0)
	_recalc_knowledge()

func _recalc_knowledge() -> void:
	if subject_mastery.is_empty():
		knowledge_rank = 0
	else:
		var total := 0.0
		for k in subject_mastery.keys():
			total += subject_mastery[k]
		knowledge_rank = int(total / subject_mastery.size())
	knowledge_changed.emit(knowledge_rank)

## Soft combat insight from knowledge (QoL only, no P2W).
func knowledge_insight_bonus() -> float:
	return clampf(float(knowledge_rank) * 0.002, 0.0, 0.15)
