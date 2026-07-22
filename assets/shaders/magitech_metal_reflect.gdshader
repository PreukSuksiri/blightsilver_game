shader_type canvas_item;

// One-shot left→right metal sheen. Drive progress from 0→1 then leave at 1 (no shine).
// GLES3: no `return` in fragment — use alpha mask instead.
uniform float progress : hint_range(-0.2, 2.5) = 2.0;
uniform float band_width : hint_range(0.05, 0.5) = 0.22;
uniform float intensity : hint_range(0.0, 2.5) = 1.2;
uniform vec3 shine_color : source_color = vec3(0.92, 0.98, 1.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float d = abs(UV.x - progress);
	float shine = 1.0 - smoothstep(0.0, band_width, d);
	// Only where art is visible (transparent pixels get zero add).
	float visible = step(0.04, col.a);
	col.rgb += shine_color * shine * intensity * col.a * visible;
	COLOR = col;
}
