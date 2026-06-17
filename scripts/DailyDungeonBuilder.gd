extends Control
# Daily Dungeon Builder — drag-and-drop layout editor for dungeon map JSONs.
# Open via Admin Console: dungeon_builder [dungeon_id]

const CANVAS_W := 1400.0
const CANVAS_H := 820.0
const NODE_W   := 72.0
const NODE_H   := 52.0

const COLOR_NORMAL := Color(1.00, 0.72, 0.22)
const COLOR_BOSS   := Color(1.00, 0.35, 0.35)
const COLOR_ENTRY  := Color(0.30, 1.00, 0.60)

# ─────────────────────────────────────────────────────────────
# Line canvas helper
# ─────────────────────────────────────────────────────────────
class LineCanvas extends Control:
	var _lines: Array = []
	func set_lines(lines: Array) -> void:
		_lines = lines
		queue_redraw()
	func _draw() -> void:
		for ln: Dictionary in _lines:
			draw_line(ln["from"], ln["to"], ln["color"], 2.0, true)

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var _dungeon_id:    String = ""
var _layout:        Dictionary = {}   # working copy of the layout
var _positions:     Dictionary = {}   # node_id → Vector2 (center)
var _node_controls: Dictionary = {}   # node_id → Control
var _selected_id:   String = ""
var _drag_node_id:  String = ""
var _drag_start_mouse:    Vector2
var _drag_start_node_pos: Vector2
var _connect_from: String = ""        # first node clicked for connection

var _canvas:      Control    = null
var _line_canvas: LineCanvas = null
var _status_lbl:  Label      = null
var _dungeon_picker: OptionButton = null
var _mode_filter_opt: OptionButton = null   # header filter: All / Daily Dungeon / Story Mode
var _dungeon_mode_opt: OptionButton = null  # meta panel: this layout's mode
var _clear_modifiers_on_spin_chk: CheckBox = null
var _all_ids: Array = []
var _filtered_ids: Array = []  # subset of _all_ids shown in picker after mode filter

# Property panel refs
var _prop_panel:        Control  = null
var _prop_id_lbl:       Label    = null
var _prop_label_edit:   LineEdit = null
var _prop_type_opt:     OptionButton = null
var _prop_entry_chk:    CheckBox = null
var _prop_pack_edit:    LineEdit = null
var _prop_chars_edit:   TextEdit = null
var _prop_traps_edit:   TextEdit = null
var _prop_tech_edit:    TextEdit = null
var _prop_vault_opt:    OptionButton = null
var _prop_vault_form_opt: OptionButton = null

var _conn_text: TextEdit = null
var _prop_img_edit:     LineEdit = null
var _bg_edit:           LineEdit = null
var _dungeon_name_edit: LineEdit = null
var _canvas_bg_node:    Node     = null

# Battle-settings field refs (per-node)
var _prop_p1_name:       LineEdit = null
var _prop_p2_name:       LineEdit = null
var _prop_portrait_p1:   LineEdit = null
var _prop_p1_offset_x:   SpinBox  = null
var _prop_p1_offset_y:   SpinBox  = null
var _prop_p1_size:       SpinBox  = null
var _prop_portrait_p2:   LineEdit = null
var _prop_p2_offset_x:   SpinBox  = null
var _prop_p2_offset_y:   SpinBox  = null
var _prop_p2_size:       SpinBox  = null
var _prop_battle_bgm:    LineEdit = null
var _prop_bgm_vol:       SpinBox  = null
var _prop_ai_union_chk:  CheckBox = null
var _prop_plr_union_chk: CheckBox = null
var _prop_ai_pers_def: OptionButton = null
var _prop_ai_pers_off: OptionButton = null
var _prop_ai_pers_soc: OptionButton = null
var _player_forced_grid: Dictionary    = {}   # key="r,c"  value=card_name
var _ai_forced_grid:     Dictionary    = {}
var _player_forced_gc:   GridContainer = null
var _ai_forced_gc:       GridContainer = null
const ENEMY_TECH_SLOTS: int = 3
var _ai_forced_tech: Array = ["", "", ""]
var _ai_forced_tech_btns: Array[Button] = []

# Spinning wheel fields
var _prop_wheel_chk:            CheckBox      = null
var _prop_wheel_count:          SpinBox       = null
var _prop_wheel_outcome_picker: OptionButton  = null
var _prop_wheel_outcomes_vbox:  VBoxContainer = null
var _wheel_outcomes_list:       Array         = []   # Array[String]

# Message fields
var _prop_pre_msg_edit:  LineEdit = null
var _prop_post_msg_edit: LineEdit = null

# Battle data clipboard (Copy/Paste between nodes)
var _battle_clipboard: Dictionary = {}

# Dungeon BGM
var _dungeon_bgm_edit:   LineEdit            = null
var _dungeon_bgm_player: AudioStreamPlayer   = null

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 50
	_build_ui()
	_all_ids = DailyDungeonManager.get_all_layout_ids()
	_populate_dungeon_picker()
	if not _filtered_ids.is_empty():
		_load_dungeon(_filtered_ids[0])

# ─────────────────────────────────────────────────────────────
# Dungeon loading / saving
# ─────────────────────────────────────────────────────────────
func _load_dungeon(dungeon_id: String) -> void:
	_dungeon_id = dungeon_id
	_layout = DailyDungeonManager.get_layout(dungeon_id).duplicate(true)
	if _layout.is_empty():
		_layout = {"id": dungeon_id, "name": dungeon_id, "background": "", "nodes": [], "connections": []}
	_positions.clear()
	for nd: Dictionary in _layout.get("nodes", []):
		var nid: String = nd.get("id", "")
		_positions[nid] = Vector2(float(nd.get("x", 300)), float(nd.get("y", 400)))
	_selected_id = ""
	_connect_from = ""
	_rebuild_canvas()
	_refresh_canvas_bg()
	_update_prop_panel()
	if _dungeon_mode_opt:
		_dungeon_mode_opt.selected = 1 if _layout.get("mode", "daily_dungeon") == "story_mode" else 0
	if _dungeon_name_edit:
		_dungeon_name_edit.text = _layout.get("name", "")
	if _bg_edit:
		_bg_edit.text = _layout.get("background", "")
	if _dungeon_bgm_edit:
		_dungeon_bgm_edit.text = str(_layout.get("dungeon_bgm", ""))
	if _clear_modifiers_on_spin_chk:
		_clear_modifiers_on_spin_chk.button_pressed = bool(_layout.get("clear_modifiers_on_spin", false))
	_set_status("Loaded: %s  (%d nodes)" % [dungeon_id, _positions.size()])

func _save_layout() -> void:
	# Auto-apply current node panel edits and dungeon meta before saving
	_apply_node_changes()
	_layout["mode"]       = "story_mode" if _dungeon_mode_opt.selected == 1 else "daily_dungeon"
	_layout["name"]       = _dungeon_name_edit.text
	_layout["background"] = _bg_edit.text
	_layout["dungeon_bgm"] = _dungeon_bgm_edit.text.strip_edges() if _dungeon_bgm_edit != null else ""
	_layout["clear_modifiers_on_spin"] = _clear_modifiers_on_spin_chk.button_pressed \
			if _clear_modifiers_on_spin_chk != null else false
	# Write positions back to node data
	for nd: Dictionary in _layout.get("nodes", []):
		var nid: String = nd.get("id", "")
		var pos: Vector2 = _positions.get(nid, Vector2(300, 400))
		nd["x"] = int(pos.x)
		nd["y"] = int(pos.y)
	DailyDungeonManager.save_layout(_layout)
	_set_status("Saved: %s" % _dungeon_id)
	_refresh_canvas_bg()
	_rebuild_canvas()

func _refresh_canvas_bg() -> void:
	if _canvas_bg_node == null or not is_instance_valid(_canvas_bg_node):
		return
	var bg_path: String = _layout.get("background", "")
	if bg_path != "" and ResourceLoader.exists(bg_path):
		(_canvas_bg_node as TextureRect).texture = load(bg_path) as Texture2D
		_canvas_bg_node.visible = true
	else:
		(_canvas_bg_node as TextureRect).texture = null
		_canvas_bg_node.visible = false

# ─────────────────────────────────────────────────────────────
# Build UI
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.94)
	dimmer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(dimmer)

	_build_header()

	var body := HBoxContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_top = 56.0
	body.add_theme_constant_override("separation", 0)
	add_child(body)

	# Canvas area
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	body.add_child(scroll)

	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(CANVAS_W, CANVAS_H)
	_canvas.mouse_filter = MOUSE_FILTER_PASS
	scroll.add_child(_canvas)

	# Canvas background — dark fallback always shown
	var dark_bg := ColorRect.new()
	dark_bg.name = "_bg_dark"
	dark_bg.size = Vector2(CANVAS_W, CANVAS_H)
	dark_bg.color = Color(0.04, 0.06, 0.12, 1.0)
	dark_bg.mouse_filter = MOUSE_FILTER_IGNORE
	_canvas.add_child(dark_bg)

	# Canvas background — texture overlay (shown when a bg path is set)
	var bg := TextureRect.new()
	bg.name = "_bg_canvas"
	bg.size = Vector2(CANVAS_W, CANVAS_H)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	bg.visible = false
	_canvas.add_child(bg)
	_canvas_bg_node = bg

	var sz_lbl := Label.new()
	sz_lbl.text = "Canvas  1400 × 820   |  Drag to move nodes  |  Double-click a node to enter connection mode"
	sz_lbl.position = Vector2(8.0, 8.0)
	sz_lbl.add_theme_font_size_override("font_size", 10)
	sz_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.75, 0.55))
	sz_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	_canvas.add_child(sz_lbl)

	_line_canvas = LineCanvas.new()
	_line_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_line_canvas.mouse_filter = MOUSE_FILTER_IGNORE
	_canvas.add_child(_line_canvas)

	# Right property panel
	_build_prop_panel(body)

