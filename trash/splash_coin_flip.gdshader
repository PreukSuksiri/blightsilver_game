shader_type canvas_item;

uniform sampler2D coin_front : filter_linear, repeat_disable;
uniform sampler2D coin_back : filter_linear, repeat_disable;
uniform float flip_speed = 2.15;
uniform float running = 1.0;

void fragment() {
	float t: float = TIME * flip_speed * running;
	float c: float = cos(t * PI);
	float squash: float = max(abs(c), 0.07);
	vec2 uv: vec2 = UV;
	uv.x = (uv.x - 0.5) / squash + 0.5;

	vec4 front_col: vec4 = texture(coin_front, uv);
	vec4 back_col: vec4 = texture(coin_back, uv);
	float show_front: float = step(0.0, c);
	COLOR = mix(back_col, front_col, show_front);

	if (uv.x < 0.0 || uv.x > 1.0) {
		COLOR.a = 0.0;
	}
}
