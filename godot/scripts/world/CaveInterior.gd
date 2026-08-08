extends Node3D
class_name CaveInterior
## Procedural cave pockets + enter/exit for walker (F near mouth). No combat.

const _Math = preload("res://scripts/world/SurfaceChunkMath.gd")
const _Relief = preload("res://scripts/world/PlanetRelief.gd")

const STREAM_HZ := 0.5
const MAX_CAVES := 3
const ENTER_DIST := 6.5
const EXIT_DIST := 16.0

var _planet: Node3D
var _radius: float = 1200.0
var _observer: Node3D
var _seed: int = 1
var _planet_id: String = "Nex-Prime"
var _profile: Dictionary = {}
var _accum: float = 0.0
var _caves: Array = []
var _active_cave: Node3D = null
var _inside: bool = false
var _enter_cd: float = 0.0
var _entry_world: Vector3 = Vector3.ZERO
var _prompt_cd: float = 0.0


func setup(planet: Node3D, radius: float, planet_id: String, seed_i: int = 7) -> void:
	_planet = planet
	_radius = radius
	_planet_id = planet_id
	_seed = seed_i
	_profile = _Relief.profile_for_planet(planet_id)
	if _caves.is_empty():
		_build_pool()


func set_observer(n: Node3D) -> void:
	_observer = n


func _ready() -> void:
	set_process(true)
	if _caves.is_empty() and _planet != null:
		_build_pool()


