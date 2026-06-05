extends Control
## ExplorationEditor — GraphEdit-based designer tool for building Exploration graphs.
##
## Open from the Admin Console command:
##   exploration_editor [path/to/graph.json]
##
## Or load the scene directly:
##   get_tree().change_scene_to_file("res://scenes/exploration_editor.tscn")
##
## Controls:
##   • Click a node to select it and edit its properties in the right panel.
##   • Drag from an output port (right side) to an input port (left side)
##     of another node to create a connection.
##   • Right-click in the graph area to add a new node.
##   • Toolbar buttons: New, Load, Save, Add Node, Validate, Test Play.
##   • Ctrl+S to save, Delete to remove selected node.
##
## Data format: see ExplorationGraph / ExplorationNode for JSON schema.

const FONT_PATH: String = "res://assets/fonts/Chivo-VariableFont_wght.ttf"

# ── Node type colours ─────────────────────────────────────────────────────
const NODE_TYPE_COLORS: Dictionary = {
	"NORMAL":  Color(0.25, 0.40, 0.60),
	"STORY":   Color(0.20, 0.45, 0.75),
	"BATTLE":  Color(0.65, 0.25, 0.25),
	"REWARD":  Color(0.25, 0.55, 0.30),
	"EXIT":    Color(0.55, 0.50, 0.15),
	"HUB":     Color(0.40, 0.25, 0.65),
}

# ── Layout constants ──────────────────────────────────────────────────────
const PROPS_PANEL_W: float  = 380.0
const TOOLBAR_H: float      = 44.0
const GRAPH_NODE_W: float   = 200.0

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────

var _graph: ExplorationGraph = null          ## The graph being edited
var _graph_path: String = ""                 ## Path to the JSON file on disk
var _dirty: bool = false                     ## Unsaved changes exist
var _selected_node_id: String = ""           ## Currently selected ExplorationNode id

## Maps node_id → GraphNode widget
var _gn_map: Dictionary = {}

# ─────────────────────────────────────────────────────────────
# UI references
# ─────────────────────────────────────────────────────────────

var _graph_edit: GraphEdit = null
var _props_panel: Control  = null

# ── Properties panel fields ───────────────────────────────────
var _prop_id_edit:          LineEdit    = null
var _prop_title_edit:       LineEdit    = null
var _prop_desc_edit:        TextEdit    = null
var _prop_type_btn:         OptionButton = null
var _prop_bg_edit:          LineEdit    = null
var _prop_vn_edit:            LineEdit    = null
var _prop_vn_play_once_chk:   CheckBox    = null
var _prop_show_info_chk:      CheckBox    = null
var _prop_show_who_chk:       CheckBox    = null
var _prop_music_edit:       LineEdit    = null
var _prop_connections_vbox: VBoxContainer = null
var _prop_events_in_vbox:   VBoxContainer = null
var _prop_events_out_vbox:  VBoxContainer = null
var _prop_characters_vbox:  VBoxContainer = null
var _prop_spots_vbox:       VBoxContainer = null
var _spot_picker_window:    Window        = null

# ── Status bar ────────────────────────────────────────────────
var _status_lbl: Label = null

# ── Persistent file dialogs ───────────────────────────────────
var _load_dialog: FileDialog = null
var _save_dialog: FileDialog = null

# ── Preview helpers ────────────────────────────────────────────
var _preview_player: AudioStreamPlayer = null
var _img_popup:      PopupPanel        = null
var _img_popup_tex:  TextureRect       = null

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_new_graph()

## Call this to open a specific graph file immediately after the scene loads.
func open_file(path: String) -> void:
	_load_graph(path)

# ─────────────────────────────────────────────────────────────
# UI Construction
# ─────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Dark background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color        = Color(0.08, 0.09, 0.12)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── Toolbar ───────────────────────────────────────────────
	var toolbar := _build_toolbar()
	add_child(toolbar)

	# ── Main area (GraphEdit left, Props panel right) ─────────
	var h_split := HBoxContainer.new()
	h_split.layout_mode  = 1
	h_split.anchor_left  = 0.0; h_split.anchor_right  = 1.0
	h_split.anchor_top   = 0.0; h_split.anchor_bottom = 1.0
	h_split.offset_top   = TOOLBAR_H
	add_child(h_split)

	# GraphEdit
	_graph_edit = GraphEdit.new()
	_graph_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_edit.right_disconnects = true
	_graph_edit.connection_request.connect(_on_connection_request)
	_graph_edit.disconnection_request.connect(_on_disconnection_request)
	_graph_edit.node_selected.connect(_on_graph_node_selected)
	_graph_edit.node_deselected.connect(_on_graph_node_deselected)
	_graph_edit.popup_request.connect(_on_graph_popup_request)
	h_split.add_child(_graph_edit)

	# Properties panel (right side)
	_props_panel = _build_props_panel()
	h_split.add_child(_props_panel)

	# ── Status bar ────────────────────────────────────────────
	_status_lbl = Label.new()
	_status_lbl.layout_mode   = 1
	_status_lbl.anchor_left   = 0.0; _status_lbl.anchor_right  = 1.0
	_status_lbl.anchor_top    = 1.0; _status_lbl.anchor_bottom = 1.0
	_status_lbl.offset_top    = -24.0
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	add_child(_status_lbl)

	# ── Persistent file dialogs ────────────────────────────────
	_load_dialog = FileDialog.new()
	_load_dialog.file_mode   = FileDialog.FILE_MODE_OPEN_FILE
	_load_dialog.filters     = PackedStringArray(["*.json ; Exploration Graph JSON"])
	_load_dialog.access      = FileDialog.ACCESS_FILESYSTEM
	_load_dialog.current_dir = ProjectSettings.globalize_path("res://exploration/graphs")
	_load_dialog.file_selected.connect(_on_load_file_selected)
	add_child(_load_dialog)

	_save_dialog = FileDialog.new()
	_save_dialog.file_mode    = FileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.filters      = PackedStringArray(["*.json ; Exploration Graph JSON"])
	_save_dialog.access       = FileDialog.ACCESS_FILESYSTEM
	_save_dialog.current_dir  = ProjectSettings.globalize_path("res://exploration/graphs")
	_save_dialog.current_file = "exploration_graph.json"
	_save_dialog.file_selected.connect(_on_save_file_selected)
	add_child(_save_dialog)

	# ── Audio preview player ───────────────────────────────────
	_preview_player = AudioStreamPlayer.new()
	add_child(_preview_player)

	# ── Image preview popup ────────────────────────────────────
	_img_popup = PopupPanel.new()
	add_child(_img_popup)
	_img_popup_tex = TextureRect.new()
	_img_popup_tex.custom_minimum_size = Vector2(700, 500)
	_img_popup_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_img_popup.add_child(_img_popup_tex)

func _build_toolbar() -> Control:
	var bar := HBoxContainer.new()
	bar.layout_mode  = 1
	bar.anchor_left  = 0.0; bar.anchor_right  = 1.0
	bar.anchor_top   = 0.0; bar.anchor_bottom = 0.0
	bar.offset_bottom = TOOLBAR_H
	bar.add_theme_constant_override("separation", 6)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.13, 0.18)
	sb.content_margin_left = 8.0; sb.content_margin_right = 8.0
	sb.content_margin_top  = 6.0; sb.content_margin_bottom = 6.0

	var panel := PanelContainer.new()
	panel.layout_mode  = 1
	panel.anchor_left  = 0.0; panel.anchor_right  = 1.0
	panel.anchor_top   = 0.0; panel.anchor_bottom = 0.0
	panel.offset_bottom = TOOLBAR_H
	panel.add_theme_stylebox_override("panel", sb)
	panel.add_child(bar)

	_make_tool_btn(bar, "New",        _on_new_pressed)
	_make_tool_btn(bar, "Load…",      _on_load_pressed)
	_make_tool_btn(bar, "Save",       _on_save_pressed)
	_make_tool_btn(bar, "Save As…",   _on_save_as_pressed)
	bar.add_child(VSeparator.new())
	_make_tool_btn(bar, "+ Node",     _on_add_node_pressed)
	_make_tool_btn(bar, "Delete",     _on_delete_node_pressed)
	bar.add_child(VSeparator.new())
	_make_tool_btn(bar, "Validate",   _on_validate_pressed)
	_make_tool_btn(bar, "▶ Test Play",_on_test_play_pressed)
	bar.add_child(VSeparator.new())
	_make_tool_btn(bar, "🗃 Items",   _on_items_pressed)
	bar.add_child(VSeparator.new())
	_make_tool_btn(bar, "← Back",     _on_back_pressed)

	return panel   # bar is a child of panel; we return panel as the toolbar Control

