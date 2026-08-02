shader_type canvas_item;

// Soft drifting smoke puff: scrolling noise shaped by a radial falloff.
render_mode blend_mix;

uniform sampler2D fog_noise : hint_default_white, filter_linear, repeat_enable;
uniform vec2 noise_offset = vec2(0.0, 0.0);
uniform float noise_scale : hint_range(0.2, 4.0) = 1.0;
uniform vec4 tint : source_color = vec4(0.76, 0.83, 0.95, 1.0);
uniform float density : hint_range(0.0, 3.0) = 1.0;
uniform float softness : hint_range(0.05, 1.0) = 0.45;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float falloff = pow(clamp(1.0 - length(p), 0.0, 1.0), 1.9);
	float n = texture(fog_noise, UV * noise_scale + noise_offset).r;
	float smoke = clamp(1.0 - n, 0.0, 1.0);
	smoke = smoothstep(0.5 - softness, 0.5 + softness, smoke);
	COLOR = vec4(tint.rgb, tint.a * smoke * falloff * density);
}
