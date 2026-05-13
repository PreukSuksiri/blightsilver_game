shader_type canvas_item;

// Thin stroke drawn just outside the logo's alpha edge.
uniform vec4  outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.5, 8.0) = 2.0;

void fragment() {
	vec4 texel = texture(TEXTURE, UV);

	if (texel.a > 0.01) {
		// Inside the logo — preserve inherited modulate fade
		COLOR = vec4(texel.rgb, texel.a * COLOR.a);
	} else {
		// Outside the logo — check if any neighbour within outline_width is inside
		float edge = 0.0;
		for (int x = -3; x <= 3; x++) {
			for (int y = -3; y <= 3; y++) {
				float dist = sqrt(float(x * x + y * y));
				if (dist <= outline_width) {
					vec2 off = vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE;
					edge = max(edge, texture(TEXTURE, UV + off).a);
				}
			}
		}
		COLOR = vec4(outline_color.rgb, outline_color.a * edge * COLOR.a);
	}
}
