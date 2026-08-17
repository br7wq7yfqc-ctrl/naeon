extends Node3D
class_name FormSwitchFX
## Brief dual-theme ring burst on form cycle — readable, no combat power.

static func play_at(parent: Node3D, faction: String, form: String) -> void:
	if parent == null:
		return
	if DisplayServer.get_name() == "headless":
		return
	var fx := Node3D.new()
	fx.name = "FormSwitchFX"
	parent.add_child(fx)
	fx.position = Vector3(0, 0.05, 0)
	var col := Color(0.25, 0.9, 1.0) if faction != "gROT" else Color(0.95, 0.2, 0.45)
	# torus-ish via scaled torus mesh if available, else flat cylinder
	var mi := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.55
	mesh.outer_radius = 0.72
	mesh.rings = 12
	mesh.ring_segments = 24
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(col.r, col.g, col.b, 0.85)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	fx.add_child(mi)
	# rising particles (GPUParticles3D if available)
	var gp := GPUParticles3D.new()
	gp.amount = 18
	gp.lifetime = 0.45
	gp.one_shot = true
	gp.explosiveness = 0.95
	gp.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 80.0
	pm.initial_velocity_min = 1.5
	pm.initial_velocity_max = 3.5
	pm.gravity = Vector3(0, -2.0, 0)
	pm.color = col
	gp.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.04
	sm.height = 0.08
	gp.draw_pass_1 = sm
	fx.add_child(gp)
	# animate scale + fade
	var tw := parent.get_tree().create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(2.2, 0.4, 2.2), 0.4)
	tw.tween_property(mat, "emission_energy_multiplier", 0.1, 0.4)
	tw.chain().tween_callback(func():
		if is_instance_valid(fx):
			fx.queue_free()
	)
	print("[FormSwitchFX] ", form, " / ", faction)
