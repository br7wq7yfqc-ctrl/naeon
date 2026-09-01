extends Node3D
class_name PadPrintBench
## ST-C §6(a) / NP-G: print one catalog module at an unnamed pad / NPC bench.
## ST-G §6(c) / NP-I: print_one_factory_module at the player-cluster factory.
## Spends Contribution (CX) or Biomass (GR). Never cash. Knowledge labels only.
## NP-G uses print_one_module — not factory (c), not hangar (b), not NP-C habitat.
## NP-I uses print_one_factory_module — not pad bench (a), not hangar (b).

const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
const _Builder = preload("res://scripts/world/BaseBuilder.gd")

## rules/15 §4 Personal extractor T1 mid-band (80–120). Habitat uses the low end.
const EXTRACTOR_T1_COST := 100.0
const HABITAT_T1_COST := 80.0
const DEFAULT_KIND := "extractor"

var _granted: Node3D = null
var _factory_granted: Node3D = null


func _ready() -> void:
	name = "PadPrintBench"
	set_meta("site_pin", "")
	set_meta("print_bench", true)
	if not is_in_group("print_benches"):
		add_to_group("print_benches")
	_ensure_proxy()
	print("[PadPrintBench] §6(a) bench on ", _pad_name(), " cost=", print_cost(), " cash_skip=false")


func print_cost(kind: String = "") -> float:
	## Fixed rules/15 band. Knowledge never discounts.
	var k := _kind(kind)
	if k == "habitat":
		return HABITAT_T1_COST
	return EXTRACTOR_T1_COST


func offer_kind() -> String:
	return DEFAULT_KIND


func cash_shop_skip_possible() -> bool:
	return false


func reload_for_faction(faction_name: String) -> void:
	## ST-F bench skin only. print_cost stays the rules/15 T1 number.
	var fac := faction_name
	var slab: MeshInstance3D = get_node_or_null("Slab") as MeshInstance3D
	var lab: Label3D = get_node_or_null("BenchLabel") as Label3D
	var col := Color(0.35, 0.85, 0.7)
	var mat: StandardMaterial3D = null
	if fac == "gROT":
		col = Color(0.95, 0.22, 0.42)
	elif fac == "Cybernex":
		col = Color(0.15, 0.85, 1.0)
	if slab != null:
		mat = slab.material_override as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			slab.material_override = mat
		mat.albedo_color = col * 0.4
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.05
	if lab != null:
		lab.modulate = col
		lab.text = "%s\n%.0f %s · no cash" % [_SoftK.print_bench_label(), print_cost(), _wallet_name().to_upper()]


func try_cash_skip_print(_cash: float = 0.0) -> bool:
	## Freemium / rules/19: shop may not skip print. Always refuse.
	print("[PadPrintBench] cash-shop skip refused")
	return false


func granted_module() -> Node3D:
	if _granted != null and is_instance_valid(_granted):
		return _granted
	return null


func factory_granted_module() -> Node3D:
	if _factory_granted != null and is_instance_valid(_factory_granted):
		return _factory_granted
	return null


func factory_in_cluster() -> Node3D:
	## ST-G §6(c): factory must already sit in the player cluster.
	var tree := get_tree()
	var cluster: Node = null
	var n: Node = null
	if tree:
		for m in tree.get_nodes_in_group("player_factory_modules"):
			if m != null and is_instance_valid(m) and m.is_inside_tree():
				if str(m.get_meta("module_type", "")) == "factory":
					return m as Node3D
		var listed: Array = tree.get_nodes_in_group("player_orbital_stations")
		if not listed.is_empty():
			cluster = listed[0]
	if cluster != null and cluster.has_method("factory_module"):
		n = cluster.factory_module()
		if n is Node3D and (n as Node3D).is_inside_tree():
			return n as Node3D
	return null


func print_one_factory_module(kind: String = "", cash: float = 0.0) -> Node3D:
	## ST-G / NP-I §6(c): same rules/15 spend as ST-C, gated on a factory in-cluster.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var k := ""
	var cost := 0.0
	var fac := ""
	var cluster: Node3D = null
	var factory: Node3D = null
	var mod: Node3D = null
	if P0 == null or not bool(P0.ST_G_FACTORY):
		return null
	if cash > 0.0:
		print("[PadPrintBench] cash-shop skip refused")
		return null
	factory = factory_in_cluster()
	if factory == null:
		print("[PadPrintBench] §6(c) refuse: no factory")
		return null
	if factory_granted_module() != null:
		print("[PadPrintBench] §6(c) already granted one module")
		return null
	k = _kind(kind)
	cost = print_cost(k)
	if cost <= 0.0:
		return null
	if GameManager == null or not GameManager.has_method("try_spend_economy"):
		return null
	if not bool(GameManager.try_spend_economy(cost)):
		print("[PadPrintBench] §6(c) need ", snapped(cost, 0.1), " Contribution/Biomass")
		return null
	cluster = _factory_cluster()
	fac = _faction()
	mod = _Builder.print_factory_catalog_module(cluster, fac, k)
	if mod == null or not is_instance_valid(mod):
		_refund(cost)
		return null
	if str(mod.get_meta("site_pin", "x")) != "":
		push_error("[PadPrintBench] factory print minted a site_pin")
		mod.queue_free()
		_refund(cost)
		return null
	_factory_granted = mod
	if GameManager:
		GameManager.toast_requested.emit(
			"Factory printed %s (−%.0f %s) — no cash skip" % [k, cost, _wallet_name()]
		)
	print("[PadPrintBench] §6(c) printed ", k, " spent ", snapped(cost, 0.1),
		" factory=", factory.name, " cash_skip=false")
	return mod


