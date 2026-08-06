shader_type canvas_item;

// Noise dissolve fade-in for Labels / canvas text.
// progress 0 = fully dissolved (invisible), 1 = fully materialised.

uniform sampler2D fog_noise : hint_default_white, filter_linear, repeat_enable;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.02, 0.6) = 0.22;
uniform float noise_scale : hint_range(0.4, 10.0) = 3.2;
uniform vec2 noise_scroll = vec2(0.0, 0.0);

void fragment() {
	vec4 col = COLOR;
	float n = texture(fog_noise, UV * noise_scale + noise_scroll).r;
	float p = clamp(progress, 0.0, 1.0);
	float soft = max(softness, 0.02);
	// Low-noise blotches appear first as progress rises.
	float mask = smoothstep(n - soft, n + soft * 0.35, p);
	// Soft overall lift so the last wisps don't linger too long.
	mask *= smoothstep(0.0, 0.18, p);
	col.a *= mask;
	COLOR = col;
}
