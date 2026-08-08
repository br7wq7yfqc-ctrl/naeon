shader_type spatial;
/* NAEON far/mid planet surface — land vs ocean albedo bands.
 * Cheap procedural noise on sphere normal. Matches PlanetRelief continent feel.
 * Safe on RTX 1060 3GB (no textures, no raymarch).
 */
render_mode diffuse_lambert, specular_disabled, ambient_light_disabled, shadows_disabled;

uniform vec4 land_color : source_color = vec4(0.14, 0.28, 0.16, 1.0);
uniform vec4 ocean_color : source_color = vec4(0.05, 0.18, 0.38, 1.0);
uniform vec4 shore_color : source_color = vec4(0.42, 0.38, 0.22, 1.0);
uniform vec4 ice_color : source_color = vec4(0.72, 0.78, 0.85, 1.0);
uniform vec4 mountain_tint : source_color = vec4(0.35, 0.35, 0.38, 1.0);
uniform float sea_threshold : hint_range(-0.5, 0.8) = 0.08;
uniform float shore_width : hint_range(0.01, 0.25) = 0.07;
uniform float mountain_threshold : hint_range(0.0, 1.0) = 0.62;
uniform float ice_lat : hint_range(0.5, 1.0) = 0.78;
uniform float seed : hint_range(0.0, 100.0) = 1.0;
uniform float emission_strength : hint_range(0.0, 1.0) = 0.08;
uniform vec3 sun_direction = vec3(0.55, 0.75, 0.35);

varying vec3 v_world_n;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1 + seed * 0.01);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
			mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
			mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y),
		f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.05;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	v_world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(v_world_n);
	// Continent / basin (large scale)
	float continent = fbm(n * 2.2 + seed * 0.1) * 2.0 - 0.85;
	// Ridges
	float ridge = 1.0 - abs(fbm(n * 5.5 + 1.7) * 2.0 - 1.0);
	float elev = continent + ridge * 0.35;

	float lat = abs(n.y);
	vec3 col = ocean_color.rgb;
	if (elev > sea_threshold + shore_width) {
		col = mix(land_color.rgb, mountain_tint.rgb, smoothstep(mountain_threshold, mountain_threshold + 0.25, elev));
	} else if (elev > sea_threshold) {
		float t = (elev - sea_threshold) / max(shore_width, 0.001);
		col = mix(ocean_color.rgb, shore_color.rgb, t);
		col = mix(col, land_color.rgb, t * 0.35);
	} else {
		// Deep vs shallow ocean
		float depth = clamp((sea_threshold - elev) * 2.0, 0.0, 1.0);
		col = mix(ocean_color.rgb * 1.15, ocean_color.rgb * 0.55, depth);
	}
	// Polar ice
	if (lat > ice_lat) {
		float ice_t = smoothstep(ice_lat, 0.98, lat);
		col = mix(col, ice_color.rgb, ice_t);
	}

	float day = clamp(dot(n, normalize(sun_direction)) * 0.5 + 0.55, 0.15, 1.0);
	ALBEDO = col * day;
	ROUGHNESS = mix(0.25, 0.92, step(sea_threshold, elev));
	METALLIC = 0.05 * (1.0 - step(sea_threshold, elev));
	EMISSION = col * emission_strength * (0.5 + 0.5 * day);
}
