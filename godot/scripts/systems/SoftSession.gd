extends Node
## Soft local session persist — form/faction/layer + last legal action.
## NP-F: player leave starts a short local offline cycle. Not combat power. Not P2W.
## PC-A: pad/orbital player modules + ship across relaunch. Same user:// file.
## PC-B: one crate (amount/slug) for PadStorage / CargoHold. Same file.
## PC-C: ONE hangar insurance record (ST-J/ST-K stub; optional ST-D queue).
## SoftKnowledge / HUD only. Host authority. Never Pulse / kit / P2W.

signal offline_changed(offline: bool)

const PATH := "user://soft_session.json"
const LEGAL_ACTIONS := ["occupy", "harvest", "invite", "form", "faction"]
const WS_DAILY_CAP := 60.0
const LEGAL_PADS := ["Pad_North", "Pad_Approach", "Pad_Flank"]
const LEGAL_PAD_KINDS := ["habitat", "turret", "storage", "hangar"]
const LEGAL_ORBITAL_KINDS := ["hangar", "turret", "storage"]
const LEGAL_CRATE_WHERE := ["pad", "orbital", "ship"]
const LEGAL_HANGAR_WHERE := ["pad", "orbital", "queue"]
const LEGAL_HANGAR_KINDS := ["hangar_stub", "queue"]
const LEGAL_QUEUE_KINDS := ["sensor", "extractor", "engine", "cargo"]
const PC_B_SLUG := "pc_b_crate"

var form: String = "Canine"
var faction: String = "Cybernex"
var last_layer: String = "Space"
var last_action: String = ""
var quest: Dictionary = {}
var alliance_quest: Dictionary = {}
var war_score_daily: float = 0.0
var war_score_day: String = ""
var clash_result: String = ""
var clash_ws_granted: float = 0.0
var clash_cosmetic: bool = false
var colony: Array = []
var orbital: Array = []
var ship: Dictionary = {}
var crate: Dictionary = {}
var hangar: Dictionary = {}
var _offline: bool = false

func _ready() -> void:
	load_session()

func load_session() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	form = str(data.get("form", form))
	faction = str(data.get("faction", faction))
	last_layer = str(data.get("last_layer", last_layer))
	var act := str(data.get("last_action", last_action))
	if LEGAL_ACTIONS.has(act):
		last_action = act
	var q = data.get("quest", {})
	if typeof(q) == TYPE_DICTIONARY:
		quest = q
	var aq = data.get("alliance_quest", {})
	if typeof(aq) == TYPE_DICTIONARY:
		alliance_quest = aq
	war_score_day = str(data.get("war_score_day", war_score_day))
	war_score_daily = clampf(float(data.get("war_score_daily", war_score_daily)), 0.0, WS_DAILY_CAP)
	clash_result = str(data.get("clash_result", clash_result))
	clash_ws_granted = float(data.get("clash_ws_granted", clash_ws_granted))
	clash_cosmetic = bool(data.get("clash_cosmetic", clash_cosmetic))
	_ingest_colony(data.get("colony", []))
	_ingest_orbital(data.get("orbital", []))
	_ingest_ship(data.get("ship", {}))
	_ingest_crate(data.get("crate", {}))
	_ingest_hangar(data.get("hangar", {}))
	_roll_ws_day()
	print("[SoftSession] loaded form=", form, " faction=", faction, " ws=", war_score_daily, "/", WS_DAILY_CAP,
		" colony=", colony.size(), " orbital=", orbital.size(), " ship=", str(ship.get("faction", "")),
		" crate=", str(crate.get("slug", "")), " hangar=", str(hangar.get("where", "")))

func save_session() -> void:
	var payload := {
		"form": form,
		"faction": faction,
		"last_layer": last_layer,
		"last_action": last_action,
		"quest": quest,
		"alliance_quest": alliance_quest,
		"war_score_day": war_score_day,
		"war_score_daily": war_score_daily,
		"clash_result": clash_result,
		"clash_ws_granted": clash_ws_granted,
		"clash_cosmetic": clash_cosmetic,
		"saved_at": Time.get_datetime_string_from_system(true),
	}
	if _pc_a():
		payload["colony"] = colony
		payload["orbital"] = orbital
		payload["ship"] = ship
	if _pc_b():
		payload["crate"] = crate
	if _pc_c():
		payload["hangar"] = hangar
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()

