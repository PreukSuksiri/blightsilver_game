extends Control
class_name LiminalBackdrop
## Shared liminal Ken-Burns carousel + drifting fog (Campaign Gallery / Quick Duel).

const _FOG_PATH := "res://assets/textures/effect/fog/Noise 3.png"
const _FOG_TILE_REPEAT: float = 8.0
const _FOG_TILE_REPEAT_DIAG: float = 3.0
const _FOG_IMAGE_SCALE: float = 3.0
const _FOG_ALPHA: float = 0.15
const _FOG_SCROLL_X_DEFAULT: float = 14.0
const _FOG_DIAG_SCROLL_X_DEFAULT: float = 11.0
const _CAROUSEL_Z := 0
const _FOG_Z := 1
const _CAROUSEL_ZOOM_MIN := 1.28
const _CAROUSEL_ZOOM_MAX := 1.48
const _CAROUSEL_PEAK_ALPHA := 1.0
const _CAROUSEL_MACABRE_SHADER: Shader = preload("res://assets/shaders/liminal_macabre.gdshader")
const _CAROUSEL_PRE_FADE_MIN := 0.7
const _CAROUSEL_PRE_FADE_MAX := 1.6
const _CAROUSEL_FADE_IN_MIN := 1.6
const _CAROUSEL_FADE_IN_MAX := 2.8
const _CAROUSEL_HOLD_MIN := 6.5
const _CAROUSEL_HOLD_MAX := 11.0
const _CAROUSEL_FADE_OUT_MIN := 1.6
const _CAROUSEL_FADE_OUT_MAX := 2.6
const _CAROUSEL_PAN_MIN := 14.0
const _CAROUSEL_PAN_MAX := 22.0
const _CAROUSEL_FIRST_DELAY_MIN := 0.5
const _CAROUSEL_FIRST_DELAY_MAX := 1.0
const _CAROUSEL_BETWEEN_DELAY_MIN := 1.0
const _CAROUSEL_BETWEEN_DELAY_MAX := 2.0
const _CAROUSEL_RECENT_MEMORY := 10

var carousel_dir: String = "res://assets/textures/liminal_carousel/"

var _fog_material: ShaderMaterial = null
var _fog_material_diag: ShaderMaterial = null
var _fog_scroll: Vector2 = Vector2.ZERO
var _fog_scroll_diag: Vector2 = Vector2(0.37, 0.61)
var _fog_scroll_x: float = _FOG_SCROLL_X_DEFAULT
var _fog_scroll_y: float = 0.0
var _fog_diag_scroll_x: float = _FOG_DIAG_SCROLL_X_DEFAULT
var _fog_diag_scroll_y: float = -11.0
var _fog_dir_timer: float = 0.0
var _carousel_paths: PackedStringArray = PackedStringArray()
var _carousel_clip: Control = null
var _carousel_fade: Control = null
var _carousel_flicker: Control = null
var _carousel_img: TextureRect = null
var _carousel_pan_tween: Tween = null
var _carousel_fade_tween: Tween = null
var _carousel_recent_paths: PackedStringArray = PackedStringArray()
var _carousel_flicker_enabled: bool = false
var _carousel_flicker_cd: float = 0.0
var _carousel_flicker_left: float = 0.0
var _carousel_flicker_tick_cd: float = 0.0
var _carousel_running: bool = false
var _carousel_first_slide: bool = true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_liminal_carousel()
	_build_fog()
	set_process(true)


func _process(delta: float) -> void:
	_update_fog(delta)
	_update_carousel_flicker(delta)


func _exit_tree() -> void:
	stop()


func stop() -> void:
	_carousel_running = false
	_carousel_flicker_enabled = false
	_kill_carousel_tweens()
	_restore_fog_scroll_defaults()


func has_carousel() -> bool:
	return not _carousel_paths.is_empty()


