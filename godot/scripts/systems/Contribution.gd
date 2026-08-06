class_name Contribution
extends Resource

## Cybernex RBE Contribution Score

@export var player_id: String = ""
@export var value: float = 0.0
@export var lifetime_value: float = 0.0
@export var last_updated: int = 0

func add(amount: float) -> void:
	value += amount
	lifetime_value += amount
	last_updated = int(Time.get_unix_time_from_system())

func spend(amount: float) -> bool:
	if value < amount:
		return false
	value -= amount
	last_updated = int(Time.get_unix_time_from_system())
	return true
