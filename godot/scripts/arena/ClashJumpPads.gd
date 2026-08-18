extends Node3D
class_name ClashJumpPads
## Short vertical hops on the existing 60×60 TestArena footprint.
## Predecessor-style pads — not flight, not ship, not SITE_*, not pay-to-jump.

const FOOTPRINT_HALF := 28.0
const HOP_UP := 6.4
const HOP_FWD := 3.2
const COOLDOWN := 0.9
const TRIGGER_R := 1.15
const MAX_HOP_PEAK := 4.5

## Inter-lane pockets. Clear of camp (7.2, −1.2) and the session bench (−7.2, 10.5).
const PAD_SPECS := [
	{"name": "PadTopMidS", "pos": Vector3(7.0, 0.0, 8.4), "dir": Vector3(0.0, 0.0, 1.0)},
	{"name": "PadTopMidN", "pos": Vector3(7.0, 0.0, -7.6), "dir": Vector3(0.0, 0.0, -1.0)},
	{"name": "PadMidBotS", "pos": Vector3(-7.0, 0.0, 8.4), "dir": Vector3(0.0, 0.0, 1.0)},
	{"name": "PadMidBotN", "pos": Vector3(-7.0, 0.0, -7.6), "dir": Vector3(0.0, 0.0, -1.0)},
]

var _pads: Array = []
var _last_hop_ok: bool = false
var _mat: StandardMaterial3D = null
var _ring_mat: StandardMaterial3D = null

func _ready() -> void:
	name = "ClashJumpPads"
	add_to_group("clash_jump_pads")
	_build()
	print("[ClashJumpPads] n=", _pads.size(), " footprint=", is_on_footprint())


func is_present() -> bool:
	return _pads.size() >= 2 and _pads.size() <= 4


func is_on_footprint() -> bool:
	if _pads.is_empty():
		return false
	for e in _pads:
		var p: Vector3 = e["pos"]
		if absf(p.x) > FOOTPRINT_HALF or absf(p.z) > FOOTPRINT_HALF:
			return false
	return true


func is_flight() -> bool:
	return false


func is_objective() -> bool:
	return false


func pad_count() -> int:
	return _pads.size()


func pad_table() -> Array:
	return _pads.duplicate()


func last_hop_ok() -> bool:
	return _last_hop_ok


func hop_up_speed() -> float:
	return HOP_UP


func max_hop_peak() -> float:
	return MAX_HOP_PEAK


func contains(pos: Vector3) -> bool:
	for e in _pads:
		var p: Vector3 = e["pos"]
		if Vector2(pos.x - p.x, pos.z - p.z).length() <= TRIGGER_R + 0.2:
			return true
	return false


func try_launch(body: Node, force: bool = false) -> bool:
	if not _is_walker(body):
		return false
	var cb := body as CharacterBody3D
	if not force and not cb.is_on_floor():
		return false
	var pad: Dictionary = _nearest(cb.global_position)
	if pad.is_empty():
		return false
	return _launch_from(pad, cb)


func _is_walker(body: Node) -> bool:
	if body == null or not is_instance_valid(body) or not (body is CharacterBody3D):
		return false
	if body.is_in_group("ship") or body.is_in_group("spaceship"):
		return false
	if body.has_method("is_ship") and bool(body.call("is_ship")):
		return false
	var scr: Script = body.get_script() as Script
	if scr:
		var p := str(scr.resource_path)
		if p.find("ShipController") >= 0 or p.find("/ship/") >= 0:
			return false
	return true


func _nearest(pos: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var best_d := 99.0
	for e in _pads:
		var p: Vector3 = e["pos"]
		var d := Vector2(pos.x - p.x, pos.z - p.z).length()
		if d < best_d:
			best_d = d
			best = e
	if best_d > TRIGGER_R + 0.85:
		return {}
	return best


func _launch_from(pad: Dictionary, cb: CharacterBody3D) -> bool:
	var now := Time.get_ticks_msec()
	if int(pad.get("ready_ms", 0)) > now:
		return false
	var dir: Vector3 = pad["dir"]
	var impulse := Vector3(dir.x * HOP_FWD, HOP_UP, dir.z * HOP_FWD)
	if cb.has_method("apply_arena_hop"):
		cb.call("apply_arena_hop", impulse)
	else:
		cb.velocity = impulse
	pad["ready_ms"] = now + int(COOLDOWN * 1000.0)
	_last_hop_ok = true
	return true


func _build() -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.12, 0.55, 0.42, 0.92)
	_mat.metallic = 0.35
	_mat.roughness = 0.32
	_mat.emission_enabled = true
	_mat.emission = Color(0.22, 0.95, 0.62)
	_mat.emission_energy_multiplier = 1.35
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat = _mat.duplicate() as StandardMaterial3D
	_ring_mat.albedo_color = Color(0.85, 0.95, 0.4, 0.95)
	_ring_mat.emission = Color(0.95, 1.0, 0.35)
	_ring_mat.emission_energy_multiplier = 1.7
	for spec in PAD_SPECS:
		_make_pad(str(spec["name"]), spec["pos"] as Vector3, spec["dir"] as Vector3)


func _make_pad(nname: String, pos: Vector3, dir: Vector3) -> void:
	var root := Node3D.new()
	root.name = nname
	root.position = pos
	add_child(root)
	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.05
	cyl.bottom_radius = 1.1
	cyl.height = 0.12
	plate.mesh = cyl
	plate.material_override = _mat
	plate.position.y = 0.07
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(plate)
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var torus := CylinderMesh.new()
	torus.top_radius = 1.18
	torus.bottom_radius = 1.18
	torus.height = 0.05
	ring.mesh = torus
	ring.material_override = _ring_mat
	ring.position.y = 0.14
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	if DisplayServer.get_name() != "headless":
		var lab := Label3D.new()
		lab.name = "PadLabel"
		lab.text = "PAD"
		lab.font_size = 18
		lab.modulate = Color(0.55, 1.0, 0.7)
		lab.outline_size = 8
		lab.outline_modulate = Color(0, 0, 0, 0.9)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.position = Vector3(0, 1.6, 0)
		root.add_child(lab)
	var area := Area3D.new()
	area.name = "Trigger"
	area.monitoring = true
	area.monitorable = false
	area.collision_layer = 0
	area.collision_mask = 6
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = TRIGGER_R
	sh.height = 1.6
	cs.shape = sh
	cs.position.y = 0.8
	area.add_child(cs)
	root.add_child(area)
	var entry := {
		"name": nname,
		"pos": pos,
		"dir": dir,
		"node": root,
		"ready_ms": 0,
	}
	_pads.append(entry)
	area.body_entered.connect(_on_body_entered.bind(entry))


func _on_body_entered(body: Node, pad: Dictionary) -> void:
	if not _is_walker(body):
		return
	var cb := body as CharacterBody3D
	if not cb.is_on_floor():
		return
	_launch_from(pad, cb)
