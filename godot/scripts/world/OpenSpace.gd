extends Node3D
const _PlanetProfiles = preload("res://scripts/world/PlanetProfileCatalog.gd")
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
var _eva_mode: bool = false
var _in_rover: bool = false
var _rover: Node3D = null
var _eva_warn_t: float = 0.0
var _spawn_ship_pos := Vector3(0, 0, 2800)

func _ready() -> void:
	_phase0_space_feel()
	add_to_group("open_space")
	print("[OpenSpace] boot")
	if LayerContext:
		LayerContext.set_layer("Space")
		LayerContext.seamless_stage = "S1"
	_spawn_starfield()
	_spawn_planets()
	_spawn_orbital_stations()
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
	var script: Script = preload("res://scripts/world/PlanetBody.gd") as Script
	for pid in ["Nex-Prime", "ROT-Hive", "Shard-Moon"]:
		var pl: Node3D = Node3D.new()
		pl.set_script(script)
		_PlanetProfiles.apply_to(pl, pid)
		world_root.add_child(pl)
		# position from profile (local); ensure global after enter tree
		var prof: Dictionary = _PlanetProfiles.profiles().get(pid, {})
		if prof.has("pos"):
			pl.position = prof["pos"]
		planets.append(pl)
	print("[OpenSpace] planets from PlanetProfileCatalog: ", planets.size())



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
	_bind_soft_net_actor(ship)
	_bind_planet_observers()
	_sync_planet_sun()


func _bind_planet_observers() -> void:
	for pl in planets:
		if pl and pl.has_method("set_observer") and ship:
			pl.set_observer(ship)
		_set_planet_observers(ship)


func _sync_planet_sun() -> void:
	var sun := $Sun as DirectionalLight3D
	if sun == null:
		return
	var dir: Vector3 = -sun.global_transform.basis.z
	for pl in planets:
		if pl and pl.has_method("set_sun_direction"):
			pl.set_sun_direction(dir)


func _update_altitude_fog() -> void:
	## Height fog + ambient tint near planets (SC-lite continuum, min-spec safe).
	var we := $WorldEnvironment as WorldEnvironment
	if we == null or we.environment == null or ship == null or not is_instance_valid(ship):
		return
	var env := we.environment
	var pl: Node3D = nearest_planet(ship.global_position)
	if pl == null or not is_instance_valid(pl) or not pl.has_method("altitude_of"):
		env.fog_enabled = false
		env.ambient_light_energy = 0.32
		return
	var alt: float = float(pl.altitude_of(ship.global_position))
	var h_val = pl.get("atmosphere_height")
	var h: float = float(h_val) if h_val != null else 300.0
	var col = pl.get("atmosphere_color")
	var fog_col := Color(0.18, 0.32, 0.55)
	if col is Color:
		fog_col = Color(col.r, col.g, col.b).lerp(Color(0.55, 0.7, 0.95), 0.25)
	var depth: float = clampf(1.0 - maxf(alt, 0.0) / maxf(h * 1.65, 1.0), 0.0, 1.0)
	if alt > h * 1.65:
		env.fog_enabled = false
		env.ambient_light_energy = 0.28
		env.glow_intensity = 0.55
		return
	env.fog_enabled = true
	env.fog_light_color = fog_col
	env.fog_aerial_perspective = depth * 0.45
	var dens: float = 0.00018 + depth * depth * 0.0028
	# Surface haze denser when walking
	if not _in_ship:
		dens *= 1.25
		env.ambient_light_energy = 0.45 + depth * 0.35
	else:
		env.ambient_light_energy = 0.3 + depth * 0.4
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq:
		match int(gq.tier):
			0:
				dens *= 0.5
			2:
				dens *= 1.2
			3:
				dens *= 1.4
	env.fog_density = dens
	env.glow_intensity = 0.5 + depth * 0.35
	# Sun warm-up near limb
	var sun := get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_color = Color(1, 0.96, 0.9).lerp(fog_col.lightened(0.4), depth * 0.35)
		sun.light_energy = 1.15 + depth * 0.45


