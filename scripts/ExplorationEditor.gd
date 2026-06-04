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
var _prop_vn_edit:          LineEdit    = null
var _prop_music_edit:       LineEdit    = null
var _prop_connections_vbox: VBoxContainer = null
var _prop_events_in_vbox:   VBoxContainer = null
var _prop_events_out_vbox:  VBoxContainer = null

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
		PackedStringArray(["*.json ; JSON Files"]), "res://campaign/scenes")
	var edit_beats_btn := Button.new()
	edit_beats_btn.text = "Edit Beats ↗"
	edit_beats_btn.add_theme_font_size_override("font_size", 13)
	edit_beats_btn.pressed.connect(_on_edit_beats_pressed)
	vbox.add_child(edit_beats_btn)
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
		filters: PackedStringArray, start_dir: String) -> LineEdit:
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
	browse_btn.pressed.connect(func() -> void: _browse_for_file(edit, filters, start_dir))
	row.add_child(browse_btn)
	return edit

func _browse_for_file(target_edit: LineEdit, filters: PackedStringArray, start_dir: String) -> void:
	var dialog := FileDialog.new()
	dialog.file_mode   = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters     = filters
	dialog.access      = FileDialog.ACCESS_RESOURCES
	dialog.current_dir = start_dir
	dialog.file_selected.connect(func(path: String) -> void: target_edit.text = path)
	add_child(dialog)
	dialog.popup_centered(Vector2(900, 600))

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
	var _action_list: Array[String] = ["give_item","remove_item","set_var","give_credits","set_flag","show_message","play_sfx"]
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

	var val_edit := LineEdit.new()
	val_edit.text             = value
	val_edit.placeholder_text = "value"
	val_edit.add_theme_font_size_override("font_size", 12)
	val_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(val_edit)

	var del_btn := Button.new()
	del_btn.text = "x"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	del_btn.pressed.connect(row.queue_free)
	row.add_child(del_btn)

## Add one connection row to the connections VBox.
func _add_connection_row(conn_vbox: VBoxContainer, target: String = "",
		label_text: String = "Continue", hint: String = "") -> void:
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
	var add_cond_btn := Button.new()
	add_cond_btn.text = "+ Condition"
	add_cond_btn.add_theme_font_size_override("font_size", 11)
	add_cond_btn.pressed.connect(func() -> void: _add_condition_row(cond_vbox))
	vb.add_child(add_cond_btn)

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
	var _cond_list: Array[String] = ["has_item","not_has_item","var_equals","var_not_equals"]
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

	# Connections
	for child: Node in _prop_connections_vbox.get_children():
		child.queue_free()
	for conn: Variant in en.connections:
		if conn is Dictionary:
			var cd: Dictionary = conn as Dictionary
			_add_connection_row(_prop_connections_vbox,
				str(cd.get("target", "")),
				str(cd.get("label", "Continue")),
				str(cd.get("locked_hint", "")))
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
	en.music       = _prop_music_edit.text.strip_edges()

	# On-enter events
	en.on_enter_events.clear()
	en.on_enter_events = _collect_events(_prop_events_in_vbox)

	# On-exit events
	en.on_exit_events.clear()
	en.on_exit_events = _collect_events(_prop_events_out_vbox)

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
		var children: Array = (row as HBoxContainer).get_children()
		if children.size() < 4:
			continue
		var action_btn: OptionButton = children[0] as OptionButton
		var key_edit: LineEdit       = children[1] as LineEdit
		var val_edit: LineEdit       = children[2] as LineEdit
		result.append({
			"action": action_btn.get_item_text(action_btn.selected),
			"key":    key_edit.text,
			"value":  val_edit.text,
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
			var rc: Array = (row as HBoxContainer).get_children()
			if rc.size() < 4:
				continue
			conditions.append({
				"type":  (rc[0] as OptionButton).get_item_text((rc[0] as OptionButton).selected),
				"key":   (rc[1] as LineEdit).text,
				"value": (rc[2] as LineEdit).text,
			})

	return {
		"target":      target_edit.text.strip_edges() if target_edit != null else "",
		"label":       label_edit.text if label_edit != null else "Continue",
		"locked_hint": hint_edit.text  if hint_edit  != null else "",
		"conditions":  conditions,
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
	get_tree().change_scene_to_file("res://scenes/exploration_item_manager.tscn")

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
		_set_status("Enter a VN Scene path first.")
		return
	# Create empty beat file if it doesn't exist yet
	if not FileAccess.file_exists(path):
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
		_set_status("Saved to '%s'." % path)
	else:
		_set_status("ERROR: Could not save to '%s'." % path)

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
