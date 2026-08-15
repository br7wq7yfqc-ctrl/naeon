extends Node3D
const _SoftK = preload("res://scripts/systems/SoftKnowledge.gd")
## Pad base: Dynamic Ownership claim + extractor harvest → Contribution (soft economy, no P2W combat).

signal claimed(faction: String)
signal harvested(amount: float, total: float)

@export var default_faction: String = "Cybernex"
@export var extract_rate: float = 4.0
@export var contribution_per_unit: float = 0.35
@export var crystal_reserves: float = 120.0
@export var claim_radius: float = 40.0

var ownership: OwnershipData
var running: bool = true
var total_extracted: float = 0.0
var _label: Label3D
var _status: String = "unclaimed"
var _contest_ring: Node3D = null
var _contest_fov_t: float = 0.0
var _base_fov: float = 70.0
var _claim_cd: float = 0.0
var _harvest_fx_cd: float = 0.0
var _harvest_accum_fx: float = 0.0
var _contest_side: String = ""
var _guard: Node3D = null
var _occupy_in_t: float = 0.0
var _occupy_label_t: float = 0.0
var _seeding: bool = false
var _guard_respawn_t: float = 0.0

const CLAIM_NEED := 1.75
const OCCUPY_RATE := 0.32
const GUARD_RATE := 0.18
const DECAY_RATE := 0.16
const PULSE_STR := 0.38
const HACK_STR := 0.22

func _ready() -> void:
	add_to_group("pad_base")
	add_to_group("hackable")
	call_deferred("_ensure_claim_beacon")
	ownership = OwnershipData.new()
	ownership.object_id = "%s/%s" % [get_parent().name if get_parent() else "pad", name]
	ownership.current_faction = OwnershipData.Faction.NEUTRAL
	_ensure_label()
	set_process(true)
	add_to_group("pad_bases")
	_contest_ring = Node3D.new()
	_contest_ring.set_script(preload("res://scripts/world/ContestedRing.gd"))
	_contest_ring.name = "ContestedRing"
	add_child(_contest_ring)
	await get_tree().create_timer(0.4).timeout
	if ownership.current_faction == OwnershipData.Faction.NEUTRAL:
		_seeding = true
		claim(default_faction, 0.5)
		_seeding = false

func _ensure_label() -> void:
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 28
	_label.outline_size = 6
	_label.position = Vector3(0, 8, 0)
	add_child(_label)
	_refresh_label()

func _process(delta: float) -> void:
	_tick_contest_fov(delta)
	_claim_cd = maxf(0.0, _claim_cd - delta)
	if ownership and ownership.transition_progress < 1.0:
		ownership.advance_transition(delta, 5.0)
		_apply_faction_visual()
		if ownership.transition_progress >= 1.0:
			_status = "owned"
			_set_contested_ring(false)
			swap_cluster_theme(ownership.faction_name())
			_update_city_density()
			_refresh_label()
	_tick_occupy(delta)
	_tick_guard_respawn(delta)
	if running and ownership and ownership.is_fully_owned() and _status != "contested" and _owner_in_zone():
		_tick_harvest(delta)
	elif _status == "extracting":
		_status = "owned"
		_refresh_label()
	_try_player_claim()
	_try_pad_scan()

func _try_player_claim() -> void:
	if _claim_cd > 0.0:
		return
	if not Input.is_physical_key_pressed(KEY_C):
		return
	var actor := _find_actor()
	if actor == null:
		return
	if actor.global_position.distance_to(global_position) > claim_radius:
		return
	var fac := "Cybernex"
	if actor.has_method("get_faction"):
		fac = str(actor.get_faction())
	elif GameManager:
		fac = GameManager.get_faction_name()
	claim(fac, PULSE_STR)
	_claim_cd = 0.85

