extends Control
class_name DetectiveNoteOverlay
## The detective note: chapter list, topic list, notebook area (notepaper with
## the verdict map) and the clue panels (individuals / objects / information).
##
## Open modes:
##   open_for_chapter() — exploration / VN entry points; chapter list hidden, topics only
##                        (Done button + bounce when the map is fully filled)
##   open_all()         — inventory NOTE tab; chapters + topics in the sidebar
##                        (Close button, no bounce)
##   open_stamp_view()  — pack-style flat notebook + verdict map (no ScrollContainer);
##                        plays the APPROVED stamp animation; click/key to dismiss
##
## Tap the dimmed margin outside the notebook panel (or Escape) to close in normal mode.
## Player interactions on the verdict map (delegated to DetectiveNoteVerdictMap):
##   drag clue tile → frame, drag between frames, drag back to the clue panel,
##   double-click or right-click a frame to remove.
## All placements route through DetectiveNoteManager (variables/flags + save).
## Stamped topics render read-only with the stamp shown permanently.

signal closed

const NOTEPAPER := "res://assets/textures/detective/ui_detective_notepaper_repeat.png"
const DIM_COLOR := Color(0.0, 0.0, 0.0, 0.60)
const PAPER_FALLBACK := Color(0.93, 0.89, 0.80)
const SIDEBAR_W := 250.0
const CLUEBAR_W := 300.0
## Shift empty-state copy left so it reads centered across the full three-column layout
## (left topics sidebar is narrower than the right clue panel).
const EMPTY_LBL_SHIFT_X := (CLUEBAR_W - SIDEBAR_W) * 0.5
const EMPTY_LBL_W := 320.0
const TILE_SIZE := DetectiveNoteVerdictMap.DRAG_PREVIEW_SIZE
const CLUE_NAME_FONT_SIZE := 12
const CLUE_NAME_MAX_LINES := 2
const CLUE_NAME_LINE_H := 17.0
## Space below the clue image: separator + up to two caption lines + padding.
const CLUE_CAPTION_TEXT_H := CLUE_NAME_LINE_H * float(CLUE_NAME_MAX_LINES) + 6.0
const CLUE_CAPTION_BLOCK_H := 4.0 + CLUE_CAPTION_TEXT_H + 4.0
const CLUE_TILE_PAD_TOP := 14.0
const CLUE_TILE_PAD_SIDE := 6.0
const CLUE_TILE_PAD_BOTTOM := 6.0
const CLUE_TILE_PANEL_MARGIN_V := CLUE_TILE_PAD_TOP + CLUE_TILE_PAD_BOTTOM
const HOVER_OPEN_SEC := 1.0
const HOVER_STEP_SEC := 0.25
const HOVER_MOVE_THRESHOLD_PX := 16.0
const KIND_TABS := ["individual", "object", "information"]
const KIND_LABELS := {"individual": "INDIVs.", "object": "OBJECTS", "information": "INFO"}
const DONE_BTN_SIZE := Vector2(210.0, 96.0)
const DONE_FONT_SIZE := 44
const DONE_TILT_DEG := 20.0
const DONE_PULSE_SCALE := 1.18
const DONE_PULSE_HALF_SEC := 0.55
const BTN_FILL := Color(0.20, 0.16, 0.12, 0.96)
const BTN_FILL_HOVER := Color(0.28, 0.22, 0.16, 0.98)
const BTN_FILL_SELECTED := Color(0.36, 0.26, 0.14, 0.98)
const BTN_BORDER := Color(0.82, 0.66, 0.38, 0.95)
const BTN_BORDER_SELECTED := Color(0.95, 0.82, 0.48, 1.0)
const DONE_FILL := Color(0.52, 0.10, 0.10, 0.96)
const DONE_FILL_HOVER := Color(0.66, 0.14, 0.14, 0.98)
const DONE_FILL_PRESSED := Color(0.40, 0.07, 0.07, 0.98)
const DONE_BORDER := Color(0.95, 0.78, 0.42, 1.0)
const NEW_BADGE_TILT_DEG := 14.0
const NEW_BADGE_PULSE_SCALE := 1.22
const NEW_BADGE_PULSE_HALF_SEC := 0.45
const NEW_BADGE_FONT_SIZE := 13
const NEW_BADGE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const NEW_BADGE_SHADOW := Color(0.0, 0.0, 0.0, 1.0)

var locale: String = "en"

var _active_chapter: String = ""
var _selected_chapter: String = ""
var _selected_topic: String = ""
var _all_chapters_mode: bool = false
var _stamp_view_mode: bool = false
var _stamp_view_dismissable: bool = false

var _root_panel: Control = null
var _chapter_vbox: VBoxContainer = null
var _chapter_header: Label = null
var _chapter_scroll: ScrollContainer = null
var _topic_vbox: VBoxContainer = null
var _topic_header: Label = null
var _topic_scroll: ScrollContainer = null
var _map: DetectiveNoteVerdictMap = null
var _map_host: Control = null
var _map_scroll: ScrollContainer = null
var _notebook_area: Control = null
var _notebook_root: Control = null
var _topic_title_lbl: Label = null
var _clue_tab_buttons: Dictionary = {}
var _clue_grid: GridContainer = null
var _clue_scroll: ScrollContainer = null
var _clue_kind: String = "individual"
var _empty_lbl: Label = null
var _done_btn: Button = null
var _done_pulse_tween: Tween = null
## Guards _fit_verdict_map against ScrollContainer.resized → fit → resized recursion
## (export hard-freeze / crash on stamp view).
var _fitting_map: bool = false
var _last_fit_avail_w: float = -1.0
var _fit_call_count: int = 0  # tests / diagnostics only
## Stored so stamp mode can disconnect resized→fit (deferred scrollbar oscillation).
var _map_scroll_fit_cb: Callable = Callable()

# Hover-hold (1s, deckbuilder-style) for clue tiles and filled frames
var _hover_clue_id: String = ""
var _hover_control: Control = null
var _hover_elapsed: float = 0.0
var _hover_anchor: Vector2 = Vector2.ZERO
var _detail_anchor_mouse: Vector2 = Vector2.ZERO
var _hover_dots: Label = null
var _detail_popup: Control = null

# Drag ghost (formation-page style — image follows cursor)
var _drag_ghost: Control = null
var _drag_ghost_active: bool = false


static func open_for_chapter(
		parent: Node, chapter_id: String, topic_id: String = "") -> DetectiveNoteOverlay:
	var overlay := _make()
	overlay._active_chapter = chapter_id.strip_edges()
	overlay._all_chapters_mode = false
	var tid: String = topic_id.strip_edges()
	if not tid.is_empty():
		overlay._selected_chapter = overlay._active_chapter
		overlay._selected_topic = tid
	_attach_to_viewport(overlay, parent)  # fields must be set before add_child (_ready)
	return overlay


