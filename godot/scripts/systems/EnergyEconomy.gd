extends RefCounted
class_name EnergyEconomy
## Single source of truth for soft energy costs (TPS / ship / channel).
## No P2W — numbers only; economy contribution never modifies these.

# --- Regen (units/sec) ---
const REGEN_PLAYER := 12.0
const REGEN_WALKER := 12.0
const REGEN_SHIP := 8.0
const MAX_DEFAULT := 100.0

# --- Ability kit ---
const PULSE_BOLT := 6.0
const NEX_FIREWALL := 28.0
const SYSTEM_PROBE := 22.0
const HACK := 22.0
const ROT_SURGE := 14.0
const FORM_CYCLE := 0.0

# --- Ability cooldowns (seconds) mirrored for HUD consistency ---
const CD_PULSE := 0.55
const CD_FIREWALL := 16.0
const CD_PROBE := 11.0
const CD_HACK := 11.0
const CD_SURGE := 5.0
const CD_FORM := 2.0

# --- Ship weapons ---
const SHIP_BOLT_BASE := 5.0
const SHIP_BOLT_NAV := 5.5
const SHIP_BOLT_SIEGE_MULT := 1.35


static func ship_bolt_cost(flight_mode: int, op_mode: int) -> float:
	## flight_mode: 0 SCM, 1 NAV, 2 HOVER (matches ShipController enum order if used carefully)
	var c := SHIP_BOLT_BASE
	if flight_mode == 1:
		c = SHIP_BOLT_NAV
	if op_mode == 1:
		c *= SHIP_BOLT_SIEGE_MULT
	return c


static func can_afford(caster: Node, cost: float) -> bool:
	if cost <= 0.0:
		return true
	if caster == null:
		return false
	if caster.has_method("get_energy"):
		return float(caster.get_energy()) >= cost
	if "energy" in caster:
		return float(caster.energy) >= cost
	return true


static func spend(caster: Node, cost: float) -> bool:
	if cost <= 0.0:
		return true
	if not can_afford(caster, cost):
		return false
	if caster.has_method("spend_energy"):
		caster.spend_energy(cost)
		return true
	if "energy" in caster:
		caster.energy = maxf(0.0, float(caster.energy) - cost)
		return true
	return false


static func refund(caster: Node, cost: float) -> void:
	if cost <= 0.0 or caster == null:
		return
	if caster.has_method("spend_energy") and "energy" in caster and "max_energy" in caster:
		caster.energy = minf(float(caster.max_energy), float(caster.energy) + cost)
	elif "energy" in caster and "max_energy" in caster:
		caster.energy = minf(float(caster.max_energy), float(caster.energy) + cost)
	elif "energy" in caster:
		caster.energy = float(caster.energy) + cost
