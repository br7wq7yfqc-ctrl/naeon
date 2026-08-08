shader_type spatial;
/* NAEON planet surface — land/ocean + micro-detail + night city.
 * Still 2-octave base FBM; one extra micro layer for texture read.
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
uniform float sea_threshold : hint_range(-0.5, 0.8) = 0.08;
uniform float shore_width : hint_range(0.01, 0.25) = 0.07;
uniform float mountain_threshold : hint_range(0.0, 1.0) = 0.62;
uniform float ice_lat : hint_range(0.5, 1.0) = 0.78;
uniform float seed : hint_range(0.0, 100.0) = 1.0;
uniform float emission_strength : hint_range(0.0, 1.0) = 0.06;
uniform float city_intensity : hint_range(0.0, 3.0) = 1.35;
uniform float city_density : hint_range(0.0, 1.0) = 0.55;
uniform float micro_detail : hint_range(0.0, 0.35) = 0.14;
uniform vec3 sun_direction = vec3(0.55, 0.75, 0.35);

varying vec3 v_world_n;

float hash13(vec3 p) {
	p = fract(p * 0.1031 + seed * 0.017);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f *= f * (3.0 - 2.0 * f);
	float n000 = hash13(i);
	float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
	float x00 = mix(n000, n100, f.x);
	float x10 = mix(n010, n110, f.x);
	float x01 = mix(n001, n101, f.x);
	float x11 = mix(n011, n111, f.x);
	return mix(mix(x00, x10, f.y), mix(x01, x11, f.y), f.z);
}

float fbm2(vec3 p) {
	return vnoise(p) * 0.65 + vnoise(p * 2.05) * 0.35;
}

void vertex() {
	v_world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(v_world_n);
	float continent = fbm2(n * 2.15 + seed * 0.07) * 2.0 - 0.85;
	float ridge = 1.0 - abs(fbm2(n * 4.8 + 1.3) * 2.0 - 1.0);
	float elev = continent + ridge * 0.32;
	float lat = abs(n.y);
	/* Micro texture grain (land only later) */
	float grain = vnoise(n * 28.0 + seed) * 2.0 - 1.0;
	float dune_wave = sin(n.x * 40.0 + n.z * 22.0 + seed) * 0.5 + 0.5;

	vec3 col = ocean_color.rgb;
	float is_land = 0.0;
	if (elev > sea_threshold + shore_width) {
		float mt = smoothstep(mountain_threshold, mountain_threshold + 0.25, elev);
		float arid = smoothstep(0.15, 0.55, elev) * (1.0 - mt) * (1.0 - lat);
		col = mix(land_color.rgb, mountain_tint.rgb, mt);
		col = mix(col, dune_color.rgb, arid * 0.45 * dune_wave);
		col += grain * micro_detail * (0.5 + 0.5 * is_land);
		is_land = 1.0 - mt * 0.35;
		col += grain * micro_detail * is_land;
	} else if (elev > sea_threshold) {
		float t = (elev - sea_threshold) / max(shore_width, 0.001);
		col = mix(ocean_color.rgb, mix(shore_color.rgb, land_color.rgb, 0.35), t);
		col += grain * micro_detail * 0.35 * t;
		is_land = t * 0.5;
	} else {
		float depth = clamp((sea_threshold - elev) * 2.0, 0.0, 1.0);
		col = mix(ocean_color.rgb * 1.12, ocean_color.rgb * 0.5, depth);
		/* Soft specular sparkle on ocean (unshaded fake) */
		float spark = step(0.97, hash13(floor(n * 90.0 + seed)));
		col += vec3(0.15, 0.2, 0.25) * spark * (1.0 - depth);
	}
	if (lat > ice_lat) {
		col = mix(col, ice_color.rgb, smoothstep(ice_lat, 0.98, lat));
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
