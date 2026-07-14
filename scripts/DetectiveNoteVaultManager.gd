extends Control
class_name DetectiveNoteVaultManager
## Admin editor for detective note content (data/detective_note_vault.json).
## Opened via admin command: detective_note_vault
##
## Three tabs:
##   CHAPTERS — chapters with VN scene / exploration graph bindings and
##              topics (verdict maps: nodes + edges, levels 1..5)
##   CLUES    — the global clue pool (individuals / objects / information;
##              styles: image, postit, messenger chat from Messenger Vault)
##   STAMPS   — APPROVED stamps (logo image + approver name)
##
## Localized fields have EN and TH inputs; TH left empty stores a plain string.

const NODE_KINDS := ["any", "individual", "object", "information"]
const NODE_LABEL_SIDES := DetectiveNoteVault.NODE_LABEL_SIDES
const CLUE_KINDS := ["individual", "object", "information"]
const ARROWS := ["none", "end", "start", "both"]
const CLUE_STYLES := DetectiveNoteVault.CLUE_STYLES
const TABS := ["chapters", "clues", "stamps"]

var _chapters: Array = []
var _clues: Array = []
var _stamps: Array = []
var _dirty: bool = false
var _loading: bool = false
var _tab: String = "chapters"

# Selection state
var _chapter_idx: int = -1
var _topic_idx: int = -1
var _clue_idx: int = -1
var _stamp_idx: int = -1

# Shared chrome
var _status_lbl: Label = null
var _tab_buttons: Dictionary = {}
var _tab_panels: Dictionary = {}
var _texture_dialog: FileDialog = null
var _texture_target: LineEdit = null
var _json_dialog: FileDialog = null
var _json_target: LineEdit = null

# Chapters tab controls
var _ch_list: ItemList = null
var _ch_fields: VBoxContainer = null
var _ch_id: LineEdit = null
var _ch_title_en: LineEdit = null
var _ch_title_th: LineEdit = null
var _ch_scenes_vbox: VBoxContainer = null
var _ch_graphs_vbox: VBoxContainer = null
var _ch_scene_rows: Array = []
var _ch_graph_rows: Array = []
var _ch_start_clues_vbox: VBoxContainer = null
var _ch_start_clue_rows: Array = []
var _topic_list: ItemList = null
var _topic_fields: VBoxContainer = null
var _topic_id: LineEdit = null
var _topic_title_en: LineEdit = null
var _topic_title_th: LineEdit = null
var _node_vbox: VBoxContainer = null
var _edge_vbox: VBoxContainer = null
var _node_rows: Array = []
var _edge_rows: Array = []

# Clues tab controls
var _clue_list: ItemList = null
var _clue_id: LineEdit = null
var _clue_kind_opt: OptionButton = null
var _clue_name_en: LineEdit = null
var _clue_name_th: LineEdit = null
var _clue_caption_en: LineEdit = null
var _clue_caption_th: LineEdit = null
var _clue_info_en: TextEdit = null
var _clue_info_th: TextEdit = null
var _clue_image: LineEdit = null
var _clue_thumb: TextureRect = null
var _clue_image_row: HBoxContainer = null
var _clue_conversation_row: HBoxContainer = null
var _clue_conversation_opt: OptionButton = null
var _clue_style_opt: OptionButton = null

# Stamps tab controls
var _stamp_list: ItemList = null
var _stamp_id: LineEdit = null
var _stamp_name_en: LineEdit = null
var _stamp_name_th: LineEdit = null
var _stamp_image: LineEdit = null
var _stamp_thumb: TextureRect = null


static func open(parent: Node) -> void:
	var overlay: Control = load("res://scripts/DetectiveNoteVaultManager.gd").new()
	overlay.name = "DetectiveNoteVaultManagerOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)


func _ready() -> void:
	DetectiveNoteVault.reload()
	_chapters = DetectiveNoteVault.get_chapters()
	_clues = DetectiveNoteVault.get_clues()
	_stamps = DetectiveNoteVault.get_stamps()
	_build_ui()
	_switch_tab("chapters")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _layout_overlay != null and is_instance_valid(_layout_overlay):
			_close_layout_editor()
		else:
			_request_close()
		get_viewport().set_input_as_handled()


func _request_close() -> void:
	if not _dirty:
		queue_free()
		return
	GameDialog.confirmation_overlay(
		self, "Unsaved Changes",
		"Close the Detective Note Vault without saving?",
		"Discard & Close", "Keep Editing",
		func() -> void: queue_free())


# ─────────────────────────────────────────────────────────────
# Localization helpers
# ─────────────────────────────────────────────────────────────
static func _loc_get(val: Variant, lang: String) -> String:
	if val is Dictionary:
		return str((val as Dictionary).get(lang, ""))
	return str(val) if lang == "en" and val != null else ""


static func _loc_make(en: String, th: String) -> Variant:
	if th.strip_edges().is_empty():
		return en.strip_edges()
	return {"en": en.strip_edges(), "th": th.strip_edges()}


# ─────────────────────────────────────────────────────────────
# UI construction — chrome
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.10, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := Label.new()
	header.text = "Detective Note Vault  —  chapters, verdict maps, clues and stamps"
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 8.0
	header.offset_bottom = 40.0
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	add_child(header)

	var top_btns := HBoxContainer.new()
	top_btns.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top_btns.offset_left = -320.0
	top_btns.offset_top = 6.0
	top_btns.offset_right = -8.0
	top_btns.add_theme_constant_override("separation", 8)
	add_child(top_btns)
	_add_btn(top_btns, "Reload", _on_reload)
	_add_btn(top_btns, "Save", _on_save)
	_add_btn(top_btns, "Close", _request_close)

	var tab_bar := HBoxContainer.new()
	tab_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tab_bar.offset_top = 44.0
	tab_bar.offset_bottom = 76.0
	tab_bar.offset_left = 12.0
	tab_bar.add_theme_constant_override("separation", 8)
	add_child(tab_bar)
	for t: String in TABS:
		var btn := Button.new()
		btn.text = t.to_upper()
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(120, 0)
		btn.pressed.connect(_switch_tab.bind(t))
		tab_bar.add_child(btn)
		_tab_buttons[t] = btn

	for t: String in TABS:
		var panel := HBoxContainer.new()
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.offset_top = 82.0
		panel.offset_bottom = -40.0
		panel.offset_left = 12.0
		panel.offset_right = -12.0
		panel.add_theme_constant_override("separation", 12)
		panel.visible = false
		add_child(panel)
		_tab_panels[t] = panel

	_build_chapters_tab(_tab_panels["chapters"] as HBoxContainer)
	_build_clues_tab(_tab_panels["clues"] as HBoxContainer)
	_build_stamps_tab(_tab_panels["stamps"] as HBoxContainer)

	_status_lbl = Label.new()
	_status_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status_lbl.offset_top = -32.0
	_status_lbl.offset_left = 12.0
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	add_child(_status_lbl)

	_texture_dialog = FileDialog.new()
	_texture_dialog.access = FileDialog.ACCESS_RESOURCES
	_texture_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_texture_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Images"])
	_texture_dialog.current_dir = "res://assets/textures"
	_texture_dialog.size = Vector2(900, 600)
	_texture_dialog.file_selected.connect(func(path: String) -> void:
		if _texture_target != null:
			_texture_target.text = path
			_texture_target.text_changed.emit(path))
	add_child(_texture_dialog)

	_json_dialog = FileDialog.new()
	_json_dialog.access = FileDialog.ACCESS_RESOURCES
	_json_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_json_dialog.filters = PackedStringArray(["*.json ; JSON files"])
	_json_dialog.size = Vector2(900, 600)
	_json_dialog.file_selected.connect(func(path: String) -> void:
		if _json_target != null:
			_json_target.text = path
			_json_target.text_changed.emit(path))
	add_child(_json_dialog)


