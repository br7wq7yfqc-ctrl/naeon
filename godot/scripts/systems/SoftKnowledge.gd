extends RefCounted
class_name SoftKnowledge
## Soft Knowledge / Subject Mastery — informational & QoL only (CONCEPT §7.3).
## NEVER grants raw damage, HP, shields, CDR, or claim strength.

const CAP_INSIGHT := 0.15  ## max soft insight fraction (display / QoL)

static func mastery(subject: String) -> float:
	if GameManager == null:
		return 0.0
	return float(GameManager.subject_mastery.get(subject, 0.0))

static func rank() -> int:
	if GameManager == null:
		return 0
	return int(GameManager.knowledge_rank)

## Biology/Genetics: earlier infection stage labels (info only).
## HF-A: names the stack only — never DPS / yield / thrust.
static func infection_label(stacks: int) -> String:
	var bio := mastery("biology")
	if stacks <= 0:
		return ""
	# Higher bio mastery → earlier warning text detail
	if bio >= 40.0:
		match stacks:
			1: return "INF α (trace) — purge window open"
			2: return "INF β (spread) — energy drain rising"
			3: return "INF γ (deep) — channel risk"
			4: return "INF δ (critical)"
			_: return "INF Ω GLITCH — cannot channel"
	if bio >= 15.0:
		return "INF ×%d  stage visible" % stacks
	return "INF ×%d" % stacks

## Logic/Programming: Firewall diagnostic text (not stronger shield)
static func firewall_hint(charges_left: float, duration: float) -> String:
	var logic := mastery("logic")
	if logic < 10.0:
		return "FIREWALL %.0fs" % duration
	if logic >= 50.0:
		return "NEX-DIAG: resist window %.1fs | cleanse ready" % duration
	return "FW %.0fs  (diag L%.0f)" % [duration, logic]

## Physics: optional lead marker scale for HUD (visual aid only — not auto-aim)
static func lead_marker_visible() -> bool:
	return mastery("physics") >= 20.0

static func lead_marker_scale() -> float:
	# Caps at mild prediction ring; never locks aim
	return clampf(0.4 + mastery("physics") * 0.008, 0.4, 1.2)

## Languages: intercept flavor on enemy claim (dialogue QoL)
static func intercept_claim_toast(enemy_faction: String) -> String:
	var lang := mastery("languages")
	if lang < 10.0:
		return ""
	if enemy_faction == "gROT":
		return "Intercept: swarm chatter decoded — claim pressure rising"
	if enemy_faction == "Cybernex":
		return "Intercept: Nex-band handshake — rival claim active"
	return "Intercept: unknown protocol"

## Ecology/History: jungle camp name only — never HP / DPS.
static func camp_label() -> String:
	var eco := mastery("ecology")
	var hist := mastery("history")
	if eco >= 10.0 or hist >= 15.0 or rank() >= 5:
		return "PIT OBJECTIVE"
	return "CAMP"


## Cybernetics/Logic: module bench name only — never DPS / HP.
static func module_bench_label() -> String:
	var cyber := mastery("cybernetics")
	var logic := mastery("logic")
	if cyber >= 10.0 or logic >= 15.0 or rank() >= 5:
		return "BLUEPRINT BENCH"
	return "MODULE BENCH"


## Logistics/Ecology: rover name only — never speed / HP.
static func rover_label() -> String:
	var logi := mastery("logistics")
	var eco := mastery("ecology")
	if logi >= 10.0 or eco >= 15.0 or rank() >= 5:
		return "SURFACE ROVER"
	return "ROVER"


## History/Languages: pad traffic name only — never DPS / density.
static func traffic_label(kind: String = "guard") -> String:
	var hist := mastery("history")
	var lang := mastery("languages")
	var named := hist >= 10.0 or lang >= 10.0 or rank() >= 5
	if kind == "visitor":
		return "VISITING HULL" if named else "VISITOR"
	return "PAD GUARD" if named else "GUARD"


