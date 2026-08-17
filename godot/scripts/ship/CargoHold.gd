extends Node
class_name CargoHold
## Volume/mass budget + stored vehicle ids + pad crate units.
## Soft logistics only — no P2W combat cargo. Knowledge never writes mass/value.

signal inventory_changed
signal ramp_state_changed(state: String)

const UNIT_VOL_M3 := 1.2
const UNIT_MASS_T := 0.35
const UNIT_VALUE := 1.0

@export var volume_m3: float = 80.0
@export var mass_t: float = 25.0
@export var max_vehicle_slots: int = 2
@export var max_unit_slots: int = 8

var used_volume: float = 0.0
var used_mass: float = 0.0
var vehicles: Array = []  # Dictionary {id, class_id, health, meta}
var units: Array = []  # Dictionary {id, kind, volume, mass, value}

func can_store(class_id: String, vol: float, mass: float) -> bool:
	if vehicles.size() >= max_vehicle_slots:
		return false
	return used_volume + vol <= volume_m3 and used_mass + mass <= mass_t

func store_vehicle(entry: Dictionary) -> bool:
	var vol := float(entry.get("volume", 8.0))
	var mass := float(entry.get("mass", 2.0))
	var cid := str(entry.get("class_id", "rover"))
	if not can_store(cid, vol, mass):
		return false
	vehicles.append(entry)
	used_volume += vol
	used_mass += mass
	inventory_changed.emit()
	return true

func retrieve_vehicle(index: int = 0) -> Dictionary:
	if index < 0 or index >= vehicles.size():
		return {}
	var e: Dictionary = vehicles.pop_at(index)
	used_volume = maxf(0.0, used_volume - float(e.get("volume", 0.0)))
	used_mass = maxf(0.0, used_mass - float(e.get("mass", 0.0)))
	inventory_changed.emit()
	return e

func can_store_unit(vol: float, mass: float) -> bool:
	if units.size() >= max_unit_slots:
		return false
	return used_volume + vol <= volume_m3 and used_mass + mass <= mass_t

func store_unit(entry: Dictionary) -> bool:
	var packed: Dictionary = normalize_unit(entry)
	var vol := float(packed.get("volume", UNIT_VOL_M3))
	var mass := float(packed.get("mass", UNIT_MASS_T))
	if not can_store_unit(vol, mass):
		return false
	units.append(packed)
	used_volume += vol
	used_mass += mass
	inventory_changed.emit()
	return true

func retrieve_unit(index: int = 0) -> Dictionary:
	if index < 0 or index >= units.size():
		return {}
	var e: Dictionary = units.pop_at(index)
	used_volume = maxf(0.0, used_volume - float(e.get("volume", 0.0)))
	used_mass = maxf(0.0, used_mass - float(e.get("mass", 0.0)))
	inventory_changed.emit()
	return e

func unit_count() -> int:
	return units.size()

static func normalize_unit(entry: Dictionary) -> Dictionary:
	## Mass / value stay authored. Knowledge may only label at display time.
	return {
		"id": str(entry.get("id", "crate")),
		"kind": str(entry.get("kind", "crate")),
		"volume": float(entry.get("volume", UNIT_VOL_M3)),
		"mass": float(entry.get("mass", UNIT_MASS_T)),
		"value": float(entry.get("value", UNIT_VALUE)),
	}

static func make_crate(id: String = "crate") -> Dictionary:
	return {
		"id": id,
		"kind": "crate",
		"volume": UNIT_VOL_M3,
		"mass": UNIT_MASS_T,
		"value": UNIT_VALUE,
	}

func summary() -> String:
	return "HOLD %d/%d veh  %d/%d u  %.0f/%.0fm³  %.1f/%.1ft" % [
		vehicles.size(), max_vehicle_slots, units.size(), max_unit_slots,
		used_volume, volume_m3, used_mass, mass_t
	]
