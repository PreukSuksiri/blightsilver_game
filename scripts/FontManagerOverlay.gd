extends Control
# FontManagerOverlay — admin UI to assign fonts per game slot and preview live.
# Open via Admin Console: manage_fonts

const _BG_COLOR     := Color(0.05, 0.05, 0.10, 0.97)
const _HEADER_COLOR := Color(0.10, 0.12, 0.22, 1.0)
const _PANEL_COLOR  := Color(0.09, 0.10, 0.16, 1.0)
const _ROW_A        := Color(0.09, 0.09, 0.15, 1.0)
const _ROW_B        := Color(0.12, 0.12, 0.20, 1.0)
const _BTN_SAVE     := Color(0.12, 0.55, 0.28, 1.0)
const _BTN_CLOSE    := Color(0.55, 0.12, 0.12, 1.0)
const _BTN_RESET    := Color(0.30, 0.22, 0.10, 1.0)
const _BTN_BROWSE   := Color(0.22, 0.22, 0.32, 1.0)
const _BTN_APPLY    := Color(0.12, 0.42, 0.62, 1.0)

var _status_lbl: Label = null
var _rows: Dictionary = {}
var _file_dialog: FileDialog = null
var _browse_slot: String = ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 100

	var bg := ColorRect.new()
	bg.color = _BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_build_header()
	_build_body()
	_build_bottom_bar()
	_build_file_dialog()


func _build_header() -> void:
	var header := _make_panel(_HEADER_COLOR)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.custom_minimum_size = Vector2(0, 52)
	add_child(header)
	
	

	var title := Label.new()
	title.text = "Font Manager"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)

	var close_btn := _make_button("X", _BTN_CLOSE)
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -48
	close_btn.offset_top = 4
	close_btn.offset_right = -4
	close_btn.offset_bottom = 48
	close_btn.pressed.connect(queue_free)
	#header.add_child(close_btn)
	
	
	var save_btn := _make_button("Save", _BTN_SAVE)
	save_btn.pressed.connect(_on_save)
	header.add_child(save_btn)


func _build_body() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchor(SIDE_LEFT, 0.0)
	scroll.set_anchor(SIDE_RIGHT, 1.0)
	scroll.set_anchor(SIDE_TOP, 0.0)
	scroll.set_anchor(SIDE_BOTTOM, 1.0)
	scroll.offset_left = 20.0
	scroll.offset_right = -20.0
	scroll.offset_top = 60.0
	scroll.offset_bottom = -64.0
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	var hint := Label.new()
	hint.text = "Assign a .ttf/.otf per slot. Apply swaps fonts live across tagged UI (exploration, VN, main menu)."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
	vbox.add_child(hint)

	var row_idx: int = 0
	for slot_id: Variant in FontManager.get_slot_ids():
		var sid: String = str(slot_id)
		vbox.add_child(_build_slot_row(sid, row_idx % 2 == 0))
		row_idx += 1


func _build_slot_row(slot_id: String, alt: bool) -> PanelContainer:
	var panel := _make_panel(_ROW_A if alt else _ROW_B)
	panel.custom_minimum_size = Vector2(0, 108)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 12.0
	vb.offset_right = -12.0
	vb.offset_top = 8.0
	vb.offset_bottom = -8.0
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vb.add_child(title_row)

	var title := Label.new()
	title.text = "%s  (%s)" % [FontManager.get_slot_label(slot_id), slot_id]
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var reset_btn := _make_button("Reset", _BTN_RESET)
	reset_btn.custom_minimum_size = Vector2(64, 28)
	reset_btn.pressed.connect(func() -> void: _on_reset_slot(slot_id))
	title_row.add_child(reset_btn)

	var desc := Label.new()
	desc.text = FontManager.get_slot_description(slot_id)
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72))
	vb.add_child(desc)

	var path_row := HBoxContainer.new()
	path_row.add_theme_constant_override("separation", 6)
	vb.add_child(path_row)

	var path_edit := LineEdit.new()
	path_edit.text = FontManager.get_slot_path(slot_id)
	path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_edit.add_theme_font_size_override("font_size", 12)
	path_row.add_child(path_edit)

	var browse_btn := _make_button("...", _BTN_BROWSE)
	browse_btn.custom_minimum_size = Vector2(36, 0)
	browse_btn.pressed.connect(func() -> void:
		_browse_slot = slot_id
		_file_dialog.popup_centered(Vector2(700, 500)))
	path_row.add_child(browse_btn)

	var preview_lbl := Label.new()
	preview_lbl.text = "The quick brown fox jumps — あいうえお"
	preview_lbl.add_theme_font_override("font", FontManager.make_font(slot_id, 500))
	preview_lbl.add_theme_font_size_override("font_size", 18)
	preview_lbl.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0))
	vb.add_child(preview_lbl)

	path_edit.text_changed.connect(func(t: String) -> void:
		FontManager.set_slot_path(slot_id, t)
		preview_lbl.add_theme_font_override("font", FontManager.make_font(slot_id, 500)))

	_rows[slot_id] = {"path_edit": path_edit, "preview": preview_lbl}
	return panel


