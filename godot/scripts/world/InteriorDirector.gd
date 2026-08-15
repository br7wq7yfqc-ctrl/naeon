extends Node
class_name InteriorDirector
## Enter/exit station or ship interiors (procedural pockets).
## Pocket is parented under OpenSpace (NOT WorldRoot) so FloatingOrigin cannot
## yank the room away from the player. Deferred surface snaps are cancelled.

signal entered(kind: String)
signal exited(kind: String)

const _Gen = preload("res://scripts/world/InteriorGenerator.gd")
## Pocket is parented under OpenSpace (NOT WorldRoot). Nex-Prime sits at
## origin with radius 1400 — y=120 was inside the planet mesh.
const POCKET_LOCAL := Vector3(0.0, 9200.0, 0.0)

var _root: Node3D  ## WorldRoot (legacy; not used for pocket parent)
var _active: Node3D
var _kind: String = ""
var _return_pos: Vector3 = Vector3.ZERO
var _return_up: Vector3 = Vector3.UP
var _player: Node3D
var _open_space: Node
var _inside: bool = false
var _exit_hint_t: float = 0.0
var _player_was_parent: Node = null
var _sealed: bool = true
var _atmo: float = 1.0
var _recycler_on: bool = true
var _console_cd: float = 0.0
var _console_hint_t: float = 0.0


func setup(world_root: Node3D, open_space: Node) -> void:
	add_to_group("interior_director")
	_root = world_root
	_open_space = open_space


func is_inside() -> bool:
	return _inside


func get_kind() -> String:
	return _kind


func get_active_interior() -> Node3D:
	return _active


func get_atmo() -> float:
	return _atmo if _inside else 1.0


func is_sealed() -> bool:
	return _sealed


func recycler_on() -> bool:
	return _recycler_on


func life_support_line() -> String:
	if not _inside:
		return ""
	var bus := "POWER BUS STABLE" if _recycler_on else "POWER IDLE · VENTED"
	if _kind == "ship":
		return "HULL SEALED · ATMO %.2f · %s" % [_atmo, bus]
	if _atmo >= 0.72:
		return "LIFE SUPPORT OK · ATMO %.2f · %s" % [_atmo, bus]
	if _atmo >= 0.25:
		return "LIFE SUPPORT MARGINAL · ATMO %.2f · SUIT READY · %s" % [_atmo, bus]
	return "SUIT REQUIRED · ATMO %.2f · %s" % [_atmo, bus]


func try_toggle(player: Node3D, ship: Node3D = null) -> void:
	if _inside:
		exit_interior()
		return
	if player == null or not is_instance_valid(player):
		_toast("No walker")
		return
	# Prefer station if near pad
	if _open_space and _open_space.has_method("nearest_pad"):
		var pad: Node3D = _open_space.nearest_pad(player.global_position)
		if pad and is_instance_valid(pad) and player.global_position.distance_to(pad.global_position) < 45.0:
			enter_station(player, pad)
			return
	# Ship interior if near ship
	if ship and is_instance_valid(ship):
		var sd: float = player.global_position.distance_to(ship.global_position)
		if sd < 48.0:
			enter_ship(player, ship)
			return
		print("[Interior] Too far from ship (", int(sd), "m)")
		_toast("Closer to ship for interior")
		return
	print("[Interior] Nothing to enter (near pad or ship)")
	_toast("Near pad or ship, then I")


func enter_station(player: Node3D, pad: Node3D) -> void:
	var fac := "Cybernex"
	if pad.has_meta("base_faction"):
		fac = str(pad.get_meta("base_faction"))
	elif GameManager:
		fac = GameManager.get_faction_name()
	var up: Vector3 = pad.get_meta("pad_up") if pad.has_meta("pad_up") else Vector3.UP
	_begin(player, "station", _Gen.build_station(fac), pad.global_position, up)


func enter_ship(player: Node3D, ship: Node3D) -> void:
	var fac := "Cybernex"
	if ship.get("faction") != null:
		fac = str(ship.faction)
	var pid := "scout_single"
	if ship.has_method("get_interior_profile_id"):
		pid = str(ship.get_interior_profile_id())
	var interior: Node3D = _Gen.build_from_profile(pid, fac)
	if interior == null:
		# Fallback simple ship pocket
		interior = _Gen.build_ship(fac)
	if interior == null:
		print("[Interior] build failed ", pid)
		_toast("Interior build failed")
		return
	print("[Interior] building ship pocket ", pid)
	var up := Vector3.UP
	if _open_space and _open_space.has_method("nearest_planet"):
		var pl: Node3D = _open_space.nearest_planet(ship.global_position)
		if pl and is_instance_valid(pl):
			up = (ship.global_position - pl.global_position).normalized()
	_begin(player, "ship", interior, ship.global_position, up)


