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
const KIND_STORAGE := "storage"

const BODY_NEX := "Nex-Prime"
const BODY_ROT := "ROT-Hive"
const BODY_SHARD := "Shard-Moon"

const _Prop := preload("res://scripts/assets/GlbProp.gd")
const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")

var orbit_body: String = BODY_NEX
var faction: String = "Cybernex"
var ownership: OwnershipData
var _modules: Array = []
var _factory: Node3D = null
var _hangar: Node3D = null
var _turret: Node3D = null
var _storage: Node3D = null
var _contest_ring: Node3D = null
var _contest_side: String = ""
var _status: String = "owned"


func _ready() -> void:
	_bind_meta()
	if not is_in_group("player_orbital_stations"):
		add_to_group("player_orbital_stations")
	_ensure_ownership()
	if get_node_or_null("DockModule") == null:
		setup(BODY_NEX, "Cybernex")


func setup(body: String = BODY_NEX, fac: String = "Cybernex") -> void:
	orbit_body = authored_body_id(body)
	faction = fac if fac != "" else "Cybernex"
	name = "PlayerOrbitalStation"
	_bind_meta()
	_ensure_ownership()
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


func hangar_stub() -> Node3D:
	## ST-K: orbital hangar stub. Not in the ST-E dock+habitat pair.
	if _hangar != null and is_instance_valid(_hangar) and _hangar.is_inside_tree():
		return _hangar
	var n: Node = get_node_or_null("OrbitalHangarStub")
	if n is Node3D:
		_hangar = n as Node3D
		return _hangar
	var _Builder = preload("res://scripts/world/BaseBuilder.gd")
	n = _Builder.orbital_hangar_stub_on(self)
	if n is Node3D:
		_hangar = n as Node3D
		return _hangar
	return null


func has_hangar_stub() -> bool:
	return hangar_stub() != null


func hangar_hud_line() -> String:
	## SoftKnowledge hangar stub label only. Never mass / queue / combat.
	if hangar_stub() == null:
		return ""
	return _SoftK.hangar_stub_label()


func ensure_hangar_stub() -> Node3D:
	## ST-K: one hangar stub in this player cluster. Not a third ST-E module.
	## Host authority. SoftKnowledge / HUD label only.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var _Builder = preload("res://scripts/world/BaseBuilder.gd")
	var n: Node3D = hangar_stub()
	if P0 == null or not bool(P0.ST_K_HANGAR):
		return null
	if not is_host_authority():
		return n
	if n != null:
		return n
	n = _Builder.place_orbital_hangar_stub(self, faction)
	if n != null:
		_hangar = n
		_refresh_label()
		print("[PlayerOrbitalStation] ST-K hangar stub in cluster body=", orbit_body, " site_pin=")
	return n


func defense_turret() -> Node3D:
	## ST-L: orbital defense turret. Not in the ST-E dock+habitat pair.
	if _turret != null and is_instance_valid(_turret) and _turret.is_inside_tree():
		return _turret
	var n: Node = get_node_or_null("OrbitalDefenseTurret")
	if n is Node3D:
		_turret = n as Node3D
		return _turret
	var _Builder = preload("res://scripts/world/BaseBuilder.gd")
	n = _Builder.orbital_turret_on(self)
	if n is Node3D:
		_turret = n as Node3D
		return _turret
	return null


func has_defense_turret() -> bool:
	return defense_turret() != null


func turret_hud_line() -> String:
	## SoftKnowledge turret label only. Never Pulse / HP / repair.
	if defense_turret() == null:
		return ""
	return _SoftK.turret_label()


func ensure_defense_turret() -> Node3D:
	## ST-L: one PadDefenseTurret in this player cluster. Not a third ST-E module.
	## Host authority. SoftKnowledge / HUD label only. Pulse 11.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var _Builder = preload("res://scripts/world/BaseBuilder.gd")
	var n: Node3D = defense_turret()
	if P0 == null or not bool(P0.ST_L_TURRET):
		return null
	if not is_host_authority():
		return n
	if n != null:
		return n
	n = _Builder.place_orbital_turret(self, faction)
	if n != null:
		_turret = n
		_refresh_label()
		print("[PlayerOrbitalStation] ST-L defense turret in cluster body=", orbit_body, " site_pin=")
	return n


