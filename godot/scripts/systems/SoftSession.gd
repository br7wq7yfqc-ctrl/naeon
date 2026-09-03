extends Node
## Soft local session persist — form/faction/layer + last legal action.
## NP-F: player leave starts a short local offline cycle. Not combat power. Not P2W.
## PC-A: same file also keeps a small colony + ship snapshot (legal stubs only).

signal offline_changed(offline: bool)

const PATH := "user://soft_session.json"
const LEGAL_ACTIONS := ["occupy", "harvest", "invite", "form", "faction"]
const LEGAL_PADS := ["Pad_North", "Pad_Approach", "Pad_Flank"]
const LEGAL_HULLS := ["scout", "sniper", "hauler"]
const WS_DAILY_CAP := 60.0
const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
const _Builder = preload("res://scripts/world/BaseBuilder.gd")

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
var colony: Dictionary = {}
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
	colony = _sanitize_colony(data.get("colony", {}))
	ship = _sanitize_ship(data.get("ship", {}))
	if str(ship.get("form", "")) != "":
		form = str(ship.get("form"))
	if str(ship.get("faction", "")) != "":
		faction = str(ship.get("faction"))
	_roll_ws_day()
	print("[SoftSession] loaded form=", form, " faction=", faction, " hull=", ship.get("hull", ""),
		" colony=", has_colony_snapshot(), " ws=", war_score_daily, "/", WS_DAILY_CAP)

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
		"colony": colony,
		"ship": ship,
		"saved_at": Time.get_datetime_string_from_system(true),
	}
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
	remember_world()
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
	_remember_ship_identity(p)
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


func has_colony_snapshot() -> bool:
	if typeof(colony) != TYPE_DICTIONARY:
		return false
	var pads = colony.get("pads", [])
	var orb = colony.get("orbital", {})
	if typeof(pads) == TYPE_ARRAY and not pads.is_empty():
		return true
	if typeof(orb) == TYPE_DICTIONARY and not orb.is_empty():
		return bool(orb.get("storage", false)) or bool(orb.get("hangar", false)) \
			or bool(orb.get("turret", false)) or bool(orb.get("factory", false)) \
			or bool(orb.get("dock", false)) or bool(orb.get("habitat", false))
	return false


func has_ship_snapshot() -> bool:
	if typeof(ship) != TYPE_DICTIONARY:
		return false
	return str(ship.get("hull", "")) != "" or str(ship.get("form", "")) != "" \
		or str(ship.get("faction", "")) != "" or form != "" or faction != ""


func persist_hud_line() -> String:
	## SoftKnowledge COLONY / SHIP / SAVED. Never DPS / yield.
	var parts := PackedStringArray()
	if has_colony_snapshot():
		parts.append(_SoftK.colony_label())
	if has_ship_snapshot():
		parts.append(_SoftK.persist_ship_label())
	if parts.size() > 0:
		parts.append(_SoftK.saved_label())
	return " · ".join(parts)


func clear_persist_memory() -> void:
	## Playtest: drop in-memory colony/ship so load_session must refill them.
	colony = {}
	ship = {}


func remember_world(actor: Node = null) -> void:
	## Capture legal pad/orbital stubs + soft ship identity. Same JSON file.
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 != null and not bool(P0.PC_A_PERSIST):
		return
	if not _is_host():
		return
	_capture_colony()
	_remember_ship_identity(actor)
	if actor == null:
		_remember_ship_identity(_player_ship())
	save_session()


func restore_world() -> void:
	## Re-place the same legal stubs via existing BaseBuilder APIs.
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 != null and not bool(P0.PC_A_PERSIST):
		return
	if not _is_host():
		return
	if not has_colony_snapshot():
		return
	_restore_pads()
	_restore_orbital(_find_orbital())


func restore_pad_on(pad: Node3D) -> void:
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 != null and not bool(P0.PC_A_PERSIST):
		return
	if not _is_host():
		return
	if pad == null or not is_instance_valid(pad):
		return
	if not _Builder.is_unnamed_pad(pad):
		return
	_restore_one_pad(pad)


func restore_orbital_on(cluster: Node3D) -> void:
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 != null and not bool(P0.PC_A_PERSIST):
		return
	if not _is_host():
		return
	_restore_orbital(cluster)