func _make_tool_btn(parent: Control, label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func _build_props_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PROPS_PANEL_W, 0.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.11, 0.16)
	sb.border_width_left = 2
	sb.border_color = Color(0.35, 0.55, 0.85, 0.4)
	panel.add_theme_stylebox_override("panel", sb)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(PROPS_PANEL_W - 20.0, 0.0)
	vbox.add_theme_constant_override("separation", 10)
	vbox.offset_top   = 10.0
	vbox.offset_bottom = -10.0
	scroll.add_child(vbox)

	# Section: Node Identity
	_add_section_header(vbox, "NODE IDENTITY")
	_prop_id_edit    = _add_field(vbox, "ID", "node_id")
	_prop_title_edit = _add_field(vbox, "Title", "")
	_prop_type_btn   = _add_type_dropdown(vbox)
	vbox.add_child(HSeparator.new())

	# Section: Content
	_add_section_header(vbox, "CONTENT")
	_prop_desc_edit  = _add_textarea(vbox, "Description")
	_prop_bg_edit    = _add_file_field(vbox, "Background (res:// path)",
		PackedStringArray(["*.png,*.jpg,*.jpeg ; Images"]), "res://assets/textures")
	var bg_preview_btn := Button.new()
	bg_preview_btn.text = "Preview"
	bg_preview_btn.custom_minimum_size = Vector2(60, 0)
	bg_preview_btn.add_theme_font_size_override("font_size", 13)
	bg_preview_btn.pressed.connect(func() -> void: _preview_image(_prop_bg_edit.text.strip_edges()))
	_prop_bg_edit.get_parent().add_child(bg_preview_btn)
	_prop_vn_edit    = _add_file_field(vbox, "VN Scene (res:// path)",
		PackedStringArray(["*.json ; JSON Files"]), "res://exploration/vn",
		func() -> void: _browse_for_vn_scene())
	var edit_beats_btn := Button.new()
	edit_beats_btn.text = "Edit Beats ↗"
	edit_beats_btn.add_theme_font_size_override("font_size", 13)
	edit_beats_btn.pressed.connect(_on_edit_beats_pressed)
	vbox.add_child(edit_beats_btn)
	_prop_vn_play_once_chk = CheckBox.new()
	_prop_vn_play_once_chk.text = "Play Once"
	_prop_vn_play_once_chk.button_pressed = true
	_prop_vn_play_once_chk.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_prop_vn_play_once_chk)
	_prop_show_info_chk = CheckBox.new()
	_prop_show_info_chk.text = "Show Info Panel on Enter"
	_prop_show_info_chk.button_pressed = true
	_prop_show_info_chk.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_prop_show_info_chk)
	_prop_show_who_chk = CheckBox.new()
	_prop_show_who_chk.text = "Show 'Who is Here' in Info Panel"
	_prop_show_who_chk.button_pressed = true
	_prop_show_who_chk.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_prop_show_who_chk)
	_prop_music_edit = _add_file_field(vbox, "Music (res:// path)",
		PackedStringArray(["*.mp3,*.ogg,*.wav ; Audio Files"]), "res://assets/audio")
	var music_play_btn := Button.new()
	music_play_btn.text = "▶"
	music_play_btn.custom_minimum_size = Vector2(30, 0)
	music_play_btn.add_theme_font_size_override("font_size", 13)
	music_play_btn.pressed.connect(func() -> void: _preview_audio(_prop_music_edit.text.strip_edges()))
	_prop_music_edit.get_parent().add_child(music_play_btn)
	var music_stop_btn := Button.new()
	music_stop_btn.text = "■"
	music_stop_btn.custom_minimum_size = Vector2(30, 0)
	music_stop_btn.add_theme_font_size_override("font_size", 13)
	music_stop_btn.pressed.connect(func() -> void: if _preview_player != null: _preview_player.stop())
	_prop_music_edit.get_parent().add_child(music_stop_btn)
	vbox.add_child(HSeparator.new())

	# Section: On-Enter Events
	_add_section_header(vbox, "ON-ENTER EVENTS")
	_prop_events_in_vbox = VBoxContainer.new()
	_prop_events_in_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(_prop_events_in_vbox)
	var add_enter_btn := Button.new()
	add_enter_btn.text = "+ Add Event"
	add_enter_btn.add_theme_font_size_override("font_size", 13)
	add_enter_btn.pressed.connect(func() -> void: _add_event_row(_prop_events_in_vbox))
	vbox.add_child(add_enter_btn)
	vbox.add_child(HSeparator.new())

	# Section: On-Exit Events
	_add_section_header(vbox, "ON-EXIT EVENTS")
	_prop_events_out_vbox = VBoxContainer.new()
	_prop_events_out_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(_prop_events_out_vbox)
	var add_exit_btn := Button.new()
	add_exit_btn.text = "+ Add Event"
	add_exit_btn.add_theme_font_size_override("font_size", 13)
	add_exit_btn.pressed.connect(func() -> void: _add_event_row(_prop_events_out_vbox))
	vbox.add_child(add_exit_btn)
	vbox.add_child(HSeparator.new())

	# Section: Connections
	_add_section_header(vbox, "OUTGOING CONNECTIONS")
	_prop_connections_vbox = VBoxContainer.new()
	_prop_connections_vbox.add_theme_constant_override("separation", 6)
	vbox.add_child(_prop_connections_vbox)
	var add_conn_btn := Button.new()
	add_conn_btn.text = "+ Add Connection"
	add_conn_btn.add_theme_font_size_override("font_size", 13)
	add_conn_btn.pressed.connect(_on_add_connection_pressed)
	vbox.add_child(add_conn_btn)
	vbox.add_child(HSeparator.new())

	# Section: Characters
	_add_section_header(vbox, "CHARACTERS")
	_prop_characters_vbox = VBoxContainer.new()
	_prop_characters_vbox.add_theme_constant_override("separation", 6)
	vbox.add_child(_prop_characters_vbox)
	var add_char_btn := Button.new()
	add_char_btn.text = "+ Add Character"
	add_char_btn.add_theme_font_size_override("font_size", 13)
	add_char_btn.pressed.connect(func() -> void: _add_character_row(_prop_characters_vbox, {}))
	vbox.add_child(add_char_btn)
	vbox.add_child(HSeparator.new())

	# Section: Investigable Points
	_add_section_header(vbox, "INVESTIGABLE POINTS")
	_prop_spots_vbox = VBoxContainer.new()
	_prop_spots_vbox.add_theme_constant_override("separation", 6)
	vbox.add_child(_prop_spots_vbox)
	var add_spot_btn := Button.new()
	add_spot_btn.text = "+ Add Investigable Point"
	add_spot_btn.add_theme_font_size_override("font_size", 13)
	add_spot_btn.pressed.connect(func() -> void: _add_spot_row(_prop_spots_vbox, {}))
	vbox.add_child(add_spot_btn)
	vbox.add_child(HSeparator.new())

	# Apply button
	var apply_btn := Button.new()
	apply_btn.text = "Apply Changes"
	apply_btn.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	apply_btn.add_theme_font_size_override("font_size", 16)
	apply_btn.pressed.connect(_on_apply_pressed)
	vbox.add_child(apply_btn)

	return panel

# ─────────────────────────────────────────────────────────────
# Properties Panel Helpers
# ─────────────────────────────────────────────────────────────

func _add_section_header(parent: Control, text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.70, 0.90))
	parent.add_child(lbl)
	return lbl

func _add_field(parent: Control, label_text: String, placeholder: String) -> LineEdit:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
	parent.add_child(lbl)
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.add_theme_font_size_override("font_size", 14)
	parent.add_child(edit)
	return edit

func _add_file_field(parent: Control, label_text: String,
		filters: PackedStringArray, start_dir: String, custom_browse: Callable = Callable()) -> LineEdit:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
	parent.add_child(lbl)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.add_theme_font_size_override("font_size", 14)
	row.add_child(edit)
	var browse_btn := Button.new()
	browse_btn.text = "…"
	browse_btn.custom_minimum_size = Vector2(32.0, 0.0)
	if custom_browse.is_valid():
		browse_btn.pressed.connect(custom_browse)
	else:
		browse_btn.pressed.connect(func() -> void: _browse_for_file(edit, filters, start_dir))
	row.add_child(browse_btn)
	return edit

func _browse_for_vn_scene() -> void:
	var start_dir: String = "res://exploration/vn"
	if not _graph_path.is_empty():
		var name: String = _graph_path.get_file().get_basename()
		start_dir = "res://exploration/vn/vn_" + name
	_browse_for_file(_prop_vn_edit, PackedStringArray(["*.json ; JSON Files"]), start_dir)

func _browse_for_file(target_edit: LineEdit, filters: PackedStringArray, start_dir: String) -> void:
	var dialog := FileDialog.new()
	dialog.file_mode   = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters     = filters
	dialog.access      = FileDialog.ACCESS_RESOURCES
	dialog.current_dir = start_dir
	dialog.file_selected.connect(func(path: String) -> void: target_edit.text = path)
	add_child(dialog)
	dialog.popup_centered(Vector2(900, 600))

## Open a searchable item-picker popup. On selection sets target_edit.text to the item id.
func _open_item_picker(target_edit: LineEdit) -> void:
	var win := Window.new()
	win.title = "Pick Item"
	win.size  = Vector2i(380, 500)
	win.unresizable = true
	add_child(win)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	win.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var search := LineEdit.new()
	search.placeholder_text = "Search by name or ID..."
	search.add_theme_font_size_override("font_size", 14)
	vbox.add_child(search)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(list_vbox)

	var all_items: Array = ExplorationItemDatabase.all_items()

	var refresh := func(filter: String) -> void:
		for c: Node in list_vbox.get_children():
			c.queue_free()
		var f: String = filter.strip_edges().to_lower()
		for entry: Variant in all_items:
			if not entry is Dictionary:
				continue
			var d: Dictionary = entry as Dictionary
			var iid: String   = str(d.get("id",   ""))
			var iname: String = str(d.get("name",  iid))
			if not f.is_empty() and not iid.to_lower().contains(f) and not iname.to_lower().contains(f):
				continue
			var btn := Button.new()
			btn.text = "%s  [%s]" % [iname, iid]
			btn.flat = true
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", 13)
			var cap_id: String = iid
			btn.pressed.connect(func() -> void:
				target_edit.text = cap_id
				win.queue_free())
			list_vbox.add_child(btn)

	refresh.call("")
	search.text_changed.connect(refresh)
	win.close_requested.connect(win.queue_free)
	win.popup_centered()

## Open a searchable booster-pack picker. On selection sets target_edit.text to pack name.
func _open_pack_picker(target_edit: LineEdit) -> void:
	var win := Window.new()
	win.title = "Pick Booster Pack"
	win.size  = Vector2i(420, 500)
	win.unresizable = true
	add_child(win)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	win.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var search := LineEdit.new()
	search.placeholder_text = "Search by pack name or id..."
	search.add_theme_font_size_override("font_size", 14)
	vbox.add_child(search)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(list_vbox)

	var all_packs: Array = ShopManager.get_all_packs_unfiltered()

	var refresh := func(filter: String) -> void:
		for c: Node in list_vbox.get_children():
			c.queue_free()
		var f: String = filter.strip_edges().to_lower()
		for entry: Variant in all_packs:
			if not entry is Dictionary:
				continue
			var d: Dictionary = entry as Dictionary
			var pid: String   = str(d.get("id",   ""))
			var pname: String = str(d.get("name", pid))
			if not f.is_empty() \
					and not pid.to_lower().contains(f) \
					and not pname.to_lower().contains(f):
				continue
			var btn := Button.new()
			btn.text = "%s  [%s]" % [pname, pid]
			btn.flat = true
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", 13)
			var cap_name: String = pname
			btn.pressed.connect(func() -> void:
				target_edit.text = cap_name
				win.queue_free())
			list_vbox.add_child(btn)

	refresh.call("")
	search.text_changed.connect(refresh)
	win.close_requested.connect(win.queue_free)
	win.popup_centered()

func _add_textarea(parent: Control, label_text: String) -> TextEdit:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
	parent.add_child(lbl)
	var edit := TextEdit.new()
	edit.custom_minimum_size = Vector2(0.0, 90.0)
	edit.wrap_mode           = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.add_theme_font_size_override("font_size", 14)
	parent.add_child(edit)
	return edit

