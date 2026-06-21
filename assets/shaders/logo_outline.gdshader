shader_type canvas_item;

// Thin stroke drawn just outside the logo's alpha edge.
uniform vec4  outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.5, 32.0) = 2.0;
// When false, the outline stays fully opaque while modulate fades the icon fill.
uniform bool  outline_fade_with_modulate = true;

void fragment() {
	vec4 texel = texture(TEXTURE, UV);

	if (texel.a > 0.01) {
		// Inside the logo — preserve inherited modulate fade
		COLOR = vec4(texel.rgb, texel.a * COLOR.a);
	} else {
		// Outside the logo — check neighbours within outline_width (texture pixels)
		float edge = 0.0;
		int radius = int(ceil(outline_width));
		if (radius > 32) {
			radius = 32;
		}
		for (int x = -32; x <= 32; x++) {
			if (abs(x) > radius) {
				continue;
			}
			for (int y = -32; y <= 32; y++) {
				if (abs(y) > radius) {
					continue;
				}
				float dist = sqrt(float(x * x + y * y));
				if (dist <= outline_width) {
					vec2 off = vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE;
					edge = max(edge, texture(TEXTURE, UV + off).a);
				}
			}
		}
		float outline_a = outline_color.a * edge;
		if (outline_fade_with_modulate) {
			outline_a *= COLOR.a;
		}
		COLOR = vec4(outline_color.rgb, outline_a);
	}
}
