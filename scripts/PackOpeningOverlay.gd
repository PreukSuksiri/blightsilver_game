extends Control
class_name PackOpeningOverlay

signal reveal_finished

# ──────────────────────────────────────────────────────────────────────────────
# PackOpeningOverlay — standalone booster-pack opening animation.
#
# Usage (callable from anywhere):
#   PackOpeningOverlay.open(get_tree().root, "Aether Warden", "Radar", "Bunker")
#
# Any null / empty / unrecognised card name shows the fallback vellum frame.
# Only pre-rendered full_cards/ images are shown (never raw artwork).
# Textures are preloaded before the reveal animation starts.
# The overlay blocks all input during the animation.
# Clicking / Space skips the display wait and triggers the fly-off once all cards
# are on screen and have settled (0.2s after the fan-out animation).
# ──────────────────────────────────────────────────────────────────────────────

const PACK_TEX_PATH     : String = "res://assets/textures/cards/booster_pack/booster_pack_basic.png"
const FALLBACK_CARD_PATH: String = "res://assets/textures/cards/frames/vellum_card_frame_full.png"
const FULL_CARDS_DIR    : String = "res://assets/textures/cards/full_cards/"
const DISPLAY_HOLD_SECONDS: float = 30.0
const CARD_SETTLE_SECONDS: float = 0.2
const HOLD_SKIP_ALL_SECONDS: float = 3.0
const _ROUNDED_CLIP: Shader = preload("res://assets/shaders/rounded_clip.gdshader")
const _CARD_CORNER_RADIUS_REF: float = 16.0   # px at 150px card width
const _POSE_FRAME_COLOR: Color = Color(0.40, 0.85, 1.0, 0.95)
const _POSE_FRAME_BG_COLOR: Color = Color(0.02, 0.04, 0.10, 0.88)

# Sizes computed from viewport at _ready; pack ~82% screen height, cards fill remaining width
var _pack_w : float = 0.0
var _pack_h : float = 0.0
var _card_w : float = 0.0
var _card_h : float = 0.0
var _card_gap: float = 0.0
var _pose_w: float = 0.0
var _pose_h: float = 0.0
var _reveal_glow_h: float = 0.0

# ── State ──────────────────────────────────────────────────────────────────────
var _card_names     : Array[String] = []
var _pack_image_path:  String = ""   # overrides PACK_TEX_PATH when non-empty
var _reroll_pack_name: String = ""   # non-empty enables Re-roll button
var _skip_requested:   bool   = false
var _skippable:        bool   = true
var _dismiss_allowed:  bool   = false
var _anim_done:        bool   = false
var _reroll_triggered: bool   = false
var _single_card_mode: bool   = false
var _single_pose_mode: bool   = false
var _pose_portrait_path: String = ""
var _pose_label: String = ""
var _pose_tex: Texture2D = null
var _hold_skip_elapsed: float = 0.0
var _glow_sbs:         Array  = [null, null, null]  # StyleBoxFlat refs
var _card_tex_cache:   Array  = []                    # preloaded full-card textures

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
static func open(parent: Node, pack_image: String, card1: String, card2: String, card3: String, skippable: bool = true, reroll_pack_name: String = "") -> PackOpeningOverlay:
	var overlay := PackOpeningOverlay.new()
	overlay._pack_image_path  = pack_image if pack_image != null else ""
	overlay._reroll_pack_name = reroll_pack_name
	overlay._skippable        = skippable
	overlay._card_names = [
		card1 if card1 != null else "",
		card2 if card2 != null else "",
		card3 if card3 != null else "",
	]
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index        = 50
	overlay.mouse_filter   = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)
	return overlay

static func open_single_card_reveal(parent: Node, card_name: String, skippable: bool = true) -> PackOpeningOverlay:
	var overlay := PackOpeningOverlay.new()
	overlay._single_card_mode = true
	overlay._skippable = skippable
	overlay._card_names = [card_name if card_name != null else ""]
	overlay._glow_sbs = [null]
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 50
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)
	return overlay

