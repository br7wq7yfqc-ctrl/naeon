extends RefCounted
class_name ContractBoard
## Q-A: one generated contract from a template on the same ARK body.
## Q-E: the same board can also roll scan_extractor (ST-B PadHarvestExtractor).
## Q-D: the pad visitor offers this same board id. Not a second quest system.
## Completing grants SoftKnowledge rank/label only. Never yield / DPS / modules.
## No cash-shop skip. No pay-to-complete. story ≠ power.

const SUBJECT := "quest_intel"
const MASTERY_GRANT := 12.0
const BODY := "Nex-Prime"


static func templates() -> PackedStringArray:
	return PackedStringArray(["occupy", "harvest", "deliver_crate", "scan_extractor"])


static func reset_slice() -> void:
	_write({})
	if LayerContext and LayerContext.has_method("set_quest"):
		var qid := str(LayerContext.active_quest_id)
		if qid.begins_with("QA-"):
			LayerContext.set_quest("")


static func snapshot() -> Dictionary:
	return _state().duplicate(true)


static func offer_one(host_id: String, body: String = BODY, template: String = "") -> Dictionary:
	var P0 = load("res://scripts/world/P0Slice.gd")
	var cur := _state()
	var host := str(host_id).strip_edges()
	var on := str(body).strip_edges()
	var tmpl := ""
	if P0 == null or not bool(P0.Q_A_CONTRACT):
		return {}
	if on == "":
		on = BODY
	if on != BODY:
		return {}
	if not cur.is_empty():
		if _ensure_learning_node(cur):
			_write(cur)
		return cur.duplicate(true)
	if host == "":
		host = "unnamed_pad"
	tmpl = _resolve_template(host, template)
	cur = {
		"id": "QA-%s-%s" % [tmpl, host],
		"template": tmpl,
		"host": host,
		"body": on,
		"status": "offered",
		"progress": false,
		"reward": "knowledge_label",
	}
	_ensure_learning_node(cur)
	_write(cur)
	print("[ContractBoard] offered ", cur["id"], " template=", tmpl, " host=", host)
	return cur.duplicate(true)


static func accept() -> Dictionary:
	var cur := _state()
	if cur.is_empty() or str(cur.get("status", "")) != "offered":
		return cur.duplicate(true)
	cur["status"] = "accepted"
	_write(cur)
	if LayerContext and LayerContext.has_method("set_quest"):
		LayerContext.set_quest(str(cur.get("id", "")))
	print("[ContractBoard] accepted ", cur.get("id", ""))
	return cur.duplicate(true)


static func note_progress(kind: String, body: String = BODY) -> Dictionary:
	var cur := _state()
	var k := str(kind)
	var on := str(body).strip_edges()
	if cur.is_empty() or str(cur.get("status", "")) != "accepted":
		return cur.duplicate(true)
	if on == "":
		on = BODY
	if on != str(cur.get("body", BODY)):
		return cur.duplicate(true)
	if k != str(cur.get("template", "")):
		return cur.duplicate(true)
	cur["progress"] = true
	_write(cur)
	print("[ContractBoard] progress ", cur.get("id", ""), " kind=", k)
	return cur.duplicate(true)


static func try_complete() -> Dictionary:
	var cur := _state()
	var gained := 0.0
	if cur.is_empty() or str(cur.get("status", "")) != "accepted":
		return cur.duplicate(true)
	if not bool(cur.get("progress", false)):
		return cur.duplicate(true)
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery(SUBJECT, MASTERY_GRANT)
		gained = MASTERY_GRANT
	cur["status"] = "complete"
	cur["mastery_granted"] = gained
	_write(cur)
	if GameManager:
		var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
		var lab := "PAD INTEL" if SoftK == null else str(SoftK.contract_intel_label())
		GameManager.toast_requested.emit(
			"Contract complete — %s (soft Knowledge only, no yield)" % lab
		)
	print("[ContractBoard] complete ", cur.get("id", ""), " +", snapped(gained, 0.1), " ", SUBJECT)
	return cur.duplicate(true)


static func cash_shop_skip_possible() -> bool:
	return false


static func try_pay_complete(cash: float = 0.0) -> bool:
	## Freemium / no-P2W: cash never finishes a contract.
	if cash > 0.0:
		print("[ContractBoard] pay-to-complete refused")
	return false


static func try_cash_skip() -> bool:
	print("[ContractBoard] cash-shop skip refused")
	return false


static func knowledge_gated_weapon(_id: String = "") -> bool:
	return false


static func knowledge_gated_module(_id: String = "") -> bool:
	return false


static func try_unlock_exclusive_weapon(_id: String = "") -> bool:
	print("[ContractBoard] Knowledge-gated exclusive weapon refused")
	return false


static func try_unlock_exclusive_module(_id: String = "") -> bool:
	print("[ContractBoard] Knowledge-gated exclusive module refused")
	return false


