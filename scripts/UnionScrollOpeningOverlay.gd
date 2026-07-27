extends Control
class_name UnionScrollOpeningOverlay

signal reveal_finished

const SCROLL_TEX_PATH: String = "res://assets/textures/inventory/ui_union_scroll.png"
const FALLBACK_CARD_PATH: String = "res://assets/textures/cards/frames/vellum_card_frame_full.png"
const CARD_BACK_PATH: String = "res://assets/textures/cards/sample/card_back.png"
const FULL_CARDS_DIR: String = "res://assets/textures/cards/full_cards/"
const FANFARE_UNION_PATH: String = "res://assets/audio/fanfare/pack_fanfare_union.mp3"
const DISPLAY_HOLD_SECONDS: float = 30.0
const CARD_SETTLE_SECONDS: float = 0.2
const FANFARE_FADE_IN_SECONDS: float = 0.2
const FANFARE_FADE_OUT_SECONDS: float = 0.5
const BGM_FADE_OUT_BEFORE_FANFARE: float = 0.3
const BGM_FADE_IN_AFTER_FANFARE: float = 0.5
const FLIP_HALF_SEC: float = 0.16
const FAN_MOVE_SEC: float = 0.38
## Keep old tear-apart path in code; false = shatter + facedown reveal.
const USE_LEGACY_TEAR_OPENING: bool = false
const _ROUNDED_CLIP: Shader = preload("res://assets/shaders/rounded_rect_clip.gdshader")
const _REVEAL_GLOW_SHADER: Shader = preload("res://assets/shaders/pack_reveal_glow.gdshader")
const _CARD_CORNER_RADIUS_REF: float = 8.0
const _GLOW_PAD_FRAC: float = 0.12
const _GLOW_SPREAD_MIN: float = 10.0
const _PACK_MAX_H_FRAC: float = 0.85
const _PACK_MAX_W_FRAC: float = 0.50
const _STACK_IN_PACK_FRAC: float = 0.36
const _PACK_Z := 25
const _CARD_STACK_Z := 1
const _CARD_FAN_Z := 10
## Match union-scroll art: diagonal cylinder (~top-right → bottom-left).
const _SCROLL_CARD_ROT_RAD: float = PI * 0.28
## Edge-on look while nested in the scroll (X squash). Y keeps stack height.
const _SCROLL_CARD_SIDE_X: float = 0.10
## Unflatten + upright while the scroll shatters.
const _SCROLL_CARD_RESTORE_SEC: float = 0.55
const _WHITE_GLOW: Color = Color(1.0, 1.0, 1.0, 0.72)

var _union_name: String = ""
var _pack_w: float = 0.0
var _pack_h: float = 0.0
var _pack_aspect: float = 160.0 / 220.0
var _card_w: float = 0.0
var _card_h: float = 0.0
var _skip_requested: bool = false
var _skippable: bool = true
var _dismiss_allowed: bool = false
var _anim_done: bool = false
var _glow_sb: StyleBoxFlat = null
var _glow_mat: ShaderMaterial = null
var _card_tex: Texture2D = null
var _fanfare_player: AudioStreamPlayer = null
var _fanfare_tween: Tween = null
var _bgm_restored: bool = false
var _should_restore_bgm: bool = true

var _bg: ColorRect = null
var _pack_root: Control = null
var _clip_top: Control = null
var _clip_bot: Control = null
var _pack_img: TextureRect = null
var _pack_tex: Texture2D = null
var _card_back_tex: Texture2D = null

static func open(parent: Node, union_name: String, skippable: bool = true) -> UnionScrollOpeningOverlay:
	var overlay := UnionScrollOpeningOverlay.new()
	overlay._union_name = union_name if union_name != null else ""
	overlay._skippable = skippable
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 50
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if parent != null and is_instance_valid(parent):
		parent.add_child.call_deferred(overlay)
	return overlay

func _ready() -> void:
	_compute_sizes()
	if ResourceLoader.exists(CARD_BACK_PATH):
		_card_back_tex = load(CARD_BACK_PATH) as Texture2D
	_build_ui()
	_run.call_deferred()

