extends Node3D
class_name PlayerBaseModule
## ST-A: one player-placed habitat on an unnamed pad.
## Cosmetic + soft morale only (rules/22). Zero combat stats. Not SITE_*.

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
	if DisplayServer.get_name() != "headless":
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
	var n: Node3D = get_node_or_null("Habitat") as Node3D
	if n == null:
		return
	var col := Color(0.95, 0.18, 0.38) if faction == "gROT" else Color(0.28, 0.88, 1.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col.darkened(0.12)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.5
	var hall := BoxMesh.new()
	hall.size = HAB_SIZE
	var mi := MeshInstance3D.new()
	mi.name = "HabitatMesh"
	mi.mesh = hall
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	n.add_child(mi)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = HAB_SIZE
	cs.shape = box
	body.add_child(cs)
	n.add_child(body)
