shader_type canvas_item;

uniform vec2 circle_center = vec2(800.0, 450.0);
uniform float circle_radius = 64.0;
uniform float soft_edge = 12.0;
uniform float dim_alpha = 0.78;

void fragment() {
	float dist = distance(FRAGCOORD.xy, circle_center);
	float t = smoothstep(circle_radius, circle_radius + soft_edge, dist);
	COLOR = vec4(0.0, 0.0, 0.0, t * dim_alpha);
}
