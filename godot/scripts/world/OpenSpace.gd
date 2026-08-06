extends Node3D
## Seamless open space: free flight, planets, bases, surface walk, origin rebase.
## Entry scene for SC-like continuum (no change_scene landing).

const ShipScene := preload("res://scenes/ship/Ship.tscn")
const PlayerScene_PATH := "res://scenes/player/Player.tscn"

@onready var world_root: Node3D = $WorldRoot
@onready var floating: Node = $FloatingOrigin
@onready var hud_label: Label = $HUD/Root/Hint
@onready var mode_label: Label = $HUD/Root/Mode

var ship: CharacterBody3D
var player: CharacterBody3D
var planets: Array = []
var _in_ship: bool = true
var _spawn_ship_pos := Vector3(0, 0, 2800)

func _ready() -> void:
	print("[OpenSpace] boot")
	_spawn_starfield()
	_spawn_planets()
	_spawn_ship()
	if floating and floating.has_method("set_target"):
		floating.set_target(ship)
	# Graphics
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq:
		_apply_env_quality(gq)
		gq.tier_changed.connect(_on_tier)
	print("[OpenSpace] ready planets=", planets.size())

func _on_tier(_t: int) -> void:
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq:
		_apply_env_quality(gq)

func _apply_env_quality(gq) -> void:
	var we := $WorldEnvironment as WorldEnvironment
	if we and we.environment:
		we.environment.glow_enabled = gq.glow
		we.environment.ssao_enabled = gq.ssao
		we.environment.ssil_enabled = gq.ssil
	if ship:
		var cam: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D")
		if cam:
			cam.far = gq.far_clip

func _spawn_starfield() -> void:
	var root := $WorldRoot/Starfield as Node3D
	if root == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var mesh := SphereMesh.new()
	mesh.radius = 0.4
	mesh.height = 0.8
	mesh.radial_segments = 4
	mesh.rings = 2
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 0.9, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.85, 1.0)
	mat.emission_energy_multiplier = 1.5
	for i in 180:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		mi.position = dir * rng.randf_range(6000, 16000)
		mi.scale = Vector3.ONE * rng.randf_range(0.6, 3.5)
		root.add_child(mi)

func _spawn_planets() -> void:
	var script := preload("res://scripts/world/PlanetBody.gd")
	# Planet A — Cybernex colony world (near spawn)
	var a: Node3D = Node3D.new()
	a.set_script(script)
	a.set("planet_name", "Nex-Prime")
	a.set("radius", 1400.0)
	a.set("atmosphere_height", 320.0)
	a.set("surface_color", Color(0.1, 0.18, 0.28))
	a.set("atmosphere_color", Color(0.25, 0.55, 0.95, 0.1))
	a.set("faction_base", "Cybernex")
	a.set("gravity", 9.0)
	world_root.add_child(a)
	a.global_position = Vector3(0, 0, 0)
	planets.append(a)
	# Planet B — gROT biomass world (free flight destination)
	var b: Node3D = Node3D.new()
	b.set_script(script)
	b.set("planet_name", "ROT-Hive")
	b.set("radius", 1100.0)
	b.set("atmosphere_height", 260.0)
	b.set("surface_color", Color(0.22, 0.06, 0.08))
	b.set("atmosphere_color", Color(0.7, 0.15, 0.25, 0.1))
	b.set("faction_base", "gROT")
	b.set("gravity", 8.4)
	world_root.add_child(b)
	b.global_position = Vector3(9000, 400, -6000)
	planets.append(b)
	# Small moon (no base)
	var c: Node3D = Node3D.new()
	c.set_script(script)
	c.set("planet_name", "Shard-Moon")
	c.set("radius", 420.0)
	c.set("atmosphere_height", 40.0)
	c.set("surface_color", Color(0.35, 0.34, 0.32))
	c.set("atmosphere_color", Color(0.4, 0.4, 0.45, 0.04))
	c.set("has_base", false)
	c.set("gravity", 2.2)
	world_root.add_child(c)
	c.global_position = Vector3(-5500, 1800, 4000)
	planets.append(c)
	# Ambient free-space props (asteroids between)
	_spawn_asteroid_belt()

func _spawn_asteroid_belt() -> void:
	var prop_script: Script = preload("res://scripts/assets/GlbProp.gd")
	var belt := Node3D.new()
	belt.name = "AsteroidBelt"
	world_root.add_child(belt)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 14:
		var p: Node3D = Node3D.new()
		p.set_script(prop_script)
		p.set("relative_path", "environments/asteroid_ore/asteroid_ore_cybernex_lod2.glb" if i % 2 == 0 else "environments/asteroid_ore/asteroid_ore_grot_lod2.glb")
		p.set("scale_factor", rng.randf_range(4.0, 14.0))
		p.set("add_static_collision", true)
		belt.add_child(p)
		var ang := rng.randf() * TAU
		var r := rng.randf_range(3200, 5200)
		p.global_position = Vector3(cos(ang) * r, rng.randf_range(-400, 400), sin(ang) * r - 800)

func _spawn_ship() -> void:
	ship = ShipScene.instantiate()
	world_root.add_child(ship)
	# Start in free space above Nex-Prime atmosphere
	var p0: Node3D = planets[0]
	var r: float = p0.get("radius")
	var ah: float = p0.get("atmosphere_height")
	ship.global_position = p0.global_position + Vector3(0, 0, r + ah + 450.0)
	_spawn_ship_pos = ship.global_position
	if ship.has_signal("landed"):
		ship.landed.connect(_on_ship_landed)
	if ship.has_signal("launched"):
		ship.launched.connect(_on_ship_launched)
	if ship.has_method("set_open_space_context"):
		ship.set_open_space_context(self)

