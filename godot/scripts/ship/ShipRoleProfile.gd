extends Resource
class_name ShipRoleProfile
## Data-driven hull role: op-modes, siege mults, interior id, morph node poses.
## Economical: no assets required — multipliers + morph paths only.

@export var hull_id: String = scout
@export var display_name: String = Scout
@export var interior_profile_id: String = scout_single
@export var can_eva: bool = true
@export var eva_max_exit_speed: float = 40.0

## Op modes available on this hull
@export var allows_siege: bool = false
@export var allows_scan: bool = true
@export var allows_cargo_open: bool = false

## Siege (sniper / emplaced) — role kit, not P2W shop power
@export var siege_thrust_mult: float = 0.35
@export var siege_turn_mult: float = 0.4
@export var siege_main_dps_mult: float = 1.6
@export var siege_spread_mult: float = 0.5
@export var siege_enter_sec: float = 1.2
@export var siege_exit_sec: float = 0.8

static func make_scout() -> ShipRoleProfile:
	var p := ShipRoleProfile.new()
	p.hull_id = scout
	p.display_name = Scout
	p.interior_profile_id = scout_single
	p.allows_siege = false
	p.allows_scan = true
	return p

static func make_sniper() -> ShipRoleProfile:
	var p := ShipRoleProfile.new()
	p.hull_id = sniper
	p.display_name = Siege Lance
	p.interior_profile_id = sniper_gunnery
	p.allows_siege = true
	p.allows_scan = true
	p.siege_thrust_mult = 0.32
	p.siege_turn_mult = 0.38
	p.siege_main_dps_mult = 1.75
	p.siege_spread_mult = 0.4
	return p

static func make_hauler() -> ShipRoleProfile:
	var p := ShipRoleProfile.new()
	p.hull_id = hauler
	p.display_name = Hauler
	p.interior_profile_id = hauler_cargo
	p.allows_cargo_open = true
	p.allows_siege = false
	return p
