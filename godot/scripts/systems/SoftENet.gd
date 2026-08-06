extends Node
## Soft ENet multiplayer bootstrap (code-first).
## Host/join on local LAN; state = form/faction/pos only — no combat power.
## Holistic: authority via LayerContextAuthority; soft WS never becomes P2W.

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal host_started(port: int)
signal joined(address: String, port: int)

const DEFAULT_PORT := 27700
const MAX_CLIENTS := 8

var is_host: bool = false
var is_connected: bool = false
var port: int = DEFAULT_PORT
var _peer: MultiplayerPeer = null

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

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
	host_started.emit(port)
	if GameManager:
		GameManager.toast_requested.emit("SoftENet host :%d (soft state only)" % port)
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
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	_peer = null
	is_host = false
	is_connected = false
	print("[SoftENet] left session")

func status_line() -> String:
	if not is_connected and not is_host:
		return "NET off"
	var n := 0
	if multiplayer.multiplayer_peer:
		n = multiplayer.get_peers().size()
	return "NET %s peers=%d :%d" % ["HOST" if is_host else "CLIENT", n, port]

func _on_peer_connected(id: int) -> void:
	print("[SoftENet] peer +", id)
	peer_connected.emit(id)
	if GameManager:
		GameManager.toast_requested.emit("Peer connected id=%d" % id)

func _on_peer_disconnected(id: int) -> void:
	print("[SoftENet] peer -", id)
	peer_disconnected.emit(id)

func _on_connected_ok() -> void:
	is_connected = true
	joined.emit("remote", port)
	if LayerContextAuthority:
		LayerContextAuthority.is_authority = false
		LayerContextAuthority.peer_id = multiplayer.get_unique_id()
	print("[SoftENet] connected as ", multiplayer.get_unique_id())
	if GameManager:
		GameManager.toast_requested.emit("SoftENet connected (client)")

func _on_connection_failed() -> void:
	is_connected = false
	print("[SoftENet] connection failed")
	if GameManager:
		GameManager.toast_requested.emit("SoftENet connection failed")

func _on_server_disconnected() -> void:
	is_connected = false
	is_host = false
	print("[SoftENet] server disconnected")

## Soft state channel (pos/form/faction only — never combat power)
var _broadcast_tick: float = 0.0
var _player_ref: Node3D = null

func bind_player(p: Node3D) -> void:
	_player_ref = p

func _process(delta: float) -> void:
	if not is_connected and not is_host:
		return
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	_broadcast_tick += delta
	if _broadcast_tick < 0.1:
		return
	_broadcast_tick = 0.0
	var form := ""
	var fac := "Cybernex"
	if "current_form" in _player_ref:
		form = str(_player_ref.current_form)
	elif "form_name" in _player_ref:
		form = str(_player_ref.form_name)
	if "faction" in _player_ref:
		fac = str(_player_ref.faction)
	var pos: Vector3 = _player_ref.global_position
	rpc_soft_state.rpc(pos.x, pos.y, pos.z, _player_ref.rotation.y, form, fac)

@rpc("any_peer", "unreliable_ordered")
func rpc_soft_state(x: float, y: float, z: float, yaw: float, form: String, faction: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	# Visual-only remote proxies later; log for now
	if sender != multiplayer.get_unique_id():
		# swallow — SoftNetSession ghost remains local lag sim until full puppet system
		pass