static func open_all(parent: Node) -> DetectiveNoteOverlay:
	var overlay := _make()
	overlay._all_chapters_mode = true
	_attach_to_viewport(overlay, parent)
	return overlay


## Read-only notebook + verdict map with the stamp animation (VN show_note_stamp).
static func open_stamp_view(parent: Node, chapter_id: String, topic_id: String) -> DetectiveNoteOverlay:
	var overlay := _make()
	overlay._active_chapter = chapter_id.strip_edges()
	overlay._selected_chapter = chapter_id.strip_edges()
	overlay._selected_topic = topic_id.strip_edges()
	overlay._stamp_view_mode = true
	# Stamp must keep running even if the VN / tree is paused.
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_attach_to_viewport(overlay, parent)
	return overlay


## VN / exploration parents can be 0×0 on the first frame; mount on the viewport host instead.
static func _attach_to_viewport(overlay: DetectiveNoteOverlay, requester: Node) -> void:
	GameDialog.attach_viewport_overlay(overlay, requester)


static func _make() -> DetectiveNoteOverlay:
	var overlay := DetectiveNoteOverlay.new()
	overlay.name = "DetectiveNoteOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 250
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	return overlay


func _ready() -> void:
	if _stamp_view_mode:
		# Pack-style flat UI — never build ScrollContainer / fit machinery (export hang).
		_build_stamp_ui()
		_show_stamp_view()
		call_deferred("_sync_viewport_layout")
		call_deferred("_layout_stamp_map")
		return
	_build_ui()
	var chapters: Array = DetectiveNoteManager.get_unlocked_chapter_ids() \
		if _all_chapters_mode else DetectiveNoteVault.get_chapter_ids()
	if _selected_chapter.is_empty():
		if not _active_chapter.is_empty() and DetectiveNoteVault.get_chapter_ids().has(_active_chapter):
			# VN / exploration may open a chapter even if it is inventory-hidden.
			_selected_chapter = _active_chapter
		elif not chapters.is_empty():
			_selected_chapter = str(chapters[0])
	# Inventory never starts on a hidden or story-locked chapter.
	if _all_chapters_mode and (
			DetectiveNoteVault.is_chapter_hidden(_selected_chapter)
			or not DetectiveNoteManager.is_chapter_unlocked(_selected_chapter)):
		_selected_chapter = str(chapters[0]) if not chapters.is_empty() else ""
	_refresh_chapter_list()
	_select_chapter(_selected_chapter)
	call_deferred("_sync_viewport_layout")
	call_deferred("_fit_verdict_map")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_sync_viewport_layout")
		# Stamp: re-layout once host has a real size (no scroll fit).
		if _stamp_view_mode:
			call_deferred("_layout_stamp_map")
		else:
			call_deferred("_fit_verdict_map")


func _sync_viewport_layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	if size.x > 1.0 and size.y > 1.0:
		return
	# Fallback when the overlay host has not laid out yet (unit-test hosts, first frame).
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_right = vp.x
	offset_bottom = vp.y


func _input(event: InputEvent) -> void:
	if _stamp_view_mode:
		if not _stamp_view_dismissable:
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			_close()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo:
			_close()
			get_viewport().set_input_as_handled()
			return
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	_stop_done_btn_pulse()
	_hide_drag_ghost()
	# VN / exploration: closing dismisses remaining "New" badges for this chapter.
	if not _all_chapters_mode and not _stamp_view_mode and not _selected_chapter.is_empty():
		DetectiveNoteManager.mark_all_clues_seen(_selected_chapter)
	emit_signal("closed")
	queue_free()


func _make_done_button() -> Button:
	var btn := Button.new()
	# Inventory (all-chapters) uses Close with no bounce; VN/exploration keep Done + pulse.
	btn.text = "Close" if _all_chapters_mode else "Done"
	btn.custom_minimum_size = DONE_BTN_SIZE
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", FontManager.make_font("handwritten", 700))
	btn.add_theme_font_size_override("font_size", DONE_FONT_SIZE)
	btn.add_theme_color_override("font_color", Color(0.97, 0.93, 0.86))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.92))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.85, 0.75))
	_apply_note_button_skin(btn, DONE_FILL, DONE_FILL_HOVER, DONE_FILL_PRESSED, DONE_BORDER, DONE_BORDER, 3)
	btn.rotation_degrees = DONE_TILT_DEG
	btn.pressed.connect(_close)
	btn.resized.connect(func() -> void:
		btn.pivot_offset = btn.size * 0.5)
	return btn


## Flat fill + colored border for detective-note chrome (tabs / Done / Close).
func _apply_note_button_skin(
		btn: Button,
		fill: Color,
		hover_fill: Color,
		pressed_fill: Color,
		border: Color,
		pressed_border: Color,
		border_w: int = 2) -> void:
	var normal := _note_button_stylebox(fill, border, border_w)
	var hover := _note_button_stylebox(hover_fill, border.lightened(0.12), border_w)
	var pressed := _note_button_stylebox(pressed_fill, pressed_border, border_w + 1)
	var hover_pressed := _note_button_stylebox(
		pressed_fill.lightened(0.08), pressed_border.lightened(0.1), border_w + 1)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("hover_pressed", hover_pressed)
	btn.add_theme_stylebox_override("focus", normal.duplicate())
	btn.add_theme_stylebox_override("disabled", _note_button_stylebox(
		Color(fill.r, fill.g, fill.b, 0.45),
		Color(border.r, border.g, border.b, 0.35),
		border_w))


