extends Node3D

## Aexion Clash vertical slice — OTS 3rd-person kits + soft War Score (Predecessor bar).
## Soft world influence only; never permanent planet flip from Arena alone.

@onready var hud: CanvasLayer = $HUD
@onready var info_label: Label = $HUD/Root/Info
@onready var bar_health: ProgressBar = $HUD/Root/HealthBar
@onready var bar_energy: ProgressBar = $HUD/Root/EnergyBar
@onready var ability_label: Label = $HUD/Root/Abilities
@onready var contrib_label: Label = $HUD/Root/Contribution
@onready var player: CharacterBody3D = $Player
@onready var kills_label: Label = $HUD/Root/Kills

var kills: int = 0
var _match_over: bool = false
var _clash: Node = null
var _lanes: Node3D = null
var _radar: Control = null
var _lane_hud: Label = null
var dummy_scene: PackedScene = preload("res://scenes/combat/CombatDummy.tscn")

func _ready() -> void:
	var _PoolReset = load("res://scripts/combat/ProjectilePool.gd")
	if _PoolReset and _PoolReset.has_method("reset_counters"):
		_PoolReset.reset_counters()
	_apply_arena_perf()
	_phase0_arena_feel()
	_ensure_clash_director()
	print("[TestArena] Loaded — Aexion Clash slice")
	if player and player.has_method("apply_clash_ots"):
		player.apply_clash_ots()
	_clash = Node.new()
	_clash.set_script(preload("res://scripts/arena/AexionClash.gd"))
	_clash.name = "AexionClash"
	add_child(_clash)
	call_deferred("_finish_clash_layout")
	var au: Node = get_node_or_null("/root/AutoUpdater")
	if au != null and au.has_signal("update_available"):
		au.connect("update_available", Callable(self, "_on_update_available"))
	if GameManager:
		GameManager.add_mastery("cybernetics", 5.0)
		GameManager.contribution_changed.connect(_on_contrib)
	_on_contrib(GameManager.contribution if GameManager else 0.0)
	_upgrade_environment_materials()
	_spawn_dummies()
	_spawn_props()
	_spawn_cover()
	_soft_neon_ambient()
	_spawn_turrets()
	_spawn_claim_nodes()
	# Look-dev boards sat between the camera and the spawn, filling the screen
	# on load. Keep them behind the north nexus.
	var CP = load("res://scripts/assets/CanonPlates.gd")
	if CP:
		CP.spawn_arena_wall(self, Vector3(0, 0, 34))
	if kills_label:
		kills_label.text = "Kills: 0"
	_apply_arena_hud_layout()


func _upgrade_environment_materials() -> void:
	var floor_body := get_node_or_null("Floor")
	if floor_body:
		var mesh_i := floor_body.get_node_or_null("Mesh") as MeshInstance3D
		if mesh_i:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.07, 0.09, 0.12)
			mat.metallic = 0.55
			mat.roughness = 0.72
			mat.emission_enabled = true
			mat.emission = Color(0.02, 0.12, 0.18)
			mat.emission_energy_multiplier = 0.35
			mat.uv1_scale = Vector3(12, 12, 12)
			mat.uv1_triplanar = true
			mesh_i.material_override = mat
	for pillar_name in ["ClaimPillarA", "ClaimPillarB", "Barrier"]:
		var n := get_node_or_null(pillar_name)
		if n == null:
			continue
		for c in n.get_children():
			if c is MeshInstance3D:
				var m := StandardMaterial3D.new()
				m.albedo_color = Color(0.18, 0.2, 0.24)
				m.metallic = 0.65
				m.roughness = 0.4
				m.emission_enabled = true
				m.emission = Color(0.15, 0.55, 0.75)
				m.emission_energy_multiplier = 0.55
				(c as MeshInstance3D).material_override = m

