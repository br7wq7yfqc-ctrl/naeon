extends RefCounted
class_name BaseBuilder
## Streams HQ colony props onto a landing pad + PadBaseController (claim/harvest).

const _AP = preload("res://scripts/assets/AssetPaths.gd")
const _Prop = preload("res://scripts/assets/GlbProp.gd")
const _PadCtrl = preload("res://scripts/world/PadBaseController.gd")

static func build_on_pad(pad: Node3D, faction: String) -> void:
	if pad == null or not is_instance_valid(pad):
		return
	if pad.has_meta("base_built") and pad.get_meta("base_built"):
		return
	pad.set_meta("base_built", true)
	pad.set_meta("base_faction", faction)
	var p0 := load("res://scripts/world/P0Slice.gd")
	if p0 and bool(p0.ACTIVE) and bool(p0.ONE_PAD):
		var ctrl0 := Node3D.new()
		ctrl0.set_script(_PadCtrl)
		ctrl0.set("default_faction", faction)
		ctrl0.name = "PadBaseController"
		var root0 := Node3D.new()
		root0.name = "BaseCluster"
		pad.add_child(root0)
		root0.add_child(ctrl0)
		print("[BaseBuilder] P0 controller only on ", pad.name)
		return
	var fx := "cybernex" if faction != "gROT" else "grot"
	var layout: Array = [
		{"rel": "colony/colony_habitat/colony_habitat_%s_lod1.glb" % fx, "pos": Vector3(0, 1.2, -14), "s": 2.2, "id": "habitat"},
		{"rel": "colony/extractor_unit/extractor_unit_%s_lod1.glb" % fx, "pos": Vector3(12, 1.0, 4), "s": 1.4, "id": "extractor"},
		{"rel": "props/turret_emplacement/turret_emplacement_%s_lod1.glb" % fx, "pos": Vector3(-12, 1.0, 4), "s": 1.3, "id": "turret"},
		{"rel": "props/claim_beacon/claim_beacon_%s_lod1.glb" % fx, "pos": Vector3(0, 1.0, 10), "s": 1.1, "id": "beacon"},
		{"rel": "props/control_console/control_console_%s_lod1.glb" % fx, "pos": Vector3(6, 1.0, -6), "s": 1.0, "id": "console"},
		{"rel": "props/med_station/med_station_%s_lod1.glb" % fx, "pos": Vector3(-6, 1.0, -6), "s": 1.0, "id": "med"},
		{"rel": "props/energy_barrier/energy_barrier_%s_lod2.glb" % fx, "pos": Vector3(0, 1.5, 16), "s": 1.6, "id": "barrier"},
		{"rel": "colony/resource_crystal/resource_crystal_%s_lod2.glb" % fx, "pos": Vector3(9, 1.0, -10), "s": 0.9, "id": "crystal"},
	]
	var root := Node3D.new()
	root.name = "BaseCluster"
	pad.add_child(root)
	for e in layout:
		var rel: String = str(e["rel"])
		var path: String = _AP.resolve(rel)
		if path == "" or not FileAccess.file_exists(path):
			rel = rel.replace("_lod1.glb", "_lod2.glb")
			path = _AP.resolve(rel)
		if path == "" or not FileAccess.file_exists(path):
			continue
		var prop: Node3D = Node3D.new()
		prop.set_script(_Prop)
		prop.set("relative_path", rel)
		prop.set("scale_factor", float(e["s"]))
		prop.set("add_static_collision", true)
		prop.name = str(e["id"])
		root.add_child(prop)
		prop.position = e["pos"]

	# Interactive controller at pad center
	var ctrl := Node3D.new()
	ctrl.set_script(_PadCtrl)
	ctrl.set("default_faction", faction)
	ctrl.name = "PadBaseController"
	root.add_child(ctrl)
	print("[BaseBuilder] cluster+controller on ", pad.name, " faction=", faction)


static func is_unnamed_pad(pad: Node) -> bool:
	if pad == null:
		return false
	return str(pad.name) in ["Pad_North", "Pad_Approach", "Pad_Flank"]


