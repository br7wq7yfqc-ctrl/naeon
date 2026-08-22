extends Node3D
class_name PlayerBaseModule
## ST-A: one player-placed habitat on an unnamed pad.
## Cosmetic + soft morale only (rules/22). Zero combat stats. Not SITE_*.

const _Prop := preload("res://scripts/assets/GlbProp.gd")

const HAB_SIZE := Vector3(10.0, 5.0, 8.0)

var faction: String = "Cybernex"


func setup(fac: String) -> void:
	faction = fac if fac != "" else "Cybernex"
	name = "PlayerHabitat"
	set_meta("player_module", true)
	set_meta("module_type", "habitat")
	set_meta("site_pin", "")
	set_meta("combat_stats", 0)
	add_to_group("player_base_modules")
	_spawn_marker()
	_spawn_mesh()


func module_type() -> String:
	return "habitat"


func combat_stats() -> int:
	return 0


func _spawn_marker() -> void:
	var n := Node3D.new()
	n.name = "Habitat"
	n.set_meta("site_pin", "")
	n.set_meta("outpost_part", "player_habitat")
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
