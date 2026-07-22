shader_type canvas_item;

// Subtle Magitech message-box fill + border. GLES3-safe (no return in fragment).
uniform vec4 fill_top : source_color = vec4(0.06, 0.09, 0.16, 0.97);
uniform vec4 fill_bottom : source_color = vec4(0.02, 0.03, 0.07, 0.97);
uniform vec4 border_a : source_color = vec4(0.55, 0.90, 1.0, 0.85);
uniform vec4 border_b : source_color = vec4(0.75, 0.82, 0.92, 0.75);
uniform float border_width : hint_range(0.005, 0.08) = 0.018;
uniform float corner_radius : hint_range(0.0, 0.25) = 0.06;
uniform float rim_speed : hint_range(0.0, 2.0) = 0.22;
uniform float rim_pulse : hint_range(0.0, 1.0) = 0.35;

float rounded_box(vec2 uv, float radius) {
	vec2 p = uv * 2.0 - 1.0;
	vec2 b = vec2(1.0 - radius);
	vec2 q = abs(p) - b;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	float dist = rounded_box(UV, corner_radius);
	float inside = 1.0 - smoothstep(0.0, 0.01, dist);
	float edge = 1.0 - smoothstep(-border_width, 0.0, dist);
	edge *= smoothstep(-border_width * 2.2, -border_width * 0.35, dist);

	vec4 fill = mix(fill_top, fill_bottom, UV.y);
	float rim_t = fract(TIME * rim_speed + UV.x * 0.65 + UV.y * 0.35);
	vec4 rim = mix(border_a, border_b, rim_t);
	float pulse = 1.0 + rim_pulse * 0.25 * sin(TIME * 1.4 + UV.x * 6.0);

	vec4 col = fill;
	col = mix(col, rim * pulse, clamp(edge, 0.0, 1.0));
	col.a *= inside;
	COLOR = col;
}
