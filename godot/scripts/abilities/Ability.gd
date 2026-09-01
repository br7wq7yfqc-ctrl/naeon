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

## HF-A: last apply refuse (e.g. Infection cap 5). Empty on success.
var last_refuse: String = ""

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
		if not EE.spend(caster, energy_cost):
			print("[Ability] ", ability_name, " denied — energy")
			return
	elif caster != null and caster.has_method("spend_energy"):
		caster.spend_energy(energy_cost)
	var VFX = load("res://scripts/abilities/AbilityVfx.gd")
	if VFX and caster:
		VFX.cast_flash(caster, effect_color if effect_color.a > 0.0 else Color(0.3, 0.9, 1.0))
	if biomass_cost > 0.0 and caster != null and caster.has_method("spend_biomass"):
		caster.spend_biomass(biomass_cost)
	last_refuse = ""
	if is_channeled and channel_time > 0.0:
		# ChannelController on caster completes → _apply_effect
		print("[Ability] ", ability_name, " channeling…")
		return
	_apply_effect(caster, target)
	print("[Ability] ", ability_name, " activated")

func finish_channel(caster: Node, target = null) -> void:
	_apply_effect(caster, target)
	print("[Ability] ", ability_name, " channel complete")

func _apply_effect(caster: Node, target = null) -> void:
	last_refuse = ""
	if ability_name == "Form Cycle":
		if caster and caster.has_method("_cycle_form"):
			caster._cycle_form()
		elif caster and caster.has_method("cycle_form"):
			caster.cycle_form()
		return
	if is_hacking:
		_apply_hacking(caster, target)
	elif is_firewall:
		_apply_firewall(caster, target)
	elif damage > 0.0 and aoe_radius > 0.05:
		_apply_aoe_burst(caster)
	elif damage > 0.0:
		_spawn_projectile(caster, damage, effect_color)
	elif heal > 0.0 and caster.has_method("heal"):
		caster.heal(heal)

func _apply_aoe_burst(caster: Node) -> void:
	if caster == null or not (caster is Node3D) or not caster.is_inside_tree():
		return
	var origin: Vector3 = (caster as Node3D).global_position
	var tree: SceneTree = caster.get_tree()
	if tree == null:
		return
	var rad := maxf(aoe_radius, 0.5)
	var fac := "Cybernex"
	if "faction" in caster:
		fac = str(caster.faction)
	elif caster.has_method("get_faction"):
		fac = str(caster.get_faction())
	# Knowledge stays soft (rules/08) — no raw damage bonus here.
	var dmg: float = damage
	var Hits = load("res://scripts/combat/CombatHits.gd")
	# Snapshot: a kill inside the loop invalidates the shared cache array.
	var targets: Array = []
	for g in ["enemy", "player", "ship", "ally"]:
		for n in tree.get_nodes_in_group(g):
			if n != null and is_instance_valid(n) and not targets.has(n):
				targets.append(n)
	for e in targets:
		if e == null or not is_instance_valid(e) or e == caster or not (e is Node3D):
			continue
		if e.has_method("get_faction") and str(e.get_faction()) == fac:
			continue
		if "faction" in e and str(e.faction) == fac:
			continue
		var dist: float = origin.distance_to((e as Node3D).global_position)
		if dist > rad:
			continue
		if e.has_method("take_damage"):
			e.take_damage(dmg, fac)
		if Hits:
			var away: Vector3 = (e as Node3D).global_position - origin
			var knock_dmg := force if force > 0.05 else dmg
			Hits.apply_planar_knock(e, away, knock_dmg, 1.6)
	var NP = load("res://scripts/fx/NeonParticles.gd")
	if NP:
		NP.burst(origin + Vector3(0, 0.6, 0), effect_color, tree, 14, 7.0)
	var VFX = load("res://scripts/abilities/AbilityVfx.gd")
	if VFX:
		VFX.cast_flash(caster, effect_color, 3.2)


func _apply_hacking(caster: Node, hint = null) -> void:
	last_refuse = ""
	var hit: Dictionary = _ray_query(caster, range)
	var target: Node = _usable_infection_host(caster, hint)
	var hit_pos: Vector3 = caster.global_position if caster is Node3D else Vector3.ZERO
	if target == null and not hit.is_empty():
		var col_v: Variant = hit.get("collider")
		var col: Node = col_v as Node
		target = _find_hackable(col)
		hit_pos = hit.get("position", hit_pos)
		if target == null:
			print("[Hacking] Hit non-hackable: ", col)
	if target == null:
		target = _nearest_hack_pad(caster)
	if target:
		if target.has_method("apply_infection"):
			last_refuse = str(target.apply_infection(1))
			if last_refuse != "":
				print("[Hacking] ", last_refuse)
			elif target is Node3D:
				hit_pos = (target as Node3D).global_position
		elif target.has_method("on_hacked"):
			target.on_hacked(caster, damage)
			if target is Node3D:
				hit_pos = (target as Node3D).global_position
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
	var fac := ""
	if "faction" in caster:
		fac = str(caster.faction)
	elif caster.has_method("get_faction"):
		fac = str(caster.get_faction())
	for n in caster.get_tree().get_nodes_in_group("pad_bases"):
		if n == null or not is_instance_valid(n) or not (n is Node3D):
			continue
		if not n.has_method("on_hacked"):
			continue
		var d: float = origin.distance_to((n as Node3D).global_position)
		if d < best_d:
			best = n
			best_d = d
	for n in caster.get_tree().get_nodes_in_group("hackable"):
		if n == null or not is_instance_valid(n) or n == caster or not (n is Node3D):
			continue
		if not n.has_method("on_hacked"):
			continue
		# Never auto-acquire your own side (rules/04 counterplay, no friendly fire).
		if fac != "" and n.has_method("get_faction") and str(n.get_faction()) == fac:
			continue
		var d2: float = origin.distance_to((n as Node3D).global_position)
		if d2 < best_d:
			best = n
			best_d = d2
	return best

