extends Node
class_name SoftAlliance
## NP-E: two local NPCs share AllianceRanks + a visible raid/logistics intent.
## Ranks are soft perms (rules/11), not power. Intent is not rules/23 siege.
## No HP/DPS/claim bonus. Not pay-to-rank. Not pay-to-war.

const _Ranks = preload("res://scripts/systems/AllianceRanks.gd")

const INTENTS := ["raid", "logistics"]
const MEMBER_MAX := 2

var _members: Array = []
var _intent: String = "raid"
var _shared_contract_id: String = ""


func _ready() -> void:
	add_to_group("soft_alliance")


func bind(a: Node, rank_a: int, perm_a: String, b: Node, rank_b: int, perm_b: String, intent: String = "raid") -> bool:
	## Two local NPCs. Assignment spends nothing and grants no combat/claim.
	if a == null or b == null or not is_instance_valid(a) or not is_instance_valid(b):
		return false
	if a == b:
		return false
	_members.clear()
	if not _add(a, rank_a, perm_a):
		return false
	if not _add(b, rank_b, perm_b):
		_members.clear()
		return false
	set_intent(intent)
	print("[Alliance] NP-E bind n=", member_count(), " intent=", _intent)
	return member_count() == MEMBER_MAX


func member_count() -> int:
	return _members.size()


func intent() -> String:
	return _intent


func set_intent(kind: String) -> bool:
	var k := str(kind).to_lower()
	if k == "siege" or k == "war":
		return false
	if k not in INTENTS:
		return false
	_intent = k
	_stamp_intent()
	var host := get_parent()
	if host != null and host.has_method("refresh_labels"):
		host.refresh_labels()
	return true


func is_siege() -> bool:
	## Intent is a banner, not rules/23 structure siege.
	return false


func is_war() -> bool:
	return false


func combat_bonus() -> float:
	return 0.0


func claim_bonus() -> float:
	return 0.0


func rank_cost() -> float:
	## NPC bind is not a shop rank.
	return 0.0


func war_cost() -> float:
	## Intent is not a paid war declare.
	return 0.0


func member_rank(who) -> int:
	var m: Dictionary = _find(who)
	return int(m.get("rank", -1))


func member_perm(who) -> String:
	var m: Dictionary = _find(who)
	return str(m.get("perm", ""))


func member_has_perm(who) -> bool:
	var m: Dictionary = _find(who)
	if m.is_empty():
		return false
	return _Ranks.has_perm(int(m.get("rank", -1)), str(m.get("perm", "")))


func hud_line() -> String:
	if member_count() < MEMBER_MAX:
		return ""
	var a: Dictionary = _members[0]
	var b: Dictionary = _members[1]
	var line := "ALLY 2 · %s/%s · %s · %s/%s · no power" % [
		_Ranks.rank_name(int(a.get("rank", 0))),
		_Ranks.rank_name(int(b.get("rank", 0))),
		_intent.to_upper(),
		str(a.get("perm", "")),
		str(b.get("perm", "")),
	]
	var intel := intel_label()
	if intel == "ALLY INTEL":
		line += " · ALLY INTEL"
	return line


func intel_label() -> String:
	var SoftK = load("res://scripts/systems/SoftKnowledge.gd")
	if SoftK == null:
		return "ALLY"
	return str(SoftK.alliance_intel_label())


func shared_contract_id() -> String:
	return _shared_contract_id


func member_seen_id(who) -> String:
	var m: Dictionary = _find(who)
	if m.is_empty():
		return ""
	var n: Node = m.get("node") as Node
	if n != null and is_instance_valid(n) and n.has_meta("alliance_contract_id"):
		return str(n.get_meta("alliance_contract_id"))
	return _shared_contract_id


func see_contract(id: String) -> bool:
	## Constructor pin (Officer+) shares one ContractBoard id. Not pay-to-rank.
	var cid := str(id).strip_edges()
	if cid == "" or cid.begins_with("SITE_"):
		return false
	if member_count() < MEMBER_MAX:
		return false
	var can_pin := false
	for m in _members:
		if _Ranks.has_perm(int(m.get("rank", -1)), "constructor_pin"):
			can_pin = true
			break
	if not can_pin:
		return false
	_shared_contract_id = cid
	_stamp_contract(cid)
	return true


func intent_visible() -> bool:
	var line := hud_line().to_upper()
	return _intent in INTENTS and line.find(_intent.to_upper()) >= 0 and line.find("SIEGE") < 0


func _add(n: Node, rank: int, perm: String) -> bool:
	if member_count() >= MEMBER_MAX:
		return false
	var r: int = clampi(rank, 0, 4)
	var p := str(perm)
	if not _Ranks.has_perm(r, p):
		var list: Array = _Ranks.PERMS.get(r, [])
		if list.is_empty():
			return false
		p = str(list[0])
	_members.append({"id": _id_of(n), "node": n, "rank": r, "perm": p})
	n.set_meta("alliance_rank", r)
	n.set_meta("alliance_perm", p)
	n.set_meta("alliance_intent", _intent)
	n.set_meta("site_pin", "")
	return true


func _stamp_intent() -> void:
	for m in _members:
		var n: Node = m.get("node") as Node
		if n != null and is_instance_valid(n):
			n.set_meta("alliance_intent", _intent)
			n.set_meta("site_pin", "")


func _stamp_contract(id: String) -> void:
	for m in _members:
		var n: Node = m.get("node") as Node
		if n == null or not is_instance_valid(n):
			continue
		n.set_meta("alliance_contract_id", id)
		n.set_meta("site_pin", "")
		var p := n.get_parent()
		if p != null and is_instance_valid(p):
			p.set_meta("alliance_contract_id", id)
			p.set_meta("site_pin", "")


func _find(who) -> Dictionary:
	if who == null:
		return {}
	if who is String or who is StringName:
		var sid := str(who)
		for m in _members:
			if str(m.get("id", "")) == sid:
				return m
		return {}
	if not (who is Node):
		return {}
	var node: Node = who
	if not is_instance_valid(node):
		return {}
	for m in _members:
		var held: Node = m.get("node") as Node
		if held != null and is_instance_valid(held) and (held == node or held == node.get_parent()):
			return m
		if node.has_node("NpcPilot") and m.get("node") == node.get_node("NpcPilot"):
			return m
	return {}


func _id_of(n: Node) -> String:
	if n.has_meta("squad_id") and str(n.get_meta("squad_id")) != "":
		return str(n.get_meta("squad_id"))
	if n.name == "NpcPilot":
		return "npc_visitor"
	if n.has_meta("pad_traffic_role"):
		return "npc_%s" % str(n.get_meta("pad_traffic_role"))
	return "npc_%s" % n.get_instance_id()
