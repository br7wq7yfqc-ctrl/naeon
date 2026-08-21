extends RefCounted
class_name PlanetRelief
## Analytic multi-feature height: mountains, seas, rivers, canyons, cave openness.
## OS-A: one body_seed + sphere_xz domain for orbit paint and dirt chunks.
## P0.6 also keeps dir_to_chart / height_at_dir on CHART_RADIUS (Nex-Prime scale).

## Metres-per-radian of the shared chart. Matches Nex-Prime scale so existing
## Relief frequencies stay in the same ballpark.
const CHART_RADIUS := 1400.0


static func body_seed(planet_id: String) -> int:
	## Single stable integer per authored body id. Channel offsets are for
	## placement RNG only — never a second height seed.
	return int(absi(str(planet_id).hash()) % 10000)


static func dir_to_chart(dir: Vector3) -> Vector2:
	return sphere_xz(dir, CHART_RADIUS)


static func height_at_dir(dir: Vector3, seed: int, profile: Dictionary = {}) -> float:
	var c: Vector2 = dir_to_chart(dir)
	return height_at(c.x, c.y, seed, profile)


static func sphere_xz(dir: Vector3, radius: float) -> Vector2:
	var n := dir.normalized()
	var lat := asin(clampf(n.y, -1.0, 1.0))
	var lon := atan2(n.x, n.z)
	return Vector2(lon * radius, lat * radius)


static func height_on_sphere(dir: Vector3, radius: float, seed: int, profile: Dictionary = {}, macro_only: bool = false) -> float:
	# radius is the displacement frame only. FBM domain is CHART_RADIUS so
	# orbit paint, dirt chunks, walker, and ship AGL read one field.
	var _r := radius
	var xz: Vector2 = dir_to_chart(dir)
	if macro_only:
		return height_macro_at(xz.x, xz.y, seed, profile)
	return height_at(xz.x, xz.y, seed, profile)


static func height_macro_at(x: float, z: float, seed: int, profile: Dictionary = {}) -> float:
	## Continent / ridge / sea only — far & impostor. Same FBM as height_at.
	var m: Dictionary = _macro_terms(x, z, seed, profile)
	return float(m.get("h", 0.0))


static func _domain(x: float, z: float, seed: int) -> Vector2:
	return Vector2(x * 0.07 + float(seed) * 0.017, z * 0.07 + float(seed) * 0.013)


static func _macro_terms(x: float, z: float, seed: int, profile: Dictionary) -> Dictionary:
	var sea: float = float(profile.get("sea_level", -0.35))
	var mtn_amp: float = float(profile.get("mountain_amp", 6.5))
	var hill_amp: float = float(profile.get("hill_amp", 1.8))
	var d: Vector2 = _domain(x, z, seed)
	var sx := d.x
	var sz := d.y
	var hills := _fbm(sx * 0.9, sz * 0.9, 3) * hill_amp
	var ridge := 1.0 - absf(_fbm(sx * 0.35 + 2.1, sz * 0.35 - 1.4, 4))
	ridge = pow(clampf(ridge, 0.0, 1.0), 1.6)
	var mountains := ridge * mtn_amp * _mask(sx * 0.15 + 0.3, sz * 0.15, 0.42)
	var continent := _fbm(sx * 0.12, sz * 0.12, 2)
	var basin := _smoothstep(-0.15, 0.25, continent)
	var h_land := hills + mountains * basin
	var h := h_land
	if basin < 0.35:
		var ocean_pull := (0.35 - basin) / 0.35
		h = lerpf(h, sea - 0.8 - ocean_pull * 1.4, clampf(ocean_pull * 1.2, 0.0, 1.0))
	return {"h": h, "h_land": h_land, "basin": basin, "ridge": ridge, "continent": continent, "sx": sx, "sz": sz, "sea": sea}


