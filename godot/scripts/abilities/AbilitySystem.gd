class_name AbilitySystem
extends Node
const _Kit = preload("res://scripts/abilities/AbilityKitCatalog.gd")

## Manages abilities for a character (TPS / MOBA hero / ship systems).

signal ability_activated(ability: Ability)
signal ability_failed(ability: Ability, reason: String)

@export var abilities: Array[Ability] = []

var current_cooldowns: Dictionary = {}  # Ability -> remaining time
var owner_character: Node = null
var current_kit_id: String = ""
var _pending_channel_ability: Ability = null
var _pending_channel_target = null

func _ready() -> void:
	owner_character = get_parent()
	for ability in abilities:
		if ability:
			current_cooldowns[ability] = 0.0
	if not ability_failed.is_connected(_on_ability_failed):
		ability_failed.connect(_on_ability_failed)
	if not ability_activated.is_connected(_on_ability_activated):
		ability_activated.connect(_on_ability_activated)

func _process(delta: float) -> void:
	for ability in current_cooldowns.keys():
		if current_cooldowns[ability] > 0.0:
			current_cooldowns[ability] = max(0.0, current_cooldowns[ability] - delta)

func try_activate(index: int, target = null) -> bool:
	if index < 0 or index >= abilities.size():
		return false  # soft fail
	var ability: Ability = abilities[index]
	if ability == null:
		return false
	var cd_left: float = float(current_cooldowns.get(ability, 0.0))
	if cd_left > 0.0:
		ability_failed.emit(ability, "Cooldown %.1fs" % cd_left)
		return false
	var why := _cannot_reason(ability)
	if why != "":
		ability_failed.emit(ability, why)
		return false
	var ch := _ensure_channel()
	if ch and ch.has_method("is_channeling") and ch.is_channeling():
		ability_failed.emit(ability, "Channeling")
		return false
	if ability.is_channeled and ability.channel_time > 0.0 and ch:
		ability.activate(owner_character, target)
		_pending_channel_ability = ability
		_pending_channel_target = target
		var ok: bool = ch.start_channel(
			ability.ability_name,
			ability.channel_time,
			Callable(self, "_on_channel_done"),
			owner_character
		)
		if not ok:
			if owner_character and ability.energy_cost > 0.0:
				var EE = load("res://scripts/systems/EnergyEconomy.gd")
				if EE:
					EE.refund(owner_character, ability.energy_cost)
			_pending_channel_ability = null
			_pending_channel_target = null
			ability_failed.emit(ability, "Cannot channel")
			return false
		current_cooldowns[ability] = minf(ability.cooldown * 0.25, 2.0)
		ability_activated.emit(ability)
		return true
	ability.activate(owner_character, target)
	current_cooldowns[ability] = ability.cooldown
	ability_activated.emit(ability)
	return true

func _ensure_channel() -> Node:
	if owner_character == null:
		return null
	var ch = owner_character.get_node_or_null("ChannelController")
	if ch == null:
		ch = Node.new()
		ch.set_script(preload("res://scripts/abilities/ChannelController.gd"))
		ch.name = "ChannelController"
		owner_character.add_child(ch)
	return ch

func _on_channel_done() -> void:
	_complete_channel(_pending_channel_ability, _pending_channel_target)
	_pending_channel_ability = null
	_pending_channel_target = null

func _complete_channel(ability: Ability, target) -> void:
	if ability == null:
		return
	if ability.has_method("finish_channel"):
		ability.finish_channel(owner_character, target)
	else:
		ability._apply_effect(owner_character, target)
	current_cooldowns[ability] = ability.cooldown
	print("[AbilitySystem] channel finished ", ability.ability_name)

func get_channel_ratio() -> float:
	var ch := _ensure_channel()
	if ch and ch.has_method("get_ratio") and ch.is_channeling():
		return float(ch.get_ratio())
	return 0.0

func is_channeling() -> bool:
	if owner_character == null:
		return false
	var ch = owner_character.get_node_or_null("ChannelController")
	return ch != null and ch.has_method("is_channeling") and ch.is_channeling()

