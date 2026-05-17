extends Control

# ──────────────────────────────────────────────────────────────────────────────
# PackOpeningOverlay — standalone booster-pack opening animation.
#
# Usage (callable from anywhere):
#   PackOpeningOverlay.open(get_tree().root, "Aether Warden", "Radar", "Bunker")
#
# Any null / empty / unrecognised card name shows the fallback vellum frame.
# The overlay blocks all input during the animation.
# Clicking / Space skips the display wait and triggers the fly-off immediately.
# ──────────────────────────────────────────────────────────────────────────────

const PACK_TEX_PATH     : String = "res://assets/textures/cards/booster_pack/booster_pack_basic.png"
const FALLBACK_CARD_PATH: String = "res://assets/textures/cards/frames/vellum_card_frame_full.png"
const FULL_CARDS_DIR    : String = "res://assets/textures/cards/full_cards/"

const PACK_W  : float = 160.0
const PACK_H  : float = 220.0
const CARD_W  : float = 150.0
const CARD_H  : float = 210.0
const CARD_GAP: float = 16.0

# ── State ──────────────────────────────────────────────────────────────────────
var _card_names     : Array[String] = []
var _pack_image_path: String        = ""   # overrides PACK_TEX_PATH when non-empty
var _skip_requested : bool          = false
var _anim_done      : bool          = false
var _glow_sbs       : Array         = [null, null, null]  # StyleBoxFlat refs

# ── Scene nodes ───────────────────────────────────────────────────────────────
var _bg       : ColorRect = null
var _pack_root: Control   = null
var _clip_top : Control   = null
var _clip_bot : Control   = null

# ──────────────────────────────────────────────────────────────────────────────
# Static entry point
# pack_image: res:// path to the pack illustration (empty = use default)
# card1/2/3 : card names (empty / invalid = shows fallback vellum frame)
# ──────────────────────────────────────────────────────────────────────────────
static func open(parent: Node, pack_image: String, card1: String, card2: String, card3: String) -> void:
	var overlay := PackOpeningOverlay.new()
	overlay._pack_image_path = pack_image if pack_image != null else ""
	overlay._card_names = [
		card1 if card1 != null else "",
		card2 if card2 != null else "",
		card3 if card3 != null else "",
	]
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index        = 50
	overlay.mouse_filter   = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)

# ──────────────────────────────────────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()
	_run.call_deferred()

func _input(event: InputEvent) -> void:
	if _anim_done:
		return
	if event is InputEventMouseButton:
		var mbe: InputEventMouseButton = event as InputEventMouseButton
		if mbe.pressed and mbe.button_index == MOUSE_BUTTON_LEFT:
			_skip_requested = true
	elif event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and ke.keycode == KEY_SPACE:
			_skip_requested = true

