shader_type spatial;
/* NAEON near-ground read — OS-E PBR.
 * Tileable CC0 albedo / roughness / normal on existing Relief chunks.
 * Decals + near LOD fade. Not a second height field. Forward+ lights ALBEDO.
 * Chart UV is CHART_RADIUS metres (same as PlanetRelief.dir_to_chart).
 * CC0 stand-ins (binaries stay on s3://neon, not git):
 *   Poly Haven forest_ground_04 / rock_face
 *   ambientCG Ground037 / Rock023
 */
render_mode shadows_disabled, cull_disabled;

uniform float seed : hint_range(0.0, 10000.0) = 1.0;
uniform vec3 planet_origin = vec3(0.0);
uniform vec3 sun_direction = vec3(0.55, 0.75, 0.35);
uniform float micro_strength : hint_range(0.0, 0.5) = 0.22;
uniform float decal_strength : hint_range(0.0, 1.0) = 0.55;
uniform float decal_density : hint_range(0.2, 2.0) = 1.0;
uniform float tile_meters : hint_range(0.5, 32.0) = 4.0;
uniform float near_fade_start : hint_range(2.0, 40.0) = 8.0;
uniform float near_fade_end : hint_range(20.0, 160.0) = 52.0;
uniform float emission_strength : hint_range(0.0, 0.4) = 0.06;
uniform float roughness_var : hint_range(0.0, 1.0) = 0.55;
uniform float chart_radius : hint_range(100.0, 4000.0) = 1400.0;
uniform float normal_depth : hint_range(0.0, 2.0) = 0.85;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rough_tex : hint_default_white, filter_linear_mipmap, repeat_enable;

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
	/* Periodic grit. Same chart metres as Relief. Not a height FBM. */
	float v = sin(p.x * 1.9 + p.y * 1.4) * cos(p.y * 1.1 - p.x * 0.7);
	v += 0.45 * sin(p.x * 4.1 - p.y * 3.3) * cos(p.y * 3.7 + p.x * 2.2);
	return v * 0.5;
}

vec2 chart_of(vec3 world) {
	/* Always CHART_RADIUS. Body radius must not retile dirt vs rock. */
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
	vec3 vertex_col = v_color;
	float dist = length(CAMERA_POSITION_WORLD - v_world);
	float near_w = 1.0 - smoothstep(near_fade_start, near_fade_end, dist);
	float mid_w = 1.0 - smoothstep(near_fade_end, near_fade_end * 2.2, dist);
	float land = step(0.12, v_biome);

	vec2 chart = chart_of(v_world);
	float g1 = tile_grain(chart * 0.85 + seed * 0.13);
	float g2 = tile_grain(chart * 3.4 - seed * 0.07);
	float dens = clamp(decal_density, 0.2, 2.0);
	float grit = hash21(floor(chart * 6.5 * dens + seed));
	float pebble = step(0.82 - dens * 0.06, hash21(floor(chart * 14.0 * dens + seed * 0.3)));
	float blotch = smoothstep(0.55 - dens * 0.08, 0.92, hash21(floor(chart * 0.22 + seed)));
	float flake = step(0.88 - dens * 0.05, hash21(floor(chart * 1.15 + 4.2)));
	float dust = smoothstep(0.62, 0.95, hash21(floor(chart * 0.08 - seed * 0.02)));

	vec2 uv_d = chart / max(tile_meters, 0.5);
	vec2 uv_r = chart / max(tile_meters * 1.35, 0.5);
	vec3 dirt = texture(albedo_tex, uv_d).rgb;
	vec3 rock = texture(rock_tex, uv_r).rgb;
	vec3 nrm = texture(normal_tex, uv_d).rgb;
	float rough_s = texture(rough_tex, uv_d).r;

	vec3 overlay = dirt;
	if (v_biome > 0.24 && v_biome < 0.36) {
		overlay = mix(dirt, vec3(0.62, 0.52, 0.32), 0.35);
	} else if (v_biome > 0.60 && v_biome < 0.72) {
		overlay = mix(dirt, rock, 0.72);
	} else if (v_biome > 0.94) {
		overlay = mix(dirt, vec3(0.18, 0.28, 0.14), 0.28);
	}

	vec3 col = mix(vertex_col, overlay, 0.78 * near_w + 0.22 * mid_w);
	col += vec3(g1 * 0.06 + g2 * 0.04) * micro_strength * mid_w;
	col = mix(col, mix(dirt, rock, 0.55), blotch * decal_strength * near_w * land);
	col = mix(col, rock, flake * decal_strength * 0.65 * near_w * land);
	col = mix(col, mix(dirt, vec3(0.62, 0.52, 0.32), 0.5), dust * decal_strength * 0.22 * near_w * land);
	col += vec3(pebble * 0.05 - grit * 0.03) * near_w * micro_strength * land;

	float rough = mix(0.42, 0.92, roughness_var * (0.45 + 0.55 * rough_s));
	rough = mix(rough, 0.78, blotch * 0.25 * near_w);
	rough = clamp(rough + g1 * 0.08 * micro_strength, 0.18, 0.97);

	vec3 far_col = vertex_col;
	col = mix(far_col, col, clamp(near_w * 0.92 + mid_w * 0.35, 0.0, 1.0));

	ALBEDO = col;
	ROUGHNESS = mix(0.72, rough, near_w);
	METALLIC = 0.0;
	SPECULAR = 0.35;
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), nrm, near_w * land);
	NORMAL_MAP_DEPTH = normal_depth * near_w;
	EMISSION = col * emission_strength * (0.4 + 0.6 * near_w);
}