func _find_actor() -> Node3D:
	_actor_cache_t -= get_process_delta_time() if is_inside_tree() else 0.0
	if _actor_cache != null and is_instance_valid(_actor_cache) and _actor_cache_t > 0.0:
		return _actor_cache
	_actor_cache_t = 0.4
	if SoftScanCache:
		_actor_cache = SoftScanCache.get_player()
		return _actor_cache
	var tree := get_tree()
	if tree == null:
		return null
	for p in tree.get_nodes_in_group("player"):
		if p is Node3D:
			_actor_cache = p as Node3D
			return _actor_cache
	for s in tree.get_nodes_in_group("ship"):
		if s is Node3D:
			_actor_cache = s as Node3D
			return _actor_cache
	_actor_cache = null
	return null

func claim(faction_name: String, strength: float = 1.0) -> void:
	_nudge_claim(faction_name, strength, true)


func on_hacked(caster: Node, amount: float = 1.0) -> void:
	var fac := "Cybernex"
	if caster and caster.has_method("get_faction"):
		fac = str(caster.get_faction())
	elif GameManager:
		fac = GameManager.get_faction_name()
	_nudge_claim(fac, HACK_STR + maxf(amount, 0.0) * 0.04, true)


func get_contest_side() -> String:
	return _contest_side


func get_claim_need() -> float:
	return CLAIM_NEED


func _tick_occupy(delta: float) -> void:
	if ownership == null:
		return
	var actor := _find_actor()
	var in_zone := actor != null and is_instance_valid(actor) \
		and actor.global_position.distance_to(global_position) <= claim_radius
	var pfac := "Cybernex"
	if in_zone:
		if actor.has_method("get_faction"):
			pfac = str(actor.get_faction())
		elif GameManager:
			pfac = GameManager.get_faction_name()
	var hostile := ownership.is_fully_owned() and ownership.faction_name() != pfac
	if in_zone:
		_occupy_in_t += delta
		if _occupy_in_t >= 0.35:
			var same_hold := ownership.is_fully_owned() and ownership.faction_name() == pfac
			if not same_hold:
				_nudge_claim(pfac, OCCUPY_RATE * delta, false)
		if hostile or _status == "contested":
			_ensure_guard()
	else:
		_occupy_in_t = 0.0
		if _status == "contested":
			_decay_contest(delta)
	if in_zone and _guard_alive():
		var gf := ""
		if _guard.has_method("get_faction"):
			gf = str(_guard.get_faction())
		if gf != "" and gf != "Neutral":
			_nudge_claim(gf, GUARD_RATE * delta, false)
	if ownership.is_fully_owned() and _status != "contested":
		_clear_guard()
	_occupy_label_t += delta
	if _occupy_label_t >= 0.35:
		_occupy_label_t = 0.0
		if _status == "contested":
			_refresh_label()
			_set_contested_ring(true)


func _decay_contest(delta: float) -> void:
	if ownership == null or ownership.current_faction != OwnershipData.Faction.CONTESTED:
		return
	ownership.claim_strength = maxf(0.0, ownership.claim_strength - DECAY_RATE * delta)
	if ownership.claim_strength > 0.02:
		return
	var prev: OwnershipData.Faction = ownership.previous_faction
	_contest_side = ""
	_clear_guard()
	if prev == OwnershipData.Faction.NEUTRAL or prev == OwnershipData.Faction.CONTESTED:
		ownership.current_faction = OwnershipData.Faction.NEUTRAL
		ownership.claim_strength = 0.0
		_status = "unclaimed"
		_set_contested_ring(false)
	else:
		ownership.current_faction = prev
		ownership.transition_progress = 1.0
		ownership.claim_strength = 0.0
		_status = "owned"
		_set_contested_ring(false)
	_apply_faction_visual()
	_refresh_label()
	print("[PadBase] contest decayed → ", ownership.faction_name(), " @ ", name)


