extends Node3D
class_name CargoRamp
## Deployable cargo ramp. Hidden when stowed (was a black monolith under scout hulls).

signal state_changed(state: String)

enum State { STOWED, DEPLOYING, DEPLOYED, STOWING }

var state: int = State.STOWED
var _mesh: MeshInstance3D
var _body: StaticBody3D
var _angle: float = 0.0
var _tween: Tween

@export var deploy_sec: float = 1.1
@export var ramp_length: float = 8.0
@export var ramp_width: float = 4.0

func _ready() -> void:
	_build()
	_apply_angle(0.0)


func _build() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.name = "RampPlate"
	var box := BoxMesh.new()
	box.size = Vector3(ramp_width, 0.12, ramp_length)
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
	sh.size = box.size
	cs.shape = sh
	_body.add_child(cs)
	_mesh.add_child(_body)
	# hinge at ship belly-aft, not hanging mid-hull
	position = Vector3(0, -0.35, 1.2)
	_mesh.position = Vector3(0, 0, ramp_length * 0.5)


func toggle() -> void:
	if state == State.STOWED or state == State.STOWING:
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


func _animate_to(target: float, sec: float, end_state: int) -> void:
	if _tween and is_instance_valid(_tween):
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_apply_angle, _angle, target, maxf(sec, 0.05))
	_tween.tween_callback(func():
		state = end_state
		if end_state == State.STOWED:
			visible = false
			if _body:
				_body.collision_layer = 0
		state_changed.emit("DEPLOYED" if end_state == State.DEPLOYED else "STOWED")
	)


func _apply_angle(t: float) -> void:
	_angle = clampf(t, 0.0, 1.0)
	# 0 = fully folded into belly (flat, hidden), 1 = ~28° drive ramp
	var deg := lerpf(0.0, 28.0, _angle)
	rotation_degrees.x = deg
	visible = _angle > 0.02
	if _body:
		_body.collision_layer = 1 if _angle > 0.5 else 0
	if _mesh:
		_mesh.scale = Vector3(1, 1, lerpf(0.05, 1.0, _angle))


func is_driveable() -> bool:
	return state == State.DEPLOYED



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