func gravity_at(global_pos: Vector3) -> Vector3:
	var g := Vector3.ZERO
	for pl in planets:
		if pl.has_method("gravity_at"):
			g += pl.gravity_at(global_pos)
	return g



func atmosphere_density_at(global_pos: Vector3) -> float:
	var pl: Node3D = nearest_planet(global_pos)
	if pl == null or not is_instance_valid(pl):
		return 0.0
	var alt := 99999.0
	if pl.has_method("altitude_of"):
		alt = float(pl.altitude_of(global_pos))
	var ah := 280.0
	if "atmosphere_height" in pl:
		ah = float(pl.atmosphere_height)
	# Same curve as ShipFlightModel
	if ah <= 1.0 or alt >= ah * 1.6:
		return 0.0
	if alt <= 0.0:
		return 1.0
	var t := 1.0 - alt / (ah * 1.6)
	return clampf(t * t, 0.0, 1.0)


func radial_up_at(global_pos: Vector3) -> Vector3:
	var g := gravity_at(global_pos)
	if g.length() > 0.2:
		return (-g).normalized()
	return Vector3.UP

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
	if not _in_ship or ship == null or not is_instance_valid(ship):
		return
	var landed := bool(ship.get("is_landed"))
	var spd := 0.0
	if ship.get("velocity") != null:
		spd = float(ship.velocity.length()) if ship.velocity is Vector3 else 0.0
	elif "velocity" in ship:
		spd = float(ship.velocity.length())
	# Soft speed gate for EVA (not landed)
	if not landed and spd > 42.0:
		print("[OpenSpace] Slow down to EVA (spd=", int(spd), ")")
		return
	_in_ship = false
	_eva_mode = not landed
	if LayerContext:
		LayerContext.set_layer("TPS")
	if landed:
		_spawn_player_near_ship()
	else:
		_spawn_eva_near_ship()
	if is_instance_valid(ship) and ship.has_method("set_pilot_active"):
		ship.set_pilot_active(false)
	if floating and is_instance_valid(floating) and floating.has_method("set_target") and player and is_instance_valid(player):
		floating.set_target(player)
	for pl in planets:
		if pl and is_instance_valid(pl) and pl.has_method("set_observer") and player and is_instance_valid(player):
			pl.set_observer(player)
		_set_planet_observers(player)
	_bind_soft_net_actor(player)
	print("[OpenSpace] exited ship  eva=", _eva_mode)