func _note_button_stylebox(fill: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_border_width_all(border_w)
	sb.border_color = border
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb


func _sync_done_btn_pulse() -> void:
	if _done_btn == null or not is_instance_valid(_done_btn):
		return
	# Inventory browse mode: never bounce the Close button.
	if _all_chapters_mode:
		_stop_done_btn_pulse()
		return
	var complete: bool = _map != null and is_instance_valid(_map) \
		and not _selected_topic.is_empty() and _map.is_map_fully_filled()
	if complete:
		_start_done_btn_pulse()
	else:
		_stop_done_btn_pulse()


func _start_done_btn_pulse() -> void:
	if _done_btn == null or not is_instance_valid(_done_btn):
		return
	if _all_chapters_mode:
		_stop_done_btn_pulse()
		return
	if _done_pulse_tween != null and is_instance_valid(_done_pulse_tween) \
			and _done_pulse_tween.is_running():
		return
	_stop_done_btn_pulse()
	_done_btn.pivot_offset = _done_btn.size * 0.5
	_done_btn.scale = Vector2.ONE
	_done_pulse_tween = create_tween().set_loops()
	_done_pulse_tween.tween_property(
		_done_btn, "scale", Vector2.ONE * DONE_PULSE_SCALE, DONE_PULSE_HALF_SEC) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_done_pulse_tween.tween_property(
		_done_btn, "scale", Vector2.ONE, DONE_PULSE_HALF_SEC) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_done_btn_pulse() -> void:
	if _done_pulse_tween != null and is_instance_valid(_done_pulse_tween):
		_done_pulse_tween.kill()
	_done_pulse_tween = null
	if _done_btn != null and is_instance_valid(_done_btn):
		_done_btn.scale = Vector2.ONE


# ─────────────────────────────────────────────────────────────
# UI construction
# ─────────────────────────────────────────────────────────────
## Stamp-only UI: pack-style flat overlay. No ScrollContainer, no HBox min-size
## fight, no `_fit_verdict_map` — those hang Godot's layout solver in export.
func _build_stamp_ui() -> void:
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if not _stamp_view_dismissable:
				return
			_close())
	add_child(dim)

	_root_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.11, 0.09)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12.0)
	_root_panel.add_theme_stylebox_override("panel", sb)
	_root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Same gutter as play-mode notebook (sidebar + clue bar reserved visually).
	_root_panel.offset_left = 60.0 + SIDEBAR_W
	_root_panel.offset_right = -(60.0 + CLUEBAR_W)
	_root_panel.offset_top = 30.0
	_root_panel.offset_bottom = -30.0
	_root_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root_panel)

	_notebook_area = PanelContainer.new()
	var paper_sb := StyleBoxFlat.new()
	paper_sb.bg_color = PAPER_FALLBACK
	paper_sb.set_corner_radius_all(4)
	_notebook_area.add_theme_stylebox_override("panel", paper_sb)
	_notebook_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notebook_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Stamp sits on the paper’s right; don’t clip it off the map host.
	_notebook_area.clip_contents = false
	_root_panel.add_child(_notebook_area)

	_notebook_root = Control.new()
	_notebook_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notebook_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_notebook_root.clip_contents = false
	_notebook_area.add_child(_notebook_root)

	if ResourceLoader.exists(NOTEPAPER):
		var paper := TextureRect.new()
		paper.texture = load(NOTEPAPER) as Texture2D
		paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_notebook_root.add_child(paper)

	# Map host stays clipped; stamp is parented to notebook_root (right of paper).
	_map_host = Control.new()
	_map_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_host.offset_top = 46.0
	_map_host.offset_right = -(DetectiveNoteVerdictMap.STAMP_SIZE + 100.0)
	_map_host.clip_contents = true
	_notebook_root.add_child(_map_host)

	_map = DetectiveNoteVerdictMap.new()
	_map.locale = locale
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_host.add_child(_map)

	_topic_title_lbl = Label.new()
	_topic_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_topic_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_topic_title_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_topic_title_lbl.offset_top = 10.0
	_topic_title_lbl.offset_bottom = 46.0
	_topic_title_lbl.add_theme_font_override("font", FontManager.make_font("handwritten", 700))
	_topic_title_lbl.add_theme_font_size_override("font_size", 28)
	_topic_title_lbl.add_theme_color_override("font_color", Color(0.28, 0.22, 0.16))
	_topic_title_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_topic_title_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_topic_title_lbl.clip_text = true
	_topic_title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_topic_title_lbl.visible = false
	_notebook_root.add_child(_topic_title_lbl)

	set_process(false)


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if _stamp_view_mode and not _stamp_view_dismissable:
				return
			_close())
	add_child(dim)

	_root_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.11, 0.09)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12.0)
	_root_panel.add_theme_stylebox_override("panel", sb)
	_root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_panel.offset_left = 60.0
	_root_panel.offset_right = -60.0
	_root_panel.offset_top = 30.0
	_root_panel.offset_bottom = -30.0
	add_child(_root_panel)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_panel.add_child(columns)

	# ── Left: chapters + topics ──
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(SIDEBAR_W, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	columns.add_child(left)

	var title := Label.new()
	title.text = "DETECTIVE NOTE"
	title.add_theme_font_override("font", FontManager.make_font("handwritten", 700))
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.92, 0.88, 0.80))
	left.add_child(title)

	_chapter_header = _section_header(left, "CHAPTERS")
	_chapter_scroll = ScrollContainer.new()
	_chapter_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chapter_scroll.custom_minimum_size = Vector2(0, 140)
	left.add_child(_chapter_scroll)
	_chapter_vbox = VBoxContainer.new()
	_chapter_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chapter_vbox.add_theme_constant_override("separation", 4)
	_chapter_scroll.add_child(_chapter_vbox)

	_topic_header = _section_header(left, "TOPICS")
	_topic_scroll = ScrollContainer.new()
	_topic_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_topic_scroll.custom_minimum_size = Vector2(0, 140)
	left.add_child(_topic_scroll)
	_topic_vbox = VBoxContainer.new()
	_topic_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_topic_vbox.add_theme_constant_override("separation", 4)
	_topic_scroll.add_child(_topic_vbox)

	_done_btn = _make_done_button()
	left.add_child(_done_btn)

	# ── Center: notebook area ──
	_notebook_area = PanelContainer.new()
	var paper_sb := StyleBoxFlat.new()
	paper_sb.bg_color = PAPER_FALLBACK
	paper_sb.set_corner_radius_all(4)
	_notebook_area.add_theme_stylebox_override("panel", paper_sb)
	_notebook_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notebook_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(_notebook_area)
	# Sidebar (and tilted/pulsing Done) must paint above the notebook; tree order
	# alone draws the notebook on top and conceals Done when it scales out.
	# Notebook itself must clip — wide verdict maps used to spill over the scene.
	columns.clip_contents = false
	left.clip_contents = false
	left.z_index = 2
	_notebook_area.z_index = 0
	_notebook_area.clip_contents = true

	_notebook_root = Control.new()
	_notebook_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notebook_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Stamp overlays the paper’s right edge (sibling of map_scroll).
	_notebook_root.clip_contents = false
	_notebook_area.add_child(_notebook_root)

	if ResourceLoader.exists(NOTEPAPER):
		var paper := TextureRect.new()
		paper.texture = load(NOTEPAPER) as Texture2D
		paper.stretch_mode = TextureRect.STRETCH_TILE
		paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_notebook_root.add_child(paper)

	_map_scroll = ScrollContainer.new()
	_map_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_scroll.offset_top = 46.0
	_map_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Vertical scroll only. Width is handled by _fit_verdict_map() scaling.
	# SHOW_ALWAYS: reserved scrollbar width so fit → scrollbar toggle cannot oscillate avail_w.
	_map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_map_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	_map_scroll.clip_contents = true
	_notebook_root.add_child(_map_scroll)
	# Deferred: writing map_host size can emit resized synchronously and hard-freeze
	# exports via fit → resized → fit recursion. Stamp mode disconnects this entirely.
	_map_scroll_fit_cb = Callable(self, "_on_map_scroll_resized_fit")
	_map_scroll.resized.connect(_map_scroll_fit_cb)

	# Host reports the scaled layout size so horizontal_scroll DISABLED does not
	# force a crushing min-width when the authored map is wider than the notebook.
	_map_host = Control.new()
	_map_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_scroll.add_child(_map_host)

	_map = DetectiveNoteVerdictMap.new()
	_map.locale = locale
	_map.clue_drop_requested.connect(_on_map_drop_requested)
	_map.node_hover_started.connect(_on_map_node_hover_started)
	_map.node_hover_ended.connect(func() -> void: _on_hover_control_exited())
	_map.drag_ghost_show = _show_drag_ghost_for_clue
	_map.drag_ghost_hide = _hide_drag_ghost
	_map_host.add_child(_map)

	_topic_title_lbl = Label.new()
	_topic_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_topic_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_topic_title_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_topic_title_lbl.offset_top = 10.0
	_topic_title_lbl.offset_bottom = 46.0
	_topic_title_lbl.add_theme_font_override("font", FontManager.make_font("handwritten", 700))
	_topic_title_lbl.add_theme_font_size_override("font_size", 28)
	_topic_title_lbl.add_theme_color_override("font_color", Color(0.28, 0.22, 0.16))
	_topic_title_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_topic_title_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_topic_title_lbl.clip_text = true
	_topic_title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_topic_title_lbl.visible = false
	_notebook_root.add_child(_topic_title_lbl)

	_empty_lbl = Label.new()
	_empty_lbl.text = "Nothing here yet.\nClues you discover will appear in this note."
	_empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty_lbl.custom_minimum_size = Vector2(EMPTY_LBL_W, 0.0)
	_empty_lbl.add_theme_font_override("font", FontManager.make_font("handwritten", 400))
	_empty_lbl.add_theme_font_size_override("font_size", 24)
	_empty_lbl.add_theme_color_override("font_color", Color(0.35, 0.30, 0.25, 0.85))
	_empty_lbl.set_anchors_preset(Control.PRESET_CENTER)
	_empty_lbl.offset_left = -EMPTY_LBL_W * 0.5 - EMPTY_LBL_SHIFT_X
	_empty_lbl.offset_right = EMPTY_LBL_W * 0.5 - EMPTY_LBL_SHIFT_X
	_empty_lbl.offset_top = -36.0
	_empty_lbl.offset_bottom = 36.0
	_empty_lbl.visible = false
	_empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notebook_root.add_child(_empty_lbl)

	# ── Right: clue panels ──
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(CLUEBAR_W, 0)
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	columns.add_child(right)

	var tab_bar := HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 4)
	right.add_child(tab_bar)
	for kind: String in KIND_TABS:
		var btn := Button.new()
		btn.text = str(KIND_LABELS.get(kind, kind.to_upper()))
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_override("font", FontManager.make_font("handwritten", 700))
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_color_override("font_color", Color(0.90, 0.84, 0.72))
		btn.add_theme_color_override("font_hover_color", Color(0.98, 0.94, 0.84))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.96, 0.86))
		_apply_note_button_skin(
			btn, BTN_FILL, BTN_FILL_HOVER, BTN_FILL_SELECTED, BTN_BORDER, BTN_BORDER_SELECTED, 2)
		btn.pressed.connect(_switch_clue_tab.bind(kind))
		tab_bar.add_child(btn)
		_clue_tab_buttons[kind] = btn

	var clue_scroll := ScrollContainer.new()
	clue_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	clue_scroll.clip_contents = true
	right.add_child(clue_scroll)
	_clue_scroll = clue_scroll
	_clue_grid = GridContainer.new()
	_clue_grid.columns = 2
	_clue_grid.add_theme_constant_override("h_separation", 8)
	_clue_grid.add_theme_constant_override("v_separation", 8)
	clue_scroll.add_child(_clue_grid)
	var panel_drop_can := func(_pos: Vector2, data: Variant) -> bool:
		return _clue_panel_can_accept_drag(data)
	var panel_drop_do := func(_pos: Vector2, data: Variant) -> void:
		_clue_panel_accept_drag(data)
	clue_scroll.set_drag_forwarding(Callable(), panel_drop_can, panel_drop_do)
	_clue_grid.set_drag_forwarding(Callable(), panel_drop_can, panel_drop_do)

	var hint := Label.new()
	hint.text = "Drag a clue onto a frame.\nDrag back here or double-click a frame to remove.\nHold hover 1s for details."
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.7, 0.66, 0.6))
	right.add_child(hint)

	if _stamp_view_mode:
		_apply_stamp_view_layout(columns, left, right)
	else:
		_sync_chapter_sidebar_visibility()

	_hover_dots = Label.new()
	_hover_dots.add_theme_font_size_override("font_size", 24)
	_hover_dots.add_theme_color_override("font_color", Color.WHITE)
	_hover_dots.add_theme_color_override("font_shadow_color", Color.BLACK)
	_hover_dots.add_theme_constant_override("shadow_offset_x", 1)
	_hover_dots.add_theme_constant_override("shadow_offset_y", 1)
	_hover_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_dots.visible = false
	_hover_dots.z_index = 60
	add_child(_hover_dots)
	set_process(false)


