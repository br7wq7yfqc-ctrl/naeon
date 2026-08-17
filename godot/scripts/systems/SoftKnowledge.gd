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

## Biology/Genetics: earlier infection stage labels (info only)
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

## Logistics: resource warning threshold earlier (QoL)
static func low_energy_threshold() -> float:
	var logi := mastery("logistics")
	# Higher logistics → warn earlier (at higher remaining %)
	return clampf(0.15 + logi * 0.002, 0.15, 0.35)

static func insight_display_pct() -> float:
	if GameManager and GameManager.has_method("knowledge_insight_bonus"):
		return float(GameManager.knowledge_insight_bonus()) * 100.0
	return clampf(float(rank()) * 0.2, 0.0, 15.0)
