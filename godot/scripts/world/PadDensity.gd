extends Node3D
class_name PadDensity
## Fills a landing pad / base footprint with existing dual-theme props (0 Tripo).

const PROPS := [
	"colony/colony_habitat/colony_habitat_cybernex_lod1.glb",
	"colony/solar_panel/solar_panel_cybernex_lod2.glb",
	"colony/fuel_tank/fuel_tank_cybernex_lod2.glb",
	"colony/extractor_unit/extractor_unit_cybernex_lod1.glb",
	"props/antenna_array/antenna_array_cybernex_lod2.glb",
	"props/control_console/control_console_cybernex_lod1.glb",
	"props/sci_fi_crate/sci_fi_crate_cybernex_lod2.glb",
	"props/storage_barrel/storage_barrel_cybernex_lod2.glb",
	"props/claim_beacon/claim_beacon_cybernex_lod1.glb",
	"props/energy_barrier/energy_barrier_cybernex_lod2.glb",
	"props/nex_relay/nex_relay_cybernex_lod2.glb",
	"props/med_station/med_station_cybernex_lod1.glb",
	"environments/walkway_segment/walkway_segment_cybernex_lod2.glb",
	"environments/gate_arch/gate_arch_cybernex_lod1.glb",
	"colony/station_habitat_ring/station_habitat_ring_cybernex_lod1.glb",
	"props/pad_floodlight/pad_floodlight_cybernex_lod2.glb",
	"colony/surface_crystal_spire/surface_crystal_spire_cybernex_lod2.glb",
]

func build(faction: String = "Cybernex", radius: float = 28.0, count: int = 16) -> void:
	var prop_script: Script = load("res://scripts/assets/GlbProp.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 40401
	var fx := "grot" if faction == "gROT" else "cybernex"
	for i in count:
		var rel: String = PROPS[i % PROPS.size()]
		rel = rel.replace("_cybernex_", "_%s_" % fx)
		var ang := TAU * float(i) / float(count) + rng.randf() * 0.15
		var r := radius * (0.35 + 0.55 * rng.randf())
		var p: Node3D = Node3D.new()
		p.set_script(prop_script)
		p.set("relative_path", rel)
		p.set("scale_factor", rng.randf_range(0.7, 1.35))
		p.set("add_static_collision", false)  # visual density only — avoid walker embed
		add_child(p)
		p.position = Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		p.rotation.y = rng.randf() * TAU
	# central beacon
	var core: Node3D = Node3D.new()
	core.set_script(prop_script)
	core.set("relative_path", "props/claim_beacon/claim_beacon_%s_lod1.glb" % fx)
	core.set("scale_factor", 1.4)
	core.set("add_static_collision", false)
	add_child(core)
	print("[PadDensity] props=", count, " faction=", faction)
