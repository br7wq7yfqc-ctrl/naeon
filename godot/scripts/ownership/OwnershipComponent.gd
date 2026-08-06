class_name OwnershipComponent
extends Node3D

## Applies Dynamic Ownership: data + visual Cybernex/gROT theme blend.

signal ownership_changed(faction: OwnershipData.Faction, progress: float)
signal fully_claimed(faction: OwnershipData.Faction)

@export var data: OwnershipData
@export var transition_duration: float = 6.0
@export var mesh_path: NodePath = NodePath("Mesh")
@export var label_height: float = 2.2
@export var claimable: bool = true

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
	_apply_visual(true)
	set_process(true)

func _process(delta: float) -> void:
	if data and data.transition_progress < 1.0:
		data.advance_transition(delta, transition_duration)
		_apply_visual(false)
		ownership_changed.emit(data.current_faction, data.transition_progress)
		if data.transition_progress >= 1.0:
			fully_claimed.emit(data.current_faction)

func claim(faction_name: String, strength: float = 1.0) -> void:
	if not claimable:
		return
	var f := OwnershipData.from_string(faction_name)
	data.claim_strength += strength
	data.start_transition(f)
	ownership_changed.emit(data.current_faction, data.transition_progress)
	print("[Ownership] ", name, " → ", data.faction_name())

func on_hacked(caster: Node, amount: float = 1.0) -> void:
	var faction := "Cybernex"
	if caster and caster.has_method("get_faction"):
		faction = caster.get_faction()
	# gROT hacking claims toward gROT; Cybernex probe claims toward Cybernex
	claim(faction, amount * 0.25)
	if has_method("take_damage"):
		call("take_damage", amount * 0.5)
	elif get_parent() and get_parent().has_method("take_damage"):
		get_parent().take_damage(amount * 0.5)

func get_faction() -> String:
	return data.faction_name() if data else "Neutral"

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
	var target := _neutral_color
	match data.current_faction:
		OwnershipData.Faction.CYBERNEX:
			target = _cybernex_color
		OwnershipData.Faction.GROT:
			target = _grot_color
		OwnershipData.Faction.CONTESTED:
			target = _cybernex_color.lerp(_grot_color, 0.5)
		_:
			target = _neutral_color
	var from := _neutral_color
	match data.previous_faction:
		OwnershipData.Faction.CYBERNEX:
			from = _cybernex_color
		OwnershipData.Faction.GROT:
			from = _grot_color
		_:
			from = _neutral_color
	var c := from.lerp(target, data.transition_progress)
	_mat.albedo_color = c.darkened(0.35)
	_mat.emission = c
	_mat.emission_energy_multiplier = 0.8 + data.transition_progress * 1.4
	if _label:
		var pct := int(data.transition_progress * 100.0)
		_label.text = "%s  %d%%" % [data.faction_name(), pct]
		_label.modulate = c
