extends RefCounted
class_name FaunaCatalog
## Data-driven fauna: domain x biome -> species defs (visual soft density).

enum Domain { AQUATIC, TERRESTRIAL, AERIAL, SPACE }


static func domain_name(d: int) -> String:
	match d:
		Domain.AQUATIC:
			return "aquatic"
		Domain.TERRESTRIAL:
			return "terrestrial"
		Domain.AERIAL:
			return "aerial"
		Domain.SPACE:
			return "space"
		_:
			return "unknown"


static func biomes() -> Dictionary:
	return {
		"temperate_forest": {"domains": [Domain.TERRESTRIAL, Domain.AERIAL], "tint": Color(0.25, 0.55, 0.28), "density": 1.0},
		"crystal_coast": {"domains": [Domain.TERRESTRIAL, Domain.AQUATIC, Domain.AERIAL], "tint": Color(0.3, 0.55, 0.7), "density": 0.9},
		"shallow_sea": {"domains": [Domain.AQUATIC], "tint": Color(0.15, 0.4, 0.65), "density": 1.1},
		"fungal_wastes": {"domains": [Domain.TERRESTRIAL, Domain.AERIAL], "tint": Color(0.55, 0.18, 0.32), "density": 1.05},
		"biomass_sea": {"domains": [Domain.AQUATIC, Domain.AERIAL], "tint": Color(0.6, 0.12, 0.28), "density": 1.0},
		"spore_sky": {"domains": [Domain.AERIAL], "tint": Color(0.7, 0.3, 0.45), "density": 0.85},
		"barren_regolith": {"domains": [Domain.TERRESTRIAL, Domain.SPACE], "tint": Color(0.45, 0.45, 0.48), "density": 0.55},
		"ice_crater": {"domains": [Domain.TERRESTRIAL, Domain.AQUATIC], "tint": Color(0.55, 0.7, 0.85), "density": 0.5},
		"thin_air": {"domains": [Domain.AERIAL, Domain.SPACE], "tint": Color(0.5, 0.55, 0.65), "density": 0.45},
		"orbital_belt": {"domains": [Domain.SPACE], "tint": Color(0.4, 0.75, 1.0), "density": 0.7},
	}


static func species() -> Dictionary:
	return {
		"crystal_grazer": {
			"domain": Domain.TERRESTRIAL, "scale": 0.9, "speed": 1.2,
			"color": Color(0.45, 0.85, 0.95), "shape": "quad", "mesh": "",
			"biomes": ["temperate_forest", "crystal_coast"],
		},
		"shard_hopper": {
			"domain": Domain.TERRESTRIAL, "scale": 0.55, "speed": 2.4,
			"color": Color(0.7, 0.7, 0.75), "shape": "sphere", "mesh": "",
			"biomes": ["barren_regolith", "ice_crater", "crystal_coast"],
		},
		"thrall_beetle": {
			"domain": Domain.TERRESTRIAL, "scale": 0.7, "speed": 1.0,
			"color": Color(0.85, 0.2, 0.4), "shape": "capsule",
			"mesh": "characters/grot_thrall/grot_thrall_grot_lod2.glb",
			"biomes": ["fungal_wastes"],
		},
		"nex_fox": {
			"domain": Domain.TERRESTRIAL, "scale": 0.75, "speed": 1.8,
			"color": Color(0.3, 0.75, 0.95), "shape": "capsule",
			"mesh": "characters/player_canine/player_canine_cybernex_lod2.glb",
			"biomes": ["temperate_forest"],
		},
		"reef_runner": {
			"domain": Domain.AQUATIC, "scale": 0.5, "speed": 2.0,
			"color": Color(0.2, 0.7, 0.9), "shape": "sphere", "mesh": "",
			"biomes": ["shallow_sea", "crystal_coast"],
		},
		"abyssal_jelly": {
			"domain": Domain.AQUATIC, "scale": 1.1, "speed": 0.6,
			"color": Color(0.5, 0.15, 0.55), "shape": "sphere", "mesh": "",
			"biomes": ["shallow_sea", "biomass_sea"],
		},
		"ice_krill_swarm": {
			"domain": Domain.AQUATIC, "scale": 0.25, "speed": 1.5,
			"color": Color(0.7, 0.85, 1.0), "shape": "sphere", "mesh": "",
			"biomes": ["ice_crater"],
		},
		"biomass_leech": {
			"domain": Domain.AQUATIC, "scale": 0.65, "speed": 1.1,
			"color": Color(0.9, 0.15, 0.35), "shape": "capsule", "mesh": "",
			"biomes": ["biomass_sea"],
		},
		"nex_glider": {
			"domain": Domain.AERIAL, "scale": 0.8, "speed": 3.0,
			"color": Color(0.35, 0.8, 1.0), "shape": "quad",
			"mesh": "characters/player_avian/player_avian_cybernex_lod2.glb",
			"biomes": ["temperate_forest", "crystal_coast", "thin_air"],
		},
		"spore_moth": {
			"domain": Domain.AERIAL, "scale": 0.45, "speed": 2.2,
			"color": Color(0.95, 0.4, 0.55), "shape": "sphere", "mesh": "",
			"biomes": ["spore_sky", "fungal_wastes", "biomass_sea"],
		},
		"hive_wasp": {
			"domain": Domain.AERIAL, "scale": 0.4, "speed": 3.5,
			"color": Color(1.0, 0.55, 0.2), "shape": "capsule",
			"mesh": "characters/combat_drone/combat_drone_cybernex_lod2.glb",
			"biomes": ["fungal_wastes", "spore_sky"],
		},
		"void_mite": {
			"domain": Domain.SPACE, "scale": 0.35, "speed": 1.4,
			"color": Color(0.5, 0.9, 1.0), "shape": "sphere", "mesh": "",
			"biomes": ["thin_air", "orbital_belt", "barren_regolith"],
		},
		"metal_barnacle": {
			"domain": Domain.SPACE, "scale": 0.5, "speed": 0.3,
			"color": Color(0.55, 0.6, 0.65), "shape": "sphere", "mesh": "",
			"biomes": ["orbital_belt", "barren_regolith"],
		},
		"plasma_eel": {
			"domain": Domain.SPACE, "scale": 1.2, "speed": 2.8,
			"color": Color(0.3, 0.95, 1.0), "shape": "capsule", "mesh": "",
			"biomes": ["orbital_belt"],
		},
	}


static func planet_biomes(planet_id: String) -> PackedStringArray:
	match planet_id:
		"Nex-Prime":
			return PackedStringArray(["temperate_forest", "crystal_coast", "shallow_sea"])
		"ROT-Hive":
			return PackedStringArray(["fungal_wastes", "biomass_sea", "spore_sky"])
		"Shard-Moon":
			return PackedStringArray(["barren_regolith", "ice_crater", "thin_air"])
		_:
			return PackedStringArray(["temperate_forest"])


static func species_for_biome(biome: String) -> Array:
	var out: Array = []
	var all: Dictionary = species()
	for id in all.keys():
		var d: Dictionary = all[id]
		var bl: Array = d.get("biomes", [])
		if biome in bl:
			var e: Dictionary = d.duplicate()
			e["id"] = id
			out.append(e)
	return out


static func pick_species(biome: String, rng: RandomNumberGenerator) -> Dictionary:
	var list: Array = species_for_biome(biome)
	if list.is_empty():
		return {}
	return list[rng.randi() % list.size()]
