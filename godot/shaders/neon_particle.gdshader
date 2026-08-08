shader_type spatial;
render_mode unshaded, blend_add, depth_draw_opaque, cull_disabled, shadows_disabled, ambient_light_disabled;

// Soft neon billboard particle — min-spec friendly (no lighting, additive).
uniform vec4 albedo : source_color = vec4(0.3, 0.9, 1.0, 0.85);
uniform float soft_edge : hint_range(0.1, 1.0) = 0.55;
uniform float core_boost : hint_range(0.0, 4.0) = 1.6;

void fragment() {
	// UV-centered soft disc (cheaper than texture sample)
	vec2 c = UV - vec2(0.5);
	float d = length(c) * 2.0;
	float a = 1.0 - smoothstep(soft_edge, 1.0, d);
	a *= albedo.a;
	if (a < 0.02) {
		discard;
	}
	float core = 1.0 - smoothstep(0.0, 0.45, d);
	vec3 col = albedo.rgb * (1.0 + core * core_boost);
	ALBEDO = col;
	ALPHA = a;
	EMISSION = col * (0.8 + core);
}
