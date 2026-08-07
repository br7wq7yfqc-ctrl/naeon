extends Node3D
## Soft ambient characters near pads — density without combat power.

const PATHS := [
	"characters/grot_thrall/grot_thrall_cybernex_lod2.glb",
	"characters/cybernex_sentry/cybernex_sentry_cybernex_lod2.glb",
	"characters/combat_drone/combat_drone_cybernex_lod2.glb",
]

func build(count: int = 5) -> void:
	var prop_script: Script = load("res://scripts/assets/GlbProp.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 77701
	for i in count:
		var rel: String = PATHS[i % PATHS.size()]
		var p: Node3D = Node3D.new()
		p.set_script(prop_script)
		p.set("relative_path", rel)
		p.set("scale_factor", rng.randf_range(0.85, 1.15))
		p.set("add_static_collision", false)
		add_child(p)
		var ang := TAU * float(i) / float(count)
		p.position = Vector3(cos(ang) * 12.0, 0.2, sin(ang) * 12.0)
		p.rotation.y = ang + PI
	print("[PadAmbientLife] n=", count)