func _switch_tab(tab: String) -> void:
	_flush_all()
	_tab = tab
	for t: String in TABS:
		(_tab_panels[t] as Control).visible = (t == tab)
		(_tab_buttons[t] as Button).button_pressed = (t == tab)
	match tab:
		"chapters":
			_refresh_chapter_list()
			if _chapter_idx < 0 and not _chapters.is_empty():
				_select_chapter(0)
			elif _chapter_idx >= 0:
				_select_chapter(_chapter_idx)
		"clues":
			MessengerVault.reload()
			_refresh_clue_list()
			if _clue_idx < 0 and not _clues.is_empty():
				_select_clue(0)
			elif _clue_idx >= 0:
				_select_clue(_clue_idx)
		"stamps":
			_refresh_stamp_list()
			if _stamp_idx < 0 and not _stamps.is_empty():
				_select_stamp(0)
			elif _stamp_idx >= 0:
				_select_stamp(_stamp_idx)


# ─────────────────────────────────────────────────────────────
# Small builders
# ─────────────────────────────────────────────────────────────
func _add_btn(parent: Control, text: String, cb: Callable, expand: bool = false) -> Button:
	var btn := Button.new()
	btn.text = text
	if expand:
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(cb)
	parent.add_child(btn)
	return btn


func _section_label(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
	parent.add_child(lbl)


func _labeled_line_edit(parent: Control, label: String, label_w: float = 200.0) -> LineEdit:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label + ":"
	lbl.custom_minimum_size = Vector2(label_w, 0)
	row.add_child(lbl)
	var le := LineEdit.new()
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	row.add_child(le)
	return le


## Two line edits (EN / TH) on one labeled row; returns [en_edit, th_edit].
func _loc_pair(parent: Control, label: String, label_w: float = 200.0) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label + ":"
	lbl.custom_minimum_size = Vector2(label_w, 0)
	row.add_child(lbl)
	var en := LineEdit.new()
	en.placeholder_text = "EN"
	en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	en.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	row.add_child(en)
	var th := LineEdit.new()
	th.placeholder_text = "TH (optional)"
	th.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	row.add_child(th)
	return [en, th]


func _spin(parent: Control, value: float, min_v: float, max_v: float, width: float = 80.0) -> SpinBox:
	var sb := SpinBox.new()
	sb.min_value = min_v
	sb.max_value = max_v
	sb.step = 1
	sb.value = value
	sb.custom_minimum_size = Vector2(width, 0)
	sb.value_changed.connect(func(_v: float) -> void: _mark_dirty())
	parent.add_child(sb)
	return sb


func _mini_label(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	parent.add_child(lbl)


func _image_picker_row(parent: Control, label: String) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label + ":"
	lbl.custom_minimum_size = Vector2(200, 0)
	row.add_child(lbl)
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(40, 40)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(thumb)
	var le := LineEdit.new()
	le.placeholder_text = "res://…/image.png"
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.text_changed.connect(func(t: String) -> void:
		_mark_dirty()
		_update_thumb(thumb, t))
	row.add_child(le)
	var browse := Button.new()
	browse.text = "Browse…"
	browse.pressed.connect(func() -> void:
		_texture_target = le
		_texture_dialog.popup_centered())
	row.add_child(browse)
	return [le, thumb, row]


func _update_thumb(thumb: TextureRect, path: String) -> void:
	var p := path.strip_edges()
	if not p.is_empty() and ResourceLoader.exists(p):
		thumb.texture = load(p) as Texture2D
	else:
		thumb.texture = null


func _populate_option(opt: OptionButton, items: Array, selected_value: String) -> void:
	opt.clear()
	for i: int in range(items.size()):
		opt.add_item(str(items[i]))
		if str(items[i]) == selected_value:
			opt.select(i)
	if opt.selected < 0 and opt.item_count > 0:
		opt.select(0)


func _option_value(opt: OptionButton) -> String:
	if opt == null or opt.selected < 0:
		return ""
	return opt.get_item_text(opt.selected)


# ─────────────────────────────────────────────────────────────
# CHAPTERS tab
# ─────────────────────────────────────────────────────────────
func _build_chapters_tab(body: HBoxContainer) -> void:
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(260, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)

	_ch_list = ItemList.new()
	_ch_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ch_list.item_selected.connect(func(idx: int) -> void:
		_flush_all()
		_select_chapter(idx))
	left.add_child(_ch_list)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	left.add_child(row1)
	_add_btn(row1, "New", _on_new_chapter, true)
	_add_btn(row1, "Duplicate", _on_duplicate_chapter, true)
	_add_btn(row1, "Delete", _on_delete_chapter, true)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	left.add_child(row2)
	_add_btn(row2, "Copy JSON", _on_copy_chapter_json, true)
	_add_btn(row2, "Paste JSON", _on_paste_chapter_json, true)

	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right_scroll)

	_ch_fields = VBoxContainer.new()
	_ch_fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ch_fields.add_theme_constant_override("separation", 10)
	right_scroll.add_child(_ch_fields)

	_ch_id = _labeled_line_edit(_ch_fields, "Chapter ID")
	var title_pair: Array = _loc_pair(_ch_fields, "Chapter title")
	_ch_title_en = title_pair[0]
	_ch_title_th = title_pair[1]

	_section_label(_ch_fields, "VN SCENES  (campaign scene paths belonging to this chapter)")
	_ch_scenes_vbox = VBoxContainer.new()
	_ch_scenes_vbox.add_theme_constant_override("separation", 4)
	_ch_fields.add_child(_ch_scenes_vbox)
	_add_btn(_ch_fields, "+ Add VN Scene", func() -> void:
		_add_path_row(_ch_scenes_vbox, _ch_scene_rows, "", "res://campaign/scenes")
		_mark_dirty())

	_section_label(_ch_fields, "EXPLORATION GRAPHS  (graph paths belonging to this chapter)")
	_ch_graphs_vbox = VBoxContainer.new()
	_ch_graphs_vbox.add_theme_constant_override("separation", 4)
	_ch_fields.add_child(_ch_graphs_vbox)
	_add_btn(_ch_fields, "+ Add Graph", func() -> void:
		_add_path_row(_ch_graphs_vbox, _ch_graph_rows, "", "res://exploration/graphs")
		_mark_dirty())

	_section_label(_ch_fields,
		"START CLUES  (pre-discovered when player enters this chapter — no toast)")
	_mini_label(_ch_fields,
		"Clues appear in the notebook panels immediately; story add_clue beats still work for later finds.")
	_ch_start_clues_vbox = VBoxContainer.new()
	_ch_start_clues_vbox.add_theme_constant_override("separation", 4)
	_ch_fields.add_child(_ch_start_clues_vbox)
	_add_btn(_ch_fields, "+ Add Start Clue", func() -> void:
		_add_start_clue_row("")
		_mark_dirty())

	_section_label(_ch_fields, "TOPICS  (one verdict map per topic — select to edit)")
	var topic_row := HBoxContainer.new()
	topic_row.add_theme_constant_override("separation", 8)
	_ch_fields.add_child(topic_row)
	_topic_list = ItemList.new()
	_topic_list.custom_minimum_size = Vector2(280, 120)
	_topic_list.item_selected.connect(func(idx: int) -> void:
		_flush_topic()
		_select_topic(idx))
	topic_row.add_child(_topic_list)
	var topic_btns := VBoxContainer.new()
	topic_btns.add_theme_constant_override("separation", 4)
	topic_row.add_child(topic_btns)
	_add_btn(topic_btns, "+ New Topic", _on_new_topic)
	_add_btn(topic_btns, "Delete Topic", _on_delete_topic)
	_add_btn(topic_btns, "Layout Editor", _on_open_layout_editor)
	_mini_label(topic_btns, "WYSIWYG: drag nodes,\nright-drag node→node = edge")

	_topic_fields = VBoxContainer.new()
	_topic_fields.add_theme_constant_override("separation", 8)
	_ch_fields.add_child(_topic_fields)

	_topic_id = _labeled_line_edit(_topic_fields, "Topic ID")
	var tt_pair: Array = _loc_pair(_topic_fields, "Topic title")
	_topic_title_en = tt_pair[0]
	_topic_title_th = tt_pair[1]

	_section_label(_topic_fields, "VERDICT MAP — NODES  (drop frames; min level 1-%d reveals on upgrade)"
		% DetectiveNoteVault.MAX_LEVEL)
	_mini_label(_topic_fields,
		"Each node writes exploration var + flag 'note_<topic>_<node>' = placed clue id; label side = frame title placement.")
	_node_vbox = VBoxContainer.new()
	_node_vbox.add_theme_constant_override("separation", 6)
	_topic_fields.add_child(_node_vbox)
	_add_btn(_topic_fields, "+ Add Node", func() -> void:
		_add_node_row({})
		_mark_dirty()
		_refresh_edge_node_options())

	_section_label(_topic_fields, "VERDICT MAP — EDGES  (marker lines between nodes, optional arrowhead)")
	_edge_vbox = VBoxContainer.new()
	_edge_vbox.add_theme_constant_override("separation", 6)
	_topic_fields.add_child(_edge_vbox)
	_add_btn(_topic_fields, "+ Add Edge", func() -> void:
		_add_edge_row({})
		_mark_dirty())


func _add_path_row(vbox: VBoxContainer, rows: Array, path: String, browse_dir: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	vbox.add_child(row)
	var le := LineEdit.new()
	le.text = path
	le.placeholder_text = "res://…"
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	row.add_child(le)
	var browse := Button.new()
	browse.text = "Browse…"
	browse.pressed.connect(func() -> void:
		_json_target = le
		_json_dialog.current_dir = browse_dir
		_json_dialog.popup_centered())
	row.add_child(browse)
	var remove := Button.new()
	remove.text = "✕"
	remove.pressed.connect(func() -> void:
		for i: int in range(rows.size()):
			if (rows[i] as Dictionary).get("row") == row:
				rows.remove_at(i)
				break
		row.queue_free()
		_mark_dirty())
	row.add_child(remove)
	rows.append({"row": row, "path": le})


func _collect_path_rows(rows: Array) -> Array:
	var out: Array = []
	for r: Dictionary in rows:
		var p: String = (r["path"] as LineEdit).text.strip_edges()
		if not p.is_empty():
			out.append(p)
	return out


func _clear_rows(rows: Array, key: String) -> void:
	for r: Dictionary in rows:
		(r[key] as Control).queue_free()
	rows.clear()


# ── Node rows ──
func _add_node_row(nd: Dictionary) -> void:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8.0)
	panel.add_theme_stylebox_override("panel", sb)
	_node_vbox.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)

	var line1 := HBoxContainer.new()
	line1.add_theme_constant_override("separation", 6)
	col.add_child(line1)
	_mini_label(line1, "id")
	var id_le := LineEdit.new()
	id_le.text = str(nd.get("id", ""))
	id_le.placeholder_text = "node_id"
	id_le.custom_minimum_size = Vector2(140, 0)
	id_le.text_changed.connect(func(_t: String) -> void:
		_mark_dirty()
		_refresh_edge_node_options())
	line1.add_child(id_le)
	_mini_label(line1, "kind")
	var kind_opt := OptionButton.new()
	_populate_option(kind_opt, NODE_KINDS, str(nd.get("kind", "any")))
	kind_opt.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	line1.add_child(kind_opt)
	_mini_label(line1, "lvl")
	var lvl_sb := _spin(line1, float(nd.get("min_level", 1)), 1, DetectiveNoteVault.MAX_LEVEL, 60)
	var pos: Array = nd.get("pos", [0, 0]) if nd.get("pos", null) is Array else [0, 0]
	_mini_label(line1, "pos")
	var px_sb := _spin(line1, float(pos[0]) if pos.size() > 0 else 0.0, -8192, 8192)
	var py_sb := _spin(line1, float(pos[1]) if pos.size() > 1 else 0.0, -8192, 8192)
	var def_w: float = DetectiveNoteVault.DEFAULT_NODE_SIZE.x
	var def_h: float = DetectiveNoteVault.DEFAULT_NODE_SIZE.y
	var size_arr: Array = nd.get("size", [def_w, def_h]) if nd.get("size", null) is Array else [def_w, def_h]
	_mini_label(line1, "size")
	var w_sb := _spin(line1, float(size_arr[0]) if size_arr.size() > 0 else def_w, 20, 2048)
	var h_sb := _spin(line1, float(size_arr[1]) if size_arr.size() > 1 else def_h, 20, 2048)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line1.add_child(spacer)
	var remove := Button.new()
	remove.text = "✕"
	line1.add_child(remove)

	var line2 := HBoxContainer.new()
	line2.add_theme_constant_override("separation", 6)
	col.add_child(line2)
	_mini_label(line2, "label EN")
	var lbl_en := LineEdit.new()
	lbl_en.text = _loc_get(nd.get("label", ""), "en")
	lbl_en.placeholder_text = "Individual #1"
	lbl_en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_en.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	line2.add_child(lbl_en)
	_mini_label(line2, "TH")
	var lbl_th := LineEdit.new()
	lbl_th.text = _loc_get(nd.get("label", ""), "th")
	lbl_th.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_th.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	line2.add_child(lbl_th)
	_mini_label(line2, "side")
	var side_opt := OptionButton.new()
	_populate_option(side_opt, NODE_LABEL_SIDES, DetectiveNoteVault.node_label_side(nd))
	side_opt.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	line2.add_child(side_opt)

	var line3 := HBoxContainer.new()
	line3.add_theme_constant_override("separation", 6)
	col.add_child(line3)
	_mini_label(line3, "prefill clue")
	var prefill_opt := OptionButton.new()
	prefill_opt.custom_minimum_size = Vector2(220, 0)
	var clue_ids: Array = ["(none)"]
	clue_ids.append_array(_clue_id_list())
	var want_prefill: String = str(nd.get("prefill", "")).strip_edges()
	_populate_option(prefill_opt, clue_ids, want_prefill if not want_prefill.is_empty() else "(none)")
	prefill_opt.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	line3.add_child(prefill_opt)
	_mini_label(line3, "var_key override")
	var var_le := LineEdit.new()
	var_le.text = str(nd.get("var_key", ""))
	var_le.placeholder_text = "auto: note_<topic>_<node>"
	var_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var_le.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	line3.add_child(var_le)

	var row_entry: Dictionary = {
		"panel": panel, "id": id_le, "kind": kind_opt, "min_level": lvl_sb,
		"px": px_sb, "py": py_sb, "w": w_sb, "h": h_sb,
		"label_en": lbl_en, "label_th": lbl_th, "label_side": side_opt,
		"prefill": prefill_opt, "var_key": var_le,
	}
	remove.pressed.connect(func() -> void:
		for i: int in range(_node_rows.size()):
			if (_node_rows[i] as Dictionary).get("panel") == panel:
				_node_rows.remove_at(i)
				break
		panel.queue_free()
		_mark_dirty()
		_refresh_edge_node_options())
	_node_rows.append(row_entry)


