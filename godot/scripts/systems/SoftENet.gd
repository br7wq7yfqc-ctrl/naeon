extends Node
## Soft ENet multiplayer — host/join + remote puppets.
## Syncs pos/form/faction only. Never combat power / loot / P2W.

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal host_started(port: int)
signal joined(address: String, port: int)

const DEFAULT_PORT := 27700
const MAX_CLIENTS := 8
const _Puppet = preload("res://scripts/systems/SoftRemotePuppet.gd")

var is_host: bool = false
var is_connected: bool = false
var port: int = DEFAULT_PORT
var _peer: MultiplayerPeer = null
var _broadcast_tick: float = 0.0
var _player_ref: Node3D = null
var _puppets: Dictionary = {}  ## peer_id -> SoftRemotePuppet
var _puppet_root: Node3D = null

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	call_deferred("_maybe_cmdline_net")

func bind_player(p: Node3D) -> void:
	_player_ref = p
	_ensure_puppet_root()

func _ensure_puppet_root() -> void:
	if _puppet_root and is_instance_valid(_puppet_root):
		return
	var parent: Node = null
	if _player_ref and is_instance_valid(_player_ref):
		parent = _player_ref.get_parent()
	if parent == null and get_tree():
		parent = get_tree().current_scene
	if parent == null:
		return
	_puppet_root = Node3D.new()
	_puppet_root.name = "SoftRemotePuppets"
	parent.add_child.call_deferred(_puppet_root)

func host(p: int = DEFAULT_PORT) -> Error:
	port = p
	var enet := ENetMultiplayerPeer.new()
	var err := enet.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_warning("[SoftENet] host failed: %s" % err)
		if GameManager:
			GameManager.toast_requested.emit("SoftENet host failed (%s)" % err)
		return err
	_peer = enet
	multiplayer.multiplayer_peer = enet
	is_host = true
	is_connected = true
	if LayerContextAuthority:
		LayerContextAuthority.claim_local_authority()
		LayerContextAuthority.peer_id = 1
	_ensure_puppet_root()
	host_started.emit(port)
	if GameManager:
		GameManager.toast_requested.emit("SoftENet HOST :%d · soft puppets only" % port)
	print("[SoftENet] host port=", port)
	return OK

func join(address: String = "127.0.0.1", p: int = DEFAULT_PORT) -> Error:
	port = p
	var enet := ENetMultiplayerPeer.new()
	var err := enet.create_client(address, port)
	if err != OK:
		push_warning("[SoftENet] join failed: %s" % err)
		if GameManager:
			GameManager.toast_requested.emit("SoftENet join failed")
		return err
	_peer = enet
	multiplayer.multiplayer_peer = enet
	is_host = false
	if GameManager:
		GameManager.toast_requested.emit("SoftENet joining %s:%d…" % [address, port])
	print("[SoftENet] joining ", address, ":", port)
	return OK

func leave() -> void:
	_clear_puppets()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	_peer = null
	is_host = false
	is_connected = false
	print("[SoftENet] left session")
	if GameManager:
		GameManager.toast_requested.emit("SoftENet left")

func status_line() -> String:
	if not is_connected and not is_host:
		return "NET off"
	var n := multiplayer.get_peers().size() if multiplayer.multiplayer_peer else 0
	return "NET %s peers=%d puppets=%d :%d" % [
		"HOST" if is_host else "CLIENT", n, _puppets.size(), port
	]

func _process(delta: float) -> void:
	if not is_connected and not is_host:
		return
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	_broadcast_tick += delta
	if _broadcast_tick < 0.1:
		return
	_broadcast_tick = 0.0
	var form := "Canine"
	var fac := "Cybernex"
	if "current_form" in _player_ref:
		form = str(_player_ref.current_form)
	elif "form_name" in _player_ref:
		form = str(_player_ref.form_name)
	elif _player_ref.is_in_group("ship"):
		form = "Ship"
	if "faction" in _player_ref:
		fac = str(_player_ref.faction)
	var pos: Vector3 = _player_ref.global_position
	rpc_soft_state.rpc(pos.x, pos.y, pos.z, _player_ref.rotation.y, form, fac)

@rpc("any_peer", "unreliable_ordered")
func rpc_soft_state(x: float, y: float, z: float, yaw: float, form: String, faction: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0 or sender == multiplayer.get_unique_id():
		return
	_ensure_puppet_root()
	var pup = _get_or_create_puppet(sender)
	if pup and pup.has_method("apply_state"):
		pup.call("apply_state", Vector3(x, y, z), yaw, form, faction)

func _get_or_create_puppet(id: int) -> Node3D:
	if _puppets.has(id) and is_instance_valid(_puppets[id]):
		return _puppets[id]
	if _puppet_root == null or not is_instance_valid(_puppet_root):
		return null
	if _puppet_root.get_parent() == null:
		return null
	var pup := Node3D.new()
	pup.set_script(_Puppet)
	_puppet_root.add_child(pup)
	if pup.has_method("setup"):
		pup.call("setup", id)
	_puppets[id] = pup
	print("[SoftENet] puppet +", id)
	if GameManager:
		GameManager.toast_requested.emit("Remote peer puppet id=%d" % id)
	return pup

func _clear_puppets() -> void:
	for k in _puppets.keys():
		var p = _puppets[k]
		if p and is_instance_valid(p):
			p.queue_free()
	_puppets.clear()

func _on_peer_connected(id: int) -> void:
	print("[SoftENet] peer +", id)
	peer_connected.emit(id)
	if GameManager:
		GameManager.toast_requested.emit("Peer connected id=%d" % id)

func _on_peer_disconnected(id: int) -> void:
	print("[SoftENet] peer -", id)
	if _puppets.has(id):
		var p = _puppets[id]
		if p and is_instance_valid(p):
			p.queue_free()
		_puppets.erase(id)
	peer_disconnected.emit(id)

func _on_connected_ok() -> void:
	is_connected = true
	joined.emit("remote", port)
	if LayerContextAuthority:
		LayerContextAuthority.is_authority = false
		LayerContextAuthority.peer_id = multiplayer.get_unique_id()
	_ensure_puppet_root()
	print("[SoftENet] connected as ", multiplayer.get_unique_id())
	if GameManager:
		GameManager.toast_requested.emit("SoftENet connected (client) · puppets on")

func _on_connection_failed() -> void:
	is_connected = false
	print("[SoftENet] connection failed")
	if GameManager:
		GameManager.toast_requested.emit("SoftENet connection failed")

func _on_server_disconnected() -> void:
	is_connected = false
	is_host = false
	_clear_puppets()
	print("[SoftENet] server disconnected")

func _maybe_cmdline_net() -> void:
	# Headless / CLI stress: -- --softnet-host | --softnet-join=host
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a == "--softnet-host" or a == "softnet-host":
			host()
			return
		if a.begins_with("--softnet-join=") or a.begins_with("softnet-join="):
			var addr := a.split("=", true, 1)[1]
			if addr == "":
				addr = "127.0.0.1"
			join(addr)
			return
		if a == "--softnet-join" or a == "softnet-join":
			join("127.0.0.1")
			return
