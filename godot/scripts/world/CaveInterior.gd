extends Node3D
class_name CaveInterior
## Procedural cave pocket near mouths — tunnel mesh + floor, streamed, no combat.

const _Math = preload("res://scripts/world/SurfaceChunkMath.gd")
const _Relief = preload("res://scripts/world/PlanetRelief.gd")

const STREAM_HZ := 0.5
const MAX_CAVES := 3

var _planet: Node3D
var _radius: float = 1200.0
var _observer: Node3D
var _seed: int = 1
var _planet_id: String = "Nex-Prime"
var _profile: Dictionary = {}
var _accum: float = 0.0
var _caves: Array = []


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
		# Tunnel body (horizontal capsule-ish via scaled cylinder)
		var tunnel := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 2.2
		cm.bottom_radius = 2.4
		cm.height = 14.0
		cm.radial_segments = 10
		cm.rings = 1
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
		# Floor slab
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
		# Soft blue crystal accents (grot/nex tint later)
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
		# Collision floor for walker
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
		var lab := Label3D.new()
		lab.text = "CAVE INTERIOR"
		lab.font_size = 18
		lab.position = Vector3(0, 0.5, -5.0)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.modulate = Color(0.5, 0.7, 0.9, 0.6)
		root.add_child(lab)
		root.visible = false
		add_child(root)
		_caves.append(root)
	print("[CaveInterior] pool=", n, " planet=", _planet_id)


func _process(delta: float) -> void:
	_accum += delta
	if _accum < STREAM_HZ:
		return
	_accum = 0.0
	if _planet == null or _observer == null or not is_instance_valid(_observer):
		return
	if not bool(_profile.get("caves", true)):
		return
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
		# Place tunnel slightly below surface along radial, oriented into planet
		var xform: Transform3D = _Math.cell_transform(_planet.global_position, _radius, c, 56.0, h - 2.5)
		var cave: Node3D = _caves[placed]
		cave.global_transform = xform
		# Point tunnel inward along -up of cell (into planet)
		cave.scale = Vector3.ONE * (0.85 + open * 0.5)
		cave.visible = true
		# Faction crystal tint
		var crystal = cave.get_child(2) if cave.get_child_count() > 2 else null
		if crystal is MeshInstance3D:
			var mat := (crystal as MeshInstance3D).material_override as StandardMaterial3D
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
