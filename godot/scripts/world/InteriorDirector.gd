extends Node
class_name InteriorDirector
## Enter/exit station or ship interiors (procedural pockets).
## Pocket is parented under OpenSpace (NOT WorldRoot) so FloatingOrigin cannot
## yank the room away from the player. Deferred surface snaps are cancelled.

signal entered(kind: String)
signal exited(kind: String)

const _Gen = preload("res://scripts/world/InteriorGenerator.gd")
const _Board = preload("res://scripts/systems/ContractBoard.gd")
const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
## Pocket is parented under OpenSpace (NOT WorldRoot). Nex-Prime sits at
## origin with radius 1400 — y=120 was inside the planet mesh.
const POCKET_LOCAL := Vector3(0.0, 9200.0, 0.0)

var _root: Node3D  ## WorldRoot (legacy; not used for pocket parent)
var _active: Node3D
var _kind: String = ""
var _return_pos: Vector3 = Vector3.ZERO
var _return_up: Vector3 = Vector3.UP
var _return_mode: String = "pad"  # pad | dock — hatch must not dump to MainMenu
var _player: Node3D
var _open_space: Node
var _inside: bool = false
var _player_was_parent: Node = null
var _sealed: bool = true
var _atmo: float = 1.0
var _recycler_on: bool = true
var _console_cd: float = 0.0
var _door_hold: Dictionary = {}  # portal name -> remain-open seconds
var _seated: bool = false
var _seat_role: String = ""  # ops | carrier_pilot — never the ship cockpit
var _console_board: Dictionary = {}
var _ls_warn_t: float = 0.0
var _ls_warn_shown: bool = false
var _occupy_host: Node = null  # pad controller for board occupy; never a SITE_*
var _hangar_host: Node = null  # ST-D catalog carrier; hatch may land on a deployed ramp


func setup(world_root: Node3D, open_space: Node) -> void:
	add_to_group("interior_director")
	_root = world_root
	_open_space = open_space


func is_inside() -> bool:
	return _inside


func get_kind() -> String:
	return _kind


func get_return_mode() -> String:
	return _return_mode


func get_active_interior() -> Node3D:
	return _active


func pocket_is_ship() -> bool:
	return _kind == "ship"


func get_atmo() -> float:
	return _atmo if _inside else 1.0


func is_sealed() -> bool:
	return _sealed


func recycler_on() -> bool:
	return _recycler_on


func is_seated() -> bool:
	return _inside and _seated


func get_seat_role() -> String:
	return _seat_role if _seated else ""


func last_console_action() -> Dictionary:
	return _console_board.duplicate()


func try_accept_contract() -> Dictionary:
	## Q-A: accept the offered ops contract. Does not occupy / print / mint SITE_*.
	var cur: Dictionary = _Board.accept()
	_console_board["contract"] = cur
	_console_board["contract_status"] = str(cur.get("status", ""))
	return cur


func try_complete_contract() -> Dictionary:
	## Q-A: complete after template progress. Knowledge label only.
	var cur: Dictionary = _Board.try_complete()
	_console_board["contract"] = cur
	_console_board["contract_status"] = str(cur.get("status", ""))
	return cur


func try_pay_complete_contract(cash: float = 0.0) -> bool:
	return bool(_Board.try_pay_complete(cash))


func try_interact_learning_node() -> Dictionary:
	## Q-C: read pad / extractor / crate intel. Does not harvest / print / mint SITE_*.
	var cur: Dictionary = _Board.interact_learning_node()
	_console_board["learning_node"] = cur.get("node", {})
	_console_board["learning_intel"] = cur.get("intel", {})
	return cur


func try_complete_learning_node() -> Dictionary:
	## Q-C: subject mastery label only. Combat / economy tables stay.
	var cur: Dictionary = _Board.try_complete_learning_node()
	_console_board["learning_node"] = cur.get("learning_node", {})
	_console_board["contract"] = cur
	return cur


func try_accept_alliance_contract() -> Dictionary:
	## Q-B: accept the shared alliance contract. Same board. Not a second quest system.
	var cur: Dictionary = _Board.accept_alliance()
	_console_board["alliance_contract"] = cur
	return cur


func try_complete_alliance_contract() -> Dictionary:
	## Q-B: complete after occupy/logistics progress. Alliance intel label only.
	var cur: Dictionary = _Board.try_complete_alliance()
	_console_board["alliance_contract"] = cur
	return cur