func _node_id_list() -> Array:
	var out: Array = []
	for r: Dictionary in _node_rows:
		var n: String = (r["id"] as LineEdit).text.strip_edges()
		if not n.is_empty():
			out.append(n)
	return out


func _add_start_clue_row(clue_id: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_ch_start_clues_vbox.add_child(row)
	var clue_opt := OptionButton.new()
	clue_opt.custom_minimum_size = Vector2(280, 0)
	clue_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ids: Array = _clue_id_list()
	if ids.is_empty():
		ids.append("(no clues in vault)")
	var want: String = clue_id.strip_edges()
	_populate_option(clue_opt, ids, want if not want.is_empty() and ids.has(want) else ids[0])
	clue_opt.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	row.add_child(clue_opt)
	var remove := Button.new()
	remove.text = "✕"
	remove.pressed.connect(func() -> void:
		for i: int in range(_ch_start_clue_rows.size()):
			if (_ch_start_clue_rows[i] as Dictionary).get("row") == row:
				_ch_start_clue_rows.remove_at(i)
				break
		row.queue_free()
		_mark_dirty())
	row.add_child(remove)
	_ch_start_clue_rows.append({"row": row, "clue": clue_opt})


func _collect_start_clue_rows() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for r: Dictionary in _ch_start_clue_rows:
		var cid: String = _option_value(r["clue"] as OptionButton)
		if cid.is_empty() or cid == "(no clues in vault)" or seen.has(cid):
			continue
		seen[cid] = true
		out.append(cid)
	return out


func _clue_id_list() -> Array:
	var out: Array = []
	for c: Variant in _clues:
		if c is Dictionary:
			var cid: String = str((c as Dictionary).get("id", "")).strip_edges()
			if not cid.is_empty():
				out.append(cid)
	return out


func _refresh_edge_node_options() -> void:
	var ids: Array = _node_id_list()
	for r: Dictionary in _edge_rows:
		var from_opt: OptionButton = r["from"] as OptionButton
		var to_opt: OptionButton = r["to"] as OptionButton
		_populate_option(from_opt, ids, _option_value(from_opt))
		_populate_option(to_opt, ids, _option_value(to_opt))


# ── Edge rows ──
func _add_edge_row(ed: Dictionary) -> void:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.14, 0.12)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8.0)
	panel.add_theme_stylebox_override("panel", sb)
	_edge_vbox.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)

	var line1 := HBoxContainer.new()
	line1.add_theme_constant_override("separation", 6)
	col.add_child(line1)
	_mini_label(line1, "from")
	var from_opt := OptionButton.new()
	from_opt.custom_minimum_size = Vector2(150, 0)
	_populate_option(from_opt, _node_id_list(), str(ed.get("from", "")))
	from_opt.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	line1.add_child(from_opt)
	_mini_label(line1, "to")
	var to_opt := OptionButton.new()
	to_opt.custom_minimum_size = Vector2(150, 0)
	_populate_option(to_opt, _node_id_list(), str(ed.get("to", "")))
	to_opt.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	line1.add_child(to_opt)
	_mini_label(line1, "arrow")
	var arrow_opt := OptionButton.new()
	_populate_option(arrow_opt, ARROWS, str(ed.get("arrow", "none")))
	arrow_opt.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	line1.add_child(arrow_opt)
	_mini_label(line1, "lvl")
	var lvl_sb := _spin(line1, float(ed.get("min_level", 1)), 1, DetectiveNoteVault.MAX_LEVEL, 60)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line1.add_child(spacer)
	var remove := Button.new()
	remove.text = "✕"
	line1.add_child(remove)

	var line2 := HBoxContainer.new()
	line2.add_theme_constant_override("separation", 6)
	col.add_child(line2)
	_mini_label(line2, "label EN")
	var lbl_en := LineEdit.new()
	lbl_en.text = _loc_get(ed.get("label", ""), "en")
	lbl_en.placeholder_text = "Owned / Killed / Caused…"
	lbl_en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_en.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	line2.add_child(lbl_en)
	_mini_label(line2, "TH")
	var lbl_th := LineEdit.new()
	lbl_th.text = _loc_get(ed.get("label", ""), "th")
	lbl_th.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_th.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	line2.add_child(lbl_th)

	remove.pressed.connect(func() -> void:
		for i: int in range(_edge_rows.size()):
			if (_edge_rows[i] as Dictionary).get("panel") == panel:
				_edge_rows.remove_at(i)
				break
		panel.queue_free()
		_mark_dirty())
	_edge_rows.append({
		"panel": panel, "from": from_opt, "to": to_opt,
		"arrow": arrow_opt, "min_level": lvl_sb,
		"label_en": lbl_en, "label_th": lbl_th,
	})


