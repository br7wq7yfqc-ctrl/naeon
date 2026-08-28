extends RefCounted
class_name P0Slice
## P0 stabilization gate. Not content. Flip FILL_STREAMERS / ONLY_BODY when
## P0.1–P0.4 are green — do not grow rings or mint systems from here.

const ACTIVE := true
## Human slice pays for one body until a single chunk is stable.
const ONLY_BODY := "Nex-Prime"
## Flora / fauna / water / caves / landscape / terrain-edit: seven independent
## live waves. Off until one heightfield ring restores without a rebuild.
const FILL_STREAMERS := false
## P0.2: no density cluster. OS-D still adds extra unnamed pads + sparse scatter.
## OS-G clusters a mast/habitat on one of those pads.
const ONE_PAD := true
## OS-D: Pad_North + two extra unnamed plates + denser unnamed scatter
## from existing ledger slugs (crates, debris, pad props, extra masts).
const OS_D_FILL := true
## WF-A: one density slice on those same unnamed pads. Existing ledger slugs
## / filler IDs only. Not a new pad. Not SITE_*. Does not flip ORBITAL_STATIONS.
const WF_A_DENSITY := true
## OS-G: one unnamed mast+habitat cluster on an existing pad. Not SITE_*.
const OS_G_OUTPOST := true
const FILLER_PROP_ID := "pad_crate_cc0"
const ORBITAL_STATIONS := false
const PAD_DENSITY := false
## ST-A: strategy overlay + one player habitat on an unnamed pad. Not G2.
const ST_A_OVERLAY := true
## ST-B: visible extractor on unnamed pad + Contribution on HUD. Knowledge labels only.
const ST_B_EXTRACTOR := true
## ST-C: print one catalog module at pad / NPC bench. Spend Contribution/Biomass. No cash skip.
const ST_C_PRINT := true
## ST-D: hangar queue of one module on a catalog carrier. Blocked by mass/power. Not SITE_*.
const ST_D_HANGAR := true
## ST-E: player-owned orbital cluster of two catalog modules near Nex-Prime. Not SITE_*.
## Does not flip ORBITAL_STATIONS (those remain unnamed props, still off).
const ST_E_ORBITAL := true
## ST-F: CX↔GR owner swap on one occupied unnamed pad. Theme + services; same tier numbers.
## Uses swap_cluster_theme + OwnershipData. Not a second SITE_*. Not arena-flip.
const ST_F_OWNERSHIP := true
## ST-G: factory in the existing player cluster. Bench (c) print of one catalog module.
## Does not rewrite ST-E dock+habitat. Does not flip ORBITAL_STATIONS.
const ST_G_FACTORY := true
## NP-C: visitor places one habitat on an empty unnamed pad. Same BaseBuilder. Not SITE_*.
const NP_C_MODULE := true
## Q-A: one Contract Board + one generated template. SoftKnowledge label only.
const Q_A_CONTRACT := true
## Q-B: one alliance-shared occupy/logistics contract on the same unnamed pad.
## SoftKnowledge alliance intel only. Reuses ContractBoard / SoftSession. Not siege.
const Q_B_ALLIANCE := true

const BUILD_TOKENS := 1
const RESTORE_TOKENS := 6

static var _frame: int = -1
static var _builds: int = 0
static var _restores: int = 0


static func reset_budget() -> void:
	var f: int = Engine.get_process_frames()
	if f == _frame:
		return
	_frame = f
	_builds = 0
	_restores = 0


static func take_build() -> bool:
	reset_budget()
	if _builds >= BUILD_TOKENS:
		return false
	_builds += 1
	return true


static func take_restore() -> bool:
	reset_budget()
	if _restores >= RESTORE_TOKENS:
		return false
	_restores += 1
	return true


static func body_allowed(planet_id: String) -> bool:
	if not ACTIVE or ONLY_BODY == "":
		return true
	return planet_id == ONLY_BODY