# ──────────────────────────────────────────────────────────────────────────────
# Build UI nodes
# ──────────────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Dark background
	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color        = Color(0.0, 0.0, 0.0, 0.0)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# Pack root — pivot at centre of pack image
	_pack_root = Control.new()
	_pack_root.custom_minimum_size = Vector2(PACK_W, PACK_H)
	_pack_root.size                = Vector2(PACK_W, PACK_H)
	_pack_root.pivot_offset        = Vector2(PACK_W * 0.5, PACK_H * 0.5)
	_pack_root.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	add_child(_pack_root)

	var tex_path: String = _pack_image_path \
		if (_pack_image_path != "" and ResourceLoader.exists(_pack_image_path)) \
		else PACK_TEX_PATH
	var pack_tex: Variant = null
	if ResourceLoader.exists(tex_path):
		pack_tex = load(tex_path)

	# ── Top-half clip (clips top PACK_H/2 of the pack image) ──────────────
	_clip_top = Control.new()
	_clip_top.clip_contents  = true
	_clip_top.size           = Vector2(PACK_W, PACK_H * 0.5)
	_clip_top.position       = Vector2(0.0, 0.0)
	_clip_top.pivot_offset   = Vector2(PACK_W * 0.5, PACK_H * 0.5)  # tear edge
	_clip_top.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	_pack_root.add_child(_clip_top)

	var top_img := TextureRect.new()
	top_img.texture      = pack_tex as Texture2D
	top_img.size         = Vector2(PACK_W, PACK_H)
	top_img.position     = Vector2.ZERO
	top_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	top_img.stretch_mode = TextureRect.STRETCH_SCALE
	top_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip_top.add_child(top_img)

	# ── Bottom-half clip (clips bottom PACK_H/2 of the pack image) ────────
	_clip_bot = Control.new()
	_clip_bot.clip_contents = true
	_clip_bot.size          = Vector2(PACK_W, PACK_H * 0.5)
	_clip_bot.position      = Vector2(0.0, PACK_H * 0.5)
	_clip_bot.pivot_offset  = Vector2(PACK_W * 0.5, 0.0)  # tear edge
	_clip_bot.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_pack_root.add_child(_clip_bot)

	var bot_img := TextureRect.new()
	bot_img.texture      = pack_tex as Texture2D
	bot_img.size         = Vector2(PACK_W, PACK_H)
	bot_img.position     = Vector2(0.0, -PACK_H * 0.5)   # offset so bottom shows
	bot_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bot_img.stretch_mode = TextureRect.STRETCH_SCALE
	bot_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip_bot.add_child(bot_img)

# ──────────────────────────────────────────────────────────────────────────────
# Main animation coroutine
# ──────────────────────────────────────────────────────────────────────────────
func _run() -> void:
	var screen: Vector2 = get_viewport_rect().size
	var cx: float = screen.x * 0.5
	var cy: float = screen.y * 0.5

	# Start pack off the bottom
	var pack_final_pos := Vector2(cx - PACK_W * 0.5, cy - PACK_H * 0.5)
	_pack_root.position = Vector2(cx - PACK_W * 0.5, screen.y + 40.0)
	_pack_root.scale    = Vector2.ONE
	_pack_root.rotation = 0.0

	# ── Phase 1: BG fade-in + pack slides up ──────────────────────────────
	var t1: Tween = create_tween().set_parallel(true)
	t1.tween_property(_bg, "color:a", 0.75, 0.35)
	t1.tween_property(_pack_root, "position:y", pack_final_pos.y, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t1.finished

	# ── Phase 2: Wiggle (like shaking a snack bag) ────────────────────────
	await _wiggle(_pack_root)

	# ── Phase 3: Tear — top flies upper-left, bottom flies lower-right ────
	var t3: Tween = create_tween().set_parallel(true)
	# Top half
	t3.tween_property(_clip_top, "position:y",
			_clip_top.position.y - screen.y * 0.75, 0.52) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t3.tween_property(_clip_top, "position:x",
			_clip_top.position.x - 90.0, 0.52)
	t3.tween_property(_clip_top, "rotation", -0.55, 0.52)
	# Bottom half
	t3.tween_property(_clip_bot, "position:y",
			_clip_bot.position.y + screen.y * 0.75, 0.52) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t3.tween_property(_clip_bot, "position:x",
			_clip_bot.position.x + 90.0, 0.52)
	t3.tween_property(_clip_bot, "rotation", 0.55, 0.52)
	await t3.finished

	_pack_root.visible = false

	# ── Phase 4: Debris scatter ───────────────────────────────────────────
	_spawn_debris(cx, cy)

	# ── Phase 5: Cards rise stacked from centre ───────────────────────────
	var total_w: float  = CARD_W * 3.0 + CARD_GAP * 2.0
	var card_y : float  = cy - CARD_H * 0.5
	var fan_positions: Array[Vector2] = [
		Vector2(cx - total_w * 0.5,            card_y),
		Vector2(cx - CARD_W * 0.5,             card_y),
		Vector2(cx + total_w * 0.5 - CARD_W,   card_y),
	]

	var card_wrappers: Array = []
	for i: int in range(3):
		var w: Control = _make_card_ctrl(_card_names[i], i)
		w.position     = Vector2(cx - CARD_W * 0.5, screen.y + 20.0)
		w.scale        = Vector2(0.5, 0.5)
		w.pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)
		w.z_index      = 2
		add_child(w)
		card_wrappers.append(w)

	var t5: Tween = create_tween().set_parallel(true)
	for w: Control in card_wrappers:
		t5.tween_property(w, "position:y", card_y, 0.42) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t5.tween_property(w, "scale", Vector2.ONE, 0.42) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t5.finished

	await get_tree().create_timer(0.07).timeout

	# ── Phase 6: Fan out side by side ─────────────────────────────────────
	var t6: Tween = create_tween().set_parallel(true)
	for i: int in range(3):
		var w: Control = card_wrappers[i] as Control
		t6.tween_property(w, "position:x", fan_positions[i].x, 0.38) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t6.finished

	# ── Phase 7: Glow pulse on each card ──────────────────────────────────
	for i: int in range(3):
		_start_glow_pulse(i)

	# ── Phase 8: Hold (skippable by click / Space) ─────────────────────────
	var elapsed: float = 0.0
	while elapsed < 3.5 and not _skip_requested:
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05

	_skip_requested = false

	# ── Phase 9: Cards fly to top-right corner ────────────────────────────
	var dest: Vector2 = Vector2(screen.x + 60.0, -CARD_H - 60.0)
	var t9: Tween = create_tween().set_parallel(true)
	for w: Control in card_wrappers:
		t9.tween_property(w, "position", dest, 0.48) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
		t9.tween_property(w, "scale", Vector2(0.0, 0.0), 0.48) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t9.tween_property(_bg, "color:a", 0.0, 0.40)
	await t9.finished

	_anim_done = true
	queue_free()

