extends Node3D

## Space flight test — ship modules + land → TPS.

@onready var hint: Label = $HUD/Root/Hint
@onready var ship: CharacterBody3D = $Ship

func _ready() -> void:
	print("[SpaceTest] Loaded")
	if ship and ship.has_signal("landed"):
		ship.landed.connect(func(): print("[SpaceTest] Landing acknowledged"))

func _process(_delta: float) -> void:
	if hint and ship:
		hint.text = (
			"NAEON SpaceTest  |  WASD thrust/strafe  |  Space/Shift lift  |  Mouse aim\n"
			+ "Q fire  |  E land → TestArena  |  R attach Extractor module  |  Tab → Arena\n"
			+ "Modules: %d  Speed: %d" % [ship.modules.size(), int(ship.velocity.length())]
		)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if ResourceLoader.exists("res://scenes/test/TestArena.tscn"):
			get_tree().change_scene_to_file("res://scenes/test/TestArena.tscn")
