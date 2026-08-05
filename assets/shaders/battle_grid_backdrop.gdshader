shader_type canvas_item;

// Continuous vertical fill behind a whole battle grid (not per-cell).
uniform vec4 color_top : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.18, 0.18, 0.18, 1.0);

void fragment() {
	COLOR = mix(color_top, color_bottom, UV.y);
}
