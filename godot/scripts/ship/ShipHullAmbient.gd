extends Node3D
class_name ShipHullAmbient
## Soft hull presentation: faction rim lights, engine wash, mode pulse.
## Code-first, 0 Tripo. Cheap (~3 OmniLight3D, 12–15 Hz tick).

var _ship: Node3D
var _engine_light: OmniLight3D
var _rim_l: OmniLight3D
var _rim_r: OmniLight3D
var _cabin: OmniLight3D
var _accum: float = 0.0
var _pulse: float = 0.0
var _power: float = 0.0
var _op_mode: int = 0
var _faction: String = "Cybernex"
var _landed: bool = false


func setup(ship: Node3D) -> void:
	_ship = ship
	_build()
	_sync_faction()


func set_faction(fac: String) -> void:
	_faction = fac
	_sync_faction()


func set_op_mode(mode: int) -> void:
	_op_mode = mode


func set_landed(v: bool) -> void:
	_landed = v


func set_engine_power(p: float) -> void:
	_power = clampf(p, 0.0, 1.5)


func _ready() -> void:
	set_process(true)
	if _engine_light == null:
		_build()


func _build() -> void:
	if _engine_light != null:
		return
	_engine_light = _make_light("EngineWash", Vector3(0, 0.1, 2.4), 9.0, 2.2)
	_rim_l = _make_light("RimL", Vector3(-1.4, 0.2, 0.0), 5.0, 0.7)
	_rim_r = _make_light("RimR", Vector3(1.4, 0.2, 0.0), 5.0, 0.7)
	_cabin = _make_light("Cabin", Vector3(0, 0.55, -0.6), 3.5, 0.45)
	_sync_faction()
	print("[HullAmbient] lights ready")


func _make_light(nm: String, pos: Vector3, rng: float, energy: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = nm
	l.position = pos
	l.omni_range = rng
	l.light_energy = energy
	l.shadow_enabled = false
	l.light_specular = 0.15
	add_child(l)
	return l


func _sync_faction() -> void:
	var primary := Color(0.25, 0.75, 1.0)
	var accent := Color(0.45, 0.9, 1.0)
	if _faction == "gROT":
		primary = Color(0.95, 0.2, 0.35)
		accent = Color(1.0, 0.35, 0.2)
	if _engine_light:
		_engine_light.light_color = primary
	if _rim_l:
		_rim_l.light_color = accent
	if _rim_r:
		_rim_r.light_color = accent
	if _cabin:
		_cabin.light_color = primary.lightened(0.35)


func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.07:
		return
	_accum = 0.0
	_pulse += 0.07
	_apply()


func _apply() -> void:
	if _engine_light == null:
		return
	var idle := 0.35 if not _landed else 0.12
	var eng := idle + _power * 2.4
	# Mode envelopes
	if _op_mode == 1:  # SIEGE — hot, tight
		eng *= 1.35
		_engine_light.omni_range = 7.0 + _power * 2.0
	elif _op_mode == 2:  # SCAN — cool pulse, wider
		var wave := 0.55 + 0.45 * sin(_pulse * 2.2)
		eng = 0.5 + wave * 0.9
		_engine_light.omni_range = 11.0 + wave * 3.0
	else:
		_engine_light.omni_range = 8.0 + _power * 3.0
	if _landed:
		eng *= 0.35
	_engine_light.light_energy = eng

	var rim_e := 0.35 + _power * 0.25
	if _op_mode == 2:
		rim_e = 0.55 + 0.4 * sin(_pulse * 3.1)
	elif _op_mode == 1:
		rim_e = 0.9
	if _landed:
		rim_e *= 0.4
	if _rim_l:
		_rim_l.light_energy = rim_e
	if _rim_r:
		_rim_r.light_energy = rim_e
	if _cabin:
		_cabin.light_energy = 0.25 if _landed else (0.45 + (0.2 if _op_mode == 2 else 0.0))

	# Soft hull emission pulse (placeholder Prism or loaded hull)
	if _ship and is_instance_valid(_ship):
		var hm = _ship.get_node_or_null("HullMesh")
		if hm is MeshInstance3D:
			var mi: MeshInstance3D = hm
			var mat = mi.material_override
			if mat is StandardMaterial3D:
				var sm: StandardMaterial3D = mat
				sm.emission_enabled = true
				var base_e := 0.6 + _power * 0.5
				if _op_mode == 2:
					base_e = 0.5 + 0.6 * absf(sin(_pulse * 2.5))
				elif _op_mode == 1:
					base_e = 1.1
				if _landed:
					base_e *= 0.45
				sm.emission_energy_multiplier = base_e
