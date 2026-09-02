extends Node
class_name StrategyOverlay
## ST-A: top-down overlay on an already-loaded unnamed pad (Nex-Prime / ARK).
## Not a galaxy map (G2 locked). Does not replace ship or TPS.
## FL-A: one extra allied fleet pip (existing pad-visitor NpcPilot).
## FL-B: second extra allied pip (SoftNet visual, same NP-A grammar). Cap 3.
## FL-C: third extra allied pip (SoftNet visual, same NP-A grammar). Cap 4.
## FL-D: fourth extra allied pip (SoftNet visual, same NP-A grammar). Cap 5.
## SN-C: second local viewer sees SoftNet visual habitat/extractor/modules puppet.
## SoftKnowledge / HUD label only. Click/select ≠ combat. Host Pulse / occupy / Hack.

const _Builder = preload("res://scripts/world/BaseBuilder.gd")
const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
const _OverlayNet = preload("res://scripts/world/OverlaySoftNet.gd")

const ENTER_M := 90.0
const CAM_HEIGHT := 180.0
const CAM_SIZE := 120.0
const LEGAL_PADS := ["Pad_North", "Pad_Approach", "Pad_Flank"]
const FLEET_CAP := 5

var _os: Node = null
var _pad: Node3D = null
var _cam: Camera3D = null
var _prev_cam: Camera3D = null
var _prev_layer: String = "Space"
var _active: bool = false
var _last_line: String = "STRATEGY: no unnamed pad"
var _frozen: Array = []
var _fleet_pip: Node3D = null
var _fleet_pip_b: Node3D = null
var _fleet_pip_c: Node3D = null
var _fleet_pip_d: Node3D = null
var _fleet_selected: bool = false
var _fleet_selected_b: bool = false
var _fleet_selected_c: bool = false
var _fleet_selected_d: bool = false
var _softnet: Node = null


func setup(host: Node) -> void:
	_os = host
	add_to_group("strategy_overlay")
	set_process_input(true)
	_ensure_overlay_softnet()


func is_active() -> bool:
	return _active


func active_pad() -> Node3D:
	return _pad if _active else null


func overlay_softnet() -> Node:
	if _softnet != null and is_instance_valid(_softnet):
		return _softnet
	return get_node_or_null("OverlaySoftNet")


func get_overlay_softnet() -> Node:
	return overlay_softnet()


func _ensure_overlay_softnet() -> void:
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 == null or not bool(P0.SN_C_OVERLAY):
		return
	var existing: Node = get_node_or_null("OverlaySoftNet")
	if existing != null:
		_softnet = existing
		if _softnet.has_method("bind"):
			_softnet.bind(self)
		return
	var n: Node3D = Node3D.new()
	n.set_script(_OverlayNet)
	n.name = "OverlaySoftNet"
	add_child(n)
	_softnet = n
	if n.has_method("bind"):
		n.bind(self)


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


func fleet_cap() -> int:
	return FLEET_CAP


func fleet_guest() -> Node3D:
	var traffic := _pad_traffic()
	var guest := _guest_from_traffic(traffic)
	if guest != null:
		return guest
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("pad_traffic"):
		guest = _guest_from_traffic(n)
		if guest != null:
			return guest
	return null


func fleet_guest_b() -> Node3D:
	var traffic := _pad_traffic()
	var guest := _guest_b_from_traffic(traffic)
	if guest != null:
		return guest
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("pad_traffic"):
		guest = _guest_b_from_traffic(n)
		if guest != null:
			return guest
	return null


func _guest_from_traffic(traffic: Node) -> Node3D:
	if traffic == null or not is_instance_valid(traffic):
		return null
	if traffic.has_method("fleet_guest"):
		var g: Node3D = traffic.fleet_guest()
		if g != null and is_instance_valid(g):
			return g
	if traffic.has_method("get_visitor"):
		var v: Node3D = traffic.get_visitor()
		if v != null and is_instance_valid(v):
			return v
	return null


func _guest_b_from_traffic(traffic: Node) -> Node3D:
	if traffic == null or not is_instance_valid(traffic):
		return null
	if traffic.has_method("fleet_guest_b"):
		var g: Node3D = traffic.fleet_guest_b()
		if g != null and is_instance_valid(g):
			return g
	return null


func fleet_guest_c() -> Node3D:
	var traffic := _pad_traffic()
	var guest := _guest_c_from_traffic(traffic)
	if guest != null:
		return guest
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("pad_traffic"):
		guest = _guest_c_from_traffic(n)
		if guest != null:
			return guest
	return null


func _guest_c_from_traffic(traffic: Node) -> Node3D:
	if traffic == null or not is_instance_valid(traffic):
		return null
	if traffic.has_method("fleet_guest_c"):
		var g: Node3D = traffic.fleet_guest_c()
		if g != null and is_instance_valid(g):
			return g
	return null


