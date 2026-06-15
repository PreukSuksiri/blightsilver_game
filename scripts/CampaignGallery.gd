extends Control
class_name CampaignGallery

const GALLERY_DATA_PATH := "res://campaign/gallery_data.json"
const PLACEHOLDER_IMG   := "res://assets/textures/campagin/placeholder_campagin.png"
const VN_PLAYER_SCENE   := "res://scenes/vn_player.tscn"

const CHIVO_FONT := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")

const CARD_IMG_W: float = 180.0
const CARD_IMG_H: float = 260.0
const CARD_GAP:   float = 20.0
const ROW_GAP:    float = 36.0
const CARD_DIM_OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.62)
const CARD_DIM_LABEL_COLOR   := Color(0.65, 0.65, 0.68)
const CARD_DIM_LABEL_SIZE    := 13
const DUNGEON_MAP_SCENE := DailyDungeonManager.DUNGEON_MAP_SCENE

var _data: Array = []


func _ready() -> void:
	_load_data()
	_build_ui()


func _load_data() -> void:
	if not FileAccess.file_exists(GALLERY_DATA_PATH):
		return
	var f := FileAccess.open(GALLERY_DATA_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Array:
		_data = parsed as Array


func _build_ui() -> void:
	# ── Background ────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.07, 0.09)
	add_child(bg)

	# ── Back button ───────────────────────────────────────────
	var back_btn := Button.new()
	back_btn.text = "← BACK"
	back_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_btn.offset_left   = 20.0
	back_btn.offset_top    = 20.0
	back_btn.offset_right  = 140.0
	back_btn.offset_bottom = 52.0
	back_btn.add_theme_font_override("font", FontManager.make_font("primary", 400))
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(queue_free)
	add_child(back_btn)

	# ── Title ─────────────────────────────────────────────────
	var title := Label.new()
	title.text = "CAMPAIGN"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top    = 20.0
	title.offset_bottom = 62.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CHIVO_FONT)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	add_child(title)

	# ── Scroll container ──────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = 76.0
	scroll.offset_left   = 32.0
	scroll.offset_right  = -32.0
	scroll.offset_bottom = -24.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(ROW_GAP))
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# ── Cards ─────────────────────────────────────────────────
	var current_row: HBoxContainer = null
	for raw: Variant in _data:
		var d: Dictionary = raw as Dictionary
		if current_row == null or bool(d.get("new_line_before", false)):
			current_row = HBoxContainer.new()
			current_row.add_theme_constant_override("separation", int(CARD_GAP))
			vbox.add_child(current_row)
		current_row.add_child(_build_card(d))


