extends Node3D
class_name CatalogCarrier
## ST-D §6(b) / §7: one catalog carrier hull. Hangar queue lives here.
## IN-A: I enters InteriorGenerator hangar_bay pocket (not a mobile SITE_*).
## IN-C: HangarBay + CargoHold data + CargoRamp V0/V1. No rover. Not a mobile SITE_*.
## No new hull UUID.

const DEFAULT_HULL := "cybernex_capital_carrier"
const HULL_CX_CARRIER := "cybernex_capital_carrier"
const HULL_GR_CARRIER := "grot_capital_carrier"
const HULL_GR_DRONE := "grot_drone_carrier"
const HULL_CX_MOTHER := "cybernex_mothership"
const HULL_GR_MOTHER := "grot_mothership"

## Tight hull budget so a catalog ShipModule can exceed mass or power.
const HULL_MASS_CAP := 2.0
const HULL_POWER_CAP := 2.0

var hull_id: String = DEFAULT_HULL
var mass_cap: float = HULL_MASS_CAP
var power_cap: float = HULL_POWER_CAP
var _role = null
var _queue: Node = null
var _hold: Node = null
var _bay: Node3D = null
var _ramp: Node3D = null
var _landed: bool = false
var _docked: bool = false
var _speed: float = 0.0
var _pad: Node3D = null
var _home_pos: Vector3 = Vector3.ZERO
var _home_basis: Basis = Basis.IDENTITY
var _home_ok: bool = false


func _ready() -> void:
	set_meta("site_pin", "")
	set_meta("catalog_carrier", true)
	set_meta("mobile_site", false)
	if not is_in_group("catalog_carriers"):
		add_to_group("catalog_carriers")
	if hull_id == "":
		setup(DEFAULT_HULL)


func setup(slug: String = DEFAULT_HULL) -> void:
	var s := slug.strip_edges()
	var Role = load("res://scripts/ship/ShipRoleProfile.gd")
	hull_id = s if is_catalog_hull(s) else DEFAULT_HULL
	name = "CatalogCarrier"
	set_meta("site_pin", "")
	set_meta("catalog_hull", hull_id)
	set_meta("mobile_site", false)
	mass_cap = HULL_MASS_CAP
	power_cap = HULL_POWER_CAP
	if Role != null and Role.has_method("make_carrier"):
		_role = Role.make_carrier(hull_id)
	_ensure_hangar_queue()
	_ensure_hangar_systems()
	_ensure_proxy()
	if not _home_ok:
		_home_pos = global_position
		_home_basis = global_transform.basis
		_home_ok = true
	print("[CatalogCarrier] hull=", hull_id, " hangar=1 mass_cap=", mass_cap, " power_cap=", power_cap, " site_pin=")


static func is_catalog_hull(slug: String) -> bool:
	match slug:
		HULL_CX_CARRIER, HULL_GR_CARRIER, HULL_GR_DRONE, HULL_CX_MOTHER, HULL_GR_MOTHER:
			return true
		_:
			return false


func hangar_queue() -> Node:
	if _queue != null and is_instance_valid(_queue):
		return _queue
	return get_node_or_null("CarrierHangarQueue")


func hangar_bay() -> Node:
	if _bay != null and is_instance_valid(_bay):
		return _bay
	return get_node_or_null("HangarBay")


func cargo_hold() -> Node:
	if _hold != null and is_instance_valid(_hold):
		return _hold
	return get_node_or_null("CargoHold")


func cargo_ramp() -> Node:
	if _ramp != null and is_instance_valid(_ramp):
		return _ramp
	var bay: Node = hangar_bay()
	if bay != null:
		var r: Node = bay.get_node_or_null("CargoRamp")
		if r != null:
			return r
	return find_child("CargoRamp", true, false)


func is_landed() -> bool:
	return _landed


func is_docked() -> bool:
	return _docked


func hull_speed() -> float:
	return _speed


func altitude_agl() -> float:
	var pl: Node = _planet()
	if pl != null and pl.has_method("altitude_of"):
		return float(pl.altitude_of(global_position))
	if _pad != null and is_instance_valid(_pad):
		return global_position.distance_to(_pad.global_position)
	return 9999.0