func _sanitize_colony(raw) -> Dictionary:
	var out := {}
	var pads_out: Array = []
	var orb_out := {}
	var raw_pads = null
	var raw_orb = null
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	raw_pads = raw.get("pads", [])
	if typeof(raw_pads) == TYPE_ARRAY:
		for e in raw_pads:
			var row := _sanitize_pad_row(e)
			if not row.is_empty():
				pads_out.append(row)
	if not pads_out.is_empty():
		out["pads"] = pads_out
	raw_orb = raw.get("orbital", {})
	if typeof(raw_orb) == TYPE_DICTIONARY:
		orb_out = _sanitize_orbital_row(raw_orb)
	if not orb_out.is_empty():
		out["orbital"] = orb_out
	return out


func _sanitize_pad_row(raw) -> Dictionary:
	var id := ""
	var fac := "Cybernex"
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	id = str(raw.get("id", ""))
	if not LEGAL_PADS.has(id):
		return {}
	fac = str(raw.get("faction", "Cybernex"))
	if fac != "Cybernex" and fac != "gROT":
		fac = "Cybernex"
	return {
		"id": id,
		"faction": fac,
		"turret": bool(raw.get("turret", false)),
		"storage": bool(raw.get("storage", false)),
		"hangar": bool(raw.get("hangar", false)),
	}


func _sanitize_orbital_row(raw) -> Dictionary:
	var body := "Nex-Prime"
	var fac := "Cybernex"
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	if raw.is_empty():
		return {}
	body = str(raw.get("body", "Nex-Prime"))
	if body != "Nex-Prime" and body != "ROT-Hive" and body != "Shard-Moon":
		body = "Nex-Prime"
	fac = str(raw.get("faction", "Cybernex"))
	if fac != "Cybernex" and fac != "gROT":
		fac = "Cybernex"
	return {
		"body": body,
		"faction": fac,
		"dock": bool(raw.get("dock", false)),
		"habitat": bool(raw.get("habitat", false)),
		"factory": bool(raw.get("factory", false)),
		"hangar": bool(raw.get("hangar", false)),
		"turret": bool(raw.get("turret", false)),
		"storage": bool(raw.get("storage", false)),
	}


func _sanitize_ship(raw) -> Dictionary:
	var hull := ""
	var f := form
	var fac := faction
	if typeof(raw) != TYPE_DICTIONARY:
		return _ship_row(hull, f, fac)
	hull = str(raw.get("hull", ""))
	if hull != "" and not LEGAL_HULLS.has(hull):
		hull = ""
	if str(raw.get("form", "")) != "":
		f = str(raw.get("form"))
	if str(raw.get("faction", "")) != "":
		fac = str(raw.get("faction"))
	return _ship_row(hull, f, fac)


func _ship_row(hull: String, f: String, fac: String) -> Dictionary:
	return {"hull": hull, "form": f, "faction": fac}


func _remember_ship_identity(p: Node) -> void:
	var hull := _hull_from(p)
	if hull == "" and typeof(ship) == TYPE_DICTIONARY:
		hull = str(ship.get("hull", ""))
	if hull != "" and not LEGAL_HULLS.has(hull):
		hull = ""
	ship = _ship_row(hull, form, faction)


func _hull_from(p: Node) -> String:
	var role = null
	if p == null or not is_instance_valid(p):
		return ""
	if p.has_method("hull_slug"):
		return str(p.hull_slug())
	if "_role" in p:
		role = p.get("_role")
	if role != null and "hull_id" in role:
		return str(role.hull_id)
	return ""


func _capture_colony() -> void:
	var pads_out: Array = []
	var orb := _find_orbital()
	var orb_row := {}
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("pad_bases"):
			var pad := _pad_host_of(n)
			var row := {}
			if pad == null:
				continue
			row = {
				"id": pad.name,
				"faction": _pad_faction(n),
				"turret": _Builder.pad_turret_on(pad) != null,
				"storage": _Builder.pad_storage_on(pad) != null,
				"hangar": _Builder.pad_hangar_stub_on(pad) != null,
			}
			if bool(row["turret"]) or bool(row["storage"]) or bool(row["hangar"]):
				pads_out.append(row)
	if orb != null and is_instance_valid(orb):
		orb_row = {
			"body": str(orb.get("orbit_body")) if "orbit_body" in orb else "Nex-Prime",
			"faction": str(orb.get_faction()) if orb.has_method("get_faction") else faction,
			"dock": true,
			"habitat": true,
			"factory": bool(orb.has_factory()) if orb.has_method("has_factory") else orb.get_node_or_null("FactoryModule") != null,
			"hangar": bool(orb.has_hangar_stub()) if orb.has_method("has_hangar_stub") else _Builder.orbital_hangar_stub_on(orb) != null,
			"turret": bool(orb.has_defense_turret()) if orb.has_method("has_defense_turret") else _Builder.orbital_turret_on(orb) != null,
			"storage": bool(orb.has_storage()) if orb.has_method("has_storage") else _Builder.orbital_storage_on(orb) != null,
		}
	colony = _sanitize_colony({"pads": pads_out, "orbital": orb_row})


