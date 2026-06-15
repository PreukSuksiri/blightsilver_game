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
##   • Toolbar buttons: New, Load, Save, Add Node, Validate, Reward Report, Test Play.
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
const VN_TRIGGER_VALUES: Array[String] = ["on_enter", "on_exit", "on_var_change"]
const REWARD_REPORT_DIR: String = "res://logs/reports/"

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────

var _graph: ExplorationGraph = null          ## The graph being edited
var _graph_path: String = ""                 ## Path to the JSON file on disk
var _dirty: bool = false                     ## Unsaved changes exist
var _selected_node_id: String = ""           ## Currently selected ExplorationNode id

## Maps node_id → GraphNode widget
var _gn_map: Dictionary = {}

# ── Test-play params popup ─────────────────────────────────────
var _test_params_popup:   PopupPanel     = null
var _test_force_fresh_chk: CheckBox      = null
var _test_vars_vbox:      VBoxContainer  = null
var _test_inv_vbox:       VBoxContainer  = null

# ─────────────────────────────────────────────────────────────
# UI references
# ─────────────────────────────────────────────────────────────

var _graph_edit: GraphEdit = null
var _props_panel: Control  = null

# ── Properties panel fields ───────────────────────────────────
var _prop_start_node_edit:  LineEdit    = null
var _prop_start_cond_vbox:  VBoxContainer = null
var _prop_id_edit:          LineEdit    = null
var _prop_title_edit:       LineEdit    = null
var _prop_title_cond_vbox:  VBoxContainer = null
var _prop_desc_edit:        TextEdit    = null
var _prop_desc_cond_vbox:   VBoxContainer = null
var _prop_type_btn:         OptionButton = null
var _prop_bg_edit:          LineEdit    = null
var _prop_bg_cond_vbox:     VBoxContainer = null
var _prop_vn_edit:            LineEdit    = null
var _prop_vn_cond_vbox:       VBoxContainer = null
var _prop_vn_trigger_btn:     OptionButton = null
var _prop_vn_var_trigger_panel: VBoxContainer = null
var _prop_vn_trigger_var_edit: LineEdit   = null
var _prop_vn_trigger_eq_edit:  LineEdit   = null
var _prop_vn_play_once_chk:   CheckBox    = null
var _prop_vn_keep_bgm_chk:    CheckBox    = null
var _prop_vn_after_vbox:    VBoxContainer = null
var _prop_show_info_chk:      CheckBox    = null
var _prop_show_who_chk:       CheckBox    = null
var _prop_music_edit:       LineEdit    = null
var _prop_music_cond_vbox:  VBoxContainer = null
var _prop_battle_section:   VBoxContainer = null
var _prop_battle_bgm_edit:  LineEdit    = null
var _prop_setup_bgm_edit:   LineEdit    = null
var _prop_almost_win_bgm_edit: LineEdit = null
var _prop_battle_bgm_vol:   SpinBox     = null
var _prop_connections_vbox: VBoxContainer = null
var _prop_events_in_vbox:       VBoxContainer = null
var _prop_events_in_cond_vbox:  VBoxContainer = null
var _prop_events_out_vbox:      VBoxContainer = null
var _prop_events_out_cond_vbox: VBoxContainer = null
var _prop_characters_vbox:  VBoxContainer = null
var _prop_spots_vbox:       VBoxContainer = null
var _spot_picker_window:    Window        = null

# ── Status bar ────────────────────────────────────────────────
var _status_lbl: Label = null

# ── Persistent file dialogs ───────────────────────────────────
var _load_dialog: FileDialog = null
var _save_dialog: FileDialog = null
var _new_confirm_dialog: ConfirmationDialog = null

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
	_build_test_params_popup()
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
	_status_lbl.add_theme_font_override("font", FontManager.make_font("primary", 400))
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

	_new_confirm_dialog = ConfirmationDialog.new()
	_new_confirm_dialog.title = "New Graph"
	_new_confirm_dialog.dialog_text = (
		"Create a new graph?\n\nUnsaved changes to the current graph will be lost.")
	_new_confirm_dialog.ok_button_text = "New Graph"
	_new_confirm_dialog.cancel_button_text = "Cancel"
	_new_confirm_dialog.confirmed.connect(_new_graph)
	add_child(_new_confirm_dialog)

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
	_make_tool_btn(bar, "📋 Reward Report", _on_reward_report_pressed)
	_make_tool_btn(bar, "▶ Test Play",_on_test_play_pressed)
	bar.add_child(VSeparator.new())
	_make_tool_btn(bar, "🗃 Items",   _on_items_pressed)
	_make_tool_btn(bar, "🧩 Puzzles", _on_puzzles_pressed)
	bar.add_child(VSeparator.new())
	_make_tool_btn(bar, "← Back",     _on_back_pressed)

	return panel   # bar is a child of panel; we return panel as the toolbar Control

func _make_tool_btn(parent: Control, label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_override("font", FontManager.make_font("primary", 400))
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

	# Section: Graph
	_add_section_header(vbox, "GRAPH")
	_prop_start_node_edit = _add_field(vbox, "Start Node ID", "start")
	_add_section_header(vbox, "CONDITIONAL START NODE")
	_prop_start_cond_vbox = VBoxContainer.new()
	_prop_start_cond_vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(_prop_start_cond_vbox)
	var add_start_cond_btn := Button.new()
	add_start_cond_btn.text = "+ Add Condition"
	add_start_cond_btn.add_theme_font_size_override("font_size", 13)
	add_start_cond_btn.pressed.connect(func() -> void: _add_node_id_cond_row(_prop_start_cond_vbox))
	vbox.add_child(add_start_cond_btn)
	vbox.add_child(HSeparator.new())

	# Section: Node Identity
	_add_section_header(vbox, "NODE IDENTITY")
	_prop_id_edit    = _add_field(vbox, "ID", "node_id")
	var copy_loc_row := HBoxContainer.new()
	copy_loc_row.add_theme_constant_override("separation", 6)
	vbox.add_child(copy_loc_row)
	var copy_loc_btn := Button.new()
	copy_loc_btn.text = "📋 Copy Graph + Node ID"
	copy_loc_btn.add_theme_font_size_override("font_size", 12)
	copy_loc_btn.tooltip_text = "Copy graph file name and node ID for bug reports"
	copy_loc_btn.pressed.connect(_on_copy_bug_loc_pressed)
	copy_loc_row.add_child(copy_loc_btn)
	_prop_title_edit = _add_field(vbox, "Title", "")
	_add_section_header(vbox, "CONDITIONAL TITLE")
	_prop_title_cond_vbox = VBoxContainer.new()
	_prop_title_cond_vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(_prop_title_cond_vbox)
	var add_title_cond_btn := Button.new()
	add_title_cond_btn.text = "+ Add Condition"
	add_title_cond_btn.add_theme_font_size_override("font_size", 13)
	add_title_cond_btn.pressed.connect(func() -> void: _add_text_cond_row(_prop_title_cond_vbox, false))
	vbox.add_child(add_title_cond_btn)
	_prop_type_btn   = _add_type_dropdown(vbox)
	_prop_type_btn.item_selected.connect(func(_idx: int) -> void: _update_battle_section_visibility())
	vbox.add_child(HSeparator.new())

	# Battle BGM (BATTLE nodes only)
	_prop_battle_section = VBoxContainer.new()
	_prop_battle_section.add_theme_constant_override("separation", 4)
	vbox.add_child(_prop_battle_section)
	_add_section_header(_prop_battle_section, "BATTLE BGM")
	var battle_hint := Label.new()
	battle_hint.text = "Used when this BATTLE node starts a grid duel. Blank paths use manage_bgm defaults (battle / placement / almost_win)."
	battle_hint.add_theme_font_size_override("font_size", 11)
	battle_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	battle_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prop_battle_section.add_child(battle_hint)
	var audio_filters := PackedStringArray(["*.mp3,*.ogg,*.wav ; Audio Files"])
	_prop_battle_bgm_edit = _add_file_field(_prop_battle_section, "Battle BGM",
		audio_filters, "res://assets/audio")
	_prop_setup_bgm_edit = _add_file_field(_prop_battle_section, "Setup BGM",
		audio_filters, "res://assets/audio")
	_prop_almost_win_bgm_edit = _add_file_field(_prop_battle_section, "Almost-win BGM",
		audio_filters, "res://assets/audio")
	var vol_lbl := Label.new()
	vol_lbl.text = "BGM Volume"
	vol_lbl.add_theme_font_size_override("font_size", 13)
	vol_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
	_prop_battle_section.add_child(vol_lbl)
	_prop_battle_bgm_vol = SpinBox.new()
	_prop_battle_bgm_vol.min_value = 0.0
	_prop_battle_bgm_vol.max_value = 200.0
	_prop_battle_bgm_vol.step = 1.0
	_prop_battle_bgm_vol.value = 100.0
	_prop_battle_bgm_vol.add_theme_font_size_override("font_size", 14)
	_prop_battle_section.add_child(_prop_battle_bgm_vol)
	_update_battle_section_visibility()

	# Section: Content
	_add_section_header(vbox, "CONTENT")
	_prop_desc_edit  = _add_textarea(vbox, "Description")
	_add_section_header(vbox, "CONDITIONAL DESCRIPTION")
	_prop_desc_cond_vbox = VBoxContainer.new()
	_prop_desc_cond_vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(_prop_desc_cond_vbox)
	var add_desc_cond_btn := Button.new()
	add_desc_cond_btn.text = "+ Add Condition"
	add_desc_cond_btn.add_theme_font_size_override("font_size", 13)
	add_desc_cond_btn.pressed.connect(func() -> void: _add_text_cond_row(_prop_desc_cond_vbox, true))
	vbox.add_child(add_desc_cond_btn)
	_prop_bg_edit    = _add_file_field(vbox, "Background (res:// path)",
		PackedStringArray(["*.png,*.jpg,*.jpeg ; Images"]), "res://assets/textures")
	var bg_preview_btn := Button.new()
	bg_preview_btn.text = "Preview"
	bg_preview_btn.custom_minimum_size = Vector2(60, 0)
	bg_preview_btn.add_theme_font_size_override("font_size", 13)
	bg_preview_btn.pressed.connect(func() -> void: _preview_image(_prop_bg_edit.text.strip_edges()))
	_prop_bg_edit.get_parent().add_child(bg_preview_btn)

	# Conditional background overrides
	_add_section_header(vbox, "CONDITIONAL BACKGROUND")
	_prop_bg_cond_vbox = VBoxContainer.new()
	_prop_bg_cond_vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(_prop_bg_cond_vbox)
	var add_bg_cond_btn := Button.new()
	add_bg_cond_btn.text = "+ Add Condition"
	add_bg_cond_btn.add_theme_font_size_override("font_size", 13)
	add_bg_cond_btn.pressed.connect(func() -> void: _add_media_cond_row(_prop_bg_cond_vbox, true))
	vbox.add_child(add_bg_cond_btn)

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
	_prop_vn_keep_bgm_chk = CheckBox.new()
	_prop_vn_keep_bgm_chk.text = "Keep Exploration BGM (VN won't change music)"
	_prop_vn_keep_bgm_chk.button_pressed = true
	_prop_vn_keep_bgm_chk.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_prop_vn_keep_bgm_chk)

	var vn_trigger_lbl := Label.new()
	vn_trigger_lbl.text = "VN Trigger"
	vn_trigger_lbl.add_theme_font_size_override("font_size", 13)
	vn_trigger_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
	vbox.add_child(vn_trigger_lbl)
	_prop_vn_trigger_btn = OptionButton.new()
	_prop_vn_trigger_btn.add_item("On Enter")
	_prop_vn_trigger_btn.add_item("On Exit")
	_prop_vn_trigger_btn.add_item("On Variable Change")
	_prop_vn_trigger_btn.add_theme_font_size_override("font_size", 14)
	_prop_vn_trigger_btn.item_selected.connect(_on_vn_trigger_changed)
	vbox.add_child(_prop_vn_trigger_btn)

	_prop_vn_var_trigger_panel = VBoxContainer.new()
	_prop_vn_var_trigger_panel.add_theme_constant_override("separation", 4)
	vbox.add_child(_prop_vn_var_trigger_panel)
	var trig_var_lbl := Label.new()
	trig_var_lbl.text = "Watch Variable"
	trig_var_lbl.add_theme_font_size_override("font_size", 12)
	trig_var_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
	_prop_vn_var_trigger_panel.add_child(trig_var_lbl)
	_prop_vn_trigger_var_edit = LineEdit.new()
	_prop_vn_trigger_var_edit.placeholder_text = "variable key (empty = any var)"
	_prop_vn_trigger_var_edit.add_theme_font_size_override("font_size", 14)
	_prop_vn_var_trigger_panel.add_child(_prop_vn_trigger_var_edit)
	var trig_eq_lbl := Label.new()
	trig_eq_lbl.text = "Equals Value"
	trig_eq_lbl.add_theme_font_size_override("font_size", 12)
	trig_eq_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
	_prop_vn_var_trigger_panel.add_child(trig_eq_lbl)
	_prop_vn_trigger_eq_edit = LineEdit.new()
	_prop_vn_trigger_eq_edit.placeholder_text = "value (empty = any value)"
	_prop_vn_trigger_eq_edit.add_theme_font_size_override("font_size", 14)
	_prop_vn_var_trigger_panel.add_child(_prop_vn_trigger_eq_edit)
	var trig_hint := _make_kv_hint_label()
	trig_hint.text = "Plays vn_scene while the player is on this node when the watched variable changes to the equals value."
	_prop_vn_var_trigger_panel.add_child(trig_hint)
	_prop_vn_var_trigger_panel.visible = false

	_add_section_header(vbox, "CONDITIONAL VN SCENE")
	_prop_vn_cond_vbox = VBoxContainer.new()
	_prop_vn_cond_vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(_prop_vn_cond_vbox)
	var add_vn_cond_btn := Button.new()
	add_vn_cond_btn.text = "+ Add Condition"
	add_vn_cond_btn.add_theme_font_size_override("font_size", 13)
	add_vn_cond_btn.pressed.connect(func() -> void:
		_add_path_cond_row(_prop_vn_cond_vbox,
			PackedStringArray(["*.json ; JSON Files"]), "res://exploration/vn",
			"", "", "", Callable(), true))
	vbox.add_child(add_vn_cond_btn)

	_add_section_header(vbox, "AFTER VN ACTIONS (default — when no condition matches)")
	_prop_vn_after_vbox = VBoxContainer.new()
	_prop_vn_after_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(_prop_vn_after_vbox)
	var add_vn_after_btn := Button.new()
	add_vn_after_btn.text = "+ Add Action"
	add_vn_after_btn.add_theme_font_size_override("font_size", 13)
	add_vn_after_btn.pressed.connect(func() -> void: _add_spot_action_row(_prop_vn_after_vbox))
	vbox.add_child(add_vn_after_btn)

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

	# Conditional music overrides
	_add_section_header(vbox, "CONDITIONAL MUSIC")
	_prop_music_cond_vbox = VBoxContainer.new()
	_prop_music_cond_vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(_prop_music_cond_vbox)
	var add_music_cond_btn := Button.new()
	add_music_cond_btn.text = "+ Add Condition"
	add_music_cond_btn.add_theme_font_size_override("font_size", 13)
	add_music_cond_btn.pressed.connect(func() -> void: _add_media_cond_row(_prop_music_cond_vbox, false))
	vbox.add_child(add_music_cond_btn)

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
	_add_section_header(vbox, "CONDITIONAL ON-ENTER EVENTS")
	_prop_events_in_cond_vbox = VBoxContainer.new()
	_prop_events_in_cond_vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(_prop_events_in_cond_vbox)
	var add_enter_cond_btn := Button.new()
	add_enter_cond_btn.text = "+ Add Condition"
	add_enter_cond_btn.add_theme_font_size_override("font_size", 13)
	add_enter_cond_btn.pressed.connect(func() -> void: _add_events_cond_row(_prop_events_in_cond_vbox))
	vbox.add_child(add_enter_cond_btn)
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
	_add_section_header(vbox, "CONDITIONAL ON-EXIT EVENTS")
	_prop_events_out_cond_vbox = VBoxContainer.new()
	_prop_events_out_cond_vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(_prop_events_out_cond_vbox)
	var add_exit_cond_btn := Button.new()
	add_exit_cond_btn.text = "+ Add Condition"
	add_exit_cond_btn.add_theme_font_size_override("font_size", 13)
	add_exit_cond_btn.pressed.connect(func() -> void: _add_events_cond_row(_prop_events_out_cond_vbox))
	vbox.add_child(add_exit_cond_btn)
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