# ── Chapter list / selection ──
func _refresh_chapter_list() -> void:
	_ch_list.clear()
	for c: Variant in _chapters:
		var cd: Dictionary = c as Dictionary if c is Dictionary else {}
		var cid: String = str(cd.get("id", "?"))
		var title: String = DetectiveNoteVault.loc_text(cd.get("title", ""))
		_ch_list.add_item("%s  —  %s" % [cid, title] if not title.is_empty() else cid)


func _select_chapter(idx: int) -> void:
	if idx < 0 or idx >= _chapters.size():
		_chapter_idx = -1
		return
	_chapter_idx = idx
	_ch_list.select(idx)
	_populate_chapter_fields(_chapters[idx] as Dictionary)


func _populate_chapter_fields(ch: Dictionary) -> void:
	_loading = true
	_ch_id.text = str(ch.get("id", ""))
	_ch_title_en.text = _loc_get(ch.get("title", ""), "en")
	_ch_title_th.text = _loc_get(ch.get("title", ""), "th")

	_clear_rows(_ch_scene_rows, "row")
	var scenes: Variant = ch.get("vn_scenes", [])
	if scenes is Array:
		for s: Variant in (scenes as Array):
			_add_path_row(_ch_scenes_vbox, _ch_scene_rows, str(s), "res://campaign/scenes")

	_clear_rows(_ch_graph_rows, "row")
	var graphs: Variant = ch.get("graphs", [])
	if graphs is Array:
		for g: Variant in (graphs as Array):
			_add_path_row(_ch_graphs_vbox, _ch_graph_rows, str(g), "res://exploration/graphs")

	_clear_rows(_ch_start_clue_rows, "row")
	var start_clues: Variant = ch.get("start_clues", [])
	if start_clues is Array:
		for sc: Variant in (start_clues as Array):
			_add_start_clue_row(str(sc))

	_refresh_topic_list(ch)
	_topic_idx = -1
	var topics: Variant = ch.get("topics", [])
	if topics is Array and not (topics as Array).is_empty():
		_select_topic(0)
	else:
		_populate_topic_fields({})
	_loading = false


func _refresh_topic_list(ch: Dictionary) -> void:
	_topic_list.clear()
	var topics: Variant = ch.get("topics", [])
	if not topics is Array:
		return
	for t: Variant in (topics as Array):
		var td: Dictionary = t as Dictionary if t is Dictionary else {}
		var tid: String = str(td.get("id", "?"))
		var title: String = DetectiveNoteVault.loc_text(td.get("title", ""))
		_topic_list.add_item("%s  —  %s" % [tid, title] if not title.is_empty() else tid)


func _select_topic(idx: int) -> void:
	if _chapter_idx < 0:
		return
	var topics: Variant = (_chapters[_chapter_idx] as Dictionary).get("topics", [])
	if not topics is Array or idx < 0 or idx >= (topics as Array).size():
		_topic_idx = -1
		return
	_topic_idx = idx
	_topic_list.select(idx)
	var was_loading := _loading
	_loading = true
	_populate_topic_fields((topics as Array)[idx] as Dictionary)
	_loading = was_loading


