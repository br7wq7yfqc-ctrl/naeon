extends Node3D

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
		[Vector3(0, 1, 6), "ships/shield_module/shield_module_cybernex_lod2.glb", 1.2],
		[Vector3(4, -1, -4), "ships/cargo_pod/cargo_pod_cybernex_lod2.glb", 1.0],
		[Vector3(-8, -2, -2), "colony/colony_habitat/colony_habitat_cybernex_lod2.glb", 1.5],
		[Vector3(10, -2, 0), "environments/gate_arch/gate_arch_cybernex_lod2.glb", 1.8],
		[Vector3(-3, -1.5, -3), "environments/walkway_segment/walkway_segment_cybernex_lod2.glb", 1.4],
		[Vector3(12, 3, 8), "environments/asteroid_ore/asteroid_ore_cybernex_lod2.glb", 2.0],
		[Vector3(-14, 2, 6), "environments/asteroid_ore/asteroid_ore_grot_lod2.glb", 1.6],
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
			"NAEON SpaceTest  |  WASD thrust  |  Space/Shift lift  |  Mouse aim\n"
			+ "Q fire  |  E land→Arena  |  R extractor module  |  Tab→Arena\n"
			+ "Modules: %d  Speed: %d  HP: %d  Shield: %d" % [
				ship.modules.size(), int(ship.velocity.length()), int(ship.health), int(ship.shields)
			]
		)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if ResourceLoader.exists("res://scenes/world/OpenSpace.tscn"):
			get_tree().change_scene_to_file("res://scenes/world/OpenSpace.tscn")
