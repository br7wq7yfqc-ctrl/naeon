extends RefCounted
class_name HeroFormCatalog
## Wave C hero forms — dual-theme paths (Cybernex/gROT), LOD fallback.
## Soft movement flavor only; never raw combat power from form (CONCEPT / no P2W).

const FORMS_BASE := ["Canine", "Feline", "Avian", "Human"]
const FORM_INFECTOR := "Infector"  ## gROT asymmetric skin (same soft stats band as Feline)

static func forms_for_faction(faction: String) -> PackedStringArray:
	var out := PackedStringArray(FORMS_BASE)
	if faction == "gROT":
		out.append(FORM_INFECTOR)
	return out

static func faction_token(faction: String) -> String:
	return "grot" if faction == "gROT" else "cybernex"

## Relative asset candidates, preferred first
static func mesh_candidates(form: String, faction: String) -> PackedStringArray:
	var fx := faction_token(faction)
	var key := form.to_lower()
	var folder := "player_%s" % key
	var base := "characters/%s/%s_%s" % [folder, folder.replace("player_", "player_"), fx]
	# Normalize folder names
	match form:
		"Canine":
			folder = "player_canine"
		"Feline":
			folder = "player_feline"
		"Avian":
			folder = "player_avian"
		"Human":
			folder = "player_human"
		"Infector":
			folder = "grot_infector"
		_:
			folder = "player_canine"
	var stem := ""
	match form:
		"Canine":
			stem = "player_canine"
		"Feline":
			stem = "player_feline"
		"Avian":
			stem = "player_avian"
		"Human":
			stem = "player_human"
		"Infector":
			stem = "grot_infector"
		_:
			stem = "player_canine"
	var cands := PackedStringArray()
	for s in skinned_candidates(form, faction):
		cands.append(s)
	# preferred clean → base → worn → lod cascade
	for suffix in ["", "_clean", "_worn"]:
		for lod in ["lod0", "lod1", "lod2"]:
			cands.append("characters/%s/%s_%s%s_%s.glb" % [folder, stem, fx, suffix, lod])
	# Infector uses grot/cybernex naming without clean/worn sometimes
	if form == "Infector":
		var inf := PackedStringArray()
		for s in skinned_candidates(form, faction):
			inf.append(s)
		for lod in ["lod0", "lod1", "lod2"]:
			inf.append("characters/grot_infector/grot_infector_%s_%s.glb" % [fx, lod])
		return inf
	return cands

## Soft mobility profile (no DPS/HP/shields)
static func apply_soft_mobility(form: String) -> Dictionary:
	match form:
		"Canine":
			return {"move": 8.5, "jump": 6.5, "sprint": 1.7, "emit": Color(0.2, 0.85, 1.0)}
		"Feline":
			return {"move": 9.5, "jump": 7.5, "sprint": 1.5, "emit": Color(0.9, 0.5, 0.15)}
		"Avian":
			return {"move": 7.5, "jump": 9.0, "sprint": 1.4, "emit": Color(0.55, 0.35, 1.0)}
		"Human":
			return {"move": 7.0, "jump": 6.0, "sprint": 1.5, "emit": Color(0.4, 0.9, 0.55)}
		"Infector":
			return {"move": 9.0, "jump": 7.0, "sprint": 1.55, "emit": Color(0.95, 0.15, 0.45)}
		_:
			return {"move": 8.0, "jump": 6.5, "sprint": 1.5, "emit": Color(0.5, 0.7, 0.9)}


## Sprint C helpers — skinned GLB paths preferred by mesh_candidates callers via extra prepend
static func skinned_candidates(form: String, faction: String) -> PackedStringArray:
	var fx := "grot" if faction == "gROT" else "cybernex"
	var stem := "player_canine"
	match form:
		"Feline":
			stem = "player_feline"
		"Avian":
			stem = "player_avian"
		"Human":
			stem = "player_human"
		"Infector":
			stem = "grot_infector"
		_:
			stem = "player_canine"
	var folder := stem + "_skinned"
	var out := PackedStringArray()
	for lod in ["lod0", "lod1", "lod2"]:
		# pipeline layout: characters/{name}/{name}_{fx}_{lod}.glb
		out.append("characters/%s/%s_%s_%s.glb" % [folder, folder, fx, lod])
		out.append("characters/%s/%s_skinned_%s_%s.glb" % [stem, stem, fx, lod])
	out.append("characters/%s/%s_%s.glb" % [folder, folder, fx])
	return out