func try_enter_ship() -> void:
	# Hardened: never has_method on queue_freed walker (SIGSEGV ClassDB::get_method).
	if _in_ship or ship == null or not is_instance_valid(ship):
		return
	if player == null or not is_instance_valid(player):
		player = null
		print("[OpenSpace] No walker to board")
		return
	var board_r := 22.0 if _eva_mode else 14.0
	if player.global_position.distance_to(ship.global_position) > board_r:
		print("[OpenSpace] Too far from hatch")
		return
	_in_ship = true
	_eva_mode = false
	if LayerContext:
		LayerContext.set_layer("Space")
	# Point systems at ship BEFORE freeing walker
	for pl in planets:
		if pl and is_instance_valid(pl) and pl.has_method("set_observer"):
			pl.set_observer(ship)
	if floating and is_instance_valid(floating) and floating.has_method("set_target"):
		floating.set_target(ship)
	_bind_soft_net_actor(ship)
	# Disable walker ticks then free safely
	var old: Node = player
	player = null
	if is_instance_valid(old):
		old.set_process(false)
		old.set_physics_process(false)
		old.set_process_input(false)
		old.set_process_unhandled_input(false)
		if old is CollisionObject3D:
			(old as CollisionObject3D).collision_layer = 0
			(old as CollisionObject3D).collision_mask = 0
		old.queue_free()
	if is_instance_valid(ship) and ship.has_method("set_pilot_active"):
		ship.set_pilot_active(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("[OpenSpace] boarded ship")


func _spawn_eva_near_ship() -> void:
	## Open-space EVA: hatch offset, thruster suit, no floor snap.
	if ship == null or not is_instance_valid(ship):
		return
	player = _make_fallback_player()
	world_root.add_child(player)
	var hatch: Node3D = ship.get_node_or_null("HatchPoint") as Node3D
	var side: Vector3 = ship.global_transform.basis.x
	var up: Vector3 = ship.global_transform.basis.y
	if hatch:
		player.global_position = hatch.global_position
	else:
		player.global_position = ship.global_position + side * 4.0 + up * 1.2
	if player.has_method("set_planet_gravity_provider"):
		player.set_planet_gravity_provider(self)
	if player.has_method("set_eva_profile"):
		player.set_eva_profile(true)
	if player.has_method("set_spawn_basis"):
		var nose: Vector3 = -ship.global_transform.basis.z
		player.set_spawn_basis(up, atan2(-nose.x, -nose.z))
	# Match ship velocity soft so no instant relative slam
	if player is CharacterBody3D and ship.get("velocity") != null:
		(player as CharacterBody3D).velocity = ship.velocity * 0.85
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("[OpenSpace] EVA deployed")


func _spawn_player_near_ship() -> void:
	_eva_mode = false

	# SurfaceWalker + safe pad spawn (clear of density props / terrain embed).
	if ship == null or not is_instance_valid(ship):
		return
	player = _make_fallback_player()
	world_root.add_child(player)
	var pad_up := Vector3.UP
	var pad: Node3D = nearest_pad(ship.global_position)
	if pad and is_instance_valid(pad) and pad.has_meta("pad_up"):
		pad_up = pad.get_meta("pad_up")
	else:
		var pl = nearest_planet(ship.global_position)
		if pl and is_instance_valid(pl):
			pad_up = (ship.global_position - pl.global_position).normalized()
	var side: Vector3 = ship.global_transform.basis.x
	side = (side - pad_up * side.dot(pad_up))
	if side.length_squared() < 0.01:
		side = pad_up.cross(Vector3(0, 0, -1))
		if side.length_squared() < 0.01:
			side = pad_up.cross(Vector3.RIGHT)
	side = side.normalized()
	# High clear spawn — away from pad props (density cluster)
	player.global_position = ship.global_position + pad_up * 4.5 + side * 7.0
	if player.has_method("set_planet_gravity_provider"):
		player.set_planet_gravity_provider(self)
	if player.has_method("set_eva_profile"):
		player.set_eva_profile(false)
	# Face same way as ship nose (−Z of ship)
	var nose: Vector3 = -ship.global_transform.basis.z
	nose = (nose - pad_up * nose.dot(pad_up)).normalized()
	var yaw := atan2(-nose.x, -nose.z)
	if player.has_method("set_spawn_basis"):
		player.set_spawn_basis(pad_up, yaw)
	if player.has_method("snap_to_surface"):
		player.call_deferred("snap_to_surface")
		# Second snap next frames for physics settle
		get_tree().create_timer(0.05).timeout.connect(func():
			if player and is_instance_valid(player) and player.has_method("snap_to_surface"):
				player.snap_to_surface()
		)
		get_tree().create_timer(0.15).timeout.connect(func():
			if player and is_instance_valid(player) and player.has_method("safe_unground"):
				player.safe_unground()
		)
	if is_instance_valid(ship) and ship.has_method("set_pilot_active"):
		ship.set_pilot_active(false)
	_bind_soft_net_actor(player)
	print("[OpenSpace] TPS exit at ", player.global_position, " up=", pad_up)


func _make_fallback_player() -> CharacterBody3D:
	var p := CharacterBody3D.new()
	p.set_script(preload("res://scripts/player/SurfaceWalker.gd"))
	p.set("faction", "Cybernex")
	p.set("form_name", "Canine")
	return p

func _bind_soft_net_actor(actor: Node3D) -> void:
	## Soft multiplayer tracks current pilot/walker (pos/form only).
	if actor == null or not is_instance_valid(actor):
		return
	if SoftNetSession and SoftNetSession.has_method("bind_player"):
		SoftNetSession.bind_player(actor)
	if SoftENet and SoftENet.has_method("bind_player"):
		SoftENet.bind_player(actor)
	print("[OpenSpace] soft net actor → ", actor.name)


func _process(delta: float) -> void:
	_update_altitude_fog()
	_update_hud()
	# Soft EVA timer (warning only — no death Phase 0)
	if _eva_mode and player and is_instance_valid(player) and "eva_time" in player:
		if float(player.eva_time) > 90.0:
			_eva_warn_t += delta
			if _eva_warn_t > 8.0:
				_eva_warn_t = 0.0
				print("[OpenSpace] EVA soft warning — reboard soon")

func _update_hud() -> void:
	if hud_label == null or ship == null:
		return
	var pl: Node3D = nearest_planet(ship.global_position)
	var alt := 0.0
	var pname := "-"
	if pl and is_instance_valid(pl) and pl.has_method("altitude_of"):
		alt = pl.altitude_of(ship.global_position)
		pname = str(pl.get("planet_name"))
	var mode := "SHIP"
	if ship.get("flight_mode") != null:
		mode = str(ship.call("flight_mode_name")) if is_instance_valid(ship) and ship.has_method("flight_mode_name") else mode
	if _in_rover:
		mode = "ROVER"
	elif _eva_mode:
		mode = "EVA"
	elif not _in_ship:
		mode = "ON FOOT"
	var gq := get_node_or_null("/root/GraphicsQuality")
	var gqn: String = gq.tier_name() if gq else "?"
	var spd: float = 0.0
	if _in_ship and is_instance_valid(ship):
		spd = ship.velocity.length()
	elif player != null and is_instance_valid(player):
		spd = player.velocity.length()
	hud_label.text = (
		"NAEON OpenSpace  |  free flight · seamless land · surface walk\n"
		+ "WASD thrust  Space/Shift lift  Mouse=flight plane  Z/X roll  |  1/2/3 flight  4 siege  5 ramp  6 rover  7 store  |  E land  F exit/EVA/board  C claim  G/B terra  U undo  I interior  Q hack\n"
		+ "F1 cycle quality  |  Tab → TestArena (combat sandbox)\n"
		+ "Mode: %s  Planet: %s  Alt: %dm  Spd: %d  HP:%d SHD:%d  PLOD:%s  CONTRIB:%.0f" % [
			mode, pname, int(alt), int(spd), int(ship.health), int(ship.shields), (pl.current_lod_name() if pl and is_instance_valid(pl) and pl.has_method("current_lod_name") else "-"), (GameManager.contribution if GameManager else 0.0)
		]
	)
	if mode_label:
		mode_label.text = "GFX: %s" % gqn

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE):
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	# Godot 4 often leaves keycode=0 — always prefer physical
	var k: int = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
	if k == KEY_NONE:
		k = event.physical_keycode
	match k:
		KEY_I:
			_toggle_interior()
		KEY_F9:
			_cycle_faction_demo()
		KEY_T:
			_try_edu_quest()
		KEY_Y:
			_skip_edu_quest()
		KEY_F:
			_handle_f_interact()
		KEY_7:
			_try_store_rover()
		KEY_F1:
			var gq := get_node_or_null("/root/GraphicsQuality")
			if gq:
				gq.cycle()
		KEY_P:
			if GameManager and GameManager.has_method("try_promote_alliance"):
				GameManager.try_promote_alliance()
		KEY_M, KEY_TAB:
			if ResourceLoader.exists("res://scenes/test/TestArena.tscn"):
				get_tree().change_scene_to_file("res://scenes/test/TestArena.tscn")


