extends RefCounted
class_name AbilityVfx
## Soft cast/impact presentation — no combat power. Shared by Ability + Channel.

static func cast_flash(caster: Node, color: Color, energy: float = 2.5) -> void:
	if caster == null or not caster is Node3D or not caster.is_inside_tree():
		return
	var tree := caster.get_tree()
	if tree == null or tree.current_scene == null:
		return
	var origin: Vector3 = (caster as Node3D).global_position + Vector3.UP * 1.2
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 6.0
	light.shadow_enabled = false
	tree.current_scene.add_child(light)
	light.global_position = origin
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.05
	tm.outer_radius = 0.55
	tm.rings = 6
	tm.ring_segments = 10
	ring.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(color.r, color.g, color.b, 0.85)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tree.current_scene.add_child(ring)
	ring.global_position = origin
	var tw := tree.create_tween()
	tw.set_parallel(true)
	tw.tween_property(light, "light_energy", 0.0, 0.28)
	tw.tween_property(ring, "scale", Vector3.ONE * 1.8, 0.32)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.32)
	tw.chain().tween_callback(func():
		if is_instance_valid(light):
			light.queue_free()
		if is_instance_valid(ring):
			ring.queue_free()
	)


static func bolt_trail(body: Node3D, color: Color) -> void:
	if body == null:
		return
	var p := GPUParticles3D.new()
	p.amount = 8
	p.lifetime = 0.25
	p.emitting = true
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, 1)
	pm.spread = 15.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 1.0
	pm.gravity = Vector3.ZERO
	pm.color = Color(color.r, color.g, color.b, 0.7)
	pm.scale_min = 0.04
	pm.scale_max = 0.1
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	p.draw_pass_1 = sm
	body.add_child(p)


static func impact_burst(at: Vector3, color: Color, tree: SceneTree, crit: bool = false) -> void:
	if tree == null or tree.current_scene == null:
		return
	var p := GPUParticles3D.new()
	p.amount = 14 if crit else 8
	p.lifetime = 0.4
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 7.0 if crit else 4.0
	pm.gravity = Vector3(0, -4, 0)
	pm.color = color
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.14
	p.draw_pass_1 = sm
	tree.current_scene.add_child(p)
	p.global_position = at
	tree.create_timer(0.5).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free()
	)
