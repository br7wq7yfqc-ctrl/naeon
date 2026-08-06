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
var _interior: Node = null
var _spawn_ship_pos := Vector3(0, 0, 2800)

func _ready() -> void:
	print("[OpenSpace] boot")
	if LayerContext:
		LayerContext.set_layer("Space")
		LayerContext.seamless_stage = "S1"
	_spawn_starfield()
	_spawn_planets()
	_spawn_ship()
	_setup_interior()
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
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 4
	mesh.rings = 2
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 0.9, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.85, 1.0)
	mat.emission_energy_multiplier = 1.4
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = 160
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	root.add_child(mmi)
	for i in 160:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var pos := dir * rng.randf_range(6000, 16000)
		var s := rng.randf_range(0.6, 3.2)
		var xf := Transform3D(Basis.from_scale(Vector3.ONE * s), pos)
		mm.set_instance_transform(i, xf)

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
	_bind_planet_observers()
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

func _setup_interior() -> void:
	_interior = Node.new()
	_interior.set_script(preload("res://scripts/world/InteriorDirector.gd"))
	_interior.name = "InteriorDirector"
	add_child(_interior)
	if _interior.has_method("setup"):
		_interior.setup(world_root, self)

func _spawn_ship() -> void:
	ship = ShipScene.instantiate()
	world_root.add_child(ship)
	# Start in free space above Nex-Prime atmosphere
	var p0: Node3D = planets[0]
	var r: float = float(p0.get("radius") if p0.get("radius") != null else 1400.0)
	var ah: float = float(p0.get("atmosphere_height") if p0.get("atmosphere_height") != null else 320.0)
	ship.global_position = p0.global_position + Vector3(0, 0, r + ah + 450.0)
	_spawn_ship_pos = ship.global_position
	if ship.has_signal("landed"):
		ship.landed.connect(_on_ship_landed)
	if ship.has_signal("launched"):
		ship.launched.connect(_on_ship_launched)
	if ship.has_method("set_open_space_context"):
		ship.set_open_space_context(self)
	_bind_planet_observers()
	_sync_planet_sun()


func _bind_planet_observers() -> void:
	for pl in planets:
		if pl and pl.has_method("set_observer") and ship:
			pl.set_observer(ship)


func _sync_planet_sun() -> void:
	var sun := $Sun as DirectionalLight3D
	if sun == null:
		return
	var dir: Vector3 = -sun.global_transform.basis.z
	for pl in planets:
		if pl and pl.has_method("set_sun_direction"):
			pl.set_sun_direction(dir)


func _update_altitude_fog() -> void:
	## Cheap height fog denser inside atmosphere (tier-aware).
	var we := $WorldEnvironment as WorldEnvironment
	if we == null or we.environment == null or ship == null:
		return
	var env := we.environment
	var pl: Node3D = nearest_planet(ship.global_position)
	if pl == null or not pl.has_method("altitude_of"):
		env.fog_enabled = false
		return
	var alt: float = float(pl.altitude_of(ship.global_position))
	var h_val = pl.get("atmosphere_height")
	var h: float = float(h_val) if h_val != null else 300.0
	var col = pl.get("atmosphere_color")
	var fog_col := Color(0.15, 0.25, 0.45)
	if col is Color:
		fog_col = Color(col.r, col.g, col.b)
	if alt > h * 1.6:
		env.fog_enabled = false
		return
	env.fog_enabled = true
	env.fog_light_color = fog_col
	var depth: float = clampf(1.0 - maxf(alt, 0.0) / maxf(h * 1.6, 1.0), 0.0, 1.0)
	var dens: float = 0.00015 + depth * depth * 0.0022
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq:
		match int(gq.tier):
			0:
				dens *= 0.55
			2:
				dens *= 1.15
			3:
				dens *= 1.35
	env.fog_density = dens


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
	if LayerContext:
		LayerContext.set_layer("TPS")
	_spawn_player_near_ship()
	if ship.has_method("set_pilot_active"):
		ship.set_pilot_active(false)
	if floating and floating.has_method("set_target") and player:
		floating.set_target(player)
	for pl in planets:
		if pl.has_method("set_observer"):
			pl.set_observer(player)

func try_enter_ship() -> void:
	if _in_ship or ship == null or player == null:
		return
	if player.global_position.distance_to(ship.global_position) > 12.0:
		print("[OpenSpace] Too far from ship")
		return
	_in_ship = true
	if LayerContext:
		LayerContext.set_layer("Space")
	if player:
		player.queue_free()
		player = null
	if ship.has_method("set_pilot_active"):
		ship.set_pilot_active(true)
	if floating and floating.has_method("set_target"):
		floating.set_target(ship)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _spawn_player_near_ship() -> void:
	# Always use SurfaceWalker for planetary gravity (PlayerController is flat-world TPS).
	player = _make_fallback_player()
	world_root.add_child(player)
	var pad_up := Vector3.UP
	var pad: Node3D = nearest_pad(ship.global_position)
	if pad and pad.has_meta("pad_up"):
		pad_up = pad.get_meta("pad_up")
	elif nearest_planet(ship.global_position):
		var pl = nearest_planet(ship.global_position)
		pad_up = (ship.global_position - pl.global_position).normalized()
	# Spawn beside ship, clearly above pad/surface
	var side: Vector3 = ship.global_transform.basis.x
	side = (side - pad_up * side.dot(pad_up)).normalized()
	if side.length_squared() < 0.01:
		side = pad_up.cross(Vector3.FORWARD).normalized()
	player.global_position = ship.global_position + pad_up * 2.5 + side * 5.0
	if player.has_method("set_planet_gravity_provider"):
		player.set_planet_gravity_provider(self)
	if player.has_method("set_spawn_basis"):
		var yaw := atan2(-side.x, -side.z)
		player.set_spawn_basis(pad_up, yaw)
	if player.has_method("snap_to_surface"):
		player.call_deferred("snap_to_surface")
	# Ensure ship camera off
	if ship.has_method("set_pilot_active"):
		ship.set_pilot_active(false)
	print("[OpenSpace] TPS exit at ", player.global_position, " up=", pad_up)

