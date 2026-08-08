class_name Ability
extends Resource

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
	if hit.is_empty():
		print("[Hacking] No target in range")
		return
	var col_v: Variant = hit.get("collider")
	var col: Node = col_v as Node
	var target: Node = _find_hackable(col)
	if target:
		target.on_hacked(caster, damage)
	else:
		print("[Hacking] Hit non-hackable: ", col)
	var hit_pos: Vector3 = hit.get("position", caster.global_position)
	_spawn_beam(caster, hit_pos, Color(1.0, 0.2, 0.55))

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
	var body := Area3D.new()
	body.collision_layer = 8
	body.collision_mask = 5
	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.2
	shape.shape = sphere_shape
	body.add_child(shape)
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	ball.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.5
	ball.material_override = mat
	body.add_child(ball)
	body.set_meta("damage", dmg)
	body.set_meta("direction", dir)
	body.set_meta("speed", 28.0)
	caster.get_tree().current_scene.add_child(body)
	body.global_position = origin
	body.monitoring = true
	body.monitorable = true
	body.body_entered.connect(func(other: Node):
		if other == caster:
			return
		if other.is_in_group("player") and caster.is_in_group("player"):
			return
		if other.has_method("take_damage"):
			var final_dmg: float = dmg
			if GameManager:
				final_dmg *= 1.0 + GameManager.knowledge_insight_bonus()
			other.take_damage(final_dmg)
		if is_instance_valid(body):
			body.queue_free()
	)
	var runner := Node.new()
	runner.set_script(preload("res://scripts/abilities/ProjectileRunner.gd"))
	body.add_child(runner)

func _spawn_beam(caster: Node, to: Vector3, color: Color) -> void:
	if caster == null or not caster.is_inside_tree():
		return
	var im := MeshInstance3D.new()
	var imm := ImmediateMesh.new()
	im.mesh = imm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	im.material_override = mat
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
	var sphere := SphereMesh.new()
	sphere.radius = 1.4
	sphere.height = 2.8
	shell.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color.r, color.g, color.b, 0.25)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell.material_override = mat
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
