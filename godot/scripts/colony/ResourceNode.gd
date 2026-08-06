class_name ResourceNode
extends Node3D

## Harvestable resource node on planet surface / asteroid.

signal depleted
signal extracted(amount: float, resource_type: String)

@export var resource_type: String = "rare_ore"
@export var reserves: float = 100.0
@export var max_reserves: float = 100.0
@export var richness: float = 1.0

@onready var mesh: MeshInstance3D = $Mesh
@onready var label: Label3D = $Label

func _ready() -> void:
	call_deferred("_ready_load_visual")
	_refresh_label()
	_tint()

func extract(amount: float) -> float:
	var got: float = min(reserves, amount * richness)
	reserves -= got
	_refresh_label()
	_tint()
	if got > 0.0:
		extracted.emit(got, resource_type)
	if reserves <= 0.0:
		depleted.emit()
	return got

func _refresh_label() -> void:
	if label:
		label.text = "%s\n%.0f / %.0f" % [resource_type, reserves, max_reserves]

func _tint() -> void:
	if mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	var t: float = reserves / max(max_reserves, 1.0)
	mat.albedo_color = Color(0.2, 0.15, 0.05).lerp(Color(0.55, 0.4, 0.1), t)
	mat.emission = Color(0.9, 0.7, 0.15) * t
	mat.emission_energy_multiplier = 0.5 + t
	mesh.material_override = mat

func _ready_load_visual() -> void:
	# called from _ready if present
	try_load_glb("colony/resource_crystal/resource_crystal_cybernex_lod1.glb")

func try_load_glb(rel: String) -> void:
	var base := ProjectSettings.globalize_path("res://").get_base_dir().get_base_dir()
	var path := base.path_join("assets").path_join(rel)
	if not FileAccess.file_exists(path):
		var home := OS.get_environment("HOME")
		path = home.path_join("Documents/naeon/assets").path_join(rel)
	if not FileAccess.file_exists(path):
		return
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return
	var root := doc.generate_scene(state)
	if root == null:
		return
	var old := get_node_or_null("Mesh")
	if old:
		old.visible = false
	add_child(root)
	root.name = "GLBVisual"
	print("[", name, "] loaded ", path)