func _make_var_cond_frame(cond_vbox: VBoxContainer, var_key: String = "", equals: String = "") -> Dictionary:
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.18)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.35, 0.50, 0.80, 0.45)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 6.0; sb.content_margin_right  = 6.0
	sb.content_margin_top  = 4.0; sb.content_margin_bottom = 4.0
	frame.add_theme_stylebox_override("panel", sb)
	cond_vbox.add_child(frame)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	frame.add_child(vb)

	var cond_row := HBoxContainer.new()
	cond_row.add_theme_constant_override("separation", 4)
	vb.add_child(cond_row)

	var var_lbl := Label.new()
	var_lbl.text = "var"
	var_lbl.add_theme_font_size_override("font_size", 11)
	var_lbl.add_theme_color_override("font_color", Color(0.55, 0.70, 0.90))
	cond_row.add_child(var_lbl)

	var key_edit := LineEdit.new()
	key_edit.text             = var_key
	key_edit.placeholder_text = "variable key"
	key_edit.add_theme_font_size_override("font_size", 12)
	key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cond_row.add_child(key_edit)

	var eq_lbl := Label.new()
	eq_lbl.text = "="
	eq_lbl.add_theme_font_size_override("font_size", 11)
	cond_row.add_child(eq_lbl)

	var eq_edit := LineEdit.new()
	eq_edit.text             = equals
	eq_edit.placeholder_text = "value"
	eq_edit.add_theme_font_size_override("font_size", 12)
	eq_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cond_row.add_child(eq_edit)

	return {"frame": frame, "vb": vb, "key_edit": key_edit, "eq_edit": eq_edit}

## Add one conditional background/music row.
func _add_media_cond_row(cond_vbox: VBoxContainer, is_image: bool,
		var_key: String = "", equals: String = "", path: String = "") -> void:
	var filters: PackedStringArray = PackedStringArray(["*.png,*.jpg,*.jpeg ; Images"]) if is_image \
		else PackedStringArray(["*.mp3,*.ogg,*.wav ; Audio Files"])
	var browse_dir: String = "res://assets/textures" if is_image else "res://assets/audio"
	_add_path_cond_row(cond_vbox, filters, browse_dir, var_key, equals, path)

## Conditional path row: var = equals → path.
func _add_path_cond_row(cond_vbox: VBoxContainer, filters: PackedStringArray, start_dir: String,
		var_key: String = "", equals: String = "", path: String = "",
		custom_browse: Callable = Callable(), edit_beats: bool = false,
		cond_play_once: bool = true, after_actions: Array = []) -> void:
	var parts: Dictionary = _make_var_cond_frame(cond_vbox, var_key, equals)
	var frame: PanelContainer = parts["frame"] as PanelContainer
	var vb: VBoxContainer = parts["vb"] as VBoxContainer
	var key_edit: LineEdit = parts["key_edit"] as LineEdit
	var eq_edit: LineEdit = parts["eq_edit"] as LineEdit

	var path_row := HBoxContainer.new()
	path_row.add_theme_constant_override("separation", 4)
	vb.add_child(path_row)

	var path_lbl := Label.new()
	path_lbl.text = "→"
	path_lbl.add_theme_font_override("font", FontManager.make_font("primary", 400))
	path_lbl.add_theme_font_size_override("font_size", 11)
	path_lbl.add_theme_color_override("font_color", Color(0.55, 0.90, 0.60))
	path_row.add_child(path_lbl)

	var path_edit := LineEdit.new()
	path_edit.text             = path
	path_edit.placeholder_text = "res:// path"
	path_edit.add_theme_font_size_override("font_size", 12)
	path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_row.add_child(path_edit)

	var browse_btn := Button.new()
	browse_btn.text = "…"
	browse_btn.custom_minimum_size = Vector2(28.0, 0.0)
	browse_btn.add_theme_font_size_override("font_size", 12)
	if custom_browse.is_valid():
		browse_btn.pressed.connect(custom_browse)
	else:
		browse_btn.pressed.connect(func() -> void: _browse_for_file(path_edit, filters, start_dir))
	path_row.add_child(browse_btn)

	if edit_beats:
		var beats_btn := Button.new()
		beats_btn.text = "Edit Beats ↗"
		beats_btn.add_theme_font_size_override("font_size", 11)
		beats_btn.pressed.connect(func() -> void:
			_on_edit_cond_vn_beats_pressed(path_edit, key_edit, eq_edit))
		path_row.add_child(beats_btn)

		var play_once_row := HBoxContainer.new()
		vb.add_child(play_once_row)
		var play_once_chk := CheckBox.new()
		play_once_chk.text = "Play Once"
		play_once_chk.button_pressed = cond_play_once
		play_once_chk.add_theme_font_size_override("font_size", 12)
		play_once_row.add_child(play_once_chk)
		frame.set_meta("play_once_chk", play_once_chk)

		var after_hdr := Label.new()
		after_hdr.text = "After VN actions (this condition only; empty = use default below):"
		after_hdr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		after_hdr.add_theme_font_size_override("font_size", 11)
		after_hdr.add_theme_color_override("font_color", Color(0.65, 0.80, 0.65))
		vb.add_child(after_hdr)
		var after_vbox := VBoxContainer.new()
		after_vbox.add_theme_constant_override("separation", 4)
		vb.add_child(after_vbox)
		for act: Variant in after_actions:
			if act is Dictionary:
				var ad: Dictionary = act as Dictionary
				_add_spot_action_row(after_vbox,
					str(ad.get("action", "show_message")),
					str(ad.get("key", "")),
					str(ad.get("value", "")),
					bool(ad.get("play_once", true)))
		var add_after_btn := Button.new()
		add_after_btn.text = "+ Add Action"
		add_after_btn.add_theme_font_size_override("font_size", 11)
		add_after_btn.pressed.connect(func() -> void: _add_spot_action_row(after_vbox))
		vb.add_child(add_after_btn)
		frame.set_meta("after_actions_vbox", after_vbox)

	var del_btn := Button.new()
	del_btn.text = "x"
	del_btn.custom_minimum_size = Vector2(24.0, 0.0)
	del_btn.add_theme_font_size_override("font_size", 12)
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	del_btn.pressed.connect(frame.queue_free)
	path_row.add_child(del_btn)

	frame.set_meta("key_edit",  key_edit)
	frame.set_meta("eq_edit",   eq_edit)
	frame.set_meta("path_edit", path_edit)

## Conditional text row: var = equals → value (title/description).
func _add_text_cond_row(cond_vbox: VBoxContainer, multiline: bool,
		var_key: String = "", equals: String = "", value: String = "") -> void:
	var parts: Dictionary = _make_var_cond_frame(cond_vbox, var_key, equals)
	var frame: PanelContainer = parts["frame"] as PanelContainer
	var vb: VBoxContainer = parts["vb"] as VBoxContainer
	var key_edit: LineEdit = parts["key_edit"] as LineEdit
	var eq_edit: LineEdit = parts["eq_edit"] as LineEdit

	var value_row := HBoxContainer.new()
	value_row.add_theme_constant_override("separation", 4)
	vb.add_child(value_row)

	var value_lbl := Label.new()
	value_lbl.text = "→"
	value_lbl.add_theme_font_override("font", FontManager.make_font("primary", 400))
	value_lbl.add_theme_font_size_override("font_size", 11)
	value_lbl.add_theme_color_override("font_color", Color(0.55, 0.90, 0.60))
	value_row.add_child(value_lbl)

	var value_edit: Control
	if multiline:
		var te := TextEdit.new()
		te.text = value
		te.placeholder_text = "description text"
		te.custom_minimum_size = Vector2(0.0, 64.0)
		te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		te.add_theme_font_size_override("font_size", 12)
		value_edit = te
	else:
		var le := LineEdit.new()
		le.text = value
		le.placeholder_text = "title text"
		le.add_theme_font_size_override("font_size", 12)
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_edit = le
	value_row.add_child(value_edit)

	var del_btn := Button.new()
	del_btn.text = "x"
	del_btn.custom_minimum_size = Vector2(24.0, 0.0)
	del_btn.add_theme_font_size_override("font_size", 12)
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	del_btn.pressed.connect(frame.queue_free)
	value_row.add_child(del_btn)

	frame.set_meta("key_edit",   key_edit)
	frame.set_meta("eq_edit",    eq_edit)
	frame.set_meta("value_edit", value_edit)