static func player_module_on(pad: Node3D) -> Node3D:
	if pad == null or not is_instance_valid(pad):
		return null
	for c in pad.get_children():
		if c is Node3D and c.has_meta("player_module") and bool(c.get_meta("player_module")):
			return c as Node3D
	return pad.find_child("PlayerHabitat", true, false) as Node3D


static func npc_module_on(pad: Node3D) -> Node3D:
	if pad == null or not is_instance_valid(pad):
		return null
	for c in pad.get_children():
		if c is Node3D and c.has_meta("npc_module") and bool(c.get_meta("npc_module")):
			return c as Node3D
	return pad.find_child("NpcHabitat", true, false) as Node3D


static func pad_has_player_module(pad: Node3D) -> bool:
	return module_on(pad) != null


static func module_on(pad: Node3D) -> Node3D:
	var p := player_module_on(pad)
	if p != null:
		return p
	return npc_module_on(pad)


static func pad_has_module(pad: Node3D) -> bool:
	return module_on(pad) != null


static func printed_module_on(pad: Node3D) -> Node3D:
	var kids: Array = []
	if pad == null or not is_instance_valid(pad):
		return null
	kids = pad.get_children()
	for c in kids:
		if c is Node3D and c.has_meta("printed_module") and bool(c.get_meta("printed_module")):
			return c as Node3D
	return pad.find_child("PrintedExtractor", true, false) as Node3D


static func print_catalog_module(pad: Node3D, faction: String, kind: String = "extractor") -> Node3D:
	## ST-C / NP-G: one catalog habitat or extractor after a wallet spend. Not SITE_*.
	var n: Node3D = null
	var k := kind
	if pad == null or not is_instance_valid(pad):
		return null
	if not is_unnamed_pad(pad):
		return null
	if printed_module_on(pad) != null:
		return null
	if k != "habitat" and k != "extractor":
		k = "extractor"
	n = Node3D.new()
	n.set_script(preload("res://scripts/world/PlayerBaseModule.gd"))
	n.name = "PrintedHabitat" if k == "habitat" else "PrintedExtractor"
	n.set_meta("site_pin", "")
	pad.add_child(n)
	n.position = Vector3(-10.0, 1.2, -8.0) if k == "extractor" else Vector3(0.0, 2.6, 12.0)
	if n.has_method("setup_printed"):
		n.setup_printed(faction, k)
	print("[BaseBuilder] printed ", k, " on ", pad.name, " faction=", faction)
	return n


static func print_factory_catalog_module(cluster: Node3D, faction: String, kind: String = "extractor") -> Node3D:
	## ST-G / NP-I §6(c): one catalog module at the player factory cluster. Not SITE_*.
	## Separate slot from ST-C printed_base_modules.
	var n: Node3D = null
	var k := kind
	if cluster == null or not is_instance_valid(cluster):
		return null
	if factory_printed_on(cluster) != null:
		return null
	if k != "habitat" and k != "extractor":
		k = "extractor"
	n = Node3D.new()
	n.set_script(preload("res://scripts/world/PlayerBaseModule.gd"))
	n.name = "FactoryPrintedHabitat" if k == "habitat" else "FactoryPrintedExtractor"
	n.set_meta("site_pin", "")
	cluster.add_child(n)
	n.position = Vector3(0.0, 0.4, 16.0) if k == "extractor" else Vector3(10.0, 0.4, 12.0)
	if n.has_method("setup_factory_printed"):
		n.setup_factory_printed(faction, k)
	print("[BaseBuilder] factory printed ", k, " on ", cluster.name, " faction=", faction)
	return n


static func factory_printed_on(cluster: Node3D) -> Node3D:
	var kids: Array = []
	if cluster == null or not is_instance_valid(cluster):
		return null
	kids = cluster.get_children()
	for c in kids:
		if c is Node3D and c.has_meta("factory_printed") and bool(c.get_meta("factory_printed")):
			return c as Node3D
	return cluster.find_child("FactoryPrintedExtractor", true, false) as Node3D


