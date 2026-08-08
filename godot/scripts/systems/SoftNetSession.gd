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
	if not enabled or _player == null or not is_instance_valid(_player):
		return
	_tick += delta
	if _tick < SNAP_INTERVAL:
		return
	_tick = 0.0
	var snap := _capture()
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
	var form := ""
	var fac := "Cybernex"
	if "current_form" in _player:
		form = str(_player.current_form)
	elif "form_name" in _player:
		form = str(_player.form_name)
	if "faction" in _player:
		fac = str(_player.faction)
	# Lightweight — skip LayerContextAuthority bundle every tick (was heavy)
	var actor_mode := "pilot"
	var op_mode := 0
	var morph_t := 0.0
	var landed := false
	if "eva_mode" in _player and bool(_player.eva_mode):
		actor_mode = "eva"
	elif _player.is_in_group("ship") or str(_player.get_class()).find("Ship") >= 0 or _player.has_method("flight_mode_name"):
		actor_mode = "pilot"
		if "op_mode" in _player:
			op_mode = int(_player.op_mode)
		if "is_landed" in _player:
			landed = bool(_player.is_landed)
		var hm = _player.get_node_or_null("HullMorph")
		if hm and "morph_t" in hm:
			morph_t = float(hm.morph_t)
	elif _player.has_method("board"):
		actor_mode = "vehicle"
	else:
		actor_mode = "surface"
	return {
		"pos": [_player.global_position.x, _player.global_position.y, _player.global_position.z],
		"yaw": _player.rotation.y,
		"pitch": _player.rotation.x,
		"roll": _player.rotation.z,
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
