shader_type canvas_item;

// Slow churning shadow behind an omen capsule: two noise layers scrolling in
// opposite directions, shaped by a radial falloff with a softened core so the
// capsule's own halo still reads on top.
render_mode blend_mix;

uniform sampler2D fog_noise : hint_default_white, filter_linear, repeat_enable;
uniform vec2 scroll_a = vec2(0.0, 0.0);
uniform vec2 scroll_b = vec2(0.0, 0.0);
uniform float scale_a : hint_range(0.2, 4.0) = 1.15;
uniform float scale_b : hint_range(0.2, 4.0) = 0.68;
uniform vec4 tint : source_color = vec4(0.01, 0.01, 0.02, 1.0);
uniform float density : hint_range(0.0, 3.0) = 1.0;
uniform float edge_softness : hint_range(0.5, 4.0) = 1.35;
uniform float core_relief : hint_range(0.0, 1.0) = 0.22;
uniform float contrast : hint_range(0.0, 1.0) = 0.16;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float r = length(p);
	// Flat through the body, then a soft outer edge — a plain pow() falloff puts
	// all the density behind the capsule where it can't be seen.
	float falloff = smoothstep(1.0, mix(0.65, 0.25, clamp(edge_softness / 4.0, 0.0, 1.0)), r);

	float n1 = texture(fog_noise, UV * scale_a + scroll_a).r;
	float n2 = texture(fog_noise, UV * scale_b - scroll_b).r;
	float smoke = clamp((1.0 - n1) * 0.70 + (1.0 - n2) * 0.70, 0.0, 1.0);
	smoke = smoothstep(contrast, 1.0 - contrast * 0.4, smoke);
	// Floor keeps a continuous pool of shadow between the noise tendrils.
	smoke = max(smoke, 0.45);

	// Thin the very centre so the disc doesn't sit on a flat black plate.
	float core = mix(1.0 - core_relief, 1.0, smoothstep(0.18, 0.62, r));

	COLOR = vec4(tint.rgb, tint.a * smoke * falloff * core * density);
}