func has_life_support() -> bool:
	## Recycler is the pocket LS. Vented / off = no LS (suit warn, never HP).
	return _inside and _recycler_on


func life_support_warn_shown() -> bool:
	return _ls_warn_shown


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
		if _seated:
			leave_legal_seat()
			return
		if player != null and is_instance_valid(player) and not is_near_hatch(player):
			if _kind == "ship":
				_toast("AIRLOCK · walk to hatch [F/I] · F seat")
			else:
				_toast("HATCH · walk to door [F/I]")
			return
		exit_interior()
		return
	if player == null or not is_instance_valid(player):
		_toast("No walker")
		return
	# IN-A: pad / cluster → station pocket. Carrier → hangar_bay. Not the ship cockpit.
	var pad: Node3D = _nearby_pad(player)
	if pad != null:
		enter_station(player, pad)
		return
	var cluster: Node3D = _nearby_orbital_cluster(player)
	if cluster != null:
		enter_station(player, cluster)
		return
	var carrier: Node3D = _nearby_catalog_carrier(player)
	if carrier != null:
		enter_hangar(player, carrier)
		return
	if ship and is_instance_valid(ship):
		var sd: float = player.global_position.distance_to(ship.global_position)
		if sd < 48.0:
			enter_ship(player, ship)
			return
		print("[Interior] Too far from ship (", int(sd), "m)")
		_toast("Closer to ship for interior")
		return
	print("[Interior] Nothing to enter (near pad, cluster, carrier, or ship)")
	_toast("Near pad, dock, hangar, or ship, then I")


func enter_station(player: Node3D, host: Node3D) -> void:
	if host == null or not is_instance_valid(host):
		return
	var fac := "Cybernex"
	var up := Vector3.UP
	var ret_pos: Vector3 = host.global_position
	var hatch_to := "pad"
	if host.has_meta("base_faction"):
		fac = str(host.get_meta("base_faction"))
	elif host.get("faction") != null and str(host.faction) != "":
		fac = str(host.faction)
	elif GameManager:
		fac = GameManager.get_faction_name()
	if host.has_meta("pad_up"):
		up = host.get_meta("pad_up")
		hatch_to = "pad"
	elif _is_orbital_station_host(host):
		hatch_to = "dock"
		var dock: Node3D = _cluster_dock(host)
		if dock != null:
			ret_pos = dock.global_position
		up = _up_from_planet(host.global_position)
	_begin(player, "station", _Gen.build_station(fac, hatch_to), ret_pos, up, hatch_to)
	if hatch_to == "pad":
		_occupy_host = _claimable_from(host)


func enter_hangar(player: Node3D, carrier: Node3D) -> void:
	## Catalog carrier bay. Not a mobile SITE_*. Not the player-ship cockpit.
	if carrier == null or not is_instance_valid(carrier):
		_toast("No carrier hangar")
		return
	if str(carrier.get_meta("site_pin", "")) != "":
		print("[Interior] refuse hangar on SITE_* carrier")
		_toast("Hangar refuses SITE_*")
		return
	var fac := "Cybernex"
	var slug := ""
	if carrier.get("faction") != null and str(carrier.faction) != "":
		fac = str(carrier.faction)
	if carrier.has_method("hull_slug"):
		slug = str(carrier.hull_slug())
	elif carrier.get("hull_id") != null:
		slug = str(carrier.hull_id)
	if slug.find("grot") >= 0:
		fac = "gROT"
	var up := _up_from_planet(carrier.global_position)
	var interior: Node3D = _Gen.build_hangar_bay(fac)
	if interior == null:
		_toast("Hangar build failed")
		return
	print("[Interior] building hangar_bay pocket hull=", slug)
	_begin(player, "hangar_bay", interior, carrier.global_position, up, "dock")
	_hangar_host = carrier


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


