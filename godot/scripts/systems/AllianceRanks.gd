extends RefCounted
class_name AllianceRanks
## Alliance hierarchy ranks 0–4 (rules/11). Cosmetic + permission soft gates.
## NEVER grants combat power, claim strength, or shop DPS.

const RANK_NAMES := {
	0: "Initiate",
	1: "Operative",
	2: "Officer",
	3: "Architect",
	4: "Chancellor",
}

## Soft permissions only (constructor / voice / pool visibility)
const PERMS := {
	0: ["chat", "pad_claim_assist"],
	1: ["chat", "pad_claim_assist", "harvest_share"],
	2: ["chat", "pad_claim_assist", "harvest_share", "constructor_pin", "voice_listen"],
	3: ["chat", "pad_claim_assist", "harvest_share", "constructor_pin", "voice_listen", "voice_speak", "pool_view"],
	4: ["chat", "pad_claim_assist", "harvest_share", "constructor_pin", "voice_listen", "voice_speak", "pool_view", "pool_allocate", "diplomacy"],
}

static func rank_name(rank: int) -> String:
	return str(RANK_NAMES.get(clampi(rank, 0, 4), "Initiate"))

static func has_perm(rank: int, perm: String) -> bool:
	var list: Array = PERMS.get(clampi(rank, 0, 4), [])
	return perm in list

static func next_rank_cost_contribution(rank: int) -> float:
	## Soft social spend of Contribution/Biomass — not combat unlock
	match clampi(rank, 0, 4):
		0: return 50.0
		1: return 150.0
		2: return 400.0
		3: return 1000.0
		_: return 0.0
