extends RefCounted
class_name ShipFlightModel
## Semi-Newtonian continuum flight helpers.
## Vacuum: low linear damp, full thrust.
## Atmosphere: density scales drag + gravity feel + OS-F lift/glide; HOVER holds altitude.

enum Mode { SCM, NAV, HOVER }


static func atmosphere_density(alt: float, atmo_height: float, envelope: float = -1.0) -> float:
	## 0 vacuum … 1 dense near surface. Envelope is the thin OS-B shell
	## (drag / fog / ceiling). Falls back to height*1.6 when omitted.
	var h: float = envelope if envelope > 1.0 else atmo_height * 1.6
	if h <= 1.0:
		return 0.0
	if alt >= h:
		return 0.0
	if alt <= 0.0:
		return 1.0
	var t := 1.0 - alt / h
	return clampf(t * t, 0.0, 1.0)


static func apply_ceiling(velocity: Vector3, inward: Vector3, atmo: float, delta: float) -> Vector3:
	## Extra damp on climb in dense air. Does not oppose S-sink (inward).
	if atmo < 0.02 or inward.length_squared() < 0.25 or delta <= 0.0:
		return velocity
	var climb: float = velocity.dot(-inward)
	if climb <= 0.4:
		return velocity
	return velocity - (-inward) * climb * atmo * 0.38 * delta


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
	snap_dist: float,
	delta: float = 0.0
) -> Vector3:
	## Soft brake when near a pad and closing in (landing assist, not autopilot).
	## `to_pad` points at the pad, so closing speed is a positive dot product.
	if dist > snap_dist or dist < 2.0:
		return velocity
	if to_pad.length_squared() <= 0.01:
		return velocity
	var closing := velocity.dot(to_pad.normalized())
	if closing < 2.0:
		return velocity
	var t := 1.0 - dist / snap_dist
	# Frame-rate independent, and weak enough that it cannot sneak a fast
	# approach past the land gate.
	var w: float = t * t * 1.6 * (delta if delta > 0.0 else 0.016)
	return velocity.lerp(Vector3.ZERO, clampf(w, 0.0, 0.2))


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


static func ground_effect_accel(g: Vector3, height_agl: float, pad_dist: float, v_up: float) -> Vector3:
	## Extra lift near terrain / pads — cushion, not an autopilot.
	if g.length() < 0.01:
		return Vector3.ZERO
	var up_dir := (-g).normalized()
	var h := clampf(height_agl, 0.15, 90.0)
	var ge := 0.0
	if h < 22.0:
		var t := 1.0 - h / 22.0
		ge = t * t
	var pad_n := 0.0
	if pad_dist >= 0.0 and pad_dist < 55.0:
		pad_n = 1.0 - pad_dist / 55.0
	var lift: float = g.length() * (ge * 0.38 + pad_n * ge * 0.32)
	if v_up < -1.0 and ge > 0.04:
		lift += (-v_up) * ge * 2.4
	return up_dir * lift


static func stall_speed(mode: int) -> float:
	## Minimum flying speed in dense atmo. HOVER is VTOL — no stall.
	match mode:
		Mode.NAV:
			return 48.0
		Mode.HOVER:
			return 0.0
		_:
			return 16.0


static func stall_amount(atmo: float, speed: float, stall_spd: float) -> float:
	## 0 flying … 1 fully stalled. Vacuum does not stall.
	if stall_spd <= 0.05 or atmo < 0.22:
		return 0.0
	var need: float = stall_spd * (0.32 + atmo * 0.68)
	if speed >= need:
		return 0.0
	return clampf(1.0 - speed / maxf(need, 0.15), 0.0, 1.0)


static func stall_sink_accel(g: Vector3, stall: float) -> Vector3:
	if stall <= 0.01 or g.length() < 0.01:
		return Vector3.ZERO
	return g * stall * 0.9


static func aero_lift_accel(velocity: Vector3, wing_up: Vector3, atmo: float, stall: float = 0.0) -> Vector3:
	## OS-F: dynamic-pressure lift in the dense OS-B shell. Vacuum / thin
	## 770 m envelope = 0. Force is perpendicular to airflow toward the wing
	## (glide), never along-velocity thrust. Cap stays under hold-S (28).
	## HOVER / hold-S skip this in ShipController — VTOL and inward sink stay.
	if atmo < 0.18 or stall >= 0.92 or wing_up.length_squared() < 0.25:
		return Vector3.ZERO
	var spd: float = velocity.length()
	if spd < 6.0:
		return Vector3.ZERO
	var up: Vector3 = wing_up.normalized()
	var v_dir: Vector3 = velocity / spd
	var lift_dir: Vector3 = up - v_dir * v_dir.dot(up)
	if lift_dir.length_squared() < 0.05:
		return Vector3.ZERO
	lift_dir = lift_dir.normalized()
	var live: float = clampf(1.0 - stall, 0.0, 1.0)
	var lift: float = atmo * spd * spd * 0.0085 * live
	return lift_dir * minf(lift, 18.0)
