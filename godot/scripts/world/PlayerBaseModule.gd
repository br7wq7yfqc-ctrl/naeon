extends Node3D
class_name PlayerBaseModule
## ST-A: one player-placed habitat on an unnamed pad.
## Cosmetic + soft morale only (rules/22). Zero combat stats. Not SITE_*.

const _Prop := preload("res://scripts/assets/GlbProp.gd")

const HAB_SIZE := Vector3(10.0, 5.0, 8.0)

var faction: String = "Cybernex"


func setup(fac: String) -> void:
	_bind(fac, false)


func setup_npc(fac: String) -> void:
	## NP-C: same habitat, not the player's ST-A slot, not SITE_*.
	_bind(fac, true)


func setup_printed(fac: String, kind: String) -> void:
	## ST-C: catalog grant after Contribution/Biomass spend. Not ST-A/NP-C slots.
	var k := kind if kind == "habitat" or kind == "extractor" else "extractor"
	faction = fac if fac != "" else "Cybernex"
	name = "PrintedHabitat" if k == "habitat" else "PrintedExtractor"
	set_meta("player_module", false)
	set_meta("npc_module", false)
	set_meta("printed_module", true)
	set_meta("module_type", k)
	set_meta("site_pin", "")
	set_meta("combat_stats", 0)
	if k == "extractor":
		set_meta("ledger_slug", "t1_resource_extractor")
	add_to_group("printed_base_modules")
	_spawn_printed(k)


func _bind(fac: String, by_npc: bool) -> void:
	faction = fac if fac != "" else "Cybernex"
	name = "NpcHabitat" if by_npc else "PlayerHabitat"
	set_meta("player_module", not by_npc)
	set_meta("npc_module", by_npc)
	set_meta("module_type", "habitat")
	set_meta("site_pin", "")
	set_meta("combat_stats", 0)
	add_to_group("npc_base_modules" if by_npc else "player_base_modules")
	_spawn_marker()
	_spawn_mesh()


func module_type() -> String:
	return str(get_meta("module_type", "habitat"))


func combat_stats() -> int:
	return 0


func _spawn_marker() -> void:
	var n := Node3D.new()
	n.name = "Habitat"
	n.set_meta("site_pin", "")
	n.set_meta("outpost_part", "npc_habitat" if bool(get_meta("npc_module", false)) else "player_habitat")
	add_child(n)


func _spawn_mesh() -> void:
	## Catalog habitat GLB when present; GlbProp already proxies on headless.
	var n: Node3D = get_node_or_null("Habitat") as Node3D
	if n == null:
		return
	var fx := "cybernex" if faction != "gROT" else "grot"
	var prop := Node3D.new()
	prop.set_script(_Prop)
	prop.set("relative_path", "colony/colony_habitat/colony_habitat_%s_lod1.glb" % fx)
	prop.set("scale_factor", 2.2)
	prop.set("add_static_collision", true)
	prop.name = "HabitatMesh"
	n.add_child(prop)


func _spawn_printed(kind: String) -> void:
	var marker := Node3D.new()
	marker.name = "Habitat" if kind == "habitat" else "Extractor"
	marker.set_meta("site_pin", "")
	marker.set_meta("outpost_part", "printed_%s" % kind)
	add_child(marker)
	var fx := "cybernex" if faction != "gROT" else "grot"
	var prop := Node3D.new()
	prop.set_script(_Prop)
	if kind == "habitat":
		prop.set("relative_path", "colony/colony_habitat/colony_habitat_%s_lod1.glb" % fx)
		prop.set("scale_factor", 2.2)
	else:
		prop.set("relative_path", "colony/extractor_unit/extractor_unit_%s_lod1.glb" % fx)
		prop.set("scale_factor", 1.4)
	prop.set("add_static_collision", true)
	prop.name = "PrintedMesh"
	marker.add_child(prop)
