extends RefCounted
class_name AbilityKitCatalog
## Balanced cross-mode ability kits — costs from EnergyEconomy (single source).
## AR-E: 4 faction kits × 4 slots. Forms = identity, never a hidden stat.
## AR-L: fifth kit (CX Lattice) toward Phase-3 6–8. Same Pulse / utility /
## probe|surge / Form Cycle grammar. SoftKnowledge labels only.
## AR-M: sixth kit (GR Vein) — gROT symmetric to CX Lattice. Same grammar.
## AR-N: seventh kit (CX Prism) — Cybernex symmetric slot after Lattice / Vein.
## AR-O: eighth kit (GR Facet) — gROT symmetric slot after CX Prism / GR Vein.
## AR-P: ninth kit (CX Helix) — Cybernex symmetric slot after Prism / Facet.

const EE = preload("res://scripts/systems/EnergyEconomy.gd")

const KIT_CX_NEX := "cx_nex"
const KIT_CX_GRID := "cx_grid"
const KIT_GR_ROT := "gr_rot"
const KIT_GR_SPORE := "gr_spore"
const KIT_CX_LATTICE := "cx_lattice"
const KIT_GR_VEIN := "gr_vein"
const KIT_CX_PRISM := "cx_prism"
const KIT_GR_FACET := "gr_facet"
const KIT_CX_HELIX := "cx_helix"

const KIT_TABLE := [
	{"id": KIT_CX_NEX, "faction": "Cybernex", "label": "Nex"},
	{"id": KIT_CX_GRID, "faction": "Cybernex", "label": "Grid"},
	{"id": KIT_GR_ROT, "faction": "gROT", "label": "Rot"},
	{"id": KIT_GR_SPORE, "faction": "gROT", "label": "Spore"},
	{"id": KIT_CX_LATTICE, "faction": "Cybernex", "label": "Lattice"},
	{"id": KIT_GR_VEIN, "faction": "gROT", "label": "Vein"},
	{"id": KIT_CX_PRISM, "faction": "Cybernex", "label": "Prism"},
	{"id": KIT_GR_FACET, "faction": "gROT", "label": "Facet"},
	{"id": KIT_CX_HELIX, "faction": "Cybernex", "label": "Helix"},
]


static func kit_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for row in KIT_TABLE:
		out.append(str(row["id"]))
	return out


static func kit_table() -> Array:
	return KIT_TABLE.duplicate(true)


static func kit_meta(kit_id: String) -> Dictionary:
	for row in KIT_TABLE:
		if str(row["id"]) == kit_id:
			return row.duplicate(true)
	return {}


static func default_kit_id(faction: String) -> String:
	return KIT_GR_ROT if faction == "gROT" else KIT_CX_NEX


static func kits_for_faction(faction: String) -> PackedStringArray:
	var out := PackedStringArray()
	var want := "gROT" if faction == "gROT" else "Cybernex"
	for row in KIT_TABLE:
		if str(row["faction"]) == want:
			out.append(str(row["id"]))
	return out


static func kit_for_faction(faction: String) -> Array:
	return kit_by_id(default_kit_id(faction))


static func kit_by_id(kit_id: String) -> Array:
	match kit_id:
		KIT_CX_GRID:
			return [_pulse(), _nex_latch(), _grid_probe(), _form_cycle()]
		KIT_CX_LATTICE:
			return [_pulse(), _lattice_seal(), _lattice_probe(), _form_cycle()]
		KIT_CX_PRISM:
			return [_pulse(), _prism_seal(), _prism_probe(), _form_cycle()]
		KIT_CX_HELIX:
			return [_pulse(), _helix_seal(), _helix_probe(), _form_cycle()]
		KIT_GR_SPORE:
			return [_pulse(), _spore_claim(), _rot_bloom(), _form_cycle()]
		KIT_GR_VEIN:
			return [_pulse(), _vein_claim(), _vein_surge(), _form_cycle()]
		KIT_GR_FACET:
			return [_pulse(), _facet_seal(), _facet_probe(), _form_cycle()]
		KIT_GR_ROT:
			return [_pulse(), _hack_grot(), _surge(), _form_cycle()]
		_:
			return [_pulse(), _firewall(), _probe(), _form_cycle()]


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
	a.duration = 2.5
	a.heal = 12.0
	a.range = 18.0
	a.is_firewall = true
	a.faction_restriction = Ability.FactionRestriction.CYBERNEX_ONLY
	a.effect_color = Color(0.2, 1.0, 0.65)
	return a


