class_name AbilitySystem
extends Node

## Manages abilities for a character (TPS / MOBA hero / ship systems).

signal ability_activated(ability: Ability)
signal ability_failed(ability: Ability, reason: String)

@export var abilities: Array[Ability] = []

var current_cooldowns: Dictionary = {}  # Ability -> remaining time
var owner_character: Node = null
var _pending_channel_ability: Ability = null
var _pending_channel_target = null

func _ready() -> void:
	owner_character = get_parent()
	for ability in abilities:
		if ability:
			current_cooldowns[ability] = 0.0

func _process(delta: float) -> void:
	for ability in current_cooldowns.keys():
		if current_cooldowns[ability] > 0.0:
			current_cooldowns[ability] = max(0.0, current_cooldowns[ability] - delta)

func try_activate(index: int, target = null) -> bool:
	if index < 0 or index >= abilities.size():
		return false
	var ability: Ability = abilities[index]
	if ability == null:
		return false
	if current_cooldowns.get(ability, 0.0) > 0.0:
		ability_failed.emit(ability, "On cooldown")
		return false
	if not ability.can_activate(owner_character):
		ability_failed.emit(ability, "Cannot activate")
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
			ability_failed.emit(ability, "Cannot channel")
			return false
		# Short anti-spam lock; full CD applied on complete
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
	abilities.clear()
	current_cooldowns.clear()
	var pulse := Ability.new()
	pulse.ability_name = "Pulse Bolt"
	pulse.description = "Quick energy bolt"
	pulse.cooldown = 0.6
	pulse.energy_cost = 5.0
	pulse.damage = 12.0
	pulse.targeting = Ability.TargetingType.TARGET_DIRECTION
	pulse.effect_color = Color(0.2, 0.9, 1.0)
	add_ability(pulse)

	if faction == "Cybernex":
		var fw := Ability.new()
		fw.ability_name = "Nex-Firewall"
		fw.description = "Nex shield window + cleanse (param sheet rank 1)"
		fw.cooldown = 14.0
		fw.energy_cost = 30.0
		fw.duration = 5.0
		fw.heal = 10.0
		fw.is_firewall = true
		fw.faction_restriction = Ability.FactionRestriction.CYBERNEX_ONLY
		fw.effect_color = Color(0.2, 1.0, 0.65)
		add_ability(fw)

		var hack := Ability.new()
		hack.ability_name = "System Probe"
		hack.description = "Soft recon / structure claim pulse (channeled)"
		hack.cooldown = 10.0
		hack.energy_cost = 25.0
		hack.damage = 6.0
		hack.range = 18.0
		hack.is_hacking = true
		hack.is_channeled = true
		hack.channel_time = 1.5
		hack.effect_color = Color(0.4, 0.8, 1.0)
		add_ability(hack)
	else:
		var infection := Ability.new()
		infection.ability_name = "Hack"
		infection.description = "Channeled claim/hack push (param sheet rank 1)"
		infection.cooldown = 10.0
		infection.energy_cost = 25.0
		infection.biomass_cost = 0.0
		infection.damage = 12.0
		infection.range = 18.0
		infection.is_hacking = true
		infection.is_channeled = true
		infection.channel_time = 1.5
		infection.faction_restriction = Ability.FactionRestriction.GROT_ONLY
		infection.effect_color = Color(1.0, 0.15, 0.45)
		add_ability(infection)

		var surge := Ability.new()
		surge.ability_name = "Rot Surge"
		surge.description = "Close burst"
		surge.cooldown = 4.0
		surge.energy_cost = 10.0
		surge.damage = 18.0
		surge.effect_color = Color(0.85, 0.1, 0.4)
		add_ability(surge)

	var form_swap := Ability.new()
	form_swap.ability_name = "Form Cycle"
	form_swap.description = "Cycle cyber-animal form"
	form_swap.cooldown = 1.5
	form_swap.energy_cost = 0.0
	form_swap.targeting = Ability.TargetingType.SELF
	add_ability(form_swap)
