class_name ShipModule
extends Resource

## Modular ship component (engine / weapon / shield / cargo / extractor).

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