func _nudge_claim(faction_name: String, amount: float, noisy: bool) -> void:
	if ownership == null or amount <= 0.0005:
		return
	var f: OwnershipData.Faction = OwnershipData.from_string(faction_name)
	if f == OwnershipData.Faction.NEUTRAL or f == OwnershipData.Faction.CONTESTED:
		return
	var cur := ownership.current_faction
	if cur == OwnershipData.Faction.NEUTRAL:
		_meter_toward(faction_name, amount)
		if ownership.claim_strength >= 0.45:
			_lock_to(f, noisy)
		elif noisy:
			_pulse_feedback(false)
			_notify_hud("CLAIM %.0f%% — occupy the ring" % (ownership.claim_strength / 0.45 * 100.0))
		return
	if ownership.is_fully_owned() and cur == f:
		if noisy:
			_notify_hud("Pad held by %s — stay in zone to harvest" % faction_name)
		return
	if ownership.is_fully_owned() and cur != f:
		_open_contest(f, faction_name, amount)
		return
	if cur == OwnershipData.Faction.CONTESTED:
		_meter_toward(faction_name, amount)
		if ownership.claim_strength >= CLAIM_NEED:
			_lock_to(f, true)
		else:
			_status = "contested"
			if noisy:
				_pulse_feedback(false)
				_notify_hud("OCCUPY %.0f%% → %s  ·  C pulse / Hack" % [
					clampf(ownership.claim_strength / CLAIM_NEED, 0.0, 1.0) * 100.0,
					_contest_side,
				])
			_bind_layer_claim()
		return
	# In-progress transition toward another faction
	if cur != f:
		_open_contest(f, faction_name, amount)


func _meter_toward(faction_name: String, amount: float) -> void:
	if _contest_side == "" or _contest_side == faction_name:
		_contest_side = faction_name
		ownership.claim_strength += amount
	else:
		ownership.claim_strength -= amount
		if ownership.claim_strength <= 0.0:
			_contest_side = faction_name
			ownership.claim_strength = absf(ownership.claim_strength)


func _open_contest(f: OwnershipData.Faction, faction_name: String, amount: float) -> void:
	ownership.previous_faction = ownership.current_faction
	ownership.current_faction = OwnershipData.Faction.CONTESTED
	ownership.transition_progress = 0.35
	_contest_side = faction_name
	ownership.claim_strength = maxf(amount, 0.05)
	_status = "contested"
	_set_contested_ring(true)
	_apply_faction_visual()
	_refresh_label()
	_ensure_guard()
	if SessionObjectives and not _seeding:
		SessionObjectives.on_claim_or_obj()
	if _seeding:
		claimed.emit("Contested")
		return
	if AudioDirector:
		if AudioDirector.has_method("play_contest"):
			AudioDirector.play_contest()
		else:
			AudioDirector.play_claim()
	if CombatJuice:
		CombatJuice.hit_feedback(6.0, global_position, false)
	_spawn_claim_fx(Color(1.0, 0.55, 0.15))
	if _contest_ring and _contest_ring.has_method("pulse"):
		_contest_ring.pulse()
	claimed.emit("Contested")
	print("[PadBase] CONTESTED ", ownership.previous_faction, " vs ", f, " @ ", name)
	_notify_hud("CONTESTED — occupy the ring · C pulse · Hack (soft, no P2W)")
	var ic: String = _SoftK.intercept_claim_toast(faction_name)
	if ic != "":
		_notify_hud(ic)
	var tip: String = _SoftK.structure_tip(ownership.faction_name() if ownership else "")
	if tip != "":
		_notify_hud(tip)


func _lock_to(f: OwnershipData.Faction, noisy: bool) -> void:
	ownership.start_transition(f)
	ownership.claim_strength = 0.0
	_contest_side = ""
	_status = "claiming"
	_set_contested_ring(false)
	_clear_guard()
	_apply_faction_visual()
	_refresh_label()
	_update_city_density()
	if SessionObjectives and not _seeding:
		SessionObjectives.on_claim_or_obj()
	if noisy and not _seeding:
		if AudioDirector:
			AudioDirector.play_claim()
		if CombatJuice:
			CombatJuice.hit_feedback(12.0, global_position, true)
		_claim_pylon_pulse(true)
		var win_c := Color(0.15, 0.85, 1.0) if ownership.faction_name() == "Cybernex" else Color(0.95, 0.12, 0.42)
		_spawn_claim_fx(win_c)
		_notify_hud("Claim locked → %s. Harvest = Contribution (no combat power)." % ownership.faction_name())
	claimed.emit(ownership.faction_name())
	_bind_layer_claim()
	call_deferred("_ensure_claim_beacon")
	print("[PadBase] claim → ", ownership.faction_name(), " @ ", name)


