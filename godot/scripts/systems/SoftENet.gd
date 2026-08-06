extends Node
## Soft multiplayer — ENet or WebSocket + remote puppets.
## Syncs pos/form/faction only. Never combat power / loot / P2W.

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal host_started(port: int)
signal joined(address: String, port: int)

const DEFAULT_PORT := 27700
const DEFAULT_WS_PORT := 27701
const MAX_CLIENTS := 8
const _Puppet = preload("res://scripts/systems/SoftRemotePuppet.gd")

var is_host: bool = false
var is_connected: bool = false
var is_joining: bool = false
var use_websocket: bool = false
var port: int = DEFAULT_PORT
var _peer: MultiplayerPeer = null
var _broadcast_tick: float = 0.0
var _peer_log_tick: float = 0.0
var _player_ref: Node3D = null
var _puppets: Dictionary = {}
var _puppet_root: Node3D = null
var loopback_enabled: bool = false
var _loopback_tick: float = 0.0
const LOOPBACK_PEER_ID := 99

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

func host(p: int = -1) -> Error:
	if p < 0:
		p = DEFAULT_WS_PORT if use_websocket else DEFAULT_PORT
	port = p
	var err: Error
	if use_websocket:
		var ws := WebSocketMultiplayerPeer.new()
		# Bind all interfaces (headless macOS localhost issues with default)
		err = ws.create_server(port, "*")
		_peer = ws
	else:
		var enet := ENetMultiplayerPeer.new()
		err = enet.create_server(port, MAX_CLIENTS)
		_peer = enet
	if err != OK:
		push_warning("[SoftENet] host failed: %s transport=%s" % [err, _transport_name()])
		if GameManager:
			GameManager.toast_requested.emit("SoftENet host failed (%s)" % err)
		return err
	multiplayer.multiplayer_peer = _peer
	is_host = true
	is_connected = true
	is_joining = false
	if LayerContextAuthority:
		LayerContextAuthority.claim_local_authority()
		LayerContextAuthority.peer_id = 1
	_ensure_puppet_root()
	host_started.emit(port)
	if GameManager:
		GameManager.toast_requested.emit("SoftENet HOST :%d (%s)" % [port, _transport_name()])
	print("[SoftENet] host port=", port, " unique_id=", multiplayer.get_unique_id(), " transport=", _transport_name())
	return OK

func join(address: String = "127.0.0.1", p: int = -1) -> Error:
	if p < 0:
		p = DEFAULT_WS_PORT if use_websocket else DEFAULT_PORT
	port = p
	var err: Error
	if use_websocket:
		var ws := WebSocketMultiplayerPeer.new()
		var url := address if address.begins_with("ws") else "ws://%s:%d" % [address, port]
		err = ws.create_client(url)
		_peer = ws
	else:
		var enet := ENetMultiplayerPeer.new()
		err = enet.create_client(address, port)
		_peer = enet
	if err != OK:
		push_warning("[SoftENet] join failed: %s" % err)
		if GameManager:
			GameManager.toast_requested.emit("SoftENet join failed")
		return err
	multiplayer.multiplayer_peer = _peer
	is_host = false
	is_joining = true
	is_connected = false
	if GameManager:
		GameManager.toast_requested.emit("SoftENet joining %s:%d…" % [address, port])
	print("[SoftENet] joining ", address, ":", port, " transport=", _transport_name())
	return OK

func leave() -> void:
	_clear_puppets()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	_peer = null
	is_host = false
	is_connected = false
	is_joining = false
	print("[SoftENet] left session")
	if GameManager:
		GameManager.toast_requested.emit("SoftENet left")

func _transport_name() -> String:
	return "ws" if use_websocket else "enet"

func status_line() -> String:
	if not is_connected and not is_host and not is_joining:
		return "NET off"
	var n := multiplayer.get_peers().size() if multiplayer.multiplayer_peer else 0
	var st := "HOST" if is_host else ("JOIN" if is_joining else "CLIENT")
	return "NET %s peers=%d puppets=%d :%d %s" % [st, n, _puppets.size(), port, _transport_name()]

func _process(delta: float) -> void:
	_loopback_tick_process(delta)
	if not is_connected and not is_host and not is_joining:
		return
	# Diagnostics while joining / hosting
	_peer_log_tick += delta
	if _peer_log_tick >= 1.5:
		_peer_log_tick = 0.0
		var st := -1
		if multiplayer.multiplayer_peer:
			st = multiplayer.multiplayer_peer.get_connection_status()
		var n := multiplayer.get_peers().size() if multiplayer.multiplayer_peer else 0
		print("[SoftENet] status=", st, " peers=", n, " puppets=", _puppets.size(), " host=", is_host, " join=", is_joining)
		if n > 0 and is_joining and not is_connected:
			# some transports mark peers before connected_to_server
			is_connected = true
			is_joining = false
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
	is_joining = false
	joined.emit("remote", port)
	if LayerContextAuthority:
		LayerContextAuthority.is_authority = false
		LayerContextAuthority.peer_id = multiplayer.get_unique_id()
	_ensure_puppet_root()
	print("[SoftENet] connected as ", multiplayer.get_unique_id())
	if GameManager:
		GameManager.toast_requested.emit("SoftENet connected · puppets on")

func _on_connection_failed() -> void:
	is_connected = false
	is_joining = false
	print("[SoftENet] connection failed")
	if GameManager:
		GameManager.toast_requested.emit("SoftENet connection failed")

func _on_server_disconnected() -> void:
	is_connected = false
	is_host = false
	is_joining = false
	_clear_puppets()
	print("[SoftENet] server disconnected")

func _maybe_cmdline_net() -> void:
	var args := OS.get_cmdline_user_args()
	print("[SoftENet] cmdline_user_args=", args)
	for a in args:
		if a == "--softnet-ws" or a == "softnet-ws":
			use_websocket = true
		if a == "--softnet-loopback" or a == "softnet-loopback":
			loopback_enabled = true
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
	if loopback_enabled:
		enable_loopback()


func enable_loopback() -> void:
	loopback_enabled = true
	is_host = true
	is_connected = true
	_ensure_puppet_root()
	print("[SoftENet] loopback peer enabled (puppet stress, no OS socket)")
	if GameManager:
		GameManager.toast_requested.emit("SoftENet loopback puppet on")


func _loopback_tick_process(delta: float) -> void:
	if not loopback_enabled:
		return
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	_loopback_tick += delta
	if _loopback_tick < 0.1:
		return
	_loopback_tick = 0.0
	_ensure_puppet_root()
	var pup = _get_or_create_puppet(LOOPBACK_PEER_ID)
	if pup == null or not pup.has_method("apply_state"):
		return
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
	var pos: Vector3 = _player_ref.global_position + Vector3(2.0, 0, 1.2)
	pup.call("apply_state", pos, _player_ref.rotation.y, form, fac)