func _spawn_dummies() -> void:
	# Lane-slotted hostiles for MOBA readability (TOP/MID/BOT)
	var table: Array = []
	if _lanes and _lanes.has_method("lane_spawn_table"):
		table = _lanes.lane_spawn_table()
	else:
		table = [
			[Vector3(0, 0.1, -8), "MID", "gROT"],
			[Vector3(14, 0.1, -6), "TOP", "gROT"],
			[Vector3(-14, 0.1, -6), "BOT", "gROT"],
			[Vector3(0, 0.1, -16), "MID", "gROT"],
			[Vector3(2, 0.1, 2), "MID", "gROT"],
			[Vector3(14, 0.1, 4), "TOP", "gROT"],
			[Vector3(-12, 0.1, 3), "BOT", "gROT"],
		]
	var cap := table.size()
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq:
		match int(gq.tier):
			0: cap = mini(cap, 3)
			1: cap = mini(cap, 5)
			2: cap = mini(cap, 6)
			_: cap = mini(cap, table.size())
	for i in mini(table.size(), cap):
		var entry = table[i]
		var d: Node = dummy_scene.instantiate()
		# Faction before add_child — _ready() reads it for groups and mesh.
		d.set("faction", str(entry[2]))
		# Outer lane dummies hold; mid skirmishes can move
		if str(entry[1]) != "MID":
			d.set("can_move", false)
		add_child(d)
		d.global_position = entry[0]
		d.set_meta("lane", str(entry[1]))
		if d.has_signal("died"):
			d.died.connect(_on_dummy_died.bind(str(entry[1])))

func _spawn_props() -> void:
	# Sprint C enemy mesh sample
	var thrall := Node3D.new()
	thrall.set_script(preload("res://scripts/assets/GlbProp.gd"))
	thrall.set("relative_path", "characters/grot_thrall/grot_thrall_grot_lod0.glb")
	thrall.set("scale_factor", 1.0)
	thrall.set("add_static_collision", false)
	add_child(thrall)
	thrall.global_position = Vector3(6, 0, 8)
	var sentry := Node3D.new()
	sentry.set_script(preload("res://scripts/assets/GlbProp.gd"))
	sentry.set("relative_path", "characters/cybernex_sentry/cybernex_sentry_cybernex_lod0.glb")
	sentry.set("scale_factor", 1.0)
	sentry.set("add_static_collision", false)
	add_child(sentry)
	sentry.global_position = Vector3(-6, 0, 8)
	var prop_script: Script = preload("res://scripts/assets/GlbProp.gd")
	var positions: Array = [
		# crates / storage
		[Vector3(2, 0, 3), "props/sci_fi_crate/sci_fi_crate_cybernex_lod2.glb", 0.7],
		[Vector3(-3, 0, 2), "props/sci_fi_crate/sci_fi_crate_grot_lod2.glb", 0.7],
		[Vector3(-2, 0, 10), "props/storage_barrel/storage_barrel_cybernex_lod2.glb", 0.6],
		[Vector3(1, 0, 10), "props/ammo_crate/ammo_crate_cybernex_lod2.glb", 0.7],
		# consoles / stations
		[Vector3(-6, 0, -3), "props/control_console/control_console_cybernex_lod1.glb", 0.9],
		[Vector3(8, 0, -5), "props/control_console/control_console_grot_lod1.glb", 0.9],
		[Vector3(-14, 0, -4), "props/med_station/med_station_cybernex_lod1.glb", 0.9],
		[Vector3(3, 0, 6), "props/holo_projector/holo_projector_cybernex_lod2.glb", 0.8],
		# ownership / combat
		[Vector3(0, 0, -12), "props/claim_beacon/claim_beacon_cybernex_lod1.glb", 1.0],
		[Vector3(3, 0, -12), "props/claim_beacon/claim_beacon_grot_lod1.glb", 1.0],
		[Vector3(-12, 0, 0), "props/energy_barrier/energy_barrier_cybernex_lod2.glb", 0.8],
		[Vector3(12, 0, 0), "props/energy_barrier/energy_barrier_grot_lod2.glb", 0.8],
		[Vector3(6, 0, -9), "props/turret_emplacement/turret_emplacement_grot_lod1.glb", 0.85],
		# colony / env
		[Vector3(14, 0, 6), "colony/colony_habitat/colony_habitat_cybernex_lod1.glb", 1.2],
		[Vector3(-8, 0, 8), "colony/solar_panel/solar_panel_cybernex_lod2.glb", 1.0],
		[Vector3(10, 0, 10), "colony/fuel_tank/fuel_tank_cybernex_lod2.glb", 0.9],
		[Vector3(0, 0, 14), "props/antenna_array/antenna_array_cybernex_lod2.glb", 1.0],
		[Vector3(5, 0, 12), "props/nex_relay/nex_relay_cybernex_lod2.glb", 1.0],
		[Vector3(0, 0, -16), "environments/gate_arch/gate_arch_cybernex_lod1.glb", 1.5],
		[Vector3(-4, 0, 5), "environments/walkway_segment/walkway_segment_cybernex_lod2.glb", 1.2],
	]
	var prop_cap := positions.size()
	var gq2 := get_node_or_null("/root/GraphicsQuality")
	if gq2:
		match int(gq2.tier):
			0: prop_cap = mini(prop_cap, 6)
			1: prop_cap = mini(prop_cap, 11)
			_: prop_cap = positions.size()
	# Prefer lod2 paths on LOW (string replace)
	for i in mini(positions.size(), prop_cap):
		var entry = positions[i]
		var rel: String = str(entry[1])
		if gq2 and int(gq2.tier) <= 1:
			rel = rel.replace("_lod0.", "_lod2.").replace("_lod1.", "_lod2.")
		var prop: Node3D = Node3D.new()
		prop.set_script(prop_script)
		prop.set("relative_path", rel)
		prop.set("scale_factor", float(entry[2]))
		prop.set("add_static_collision", false)
		add_child(prop)
		prop.global_position = entry[0]