func _build_header() -> void:
	var header := Panel.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 56.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.05, 0.12, 1.0)
	sb.border_width_bottom = 1
	sb.border_color = Color(1.0, 0.72, 0.22, 0.35)
	header.add_theme_stylebox_override("panel", sb)
	add_child(header)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left  = 16.0
	hbox.offset_right = -16.0
	hbox.add_theme_constant_override("separation", 10)
	header.add_child(hbox)

	var title := Label.new()
	title.text = "DUNGEON BUILDER"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.30))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(title)

	var mode_filter_lbl := Label.new()
	mode_filter_lbl.text = "Mode:"
	mode_filter_lbl.add_theme_font_size_override("font_size", 12)
	mode_filter_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.8))
	mode_filter_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(mode_filter_lbl)

	_mode_filter_opt = OptionButton.new()
	_mode_filter_opt.custom_minimum_size = Vector2(140, 34)
	_mode_filter_opt.add_item("All")
	_mode_filter_opt.add_item("Daily Dungeon")
	_mode_filter_opt.add_item("Story Mode")
	_mode_filter_opt.item_selected.connect(func(_i: int) -> void: _populate_dungeon_picker())
	hbox.add_child(_mode_filter_opt)

	var pick_lbl := Label.new()
	pick_lbl.text = "Layout:"
	pick_lbl.add_theme_font_size_override("font_size", 12)
	pick_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.8))
	pick_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(pick_lbl)

	_dungeon_picker = OptionButton.new()
	_dungeon_picker.custom_minimum_size = Vector2(200, 34)
	_dungeon_picker.item_selected.connect(_on_dungeon_selected)
	hbox.add_child(_dungeon_picker)

	var new_btn := Button.new()
	new_btn.text = "+ New Layout"
	new_btn.custom_minimum_size = Vector2(110, 34)
	new_btn.add_theme_font_size_override("font_size", 12)
	new_btn.pressed.connect(_on_new_layout)
	hbox.add_child(new_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	_status_lbl = Label.new()
	_status_lbl.text = "No layout loaded"
	_status_lbl.add_theme_font_size_override("font_size", 12)
	_status_lbl.add_theme_color_override("font_color", Color(0.65, 0.8, 1.0, 0.8))
	_status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_lbl.custom_minimum_size = Vector2(300, 0)
	hbox.add_child(_status_lbl)

	for data: Array in [
		["SAVE", _save_layout, 90],
		["CLOSE", func() -> void: queue_free(), 80],
	]:
		var btn := Button.new()
		btn.text = data[0]
		btn.custom_minimum_size = Vector2(data[2], 34)
		btn.pressed.connect(data[1] as Callable)
		hbox.add_child(btn)

func _build_prop_panel(parent: Control) -> void:
	_prop_panel = Panel.new()
	_prop_panel.custom_minimum_size = Vector2(320, 0)
	_prop_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 0.98)
	sb.border_width_left = 1
	sb.border_color = Color(1.0, 0.72, 0.22, 0.18)
	_prop_panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(_prop_panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_prop_panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.offset_top = 0
	vbox.add_theme_constant_override("separation", 8)
	var vbox_sb := StyleBoxFlat.new()
	vbox_sb.bg_color = Color(0, 0, 0, 0)
	vbox.add_theme_stylebox_override("panel", vbox_sb)
	scroll.add_child(vbox)

	# Padding wrapper
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_bottom", 14)
	scroll.add_child(pad)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	pad.add_child(inner)

	# ── Header ──
	var hdr := Label.new()
	hdr.text = "NODE PROPERTIES"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(1.0, 0.78, 0.30, 0.7))
	inner.add_child(hdr)

	_prop_id_lbl = Label.new()
	_prop_id_lbl.text = "(select a node)"
	_prop_id_lbl.add_theme_font_size_override("font_size", 11)
	_prop_id_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 0.8))
	inner.add_child(_prop_id_lbl)

	# ── Label ──
	inner.add_child(_make_lbl("Label"))
	_prop_label_edit = LineEdit.new()
	_prop_label_edit.placeholder_text = "Display name"
	inner.add_child(_prop_label_edit)

	# ── Type ──
	inner.add_child(_make_lbl("Type"))
	_prop_type_opt = OptionButton.new()
	_prop_type_opt.add_item("normal")
	_prop_type_opt.add_item("boss")
	inner.add_child(_prop_type_opt)

	# ── Entry ──
	_prop_entry_chk = CheckBox.new()
	_prop_entry_chk.text = "Is entry node"
	inner.add_child(_prop_entry_chk)

	# ── Spinning Wheel ──
	_prop_wheel_chk = CheckBox.new()
	_prop_wheel_chk.text = "Is wheel node  (player spins here)"
	inner.add_child(_prop_wheel_chk)

	inner.add_child(_make_lbl("Number of outcomes  (used when custom list below is empty; 0 = full catalog pool)"))
	_prop_wheel_count = SpinBox.new()
	_prop_wheel_count.min_value = 0
	_prop_wheel_count.max_value = 99
	_prop_wheel_count.step = 1
	_prop_wheel_count.value = 8
	inner.add_child(_prop_wheel_count)

	inner.add_child(_make_lbl("Custom wheel outcomes  (optional — overrides count; duplicates = higher weight)"))
	var wheel_add_row := HBoxContainer.new()
	wheel_add_row.add_theme_constant_override("separation", 4)
	inner.add_child(wheel_add_row)
	_prop_wheel_outcome_picker = OptionButton.new()
	_prop_wheel_outcome_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prop_wheel_outcome_picker.add_item("no_effect")
	for _wk: String in DailyDungeonManager.get_all_modifier_keys():
		_prop_wheel_outcome_picker.add_item(_wk)
	wheel_add_row.add_child(_prop_wheel_outcome_picker)
	var wheel_add_btn := Button.new()
	wheel_add_btn.text = "+ Add"
	wheel_add_btn.custom_minimum_size = Vector2(60, 0)
	wheel_add_btn.pressed.connect(func() -> void:
		var picked: String = _prop_wheel_outcome_picker.get_item_text(
			_prop_wheel_outcome_picker.selected)
		_wheel_outcomes_list.append(picked)
		_refresh_wheel_outcomes_ui())
	wheel_add_row.add_child(wheel_add_btn)
	var wheel_clear_btn := Button.new()
	wheel_clear_btn.text = "Clear"
	wheel_clear_btn.custom_minimum_size = Vector2(52, 0)
	wheel_clear_btn.pressed.connect(func() -> void:
		_wheel_outcomes_list.clear()
		_refresh_wheel_outcomes_ui())
	wheel_add_row.add_child(wheel_clear_btn)

	_prop_wheel_outcomes_vbox = VBoxContainer.new()
	_prop_wheel_outcomes_vbox.add_theme_constant_override("separation", 2)
	inner.add_child(_prop_wheel_outcomes_vbox)

	# ── Pack reward ──
	inner.add_child(_make_lbl("Boss pack reward (boss only)"))
	_prop_pack_edit = LineEdit.new()
	_prop_pack_edit.placeholder_text = "e.g. Starter Pack"
	inner.add_child(_prop_pack_edit)

	# ── Node image ──
	inner.add_child(_make_lbl("Node image (optional)"))
	var img_row := HBoxContainer.new()
	img_row.add_theme_constant_override("separation", 4)
	inner.add_child(img_row)
	_prop_img_edit = LineEdit.new()
	_prop_img_edit.placeholder_text = "res://assets/..."
	_prop_img_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	img_row.add_child(_prop_img_edit)
	var img_browse := Button.new()
	img_browse.text = "..."
	img_browse.custom_minimum_size = Vector2(36, 0)
	img_browse.tooltip_text = "Browse for image"
	img_browse.pressed.connect(func() -> void:
		_open_file_dialog(func(p: String) -> void: _prop_img_edit.text = p))
	img_row.add_child(img_browse)

	inner.add_child(_make_sep())

	# ── Messages ──
	inner.add_child(_make_lbl("Pre-battle message  (shown on node arrival)"))
	_prop_pre_msg_edit = LineEdit.new()
	_prop_pre_msg_edit.placeholder_text = "e.g. Welcome to the grove, traveler!"
	_prop_pre_msg_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(_prop_pre_msg_edit)

	inner.add_child(_make_lbl("Post-battle message  (shown after result banner)"))
	_prop_post_msg_edit = LineEdit.new()
	_prop_post_msg_edit.placeholder_text = "e.g. You've proven your worth here."
	_prop_post_msg_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(_prop_post_msg_edit)

	inner.add_child(_make_sep())

	# ── AI Deck Vault (overrides inline deck + AI forced cells when set) ──
	inner.add_child(_make_lbl("AI Deck Vault (optional — highest priority)"))
	_prop_vault_opt = OptionButton.new()
	_prop_vault_opt.item_selected.connect(func(_i: int) -> void: _on_vault_selected())
	inner.add_child(_prop_vault_opt)
	AIDeckVault.populate_vault_option(_prop_vault_opt)
	inner.add_child(_make_lbl("Vault formation"))
	_prop_vault_form_opt = OptionButton.new()
	_prop_vault_form_opt.item_selected.connect(func(_i: int) -> void: _on_vault_selected())
	inner.add_child(_prop_vault_form_opt)

	# ── AI Deck ──
	inner.add_child(_make_lbl("AI Characters (one per line)"))
	_prop_chars_edit = TextEdit.new()
	_prop_chars_edit.custom_minimum_size = Vector2(0, 80)
	_prop_chars_edit.placeholder_text = "Space Boy\nScout Probe\n..."
	_prop_chars_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	inner.add_child(_prop_chars_edit)

	inner.add_child(_make_lbl("AI Traps (one per line)"))
	_prop_traps_edit = TextEdit.new()
	_prop_traps_edit.custom_minimum_size = Vector2(0, 60)
	_prop_traps_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	inner.add_child(_prop_traps_edit)

	inner.add_child(_make_lbl("AI Tech (one per line)"))
	_prop_tech_edit = TextEdit.new()
	_prop_tech_edit.custom_minimum_size = Vector2(0, 50)
	_prop_tech_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	inner.add_child(_prop_tech_edit)

	var apply_btn := Button.new()
	apply_btn.text = "Apply Node Changes"
	apply_btn.pressed.connect(_apply_node_changes)
	inner.add_child(apply_btn)

	inner.add_child(_make_sep())

	# ── Battle Settings ──
	var bs_hdr := Label.new()
	bs_hdr.text = "BATTLE SETTINGS"
	bs_hdr.add_theme_font_size_override("font_size", 12)
	bs_hdr.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0, 0.8))
	inner.add_child(bs_hdr)

	var copy_paste_row := HBoxContainer.new()
	copy_paste_row.add_theme_constant_override("separation", 6)
	inner.add_child(copy_paste_row)
	var copy_btn := Button.new()
	copy_btn.text = "Copy Battle Data"
	copy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_btn.pressed.connect(_copy_battle_data)
	copy_paste_row.add_child(copy_btn)
	var paste_btn := Button.new()
	paste_btn.text = "Paste Battle Data"
	paste_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paste_btn.pressed.connect(_paste_battle_data)
	copy_paste_row.add_child(paste_btn)

	inner.add_child(_make_lbl("Player 1 Name"))
	_prop_p1_name = LineEdit.new()
	_prop_p1_name.placeholder_text = "Player"
	inner.add_child(_prop_p1_name)

	inner.add_child(_make_lbl("Player 2 Name (AI)"))
	_prop_p2_name = LineEdit.new()
	_prop_p2_name.placeholder_text = "Enemy"
	inner.add_child(_prop_p2_name)

	inner.add_child(_make_lbl("Portrait P1"))
	var p1_browse_row := HBoxContainer.new()
	p1_browse_row.add_theme_constant_override("separation", 4)
	inner.add_child(p1_browse_row)
	_prop_portrait_p1 = LineEdit.new()
	_prop_portrait_p1.placeholder_text = "res://assets/..."
	_prop_portrait_p1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p1_browse_row.add_child(_prop_portrait_p1)
	var p1_img_btn := Button.new()
	p1_img_btn.text = "..."
	p1_img_btn.custom_minimum_size = Vector2(36, 0)
	p1_img_btn.pressed.connect(func() -> void:
		_open_file_dialog(func(p: String) -> void: _prop_portrait_p1.text = p))
	p1_browse_row.add_child(p1_img_btn)

	var p1_off_row := HBoxContainer.new()
	p1_off_row.add_theme_constant_override("separation", 4)
	inner.add_child(p1_off_row)
	p1_off_row.add_child(_make_lbl("Offset X"))
	_prop_p1_offset_x = SpinBox.new()
	_prop_p1_offset_x.min_value = -500.0; _prop_p1_offset_x.max_value = 500.0
	_prop_p1_offset_x.step = 1.0; _prop_p1_offset_x.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p1_off_row.add_child(_prop_p1_offset_x)
	p1_off_row.add_child(_make_lbl("Y"))
	_prop_p1_offset_y = SpinBox.new()
	_prop_p1_offset_y.min_value = -500.0; _prop_p1_offset_y.max_value = 500.0
	_prop_p1_offset_y.step = 1.0; _prop_p1_offset_y.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p1_off_row.add_child(_prop_p1_offset_y)

	inner.add_child(_make_lbl("P1 Portrait Size"))
	_prop_p1_size = SpinBox.new()
	_prop_p1_size.min_value = 0.1; _prop_p1_size.max_value = 5.0
	_prop_p1_size.step = 0.05; _prop_p1_size.value = 1.0
	inner.add_child(_prop_p1_size)

	inner.add_child(_make_lbl("Portrait P2 (AI)"))
	var p2_browse_row := HBoxContainer.new()
	p2_browse_row.add_theme_constant_override("separation", 4)
	inner.add_child(p2_browse_row)
	_prop_portrait_p2 = LineEdit.new()
	_prop_portrait_p2.placeholder_text = "res://assets/..."
	_prop_portrait_p2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p2_browse_row.add_child(_prop_portrait_p2)
	var p2_img_btn := Button.new()
	p2_img_btn.text = "..."
	p2_img_btn.custom_minimum_size = Vector2(36, 0)
	p2_img_btn.pressed.connect(func() -> void:
		_open_file_dialog(func(p: String) -> void: _prop_portrait_p2.text = p))
	p2_browse_row.add_child(p2_img_btn)

	var p2_off_row := HBoxContainer.new()
	p2_off_row.add_theme_constant_override("separation", 4)
	inner.add_child(p2_off_row)
	p2_off_row.add_child(_make_lbl("Offset X"))
	_prop_p2_offset_x = SpinBox.new()
	_prop_p2_offset_x.min_value = -500.0; _prop_p2_offset_x.max_value = 500.0
	_prop_p2_offset_x.step = 1.0; _prop_p2_offset_x.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p2_off_row.add_child(_prop_p2_offset_x)
	p2_off_row.add_child(_make_lbl("Y"))
	_prop_p2_offset_y = SpinBox.new()
	_prop_p2_offset_y.min_value = -500.0; _prop_p2_offset_y.max_value = 500.0
	_prop_p2_offset_y.step = 1.0; _prop_p2_offset_y.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p2_off_row.add_child(_prop_p2_offset_y)

	inner.add_child(_make_lbl("P2 Portrait Size"))
	_prop_p2_size = SpinBox.new()
	_prop_p2_size.min_value = 0.1; _prop_p2_size.max_value = 5.0
	_prop_p2_size.step = 0.05; _prop_p2_size.value = 1.0
	inner.add_child(_prop_p2_size)

	inner.add_child(_make_lbl("Battle BGM"))
	var bgm_browse_row := HBoxContainer.new()
	bgm_browse_row.add_theme_constant_override("separation", 4)
	inner.add_child(bgm_browse_row)
	_prop_battle_bgm = LineEdit.new()
	_prop_battle_bgm.placeholder_text = "res://assets/audio/..."
	_prop_battle_bgm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bgm_browse_row.add_child(_prop_battle_bgm)
	var bgm_btn := Button.new()
	bgm_btn.text = "..."
	bgm_btn.custom_minimum_size = Vector2(36, 0)
	bgm_btn.pressed.connect(func() -> void:
		_open_file_dialog_audio(func(p: String) -> void: _prop_battle_bgm.text = p))
	bgm_browse_row.add_child(bgm_btn)

	inner.add_child(_make_lbl("BGM Volume (0–100)"))
	_prop_bgm_vol = SpinBox.new()
	_prop_bgm_vol.min_value = 0.0; _prop_bgm_vol.max_value = 100.0
	_prop_bgm_vol.step = 1.0; _prop_bgm_vol.value = 100.0
	inner.add_child(_prop_bgm_vol)

	_prop_ai_union_chk = CheckBox.new()
	_prop_ai_union_chk.text = "AI union enabled"
	_prop_ai_union_chk.button_pressed = true
	inner.add_child(_prop_ai_union_chk)

	_prop_plr_union_chk = CheckBox.new()
	_prop_plr_union_chk.text = "Player union enabled"
	_prop_plr_union_chk.button_pressed = true
	inner.add_child(_prop_plr_union_chk)

	var _def_names: Array = ["Random","Frontline","Fortress","Watch Tower","Mine Field",
		"Tomb Trap","Bait Trap","Diagonal Shield","Cluster Defender","Checker",
		"Straightforward","Midwit","Symmetric Defender","Random Defender","Religious",
		"Zoro","Helios","Helios 2","Zoro 2","Tomb Trap (Hard)","Frontline (Hard)"]
	var _off_names: Array = ["Random","Center Hoarder","Border Guard","Corner Assassin",
		"Melee Fighter","Sniper","Leftist","Rightist","X Sabre","Crusader",
		"Column Crusher","Row Ripper","Revealed Hunter","Explorer","Tinkerer",
		"Berserker","Shadow Lurker","Sleeping Dragon","Rambo","Spy",
		"X Alien","Technophobia","Witchhunter"]
	var _soc_names: Array = ["Random","Degen","Talkative","Fiddly","Flirty","Bully",
		"Fun Guy","Daredevil","Vengeful","Paranoid","Skeptical","Ungrateful",
		"Monk","Eager","Introvert"]
	inner.add_child(_make_lbl("AI Defensive Personality"))
	_prop_ai_pers_def = OptionButton.new()
	_prop_ai_pers_def.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prop_ai_pers_def.add_theme_font_size_override("font_size", 12)
	for _dn: Variant in _def_names: _prop_ai_pers_def.add_item(_dn as String)
	inner.add_child(_prop_ai_pers_def)
	inner.add_child(_make_lbl("AI Offensive Personality"))
	_prop_ai_pers_off = OptionButton.new()
	_prop_ai_pers_off.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prop_ai_pers_off.add_theme_font_size_override("font_size", 12)
	for _on: Variant in _off_names: _prop_ai_pers_off.add_item(_on as String)
	inner.add_child(_prop_ai_pers_off)
	inner.add_child(_make_lbl("AI Social Personality"))
	_prop_ai_pers_soc = OptionButton.new()
	_prop_ai_pers_soc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prop_ai_pers_soc.add_theme_font_size_override("font_size", 12)
	for _sn: Variant in _soc_names: _prop_ai_pers_soc.add_item(_sn as String)
	inner.add_child(_prop_ai_pers_soc)

	inner.add_child(_make_lbl("Player Forced Cells  (click cell to assign card)"))
	_player_forced_gc = _build_forced_grid_bld(_player_forced_grid)
	inner.add_child(_player_forced_gc)

	inner.add_child(_make_lbl("AI Forced Cells  (click cell to assign card)"))
	_ai_forced_gc = _build_forced_grid_bld(_ai_forced_grid)
	inner.add_child(_ai_forced_gc)

	inner.add_child(_make_lbl("AI Forced Tech Hand  (tap slot — empty = random)"))
	var ai_tech_row := HBoxContainer.new()
	ai_tech_row.add_theme_constant_override("separation", 6)
	inner.add_child(ai_tech_row)
	_ai_forced_tech_btns.clear()
	for slot: int in range(ENEMY_TECH_SLOTS):
		var tbtn := Button.new()
		tbtn.custom_minimum_size = Vector2(0, 36)
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtn.clip_text = true
		tbtn.add_theme_font_size_override("font_size", 11)
		var slot_cap := slot
		tbtn.pressed.connect(func() -> void: _open_ai_forced_tech_picker_bld(slot_cap))
		ai_tech_row.add_child(tbtn)
		_ai_forced_tech_btns.append(tbtn)
	_refresh_ai_forced_tech_row_bld()

	inner.add_child(_make_sep())

	# ── Connections ──
	inner.add_child(_make_lbl("Connections (from_id -> to_id, one per line)\nor click two nodes on canvas to toggle"))
	_conn_text = TextEdit.new()
	_conn_text.custom_minimum_size = Vector2(0, 80)
	_conn_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	inner.add_child(_conn_text)

	var conn_apply := Button.new()
	conn_apply.text = "Apply Connections"
	conn_apply.pressed.connect(_apply_connections)
	inner.add_child(conn_apply)

	inner.add_child(_make_sep())

	# ── Add / Delete node ──
	inner.add_child(_make_lbl("Add new node"))
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	inner.add_child(add_row)
	var _new_id_edit := LineEdit.new()
	_new_id_edit.placeholder_text = "node_id"
	_new_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(_new_id_edit)
	var add_node_btn := Button.new()
	add_node_btn.text = "Add"
	add_node_btn.custom_minimum_size = Vector2(60, 0)
	add_node_btn.pressed.connect(func() -> void: _add_node(_new_id_edit.text))
	add_row.add_child(add_node_btn)

	var del_btn := Button.new()
	del_btn.text = "Delete Selected Node"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	del_btn.pressed.connect(_delete_selected_node)
	inner.add_child(del_btn)

	inner.add_child(_make_sep())

	# ── Dungeon meta ──
	inner.add_child(_make_lbl("Dungeon Mode"))
	_dungeon_mode_opt = OptionButton.new()
	_dungeon_mode_opt.add_item("Daily Dungeon")
	_dungeon_mode_opt.add_item("Story Mode")
	inner.add_child(_dungeon_mode_opt)

	inner.add_child(_make_lbl("Dungeon name"))
	_dungeon_name_edit = LineEdit.new()
	inner.add_child(_dungeon_name_edit)

	inner.add_child(_make_lbl("Background image"))
	var bg_row := HBoxContainer.new()
	bg_row.add_theme_constant_override("separation", 4)
	inner.add_child(bg_row)
	_bg_edit = LineEdit.new()
	_bg_edit.placeholder_text = "res://assets/..."
	_bg_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg_row.add_child(_bg_edit)
	var bg_browse := Button.new()
	bg_browse.text = "..."
	bg_browse.custom_minimum_size = Vector2(36, 0)
	bg_browse.tooltip_text = "Browse for background image"
	bg_browse.pressed.connect(func() -> void:
		_open_file_dialog(func(p: String) -> void: _bg_edit.text = p))
	bg_row.add_child(bg_browse)

	inner.add_child(_make_lbl("Dungeon BGM"))
	var bgm_meta_row := HBoxContainer.new()
	bgm_meta_row.add_theme_constant_override("separation", 4)
	inner.add_child(bgm_meta_row)
	_dungeon_bgm_edit = LineEdit.new()
	_dungeon_bgm_edit.placeholder_text = "res://assets/audio/..."
	_dungeon_bgm_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bgm_meta_row.add_child(_dungeon_bgm_edit)
	var bgm_meta_browse := Button.new()
	bgm_meta_browse.text = "..."
	bgm_meta_browse.custom_minimum_size = Vector2(36, 0)
	bgm_meta_browse.tooltip_text = "Browse for BGM"
	bgm_meta_browse.pressed.connect(func() -> void:
		_open_file_dialog_audio(func(p: String) -> void: _dungeon_bgm_edit.text = p))
	bgm_meta_row.add_child(bgm_meta_browse)
	var bgm_preview_btn := Button.new()
	bgm_preview_btn.text = "▶"
	bgm_preview_btn.custom_minimum_size = Vector2(36, 0)
	bgm_preview_btn.tooltip_text = "Preview BGM"
	bgm_preview_btn.pressed.connect(func() -> void:
		var path: String = _dungeon_bgm_edit.text.strip_edges()
		if path.is_empty() or not ResourceLoader.exists(path):
			_set_status("BGM not found: %s" % path)
			return
		if _dungeon_bgm_player == null:
			_dungeon_bgm_player = AudioStreamPlayer.new()
			add_child(_dungeon_bgm_player)
		_dungeon_bgm_player.stream = load(path)
		if _dungeon_bgm_player.stream is AudioStreamMP3:
			(_dungeon_bgm_player.stream as AudioStreamMP3).loop = true
		_dungeon_bgm_player.play()
		_set_status("Previewing: %s" % path.get_file()))
	bgm_meta_row.add_child(bgm_preview_btn)
	var bgm_stop_btn := Button.new()
	bgm_stop_btn.text = "■"
	bgm_stop_btn.custom_minimum_size = Vector2(36, 0)
	bgm_stop_btn.tooltip_text = "Stop BGM"
	bgm_stop_btn.pressed.connect(func() -> void:
		if _dungeon_bgm_player != null:
			_dungeon_bgm_player.stop()
		_set_status("BGM stopped"))
	bgm_meta_row.add_child(bgm_stop_btn)

	_clear_modifiers_on_spin_chk = CheckBox.new()
	_clear_modifiers_on_spin_chk.text = "Clear modifiers on spin  (replace old wheel modifiers each spin)"
	inner.add_child(_clear_modifiers_on_spin_chk)

	var meta_apply := Button.new()
	meta_apply.text = "Apply Dungeon Meta"
	meta_apply.pressed.connect(func() -> void:
		_layout["name"]       = _dungeon_name_edit.text
		_layout["background"] = _bg_edit.text
		_layout["dungeon_bgm"] = _dungeon_bgm_edit.text.strip_edges()
		_layout["mode"]       = "story_mode" if _dungeon_mode_opt.selected == 1 else "daily_dungeon"
		_layout["clear_modifiers_on_spin"] = _clear_modifiers_on_spin_chk.button_pressed
		_set_status("Meta updated"))
	inner.add_child(meta_apply)

	# Populate meta fields (also refreshed in _load_dungeon)
	_dungeon_name_edit.text = _layout.get("name", "")
	_bg_edit.text           = _layout.get("background", "")

