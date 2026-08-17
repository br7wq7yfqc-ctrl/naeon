extends Node3D
class_name ClashLanes
## Three-lane readability for Aexion Clash (Predecessor bar).
## AR-B: OUTER → MID → INHIB → CORE on the same 60×60 footprint.
## Live Turret HP (no P2W repair). Ledger plate tower_iouter_mid_inhibi — no new SITE_*.

signal lane_entered(lane_id: String)

const LANE_TOP := "TOP"
const LANE_MID := "MID"
const LANE_BOT := "BOT"

const ROLE_OUTER := "OUTER"
const ROLE_MID := "MID"
const ROLE_INHIB := "INHIB"
const ROLE_CORE := "CORE"

## Arena footprint (matches TestArena floor ~60x60 centered)
const HALF := 28.0
const LANE_HALF_W := 3.2
const Y_STRIP := 0.52

var player_lane: String = LANE_MID
var _lane_label: Label3D
## {name, role, lane, faction, node}
var _structures: Array = []

func _ready() -> void:
	name = "ClashLanes"
	_build_lanes()
	_build_structures()
	_build_lane_markers()
	print("[ClashLanes] TOP/MID/BOT + OUTER/MID/INHIB/CORE ready n=", _structures.size())

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
		if DisplayServer.get_name() != "headless":
			var lab := Label3D.new()
			lab.text = id
			lab.font_size = 28
			lab.modulate = col
			lab.outline_modulate = Color(0, 0, 0, 0.9)
			lab.outline_size = 12
			lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lab.position = Vector3(x, 2.5, 0.0)
			root.add_child(lab)

func _build_structures() -> void:
	# Compact Predecessor sequence on the existing floor. Friendly OUTER stays
	# behind the AR-A OTS boom (player z=6, camera ~z=8.6) — z=12 hid the hero.
	# One INHIB per side (core gate) — 60×60 cannot host a third full row per lane.
	# Same Turret piece as Phase0 lane towers; no new mesh / SITE_* / city-map.
	var cx := Color(0.2, 0.8, 1.0)
	var gr := Color(0.9, 0.2, 0.45)
	var rows := [
		# OUTER — existing lane-tower seats
		[Vector3(0, 0, 18), cx, "T_CX_MID_OUTER", "Cybernex", LANE_MID, ROLE_OUTER],
		[Vector3(14, 0, 16), cx, "T_CX_TOP_OUTER", "Cybernex", LANE_TOP, ROLE_OUTER],
		[Vector3(-14, 0, 16), cx, "T_CX_BOT_OUTER", "Cybernex", LANE_BOT, ROLE_OUTER],
		[Vector3(0, 0, -10), gr, "T_GR_MID_OUTER", "gROT", LANE_MID, ROLE_OUTER],
		[Vector3(14, 0, -8), gr, "T_GR_TOP_OUTER", "gROT", LANE_TOP, ROLE_OUTER],
		[Vector3(-14, 0, -8), gr, "T_GR_BOT_OUTER", "gROT", LANE_BOT, ROLE_OUTER],
		# MID — second row toward each base (ledger mid)
		[Vector3(0, 0, 20.6), cx, "T_CX_MID_MID", "Cybernex", LANE_MID, ROLE_MID],
		[Vector3(14, 0, 20.2), cx, "T_CX_TOP_MID", "Cybernex", LANE_TOP, ROLE_MID],
		[Vector3(-14, 0, 20.2), cx, "T_CX_BOT_MID", "Cybernex", LANE_BOT, ROLE_MID],
		[Vector3(0, 0, -16.4), gr, "T_GR_MID_MID", "gROT", LANE_MID, ROLE_MID],
		[Vector3(14, 0, -15.8), gr, "T_GR_TOP_MID", "gROT", LANE_TOP, ROLE_MID],
		[Vector3(-14, 0, -15.8), gr, "T_GR_BOT_MID", "gROT", LANE_BOT, ROLE_MID],
		# INHIB — one shared gate in front of each core
		[Vector3(0, 0, 22.4), cx, "INHIB_CX", "Cybernex", LANE_MID, ROLE_INHIB],
		[Vector3(0, 0, -21.2), gr, "INHIB_GR", "gROT", LANE_MID, ROLE_INHIB],
		# CORE — former nexus props, now honest HP
		[Vector3(0, 0, 24), Color(0.15, 0.85, 1.0), "NEXUS_CX", "Cybernex", LANE_MID, ROLE_CORE],
		[Vector3(0, 0, -24), Color(0.95, 0.12, 0.42), "NEXUS_GR", "gROT", LANE_MID, ROLE_CORE],
	]
	for t in rows:
		_place_structure(t[0], t[1], str(t[2]), str(t[3]), str(t[4]), str(t[5]))