func _spawn_cover() -> void:
	## Procedural low walls + crates for TPS cover readability (no Tripo).
	var spots: Array = [
		[Vector3(4, 0, -4), Vector3(3.2, 1.1, 0.45)],
		[Vector3(-5, 0, -5), Vector3(2.8, 1.0, 0.4)],
		[Vector3(0, 0, -11), Vector3(4.0, 1.25, 0.5)],
		[Vector3(10, 0, -2), Vector3(0.45, 1.3, 2.5)],
		[Vector3(-10, 0, -1), Vector3(0.45, 1.2, 2.8)],
		[Vector3(7, 0, 6), Vector3(2.0, 0.9, 0.4)],
	]
	var gq := get_node_or_null("/root/GraphicsQuality")
	var n_spots := spots.size()
	if gq and int(gq.tier) == 0:
		n_spots = 3
	elif gq and int(gq.tier) == 1:
		n_spots = 4
	# Shared materials (avoid per-block StandardMaterial3D thrash)
	var mat_a := StandardMaterial3D.new()
	mat_a.albedo_color = Color(0.14, 0.16, 0.2)
	mat_a.metallic = 0.55
	mat_a.roughness = 0.55
	mat_a.emission_enabled = true
	mat_a.emission = Color(0.1, 0.45, 0.65)
	mat_a.emission_energy_multiplier = 0.35
	var mat_b := mat_a.duplicate() as StandardMaterial3D
	mat_b.emission = Color(0.55, 0.12, 0.28)
	var edge_a := StandardMaterial3D.new()
	edge_a.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge_a.albedo_color = Color(0.2, 0.85, 1.0)
	edge_a.emission_enabled = true
	edge_a.emission = edge_a.albedo_color
	edge_a.emission_energy_multiplier = 1.2
	var edge_b := edge_a.duplicate() as StandardMaterial3D
	edge_b.albedo_color = Color(0.95, 0.2, 0.4)
	edge_b.emission = edge_b.albedo_color
	var root_c := Node3D.new()
	root_c.name = "CoverField"
	add_child(root_c)
	for i in n_spots:
		var e = spots[i]
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = e[0]
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = e[1]
		cs.shape = box
		body.add_child(cs)
		if DisplayServer.get_name() != "headless":
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = e[1]
			mi.mesh = bm
			mi.material_override = mat_a if i % 2 == 0 else mat_b
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			body.add_child(mi)
			var edge := MeshInstance3D.new()
			var eb := BoxMesh.new()
			eb.size = Vector3(e[1].x * 0.95, 0.06, e[1].z * 0.95)
			edge.mesh = eb
			edge.material_override = edge_a if i % 2 == 0 else edge_b
			edge.position = Vector3(0, e[1].y * 0.5 + 0.02, 0)
			edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			edge.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			body.add_child(edge)
		root_c.add_child(body)
	print("[TestArena] cover blocks ", n_spots)

