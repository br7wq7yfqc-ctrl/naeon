extends Node
## First-session soft objectives — teaches the 10-minute loop without hard gating.
## Soft only: no combat power rewards.

signal objective_completed(id: String)
signal briefing_changed(text: String)

var _done: Dictionary = {}
var _order: PackedStringArray = [
	"boot",
	"fly_or_fight",
	"land_or_lane",
	"claim_or_obj",
	"economy_tick",
]
var _labels := {
	"boot": "NAEON Phase 0 — pick a mode from the menu (Space or Clash)",
	"fly_or_fight": "SPACE: fly (WASD) · CLASH: engage a lane dummy (Q/E abilities)",
	"land_or_lane": "SPACE: approach pad + E land · CLASH: push toward a claim beacon",
	"claim_or_obj": "SPACE: C claim pad · CLASH: secure an objective node",
	"economy_tick": "Earn Contribution / Biomass (soft economy — no P2W)",
}
var current: String = "boot"

func _ready() -> void:
	current = "boot"
	call_deferred("_emit")

func _emit() -> void:
	briefing_changed.emit(briefing())

func briefing() -> String:
	if current == "" or current not in _labels:
		return "Phase 0 loop complete — free play. O=Space · Tab=Clash · dual-theme ownership soft"
	return "OBJECTIVE  ·  " + str(_labels.get(current, current))

func complete(id: String) -> void:
	if _done.get(id, false):
		return
	_done[id] = true
	objective_completed.emit(id)
	if AudioDirector:
		AudioDirector.play_claim()
	if GameManager:
		GameManager.toast_requested.emit("Objective complete: %s" % id)
	# No economy grant here — harvest/claim work is the economy beat (no P2W, no skip)
	# advance
	var idx := _order.find(current)
	if id == current and idx >= 0 and idx + 1 < _order.size():
		current = _order[idx + 1]
	elif id in _order:
		# jump forward if out-of-order complete
		var j := _order.find(id)
		if j + 1 < _order.size() and (_order.find(current) <= j):
			current = _order[j + 1]
	# all done?
	var all := true
	for k in _order:
		if not _done.get(k, false) and k != "boot":
			# boot auto-done on menu leave
			pass
	if _done.get("economy_tick", false):
		current = ""
	_emit()

func on_entered_mode(mode: String) -> void:
	complete("boot")
	if mode == "space" or mode == "clash":
		if current == "boot" or current == "fly_or_fight":
			current = "fly_or_fight"
			_emit()

func on_moved() -> void:
	if current == "fly_or_fight":
		complete("fly_or_fight")

func on_landed_or_lane() -> void:
	complete("land_or_lane")

func on_claim_or_obj() -> void:
	complete("claim_or_obj")

func on_economy() -> void:
	complete("economy_tick")