func _section_header(parent: Control, text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.62, 0.58, 0.52))
	parent.add_child(lbl)
	return lbl


func _sync_chapter_sidebar_visibility() -> void:
	var show_chapters: bool = _all_chapters_mode
	if _chapter_header != null:
		_chapter_header.visible = show_chapters
	if _chapter_scroll != null:
		_chapter_scroll.visible = show_chapters
	if _topic_scroll != null:
		_topic_scroll.custom_minimum_size.y = 140.0 if show_chapters else 280.0


## Stamp view keeps the notebook the same width as normal play mode by reserving
## the sidebar + clue-panel gutters, centered in the root panel.
func _apply_stamp_view_layout(columns: HBoxContainer, left: Control, right: Control) -> void:
	columns.remove_child(left)
	columns.remove_child(right)
	left.queue_free()
	right.queue_free()
	var pad_l := Control.new()
	pad_l.custom_minimum_size = Vector2(SIDEBAR_W, 0)
	pad_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columns.add_child(pad_l)
	columns.move_child(pad_l, 0)
	var pad_r := Control.new()
	pad_r.custom_minimum_size = Vector2(CLUEBAR_W, 0)
	pad_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columns.add_child(pad_r)
	# No resized→fit loop during stamp — layout once, then animate (pack-style).
	_disconnect_map_scroll_fit()