func _make_fallback_player() -> CharacterBody3D:
	var p := CharacterBody3D.new()
	p.set_script(preload("res://scripts/player/SurfaceWalker.gd"))
	p.set("faction", "Cybernex")
	p.set("form_name", "Canine")
	return p

func _process(_delta: float) -> void:
	_update_altitude_fog()
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
		+ "WASD thrust  Space/Shift lift  Mouse=flight plane  Z/X roll  |  1/2/3 modes  |  E land  F exit  C claim  G/B terra  U undo  I interior  Q hack\n"
		+ "F1 cycle quality  |  Tab → TestArena (combat sandbox)\n"
		+ "Mode: %s  Planet: %s  Alt: %dm  Spd: %d  HP:%d SHD:%d  PLOD:%s  CONTRIB:%.0f" % [
			mode, pname, int(alt), int(spd), int(ship.health), int(ship.shields), (pl.current_lod_name() if pl and pl.has_method("current_lod_name") else "-"), (GameManager.contribution if GameManager else 0.0)
		]
	)
	if mode_label:
		mode_label.text = "GFX: %s" % gqn

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_I:
			_toggle_interior()
		KEY_F9:
			_cycle_faction_demo()
		KEY_T:
			_try_edu_quest()
		KEY_Y:
			_skip_edu_quest()
		KEY_F:
			if _in_ship:
				try_exit_ship()
			else:
				try_enter_ship()
		KEY_F1:
			var gq := get_node_or_null("/root/GraphicsQuality")
			if gq:
				gq.cycle()
		KEY_P:
			if GameManager and GameManager.has_method("try_promote_alliance"):
				GameManager.try_promote_alliance()
		KEY_TAB:
			if ResourceLoader.exists("res://scenes/test/TestArena.tscn"):
				get_tree().change_scene_to_file("res://scenes/test/TestArena.tscn")


func _toggle_interior() -> void:
	var actor: Node3D = player if player and is_instance_valid(player) else null
	if actor == null and ship and _in_ship:
		print("[OpenSpace] Exit ship first (F) to enter interiors on foot")
		return
	if actor == null:
		return
	if _interior and _interior.has_method("try_toggle"):
		_interior.try_toggle(actor, ship)


func _cycle_faction_demo() -> void:
	if GameManager == null:
		return
	GameManager.cycle_faction()
	# Rebuild ability kits for new faction asymmetry
	var actor: Node = player if player and is_instance_valid(player) else null
	if actor:
		var absys = actor.get_node_or_null("AbilitySystem")
		if absys == null:
			for c in actor.get_children():
				if c is AbilitySystem or (c.get_script() and "AbilitySystem" in str(c.get_script().resource_path)):
					absys = c
					break
		if absys and absys.has_method("setup_default_loadout"):
			absys.setup_default_loadout(GameManager.get_faction_name())
	# Dual-theme ship modules
	if ship and ship.has_method("apply_faction_modules"):
		ship.apply_faction_modules(GameManager.get_faction_name())
	print("[OpenSpace] faction demo → ", GameManager.get_faction_name())

func _ensure_edu_on_player() -> Node:
	if player == null or not is_instance_valid(player):
		return null
	var eq = player.get_node_or_null("EduQuestStub")
	if eq == null:
		eq = Node.new()
		eq.set_script(preload("res://scripts/systems/EduQuestStub.gd"))
		eq.name = "EduQuestStub"
		player.add_child(eq)
	return eq

func _try_edu_quest() -> void:
	# Near pad: start educational puzzle (CONCEPT §7.2) — soft Knowledge only
	if player == null:
		return
	var near_pad := false
	if get_tree():
		for n in get_tree().get_nodes_in_group("pad_bases"):
			if n is Node3D and player.global_position.distance_to((n as Node3D).global_position) < 45.0:
				near_pad = true
				break
	if not near_pad:
		if GameManager:
			GameManager.toast_requested.emit("EduQuest: approach a pad console (C claim zone)")
		return
	var eq := _ensure_edu_on_player()
	if eq == null:
		return
	if eq.is_active():
		# Cycle simple answers for vertical slice: try random near-correct
		var guess := randi_range(1, 30)
		var res: String = eq.try_answer(guess)
		if res == "ok":
			GameManager.add_mastery("history", 0.5)  # tiny lore crumb
		elif res.begins_with("hint:"):
			var ans := int(res.split(":")[1])
			GameManager.toast_requested.emit("EduQuest hint: answer is %d — press T to retry" % ans)
		else:
			GameManager.toast_requested.emit("EduQuest: incorrect (%s)" % res)
	else:
		var info: Dictionary = eq.start_logic_puzzle()
		GameManager.toast_requested.emit("EduQuest [%s]: %s — T submit · Y skip" % [info.get("subject", "?"), info.get("prompt", "")])

func _skip_edu_quest() -> void:
	var eq := _ensure_edu_on_player()
	if eq and eq.has_method("skip"):
		eq.skip()