func _build_card(d: Dictionary) -> Control:
	var vn_path:    String = str(d.get("vn_scene", "")).strip_edges()
	var has_vn:    bool   = vn_path != ""
	var is_locked: bool   = _is_chapter_locked(d)
	var prereq_vn: String = _get_prerequisite_vn(d)

	# ── Card root ─────────────────────────────────────────────
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)
	card.custom_minimum_size = Vector2(CARD_IMG_W, 0.0)

	# ── Image frame ───────────────────────────────────────────
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(CARD_IMG_W, CARD_IMG_H)
	var sb := StyleBoxFlat.new()
	sb.bg_color         = Color(0.12, 0.12, 0.15)
	sb.border_width_left   = 1
	sb.border_width_right  = 1
	sb.border_width_top    = 1
	sb.border_width_bottom = 1
	sb.border_color     = Color(0.28, 0.28, 0.35)
	frame.add_theme_stylebox_override("panel", sb)
	card.add_child(frame)

	# Image texture
	var img_path: String = str(d.get("image", ""))
	var tex: Variant = null
	if img_path != "" and ResourceLoader.exists(img_path):
		tex = load(img_path)
	if tex == null:
		tex = load(PLACEHOLDER_IMG)

	var img := TextureRect.new()
	img.texture      = tex
	img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_child(img)

	# ── Locked overlay ────────────────────────────────────────
	if is_locked:
		_add_card_dim_overlay(frame)

		var lbl_lock := Label.new()
		var prereq_label: String = _prerequisite_display_name(prereq_vn)
		if prereq_label != "":
			lbl_lock.text = "🔒\nFinish\n%s" % prereq_label
		else:
			lbl_lock.text = "🔒\nLOCKED"
		lbl_lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_lock.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl_lock.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_lock.add_theme_font_override("font", FontManager.make_font("primary", 400))
		lbl_lock.add_theme_font_size_override("font_size", CARD_DIM_LABEL_SIZE)
		lbl_lock.add_theme_color_override("font_color", CARD_DIM_LABEL_COLOR)
		lbl_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(lbl_lock)

	# ── Coming soon overlay (unlocked but no VN yet) ──────────
	elif not has_vn:
		_add_card_dim_overlay(frame)

		var lbl_cs := Label.new()
		var _ct: String = str(d.get("custom_text", "")).strip_edges()
		lbl_cs.text = _ct if _ct != "" else "COMING\nSOON"
		lbl_cs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_cs.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl_cs.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_cs.add_theme_font_override("font", CHIVO_FONT)
		lbl_cs.add_theme_font_size_override("font_size", CARD_DIM_LABEL_SIZE)
		lbl_cs.add_theme_color_override("font_color", CARD_DIM_LABEL_COLOR)
		lbl_cs.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(lbl_cs)

	# ── Playable ──────────────────────────────────────────────
	else:
		frame.mouse_entered.connect(func() -> void:
			sb.border_color = Color(0.75, 0.75, 0.85)
			sb.bg_color     = Color(0.18, 0.18, 0.24)
			frame.add_theme_stylebox_override("panel", sb))
		frame.mouse_exited.connect(func() -> void:
			sb.border_color = Color(0.28, 0.28, 0.35)
			sb.bg_color     = Color(0.12, 0.12, 0.15)
			frame.add_theme_stylebox_override("panel", sb))
		frame.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton \
					and (ev as InputEventMouseButton).pressed \
					and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				_on_chapter_pressed(d))

		var save_kind: String = _get_chapter_save_kind(d, vn_path)
		if save_kind != "":
			_add_saved_progress_badge(frame, save_kind)

	# ── Line 1 (chapter) ──────────────────────────────────────
	var l1 := Label.new()
	l1.text = str(d.get("line1", ""))
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_font_override("font", CHIVO_FONT)
	l1.add_theme_font_size_override("font_size", 14)
	l1.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	card.add_child(l1)

	# ── Line 2 (stage) ────────────────────────────────────────
	var l2 := Label.new()
	l2.text = str(d.get("line2", ""))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.add_theme_font_override("font", CHIVO_FONT)
	l2.add_theme_font_size_override("font_size", 12)
	l2.add_theme_color_override("font_color", Color(0.60, 0.62, 0.68, 0.85))
	card.add_child(l2)

	return card


func _add_card_dim_overlay(frame: Panel) -> void:
	var dim := ColorRect.new()
	dim.color = CARD_DIM_OVERLAY_COLOR
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(dim)


func _get_chapter_save_kind(card: Dictionary, vn_path: String) -> String:
	if vn_path.is_empty() or _is_chapter_locked(card):
		return ""
	var dungeon_info: Dictionary = _resolve_chapter_dungeon(card, vn_path)
	var dungeon_id: String = str(dungeon_info.get("dungeon_id", "")).strip_edges()
	if dungeon_id != "" and DailyDungeonManager.has_story_dungeon_save(dungeon_id):
		return "dungeon"
	var expl_info: Dictionary = _resolve_chapter_exploration(card, vn_path)
	var graph_path: String = str(expl_info.get("graph_path", "")).strip_edges()
	if graph_path != "" and ExplorationManager.has_saved_session_for_chapter(vn_path, graph_path, card):
		return "exploration"
	if SaveManager.has_vn_checkpoint(vn_path):
		return "vn"
	if SaveManager.is_gallery_chapter_completed(vn_path):
		return ""
	return ""


