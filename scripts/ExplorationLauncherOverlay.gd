extends Control
## ExplorationLauncherOverlay — admin overlay to browse and launch exploration graphs.
##
## Open via Admin Console:  exploration_play
## Scans res://exploration/graphs/ for all *.json files, reads their display_name,
## and presents a scrollable list. Click a row to launch it.

const _GRAPHS_DIR := "res://exploration/graphs/"
const _ACCENT      := Color(0.35, 0.70, 1.0)
const _BG          := Color(0.04, 0.06, 0.14, 0.97)
const _HEADER_BG   := Color(0.08, 0.11, 0.22, 1.0)
const _ROW_A       := Color(0.07, 0.10, 0.18, 1.0)
const _ROW_B       := Color(0.10, 0.14, 0.24, 1.0)
const _ROW_HOVER   := Color(0.14, 0.22, 0.40, 1.0)
const _BTN_LAUNCH  := Color(0.12, 0.42, 0.22, 1.0)
const _BTN_EDITOR  := Color(0.18, 0.28, 0.55, 1.0)
const _BTN_CLOSE   := Color(0.45, 0.10, 0.10, 1.0)

# Each entry: { "path": String, "graph_id": String, "display_name": String, "node_count": int }
var _entries: Array = []
var _selected_idx: int = -1

var _status_lbl: Label = null
var _list_vbox: VBoxContainer = null
var _launch_btn: Button = null
var _editor_btn: Button = null

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 95

	var bg := ColorRect.new()
	bg.color = _BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_panel()
	_scan_graphs()
	_rebuild_list()

