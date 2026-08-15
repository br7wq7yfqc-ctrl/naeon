class_name Ability
extends Resource

static var _ball_mesh: SphereMesh = null
static var _shield_mesh: SphereMesh = null
static var _mat_cache: Dictionary = {}  # key -> StandardMaterial3D
static var _proj_shape: SphereShape3D = null

static func _shared_ball_mesh() -> SphereMesh:
	if _ball_mesh == null:
		var sm := SphereMesh.new()
		sm.radius = 0.18
		sm.height = 0.36
		sm.radial_segments = 8
		sm.rings = 6
		_ball_mesh = sm
	return _ball_mesh

static func _shared_shield_mesh() -> SphereMesh:
	if _shield_mesh == null:
		var sm := SphereMesh.new()
		sm.radius = 1.4
		sm.height = 2.8
		sm.radial_segments = 12
		sm.rings = 8
		_shield_mesh = sm
	return _shield_mesh

static func _shared_shape() -> SphereShape3D:
	if _proj_shape == null:
		var sh := SphereShape3D.new()
		sh.radius = 0.2
		_proj_shape = sh
	return _proj_shape

static func _shared_mat(color: Color, alpha: float = 1.0, unshaded: bool = false) -> StandardMaterial3D:
	var key := "%d_%d_%d_%d_%d" % [int(color.r * 20.0), int(color.g * 20.0), int(color.b * 20.0), int(alpha * 10.0), (1 if unshaded else 0)]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.5 if alpha >= 0.99 else 1.5
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if alpha < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if _mat_cache.size() > 20:
		_mat_cache.clear()
	_mat_cache[key] = mat
	return mat


## Data-driven ability for TPS / MOBA / Strategy layers.

@export var ability_name: String = "Unnamed Ability"
@export var description: String = ""
@export var icon: Texture2D

@export_group("Costs & Cooldown")
@export var cooldown: float = 5.0
@export var energy_cost: float = 10.0
@export var biomass_cost: float = 0.0

@export_group("Targeting")
enum TargetingType { SELF, TARGET_ENEMY, TARGET_ALLY, TARGET_POINT, TARGET_DIRECTION, AOE }
@export var targeting: TargetingType = TargetingType.SELF
@export var range: float = 10.0
@export var aoe_radius: float = 0.0

@export_group("Faction")
enum FactionRestriction { ANY, CYBERNEX_ONLY, GROT_ONLY }
@export var faction_restriction: FactionRestriction = FactionRestriction.ANY

@export_group("Effects")
@export var duration: float = 0.0
@export var damage: float = 0.0
@export var heal: float = 0.0
@export var is_hacking: bool = false
@export var is_firewall: bool = false
@export var is_channeled: bool = false
@export var channel_time: float = 0.0  ## >0 starts ChannelController
@export var force: float = 0.0
@export var effect_color: Color = Color(0.0, 0.9, 1.0, 1.0)

func can_activate(caster: Node) -> bool:
	if caster == null:
		return false
	if caster.has_method("get_energy") and caster.get_energy() < energy_cost:
		return false
	if biomass_cost > 0.0 and caster.has_method("get_biomass") and caster.get_biomass() < biomass_cost:
		return false
	if faction_restriction != FactionRestriction.ANY and caster.has_method("get_faction"):
		var f = caster.get_faction()
		if faction_restriction == FactionRestriction.CYBERNEX_ONLY and f != "Cybernex":
			return false
		if faction_restriction == FactionRestriction.GROT_ONLY and f != "gROT":
			return false
	return true

func activate(caster: Node, target = null) -> void:
	var EE = load("res://scripts/systems/EnergyEconomy.gd")
	if EE and caster != null:
		EE.spend(caster, energy_cost)
	elif caster != null and caster.has_method("spend_energy"):
		caster.spend_energy(energy_cost)
	var VFX = load("res://scripts/abilities/AbilityVfx.gd")
	if VFX and caster:
		VFX.cast_flash(caster, effect_color if effect_color.a > 0.0 else Color(0.3, 0.9, 1.0))
	if biomass_cost > 0.0 and caster != null and caster.has_method("spend_biomass"):
		caster.spend_biomass(biomass_cost)
	if is_channeled and channel_time > 0.0:
		# ChannelController on caster completes → _apply_effect
		print("[Ability] ", ability_name, " channeling…")
		return
	_apply_effect(caster, target)
	print("[Ability] ", ability_name, " activated")

func finish_channel(caster: Node, target = null) -> void:
	_apply_effect(caster, target)
	print("[Ability] ", ability_name, " channel complete")

func _apply_effect(caster: Node, _target) -> void:
	if ability_name == "Form Cycle":
		if caster and caster.has_method("_cycle_form"):
			caster._cycle_form()
		elif caster and caster.has_method("cycle_form"):
			caster.cycle_form()
		return
	if is_hacking:
		_apply_hacking(caster)
	elif is_firewall:
		_apply_firewall(caster)
	elif damage > 0.0:
		_spawn_projectile(caster, damage, effect_color)
	elif heal > 0.0 and caster.has_method("heal"):
		caster.heal(heal)