func _spawn_turrets() -> void:
	var tscn: PackedScene = load("res://scenes/combat/Turret.tscn")
	if tscn == null:
		return
	var spots: Array = [
		[Vector3(6, 0, -9), "gROT"],
		[Vector3(-11, 0, -6), "gROT"],
		[Vector3(9, 0, 4), "Cybernex"],
	]
	var tcap := spots.size()
	var gqt := get_node_or_null("/root/GraphicsQuality")
	if gqt:
		match int(gqt.tier):
			0: tcap = mini(tcap, 1)
			1: tcap = mini(tcap, 2)
			_: tcap = mini(tcap, spots.size())
	for si in mini(spots.size(), tcap):
		var s = spots[si]
		var turr: Node = tscn.instantiate()
		# Faction before add_child: _ready() picks the target group, mesh and
		# label from it, so a late set left a "Cybernex" turret tagged gROT.
		turr.set("faction", s[1])
		turr.set("target_player", s[1] == "gROT")
		add_child(turr)
		turr.global_position = s[0]

func _spawn_claim_nodes() -> void:
	# Lane beacons start Neutral — C pulse / Hack occupy-to-hold, no pre-claim.
	var spots: Array = [
		[Vector3(0, 0, -12), "MID"],
		[Vector3(14, 0, -10), "TOP"],
		[Vector3(-14, 0, -10), "BOT"],
	]
	for s in spots:
		var n := Node3D.new()
		n.name = "ClaimNode"
		n.set_meta("lane", str(s[1]))
		var own := Node3D.new()
		own.name = "Ownership"
		own.set_script(preload("res://scripts/ownership/OwnershipComponent.gd"))
		own.set("dual_mesh_base", "props/claim_beacon/claim_beacon")
		own.set("claimable", true)
		n.add_child(own)
		if DisplayServer.get_name() != "headless":
			var mesh := MeshInstance3D.new()
			mesh.name = "Mesh"
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.25
			cyl.bottom_radius = 0.35
			cyl.height = 1.6
			mesh.mesh = cyl
			own.add_child(mesh)
		add_child(n)
		n.global_position = s[0]
		if own.has_signal("fully_claimed"):
			own.fully_claimed.connect(_on_beacon_claimed.bind(str(s[1])))

func _on_beacon_claimed(_fac, lane: String = "MID") -> void:
	var md = get_node_or_null("ClashMatchDirector")
	if md and md.has_method("register_objective"):
		md.register_objective()
	if _clash and _clash.has_method("_add_pressure"):
		_clash._add_pressure(lane, 28.0)
	elif _clash and "lane_pressure" in _clash:
		var lp: Dictionary = _clash.lane_pressure
		var k := lane if lp.has(lane) else "MID"
		lp[k] = clampf(float(lp.get(k, 0.0)) + 28.0, 0.0, 100.0)


func _on_dummy_died(lane: String = "") -> void:
	if SessionObjectives:
		SessionObjectives.on_landed_or_lane()
	if AudioDirector:
		AudioDirector.play_hit(true)
	call_deferred("_maybe_refill_lane")
	# Credit the lane the kill happened on, not the one the player stands in.
	var lane_k := lane
	if lane_k == "" and _lanes and "player_lane" in _lanes:
		lane_k = str(_lanes.player_lane)
	if lane_k == "":
		lane_k = "MID"
	if _clash and _clash.has_method("register_kill"):
		_clash.register_kill(lane_k)
	# The director owns the kill reward (soft economy + mastery + flash).
	var md := get_node_or_null("ClashMatchDirector")
	if md and md.has_method("register_kill"):
		md.register_kill()
	if kills_label:
		# AexionClash is the single source of truth for the count.
		kills = int(_clash.kills) if _clash and "kills" in _clash else kills + 1
		var extra := ""
		if _clash and _clash.has_method("status_line"):
			extra = "  |  " + str(_clash.status_line())
		kills_label.text = "Kills: %d%s" % [kills, extra]

var _ui_accum: float = 0.0

