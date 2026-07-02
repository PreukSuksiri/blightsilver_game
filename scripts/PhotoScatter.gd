extends Control
class_name PhotoScatter

# ── Asset paths ───────────────────────────────────────────────
const PHOTOS: PackedStringArray = [
	"res://assets/textures/demo_photo_scatter/scatter1.png",
	"res://assets/textures/demo_photo_scatter/scatter2.png",
	"res://assets/textures/demo_photo_scatter/scatter3.png",
	"res://assets/textures/demo_photo_scatter/scatter4.png",
	"res://assets/textures/demo_photo_scatter/scatter5.png",
]
const BGM_PATH:      String = "res://assets/audio/bgm_ost_blind_cross.mp3"
const CREDITS_SCENE: String = "res://scenes/credit_demo.tscn"
const WISHLIST_MINI_PATH: String = "res://assets/textures/ui/decorations/wishlist_now_mini.png"
const WISHLIST_MINI_MAX_WIDTH_RATIO: float = 0.11
const WISHLIST_MINI_MARGIN: float = 28.0
const WISHLIST_MINI_FADE_IN: float = 1.0

# ── Final resting positions (offset from screen centre) ───────
const OFFSET_X: PackedFloat32Array  = [-370.0,  170.0, -120.0,  350.0,  20.0]
const OFFSET_Y: PackedFloat32Array  = [ -120.0, -230.0,  160.0,   90.0, 280.0]
const ROTATIONS: PackedFloat32Array = [  -14.0,    9.0,  19.0,  -22.0,   5.0]
const Z_INDICES: PackedInt32Array   = [      2,      3,     4,      1,     5]

# ── Entry directions (each photo flies in from a different edge) ──
const ENTRY_X: PackedFloat32Array = [-1.0,  0.4, -1.0,  1.0,  0.1]
const ENTRY_Y: PackedFloat32Array = [-0.5, -1.0,  0.6,  0.3,  1.0]

# ── Polaroid frame dimensions (landscape, matching the reference) ──────────
# PAD_EDGE = equal border on left, right, and top
# PAD_BOTTOM = thick white footer — the Polaroid signature
const FRAME_W: float    = 440.0
const FRAME_H: float    = 350.0
const PAD_EDGE: float   = 20.0   # equal margin: left, right, top
const PAD_BOTTOM: float = 84.0   # thick bottom footer

# ── Timing ────────────────────────────────────────────────────
const DROP_STAGGER: float   = 0.55   # delay between each photo drop
const DROP_DURATION: float  = 0.60   # flight time per photo

const HOLD_DURATION: float  = 3.5    # pause after all photos land
const FADE_OUT: float       = 1.8    # screen + BGM fade-out duration

# last photo lands at: (PHOTOS.size()-1)*DROP_STAGGER + DROP_DURATION
# = 4*0.55 + 0.60 = 2.80 s
const ALL_LANDED: float = 2.80

# ── Zoom ──────────────────────────────────────────────────────
# Camera starts zoomed in and slowly pulls back until all photos settled
const ZOOM_START: float = 1.35   # initial scale (35% zoomed in)
const ZOOM_END: float   = 1.0    # final scale (normal)
const ZOOM_DURATION: float = ALL_LANDED + 0.4   # finishes just after last drop

# ── Internal nodes ────────────────────────────────────────────
var _bgm:          AudioStreamPlayer = null
var _fade_overlay: ColorRect         = null
var _content:      Control           = null   # zoom container
var _wishlist_mini: TextureRect      = null


func _ready() -> void:
	_build_background()
	_build_content_layer()
	_start_bgm()
	_drop_photos()
	_start_zoom_out()
	_schedule_outro()


# ── Table background ───────────────────────────────────────────
func _build_background() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tex: Variant = load("res://assets/textures/ui/backgrounds/bg_demo_photo_table_2.png")
	bg.texture = tex
	add_child(bg)


# ── Content layer — photos go here so zoom doesn't affect overlay ──
func _build_content_layer() -> void:
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_content)