func fleet_guest_d() -> Node3D:
	var traffic := _pad_traffic()
	var guest := _guest_d_from_traffic(traffic)
	if guest != null:
		return guest
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("pad_traffic"):
		guest = _guest_d_from_traffic(n)
		if guest != null:
			return guest
	return null


func _guest_d_from_traffic(traffic: Node) -> Node3D:
	if traffic == null or not is_instance_valid(traffic):
		return null
	if traffic.has_method("fleet_guest_d"):
		var g: Node3D = traffic.fleet_guest_d()
		if g != null and is_instance_valid(g):
			return g
	return null


func fleet_count() -> int:
	var n := 0
	if _os != null:
		var sh = _os.get("ship")
		if sh is Node3D and is_instance_valid(sh):
			n += 1
	if fleet_guest() != null:
		n += 1
	if fleet_guest_b() != null:
		n += 1
	if fleet_guest_c() != null:
		n += 1
	if fleet_guest_d() != null:
		n += 1
	return mini(n, FLEET_CAP)


func fleet_hud_line() -> String:
	return "%s %d/%d" % [_SoftK.fleet_label(), fleet_count(), FLEET_CAP]


func fleet_pip_visible() -> bool:
	return _active and _fleet_pip != null and is_instance_valid(_fleet_pip)


func fleet_pip_b_visible() -> bool:
	return _active and _fleet_pip_b != null and is_instance_valid(_fleet_pip_b)


func fleet_pip_c_visible() -> bool:
	return _active and _fleet_pip_c != null and is_instance_valid(_fleet_pip_c)


func fleet_pip_d_visible() -> bool:
	return _active and _fleet_pip_d != null and is_instance_valid(_fleet_pip_d)


func is_fleet_selected() -> bool:
	return _fleet_selected and fleet_pip_visible()


func is_fleet_b_selected() -> bool:
	return _fleet_selected_b and fleet_pip_b_visible()


func is_fleet_c_selected() -> bool:
	return _fleet_selected_c and fleet_pip_c_visible()


func is_fleet_d_selected() -> bool:
	return _fleet_selected_d and fleet_pip_d_visible()


func fleet_combat_authority() -> String:
	## Click/select never hands Pulse / occupy to the guest.
	return "host"


func try_select_fleet_pip() -> bool:
	if not fleet_pip_visible():
		return false
	_fleet_selected = true
	_toast(fleet_hud_line())
	var guest := fleet_guest()
	if guest != null and is_instance_valid(guest):
		guest.set_meta("combat_authority", "host")
	print("[StrategyOverlay] fleet pip select ", fleet_hud_line(), " auth=host")
	return true


func try_select_fleet_pip_b() -> bool:
	if not fleet_pip_b_visible():
		return false
	_fleet_selected_b = true
	_toast(fleet_hud_line())
	var guest := fleet_guest_b()
	if guest != null and is_instance_valid(guest):
		guest.set_meta("combat_authority", "host")
		guest.set_meta("occupy_authority", "host")
	print("[StrategyOverlay] fleet pip B select ", fleet_hud_line(), " auth=host")
	return true


func try_select_fleet_pip_c() -> bool:
	if not fleet_pip_c_visible():
		return false
	_fleet_selected_c = true
	_toast(fleet_hud_line())
	var guest := fleet_guest_c()
	if guest != null and is_instance_valid(guest):
		guest.set_meta("combat_authority", "host")
		guest.set_meta("occupy_authority", "host")
	print("[StrategyOverlay] fleet pip C select ", fleet_hud_line(), " auth=host")
	return true


func try_select_fleet_pip_d() -> bool:
	if not fleet_pip_d_visible():
		return false
	_fleet_selected_d = true
	_toast(fleet_hud_line())
	var guest := fleet_guest_d()
	if guest != null and is_instance_valid(guest):
		guest.set_meta("combat_authority", "host")
		guest.set_meta("occupy_authority", "host")
	print("[StrategyOverlay] fleet pip D select ", fleet_hud_line(), " auth=host")
	return true


func try_add_fleet_member(_who: Node = null) -> bool:
	## Cap 5 this slice. Does not spawn a fifth extra hull or OpenSpace.
	return false


func exit_overlay() -> void:
	if not _active:
		return
	_active = false
	_hide_fleet_pip()
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
	if _softnet != null and is_instance_valid(_softnet) and _softnet.has_method("sync_from_host"):
		_softnet.sync_from_host()
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
		if _try_click_fleet_pip(event):
			get_viewport().set_input_as_handled()
			return
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
	_show_fleet_pip()
	_ensure_overlay_softnet()
	if _softnet != null and is_instance_valid(_softnet) and _softnet.has_method("sync_from_host"):
		_softnet.sync_from_host()
	if LayerContext:
		LayerContext.set_layer("Strategy")
	if DisplayServer.get_name() != "headless":
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("[StrategyOverlay] enter ", pad.name, " d=", snapped(_actor_distance(pad), 0.1),
		" ", fleet_hud_line())


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