static func height_at(x: float, z: float, seed: int, profile: Dictionary = {}) -> float:
	var m: Dictionary = _macro_terms(x, z, seed, profile)
	var h: float = float(m.get("h", 0.0))
	var basin: float = float(m.get("basin", 0.0))
	var ridge: float = float(m.get("ridge", 0.0))
	var sx: float = float(m.get("sx", 0.0))
	var sz: float = float(m.get("sz", 0.0))
	var sea: float = float(m.get("sea", -0.35))
	var canyon_amp: float = float(profile.get("canyon_amp", 4.2))
	var river_w: float = float(profile.get("river_width", 1.1))
	var canyon_line := absf(_warp_noise(sx * 0.55, sz * 0.55, seed))
	var canyon := 0.0
	if canyon_line < 0.085:
		var t := 1.0 - canyon_line / 0.085
		canyon = -canyon_amp * t * t * (0.55 + 0.45 * basin)
	var river_line := absf(_warp_noise(sx * 0.4 + 5.0, sz * 0.4 - 3.0, seed + 17))
	var river := 0.0
	if river_line < 0.05 * river_w:
		var rt := 1.0 - river_line / maxf(0.05 * river_w, 0.001)
		river = -1.6 * rt * rt * (1.1 - basin * 0.4)
	# Dunes (arid plains)
	var dune_amp: float = float(profile.get("dune_amp", 0.0))
	var dunes := 0.0
	if dune_amp > 0.01 and basin > 0.4 and ridge < 0.55:
		var dphase := sx * 2.4 + _fbm(sx * 0.5, sz * 0.5, 1) * 1.2
		dunes = sin(dphase) * cos(sz * 1.7) * dune_amp * (0.5 + 0.5 * basin)
	# Mesa plateaus
	var mesa_amp: float = float(profile.get("mesa_amp", 0.0))
	var mesa := 0.0
	if mesa_amp > 0.01:
		var mmask := _mask(sx * 0.22 + 1.7, sz * 0.22 - 0.9, 0.58)
		if mmask > 0.55:
			mesa = mesa_amp * mmask
			# Steep mesa skirts
			var edge := absf(mmask - 0.55)
			if edge < 0.12:
				mesa *= 0.7 + edge * 2.0
	# Impact craters
	var crater_amp: float = float(profile.get("crater_amp", 0.0))
	var crater := 0.0
	if crater_amp > 0.01:
		var cx := _fbm(sx * 0.08 + 9.0, sz * 0.08, 1)
		var cz := _fbm(sx * 0.08, sz * 0.08 + 4.0, 1)
		var cr := sqrt(cx * cx + cz * cz)
		var cell := Vector2(floorf(sx * 0.35), floorf(sz * 0.35))
		var ch := absf(sin(cell.x * 12.9898 + cell.y * 78.233 + float(seed))) 
		if ch > 0.82:
			var lx := fract(sx * 0.35) - 0.5
			var lz := fract(sz * 0.35) - 0.5
			var rd := sqrt(lx * lx + lz * lz)
			if rd < 0.28:
				var bowl := (1.0 - rd / 0.28)
				crater = -crater_amp * bowl * bowl
				if rd > 0.18:
					crater += crater_amp * 0.35 * (1.0 - absf(rd - 0.22) / 0.06)  # rim
	h = float(m.get("h_land", h)) + canyon + river + dunes + mesa + crater
	if basin < 0.35:
		var ocean_pull := (0.35 - basin) / 0.35
		h = lerpf(h, sea - 0.8 - ocean_pull * 1.4, clampf(ocean_pull * 1.2, 0.0, 1.0))
	if h < sea + 0.6 and h > sea - 1.5:
		h = lerpf(h, sea * 0.3 + h * 0.7, 0.35)
	return h

static func is_sea(h: float, profile: Dictionary = {}) -> bool:
	return h < float(profile.get("sea_level", -0.35))

static func is_river(x: float, z: float, seed: int, profile: Dictionary = {}) -> bool:
	var river_w: float = float(profile.get("river_width", 1.1))
	var sx := x * 0.07 + float(seed) * 0.017
	var sz := z * 0.07 + float(seed) * 0.013
	var river_line := absf(_warp_noise(sx * 0.4 + 5.0, sz * 0.4 - 3.0, seed + 17))
	return river_line < 0.045 * river_w

static func is_canyon(x: float, z: float, seed: int) -> bool:
	var sx := x * 0.07 + float(seed) * 0.017
	var sz := z * 0.07 + float(seed) * 0.013
	return absf(_warp_noise(sx * 0.55, sz * 0.55, seed)) < 0.07

