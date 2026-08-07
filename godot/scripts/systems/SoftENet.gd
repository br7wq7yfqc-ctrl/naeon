extends Node
## Soft multiplayer — primary transport: UDP soft protocol (pos/form/faction).
## ENet/WS kept as optional; UDP works headless on macOS.
## Never combat power / loot / P2W.

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal host_started(port: int)
signal joined(address: String, port: int)

const DEFAULT_PORT := 27700
const MAX_CLIENTS := 8
const _Puppet = preload("res://scripts/systems/SoftRemotePuppet.gd")

## Protocol magic + kinds
const MAGIC := "NAE1"
const KIND_HELLO := 1
const KIND_STATE := 2
const KIND_BYE := 3
const KIND_WELCOME := 4

var is_host: bool = false
var is_connected: bool = false
var is_joining: bool = false
var use_websocket: bool = false
var use_enet: bool = false  ## default false → UDP soft
var loopback_enabled: bool = false
var port: int = DEFAULT_PORT
var join_address: String = "127.0.0.1"
var local_peer_id: int = 1
var _next_client_id: int = 2

var _udp: PacketPeerUDP = null
var _peer: MultiplayerPeer = null  ## optional ENet/WS
var _broadcast_tick: float = 0.0
var _peer_log_tick: float = 0.0
var _loopback_tick: float = 0.0
var _hello_tick: float = 0.0
var _player_ref: Node3D = null
var _puppets: Dictionary = {}  ## peer_id -> Node3D
var _last_seen: Dictionary = {}  ## peer_id -> msec last STATE
const STALE_MS := 8000
var _puppet_root: Node3D = null
var _client_addrs: Dictionary = {}  ## peer_id -> {ip, port}
var _addr_to_id: Dictionary = {}  ## "ip:port" -> peer_id
const LOOPBACK_PEER_ID := 99

func _ready() -> void:
	if multiplayer:
		multiplayer.peer_connected.connect(_on_mp_peer_connected)
		multiplayer.peer_disconnected.connect(_on_mp_peer_disconnected)
		multiplayer.connected_to_server.connect(_on_mp_connected_ok)
		multiplayer.connection_failed.connect(_on_mp_connection_failed)
		multiplayer.server_disconnected.connect(_on_mp_server_disconnected)
	call_deferred("_maybe_cmdline_net")

func bind_player(p: Node3D) -> void:
	_player_ref = p if p != null and is_instance_valid(p) else null


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

func _transport_name() -> String:
	if loopback_enabled and _udp == null and _peer == null:
		return "loopback"
	if use_websocket:
		return "ws"
	if use_enet:
		return "enet"
	return "udp"

func host(p: int = -1) -> Error:
	if p < 0:
		p = DEFAULT_PORT
	port = p
	if use_enet or use_websocket:
		return _host_multiplayer(p)
	return _host_udp(p)

func join(address: String = "127.0.0.1", p: int = -1) -> Error:
	if p < 0:
		p = DEFAULT_PORT
	port = p
	join_address = address
	if use_enet or use_websocket:
		return _join_multiplayer(address, p)
	return _join_udp(address, p)

func _host_udp(p: int) -> Error:
	_close_transport()
	_udp = PacketPeerUDP.new()
	var err := _udp.bind(p, "*")
	if err != OK:
		# fallback localhost bind
		err = _udp.bind(p, "127.0.0.1")
	if err != OK:
		push_warning("[SoftENet] UDP host bind failed: %s" % err)
		if GameManager:
			GameManager.toast_requested.emit("SoftENet UDP host failed (%s)" % err)
		_udp = null
		return err
	is_host = true
	is_connected = true
	is_joining = false
	local_peer_id = 1
	_next_client_id = 2
	_client_addrs.clear()
	_addr_to_id.clear()
	_ensure_puppet_root()
	host_started.emit(p)
	print("[SoftENet] host port=", p, " unique_id=1 transport=udp bind_ok")
	if SoftNetSession and SoftNetSession.has_method("enable"):
		SoftNetSession.enable(true, false)
	_write_host_info(p)
	if GameManager:
		GameManager.toast_requested.emit("SoftENet UDP HOST :%d" % p)
	return OK