func _begin(player: Node3D, kind: String, interior: Node3D, ret_pos: Vector3, ret_up: Vector3, return_mode: String = "pad") -> void:
	if interior == null or player == null or not is_instance_valid(player):
		return
	# Tear down previous pocket
	if _active and is_instance_valid(_active):
		_active.queue_free()
		_active = null

	_kind = kind
	_player = player
	_console_cd = 0.0
	_door_hold.clear()
	_console_board.clear()
	_seated = false
	_seat_role = ""
	_ls_warn_t = 0.0
	_ls_warn_shown = false
	_occupy_host = null
	_hangar_host = null
	_recycler_on = true
	_return_mode = "dock" if return_mode == "dock" else "pad"
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
	# EVA off first: set_eva_profile overwrites the interior movement profile.
	if player != null and is_instance_valid(player) and player.has_method("set_eva_profile"):
		player.set_eva_profile(false)
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
		_toast("Ship pocket · F seat · walk to airlock [I]")
	elif kind == "hangar_bay":
		_toast("Hangar bay · F carrier seat · E bay · F/I hatch")
	else:
		_toast("Entered station · F ops seat · E console · F/I hatch")
	print("[Interior] entered ", kind, " at ", target, " atmo=", snapped(_atmo, 0.01), " return=", _return_mode)
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
	# The pocket's StaticBody shapes were added this frame; wait for the physics
	# server to commit them or the floor ray finds nothing on a cold entry.
	if get_tree():
		await get_tree().physics_frame
	if not _inside or _player == null or not is_instance_valid(_player) or not is_instance_valid(_active):
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
	var was_ship := _kind == "ship"
	var dest := _return_mode
	var ramp: Node3D = null
	if not was_ship and _kind == "hangar_bay":
		ramp = _deployed_hangar_ramp()
		if ramp != null:
			dest = "ramp"
	_hatch_fx(false)
	if _player and is_instance_valid(_player):
		if _player != null and is_instance_valid(_player) and _player.has_method("set_interior_mode"):
			_player.set_interior_mode(false)
		elif "interior_mode" in _player:
			_player.interior_mode = false
		# Restore exterior gravity + place on pad/ship return
		if _player != null and is_instance_valid(_player) and _player.has_method("set_planet_gravity_provider") and _open_space:
			_player.set_planet_gravity_provider(_open_space)
		_apply_hatch_facing()
		# Must leave the pocket before queue_free, or the walker is freed with it.
		_restore_player_parent()
		var via_hatch := was_ship and _open_space != null and _open_space.has_method("place_from_ship_pocket")
		if not via_hatch:
			if dest == "ramp" and ramp != null and ramp.has_method("walk_mouth_global"):
				_player.global_position = ramp.walk_mouth_global()
			else:
				_player.global_position = _return_pos
			if _player is CharacterBody3D:
				(_player as CharacterBody3D).velocity = Vector3.ZERO
			if dest == "pad":
				# Occupied unnamed pad: grounded walker. Do not snap orbital dock onto dirt.
				if _player != null and is_instance_valid(_player) and _player.has_method("set_eva_profile"):
					_player.set_eva_profile(false)
				if _player != null and is_instance_valid(_player) and _player.has_method("snap_to_surface"):
					_player.call_deferred("snap_to_surface")
			elif dest == "ramp":
				# Hangar mouth → deployed plates. Walk to pad. Same OpenSpace.
				if _player != null and is_instance_valid(_player) and _player.has_method("set_eva_profile"):
					var grounded := _hangar_host != null and _hangar_host.has_method("is_landed") and bool(_hangar_host.is_landed())
					_player.set_eva_profile(not grounded)
			else:
				# Cluster / carrier hatch: stay at dock. Zero-G, same scene.
				if _player != null and is_instance_valid(_player) and _player.has_method("set_eva_profile"):
					_player.set_eva_profile(true)
	if _active and is_instance_valid(_active):
		_active.queue_free()
	_active = null
	_inside = false
	_seated = false
	_seat_role = ""
	_ls_warn_t = 0.0

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
		LayerContext.current_layer = "surface" if not was_ship else "space"
		if "seamless_stage" in LayerContext:
			LayerContext.seamless_stage = "world"
	if was_ship and _open_space != null and _open_space.has_method("place_from_ship_pocket") and _player != null and is_instance_valid(_player):
		_open_space.place_from_ship_pocket(_player)
	exited.emit(_kind)
	if was_ship:
		_toast("Hatch → EVA")
	elif dest == "pad":
		_toast("Hatch → pad")
	elif dest == "ramp":
		_toast("Hatch → ramp")
	else:
		_toast("Hatch → dock")
	print("[Interior] exited ", _kind, " → ", dest if not was_ship else "eva")
	_kind = ""
	_return_mode = "pad"
	_hangar_host = null
	set_process(false)


