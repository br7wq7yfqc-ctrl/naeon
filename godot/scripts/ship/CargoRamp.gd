extends Node3D
class_name CargoRamp
## Deployable cargo ramp. Hidden when stowed (was a black monolith under scout hulls).
## IN-C: hangar plates are walkable. BLOCKED is a refuse, not a parked state.

signal state_changed(state: String)

enum State { STOWED, DEPLOYING, DEPLOYED, STOWING }

const MAX_HOVER_AGL := 8.0
const MAX_DEPLOY_SPEED := 5.0
const DEPLOY_DEG := 28.0

var state: int = State.STOWED
var last_block_reason: String = ""
var _mesh: MeshInstance3D
var _body: StaticBody3D
var _plates: Array = []
var _angle: float = 0.0
var _tween: Tween

@export var deploy_sec: float = 1.1
@export var ramp_length: float = 8.0
@export var ramp_width: float = 4.0

func _ready() -> void:
	set_meta("site_pin", "")
	_build()
	_apply_angle(0.0)


func _build() -> void:
	var hangar := _is_hangar_ramp()
	if hangar:
		_build_hangar_plates()
		position = Vector3.ZERO
		return
	var plate := Vector3(ramp_width, 0.12, ramp_length)
	if DisplayServer.get_name() != "headless":
		_mesh = MeshInstance3D.new()
		_mesh.name = "RampPlate"
		var box := BoxMesh.new()
		box.size = plate
		_mesh.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.38, 0.42)
		mat.metallic = 0.55
		mat.roughness = 0.45
		_mesh.material_override = mat
		add_child(_mesh)
		_try_glb_skin()
	_body = StaticBody3D.new()
	_body.collision_layer = 0
	_body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = plate
	cs.shape = sh
	_body.add_child(cs)
	if _mesh:
		_mesh.add_child(_body)
		_mesh.position = Vector3(0, 0, ramp_length * 0.5)
	else:
		add_child(_body)
		_body.position = Vector3(0, 0, ramp_length * 0.5)
	# hinge at ship belly-aft, not hanging mid-hull
	position = Vector3(0, -0.35, 1.2)


func _build_hangar_plates() -> void:
	## Three procedural plates from hangar_bay mouth toward the pad/deck. 0 Tripo.
	var old: Node = get_node_or_null("Plates")
	if old != null:
		old.free()
	_plates.clear()
	_mesh = null
	_body = null
	var root := Node3D.new()
	root.name = "Plates"
	add_child(root)
	var n := 3
	var seg_z: float = ramp_length / float(n)
	for i in n:
		var z0: float = seg_z * (float(i) + 0.5)
		var holder := Node3D.new()
		holder.name = "RampPlate_%d" % i
		holder.position = Vector3(0, 0, z0)
		root.add_child(holder)
		if DisplayServer.get_name() != "headless":
			var mi := MeshInstance3D.new()
			mi.name = "Mesh"
			var box := BoxMesh.new()
			box.size = Vector3(ramp_width, 0.14, seg_z * 0.98)
			mi.mesh = box
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.34, 0.37, 0.41)
			mat.metallic = 0.5
			mat.roughness = 0.48
			mat.emission_enabled = true
			mat.emission = Color(0.18, 0.42, 0.55)
			mat.emission_energy_multiplier = 0.35
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(mi)
			if i == 0:
				_mesh = mi
		var sb := StaticBody3D.new()
		sb.name = "Body"
		sb.collision_layer = 0
		sb.collision_mask = 0
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(ramp_width, 0.14, seg_z * 0.98)
		cs.shape = sh
		sb.add_child(cs)
		holder.add_child(sb)
		_plates.append(sb)
		if i == 0:
			_body = sb


func layout_to_deck(deck_pos: Vector3) -> void:
	if not _is_hangar_ramp():
		return
	var dist: float = global_position.distance_to(deck_pos)
	var next_len: float = clampf(dist, 5.0, 16.0)
	if absf(next_len - ramp_length) < 0.15 and get_node_or_null("Plates") != null:
		return
	ramp_length = next_len
	_build_hangar_plates()
	_apply_angle(_angle)


func try_deploy() -> String:
	## Gate: landed OR hover < 8 m AGL OR docked; speed < 5. Else BLOCKED toast.
	last_block_reason = block_reason()
	if last_block_reason != "":
		if state == State.DEPLOYING or state == State.DEPLOYED:
			stow()
		_toast_blocked(last_block_reason)
		state_changed.emit("BLOCKED")
		print("[CargoRamp] BLOCKED ", last_block_reason)
		return "BLOCKED"
	if state == State.DEPLOYED:
		return "DEPLOYED"
	deploy()
	return "DEPLOYING"


func block_reason() -> String:
	var host: Node = _pose_host()
	if host == null:
		return ""
	var speed := 0.0
	var agl := 9999.0
	var landed := false
	var docked := false
	if host.has_method("hull_speed"):
		speed = float(host.hull_speed())
	elif "velocity" in host and host.velocity is Vector3:
		speed = (host.velocity as Vector3).length()
	if host.has_method("altitude_agl"):
		agl = float(host.altitude_agl())
	if host.has_method("is_landed"):
		landed = bool(host.is_landed())
	elif "is_landed" in host:
		landed = bool(host.is_landed)
	if host.has_method("is_docked"):
		docked = bool(host.is_docked())
	if speed >= MAX_DEPLOY_SPEED:
		return "too fast"
	if landed or docked:
		return ""
	if agl < MAX_HOVER_AGL:
		return ""
	if agl >= MAX_HOVER_AGL:
		return "too high"
	return "not landed/hover/docked"


