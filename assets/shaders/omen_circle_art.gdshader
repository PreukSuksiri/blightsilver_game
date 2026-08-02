shader_type canvas_item;

/// Illustration clipped to the top semicircle of the omen capsule.
/// Mask is computed from local pixel space so it survives KEEP_ASPECT_COVERED
/// stretching (which remaps UV and would otherwise skew the circle).
uniform vec2 art_size = vec2(300.0, 150.0);
uniform vec4 placeholder_color : source_color = vec4(0.2, 0.25, 0.35, 1.0);
uniform float use_texture : hint_range(0.0, 1.0) = 1.0;
/// Keeps art just inside the rarity ring.
uniform float edge_inset_px : hint_range(0.0, 40.0) = 7.0;
/// Soft dissolve into the capsule body at the equator, in pixels.
uniform float bottom_fade_px : hint_range(0.0, 120.0) = 42.0;
uniform vec4 tint_color : source_color = vec4(0.55, 0.75, 1.0, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.18;
uniform float vignette : hint_range(0.0, 1.0) = 0.35;

// Chemical fog condensation, shared timing with the capsule chrome.
uniform sampler2D fog_noise : hint_default_white, filter_linear, repeat_enable;
uniform vec2 fog_scroll = vec2(0.0, 0.0);
uniform float fog_tiling : hint_range(0.5, 6.0) = 2.1;
uniform float materialize : hint_range(0.0, 1.0) = 1.0;
uniform float condense_softness : hint_range(0.05, 0.9) = 0.38;

varying vec2 v_local;

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	vec2 s = max(art_size, vec2(1.0));
	float radius = s.x * 0.5;
	// Circle centre sits on the equator (bottom edge of this rect).
	vec2 p = v_local - vec2(radius, s.y);
	float r = length(p);

	float limit = max(radius - edge_inset_px, 1.0);
	float in_circle = 1.0 - smoothstep(limit - 1.5, limit, r);
	// Fade out as we approach the equator so art melts into the body.
	float fade = max(bottom_fade_px, 1.0);
	float in_top = smoothstep(0.0, fade, -p.y);

	vec4 tex_col = texture(TEXTURE, UV);
	vec4 col = mix(placeholder_color, tex_col, use_texture);
	col.rgb = mix(col.rgb, tint_color.rgb, tint_strength);
	// Darken toward the rim so the art seats inside the bezel.
	col.rgb *= 1.0 - smoothstep(limit * 0.72, limit, r) * vignette;
	col.a *= in_circle * in_top;

	// Match the chrome's condensation front: art uses the capsule-space UV so the
	// blotches line up across both layers.
	float m = clamp(materialize, 0.0, 1.0);
	float soft = max(condense_softness, 0.01);
	vec2 cap_uv = vec2(v_local.x / s.x, v_local.y / (s.y * 2.0));
	float n = texture(fog_noise, cap_uv * fog_tiling + fog_scroll).r;
	float thresh = n * 0.68 + clamp(r / max(radius, 1.0), 0.0, 1.0) * 0.32;
	col.a *= clamp(smoothstep(thresh, thresh + soft, m * (1.0 + soft)), 0.0, 1.0);

	COLOR = col;
}