static func cave_openness(x: float, z: float, y: float, seed: int, profile: Dictionary = {}) -> float:
	if not bool(profile.get("caves", true)):
		return 0.0
	if y > -0.4:
		return 0.0
	var sx := x * 0.11 + float(seed) * 0.02
	var sz := z * 0.11 + float(seed) * 0.015
	var sy := y * 0.14
	var n := _fbm(sx + sy * 0.3, sz - sy * 0.2, 3)
	var blob := 1.0 - absf(n)
	var boost := 0.25 if is_canyon(x, z, seed) else 0.0
	return clampf((blob - 0.55 + boost) * 2.2, 0.0, 1.0)

static func biome_hint(x: float, z: float, h: float, seed: int, profile: Dictionary = {}) -> String:
	var sea: float = float(profile.get("sea_level", -0.35))
	if h < sea - 0.3:
		return "ocean"
	if h < sea + 0.45:
		return "shore"
	if is_river(x, z, seed, profile):
		return "river"
	if is_canyon(x, z, seed):
		return "canyon"
	if float(profile.get("crater_amp", 0.0)) > 0.5 and h < sea + 0.2:
		return "crater"
	if float(profile.get("mesa_amp", 0.0)) > 1.0 and h > 3.5:
		var sx2 := x * 0.07 + float(seed) * 0.017
		var sz2 := z * 0.07 + float(seed) * 0.013
		if _mask(sx2 * 0.22 + 1.7, sz2 * 0.22 - 0.9, 0.58) > 0.55:
			return "mesa"
	if float(profile.get("dune_amp", 0.0)) > 0.4 and h > sea + 0.5 and h < 2.5:
		return "dunes"
	if h > 4.5:
		return "alpine"
	if h > 2.0:
		return "hills"
	return "plains"

static func profile_for_planet(planet_id: String) -> Dictionary:
	match planet_id:
		"Nex-Prime":
			return {"sea_level": -0.25, "mountain_amp": 7.2, "hill_amp": 2.0, "canyon_amp": 3.8, "river_width": 1.25, "caves": true, "dune_amp": 0.35, "mesa_amp": 2.2, "crater_amp": 0.8}
		"ROT-Hive":
			return {"sea_level": -0.45, "mountain_amp": 5.0, "hill_amp": 2.4, "canyon_amp": 5.5, "river_width": 1.4, "caves": true, "dune_amp": 1.1, "mesa_amp": 1.5, "crater_amp": 1.2}
		"Shard-Moon":
			return {"sea_level": -1.8, "mountain_amp": 4.0, "hill_amp": 1.1, "canyon_amp": 6.0, "river_width": 0.4, "caves": true, "dune_amp": 0.0, "mesa_amp": 3.5, "crater_amp": 3.2}
		_:
			return {"sea_level": -0.35, "mountain_amp": 6.0, "hill_amp": 1.8, "canyon_amp": 4.0, "river_width": 1.0, "caves": true}

static func _fbm(x: float, z: float, octaves: int) -> float:
	var v := 0.0
	var amp := 1.0
	var freq := 1.0
	var norm := 0.0
	for _o in octaves:
		v += amp * sin(x * freq * 1.7 + z * freq * 1.3) * cos(z * freq * 0.9 - x * freq * 0.6)
		norm += amp
		amp *= 0.5
		freq *= 2.05
	return v / maxf(norm, 0.001)

static func _warp_noise(x: float, z: float, seed: int) -> float:
	var wx := _fbm(x * 0.8 + float(seed) * 0.01, z * 0.8, 2) * 0.9
	var wz := _fbm(x * 0.8 - 2.0, z * 0.8 + float(seed) * 0.007, 2) * 0.9
	return _fbm(x + wx, z + wz, 2)

static func _mask(x: float, z: float, threshold: float) -> float:
	var m := _fbm(x, z, 2)
	return _smoothstep(threshold - 0.15, threshold + 0.25, m)

static func _smoothstep(e0: float, e1: float, x: float) -> float:
	var t := clampf((x - e0) / maxf(e1 - e0, 0.0001), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func fract(x: float) -> float:
	return x - floorf(x)