func _opt_select(opt: OptionButton, value: String) -> void:
	if value == "":
		opt.selected = 0
		return
	for i in range(opt.item_count):
		if opt.get_item_text(i) == value:
			opt.selected = i
			return
	opt.selected = 0

func _make_lbl(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.88, 0.7))
	return lbl

func _make_sep() -> ColorRect:
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(1.0, 0.72, 0.22, 0.15)
	return sep

# ─────────────────────────────────────────────────────────────
# Canvas population
# ─────────────────────────────────────────────────────────────
func _rebuild_canvas() -> void:
	for ch in _canvas.get_children():
		if ch == _line_canvas:
			continue
		if ch is ColorRect or ch is Label:
			if ch.mouse_filter == MOUSE_FILTER_IGNORE:
				continue
		if ch.name.begins_with("_bg") or ch.name.begins_with("_sz"):
			continue
		if not (ch is LineCanvas):
			ch.queue_free()
	_node_controls.clear()
	await get_tree().process_frame

	for nd: Dictionary in _layout.get("nodes", []):
		_create_node_control(nd)
	_rebuild_lines()
	_update_conn_text()

func _create_node_control(nd: Dictionary) -> void:
	var node_id: String = nd.get("id", "")
	var is_boss:  bool  = nd.get("type", "normal") == "boss"
	var is_entry: bool  = nd.get("is_entry", false)
	var pos: Vector2    = _positions.get(node_id, Vector2(300, 400))

	var ctrl := Panel.new()
	ctrl.size           = Vector2(NODE_W, NODE_H)
	ctrl.position       = pos - Vector2(NODE_W * 0.5, NODE_H * 0.5)
	ctrl.mouse_filter   = MOUSE_FILTER_STOP
	ctrl.clip_contents  = true

	var border_col: Color = COLOR_BOSS if is_boss else (COLOR_ENTRY if is_entry else COLOR_NORMAL)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.10, 0.22, 0.97)
	sb.border_width_left   = 2; sb.border_width_top    = 2
	sb.border_width_right  = 2; sb.border_width_bottom = 2
	sb.border_color = border_col
	sb.corner_radius_top_left     = 6; sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_right = 6; sb.corner_radius_bottom_left  = 6
	if _selected_id == node_id:
		sb.border_color = Color(0.3, 0.9, 1.0)
	ctrl.add_theme_stylebox_override("panel", sb)

	var type_lbl := Label.new()
	type_lbl.text = "B" if is_boss else ("E" if is_entry else "N")
	type_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	type_lbl.offset_left  = 4.0; type_lbl.offset_top = 2.0
	type_lbl.offset_right = 20.0; type_lbl.offset_bottom = 18.0
	type_lbl.add_theme_font_size_override("font_size", 10)
	type_lbl.add_theme_color_override("font_color", border_col)
	type_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	ctrl.add_child(type_lbl)

	var id_lbl := Label.new()
	id_lbl.text = node_id
	id_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	id_lbl.offset_top = 14.0
	id_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	id_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	id_lbl.add_theme_font_size_override("font_size", 9)
	id_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 0.9))
	id_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	ctrl.add_child(id_lbl)

	var label_lbl := Label.new()
	label_lbl.text = nd.get("label", "")
	label_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label_lbl.offset_top    = -14.0; label_lbl.offset_bottom = -2.0
	label_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_lbl.add_theme_font_size_override("font_size", 8)
	label_lbl.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9, 0.75))
	label_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	ctrl.add_child(label_lbl)

	# Node image thumbnail (if set) — clip_contents on ctrl handles any overflow
	var img_path: String = nd.get("image", "")
	if img_path != "" and ResourceLoader.exists(img_path):
		var thumb := TextureRect.new()
		thumb.texture             = load(img_path) as Texture2D
		thumb.custom_minimum_size = Vector2(NODE_W - 4.0, NODE_H - 4.0)
		thumb.size                = Vector2(NODE_W - 4.0, NODE_H - 4.0)
		thumb.position            = Vector2(2.0, 2.0)
		thumb.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb.modulate            = Color(1.0, 1.0, 1.0, 1.0)
		thumb.mouse_filter        = MOUSE_FILTER_IGNORE
		ctrl.add_child(thumb)

	var nid_cap := node_id
	ctrl.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_on_node_pressed(nid_cap, ctrl, ev.double_click))

	_canvas.add_child(ctrl)
	_node_controls[node_id] = ctrl

