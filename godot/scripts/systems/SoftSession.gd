extends Node
## Soft local session persist — form/faction/layer prefs only.
## Never stores combat power, loot that bypasses soft economy, or P2W flags.

const PATH := "user://soft_session.json"

var form: String = "Canine"
var faction: String = "Cybernex"
var last_layer: String = "Space"

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
	print("[SoftSession] loaded form=", form, " faction=", faction)

func save_session() -> void:
	var payload := {
		"form": form,
		"faction": faction,
		"last_layer": last_layer,
		"saved_at": Time.get_datetime_string_from_system(true),
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()

func remember_player(p: Node) -> void:
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
