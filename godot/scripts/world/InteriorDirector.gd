extends Node
class_name InteriorDirector
## Enter/exit station or ship interiors (procedural pockets). Seamless enough for vertical slice.

signal entered(kind: String)
signal exited(kind: String)

const _Gen = preload("res://scripts/world/InteriorGenerator.gd")

var _root: Node3D
var _active: Node3D
var _kind: String = ""
var _return_pos: Vector3 = Vector3.ZERO
var _return_up: Vector3 = Vector3.UP
var _player: Node3D
var _open_space: Node
var _inside: bool = false

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

func try_toggle(player: Node3D, ship: Node3D = null) -> void:
	if _inside:
		exit_interior()
		return
	# Prefer station if near pad
	if _open_space and _open_space.has_method("nearest_pad") and player:
		var pad: Node3D = _open_space.nearest_pad(player.global_position)
		if pad and player.global_position.distance_to(pad.global_position) < 35.0:
			enter_station(player, pad)
			return
	# Ship interior if near ship
	if ship and player and player.global_position.distance_to(ship.global_position) < 14.0:
		enter_ship(player, ship)
		return
	print("[Interior] Nothing to enter (near pad or ship)")

func enter_station(player: Node3D, pad: Node3D) -> void:
	var fac := "Cybernex"
	if pad.has_meta("base_faction"):
		fac = str(pad.get_meta("base_faction"))
	elif GameManager:
		fac = GameManager.get_faction_name()
	_begin(player, "station", _Gen.build_station(fac), pad.global_position, pad.get_meta("pad_up") if pad.has_meta("pad_up") else Vector3.UP)

func enter_ship(player: Node3D, ship: Node3D) -> void:
	var fac := "Cybernex"
	if ship.get("faction") != null:
		fac = str(ship.faction)
	var pid := "scout_single"
	if ship.has_method("get_interior_profile_id"):
		pid = str(ship.get_interior_profile_id())
	var interior: Node3D = _Gen.build_from_profile(pid, fac)
	_begin(player, "ship", interior, ship.global_position, Vector3.UP)

func _begin(player: Node3D, kind: String, interior: Node3D, ret_pos: Vector3, ret_up: Vector3) -> void:
	if _active:
		_active.queue_free()
	_kind = kind
	_player = player
	_return_pos = ret_pos + ret_up * 3.0
	_return_up = ret_up
	_active = interior
	# Place pocket near origin of floating space but offset from planet chaos
	if _root:
		_root.add_child(_active)
	# Offset far from planets to avoid collision
	_active.global_position = Vector3(0, 50000, 0)
	var spawn: Node3D = _active.get_node_or_null("Spawn") as Node3D
	if spawn:
		player.global_position = spawn.global_position
	else:
		player.global_position = _active.global_position + Vector3(0, 1, 0)
	if player.has_method("set_spawn_basis"):
		player.set_spawn_basis(Vector3.UP, 0.0)
	if player.has_method("set_planet_gravity_provider"):
		# Flat gravity inside
		player.set_planet_gravity_provider(self)
	_inside = true
	if LayerContext:
		LayerContext.current_layer = "ship_int" if kind == "ship" else "station"
		if "seamless_stage" in LayerContext:
			LayerContext.seamless_stage = "interior"
	_hatch_fx(true)
	entered.emit(kind)
	_toast("Entered %s · I exit · F seat (ship)" % kind)
	print("[Interior] entered ", kind)

func gravity_at(global_pos: Vector3) -> Vector3:
	# Flat down for interiors
	return Vector3(0, -12.0, 0)

func exit_interior() -> void:
	if not _inside:
		return
	if _player and is_instance_valid(_player):
		_player.global_position = _return_pos
		if _player.has_method("set_planet_gravity_provider") and _open_space:
			_player.set_planet_gravity_provider(_open_space)
		if _player.has_method("set_spawn_basis"):
			_player.set_spawn_basis(_return_up, 0.0)
		if _player.has_method("snap_to_surface"):
			_player.call_deferred("snap_to_surface")
	if _active:
		_active.queue_free()
		_active = null
	_inside = false
	if LayerContext:
		LayerContext.current_layer = "surface" if _kind != "ship" else "space"
		if "seamless_stage" in LayerContext:
			LayerContext.seamless_stage = "world"
	_hatch_fx(false)
	exited.emit(_kind)
	_toast("Exited interior")
	print("[Interior] exited ", _kind)
	_kind = ""

func _toast(msg: String) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("game_hud"):
		if n.has_method("push_toast"):
			n.push_toast(msg, 2.5)
			return


func _hatch_fx(entering: bool) -> void:
	## Soft hatch light on nearby ship hatch door (presentation only).
	if _open_space == null:
		return
	var ship = null
	if _open_space.has_method("get_player_ship"):
		ship = _open_space.get_player_ship()
	if ship == null and SoftScanCache:
		ship = SoftScanCache.get_player()
	if ship == null:
		return
	var door = ship.get_node_or_null("HatchPoint/HatchDoor")
	if door == null:
		door = ship.get_node_or_null("HatchDoor")
	if door is MeshInstance3D:
		var mi: MeshInstance3D = door
		var mat = mi.material_override
		if mat is StandardMaterial3D:
			var sm: StandardMaterial3D = mat
			sm.emission_enabled = true
			sm.emission_energy_multiplier = 2.4 if entering else 0.6
			if entering:
				mi.rotation.y = deg_to_rad(75.0)
			else:
				mi.rotation.y = 0.0



func is_near_seat(player: Node3D, max_dist: float = 3.8) -> bool:
	if player == null or not is_instance_valid(player) or not _inside or _active == null:
		return false
	if not is_instance_valid(_active):
		return false
	for nm in ["SeatVolume", "Seat", "Spawn"]:
		var n: Node = _active.get_node_or_null(nm)
		if n is Node3D:
			if player.global_position.distance_to((n as Node3D).global_position) <= max_dist:
				return true
	# Cockpit room fallback (near origin of pocket)
	if _kind == "ship" and player.global_position.distance_to(_active.global_position) < 8.0:
		return true
	return false


func exit_for_pilot() -> void:
	## Leave pocket without teleporting walker (walker will be freed for ship pilot).
	if not _inside:
		return
	_hatch_fx(false)
	if _active and is_instance_valid(_active):
		_active.queue_free()
	_active = null
	_inside = false
	_player = null
	if LayerContext:
		LayerContext.current_layer = "Space"
		if "seamless_stage" in LayerContext:
			LayerContext.seamless_stage = "world"
	exited.emit("ship_to_pilot")
	print("[Interior] exit_for_pilot")
	_kind = ""