func _populate_topic_fields(topic: Dictionary) -> void:
	_topic_fields.visible = not topic.is_empty()
	_topic_id.text = str(topic.get("id", ""))
	_topic_title_en.text = _loc_get(topic.get("title", ""), "en")
	_topic_title_th.text = _loc_get(topic.get("title", ""), "th")
	_clear_rows(_node_rows, "panel")
	var nodes: Variant = topic.get("nodes", [])
	if nodes is Array:
		for n: Variant in (nodes as Array):
			if n is Dictionary:
				_add_node_row(n as Dictionary)
	_clear_rows(_edge_rows, "panel")
	var edges: Variant = topic.get("edges", [])
	if edges is Array:
		for e: Variant in (edges as Array):
			if e is Dictionary:
				_add_edge_row(e as Dictionary)
	_refresh_edge_node_options()


func _collect_topic() -> Dictionary:
	var nodes: Array = []
	for r: Dictionary in _node_rows:
		var nid: String = (r["id"] as LineEdit).text.strip_edges()
		if nid.is_empty():
			continue
		var prefill: String = _option_value(r["prefill"] as OptionButton)
		nodes.append({
			"id": nid,
			"label": _loc_make((r["label_en"] as LineEdit).text, (r["label_th"] as LineEdit).text),
			"label_side": _option_value(r["label_side"] as OptionButton),
			"pos": [int((r["px"] as SpinBox).value), int((r["py"] as SpinBox).value)],
			"size": [int((r["w"] as SpinBox).value), int((r["h"] as SpinBox).value)],
			"kind": _option_value(r["kind"] as OptionButton),
			"min_level": int((r["min_level"] as SpinBox).value),
			"prefill": "" if prefill == "(none)" else prefill,
			"var_key": (r["var_key"] as LineEdit).text.strip_edges(),
		})
	var edges: Array = []
	for r: Dictionary in _edge_rows:
		var from_id: String = _option_value(r["from"] as OptionButton)
		var to_id: String = _option_value(r["to"] as OptionButton)
		if from_id.is_empty() or to_id.is_empty():
			continue
		edges.append({
			"from": from_id,
			"to": to_id,
			"label": _loc_make((r["label_en"] as LineEdit).text, (r["label_th"] as LineEdit).text),
			"arrow": _option_value(r["arrow"] as OptionButton),
			"min_level": int((r["min_level"] as SpinBox).value),
		})
	return {
		"id": _topic_id.text.strip_edges(),
		"title": _loc_make(_topic_title_en.text, _topic_title_th.text),
		"nodes": nodes,
		"edges": edges,
	}


func _flush_topic() -> void:
	if _chapter_idx < 0 or _topic_idx < 0:
		return
	var ch: Dictionary = _chapters[_chapter_idx] as Dictionary
	var topics: Variant = ch.get("topics", [])
	if not topics is Array or _topic_idx >= (topics as Array).size():
		return
	(topics as Array)[_topic_idx] = _collect_topic()
	_refresh_topic_list(ch)
	_topic_list.select(_topic_idx)


func _flush_chapter() -> void:
	if _chapter_idx < 0 or _chapter_idx >= _chapters.size():
		return
	_flush_topic()
	var prev: Dictionary = _chapters[_chapter_idx] as Dictionary
	_chapters[_chapter_idx] = {
		"id": _ch_id.text.strip_edges(),
		"title": _loc_make(_ch_title_en.text, _ch_title_th.text),
		"vn_scenes": _collect_path_rows(_ch_scene_rows),
		"graphs": _collect_path_rows(_ch_graph_rows),
		"start_clues": _collect_start_clue_rows(),
		"topics": prev.get("topics", []),
	}
	_refresh_chapter_list()
	_ch_list.select(_chapter_idx)


func _on_new_chapter() -> void:
	_flush_all()
	_chapters.append({
		"id": _unique_id(_chapters, "new_chapter"),
		"title": "New Chapter",
		"vn_scenes": [],
		"graphs": [],
		"start_clues": [],
		"topics": [],
	})
	_dirty = true
	_refresh_chapter_list()
	_select_chapter(_chapters.size() - 1)


func _on_duplicate_chapter() -> void:
	if _chapter_idx < 0:
		_set_status("Select a chapter to duplicate.")
		return
	_flush_all()
	var copy: Dictionary = (_chapters[_chapter_idx] as Dictionary).duplicate(true)
	copy["id"] = _unique_id(_chapters, str(copy.get("id", "chapter")) + "_copy")
	_chapters.append(copy)
	_dirty = true
	_refresh_chapter_list()
	_select_chapter(_chapters.size() - 1)


func _on_delete_chapter() -> void:
	if _chapter_idx < 0:
		_set_status("Select a chapter to delete.")
		return
	var cid: String = str((_chapters[_chapter_idx] as Dictionary).get("id", "?"))
	GameDialog.confirmation_overlay(
		self, "Delete Chapter",
		"Remove chapter '%s' and all its topics? (Takes effect on Save.)" % cid,
		"Delete", "Cancel",
		func() -> void:
			_chapters.remove_at(_chapter_idx)
			_chapter_idx = -1
			_topic_idx = -1
			_dirty = true
			_refresh_chapter_list()
			if not _chapters.is_empty():
				_select_chapter(0)
			_set_status("Deleted '%s' — remember to Save." % cid))


func _on_copy_chapter_json() -> void:
	if _chapter_idx < 0:
		_set_status("Select a chapter to copy.")
		return
	_flush_all()
	DisplayServer.clipboard_set(JSON.stringify(_chapters[_chapter_idx], "\t"))
	_set_status("Chapter JSON copied to clipboard.")


func _on_paste_chapter_json() -> void:
	var parsed: Variant = JSON.parse_string(DisplayServer.clipboard_get())
	if not parsed is Dictionary or not (parsed as Dictionary).has("topics"):
		_set_status("Clipboard does not contain valid chapter JSON.")
		return
	_flush_all()
	var ch: Dictionary = parsed as Dictionary
	ch["id"] = _unique_id(_chapters, str(ch.get("id", "pasted_chapter")))
	_chapters.append(ch)
	_dirty = true
	_refresh_chapter_list()
	_select_chapter(_chapters.size() - 1)
	_set_status("Chapter pasted from clipboard.")


func _on_new_topic() -> void:
	if _chapter_idx < 0:
		_set_status("Select a chapter first.")
		return
	_flush_topic()
	var ch: Dictionary = _chapters[_chapter_idx] as Dictionary
	if not ch.get("topics", null) is Array:
		ch["topics"] = []
	var topics: Array = ch["topics"] as Array
	topics.append({
		"id": _unique_id(topics, "new_topic"),
		"title": "New Topic",
		"nodes": [],
		"edges": [],
	})
	_dirty = true
	_refresh_topic_list(ch)
	_select_topic(topics.size() - 1)


func _on_delete_topic() -> void:
	if _chapter_idx < 0 or _topic_idx < 0:
		_set_status("Select a topic to delete.")
		return
	var ch: Dictionary = _chapters[_chapter_idx] as Dictionary
	var topics: Array = ch.get("topics", []) as Array
	var tid: String = str((topics[_topic_idx] as Dictionary).get("id", "?"))
	GameDialog.confirmation_overlay(
		self, "Delete Topic",
		"Remove topic '%s' and its verdict map? (Takes effect on Save.)" % tid,
		"Delete", "Cancel",
		func() -> void:
			topics.remove_at(_topic_idx)
			_topic_idx = -1
			_dirty = true
			_refresh_topic_list(ch)
			if not topics.is_empty():
				_select_topic(0)
			else:
				_populate_topic_fields({})
			_set_status("Deleted topic '%s' — remember to Save." % tid))


