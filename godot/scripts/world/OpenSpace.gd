extends Node3D
const _PlanetProfiles = preload("res://scripts/world/PlanetProfileCatalog.gd")
const _StarSystems = preload("res://scripts/world/StarSystemCatalog.gd")
const _Flight = preload("res://scripts/ship/ShipFlightModel.gd")
## Seamless open space: free flight, planets, bases, surface walk, origin rebase.
## Entry scene for SC-like continuum (no change_scene landing).

const ShipScene := preload("res://scenes/ship/Ship.tscn")
const PlayerScene_PATH := "res://scenes/player/Player.tscn"
const _P0 = preload("res://scripts/world/P0Slice.gd")

@onready var world_root: Node3D = $WorldRoot
@onready var floating: Node = $FloatingOrigin
@onready var hud_label: Label = $HUD/Root/Hint
@onready var mode_label: Label = $HUD/Root/Mode

var ship: CharacterBody3D
var player: CharacterBody3D
var planets: Array = []
var star: Node3D = null
var _in_ship: bool = true
var _interior: Node = null
var _squad: Node = null
var _eva_mode: bool = false
var _seat_transition: bool = false
var _in_rover: bool = false
var _rover: Node3D = null
var _rover_transition: bool = false
var _eva_warn_t: float = 0.0
var _eva_tether_t: float = 0.0
var _spawn_ship_pos := Vector3(0, 0, 2800)
var _interior_view: bool = false
## True only when pad↔flight closed a ship pocket; do not free an EVA walker.
var _drop_pocket_walker: bool = false
var _strategy: Node = null
## OS-C: useful approach in the 5–15 km AGL band. Not the toy 770 m spawn.
const APPROACH_START_AGL := 8000.0
const APPROACH_AGL_MIN := 5000.0
const APPROACH_AGL_MAX := 15000.0

func _ready() -> void:
	# Bolts freed with the previous scene never reached release().
	var _PoolReset = load("res://scripts/combat/ProjectilePool.gd")
	if _PoolReset and _PoolReset.has_method("reset_counters"):
		_PoolReset.reset_counters()
	_phase0_space_feel()
	add_to_group("open_space")
	print("[OpenSpace] boot")
	if LayerContext:
		LayerContext.set_layer("Space")
		LayerContext.seamless_stage = "S1"
		if LayerContext.site_pin_id == "":
			LayerContext.set_site_pin("SITE_SPACE_TEST_PAD")
	print("[OpenSpace] site_pin=", LayerContext.site_pin_id if LayerContext else "")
	_spawn_starfield()
	_spawn_star()
	_spawn_planets()
	_spawn_asteroid_belt()
	if _P0.ORBITAL_STATIONS:
		_spawn_orbital_stations()
	_spawn_ship()
	_spawn_catalog_carrier()
	_spawn_player_orbital_station()
	# HUD must exist before any walker does, or every claim / contest / harvest
	# toast of the opening flight is dropped on the floor.
	_ensure_game_hud()
	_setup_strategy_overlay()
	_setup_interior()
	_setup_squad()
	_setup_hull_softnet()
	_setup_clash_softnet()
	_setup_mechanics_playtest()
	_setup_sandbox_playtest()
	if floating != null and is_instance_valid(floating) and floating.has_method("set_target"):
		floating.set_target(ship)
	if floating != null and is_instance_valid(floating) and floating.has_method("rebase_now"):
		floating.rebase_now()
	if floating != null and is_instance_valid(floating) and floating.has_signal("rebased"):
		if not floating.rebased.is_connected(_on_origin_rebased):
			floating.rebased.connect(_on_origin_rebased)
	# Graphics
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq:
		_apply_env_quality(gq)
		gq.tier_changed.connect(_on_tier)
	print("[OpenSpace] ready planets=", planets.size())
	var hud_root := get_node_or_null("HUD/Root") as Control
	var CP = load("res://scripts/assets/CanonPlates.gd")
	if CP and hud_root:
		CP.spawn_space_hud(hud_root)

func _ensure_game_hud() -> void:
	var tree := get_tree()
	if tree == null or tree.get_first_node_in_group("game_hud") != null:
		return
	var hud := CanvasLayer.new()
	hud.set_script(load("res://scripts/ui/GameHUD.gd"))
	hud.name = "GameHUD"
	hud.add_to_group("game_hud")
	add_child(hud)
	if hud.has_method("bind_player") and ship != null and is_instance_valid(ship):
		hud.bind_player(ship)


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
			var need := APPROACH_AGL_MAX + 5300.0
			var pl0: Node3D = planets[0] as Node3D if not planets.is_empty() else null
			if pl0:
				var rad0: float = float(pl0.get("radius") if pl0.get("radius") != null else 1400.0)
				need = APPROACH_AGL_MAX + rad0 * 2.0 + 2500.0
			cam.far = maxf(float(gq.far_clip), need)
			if "near_clip" in gq:
				cam.near = float(gq.near_clip)

func _spawn_starfield() -> void:
	var root := $WorldRoot/Starfield as Node3D
	if root == null:
		return
	if DisplayServer.get_name() == "headless":
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

func _spawn_star() -> void:
	## Visible star at the system origin. Planets orbit it and take their light
	## direction from it, so "which way is the sun" is a real answer per body.
	var st: Dictionary = _StarSystems.star_of()
	if st.is_empty():
		return
	var root := Node3D.new()
	root.name = "Star"
	world_root.add_child(root)
	root.position = Vector3.ZERO
	star = root
	if DisplayServer.get_name() == "headless":
		return
	var r: float = float(st.get("radius", 900.0))
	var col: Color = st.get("color", Color(1.0, 0.94, 0.8))
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 24
	sm.rings = 12
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 6.0
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	root.add_child(mi)
	# No corona shell. A constant-alpha additive sphere is not a glow: 16% white
	# over black space renders as a flat grey ring around the disc, which looks
	# worse than nothing. A real corona needs the same rim/fresnel falloff the
	# planet atmospheres use — tracked as `star_corona_shell` polish in
	# docs/design/TRIPO_ASSET_MANIFEST.md. Glow post-processing (tier >= 2)
	# blooms the bright disc on its own.
	print("[OpenSpace] star %s r=%.0f" % [str(st.get("name", "Star")), r])


func star_position() -> Vector3:
	if star != null and is_instance_valid(star):
		return star.global_position
	return world_root.global_position if world_root else Vector3.ZERO


func _spawn_planets() -> void:
	var script: Script = preload("res://scripts/world/PlanetBody.gd") as Script
	var ids: PackedStringArray = _StarSystems.body_ids()
	if ids.is_empty():
		ids = PackedStringArray(["Nex-Prime", "ROT-Hive", "Shard-Moon"])
	for pid in ids:
		if not _P0.body_allowed(str(pid)):
			print("[OpenSpace] P0 skip body ", pid)
			continue
		var pl: Node3D = Node3D.new()
		pl.set_script(script)
		_PlanetProfiles.apply_to(pl, pid)
		world_root.add_child(pl)
		# Orbit around the star, not hand-typed coordinates: the three bodies
		# used to sit in one clump with no star to orbit.
		var orbital: Vector3 = _StarSystems.body_position(pid)
		if orbital != Vector3.ZERO:
			pl.position = orbital
		else:
			var prof: Dictionary = _PlanetProfiles.profiles().get(pid, {})
			if prof.has("pos"):
				pl.position = prof["pos"]
		planets.append(pl)
		print("[OpenSpace] %s at orbit %.0f" % [pid, pl.position.length()])
	print("[OpenSpace] system %s bodies=%d" % [_StarSystems.HOME, planets.size()])



func _spawn_asteroid_belt() -> void:
	## Belt band comes from the system layout, so it sits between the orbits it
	## is meant to separate instead of at hardcoded coordinates.
	if DisplayServer.get_name() == "headless":
		return
	var band: Dictionary = _StarSystems.belt_of()
	var r_in: float = float(band.get("inner", 9000.0))
	var r_out: float = float(band.get("outer", 10400.0))
	var thick: float = float(band.get("thickness", 420.0))
	var prop_script: Script = preload("res://scripts/assets/GlbProp.gd")
	var belt := Node3D.new()
	belt.name = "AsteroidBelt"
	world_root.add_child(belt)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var belt_n := 14
	var gqb := get_node_or_null("/root/GraphicsQuality")
	if gqb:
		match int(gqb.tier):
			0: belt_n = 4
			1: belt_n = 8
			2: belt_n = 11
			_: belt_n = 14
	for i in belt_n:
		var p: Node3D = Node3D.new()
		p.set_script(prop_script)
		p.set("relative_path", "environments/asteroid_ore/asteroid_ore_cybernex_lod2.glb" if i % 2 == 0 else "environments/asteroid_ore/asteroid_ore_grot_lod2.glb")
		p.set("scale_factor", rng.randf_range(4.0, 14.0))
		p.set("add_static_collision", false)  # belt collision was free-flight FPS tax
		belt.add_child(p)
		var ang := rng.randf() * TAU
		var r := rng.randf_range(r_in, r_out)
		p.global_position = Vector3(cos(ang) * r, rng.randf_range(-thick, thick) * 0.5, sin(ang) * r)
	print("[OpenSpace] belt n=%d band %.0f-%.0f" % [belt_n, r_in, r_out])

func _setup_interior() -> void:
	_interior = Node.new()
	_interior.set_script(preload("res://scripts/world/InteriorDirector.gd"))
	_interior.name = "InteriorDirector"
	add_child(_interior)
	if _interior.has_method("setup"):
		_interior.setup(world_root, self)


func _setup_squad() -> void:
	## NP-D: local 2–5 squad. SoftNet stays visual — no combat authority.
	_squad = Node.new()
	_squad.set_script(preload("res://scripts/systems/SquadRoster.gd"))
	_squad.name = "SquadRoster"
	add_child(_squad)


func get_squad() -> Node:
	return _squad


func hull_softnet() -> Node:
	return get_node_or_null("HullSoftNet")


func get_hull_softnet() -> Node:
	return hull_softnet()


func clash_softnet() -> Node:
	return get_node_or_null("ClashSoftNet")


func get_clash_softnet() -> Node:
	return clash_softnet()


func _setup_clash_softnet() -> void:
	## SN-D: second local viewer in Clash. SoftNet visual only.
	if not _P0.SN_D_CLASH:
		return
	var existing: Node = get_node_or_null("ClashSoftNet")
	if existing != null:
		if existing.has_method("bind"):
			existing.bind(self)
		if existing.has_method("sync_from_host"):
			existing.sync_from_host()
		return
	var n: Node3D = Node3D.new()
	n.set_script(preload("res://scripts/world/ClashSoftNet.gd"))
	n.name = "ClashSoftNet"
	add_child(n)
	if n.has_method("bind"):
		n.bind(self)


