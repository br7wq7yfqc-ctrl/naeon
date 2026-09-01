extends Node
## Soft local multiplayer prep — authority snapshots, optional ghost peer.
## DEFAULT OFF — was allocating Dictionary snapshots @20Hz (FPS killer / GC pressure).
## Enable via --softnet-loopback or SoftENet host/join or SoftNetSession.enable().

signal snapshot_published(snap: Dictionary)

var enabled: bool = false
var ghost_enabled: bool = false
var lag_ms: int = 120
var _history: Array = []
var _player: Node3D = null
var _ghost: Node3D = null
var _tick: float = 0.0
var _ghost_pending: bool = false
## AR-F / AR-G / IN-F / SN-A: pose-only slots. Host keeps combat / rover / occupy. Do not enable() for these.
var _visual_puppets: Array = []
const SNAP_INTERVAL := 0.4   ## soft net rare; GC safe
const HISTORY_MS := 1500

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a == "--softnet-loopback" or a == "softnet-loopback":
			enable(true, true)
	# SoftENet may enable when session starts
	if SoftENet:
		if SoftENet.has_signal("host_started"):
			SoftENet.host_started.connect(func(_p): enable(true, false))
		if SoftENet.has_signal("joined"):
			SoftENet.joined.connect(func(_a, _p): enable(true, false))

func enable(on: bool = true, with_ghost: bool = false) -> void:
	enabled = on
	ghost_enabled = with_ghost and on
	if not on:
		_history.clear()
		if _ghost and is_instance_valid(_ghost):
			_ghost.queue_free()
			_ghost = null
		print("[SoftNetSession] disabled (perf)")
		set_process(false)
	else:
		print("[SoftNetSession] enabled ghost=", ghost_enabled)
		set_process(true)
		if ghost_enabled and _player:
			_ghost_pending = true
			call_deferred("_ensure_ghost")

func bind_visual_puppet(n: Node3D) -> void:
	## Clash bot / NPC slot: visual pose only. Never grants combat authority.
	if n == null or not is_instance_valid(n):
		return
	n.set_meta("softnet_visual", true)
	n.set_meta("combat_authority", "host")
	_prune_visual_puppets()
	for e in _visual_puppets:
		if e == n:
			return
	_visual_puppets.append(n)


func visual_puppet_count() -> int:
	_prune_visual_puppets()
	return _visual_puppets.size()


func is_visual_puppet(n: Node) -> bool:
	return n != null and is_instance_valid(n) and bool(n.get_meta("softnet_visual", false))


func combat_authority() -> String:
	return "host"


func _prune_visual_puppets() -> void:
	var keep: Array = []
	for e in _visual_puppets:
		if e != null and is_instance_valid(e):
			keep.append(e)
	_visual_puppets = keep


func bind_player(p: Node3D) -> void:
	_player = p if p != null and is_instance_valid(p) else null
	if SoftENet and SoftENet.has_method("bind_player"):
		SoftENet.bind_player(_player)
	if _player == null:
		_history.clear()
		return
	if enabled and ghost_enabled:
		_ghost_pending = true
		get_tree().create_timer(0.05).timeout.connect(_ensure_ghost)


func _ensure_ghost() -> void:
	if not _ghost_pending or not ghost_enabled:
		return
	if _player == null or not is_instance_valid(_player):
		return
	if _ghost and is_instance_valid(_ghost):
		_ghost_pending = false
		return
	var parent := _player.get_parent()
	if parent == null:
		call_deferred("_ensure_ghost")
		return
	_ghost = Node3D.new()
	_ghost.name = "SoftNetGhost"
	parent.add_child.call_deferred(_ghost)
	call_deferred("_finish_ghost_visual")
	_ghost_pending = false

func _finish_ghost_visual() -> void:
	if _ghost == null or not is_instance_valid(_ghost):
		return
	if _ghost.get_child_count() > 0:
		return
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.2
	mi.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.85, 1.0, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.7, 1.0)
	mat.emission_energy_multiplier = 1.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.position = Vector3(0, 0.9, 0)
	_ghost.add_child(mi)
	var lab := Label3D.new()
	lab.text = "PEER GHOST (soft net)"
	lab.font_size = 28
	lab.modulate = Color(0.6, 0.95, 1.0, 0.8)
	lab.position = Vector3(0, 2.0, 0)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_ghost.add_child(lab)
	if _player and is_instance_valid(_player):
		_ghost.global_position = _player.global_position + Vector3(1.5, 0, 1.5)

func _process(delta: float) -> void:
	if not enabled:
		return
	if _player == null or not is_instance_valid(_player):
		_player = null
		return
	_tick += delta
	if _tick < SNAP_INTERVAL:
		return
	_tick = 0.0
	var snap := _capture()
	if snap.is_empty():
		return
	_history.append({"t": Time.get_ticks_msec(), "snap": snap})
	var now := Time.get_ticks_msec()
	while _history.size() > 0 and now - int(_history[0]["t"]) > HISTORY_MS:
		_history.pop_front()
	# Cap hard (GC safety)
	while _history.size() > 12:
		_history.pop_front()
	snapshot_published.emit(snap)
	if ghost_enabled:
		_apply_ghost(now)

func _capture() -> Dictionary:
	if _player == null or not is_instance_valid(_player):
		_player = null
		return {}
	var p: Node3D = _player
	var form := ""
	var fac := "Cybernex"
	if "current_form" in p:
		form = str(p.current_form)
	elif "form_name" in p:
		form = str(p.form_name)
	if "faction" in p:
		fac = str(p.faction)
	# Lightweight — skip LayerContextAuthority bundle every tick (was heavy)
	var actor_mode := "pilot"
	var op_mode := 0
	var morph_t := 0.0
	var landed := false
	if "eva_mode" in p and bool(p.eva_mode):
		actor_mode = "eva"
	elif p.is_in_group("ship") or str(p.get_class()).find("Ship") >= 0:
		actor_mode = "pilot"
		if "op_mode" in p:
			op_mode = int(p.op_mode)
		if "is_landed" in p:
			landed = bool(p.is_landed)
		var hm = p.get_node_or_null("HullMorph")
		if hm != null and is_instance_valid(hm) and "morph_t" in hm:
			morph_t = float(hm.morph_t)
	elif p.is_in_group("ground_vehicle"):
		actor_mode = "vehicle"
	else:
		actor_mode = "surface"
	return {
		"pos": [p.global_position.x, p.global_position.y, p.global_position.z],
		"yaw": p.rotation.y,
		"pitch": p.rotation.x,
		"roll": p.rotation.z,
		"form": form,
		"faction": fac,
		"actor_mode": actor_mode,
		"op_mode": op_mode,
		"morph_t": morph_t,
		"landed": landed,
	}

func _apply_ghost(now_ms: int) -> void:
	if _ghost == null or not is_instance_valid(_ghost):
		return
	if _ghost.get_parent() == null:
		return
	var target_t := now_ms - lag_ms
	var best: Dictionary = {}
	for h in _history:
		if int(h["t"]) <= target_t:
			best = h
		else:
			break
	if best.is_empty():
		return
	var s: Dictionary = best["snap"]
	var p: Array = s.get("pos", [0, 0, 0])
	var dest := Vector3(float(p[0]), float(p[1]), float(p[2]))
	dest += Vector3(1.2, 0, 0.8)
	_ghost.global_position = _ghost.global_position.lerp(dest, 0.35)
	_ghost.rotation.y = float(s.get("yaw", 0.0))