static func pad_turret_on(pad: Node3D) -> Node3D:
	if pad == null or not is_instance_valid(pad):
		return null
	var existing: Node = pad.get_node_or_null("PadDefenseTurret")
	if existing is Node3D:
		return existing as Node3D
	for c in pad.get_children():
		if c is Node3D and c.has_meta("pad_turret") and bool(c.get_meta("pad_turret")):
			return c as Node3D
	return pad.find_child("PadDefenseTurret", true, false) as Node3D


static func place_pad_turret(pad: Node3D, faction: String) -> Node3D:
	## ST-H: one defense turret after occupy. Not Clash Turret.gd / OUTER 160.
	var n: Node3D = null
	if pad == null or not is_instance_valid(pad):
		return null
	if not is_unnamed_pad(pad):
		return null
	n = pad_turret_on(pad)
	if n != null:
		return n
	n = Node3D.new()
	n.set_script(preload("res://scripts/world/PadDefenseTurret.gd"))
	n.name = "PadDefenseTurret"
	n.set_meta("site_pin", "")
	n.set_meta("player_module", false)
	pad.add_child(n)
	# Off ST-A habitat (8, 2.6, 6), NP-C (-8, 2.6, 6), ST-B extractor (10, 1.2, -8),
	# ST-C bench (0, 0.35, 12). Matches the HQ cluster turret slot.
	n.position = Vector3(-12.0, 1.2, 4.0)
	if n.has_method("setup"):
		n.setup(faction)
	print("[BaseBuilder] pad turret on ", pad.name, " faction=", faction)
	_pc_a_remember_pad(pad, "turret", faction)
	return n


static func pad_storage_on(pad: Node3D) -> Node3D:
	if pad == null or not is_instance_valid(pad):
		return null
	var existing: Node = pad.get_node_or_null("PadStorage")
	if existing is Node3D:
		return existing as Node3D
	for c in pad.get_children():
		if c is Node3D and c.has_meta("pad_storage") and bool(c.get_meta("pad_storage")):
			return c as Node3D
	return pad.find_child("PadStorage", true, false) as Node3D


static func place_pad_storage(pad: Node3D, faction: String) -> Node3D:
	## ST-I: one storage crate/hold after occupy. Cap 1 crate. Not a ship CargoHold.
	var n: Node3D = null
	if pad == null or not is_instance_valid(pad):
		return null
	if not is_unnamed_pad(pad):
		return null
	n = pad_storage_on(pad)
	if n != null:
		return n
	n = Node3D.new()
	n.set_script(preload("res://scripts/world/PadStorage.gd"))
	n.name = "PadStorage"
	n.set_meta("site_pin", "")
	n.set_meta("player_module", false)
	pad.add_child(n)
	# Off ST-A habitat (8, 2.6, 6), NP-C (-8, 2.6, 6), ST-B extractor (10, 1.2, -8),
	# ST-C bench (0, 0.35, 12), ST-H turret (-12, 1.2, 4).
	n.position = Vector3(12.0, 1.2, 10.0)
	if n.has_method("setup"):
		n.setup(faction)
	print("[BaseBuilder] pad storage on ", pad.name, " faction=", faction)
	_pc_a_remember_pad(pad, "storage", faction)
	return n


static func pad_hangar_stub_on(pad: Node3D) -> Node3D:
	if pad == null or not is_instance_valid(pad):
		return null
	var existing: Node = pad.get_node_or_null("PadHangarStub")
	if existing is Node3D:
		return existing as Node3D
	for c in pad.get_children():
		if c is Node3D and c.has_meta("pad_hangar_stub") and bool(c.get_meta("pad_hangar_stub")):
			return c as Node3D
	return pad.find_child("PadHangarStub", true, false) as Node3D