func _setup_hull_softnet() -> void:
	## SN-B: second local viewer on the seated hull. SoftNet visual only.
	if not _P0.SN_B_HULL:
		return
	var existing: Node = get_node_or_null("HullSoftNet")
	if existing != null:
		if existing.has_method("bind"):
			existing.bind(self)
		return
	var n: Node3D = Node3D.new()
	n.set_script(preload("res://scripts/world/HullSoftNet.gd"))
	n.name = "HullSoftNet"
	add_child(n)
	if n.has_method("bind"):
		n.bind(self)


func get_alliance() -> Node:
	## NP-E: two-NPC soft alliance lives on pad traffic. Not a siege cell.
	var tree := get_tree()
	if tree:
		var listed: Array = tree.get_nodes_in_group("soft_alliance")
		if listed.size() > 0:
			return listed[0]
	var traffic: Node = _pad_traffic_node() if has_method("_pad_traffic_node") else null
	if traffic != null and traffic.has_method("get_alliance"):
		return traffic.get_alliance()
	return null


func _setup_strategy_overlay() -> void:
	if not _P0.ST_A_OVERLAY:
		return
	var n := Node.new()
	n.set_script(preload("res://scripts/world/StrategyOverlay.gd"))
	n.name = "StrategyOverlay"
	add_child(n)
	_strategy = n
	if n.has_method("setup"):
		n.setup(self)


func strategy_overlay() -> Node:
	return _strategy


func strategy_overlay_active() -> bool:
	return _strategy != null and is_instance_valid(_strategy) \
		and _strategy.has_method("is_active") and bool(_strategy.is_active())


func _setup_mechanics_playtest() -> void:
	var n := Node.new()
	n.set_script(preload("res://scripts/test/Phase0MechanicsPlaytest.gd"))
	n.name = "Phase0MechanicsPlaytest"
	add_child(n)


func _setup_sandbox_playtest() -> void:
	var n := Node.new()
	n.set_script(preload("res://scripts/test/SandboxPlaytest.gd"))
	n.name = "SandboxPlaytest"
	add_child(n)


func _spawn_ship() -> void:
	if planets.is_empty():
		push_error("[OpenSpace] no planets to spawn ship over")
		return
	ship = ShipScene.instantiate()
	world_root.add_child(ship)
	# OS-C: start in the 5–15 km approach band. +Z so default nose (−Z) faces the body.
	var p0: Node3D = planets[0]
	var r: float = float(p0.get("radius") if p0.get("radius") != null else 1400.0)
	var agl: float = approach_start_agl()
	ship.global_position = p0.global_position + Vector3(0, 0, r + agl)
	_spawn_ship_pos = ship.global_position
	_fit_camera_to_approach(ship, p0)
	if ship.has_signal("landed"):
		ship.landed.connect(_on_ship_landed)
	if ship.has_signal("launched"):
		ship.launched.connect(_on_ship_launched)
	if ship.has_method("set_open_space_context"):
		ship.set_open_space_context(self)
	_bind_soft_net_actor(ship)
	_bind_planet_observers()
	_sync_planet_sun()
	if p0.has_method("refresh_approach_lod"):
		p0.call("refresh_approach_lod")
	# Plates (not BaseBuilder) so OS-C 8 km spawn has a radar contact / pip.
	if p0.has_method("ensure_pad_plates"):
		p0.call("ensure_pad_plates")
	print("[OpenSpace] approach AGL=%.0f over %s (r=%.0f)" % [agl, str(p0.get("planet_name")), r])
	print("[OpenSpace] OS-H F5: hold S (no pitch) → E land → F EVA → F board → Space takeoff → above atmo")


func _spawn_catalog_carrier() -> void:
	## ST-D: one catalog hull with a hangar queue. Not a mobile SITE_*.
	var n: Node3D = null
	var p0: Node3D = null
	var r := 1400.0
	if not _P0.ST_D_HANGAR:
		return
	if world_root == null:
		return
	if world_root.get_node_or_null("CatalogCarrier") != null:
		return
	n = Node3D.new()
	n.set_script(preload("res://scripts/world/CatalogCarrier.gd"))
	n.name = "CatalogCarrier"
	n.set_meta("site_pin", "")
	world_root.add_child(n)
	if not planets.is_empty():
		p0 = planets[0] as Node3D
		r = float(p0.get("radius") if p0.get("radius") != null else 1400.0)
		n.global_position = p0.global_position + Vector3(r + 600.0, 80.0, 0.0)
	elif ship != null:
		n.global_position = ship.global_position + Vector3(180.0, 40.0, 80.0)
	if n.has_method("setup"):
		n.setup("cybernex_capital_carrier")
	print("[OpenSpace] ST-D catalog carrier=", n.get("hull_id"), " hangar queue · not SITE_*")


func catalog_carrier() -> Node3D:
	if world_root == null:
		return null
	return world_root.get_node_or_null("CatalogCarrier") as Node3D


func hangar_queue() -> Node:
	var c := catalog_carrier()
	if c != null and c.has_method("hangar_queue"):
		return c.hangar_queue()
	return find_child("CarrierHangarQueue", true, false)


func _spawn_player_orbital_station() -> void:
	## ST-E: two catalog modules in one player-owned cluster. Nex-Prime orbit.
	## Does not flip P0Slice.ORBITAL_STATIONS. Not SITE_*. Not a city.
	var n: Node3D = null
	var p0: Node3D = null
	var r := 1400.0
	var body_name := "Nex-Prime"
	if not _P0.ST_E_ORBITAL:
		return
	if world_root == null:
		return
	if world_root.get_node_or_null("PlayerOrbitalStation") != null:
		return
	n = Node3D.new()
	n.set_script(preload("res://scripts/world/PlayerOrbitalStation.gd"))
	n.name = "PlayerOrbitalStation"
	n.set_meta("site_pin", "")
	n.set_meta("city", false)
	world_root.add_child(n)
	if not planets.is_empty():
		p0 = planets[0] as Node3D
		r = float(p0.get("radius") if p0.get("radius") != null else 1400.0)
		if p0.get("planet_name") != null and str(p0.get("planet_name")) != "":
			body_name = str(p0.get("planet_name"))
		n.global_position = p0.global_position + Vector3(r + 480.0, 60.0, 40.0)
	elif ship != null:
		n.global_position = ship.global_position + Vector3(-220.0, 50.0, 90.0)
	if n.has_method("setup"):
		n.setup(body_name, "Cybernex")
	if _P0.ST_G_FACTORY and n.has_method("ensure_factory"):
		n.ensure_factory()
	if _P0.ST_K_HANGAR and n.has_method("ensure_hangar_stub"):
		n.ensure_hangar_stub()
	if _P0.ST_L_TURRET and n.has_method("ensure_defense_turret"):
		n.ensure_defense_turret()
	if _P0.ST_M_STORAGE and n.has_method("ensure_storage"):
		n.ensure_storage()
	if SoftSession and SoftSession.has_method("restore_world"):
		SoftSession.restore_world()
	if SoftSession and SoftSession.has_method("remember_world"):
		SoftSession.remember_world(ship)
	if n.has_method("_refresh_label"):
		n._refresh_label()
	print("[OpenSpace] ST-E player orbital cluster modules=2 body=", body_name, " · not SITE_* · not city")


func player_orbital_station() -> Node3D:
	if world_root == null:
		return null
	return world_root.get_node_or_null("PlayerOrbitalStation") as Node3D


func player_factory() -> Node3D:
	## ST-G: factory in the existing player cluster. Not a new SITE_*.
	var cluster := player_orbital_station()
	if cluster != null and cluster.has_method("factory_module"):
		return cluster.factory_module()
	return find_child("FactoryModule", true, false) as Node3D


func player_orbital_hangar() -> Node3D:
	## ST-K: hangar stub on the existing player cluster. Not ST-D / IN-F.
	var cluster := player_orbital_station()
	if cluster != null and cluster.has_method("hangar_stub"):
		return cluster.hangar_stub()
	return find_child("OrbitalHangarStub", true, false) as Node3D


func player_orbital_turret() -> Node3D:
	## ST-L: defense turret on the existing player cluster. Not ST-H pad turret.
	var cluster := player_orbital_station()
	if cluster != null and cluster.has_method("defense_turret"):
		return cluster.defense_turret()
	return find_child("OrbitalDefenseTurret", true, false) as Node3D


func player_orbital_storage() -> Node3D:
	## ST-M: PadStorage on the existing player cluster. Not ST-I pad storage.
	var cluster := player_orbital_station()
	if cluster != null and cluster.has_method("cluster_storage"):
		return cluster.cluster_storage()
	return find_child("OrbitalStorage", true, false) as Node3D


func occupied_pad_base() -> Node:
	## ST-F / DO-A: unnamed pad controller the player already occupies. Not a new SITE_*.
	## DO-B lives on PlayerOrbitalStation, not this pad.
	var tree := get_tree()
	var actor: Node3D = null
	var best: Node = null
	var best_d := 48.0
	if not _P0.ST_F_OWNERSHIP and not _P0.DO_A_OWNERSHIP:
		return null
	if player != null and is_instance_valid(player) and player.is_inside_tree():
		actor = player
	elif ship != null and is_instance_valid(ship) and ship.is_inside_tree():
		actor = ship
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("pad_bases"):
		var d := 9999.0
		if n == null or not is_instance_valid(n):
			continue
		if not (n is Node3D):
			continue
		if not n.has_method("flip_cluster_owner"):
			continue
		if actor != null:
			d = actor.global_position.distance_to((n as Node3D).global_position)
			if d > best_d:
				continue
		if n.has_method("get_faction"):
			var fac := str(n.get_faction())
			if fac != "Cybernex" and fac != "gROT":
				continue
		if actor == null:
			return n
		if d < best_d:
			best_d = d
			best = n
	return best


func _try_flip_pad_owner() -> void:
	var pad: Node = occupied_pad_base()
	var after := ""
	if pad == null or not pad.has_method("flip_cluster_owner"):
		_toast_hud("Occupy an unnamed pad to flip owner (CX↔GR)")
		return
	after = str(pad.flip_cluster_owner())
	if after == "":
		_toast_hud("Owner flip refused — hold the pad first")
		return
	if pad.has_method("services_line"):
		_toast_hud("Owner → %s · %s · same tier" % [after, str(pad.services_line())])
	else:
		_toast_hud("Owner → %s · same tier" % after)


