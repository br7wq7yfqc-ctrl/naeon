extends Node
class_name StrategyOverlay
## ST-A: top-down overlay on an already-loaded unnamed pad (Nex-Prime / ARK).
## Not a galaxy map (G2 locked). Does not replace ship or TPS.

const _Builder = preload("res://scripts/world/BaseBuilder.gd")

const ENTER_M := 90.0
const CAM_HEIGHT := 180.0
const CAM_SIZE := 120.0
const LEGAL_PADS := ["Pad_North", "Pad_Approach", "Pad_Flank"]

var _os: Node = null
var _pad: Node3D = null
var _cam: Camera3D = null
var _prev_cam: Camera3D = null
var _prev_layer: String = "Space"
var _active: bool = false
var _last_line: String = "STRATEGY: no unnamed pad"
var _frozen: Array = []


func setup(host: Node) -> void:
	_os = host
	add_to_group("strategy_overlay")
	set_process_input(true)


func is_active() -> bool:
	return _active


func active_pad() -> Node3D:
	return _pad if _active else null


func readiness_line() -> String:
	var pad: Node3D = _pick_pad()
	if pad == null:
		_last_line = "STRATEGY: no unnamed pad"
		return _last_line
	var d := _actor_distance(pad)
	if d > ENTER_M:
		_last_line = "STRATEGY: %s %.0f m — land or EVA first" % [pad.name, d]
		return _last_line
	if _Builder.pad_has_player_module(pad):
		_last_line = "STRATEGY: %s · habitat already placed · B overlay" % pad.name
		return _last_line
	_last_line = "STRATEGY: %s %.0f m · B overlay · click/Enter habitat" % [pad.name, d]
	return _last_line


func try_enter() -> bool:
	if _active:
		return true
	var pad: Node3D = _pick_pad()
	var line := readiness_line()
	if pad == null or _actor_distance(pad) > ENTER_M:
		_toast(line)
		print("[StrategyOverlay] deny enter ", line)
		return false
	_enter(pad)
	return true


func exit_overlay() -> void:
	if not _active:
		return
	_active = false
	_thaw_actors()
	if _cam != null and is_instance_valid(_cam):
		_cam.current = false
		var p := _cam.get_parent()
		if p:
			p.remove_child(_cam)
		_cam.queue_free()
	_cam = null
	if _prev_cam != null and is_instance_valid(_prev_cam):
		_prev_cam.current = true
	elif _os != null and _os.has_method("reclaim_pilot_camera"):
		_os.reclaim_pilot_camera()
	_prev_cam = null
	if LayerContext:
		LayerContext.set_layer(_prev_layer if _prev_layer != "" else "Space")
	if DisplayServer.get_name() != "headless":
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_pad = null
	print("[StrategyOverlay] exit layer=", LayerContext.current_layer if LayerContext else "?")


func overlay_caster() -> Node3D:
	return _actor()


func infection_target() -> Node:
	if not _active or _pad == null or not is_instance_valid(_pad):
		return null
	var guard := _pad_guard()
	if guard != null:
		return guard
	return _pad_infection_host()


func try_hack(target = null) -> bool:
	return _try_kit("hack", target)


func try_firewall(target = null) -> bool:
	return _try_kit("firewall", target)


func _try_kit(kind: String, target) -> bool:
	## HF-C: reuse walker / hull AbilitySystem. Overlay is not a second kit.
	if not _active:
		return false
	var caster := overlay_caster()
	if caster == null or not is_instance_valid(caster):
		return false
	if caster.has_method("_ensure_ability_kit"):
		caster._ensure_ability_kit()
	var hint: Node = target as Node if target is Node else null
	if hint == null or not is_instance_valid(hint):
		hint = infection_target()
	_pin_caster_for_pad(caster, hint)
	if kind == "hack" and caster.has_method("try_hack"):
		return bool(caster.try_hack(hint))
	if kind == "firewall" and caster.has_method("try_firewall"):
		return bool(caster.try_firewall(hint))
	return false


