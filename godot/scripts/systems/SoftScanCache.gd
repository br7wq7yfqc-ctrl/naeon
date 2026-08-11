extends Node
## Shared TTL cache for group/file scans (HUD / pads / ship).

const PLAYER_TTL := 0.45
const PAD_TTL := 0.8
const PLANET_TTL := 1.2
const TERRAIN_TTL := 0.7
const HOST_FILE_TTL := 2.5

var _player: Node3D = null
var _player_t: float = 99.0
var _pads: Array = []
var _pads_t: float = 99.0
var _planets: Array = []
var _planets_t: float = 99.0
var _terrain: Array = []
var _terrain_t: float = 99.0
var _host_hint: String = ""
var _host_t: float = 99.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_player_t += delta
	_pads_t += delta
	_planets_t += delta
	_terrain_t += delta
	_host_t += delta


func invalidate_player() -> void:
	_player = null
	_player_t = 99.0


func get_player() -> Node3D:
	if _player != null:
		if is_instance_valid(_player) and _player_t < PLAYER_TTL:
			return _player
		_player = null
	_player_t = 0.0
	var tree := get_tree()
	if tree == null:
		_player = null
		return null
	var n = tree.get_first_node_in_group("player")
	if n is Node3D and is_instance_valid(n):
		_player = n as Node3D
		return _player
	for s in tree.get_nodes_in_group("ship"):
		if s is Node3D and is_instance_valid(s):
			_player = s as Node3D
			return _player
	_player = null
	return null


func get_pads() -> Array:
	if _pads_t < PAD_TTL and not _pads.is_empty():
		return _pads
	_pads_t = 0.0
	_pads = []
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("pad_bases"):
			if is_instance_valid(n):
				_pads.append(n)
	return _pads


func get_planets() -> Array:
	if _planets_t < PLANET_TTL and not _planets.is_empty():
		return _planets
	_planets_t = 0.0
	_planets = []
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("planets"):
			if n is Node3D and is_instance_valid(n):
				_planets.append(n)
	return _planets


func get_terrain_edits() -> Array:
	if _terrain_t < TERRAIN_TTL and not _terrain.is_empty():
		return _terrain
	_terrain_t = 0.0
	_terrain = []
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("terrain_edit"):
			if is_instance_valid(n):
				_terrain.append(n)
	return _terrain


func host_hint() -> String:
	if _host_t < HOST_FILE_TTL:
		return _host_hint
	_host_t = 0.0
	_host_hint = ""
	if not FileAccess.file_exists("user://softnet_host_info.txt"):
		return _host_hint
	var hf := FileAccess.open("user://softnet_host_info.txt", FileAccess.READ)
	if hf == null:
		return _host_hint
	var lines := hf.get_as_text().strip_edges().split("\n")
	var ip_show: PackedStringArray = []
	for ln in lines:
		if ln.begins_with("port=") or ln.begins_with("transport="):
			continue
		if ln != "":
			ip_show.append(ln)
		if ip_show.size() >= 2:
			break
	if ip_show.size() > 0:
		_host_hint = "  LAN " + ", ".join(ip_show)
	return _host_hint


func nearest_pad(from: Vector3, max_dist: float = 200.0) -> Node3D:
	var best: Node3D = null
	var best_d := max_dist
	for n in get_pads():
		if n is Node3D and is_instance_valid(n):
			var d: float = from.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n as Node3D
	return best


func nearest_planet(from: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d := 1.0e12
	for n in get_planets():
		if n is Node3D and is_instance_valid(n):
			var d: float = from.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n as Node3D
	return best


func invalidate() -> void:
	_player_t = 99.0
	_pads_t = 99.0
	_planets_t = 99.0
	_terrain_t = 99.0
	_host_t = 99.0
	_player = null
	_pads.clear()
	_planets.clear()
	_terrain.clear()
