extends Control
# Campaign Gallery Editor — full-screen overlay for managing gallery_data.json
# Open via Admin Console: gallery_editor

const GALLERY_PATH  := "res://campaign/gallery_data.json"
const PLACEHOLDER   := "res://assets/textures/campagin/placeholder_campagin.png"
const CHIVO_FONT    := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")

var _data:         Array    = []
var _selected_idx: int      = -1
var _dirty:        bool     = false

# UI refs
var _entry_list:  ItemList  = null
var _status_lbl:  Label     = null
var _f_line1:     LineEdit  = null
var _f_line2:     LineEdit  = null
var _f_image:     LineEdit  = null
var _f_vn:        LineEdit  = null
var _f_newline:        CheckBox  = null
var _f_prerequisite:   OptionButton = null
var _prerequisite_values: Array = []
var _f_custom_text_on: CheckBox  = null
var _f_custom_text:    LineEdit  = null
var _f_unlock_deckbuilding: CheckBox = null
var _fields_root: Control   = null
var _no_sel_lbl:  Label     = null
var _file_dialog: FileDialog = null
var _browse_target: LineEdit = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 200
	_load_data()
	_build_ui()
	_rebuild_list()


# ─────────────────────────────────────────────────────────────
# Data I/O
# ─────────────────────────────────────────────────────────────
func _load_data() -> void:
	if not FileAccess.file_exists(GALLERY_PATH):
		return
	var f := FileAccess.open(GALLERY_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Array:
		_data = parsed as Array


func _save_data() -> void:
	var f := FileAccess.open(GALLERY_PATH, FileAccess.WRITE)
	if f == null:
		_status("ERROR: could not write to " + GALLERY_PATH)
		return
	f.store_string(JSON.stringify(_data, "\t"))
	f.close()
	_dirty = false
	_status("Saved  (%d entries)" % _data.size())


# ─────────────────────────────────────────────────────────────
# UI construction
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Dim backdrop
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.06, 0.08, 0.97)
	add_child(bg)

	# ── Top bar ───────────────────────────────────────────────
	var top := Panel.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 48.0
	var top_sb := StyleBoxFlat.new()
	top_sb.bg_color = Color(0.12, 0.12, 0.16)
	top.add_theme_stylebox_override("panel", top_sb)
	add_child(top)

	var close_btn := Button.new()
	close_btn.text = "✕ CLOSE"
	close_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	close_btn.offset_left   = 10.0
	close_btn.offset_top    = 8.0
	close_btn.offset_right  = 120.0
	close_btn.offset_bottom = 40.0
	close_btn.add_theme_font_override("font", CHIVO_FONT)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_on_close)
	top.add_child(close_btn)

	var title_lbl := Label.new()
	title_lbl.text = "Campaign Gallery Editor"
	title_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_lbl.offset_top    = 12.0
	title_lbl.offset_bottom = 40.0
	title_lbl.offset_left   = -200.0
	title_lbl.offset_right  = 200.0
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", CHIVO_FONT)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	top.add_child(title_lbl)

	var save_btn := Button.new()
	save_btn.text = "💾 SAVE"
	save_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	save_btn.offset_left   = -120.0
	save_btn.offset_top    = 8.0
	save_btn.offset_right  = -10.0
	save_btn.offset_bottom = 40.0
	save_btn.add_theme_font_override("font", CHIVO_FONT)
	save_btn.add_theme_font_size_override("font_size", 14)
	save_btn.pressed.connect(_save_data)
	top.add_child(save_btn)

	# ── Status bar ────────────────────────────────────────────
	_status_lbl = Label.new()
	_status_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_status_lbl.offset_top    = -26.0
	_status_lbl.offset_bottom = 0.0
	_status_lbl.offset_left   = 8.0
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_status_lbl.add_theme_font_override("font", CHIVO_FONT)
	_status_lbl.add_theme_font_size_override("font_size", 12)
	_status_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	add_child(_status_lbl)

	# ── Main area (below top bar, above status) ───────────────
	var main := HSplitContainer.new()
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.offset_top    = 50.0
	main.offset_bottom = -28.0
	main.split_offset  = 300
	add_child(main)

	# ── Left: entry list + list buttons ──────────────────────
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(left)

	_entry_list = ItemList.new()
	_entry_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_entry_list.add_theme_font_override("font", CHIVO_FONT)
	_entry_list.add_theme_font_size_override("font_size", 13)
	_entry_list.item_selected.connect(_on_entry_selected)
	left.add_child(_entry_list)

	# List action buttons
	var list_btns := HBoxContainer.new()
	list_btns.add_theme_constant_override("separation", 4)
	left.add_child(list_btns)

	var _mk_lb := func(label: String, cb: Callable) -> void:
		var b := Button.new()
		b.text = label
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_override("font", CHIVO_FONT)
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(cb)
		list_btns.add_child(b)

	_mk_lb.call("+ Add",    _on_add)
	_mk_lb.call("− Remove", _on_remove)
	_mk_lb.call("↑ Up",     _on_move_up)
	_mk_lb.call("↓ Down",   _on_move_down)

	# ── Right: edit fields ────────────────────────────────────
	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(right_scroll)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right)

	_no_sel_lbl = Label.new()
	_no_sel_lbl.text = "Select an entry to edit."
	_no_sel_lbl.add_theme_font_override("font", CHIVO_FONT)
	_no_sel_lbl.add_theme_font_size_override("font_size", 14)
	_no_sel_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	right.add_child(_no_sel_lbl)

	_fields_root = VBoxContainer.new()
	_fields_root.add_theme_constant_override("separation", 10)
	_fields_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fields_root.visible = false
	right.add_child(_fields_root)

	var _row := func(label: String) -> HBoxContainer:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		_fields_root.add_child(hb)
		var lbl := Label.new()
		lbl.text             = label
		lbl.custom_minimum_size = Vector2(90.0, 0.0)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", CHIVO_FONT)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
		hb.add_child(lbl)
		return hb

	var _field := func(hb: HBoxContainer) -> LineEdit:
		var le := LineEdit.new()
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.add_theme_font_override("font", CHIVO_FONT)
		le.add_theme_font_size_override("font_size", 13)
		le.text_changed.connect(func(_s: String) -> void: _mark_dirty())
		hb.add_child(le)
		return le

	var _browse_btn := func(hb: HBoxContainer, target: LineEdit) -> void:
		var b := Button.new()
		b.text = "…"
		b.custom_minimum_size = Vector2(32.0, 0.0)
		b.add_theme_font_override("font", CHIVO_FONT)
		b.pressed.connect(func() -> void: _open_file_dialog(target))
		hb.add_child(b)

	var row1: HBoxContainer = _row.call("Line 1")
	_f_line1 = _field.call(row1)

	var row2: HBoxContainer = _row.call("Line 2")
	_f_line2 = _field.call(row2)

	var row_img: HBoxContainer = _row.call("Image")
	_f_image = _field.call(row_img)
	_browse_btn.call(row_img, _f_image)

	var row_vn: HBoxContainer = _row.call("VN Scene")
	_f_vn = _field.call(row_vn)
	_browse_btn.call(row_vn, _f_vn)

	var row_prereq: HBoxContainer = _row.call("Prerequisite")
	_f_prerequisite = OptionButton.new()
	_f_prerequisite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_f_prerequisite.add_theme_font_override("font", CHIVO_FONT)
	_f_prerequisite.add_theme_font_size_override("font_size", 13)
	_f_prerequisite.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	row_prereq.add_child(_f_prerequisite)
	var prereq_hint := Label.new()
	prereq_hint.text = "Finish this chapter first to unlock"
	prereq_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prereq_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prereq_hint.add_theme_font_override("font", CHIVO_FONT)
	prereq_hint.add_theme_font_size_override("font_size", 11)
	prereq_hint.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55))
	_fields_root.add_child(prereq_hint)

	var row_nl: HBoxContainer = _row.call("New Line")
	_f_newline = CheckBox.new()
	_f_newline.text = "Start a new row before this entry"
	_f_newline.add_theme_font_override("font", CHIVO_FONT)
	_f_newline.add_theme_font_size_override("font_size", 13)
	_f_newline.toggled.connect(func(_b: bool) -> void: _mark_dirty())
	row_nl.add_child(_f_newline)

	var row_ct: HBoxContainer = _row.call("Custom Text")
	_f_custom_text_on = CheckBox.new()
	_f_custom_text_on.text = ""
	_f_custom_text_on.add_theme_font_override("font", CHIVO_FONT)
	_f_custom_text_on.toggled.connect(func(b: bool) -> void:
		_f_custom_text.editable = b
		_f_custom_text.modulate.a = 1.0 if b else 0.4
		_mark_dirty())
	row_ct.add_child(_f_custom_text_on)
	_f_custom_text = LineEdit.new()
	_f_custom_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_f_custom_text.placeholder_text = "Text shown instead of COMING SOON"
	_f_custom_text.add_theme_font_override("font", CHIVO_FONT)
	_f_custom_text.add_theme_font_size_override("font_size", 13)
	_f_custom_text.text_changed.connect(func(_s: String) -> void: _mark_dirty())
	row_ct.add_child(_f_custom_text)

	var row_ud: HBoxContainer = _row.call("Unlock")
	_f_unlock_deckbuilding = CheckBox.new()
	_f_unlock_deckbuilding.text = "Unlock deckbuilding after cleared"
	_f_unlock_deckbuilding.add_theme_font_override("font", CHIVO_FONT)
	_f_unlock_deckbuilding.add_theme_font_size_override("font_size", 13)
	_f_unlock_deckbuilding.toggled.connect(func(_b: bool) -> void: _mark_dirty())
	row_ud.add_child(_f_unlock_deckbuilding)

	# Preview thumbnail
	var sep := HSeparator.new()
	_fields_root.add_child(sep)

	var prev_lbl := Label.new()
	prev_lbl.text = "Preview:"
	prev_lbl.add_theme_font_override("font", CHIVO_FONT)
	prev_lbl.add_theme_font_size_override("font_size", 12)
	prev_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	_fields_root.add_child(prev_lbl)

	# File dialog (shared)
	_file_dialog = FileDialog.new()
	_file_dialog.access      = FileDialog.ACCESS_RESOURCES
	_file_dialog.file_mode   = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.add_filter("*.png,*.jpg,*.jpeg,*.webp", "Images")
	_file_dialog.add_filter("*.json", "JSON files")
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)


