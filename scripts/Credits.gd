extends Control

const BG_TEXTURE      := preload("res://assets/textures/ui/backgrounds/bg_ending_1.png")
const BGM_STREAM      := preload("res://assets/audio/bgm_ost_blind_cross.mp3")
const CHIVO_FONT      := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")
const MPLUS_FONT      := preload("res://assets/fonts/MPLUS1p-ExtraBold.ttf")
const LOGO_TEXTURE    := preload("res://assets/textures/ui/decorations/ui_logo_quiet_eve.png")
const SHADER_LANTERN  := preload("res://assets/shaders/bg_lantern_glow.gdshader")
const SHADER_SILHOUETTE := preload("res://assets/shaders/silhouette.gdshader")
const SHADER_OUTLINE  := preload("res://assets/shaders/logo_outline.gdshader")

const LOGO_W := 840.0
const LOGO_H := 420.0

const SCROLL_SPEED  := 50.0   # pixels per second — increase to scroll faster
const FADE_DURATION := 1.5

const CREDITS_TEXT := \
"ORIGINAL SOUNDTRACK

\"Blind Cross ● 盲目の十字架を抱いて\"




DIRECTED BY

Preuk Suksiri




GAME DESIGN

Preuk Suksiri




DEVELOPED BY

Preuk Suksiri




STORY BY

Preuk Suksiri




DIALOGUES BY

Preuk Suksiri




ART DIRECTOR

Preuk Suksiri




VISUAL ARTS

Anifusion




CARD ILLUSTRATIONS

Anifusion
Grok Imagine




MUSIC & SOUND DIRECTOR

Preuk Suksiri




GAME MUSICS

Suno




SOUND EFFECTS

Eleven Lab




FONTS

Coji Morishita
Omnibus-Type




MARKETING DIRECTOR

Preuk Suksiri




GAME ENGINE

Godot




GAME TESTERS

james3ds
ozzygen
luciferlight




SPECIAL THANKS

Everyone who believed.




Thank you for playing
<img=./assets/textures/ui/decorations/decor_game_title_text.png>



Quiet Eve Studio Presents
<img=./assets/textures/ui/decorations/ui_logo_quiet_eve.png>


"

var _scroll_label: RichTextLabel
var _logo_node: Control
var _logo_y:    float = 0.0
var _bgm: AudioStreamPlayer
var _fade: ColorRect
var _is_ending: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP

	# ── Background ───────────────────────────────────────────────
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture      = BG_TEXTURE
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── Dark overlay for text readability ────────────────────────
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.01)
	dimmer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(dimmer)

	# ── Clip container — center column ───────────────────────────
	var vp_size := get_viewport_rect().size
	var clip := Control.new()
	clip.clip_contents = true
	clip.mouse_filter  = MOUSE_FILTER_IGNORE
	clip.set_anchors_preset(Control.PRESET_CENTER)
	clip.offset_left   = -420.0
	clip.offset_top    = -vp_size.y * 0.5
	clip.offset_right  =  420.0
	clip.offset_bottom =  vp_size.y * 0.5
	add_child(clip)

	# ── Scrolling credits label (RichTextLabel for BBCode + image support) ──
	_scroll_label = RichTextLabel.new()
	_scroll_label.bbcode_enabled  = true
	_scroll_label.fit_content     = true
	_scroll_label.scroll_active   = false
	_scroll_label.size            = Vector2(840.0, 0.0)
	_scroll_label.add_theme_font_override("normal_font", CHIVO_FONT)
	_scroll_label.add_theme_font_size_override("normal_font_size", 36)
	_scroll_label.add_theme_color_override("default_color", Color(0.92, 0.95, 1.0))
	_scroll_label.add_theme_constant_override("line_separation", 8)
	_scroll_label.mouse_filter = MOUSE_FILTER_IGNORE
	# Convert <img=./path> tags to BBCode [img]res://path[/img] and center everything
	var processed := CREDITS_TEXT
	# Convert <img=./path> → [img width=320]res://path[/img]
	var img_regex := RegEx.new()
	img_regex.compile("<img=\\./(.*?)>")
	for m: RegExMatch in img_regex.search_all(CREDITS_TEXT):
		var img_path: String = m.get_string(1)
		if "ui_logo_quiet_eve" in img_path:
			# Studio logo rendered as separate shader node — remove from text
			processed = processed.replace(m.get_string(0), "")
		else:
			processed = processed.replace(m.get_string(0),
				"[img width=840]res://" + img_path + "[/img]")
	# Wrap Japanese subtitle in MPLUS ExtraBold
	processed = processed.replace(
		"盲目の十字架を抱いて",
		"[font=res://assets/fonts/MPLUS1p-ExtraBold.ttf]盲目の十字架を抱いて[/font]")
	_scroll_label.text = "[center]" + processed + "[/center]"
	clip.add_child(_scroll_label)

	# ── Fade overlay — added BEFORE the process_frame await so the first
	#    rendered frame is always fully black (prevents flash of background)
	_fade = ColorRect.new()
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_fade)

	# Wait one frame so the label calculates its height, then place below screen
	await get_tree().process_frame
	_scroll_label.position.y = vp_size.y
	# Studio logo starts just below the end of the text
	var text_h := maxf(_scroll_label.size.y, _scroll_label.get_combined_minimum_size().y)
	_logo_y = vp_size.y + text_h + 80.0
	_build_shader_logo(vp_size)

	# ── BGM ───────────────────────────────────────────────────────
	_bgm = AudioStreamPlayer.new()
	_bgm.stream = BGM_STREAM
	_bgm.bus = &"Music"
	(_bgm.stream as AudioStreamMP3).loop = true
	add_child(_bgm)
	_bgm.play()

	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.0, FADE_DURATION).set_trans(Tween.TRANS_SINE)

	# ── Skip hint ─────────────────────────────────────────────────
	var hint := Label.new()
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_left   = -320.0
	hint.offset_top    = -36.0
	hint.offset_right  = -16.0
	hint.offset_bottom = -8.0
	hint.text = "Press Esc or click to skip"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_override("font", CHIVO_FONT)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 0.5))
	hint.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(hint)

