extends Node
class_name CargoHold
## Volume/mass budget + stored vehicle ids for haulers / capitals.
## Soft logistics only — no P2W combat cargo.

signal inventory_changed
signal ramp_state_changed(state: String)

@export var volume_m3: float = 80.0
@export var mass_t: float = 25.0
@export var max_vehicle_slots: int = 2

var used_volume: float = 0.0
var used_mass: float = 0.0
var vehicles: Array = []  # Dictionary {id, class_id, health, meta}

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

func summary() -> String:
	return "HOLD %d/%d  %.0f/%.0fm³  %.1f/%.1ft" % [
		vehicles.size(), max_vehicle_slots, used_volume, volume_m3, used_mass, mass_t
	]
