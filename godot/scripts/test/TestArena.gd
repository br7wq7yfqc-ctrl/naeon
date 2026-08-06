extends Node3D

## Playable TPS TestArena — movement, abilities, ownership, colony seed.

@onready var hud: CanvasLayer = $HUD
@onready var info_label: Label = $HUD/Root/Info
@onready var bar_health: ProgressBar = $HUD/Root/HealthBar
@onready var bar_energy: ProgressBar = $HUD/Root/EnergyBar
@onready var ability_label: Label = $HUD/Root/Abilities
@onready var contrib_label: Label = $HUD/Root/Contribution
@onready var player: CharacterBody3D = $Player

func _ready() -> void:
	print("[TestArena] Loaded")
	if GameManager:
		GameManager.add_mastery("cybernetics", 5.0)
		GameManager.contribution_changed.connect(_on_contrib)
	_on_contrib(GameManager.contribution if GameManager else 0.0)

func _process(_delta: float) -> void:
	if player == null:
		return
	bar_health.value = player.health
	bar_health.max_value = player.max_health
	bar_energy.value = player.energy
	bar_energy.max_value = player.max_energy
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
	info_label.text = "NAEON TestArena  |  %s  |  Form %s  |  WASD move  |  mouse look  |  Esc free cursor\nQ pulse  E firewall/hack  R probe  F form cycle  |  Hack claimable pillars (Ownership)" % [
		player.faction, player.current_form
	]

func _on_contrib(v: float) -> void:
	if contrib_label:
		contrib_label.text = "Contribution: %.1f  |  Knowledge: %d" % [
			v, GameManager.knowledge_rank if GameManager else 0
		]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_home") or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
		if ResourceLoader.exists("res://scenes/test/SpaceTest.tscn"):
			get_tree().change_scene_to_file("res://scenes/test/SpaceTest.tscn")