static func _nex_latch() -> Ability:
	var a := Ability.new()
	a.ability_name = "Nex Latch"
	a.description = "Short seal window (identity, same cost sheet)"
	a.cooldown = EE.CD_FIREWALL
	a.energy_cost = EE.NEX_FIREWALL
	a.duration = 2.5
	a.heal = 12.0
	a.range = 18.0
	a.is_firewall = true
	a.faction_restriction = Ability.FactionRestriction.CYBERNEX_ONLY
	a.effect_color = Color(0.35, 0.95, 0.85)
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
	a.channel_time = 1.5
	a.effect_color = Color(0.4, 0.85, 1.0)
	return a


static func _lattice_seal() -> Ability:
	var a := Ability.new()
	a.ability_name = "Lattice Seal"
	a.description = "Short lattice seal window (identity, same cost sheet)"
	a.cooldown = EE.CD_FIREWALL
	a.energy_cost = EE.NEX_FIREWALL
	a.duration = 2.5
	a.heal = 12.0
	a.range = 18.0
	a.is_firewall = true
	a.faction_restriction = Ability.FactionRestriction.CYBERNEX_ONLY
	a.effect_color = Color(0.45, 0.8, 1.0)
	return a


static func _lattice_probe() -> Ability:
	var a := Ability.new()
	a.ability_name = "Lattice Probe"
	a.description = "Channeled lattice recon (identity, same cost sheet)"
	a.cooldown = EE.CD_PROBE
	a.energy_cost = EE.SYSTEM_PROBE
	a.damage = 7.0
	a.range = 18.0
	a.is_hacking = true
	a.is_channeled = true
	a.channel_time = 1.5
	a.effect_color = Color(0.65, 0.7, 1.0)
	return a


static func _prism_seal() -> Ability:
	var a := Ability.new()
	a.ability_name = "Prism Seal"
	a.description = "Short prism seal window (identity, same cost sheet)"
	a.cooldown = EE.CD_FIREWALL
	a.energy_cost = EE.NEX_FIREWALL
	a.duration = 2.5
	a.heal = 12.0
	a.range = 18.0
	a.is_firewall = true
	a.faction_restriction = Ability.FactionRestriction.CYBERNEX_ONLY
	a.effect_color = Color(0.72, 0.52, 1.0)
	return a


static func _prism_probe() -> Ability:
	var a := Ability.new()
	a.ability_name = "Prism Probe"
	a.description = "Channeled prism recon (identity, same cost sheet)"
	a.cooldown = EE.CD_PROBE
	a.energy_cost = EE.SYSTEM_PROBE
	a.damage = 7.0
	a.range = 18.0
	a.is_hacking = true
	a.is_channeled = true
	a.channel_time = 1.5
	a.effect_color = Color(0.88, 0.48, 1.0)
	return a


static func _helix_seal() -> Ability:
	var a := Ability.new()
	a.ability_name = "Helix Seal"
	a.description = "Short helix seal window (identity, same cost sheet)"
	a.cooldown = EE.CD_FIREWALL
	a.energy_cost = EE.NEX_FIREWALL
	a.duration = 2.5
	a.heal = 12.0
	a.range = 18.0
	a.is_firewall = true
	a.faction_restriction = Ability.FactionRestriction.CYBERNEX_ONLY
	a.effect_color = Color(0.28, 0.92, 0.78)
	return a


static func _helix_probe() -> Ability:
	var a := Ability.new()
	a.ability_name = "Helix Probe"
	a.description = "Channeled helix recon (identity, same cost sheet)"
	a.cooldown = EE.CD_PROBE
	a.energy_cost = EE.SYSTEM_PROBE
	a.damage = 7.0
	a.range = 18.0
	a.is_hacking = true
	a.is_channeled = true
	a.channel_time = 1.5
	a.effect_color = Color(0.18, 0.85, 0.72)
	return a


static func _grid_probe() -> Ability:
	var a := Ability.new()
	a.ability_name = "Grid Probe"
	a.description = "Channeled lattice recon (identity, same cost sheet)"
	a.cooldown = EE.CD_PROBE
	a.energy_cost = EE.SYSTEM_PROBE
	a.damage = 7.0
	a.range = 18.0
	a.is_hacking = true
	a.is_channeled = true
	a.channel_time = 1.5
	a.effect_color = Color(0.55, 0.75, 1.0)
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
	a.channel_time = 1.5
	a.faction_restriction = Ability.FactionRestriction.GROT_ONLY
	a.effect_color = Color(1.0, 0.15, 0.45)
	return a