func _on_map_scroll_resized_fit() -> void:
	if _stamp_view_mode:
		return
	call_deferred("_fit_verdict_map")


func _disconnect_map_scroll_fit() -> void:
	if _map_scroll == null or not is_instance_valid(_map_scroll):
		return
	if _map_scroll_fit_cb.is_valid() and _map_scroll.resized.is_connected(_map_scroll_fit_cb):
		_map_scroll.resized.disconnect(_map_scroll_fit_cb)


# ─────────────────────────────────────────────────────────────
# Chapter / topic lists
# ─────────────────────────────────────────────────────────────
## Detach immediately so child counts are correct within the same frame.
static func _clear_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _refresh_chapter_list() -> void:
	_clear_children(_chapter_vbox)
	if not _all_chapters_mode:
		return
	for cid_v: Variant in DetectiveNoteManager.get_unlocked_chapter_ids():
		var cid: String = str(cid_v)
		var chapter: Dictionary = DetectiveNoteVault.get_chapter(cid)
		var btn := Button.new()
		var chapter_title: String = DetectiveNoteVault.loc_text(chapter.get("title", ""), locale)
		btn.text = chapter_title if not chapter_title.is_empty() else cid
		btn.set_meta("chapter_id", cid)
		btn.toggle_mode = true
		btn.button_pressed = (cid == _selected_chapter)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_select_chapter.bind(cid))
		_chapter_vbox.add_child(btn)


func _select_chapter(chapter_id: String) -> void:
	var keep_topic: String = _selected_topic.strip_edges()
	_selected_chapter = chapter_id
	DetectiveNoteManager.apply_start_clues(chapter_id)
	if _all_chapters_mode:
		for btn: Node in _chapter_vbox.get_children():
			if btn is Button:
				(btn as Button).button_pressed = str(btn.get_meta("chapter_id", "")) == chapter_id
	_refresh_topic_list()
	var unlocked: Array = DetectiveNoteManager.get_unlocked_topics(chapter_id)
	if not keep_topic.is_empty() and unlocked.has(keep_topic):
		_select_topic(keep_topic)
	else:
		_select_topic(DetectiveNoteManager.get_preferred_topic(chapter_id))
	_switch_clue_tab(_clue_kind)


func _refresh_topic_list() -> void:
	_clear_children(_topic_vbox)
	for tid_v: Variant in DetectiveNoteManager.get_unlocked_topics(_selected_chapter):
		var tid: String = str(tid_v)
		var topic: Dictionary = DetectiveNoteVault.get_topic(_selected_chapter, tid)
		var btn := Button.new()
		var topic_title: String = DetectiveNoteVault.loc_text(topic.get("title", ""), locale)
		btn.text = topic_title if not topic_title.is_empty() else tid
		if DetectiveNoteManager.is_topic_stamped(_selected_chapter, tid):
			btn.text += "  ✓"
		btn.toggle_mode = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_select_topic.bind(tid))
		_topic_vbox.add_child(btn)


func _select_topic(topic_id: String) -> void:
	_selected_topic = topic_id
	var topics: Array = DetectiveNoteManager.get_unlocked_topics(_selected_chapter)
	for i: int in range(_topic_vbox.get_child_count()):
		var btn := _topic_vbox.get_child(i) as Button
		if btn != null:
			btn.button_pressed = (i < topics.size() and str(topics[i]) == topic_id)
	_refresh_map()


func _refresh_map() -> void:
	_map.clear_stamp()
	_refresh_topic_title()
	if _selected_topic.is_empty():
		_map.setup({}, 1, DetectiveNoteVerdictMap.Mode.READONLY)
		_empty_lbl.visible = true
		_fit_verdict_map()
		_sync_done_btn_pulse()
		return
	_empty_lbl.visible = false
	var topic: Dictionary = DetectiveNoteVault.get_topic(_selected_chapter, _selected_topic)
	var level: int = DetectiveNoteManager.get_topic_level(_selected_chapter, _selected_topic)
	var stamped: bool = DetectiveNoteManager.is_topic_stamped(_selected_chapter, _selected_topic)
	var map_mode: int = DetectiveNoteVerdictMap.Mode.READONLY if (stamped or _stamp_view_mode) \
		else DetectiveNoteVerdictMap.Mode.PLAYER
	_map.setup(topic, maxi(level, 1), map_mode,
		DetectiveNoteManager.get_placements(_selected_chapter, _selected_topic))
	if stamped and not _stamp_view_mode:
		# Same as approval overlay: stamp on notebook paper’s right, not on the
		# scaled verdict map (which looked centered / over the nodes).
		_map.show_stamp(
			DetectiveNoteManager.get_topic_stamp(_selected_chapter, _selected_topic),
			false,
			DetectiveNoteManager.get_topic_stamp_angle(_selected_chapter, _selected_topic),
			_notebook_root)
	_fit_verdict_map()
	# Stamp: one deferred fit after first layout frame only (no resize re-arm).
	# Play mode: deferred catches late ScrollContainer size.
	call_deferred("_fit_verdict_map")
	_sync_done_btn_pulse()


## Scale the authored verdict map down when it is wider than the notebook column.
## Horizontal scroll is disabled, so without this a wide map forces a huge min-width,
## crushes the notebook, and (without clipping) paints over the exploration scene.
func _fit_verdict_map() -> void:
	if _stamp_view_mode:
		return
	if _fitting_map:
		return
	if _map == null or not is_instance_valid(_map) \
			or _map_host == null or not is_instance_valid(_map_host) \
			or _map_scroll == null or not is_instance_valid(_map_scroll):
		return
	_fitting_map = true
	_fit_call_count += 1
	var extent: Vector2 = _map.content_extent()
	extent.x = maxf(extent.x, 1.0)
	extent.y = maxf(extent.y, 1.0)
	var avail_w: float = _map_scroll.size.x
	if avail_w < 64.0 and _notebook_area != null:
		avail_w = _notebook_area.size.x
	# Export / first-frame layout can leave children at 0×0 — use viewport fallback.
	if avail_w < 64.0:
		var vp_w: float = get_viewport().get_visible_rect().size.x
		avail_w = maxf(vp_w - SIDEBAR_W - CLUEBAR_W - 160.0, 320.0)
	var s: float = 1.0 if extent.x <= avail_w else avail_w / extent.x
	var scaled := Vector2(extent.x * s, extent.y * s)
	# Skip no-op writes so resized feedback cannot churn forever.
	if absf(avail_w - _last_fit_avail_w) < 0.5 \
			and _map_host.size.distance_to(scaled) < 0.5 \
			and _map_host.custom_minimum_size.distance_to(scaled) < 0.5:
		_fitting_map = false
		return
	_last_fit_avail_w = avail_w
	_map.scale = Vector2(s, s)
	_map.position = Vector2.ZERO
	_map.size = extent
	# Host owns scroll metrics; full authored extent as min-width crushes the HBox.
	_map.custom_minimum_size = Vector2.ZERO
	_map_host.custom_minimum_size = scaled
	_map_host.size = scaled
	_fitting_map = false