func _build_liminal_carousel() -> void:
	_load_carousel_pool()
	if _carousel_paths.is_empty():
		return

	_carousel_clip = Control.new()
	_carousel_clip.name = "LiminalCarousel"
	_carousel_clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_carousel_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carousel_clip.clip_contents = true
	_carousel_clip.z_index = _CAROUSEL_Z
	add_child(_carousel_clip)

	_carousel_fade = Control.new()
	_carousel_fade.name = "CarouselFade"
	_carousel_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_carousel_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carousel_fade.modulate = Color(1, 1, 1, 0)
	_carousel_clip.add_child(_carousel_fade)

	_carousel_flicker = Control.new()
	_carousel_flicker.name = "CarouselFlicker"
	_carousel_flicker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_carousel_flicker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carousel_flicker.modulate = Color(1, 1, 1, 1)
	_carousel_fade.add_child(_carousel_flicker)

	_carousel_img = TextureRect.new()
	_carousel_img.name = "CarouselImage"
	_carousel_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_carousel_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_carousel_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carousel_img.modulate = Color(1, 1, 1, 1)
	var macabre := ShaderMaterial.new()
	macabre.shader = _CAROUSEL_MACABRE_SHADER
	macabre.set_shader_parameter("contrast", 2.0)
	macabre.set_shader_parameter("grade_tint", Color(0.88, 0.90, 0.92, 1.0))
	macabre.set_shader_parameter("crush_blacks", 0.02)
	macabre.set_shader_parameter("vignette", 0.1)
	_carousel_img.material = macabre
	_carousel_flicker.add_child(_carousel_img)

	_carousel_running = true
	_carousel_first_slide = true
	_run_liminal_carousel_loop()


func _load_carousel_pool() -> void:
	_carousel_paths.clear()
	_carousel_recent_paths.clear()
	var dir_path := carousel_dir
	if not dir_path.ends_with("/"):
		dir_path += "/"
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir():
			var lower := fname.to_lower()
			if lower.ends_with(".jpg") or lower.ends_with(".jpeg") \
					or lower.ends_with(".png") or lower.ends_with(".webp"):
				_carousel_paths.append(dir_path.path_join(fname))
		fname = dir.get_next()
	dir.list_dir_end()
	_carousel_paths.sort()


func _pick_carousel_path() -> String:
	if _carousel_paths.is_empty():
		return ""
	if _carousel_paths.size() == 1:
		return _carousel_paths[0]
	if _carousel_paths.size() < 20:
		var last := ""
		if not _carousel_recent_paths.is_empty():
			last = _carousel_recent_paths[_carousel_recent_paths.size() - 1]
		var path := last
		while path == last:
			path = _carousel_paths[randi() % _carousel_paths.size()]
		return path
	var memory_cap: int = mini(_CAROUSEL_RECENT_MEMORY, _carousel_paths.size() - 1)
	var blocked: Dictionary = {}
	var recent_n: int = mini(memory_cap, _carousel_recent_paths.size())
	for i: int in range(_carousel_recent_paths.size() - recent_n, _carousel_recent_paths.size()):
		blocked[_carousel_recent_paths[i]] = true
	var candidates: PackedStringArray = PackedStringArray()
	for path: String in _carousel_paths:
		if not blocked.has(path):
			candidates.append(path)
	if candidates.is_empty():
		candidates = _carousel_paths.duplicate()
	return candidates[randi() % candidates.size()]


func _remember_carousel_path(path: String) -> void:
	if path.is_empty():
		return
	if _carousel_paths.size() < 20:
		_carousel_recent_paths.clear()
		_carousel_recent_paths.append(path)
		return
	_carousel_recent_paths.append(path)
	var max_keep: int = maxi(_CAROUSEL_RECENT_MEMORY, 1)
	while _carousel_recent_paths.size() > max_keep:
		_carousel_recent_paths.remove_at(0)


func _load_carousel_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var loaded: Texture2D = load(path) as Texture2D
		if loaded != null:
			return loaded
	var abs_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_path):
		return null
	var img := Image.new()
	if img.load(abs_path) != OK:
		return null
	return ImageTexture.create_from_image(img)


func _kill_carousel_tweens() -> void:
	if _carousel_pan_tween != null and _carousel_pan_tween.is_valid():
		_carousel_pan_tween.kill()
	_carousel_pan_tween = null
	if _carousel_fade_tween != null and _carousel_fade_tween.is_valid():
		_carousel_fade_tween.kill()
	_carousel_fade_tween = null


func _carousel_alive() -> bool:
	return _carousel_running \
			and is_inside_tree() \
			and _carousel_img != null \
			and is_instance_valid(_carousel_img) \
			and _carousel_fade != null \
			and is_instance_valid(_carousel_fade) \
			and _carousel_flicker != null \
			and is_instance_valid(_carousel_flicker)


