extends RefCounted
class_name PlanetRelief
## Analytic multi-feature height: mountains, seas, rivers, canyons, cave openness.

static func height_at(x: float, z: float, seed: int, profile: Dictionary = {}) -> float:
	var sea: float = float(profile.get("sea_level", -0.35))
	var mtn_amp: float = float(profile.get("mountain_amp", 6.5))
	var hill_amp: float = float(profile.get("hill_amp", 1.8))
	var canyon_amp: float = float(profile.get("canyon_amp", 4.2))
	var river_w: float = float(profile.get("river_width", 1.1))
	var sx := x * 0.07 + float(seed) * 0.017
	var sz := z * 0.07 + float(seed) * 0.013
	var hills := _fbm(sx * 0.9, sz * 0.9, 3) * hill_amp
	var ridge := 1.0 - absf(_fbm(sx * 0.35 + 2.1, sz * 0.35 - 1.4, 4))
	ridge = pow(clampf(ridge, 0.0, 1.0), 1.6)
	var mountains := ridge * mtn_amp * _mask(sx * 0.15 + 0.3, sz * 0.15, 0.42)
	var continent := _fbm(sx * 0.12, sz * 0.12, 2)
	var basin := smoothstep(-0.15, 0.25, continent)
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
	var h := hills + mountains * basin + canyon + river
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
	if h > 4.5:
		return "alpine"
	if h > 2.0:
		return "hills"
	return "plains"

static func profile_for_planet(planet_id: String) -> Dictionary:
	match planet_id:
		"Nex-Prime":
			return {"sea_level": -0.25, "mountain_amp": 7.2, "hill_amp": 2.0, "canyon_amp": 3.8, "river_width": 1.25, "caves": true}
		"ROT-Hive":
			return {"sea_level": -0.45, "mountain_amp": 5.0, "hill_amp": 2.4, "canyon_amp": 5.5, "river_width": 1.4, "caves": true}
		"Shard-Moon":
			return {"sea_level": -1.8, "mountain_amp": 4.0, "hill_amp": 1.1, "canyon_amp": 6.0, "river_width": 0.4, "caves": true}
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
	return smoothstep(threshold - 0.15, threshold + 0.25, m)

static func smoothstep(e0: float, e1: float, x: float) -> float:
	var t := clampf((x - e0) / maxf(e1 - e0, 0.0001), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