## Conditional node-id row: var = equals → node_id (for graph start node).
func _add_node_id_cond_row(cond_vbox: VBoxContainer,
		var_key: String = "", equals: String = "", node_id: String = "") -> void:
	var parts: Dictionary = _make_var_cond_frame(cond_vbox, var_key, equals)
	var frame: PanelContainer = parts["frame"] as PanelContainer
	var vb: VBoxContainer = parts["vb"] as VBoxContainer
	var key_edit: LineEdit = parts["key_edit"] as LineEdit
	var eq_edit: LineEdit = parts["eq_edit"] as LineEdit

	var id_row := HBoxContainer.new()
	id_row.add_theme_constant_override("separation", 4)
	vb.add_child(id_row)

	var id_lbl := Label.new()
	id_lbl.text = "→"
	id_lbl.add_theme_font_override("font", FontManager.make_font("primary", 400))
	id_lbl.add_theme_font_size_override("font_size", 11)
	id_lbl.add_theme_color_override("font_color", Color(0.55, 0.90, 0.60))
	id_row.add_child(id_lbl)

	var node_id_edit := LineEdit.new()
	node_id_edit.text             = node_id
	node_id_edit.placeholder_text = "node_id"
	node_id_edit.add_theme_font_size_override("font_size", 12)
	node_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	id_row.add_child(node_id_edit)

	var del_btn := Button.new()
	del_btn.text = "x"
	del_btn.custom_minimum_size = Vector2(24.0, 0.0)
	del_btn.add_theme_font_size_override("font_size", 12)
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	del_btn.pressed.connect(frame.queue_free)
	id_row.add_child(del_btn)

	frame.set_meta("key_edit",      key_edit)
	frame.set_meta("eq_edit",       eq_edit)
	frame.set_meta("node_id_edit",  node_id_edit)

## Conditional events row: var = equals → event list.
func _add_events_cond_row(cond_vbox: VBoxContainer,
		var_key: String = "", equals: String = "", events: Array = []) -> void:
	var parts: Dictionary = _make_var_cond_frame(cond_vbox, var_key, equals)
	var frame: PanelContainer = parts["frame"] as PanelContainer
	var vb: VBoxContainer = parts["vb"] as VBoxContainer
	var key_edit: LineEdit = parts["key_edit"] as LineEdit
	var eq_edit: LineEdit = parts["eq_edit"] as LineEdit

	var events_vbox := VBoxContainer.new()
	events_vbox.add_theme_constant_override("separation", 4)
	vb.add_child(events_vbox)

	for ev: Variant in events:
		if ev is Dictionary:
			var d: Dictionary = ev as Dictionary
			_add_event_row(events_vbox,
				str(d.get("action", "show_message")),
				str(d.get("key", "")),
				str(d.get("value", "")))

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 4)
	vb.add_child(btn_row)

	var add_ev_btn := Button.new()
	add_ev_btn.text = "+ Add Event"
	add_ev_btn.add_theme_font_size_override("font_size", 12)
	add_ev_btn.pressed.connect(func() -> void: _add_event_row(events_vbox))
	btn_row.add_child(add_ev_btn)

	var del_btn := Button.new()
	del_btn.text = "x"
	del_btn.add_theme_font_size_override("font_size", 12)
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	del_btn.pressed.connect(frame.queue_free)
	btn_row.add_child(del_btn)

	frame.set_meta("key_edit",     key_edit)
	frame.set_meta("eq_edit",      eq_edit)
	frame.set_meta("events_vbox",  events_vbox)

func _vn_trigger_index(trigger: String) -> int:
	var idx: int = VN_TRIGGER_VALUES.find(trigger)
	return idx if idx >= 0 else 0

func _on_vn_trigger_changed(_idx: int) -> void:
	if _prop_vn_var_trigger_panel != null and _prop_vn_trigger_btn != null:
		_prop_vn_var_trigger_panel.visible = (_prop_vn_trigger_btn.selected == 2)

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

## Open a searchable puzzle picker. On selection sets target_edit.text to puzzle id.
func _open_puzzle_picker(target_edit: LineEdit) -> void:
	var win := Window.new()
	win.title = "Pick Puzzle"
	win.size  = Vector2i(520, 580)
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
	search.placeholder_text = "Search by name or id..."
	search.add_theme_font_size_override("font_size", 14)
	vbox.add_child(search)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(list_vbox)

	var all_puzzles: Array = ExplorationPuzzleDatabase.all_puzzles()

	var refresh := func(filter: String) -> void:
		for c: Node in list_vbox.get_children():
			c.queue_free()
		var f: String = filter.strip_edges().to_lower()
		for entry: Variant in all_puzzles:
			if not entry is Dictionary:
				continue
			var d: Dictionary = entry as Dictionary
			var pid: String    = str(d.get("id",   ""))
			var pname: String  = str(d.get("name", pid))
			var guide: String  = str(d.get("params_guide", ""))
			var implemented: bool = ExplorationPuzzleDatabase.is_implemented(pid)
			var status: String = "Implemented" if implemented else "Not implemented"
			if not f.is_empty() \
					and not pid.to_lower().contains(f) \
					and not pname.to_lower().contains(f):
				continue

			# Entry wrapper
			var entry_vbox := VBoxContainer.new()
			entry_vbox.add_theme_constant_override("separation", 2)
			entry_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			list_vbox.add_child(entry_vbox)

			# Puzzle button (name + id + status)
			var btn := Button.new()
			btn.text = "%s  [%s]  —  %s" % [pname, pid, status]
			btn.flat = true
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", 13)
			if implemented:
				btn.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
			else:
				btn.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
			var cap_id: String = pid
			btn.pressed.connect(func() -> void:
				target_edit.text = cap_id
				win.queue_free())
			entry_vbox.add_child(btn)

			# Parameter guide label
			var guide_lbl := Label.new()
			guide_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			guide_lbl.add_theme_font_size_override("font_size", 11)
			if not implemented:
				var suffix: String = ("\n" + guide) if not guide.is_empty() else ""
				guide_lbl.text = "  ⚠ Not implemented yet.%s" % suffix
				guide_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.25))
			elif guide.is_empty():
				guide_lbl.text = "  ℹ No parameter guide defined."
				guide_lbl.add_theme_color_override("font_color", Color(0.50, 0.55, 0.65))
			else:
				guide_lbl.text = "  " + guide.replace("\n", "\n  ")
				guide_lbl.add_theme_color_override("font_color", Color(0.60, 0.85, 0.65))
			entry_vbox.add_child(guide_lbl)

			entry_vbox.add_child(HSeparator.new())

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

func _update_battle_section_visibility() -> void:
	if _prop_battle_section == null or _prop_type_btn == null:
		return
	_prop_battle_section.visible = _prop_type_btn.selected == ExplorationNode.NodeType.BATTLE

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

func _make_kv_hint_label() -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

func _find_kv_row_node(node: Node) -> HBoxContainer:
	if node is HBoxContainer:
		return node as HBoxContainer
	if node is VBoxContainer:
		for c: Node in (node as VBoxContainer).get_children():
			if c is HBoxContainer:
				return c as HBoxContainer
	return null

func _event_action_kv_hint(action: String) -> String:
	match action:
		"give_item":
			return "key: item id to add. value: unused (or item id if key is empty)."
		"remove_item":
			return "key: item id to remove. value: unused (or item id if key is empty)."
		"set_var":
			return "key: session variable name. value: value to set."
		"give_credits":
			return "key: credit amount if value is empty, or optional mail subject if value is the amount. value: credit amount (integer)."
		"give_booster_pack":
			return "key: optional mail subject override. value: booster pack id or name."
		"give_union_scroll":
			return "key: optional mail subject override (or count if value empty). value: scroll count (integer, default 1)."
		"set_flag":
			return "key: carry-over flag name. value: flag value (saved on session end)."
		"show_message":
			return "key: unused. value: toast message text shown to the player."
		"play_sfx":
			return "key: unused. value: res:// path to audio file."
		_:
			return ""

func _spot_action_kv_hint(action: String) -> String:
	var base: String = _event_action_kv_hint(action)
	if not base.is_empty():
		return base
	match action:
		"play_vn":
			return "key: unused. value: res:// path to VN beat JSON. Play Once skips if already seen."
		"navigate_to":
			return "key: unused. value: target node id to navigate to."
		"play_puzzle":
			return "key: puzzle params (JSON or text). value: puzzle id."
		_:
			return ""

func _condition_kv_hint(ctype: String) -> String:
	match ctype:
		"has_item":
			return "key: item id the player must have. value: unused."
		"not_has_item":
			return "key: item id the player must not have. value: unused."
		"var_equals":
			return "key: session variable name. value: exact string it must equal."
		"var_not_equals":
			return "key: session variable name. value: string it must not equal."
		"var_greater":
			return "key: session variable name. value: numeric threshold (var > value)."
		"var_less":
			return "key: session variable name. value: numeric threshold (var < value)."
		"at_node":
			return "key: node id (fallback). value: node id player must be at (preferred)."
		_:
			return ""

func _add_kv_row_block(parent: VBoxContainer) -> Dictionary:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 2)
	parent.add_child(block)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	block.add_child(row)
	var hint_lbl := _make_kv_hint_label()
	block.add_child(hint_lbl)
	return {"block": block, "row": row, "hint": hint_lbl}

func _collect_conditions_from_vbox(cond_vbox: VBoxContainer) -> Array:
	var result: Array = []
	for child: Node in cond_vbox.get_children():
		var row: HBoxContainer = _find_kv_row_node(child)
		if row == null:
			continue
		var ob: OptionButton = null
		var les: Array[LineEdit] = []
		for c: Node in row.get_children():
			if c is OptionButton and ob == null:
				ob = c as OptionButton
			elif c is LineEdit:
				les.append(c as LineEdit)
		if ob == null or les.size() < 2:
			continue
		result.append({
			"type":  ob.get_item_text(ob.selected),
			"key":   les[0].text,
			"value": les[1].text,
		})
	return result

