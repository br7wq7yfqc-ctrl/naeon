extends Node3D
## Visual-only remote peer — soft multiplayer. No combat power, no authority.
const _AP = preload("res://scripts/assets/AssetPaths.gd")
const _HeroForms = preload("res://scripts/player/HeroFormCatalog.gd")

var peer_id: int = 0
var form: String = "Canine"
var faction: String = "Cybernex"
var ship_mode: String = ""
var ship_landed: bool = false
var op_mode: int = 0
var morph_t: float = 0.0
var actor_mode: String = "surface"
var _target: Vector3 = Vector3.ZERO
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _target_roll: float = 0.0
var _body: MeshInstance3D
var _label: Label3D
var _mat: StandardMaterial3D
var _form_root: Node3D = null
var _gear: Node3D = null
var _want_form_mesh: bool = true

func setup(id: int) -> void:
	peer_id = id
	name = "RemotePuppet_%d" % id
	_body = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.38
	cap.height = 1.15
	_body.mesh = cap
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.95, 0.55, 0.2, 0.75)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.45, 0.15)
	_mat.emission_energy_multiplier = 1.4
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_body.material_override = _mat
	_body.position = Vector3(0, 0.9, 0)
	add_child(_body)
	_label = Label3D.new()
	_label.font_size = 26
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 2.05, 0)
	_label.modulate = Color(1.0, 0.85, 0.55, 0.9)
	add_child(_label)
	_refresh_label()
	call_deferred("_try_load_form_mesh")

func apply_state(pos: Vector3, yaw: float, f: String, fac: String) -> void:
	apply_state_ex(pos, yaw, 0.0, 0.0, f, fac, "", false)

func apply_state_ex(pos: Vector3, yaw: float, pitch: float, roll: float, f: String, fac: String, mode: String, landed: bool) -> void:
	_target = pos
	_target_yaw = yaw
	_target_pitch = pitch
	_target_roll = roll
	var changed := form != f or faction != fac
	form = f
	faction = fac
	ship_mode = mode
	ship_landed = landed
	if changed:
		_refresh_visual()
		call_deferred("_try_load_form_mesh")
	_sync_remote_gear()
	_refresh_label()

func _sync_remote_gear() -> void:
	if form != "Ship":
		if _gear and is_instance_valid(_gear):
			_gear.visible = false
		return
	if _gear == null or not is_instance_valid(_gear):
		_gear = Node3D.new()
		_gear.set_script(preload("res://scripts/ship/ShipLandingGear.gd"))
		add_child(_gear)
	_gear.visible = true
	if _gear.has_method("set_deployed"):
		_gear.call("set_deployed", ship_landed)

func _refresh_visual() -> void:
	if _mat == null:
		return
	if form == "Ship":
		_mat.emission = Color(0.4, 0.7, 1.0)
		_mat.albedo_color = Color(0.35, 0.55, 0.85, 0.7)
		if _body:
			_body.scale = Vector3(1.6, 0.55, 2.2)
			_body.position = Vector3(0, 0.4, 0)
		return
	if faction == "gROT":
		_mat.emission = Color(0.95, 0.15, 0.45)
		_mat.albedo_color = Color(0.9, 0.2, 0.4, 0.75)
	else:
		_mat.emission = Color(0.25, 0.85, 1.0)
		_mat.albedo_color = Color(0.25, 0.75, 0.95, 0.75)
	var s := 1.0
	match form:
		"Feline":
			s = 0.92
		"Avian":
			s = 0.88
		"Human":
			s = 1.05
		"Infector":
			s = 1.1
		_:
			s = 1.0
	if _body:
		_body.scale = Vector3.ONE * s
		_body.position = Vector3(0, 0.9, 0)

func _ship_mesh_candidates() -> PackedStringArray:
	var fx := "grot" if faction == "gROT" else "cybernex"
	var out := PackedStringArray()
	for lod in ["lod0", "lod1", "lod2"]:
		out.append("ships/ship_hull_scout/ship_hull_scout_%s_%s.glb" % [fx, lod])
	return out

func _try_load_form_mesh() -> void:
	if not _want_form_mesh:
		return
	var path := ""
	var cands: PackedStringArray
	if form == "Ship":
		cands = _ship_mesh_candidates()
	else:
		cands = _HeroForms.mesh_candidates(form, faction)
	for rel in cands:
		var p: String = _AP.resolve(rel)
		if p != "" and FileAccess.file_exists(p):
			path = p
			break
	if path == "":
		if _body:
			_body.visible = true
		return
	if _form_root and is_instance_valid(_form_root):
		_form_root.queue_free()
		_form_root = null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return
	var root := doc.generate_scene(state)
	if root == null:
		return
	_strip(root)
	add_child(root)
	root.name = "FormGLB"
	if form == "Ship":
		root.scale = Vector3.ONE * 0.35
		root.position = Vector3(0, 0.2, 0)
	else:
		root.scale = Vector3.ONE * 0.85
	_form_root = root
	if _body:
		_body.visible = false
	print("[SoftRemotePuppet] form ", form, "/", faction, " ", path)

func _strip(n: Node) -> void:
	for c in n.get_children():
		_strip(c)
	if n is CollisionObject3D:
		(n as CollisionObject3D).collision_layer = 0
		(n as CollisionObject3D).collision_mask = 0

func _refresh_label() -> void:
	if _label:
		var extra := ""
		if form == "Ship":
			extra = " · %s%s" % [ship_mode if ship_mode != "" else "SCM", " LANDED" if ship_landed else ""]
			if op_mode == 1:
				extra += " SIEGE"
		elif actor_mode == "eva":
			extra = " · EVA"
		_label.text = "P%d · %s · %s%s" % [peer_id, form, faction, extra]
		_label.position = Vector3(0, 2.4 if form == "Ship" else 2.05, 0)

func _process(delta: float) -> void:
	global_position = global_position.lerp(_target, clampf(delta * 12.0, 0.0, 1.0))
	rotation.y = lerp_angle(rotation.y, _target_yaw, clampf(delta * 10.0, 0.0, 1.0))
	if form == "Ship":
		rotation.x = lerp_angle(rotation.x, _target_pitch, clampf(delta * 8.0, 0.0, 1.0))
		rotation.z = lerp_angle(rotation.z, _target_roll, clampf(delta * 8.0, 0.0, 1.0))
	if _form_root and is_instance_valid(_form_root):
		var amp := 0.02 if form == "Ship" else 0.03
		_form_root.position.y = (0.2 if form == "Ship" else 0.0) + sin(Time.get_ticks_msec() * 0.004) * amp


func apply_soft_extra(mode: int, morph: float, amode: String) -> void:
	op_mode = mode
	morph_t = morph
	actor_mode = amode
	_refresh_label()