func _rebuild_lines() -> void:
	var lines: Array = []
	for conn: Array in _layout.get("connections", []):
		if conn.size() < 2:
			continue
		var a: String = conn[0]; var b: String = conn[1]
		var pa: Vector2 = _positions.get(a, Vector2())
		var pb: Vector2 = _positions.get(b, Vector2())
		lines.append({"from": pa, "to": pb, "color": Color(1.0, 0.72, 0.22, 0.45)})
	if not _connect_from.is_empty():
		var pf: Vector2 = _positions.get(_connect_from, Vector2())
		lines.append({"from": pf, "to": _canvas.get_local_mouse_position(), "color": Color(0.3, 0.9, 1.0, 0.6)})
	_line_canvas.set_lines(lines)

# ─────────────────────────────────────────────────────────────
# Node interaction
# ─────────────────────────────────────────────────────────────
func _on_node_pressed(node_id: String, ctrl: Control, is_double_click: bool = false) -> void:
	# Single click always selects the node
	_selected_id = node_id
	_update_prop_panel()
	_refresh_node_borders()
	ctrl.move_to_front()

	if _connect_from.is_empty():
		if is_double_click:
			# Double-click: enter connection mode
			_connect_from = node_id
			_set_status("Connection mode: %s  — click another node to toggle connection" % node_id)
		else:
			_set_status("Selected: %s  (double-click to enter connection mode)" % node_id)
	else:
		# Already in connection mode: any click on another node completes it
		if _connect_from == node_id:
			_connect_from = ""
			_set_status("Cancelled connection")
		else:
			_toggle_connection(_connect_from, node_id)
			_connect_from = ""
			_update_conn_text()
			_rebuild_lines()
	get_viewport().set_input_as_handled()