# ──────────────────────────────────────────────────────────────────────────────
# Pack wiggle animation
# ──────────────────────────────────────────────────────────────────────────────
func _wiggle(ctrl: Control) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(ctrl, "rotation", -0.08, 0.11)
	tw.tween_property(ctrl, "rotation",  0.08, 0.11)
	tw.tween_property(ctrl, "rotation", -0.10, 0.09)
	tw.tween_property(ctrl, "rotation",  0.10, 0.09)
	tw.tween_property(ctrl, "rotation", -0.06, 0.09)
	tw.tween_property(ctrl, "rotation",  0.06, 0.09)
	tw.tween_property(ctrl, "rotation",  0.00, 0.07)
	await tw.finished

# ──────────────────────────────────────────────────────────────────────────────
# Debris scraps scatter
# ──────────────────────────────────────────────────────────────────────────────
func _spawn_debris(cx: float, cy: float) -> void:
	var palette: Array[Color] = [
		Color(0.88, 0.55, 0.12),
		Color(0.20, 0.62, 0.92),
		Color(0.92, 0.86, 0.28),
		Color(0.50, 0.92, 0.42),
		Color(0.92, 0.30, 0.30),
		Color(0.78, 0.78, 0.78),
	]
	for _i: int in range(14):
		var scrap := ColorRect.new()
		var sw: float = randf_range(9.0, 30.0)
		var sh: float = randf_range(5.0, 15.0)
		scrap.size         = Vector2(sw, sh)
		scrap.position     = Vector2(cx - sw * 0.5, cy - sh * 0.5)
		scrap.color        = palette[randi() % palette.size()]
		scrap.rotation     = randf_range(-PI, PI)
		scrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scrap.z_index      = 1
		add_child(scrap)

		var angle : float  = randf_range(0.0, TAU)
		var dist  : float  = randf_range(70.0, 230.0)
		var dest  : Vector2 = Vector2(
			scrap.position.x + cos(angle) * dist,
			scrap.position.y + sin(angle) * dist
		)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(scrap, "position", dest, 0.55) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tw.tween_property(scrap, "rotation",
				scrap.rotation + randf_range(-TAU, TAU), 0.55)
		tw.tween_property(scrap, "color:a", 0.0, 0.55)
		var captured: ColorRect = scrap
		tw.finished.connect(func() -> void: captured.queue_free())