## Add one event row to an events VBox.
## Row format: [action OptionButton] [key LineEdit] [value LineEdit] [x Button]
func _add_event_row(events_vbox: VBoxContainer, action: String = "show_message",
		key: String = "", value: String = "") -> void:
	var block_parts: Dictionary = _add_kv_row_block(events_vbox)
	var block: VBoxContainer = block_parts["block"] as VBoxContainer
	var row: HBoxContainer = block_parts["row"] as HBoxContainer
	var hint_lbl: Label = block_parts["hint"] as Label

	var action_btn := OptionButton.new()
	var _action_list: Array[String] = [
		"give_item", "give_booster_pack", "give_union_scroll", "remove_item", "set_var",
		"give_credits", "set_flag", "show_message", "play_sfx", "end_exploration", "end_exploration_vn"]
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

	var event_vn_browse_btn := Button.new()
	event_vn_browse_btn.text = "…"
	event_vn_browse_btn.tooltip_text = "Browse VN JSON (fills value field)"
	event_vn_browse_btn.custom_minimum_size = Vector2(28.0, 0.0)
	event_vn_browse_btn.pressed.connect(func() -> void:
		_browse_for_file(val_edit, PackedStringArray(["*.json ; JSON Files"]), "res://exploration"))
	row.add_child(event_vn_browse_btn)

	# Show only the relevant picker button based on the selected action.
	var _update_event_pickers := func(sel_idx: int) -> void:
		var sel: String = _action_list[sel_idx]
		item_pick_btn.visible       = sel in ["give_item", "remove_item"]
		pack_pick_btn.visible       = sel == "give_booster_pack"
		event_vn_browse_btn.visible = sel == "end_exploration_vn"
		hint_lbl.text = _event_action_kv_hint(sel)
	action_btn.item_selected.connect(_update_event_pickers)
	_update_event_pickers.call(action_btn.selected)

	var del_btn := Button.new()
	del_btn.text = "x"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	del_btn.pressed.connect(block.queue_free)
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
	target_lbl.add_theme_font_override("font", FontManager.make_font("primary", 400))
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
	frame.set_meta("cond_vbox", cond_vbox)   # used by _find_cond_vbox

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
	var block_parts: Dictionary = _add_kv_row_block(cond_vbox)
	var block: VBoxContainer = block_parts["block"] as VBoxContainer
	var row: HBoxContainer = block_parts["row"] as HBoxContainer
	var hint_lbl: Label = block_parts["hint"] as Label

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

	var _update_condition_hint := func(sel_idx: int) -> void:
		var sel: String = _cond_list[sel_idx]
		cond_pick_btn.visible = sel in ["has_item", "not_has_item"]
		hint_lbl.text = _condition_kv_hint(sel)
	type_btn.item_selected.connect(_update_condition_hint)
	_update_condition_hint.call(type_btn.selected)

	var del_btn := Button.new()
	del_btn.text = "x"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	del_btn.pressed.connect(block.queue_free)
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

	# Remove from room after talked (index 4)
	var remove_after_chk := CheckBox.new()
	remove_after_chk.text = "Remove from room after talked"
	remove_after_chk.button_pressed = bool(char_data.get("remove_after_talk", false))
	remove_after_chk.add_theme_font_size_override("font_size", 12)
	vb.add_child(remove_after_chk)

	# Thumbnail row (index 5)
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

	# After-talk actions (same action types as investigable points)
	var acts_hdr := Label.new()
	acts_hdr.text = "After Talk Actions (run when dialogue ends):"
	acts_hdr.add_theme_font_size_override("font_size", 11)
	acts_hdr.add_theme_color_override("font_color", Color(0.65, 0.80, 0.65))
	vb.add_child(acts_hdr)
	var acts_vbox := VBoxContainer.new()
	acts_vbox.add_theme_constant_override("separation", 4)
	vb.add_child(acts_vbox)
	var add_act_btn := Button.new()
	add_act_btn.text = "+ Add Action"
	add_act_btn.add_theme_font_size_override("font_size", 11)
	add_act_btn.pressed.connect(func() -> void: _add_spot_action_row(acts_vbox))
	vb.add_child(add_act_btn)
	var raw_acts: Variant = char_data.get("actions", [])
	if raw_acts is Array:
		for act: Variant in (raw_acts as Array):
			if act is Dictionary:
				var ad: Dictionary = act as Dictionary
				_add_spot_action_row(acts_vbox,
					str(ad.get("action", "show_message")),
					str(ad.get("key", "")),
					str(ad.get("value", "")),
					bool(ad.get("play_once", true)))

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

	vb.set_meta("char_name_edit", name_edit)
	vb.set_meta("char_vn_edit", vn_edit)
	vb.set_meta("char_play_once_chk", play_once_chk)
	vb.set_meta("char_canon_chk", canon_chk)
	vb.set_meta("char_remove_after_chk", remove_after_chk)
	vb.set_meta("char_thumb_edit", thumb_edit)
	vb.set_meta("char_acts_vbox", acts_vbox)
	vb.set_meta("char_cond_vbox", cond_vbox)

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
		if vb == null:
			continue
		var name_edit: LineEdit = vb.get_meta("char_name_edit") as LineEdit \
			if vb.has_meta("char_name_edit") else null
		var vn_edit: LineEdit = vb.get_meta("char_vn_edit") as LineEdit \
			if vb.has_meta("char_vn_edit") else null
		var play_once_chk: CheckBox = vb.get_meta("char_play_once_chk") as CheckBox \
			if vb.has_meta("char_play_once_chk") else null
		var canon_chk: CheckBox = vb.get_meta("char_canon_chk") as CheckBox \
			if vb.has_meta("char_canon_chk") else null
		var remove_after_chk: CheckBox = vb.get_meta("char_remove_after_chk") as CheckBox \
			if vb.has_meta("char_remove_after_chk") else null
		var thumb_edit: LineEdit = vb.get_meta("char_thumb_edit") as LineEdit \
			if vb.has_meta("char_thumb_edit") else null
		var acts_vbox: VBoxContainer = vb.get_meta("char_acts_vbox") as VBoxContainer \
			if vb.has_meta("char_acts_vbox") else null
		var cond_vbox: VBoxContainer = vb.get_meta("char_cond_vbox") as VBoxContainer \
			if vb.has_meta("char_cond_vbox") else null
		var actions: Array = _collect_events(acts_vbox) if acts_vbox != null else []
		var conditions: Array = _collect_conditions_from_vbox(cond_vbox) if cond_vbox != null else []
		var entry: Dictionary = {
			"name":        name_edit.text.strip_edges()  if name_edit  != null else "",
			"vn_scene":    vn_edit.text.strip_edges()    if vn_edit    != null else "",
			"thumbnail":   thumb_edit.text.strip_edges() if thumb_edit != null else "",
			"play_once":   play_once_chk.button_pressed if play_once_chk != null else true,
			"canon_story": canon_chk.button_pressed if canon_chk != null else false,
			"remove_after_talk": remove_after_chk.button_pressed if remove_after_chk != null else false,
			"conditions":  conditions,
		}
		if not actions.is_empty():
			entry["actions"] = actions
		result.append(entry)
	return result

## Auto hitbox size when hitbox_w/h are 0: scaled icon, else 24×24.
func _compute_spot_auto_hitbox(icon_path: String, icon_scale: float) -> Vector2:
	var w: float = 24.0
	var h: float = 24.0
	var path: String = icon_path.strip_edges()
	if path.is_empty() or not ResourceLoader.exists(path):
		return Vector2(w, h)
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return Vector2(w, h)
	var nat: Vector2 = tex.get_size()
	w = nat.x * icon_scale / 100.0
	h = nat.y * icon_scale / 100.0
	return Vector2(w, h)

func _apply_hitbox_spin_auto_display(spin: SpinBox, auto_px: float) -> void:
	var le: LineEdit = spin.get_line_edit()
	le.placeholder_text = str(int(round(auto_px)))
	spin.set_meta("auto_px", auto_px)
	if spin.value <= 0.0:
		le.text = ""

func _refresh_spot_hitbox_auto_display(
		icon_edit: LineEdit, scale_spin: SpinBox,
		hit_w_spin: SpinBox, hit_h_spin: SpinBox) -> void:
	var auto_size: Vector2 = _compute_spot_auto_hitbox(icon_edit.text, scale_spin.value)
	_apply_hitbox_spin_auto_display(hit_w_spin, auto_size.x)
	_apply_hitbox_spin_auto_display(hit_h_spin, auto_size.y)

func _wire_hitbox_spin_auto_display(spin: SpinBox, refresh_cb: Callable) -> void:
	spin.get_line_edit().focus_exited.connect(func() -> void:
		if spin.get_line_edit().text.strip_edges().is_empty():
			spin.set_value(0.0)
		refresh_cb.call())
	spin.value_changed.connect(func(new_val: float) -> void:
		if new_val <= 0.0:
			spin.get_line_edit().text = ""
	)