func _toggle_connection(a: String, b: String) -> void:
	var conns: Array = _layout.get("connections", [])
	for i: int in range(conns.size()):
		var c: Array = conns[i]
		if (c[0] == a and c[1] == b) or (c[0] == b and c[1] == a):
			conns.remove_at(i)
			_layout["connections"] = conns
			_set_status("Removed connection: %s ↔ %s" % [a, b])
			return
	conns.append([a, b])
	_layout["connections"] = conns
	_set_status("Added connection: %s → %s" % [a, b])

func _refresh_node_borders() -> void:
	for nid: String in _node_controls:
		var nd: Dictionary = _find_node(nid)
		var is_boss: bool  = nd.get("type", "normal") == "boss"
		var is_entry: bool = nd.get("is_entry", false)
		var border_col: Color = Color(0.3, 0.9, 1.0) if nid == _selected_id \
			else (COLOR_BOSS if is_boss else (COLOR_ENTRY if is_entry else COLOR_NORMAL))
		var ctrl: Control = _node_controls[nid]
		var sb2 := StyleBoxFlat.new()
		sb2.bg_color = Color(0.05, 0.10, 0.22, 0.97)
		sb2.border_width_left  = 2; sb2.border_width_top    = 2
		sb2.border_width_right = 2; sb2.border_width_bottom = 2
		sb2.border_color = border_col
		sb2.corner_radius_top_left     = 6; sb2.corner_radius_top_right    = 6
		sb2.corner_radius_bottom_right = 6; sb2.corner_radius_bottom_left  = 6
		ctrl.add_theme_stylebox_override("panel", sb2)

# ─────────────────────────────────────────────────────────────
# Drag tracking
# ─────────────────────────────────────────────────────────────
func _input(ev: InputEvent) -> void:
	if _drag_node_id != "":
		if ev is InputEventMouseMotion:
			var ctrl: Control = _node_controls.get(_drag_node_id) as Control
			if ctrl and _canvas:
				var delta: Vector2 = _canvas.get_local_mouse_position() - _drag_start_mouse
				var new_pos: Vector2 = _drag_start_node_pos + delta
				new_pos.x = clampf(new_pos.x, 0.0, CANVAS_W - NODE_W)
				new_pos.y = clampf(new_pos.y, 0.0, CANVAS_H - NODE_H)
				ctrl.position = new_pos
				_positions[_drag_node_id] = new_pos + Vector2(NODE_W * 0.5, NODE_H * 0.5)
				_rebuild_lines()
				_status_lbl.text = "%s → x: %.0f  y: %.0f" % [
					_drag_node_id,
					_positions[_drag_node_id].x, _positions[_drag_node_id].y]
				get_viewport().set_input_as_handled()
		elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
			_drag_node_id = ""
		return

	# Start drag only when we have a selected node with significant motion
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		# Check if mouse is over a node control to init drag
		for nid: String in _node_controls:
			var ctrl: Control = _node_controls[nid]
			if ctrl.get_global_rect().has_point(get_global_mouse_position()):
				# Only start drag after slight movement — handled by mouse-motion check
				_drag_node_id       = nid
				_drag_start_mouse   = _canvas.get_local_mouse_position()
				_drag_start_node_pos = ctrl.position
				ctrl.move_to_front()
				break

# ─────────────────────────────────────────────────────────────
# Property panel
# ─────────────────────────────────────────────────────────────
func _update_prop_panel() -> void:
	if _prop_id_lbl == null:
		return
	if _selected_id.is_empty():
		_prop_id_lbl.text = "(select a node)"
		return
	var nd: Dictionary = _find_node(_selected_id)
	_prop_id_lbl.text   = "ID: %s" % _selected_id
	_prop_label_edit.text = nd.get("label", "")
	_prop_type_opt.selected = 1 if nd.get("type", "normal") == "boss" else 0
	_prop_entry_chk.button_pressed = nd.get("is_entry", false)
	if _prop_wheel_chk != null:
		_prop_wheel_chk.button_pressed = bool(nd.get("is_wheel_node", false))
	if _prop_wheel_count != null:
		_prop_wheel_count.value = int(nd.get("wheel_outcome_count", 8))
	var _raw_wo: Variant = nd.get("wheel_outcomes", [])
	_wheel_outcomes_list = (_raw_wo as Array).duplicate() if _raw_wo is Array else []
	_refresh_wheel_outcomes_ui()
	_prop_pack_edit.text = nd.get("pack_reward", "")
	_prop_img_edit.text  = nd.get("image", "")
	if _prop_pre_msg_edit != null:
		_prop_pre_msg_edit.text  = str(nd.get("pre_battle_message", ""))
	if _prop_post_msg_edit != null:
		_prop_post_msg_edit.text = str(nd.get("post_battle_message", ""))
	var deck: Dictionary = nd.get("ai_deck", {})
	var bs: Dictionary = nd.get("battle_settings", {})
	_prop_chars_edit.text = "\n".join(PackedStringArray(deck.get("characters", [])))
	_prop_traps_edit.text = "\n".join(PackedStringArray(deck.get("traps", [])))
	_prop_tech_edit.text  = "\n".join(PackedStringArray(deck.get("tech", [])))
	if _prop_vault_opt != null:
		AIDeckVault.populate_vault_option(_prop_vault_opt)
		var vault_id: String = str(nd.get("ai_deck_vault", "")).strip_edges()
		if vault_id.is_empty():
			vault_id = str(bs.get("ai_deck_vault", "")).strip_edges()
		AIDeckVault.select_vault_option(_prop_vault_opt, vault_id)
		_on_vault_selected(false)
		if _prop_vault_form_opt != null:
			var form_idx: int = int(nd.get("ai_deck_vault_formation", bs.get("ai_deck_vault_formation", 0)))
			AIDeckVault.select_formation_option(_prop_vault_form_opt, form_idx)

	# Battle settings
	if _prop_p1_name != null:
		_prop_p1_name.text       = str(bs.get("player1_name", ""))
		_prop_p2_name.text       = str(bs.get("player2_name", ""))
		_prop_portrait_p1.text   = str(bs.get("portrait_p1", ""))
		_prop_p1_offset_x.value  = float(bs.get("portrait_p1_offset_x", 0.0))
		_prop_p1_offset_y.value  = float(bs.get("portrait_p1_offset_y", 0.0))
		_prop_p1_size.value      = float(bs.get("portrait_p1_size", 1.0))
		_prop_portrait_p2.text   = str(bs.get("portrait_p2", ""))
		_prop_p2_offset_x.value  = float(bs.get("portrait_p2_offset_x", 0.0))
		_prop_p2_offset_y.value  = float(bs.get("portrait_p2_offset_y", 0.0))
		_prop_p2_size.value      = float(bs.get("portrait_p2_size", 1.0))
		_prop_battle_bgm.text    = str(bs.get("battle_bgm", ""))
		_prop_bgm_vol.value      = float(bs.get("battle_bgm_volume", 100.0))
		_prop_ai_union_chk.button_pressed  = bool(bs.get("ai_union_enabled", true))
		_prop_plr_union_chk.button_pressed = bool(bs.get("player_union_enabled", true))
		_opt_select(_prop_ai_pers_def, str(bs.get("ai_personality_defensive", "")))
		_opt_select(_prop_ai_pers_off, str(bs.get("ai_personality_offensive", "")))
		_opt_select(_prop_ai_pers_soc, str(bs.get("ai_personality_social",    "")))
		var raw_pfc: Variant = bs.get("player_forced_cells", [])
		var raw_afc: Variant = bs.get("ai_forced_cells", [])
		_rebuild_forced_grid_bld(_player_forced_grid, _player_forced_gc,
			raw_pfc if raw_pfc is Array else [])
		_rebuild_forced_grid_bld(_ai_forced_grid, _ai_forced_gc,
			raw_afc if raw_afc is Array else [])
		_load_ai_forced_tech_from_bs(bs, deck.get("tech", []))

