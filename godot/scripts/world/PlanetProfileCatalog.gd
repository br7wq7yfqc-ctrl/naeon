extends RefCounted
class_name PlanetProfileCatalog
## Data-driven planet gravity / atmosphere envelopes (continuum feel, not P2W).

## id -> profile dict
static func profiles() -> Dictionary:
	return {
		"Nex-Prime": {
			"radius": 1400.0,
			"atmosphere_height": 320.0,
			"gravity": 9.0,
			"atmosphere_color": Color(0.25, 0.55, 0.95, 0.1),
			"surface_color": Color(0.12, 0.22, 0.18),
			"faction_base": "Cybernex",
			"has_base": true,
			"pos": Vector3(0, 0, 0),
		},
		"ROT-Hive": {
			"radius": 1100.0,
			"atmosphere_height": 260.0,
			"gravity": 8.4,
			"atmosphere_color": Color(0.7, 0.15, 0.25, 0.1),
			"surface_color": Color(0.22, 0.08, 0.1),
			"faction_base": "gROT",
			"has_base": true,
			"pos": Vector3(4200, 200, -1800),
		},
		"Shard-Moon": {
			"radius": 420.0,
			"atmosphere_height": 40.0,
			"gravity": 2.2,
			"atmosphere_color": Color(0.4, 0.4, 0.45, 0.04),
			"surface_color": Color(0.35, 0.35, 0.38),
			"faction_base": "Neutral",
			"has_base": false,
			"pos": Vector3(-2800, -400, 2200),
		},
	}


static func apply_to(node: Node, profile_id: String) -> void:
	var p: Dictionary = profiles().get(profile_id, {})
	if p.is_empty() or node == null:
		return
	node.set("planet_name", profile_id)
	for k in ["radius", "atmosphere_height", "gravity", "atmosphere_color", "surface_color", "faction_base", "has_base"]:
		if p.has(k):
			node.set(k, p[k])
	if p.has("pos") and node is Node3D:
		(node as Node3D).position = p["pos"]