func _add_type_dropdown(parent: Control) -> OptionButton:
	var lbl := Label.new()
	lbl.text = "Node Type"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
	parent.add_child(lbl)
	var ob := OptionButton.new()
	for type_name: String in ExplorationNode.NodeType.keys():
		ob.add_item(type_name)
	ob.add_theme_font_size_override("font_size", 14)
	parent.add_child(ob)
	return ob

## Add one event row to an events VBox.
## Row format: [action OptionButton] [key LineEdit] [value LineEdit] [x Button]
func _add_event_row(events_vbox: VBoxContainer, action: String = "show_message",
		key: String = "", value: String = "") -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	events_vbox.add_child(row)

	var action_btn := OptionButton.new()
	var _action_list: Array[String] = [
		"give_item", "give_booster_pack", "remove_item", "set_var",
		"give_credits", "set_flag", "show_message", "play_sfx"]
	for a: String in _action_list:
		action_btn.add_item(a)
	var _action_idx: int = _action_list.find(action)
	action_btn.select(_action_idx if _action_idx >= 0 else 0)
	action_btn.add_theme_font_size_override("font_size", 12)
	action_btn.custom_minimum_size = Vector2(110.0, 0.0)
	row.add_child(action_btn)

	var key_edit := LineEdit.new()
	key_edit.text             = key
	key_edit.placeholder_text = "key"
	key_edit.add_theme_font_size_override("font_size", 12)
	key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(key_edit)

	var item_pick_btn := Button.new()
	item_pick_btn.text = "…"
	item_pick_btn.tooltip_text = "Browse items (fills key field)"
	item_pick_btn.custom_minimum_size = Vector2(28.0, 0.0)
	item_pick_btn.pressed.connect(func() -> void: _open_item_picker(key_edit))
	row.add_child(item_pick_btn)

	var val_edit := LineEdit.new()
	val_edit.text             = value
	val_edit.placeholder_text = "value / amount / pack"
	val_edit.add_theme_font_size_override("font_size", 12)
	val_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(val_edit)

	var pack_pick_btn := Button.new()
	pack_pick_btn.text = "…"
	pack_pick_btn.tooltip_text = "Browse booster packs (fills value field)"
	pack_pick_btn.custom_minimum_size = Vector2(28.0, 0.0)
	pack_pick_btn.pressed.connect(func() -> void: _open_pack_picker(val_edit))
	row.add_child(pack_pick_btn)

	# Show only the relevant picker button based on the selected action.
	var _update_event_pickers := func(sel_idx: int) -> void:
		var sel: String = _action_list[sel_idx]
		item_pick_btn.visible = sel in ["give_item", "remove_item"]
		pack_pick_btn.visible = sel == "give_booster_pack"
	action_btn.item_selected.connect(_update_event_pickers)
	_update_event_pickers.call(action_btn.selected)

	var del_btn := Button.new()
	del_btn.text = "x"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	del_btn.pressed.connect(row.queue_free)
	row.add_child(del_btn)

## Add one connection row to the connections VBox.
func _add_connection_row(conn_vbox: VBoxContainer, target: String = "",
		label_text: String = "Continue", hint: String = "",
		locked_mode: String = "hide") -> void:
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.14, 0.22)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.30, 0.50, 0.80, 0.50)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8.0; sb.content_margin_right  = 8.0
	sb.content_margin_top  = 6.0; sb.content_margin_bottom = 6.0
	frame.add_theme_stylebox_override("panel", sb)
	conn_vbox.add_child(frame)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	frame.add_child(vb)

	# Target node ID
	var target_row := HBoxContainer.new()
	var target_lbl := Label.new()
	target_lbl.text = "→ Target"
	target_lbl.add_theme_font_size_override("font_size", 12)
	target_row.add_child(target_lbl)
	var target_edit := LineEdit.new()
	target_edit.text             = target
	target_edit.placeholder_text = "node_id"
	target_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_edit.add_theme_font_size_override("font_size", 13)
	target_row.add_child(target_edit)
	vb.add_child(target_row)

	# Label text
	var label_row := HBoxContainer.new()
	var label_lbl := Label.new()
	label_lbl.text = "Label"
	label_lbl.add_theme_font_size_override("font_size", 12)
	label_row.add_child(label_lbl)
	var label_edit := LineEdit.new()
	label_edit.text             = label_text
	label_edit.placeholder_text = "button text"
	label_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_edit.add_theme_font_size_override("font_size", 13)
	label_row.add_child(label_edit)
	vb.add_child(label_row)

	# Locked hint
	var hint_row := HBoxContainer.new()
	var hint_lbl := Label.new()
	hint_lbl.text = "Lock Hint"
	hint_lbl.add_theme_font_size_override("font_size", 12)
	hint_row.add_child(hint_lbl)
	var hint_edit := LineEdit.new()
	hint_edit.text             = hint
	hint_edit.placeholder_text = "e.g. Requires Rusty Key"
	hint_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_edit.add_theme_font_size_override("font_size", 13)
	hint_row.add_child(hint_edit)
	vb.add_child(hint_row)

	# Conditions section
	var cond_lbl := Label.new()
	cond_lbl.text = "Conditions (all must pass to unlock):"
	cond_lbl.add_theme_font_size_override("font_size", 11)
	cond_lbl.add_theme_color_override("font_color", Color(0.65, 0.80, 0.65))
	vb.add_child(cond_lbl)
	var cond_vbox := VBoxContainer.new()
	cond_vbox.add_theme_constant_override("separation", 3)
	vb.add_child(cond_vbox)

	# If locked — only shown when the connection has conditions
	var locked_mode_row := HBoxContainer.new()
	locked_mode_row.add_theme_constant_override("separation", 6)
	locked_mode_row.visible = false
	var locked_mode_lbl := Label.new()
	locked_mode_lbl.text = "If locked"
	locked_mode_lbl.add_theme_font_size_override("font_size", 12)
	locked_mode_row.add_child(locked_mode_lbl)
	var locked_mode_btn := OptionButton.new()
	locked_mode_btn.add_item("Hide")
	locked_mode_btn.add_item("Disable")
	locked_mode_btn.select(1 if locked_mode.strip_edges().to_lower() == "disable" else 0)
	locked_mode_btn.add_theme_font_size_override("font_size", 12)
	locked_mode_btn.custom_minimum_size = Vector2(120.0, 0.0)
	locked_mode_btn.tooltip_text = "Hide = omit from compass menu. Disable = show greyed out."
	locked_mode_row.add_child(locked_mode_btn)
	frame.set_meta("locked_mode_btn", locked_mode_btn)

	var update_locked_mode_row := func() -> void:
		locked_mode_row.visible = cond_vbox.get_child_count() > 0
	var add_cond_btn := Button.new()
	add_cond_btn.text = "+ Condition"
	add_cond_btn.add_theme_font_size_override("font_size", 11)
	add_cond_btn.pressed.connect(func() -> void:
		_add_condition_row(cond_vbox)
		update_locked_mode_row.call())
	vb.add_child(add_cond_btn)
	vb.add_child(locked_mode_row)
	cond_vbox.child_entered_tree.connect(func(_n: Node) -> void: update_locked_mode_row.call())
	cond_vbox.child_exiting_tree.connect(func(_n: Node) -> void:
		update_locked_mode_row.call())
	update_locked_mode_row.call()

	# Remove connection button
	var del_btn := Button.new()
	del_btn.text = "Remove Connection"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	del_btn.add_theme_font_size_override("font_size", 12)
	del_btn.pressed.connect(frame.queue_free)
	vb.add_child(del_btn)

## Add one condition row inside a connection's conditions VBox.
func _add_condition_row(cond_vbox: VBoxContainer, ctype: String = "has_item",
		key: String = "", val: String = "") -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	cond_vbox.add_child(row)

	var type_btn := OptionButton.new()
	var _cond_list: Array[String] = [
		"has_item", "not_has_item", "var_equals", "var_not_equals",
		"var_greater", "var_less", "at_node"]
	for t: String in _cond_list:
		type_btn.add_item(t)
	var _cond_idx: int = _cond_list.find(ctype)
	type_btn.select(_cond_idx if _cond_idx >= 0 else 0)
	type_btn.add_theme_font_size_override("font_size", 11)
	type_btn.custom_minimum_size = Vector2(120.0, 0.0)
	row.add_child(type_btn)

	var key_edit := LineEdit.new()
	key_edit.text             = key
	key_edit.placeholder_text = "key"
	key_edit.add_theme_font_size_override("font_size", 11)
	key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(key_edit)

	var cond_pick_btn := Button.new()
	cond_pick_btn.text = "…"
	cond_pick_btn.tooltip_text = "Pick item ID"
	cond_pick_btn.custom_minimum_size = Vector2(28.0, 0.0)
	cond_pick_btn.pressed.connect(func() -> void: _open_item_picker(key_edit))
	row.add_child(cond_pick_btn)

	var val_edit := LineEdit.new()
	val_edit.text             = val
	val_edit.placeholder_text = "value"
	val_edit.add_theme_font_size_override("font_size", 11)
	val_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(val_edit)

	var del_btn := Button.new()
	del_btn.text = "x"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	del_btn.pressed.connect(row.queue_free)
	row.add_child(del_btn)