# ─────────────────────────────────────────────────────────────
# WYSIWYG layout editor
# Renders the verdict map with the exact player-facing renderer
# (DetectiveNoteVerdictMap in EDIT mode). Left-drag moves a node and writes
# the position back into its form row; right-drag from one node to another
# creates an edge (arrow "end") and adds its form row.
# ─────────────────────────────────────────────────────────────
var _layout_overlay: Control = null
var _layout_map: DetectiveNoteVerdictMap = null
var _layout_level: int = 0


func _on_open_layout_editor() -> void:
	if _chapter_idx < 0 or _topic_idx < 0:
		_set_status("Select a topic first.")
		return
	_flush_topic()
	var topic: Dictionary = _collect_topic()
	if (topic.get("nodes", []) as Array).is_empty():
		_set_status("Add at least one node before opening the layout editor.")
		return
	var max_level: int = DetectiveNoteVault.topic_max_level(topic)
	if _layout_level < 1 or _layout_level > max_level:
		_layout_level = max_level

	_layout_overlay = Control.new()
	_layout_overlay.name = "DetectiveNoteLayoutEditor"
	_layout_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout_overlay.z_index = 250
	_layout_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_layout_overlay)

	var paper := ColorRect.new()
	paper.color = Color(0.93, 0.89, 0.80)
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout_overlay.add_child(paper)
	var notepaper_path: String = "res://assets/textures/detective/ui_detective_notepaper_repeat.png"
	if ResourceLoader.exists(notepaper_path):
		var tile := TextureRect.new()
		tile.texture = load(notepaper_path) as Texture2D
		tile.stretch_mode = TextureRect.STRETCH_TILE
		tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layout_overlay.add_child(tile)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 48.0
	# Match the player notebook: vertical scrolling only, so authors see the
	# same horizontal bounds players get.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_layout_overlay.add_child(scroll)

	_layout_map = DetectiveNoteVerdictMap.new()
	_layout_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_layout_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_layout_map.setup(topic, _layout_level, DetectiveNoteVerdictMap.Mode.EDIT)
	_layout_map.edit_node_moved.connect(_on_layout_node_moved)
	_layout_map.edit_edge_created.connect(_on_layout_edge_created)
	scroll.add_child(_layout_map)

	var bar := HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 44.0
	bar.add_theme_constant_override("separation", 12)
	_layout_overlay.add_child(bar)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.05, 0.05, 0.10, 0.92)
	bar_bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar_bg.offset_bottom = 44.0
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_overlay.add_child(bar_bg)
	_layout_overlay.move_child(bar_bg, bar.get_index())

	var info := Label.new()
	info.text = "  LAYOUT EDITOR — drag node = move   |   right-drag node → node = new edge   |   labels/levels in the form"
	bar.add_child(info)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	var lvl_lbl := Label.new()
	lvl_lbl.text = "View level:"
	bar.add_child(lvl_lbl)
	var lvl_opt := OptionButton.new()
	for lvl: int in range(1, max_level + 1):
		lvl_opt.add_item("Level %d" % lvl)
	lvl_opt.select(_layout_level - 1)
	lvl_opt.item_selected.connect(func(i: int) -> void:
		_layout_level = i + 1
		_layout_map.setup(_layout_map.get_topic(), _layout_level,
			DetectiveNoteVerdictMap.Mode.EDIT))
	bar.add_child(lvl_opt)
	var done := Button.new()
	done.text = "Done"
	done.pressed.connect(_close_layout_editor)
	bar.add_child(done)


func _close_layout_editor() -> void:
	if _layout_overlay != null and is_instance_valid(_layout_overlay):
		_layout_overlay.queue_free()
	_layout_overlay = null
	_layout_map = null


func _on_layout_node_moved(node_id: String, new_pos: Vector2) -> void:
	for r: Dictionary in _node_rows:
		if (r["id"] as LineEdit).text.strip_edges() == node_id:
			(r["px"] as SpinBox).value = round(new_pos.x)
			(r["py"] as SpinBox).value = round(new_pos.y)
			break
	_dirty = true
	_set_status("Node '%s' moved to (%d, %d) — remember to Save." %
		[node_id, int(round(new_pos.x)), int(round(new_pos.y))])


func _on_layout_edge_created(from_id: String, to_id: String) -> void:
	# Skip exact duplicates (same direction).
	for r: Dictionary in _edge_rows:
		if _option_value(r["from"] as OptionButton) == from_id \
				and _option_value(r["to"] as OptionButton) == to_id:
			_set_status("Edge %s → %s already exists." % [from_id, to_id])
			return
	var edge: Dictionary = {
		"from": from_id, "to": to_id, "label": "",
		"arrow": "end", "min_level": _layout_level,
	}
	_add_edge_row(edge)
	_refresh_edge_node_options()
	if _layout_map != null and is_instance_valid(_layout_map):
		_layout_map.add_edge(edge)
	_dirty = true
	_set_status("Edge %s → %s created (label/arrow editable in the form)." % [from_id, to_id])


# ─────────────────────────────────────────────────────────────
# CLUES tab
# ─────────────────────────────────────────────────────────────
func _build_clues_tab(body: HBoxContainer) -> void:
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(260, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)

	_clue_list = ItemList.new()
	_clue_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_clue_list.item_selected.connect(func(idx: int) -> void:
		_flush_all()
		_select_clue(idx))
	left.add_child(_clue_list)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	left.add_child(row1)
	_add_btn(row1, "New", _on_new_clue, true)
	_add_btn(row1, "Duplicate", _on_duplicate_clue, true)
	_add_btn(row1, "Delete", _on_delete_clue, true)

	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right_scroll)

	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("separation", 10)
	right_scroll.add_child(fields)

	_clue_id = _labeled_line_edit(fields, "Clue ID")
	var kind_row := HBoxContainer.new()
	kind_row.add_theme_constant_override("separation", 8)
	fields.add_child(kind_row)
	var kind_lbl := Label.new()
	kind_lbl.text = "Kind:"
	kind_lbl.custom_minimum_size = Vector2(200, 0)
	kind_row.add_child(kind_lbl)
	_clue_kind_opt = OptionButton.new()
	_populate_option(_clue_kind_opt, CLUE_KINDS, "individual")
	_clue_kind_opt.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	kind_row.add_child(_clue_kind_opt)
	var style_lbl := Label.new()
	style_lbl.text = "Style:"
	kind_row.add_child(style_lbl)
	_clue_style_opt = OptionButton.new()
	_populate_option(_clue_style_opt, CLUE_STYLES, "image")
	_clue_style_opt.item_selected.connect(func(_i: int) -> void:
		_sync_clue_style_fields()
		_mark_dirty())
	kind_row.add_child(_clue_style_opt)
	_mini_label(kind_row, "(postit = note; messenger = Messenger Vault chat)")

	var conv_row := HBoxContainer.new()
	conv_row.add_theme_constant_override("separation", 8)
	fields.add_child(conv_row)
	_clue_conversation_row = conv_row
	var conv_lbl := Label.new()
	conv_lbl.text = "Messenger conversation:"
	conv_lbl.custom_minimum_size = Vector2(200, 0)
	conv_row.add_child(conv_lbl)
	_clue_conversation_opt = OptionButton.new()
	_clue_conversation_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MessengerVault.populate_conversation_option(_clue_conversation_opt)
	_clue_conversation_opt.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	conv_row.add_child(_clue_conversation_opt)

	var name_pair: Array = _loc_pair(fields, "Name")
	_clue_name_en = name_pair[0]
	_clue_name_th = name_pair[1]
	var caption_pair: Array = _loc_pair(fields, "Caption (short)")
	_clue_caption_en = caption_pair[0]
	_clue_caption_th = caption_pair[1]

	_section_label(fields, "FULL INFO  (image/postit: hover-hold detail; messenger: optional subtitle)")
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 8)
	fields.add_child(info_row)
	_clue_info_en = TextEdit.new()
	_clue_info_en.placeholder_text = "EN"
	_clue_info_en.custom_minimum_size = Vector2(0, 110)
	_clue_info_en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clue_info_en.text_changed.connect(_mark_dirty)
	info_row.add_child(_clue_info_en)
	_clue_info_th = TextEdit.new()
	_clue_info_th.placeholder_text = "TH (optional)"
	_clue_info_th.custom_minimum_size = Vector2(0, 110)
	_clue_info_th.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clue_info_th.text_changed.connect(_mark_dirty)
	info_row.add_child(_clue_info_th)

	var img: Array = _image_picker_row(fields, "Image")
	_clue_image = img[0]
	_clue_thumb = img[1]
	_clue_image_row = img[2] as HBoxContainer
	_sync_clue_style_fields()


