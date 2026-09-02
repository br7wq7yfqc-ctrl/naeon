extends Node
const _AllianceRanks = preload("res://scripts/systems/AllianceRanks.gd")

## Global game manager for NAEON.
## Concept: asymmetric Cybernex Contribution (RBE) vs gROT Biomass; Soft Knowledge only.

enum Faction { CYBERNEX, GROT, NEUTRAL }

signal contribution_changed(value: float)
signal biomass_changed(value: float)
signal knowledge_changed(rank: int)
signal faction_changed(faction: Faction)
signal mastery_gained(subject: String, value: float)
signal toast_requested(msg: String)

var player_faction: Faction = Faction.CYBERNEX
var contribution: float = 0.0  ## Cybernex RBE score
var lifetime_contribution: float = 0.0  ## earned Contribution; spend does not reduce (CR-A rank)
var biomass: float = 0.0       ## gROT Biomass score
var lifetime_biomass: float = 0.0  ## earned Biomass; spend does not reduce (BR-A rank)
var knowledge_rank: int = 0
var lifetime_knowledge: float = 0.0  ## earned mastery; never reduced (KR-A rank)
var subject_mastery: Dictionary = {}
var session_started_at: int = 0
var alliance_rank: int = 0  ## 0–4 soft social only (AllianceRanks)

func _ready() -> void:
	ensure_default_input()
	session_started_at = int(Time.get_unix_time_from_system())
	print("[GameManager] NAEON initialized")
	if not toast_requested.is_connected(_on_toast_audio):
		toast_requested.connect(_on_toast_audio)
	call_deferred("_bind_play_window")


func _bind_play_window() -> void:
	## F5 "NAEON DEBUG" must stay a normal window: editor/debugger reachable,
	## title-bar close quits, no always-on-top, no exclusive grab.
	var w := get_window()
	if w == null:
		return
	w.always_on_top = false
	w.borderless = false
	w.unresizable = false
	if w.mode == Window.MODE_EXCLUSIVE_FULLSCREEN or w.mode == Window.MODE_FULLSCREEN \
			or w.mode == Window.MODE_MAXIMIZED:
		w.mode = Window.MODE_WINDOWED
	if not w.close_requested.is_connected(_on_window_close):
		w.close_requested.connect(_on_window_close)


func _on_window_close() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_window_close()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if SoftSession and SoftSession.has_method("begin_offline"):
			SoftSession.begin_offline()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if SoftSession and SoftSession.has_method("end_offline"):
			SoftSession.end_offline()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		if SoftSession and SoftSession.has_method("begin_offline"):
			SoftSession.begin_offline()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		if SoftSession and SoftSession.has_method("end_offline"):
			SoftSession.end_offline()

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
	toast_requested.emit("Faction → %s (asymmetric economy + ability kits)" % get_faction_name())

func cycle_faction() -> void:
	if player_faction == Faction.CYBERNEX:
		set_faction(Faction.GROT)
	else:
		set_faction(Faction.CYBERNEX)

func add_contribution(amount: float) -> void:
	contribution += amount
	if amount > 0.0:
		lifetime_contribution += amount
	contribution_changed.emit(contribution)


func try_spend_contribution(amount: float) -> bool:
	## Soft economy spend — never cash, never combat unlock.
	if amount <= 0.0:
		return true
	if contribution < amount:
		return false
	contribution -= amount
	contribution_changed.emit(contribution)
	return true


func try_spend_biomass(amount: float) -> bool:
	## Soft economy spend — never cash, never combat unlock.
	if amount <= 0.0:
		return true
	if biomass < amount:
		return false
	biomass -= amount
	biomass_changed.emit(biomass)
	return true


func try_spend_economy(amount: float) -> bool:
	## Faction wallet: Contribution (CX) or Biomass (GR). Never cash.
	if player_faction == Faction.GROT:
		return try_spend_biomass(amount)
	return try_spend_contribution(amount)

func add_biomass(amount: float) -> void:
	biomass += amount
	if amount > 0.0:
		lifetime_biomass += amount
	biomass_changed.emit(biomass)


func biomass_rank() -> int:
	## BR-A: 0–4 from lifetime Biomass wallet. Label only — never combat / yield.
	return _AllianceRanks.rank_from_lifetime(lifetime_biomass)


func contribution_rank() -> int:
	## CR-A: 0–4 from lifetime Contribution wallet. Label only — never combat / yield.
	return _AllianceRanks.rank_from_lifetime(lifetime_contribution)


func knowledge_ladder() -> int:
	## KR-A: 0–4 from lifetime mastery. HUD label only — never yield / DPS / Pulse.
	return _AllianceRanks.rank_from_lifetime(lifetime_knowledge)

## Faction-aware soft economy deposit from harvest/work.
## `owner_faction` names the side that earned it; empty means the local player.
func deposit_economy(amount: float, from_harvest: bool = false, owner_faction: String = "") -> void:
	if amount <= 0.0:
		return
	var grot := player_faction == Faction.GROT
	if owner_faction != "":
		if owner_faction == "Cybernex":
			grot = false
		elif owner_faction == "gROT":
			grot = true
		else:
			return  # Neutral / Contested pays nobody
	if grot:
		add_biomass(amount)
		add_mastery("biomass_ops", amount * 0.02)
	else:
		add_contribution(amount)
		add_mastery("colony_ops", amount * 0.02)
	if from_harvest and SessionObjectives:
		SessionObjectives.on_economy()

func get_alliance_rank_name() -> String:
	return _AllianceRanks.rank_name(alliance_rank)

func try_promote_alliance() -> bool:
	## Spend soft economy only — no combat unlock
	var cost: float = _AllianceRanks.next_rank_cost_contribution(alliance_rank)
	if cost <= 0.0 or alliance_rank >= 4:
		return false
	if player_faction == Faction.GROT:
		if biomass < cost:
			toast_requested.emit("Need %.0f Biomass for rank (social only)" % cost)
			return false
		biomass -= cost
		biomass_changed.emit(biomass)
	else:
		if contribution < cost:
			toast_requested.emit("Need %.0f Contribution for rank (social only)" % cost)
			return false
		contribution -= cost
		contribution_changed.emit(contribution)
	alliance_rank = mini(4, alliance_rank + 1)
	toast_requested.emit("Alliance rank → %s (permissions only, no combat power)" % get_alliance_rank_name())
	return true

func next_alliance_cost() -> float:
	return _AllianceRanks.next_rank_cost_contribution(alliance_rank)


func economy_label() -> String:
	if player_faction == Faction.GROT:
		return "BIOMASS %.1f" % biomass
	return "CONTRIB %.1f" % contribution

func add_mastery(subject: String, amount: float) -> void:
	if amount > 0.0:
		lifetime_knowledge += amount
	var cur: float = subject_mastery.get(subject, 0.0)
	var nxt: float = clampf(cur + amount, 0.0, 100.0)
	subject_mastery[subject] = nxt
	_recalc_knowledge()
	mastery_gained.emit(subject, nxt)
	# Soft-only: every 5 pts fires info toast (no combat)
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
	# Soft display/QoL insight — CAP 15%. Never raw combat.
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

func _on_toast_audio(_msg: String) -> void:
	if AudioDirector:
		AudioDirector.play_toast()
