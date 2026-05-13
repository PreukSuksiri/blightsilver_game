shader_type canvas_item;

uniform vec4  glow_color    : source_color = vec4(0.72, 0.92, 1.0, 1.0);
uniform float glow_size     : hint_range(1.0, 40.0)  = 14.0;
uniform float glow_strength : hint_range(0.0, 6.0)   = 2.8;

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// 16-sample radial blur to build the glow halo
	float halo = 0.0;
	int   steps = 16;
	for (int i = 0; i < steps; i++) {
		float angle  = float(i) / float(steps) * TAU;
		vec2  offset = vec2(cos(angle), sin(angle)) * glow_size * TEXTURE_PIXEL_SIZE;
		halo += texture(TEXTURE, UV + offset).a;
	}
	halo = (halo / float(steps)) * glow_strength;

	// Only glow where the base pixel is transparent
	float glow_alpha = halo * (1.0 - base.a);
	vec3  glow_rgb   = glow_color.rgb * glow_alpha;

	COLOR.rgb = base.rgb + glow_rgb;
	COLOR.a   = max(base.a, glow_alpha * glow_color.a);
}
