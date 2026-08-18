extends Node
class_name SquadRoster
## NP-D: local squad invite. rules/24 size 2–5. One NPC slot this slice.
## No damage aura. No pay-slot. SoftNet stays visual — no combat authority.

const SIZE_MIN := 2
const SIZE_MAX := 5
const NPC_SLOT_MAX := 1
const PLAYER_ID := "player"

var _members: Array = []


func _ready() -> void:
	add_to_group("squad_roster")
	if _members.is_empty():
		_members.append({"id": PLAYER_ID, "kind": "player", "node": null})


func bind_player(p: Node) -> void:
	for m in _members:
		if str(m.get("id", "")) == PLAYER_ID:
			m["node"] = p if p != null and is_instance_valid(p) else null
			return


func size() -> int:
	return _members.size()


func npc_count() -> int:
	var n := 0
	for m in _members:
		if str(m.get("kind", "")) == "npc":
			n += 1
	return n


func member_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for m in _members:
		ids.append(str(m.get("id", "")))
	return ids


func contains(who) -> bool:
	if who == null:
		return false
	if who is String or who is StringName:
		var sid := str(who)
		for m in _members:
			if str(m.get("id", "")) == sid:
				return true
		return false
	if not (who is Node):
		return false
	var node: Node = who
	if not is_instance_valid(node):
		return false
	var nid := _id_of(node)
	for m in _members:
		if str(m.get("id", "")) == nid:
			return true
		var held: Node = m.get("node") as Node
		if held != null and is_instance_valid(held) and held == node:
			return true
		if node.get_parent() != null and held != null and is_instance_valid(held) and held == node.get_parent():
			return true
		if node.has_node("NpcPilot") and m.get("node") == node.get_node("NpcPilot"):
			return true
	return false


func invite(npc: Node) -> bool:
	## One local NPC. Does not spend Contribution. Does not buff combat.
	if npc == null or not is_instance_valid(npc):
		return false
	if contains(npc):
		return false
	if size() >= SIZE_MAX:
		return false
	if npc_count() >= NPC_SLOT_MAX:
		return false
	var id := _id_of(npc)
	_members.append({"id": id, "kind": "npc", "node": npc})
	if npc.has_method("accept_squad_invite"):
		npc.accept_squad_invite(self)
	if SoftSession and SoftSession.has_method("note_player_action"):
		SoftSession.note_player_action("invite")
	print("[Squad] invite ", id, " size=", size())
	return true


func combat_bonus() -> float:
	## Grouping is not a damage aura.
	return 0.0


func invite_cost() -> float:
	## Not a pay-slot.
	return 0.0


func hud_line() -> String:
	if npc_count() <= 0:
		return ""
	return "SQUAD %d/%d · NPC" % [size(), SIZE_MAX]


func _id_of(n: Node) -> String:
	if n.has_meta("squad_id") and str(n.get_meta("squad_id")) != "":
		return str(n.get_meta("squad_id"))
	if n.name == "NpcPilot":
		return "npc_visitor"
	if n.has_meta("pad_traffic_role") and str(n.get_meta("pad_traffic_role")) == "visitor":
		return "npc_visitor"
	return "npc_%s" % n.get_instance_id()