func _run_liminal_carousel_loop() -> void:
	var first_delay := randf_range(_CAROUSEL_FIRST_DELAY_MIN, _CAROUSEL_FIRST_DELAY_MAX)
	await get_tree().create_timer(first_delay).timeout
	while _carousel_alive():
		await _play_liminal_carousel_slide()
		if not _carousel_alive():
			return
		var gap := randf_range(_CAROUSEL_BETWEEN_DELAY_MIN, _CAROUSEL_BETWEEN_DELAY_MAX)
		await get_tree().create_timer(gap).timeout


func _play_liminal_carousel_slide() -> void:
	if not _carousel_alive():
		return

	var path := _pick_carousel_path()
	var tex: Texture2D = _load_carousel_texture(path)
	if tex == null:
		await get_tree().create_timer(1.0).timeout
		return
	_remember_carousel_path(path)

	_kill_carousel_tweens()
	_carousel_flicker_enabled = false
	_carousel_fade.modulate = Color(1, 1, 1, 0)
	_carousel_flicker.modulate = Color(1, 1, 1, 1)
	_carousel_img.modulate = Color(1, 1, 1, 1)
	_carousel_img.texture = tex
	_carousel_img.visible = false

	await get_tree().process_frame
	if not _carousel_alive():
		return

	var view := _carousel_clip.size
	if view.x < 2.0 or view.y < 2.0:
		view = get_viewport_rect().size
	var zoom := randf_range(_CAROUSEL_ZOOM_MIN, _CAROUSEL_ZOOM_MAX)
	var img_size := view * zoom
	_carousel_img.size = img_size
	_carousel_img.position = Vector2.ZERO

	var max_x := maxf(0.0, img_size.x - view.x)
	var y := (view.y - img_size.y) * 0.5
	var pan_ltr: bool = randf() >= 0.5
	var start_x := 0.0 if pan_ltr else -max_x
	var end_x := -max_x if pan_ltr else 0.0
	_carousel_img.position = Vector2(start_x, y)
	_carousel_img.visible = true
	_apply_fog_oppose_carousel_pan(pan_ltr)

	var pan_sec := randf_range(_CAROUSEL_PAN_MIN, _CAROUSEL_PAN_MAX)
	_carousel_pan_tween = create_tween()
	_carousel_pan_tween.tween_property(
			_carousel_img, "position", Vector2(end_x, y), pan_sec) \
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	var pre_fade: float
	if _carousel_first_slide:
		pre_fade = randf_range(0.12, 0.28)
	else:
		pre_fade = randf_range(_CAROUSEL_PRE_FADE_MIN, _CAROUSEL_PRE_FADE_MAX)
	await get_tree().create_timer(pre_fade).timeout
	if not _carousel_alive():
		return

	await _tween_carousel_fade(0.0, _CAROUSEL_PEAK_ALPHA,
			randf_range(_CAROUSEL_FADE_IN_MIN, _CAROUSEL_FADE_IN_MAX), true)
	_carousel_first_slide = false
	if not _carousel_alive():
		return

	_carousel_flicker_enabled = true
	_carousel_flicker_cd = randf_range(1.5, 4.5)
	_carousel_flicker_left = 0.0
	var hold := randf_range(_CAROUSEL_HOLD_MIN, _CAROUSEL_HOLD_MAX)
	await get_tree().create_timer(hold).timeout
	if not _carousel_alive():
		return

	_carousel_flicker_enabled = false
	_carousel_flicker.modulate = Color(1, 1, 1, 1)

	await _tween_carousel_fade(_CAROUSEL_PEAK_ALPHA, 0.0,
			randf_range(_CAROUSEL_FADE_OUT_MIN, _CAROUSEL_FADE_OUT_MAX), false)
	_restore_fog_scroll_defaults()


func _tween_carousel_fade(from_a: float, to_a: float, duration: float, ease_out: bool) -> void:
	if not _carousel_alive():
		return
	if _carousel_fade_tween != null and _carousel_fade_tween.is_valid():
		_carousel_fade_tween.kill()
	_carousel_fade.modulate = Color(1, 1, 1, from_a)
	_carousel_fade_tween = create_tween()
	var tw := _carousel_fade_tween.tween_method(
			func(a: float) -> void:
				if _carousel_fade != null and is_instance_valid(_carousel_fade):
					_carousel_fade.modulate = Color(1, 1, 1, a),
			from_a,
			to_a,
			duration
		).set_trans(Tween.TRANS_SINE)
	if ease_out:
		tw.set_ease(Tween.EASE_OUT)
	else:
		tw.set_ease(Tween.EASE_IN)
	await _carousel_fade_tween.finished


