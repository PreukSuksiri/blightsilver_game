extends Control
## ExplorationPuzzleManager — editor UI for the global puzzle catalog.
## Puzzle scenes are manually coded; this UI manages metadata only.

const FONT_PATH: String = "res://assets/fonts/Chivo-VariableFont_wght.ttf"

var _list_vbox: VBoxContainer = null
var _edit_panel: Panel        = null
var _ef_id: LineEdit          = null
var _ef_name: LineEdit        = null
var _ef_desc: TextEdit        = null
var _status_lbl: Label        = null
var _scene_lbl: Label         = null
var _editing_id: String       = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 50
	_build_ui()
	_refresh_list()
	set_anchors_and_offsets_preset.call_deferred(Control.PRESET_FULL_RECT)

func _make_font(weight: int) -> FontVariation:
	var base := load(FONT_PATH) as FontFile
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {"wght": weight}
	return fv

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.10, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var toolbar_bg := PanelContainer.new()
	toolbar_bg.custom_minimum_size = Vector2(0, 44)
	var tb_sb := StyleBoxFlat.new()
	tb_sb.bg_color = Color(0.06, 0.08, 0.18, 1.0)
	toolbar_bg.add_theme_stylebox_override("panel", tb_sb)
	root_vbox.add_child(toolbar_bg)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	toolbar_bg.add_child(toolbar)

	var title_lbl := Label.new()
	title_lbl.text = "  Exploration Puzzles"
	title_lbl.add_theme_font_override("font", _make_font(700))
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(title_lbl)

	toolbar.add_child(_make_btn("+ New Puzzle", func() -> void: _start_edit_new()))
	toolbar.add_child(_make_btn("← Back", func() -> void: queue_free()))

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 0)
	root_vbox.add_child(cols)

	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(list_scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 2)
	list_scroll.add_child(_list_vbox)

	_edit_panel = Panel.new()
	_edit_panel.custom_minimum_size = Vector2(480.0, 0.0)
	_edit_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_edit_panel.visible = false
	var ep_sb := StyleBoxFlat.new()
	ep_sb.bg_color = Color(0.06, 0.08, 0.18, 1.0)
	ep_sb.border_width_left = 2
	ep_sb.border_color = Color(0.35, 0.60, 1.0, 0.30)
	_edit_panel.add_theme_stylebox_override("panel", ep_sb)
	cols.add_child(_edit_panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edit_panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.offset_left = 20.0
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	var heading := Label.new()
	heading.text = "Edit Puzzle"
	heading.add_theme_font_override("font", _make_font(700))
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
	vbox.add_child(heading)

	_ef_id = _make_field_row(vbox, "ID", "puzzle_id")
	_ef_name = _make_field_row(vbox, "Name", "Display name")
	vbox.add_child(_make_label("Description"))
	_ef_desc = TextEdit.new()
	_ef_desc.custom_minimum_size = Vector2(0.0, 90.0)
	_ef_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ef_desc.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_ef_desc)

	_status_lbl = Label.new()
	_status_lbl.add_theme_font_size_override("font_size", 14)
	_status_lbl.add_theme_color_override("font_color", Color(0.70, 0.82, 0.90))
	vbox.add_child(_status_lbl)

	_scene_lbl = Label.new()
	_scene_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_scene_lbl.add_theme_font_size_override("font_size", 12)
	_scene_lbl.add_theme_color_override("font_color", Color(0.50, 0.58, 0.65))
	vbox.add_child(_scene_lbl)

	var note := Label.new()
	note.text = "Puzzle scenes are registered in code (ExplorationPuzzleDatabase.SCENE_REGISTRY)."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color(0.45, 0.52, 0.58))
	vbox.add_child(note)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)
	btn_row.add_child(_make_btn("Save Puzzle", func() -> void: _commit_edit()))
	var del_btn := _make_btn("Delete Puzzle", func() -> void: _delete_editing_puzzle())
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.50, 0.45))
	btn_row.add_child(del_btn)
	btn_row.add_child(_make_btn("Cancel", func() -> void: _edit_panel.visible = false))

func _refresh_list() -> void:
	for c: Node in _list_vbox.get_children():
		c.queue_free()

	var puzzles: Array = ExplorationPuzzleDatabase.all_puzzles()
	if puzzles.is_empty():
		var lbl := Label.new()
		lbl.text = "  No puzzles yet. Click '+ New Puzzle'."
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.65))
		_list_vbox.add_child(lbl)
		return

	for entry: Variant in puzzles:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		var pid: String = str(d.get("id", ""))
		var pname: String = str(d.get("name", pid))
		var status: String = ExplorationPuzzleDatabase.get_status_label(pid)
		var row := Button.new()
		row.text = "%s  [%s]  —  %s" % [pname, pid, status]
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.flat = true
		row.add_theme_font_size_override("font_size", 14)
		if status == "Not implemented":
			row.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
		var captured_id: String = pid
		row.pressed.connect(func() -> void: _start_edit_existing(captured_id))
		_list_vbox.add_child(row)

func _start_edit_new() -> void:
	_editing_id = ""
	_ef_id.text = ExplorationPuzzleDatabase.generate_id()
	_ef_id.editable = true
	_ef_name.text = ""
	_ef_desc.text = ""
	_update_status_labels(_ef_id.text)
	_edit_panel.visible = true

func _start_edit_existing(puzzle_id: String) -> void:
	var d: Dictionary = ExplorationPuzzleDatabase.get_puzzle(puzzle_id)
	if d.is_empty():
		return
	_editing_id = puzzle_id
	_ef_id.text = puzzle_id
	_ef_id.editable = false
	_ef_name.text = str(d.get("name", ""))
	_ef_desc.text = str(d.get("description", ""))
	_update_status_labels(puzzle_id)
	_edit_panel.visible = true

func _update_status_labels(puzzle_id: String) -> void:
	var status: String = ExplorationPuzzleDatabase.get_status_label(puzzle_id)
	_status_lbl.text = "Status: %s" % status
	if ExplorationPuzzleDatabase.is_implemented(puzzle_id):
		_status_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.70))
		_scene_lbl.text = "Scene: %s" % ExplorationPuzzleDatabase.get_scene_path(puzzle_id)
	else:
		_status_lbl.add_theme_color_override("font_color", Color(0.90, 0.55, 0.45))
		_scene_lbl.text = "Scene: not implemented"

func _commit_edit() -> void:
	var new_id: String = _ef_id.text.strip_edges()
	if new_id.is_empty():
		return
	ExplorationPuzzleDatabase.upsert_puzzle({
		"id":          new_id,
		"name":        _ef_name.text.strip_edges(),
		"description": _ef_desc.text.strip_edges(),
	})
	_editing_id = new_id
	_ef_id.editable = false
	_update_status_labels(new_id)
	_refresh_list()

func _delete_editing_puzzle() -> void:
	if _editing_id.is_empty():
		_edit_panel.visible = false
		return
	ExplorationPuzzleDatabase.delete_puzzle(_editing_id)
	_editing_id = ""
	_edit_panel.visible = false
	_refresh_list()

func _make_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.90))
	return lbl

func _make_field_row(parent: Control, label_text: String, placeholder: String) -> LineEdit:
	parent.add_child(_make_label(label_text))
	var le := LineEdit.new()
	le.placeholder_text = placeholder
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.add_theme_font_size_override("font_size", 14)
	parent.add_child(le)
	return le

func _make_btn(text: String, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(cb)
	return btn