## Add one investigable-point row to the spots VBox.
## VBoxContainer children layout (by index):
##   0: pos_row      (HBoxContainer → SpinBox x_norm, SpinBox y_norm)
##   1: icon_row     (HBoxContainer → LineEdit icon_path)
##   2: scale_row    (HBoxContainer → SpinBox icon_scale)
##   3: hitbox_row   (HBoxContainer → SpinBox hitbox_w, SpinBox hitbox_h; 0 = auto)
##   4: tooltip_row  (HBoxContainer → LineEdit tooltip)
##   5: hide_row     (HBoxContainer → CheckBox hide_after_interact)
##   6: acts_hdr     (Label)
##   7: acts_vbox    (VBoxContainer of action rows)
##   8: add_act_btn  (Button)
##   9: conds_hdr    (Label)
##  10: conds_vbox   (VBoxContainer of condition rows)
##  11: add_cond_btn (Button)
##  12: del_btn      (Button)
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

	# Index 3: Hitbox size row (px; 0 = auto from icon scale or 24×24 default)
	var hitbox_row := HBoxContainer.new()
	hitbox_row.add_theme_constant_override("separation", 4)
	var hw_lbl := Label.new()
	hw_lbl.text = "Hit W"
	hw_lbl.add_theme_font_size_override("font_size", 12)
	hitbox_row.add_child(hw_lbl)
	var hit_w_spin := SpinBox.new()
	hit_w_spin.min_value = 0.0
	hit_w_spin.max_value = 4096.0
	hit_w_spin.step = 1.0
	hit_w_spin.value = float(spot_data.get("hitbox_w", 0.0))
	hit_w_spin.custom_minimum_size = Vector2(72, 0)
	hit_w_spin.add_theme_font_size_override("font_size", 12)
	hitbox_row.add_child(hit_w_spin)
	var hh_lbl := Label.new()
	hh_lbl.text = "Hit H"
	hh_lbl.add_theme_font_size_override("font_size", 12)
	hitbox_row.add_child(hh_lbl)
	var hit_h_spin := SpinBox.new()
	hit_h_spin.min_value = 0.0
	hit_h_spin.max_value = 4096.0
	hit_h_spin.step = 1.0
	hit_h_spin.value = float(spot_data.get("hitbox_h", 0.0))
	hit_h_spin.custom_minimum_size = Vector2(72, 0)
	hit_h_spin.add_theme_font_size_override("font_size", 12)
	hitbox_row.add_child(hit_h_spin)
	var hit_note := Label.new()
	hit_note.text = "px (empty = auto)"
	hit_note.add_theme_font_size_override("font_size", 11)
	hit_note.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68, 0.75))
	hitbox_row.add_child(hit_note)
	vb.add_child(hitbox_row)
	var refresh_hitbox_defaults := func() -> void:
		_refresh_spot_hitbox_auto_display(icon_edit, scale_spin, hit_w_spin, hit_h_spin)
	icon_edit.text_changed.connect(func(_t: String) -> void: refresh_hitbox_defaults.call())
	scale_spin.value_changed.connect(func(_v: float) -> void: refresh_hitbox_defaults.call())
	_wire_hitbox_spin_auto_display(hit_w_spin, refresh_hitbox_defaults)
	_wire_hitbox_spin_auto_display(hit_h_spin, refresh_hitbox_defaults)
	refresh_hitbox_defaults.call()

	# Index 4: Tooltip row
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

	# Index 5: Hide-after-interact row
	var hide_row := HBoxContainer.new()
	var hide_cb := CheckBox.new()
	hide_cb.text           = "Hide after interact"
	hide_cb.button_pressed = bool(spot_data.get("hide_after_interact", false))
	hide_cb.add_theme_font_size_override("font_size", 12)
	hide_row.add_child(hide_cb)
	vb.add_child(hide_row)

	# Index 6: Actions header
	var acts_hdr := Label.new()
	acts_hdr.text = "Actions on click:"
	acts_hdr.add_theme_font_size_override("font_size", 11)
	acts_hdr.add_theme_color_override("font_color", Color(0.80, 0.65, 1.0))
	vb.add_child(acts_hdr)

	# Index 7: Actions VBox
	var acts_vbox := VBoxContainer.new()
	acts_vbox.add_theme_constant_override("separation", 3)
	acts_vbox.set_meta("spot_index", spots_vbox.get_child_count() - 1)
	vb.add_child(acts_vbox)

	# Index 8: Add Action button
	var add_act_btn := Button.new()
	add_act_btn.text = "+ Add Action"
	add_act_btn.add_theme_font_size_override("font_size", 11)
	add_act_btn.pressed.connect(func() -> void: _add_spot_action_row(acts_vbox))
	vb.add_child(add_act_btn)

	# Index 9: Conditions header
	var cond_hdr := Label.new()
	cond_hdr.text = "Conditions (all must pass to show):"
	cond_hdr.add_theme_font_size_override("font_size", 11)
	cond_hdr.add_theme_color_override("font_color", Color(0.65, 0.80, 0.65))
	vb.add_child(cond_hdr)

	# Index 10: Conditions VBox
	var cond_vbox := VBoxContainer.new()
	cond_vbox.add_theme_constant_override("separation", 3)
	vb.add_child(cond_vbox)

	# Index 11: Add Condition button
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
					str(ad.get("value",  "")),
					bool(ad.get("play_once", true)))
	# Backward compat: legacy vn_scene field → play_vn action
	var legacy_vn: String = str(spot_data.get("vn_scene", ""))
	if not legacy_vn.is_empty() and (not (raw_acts is Array) or (raw_acts as Array).is_empty()):
		_add_spot_action_row(acts_vbox, "play_vn", "", legacy_vn, true)

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
		key: String = "", value: String = "", play_once: bool = true) -> void:
	var block_parts: Dictionary = _add_kv_row_block(vbox)
	var block: VBoxContainer = block_parts["block"] as VBoxContainer
	var row: HBoxContainer = block_parts["row"] as HBoxContainer
	var hint_lbl: Label = block_parts["hint"] as Label
	block.set_meta("spot_action_index", vbox.get_child_count() - 1)
	var _spot_actions: Array[String] = [
		"give_item", "give_booster_pack", "give_union_scroll", "remove_item", "set_var", "give_credits", "set_flag",
		"show_message", "play_sfx", "play_vn", "navigate_to", "play_puzzle", "end_exploration", "end_exploration_vn"
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
	var spot_puzzle_pick_btn := Button.new()
	spot_puzzle_pick_btn.text = "…"
	spot_puzzle_pick_btn.tooltip_text = "Browse puzzles (fills value field)"
	spot_puzzle_pick_btn.custom_minimum_size = Vector2(28.0, 0.0)
	spot_puzzle_pick_btn.pressed.connect(func() -> void: _open_puzzle_picker(val_edit))
	row.add_child(spot_puzzle_pick_btn)
	var spot_vn_browse_btn := Button.new()
	spot_vn_browse_btn.text = "…"
	spot_vn_browse_btn.tooltip_text = "Browse VN beat JSON (fills value field)"
	spot_vn_browse_btn.custom_minimum_size = Vector2(28.0, 0.0)
	spot_vn_browse_btn.pressed.connect(func() -> void:
		_browse_for_file(val_edit, PackedStringArray(["*.json ; JSON Files"]), "res://exploration/vn"))
	row.add_child(spot_vn_browse_btn)

	var vn_extra_row := HBoxContainer.new()
	vn_extra_row.add_theme_constant_override("separation", 6)
	var spot_edit_beats_btn := Button.new()
	spot_edit_beats_btn.text = "Edit Beats ↗"
	spot_edit_beats_btn.add_theme_font_size_override("font_size", 11)
	spot_edit_beats_btn.pressed.connect(func() -> void:
		_on_edit_spot_vn_beats_pressed(val_edit, vbox, block))
	vn_extra_row.add_child(spot_edit_beats_btn)
	var spot_play_once_chk := CheckBox.new()
	spot_play_once_chk.text = "Play Once"
	spot_play_once_chk.button_pressed = play_once
	spot_play_once_chk.add_theme_font_size_override("font_size", 11)
	vn_extra_row.add_child(spot_play_once_chk)
	block.add_child(vn_extra_row)
	block.move_child(vn_extra_row, 1)
	block.set_meta("play_once_chk", spot_play_once_chk)
	block.set_meta("acts_vbox", vbox)

	# Update pickers, placeholders, and hint text based on selected action.
	var _update_spot_hint := func() -> void:
		var sel: String = _spot_actions[action_btn.selected]
		if sel == "play_puzzle":
			var extra: String = _puzzle_params_guide_text(val_edit.text.strip_edges())
			hint_lbl.text = _spot_action_kv_hint(sel) if extra.is_empty() \
				else _spot_action_kv_hint(sel) + "\n" + extra
		else:
			hint_lbl.text = _spot_action_kv_hint(sel)

	var _update_spot_pickers := func(sel_idx: int) -> void:
		var sel: String = _spot_actions[sel_idx]
		spot_pick_btn.visible        = sel in ["give_item", "remove_item"]
		spot_pack_pick_btn.visible   = sel == "give_booster_pack"
		spot_puzzle_pick_btn.visible = sel == "play_puzzle"
		spot_vn_browse_btn.visible   = sel in ["play_vn", "end_exploration_vn"]
		vn_extra_row.visible         = sel == "play_vn"
		key_edit.visible             = sel not in ["play_vn", "end_exploration_vn"]
		if sel == "play_puzzle":
			key_edit.placeholder_text = "params (JSON or text)"
			val_edit.placeholder_text = "puzzle id"
		elif sel in ["play_vn", "end_exploration_vn"]:
			val_edit.placeholder_text = "res:// path to VN JSON"
		else:
			key_edit.placeholder_text = "key"
			val_edit.placeholder_text = "value / amount / pack"
		_update_spot_hint.call()
	action_btn.item_selected.connect(_update_spot_pickers)
	_update_spot_pickers.call(action_btn.selected)

	val_edit.text_changed.connect(func(_new_text: String) -> void:
		if _spot_actions[action_btn.selected] == "play_puzzle":
			_update_spot_hint.call()
	)

	var del_btn := Button.new()
	del_btn.text = "x"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	del_btn.pressed.connect(block.queue_free)
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
		# Index 3: hitbox_row — two SpinBoxes (W, H)
		var hitbox_w: float = 0.0
		var hitbox_h: float = 0.0
		if vb.get_child_count() > 3 and vb.get_child(3) is HBoxContainer:
			var hit_spins: Array = []
			for c: Node in (vb.get_child(3) as HBoxContainer).get_children():
				if c is SpinBox:
					hit_spins.append(c as SpinBox)
			if hit_spins.size() >= 1:
				hitbox_w = (hit_spins[0] as SpinBox).value
			if hit_spins.size() >= 2:
				hitbox_h = (hit_spins[1] as SpinBox).value
		# Index 4: tooltip_row — first LineEdit
		var tooltip: String = ""
		var tip_le: LineEdit = _find_line_edit(vb.get_child(4)) if vb.get_child_count() > 4 else null
		if tip_le != null:
			tooltip = tip_le.text
		# Index 5: hide_after_interact CheckBox
		var hide_after_interact: bool = false
		if vb.get_child_count() > 5 and vb.get_child(5) is HBoxContainer:
			for c: Node in (vb.get_child(5) as HBoxContainer).get_children():
				if c is CheckBox:
					hide_after_interact = (c as CheckBox).button_pressed
					break
		# Index 7: acts_vbox — VBoxContainer
		var actions: Array = []
		if vb.get_child_count() > 7 and vb.get_child(7) is VBoxContainer:
			actions = _collect_events(vb.get_child(7) as VBoxContainer)
		# Index 10: conds_vbox — VBoxContainer
		var conditions: Array = []
		if vb.get_child_count() > 10 and vb.get_child(10) is VBoxContainer:
			conditions = _collect_conditions_from_vbox(vb.get_child(10) as VBoxContainer)
		var entry: Dictionary = {
			"x_norm":             x_norm,
			"y_norm":             y_norm,
			"icon":               icon_path,
			"icon_scale":         icon_scale,
			"tooltip":            tooltip,
			"hide_after_interact": hide_after_interact,
			"actions":            actions,
			"conditions":         conditions,
		}
		if hitbox_w > 0.0:
			entry["hitbox_w"] = hitbox_w
		if hitbox_h > 0.0:
			entry["hitbox_h"] = hitbox_h
		result.append(entry)
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
	GameState.attach_popup_cursor(win)

## Edit beats for an investigable-point play_vn action.
## Auto-creates vn_<node_id>_invest_<spot_idx>_<action_idx>.json when path is empty.
func _on_edit_spot_vn_beats_pressed(val_edit: LineEdit, acts_vbox: VBoxContainer,
		block: VBoxContainer) -> void:
	var path: String = val_edit.text.strip_edges()
	if path.is_empty():
		if _graph_path.is_empty():
			_set_status("Save the graph first before creating a spot VN scene.")
			return
		if _selected_node_id.is_empty():
			_set_status("Select a node first.")
			return
		var graph_name: String = _graph_path.get_file().get_basename()
		var spot_idx: int = int(acts_vbox.get_meta("spot_index", 0))
		var act_idx: int = int(block.get_meta("spot_action_index", 0))
		var uid: String = "%d_%d" % [spot_idx, act_idx]
		path = "res://exploration/vn/vn_%s/vn_%s_invest_%s.json" % [
			graph_name, _selected_node_id, uid]
		_create_vn_subfolder(_graph_path)
		if not _ensure_vn_beat_file(path):
			return
		val_edit.text = path
		_commit_selected_node()
		_set_status("Created '%s' — opening VN Editor." % path.get_file())
	elif not _ensure_vn_beat_file(path):
		return
	else:
		_set_status("Opening VN Editor: %s" % path.get_file())
	_open_vn_editor_overlay(path)

## Called when the "Edit Beats ↗" button inside a character row is pressed.
## Auto-creates the VN JSON file using the pattern vn_<node_id>_char_<char_name>.json.
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
		path = "res://exploration/vn/vn_%s/vn_%s_char_%s.json" % [graph_name, _selected_node_id, sanitized]
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
	for child: Node in _prop_title_cond_vbox.get_children():
		child.queue_free()
	for cond: Variant in en.title_conditions:
		if cond is Dictionary:
			var cd: Dictionary = cond as Dictionary
			_add_text_cond_row(_prop_title_cond_vbox, false,
				str(cd.get("var", "")), str(cd.get("equals", "")), str(cd.get("value", "")))
	_prop_desc_edit.text  = en.description
	for child: Node in _prop_desc_cond_vbox.get_children():
		child.queue_free()
	for cond: Variant in en.description_conditions:
		if cond is Dictionary:
			var cd: Dictionary = cond as Dictionary
			_add_text_cond_row(_prop_desc_cond_vbox, true,
				str(cd.get("var", "")), str(cd.get("equals", "")), str(cd.get("value", "")))
	_prop_type_btn.select(en.node_type)
	_update_battle_section_visibility()
	_prop_battle_bgm_edit.text = en.battle_bgm
	_prop_setup_bgm_edit.text = en.setup_bgm
	_prop_almost_win_bgm_edit.text = en.almost_win_bgm
	_prop_battle_bgm_vol.value = en.battle_bgm_volume
	_prop_bg_edit.text    = en.background

	for child: Node in _prop_bg_cond_vbox.get_children():
		child.queue_free()
	for cond: Variant in en.background_conditions:
		if cond is Dictionary:
			var cd: Dictionary = cond as Dictionary
			_add_media_cond_row(_prop_bg_cond_vbox, true,
				str(cd.get("var", "")), str(cd.get("equals", "")), str(cd.get("path", "")))

	_prop_vn_edit.text    = en.vn_scene
	for child: Node in _prop_vn_cond_vbox.get_children():
		child.queue_free()
	for cond: Variant in en.vn_scene_conditions:
		if cond is Dictionary:
			var cd: Dictionary = cond as Dictionary
			var cond_after: Variant = cd.get("after_actions", [])
			_add_path_cond_row(_prop_vn_cond_vbox,
				PackedStringArray(["*.json ; JSON Files"]), "res://exploration/vn",
				str(cd.get("var", "")), str(cd.get("equals", "")), str(cd.get("path", "")),
				Callable(), true, bool(cd.get("play_once", true)),
				cond_after if cond_after is Array else [])
	if _prop_vn_trigger_btn != null:
		_prop_vn_trigger_btn.select(_vn_trigger_index(en.vn_trigger))
		_prop_vn_trigger_var_edit.text = en.vn_trigger_var
		_prop_vn_trigger_eq_edit.text  = en.vn_trigger_equals
		_on_vn_trigger_changed(_prop_vn_trigger_btn.selected)
	_prop_vn_play_once_chk.button_pressed = en.vn_play_once
	_prop_vn_keep_bgm_chk.button_pressed = en.vn_keep_bgm
	for child: Node in _prop_vn_after_vbox.get_children():
		child.queue_free()
	for act: Variant in en.vn_after_actions:
		if act is Dictionary:
			var ad: Dictionary = act as Dictionary
			_add_spot_action_row(_prop_vn_after_vbox,
				str(ad.get("action", "show_message")),
				str(ad.get("key", "")),
				str(ad.get("value", "")),
				bool(ad.get("play_once", true)))
	_prop_show_info_chk.button_pressed = en.show_info_on_enter
	_prop_show_who_chk.button_pressed  = en.show_who_is_here
	_prop_music_edit.text = en.music

	for child: Node in _prop_music_cond_vbox.get_children():
		child.queue_free()
	for cond: Variant in en.music_conditions:
		if cond is Dictionary:
			var cd: Dictionary = cond as Dictionary
			_add_media_cond_row(_prop_music_cond_vbox, false,
				str(cd.get("var", "")), str(cd.get("equals", "")), str(cd.get("path", "")))

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
	for child: Node in _prop_events_in_cond_vbox.get_children():
		child.queue_free()
	for cond: Variant in en.on_enter_events_conditions:
		if cond is Dictionary:
			var cd: Dictionary = cond as Dictionary
			var evs: Variant = cd.get("events", [])
			_add_events_cond_row(_prop_events_in_cond_vbox,
				str(cd.get("var", "")), str(cd.get("equals", "")),
				evs if evs is Array else [])

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
	for child: Node in _prop_events_out_cond_vbox.get_children():
		child.queue_free()
	for cond: Variant in en.on_exit_events_conditions:
		if cond is Dictionary:
			var cd: Dictionary = cond as Dictionary
			var evs: Variant = cd.get("events", [])
			_add_events_cond_row(_prop_events_out_cond_vbox,
				str(cd.get("var", "")), str(cd.get("equals", "")),
				evs if evs is Array else [])

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
	en.title_conditions = _collect_text_conds(_prop_title_cond_vbox)
	en.description = _prop_desc_edit.text
	en.description_conditions = _collect_text_conds(_prop_desc_cond_vbox)
	en.node_type   = _prop_type_btn.selected
	en.battle_bgm         = _prop_battle_bgm_edit.text.strip_edges()
	en.setup_bgm          = _prop_setup_bgm_edit.text.strip_edges()
	en.almost_win_bgm     = _prop_almost_win_bgm_edit.text.strip_edges()
	en.battle_bgm_volume  = _prop_battle_bgm_vol.value
	en.background  = _prop_bg_edit.text.strip_edges()
	en.background_conditions.clear()
	for frame: Node in _prop_bg_cond_vbox.get_children():
		if frame.has_meta("key_edit") and frame.has_meta("eq_edit") and frame.has_meta("path_edit"):
			en.background_conditions.append({
				"var":    (frame.get_meta("key_edit")  as LineEdit).text.strip_edges(),
				"equals": (frame.get_meta("eq_edit")   as LineEdit).text.strip_edges(),
				"path":   (frame.get_meta("path_edit") as LineEdit).text.strip_edges(),
			})
	en.vn_scene    = _prop_vn_edit.text.strip_edges()
	en.vn_scene_conditions.clear()
	for frame: Node in _prop_vn_cond_vbox.get_children():
		if frame.has_meta("key_edit") and frame.has_meta("eq_edit") and frame.has_meta("path_edit"):
			var vn_cond: Dictionary = {
				"var":    (frame.get_meta("key_edit")  as LineEdit).text.strip_edges(),
				"equals": (frame.get_meta("eq_edit")   as LineEdit).text.strip_edges(),
				"path":   (frame.get_meta("path_edit") as LineEdit).text.strip_edges(),
			}
			if frame.has_meta("play_once_chk"):
				vn_cond["play_once"] = (frame.get_meta("play_once_chk") as CheckBox).button_pressed
			if frame.has_meta("after_actions_vbox"):
				var cond_acts: Array = _collect_events(frame.get_meta("after_actions_vbox") as VBoxContainer)
				if not cond_acts.is_empty():
					vn_cond["after_actions"] = cond_acts
			en.vn_scene_conditions.append(vn_cond)
	if _prop_vn_trigger_btn != null:
		var trig_idx: int = _prop_vn_trigger_btn.selected
		en.vn_trigger = VN_TRIGGER_VALUES[trig_idx] if trig_idx >= 0 and trig_idx < VN_TRIGGER_VALUES.size() else "on_enter"
		en.vn_trigger_var    = _prop_vn_trigger_var_edit.text.strip_edges()
		en.vn_trigger_equals = _prop_vn_trigger_eq_edit.text.strip_edges()
	en.vn_play_once       = _prop_vn_play_once_chk.button_pressed
	en.vn_keep_bgm        = _prop_vn_keep_bgm_chk.button_pressed
	en.vn_after_actions   = _collect_events(_prop_vn_after_vbox)
	en.show_info_on_enter = _prop_show_info_chk.button_pressed
	en.show_who_is_here   = _prop_show_who_chk.button_pressed
	en.music       = _prop_music_edit.text.strip_edges()
	en.music_conditions.clear()
	for frame: Node in _prop_music_cond_vbox.get_children():
		if frame.has_meta("key_edit") and frame.has_meta("eq_edit") and frame.has_meta("path_edit"):
			en.music_conditions.append({
				"var":    (frame.get_meta("key_edit")  as LineEdit).text.strip_edges(),
				"equals": (frame.get_meta("eq_edit")   as LineEdit).text.strip_edges(),
				"path":   (frame.get_meta("path_edit") as LineEdit).text.strip_edges(),
			})

	# On-enter events
	en.on_enter_events.clear()
	en.on_enter_events = _collect_events(_prop_events_in_vbox)
	en.on_enter_events_conditions = _collect_events_conds(_prop_events_in_cond_vbox)

	# On-exit events
	en.on_exit_events.clear()
	en.on_exit_events = _collect_events(_prop_events_out_vbox)
	en.on_exit_events_conditions = _collect_events_conds(_prop_events_out_cond_vbox)

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

func _populate_graph_props() -> void:
	if _prop_start_node_edit == null or _graph == null:
		return
	_prop_start_node_edit.text = _graph.start_node_id
	for child: Node in _prop_start_cond_vbox.get_children():
		child.queue_free()
	for cond: Variant in _graph.start_node_id_conditions:
		if cond is Dictionary:
			var cd: Dictionary = cond as Dictionary
			_add_node_id_cond_row(_prop_start_cond_vbox,
				str(cd.get("var", "")), str(cd.get("equals", "")), str(cd.get("node_id", "")))

func _collect_graph_props() -> void:
	if _prop_start_node_edit == null or _graph == null:
		return
	_graph.start_node_id = _prop_start_node_edit.text.strip_edges()
	_graph.start_node_id_conditions = _collect_node_id_conds(_prop_start_cond_vbox)

func _collect_node_id_conds(cond_vbox: VBoxContainer) -> Array:
	var result: Array = []
	for frame: Node in cond_vbox.get_children():
		if not frame.has_meta("key_edit") or not frame.has_meta("eq_edit") or not frame.has_meta("node_id_edit"):
			continue
		result.append({
			"var":     (frame.get_meta("key_edit")     as LineEdit).text.strip_edges(),
			"equals":  (frame.get_meta("eq_edit")      as LineEdit).text.strip_edges(),
			"node_id": (frame.get_meta("node_id_edit") as LineEdit).text.strip_edges(),
		})
	return result

func _collect_text_conds(cond_vbox: VBoxContainer) -> Array:
	var result: Array = []
	for frame: Node in cond_vbox.get_children():
		if not frame.has_meta("key_edit") or not frame.has_meta("eq_edit") or not frame.has_meta("value_edit"):
			continue
		var value_edit: Node = frame.get_meta("value_edit") as Node
		var val: String = ""
		if value_edit is LineEdit:
			val = (value_edit as LineEdit).text
		elif value_edit is TextEdit:
			val = (value_edit as TextEdit).text
		result.append({
			"var":    (frame.get_meta("key_edit") as LineEdit).text.strip_edges(),
			"equals": (frame.get_meta("eq_edit")  as LineEdit).text.strip_edges(),
			"value":  val,
		})
	return result

func _collect_events_conds(cond_vbox: VBoxContainer) -> Array:
	var result: Array = []
	for frame: Node in cond_vbox.get_children():
		if not frame.has_meta("key_edit") or not frame.has_meta("eq_edit") or not frame.has_meta("events_vbox"):
			continue
		var events_vbox: VBoxContainer = frame.get_meta("events_vbox") as VBoxContainer
		result.append({
			"var":    (frame.get_meta("key_edit") as LineEdit).text.strip_edges(),
			"equals": (frame.get_meta("eq_edit")  as LineEdit).text.strip_edges(),
			"events": _collect_events(events_vbox),
		})
	return result

func _collect_events(events_vbox: VBoxContainer) -> Array:
	var result: Array = []
	for child: Node in events_vbox.get_children():
		var row: HBoxContainer = _find_kv_row_node(child)
		if row == null:
			continue
		var ob: OptionButton = null
		var les: Array[LineEdit] = []
		for c: Node in row.get_children():
			if c is OptionButton and ob == null:
				ob = c as OptionButton
			elif c is LineEdit:
				les.append(c as LineEdit)
		if ob == null or les.size() < 2:
			continue
		var action_name: String = ob.get_item_text(ob.selected)
		var entry: Dictionary = {
			"action": action_name,
			"key":    les[0].text,
			"value":  les[1].text,
		}
		if action_name == "play_vn" and child.has_meta("play_once_chk"):
			entry["play_once"] = (child.get_meta("play_once_chk") as CheckBox).button_pressed
		result.append(entry)
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
		conditions = _collect_conditions_from_vbox(cond_vbox)

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
	# Fast path: the vbox is tagged with meta when created in _add_connection_row.
	if frame.has_meta("cond_vbox"):
		var tagged: Variant = frame.get_meta("cond_vbox")
		if tagged is VBoxContainer:
			return tagged as VBoxContainer
	# Fallback walk for any frame created before the meta tag was added.
	for child: Node in frame.get_children():
		if child is VBoxContainer:
			for sub: Node in (child as VBoxContainer).get_children():
				if sub is VBoxContainer:
					return sub as VBoxContainer
	return null

# ─────────────────────────────────────────────────────────────
# Toolbar Actions
# ─────────────────────────────────────────────────────────────

func _on_new_pressed() -> void:
	if _dirty:
		_new_confirm_dialog.popup_centered()
	else:
		_new_graph()

func _on_load_pressed() -> void:
	_load_dialog.popup_centered(Vector2(900, 600))

func _on_load_file_selected(path: String) -> void:
	_load_graph(path)

func _on_save_pressed() -> void:
	_collect_graph_props()
	_commit_selected_node()
	if _graph_path.is_empty():
		_on_save_as_pressed()
	else:
		_save_graph(_graph_path)

func _on_save_as_pressed() -> void:
	_collect_graph_props()
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

func _on_reward_report_pressed() -> void:
	if _graph == null:
		_set_status("Load a graph first.")
		return
	_collect_graph_props()
	_commit_selected_node()
	var report: String = _generate_reward_report()
	var saved_path: String = _save_reward_report_markdown(report)
	DisplayServer.clipboard_set(report)
	_show_reward_report_popup(report, saved_path)
	var status_bits: Array[String] = ["Reward report generated (%d chars), copied to clipboard." % report.length()]
	if not saved_path.is_empty():
		status_bits.append("Saved: %s" % saved_path.get_file())
	_set_status(" ".join(status_bits))

func _generate_reward_report() -> String:
	var graph_label: String = _graph_path.get_file() if not _graph_path.is_empty() else _graph.graph_id
	if graph_label.is_empty():
		graph_label = "(unsaved graph)"
	var display_name: String = _graph.display_name if not _graph.display_name.is_empty() else _graph.graph_id
	var lines: Array[String] = []
	lines.append("# Reward Report — %s" % graph_label)
	if not display_name.is_empty() and display_name != graph_label:
		lines.append("Display name: %s" % display_name)
	lines.append("Generated: %s" % Time.get_datetime_string_from_system(true, true))
	lines.append("")

	var entries: Array[Dictionary] = []
	for node: ExplorationNode in _graph.nodes:
		_collect_spot_reward_entries(entries, node)
		_collect_on_enter_reward_entries(entries, node)

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("sort", "")) < str(b.get("sort", ""))
	)

	var credit_total: int = 0
	var credit_count: int = 0
	var booster_counts: Dictionary = {}
	for entry: Dictionary in entries:
		var reward: String = str(entry.get("reward", ""))
		if reward.begins_with("credits:"):
			credit_count += 1
			credit_total += int(entry.get("credit_amount", 0))
		elif reward.begins_with("booster:"):
			var pack_id: String = str(entry.get("booster_id", ""))
			booster_counts[pack_id] = int(booster_counts.get(pack_id, 0)) + 1

	lines.append("## Summary")
	lines.append("Reward entries: %d" % entries.size())
	lines.append("Credits: %d spot(s), %d total if all obtained" % [credit_count, credit_total])
	if booster_counts.is_empty():
		lines.append("Boosters: none")
	else:
		var booster_total: int = 0
		for pack_id: Variant in booster_counts.keys():
			booster_total += int(booster_counts[pack_id])
		lines.append("Boosters: %d spot(s)" % booster_total)
		var pack_ids: Array = booster_counts.keys()
		pack_ids.sort()
		for pack_id: Variant in pack_ids:
			lines.append("  • %s: %d" % [str(pack_id), int(booster_counts[pack_id])])
	lines.append("")

	if entries.is_empty():
		lines.append("No give_credits or give_booster_pack actions found in clickable spots or on-enter events.")
		return "\n".join(lines)

	lines.append("## Entries (%d)" % entries.size())
	lines.append("")
	for entry: Dictionary in entries:
		lines.append("### [%s] %s — %s" % [
			str(entry.get("node_id", "")),
			str(entry.get("node_title", "")),
			str(entry.get("source", "")),
		])
		lines.append("Reward: %s" % _reward_report_reward_text(entry))
		var tooltip: String = str(entry.get("tooltip", ""))
		if not tooltip.is_empty():
			lines.append("Tooltip: \"%s\"" % tooltip)
		var hide_after: Variant = entry.get("hide_after", null)
		if hide_after != null:
			lines.append("Hide after click: %s" % ("yes" if bool(hide_after) else "no"))
		var event_gate: String = str(entry.get("event_gate", ""))
		if not event_gate.is_empty():
			lines.append("Event gate: %s" % event_gate)
		lines.append("Visibility conditions: %s" % _format_report_conditions(entry.get("conditions", [])))
		lines.append("Action chain: %s" % str(entry.get("chain", "(direct)")))
		lines.append("")

	return "\n".join(lines)

