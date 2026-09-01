class_name Extractor
extends Node3D
const _AP = preload("res://scripts/assets/AssetPaths.gd")
const _Prop = preload("res://scripts/assets/GlbProp.gd")
const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")

## Surface extractor — pulls resources + grants Contribution.
## ST-B pad-driven: visual + label only. PadBaseController deposits.

signal contribution_gained(amount: float)

@export var extract_rate: float = 3.0
@export var contribution_per_unit: float = 0.4
@export var auto_start: bool = true

var ownership: Node = null
var mesh: MeshInstance3D = null
var label: Label3D = null
var target_node: ResourceNode = null
var running: bool = false
var total_extracted: float = 0.0
var _pad: Node = null

func _ready() -> void:
	ownership = get_node_or_null("Ownership")
	mesh = get_node_or_null("Mesh") as MeshInstance3D
	label = get_node_or_null("StatusLabel") as Label3D
	set_process(true)
	if _pad != null:
		return
	if auto_start:
		running = true
		call_deferred("_ready_load_visual")
		_find_nearest_resource()


func bind_pad(ctrl: Node) -> void:
	## ST-B: show the harvest machine. Wallet stays on PadBaseController.
	_pad = ctrl
	auto_start = false
	running = false
	set_meta("site_pin", "")
	set_meta("module_type", "extractor")
	set_meta("pad_harvest", true)
	set_meta("ledger_slug", "t1_resource_extractor")
	if not is_in_group("pad_extractors"):
		add_to_group("pad_extractors")
	_ensure_pad_visual()
	_ensure_pad_label()
	_sync_from_pad()


func is_pad_driven() -> bool:
	return _pad != null and is_instance_valid(_pad)


func scan_intel() -> Dictionary:
	## Q-E: SoftKnowledge extractor label only. Does not harvest / change yield.
	var Board = load("res://scripts/systems/ContractBoard.gd")
	var intel := _SoftK.extractor_label()
	var out := {}
	set_meta("last_scan_intel", intel)
	if Board != null and Board.has_method("interact_scan_extractor"):
		out = Board.interact_scan_extractor()
	if typeof(out) != TYPE_DICTIONARY or out.is_empty():
		out = {"intel": intel}
	elif str(out.get("intel", "")) == "":
		out["intel"] = intel
	return out


func reload_for_faction(faction_name: String) -> void:
	## ST-F mesh theme only. Does not touch extract_rate / contribution_per_unit.
	var mesh: Node = get_node_or_null("ExtractorMesh")
	if mesh != null and mesh.has_method("reload_for_faction"):
		mesh.reload_for_faction(faction_name)
	_sync_from_pad()


func _process(_delta: float) -> void:
	if is_pad_driven():
		_sync_from_pad()
		return
	if not running:
		return
	if ownership and ownership.has_method("get_faction"):
		var ofac := str(ownership.get_faction())
		if ofac in ["Neutral", "Contested", ""]:
			if label:
				label.text = "Extractor idle · claim first"
			return
		var pfac := GameManager.get_faction_name() if GameManager else ""
		if pfac != "" and ofac != pfac:
			if label:
				label.text = "Extractor %s · not yours" % ofac
			return
	if target_node == null or not is_instance_valid(target_node) or target_node.reserves <= 0.0:
		_find_nearest_resource()
		if target_node == null:
			if label:
				label.text = "Extractor idle"
			return
	var got: float = target_node.extract(extract_rate * _delta)
	if got <= 0.0:
		return
	total_extracted += got
	var contrib: float = got * contribution_per_unit
	if GameManager:
		# Route through the shared deposit so a gROT-owned extractor pays
		# Biomass and the harvest objective actually ticks.
		GameManager.deposit_economy(contrib, true, ownership.get_faction() if ownership else "")
	contribution_gained.emit(contrib)
	if label:
		var fac: String = ownership.get_faction() if ownership else "?"
		label.text = "EXTRACT %.1f\n%s +%.1f C" % [total_extracted, fac, contrib]


func _sync_from_pad() -> void:
	if not is_pad_driven():
		return
	if "total_extracted" in _pad:
		total_extracted = float(_pad.get("total_extracted"))
	var st := ""
	if _pad.has_method("get_claim_status"):
		st = str(_pad.get_claim_status())
	var grot := false
	if GameManager and GameManager.has_method("get_faction_name"):
		grot = str(GameManager.get_faction_name()) == "gROT"
	elif _pad.has_method("get_faction"):
		grot = str(_pad.get_faction()) == "gROT"
	var unit := _SoftK.yield_label(grot)
	var machine := _SoftK.extractor_label()
	if label == null:
		return
	if st == "extracting":
		var rate := 0.0
		if "extract_rate" in _pad and "contribution_per_unit" in _pad:
			rate = float(_pad.get("extract_rate")) * float(_pad.get("contribution_per_unit"))
		label.text = "%s\n%s  +%.1f/s" % [machine, unit, rate]
	else:
		label.text = "%s\n%s · occupy to harvest" % [machine, unit]


func _ensure_pad_visual() -> void:
	if get_node_or_null("ExtractorMesh") != null:
		return
	var fx := "cybernex"
	if _pad != null and _pad.has_method("get_faction") and str(_pad.get_faction()) == "gROT":
		fx = "grot"
	var prop := Node3D.new()
	prop.set_script(_Prop)
	prop.set("relative_path", "colony/extractor_unit/extractor_unit_%s_lod1.glb" % fx)
	prop.set("scale_factor", 1.4)
	prop.set("add_static_collision", true)
	prop.name = "ExtractorMesh"
	add_child(prop)


func _ensure_pad_label() -> void:
	if label != null:
		return
	label = Label3D.new()
	label.name = "StatusLabel"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 20
	label.outline_size = 4
	label.position = Vector3(0, 2.6, 0)
	add_child(label)


func _find_nearest_resource() -> void:
	target_node = null
	var tree := get_tree()
	if tree == null:
		return
	var best_d: float = 9999.0
	for n in tree.get_nodes_in_group("resource_nodes"):
		if n is ResourceNode and n.reserves > 0.0:
			var d: float = global_position.distance_to(n.global_position)
			if d < best_d and d < 18.0:
				best_d = d
				target_node = n

func on_hacked(caster: Node, amount: float = 1.0) -> void:
	if ownership:
		ownership.on_hacked(caster, amount)

func _ready_load_visual() -> void:
	if is_pad_driven():
		return
	try_load_glb("colony/extractor_unit/extractor_unit_cybernex_lod1.glb")

func try_load_glb(rel: String) -> void:
	var path: String = _AP.resolve(rel)
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
