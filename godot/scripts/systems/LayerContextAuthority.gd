extends Node
## Soft multiplayer-ready authority for LayerContext (local-only until net).
## Does NOT grant combat power. Serializes session ownership of context flags.

signal authority_changed(is_authority: bool)

var session_id: String = ""
var peer_id: int = 1
var is_authority: bool = true  ## single-player default: local is authority
var authority_token: String = ""

func _ready() -> void:
	session_id = _make_id()
	authority_token = _make_id()
	peer_id = 1
	is_authority = true
	print("[LayerContextAuthority] local session=", session_id, " auth=", is_authority)

func _make_id() -> String:
	return "%d_%d" % [Time.get_ticks_usec(), randi()]

func claim_local_authority() -> void:
	is_authority = true
	authority_token = _make_id()
	authority_changed.emit(true)

## Future multiplayer: only authority may mutate LayerContext quest/claim
func can_mutate_context() -> bool:
	return is_authority

func apply_context_mutation(mut: Callable) -> bool:
	if not can_mutate_context():
		if GameManager:
			GameManager.toast_requested.emit("No LayerContext authority (multiplayer stub)")
		return false
	mut.call()
	return true

func export_bundle() -> Dictionary:
	var ctx := {}
	if LayerContext:
		ctx = LayerContext.snapshot()
	return {
		"session_id": session_id,
		"peer_id": peer_id,
		"is_authority": is_authority,
		"token": authority_token,
		"context": ctx,
	}

func import_bundle(data: Dictionary, as_authority: bool = false) -> void:
	if data.has("session_id"):
		session_id = str(data["session_id"])
	if data.has("peer_id"):
		peer_id = int(data["peer_id"])
	is_authority = as_authority
	if data.has("token"):
		authority_token = str(data["token"])
	if data.has("context") and data["context"] is Dictionary and LayerContext:
		LayerContext.restore(data["context"])
	authority_changed.emit(is_authority)
	print("[LayerContextAuthority] import auth=", is_authority, " session=", session_id)