func _process(_delta: float) -> void:
	if player == null:
		return
	_ui_accum += _delta
	# Radar + labels ~10 Hz (was every frame)
	if _ui_accum < 0.2:
		return
	_ui_accum = 0.0
	_update_clash_radar()
	_apply_arena_hud_layout()
	if not ("health" in player):
		return
	# max first: assigning value against a stale maximum clamps it.
	bar_health.max_value = player.max_health
	bar_health.value = player.health
	bar_energy.max_value = player.max_energy
	bar_energy.value = player.energy
	_try_med_heal(_delta)
	var lines: PackedStringArray = []
	if player.ability_system:
		for i in range(mini(4, player.ability_system.abilities.size())):
			var ab: Ability = player.ability_system.abilities[i]
			if ab == null:
				continue
			var cd: float = player.ability_system.get_cooldown_remaining(i)
			var key: String = ["Q", "E", "R", "F"][i]
			if cd > 0.0:
				lines.append("%s %s (%.1fs)" % [key, ab.ability_name, cd])
			else:
				lines.append("%s %s" % [key, ab.ability_name])
	if _arena_debug():
		ability_label.text = "\n".join(lines)
		var mvin: Vector2 = Vector2.ZERO
		if "last_move_input" in player:
			mvin = player.last_move_input
		info_label.text = (
			"NAEON CLASH | %s | Form %s | O=OpenSpace | 3 LANES + radar | soft WS\n" % [
				player.faction, player.current_form
			]
			+ "Q/E/R/F abilities | input(%.0f,%.0f) floor=%s | med heals  |  F3 HUD" % [
				mvin.x, mvin.y, str(player.is_on_floor())
			]
		)
	if contrib_label and _clash and _clash.has_method("status_line"):
		var econ2 := GameManager.economy_label() if GameManager and GameManager.has_method("economy_label") else ""
		var obj := ""
		if _clash.has_method("objectives_secured"):
			obj = "  |  OBJ %d/3" % int(_clash.objectives_secured())
		contrib_label.text = "%s  |  %s%s" % [econ2, _clash.status_line(), obj]

func _try_med_heal(delta: float) -> void:
	if player == null or not ("health" in player):
		return
	var med_pos := Vector3(-14, 0, -4)
	if player.global_position.distance_to(med_pos) < 3.5:
		if player.health < player.max_health and player.has_method("heal"):
			player.heal(8.0 * delta)

func _on_contrib(v: float) -> void:
	if contrib_label:
		var econ := GameManager.economy_label() if GameManager and GameManager.has_method("economy_label") else ("C:%.1f" % v)
		var ws := ""
		if _clash and _clash.get("war") != null and _clash.war.has_method("hud_line"):
			ws = "  |  " + _clash.war.hud_line()
		contrib_label.text = "%s  |  Knowledge: %d%s" % [
			econ, GameManager.knowledge_rank if GameManager else 0, ws
		]

func _on_update_available(version: String, notes: String) -> void:
	print("[TestArena] Update available: ", version, " ", notes)
	if info_label:
		info_label.text += "\n⬆ Update %s available" % version

