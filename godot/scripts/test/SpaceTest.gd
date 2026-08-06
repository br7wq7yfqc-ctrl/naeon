extends Node3D

## Space flight test — ship modules + land → TPS.

@onready var hint: Label = $HUD/Root/Hint
@onready var ship: CharacterBody3D = $Ship

func _ready() -> void:
	print("[SpaceTest] Loaded")
	if ship and ship.has_signal("landed"):
		ship.landed.connect(func(): print("[SpaceTest] Landing acknowledged"))
	_spawn_space_props()

func _spawn_space_props() -> void:
	var prop_script: Script = preload("res://scripts/assets/GlbProp.gd")
	var entries: Array = [
		[Vector3(0, -2, -8), "environments/landing_pad/landing_pad_cybernex_lod1.glb", 2.5],
		[Vector3(6, 0, 4), "ships/ship_module_engine/ship_module_engine_cybernex_lod2.glb", 1.5],
		[Vector3(-6, 0, 4), "ships/ship_module_weapon/ship_module_weapon_cybernex_lod2.glb", 1.5],
	]
	for e in entries:
		var prop: Node3D = Node3D.new()
		prop.set_script(prop_script)
		prop.set("relative_path", str(e[1]))
		prop.set("scale_factor", float(e[2]))
		prop.set("add_static_collision", false)
		add_child(prop)
		prop.global_position = e[0]

func _process(_delta: float) -> void:
	if hint and ship:
		hint.text = (
			"NAEON SpaceTest  |  WASD thrust/strafe  |  Space/Shift lift  |  Mouse aim\n"
			+ "Q fire  |  E land → TestArena  |  R attach Extractor module  |  Tab → Arena\n"
			+ "Modules: %d  Speed: %d  HP: %d  Shield: %d" % [
				ship.modules.size(),
				int(ship.velocity.length()),
				int(ship.health),
				int(ship.shields),
			]
		)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if ResourceLoader.exists("res://scenes/test/TestArena.tscn"):
			get_tree().change_scene_to_file("res://scenes/test/TestArena.tscn")
