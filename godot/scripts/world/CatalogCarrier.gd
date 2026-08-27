extends Node3D
class_name CatalogCarrier
## ST-D §6(b) / §7: one catalog carrier hull. Hangar queue lives here.
## Not a mobile SITE_*. Interiors later. No new hull UUID.

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
	_ensure_proxy()
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