# ─────────────────────────────────────────────────────────────
# Layout
# ─────────────────────────────────────────────────────────────
func _build_panel() -> void:
	# Centred card
	var card := PanelContainer.new()
	card.layout_mode   = 1
	card.anchor_left   = 0.5;  card.anchor_right  = 0.5
	card.anchor_top    = 0.5;  card.anchor_bottom = 0.5
	card.offset_left   = -420.0; card.offset_right  = 420.0
	card.offset_top    = -320.0; card.offset_bottom = 320.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = _BG
	sb.set_border_width_all(2)
	sb.border_color = _ACCENT
	sb.set_corner_radius_all(8)
	sb.content_margin_left   = 0.0
	sb.content_margin_right  = 0.0
	sb.content_margin_top    = 0.0
	sb.content_margin_bottom = 0.0
	card.add_theme_stylebox_override("panel", sb)
	add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	card.add_child(vbox)

	# ── Header ────────────────────────────────────────────────
	var header := PanelContainer.new()
	var sb_hdr := StyleBoxFlat.new()
	sb_hdr.bg_color = _HEADER_BG
	sb_hdr.content_margin_left = 20.0; sb_hdr.content_margin_right  = 12.0
	sb_hdr.content_margin_top  = 12.0; sb_hdr.content_margin_bottom = 12.0
	header.add_theme_stylebox_override("panel", sb_hdr)
	vbox.add_child(header)

	var hdr_row := HBoxContainer.new()
	hdr_row.add_theme_constant_override("separation", 10)
	header.add_child(hdr_row)

	var title_lbl := Label.new()
	title_lbl.text = "Exploration Regions"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", _ACCENT)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_row.add_child(title_lbl)

	_status_lbl = Label.new()
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hdr_row.add_child(_status_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 18)
	_style_btn(close_btn, _BTN_CLOSE)
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(queue_free)
	hdr_row.add_child(close_btn)

	# ── Dir hint ─────────────────────────────────────────────
	var dir_lbl := Label.new()
	dir_lbl.text = "  Scanning: " + _GRAPHS_DIR
	dir_lbl.add_theme_font_size_override("font_size", 12)
	dir_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
	dir_lbl.add_theme_constant_override("margin_left", 20)
	var dir_margin := MarginContainer.new()
	dir_margin.add_theme_constant_override("margin_left",  20)
	dir_margin.add_theme_constant_override("margin_top",    6)
	dir_margin.add_theme_constant_override("margin_bottom", 6)
	dir_margin.add_child(dir_lbl)
	vbox.add_child(dir_margin)

	# ── Scrollable list ───────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 340)
	vbox.add_child(scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 0)
	scroll.add_child(_list_vbox)

	# ── Bottom bar ────────────────────────────────────────────
	var sep := HSeparator.new()
	var sb_sep := StyleBoxFlat.new()
	sb_sep.bg_color = Color(_ACCENT, 0.30)
	sb_sep.content_margin_top = 1.0; sb_sep.content_margin_bottom = 1.0
	sep.add_theme_stylebox_override("separator", sb_sep)
	vbox.add_child(sep)

	var bot := HBoxContainer.new()
	bot.add_theme_constant_override("separation", 10)
	var bot_margin := MarginContainer.new()
	bot_margin.add_theme_constant_override("margin_left",   16)
	bot_margin.add_theme_constant_override("margin_right",  16)
	bot_margin.add_theme_constant_override("margin_top",    12)
	bot_margin.add_theme_constant_override("margin_bottom", 12)
	bot_margin.add_child(bot)
	vbox.add_child(bot_margin)

	# Refresh button
	var refresh_btn := Button.new()
	refresh_btn.text = "⟳  Refresh"
	refresh_btn.add_theme_font_size_override("font_size", 16)
	_style_btn(refresh_btn, Color(0.22, 0.22, 0.32, 1.0))
	refresh_btn.pressed.connect(_on_refresh_pressed)
	bot.add_child(refresh_btn)

	# Open Editor button
	_editor_btn = Button.new()
	_editor_btn.text = "✎  Open Editor"
	_editor_btn.add_theme_font_size_override("font_size", 16)
	_style_btn(_editor_btn, _BTN_EDITOR)
	_editor_btn.pressed.connect(_on_editor_pressed)
	bot.add_child(_editor_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot.add_child(spacer)

	# Launch button
	_launch_btn = Button.new()
	_launch_btn.text = "▶   Launch Region"
	_launch_btn.add_theme_font_size_override("font_size", 18)
	_launch_btn.disabled = true
	_style_btn(_launch_btn, _BTN_LAUNCH)
	_launch_btn.custom_minimum_size = Vector2(200, 44)
	_launch_btn.pressed.connect(_on_launch_pressed)
	bot.add_child(_launch_btn)

# ─────────────────────────────────────────────────────────────
# Graph scanning
# ─────────────────────────────────────────────────────────────
func _scan_graphs() -> void:
	_entries.clear()
	var dir := DirAccess.open(ProjectSettings.globalize_path(_GRAPHS_DIR))
	if dir == null:
		_set_status("Directory not found.")
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			var full_path: String = _GRAPHS_DIR + fname
			var entry: Dictionary = _read_graph_meta(full_path)
			_entries.append(entry)
		fname = dir.get_next()
	dir.list_dir_end()
	# Sort by display_name
	_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["display_name"] as String).to_lower() < (b["display_name"] as String).to_lower())
	_set_status("%d region%s found" % [_entries.size(), "s" if _entries.size() != 1 else ""])

func _read_graph_meta(path: String) -> Dictionary:
	var result: Dictionary = {
		"path": path,
		"graph_id": "",
		"display_name": path.get_file().get_basename(),
		"node_count": 0,
	}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result
	var raw := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		return result
	var d: Dictionary = parsed as Dictionary
	var gid: String   = str(d.get("graph_id",     ""))
	var dn: String    = str(d.get("display_name",  ""))
	var nodes: Variant = d.get("nodes", [])
	result["graph_id"]     = gid
	result["display_name"] = dn if not dn.is_empty() else path.get_file().get_basename()
	result["node_count"]   = (nodes as Array).size() if nodes is Array else 0
	return result

# ─────────────────────────────────────────────────────────────
# List rendering
# ─────────────────────────────────────────────────────────────
func _rebuild_list() -> void:
	for child: Node in _list_vbox.get_children():
		child.queue_free()

	if _entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No exploration graphs found in\n" + _GRAPHS_DIR
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 16)
		empty_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_top", 40)
		m.add_child(empty_lbl)
		_list_vbox.add_child(m)
		_selected_idx = -1
		_refresh_launch_btn()
		return

	for i: int in range(_entries.size()):
		var entry: Dictionary = _entries[i]
		_list_vbox.add_child(_make_row(i, entry))

	# Re-select previously selected index if still valid
	if _selected_idx >= _entries.size():
		_selected_idx = -1
	_refresh_launch_btn()