func _bind_planet_observers() -> void:
	for pl in planets:
		if pl and pl.has_method("set_observer") and ship:
			pl.set_observer(ship)
		_set_planet_observers(ship)


func _sync_planet_sun() -> void:
	## Each body is lit from the star it orbits, not from one fixed world angle.
	var sun := $Sun as DirectionalLight3D
	var sc: Vector3 = star_position()
	for pl in planets:
		if pl == null or not is_instance_valid(pl) or not pl.has_method("set_sun_direction"):
			continue
		var to_body: Vector3 = (pl as Node3D).global_position - sc
		if to_body.length_squared() < 1.0:
			continue
		pl.set_sun_direction(to_body.normalized())
	# Aim the shadow-casting light along the star→observer line so the terminator
	# on the planet you are at matches where the star actually is.
	if sun == null:
		return
	var obs: Node3D = ship if (ship and is_instance_valid(ship)) else (player if (player and is_instance_valid(player)) else null)
	if obs == null:
		return
	var to_obs: Vector3 = obs.global_position - sc
	if to_obs.length_squared() < 1.0:
		return
	sun.look_at_from_position(sun.global_position, sun.global_position + to_obs.normalized(), Vector3.UP)


func _update_altitude_fog() -> void:
	## Height fog + scatter tint across the catalog envelope (OS-B).
	if _interior_view:
		_apply_interior_env()
		return
	if _interior != null and is_instance_valid(_interior) and _interior.has_method("is_inside") and bool(_interior.is_inside()):
		_apply_interior_env()
		return
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
	var h: float = _envelope_of(pl)
	var col = pl.get("atmosphere_color")
	var fog_col := Color(0.18, 0.32, 0.55)
	if col is Color:
		fog_col = Color(col.r, col.g, col.b).lerp(Color(0.55, 0.72, 0.98), 0.32)
	var depth: float = clampf(1.0 - maxf(alt, 0.0) / maxf(h, 1.0), 0.0, 1.0)
	if alt > h:
		env.fog_enabled = false
		env.fog_sun_scatter = 0.0
		env.ambient_light_energy = 0.28
		env.glow_intensity = 0.55
		return
	env.fog_enabled = true
	env.fog_light_color = fog_col
	env.fog_light_energy = 0.85 + depth * 0.45
	env.fog_sun_scatter = 0.18 + depth * 0.42
	env.fog_aerial_perspective = depth * 0.55
	env.fog_sky_affect = 0.35 + depth * 0.4
	var dens: float = 0.00022 + depth * depth * 0.0034
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
				env.fog_sun_scatter *= 0.65
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


func set_interior_view(on: bool) -> void:
	_interior_view = on
	var sun := $Sun as DirectionalLight3D
	if on:
		_apply_interior_env()
		if sun:
			sun.light_energy = 0.22
			sun.shadow_enabled = false
	else:
		_restore_exterior_env_sources()
		if sun:
			sun.light_energy = 1.35
			sun.shadow_enabled = true
		_update_altitude_fog()


func _apply_interior_env() -> void:
	var we := $WorldEnvironment as WorldEnvironment
	if we == null or we.environment == null:
		return
	var env := we.environment
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	env.fog_density = 0.0
	env.fog_sun_scatter = 0.0
	env.background_color = Color(0.04, 0.05, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.92, 0.98)
	env.ambient_light_energy = 0.9
	env.glow_intensity = 0.18
	env.glow_enabled = true


func _restore_exterior_env_sources() -> void:
	## Pocket paint must not stick after pad↔flight: sky + sky ambient
	## (OpenSpace.tscn Env). Altitude fog then retunes energy.
	var we := $WorldEnvironment as WorldEnvironment
	if we == null or we.environment == null:
		return
	var env := we.environment
	env.background_mode = Environment.BG_SKY
	env.background_color = Color(0.004, 0.005, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.05, 0.07, 0.14)


func approach_start_agl() -> float:
	return APPROACH_START_AGL


func _fit_camera_to_approach(sh: Node3D, pl: Node3D) -> void:
	## Scene default far=4000 clips a 5–15 km body. Match GraphicsQuality, then
	## guarantee the far side of the approached planet stays in the frustum.
	var cam: Camera3D = sh.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if cam == null:
		return
	var gq := get_node_or_null("/root/GraphicsQuality")
	var clip := 22000.0
	if gq and "far_clip" in gq:
		clip = float(gq.far_clip)
	var rad: float = float(pl.get("radius") if pl.get("radius") != null else 1400.0)
	var need := APPROACH_AGL_MAX + rad * 2.0 + 2500.0
	cam.far = maxf(clip, need)
	if gq and "near_clip" in gq:
		cam.near = float(gq.near_clip)


func gravity_at(global_pos: Vector3) -> Vector3:
	var g := Vector3.ZERO
	for pl in planets:
		if pl.has_method("gravity_at"):
			g += pl.gravity_at(global_pos)
	return g



func _envelope_of(pl: Node) -> float:
	if pl != null and pl.has_method("envelope_height"):
		return float(pl.call("envelope_height"))
	var pid := str(pl.get("planet_name")) if pl else ""
	if pid != "" and pid != "<null>":
		return float(_PlanetProfiles.envelope_of(pid))
	var h_val = pl.get("atmosphere_height") if pl else null
	return float(h_val) * 1.6 if h_val != null else 448.0


func atmosphere_density_at(global_pos: Vector3) -> float:
	var pl: Node3D = nearest_planet(global_pos)
	if pl == null or not is_instance_valid(pl):
		return 0.0
	if pl.has_method("density_at"):
		return float(pl.call("density_at", global_pos))
	var alt := 99999.0
	if pl.has_method("altitude_of"):
		alt = float(pl.altitude_of(global_pos))
	var ah := 280.0
	if "atmosphere_height" in pl:
		ah = float(pl.atmosphere_height)
	return float(_Flight.atmosphere_density(alt, ah, _envelope_of(pl)))


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
	reclaim_pilot_camera()
	print("[OpenSpace] ship landed (seamless — same scene)")

func _on_ship_launched() -> void:
	## 3090: SPACE @ 8 km is fine. Black is pad LAND / cockpit / Space→HOVER.
	ensure_flight_view()
	print("[OpenSpace] ship launched")


func ensure_flight_view() -> void:
	## Pad ↔ flight: close the ship pocket, unhide WorldRoot, seat chase cam.
	## Boot sky/planet is already correct on the 3090 — do not retune spawn.
	if strategy_overlay_active():
		return
	var pocket_walker := false
	if _interior != null and is_instance_valid(_interior) and _interior.has_method("is_inside") and bool(_interior.is_inside()):
		if not _interior.has_method("get_kind") or str(_interior.get_kind()) == "ship":
			pocket_walker = true
	if player != null and is_instance_valid(player) and "interior_mode" in player and bool(player.interior_mode):
		pocket_walker = true
	_close_interior_for_flight()
	## OR: _do_launch and launched both call this; the second must not clear the flag.
	_drop_pocket_walker = _drop_pocket_walker or pocket_walker
	var eva_walker_live := player != null and is_instance_valid(player) and not pocket_walker
	if not eva_walker_live:
		_in_ship = true
		_eva_mode = false
		if LayerContext:
			LayerContext.set_layer("Space")
			if "seamless_stage" in LayerContext:
				LayerContext.seamless_stage = "world"
	_interior_view = false
	if world_root:
		world_root.visible = true
	set_interior_view(false)
	if not eva_walker_live:
		_restore_floating_origin_to_ship()
	if ship == null or not is_instance_valid(ship):
		return
	if pocket_walker:
		for pl_obs in planets:
			if pl_obs != null and is_instance_valid(pl_obs) and pl_obs.has_method("set_observer"):
				pl_obs.set_observer(ship)
		_bind_soft_net_actor(ship)
		_hand_view_to_ship()
		if ship.has_method("set_pilot_active"):
			ship.set_pilot_active(true)
		_hand_view_to_ship()
	elif not eva_walker_live:
		if ship.has_method("set_pilot_active"):
			ship.set_pilot_active(true)
		_hand_view_to_ship()
	var pl: Node3D = nearest_planet(ship.global_position)
	if pl:
		_fit_camera_to_approach(ship, pl)
	if not eva_walker_live:
		reclaim_pilot_camera()
	## Walker free / GLB enter_tree can run next idle frame (clear_current lottery).
	call_deferred("_finish_flight_view")


func _close_interior_for_flight() -> void:
	if _interior == null or not is_instance_valid(_interior):
		return
	if not _interior.has_method("is_inside") or not bool(_interior.is_inside()):
		return
	# Station / hangar_bay pockets are not the flight seat. Do not steal their walker.
	if _interior.has_method("get_kind") and str(_interior.get_kind()) != "ship":
		return
	if _interior.has_method("exit_for_pilot"):
		_interior.exit_for_pilot()


func _restore_floating_origin_to_ship() -> void:
	if floating == null or not is_instance_valid(floating):
		return
	if floating.has_method("set_process"):
		floating.set_process(true)
	if floating.has_method("set_physics_process"):
		floating.set_physics_process(true)
	if ship != null and is_instance_valid(ship) and floating.has_method("set_target"):
		floating.set_target(ship)


func _finish_flight_view() -> void:
	## Only drop the pocket walker. An EVA/pad walker must survive a later
	## `_do_launch` (harvest / tether / EVA→board tests).
	if _drop_pocket_walker:
		_drop_pocket_walker = false
		_hand_view_to_ship()
		if player != null and is_instance_valid(player):
			_safe_free_walker()
		if ship != null and is_instance_valid(ship):
			if ship.has_method("set_pilot_active"):
				ship.set_pilot_active(true)
			if ship.has_method("set_hatch_open"):
				ship.set_hatch_open(false)
		_seat_transition = false
		var hud = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
		if hud and hud.has_method("bind_player") and ship:
			hud.bind_player(ship)
	if _in_ship:
		commit_presence("pilot")


func _hand_view_to_ship() -> void:
	var walker_cam: Camera3D = null
	if player != null and is_instance_valid(player):
		walker_cam = player.get_node_or_null("CamPivot/Camera3D") as Camera3D
		if walker_cam == null and "camera" in player:
			walker_cam = player.camera as Camera3D
	if walker_cam != null:
		walker_cam.current = false
		walker_cam.clear_current(false)
	var cam: Camera3D = null
	if ship != null and is_instance_valid(ship):
		cam = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	var vp := get_viewport()
	if vp != null:
		var live: Camera3D = vp.get_camera_3d()
		if live != null and live != cam:
			live.current = false
			live.clear_current(false)
	if cam:
		cam.current = true
	reclaim_pilot_camera()


