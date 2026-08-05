class_name AbilitySystem
extends Node

## Manages abilities for a character (TPS / MOBA hero / etc.)
## Supports cooldowns, costs, and asymmetric faction abilities

signal ability_activated(ability: Ability)
signal ability_failed(ability: Ability, reason: String)

@export var abilities: Array[Ability] = []

var current_cooldowns: Dictionary = {}  # Ability -> remaining time
var owner_character: Node = null

func _ready() -> void:
	owner_character = get_parent()
	for ability in abilities:
		current_cooldowns[ability] = 0.0

func _process(delta: float) -> void:
	for ability in current_cooldowns.keys():
		if current_cooldowns[ability] > 0.0:
			current_cooldowns[ability] = max(0.0, current_cooldowns[ability] - delta)

func try_activate(index: int, target = null) -> bool:
	if index < 0 or index >= abilities.size():
		return false
	
	var ability: Ability = abilities[index]
	
	if current_cooldowns.get(ability, 0.0) > 0.0:
		ability_failed.emit(ability, "On cooldown")
		return false
	
	if not ability.can_activate(owner_character):
		ability_failed.emit(ability, "Cannot activate")
		return false
	
	# TODO: Check energy / biomass cost against character stats
	
	ability.activate(owner_character, target)
	current_cooldowns[ability] = ability.cooldown
	ability_activated.emit(ability)
	return true

func get_cooldown_remaining(index: int) -> float:
	if index < 0 or index >= abilities.size():
		return 0.0
	return current_cooldowns.get(abilities[index], 0.0)

func add_ability(ability: Ability) -> void:
	if ability not in abilities:
		abilities.append(ability)
		current_cooldowns[ability] = 0.0