func _build_pool() -> void:
	var gq := get_node_or_null("/root/GraphicsQuality")
	var n: int = MAX_CAVES
	if gq != null and int(gq.tier) == 0:
		n = 2
	for i in n:
		var root := Node3D.new()
		root.name = "Cave_%d" % i
		var tunnel := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 2.2
		cm.bottom_radius = 2.4
		cm.height = 14.0
		cm.radial_segments = 10
		tunnel.mesh = cm
		tunnel.rotation_degrees = Vector3(0, 0, 90)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.08, 0.07, 0.06)
		mat.roughness = 1.0
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = Color(0.04, 0.05, 0.06)
		mat.emission_energy_multiplier = 0.35
		tunnel.material_override = mat
		tunnel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(tunnel)
		var floor_mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(4.0, 0.25, 12.0)
		floor_mi.mesh = box
		floor_mi.position = Vector3(0, -1.8, 0)
		var fm := StandardMaterial3D.new()
		fm.albedo_color = Color(0.12, 0.1, 0.09)
		fm.roughness = 0.95
		floor_mi.material_override = fm
		floor_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(floor_mi)
		var crystal := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.35
		sm.height = 0.7
		crystal.mesh = sm
		crystal.position = Vector3(0.8, -1.0, 3.0)
		var cm2 := StandardMaterial3D.new()
		cm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cm2.albedo_color = Color(0.25, 0.7, 0.95)
		cm2.emission_enabled = true
		cm2.emission = Color(0.2, 0.6, 0.9)
		cm2.emission_energy_multiplier = 2.0
		crystal.material_override = cm2
		crystal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(crystal)
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(4.0, 0.3, 12.0)
		col.shape = shape
		col.position = Vector3(0, -1.8, 0)
		body.add_child(col)
		root.add_child(body)
		# Enter trigger volume (Area3D)
		var area := Area3D.new()
		area.name = "EnterZone"
		area.collision_layer = 0
		area.collision_mask = 2  # player if on layer 2; also check distance
		area.monitoring = true
		var ashape := CollisionShape3D.new()
		var sph := SphereShape3D.new()
		sph.radius = ENTER_DIST
		ashape.shape = sph
		ashape.position = Vector3(0, 0, -5.0)
		area.add_child(ashape)
		root.add_child(area)
		var lab := Label3D.new()
		lab.name = "Prompt"
		lab.text = "[F] Enter cave"
		lab.font_size = 22
		lab.position = Vector3(0, 1.2, -5.0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.modulate = Color(0.7, 0.9, 1.0, 0.85)
		lab.visible = false
		root.add_child(lab)
		root.visible = false
		add_child(root)
		_caves.append(root)
	print("[CaveInterior] pool=", n, " planet=", _planet_id)


func _process(delta: float) -> void:
	_enter_cd = maxf(0.0, _enter_cd - delta)
	_prompt_cd = maxf(0.0, _prompt_cd - delta)
	_accum += delta
	if _accum >= STREAM_HZ:
		_accum = 0.0
		_stream_caves()
	_tick_enter_exit()


func _stream_caves() -> void:
	if _planet == null or _observer == null or not is_instance_valid(_observer):
		return
	if not bool(_profile.get("caves", true)):
		return
	if _inside:
		return  # keep active cave placed
	var dist: float = _observer.global_position.distance_to(_planet.global_position)
	var alt: float = dist - _radius
	if alt > 70.0 or alt < -25.0:
		for c in _caves:
			if c:
				c.visible = false
		return
	var cell: Vector2i = _Math.cell_of(_planet.global_position, _radius, _observer.global_position, 56.0)
	var ring: Array = _Math.ring_cells(cell, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 41 + cell.x * 13 + cell.y
	var placed := 0
	for c in ring:
		if placed >= _caves.size():
			break
		var wx: float = float(c.x) * 56.0 + rng.randf_range(-6.0, 6.0)
		var wz: float = float(c.y) * 56.0 + rng.randf_range(-6.0, 6.0)
		if not bool(_Relief.is_canyon(wx, wz, _seed)):
			continue
		var open: float = float(_Relief.cave_openness(wx, wz, -1.2, _seed, _profile))
		if open < 0.4:
			continue
		var h: float = float(_Relief.height_at(wx, wz, _seed, _profile))
		var xform: Transform3D = _Math.cell_transform(_planet.global_position, _radius, c, 56.0, h - 2.5)
		var cave: Node3D = _caves[placed]
		cave.global_transform = xform
		cave.scale = Vector3.ONE * (0.85 + open * 0.5)
		cave.visible = true
		var crystal = cave.get_node_or_null("MeshInstance3D")  # fragile; use child index
		if cave.get_child_count() > 2 and cave.get_child(2) is MeshInstance3D:
			var mat := (cave.get_child(2) as MeshInstance3D).material_override as StandardMaterial3D
			if mat:
				if _planet_id == "ROT-Hive":
					mat.albedo_color = Color(0.95, 0.2, 0.4)
					mat.emission = Color(0.9, 0.15, 0.35)
				else:
					mat.albedo_color = Color(0.25, 0.7, 0.95)
					mat.emission = Color(0.2, 0.6, 0.9)
		placed += 1
	for i in range(placed, _caves.size()):
		_caves[i].visible = false


func _tick_enter_exit() -> void:
	if _observer == null or not is_instance_valid(_observer):
		return
	if _inside and _active_cave != null and is_instance_valid(_active_cave):
		# Exit: F or leave far from cave
		var d: float = _observer.global_position.distance_to(_active_cave.global_position)
		_show_prompt(_active_cave, true, "[F] Exit cave")
		if _enter_cd <= 0.0 and (Input.is_physical_key_pressed(KEY_F) or d > EXIT_DIST):
			_do_exit()
		return
	# Find nearest visible cave mouth
	var best: Node3D = null
	var best_d := ENTER_DIST
	for c in _caves:
		if c == null or not is_instance_valid(c) or not c.visible:
			continue
		# Mouth point: local -Z side
		var mouth: Vector3 = c.to_global(Vector3(0, 0, -5.0))
		var d2: float = _observer.global_position.distance_to(mouth)
		if d2 < best_d:
			best_d = d2
			best = c
	for c in _caves:
		_show_prompt(c, c == best, "[F] Enter cave")
	if best != null and _enter_cd <= 0.0 and Input.is_physical_key_pressed(KEY_F):
		_do_enter(best)


func _show_prompt(cave: Node3D, on: bool, text: String) -> void:
	if cave == null:
		return
	var lab = cave.get_node_or_null("Prompt")
	if lab is Label3D:
		(lab as Label3D).visible = on
		if on:
			(lab as Label3D).text = text


func _do_enter(cave: Node3D) -> void:
	_inside = true
	_active_cave = cave
	_enter_cd = 0.6
	_entry_world = _observer.global_position
	# Place player on cave floor center
	var target: Vector3 = cave.to_global(Vector3(0, -0.8, 2.0))
	if _observer is CharacterBody3D:
		(_observer as CharacterBody3D).velocity = Vector3.ZERO
	_observer.global_position = target
	_notify("Entered cave — [F] to exit")
	if AudioDirector and AudioDirector.has_method("play_ui"):
		AudioDirector.play_ui()
	print("[CaveInterior] enter ", cave.name)


func _do_exit() -> void:
	_enter_cd = 0.6
	if _observer and is_instance_valid(_observer):
		var back := _entry_world
		if _active_cave and is_instance_valid(_active_cave):
			back = _active_cave.to_global(Vector3(0, 1.5, -7.0))
		if _observer is CharacterBody3D:
			(_observer as CharacterBody3D).velocity = Vector3.ZERO
		_observer.global_position = back
	_inside = false
	_active_cave = null
	_notify("Exited cave")
	if AudioDirector and AudioDirector.has_method("play_ui"):
		AudioDirector.play_ui()
	print("[CaveInterior] exit")


func _notify(msg: String) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("game_hud"):
		if n.has_method("push_toast"):
			n.push_toast(msg, 2.5)
			return