func reclaim_pilot_camera() -> void:
	if strategy_overlay_active():
		return
	if _in_rover or not _in_ship:
		return
	if ship == null or not is_instance_valid(ship):
		return
	if ship.has_method("is_npc_pilot") and bool(ship.is_npc_pilot()):
		return
	if "pilot_active" in ship and not bool(ship.get("pilot_active")):
		return
	var cam: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if cam == null:
		return
	var vp := get_viewport()
	if vp != null:
		var live: Camera3D = vp.get_camera_3d()
		if live != null and live != cam:
			live.current = false
			live.clear_current(false)
	cam.current = true


func commit_presence(kind: String) -> void:
	## Atomic seat/hatch/board. Layer + HUD + radar + camera follow `_in_ship`.
	## kind: pilot | pocket | walker | eva
	match kind:
		"pilot":
			_in_ship = true
			_eva_mode = false
			if LayerContext:
				LayerContext.set_layer("Space")
				LayerContext.seamless_stage = "world"
			_bind_presence_camera("pilot")
			_bind_presence_hud(ship)
		"pocket":
			_in_ship = false
			_eva_mode = false
			if LayerContext:
				LayerContext.set_layer("ship_int")
				LayerContext.seamless_stage = "pocket"
			_bind_presence_camera("pocket")
			_bind_presence_hud(player)
		"walker":
			_in_ship = false
			_eva_mode = false
			if player != null and is_instance_valid(player):
				if player.has_method("set_interior_mode"):
					player.set_interior_mode(false)
				elif "interior_mode" in player:
					player.interior_mode = false
				if player.has_method("set_eva_profile"):
					player.set_eva_profile(false)
				if "zero_g" in player:
					player.zero_g = false
				if player.has_method("_near_dirt_floor") and bool(player.call("_near_dirt_floor")):
					player.set("_coyote_t", 0.14)
					player.set("_spawn_grace_t", 0.0)
					if player.has_method("_update_up"):
						player._update_up()
					if player.has_method("_relief_slope_rad") and "last_slope_ang" in player:
						player.set("last_slope_ang", float(player.call("_relief_slope_rad")))
			if LayerContext:
				LayerContext.set_layer("TPS")
				LayerContext.seamless_stage = "surface"
			_bind_presence_camera("walker")
			_bind_presence_hud(player)
		"eva":
			_in_ship = false
			_eva_mode = true
			if player != null and is_instance_valid(player) and "interior_mode" in player:
				player.interior_mode = false
			if LayerContext:
				LayerContext.set_layer("TPS")
				LayerContext.seamless_stage = "eva"
			_bind_presence_camera("eva")
			_bind_presence_hud(player)
		_:
			return


func _bind_presence_camera(kind: String) -> void:
	## Hatch must not leave the hull chase cam current; board must not leave TPS.
	if kind == "pilot":
		reclaim_pilot_camera()
		return
	if ship != null and is_instance_valid(ship):
		var scam: Camera3D = ship.get_node_or_null("CameraPivot/Camera3D") as Camera3D
		if scam != null:
			scam.current = false
			scam.clear_current(false)
	if player == null or not is_instance_valid(player):
		return
	var wcam: Camera3D = player.get_node_or_null("CamPivot/Camera3D") as Camera3D
	if wcam == null and "camera" in player:
		wcam = player.camera as Camera3D
	if wcam != null:
		wcam.current = true


func _bind_presence_hud(actor: Node) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var hud: Node = tree.get_first_node_in_group("game_hud")
	if hud == null:
		return
	if actor != null and is_instance_valid(actor) and hud.has_method("bind_player"):
		hud.bind_player(actor)
	if hud.has_method("_refresh"):
		hud._refresh()


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
	commit_presence("walker" if landed else "eva")
	_toast_hud("EVA suit" if _eva_mode else "Debarked — clear of hull")
	print("[OpenSpace] exited ship  eva=", _eva_mode)


func try_enter_ship() -> void:
	if _seat_transition:
		return
	if _in_ship or ship == null or not is_instance_valid(ship):
		return
	if player == null or not is_instance_valid(player):
		player = null
		print("[OpenSpace] No walker to board")
		return
	var board_r := 16.0
	if _eva_mode:
		board_r = 28.0
	elif ship != null and bool(ship.get("is_landed")):
		var lp: Node3D = null
		if ship.has_method("get_landed_pad"):
			lp = ship.get_landed_pad() as Node3D
		if lp == null:
			# Dirt hull-side spawn is ~11 m + HatchPoint offset. 16 m misses.
			board_r = 28.0
	var board_anchor: Vector3 = ship.global_position
	var hatch_n: Node3D = ship.get_node_or_null("HatchPoint") as Node3D
	if hatch_n != null and is_instance_valid(hatch_n):
		board_anchor = hatch_n.global_position
	if player.global_position.distance_to(board_anchor) > board_r:
		print("[OpenSpace] Too far from hatch")
		_toast_hud("Too far from hatch")
		return
	_seat_transition = true
	_in_ship = true
	_eva_mode = false
	if LayerContext:
		LayerContext.set_layer("Space")
	if player.has_method("mark_dying"):
		player.mark_dying()
	_hand_view_to_ship()
	for pl in planets:
		if pl != null and is_instance_valid(pl) and pl.has_method("set_observer"):
			pl.set_observer(ship)
	if floating != null and is_instance_valid(floating) and floating.has_method("set_target"):
		floating.set_target(ship)
	_bind_soft_net_actor(ship)
	if SoftScanCache != null and SoftScanCache.has_method("invalidate_player"):
		SoftScanCache.invalidate_player()
	call_deferred("_finish_board_ship")
	_toast_hud("Boarding…")


func _finish_board_ship() -> void:
	_hand_view_to_ship()
	_safe_free_walker()
	if ship != null and is_instance_valid(ship) and ship.has_method("set_pilot_active"):
		ship.set_pilot_active(true)
	_seat_transition = false
	commit_presence("pilot")
	print("[OpenSpace] boarded ship OK")



func _spawn_eva_near_ship() -> void:
	## Open-space EVA from hatch: thruster suit, velocity match, hatch ajar.
	if ship == null or not is_instance_valid(ship):
		return
	player = _make_fallback_player()
	# Set before add_child so _ready does not defer snap_to_surface onto dirt.
	player.set("eva_mode", true)
	player.set("zero_g", true)
	world_root.add_child(player)
	var hatch: Node3D = ship.get_node_or_null("HatchPoint") as Node3D
	var side: Vector3 = ship.global_transform.basis.x
	var up: Vector3 = ship.global_transform.basis.y
	var aft: Vector3 = ship.global_transform.basis.z
	if hatch:
		# Out from hatch along +X of ship (hatch side) + slight aft
		player.global_position = hatch.global_position + side * 2.2 + up * 0.4 + aft * 0.5
	else:
		player.global_position = ship.global_position + side * 4.5 + up * 1.4
	# Open hatch door soft
	if ship != null and is_instance_valid(ship) and ship.has_method("set_hatch_open"):
		ship.set_hatch_open(true)
	else:
		var door = ship.get_node_or_null("HatchPoint/HatchDoor")
		if door is Node3D:
			(door as Node3D).visible = true
			(door as Node3D).rotation.y = deg_to_rad(85.0)
	if player != null and is_instance_valid(player) and player.has_method("set_planet_gravity_provider"):
		player.set_planet_gravity_provider(self)
	if player != null and is_instance_valid(player) and player.has_method("set_eva_profile"):
		player.set_eva_profile(true)
	if player != null and is_instance_valid(player):
		var nose: Vector3 = -ship.global_transform.basis.z
		if player.has_method("set_spawn_facing"):
			player.set_spawn_facing(up, nose)
		elif player.has_method("set_spawn_basis"):
			player.set_spawn_basis(up, atan2(-nose.x, -nose.z))
	# Match ship velocity so no instant relative slam
	if player is CharacterBody3D and "velocity" in ship and ship.velocity is Vector3:
		(player as CharacterBody3D).velocity = (ship.velocity as Vector3) * 0.9
	# Skip floor snap for EVA
	if player != null and is_instance_valid(player) and player.has_method("set") and "eva_mode" in player:
		pass
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_toast_hud("EVA zero-G — thrusters WASD · Space/Shift · F reboard hatch")
	print("[OpenSpace] EVA zero-G deployed from hatch")


func _land_eva_pad() -> Node3D:
	## Occupied unnamed deck the hull actually landed on. Not nearest dirt.
	if ship != null and is_instance_valid(ship) and ship.has_method("get_landed_pad"):
		var landed_pad: Node3D = ship.get_landed_pad() as Node3D
		if landed_pad != null and is_instance_valid(landed_pad):
			if ship.global_position.distance_to(landed_pad.global_position) <= 16.0:
				return landed_pad
	return null


func _place_walker_on_land_deck(walker: Node3D) -> bool:
	## Outdoor pad-deck walker. Not the in-flight ship pocket (y=9200).
	if walker == null or not is_instance_valid(walker):
		return false
	if world_root != null and is_instance_valid(world_root):
		world_root.visible = true
	if walker.has_method("set_interior_mode"):
		walker.set_interior_mode(false)
	elif "interior_mode" in walker:
		walker.interior_mode = false
	if walker.has_method("set_eva_profile"):
		walker.set_eva_profile(false)
	var pad: Node3D = _land_eva_pad()
	if pad == null or not is_instance_valid(pad):
		return false
	var pad_up := Vector3.UP
	if pad.has_meta("pad_up"):
		var raw: Vector3 = pad.get_meta("pad_up")
		if raw.length_squared() > 0.01:
			pad_up = raw.normalized()
	else:
		var pl = nearest_planet(pad.global_position)
		if pl != null and is_instance_valid(pl):
			pad_up = (pad.global_position - pl.global_position).normalized()
	var side: Vector3 = Vector3.ZERO
	if ship != null and is_instance_valid(ship):
		side = ship.global_transform.basis.x
	if side.length_squared() < 0.01:
		side = pad.global_transform.basis.x
	side = side - pad_up * side.dot(pad_up)
	if side.length_squared() < 0.01:
		side = pad_up.cross(Vector3.RIGHT)
	side = side.normalized()
	# On the 28 m plate, clear of the hull (5.5 m was still inside the mesh).
	walker.global_position = pad.global_position + pad_up * 1.35 + side * 11.0
	if walker.has_method("set_planet_gravity_provider"):
		walker.set_planet_gravity_provider(self)
	var nose := Vector3.FORWARD
	if ship != null and is_instance_valid(ship):
		nose = -ship.global_transform.basis.z
	nose = nose - pad_up * nose.dot(pad_up)
	if nose.length_squared() < 0.01:
		nose = -pad.global_transform.basis.z
		nose = nose - pad_up * nose.dot(pad_up)
	if nose.length_squared() > 0.01:
		nose = nose.normalized()
	if walker.has_method("set_spawn_facing"):
		walker.set_spawn_facing(pad_up, nose)
	elif walker.has_method("set_spawn_basis"):
		walker.set_spawn_basis(pad_up, atan2(-nose.x, -nose.z))
	if walker.has_method("snap_to_pad"):
		walker.snap_to_pad(pad)
	print("[OpenSpace] land EVA on pad deck ", pad.name, " at ", walker.global_position)
	return true