## History/combat: surface dummy name only — never Pulse DPS.
static func surface_dummy_label() -> String:
	var hist := mastery("history")
	var combat := mastery("combat")
	if hist >= 10.0 or combat >= 10.0 or rank() >= 5:
		return "DRILL DUMMY"
	return "DUMMY"


## History/combat: pad rival name only — never Pulse DPS / HP.
static func rival_label() -> String:
	var hist := mastery("history")
	var combat := mastery("combat")
	if hist >= 10.0 or combat >= 10.0 or rank() >= 5:
		return "PAD RIVAL"
	return "RIVAL"


## History/combat: gROT swarm name only — never Pulse DPS / HP / yield.
static func swarm_label() -> String:
	var hist := mastery("history")
	var combat := mastery("combat")
	if hist >= 10.0 or combat >= 10.0 or rank() >= 5:
		return "GROT SWARM"
	return "SWARM"


## History/combat: Cybernex animal-robot pack name only — never Pulse DPS / HP / yield.
static func pack_label() -> String:
	var hist := mastery("history")
	var combat := mastery("combat")
	if hist >= 10.0 or combat >= 10.0 or rank() >= 5:
		return "NEX PACK"
	return "PACK"


## History/Lore: structure weakness tip (info only)
static func structure_tip(faction: String) -> String:
	var lore := mastery("history")
	if lore < 15.0:
		return ""
	if faction == "gROT":
		return "Lore: biomass nodes slow under sustained Firewall pulses"
	if faction == "Cybernex":
		return "Lore: Nex pads recover claim if Extraction uninterrupted"
	return ""

## Logistics: name the pad pump. Never changes refill rate or skips the wait.
static func pump_label() -> String:
	var logi := mastery("logistics")
	if logi >= 15.0 or rank() >= 5:
		return "REFUEL PUMP"
	return "PUMP"


## Logistics/combat: name the pad locker. Never skips the energy / Pulse wait.
static func locker_label() -> String:
	var logi := mastery("logistics")
	var combat := mastery("combat")
	if logi >= 15.0 or combat >= 15.0 or rank() >= 5:
		return "RESTOCK LOCKER"
	return "LOCKER"


## Logistics: name the crate. Never changes mass or value.
static func crate_label() -> String:
	var logi := mastery("logistics")
	if logi >= 15.0 or rank() >= 5:
		return "SCU CRATE"
	return "CRATE"


## Colony/biomass ops: name the soft wallet. Never changes harvest yield.
## gROT: BIOMASS / BIOMASS RANK. Cybernex stays CONTRIB / CONTRIBUTION.
static func yield_label(grot: bool = false) -> String:
	var ops := mastery("biomass_ops") if grot else mastery("colony_ops")
	if grot:
		return "BIOMASS RANK" if ops >= 15.0 or rank() >= 5 else "BIOMASS"
	return "CONTRIBUTION" if ops >= 15.0 or rank() >= 5 else "CONTRIB"


## BR-A: Biomass Rank 0–4 as a HUD number. Never yield / DPS / Pulse / Hack / print.
static func biomass_rank_label(rank: int = -1) -> String:
	var r := rank
	if r < 0:
		if GameManager != null and GameManager.has_method("biomass_rank"):
			r = int(GameManager.biomass_rank())
		else:
			r = 0
	return str(clampi(r, 0, 4))


## CR-A: Contribution Rank 0–4 as a HUD number. Never yield / DPS / Pulse / Hack / print.
static func contribution_rank_label(rank: int = -1) -> String:
	var r := rank
	if r < 0:
		if GameManager != null and GameManager.has_method("contribution_rank"):
			r = int(GameManager.contribution_rank())
		else:
			r = 0
	return str(clampi(r, 0, 4))


## KR-A: name the Knowledge Rank track. Never yield / DPS / Pulse / Hack / print.
static func knowledge_rank_word() -> String:
	var intel := mastery("quest_intel") + mastery("field_intel") + mastery("history")
	if intel >= 15.0 or rank() >= 5:
		return "KNOWLEDGE RANK"
	return "KNOWLEDGE"


