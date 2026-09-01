extends Node3D
class_name PlayerOrbitalStation
## ST-E §5 / §9: player-owned orbital cluster of two catalog modules.
## Orbit of an authored ARK body (Nex-Prime / ROT-Hive / Shard-Moon).
## Not a city. Not SITE_*. Not P0Slice.ORBITAL_STATIONS unnamed props.

const KIND_DOCK := "dock"
const KIND_HABITAT := "habitat"
const KIND_FACTORY := "factory"
const KIND_DEFENSE := "defense"
const KIND_HANGAR := "hangar"

const BODY_NEX := "Nex-Prime"
const BODY_ROT := "ROT-Hive"
const BODY_SHARD := "Shard-Moon"

const _Prop := preload("res://scripts/assets/GlbProp.gd")
const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")

var orbit_body: String = BODY_NEX
var faction: String = "Cybernex"
var _modules: Array = []
var _factory: Node3D = null


func _ready() -> void:
	_bind_meta()
	if not is_in_group("player_orbital_stations"):
		add_to_group("player_orbital_stations")
	if get_node_or_null("DockModule") == null:
		setup(BODY_NEX, "Cybernex")


func setup(body: String = BODY_NEX, fac: String = "Cybernex") -> void:
	orbit_body = authored_body_id(body)
	faction = fac if fac != "" else "Cybernex"
	name = "PlayerOrbitalStation"
	_bind_meta()
	if module_count() >= 2:
		_refresh_label()
		return
	_spawn_module(KIND_DOCK, Vector3(-14.0, 0.0, 0.0))
	_spawn_module(KIND_HABITAT, Vector3(14.0, 0.4, 0.0))
	_refresh_label()
	print("[PlayerOrbitalStation] cluster modules=2 kinds=dock,habitat body=", orbit_body, " city=false site_pin=")


func _bind_meta() -> void:
	set_meta("site_pin", "")
	set_meta("player_orbital_station", true)
	set_meta("player_owned", true)
	set_meta("orbital_cluster", true)
	set_meta("city", false)
	set_meta("orbit_body", orbit_body)


func authored_body() -> String:
	return orbit_body


func is_city() -> bool:
	return false


func module_count() -> int:
	var n := 0
	for m in _modules:
		if m != null and is_instance_valid(m):
			n += 1
	return n


func module_kinds() -> PackedStringArray:
	var out := PackedStringArray()
	for m in _modules:
		if m != null and is_instance_valid(m):
			out.append(str(m.get_meta("module_type", "")))
	return out


func cluster_modules() -> Array:
	var out: Array = []
	for m in _modules:
		if m != null and is_instance_valid(m):
			out.append(m)
	return out


func factory_module() -> Node3D:
	## ST-G: factory lives in this cluster, not in the ST-E dock+habitat pair.
	if _factory != null and is_instance_valid(_factory) and _factory.is_inside_tree():
		return _factory
	var n: Node = get_node_or_null("FactoryModule")
	if n is Node3D:
		_factory = n as Node3D
		return _factory
	return null


func has_factory() -> bool:
	return factory_module() != null


func ensure_factory() -> Node3D:
	## ST-G §6(c): one factory in this player cluster. Not a third ST-E module.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var n: Node3D = factory_module()
	if P0 == null or not bool(P0.ST_G_FACTORY):
		return null
	if n != null:
		return n
	n = _spawn_factory(Vector3(0.0, 0.2, -16.0))
	_refresh_label()
	print("[PlayerOrbitalStation] ST-G factory in cluster body=", orbit_body, " site_pin=")
	return n


static func is_grammar_kind(kind: String) -> bool:
	match kind:
		KIND_DOCK, KIND_HABITAT, KIND_FACTORY, KIND_DEFENSE, KIND_HANGAR:
			return true
		_:
			return false


static func is_authored_ark_body(body: String) -> bool:
	match body:
		BODY_NEX, BODY_ROT, BODY_SHARD:
			return true
		_:
			return false


