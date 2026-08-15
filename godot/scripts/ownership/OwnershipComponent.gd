class_name OwnershipComponent
extends Node3D
const _AP = preload("res://scripts/assets/AssetPaths.gd")

## Applies Dynamic Ownership: data + visual Cybernex/gROT theme blend.

signal ownership_changed(faction: OwnershipData.Faction, progress: float)
signal fully_claimed(faction: OwnershipData.Faction)

@export var data: OwnershipData
@export var transition_duration: float = 6.0
@export var mesh_path: NodePath = NodePath("Mesh")
@export var label_height: float = 2.2
@export var claimable: bool = true
@export var dual_mesh_base: String = ""  # e.g. props/claim_beacon/claim_beacon — loads _cybernex/_grot lod1
@export var occupy_radius: float = 4.2
var _dual_root: Node3D
var _pulse_cd: float = 0.0
var _claimed_emitted: bool = false
const OCCUPY_NEED := 1.75
const OCCUPY_PULSE := 0.38
const OCCUPY_DECAY := 0.16

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _label: Label3D
var _cybernex_color := Color(0.15, 0.85, 1.0)
var _grot_color := Color(0.95, 0.12, 0.42)
var _neutral_color := Color(0.55, 0.55, 0.6)

func _ready() -> void:
	if data == null:
		data = OwnershipData.new()
		data.object_id = name
	_mesh = get_node_or_null(mesh_path) as MeshInstance3D
	if _mesh == null:
		_mesh = find_child("Mesh", true, false) as MeshInstance3D
	_ensure_material()
	_ensure_label()
	_ensure_body()
	add_to_group("hackable")
	_apply_visual(true)
	call_deferred("_refresh_dual_mesh")
	set_process(true)

func _process(delta: float) -> void:
	_tick_occupy(delta)
	if data:
		if not data.is_fully_owned():
			data.transition_progress = clampf(data.claim_strength / OCCUPY_NEED, 0.0, 1.0)
		_apply_visual(false)
		if data.claim_strength >= OCCUPY_NEED:
			_emit_claimed()


func claim(faction_name: String, strength: float = 1.0) -> void:
	if not claimable or data == null:
		return
	var f: OwnershipData.Faction = OwnershipData.from_string(faction_name)
	if data.current_faction != f:
		if data.current_faction != OwnershipData.Faction.NEUTRAL and data.current_faction != OwnershipData.Faction.CONTESTED:
			data.claim_strength *= 0.35
		data.start_transition(f)
		_claimed_emitted = false
	data.claim_strength += strength
	data.transition_progress = clampf(data.claim_strength / OCCUPY_NEED, 0.0, 1.0)
	ownership_changed.emit(data.current_faction, data.transition_progress)
	_apply_visual(false)
	print("[Ownership] ", name, " → ", data.faction_name(), " ", snapped(data.claim_strength, 0.01))
	if data.claim_strength >= OCCUPY_NEED:
		_emit_claimed()

func on_hacked(caster: Node, amount: float = 1.0) -> void:
	var faction: String = "Cybernex"
	if caster and caster.has_method("get_faction"):
		faction = caster.get_faction()
	# gROT hacking claims toward gROT; Cybernex probe claims toward Cybernex
	claim(faction, 0.28)
	if has_method("take_damage"):
		call("take_damage", amount * 0.5)
	elif get_parent() and get_parent().has_method("take_damage"):
		get_parent().take_damage(amount * 0.5)

func get_faction() -> String:
	return data.faction_name() if data else "Neutral"


