extends ExplorationPuzzleBase
## Wire Connect — tap a source, then tap a target to connect them. Press Confirm when done.
##
## Params (JSON in spot key field):
##   pairs           : Array — [[source_label, target_label], ...] (required)
##   shuffle_targets : bool  — randomise target column order (default true)
##
## Example: {"pairs":[["Red","1"],["Blue","2"],["Green","3"]],"shuffle_targets":true}

const _SFX_BTN     := preload("res://assets/audio/sfx/scifi_ui_9.mp3")
const _SFX_CORRECT := preload("res://assets/audio/sfx/scifi_ui_30.mp3")
const _FONT_CHIVO  := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")

const _COLOR_BG      := Color(0.05, 0.08, 0.14, 0.97)
const _COLOR_BORDER  := Color(0.30, 0.70, 1.0, 0.80)
const _BTN_W: float  = 110.0
const _BTN_H: float  = 40.0
const _H_GAP: float  = 60.0   # horizontal gap between columns
const _ROW_H: float  = 54.0   # height per wire row (button + vertical gap)

# Correct mapping: src_label -> tgt_label
var _correct: Dictionary = {}
# Current player mapping: src_label -> tgt_label (or "" if unconnected)
var _connections: Dictionary = {}
# Displayed target column order: tgt_label -> row_index
var _tgt_rows: Dictionary = {}
# Source label -> row_index
var _src_rows: Dictionary = {}
# Buttons
var _src_btns: Dictionary = {}
var _tgt_btns: Dictionary = {}
# Wire line nodes (ColorRect): src_label -> ColorRect
var _wire_lines: Dictionary = {}

var _selected_src: String = ""
var _wire_area: Control = null
var _status_lbl: Label = null
var _locked: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var pairs_raw: Variant = get_param("pairs", null)
	if not pairs_raw is Array or (pairs_raw as Array).is_empty():
		_build_error_ui()
		return

	for p: Variant in (pairs_raw as Array):
		if not p is Array or (p as Array).size() < 2:
			_build_error_ui()
			return

	var src_list: Array[String] = []
	var tgt_list: Array[String] = []

	for p: Variant in (pairs_raw as Array):
		var pair: Array = p as Array
		var src: String = str(pair[0])
		var tgt: String = str(pair[1])
		src_list.append(src)
		tgt_list.append(tgt)
		_correct[src] = tgt
		_connections[src] = ""

	var shuffle: bool = bool(get_param("shuffle_targets", true))
	if shuffle:
		tgt_list.shuffle()

	for i: int in range(src_list.size()):
		_src_rows[src_list[i]] = i
	for i: int in range(tgt_list.size()):
		_tgt_rows[tgt_list[i]] = i

	_build_ui(src_list, tgt_list)


# ── Error UI ──────────────────────────────────────────────────────────────────

func _build_error_ui() -> void:
	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size
	add_child(center)

	var panel := _make_panel(Vector2(380.0, 180.0))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var err_lbl := Label.new()
	err_lbl.text = "invalid parameter"
	err_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	err_lbl.add_theme_font_size_override("font_size", 22)
	err_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	vbox.add_child(err_lbl)

	var hint := Label.new()
	hint.text = "Requires \"pairs\" as array of [source, target] pairs.\nExample: {\"pairs\":[[\"Red\",\"1\"],[\"Blue\",\"2\"]]}"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	vbox.add_child(hint)

	var close_btn := _make_button("Close")
	close_btn.pressed.connect(func() -> void: complete_puzzle(false))
	vbox.add_child(close_btn)


# ── Main UI ───────────────────────────────────────────────────────────────────

