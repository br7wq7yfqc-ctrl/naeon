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
	_root = world_root
	_open_space = open_space

func is_inside() -> bool:
	return _inside

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
	_begin(player, "ship", _Gen.build_ship(fac), ship.global_position, Vector3.UP)

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
	entered.emit(kind)
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
	exited.emit(_kind)
	print("[Interior] exited ", _kind)
	_kind = ""