func _build_bottom_bar() -> void:
	var bar := _make_panel(_PANEL_COLOR)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.custom_minimum_size = Vector2(0, 52)
	add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 16.0
	hbox.offset_right = -16.0
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(hbox)

	_status_lbl = Label.new()
	_status_lbl.text = "Edit paths then Apply — saves to res://data/fonts.json in the editor."
	_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_lbl.add_theme_font_size_override("font_size", 12)
	_status_lbl.add_theme_color_override("font_color", Color(0.55, 0.70, 0.85))
	hbox.add_child(_status_lbl)

	var reset_all_btn := _make_button("Reset All", _BTN_RESET)
	reset_all_btn.pressed.connect(_on_reset_all)
	hbox.add_child(reset_all_btn)

	var apply_btn := _make_button("Apply", _BTN_APPLY)
	apply_btn.pressed.connect(_on_apply)
	hbox.add_child(apply_btn)



func _build_file_dialog() -> void:
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_file_dialog.filters = PackedStringArray(["*.ttf,*.otf ; Font Files"])
	_file_dialog.current_dir = "res://assets/fonts"
	_file_dialog.file_selected.connect(_on_font_selected)
	add_child(_file_dialog)


func _on_font_selected(path: String) -> void:
	if _browse_slot.is_empty() or not _rows.has(_browse_slot):
		return
	var row: Dictionary = _rows[_browse_slot]
	(row["path_edit"] as LineEdit).text = path
	FontManager.set_slot_path(_browse_slot, path)
	(row["preview"] as Label).add_theme_font_override(
		"font", FontManager.make_font(_browse_slot, 500))
	if BuildConfig.can_write_shipped_data() and FontManager.save_config():
		_set_status("Saved slot '%s' → %s" % [_browse_slot, FontManager.get_shipped_config_path()])


func _on_reset_slot(slot_id: String) -> void:
	FontManager.reset_slot(slot_id)
	if _rows.has(slot_id):
		var row: Dictionary = _rows[slot_id]
		(row["path_edit"] as LineEdit).text = FontManager.get_slot_path(slot_id)
		(row["preview"] as Label).add_theme_font_override(
			"font", FontManager.make_font(slot_id, 500))
	_set_status("Reset slot '%s' to default." % slot_id)


func _on_reset_all() -> void:
	FontManager.reset_all()
	for slot_id: String in _rows:
		var row: Dictionary = _rows[slot_id]
		(row["path_edit"] as LineEdit).text = FontManager.get_slot_path(slot_id)
		(row["preview"] as Label).add_theme_font_override(
			"font", FontManager.make_font(slot_id, 500))
	_set_status("All slots reset to shipped defaults.")


func _on_apply() -> void:
	for slot_id: String in _rows:
		var row: Dictionary = _rows[slot_id]
		FontManager.set_slot_path(slot_id, (row["path_edit"] as LineEdit).text.strip_edges())
	FontManager.apply_and_notify()
	if BuildConfig.can_write_shipped_data():
		_set_status("Applied and saved to %s." % FontManager.get_shipped_config_path())
	else:
		_set_status("Fonts applied live.")


func _on_save() -> void:
	_on_apply()
	if FontManager.save_config():
		_set_status("Saved to %s and applied." % FontManager.get_shipped_config_path())
	else:
		_set_status("Apply OK but save failed.")


func _set_status(msg: String) -> void:
	if _status_lbl != null:
		_status_lbl.text = msg


func _make_panel(color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(4)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _make_button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 13)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(4)
	b.add_theme_stylebox_override("normal", sb)
	return b
