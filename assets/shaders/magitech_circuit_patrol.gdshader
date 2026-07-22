shader_type canvas_item;

// Cyan patrol band for Magitech chrome. Idle when active < 0.5.
// GLES3: no `return` in fragment.
uniform float active : hint_range(0.0, 1.0) = 0.0;
uniform float speed : hint_range(0.1, 4.0) = 1.35;
uniform float band_width : hint_range(0.02, 0.55) = 0.16;
uniform float intensity : hint_range(0.0, 3.0) = 1.35;
uniform vec3 glow_color : source_color = vec3(0.45, 0.97, 1.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float lum = max(col.r, max(col.g, col.b));
	float cool = col.b * 0.5 + col.g * 0.35 - col.r * 0.15;
	float mask = mix(0.35, 1.0, smoothstep(0.12, 0.75, lum));
	mask = max(mask, smoothstep(0.0, 0.35, cool) * 0.85);

	float t = fract(TIME * speed);
	float axis = fract(UV.x * 0.72 + UV.y * 0.28);
	float d = abs(axis - t);
	d = min(d, 1.0 - d);
	float band = 1.0 - smoothstep(0.0, band_width, d);

	float on = step(0.5, active) * step(0.02, col.a);
	col.rgb += glow_color * band * mask * intensity * col.a * on;
	COLOR = col;
}