func _pin_caster_for_pad(caster: Node3D, hint: Node) -> void:
	## Overlay is pad-scoped. Frozen leftover dirt pose must not miss the guard.
	if caster == null or not is_instance_valid(caster) or hint == null:
		return
	if not (hint is Node3D) or not is_instance_valid(hint):
		return
	var dest: Vector3 = (hint as Node3D).global_position
	if caster.global_position.distance_to(dest) <= 16.0:
		return
	caster.global_position = dest + _pad_up() * 4.0


func _pad_guard() -> Node:
	if _pad == null or not is_instance_valid(_pad):
		return null
	if _pad.has_method("get_guard"):
		var g: Node = _pad.get_guard()
		if _is_infection_host(g):
			return g
	var traffic := _pad_traffic()
	if traffic == null:
		return null
	if traffic.has_method("get_guard"):
		var g2: Node = traffic.get_guard()
		if _is_infection_host(g2):
			return g2
	if traffic.has_method("get_surface_dummy"):
		var d: Node = traffic.get_surface_dummy()
		if _is_infection_host(d):
			return d
	if traffic.has_method("pulse_target"):
		var p: Node = traffic.pulse_target()
		if _is_infection_host(p):
			return p
	return null


func _pad_infection_host() -> Node:
	if _pad == null or not is_instance_valid(_pad):
		return null
	if _is_infection_host(_pad):
		return _pad
	return null


