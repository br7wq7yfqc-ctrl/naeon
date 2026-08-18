extends CharacterBody3D
class_name CombatDummy
const _AP = preload("res://scripts/assets/AssetPaths.gd")
const _ProcSil = preload("res://scripts/player/ProceduralHeroSilhouette.gd")
const _Hits = preload("res://scripts/combat/CombatHits.gd")
const _Pool = preload("res://scripts/combat/ProjectilePool.gd")

## Trainable combat target for TestArena. Takes damage, optional aggro fire.

signal died
signal damaged(amount: float, health_left: float)

@export var max_health: float = 80.0
@export var move_speed: float = 2.2
@export var aggro_range: float = 16.0
@export var attack_range: float = 12.0
@export var attack_damage: float = 6.0
@export var attack_cooldown: float = 1.4
@export var faction: String = "gROT"
@export var respawn_time: float = 4.0
@export var can_move: bool = true
@export var lane_march: bool = false
@export var one_shot: bool = false
@export var grant_economy: bool = true
@export var intel_name: String = ""
var lane_waypoints: Array = []
var _wp_i: int = 0
var _hostile_cache: Node3D = null

@onready var mesh: MeshInstance3D = $Mesh
@onready var label: Label3D = $Label
@onready var health_bar: Label3D = $HealthBar

var health: float = 80.0
var _cd: float = 0.0
var _alive: bool = true
var _player_cache: Node3D = null
var _ai_accum: float = 0.0
var _spawn_pos: Vector3
var _mat: StandardMaterial3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _stagger: float = 0.0
var _windup_t: float = 0.0
var _gq: Node = null

func _ready() -> void:
	_gq = get_node_or_null("/root/GraphicsQuality")
	health = max_health
	_spawn_pos = global_position
	collision_layer = 4  # Enemy
	collision_mask = 3   # World + Player
	add_to_group("enemy")
	add_to_group("hackable")
	if lane_march:
		add_to_group("clash_minion")
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.35, 0.08, 0.14)
	_mat.metallic = 0.45
	_mat.roughness = 0.4
	_mat.emission_enabled = true
	_mat.emission = Color(0.9, 0.1, 0.35)
	_mat.emission_energy_multiplier = 1.2
	if mesh:
		if DisplayServer.get_name() == "headless":
			var box := BoxMesh.new()
			box.size = Vector3(0.9, 1.7, 0.9)
			mesh.mesh = box
		else:
			var cap := CapsuleMesh.new()
			cap.radius = 0.45
			cap.height = 1.7
			mesh.mesh = cap
		mesh.material_override = _mat
	_update_labels()
	call_deferred("try_load_drone")

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_stagger = maxf(0.0, _stagger - delta)
	_cd = max(0.0, _cd - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	# Knock must survive this frame — do not overwrite xz while staggered.
	if _stagger > 0.0:
		move_and_slide()
		return

	_ai_accum += delta
	var ai_need := 0.1
	if not can_move:
		ai_need = 0.28  # static lane holds — rare retarget
	if _gq and int(_gq.tier) == 0:
		ai_need *= 1.6
	var do_ai := _ai_accum >= ai_need
	if do_ai:
		_ai_accum = 0.0
	if lane_march:
		_lane_ai(delta, do_ai)
		move_and_slide()
		return
	var player := _find_player() if do_ai or _player_cache == null else _player_cache
	# Far culling: no move/look when far from player (still take damage)
	if player and global_position.distance_squared_to(player.global_position) > 55.0 * 55.0:
		velocity.x = 0.0
		velocity.z = 0.0
		_windup_t = 0.0
		move_and_slide()
		return
	var dist := 999.0
	var to_p := Vector3.ZERO
	if player:
		to_p = player.global_position - global_position
		to_p.y = 0.0
		dist = to_p.length()
	if player and can_move:
		if dist < aggro_range and dist > 1.6:
			var dir: Vector3 = to_p.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			look_at(global_position + dir, Vector3.UP)
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed)
			velocity.z = move_toward(velocity.z, 0.0, move_speed)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if player and dist < aggro_range and to_p.length_squared() > 0.0001:
			look_at(global_position + to_p.normalized(), Vector3.UP)
	# Lane holds (can_move=false) still contest the strip — they fire, they don't chase.
	var downed := _target_downed(player)
	if _windup_t > 0.0:
		_windup_t -= delta
		if _windup_t <= 0.0 and player and dist <= attack_range * 1.15 and not downed:
			_fire_at(player)
			_cd = attack_cooldown
	elif player and dist <= attack_range and _cd <= 0.0 and not downed:
		_windup_t = 0.22
		_begin_windup_fx()
	move_and_slide()