func _join_udp(address: String, p: int) -> Error:
	_close_transport()
	_udp = PacketPeerUDP.new()
	# ephemeral local bind
	var err := _udp.bind(0)
	if err != OK:
		push_warning("[SoftENet] UDP client bind failed: %s" % err)
		_udp = null
		return err
	err = _udp.set_dest_address(address, p)
	if err != OK:
		push_warning("[SoftENet] UDP set_dest failed: %s" % err)
		_udp = null
		return err
	is_host = false
	is_joining = true
	is_connected = false
	local_peer_id = 0
	_ensure_puppet_root()
	_send_hello()
	print("[SoftENet] joining ", address, ":", p, " transport=udp")
	if GameManager:
		GameManager.toast_requested.emit("SoftENet UDP joining %s:%d…" % [address, p])
	return OK

func _host_multiplayer(p: int) -> Error:
	_close_transport()
	var err: Error
	if use_websocket:
		var ws := WebSocketMultiplayerPeer.new()
		err = ws.create_server(p, "*")
		_peer = ws
	else:
		var enet := ENetMultiplayerPeer.new()
		err = enet.create_server(p, MAX_CLIENTS)
		_peer = enet
	if err != OK:
		push_warning("[SoftENet] host failed: %s" % err)
		return err
	multiplayer.multiplayer_peer = _peer
	is_host = true
	is_connected = true
	local_peer_id = 1
	_ensure_puppet_root()
	host_started.emit(p)
	print("[SoftENet] host port=", p, " transport=", _transport_name())
	return OK

func _join_multiplayer(address: String, p: int) -> Error:
	_close_transport()
	var err: Error
	if use_websocket:
		var ws := WebSocketMultiplayerPeer.new()
		var url := address if address.begins_with("ws") else "ws://%s:%d" % [address, p]
		err = ws.create_client(url)
		_peer = ws
	else:
		var enet := ENetMultiplayerPeer.new()
		err = enet.create_client(address, p)
		_peer = enet
	if err != OK:
		return err
	multiplayer.multiplayer_peer = _peer
	is_host = false
	is_joining = true
	print("[SoftENet] joining ", address, ":", p, " transport=", _transport_name())
	return OK

func leave() -> void:
	if _udp and is_connected:
		_send_raw({"k": KIND_BYE, "id": local_peer_id})
	_clear_puppets()
	_close_transport()
	is_host = false
	is_connected = false
	is_joining = false
	loopback_enabled = false
	print("[SoftENet] left session")
	if SoftNetSession and SoftNetSession.has_method("enable"):
		SoftNetSession.enable(false, false)
	if GameManager:
		GameManager.toast_requested.emit("SoftENet left")

func _close_transport() -> void:
	if _udp:
		_udp.close()
		_udp = null
	if multiplayer and multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	_peer = null
	_client_addrs.clear()
	_addr_to_id.clear()

func status_line() -> String:
	if not is_connected and not is_host and not is_joining and not loopback_enabled:
		return "NET off"
	var n := _puppets.size()
	if is_host:
		n = _client_addrs.size() if _udp else (multiplayer.get_peers().size() if multiplayer.multiplayer_peer else 0)
	var st := "HOST" if is_host else ("JOIN" if is_joining else ("LOOP" if loopback_enabled else "CLIENT"))
	return "NET %s peers=%d puppets=%d :%d %s" % [st, n, _puppets.size(), port, _transport_name()]

