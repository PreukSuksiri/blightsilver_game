shader_type canvas_item;

// Magitech dialog panel fill + border in pixel space (aspect-correct).
// GLES3-safe (no return in fragment).
uniform vec2 rect_size = vec2(480.0, 280.0);
uniform vec4 fill_top : source_color = vec4(0.06, 0.09, 0.16, 0.97);
uniform vec4 fill_bottom : source_color = vec4(0.02, 0.03, 0.07, 0.97);
uniform vec4 border_a : source_color = vec4(0.55, 0.90, 1.0, 0.85);
uniform vec4 border_b : source_color = vec4(0.75, 0.82, 0.92, 0.75);
uniform float border_px : hint_range(0.5, 6.0) = 2.0;
uniform float corner_radius_px : hint_range(0.0, 24.0) = 8.0;
uniform float rim_speed : hint_range(0.0, 2.0) = 0.22;
uniform float rim_pulse : hint_range(0.0, 1.0) = 0.35;
uniform float circuit_patrol : hint_range(0.0, 1.0) = 1.0;

float sd_rounded_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + vec2(r);
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 size = max(rect_size, vec2(1.0));
	vec2 half_size = size * 0.5;
	float r = min(corner_radius_px, min(half_size.x, half_size.y));
	vec2 p = (UV - 0.5) * size;
	float dist = sd_rounded_box(p, half_size, r);

	float aa = max(fwidth(dist), 0.75);
	float inside = 1.0 - smoothstep(0.0, aa, dist);
	float inner = 1.0 - smoothstep(0.0, aa, dist + border_px);
	float edge = clamp(inside - inner, 0.0, 1.0);

	vec4 fill = mix(fill_top, fill_bottom, UV.y);
	float rim_t = fract(TIME * rim_speed + UV.x * 0.65 + UV.y * 0.35);
	vec4 rim = mix(border_a, border_b, rim_t);
	float pulse = 1.0 + rim_pulse * 0.18 * sin(TIME * 1.4 + UV.x * 6.0);

	// Circuit patrol: bright hotspot travels around the frame edge.
	float ang = atan(p.y, p.x) / 6.2831853 + 0.5;
	float patrol_t = fract(TIME * max(rim_speed * 2.4, 0.001));
	float pd = abs(ang - patrol_t);
	pd = min(pd, 1.0 - pd);
	float band_w = mix(0.05, 0.11, clamp(rim_pulse, 0.0, 1.0));
	float patrol = (1.0 - smoothstep(0.0, band_w, pd)) * clamp(circuit_patrol, 0.0, 1.0);
	rim.rgb += border_a.rgb * patrol * (0.75 + rim_pulse * 0.55);

	vec4 col = fill;
	col = mix(col, rim * pulse, edge);
	col.a *= inside;
	COLOR = col;
}
