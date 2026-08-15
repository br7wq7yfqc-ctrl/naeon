extends Node3D
class_name ClashLanes
## Three-lane readability for Aexion Clash (Predecessor bar).
## Strips + spawn layout; lane towers are live Turrets (faction fire, no P2W).

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

var _mat_cache: Dictionary = {}
var _mesh_cache: Dictionary = {}

func _mat(col: Color, emit: float = 1.2) -> StandardMaterial3D:
	# Share by colour+emission: the arena built 45+ unique materials for a
	# handful of colours, and each one is its own draw call on min spec.
	var key := "%d_%d_%d_%d" % [int(col.r * 32.0), int(col.g * 32.0), int(col.b * 32.0), int(emit * 8.0)]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col * 0.35
	m.metallic = 0.4
	m.roughness = 0.55
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = emit
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a = 0.85
	_mat_cache[key] = m
	return m

func _shared_box(size: Vector3) -> BoxMesh:
	var key := "%.2f_%.2f_%.2f" % [size.x, size.y, size.z]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var bm := BoxMesh.new()
	bm.size = size
	_mesh_cache[key] = bm
	return bm

func _box(size: Vector3, pos: Vector3, col: Color, parent: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _shared_box(size)
	mi.material_override = _mat(col)
	parent.add_child(mi)
	mi.position = pos
	return mi

func _build_lanes() -> void:
	# Perimeter — reads as an arena, not an infinite greybox
	_box(Vector3(HALF * 2.0 + 1.2, 0.35, 0.45), Vector3(0, 0.7, HALF), Color(0.25, 0.7, 0.95) * 0.8)
	_box(Vector3(HALF * 2.0 + 1.2, 0.35, 0.45), Vector3(0, 0.7, -HALF), Color(0.95, 0.2, 0.45) * 0.8)
	_box(Vector3(0.45, 0.35, HALF * 2.0 + 1.2), Vector3(HALF, 0.7, 0), Color(0.7, 0.75, 0.85) * 0.6)
	_box(Vector3(0.45, 0.35, HALF * 2.0 + 1.2), Vector3(-HALF, 0.7, 0), Color(0.7, 0.75, 0.85) * 0.6)
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
		lab.font_size = 28
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
	# halo ring
	var halo := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.55
	torus.outer_radius = 1.85
	torus.rings = 10
	torus.ring_segments = 20
	halo.mesh = torus
	halo.material_override = _mat(col, 2.4)
	halo.position.y = 1.5
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(halo)
	# ring
	_box(Vector3(5.5, 0.15, 5.5), Vector3(0, 0.1, 0), col * 0.8, root)
	var lab := Label3D.new()
	lab.text = "NEXUS\n%s" % fac
	lab.font_size = 28
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
	# Mid-lane towers along Z for both sides — live guns, visual spire stays.
	var towers := [
		[Vector3(0, 0, 12), Color(0.2, 0.8, 1.0), "T_CX_MID", "Cybernex", "MID"],
		[Vector3(0, 0, -12), Color(0.9, 0.2, 0.45), "T_GR_MID", "gROT", "MID"],
		[Vector3(14, 0, 10), Color(0.2, 0.8, 1.0), "T_CX_TOP", "Cybernex", "TOP"],
		[Vector3(14, 0, -10), Color(0.9, 0.2, 0.45), "T_GR_TOP", "gROT", "TOP"],
		[Vector3(-14, 0, 10), Color(0.2, 0.8, 1.0), "T_CX_BOT", "Cybernex", "BOT"],
		[Vector3(-14, 0, -10), Color(0.9, 0.2, 0.45), "T_GR_BOT", "gROT", "BOT"],
	]
	for t in towers:
		var root := Node3D.new()
		root.name = str(t[2])
		add_child(root)
		root.position = t[0]
		root.set_meta("clash_lane", str(t[4]))
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.45
		cyl.bottom_radius = 0.7
		cyl.height = 3.2
		mi.mesh = cyl
		mi.material_override = _mat(t[1], 1.6)
		mi.position.y = 1.6
		mi.name = "Spire"
		root.add_child(mi)
		_box(Vector3(1.8, 0.12, 1.8), Vector3(0, 0.05, 0), t[1], root)
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var cyls := CylinderShape3D.new()
		cyls.radius = 0.72
		cyls.height = 3.2
		cs.shape = cyls
		cs.position.y = 1.6
		body.add_child(cs)
		root.add_child(body)
		var gun := Node3D.new()
		gun.name = "Gun"
		gun.set_script(preload("res://scripts/combat/Turret.gd"))
		gun.set("faction", str(t[3]))
		gun.set("target_player", true)
		gun.set("aggro_range", 15.5)
		gun.set("fire_rate", 1.35)
		gun.set("damage", 6.0)
		gun.set("max_health", 160.0)
		gun.set("projectile_speed", 38.0)
		gun.set("skip_visual", true)
		gun.set("display_name", "TOWER")
		root.add_child(gun)
		if gun.get("_label") != null:
			var lab = gun.get("_label")
			if lab is Label3D:
				(lab as Label3D).position.y = 3.35
				(lab as Label3D).font_size = 18
		# Turret._ready already files itself by faction. Forcing every tower into
		# "enemy" let the player farm their own base for lane pressure.
		if gun.has_signal("died"):
			gun.died.connect(_on_tower_died.bind(root, str(t[4]), str(t[3])))


func _on_tower_died(spire: Node3D, lane: String, fac: String) -> void:
	if spire and is_instance_valid(spire):
		var mesh: MeshInstance3D = spire.get_node_or_null("Spire") as MeshInstance3D
		if mesh and mesh.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = mesh.material_override
			mat.emission_energy_multiplier = 0.18
			var c: Color = mat.albedo_color
			c.a = 0.4
			mat.albedo_color = c
	# Only an enemy tower is progress. Losing your own must not reward you.
	var player_fac := GameManager.get_faction_name() if GameManager else "Cybernex"
	var tree := get_tree()
	if fac != player_fac and tree:
		var clash: Node = tree.get_first_node_in_group("aexion_clash")
		if clash and clash.has_method("register_tower_down"):
			clash.register_tower_down(lane)
		var matchn: Node = tree.get_first_node_in_group("clash_match")
		if matchn and matchn.has_method("register_objective"):
			matchn.register_objective()
		if GameManager:
			GameManager.toast_requested.emit("Tower down (%s %s) — soft lane pressure only" % [fac, lane])
	elif GameManager:
		GameManager.toast_requested.emit("Your %s tower is down (%s)" % [lane, fac])
	print("[ClashLanes] tower down ", fac, " ", lane)

func _build_lane_markers() -> void:
	_lane_label = Label3D.new()
	_lane_label.name = "PlayerLaneHint"
	_lane_label.font_size = 22
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
