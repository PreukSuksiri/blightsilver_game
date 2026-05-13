shader_type canvas_item;

// Lantern glow: bright near the logo, exponentially fading outward.
uniform vec4  glow_color   : source_color = vec4(1.0, 0.96, 0.85, 1.0); // warm lantern white
uniform float glow_radius  : hint_range(5.0, 200.0) = 90.0;  // total spread in pixels
uniform float falloff_rate : hint_range(0.1, 5.0)  = 0.5;   // lower = wider bright halo
uniform float glow_boost   : hint_range(1.0, 10.0) = 4.5;   // brightness multiplier

void fragment() {
	float inherited_alpha = COLOR.a;

	float glow         = 0.0;
	float total_weight = 0.0;
	int   rings        = 12;  // concentric sample rings
	int   steps        = 20;  // samples per ring

	for (int r = 1; r <= rings; r++) {
		float t      = float(r) / float(rings);
		float radius = t * glow_radius;
		float weight = exp(-t * falloff_rate);

		for (int i = 0; i < steps; i++) {
			float angle  = float(i) / float(steps) * TAU;
			vec2  offset = vec2(cos(angle), sin(angle)) * radius * TEXTURE_PIXEL_SIZE;
			glow += texture(TEXTURE, UV + offset).a * weight;
		}
		total_weight += weight * float(steps);
	}

	// Normalise rings only — keep center separate so it never dilutes outer glow
	float center     = texture(TEXTURE, UV).a;
	float glow_alpha = clamp((glow / total_weight) * glow_boost, 0.0, 1.0);

	// Silhouette stays fully opaque; glow blooms around it
	float alpha = max(glow_alpha, center);
	COLOR = vec4(glow_color.rgb, glow_color.a * alpha * inherited_alpha);
}