func _handle_f_interact() -> void:
	# Priority: unboard rover → board rover → seat→pilot (interior) → ship board/exit
	if _in_rover and _rover and is_instance_valid(_rover):
		_unboard_rover()
		return
	if not _in_ship and player and is_instance_valid(player):
		if _try_board_nearby_rover():
			return
		if _try_seat_to_pilot():
			return
	if _in_ship:
		try_exit_ship()
	else:
		try_enter_ship()


func _try_board_nearby_rover() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var best: Node3D = null
	var best_d := 6.0
	# ship-deployed rover
	if ship and is_instance_valid(ship) and ship.has_method("get_deployed_rover"):
		var r: Node3D = ship.get_deployed_rover()
		if r != null and is_instance_valid(r):
			var d: float = player.global_position.distance_to(r.global_position)
			if d < best_d:
				best = r
				best_d = d
	if best == null:
		var tree := get_tree()
		if tree:
			for n in tree.get_nodes_in_group("ground_vehicle"):
				if n is Node3D and is_instance_valid(n):
					var d2: float = player.global_position.distance_to(n.global_position)
					if d2 < best_d:
						best = n
						best_d = d2
	if best == null:
		return false
	_rover = best
	_in_rover = true
	if _rover.has_method("board"):
		_rover.board(player)
	if floating and floating.has_method("set_target"):
		floating.set_target(_rover)
	_bind_soft_net_actor(_rover)
	print("[OpenSpace] boarded rover")
	return true


