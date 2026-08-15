extends RefCounted
class_name ShipFlightModel
## Semi-Newtonian continuum flight helpers.
## Vacuum: low linear damp, full thrust.
## Atmosphere: density scales drag + gravity feel; HOVER holds altitude.

enum Mode { SCM, NAV, HOVER }


static func atmosphere_density(alt: float, atmo_height: float) -> float:
	## 0 vacuum … 1 dense near surface. Smooth falloff.
	if atmo_height <= 1.0:
		return 0.0
	if alt >= atmo_height * 1.6:
		return 0.0
	if alt <= 0.0:
		return 1.0
	var t := 1.0 - alt / (atmo_height * 1.6)
	return clampf(t * t, 0.0, 1.0)


static func max_speed(mode: int, scm: float, nav: float, hover: float) -> float:
	match mode:
		Mode.NAV:
			return nav
		Mode.HOVER:
			return hover
		_:
			return scm


static func thrust_mult(mode: int) -> float:
	match mode:
		Mode.NAV:
			return 1.55
		Mode.HOVER:
			return 0.5
		_:
			return 1.0


static func base_damp(mode: int) -> float:
	## Multiplier on linear_damp_custom (vacuum baseline).
	match mode:
		Mode.NAV:
			return 0.35
		Mode.HOVER:
			return 2.2
		_:
			return 1.0


static func integrate(
	velocity: Vector3,
	accel: Vector3,
	delta: float,
	linear_damp: float,
	damp_mult: float,
	atmo: float,
	max_spd: float
) -> Vector3:
	## Vacuum: light linear damp. Atmosphere: + quadratic drag ~ v² * atmo.
	var v := velocity + accel * delta
	var damp := linear_damp * damp_mult * (1.0 + atmo * 1.4)
	v = v.lerp(Vector3.ZERO, clampf(damp * delta, 0.0, 0.95))
	if atmo > 0.02:
		var spd := v.length()
		if spd > 0.01:
			var qdrag := atmo * 0.012 * spd * spd
			v -= v.normalized() * qdrag * delta
	var ms := max_spd * (1.0 - atmo * 0.12)  # slightly lower top speed in atmo
	ms = maxf(ms, max_spd * 0.55)
	if v.length() > ms:
		v = v.normalized() * ms
	return v


static func hover_hold(
	velocity: Vector3,
	g: Vector3,
	accel: Vector3,
	delta: float,
	hold_strength: float = 1.0
) -> Array:
	## Cancel gravity + soft damp radial velocity. Returns [accel, velocity].
	if g.length() < 0.01:
		return [accel, velocity]
	var up_dir := (-g).normalized()
	accel = accel - g * hold_strength
	var v_up := velocity.dot(up_dir)
	# Critically damp vertical drift (no bounce)
	velocity = velocity - up_dir * v_up * clampf(6.0 * delta, 0.0, 0.85)
	return [accel, velocity]


static func approach_assist(
	velocity: Vector3,
	to_pad: Vector3,
	dist: float,
	snap_dist: float
) -> Vector3:
	## Soft brake when near pad and closing in (landing assist, not autopilot).
	if dist > snap_dist or dist < 2.0:
		return velocity
	var closing := -velocity.dot(to_pad.normalized()) if to_pad.length_squared() > 0.01 else 0.0
	if closing < 2.0:
		return velocity
	var t := 1.0 - dist / snap_dist
	return velocity.lerp(Vector3.ZERO, t * t * 0.08)


static func land_ok(speed: float, v_radial: float, max_spd: float = 18.0, max_sink: float = 12.0) -> bool:
	return speed <= max_spd and absf(v_radial) <= max_sink


static func hover_alt_accel(g: Vector3, alt: float, hold_alt: float, v_up: float) -> Vector3:
	## PD toward a captured hover altitude. Presentation/feel only.
	if g.length() < 0.01:
		return Vector3.ZERO
	var up_dir := (-g).normalized()
	var err := hold_alt - alt
	var spring := clampf(err * 0.55, -22.0, 22.0)
	var damp := -v_up * 3.4
	return up_dir * (spring + damp)