# ── Slow zoom-out from ZOOM_START → 1.0 while photos drop ─────
func _start_zoom_out() -> void:
	await get_tree().process_frame
	_content.pivot_offset = size / 2.0
	_content.scale        = Vector2(ZOOM_START, ZOOM_START)

	var tw := create_tween()
	tw.tween_property(_content, "scale", Vector2(ZOOM_END, ZOOM_END), ZOOM_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUAD)


# ── BGM: play immediately at full volume ──────────────────────
func _start_bgm() -> void:
	var stream: Variant = load(BGM_PATH)
	_bgm = AudioStreamPlayer.new()
	_bgm.name      = "PhotoScatterBGM"
	_bgm.stream    = stream
	_bgm.volume_db = 0.0
	_bgm.autoplay  = false
	add_child(_bgm)
	_bgm.play()


# ── Spawn and animate all 5 Polaroids ─────────────────────────
func _drop_photos() -> void:
	await get_tree().process_frame
	var center: Vector2     = size / 2.0
	var offscreen: float    = max(size.x, size.y) * 1.4
	var pivot_half: Vector2 = Vector2(FRAME_W / 2.0, FRAME_H / 2.0)

	for i: int in range(PHOTOS.size()):
		var final_pos: Vector2  = center + Vector2(OFFSET_X[i], OFFSET_Y[i]) - pivot_half
		var final_rot: float    = ROTATIONS[i]
		var entry: Vector2      = Vector2(ENTRY_X[i], ENTRY_Y[i])
		var start_pos: Vector2  = final_pos + entry * offscreen
		var start_rot: float    = final_rot + entry.x * 45.0 + entry.y * 15.0

		var pivot := Control.new()
		pivot.custom_minimum_size = Vector2(FRAME_W, FRAME_H)
		pivot.size                = Vector2(FRAME_W, FRAME_H)
		pivot.pivot_offset        = pivot_half
		pivot.position            = start_pos
		pivot.rotation_degrees    = start_rot
		pivot.z_index             = Z_INDICES[i]
		_content.add_child(pivot)

		_build_polaroid(pivot, PHOTOS[i])
		_animate_drop(pivot, i, final_pos, final_rot)


# ── Build one Polaroid card ────────────────────────────────────
func _build_polaroid(pivot: Control, photo_path: String) -> void:
	var tex: Variant = load(photo_path)
	var card := _PolaroidCard.new()
	card.setup(tex as Texture2D, FRAME_W, FRAME_H, PAD_EDGE, PAD_BOTTOM)
	pivot.add_child(card)


# ── Tween one photo from off-screen to its resting place ──────
func _animate_drop(
		pivot: Control,
		idx: int,
		final_pos: Vector2,
		final_rot: float
) -> void:
	var delay: float = idx * DROP_STAGGER

	var tw_pos := create_tween()
	tw_pos.tween_interval(delay)
	tw_pos.tween_property(pivot, "position", final_pos, DROP_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)

	var tw_rot := create_tween()
	tw_rot.tween_interval(delay)
	tw_rot.tween_property(pivot, "rotation_degrees", final_rot, DROP_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)


# ── Outro: hold → fade out BGM + screen → go to credits ───────
func _schedule_outro() -> void:
	_fade_in_wishlist_mini()

	# "To be continued . . ." — fades in when all photos have settled
	var label := Label.new()
	label.text                  = "To be continued . . ."
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.z_index               = 50
	label.modulate              = Color(1.0, 1.0, 1.0, 0.0)
	label.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	add_child(label)

	var tw_text := create_tween()
	tw_text.tween_interval(ALL_LANDED)
	tw_text.tween_property(label, "modulate:a", 1.0, 1.0) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUAD)

	# Black overlay sitting on top of everything, starts transparent
	_fade_overlay = ColorRect.new()
	_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.color   = Color(0.0, 0.0, 0.0, 0.0)
	_fade_overlay.z_index = 100
	add_child(_fade_overlay)

	var outro_start: float    = ALL_LANDED + HOLD_DURATION
	var text_fade_out: float  = 1.2   # text fades out first
	var screen_start: float   = outro_start + text_fade_out

	# Text fade-out
	var tw_text_out := create_tween()
	tw_text_out.tween_interval(outro_start)
	tw_text_out.tween_property(label, "modulate:a", 0.0, text_fade_out) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_QUAD)

	# Screen fade-out (after text is gone)
	var tw_screen := create_tween()
	tw_screen.tween_interval(screen_start)
	tw_screen.tween_property(_fade_overlay, "color", Color(0.0, 0.0, 0.0, 1.0), FADE_OUT) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_QUAD)

	# Scene change after screen fade completes
	var tw_change := create_tween()
	tw_change.tween_interval(screen_start + FADE_OUT)
	tw_change.tween_callback(_go_to_credits)