func enable_loopback() -> void:
	if loopback_enabled and _puppets.has(LOOPBACK_PEER_ID):
		return
	loopback_enabled = true
	is_host = true
	is_connected = true
	local_peer_id = 1
	_ensure_puppet_root()
	print("[SoftENet] loopback peer enabled (puppet stress, no OS socket)")
	if GameManager:
		GameManager.toast_requested.emit("SoftNet LOOP — ghost peer (visual only, no combat)")

func _process(delta: float) -> void:
	_poll_udp()
	_loopback_tick_process(delta)
	_prune_stale()
	if not is_connected and not is_host and not is_joining and not loopback_enabled:
		return
	_peer_log_tick += delta
	if _peer_log_tick >= 8.0:
		_peer_log_tick = 0.0
		if OS.is_debug_build():
			print("[SoftENet] ", status_line(), " local_id=", local_peer_id)
	if is_joining and _udp:
		_hello_tick += delta
		if _hello_tick >= 0.5:
			_hello_tick = 0.0
			_send_hello()
	if not is_connected and not is_host and not loopback_enabled:
		return
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	_broadcast_tick += delta
	if _broadcast_tick < 0.1:
		return
	_broadcast_tick = 0.0
	_broadcast_state()

func _broadcast_state() -> void:
	var form := "Canine"
	var fac := "Cybernex"
	var mode := ""
	var landed := 0
	if "current_form" in _player_ref:
		form = str(_player_ref.current_form)
	elif "form_name" in _player_ref:
		form = str(_player_ref.form_name)
	elif _player_ref.is_in_group("ship"):
		form = "Ship"
	if "faction" in _player_ref:
		fac = str(_player_ref.faction)
	if _player_ref.is_in_group("ship"):
		if is_instance_valid(_player_ref) and _player_ref.has_method("flight_mode_name"):
			mode = str(_player_ref.flight_mode_name())
		elif "flight_mode" in _player_ref:
			mode = str(_player_ref.flight_mode)
		if "is_landed" in _player_ref:
			landed = 1 if bool(_player_ref.is_landed) else 0
	var pos: Vector3 = _player_ref.global_position
	var yaw: float = _player_ref.rotation.y
	var pitch := 0.0
	var roll := 0.0
	if "rotation" in _player_ref:
		pitch = _player_ref.rotation.x
		roll = _player_ref.rotation.z
	var op_mode := 0
	var morph_t := 0.0
	var actor_mode := "surface"
	if "op_mode" in _player_ref:
		op_mode = int(_player_ref.op_mode)
	if _player_ref.has_method("flight_mode_name") or _player_ref.is_in_group("ship"):
		actor_mode = "pilot"
	elif "eva_mode" in _player_ref and bool(_player_ref.eva_mode):
		actor_mode = "eva"
	var hm = _player_ref.get_node_or_null("HullMorph")
	if hm and "morph_t" in hm:
		morph_t = float(hm.morph_t)
	if _udp and (is_host or is_connected):
		_send_raw({
			"k": KIND_STATE,
			"id": local_peer_id,
			"x": pos.x, "y": pos.y, "z": pos.z,
			"yaw": yaw, "pitch": pitch, "roll": roll,
			"form": form, "fac": fac, "mode": mode, "landed": landed,
			"op": op_mode, "morph": morph_t, "amode": actor_mode,
		})
	elif _peer and multiplayer.multiplayer_peer and (is_host or is_connected):
		rpc_soft_state_ex.rpc(pos.x, pos.y, pos.z, yaw, pitch, roll, form, fac, mode, landed, op_mode, morph_t, actor_mode)

func _send_hello() -> void:
	_send_raw({"k": KIND_HELLO, "id": 0, "name": "client"})

func _send_raw(data: Dictionary) -> void:
	if _udp == null:
		return
	data["m"] = MAGIC
	var payload := JSON.stringify(data).to_utf8_buffer()
	if is_host:
		# fan-out to known clients
		for pid in _client_addrs.keys():
			var info: Dictionary = _client_addrs[pid]
			_udp.set_dest_address(str(info["ip"]), int(info["port"]))
			_udp.put_packet(payload)
	else:
		_udp.put_packet(payload)

