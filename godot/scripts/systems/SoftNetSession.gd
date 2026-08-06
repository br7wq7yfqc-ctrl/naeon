extends Node
## Soft local multiplayer prep — authority snapshots, optional ghost peer.
## No real net yet; validates LayerContextAuthority export/import + lag ghost.
## Never syncs combat power multipliers.

signal snapshot_published(snap: Dictionary)

var enabled: bool = true
var ghost_enabled: bool = true
var lag_ms: int = 120  ## simulated RTT half for ghost
var _history: Array = []  ## {t, snap}
var _player: Node3D = null
var _ghost: Node3D = null
var _tick: float = 0.0

func bind_player(p: Node3D) -> void:
	_player = p
	if ghost_enabled:
		call_deferred("_ensure_ghost")

func _ensure_ghost() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _ghost and is_instance_valid(_ghost):
		return
	var parent := _player.get_parent()
	if parent == null:
		return
	_ghost = Node3D.new()
	_ghost.name = "SoftNetGhost"
	parent.add_child(_ghost)
	# capsule body
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
	_ghost.global_position = _player.global_position + Vector3(1.5, 0, 1.5)
	print("[SoftNetSession] ghost spawned (local lag sim ", lag_ms, "ms)")

func _process(delta: float) -> void:
	if not enabled or _player == null or not is_instance_valid(_player):
		return
	_tick += delta
	if _tick < 0.05:
		return
	_tick = 0.0
	var snap := _capture()
	_history.append({"t": Time.get_ticks_msec(), "snap": snap})
	# trim 2s
	var now := Time.get_ticks_msec()
	while _history.size() > 0 and now - int(_history[0]["t"]) > 2000:
		_history.pop_front()
	snapshot_published.emit(snap)
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
	var ctx := {}
	if LayerContext:
		ctx = LayerContext.snapshot()
	var auth := {}
	if LayerContextAuthority:
		auth = LayerContextAuthority.export_bundle()
	return {
		"pos": [_player.global_position.x, _player.global_position.y, _player.global_position.z],
		"yaw": _player.rotation.y,
		"form": form,
		"faction": fac,
		"context": ctx,
		"authority": auth,
	}

func _apply_ghost(now_ms: int) -> void:
	if _ghost == null or not is_instance_valid(_ghost):
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
	# offset ghost slightly so it doesn't z-fight under player
	dest += Vector3(1.2, 0, 0.8)
	_ghost.global_position = _ghost.global_position.lerp(dest, 0.35)
	_ghost.rotation.y = float(s.get("yaw", 0.0))
