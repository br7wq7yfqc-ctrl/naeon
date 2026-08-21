shader_type spatial;
/* NAEON planet surface — OS-A same-body paint.
 * Continent / ridge / sea = PlanetRelief.height_macro_at (sin/cos FBM).
 * LOD drops rivers/micro. Must not substitute a different FBM.
 * Min-spec safe (RTX 1060 3GB).
 */
render_mode unshaded, ambient_light_disabled, shadows_disabled, fog_disabled;

uniform vec4 land_color : source_color = vec4(0.14, 0.28, 0.16, 1.0);
uniform vec4 ocean_color : source_color = vec4(0.05, 0.18, 0.38, 1.0);
uniform vec4 shore_color : source_color = vec4(0.42, 0.38, 0.22, 1.0);
uniform vec4 ice_color : source_color = vec4(0.72, 0.78, 0.85, 1.0);
uniform vec4 mountain_tint : source_color = vec4(0.35, 0.35, 0.38, 1.0);
uniform vec4 dune_color : source_color = vec4(0.55, 0.45, 0.28, 1.0);
uniform vec4 city_light_color : source_color = vec4(1.0, 0.82, 0.45, 1.0);
uniform float sea_threshold : hint_range(-2.0, 2.0) = -0.25;
uniform float shore_width : hint_range(0.01, 2.0) = 0.55;
uniform float mountain_threshold : hint_range(0.0, 1.0) = 0.62;
uniform float ice_lat : hint_range(0.5, 1.0) = 0.78;
uniform float seed : hint_range(0.0, 10000.0) = 1.0;
uniform float planet_radius : hint_range(100.0, 4000.0) = 1400.0;
uniform float chart_radius : hint_range(100.0, 4000.0) = 1400.0;
uniform float hill_amp : hint_range(0.0, 8.0) = 2.0;
uniform float mountain_amp : hint_range(0.0, 16.0) = 7.2;
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

float relief_fbm2(float x, float z) {
	float v = sin(x * 1.7 + z * 1.3) * cos(z * 0.9 - x * 0.6);
	float f = 2.05;
	v += 0.5 * sin(x * f * 1.7 + z * f * 1.3) * cos(z * f * 0.9 - x * f * 0.6);
	return v / 1.5;
}

float relief_fbm3(float x, float z) {
	float v = sin(x * 1.7 + z * 1.3) * cos(z * 0.9 - x * 0.6);
	float amp = 0.5;
	float freq = 2.05;
	v += amp * sin(x * freq * 1.7 + z * freq * 1.3) * cos(z * freq * 0.9 - x * freq * 0.6);
	amp *= 0.5;
	freq *= 2.05;
	v += amp * sin(x * freq * 1.7 + z * freq * 1.3) * cos(z * freq * 0.9 - x * freq * 0.6);
	return v / 1.75;
}

float relief_fbm4(float x, float z) {
	float v = 0.0;
	float amp = 1.0;
	float freq = 1.0;
	float norm = 0.0;
	for (int o = 0; o < 4; o++) {
		v += amp * sin(x * freq * 1.7 + z * freq * 1.3) * cos(z * freq * 0.9 - x * freq * 0.6);
		norm += amp;
		amp *= 0.5;
		freq *= 2.05;
	}
	return v / max(norm, 0.001);
}

float relief_mask(float x, float z, float threshold) {
	return smoothstep(threshold - 0.15, threshold + 0.25, relief_fbm2(x, z));
}

void vertex() {
	v_world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(v_world_n);
	float lat = asin(clamp(n.y, -1.0, 1.0));
	float lon = atan(n.x, n.z);
	float px = lon * chart_radius;
	float pz = lat * chart_radius;
	float sx = px * 0.07 + seed * 0.017;
	float sz = pz * 0.07 + seed * 0.013;

	float hills = relief_fbm3(sx * 0.9, sz * 0.9) * hill_amp;
	float ridge = 1.0 - abs(relief_fbm4(sx * 0.35 + 2.1, sz * 0.35 - 1.4));
	ridge = pow(clamp(ridge, 0.0, 1.0), 1.6);
	float mountains = ridge * mountain_amp * relief_mask(sx * 0.15 + 0.3, sz * 0.15, 0.42);
	float continent = relief_fbm2(sx * 0.12, sz * 0.12);
	float basin = smoothstep(-0.15, 0.25, continent);
	float h = hills + mountains * basin;
	if (basin < 0.35) {
		float ocean_pull = (0.35 - basin) / 0.35;
		h = mix(h, sea_threshold - 0.8 - ocean_pull * 1.4, clamp(ocean_pull * 1.2, 0.0, 1.0));
	}

	float grain = hash13(floor(n * 28.0 + seed)) * 2.0 - 1.0;
	vec3 col = ocean_color.rgb;
	float is_land = 0.0;
	if (h > sea_threshold + shore_width) {
		float mt = smoothstep(mountain_threshold, mountain_threshold + 0.25, ridge);
		col = mix(land_color.rgb, mountain_tint.rgb, mt);
		col = mix(col, dune_color.rgb, (1.0 - mt) * basin * 0.25);
		is_land = 1.0 - mt * 0.35;
		col += grain * micro_detail * is_land;
	} else if (h > sea_threshold) {
		float t = (h - sea_threshold) / max(shore_width, 0.001);
		col = mix(ocean_color.rgb, mix(shore_color.rgb, land_color.rgb, 0.35), t);
		col += grain * micro_detail * 0.35 * t;
		is_land = t * 0.5;
	} else {
		float depth = clamp((sea_threshold - h) * 0.35, 0.0, 1.0);
		col = mix(ocean_color.rgb * 1.12, ocean_color.rgb * 0.5, depth);
		float spark = step(0.97, hash13(floor(n * 90.0 + seed)));
		col += vec3(0.15, 0.2, 0.25) * spark * (1.0 - depth);
	}
	float abs_lat = abs(n.y);
	if (abs_lat > ice_lat) {
		col = mix(col, ice_color.rgb, smoothstep(ice_lat, 0.98, abs_lat));
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
