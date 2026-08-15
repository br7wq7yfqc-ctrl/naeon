extends RefCounted
class_name StarSystemCatalog
## Authored star-system layout: one star at the origin, bodies on distinct
## orbits, a belt band, and gate anchors to neighbouring systems.
##
## Physical envelopes (radius / gravity / atmosphere) stay in
## PlanetProfileCatalog. This file owns *where things are*, so planets are
## spread around their star instead of sitting on hand-typed coordinates.
##
## Gate anchors are authored here but nothing spawns them yet: a gate prop with
## no jump behind it would be exactly the "looks implemented, is inert" trap the
## 2026-08-15 audit was cleaning up. See docs/design/GALAXY_LAYER_PLAN.md.

const HOME := "ARK"


static func systems() -> Dictionary:
	return {
		"ARK": {
			"display": "ARK",
			"faction": "Cybernex",
			"star": {
				"name": "Aex",
				"radius": 900.0,
				"spectral": "G",
				"color": Color(1.0, 0.94, 0.80),
				"light_energy": 1.55,
			},
			# orbit = distance from the star, angle = position along the orbit,
			# incl = orbital plane tilt. Distinct angles keep the bodies from
			# lining up, distinct inclinations keep them out of one plane.
			"bodies": [
				{"id": "Nex-Prime", "orbit": 3800.0, "angle_deg": 24.0, "incl_deg": 0.0},
				{"id": "ROT-Hive", "orbit": 7400.0, "angle_deg": 158.0, "incl_deg": 6.5},
				{"id": "Shard-Moon", "orbit": 11800.0, "angle_deg": 268.0, "incl_deg": -9.0},
			],
			"belt": {"inner": 9000.0, "outer": 10400.0, "thickness": 420.0},
			"gates": [
				{"to": "ROT-Prime", "orbit": 13600.0, "angle_deg": 312.0, "incl_deg": 3.0, "state": "open"},
				{"to": "Helios Reach", "orbit": 13600.0, "angle_deg": 84.0, "incl_deg": -4.0, "state": "open"},
				{"to": "Echo Ruins", "orbit": 15200.0, "angle_deg": 200.0, "incl_deg": 11.0, "state": "dormant"},
			],
		},
	}


static func home_system() -> Dictionary:
	return systems().get(HOME, {})


static func body_ids(system_id: String = HOME) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var sys: Dictionary = systems().get(system_id, {})
	for b in sys.get("bodies", []):
		out.append(str(b.get("id", "")))
	return out


static func orbital_position(orbit: float, angle_deg: float, incl_deg: float) -> Vector3:
	## Point on an inclined circular orbit around the system origin.
	var a := deg_to_rad(angle_deg)
	var flat := Vector3(cos(a) * orbit, 0.0, sin(a) * orbit)
	return flat.rotated(Vector3.RIGHT, deg_to_rad(incl_deg))


static func body_position(body_id: String, system_id: String = HOME) -> Vector3:
	var sys: Dictionary = systems().get(system_id, {})
	for b in sys.get("bodies", []):
		if str(b.get("id", "")) == body_id:
			return orbital_position(
				float(b.get("orbit", 4000.0)),
				float(b.get("angle_deg", 0.0)),
				float(b.get("incl_deg", 0.0))
			)
	return Vector3.ZERO


static func star_of(system_id: String = HOME) -> Dictionary:
	return systems().get(system_id, {}).get("star", {})


static func belt_of(system_id: String = HOME) -> Dictionary:
	return systems().get(system_id, {}).get("belt", {})


static func gates_of(system_id: String = HOME) -> Array:
	return systems().get(system_id, {}).get("gates", [])


static func gate_position(gate: Dictionary) -> Vector3:
	return orbital_position(
		float(gate.get("orbit", 13000.0)),
		float(gate.get("angle_deg", 0.0)),
		float(gate.get("incl_deg", 0.0))
	)
