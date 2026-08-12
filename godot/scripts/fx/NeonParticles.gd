extends RefCounted
class_name NeonParticles
## Optimized neon particle factory — Cybernex cyan / gROT magenta.
## Shared quad mesh + unshaded additive shader, global spawn budget,
## GraphicsQuality tiers. Presentation only.

const CYAN := Color(0.25, 0.9, 1.0, 0.9)
const MAGENTA := Color(0.95, 0.15, 0.45, 0.9)
const AMBER := Color(1.0, 0.65, 0.2, 0.9)

## Concurrent one-shot systems (RTX 1060 safe).
static var _active_oneshot: int = 0
static var _shared_quad: QuadMesh = null
static var _shader: Shader = null
static var _mat_cache: Dictionary = {}  # Color rgba key -> Material

const MAX_ONESHOT_LOW := 4
const MAX_ONESHOT_MED := 8
const MAX_ONESHOT_HIGH := 12


static func faction_color(faction: String) -> Color:
	if faction == "gROT" or faction == "grot":
		return MAGENTA
	return CYAN


static func _quality_tier() -> int:
	var gq = Engine.get_main_loop()
	if gq is SceneTree:
		var n = (gq as SceneTree).root.get_node_or_null("/root/GraphicsQuality")
		if n and "tier" in n:
			return int(n.tier)
	return 1


static func _max_oneshot() -> int:
	match _quality_tier():
		0:
			return MAX_ONESHOT_LOW
		2, 3:
			return MAX_ONESHOT_HIGH
		_:
			return MAX_ONESHOT_MED


static func _amount_scale() -> float:
	match _quality_tier():
		0:
			return 0.45
		2, 3:
			return 1.0
		_:
			return 0.7


static func _shared_mesh() -> QuadMesh:
	if _shared_quad == null:
		_shared_quad = QuadMesh.new()
		_shared_quad.size = Vector2(0.18, 0.18)
	return _shared_quad


static func _neon_mat(color: Color) -> Material:
	var key := "%d_%d_%d" % [int(color.r * 40.0), int(color.g * 40.0), int(color.b * 40.0)]
	if _mat_cache.has(key):
		return _mat_cache[key]
	if _shader == null:
		_shader = load("res://shaders/neon_particle.gdshader") as Shader
	var mat: Material
	if _shader:
		var smat := ShaderMaterial.new()
		smat.shader = _shader
		smat.set_shader_parameter("albedo", color)
		smat.set_shader_parameter("soft_edge", 0.5)
		smat.set_shader_parameter("core_boost", 1.5)
		mat = smat
	else:
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.albedo_color = color
		sm.emission_enabled = true
		sm.emission = color
		sm.emission_energy_multiplier = 2.0
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat = sm
	# Bound cache (few faction colors in practice)
	if _mat_cache.size() > 16:
		_mat_cache.clear()
	_mat_cache[key] = mat
	return mat


static func _make_particles(amount: int, lifetime: float, one_shot: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var sc := _amount_scale()
	p.amount = maxi(3, int(float(amount) * sc))
	p.lifetime = lifetime
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.15
	p.local_coords = true
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	p.visibility_aabb = AABB(Vector3(-4, -4, -4), Vector3(8, 8, 8))
	p.fixed_fps = 24 if _quality_tier() == 0 else 30
	p.fract_delta = true
	p.draw_pass_1 = _shared_mesh()
	return p


static func _process_mat(dir: Vector3, spread: float, vmin: float, vmax: float, color: Color, grav: Vector3 = Vector3.ZERO) -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.direction = dir
	pm.spread = spread
	pm.initial_velocity_min = vmin
	pm.initial_velocity_max = vmax
	pm.gravity = grav
	pm.color = color
	pm.scale_min = 0.55
	pm.scale_max = 1.35
	# Kill unused channels (cheaper GPU sim)
	pm.angular_velocity_min = 0.0
	pm.angular_velocity_max = 0.0
	pm.orbit_velocity_min = 0.0
	pm.orbit_velocity_max = 0.0
	pm.radial_accel_min = 0.0
	pm.radial_accel_max = 0.0
	pm.tangential_accel_min = 0.0
	pm.tangential_accel_max = 0.0
	pm.damping_min = 0.5
	pm.damping_max = 1.5
	return pm


static func _can_spawn_oneshot() -> bool:
	return _active_oneshot < _max_oneshot()


static func _track(p: GPUParticles3D, tree: SceneTree, life: float) -> void:
	_active_oneshot += 1
	tree.create_timer(life).timeout.connect(func():
		_active_oneshot = maxi(0, _active_oneshot - 1)
		if is_instance_valid(p):
			p.queue_free()
	)


static func burst(at: Vector3, color: Color, tree: SceneTree, amount: int = 12, speed: float = 6.0) -> void:
	if tree == null or tree.current_scene == null:
		return
	if DisplayServer.get_name() == "headless":
		return
	if not _can_spawn_oneshot():
		return
	var p := _make_particles(amount, 0.4, true)
	p.emitting = true
	p.process_material = _process_mat(Vector3(0, 1, 0), 180.0, speed * 0.35, speed, color, Vector3(0, -1.2, 0))
	p.material_override = _neon_mat(color)
	tree.current_scene.add_child(p)
	p.global_position = at
	_track(p, tree, 0.5)


static func trail_attach(parent: Node3D, color: Color, local_pos: Vector3 = Vector3.ZERO) -> GPUParticles3D:
	if parent == null or DisplayServer.get_name() == "headless":
		return null
	var p := _make_particles(10, 0.28, false)
	p.name = "NeonTrail"
	p.emitting = true
	p.position = local_pos
	p.explosiveness = 0.05
	p.process_material = _process_mat(Vector3(0, 0, 1), 14.0, 0.4, 1.8, color)
	p.material_override = _neon_mat(color)
	p.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 6))
	parent.add_child(p)
	return p