static func interact_scan_extractor() -> Dictionary:
	## Q-E: read ST-B PadHarvestExtractor via SoftKnowledge. Never harvest / yield.
	var cur := _state()
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	var intel := ""
	if cur.is_empty() or str(cur.get("template", "")) != "scan_extractor":
		return {}
	if str(cur.get("status", "")) == "":
		return {}
	if SoftK == null:
		return {}
	intel = str(SoftK.read_node_intel("extractor"))
	if intel == "":
		return {}
	cur["scan_intel"] = intel
	cur["scan_read"] = true
	if str(cur.get("status", "")) == "accepted":
		cur["progress"] = true
	_write(cur)
	if GameManager:
		GameManager.toast_requested.emit(
			"Extractor scan — %s (soft intel only, no yield)" % intel
		)
	print("[ContractBoard] scan extractor ", cur.get("id", ""), " intel=", intel)
	return {
		"id": str(cur.get("id", "")),
		"intel": intel,
		"status": str(cur.get("status", "")),
		"progress": bool(cur.get("progress", false)),
	}


static func learning_node() -> Dictionary:
	## Q-C: optional node on harvest / deliver. Empty on occupy.
	var cur := _state()
	var node = cur.get("learning_node", {})
	if typeof(node) != TYPE_DICTIONARY:
		return {}
	return (node as Dictionary).duplicate(true)


static func interact_learning_node() -> Dictionary:
	## Read pad / extractor / crate via SoftKnowledge. Never yield / DPS.
	var cur := _state()
	var node = cur.get("learning_node", {})
	var intel := {}
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	var reads: Array = []
	var kind := ""
	if cur.is_empty() or typeof(node) != TYPE_DICTIONARY or (node as Dictionary).is_empty():
		return {}
	if str(cur.get("status", "")) == "":
		return {}
	reads = node.get("reads", ["pad", "extractor", "crate"])
	if SoftK == null:
		return {}
	for k in reads:
		kind = str(k)
		intel[kind] = str(SoftK.read_node_intel(kind))
	node["status"] = "read"
	node["intel"] = intel
	cur["learning_node"] = node
	_write(cur)
	if GameManager:
		GameManager.toast_requested.emit(
			"Learning Node — %s / %s / %s (soft intel only)" % [
				str(intel.get("pad", "")),
				str(intel.get("extractor", "")),
				str(intel.get("crate", "")),
			]
		)
	print("[ContractBoard] learning node read ", cur.get("id", ""),
		" pad=", intel.get("pad", ""),
		" extractor=", intel.get("extractor", ""),
		" crate=", intel.get("crate", ""))
	return {"id": str(cur.get("id", "")), "node": node.duplicate(true), "intel": intel}


static func try_complete_learning_node() -> Dictionary:
	## Subject mastery label only. Combat / economy tables stay identical.
	var cur := _state()
	var node = cur.get("learning_node", {})
	var gained := 0.0
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if cur.is_empty() or typeof(node) != TYPE_DICTIONARY or (node as Dictionary).is_empty():
		return cur.duplicate(true)
	if str(node.get("status", "")) != "read":
		return cur.duplicate(true)
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("field_intel", MASTERY_GRANT)
		gained = MASTERY_GRANT
	node["status"] = "complete"
	node["mastery_granted"] = gained
	cur["learning_node"] = node
	_write(cur)
	if GameManager:
		var lab := "FIELD INTEL" if SoftK == null else str(SoftK.field_intel_label())
		GameManager.toast_requested.emit(
			"Learning Node complete — %s (soft Knowledge only, no yield)" % lab
		)
	print("[ContractBoard] learning node complete ", cur.get("id", ""),
		" +", snapped(gained, 0.1), " field_intel")
	return cur.duplicate(true)


static func alliance_templates() -> PackedStringArray:
	## Q-B: occupy or logistics on the same unnamed pad. Not siege. Not a second board.
	return PackedStringArray(["occupy", "logistics"])


static func reset_alliance_slice() -> void:
	_write_alliance({})


static func alliance_snapshot() -> Dictionary:
	return _alliance_state().duplicate(true)


static func offer_alliance_one(host_id: String, body: String = BODY, intent: String = "") -> Dictionary:
	var P0 = load("res://scripts/world/P0Slice.gd")
	var cur := _alliance_state()
	var host := str(host_id).strip_edges()
	var on := str(body).strip_edges()
	var tmpl := ""
	if P0 == null or not bool(P0.Q_B_ALLIANCE):
		return {}
	if on == "":
		on = BODY
	if on != BODY:
		return {}
	if not cur.is_empty():
		return cur.duplicate(true)
	if host == "":
		host = "unnamed_pad"
	tmpl = _pick_alliance_template(host, intent)
	cur = {
		"id": "QB-%s-%s" % [tmpl, host],
		"template": tmpl,
		"host": host,
		"body": on,
		"status": "offered",
		"progress": false,
		"reward": "knowledge_label",
		"shared": true,
		"scope": "alliance",
	}
	_write_alliance(cur)
	print("[ContractBoard] alliance offered ", cur["id"], " template=", tmpl, " host=", host)
	return cur.duplicate(true)


