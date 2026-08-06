class_name Extractor
extends Node3D

## Surface extractor — pulls resources + grants Contribution.

signal contribution_gained(amount: float)

@export var extract_rate: float = 3.0
@export var contribution_per_unit: float = 0.4
@export var auto_start: bool = true

@onready var ownership: OwnershipComponent = $Ownership
@onready var mesh: MeshInstance3D = $Mesh
@onready var label: Label3D = $StatusLabel

var target_node: ResourceNode = null
var running: bool = false
var total_extracted: float = 0.0

func _ready() -> void:
	call_deferred("_ready_load_visual")
	if auto_start:
		running = true
	_find_nearest_resource()
	set_process(true)

func _process(delta: float) -> void:
	if not running:
		return
	if target_node == null or not is_instance_valid(target_node) or target_node.reserves <= 0.0:
		_find_nearest_resource()
		if target_node == null:
			if label:
				label.text = "Extractor idle"
			return
	var got: float = target_node.extract(extract_rate * delta)
	if got <= 0.0:
		return
	total_extracted += got
	var contrib: float = got * contribution_per_unit
	if GameManager:
		GameManager.add_contribution(contrib)
	contribution_gained.emit(contrib)
	if label:
		var fac: String = ownership.get_faction() if ownership else "?"
		label.text = "EXTRACT %.1f\n%s +%.1f C" % [total_extracted, fac, contrib]

func _find_nearest_resource() -> void:
	target_node = null
	var best_d: float = 9999.0
	for n in get_tree().get_nodes_in_group("resource_nodes"):
		if n is ResourceNode and n.reserves > 0.0:
			var d: float = global_position.distance_to(n.global_position)
			if d < best_d and d < 18.0:
				best_d = d
				target_node = n

func on_hacked(caster: Node, amount: float = 1.0) -> void:
	if ownership:
		ownership.on_hacked(caster, amount)

func _ready_load_visual() -> void:
	# called from _ready if present
	try_load_glb("colony/extractor_unit/extractor_unit_cybernex_lod1.glb")

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
