extends Node
## Cross-layer context payload (skill §4.1 S1).
## Land/dock must not drop quest, claim, or cargo risk flags.

signal layer_changed(layer_name: String)

## Strategy | Space | TPS | Arena
var current_layer: String = "Space"
var active_quest_id: String = ""
var active_claim_id: String = ""
var cargo_risk: float = 0.0  ## 0–1 soft risk indicator (EVE bar, not combat power)
var seamless_stage: String = "S1"  ## documented transition stage

func set_layer(name: String) -> void:
	if name == current_layer:
		return
	current_layer = name
	layer_changed.emit(name)
	print("[LayerContext] → ", name, " stage=", seamless_stage)

func set_quest(qid: String) -> void:
	if LayerContextAuthority and not LayerContextAuthority.can_mutate_context():
		return
	active_quest_id = qid

func set_claim(cid: String) -> void:
	if LayerContextAuthority and not LayerContextAuthority.can_mutate_context():
		return
	active_claim_id = cid

func add_cargo_risk(delta: float) -> void:
	cargo_risk = clampf(cargo_risk + delta, 0.0, 1.0)

func clear_cargo_risk() -> void:
	cargo_risk = 0.0

func snapshot() -> Dictionary:
	return {
		"layer": current_layer,
		"quest": active_quest_id,
		"claim": active_claim_id,
		"cargo_risk": cargo_risk,
		"stage": seamless_stage,
	}

func restore(data: Dictionary) -> void:
	if data.has("quest"):
		active_quest_id = str(data["quest"])
	if data.has("claim"):
		active_claim_id = str(data["claim"])
	if data.has("cargo_risk"):
		cargo_risk = float(data["cargo_risk"])
	# layer set by caller after spawn