static func place_pad_hangar_stub(pad: Node3D, faction: String) -> Node3D:
	## ST-J: one hangar stub after occupy. Not ST-D carrier hangar queue.
	var n: Node3D = null
	if pad == null or not is_instance_valid(pad):
		return null
	if not is_unnamed_pad(pad):
		return null
	n = pad_hangar_stub_on(pad)
	if n != null:
		return n
	n = Node3D.new()
	n.set_script(preload("res://scripts/world/PadHangarStub.gd"))
	n.name = "PadHangarStub"
	n.set_meta("site_pin", "")
	n.set_meta("player_module", false)
	pad.add_child(n)
	# Off ST-A habitat (8, 2.6, 6), NP-C (-8, 2.6, 6), ST-B extractor (10, 1.2, -8),
	# ST-C bench (0, 0.35, 12), ST-H turret (-12, 1.2, 4), ST-I storage (12, 1.2, 10).
	n.position = Vector3(-6.0, 1.2, -12.0)
	if n.has_method("setup"):
		n.setup(faction)
	print("[BaseBuilder] pad hangar stub on ", pad.name, " faction=", faction)
	_pc_a_remember_pad(pad, "hangar", faction)
	return n


static func orbital_hangar_stub_on(cluster: Node3D) -> Node3D:
	if cluster == null or not is_instance_valid(cluster):
		return null
	var existing: Node = cluster.get_node_or_null("OrbitalHangarStub")
	if existing is Node3D:
		return existing as Node3D
	for c in cluster.get_children():
		if c is Node3D and c.has_meta("orbital_hangar_stub") and bool(c.get_meta("orbital_hangar_stub")):
			return c as Node3D
	return cluster.find_child("OrbitalHangarStub", true, false) as Node3D


static func place_orbital_hangar_stub(cluster: Node3D, faction: String) -> Node3D:
	## ST-K: one hangar stub on the existing PlayerOrbitalStation.
	## Same PadHangarStub grammar as ST-J. Not ST-D carrier hangar.
	var n: Node3D = null
	if cluster == null or not is_instance_valid(cluster):
		return null
	if not bool(cluster.get_meta("player_orbital_station", false)):
		return null
	n = orbital_hangar_stub_on(cluster)
	if n != null:
		return n
	n = Node3D.new()
	n.set_script(preload("res://scripts/world/PadHangarStub.gd"))
	n.name = "OrbitalHangarStub"
	n.set_meta("site_pin", "")
	n.set_meta("player_module", false)
	cluster.add_child(n)
	# Off ST-E dock (-14,0,0) / habitat (14,0.4,0) and ST-G factory (0,0.2,-16).
	n.position = Vector3(0.0, 0.2, 16.0)
	if n.has_method("setup_orbital"):
		n.setup_orbital(faction)
	print("[BaseBuilder] orbital hangar stub on ", cluster.name, " faction=", faction)
	_pc_a_remember_orbital("hangar", faction)
	return n


static func orbital_turret_on(cluster: Node3D) -> Node3D:
	if cluster == null or not is_instance_valid(cluster):
		return null
	var existing: Node = cluster.get_node_or_null("OrbitalDefenseTurret")
	if existing is Node3D:
		return existing as Node3D
	for c in cluster.get_children():
		if c is Node3D and c.has_meta("orbital_turret") and bool(c.get_meta("orbital_turret")):
			return c as Node3D
	return cluster.find_child("OrbitalDefenseTurret", true, false) as Node3D


static func place_orbital_turret(cluster: Node3D, faction: String) -> Node3D:
	## ST-L: one defense turret on the existing PlayerOrbitalStation.
	## Same PadDefenseTurret grammar as ST-H. Not Clash Turret.gd.
	var n: Node3D = null
	if cluster == null or not is_instance_valid(cluster):
		return null
	if not bool(cluster.get_meta("player_orbital_station", false)):
		return null
	n = orbital_turret_on(cluster)
	if n != null:
		return n
	n = Node3D.new()
	n.set_script(preload("res://scripts/world/PadDefenseTurret.gd"))
	n.name = "OrbitalDefenseTurret"
	n.set_meta("site_pin", "")
	n.set_meta("player_module", false)
	cluster.add_child(n)
	# Off ST-E dock (-14,0,0) / habitat (14,0.4,0), ST-G factory (0,0.2,-16),
	# ST-K hangar (0,0.2,16).
	n.position = Vector3(-16.0, 0.4, 12.0)
	if n.has_method("setup_orbital"):
		n.setup_orbital(faction)
	print("[BaseBuilder] orbital turret on ", cluster.name, " faction=", faction)
	_pc_a_remember_orbital("turret", faction)
	return n