func _begin(player: Node3D, kind: String, interior: Node3D, ret_pos: Vector3, ret_up: Vector3) -> void:
	if interior == null or player == null or not is_instance_valid(player):
		return
	# Tear down previous pocket
	if _active and is_instance_valid(_active):
		_active.queue_free()
		_active = null

	_kind = kind
	_player = player
	_console_cd = 0.0
	_console_hint_t = 0.0
	if kind == "station":
		_recycler_on = true
	else:
		_recycler_on = true
	_return_up = ret_up.normalized() if ret_up.length_squared() > 0.01 else Vector3.UP
	_return_pos = ret_pos + _return_up * 4.0
	_active = interior

	# Parent under OpenSpace (scene root), NOT WorldRoot — FloatingOrigin only shifts WorldRoot.
	var host: Node = _open_space if _open_space else _root
	if host == null:
		print("[Interior] no host")
		return
	host.add_child(_active)
	# Fixed local pocket — stable, near camera origin of OpenSpace
	if _active is Node3D:
		(_active as Node3D).position = POCKET_LOCAL
		(_active as Node3D).rotation = Vector3.ZERO
	# Walker + TPS camera live under WorldRoot. Hide the planet only after
	# the camera is parented out, or the interior is a black frame.
	_host_player_outside_world()
	_set_world_hidden(true)

	# Cancel any pending surface snap / exterior physics on walker
	if player != null and is_instance_valid(player) and player.has_method("set_interior_mode"):
		player.set_interior_mode(true)
	elif "interior_mode" in player:
		player.interior_mode = true
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
		(player as CharacterBody3D).floor_snap_length = 0.5

	# Zero vertical velocity + flat gravity BEFORE teleport
	if player != null and is_instance_valid(player) and player.has_method("set_planet_gravity_provider"):
		player.set_planet_gravity_provider(self)
	if player != null and is_instance_valid(player) and player.has_method("set_spawn_basis"):
		player.set_spawn_basis(Vector3.UP, PI)
	if player != null and is_instance_valid(player) and player.has_method("set_eva_profile"):
		player.set_eva_profile(false)

	# Place on spawn marker (floor + clearance)
	var spawn: Node3D = _active.get_node_or_null("Spawn") as Node3D
	var target: Vector3
	if spawn:
		# Force update transforms
		_active.force_update_transform()
		spawn.force_update_transform()
		target = spawn.global_position
	else:
		target = (_active as Node3D).global_position + Vector3(0, 1.2, 0)
	# Safety: never leave player below floor of pocket
	var floor_y: float = (_active as Node3D).global_position.y + 0.3
	if target.y < floor_y + 0.9:
		target.y = floor_y + 1.15
	player.global_position = target
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO

	# Pause floating origin while inside (prevents void rebase)
	if _open_space and _open_space.get("floating") != null:
		var fo = _open_space.floating
		if fo != null and is_instance_valid(fo) and fo.has_method("set_target"):
			fo.set_target(null)
		if fo != null and is_instance_valid(fo) and fo.has_method("set_process"):
			fo.set_process(false)
		if fo != null and is_instance_valid(fo) and fo.has_method("set_physics_process"):
			fo.set_physics_process(false)

	_inside = true
	_recycler_on = true
	_sealed = kind == "ship"
	_refresh_life_support()
	if LayerContext:
		LayerContext.current_layer = "ship_int" if kind == "ship" else "station"
		if "seamless_stage" in LayerContext:
			LayerContext.seamless_stage = "interior"
	_hatch_fx(true)
	entered.emit(kind)
	if kind == "ship":
		_toast("Entered ship · I hatch · F seat · E console")
	else:
		_toast("Entered station · I exit · E ops console")
	print("[Interior] entered ", kind, " at ", target, " atmo=", snapped(_atmo, 0.01))
	set_process(true)

	# Deferred floor settle (same-frame collision may not be ready)
	call_deferred("_settle_player_on_floor")
	if AudioDirector and AudioDirector.has_method("play_interior_enter"):
		AudioDirector.play_interior_enter()


