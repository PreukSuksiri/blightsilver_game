shader_type canvas_item;

// A soft directional shadow that makes dark logos readable on dark backgrounds.
uniform vec4  shadow_color    : source_color = vec4(0.55, 0.85, 1.0, 1.0);
uniform float shadow_offset_x : hint_range(-20.0, 20.0) = 3.0;
uniform float shadow_offset_y : hint_range(-20.0, 20.0) = 4.0;
uniform float shadow_spread   : hint_range(0.0, 24.0)   = 9.0;
uniform float shadow_strength : hint_range(0.0, 4.0)    = 2.2;

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// 12-sample soft shadow — offset + radial spread combined
	float shadow = 0.0;
	int steps = 12;
	for (int i = 0; i < steps; i++) {
		float angle  = float(i) / float(steps) * TAU;
		vec2  spread = vec2(cos(angle), sin(angle)) * shadow_spread;
		vec2  dir    = vec2(shadow_offset_x, shadow_offset_y);
		vec2  offset = (spread + dir) * TEXTURE_PIXEL_SIZE;
		shadow += texture(TEXTURE, UV + offset).a;
	}
	shadow  = (shadow / float(steps)) * shadow_strength;
	shadow *= (1.0 - base.a);   // only bleeds into transparent areas

	COLOR.rgb = base.rgb + shadow_color.rgb * shadow;
	COLOR.a   = max(base.a, shadow * shadow_color.a);
}
