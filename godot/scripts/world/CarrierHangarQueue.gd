extends Node3D
class_name CarrierHangarQueue
## ST-D §6(b) / §7: hangar queue of ONE module on a catalog carrier.
## Blocked by hull mass / power (ShipModule.mass, power_draw). Not a SITE_*.
## Interiors later. Does not rewrite the ST-C pad print bench.

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
const DEFAULT_KIND := "sensor"
const SLOT_COUNT := 1

var _queued: Node3D = null
var _last_refuse: String = ""


func _ready() -> void:
	name = "CarrierHangarQueue"
	set_meta("site_pin", "")
	set_meta("hangar_queue", true)
	if not is_in_group("hangar_queues"):
		add_to_group("hangar_queues")
	_ensure_proxy()
	print("[CarrierHangarQueue] hangar seed on ", _hull_slug(), " slots=", SLOT_COUNT, " cash_skip=false")


func slot_count() -> int:
	return SLOT_COUNT


func last_refuse() -> String:
	return _last_refuse


func queued_module() -> Node3D:
	if _queued != null and is_instance_valid(_queued):
		return _queued
	return null


func queued_mass() -> float:
	var n := queued_module()
	if n == null:
		return 0.0
	return float(n.get_meta("mass", 0.0))


func queued_power() -> float:
	var n := queued_module()
	if n == null:
		return 0.0
	return float(n.get_meta("power_draw", 0.0))


func cash_shop_skip_possible() -> bool:
	return false


func try_cash_skip_queue(_cash: float = 0.0) -> bool:
	print("[CarrierHangarQueue] cash-shop skip refused")
	return false


func enqueue_module(kind: String = "", cash: float = 0.0) -> Node3D:
	## One hangar slot. Refuse if mass or power exceeds the catalog hull.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var k := ""
	var spec: ShipModule = null
	var mass := 0.0
	var power := 0.0
	var hull: Node = null
	var stub: Node3D = null
	var remain_m := 0.0
	var remain_p := 0.0
	_last_refuse = ""
	if P0 == null or not bool(P0.ST_D_HANGAR):
		return null
	if cash > 0.0:
		_last_refuse = "cash"
		print("[CarrierHangarQueue] cash-shop skip refused")
		return null
	if queued_module() != null:
		_last_refuse = "slot"
		print("[CarrierHangarQueue] one slot full")
		return null
	k = _kind(kind)
	spec = _spec_for(k)
	if spec == null:
		return null
	mass = spec.mass
	power = spec.power_draw
	hull = _hull()
	if hull != null and hull.has_method("mass_remaining"):
		remain_m = float(hull.mass_remaining())
	else:
		remain_m = 2.0
	if hull != null and hull.has_method("power_remaining"):
		remain_p = float(hull.power_remaining())
	else:
		remain_p = 2.0
	if mass > remain_m + 0.0001:
		_last_refuse = "mass"
		print("[CarrierHangarQueue] refuse mass ", snapped(mass, 0.01), " > remaining ", snapped(remain_m, 0.01), " hull=", _hull_slug())
		return null
	if power > remain_p + 0.0001:
		_last_refuse = "power"
		print("[CarrierHangarQueue] refuse power ", snapped(power, 0.01), " > remaining ", snapped(remain_p, 0.01), " hull=", _hull_slug())
		return null
	stub = _make_stub(k, spec)
	if stub == null:
		return null
	if str(stub.get_meta("site_pin", "x")) != "":
		push_error("[CarrierHangarQueue] queued module minted a site_pin")
		stub.queue_free()
		return null
	_queued = stub
	if GameManager:
		GameManager.toast_requested.emit(
			"Hangar queued %s — mass/power gate · no SITE_*" % k
		)
	print("[CarrierHangarQueue] queued ", k, " mass=", snapped(mass, 0.01), " power=", snapped(power, 0.01), " hull=", _hull_slug(), " slots=1")
	return stub


func _kind(kind: String) -> String:
	var k := kind.strip_edges().to_lower()
	if k == "sensor" or k == "extractor" or k == "engine" or k == "cargo":
		return k
	return DEFAULT_KIND


func _spec_for(kind: String) -> ShipModule:
	## Existing ShipModule factories only. No new hull / module UUID.
	match kind:
		"extractor":
			return ShipModule.make_extractor()
		"engine":
			return ShipModule.make_engine()
		"cargo":
			return ShipModule.make_cargo()
		_:
			return ShipModule.make_sensor()


func _make_stub(kind: String, spec: ShipModule) -> Node3D:
	var n := Node3D.new()
	n.name = "Queued%s" % kind.capitalize()
	n.set_meta("site_pin", "")
	n.set_meta("hangar_queued", true)
	n.set_meta("module_type", kind)
	n.set_meta("mass", spec.mass)
	n.set_meta("power_draw", spec.power_draw)
	n.set_meta("printed_module", false)
	n.set_meta("player_module", false)
	n.set_meta("npc_module", false)
	n.add_to_group("hangar_queued_modules")
	add_child(n)
	return n


func _hull() -> Node:
	var n: Node = get_parent()
	if n != null and n.has_method("hull_slug"):
		return n
	return n


func _hull_slug() -> String:
	var h := _hull()
	if h != null and h.has_method("hull_slug"):
		return str(h.hull_slug())
	if h != null:
		return str(h.get_meta("catalog_hull", ""))
	return ""


func _ensure_proxy() -> void:
	var col := Color(0.7, 0.85, 1.0)
	var mat: StandardMaterial3D = null
	var bay: MeshInstance3D = null
	var box: BoxMesh = null
	var lab: Label3D = null
	if get_node_or_null("Bay") != null:
		return
	mat = StandardMaterial3D.new()
	mat.albedo_color = col * 0.3
	mat.metallic = 0.4
	mat.roughness = 0.45
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.9
	bay = MeshInstance3D.new()
	bay.name = "Bay"
	box = BoxMesh.new()
	box.size = Vector3(3.2, 0.22, 4.0)
	bay.mesh = box
	bay.material_override = mat
	bay.position = Vector3(0, -0.4, 0)
	bay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bay)
	lab = Label3D.new()
	lab.name = "HangarLabel"
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 16
	lab.outline_size = 4
	lab.position = Vector3(0, 1.6, 0)
	lab.text = "%s\n1 slot · mass/power gate" % _SoftK.hangar_queue_label()
	add_child(lab)
