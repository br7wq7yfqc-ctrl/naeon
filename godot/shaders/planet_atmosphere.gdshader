shader_type spatial;
/* NAEON planet atmosphere — limb/fresnel shell (space & approach).
 * Cost: 1 transparent sphere, no raymarch. Safe on RTX 1060 3GB.
 * Not a full Bruneton multiple-scattering model (see docs).
 */
render_mode unshaded, cull_front, depth_draw_never, blend_mix,
	ambient_light_disabled, shadows_disabled, fog_disabled;

uniform vec4 atmosphere_color : source_color = vec4(0.30, 0.55, 0.95, 0.55);
uniform float intensity : hint_range(0.0, 4.0) = 1.35;
uniform float rim_power : hint_range(0.5, 12.0) = 3.8;
uniform float density : hint_range(0.0, 2.0) = 0.95;
uniform float night_floor : hint_range(0.0, 0.5) = 0.12;
uniform vec3 sun_direction = vec3(0.55, 0.75, 0.35);
/* 0 = soft day/night on rim, 1 = full day always */
uniform float sun_influence : hint_range(0.0, 1.0) = 0.85;
/* Horizon boost when camera closer (set from script by altitude) */
uniform float horizon_boost : hint_range(0.0, 2.0) = 0.0;
uniform float alpha_max : hint_range(0.0, 1.0) = 0.85;

varying vec3 v_world_normal;

void vertex() {
	v_world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	// VIEW is toward camera in view space; NORMAL is view-space for default mesh.
	float ndv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndv, rim_power);

	vec3 n_world = normalize(v_world_normal);
	vec3 l = normalize(sun_direction);
	float day = mix(night_floor, 1.0, clamp(dot(n_world, l) * 0.5 + 0.5, 0.0, 1.0));
	day = mix(1.0, day, sun_influence);

	// Thin limb + slight fill so disk is not a hard ring only
	float limb = fresnel * density;
	float fill = pow(fresnel, max(rim_power * 0.45, 1.0)) * 0.25;
	float a = (limb + fill + horizon_boost * fresnel * 0.5) * intensity * day * atmosphere_color.a;
	a = clamp(a, 0.0, alpha_max);

	ALBEDO = atmosphere_color.rgb;
	EMISSION = atmosphere_color.rgb * (limb * 0.65 + horizon_boost * 0.2);
	ALPHA = a;
}