func _collect_spot_reward_entries(entries: Array[Dictionary], node: ExplorationNode) -> void:
	for spot_idx: int in node.clickable_spots.size():
		var spot_var: Variant = node.clickable_spots[spot_idx]
		if not spot_var is Dictionary:
			continue
		var spot: Dictionary = spot_var as Dictionary
		var actions: Array = spot.get("actions", []) if spot.get("actions", []) is Array else []
		var extra: Dictionary = {
			"tooltip": str(spot.get("tooltip", "")),
			"hide_after": bool(spot.get("hide_after_interact", false)),
			"conditions": spot.get("conditions", []) if spot.get("conditions", []) is Array else [],
		}
		_append_reward_entries_from_actions(
			entries,
			node,
			"spot #%d" % spot_idx,
			actions,
			extra,
		)

func _collect_on_enter_reward_entries(entries: Array[Dictionary], node: ExplorationNode) -> void:
	var base_extra: Dictionary = {
		"tooltip": "",
		"hide_after": null,
		"conditions": [],
	}
	_append_reward_entries_from_actions(entries, node, "on enter", node.on_enter_events, base_extra)
	for cond_var: Variant in node.on_enter_events_conditions:
		if not cond_var is Dictionary:
			continue
		var cond_block: Dictionary = cond_var as Dictionary
		var var_key: String = str(cond_block.get("var", ""))
		var eq_val: String = str(cond_block.get("equals", ""))
		var gate: String = "%s=%s" % [var_key, eq_val] if not var_key.is_empty() else "(conditional)"
		var events: Array = cond_block.get("events", []) if cond_block.get("events", []) is Array else []
		var gated_extra: Dictionary = base_extra.duplicate(true)
		gated_extra["event_gate"] = gate
		_append_reward_entries_from_actions(
			entries,
			node,
			"on enter (when %s)" % gate,
			events,
			gated_extra,
		)

