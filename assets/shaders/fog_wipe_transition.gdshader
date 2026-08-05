shader_type canvas_item;

// Soft fog wipe for scene handoffs. Solid black advances along a diagonal;
// the leading edge is a long animated fog tail (scrolling dual-noise tendrils)
// instead of a hard geometric box / checkerboard.

render_mode blend_mix;

uniform sampler2D fog_noise : hint_default_white, filter_linear, repeat_enable;
// 0 = fully clear, 1 = fully covered
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Soft leading edge length as a fraction of the diagonal (keep long / atmospheric)
uniform float fog_tail : hint_range(0.15, 1.2) = 0.85;
uniform vec2 scroll_a = vec2(0.0, 0.0);
uniform vec2 scroll_b = vec2(0.0, 0.0);
uniform float noise_scale_a : hint_range(0.4, 6.0) = 2.4;
uniform float noise_scale_b : hint_range(0.4, 6.0) = 1.15;
uniform float fog_contrast : hint_range(0.0, 0.5) = 0.22;
uniform float tendril : hint_range(0.0, 1.0) = 0.72;
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	// Diagonal axis: top-left (0) → bottom-right (1), matching the old wipe direction.
	float d = (UV.x + UV.y) * 0.5;

	vec2 nuv_a = UV * noise_scale_a + scroll_a;
	vec2 nuv_b = UV * noise_scale_b * vec2(1.35, 0.85) - scroll_b;
	float n1 = texture(fog_noise, nuv_a).r;
	float n2 = texture(fog_noise, nuv_b).r;
	// Invert so bright noise = denser smoke (matches playmat fog convention).
	float smoke = clamp((1.0 - n1) * 0.62 + (1.0 - n2) * 0.55, 0.0, 1.0);
	smoke = smoothstep(fog_contrast, 1.0 - fog_contrast * 0.35, smoke);

	float p = clamp(progress, 0.0, 1.0);
	float tail = max(fog_tail, 0.05);
	// At p=0 front sits before the screen; at p=1 solid has fully crossed.
	float cover_pos = mix(-tail, 1.0, p);

	// Positive = still ahead of the solid front (toward uncovered area).
	float ahead = d - cover_pos;
	// Noise pulls wispy tendrils far into the clear zone.
	float jagged = ahead - (smoke - 0.42) * tail * tendril;

	// Deep cover behind the front stays fully opaque.
	float solid = 1.0 - smoothstep(-tail * 0.28, tail * 0.04, ahead);
	// Long soft mist ahead of the solid body.
	float mist = 1.0 - smoothstep(0.0, tail, jagged);
	mist *= mix(0.12, 1.0, smoke);

	float alpha = clamp(max(solid, mist), 0.0, 1.0);
	COLOR = vec4(tint.rgb, tint.a * alpha);
}