func try_deploy_ramp() -> String:
	var ramp: Node = cargo_ramp()
	if ramp == null:
		return "BLOCKED"
	if _landed and _pad != null and is_instance_valid(_pad) and ramp.has_method("layout_to_deck"):
		var up := _up_at(_pad)
		ramp.layout_to_deck(_pad.global_position + up * 0.15)
	if ramp.has_method("try_deploy"):
		return str(ramp.try_deploy())
	return "BLOCKED"


func set_pose_landed(pad: Node3D) -> void:
	if pad == null or not is_instance_valid(pad):
		return
	_remember_home()
	_landed = true
	_docked = false
	_speed = 0.0
	_pad = pad
	var up := _up_at(pad)
	var along := _along_on_pad(up)
	global_transform.basis = _basis_from_up_along(up, along)
	global_position = pad.global_position + up * 4.2 - along * 10.4
	var ramp: Node = cargo_ramp()
	if ramp != null and ramp.has_method("layout_to_deck"):
		ramp.layout_to_deck(pad.global_position + up * 0.15)
	print("[CatalogCarrier] pose landed AGL=", snapped(altitude_agl(), 0.1), " speed=", _speed)


func set_pose_hover(agl_m: float, speed: float, pad: Node3D = null) -> void:
	_remember_home()
	_landed = false
	_docked = false
	_speed = maxf(0.0, speed)
	if pad != null and is_instance_valid(pad):
		_pad = pad
	var up := _up_at(_pad) if _pad != null else _up_at(self)
	var along := _along_on_pad(up)
	var origin: Vector3 = global_position
	if _pad != null and is_instance_valid(_pad):
		origin = _pad.global_position
	global_transform.basis = _basis_from_up_along(up, along)
	global_position = origin + up * maxf(1.0, agl_m)
	print("[CatalogCarrier] pose hover AGL=", snapped(altitude_agl(), 0.1), " speed=", _speed)


func set_pose_docked(dock: Node3D) -> void:
	if dock == null or not is_instance_valid(dock):
		return
	_remember_home()
	_landed = false
	_docked = true
	_speed = 0.0
	global_position = dock.global_position
	print("[CatalogCarrier] pose docked speed=", _speed)


func set_pose_flight(agl_m: float, speed: float, pad: Node3D = null) -> void:
	set_pose_hover(agl_m, speed, pad)
	_landed = false
	_docked = false
	print("[CatalogCarrier] pose flight AGL=", snapped(altitude_agl(), 0.1), " speed=", _speed)


func restore_orbit_pose() -> void:
	_landed = false
	_docked = false
	_speed = 0.0
	_pad = null
	if _home_ok:
		global_transform.basis = _home_basis
		global_position = _home_pos
	var ramp: Node = cargo_ramp()
	if ramp != null and ramp.has_method("stow_immediate"):
		ramp.stow_immediate()


func hangar_slots() -> int:
	if _role != null and "hangar_slots" in _role:
		return int(_role.hangar_slots)
	return 1


func hull_slug() -> String:
	return hull_id


func mass_remaining() -> float:
	var q := hangar_queue()
	var used := 0.0
	if q != null and q.has_method("queued_mass"):
		used = float(q.queued_mass())
	return maxf(0.0, mass_cap - used)


func power_remaining() -> float:
	var q := hangar_queue()
	var used := 0.0
	if q != null and q.has_method("queued_power"):
		used = float(q.queued_power())
	return maxf(0.0, power_cap - used)


func _ensure_hangar_queue() -> void:
	var q: Node3D = null
	if get_node_or_null("CarrierHangarQueue") != null:
		_queue = get_node_or_null("CarrierHangarQueue")
		return
	q = Node3D.new()
	q.set_script(preload("res://scripts/world/CarrierHangarQueue.gd"))
	q.name = "CarrierHangarQueue"
	q.set_meta("site_pin", "")
	add_child(q)
	_queue = q