static func authored_body_id(body: String) -> String:
	if is_authored_ark_body(body):
		return body
	return BODY_NEX


func _spawn_module(kind: String, offset: Vector3) -> Node3D:
	var k := kind
	var n := Node3D.new()
	if not is_grammar_kind(k):
		k = KIND_HABITAT
	n.name = "DockModule" if k == KIND_DOCK else "HabitatModule"
	n.set_meta("site_pin", "")
	n.set_meta("orbital_module", true)
	n.set_meta("module_type", k)
	n.set_meta("player_module", false)
	n.set_meta("npc_module", false)
	n.set_meta("printed_module", false)
	n.set_meta("hangar_queued", false)
	n.set_meta("combat_stats", 0)
	n.set_meta("city", false)
	if not n.is_in_group("player_orbital_modules"):
		n.add_to_group("player_orbital_modules")
	add_child(n)
	n.position = offset
	_attach_catalog_mesh(n, k)
	_modules.append(n)
	return n


func _spawn_factory(offset: Vector3) -> Node3D:
	## Same cluster as ST-E. Own group so ST-E still counts dock+habitat only.
	var n := Node3D.new()
	n.name = "FactoryModule"
	n.set_meta("site_pin", "")
	n.set_meta("orbital_module", false)
	n.set_meta("factory_module", true)
	n.set_meta("module_type", KIND_FACTORY)
	n.set_meta("player_module", false)
	n.set_meta("npc_module", false)
	n.set_meta("printed_module", false)
	n.set_meta("hangar_queued", false)
	n.set_meta("factory_printed", false)
	n.set_meta("combat_stats", 0)
	n.set_meta("city", false)
	if not n.is_in_group("player_factory_modules"):
		n.add_to_group("player_factory_modules")
	add_child(n)
	n.position = offset
	_attach_catalog_mesh(n, KIND_FACTORY)
	_label_factory(n)
	_factory = n
	return n


func print_one_factory_module(kind: String = "", cash: float = 0.0) -> Node3D:
	## ST-G / NP-I §6(c) via the existing PadPrintBench spend path.
	var tree := get_tree()
	if tree:
		for b in tree.get_nodes_in_group("print_benches"):
			if b != null and b.has_method("print_one_factory_module"):
				return b.print_one_factory_module(kind, cash)
	return null


func _label_factory(host: Node3D) -> void:
	var lab := Label3D.new()
	lab.name = "FactoryLabel"
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 16
	lab.outline_size = 4
	lab.position = Vector3(0.0, 3.2, 0.0)
	lab.text = _SoftK.factory_label()
	host.add_child(lab)


func _attach_catalog_mesh(host: Node3D, kind: String) -> void:
	## Existing catalog paths only. GlbProp already proxies on headless.
	var fx := "cybernex" if faction != "gROT" else "grot"
	var prop := Node3D.new()
	var rel := "colony/colony_habitat/colony_habitat_%s_lod1.glb" % fx
	var scale := 2.2
	prop.set_script(_Prop)
	if kind == KIND_DOCK:
		rel = "environments/landing_pad/landing_pad_%s_lod1.glb" % fx
		scale = 1.6
	elif kind == KIND_FACTORY:
		rel = "colony/extractor_unit/extractor_unit_%s_lod1.glb" % fx
		scale = 1.4
	prop.set("relative_path", rel)
	prop.set("scale_factor", scale)
	prop.set("add_static_collision", false)
	prop.name = "CatalogMesh"
	host.add_child(prop)


func _refresh_label() -> void:
	var lab: Label3D = get_node_or_null("ClusterLabel") as Label3D
	var kinds := ",".join(module_kinds())
	if lab == null:
		lab = Label3D.new()
		lab.name = "ClusterLabel"
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.font_size = 18
		lab.outline_size = 4
		lab.position = Vector3(0.0, 6.0, 0.0)
		add_child(lab)
	lab.text = "%s\n%s · %s" % [_SoftK.orbital_station_label(), kinds, orbit_body]
