shader_type canvas_item;

/// Long / elongated hexagon (flat top & bottom, pointed left & right ends)
/// with white fill, art tint, and colored frame stroke.

uniform vec2 rect_size = vec2(160.0, 64.0);
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 frame_color : source_color = vec4(0.60, 0.82, 1.0, 0.95);
uniform float frame_width = 5.0;
uniform float edge_glow = 0.0; // 0..1 equipped accent
/// How far the pointy ends cut in from left/right (fraction of half-width, ~0.2–0.45).
uniform float tip_inset = 0.28;

varying vec2 v_pos;

void vertex() {
	v_pos = VERTEX;
}

/// SDF for a horizontal long hexagon centered at origin.
/// half_size = half width/height of the bounding rect; tip = end chamfer in pixels.
float sd_long_hexagon(vec2 p, vec2 half_size, float tip) {
	p = abs(p);
	float hx = half_size.x;
	float hy = half_size.y;
	tip = clamp(tip, 1.0, hx - 1.0);

	// Flat top/bottom + vertical sides, with 45°-ish cuts toward the points.
	// Region is intersection of:
	//   |y| <= hy
	//   |x| <= hx
	//   |x| / hx + |y| * (tip / (hx * hy)) ... use plane from (hx - tip, hy) to (hx, 0)
	float d_box = max(p.x - hx, p.y - hy);

	// Diagonal half-plane: line through (hx - tip, hy) and (hx, 0)
	// (x - (hx - tip)) / tip + y / hy <= 1
	float d_diag = (p.x - (hx - tip)) / tip + p.y / hy - 1.0;
	// Scale diag distance roughly to pixels for AA
	float diag_scale = min(tip, hy);
	d_diag *= diag_scale * 0.5;

	return max(d_box, d_diag);
}

void fragment() {
	vec2 size = max(rect_size, vec2(1.0));
	vec2 half_size = size * 0.5 - vec2(1.0);
	vec2 p = v_pos - size * 0.5;
	float tip = half_size.x * clamp(tip_inset, 0.12, 0.48);

	float d = sd_long_hexagon(p, half_size, tip);
	float aa = max(fwidth(d), 0.75);
	float inside = 1.0 - smoothstep(0.0, aa, d);
	float inner = 1.0 - smoothstep(0.0, aa, d + frame_width);
	float stroke = clamp(inside - inner, 0.0, 1.0);

	vec4 tex = texture(TEXTURE, UV);
	vec3 art = tex.rgb * tint.rgb;
	float art_a = tex.a * tint.a;

	// White background under art.
	vec3 rgb = mix(fill_color.rgb, art, art_a);

	float glow = clamp(edge_glow, 0.0, 1.0);
	vec3 stroke_col = mix(frame_color.rgb, vec3(1.0, 0.88, 0.35), glow * 0.75);
	float stroke_a = stroke * mix(frame_color.a, 1.0, glow * 0.35);
	rgb = mix(rgb, stroke_col, stroke_a);

	COLOR = vec4(rgb, inside);
}