func remember_quest(q: Dictionary) -> void:
	## Q-A contract state only. Not DPS. Not a second Knowledge system.
	if typeof(q) != TYPE_DICTIONARY:
		return
	quest = q.duplicate(true)
	save_session()


func ws_day_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


func _roll_ws_day() -> void:
	var k := ws_day_key()
	if war_score_day != k:
		war_score_day = k
		war_score_daily = 0.0


func remaining_war_score() -> float:
	_roll_ws_day()
	return maxf(0.0, WS_DAILY_CAP - war_score_daily)


func grant_war_score(amount: float) -> float:
	## Soft Arena WS. Daily cap 60. Further wins → 0 WS (cosmetics only).
	_roll_ws_day()
	if amount <= 0.0:
		return 0.0
	var room := remaining_war_score()
	var got := minf(amount, room)
	if got <= 0.0:
		return 0.0
	war_score_daily += got
	save_session()
	return got


func remember_clash_result(won: bool, granted: float) -> void:
	## AR-I: SoftKnowledge WIN/LOSS + WS grant. Never DPS. Not a planet flip.
	clash_result = "WIN" if won else "LOSS"
	clash_ws_granted = granted
	clash_cosmetic = won and granted <= 0.0
	save_session()
	print("[SoftSession] clash ", clash_result, " ws=", granted, " daily=", war_score_daily, "/", WS_DAILY_CAP, " cosmetic=", clash_cosmetic)


func remember_alliance_quest(q: Dictionary) -> void:
	## Q-B shared alliance contract. Same SoftSession file. Not a second quest system.
	if typeof(q) != TYPE_DICTIONARY:
		return
	alliance_quest = q.duplicate(true)
	save_session()


func note_player_action(kind: String) -> void:
	## Last occupy / harvest / invite / form / faction. Choice only — not DPS.
	var k := str(kind)
	if not LEGAL_ACTIONS.has(k):
		return
	last_action = k

func next_legal_step() -> String:
	## Invite keeps follow. Occupy / harvest / form / faction stay on the pad.
	if last_action == "invite":
		return "follow"
	return "pad"

func is_offline() -> bool:
	return _offline

func begin_offline() -> void:
	## Player left (focus out / session pause). Local process, not a cluster.
	if _offline:
		return
	_offline = true
	save_session()
	offline_changed.emit(true)
	print("[SoftSession] offline last_action=", last_action, " next=", next_legal_step())

func end_offline() -> void:
	if not _offline:
		return
	_offline = false
	offline_changed.emit(false)

func remember_player(p: Node, action: String = "") -> void:
	if p == null:
		return
	if "current_form" in p:
		form = str(p.current_form)
	elif "form_name" in p:
		form = str(p.form_name)
	if "faction" in p:
		faction = str(p.faction)
	if LayerContext:
		last_layer = LayerContext.current_layer
	if action != "":
		note_player_action(action)
	if _pc_a() and is_host_authority():
		remember_ship(p)
	save_session()

func apply_to_player(p: Node) -> void:
	if p == null:
		return
	if "faction" in p:
		p.faction = faction
	if p.has_method("switch_form"):
		p.switch_form(form)
	elif "form_name" in p:
		p.form_name = form
		if p.has_method("_load_form_visual"):
			p._load_form_visual()
	print("[SoftSession] applied form=", form, " faction=", faction)


func _pc_a() -> bool:
	var P0 = load("res://scripts/world/P0Slice.gd")
	return P0 != null and bool(P0.PC_A_PERSIST)


func _pc_b() -> bool:
	var P0 = load("res://scripts/world/P0Slice.gd")
	return P0 != null and bool(P0.PC_B_PERSIST)