static func thruster_plume(parent: Node3D, color: Color, local_pos: Vector3 = Vector3(0, 0, 0.8)) -> GPUParticles3D:
	if parent == null or DisplayServer.get_name() == "headless":
		return null
	var base_amt := 14
	match _quality_tier():
		0:
			base_amt = 8
		2, 3:
			base_amt = 20
	var p := _make_particles(base_amt, 0.24, false)
	p.name = "ThrusterPlume"
	p.emitting = false
	p.position = local_pos
	p.explosiveness = 0.1
	p.process_material = _process_mat(Vector3(0, 0, 1), 10.0, 4.0, 11.0, color)
	p.material_override = _neon_mat(color)
	p.visibility_aabb = AABB(Vector3(-1.5, -1.5, -1), Vector3(3, 3, 8))
	parent.add_child(p)
	return p


static func claim_radial(at: Vector3, color: Color, tree: SceneTree) -> void:
	if tree == null or tree.current_scene == null or DisplayServer.get_name() == "headless":
		return
	if not _can_spawn_oneshot():
		return
	var p := _make_particles(16, 0.55, true)
	p.emitting = true
	p.process_material = _process_mat(Vector3(0, 0.25, 1), 180.0, 2.5, 7.5, color, Vector3(0, 0.4, 0))
	p.material_override = _neon_mat(color)
	tree.current_scene.add_child(p)
	p.global_position = at + Vector3(0, 1.2, 0)
	_track(p, tree, 0.65)
	# Single cheap ring (no particle storm)
	if _quality_tier() == 0:
		return
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.25
	tm.outer_radius = 0.95
	tm.rings = 6
	tm.ring_segments = 10
	mi.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(color.r, color.g, color.b, 0.75)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	tree.current_scene.add_child(mi)
	mi.global_position = at + Vector3(0, 0.4, 0)
	var tw := tree.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * 3.2, 0.45)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.45)
	tw.chain().tween_callback(func():
		if is_instance_valid(mi):
			mi.queue_free()
	)


static func muzzle_flash(at: Vector3, dir: Vector3, color: Color, tree: SceneTree) -> void:
	if tree == null or tree.current_scene == null or DisplayServer.get_name() == "headless":
		return
	if not _can_spawn_oneshot():
		return
	var p := _make_particles(8, 0.15, true)
	p.emitting = true
	var d := dir.normalized() if dir.length_squared() > 0.01 else Vector3(0, 0, -1)
	p.process_material = _process_mat(d, 22.0, 3.5, 11.0, color)
	p.material_override = _neon_mat(color)
	tree.current_scene.add_child(p)
	p.global_position = at
	_track(p, tree, 0.22)
	# Omni only on medium+
	if _quality_tier() == 0:
		return
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.8
	light.omni_range = 3.5
	light.shadow_enabled = false
	tree.current_scene.add_child(light)
	light.global_position = at
	tree.create_timer(0.12).timeout.connect(func():
		if is_instance_valid(light):
			light.queue_free()
	)


static func active_count() -> int:
	return _active_oneshot
