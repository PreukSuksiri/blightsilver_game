shader_type canvas_item;

// Radial lantern bloom centered on the node.
uniform vec4  glow_color   : source_color = vec4(1.0, 1.0, 1.0, 1.0); // white
uniform float radius       : hint_range(0.05, 1.0) = 0.12;   // tight — just around logo area
uniform float intensity    : hint_range(0.1, 8.0)  = 0.7;    // peak brightness
uniform float falloff      : hint_range(0.5, 6.0)  = 2.0;    // higher = tighter falloff

void fragment() {
	vec2  centered = UV - vec2(0.5);          // -0.5 → 0.5
	float dist     = length(centered);
	float glow     = exp(-pow(dist / radius, falloff)) * intensity;
	glow           = clamp(glow, 0.0, 1.0);
	COLOR          = vec4(glow_color.rgb, glow_color.a * glow * COLOR.a);
}
