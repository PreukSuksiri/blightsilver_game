shader_type canvas_item;

// Rounded mask in control pixel space (UV 0–1 across the control quad).
uniform float corner_radius = 8.0;
uniform vec2 rect_size = vec2(100.0, 100.0);

void fragment() {
	vec2 pixel_pos = UV * rect_size;
	float r = corner_radius;
	vec2 q = abs(pixel_pos - rect_size * 0.5) - (rect_size * 0.5 - r);
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;

	COLOR = texture(TEXTURE, UV);
	if (d > 0.0) {
		COLOR.a = 0.0;
	}
}