func _overlay_area() -> Vector2:
	var area: Vector2 = size
	if area.x < 8.0 or area.y < 8.0:
		area = get_viewport().get_visible_rect().size
	if area.x < 8.0 or area.y < 8.0:
		area = get_viewport_rect().size
	return area


func _fit_pack_size(aspect: float) -> Vector2:
	var s: Vector2 = _overlay_area()
	var safe_aspect: float = maxf(aspect, 0.001)
	var max_h: float = s.y * _PACK_MAX_H_FRAC
	var max_w: float = s.x * _PACK_MAX_W_FRAC
	var h: float = max_h
	var w: float = h * safe_aspect
	if w > max_w:
		w = max_w
		h = w / safe_aspect
	w = minf(w, s.x * 0.90)
	h = minf(h, s.y * 0.90)
	if w / safe_aspect > h:
		w = h * safe_aspect
	else:
		h = w / safe_aspect
	return Vector2(maxf(1.0, w), maxf(1.0, h))


func _apply_pack_display_size(pack_sz: Vector2) -> void:
	_pack_w = pack_sz.x
	_pack_h = pack_sz.y
	if _pack_root == null or not is_instance_valid(_pack_root):
		return
	_pack_root.custom_minimum_size = Vector2(_pack_w, _pack_h)
	_pack_root.size = Vector2(_pack_w, _pack_h)
	_pack_root.pivot_offset = Vector2(_pack_w * 0.5, _pack_h * 0.5)
	if _pack_img != null and is_instance_valid(_pack_img):
		_pack_img.custom_minimum_size = Vector2(_pack_w, _pack_h)
		_pack_img.size = Vector2(_pack_w, _pack_h)
		_pack_img.position = Vector2.ZERO
	if _clip_top != null and is_instance_valid(_clip_top):
		var split_y: float = floor(_pack_h * 0.5)
		_clip_top.size = Vector2(_pack_w, split_y)
		_clip_top.pivot_offset = Vector2(_pack_w * 0.5, split_y)
		if _clip_bot != null and is_instance_valid(_clip_bot):
			_clip_bot.size = Vector2(_pack_w, _pack_h - split_y)
			_clip_bot.position = Vector2(0.0, split_y)
			_clip_bot.pivot_offset = Vector2(_pack_w * 0.5, 0.0)


func _park_pack_offscreen() -> void:
	if _pack_root == null or not is_instance_valid(_pack_root):
		return
	var screen: Vector2 = _overlay_area()
	var cx: float = screen.x * 0.5
	_pack_root.position = Vector2(cx - _pack_w * 0.5, screen.y + _pack_h + 40.0)
	_pack_root.scale = Vector2.ONE
	_pack_root.rotation = 0.0
	_pack_root.visible = false


func _prepare_pack_layout() -> void:
	for _i: int in range(3):
		var area: Vector2 = size
		if area.x >= 8.0 and area.y >= 8.0:
			break
		await get_tree().process_frame
	_compute_sizes()
	_apply_pack_display_size(_fit_pack_size(_pack_aspect))
	_park_pack_offscreen()
	if _pack_root != null and is_instance_valid(_pack_root):
		_pack_root.visible = true


func _stack_scale_for_pack() -> float:
	if _card_w <= 1.0 or _pack_w <= 1.0:
		return 0.28
	# Keep the facedown card clearly inside the scroll silhouette.
	return clampf((_pack_w * _STACK_IN_PACK_FRAC) / _card_w, 0.18, 0.45)


func _card_corner_radius() -> float:
	return maxf(4.0, _card_w * (_CARD_CORNER_RADIUS_REF / 150.0))


func _apply_card_rounded_clip(host: CanvasItem) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = _ROUNDED_CLIP
	mat.set_shader_parameter("corner_radius", _card_corner_radius())
	mat.set_shader_parameter("rect_size", Vector2(_card_w, _card_h))
	host.material = mat