## KR-A: Knowledge Rank 0–4 as a HUD number. Never yield / DPS / Pulse / Hack / print.
static func knowledge_rank_label(rank: int = -1) -> String:
	var r := rank
	if r < 0:
		if GameManager != null and GameManager.has_method("knowledge_ladder"):
			r = int(GameManager.knowledge_ladder())
		else:
			r = 0
	return str(clampi(r, 0, 4))


## Colony/history: name the ST-E orbital cluster. Never mints SITE_* or a city.
static func orbital_station_label() -> String:
	var ops := mastery("colony_ops")
	var hist := mastery("history")
	if ops >= 15.0 or hist >= 15.0 or rank() >= 5:
		return "T1 ORBITAL CLUSTER"
	return "ORBITAL CLUSTER"


## Colony/history: name the §6(b) hangar queue. Never changes mass/power caps.
static func hangar_queue_label() -> String:
	var ops := mastery("colony_ops")
	var hist := mastery("history")
	if ops >= 15.0 or hist >= 15.0 or rank() >= 5:
		return "T1 HANGAR QUEUE"
	return "HANGAR QUEUE"


## Colony/history: name the §6(c) factory. Never changes print cost.
static func factory_label() -> String:
	var ops := mastery("colony_ops")
	var hist := mastery("history")
	if ops >= 15.0 or hist >= 15.0 or rank() >= 5:
		return "T1 FACTORY"
	return "FACTORY"


## Colony/history: name the §6(a) print bench. Never changes print cost.
static func print_bench_label() -> String:
	var ops := mastery("colony_ops")
	var hist := mastery("history")
	if ops >= 15.0 or hist >= 15.0 or rank() >= 5:
		return "T1 PRINT BENCH"
	return "PRINT BENCH"


## Colony/history: name the pad extractor. Never changes extract_rate or yield.
static func extractor_label() -> String:
	var ops := mastery("colony_ops")
	var hist := mastery("history")
	if ops >= 15.0 or hist >= 15.0 or rank() >= 5:
		return "T1 EXTRACTOR"
	return "EXTRACTOR"


## Colony/logistics: name the ST-I pad storage. Never mass / value / cap.
static func storage_label() -> String:
	var ops := mastery("colony_ops")
	var logi := mastery("logistics")
	if ops >= 15.0 or logi >= 15.0 or rank() >= 5:
		return "T1 STORAGE"
	return "STORAGE"


## Colony/combat: name the ST-H pad turret. Never Pulse DPS / HP / repair.
static func turret_label() -> String:
	var ops := mastery("colony_ops")
	var combat := mastery("combat")
	if ops >= 15.0 or combat >= 15.0 or rank() >= 5:
		return "T1 TURRET"
	return "TURRET"


## Colony/logistics: name the ST-J pad hangar stub. Never mass / queue / combat.
static func hangar_stub_label() -> String:
	var ops := mastery("colony_ops")
	var logi := mastery("logistics")
	if ops >= 15.0 or logi >= 15.0 or rank() >= 5:
		return "T1 HANGAR STUB"
	return "HANGAR STUB"


## Q-A: name the ops contract board. Never yield / DPS / exclusive modules.
static func contract_board_label() -> String:
	var intel := mastery("quest_intel")
	if intel >= 10.0:
		return "OPS CONTRACT BOARD"
	return "CONTRACT BOARD"


## Q-A: contract intel rank/label. story ≠ power. Never a weapon gate.
static func contract_intel_label() -> String:
	var intel := mastery("quest_intel")
	if intel >= 10.0:
		return "PAD INTEL"
	return "CONTRACT"


## Q-B: alliance intel rank/label. story ≠ power. Never HP / DPS / claim.
static func alliance_intel_label() -> String:
	var intel := mastery("alliance_intel")
	if intel >= 10.0:
		return "ALLY INTEL"
	return "ALLY"


## Hull buses: name only. Never changes supply / draw / sag / repair.
static func power_bus_label() -> String:
	var cyber := mastery("cybernetics")
	if cyber >= 10.0 or rank() >= 5:
		return "PWR BUS"
	return "PWR"


