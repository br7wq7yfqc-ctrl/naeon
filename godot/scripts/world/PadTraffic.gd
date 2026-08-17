extends Node3D
## SC pillar 13: one pad-guard dummy + one visiting hull hold on a loaded pad.
## Code-first proxy. Not galaxy traffic. Knowledge labels only — never DPS.

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
const _DUMMY := preload("res://scenes/combat/CombatDummy.tscn")

var _host_name: String = ""
var _guard: Node3D = null
var _visitor: Node3D = null
var _visitor_base: Vector3 = Vector3(16.0, 6.5, -12.0)
var _life_accum: float = 0.0


func setup(host_pad: Node3D) -> void:
	if host_pad != null:
		_host_name = str(host_pad.name)
	set_meta("site_pin", "")
	set_meta("pad_traffic", true)
	add_to_group("pad_traffic")
	_spawn_guard()
	_spawn_visitor()
	refresh_labels()
	set_process(true)
	print("[PadTraffic] host=", _host_name, " guard=1 visitor=1")


func host_pad_name() -> String:
	return _host_name


func get_guard() -> Node3D:
	if _guard != null and is_instance_valid(_guard):
		return _guard
	return null


func get_visitor() -> Node3D:
	if _visitor != null and is_instance_valid(_visitor):
		return _visitor
	return null


func actor_count() -> int:
	var n := 0
	if get_guard() != null:
		n += 1
	if get_visitor() != null:
		n += 1
	return n


func guard_label() -> String:
	return _SoftK.traffic_label("guard")


func visitor_label() -> String:
	return _SoftK.traffic_label("visitor")


func refresh_labels() -> void:
	var gname := guard_label()
	if _guard != null and is_instance_valid(_guard):
		_guard.set("intel_name", gname)
		if _guard.has_method("_update_labels"):
			_guard._update_labels()
	var vname := visitor_label()
	if _visitor != null and is_instance_valid(_visitor):
		var lab: Label3D = _visitor.get_node_or_null("Label") as Label3D
		if lab:
			lab.text = vname


func _spawn_guard() -> void:
	if _DUMMY == null:
		return
	var d: Node = _DUMMY.instantiate()
	d.name = "PadGuardDummy"
	d.set("faction", _host_faction())
	d.set("can_move", false)
	d.set("aggro_range", 0.0)
	d.set("attack_range", 0.0)
	d.set("grant_economy", false)
	d.set("intel_name", guard_label())
	d.set_meta("pad_traffic_role", "guard")
	d.set_meta("site_pin", "")
	add_child(d)
	if d is Node3D:
		(d as Node3D).position = Vector3(-8.0, 1.2, 8.0)
		d.set("_spawn_pos", (d as Node3D).global_position)
		_guard = d as Node3D


func _spawn_visitor() -> void:
	var v := Node3D.new()
	v.name = "VisitorHold"
	v.set_meta("pad_traffic_role", "visitor")
	v.set_meta("site_pin", "")
	v.position = _visitor_base
	add_child(v)
	_visitor = v
	_add_marker(v, "Hull")
	if DisplayServer.get_name() == "headless":
		return
	_build_visitor_hull(v)
	var lab := Label3D.new()
	lab.name = "Label"
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 22
	lab.outline_size = 5
	lab.position = Vector3(0, 2.4, 0)
	lab.text = visitor_label()
	lab.modulate = Color(0.75, 0.9, 1.0)
	v.add_child(lab)


func _add_marker(host: Node3D, id: String) -> void:
	var n := Node3D.new()
	n.name = id
	n.set_meta("site_pin", "")
	n.set_meta("pad_traffic_part", id.to_lower())
	host.add_child(n)


func _build_visitor_hull(v: Node3D) -> void:
	var col := Color(0.28, 0.82, 1.0)
	if _host_faction() == "gROT":
		col = Color(0.95, 0.2, 0.4)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.6
	_box(v, "Body", Vector3(2.4, 0.9, 5.2), Vector3.ZERO, mat)
	_box(v, "Wing", Vector3(5.4, 0.16, 1.6), Vector3(0, -0.1, 0.4), mat)
	_box(v, "Nacelle", Vector3(0.7, 0.45, 2.2), Vector3(0, 0.55, 1.1), mat)


func _box(host: Node3D, id: String, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = id + "Mesh"
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.position = pos
	host.add_child(mi)


func _host_faction() -> String:
	var host := get_parent()
	var planet: Node = null
	if host != null and host.has_meta("planet"):
		planet = host.get_meta("planet")
	if planet != null and "faction_base" in planet:
		return str(planet.faction_base)
	return "Cybernex"


func _process(delta: float) -> void:
	_life_accum += delta
	if _life_accum < 0.2:
		return
	_life_accum = 0.0
	if _visitor == null or not is_instance_valid(_visitor):
		return
	var t := Time.get_ticks_msec() * 0.001
	_visitor.position = _visitor_base + Vector3(0.0, sin(t * 0.9) * 0.35, 0.0)
	_visitor.rotation.y = t * 0.08
