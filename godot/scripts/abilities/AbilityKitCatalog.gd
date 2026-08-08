extends RefCounted
class_name AbilityKitCatalog
## Balanced cross-mode ability kits — costs from EnergyEconomy (single source).

const EE = preload("res://scripts/systems/EnergyEconomy.gd")

static func kit_for_faction(faction: String) -> Array:
	var out: Array = []
	out.append(_pulse())
	if faction == "gROT":
		out.append(_hack_grot())
		out.append(_surge())
	else:
		out.append(_firewall())
		out.append(_probe())
	out.append(_form_cycle())
	return out


static func _pulse() -> Ability:
	var a := Ability.new()
	a.ability_name = "Pulse Bolt"
	a.description = "Primary soft bolt"
	a.cooldown = EE.CD_PULSE
	a.energy_cost = EE.PULSE_BOLT
	a.damage = 11.0
	a.range = 24.0
	a.targeting = Ability.TargetingType.TARGET_DIRECTION
	a.effect_color = Color(0.25, 0.9, 1.0)
	return a


static func _firewall() -> Ability:
	var a := Ability.new()
	a.ability_name = "Nex-Firewall"
	a.description = "Shield window + soft cleanse"
	a.cooldown = EE.CD_FIREWALL
	a.energy_cost = EE.NEX_FIREWALL
	a.duration = 4.5
	a.heal = 12.0
	a.is_firewall = true
	a.faction_restriction = Ability.FactionRestriction.CYBERNEX_ONLY
	a.effect_color = Color(0.2, 1.0, 0.65)
	return a


static func _probe() -> Ability:
	var a := Ability.new()
	a.ability_name = "System Probe"
	a.description = "Channeled claim/recon pulse"
	a.cooldown = EE.CD_PROBE
	a.energy_cost = EE.SYSTEM_PROBE
	a.damage = 7.0
	a.range = 18.0
	a.is_hacking = true
	a.is_channeled = true
	a.channel_time = 1.35
	a.effect_color = Color(0.4, 0.85, 1.0)
	return a


static func _hack_grot() -> Ability:
	var a := Ability.new()
	a.ability_name = "Hack"
	a.description = "Channeled infection claim push"
	a.cooldown = EE.CD_HACK
	a.energy_cost = EE.HACK
	a.damage = 12.0
	a.range = 18.0
	a.is_hacking = true
	a.is_channeled = true
	a.channel_time = 1.35
	a.faction_restriction = Ability.FactionRestriction.GROT_ONLY
	a.effect_color = Color(1.0, 0.15, 0.45)
	return a


static func _surge() -> Ability:
	var a := Ability.new()
	a.ability_name = "Rot Surge"
	a.description = "Close burst"
	a.cooldown = EE.CD_SURGE
	a.energy_cost = EE.ROT_SURGE
	a.damage = 16.0
	a.effect_color = Color(0.9, 0.12, 0.4)
	return a


static func _form_cycle() -> Ability:
	var a := Ability.new()
	a.ability_name = "Form Cycle"
	a.description = "Cycle cyber-animal form (identity, not power)"
	a.cooldown = EE.CD_FORM
	a.energy_cost = EE.FORM_CYCLE
	a.targeting = Ability.TargetingType.SELF
	return a