func _unboard_rover() -> void:
	if _rover == null or not is_instance_valid(_rover):
		_in_rover = false
		_rover = null
		return
	var actor: Node3D = null
	if _rover.has_method("unboard"):
		actor = _rover.unboard()
	_in_rover = false
	if actor and is_instance_valid(actor):
		player = actor
		if player.has_method("set_planet_gravity_provider"):
			player.set_planet_gravity_provider(self)
		if floating and floating.has_method("set_target"):
			floating.set_target(player)
		_bind_soft_net_actor(player)
	_rover = null
	print("[OpenSpace] left rover")


func _try_seat_to_pilot() -> bool:
	## Interior seat volume → direct PILOT (single-seat fast path).
	if _interior == null or not is_instance_valid(_interior):
		return false
	if not _interior.has_method("is_inside") or not _interior.is_inside():
		return false
	if player == null or not is_instance_valid(player):
		return false
	var active: Node3D = null
	if _interior.has_method("get_active_interior"):
		active = _interior.get_active_interior()
	# find SeatVolume near player
	var seat_near := false
	if active and is_instance_valid(active):
		var seat: Node = active.get_node_or_null("SeatVolume")
		if seat and seat is Node3D:
			if player.global_position.distance_to((seat as Node3D).global_position) < 3.5:
				seat_near = true
		var seat_m: Node = active.get_node_or_null("Seat")
		if seat_m and seat_m is Node3D:
			if player.global_position.distance_to((seat_m as Node3D).global_position) < 3.5:
				seat_near = true
	if not seat_near:
		# also allow if kind ship and near spawn
		if _interior.has_method("get_kind") and str(_interior.get_kind()) == "ship":
			if player.global_position.distance_to(Vector3(0, 50000, 0)) < 12.0:
				seat_near = true
	if not seat_near:
		return false
	# Exit interior pocket then board ship without distance check
	if _interior.has_method("exit_interior"):
		_interior.exit_interior()
	# Force board
	if ship == null or not is_instance_valid(ship):
		return false
	_in_ship = true
	_eva_mode = false
	if LayerContext:
		LayerContext.set_layer("Space")
	for pl in planets:
		if pl and is_instance_valid(pl) and pl.has_method("set_observer"):
			pl.set_observer(ship)
	if floating and is_instance_valid(floating) and floating.has_method("set_target"):
		floating.set_target(ship)
	_bind_soft_net_actor(ship)
	var old: Node = player
	player = null
	if is_instance_valid(old):
		old.set_process(false)
		old.set_physics_process(false)
		if old is CollisionObject3D:
			(old as CollisionObject3D).collision_layer = 0
		old.queue_free()
	if ship.has_method("set_pilot_active"):
		ship.set_pilot_active(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("[OpenSpace] seat → pilot")
	return true


func _try_store_rover() -> void:
	if _in_rover:
		print("[OpenSpace] Unboard rover first (F)")
		return
	if ship == null or not is_instance_valid(ship):
		return
	if not bool(ship.get("is_landed")):
		print("[OpenSpace] Land to store rover")
		return
	var r: Node3D = null
	if ship.has_method("get_deployed_rover"):
		r = ship.get_deployed_rover()
	if r == null or not is_instance_valid(r):
		print("[OpenSpace] No deployed rover")
		return
	if r.global_position.distance_to(ship.global_position) > 18.0:
		print("[OpenSpace] Rover too far from ship/ramp")
		return
	var hold = ship.get_node_or_null("CargoHold")
	if hold and hold.has_method("store_vehicle"):
		var entry: Dictionary = r.as_storage_entry() if r.has_method("as_storage_entry") else {"class_id": "rover", "volume": 8.0, "mass": 2.0}
		if hold.store_vehicle(entry):
			r.queue_free()
			if ship.has_method("clear_deployed_rover"):
				ship.clear_deployed_rover()
			print("[OpenSpace] Rover stored in cargo hold")
		else:
			print("[OpenSpace] Hold full")
	else:
		r.queue_free()
		if ship.has_method("clear_deployed_rover"):
			ship.clear_deployed_rover()
		print("[OpenSpace] Rover despawned (no hold)")


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


func _phase0_space_feel() -> void:
	var we := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		var e := we.environment
		e.glow_enabled = true
		e.glow_intensity = 0.65
		e.glow_bloom = 0.18
		e.tonemap_mode = Environment.TONE_MAPPER_ACES
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(0.01, 0.015, 0.04)
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.08, 0.1, 0.16)
		e.ambient_light_energy = 0.35
	var sun := get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_energy = 1.35
		sun.shadow_enabled = true
	if SessionObjectives:
		SessionObjectives.on_entered_mode("space")
	print("[OpenSpace] Phase0 space feel")