func _pc_c() -> bool:
	var P0 = load("res://scripts/world/P0Slice.gd")
	return P0 != null and bool(P0.PC_C_INSURE)


func is_host_authority() -> bool:
	if multiplayer == null or not multiplayer.has_multiplayer_peer():
		return true
	return multiplayer.is_server()


func persist_hud_line() -> String:
	## SoftKnowledge COLONY / SHIP / PERSIST. Never Pulse / kit / P2W.
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if SoftK == null:
		return ""
	return "%s · %s · %s" % [str(SoftK.colony_label()), str(SoftK.ship_label()), str(SoftK.persist_label())]


func crate_persist_hud_line() -> String:
	## PC-B SoftKnowledge CRATE / CARGO / PERSIST. Never mass / Pulse / kit.
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if SoftK == null:
		return ""
	return "%s · %s · %s" % [str(SoftK.crate_label()), str(SoftK.cargo_label()), str(SoftK.persist_label())]


func hangar_insure_hud_line() -> String:
	## PC-C SoftKnowledge HANGAR / INSURE / PERSIST. Never Pulse / P2W / kit.
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if SoftK == null:
		return ""
	return "%s · %s · %s" % [str(SoftK.hangar_label()), str(SoftK.insure_label()), str(SoftK.persist_label())]


func remember_pad_module(pad, kind: String, faction_name: String) -> void:
	## Player pad module identity only. Not NPC. Not SITE_*. Not Pulse.
	if not _pc_a() or not is_host_authority():
		return
	var pname := ""
	var k := str(kind)
	var fac := str(faction_name)
	if pad is Node:
		pname = str((pad as Node).name)
	else:
		pname = str(pad)
	if not LEGAL_PADS.has(pname):
		return
	if not LEGAL_PAD_KINDS.has(k):
		return
	if fac == "":
		fac = "Cybernex"
	_upsert_entry(colony, {"pad": pname, "kind": k, "faction": fac}, "pad")
	save_session()
	print("[SoftSession] PC-A pad ", pname, " kind=", k, " faction=", fac)


func remember_orbital_module(kind: String, faction_name: String) -> void:
	## ST-K/L/M extras on the existing PlayerOrbitalStation. Not ST-E dock/habitat.
	if not _pc_a() or not is_host_authority():
		return
	var k := str(kind)
	var fac := str(faction_name)
	if not LEGAL_ORBITAL_KINDS.has(k):
		return
	if fac == "":
		fac = "Cybernex"
	_upsert_entry(orbital, {"kind": k, "faction": fac}, "")
	save_session()
	print("[SoftSession] PC-A orbital kind=", k, " faction=", fac)


func remember_ship(p: Node = null) -> void:
	## Ship faction + module kind tags. Never HP / DPS / Pulse / kit unlock.
	if not _pc_a() or not is_host_authority():
		return
	var fac := faction
	var kinds: Array = []
	var hull: Node = p
	if hull != null and is_instance_valid(hull):
		if "faction" in hull and str(hull.get("faction")) != "":
			fac = str(hull.get("faction"))
		kinds = _ship_module_kinds(hull)
	if fac == "":
		fac = "Cybernex"
	ship = {"faction": fac, "modules": kinds}
	faction = fac
	save_session()
	print("[SoftSession] PC-A ship faction=", fac, " modules=", kinds.size())


func remember_crate(source = null, where: String = "") -> void:
	## ONE crate amount/slug from existing PadStorage / CargoHold. No SITE_*.
	if not _pc_b() or not is_host_authority():
		return
	var amount := 0
	var slug := ""
	var loc := str(where)
	if source is Node and is_instance_valid(source):
		if source.has_method("crate_amount"):
			amount = int(source.crate_amount())
		elif source.has_method("unit_count"):
			amount = int(source.unit_count())
		if source.has_method("crate_slug"):
			slug = str(source.crate_slug())
		if loc == "":
			if source.has_meta("orbital_storage") and bool(source.get_meta("orbital_storage")):
				loc = "orbital"
			elif source.has_meta("pad_storage") and bool(source.get_meta("pad_storage")):
				loc = "pad"
			elif str(source.name) == "CargoHold":
				loc = "ship"
	if not LEGAL_CRATE_WHERE.has(loc):
		return
	if not _legal_crate_slug(slug) or amount < 1:
		return
	crate = {"amount": 1, "slug": slug, "where": loc}
	save_session()
	print("[SoftSession] PC-B crate slug=", slug, " amount=1 where=", loc)


