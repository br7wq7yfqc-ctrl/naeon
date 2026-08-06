extends Node3D
class_name ClashLanes
## Three-lane readability for Aexion Clash (Predecessor bar).
## Visual + spawn layout only — no combat power.

signal lane_entered(lane_id: String)

const LANE_TOP := "TOP"
const LANE_MID := "MID"
const LANE_BOT := "BOT"

## Arena footprint (matches TestArena floor ~60x60 centered)
const HALF := 28.0
const LANE_HALF_W := 3.2
const Y_STRIP := 0.52

var player_lane: String = LANE_MID
var _lane_label: Label3D

func _ready() -> void:
	name = "ClashLanes"
	_build_lanes()
	_build_nexuses()
	_build_towers()
	_build_lane_markers()
	print("[ClashLanes] TOP/MID/BOT + dual nexus ready")

func _mat(col: Color, emit: float = 1.2) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col * 0.35
	m.metallic = 0.4
	m.roughness = 0.55
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = emit
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a = 0.85
	return m

func _box(size: Vector3, pos: Vector3, col: Color, parent: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col)
	parent.add_child(mi)
	mi.position = pos
	return mi

func _build_lanes() -> void:
	# Lanes run along Z (home south +Z Cybernex → north -Z gROT)
	# TOP = +X, MID = 0, BOT = -X
	var defs := [
		[LANE_TOP, 14.0, Color(0.3, 0.85, 1.0)],   # cyan-ish outer
		[LANE_MID, 0.0, Color(0.95, 0.85, 0.25)],  # gold mid
		[LANE_BOT, -14.0, Color(0.95, 0.25, 0.55)], # magenta outer
	]
	for d in defs:
		var id: String = d[0]
		var x: float = d[1]
		var col: Color = d[2]
		var root := Node3D.new()
		root.name = "Lane_%s" % id
		add_child(root)
		# long strip
		_box(Vector3(LANE_HALF_W * 2.0, 0.08, HALF * 2.0 - 4.0), Vector3(x, Y_STRIP, 0.0), col, root)
		# centerline ticks
		for z in range(-24, 25, 8):
			_box(Vector3(LANE_HALF_W * 2.2, 0.12, 0.35), Vector3(x, Y_STRIP + 0.02, float(z)), col * 1.2, root)
		# Label3D at mid
		var lab := Label3D.new()
		lab.text = id
		lab.font_size = 64
		lab.modulate = col
		lab.outline_modulate = Color(0, 0, 0, 0.9)
		lab.outline_size = 12
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.position = Vector3(x, 2.5, 0.0)
		root.add_child(lab)

func _build_nexuses() -> void:
	# Cybernex base (south +Z) blue, gROT (north -Z) magenta
	_nexus(Vector3(0, 0, 24), Color(0.15, 0.85, 1.0), "NEXUS_CX", "Cybernex")
	_nexus(Vector3(0, 0, -24), Color(0.95, 0.12, 0.42), "NEXUS_GR", "gROT")

func _nexus(pos: Vector3, col: Color, nname: String, fac: String) -> void:
	var root := Node3D.new()
	root.name = nname
	add_child(root)
	root.position = pos
	# core
	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 1.4
	sp.height = 2.8
	mi.mesh = sp
	mi.material_override = _mat(col, 2.0)
	root.add_child(mi)
	# ring
	_box(Vector3(5.5, 0.15, 5.5), Vector3(0, 0.1, 0), col * 0.8, root)
	var lab := Label3D.new()
	lab.text = "NEXUS\n%s" % fac
	lab.font_size = 48
	lab.modulate = col
	lab.outline_size = 10
	lab.outline_modulate = Color(0, 0, 0, 0.9)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.position = Vector3(0, 3.2, 0)
	root.add_child(lab)
	# soft body for presence (no damage — readability prop)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 1.5
	cs.shape = sh
	body.add_child(cs)
	root.add_child(body)

func _build_towers() -> void:
	# Mid-lane towers along Z for both sides
	var towers := [
		[Vector3(0, 0, 12), Color(0.2, 0.8, 1.0), "T_CX_MID"],
		[Vector3(0, 0, -12), Color(0.9, 0.2, 0.45), "T_GR_MID"],
		[Vector3(14, 0, 10), Color(0.2, 0.8, 1.0), "T_CX_TOP"],
		[Vector3(14, 0, -10), Color(0.9, 0.2, 0.45), "T_GR_TOP"],
		[Vector3(-14, 0, 10), Color(0.2, 0.8, 1.0), "T_CX_BOT"],
		[Vector3(-14, 0, -10), Color(0.9, 0.2, 0.45), "T_GR_BOT"],
	]
	for t in towers:
		var root := Node3D.new()
		root.name = str(t[2])
		add_child(root)
		root.position = t[0]
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.45
		cyl.bottom_radius = 0.7
		cyl.height = 3.2
		mi.mesh = cyl
		mi.material_override = _mat(t[1], 1.6)
		mi.position.y = 1.6
		root.add_child(mi)
		_box(Vector3(1.8, 0.12, 1.8), Vector3(0, 0.05, 0), t[1], root)

func _build_lane_markers() -> void:
	_lane_label = Label3D.new()
	_lane_label.name = "PlayerLaneHint"
	_lane_label.font_size = 42
	_lane_label.modulate = Color(1, 1, 1)
	_lane_label.outline_size = 8
	_lane_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_lane_label.position = Vector3(0, 3.5, 18)
	add_child(_lane_label)

func lane_at(pos: Vector3) -> String:
	if pos.x > 7.0:
		return LANE_TOP
	if pos.x < -7.0:
		return LANE_BOT
	return LANE_MID

func update_player(pos: Vector3) -> void:
	var lane := lane_at(pos)
	if lane != player_lane:
		player_lane = lane
		lane_entered.emit(lane)
	if _lane_label:
		_lane_label.text = "YOU · %s LANE" % player_lane

## Spawn points for wave dummies: [pos, lane, faction]
func lane_spawn_table() -> Array:
	return [
		# gROT pressure north-ish mid
		[Vector3(0, 0.1, -8), LANE_MID, "gROT"],
		[Vector3(14, 0.1, -6), LANE_TOP, "gROT"],
		[Vector3(-14, 0.1, -6), LANE_BOT, "gROT"],
		[Vector3(0, 0.1, -16), LANE_MID, "gROT"],
		# mid skirmish
		[Vector3(2, 0.1, 2), LANE_MID, "gROT"],
		[Vector3(14, 0.1, 4), LANE_TOP, "gROT"],
		[Vector3(-12, 0.1, 3), LANE_BOT, "gROT"],
	]