## Add one character row to the characters VBox.
func _add_character_row(chars_vbox: VBoxContainer, char_data: Dictionary) -> void:
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.16, 0.14)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.30, 0.70, 0.50, 0.50)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8.0; sb.content_margin_right  = 8.0
	sb.content_margin_top  = 6.0; sb.content_margin_bottom = 6.0
	frame.add_theme_stylebox_override("panel", sb)
	chars_vbox.add_child(frame)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	frame.add_child(vb)

	# Name row
	var name_row := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = "Name"
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_row.add_child(name_lbl)
	var name_edit := LineEdit.new()
	name_edit.text             = str(char_data.get("name", ""))
	name_edit.placeholder_text = "Character name"
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.add_theme_font_size_override("font_size", 13)
	name_row.add_child(name_edit)
	vb.add_child(name_row)

	# VN Scene row
	var vn_row := HBoxContainer.new()
	var vn_lbl := Label.new()
	vn_lbl.text = "VN Scene"
	vn_lbl.add_theme_font_size_override("font_size", 12)
	vn_row.add_child(vn_lbl)
	var vn_edit := LineEdit.new()
	vn_edit.text             = str(char_data.get("vn_scene", ""))
	vn_edit.placeholder_text = "res:// path to beat JSON"
	vn_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vn_edit.add_theme_font_size_override("font_size", 13)
	vn_row.add_child(vn_edit)
	var browse_btn := Button.new()
	browse_btn.text = "…"
	browse_btn.custom_minimum_size = Vector2(28.0, 0.0)
	browse_btn.pressed.connect(func() -> void:
		_browse_for_file(vn_edit, PackedStringArray(["*.json ; JSON Files"]), "res://exploration/vn"))
	vn_row.add_child(browse_btn)
	vb.add_child(vn_row)

	# Play Once checkbox (index 2)
	var play_once_chk := CheckBox.new()
	play_once_chk.text = "Play Once"
	play_once_chk.button_pressed = bool(char_data.get("play_once", true))
	play_once_chk.add_theme_font_size_override("font_size", 12)
	vb.add_child(play_once_chk)

	# Canon Story checkbox (index 3) — pulses chat HUD when available
	var canon_chk := CheckBox.new()
	canon_chk.text = "Canon Story"
	canon_chk.button_pressed = bool(char_data.get("canon_story", false))
	canon_chk.add_theme_font_size_override("font_size", 12)
	vb.add_child(canon_chk)

	# Thumbnail row (index 4)
	var thumb_row := HBoxContainer.new()
	var thumb_lbl := Label.new()
	thumb_lbl.text = "Thumbnail"
	thumb_lbl.add_theme_font_size_override("font_size", 12)
	thumb_row.add_child(thumb_lbl)
	var thumb_edit := LineEdit.new()
	thumb_edit.text             = str(char_data.get("thumbnail", ""))
	thumb_edit.placeholder_text = "res:// path to portrait image"
	thumb_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	thumb_edit.add_theme_font_size_override("font_size", 13)
	thumb_row.add_child(thumb_edit)
	var thumb_browse_btn := Button.new()
	thumb_browse_btn.text = "…"
	thumb_browse_btn.custom_minimum_size = Vector2(28.0, 0.0)
	thumb_browse_btn.pressed.connect(func() -> void:
		_browse_for_file(thumb_edit,
			PackedStringArray(["*.png,*.jpg,*.webp ; Images"]),
			"res://assets/textures/exploration/thumbnail"))
	thumb_row.add_child(thumb_browse_btn)
	vb.add_child(thumb_row)

	# Edit Beats button
	var edit_beats_btn := Button.new()
	edit_beats_btn.text = "Edit Beats ↗"
	edit_beats_btn.add_theme_font_size_override("font_size", 12)
	edit_beats_btn.pressed.connect(func() -> void: _on_edit_char_beats_pressed(name_edit, vn_edit))
	vb.add_child(edit_beats_btn)

	# Conditions section
	var cond_hdr := Label.new()
	cond_hdr.text = "Conditions (all must pass to show):"
	cond_hdr.add_theme_font_size_override("font_size", 11)
	cond_hdr.add_theme_color_override("font_color", Color(0.65, 0.80, 0.65))
	vb.add_child(cond_hdr)
	var cond_vbox := VBoxContainer.new()
	cond_vbox.add_theme_constant_override("separation", 3)
	vb.add_child(cond_vbox)
	var add_cond_btn := Button.new()
	add_cond_btn.text = "+ Condition"
	add_cond_btn.add_theme_font_size_override("font_size", 11)
	add_cond_btn.pressed.connect(func() -> void: _add_condition_row(cond_vbox))
	vb.add_child(add_cond_btn)

	# Populate existing conditions
	var conds: Variant = char_data.get("conditions", [])
	if conds is Array:
		for cond: Variant in (conds as Array):
			if cond is Dictionary:
				var cdd: Dictionary = cond as Dictionary
				_add_condition_row(cond_vbox,
					str(cdd.get("type", "has_item")),
					str(cdd.get("key", "")),
					str(cdd.get("value", "")))

	# Remove button
	var del_btn := Button.new()
	del_btn.text = "Remove Character"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	del_btn.add_theme_font_size_override("font_size", 12)
	del_btn.pressed.connect(frame.queue_free)
	vb.add_child(del_btn)

## Collect all character rows from the characters VBox into an Array of Dictionaries.
func _collect_characters(chars_vbox: VBoxContainer) -> Array:
	var result: Array = []
	for frame: Node in chars_vbox.get_children():
		if not frame is PanelContainer:
			continue
		var vb: VBoxContainer = null
		for child: Node in frame.get_children():
			if child is VBoxContainer:
				vb = child as VBoxContainer
				break
		if vb == null or vb.get_child_count() < 2:
			continue
		# Row 0: name_row (HBoxContainer → LineEdit)
		var name_edit: LineEdit = _find_line_edit(vb.get_child(0))
		# Row 1: vn_row (HBoxContainer → LineEdit)
		var vn_edit: LineEdit   = _find_line_edit(vb.get_child(1))
		# Row 2: play_once_chk (CheckBox)
		var play_once: bool = true
		if vb.get_child_count() > 2 and vb.get_child(2) is CheckBox:
			play_once = (vb.get_child(2) as CheckBox).button_pressed
		# Row 3: canon_story_chk (CheckBox)
		var canon_story: bool = false
		if vb.get_child_count() > 3 and vb.get_child(3) is CheckBox:
			canon_story = (vb.get_child(3) as CheckBox).button_pressed
		# Row 4: thumbnail_row (HBoxContainer → LineEdit)
		var thumb_edit: LineEdit = _find_line_edit(vb.get_child(4)) if vb.get_child_count() > 4 else null
		# Row 7: cond_vbox (VBoxContainer at index 7)
		var conditions: Array = []
		if vb.get_child_count() > 7 and vb.get_child(7) is VBoxContainer:
			var cond_vbox: VBoxContainer = vb.get_child(7) as VBoxContainer
			for row: Node in cond_vbox.get_children():
				if not row is HBoxContainer:
					continue
				var rc: Array = (row as HBoxContainer).get_children()
				if rc.size() < 4:
					continue
				conditions.append({
					"type":  (rc[0] as OptionButton).get_item_text((rc[0] as OptionButton).selected),
					"key":   (rc[1] as LineEdit).text,
					"value": (rc[2] as LineEdit).text,
				})
		result.append({
			"name":        name_edit.text.strip_edges()  if name_edit  != null else "",
			"vn_scene":    vn_edit.text.strip_edges()    if vn_edit    != null else "",
			"thumbnail":   thumb_edit.text.strip_edges() if thumb_edit != null else "",
			"play_once":   play_once,
			"canon_story": canon_story,
			"conditions":  conditions,
		})
	return result