static func accept_alliance() -> Dictionary:
	var cur := _alliance_state()
	if cur.is_empty() or str(cur.get("status", "")) != "offered":
		return cur.duplicate(true)
	cur["status"] = "accepted"
	_write_alliance(cur)
	print("[ContractBoard] alliance accepted ", cur.get("id", ""))
	return cur.duplicate(true)


static func note_alliance_progress(kind: String, body: String = BODY) -> Dictionary:
	var cur := _alliance_state()
	var k := str(kind)
	var on := str(body).strip_edges()
	if cur.is_empty() or str(cur.get("status", "")) != "accepted":
		return cur.duplicate(true)
	if on == "":
		on = BODY
	if on != str(cur.get("body", BODY)):
		return cur.duplicate(true)
	if k != str(cur.get("template", "")):
		return cur.duplicate(true)
	cur["progress"] = true
	_write_alliance(cur)
	print("[ContractBoard] alliance progress ", cur.get("id", ""), " kind=", k)
	return cur.duplicate(true)


static func try_complete_alliance() -> Dictionary:
	var cur := _alliance_state()
	var gained := 0.0
	if cur.is_empty() or str(cur.get("status", "")) != "accepted":
		return cur.duplicate(true)
	if not bool(cur.get("progress", false)):
		return cur.duplicate(true)
	if GameManager and GameManager.has_method("add_mastery"):
		GameManager.add_mastery("alliance_intel", MASTERY_GRANT)
		gained = MASTERY_GRANT
	cur["status"] = "complete"
	cur["mastery_granted"] = gained
	_write_alliance(cur)
	if GameManager:
		var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
		var lab := "ALLY INTEL" if SoftK == null else str(SoftK.alliance_intel_label())
		GameManager.toast_requested.emit(
			"Alliance contract complete — %s (soft Knowledge only, no yield)" % lab
		)
	print("[ContractBoard] alliance complete ", cur.get("id", ""), " +", snapped(gained, 0.1), " alliance_intel")
	return cur.duplicate(true)


static func try_pay_rank(cash: float = 0.0) -> bool:
	## Freemium / no-P2W: cash never buys alliance rank or constructor pin.
	if cash > 0.0:
		print("[ContractBoard] pay-to-rank refused")
	return false


static func _pick_template(host_id: String) -> String:
	var list := templates()
	var h := absi(host_id.hash())
	if list.is_empty():
		return "occupy"
	return str(list[h % list.size()])


static func _resolve_template(host_id: String, template: String) -> String:
	var want := str(template).strip_edges()
	if want != "" and templates().has(want):
		return want
	return _pick_template(host_id)


static func _learning_templates() -> PackedStringArray:
	return PackedStringArray(["harvest", "deliver_crate"])


static func _ensure_learning_node(cur: Dictionary) -> bool:
	## Optional. Occupy stays node-less. Does not rewrite Q-A pick.
	var P0 = load("res://scripts/world/P0Slice.gd")
	var tmpl := str(cur.get("template", ""))
	var node = cur.get("learning_node", {})
	if P0 == null or not bool(P0.Q_C_LEARNING):
		return false
	if not _learning_templates().has(tmpl):
		return false
	if typeof(node) == TYPE_DICTIONARY and not (node as Dictionary).is_empty():
		return false
	cur["learning_node"] = {
		"id": "LN-%s" % str(cur.get("id", "QA")),
		"status": "available",
		"subject": "field_intel",
		"reads": ["pad", "extractor", "crate"],
		"optional": true,
	}
	print("[ContractBoard] learning node on ", cur.get("id", ""))
	return true


static func _pick_alliance_template(host_id: String, intent: String = "") -> String:
	var kind := str(intent).to_lower()
	if kind == "logistics":
		return "logistics"
	if kind == "raid" or kind == "occupy":
		return "occupy"
	var list := alliance_templates()
	var h := absi(host_id.hash())
	if list.is_empty():
		return "occupy"
	return str(list[h % list.size()])


static func _state() -> Dictionary:
	if SoftSession == null:
		return {}
	var q = SoftSession.get("quest")
	if typeof(q) != TYPE_DICTIONARY:
		return {}
	return (q as Dictionary).duplicate(true)


static func _write(q: Dictionary) -> void:
	if SoftSession and SoftSession.has_method("remember_quest"):
		SoftSession.remember_quest(q)


static func _alliance_state() -> Dictionary:
	if SoftSession == null:
		return {}
	var q = SoftSession.get("alliance_quest")
	if typeof(q) != TYPE_DICTIONARY:
		return {}
	return (q as Dictionary).duplicate(true)


static func _write_alliance(q: Dictionary) -> void:
	if SoftSession and SoftSession.has_method("remember_alliance_quest"):
		SoftSession.remember_alliance_quest(q)
