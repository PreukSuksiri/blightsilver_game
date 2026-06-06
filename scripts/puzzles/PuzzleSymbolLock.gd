extends ExplorationPuzzleBase
## Symbol Sequence Lock — tap symbols in the correct order.
##
## Params (JSON in spot key field):
##   sequence : Array — ordered symbols to tap, e.g. ["☽","★","◎"]  (required)
##   symbols  : Array — full pool of symbols shown as buttons (required, must contain all sequence items)
##
## Example: {"sequence":["☽","★","◎"],"symbols":["☽","★","◎","♛","✦","⚿"]}

const _SFX_BTN     := preload("res://assets/audio/sfx/scifi_ui_9.mp3")
const _SFX_CORRECT := preload("res://assets/audio/sfx/scifi_ui_30.mp3")
const _FONT_CHIVO  := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")

const _COLOR_BG        := Color(0.05, 0.08, 0.14, 0.97)
const _COLOR_BORDER    := Color(0.30, 0.70, 1.0, 0.80)
const _COLOR_BTN_TEXT  := Color(0.85, 0.95, 1.0)
const _COLOR_DOT_FILL  := Color(0.40, 0.85, 1.0)
const _COLOR_DOT_EMPTY := Color(0.25, 0.35, 0.50)

var _sequence: Array[String] = []
var _current: Array[String] = []
var _dot_labels: Array[Label] = []
var _dot_row: HBoxContainer = null
var _feedback_label: Label = null
var _locked: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var seq_raw: Variant = get_param("sequence", null)
	var sym_raw: Variant = get_param("symbols", null)

	if not seq_raw is Array or not sym_raw is Array:
		_build_error_ui()
		return

	var seq: Array = seq_raw as Array
	var sym_pool: Array = sym_raw as Array

	if seq.is_empty() or sym_pool.is_empty():
		_build_error_ui()
		return

	var sym_strs: Array[String] = []
	for s: Variant in sym_pool:
		sym_strs.append(str(s))

	_sequence = []
	for s: Variant in seq:
		var sv: String = str(s)
		if not sym_strs.has(sv):
			_build_error_ui()
			return
		_sequence.append(sv)

	_build_ui(sym_strs)


# ── Error UI ──────────────────────────────────────────────────────────────────

func _build_error_ui() -> void:
	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size
	add_child(center)

	var panel := _make_panel(Vector2(360.0, 180.0))
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
	hint.text = "Requires \"sequence\" and \"symbols\" arrays.\nAll sequence items must appear in symbols.\nExample: {\"sequence\":[\"☽\",\"★\"],\"symbols\":[\"☽\",\"★\",\"◎\",\"♛\"]}"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	vbox.add_child(hint)

	var close_btn := _make_button("Close")
	close_btn.pressed.connect(func() -> void: complete_puzzle(false))
	vbox.add_child(close_btn)


# ── Main UI ───────────────────────────────────────────────────────────────────

func _build_ui(sym_pool: Array[String]) -> void:
	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size
	add_child(center)

	var panel := _make_panel(Vector2(340.0, 0.0))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Bead slot — dot row and feedback label share this slot; one visible at a time
	var bead_slot := CenterContainer.new()
	bead_slot.custom_minimum_size = Vector2(0.0, 48.0)
	vbox.add_child(bead_slot)

	_dot_row = HBoxContainer.new()
	_dot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dot_row.add_theme_constant_override("separation", 10)
	bead_slot.add_child(_dot_row)

	for _i: int in range(_sequence.size()):
		var dot := Label.new()
		dot.text = "○"
		dot.add_theme_font_size_override("font_size", 28)
		dot.add_theme_color_override("font_color", _COLOR_DOT_EMPTY)
		_dot_row.add_child(dot)
		_dot_labels.append(dot)

	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_override("font", _FONT_CHIVO)
	_feedback_label.add_theme_font_size_override("font_size", 18)
	_feedback_label.add_theme_color_override("font_color", Color.WHITE)
	_feedback_label.visible = false
	bead_slot.add_child(_feedback_label)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", _COLOR_BORDER)
	vbox.add_child(sep)

	# Symbol grid — columns scale with pool size
	var cols: int = 4 if sym_pool.size() > 6 else (3 if sym_pool.size() > 4 else 2)
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	for sym: String in sym_pool:
		var btn := _make_sym_button(sym)
		var cap: String = sym
		btn.pressed.connect(func() -> void: _on_symbol_pressed(cap))
		grid.add_child(btn)

	var cancel := _make_button("Cancel")
	cancel.pressed.connect(func() -> void: complete_puzzle(false))
	vbox.add_child(cancel)


# ── Input logic ───────────────────────────────────────────────────────────────

func _on_symbol_pressed(sym: String) -> void:
	if _locked:
		return
	SFXManager.play(_SFX_BTN)

	var idx: int = _current.size()
	_current.append(sym)

	if idx < _dot_labels.size():
		_dot_labels[idx].text = "●"
		_dot_labels[idx].add_theme_color_override("font_color", _COLOR_DOT_FILL)

	if sym != _sequence[idx]:
		_locked = true
		_show_inline_feedback("Wrong sequence.")
		await get_tree().create_timer(1.5).timeout
		_hide_inline_feedback()
		_reset()
		_locked = false
		return

	if _current.size() == _sequence.size():
		_locked = true
		SFXManager.play(_SFX_CORRECT)
		_show_inline_feedback("Sequence correct!")
		await get_tree().create_timer(2.0).timeout
		_hide_inline_feedback()
		complete_puzzle(true)


func _reset() -> void:
	_current.clear()
	for dot: Label in _dot_labels:
		dot.text = "○"
		dot.add_theme_color_override("font_color", _COLOR_DOT_EMPTY)


func _show_inline_feedback(msg: String) -> void:
	if _dot_row != null:
		_dot_row.visible = false
	if _feedback_label != null:
		_feedback_label.text = msg
		_feedback_label.visible = true


func _hide_inline_feedback() -> void:
	if _feedback_label != null:
		_feedback_label.visible = false
	if _dot_row != null:
		_dot_row.visible = true


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


func _make_sym_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(72.0, 56.0)
	btn.add_theme_font_size_override("font_size", 26)
	btn.add_theme_color_override("font_color", _COLOR_BTN_TEXT)

	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = Color(0.10, 0.18, 0.32)
	normal_sb.set_border_width_all(1)
	normal_sb.border_color = _COLOR_BORDER
	normal_sb.set_corner_radius_all(6)

	var hover_sb := StyleBoxFlat.new()
	hover_sb.bg_color = Color(0.18, 0.32, 0.55)
	hover_sb.set_border_width_all(1)
	hover_sb.border_color = Color(0.55, 0.85, 1.0)
	hover_sb.set_corner_radius_all(6)

	var pressed_sb := StyleBoxFlat.new()
	pressed_sb.bg_color = Color(0.08, 0.14, 0.26)
	pressed_sb.set_border_width_all(1)
	pressed_sb.border_color = _COLOR_BORDER
	pressed_sb.set_corner_radius_all(6)

	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.add_theme_stylebox_override("focus", normal_sb)
	return btn


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