func _refresh_topic_title() -> void:
	if _topic_title_lbl == null:
		return
	if _selected_topic.is_empty():
		_topic_title_lbl.visible = false
		return
	var topic: Dictionary = DetectiveNoteVault.get_topic(_selected_chapter, _selected_topic)
	var title: String = DetectiveNoteVault.loc_text(topic.get("title", ""), locale)
	_topic_title_lbl.text = title if not title.is_empty() else _selected_topic
	_topic_title_lbl.visible = true


# ─────────────────────────────────────────────────────────────
# Clue panels
# ─────────────────────────────────────────────────────────────
func _switch_clue_tab(kind: String) -> void:
	_clue_kind = kind
	for k: String in KIND_TABS:
		(_clue_tab_buttons[k] as Button).button_pressed = (k == kind)
	_clear_children(_clue_grid)
	for cid_v: Variant in DetectiveNoteManager.get_discovered_clues_by_kind(_selected_chapter, kind):
		_clue_grid.add_child(_make_clue_tile(str(cid_v)))


func _configure_clue_name_label(lbl: Label, max_lines: int = CLUE_NAME_MAX_LINES) -> void:
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.max_lines_visible = max_lines
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.clip_text = false
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _make_clue_caption_host(name_text: String) -> Control:
	var host := Control.new()
	host.custom_minimum_size = Vector2(TILE_SIZE.x, CLUE_CAPTION_TEXT_H)
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_lbl := Label.new()
	name_lbl.text = name_text
	name_lbl.add_theme_font_size_override("font_size", CLUE_NAME_FONT_SIZE)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_configure_clue_name_label(name_lbl, CLUE_NAME_MAX_LINES)
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(name_lbl)
	return host


func _make_clue_tile(clue_id: String) -> Control:
	var clue: Dictionary = DetectiveNoteVault.get_clue(clue_id)
	var tile := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.20, 0.17, 0.14)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = CLUE_TILE_PAD_SIDE
	sb.content_margin_right = CLUE_TILE_PAD_SIDE
	sb.content_margin_top = CLUE_TILE_PAD_TOP
	sb.content_margin_bottom = CLUE_TILE_PAD_BOTTOM
	tile.add_theme_stylebox_override("panel", sb)
	tile.custom_minimum_size = Vector2(
		TILE_SIZE.x + 16.0,
		TILE_SIZE.y + CLUE_CAPTION_BLOCK_H + CLUE_TILE_PANEL_MARGIN_V)
	tile.clip_contents = false
	tile.mouse_filter = Control.MOUSE_FILTER_STOP

	var shell := Control.new()
	shell.custom_minimum_size = Vector2(TILE_SIZE.x + 4.0, TILE_SIZE.y + CLUE_CAPTION_BLOCK_H)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(shell)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_child(body)

	var clue_name: String = DetectiveNoteVault.clue_display_name(clue, locale)
	if DetectiveNoteVault.clue_is_messenger(clue):
		var tex_rect := TextureRect.new()
		if ResourceLoader.exists(DetectiveNoteVault.MESSENGER_CLUE_ICON):
			tex_rect.texture = load(DetectiveNoteVault.MESSENGER_CLUE_ICON) as Texture2D
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = TILE_SIZE
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(tex_rect)
	else:
		var img_path: String = str(clue.get("image", "")).strip_edges()
		if DetectiveNoteVault.clue_is_postit(clue):
			var postit := ColorRect.new()
			postit.color = DetectiveNoteVerdictMap.POSTIT_COLOR
			postit.custom_minimum_size = TILE_SIZE
			postit.clip_contents = true
			var pl := Label.new()
			pl.text = clue_name
			pl.add_theme_font_override("font", FontManager.make_font("handwritten", 400))
			pl.add_theme_font_size_override("font_size", 14)
			pl.add_theme_color_override("font_color", DetectiveNoteVerdictMap.POSTIT_TEXT)
			pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			pl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
			pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pl.clip_text = true
			pl.max_lines_visible = 4
			pl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			postit.add_child(pl)
			postit.mouse_filter = Control.MOUSE_FILTER_IGNORE
			body.add_child(postit)
		else:
			var tex_rect := TextureRect.new()
			if ResourceLoader.exists(img_path):
				tex_rect.texture = load(img_path) as Texture2D
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = TILE_SIZE
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			body.add_child(tex_rect)

	body.add_child(_make_clue_caption_host(clue_name))

	if _should_show_new_badge(clue_id):
		shell.add_child(_make_new_badge())

	tile.set_meta("clue_id", clue_id)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			_dismiss_new_badge_for_clue(clue_id, tile))
	tile.set_drag_forwarding(
		func(_pos: Vector2) -> Variant:
			_dismiss_new_badge_for_clue(clue_id, tile)
			_hover_end()
			tile.set_drag_preview(_map.make_drag_preview_stub())
			_show_drag_ghost_for_clue(clue_id)
			return {"detective_clue": clue_id, "from_node": ""},
		func(_pos: Vector2, data: Variant) -> bool:
			return _clue_panel_can_accept_drag(data),
		func(_pos: Vector2, data: Variant) -> void:
			_clue_panel_accept_drag(data))
	tile.mouse_entered.connect(func() -> void: _hover_begin(clue_id, tile))
	tile.mouse_exited.connect(func() -> void: _on_hover_control_exited())
	return tile


func _should_show_new_badge(clue_id: String) -> bool:
	# Inventory / stamp view: no "New" badges.
	if _all_chapters_mode or _stamp_view_mode:
		return false
	return DetectiveNoteManager.is_clue_new(_selected_chapter, clue_id)


func _make_new_badge() -> Label:
	var badge := Label.new()
	badge.name = "NewBadge"
	badge.text = "New"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_font_override("font", FontManager.make_font("handwritten", 700))
	badge.add_theme_font_size_override("font_size", NEW_BADGE_FONT_SIZE)
	badge.add_theme_color_override("font_color", NEW_BADGE_COLOR)
	badge.add_theme_color_override("font_shadow_color", NEW_BADGE_SHADOW)
	badge.add_theme_constant_override("shadow_offset_x", 2)
	badge.add_theme_constant_override("shadow_offset_y", 2)
	badge.add_theme_constant_override("shadow_outline_size", 2)
	badge.add_theme_color_override("font_outline_color", NEW_BADGE_SHADOW)
	badge.add_theme_constant_override("outline_size", 3)
	badge.rotation_degrees = NEW_BADGE_TILT_DEG
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	badge.grow_vertical = Control.GROW_DIRECTION_END
	badge.offset_left = -52.0
	badge.offset_right = -2.0
	badge.offset_top = -2.0
	badge.offset_bottom = 22.0
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.resized.connect(func() -> void:
		badge.pivot_offset = badge.size * 0.5)
	# Pulse after enter tree so size/pivot are valid.
	badge.ready.connect(func() -> void:
		badge.pivot_offset = badge.size * 0.5
		var tw := badge.create_tween().set_loops()
		tw.tween_property(badge, "scale", Vector2.ONE * NEW_BADGE_PULSE_SCALE, NEW_BADGE_PULSE_HALF_SEC) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(badge, "scale", Vector2.ONE, NEW_BADGE_PULSE_HALF_SEC) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT))
	return badge


func _dismiss_new_badge_for_clue(clue_id: String, tile: Control = null) -> void:
	if _all_chapters_mode or _stamp_view_mode:
		return
	if not DetectiveNoteManager.mark_clue_seen(_selected_chapter, clue_id):
		# Already seen — still strip any leftover badge node.
		pass
	var host: Control = tile
	if host == null and _clue_grid != null:
		for child: Node in _clue_grid.get_children():
			if child is Control and str((child as Control).get_meta("clue_id", "")) == clue_id:
				host = child as Control
				break
	if host == null or not is_instance_valid(host):
		return
	_remove_new_badge_from_tile(host)


func _remove_new_badge_from_tile(tile: Control) -> void:
	for child: Node in tile.get_children():
		if child is Control:
			var badge: Node = (child as Control).get_node_or_null("NewBadge")
			if badge != null and is_instance_valid(badge):
				badge.queue_free()
				return
		if child.name == "NewBadge":
			child.queue_free()
			return


# ─────────────────────────────────────────────────────────────
# Verdict map interaction
# ─────────────────────────────────────────────────────────────
func _on_map_drop_requested(node_id: String, clue_id: String, from_node: String) -> void:
	_hide_drag_ghost()
	if clue_id.is_empty():
		if DetectiveNoteManager.clear_placement(_selected_chapter, _selected_topic, node_id):
			SFXManager.play(SFXManager.SFX_REMOVE)
	else:
		if DetectiveNoteManager.set_placement(_selected_chapter, _selected_topic, node_id, clue_id):
			if not from_node.is_empty() and from_node != node_id:
				DetectiveNoteManager.clear_placement(_selected_chapter, _selected_topic, from_node)
			SFXManager.play(SFXManager.SFX_PLACE)
	_map.set_placements(DetectiveNoteManager.get_placements(_selected_chapter, _selected_topic))
	_sync_done_btn_pulse()


func _clue_panel_can_accept_drag(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var d: Dictionary = data as Dictionary
	return d.has("detective_clue") and not str(d.get("from_node", "")).is_empty()


func _clue_panel_accept_drag(data: Variant) -> void:
	if not data is Dictionary:
		return
	var from_node: String = str((data as Dictionary).get("from_node", "")).strip_edges()
	if from_node.is_empty():
		return
	_on_map_drop_requested(from_node, "", from_node)


func _on_map_node_hover_started(_node_id: String, clue_id: String, hit: Control) -> void:
	if clue_id.is_empty():
		return
	_hover_begin(clue_id, hit)


# ─────────────────────────────────────────────────────────────
# Hover-hold (1s) → clue detail popup
# ─────────────────────────────────────────────────────────────
func _hover_begin(clue_id: String, hover_control: Control) -> void:
	if _detail_popup != null and is_instance_valid(_detail_popup):
		_close_detail_popup()
	_hover_clue_id = clue_id
	_hover_control = hover_control
	_hover_elapsed = 0.0
	_hover_anchor = get_global_mouse_position()
	set_process(true)


func _on_hover_control_exited() -> void:
	# Full-screen detail overlay steals hover from the tile/frame; keep it until move/close.
	if _detail_popup != null and is_instance_valid(_detail_popup):
		_hover_clue_id = ""
		_hover_control = null
		_hover_elapsed = 0.0
		_hover_dots.visible = false
		return
	_hover_end()


func _hover_end() -> void:
	_hover_clue_id = ""
	_hover_control = null
	_hover_elapsed = 0.0
	_hover_dots.visible = false
	_sync_process_idle()


func _sync_process_idle() -> void:
	if _drag_ghost_active:
		return
	if _detail_popup != null and is_instance_valid(_detail_popup):
		return
	set_process(false)


func _show_drag_ghost_for_clue(clue_id: String) -> void:
	_hide_drag_ghost()
	if _map == null:
		return
	var ghost: Control = _map.build_drag_ghost(clue_id)
	ghost.name = "DetectiveNoteDragGhost"
	ghost.z_index = 4096
	ghost.top_level = true
	add_child(ghost)
	_drag_ghost = ghost
	_drag_ghost_active = true
	set_process(true)
	_update_drag_ghost_pos()


func _update_drag_ghost_pos() -> void:
	if _drag_ghost == null or not is_instance_valid(_drag_ghost):
		return
	var mp: Vector2 = get_viewport().get_mouse_position()
	_drag_ghost.global_position = mp - _drag_ghost.size * 0.5


func _hide_drag_ghost() -> void:
	_drag_ghost_active = false
	if _drag_ghost != null and is_instance_valid(_drag_ghost):
		_drag_ghost.queue_free()
	_drag_ghost = null
	_sync_process_idle()


func _process(delta: float) -> void:
	if _drag_ghost_active:
		_update_drag_ghost_pos()
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_hide_drag_ghost()
	if _detail_popup != null and is_instance_valid(_detail_popup):
		var mouse_open := get_global_mouse_position()
		if mouse_open.distance_to(_detail_anchor_mouse) > HOVER_MOVE_THRESHOLD_PX:
			_close_detail_popup()
		return
	if _hover_clue_id.is_empty() or _hover_control == null \
			or not is_instance_valid(_hover_control):
		return
	var mouse := get_global_mouse_position()
	if not _hover_control.get_global_rect().has_point(mouse):
		_hover_end()
		return
	if mouse.distance_to(_hover_anchor) > HOVER_MOVE_THRESHOLD_PX:
		_hover_elapsed = 0.0
		_hover_anchor = mouse
		_hover_dots.visible = false
		return
	_hover_elapsed += delta
	var dots: int = mini(int(floor(_hover_elapsed / HOVER_STEP_SEC)), 4)
	if dots > 0:
		var parts := PackedStringArray()
		for _i: int in range(dots):
			parts.append("•")
		_hover_dots.text = " ".join(parts)
		_hover_dots.visible = true
		_hover_dots.position = mouse - global_position + Vector2(22.0, 52.0)
	if _hover_elapsed >= HOVER_OPEN_SEC:
		_open_clue_detail(_hover_clue_id)
		_hover_clue_id = ""
		_hover_control = null
		_hover_dots.visible = false


func _close_detail_popup() -> void:
	if _detail_popup != null and is_instance_valid(_detail_popup):
		_detail_popup.queue_free()
	_detail_popup = null
	_hover_end()


func _open_clue_detail(clue_id: String) -> void:
	if _detail_popup != null and is_instance_valid(_detail_popup):
		return
	var clue: Dictionary = DetectiveNoteVault.get_clue(clue_id)
	if clue.is_empty():
		return
	_dismiss_new_badge_for_clue(clue_id)
	if DetectiveNoteVault.clue_is_messenger(clue):
		_show_messenger_for_clue(clue_id)
		return
	_detail_anchor_mouse = get_global_mouse_position()
	_detail_popup = Control.new()
	_detail_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_popup.z_index = 80
	_detail_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_detail_popup)
	set_process(true)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			_close_detail_popup())
	_detail_popup.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_popup.add_child(center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.14, 0.11)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(18.0)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(520.0, 0)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = DetectiveNoteVault.loc_text(clue.get("name", ""), locale)
	name_lbl.add_theme_font_override("font", FontManager.make_font("handwritten", 700))
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	vbox.add_child(name_lbl)

	var img_path: String = str(clue.get("image", "")).strip_edges()
	if not img_path.is_empty() and ResourceLoader.exists(img_path):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(img_path) as Texture2D
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(480.0, 260.0)
		vbox.add_child(tex_rect)

	var caption: String = DetectiveNoteVault.loc_text(clue.get("caption", ""), locale)
	if not caption.is_empty():
		var cap_lbl := Label.new()
		cap_lbl.text = caption
		cap_lbl.add_theme_font_size_override("font_size", 15)
		cap_lbl.add_theme_color_override("font_color", Color(0.78, 0.74, 0.68))
		cap_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(cap_lbl)

	var info: String = DetectiveNoteVault.loc_text(clue.get("info", ""), locale)
	if not info.is_empty():
		var info_lbl := Label.new()
		info_lbl.text = info
		info_lbl.add_theme_font_size_override("font_size", 16)
		info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_lbl.custom_minimum_size = Vector2(480.0, 0)
		vbox.add_child(info_lbl)

	var hint := Label.new()
	hint.text = "(tap anywhere or move mouse to close)"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.56, 0.5))
	vbox.add_child(hint)