func _sync_clue_style_fields() -> void:
	if _clue_style_opt == null:
		return
	var style: String = _option_value(_clue_style_opt)
	if _clue_conversation_row != null:
		_clue_conversation_row.visible = style == "messenger"
	if _clue_image_row != null:
		_clue_image_row.visible = style == "image"


func _refresh_clue_list() -> void:
	_clue_list.clear()
	for c: Variant in _clues:
		var cd: Dictionary = c as Dictionary if c is Dictionary else {}
		var cid: String = str(cd.get("id", "?"))
		var kind: String = str(cd.get("kind", "?"))
		var style: String = str(cd.get("style", "image"))
		var cname: String = DetectiveNoteVault.clue_display_name(cd)
		var style_tag: String = " [%s]" % style if style != "image" else ""
		_clue_list.add_item("[%s%s] %s  —  %s" % [kind, style_tag, cid, cname])


func _select_clue(idx: int) -> void:
	if idx < 0 or idx >= _clues.size():
		_clue_idx = -1
		return
	_clue_idx = idx
	_clue_list.select(idx)
	var cd: Dictionary = _clues[idx] as Dictionary
	_loading = true
	_clue_id.text = str(cd.get("id", ""))
	_populate_option(_clue_kind_opt, CLUE_KINDS, str(cd.get("kind", "individual")))
	_populate_option(_clue_style_opt, CLUE_STYLES, str(cd.get("style", "image")))
	_clue_name_en.text = _loc_get(cd.get("name", ""), "en")
	_clue_name_th.text = _loc_get(cd.get("name", ""), "th")
	_clue_caption_en.text = _loc_get(cd.get("caption", ""), "en")
	_clue_caption_th.text = _loc_get(cd.get("caption", ""), "th")
	_clue_info_en.text = _loc_get(cd.get("info", ""), "en")
	_clue_info_th.text = _loc_get(cd.get("info", ""), "th")
	_clue_image.text = str(cd.get("image", ""))
	_update_thumb(_clue_thumb, _clue_image.text)
	MessengerVault.populate_conversation_option(_clue_conversation_opt)
	MessengerVault.select_conversation_option(
		_clue_conversation_opt, str(cd.get("conversation", "")).strip_edges())
	_sync_clue_style_fields()
	_loading = false


func _flush_clue() -> void:
	if _clue_idx < 0 or _clue_idx >= _clues.size():
		return
	var style: String = _option_value(_clue_style_opt)
	var entry: Dictionary = {
		"id": _clue_id.text.strip_edges(),
		"kind": _option_value(_clue_kind_opt),
		"name": _loc_make(_clue_name_en.text, _clue_name_th.text),
		"caption": _loc_make(_clue_caption_en.text, _clue_caption_th.text),
		"info": _loc_make(_clue_info_en.text, _clue_info_th.text),
		"style": style,
	}
	match style:
		"messenger":
			entry["conversation"] = MessengerVault.option_conversation_id(_clue_conversation_opt)
			entry["image"] = ""
		"postit":
			entry["image"] = ""
		_:
			entry["image"] = _clue_image.text.strip_edges()
	_clues[_clue_idx] = entry
	_refresh_clue_list()
	_clue_list.select(_clue_idx)


func _on_new_clue() -> void:
	_flush_all()
	_clues.append({
		"id": _unique_id(_clues, "new_clue"),
		"kind": "information",
		"name": "New Clue",
		"caption": "",
		"info": "",
		"image": "",
		"style": "postit",
	})
	_dirty = true
	_refresh_clue_list()
	_select_clue(_clues.size() - 1)


func _on_duplicate_clue() -> void:
	if _clue_idx < 0:
		_set_status("Select a clue to duplicate.")
		return
	_flush_all()
	var copy: Dictionary = (_clues[_clue_idx] as Dictionary).duplicate(true)
	copy["id"] = _unique_id(_clues, str(copy.get("id", "clue")) + "_copy")
	_clues.append(copy)
	_dirty = true
	_refresh_clue_list()
	_select_clue(_clues.size() - 1)


func _on_delete_clue() -> void:
	if _clue_idx < 0:
		_set_status("Select a clue to delete.")
		return
	var cid: String = str((_clues[_clue_idx] as Dictionary).get("id", "?"))
	GameDialog.confirmation_overlay(
		self, "Delete Clue",
		"Remove clue '%s'? Verdict nodes prefilled with it will break. (Takes effect on Save.)" % cid,
		"Delete", "Cancel",
		func() -> void:
			_clues.remove_at(_clue_idx)
			_clue_idx = -1
			_dirty = true
			_refresh_clue_list()
			if not _clues.is_empty():
				_select_clue(0)
			_set_status("Deleted '%s' — remember to Save." % cid))


# ─────────────────────────────────────────────────────────────
# STAMPS tab
# ─────────────────────────────────────────────────────────────
func _build_stamps_tab(body: HBoxContainer) -> void:
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(260, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)

	_stamp_list = ItemList.new()
	_stamp_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stamp_list.item_selected.connect(func(idx: int) -> void:
		_flush_all()
		_select_stamp(idx))
	left.add_child(_stamp_list)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	left.add_child(row1)
	_add_btn(row1, "New", _on_new_stamp, true)
	_add_btn(row1, "Duplicate", _on_duplicate_stamp, true)
	_add_btn(row1, "Delete", _on_delete_stamp, true)

	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right_scroll)

	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("separation", 10)
	right_scroll.add_child(fields)

	_stamp_id = _labeled_line_edit(fields, "Stamp ID (used by show_note_stamp)")
	var name_pair: Array = _loc_pair(fields, "Approver name")
	_stamp_name_en = name_pair[0]
	_stamp_name_th = name_pair[1]
	_mini_label(fields, "Shown typed letter-by-letter under the red APPROVED text.")
	var img: Array = _image_picker_row(fields, "Stamp logo")
	_stamp_image = img[0]
	_stamp_thumb = img[1]


func _refresh_stamp_list() -> void:
	_stamp_list.clear()
	for s: Variant in _stamps:
		var sd: Dictionary = s as Dictionary if s is Dictionary else {}
		var sid: String = str(sd.get("id", "?"))
		var sname: String = DetectiveNoteVault.loc_text(sd.get("name", ""))
		_stamp_list.add_item("%s  —  %s" % [sid, sname] if not sname.is_empty() else sid)