func get_cooldown_remaining(index: int) -> float:
	if index < 0 or index >= abilities.size():
		return 0.0
	var ability: Ability = abilities[index]
	return current_cooldowns.get(ability, 0.0)


func restock_cooldowns(amount: float) -> bool:
	## Occupy locker: shave Pulse / kit CDs. Knowledge never changes this rate.
	if amount <= 0.0:
		return false
	var any := false
	for ability in current_cooldowns.keys():
		var left: float = float(current_cooldowns[ability])
		if left <= 0.01:
			continue
		current_cooldowns[ability] = maxf(0.0, left - amount)
		any = true
	return any

func get_cooldown_ratio(index: int) -> float:
	if index < 0 or index >= abilities.size() or abilities[index] == null:
		return 0.0
	var cd = abilities[index].cooldown
	if cd <= 0.0:
		return 0.0
	return get_cooldown_remaining(index) / cd

func add_ability(ability: Ability) -> void:
	if ability and ability not in abilities:
		abilities.append(ability)
		current_cooldowns[ability] = 0.0

func setup_default_loadout(faction: String = "Cybernex") -> void:
	setup_kit(_Kit.default_kit_id(faction), faction)


func setup_kit(kit_id: String, faction: String = "") -> void:
	abilities.clear()
	current_cooldowns.clear()
	current_kit_id = kit_id
	var kit: Array = _Kit.kit_by_id(kit_id)
	for a in kit:
		if a:
			add_ability(a)
	var tag := faction if faction != "" else kit_id
	print("[AbilitySystem] kit ", tag, " id=", current_kit_id, " n=", abilities.size())
	if not ability_failed.is_connected(_on_ability_failed):
		ability_failed.connect(_on_ability_failed)
	if not ability_activated.is_connected(_on_ability_activated):
		ability_activated.connect(_on_ability_activated)


func kit_label() -> String:
	var meta: Dictionary = _Kit.kit_meta(current_kit_id)
	if meta.is_empty():
		return current_kit_id if current_kit_id != "" else "—"
	return str(meta.get("label", current_kit_id))




func _cannot_reason(ability: Ability) -> String:
	if ability == null or owner_character == null:
		return "No caster"
	if owner_character.has_method("get_energy") and ability.energy_cost > 0.0:
		if float(owner_character.get_energy()) < ability.energy_cost:
			return "Need %.0f energy" % ability.energy_cost
	if ability.biomass_cost > 0.0 and owner_character.has_method("get_biomass"):
		if float(owner_character.get_biomass()) < ability.biomass_cost:
			return "Need biomass"
	if ability.faction_restriction != Ability.FactionRestriction.ANY and owner_character.has_method("get_faction"):
		var f := str(owner_character.get_faction())
		if ability.faction_restriction == Ability.FactionRestriction.CYBERNEX_ONLY and f != "Cybernex":
			return "Cybernex only"
		if ability.faction_restriction == Ability.FactionRestriction.GROT_ONLY and f != "gROT":
			return "gROT only"
	if not ability.can_activate(owner_character):
		return "Cannot activate"
	return ""


func _on_ability_failed(ability: Ability, reason: String) -> void:
	var name := ability.ability_name if ability else "Ability"
	_toast("%s — %s" % [name, reason], 2.0)
	if AudioDirector and AudioDirector.has_method("play_ui_deny"):
		AudioDirector.play_ui_deny()
	elif AudioDirector:
		AudioDirector.play_hit(false)


func _on_ability_activated(ability: Ability) -> void:
	if ability == null:
		return
	var tag := "CHANNEL" if ability.is_channeled else "CAST"
	_toast("%s  %s" % [tag, ability.ability_name], 1.4)


func _toast(msg: String, ttl: float = 2.5) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("game_hud"):
		if n.has_method("push_toast"):
			n.push_toast(msg, ttl)
			return
	# fallback print
	print("[Ability] ", msg)


func get_slot_label(index: int) -> String:
	if index < 0 or index >= abilities.size() or abilities[index] == null:
		return "—"
	var a: Ability = abilities[index]
	var cd := float(current_cooldowns.get(a, 0.0))
	if cd > 0.05:
		return "%s %.0f" % [a.ability_name.substr(0, 8), cd]
	return a.ability_name.substr(0, 10)