func _apply_hatch_facing() -> void:
	## Pad-tangent hull nose, same as land-EVA. World-XZ yaw is the wrong frame.
	if _player == null or not is_instance_valid(_player):
		return
	var ref := Vector3(0, 0, -1)
	if _open_space != null:
		var sh: Variant = _open_space.get("ship")
		if sh is Node3D and is_instance_valid(sh):
			ref = -(sh as Node3D).global_transform.basis.z
	if _player.has_method("set_spawn_facing"):
		_player.set_spawn_facing(_return_up, ref)
	elif _player.has_method("set_spawn_basis"):
		_player.set_spawn_basis(_return_up, 0.0)


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


func seat_companion(body: Node3D) -> bool:
	## NP-D: squad NPC sits at the existing F seat. No extra combat seat.
	if body == null or not is_instance_valid(body):
		return false
	if not _inside or _kind != "ship" or _active == null or not is_instance_valid(_active):
		return false
	var seat: Node3D = _active.get_node_or_null("Seat") as Node3D
	if seat == null:
		seat = _active.get_node_or_null("SeatVolume") as Node3D
	if seat == null:
		return false
	if body.get_parent() != _active:
		if body.get_parent() != null:
			body.reparent(_active, true)
		else:
			_active.add_child(body)
	body.global_position = seat.global_position + Vector3(0.0, 1.05, 0.0)
	body.set_meta("squad_seated", true)
	return true


func is_near_seat(player: Node3D, max_dist: float = 3.6) -> bool:
	## Ship cockpit Seat/SeatVolume only. Station/hangar use legal seats.
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


func is_near_legal_seat(player: Node3D, max_dist: float = 3.6) -> bool:
	## Ops seat (station) or carrier pilot seat (hangar_bay). Not the ship cockpit.
	if _kind != "station" and _kind != "hangar_bay":
		return false
	if player == null or not is_instance_valid(player) or not _inside or _active == null:
		return false
	if not is_instance_valid(_active):
		return false
	var seat: Node3D = _legal_seat_node()
	if seat == null:
		return false
	return player.global_position.distance_to(seat.global_position) <= max_dist


func _legal_seat_node() -> Node3D:
	if _active == null or not is_instance_valid(_active):
		return null
	for nm in ["OpsSeat", "OpsSeatVolume", "HangarSeat", "HangarSeatVolume"]:
		var n: Node = _active.get_node_or_null(nm)
		if n is Node3D:
			return n as Node3D
	return null


func try_board_legal_seat(player: Node3D = null) -> bool:
	## F in station/hangar boards the legal seat. Walker stays in this pocket.
	var who: Node3D = player if player != null else _player
	if not _inside or _kind == "ship":
		return false
	if who == null or not is_instance_valid(who):
		return false
	if _seated:
		return false
	if not is_near_legal_seat(who, 3.8):
		return false
	var seat: Node3D = _legal_seat_node()
	if seat == null:
		return false
	_player = who
	_seated = true
	_seat_role = "ops" if _kind == "station" else "carrier_pilot"
	who.global_position = seat.global_position + Vector3(0.0, 1.05, 0.0)
	if who is CharacterBody3D:
		(who as CharacterBody3D).velocity = Vector3.ZERO
	if _kind == "station":
		_toast("OPS SEAT · I leave · same pocket")
	else:
		_toast("CARRIER PILOT · I leave · same pocket")
	print("[Interior] boarded legal seat role=", _seat_role, " kind=", _kind)
	return true


func leave_legal_seat() -> bool:
	## I from the legal seat returns to the same pocket. No exterior hop.
	if not _inside or not _seated:
		return false
	var seat: Node3D = _legal_seat_node()
	var role := _seat_role
	_seated = false
	_seat_role = ""
	if _player != null and is_instance_valid(_player):
		if seat != null:
			var along: Vector3 = -seat.global_transform.basis.z
			if along.length_squared() < 0.04:
				along = Vector3(0, 0, 1)
			_player.global_position = seat.global_position + Vector3(0.0, 1.05, 0.0) + along.normalized() * 1.2
		if _player is CharacterBody3D:
			(_player as CharacterBody3D).velocity = Vector3.ZERO
	_toast("Left seat — %s pocket" % _kind)
	print("[Interior] left legal seat ", role, " → ", _kind)
	return true