func _goto_openspace() -> void:
	if ResourceLoader.exists("res://scenes/world/OpenSpace.tscn"):
		get_tree().change_scene_to_file("res://scenes/world/OpenSpace.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if _match_over and event is InputEventKey and event.pressed \
		and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		get_tree().reload_current_scene()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_O:
		_goto_openspace()
		return
	if event.is_action_pressed("ui_home") or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
		if ResourceLoader.exists("res://scenes/test/SpaceTest.tscn"):
			get_tree().change_scene_to_file("res://scenes/test/SpaceTest.tscn")


func _finish_clash_layout() -> void:
	_lanes = Node3D.new()
	_lanes.set_script(preload("res://scripts/arena/ClashLanes.gd"))
	_lanes.name = "ClashLanes"
	add_child(_lanes)
	_setup_clash_radar()
	_spawn_clash_landmarks()
	if _clash and _clash.has_method("bind_player") and player:
		_clash.bind_player(player)
	# The match used to end silently: active=false and nobody listening.
	if _clash and _clash.has_signal("match_ended") \
		and not _clash.match_ended.is_connected(_on_match_ended):
		_clash.match_ended.connect(_on_match_ended)
	if SoftNetSession and player:
		SoftNetSession.bind_player(player)
	_evidence_ar_a()
	_setup_arena_playtest()


func _on_match_ended(winner: String) -> void:
	var obj := 0
	if _clash and _clash.has_method("objectives_secured"):
		obj = int(_clash.objectives_secured())
	var ws := ""
	if _clash and _clash.get("war") != null and _clash.war.has_method("hud_line"):
		ws = str(_clash.war.hud_line())
	_show_match_result("CLASH COMPLETE — %s\nkills %d  ·  lanes %d/3\n%s\nEnter: rematch   ·   Esc: menu" % [
		winner, int(_clash.kills) if _clash else 0, obj, ws,
	])


func _show_match_result(text: String) -> void:
	if hud == null:
		return
	var root: Control = hud.get_node_or_null("Root")
	if root == null:
		return
	if root.has_node("MatchResult"):
		return
	# Top-centre and compact: a centred panel covered the fight underneath it.
	var panel := PanelContainer.new()
	panel.name = "MatchResult"
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -250
	panel.offset_right = 250
	panel.offset_top = 96
	panel.offset_bottom = 208
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.06, 0.1, 0.88)
	sb.border_color = Color(0.25, 0.85, 1.0, 0.7)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)
	var lab := Label.new()
	lab.text = text
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 17)
	lab.add_theme_color_override("font_color", Color(0.9, 0.97, 1.0))
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lab.add_theme_constant_override("outline_size", 5)
	panel.add_child(lab)
	root.add_child(panel)
	_match_over = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _setup_clash_radar() -> void:
	if hud == null:
		return
	var root: Control = hud.get_node_or_null("Root")
	if root == null:
		return
	_radar = Control.new()
	_radar.set_script(preload("res://scripts/arena/ClashRadar.gd"))
	_radar.name = "ClashRadar"
	_radar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_radar.offset_left = -156
	_radar.offset_top = -170
	_radar.offset_right = -12
	_radar.offset_bottom = -26
	root.add_child(_radar)
	_lane_hud = Label.new()
	_lane_hud.name = "LaneHUD"
	# Anchored here, not in the per-tick layout pass: that pass first runs from
	# _ready, before this label exists, so the styling never landed.
	_lane_hud.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_lane_hud.offset_left = -440
	_lane_hud.offset_right = -16
	_lane_hud.offset_top = 70
	_lane_hud.offset_bottom = 100
	_lane_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lane_hud.add_theme_font_size_override("font_size", 14)
	_lane_hud.add_theme_color_override("font_color", Color(0.95, 0.9, 0.4))
	_lane_hud.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_lane_hud.add_theme_constant_override("outline_size", 4)
	_lane_hud.text = "LANE · MID"
	root.add_child(_lane_hud)


func _update_clash_radar() -> void:
	if player == null:
		return
	if _lanes and _lanes.has_method("update_player"):
		_lanes.update_player(player.global_position)
		if _lane_hud and "player_lane" in _lanes:
			var press := ""
			if _clash and _clash.has_method("lane_hud_line"):
				press = str(_clash.lane_hud_line())
			if press == "":
				_lane_hud.text = "LANE %s" % _lanes.player_lane
			else:
				_lane_hud.text = "LANE %s  ·  %s" % [_lanes.player_lane, press]
	if _radar == null or not _radar.has_method("set_snapshot"):
		return
	# One entry per node: the old second pass compared a Node against an Array
	# of Vector3, so every gROT node was plotted twice.
	var ene: Array = []
	var all: Array = []
	for c in get_children():
		if c == player or not (c is Node3D) or not is_instance_valid(c):
			continue
		if c.get("_alive") == false:
			continue
		var fac := ""
		if "faction" in c:
			fac = str(c.faction)
		elif c.has_meta("lane"):
			fac = "gROT"
		if fac == "gROT":
			ene.append((c as Node3D).global_position)
		elif fac == "Cybernex":
			all.append((c as Node3D).global_position)
	var nex := [
		[Vector3(0, 0, 24), Color(0.15, 0.85, 1.0)],
		[Vector3(0, 0, -24), Color(0.95, 0.12, 0.42)],
	]
	_radar.set_snapshot(player.global_position, ene, all, nex)


func _maybe_refill_lane() -> void:
	var alive := 0
	for c in get_children():
		if not (c is Node3D and is_instance_valid(c) and c.has_meta("lane")):
			continue
		# A corpse stays in the tree until respawn; only living holds count,
		# or the cap is reached once and reinforcement never runs again.
		if c.get("_alive") == false:
			continue
		if c.is_in_group("enemy") or c.has_method("take_damage"):
			alive += 1
	if alive >= 4 or dummy_scene == null:
		return
	var table: Array = _lanes.lane_spawn_table() if _lanes and _lanes.has_method("lane_spawn_table") else []
	if table.is_empty():
		return
	var entry = table[randi() % table.size()]
	var d: Node = dummy_scene.instantiate()
	d.set("faction", str(entry[2]))
	if str(entry[1]) != "MID":
		d.set("can_move", false)
	add_child(d)
	d.global_position = entry[0]
	d.set_meta("lane", str(entry[1]))
	if d.has_signal("died"):
		d.died.connect(_on_dummy_died.bind(str(entry[1])))
	if GameManager:
		GameManager.toast_requested.emit("Lane wave: %s reinforced" % str(entry[1]))


