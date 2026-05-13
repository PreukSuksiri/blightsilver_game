shader_type canvas_item;

uniform float corner_radius = 8.0;

void fragment() {
	vec2 size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
	vec2 pixel_pos = UV * size;
	float r = corner_radius;

	vec2 q = abs(pixel_pos - size * 0.5) - (size * 0.5 - r);
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;

	COLOR = texture(TEXTURE, UV);
	if (d > 0.0) {
		COLOR.a = 0.0;
	}
}
