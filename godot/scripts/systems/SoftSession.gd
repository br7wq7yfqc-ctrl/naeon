extends Node
## Soft local session persist — form/faction/layer + last legal action.
## NP-F: player leave starts a short local offline cycle. Not combat power. Not P2W.
## PC-A: pad/orbital player modules + ship across relaunch. Same user:// file.
## SoftKnowledge / HUD only. Host authority. Never Pulse / kit / P2W.

signal offline_changed(offline: bool)

const PATH := "user://soft_session.json"
const LEGAL_ACTIONS := ["occupy", "harvest", "invite", "form", "faction"]
const WS_DAILY_CAP := 60.0
const LEGAL_PADS := ["Pad_North", "Pad_Approach", "Pad_Flank"]
const LEGAL_PAD_KINDS := ["habitat", "turret", "storage", "hangar"]
const LEGAL_ORBITAL_KINDS := ["hangar", "turret", "storage"]

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
	_roll_ws_day()
	print("[SoftSession] loaded form=", form, " faction=", faction, " ws=", war_score_daily, "/", WS_DAILY_CAP,
		" colony=", colony.size(), " orbital=", orbital.size(), " ship=", str(ship.get("faction", "")))

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


func wipe_colony_memory() -> void:
	## Playtest relaunch sim. Does not write disk.
	colony = []
	orbital = []
	ship = {}


func restore_world(os: Node = null) -> void:
	## Host-only. BaseBuilder place_*. Never steals the ST-A player_module slot.
	if not _pc_a() or not is_host_authority():
		return
	restore_colony()
	restore_orbital()
	restore_ship(os)
	print("[SoftSession] PC-A restore colony=", colony.size(), " orbital=", orbital.size(),
		" ship=", str(ship.get("faction", "")))


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
