shader_type canvas_item;

// Liminal carousel grade: crushed contrast, cold desat, soft vignette.
uniform float contrast : hint_range(0.5, 3.0) = 2.0;
uniform float saturation : hint_range(0.0, 1.5) = 0.38;
uniform float crush_blacks : hint_range(0.0, 0.35) = 0.05;
uniform vec4 grade_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float vignette : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	// COLOR arrives as node modulate (canvas_item has no MODULATE built-in).
	vec4 modc = COLOR;
	vec4 tex = texture(TEXTURE, UV);
	vec3 c = tex.rgb;

	// Mid-gray contrast push.
	c = (c - 0.5) * contrast + 0.5;
	// Crush shadows toward void.
	float keep = max(1.0 - crush_blacks, 0.001);
	c = max(c - crush_blacks, 0.0) / keep;
	c = clamp(c, 0.0, 1.0);

	// Desaturate toward a sickly cool grade.
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(luma), c, saturation);
	c *= grade_tint.rgb;

	// Soft edge vignette (pulls toward black).
	vec2 q = UV * 2.0 - 1.0;
	float vig = smoothstep(1.35, 0.25, length(q * vec2(1.05, 0.95)));
	c *= mix(1.0 - vignette, 1.0, vig);

	COLOR = vec4(clamp(c, 0.0, 1.0), tex.a) * modc;
}
