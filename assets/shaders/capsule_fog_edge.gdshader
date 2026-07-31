shader_type canvas_item;

// Soft fog-edge dissolve on capsule portraits. Outer rim punches art to
// transparent via scrolling noise (gallery grey smoke shows through).
// Center stays opaque. Drive `relief` 0→1 to clear the fringe.
// use_vertex_color: 0 = portrait (raw texture), 1 = dim ColorRect (tex × COLOR).

render_mode blend_mix;

uniform vec2 rect_size = vec2(180.0, 260.0);
uniform float corner_radius = 4.0;
uniform float fog_width : hint_range(0.0, 64.0) = 36.0;
uniform float fog_strength : hint_range(0.0, 2.0) = 1.35;
uniform vec2 scroll = vec2(0.0, 0.0);
uniform float relief : hint_range(0.0, 1.0) = 0.0;
uniform float use_vertex_color : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D fog_noise : hint_default_white, filter_linear, repeat_enable;

// Metal sheen (idle progress ≈ 2.0 = off)
uniform float progress : hint_range(-0.2, 2.5) = 2.0;
uniform float band_width : hint_range(0.05, 0.5) = 0.20;
uniform float intensity : hint_range(0.0, 2.5) = 1.2;
uniform vec3 shine_color : source_color = vec3(0.92, 0.98, 1.0);

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Portraits must NOT multiply by COLOR (can crush contrast). Dim overlays do.
	vec4 col = mix(tex, tex * COLOR, use_vertex_color);

	vec2 rs = max(rect_size, vec2(1.0));
	float r = max(corner_radius, 0.0);
	vec2 half_size = rs * 0.5;
	vec2 q = abs(local_pos - half_size) - (half_size - vec2(r));
	float sdf = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;

	float aa = max(fwidth(sdf), 0.75);
	float inside = 1.0 - smoothstep(-aa, aa, sdf);

	float dist_edge = min(
		min(local_pos.x, rs.x - local_pos.x),
		min(local_pos.y, rs.y - local_pos.y)
	);

	float clear = smoothstep(0.0, 1.0, clamp(relief, 0.0, 1.0));
	float width = max(fog_width * (1.0 - clear * clear), 0.001);
	float edge = 1.0 - smoothstep(0.0, width, dist_edge);

	vec2 nuv = local_pos / rs * vec2(2.6, 3.4) + scroll;
	float n = texture(fog_noise, nuv).r;
	float smoke = clamp(1.0 - n, 0.0, 1.0);

	float fringe = edge * mix(0.45, 1.0, smoke) * fog_strength * (1.0 - clear);
	fringe = clamp(fringe, 0.0, 1.0);
	float keep = 1.0 - fringe;

	col.a *= keep * inside;

	float shine = 1.0 - smoothstep(0.0, band_width, abs(UV.x - progress));
	float visible = step(0.04, col.a);
	col.rgb += shine_color * shine * intensity * col.a * visible;

	COLOR = col;
}