func _tick_occupy(delta: float) -> void:
	if not claimable or data == null:
		return
	_pulse_cd = maxf(0.0, _pulse_cd - delta)
	var actor := _find_actor()
	var near := actor != null and is_instance_valid(actor) \
		and global_position.distance_to(actor.global_position) <= occupy_radius
	if near and _pulse_cd <= 0.0 and Input.is_physical_key_pressed(KEY_C):
		var fac := "Cybernex"
		if actor.has_method("get_faction"):
			fac = str(actor.get_faction())
		elif GameManager:
			fac = GameManager.get_faction_name()
		claim(fac, OCCUPY_PULSE)
		_pulse_cd = 0.55
		if AudioDirector and AudioDirector.has_method("play_claim_pulse"):
			AudioDirector.play_claim_pulse()
		elif AudioDirector:
			AudioDirector.play_ui()
	elif not near and not data.is_fully_owned():
		data.claim_strength = maxf(0.0, data.claim_strength - OCCUPY_DECAY * delta)
		if data.claim_strength <= 0.02 and data.current_faction != OwnershipData.Faction.NEUTRAL:
			data.current_faction = OwnershipData.Faction.NEUTRAL
			data.transition_progress = 0.0
			_claimed_emitted = false


func _find_actor() -> Node3D:
	if SoftScanCache:
		var p = SoftScanCache.get_player()
		if p is Node3D:
			return p as Node3D
	var tree := get_tree()
	if tree == null:
		return null
	var n := tree.get_first_node_in_group("player")
	return n as Node3D if n is Node3D else null


func _emit_claimed() -> void:
	if _claimed_emitted or data == null:
		return
	if data.claim_strength < OCCUPY_NEED:
		return
	_claimed_emitted = true
	data.transition_progress = 1.0
	fully_claimed.emit(data.current_faction)
	_refresh_dual_mesh()
	if GameManager:
		GameManager.toast_requested.emit("Beacon held · %s · soft WS only" % data.faction_name())


func _ensure_body() -> void:
	if get_node_or_null("Body") != null:
		return
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.45
	sh.height = 1.7
	cs.shape = sh
	cs.position = Vector3(0, 0.85, 0)
	body.add_child(cs)
	add_child(body)


func _ensure_material() -> void:
	if _mesh == null:
		return
	_mat = StandardMaterial3D.new()
	_mat.metallic = 0.55
	_mat.roughness = 0.35
	_mat.emission_enabled = true
	_mesh.material_override = _mat

func _ensure_label() -> void:
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 28
	_label.outline_size = 6
	_label.modulate = Color(0.9, 0.95, 1.0)
	add_child(_label)
	_label.position = Vector3(0, label_height, 0)

func _apply_visual(force: bool = false) -> void:
	if _mat == null and not force:
		return
	if _mat == null:
		_ensure_material()
	if _mat == null:
		return
	var target: Color = _neutral_color
	match data.current_faction:
		OwnershipData.Faction.CYBERNEX:
			target = _cybernex_color
		OwnershipData.Faction.GROT:
			target = _grot_color
		OwnershipData.Faction.CONTESTED:
			target = _cybernex_color.lerp(_grot_color, 0.5)
		_:
			target = _neutral_color
	var from: Color = _neutral_color
	match data.previous_faction:
		OwnershipData.Faction.CYBERNEX:
			from = _cybernex_color
		OwnershipData.Faction.GROT:
			from = _grot_color
		_:
			from = _neutral_color
	var c: Color = from.lerp(target, data.transition_progress)
	_mat.albedo_color = c.darkened(0.35)
	_mat.emission = c
	_mat.emission_energy_multiplier = 0.8 + data.transition_progress * 1.4
	if _label:
		if data.is_fully_owned():
			_label.text = "%s  HELD" % data.faction_name()
		else:
			var pct: int = int(data.transition_progress * 100.0)
			_label.text = "%s  %d%% · C" % [data.faction_name(), pct]
		_label.modulate = c

func _refresh_dual_mesh() -> void:
	if dual_mesh_base == "":
		return
	var fac := "cybernex"
	if data and data.faction_name() == "gROT":
		fac = "grot"
	var rel := "%s_%s_lod1.glb" % [dual_mesh_base, fac]
	var path: String = _AP.resolve(rel)
	if not FileAccess.file_exists(path):
		return
	if _dual_root and is_instance_valid(_dual_root):
		_dual_root.queue_free()
		_dual_root = null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return
	var root := doc.generate_scene(state)
	if root == null:
		return
	add_child(root)
	_dual_root = root as Node3D
	if _dual_root:
		_dual_root.scale = Vector3.ONE * 0.9
	if _mesh:
		_mesh.visible = false
	print("[Ownership] dual mesh ", rel)