static func open_pose_reveal(parent: Node, portrait_path: String, pose_label: String, skippable: bool = true) -> PackOpeningOverlay:
	var overlay := PackOpeningOverlay.new()
	overlay._single_pose_mode = true
	overlay._skippable = skippable
	overlay._pose_portrait_path = portrait_path if portrait_path != null else ""
	overlay._pose_label = pose_label if pose_label != null else ""
	overlay._glow_sbs = [null]
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 50
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)
	return overlay

# ──────────────────────────────────────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_compute_sizes()
	if _single_pose_mode:
		_load_pose_texture()
		_compute_pose_sizes()
		_build_single_pose_ui()
	elif _single_card_mode:
		_build_single_card_ui()
	else:
		_build_ui()
	_run.call_deferred()

func _process(delta: float) -> void:
	if _anim_done or GameState.quick_duel_reveal_skip_all:
		return
	if _is_hold_skip_pressed():
		_hold_skip_elapsed += delta
		if _hold_skip_elapsed >= HOLD_SKIP_ALL_SECONDS:
			GameState.quick_duel_reveal_skip_all = true
			_skip_requested = true
	else:
		_hold_skip_elapsed = 0.0

func _is_hold_skip_pressed() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE)

func _compute_sizes() -> void:
	var s: Vector2 = get_viewport_rect().size
	# pack_w / pack_h derived from actual image aspect ratio in _build_ui
	# Cards: fit 3 side-by-side; gap = 4% of screen width
	_card_gap = s.x * 0.04
	var max_by_w: float = (s.x - 120.0) / 3.0 - _card_gap
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

	# ── Load texture first so we can derive the correct aspect ratio ──────
	var tex_path: String = _pack_image_path \
		if (_pack_image_path != "" and ResourceLoader.exists(_pack_image_path)) \
		else PACK_TEX_PATH
	var pack_tex: Texture2D = null
	if ResourceLoader.exists(tex_path):
		pack_tex = load(tex_path) as Texture2D

	# Pack display size derived from actual pixel dimensions
	var s: Vector2 = get_viewport_rect().size
	_pack_h = s.y * 0.84
	if pack_tex != null:
		_pack_w = _pack_h * (float(pack_tex.get_width()) / float(pack_tex.get_height()))
	else:
		_pack_w = _pack_h * (160.0 / 220.0)

	# ── Pack root — pivot at centre ────────────────────────────────────────
	_pack_root = Control.new()
	_pack_root.custom_minimum_size = Vector2(_pack_w, _pack_h)
	_pack_root.size                = Vector2(_pack_w, _pack_h)
	_pack_root.pivot_offset        = Vector2(_pack_w * 0.5, _pack_h * 0.5)
	_pack_root.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	add_child(_pack_root)

	# Split at the midpoint in source-texture pixel space
	var split_y: float     = floor(_pack_h * 0.5)
	var tex_w  : float     = float(pack_tex.get_width())  if pack_tex != null else 832.0
	var tex_h  : float     = float(pack_tex.get_height()) if pack_tex != null else 1216.0
	var tex_mid: float     = floor(tex_h * 0.5)

	# ── Top-half: AtlasTexture shows only the top portion of the source ────
	# No clip_contents needed — the AtlasTexture itself limits what is drawn.
	var atlas_top          := AtlasTexture.new()
	atlas_top.atlas         = pack_tex
	atlas_top.region        = Rect2(0.0, 0.0, tex_w, tex_mid)
	atlas_top.filter_clip   = true

	_clip_top              = Control.new()
	_clip_top.size          = Vector2(_pack_w, split_y)
	_clip_top.position      = Vector2(0.0, 0.0)
	_clip_top.pivot_offset  = Vector2(_pack_w * 0.5, split_y)  # pivot at tear edge
	_clip_top.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_pack_root.add_child(_clip_top)

	var top_img            := TextureRect.new()
	top_img.texture         = atlas_top
	top_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_img.expand_mode     = TextureRect.EXPAND_IGNORE_SIZE
	top_img.stretch_mode    = TextureRect.STRETCH_SCALE
	top_img.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	_clip_top.add_child(top_img)

	# ── Bottom-half: AtlasTexture shows only the bottom portion ────────────
	var atlas_bot          := AtlasTexture.new()
	atlas_bot.atlas         = pack_tex
	atlas_bot.region        = Rect2(0.0, tex_mid, tex_w, tex_h - tex_mid)
	atlas_bot.filter_clip   = true

	_clip_bot              = Control.new()
	_clip_bot.size          = Vector2(_pack_w, _pack_h - split_y)
	_clip_bot.position      = Vector2(0.0, split_y)
	_clip_bot.pivot_offset  = Vector2(_pack_w * 0.5, 0.0)  # pivot at tear edge
	_clip_bot.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_pack_root.add_child(_clip_bot)

	var bot_img            := TextureRect.new()
	bot_img.texture         = atlas_bot
	bot_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bot_img.expand_mode     = TextureRect.EXPAND_IGNORE_SIZE
	bot_img.stretch_mode    = TextureRect.STRETCH_SCALE
	bot_img.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	_clip_bot.add_child(bot_img)