func _build_ui(src_list: Array[String], tgt_list: Array[String]) -> void:
	var n: int = src_list.size()
	var area_w: float = _BTN_W * 2.0 + _H_GAP
	var area_h: float = float(n) * _ROW_H

	var panel_w: float = area_w + 48.0
	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size
	add_child(center)

	var panel := _make_panel(Vector2(panel_w, 0.0))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	_status_lbl = Label.new()
	_status_lbl.text = "Connect all wires"
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_override("font", _FONT_CHIVO)
	_status_lbl.add_theme_font_size_override("font_size", 17)
	_status_lbl.add_theme_color_override("font_color", Color(0.65, 0.80, 1.0))
	vbox.add_child(_status_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", _COLOR_BORDER)
	vbox.add_child(sep)

	# Wire area — plain Control with manually positioned buttons and ColorRect lines
	_wire_area = Control.new()
	_wire_area.custom_minimum_size = Vector2(area_w, area_h)
	_wire_area.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(_wire_area)

	# Source buttons (left column)
	for i: int in range(n):
		var lbl: String = src_list[i]
		var btn := _make_wire_button(lbl)
		btn.position = Vector2(0.0, float(i) * _ROW_H)
		btn.size = Vector2(_BTN_W, _BTN_H)
		var cap: String = lbl
		btn.pressed.connect(func() -> void: _on_src_pressed(cap))
		_wire_area.add_child(btn)
		_src_btns[lbl] = btn

	# Target buttons (right column)
	for i: int in range(tgt_list.size()):
		var lbl: String = tgt_list[i]
		var btn := _make_wire_button(lbl)
		btn.position = Vector2(_BTN_W + _H_GAP, float(i) * _ROW_H)
		btn.size = Vector2(_BTN_W, _BTN_H)
		var cap: String = lbl
		btn.pressed.connect(func() -> void: _on_tgt_pressed(cap))
		_wire_area.add_child(btn)
		_tgt_btns[lbl] = btn

	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("color", _COLOR_BORDER)
	vbox.add_child(sep2)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var confirm_btn := _make_button("Confirm")
	confirm_btn.custom_minimum_size = Vector2(120.0, 0.0)
	confirm_btn.pressed.connect(_on_confirm)
	btn_row.add_child(confirm_btn)

	var cancel_btn := _make_button("Cancel")
	cancel_btn.custom_minimum_size = Vector2(120.0, 0.0)
	cancel_btn.pressed.connect(func() -> void: complete_puzzle(false))
	btn_row.add_child(cancel_btn)


# ── Input logic ───────────────────────────────────────────────────────────────

func _on_src_pressed(src: String) -> void:
	if _locked:
		return
	SFXManager.play(_SFX_BTN)

	if _selected_src == src:
		# Deselect
		_selected_src = ""
		_set_src_selected(src, false)
		return

	if _selected_src != "":
		_set_src_selected(_selected_src, false)

	_selected_src = src
	_set_src_selected(src, true)


func _on_tgt_pressed(tgt: String) -> void:
	if _locked or _selected_src.is_empty():
		return
	SFXManager.play(_SFX_BTN)

	var src: String = _selected_src
	_selected_src = ""
	_set_src_selected(src, false)

	# If target already connected to another source, disconnect that source first
	for other_src: String in _connections:
		if _connections[other_src] == tgt and other_src != src:
			_connections[other_src] = ""
			_remove_wire(other_src)
			break

	# Disconnect source's previous wire if any
	if _connections[src] != "":
		_remove_wire(src)

	_connections[src] = tgt
	_draw_wire(src, tgt)


func _on_confirm() -> void:
	if _locked:
		return

	# Check all connections are correct
	var all_correct: bool = true
	for src: String in _correct:
		if _connections.get(src, "") != _correct[src]:
			all_correct = false
			break

	_locked = true
	if all_correct:
		SFXManager.play(_SFX_CORRECT)
		_set_status("All wires connected!", Color(0.45, 1.0, 0.60))
		await get_tree().create_timer(2.0).timeout
		complete_puzzle(true)
	else:
		_set_status("Incorrect connection.", Color(1.0, 0.45, 0.45))
		await get_tree().create_timer(1.5).timeout
		_set_status("Connect all wires", Color(0.65, 0.80, 1.0))
		_locked = false


func _draw_wire(src: String, tgt: String) -> void:
	var src_row: int = _src_rows[src]
	var tgt_row: int = _tgt_rows[tgt]

	var p1 := Vector2(_BTN_W, float(src_row) * _ROW_H + _BTN_H * 0.5)
	var p2 := Vector2(_BTN_W + _H_GAP, float(tgt_row) * _ROW_H + _BTN_H * 0.5)

	var dx: float = p2.x - p1.x
	var dy: float = p2.y - p1.y
	var length: float = sqrt(dx * dx + dy * dy)
	var angle: float = atan2(dy, dx)

	var line := ColorRect.new()
	line.color = Color(0.40, 0.80, 1.0, 0.85)
	line.size = Vector2(length, 2.0)
	line.position = Vector2(p1.x, p1.y - 1.0)
	line.pivot_offset = Vector2(0.0, 1.0)
	line.rotation = angle
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.z_index = -1
	_wire_area.add_child(line)
	_wire_lines[src] = line


func _remove_wire(src: String) -> void:
	if _wire_lines.has(src):
		_wire_lines[src].queue_free()
		_wire_lines.erase(src)


func _set_src_selected(src: String, selected: bool) -> void:
	var btn: Button = _src_btns[src]
	if selected:
		btn.add_theme_stylebox_override("normal", _make_wire_btn_selected_sb())
		btn.add_theme_stylebox_override("hover", _make_wire_btn_selected_sb())
	else:
		btn.add_theme_stylebox_override("normal", _make_wire_btn_normal_sb())
		btn.add_theme_stylebox_override("hover", _make_wire_btn_hover_sb())


func _set_status(msg: String, color: Color = Color.WHITE) -> void:
	if _status_lbl != null:
		_status_lbl.text = msg
		_status_lbl.add_theme_color_override("font_color", color)


# ── UI helpers ────────────────────────────────────────────────────────────────

func _make_panel(min_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	var sb := StyleBoxFlat.new()
	sb.bg_color = _COLOR_BG
	sb.set_border_width_all(2)
	sb.border_color = _COLOR_BORDER
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 20.0
	sb.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", sb)
	return panel


func _make_wire_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	btn.add_theme_stylebox_override("normal", _make_wire_btn_normal_sb())
	btn.add_theme_stylebox_override("hover", _make_wire_btn_hover_sb())
	btn.add_theme_stylebox_override("pressed", _make_wire_btn_normal_sb())
	btn.add_theme_stylebox_override("focus", _make_wire_btn_normal_sb())
	return btn


func _make_wire_btn_normal_sb() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.18, 0.32)
	sb.set_border_width_all(1)
	sb.border_color = _COLOR_BORDER
	sb.set_corner_radius_all(6)
	return sb


func _make_wire_btn_hover_sb() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.28, 0.50)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.55, 0.85, 1.0)
	sb.set_corner_radius_all(6)
	return sb


func _make_wire_btn_selected_sb() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.38, 0.60)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.60, 1.0, 1.0)
	sb.set_corner_radius_all(6)
	return sb


func _make_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.15, 0.26)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.25, 0.40, 0.60)
	sb.set_corner_radius_all(6)
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0

	var hover_sb := StyleBoxFlat.new()
	hover_sb.bg_color = Color(0.15, 0.22, 0.38)
	hover_sb.set_border_width_all(1)
	hover_sb.border_color = Color(0.40, 0.60, 0.90)
	hover_sb.set_corner_radius_all(6)
	hover_sb.content_margin_top = 8.0
	hover_sb.content_margin_bottom = 8.0

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)
	return btn