func _process(delta: float) -> void:
	if _is_ending or _scroll_label == null:
		return
	_scroll_label.position.y -= SCROLL_SPEED * delta
	# Scroll shader logo at the same speed
	if _logo_node != null:
		_logo_y -= SCROLL_SPEED * delta
		_logo_node.position.y = _logo_y
		# End when the logo has scrolled fully off the top
		if _logo_y + LOGO_H < 0.0:
			_end_credits()
	else:
		# Fallback if logo never built
		var content_h := maxf(_scroll_label.size.y, _scroll_label.get_combined_minimum_size().y)
		if _scroll_label.position.y + content_h < 0.0:
			_end_credits()

func _input(event: InputEvent) -> void:
	if _is_ending:
		return
	var skip := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			skip = true
	if event is InputEventMouseButton and event.pressed:
		skip = true
	if skip:
		get_viewport().set_input_as_handled()
		_end_credits()

func _end_credits() -> void:
	if _is_ending:
		return
	_is_ending = true
	if _bgm:
		var btween := create_tween()
		btween.tween_property(_bgm, "volume_db", -40.0, FADE_DURATION)
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_DURATION).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _build_shader_logo(vp_size: Vector2) -> void:
	# Root container — horizontally centered, Y tracked by _logo_y
	_logo_node = Control.new()
	_logo_node.size         = Vector2(LOGO_W, LOGO_H)
	_logo_node.position     = Vector2((vp_size.x - LOGO_W) * 0.5, _logo_y)
	_logo_node.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_logo_node)

	# ── BgGlow: radial lantern bloom behind logo ───────────────
	var bg_mat := ShaderMaterial.new()
	bg_mat.shader = SHADER_LANTERN
	var bg_glow := ColorRect.new()
	bg_glow.set_anchors_preset(Control.PRESET_CENTER)
	bg_glow.offset_left   = -LOGO_W
	bg_glow.offset_top    = -LOGO_H
	bg_glow.offset_right  =  LOGO_W
	bg_glow.offset_bottom =  LOGO_H
	bg_glow.material      = bg_mat
	bg_glow.color         = Color.WHITE
	bg_glow.mouse_filter  = MOUSE_FILTER_IGNORE
	_logo_node.add_child(bg_glow)

	# ── LogoShadow: silhouette glow, offset slightly ───────────
	var sil_mat := ShaderMaterial.new()
	sil_mat.shader = SHADER_SILHOUETTE
	var shadow := TextureRect.new()
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.offset_left   = 4.0
	shadow.offset_top    = 4.0
	shadow.offset_right  = 4.0
	shadow.offset_bottom = 4.0
	shadow.material      = sil_mat
	shadow.texture       = LOGO_TEXTURE
	shadow.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
	shadow.mouse_filter  = MOUSE_FILTER_IGNORE
	_logo_node.add_child(shadow)

	# ── Logo: outline shader on top ────────────────────────────
	var out_mat := ShaderMaterial.new()
	out_mat.shader = SHADER_OUTLINE
	var logo := TextureRect.new()
	logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo.material    = out_mat
	logo.texture     = LOGO_TEXTURE
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.mouse_filter = MOUSE_FILTER_IGNORE
	_logo_node.add_child(logo)
