extends RefCounted
class_name CombatHits
## Headless-safe shot resolution. Sphere-cast along a ray onto hurtboxes.
## GUI still uses flying bolts; this is the logic path when the dummy renderer
## cannot spawn meshes, and a shared helper for tests.


static func apply_shot(tree: SceneTree, origin: Vector3, dir: Vector3, dmg: float, faction: String, max_range: float = 42.0, exclude: Array = []) -> Node:
	if tree == null or dmg <= 0.0 or max_range <= 0.05:
		return null
	var n := dir.normalized()
	if n.length_squared() < 0.0001:
		return null
	var best: Node = null
	var best_t := max_range
	var player: Node = SoftScanCache.get_player() if SoftScanCache else tree.get_first_node_in_group("player")
	var hit_p: Array = _consider(origin, n, max_range, faction, player, exclude, best, best_t)
	best = hit_p[0]
	best_t = hit_p[1]
	var enemies: Array = SoftScanCache.get_enemies() if SoftScanCache else tree.get_nodes_in_group("enemy")
	for e in enemies:
		var hit_e: Array = _consider(origin, n, max_range, faction, e, exclude, best, best_t)
		best = hit_e[0]
		best_t = hit_e[1]
	var ships: Array = []
	if SoftScanCache and SoftScanCache.has_method("get_ships"):
		ships = SoftScanCache.get_ships()
	else:
		ships = tree.get_nodes_in_group("ship")
	for s in ships:
		var hit_s: Array = _consider(origin, n, max_range, faction, s, exclude, best, best_t)
		best = hit_s[0]
		best_t = hit_s[1]
	if best == null or not is_instance_valid(best):
		return null
	if best.has_method("take_damage"):
		best.take_damage(dmg)
	apply_planar_knock(best, n, dmg)
	if CombatJuice and best is Node3D:
		CombatJuice.hit_feedback(dmg, (best as Node3D).global_position, dmg >= 20.0)
	return best


static func _consider(origin: Vector3, dir: Vector3, max_range: float, faction: String, target: Node, exclude: Array, best: Node, best_t: float) -> Array:
	if target == null or target == best:
		return [best, best_t]
	if exclude.has(target):
		return [best, best_t]
	var t: float = _ray_hit_t(origin, dir, max_range, faction, target)
	if t < best_t:
		return [target, t]
	return [best, best_t]


static func apply_planar_knock(body: Node, dir: Vector3, dmg: float, extra_y: float = 1.2) -> void:
	if body == null or not (body is CharacterBody3D):
		return
	if "is_landed" in body and bool(body.is_landed):
		return
	var n := Vector3(dir.x, 0.0, dir.z)
	if n.length_squared() < 0.0001:
		return
	n = n.normalized()
	var mag := clampf(dmg * 0.35, 2.5, 9.0)
	(body as CharacterBody3D).velocity += n * mag + Vector3(0, extra_y, 0)


static func _ray_hit_t(origin: Vector3, dir: Vector3, max_range: float, faction: String, target: Node) -> float:
	if target == null or not is_instance_valid(target) or not (target is Node3D):
		return max_range + 1.0
	if "_alive" in target and not bool(target._alive):
		return max_range + 1.0
	if target.has_method("is_alive") and not bool(target.is_alive()):
		return max_range + 1.0
	if "faction" in target and str(target.faction) == faction:
		return max_range + 1.0
	if target.has_method("get_faction") and str(target.get_faction()) == faction:
		return max_range + 1.0
	if not target.has_method("take_damage"):
		return max_range + 1.0
	var c: Vector3 = (target as Node3D).global_position
	var r := 1.05
	if target.has_method("hurtbox_center"):
		c = target.hurtbox_center()
	if target.has_method("hurtbox_radius"):
		r = maxf(r, float(target.hurtbox_radius()))
	var to: Vector3 = c - origin
	var t: float = to.dot(dir)
	if t < 0.0 or t > max_range:
		return max_range + 1.0
	var closest: Vector3 = origin + dir * t
	if closest.distance_squared_to(c) > r * r:
		return max_range + 1.0
	return t


static func aim_from(caster: Node) -> Array:
	## [origin: Vector3, dir: Vector3] — TPS CamPivot or ship CameraPivot.
	var origin := Vector3.ZERO
	var dir := Vector3(0, 0, -1)
	if caster == null or not (caster is Node3D):
		return [origin, dir]
	var body := caster as Node3D
	origin = body.global_position + body.global_transform.basis.y * 1.35
	dir = -body.global_transform.basis.z
	for path in ["CamPivot/Camera3D", "CameraPivot/Camera3D"]:
		if body.has_node(path):
			var cam: Camera3D = body.get_node(path) as Camera3D
			if cam:
				dir = -cam.global_transform.basis.z
				origin = cam.global_position + dir * 0.8
				break
	if dir.length_squared() < 0.0001:
		dir = Vector3(0, 0, -1)
	else:
		dir = dir.normalized()
	return [origin, dir]