func _build_single_card_ui() -> void:
	_build_single_reveal_bg()

func _build_single_pose_ui() -> void:
	_build_single_reveal_bg()

func _build_single_reveal_bg() -> void:
	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.0, 0.0, 0.0, 0.0)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

func _load_pose_texture() -> void:
	_pose_tex = null
	var path: String = _pose_portrait_path.strip_edges()
	if path != "" and ResourceLoader.exists(path):
		_pose_tex = load(path) as Texture2D

func _compute_pose_sizes() -> void:
	var s: Vector2 = get_viewport_rect().size
	var max_h: float = s.y * 0.62
	var max_w: float = s.x * 0.58
	var aspect: float = 0.72
	if _pose_tex != null and _pose_tex.get_height() > 0:
		aspect = float(_pose_tex.get_width()) / float(_pose_tex.get_height())
	_pose_h = minf(max_h, max_w / aspect)
	_pose_w = _pose_h * aspect
	_reveal_glow_h = _pose_h

# ──────────────────────────────────────────────────────────────────────────────
# Main animation coroutine
# ──────────────────────────────────────────────────────────────────────────────
func _run() -> void:
	if _single_pose_mode:
		await _run_single_pose_reveal()
		return
	if _single_card_mode:
		await _run_single_card_reveal()
		return
	_reveal_glow_h = _card_h
	_preload_card_textures()

	var screen: Vector2 = get_viewport_rect().size
	var cx: float = screen.x * 0.5
	var cy: float = screen.y * 0.5

	# Start pack off the bottom
	var pack_final_pos := Vector2(cx - _pack_w * 0.5, cy - _pack_h * 0.5)
	_pack_root.position = Vector2(cx - _pack_w * 0.5, screen.y + 40.0)
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
	var total_w: float  = _card_w * 3.0 + _card_gap * 2.0
	var card_y : float  = cy - _card_h * 0.5
	var fan_positions: Array[Vector2] = [
		Vector2(cx - total_w * 0.5,             card_y),
		Vector2(cx - _card_w * 0.5,             card_y),
		Vector2(cx + total_w * 0.5 - _card_w,   card_y),
	]

	var card_wrappers: Array = []
	for i: int in range(3):
		var w: Control = _make_card_ctrl(_card_names[i], i)
		w.position     = Vector2(cx - _card_w * 0.5, screen.y + 20.0)
		w.scale        = Vector2(0.5, 0.5)
		w.pivot_offset = Vector2(_card_w * 0.5, _card_h * 0.5)
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

	await get_tree().create_timer(CARD_SETTLE_SECONDS).timeout
	_skip_requested = false
	_dismiss_allowed = true

	# ── Phase 7: Glow pulse on each card ──────────────────────────────────
	for i: int in range(3):
		_start_glow_pulse(i)

	# ── Phase 8: Hold (skippable by click / Space) ─────────────────────────
	# Show Re-roll button if player has winding keys and pack name is known
	var reroll_btn: Button = null
	if _reroll_pack_name != "":
		reroll_btn = _make_reroll_btn(cx, card_y)

	var elapsed: float = 0.0
	while elapsed < DISPLAY_HOLD_SECONDS and not _skip_requested and not _reroll_triggered \
			and not GameState.quick_duel_reveal_skip_all:
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05

	if _reroll_triggered:
		return

	_skip_requested = false
	if reroll_btn and is_instance_valid(reroll_btn):
		reroll_btn.queue_free()

	# ── Phase 9: Cards fly to top-right corner ────────────────────────────
	var dest: Vector2 = Vector2(screen.x + 60.0, -_card_h - 60.0)
	var t9: Tween = create_tween().set_parallel(true)
	for w: Control in card_wrappers:
		t9.tween_property(w, "position", dest, 0.48) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
		t9.tween_property(w, "scale", Vector2(0.0, 0.0), 0.48) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t9.tween_property(_bg, "color:a", 0.0, 0.40)
	await t9.finished
	_finish_reveal()