func is_near_hatch(player: Node3D, max_dist: float = 3.6) -> bool:
	if player == null or not is_instance_valid(player) or not _inside or _active == null:
		return false
	if not is_instance_valid(_active):
		return false
	for nm in ["ExitVolume", "HatchArch", "AirlockStub"]:
		var n: Node = _active.get_node_or_null(nm)
		if n is Node3D:
			if player.global_position.distance_to((n as Node3D).global_position) <= max_dist:
				return true
	for n2 in _active.get_children():
		if not (n2 is Node3D):
			continue
		if not str(n2.name).begins_with("DoorPortal"):
			continue
		var dest := str(n2.get_meta("leads_to", ""))
		if dest != "eva" and dest != "pad" and dest != "dock":
			continue
		if player.global_position.distance_to((n2 as Node3D).global_position) <= max_dist:
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
	if _kind == "station" or _kind == "hangar_bay":
		_recycler_on = not _recycler_on
		_refresh_life_support()
		_apply_ops_console()
		_tick_life_support_warn(0.0, true)
		var retrieved := _try_hangar_retrieve()
		var rec := "HABITAT SEALED" if _recycler_on else "VENTED TO PLANET"
		var board := str(_console_board.get("board", _pad_status_line()))
		if retrieved == "DEPLOYED":
			_toast("ROVER ON RAMP · F board")
		elif retrieved == "BLOCKED":
			_toast("RAMP BLOCKED · cannot retrieve")
		else:
			_toast("%s · ATMO %.2f · %s" % [rec, _atmo, board])
	else:
		_toast("COCKPIT · %s · F seat · F/I hatch" % life_support_line())
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
	_seated = false
	_seat_role = ""
	_player = null
	_set_world_hidden(false)
	if _open_space:
		var fo = _open_space.get("floating")
		if fo != null and is_instance_valid(fo):
			if fo.has_method("set_process"):
				fo.set_process(true)
			if fo.has_method("set_physics_process"):
				fo.set_physics_process(true)
			if fo.has_method("set_target"):
				var sh = _open_space.get("ship")
				if sh != null and is_instance_valid(sh):
					fo.set_target(sh)
	if LayerContext:
		LayerContext.current_layer = "Space"
		if "seamless_stage" in LayerContext:
			LayerContext.seamless_stage = "world"
	exited.emit("ship_to_pilot")
	print("[Interior] exit_for_pilot")
	_kind = ""
	_return_mode = "pad"
	_hangar_host = null
	set_process(false)


func _deployed_hangar_ramp() -> Node3D:
	## IN-C: hatch onto plates only when the carrier ramp is DEPLOYED.
	if _hangar_host == null or not is_instance_valid(_hangar_host):
		return null
	var ramp: Node = null
	if _hangar_host.has_method("cargo_ramp"):
		ramp = _hangar_host.cargo_ramp()
	if ramp == null:
		ramp = _hangar_host.find_child("CargoRamp", true, false)
	if ramp == null or not is_instance_valid(ramp):
		return null
	if ramp.has_method("is_driveable") and bool(ramp.is_driveable()):
		return ramp as Node3D
	return null


func _process(delta: float) -> void:
	if not _inside or _player == null or not is_instance_valid(_player) or _active == null:
		return
	if not is_instance_valid(_active):
		return
	_console_cd = maxf(0.0, _console_cd - delta)
	_refresh_life_support()
	_tick_life_support_warn(delta, false)
	_tick_doors(delta)
	if _seated:
		var seat_hold: Node3D = _legal_seat_node()
		if seat_hold != null and _player != null and is_instance_valid(_player):
			_player.global_position = seat_hold.global_position + Vector3(0.0, 1.05, 0.0)
			if _player is CharacterBody3D:
				(_player as CharacterBody3D).velocity = Vector3.ZERO
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
	var near_legal := is_near_legal_seat(_player, 3.6)
	for lnm in ["OpsSeatLabel", "HangarSeatLabel"]:
		var sl = _active.get_node_or_null(lnm)
		if sl is Label3D:
			(sl as Label3D).modulate.a = 1.0 if near_legal or _seated else 0.55
			if lnm == "OpsSeatLabel":
				(sl as Label3D).text = "OPS SEAT · I" if _seated else ("OPS SEAT · F" if near_legal else "OPS SEAT")
			else:
				(sl as Label3D).text = "CARRIER PILOT · I" if _seated else ("CARRIER PILOT · F" if near_legal else "CARRIER PILOT")
	var hlab = _active.get_node_or_null("HatchLabel")
	if hlab is Label3D:
		var near_h := is_near_hatch(_player)
		(hlab as Label3D).modulate.a = 1.0 if near_h else 0.55
		if _kind == "ship":
			(hlab as Label3D).text = "AIRLOCK · HATCH [I] EVA" if near_h else "AIRLOCK · HATCH [I]"
		elif _kind == "hangar_bay" and _deployed_hangar_ramp() != null:
			(hlab as Label3D).text = "HATCH [I] RAMP" if near_h else "HATCH [I]"
		elif _return_mode == "dock":
			(hlab as Label3D).text = "HATCH [I] DOCK" if near_h else "HATCH [I]"
		else:
			(hlab as Label3D).text = "HATCH [I] PAD" if near_h else "HATCH [I]"
		(hlab as Label3D).font_size = 48 if near_h else 36