func _pulse_feedback(strong: bool) -> void:
	if AudioDirector and AudioDirector.has_method("play_claim_pulse"):
		AudioDirector.play_claim_pulse()
	elif AudioDirector:
		AudioDirector.play_ui()
	if _contest_ring and _contest_ring.has_method("pulse"):
		_contest_ring.pulse()
	_spawn_claim_fx(Color(1.0, 0.6, 0.2))
	_claim_pylon_pulse(strong)


func _guard_alive() -> bool:
	if _guard == null or not is_instance_valid(_guard):
		return false
	if _guard.has_method("is_alive"):
		return bool(_guard.is_alive())
	if "_alive" in _guard and not bool(_guard._alive):
		return false
	return true


func get_guard() -> Node3D:
	return _guard if _guard_alive() else null


func _tick_guard_respawn(delta: float) -> void:
	if _status != "contested":
		_guard_respawn_t = 0.0
		return
	if _guard_alive():
		return
	if _guard_respawn_t <= 0.0:
		return
	_guard_respawn_t -= delta
	if _guard_respawn_t > 0.0:
		return
	if _guard != null and is_instance_valid(_guard):
		_guard.queue_free()
	_guard = null
	_ensure_guard()


func _on_guard_died() -> void:
	_guard_respawn_t = 8.0
	_notify_hud("PAD GUARD DOWN — occupy the ring")
	print("[PadBase] guard down @ ", name)


func _ensure_guard() -> void:
	if _guard_alive():
		return
	var fac := "gROT"
	if ownership:
		if ownership.is_fully_owned():
			fac = ownership.faction_name()
		elif ownership.previous_faction == OwnershipData.Faction.GROT:
			fac = "gROT"
		elif ownership.previous_faction == OwnershipData.Faction.CYBERNEX:
			fac = "Cybernex"
		elif default_faction != "":
			fac = default_faction
	if fac == "Contested" or fac == "Neutral":
		fac = "gROT"
	var t := Node3D.new()
	t.name = "PadContestGuard"
	t.set_script(preload("res://scripts/combat/Turret.gd"))
	t.set("faction", fac)
	t.set("target_player", true)
	t.set("aggro_range", 38.0)
	t.set("fire_rate", 1.25)
	t.set("damage", 5.0)
	add_child(t)
	t.position = Vector3(9.0, 1.15, 7.0)
	var up := Vector3.UP
	var pad_n: Node = get_parent()
	while pad_n:
		if pad_n.has_meta("pad_up"):
			up = pad_n.get_meta("pad_up")
			break
		pad_n = pad_n.get_parent()
	if t.has_method("set_aim_up"):
		t.set_aim_up(up)
	if t.has_signal("died") and not t.died.is_connected(_on_guard_died):
		t.died.connect(_on_guard_died)
	if t.is_in_group("ally"):
		t.remove_from_group("ally")
	t.add_to_group("enemy")
	if SoftScanCache:
		SoftScanCache.invalidate_enemies()
	_guard = t
	print("[PadBase] contest guard ", fac, " @ ", name)


func _clear_guard() -> void:
	if _guard != null and is_instance_valid(_guard):
		_guard.queue_free()
	_guard = null

func _tick_harvest(delta: float) -> void:
	if crystal_reserves <= 0.0:
		_status = "depleted"
		_refresh_label()
		return
	var got: float = minf(crystal_reserves, extract_rate * delta)
	crystal_reserves -= got
	total_extracted += got
	var econ: float = got * contribution_per_unit
	if GameManager:
		# Asymmetric soft economy (CONCEPT): Cybernex Contribution vs gROT Biomass
		GameManager.deposit_economy(econ, true)
		_harvest_accum_fx += econ
		_harvest_fx_cd -= delta
		if _harvest_fx_cd <= 0.0 and _harvest_accum_fx > 0.4:
			_harvest_fx_cd = 1.8
			if AudioDirector and AudioDirector.has_method("play_ui"):
				AudioDirector.play_ui()
			_notify_hud("HARVEST +%.1f  %s" % [_harvest_accum_fx, GameManager.economy_label()])
			_harvest_accum_fx = 0.0
	harvested.emit(got, total_extracted)
	_status = "extracting"
	_refresh_label()

