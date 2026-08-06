extends Node3D

## Playable TPS TestArena — combat, ownership, colony, full prop set.

@onready var hud: CanvasLayer = $HUD
@onready var info_label: Label = $HUD/Root/Info
@onready var bar_health: ProgressBar = $HUD/Root/HealthBar
@onready var bar_energy: ProgressBar = $HUD/Root/EnergyBar
@onready var ability_label: Label = $HUD/Root/Abilities
@onready var contrib_label: Label = $HUD/Root/Contribution
@onready var player: CharacterBody3D = $Player
@onready var kills_label: Label = $HUD/Root/Kills

var kills: int = 0
var dummy_scene: PackedScene = preload("res://scenes/combat/CombatDummy.tscn")

func _ready() -> void:
	print("[TestArena] Loaded")
	var au: Node = get_node_or_null("/root/AutoUpdater")
	if au != null and au.has_signal("update_available"):
		au.connect("update_available", Callable(self, "_on_update_available"))
	if GameManager:
		GameManager.add_mastery("cybernetics", 5.0)
		GameManager.contribution_changed.connect(_on_contrib)
	_on_contrib(GameManager.contribution if GameManager else 0.0)
	_spawn_dummies()
	_spawn_props()
	if kills_label:
		kills_label.text = "Kills: 0"

func _spawn_dummies() -> void:
	var spots: Array[Vector3] = [
		Vector3(4, 0.1, -8),
		Vector3(-5, 0.1, -10),
		Vector3(12, 0.1, -2),
		Vector3(-10, 0.1, 2),
	]
	for i in spots.size():
		var d: Node = dummy_scene.instantiate()
		add_child(d)
		d.global_position = spots[i]
		if d.has_signal("died"):
			d.died.connect(_on_dummy_died)
		if i % 2 == 1:
			d.set("can_move", false)
			d.set("faction", "gROT")

func _spawn_props() -> void:
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
		[Vector3(-14, 0, -4), "props/med_station/med_station_cybernex_lod2.glb", 0.9],
		[Vector3(3, 0, 6), "props/holo_projector/holo_projector_cybernex_lod2.glb", 0.8],
		# ownership / combat
		[Vector3(0, 0, -12), "props/claim_beacon/claim_beacon_cybernex_lod1.glb", 1.0],
		[Vector3(3, 0, -12), "props/claim_beacon/claim_beacon_grot_lod1.glb", 1.0],
		[Vector3(-12, 0, 0), "props/energy_barrier/energy_barrier_cybernex_lod2.glb", 0.8],
		[Vector3(12, 0, 0), "props/energy_barrier/energy_barrier_grot_lod2.glb", 0.8],
		[Vector3(6, 0, -9), "props/turret_emplacement/turret_emplacement_grot_lod2.glb", 0.85],
		# colony / env
		[Vector3(14, 0, 6), "colony/colony_habitat/colony_habitat_cybernex_lod2.glb", 1.2],
		[Vector3(-8, 0, 8), "colony/solar_panel/solar_panel_cybernex_lod2.glb", 1.0],
		[Vector3(10, 0, 10), "colony/fuel_tank/fuel_tank_cybernex_lod2.glb", 0.9],
		[Vector3(0, 0, 14), "props/antenna_array/antenna_array_cybernex_lod2.glb", 1.0],
		[Vector3(0, 0, -16), "environments/gate_arch/gate_arch_cybernex_lod2.glb", 1.5],
		[Vector3(-4, 0, 5), "environments/walkway_segment/walkway_segment_cybernex_lod2.glb", 1.2],
	]
	for entry in positions:
		var prop: Node3D = Node3D.new()
		prop.set_script(prop_script)
		prop.set("relative_path", str(entry[1]))
		prop.set("scale_factor", float(entry[2]))
		add_child(prop)
		prop.global_position = entry[0]

func _on_dummy_died() -> void:
	kills += 1
	if kills_label:
		kills_label.text = "Kills: %d" % kills

func _process(_delta: float) -> void:
	if player == null:
		return
	bar_health.value = player.health
	bar_health.max_value = player.max_health
	bar_energy.value = player.energy
	bar_energy.max_value = player.max_energy
	# proximity med station heal
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
	info_label.text = "NAEON TestArena  |  %s  |  Form %s  |  WASD mouse Esc  Tab→Space\nQ pulse  E firewall  R hack  F form  |  med station heals nearby  |  dummies+turret" % [
		player.faction, player.current_form
	]

func _try_med_heal(delta: float) -> void:
	# Heal near world position of med station prop placement
	var med_pos := Vector3(-14, 0, -4)
	if player.global_position.distance_to(med_pos) < 3.5:
		if player.health < player.max_health:
			player.heal(8.0 * delta)

func _on_contrib(v: float) -> void:
	if contrib_label:
		contrib_label.text = "Contribution: %.1f  |  Knowledge: %d" % [
			v, GameManager.knowledge_rank if GameManager else 0
		]

func _on_update_available(version: String, notes: String) -> void:
	print("[TestArena] Update available: ", version, " ", notes)
	if info_label:
		info_label.text += "\n⬆ Update %s available" % version

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_home") or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
		if ResourceLoader.exists("res://scenes/test/SpaceTest.tscn"):
			get_tree().change_scene_to_file("res://scenes/test/SpaceTest.tscn")
