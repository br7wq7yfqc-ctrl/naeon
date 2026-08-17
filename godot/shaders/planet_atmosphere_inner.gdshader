shader_type spatial;
/* Inner haze shell — camera inside atmosphere looking at horizon.
 * Cull back faces, softer power. Used only when altitude < atmosphere_height.
 */
render_mode unshaded, cull_back, depth_draw_never, blend_mix,
	ambient_light_disabled, shadows_disabled, fog_disabled;

uniform vec4 haze_color : source_color = vec4(0.45, 0.65, 0.95, 0.35);
uniform float intensity : hint_range(0.0, 3.0) = 0.9;
uniform float rim_power : hint_range(0.5, 8.0) = 2.2;
uniform vec3 sun_direction = vec3(0.55, 0.75, 0.35);
uniform float density : hint_range(0.0, 2.0) = 0.7;
uniform float scatter_strength : hint_range(0.0, 2.0) = 0.7;

void fragment() {
	float ndv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndv, rim_power);
	vec3 l = normalize(sun_direction);
	float ndl = clamp(dot(normalize(NORMAL), l), -1.0, 1.0);
	float day = clamp(ndl * 0.5 + 0.5, 0.2, 1.0);
	vec3 rayleigh = mix(haze_color.rgb, vec3(0.4, 0.62, 1.0), 0.35 * scatter_strength);
	float mie = pow(max(ndl, 0.0), 6.0) * scatter_strength;
	vec3 col = mix(rayleigh, vec3(1.0, 0.7, 0.42), mie * 0.45);
	float a = fresnel * density * intensity * day * max(haze_color.a, 0.28);
	ALBEDO = col;
	EMISSION = col * (fresnel * 0.45 + mie * 0.2);
	ALPHA = clamp(a, 0.0, 0.78);
}
