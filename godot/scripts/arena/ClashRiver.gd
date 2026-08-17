extends Node3D
class_name ClashRiver
## Readable river strip on the existing 60×60 TestArena floor.
## Terrain/read only — not an objective. No GLB, no jump pads, no SITE_*.

const FOOTPRINT_HALF := 28.0
const Y_FILM := 0.14

## East-west mid crossing (Predecessor river read).
const CROSS_Z := 1.4
const CROSS_HALF_W := 2.35
const CROSS_HALF_LEN := 24.0

## North-south channels in the TOP–MID and MID–BOT pockets.
const CHANNEL_XS := [7.0, -7.0]
const CHANNEL_HALF_W := 2.05
const CHANNEL_Z0 := -9.5
const CHANNEL_Z1 := 11.5

var _strips: Array = []
var _mat: StandardMaterial3D = null
var _bank_mat: StandardMaterial3D = null

func _ready() -> void:
	name = "ClashRiver"
	add_to_group("clash_river")
	_build()
	print("[ClashRiver] strips=", _strips.size(), " footprint=", is_on_footprint(), " between_lanes=", is_between_lanes())


func is_present() -> bool:
	return _strips.size() >= 3


func is_on_footprint() -> bool:
	if _strips.is_empty():
		return false
	for e in _strips:
		var p: Vector3 = e["pos"]
		var s: Vector3 = e["size"]
		if absf(p.x) + s.x * 0.5 > FOOTPRINT_HALF + 0.05:
			return false
		if absf(p.z) + s.z * 0.5 > FOOTPRINT_HALF + 0.05:
			return false
	return true


func is_between_lanes() -> bool:
	for e in _strips:
		var x := absf(float((e["pos"] as Vector3).x))
		if x > 3.6 and x < 10.8:
			return true
	return false


func is_objective() -> bool:
	return false


func strip_table() -> Array:
	return _strips.duplicate()


func contains(pos: Vector3) -> bool:
	for e in _strips:
		var p: Vector3 = e["pos"]
		var s: Vector3 = e["size"]
		if absf(pos.x - p.x) <= s.x * 0.5 + 0.25 and absf(pos.z - p.z) <= s.z * 0.5 + 0.25:
			return true
	return false


func _build() -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.06, 0.22, 0.32, 0.88)
	_mat.metallic = 0.15
	_mat.roughness = 0.28
	_mat.emission_enabled = true
	_mat.emission = Color(0.12, 0.48, 0.62)
	_mat.emission_energy_multiplier = 1.05
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bank_mat = _mat.duplicate() as StandardMaterial3D
	_bank_mat.albedo_color = Color(0.18, 0.55, 0.68, 0.95)
	_bank_mat.emission = Color(0.28, 0.78, 0.88)
	_bank_mat.emission_energy_multiplier = 1.45
	var cross_size := Vector3(CROSS_HALF_LEN * 2.0, 0.06, CROSS_HALF_W * 2.0)
	_strip("RiverCross", Vector3(0.0, Y_FILM, CROSS_Z), cross_size)
	_box("BankN", Vector3(CROSS_HALF_LEN * 2.0, 0.05, 0.18), Vector3(0.0, Y_FILM + 0.03, CROSS_Z - CROSS_HALF_W), _bank_mat)
	_box("BankS", Vector3(CROSS_HALF_LEN * 2.0, 0.05, 0.18), Vector3(0.0, Y_FILM + 0.03, CROSS_Z + CROSS_HALF_W), _bank_mat)
	var ch_len := CHANNEL_Z1 - CHANNEL_Z0
	var ch_z := (CHANNEL_Z0 + CHANNEL_Z1) * 0.5
	var ch_size := Vector3(CHANNEL_HALF_W * 2.0, 0.06, ch_len)
	_strip("RiverTopMid", Vector3(float(CHANNEL_XS[0]), Y_FILM, ch_z), ch_size)
	_strip("RiverMidBot", Vector3(float(CHANNEL_XS[1]), Y_FILM, ch_z), ch_size)
	if DisplayServer.get_name() != "headless":
		var lab := Label3D.new()
		lab.name = "RiverLabel"
		lab.text = "RIVER"
		lab.font_size = 22
		lab.modulate = Color(0.45, 0.9, 1.0)
		lab.outline_size = 10
		lab.outline_modulate = Color(0, 0, 0, 0.9)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.position = Vector3(7.0, 2.0, 4.8)
		add_child(lab)


func _strip(nname: String, pos: Vector3, size: Vector3) -> void:
	_box(nname, size, pos, _mat)
	_strips.append({"name": nname, "pos": pos, "size": size})


func _box(nname: String, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nname
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi
