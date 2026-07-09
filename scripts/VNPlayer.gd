extends Control
class_name VNPlayer
# Visual Novel player — loads a JSON scene file and plays it beat by beat.
# Usage: instantiate vn_player.tscn, add_child, then call play_scene(path, callback).

# ─────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────
const SLOT_NAMES  := ["far_left", "left", "center", "right", "far_right"]
const _ANIMATION_SCENE := preload("res://scripts/VellumCardCommenceAnimation.gd")
const SLOT_X      := [0.0,        200.0,  640.0,    1080.0,  1280.0]
const CHAR_W      := 320.0
const CHAR_H      := 560.0
const CHAR_Y      := 80.0
const DIALOG_Y    := 640.0
const DIALOG_H    := 260.0
const DIALOG_SIDE_BORDER_W := 3.0
const DIALOG_BORDER_CYAN := Color(0.38, 0.65, 1.0, 0.35)
const STAGE_DESIGN_SIZE := Vector2(1600.0, 900.0)

const HINT_ICON_PATH  := "res://assets/textures/vn/etc/star_compass.png"
const WINDOWSKIN_PATH := "res://assets/textures/ui/decorations/ui_window_skin.png"
const TEXT_SHADOW_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const TEXT_SHADOW_OFFSET := 2

# ── Toggle dialog style ───────────────────────────────────────
# true  = decorative windowskin (NinePatchRect)
# false = original flat dark panel
const USE_WINDOWSKIN: bool = false

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var locale: String = "en"   # set before play_scene() to switch language
## When true the stage's solid colour base is hidden (bg images can still show).
## Set before add_child() so _ready() picks it up.
var transparent_bg: bool = false

## When true, all BGM changes inside the VN are suppressed — music keeps playing as-is.
## Use for overlay VNs (e.g. exploration) that should not interrupt the ambient track.
## Set before add_child() so _ready() picks it up.
var keep_bgm: bool = false
## Overlay VN launched on top of exploration — do not fade out BGM when the scene ends.
var exploration_overlay: bool = false
## When true, mark this scene played in ExplorationManager if start_battle ends the VN early.
var mark_played_on_battle: bool = false
## When true, mark exploration character talked if start_battle ends the VN early.
var mark_char_talked_on_battle: bool = false
var char_talk_node_id: String = ""
var char_talk_index: int = -1
## True while rendering a beat that launches exploration with exploration_keep_vn_bgm.
var _preserve_bgm_for_exploration: bool = false

var _beats: Array = []
var _beat_index: int = 0
var _beat_raw_indices: Array = []   # maps filtered index → raw JSON index
var _scene_path: String = ""
var _on_complete: Callable = Callable()
var _track_campaign_checkpoint: bool = false
var _chapter_arc_key: String = ""
var _current_bg_path: String = ""
var _accepting_input: bool = true
var _battle_handoff_started: bool = false
var _cmd_panel: PanelContainer = null
var _cmd_input: LineEdit = null

# ─────────────────────────────────────────────────────────────
# UI refs
# ─────────────────────────────────────────────────────────────
var _stage: Control = null          # 1600×900 content; shaken locally for screen shake
var _stage_holder: Control = null   # scaled + centered; layout reflow only touches this
var _bg_rect:  TextureRect = null
var _bg_base:  ColorRect   = null   # solid-colour base behind the background image
var _char_slots: Dictionary = {}    # slot_name -> TextureRect
var _dialog_panel: Panel = null
var _speaker_panel: PanelContainer = null
var _speaker_lbl: Label = null
var _dialog_lbl: RichTextLabel = null
var _hint_icon: TextureRect = null
var _hint_tween: Tween = null
var _video_player: VideoStreamPlayer = null
var _current_music_path: String = ""
var _fade_rect: ColorRect = null
var _backdrop: ColorRect = null
var _letterbox_bars: Array[ColorRect] = []   # L, R, T, B gutters for exploration contain mode
var _kb_tween: Tween = null      # Ken Burns background animation
var _stage_base_pos: Vector2 = Vector2.ZERO
var _stage_layout_pending: bool = false
var _screen_shake_tween: Tween = null

# ─────────────────────────────────────────────────────────────
# Localisation helper
# ─────────────────────────────────────────────────────────────
# val can be a plain String or a {"en": "...", "th": "..."} dict.
# Returns the string for the current locale, falling back to the
# first available language if the locale key is not found.
func _loc(val) -> String:
	if val is Dictionary:
		if val.has(locale):
			return str(val[locale])
		if not val.is_empty():
			return str(val.values()[0])
		return ""
	return str(val) if val != null else ""

func _resolve_gallery_chapter_end(beat: Dictionary) -> String:
	if beat.get("complete_current_gallery_chapter", false) \
			or beat.get("unlock_current_gallery_chapter", false):
		return _scene_path
	var vn_path: String = str(beat.get("complete_gallery_chapter", "")).strip_edges()
	if vn_path.is_empty():
		vn_path = str(beat.get("unlock_gallery_chapter", "")).strip_edges()
	return vn_path

# ─────────────────────────────────────────────────────────────
# Font helper
# ─────────────────────────────────────────────────────────────
func _make_font(weight: int) -> Font:
	return FontManager.make_font("primary", weight)

func _tag_ui(node: Control, property: String, weight: int = 400) -> void:
	FontManager.tag_font(node, property, "primary", weight)

func _apply_text_shadow(node: Control) -> void:
	node.add_theme_color_override("font_shadow_color", TEXT_SHADOW_COLOR)
	node.add_theme_constant_override("shadow_offset_x", TEXT_SHADOW_OFFSET)
	node.add_theme_constant_override("shadow_offset_y", TEXT_SHADOW_OFFSET)

func _on_fonts_changed() -> void:
	FontManager.refresh_tree(self)

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	clip_contents = false
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	if not FontManager.fonts_changed.is_connected(_on_fonts_changed):
		FontManager.fonts_changed.connect(_on_fonts_changed)
	if transparent_bg:
		_bg_base.visible = false
	_update_backdrop_visibility()
	get_viewport().size_changed.connect(_ensure_stage_layout)
	call_deferred("_reflow_stage")
	# Mini command overlay (Ctrl+Shift+A to open during VN playback)
	_cmd_panel = PanelContainer.new()
	_cmd_panel.visible = false
	_cmd_panel.z_index = 200
	_cmd_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_cmd_panel.offset_top = 8.0
	_cmd_panel.custom_minimum_size = Vector2(520.0, 0.0)
	add_child(_cmd_panel)
	var cmd_hbox := HBoxContainer.new()
	cmd_hbox.add_theme_constant_override("separation", 6)
	_cmd_panel.add_child(cmd_hbox)
	var cmd_lbl := Label.new()
	cmd_lbl.text = "VN CMD>"
	cmd_lbl.add_theme_font_size_override("font_size", 16)
	cmd_hbox.add_child(cmd_lbl)
	_cmd_input = LineEdit.new()
	_cmd_input.placeholder_text = "tag_bug"
	_cmd_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cmd_input.add_theme_font_size_override("font_size", 16)
	_cmd_input.text_submitted.connect(_handle_vn_command)
	cmd_hbox.add_child(_cmd_input)

# ─────────────────────────────────────────────────────────────
# Build UI
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.name = "ViewportBackdrop"
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color.BLACK
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.z_index = 0
	add_child(_backdrop)

	for _i in 4:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.visible = false
		bar.z_index = 3   # above scaled stage — covers contain letterbox gutters
		add_child(bar)
		_letterbox_bars.append(bar)

	# Stage holder — scaled/centered by layout; _stage shakes locally inside it.
	_stage_holder = Control.new()
	_stage_holder.z_index = 1
	add_child(_stage_holder)

	_stage = Control.new()
	_stage.position = Vector2.ZERO
	_stage.size     = STAGE_DESIGN_SIZE
	_stage_holder.add_child(_stage)

	# Dark base background (colour controllable via bg_color beat field)
	_bg_base = ColorRect.new()
	_bg_base.position = Vector2.ZERO
	_bg_base.size     = STAGE_DESIGN_SIZE
	_bg_base.color    = Color(0.04, 0.06, 0.14, 1.0)
	_stage.add_child(_bg_base)

	# Full-screen background image
	_bg_rect = TextureRect.new()
	_bg_rect.position     = Vector2.ZERO
	_bg_rect.size         = STAGE_DESIGN_SIZE
	_bg_rect.pivot_offset = STAGE_DESIGN_SIZE * 0.5
	_bg_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.modulate     = Color(1.0, 1.0, 1.0, 0.0)
	_stage.add_child(_bg_rect)

	# Character slots — 5 fixed-position TextureRects
	var slot_name_list: Array = ["far_left", "left", "center", "right", "far_right"]
	var slot_x_list: Array    = [0.0, 200.0, 640.0, 1080.0, 1280.0]
	for i in slot_name_list.size():
		var sname: String = slot_name_list[i]
		var slot := TextureRect.new()
		slot.name         = sname
		slot.position     = Vector2(slot_x_list[i], CHAR_Y)
		slot.size         = Vector2(CHAR_W, CHAR_H)
		slot.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.modulate     = Color(1.0, 1.0, 1.0, 0.0)
		_stage.add_child(slot)
		_char_slots[sname] = slot

	# Dialog panel (bottom strip)
	_dialog_panel = Panel.new()
	_dialog_panel.position            = Vector2(0.0, DIALOG_Y)
	_dialog_panel.size                = Vector2(STAGE_DESIGN_SIZE.x, DIALOG_H)
	_dialog_panel.custom_minimum_size = Vector2(STAGE_DESIGN_SIZE.x, DIALOG_H)
	if USE_WINDOWSKIN:
		_dialog_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var nine := NinePatchRect.new()
		nine.texture             = load(WINDOWSKIN_PATH) as Texture2D
		nine.patch_margin_left   = 110
		nine.patch_margin_right  = 110
		nine.patch_margin_top    = 110
		nine.patch_margin_bottom = 110
		nine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_dialog_panel.add_child(nine)
	else:
		var sb_dlg := StyleBoxFlat.new()
		sb_dlg.bg_color = Color(0.02, 0.04, 0.12, 0.93)
		_dialog_panel.add_theme_stylebox_override("panel", sb_dlg)
	_add_dialog_side_borders(_dialog_panel)
	_dialog_panel.z_index = 1
	_stage.add_child(_dialog_panel)

	# Speaker name panel — child of dialog panel so it anchors to its top edge
	_speaker_panel = PanelContainer.new()
	_speaker_panel.position = Vector2(40.0, 0.0)
	var sb_spk := StyleBoxFlat.new()
	sb_spk.bg_color               = Color(0.08, 0.16, 0.38, 0.97)
	sb_spk.border_width_left      = 1
	sb_spk.border_width_top       = 1
	sb_spk.border_width_right     = 1
	sb_spk.border_width_bottom    = 0
	sb_spk.border_color           = Color(0.38, 0.65, 1.0, 0.6)
	sb_spk.corner_radius_top_left  = 6
	sb_spk.corner_radius_top_right = 6
	sb_spk.content_margin_left    = 18.0
	sb_spk.content_margin_right   = 18.0
	sb_spk.content_margin_top     = 7.0
	sb_spk.content_margin_bottom  = 7.0
	_speaker_panel.add_theme_stylebox_override("panel", sb_spk)
	_speaker_panel.z_index = 2
	_speaker_panel.visible = false
	_dialog_panel.add_child(_speaker_panel)

	_speaker_lbl = Label.new()
	_tag_ui(_speaker_lbl, "font", 700)
	_speaker_lbl.add_theme_font_size_override("font_size", 24)
	_speaker_lbl.add_theme_color_override("font_color", Color(0.72, 0.92, 1.0, 1.0))
	_apply_text_shadow(_speaker_lbl)
	_speaker_panel.add_child(_speaker_lbl)

	# Dialog text (inside panel) — RichTextLabel for BBCode color tag support
	_dialog_lbl = RichTextLabel.new()
	_dialog_lbl.position        = Vector2(50.0, 18.0)
	_dialog_lbl.size            = Vector2(1460.0, 218.0)
	_dialog_lbl.bbcode_enabled  = true
	_dialog_lbl.scroll_active   = false
	_tag_ui(_dialog_lbl, "normal_font", 400)
	_dialog_lbl.add_theme_font_size_override("normal_font_size", 30)
	_dialog_lbl.add_theme_color_override("default_color", Color(0.90, 0.95, 1.0, 0.97))
	_apply_text_shadow(_dialog_lbl)
	_dialog_panel.add_child(_dialog_lbl)

	# Continue icon (bottom-right of dialog panel)
	_hint_icon = TextureRect.new()
	_hint_icon.position     = Vector2(1530.0, DIALOG_H - 62.0)
	_hint_icon.size         = Vector2(52.0, 52.0)
	_hint_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_hint_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(HINT_ICON_PATH):
		_hint_icon.texture = load(HINT_ICON_PATH) as Texture2D
	_dialog_panel.add_child(_hint_icon)

	# Video player — full-screen, above bg/chars, below fade overlay
	_video_player = VideoStreamPlayer.new()
	_video_player.position     = Vector2.ZERO
	_video_player.size         = STAGE_DESIGN_SIZE
	_video_player.expand       = true
	_video_player.z_index      = 5
	_video_player.visible      = false
	_video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video_player.finished.connect(_on_video_finished)
	_stage.add_child(_video_player)

	# Fade overlay — full viewport; used for fade_in / fade_out beats
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color        = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.z_index      = 50
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

func _add_dialog_side_borders(panel: Panel) -> void:
	var w := DIALOG_SIDE_BORDER_W
	var top := ColorRect.new()
	top.position     = Vector2(0.0, 0.0)
	top.size         = Vector2(STAGE_DESIGN_SIZE.x, w)
	top.color        = DIALOG_BORDER_CYAN
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.z_index      = 4
	panel.add_child(top)
	# Side strips start below the top strip so semi-transparent corners don't stack.
	for x: float in [0.0, STAGE_DESIGN_SIZE.x - w]:
		var edge := ColorRect.new()
		edge.position     = Vector2(x, w)
		edge.size         = Vector2(w, DIALOG_H - w)
		edge.color        = DIALOG_BORDER_CYAN
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edge.z_index      = 4
		panel.add_child(edge)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_ensure_stage_layout()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_PAUSED:
		_persist_campaign_checkpoint()

## Scale the 1600×900 stage to fit inside the viewport (contain) and center it on screen.
func _ensure_stage_layout() -> void:
	if _stage_layout_pending:
		return
	_stage_layout_pending = true
	call_deferred("_reflow_stage")

func _reflow_stage() -> void:
	_stage_layout_pending = false
	if _stage_holder == null:
		return
	await get_tree().process_frame
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	var sx: float = vp.x / STAGE_DESIGN_SIZE.x
	var sy: float = vp.y / STAGE_DESIGN_SIZE.y
	var s: float = minf(sx, sy)
	_apply_stage_layout(vp, s)

func _apply_stage_layout(vp: Vector2, scale: float = -1.0) -> void:
	if _stage_holder == null:
		return
	if scale < 0.0:
		var sx: float = vp.x / STAGE_DESIGN_SIZE.x
		var sy: float = vp.y / STAGE_DESIGN_SIZE.y
		scale = minf(sx, sy)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sync_viewport_backdrop(vp)
	_sync_fade_overlay(vp)
	_stage_holder.scale = Vector2(scale, scale)
	var scaled: Vector2 = STAGE_DESIGN_SIZE * scale
	var new_base: Vector2 = (vp - scaled) * 0.5
	if _screen_shake_tween != null and _screen_shake_tween.is_running():
		var offset: Vector2 = _stage_holder.position - _stage_base_pos
		_stage_base_pos = new_base
		_stage_holder.position = _stage_base_pos + offset
	else:
		_stage_base_pos = new_base
		_stage_holder.position = _stage_base_pos
	if _stage != null:
		_stage.position = Vector2.ZERO
	_sync_exploration_letterbox(vp, scaled, new_base)

## Black bars in the contain-scale gutters (exploration overlay + bg image).
func _sync_exploration_letterbox(vp: Vector2, scaled: Vector2, base: Vector2) -> void:
	if _letterbox_bars.size() != 4:
		return
	for bar: ColorRect in _letterbox_bars:
		bar.visible = false
	if not exploration_overlay or not _is_vn_bg_image_visible():
		return
	var gap_l: float = base.x
	var gap_t: float = base.y
	var gap_r: float = maxf(0.0, vp.x - base.x - scaled.x)
	var gap_b: float = maxf(0.0, vp.y - base.y - scaled.y)
	if gap_l > 0.5:
		var bar_l: ColorRect = _letterbox_bars[0]
		bar_l.visible = true
		bar_l.position = Vector2.ZERO
		bar_l.size = Vector2(gap_l, vp.y)
	if gap_r > 0.5:
		var bar_r: ColorRect = _letterbox_bars[1]
		bar_r.visible = true
		bar_r.position = Vector2(base.x + scaled.x, 0.0)
		bar_r.size = Vector2(gap_r, vp.y)
	if gap_t > 0.5:
		var bar_t: ColorRect = _letterbox_bars[2]
		bar_t.visible = true
		bar_t.position = Vector2(base.x, 0.0)
		bar_t.size = Vector2(scaled.x, gap_t)
	if gap_b > 0.5:
		var bar_b: ColorRect = _letterbox_bars[3]
		bar_b.visible = true
		bar_b.position = Vector2(base.x, base.y + scaled.y)
		bar_b.size = Vector2(scaled.x, gap_b)

func _hide_letterbox_bars() -> void:
	for bar: ColorRect in _letterbox_bars:
		bar.visible = false

## Full-viewport fade layer — sized explicitly for export (anchors alone can be 0×0 on first frame).
func _sync_fade_overlay(vp: Vector2) -> void:
	if _fade_rect == null:
		return
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.position = Vector2.ZERO
	var fill: Vector2 = size
	if fill.x <= 0.0 or fill.y <= 0.0:
		fill = vp
	_fade_rect.size = fill

func _ensure_fade_overlay_ready() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	_apply_stage_layout(vp)

## True when the current beat is displaying a VN background image (not cleared with null).
func _is_vn_bg_image_visible() -> bool:
	return _current_bg_path != "" \
		and _bg_rect != null \
		and _bg_rect.texture != null \
		and _bg_rect.modulate.a > 0.01

## Exploration overlays only show the black letterbox when a background image is active.
func _update_backdrop_visibility() -> void:
	if exploration_overlay:
		if _backdrop != null:
			_backdrop.visible = false
		if _is_vn_bg_image_visible():
			var vp: Vector2 = get_viewport().get_visible_rect().size
			if vp.x > 0.0 and vp.y > 0.0:
				var sx: float = vp.x / STAGE_DESIGN_SIZE.x
				var sy: float = vp.y / STAGE_DESIGN_SIZE.y
				var s: float = minf(sx, sy)
				var scaled: Vector2 = STAGE_DESIGN_SIZE * s
				var base: Vector2 = (vp - scaled) * 0.5
				_sync_exploration_letterbox(vp, scaled, base)
		else:
			_hide_letterbox_bars()
		return
	if _backdrop == null:
		return
	_hide_letterbox_bars()
	_backdrop.visible = true
	_apply_backdrop_geometry()

## Full-viewport black letterbox — explicit size for export (anchors alone can be 0×0).
func _apply_backdrop_geometry() -> void:
	if _backdrop == null:
		return
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.position = Vector2.ZERO
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var fill: Vector2 = size
	if fill.x <= 0.0 or fill.y <= 0.0:
		fill = vp
	_backdrop.size = fill

## Keep the black letterbox backdrop covering the full overlay area (export-safe).
func _sync_viewport_backdrop(vp: Vector2) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_backdrop_visibility()

# ─────────────────────────────────────────────────────────────
# Hint icon — pulse animation
# ─────────────────────────────────────────────────────────────
func _show_hint_icon() -> void:
	_hint_icon.visible = true
	if _hint_tween != null:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.set_loops()
	_hint_tween.tween_property(_hint_icon, "modulate:a", 0.3, 0.8)
	_hint_tween.tween_property(_hint_icon, "modulate:a", 1.0, 0.8)

func _hide_hint_icon() -> void:
	if _hint_tween != null:
		_hint_tween.kill()
		_hint_tween = null
	_hint_icon.visible = false

# ─────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────
## Play a VN on a top-level CanvasLayer so it renders above battle UI / fade overlays.
static func launch_overlay(json_path: String, on_complete: Callable, canvas_layer: int = 300) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		push_warning("VNPlayer.launch_overlay: no SceneTree")
		return
	var host := CanvasLayer.new()
	host.layer = canvas_layer
	host.name = "VNOverlayLayer"
	tree.root.add_child(host)
	var vn := preload("res://scenes/vn_player.tscn").instantiate()
	vn.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(vn)
	vn.play_scene(json_path, func() -> void:
		host.queue_free()
		if on_complete.is_valid():
			on_complete.call())

## Remove a launch_overlay() host left on the scene tree (e.g. after tutorial_battle handoff).
static func dismiss_overlay_if_present(tree: SceneTree = null) -> void:
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var host: Node = tree.root.get_node_or_null("VNOverlayLayer")
	if host != null:
		host.queue_free()

func _is_vn_overlay() -> bool:
	var host: Node = get_parent()
	return host != null and host.name == "VNOverlayLayer"

## Vellum commence must render above overlay VNs (layer 300) — not on current_scene.
func _spawn_vn_animation(anim_key: String) -> void:
	var anim: CanvasLayer = _ANIMATION_SCENE.new()
	anim.name = "VNAnimation"
	var flip: bool = anim_key == "animation_vellum_card_commence_flip"
	var parent: Node
	if _is_vn_overlay():
		parent = get_tree().root
	else:
		parent = get_tree().current_scene
		if parent == null:
			parent = self
	parent.add_child(anim)
	if _is_vn_overlay():
		anim.layer = 310
	anim.call("launch", flip)

func play_scene(
		json_path: String,
		on_complete: Callable,
		track_checkpoint: bool = false,
		chapter_arc_key: String = "") -> void:
	_on_complete = on_complete
	_track_campaign_checkpoint = track_checkpoint
	_chapter_arc_key = chapter_arc_key.strip_edges()
	if _chapter_arc_key.is_empty() and track_checkpoint:
		_chapter_arc_key = SaveManager.resolve_chapter_key_for_vn(json_path)

	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_warning("VNPlayer: cannot open '%s'" % json_path)
		_finish()
		return

	var raw := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(raw)
	if parsed == null or not parsed is Array:
		push_warning("VNPlayer: invalid JSON in '%s'" % json_path)
		_finish()
		return

	# Filter beats by hidden/NSFW flags, tracking original JSON indices for bug tagging.
	_scene_path = json_path
	_beats = []
	_beat_raw_indices = []
	var raw_beats: Array = parsed as Array
	for _ri: int in range(raw_beats.size()):
		var _rb: Variant = raw_beats[_ri]
		if (_rb as Dictionary).get("hidden", false):
			continue
		var _flag: String = str((_rb as Dictionary).get("nsfw", "both")).to_lower()
		if _flag == "safe" and SaveManager.nsfw_enabled:
			continue
		if _flag == "nsfw" and not SaveManager.nsfw_enabled:
			continue
		_beats.append(_rb)
		_beat_raw_indices.append(_ri)
	_beat_index = 0
	if _track_campaign_checkpoint:
		var resume_at: int = SaveManager.get_vn_checkpoint(json_path)
		if resume_at <= 0 and not _chapter_arc_key.is_empty():
			var arc: Dictionary = SaveManager.get_chapter_arc(_chapter_arc_key)
			if str(arc.get("vn_path", "")).strip_edges() == json_path.strip_edges():
				resume_at = int(arc.get("vn_beat_index", 0))
		if resume_at > 0 and resume_at < _beats.size():
			_beat_index = resume_at
			# Campaign gallery fades BGM out before continue; replay music from skipped beats.
			_apply_music_state(_music_state_before_beat(_beat_index), true)
	call_deferred("_start_playback")

func _start_playback() -> void:
	await get_tree().process_frame
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_apply_stage_layout(vp)
	_show_beat()

# ─────────────────────────────────────────────────────────────
# Beat rendering
# ─────────────────────────────────────────────────────────────

## Scene-change / battle actions that must run on the same beat after wait/center-text.
func _beat_has_deferred_actions(beat: Dictionary) -> bool:
	if beat.get("start_battle", false):
		return true
	if str(beat.get("tutorial_battle", "")).strip_edges() != "":
		return true
	if str(beat.get("exploration_call", "")).strip_edges() != "":
		return true
	if str(beat.get("dungeon_call", "")).strip_edges() != "":
		return true
	if beat.get("go_to_campaign_gallery", false):
		return true
	if beat.get("go_to_quick_duel", false):
		return true
	if beat.get("go_to_credits", false):
		return true
	if str(beat.get("call_scene", "")).strip_edges() != "":
		return true
	return false

func _show_beat() -> void:
	if _beat_index >= _beats.size():
		_finish()
		return

	var beat: Dictionary = _beats[_beat_index]
	_beat_index += 1
	_persist_campaign_checkpoint()
	_preserve_bgm_for_exploration = bool(beat.get("exploration_keep_vn_bgm", false)) \
		and str(beat.get("exploration_call", "")).strip_edges() != ""

	# ── Debug message ──
	if beat.has("debug"):
		print("[VNPlayer] beat %d — %s" % [_beat_index, str(beat.get("debug", ""))])

	# ── Video ──
	if beat.has("video"):
		var vid_path: String = str(beat["video"])
		var stream := load(vid_path) as VideoStream
		if stream:
			_accepting_input      = false
			_hide_hint_icon()
			_dialog_panel.visible = false
			_video_player.stream  = stream
			_video_player.visible = true
			_video_player.play()
			return
		else:
			push_warning("VNPlayer: failed to load video '%s' — skipping beat" % vid_path)
			_show_beat()
			return

	# Restore dialog panel for all non-video beats
	_dialog_panel.visible = true

	# ── Fade out (before visuals update) ──
	if beat.has("fade_out"):
		var dur: float = maxf(float(beat.get("fade_out", 0.5)), 0.01)
		if beat.has("fade_color"):
			var fc := Color.html(beat.get("fade_color", "#000000"))
			_fade_rect.color = Color(fc.r, fc.g, fc.b, _fade_rect.color.a)
		_ensure_fade_overlay_ready()
		_accepting_input = false
		_hide_hint_icon()
		var tw := create_tween()
		tw.tween_property(_fade_rect, "color:a", 1.0, dur)
		await tw.finished
		_accepting_input = true

	# ── Background ──
	if beat.has("background"):
		var bg_val = beat["background"]
		if bg_val == null:
			_kb_stop_reset()
			_bg_rect.texture  = null
			_bg_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
			_current_bg_path  = ""
		else:
			var bg_path: String = bg_val
			if bg_path != "":
				if bg_path != _current_bg_path:
					_kb_stop_reset()
					_current_bg_path = bg_path
					var tex := load(bg_path) as Texture2D
					if tex:
						_bg_rect.texture  = tex
					else:
						push_warning("VNPlayer: failed to load background '%s'" % bg_path)
				if _bg_rect.texture != null:
					_bg_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_update_backdrop_visibility()

	# ── Background colour ──
	if beat.has("bg_color"):
		_bg_base.color = Color.html(str(beat.get("bg_color", "#000000")))

	# ── Ken Burns (slow zoom/pan on background) ──
	if beat.has("bg_ken_burns"):
		var kb = beat["bg_ken_burns"]
		var zoom: float = float(kb.get("zoom", 1.05))
		var pan_x: float = float(kb.get("pan_x", 0.0))
		var pan_y: float = float(kb.get("pan_y", 0.0))
		var dur: float  = maxf(float(kb.get("duration", 4.0)), 0.1)
		if _kb_tween != null:
			_kb_tween.kill()
		_kb_tween = create_tween()
		_kb_tween.set_parallel(true)
		_kb_tween.tween_property(_bg_rect, "scale",    Vector2(zoom, zoom),  dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_kb_tween.tween_property(_bg_rect, "position", Vector2(pan_x, pan_y), dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# ── Characters ──
	# Skip entirely when linger_characters is set — keep previous beat's sprites.
	if not beat.get("linger_characters", false):
		for i in SLOT_NAMES.size():
			var sn: String = SLOT_NAMES[i]
			_char_slots[sn].texture  = null
			_char_slots[sn].flip_h   = false
			_char_slots[sn].size     = Vector2(CHAR_W, CHAR_H)
			_char_slots[sn].position = Vector2(SLOT_X[i], CHAR_Y)
			_char_slots[sn].modulate = Color(1.0, 1.0, 1.0, 0.0)
	if not beat.get("linger_characters", false) and beat.has("characters"):
		var char_data: Array = beat["characters"]
		var active_slots: Array = []
		for ci in char_data:
			var pos_name: String = ci.get("position", "center")
			var spr_path: String = ci.get("sprite", "")
			if not _char_slots.has(pos_name):
				continue
			if spr_path != "":
				var tex := load(spr_path) as Texture2D
				if tex:
					# Crop bottom percentage by using an AtlasTexture sub-region
					var crop: float     = clampf(float(ci.get("crop_bottom", 0.0)), 0.0, 99.0)
					var src_w: float    = float(tex.get_width())
					var src_h: float    = float(tex.get_height())
					var visible_h: float = src_h * (1.0 - crop / 100.0)
					var display_tex: Texture2D = tex
					if crop > 0.0:
						var atlas := AtlasTexture.new()
						atlas.atlas  = tex
						atlas.region = Rect2(0.0, 0.0, src_w, visible_h)
						display_tex  = atlas
					var scale_pct: float    = clampf(float(ci.get("scale", 100.0)), 10.0, 500.0)
					var scale_factor: float = scale_pct / 100.0
					var draw_w: float       = CHAR_W * scale_factor
					var draw_h: float       = draw_w * visible_h / src_w
					var slot_idx: int       = SLOT_NAMES.find(pos_name)
					_char_slots[pos_name].size         = Vector2(draw_w, draw_h)
					_char_slots[pos_name].position.x   = SLOT_X[slot_idx] + (CHAR_W - draw_w) / 2.0
					_char_slots[pos_name].position.y   = DIALOG_Y - draw_h
					_char_slots[pos_name].stretch_mode = TextureRect.STRETCH_SCALE
					_char_slots[pos_name].texture      = display_tex
					_char_slots[pos_name].flip_h       = ci.get("flip", false)
					_char_slots[pos_name].modulate     = Color(1.0, 1.0, 1.0, 1.0)
					active_slots.append(pos_name)
				else:
					push_warning("VNPlayer: failed to load character sprite '%s'" % spr_path)
		if beat.get("dim_others", false) and active_slots.size() > 0:
			for sn in SLOT_NAMES:
				if _char_slots[sn].texture != null and sn not in active_slots:
					_char_slots[sn].modulate = Color(0.38, 0.38, 0.38, 1.0)

	# ── Speaker ──
	var speaker: String = _loc(beat.get("speaker", ""))
	if speaker != "":
		_speaker_lbl.text      = speaker
		_speaker_panel.reset_size()
		var ph: float = _speaker_panel.get_minimum_size().y
		_speaker_panel.position.y = -ph
		_speaker_panel.visible = true
	else:
		_speaker_panel.visible = false

	# ── Dialog text ──
	_dialog_lbl.text = ""
	_dialog_lbl.append_text(_loc(beat.get("text", "")))

	# ── Hide messagebox ──
	if beat.get("hide_dialog", false):
		_dialog_panel.visible = false

	# ── Music ──
	if beat.has("music"):
		var music_val = beat["music"]
		var music_path: String = music_val if music_val != null else ""
		_set_music(music_path,
			beat.get("music_fade_out", 0.0),
			beat.get("music_fade_in",  0.0))
	elif beat.has("music_fade_out"):
		_set_music("", beat.get("music_fade_out", 0.0), 0.0)

	# ── Sound effect ──
	var sfx_path: String = beat.get("sfx", beat.get("sound", ""))
	if sfx_path != "":
		var vol_pct: float = clampf(float(beat.get("sfx_volume", beat.get("sound_volume", 100.0))), 0.0, 200.0)
		var vol_db: float  = -80.0 if vol_pct <= 0.0 else linear_to_db(vol_pct / 100.0)
		_play_sfx(sfx_path, vol_db)

	# ── Character shake ──
	var shake_val = beat.get("shake", null)
	if shake_val != null:
		_do_shake(shake_val, beat.get("shake_magnitude", 8.0))

	# ── Screen shake ──
	var screen_shake = beat.get("shake_screen", null)
	if screen_shake != null:
		var smag: float = 10.0
		if screen_shake is bool:
			if not screen_shake:
				smag = 0.0
		elif screen_shake is float or screen_shake is int:
			smag = float(screen_shake)
		if smag > 0.0:
			_do_screen_shake(smag)

	# ── Fade in (after visuals update) ──
	if beat.has("fade_in"):
		var dur: float = maxf(float(beat.get("fade_in", 0.5)), 0.01)
		if beat.has("fade_color"):
			var fc := Color.html(beat.get("fade_color", "#000000"))
			_fade_rect.color = Color(fc.r, fc.g, fc.b, _fade_rect.color.a)
		_ensure_fade_overlay_ready()
		_accepting_input = false
		_hide_hint_icon()
		var tw := create_tween()
		tw.tween_property(_fade_rect, "color:a", 0.0, dur)
		await tw.finished
		_accepting_input = true

	# ── Flash effect ──
	if beat.has("flash_count") or beat.has("flash_color"):
		var count: int   = int(beat.get("flash_count", 1))
		var dur: float   = maxf(float(beat.get("flash_duration", 0.2)), 0.01)
		var delay: float = maxf(float(beat.get("flash_delay", 0.05)), 0.0)
		var fc := Color.html(beat.get("flash_color", "#ffffff"))
		var target       = beat.get("flash_target", "screen")
		_accepting_input = false
		_hide_hint_icon()
		await _do_flash(fc, count, dur, delay, target)
		_accepting_input = true

	# ── Animation (fire-and-forget overlay) ──
	var anim_key: String = str(beat.get("animation", ""))
	if anim_key != "":
		_spawn_vn_animation(anim_key)

	# ── Wait (auto-advance after N seconds, blocks input) ──
	var wait_sec: float = beat.get("wait", 0.0)
	if wait_sec > 0.0:
		_accepting_input = false
		_hide_hint_icon()
		await get_tree().create_timer(wait_sec).timeout
		_accepting_input = true
		if not _beat_has_deferred_actions(beat):
			_show_beat()
			return

	# ── Auto-advance if screen is fully covered and there is nothing to read ──
	# After a fade_out with no text the screen is black — hint icon is invisible,
	# so waiting for a click makes no sense. Skip to the next beat automatically.
	if beat.has("fade_out") and not beat.has("text") \
			and not _beat_has_deferred_actions(beat):
		_show_beat()
		return

	# ── Center text (title-card with fade in/hold/fade out) ──
	var center_txt: String = str(beat.get("center_text", ""))
	if center_txt != "":
		_dialog_panel.visible = false
		_accepting_input = false
		_hide_hint_icon()
		var lbl := Label.new()
		lbl.text = center_txt
		lbl.add_theme_font_size_override("font_size", int(beat.get("center_text_size", 48)))
		lbl.add_theme_color_override("font_color", Color.WHITE)
		_apply_text_shadow(lbl)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
		lbl.position             = Vector2(0.0, 0.0)
		lbl.size                 = Vector2(1600.0, 900.0)
		lbl.modulate.a = 0.0
		lbl.z_index    = 60    # above _fade_rect so it always shows
		add_child(lbl)
		var fi: float = maxf(float(beat.get("center_text_fade_in",  0.8)), 0.01)
		var ho: float = maxf(float(beat.get("center_text_hold",     1.5)), 0.0)
		var fo: float = maxf(float(beat.get("center_text_fade_out", 0.8)), 0.01)
		var tw := create_tween()
		tw.tween_property(lbl, "modulate:a", 1.0, fi)
		tw.tween_interval(ho)
		tw.tween_property(lbl, "modulate:a", 0.0, fo)
		await tw.finished
		lbl.queue_free()
		_accepting_input = true
		if not _beat_has_deferred_actions(beat):
			_show_beat()
			return

	# ── Battle portraits (set before optional start_battle) ──
	if beat.has("portrait_p1"):
		GameState.player_portraits[0] = str(beat["portrait_p1"])
	if beat.has("portrait_p2"):
		GameState.player_portraits[1] = str(beat["portrait_p2"])

	# ── Tutorial battle (config JSON — no builder UI) ──
	var tutorial_path: String = str(beat.get("tutorial_battle", "")).strip_edges()
	if tutorial_path != "":
		if SaveManager.is_attack_tutorial_complete():
			await _skip_completed_tutorial_battle(beat)
			return
		if not GameState.quick_duel_launch:
			GlobalStatManager.on_prologue_tutorial_battle_reached()
		_battle_handoff_started = true
		_accepting_input = false
		_hide_hint_icon()
		_set_music("", 0.0, 0.0)
		GameState.new_game(GameState.GameMode.VS_AI)
		var run_missions: bool = GameState.quick_duel_launch \
			or not SaveManager.is_attack_tutorial_complete()
		var tut_err: String = TutorialBattleManager.configure_battle_from_path(
			tutorial_path, run_missions)
		if not tut_err.is_empty():
			push_error(tut_err)
			_accepting_input = true
			_show_beat()
			return
		GameState.apply_tutorial_opponent_crystals()
		_apply_beat_battle_display(beat, true)
		GameState.vn_on_win  = str(beat.get("on_win",  ""))
		GameState.vn_on_lose = str(beat.get("on_lose", ""))
		var tut_battle_rewards: Variant = beat.get("battle_reward", [])
		GameState.vn_battle_rewards = tut_battle_rewards if tut_battle_rewards is Array else []
		await CheckerTransition.fade_out_to_battle(func() -> void:
			VNPlayer.dismiss_overlay_if_present(get_tree())
			get_tree().change_scene_to_file("res://scenes/game_board.tscn"))
		return

	# ── Start battle ──
	if beat.get("start_battle", false):
		_battle_handoff_started = true
		_accepting_input = false
		_hide_hint_icon()
		if _scene_path.find("ch1_s1_pre_DEMO_PART2") >= 0:
			GameState.analytics_battle_tag = "ch1_stage1_boss"
			GlobalStatManager.on_chapter1_boss_reached()
		GameState.quick_duel_protagonist_id = "nex"
		GlobalStatManager.on_duel_started({"is_quick_duel": false, "is_tutorial": false})
		if exploration_overlay and ExplorationManager.is_session_active:
			ExplorationManager.snapshot_bgm_before_vn()
			ExplorationManager.save_session_now()
		_set_music("", 0.0, 0.0)
		# Always VS_AI for VN-configured battles (enemy_deck + AI setup).
		# EXPLORATION mode breaks setup — GameBoard expects AI to place P2.
		GameState.new_game(GameState.GameMode.VS_AI)
		GameState.apply_battle_start_crystals(beat)
		if exploration_overlay and ExplorationManager.is_session_active:
			GameState.vn_launched_from_exploration = true
		# Set post-new_game fields (new_game resets most state but not these)
		GameState.vn_on_win  = str(beat.get("on_win",  ""))
		GameState.vn_on_lose = str(beat.get("on_lose", ""))
		var battle_rewards: Variant = beat.get("battle_reward", [])
		GameState.vn_battle_rewards = battle_rewards if battle_rewards is Array else []
		var loss_rewards: Variant = beat.get("battle_loss_reward", [])
		GameState.vn_battle_loss_rewards = loss_rewards if loss_rewards is Array else []
		GameState.vn_battle_loss_reward_once = str(beat.get("battle_loss_reward_once", "")).strip_edges()
		_apply_beat_battle_display(beat)
		GameState.apply_battle_audio_config(beat)
		# Enemy deck — vault entry overrides inline enemy_deck + ai_forced_cells
		var vault_cfg: Dictionary = AIDeckVault.resolve_vault_from_dict(beat)
		if bool(vault_cfg.get("ok", false)):
			AIDeckVault.apply_enemy_battle_config(vault_cfg)
		else:
			var enemy_deck: Variant = beat.get("enemy_deck", null)
			var deck_chars: Array = []
			var deck_traps: Array = []
			var deck_tech: Array = []
			if enemy_deck is Dictionary:
				deck_chars = (enemy_deck as Dictionary).get("characters", [])
				deck_traps = (enemy_deck as Dictionary).get("traps", [])
				deck_tech = (enemy_deck as Dictionary).get("tech", [])
				GameState.battle_ai_deck = DeckData.deck_dict_to_deck_data(enemy_deck as Dictionary)
			else:
				GameState.battle_ai_deck = null
			var merged_tech: Array = DailyDungeonManager.resolve_enemy_forced_tech(
				beat.get("ai_forced_tech", []), deck_tech)
			var has_tech: bool = false
			for t: Variant in merged_tech:
				if str(t).strip_edges() != "":
					has_tech = true
					break
			if not deck_chars.is_empty() or not deck_traps.is_empty() or has_tech:
				GameState.campaign_enemy_config = {
					"forced_characters": deck_chars,
					"forced_traps":      deck_traps,
					"forced_tech":       merged_tech,
				}
			else:
				GameState.campaign_enemy_config = {}
			var afc_inline: Variant = beat.get("ai_forced_cells", null)
			GameState.battle_ai_forced_cells = afc_inline if afc_inline is Array else []
		# AI personality overrides (empty string = pick randomly)
		var _apd: String = str(beat.get("ai_personality_defensive", ""))
		var _apo: String = str(beat.get("ai_personality_offensive", ""))
		var _aps: String = str(beat.get("ai_personality_social",    ""))
		if _apd != "": GameState.campaign_enemy_config["ai_personality_defensive"] = _apd
		if _apo != "": GameState.campaign_enemy_config["ai_personality_offensive"] = _apo
		if _aps != "": GameState.campaign_enemy_config["ai_personality_social"]    = _aps
		# Optional player deck override — empty = active save deck at setup
		var player_deck_raw: Variant = beat.get("player_deck", null)
		if player_deck_raw is Dictionary:
			GameState.battle_player_deck = DeckData.deck_dict_to_deck_data(player_deck_raw as Dictionary)
		else:
			GameState.battle_player_deck = null
		# Union summon + forced placement config
		# Flag tells new_game() not to reset these values when the scene loads
		GameState._vn_battle_pending          = true
		GameState.battle_ai_union_enabled     = bool(beat.get("ai_union_enabled",     true))
		GameState.battle_player_union_enabled = bool(beat.get("player_union_enabled", true))
		var pfc: Variant = beat.get("player_forced_cells", null)
		GameState.battle_player_forced_cells  = pfc if pfc is Array else []
		await CheckerTransition.fade_out_to_battle(func() -> void:
			get_tree().change_scene_to_file("res://scenes/game_board.tscn"))
		return

	# ── Exploration call ──
	var expl_graph: String = str(beat.get("exploration_call", "")).strip_edges()
	if expl_graph != "":
		var chapter_key: String = _chapter_arc_key
		if chapter_key.is_empty():
			chapter_key = SaveManager.resolve_chapter_key_for_vn(_scene_path)
		if chapter_key.is_empty():
			chapter_key = _scene_path
		_chapter_arc_key = chapter_key
		var on_return: String = str(beat.get("exploration_on_return", "")).strip_edges()
		SaveManager.update_chapter_arc_exploration(
			chapter_key, expl_graph, on_return, _scene_path, _beat_index)
		var keep_vn_bgm: bool = bool(beat.get("exploration_keep_vn_bgm", false))
		if not keep_vn_bgm:
			_set_music("", 0.0, 0.0)
		var params: Dictionary = {}
		var expl_params: Variant = beat.get("exploration_params", null)
		if expl_params is Dictionary:
			for k: Variant in (expl_params as Dictionary):
				params[str(k)] = (expl_params as Dictionary)[k]
		if keep_vn_bgm:
			params["keep_vn_bgm"] = true
		ExplorationManager.pending_return_vn = on_return
		ExplorationManager.launch_source_vn = _scene_path
		var return_scene: String = get_tree().current_scene.scene_file_path
		if return_scene.is_empty():
			return_scene = "res://scenes/main_menu.tscn"
		await _prepare_scene_handoff()
		ExplorationManager.launch(expl_graph, return_scene, params)
		var inv: Variant = beat.get("exploration_inventory", null)
		if inv is Array:
			for item_var: Variant in (inv as Array):
				var item_id: String = str(item_var).strip_edges()
				if not item_id.is_empty():
					ExplorationManager.add_item(item_id)
		return

	# ── Dungeon call ──
	var dungeon_id: String = str(beat.get("dungeon_call", ""))
	if dungeon_id != "":
		var chapter_key: String = _chapter_arc_key
		if chapter_key.is_empty():
			chapter_key = SaveManager.resolve_chapter_key_for_vn(_scene_path)
		if chapter_key.is_empty():
			chapter_key = _scene_path
		_chapter_arc_key = chapter_key
		SaveManager.update_chapter_arc_dungeon(chapter_key, dungeon_id)
		_set_music("", 0.0, 0.0)
		DailyDungeonManager.begin_story_session(
			dungeon_id,
			str(beat.get("dungeon_on_win", "")),
			str(beat.get("dungeon_on_lose", "")),
			_scene_path)
		SaveManager.save_data()
		CheckerTransition.fade_out_to_battle(func() -> void:
			get_tree().change_scene_to_file(DailyDungeonManager.DUNGEON_MAP_SCENE))
		return

	# ── Campaign gallery unlock + navigation ──
	var complete_gallery: String = _resolve_gallery_chapter_end(beat)
	if not complete_gallery.is_empty():
		var card: Dictionary = SaveManager.get_gallery_card_for_chapter(complete_gallery)
		SaveManager.finalize_chapter_arc(complete_gallery, card)

	if beat.get("go_to_campaign_gallery", false):
		_set_music("", 0.0, 0.0)
		_accepting_input = false
		_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
		var gal_tw := create_tween()
		gal_tw.tween_property(_fade_rect, "color:a", 1.0, 1.0)
		await gal_tw.finished
		GameState.open_campaign_gallery_on_menu = true
		queue_free()
		MainMenuReturnLoader.return_to_main_menu()
		return

	if beat.get("go_to_quick_duel", false):
		_set_music("", 0.0, 0.0)
		_accepting_input = false
		_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
		var qd_tw := create_tween()
		qd_tw.tween_property(_fade_rect, "color:a", 1.0, 1.0)
		await qd_tw.finished
		GlobalStatManager.on_first_touch("quick_duel_menu")
		GameState.open_quick_duel_overlay_on_menu = true
		queue_free()
		MainMenuReturnLoader.return_to_main_menu()
		return

	# ── Credits ──
	if beat.get("go_to_credits", false):
		_set_music("", 0.0, 0.0)
		_accepting_input = false
		_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
		var cred_tw := create_tween()
		cred_tw.tween_property(_fade_rect, "color:a", 1.0, 1.0)
		await cred_tw.finished
		var cred_scene: String = "res://scenes/credit_demo.tscn" \
			if str(beat.get("credits_target", "")) == "demo" \
			else "res://scenes/credits.tscn"
		get_tree().change_scene_to_file(cred_scene)
		return

	# ── Special Command / Call Scene ──
	var _call_scene: String = str(beat.get("call_scene", ""))
	if _call_scene != "":
		_set_music("", 0.0, 0.0)
		_accepting_input = false
		_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
		var _sc_tw := create_tween()
		_sc_tw.tween_property(_fade_rect, "color:a", 1.0, 1.0)
		await _sc_tw.finished
		var _scene_map: Dictionary = {
			"credit":        "res://scenes/credits.tscn",
			"credit_demo":   "res://scenes/credit_demo.tscn",
			"photo_scatter": "res://scenes/photo_scatter.tscn",
		}
		var _target: String = _scene_map.get(_call_scene, "")
		if _target != "":
			queue_free()
			get_tree().change_scene_to_file(_target)
		return

	# ── Exploration session actions ──
	# exploration_actions fires give_item / remove_item / set_var / etc. on
	# ExplorationManager when a VN beat is displayed, only during an active session.
	# Format: [{ "action": "give_item", "key": "rusty_key", "value": "" }, ...]
	var expl_actions: Variant = beat.get("exploration_actions", null)
	if expl_actions is Array and ExplorationManager.is_session_active:
		for ea: Variant in (expl_actions as Array):
			if ea is Dictionary:
				var ead: Dictionary = ea as Dictionary
				ExplorationManager.dispatch_event(
					str(ead.get("action", "")),
					str(ead.get("key",    "")),
					str(ead.get("value",  "")))

	# ── Continue hint icon ──
	_show_hint_icon()

func _on_video_finished() -> void:
	_video_player.visible  = false
	_video_player.stream   = null
	_dialog_panel.visible  = true
	_accepting_input       = true
	_show_beat()

func _finish() -> void:
	_hide_hint_icon()
	if not exploration_overlay:
		_set_music("", 0.0, 0.0)
	if _on_complete.is_valid():
		_on_complete.call()
	queue_free()


func _await_game_dialog_accept(title: String, body: String) -> void:
	if GameDialog.has_open_overlay(self):
		return
	var closed: Array[bool] = [false]
	GameDialog.accept_overlay(
		self,
		title,
		body,
		"OK",
		func() -> void: closed[0] = true)
	while not closed[0]:
		await get_tree().process_frame


func _skip_completed_tutorial_battle(beat: Dictionary) -> void:
	_accepting_input = false
	_hide_hint_icon()
	await _await_game_dialog_accept(
		"Tutorial Already Complete",
		"You've already finished the tutorial in Quick Duel mode. This tutorial will be skipped.")
	var on_win: String = str(beat.get("on_win", "")).strip_edges()
	if on_win.is_empty():
		_accepting_input = true
		_show_beat()
		return
	play_scene(on_win, _on_complete, _track_campaign_checkpoint, _chapter_arc_key)


## Fade to black and hide campaign-gallery chrome before scene handoffs.
## VNs launched from CampaignGallery sit on top of the gallery overlay; without
## this, checker transitions can briefly reveal chapter cards around the 1600×900 stage.
func _prepare_scene_handoff(fade_sec: float = 0.35) -> void:
	_accepting_input = false
	_hide_hint_icon()
	if _dialog_panel != null:
		_dialog_panel.visible = false
	var host: Node = get_parent()
	if host != null:
		for child: Node in host.get_children():
			if child != self:
				child.visible = false
	if _fade_rect != null:
		_ensure_fade_overlay_ready()
		_fade_rect.color = Color(0.0, 0.0, 0.0, _fade_rect.color.a)
		var tw := create_tween()
		tw.tween_property(_fade_rect, "color:a", 1.0, maxf(fade_sec, 0.01))
		await tw.finished

func _persist_campaign_checkpoint() -> void:
	if not _track_campaign_checkpoint or _scene_path.is_empty():
		return
	if _beat_index <= 0:
		return
	if not _chapter_arc_key.is_empty():
		SaveManager.set_vn_checkpoint_for_chapter(_chapter_arc_key, _scene_path, _beat_index)
	else:
		SaveManager.set_vn_checkpoint(_scene_path, _beat_index)

# ─────────────────────────────────────────────────────────────
# Bug tagging (Ctrl+Shift+A → "tag_bug")
# ─────────────────────────────────────────────────────────────
const _BUG_TAGS_PATH := "user://vn_bug_tags.json"

func _toggle_cmd_panel() -> void:
	if _cmd_panel == null:
		return
	_cmd_panel.visible = not _cmd_panel.visible
	if _cmd_panel.visible:
		_cmd_input.clear()
		_cmd_input.grab_focus()

func _handle_vn_command(raw: String) -> void:
	_cmd_panel.visible = false
	var trimmed: String = raw.strip_edges()
	if trimmed.to_lower().begins_with("tag_bug"):
		var note: String = trimmed.substr(7).strip_edges()  # everything after "tag_bug"
		_tag_current_beat(note)
	else:
		_show_vn_toast("Unknown command: " + raw)

func _tag_current_beat(note: String) -> void:
	if _beat_index <= 0 or _beat_index > _beat_raw_indices.size():
		_show_vn_toast("Nothing to tag.")
		return
	var raw_idx: int = _beat_raw_indices[_beat_index - 1]
	var tags: Dictionary = _vn_load_bug_tags()
	if not tags.has(_scene_path):
		tags[_scene_path] = {}
	var file_tags: Dictionary = tags[_scene_path] as Dictionary
	file_tags[str(raw_idx)] = note
	tags[_scene_path] = file_tags
	_vn_save_bug_tags(tags)
	var msg: String = "Bug tagged  —  beat #%d  (%s)" % [raw_idx + 1, _scene_path.get_file()]
	if not note.is_empty():
		msg += "\n" + note
	_show_vn_toast(msg)

func _vn_load_bug_tags() -> Dictionary:
	if not FileAccess.file_exists(_BUG_TAGS_PATH):
		return {}
	var f := FileAccess.open(_BUG_TAGS_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}

func _vn_save_bug_tags(tags: Dictionary) -> void:
	var f := FileAccess.open(_BUG_TAGS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(tags, "\t"))
	f.close()

func _show_vn_toast(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl.offset_top = 60.0
	lbl.z_index = 201
	add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)

# ─────────────────────────────────────────────────────────────
# Sound effect — fire and forget
# ─────────────────────────────────────────────────────────────
func _play_sfx(path: String, vol_db: float = 0.0) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream    = stream
	player.volume_db = vol_db
	player.bus       = &"SFX"
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

# ─────────────────────────────────────────────────────────────
# Music — looping BGM, one track at a time, with fade in/out
# ─────────────────────────────────────────────────────────────
## Effective music after beats [0, up_to_index) — used when resuming a saved checkpoint.
func _music_state_before_beat(up_to_index: int) -> Dictionary:
	var path: String = ""
	var fade_out: float = 0.0
	var fade_in: float = 0.0
	for i: int in range(mini(up_to_index, _beats.size())):
		var beat: Dictionary = _beats[i]
		if beat.has("music"):
			var music_val = beat["music"]
			path = str(music_val).strip_edges() if music_val != null else ""
			fade_out = float(beat.get("music_fade_out", 0.0))
			fade_in = float(beat.get("music_fade_in", 0.0))
		elif beat.has("music_fade_out"):
			path = ""
			fade_out = float(beat.get("music_fade_out", 0.0))
			fade_in = 0.0
	return {"path": path, "fade_out": fade_out, "fade_in": fade_in}


func _apply_music_state(state: Dictionary, skip_fade_out: bool = false) -> void:
	var fade_out: float = 0.0 if skip_fade_out else float(state.get("fade_out", 0.0))
	_set_music(str(state.get("path", "")).strip_edges(), fade_out, float(state.get("fade_in", 0.0)))


func _set_music(path: String, fade_out: float = 0.0, fade_in: float = 0.0) -> void:
	if keep_bgm or _preserve_bgm_for_exploration:
		return
	var normalized := path.strip_edges()
	if normalized == BGMManager.get_current_path():
		return
	_current_music_path = normalized

	if normalized.is_empty():
		BGMManager.stop(fade_out)
		return

	BGMManager.play_path(normalized, fade_in, fade_out, 100.0, BGMManager.CONTEXT_VN)

# ─────────────────────────────────────────────────────────────
# Character shake — damped horizontal oscillation
# ─────────────────────────────────────────────────────────────
func _do_shake(shake_val, magnitude: float) -> void:
	var slots_to_shake: Array = []
	if shake_val is String and shake_val == "all":
		for sn in SLOT_NAMES:
			if _char_slots[sn].texture != null:
				slots_to_shake.append(_char_slots[sn])
	elif shake_val is Array:
		for sn in shake_val:
			if _char_slots.has(sn) and _char_slots[sn].texture != null:
				slots_to_shake.append(_char_slots[sn])

	var m: float = magnitude
	for slot in slots_to_shake:
		var ox: float = slot.position.x
		var tw := create_tween()
		tw.tween_property(slot, "position:x", ox + m,         0.035)
		tw.tween_property(slot, "position:x", ox - m,         0.035)
		tw.tween_property(slot, "position:x", ox + m * 0.75,  0.030)
		tw.tween_property(slot, "position:x", ox - m * 0.75,  0.030)
		tw.tween_property(slot, "position:x", ox + m * 0.375, 0.025)
		tw.tween_property(slot, "position:x", ox,             0.025)

# ─────────────────────────────────────────────────────────────
# Screen shake — shakes the entire stage in 2D
# ─────────────────────────────────────────────────────────────
func _do_screen_shake(magnitude: float) -> void:
	if _screen_shake_tween != null:
		_screen_shake_tween.kill()
		_screen_shake_tween = null
	if _stage_holder != null:
		_stage_holder.position = _stage_base_pos
	var ox: float = _stage_base_pos.x
	var oy: float = _stage_base_pos.y
	var m: float  = magnitude
	var tw := create_tween()
	_screen_shake_tween = tw
	tw.tween_property(_stage_holder, "position", Vector2(ox + m,          oy + m * 0.4),  0.03)
	tw.tween_property(_stage_holder, "position", Vector2(ox - m,          oy - m * 0.3),  0.03)
	tw.tween_property(_stage_holder, "position", Vector2(ox + m * 0.6,    oy + m * 0.2),  0.025)
	tw.tween_property(_stage_holder, "position", Vector2(ox - m * 0.4,    oy - m * 0.15), 0.025)
	tw.tween_property(_stage_holder, "position", Vector2(ox + m * 0.2,    oy + m * 0.05), 0.02)
	tw.tween_property(_stage_holder, "position", _stage_base_pos, 0.02)
	tw.finished.connect(func() -> void:
		if _screen_shake_tween == tw:
			_screen_shake_tween = null
	)

# ─────────────────────────────────────────────────────────────
# Ken Burns — stop animation and reset bg to neutral transform
# ─────────────────────────────────────────────────────────────
func _kb_stop_reset() -> void:
	if _kb_tween != null:
		_kb_tween.kill()
		_kb_tween = null
	_bg_rect.scale    = Vector2(1.0, 1.0)
	_bg_rect.position = Vector2(0.0, 0.0)

# ─────────────────────────────────────────────────────────────
# Flash — repeating overlay pulse (screen) or modulate pulse (characters)
# target: "screen" | "all" | ["left", "right", ...]
# ─────────────────────────────────────────────────────────────
func _do_flash(color: Color, count: int, duration: float, delay: float, target = "screen") -> void:
	var half: float = duration / 2.0

	# Resolve target to a list of character slots, or nil for screen mode
	var slots: Array = []
	if target != "screen":
		if target == "all":
			for sn in SLOT_NAMES:
				if _char_slots[sn].texture != null:
					slots.append(_char_slots[sn])
		elif target is Array:
			for sn in target:
				if _char_slots.has(sn) and _char_slots[sn].texture != null:
					slots.append(_char_slots[sn])

	# If character target but nothing visible, fall back to screen
	var use_screen: bool = target == "screen" or slots.is_empty()

	if use_screen:
		_ensure_fade_overlay_ready()
		_fade_rect.color = Color(color.r, color.g, color.b, 0.0)
		for i in count:
			var tw := create_tween()
			tw.tween_property(_fade_rect, "color:a", 1.0, half)
			tw.tween_property(_fade_rect, "color:a", 0.0, half)
			await tw.finished
			if delay > 0.0 and i < count - 1:
				await get_tree().create_timer(delay).timeout
	else:
		# Save original modulate for each slot (respects dim_others)
		var saved: Dictionary = {}
		for slot in slots:
			saved[slot] = slot.modulate
		for i in count:
			var tw1 := create_tween()
			tw1.set_parallel(true)
			for slot in slots:
				tw1.tween_property(slot, "modulate", color, half)
			await tw1.finished
			var tw2 := create_tween()
			tw2.set_parallel(true)
			for slot in slots:
				tw2.tween_property(slot, "modulate", saved[slot], half)
			await tw2.finished
			if delay > 0.0 and i < count - 1:
				await get_tree().create_timer(delay).timeout

# ─────────────────────────────────────────────────────────────
# Input
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			# Ctrl+Shift+A — toggle mini command panel
			if ke.ctrl_pressed and ke.shift_pressed and ke.keycode == KEY_A:
				_toggle_cmd_panel()
				get_viewport().set_input_as_handled()
				return
			# Escape — close command panel
			if ke.keycode == KEY_ESCAPE and _cmd_panel != null and _cmd_panel.visible:
				_cmd_panel.visible = false
				get_viewport().set_input_as_handled()
				return
	# Block beat advance while command panel is open
	if _cmd_panel != null and _cmd_panel.visible:
		return
	if not _accepting_input:
		return
	if _battle_handoff_started:
		return
	var advance := false
	if event is InputEventMouseButton:
		var mbe := event as InputEventMouseButton
		if mbe.pressed and mbe.button_index == MOUSE_BUTTON_LEFT:
			advance = true
	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			if ke.keycode == KEY_SPACE or ke.keycode == KEY_ENTER:
				advance = true
	if advance:
		get_viewport().set_input_as_handled()
		_show_beat()


## Apply optional P1/P2 display names and battle illustrations from a VN beat.
## When only_override_present is true (tutorial battles), beat fields override config
## only when explicitly present; otherwise tutorial JSON values are kept.
func _apply_beat_battle_display(beat: Dictionary, only_override_present: bool = false) -> void:
	if beat.has("portrait_p1"):
		GameState.player_portraits[0] = str(beat["portrait_p1"])
	if beat.has("portrait_p2"):
		GameState.player_portraits[1] = str(beat["portrait_p2"])
	if not only_override_present \
			or beat.has("portrait_p1_offset_x") or beat.has("portrait_p1_offset_y"):
		GameState.portrait_p1_offset = Vector2(
			float(beat.get("portrait_p1_offset_x", 0.0)),
			float(beat.get("portrait_p1_offset_y", 0.0)))
	if not only_override_present or beat.has("portrait_p1_size"):
		GameState.portrait_p1_size = float(beat.get("portrait_p1_size", 1.0))
	if not only_override_present \
			or beat.has("portrait_p2_offset_x") or beat.has("portrait_p2_offset_y"):
		GameState.portrait_p2_offset = Vector2(
			float(beat.get("portrait_p2_offset_x", 0.0)),
			float(beat.get("portrait_p2_offset_y", 0.0)))
	if not only_override_present or beat.has("portrait_p2_size"):
		GameState.portrait_p2_size = float(beat.get("portrait_p2_size", 1.0))
	if beat.has("ask_player_name"):
		GameState.battle_ask_player_name = _normalize_ask_player_name(
			str(beat.get("ask_player_name", "")))
	elif not only_override_present:
		GameState.battle_ask_player_name = ""
	if beat.has("player1_name") or beat.has("player2_name"):
		GameState.campaign_player_names = [
			str(beat.get("player1_name", "")).strip_edges(),
			str(beat.get("player2_name", "")).strip_edges(),
		]
	elif not only_override_present:
		var p1n: String = str(beat.get("player1_name", "")).strip_edges()
		var p2n: String = str(beat.get("player2_name", "")).strip_edges()
		if not p1n.is_empty() or not p2n.is_empty():
			GameState.campaign_player_names = [p1n, p2n]
		else:
			GameState.campaign_player_names = []


func _normalize_ask_player_name(raw: String) -> String:
	var key: String = raw.strip_edges().to_lower()
	if key in ["player1", "p1", "player_1"]:
		return "player1"
	if key in ["player2", "p2", "player_2"]:
		return "player2"
	if key == "both":
		return "both"
	return ""
