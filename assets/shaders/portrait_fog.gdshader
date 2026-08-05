shader_type canvas_item;
render_mode blend_mix;

// Portrait alpha mask — fog only where the illustration is opaque.
uniform sampler2D portrait_tex : filter_linear;
uniform vec4 art_uv_rect = vec4(0.0, 0.0, 1.0, 1.0); // xy offset, zw size (host-normalized)
uniform float flip_h = 0.0;
uniform vec2 scroll = vec2(0.0, 0.0);
uniform float tile_repeat = 1.0;
uniform float image_scale = 3.0;
uniform float fog_alpha = 0.15;
uniform float alpha_threshold = 0.04;

void fragment() {
	vec2 art_uv = (UV - art_uv_rect.xy) / art_uv_rect.zw;
	if (art_uv.x < 0.0 || art_uv.x > 1.0 || art_uv.y < 0.0 || art_uv.y > 1.0) {
		discard;
	}
	if (flip_h > 0.5) {
		art_uv.x = 1.0 - art_uv.x;
	}
	vec4 portrait = texture(portrait_tex, art_uv);
	if (portrait.a < alpha_threshold) {
		discard;
	}
	vec2 fog_uv = fract(UV * tile_repeat / image_scale + scroll);
	float smoke = 1.0 - texture(TEXTURE, fog_uv).r;
	COLOR = vec4(vec3(smoke), smoke * fog_alpha * portrait.a);
}