func _show_messenger_for_clue(clue_id: String) -> void:
	var conv_id: String = DetectiveNoteVault.get_clue_conversation_id(clue_id)
	if conv_id.is_empty():
		return
	_hover_end()
	MessengerOverlay.open(self, conv_id)


# ─────────────────────────────────────────────────────────────
# Stamp view (VN show_note_stamp)
# ─────────────────────────────────────────────────────────────
func _show_stamp_view() -> void:
	DetectiveNoteManager.apply_start_clues(_selected_chapter)
	_stamp_view_dismissable = false
	# process_always: still fires if the tree is paused.
	var safety: SceneTreeTimer = get_tree().create_timer(8.0, true, false, true)
	safety.timeout.connect(func() -> void:
		if is_instance_valid(self) and not _stamp_view_dismissable:
			_stamp_view_dismissable = true, CONNECT_ONE_SHOT)
	# Auto-dismiss so VN await view.closed cannot soft-dead forever.
	var auto_close: SceneTreeTimer = get_tree().create_timer(12.0, true, false, true)
	auto_close.timeout.connect(func() -> void:
		if is_instance_valid(self) and _stamp_view_mode:
			_close(), CONNECT_ONE_SHOT)
	_stamp_setup_map()
	_layout_stamp_map()
	var stamp_id: String = DetectiveNoteManager.get_topic_stamp(_selected_chapter, _selected_topic)
	if stamp_id.is_empty():
		push_warning("DetectiveNoteOverlay: stamp view for unstamped topic '%s/%s'"
			% [_selected_chapter, _selected_topic])
		_stamp_view_dismissable = true
		return
	_map.stamp_animation_finished.connect(func() -> void:
		_stamp_view_dismissable = true, CONNECT_ONE_SHOT)
	# Parent stamp to the notebook paper (right side), not the scaled verdict map.
	_map.show_stamp(
		stamp_id,
		true,
		DetectiveNoteManager.get_topic_stamp_angle(_selected_chapter, _selected_topic),
		_notebook_root)


## Load topic onto the map without ScrollContainer fit (stamp path only).
func _stamp_setup_map() -> void:
	if _map == null:
		return
	_refresh_topic_title()
	if _selected_topic.is_empty():
		_map.setup({}, 1, DetectiveNoteVerdictMap.Mode.READONLY)
		return
	var topic: Dictionary = DetectiveNoteVault.get_topic(_selected_chapter, _selected_topic)
	var level: int = DetectiveNoteManager.get_topic_level(_selected_chapter, _selected_topic)
	_map.setup(topic, maxi(level, 1), DetectiveNoteVerdictMap.Mode.READONLY,
		DetectiveNoteManager.get_placements(_selected_chapter, _selected_topic))


## Scale map to the real notebook host (same idea as play-mode width-fit).
## Never invent host sizes or write `_map_host.size` — that fought anchors and made
## the map oversized so it bled bottom-right of the paper.
func _layout_stamp_map() -> void:
	if not _stamp_view_mode:
		return
	if _map == null or not is_instance_valid(_map) \
			or _map_host == null or not is_instance_valid(_map_host):
		return
	var extent: Vector2 = _map.content_extent()
	extent.x = maxf(extent.x, 1.0)
	extent.y = maxf(extent.y, 1.0)
	var avail: Vector2 = _map_host.size
	# Host still 0×0 on the open frame — deferred / RESIZED will retry.
	if avail.x < 64.0 or avail.y < 64.0:
		if _notebook_area != null and _notebook_area.size.x >= 64.0:
			avail = Vector2(
				_notebook_area.size.x,
				maxf(_notebook_area.size.y - 46.0, 64.0))
		else:
			return
	# Contain in both axes (no vertical scroll in stamp view).
	var s: float = minf(1.0, minf(avail.x / extent.x, avail.y / extent.y))
	_map.custom_minimum_size = Vector2.ZERO
	_map.size = extent
	_map.scale = Vector2(s, s)
	# Top-left like play notebook — centering + bad avail looked like BR bleed.
	_map.position = Vector2.ZERO
