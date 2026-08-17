extends RefCounted
class_name OpenSpaceHudStack
## One OpenSpace play stack. Presentation only — no gameplay, no SITE_*, no G2–G6.
## Left column under the no-P2W line; GFX/FPS/OBJECTIVE stay on the right/center.

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")

const FIELDS := [
	"fuel", "fuel_max", "cargo", "module_tag", "module_pct",
	"landed", "occupy", "eva_mode",
	"econ", "econ_rate", "econ_grot",
]


static func snapshot(ship: Node = null, player: Node = null, pad: Node = null) -> Dictionary:
	var snap := {
		"fuel": -1.0,
		"fuel_max": -1.0,
		"cargo": 0,
		"module_tag": "",
		"module_pct": 100.0,
		"landed": false,
		"occupy": "",
		"eva_mode": "",
		"econ": 0.0,
		"econ_rate": 0.0,
		"econ_grot": false,
	}
	if ship != null and is_instance_valid(ship):
		if "fuel" in ship:
			snap["fuel"] = float(ship.get("fuel"))
			snap["fuel_max"] = float(ship.get("max_fuel")) if "max_fuel" in ship else 100.0
		var hold: Node = ship.get_node_or_null("CargoHold")
		if hold != null and hold.has_method("unit_count"):
			snap["cargo"] = int(hold.unit_count())
		if "is_landed" in ship:
			snap["landed"] = bool(ship.get("is_landed"))
		var worst := _worst_module(ship)
		snap["module_tag"] = str(worst.get("tag", ""))
		snap["module_pct"] = float(worst.get("pct", 100.0))
	if pad != null and is_instance_valid(pad) and pad.has_method("get_claim_status"):
		snap["occupy"] = str(pad.get_claim_status())
		# Rate is display-only. Knowledge may label it; harvest yield stays.
		if str(snap["occupy"]) == "extracting":
			var rate := 0.0
			if "extract_rate" in pad and "contribution_per_unit" in pad:
				rate = float(pad.get("extract_rate")) * float(pad.get("contribution_per_unit"))
			snap["econ_rate"] = rate
	if GameManager:
		var grot := false
		if GameManager.has_method("get_faction_name"):
			grot = str(GameManager.get_faction_name()) == "gROT"
		snap["econ_grot"] = grot
		if grot:
			snap["econ"] = float(GameManager.biomass) if "biomass" in GameManager else 0.0
		else:
			snap["econ"] = float(GameManager.contribution) if "contribution" in GameManager else 0.0
	if player != null and is_instance_valid(player):
		if "eva_mode" in player and bool(player.get("eva_mode")):
			if player.has_method("is_zero_g") and bool(player.is_zero_g()):
				snap["eva_mode"] = "EVA 0G"
			else:
				snap["eva_mode"] = "EVA"
	return snap


static func has_fields(snap: Dictionary) -> bool:
	if snap.is_empty():
		return false
	for k in FIELDS:
		if not snap.has(k):
			return false
	return true


static func stack_text(snap: Dictionary) -> String:
	if not has_fields(snap):
		return ""
	var fuel_s := "FUEL —"
	var fuel_now := float(snap.get("fuel", -1.0))
	var fuel_max := float(snap.get("fuel_max", -1.0))
	if fuel_now >= 0.0 and fuel_max > 0.0:
		fuel_s = "FUEL %.0f/%.0f" % [fuel_now, fuel_max]
	var cargo_s := "%s ×%d" % [_SoftK.crate_label(), int(snap.get("cargo", 0))]
	var tag := str(snap.get("module_tag", ""))
	var mod_s := "MOD —"
	if tag != "":
		mod_s = "MOD %s %.0f%%" % [tag, float(snap.get("module_pct", 100.0))]
	var land_s := "LANDED" if bool(snap.get("landed", false)) else "FLIGHT"
	var occ := str(snap.get("occupy", ""))
	if occ != "":
		land_s += " · occupy %s" % occ
	var eva := str(snap.get("eva_mode", ""))
	if eva == "":
		eva = "—"
	var grot := bool(snap.get("econ_grot", false))
	var unit := _SoftK.yield_label(grot)
	var econ_s := "%s %.1f" % [unit, float(snap.get("econ", 0.0))]
	var rate := float(snap.get("econ_rate", 0.0))
	if rate > 0.001:
		econ_s += "  +%.1f/s" % rate
	return "%s\n%s\n%s\n%s\n%s\n%s" % [econ_s, fuel_s, cargo_s, mod_s, land_s, eva]


static func _worst_module(ship: Node) -> Dictionary:
	var tag := ""
	var pct := 100.0
	if ship == null or not ("modules" in ship):
		return {"tag": tag, "pct": pct}
	var mods = ship.get("modules")
	if mods == null:
		return {"tag": tag, "pct": pct}
	for m in mods:
		if m == null:
			continue
		var p := 100.0
		if m.has_method("integrity"):
			p = float(m.integrity()) * 100.0
		elif "hp" in m and "max_hp" in m and float(m.max_hp) > 0.01:
			p = clampf(float(m.hp) / float(m.max_hp), 0.0, 1.0) * 100.0
		var t := ""
		if m.has_method("short_tag"):
			t = str(m.short_tag())
		elif "display_name" in m:
			t = str(m.display_name)
		if t == "":
			continue
		if tag == "" or p < pct:
			tag = t
			pct = p
	return {"tag": tag, "pct": pct}