## Add one investigable-point row to the spots VBox.
## VBoxContainer children layout (by index):
##   0: pos_row      (HBoxContainer → SpinBox x_norm, SpinBox y_norm)
##   1: icon_row     (HBoxContainer → LineEdit icon_path)
##   2: scale_row    (HBoxContainer → SpinBox icon_scale)
##   3: tooltip_row  (HBoxContainer → LineEdit tooltip)
##   4: acts_hdr     (Label)
##   5: acts_vbox    (VBoxContainer of action rows)
##   6: add_act_btn  (Button)
##   7: conds_hdr    (Label)
##   8: conds_vbox   (VBoxContainer of condition rows)
##   9: add_cond_btn (Button)
##  10: del_btn      (Button)
func _add_spot_row(spots_vbox: VBoxContainer, spot_data: Dictionary) -> void:
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.18)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.70, 0.45, 0.90, 0.55)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8.0; sb.content_margin_right  = 8.0
	sb.content_margin_top  = 6.0; sb.content_margin_bottom = 6.0
	frame.add_theme_stylebox_override("panel", sb)
	spots_vbox.add_child(frame)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	frame.add_child(vb)

	# Index 0: Position row
	var pos_row := HBoxContainer.new()
	pos_row.add_theme_constant_override("separation", 4)
	var xlbl := Label.new(); xlbl.text = "X:"; xlbl.add_theme_font_size_override("font_size", 12)
	pos_row.add_child(xlbl)
	var x_spin := SpinBox.new()
	x_spin.min_value = 0.0; x_spin.max_value = 1.0; x_spin.step = 0.001
	x_spin.value = float(spot_data.get("x_norm", 0.5))
	x_spin.custom_minimum_size = Vector2(80, 0)
	x_spin.add_theme_font_size_override("font_size", 12)
	pos_row.add_child(x_spin)
	var ylbl := Label.new(); ylbl.text = "Y:"; ylbl.add_theme_font_size_override("font_size", 12)
	pos_row.add_child(ylbl)
	var y_spin := SpinBox.new()
	y_spin.min_value = 0.0; y_spin.max_value = 1.0; y_spin.step = 0.001
	y_spin.value = float(spot_data.get("y_norm", 0.5))
	y_spin.custom_minimum_size = Vector2(80, 0)
	y_spin.add_theme_font_size_override("font_size", 12)
	pos_row.add_child(y_spin)
	var pick_btn := Button.new()
	pick_btn.text = "Pick ◎"
	pick_btn.add_theme_font_size_override("font_size", 12)
	pick_btn.pressed.connect(func() -> void:
		_open_spot_picker(_prop_bg_edit.text.strip_edges(), x_spin, y_spin))
	pos_row.add_child(pick_btn)
	vb.add_child(pos_row)

	# Index 1: Icon row
	var icon_row := HBoxContainer.new()
	var icon_lbl := Label.new(); icon_lbl.text = "Icon"; icon_lbl.add_theme_font_size_override("font_size", 12)
	icon_row.add_child(icon_lbl)
	var icon_edit := LineEdit.new()
	icon_edit.text             = str(spot_data.get("icon", ""))
	icon_edit.placeholder_text = "res:// image path (optional)"
	icon_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_edit.add_theme_font_size_override("font_size", 12)
	icon_row.add_child(icon_edit)
	var icon_browse := Button.new()
	icon_browse.text = "…"
	icon_browse.custom_minimum_size = Vector2(28, 0)
	icon_browse.pressed.connect(func() -> void:
		_browse_for_file(icon_edit, PackedStringArray(["*.png,*.jpg,*.webp ; Images"]),
			"res://assets/textures/exploration"))
	icon_row.add_child(icon_browse)
	vb.add_child(icon_row)

	# Index 2: Scale row
	var scale_row := HBoxContainer.new()
	scale_row.add_theme_constant_override("separation", 4)
	var slbl := Label.new(); slbl.text = "Scale %"; slbl.add_theme_font_size_override("font_size", 12)
	scale_row.add_child(slbl)
	var scale_spin := SpinBox.new()
	scale_spin.min_value = 1.0; scale_spin.max_value = 500.0; scale_spin.step = 1.0
	scale_spin.value = float(spot_data.get("icon_scale", 100.0))
	scale_spin.custom_minimum_size = Vector2(80, 0)
	scale_spin.add_theme_font_size_override("font_size", 12)
	scale_row.add_child(scale_spin)
	vb.add_child(scale_row)

	# Index 3: Tooltip row
	var tip_row := HBoxContainer.new()
	var tlbl := Label.new(); tlbl.text = "Tooltip"; tlbl.add_theme_font_size_override("font_size", 12)
	tip_row.add_child(tlbl)
	var tip_edit := LineEdit.new()
	tip_edit.text             = str(spot_data.get("tooltip", ""))
	tip_edit.placeholder_text = "hover text (optional)"
	tip_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip_edit.add_theme_font_size_override("font_size", 12)
	tip_row.add_child(tip_edit)
	vb.add_child(tip_row)

	# Index 4: Hide-after-interact row
	var hide_row := HBoxContainer.new()
	var hide_cb := CheckBox.new()
	hide_cb.text           = "Hide after interact"
	hide_cb.button_pressed = bool(spot_data.get("hide_after_interact", false))
	hide_cb.add_theme_font_size_override("font_size", 12)
	hide_row.add_child(hide_cb)
	vb.add_child(hide_row)

	# Index 5: Actions header
	var acts_hdr := Label.new()
	acts_hdr.text = "Actions on click:"
	acts_hdr.add_theme_font_size_override("font_size", 11)
	acts_hdr.add_theme_color_override("font_color", Color(0.80, 0.65, 1.0))
	vb.add_child(acts_hdr)

	# Index 6: Actions VBox
	var acts_vbox := VBoxContainer.new()
	acts_vbox.add_theme_constant_override("separation", 3)
	vb.add_child(acts_vbox)

	# Index 7: Add Action button
	var add_act_btn := Button.new()
	add_act_btn.text = "+ Add Action"
	add_act_btn.add_theme_font_size_override("font_size", 11)
	add_act_btn.pressed.connect(func() -> void: _add_spot_action_row(acts_vbox))
	vb.add_child(add_act_btn)

	# Index 8: Conditions header
	var cond_hdr := Label.new()
	cond_hdr.text = "Conditions (all must pass to show):"
	cond_hdr.add_theme_font_size_override("font_size", 11)
	cond_hdr.add_theme_color_override("font_color", Color(0.65, 0.80, 0.65))
	vb.add_child(cond_hdr)

	# Index 9: Conditions VBox
	var cond_vbox := VBoxContainer.new()
	cond_vbox.add_theme_constant_override("separation", 3)
	vb.add_child(cond_vbox)

	# Index 10: Add Condition button
	var add_cond_btn := Button.new()
	add_cond_btn.text = "+ Condition"
	add_cond_btn.add_theme_font_size_override("font_size", 11)
	add_cond_btn.pressed.connect(func() -> void: _add_condition_row(cond_vbox))
	vb.add_child(add_cond_btn)

	# Populate existing actions
	var raw_acts: Variant = spot_data.get("actions", [])
	if raw_acts is Array:
		for act_var: Variant in (raw_acts as Array):
			if act_var is Dictionary:
				var ad: Dictionary = act_var as Dictionary
				_add_spot_action_row(acts_vbox,
					str(ad.get("action", "show_message")),
					str(ad.get("key",    "")),
					str(ad.get("value",  "")))
	# Backward compat: legacy vn_scene field → play_vn action
	var legacy_vn: String = str(spot_data.get("vn_scene", ""))
	if not legacy_vn.is_empty() and (not (raw_acts is Array) or (raw_acts as Array).is_empty()):
		_add_spot_action_row(acts_vbox, "play_vn", "", legacy_vn)

	# Populate existing conditions
	var conds_v: Variant = spot_data.get("conditions", [])
	if conds_v is Array:
		for cond_var: Variant in (conds_v as Array):
			if cond_var is Dictionary:
				var cd: Dictionary = cond_var as Dictionary
				_add_condition_row(cond_vbox,
					str(cd.get("type",  "has_item")),
					str(cd.get("key",   "")),
					str(cd.get("value", "")))

	# Index 10: Remove button
	var del_btn := Button.new()
	del_btn.text = "Remove Point"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	del_btn.add_theme_font_size_override("font_size", 12)
	del_btn.pressed.connect(frame.queue_free)
	vb.add_child(del_btn)

## Add one action row inside a spot's actions VBox.
## Action list extended with play_vn and navigate_to vs. on_enter_events.
func _add_spot_action_row(vbox: VBoxContainer, action: String = "show_message",
		key: String = "", value: String = "") -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	vbox.add_child(row)
	var _spot_actions: Array[String] = [
		"give_item", "give_booster_pack", "remove_item", "set_var", "give_credits", "set_flag",
		"show_message", "play_sfx", "play_vn", "navigate_to"
	]
	var action_btn := OptionButton.new()
	for a: String in _spot_actions:
		action_btn.add_item(a)
	var _idx: int = _spot_actions.find(action)
	action_btn.select(_idx if _idx >= 0 else 0)
	action_btn.add_theme_font_size_override("font_size", 12)
	action_btn.custom_minimum_size = Vector2(120.0, 0.0)
	row.add_child(action_btn)
	var key_edit := LineEdit.new()
	key_edit.text             = key
	key_edit.placeholder_text = "key"
	key_edit.add_theme_font_size_override("font_size", 12)
	key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(key_edit)
	var spot_pick_btn := Button.new()
	spot_pick_btn.text = "…"
	spot_pick_btn.tooltip_text = "Browse items (fills key field)"
	spot_pick_btn.custom_minimum_size = Vector2(28.0, 0.0)
	spot_pick_btn.pressed.connect(func() -> void: _open_item_picker(key_edit))
	row.add_child(spot_pick_btn)
	var val_edit := LineEdit.new()
	val_edit.text             = value
	val_edit.placeholder_text = "value / amount / pack"
	val_edit.add_theme_font_size_override("font_size", 12)
	val_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(val_edit)
	var spot_pack_pick_btn := Button.new()
	spot_pack_pick_btn.text = "…"
	spot_pack_pick_btn.tooltip_text = "Browse booster packs (fills value field)"
	spot_pack_pick_btn.custom_minimum_size = Vector2(28.0, 0.0)
	spot_pack_pick_btn.pressed.connect(func() -> void: _open_pack_picker(val_edit))
	row.add_child(spot_pack_pick_btn)
	# Show only the relevant picker button based on the selected action.
	var _update_spot_pickers := func(sel_idx: int) -> void:
		var sel: String = _spot_actions[sel_idx]
		spot_pick_btn.visible     = sel in ["give_item", "remove_item"]
		spot_pack_pick_btn.visible = sel == "give_booster_pack"
	action_btn.item_selected.connect(_update_spot_pickers)
	_update_spot_pickers.call(action_btn.selected)
	var del_btn := Button.new()
	del_btn.text = "x"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	del_btn.pressed.connect(row.queue_free)
	row.add_child(del_btn)

## Collect all investigable-point rows back into an Array of Dictionaries.
func _collect_spots(spots_vbox: VBoxContainer) -> Array:
	var result: Array = []
	for frame: Node in spots_vbox.get_children():
		if not frame is PanelContainer:
			continue
		var vb: VBoxContainer = null
		for ch: Node in frame.get_children():
			if ch is VBoxContainer:
				vb = ch as VBoxContainer
				break
		if vb == null or vb.get_child_count() < 5:
			continue
		# Index 0: pos_row — find two SpinBoxes
		var x_norm: float = 0.5
		var y_norm: float = 0.5
		if vb.get_child(0) is HBoxContainer:
			var spins: Array = []
			for c: Node in (vb.get_child(0) as HBoxContainer).get_children():
				if c is SpinBox:
					spins.append(c as SpinBox)
			if spins.size() >= 1:
				x_norm = (spins[0] as SpinBox).value
			if spins.size() >= 2:
				y_norm = (spins[1] as SpinBox).value
		# Index 1: icon_row — first LineEdit
		var icon_path: String = ""
		var icon_le: LineEdit = _find_line_edit(vb.get_child(1)) if vb.get_child_count() > 1 else null
		if icon_le != null:
			icon_path = icon_le.text.strip_edges()
		# Index 2: scale_row — SpinBox
		var icon_scale: float = 100.0
		if vb.get_child_count() > 2 and vb.get_child(2) is HBoxContainer:
			for c: Node in (vb.get_child(2) as HBoxContainer).get_children():
				if c is SpinBox:
					icon_scale = (c as SpinBox).value
					break
		# Index 3: tooltip_row — first LineEdit
		var tooltip: String = ""
		var tip_le: LineEdit = _find_line_edit(vb.get_child(3)) if vb.get_child_count() > 3 else null
		if tip_le != null:
			tooltip = tip_le.text
		# Index 4: hide_after_interact CheckBox
		var hide_after_interact: bool = false
		if vb.get_child_count() > 4 and vb.get_child(4) is HBoxContainer:
			for c: Node in (vb.get_child(4) as HBoxContainer).get_children():
				if c is CheckBox:
					hide_after_interact = (c as CheckBox).button_pressed
					break
		# Index 6: acts_vbox — VBoxContainer
		var actions: Array = []
		if vb.get_child_count() > 6 and vb.get_child(6) is VBoxContainer:
			actions = _collect_events(vb.get_child(6) as VBoxContainer)
		# Index 9: conds_vbox — VBoxContainer
		var conditions: Array = []
		if vb.get_child_count() > 9 and vb.get_child(9) is VBoxContainer:
			var cv: VBoxContainer = vb.get_child(9) as VBoxContainer
			for row: Node in cv.get_children():
				if not row is HBoxContainer:
					continue
				var ob: OptionButton = null
				var les: Array[LineEdit] = []
				for c: Node in (row as HBoxContainer).get_children():
					if c is OptionButton and ob == null:
						ob = c as OptionButton
					elif c is LineEdit:
						les.append(c as LineEdit)
				if ob == null or les.size() < 2:
					continue
				conditions.append({
					"type":  ob.get_item_text(ob.selected),
					"key":   les[0].text,
					"value": les[1].text,
				})
		result.append({
			"x_norm":             x_norm,
			"y_norm":             y_norm,
			"icon":               icon_path,
			"icon_scale":         icon_scale,
			"tooltip":            tooltip,
			"hide_after_interact": hide_after_interact,
			"actions":            actions,
			"conditions":         conditions,
		})
	return result