func restore_crate(os: Node = null) -> void:
	## Host-only. Existing PadStorage / CargoHold APIs. Never mints SITE_*.
	if not _pc_b() or not is_host_authority():
		return
	var slug := str(crate.get("slug", ""))
	var loc := str(crate.get("where", ""))
	var amount := clampi(int(crate.get("amount", 0)), 0, 1)
	if amount < 1 or not _legal_crate_slug(slug) or not LEGAL_CRATE_WHERE.has(loc):
		return
	var target: Node = _crate_target(loc, os)
	if target == null or not is_instance_valid(target):
		return
	_apply_crate_to(target, slug)


func remember_hangar_insure(source = null, where: String = "") -> void:
	## ONE hangar insurance record. Prefer ST-J pad / ST-K orbital stub.
	## Optional ST-D queue kind if that queue is already in-tree. No SITE_*.
	if not _pc_c() or not is_host_authority():
		return
	var loc := str(where)
	var kind := "hangar_stub"
	var pname := ""
	var fac := faction if faction != "" else "Cybernex"
	var queued := ""
	if source is Node and is_instance_valid(source):
		if source.has_meta("orbital_hangar_stub") and bool(source.get_meta("orbital_hangar_stub")):
			loc = "orbital"
			kind = "hangar_stub"
		elif source.has_meta("pad_hangar_stub") and bool(source.get_meta("pad_hangar_stub")):
			loc = "pad"
			kind = "hangar_stub"
			var parent := source.get_parent()
			if parent != null:
				pname = str(parent.name)
		elif source.has_meta("hangar_queue") and bool(source.get_meta("hangar_queue")):
			loc = "queue"
			kind = "queue"
			queued = _queued_kind_from(source)
		if "faction" in source and str(source.get("faction")) != "":
			fac = str(source.get("faction"))
	if loc == "":
		loc = "pad"
	if not LEGAL_HANGAR_WHERE.has(loc) or not LEGAL_HANGAR_KINDS.has(kind):
		return
	if loc == "pad":
		if pname == "" and source is Node and is_instance_valid(source):
			var pad_n := source.get_parent()
			if pad_n != null:
				pname = str(pad_n.name)
		if not LEGAL_PADS.has(pname):
			return
	if loc == "queue":
		if queued == "":
			queued = _snapshot_queue_kind()
		if not LEGAL_QUEUE_KINDS.has(queued):
			return
	elif queued == "":
		queued = _snapshot_queue_kind()
	if fac == "":
		fac = "Cybernex"
	hangar = {"where": loc, "kind": kind, "faction": fac}
	if loc == "pad":
		hangar["pad"] = pname
	if LEGAL_QUEUE_KINDS.has(queued):
		hangar["queued"] = queued
	save_session()
	print("[SoftSession] PC-C hangar where=", loc, " kind=", kind, " pad=", pname, " queued=", queued)


func restore_hangar_insure(_os: Node = null) -> void:
	## Host-only. Existing BaseBuilder / CarrierHangarQueue APIs. Never mints SITE_*.
	if not _pc_c() or not is_host_authority():
		return
	var loc := str(hangar.get("where", ""))
	var kind := str(hangar.get("kind", "hangar_stub"))
	var fac := str(hangar.get("faction", "Cybernex"))
	var queued := str(hangar.get("queued", ""))
	if not LEGAL_HANGAR_WHERE.has(loc) or not LEGAL_HANGAR_KINDS.has(kind):
		return
	if fac == "":
		fac = "Cybernex"
	if loc == "pad" or (loc != "queue" and kind == "hangar_stub"):
		_restore_hangar_stub(loc, fac)
	if LEGAL_QUEUE_KINDS.has(queued) or loc == "queue":
		_restore_hangar_queue(queued if queued != "" else "sensor")