func _run_single_card_reveal() -> void:
	_reveal_glow_h = _card_h
	_card_tex_cache.clear()
	_card_tex_cache.append(_load_card_tex(_card_names[0] if _card_names.size() > 0 else ""))

	var screen: Vector2 = get_viewport_rect().size
	var cx: float = screen.x * 0.5
	var cy: float = screen.y * 0.5
	var card_y: float = cy - _card_h * 0.5

	var t1: Tween = create_tween()
	t1.tween_property(_bg, "color:a", 0.75, 0.35)
	await t1.finished
	if GameState.quick_duel_reveal_skip_all:
		_finish_reveal()
		return

	_spawn_debris(cx, cy)

	var w: Control = _make_card_ctrl(_card_names[0] if _card_names.size() > 0 else "", 0)
	w.position = Vector2(cx - _card_w * 0.5, screen.y + 20.0)
	w.scale = Vector2(0.5, 0.5)
	w.pivot_offset = Vector2(_card_w * 0.5, _card_h * 0.5)
	w.z_index = 2
	add_child(w)

	var t5: Tween = create_tween().set_parallel(true)
	t5.tween_property(w, "position:y", card_y, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t5.tween_property(w, "scale", Vector2.ONE, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t5.finished
	await get_tree().create_timer(CARD_SETTLE_SECONDS).timeout
	_skip_requested = false
	_dismiss_allowed = true
	_start_glow_pulse(0)

	var elapsed: float = 0.0
	while elapsed < DISPLAY_HOLD_SECONDS and not _skip_requested and not GameState.quick_duel_reveal_skip_all:
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05

	_skip_requested = false
	var dest: Vector2 = Vector2(screen.x + 60.0, -_card_h - 60.0)
	var t9: Tween = create_tween().set_parallel(true)
	t9.tween_property(w, "position", dest, 0.48) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t9.tween_property(w, "scale", Vector2(0.0, 0.0), 0.48) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t9.tween_property(_bg, "color:a", 0.0, 0.40)
	await t9.finished
	_finish_reveal()

func _run_single_pose_reveal() -> void:
	_reveal_glow_h = _pose_h
	var screen: Vector2 = get_viewport_rect().size
	var cx: float = screen.x * 0.5
	var cy: float = screen.y * 0.5
	var block_h: float = _pose_h + 56.0
	var block_y: float = cy - block_h * 0.5

	var t1: Tween = create_tween()
	t1.tween_property(_bg, "color:a", 0.75, 0.35)
	await t1.finished
	if GameState.quick_duel_reveal_skip_all:
		_finish_reveal()
		return

	_spawn_debris(cx, cy)

	var w: Control = _make_pose_ctrl()
	w.position = Vector2(cx - _pose_w * 0.5, screen.y + 20.0)
	w.scale = Vector2(0.5, 0.5)
	w.pivot_offset = Vector2(_pose_w * 0.5, block_h * 0.5)
	w.z_index = 2
	add_child(w)

	var t5: Tween = create_tween().set_parallel(true)
	t5.tween_property(w, "position:y", block_y, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t5.tween_property(w, "scale", Vector2.ONE, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t5.finished
	await get_tree().create_timer(CARD_SETTLE_SECONDS).timeout
	_skip_requested = false
	_dismiss_allowed = true

	var elapsed: float = 0.0
	while elapsed < DISPLAY_HOLD_SECONDS and not _skip_requested and not GameState.quick_duel_reveal_skip_all:
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05

	_skip_requested = false
	var dest: Vector2 = Vector2(screen.x + 60.0, -block_h - 60.0)
	var t9: Tween = create_tween().set_parallel(true)
	t9.tween_property(w, "position", dest, 0.48) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t9.tween_property(w, "scale", Vector2(0.0, 0.0), 0.48) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t9.tween_property(_bg, "color:a", 0.0, 0.40)
	await t9.finished
	_finish_reveal()

func _finish_reveal() -> void:
	if _anim_done:
		return
	_anim_done = true
	reveal_finished.emit()
	queue_free()


## Release awaiters (InventoryMenu / AchievementCelebrationRunner) without freeing.
## Used when replacing this overlay via re-roll.
func _emit_reveal_finished_once() -> void:
	if _anim_done:
		return
	_anim_done = true
	reveal_finished.emit()
# ──────────────────────────────────────────────────────────────────────────────
func _make_reroll_btn(cx: float, card_y: float) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(200, 44)
	btn.position = Vector2(cx - 100.0, card_y + _card_h + 18.0)
	btn.z_index  = 10
	var key_icon_path := "res://assets/textures/ui/decorations/ui_icon_winding_key.png"
	if ResourceLoader.exists(key_icon_path):
		btn.icon = load(key_icon_path) as Texture2D
	btn.pressed.connect(func() -> void: _on_reroll_pressed(btn))
	add_child(btn)
	# Update text and visibility whenever collection changes (e.g. after spending a key)
	var _update := func() -> void:
		var keys: int = Collection.winding_keys
		btn.visible = keys > 0
		btn.text    = "Re-roll  (%d)" % keys
	_update.call()
	Collection.collection_changed.connect(_update)
	btn.tree_exiting.connect(func() -> void:
		if Collection.collection_changed.is_connected(_update):
			Collection.collection_changed.disconnect(_update))
	return btn

func _on_reroll_pressed(btn: Button) -> void:
	if not Collection.spend_winding_key():
		return
	_reroll_triggered = true
	if btn and is_instance_valid(btn):
		btn.visible = false
	var new_cards: Array = ShopManager.draw_pack_free(_reroll_pack_name)
	var c1: String = new_cards[0].get("name","") if new_cards.size() > 0 else ""
	var c2: String = new_cards[1].get("name","") if new_cards.size() > 1 else ""
	var c3: String = new_cards[2].get("name","") if new_cards.size() > 2 else ""
	var pack_dict: Dictionary = ShopManager.get_pack_by_name(_reroll_pack_name)
	var pack_img: String = str(pack_dict.get("pack_image", ""))
	var parent: Node = get_parent()
	# Unlock awaiters before freeing — otherwise InventoryMenu hangs on reveal_finished.
	_emit_reveal_finished_once()
	queue_free()
	PackOpeningOverlay.open(parent, pack_img, c1, c2, c3, true, _reroll_pack_name)

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
	const DURATION: float = 1.45
	const FADE_DELAY: float = 0.85
	const FADE_DURATION: float = 0.65
	const DIST_MIN: float = 160.0
	const DIST_MAX: float = 420.0
	var palette: Array[Color] = [
		Color(0.88, 0.55, 0.12),
		Color(0.20, 0.62, 0.92),
		Color(0.92, 0.86, 0.28),
		Color(0.50, 0.92, 0.42),
		Color(0.92, 0.30, 0.30),
		Color(0.78, 0.78, 0.78),
	]
	for _i: int in range(18):
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
		var dist  : float  = randf_range(DIST_MIN, DIST_MAX)
		var dest  : Vector2 = Vector2(
			scrap.position.x + cos(angle) * dist,
			scrap.position.y + sin(angle) * dist
		)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(scrap, "position", dest, DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(scrap, "rotation",
				scrap.rotation + randf_range(-TAU, TAU), DURATION) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(scrap, "color:a", 0.0, FADE_DURATION).set_delay(FADE_DELAY)
		var captured: ColorRect = scrap
		tw.finished.connect(func() -> void: captured.queue_free())

# ──────────────────────────────────────────────────────────────────────────────
# Card control builder
# ──────────────────────────────────────────────────────────────────────────────
func _card_corner_radius() -> float:
	return max(6.0, _card_w * (_CARD_CORNER_RADIUS_REF / 150.0))

func _make_card_ctrl(card_name: String, idx: int) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(_card_w, _card_h)
	wrapper.size                = Vector2(_card_w, _card_h)
	wrapper.mouse_filter        = Control.MOUSE_FILTER_IGNORE

	# Glow aura — Panel exactly the size of the card; shadow radiates outward from its edges.
	# Transparent center so the card image on top shows through cleanly.
	var glow_panel       := Panel.new()
	glow_panel.size         = Vector2(_card_w, _card_h)
	glow_panel.position     = Vector2.ZERO
	glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var gc: Color     = _glow_color_for(card_name)
	var gp_sb         := StyleBoxFlat.new()
	gp_sb.bg_color    = Color(0.0, 0.0, 0.0, 0.0)  # fully transparent fill
	gp_sb.draw_center = true
	gp_sb.border_width_left   = 0
	gp_sb.border_width_top    = 0
	gp_sb.border_width_right  = 0
	gp_sb.border_width_bottom = 0
	gp_sb.shadow_color  = gc
	gp_sb.shadow_size   = int(_card_h * 0.05)
	gp_sb.shadow_offset = Vector2.ZERO
	glow_panel.add_theme_stylebox_override("panel", gp_sb)
	wrapper.add_child(glow_panel)
	_glow_sbs[idx] = gp_sb

	# Card artwork
	var card_img         := TextureRect.new()
	card_img.size         = Vector2(_card_w, _card_h)
	card_img.position     = Vector2.ZERO
	card_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	card_img.stretch_mode = TextureRect.STRETCH_SCALE
	card_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_img.texture      = _cached_card_tex(idx, card_name)
	var rc_mat := ShaderMaterial.new()
	rc_mat.shader = _ROUNDED_CLIP
	rc_mat.set_shader_parameter("corner_radius", _card_corner_radius())
	card_img.material = rc_mat
	wrapper.add_child(card_img)

	return wrapper

func _make_pose_ctrl() -> Control:
	var wrapper := Control.new()
	var label_h: float = 56.0
	wrapper.custom_minimum_size = Vector2(_pose_w, _pose_h + label_h)
	wrapper.size = Vector2(_pose_w, _pose_h + label_h)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var corner_radius: int = maxi(8, int(_pose_w * 0.03))

	var bg_panel := Panel.new()
	bg_panel.size = Vector2(_pose_w, _pose_h)
	bg_panel.position = Vector2.ZERO
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = _POSE_FRAME_BG_COLOR
	bg_sb.set_corner_radius_all(corner_radius)
	bg_panel.add_theme_stylebox_override("panel", bg_sb)
	wrapper.add_child(bg_panel)

	var portrait := TextureRect.new()
	portrait.size = Vector2(_pose_w, _pose_h)
	portrait.position = Vector2.ZERO
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = _pose_tex
	var rc_mat := ShaderMaterial.new()
	rc_mat.shader = _ROUNDED_CLIP
	rc_mat.set_shader_parameter("corner_radius", float(corner_radius))
	portrait.material = rc_mat
	wrapper.add_child(portrait)

	var frame_panel := Panel.new()
	frame_panel.size = Vector2(_pose_w, _pose_h)
	frame_panel.position = Vector2.ZERO
	frame_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_sb := StyleBoxFlat.new()
	frame_sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	frame_sb.draw_center = false
	frame_sb.border_color = _POSE_FRAME_COLOR
	frame_sb.set_border_width_all(2)
	frame_sb.set_corner_radius_all(corner_radius)
	frame_panel.add_theme_stylebox_override("panel", frame_sb)
	wrapper.add_child(frame_panel)

	var title_lbl := Label.new()
	title_lbl.text = "New Pose Unlocked"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.position = Vector2(0.0, _pose_h + 4.0)
	title_lbl.size = Vector2(_pose_w, 22.0)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.5))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(title_lbl)

	var name_lbl := Label.new()
	name_lbl.text = _pose_label if not _pose_label.is_empty() else "Protagonist Pose"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(0.0, _pose_h + 26.0)
	name_lbl.size = Vector2(_pose_w, 22.0)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.82, 0.9, 0.98))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(name_lbl)

	return wrapper

# ──────────────────────────────────────────────────────────────────────────────
# Glow pulse (looping, via shadow_size)
# ──────────────────────────────────────────────────────────────────────────────
func _start_glow_pulse(idx: int) -> void:
	var sb: Variant = _glow_sbs[idx]
	if sb == null:
		return
	var gp_sb: StyleBoxFlat = sb as StyleBoxFlat
	var glow_h: float = _reveal_glow_h if _reveal_glow_h > 0.0 else _card_h
	var lo: float = glow_h * 0.035
	var hi: float = glow_h * 0.075
	var tw: Tween = create_tween().set_loops()
	tw.tween_method(
		func(v: float) -> void: gp_sb.shadow_size = int(v),
		lo, hi, 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(
		func(v: float) -> void: gp_sb.shadow_size = int(v),
		hi, lo, 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ──────────────────────────────────────────────────────────────────────────────
# Full-card texture loading (full_cards/ only — fallback to vellum frame)
# ──────────────────────────────────────────────────────────────────────────────
func _preload_card_textures() -> void:
	_card_tex_cache.clear()
	for i: int in range(3):
		var name: String = _card_names[i] if i < _card_names.size() else ""
		_card_tex_cache.append(_load_card_tex(name))

func _cached_card_tex(idx: int, card_name: String) -> Texture2D:
	if idx >= 0 and idx < _card_tex_cache.size():
		var cached: Variant = _card_tex_cache[idx]
		if cached is Texture2D:
			return cached as Texture2D
	return _load_card_tex(card_name)

func _load_card_tex(card_name: String) -> Texture2D:
	var path: String = _resolve_full_card_path(card_name)
	if path != "":
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			return tex
	return load(FALLBACK_CARD_PATH) as Texture2D

func _resolve_full_card_path(card_name: String) -> String:
	if card_name == null or card_name.is_empty():
		return ""
	var snake: String = card_name.to_lower() \
		.replace(" ", "_").replace("'", "").replace("-", "_")
	var card_type: String = _card_type_for(card_name)
	var candidates: Array[String] = []
	if SaveManager.nsfw_enabled:
		candidates.append(snake + "_nsfw")
		if card_type != "":
			candidates.append(card_type + "_" + snake + "_nsfw")
	candidates.append(snake)
	if card_type != "":
		candidates.append(card_type + "_" + snake)
	for base: String in candidates:
		for ext: String in ["png", "jpg"]:
			var path: String = FULL_CARDS_DIR + base + "." + ext
			if ResourceLoader.exists(path):
				return path
	return ""

func _card_type_for(card_name: String) -> String:
	if CardDatabase.get_character(card_name) != null:
		return "character"
	if CardDatabase.get_trap(card_name) != null:
		return "trap"
	if CardDatabase.get_tech(card_name) != null:
		return "tech"
	return ""

# ──────────────────────────────────────────────────────────────────────────────
# Glow colour by card type
# ──────────────────────────────────────────────────────────────────────────────
func _glow_color_for(card_name: String) -> Color:
	if card_name == null or card_name == "":
		return Color(0.65, 0.65, 0.65, 0.9)
	var rarity: int = -1
	var cd: CharacterData = CardDatabase.get_character(card_name)
	if cd != null:
		rarity = cd.rarity
	else:
		var td: TrapData = CardDatabase.get_trap(card_name)
		if td != null:
			rarity = td.rarity
		else:
			var tech: TechCardData = CardDatabase.get_tech(card_name)
			if tech != null:
				rarity = tech.rarity
	match rarity:
		CharacterData.Rarity.COMMON:    return Color(0.65, 0.65, 0.65, 0.9)  # grey
		CharacterData.Rarity.UNCOMMON:  return Color(0.30, 0.90, 0.40, 0.9)  # green
		CharacterData.Rarity.RARE:      return Color(0.30, 0.65, 1.00, 0.9)  # blue
		CharacterData.Rarity.LEGENDARY: return Color(0.78, 0.35, 1.00, 0.9)  # purple
		CharacterData.Rarity.EXOTIC:    return Color(1.00, 0.80, 0.10, 0.9)  # gold
		_:                              return Color(0.65, 0.65, 0.65, 0.9)
