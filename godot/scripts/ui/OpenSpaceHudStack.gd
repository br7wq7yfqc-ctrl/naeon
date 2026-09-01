extends RefCounted
class_name OpenSpaceHudStack
## One OpenSpace play stack. Presentation only — no gameplay, no SITE_*, no G2–G6.
## Left column under the no-P2W line; GFX/FPS/OBJECTIVE stay on the right/center.

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")

const FIELDS := [
	"fuel", "fuel_max", "cargo", "module_tag", "module_pct",
	"landed", "occupy", "eva_mode",
	"econ", "econ_rate", "econ_grot",
	"energy", "energy_max",
	"power_draw", "power_supply", "cool_load", "cool_cap", "life",
	"crew", "crew_max", "crew_role",
]


static func player_ship(tree: SceneTree) -> Node:
	## Do not use get_first_node_in_group("ship"): pad-traffic VisitorShip is
	## often LANDED and wins the HashSet. Same lottery as the chase Camera3D.
	if tree == null:
		return null
	var os: Node = tree.get_first_node_in_group("open_space")
	if os != null and is_instance_valid(os):
		var sh = os.get("ship")
		if sh != null and is_instance_valid(sh):
			return sh
	for n in tree.get_nodes_in_group("ship"):
		if n == null or not is_instance_valid(n):
			continue
		if n.has_method("is_npc_pilot") and bool(n.is_npc_pilot()):
			continue
		return n
	return null


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
		"energy": -1.0,
		"energy_max": -1.0,
		"power_draw": 0.0,
		"power_supply": 0.0,
		"cool_load": 0.0,
		"cool_cap": 0.0,
		"life": "",
		"crew": 0,
		"crew_max": 2,
		"crew_role": "gunner",
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
		var buses: Node = null
		if ship.has_method("engineering_buses"):
			buses = ship.engineering_buses()
		if buses == null:
			buses = ship.get_node_or_null("SoftShipSystems")
		if buses != null:
			if buses.has_method("power_draw_total"):
				snap["power_draw"] = float(buses.power_draw_total())
			if buses.has_method("power_supply"):
				snap["power_supply"] = float(buses.power_supply())
			if buses.has_method("cool_load"):
				snap["cool_load"] = float(buses.cool_load())
			if buses.has_method("cool_capacity"):
				snap["cool_cap"] = float(buses.cool_capacity())
			if buses.has_method("life_support_line"):
				snap["life"] = str(buses.life_support_line())
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
		if "energy" in player:
			snap["energy"] = float(player.get("energy"))
			snap["energy_max"] = float(player.get("max_energy")) if "max_energy" in player else 100.0
		if "eva_mode" in player and bool(player.get("eva_mode")):
			if player.has_method("is_zero_g") and bool(player.is_zero_g()):
				snap["eva_mode"] = "EVA 0G"
			else:
				snap["eva_mode"] = "EVA"
	_fill_crew(snap, ship, player)
	return snap


static func _fill_crew(snap: Dictionary, ship: Node, player: Node) -> void:
	## Label only. Knowledge may rename the word; numbers stay occupancy.
	var tree: SceneTree = null
	if ship != null and is_instance_valid(ship):
		tree = ship.get_tree()
	elif player != null and is_instance_valid(player):
		tree = player.get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("interior_director"):
		if n != null and is_instance_valid(n) and n.has_method("crew_occupancy"):
			var o: Dictionary = n.crew_occupancy()
			snap["crew"] = int(o.get("total", 0))
			snap["crew_max"] = int(o.get("max", 2))
			snap["crew_role"] = str(o.get("role", "gunner"))
			return
	var os: Node = tree.get_first_node_in_group("open_space")
	if os != null and is_instance_valid(os) and bool(os.get("_in_ship")):
		snap["crew"] = 1
		snap["crew_max"] = 2
		snap["crew_role"] = "gunner"


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
	var en_s := "EN —"
	var en_now := float(snap.get("energy", -1.0))
	var en_max := float(snap.get("energy_max", -1.0))
	if en_now >= 0.0 and en_max > 0.0:
		en_s = "EN %.0f/%.0f" % [en_now, en_max]
	var pwr_s := "PWR —"
	var p_draw := float(snap.get("power_draw", 0.0))
	var p_sup := float(snap.get("power_supply", 0.0))
	if p_draw > 0.0 or p_sup > 0.0:
		pwr_s = "%s %.1f/%.1f" % [_SoftK.power_bus_label(), p_draw, p_sup]
	var cool_s := "COOL —"
	var c_load := float(snap.get("cool_load", 0.0))
	var c_cap := float(snap.get("cool_cap", 0.0))
	if c_load > 0.0 or c_cap > 0.0:
		cool_s = "%s %.1f/%.1f" % [_SoftK.cool_bus_label(), c_load, c_cap]
	var life_raw := str(snap.get("life", ""))
	var ls_s := "%s —" % _SoftK.life_bus_label()
	if life_raw != "":
		ls_s = "%s %s" % [_SoftK.life_bus_label(), life_raw]
	var crew_s := "%s %d/%d · %s" % [
		_SoftK.crew_label(),
		int(snap.get("crew", 0)),
		int(snap.get("crew_max", 2)),
		_SoftK.crew_role_label(str(snap.get("crew_role", "gunner"))),
	]
	return "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s" % [
		econ_s, fuel_s, cargo_s, mod_s, pwr_s, cool_s, ls_s, land_s, eva, en_s, crew_s,
	]


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