func _show_fleet_pip() -> void:
	## SoftKnowledge markers only. FL-A reuses the visitor hull. FL-B/C/D are SoftNet.
	_hide_fleet_pip()
	var P0 = load("res://scripts/world/P0Slice.gd")
	if P0 != null and not bool(P0.FL_A_FLEET):
		return
	if _pad == null or not is_instance_valid(_pad):
		return
	var guest := fleet_guest()
	if guest == null:
		return
	_fleet_pip = _make_fleet_pip("FleetPip", guest, Color(0.35, 0.9, 1.0))
	if P0 != null and bool(P0.FL_B_FLEET):
		var guest_b := fleet_guest_b()
		if guest_b != null:
			_fleet_pip_b = _make_fleet_pip("FleetPipB", guest_b, Color(0.4, 0.95, 0.75))
	if P0 != null and bool(P0.FL_C_FLEET):
		var guest_c := fleet_guest_c()
		if guest_c != null:
			_fleet_pip_c = _make_fleet_pip("FleetPipC", guest_c, Color(0.85, 0.6, 1.0))
	if P0 != null and bool(P0.FL_D_FLEET):
		var guest_d := fleet_guest_d()
		if guest_d != null:
			_fleet_pip_d = _make_fleet_pip("FleetPipD", guest_d, Color(1.0, 0.72, 0.32))


func _make_fleet_pip(id: String, guest: Node3D, col: Color) -> Node3D:
	var pip := Node3D.new()
	pip.name = id
	pip.set_meta("site_pin", "")
	pip.set_meta("fleet_pip", true)
	pip.set_meta("combat_authority", "host")
	pip.add_to_group("fleet_pips")
	_pad.add_child(pip)
	var up := _pad_up()
	pip.global_position = guest.global_position + up * 8.0
	var lab := Label3D.new()
	lab.name = "Label"
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 28
	lab.outline_size = 6
	lab.position = Vector3(0.0, 2.0, 0.0)
	lab.text = fleet_hud_line()
	lab.modulate = col
	pip.add_child(lab)
	if DisplayServer.get_name() != "headless":
		var mi := MeshInstance3D.new()
		mi.name = "PipMesh"
		var sphere := SphereMesh.new()
		sphere.radius = 1.4
		sphere.height = 2.8
		mi.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.8
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pip.add_child(mi)
	return pip


func _hide_fleet_pip() -> void:
	_fleet_selected = false
	_fleet_selected_b = false
	_fleet_selected_c = false
	_fleet_selected_d = false
	if _fleet_pip != null and is_instance_valid(_fleet_pip):
		var p := _fleet_pip.get_parent()
		if p:
			p.remove_child(_fleet_pip)
		_fleet_pip.queue_free()
	_fleet_pip = null
	if _fleet_pip_b != null and is_instance_valid(_fleet_pip_b):
		var pb := _fleet_pip_b.get_parent()
		if pb:
			pb.remove_child(_fleet_pip_b)
		_fleet_pip_b.queue_free()
	_fleet_pip_b = null
	if _fleet_pip_c != null and is_instance_valid(_fleet_pip_c):
		var pc := _fleet_pip_c.get_parent()
		if pc:
			pc.remove_child(_fleet_pip_c)
		_fleet_pip_c.queue_free()
	_fleet_pip_c = null
	if _fleet_pip_d != null and is_instance_valid(_fleet_pip_d):
		var pd := _fleet_pip_d.get_parent()
		if pd:
			pd.remove_child(_fleet_pip_d)
		_fleet_pip_d.queue_free()
	_fleet_pip_d = null


func _ray_hits_pip(event: InputEventMouseButton, pip: Node3D) -> bool:
	if pip == null or not is_instance_valid(pip) or _cam == null or not is_instance_valid(_cam):
		return false
	var vp := get_viewport()
	if vp == null:
		return false
	var origin: Vector3 = _cam.project_ray_origin(event.position)
	var dir: Vector3 = _cam.project_ray_normal(event.position)
	var dest: Vector3 = pip.global_position
	var to: Vector3 = dest - origin
	var t: float = to.dot(dir)
	if t < 0.0:
		return false
	var nearest: Vector3 = origin + dir * t
	return nearest.distance_to(dest) <= 10.0


func _try_click_fleet_pip(event: InputEventMouseButton) -> bool:
	if _cam == null or not is_instance_valid(_cam):
		return false
	if fleet_pip_d_visible() and _ray_hits_pip(event, _fleet_pip_d):
		return try_select_fleet_pip_d()
	if fleet_pip_c_visible() and _ray_hits_pip(event, _fleet_pip_c):
		return try_select_fleet_pip_c()
	if fleet_pip_b_visible() and _ray_hits_pip(event, _fleet_pip_b):
		return try_select_fleet_pip_b()
	if fleet_pip_visible() and _ray_hits_pip(event, _fleet_pip):
		return try_select_fleet_pip()
	return false


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