func _settle_player_on_floor() -> void:
	if not _inside or _player == null or not is_instance_valid(_player) or _active == null:
		return
	if not is_instance_valid(_active):
		return
	var space = _player.get_world_3d().direct_space_state if _player.get_world_3d() else null
	if space == null:
		_player.global_position = _active.global_position + Vector3(0, 1.2, 0)
		return
	var origin: Vector3 = _player.global_position + Vector3(0, 8, 0)
	var end: Vector3 = _player.global_position + Vector3(0, -20, 0)
	var q := PhysicsRayQueryParameters3D.create(origin, end)
	q.collision_mask = 1
	q.exclude = [_player.get_rid()]
	var hit := space.intersect_ray(q)
	if hit:
		_player.global_position = hit.position + Vector3(0, 1.05, 0)
		print("[Interior] settled on floor ", hit.position)
	else:
		# Hard place above pocket origin (thick safety floor is at y~0 local)
		_player.global_position = _active.global_position + Vector3(0, 1.25, 0)
		print("[Interior] no floor ray — hard place")
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO
	if _player != null and is_instance_valid(_player) and _player.has_method("set_spawn_basis"):
		_player.set_spawn_basis(Vector3.UP, PI)


func gravity_at(_global_pos: Vector3) -> Vector3:
	## Flat down — Y-up interior (never radial planet gravity). Slightly snappier than surface 14.
	return Vector3(0, -16.0, 0)


func _set_world_hidden(hidden: bool) -> void:
	## Pocket must not sit inside Nex-Prime or inherit surface fog.
	if _root and is_instance_valid(_root):
		_root.visible = not hidden
	if _open_space and _open_space.has_method("set_interior_view"):
		_open_space.set_interior_view(hidden)


func _host_player_outside_world() -> void:
	## Keep walker+camera as a sibling of WorldRoot so hiding the planet
	## does not hide the TPS camera (black void).
	if _player == null or not is_instance_valid(_player):
		return
	var dest: Node = _open_space if _open_space else _active
	if dest == null or not is_instance_valid(dest):
		return
	if _player.get_parent() == dest:
		return
	_player_was_parent = _player.get_parent()
	_player.reparent(dest, true)
	_make_player_camera_current()


func _restore_player_parent() -> void:
	if _player == null or not is_instance_valid(_player):
		_player_was_parent = null
		return
	var dest: Node = _player_was_parent
	_player_was_parent = null
	if dest == null or not is_instance_valid(dest):
		dest = _root
	if dest == null or not is_instance_valid(dest):
		return
	if _player.get_parent() == dest:
		return
	_player.reparent(dest, true)


func _make_player_camera_current() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var cam: Camera3D = _player.get_node_or_null("CamPivot/Camera3D") as Camera3D
	if cam == null and "camera" in _player:
		cam = _player.camera as Camera3D
	if cam:
		cam.current = true


func exit_interior() -> void:
	if not _inside:
		return
	_hatch_fx(false)
	if _player and is_instance_valid(_player):
		if _player != null and is_instance_valid(_player) and _player.has_method("set_interior_mode"):
			_player.set_interior_mode(false)
		elif "interior_mode" in _player:
			_player.interior_mode = false
		# Restore exterior gravity + place on pad/ship return
		if _player != null and is_instance_valid(_player) and _player.has_method("set_planet_gravity_provider") and _open_space:
			_player.set_planet_gravity_provider(_open_space)
		if _player != null and is_instance_valid(_player) and _player.has_method("set_spawn_basis"):
			_player.set_spawn_basis(_return_up, 0.0)
		# Must leave the pocket before queue_free, or the walker is freed with it.
		_restore_player_parent()
		_player.global_position = _return_pos
		if _player is CharacterBody3D:
			(_player as CharacterBody3D).velocity = Vector3.ZERO
		# Snap only AFTER exterior gravity restored
		if _player != null and is_instance_valid(_player) and _player.has_method("snap_to_surface"):
			_player.call_deferred("snap_to_surface")
	if _active and is_instance_valid(_active):
		_active.queue_free()
	_active = null
	_inside = false

	_set_world_hidden(false)
	# Resume floating origin on walker/ship
	if _open_space:
		var fo = _open_space.get("floating")
		if fo:
			if fo.has_method("set_physics_process"):
				fo.set_physics_process(true)
			if fo.has_method("set_process"):
				fo.set_process(true)
			if fo.has_method("set_target"):
				var tgt: Node3D = null
				if _open_space.get("player") and is_instance_valid(_open_space.player):
					tgt = _open_space.player
				elif _open_space.get("ship") and is_instance_valid(_open_space.ship):
					tgt = _open_space.ship
				if tgt:
					fo.set_target(tgt)

	if LayerContext:
		LayerContext.current_layer = "surface" if _kind != "ship" else "space"
		if "seamless_stage" in LayerContext:
			LayerContext.seamless_stage = "world"
	exited.emit(_kind)
	_toast("Exited interior")
	print("[Interior] exited ", _kind)
	_kind = ""
	set_process(false)


