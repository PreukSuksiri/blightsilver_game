shader_type canvas_item;

// Magitech dialog button fill + border in pixel space (aspect-correct).
// GLES3-safe (no return in fragment).
uniform vec2 rect_size = vec2(140.0, 40.0);
uniform vec4 fill_top : source_color = vec4(0.10, 0.18, 0.36, 0.97);
uniform vec4 fill_bottom : source_color = vec4(0.05, 0.10, 0.22, 0.97);
uniform vec4 border_a : source_color = vec4(0.45, 0.85, 1.0, 0.80);
uniform vec4 border_b : source_color = vec4(0.70, 0.78, 0.90, 0.70);
uniform float border_px : hint_range(0.5, 6.0) = 1.5;
uniform float corner_radius_px : hint_range(0.0, 24.0) = 8.0;
uniform float brightness : hint_range(0.5, 1.6) = 1.0;

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

	vec4 fill = mix(fill_top, fill_bottom, UV.y) * vec4(vec3(brightness), 1.0);
	// Soft rim along the top edge, not a left→right cyan sweep.
	vec4 rim = mix(border_b, border_a, 1.0 - UV.y);

	vec4 col = fill;
	col = mix(col, rim, edge);
	col.a *= inside;
	COLOR = col;
}
