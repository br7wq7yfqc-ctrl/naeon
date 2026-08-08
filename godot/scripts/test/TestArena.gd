extends Node3D

## Aexion Clash vertical slice — TPS MOBA kits + soft War Score (Predecessor bar).
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
var _clash: Node = null
var _lanes: Node3D = null
var _radar: Control = null
var _lane_hud: Label = null
var dummy_scene: PackedScene = preload("res://scenes/combat/CombatDummy.tscn")

func _ready() -> void:
	_phase0_arena_feel()
	_ensure_clash_director()
	print("[TestArena] Loaded — Aexion Clash slice")
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
	_spawn_turrets()
	_spawn_claim_nodes()
	if kills_label:
		kills_label.text = "Kills: 0"


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
	for pillar_name in ["PillarA", "PillarB", "Wall"]:
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
			0: cap = mini(cap, 4)
			1: cap = mini(cap, 6)
			_: cap = table.size()
	for i in mini(table.size(), cap):
		var entry = table[i]
		var d: Node = dummy_scene.instantiate()
		add_child(d)
		d.global_position = entry[0]
		d.set_meta("lane", str(entry[1]))
		if d.has_signal("died"):
			d.died.connect(_on_dummy_died)
		d.set("faction", str(entry[2]))
		# Outer lane dummies hold; mid skirmishes can move
		if str(entry[1]) != "MID":
			d.set("can_move", false)

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
	for entry in positions:
		var prop: Node3D = Node3D.new()
		prop.set_script(prop_script)
		prop.set("relative_path", str(entry[1]))
		prop.set("scale_factor", float(entry[2]))
		add_child(prop)
		prop.global_position = entry[0]



func _spawn_turrets() -> void:
	var tscn: PackedScene = load("res://scenes/combat/Turret.tscn")
	if tscn == null:
		return
	var spots: Array = [
		[Vector3(6, 0, -9), "gROT"],
		[Vector3(-11, 0, -6), "gROT"],
		[Vector3(9, 0, 4), "Cybernex"],
	]
	for s in spots:
		var turr: Node = tscn.instantiate()
		add_child(turr)
		turr.global_position = s[0]
		turr.set("faction", s[1])
		turr.set("target_player", s[1] == "gROT")

func _spawn_claim_nodes() -> void:
	# Interactive ownership beacons using dual-theme mesh swap
	var spots: Array = [
		[Vector3(-1, 0, -14), "Cybernex"],
		[Vector3(4, 0, -14), "gROT"],
	]
	for s in spots:
		var n := Node3D.new()
		n.name = "ClaimNode"
		var own := Node3D.new()
		own.name = "Ownership"
		own.set_script(preload("res://scripts/ownership/OwnershipComponent.gd"))
		own.set("dual_mesh_base", "props/claim_beacon/claim_beacon")
		own.set("claimable", true)
		n.add_child(own)
		# mesh placeholder under Ownership
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
		if own.has_method("claim"):
			own.claim(str(s[1]), 2.0)

func _on_dummy_died() -> void:
	if SessionObjectives:
		SessionObjectives.on_landed_or_lane()
	if AudioDirector:
		AudioDirector.play_hit(true)
	call_deferred("_maybe_refill_lane")
	kills += 1
	var lane_k := "MID"
	# last-killed lane is unknown here; prefer player lane if available
	if _lanes and "player_lane" in _lanes:
		lane_k = str(_lanes.player_lane)
	if _clash and _clash.has_method("register_kill"):
		_clash.register_kill(lane_k)
	elif _clash and "kills" in _clash:
		# sync local kills display from clash if present
		pass
	if kills_label:
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
	if not ("health" in player):
		return
	bar_health.value = player.health
	bar_health.max_value = player.max_health
	bar_energy.value = player.energy
	bar_energy.max_value = player.max_energy
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
	ability_label.text = "\n".join(lines)
	if contrib_label and _clash and _clash.has_method("status_line"):
		var econ2 := GameManager.economy_label() if GameManager and GameManager.has_method("economy_label") else ""
		var obj := ""
		if _clash.has_method("objectives_secured"):
			obj = "  |  OBJ %d/3" % int(_clash.objectives_secured())
		contrib_label.text = "%s  |  %s%s" % [econ2, _clash.status_line(), obj]
	var mvin: Vector2 = Vector2.ZERO
	if "last_move_input" in player:
		mvin = player.last_move_input
	info_label.text = (
		"NAEON CLASH | %s | Form %s | O=OpenSpace | 3 LANES + radar | soft WS\n" % [
			player.faction, player.current_form
		]
		+ "Q/E/R/F abilities | input(%.0f,%.0f) floor=%s | med heals" % [
			mvin.x, mvin.y, str(player.is_on_floor())
		]
	)

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
	if _clash and _clash.has_method("bind_player") and player:
		_clash.bind_player(player)
	if SoftNetSession and player:
		SoftNetSession.bind_player(player)


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
	_lane_hud.position = Vector2(14, 130)
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
				press = "  ·  " + str(_clash.lane_hud_line())
			_lane_hud.text = "LANE · %s  |  TOP cyan · MID gold · BOT magenta%s" % [_lanes.player_lane, press]
	if _radar == null or not _radar.has_method("set_snapshot"):
		return
	var ene: Array = []
	var all: Array = []
	for c in get_children():
		if c == player:
			continue
		if c is Node3D and "faction" in c:
			var fac := str(c.faction)
			if fac == "gROT":
				ene.append((c as Node3D).global_position)
			elif fac == "Cybernex":
				all.append((c as Node3D).global_position)
		# CombatDummy may use set faction property differently
		if c is Node3D and c.has_meta("lane"):
			if c not in ene and c != player:
				# treat lane meta dummies as enemies if not player
				if "health" in c or c.get_script():
					var fp := str(c.get("faction")) if "faction" in c else "gROT"
					if fp == "gROT":
						ene.append((c as Node3D).global_position)
	var nex := [
		[Vector3(0, 0, 24), Color(0.15, 0.85, 1.0)],
		[Vector3(0, 0, -24), Color(0.95, 0.12, 0.42)],
	]
	_radar.set_snapshot(player.global_position, ene, all, nex)


func _maybe_refill_lane() -> void:
	var alive := 0
	for c in get_children():
		if c is Node3D and c.has_meta("lane") and is_instance_valid(c):
			alive += 1
	if alive >= 4 or dummy_scene == null:
		return
	var table: Array = _lanes.lane_spawn_table() if _lanes and _lanes.has_method("lane_spawn_table") else []
	if table.is_empty():
		return
	var entry = table[randi() % table.size()]
	var d: Node = dummy_scene.instantiate()
	add_child(d)
	d.global_position = entry[0]
	d.set_meta("lane", str(entry[1]))
	if d.has_signal("died"):
		d.died.connect(_on_dummy_died)
	d.set("faction", str(entry[2]))
	if str(entry[1]) != "MID":
		d.set("can_move", false)
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
	# Lane light pillars
	for i in 3:
		var o := OmniLight3D.new()
		o.light_color = [Color(0.2, 0.8, 1), Color(1, 0.85, 0.3), Color(1, 0.25, 0.4)][i]
		o.light_energy = 0.9
		o.omni_range = 16.0
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
		node.set("add_static_collision", true)
		add_child(node)
		node.position = s["pos"]
	print("[TestArena] clash landmarks placed")
	for pos in [Vector3(0, 6, -48), Vector3(0, 6, 48), Vector3(-28, 5, -10), Vector3(28, 5, -10)]:
		var o := OmniLight3D.new()
		o.light_energy = 1.2
		o.omni_range = 14.0
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