static func orbital_storage_on(cluster: Node3D) -> Node3D:
	if cluster == null or not is_instance_valid(cluster):
		return null
	var existing: Node = cluster.get_node_or_null("OrbitalStorage")
	if existing is Node3D:
		return existing as Node3D
	for c in cluster.get_children():
		if c is Node3D and c.has_meta("orbital_storage") and bool(c.get_meta("orbital_storage")):
			return c as Node3D
	return cluster.find_child("OrbitalStorage", true, false) as Node3D


static func place_orbital_storage(cluster: Node3D, faction: String) -> Node3D:
	## ST-M: one PadStorage on the existing PlayerOrbitalStation.
	## Same PadStorage grammar as ST-I. Not a ship CargoHold.
	var n: Node3D = null
	if cluster == null or not is_instance_valid(cluster):
		return null
	if not bool(cluster.get_meta("player_orbital_station", false)):
		return null
	n = orbital_storage_on(cluster)
	if n != null:
		return n
	n = Node3D.new()
	n.set_script(preload("res://scripts/world/PadStorage.gd"))
	n.name = "OrbitalStorage"
	n.set_meta("site_pin", "")
	n.set_meta("player_module", false)
	cluster.add_child(n)
	# Off ST-E dock (-14,0,0) / habitat (14,0.4,0), ST-G factory (0,0.2,-16),
	# ST-K hangar (0,0.2,16), ST-L turret (-16,0.4,12).
	n.position = Vector3(16.0, 0.4, 12.0)
	if n.has_method("setup_orbital"):
		n.setup_orbital(faction)
	print("[BaseBuilder] orbital storage on ", cluster.name, " faction=", faction)
	_pc_a_remember_orbital("storage", faction)
	return n


static func place_player_habitat(pad: Node3D, faction: String) -> Node3D:
	## ST-A: one habitat, code-first. Not a SITE_*, not the OS-G silhouette.
	return _place_habitat(pad, faction, false)


static func place_npc_habitat(pad: Node3D, faction: String) -> Node3D:
	## NP-C: one habitat by the visitor. Same mesh, other pad slot. Not SITE_*.
	return _place_habitat(pad, faction, true)


static func _place_habitat(pad: Node3D, faction: String, by_npc: bool) -> Node3D:
	var n: Node3D = null
	if pad == null or not is_instance_valid(pad):
		return null
	if not is_unnamed_pad(pad):
		return null
	if pad_has_module(pad):
		return null
	n = Node3D.new()
	n.set_script(preload("res://scripts/world/PlayerBaseModule.gd"))
	n.name = "NpcHabitat" if by_npc else "PlayerHabitat"
	n.set_meta("site_pin", "")
	pad.add_child(n)
	n.position = Vector3(-8.0, 2.6, 6.0) if by_npc else Vector3(8.0, 2.6, 6.0)
	if by_npc and n.has_method("setup_npc"):
		n.setup_npc(faction)
	elif n.has_method("setup"):
		n.setup(faction)
	print("[BaseBuilder] ", "npc" if by_npc else "player", " habitat on ", pad.name, " faction=", faction)
	if not by_npc:
		_pc_a_remember_pad(pad, "habitat", faction)
	return n


static func _pc_a_on() -> bool:
	var p0 := load("res://scripts/world/P0Slice.gd")
	return p0 != null and bool(p0.PC_A_PERSIST)


static func _pc_a_session():
	var tree := Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return null
	return (tree as SceneTree).root.get_node_or_null("/root/SoftSession")


static func _pc_a_remember_pad(pad: Node3D, kind: String, faction: String) -> void:
	if not _pc_a_on():
		return
	var sess = _pc_a_session()
	if sess != null and sess.has_method("remember_pad_module"):
		sess.remember_pad_module(pad, kind, faction)


static func _pc_a_remember_orbital(kind: String, faction: String) -> void:
	if not _pc_a_on():
		return
	var sess = _pc_a_session()
	if sess != null and sess.has_method("remember_orbital_module"):
		sess.remember_orbital_module(kind, faction)