func _is_infection_host(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	return node.has_method("apply_infection") or node.has_method("purge_infection") \
			or node.get_node_or_null("InfectionStatus") != null


func _pad_traffic() -> Node:
	if _pad == null or not is_instance_valid(_pad):
		return null
	var t: Node = _pad.get_node_or_null("PadTraffic")
	if t != null and is_instance_valid(t):
		return t
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("pad_traffic"):
		if n == null or not is_instance_valid(n):
			continue
		if n.get_parent() == _pad:
			return n
	return null


func place_module() -> Node3D:
	if not _active or _pad == null or not is_instance_valid(_pad):
		_toast("STRATEGY: overlay closed")
		return null
	if _actor_distance(_pad) > ENTER_M:
		_toast(readiness_line())
		return null
	if _Builder.pad_has_player_module(_pad):
		var line := "STRATEGY: pad already has a module (one per pad this slice)"
		_last_line = line
		_toast(line)
		print("[StrategyOverlay] deny place ", line)
		return null
	var fac := _faction()
	var mod: Node3D = _Builder.place_player_habitat(_pad, fac)
	if mod == null:
		_toast("STRATEGY: place failed")
		return null
	if str(mod.get_meta("site_pin", "x")) != "":
		push_error("[StrategyOverlay] player module minted a site_pin")
	_toast("Habitat on %s — 0 combat stats" % _pad.name)
	print("[StrategyOverlay] placed habitat on ", _pad.name, " fac=", fac)
	return mod


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
		if k == KEY_NONE:
			k = event.physical_keycode
		if _active:
			if k == KEY_ESCAPE or k == KEY_B:
				exit_overlay()
				get_viewport().set_input_as_handled()
			elif k == KEY_ENTER or k == KEY_KP_ENTER:
				place_module()
				get_viewport().set_input_as_handled()
			elif k == KEY_Q:
				try_hack()
				get_viewport().set_input_as_handled()
			elif k == KEY_E:
				try_firewall()
				get_viewport().set_input_as_handled()
			elif k == KEY_I or k == KEY_F or k == KEY_M or k == KEY_TAB:
				get_viewport().set_input_as_handled()
			return
		if k == KEY_B:
			try_enter()
			get_viewport().set_input_as_handled()
	if _active and event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT:
		place_module()
		get_viewport().set_input_as_handled()


func _enter(pad: Node3D) -> void:
	_pad = pad
	_prev_layer = str(LayerContext.current_layer) if LayerContext else "Space"
	if _prev_layer == "Strategy":
		_prev_layer = "Space" if _os != null and bool(_os.get("_in_ship")) else "TPS"
	var vp := get_viewport()
	_prev_cam = vp.get_camera_3d() if vp else null
	_freeze_actors()
	_make_camera()
	_active = true
	if LayerContext:
		LayerContext.set_layer("Strategy")
	if DisplayServer.get_name() != "headless":
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("[StrategyOverlay] enter ", pad.name, " d=", snapped(_actor_distance(pad), 0.1))


func _make_camera() -> void:
	if _cam != null and is_instance_valid(_cam):
		_cam.queue_free()
	_cam = Camera3D.new()
	_cam.name = "StrategyCamera"
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = CAM_SIZE
	_cam.near = 0.5
	_cam.far = 800.0
	_cam.current = false
	_pad.add_child(_cam)
	_cam.position = Vector3(0.0, CAM_HEIGHT, 0.0)
	var origin := _pad.global_position
	var up := _pad_up()
	var east: Vector3 = up.cross(Vector3(0, 0, 1))
	if east.length_squared() < 0.04:
		east = up.cross(Vector3(1, 0, 0))
	east = east.normalized()
	_cam.look_at(origin, east)
	_cam.current = true


func _pick_pad() -> Node3D:
	if _os == null or not _os.has_method("nearest_pad"):
		return null
	var actor := _actor()
	if actor == null:
		return null
	var pad: Node3D = _os.nearest_pad(actor.global_position)
	if pad == null or not _is_legal_pad(pad):
		var tree := get_tree()
		if tree == null:
			return null
		var best: Node3D = null
		var best_d := INF
		for n in tree.get_nodes_in_group("landing_pads"):
			if not (n is Node3D) or not _is_legal_pad(n):
				continue
			var d: float = actor.global_position.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n as Node3D
		return best
	return pad


func _is_legal_pad(n: Node) -> bool:
	if n == null:
		return false
	return str(n.name) in LEGAL_PADS


func _actor() -> Node3D:
	if _os == null:
		return null
	if not bool(_os.get("_in_ship")):
		var p = _os.get("player")
		if p is Node3D and is_instance_valid(p):
			return p
	var s = _os.get("ship")
	if s is Node3D and is_instance_valid(s):
		return s
	return null


func _actor_distance(pad: Node3D) -> float:
	var a := _actor()
	if a == null or pad == null:
		return INF
	return a.global_position.distance_to(pad.global_position)


func _pad_up() -> Vector3:
	if _pad != null and _pad.has_meta("pad_up"):
		return (_pad.get_meta("pad_up") as Vector3).normalized()
	return Vector3.UP


func _faction() -> String:
	var a := _actor()
	if a != null and a.has_method("get_faction"):
		return str(a.get_faction())
	if GameManager and GameManager.has_method("get_faction_name"):
		return str(GameManager.get_faction_name())
	return "Cybernex"


func _freeze_actors() -> void:
	_frozen.clear()
	for n in [_os.get("ship") if _os else null, _os.get("player") if _os else null]:
		if n == null or not is_instance_valid(n):
			continue
		_frozen.append({
			"n": n,
			"phys": n.is_physics_processing(),
			"inp": n.is_processing_input(),
			"unh": n.is_processing_unhandled_input(),
		})
		n.set_physics_process(false)
		n.set_process_input(false)
		n.set_process_unhandled_input(false)


func _thaw_actors() -> void:
	for rec in _frozen:
		var n: Node = rec.get("n")
		if n == null or not is_instance_valid(n):
			continue
		n.set_physics_process(bool(rec.get("phys", true)))
		n.set_process_input(bool(rec.get("inp", true)))
		n.set_process_unhandled_input(bool(rec.get("unh", true)))
	_frozen.clear()


func _toast(msg: String) -> void:
	if _os != null and _os.has_method("_toast_hud"):
		_os._toast_hud(msg)
		return
	print("[StrategyOverlay] ", msg)