func _update_carousel_flicker(delta: float) -> void:
	if not _carousel_flicker_enabled or not _carousel_alive():
		return
	if _carousel_flicker_left > 0.0:
		_carousel_flicker_left -= delta
		_carousel_flicker_tick_cd -= delta
		if _carousel_flicker_left <= 0.0:
			_carousel_flicker.modulate = Color(1, 1, 1, 1)
			_carousel_flicker_cd = randf_range(2.0, 7.5)
			return
		if _carousel_flicker_tick_cd <= 0.0:
			_carousel_flicker_tick_cd = randf_range(0.025, 0.07)
			var a := 1.0
			if randf() < 0.65:
				a = randf_range(0.12, 0.55)
			_carousel_flicker.modulate = Color(1, 1, 1, a)
		return
	_carousel_flicker_cd -= delta
	if _carousel_flicker_cd <= 0.0:
		_carousel_flicker_left = randf_range(0.08, 0.32)
		_carousel_flicker_tick_cd = 0.0


func _build_fog() -> void:
	var fog_tex := load(_FOG_PATH) as Texture2D
	if fog_tex == null:
		return

	var smoke_shader := Shader.new()
	smoke_shader.code = """
shader_type canvas_item;
uniform vec2 scroll = vec2(0.0, 0.0);
uniform float tile_repeat = 1.0;
uniform float image_scale = 3.0;
uniform float fog_alpha = 0.2;
void fragment() {
	vec2 uv = fract(UV * tile_repeat / image_scale + scroll);
	vec4 tex = texture(TEXTURE, uv);
	float smoke = 1.0 - tex.r;
	COLOR = vec4(vec3(smoke), smoke * fog_alpha);
}
"""

	var fog_clip := Control.new()
	fog_clip.name = "LiminalFog"
	fog_clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fog_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_clip.z_index = _FOG_Z
	add_child(fog_clip)

	_fog_material = _make_fog_material(smoke_shader, _FOG_TILE_REPEAT)
	_fog_material_diag = _make_fog_material(smoke_shader, _FOG_TILE_REPEAT_DIAG)
	fog_clip.add_child(_make_fog_layer(fog_tex, _fog_material))
	fog_clip.add_child(_make_fog_layer(fog_tex, _fog_material_diag))

	_fog_dir_timer = randf_range(3.0, 6.0)
	_pick_new_fog_vertical_dir()


func _make_fog_material(smoke_shader: Shader, tile_repeat: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = smoke_shader
	mat.set_shader_parameter("tile_repeat", tile_repeat)
	mat.set_shader_parameter("image_scale", _FOG_IMAGE_SCALE)
	mat.set_shader_parameter("fog_alpha", _FOG_ALPHA)
	return mat


func _make_fog_layer(fog_tex: Texture2D, mat: ShaderMaterial) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = fog_tex
	tr.material = mat
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _pick_new_fog_vertical_dir() -> void:
	_fog_scroll_y = randf_range(-5.0, 5.0)
	if absf(_fog_scroll_y) < 1.5:
		_fog_scroll_y = 2.0 if randf() > 0.5 else -2.0


func _apply_fog_oppose_carousel_pan(pan_ltr: bool) -> void:
	var fog_x: float = absf(_FOG_SCROLL_X_DEFAULT)
	var diag_x: float = absf(_FOG_DIAG_SCROLL_X_DEFAULT)
	if pan_ltr:
		_fog_scroll_x = -fog_x
		_fog_diag_scroll_x = -diag_x
	else:
		_fog_scroll_x = fog_x
		_fog_diag_scroll_x = diag_x


func _restore_fog_scroll_defaults() -> void:
	_fog_scroll_x = _FOG_SCROLL_X_DEFAULT
	_fog_diag_scroll_x = _FOG_DIAG_SCROLL_X_DEFAULT


func _update_fog(delta: float) -> void:
	if _fog_material == null:
		return
	_fog_dir_timer -= delta
	if _fog_dir_timer <= 0.0:
		_fog_dir_timer = randf_range(3.0, 7.0)
		_pick_new_fog_vertical_dir()
	var step := delta * 0.002
	_fog_scroll.x += _fog_scroll_x * step
	_fog_scroll.y += _fog_scroll_y * step
	_fog_material.set_shader_parameter("scroll", _fog_scroll)
	if _fog_material_diag != null:
		_fog_scroll_diag.x += _fog_diag_scroll_x * step
		_fog_scroll_diag.y += _fog_diag_scroll_y * step
		_fog_material_diag.set_shader_parameter("scroll", _fog_scroll_diag)
