extends Node3D
class_name PadHangarStub
## ST-J: one pad hangar stub after occupy. Not ST-D CarrierHangarQueue.
## ST-K: same grammar on PlayerOrbitalStation (orbital_hangar_stub).
## Occupied unnamed pad (ST-J) or host orbital cluster (ST-K).
## Hatch/LAND stay legal (pad or dock). Knowledge labels only.
## No rover spawn. No SITE_*. Combat stats 0.

const _SoftK := preload("res://scripts/systems/SoftKnowledge.gd")

const BAY_SLOTS := 1

var faction: String = "Cybernex"
var _label: Label3D = null
var _hatch_dest: String = "pad"


func setup(fac: String) -> void:
	_bind_stub(fac, false)


func setup_orbital(fac: String) -> void:
	## ST-K: same stub on the player orbital cluster. Hatch → dock.
	_bind_stub(fac, true)


func _bind_stub(fac: String, orbital: bool) -> void:
	faction = fac if fac != "" else "Cybernex"
	_hatch_dest = "dock" if orbital else "pad"
	name = "OrbitalHangarStub" if orbital else "PadHangarStub"
	set_meta("site_pin", "")
	set_meta("module_type", "hangar_stub")
	set_meta("pad_hangar_stub", not orbital)
	set_meta("orbital_hangar_stub", orbital)
	set_meta("player_module", false)
	set_meta("npc_module", false)
	set_meta("printed_module", false)
	set_meta("carrier_hangar", false)
	set_meta("mobile_site", false)
	set_meta("hatch_exit", _hatch_dest)
	set_meta("combat_stats", 0)
	if orbital:
		if not is_in_group("orbital_hangar_stubs"):
			add_to_group("orbital_hangar_stubs")
	elif not is_in_group("pad_hangar_stubs"):
		add_to_group("pad_hangar_stubs")
	_spawn_marker()
	_spawn_mesh()
	_ensure_label()
	if orbital:
		print("[PadHangarStub] ST-K on orbital cluster fac=", faction, " slots=", BAY_SLOTS)
	else:
		print("[PadHangarStub] ST-J on pad fac=", faction, " slots=", BAY_SLOTS)


func module_type() -> String:
	return "hangar_stub"


func combat_stats() -> int:
	return 0


func is_carrier_hangar() -> bool:
	return false


func bay_slots() -> int:
	return BAY_SLOTS


func rover_spawned() -> bool:
	return false


func hatch_exit() -> String:
	return _hatch_dest


func hatch_returns_to_pad() -> bool:
	return _hatch_dest == "pad"


func hatch_returns_to_dock() -> bool:
	return _hatch_dest == "dock"


func scene_swap() -> bool:
	return false


func hangar_label() -> String:
	return _SoftK.hangar_stub_label()


func reload_for_faction(faction_name: String) -> void:
	## ST-F theme only. Does not change slots / hatch / combat.
	if faction_name == "" or faction_name == "Contested" or faction_name == "Neutral":
		return
	faction = faction_name
	var mesh: Node = get_node_or_null("Hangar/HangarMesh")
	if mesh is MeshInstance3D:
		var mat := (mesh as MeshInstance3D).get_active_material(0)
		if mat is StandardMaterial3D:
			(mat as StandardMaterial3D).albedo_color = _faction_color()
			(mat as StandardMaterial3D).emission = _faction_color()
	_refresh_label()


func _faction_color() -> Color:
	return Color(0.72, 0.22, 0.28) if faction == "gROT" else Color(0.18, 0.55, 0.72)


func _spawn_marker() -> void:
	var n := Node3D.new()
	n.name = "Hangar"
	n.set_meta("site_pin", "")
	n.set_meta("outpost_part", "orbital_hangar_stub" if _hatch_dest == "dock" else "pad_hangar_stub")
	n.set_meta("hatch_exit", _hatch_dest)
	add_child(n)
	var hatch := Node3D.new()
	hatch.name = "Hatch"
	hatch.set_meta("hatch_exit", _hatch_dest)
	hatch.set_meta("site_pin", "")
	n.add_child(hatch)


func _spawn_mesh() -> void:
	var n: Node3D = get_node_or_null("Hangar") as Node3D
	if n == null:
		return
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(8.0, 3.2, 10.0)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _faction_color()
	mat.emission_enabled = true
	mat.emission = _faction_color()
	mat.emission_energy_multiplier = 0.35
	mesh.material_override = mat
	mesh.name = "HangarMesh"
	mesh.position = Vector3(0.0, 1.6, 0.0)
	n.add_child(mesh)


func _ensure_label() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 20
	_label.position = Vector3(0, 3.6, 0)
	add_child(_label)
	_refresh_label()


func _refresh_label() -> void:
	if _label == null:
		return
	var dest := "DOCK" if _hatch_dest == "dock" else "PAD"
	_label.text = "%s %s\nHATCH → %s" % [hangar_label(), faction, dest]