func _role_combat(role: String) -> Dictionary:
	match role:
		ROLE_OUTER:
			return {"hp": 160.0, "aggro": 15.5, "rate": 1.35, "dmg": 6.0, "label_y": 3.35}
		ROLE_MID:
			return {"hp": 200.0, "aggro": 12.0, "rate": 1.5, "dmg": 5.0, "label_y": 3.05}
		ROLE_INHIB:
			return {"hp": 260.0, "aggro": 8.0, "rate": 2.4, "dmg": 4.0, "label_y": 2.65}
		_:
			return {"hp": 360.0, "aggro": 10.0, "rate": 1.8, "dmg": 7.0, "label_y": 3.55}


func _place_structure(pos: Vector3, col: Color, nname: String, fac: String, lane: String, role: String) -> void:
	var root := Node3D.new()
	root.name = nname
	add_child(root)
	root.position = pos
	root.set_meta("clash_lane", lane)
	root.set_meta("clash_role", role)
	root.set_meta("clash_faction", fac)
	root.add_to_group("clash_structure")
	if role == ROLE_CORE:
		_build_core_hull(root, col, fac)
	else:
		_build_tower_hull(root, col, role)
	var spec: Dictionary = _role_combat(role)
	var gun := Node3D.new()
	gun.name = "Gun"
	gun.set_script(preload("res://scripts/combat/Turret.gd"))
	gun.set("faction", fac)
	gun.set("target_player", true)
	gun.set("aggro_range", float(spec["aggro"]))
	gun.set("fire_rate", float(spec["rate"]))
	gun.set("damage", float(spec["dmg"]))
	gun.set("max_health", float(spec["hp"]))
	gun.set("projectile_speed", 38.0)
	gun.set("skip_visual", true)
	gun.set("display_name", role)
	root.add_child(gun)
	if gun.get("_label") != null:
		var lab = gun.get("_label")
		if lab is Label3D:
			(lab as Label3D).position.y = float(spec["label_y"])
			(lab as Label3D).font_size = 16 if role != ROLE_CORE else 20
	if gun.has_signal("died"):
		gun.died.connect(_on_structure_died.bind(root, lane, fac, role))
	_structures.append({
		"name": nname,
		"role": role,
		"lane": lane,
		"faction": fac,
		"node": root,
	})


func _build_tower_hull(root: Node3D, col: Color, role: String) -> void:
	var h := 3.2
	var r_top := 0.45
	var r_bot := 0.7
	var pad := 1.8
	if role == ROLE_MID:
		h = 2.8
		r_top = 0.5
		r_bot = 0.85
		pad = 2.0
	elif role == ROLE_INHIB:
		h = 2.1
		r_top = 0.85
		r_bot = 1.15
		pad = 2.6
	var mi := MeshInstance3D.new()
	mi.name = "Spire"
	if DisplayServer.get_name() == "headless":
		var box := BoxMesh.new()
		box.size = Vector3(r_bot * 2.0, h, r_bot * 2.0)
		mi.mesh = box
	else:
		var cyl := CylinderMesh.new()
		cyl.top_radius = r_top
		cyl.bottom_radius = r_bot
		cyl.height = h
		mi.mesh = cyl
	mi.material_override = _mat(col, 1.6 if role != ROLE_INHIB else 1.9)
	mi.position.y = h * 0.5
	root.add_child(mi)
	_box(Vector3(pad, 0.12, pad), Vector3(0, 0.05, 0), col, root)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var cyls := CylinderShape3D.new()
	cyls.radius = r_bot + 0.02
	cyls.height = h
	cs.shape = cyls
	cs.position.y = h * 0.5
	body.add_child(cs)
	root.add_child(body)


