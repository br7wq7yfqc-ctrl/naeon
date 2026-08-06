extends Node
class_name ChannelController
## Channeled abilities (Hack): progress bar, interrupt, beam VFX.
## Design: interruptible full window. No P2W.

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
	print("[Channel] interrupted: ", reason)
	_on_complete = Callable()
	_caster = null

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
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
	_clear_vfx()
	_caster = null
	channel_completed.emit(n)
	if cb.is_valid():
		cb.call()
	print("[Channel] complete ", n)

func notify_damage() -> void:
	if active:
		interrupt("damage")

func notify_firewall_break() -> void:
	if active:
		interrupt("firewall")

func _spawn_vfx() -> void:
	_clear_vfx()
	if _caster == null or not _caster is Node3D:
		return
	var c := _caster as Node3D
	# Ground ring under caster
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.55
	tm.outer_radius = 0.7
	tm.rings = 6
	tm.ring_segments = 12
	_ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(1.0, 0.25, 0.55, 0.7)
	rm.emission_enabled = true
	rm.emission = Color(1.0, 0.2, 0.5)
	rm.emission_energy_multiplier = 3.0
	_ring.material_override = rm
	c.add_child(_ring)
	_ring.position = Vector3(0, 0.08, 0)
	# Forward beam stub
	_beam = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 1.0)
	_beam.mesh = box
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.albedo_color = Color(1.0, 0.3, 0.6, 0.65)
	bm.emission_enabled = true
	bm.emission = Color(1.0, 0.25, 0.55)
	bm.emission_energy_multiplier = 4.0
	_beam.material_override = bm
	c.add_child(_beam)
	_beam.position = Vector3(0, 1.3, -0.6)

func _update_vfx() -> void:
	var r := get_ratio()
	if _ring:
		var s := 0.8 + r * 1.4
		_ring.scale = Vector3(s, 1.0, s)
		_ring.rotate_y(0.08)
	if _beam:
		_beam.scale = Vector3(1.0, 1.0, 0.5 + r * 8.0)
		_beam.position = Vector3(0, 1.3, -0.5 - r * 4.0)

func _clear_vfx() -> void:
	if _beam and is_instance_valid(_beam):
		_beam.queue_free()
	if _ring and is_instance_valid(_ring):
		_ring.queue_free()
	_beam = null
	_ring = null