func _restore_pads() -> void:
	var pads = colony.get("pads", [])
	if typeof(pads) != TYPE_ARRAY:
		return
	for e in pads:
		var row := _sanitize_pad_row(e)
		var pad := _find_pad(str(row.get("id", "")))
		if pad == null:
			continue
		_Builder.restore_pad_modules(
			pad,
			str(row.get("faction", faction)),
			bool(row.get("turret", false)),
			bool(row.get("storage", false)),
			bool(row.get("hangar", false))
		)


func _restore_one_pad(pad: Node3D) -> void:
	var pads = colony.get("pads", [])
	if typeof(pads) != TYPE_ARRAY:
		return
	for e in pads:
		var row := _sanitize_pad_row(e)
		if str(row.get("id", "")) != pad.name:
			continue
		_Builder.restore_pad_modules(
			pad,
			str(row.get("faction", faction)),
			bool(row.get("turret", false)),
			bool(row.get("storage", false)),
			bool(row.get("hangar", false))
		)
		return


func _restore_orbital(cluster: Node3D) -> void:
	var raw = colony.get("orbital", {})
	var row := _sanitize_orbital_row(raw)
	var fac := faction
	if cluster == null or not is_instance_valid(cluster):
		return
	if row.is_empty():
		return
	fac = str(row.get("faction", faction))
	if bool(row.get("factory", false)) and cluster.has_method("ensure_factory"):
		cluster.ensure_factory()
	_Builder.restore_orbital_modules(
		cluster,
		fac,
		bool(row.get("hangar", false)),
		bool(row.get("turret", false)),
		bool(row.get("storage", false))
	)
	if cluster.has_method("_refresh_label"):
		cluster._refresh_label()


func _find_pad(id: String) -> Node3D:
	var tree := get_tree()
	var os: Node = null
	if id == "" or not LEGAL_PADS.has(id):
		return null
	if tree:
		for n in tree.get_nodes_in_group("pad_bases"):
			var host := _pad_host_of(n)
			if host != null and host.name == id:
				return host
		os = tree.get_first_node_in_group("open_space")
		if os != null:
			var found: Node = os.find_child(id, true, false)
			if found is Node3D:
				return found as Node3D
	return null


func _find_orbital() -> Node3D:
	var tree := get_tree()
	var os: Node = null
	if tree:
		var listed: Array = tree.get_nodes_in_group("player_orbital_stations")
		if not listed.is_empty() and listed[0] is Node3D:
			return listed[0] as Node3D
		os = tree.get_first_node_in_group("open_space")
		if os != null and os.has_method("player_orbital_station"):
			return os.player_orbital_station()
	return null


func _pad_host_of(n: Node) -> Node3D:
	var walk: Node = n
	while walk:
		if walk is Node3D and _Builder.is_unnamed_pad(walk):
			return walk as Node3D
		walk = walk.get_parent()
	return null


func _pad_faction(n: Node) -> String:
	if n != null and n.has_method("get_faction"):
		var f := str(n.get_faction())
		if f == "Cybernex" or f == "gROT":
			return f
	return faction


func _player_ship() -> Node:
	var tree := get_tree()
	var os: Node = null
	if tree == null:
		return null
	os = tree.get_first_node_in_group("open_space")
	if os != null:
		var sh = os.get("ship")
		if sh != null and is_instance_valid(sh):
			return sh
	return null


func _is_host() -> bool:
	if multiplayer == null or not multiplayer.has_multiplayer_peer():
		return true
	return multiplayer.is_server()
