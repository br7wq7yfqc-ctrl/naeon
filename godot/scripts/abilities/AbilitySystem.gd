class_name AbilitySystem
extends Node

## Manages abilities for a character (TPS / MOBA hero / ship systems).

signal ability_activated(ability: Ability)
signal ability_failed(ability: Ability, reason: String)

@export var abilities: Array[Ability] = []

var current_cooldowns: Dictionary = {}  # Ability -> remaining time
var owner_character: Node = null

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
	ability.activate(owner_character, target)
	current_cooldowns[ability] = ability.cooldown
	ability_activated.emit(ability)
	return true

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
		fw.description = "Raise short Nex shield + minor heal"
		fw.cooldown = 8.0
		fw.energy_cost = 20.0
		fw.duration = 3.0
		fw.heal = 15.0
		fw.is_firewall = true
		fw.faction_restriction = Ability.FactionRestriction.CYBERNEX_ONLY
		fw.effect_color = Color(0.2, 1.0, 0.65)
		add_ability(fw)

		var hack := Ability.new()
		hack.ability_name = "System Probe"
		hack.description = "Soft recon probe (training)"
		hack.cooldown = 5.0
		hack.energy_cost = 12.0
		hack.damage = 8.0
		hack.range = 14.0
		hack.is_hacking = true
		hack.effect_color = Color(0.4, 0.8, 1.0)
		add_ability(hack)
	else:
		var infection := Ability.new()
		infection.ability_name = "Biomass Infection"
		infection.description = "gROT hack / claim push"
		infection.cooldown = 6.0
		infection.energy_cost = 8.0
		infection.biomass_cost = 5.0
		infection.damage = 10.0
		infection.range = 12.0
		infection.is_hacking = true
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
	# Handled specially in player — still occupies slot 3
	add_ability(form_swap)
