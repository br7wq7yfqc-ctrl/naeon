extends Node
class_name ChannelController
## Channeled abilities: faction-tinted ring, progress beam, interrupt-safe VFX.

signal channel_started(ability_name: String, duration: float)
signal channel_progress(ratio: float)
signal channel_completed(ability_name: String)
signal channel_interrupted(reason: String)

var active: bool = false
var ability_name: String = ""
var duration: float = 1.5
var elapsed: float = 0.0
var _on_complete: Callable = Callable()
var _caster: Node = null
var _beam: MeshInstance3D = null
var _ring: MeshInstance3D = null
var _ring_inner: MeshInstance3D = null
var _light: OmniLight3D = null
var _col: Color = Color(0.25, 0.9, 1.0)


func _ready() -> void:
	set_process(true)


func is_channeling() -> bool:
	return active


func get_ratio() -> float:
	if not active or duration <= 0.0:
		return 0.0
	return clampf(elapsed / duration, 0.0, 1.0)


func start_channel(p_name: String, p_duration: float, on_complete: Callable, caster: Node = null) -> bool:
	if active:
		interrupt("already_channeling")
	if caster:
		var inf = caster.get_node_or_null("InfectionStatus")
		if inf and inf.has_method("can_channel") and not inf.can_channel():
			channel_interrupted.emit("glitch")
			return false
	ability_name = p_name
	duration = maxf(p_duration, 0.05)
	elapsed = 0.0
	_on_complete = on_complete
	_caster = caster
	active = true
	_resolve_color()
	_spawn_vfx()
	channel_started.emit(ability_name, duration)
	print("[Channel] start ", ability_name, " ", duration, "s")
	return true


func interrupt(reason: String = "interrupt") -> void:
	if not active:
		return
	active = false
	elapsed = 0.0
	_clear_vfx()
	channel_interrupted.emit(reason)
	_toast("Channel interrupted: %s" % reason)
	print("[Channel] interrupted: ", reason)
	_on_complete = Callable()
	_caster = null


func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	if int(elapsed * 4.0) != int((elapsed - delta) * 4.0):
		if AudioDirector and AudioDirector.has_method("play_channel_tick"):
			AudioDirector.play_channel_tick()
	channel_progress.emit(get_ratio())
	_update_vfx()
	if elapsed >= duration:
		_finish()


func _finish() -> void:
	if not active:
		return
	active = false
	var cb := _on_complete
	var n := ability_name
	_on_complete = Callable()
	_spawn_complete_burst()
	_clear_vfx()
	_caster = null
	channel_completed.emit(n)
	_toast("Channel complete: %s" % n)
	if cb.is_valid():
		cb.call()
	print("[Channel] complete ", n)


func notify_damage() -> void:
	if active:
		interrupt("damage")


func notify_firewall_break() -> void:
	if active:
		interrupt("firewall")


func _resolve_color() -> void:
	_col = Color(0.25, 0.9, 1.0)
	if _caster and _caster.has_method("get_faction"):
		if str(_caster.get_faction()) == "gROT":
			_col = Color(1.0, 0.2, 0.48)
	elif GameManager and GameManager.get_faction_name() == "gROT":
		_col = Color(1.0, 0.2, 0.48)


func _mat(energy: float = 3.0, alpha: float = 0.75) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(_col.r, _col.g, _col.b, alpha)
	m.emission_enabled = true
	m.emission = _col
	m.emission_energy_multiplier = energy
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _spawn_vfx() -> void:
	_clear_vfx()
	if _caster == null or not _caster is Node3D:
		return
	var c := _caster as Node3D
	# Outer torus ring
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.62
	tm.outer_radius = 0.78
	tm.rings = 10
	tm.ring_segments = 24
	_ring.mesh = tm
	_ring.material_override = _mat(3.2, 0.72)
	c.add_child(_ring)
	_ring.position = Vector3(0, 0.06, 0)
	# Inner progress disc (scales with ratio via scale.y thickness pulse)
	_ring_inner = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.45
	cyl.bottom_radius = 0.45
	cyl.height = 0.04
	cyl.radial_segments = 20
	_ring_inner.mesh = cyl
	_ring_inner.material_override = _mat(2.0, 0.35)
	c.add_child(_ring_inner)
	_ring_inner.position = Vector3(0, 0.04, 0)
	# Soft omni
	_light = OmniLight3D.new()
	_light.light_color = _col
	_light.light_energy = 1.8
	_light.omni_range = 6.0
	_light.position = Vector3(0, 1.2, 0)
	c.add_child(_light)
	# Forward beam
	_beam = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.07, 0.07, 1.0)
	_beam.mesh = box
	_beam.material_override = _mat(4.0, 0.7)
	c.add_child(_beam)
	_beam.position = Vector3(0, 1.35, -0.55)


func _update_vfx() -> void:
	var r := get_ratio()
	if _ring and is_instance_valid(_ring):
		var s := 0.85 + r * 1.55
		_ring.scale = Vector3(s, 1.0, s)
		_ring.rotate_y(0.12 + r * 0.08)
		var mat := _ring.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 2.2 + r * 3.5
			mat.albedo_color.a = 0.45 + r * 0.45
	if _ring_inner and is_instance_valid(_ring_inner):
		var si := 0.35 + r * 1.1
		_ring_inner.scale = Vector3(si, 1.0, si)
		_ring_inner.rotate_y(-0.18)
	if _beam and is_instance_valid(_beam):
		_beam.scale = Vector3(1.0 + r * 0.4, 1.0 + r * 0.4, 0.6 + r * 9.0)
		_beam.position = Vector3(0, 1.35, -0.45 - r * 4.5)
	if _light and is_instance_valid(_light):
		_light.light_energy = 1.2 + r * 3.5
		# gentle pulse
		_light.light_energy += 0.4 * sin(Time.get_ticks_msec() * 0.012)


func _spawn_complete_burst() -> void:
	if _caster == null or not _caster is Node3D:
		return
	var c := _caster as Node3D
	var p := GPUParticles3D.new()
	p.amount = 18
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 6.0
	pm.gravity = Vector3(0, -2, 0)
	pm.color = _col
	p.process_material = pm
	var dm := SphereMesh.new()
	dm.radius = 0.06
	dm.height = 0.12
	p.draw_pass_1 = dm
	p.position = Vector3(0, 0.5, 0)
	c.add_child(p)
	var tree := c.get_tree()
	if tree:
		tree.create_timer(0.7).timeout.connect(func():
			if is_instance_valid(p):
				p.queue_free()
		)


func _clear_vfx() -> void:
	for n in [_beam, _ring, _ring_inner, _light]:
		if n and is_instance_valid(n):
			n.queue_free()
	_beam = null
	_ring = null
	_ring_inner = null
	_light = null


func _toast(msg: String) -> void:
	if GameManager and GameManager.has_signal("toast_requested"):
		GameManager.toast_requested.emit(msg)
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("game_hud"):
			if n.has_method("push_toast"):
				n.push_toast(msg, 2.0)
				return
