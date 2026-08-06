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

void fragment() {
	float ndv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndv, rim_power);
	float day = clamp(dot(normalize(NORMAL), normalize(sun_direction)) * 0.5 + 0.5, 0.2, 1.0);
	float a = fresnel * density * intensity * day * haze_color.a;
	ALBEDO = haze_color.rgb;
	EMISSION = haze_color.rgb * fresnel * 0.4;
	ALPHA = clamp(a, 0.0, 0.75);
}
