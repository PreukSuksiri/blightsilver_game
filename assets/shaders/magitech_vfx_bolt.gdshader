shader_type canvas_item;
render_mode blend_mix, unshaded;

// Electric jolt streak: textured bolt + fast traveling bright pulse.
// GLES3-safe (// comments only; no return in fragment).
// TEXTURE alpha defines the bolt shape; tint/pulse stay translucent.
uniform vec4 tint : source_color = vec4(0.55, 0.95, 1.0, 1.0);
uniform vec4 band_color : source_color = vec4(0.95, 0.99, 1.0, 1.0);
uniform float speed : hint_range(0.5, 10.0) = 3.8;
uniform float band_width : hint_range(0.04, 0.55) = 0.20;
uniform float phase : hint_range(0.0, 1.0) = 0.0;
uniform float vertical : hint_range(0.0, 1.0) = 1.0;
uniform float base_alpha : hint_range(0.15, 1.0) = 0.62;
uniform float pulse_boost : hint_range(0.0, 1.5) = 0.90;

varying vec2 v_uv;

void vertex() {
	v_uv = UV;
}

void fragment() {
	vec4 tex = texture(TEXTURE, v_uv);
	float shape_a = tex.a;

	float axis = mix(v_uv.x, v_uv.y, step(0.5, vertical));
	float t = fract(TIME * speed + phase);
	float d = abs(axis - t);
	d = min(d, 1.0 - d);
	float band = 1.0 - smoothstep(0.0, band_width, d);
	band = band * band;

	vec3 rgb = mix(tint.rgb * tex.rgb, band_color.rgb, band * pulse_boost);
	float a = shape_a * base_alpha * tint.a;
	a = mix(a, min(1.0, a + 0.28), band);
	// COLOR carries Control.modulate (incl. fade-out tweens).
	COLOR = vec4(rgb, a) * COLOR;
}