static func cool_bus_label() -> String:
	var cyber := mastery("cybernetics")
	if cyber >= 10.0 or rank() >= 5:
		return "COOL BUS"
	return "COOL"


static func life_bus_label() -> String:
	var bio := mastery("biology")
	if bio >= 10.0 or rank() >= 5:
		return "LIFE SUPPORT"
	return "LS"


## SN-B: name the hull SoftNet visual. Never DPS / yield / thrust / Pulse.
static func net_visual_label() -> String:
	var logi := mastery("logistics")
	if logi >= 15.0 or rank() >= 5:
		return "NET VISUAL"
	return "NET"


## FL-A: name the Strategy overlay fleet pip. Never DPS / yield / thrust.
static func fleet_label() -> String:
	var logi := mastery("logistics")
	var hist := mastery("history")
	if logi >= 15.0 or hist >= 15.0 or rank() >= 5:
		return "FLEET MANIFEST"
	return "FLEET"


## MC-A: name the hull crew count. Never changes thrust / DPS / yield.
static func crew_label() -> String:
	var logi := mastery("logistics")
	if logi >= 15.0 or rank() >= 5:
		return "CREW MANIFEST"
	return "CREW"


## MC-B / MC-C / MC-D: name the crew station role. Never Pulse / Hack / thrust / DPS / yield.
static func crew_role_label(role: String = "gunner") -> String:
	var r := str(role)
	if r == "engineer":
		var ops := mastery("colony_ops")
		var logi_e := mastery("logistics")
		if ops >= 15.0 or logi_e >= 15.0 or rank() >= 5:
			return "ENGINEER STATION"
		return "ENGINEER"
	if r == "ops":
		var ops_m := mastery("colony_ops")
		var logi_o := mastery("logistics")
		if ops_m >= 15.0 or logi_o >= 15.0 or rank() >= 5:
			return "OPS STATION"
		return "OPS"
	if r != "gunner":
		return ""
	var combat := mastery("combat")
	var logi := mastery("logistics")
	if combat >= 15.0 or logi >= 15.0 or rank() >= 5:
		return "GUNNER STATION"
	return "GUNNER"


## Q-D: name the pad visitor as a giver. Never yield / DPS / exclusive modules.
static func quest_giver_label() -> String:
	var intel := mastery("quest_intel")
	if intel >= 10.0:
		return "LIAISON"
	return "GIVER"


## Q-C: Learning Node subject label. story ≠ power. Never yield / DPS / modules.
static func field_intel_label() -> String:
	var intel := mastery("field_intel")
	if intel >= 10.0:
		return "FIELD INTEL"
	return "FIELD"


## Q-C: read pad / extractor / crate intel. Labels only. Never harvest numbers.
static func read_node_intel(kind: String) -> String:
	match str(kind):
		"extractor":
			return extractor_label()
		"crate":
			return crate_label()
		"pad":
			var intel := mastery("field_intel")
			var hist := mastery("history")
			if intel >= 10.0 or hist >= 15.0:
				return "HELD PAD"
			return "PAD"
		_:
			return ""


static func exclusive_weapon_unlocked(_id: String = "") -> bool:
	return false


static func exclusive_module_unlocked(_id: String = "") -> bool:
	return false


## ST-F: owner skins the service list. Never harvest / print / hangar numbers.
static func cluster_services(grot: bool = false) -> PackedStringArray:
	if grot:
		return PackedStringArray(["biomass harvest", "vat print", "spore locker"])
	return PackedStringArray(["contribution harvest", "factory print", "nex locker"])


## Logistics: resource warning threshold earlier (QoL)
static func low_energy_threshold() -> float:
	var logi := mastery("logistics")
	# Higher logistics → warn earlier (at higher remaining %)
	return clampf(0.15 + logi * 0.002, 0.15, 0.35)

static func insight_display_pct() -> float:
	if GameManager and GameManager.has_method("knowledge_insight_bonus"):
		return float(GameManager.knowledge_insight_bonus()) * 100.0
	return clampf(float(rank()) * 0.2, 0.0, 15.0)