func _apply_node_changes() -> void:
	if _selected_id.is_empty():
		_set_status("No node selected")
		return
	var nd: Dictionary = _find_node(_selected_id)
	if nd.is_empty():
		return
	nd["label"]    = _prop_label_edit.text.strip_edges()
	nd["type"]     = "boss" if _prop_type_opt.selected == 1 else "normal"
	nd["is_entry"] = _prop_entry_chk.button_pressed
	nd["is_wheel_node"]  = _prop_wheel_chk.button_pressed if _prop_wheel_chk != null else false
	nd["wheel_outcome_count"] = int(_prop_wheel_count.value) if _prop_wheel_count != null else 0
	nd["wheel_outcomes"] = _wheel_outcomes_list.duplicate()
	nd["pack_reward"] = _prop_pack_edit.text.strip_edges()
	nd["image"]       = _prop_img_edit.text.strip_edges()
	if _prop_pre_msg_edit != null:
		nd["pre_battle_message"]  = _prop_pre_msg_edit.text.strip_edges()
	if _prop_post_msg_edit != null:
		nd["post_battle_message"] = _prop_post_msg_edit.text.strip_edges()
	# Parse AI deck
	var chars: Array = []
	for line: String in _prop_chars_edit.text.split("\n"):
		var s: String = line.strip_edges()
		if not s.is_empty():
			chars.append(s)
	var traps: Array = []
	for line: String in _prop_traps_edit.text.split("\n"):
		var s: String = line.strip_edges()
		if not s.is_empty():
			traps.append(s)
	var techs: Array = []
	for line: String in _prop_tech_edit.text.split("\n"):
		var s: String = line.strip_edges()
		if not s.is_empty():
			techs.append(s)
	nd["ai_deck"] = {"characters": chars, "traps": traps, "tech": techs}
	if _prop_vault_opt != null:
		var vault_id: String = AIDeckVault.option_entry_id(_prop_vault_opt)
		if vault_id.is_empty():
			nd.erase("ai_deck_vault")
			nd.erase("ai_deck_vault_formation")
		else:
			nd["ai_deck_vault"] = vault_id
			var form_idx: int = AIDeckVault.option_formation_index(_prop_vault_form_opt)
			if form_idx != 0:
				nd["ai_deck_vault_formation"] = form_idx
			else:
				nd.erase("ai_deck_vault_formation")
	# Collect battle settings
	if _prop_p1_name != null:
		var pfc: Array = _collect_forced_cells_from_grid_bld(_player_forced_grid)
		var afc: Array = _collect_forced_cells_from_grid_bld(_ai_forced_grid)
		var aft: Array = _collect_ai_forced_tech_bld()
		nd["battle_settings"] = {
			"player1_name":         _prop_p1_name.text.strip_edges(),
			"player2_name":         _prop_p2_name.text.strip_edges(),
			"portrait_p1":          _prop_portrait_p1.text.strip_edges(),
			"portrait_p1_offset_x": _prop_p1_offset_x.value,
			"portrait_p1_offset_y": _prop_p1_offset_y.value,
			"portrait_p1_size":     _prop_p1_size.value,
			"portrait_p2":          _prop_portrait_p2.text.strip_edges(),
			"portrait_p2_offset_x": _prop_p2_offset_x.value,
			"portrait_p2_offset_y": _prop_p2_offset_y.value,
			"portrait_p2_size":     _prop_p2_size.value,
			"battle_bgm":           _prop_battle_bgm.text.strip_edges(),
			"battle_bgm_volume":    _prop_bgm_vol.value,
			"ai_union_enabled":     _prop_ai_union_chk.button_pressed,
			"player_union_enabled": _prop_plr_union_chk.button_pressed,
			"ai_personality_defensive": _prop_ai_pers_def.get_item_text(_prop_ai_pers_def.selected) if _prop_ai_pers_def.selected > 0 else "",
			"ai_personality_offensive": _prop_ai_pers_off.get_item_text(_prop_ai_pers_off.selected) if _prop_ai_pers_off.selected > 0 else "",
			"ai_personality_social":    _prop_ai_pers_soc.get_item_text(_prop_ai_pers_soc.selected) if _prop_ai_pers_soc.selected > 0 else "",
			"player_forced_cells":  pfc,
			"ai_forced_cells":      afc,
			"ai_forced_tech":       aft,
		}
	# Rebuild node control to reflect label change
	if _node_controls.has(_selected_id):
		_node_controls[_selected_id].queue_free()
		_node_controls.erase(_selected_id)
	_create_node_control(nd)
	_refresh_node_borders()
	_set_status("Applied: %s" % _selected_id)

# ─────────────────────────────────────────────────────────────
# Connections text
# ─────────────────────────────────────────────────────────────
func _update_conn_text() -> void:
	if _conn_text == null:
		return
	var lines: Array = []
	for conn: Array in _layout.get("connections", []):
		if conn.size() >= 2:
			lines.append("%s -> %s" % [conn[0], conn[1]])
	_conn_text.text = "\n".join(PackedStringArray(lines))

func _apply_connections() -> void:
	var conns: Array = []
	for line: String in _conn_text.text.split("\n"):
		var s: String = line.strip_edges()
		if s.is_empty():
			continue
		var sep := s.find("->")
		if sep < 0:
			continue
		var a: String = s.substr(0, sep).strip_edges()
		var b: String = s.substr(sep + 2).strip_edges()
		if not a.is_empty() and not b.is_empty():
			conns.append([a, b])
	_layout["connections"] = conns
	_rebuild_lines()
	_set_status("Connections updated (%d)" % conns.size())

# ─────────────────────────────────────────────────────────────
# Add / Delete node
# ─────────────────────────────────────────────────────────────
func _add_node(node_id: String) -> void:
	node_id = node_id.strip_edges()
	if node_id.is_empty():
		_set_status("Node ID cannot be empty")
		return
	for nd: Dictionary in _layout.get("nodes", []):
		if nd.get("id", "") == node_id:
			_set_status("Node already exists: %s" % node_id)
			return
	var new_nd: Dictionary = {
		"id": node_id, "type": "normal", "label": node_id,
		"x": 400, "y": 400, "is_entry": false, "pack_reward": "",
		"ai_deck": {"characters": [], "traps": [], "tech": []}
	}
	_layout.get("nodes", []).append(new_nd)
	_positions[node_id] = Vector2(400, 400)
	_create_node_control(new_nd)
	_set_status("Added node: %s" % node_id)

func _delete_selected_node() -> void:
	if _selected_id.is_empty():
		_set_status("No node selected")
		return
	var nodes: Array = _layout.get("nodes", [])
	for i: int in range(nodes.size()):
		if nodes[i].get("id", "") == _selected_id:
			nodes.remove_at(i)
			break
	# Remove connections involving this node
	var conns: Array = _layout.get("connections", [])
	var kept: Array = []
	for c: Array in conns:
		if c[0] != _selected_id and c[1] != _selected_id:
			kept.append(c)
	_layout["connections"] = kept
	if _node_controls.has(_selected_id):
		_node_controls[_selected_id].queue_free()
		_node_controls.erase(_selected_id)
	_positions.erase(_selected_id)
	_set_status("Deleted: %s" % _selected_id)
	_selected_id  = ""
	_connect_from = ""
	_rebuild_lines()
	_update_conn_text()
	_update_prop_panel()