func _phase0_arena_feel() -> void:
	## Predecessor-ish readable arena chrome (code-only).
	var we := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		var e := we.environment
		e.glow_enabled = true
		e.glow_intensity = 0.25
		e.glow_bloom = 0.08
		e.tonemap_mode = Environment.TONE_MAPPER_ACES
		e.adjustment_enabled = true
		e.adjustment_saturation = 1.08
	# Lane light pillars — tier-capped (omni lights are FPS killers on 1060)
	var gq := get_node_or_null("/root/GraphicsQuality")
	var n_lights := 3
	if gq:
		match int(gq.tier):
			0: n_lights = 1
			1: n_lights = 2
			_: n_lights = 3
		if not bool(gq.glow):
			var we2 := get_node_or_null("WorldEnvironment") as WorldEnvironment
			if we2 and we2.environment:
				we2.environment.glow_enabled = false
	for i in n_lights:
		var o := OmniLight3D.new()
		o.light_color = [Color(0.2, 0.8, 1), Color(1, 0.85, 0.3), Color(1, 0.25, 0.4)][i]
		o.light_energy = 0.55 if gq and int(gq.tier) == 0 else 0.75
		o.omni_range = 10.0 if gq and int(gq.tier) == 0 else 14.0
		o.shadow_enabled = false
		o.position = Vector3([-22, 0, 22][i], 6.0, 0)
		add_child(o)
	if SessionObjectives:
		SessionObjectives.on_entered_mode("clash")
	print("[TestArena] Phase0 feel chrome")


func _spawn_clash_landmarks() -> void:
	var prop_script: Script = load("res://scripts/assets/GlbProp.gd")
	var specs: Array = [
		{"rel": "environments/clash_nexus_core/clash_nexus_core_cybernex_lod1.glb", "pos": Vector3(0, 0, -48), "s": 2.4},
		{"rel": "environments/clash_nexus_core/clash_nexus_core_grot_lod1.glb", "pos": Vector3(0, 0, 48), "s": 2.4},
		{"rel": "environments/clash_lane_tower/clash_lane_tower_cybernex_lod1.glb", "pos": Vector3(-28, 0, -10), "s": 1.6},
		{"rel": "environments/clash_lane_tower/clash_lane_tower_cybernex_lod1.glb", "pos": Vector3(0, 0, -10), "s": 1.6},
		{"rel": "environments/clash_lane_tower/clash_lane_tower_grot_lod1.glb", "pos": Vector3(28, 0, -10), "s": 1.6},
	]
	for s in specs:
		var node: Node3D = Node3D.new()
		node.set_script(prop_script)
		node.set("relative_path", str(s["rel"]))
		node.set("scale_factor", float(s["s"]))
		var gqm := get_node_or_null("/root/GraphicsQuality")
		node.set("add_static_collision", false if gqm and int(gqm.tier) <= 1 else true)
		if gqm and int(gqm.tier) <= 1:
			node.set("relative_path", str(s["rel"]).replace("_lod1.", "_lod2."))
		add_child(node)
		node.position = s["pos"]
	print("[TestArena] clash landmarks placed")
	var lm_pos: Array = [Vector3(0, 6, -48), Vector3(0, 6, 48), Vector3(-28, 5, -10), Vector3(28, 5, -10)]
	var gql := get_node_or_null("/root/GraphicsQuality")
	var lm_n := lm_pos.size()
	if gql:
		match int(gql.tier):
			0: lm_n = 0  # directional only on LOW
			1: lm_n = 2
			_: lm_n = lm_pos.size()
	for i in lm_n:
		var pos: Vector3 = lm_pos[i]
		var o := OmniLight3D.new()
		o.light_energy = 0.7
		o.omni_range = 11.0
		o.shadow_enabled = false
		o.light_color = Color(0.4, 0.85, 1.0) if pos.z < 0 else Color(1.0, 0.3, 0.45)
		o.position = pos
		add_child(o)


