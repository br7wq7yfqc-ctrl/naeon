extends Node
## Soft local session persist — form/faction/layer + last legal action.
## NP-F: player leave starts a short local offline cycle. Not combat power. Not P2W.

signal offline_changed(offline: bool)

const PATH := "user://soft_session.json"
const LEGAL_ACTIONS := ["occupy", "harvest", "invite", "form", "faction"]

var form: String = "Canine"
var faction: String = "Cybernex"
var last_layer: String = "Space"
var last_action: String = ""
var quest: Dictionary = {}
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
	print("[SoftSession] loaded form=", form, " faction=", faction)

func save_session() -> void:
	var payload := {
		"form": form,
		"faction": faction,
		"last_layer": last_layer,
		"last_action": last_action,
		"quest": quest,
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
