shader_type canvas_item;

// Magitech grid strip: static cyan↔silver gradient + slow traveling bright pulse.
// GLES3-safe (// comments only; no return in fragment).
// Prefer TextureRect + white tex so UV spans the strip (ColorRect UVs are unreliable).
uniform vec4 dim_color : source_color = vec4(0.28, 0.42, 0.52, 1.0);
uniform vec4 mid_color : source_color = vec4(0.55, 0.82, 0.95, 1.0);
uniform vec4 band_color : source_color = vec4(0.92, 0.98, 1.0, 1.0);
uniform float vertical : hint_range(0.0, 1.0) = 0.0;
uniform float speed : hint_range(0.05, 1.5) = 0.18;
uniform float band_width : hint_range(0.04, 0.5) = 0.16;
uniform float phase : hint_range(0.0, 1.0) = 0.0;

varying vec2 v_uv;

void vertex() {
	v_uv = UV;
}

void fragment() {
	float axis = mix(v_uv.x, v_uv.y, step(0.5, vertical));

	// Always-on spatial gradient along the strip (visible even without TIME).
	float arch = sin(axis * 3.14159265);
	arch = arch * arch;
	vec3 base_rgb = mix(dim_color.rgb, mid_color.rgb, arch);
	float base_a = mix(dim_color.a, mid_color.a, arch);

	// Traveling bright pulse (wraps).
	float t = fract(TIME * speed + phase);
	float d = abs(axis - t);
	d = min(d, 1.0 - d);
	float band = 1.0 - smoothstep(0.0, band_width, d);
	band = band * band;

	vec3 rgb = mix(base_rgb, band_color.rgb, band);
	float a = mix(base_a, band_color.a, band * 0.85);
	COLOR = vec4(rgb, a);
}