func _spawn_player_near_ship() -> void:
	_eva_mode = false

	# SurfaceWalker on the occupied unnamed pad deck — not the ship pocket.
	if ship == null or not is_instance_valid(ship):
		return
	player = _make_fallback_player()
	player.set_meta("skip_ready_snap", true)
	world_root.add_child(player)
	if not _place_walker_on_land_deck(player):
		## Dirt EVA: local radial up + hull nose. Not nearest-pad up (sideways W).
		var pad_up := Vector3.UP
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
		player.global_position = ship.global_position + pad_up * 3.2 + side * 11.0
		if player.has_method("set_planet_gravity_provider"):
			player.set_planet_gravity_provider(self)
		if player.has_method("set_eva_profile"):
			player.set_eva_profile(false)
		var nose: Vector3 = -ship.global_transform.basis.z
		nose = nose - pad_up * nose.dot(pad_up)
		if nose.length_squared() < 0.01:
			nose = -ship.global_transform.basis.x
			nose = nose - pad_up * nose.dot(pad_up)
		if nose.length_squared() > 0.01:
			nose = nose.normalized()
		if player.has_method("set_spawn_facing"):
			player.set_spawn_facing(pad_up, nose)
		elif player.has_method("set_spawn_basis"):
			player.set_spawn_basis(pad_up, atan2(-nose.x, -nose.z))
		if player.has_method("snap_to_surface"):
			player.snap_to_surface()
		if player.has_method("set_eva_profile"):
			player.set_eva_profile(false)
		if player.has_method("set_interior_mode"):
			player.set_interior_mode(false)
		elif "interior_mode" in player:
			player.interior_mode = false
		player.set("_spawn_grace_t", 0.0)
		if player.has_method("_update_up"):
			player._update_up()
		if player.has_method("_relief_slope_rad") and "last_slope_ang" in player:
			player.set("last_slope_ang", float(player.call("_relief_slope_rad")))
		if player.has_method("set_spawn_facing") and nose.length_squared() > 0.01:
			player.set_spawn_facing(pad_up, nose)
		print("[OpenSpace] TPS dirt exit at ", player.global_position, " up=", pad_up)
	if player != null and is_instance_valid(player) and player.has_method("snap_to_surface"):
		_schedule_surface_settle()
	if is_instance_valid(ship) and ship.has_method("set_pilot_active"):
		ship.set_pilot_active(false)
	if player != null and is_instance_valid(player) and player.has_method("_bind_hud"):
		player._bind_hud()
	_bind_soft_net_actor(player)


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


var _hud_accum: float = 0.0
var _os_perf_applied: bool = false

func _process(delta: float) -> void:
	if not _os_perf_applied:
		_os_perf_applied = true
		_apply_openspace_perf()
	_hud_accum += delta
	# Fog + HUD ~8Hz (was every frame — string build is not free)
	if _hud_accum >= 0.12:
		_hud_accum = 0.0
		reclaim_pilot_camera()
		_update_altitude_fog()
		_update_hud()
		_park_far_planets()
	# Soft EVA timer (warning only — no death Phase 0)
	if _eva_mode and player and is_instance_valid(player) and "eva_time" in player:
		if float(player.eva_time) > 90.0:
			_eva_warn_t += delta
			if _eva_warn_t > 8.0:
				_eva_warn_t = 0.0
				_toast_hud("EVA suit — reboard soon (soft warn)")
				print("[OpenSpace] EVA soft warning — reboard soon")
		_tick_eva_tether(delta)


func eva_tether_distance() -> float:
	if not _eva_mode or player == null or not is_instance_valid(player):
		return -1.0
	if ship == null or not is_instance_valid(ship):
		return -1.0
	return player.global_position.distance_to(ship.global_position)


func _tick_eva_tether(delta: float) -> void:
	## Soft reel-in past 120m. Warn at 80m. Never lethal.
	if ship == null or not is_instance_valid(ship) or player == null or not is_instance_valid(player):
		return
	var td: float = player.global_position.distance_to(ship.global_position)
	if td <= 80.0:
		_eva_tether_t = 0.0
		return
	_eva_tether_t += delta
	if _eva_tether_t > 5.0:
		_eva_tether_t = 0.0
		_toast_hud("EVA tether soft — ship %.0fm" % td)
	if td <= 120.0:
		return
	if player.get("_mag_latched"):
		return
	var dir: Vector3 = ship.global_position - player.global_position
	if dir.length_squared() < 0.01:
		return
	dir = dir.normalized()
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity += dir * 7.5 * delta
	if player is Node3D:
		(player as Node3D).global_position += dir * 5.0 * delta


func _update_hud() -> void:
	if hud_label == null or ship == null or not is_instance_valid(ship):
		return
	if strategy_overlay_active() and _strategy.has_method("readiness_line"):
		var ov := str(_strategy.readiness_line())
		hud_label.visible = true
		var pvp := ""
		if _strategy.has_method("pvp_hud_line"):
			pvp = "  ·  %s  ·  R pulse" % str(_strategy.pvp_hud_line())
		hud_label.text = ov + pvp + "  ·  Q hack  E firewall  ·  Esc leave"
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
		if _rover != null and is_instance_valid(_rover) and _rover.has_method("label_text"):
			var rlab := str(_rover.label_text())
			if rlab != "":
				mode = rlab
	elif _interior != null and is_instance_valid(_interior) and _interior.has_method("is_inside") and bool(_interior.is_inside()):
		mode = "INTERIOR"
	elif _eva_mode:
		mode = "EVA 0G"
		if player != null and is_instance_valid(player) and player.has_method("is_zero_g") and not bool(player.is_zero_g()):
			mode = "EVA"
	elif not _in_ship:
		mode = "ON FOOT"
	var gq := get_node_or_null("/root/GraphicsQuality")
	var gqn: String = gq.tier_name() if gq else "?"
	var spd: float = 0.0
	if _in_rover and _rover != null and is_instance_valid(_rover) and "velocity" in _rover:
		spd = float(_rover.velocity.length())
	elif _in_ship and is_instance_valid(ship):
		spd = ship.velocity.length()
	elif player != null and is_instance_valid(player):
		spd = player.velocity.length()
	var dbg := false
	var gh = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
	if gh and gh.has_method("is_debug_overlay"):
		dbg = bool(gh.is_debug_overlay())
	var loc := pname
	var atmo_now := 0.0
	if has_method("atmosphere_density_at") and ship:
		atmo_now = float(atmosphere_density_at(ship.global_position))
	var alt_s := "%dm" % int(alt)
	if atmo_now > 0.01 and mode != "INTERIOR":
		alt_s = "%dm ATMO %d%%" % [int(alt), int(atmo_now * 100.0)]
	if mode == "INTERIOR":
		loc = str(_interior.get_kind()) if _interior.has_method("get_kind") else "pocket"
		alt_s = "POCKET"
	# GameHUD owns pocket chrome; hide the ship occupy/AGL one-liner unless F3.
	hud_label.visible = not (mode == "INTERIOR" and not dbg)
	var extra := ""
	if mode == "INTERIOR" and _interior.has_method("life_support_line"):
		extra = "  ·  " + str(_interior.life_support_line())
	elif _in_ship:
		if bool(ship.get("is_landed")):
			extra = "  ·  LANDED"
		else:
			if ship.has_method("get_stall") and float(ship.get_stall()) > 0.4:
				extra = "  ·  STALL %.0f%%" % (float(ship.get_stall()) * 100.0)
			if ship.has_method("land_readiness_line"):
				var lr := str(ship.land_readiness_line())
				if lr != "" and lr != "LANDED":
					extra += "  ·  " + lr
	var tail := "  ·  occupy/C · E land · F EVA"
	if _in_ship and not bool(ship.get("is_landed")):
		tail = "  ·  S descend · occupy/C · E land · F EVA"
	elif bool(ship.get("is_landed")):
		tail = ""
	if _strategy != null and _strategy.has_method("readiness_line"):
		var rl := str(_strategy.readiness_line())
		if rl.find("B overlay") >= 0:
			tail += "  ·  B overlay"
	var brief := "%s  ·  %s  ·  %s  ·  %d m/s  ·  HP %d  SHD %d%s%s" % [
		mode, loc, alt_s, int(spd), int(ship.health), int(ship.shields), extra, tail
	]
	var ally: Node = get_alliance()
	if ally != null and ally.has_method("hud_line"):
		var al := str(ally.hud_line())
		if al != "":
			brief += "\n" + al
	if not dbg:
		hud_label.text = brief
	else:
		hud_label.text = (
			"NAEON OpenSpace  |  free flight · seamless land · surface walk\n"
			+ "WASD thrust  Space/Shift lift  Mouse=flight plane  Z/X roll  |  1/2/3 flight  4 siege  5 ramp  6 rover  7 store  9/0 cargo  |  E land  F exit/EVA/board  C pulse  G/B terra  U undo  I interior  Q hack\n"
			+ "F1 cycle quality  F3 HUD debug  |  Tab Clash sandbox (not a map)  ·  M galaxy map locked\n"
			+ "Mode: %s  Planet: %s  Alt: %dm  ATMO:%.0f%%  Spd: %d  HP:%d SHD:%d  PLOD:%s  CONTRIB:%.0f" % [
				mode, pname, int(alt), atmo_now * 100.0, int(spd), int(ship.health), int(ship.shields), (pl.current_lod_name() if pl and is_instance_valid(pl) and pl.has_method("current_lod_name") else "-"), (GameManager.contribution if GameManager else 0.0)
			]
		)
	if dbg:
		var objs := int(Performance.get_monitor(Performance.OBJECT_COUNT))
		var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var oram := int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
		var live := 0
		var pool := 0
		var pa := 0
		var pf := 0
		if pl != null and is_instance_valid(pl):
			var sd = pl.get_node_or_null("SurfaceDetail")
			if sd != null and sd.has_method("live_count"):
				live = int(sd.live_count())
			# SurfaceDetail exposes queue_depth, not pool_count — the old name
			# never matched, so this always read 0.
			if sd != null and sd.has_method("queue_depth"):
				pool = int(sd.queue_depth())
		var PP = load("res://scripts/combat/ProjectilePool.gd")
		if PP:
			pa = int(PP.active_count())
			pf = int(PP.free_count())
		hud_label.text += "\nMEM obj:%d nodes:%d ram:%dMB  detail %d/%d  proj %d/%d" % [objs, nodes, oram, live, pool, pa, pf]
	var oram2 := int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	# GameHUD owns the top-right GFX/FPS stack so Mode does not sit on LAYER.
	if mode_label:
		mode_label.visible = false
		mode_label.text = "GFX: %s  MEM %dMB" % [gqn, oram2]
	var gh_stack = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
	if gh_stack and gh_stack.has_method("set_gfx_line"):
		gh_stack.set_gfx_line(gqn, oram2)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE):
		if strategy_overlay_active() and _strategy.has_method("exit_overlay"):
			_strategy.exit_overlay()
			get_viewport().set_input_as_handled()
			return
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
		KEY_6:
			if not _in_ship:
				_try_deploy_hangar_rover()
		KEY_N:
			invite_nearby_npc()
		KEY_J:
			accept_nearby_npc_contract()
		KEY_7:
			_try_store_rover()
		KEY_F1:
			var gq := get_node_or_null("/root/GraphicsQuality")
			if gq:
				gq.cycle()
		KEY_P:
			if GameManager and GameManager.has_method("try_promote_alliance"):
				GameManager.try_promote_alliance()
		KEY_O:
			_try_flip_pad_owner()
		KEY_M:
			_toast_hud("Galaxy map locked (G2) — not implemented. M is not a map.")
		KEY_TAB:
			_toast_hud("Clash sandbox — not a galaxy map")
			if ResourceLoader.exists("res://scenes/test/TestArena.tscn"):
				get_tree().change_scene_to_file("res://scenes/test/TestArena.tscn")


