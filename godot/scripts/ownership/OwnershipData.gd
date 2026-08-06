class_name OwnershipData
extends Resource

## Ownership state for claimable objects (bases, stations, extractors, modules).

enum Faction {
	NEUTRAL,
	CYBERNEX,
	GROT,
	CONTESTED
}

@export var current_faction: Faction = Faction.NEUTRAL
@export var previous_faction: Faction = Faction.NEUTRAL
@export var transition_progress: float = 1.0  ## 0.0 = just started, 1.0 = fully transformed
@export var claim_strength: float = 0.0
@export var last_claim_time: int = 0
@export var owner_alliance_id: String = ""
@export var object_id: String = ""

func is_fully_owned() -> bool:
	return current_faction != Faction.NEUTRAL \
		and current_faction != Faction.CONTESTED \
		and transition_progress >= 1.0

func start_transition(new_faction: Faction) -> void:
	if new_faction == current_faction and transition_progress >= 1.0:
		return
	previous_faction = current_faction
	current_faction = new_faction
	transition_progress = 0.0
	last_claim_time = int(Time.get_unix_time_from_system())

func advance_transition(delta: float, duration: float = 8.0) -> void:
	if transition_progress >= 1.0:
		return
	transition_progress = clampf(transition_progress + delta / max(duration, 0.01), 0.0, 1.0)

func faction_name() -> String:
	match current_faction:
		Faction.CYBERNEX:
			return "Cybernex"
		Faction.GROT:
			return "gROT"
		Faction.CONTESTED:
			return "Contested"
		_:
			return "Neutral"

static func from_string(name: String) -> Faction:
	match name:
		"Cybernex", "CYBERNEX":
			return Faction.CYBERNEX
		"gROT", "GROT", "Grot":
			return Faction.GROT
		"Contested":
			return Faction.CONTESTED
		_:
			return Faction.NEUTRAL