func _poll_udp() -> void:
	if _udp == null:
		return
	while _udp.get_available_packet_count() > 0:
		var pkt: PackedByteArray = _udp.get_packet()
		var ip := _udp.get_packet_ip()
		var pport := _udp.get_packet_port()
		var text := pkt.get_string_from_utf8()
		var parsed = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = parsed
		if str(d.get("m", "")) != MAGIC:
			continue
		var kind := int(d.get("k", 0))
		if is_host:
			_handle_host_packet(kind, d, ip, pport)
		else:
			_handle_client_packet(kind, d)

func _handle_host_packet(kind: int, d: Dictionary, ip: String, pport: int) -> void:
	var key := "%s:%d" % [ip, pport]
	if kind == KIND_HELLO:
		var pid: int
		if _addr_to_id.has(key):
			pid = int(_addr_to_id[key])
		else:
			if _client_addrs.size() >= MAX_CLIENTS:
				return
			pid = _next_client_id
			_next_client_id += 1
			_addr_to_id[key] = pid
			_client_addrs[pid] = {"ip": ip, "port": pport}
			print("[SoftENet] peer +", pid, " from ", key)
			peer_connected.emit(pid)
			_ensure_puppet_root()
			_get_or_create_puppet(pid)
			if GameManager:
				GameManager.toast_requested.emit("Peer +%d (UDP)" % pid)
		# welcome
		_udp.set_dest_address(ip, pport)
		var welcome := JSON.stringify({"m": MAGIC, "k": KIND_WELCOME, "id": pid}).to_utf8_buffer()
		_udp.put_packet(welcome)
		return
	if kind == KIND_STATE:
		var pid2 := int(d.get("id", 0))
		if pid2 <= 1:
			# map by addr if needed
			if _addr_to_id.has(key):
				pid2 = int(_addr_to_id[key])
			else:
				return
		# refresh addr
		_client_addrs[pid2] = {"ip": ip, "port": pport}
		_addr_to_id[key] = pid2
		_apply_remote_state(pid2, d)
		# relay to other clients
		_relay_state_except(pid2, d)
		return
	if kind == KIND_BYE:
		var pid3 := int(d.get("id", 0))
		if _addr_to_id.has(key):
			pid3 = int(_addr_to_id[key])
		_drop_peer(pid3, key)

func _relay_state_except(except_id: int, d: Dictionary) -> void:
	if _udp == null:
		return
	d["m"] = MAGIC
	var payload := JSON.stringify(d).to_utf8_buffer()
	for pid in _client_addrs.keys():
		if int(pid) == except_id:
			continue
		var info: Dictionary = _client_addrs[pid]
		_udp.set_dest_address(str(info["ip"]), int(info["port"]))
		_udp.put_packet(payload)

func _handle_client_packet(kind: int, d: Dictionary) -> void:
	if kind == KIND_WELCOME:
		local_peer_id = int(d.get("id", 2))
		is_connected = true
		is_joining = false
		joined.emit(join_address, port)
		print("[SoftENet] connected as ", local_peer_id, " transport=udp")
		if SoftNetSession and SoftNetSession.has_method("enable"):
			SoftNetSession.enable(true, false)
		if GameManager:
			GameManager.toast_requested.emit("SoftENet UDP connected id=%d" % local_peer_id)
		return
	if kind == KIND_STATE:
		var pid := int(d.get("id", 0))
		if pid == local_peer_id or pid == 0:
			return
		_apply_remote_state(pid, d)