func _is_infection_host(node: Node) -> bool:
	if node == null:
		return false
	return node.has_method("apply_infection") or node.has_method("on_hacked") \
			or node.get_node_or_null("InfectionStatus") != null


func _find_hackable(node: Node) -> Node:
	if node == null:
		return null
	if _is_infection_host(node):
		return node
	for c in node.get_children():
		if _is_infection_host(c):
			return c
	var p: Node = node.get_parent()
	if p and _is_infection_host(p):
		return p
	if p:
		for c in p.get_children():
			if _is_infection_host(c):
				return c
	return null

func _apply_firewall(caster: Node, hint = null) -> void:
	last_refuse = ""
	var host: Node = _usable_infection_host(caster, hint, true)
	if host == null:
		host = _nearest_infected_host(caster)
	if host != null:
		if host.has_method("purge_infection"):
			host.purge_infection(1)
		else:
			var inf: Node = host.get_node_or_null("InfectionStatus")
			if inf != null and inf.has_method("remove_one"):
				inf.remove_one()
			elif inf != null and inf.has_method("remove_stacks"):
				inf.remove_stacks(1)
	if caster.has_method("apply_firewall"):
		caster.apply_firewall(duration, heal)
	_spawn_shield_fx(caster, effect_color if effect_color.a > 0.0 else Color(0.2, 1.0, 0.7))


func _host_world_pos(host: Node) -> Vector3:
	if host == null:
		return Vector3.ZERO
	if host is Node3D:
		return (host as Node3D).global_position
	if host.has_method("hull"):
		var h: Variant = host.call("hull")
		if h is Node3D and is_instance_valid(h):
			return (h as Node3D).global_position
	var p := host.get_parent()
	if p is Node3D:
		return (p as Node3D).global_position
	return Vector3.ZERO


func _usable_infection_host(caster: Node, hint, allow_zero: bool = false) -> Node:
	if hint == null or not (hint is Node) or not is_instance_valid(hint):
		return null
	var host: Node = hint as Node
	if not _is_infection_host(host):
		return null
	if caster is Node3D:
		var reach := maxf(range, 18.0)
		var dest := _host_world_pos(host)
		if dest != Vector3.ZERO \
				and (caster as Node3D).global_position.distance_to(dest) > reach:
			return null
	if _same_side(caster, host) and not allow_zero:
		return null
	return host


func _nearest_infected_host(caster: Node) -> Node:
	if caster == null or not (caster is Node3D) or caster.get_tree() == null:
		return null
	var origin: Vector3 = (caster as Node3D).global_position
	var best: Node = null
	var best_d := maxf(range, 18.0)
	for g in ["hackable", "enemy", "player", "ship"]:
		for n in caster.get_tree().get_nodes_in_group(g):
			if n == null or not is_instance_valid(n) or n == caster:
				continue
			var host: Node = n
			if not _is_infection_host(host):
				var pilot: Node = n.get_node_or_null("NpcPilot") if n.has_method("get_node_or_null") else null
				if pilot != null and _is_infection_host(pilot):
					host = pilot
				else:
					continue
			var stacks := 0
			if host.has_method("infection_stacks"):
				stacks = int(host.infection_stacks())
			else:
				var inf: Node = host.get_node_or_null("InfectionStatus")
				if inf != null:
					stacks = int(inf.get("stacks"))
			if stacks <= 0:
				continue
			var dest := _host_world_pos(host)
			if dest == Vector3.ZERO:
				continue
			var d: float = origin.distance_to(dest)
			if d < best_d:
				best = host
				best_d = d
	return best


func _same_side(caster: Node, other: Node) -> bool:
	if caster == null or other == null:
		return false
	var a := ""
	var b := ""
	if caster.has_method("get_faction"):
		a = str(caster.get_faction())
	elif "faction" in caster:
		a = str(caster.faction)
	if other.has_method("get_faction"):
		b = str(other.get_faction())
	elif "faction" in other:
		b = str(other.faction)
	return a != "" and a == b

func _spawn_projectile(caster: Node, dmg: float, color: Color) -> void:
	if caster == null or not caster.is_inside_tree():
		return
	var Hits = load("res://scripts/combat/CombatHits.gd")
	var origin: Vector3 = caster.global_position + Vector3.UP * 1.4
	var dir: Vector3 = -caster.global_transform.basis.z
	if Hits:
		var aim: Array = Hits.aim_from(caster)
		origin = aim[0]
		dir = aim[1]
	# Knowledge stays soft (rules/08) — no raw damage bonus here.
	var final_dmg: float = dmg
	var fac := "Cybernex"
	if "faction" in caster:
		fac = str(caster.faction)
	elif caster.has_method("get_faction"):
		fac = str(caster.get_faction())
	var _Pool = load("res://scripts/combat/ProjectilePool.gd")
	_Pool.spawn(caster.get_tree(), origin, dir, 28.0, final_dmg, fac, color, 1.4, [caster])
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
	var Hits = load("res://scripts/combat/CombatHits.gd")
	var from: Vector3 = caster.global_position + Vector3.UP * 1.4
	var dir: Vector3 = -caster.global_transform.basis.z
	if Hits:
		var aim: Array = Hits.aim_from(caster)
		from = aim[0]
		dir = aim[1]
	var to: Vector3 = from + dir * max_range
	var q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	if caster is CollisionObject3D:
		q.exclude = [caster.get_rid()]
	q.collision_mask = 0xFFFFFFFF
	var result: Dictionary = space.intersect_ray(q)
	return result
