shader_type canvas_item;

uniform sampler2D coin_front : filter_linear, repeat_disable;
uniform sampler2D coin_back : filter_linear, repeat_disable;
uniform float flip_speed = 2.2;
uniform float running = 1.0;
uniform vec2 quad_half_size = vec2(18.0, 18.0);

void vertex() {
	float c = cos(TIME * flip_speed * running * PI);
	float squash = max(abs(c), 0.08);
	// Scale width around horizontal center (not top-left origin).
	VERTEX.x = (VERTEX.x - quad_half_size.x) * squash + quad_half_size.x;
}

void fragment() {
	float c = cos(TIME * flip_speed * running * PI);
	float squash = max(abs(c), 0.08);
	vec2 uv = UV;
	uv.x = (uv.x - 0.5) / squash + 0.5;

	vec4 front_col = texture(coin_front, uv);
	vec4 back_col = texture(coin_back, uv);
	COLOR = c >= 0.0 ? front_col : back_col;

	if (uv.x < 0.0 || uv.x > 1.0) {
		COLOR.a = 0.0;
	}
}