func _ensure_hangar_systems() -> void:
	## V0: CargoHold + HangarBay data. V1: CargoRamp plates. No GroundVehicle.
	if get_node_or_null("CargoHold") == null:
		_hold = Node.new()
		_hold.set_script(preload("res://scripts/ship/CargoHold.gd"))
		_hold.name = "CargoHold"
		if _role != null:
			_hold.set("volume_m3", float(_role.cargo_volume_m3))
			_hold.set("mass_t", float(_role.cargo_mass_t))
			_hold.set("max_vehicle_slots", int(_role.hangar_slots))
		add_child(_hold)
	else:
		_hold = get_node_or_null("CargoHold")
	if get_node_or_null("HangarBay") == null:
		_bay = Node3D.new()
		_bay.set_script(preload("res://scripts/world/HangarBay.gd"))
		_bay.name = "HangarBay"
		_bay.position = Vector3(0.0, -0.55, 10.4)
		_bay.set_meta("site_pin", "")
		add_child(_bay)
	else:
		_bay = get_node_or_null("HangarBay") as Node3D
	if _bay != null and _bay.get_node_or_null("CargoRamp") == null:
		_ramp = Node3D.new()
		_ramp.set_script(preload("res://scripts/ship/CargoRamp.gd"))
		_ramp.name = "CargoRamp"
		_ramp.set("deploy_sec", 0.35)
		_ramp.set("ramp_length", 8.0)
		_ramp.set("ramp_width", 4.2)
		_bay.add_child(_ramp)
	elif _bay != null:
		_ramp = _bay.get_node_or_null("CargoRamp") as Node3D


func _remember_home() -> void:
	if _home_ok:
		return
	_home_pos = global_position
	_home_basis = global_transform.basis
	_home_ok = true


func _planet() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.has_method("nearest_planet"):
			var pl: Node = n.nearest_planet(global_position)
			if pl != null:
				return pl
		n = n.get_parent()
	var tree := get_tree()
	if tree == null:
		return null
	for p in tree.get_nodes_in_group("planets"):
		if p is Node3D:
			return p
	return null


func _up_at(host: Node3D) -> Vector3:
	if host != null and host.has_meta("pad_up"):
		var raw: Vector3 = host.get_meta("pad_up")
		if raw.length_squared() > 0.01:
			return raw.normalized()
	var pl: Node = _planet()
	if pl is Node3D:
		var up: Vector3 = (host.global_position if host != null else global_position) - (pl as Node3D).global_position
		if up.length_squared() > 0.01:
			return up.normalized()
	return Vector3.UP


func _along_on_pad(up: Vector3) -> Vector3:
	var along: Vector3 = Vector3.FORWARD - up * Vector3.FORWARD.dot(up)
	if along.length_squared() < 0.01:
		along = Vector3.RIGHT - up * Vector3.RIGHT.dot(up)
	if along.length_squared() < 0.01:
		along = up.cross(Vector3.RIGHT)
	return along.normalized()


func _basis_from_up_along(up: Vector3, along: Vector3) -> Basis:
	var nup := up.normalized()
	var nalong := along.normalized()
	var x := nalong.cross(nup)
	if x.length_squared() < 0.01:
		x = nup.cross(Vector3.FORWARD)
	x = x.normalized()
	nalong = nup.cross(x).normalized()
	return Basis(x, nup, nalong)


func _ensure_proxy() -> void:
	var col := Color(0.45, 0.72, 1.0)
	var mat: StandardMaterial3D = null
	var hull: MeshInstance3D = null
	var box: BoxMesh = null
	var lab: Label3D = null
	if get_node_or_null("HullProxy") != null:
		return
	mat = StandardMaterial3D.new()
	mat.albedo_color = col * 0.35
	mat.metallic = 0.55
	mat.roughness = 0.38
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.85
	hull = MeshInstance3D.new()
	hull.name = "HullProxy"
	box = BoxMesh.new()
	box.size = Vector3(9.0, 1.6, 22.0)
	hull.mesh = box
	hull.material_override = mat
	hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(hull)
	lab = Label3D.new()
	lab.name = "HullLabel"
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 18
	lab.outline_size = 4
	lab.position = Vector3(0, 3.2, 0)
	lab.text = "%s\nhangar · mass %.1f / power %.1f" % [hull_id, mass_cap, power_cap]
	add_child(lab)
