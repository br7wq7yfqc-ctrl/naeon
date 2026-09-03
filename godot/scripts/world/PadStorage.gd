extends Node3D
class_name PadStorage
## ST-I: one pad storage crate/hold. Not a ship CargoHold. Cap 1 crate unit.
## ST-M: same grammar on PlayerOrbitalStation (orbital_storage).
## Occupied unnamed pad (ST-I) or host orbital cluster (ST-M).
## Knowledge labels only. Mass/value stay. No SITE_*.

const _Prop := preload("res://scripts/assets/GlbProp.gd")
const _SoftK := preload("res://scripts/systems/SoftKnowledge.gd")
const _Hold := preload("res://scripts/ship/CargoHold.gd")

const CAP := 1

var faction: String = "Cybernex"
var _units: Array = []
var _label: Label3D = null


func setup(fac: String) -> void:
	_bind_storage(fac, false)


func setup_orbital(fac: String) -> void:
	## ST-M: same PadStorage grammar on the player orbital cluster.
	_bind_storage(fac, true)


func _bind_storage(fac: String, orbital: bool) -> void:
	faction = fac if fac != "" else "Cybernex"
	name = "OrbitalStorage" if orbital else "PadStorage"
	set_meta("site_pin", "")
	set_meta("module_type", "storage")
	set_meta("pad_storage", not orbital)
	set_meta("orbital_storage", orbital)
	set_meta("player_module", false)
	set_meta("npc_module", false)
	set_meta("printed_module", false)
	set_meta("ship_cargo_hold", false)
	set_meta("combat_stats", 0)
	if orbital:
		if not is_in_group("orbital_storages"):
			add_to_group("orbital_storages")
	elif not is_in_group("pad_storage"):
		add_to_group("pad_storage")
	_spawn_marker()
	_spawn_mesh()
	_ensure_label()
	if _units.is_empty():
		seed_one()
	if orbital:
		print("[PadStorage] ST-M on orbital cluster fac=", faction, " cap=", CAP, " units=", _units.size())
	else:
		print("[PadStorage] ST-I on pad fac=", faction, " cap=", CAP, " units=", _units.size())


func module_type() -> String:
	return "storage"


func combat_stats() -> int:
	return 0


func is_ship_cargo_hold() -> bool:
	return false


func max_units() -> int:
	return CAP


func unit_count() -> int:
	return _units.size()


func can_store_unit(vol: float, mass: float) -> bool:
	if _units.size() >= CAP:
		return false
	if vol < 0.0 or mass < 0.0:
		return false
	return true


func crate_amount() -> int:
	## PC-B: one-crate count. Cap 1. Never a SITE_* mint.
	return _units.size()


func crate_slug() -> String:
	## PC-B: first crate id/slug already on the unit.
	if _units.is_empty():
		return ""
	var e: Dictionary = _units[0] as Dictionary
	return str(e.get("slug", e.get("id", "")))


func store_unit(entry: Dictionary) -> bool:
	var packed: Dictionary = _Hold.normalize_unit(entry)
	var vol := float(packed.get("volume", _Hold.UNIT_VOL_M3))
	var mass := float(packed.get("mass", _Hold.UNIT_MASS_T))
	if not can_store_unit(vol, mass):
		return false
	_units.append(packed)
	_refresh_label()
	_pc_b_remember()
	return true


func retrieve_unit(index: int = 0) -> Dictionary:
	if index < 0 or index >= _units.size():
		return {}
	var e: Dictionary = _units.pop_at(index)
	_refresh_label()
	return e


func seed_one() -> void:
	if _units.size() >= CAP:
		return
	_units.append(_Hold.make_crate("pad_storage_1"))
	_refresh_label()


func storage_label() -> String:
	return _SoftK.storage_label()


func crate_mass() -> float:
	if _units.is_empty():
		return _Hold.UNIT_MASS_T
	return float((_units[0] as Dictionary).get("mass", _Hold.UNIT_MASS_T))


func crate_value() -> float:
	if _units.is_empty():
		return _Hold.UNIT_VALUE
	return float((_units[0] as Dictionary).get("value", _Hold.UNIT_VALUE))


func reload_for_faction(faction_name: String) -> void:
	## ST-F theme only. Does not change mass / value / cap.
	if faction_name == "" or faction_name == "Contested" or faction_name == "Neutral":
		return
	faction = faction_name
	var mesh: Node = get_node_or_null("Storage/StorageMesh")
	if mesh != null and mesh.has_method("reload_for_faction"):
		mesh.reload_for_faction(faction_name)
	_refresh_label()


func _spawn_marker() -> void:
	var n := Node3D.new()
	n.name = "Storage"
	n.set_meta("site_pin", "")
	n.set_meta("outpost_part", "orbital_storage" if bool(get_meta("orbital_storage", false)) else "pad_storage")
	add_child(n)


func _spawn_mesh() -> void:
	var n: Node3D = get_node_or_null("Storage") as Node3D
	if n == null:
		return
	var fx := "cybernex" if faction != "gROT" else "grot"
	var prop := Node3D.new()
	prop.set_script(_Prop)
	prop.set("relative_path", "props/sci_fi_crate/sci_fi_crate_%s_lod2.glb" % fx)
	prop.set("scale_factor", 1.8)
	prop.set("add_static_collision", true)
	prop.name = "StorageMesh"
	n.add_child(prop)


func _ensure_label() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 20
	_label.position = Vector3(0, 2.2, 0)
	add_child(_label)
	_refresh_label()


func _pc_b_remember() -> void:
	## SoftSession crate snapshot. Host only. Not a second hold.
	if SoftSession == null or not SoftSession.has_method("remember_crate"):
		return
	var where := "orbital" if bool(get_meta("orbital_storage", false)) else "pad"
	SoftSession.remember_crate(self, where)


func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = "%s %s\n%s ×%d/%d" % [
		storage_label(), faction, _SoftK.crate_label(), _units.size(), CAP
	]
