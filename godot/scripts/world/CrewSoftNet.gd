extends Node3D
class_name CrewSoftNet
## MC-A visual: second local viewer sees a puppet in the ship crew seat.
## SoftNet pose only — same bind_visual_puppet path as IN-F / AR-F.
## Host keeps hull / combat authority. No second physical hull. No passenger combat.

const VIEWER_NAME := "CrewSoftViewer"
const PUPPET_NAME := "CrewSeatPuppet"
const ENGINEER_PUPPET := "EngineerSeatPuppet"
const OPS_PUPPET := "OpsCrewSeatPuppet"

var _director: Node = null
var _viewer: Node3D = null
var _puppet: Node3D = null
var _eng_puppet: Node3D = null
var _ops_puppet: Node3D = null
var _pose: Dictionary = {}


func _ready() -> void:
	name = "CrewSoftNet"
	set_meta("site_pin", "")
	set_meta("mobile_site", false)
	set_meta("softnet_visual", true)
	set_meta("combat_authority", "host")
	set_meta("passenger_combat", false)
	if not is_in_group("crew_softnet"):
		add_to_group("crew_softnet")
	_ensure_viewer()
	_ensure_puppet()
	_ensure_engineer_puppet()
	_ensure_ops_puppet()
	sync_from_host()


func bind_director(d: Node) -> void:
	if d == null or not is_instance_valid(d):
		return
	_director = d
	_ensure_viewer()
	_ensure_puppet()
	_ensure_engineer_puppet()
	_ensure_ops_puppet()
	sync_from_host()


func viewer() -> Node3D:
	_ensure_viewer()
	return _viewer if _viewer != null and is_instance_valid(_viewer) else null


func crew_puppet() -> Node3D:
	_ensure_puppet()
	return _puppet if _puppet != null and is_instance_valid(_puppet) else null


func engineer_puppet() -> Node3D:
	_ensure_engineer_puppet()
	return _eng_puppet if _eng_puppet != null and is_instance_valid(_eng_puppet) else null


func ops_puppet() -> Node3D:
	_ensure_ops_puppet()
	return _ops_puppet if _ops_puppet != null and is_instance_valid(_ops_puppet) else null


func hull_authority() -> String:
	return "host"


func combat_authority() -> String:
	return "host"


func is_host_authority() -> bool:
	return true


func has_passenger_combat() -> bool:
	return false


func has_second_hull() -> bool:
	return false


func puppet_in_seat() -> bool:
	var p := crew_puppet()
	return p != null and p.visible and bool(p.get_meta("softnet_visual", false))


func observed_pose() -> Dictionary:
	if _pose.is_empty():
		sync_from_host()
	return _pose.duplicate()


func sync_from_host() -> void:
	_ensure_viewer()
	_ensure_puppet()
	_ensure_engineer_puppet()
	_ensure_ops_puppet()
	var seat: Node3D = _crew_seat()
	var eng: Node3D = _engineer_seat()
	var ops: Node3D = _ops_seat()
	var host_in_gunner := false
	var host_in_engineer := false
	var host_in_ops := false
	if _director != null and is_instance_valid(_director):
		if _director.has_method("is_seated") and _director.has_method("get_seat_role"):
			var seated := bool(_director.is_seated()) and str(_director.get_seat_role()) == "crew"
			var named := ""
			if _director.has_method("boarded_station_role"):
				named = str(_director.boarded_station_role())
			host_in_gunner = seated and named != "engineer" and named != "ops"
			host_in_engineer = seated and named == "engineer"
			host_in_ops = seated and named == "ops"
	if _puppet != null and is_instance_valid(_puppet):
		if seat != null:
			_puppet.global_position = seat.global_position + Vector3(0.0, 1.05, 0.0)
		_puppet.visible = not host_in_gunner
	if _eng_puppet != null and is_instance_valid(_eng_puppet):
		if eng != null:
			_eng_puppet.global_position = eng.global_position + Vector3(0.0, 1.05, 0.0)
		_eng_puppet.visible = not host_in_engineer
	if _ops_puppet != null and is_instance_valid(_ops_puppet):
		if ops != null:
			_ops_puppet.global_position = ops.global_position + Vector3(0.0, 1.05, 0.0)
		_ops_puppet.visible = not host_in_ops
	_pose = {
		"seat_role": "crew",
		"station_role": "gunner",
		"engineer_role": "engineer",
		"ops_role": "ops",
		"puppet_in_seat": puppet_in_seat(),
		"authority": "host",
		"second_hull": false,
		"passenger_combat": false,
	}
	_bind_soft_visuals()