func _apply_faction_visual() -> void:
	var fac := ownership.faction_name() if ownership else "Neutral"
	var col := Color(0.55, 0.55, 0.6)
	match fac:
		"Cybernex":
			col = Color(0.15, 0.85, 1.0)
		"gROT":
			col = Color(0.95, 0.12, 0.42)
		"Contested":
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
			col = Color(0.15, 0.85, 1.0).lerp(Color(0.95, 0.12, 0.42), pulse)
	var tp: float = ownership.transition_progress if ownership else 1.0
	if fac == "Contested":
		tp = 1.0
	_tint_recursive(get_parent(), col, tp)

func _tint_recursive(n: Node, col: Color, t: float) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var mat := StandardMaterial3D.new()
		mat.metallic = 0.55
		mat.roughness = 0.4
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.4 + 1.2 * t
		mat.albedo_color = Color(0.08, 0.1, 0.12).lerp(col * 0.35, t)
		mi.material_override = mat
	for c in n.get_children():
		_tint_recursive(c, col, t)

func _refresh_label() -> void:
	if _label == null or ownership == null:
		return
	var meter := ""
	if _status == "contested" and _contest_side != "":
		var pct := int(clampf(ownership.claim_strength / CLAIM_NEED, 0.0, 1.0) * 100.0)
		meter = " → %s %d%%" % [_contest_side, pct]
	_label.text = "BASE %s\n%s%s  %s\nEXT %.0f / R%.0f" % [
		ownership.faction_name().to_upper(),
		_status,
		meter,
		GameManager.economy_label() if GameManager else "—",
		total_extracted,
		crystal_reserves,
	]
	match ownership.faction_name():
		"Cybernex":
			_label.modulate = Color(0.5, 0.95, 1.0)
		"gROT":
			_label.modulate = Color(1.0, 0.45, 0.55)
		"Contested":
			_label.modulate = Color(1.0, 0.7, 0.25)
		_:
			_label.modulate = Color(0.85, 0.85, 0.9)

func get_claim_status() -> String:
	return _status


func harvest_hud_line() -> String:
	if _status != "extracting":
		return ""
	var rate: float = extract_rate * contribution_per_unit
	var unit := "CONTRIB"
	if GameManager and GameManager.has_method("get_faction_name") and str(GameManager.get_faction_name()) == "gROT":
		unit = "BIOMASS"
	elif ownership and ownership.faction_name() == "gROT":
		unit = "BIOMASS"
	return "EXTRACTING  %s +%.1f/s  R%.0f" % [unit, rate, crystal_reserves]


func get_occupy_strength() -> float:
	return ownership.claim_strength if ownership else 0.0


func _owner_in_zone() -> bool:
	if ownership == null or not ownership.is_fully_owned():
		return false
	var own_fac := ownership.faction_name()
	if _actor_holds_zone(own_fac):
		return true
	return _landed_ship_holds_zone(own_fac)


func _actor_holds_zone(own_fac: String) -> bool:
	var actor := _find_actor()
	if actor == null or not is_instance_valid(actor):
		return false
	if actor.global_position.distance_to(global_position) > claim_radius:
		return false
	var pfac := "Cybernex"
	if actor.has_method("get_faction"):
		pfac = str(actor.get_faction())
	elif GameManager:
		pfac = GameManager.get_faction_name()
	return pfac == own_fac


func _landed_ship_holds_zone(own_fac: String) -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	for s in tree.get_nodes_in_group("ship"):
		if s == null or not is_instance_valid(s):
			continue
		if not bool(s.get("is_landed")):
			continue
		var sfac := "Cybernex"
		if s.has_method("get_faction"):
			sfac = str(s.get_faction())
		if sfac != own_fac:
			continue
		if _ship_landed_on_this(s):
			return true
	return false