func _spawn_orbital_stations() -> void:
	## Habitat modules in orbit near first planet — free continuum density.
	if planets.is_empty():
		return
	var pl: Node3D = planets[0]
	if pl == null or not is_instance_valid(pl):
		return
	var prop_script: Script = load("res://scripts/assets/GlbProp.gd")
	var root := Node3D.new()
	root.name = "OrbitalStations"
	world_root.add_child(root)
	var center: Vector3 = pl.global_position
	var rad_v = pl.get("radius")
	var rad: float = float(rad_v) if rad_v != null else 400.0
	for i in 3:
		var ang := TAU * float(i) / 3.0
		var pos := center + Vector3(cos(ang), 0.15 * sin(ang * 2.0), sin(ang)) * (rad + 90.0)
		var n: Node3D = Node3D.new()
		n.set_script(prop_script)
		n.set("relative_path", "colony/station_habitat_ring/station_habitat_ring_cybernex_lod1.glb")
		n.set("scale_factor", 8.0)
		n.set("add_static_collision", false)
		root.add_child(n)
		n.global_position = pos
		n.look_at(center, Vector3.UP)
		var o := OmniLight3D.new()
		o.light_energy = 4.0
		o.omni_range = 80.0
		o.light_color = Color(0.4, 0.85, 1.0)
		n.add_child(o)
	print("[OpenSpace] orbital stations x3")


func _set_planet_observers(obs: Node3D) -> void:
	if obs == null or not is_instance_valid(obs):
		return
	for n in get_children():
		_walk_set_obs(n, obs)


func _walk_set_obs(n: Node, obs: Node3D) -> void:
	if n == null:
		return
	if n.has_method("set_observer"):
		n.set_observer(obs)
	for c in n.get_children():
		_walk_set_obs(c, obs)

