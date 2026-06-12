extends Control
class_name UnionScrollOpeningOverlay

const SCROLL_TEX_PATH: String = "res://assets/textures/inventory/ui_union_scroll.png"
const FALLBACK_CARD_PATH: String = "res://assets/textures/cards/frames/vellum_card_frame_full.png"
const FULL_CARDS_DIR: String = "res://assets/textures/cards/full_cards/"
const DISPLAY_HOLD_SECONDS: float = 30.0
const CARD_SETTLE_SECONDS: float = 0.2
const _ROUNDED_CLIP: Shader = preload("res://assets/shaders/rounded_clip.gdshader")
const _CARD_CORNER_RADIUS_REF: float = 16.0
const _WHITE_GLOW: Color = Color(1.0, 1.0, 1.0, 0.72)

var _union_name: String = ""
var _pack_w: float = 0.0
var _pack_h: float = 0.0
var _card_w: float = 0.0
var _card_h: float = 0.0
var _skip_requested: bool = false
var _skippable: bool = true
var _dismiss_allowed: bool = false
var _anim_done: bool = false
var _glow_sb: StyleBoxFlat = null
var _card_tex: Texture2D = null

var _bg: ColorRect = null
var _pack_root: Control = null
var _clip_top: Control = null
var _clip_bot: Control = null

static func open(parent: Node, union_name: String, skippable: bool = true) -> void:
	var overlay := UnionScrollOpeningOverlay.new()
	overlay._union_name = union_name if union_name != null else ""
	overlay._skippable = skippable
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 50
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)

func _ready() -> void:
	_compute_sizes()
	_build_ui()
	_run.call_deferred()

func _compute_sizes() -> void:
	var s: Vector2 = get_viewport_rect().size
	var max_by_w: float = s.x * 0.42
	var max_by_h: float = s.y * 0.78 * (150.0 / 210.0)
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

	var s: Vector2 = get_viewport_rect().size
	_pack_h = s.y * 0.84
	if pack_tex != null:
		_pack_w = _pack_h * (float(pack_tex.get_width()) / float(pack_tex.get_height()))
	else:
		_pack_w = _pack_h * (160.0 / 220.0)

	_pack_root = Control.new()
	_pack_root.custom_minimum_size = Vector2(_pack_w, _pack_h)
	_pack_root.size = Vector2(_pack_w, _pack_h)
	_pack_root.pivot_offset = Vector2(_pack_w * 0.5, _pack_h * 0.5)
	_pack_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pack_root)

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
	_card_tex = _load_union_tex(_union_name)

	var screen: Vector2 = get_viewport_rect().size
	var cx: float = screen.x * 0.5
	var cy: float = screen.y * 0.5

	var pack_final_pos := Vector2(cx - _pack_w * 0.5, cy - _pack_h * 0.5)
	_pack_root.position = Vector2(cx - _pack_w * 0.5, screen.y + 40.0)

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

	var dest: Vector2 = Vector2(screen.x + 60.0, -_card_h - 60.0)
	var t9: Tween = create_tween().set_parallel(true)
	t9.tween_property(card_wrapper, "position", dest, 0.48) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t9.tween_property(card_wrapper, "scale", Vector2.ZERO, 0.48) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t9.tween_property(_bg, "color:a", 0.0, 0.40)
	await t9.finished

	_anim_done = true
	queue_free()

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
	var rc_mat := ShaderMaterial.new()
	rc_mat.shader = _ROUNDED_CLIP
	rc_mat.set_shader_parameter("corner_radius", max(6.0, _card_w * (_CARD_CORNER_RADIUS_REF / 150.0)))
	card_img.material = rc_mat
	wrapper.add_child(card_img)
	return wrapper

func _start_glow_pulse() -> void:
	if _glow_sb == null:
		return
	var lo: float = _card_h * 0.028
	var hi: float = _card_h * 0.048
	var tw: Tween = create_tween().set_loops()
	tw.tween_method(
		func(v: float) -> void: _glow_sb.shadow_size = int(v),
		lo, hi, 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(
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