func _append_reward_entries_from_actions(
	entries: Array[Dictionary],
	node: ExplorationNode,
	source_label: String,
	actions: Array,
	extra: Dictionary,
) -> void:
	for action_idx: int in actions.size():
		var act_var: Variant = actions[action_idx]
		if not act_var is Dictionary:
			continue
		var act: Dictionary = act_var as Dictionary
		var action: String = str(act.get("action", ""))
		if action != "give_credits" and action != "give_booster_pack" and action != "give_union_scroll":
			continue
		var reward_meta: Dictionary = _reward_report_meta_from_action(act)
		var sort_key: String = "%s|%s|%03d" % [node.title.to_lower(), source_label.to_lower(), action_idx]
		entries.append({
			"sort": sort_key,
			"node_id": node.id,
			"node_title": node.title,
			"source": source_label,
			"reward": str(reward_meta.get("label", "")),
			"credit_amount": int(reward_meta.get("credit_amount", 0)),
			"booster_id": str(reward_meta.get("booster_id", "")),
			"chain": _format_report_action_chain(actions, action_idx),
			"tooltip": str(extra.get("tooltip", "")),
			"hide_after": extra.get("hide_after", null),
			"conditions": extra.get("conditions", []),
			"event_gate": str(extra.get("event_gate", "")),
		})

func _reward_report_meta_from_action(act: Dictionary) -> Dictionary:
	var action: String = str(act.get("action", ""))
	if action == "give_credits":
		var amount: int = _extract_credit_amount(act)
		return {"label": "credits:%d" % amount, "credit_amount": amount, "booster_id": ""}
	if action == "give_booster_pack":
		var pack_id: String = _extract_booster_pack_id(act)
		return {"label": "booster:%s" % pack_id, "credit_amount": 0, "booster_id": pack_id}
	if action == "give_union_scroll":
		var scroll_n: int = _extract_credit_amount(act)
		if scroll_n <= 0:
			scroll_n = 1
		return {"label": "union_scroll:%d" % scroll_n, "credit_amount": 0, "booster_id": ""}
	return {"label": action, "credit_amount": 0, "booster_id": ""}

func _reward_report_reward_text(entry: Dictionary) -> String:
	var reward: String = str(entry.get("reward", ""))
	if reward.begins_with("credits:"):
		return "%s credits" % str(entry.get("credit_amount", 0))
	if reward.begins_with("booster:"):
		var pack_id: String = str(entry.get("booster_id", ""))
		if pack_id.is_empty():
			return "booster pack (id missing)"
		return "booster \"%s\"" % pack_id
	return reward

func _extract_credit_amount(act: Dictionary) -> int:
	var val_str: String = str(act.get("value", "")).strip_edges()
	if val_str.is_valid_int():
		return int(val_str)
	var key_str: String = str(act.get("key", "")).strip_edges()
	if key_str.is_valid_int():
		return int(key_str)
	return 0

func _extract_booster_pack_id(act: Dictionary) -> String:
	return str(act.get("value", "")).strip_edges()

func _format_report_action_chain(actions: Array, reward_index: int) -> String:
	if reward_index <= 0:
		return "(direct)"
	var parts: Array[String] = []
	for i: int in range(reward_index):
		var act_var: Variant = actions[i]
		if not act_var is Dictionary:
			parts.append("?")
			continue
		var act: Dictionary = act_var as Dictionary
		var action: String = str(act.get("action", ""))
		match action:
			"play_vn":
				parts.append("play_vn(%s)" % str(act.get("value", "")))
			"play_puzzle":
				parts.append("play_puzzle(%s)" % str(act.get("value", "")))
			"navigate_to":
				parts.append("navigate_to(%s)" % str(act.get("value", "")))
			_:
				parts.append(action if not action.is_empty() else "?")
	parts.append("reward")
	return " → ".join(parts)

func _format_report_conditions(conditions: Array) -> String:
	if conditions.is_empty():
		return "(none — always visible if spot shown)"
	var parts: Array[String] = []
	for cond_var: Variant in conditions:
		if not cond_var is Dictionary:
			continue
		parts.append(_format_report_condition(cond_var as Dictionary))
	if parts.is_empty():
		return "(none — always visible if spot shown)"
	return "; ".join(parts)

func _format_report_condition(cond: Dictionary) -> String:
	var ctype: String = str(cond.get("type", ""))
	var key: String = str(cond.get("key", ""))
	var value: String = str(cond.get("value", ""))
	match ctype:
		"has_item":
			return "has_item(%s)" % key
		"not_has_item":
			return "not_has_item(%s)" % key
		"var_equals":
			return "%s == %s" % [key, value]
		"var_not_equals":
			return "%s != %s" % [key, value]
		"var_greater":
			return "%s > %s" % [key, value]
		"var_less":
			return "%s < %s" % [key, value]
		"at_node":
			var node_ref: String = value if not value.is_empty() else key
			return "at_node(%s)" % node_ref
		_:
			if ctype.is_empty():
				return "(invalid condition)"
			return "%s(key=%s, value=%s)" % [ctype, key, value]

func _save_reward_report_markdown(report: String) -> String:
	var dir_abs: String = ProjectSettings.globalize_path(REWARD_REPORT_DIR)
	var err: Error = DirAccess.make_dir_recursive_absolute(dir_abs)
	if err != OK:
		push_warning("ExplorationEditor: could not create report dir: %s" % REWARD_REPORT_DIR)
		return ""
	var stem: String = _graph_path.get_file().get_basename() if not _graph_path.is_empty() else _graph.graph_id
	if stem.is_empty():
		stem = "unsaved_graph"
	var stamp: String = Time.get_datetime_string_from_system(true, true).replace(":", "-").replace(" ", "_")
	var file_name: String = "reward_report_%s_%s.md" % [stem, stamp]
	var file_abs: String = dir_abs.path_join(file_name)
	var f: FileAccess = FileAccess.open(file_abs, FileAccess.WRITE)
	if f == null:
		push_warning("ExplorationEditor: could not write reward report: %s" % file_abs)
		return ""
	f.store_string(report)
	f.close()
	return file_abs

