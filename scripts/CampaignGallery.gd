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
	back_btn.add_theme_font_override("font", CHIVO_FONT)
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
	var req_node:  String = str(d.get("unlock_requires", "")).strip_edges()
	var is_locked: bool   = req_node != "" and not CampaignManager.completed.has(req_node)

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
	if not is_locked and img_path != "" and ResourceLoader.exists(img_path):
		tex = load(img_path)
	if tex == null:
		tex = load(PLACEHOLDER_IMG)

	var img := TextureRect.new()
	img.texture      = tex
	img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Desaturate locked cards at the modulate level
	if is_locked:
		img.modulate = Color(0.35, 0.35, 0.38, 1.0)
	frame.add_child(img)

	# ── Locked overlay ────────────────────────────────────────
	if is_locked:
		var dim := ColorRect.new()
		dim.color = Color(0.0, 0.0, 0.0, 0.70)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(dim)

		var lbl_lock := Label.new()
		lbl_lock.text = "🔒\nLOCKED"
		lbl_lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_lock.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl_lock.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_lock.add_theme_font_override("font", CHIVO_FONT)
		lbl_lock.add_theme_font_size_override("font_size", 14)
		lbl_lock.add_theme_color_override("font_color", Color(0.55, 0.55, 0.58))
		lbl_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(lbl_lock)

	# ── Coming soon overlay (unlocked but no VN yet) ──────────
	elif not has_vn:
		var dim := ColorRect.new()
		dim.color = Color(0.0, 0.0, 0.0, 0.62)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(dim)

		var lbl_cs := Label.new()
		var _ct: String = str(d.get("custom_text", "")).strip_edges()
		lbl_cs.text = _ct if _ct != "" else "COMING\nSOON"
		lbl_cs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_cs.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl_cs.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_cs.add_theme_font_override("font", CHIVO_FONT)
		lbl_cs.add_theme_font_size_override("font_size", 13)
		lbl_cs.add_theme_color_override("font_color", Color(0.65, 0.65, 0.68))
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

	# ── Line 1 (chapter) ──────────────────────────────────────
	var l1 := Label.new()
	l1.text = str(d.get("line1", ""))
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_font_override("font", CHIVO_FONT)
	l1.add_theme_font_size_override("font_size", 14)
	l1.add_theme_color_override("font_color",
		Color(0.40, 0.40, 0.43, 0.7) if is_locked else Color(1.0, 1.0, 1.0, 0.95))
	card.add_child(l1)

	# ── Line 2 (stage) ────────────────────────────────────────
	var l2 := Label.new()
	l2.text = str(d.get("line2", ""))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.add_theme_font_override("font", CHIVO_FONT)
	l2.add_theme_font_size_override("font_size", 12)
	l2.add_theme_color_override("font_color",
		Color(0.35, 0.35, 0.38, 0.6) if is_locked else Color(0.60, 0.62, 0.68, 0.85))
	card.add_child(l2)

	return card


func _on_chapter_pressed(card: Dictionary) -> void:
	var vn_path: String = str(card.get("vn_scene", "")).strip_edges()
	if vn_path.is_empty():
		return
	var dungeon_info: Dictionary = _resolve_chapter_dungeon(card, vn_path)
	var dungeon_id: String = str(dungeon_info.get("dungeon_id", "")).strip_edges()
	if dungeon_id != "" and DailyDungeonManager.has_story_dungeon_save(dungeon_id):
		_show_continue_or_restart_dialog(card, vn_path, dungeon_id)
	else:
		_play_vn(vn_path)


func _resolve_chapter_dungeon(card: Dictionary, vn_path: String) -> Dictionary:
	var dungeon_id: String = str(card.get("dungeon_id", "")).strip_edges()
	if dungeon_id != "":
		return {
			"dungeon_id": dungeon_id,
			"dungeon_on_win": str(card.get("dungeon_on_win", "")),
			"dungeon_on_lose": str(card.get("dungeon_on_lose", "")),
		}
	return DailyDungeonManager.find_dungeon_call_in_vn(vn_path)


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
	body.text = (
		"Restarting %s will erase all saved dungeon progress,\n"
		% chapter_label
		+ "wheel modifiers, and map position for this chapter.")
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
		_play_vn(vn_path))
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


func _play_vn(json_path: String) -> void:
	var vn_scene: Variant = load(VN_PLAYER_SCENE)
	var vn := (vn_scene as PackedScene).instantiate()
	add_child(vn)
	vn.play_scene(json_path, func() -> void: pass)