static func _spore_claim() -> Ability:
	var a := Ability.new()
	a.ability_name = "Spore Claim"
	a.description = "Channeled spore claim (identity, same cost sheet)"
	a.cooldown = EE.CD_HACK
	a.energy_cost = EE.HACK
	a.damage = 12.0
	a.range = 18.0
	a.is_hacking = true
	a.is_channeled = true
	a.channel_time = 1.5
	a.faction_restriction = Ability.FactionRestriction.GROT_ONLY
	a.effect_color = Color(0.95, 0.35, 0.2)
	return a


static func _surge() -> Ability:
	var a := Ability.new()
	a.ability_name = "Rot Surge"
	a.description = "Close burst"
	a.cooldown = EE.CD_SURGE
	a.energy_cost = EE.ROT_SURGE
	a.damage = 16.0
	a.range = 5.0
	a.aoe_radius = 4.5
	a.force = 8.0
	a.targeting = Ability.TargetingType.AOE
	a.effect_color = Color(0.9, 0.12, 0.4)
	return a


static func _rot_bloom() -> Ability:
	var a := Ability.new()
	a.ability_name = "Rot Bloom"
	a.description = "Close spore burst (identity, same cost sheet)"
	a.cooldown = EE.CD_SURGE
	a.energy_cost = EE.ROT_SURGE
	a.damage = 16.0
	a.range = 5.0
	a.aoe_radius = 4.5
	a.force = 8.0
	a.targeting = Ability.TargetingType.AOE
	a.effect_color = Color(0.85, 0.28, 0.12)
	return a


static func _vein_claim() -> Ability:
	var a := Ability.new()
	a.ability_name = "Vein Claim"
	a.description = "Channeled vein claim (identity, same cost sheet)"
	a.cooldown = EE.CD_HACK
	a.energy_cost = EE.HACK
	a.damage = 12.0
	a.range = 18.0
	a.is_hacking = true
	a.is_channeled = true
	a.channel_time = 1.5
	a.faction_restriction = Ability.FactionRestriction.GROT_ONLY
	a.effect_color = Color(0.78, 0.18, 0.48)
	return a


static func _vein_surge() -> Ability:
	var a := Ability.new()
	a.ability_name = "Vein Surge"
	a.description = "Close vein burst (identity, same cost sheet)"
	a.cooldown = EE.CD_SURGE
	a.energy_cost = EE.ROT_SURGE
	a.damage = 16.0
	a.range = 5.0
	a.aoe_radius = 4.5
	a.force = 8.0
	a.targeting = Ability.TargetingType.AOE
	a.effect_color = Color(0.68, 0.08, 0.32)
	return a


static func _facet_seal() -> Ability:
	var a := Ability.new()
	a.ability_name = "Facet Seal"
	a.description = "Short facet seal window (identity, same cost sheet)"
	a.cooldown = EE.CD_FIREWALL
	a.energy_cost = EE.NEX_FIREWALL
	a.duration = 2.5
	a.heal = 12.0
	a.range = 18.0
	a.is_firewall = true
	a.faction_restriction = Ability.FactionRestriction.GROT_ONLY
	a.effect_color = Color(0.95, 0.38, 0.55)
	return a


static func _facet_probe() -> Ability:
	var a := Ability.new()
	a.ability_name = "Facet Probe"
	a.description = "Channeled facet recon (identity, same cost sheet)"
	a.cooldown = EE.CD_PROBE
	a.energy_cost = EE.SYSTEM_PROBE
	a.damage = 7.0
	a.range = 18.0
	a.is_hacking = true
	a.is_channeled = true
	a.channel_time = 1.5
	a.effect_color = Color(0.82, 0.15, 0.42)
	return a


static func _form_cycle() -> Ability:
	var a := Ability.new()
	a.ability_name = "Form Cycle"
	a.description = "Cycle cyber-animal form (identity, not power)"
	a.cooldown = EE.CD_FORM
	a.energy_cost = EE.FORM_CYCLE
	a.targeting = Ability.TargetingType.SELF
	return a