func _crew_seat() -> Node3D:
	var pocket: Node = get_parent()
	if pocket == null or not is_instance_valid(pocket):
		return null
	var n: Node = pocket.get_node_or_null("CrewSeat")
	if n is Node3D:
		return n as Node3D
	n = pocket.get_node_or_null("CrewSeatVolume")
	if n is Node3D:
		return n as Node3D
	return null


func _engineer_seat() -> Node3D:
	var pocket: Node = get_parent()
	if pocket == null or not is_instance_valid(pocket):
		return null
	var n: Node = pocket.get_node_or_null("EngineerSeat")
	if n is Node3D:
		return n as Node3D
	n = pocket.get_node_or_null("EngineerSeatVolume")
	if n is Node3D:
		return n as Node3D
	return null


func _ops_seat() -> Node3D:
	var pocket: Node = get_parent()
	if pocket == null or not is_instance_valid(pocket):
		return null
	var n: Node = pocket.get_node_or_null("OpsCrewSeat")
	if n is Node3D:
		return n as Node3D
	n = pocket.get_node_or_null("OpsCrewSeatVolume")
	if n is Node3D:
		return n as Node3D
	return null


func _ensure_viewer() -> void:
	if _viewer != null and is_instance_valid(_viewer):
		return
	var existing: Node = get_node_or_null(VIEWER_NAME)
	if existing is Node3D:
		_viewer = existing as Node3D
		_tag_visual(_viewer, "crew_soft_viewer")
		return
	_viewer = Node3D.new()
	_viewer.name = VIEWER_NAME
	_tag_visual(_viewer, "crew_soft_viewer")
	_viewer.set_meta("site_pin", "")
	add_child(_viewer)
	_viewer.position = Vector3(2.2, 1.4, 2.4)
	if DisplayServer.get_name() != "headless":
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.28
		cap.height = 1.05
		mi.mesh = cap
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.85, 1.0, 0.3)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.25, 0.7, 1.0)
		mat.emission_energy_multiplier = 0.9
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = mat
		mi.position = Vector3(0, 0.8, 0)
		_viewer.add_child(mi)
		var lab := Label3D.new()
		lab.text = "GUNNER VIEWER (soft net)"
		lab.font_size = 20
		lab.modulate = Color(0.7, 0.95, 1.0, 0.8)
		lab.position = Vector3(0, 1.9, 0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_viewer.add_child(lab)
	if SoftNetSession and SoftNetSession.has_method("bind_visual_puppet"):
		SoftNetSession.bind_visual_puppet(_viewer)


func _ensure_puppet() -> void:
	if _puppet != null and is_instance_valid(_puppet):
		return
	var existing: Node = get_node_or_null(PUPPET_NAME)
	if existing is Node3D:
		_puppet = existing as Node3D
		_tag_visual(_puppet, "crew_seat_puppet")
		return
	_puppet = Node3D.new()
	_puppet.name = PUPPET_NAME
	_tag_visual(_puppet, "crew_seat_puppet")
	_puppet.set_meta("site_pin", "")
	_puppet.set_meta("passenger_combat", false)
	add_child(_puppet)
	if DisplayServer.get_name() != "headless":
		var body := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.3
		cap.height = 1.1
		body.mesh = cap
		body.position.y = 0.85
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.75, 0.9, 0.28)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.6, 0.85)
		mat.emission_energy_multiplier = 0.85
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		body.material_override = mat
		_puppet.add_child(body)
		var lab := Label3D.new()
		lab.name = "PuppetLabel"
		lab.text = "GUNNER PUPPET (soft net)"
		lab.font_size = 18
		lab.modulate = Color(0.65, 0.95, 1.0, 0.75)
		lab.position = Vector3(0, 2.0, 0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_puppet.add_child(lab)
	if SoftNetSession and SoftNetSession.has_method("bind_visual_puppet"):
		SoftNetSession.bind_visual_puppet(_puppet)


func _ensure_engineer_puppet() -> void:
	if _eng_puppet != null and is_instance_valid(_eng_puppet):
		return
	var existing: Node = get_node_or_null(ENGINEER_PUPPET)
	if existing is Node3D:
		_eng_puppet = existing as Node3D
		_tag_visual(_eng_puppet, "engineer_seat_puppet")
		return
	_eng_puppet = Node3D.new()
	_eng_puppet.name = ENGINEER_PUPPET
	_tag_visual(_eng_puppet, "engineer_seat_puppet")
	_eng_puppet.set_meta("site_pin", "")
	_eng_puppet.set_meta("passenger_combat", false)
	add_child(_eng_puppet)
	if DisplayServer.get_name() != "headless":
		var body := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.3
		cap.height = 1.1
		body.mesh = cap
		body.position.y = 0.85
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.9, 0.55, 0.28)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.25, 0.8, 0.4)
		mat.emission_energy_multiplier = 0.85
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		body.material_override = mat
		_eng_puppet.add_child(body)
		var lab := Label3D.new()
		lab.name = "PuppetLabel"
		lab.text = "ENGINEER PUPPET (soft net)"
		lab.font_size = 18
		lab.modulate = Color(0.7, 1.0, 0.75, 0.75)
		lab.position = Vector3(0, 2.0, 0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_eng_puppet.add_child(lab)
	if SoftNetSession and SoftNetSession.has_method("bind_visual_puppet"):
		SoftNetSession.bind_visual_puppet(_eng_puppet)


func _ensure_ops_puppet() -> void:
	if _ops_puppet != null and is_instance_valid(_ops_puppet):
		return
	var existing: Node = get_node_or_null(OPS_PUPPET)
	if existing is Node3D:
		_ops_puppet = existing as Node3D
		_tag_visual(_ops_puppet, "ops_crew_seat_puppet")
		return
	_ops_puppet = Node3D.new()
	_ops_puppet.name = OPS_PUPPET
	_tag_visual(_ops_puppet, "ops_crew_seat_puppet")
	_ops_puppet.set_meta("site_pin", "")
	_ops_puppet.set_meta("passenger_combat", false)
	add_child(_ops_puppet)
	if DisplayServer.get_name() != "headless":
		var body := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.3
		cap.height = 1.1
		body.mesh = cap
		body.position.y = 0.85
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.55, 0.95, 0.28)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.35, 0.4, 0.9)
		mat.emission_energy_multiplier = 0.85
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		body.material_override = mat
		_ops_puppet.add_child(body)
		var lab := Label3D.new()
		lab.name = "PuppetLabel"
		lab.text = "OPS PUPPET (soft net)"
		lab.font_size = 18
		lab.modulate = Color(0.75, 0.8, 1.0, 0.75)
		lab.position = Vector3(0, 2.0, 0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_ops_puppet.add_child(lab)
	if SoftNetSession and SoftNetSession.has_method("bind_visual_puppet"):
		SoftNetSession.bind_visual_puppet(_ops_puppet)


func _tag_visual(n: Node3D, kind: String) -> void:
	n.set_meta("softnet_visual", true)
	n.set_meta("combat_authority", "host")
	n.set_meta("passenger_combat", false)
	n.set_meta(kind, true)
	if not n.is_in_group(kind):
		n.add_to_group(kind)


func _bind_soft_visuals() -> void:
	if SoftNetSession == null:
		return
	if SoftNetSession.has_method("bind_visual_puppet"):
		if _viewer != null and is_instance_valid(_viewer):
			SoftNetSession.bind_visual_puppet(_viewer)
		if _puppet != null and is_instance_valid(_puppet) and _puppet.visible:
			SoftNetSession.bind_visual_puppet(_puppet)
		if _eng_puppet != null and is_instance_valid(_eng_puppet) and _eng_puppet.visible:
			SoftNetSession.bind_visual_puppet(_eng_puppet)
		if _ops_puppet != null and is_instance_valid(_ops_puppet) and _ops_puppet.visible:
			SoftNetSession.bind_visual_puppet(_ops_puppet)