func invite_nearby_npc() -> bool:
	## NP-D: invite the pad visitor into the local squad. Not a pay-slot.
	if _squad == null or not _squad.has_method("invite"):
		return false
	var traffic: Node = _pad_traffic_node()
	if traffic == null:
		_toast_hud("No NPC nearby")
		return false
	var pilot: Node = traffic.get_npc_pilot() if traffic.has_method("get_npc_pilot") else null
	var visitor: Node3D = traffic.get_visitor() if traffic.has_method("get_visitor") else null
	if pilot == null or visitor == null or not is_instance_valid(visitor):
		_toast_hud("No NPC nearby")
		return false
	var actor: Node3D = player if player != null and is_instance_valid(player) else ship
	if actor == null or not is_instance_valid(actor):
		_toast_hud("No NPC nearby")
		return false
	if actor.global_position.distance_to(visitor.global_position) > 90.0:
		_toast_hud("Closer to invite")
		return false
	if _squad.contains(pilot) if _squad.has_method("contains") else false:
		_toast_hud(_squad.hud_line() if _squad.has_method("hud_line") else "Already in squad")
		return false
	if not bool(_squad.invite(pilot)):
		_toast_hud("Squad full (2–5)")
		return false
	if SoftSession and SoftSession.has_method("note_player_action"):
		SoftSession.note_player_action("invite")
	_toast_hud("Squad 2/5 · visitor · no power")
	return true


func accept_nearby_npc_contract() -> Dictionary:
	## Q-D: accept the same Q-A ContractBoard from the pad visitor. Not a second board.
	var traffic: Node = _pad_traffic_node()
	var pilot: Node = null
	var visitor: Node3D = null
	var actor: Node3D = player if player != null and is_instance_valid(player) else ship
	var cur: Dictionary = {}
	if traffic == null:
		_toast_hud("No NPC nearby")
		return {}
	pilot = traffic.get_npc_pilot() if traffic.has_method("get_npc_pilot") else null
	visitor = traffic.get_visitor() if traffic.has_method("get_visitor") else null
	if pilot == null or visitor == null or not is_instance_valid(visitor):
		_toast_hud("No NPC nearby")
		return {}
	if actor == null or not is_instance_valid(actor):
		_toast_hud("No NPC nearby")
		return {}
	if actor.global_position.distance_to(visitor.global_position) > 90.0:
		_toast_hud("Closer to the giver")
		return {}
	if not pilot.has_method("accept_player_contract"):
		return {}
	if pilot.has_method("offer_player_contract") and str(pilot.offered_player_contract_id() if pilot.has_method("offered_player_contract_id") else "") == "":
		pilot.offer_player_contract()
	cur = pilot.accept_player_contract()
	if cur.is_empty() or str(cur.get("status", "")) == "":
		_toast_hud("No contract on this giver")
		return {}
	_toast_hud("Contract %s · %s" % [str(cur.get("id", "")), str(cur.get("status", ""))])
	return cur


func _pad_traffic_node() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var listed: Array = tree.get_nodes_in_group("pad_traffic")
	if listed.size() > 0:
		return listed[0]
	for pl in planets:
		if pl != null and is_instance_valid(pl) and pl.has_method("pad_traffic"):
			var t: Node = pl.call("pad_traffic")
			if t != null:
				return t
	return null


func clash_pad_door() -> Node3D:
	## AR-H: occupied-pad door into Clash TestArena. Not a city-map.
	var traffic := _pad_traffic_node()
	if traffic != null and traffic.has_method("get_clash_door"):
		var d: Node3D = traffic.get_clash_door()
		if d != null and is_instance_valid(d):
			return d
	return null


func clash_door_target() -> String:
	return "res://scenes/test/TestArena.tscn"


func is_city_map() -> bool:
	return false


func is_near_clash_door(who: Node3D = null, max_dist: float = 4.2) -> bool:
	var door := clash_pad_door()
	if door == null:
		return false
	var actor: Node3D = who
	if actor == null:
		actor = player if player != null and is_instance_valid(player) else ship
	if actor == null or not is_instance_valid(actor):
		return false
	return actor.global_position.distance_to(door.global_position) <= max_dist


func try_clash_pad_door() -> bool:
	## F at the pad door → Clash TestArena. Headless keeps this OpenSpace.
	## Not enter_clash_from_world (G5). Not a city-map (G2).
	if _in_ship:
		return false
	if not is_near_clash_door(player, 4.2):
		return false
	var target := clash_door_target()
	if not ResourceLoader.exists(target):
		_toast_hud("Clash door — TestArena missing")
		return false
	set_meta("clash_via_pad_door", true)
	set_meta("city_map", false)
	set_meta("site_pin", "")
	if LayerContext:
		LayerContext.set_layer("Arena")
	_toast_hud("CLASH DOOR · TESTARENA")
	print("[OpenSpace] AR-H clash door → TestArena layer=Arena city_map=0")
	_setup_clash_softnet()
	if DisplayServer.get_name() == "headless":
		return true
	get_tree().change_scene_to_file(target)
	return true


func _try_clash_pad_door() -> bool:
	return try_clash_pad_door()


func _handle_f_interact() -> void:
	# Priority: unboard rover → pocket seat / hatch → rover → seat→pilot → ship board/exit
	if _seat_transition or _rover_transition:
		return
	if _in_rover and _rover != null and is_instance_valid(_rover):
		_unboard_rover()
		return
	if not _in_ship and player and is_instance_valid(player) and player.is_inside_tree():
		if _pocket_f_interact():
			return
		if _try_clash_pad_door():
			return
		if _try_board_nearby_rover():
			return
		if _try_seat_to_pilot():
			return
	if _in_ship:
		try_exit_ship()
	else:
		try_enter_ship()


func _pocket_f_interact() -> bool:
	## Interior leftover: F at hatch is the airlock (same as I). F at seat boards.
	## Do not fall through to try_enter_ship from y=9200 (silent miss).
	if _interior == null or not is_instance_valid(_interior):
		return false
	if not _interior.has_method("is_inside") or not bool(_interior.is_inside()):
		return false
	if _interior.has_method("is_seated") and bool(_interior.is_seated()):
		if _interior.has_method("leave_legal_seat"):
			_interior.leave_legal_seat()
		return true
	if _try_board_pocket_seat():
		return true
	if _interior.has_method("get_kind") and str(_interior.get_kind()) == "ship":
		var near_seat := false
		if _interior.has_method("is_near_seat") and player != null:
			near_seat = bool(_interior.is_near_seat(player, 3.8))
		if near_seat and _try_seat_to_pilot():
			return true
	if _try_hatch_exit():
		return true
	if _interior.has_method("get_kind") and str(_interior.get_kind()) == "ship":
		_toast_hud("AIRLOCK · walk to hatch [F/I] · F seat")
	else:
		_toast_hud("F seat · F/I hatch")
	return true


func _try_hatch_exit() -> bool:
	if _interior == null or not is_instance_valid(_interior):
		return false
	if not _interior.has_method("is_inside") or not bool(_interior.is_inside()):
		return false
	if player == null or not is_instance_valid(player):
		return false
	if _interior.has_method("is_near_hatch") and not bool(_interior.is_near_hatch(player)):
		return false
	if _interior.has_method("exit_interior"):
		_interior.exit_interior()
		return true
	return false


func _try_deploy_hangar_rover() -> bool:
	## IN-D spawn if hold is empty. IN-E retrieve if CargoHold has a vehicle.
	var c := catalog_carrier()
	if c == null:
		return false
	if c.has_method("stored_vehicle_count") and int(c.stored_vehicle_count()) > 0 and c.has_method("try_retrieve_rover"):
		var retrieved := str(c.try_retrieve_rover())
		if retrieved == "DEPLOYED":
			_toast_hud("Rover on ramp · F board")
			return true
		if retrieved == "ALREADY":
			_toast_hud("Rover already out · F board")
			return false
		if retrieved == "BLOCKED":
			_toast_hud("Rover needs ramp DEPLOYED · land/slow hover")
			return false
		_toast_hud("Retrieve refused")
		return false
	if not c.has_method("try_deploy_rover"):
		return false
	var result := str(c.try_deploy_rover())
	if result == "DEPLOYED":
		_toast_hud("Rover on ramp · F board")
		return true
	if result == "ALREADY":
		_toast_hud("Rover already out · F board")
		return false
	_toast_hud("Rover needs ramp DEPLOYED · land/slow hover")
	return false