func gravity_at(global_pos: Vector3) -> Vector3:
	var g := Vector3.ZERO
	for pl in planets:
		if pl.has_method("gravity_at"):
			g += pl.gravity_at(global_pos)
	return g

func nearest_planet(global_pos: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for pl in planets:
		var d: float = pl.global_position.distance_to(global_pos)
		if d < best_d:
			best_d = d
			best = pl
	return best

func nearest_pad(global_pos: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for pl in planets:
		if pl.has_method("nearest_pad"):
			var pad: Node3D = pl.nearest_pad(global_pos)
			if pad:
				var d: float = pad.global_position.distance_to(global_pos)
				if d < best_d:
					best_d = d
					best = pad
	return best

func _on_ship_landed() -> void:
	print("[OpenSpace] ship landed (seamless — same scene)")

func _on_ship_launched() -> void:
	print("[OpenSpace] ship launched")

func try_exit_ship() -> void:
	if not _in_ship or ship == null:
		return
	if not ship.get("is_landed"):
		print("[OpenSpace] Exit only when landed")
		return
	_in_ship = false
	_spawn_player_near_ship()
	if ship.has_method("set_pilot_active"):
		ship.set_pilot_active(false)
	if floating and floating.has_method("set_target") and player:
		floating.set_target(player)

func try_enter_ship() -> void:
	if _in_ship or ship == null or player == null:
		return
	if player.global_position.distance_to(ship.global_position) > 12.0:
		print("[OpenSpace] Too far from ship")
		return
	_in_ship = true
	if player:
		player.queue_free()
		player = null
	if ship.has_method("set_pilot_active"):
		ship.set_pilot_active(true)
	if floating and floating.has_method("set_target"):
		floating.set_target(ship)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _spawn_player_near_ship() -> void:
	# Prefer full player scene; fallback CharacterBody3D minimal
	if ResourceLoader.exists(PlayerScene_PATH):
		player = load(PlayerScene_PATH).instantiate()
	else:
		player = _make_fallback_player()
	world_root.add_child(player)
	var pad_up := Vector3.UP
	var pad: Node3D = nearest_pad(ship.global_position)
	if pad and pad.has_meta("pad_up"):
		pad_up = pad.get_meta("pad_up")
	player.global_position = ship.global_position + pad_up * 3.0 + ship.global_transform.basis.x * 4.0
	# Point camera-ish
	if player.has_method("set_planet_gravity_provider"):
		player.set_planet_gravity_provider(self)
	print("[OpenSpace] TPS exit at ", player.global_position)

func _make_fallback_player() -> CharacterBody3D:
	var p := CharacterBody3D.new()
	p.collision_layer = 2
	p.collision_mask = 1
	var col := CollisionShape3D.new()
	var sh := CapsuleShape3D.new()
	sh.radius = 0.4
	sh.height = 1.6
	col.shape = sh
	col.position.y = 0.9
	p.add_child(col)
	var mesh := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.4
	cm.height = 1.6
	mesh.mesh = cm
	mesh.position.y = 0.9
	p.add_child(mesh)
	var cam_p := Node3D.new()
	cam_p.name = "CamPivot"
	cam_p.position.y = 1.5
	p.add_child(cam_p)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.2, 3.5)
	cam.current = true
	cam_p.add_child(cam)
	p.set_script(preload("res://scripts/player/SurfaceWalker.gd"))
	return p

func _process(_delta: float) -> void:
	_update_hud()

func _update_hud() -> void:
	if hud_label == null or ship == null:
		return
	var pl: Node3D = nearest_planet(ship.global_position)
	var alt := 0.0
	var pname := "-"
	if pl and pl.has_method("altitude_of"):
		alt = pl.altitude_of(ship.global_position)
		pname = str(pl.get("planet_name"))
	var mode := "SHIP"
	if ship.get("flight_mode") != null:
		mode = str(ship.call("flight_mode_name")) if ship.has_method("flight_mode_name") else mode
	if not _in_ship:
		mode = "ON FOOT"
	var gq := get_node_or_null("/root/GraphicsQuality")
	var gqn: String = gq.tier_name() if gq else "?"
	var spd: float = ship.velocity.length() if _in_ship else (player.velocity.length() if player else 0.0)
	hud_label.text = (
		"NAEON OpenSpace  |  free flight · seamless land · surface walk\n"
		+ "WASD thrust  Space/Shift lift  Mouse look  |  1/2/3 flight modes  |  E land/launch  |  F exit/enter\n"
		+ "F1 cycle quality  |  Tab → TestArena (combat sandbox)\n"
		+ "Mode: %s  Planet: %s  Alt: %dm  Spd: %d  HP:%d SHD:%d" % [
			mode, pname, int(alt), int(spd), int(ship.health), int(ship.shields)
		]
	)
	if mode_label:
		mode_label.text = "GFX: %s" % gqn

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F:
				if _in_ship:
					try_exit_ship()
				else:
					try_enter_ship()
			KEY_F1:
				var gq := get_node_or_null("/root/GraphicsQuality")
				if gq:
					gq.cycle()
			KEY_TAB:
				if ResourceLoader.exists("res://scenes/test/TestArena.tscn"):
					get_tree().change_scene_to_file("res://scenes/test/TestArena.tscn")