func _refresh_life_support() -> void:
	if not _inside:
		_atmo = 1.0
		_sealed = true
		return
	if _kind == "ship":
		_sealed = true
		_atmo = 1.0
		_sync_ambient()
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
	_sync_ambient()


func _sync_ambient() -> void:
	if _active == null or not is_instance_valid(_active):
		return
	var amb = _active.get_node_or_null("InteriorAmbient")
	if amb and amb.has_method("sync_life_support"):
		amb.sync_life_support(_atmo, _sealed, _recycler_on, life_support_line())


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


func _try_hangar_retrieve() -> String:
	## IN-E: bay console retrieves a stored rover when the ramp is DEPLOYED.
	if _kind != "hangar_bay":
		return ""
	if _hangar_host == null or not is_instance_valid(_hangar_host):
		return ""
	if not _hangar_host.has_method("try_retrieve_rover"):
		return ""
	if _hangar_host.has_method("stored_vehicle_count") and int(_hangar_host.stored_vehicle_count()) <= 0:
		return "EMPTY"
	var retrieved := str(_hangar_host.try_retrieve_rover())
	_console_board["retrieve"] = retrieved
	print("[Interior] hangar retrieve=", retrieved)
	return retrieved


func _apply_ops_console() -> void:
	## Real board action: occupy the linked pad and/or read the factory print gate.
	## Not a locked prop. Not toast-only. Does not print a module. Does not mint SITE_*.
	var pad: Node3D = _linked_occupy_pad()
	var occupy_applied := false
	var occupy_status := ""
	var occupy_before := 0.0
	var occupy_after := 0.0
	var fac := "Cybernex"
	var factory: Node3D = _factory_in_cluster()
	var factory_gate := factory != null
	if _player != null and is_instance_valid(_player) and _player.has_method("get_faction"):
		fac = str(_player.get_faction())
	elif GameManager:
		fac = GameManager.get_faction_name()
	if pad != null and pad.has_method("claim"):
		if pad.has_method("get_occupy_strength"):
			occupy_before = float(pad.get_occupy_strength())
		pad.claim(fac, 0.55)
		occupy_applied = true
		if pad.has_method("get_occupy_strength"):
			occupy_after = float(pad.get_occupy_strength())
		if pad.has_method("get_claim_status"):
			occupy_status = str(pad.get_claim_status())
	_console_board = {
		"used": true,
		"kind": _kind,
		"board": _board_status_line(pad, factory_gate, occupy_status),
		"occupy": occupy_applied,
		"occupy_status": occupy_status,
		"occupy_before": occupy_before,
		"occupy_after": occupy_after,
		"factory_gate": factory_gate,
		"ls": life_support_line(),
	}
	_attach_contract_offer(pad, occupy_applied)
	_attach_alliance_offer(pad)
	print("[Interior] ops console used occupy=", occupy_applied, " factory_gate=", factory_gate,
		" status=", occupy_status, " ls=", life_support_line())


func _attach_contract_offer(pad: Node3D, occupy_applied: bool) -> void:
	## Q-A board lives on the station ops console. Hangar/ship keep IN-B/IN-E roles.
	var offer: Dictionary = {}
	var host := ""
	if _kind != "station":
		return
	host = _contract_host_id(pad)
	offer = _Board.offer_one(host, "Nex-Prime")
	if offer.is_empty():
		return
	_console_board["contract"] = offer
	_console_board["contract_offered"] = true
	_console_board["contract_template"] = str(offer.get("template", ""))
	_console_board["contract_status"] = str(offer.get("status", ""))
	_console_board["board"] = str(_console_board.get("board", "")) + " · %s %s" % [
		_SoftK.contract_board_label(),
		str(offer.get("template", "")),
	]
	if typeof(offer.get("learning_node")) == TYPE_DICTIONARY \
			and not (offer.get("learning_node") as Dictionary).is_empty():
		_console_board["learning_node"] = offer.get("learning_node")
		_console_board["board"] = str(_console_board.get("board", "")) + " · NODE"
	if occupy_applied:
		_Board.note_progress("occupy")