func cluster_storage() -> Node3D:
	## ST-M: orbital storage. Not in the ST-E dock+habitat pair.
	if _storage != null and is_instance_valid(_storage) and _storage.is_inside_tree():
		return _storage
	var n: Node = get_node_or_null("OrbitalStorage")
	if n is Node3D:
		_storage = n as Node3D
		return _storage
	var _Builder = preload("res://scripts/world/BaseBuilder.gd")
	n = _Builder.orbital_storage_on(self)
	if n is Node3D:
		_storage = n as Node3D
		return _storage
	return null


func has_storage() -> bool:
	return cluster_storage() != null


func storage_hud_line() -> String:
	## SoftKnowledge storage label only. Never mass / value / cap.
	if cluster_storage() == null:
		return ""
	return _SoftK.storage_label()


func ensure_storage() -> Node3D:
	## ST-M: one PadStorage in this player cluster. Not a third ST-E module.
	## Host authority. SoftKnowledge / HUD label only.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var _Builder = preload("res://scripts/world/BaseBuilder.gd")
	var n: Node3D = cluster_storage()
	if P0 == null or not bool(P0.ST_M_STORAGE):
		return null
	if not is_host_authority():
		return n
	if n != null:
		return n
	n = _Builder.place_orbital_storage(self, faction)
	if n != null:
		_storage = n
		_refresh_label()
		print("[PlayerOrbitalStation] ST-M storage in cluster body=", orbit_body, " site_pin=")
	return n


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
		KIND_DOCK, KIND_HABITAT, KIND_FACTORY, KIND_DEFENSE, KIND_HANGAR, KIND_STORAGE:
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
	var own := ownership_state_label()
	var hang := hangar_hud_line()
	var tur := turret_hud_line()
	var store := storage_hud_line()
	var extras := PackedStringArray()
	if hang != "":
		extras.append(hang)
	if tur != "":
		extras.append(tur)
	if store != "":
		extras.append(store)
	if own != "":
		extras.append(own)
	if lab == null:
		lab = Label3D.new()
		lab.name = "ClusterLabel"
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.font_size = 18
		lab.outline_size = 4
		lab.position = Vector3(0.0, 6.0, 0.0)
		add_child(lab)
	if extras.size() > 0:
		lab.text = "%s\n%s · %s\n%s" % [_SoftK.orbital_station_label(), kinds, orbit_body, "\n".join(extras)]
	else:
		lab.text = "%s\n%s · %s" % [_SoftK.orbital_station_label(), kinds, orbit_body]


func start_contested_transition(to_faction: String = "") -> String:
	## DO-B: host starts Cybernex ↔ gROT contest on this cluster.
	## Same OwnershipData / ContestedRing grammar as DO-A. Not ST-F flip.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var dest := ""
	var cur := ""
	if P0 == null or not bool(P0.DO_B_OWNERSHIP):
		return ""
	if not is_host_authority():
		return ""
	_ensure_ownership()
	if ownership == null:
		return ""
	cur = ownership.faction_name()
	dest = to_faction
	if dest == "":
		dest = "gROT" if cur == "Cybernex" else "Cybernex"
	if dest != "Cybernex" and dest != "gROT":
		return ""
	if dest == cur:
		dest = "gROT" if cur == "Cybernex" else "Cybernex"
	if ownership.current_faction == OwnershipData.Faction.CONTESTED:
		_contest_side = dest
		_status = "contested"
		_set_contested_ring(true)
		_ensure_do_b_component()
		_refresh_label()
		return "Contested"
	if not ownership.is_fully_owned():
		var hold: OwnershipData.Faction = OwnershipData.from_string(cur)
		if hold != OwnershipData.Faction.CYBERNEX and hold != OwnershipData.Faction.GROT:
			hold = OwnershipData.Faction.CYBERNEX
		_lock_to(hold)
		ownership.transition_progress = 1.0
		_status = "owned"
	ownership.start_transition(OwnershipData.Faction.CONTESTED)
	_contest_side = dest
	ownership.claim_strength = maxf(ownership.claim_strength, 0.2)
	_status = "contested"
	_set_contested_ring(true)
	_refresh_label()
	_ensure_do_b_component()
	print("[PlayerOrbitalStation] DO-B contest ", ownership.previous_faction, " vs ", dest)
	return "Contested"