func _ship_landed_on_this(ship: Node) -> bool:
	var pad: Node = null
	if ship.has_method("get_landed_pad"):
		pad = ship.get_landed_pad()
	elif "_landed_pad" in ship:
		pad = ship.get("_landed_pad")
	if pad != null and is_instance_valid(pad):
		if pad == self:
			return true
		if pad is Node and (pad == get_parent() or pad.is_ancestor_of(self) or is_ancestor_of(pad)):
			return true
	if ship is Node3D:
		return (ship as Node3D).global_position.distance_to(global_position) <= claim_radius
	return false


func get_faction() -> String:
	return ownership.faction_name() if ownership else "Neutral"

func swap_cluster_theme(faction_name: String) -> void:
	var cluster := get_parent()
	if cluster == null:
		return
	var fac := faction_name
	if fac == "Contested" or fac == "Neutral":
		return
	for c in cluster.get_children():
		if c == self:
			continue
		if c.has_method("reload_for_faction"):
			c.reload_for_faction(fac)
	print("[PadBase] dual-theme cluster → ", fac)

func _set_contested_ring(on: bool) -> void:
	if _contest_ring and _contest_ring.has_method("set_contested"):
		var stren := ownership.claim_strength if ownership else 0.0
		_contest_ring.set_contested(on, stren)

func _notify_hud(msg: String) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("game_hud"):
		if n.has_method("push_toast"):
			n.push_toast(msg, 3.2)
			return



func _ensure_claim_beacon() -> void:
	if has_node("ClaimBeaconVis"):
		return
	var root := Node3D.new()
	root.name = "ClaimBeaconVis"
	add_child(root)
	var loaded := false
	var fac := "cybernex"
	if ownership:
		var fn := ownership.faction_name().to_lower()
		if fn == "grot":
			fac = "grot"
	var rels := [
		"props/ownership_claim_pylon/ownership_claim_pylon_%s_lod1.glb" % fac,
		"props/ownership_claim_pylon/ownership_claim_pylon_%s_lod2.glb" % fac,
		"props/faction_claim_totem/faction_claim_totem_%s_lod1.glb" % fac,
		"props/claim_beacon/claim_beacon_%s_lod1.glb" % fac,
	]
	var AP = load("res://scripts/assets/AssetPaths.gd")
	for rel in rels:
		var path := ""
		if AP and AP.has_method("resolve"):
			path = AP.resolve(rel)
		if path == "" or not FileAccess.file_exists(path):
			continue
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_file(path, st) != OK:
			continue
		var scn := doc.generate_scene(st)
		if scn:
			root.add_child(scn)
			scn.scale = Vector3.ONE * 1.4
			scn.position = Vector3(0, 0.2, 0)
			loaded = true
			break
	if not loaded:
		_build_proc_pylon(root)


func _build_proc_pylon(root: Node3D) -> void:
	var fac := "Cybernex"
	if ownership:
		fac = ownership.faction_name() if ownership.has_method("faction_name") else fac
	var col := Color(0.2, 0.85, 1.0)
	if fac == "gROT":
		col = Color(0.95, 0.12, 0.42)
	elif fac == "Contested":
		col = Color(1.0, 0.65, 0.2)
	elif fac == "Neutral":
		col = Color(0.65, 0.7, 0.75)
	var armor := StandardMaterial3D.new()
	armor.albedo_color = Color(0.1, 0.12, 0.16)
	armor.metallic = 0.7
	armor.roughness = 0.35
	armor.emission_enabled = true
	armor.emission = col
	armor.emission_energy_multiplier = 0.7
	var emit := StandardMaterial3D.new()
	emit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	emit.albedo_color = col
	emit.emission_enabled = true
	emit.emission = col
	emit.emission_energy_multiplier = 2.2
	var disc := CylinderMesh.new()
	disc.top_radius = 0.85
	disc.bottom_radius = 0.95
	disc.height = 0.14
	disc.radial_segments = 12
	var base := MeshInstance3D.new()
	base.mesh = disc
	base.material_override = armor
	base.position.y = 0.07
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(base)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.28
	cyl.height = 4.2
	cyl.radial_segments = 8
	var shaft := MeshInstance3D.new()
	shaft.mesh = cyl
	shaft.material_override = armor
	shaft.position.y = 2.2
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shaft)
	var rod := CylinderMesh.new()
	rod.top_radius = 0.05
	rod.bottom_radius = 0.05
	rod.height = 4.4
	var core := MeshInstance3D.new()
	core.mesh = rod
	core.material_override = emit
	core.position.y = 2.25
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(core)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.22
	torus.outer_radius = 0.48
	torus.rings = 10
	torus.ring_segments = 16
	var crown := MeshInstance3D.new()
	crown.mesh = torus
	crown.material_override = emit
	crown.position.y = 4.35
	crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(crown)
	for i in 3:
		var box := BoxMesh.new()
		box.size = Vector3(0.06, 1.6, 0.28)
		var fin := MeshInstance3D.new()
		fin.mesh = box
		fin.material_override = emit
		fin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(fin)
		fin.position = Vector3(cos(float(i) * TAU / 3.0) * 0.32, 1.4, sin(float(i) * TAU / 3.0) * 0.32)
		fin.rotation.y = float(i) * TAU / 3.0
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq == null or int(gq.tier) >= 1:
		var light := OmniLight3D.new()
		light.omni_range = 10.0
		light.light_energy = 1.1
		light.light_color = col
		light.shadow_enabled = false
		light.position = Vector3(0, 3.6, 0)
		root.add_child(light)