# ─────────────────────────────────────────────────────────────
# Entry list
# ─────────────────────────────────────────────────────────────
func _rebuild_list() -> void:
	_entry_list.clear()
	for i: int in range(_data.size()):
		var d: Dictionary = _data[i] as Dictionary
		var nl: String    = "⏎ " if bool(d.get("new_line_before", false)) else "   "
		var has_vn: String = "▶ " if str(d.get("vn_scene", "")).strip_edges() != "" else "○ "
		var lock_mark: String = ""
		var prereq_vn: String = str(d.get("prerequisite_chapter", "")).strip_edges()
		if prereq_vn == "":
			var legacy: String = str(d.get("unlock_requires", "")).strip_edges()
			if legacy != "":
				prereq_vn = CampaignManager.get_vn_scene_for_node(legacy)
		if prereq_vn != "":
			lock_mark = "🔒 "
		var label: String = "%s%s%s%s  /  %s" % [
			nl, lock_mark, has_vn, str(d.get("line1", "")), str(d.get("line2", ""))
		]
		_entry_list.add_item(label)
	if _selected_idx >= 0 and _selected_idx < _entry_list.item_count:
		_entry_list.select(_selected_idx)


func _on_entry_selected(idx: int) -> void:
	_selected_idx = idx
	_load_fields()