func toggle() -> void:
	if state == State.STOWED or state == State.STOWING:
		if _pose_host() != null:
			try_deploy()
		else:
			deploy()
	else:
		stow()


func deploy() -> void:
	if state == State.DEPLOYED or state == State.DEPLOYING:
		return
	state = State.DEPLOYING
	visible = true
	state_changed.emit("DEPLOYING")
	_animate_to(1.0, deploy_sec, State.DEPLOYED)


func stow() -> void:
	if state == State.STOWED or state == State.STOWING:
		return
	state = State.STOWING
	state_changed.emit("STOWING")
	_animate_to(0.0, deploy_sec * 0.85, State.STOWED)


func stow_immediate() -> void:
	if _tween and is_instance_valid(_tween):
		_tween.kill()
	state = State.STOWED
	_apply_angle(0.0)
	visible = false
	state_changed.emit("STOWED")


func deploy_immediate() -> void:
	if _tween and is_instance_valid(_tween):
		_tween.kill()
	state = State.DEPLOYED
	visible = true
	_apply_angle(1.0)
	state_changed.emit("DEPLOYED")


func _animate_to(target: float, sec: float, end_state: int) -> void:
	if _tween and is_instance_valid(_tween):
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_apply_angle, _angle, target, maxf(sec, 0.05))
	_tween.tween_callback(func():
		state = end_state
		if end_state == State.STOWED:
			visible = false
			_set_plate_collision(false)
		state_changed.emit("DEPLOYED" if end_state == State.DEPLOYED else "STOWED")
	)


func _apply_angle(t: float) -> void:
	_angle = clampf(t, 0.0, 1.0)
	# 0 = fully folded into belly (flat, hidden), 1 = ~28° drive ramp
	var deg := lerpf(0.0, DEPLOY_DEG, _angle)
	rotation_degrees.x = deg
	visible = _angle > 0.02
	_set_plate_collision(_angle > 0.5)
	if _mesh and not _is_hangar_ramp():
		_mesh.scale = Vector3(1, 1, lerpf(0.05, 1.0, _angle))


func _set_plate_collision(on: bool) -> void:
	var layer := 1 if on else 0
	if _body:
		_body.collision_layer = layer
	for p in _plates:
		if p is CollisionObject3D:
			(p as CollisionObject3D).collision_layer = layer


func is_driveable() -> bool:
	return state == State.DEPLOYED


func state_name() -> String:
	match state:
		State.DEPLOYING:
			return "DEPLOYING"
		State.DEPLOYED:
			return "DEPLOYED"
		State.STOWING:
			return "STOWING"
		_:
			return "STOWED"


func walk_mouth_global() -> Vector3:
	return to_global(Vector3(0.0, 0.72, 0.85))


func walk_foot_global() -> Vector3:
	return to_global(Vector3(0.0, 0.72, ramp_length * 0.92))


func sample_walk(t: float) -> Vector3:
	var u := clampf(t, 0.0, 1.0)
	return to_global(Vector3(0.0, 0.72, lerpf(0.85, ramp_length * 0.92, u)))


func _is_hangar_ramp() -> bool:
	## Hangar plates only on CatalogCarrier / HangarBay. Player-ship belly
	## ramp must not flip to hangar plates just because the hull has AGL.
	var p: Node = get_parent()
	if p != null and p.is_in_group("hangar_bays"):
		return true
	var n: Node = p
	while n != null:
		if n.has_method("hangar_bay") and n.has_method("try_deploy_rover"):
			return true
		n = n.get_parent()
	return false


func _pose_host() -> Node:
	## Landed / HOVER AGL / speed. Player ship or catalog carrier.
	var n: Node = get_parent()
	while n != null:
		if n.has_method("altitude_agl"):
			return n
		if n.has_method("hangar_bay") and n.has_method("cargo_hold"):
			return n
		n = n.get_parent()
	return null


func _hangar_host() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.has_method("hangar_bay") and n.has_method("cargo_hold"):
			return n
		n = n.get_parent()
	return null


func _toast_blocked(reason: String) -> void:
	var msg := "RAMP BLOCKED · %s" % reason
	if GameManager and GameManager.has_signal("toast_requested"):
		GameManager.toast_requested.emit(msg)
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("game_hud"):
		if n.has_method("push_toast"):
			n.push_toast(msg, 2.5)
			return


func _try_glb_skin() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var AP = load("res://scripts/assets/AssetPaths.gd")
	if AP == null or not AP.has_method("resolve"):
		return
	var fac := "cybernex"
	var ship := get_parent()
	while ship and not ("faction" in ship):
		ship = ship.get_parent()
	if ship and "faction" in ship and str(ship.faction) == "gROT":
		fac = "grot"
	var rel := "ships/cargo_ramp_segment/cargo_ramp_segment_%s_lod1.glb" % fac
	var path: String = str(AP.resolve(rel))
	if path == "" or not FileAccess.file_exists(path):
		return
	var doc := GLTFDocument.new()
	var st2 := GLTFState.new()
	if doc.append_from_file(path, st2) != OK:
		return
	var scn := doc.generate_scene(st2)
	if scn == null:
		return
	# Hide procedural plate mesh, show GLB under same hinge
	if _mesh:
		_mesh.visible = false
	add_child(scn)
	scn.name = "RampGLB"
	scn.position = Vector3(0, 0, ramp_length * 0.35)
	scn.scale = Vector3(ramp_width / 2.0, 1.0, ramp_length / 4.0) * 0.35
