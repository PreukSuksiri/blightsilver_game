shader_type canvas_item;

## One-shot left→right metal sheen. Drive `progress` from 0→1 then leave at 1 (no shine).
uniform float progress : hint_range(-0.2, 1.2) = 1.2;
uniform float band_width : hint_range(0.05, 0.5) = 0.18;
uniform float intensity : hint_range(0.0, 2.0) = 0.75;
uniform vec3 shine_color : source_color = vec3(0.85, 0.95, 1.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float d = abs(UV.x - progress);
	float shine = 1.0 - smoothstep(0.0, band_width, d);
	col.rgb += shine_color * shine * intensity * col.a;
	COLOR = col;
}
