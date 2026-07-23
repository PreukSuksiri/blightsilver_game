shader_type canvas_item;

// Digital readout glitch: scrolling cyan↔amber gradient + alpha flicker.
// intensity 0 = normal glyph; 1 = full glitch treatment.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float scroll_speed : hint_range(0.5, 40.0) = 14.0;
uniform float flicker_speed : hint_range(1.0, 80.0) = 28.0;
uniform vec4 color_cool : source_color = vec4(0.20, 1.00, 0.88, 1.0);
uniform vec4 color_hot : source_color = vec4(1.00, 0.42, 0.28, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float band = fract(UV.x * 1.8 + UV.y * 0.55 - TIME * scroll_speed * 0.08);
	vec3 grad = mix(color_cool.rgb, color_hot.rgb, band);
	// Soft mid highlight so digits stay readable.
	grad = mix(grad, vec3(0.95, 0.98, 1.0), 0.22 * sin(band * TAU));

	float flick = 0.40 + 0.60 * abs(sin(TIME * flicker_speed + UV.y * 18.0));
	flick *= 0.55 + 0.45 * abs(sin(TIME * flicker_speed * 1.7));
	// Occasional hard dropouts.
	float drop = step(0.88, fract(sin(floor(TIME * 40.0) * 12.9898 + floor(UV.y * 16.0)) * 43758.5453));
	flick = mix(flick, 0.12, drop);

	float a = tex.a * mix(1.0, flick, intensity);
	vec3 rgb = mix(tex.rgb, grad * tex.a, intensity);
	COLOR = vec4(rgb, a);
}