func wipe_colony_memory() -> void:
	## Playtest relaunch sim. Does not write disk. Does not touch PC-B crate or PC-C hangar.
	colony = []
	orbital = []
	ship = {}


func wipe_crate_memory() -> void:
	## PC-B playtest relaunch sim. Does not write disk.
	crate = {}


func wipe_hangar_insure_memory() -> void:
	## PC-C playtest relaunch sim. Does not write disk.
	hangar = {}


func restore_world(os: Node = null) -> void:
	## Host-only. BaseBuilder place_*. Never steals the ST-A player_module slot.
	if not is_host_authority():
		return
	var crate_snap: Dictionary = crate.duplicate()
	if _pc_a():
		restore_colony()
		restore_orbital()
		restore_ship(os)
		print("[SoftSession] PC-A restore colony=", colony.size(), " orbital=", orbital.size(),
			" ship=", str(ship.get("faction", "")))
	if _pc_b():
		if crate.is_empty() and not crate_snap.is_empty():
			crate = crate_snap
		restore_crate(os)
		print("[SoftSession] PC-B restore crate=", str(crate.get("slug", "")),
			" amount=", int(crate.get("amount", 0)), " where=", str(crate.get("where", "")))
	if _pc_c():
		restore_hangar_insure(os)
		print("[SoftSession] PC-C restore hangar=", str(hangar.get("where", "")),
			" kind=", str(hangar.get("kind", "")), " queued=", str(hangar.get("queued", "")))


func restore_colony() -> void:
	var Builder = load("res://scripts/world/BaseBuilder.gd")
	var tree := get_tree()
	if not _pc_a() or not is_host_authority() or Builder == null or tree == null:
		return
	for raw in colony:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var pname := str(raw.get("pad", ""))
		var k := str(raw.get("kind", ""))
		var fac := str(raw.get("faction", "Cybernex"))
		var pad: Node3D = _pad_named(pname)
		if pad == null or not LEGAL_PAD_KINDS.has(k):
			continue
		_place_pad_kind(Builder, pad, k, fac)


func restore_orbital() -> void:
	var Builder = load("res://scripts/world/BaseBuilder.gd")
	var tree := get_tree()
	var cluster: Node3D = null
	if not _pc_a() or not is_host_authority() or Builder == null or tree == null:
		return
	var listed: Array = tree.get_nodes_in_group("player_orbital_stations")
	if listed.is_empty():
		return
	cluster = listed[0] as Node3D
	if cluster == null or not is_instance_valid(cluster):
		return
	for raw in orbital:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var k := str(raw.get("kind", ""))
		var fac := str(raw.get("faction", "Cybernex"))
		_place_orbital_kind(Builder, cluster, k, fac)


func restore_ship(os: Node = null) -> void:
	if not _pc_a() or not is_host_authority():
		return
	var fac := str(ship.get("faction", faction))
	if fac == "":
		return
	faction = fac
	var hull: Node = null
	if os != null and is_instance_valid(os):
		hull = os.get("ship") as Node
	if hull == null:
		var tree := get_tree()
		if tree:
			hull = tree.get_first_node_in_group("player_ship")
	if hull != null and is_instance_valid(hull) and "faction" in hull:
		hull.faction = fac
	var walker: Node = null
	if os != null and is_instance_valid(os):
		walker = os.get("player") as Node
	if walker != null and is_instance_valid(walker) and "faction" in walker:
		walker.faction = fac


func _ingest_colony(raw) -> void:
	colony = []
	if typeof(raw) != TYPE_ARRAY:
		return
	for e in raw:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var pname := str(e.get("pad", ""))
		var k := str(e.get("kind", ""))
		var fac := str(e.get("faction", "Cybernex"))
		if LEGAL_PADS.has(pname) and LEGAL_PAD_KINDS.has(k):
			colony.append({"pad": pname, "kind": k, "faction": fac if fac != "" else "Cybernex"})


