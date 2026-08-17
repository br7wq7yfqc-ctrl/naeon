extends Node3D
class_name ClashCamp
## AR-D: one off-lane jungle objective (fangtooth-class role, not IP).
## Code-first proxy — no GLB, no unique weapon, Knowledge may label only.

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")

signal contest_changed(contested: bool)
signal camp_down

## Between MID (x=0±3.2) and TOP (x=14±3.2) on the same 60×60 floor.
const CAMP_POS := Vector3(7.2, 0.0, -1.2)
const CONTEST_RADIUS := 7.5
const CAMP_HP := 220.0
const RESPAWN := 40.0
const CONTEST_HOLD := 2.4

var faction: String = "Neutral"
var max_health: float = CAMP_HP
var health: float = CAMP_HP
var _alive: bool = true
var _contested: bool = false
var _contest_t: float = 0.0
var _player_ref: Node3D = null
var _label: Label3D = null
var _mat: StandardMaterial3D = null
var _last_announce: String = ""
var _drop_kind: String = "soft_ws"

func _ready() -> void:
	name = "ClashCamp"
	add_to_group("clash_camp")
	add_to_group("enemy")
	add_to_group("hackable")
	position = CAMP_POS
	health = max_health
	_build_proxy()
	_refresh_label()
	set_process(true)
	print("[ClashCamp] off-lane pit at ", CAMP_POS, " hp=", max_health, " label=", label_text())


func bind_player(p: Node3D) -> void:
	_player_ref = p


func is_alive() -> bool:
	return _alive


func is_contested() -> bool:
	return _contested and _alive


func get_contest_state() -> String:
	if not _alive:
		return "down"
	if _contested:
		return "contested"
	return "idle"


func last_announce() -> String:
	return _last_announce


func camp_drop_kind() -> String:
	return _drop_kind


func is_off_lane() -> bool:
	return absf(global_position.x) > 3.6 and absf(global_position.x - 14.0) > 3.6 \
		and absf(global_position.x + 14.0) > 3.6


func label_text() -> String:
	return _SoftK.camp_label()


func get_faction() -> String:
	return faction


func hurtbox_center() -> Vector3:
	return global_position + Vector3(0, 1.15, 0)


func hurtbox_radius() -> float:
	return 1.45


func note_presence(pos: Vector3) -> void:
	if not _alive:
		return
	if global_position.distance_to(pos) <= CONTEST_RADIUS:
		_open_contest("presence")


func take_damage(amount: float, _source_faction: String = "") -> void:
	if not _alive or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	_open_contest("damage")
	_flash()
	_refresh_label()
	if CombatJuice:
		CombatJuice.hit_feedback(float(amount), hurtbox_center(), amount >= 24.0)
	if health <= 0.0:
		_die()


func on_hacked(caster: Node, amount: float = 1.0) -> void:
	if caster and caster.has_method("get_faction") and str(caster.get_faction()) == faction:
		return
	take_damage(amount * 1.5, str(caster.get_faction()) if caster and caster.has_method("get_faction") else "")


func _process(delta: float) -> void:
	if not _alive:
		return
	if _player_ref != null and is_instance_valid(_player_ref):
		note_presence(_player_ref.global_position)
	if not _contested:
		return
	_contest_t -= delta
	if _contest_t <= 0.0:
		_close_contest()


func _open_contest(reason: String) -> void:
	_contest_t = CONTEST_HOLD
	if _contested:
		return
	_contested = true
	_last_announce = "CAMP CONTESTED — soft · no unique weapon"
	contest_changed.emit(true)
	_refresh_label()
	if _mat:
		_mat.emission_energy_multiplier = 2.2
	var tree := get_tree()
	var announced := false
	if tree:
		var matchn: Node = tree.get_first_node_in_group("clash_match")
		if matchn and matchn.has_method("register_camp_contest"):
			matchn.register_camp_contest()
			announced = true
	if not announced and GameManager:
		GameManager.toast_requested.emit(_last_announce)
	print("[ClashCamp] contest open via ", reason)


func _close_contest() -> void:
	if not _contested:
		return
	_contested = false
	_contest_t = 0.0
	contest_changed.emit(false)
	if _mat and _alive:
		_mat.emission_energy_multiplier = 1.35
	_refresh_label()
	print("[ClashCamp] contest closed")


func _die() -> void:
	_alive = false
	_close_contest()
	if is_in_group("enemy"):
		remove_from_group("enemy")
	if SoftScanCache:
		SoftScanCache.invalidate_enemies()
	camp_down.emit()
	var tree := get_tree()
	if tree:
		var clash: Node = tree.get_first_node_in_group("aexion_clash")
		if clash and clash.has_method("register_camp_down"):
			clash.register_camp_down()
	if CombatJuice:
		CombatJuice.kill_pop(global_position)
	visible = false
	print("[ClashCamp] down drop=", _drop_kind, " (not a unique weapon)")
	if get_tree():
		get_tree().create_timer(RESPAWN).timeout.connect(_respawn)


func _respawn() -> void:
	health = max_health
	_alive = true
	visible = true
	if not is_in_group("enemy"):
		add_to_group("enemy")
	if SoftScanCache:
		SoftScanCache.invalidate_enemies()
	_refresh_label()
	print("[ClashCamp] respawned")


func _build_proxy() -> void:
	var col := Color(0.55, 0.82, 0.28)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = col * 0.4
	_mat.metallic = 0.35
	_mat.roughness = 0.55
	_mat.emission_enabled = true
	_mat.emission = col
	_mat.emission_energy_multiplier = 1.35
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color.a = 0.9
	var headless := DisplayServer.get_name() == "headless"
	var mound := MeshInstance3D.new()
	mound.name = "Mound"
	var mound_mesh := BoxMesh.new()
	mound_mesh.size = Vector3(2.2, 1.6, 2.2)
	mound.mesh = mound_mesh
	mound.material_override = _mat
	mound.position.y = 0.8
	mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mound)
	var ring := MeshInstance3D.new()
	ring.name = "PitRing"
	var ring_mesh := BoxMesh.new()
	ring_mesh.size = Vector3(4.4, 0.12, 4.4)
	ring.mesh = ring_mesh
	ring.material_override = _mat
	ring.position.y = 0.06
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	if not headless:
		_label = Label3D.new()
		_label.name = "CampLabel"
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label.font_size = 20
		_label.outline_size = 10
		_label.outline_modulate = Color(0, 0, 0, 0.9)
		_label.position = Vector3(0, 2.6, 0)
		add_child(_label)
	var body := StaticBody3D.new()
	body.collision_layer = 4
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.6, 2.2)
	cs.shape = box
	cs.position.y = 0.8
	body.add_child(cs)
	add_child(body)


func _refresh_label() -> void:
	if _label == null:
		return
	var tag := label_text()
	if not _alive:
		_label.text = "%s\nDOWN" % tag
		_label.modulate = Color(0.45, 0.45, 0.45)
		return
	if _contested:
		_label.text = "%s\nCONTESTED  %d" % [tag, int(health)]
		_label.modulate = Color(1.0, 0.75, 0.25)
	else:
		_label.text = "%s\n%d" % [tag, int(health)]
		_label.modulate = Color(0.7, 0.95, 0.4)


func _flash() -> void:
	if _mat == null:
		return
	var orig: Color = _mat.albedo_color
	_mat.albedo_color = Color(1, 1, 1, orig.a)
	if get_tree():
		get_tree().create_timer(0.07).timeout.connect(func():
			if is_instance_valid(self) and _mat:
				_mat.albedo_color = orig
		)