func _compute_sizes() -> void:
	var s: Vector2 = _overlay_area()
	var max_by_w: float = s.x * 0.38
	var max_by_h: float = s.y * 0.72 * (150.0 / 210.0)
	_card_w = min(max_by_h, max_by_w)
	_card_h = _card_w * (210.0 / 150.0)

func _input(event: InputEvent) -> void:
	if _anim_done or not _skippable or not _dismiss_allowed:
		return
	if event is InputEventMouseButton:
		var mbe: InputEventMouseButton = event as InputEventMouseButton
		if mbe.pressed and mbe.button_index == MOUSE_BUTTON_LEFT:
			_skip_requested = true
	elif event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and ke.keycode == KEY_SPACE:
			_skip_requested = true

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.0, 0.0, 0.0, 0.0)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	var tex_path: String = SCROLL_TEX_PATH
	var pack_tex: Texture2D = null
	if ResourceLoader.exists(tex_path):
		pack_tex = load(tex_path) as Texture2D

	_pack_aspect = 160.0 / 220.0
	if pack_tex != null and pack_tex.get_height() > 0:
		_pack_aspect = float(pack_tex.get_width()) / float(pack_tex.get_height())
	var pack_sz: Vector2 = _fit_pack_size(_pack_aspect)
	_pack_tex = pack_tex

	_pack_root = Control.new()
	_pack_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pack_root.z_index = _PACK_Z
	_pack_root.clip_contents = true
	_pack_root.visible = false
	add_child(_pack_root)
	_apply_pack_display_size(pack_sz)
	_park_pack_offscreen()

	if USE_LEGACY_TEAR_OPENING:
		_build_legacy_tear_halves(pack_tex)
	else:
		_pack_img = TextureRect.new()
		_pack_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_pack_img.stretch_mode = TextureRect.STRETCH_SCALE
		_pack_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pack_img.texture = pack_tex
		_pack_root.add_child(_pack_img)
		_apply_pack_display_size(Vector2(_pack_w, _pack_h))


func _build_legacy_tear_halves(pack_tex: Texture2D) -> void:
	var split_y: float = floor(_pack_h * 0.5)
	var tex_w: float = float(pack_tex.get_width()) if pack_tex != null else 832.0
	var tex_h: float = float(pack_tex.get_height()) if pack_tex != null else 1216.0
	var tex_mid: float = floor(tex_h * 0.5)

	var atlas_top := AtlasTexture.new()
	atlas_top.atlas = pack_tex
	atlas_top.region = Rect2(0.0, 0.0, tex_w, tex_mid)
	atlas_top.filter_clip = true

	_clip_top = Control.new()
	_clip_top.size = Vector2(_pack_w, split_y)
	_clip_top.position = Vector2(0.0, 0.0)
	_clip_top.pivot_offset = Vector2(_pack_w * 0.5, split_y)
	_clip_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pack_root.add_child(_clip_top)

	var top_img := TextureRect.new()
	top_img.texture = atlas_top
	top_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_img.stretch_mode = TextureRect.STRETCH_SCALE
	top_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip_top.add_child(top_img)

	var atlas_bot := AtlasTexture.new()
	atlas_bot.atlas = pack_tex
	atlas_bot.region = Rect2(0.0, tex_mid, tex_w, tex_h - tex_mid)
	atlas_bot.filter_clip = true

	_clip_bot = Control.new()
	_clip_bot.size = Vector2(_pack_w, _pack_h - split_y)
	_clip_bot.position = Vector2(0.0, split_y)
	_clip_bot.pivot_offset = Vector2(_pack_w * 0.5, 0.0)
	_clip_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pack_root.add_child(_clip_bot)

	var bot_img := TextureRect.new()
	bot_img.texture = atlas_bot
	bot_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bot_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bot_img.stretch_mode = TextureRect.STRETCH_SCALE
	bot_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip_bot.add_child(bot_img)


func _run() -> void:
	if USE_LEGACY_TEAR_OPENING:
		await _run_legacy_tear_scroll()
		return
	await _run_shatter_scroll()