func _load_fields() -> void:
	if _selected_idx < 0 or _selected_idx >= _data.size():
		_fields_root.visible = false
		_no_sel_lbl.visible  = true
		return
	_fields_root.visible = true
	_no_sel_lbl.visible  = false
	var d: Dictionary = _data[_selected_idx] as Dictionary
	_f_line1.text   = str(d.get("line1", ""))
	_f_line2.text   = str(d.get("line2", ""))
	_f_image.text   = str(d.get("image", ""))
	_f_vn.text      = str(d.get("vn_scene", ""))
	_rebuild_prerequisite_options()
	var prereq_vn: String = str(d.get("prerequisite_chapter", "")).strip_edges()
	if prereq_vn == "":
		var legacy_id: String = str(d.get("unlock_requires", "")).strip_edges()
		if legacy_id != "":
			prereq_vn = CampaignManager.get_vn_scene_for_node(legacy_id)
	var sel_idx: int = _prerequisite_values.find(prereq_vn)
	_f_prerequisite.select(maxi(0, sel_idx))
	_f_newline.button_pressed = bool(d.get("new_line_before", false))
	var _ct: String = str(d.get("custom_text", "")).strip_edges()
	_f_custom_text_on.button_pressed = _ct != ""
	_f_custom_text.text = _ct
	_f_custom_text.editable = _ct != ""
	_f_custom_text.modulate.a = 1.0 if _ct != "" else 0.4
	_f_unlock_deckbuilding.button_pressed = bool(d.get("unlock_deckbuilding", false))