func _attach_alliance_offer(pad: Node3D) -> void:
	## Q-B: same ContractBoard, alliance slot. Does not replace the Q-A offer.
	var offer: Dictionary = {}
	var host := ""
	var intent := ""
	var ally: Node = null
	if _kind != "station":
		return
	host = _contract_host_id(pad)
	if get_tree():
		for n in get_tree().get_nodes_in_group("soft_alliance"):
			if n != null and is_instance_valid(n):
				ally = n
				break
	if ally != null and ally.has_method("intent"):
		intent = str(ally.intent())
	offer = _Board.offer_alliance_one(host, "Nex-Prime", intent)
	if offer.is_empty():
		return
	if ally != null and ally.has_method("see_contract"):
		ally.see_contract(str(offer.get("id", "")))
	_console_board["alliance_contract"] = offer
	_console_board["alliance_offered"] = true
	_console_board["board"] = str(_console_board.get("board", "")) + " · ALLY %s" % str(offer.get("template", ""))


func _contract_host_id(pad: Node3D) -> String:
	var n: Node = pad
	while n:
		if n is Node3D and str(n.name) in ["Pad_North", "Pad_Approach", "Pad_Flank"]:
			return str(n.name)
		n = n.get_parent()
	if pad != null and is_instance_valid(pad):
		return str(pad.name)
	return "orbital_ops"


func _linked_occupy_pad() -> Node3D:
	## Pad-linked station only. Orbital dock / hangar do not steal a distant plate.
	var found: Node = null
	if _occupy_host != null and is_instance_valid(_occupy_host) and _occupy_host.has_method("claim"):
		return _occupy_host as Node3D
	if _return_mode != "pad":
		return null
	if _open_space != null and _open_space.has_method("nearest_pad"):
		found = _claimable_from(_open_space.nearest_pad(_return_pos))
		if found is Node3D:
			return found as Node3D
	found = _claimable_near(_return_pos, 50.0)
	if found is Node3D:
		return found as Node3D
	return null


func _claimable_from(n: Node) -> Node:
	var cur: Node = n
	while cur != null:
		if cur.has_method("claim"):
			return cur
		cur = cur.get_parent()
	if n != null:
		for c in n.get_children():
			if c.has_method("claim"):
				return c
	return null


func _claimable_near(at: Vector3, max_d: float) -> Node:
	var tree := get_tree()
	var best: Node = null
	var best_d := max_d
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("pad_bases"):
		if n == null or not is_instance_valid(n) or not n.has_method("claim"):
			continue
		if not (n is Node3D):
			continue
		var d: float = (n as Node3D).global_position.distance_to(at)
		if d < best_d:
			best_d = d
			best = n
	return best


func _factory_in_cluster() -> Node3D:
	if _open_space == null:
		return null
	var cluster: Node3D = null
	if _open_space.has_method("player_orbital_station"):
		cluster = _open_space.player_orbital_station()
	if cluster == null or not is_instance_valid(cluster):
		return null
	if cluster.has_method("factory_module"):
		var fac: Node3D = cluster.factory_module()
		if fac != null and is_instance_valid(fac):
			return fac
	return null


func _board_status_line(pad: Node3D, factory_gate: bool, occupy_status: String) -> String:
	var line := ""
	if pad != null:
		line = _pad_status_line()
		if occupy_status != "":
			line += " · OCCUPY %s" % occupy_status
	elif _return_mode == "dock":
		line = "DOCK BOARD"
	if factory_gate:
		line += " · FACTORY PRINT OPEN"
	else:
		line += " · FACTORY PRINT GATED"
	return line.strip_edges()


func _tick_life_support_warn(delta: float, force: bool) -> void:
	## Same soft suit line as EVA. Never HP. Never lethal.
	if not _inside:
		_ls_warn_t = 0.0
		return
	if has_life_support():
		_ls_warn_t = 0.0
		return
	_ls_warn_t += delta
	if force or _ls_warn_t >= 8.0:
		_ls_warn_t = 0.0
		_ls_warn_shown = true
		_toast("EVA suit — reboard soon (soft warn)")
		print("[Interior] EVA soft warning — reboard soon")


