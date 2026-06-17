shader_type canvas_item;

// Cone flashlight dim overlay — local pixel coords (UV * overlay_size).
uniform vec2 overlay_size = vec2(1280.0, 720.0);
uniform vec2 beam_origin = vec2(1024.0, 677.0);
uniform vec2 beam_direction = vec2(0.0, -1.0);
uniform float beam_half_angle = 0.42;
uniform float beam_length = 1800.0;
uniform float angular_softness = 0.16;
uniform float length_softness = 96.0;
uniform float dim_alpha = 0.93;
uniform float beam_spread = 1.0;
uniform float origin_glow_radius = 52.0;
uniform float origin_glow_soft = 34.0;
uniform bool use_cone = false;
uniform float circle_radius = 220.0;
uniform float circle_softness = 72.0;

void fragment() {
	vec2 local_px = UV * overlay_size;
	vec2 to_frag = local_px - beam_origin;
	float dist_origin = length(to_frag);

	// Circular beam mode (mouse-follow spotlight).
	float lit_circle = 1.0 - smoothstep(
		circle_radius,
		circle_radius + circle_softness,
		dist_origin);
	lit_circle = lit_circle * lit_circle;

	// Soft lit pool at the flashlight hand (visible even behind the aim axis).
	float lit_pool = 1.0 - smoothstep(
		origin_glow_radius,
		origin_glow_radius + origin_glow_soft,
		dist_origin);
	lit_pool = lit_pool * lit_pool;

	float lit_cone = 0.0;
	float dist_along = dot(to_frag, beam_direction);
	if (dist_along > 0.0 && dot(to_frag, to_frag) > 1.0) {
		vec2 dir_to_frag = normalize(to_frag);
		float cos_ang = clamp(dot(dir_to_frag, beam_direction), -1.0, 1.0);
		float ang = acos(cos_ang);
		float half_ang = beam_half_angle * beam_spread;
		float lit_ang = 1.0 - smoothstep(
			half_ang - angular_softness,
			half_ang + angular_softness,
			ang);
		float lit_len = 1.0 - smoothstep(
			beam_length - length_softness,
			beam_length,
			dist_along);
		lit_cone = lit_ang * lit_len;
		lit_cone = lit_cone * lit_cone;
	}

	float lit = lit_circle;
	if (use_cone) {
		lit = max(lit_pool, lit_cone);
	}
	COLOR = vec4(0.0, 0.0, 0.0, dim_alpha * (1.0 - lit));
}