func _ensure_clash_director() -> void:

	if get_node_or_null("ClashMatchDirector"):
		return
	var d := Node.new()
	d.set_script(load("res://scripts/test/ClashMatchDirector.gd"))
	d.name = "ClashMatchDirector"
	add_child(d)
	print("[TestArena] ClashMatchDirector")


func _soft_neon_ambient() -> void:
	## Cheap neon pillars (no particles) for Arena readability under budget.
	var spots := [Vector3(0,0,-14), Vector3(12,0,2), Vector3(-12,0,2)]
	var gqa := get_node_or_null("/root/GraphicsQuality")
	if gqa and int(gqa.tier) == 0:
		spots = [Vector3(0,0,-14)]
	elif gqa and int(gqa.tier) == 1:
		spots = [Vector3(0,0,-14), Vector3(12,0,2)]
	var root_n := Node3D.new()
	root_n.name = "NeonAmbient"
	add_child(root_n)
	for i in spots.size():
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.15, 3.2, 0.15)
		mi.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var col := Color(0.2, 0.85, 1.0) if i % 2 == 0 else Color(0.95, 0.2, 0.42)
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.6
		mi.material_override = mat
		mi.position = spots[i] + Vector3(0, 1.6, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root_n.add_child(mi)
	print("[TestArena] soft neon ambient")



func _apply_arena_perf() -> void:
	## Clash FPS envelope for min-spec (RTX 1060 3GB floor).
	var gq := get_node_or_null("/root/GraphicsQuality")
	var tier := 1
	if gq:
		tier = int(gq.tier)
		if gq.has_method("apply_tier"):
			gq.apply_tier(tier)  # refresh viewport MSAA/shadows
	var we := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		var e := we.environment
		e.ssao_enabled = false
		e.ssil_enabled = false
		e.sdfgi_enabled = false
		e.volumetric_fog_enabled = false
		e.glow_enabled = tier >= 2
		if tier <= 1:
			e.glow_intensity = 0.0
			e.adjustment_enabled = tier >= 1
		e.fog_enabled = false
	# Directional light: one shadow caster max
	for c in get_children():
		if c is DirectionalLight3D:
			var dl := c as DirectionalLight3D
			dl.shadow_enabled = tier >= 1
			if tier == 0:
				dl.light_energy = minf(dl.light_energy, 0.85)
			elif tier == 1:
				dl.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		if c is OmniLight3D:
			(c as OmniLight3D).shadow_enabled = false
	# HUD refresh budget already 10Hz; mark FPS-friendly
	Engine.max_fps = 0  # uncapped; GPU-bound preferred over artificial 30
	print("[TestArena] arena perf tier=", tier)


func _arena_debug() -> bool:
	var h = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
	return h != null and h.has_method("is_debug_overlay") and bool(h.is_debug_overlay())


func _evidence_ar_a() -> void:
	var ev: Dictionary = {}
	if player and player.has_method("ots_evidence"):
		ev = player.ots_evidence()
	var table: Array = _lanes.lane_spawn_table() if _lanes and _lanes.has_method("lane_spawn_table") else []
	var ids: PackedStringArray = PackedStringArray()
	for e in table:
		var lane_id := str(e[1])
		if not ids.has(lane_id):
			ids.append(lane_id)
	print("[AR-A] ots=", ev, " lanes=", ",".join(ids), " pin=", LayerContext.site_pin_id if LayerContext else "")


func _setup_arena_playtest() -> void:
	var n := Node.new()
	n.set_script(preload("res://scripts/test/ArenaOTSPlaytest.gd"))
	n.name = "ArenaOTSPlaytest"
	add_child(n)


func _apply_arena_hud_layout() -> void:
	# Styling happens once: re-applying theme overrides five times a second
	# fired NOTIFICATION_THEME_CHANGED and queued a redraw each tick.
	# GameHUD owns every stat readout, including the F3 overlay. These legacy
	# labels occupy the same screen corners and overprinted it — keep them off.
	if info_label:
		info_label.visible = false
	if bar_health:
		bar_health.visible = false
	if bar_energy:
		bar_energy.visible = false
	if ability_label:
		ability_label.visible = false
	if contrib_label:
		contrib_label.visible = false
	if kills_label:
		kills_label.visible = false
	if _lane_hud:
		_lane_hud.visible = true