func _run_shatter_scroll() -> void:
	_card_tex = _load_union_tex(_union_name)

	await _prepare_pack_layout()

	var screen: Vector2 = _overlay_area()
	var cx: float = screen.x * 0.5
	var cy: float = screen.y * 0.5
	var pack_final_pos := Vector2(cx - _pack_w * 0.5, cy - _pack_h * 0.5)
	_pack_root.position = Vector2(cx - _pack_w * 0.5, screen.y + _pack_h + 40.0)
	_pack_root.scale = Vector2.ONE
	_pack_root.rotation = 0.0
	_pack_root.visible = true

	await _play_union_fanfare()

	var t1: Tween = create_tween().set_parallel(true)
	t1.tween_property(_bg, "color:a", 0.75, 0.35)
	t1.tween_property(_pack_root, "position:y", pack_final_pos.y, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t1.finished

	var stack_scale: float = _stack_scale_for_pack()
	var stack_pos := Vector2(cx - _card_w * 0.5, cy - _card_h * 0.5)
	var card_wrapper: Control = _make_flip_card_ctrl()
	card_wrapper.pivot_offset = Vector2(_card_w * 0.5, _card_h * 0.5)
	# Nested pose: same diagonal as the scroll, edge-on (looking at the card's side).
	card_wrapper.rotation = _SCROLL_CARD_ROT_RAD
	card_wrapper.scale = Vector2(stack_scale * _SCROLL_CARD_SIDE_X, stack_scale)
	card_wrapper.position = stack_pos
	card_wrapper.z_index = _CARD_STACK_Z
	add_child(card_wrapper)

	SFXManager.play(SFXManager.SFX_PACK_SHAKE)
	await _wiggle(_pack_root)

	SFXManager.play(SFXManager.SFX_PACK_TEAR_OFF)
	var shatter_rect := Rect2(_pack_root.position, Vector2(_pack_w, _pack_h))
	var shatter_tex: Texture2D = _pack_tex
	if shatter_tex == null and _pack_img != null:
		shatter_tex = _pack_img.texture
	PackShatterFx.shake_screen(self)

	# While the scroll shatters, stand the card upright and unflatten to face-on
	# (still at the small nested size — fan grows it next).
	var t_restore: Tween = create_tween().set_parallel(true)
	t_restore.tween_property(card_wrapper, "rotation", 0.0, _SCROLL_CARD_RESTORE_SEC) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t_restore.tween_property(
			card_wrapper, "scale", Vector2(stack_scale, stack_scale), _SCROLL_CARD_RESTORE_SEC) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Intact scroll stays until first triangle level is ready (Reckoning-style).
	await PackShatterFx.shatter_texture(
			self, shatter_tex, shatter_rect, PackShatterFx.SHATTER_LEVELS, _pack_root)
	if t_restore.is_valid() and t_restore.is_running():
		await t_restore.finished

	var card_y: float = cy - _card_h * 0.5
	var fan_pos := Vector2(cx - _card_w * 0.5, card_y)
	var t_fan: Tween = create_tween().set_parallel(true)
	t_fan.tween_property(card_wrapper, "position", fan_pos, FAN_MOVE_SEC) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t_fan.tween_property(card_wrapper, "scale", Vector2.ONE, FAN_MOVE_SEC) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t_fan.tween_property(card_wrapper, "rotation", 0.0, FAN_MOVE_SEC) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t_fan.tween_property(card_wrapper, "z_index", _CARD_FAN_Z, 0.01)
	await t_fan.finished

	await _flip_card_face_up(card_wrapper)
	_start_glow_pulse()

	await get_tree().create_timer(CARD_SETTLE_SECONDS).timeout
	_skip_requested = false
	_dismiss_allowed = true

	var elapsed: float = 0.0
	while elapsed < DISPLAY_HOLD_SECONDS and not _skip_requested:
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05

	_skip_requested = false
	_fade_out_union_fanfare(true)

	var dest: Vector2 = Vector2(screen.x + 60.0, -_card_h - 60.0)
	var t9: Tween = create_tween().set_parallel(true)
	t9.tween_property(card_wrapper, "position", dest, 0.48) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t9.tween_property(card_wrapper, "scale", Vector2.ZERO, 0.48) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t9.tween_property(_bg, "color:a", 0.0, 0.40)
	await t9.finished
	_finish_reveal()


func _make_flip_card_ctrl() -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(_card_w, _card_h)
	wrapper.size = Vector2(_card_w, _card_h)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.clip_contents = false

	var pad: float = maxf(_card_w, _card_h) * _GLOW_PAD_FRAC
	var glow := ColorRect.new()
	glow.color = Color(1, 1, 1, 1)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = 0
	glow.position = Vector2(-pad, -pad)
	glow.size = Vector2(_card_w + pad * 2.0, _card_h + pad * 2.0)
	var mat := ShaderMaterial.new()
	mat.shader = _REVEAL_GLOW_SHADER
	mat.set_shader_parameter("rect_size", glow.size)
	mat.set_shader_parameter("card_size", Vector2(_card_w, _card_h))
	mat.set_shader_parameter("corner_radius_px", _card_corner_radius())
	mat.set_shader_parameter("glow_color", _WHITE_GLOW)
	mat.set_shader_parameter("intensity", 0.0)
	mat.set_shader_parameter("glow_spread", maxf(_GLOW_SPREAD_MIN, pad * 0.9))
	mat.set_shader_parameter("rim_speed", 0.55)
	mat.set_shader_parameter("rim_pulse", 0.55)
	mat.set_shader_parameter("circuit_patrol", 1.0)
	glow.material = mat
	wrapper.add_child(glow)
	_glow_mat = mat

	var flip_host := Control.new()
	flip_host.size = Vector2(_card_w, _card_h)
	flip_host.pivot_offset = Vector2(_card_w * 0.5, _card_h * 0.5)
	flip_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flip_host.z_index = 1
	wrapper.add_child(flip_host)

	var back_img := TextureRect.new()
	back_img.size = Vector2(_card_w, _card_h)
	back_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back_img.stretch_mode = TextureRect.STRETCH_SCALE
	back_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_img.texture = _card_back_tex if _card_back_tex != null else _card_tex
	_apply_card_rounded_clip(back_img)
	flip_host.add_child(back_img)

	var front_img := TextureRect.new()
	front_img.size = Vector2(_card_w, _card_h)
	front_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	front_img.stretch_mode = TextureRect.STRETCH_SCALE
	front_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front_img.texture = _card_tex if _card_tex != null else load(FALLBACK_CARD_PATH) as Texture2D
	front_img.visible = false
	_apply_card_rounded_clip(front_img)
	flip_host.add_child(front_img)

	wrapper.set_meta("_flip_host", flip_host)
	wrapper.set_meta("_flip_back", back_img)
	wrapper.set_meta("_flip_front", front_img)
	return wrapper


func _flip_card_face_up(wrapper: Control) -> void:
	if wrapper == null or not is_instance_valid(wrapper):
		return
	var flip_host: Control = wrapper.get_meta("_flip_host") as Control
	var back_img: TextureRect = wrapper.get_meta("_flip_back") as TextureRect
	var front_img: TextureRect = wrapper.get_meta("_flip_front") as TextureRect
	if flip_host == null:
		return
	SFXManager.play(SFXManager.SFX_FLIP, SFXManager.SFX_FLIP_VOLUME)
	var tw1 := create_tween()
	tw1.tween_property(flip_host, "scale:x", 0.0, FLIP_HALF_SEC) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw1.finished
	if back_img != null and is_instance_valid(back_img):
		back_img.visible = false
	if front_img != null and is_instance_valid(front_img):
		front_img.visible = true
	var tw2 := create_tween()
	tw2.tween_property(flip_host, "scale:x", 1.0, FLIP_HALF_SEC) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw2.finished


## Legacy tear-apart scroll opening (suppressed when USE_LEGACY_TEAR_OPENING is false).
func _run_legacy_tear_scroll() -> void:
	_card_tex = _load_union_tex(_union_name)

	await _prepare_pack_layout()

	var screen: Vector2 = _overlay_area()
	var cx: float = screen.x * 0.5
	var cy: float = screen.y * 0.5

	var pack_final_pos := Vector2(cx - _pack_w * 0.5, cy - _pack_h * 0.5)
	_pack_root.position = Vector2(cx - _pack_w * 0.5, screen.y + _pack_h + 40.0)
	_pack_root.scale = Vector2.ONE
	_pack_root.rotation = 0.0
	_pack_root.visible = true

	await _play_union_fanfare()

	var t1: Tween = create_tween().set_parallel(true)
	t1.tween_property(_bg, "color:a", 0.75, 0.35)
	t1.tween_property(_pack_root, "position:y", pack_final_pos.y, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t1.finished

	await _wiggle(_pack_root)

	var t3: Tween = create_tween().set_parallel(true)
	t3.tween_property(_clip_top, "position:y", _clip_top.position.y - screen.y * 0.75, 0.52) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t3.tween_property(_clip_top, "position:x", _clip_top.position.x - 90.0, 0.52)
	t3.tween_property(_clip_top, "rotation", -0.55, 0.52)
	t3.tween_property(_clip_bot, "position:y", _clip_bot.position.y + screen.y * 0.75, 0.52) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t3.tween_property(_clip_bot, "position:x", _clip_bot.position.x + 90.0, 0.52)
	t3.tween_property(_clip_bot, "rotation", 0.55, 0.52)
	await t3.finished

	_pack_root.visible = false
	_spawn_debris(cx, cy)

	var card_y: float = cy - _card_h * 0.5
	var card_wrapper: Control = _make_card_ctrl(_union_name)
	card_wrapper.position = Vector2(cx - _card_w * 0.5, screen.y + 20.0)
	card_wrapper.scale = Vector2(0.5, 0.5)
	card_wrapper.pivot_offset = Vector2(_card_w * 0.5, _card_h * 0.5)
	card_wrapper.z_index = 2
	add_child(card_wrapper)

	var t5: Tween = create_tween().set_parallel(true)
	t5.tween_property(card_wrapper, "position:y", card_y, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t5.tween_property(card_wrapper, "scale", Vector2.ONE, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t5.finished

	await get_tree().create_timer(CARD_SETTLE_SECONDS).timeout
	_skip_requested = false
	_dismiss_allowed = true

	_start_glow_pulse()

	var elapsed: float = 0.0
	while elapsed < DISPLAY_HOLD_SECONDS and not _skip_requested:
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05

	_skip_requested = false
	_fade_out_union_fanfare(true)

	var dest: Vector2 = Vector2(screen.x + 60.0, -_card_h - 60.0)
	var t9: Tween = create_tween().set_parallel(true)
	t9.tween_property(card_wrapper, "position", dest, 0.48) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t9.tween_property(card_wrapper, "scale", Vector2.ZERO, 0.48) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t9.tween_property(_bg, "color:a", 0.0, 0.40)
	await t9.finished

	_finish_reveal()


func _finish_reveal() -> void:
	if _anim_done:
		return
	_anim_done = true
	# If dismiss already started a fanfare fade, let that callback restore BGM.
	if _fanfare_player != null and is_instance_valid(_fanfare_player):
		_fade_out_union_fanfare(true)
	reveal_finished.emit()
	queue_free()


func _exit_tree() -> void:
	# Safety net: fade callbacks that captured this overlay can die on queue_free.
	if _should_restore_bgm and not _bgm_restored and BGMManager.has_suspended():
		_bgm_restored = true
		BGMManager.resume_suspended(BGM_FADE_IN_AFTER_FANFARE)

# ──────────────────────────────────────────────────────────────────────────────
# Opening audio (union fanfare + settle sparkle)
# ──────────────────────────────────────────────────────────────────────────────
func _play_union_fanfare() -> void:
	_bgm_restored = false
	_stop_union_fanfare_immediate()
	await BGMManager.suspend_current(BGM_FADE_OUT_BEFORE_FANFARE)
	if not is_instance_valid(self):
		return
	if not ResourceLoader.exists(FANFARE_UNION_PATH):
		_restore_bgm_after_fanfare()
		return
	var stream: AudioStream = load(FANFARE_UNION_PATH) as AudioStream
	if stream == null:
		_restore_bgm_after_fanfare()
		return
	_disable_stream_loop(stream)
	_fanfare_player = AudioStreamPlayer.new()
	_fanfare_player.stream = stream
	_fanfare_player.bus = &"Music"
	_fanfare_player.volume_db = -80.0
	add_child(_fanfare_player)
	_fanfare_player.play()
	_fanfare_player.finished.connect(_on_fanfare_finished, CONNECT_ONE_SHOT)
	if _fanfare_tween and _fanfare_tween.is_valid():
		_fanfare_tween.kill()
	_fanfare_tween = create_tween()
	_fanfare_tween.tween_property(_fanfare_player, "volume_db", 0.0, FANFARE_FADE_IN_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _disable_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = false
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED

func _fade_out_union_fanfare(restore_bgm: bool = true) -> void:
	if not restore_bgm:
		_should_restore_bgm = false
	if _fanfare_player == null or not is_instance_valid(_fanfare_player):
		_fanfare_player = null
		if restore_bgm:
			_restore_bgm_after_fanfare()
		return
	if _fanfare_tween and _fanfare_tween.is_valid():
		_fanfare_tween.kill()
	var player: AudioStreamPlayer = _fanfare_player
	_fanfare_player = null
	if player.finished.is_connected(_on_fanfare_finished):
		player.finished.disconnect(_on_fanfare_finished)
	if not player.playing:
		player.queue_free()
		if restore_bgm:
			_restore_bgm_after_fanfare()
		return
	if player.get_parent() == self:
		remove_child(player)
		var host: Node = get_tree().root if get_tree() != null else null
		if host != null:
			host.add_child(player)
		else:
			player.queue_free()
			if restore_bgm:
				_restore_bgm_after_fanfare()
			return
	# Do not capture `self` — overlay may be freed before this fires.
	var should_restore: bool = restore_bgm
	var fade_in_sec: float = BGM_FADE_IN_AFTER_FANFARE
	var tw: Tween = player.create_tween()
	tw.tween_property(player, "volume_db", -80.0, FANFARE_FADE_OUT_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
		if should_restore:
			BGMManager.resume_suspended(fade_in_sec))

func _stop_union_fanfare_immediate() -> void:
	if _fanfare_tween and _fanfare_tween.is_valid():
		_fanfare_tween.kill()
	_fanfare_tween = null
	if _fanfare_player != null and is_instance_valid(_fanfare_player):
		if _fanfare_player.finished.is_connected(_on_fanfare_finished):
			_fanfare_player.finished.disconnect(_on_fanfare_finished)
		_fanfare_player.stop()
		_fanfare_player.queue_free()
	_fanfare_player = null

func _on_fanfare_finished() -> void:
	if not is_instance_valid(self):
		return
	if _fanfare_player != null and is_instance_valid(_fanfare_player):
		_fanfare_player.queue_free()
	_fanfare_player = null
	_restore_bgm_after_fanfare()

func _restore_bgm_after_fanfare() -> void:
	if _bgm_restored or not _should_restore_bgm:
		return
	if not BGMManager.has_suspended():
		_bgm_restored = true
		return
	_bgm_restored = true
	BGMManager.resume_suspended(BGM_FADE_IN_AFTER_FANFARE)

func _wiggle(ctrl: Control) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(ctrl, "rotation", -0.08, 0.11)
	tw.tween_property(ctrl, "rotation", 0.08, 0.11)
	tw.tween_property(ctrl, "rotation", -0.10, 0.09)
	tw.tween_property(ctrl, "rotation", 0.10, 0.09)
	tw.tween_property(ctrl, "rotation", 0.00, 0.07)
	await tw.finished

func _spawn_debris(cx: float, cy: float) -> void:
	const DURATION: float = 1.45
	const FADE_DELAY: float = 0.85
	const FADE_DURATION: float = 0.65
	var palette: Array[Color] = [
		Color(0.95, 0.95, 1.0),
		Color(0.85, 0.88, 1.0),
		Color(0.78, 0.82, 0.95),
		Color(0.92, 0.92, 0.98),
	]
	for _i: int in range(14):
		var scrap := ColorRect.new()
		var sw: float = randf_range(9.0, 24.0)
		var sh: float = randf_range(5.0, 12.0)
		scrap.size = Vector2(sw, sh)
		scrap.position = Vector2(cx - sw * 0.5, cy - sh * 0.5)
		scrap.color = palette[randi() % palette.size()]
		scrap.rotation = randf_range(-PI, PI)
		scrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scrap.z_index = 1
		add_child(scrap)
		var angle: float = randf_range(0.0, TAU)
		var dist: float = randf_range(160.0, 380.0)
		var dest: Vector2 = Vector2(
			scrap.position.x + cos(angle) * dist,
			scrap.position.y + sin(angle) * dist
		)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(scrap, "position", dest, DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(scrap, "color:a", 0.0, FADE_DURATION).set_delay(FADE_DELAY)
		var captured: ColorRect = scrap
		tw.finished.connect(func() -> void: captured.queue_free())

func _make_card_ctrl(card_name: String) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(_card_w, _card_h)
	wrapper.size = Vector2(_card_w, _card_h)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var glow_panel := Panel.new()
	glow_panel.size = Vector2(_card_w, _card_h)
	glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gp_sb := StyleBoxFlat.new()
	gp_sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	gp_sb.draw_center = true
	gp_sb.shadow_color = _WHITE_GLOW
	gp_sb.shadow_size = int(_card_h * 0.035)
	gp_sb.shadow_offset = Vector2.ZERO
	glow_panel.add_theme_stylebox_override("panel", gp_sb)
	wrapper.add_child(glow_panel)
	_glow_sb = gp_sb

	var card_img := TextureRect.new()
	card_img.size = Vector2(_card_w, _card_h)
	card_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_img.stretch_mode = TextureRect.STRETCH_SCALE
	card_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_img.texture = _card_tex if _card_tex != null else load(FALLBACK_CARD_PATH) as Texture2D
	_apply_card_rounded_clip(card_img)
	wrapper.add_child(card_img)
	return wrapper

func _start_glow_pulse() -> void:
	if _glow_mat != null and is_instance_valid(_glow_mat):
		_glow_mat.set_shader_parameter("circuit_patrol", 1.0)
		_glow_mat.set_shader_parameter("rim_pulse", 0.55)
		var tw: Tween = create_tween().set_loops()
		tw.tween_method(
			func(v: float) -> void:
				if _glow_mat != null and is_instance_valid(_glow_mat):
					_glow_mat.set_shader_parameter("intensity", v),
			0.48, 0.78, 0.70
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_method(
			func(v: float) -> void:
				if _glow_mat != null and is_instance_valid(_glow_mat):
					_glow_mat.set_shader_parameter("intensity", v),
			0.78, 0.48, 0.70
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		return
	if _glow_sb == null:
		return
	var lo: float = _card_h * 0.028
	var hi: float = _card_h * 0.048
	var tw2: Tween = create_tween().set_loops()
	tw2.tween_method(
		func(v: float) -> void: _glow_sb.shadow_size = int(v),
		lo, hi, 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw2.tween_method(
		func(v: float) -> void: _glow_sb.shadow_size = int(v),
		hi, lo, 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _load_union_tex(card_name: String) -> Texture2D:
	if card_name.is_empty():
		return load(FALLBACK_CARD_PATH) as Texture2D
	var snake: String = card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
	if SaveManager.nsfw_enabled:
		var nsfw_path: String = FULL_CARDS_DIR + snake + "_nsfw.png"
		if ResourceLoader.exists(nsfw_path):
			return load(nsfw_path) as Texture2D
	var path: String = FULL_CARDS_DIR + snake + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return load(FALLBACK_CARD_PATH) as Texture2D
