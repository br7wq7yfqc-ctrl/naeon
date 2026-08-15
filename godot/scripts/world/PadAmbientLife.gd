extends Node3D
## Soft ambient NPCs near pads — density/life, zero combat power.

const CYBER := [
	"characters/cybernex_sentry/cybernex_sentry_cybernex_lod2.glb",
	"characters/combat_drone/combat_drone_cybernex_lod2.glb",
	"characters/player_canine/player_canine_cybernex_lod2.glb",
]
const GROT := [
	"characters/grot_thrall/grot_thrall_grot_lod2.glb",
	"characters/grot_infector/grot_infector_grot_lod2.glb",
	"characters/combat_drone/combat_drone_grot_lod2.glb",
]

var _actors: Array = []
var _bases: Array = []  # local origin per actor
var _phases: Array = []
var _faction: String = "Cybernex"
var _life_accum: float = 0.0


func build(count: int = 5, faction: String = "Cybernex") -> void:
	_faction = faction
	var paths: Array = GROT if faction == "gROT" else CYBER
	var prop_script: Script = load("res://scripts/assets/GlbProp.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 77701 + hash(faction)
	var gq := get_node_or_null("/root/GraphicsQuality")
	var n := count
	if gq:
		match int(gq.tier):
			0:
				n = maxi(3, count - 2)
			2, 3:
				n = count + 3
	for i in n:
		var rel: String = str(paths[i % paths.size()])
		var p: Node3D = Node3D.new()
		p.set_script(prop_script)
		p.set("relative_path", rel)
		p.set("scale_factor", rng.randf_range(0.8, 1.2))
		p.set("add_static_collision", false)
		add_child(p)
		var ang := TAU * float(i) / float(n) + rng.randf() * 0.2
		var rad := 10.0 + rng.randf() * 8.0
		var base := Vector3(cos(ang) * rad, 0.15, sin(ang) * rad)
		p.position = base
		p.rotation.y = ang + PI
		_actors.append(p)
		_bases.append(base)
		_phases.append(rng.randf() * TAU)
	set_process(true)
	print("[PadAmbientLife] n=", n, " faction=", faction)


func _process(delta: float) -> void:
	_life_accum += delta
	if _life_accum < 0.2:
		return
	_life_accum = 0.0
	if _actors.is_empty():
		return
	var t := Time.get_ticks_msec() * 0.001
	for i in _actors.size():
		var a: Node3D = _actors[i]
		if a == null or not is_instance_valid(a):
			continue
		var base: Vector3 = _bases[i]
		var ph: float = float(_phases[i])
		var bob := sin(t * 1.6 + ph) * 0.06
		var wander := Vector3(cos(t * 0.25 + ph), 0.0, sin(t * 0.22 + ph)) * 0.8
		a.position = base + wander + Vector3(0, bob, 0)
		a.rotation.y = ph + t * 0.15
