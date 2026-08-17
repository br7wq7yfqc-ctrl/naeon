extends Node3D
class_name ClashModuleBench
## AR-E: one module/blueprint bench on the existing TestArena footprint.
## Session item — not a shop of power, not cash-shop. Knowledge may label only.

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
const _ShipModule = preload("res://scripts/ship/ShipModule.gd")

## BOT-side pocket, same 60×60 floor. Opposite the AR-D camp (x=+7.2).
const BENCH_POS := Vector3(-7.2, 0.0, 10.5)
const INTERACT_RADIUS := 3.2
const EQUIP_COST := 0.0  ## session — Contribution or none, never cash

var _player_ref: Node3D = null
var _label: Label3D = null
var _mat: StandardMaterial3D = null
var _offer: ShipModule = null
var _equipped: ShipModule = null

func _ready() -> void:
	name = "ClashModuleBench"
	add_to_group("clash_module_bench")
	position = BENCH_POS
	_offer = _ShipModule.make_sensor("Nex Sensor")
	_build_proxy()
	_refresh_label()
	print("[ClashModuleBench] session bench at ", BENCH_POS, " offer=", offer_id(), " cost=", EQUIP_COST)


func bind_player(p: Node3D) -> void:
	_player_ref = p


func is_on_footprint() -> bool:
	return absf(global_position.x) <= 28.0 and absf(global_position.z) <= 28.0


func is_off_lane() -> bool:
	return absf(global_position.x) > 3.6 and absf(global_position.x - 14.0) > 3.6 \
		and absf(global_position.x + 14.0) > 3.6


func offer_kind() -> String:
	return "ship_module"


func cost_kind() -> String:
	return "session"


func equip_cost() -> float:
	return EQUIP_COST


func offer_id() -> String:
	return str(_offer.module_id) if _offer else ""


func offer_name() -> String:
	return str(_offer.display_name) if _offer else ""


func has_equipped() -> bool:
	return _equipped != null


func equipped_id() -> String:
	return str(_equipped.module_id) if _equipped else ""


func equipped_name() -> String:
	return str(_equipped.display_name) if _equipped else ""


func label_text() -> String:
	return _SoftK.module_bench_label()


func modifies_combat() -> bool:
	return false


func try_equip(player: Node = null) -> bool:
	var p: Node = player if player != null else _player_ref
	if p == null or not is_instance_valid(p) or _offer == null:
		return false
	if EQUIP_COST > 0.0:
		if GameManager == null or not GameManager.has_method("try_spend_contribution"):
			return false
		if not bool(GameManager.try_spend_contribution(EQUIP_COST)):
			return false
	_equipped = _offer
	if p.has_method("equip_clash_module"):
		p.equip_clash_module(_equipped)
	else:
		p.set_meta("clash_module_id", offer_id())
		p.set_meta("clash_module_name", offer_name())
	_refresh_label()
	if GameManager:
		GameManager.toast_requested.emit(
			"Module %s — session blueprint, not a power card" % offer_name()
		)
	print("[ClashModuleBench] equipped ", offer_id(), " combat=", modifies_combat())
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode != KEY_G and event.physical_keycode != KEY_G:
		return
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	if global_position.distance_to(_player_ref.global_position) > INTERACT_RADIUS:
		return
	try_equip(_player_ref)
	get_viewport().set_input_as_handled()


func _build_proxy() -> void:
	var col := Color(0.25, 0.75, 0.95)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = col * 0.35
	_mat.metallic = 0.55
	_mat.roughness = 0.45
	_mat.emission_enabled = true
	_mat.emission = col
	_mat.emission_energy_multiplier = 1.15
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color.a = 0.92
	var headless := DisplayServer.get_name() == "headless"
	var slab := MeshInstance3D.new()
	slab.name = "Slab"
	var slab_mesh := BoxMesh.new()
	slab_mesh.size = Vector3(1.8, 0.35, 1.2)
	slab.mesh = slab_mesh
	slab.material_override = _mat
	slab.position.y = 0.22
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(slab)
	var post := MeshInstance3D.new()
	post.name = "Post"
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.22, 1.4, 0.22)
	post.mesh = post_mesh
	post.material_override = _mat
	post.position = Vector3(0.7, 0.9, 0)
	post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(post)
	if not headless:
		_label = Label3D.new()
		_label.name = "BenchLabel"
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label.font_size = 20
		_label.outline_size = 10
		_label.outline_modulate = Color(0, 0, 0, 0.9)
		_label.position = Vector3(0, 2.1, 0)
		add_child(_label)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 0.35, 1.2)
	cs.shape = box
	cs.position.y = 0.22
	body.add_child(cs)
	add_child(body)


func _refresh_label() -> void:
	if _label == null:
		return
	var tag := label_text()
	if has_equipped():
		_label.text = "%s\n%s · ON" % [tag, offer_name()]
		_label.modulate = Color(0.55, 0.95, 0.75)
	else:
		_label.text = "%s\n%s · G" % [tag, offer_name()]
		_label.modulate = Color(0.45, 0.85, 1.0)
