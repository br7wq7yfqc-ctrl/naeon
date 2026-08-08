extends Node
class_name SoftShipSystems
## Soft ship status for HUD — life support / power / hull (presentation + regen feel).
## No P2W combat power from economy.

var life_support: float = 100.0
var power_bus: float = 100.0
var hull_integrity: float = 100.0
var atmo_ok: bool = true
var _ship: Node = null
var _t: float = 0.0


func setup(ship: Node) -> void:
	_ship = ship
	name = "SoftShipSystems"
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	if _ship == null or not is_instance_valid(_ship):
		return
	# Slow recovery
	life_support = minf(100.0, life_support + 2.0 * delta)
	power_bus = minf(100.0, power_bus + 3.0 * delta)
	if "health" in _ship and "max_health" in _ship:
		var mh := float(_ship.max_health) if float(_ship.max_health) > 0.0 else 100.0
		hull_integrity = clampf(float(_ship.health) / mh * 100.0, 0.0, 100.0)
	# EVA drain soft when open hatch long — optional future
	if _t > 1.0:
		_t = 0.0


func status_line() -> String:
	return "LS %.0f  PWR %.0f  HULL %.0f" % [life_support, power_bus, hull_integrity]


func pulse_stress(amount: float = 5.0) -> void:
	life_support = maxf(40.0, life_support - amount)
	power_bus = maxf(30.0, power_bus - amount * 0.5)