# ──────────────────────────────────────────────────────────────────────────────
# Card control builder
# ──────────────────────────────────────────────────────────────────────────────
func _make_card_ctrl(card_name: String, idx: int) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(CARD_W, CARD_H)
	wrapper.size                = Vector2(CARD_W, CARD_H)
	wrapper.mouse_filter        = Control.MOUSE_FILTER_IGNORE

	# Glow aura (shadow-based, behind the card image)
	var glow_panel := Panel.new()
	glow_panel.size         = Vector2(CARD_W + 28.0, CARD_H + 28.0)
	glow_panel.position     = Vector2(-14.0, -14.0)
	glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var gc: Color        = _glow_color_for(card_name)
	var gp_sb            := StyleBoxFlat.new()
	gp_sb.draw_center    = false
	gp_sb.border_width_left   = 0
	gp_sb.border_width_top    = 0
	gp_sb.border_width_right  = 0
	gp_sb.border_width_bottom = 0
	gp_sb.shadow_color  = gc
	gp_sb.shadow_size   = 16
	gp_sb.shadow_offset = Vector2.ZERO
	glow_panel.add_theme_stylebox_override("panel", gp_sb)
	wrapper.add_child(glow_panel)
	_glow_sbs[idx] = gp_sb

	# Card artwork
	var card_img             := TextureRect.new()
	card_img.size             = Vector2(CARD_W, CARD_H)
	card_img.position         = Vector2.ZERO
	card_img.expand_mode      = TextureRect.EXPAND_IGNORE_SIZE
	card_img.stretch_mode     = TextureRect.STRETCH_SCALE
	card_img.mouse_filter     = Control.MOUSE_FILTER_IGNORE
	card_img.texture          = _load_card_tex(card_name)
	wrapper.add_child(card_img)

	return wrapper

# ──────────────────────────────────────────────────────────────────────────────
# Glow pulse (looping, via shadow_size)
# ──────────────────────────────────────────────────────────────────────────────
func _start_glow_pulse(idx: int) -> void:
	var sb: Variant = _glow_sbs[idx]
	if sb == null:
		return
	var gp_sb: StyleBoxFlat = sb as StyleBoxFlat
	var tw: Tween = create_tween().set_loops()
	tw.tween_method(
		func(v: float) -> void: gp_sb.shadow_size = int(v),
		16.0, 34.0, 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(
		func(v: float) -> void: gp_sb.shadow_size = int(v),
		34.0, 16.0, 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ──────────────────────────────────────────────────────────────────────────────
# Load full-card texture (fallback to vellum frame)
# ──────────────────────────────────────────────────────────────────────────────
func _load_card_tex(card_name: String) -> Texture2D:
	if card_name == null or card_name == "":
		return load(FALLBACK_CARD_PATH) as Texture2D
	var snake: String = card_name.to_lower() \
		.replace(" ", "_").replace("'", "").replace("-", "_")
	var path: String = FULL_CARDS_DIR + snake + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return load(FALLBACK_CARD_PATH) as Texture2D

# ──────────────────────────────────────────────────────────────────────────────
# Glow colour by card type
# ──────────────────────────────────────────────────────────────────────────────
func _glow_color_for(card_name: String) -> Color:
	if card_name == null or card_name == "":
		return Color(0.80, 0.80, 0.80, 0.9)
	if CardDatabase.get_character(card_name) != null:
		return Color(0.25, 0.90, 1.00, 0.9)   # cyan — character
	if CardDatabase.get_trap(card_name) != null:
		return Color(1.00, 0.28, 0.28, 0.9)   # red  — trap
	if CardDatabase.get_tech(card_name) != null:
		return Color(0.30, 1.00, 0.42, 0.9)   # green — tech
	return Color(0.80, 0.80, 0.80, 0.9)       # grey  — unknown