## Open an interactive background-picker window so the user can click a position.
func _open_spot_picker(bg_path: String, x_spin: SpinBox, y_spin: SpinBox) -> void:
	if _spot_picker_window != null and is_instance_valid(_spot_picker_window):
		_spot_picker_window.queue_free()
	const PICK_W: float = 800.0
	const PICK_H: float = 450.0
	const MARK:   float = 10.0
	var win := Window.new()
	win.title          = "Pick Investigable Point Position"
	win.size           = Vector2i(int(PICK_W + 24), int(PICK_H + 90))
	win.exclusive      = false
	win.close_requested.connect(win.queue_free)
	get_tree().current_scene.add_child(win)
	_spot_picker_window = win
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 6)
	root_vbox.offset_left = 8.0; root_vbox.offset_right  = -8.0
	root_vbox.offset_top  = 8.0; root_vbox.offset_bottom = -8.0
	win.add_child(root_vbox)
	var hint := Label.new()
	hint.text = "Click on the image to set position  •  X: %.3f   Y: %.3f" % [x_spin.value, y_spin.value]
	hint.add_theme_font_size_override("font_size", 13)
	root_vbox.add_child(hint)
	# Image container (fixed size, stretch image to fill)
	var img_ctrl := Control.new()
	img_ctrl.custom_minimum_size = Vector2(PICK_W, PICK_H)
	img_ctrl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	img_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	root_vbox.add_child(img_ctrl)
	var tex_rect := TextureRect.new()
	tex_rect.size          = Vector2(PICK_W, PICK_H)
	tex_rect.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode  = TextureRect.STRETCH_SCALE
	tex_rect.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	if not bg_path.is_empty() and ResourceLoader.exists(bg_path):
		tex_rect.texture = load(bg_path) as Texture2D
	img_ctrl.add_child(tex_rect)
	# Crosshair marker
	var marker := Control.new()
	marker.size         = Vector2(MARK * 2.0, MARK * 2.0)
	marker.position     = Vector2(x_spin.value * PICK_W - MARK, y_spin.value * PICK_H - MARK)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img_ctrl.add_child(marker)
	var hbar := ColorRect.new()
	hbar.color    = Color(1.0, 0.2, 0.2, 0.9)
	hbar.size     = Vector2(MARK * 2.0, 2.0)
	hbar.position = Vector2(0.0, MARK - 1.0)
	hbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(hbar)
	var vbar := ColorRect.new()
	vbar.color    = Color(1.0, 0.2, 0.2, 0.9)
	vbar.size     = Vector2(2.0, MARK * 2.0)
	vbar.position = Vector2(MARK - 1.0, 0.0)
	vbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(vbar)
	# Click handler
	var cap_hint:   Label   = hint
	var cap_marker: Control = marker
	img_ctrl.gui_input.connect(func(ev: InputEvent) -> void:
		if not (ev is InputEventMouseButton):
			return
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if not (mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT):
			return
		var lp: Vector2 = mb.position
		var nx: float   = clampf(lp.x / PICK_W, 0.0, 1.0)
		var ny: float   = clampf(lp.y / PICK_H, 0.0, 1.0)
		x_spin.value    = nx
		y_spin.value    = ny
		cap_marker.position = Vector2(nx * PICK_W - MARK, ny * PICK_H - MARK)
		cap_hint.text = "Click on the image to set position  •  X: %.3f   Y: %.3f" % [nx, ny])
	# Done button
	var done_btn := Button.new()
	done_btn.text = "Done"
	done_btn.add_theme_font_size_override("font_size", 14)
	done_btn.custom_minimum_size = Vector2(80, 0)
	done_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done_btn.pressed.connect(win.queue_free)
	root_vbox.add_child(done_btn)
	win.popup_centered()

## Called when the "Edit Beats ↗" button inside a character row is pressed.
## Auto-creates the VN JSON file using the pattern vn_<node_id>_<char_name>.json.
func _on_edit_char_beats_pressed(name_edit: LineEdit, vn_edit: LineEdit) -> void:
	var path: String = vn_edit.text.strip_edges()
	if path.is_empty():
		if _graph_path.is_empty():
			_set_status("Save the graph first before creating a character VN scene.")
			return
		if _selected_node_id.is_empty():
			_set_status("Select a node first.")
			return
		var char_name: String = name_edit.text.strip_edges()
		if char_name.is_empty():
			_set_status("Enter a character name first.")
			return
		var graph_name: String = _graph_path.get_file().get_basename()
		var sanitized: String  = char_name.to_lower().replace(" ", "_")
		path = "res://exploration/vn/vn_%s/vn_%s_%s.json" % [graph_name, _selected_node_id, sanitized]
		_create_vn_subfolder(_graph_path)
		var abs_path: String = ProjectSettings.globalize_path(path)
		if not FileAccess.file_exists(abs_path):
			var f := FileAccess.open(abs_path, FileAccess.WRITE)
			if f == null:
				_set_status("ERROR: Could not create '%s'." % path)
				return
			f.store_string("[]")
			f.close()
		vn_edit.text = path
		_commit_selected_node()
		_set_status("Created '%s' — opening VN Editor." % path.get_file())
	elif not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		var abs_path: String = ProjectSettings.globalize_path(path)
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		var f := FileAccess.open(abs_path, FileAccess.WRITE)
		if f == null:
			_set_status("ERROR: Could not create '%s'." % path)
			return
		f.store_string("[]")
		f.close()
		_set_status("Created '%s' — opening VN Editor." % path.get_file())
	# Open VNEditor as overlay
	var vned: Control = load("res://scripts/VNEditor.gd").new()
	vned.name = "VNEditorOverlay"
	get_tree().current_scene.add_child(vned)
	vned.call_deferred("open_file", path)

# ─────────────────────────────────────────────────────────────
# Graph rendering
# ─────────────────────────────────────────────────────────────

func _rebuild_graph_edit() -> void:
	# Remove all existing GraphNodes and connections
	_graph_edit.clear_connections()
	for child: Node in _graph_edit.get_children():
		if child is GraphNode:
			_graph_edit.remove_child(child)
			child.queue_free()
	_gn_map.clear()

	if _graph == null:
		return

	# Create a GraphNode widget for each ExplorationNode
	for en: ExplorationNode in _graph.nodes:
		_create_graph_node(en)

	# Draw connections
	await get_tree().process_frame   # let GraphNodes process their position
	_rebuild_connections()

func _create_graph_node(en: ExplorationNode) -> GraphNode:
	var gn := GraphNode.new()
	gn.name         = en.id
	gn.title        = en.id + "  [" + ExplorationNode.NodeType.keys()[en.node_type] + "]"
	gn.position_offset = en.editor_position if en.editor_position != Vector2.ZERO \
		else Vector2(randf_range(40, 600), randf_range(40, 400))
	gn.resizable    = false

	# Colour the title bar based on type
	var type_key: String = ExplorationNode.NodeType.keys()[en.node_type]
	if NODE_TYPE_COLORS.has(type_key):
		# GraphNode doesn't expose title colour directly; tint via modulate on a child
		pass   # visual theming via stylesheet would be needed for richer colours

	# Content label inside the node
	var lbl := Label.new()
	lbl.text = en.title if not en.title.is_empty() else "(no title)"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	lbl.custom_minimum_size = Vector2(GRAPH_NODE_W, 0.0)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gn.add_child(lbl)

	# Slot 0: input port (left) + output port (right)
	gn.set_slot(0, true, 0, Color(0.45, 0.70, 1.0), true, 0, Color(0.45, 0.70, 1.0))

	_graph_edit.add_child(gn)
	_gn_map[en.id] = gn

	# Track position changes to update editor_position
	gn.position_offset_changed.connect(func() -> void: _on_node_moved(en.id, gn.position_offset))

	return gn

func _rebuild_connections() -> void:
	_graph_edit.clear_connections()
	if _graph == null:
		return
	for en: ExplorationNode in _graph.nodes:
		for conn: Variant in en.connections:
			if not conn is Dictionary:
				continue
			var target_id: String = str((conn as Dictionary).get("target", ""))
			if target_id.is_empty() or not _gn_map.has(en.id) or not _gn_map.has(target_id):
				continue
			_graph_edit.connect_node(en.id, 0, target_id, 0)

func _on_node_moved(node_id: String, pos: Vector2) -> void:
	if _graph == null:
		return
	var en: ExplorationNode = _graph.get_node_by_id(node_id)
	if en != null:
		en.editor_position = pos
	_dirty = true
	_update_title()

# ─────────────────────────────────────────────────────────────
# Graph Edit signals
# ─────────────────────────────────────────────────────────────

func _on_connection_request(from_node: StringName, _from_port: int,
		to_node: StringName, _to_port: int) -> void:
	if _graph == null:
		return
	var from_id: String = str(from_node)
	var to_id: String   = str(to_node)
	if from_id == to_id:
		return
	var src: ExplorationNode = _graph.get_node_by_id(from_id)
	if src == null:
		return
	# Enforce 8-connection cap (radial menu maximum)
	if src.connections.size() >= 8:
		_set_status("Cannot add connection: '%s' already has 8 connections (maximum)." % from_id)
		return
	# Check if this connection already exists
	for conn: Variant in src.connections:
		if conn is Dictionary and str((conn as Dictionary).get("target", "")) == to_id:
			_set_status("Connection from '%s' to '%s' already exists." % [from_id, to_id])
			return
	# Add default connection
	src.connections.append({
		"target":      to_id,
		"label":       "Go to " + to_id,
		"locked_hint": "",
		"conditions":  [],
		"locked_mode": "hide",
	})
	_graph_edit.connect_node(from_node, 0, to_node, 0)
	_dirty = true
	_update_title()
	_set_status("Connected '%s' → '%s'." % [from_id, to_id])
	# Refresh properties panel if this is the selected node
	if _selected_node_id == from_id:
		_populate_props(_graph.get_node_by_id(from_id))

func _on_disconnection_request(from_node: StringName, _from_port: int,
		to_node: StringName, _to_port: int) -> void:
	if _graph == null:
		return
	var from_id: String = str(from_node)
	var to_id: String   = str(to_node)
	var src: ExplorationNode = _graph.get_node_by_id(from_id)
	if src == null:
		return
	for i: int in range(src.connections.size() - 1, -1, -1):
		var conn: Variant = src.connections[i]
		if conn is Dictionary and str((conn as Dictionary).get("target", "")) == to_id:
			src.connections.remove_at(i)
	_graph_edit.disconnect_node(from_node, 0, to_node, 0)
	_dirty = true
	_update_title()
	if _selected_node_id == from_id:
		_populate_props(_graph.get_node_by_id(from_id))