func _apply_remote_state(pid: int, d: Dictionary) -> void:
	_ensure_puppet_root()
	var pup = _get_or_create_puppet(pid)
	if pup == null or not pup.has_method("apply_state"):
		return
	var pos := Vector3(float(d.get("x", 0)), float(d.get("y", 0)), float(d.get("z", 0)))
	var yaw := float(d.get("yaw", 0))
	var form := str(d.get("form", "Canine"))
	var fac := str(d.get("fac", "Cybernex"))
	var mode := str(d.get("mode", ""))
	var landed := int(d.get("landed", 0)) == 1
	var pitch := float(d.get("pitch", 0.0))
	var roll := float(d.get("roll", 0.0))
	if pup.has_method("apply_state_ex"):
		pup.call("apply_state_ex", pos, yaw, pitch, roll, form, fac, mode, landed)
	else:
		pup.call("apply_state", pos, yaw, form, fac)
	if pup.has_method("apply_soft_extra"):
		pup.call("apply_soft_extra", int(d.get("op", 0)), float(d.get("morph", 0.0)), str(d.get("amode", "surface")))
	_last_seen[pid] = Time.get_ticks_msec()

func _drop_peer(pid: int, key: String) -> void:
	if _puppets.has(pid):
		var p = _puppets[pid]
		if p and is_instance_valid(p):
			p.queue_free()
		_puppets.erase(pid)
	_client_addrs.erase(pid)
	_addr_to_id.erase(key)
	print("[SoftENet] peer -", pid)
	peer_disconnected.emit(pid)

func _get_or_create_puppet(id: int) -> Node3D:
	if _puppets.has(id) and is_instance_valid(_puppets[id]):
		return _puppets[id]
	if _puppet_root == null or not is_instance_valid(_puppet_root):
		return null
	if _puppet_root.get_parent() == null:
		# wait deferred attach
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
	_last_seen.clear()

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
	if pup == null:
		return
	# Mirror continuum fields for local visual stress (no network, no combat)
	var form := "Canine"
	var fac := "Cybernex"
	var mode := ""
	var landed := false
	if "current_form" in _player_ref:
		form = str(_player_ref.current_form)
	elif "form_name" in _player_ref:
		form = str(_player_ref.form_name)
	elif _player_ref.is_in_group("ship"):
		form = "Ship"
	if "faction" in _player_ref:
		fac = str(_player_ref.faction)
	if form == "Ship" and _player_ref.has_method("flight_mode_name"):
		mode = str(_player_ref.flight_mode_name())
	if "is_landed" in _player_ref:
		landed = bool(_player_ref.is_landed)
	var op_mode := 0
	var morph_t := 0.0
	var amode := "surface"
	if "op_mode" in _player_ref:
		op_mode = int(_player_ref.op_mode)
	if form == "Ship":
		amode = "pilot"
	elif "eva_mode" in _player_ref and bool(_player_ref.eva_mode):
		amode = "eva"
	var hm = _player_ref.get_node_or_null("HullMorph")
	if hm and "morph_t" in hm:
		morph_t = float(hm.morph_t)
	# Soft orbit offset so ghost is readable beside local actor
	var tsec := Time.get_ticks_msec() * 0.001
	var orbit := Vector3(cos(tsec * 0.7) * 2.4, 0.15, sin(tsec * 0.7) * 2.4)
	var pos: Vector3 = _player_ref.global_position + orbit
	var yaw: float = _player_ref.rotation.y + 0.4
	var pitch: float = _player_ref.rotation.x
	var roll: float = _player_ref.rotation.z
	if pup.has_method("apply_state_ex"):
		pup.call("apply_state_ex", pos, yaw, pitch, roll, form, fac, mode, landed)
	elif pup.has_method("apply_state"):
		pup.call("apply_state", pos, yaw, form, fac)
	if pup.has_method("apply_soft_extra"):
		pup.call("apply_soft_extra", op_mode, morph_t, amode)
	_last_seen[LOOPBACK_PEER_ID] = Time.get_ticks_msec()