func apply_arena_hop(impulse: Vector3) -> void:
	if not _alive:
		return
	velocity = impulse
	_stagger = maxf(_stagger, 0.85)


func set_lane_path(path: Array) -> void:
	lane_waypoints = path.duplicate()
	_wp_i = 0
	lane_march = true
	can_move = true


func _lane_ai(_delta: float, do_ai: bool) -> void:
	if do_ai or _hostile_cache == null or not is_instance_valid(_hostile_cache):
		_hostile_cache = _find_lane_hostile()
	var hostile: Node3D = _hostile_cache
	var dist := 999.0
	var to_h := Vector3.ZERO
	if hostile:
		var aim: Vector3 = hostile.global_position
		if hostile.has_method("hurtbox_center"):
			aim = hostile.hurtbox_center()
		to_h = aim - global_position
		to_h.y = 0.0
		dist = to_h.length()
	var downed := _target_downed(hostile)
	if hostile and dist <= attack_range and not downed:
		velocity.x = 0.0
		velocity.z = 0.0
		if to_h.length_squared() > 0.0001:
			look_at(global_position + to_h.normalized(), Vector3.UP)
		if _windup_t > 0.0:
			_windup_t -= _delta
			if _windup_t <= 0.0 and dist <= attack_range * 1.15:
				_fire_at(hostile)
				_cd = attack_cooldown
		elif _cd <= 0.0:
			_windup_t = 0.22
			_begin_windup_fx()
		return
	_windup_t = 0.0
	_march_waypoints()


func _march_waypoints() -> void:
	if _wp_i >= lane_waypoints.size():
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var dest: Vector3 = lane_waypoints[_wp_i]
	var to: Vector3 = dest - global_position
	to.y = 0.0
	if to.length() < 1.15:
		_wp_i += 1
		if _wp_i >= lane_waypoints.size():
			velocity.x = 0.0
			velocity.z = 0.0
			return
		dest = lane_waypoints[_wp_i]
		to = dest - global_position
		to.y = 0.0
	if to.length_squared() < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var dir := to.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	look_at(global_position + dir, Vector3.UP)


func _find_lane_hostile() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var best: Node3D = null
	var best_d := aggro_range
	var candidates: Array = []
	for n in tree.get_nodes_in_group("clash_minion"):
		candidates.append(n)
	for n in tree.get_nodes_in_group("clash_structure"):
		if n is Node3D:
			var gun: Node = n.get_node_or_null("Gun")
			if gun:
				candidates.append(gun)
	var p: Node = SoftScanCache.get_player() if SoftScanCache else tree.get_first_node_in_group("player")
	if p:
		candidates.append(p)
	for n in candidates:
		if n == self or n == null or not is_instance_valid(n) or not (n is Node3D):
			continue
		if _same_faction(n):
			continue
		if n.has_method("is_alive") and not bool(n.is_alive()):
			continue
		if n.get("_alive") == false:
			continue
		if _target_downed(n):
			continue
		var d: float = global_position.distance_to((n as Node3D).global_position)
		if d < best_d:
			best = n as Node3D
			best_d = d
	return best

func _target_downed(player: Node) -> bool:
	if player == null or not is_instance_valid(player):
		return true
	if player.has_method("is_downed"):
		return bool(player.is_downed())
	if "_down_t" in player:
		return float(player._down_t) > 0.0
	if "health" in player and float(player.health) <= 0.0:
		return true
	return false