func _spawn_claim_fx(col: Color) -> void:
	var NP = load("res://scripts/fx/NeonParticles.gd")
	if NP:
		NP.claim_radial(global_position, col, get_tree())
		return
	var p := GPUParticles3D.new()
	p.amount = 24
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 0.95
	p.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 7.0
	pm.gravity = Vector3(0, -3, 0)
	pm.color = col
	p.process_material = pm
	var dm := SphereMesh.new()
	dm.radius = 0.08
	dm.height = 0.16
	p.draw_pass_1 = dm
	p.position = Vector3(0, 1.5, 0)
	add_child(p)
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free()
	)


func _update_city_density() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var city = parent.get_node_or_null("CityNightLights")
	if city == null:
		# pads_root may be parent of this pad; go up
		var pr = parent.get_parent()
		if pr:
			city = pr.get_node_or_null("CityNightLights")
	if city == null or not city.has_method("set_density"):
		return
	var fac := ownership.faction_name() if ownership else "Neutral"
	var dens := 0.45
	if fac == "Contested":
		dens = 0.7
	elif fac != "Neutral" and fac != "":
		dens = 1.0
		if ownership and ownership.claim_strength > 0.0:
			dens = 1.0 + clampf(ownership.claim_strength / 1.75, 0.0, 0.4)
	city.call("set_density", dens, fac)


var _pad_scan_cd: float = 0.0
var _actor_cache: Node3D = null
var _actor_cache_t: float = 0.0


func _bind_layer_claim() -> void:
	if LayerContext == null:
		return
	LayerContext.set_claim(str(name))
	if LayerContext.active_quest_id == "":
		LayerContext.set_quest("slice_claim_%s" % name)
	if LayerContext.site_pin_id == "":
		var pin := str(get_meta("site_pin_id", ""))
		if pin == "":
			pin = "SITE_SPACE_TEST_PAD"
		LayerContext.set_site_pin(pin)

func _try_pad_scan() -> void:
	_pad_scan_cd = maxf(0.0, _pad_scan_cd - get_process_delta_time())
	if _pad_scan_cd > 0.0:
		return
	if not Input.is_physical_key_pressed(KEY_V):
		return
	var actor := _find_actor()
	if actor == null:
		return
	if actor.global_position.distance_to(global_position) > claim_radius * 0.85:
		return
	_pad_scan_cd = 1.5
	soft_scan()


func soft_scan() -> String:
	## V intel: ownership + reserves. Soft Knowledge only (no combat power).
	var fac := ownership.faction_name() if ownership else "Neutral"
	var stren := ownership.claim_strength if ownership else 0.0
	var line := "Pad scan: %s  claim=%.2f  reserves=%.0f  (soft intel)" % [fac, stren, crystal_reserves]
	_notify_hud(line)
	if AudioDirector and AudioDirector.has_method("play_ui"):
		AudioDirector.play_ui()
	return line