func _flush_fields() -> void:
	if _selected_idx < 0 or _selected_idx >= _data.size():
		return
	var d: Dictionary = _data[_selected_idx] as Dictionary
	d["line1"]          = _f_line1.text.strip_edges()
	d["line2"]          = _f_line2.text.strip_edges()
	d["image"]          = _f_image.text.strip_edges()
	d["vn_scene"]        = _f_vn.text.strip_edges()
	var pre_idx: int = _f_prerequisite.selected
	var pre_vn: String = ""
	if pre_idx >= 0 and pre_idx < _prerequisite_values.size():
		pre_vn = str(_prerequisite_values[pre_idx]).strip_edges()
	if pre_vn != "":
		d["prerequisite_chapter"] = pre_vn
	else:
		d.erase("prerequisite_chapter")
	d.erase("unlock_requires")
	d["new_line_before"] = _f_newline.button_pressed
	if _f_custom_text_on.button_pressed:
		d["custom_text"] = _f_custom_text.text.strip_edges()
	else:
		d.erase("custom_text")
	if _f_unlock_deckbuilding.button_pressed:
		d["unlock_deckbuilding"] = true
	else:
		d.erase("unlock_deckbuilding")


# ─────────────────────────────────────────────────────────────
# List actions
# ─────────────────────────────────────────────────────────────
func _on_add() -> void:
	_flush_fields()
	_data.append({
		"line1": "New Entry",
		"line2": "Stage ?",
		"image": "",
		"vn_scene": "",
		"new_line_before": false,
		"prerequisite_chapter": "",
	})
	_selected_idx = _data.size() - 1
	_rebuild_list()
	_load_fields()
	_mark_dirty()


func _on_remove() -> void:
	if _selected_idx < 0 or _selected_idx >= _data.size():
		_status("Nothing selected.")
		return
	_data.remove_at(_selected_idx)
	_selected_idx = mini(_selected_idx, _data.size() - 1)
	_rebuild_list()
	_load_fields()
	_mark_dirty()


func _on_move_up() -> void:
	if _selected_idx <= 0:
		return
	_flush_fields()
	var tmp: Variant = _data[_selected_idx]
	_data[_selected_idx]     = _data[_selected_idx - 1]
	_data[_selected_idx - 1] = tmp
	_selected_idx -= 1
	_rebuild_list()
	_load_fields()
	_mark_dirty()


func _on_move_down() -> void:
	if _selected_idx < 0 or _selected_idx >= _data.size() - 1:
		return
	_flush_fields()
	var tmp: Variant = _data[_selected_idx]
	_data[_selected_idx]     = _data[_selected_idx + 1]
	_data[_selected_idx + 1] = tmp
	_selected_idx += 1
	_rebuild_list()
	_load_fields()
	_mark_dirty()


func _rebuild_prerequisite_options() -> void:
	if _f_prerequisite == null:
		return
	_f_prerequisite.clear()
	_prerequisite_values = [""]
	_f_prerequisite.add_item("(none — always unlocked)")
	for i: int in range(_data.size()):
		if i == _selected_idx:
			continue
		var d: Dictionary = _data[i] as Dictionary
		var vn: String = str(d.get("vn_scene", "")).strip_edges()
		if vn == "":
			continue
		var label: String = "%s / %s" % [str(d.get("line1", "")), str(d.get("line2", ""))]
		_f_prerequisite.add_item(label)
		_prerequisite_values.append(vn)


# ─────────────────────────────────────────────────────────────
# File browse
# ─────────────────────────────────────────────────────────────
func _open_file_dialog(target: LineEdit) -> void:
	_browse_target = target
	_file_dialog.popup_centered_ratio(0.7)


func _on_file_selected(path: String) -> void:
	if _browse_target != null:
		_browse_target.text = path
		_mark_dirty()


# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _mark_dirty() -> void:
	_flush_fields()
	_rebuild_list()
	_dirty = true


func _status(msg: String) -> void:
	_status_lbl.text = msg


func _on_close() -> void:
	if _dirty:
		_status("Unsaved changes! Save first or close again to discard.")
		_dirty = false
		return
	queue_free()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			_on_close()
			get_viewport().set_input_as_handled()
