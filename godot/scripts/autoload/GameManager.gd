extends Node

## Global game manager for NAEON.

enum Faction { CYBERNEX, GROT, NEUTRAL }

signal contribution_changed(value: float)
signal knowledge_changed(rank: int)
signal faction_changed(faction: Faction)
signal mastery_gained(subject: String, value: float)
signal toast_requested(msg: String)

var player_faction: Faction = Faction.CYBERNEX
var contribution: float = 0.0
var knowledge_rank: int = 0
var subject_mastery: Dictionary = {}
var session_started_at: int = 0

func _ready() -> void:
	ensure_default_input()
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
	var nxt: float = clampf(cur + amount, 0.0, 100.0)
	subject_mastery[subject] = nxt
	_recalc_knowledge()
	mastery_gained.emit(subject, nxt)
	# Soft-only: every integer threshold fires info toast (no combat)
	if int(nxt) > int(cur) and int(nxt) % 5 == 0:
		toast_requested.emit("Knowledge: %s reached %.0f (soft insight only)" % [subject, nxt])

func _recalc_knowledge() -> void:
	if subject_mastery.is_empty():
		knowledge_rank = 0
	else:
		var total: float = 0.0
		for k in subject_mastery.keys():
			total += subject_mastery[k]
		knowledge_rank = int(total / subject_mastery.size())
	knowledge_changed.emit(knowledge_rank)

func knowledge_insight_bonus() -> float:
	return clampf(float(knowledge_rank) * 0.002, 0.0, 0.15)

func ensure_default_input() -> void:
	var binds := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"sprint": [KEY_SHIFT],
		"ability_1": [KEY_Q],
		"ability_2": [KEY_E],
		"ability_3": [KEY_R],
		"ability_4": [KEY_F],
	}
	for action in binds.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in binds[action]:
			var has_k := false
			for existing in InputMap.action_get_events(action):
				if existing is InputEventKey and (existing.physical_keycode == k or existing.keycode == k):
					has_k = true
					break
			if not has_k:
				var ev := InputEventKey.new()
				ev.physical_keycode = k
				ev.keycode = k
				InputMap.action_add_event(action, ev)
	print("[GameManager] Input ready; move_forward events=", InputMap.action_get_events("move_forward").size())
