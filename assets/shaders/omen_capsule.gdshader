shader_type canvas_item;

// Omen capsule chrome: brushed-metal disc, double bezel with rarity ring,
// travelling circuit patrol, one-shot sheen sweep and a soft outer halo.
uniform vec2 rect_size = vec2(352.0, 352.0);
uniform float radius_px : hint_range(8.0, 400.0) = 150.0;

uniform vec4 fill_inner : source_color = vec4(0.11, 0.14, 0.22, 0.98);
uniform vec4 fill_outer : source_color = vec4(0.02, 0.03, 0.06, 0.98);
uniform vec4 ring_a : source_color = vec4(0.62, 0.64, 0.70, 1.0);
uniform vec4 ring_b : source_color = vec4(0.95, 0.97, 1.0, 1.0);

uniform float ring_px : hint_range(1.0, 14.0) = 3.5;
uniform float inner_bezel_gap : hint_range(2.0, 40.0) = 9.0;
uniform float inner_shadow : hint_range(0.0, 1.0) = 0.55;
uniform float groove_strength : hint_range(0.0, 0.3) = 0.035;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.30;

uniform float glow_px : hint_range(0.0, 80.0) = 22.0;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.4;

uniform float patrol_speed : hint_range(0.0, 3.0) = 0.35;
uniform float patrol_width : hint_range(0.01, 0.4) = 0.055;
uniform float patrol_intensity : hint_range(0.0, 3.0) = 1.1;

// Drive -0.2 -> 1.25 for a sweep; park at 2.0 to disable.
uniform float sheen_progress : hint_range(-0.5, 2.5) = 2.0;
uniform float sheen_width : hint_range(0.02, 0.6) = 0.16;
uniform float sheen_intensity : hint_range(0.0, 3.0) = 0.8;

// Chemical fog condensation. 0 = still vapour, 1 = fully materialised.
uniform sampler2D fog_noise : hint_default_white, filter_linear, repeat_enable;
uniform vec2 fog_scroll = vec2(0.0, 0.0);
uniform float fog_tiling : hint_range(0.5, 6.0) = 2.1;
uniform float materialize : hint_range(0.0, 1.0) = 1.0;
uniform float condense_softness : hint_range(0.05, 0.9) = 0.38;

void fragment() {
	vec2 size = max(rect_size, vec2(1.0));
	vec2 p = (UV - 0.5) * size;
	float radius = max(radius_px, 4.0);
	float r = length(p);
	float d = r - radius;
	float aa = max(fwidth(d), 0.85);

	float inside = 1.0 - smoothstep(-aa, aa, d);
	float rad_t = clamp(r / radius, 0.0, 1.0);
	float ang = atan(p.y, p.x) / 6.2831853 + 0.5;

	// Body: radial gradient with a gentle vertical falloff.
	float grad_t = clamp(rad_t * 0.62 + UV.y * 0.34, 0.0, 1.0);
	vec4 fill = mix(fill_inner, fill_outer, grad_t);

	// Brushed concentric grooves.
	fill.rgb *= 1.0 + sin(r * 0.55) * groove_strength;

	// Broad specular sweep across the upper-left of the disc.
	float spec = pow(clamp(1.0 - length(p / radius - vec2(-0.35, -0.45)), 0.0, 1.0), 3.0);
	fill.rgb += vec3(1.0) * spec * specular_strength * 0.35;

	// Inner shadow hugging the bezel.
	float rim_shade = smoothstep(0.68, 1.0, rad_t) * inner_shadow;
	fill.rgb *= (1.0 - rim_shade * 0.6);

	// Inner hairline bezel.
	float bez_r = max(radius - inner_bezel_gap, 2.0);
	float bez = 1.0 - smoothstep(0.0, aa + 0.8, abs(r - bez_r) - 0.7);
	fill.rgb = mix(fill.rgb, ring_a.rgb * 0.85, bez * 0.55);

	// Outer rarity ring with a slow anisotropic shimmer.
	float ring_d = abs(d + ring_px * 0.5) - ring_px * 0.5;
	float ring = 1.0 - smoothstep(0.0, aa + 0.6, ring_d);
	vec4 ring_col = mix(ring_a, ring_b, 0.45 + 0.35 * sin(ang * 12.5663706 + TIME * 0.5));

	// Circuit patrol hotspot travelling around the rim.
	float pt = fract(TIME * patrol_speed);
	float pd = abs(ang - pt);
	pd = min(pd, 1.0 - pd);
	float patrol = 1.0 - smoothstep(0.0, patrol_width, pd);
	float patrol_tail = (1.0 - smoothstep(0.0, patrol_width * 4.0, pd)) * 0.35;
	ring_col.rgb += ring_b.rgb * (patrol * patrol_intensity + patrol_tail);

	vec4 col = fill;
	col = mix(col, ring_col, ring);
	col.a *= inside;

	// One-shot diagonal metal sheen, clipped to the disc.
	float sd = abs((UV.x * 0.78 + UV.y * 0.22) - sheen_progress);
	float sheen = 1.0 - smoothstep(0.0, sheen_width, sd);
	col.rgb += vec3(1.0) * sheen * sheen_intensity * inside * 0.45;

	// Soft outer halo in the rarity colour.
	float halo = pow(1.0 - smoothstep(0.0, max(glow_px, 0.001), max(d, 0.0)), 1.6);
	halo *= 1.0 - inside;
	vec4 out_col = col;
	out_col.rgb = mix(out_col.rgb, ring_a.rgb, halo);
	out_col.a = max(col.a, halo * (glow_strength + patrol * 0.25));

	// Fog condensation: blotchy noise threshold, centre solidifies before the rim.
	float m = clamp(materialize, 0.0, 1.0);
	float soft = max(condense_softness, 0.01);
	float n = texture(fog_noise, UV * fog_tiling + fog_scroll).r;
	float thresh = n * 0.68 + rad_t * 0.32;
	float reveal = clamp(smoothstep(thresh, thresh + soft, m * (1.0 + soft)), 0.0, 1.0);
	out_col.a *= reveal;
	// Luminous wisp along the condensation front.
	float front = smoothstep(0.0, 0.30, reveal) * (1.0 - smoothstep(0.30, 0.80, reveal));
	out_col.rgb += ring_b.rgb * front * 0.55 * (1.0 - step(0.999, m));

	COLOR = out_col;
}
