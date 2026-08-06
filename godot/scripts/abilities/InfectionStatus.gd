extends Node
class_name InfectionStatus
## Infection stacks on a character (gROT pressure). Soft combat state, not P2W.
## Stack effects from docs/rules ability parameter sheet.

signal stacks_changed(stacks: int)

const MAX_STACKS := 5
const DECAY_OOC := 3.5
const DECAY_COMBAT := 7.0

var stacks: int = 0
var _decay_timer: float = 0.0
var in_combat: bool = false
var glitch_timer: float = 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if glitch_timer > 0.0:
		glitch_timer = maxf(0.0, glitch_timer - delta)
	if stacks <= 0:
		return
	_decay_timer += delta
	var need := DECAY_COMBAT if in_combat else DECAY_OOC
	if _decay_timer >= need:
		_decay_timer = 0.0
		remove_stacks(1)

func add_stacks(n: int = 1) -> void:
	var prev := stacks
	stacks = mini(MAX_STACKS, stacks + n)
	_decay_timer = 0.0
	if stacks >= 5 and prev < 5:
		glitch_timer = 1.2
	if stacks != prev:
		stacks_changed.emit(stacks)
		print("[Infection] stacks=", stacks)

func remove_stacks(n: int = 1) -> void:
	var prev := stacks
	stacks = maxi(0, stacks - n)
	if stacks != prev:
		stacks_changed.emit(stacks)

func cleanse(n: int = 1) -> void:
	remove_stacks(n)

func energy_regen_mult() -> float:
	match stacks:
		0: return 1.0
		1: return 0.80
		2: return 0.65
		3: return 0.50
		_: return 0.50

func damage_taken_mult_from_grot() -> float:
	match stacks:
		0, 1: return 1.0
		2: return 1.08
		3: return 1.15
		4: return 1.15
		_: return 1.25

func move_speed_mult() -> float:
	if glitch_timer > 0.0:
		return 0.6
	return 1.0

func can_channel() -> bool:
	return glitch_timer <= 0.0