func _ingest_orbital(raw) -> void:
	orbital = []
	if typeof(raw) != TYPE_ARRAY:
		return
	for e in raw:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var k := str(e.get("kind", ""))
		var fac := str(e.get("faction", "Cybernex"))
		if LEGAL_ORBITAL_KINDS.has(k):
			orbital.append({"kind": k, "faction": fac if fac != "" else "Cybernex"})


func _ingest_ship(raw) -> void:
	ship = {}
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var fac := str(raw.get("faction", ""))
	var mods = raw.get("modules", [])
	var kinds: Array = []
	if fac == "":
		return
	if typeof(mods) == TYPE_ARRAY:
		for m in mods:
			var tag := str(m)
			if tag != "":
				kinds.append(tag)
	ship = {"faction": fac, "modules": kinds}


func _ingest_crate(raw) -> void:
	crate = {}
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var slug := str(raw.get("slug", ""))
	var loc := str(raw.get("where", ""))
	var amount := clampi(int(raw.get("amount", 0)), 0, 1)
	if amount < 1 or not _legal_crate_slug(slug) or not LEGAL_CRATE_WHERE.has(loc):
		return
	crate = {"amount": 1, "slug": slug, "where": loc}


func _ingest_hangar(raw) -> void:
	hangar = {}
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var loc := str(raw.get("where", ""))
	var kind := str(raw.get("kind", "hangar_stub"))
	var fac := str(raw.get("faction", "Cybernex"))
	var pname := str(raw.get("pad", ""))
	var queued := str(raw.get("queued", ""))
	if not LEGAL_HANGAR_WHERE.has(loc) or not LEGAL_HANGAR_KINDS.has(kind):
		return
	if loc == "pad" and not LEGAL_PADS.has(pname):
		return
	if loc == "queue" and not LEGAL_QUEUE_KINDS.has(queued):
		return
	if fac == "":
		fac = "Cybernex"
	hangar = {"where": loc, "kind": kind, "faction": fac}
	if loc == "pad":
		hangar["pad"] = pname
	if LEGAL_QUEUE_KINDS.has(queued):
		hangar["queued"] = queued


func _restore_hangar_stub(loc: String, fac: String) -> void:
	var Builder = load("res://scripts/world/BaseBuilder.gd")
	if Builder == null:
		return
	if loc == "orbital":
		var cluster: Node3D = _orbital_cluster()
		if cluster != null:
			Builder.place_orbital_hangar_stub(cluster, fac)
		return
	var pname := str(hangar.get("pad", ""))
	var pad: Node3D = _pad_named(pname)
	if pad != null:
		Builder.place_pad_hangar_stub(pad, fac)


func _restore_hangar_queue(kind: String) -> void:
	## Existing CarrierHangarQueue only. Does not invent a carrier.
	var k := str(kind)
	if not LEGAL_QUEUE_KINDS.has(k):
		return
	var queue: Node = _hangar_queue()
	if queue == null or not queue.has_method("enqueue_module"):
		return
	if queue.has_method("queued_module") and queue.queued_module() != null:
		return
	var _mod: Node = queue.enqueue_module(k, 0.0)


func _snapshot_queue_kind() -> String:
	return _queued_kind_from(_hangar_queue())


func _queued_kind_from(queue: Node) -> String:
	if queue == null or not is_instance_valid(queue):
		return ""
	if not queue.has_method("queued_module"):
		return ""
	var mod: Node = queue.queued_module()
	if mod == null or not is_instance_valid(mod):
		return ""
	var k := str(mod.get_meta("module_type", ""))
	if LEGAL_QUEUE_KINDS.has(k):
		return k
	return ""


func _hangar_queue() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var listed: Array = tree.get_nodes_in_group("hangar_queues")
	if listed.is_empty():
		return null
	if listed[0] is Node:
		return listed[0]
	return null


func _orbital_cluster() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var listed: Array = tree.get_nodes_in_group("player_orbital_stations")
	if listed.is_empty():
		return null
	if listed[0] is Node3D:
		return listed[0] as Node3D
	return null


