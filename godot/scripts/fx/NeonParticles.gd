extends RefCounted
class_name NeonParticles
## NAEON neon particle factory — Cybernex cyan / gROT magenta.
## Budget-aware; presentation only.

const CYAN := Color(0.25, 0.9, 1.0, 0.9)
const MAGENTA := Color(0.95, 0.15, 0.45, 0.9)
const AMBER := Color(1.0, 0.65, 0.2, 0.9)


static func faction_color(faction: String) -> Color:
	if faction == "gROT" or faction == "grot":
		return MAGENTA
	return CYAN


static func burst(at: Vector3, color: Color, tree: SceneTree, amount: int = 14, speed: float = 6.0) -> void:
	if tree == null or tree.current_scene == null:
		return
	if DisplayServer.get_name() == "headless":
		return
	var p := GPUParticles3D.new()
	p.amount = clampi(amount, 4, 28)
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = speed * 0.35
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, -1.5, 0)
	pm.color = color
	pm.scale_min = 0.04
	pm.scale_max = 0.12
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	p.draw_pass_1 = sm
	tree.current_scene.add_child(p)
	p.global_position = at
	tree.create_timer(0.55).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free()
	)


static func trail_attach(parent: Node3D, color: Color, local_pos: Vector3 = Vector3.ZERO) -> GPUParticles3D:
	if parent == null or DisplayServer.get_name() == "headless":
		return null
	var p := GPUParticles3D.new()
	p.name = "NeonTrail"
	p.amount = 16
	p.lifetime = 0.35
	p.emitting = true
	p.position = local_pos
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, 1)
	pm.spread = 18.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 2.2
	pm.gravity = Vector3.ZERO
	pm.color = color
	pm.scale_min = 0.03
	pm.scale_max = 0.09
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.04
	sm.height = 0.08
	p.draw_pass_1 = sm
	parent.add_child(p)
	return p


static func thruster_plume(parent: Node3D, color: Color, local_pos: Vector3 = Vector3(0, 0, 0.8)) -> GPUParticles3D:
	if parent == null or DisplayServer.get_name() == "headless":
		return null
	var p := GPUParticles3D.new()
	p.name = "ThrusterPlume"
	p.amount = 20
	p.lifetime = 0.28
	p.emitting = false
	p.position = local_pos
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, 1)
	pm.spread = 12.0
	pm.initial_velocity_min = 4.0
	pm.initial_velocity_max = 12.0
	pm.gravity = Vector3.ZERO
	pm.color = color
	pm.scale_min = 0.05
	pm.scale_max = 0.16
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.14
	p.draw_pass_1 = sm
	parent.add_child(p)
	return p


static func claim_radial(at: Vector3, color: Color, tree: SceneTree) -> void:
	if tree == null or tree.current_scene == null or DisplayServer.get_name() == "headless":
		return
	var p := GPUParticles3D.new()
	p.amount = 24
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 0.9
	p.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0.2, 1)
	pm.spread = 180.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 9.0
	pm.gravity = Vector3(0, 0.5, 0)
	pm.color = color
	pm.scale_min = 0.06
	pm.scale_max = 0.15
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	p.draw_pass_1 = sm
	tree.current_scene.add_child(p)
	p.global_position = at + Vector3(0, 1.2, 0)
	# Ring flash
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.2
	tm.outer_radius = 1.2
	tm.rings = 8
	tm.ring_segments = 16
	mi.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tree.current_scene.add_child(mi)
	mi.global_position = at + Vector3(0, 0.4, 0)
	var tw := tree.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * 4.0, 0.55)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.55)
	tw.chain().tween_callback(func():
		if is_instance_valid(mi):
			mi.queue_free()
		if is_instance_valid(p):
			p.queue_free()
	)


static func muzzle_flash(at: Vector3, dir: Vector3, color: Color, tree: SceneTree) -> void:
	if tree == null or tree.current_scene == null or DisplayServer.get_name() == "headless":
		return
	var p := GPUParticles3D.new()
	p.amount = 10
	p.lifetime = 0.18
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.direction = dir.normalized() if dir.length_squared() > 0.01 else Vector3(0, 0, -1)
	pm.spread = 25.0
	pm.initial_velocity_min = 4.0
	pm.initial_velocity_max = 14.0
	pm.gravity = Vector3.ZERO
	pm.color = color
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	p.draw_pass_1 = sm
	tree.current_scene.add_child(p)
	p.global_position = at
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 4.0
	light.omni_range = 5.0
	light.shadow_enabled = false
	tree.current_scene.add_child(light)
	light.global_position = at
	tree.create_timer(0.2).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free()
		if is_instance_valid(light):
			light.queue_free()
	)