func _show_reward_report_popup(body: String, saved_path: String) -> void:
	var win := Window.new()
	win.title = "Reward Report"
	win.min_size = Vector2i(640, 480)
	win.size = Vector2i(760, 560)
	win.close_requested.connect(win.queue_free)
	add_child(win)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 10
	root.offset_right = -10
	root.offset_top = 10
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 8)
	win.add_child(root)

	var header := Label.new()
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if saved_path.is_empty():
		header.text = "Report copied to clipboard. Could not save markdown file."
	else:
		header.text = "Report copied to clipboard.\nSaved: %s" % saved_path
	header.add_theme_font_size_override("font_size", 13)
	root.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var text_edit := TextEdit.new()
	text_edit.text = body
	text_edit.editable = false
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_edit.custom_minimum_size = Vector2(700, 420)
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(text_edit)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	root.add_child(btn_row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	var copy_btn := Button.new()
	copy_btn.text = "Copy Again"
	copy_btn.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(body)
		_set_status("Reward report copied to clipboard.")
	)
	btn_row.add_child(copy_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(win.queue_free)
	btn_row.add_child(close_btn)

	win.popup_centered()

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
	# Show the params popup instead of launching immediately.
	_test_params_popup.popup_centered(Vector2(420, 500))

func _build_test_params_popup() -> void:
	_test_params_popup = PopupPanel.new()
	_test_params_popup.min_size = Vector2(420, 0)
	add_child(_test_params_popup)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 12; root.offset_right  = -12
	root.offset_top  = 12; root.offset_bottom = -12
	_test_params_popup.add_child(root)

	# Title
	var title := Label.new()
	title.text = "Test Play Parameters"
	title.add_theme_font_size_override("font_size", 17)
	root.add_child(title)
	root.add_child(HSeparator.new())

	# Force Fresh checkbox
	_test_force_fresh_chk = CheckBox.new()
	_test_force_fresh_chk.text = "Force Fresh  (skip saved session resume)"
	_test_force_fresh_chk.button_pressed = true
	_test_force_fresh_chk.add_theme_font_size_override("font_size", 13)
	root.add_child(_test_force_fresh_chk)
	root.add_child(HSeparator.new())

	# Initial Variables section
	var vars_hdr := HBoxContainer.new()
	root.add_child(vars_hdr)
	var vars_lbl := Label.new()
	vars_lbl.text = "Initial Variables"
	vars_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vars_lbl.add_theme_font_size_override("font_size", 14)
	vars_hdr.add_child(vars_lbl)
	var add_var_btn := Button.new()
	add_var_btn.text = "+ Add"
	add_var_btn.add_theme_font_size_override("font_size", 12)
	add_var_btn.custom_minimum_size = Vector2(60, 26)
	add_var_btn.pressed.connect(func() -> void: _test_add_var_row("", null))
	vars_hdr.add_child(add_var_btn)
	_test_vars_vbox = VBoxContainer.new()
	_test_vars_vbox.add_theme_constant_override("separation", 4)
	root.add_child(_test_vars_vbox)
	root.add_child(HSeparator.new())

	# Initial Inventory section
	var inv_hdr := HBoxContainer.new()
	root.add_child(inv_hdr)
	var inv_lbl := Label.new()
	inv_lbl.text = "Initial Inventory"
	inv_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_lbl.add_theme_font_size_override("font_size", 14)
	inv_hdr.add_child(inv_lbl)
	var add_inv_btn := Button.new()
	add_inv_btn.text = "+ Add"
	add_inv_btn.add_theme_font_size_override("font_size", 12)
	add_inv_btn.custom_minimum_size = Vector2(60, 26)
	add_inv_btn.pressed.connect(func() -> void: _test_add_inv_row(""))
	inv_hdr.add_child(add_inv_btn)
	_test_inv_vbox = VBoxContainer.new()
	_test_inv_vbox.add_theme_constant_override("separation", 4)
	root.add_child(_test_inv_vbox)
	root.add_child(HSeparator.new())

	# Launch / Cancel buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	root.add_child(btn_row)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(80, 32)
	cancel_btn.pressed.connect(func() -> void: _test_params_popup.hide())
	btn_row.add_child(cancel_btn)
	var launch_btn := Button.new()
	launch_btn.text = "▶ Launch"
	launch_btn.custom_minimum_size = Vector2(100, 32)
	launch_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	launch_btn.pressed.connect(_on_test_launch_confirmed)
	btn_row.add_child(launch_btn)

func _test_add_var_row(key: String, value: Variant) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_test_vars_vbox.add_child(row)

	var k_edit := LineEdit.new()
	k_edit.placeholder_text = "key"
	k_edit.text = key
	k_edit.custom_minimum_size.x = 100.0
	k_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k_edit.add_theme_font_size_override("font_size", 13)
	row.add_child(k_edit)

	var mode_opt := OptionButton.new()
	mode_opt.add_item("Fixed", 0)
	mode_opt.add_item("Random", 1)
	mode_opt.custom_minimum_size.x = 88.0
	mode_opt.add_theme_font_size_override("font_size", 12)
	row.add_child(mode_opt)

	var eq_lbl := Label.new()
	eq_lbl.text = "="
	row.add_child(eq_lbl)

	var v_edit := LineEdit.new()
	v_edit.placeholder_text = "value"
	v_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_edit.add_theme_font_size_override("font_size", 13)
	row.add_child(v_edit)

	var min_edit := LineEdit.new()
	min_edit.placeholder_text = "min"
	min_edit.custom_minimum_size.x = 52.0
	min_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	min_edit.add_theme_font_size_override("font_size", 13)
	row.add_child(min_edit)

	var dash_lbl := Label.new()
	dash_lbl.text = "–"
	row.add_child(dash_lbl)

	var max_edit := LineEdit.new()
	max_edit.placeholder_text = "max"
	max_edit.custom_minimum_size.x = 52.0
	max_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	max_edit.add_theme_font_size_override("font_size", 13)
	row.add_child(max_edit)

	var is_random := false
	var fixed_str := ""
	var min_str := ""
	var max_str := ""
	if value is Dictionary and (value as Dictionary).has("random"):
		var range_spec: Variant = (value as Dictionary)["random"]
		if range_spec is Array and (range_spec as Array).size() >= 2:
			is_random = true
			min_str = str((range_spec as Array)[0])
			max_str = str((range_spec as Array)[1])
		elif range_spec is Dictionary:
			is_random = true
			min_str = str((range_spec as Dictionary).get("min", 0))
			max_str = str((range_spec as Dictionary).get("max", 0))
	if not is_random and value != null:
		fixed_str = str(value)
	v_edit.text = fixed_str
	min_edit.text = min_str
	max_edit.text = max_str
	mode_opt.select(1 if is_random else 0)

	row.set_meta("key_edit", k_edit)
	row.set_meta("mode_opt", mode_opt)
	row.set_meta("eq_lbl", eq_lbl)
	row.set_meta("value_edit", v_edit)
	row.set_meta("min_edit", min_edit)
	row.set_meta("dash_lbl", dash_lbl)
	row.set_meta("max_edit", max_edit)

	var sync_mode_ui := func() -> void:
		var random_mode: bool = mode_opt.selected == 1
		eq_lbl.visible = not random_mode
		v_edit.visible = not random_mode
		min_edit.visible = random_mode
		dash_lbl.visible = random_mode
		max_edit.visible = random_mode
	mode_opt.item_selected.connect(func(_i: int) -> void: sync_mode_ui.call())
	sync_mode_ui.call()

	var rem := Button.new()
	rem.text = "✕"
	rem.custom_minimum_size = Vector2(26, 0)
	rem.add_theme_font_override("font", FontManager.make_font("primary", 400))
	rem.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	rem.pressed.connect(func() -> void: row.queue_free())
	row.add_child(rem)

func _test_add_inv_row(item_id: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_test_inv_vbox.add_child(row)

	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.add_theme_font_size_override("font_size", 13)
	var all: Array = ExplorationItemDatabase.all_items()
	var sel_idx := 0
	for i: int in all.size():
		var it: Dictionary = all[i] as Dictionary
		var id: String = str(it.get("id", ""))
		var name_str: String = str(it.get("name", id))
		opt.add_item("%s  (%s)" % [name_str, id], i)
		opt.set_item_metadata(i, id)
		if id == item_id:
			sel_idx = i
	if all.size() > 0:
		opt.select(sel_idx)
	row.add_child(opt)

	var rem := Button.new()
	rem.text = "✕"
	rem.custom_minimum_size = Vector2(26, 0)
	rem.add_theme_font_override("font", FontManager.make_font("primary", 400))
	rem.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	rem.pressed.connect(func() -> void: row.queue_free())
	row.add_child(rem)

func _on_test_launch_confirmed() -> void:
	_test_params_popup.hide()

	# Collect initial vars
	var params: Dictionary = {}
	for row_node: Node in _test_vars_vbox.get_children():
		if not row_node is HBoxContainer:
			continue
		var row: HBoxContainer = row_node as HBoxContainer
		if not row.has_meta("key_edit"):
			continue
		var k: String = (row.get_meta("key_edit") as LineEdit).text.strip_edges()
		if k.is_empty():
			continue
		var mode_opt: OptionButton = row.get_meta("mode_opt") as OptionButton
		if mode_opt.selected == 1:
			var min_edit: LineEdit = row.get_meta("min_edit") as LineEdit
			var max_edit: LineEdit = row.get_meta("max_edit") as LineEdit
			var lo_text: String = min_edit.text.strip_edges()
			var hi_text: String = max_edit.text.strip_edges()
			if lo_text.is_valid_int() and hi_text.is_valid_int():
				params[k] = {"random": [int(lo_text), int(hi_text)]}
			else:
				params[k] = {"random": [0, 0]}
		else:
			params[k] = (row.get_meta("value_edit") as LineEdit).text.strip_edges()

	if _test_force_fresh_chk.button_pressed:
		params["force_fresh"] = true

	# Pre-seed inventory via launch_params special list
	var inv_items: Array = []
	for row_node: Node in _test_inv_vbox.get_children():
		if not row_node is HBoxContainer:
			continue
		var children: Array = (row_node as HBoxContainer).get_children()
		if children.is_empty():
			continue
		var opt := children[0] as OptionButton
		if opt.item_count > 0:
			var id: Variant = opt.get_item_metadata(opt.selected)
			if id != null and str(id) != "":
				inv_items.append(str(id))
	ExplorationManager.launch(_graph_path, "res://scenes/exploration_editor.tscn", params)
	# Seed inventory — launch calls start_session synchronously before the async
	# scene transition, so add_item here lands in the correct active session.
	for item_id: String in inv_items:
		ExplorationManager.add_item(item_id)

func _on_items_pressed() -> void:
	# Prevent duplicate
	if get_node_or_null("ExplorationItemManagerOverlay") != null:
		return
	var mgr: Control = load("res://scenes/exploration_item_manager.tscn").instantiate() as Control
	mgr.name = "ExplorationItemManagerOverlay"
	add_child(mgr)
	# Set anchors AFTER add_child so the parent rect is resolved
	mgr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _on_puzzles_pressed() -> void:
	if get_node_or_null("ExplorationPuzzleManagerOverlay") != null:
		return
	var mgr: Control = load("res://scenes/exploration_puzzle_manager.tscn").instantiate() as Control
	mgr.name = "ExplorationPuzzleManagerOverlay"
	add_child(mgr)
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

func _sanitize_vn_token(token: String) -> String:
	var s: String = token.strip_edges().to_lower()
	s = s.replace(" ", "_")
	s = s.replace("/", "_")
	return s

func _open_vn_editor_overlay(path: String) -> void:
	var vned: Control = load("res://scripts/VNEditor.gd").new()
	vned.name = "VNEditorOverlay"
	get_tree().current_scene.add_child(vned)
	vned.call_deferred("open_file", path)

func _ensure_vn_beat_file(path: String) -> bool:
	var abs_path: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		return true
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f == null:
		_set_status("ERROR: Could not create '%s'." % path)
		return false
	f.store_string("[]")
	f.close()
	return true

## Edit beats for a conditional VN row (path field in that condition row).
func _on_edit_cond_vn_beats_pressed(path_edit: LineEdit, var_edit: LineEdit, eq_edit: LineEdit) -> void:
	var path: String = path_edit.text.strip_edges()
	if path.is_empty():
		if _graph_path.is_empty():
			_set_status("Save the graph first before creating a VN scene.")
			return
		if _selected_node_id.is_empty():
			_set_status("Select a node first.")
			return
		var graph_name: String = _graph_path.get_file().get_basename()
		var var_t: String = _sanitize_vn_token(var_edit.text)
		var eq_t:  String = _sanitize_vn_token(eq_edit.text)
		if var_t.is_empty():
			var_t = "anyvar"
		if eq_t.is_empty():
			eq_t = "anyval"
		path = "res://exploration/vn/vn_%s/vn_%s_cond_%s_%s.json" % [
			graph_name, _selected_node_id, var_t, eq_t]
		_create_vn_subfolder(_graph_path)
		if not _ensure_vn_beat_file(path):
			return
		path_edit.text = path
		_commit_selected_node()
		_set_status("Created '%s' — opening VN Editor." % path.get_file())
	elif not _ensure_vn_beat_file(path):
		return
	else:
		_set_status("Opening VN Editor: %s" % path.get_file())
	_open_vn_editor_overlay(path)

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
		path = "res://exploration/vn/vn_%s/vn_%s_main.json" % [graph_name, _selected_node_id]
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
	elif not _ensure_vn_beat_file(path):
		return
	else:
		_set_status("Opening VN Editor: %s" % path.get_file())
	_open_vn_editor_overlay(path)

func _on_apply_pressed() -> void:
	_collect_graph_props()
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
	_populate_graph_props()
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
	_populate_graph_props()
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

func _on_copy_bug_loc_pressed() -> void:
	var node_id: String = _prop_id_edit.text.strip_edges() if _prop_id_edit != null else ""
	if node_id.is_empty():
		node_id = _selected_node_id.strip_edges()
	if node_id.is_empty():
		_set_status("Select a node with an ID first.")
		return
	var graph_label: String = _graph_path.get_file() if not _graph_path.is_empty() else "(unsaved graph)"
	var text: String = "graph=%s  node=%s" % [graph_label, node_id]
	DisplayServer.clipboard_set(text)
	_set_status("Copied: %s" % text)

func _set_status(text: String) -> void:
	if _status_lbl != null:
		_status_lbl.text = text
	print("[ExplorationEditor] %s" % text)

func _puzzle_params_guide_text(puzzle_id: String) -> String:
	if puzzle_id.is_empty():
		return "← Enter a puzzle id in the value field to see its parameter guide."
	var data: Dictionary = ExplorationPuzzleDatabase.get_puzzle(puzzle_id)
	if data.is_empty():
		return "⚠ Puzzle \"%s\" not found in the database." % puzzle_id
	var guide: String = str(data.get("params_guide", ""))
	if not ExplorationPuzzleDatabase.is_implemented(puzzle_id):
		var suffix: String = ("\n" + guide) if not guide.is_empty() else ""
		return "⚠ Not implemented yet — no scene registered.%s" % suffix
	if guide.is_empty():
		return "ℹ No parameter guide defined for this puzzle."
	return guide

## Update the params guide label for a play_puzzle action row.
## Looks up the puzzle by id in the database and reads its params_guide field.
func _update_puzzle_guide(lbl: Label, puzzle_id: String) -> void:
	lbl.text = _puzzle_params_guide_text(puzzle_id)
	if puzzle_id.is_empty():
		lbl.add_theme_color_override("font_color", Color(0.50, 0.55, 0.65))
	elif ExplorationPuzzleDatabase.get_puzzle(puzzle_id).is_empty():
		lbl.add_theme_color_override("font_color", Color(1.0, 0.60, 0.30))
	elif not ExplorationPuzzleDatabase.is_implemented(puzzle_id):
		lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.25))
	elif str(ExplorationPuzzleDatabase.get_puzzle(puzzle_id).get("params_guide", "")).is_empty():
		lbl.add_theme_color_override("font_color", Color(0.50, 0.55, 0.65))
	else:
		lbl.add_theme_color_override("font_color", Color(0.60, 0.85, 0.65))

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
