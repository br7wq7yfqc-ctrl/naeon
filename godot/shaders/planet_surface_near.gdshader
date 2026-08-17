shader_type spatial;
/* NAEON near-ground read — OS-E.
 * Tileable albedo + procedural decals on existing Relief chunks.
 * Not a second height field. Unshaded: StandardMaterial PBR + patch
 * normals read as a black walk surface (SurfaceDetail).
 * CC0 stand-ins (binaries stay on s3://neon, not git):
 *   Poly Haven forest_ground_04 / rock_face
 *   ambientCG Ground037 / Rock023
 */
render_mode unshaded, ambient_light_disabled, shadows_disabled, cull_disabled;

uniform float seed : hint_range(0.0, 10000.0) = 1.0;
uniform vec3 planet_origin = vec3(0.0);
uniform vec3 sun_direction = vec3(0.55, 0.75, 0.35);
uniform float micro_strength : hint_range(0.0, 0.5) = 0.22;
uniform float decal_strength : hint_range(0.0, 1.0) = 0.55;
uniform float near_fade_start : hint_range(2.0, 40.0) = 8.0;
uniform float near_fade_end : hint_range(20.0, 160.0) = 52.0;
uniform float emission_strength : hint_range(0.0, 0.4) = 0.10;
uniform float roughness_var : hint_range(0.0, 1.0) = 0.55;
uniform float chart_radius : hint_range(100.0, 4000.0) = 1400.0;

varying vec3 v_world;
varying vec3 v_color;
varying float v_biome;
varying vec2 v_chart;

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031 + seed * 0.017);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float tile_grain(vec2 p) {
	/* Periodic, not a height FBM. Same chart metres as Relief. */
	float v = sin(p.x * 1.9 + p.y * 1.4) * cos(p.y * 1.1 - p.x * 0.7);
	v += 0.45 * sin(p.x * 4.1 - p.y * 3.3) * cos(p.y * 3.7 + p.x * 2.2);
	return v * 0.5;
}

vec2 chart_of(vec3 world) {
	if (abs(v_chart.x) + abs(v_chart.y) > 0.001) {
		return v_chart;
	}
	vec3 n = normalize(world - planet_origin);
	float lat = asin(clamp(n.y, -1.0, 1.0));
	float lon = atan(n.x, n.z);
	return vec2(lon, lat) * chart_radius;
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_color = COLOR.rgb;
	v_biome = COLOR.a;
	v_chart = UV2;
}

void fragment() {
	vec3 col = v_color;
	float dist = length(CAMERA_POSITION_WORLD - v_world);
	float near_w = 1.0 - smoothstep(near_fade_start, near_fade_end, dist);
	float mid_w = 1.0 - smoothstep(near_fade_end, near_fade_end * 2.2, dist);
	float land = step(0.12, v_biome);

	vec2 chart = chart_of(v_world);
	float g1 = tile_grain(chart * 0.85 + seed * 0.13);
	float g2 = tile_grain(chart * 3.4 - seed * 0.07);
	float grit = hash21(floor(chart * 6.5 + seed));
	float pebble = step(0.82, hash21(floor(chart * 14.0 + seed * 0.3)));
	float blotch = smoothstep(0.55, 0.92, hash21(floor(chart * 0.22 + seed)));
	float flake = step(0.88, hash21(floor(chart * 1.15 + 4.2)));
	float dust = smoothstep(0.62, 0.95, hash21(floor(chart * 0.08 - seed * 0.02)));

	vec3 dirt = vec3(0.28, 0.22, 0.14);
	vec3 stone = vec3(0.42, 0.40, 0.38);
	vec3 sand = vec3(0.62, 0.52, 0.32);
	vec3 moss = vec3(0.18, 0.28, 0.14);
	vec3 overlay = dirt;
	if (v_biome > 0.24 && v_biome < 0.36) {
		overlay = sand;
	} else if (v_biome > 0.60 && v_biome < 0.72) {
		overlay = stone;
	} else if (v_biome > 0.94) {
		overlay = mix(dirt, moss, 0.45);
	}

	col += vec3(g1 * 0.08 + g2 * 0.05) * micro_strength * mid_w;
	col = mix(col, overlay, blotch * decal_strength * near_w * land);
	col = mix(col, stone, flake * decal_strength * 0.65 * near_w * land);
	col = mix(col, sand, dust * decal_strength * 0.22 * near_w * land);
	col += vec3(pebble * 0.07 - grit * 0.04) * near_w * micro_strength * land;

	vec3 up = normalize(v_world - planet_origin);
	float ndl = dot(up, normalize(sun_direction));
	float day = clamp(ndl * 0.5 + 0.55, 0.14, 1.0);
	float rough = mix(0.35, 0.95, roughness_var * (0.5 + 0.5 * g1));
	float spec = pow(clamp(ndl, 0.0, 1.0), mix(18.0, 4.0, rough)) * (1.0 - rough) * 0.18 * near_w;

	ALBEDO = col * day + spec * vec3(0.85, 0.88, 0.90);
	EMISSION = col * emission_strength * day;
}