func _make_row(idx: int, entry: Dictionary) -> Control:
	var row_btn := Button.new()
	row_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row_btn.add_theme_font_size_override("font_size", 18)
	row_btn.focus_mode = FOCUS_NONE

	# Style — normal and hover
	var bg_col: Color = _ROW_A if idx % 2 == 0 else _ROW_B
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = bg_col
	sb_normal.content_margin_left   = 20.0
	sb_normal.content_margin_right  = 16.0
	sb_normal.content_margin_top    = 14.0
	sb_normal.content_margin_bottom = 14.0
	row_btn.add_theme_stylebox_override("normal", sb_normal)

	var sb_hover := sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = _ROW_HOVER
	row_btn.add_theme_stylebox_override("hover", sb_hover)

	var sb_pressed := sb_normal.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = Color(_ACCENT, 0.22)
	sb_pressed.set_border_width_all(0)
	sb_pressed.border_color = _ACCENT
	row_btn.add_theme_stylebox_override("pressed", sb_pressed)

	# Selected highlight
	if idx == _selected_idx:
		var sb_sel := sb_normal.duplicate() as StyleBoxFlat
		sb_sel.bg_color = Color(_ACCENT, 0.20)
		sb_sel.border_width_left = 3
		sb_sel.border_color = _ACCENT
		row_btn.add_theme_stylebox_override("normal", sb_sel)
		row_btn.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	else:
		row_btn.add_theme_color_override("font_color", Color(0.78, 0.86, 0.95))

	# Row content: name (left) + node count + id (right)
	var display: String = entry["display_name"] as String
	var nc: int         = entry["node_count"] as int
	var gid: String     = entry["graph_id"] as String
	var path_file: String = (entry["path"] as String).get_file()
	row_btn.text = display

	# Right-side info via a child HBox trick is not easy on Button,
	# so we add meta as a suffix in a muted colour via RichTextLabel inside the button
	# — instead, just include the info in the button text with spacing
	row_btn.text = "%-38s" % display + \
		"  %d node%s" % [nc, "s" if nc != 1 else ""] + \
		"   [%s]" % (gid if not gid.is_empty() else path_file)

	var captured_idx: int = idx
	row_btn.pressed.connect(func() -> void: _on_row_selected(captured_idx))
	# Double-click to launch
	row_btn.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb: InputEventMouseButton = ev as InputEventMouseButton
			if mb.double_click and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_on_row_selected(captured_idx)
				_on_launch_pressed())

	return row_btn

# ─────────────────────────────────────────────────────────────
# Interaction
# ─────────────────────────────────────────────────────────────
func _on_row_selected(idx: int) -> void:
	_selected_idx = idx
	_rebuild_list()
	_refresh_launch_btn()

func _refresh_launch_btn() -> void:
	if _launch_btn == null:
		return
	_launch_btn.disabled = (_selected_idx < 0 or _selected_idx >= _entries.size())

func _on_refresh_pressed() -> void:
	_selected_idx = -1
	_scan_graphs()
	_rebuild_list()

func _on_editor_pressed() -> void:
	queue_free()
	get_tree().change_scene_to_file("res://scenes/exploration_editor.tscn")

func _on_launch_pressed() -> void:
	if _selected_idx < 0 or _selected_idx >= _entries.size():
		return
	var path: String = _entries[_selected_idx]["path"] as String
	var return_scene: String = get_tree().current_scene.scene_file_path
	if return_scene.is_empty():
		return_scene = "res://scenes/main_menu.tscn"
	queue_free()
	ExplorationManager.launch(path, return_scene)

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _set_status(text: String) -> void:
	if _status_lbl != null:
		_status_lbl.text = text

func _style_btn(btn: Button, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(5)
	sb.content_margin_left   = 14.0; sb.content_margin_right  = 14.0
	sb.content_margin_top    = 8.0;  sb.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = col.lightened(0.15)
	btn.add_theme_stylebox_override("hover", sb_h)
	var sb_p := sb.duplicate() as StyleBoxFlat
	sb_p.bg_color = col.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", sb_p)
	btn.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