func _fade_in_wishlist_mini() -> void:
	await get_tree().process_frame
	var tex: Texture2D = load(WISHLIST_MINI_PATH) as Texture2D
	if tex == null:
		return

	var nat: Vector2 = tex.get_size()
	if nat.x <= 0.0:
		return

	var display_w: float = size.x * WISHLIST_MINI_MAX_WIDTH_RATIO
	var display_h: float = display_w * nat.y / nat.x

	_wishlist_mini = TextureRect.new()
	_wishlist_mini.texture = tex
	_wishlist_mini.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wishlist_mini.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_wishlist_mini.custom_minimum_size = Vector2(display_w, display_h)
	_wishlist_mini.size = Vector2(display_w, display_h)
	_wishlist_mini.position = Vector2(
		size.x - display_w - WISHLIST_MINI_MARGIN,
		WISHLIST_MINI_MARGIN
	)
	_wishlist_mini.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_wishlist_mini.z_index = 60
	_wishlist_mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wishlist_mini)

	var tw := create_tween()
	tw.tween_interval(ALL_LANDED)
	tw.tween_property(_wishlist_mini, "modulate:a", 1.0, WISHLIST_MINI_FADE_IN) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUAD)


func _go_to_credits() -> void:
	# Reparent BGM to root so it survives the scene change
	_bgm.reparent(get_tree().root)
	get_tree().change_scene_to_file(CREDITS_SCENE)


# ── Polaroid card drawn entirely via Canvas API ────────────────
# Bypasses the Control layout system so size is always exact and
# rotation works correctly (no screen-aligned clip rect issues).
class _PolaroidCard extends Control:
	var _tex:   Texture2D = null
	var _pad_e: float     = 0.0   # equal border: left, right, top
	var _pad_b: float     = 0.0   # thick bottom footer

	func setup(tex: Texture2D, fw: float, fh: float, pe: float, pb: float) -> void:
		_tex   = tex
		_pad_e = pe
		_pad_b = pb
		custom_minimum_size = Vector2(fw, fh)
		size                = Vector2(fw, fh)

	func _draw() -> void:
		var fw: float = size.x
		var fh: float = size.y
		# Soft drop-shadow (layered semi-transparent rects, offset down-right)
		for i: int in range(12, 0, -1):
			var fi: float = float(i)
			draw_rect(Rect2(fi * 0.5 + 2.0, fi * 0.9 + 3.0, fw, fh),
					Color(0.0, 0.0, 0.0, 0.04 * fi))
		# White polaroid frame
		draw_rect(Rect2(0.0, 0.0, fw, fh), Color(0.97, 0.96, 0.93))
		# Photo — cover mode: fills the photo area exactly, crops if needed,
		# so left/right/top borders are always equal width.
		if _tex == null:
			return
		var pw: float   = fw - _pad_e * 2.0
		var ph: float   = fh - _pad_e - _pad_b
		var ts: Vector2 = _tex.get_size()
		var sc: float   = maxf(pw / ts.x, ph / ts.y)
		var src_w: float = pw / sc
		var src_h: float = ph / sc
		var src_x: float = (ts.x - src_w) * 0.5
		var src_y: float = (ts.y - src_h) * 0.5
		draw_texture_rect_region(_tex,
				Rect2(_pad_e, _pad_e, pw, ph),
				Rect2(src_x, src_y, src_w, src_h))