func _claim_pylon_pulse(strong: bool = false) -> void:
	var light := OmniLight3D.new()
	light.omni_range = 22.0 if strong else 14.0
	light.light_energy = 4.5 if strong else 2.2
	var fac := "Cybernex"
	if ownership:
		fac = ownership.faction_name() if ownership.has_method("faction_name") else fac
	light.light_color = Color(0.95, 0.25, 0.4) if fac == "gROT" else Color(0.25, 0.8, 1.0)
	light.shadow_enabled = false
	add_child(light)
	light.position = Vector3(0, 6.0, 0)
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.55 if strong else 0.35)
	tw.tween_callback(light.queue_free)


func _tick_contest_fov(delta: float) -> void:
	## Soft FOV widen while player stands in contested pad — camera readability only.
	if _status != "contested":
		_restore_fov(delta)
		return
	var actor := _find_actor()
	if actor == null or not is_instance_valid(actor):
		_restore_fov(delta)
		return
	if actor.global_position.distance_to(global_position) > claim_radius:
		_restore_fov(delta)
		return
	var cam: Camera3D = null
	if actor.has_node("CameraPivot/Camera3D"):
		cam = actor.get_node("CameraPivot/Camera3D") as Camera3D
	elif actor.has_node("CamPivot/Camera3D"):
		cam = actor.get_node("CamPivot/Camera3D") as Camera3D
	else:
		for c in actor.find_children("*", "Camera3D", true, false):
			cam = c as Camera3D
			break
	if cam == null:
		return
	if _contest_fov_t <= 0.0:
		_base_fov = cam.fov
	_contest_fov_t = 0.5
	var target := minf(_base_fov + 6.0, 85.0)
	cam.fov = lerpf(cam.fov, target, clampf(delta * 3.0, 0.0, 1.0))


func _restore_fov(delta: float) -> void:
	if _contest_fov_t <= 0.0:
		return
	_contest_fov_t = maxf(0.0, _contest_fov_t - delta)
	var actor := _find_actor()
	if actor == null:
		return
	var cam: Camera3D = null
	if actor.has_node("CameraPivot/Camera3D"):
		cam = actor.get_node("CameraPivot/Camera3D") as Camera3D
	elif actor.has_node("CamPivot/Camera3D"):
		cam = actor.get_node("CamPivot/Camera3D") as Camera3D
	if cam and _base_fov > 1.0:
		cam.fov = lerpf(cam.fov, _base_fov, clampf(delta * 2.5, 0.0, 1.0))



func _harvest_vfx() -> void:
	## Soft neon extract burst + rising motes (budget via NeonParticles pool).
	if DisplayServer.get_name() == "headless":
		return
	var host: Node3D = get_parent() as Node3D
	if host == null:
		host = self
	var pos: Vector3 = host.global_position + Vector3(0, 1.2, 0)
	if has_meta("pad_up"):
		pos = host.global_position + (get_meta("pad_up") as Vector3) * 1.4
	var fac := ownership.faction_name() if ownership else "Neutral"
	var col := Color(0.3, 0.9, 1.0, 0.9)
	if fac == "gROT":
		col = Color(0.95, 0.2, 0.45, 0.9)
	elif fac == "Contested":
		col = Color(1.0, 0.75, 0.2, 0.9)
	var NP = load("res://scripts/fx/NeonParticles.gd")
	if NP:
		NP.burst(pos, col, get_tree(), 10, 3.5)
		if NP.has_method("claim_pulse"):
			NP.claim_radial(pos, col, get_tree())
	# Soft pillar flash
	var flash := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.35
	cyl.height = 2.4
	flash.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(col.r, col.g, col.b, 0.55)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.0
	flash.material_override = mat
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(flash)
	flash.global_position = pos
	var tw := host.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.55)
	tw.parallel().tween_property(mat, "emission_energy_multiplier", 0.0, 0.55)
	tw.tween_callback(flash.queue_free)
