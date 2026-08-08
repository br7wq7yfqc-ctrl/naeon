extends Node3D
class_name PadDensity
## Fills a landing pad / base footprint with dual-theme props + soft flood lights.

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
	"props/pad_control_obelisk/pad_control_obelisk_cybernex_lod1.glb",
	"props/ownership_claim_pylon/ownership_claim_pylon_cybernex_lod1.glb",
	"colony/grot_biomass_spire/grot_biomass_spire_cybernex_lod2.glb",
	"props/energy_barrier/energy_barrier_cybernex_lod2.glb",
	"props/nex_relay/nex_relay_cybernex_lod2.glb",
	"props/med_station/med_station_cybernex_lod1.glb",
	"environments/walkway_segment/walkway_segment_cybernex_lod2.glb",
	"environments/gate_arch/gate_arch_cybernex_lod1.glb",
	"colony/station_habitat_ring/station_habitat_ring_cybernex_lod1.glb",
	"props/pad_floodlight/pad_floodlight_cybernex_lod2.glb",
	"props/cybernex_shield_emitter/cybernex_shield_emitter_cybernex_lod1.glb",
	"props/cargo_landing_container/cargo_landing_container_cybernex_lod2.glb",
	"props/pad_refuel_pump/pad_refuel_pump_cybernex_lod2.glb",
	"colony/surface_crystal_spire/surface_crystal_spire_cybernex_lod2.glb",
	"environments/surface_rock_cluster/surface_rock_cluster_cybernex_lod2.glb",
]

func build(faction: String = "Cybernex", radius: float = 28.0, count: int = 18) -> void:
	var prop_script: Script = load("res://scripts/assets/GlbProp.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 40401
	var fx := "grot" if faction == "gROT" else "cybernex"
	var neon := Color(0.95, 0.2, 0.4) if faction == "gROT" else Color(0.25, 0.75, 1.0)
	var gq := get_node_or_null("/root/GraphicsQuality")
	var light_budget := 6
	if gq:
		match int(gq.tier):
			0:
				count = mini(count, 6)
				light_budget = 1
			1:
				count = mini(count, 10)
				light_budget = 3
			2:
				count = mini(count, 14)
				light_budget = 5
			_:
				light_budget = 8
	var lights_spawned := 0
	for i in count:
		var rel: String = PROPS[i % PROPS.size()]
		rel = rel.replace("_cybernex_", "_%s_" % fx)
		var ang := TAU * float(i) / float(count) + rng.randf() * 0.12
		var r := radius * (0.35 + 0.55 * rng.randf())
		var p: Node3D = Node3D.new()
		p.set_script(prop_script)
		if gq and int(gq.tier) <= 1:
			rel = rel.replace("_lod1.", "_lod2.").replace("_lod0.", "_lod2.")
		p.set("relative_path", rel)
		var is_station := "station_habitat" in rel
		var is_flood := "floodlight" in rel
		var is_spire := "crystal_spire" in rel
		p.set("scale_factor", 1.6 if is_station else (1.2 if is_flood else (1.35 if is_spire else rng.randf_range(0.75, 1.3))))
		p.set("add_static_collision", false)
		add_child(p)
		p.position = Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		p.rotation.y = rng.randf() * TAU
		# Soft flood / crystal lights — hard budget (omni = FPS tax)
		if lights_spawned < light_budget and (is_flood or is_spire or i % 7 == 0):
			var o := OmniLight3D.new()
			o.light_color = neon if is_spire else Color(1.0, 0.92, 0.75)
			o.light_energy = 1.4 if is_flood else 0.9
			o.omni_range = 14.0 if is_flood else 9.0
			o.omni_attenuation = 1.6
			o.shadow_enabled = false
			o.position = Vector3(0, 4.5 if is_flood else 2.2, 0)
			p.add_child(o)
			lights_spawned += 1
	var core: Node3D = Node3D.new()
	core.set_script(prop_script)
	core.set("relative_path", "props/claim_beacon/claim_beacon_%s_lod1.glb" % fx)
	core.set("scale_factor", 1.5)
	core.set("add_static_collision", false)
	add_child(core)
	if lights_spawned < light_budget:
		var core_l := OmniLight3D.new()
		core_l.light_color = neon
		core_l.light_energy = 1.6
		core_l.omni_range = 12.0
		core_l.shadow_enabled = false
		core_l.position = Vector3(0, 3.0, 0)
		core.add_child(core_l)
	print("[PadDensity] props=", count, " faction=", faction, " lights=", lights_spawned)
