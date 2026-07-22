shader_type canvas_item;

// Subtle Magitech dialog button fill + border. GLES3-safe (no return in fragment).
uniform vec4 fill_top : source_color = vec4(0.10, 0.18, 0.36, 0.97);
uniform vec4 fill_bottom : source_color = vec4(0.05, 0.10, 0.22, 0.97);
uniform vec4 border_a : source_color = vec4(0.45, 0.85, 1.0, 0.80);
uniform vec4 border_b : source_color = vec4(0.70, 0.78, 0.90, 0.70);
uniform float border_width : hint_range(0.01, 0.12) = 0.045;
uniform float corner_radius : hint_range(0.0, 0.4) = 0.12;
uniform float brightness : hint_range(0.5, 1.6) = 1.0;

float rounded_box(vec2 uv, float radius) {
	vec2 p = uv * 2.0 - 1.0;
	vec2 b = vec2(1.0 - radius);
	vec2 q = abs(p) - b;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	float dist = rounded_box(UV, corner_radius);
	float inside = 1.0 - smoothstep(0.0, 0.012, dist);
	float edge = 1.0 - smoothstep(-border_width, 0.0, dist);
	edge *= smoothstep(-border_width * 2.0, -border_width * 0.3, dist);

	vec4 fill = mix(fill_top, fill_bottom, UV.y) * vec4(vec3(brightness), 1.0);
	vec4 rim = mix(border_a, border_b, UV.x);

	vec4 col = fill;
	col = mix(col, rim, clamp(edge, 0.0, 1.0));
	col.a *= inside;
	COLOR = col;
}