func _try_board_nearby_rover() -> bool:
	if _rover_transition:
		return true
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
	var c := catalog_carrier()
	if c != null and c.has_method("get_deployed_rover"):
		var cr: Node3D = c.get_deployed_rover()
		if cr != null and is_instance_valid(cr):
			var dc: float = player.global_position.distance_to(cr.global_position)
			if dc < best_d:
				best = cr
				best_d = dc
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
	_rover_transition = true
	_rover = best
	_in_rover = true
	if _rover.has_method("board"):
		_rover.board(player)
	if floating != null and is_instance_valid(floating) and floating.has_method("set_target"):
		floating.set_target(_rover)
	_bind_soft_net_actor(_rover)
	_rover_transition = false
	print("[OpenSpace] boarded rover")
	return true


func _unboard_rover() -> void:
	if _rover_transition:
		return
	if _rover == null or not is_instance_valid(_rover):
		_in_rover = false
		_rover = null
		return
	_rover_transition = true
	var actor: Node3D = null
	if _rover.has_method("unboard"):
		actor = _rover.unboard()
	_in_rover = false
	if actor and is_instance_valid(actor):
		player = actor
		if player != null and is_instance_valid(player) and player.has_method("set_planet_gravity_provider"):
			player.set_planet_gravity_provider(self)
		if floating != null and is_instance_valid(floating) and floating.has_method("set_target"):
			floating.set_target(player)
		_bind_soft_net_actor(player)
	_rover = null
	_rover_transition = false
	print("[OpenSpace] left rover")


func _try_board_pocket_seat() -> bool:
	## Station ops / hangar carrier / MC-A ship crew. Stays in the same pocket. Not ship pilot.
	if _interior == null or not is_instance_valid(_interior):
		return false
	if not _interior.has_method("is_inside") or not bool(_interior.is_inside()):
		return false
	if _interior.has_method("get_kind"):
		var k := str(_interior.get_kind())
		if k != "station" and k != "hangar_bay" and k != "ship":
			return false
	if player == null or not is_instance_valid(player):
		return false
	if _interior.has_method("is_seated") and bool(_interior.is_seated()):
		return true
	if _interior.has_method("try_board_legal_seat"):
		return bool(_interior.try_board_legal_seat(player))
	return false


func _try_seat_to_pilot() -> bool:
	## Interior seat → pilot. FREE walker only next idle frame (avoids has_method SIGSEGV).
	if _seat_transition:
		return true
	if _interior == null or not is_instance_valid(_interior):
		return false
	if not _interior.has_method("is_inside") or not bool(_interior.is_inside()):
		return false
	if player == null or not is_instance_valid(player):
		return false
	if ship == null or not is_instance_valid(ship):
		return false
	if _interior.has_method("get_kind") and str(_interior.get_kind()) != "ship":
		return false
	var seat_near := false
	if _interior.has_method("is_near_seat"):
		seat_near = bool(_interior.is_near_seat(player, 3.8))
	if not seat_near:
		_toast_hud("Move to PILOT SEAT, then F")
		return false
	_seat_transition = true
	# Freeze walker now — no process, no physics, no groups
	if player != null and is_instance_valid(player):
		if player.has_method("mark_dying"):
			player.mark_dying()
		else:
			player.set_process(false)
			player.set_physics_process(false)
			if player is CollisionObject3D:
				(player as CollisionObject3D).collision_layer = 0
	# Same pad↔flight restore as Space-takeoff (close pocket, chase cam).
	ensure_flight_view()
	_toast_hud("Taking pilot seat…")
	return true


func _finish_seat_to_pilot() -> void:
	## Deferred — SceneTree finished notifications for this frame.
	if ship == null or not is_instance_valid(ship):
		_seat_transition = false
		return
	_safe_free_walker()
	if is_instance_valid(ship) and ship.has_method("set_pilot_active"):
		ship.set_pilot_active(true)
	if is_instance_valid(ship) and ship.has_method("set_hatch_open"):
		ship.set_hatch_open(false)
	elif is_instance_valid(ship):
		var door = ship.get_node_or_null("HatchPoint/HatchDoor")
		if door is MeshInstance3D:
			(door as MeshInstance3D).rotation.y = 0.0
	_seat_transition = false
	_toast_hud("PILOT — WASD fly · F exit · E land")
	print("[OpenSpace] seat→pilot OK (deferred free)")
	var hud = get_tree().get_first_node_in_group("game_hud") if get_tree() else null
	if hud and hud.has_method("bind_player") and ship:
		hud.bind_player(ship)



func _try_store_rover() -> void:
	if _try_store_hangar_rover():
		return
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


func _try_store_hangar_rover() -> bool:
	## IN-E: KEY_7 stores the catalog-carrier rover when it is on the ramp mouth.
	var c := catalog_carrier()
	if c == null or not c.has_method("try_store_rover"):
		return false
	var hangar_r: Node3D = c.get_deployed_rover() if c.has_method("get_deployed_rover") else null
	if hangar_r == null or not is_instance_valid(hangar_r):
		return false
	if _in_rover and _rover == hangar_r:
		_unboard_rover()
	var stored := str(c.try_store_rover())
	if stored == "STORED":
		_toast_hud("Rover stored · hangar hold")
		print("[OpenSpace] Hangar rover stored")
		return true
	if stored == "FAR":
		_toast_hud("Drive onto hangar ramp to store")
		return true
	if stored == "BLOCKED":
		_toast_hud("Ramp BLOCKED · cannot store")
		return true
	if stored == "FULL":
		_toast_hud("Hangar hold full")
		return true
	return false


func _toggle_interior() -> void:
	var actor: Node3D = player if player and is_instance_valid(player) else null
	# From pilot: leave the seat into the pocket. No hatch hop, no fake doors.
	if actor == null and ship and _in_ship and is_instance_valid(ship):
		_leave_seat_to_pocket()
		return
	if actor == null:
		return
	if _interior and _interior.has_method("try_toggle"):
		_interior.try_toggle(actor, ship)


func _leave_seat_to_pocket() -> void:
	if _seat_transition:
		return
	if not _in_ship or ship == null or not is_instance_valid(ship):
		return
	if _interior != null and is_instance_valid(_interior) and _interior.has_method("is_inside") and bool(_interior.is_inside()):
		return
	_in_ship = false
	_eva_mode = false
	if ship.has_method("set_pilot_active"):
		ship.set_pilot_active(false)
	player = _make_fallback_player()
	player.set("interior_mode", true)
	add_child(player)
	if player.has_method("_bind_hud"):
		player._bind_hud()
	if _interior != null and is_instance_valid(_interior) and _interior.has_method("enter_ship"):
		_interior.enter_ship(player, ship)
	commit_presence("pocket")
	_toast_hud("Left seat — pocket · F seat · F/I airlock")
	print("[OpenSpace] seat→pocket")


func place_from_ship_pocket(walker: Node3D) -> void:
	## Hatch is a real exit: EVA (zero-G) in flight, pad walk when landed.
	if walker == null or not is_instance_valid(walker) or ship == null or not is_instance_valid(ship):
		return
	player = walker
	_in_ship = false
	var landed := bool(ship.get("is_landed"))
	_eva_mode = not landed
	if walker.has_method("set_planet_gravity_provider"):
		walker.set_planet_gravity_provider(self)
	if landed:
		# Same outdoor pad-deck snap as F-from-LANDED. Do not keep the pocket.
		if walker.has_method("set_meta"):
			walker.set_meta("skip_ready_snap", true)
		if not _place_walker_on_land_deck(walker):
			## Dirt land has no occupied pad. Same as F-EVA: beside hull, not nearest pad.
			var pad_up := Vector3.UP
			var pl = nearest_planet(ship.global_position)
			if pl and is_instance_valid(pl):
				pad_up = (ship.global_position - pl.global_position).normalized()
			var side: Vector3 = ship.global_transform.basis.x
			side = (side - pad_up * side.dot(pad_up))
			if side.length_squared() < 0.01:
				side = pad_up.cross(Vector3.RIGHT)
			if side.length_squared() > 0.01:
				side = side.normalized()
			walker.global_position = ship.global_position + pad_up * 3.2 + side * 11.0
			if walker is CharacterBody3D:
				(walker as CharacterBody3D).velocity = Vector3.ZERO
			if walker.has_method("set_eva_profile"):
				walker.set_eva_profile(false)
			var nose_p: Vector3 = -ship.global_transform.basis.z
			nose_p = nose_p - pad_up * nose_p.dot(pad_up)
			if nose_p.length_squared() < 0.01:
				nose_p = -ship.global_transform.basis.x
				nose_p = nose_p - pad_up * nose_p.dot(pad_up)
			if nose_p.length_squared() > 0.01:
				nose_p = nose_p.normalized()
			if walker.has_method("set_spawn_facing"):
				walker.set_spawn_facing(pad_up, nose_p)
			elif walker.has_method("set_spawn_basis"):
				walker.set_spawn_basis(pad_up, atan2(-nose_p.x, -nose_p.z))
			if walker.has_method("snap_to_surface"):
				walker.snap_to_surface()
			if walker.has_method("set_eva_profile"):
				walker.set_eva_profile(false)
			if walker.has_method("set_interior_mode"):
				walker.set_interior_mode(false)
			elif "interior_mode" in walker:
				walker.interior_mode = false
			walker.set("_spawn_grace_t", 0.0)
			if walker.has_method("_update_up"):
				walker._update_up()
			if walker.has_method("_relief_slope_rad") and "last_slope_ang" in walker:
				walker.set("last_slope_ang", float(walker.call("_relief_slope_rad")))
			if walker.has_method("set_spawn_facing") and nose_p.length_squared() > 0.01:
				walker.set_spawn_facing(pad_up, nose_p)
			if has_method("_schedule_surface_settle"):
				_schedule_surface_settle()
			_apply_dirt_exit_facing()
			walker.set("_spawn_grace_t", 0.0)
			if walker.has_method("_update_up"):
				walker._update_up()
			if walker.has_method("_relief_slope_rad") and "last_slope_ang" in walker:
				walker.set("last_slope_ang", float(walker.call("_relief_slope_rad")))
			if walker.has_method("_bind_hud"):
				walker._bind_hud()
			print("[OpenSpace] hatch dirt exit at ", walker.global_position, " up=", pad_up)
			_toast_hud("Hatch → EVA")
		else:
			_toast_hud("Hatch → pad")
	else:
		var hatch: Node3D = ship.get_node_or_null("HatchPoint") as Node3D
		var side_e: Vector3 = ship.global_transform.basis.x
		var up_e: Vector3 = ship.global_transform.basis.y
		var aft_e: Vector3 = ship.global_transform.basis.z
		if hatch:
			walker.global_position = hatch.global_position + side_e * 2.2 + up_e * 0.4 + aft_e * 0.5
		else:
			walker.global_position = ship.global_position + side_e * 4.5 + up_e * 1.4
		walker.set("eva_mode", true)
		walker.set("zero_g", true)
		if walker.has_method("set_eva_profile"):
			walker.set_eva_profile(true)
		var nose_e: Vector3 = -ship.global_transform.basis.z
		if walker.has_method("set_spawn_facing"):
			walker.set_spawn_facing(up_e, nose_e)
		elif walker.has_method("set_spawn_basis"):
			walker.set_spawn_basis(up_e, atan2(-nose_e.x, -nose_e.z))
		if walker is CharacterBody3D and "velocity" in ship and ship.velocity is Vector3:
			(walker as CharacterBody3D).velocity = (ship.velocity as Vector3) * 0.9
		if ship.has_method("set_hatch_open"):
			ship.set_hatch_open(true)
		_toast_hud("Hatch → EVA zero-G")
	if floating != null and is_instance_valid(floating) and floating.has_method("set_target"):
		floating.set_target(walker)
	for pl2 in planets:
		if pl2 and is_instance_valid(pl2) and pl2.has_method("set_observer"):
			pl2.set_observer(walker)
	_set_planet_observers(walker)
	_bind_soft_net_actor(walker)
	commit_presence("walker" if landed else "eva")
	print("[OpenSpace] pocket→", "EVA 0G" if not landed else "pad")


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
	# Dual-theme ship modules + the same HF-A kit on the seated hull (HF-B).
	if ship and ship.has_method("apply_faction_modules"):
		ship.apply_faction_modules(GameManager.get_faction_name())
	if ship:
		var ship_ab = ship.get_node_or_null("AbilitySystem")
		if ship_ab != null and ship_ab.has_method("setup_default_loadout"):
			ship_ab.setup_default_loadout(GameManager.get_faction_name())
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
		e.ambient_light_color = Color(0.12, 0.16, 0.22)
		e.ambient_light_energy = 0.55
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