func _build_core_hull(root: Node3D, col: Color, fac: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Spire"
	if DisplayServer.get_name() == "headless":
		var core := BoxMesh.new()
		core.size = Vector3(2.4, 2.4, 2.4)
		mi.mesh = core
	else:
		var sp := SphereMesh.new()
		sp.radius = 1.4
		sp.height = 2.8
		mi.mesh = sp
	mi.material_override = _mat(col, 2.0)
	root.add_child(mi)
	var halo := MeshInstance3D.new()
	if DisplayServer.get_name() == "headless":
		var halo_box := BoxMesh.new()
		halo_box.size = Vector3(3.4, 0.15, 3.4)
		halo.mesh = halo_box
	else:
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
	_box(Vector3(5.5, 0.15, 5.5), Vector3(0, 0.1, 0), col * 0.8, root)
	if DisplayServer.get_name() != "headless":
		var lab := Label3D.new()
		lab.text = "CORE\n%s" % fac
		lab.font_size = 28
		lab.modulate = col
		lab.outline_size = 10
		lab.outline_modulate = Color(0, 0, 0, 0.9)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.position = Vector3(0, 3.2, 0)
		root.add_child(lab)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 1.5
	cs.shape = sh
	body.add_child(cs)
	root.add_child(body)


func _on_structure_died(spire: Node3D, lane: String, fac: String, role: String) -> void:
	if spire and is_instance_valid(spire):
		var mesh: MeshInstance3D = spire.get_node_or_null("Spire") as MeshInstance3D
		if mesh and mesh.material_override is StandardMaterial3D:
			# Duplicate — hulls share the colour cache; mutating it dimmed every peer.
			var mat: StandardMaterial3D = (mesh.material_override as StandardMaterial3D).duplicate()
			mat.emission_energy_multiplier = 0.18
			var c: Color = mat.albedo_color
			c.a = 0.4
			mat.albedo_color = c
			mesh.material_override = mat
	var player_fac := GameManager.get_faction_name() if GameManager else "Cybernex"
	var tree := get_tree()
	if fac != player_fac and tree:
		var clash: Node = tree.get_first_node_in_group("aexion_clash")
		if clash and clash.has_method("register_structure_down"):
			clash.register_structure_down(role, lane)
		elif clash and clash.has_method("register_tower_down"):
			clash.register_tower_down(lane)
		var matchn: Node = tree.get_first_node_in_group("clash_match")
		if matchn and matchn.has_method("register_objective"):
			matchn.register_objective()
		if GameManager:
			GameManager.toast_requested.emit(
				"%s down (%s %s) — soft lane pressure only" % [role, fac, lane]
			)
	elif GameManager:
		GameManager.toast_requested.emit("Your %s is down (%s %s)" % [role, lane, fac])
	print("[ClashLanes] structure down ", role, " ", fac, " ", lane)


func structure_table() -> Array:
	return _structures.duplicate()


func find_structure(role: String, fac: String, lane: String = "") -> Node3D:
	for e in _structures:
		if str(e.get("role", "")) != role:
			continue
		if str(e.get("faction", "")) != fac:
			continue
		if lane != "" and str(e.get("lane", "")) != lane:
			continue
		var n: Node3D = e.get("node") as Node3D
		if n and is_instance_valid(n):
			return n
	return null


func living_roles() -> PackedStringArray:
	var seen: PackedStringArray = PackedStringArray()
	for e in _structures:
		var n: Node3D = e.get("node") as Node3D
		if n == null or not is_instance_valid(n):
			continue
		var gun: Node = n.get_node_or_null("Gun")
		if gun and gun.has_method("is_alive") and not bool(gun.is_alive()):
			continue
		var role := str(e.get("role", ""))
		if role != "" and not seen.has(role):
			seen.append(role)
	return seen

func _build_lane_markers() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_lane_label = Label3D.new()
	_lane_label.name = "PlayerLaneHint"
	_lane_label.font_size = 22
	_lane_label.modulate = Color(1, 1, 1)
	_lane_label.outline_size = 8
	_lane_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_lane_label.position = Vector3(0, 3.8, 10)
	add_child(_lane_label)

func lane_at(pos: Vector3) -> String:
	if pos.x > 7.0:
		return LANE_TOP
	if pos.x < -7.0:
		return LANE_BOT
	return LANE_MID


func is_off_lane(pos: Vector3) -> bool:
	# Strips are ±LANE_HALF_W around 0 / ±14. Jungle pocket sits between them.
	var x := pos.x
	if absf(x) <= LANE_HALF_W + 0.4:
		return false
	if absf(x - 14.0) <= LANE_HALF_W + 0.4:
		return false
	if absf(x + 14.0) <= LANE_HALF_W + 0.4:
		return false
	return true

func update_player(pos: Vector3) -> void:
	var lane := lane_at(pos)
	if lane != player_lane:
		player_lane = lane
		lane_entered.emit(lane)
	if _lane_label:
		_lane_label.text = "YOU · %s LANE" % player_lane

func lane_x(lane: String) -> float:
	if lane == LANE_TOP:
		return 14.0
	if lane == LANE_BOT:
		return -14.0
	return 0.0


func lane_spawn_origin(lane: String, faction: String) -> Vector3:
	var x := lane_x(lane)
	# In front of own OUTER, walking toward the opposite core. Stay off the
	# AR-A spawn camera (player z=6, boom ~z=8.6).
	if faction == "Cybernex":
		return Vector3(x, 0.1, 12.4)
	return Vector3(x, 0.1, -5.4)


func lane_march_path(lane: String, faction: String) -> Array:
	var x := lane_x(lane)
	if faction == "Cybernex":
		return [
			Vector3(x, 0.1, 8.0),
			Vector3(x, 0.1, 0.0),
			Vector3(x, 0.1, -8.0),
			Vector3(x, 0.1, -16.0),
			Vector3(x, 0.1, -23.0),
		]
	return [
		Vector3(x, 0.1, -2.0),
		Vector3(x, 0.1, 6.0),
		Vector3(x, 0.1, 16.0),
		Vector3(x, 0.1, 20.5),
		Vector3(x, 0.1, 23.5),
	]


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
