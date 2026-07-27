shader_type canvas_item;

// Soft rarity bloom + circuit patrol for pack / scroll reveal cards.
// Drawn on an oversized ColorRect behind the card (transparent center).
// GLES3-safe (no return in fragment).
uniform vec2 rect_size = vec2(220.0, 300.0);
uniform vec2 card_size = vec2(150.0, 210.0);
uniform float corner_radius_px : hint_range(0.0, 48.0) = 12.0;
uniform vec4 glow_color : source_color = vec4(0.55, 0.92, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform float glow_spread : hint_range(4.0, 120.0) = 42.0;
uniform float rim_speed : hint_range(0.0, 3.0) = 0.55;
uniform float rim_pulse : hint_range(0.0, 1.0) = 0.72;
uniform float circuit_patrol : hint_range(0.0, 1.0) = 1.0;

float sd_rounded_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + vec2(r);
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 size = max(rect_size, vec2(1.0));
	vec2 card_half = max(card_size, vec2(1.0)) * 0.5;
	float r = min(corner_radius_px, min(card_half.x, card_half.y));
	vec2 p = (UV - 0.5) * size;
	float dist = sd_rounded_box(p, card_half, r);

	// Soft falloff outside the card silhouette.
	float bloom = 1.0 - smoothstep(0.0, max(glow_spread, 1.0), max(dist, 0.0));
	bloom *= bloom; // quadratic — less boxy than linear StyleBox shadow
	float inside = 1.0 - smoothstep(0.0, 1.75, dist);
	float outer_glow = bloom * (1.0 - inside);

	// Thin luminous rim hugging the rounded edge.
	float rim = 1.0 - smoothstep(0.0, 5.5, abs(dist));
	rim *= mix(0.35, 1.0, 1.0 - inside * 0.15);

	// Circuit patrol hotspot traveling around the frame.
	float ang = atan(p.y, p.x) / 6.2831853 + 0.5;
	float patrol_t = fract(TIME * max(rim_speed * 2.2, 0.001));
	float pd = abs(ang - patrol_t);
	pd = min(pd, 1.0 - pd);
	float band_w = mix(0.045, 0.10, clamp(rim_pulse, 0.0, 1.0));
	float patrol = (1.0 - smoothstep(0.0, band_w, pd)) * clamp(circuit_patrol, 0.0, 1.0);

	float pulse = 1.0 + rim_pulse * 0.22 * sin(TIME * 1.55 + ang * 6.2831853);
	float a = outer_glow * intensity * 0.62 * pulse;
	a += rim * intensity * 0.42 * pulse;
	a += rim * patrol * intensity * (0.95 + rim_pulse * 0.55);
	a = clamp(a, 0.0, 1.0) * glow_color.a;

	vec3 rgb = glow_color.rgb;
	rgb += glow_color.rgb * patrol * rim * 0.65;
	COLOR = vec4(rgb, a);
}