func _select_stamp(idx: int) -> void:
	if idx < 0 or idx >= _stamps.size():
		_stamp_idx = -1
		return
	_stamp_idx = idx
	_stamp_list.select(idx)
	var sd: Dictionary = _stamps[idx] as Dictionary
	_loading = true
	_stamp_id.text = str(sd.get("id", ""))
	_stamp_name_en.text = _loc_get(sd.get("name", ""), "en")
	_stamp_name_th.text = _loc_get(sd.get("name", ""), "th")
	_stamp_image.text = str(sd.get("image", ""))
	_update_thumb(_stamp_thumb, _stamp_image.text)
	_loading = false


func _flush_stamp() -> void:
	if _stamp_idx < 0 or _stamp_idx >= _stamps.size():
		return
	_stamps[_stamp_idx] = {
		"id": _stamp_id.text.strip_edges(),
		"name": _loc_make(_stamp_name_en.text, _stamp_name_th.text),
		"image": _stamp_image.text.strip_edges(),
	}
	_refresh_stamp_list()
	_stamp_list.select(_stamp_idx)


func _on_new_stamp() -> void:
	_flush_all()
	_stamps.append({
		"id": _unique_id(_stamps, "new_stamp"),
		"name": "Approver Name",
		"image": "",
	})
	_dirty = true
	_refresh_stamp_list()
	_select_stamp(_stamps.size() - 1)


func _on_duplicate_stamp() -> void:
	if _stamp_idx < 0:
		_set_status("Select a stamp to duplicate.")
		return
	_flush_all()
	var copy: Dictionary = (_stamps[_stamp_idx] as Dictionary).duplicate(true)
	copy["id"] = _unique_id(_stamps, str(copy.get("id", "stamp")) + "_copy")
	_stamps.append(copy)
	_dirty = true
	_refresh_stamp_list()
	_select_stamp(_stamps.size() - 1)


func _on_delete_stamp() -> void:
	if _stamp_idx < 0:
		_set_status("Select a stamp to delete.")
		return
	var sid: String = str((_stamps[_stamp_idx] as Dictionary).get("id", "?"))
	GameDialog.confirmation_overlay(
		self, "Delete Stamp",
		"Remove stamp '%s'? (Takes effect on Save.)" % sid,
		"Delete", "Cancel",
		func() -> void:
			_stamps.remove_at(_stamp_idx)
			_stamp_idx = -1
			_dirty = true
			_refresh_stamp_list()
			if not _stamps.is_empty():
				_select_stamp(0)
			_set_status("Deleted '%s' — remember to Save." % sid))


# ─────────────────────────────────────────────────────────────
# Shared actions
# ─────────────────────────────────────────────────────────────
func _mark_dirty() -> void:
	if not _loading:
		_dirty = true


func _set_status(text: String) -> void:
	_status_lbl.text = text


func _unique_id(items: Array, base: String) -> String:
	var ids: Dictionary = {}
	for item: Variant in items:
		if item is Dictionary:
			ids[str((item as Dictionary).get("id", ""))] = true
	if not ids.has(base):
		return base
	var n := 2
	while ids.has("%s_%d" % [base, n]):
		n += 1
	return "%s_%d" % [base, n]


func _flush_all() -> void:
	match _tab:
		"chapters":
			_flush_chapter()
		"clues":
			_flush_clue()
		"stamps":
			_flush_stamp()


func _on_reload() -> void:
	DetectiveNoteVault.reload()
	_chapters = DetectiveNoteVault.get_chapters()
	_clues = DetectiveNoteVault.get_clues()
	_stamps = DetectiveNoteVault.get_stamps()
	_chapter_idx = -1
	_topic_idx = -1
	_clue_idx = -1
	_stamp_idx = -1
	_dirty = false
	_switch_tab(_tab)
	_set_status("Reloaded from disk.")


func _on_save() -> void:
	_flush_all()
	if not BuildConfig.can_write_shipped_data():
		_set_status("Cannot write res://data in exported builds — run from the editor.")
		return
	var problems: Array = _validate()
	if not problems.is_empty():
		_set_status("NOT saved: " + "; ".join(problems))
		return
	if DetectiveNoteVault.save_vault(_chapters, _clues, _stamps):
		_dirty = false
		_set_status("Saved to %s" % DetectiveNoteVault.SAVE_PATH)
	else:
		_set_status("Save FAILED — could not open %s for writing." % DetectiveNoteVault.SAVE_PATH)


func _validate() -> Array:
	var problems: Array = []
	var seen: Dictionary = {}
	for group: Array in [[_chapters, "chapter"], [_clues, "clue"], [_stamps, "stamp"]]:
		var items: Array = group[0]
		var what: String = str(group[1])
		var group_ids: Dictionary = {}
		for item: Variant in items:
			if not item is Dictionary:
				continue
			var iid: String = str((item as Dictionary).get("id", "")).strip_edges()
			if iid.is_empty():
				problems.append("every %s needs a non-empty id" % what)
			elif group_ids.has(iid):
				problems.append("duplicate %s id '%s'" % [what, iid])
			group_ids[iid] = true
	seen.clear()
	var vault_clue_ids: Dictionary = {}
	for c: Variant in _clues:
		if c is Dictionary:
			var cid: String = str((c as Dictionary).get("id", "")).strip_edges()
			if not cid.is_empty():
				vault_clue_ids[cid] = true
	var messenger_ids: Dictionary = {}
	for mid: Variant in MessengerVault.get_all_ids():
		messenger_ids[str(mid)] = true
	for c: Variant in _clues:
		if not c is Dictionary:
			continue
		var cd: Dictionary = c as Dictionary
		var cid: String = str(cd.get("id", "")).strip_edges()
		if cid.is_empty():
			continue
		var style: String = str(cd.get("style", "image")).strip_edges()
		if style == "messenger":
			var conv_id: String = str(cd.get("conversation", "")).strip_edges()
			if conv_id.is_empty():
				problems.append("clue '%s': messenger style needs a conversation id" % cid)
			elif not messenger_ids.has(conv_id):
				problems.append("clue '%s': unknown messenger conversation '%s'" % [cid, conv_id])
	for ch: Variant in _chapters:
		if not ch is Dictionary:
			continue
		var chd: Dictionary = ch as Dictionary
		var ch_id: String = str(chd.get("id", "")).strip_edges()
		var start_clues: Variant = chd.get("start_clues", [])
		if start_clues is Array:
			for sc: Variant in (start_clues as Array):
				var scid: String = str(sc).strip_edges()
				if scid.is_empty():
					continue
				if not vault_clue_ids.has(scid):
					problems.append("chapter '%s': unknown start_clue '%s'" % [ch_id, scid])
		var topics: Variant = chd.get("topics", [])
		if not topics is Array:
			continue
		for t: Variant in (topics as Array):
			if not t is Dictionary:
				continue
			var td: Dictionary = t as Dictionary
			var tid: String = str(td.get("id", "")).strip_edges()
			if tid.is_empty():
				problems.append("every topic needs a non-empty id")
			var node_ids: Dictionary = {}
			var nodes: Variant = td.get("nodes", [])
			if nodes is Array:
				for n: Variant in (nodes as Array):
					if n is Dictionary:
						node_ids[str((n as Dictionary).get("id", ""))] = true
			var edges: Variant = td.get("edges", [])
			if edges is Array:
				for e: Variant in (edges as Array):
					if not e is Dictionary:
						continue
					for key: String in ["from", "to"]:
						var nid: String = str((e as Dictionary).get(key, "")).strip_edges()
						if not nid.is_empty() and not node_ids.has(nid):
							problems.append("topic '%s': edge %s '%s' is not a node" % [tid, key, nid])
	return problems