func _begin_windup_fx() -> void:
	if _mat == null:
		return
	_mat.emission_energy_multiplier = 2.4
	var tree := get_tree()
	if tree:
		tree.create_timer(0.22).timeout.connect(func():
			if is_instance_valid(self) and _mat:
				_mat.emission_energy_multiplier = 1.2
		)


func take_damage(amount: float, _source_faction: String = "") -> void:
	if CombatJuice:
		var crit := amount >= max_health * 0.35 or amount >= 25.0
		CombatJuice.hit_feedback(float(amount), global_position + Vector3(0, 1.2, 0), crit)
	if not _alive:
		return
	health = max(0.0, health - amount)
	damaged.emit(amount, health)
	_stagger = maxf(_stagger, 0.18 + minf(amount * 0.012, 0.35))
	_flash()
	_hit_pop(amount)
	_update_labels()
	if health <= 0.0:
		_die()

func on_hacked(caster: Node, amount: float = 1.0) -> void:
	if _same_faction(caster):
		return
	take_damage(amount * 1.5)
	# Partial claim visual toward caster faction
	if _mat and caster and caster.has_method("get_faction"):
		var f: String = caster.get_faction()
		if f == "Cybernex":
			_mat.emission = _mat.emission.lerp(Color(0.15, 0.85, 1.0), 0.35)
		else:
			_mat.emission = _mat.emission.lerp(Color(0.95, 0.12, 0.42), 0.35)

func get_faction() -> String:
	return faction


func hurtbox_center() -> Vector3:
	return global_position + Vector3(0, 0.85, 0)


func hurtbox_radius() -> float:
	return 0.95

func _die() -> void:
	if CombatJuice:
		CombatJuice.hit_feedback(max_health, global_position + Vector3(0, 1.2, 0), true)
	_alive = false
	died.emit()
	# A corpse in the enemy group blocks lane refill and soaks target scans.
	if is_in_group("enemy"):
		remove_from_group("enemy")
	if SoftScanCache:
		SoftScanCache.invalidate_enemies()
	if CombatJuice:
		CombatJuice.kill_pop(global_position)
	collision_layer = 0
	velocity = Vector3.ZERO
	if grant_economy and GameManager:
		GameManager.add_contribution(2.5)
		GameManager.add_mastery("combat", 1.5)
	print("[CombatDummy] Downed")
	var vis := _visual_root()
	if vis and DisplayServer.get_name() != "headless" and get_tree():
		var tw := get_tree().create_tween()
		tw.tween_property(vis, "scale", Vector3(1.35, 0.08, 1.35), 0.28)
		tw.tween_callback(_hide_corpse)
	else:
		visible = false
	if one_shot:
		if get_tree():
			get_tree().create_timer(0.35).timeout.connect(queue_free)
		else:
			queue_free()
		return
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)


func _hide_corpse() -> void:
	visible = false
	var vis := _visual_root()
	if vis:
		vis.scale = Vector3.ONE

func _respawn() -> void:
	var vis := _visual_root()
	if vis:
		vis.scale = Vector3.ONE
	health = max_health
	_alive = true
	visible = true
	collision_layer = 4
	if not is_in_group("enemy"):
		add_to_group("enemy")
	global_position = _spawn_pos
	velocity = Vector3.ZERO
	if _mat:
		_mat.emission = Color(0.9, 0.1, 0.35)
	_update_labels()
	if SoftScanCache:
		SoftScanCache.invalidate_enemies()
	print("[CombatDummy] Respawned")

