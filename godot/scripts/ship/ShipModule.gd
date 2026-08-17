class_name ShipModule
extends Resource

## Modular ship component (engine / weapon / shield / cargo / extractor).
## Own HP: damage degrades this function. Does not delete the hull.
## power_draw is a stat stub — this slice does not invent power/cool/life buses.

enum ModuleType { HULL, ENGINE, WEAPON, SHIELD, CARGO, EXTRACTOR, SENSOR }

@export var module_id: String = ""
@export var display_name: String = "Module"
@export var module_type: ModuleType = ModuleType.ENGINE
@export var mass: float = 1.0
@export var power_draw: float = 1.0
@export var thrust: float = 0.0
@export var weapon_dps: float = 0.0
@export var shield_bonus: float = 0.0
@export var cargo_bonus: float = 0.0
@export var extract_rate: float = 0.0
@export var faction_skin: String = "Cybernex"
@export var max_hp: float = 40.0
@export var hp: float = 40.0


func integrity() -> float:
	if max_hp <= 0.01:
		return 0.0
	return clampf(hp / max_hp, 0.0, 1.0)


func is_damaged() -> bool:
	return hp < max_hp - 0.05


func apply_damage(amount: float) -> float:
	hp = maxf(0.0, hp - maxf(0.0, amount))
	return hp


func repair(amount: float) -> float:
	hp = minf(max_hp, hp + maxf(0.0, amount))
	return hp


func effective_thrust() -> float:
	return thrust * integrity()


func effective_weapon_dps() -> float:
	return weapon_dps * integrity()


func effective_shield_bonus() -> float:
	return shield_bonus * integrity()


func effective_cargo_bonus() -> float:
	return cargo_bonus * integrity()


func effective_extract_rate() -> float:
	return extract_rate * integrity()


func short_tag() -> String:
	match module_type:
		ModuleType.ENGINE:
			return "ENG"
		ModuleType.WEAPON:
			return "WPN"
		ModuleType.SHIELD:
			return "SHD"
		ModuleType.CARGO:
			return "CRG"
		ModuleType.EXTRACTOR:
			return "EXT"
		ModuleType.SENSOR:
			return "SNS"
		_:
			return "HUL"

static func make_engine(name: String = "Ion Drive", thrust: float = 18.0) -> ShipModule:
	var m := ShipModule.new()
	m.module_id = "engine_%s" % name.to_lower().replace(" ", "_")
	m.display_name = name
	m.module_type = ModuleType.ENGINE
	m.thrust = thrust
	m.power_draw = 4.0
	m.mass = 2.0
	return m

static func make_weapon(name: String = "Pulse Cannon", dps: float = 14.0) -> ShipModule:
	var m := ShipModule.new()
	m.module_id = "weapon_%s" % name.to_lower().replace(" ", "_")
	m.display_name = name
	m.module_type = ModuleType.WEAPON
	m.weapon_dps = dps
	m.power_draw = 3.0
	m.mass = 1.5
	return m

static func make_shield(name: String = "Nex Barrier", bonus: float = 40.0) -> ShipModule:
	var m := ShipModule.new()
	m.module_id = "shield_%s" % name.to_lower().replace(" ", "_")
	m.display_name = name
	m.module_type = ModuleType.SHIELD
	m.shield_bonus = bonus
	m.power_draw = 2.5
	m.mass = 1.2
	return m

static func make_extractor(name: String = "RBE Tap", rate: float = 2.0) -> ShipModule:
	var m := ShipModule.new()
	m.module_id = "extractor_%s" % name.to_lower().replace(" ", "_")
	m.display_name = name
	m.module_type = ModuleType.EXTRACTOR
	m.extract_rate = rate
	m.power_draw = 2.0
	m.mass = 2.5
	return m

static func make_cargo(name: String = "Cargo Pod", capacity: float = 15.0) -> ShipModule:
	var m := ShipModule.new()
	m.module_id = "cargo_%s" % name.to_lower().replace(" ", "_")
	m.display_name = name
	m.module_type = ModuleType.CARGO
	m.cargo_bonus = capacity
	m.power_draw = 0.5
	m.mass = 3.0
	return m


static func make_sensor(name: String = "Nex Sensor") -> ShipModule:
	var m := ShipModule.new()
	m.module_id = "sensor_%s" % name.to_lower().replace(" ", "_")
	m.display_name = name
	m.module_type = ModuleType.SENSOR
	m.power_draw = 1.0
	m.mass = 0.8
	return m
