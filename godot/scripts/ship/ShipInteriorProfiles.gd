extends RefCounted
class_name ShipInteriorProfiles
## Catalog of interior room graphs per hull — pilot + one MC-A crew seat.

static func profile(id: String) -> Dictionary:
	match id:
		"sniper_gunnery":
			return {
				"id": "sniper_gunnery",
				"rooms": [
					{"name": "Cockpit", "pos": Vector3(0, 0, 0), "size": Vector3(4.5, 2.6, 6)},
					{"name": "Gunnery", "pos": Vector3(0, 0, 8), "size": Vector3(5.5, 3.0, 8)},
					{"name": "Airlock", "pos": Vector3(0, 0, 15), "size": Vector3(3.5, 2.4, 4)},
				],
				"props": [
					{"rel": "props/ship_cockpit_console/ship_cockpit_console_%s_lod1.glb", "pos": Vector3(0, 0, -0.3), "s": 0.9},
					{"rel": "props/holo_projector/holo_projector_%s_lod2.glb", "pos": Vector3(0, 0, 8), "s": 1.0},
					{"rel": "props/control_console/control_console_%s_lod1.glb", "pos": Vector3(1.5, 0, 9), "s": 0.8},
				],
				"seat": Vector3(0, 1.0, 0.5),
				"crew_seat": Vector3(-1.4, 1.0, 1.85),
				"hatch": Vector3(0, 1.2, 16.5),
			}
		"hauler_cargo":
			return {
				"id": "hauler_cargo",
				"rooms": [
					{"name": "Cockpit", "pos": Vector3(0, 0, 0), "size": Vector3(5, 2.8, 6)},
					{"name": "Cargo", "pos": Vector3(0, 0, 12), "size": Vector3(8, 4, 14)},
					{"name": "Airlock", "pos": Vector3(0, 0, 22), "size": Vector3(4, 2.6, 4)},
				],
				"props": [
					{"rel": "props/ship_cockpit_console/ship_cockpit_console_%s_lod1.glb", "pos": Vector3(0, 0, 0), "s": 0.85},
					{"rel": "props/storage_barrel/storage_barrel_%s_lod2.glb", "pos": Vector3(2, 0, 12), "s": 0.7},
					{"rel": "props/sci_fi_crate/sci_fi_crate_%s_lod2.glb", "pos": Vector3(-2, 0, 14), "s": 0.8},
				],
				"seat": Vector3(0, 1.0, 0.5),
				"crew_seat": Vector3(-1.5, 1.0, 1.9),
				"hatch": Vector3(0, 1.2, 23.5),
			}
		_:
			return {
				"id": "scout_single",
				"rooms": [
					{"name": "Cockpit", "pos": Vector3(0, 0, 0), "size": Vector3(4.2, 2.5, 5.5)},
					{"name": "Airlock", "pos": Vector3(0, 0, 6), "size": Vector3(3.2, 2.3, 3.5)},
				],
				"props": [
					{"rel": "props/ship_cockpit_console/ship_cockpit_console_%s_lod1.glb", "pos": Vector3(0, 0, -0.4), "s": 0.85},
					{"rel": "props/control_console/control_console_%s_lod2.glb", "pos": Vector3(1.0, 0, 0.8), "s": 0.55},
					{"rel": "props/storage_barrel/storage_barrel_%s_lod2.glb", "pos": Vector3(-1.1, 0, 5.5), "s": 0.45},
				],
				"seat": Vector3(0, 0.95, 0.4),
				"crew_seat": Vector3(-1.35, 0.95, 1.7),
				"hatch": Vector3(0, 1.1, 7.2),
			}


static func all_ids() -> PackedStringArray:
	return PackedStringArray(["scout_single", "sniper_gunnery", "hauler_cargo"])
