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
## OS-D: Pad_North + two extra unnamed plates + rare rock/crate proxies.
const OS_D_FILL := true
## OS-G: one unnamed mast+habitat cluster on an existing pad. Not SITE_*.
const OS_G_OUTPOST := true
const FILLER_PROP_ID := "pad_crate_cc0"
const ORBITAL_STATIONS := false
const PAD_DENSITY := false

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
