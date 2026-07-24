shader_type canvas_item;

/// Full-bar chrome for the equip strip: outer rounded frame + two diagonal dividers.
/// Drawn once on top of the portrait segments so tips join with no gaps / no bleed.

uniform vec2 bar_size = vec2(480.0, 56.0);
uniform float corner_radius = 8.0;
uniform float frame_width : hint_range(0.5, 6.0) = 2.5;
uniform float divider_px : hint_range(0.5, 8.0) = 3.5;
uniform float diagonal_degrees = 70.0;
uniform vec4 frame_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_speed : hint_range(0.0, 2.0) = 0.40;
uniform float rim_pulse : hint_range(0.0, 1.0) = 0.68;
uniform float circuit_patrol : hint_range(0.0, 1.0) = 1.0;

varying vec2 v_pos;

void vertex() {
	v_pos = VERTEX;
}

float sd_round_box(vec2 p, vec2 half_extents, float r) {
	vec2 q = abs(p) - half_extents + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 full = max(bar_size, vec2(1.0));
	vec2 bar_pos = v_pos;
	vec2 bar_half = full * 0.5 - vec2(0.5);
	float r = min(corner_radius, min(bar_half.x, bar_half.y));
	float box_d = sd_round_box(bar_pos - full * 0.5, bar_half, r);
	float aa = max(fwidth(box_d), 0.6);

	// Strictly inside outer path — never draw outside the rounded frame.
	float inside = 1.0 - smoothstep(0.0, aa, box_d);
	float inner = 1.0 - smoothstep(0.0, aa, box_d + frame_width);
	float stroke = clamp(inside - inner, 0.0, 1.0);

	float rad = radians(clamp(diagonal_degrees, 1.0, 89.0));
	float dx_per_dy = cos(rad) / max(sin(rad), 0.001);
	float slant = dx_per_dy * (full.y * 0.5 - bar_pos.y);
	float cut1 = full.x * (1.0 / 3.0) + slant;
	float cut2 = full.x * (2.0 / 3.0) + slant;

	float half_div = max(divider_px * 0.5, 1.0);
	float soft = max(fwidth(bar_pos.x) * 0.75, 0.4);
	float d1 = abs(bar_pos.x - cut1);
	float d2 = abs(bar_pos.x - cut2);
	float div = max(
		1.0 - smoothstep(soft, half_div, d1),
		1.0 - smoothstep(soft, half_div, d2));
	// Diagonals live in the same inside mask as the frame (meet rim, no bleed).
	div *= inside;

	float line_a = max(stroke, div);

	// Circuit patrol on frame + diagonals.
	vec2 centered = bar_pos - full * 0.5;
	float ang = atan(centered.y, centered.x) / 6.2831853 + 0.5;
	float patrol_t = fract(TIME * max(rim_speed * 2.4, 0.001));
	float pd = abs(ang - patrol_t);
	pd = min(pd, 1.0 - pd);
	float band_w = mix(0.05, 0.11, clamp(rim_pulse, 0.0, 1.0));
	float patrol = (1.0 - smoothstep(0.0, band_w, pd)) * clamp(circuit_patrol, 0.0, 1.0);

	float along = fract(bar_pos.y / max(full.y, 1.0) - TIME * max(rim_speed * 1.6, 0.001));
	float ad = min(along, 1.0 - along);
	float diag_patrol = (1.0 - smoothstep(0.0, mix(0.06, 0.14, clamp(rim_pulse, 0.0, 1.0)), ad))
			* clamp(circuit_patrol, 0.0, 1.0) * div;
	float line_patrol = max(patrol * line_a, diag_patrol);

	float pulse = 1.0 + rim_pulse * 0.18 * sin(TIME * 1.4 + ang * 6.2831853);
	vec3 rgb = frame_color.rgb * pulse;
	rgb += frame_color.rgb * line_patrol * (0.85 + rim_pulse * 0.55);

	COLOR = vec4(rgb, line_a * frame_color.a);
}
