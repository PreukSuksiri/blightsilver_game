shader_type canvas_item;

/// Portrait fill for one segment of the equip strip.
/// Frame + diagonal dividers are drawn by diagonal_capsule_chrome.gdshader on top.

uniform int role = 0;
uniform float diagonal_degrees = 70.0;
uniform float gap = 0.0;
/// Match chrome divider width so the fill stops just under the white slash.
uniform float divider_px : hint_range(0.5, 8.0) = 3.5;
uniform float corner_radius = 8.0;
uniform vec2 rect_size = vec2(160.0, 56.0);
uniform vec2 bar_size = vec2(480.0, 56.0);
uniform float segment_x = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float frame_width = 2.5;
uniform float edge_glow = 0.0;
uniform float desaturate : hint_range(0.0, 1.0) = 0.0;
uniform vec3 sepia_color : source_color = vec3(0.78, 0.64, 0.42);
uniform float sepia_mix : hint_range(0.0, 1.0) = 0.0;
uniform float sheen_progress : hint_range(-0.2, 2.5) = 2.0;
uniform float sheen_band : hint_range(0.05, 0.5) = 0.22;
uniform float sheen_intensity : hint_range(0.0, 2.5) = 1.25;
uniform vec3 sheen_color : source_color = vec3(1.0, 0.96, 0.82);
uniform float bevel_strength : hint_range(0.0, 1.0) = 0.55;
/// Uniform zoom > 1 enlarges art from the top-right pivot toward bottom-left.
uniform float art_zoom : hint_range(1.0, 1.35) = 1.0;

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
	vec2 bar_pos = vec2(segment_x + v_pos.x, v_pos.y);
	vec2 bar_half = full * 0.5 - vec2(0.5);
	float r = min(corner_radius, min(bar_half.x, bar_half.y));
	float box_d = sd_round_box(bar_pos - full * 0.5, bar_half, r);
	float aa_box = max(fwidth(box_d), 0.6);
	// Fill the full outer rounded rect so art sits under chrome rim + diagonals.
	float fill_inside = 1.0 - smoothstep(0.0, aa_box, box_d);

	float rad = radians(clamp(diagonal_degrees, 1.0, 89.0));
	float dx_per_dy = cos(rad) / max(sin(rad), 0.001);
	float slant = dx_per_dy * (full.y * 0.5 - bar_pos.y);
	float cut1 = full.x * (1.0 / 3.0) + slant;
	float cut2 = full.x * (2.0 / 3.0) + slant;
	float aa_px = max(fwidth(bar_pos.x), 0.5);
	float g_px = max(gap, 0.0) * 0.5 * (full.x / 3.0);
	// Tiny underlap past the cut so chrome slash covers the join (no black tip wedge).
	float inset = -aa_px;

	float seg_mask = 1.0;
	if (role == 0) {
		float edge = cut1 - g_px - inset;
		seg_mask *= 1.0 - smoothstep(edge - aa_px, edge + aa_px, bar_pos.x);
	} else if (role == 2) {
		float edge = cut2 + g_px + inset;
		seg_mask *= smoothstep(edge - aa_px, edge + aa_px, bar_pos.x);
	} else {
		float left_e = cut1 + g_px + inset;
		float right_e = cut2 - g_px - inset;
		seg_mask *= smoothstep(left_e - aa_px, left_e + aa_px, bar_pos.x);
		seg_mask *= 1.0 - smoothstep(right_e - aa_px, right_e + aa_px, bar_pos.x);
	}

	float mask = fill_inside * seg_mask;

	// Enlarge slightly, anchored at top-right (grows toward bottom-left). Keeps ratio.
	float zoom = max(art_zoom, 1.0);
	vec2 pivot = vec2(1.0, 0.0);
	vec2 art_uv = (UV - pivot) / zoom + pivot;
	art_uv = clamp(art_uv, vec2(0.0), vec2(1.0));
	vec4 tex = texture(TEXTURE, art_uv);
	vec3 art = tex.rgb * tint.rgb;
	float art_a = tex.a * tint.a;
	vec3 rgb = mix(fill_color.rgb, art, art_a);

	float luma = dot(rgb, vec3(0.299, 0.587, 0.114));
	vec3 gray = vec3(luma);
	rgb = mix(rgb, gray, clamp(desaturate, 0.0, 1.0));
	rgb = mix(rgb, gray * sepia_color, clamp(sepia_mix, 0.0, 1.0));

	float bevel = clamp(bevel_strength, 0.0, 1.0);
	float ny = clamp(bar_pos.y / max(full.y, 1.0), 0.0, 1.0);
	float top_glow = (1.0 - ny);
	top_glow *= top_glow;
	float bot_shade = smoothstep(0.35, 1.0, ny);
	rgb += vec3(1.0) * top_glow * (0.22 * bevel) * mask;
	rgb *= mix(1.0, 1.0 - 0.32 * bevel, bot_shade * mask);

	float glow = clamp(edge_glow, 0.0, 1.0);
	rgb = mix(rgb, rgb * (1.0 + glow * 0.08), mask);

	float shine = 1.0 - smoothstep(0.0, sheen_band, abs((bar_pos.x / max(full.x, 1.0)) - sheen_progress));
	rgb += sheen_color * shine * sheen_intensity * mask;

	COLOR = vec4(rgb, mask);
}