func _toast(msg: String) -> void:
	if GameManager and GameManager.has_signal("toast_requested"):
		GameManager.toast_requested.emit(msg)
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("game_hud"):
		if n.has_method("push_toast"):
			n.push_toast(msg, 2.5)
			return


func _hatch_fx(entering: bool) -> void:
	if _open_space == null:
		return
	var ship = null
	if "ship" in _open_space:
		ship = _open_space.ship
	if ship == null or not is_instance_valid(ship):
		return
	if ship.has_method("set_hatch_open"):
		ship.set_hatch_open(entering)
		return
	var door = ship.get_node_or_null("HatchPoint/HatchDoor")
	if door is MeshInstance3D:
		(door as MeshInstance3D).visible = entering
		(door as MeshInstance3D).rotation.y = deg_to_rad(75.0) if entering else 0.0


func is_near_seat(player: Node3D, max_dist: float = 3.6) -> bool:
	if _kind != "ship":
		return false
	if player == null or not is_instance_valid(player) or not _inside or _active == null:
		return false
	if not is_instance_valid(_active):
		return false
	for nm in ["SeatVolume", "Seat"]:
		var n: Node = _active.get_node_or_null(nm)
		if n is Node3D:
			if player.global_position.distance_to((n as Node3D).global_position) <= max_dist:
				return true
	return false


func is_near_console(player: Node3D, max_dist: float = 3.4) -> bool:
	if player == null or not is_instance_valid(player) or not _inside or _active == null:
		return false
	if not is_instance_valid(_active):
		return false
	var n: Node = _active.get_node_or_null("ConsoleVolume")
	if n is Node3D:
		return player.global_position.distance_to((n as Node3D).global_position) <= max_dist
	return false


func try_use_console() -> bool:
	if not _inside or _player == null or not is_instance_valid(_player):
		return false
	if not is_near_console(_player):
		return false
	if _console_cd > 0.0:
		return false
	_console_cd = 0.5
	_refresh_life_support()
	if _kind == "station":
		_recycler_on = not _recycler_on
		_refresh_life_support()
		var rec := "HABITAT SEALED" if _recycler_on else "VENTED TO PLANET"
		_toast("%s · ATMO %.2f · %s" % [rec, _atmo, _pad_status_line()])
	else:
		_toast("COCKPIT · %s · F seat · I hatch" % life_support_line())
	if AudioDirector and AudioDirector.has_method("play_ui"):
		AudioDirector.play_ui()
	return true


func exit_for_pilot() -> void:
	if not _inside:
		return
	_hatch_fx(false)
	# Walker will be freed by OpenSpace — do not call methods that re-enable process
	if _player != null and is_instance_valid(_player):
		if _player.has_method("mark_dying"):
			_player.mark_dying()
		elif _player.has_method("set_interior_mode"):
			_player.set_interior_mode(false)
	_restore_player_parent()
	if _active and is_instance_valid(_active):
		_active.queue_free()
	_active = null
	_inside = false
	_player = null
	_set_world_hidden(false)
	if _open_space:
		var fo = _open_space.get("floating")
		if fo != null and is_instance_valid(fo) and fo.has_method("set_physics_process"):
			fo.set_physics_process(true)
	if LayerContext:
		LayerContext.current_layer = "Space"
		if "seamless_stage" in LayerContext:
			LayerContext.seamless_stage = "world"
	exited.emit("ship_to_pilot")
	print("[Interior] exit_for_pilot")
	_kind = ""
	set_process(false)