@rpc("any_peer", "unreliable_ordered")
func rpc_soft_state(x: float, y: float, z: float, yaw: float, form: String, faction: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0 or sender == multiplayer.get_unique_id():
		return
	_apply_remote_state(sender, {"x": x, "y": y, "z": z, "yaw": yaw, "form": form, "fac": faction})


@rpc("any_peer", "unreliable_ordered")
func rpc_soft_state_ex(
	x: float, y: float, z: float, yaw: float, pitch: float, roll: float,
	form: String, faction: String, mode: String, landed: int,
	op_mode: int, morph_t: float, amode: String
) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0 or sender == multiplayer.get_unique_id():
		return
	_apply_remote_state(sender, {
		"x": x, "y": y, "z": z, "yaw": yaw, "pitch": pitch, "roll": roll,
		"form": form, "fac": faction, "mode": mode, "landed": landed,
		"op": op_mode, "morph": morph_t, "amode": amode,
	})

func _on_mp_peer_connected(id: int) -> void:
	print("[SoftENet] mp peer +", id)
	peer_connected.emit(id)

func _on_mp_peer_disconnected(id: int) -> void:
	if _puppets.has(id):
		var p = _puppets[id]
		if p and is_instance_valid(p):
			p.queue_free()
		_puppets.erase(id)
	peer_disconnected.emit(id)

func _on_mp_connected_ok() -> void:
	is_connected = true
	is_joining = false
	local_peer_id = multiplayer.get_unique_id()
	print("[SoftENet] connected as ", local_peer_id)

func _on_mp_connection_failed() -> void:
	is_connected = false
	is_joining = false
	print("[SoftENet] connection failed")

func _on_mp_server_disconnected() -> void:
	is_connected = false
	is_host = false
	_clear_puppets()
	print("[SoftENet] server disconnected")


func _write_host_info(p: int) -> void:
	var ips: PackedStringArray = IP.get_local_addresses()
	var lines: PackedStringArray = []
	lines.append("port=%d" % p)
	lines.append("transport=udp")
	for ip in ips:
		var s := str(ip)
		if s.begins_with("127.") or ":" in s:
			continue
		lines.append(s)
	var f := FileAccess.open("user://softnet_host_info.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines) + "\n")
		print("[SoftENet] wrote user://softnet_host_info.txt lines=", lines.size())


func peer_ids() -> Array:
	var out: Array = []
	if is_host:
		for k in _client_addrs.keys():
			out.append(int(k))
	for k in _puppets.keys():
		var id := int(k)
		if id not in out:
			out.append(id)
	return out

func _maybe_cmdline_net() -> void:
	var args := OS.get_cmdline_user_args()
	print("[SoftENet] cmdline_user_args=", args)
	for a in args:
		if a == "--softnet-ws" or a == "softnet-ws":
			use_websocket = true
			use_enet = false
		if a == "--softnet-enet" or a == "softnet-enet":
			use_enet = true
			use_websocket = false
		if a == "--softnet-loopback" or a == "softnet-loopback":
			loopback_enabled = true
		if a.begins_with("--softnet-join=") or a.begins_with("softnet-join="):
			join_address = a.split("=", true, 1)[1]
	for a in args:
		if a == "--softnet-host" or a == "softnet-host":
			host()
			return
		if a.begins_with("--softnet-join=") or a.begins_with("softnet-join=") or a == "--softnet-join" or a == "softnet-join":
			join(join_address if join_address != "" else "127.0.0.1")
			return
	if loopback_enabled:
		enable_loopback()



func _prune_stale() -> void:
	if _last_seen.is_empty():
		return
	var now := Time.get_ticks_msec()
	var drop: Array = []
	for pid in _last_seen.keys():
		if now - int(_last_seen[pid]) > STALE_MS:
			drop.append(int(pid))
	for pid in drop:
		_last_seen.erase(pid)
		if _puppets.has(pid):
			var p = _puppets[pid]
			if p and is_instance_valid(p):
				p.queue_free()
			_puppets.erase(pid)
			print("[SoftENet] stale drop ", pid)