func _apply_hacking(caster: Node) -> void:
	var hit: Dictionary = _ray_query(caster, range)
	var target: Node = null
	var hit_pos: Vector3 = caster.global_position if caster is Node3D else Vector3.ZERO
	if not hit.is_empty():
		var col_v: Variant = hit.get("collider")
		var col: Node = col_v as Node
		target = _find_hackable(col)
		hit_pos = hit.get("position", hit_pos)
		if target == null:
			print("[Hacking] Hit non-hackable: ", col)
	if target == null:
		target = _nearest_hack_pad(caster)
	if target:
		target.on_hacked(caster, damage)
	else:
		print("[Hacking] No target in range")
	if caster is Node3D:
		_spawn_beam(caster, hit_pos, Color(1.0, 0.2, 0.55))


func _nearest_hack_pad(caster: Node) -> Node:
	if caster == null or not (caster is Node3D) or caster.get_tree() == null:
		return null
	var origin: Vector3 = (caster as Node3D).global_position
	var best: Node = null
	var best_d := self.range
	for n in caster.get_tree().get_nodes_in_group("pad_bases"):
		if n == null or not is_instance_valid(n) or not (n is Node3D):
			continue
		if not n.has_method("on_hacked"):
			continue
		var d: float = origin.distance_to((n as Node3D).global_position)
		if d < best_d:
			best = n
			best_d = d
	return best

func _find_hackable(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("on_hacked"):
		return node
	for c in node.get_children():
		if c.has_method("on_hacked"):
			return c
	var p: Node = node.get_parent()
	if p and p.has_method("on_hacked"):
		return p
	if p:
		for c in p.get_children():
			if c.has_method("on_hacked"):
				return c
	return null

func _apply_firewall(caster: Node) -> void:
	if caster.has_method("apply_firewall"):
		caster.apply_firewall(duration, heal)
	_spawn_shield_fx(caster, effect_color if effect_color.a > 0.0 else Color(0.2, 1.0, 0.7))

func _spawn_projectile(caster: Node, dmg: float, color: Color) -> void:
	if caster == null or not caster.is_inside_tree():
		return
	var origin: Vector3 = caster.global_position + Vector3.UP * 1.4
	var dir: Vector3 = -caster.global_transform.basis.z
	if caster.has_node("CameraPivot/Camera3D"):
		var cam: Camera3D = caster.get_node("CameraPivot/Camera3D")
		dir = -cam.global_transform.basis.z
		origin = cam.global_position + dir * 0.8
	var final_dmg: float = dmg
	if GameManager:
		final_dmg *= 1.0 + GameManager.knowledge_insight_bonus()
	var fac := "Cybernex"
	if "faction" in caster:
		fac = str(caster.faction)
	elif caster.has_method("get_faction"):
		fac = str(caster.get_faction())
	var _Pool = load("res://scripts/combat/ProjectilePool.gd")
	_Pool.spawn(caster.get_tree(), origin, dir, 28.0, final_dmg, fac, color, 1.4)
	var NP = load("res://scripts/fx/NeonParticles.gd")
	if NP:
		NP.muzzle_flash(origin, dir, color, caster.get_tree())


func _spawn_beam(caster: Node, to: Vector3, color: Color) -> void:
	if caster == null or not caster.is_inside_tree():
		return
	var im := MeshInstance3D.new()
	var imm := ImmediateMesh.new()
	im.mesh = imm
	im.material_override = _shared_mat(color, 1.0, true)
	caster.get_tree().current_scene.add_child(im)
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINES)
	imm.surface_add_vertex(caster.global_position + Vector3.UP * 1.3)
	imm.surface_add_vertex(to)
	imm.surface_end()
	var tree: SceneTree = caster.get_tree()
	tree.create_timer(0.25).timeout.connect(func():
		if is_instance_valid(im):
			im.queue_free()
	)

func _spawn_shield_fx(caster: Node, color: Color) -> void:
	if caster == null:
		return
	var shell := MeshInstance3D.new()
	shell.mesh = _shared_shield_mesh()
	shell.material_override = _shared_mat(color, 0.25)
	caster.add_child(shell)
	shell.position = Vector3.UP * 1.0
	var dur: float = max(duration, 0.6)
	caster.get_tree().create_timer(dur).timeout.connect(func():
		if is_instance_valid(shell):
			shell.queue_free()
	)

func _ray_query(caster: Node, max_range: float) -> Dictionary:
	if caster == null or not caster.is_inside_tree():
		return {}
	var space: PhysicsDirectSpaceState3D = caster.get_world_3d().direct_space_state
	var from: Vector3 = caster.global_position + Vector3.UP * 1.4
	var dir: Vector3 = -caster.global_transform.basis.z
	if caster.has_node("CameraPivot/Camera3D"):
		var cam: Camera3D = caster.get_node("CameraPivot/Camera3D")
		from = cam.global_position
		dir = -cam.global_transform.basis.z
	var to: Vector3 = from + dir * max_range
	var q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	if caster is CollisionObject3D:
		q.exclude = [caster.get_rid()]
	q.collision_mask = 0xFFFFFFFF
	var result: Dictionary = space.intersect_ray(q)
	return result