# ─────────────────────────────────────────────────────────────
# Dungeon picker
# ─────────────────────────────────────────────────────────────
func _copy_battle_data() -> void:
	if _selected_id.is_empty():
		_set_status("No node selected — nothing to copy")
		return
	# Collect AI deck from text fields
	var chars: Array = []
	for line: String in _prop_chars_edit.text.split("\n"):
		var s: String = line.strip_edges()
		if not s.is_empty(): chars.append(s)
	var traps: Array = []
	for line: String in _prop_traps_edit.text.split("\n"):
		var s: String = line.strip_edges()
		if not s.is_empty(): traps.append(s)
	var techs: Array = []
	for line: String in _prop_tech_edit.text.split("\n"):
		var s: String = line.strip_edges()
		if not s.is_empty(): techs.append(s)
	# Collect forced cells from grids
	var pfc: Array = _collect_forced_cells_from_grid_bld(_player_forced_grid)
	var afc: Array = _collect_forced_cells_from_grid_bld(_ai_forced_grid)
	_battle_clipboard = {
		"ai_deck": {"characters": chars, "traps": traps, "tech": techs},
		"ai_deck_vault": AIDeckVault.option_entry_id(_prop_vault_opt) if _prop_vault_opt != null else "",
		"ai_deck_vault_formation": AIDeckVault.option_formation_index(_prop_vault_form_opt) if _prop_vault_form_opt != null else 0,
		"battle_settings": {
			"player1_name":              _prop_p1_name.text.strip_edges(),
			"player2_name":              _prop_p2_name.text.strip_edges(),
			"portrait_p1":               _prop_portrait_p1.text.strip_edges(),
			"portrait_p1_offset_x":      _prop_p1_offset_x.value,
			"portrait_p1_offset_y":      _prop_p1_offset_y.value,
			"portrait_p1_size":          _prop_p1_size.value,
			"portrait_p2":               _prop_portrait_p2.text.strip_edges(),
			"portrait_p2_offset_x":      _prop_p2_offset_x.value,
			"portrait_p2_offset_y":      _prop_p2_offset_y.value,
			"portrait_p2_size":          _prop_p2_size.value,
			"battle_bgm":                _prop_battle_bgm.text.strip_edges(),
			"battle_bgm_volume":         _prop_bgm_vol.value,
			"ai_union_enabled":          _prop_ai_union_chk.button_pressed,
			"player_union_enabled":      _prop_plr_union_chk.button_pressed,
			"ai_personality_defensive":  _prop_ai_pers_def.get_item_text(_prop_ai_pers_def.selected) if _prop_ai_pers_def.selected > 0 else "",
			"ai_personality_offensive":  _prop_ai_pers_off.get_item_text(_prop_ai_pers_off.selected) if _prop_ai_pers_off.selected > 0 else "",
			"ai_personality_social":     _prop_ai_pers_soc.get_item_text(_prop_ai_pers_soc.selected) if _prop_ai_pers_soc.selected > 0 else "",
			"player_forced_cells":       pfc,
			"ai_forced_cells":           afc,
			"ai_forced_tech":            _collect_ai_forced_tech_bld(),
		}
	}
	_set_status("Battle data copied from: %s" % _selected_id)

func _paste_battle_data() -> void:
	if _selected_id.is_empty():
		_set_status("No node selected — nothing to paste into")
		return
	if _battle_clipboard.is_empty():
		_set_status("Clipboard is empty — copy from a node first")
		return
	# Restore AI deck
	var deck: Dictionary = _battle_clipboard.get("ai_deck", {})
	_prop_chars_edit.text = "\n".join(PackedStringArray(deck.get("characters", [])))
	_prop_traps_edit.text = "\n".join(PackedStringArray(deck.get("traps", [])))
	_prop_tech_edit.text  = "\n".join(PackedStringArray(deck.get("tech", [])))
	if _prop_vault_opt != null:
		AIDeckVault.select_vault_option(_prop_vault_opt, str(_battle_clipboard.get("ai_deck_vault", "")).strip_edges())
		_on_vault_selected(false)
		if _prop_vault_form_opt != null:
			AIDeckVault.select_formation_option(_prop_vault_form_opt, int(_battle_clipboard.get("ai_deck_vault_formation", 0)))
	# Restore battle settings
	var bs: Dictionary = _battle_clipboard.get("battle_settings", {})
	_prop_p1_name.text       = str(bs.get("player1_name", ""))
	_prop_p2_name.text       = str(bs.get("player2_name", ""))
	_prop_portrait_p1.text   = str(bs.get("portrait_p1", ""))
	_prop_p1_offset_x.value  = float(bs.get("portrait_p1_offset_x", 0.0))
	_prop_p1_offset_y.value  = float(bs.get("portrait_p1_offset_y", 0.0))
	_prop_p1_size.value      = float(bs.get("portrait_p1_size", 1.0))
	_prop_portrait_p2.text   = str(bs.get("portrait_p2", ""))
	_prop_p2_offset_x.value  = float(bs.get("portrait_p2_offset_x", 0.0))
	_prop_p2_offset_y.value  = float(bs.get("portrait_p2_offset_y", 0.0))
	_prop_p2_size.value      = float(bs.get("portrait_p2_size", 1.0))
	_prop_battle_bgm.text    = str(bs.get("battle_bgm", ""))
	_prop_bgm_vol.value      = float(bs.get("battle_bgm_volume", 100.0))
	_prop_ai_union_chk.button_pressed  = bool(bs.get("ai_union_enabled", true))
	_prop_plr_union_chk.button_pressed = bool(bs.get("player_union_enabled", true))
	_opt_select(_prop_ai_pers_def, str(bs.get("ai_personality_defensive", "")))
	_opt_select(_prop_ai_pers_off, str(bs.get("ai_personality_offensive", "")))
	_opt_select(_prop_ai_pers_soc, str(bs.get("ai_personality_social",    "")))
	# Restore forced cells into grids
	var raw_pfc: Variant = bs.get("player_forced_cells", [])
	var raw_afc: Variant = bs.get("ai_forced_cells", [])
	_rebuild_forced_grid_bld(_player_forced_grid, _player_forced_gc,
		raw_pfc if raw_pfc is Array else [])
	_rebuild_forced_grid_bld(_ai_forced_grid, _ai_forced_gc,
		raw_afc if raw_afc is Array else [])
	_load_ai_forced_tech_from_bs(bs, deck.get("tech", []))
	# Auto-apply so the node data is saved immediately
	_apply_node_changes()
	_set_status("Battle data pasted to: %s" % _selected_id)

func _populate_dungeon_picker() -> void:
	_dungeon_picker.clear()
	_filtered_ids.clear()
	var filter_mode: String = ""
	if _mode_filter_opt != null:
		match _mode_filter_opt.selected:
			1: filter_mode = "daily_dungeon"
			2: filter_mode = "story_mode"
	for did: String in _all_ids:
		if filter_mode != "":
			var layout_data: Variant = DailyDungeonManager.get_layout(did)
			var lm: String = (layout_data as Dictionary).get("mode", "daily_dungeon")
			if lm != filter_mode:
				continue
		_filtered_ids.append(did)
		_dungeon_picker.add_item(did)
	if not _filtered_ids.is_empty():
		_load_dungeon(_filtered_ids[0])

func _on_dungeon_selected(idx: int) -> void:
	if idx < 0 or idx >= _filtered_ids.size():
		return
	_load_dungeon(_filtered_ids[idx])

func _on_new_layout() -> void:
	# Prompt via a small popup
	var popup := AcceptDialog.new()
	popup.title = "New Dungeon Layout"
	popup.dialog_text = "Enter new dungeon ID (e.g. dungeon_forest):"
	var line := LineEdit.new()
	line.placeholder_text = "dungeon_id"
	popup.add_child(line)
	add_child(popup)
	popup.confirmed.connect(func() -> void:
		var did: String = line.text.strip_edges()
		if did.is_empty():
			return
		_layout = {
			"id": did, "name": did, "background": "",
			"nodes": [], "connections": []
		}
		_dungeon_id = did
		_positions.clear()
		_node_controls.clear()
		_selected_id  = ""
		_connect_from = ""
		_rebuild_canvas()
		_all_ids = DailyDungeonManager.get_all_layout_ids()
		if did not in _all_ids:
			_all_ids.append(did)
		_populate_dungeon_picker()
		_dungeon_picker.selected = _filtered_ids.find(did)
		_set_status("New layout: %s  (not yet saved)" % did)
		popup.queue_free())
	popup.popup_centered()

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _refresh_wheel_outcomes_ui() -> void:
	if _prop_wheel_outcomes_vbox == null:
		return
	for ch: Node in _prop_wheel_outcomes_vbox.get_children():
		ch.queue_free()
	for i: int in range(_wheel_outcomes_list.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var lbl := Label.new()
		lbl.text = _wheel_outcomes_list[i]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color",
			Color(0.5, 0.7, 0.5) if _wheel_outcomes_list[i] == "no_effect"
			else Color(0.85, 0.92, 1.0, 0.9))
		row.add_child(lbl)
		var rm_btn := Button.new()
		rm_btn.text = "✕"
		rm_btn.add_theme_font_override("font", FontManager.make_font("primary", 400))
		rm_btn.custom_minimum_size = Vector2(30, 0)
		rm_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
		var i_cap := i
		rm_btn.pressed.connect(func() -> void:
			_wheel_outcomes_list.remove_at(i_cap)
			_refresh_wheel_outcomes_ui())
		row.add_child(rm_btn)
		_prop_wheel_outcomes_vbox.add_child(row)

func _find_node(node_id: String) -> Dictionary:
	for nd: Dictionary in _layout.get("nodes", []):
		if nd.get("id", "") == node_id:
			return nd
	return {}

func _set_status(text: String) -> void:
	if _status_lbl:
		_status_lbl.text = text

# ─────────────────────────────────────────────────────────────
# File browser
# ─────────────────────────────────────────────────────────────
func _open_file_dialog(on_selected: Callable) -> void:
	var fd := FileDialog.new()
	fd.access    = FileDialog.ACCESS_RESOURCES
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters   = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Image Files"])
	fd.min_size  = Vector2i(820, 520)
	fd.title     = "Select Image"
	add_child(fd)
	fd.file_selected.connect(func(path: String) -> void:
		on_selected.call(path)
		fd.queue_free())
	fd.canceled.connect(fd.queue_free)
	fd.popup_centered_ratio(0.6)

func _open_file_dialog_audio(on_selected: Callable) -> void:
	var fd := FileDialog.new()
	fd.access    = FileDialog.ACCESS_RESOURCES
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters   = PackedStringArray(["*.mp3,*.ogg,*.wav ; Audio Files"])
	fd.min_size  = Vector2i(820, 520)
	fd.title     = "Select Audio"
	add_child(fd)
	fd.file_selected.connect(func(path: String) -> void:
		on_selected.call(path)
		fd.queue_free())
	fd.canceled.connect(fd.queue_free)
	fd.popup_centered_ratio(0.6)