func _add_saved_progress_badge(frame: Panel, save_kind: String) -> void:
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	badge.offset_left = 8.0
	badge.offset_right = -8.0
	badge.offset_bottom = -8.0
	badge.offset_top = -34.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.18, 0.34, 0.92)
	sb.border_color = Color(0.45, 0.78, 1.0, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	badge.add_theme_stylebox_override("panel", sb)
	frame.add_child(badge)

	var lbl := Label.new()
	lbl.text = "Continue Saved Progress"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", CHIVO_FONT)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	badge.add_child(lbl)

	if save_kind == "exploration":
		lbl.tooltip_text = "Saved exploration progress is available for this chapter."
	elif save_kind == "dungeon":
		lbl.tooltip_text = "Saved dungeon progress is available for this chapter."
	elif save_kind == "vn":
		lbl.tooltip_text = "Saved story progress is available for this chapter."


func _on_chapter_pressed(card: Dictionary) -> void:
	if _is_chapter_locked(card):
		return
	var vn_path: String = str(card.get("vn_scene", "")).strip_edges()
	if vn_path.is_empty():
		return
	match _get_chapter_save_kind(card, vn_path):
		"dungeon":
			var dungeon_info: Dictionary = _resolve_chapter_dungeon(card, vn_path)
			var dungeon_id: String = str(dungeon_info.get("dungeon_id", "")).strip_edges()
			_show_continue_or_restart_dialog(card, vn_path, dungeon_id)
		"exploration":
			var expl_info: Dictionary = _resolve_chapter_exploration(card, vn_path)
			var graph_path: String = str(expl_info.get("graph_path", "")).strip_edges()
			_show_continue_or_restart_exploration_dialog(card, vn_path, graph_path)
		"vn":
			_show_continue_or_restart_vn_dialog(card, vn_path)
		_:
			_play_vn(vn_path, true, card)


func _resolve_chapter_dungeon(card: Dictionary, vn_path: String) -> Dictionary:
	var dungeon_id: String = str(card.get("dungeon_id", "")).strip_edges()
	if dungeon_id != "":
		return {
			"dungeon_id": dungeon_id,
			"dungeon_on_win": str(card.get("dungeon_on_win", "")),
			"dungeon_on_lose": str(card.get("dungeon_on_lose", "")),
		}
	return DailyDungeonManager.find_dungeon_call_in_vn(vn_path)


func _resolve_chapter_exploration(card: Dictionary, vn_path: String) -> Dictionary:
	var graph_path: String = ExplorationManager.resolve_chapter_exploration_graph(card, vn_path)
	if graph_path.is_empty():
		return {}
	return {"graph_path": graph_path}


func _show_continue_or_restart_vn_dialog(card: Dictionary, vn_path: String) -> void:
	if get_node_or_null("ChapterResumeDialog") != null:
		return
	var chapter_label: String = str(card.get("line2", card.get("line1", "this chapter")))

	var blocker := ColorRect.new()
	blocker.name = "ChapterResumeDialog"
	blocker.color = Color(0.0, 0.0, 0.0, 0.72)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.z_index = 30
	add_child(blocker)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260.0
	panel.offset_right = 260.0
	panel.offset_top = -130.0
	panel.offset_bottom = 130.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	sb.border_color = Color(0.55, 0.72, 0.95, 0.75)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	blocker.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Saved Progress Found"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CHIVO_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	vbox.add_child(title)

	var body := Label.new()
	body.text = (
		"You have saved story progress in %s.\n\n"
		% chapter_label
		+ "Continue from where you left off, or restart the chapter from the beginning.")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_override("font", CHIVO_FONT)
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color(0.78, 0.80, 0.86))
	vbox.add_child(body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var continue_btn := Button.new()
	continue_btn.text = "Continue Saved Progress"
	continue_btn.custom_minimum_size = Vector2(0, 40)
	continue_btn.add_theme_font_override("font", CHIVO_FONT)
	continue_btn.add_theme_font_size_override("font_size", 13)
	continue_btn.pressed.connect(func() -> void:
		blocker.queue_free()
		_play_vn(vn_path, false))
	btn_row.add_child(continue_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Restart Chapter"
	restart_btn.custom_minimum_size = Vector2(0, 40)
	restart_btn.add_theme_font_override("font", CHIVO_FONT)
	restart_btn.add_theme_font_size_override("font_size", 13)
	restart_btn.pressed.connect(func() -> void:
		blocker.queue_free()
		_play_vn(vn_path, true, card))
	btn_row.add_child(restart_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(90, 40)
	cancel_btn.add_theme_font_override("font", CHIVO_FONT)
	cancel_btn.add_theme_font_size_override("font_size", 13)
	cancel_btn.pressed.connect(func() -> void: blocker.queue_free())
	btn_row.add_child(cancel_btn)


func _show_continue_or_restart_exploration_dialog(
		card: Dictionary,
		vn_path: String,
		graph_path: String) -> void:
	if get_node_or_null("ChapterResumeDialog") != null:
		return
	var chapter_label: String = str(card.get("line2", card.get("line1", "this chapter")))

	var blocker := ColorRect.new()
	blocker.name = "ChapterResumeDialog"
	blocker.color = Color(0.0, 0.0, 0.0, 0.72)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.z_index = 30
	add_child(blocker)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260.0
	panel.offset_right = 260.0
	panel.offset_top = -130.0
	panel.offset_bottom = 130.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	sb.border_color = Color(0.55, 0.72, 0.95, 0.75)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	blocker.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Saved Progress Found"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CHIVO_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	vbox.add_child(title)

	var body := Label.new()
	body.text = (
		"You have saved exploration progress in %s.\n\n"
		% chapter_label
		+ "Continue from where you left off, or restart the chapter from the beginning.")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_override("font", CHIVO_FONT)
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color(0.78, 0.80, 0.86))
	vbox.add_child(body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var continue_btn := Button.new()
	continue_btn.text = "Continue Saved Progress"
	continue_btn.custom_minimum_size = Vector2(0, 40)
	continue_btn.add_theme_font_override("font", CHIVO_FONT)
	continue_btn.add_theme_font_size_override("font_size", 13)
	continue_btn.pressed.connect(func() -> void:
		blocker.queue_free()
		_resume_exploration(graph_path))
	btn_row.add_child(continue_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Restart Chapter"
	restart_btn.custom_minimum_size = Vector2(0, 40)
	restart_btn.add_theme_font_override("font", CHIVO_FONT)
	restart_btn.add_theme_font_size_override("font_size", 13)
	restart_btn.pressed.connect(func() -> void:
		blocker.queue_free()
		_show_restart_exploration_warning_dialog(card, vn_path, graph_path, chapter_label))
	btn_row.add_child(restart_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(90, 40)
	cancel_btn.add_theme_font_override("font", CHIVO_FONT)
	cancel_btn.add_theme_font_size_override("font_size", 13)
	cancel_btn.pressed.connect(func() -> void: blocker.queue_free())
	btn_row.add_child(cancel_btn)


func _show_restart_exploration_warning_dialog(
		card: Dictionary,
		vn_path: String,
		_graph_path: String,
		chapter_label: String) -> void:
	if get_node_or_null("ChapterRestartDialog") != null:
		return

	var blocker := ColorRect.new()
	blocker.name = "ChapterRestartDialog"
	blocker.color = Color(0.0, 0.0, 0.0, 0.72)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.z_index = 30
	add_child(blocker)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -250.0
	panel.offset_right = 250.0
	panel.offset_top = -110.0
	panel.offset_bottom = 110.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.06, 0.06, 0.98)
	sb.border_color = Color(1.0, 0.45, 0.35, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	blocker.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Restart Chapter?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CHIVO_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	vbox.add_child(title)

	var body := Label.new()
	body.text = "Restarting %s will erase all saved exploration progress for this chapter." % chapter_label
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_override("font", CHIVO_FONT)
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color(0.88, 0.78, 0.74))
	vbox.add_child(body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var confirm_btn := Button.new()
	confirm_btn.text = "Restart Chapter"
	confirm_btn.custom_minimum_size = Vector2(0, 40)
	confirm_btn.add_theme_font_override("font", CHIVO_FONT)
	confirm_btn.add_theme_font_size_override("font_size", 13)
	confirm_btn.pressed.connect(func() -> void:
		blocker.queue_free()
		ExplorationManager.clear_saved_session()
		SaveManager.clear_vn_checkpoint(vn_path)
		_play_vn(vn_path, true, card))
	btn_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(90, 40)
	cancel_btn.add_theme_font_override("font", CHIVO_FONT)
	cancel_btn.add_theme_font_size_override("font_size", 13)
	cancel_btn.pressed.connect(func() -> void: blocker.queue_free())
	btn_row.add_child(cancel_btn)


func _resume_exploration(graph_path: String) -> void:
	ExplorationManager.resume_saved_exploration(
		graph_path,
		"res://scenes/main_menu.tscn")


func _show_continue_or_restart_dialog(card: Dictionary, vn_path: String, dungeon_id: String) -> void:
	if get_node_or_null("ChapterResumeDialog") != null:
		return
	var chapter_label: String = str(card.get("line2", card.get("line1", "this chapter")))

	var blocker := ColorRect.new()
	blocker.name = "ChapterResumeDialog"
	blocker.color = Color(0.0, 0.0, 0.0, 0.72)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.z_index = 30
	add_child(blocker)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260.0
	panel.offset_right = 260.0
	panel.offset_top = -130.0
	panel.offset_bottom = 130.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	sb.border_color = Color(0.55, 0.72, 0.95, 0.75)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	blocker.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Saved Progress Found"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CHIVO_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	vbox.add_child(title)

	var body := Label.new()
	body.text = (
		"You have saved progress in %s.\n\n"
		% chapter_label
		+ "Continue from where you left off, or restart the chapter from the beginning.")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_override("font", CHIVO_FONT)
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color(0.78, 0.80, 0.86))
	vbox.add_child(body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var continue_btn := Button.new()
	continue_btn.text = "Continue Saved Progress"
	continue_btn.custom_minimum_size = Vector2(0, 40)
	continue_btn.add_theme_font_override("font", CHIVO_FONT)
	continue_btn.add_theme_font_size_override("font_size", 13)
	continue_btn.pressed.connect(func() -> void:
		blocker.queue_free()
		_resume_story_dungeon(dungeon_id))
	btn_row.add_child(continue_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Restart Chapter"
	restart_btn.custom_minimum_size = Vector2(0, 40)
	restart_btn.add_theme_font_override("font", CHIVO_FONT)
	restart_btn.add_theme_font_size_override("font_size", 13)
	restart_btn.pressed.connect(func() -> void:
		blocker.queue_free()
		_show_restart_warning_dialog(card, vn_path, dungeon_id, chapter_label))
	btn_row.add_child(restart_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(90, 40)
	cancel_btn.add_theme_font_override("font", CHIVO_FONT)
	cancel_btn.add_theme_font_size_override("font_size", 13)
	cancel_btn.pressed.connect(func() -> void: blocker.queue_free())
	btn_row.add_child(cancel_btn)


func _show_restart_warning_dialog(
		card: Dictionary,
		vn_path: String,
		dungeon_id: String,
		chapter_label: String) -> void:
	if get_node_or_null("ChapterRestartDialog") != null:
		return

	var blocker := ColorRect.new()
	blocker.name = "ChapterRestartDialog"
	blocker.color = Color(0.0, 0.0, 0.0, 0.72)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.z_index = 30
	add_child(blocker)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -250.0
	panel.offset_right = 250.0
	panel.offset_top = -110.0
	panel.offset_bottom = 110.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.06, 0.06, 0.98)
	sb.border_color = Color(1.0, 0.45, 0.35, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	blocker.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Restart Chapter?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CHIVO_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	vbox.add_child(title)

	var body := Label.new()
	body.text = "Restarting %s will erase all saved dungeon progress, wheel modifiers, and map position for this chapter." % chapter_label
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_override("font", CHIVO_FONT)
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color(0.88, 0.78, 0.74))
	vbox.add_child(body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var confirm_btn := Button.new()
	confirm_btn.text = "Restart Chapter"
	confirm_btn.custom_minimum_size = Vector2(0, 40)
	confirm_btn.add_theme_font_override("font", CHIVO_FONT)
	confirm_btn.add_theme_font_size_override("font_size", 13)
	confirm_btn.pressed.connect(func() -> void:
		blocker.queue_free()
		DailyDungeonManager.reset_story_dungeon_chapter(dungeon_id)
		_play_vn(vn_path, true, card))
	btn_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(90, 40)
	cancel_btn.add_theme_font_override("font", CHIVO_FONT)
	cancel_btn.add_theme_font_size_override("font_size", 13)
	cancel_btn.pressed.connect(func() -> void: blocker.queue_free())
	btn_row.add_child(cancel_btn)


func _resume_story_dungeon(dungeon_id: String) -> void:
	DailyDungeonManager.resume_story_dungeon(dungeon_id)
	get_tree().change_scene_to_file(DUNGEON_MAP_SCENE)


func _play_vn(json_path: String, fresh_start: bool = true, card: Dictionary = {}) -> void:
	_play_vn_async(json_path, fresh_start, card)

func _play_vn_async(json_path: String, fresh_start: bool = true, card: Dictionary = {}) -> void:
	await BGMManager.fade_out_and_stop(BGMManager.DEFAULT_FADE)
	if fresh_start:
		SaveManager.clear_vn_checkpoint(json_path)
	var vn_scene: Variant = load(VN_PLAYER_SCENE)
	var vn := (vn_scene as PackedScene).instantiate()
	add_child(vn)
	vn.play_scene(json_path, func() -> void:
		SaveManager.mark_gallery_chapter_completed(json_path)
		ExplorationManager.clear_saved_session_for_chapter(json_path, card)
	, true)


func _get_prerequisite_vn(d: Dictionary) -> String:
	var prereq: String = str(d.get("prerequisite_chapter", "")).strip_edges()
	if prereq != "":
		return prereq
	# Legacy: campaign map node id (e.g. ch0_s1)
	var legacy_id: String = str(d.get("unlock_requires", "")).strip_edges()
	if legacy_id == "":
		return ""
	return CampaignManager.get_vn_scene_for_node(legacy_id)


func _is_chapter_locked(d: Dictionary) -> bool:
	var prereq_vn: String = _get_prerequisite_vn(d)
	if prereq_vn == "":
		return false
	return not SaveManager.is_gallery_chapter_completed(prereq_vn)


func _prerequisite_display_name(prereq_vn: String) -> String:
	if prereq_vn.is_empty():
		return ""
	for raw: Variant in _data:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw as Dictionary
		if str(entry.get("vn_scene", "")).strip_edges() == prereq_vn:
			var line2: String = str(entry.get("line2", "")).strip_edges()
			if line2 != "":
				return line2
			return str(entry.get("line1", "prior chapter")).strip_edges()
	if ResourceLoader.exists(prereq_vn):
		return prereq_vn.get_file().get_basename()
	return prereq_vn