func _on_graph_node_selected(node: Node) -> void:
	if _graph == null:
		return
	_selected_node_id = node.name
	var en: ExplorationNode = _graph.get_node_by_id(_selected_node_id)
	if en != null:
		_populate_props(en)

func _on_graph_node_deselected(_node: Node) -> void:
	_selected_node_id = ""

func _on_graph_popup_request(position: Vector2) -> void:
	# Right-click in graph area → add new node at that position
	_add_new_node_at(position)

# ─────────────────────────────────────────────────────────────
# Properties panel: populate / collect
# ─────────────────────────────────────────────────────────────

func _populate_props(en: ExplorationNode) -> void:
	_prop_id_edit.text    = en.id
	_prop_title_edit.text = en.title
	_prop_desc_edit.text  = en.description
	_prop_type_btn.select(en.node_type)
	_prop_bg_edit.text    = en.background
	_prop_vn_edit.text    = en.vn_scene
	_prop_vn_play_once_chk.button_pressed = en.vn_play_once
	_prop_show_info_chk.button_pressed = en.show_info_on_enter
	_prop_show_who_chk.button_pressed  = en.show_who_is_here
	_prop_music_edit.text = en.music

	# On-enter events
	for child: Node in _prop_events_in_vbox.get_children():
		child.queue_free()
	for ev: Variant in en.on_enter_events:
		if ev is Dictionary:
			var d: Dictionary = ev as Dictionary
			_add_event_row(_prop_events_in_vbox,
				str(d.get("action", "show_message")),
				str(d.get("key", "")),
				str(d.get("value", "")))

	# On-exit events
	for child: Node in _prop_events_out_vbox.get_children():
		child.queue_free()
	for ev: Variant in en.on_exit_events:
		if ev is Dictionary:
			var d: Dictionary = ev as Dictionary
			_add_event_row(_prop_events_out_vbox,
				str(d.get("action", "show_message")),
				str(d.get("key", "")),
				str(d.get("value", "")))

	# Characters
	for child: Node in _prop_characters_vbox.get_children():
		child.queue_free()
	for char_data: Variant in en.characters:
		if char_data is Dictionary:
			_add_character_row(_prop_characters_vbox, char_data as Dictionary)

	# Investigable Points
	for child: Node in _prop_spots_vbox.get_children():
		child.queue_free()
	for spot_var: Variant in en.clickable_spots:
		if spot_var is Dictionary:
			_add_spot_row(_prop_spots_vbox, spot_var as Dictionary)

	# Connections
	for child: Node in _prop_connections_vbox.get_children():
		child.queue_free()
	for conn: Variant in en.connections:
		if conn is Dictionary:
			var cd: Dictionary = conn as Dictionary
			_add_connection_row(_prop_connections_vbox,
				str(cd.get("target", "")),
				str(cd.get("label", "Continue")),
				str(cd.get("locked_hint", "")),
				str(cd.get("locked_mode", "hide")))
			# Restore conditions if present
			var conds: Variant = cd.get("conditions", [])
			if conds is Array:
				var last_frame: PanelContainer = _prop_connections_vbox.get_children().back() as PanelContainer
				var cond_vbox: VBoxContainer = _find_cond_vbox(last_frame)
				if cond_vbox != null:
					for cond: Variant in (conds as Array):
						if cond is Dictionary:
							var cdd: Dictionary = cond as Dictionary
							_add_condition_row(cond_vbox,
								str(cdd.get("type", "has_item")),
								str(cdd.get("key", "")),
								str(cdd.get("value", "")))

## Collect all property values from the panel back into the ExplorationNode.
func _collect_props(en: ExplorationNode) -> void:
	en.id          = _prop_id_edit.text.strip_edges()
	en.title       = _prop_title_edit.text
	en.description = _prop_desc_edit.text
	en.node_type   = _prop_type_btn.selected
	en.background  = _prop_bg_edit.text.strip_edges()
	en.vn_scene    = _prop_vn_edit.text.strip_edges()
	en.vn_play_once       = _prop_vn_play_once_chk.button_pressed
	en.show_info_on_enter = _prop_show_info_chk.button_pressed
	en.show_who_is_here   = _prop_show_who_chk.button_pressed
	en.music       = _prop_music_edit.text.strip_edges()

	# On-enter events
	en.on_enter_events.clear()
	en.on_enter_events = _collect_events(_prop_events_in_vbox)

	# On-exit events
	en.on_exit_events.clear()
	en.on_exit_events = _collect_events(_prop_events_out_vbox)

	# Characters
	en.characters.clear()
	en.characters = _collect_characters(_prop_characters_vbox)

	# Investigable Points
	en.clickable_spots.clear()
	en.clickable_spots = _collect_spots(_prop_spots_vbox)

	# Connections
	en.connections.clear()
	for frame: Node in _prop_connections_vbox.get_children():
		if not frame is PanelContainer:
			continue
		var conn_dict: Dictionary = _collect_connection_frame(frame as PanelContainer)
		if not conn_dict.is_empty():
			en.connections.append(conn_dict)

func _collect_events(events_vbox: VBoxContainer) -> Array:
	var result: Array = []
	for row: Node in events_vbox.get_children():
		if not row is HBoxContainer:
			continue
		var ob: OptionButton = null
		var les: Array[LineEdit] = []
		for c: Node in (row as HBoxContainer).get_children():
			if c is OptionButton and ob == null:
				ob = c as OptionButton
			elif c is LineEdit:
				les.append(c as LineEdit)
		if ob == null or les.size() < 2:
			continue
		result.append({
			"action": ob.get_item_text(ob.selected),
			"key":    les[0].text,
			"value":  les[1].text,
		})
	return result

func _collect_connection_frame(frame: PanelContainer) -> Dictionary:
	# Structure: PanelContainer > VBoxContainer > [target_row, label_row, hint_row, cond_lbl, cond_vbox, add_btn, del_btn]
	var vb: VBoxContainer = null
	for child: Node in frame.get_children():
		if child is VBoxContainer:
			vb = child as VBoxContainer
			break
	if vb == null:
		return {}

	var children: Array = vb.get_children()
	if children.size() < 3:
		return {}

	# Row 0: target
	var target_edit: LineEdit = _find_line_edit(children[0])
	# Row 1: label
	var label_edit: LineEdit  = _find_line_edit(children[1])
	# Row 2: hint
	var hint_edit: LineEdit   = _find_line_edit(children[2])

	var cond_vbox: VBoxContainer = _find_cond_vbox(frame)
	var conditions: Array = []
	if cond_vbox != null:
		for row: Node in cond_vbox.get_children():
			if not row is HBoxContainer:
				continue
			var ob: OptionButton = null
			var les: Array[LineEdit] = []
			for c: Node in (row as HBoxContainer).get_children():
				if c is OptionButton and ob == null:
					ob = c as OptionButton
				elif c is LineEdit:
					les.append(c as LineEdit)
			if ob == null or les.size() < 2:
				continue
			conditions.append({
				"type":  ob.get_item_text(ob.selected),
				"key":   les[0].text,
				"value": les[1].text,
			})

	var locked_mode: String = "hide"
	if conditions.size() > 0:
		var lmb: Variant = frame.get_meta("locked_mode_btn", null)
		if lmb is OptionButton:
			locked_mode = "disable" if (lmb as OptionButton).selected == 1 else "hide"

	return {
		"target":      target_edit.text.strip_edges() if target_edit != null else "",
		"label":       label_edit.text if label_edit != null else "Continue",
		"locked_hint": hint_edit.text  if hint_edit  != null else "",
		"conditions":  conditions,
		"locked_mode": locked_mode,
	}

func _find_line_edit(row: Node) -> LineEdit:
	if row is HBoxContainer:
		for c: Node in (row as HBoxContainer).get_children():
			if c is LineEdit:
				return c as LineEdit
	return null

func _find_cond_vbox(frame: Control) -> VBoxContainer:
	# Walk the tree to find the VBoxContainer that holds condition rows
	for child: Node in frame.get_children():
		if child is VBoxContainer:
			for sub: Node in (child as VBoxContainer).get_children():
				if sub is VBoxContainer and sub.get_child_count() == 0 or _is_cond_vbox(sub as VBoxContainer):
					# Check whether this VBox contains HBoxContainers (condition rows) or is just a separator
					if sub is VBoxContainer:
						return sub as VBoxContainer
	return null

func _is_cond_vbox(vb: VBoxContainer) -> bool:
	# A condition vbox has no child or has HBoxContainer children (condition rows)
	if vb == null:
		return false
	for c: Node in vb.get_children():
		if c is HBoxContainer:
			return true
	return vb.get_child_count() == 0

# ─────────────────────────────────────────────────────────────
# Toolbar Actions
# ─────────────────────────────────────────────────────────────

func _on_new_pressed() -> void:
	_new_graph()

func _on_load_pressed() -> void:
	_load_dialog.popup_centered(Vector2(900, 600))

func _on_load_file_selected(path: String) -> void:
	_load_graph(path)

func _on_save_pressed() -> void:
	_commit_selected_node()
	if _graph_path.is_empty():
		_on_save_as_pressed()
	else:
		_save_graph(_graph_path)

func _on_save_as_pressed() -> void:
	_commit_selected_node()
	_save_dialog.popup_centered(Vector2(900, 600))

func _on_save_file_selected(path: String) -> void:
	_save_graph(path)

## Silently applies any pending property edits for the currently selected node.
## Called before every save so that unsaved panel changes (e.g. connections added
## via "+ Add Connection" without clicking Apply) are not lost.
func _commit_selected_node() -> void:
	if _selected_node_id.is_empty() or _graph == null:
		return
	var en: ExplorationNode = _graph.get_node_by_id(_selected_node_id)
	if en == null:
		return
	var old_id: String = en.id
	_collect_props(en)
	if en.id != old_id:
		_rename_node_references(old_id, en.id)
		var gn_node: GraphNode = _gn_map.get(old_id, null) as GraphNode
		if gn_node != null:
			gn_node.name  = en.id
			gn_node.title = en.id + "  [" + ExplorationNode.NodeType.keys()[en.node_type] + "]"
			_gn_map.erase(old_id)
			_gn_map[en.id] = gn_node
			_selected_node_id = en.id

func _on_add_node_pressed() -> void:
	_add_new_node_at(Vector2(200.0, 200.0) + Vector2(randf_range(-50, 50), randf_range(-50, 50)))

