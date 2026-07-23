shader_type canvas_item;

// Movie film grain overlay (fine silver-halide noise — no block dust).
uniform float intensity : hint_range(0.0, 1.0) = 0.18;
uniform float grain_scale : hint_range(200.0, 1200.0) = 640.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Value noise with bilinear blend — avoids hard brick cells.
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 drift = TIME * vec2(19.0, 31.0);
	float fine = value_noise(UV * grain_scale + drift);
	float fine2 = value_noise(UV * grain_scale * 1.7 - drift * 0.6 + 13.0);
	float grain = mix(fine, fine2, 0.45);

	// Soft edge weight (subtle, not a vignette plate).
	vec2 q = UV * 2.0 - 1.0;
	float vig = smoothstep(1.4, 0.4, length(q * vec2(1.05, 1.0)));
	grain = mix(grain * 0.9, grain, vig);

	float a = intensity * (0.20 + 0.80 * grain);
	vec3 col = mix(vec3(0.90, 0.88, 0.84), vec3(1.0), grain);
	COLOR = vec4(col, a);
}