func advance_contested_transition(delta: float = 0.25, duration: float = 5.0) -> float:
	## DO-B: host advances OwnershipData.transition_progress on the cluster.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var step := maxf(delta, 0.0)
	var dur := maxf(duration, 0.01)
	if P0 == null or not bool(P0.DO_B_OWNERSHIP):
		return -1.0
	if not is_host_authority():
		return -1.0
	_ensure_ownership()
	if ownership == null:
		return -1.0
	if ownership.current_faction != OwnershipData.Faction.CONTESTED:
		return ownership.transition_progress
	ownership.advance_transition(step, dur)
	if _contest_side != "":
		ownership.claim_strength = clampf(
			ownership.claim_strength + maxf(step * 0.15, 0.02), 0.0, 1.75)
	_set_contested_ring(true)
	_refresh_label()
	_ensure_do_b_component()
	return ownership.transition_progress


func lock_owned(to_faction: String = "Cybernex") -> String:
	## Resolve a DO-B contest back to a held CX/GR owner. ST-E/ST-G stay.
	var dest := to_faction
	var f: OwnershipData.Faction = OwnershipData.Faction.CYBERNEX
	_ensure_ownership()
	if dest != "Cybernex" and dest != "gROT":
		dest = "Cybernex"
	f = OwnershipData.from_string(dest)
	_lock_to(f)
	_status = "owned"
	_contest_side = ""
	_set_contested_ring(false)
	_refresh_label()
	return ownership.faction_name() if ownership else dest


func get_faction() -> String:
	if ownership != null:
		return ownership.faction_name()
	return faction


func ownership_state_label() -> String:
	## SoftKnowledge CONTESTED / CYBERNEX / GROT. Never DPS / yield / Pulse / Hack.
	return _SoftK.ownership_state_label(get_faction())


func hud_ownership_line() -> String:
	return ownership_state_label()


func contested_ring_active() -> bool:
	if _contest_ring == null or not is_instance_valid(_contest_ring):
		return false
	if "active" in _contest_ring:
		return bool(_contest_ring.active)
	return _status == "contested"


func transition_progress() -> float:
	if ownership == null:
		return 0.0
	return float(ownership.transition_progress)


func is_host_authority() -> bool:
	if multiplayer == null or not multiplayer.has_multiplayer_peer():
		return true
	return multiplayer.is_server()


func ownership_component() -> Node:
	return _ensure_do_b_component()


func _ensure_ownership() -> void:
	var hold: OwnershipData.Faction = OwnershipData.from_string(faction)
	if ownership == null:
		ownership = OwnershipData.new()
		ownership.object_id = "PlayerOrbitalStation/%s" % orbit_body
		if hold != OwnershipData.Faction.CYBERNEX and hold != OwnershipData.Faction.GROT:
			hold = OwnershipData.Faction.CYBERNEX
		ownership.current_faction = hold
		ownership.previous_faction = hold
		ownership.transition_progress = 1.0
		ownership.claim_strength = 1.75
	_ensure_contest_ring()


func _lock_to(f: OwnershipData.Faction) -> void:
	if ownership == null:
		ownership = OwnershipData.new()
		ownership.object_id = "PlayerOrbitalStation/%s" % orbit_body
	ownership.previous_faction = ownership.current_faction
	ownership.current_faction = f
	ownership.transition_progress = 1.0
	ownership.claim_strength = 1.75
	if f == OwnershipData.Faction.GROT:
		faction = "gROT"
	elif f == OwnershipData.Faction.CYBERNEX:
		faction = "Cybernex"


func _ensure_contest_ring() -> void:
	if _contest_ring != null and is_instance_valid(_contest_ring):
		return
	var n: Node = get_node_or_null("ContestedRing")
	if n is Node3D:
		_contest_ring = n as Node3D
		return
	_contest_ring = Node3D.new()
	_contest_ring.set_script(preload("res://scripts/world/ContestedRing.gd"))
	_contest_ring.name = "ContestedRing"
	add_child(_contest_ring)


func _set_contested_ring(on: bool) -> void:
	_ensure_contest_ring()
	if _contest_ring and _contest_ring.has_method("set_contested"):
		var stren := ownership.claim_strength if ownership else 0.0
		_contest_ring.set_contested(on, stren)


func _ensure_do_b_component() -> Node:
	var n: Node = get_node_or_null("OwnershipComponent")
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.DO_B_OWNERSHIP):
		return n
	if n != null and is_instance_valid(n):
		if "data" in n:
			n.data = ownership
		if "claimable" in n:
			n.claimable = false
		return n
	n = Node3D.new()
	n.set_script(preload("res://scripts/ownership/OwnershipComponent.gd"))
	n.name = "OwnershipComponent"
	add_child(n)
	if "data" in n:
		n.data = ownership
	if "claimable" in n:
		n.claimable = false
	return n
