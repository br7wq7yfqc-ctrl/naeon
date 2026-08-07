class_name AbilitySystem
extends Node
const _Kit = preload("res://scripts/abilities/AbilityKitCatalog.gd")

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
		return false  # soft fail
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
	if AudioDirector:
		AudioDirector.play_hit(false)
	if owner_character and is_instance_valid(owner_character) and CombatJuice:
		CombatJuice.hit_feedback(4.0, owner_character.global_position if owner_character is Node3D else Vector3.ZERO)
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
	var kit: Array = _Kit.kit_for_faction(faction)
	for a in kit:
		if a:
			add_ability(a)
	print("[AbilitySystem] kit ", faction, " n=", abilities.size())