func _legal_crate_slug(slug: String) -> bool:
	if slug == "" or slug.begins_with("SITE_") or slug.find("/") >= 0:
		return false
	if slug.length() > 48:
		return false
	return true


func _crate_target(loc: String, os: Node = null) -> Node:
	var tree := get_tree()
	if loc == "ship":
		var hull: Node = null
		if os != null and is_instance_valid(os):
			hull = os.get("ship") as Node
		if hull == null and tree:
			hull = tree.get_first_node_in_group("player_ship")
		if hull != null and is_instance_valid(hull):
			return hull.get_node_or_null("CargoHold")
		return null
	if tree == null:
		return null
	if loc == "orbital":
		var listed: Array = tree.get_nodes_in_group("orbital_storages")
		if not listed.is_empty() and listed[0] is Node:
			return listed[0]
		return null
	var pads: Array = tree.get_nodes_in_group("pad_storage")
	if not pads.is_empty() and pads[0] is Node:
		return pads[0]
	for pname in LEGAL_PADS:
		var pad := _pad_named(pname)
		if pad == null:
			continue
		var store: Node = pad.get_node_or_null("PadStorage")
		if store != null:
			return store
	return null


func _apply_crate_to(target: Node, slug: String) -> void:
	## Existing store_unit / retrieve_unit / make_crate only.
	var Hold = load("res://scripts/ship/CargoHold.gd")
	if target == null or Hold == null or not target.has_method("store_unit"):
		return
	var packed: Dictionary = Hold.make_crate(slug)
	var vol := float(packed.get("volume", Hold.UNIT_VOL_M3))
	var mass := float(packed.get("mass", Hold.UNIT_MASS_T))
	if target.has_method("retrieve_unit") and target.has_method("can_store_unit"):
		var guard := 0
		while not bool(target.can_store_unit(vol, mass)) and guard < 8:
			var dropped: Dictionary = target.retrieve_unit(0)
			if dropped.is_empty():
				break
			guard += 1
	var _ok := bool(target.store_unit(packed))


func _upsert_entry(bucket: Array, entry: Dictionary, key: String) -> void:
	var kind := str(entry.get("kind", ""))
	for i in range(bucket.size()):
		var cur = bucket[i]
		if typeof(cur) != TYPE_DICTIONARY:
			continue
		if str(cur.get("kind", "")) != kind:
			continue
		if key != "" and str(cur.get(key, "")) != str(entry.get(key, "")):
			continue
		bucket[i] = entry
		return
	bucket.append(entry)


func _pad_named(pname: String) -> Node3D:
	var tree := get_tree()
	if tree == null or pname == "":
		return null
	for n in tree.get_nodes_in_group("landing_pads"):
		if n is Node3D and str(n.name) == pname:
			return n as Node3D
	return null


func _place_pad_kind(Builder, pad: Node3D, kind: String, fac: String) -> void:
	match kind:
		"habitat":
			## Do not steal an occupied ST-A player_module slot.
			if Builder.pad_has_player_module(pad):
				return
			Builder.place_player_habitat(pad, fac)
		"turret":
			Builder.place_pad_turret(pad, fac)
		"storage":
			Builder.place_pad_storage(pad, fac)
		"hangar":
			Builder.place_pad_hangar_stub(pad, fac)


func _place_orbital_kind(Builder, cluster: Node3D, kind: String, fac: String) -> void:
	match kind:
		"hangar":
			Builder.place_orbital_hangar_stub(cluster, fac)
		"turret":
			Builder.place_orbital_turret(cluster, fac)
		"storage":
			Builder.place_orbital_storage(cluster, fac)


func _ship_module_kinds(p: Node) -> Array:
	var out: Array = []
	if p == null or not ("modules" in p):
		return out
	var mods = p.get("modules")
	if typeof(mods) != TYPE_ARRAY:
		return out
	for m in mods:
		if m == null:
			continue
		if m.has_method("short_tag"):
			var tag := str(m.short_tag())
			if tag != "":
				out.append(tag)
	return out
