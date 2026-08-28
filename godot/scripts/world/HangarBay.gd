extends Node3D
class_name HangarBay
## Door + interior spawn on the ST-D catalog carrier. Data only.
## IN-D rover spawn lives on CatalogCarrier (ramp top). Not a SITE_*. Not a mobile pad.

const INTERIOR_KIND := "hangar_bay"
const MOUTH_LOCAL := Vector3(0.0, -0.55, 10.4)

var interior_kind: String = INTERIOR_KIND
var door_id: String = "hangar_mouth"


func _ready() -> void:
	name = "HangarBay"
	set_meta("site_pin", "")
	set_meta("interior_kind", INTERIOR_KIND)
	set_meta("hangar_bay", true)
	set_meta("mobile_site", false)
	if not is_in_group("hangar_bays"):
		add_to_group("hangar_bays")


func spawn_kind() -> String:
	return INTERIOR_KIND


func mouth_local() -> Vector3:
	return position if position.length_squared() > 0.01 else MOUTH_LOCAL


func mouth_global() -> Vector3:
	return global_position


func rover_spawn_global() -> Vector3:
	var ramp: Node = get_node_or_null("CargoRamp")
	if ramp != null and ramp.has_method("walk_mouth_global"):
		return ramp.walk_mouth_global()
	return global_position + Vector3(0.0, 0.8, 0.0)