func _process(delta: float) -> void:
	if not _inside or _player == null or not is_instance_valid(_player) or _active == null:
		return
	if not is_instance_valid(_active):
		return
	_console_cd = maxf(0.0, _console_cd - delta)
	_refresh_life_support()
	_tick_doors(delta)
	# Keep player from falling out of pocket bounds
	var anchor: Vector3 = _active.global_position
	var ppos: Vector3 = _player.global_position
	if ppos.y < anchor.y - 5.0 or ppos.distance_to(anchor) > 80.0:
		print("[Interior] rescue void fall")
		_player.global_position = anchor + Vector3(0, 1.2, 0)
		if _player is CharacterBody3D:
			(_player as CharacterBody3D).velocity = Vector3.ZERO

	var near_seat := is_near_seat(_player, 3.6)
	var lab = _active.get_node_or_null("SeatLabel")
	if lab is Label3D:
		(lab as Label3D).modulate.a = 1.0 if near_seat else 0.55
		(lab as Label3D).text = "PILOT SEAT · F" if near_seat else "PILOT SEAT"
		(lab as Label3D).font_size = 56 if near_seat else 42
	var seat_n = _active.get_node_or_null("SeatGlow")
	if seat_n is MeshInstance3D:
		(seat_n as MeshInstance3D).visible = near_seat
	var clab = _active.get_node_or_null("ConsoleLabel")
	if clab is Label3D:
		var near_c := is_near_console(_player)
		(clab as Label3D).modulate.a = 1.0 if near_c else 0.5
		(clab as Label3D).text = "OPS CONSOLE · E" if near_c else "OPS CONSOLE"
	if is_near_console(_player):
		_console_hint_t += delta
		if _console_hint_t > 1.1:
			_console_hint_t = -2.4
			_toast("E — ops console")
	else:
		_console_hint_t = maxf(0.0, _console_hint_t - delta)
	var exit_v = _active.get_node_or_null("ExitVolume")
	if exit_v is Node3D:
		var d: float = _player.global_position.distance_to((exit_v as Node3D).global_position)
		if d < 2.2:
			_exit_hint_t += delta
			if _exit_hint_t > 0.6:
				_exit_hint_t = -2.0
				_toast("HATCH — press I to exit")
		else:
			_exit_hint_t = maxf(0.0, _exit_hint_t - delta)


func _refresh_life_support() -> void:
	if not _inside:
		_atmo = 1.0
		_sealed = true
		return
	if _kind == "ship":
		_sealed = true
		_atmo = 1.0
		return
	var planet := 0.0
	if _open_space and _open_space.has_method("atmosphere_density_at"):
		planet = float(_open_space.atmosphere_density_at(_return_pos))
	if _recycler_on:
		_atmo = clampf(maxf(0.88, planet), 0.0, 1.0)
		_sealed = true
	else:
		_atmo = clampf(planet, 0.0, 1.0)
		_sealed = _atmo >= 0.72


func _pad_status_line() -> String:
	if _open_space == null or not _open_space.has_method("nearest_pad"):
		return "no pad link"
	var pad: Node3D = _open_space.nearest_pad(_return_pos)
	if pad == null or not is_instance_valid(pad):
		return "no pad link"
	var fac := "?"
	var st := ""
	var cs := 0.0
	if pad.has_method("get_faction"):
		fac = str(pad.get_faction())
	if pad.get("ownership") != null and pad.ownership:
		cs = float(pad.ownership.claim_strength)
	if pad.has_method("get_claim_status"):
		st = str(pad.get_claim_status())
	return "PAD %s %s claim %.0f%%" % [fac, st, clampf(cs / 1.75, 0.0, 1.0) * 100.0]


func _tick_doors(delta: float) -> void:
	if _active == null or _player == null:
		return
	for n in _active.get_children():
		if not (n is Node3D):
			continue
		if not str(n.name).begins_with("DoorPortal"):
			continue
		var slab: Node3D = n.get_node_or_null("Slab") as Node3D
		if slab == null:
			continue
		var near := _player.global_position.distance_to((n as Node3D).global_position) < 3.2
		var target_x := 1.55 if near else 0.0
		slab.position.x = move_toward(slab.position.x, target_x, delta * 3.4)
		# Open slab must not block the hall — collision rides the mesh otherwise.
		var blocking := slab.position.x < 0.85
		for c in slab.get_children():
			if c is CollisionObject3D:
				(c as CollisionObject3D).collision_layer = 1 if blocking else 0
				(c as CollisionObject3D).collision_mask = 1 if blocking else 0
