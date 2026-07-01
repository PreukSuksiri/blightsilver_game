shader_type canvas_item;

// Rounded mask using local vertex coordinates (pixel-space, not UV-space).
// This works correctly regardless of TextureRect stretch mode, including
// STRETCH_KEEP_ASPECT_COVERED where UV != [0,1] across the control quad.
uniform float corner_radius = 8.0;
uniform vec2 rect_size = vec2(100.0, 100.0);

varying vec2 local_pos;

void vertex() {
	// VERTEX is in local canvas-item pixel space: (0,0) at top-left, (W,H) at bottom-right.
	local_pos = VERTEX;
}

void fragment() {
	float r = corner_radius;
	vec2 q = abs(local_pos - rect_size * 0.5) - (rect_size * 0.5 - r);
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;

	COLOR = texture(TEXTURE, UV);
	if (d > 0.0) {
		COLOR.a = 0.0;
	}
}
