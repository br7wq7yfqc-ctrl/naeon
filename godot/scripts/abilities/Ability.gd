class_name Ability
extends Resource

## Base class for all abilities (TPS, MOBA, Strategy)
## Data-driven design for easy expansion and balancing

@export var ability_name: String = "Unnamed Ability"
@export var description: String = ""
@export var icon: Texture2D

@export_group("Costs & Cooldown")
@export var cooldown: float = 5.0
@export var energy_cost: float = 10.0
@export var biomass_cost: float = 0.0  # for gROT

@export_group("Targeting")
enum TargetingType { SELF, TARGET_ENEMY, TARGET_ALLY, TARGET_POINT, TARGET_DIRECTION, AOE }
@export var targeting: TargetingType = TargetingType.SELF
@export var range: float = 10.0
@export var aoe_radius: float = 0.0

@export_group("Faction")
enum FactionRestriction { ANY, CYBERNEX_ONLY, GROT_ONLY }
@export var faction_restriction: FactionRestriction = FactionRestriction.ANY

@export_group("Effects")
@export var duration: float = 0.0
@export var damage: float = 0.0
@export var heal: float = 0.0
@export var is_hacking: bool = false
@export var is_firewall: bool = false

## Override in derived abilities or use signals
func can_activate(caster: Node) -> bool:
	return true

func activate(caster: Node, target = null) -> void:
	print("[Ability] Activated: ", ability_name)
	# Base implementation - override or use composition