func _on_delete_node_pressed() -> void:
	if _selected_node_id.is_empty() or _graph == null:
		return
	_delete_node(_selected_node_id)

func _on_validate_pressed() -> void:
	if _graph == null:
		return
	var warnings: Array[String] = _graph.validate()
	if warnings.is_empty():
		_set_status("Validation passed — no issues found.")
	else:
		var msg: String = "VALIDATION WARNINGS:\n" + "\n".join(warnings)
		_set_status(msg)
		# Also show as a popup
		_show_popup("Validation Results", msg)

func _on_test_play_pressed() -> void:
	if _graph == null:
		_set_status("No graph to test.")
		return
	if _dirty:
		_set_status("Save the graph before test play.")
		return
	if _graph_path.is_empty():
		_set_status("Save to a file before test play.")
		return
	ExplorationManager.launch(_graph_path, "res://scenes/exploration_editor.tscn")

func _on_items_pressed() -> void:
	# Prevent duplicate
	if get_node_or_null("ExplorationItemManagerOverlay") != null:
		return
	var mgr: Control = load("res://scenes/exploration_item_manager.tscn").instantiate() as Control
	mgr.name = "ExplorationItemManagerOverlay"
	add_child(mgr)
	# Set anchors AFTER add_child so the parent rect is resolved
	mgr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_add_connection_pressed() -> void:
	_add_connection_row(_prop_connections_vbox)

func _preview_image(path: String) -> void:
	if path.is_empty():
		_set_status("No background path set.")
		return
	if not ResourceLoader.exists(path):
		_set_status("Image not found: %s" % path.get_file())
		return
	var tex: Variant = load(path)
	if not tex is Texture2D:
		_set_status("Not an image: %s" % path.get_file())
		return
	_img_popup_tex.texture = tex as Texture2D
	_img_popup.popup_centered(Vector2(820, 620))

func _preview_audio(path: String) -> void:
	if path.is_empty():
		_set_status("No music path set.")
		return
	if not ResourceLoader.exists(path):
		_set_status("Audio not found: %s" % path.get_file())
		return
	var stream: Variant = load(path)
	if not stream is AudioStream:
		_set_status("Not an audio file: %s" % path.get_file())
		return
	_preview_player.stream = stream as AudioStream
	_preview_player.stop()
	_preview_player.play()
	_set_status("Playing: %s" % path.get_file())

func _on_edit_beats_pressed() -> void:
	var path: String = _prop_vn_edit.text.strip_edges()
	if path.is_empty():
		# Auto-create: requires graph to be saved and a node selected
		if _graph_path.is_empty():
			_set_status("Save the graph first before creating a VN scene.")
			return
		if _selected_node_id.is_empty():
			_set_status("Select a node first.")
			return
		var graph_name: String = _graph_path.get_file().get_basename()
		path = "res://exploration/vn/vn_%s/vn_%s.json" % [graph_name, _selected_node_id]
		# Ensure the subfolder exists
		_create_vn_subfolder(_graph_path)
		# Create empty beat file
		var abs_path: String = ProjectSettings.globalize_path(path)
		if not FileAccess.file_exists(abs_path):
			var f := FileAccess.open(abs_path, FileAccess.WRITE)
			if f == null:
				_set_status("ERROR: Could not create '%s'." % path)
				return
			f.store_string("[]")
			f.close()
		# Fill the VN Scene field and commit so it saves to the node
		_prop_vn_edit.text = path
		_commit_selected_node()
		_set_status("Created '%s' — opening VN Editor." % path.get_file())
	elif not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		# Path was set manually but file doesn't exist — create it
		var abs_path: String = ProjectSettings.globalize_path(path)
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		var f := FileAccess.open(abs_path, FileAccess.WRITE)
		if f == null:
			_set_status("ERROR: Could not create '%s'." % path)
			return
		f.store_string("[]")
		f.close()
		_set_status("Created '%s' — opening VN Editor." % path.get_file())
	# Open VNEditor as overlay
	var vned: Control = load("res://scripts/VNEditor.gd").new()
	vned.name = "VNEditorOverlay"
	get_tree().current_scene.add_child(vned)
	vned.call_deferred("open_file", path)

func _on_apply_pressed() -> void:
	if _graph == null or _selected_node_id.is_empty():
		_set_status("Select a node first.")
		return
	var en: ExplorationNode = _graph.get_node_by_id(_selected_node_id)
	if en == null:
		return
	var old_id: String = en.id
	_collect_props(en)
	# If the ID changed, update references in other nodes and rename the GraphNode
	if en.id != old_id:
		_rename_node_references(old_id, en.id)
	# Refresh the GraphNode title
	var gn_node: GraphNode = _gn_map.get(old_id, null) as GraphNode
	if gn_node != null:
		gn_node.name  = en.id
		gn_node.title = en.id + "  [" + ExplorationNode.NodeType.keys()[en.node_type] + "]"
		_gn_map.erase(old_id)
		_gn_map[en.id] = gn_node
		_selected_node_id = en.id
	# Rebuild connections in GraphEdit to reflect any changes
	await get_tree().process_frame
	_rebuild_connections()
	_dirty = true
	_update_title()
	_set_status("Changes applied to node '%s'." % en.id)

# ─────────────────────────────────────────────────────────────
# Graph operations
# ─────────────────────────────────────────────────────────────

func _new_graph() -> void:
	_graph = ExplorationGraph.new()
	_graph.graph_id     = "new_graph"
	_graph.display_name = "New Graph"
	_graph_path = ""
	_dirty = false
	_selected_node_id = ""
	# Add a default start node
	var start := ExplorationNode.new()
	start.id            = "start"
	start.title         = "Starting Location"
	start.description   = "Describe this location here."
	start.node_type     = ExplorationNode.NodeType.HUB
	start.editor_position = Vector2(80, 200)
	_graph.nodes.append(start)
	_graph.start_node_id = "start"
	_rebuild_graph_edit()
	_update_title()
	_set_status("New graph created. Add nodes and save to a .json file.")

func _load_graph(path: String) -> void:
	var graph: ExplorationGraph = ExplorationGraph.load_from_file(path)
	if graph == null:
		_set_status("ERROR: Could not load '%s'." % path)
		return
	_graph      = graph
	_graph_path = path
	_dirty      = false
	_selected_node_id = ""
	_rebuild_graph_edit()
	_update_title()
	_set_status("Loaded '%s' (%d nodes)." % [path, graph.nodes.size()])

func _save_graph(path: String) -> void:
	if _graph == null:
		return
	if _graph.save_to_file(path):
		_graph_path = path
		_dirty = false
		_update_title()
		_create_vn_subfolder(path)
		_set_status("Saved to '%s'." % path)
	else:
		_set_status("ERROR: Could not save to '%s'." % path)

func _create_vn_subfolder(graph_path: String) -> void:
	var name: String = graph_path.get_file().get_basename()
	if name.is_empty():
		return
	var folder: String = "res://exploration/vn/vn_" + name
	var abs_path: String = ProjectSettings.globalize_path(folder)
	var err: Error = DirAccess.make_dir_recursive_absolute(abs_path)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_warning("ExplorationEditor: could not create VN subfolder '%s' (err %d)" % [folder, err])

func _next_unique_node_id() -> String:
	var existing: Dictionary = {}
	for n: ExplorationNode in _graph.nodes:
		existing[n.id] = true
	var i: int = 1
	while existing.has("node_%d" % i):
		i += 1
	return "node_%d" % i

func _add_new_node_at(position: Vector2) -> void:
	if _graph == null:
		return
	var en := ExplorationNode.new()
	en.id             = _next_unique_node_id()
	en.title          = "New Node"
	en.description    = "Describe this location."
	en.node_type      = ExplorationNode.NodeType.NORMAL
	en.editor_position = position
	_graph.nodes.append(en)
	_create_graph_node(en)
	_dirty = true
	_update_title()
	_set_status("Added node '%s'." % en.id)

func _delete_node(node_id: String) -> void:
	if _graph == null:
		return
	# Remove from graph
	for i: int in range(_graph.nodes.size() - 1, -1, -1):
		if _graph.nodes[i].id == node_id:
			_graph.nodes.remove_at(i)
			break
	# Remove connections pointing to this node from all other nodes
	for en: ExplorationNode in _graph.nodes:
		for i: int in range(en.connections.size() - 1, -1, -1):
			var conn: Variant = en.connections[i]
			if conn is Dictionary and str((conn as Dictionary).get("target", "")) == node_id:
				en.connections.remove_at(i)
	# Remove from GraphEdit
	var gn_node: GraphNode = _gn_map.get(node_id, null) as GraphNode
	if gn_node != null:
		_graph_edit.remove_child(gn_node)
		gn_node.queue_free()
		_gn_map.erase(node_id)
	_dirty = true
	_selected_node_id = ""
	_update_title()
	_rebuild_connections()
	_set_status("Deleted node '%s'." % node_id)

func _rename_node_references(old_id: String, new_id: String) -> void:
	if _graph == null or old_id == new_id:
		return
	if _graph.start_node_id == old_id:
		_graph.start_node_id = new_id
	for en: ExplorationNode in _graph.nodes:
		for conn: Variant in en.connections:
			if conn is Dictionary and str((conn as Dictionary).get("target", "")) == old_id:
				(conn as Dictionary)["target"] = new_id

# ─────────────────────────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────────────────────────

func _update_title() -> void:
	var title_str: String = "Exploration Editor"
	if _graph != null:
		title_str += " — " + (_graph.display_name if not _graph.display_name.is_empty() else _graph.graph_id)
	if _dirty:
		title_str += " *"
	if not _graph_path.is_empty():
		title_str += "  [%s]" % _graph_path.get_file()
	get_window().title = title_str

func _set_status(text: String) -> void:
	if _status_lbl != null:
		_status_lbl.text = text
	print("[ExplorationEditor] %s" % text)

func _show_popup(title: String, body: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title        = title
	dialog.dialog_text  = body
	dialog.size         = Vector2i(500, 300)
	add_child(dialog)
	dialog.popup_centered()

# ─────────────────────────────────────────────────────────────
# Input
# ─────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var ke := event as InputEventKey
		if ke.ctrl_pressed and ke.keycode == KEY_S:
			_on_save_pressed()
			get_viewport().set_input_as_handled()
		elif ke.keycode == KEY_DELETE and not _selected_node_id.is_empty():
			_on_delete_node_pressed()
			get_viewport().set_input_as_handled()