func _nearby_pad(player: Node3D) -> Node3D:
	if player == null or _open_space == null or not _open_space.has_method("nearest_pad"):
		return null
	var pad: Node3D = _open_space.nearest_pad(player.global_position)
	if pad == null or not is_instance_valid(pad):
		return null
	if player.global_position.distance_to(pad.global_position) >= 45.0:
		return null
	return pad


func _nearby_orbital_cluster(player: Node3D) -> Node3D:
	if player == null or _open_space == null:
		return null
	var cluster: Node3D = null
	if _open_space.has_method("player_orbital_station"):
		cluster = _open_space.player_orbital_station()
	if cluster == null or not is_instance_valid(cluster):
		return null
	if _host_distance(player, cluster) < 55.0:
		return cluster
	if cluster.has_method("cluster_modules"):
		for m in cluster.cluster_modules():
			if m is Node3D and _host_distance(player, m as Node3D) < 55.0:
				return cluster
	if cluster.has_method("factory_module"):
		var fac: Node3D = cluster.factory_module()
		if fac != null and _host_distance(player, fac) < 55.0:
			return cluster
	return null


func _nearby_catalog_carrier(player: Node3D) -> Node3D:
	if player == null or _open_space == null:
		return null
	var carrier: Node3D = null
	if _open_space.has_method("catalog_carrier"):
		carrier = _open_space.catalog_carrier()
	if carrier == null or not is_instance_valid(carrier):
		return null
	if str(carrier.get_meta("site_pin", "")) != "":
		return null
	if bool(carrier.get_meta("mobile_site", false)):
		return null
	if _host_distance(player, carrier) >= 55.0:
		return null
	return carrier


func _is_orbital_station_host(host: Node3D) -> bool:
	if host == null:
		return false
	if bool(host.get_meta("player_orbital_station", false)) or bool(host.get_meta("orbital_cluster", false)):
		return true
	if bool(host.get_meta("orbital_module", false)) or bool(host.get_meta("factory_module", false)):
		return true
	return host.get_node_or_null("DockModule") != null


func _cluster_dock(host: Node3D) -> Node3D:
	if host == null:
		return null
	var dock: Node = host.get_node_or_null("DockModule")
	if dock is Node3D:
		return dock as Node3D
	if bool(host.get_meta("orbital_module", false)) and str(host.get_meta("module_type", "")) == "dock":
		return host
	return host


func _up_from_planet(at: Vector3) -> Vector3:
	if _open_space != null and _open_space.has_method("nearest_planet"):
		var pl: Node3D = _open_space.nearest_planet(at)
		if pl != null and is_instance_valid(pl):
			var up: Vector3 = at - pl.global_position
			if up.length_squared() > 0.01:
				return up.normalized()
	return Vector3.UP


func _host_distance(player: Node3D, host: Node3D) -> float:
	if player == null or host == null:
		return 9999.0
	return player.global_position.distance_to(host.global_position)


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
		var hold := float(_door_hold.get(n.name, 0.0))
		if near:
			hold = 0.55
		else:
			hold = maxf(0.0, hold - delta)
		_door_hold[n.name] = hold
		var want_open := near or hold > 0.0
		var target_x := 1.55 if want_open else 0.0
		var speed := 4.8 if want_open else 3.1
		var prev_x := slab.position.x
		slab.position.x = move_toward(slab.position.x, target_x, delta * speed)
		if prev_x < 0.18 and slab.position.x >= 0.18:
			if AudioDirector and AudioDirector.has_method("play_door"):
				AudioDirector.play_door(true)
			elif AudioDirector and AudioDirector.has_method("play_ui"):
				AudioDirector.play_ui()
		elif prev_x > 1.25 and slab.position.x <= 1.25 and not want_open:
			if AudioDirector and AudioDirector.has_method("play_door"):
				AudioDirector.play_door(false)
		# Open slab must not block the hall — but drop collision only once the
		# slab has actually cleared the opening, else you clip through it.
		var blocking := slab.position.x < 1.4
		for c in slab.get_children():
			if c is CollisionObject3D:
				(c as CollisionObject3D).collision_layer = 1 if blocking else 0
				(c as CollisionObject3D).collision_mask = 1 if blocking else 0
		if slab is MeshInstance3D:
			var mat := (slab as MeshInstance3D).material_override as StandardMaterial3D
			if mat:
				mat.emission_energy_multiplier = 1.25 if want_open else 0.55