func _on_origin_rebased(_offset: Vector3) -> void:
	for pl in planets:
		if pl == null or not is_instance_valid(pl):
			continue
		var sd: Node = pl.get_node_or_null("SurfaceDetail")
		if sd != null and sd.has_method("refresh_all_xforms"):
			sd.refresh_all_xforms()


func _toast_hud(msg: String, ttl: float = 2.2) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("game_hud"):
		if n.has_method("push_toast"):
			n.push_toast(msg, ttl)
			return
	print("[OpenSpace] ", msg)


func _safe_free_walker() -> void:
	## Null refs first, mark dying, detach, free next frame only.
	var old: Node = player
	player = null
	if SoftNetSession != null and SoftNetSession.has_method("bind_player"):
		# Keep ship binding if already piloting — only clear if still walker
		pass
	if SoftScanCache != null and SoftScanCache.has_method("invalidate_player"):
		SoftScanCache.invalidate_player()
	if old == null:
		return
	if not is_instance_valid(old):
		return
	if old.has_method("mark_dying"):
		old.mark_dying()
	else:
		old.set_process(false)
		old.set_physics_process(false)
		old.set_process_input(false)
		old.set_process_unhandled_input(false)
		if old is CollisionObject3D:
			(old as CollisionObject3D).collision_layer = 0
			(old as CollisionObject3D).collision_mask = 0
		if old.is_in_group("player"):
			old.remove_from_group("player")
	var wcam: Camera3D = old.get_node_or_null("CamPivot/Camera3D") as Camera3D
	if wcam == null and "camera" in old:
		wcam = old.camera as Camera3D
	if wcam != null and wcam.current:
		wcam.clear_current(false)
	if old is CanvasItem:
		pass
	if old is Node3D:
		(old as Node3D).visible = false
	var par := old.get_parent()
	if par != null and is_instance_valid(par):
		par.remove_child(old)
	# Free next frame so current notification stack cannot touch it
	old.call_deferred("queue_free")



func _apply_openspace_perf() -> void:
	## Space view: kill expensive post-FX; omni shadows already off on pads.
	var gq := get_node_or_null("/root/GraphicsQuality")
	var tier := int(gq.tier) if gq else 1
	var we := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we == null:
		we = find_child("WorldEnvironment", true, false) as WorldEnvironment
	if we and we.environment:
		var e := we.environment
		e.ssao_enabled = (tier >= 2 and bool(gq.ssao)) if gq else false
		e.ssil_enabled = tier >= 3
		e.sdfgi_enabled = false
		e.volumetric_fog_enabled = false
		e.glow_enabled = tier >= 2
		if tier <= 1:
			e.glow_intensity = 0.0
			e.glow_bloom = 0.0
		if not _interior_view:
			e.fog_enabled = tier >= 1  # altitude fog script may still tint
	print("[OpenSpace] perf tier=", tier)



func _park_far_planets() -> void:
	## Only nearest planet runs full surface systems; far planets = impostor + no process.
	if _interior_view:
		return
	var obs: Node3D = null
	if _in_ship and ship and is_instance_valid(ship):
		obs = ship
	elif player and is_instance_valid(player):
		obs = player
	if obs == null:
		return
	var best: Node3D = null
	var best_d := 1.0e18
	for pl in planets:
		if pl == null or not is_instance_valid(pl):
			continue
		var d: float = obs.global_position.distance_to(pl.global_position)
		if d < best_d:
			best_d = d
			best = pl
	for pl in planets:
		if pl == null or not is_instance_valid(pl):
			continue
		var d: float = obs.global_position.distance_to(pl.global_position)
		var near: bool = (pl == best) or (d < 4500.0)
		# Far: stop process entirely (LOD visual freezes on last impostor — OK at distance)
		if pl.has_method("set_process"):
			pl.set_process(near)
		if not near:
			# Unload live meshes, not just hide (baseline RSS). "Pads" is in the
			# list because its controllers poll input and scan groups forever.
			for nm in ["SurfaceDetail", "SurfaceFlora", "SurfaceFauna", "SurfaceWater", "CaveMouthField", "LandscapeFeatures", "CaveInterior", "Pads"]:
				var n = pl.get_node_or_null(nm)
				if n == null:
					continue
				n.set_process(false)
				if n.has_method("_park_all"):
					n.call("_park_all")
				n.visible = false
		else:
			for nm2 in ["SurfaceDetail", "SurfaceFlora", "SurfaceFauna", "SurfaceWater", "CaveMouthField", "LandscapeFeatures", "CaveInterior", "Pads"]:
				var n2 = pl.get_node_or_null(nm2)
				if n2:
					n2.set_process(true)
					n2.visible = true



func _schedule_surface_settle() -> void:
	## Snap walker to pad/terrain after F exit — aborted if interior_mode.
	if player == null or not is_instance_valid(player):
		return
	var pl_g: Node3D = nearest_planet(player.global_position)
	if pl_g != null and is_instance_valid(pl_g) and pl_g.has_method("force_surface_collision_at"):
		pl_g.force_surface_collision_at(player.global_position)
	if player != null and is_instance_valid(player) and player.has_method("snap_to_surface"):
		player.call_deferred("snap_to_surface")
	var tree := get_tree()
	if tree == null:
		return
	tree.create_timer(0.08).timeout.connect(_surface_settle_tick.bind(1))
	tree.create_timer(0.20).timeout.connect(_surface_settle_tick.bind(2))


func _surface_settle_tick(stage: int) -> void:
	if player == null or not is_instance_valid(player):
		player = null
		return
	if "interior_mode" in player and bool(player.interior_mode):
		return
	if _interior != null and is_instance_valid(_interior) and _interior.has_method("is_inside") and bool(_interior.is_inside()):
		return
	var pad: Node3D = nearest_pad(player.global_position)
	if pad != null and player.global_position.distance_to(pad.global_position) <= 20.0 \
			and player.has_method("snap_to_pad"):
		_call_if(player, &"snap_to_pad", [pad])
		return
	if stage <= 1:
		_call_if(player, &"snap_to_surface")
	else:
		_call_if(player, &"safe_unground")
		if "interior_mode" in player and not bool(player.interior_mode):
			player.set("_spawn_grace_t", 0.0)
	_apply_dirt_exit_facing()


func _apply_dirt_exit_facing() -> void:
	## Deferred snap can twist the body. Dirt F-EVA stays hull-nose tangent.
	if player == null or not is_instance_valid(player) or ship == null or not is_instance_valid(ship):
		return
	if _in_ship:
		return
	if "interior_mode" in player and bool(player.interior_mode):
		return
	if "eva_mode" in player and bool(player.eva_mode) \
			and "zero_g" in player and bool(player.zero_g):
		return
	if _land_eva_pad() != null:
		return
	var pl = nearest_planet(player.global_position)
	if pl == null or not is_instance_valid(pl):
		return
	var pad_up: Vector3 = (player.global_position - pl.global_position).normalized()
	var nose: Vector3 = -ship.global_transform.basis.z
	nose = nose - pad_up * nose.dot(pad_up)
	if nose.length_squared() < 0.01:
		nose = -ship.global_transform.basis.x
		nose = nose - pad_up * nose.dot(pad_up)
	if nose.length_squared() < 0.01:
		return
	nose = nose.normalized()
	if player.has_method("set_spawn_facing"):
		player.set_spawn_facing(pad_up, nose)
	if player.has_method("_update_up"):
		player._update_up()
	player.set("_spawn_grace_t", 0.0)
	if player.has_method("_relief_slope_rad") and "last_slope_ang" in player:
		player.set("last_slope_ang", float(player.call("_relief_slope_rad")))



func _node_alive(n: Object) -> bool:
	return n != null and is_instance_valid(n)


func _call_if(n: Object, method: StringName, args: Array = []) -> void:
	## Safe has_method + call — never SIGSEGV on freed objects.
	if n == null or not is_instance_valid(n):
		return
	if not n.has_method(method):
		return
	n.callv(method, args)
