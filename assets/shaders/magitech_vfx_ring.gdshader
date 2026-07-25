shader_type canvas_item;
render_mode blend_add, unshaded;

/// Kenney ring sprite + radial color gradient (inner → mid → outer).
/// TEXTURE alpha defines the ring shape; COLOR carries Control.modulate fade.

uniform vec4 color_inner : source_color = vec4(0.55, 0.98, 1.0, 1.0);
uniform vec4 color_mid : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_outer : source_color = vec4(0.35, 0.55, 1.0, 1.0);
uniform float mid_stop : hint_range(0.15, 0.85) = 0.45;
uniform float intensity : hint_range(0.2, 2.5) = 1.15;

varying vec2 v_uv;

void vertex() {
	v_uv = UV;
}

void fragment() {
	vec4 tex = texture(TEXTURE, v_uv);
	float shape_a = tex.a;
	float r = length(v_uv - vec2(0.5)) * 2.0;
	float t = clamp(r, 0.0, 1.0);
	float m = clamp(mid_stop, 0.05, 0.95);
	vec3 grad;
	if (t < m) {
		grad = mix(color_inner.rgb, color_mid.rgb, t / m);
	} else {
		grad = mix(color_mid.rgb, color_outer.rgb, (t - m) / max(1.0 - m, 0.001));
	}
	float a = shape_a * intensity;
	COLOR = vec4(grad, a) * COLOR;
}
