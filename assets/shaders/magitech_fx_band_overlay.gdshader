shader_type canvas_item;
render_mode blend_add, unshaded;

// Additive UV band overlay for ColorRect controls.
// GLES3: no `return` in fragment.
uniform float active : hint_range(0.0, 1.0) = 0.0;
uniform float use_time : hint_range(0.0, 1.0) = 1.0;
uniform float progress : hint_range(-0.2, 1.2) = 0.0;
uniform float speed : hint_range(0.1, 4.0) = 1.4;
uniform float band_width : hint_range(0.02, 0.55) = 0.18;
uniform vec4 glow_color : source_color = vec4(0.55, 0.97, 1.0, 0.85);

void fragment() {
	float t = mix(progress, fract(TIME * speed), step(0.5, use_time));
	float axis = fract(UV.x * 0.78 + UV.y * 0.22);
	float d = abs(axis - t);
	d = min(d, 1.0 - d);
	float band = 1.0 - smoothstep(0.0, band_width, d);
	float a = glow_color.a * band * active;
	COLOR = vec4(glow_color.rgb, a);
}
