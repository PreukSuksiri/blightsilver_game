shader_type canvas_item;

void fragment() {
	// Diagonal metallic gradient — near-white with subtle sheen
	float t = UV.x * 0.35 + UV.y * 0.65;

	vec3 c0 = vec3(0.82, 0.83, 0.86);
	vec3 c1 = vec3(0.93, 0.94, 0.96);
	vec3 c2 = vec3(1.00, 1.00, 1.00);
	vec3 c3 = vec3(0.88, 0.89, 0.92);
	vec3 c4 = vec3(0.97, 0.97, 0.99);
	vec3 c5 = vec3(0.84, 0.85, 0.88);

	vec3 metal;
	if (t < 0.18)
		metal = mix(c0, c1, t / 0.18);
	else if (t < 0.38)
		metal = mix(c1, c2, (t - 0.18) / 0.20);
	else if (t < 0.54)
		metal = mix(c2, c3, (t - 0.38) / 0.16);
	else if (t < 0.74)
		metal = mix(c3, c4, (t - 0.54) / 0.20);
	else
		metal = mix(c4, c5, (t - 0.74) / 0.26);

	COLOR = vec4(metal, COLOR.a);
}