func _fire_at(player: Node) -> void:
	if _same_faction(player):
		return
	if player.has_method("take_damage"):
		player.take_damage(attack_damage, str(faction))
	if player is CharacterBody3D:
		var away: Vector3 = (player as Node3D).global_position - global_position
		_Hits.apply_planar_knock(player, away, attack_damage, 1.0)
	var target_pos: Vector3 = player.global_position + Vector3.UP * 1.2
	var origin: Vector3 = global_position + Vector3.UP * 1.2
	var dir: Vector3 = (target_pos - origin).normalized()
	var col := Color(1.0, 0.2, 0.4) if faction == "gROT" else Color(0.3, 0.95, 1.0)
	_Pool.spawn(get_tree(), origin, dir, 18.0, 0.0, str(faction), col, 0.7, [self])


func _same_faction(other: Node) -> bool:
	if other == null or not is_instance_valid(other):
		return false
	if other.has_method("get_faction"):
		return str(other.get_faction()) == faction
	if "faction" in other:
		return str(other.faction) == faction
	return false


func _find_player() -> Node3D:
	if _player_cache != null and is_instance_valid(_player_cache):
		return _player_cache
	var tree := get_tree()
	if tree == null:
		return null
	# Prefer group once
	if SoftScanCache:
		var sp = SoftScanCache.get_player()
		if sp is Node3D and not _same_faction(sp):
			_player_cache = sp as Node3D
			return _player_cache
	var nodes := tree.get_nodes_in_group("player")
	if nodes.size() > 0 and nodes[0] is Node3D and not _same_faction(nodes[0]):
		_player_cache = nodes[0]
		return _player_cache
	for n in tree.get_nodes_in_group("players"):
		if n is Node3D:
			_player_cache = n
			return _player_cache
	# Fallback once expensive scan
	var scene := tree.current_scene
	if scene:
		for c in scene.get_children():
			if c is CharacterBody3D and c != self and c.has_method("take_damage"):
				_player_cache = c
				return _player_cache
	return null


func _flash() -> void:
	if _mat == null:
		return
	var orig: Color = _mat.albedo_color
	_mat.albedo_color = Color(1, 1, 1)
	get_tree().create_timer(0.07).timeout.connect(func():
		if is_instance_valid(self) and _mat:
			_mat.albedo_color = orig
	)

func _update_labels() -> void:
	if label:
		if intel_name != "":
			label.text = intel_name
		else:
			label.text = ("%s WAVE" % faction) if lane_march else str(faction)
		label.modulate = Color(0.95, 0.25, 0.5) if faction == "gROT" else Color(0.3, 0.9, 1.0)
	if health_bar:
		health_bar.text = "%d" % int(health)

func try_load_drone() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var path: String = _AP.resolve("characters/grot_infector/grot_infector_grot_lod0.glb")
	if not FileAccess.file_exists(path):
		path = _AP.resolve("characters/grot_thrall/grot_thrall_grot_lod0.glb")
	if path != "" and FileAccess.file_exists(path):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(path, state) == OK:
			var root := doc.generate_scene(state)
			if root != null:
				if mesh:
					mesh.visible = false
				add_child(root)
				root.name = "DroneGLB"
				root.scale = Vector3.ONE * 0.9
				print("[CombatDummy] drone mesh loaded")
				return
	_ProcSil.attach(self, "Infector" if faction == "gROT" else "Canine", faction, true)
	if mesh:
		mesh.visible = false
	print("[CombatDummy] procedural silhouette ", faction)


func _visual_root() -> Node3D:
	var g := get_node_or_null("FormGLB") as Node3D
	if g:
		return g
	var d := get_node_or_null("DroneGLB") as Node3D
	if d:
		return d
	return mesh



func _hit_pop(amount: float) -> void:
	var vis := _visual_root()
	if vis == null or not is_instance_valid(vis):
		return
	var base := vis.scale
	var tw := get_tree().create_tween()
	tw.tween_property(vis, "scale", base * 1.12, 0.05)
	tw.tween_property(vis, "scale", base, 0.12)
	if _mat:
		_mat.emission_energy_multiplier = 2.8 if amount >= 20.0 else 1.8
		get_tree().create_timer(0.1).timeout.connect(func():
			if is_instance_valid(self) and _mat:
				_mat.emission_energy_multiplier = 1.2
		)
