extends Node
class_name SoftShipSystems
## Live hull buses — power / cool / life. Knowledge labels only.
## Overdraw / overheat = soft sag (thrust / weapons). Not a hard lock. Not P2W.

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")

const SAG_FLOOR := 0.38
const DEFAULT_POWER_SUPPLY := 10.0
const DEFAULT_COOL_CAP := 10.0

var life_support: float = 100.0
var power_bus: float = 100.0
var cool_bus: float = 100.0
var hull_integrity: float = 100.0
var atmo_ok: bool = true
var _ship: Node = null
var _t: float = 0.0
var _power_supply: float = DEFAULT_POWER_SUPPLY
var _cool_capacity: float = DEFAULT_COOL_CAP
var _hull_vented: bool = false
var _ls_warn_shown: bool = false


func setup(ship: Node) -> void:
	_ship = ship
	name = "SoftShipSystems"
	set_process(true)
	refresh()


func _process(_delta: float) -> void:
	_t += _delta
	if _ship == null or not is_instance_valid(_ship):
		return
	refresh()
	if _t > 1.0:
		_t = 0.0


func refresh() -> void:
	var draw := power_draw_total()
	var heat := cool_load()
	var supply := power_supply()
	var cap := cool_capacity()
	if draw <= 0.0001:
		power_bus = 100.0
	else:
		power_bus = clampf(supply / draw * 100.0, 0.0, 100.0)
	if heat <= 0.0001:
		cool_bus = 100.0
	else:
		cool_bus = clampf(cap / heat * 100.0, 0.0, 100.0)
	if _hull_vented:
		life_support = 40.0
		atmo_ok = false
	else:
		life_support = 100.0
		atmo_ok = true
	if _ship != null and is_instance_valid(_ship) and "health" in _ship and "max_health" in _ship:
		var mh := float(_ship.max_health) if float(_ship.max_health) > 0.0 else 100.0
		hull_integrity = clampf(float(_ship.health) / mh * 100.0, 0.0, 100.0)


func power_draw_total() -> float:
	## Fitted ShipModule.power_draw. Integrity does not hide the bus load.
	var n := 0.0
	if _ship == null or not is_instance_valid(_ship) or not ("modules" in _ship):
		return n
	var mods = _ship.get("modules")
	if mods == null:
		return n
	for m in mods:
		if m == null:
			continue
		if "power_draw" in m:
			n += float(m.power_draw)
	return n


func cool_load() -> float:
	## Heat rides the same module draw. No second stat invented on ShipModule.
	return power_draw_total()


func power_supply() -> float:
	return _power_supply


func cool_capacity() -> float:
	return _cool_capacity


func is_overdrawn() -> bool:
	return power_draw_total() > _power_supply + 0.0001


func is_overheated() -> bool:
	return cool_load() > _cool_capacity + 0.0001


func sag_mult() -> float:
	## Soft throttle. Floor keeps thrust/weapons alive — never a hard lock.
	var p := 1.0
	var c := 1.0
	var draw := power_draw_total()
	var heat := cool_load()
	if draw > _power_supply + 0.0001:
		p = clampf(_power_supply / draw, SAG_FLOOR, 1.0)
	if heat > _cool_capacity + 0.0001:
		c = clampf(_cool_capacity / heat, SAG_FLOOR, 1.0)
	return minf(p, c)


func set_bus_caps(power: float, cool: float) -> void:
	_power_supply = maxf(0.01, power)
	_cool_capacity = maxf(0.01, cool)
	refresh()


func restore_bus_caps() -> void:
	_power_supply = DEFAULT_POWER_SUPPLY
	_cool_capacity = DEFAULT_COOL_CAP
	refresh()


func set_hull_vented(v: bool) -> void:
	## Soft warn only. This slice never cuts HP.
	_hull_vented = v
	if v:
		_ls_warn_shown = true
		if GameManager:
			GameManager.toast_requested.emit("EVA suit — reboard soon (soft warn)")
		print("[Ship] EVA soft warning — hull life-support vented (no HP cut)")
	refresh()


func is_hull_vented() -> bool:
	return _hull_vented


func has_life_support() -> bool:
	return not _hull_vented


func life_support_warn_shown() -> bool:
	return _ls_warn_shown


func life_support_line() -> String:
	## Same IN-B phrases: sealed OK / vented suit. Soft warn, no HP.
	if _hull_vented:
		return "SUIT REQUIRED · ATMO 0.00 · POWER IDLE · VENTED"
	return "LIFE SUPPORT OK · ATMO 1.00 · POWER BUS STABLE"


func try_cash_repair_skip(_cash: float = 0.0) -> bool:
	print("[Ship] cash-shop bus repair refused")
	return false


func cash_shop_skip_possible() -> bool:
	return false


func status_line() -> String:
	var p_lbl := _SoftK.power_bus_label()
	var c_lbl := _SoftK.cool_bus_label()
	var l_lbl := _SoftK.life_bus_label()
	return "%s %.1f/%.1f  %s %.1f/%.1f  %s %s" % [
		p_lbl, power_draw_total(), power_supply(),
		c_lbl, cool_load(), cool_capacity(),
		l_lbl, life_support_line(),
	]


func pulse_stress(amount: float = 5.0) -> void:
	## Presentation dip only. Does not cut HP or skip sag.
	life_support = maxf(40.0, life_support - amount)
	power_bus = maxf(30.0, power_bus - amount * 0.5)
