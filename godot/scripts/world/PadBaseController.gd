extends Node3D
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
var _claim_cd: float = 0.0

func _ready() -> void:
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
		claim(default_faction, 0.5)

func _ensure_label() -> void:
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 28
	_label.outline_size = 6
	_label.position = Vector3(0, 8, 0)
	add_child(_label)
	_refresh_label()

func _process(delta: float) -> void:
	_claim_cd = maxf(0.0, _claim_cd - delta)
	if ownership and ownership.transition_progress < 1.0:
		ownership.advance_transition(delta, 5.0)
		_apply_faction_visual()
		if ownership.transition_progress >= 1.0:
			_status = "owned"
			_set_contested_ring(false)
			swap_cluster_theme(ownership.faction_name())
			_refresh_label()
	if running and ownership and ownership.is_fully_owned():
		_tick_harvest(delta)
	_try_player_claim()

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
	claim(fac, 1.0)
	_claim_cd = 0.85

func _find_actor() -> Node3D:
	for s in get_tree().get_nodes_in_group("ship"):
		if s is Node3D:
			return s
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node3D:
			return p
	return null

func claim(faction_name: String, strength: float = 1.0) -> void:
	if ownership == null:
		return
	var f: OwnershipData.Faction = OwnershipData.from_string(faction_name)
	var cur := ownership.current_faction
	if cur != OwnershipData.Faction.NEUTRAL and cur != OwnershipData.Faction.CONTESTED and f != cur and f != OwnershipData.Faction.NEUTRAL:
		ownership.previous_faction = cur
		ownership.current_faction = OwnershipData.Faction.CONTESTED
		ownership.transition_progress = 0.35
		ownership.claim_strength += strength * 0.5
		_status = "contested"
		_set_contested_ring(true)
		_apply_faction_visual()
		_refresh_label()
		claimed.emit("Contested")
		print("[PadBase] CONTESTED ", ownership.previous_faction, " vs ", f, " @ ", name)
		return
	if ownership.current_faction == OwnershipData.Faction.CONTESTED:
		ownership.claim_strength += strength
		if ownership.claim_strength >= 2.0:
			ownership.start_transition(f)
			ownership.claim_strength = 0.0
			_status = "claiming"
			_set_contested_ring(false)
		else:
			_status = "contested"
			_set_contested_ring(true)
		_apply_faction_visual()
		_refresh_label()
		claimed.emit(ownership.faction_name())
		return
	ownership.claim_strength += strength
	ownership.start_transition(f)
	_status = "claiming"
	_set_contested_ring(false)
	_apply_faction_visual()
	_refresh_label()
	claimed.emit(ownership.faction_name())
	print("[PadBase] claim → ", ownership.faction_name(), " @ ", name)

func _tick_harvest(delta: float) -> void:
	if crystal_reserves <= 0.0:
		_status = "depleted"
		_refresh_label()
		return
	var got: float = minf(crystal_reserves, extract_rate * delta)
	crystal_reserves -= got
	total_extracted += got
	var contrib: float = got * contribution_per_unit
	if GameManager:
		GameManager.add_contribution(contrib)
		GameManager.add_mastery("colony_ops", got * 0.02)
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
	_label.text = "BASE %s\n%s  C:%.0f\nEXT %.0f / R%.0f" % [
		ownership.faction_name().to_upper(),
		_status,
		GameManager.contribution if GameManager else 0.0,
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