func print_one_module(kind: String = "", cash: float = 0.0) -> Node3D:
	## Spend wallet → place ONE existing catalog module. Cash never pays.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var k := ""
	var cost := 0.0
	var pad: Node3D = null
	var fac := ""
	var mod: Node3D = null
	if P0 == null or not bool(P0.ST_C_PRINT):
		return null
	if cash > 0.0:
		print("[PadPrintBench] cash-shop skip refused")
		return null
	if granted_module() != null:
		print("[PadPrintBench] already granted one module")
		return null
	k = _kind(kind)
	cost = print_cost(k)
	if cost <= 0.0:
		return null
	if GameManager == null or not GameManager.has_method("try_spend_economy"):
		return null
	if not bool(GameManager.try_spend_economy(cost)):
		print("[PadPrintBench] need ", snapped(cost, 0.1), " Contribution/Biomass")
		return null
	pad = _pad_host()
	fac = _faction()
	mod = _Builder.print_catalog_module(pad, fac, k)
	if mod == null or not is_instance_valid(mod):
		_refund(cost)
		return null
	if str(mod.get_meta("site_pin", "x")) != "":
		push_error("[PadPrintBench] printed module minted a site_pin")
		mod.queue_free()
		_refund(cost)
		return null
	_granted = mod
	if GameManager:
		GameManager.toast_requested.emit(
			"Printed %s (−%.0f %s) — no cash skip" % [k, cost, _wallet_name()]
		)
	print("[PadPrintBench] printed ", k, " spent ", snapped(cost, 0.1), " on ", _pad_name(), " cash_skip=false")
	return mod


func _kind(kind: String) -> String:
	var k := kind.strip_edges().to_lower()
	if k == "habitat" or k == "extractor":
		return k
	return DEFAULT_KIND


func _pad_host() -> Node3D:
	var n: Node = get_parent()
	while n:
		if n is Node3D and str(n.name) in ["Pad_North", "Pad_Approach", "Pad_Flank"]:
			return n as Node3D
		n = n.get_parent()
	return get_parent() as Node3D


func _factory_cluster() -> Node3D:
	var tree := get_tree()
	var parent: Node = null
	if tree:
		var listed: Array = tree.get_nodes_in_group("player_orbital_stations")
		if not listed.is_empty() and listed[0] is Node3D:
			return listed[0] as Node3D
		for m in tree.get_nodes_in_group("player_factory_modules"):
			if m is Node and (m as Node).is_inside_tree():
				parent = (m as Node).get_parent()
				if parent is Node3D:
					return parent as Node3D
	return _pad_host()


func _pad_name() -> String:
	var pad := _pad_host()
	return str(pad.name) if pad else "?"


func _faction() -> String:
	if GameManager and GameManager.has_method("get_faction_name"):
		return str(GameManager.get_faction_name())
	return "Cybernex"


func _wallet_name() -> String:
	if GameManager and GameManager.has_method("get_faction_name") \
		and str(GameManager.get_faction_name()) == "gROT":
		return "Biomass"
	return "Contribution"


func _refund(amount: float) -> void:
	if GameManager == null or amount <= 0.0:
		return
	if GameManager.has_method("get_faction_name") and str(GameManager.get_faction_name()) == "gROT":
		if GameManager.has_method("add_biomass"):
			GameManager.add_biomass(amount)
		return
	if GameManager.has_method("add_contribution"):
		GameManager.add_contribution(amount)


func _ensure_proxy() -> void:
	var col := Color(0.35, 0.85, 0.7)
	var mat: StandardMaterial3D = null
	var slab: MeshInstance3D = null
	var box: BoxMesh = null
	var lab: Label3D = null
	if get_node_or_null("Slab") != null:
		return
	mat = StandardMaterial3D.new()
	mat.albedo_color = col * 0.4
	mat.metallic = 0.5
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.05
	slab = MeshInstance3D.new()
	slab.name = "Slab"
	box = BoxMesh.new()
	box.size = Vector3(1.6, 0.28, 1.1)
	slab.mesh = box
	slab.material_override = mat
	slab.position.y = 0.16
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(slab)
	lab = Label3D.new()
	lab.name = "BenchLabel"
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 18
	lab.outline_size = 4
	lab.position = Vector3(0, 2.0, 0)
	lab.text = "%s\n%.0f %s · no cash" % [_SoftK.print_bench_label(), print_cost(), _wallet_name().to_upper()]
	add_child(lab)
