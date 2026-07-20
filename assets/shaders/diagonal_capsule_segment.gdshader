shader_type canvas_item;

/// Segment of ONE long rounded-rectangle sheet.
/// role: 0 = left (+ right diagonal), 1 = middle, 2 = right (+ left diagonal).

uniform int role = 0;
/// Cut angle from horizontal, in degrees (70 = steep slash).
uniform float diagonal_degrees = 70.0;
uniform float gap = 0.10;
uniform float corner_radius = 8.0;
uniform vec2 rect_size = vec2(160.0, 56.0);
uniform vec2 bar_size = vec2(480.0, 56.0); // full sheet size (all 3 segments)
uniform float segment_x = 0.0; // this segment's left edge in bar local X
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 frame_color : source_color = vec4(0.15, 0.92, 0.95, 1.0);
uniform float frame_width = 2.0;
uniform float edge_glow = 0.0;

varying vec2 v_pos;

void vertex() {
	v_pos = VERTEX;
}

float sd_round_box(vec2 p, vec2 half_extents, float r) {
	vec2 q = abs(p) - half_extents + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 seg_size = max(rect_size, vec2(1.0));
	vec2 full = max(bar_size, seg_size);
	vec2 uv = clamp(v_pos / seg_size, vec2(0.0), vec2(1.0));

	// Position in the full rounded-rectangle sheet.
	vec2 bar_pos = vec2(segment_x + v_pos.x, v_pos.y);
	vec2 bar_half = full * 0.5 - vec2(1.0);
	float r = min(corner_radius, min(bar_half.x, bar_half.y));
	float box_d = sd_round_box(bar_pos - full * 0.5, bar_half, r);
	float aa_box = max(fwidth(box_d), 0.75);
	float box_inside = 1.0 - smoothstep(0.0, aa_box, box_d);
	float box_inner = 1.0 - smoothstep(0.0, aa_box, box_d + frame_width);
	float box_stroke = clamp(box_inside - box_inner, 0.0, 1.0);

	// 70° (etc.) from horizontal → UV slant for this segment's aspect.
	float rad = radians(clamp(diagonal_degrees, 1.0, 89.0));
	float dx_per_dy = cos(rad) / max(sin(rad), 0.001); // cot(θ)
	float slant_uv = (dx_per_dy * seg_size.y) / max(seg_size.x, 1.0);

	float shift = slant_uv * (0.5 - uv.y);
	float right_edge = 1.0 + shift - gap * 0.5;
	float left_edge = 0.0 + shift + gap * 0.5;
	float aa = fwidth(uv.x) * 1.5 + 0.002;
	float seg_mask = 1.0;
	float edge_line = 0.0;

	if (role == 0) {
		seg_mask *= 1.0 - smoothstep(right_edge - aa, right_edge + aa, uv.x);
		edge_line = 1.0 - smoothstep(0.0, 0.02, abs(uv.x - right_edge));
	} else if (role == 2) {
		seg_mask *= smoothstep(left_edge - aa, left_edge + aa, uv.x);
		edge_line = 1.0 - smoothstep(0.0, 0.02, abs(uv.x - left_edge));
	} else {
		seg_mask *= smoothstep(left_edge - aa, left_edge + aa, uv.x);
		seg_mask *= 1.0 - smoothstep(right_edge - aa, right_edge + aa, uv.x);
		edge_line = max(
			1.0 - smoothstep(0.0, 0.02, abs(uv.x - left_edge)),
			1.0 - smoothstep(0.0, 0.02, abs(uv.x - right_edge)));
	}

	float mask = box_inside * seg_mask;

	vec4 tex = texture(TEXTURE, UV);
	vec3 art = tex.rgb * tint.rgb;
	float art_a = tex.a * tint.a;
	vec3 rgb = mix(fill_color.rgb, art, art_a);

	float glow = clamp(edge_glow, 0.0, 1.0);
	vec3 accent = mix(frame_color.rgb, frame_color.rgb * 1.15, glow * 0.5);
	float stroke_a = box_stroke * mix(frame_color.a, 1.0, glow * 0.35) * seg_mask;
	float cut_a = edge_line * (0.4 + glow * 0.45) * box_inside;
	rgb = mix(rgb, accent, clamp(max(stroke_a, cut_a * 0.65), 0.0, 0.9));

	COLOR = vec4(rgb, mask);
}
