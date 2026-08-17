shader_type spatial;
/* NAEON planet surface — cheap Relief subset (continent / ridge / sea).
 * Same seed and lon/lat chart as PlanetRelief. Far pass drops rivers/caves.
 * Not a second value-noise planet.
 */
render_mode unshaded, ambient_light_disabled, shadows_disabled, fog_disabled;

uniform vec4 land_color : source_color = vec4(0.14, 0.28, 0.16, 1.0);
uniform vec4 ocean_color : source_color = vec4(0.05, 0.18, 0.38, 1.0);
uniform vec4 shore_color : source_color = vec4(0.42, 0.38, 0.22, 1.0);
uniform vec4 ice_color : source_color = vec4(0.72, 0.78, 0.85, 1.0);
uniform vec4 mountain_tint : source_color = vec4(0.35, 0.35, 0.38, 1.0);
uniform vec4 dune_color : source_color = vec4(0.55, 0.45, 0.28, 1.0);
uniform vec4 city_light_color : source_color = vec4(1.0, 0.82, 0.45, 1.0);
uniform float sea_level : hint_range(-2.0, 1.0) = -0.25;
uniform float shore_width : hint_range(0.01, 0.25) = 0.07;
uniform float ice_lat : hint_range(0.5, 1.0) = 0.78;
uniform float seed : hint_range(0.0, 10000.0) = 1.0;
uniform float chart_radius : hint_range(200.0, 4000.0) = 1400.0;
uniform float emission_strength : hint_range(0.0, 1.0) = 0.06;
uniform float city_intensity : hint_range(0.0, 3.0) = 1.35;
uniform float city_density : hint_range(0.0, 1.0) = 0.55;
uniform float micro_detail : hint_range(0.0, 0.35) = 0.08;
uniform vec3 sun_direction = vec3(0.55, 0.75, 0.35);

varying vec3 v_world_n;

float hash13(vec3 p) {
	p = fract(p * 0.1031 + seed * 0.017);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float relief_fbm(float x, float z, int octaves) {
	float v = 0.0;
	float amp = 1.0;
	float freq = 1.0;
	float norm = 0.0;
	for (int o = 0; o < octaves; o++) {
		v += amp * sin(x * freq * 1.7 + z * freq * 1.3) * cos(z * freq * 0.9 - x * freq * 0.6);
		norm += amp;
		amp *= 0.5;
		freq *= 2.05;
	}
	return v / max(norm, 0.001);
}

void vertex() {
	v_world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(v_world_n);
	float lat = asin(clamp(n.y, -1.0, 1.0));
	float lon = atan(n.x, n.z);
	float x = lon * chart_radius;
	float z = lat * chart_radius;
	float sx = x * 0.07 + seed * 0.017;
	float sz = z * 0.07 + seed * 0.013;
	float continent = relief_fbm(sx * 0.12, sz * 0.12, 2);
	float t = clamp((continent + 0.15) / 0.40, 0.0, 1.0);
	float basin = t * t * (3.0 - 2.0 * t);
	float ridge = 1.0 - abs(relief_fbm(sx * 0.35 + 2.1, sz * 0.35 - 1.4, 4));
	ridge = pow(clamp(ridge, 0.0, 1.0), 1.6);
	/* Cheap height sign: ocean when basin < 0.35 (same pull as PlanetRelief). */
	float elev = mix(sea_level - 1.2, ridge * 6.0 * basin, step(0.35, basin));
	float grain = sin(sx * 9.0 + sz * 7.0) * 0.5 + 0.5;

	vec3 col = ocean_color.rgb;
	float is_land = 0.0;
	if (elev > sea_level + 0.55) {
		float mt = smoothstep(4.0, 6.0, elev);
		col = mix(land_color.rgb, mountain_tint.rgb, mt);
		col += vec3(grain * micro_detail);
		is_land = 1.0 - mt * 0.35;
	} else if (elev > sea_level) {
		float s = (elev - sea_level) / max(0.55, 0.001);
		col = mix(ocean_color.rgb, mix(shore_color.rgb, land_color.rgb, 0.35), s);
		is_land = s * 0.5;
	} else {
		float depth = clamp((sea_level - elev) * 0.7, 0.0, 1.0);
		col = mix(ocean_color.rgb * 1.12, ocean_color.rgb * 0.5, depth);
		float spark = step(0.97, hash13(floor(n * 90.0 + seed)));
		col += vec3(0.15, 0.2, 0.25) * spark * (1.0 - depth);
	}
	if (abs(n.y) > ice_lat) {
		col = mix(col, ice_color.rgb, smoothstep(ice_lat, 0.98, abs(n.y)));
		is_land *= 0.3;
	}

	float ndl = dot(n, normalize(sun_direction));
	float day = clamp(ndl * 0.5 + 0.55, 0.12, 1.0);
	float night = clamp(1.0 - (ndl * 0.5 + 0.5) * 1.6, 0.0, 1.0);

	float city = 0.0;
	if (is_land > 0.4 && night > 0.05 && city_intensity > 0.01) {
		float cells = hash13(floor(n * 48.0 + seed));
		float cluster = smoothstep(1.0 - city_density * 0.45, 1.0, cells);
		float spark = step(0.82, hash13(floor(n * 120.0)));
		city = cluster * spark * is_land * night * city_intensity;
	}

	ALBEDO = col * day + city_light_color.rgb * city * 0.35;
	EMISSION = col * emission_strength * day + city_light_color.rgb * city;
}
