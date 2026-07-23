shader_type canvas_item;
render_mode blend_add, unshaded;

// Soft white spotlight cone (origin at bottom center of the rect).
// GLES3-safe (no return in fragment).
uniform float intensity : hint_range(0.0, 2.0) = 0.55;
uniform float core_width : hint_range(0.02, 0.5) = 0.10;
uniform float tip_width : hint_range(0.1, 1.2) = 0.55;
uniform vec4 beam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// UV: (0,0) top-left → (1,1) bottom-right. Cone grows upward from bottom.
	float t = 1.0 - UV.y;
	float half_w = mix(core_width, tip_width, t);
	float d = abs(UV.x - 0.5) / max(half_w, 0.001);
	float beam = 1.0 - smoothstep(0.0, 1.0, d);
	beam *= beam;
	// Soften tip and root a bit.
	beam *= smoothstep(0.0, 0.12, t) * smoothstep(1.05, 0.55, t);
	float a = beam * intensity * beam_color.a;
	COLOR = vec4(beam_color.rgb, a);
}