# ─────────────────────────────────────────────────────────────
# Forced-cell visual grid helpers (5×5, same style as VNEditor)
# ─────────────────────────────────────────────────────────────
func _build_forced_grid_bld(grid_dict: Dictionary) -> GridContainer:
	var gc := GridContainer.new()
	gc.columns = 5
	gc.add_theme_constant_override("h_separation", 4)
	gc.add_theme_constant_override("v_separation", 4)
	for r: int in range(5):
		for c: int in range(5):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(60, 42)
			btn.clip_text = true
			btn.add_theme_font_size_override("font_size", 10)
			var r_cap := r
			var c_cap := c
			btn.pressed.connect(func() -> void:
				if _selected_id.is_empty():
					return
				_open_forced_cell_picker_bld(grid_dict, gc, r_cap, c_cap))
			gc.add_child(btn)
	_refresh_forced_grid_bld(grid_dict, gc)
	return gc

func _refresh_forced_grid_bld(grid_dict: Dictionary, gc: GridContainer) -> void:
	if gc == null:
		return
	var children: Array = gc.get_children()
	for r: int in range(5):
		for c: int in range(5):
			var btn: Button = children[r * 5 + c] as Button
			var key: String = str(r) + "," + str(c)
			if grid_dict.has(key):
				btn.text = grid_dict[key] as String
				btn.modulate = Color(0.55, 1.0, 0.55)
			else:
				btn.text = "%d,%d" % [r, c]
				btn.modulate = Color(1.0, 1.0, 1.0, 0.45)

func _open_forced_cell_picker_bld(grid_dict: Dictionary, gc: GridContainer, r: int, c: int) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 70
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "Cell [row %d, col %d]" % [r, c]
	title.add_theme_font_size_override("font_size", 15)
	vb.add_child(title)

	var key: String = str(r) + "," + str(c)
	var current: String = str(grid_dict.get(key, ""))

	var le := LineEdit.new()
	le.placeholder_text = "Character card name..."
	le.text = current
	le.add_theme_font_size_override("font_size", 14)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(le)

	var sug_scroll := ScrollContainer.new()
	sug_scroll.custom_minimum_size = Vector2(0, 120)
	sug_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(sug_scroll)
	var sug_vb := VBoxContainer.new()
	sug_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sug_scroll.add_child(sug_vb)

	var refresh_sug := func(query: String) -> void:
		for child: Node in sug_vb.get_children():
			child.queue_free()
		var q: String = query.strip_edges().to_lower()
		var names: Array = []
		for n: String in CardDatabase.characters:
			if q.is_empty() or n.to_lower().contains(q):
				names.append(n)
		names.sort()
		var shown: int = 0
		for n: String in names:
			if shown >= 25:
				break
			var sb := Button.new()
			sb.text = n
			sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			sb.add_theme_font_size_override("font_size", 12)
			sb.pressed.connect(func() -> void: le.text = n)
			sug_vb.add_child(sb)
			shown += 1

	le.text_changed.connect(refresh_sug)
	refresh_sug.call(current)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 6)
	vb.add_child(btn_hb)

	var set_btn := Button.new()
	set_btn.text = "Set"
	set_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(set_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(clear_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(cancel_btn)

	set_btn.pressed.connect(func() -> void:
		var cname: String = le.text.strip_edges()
		if not cname.is_empty():
			grid_dict[key] = cname
		else:
			grid_dict.erase(key)
		_refresh_forced_grid_bld(grid_dict, gc)
		overlay.queue_free())

	clear_btn.pressed.connect(func() -> void:
		grid_dict.erase(key)
		_refresh_forced_grid_bld(grid_dict, gc)
		overlay.queue_free())

	cancel_btn.pressed.connect(func() -> void:
		overlay.queue_free())

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if not panel.get_global_rect().has_point((event as InputEventMouseButton).global_position):
				overlay.queue_free())

	le.grab_focus()
	le.select_all()

func _collect_forced_cells_from_grid_bld(grid_dict: Dictionary) -> Array:
	var result: Array = []
	for key: String in grid_dict:
		var parts: PackedStringArray = key.split(",")
		if parts.size() == 2:
			result.append({
				"card_name": grid_dict[key],
				"row": int(parts[0]),
				"col": int(parts[1]),
			})
	return result

func _on_vault_selected(preview_grid: bool = true) -> void:
	if _prop_vault_opt == null or _prop_vault_form_opt == null:
		return
	var entry_id: String = AIDeckVault.option_entry_id(_prop_vault_opt)
	AIDeckVault.populate_formation_option(_prop_vault_form_opt, entry_id)
	if not preview_grid or entry_id.is_empty():
		return
	var cfg: Dictionary = AIDeckVault.build_ai_battle_config(
		entry_id, AIDeckVault.option_formation_index(_prop_vault_form_opt))
	if not bool(cfg.get("ok", false)):
		return
	_rebuild_forced_grid_bld(_ai_forced_grid, _ai_forced_gc, cfg.get("forced_cells", []))

func _rebuild_forced_grid_bld(grid_dict: Dictionary, gc: GridContainer, data: Array) -> void:
	grid_dict.clear()
	for fc: Variant in data:
		if fc is Dictionary:
			var r: int = int((fc as Dictionary).get("row", 0))
			var c: int = int((fc as Dictionary).get("col", 0))
			var cname: Variant = (fc as Dictionary).get("card_name", "")
			if cname is String and not (cname as String).is_empty():
				grid_dict[str(r) + "," + str(c)] = cname as String
	_refresh_forced_grid_bld(grid_dict, gc)

func _collect_ai_forced_tech_bld() -> Array:
	var result: Array = []
	for i: int in range(ENEMY_TECH_SLOTS):
		result.append(str(_ai_forced_tech[i] if i < _ai_forced_tech.size() else "").strip_edges())
	return result

func _load_ai_forced_tech_from_bs(bs: Dictionary, deck_tech: Array) -> void:
	for i: int in range(ENEMY_TECH_SLOTS):
		_ai_forced_tech[i] = ""
	var saved: Variant = bs.get("ai_forced_tech", [])
	var has_saved: bool = false
	if saved is Array:
		for i: int in range(mini(ENEMY_TECH_SLOTS, (saved as Array).size())):
			var n: String = str((saved as Array)[i]).strip_edges()
			_ai_forced_tech[i] = n
			if not n.is_empty():
				has_saved = true
	if not has_saved:
		for i: int in range(mini(ENEMY_TECH_SLOTS, deck_tech.size())):
			_ai_forced_tech[i] = str(deck_tech[i]).strip_edges()
	_refresh_ai_forced_tech_row_bld()

func _refresh_ai_forced_tech_row_bld() -> void:
	for i: int in range(_ai_forced_tech_btns.size()):
		var btn: Button = _ai_forced_tech_btns[i] as Button
		var n: String = str(_ai_forced_tech[i] if i < _ai_forced_tech.size() else "").strip_edges()
		if n.is_empty():
			btn.text = "Tech %d\n(random)" % (i + 1)
			btn.modulate = Color(1.0, 1.0, 1.0, 0.45)
		else:
			btn.text = n
			btn.modulate = Color(0.55, 0.85, 1.0)

func _open_ai_forced_tech_picker_bld(slot: int) -> void:
	var current: String = str(_ai_forced_tech[slot] if slot < _ai_forced_tech.size() else "")

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 70
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "AI Tech slot %d" % (slot + 1)
	title.add_theme_font_size_override("font_size", 15)
	vb.add_child(title)

	var le := LineEdit.new()
	le.placeholder_text = "Tech card name..."
	le.text = current
	le.add_theme_font_size_override("font_size", 14)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(le)

	var sug_scroll := ScrollContainer.new()
	sug_scroll.custom_minimum_size = Vector2(0, 160)
	sug_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(sug_scroll)
	var sug_vb := VBoxContainer.new()
	sug_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sug_scroll.add_child(sug_vb)

	var refresh_sug := func(query: String) -> void:
		for child: Node in sug_vb.get_children():
			child.queue_free()
		var q: String = query.strip_edges().to_lower()
		var names: Array = CardDatabase.get_all_tech_names()
		names.sort()
		var shown: int = 0
		for n: String in names:
			if SaveManager.demo_mode:
				var tc: TechCardData = CardDatabase.get_tech(n)
				if tc == null or not tc.include_in_demo:
					continue
			if not q.is_empty() and not n.to_lower().contains(q):
				continue
			if shown >= 30:
				break
			var sb := Button.new()
			sb.text = n
			sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			sb.add_theme_font_size_override("font_size", 12)
			sb.pressed.connect(func() -> void: le.text = n)
			sug_vb.add_child(sb)
			shown += 1

	le.text_changed.connect(refresh_sug)
	refresh_sug.call(current)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 6)
	vb.add_child(btn_hb)

	var set_btn := Button.new()
	set_btn.text = "Set"
	set_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(set_btn)
	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(clear_btn)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(cancel_btn)

	set_btn.pressed.connect(func() -> void:
		_ai_forced_tech[slot] = le.text.strip_edges()
		_refresh_ai_forced_tech_row_bld()
		overlay.queue_free())

	clear_btn.pressed.connect(func() -> void:
		_ai_forced_tech[slot] = ""
		_refresh_ai_forced_tech_row_bld()
		overlay.queue_free())

	cancel_btn.pressed.connect(func() -> void: overlay.queue_free())

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if not panel.get_global_rect().has_point(
					(event as InputEventMouseButton).global_position):
				overlay.queue_free())

	le.grab_focus()
	le.select_all()
