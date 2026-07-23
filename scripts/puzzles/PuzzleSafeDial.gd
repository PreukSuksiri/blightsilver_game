extends ExplorationPuzzleBase
## Safe Combination Dial — rotate each dial to the correct value and press Confirm.
##
## Params (JSON in spot key field):
##   combination : Array[int] — target value for each dial, e.g. [3,7,2]  (required)
##   max         : int        — max value per dial, wraps (default 9)
##   labeled     : bool       — show A/B/C labels above dials (default true)
##
## Example: {"combination":[3,7,2],"max":9,"labeled":true}

const _SFX_BTN     := preload("res://assets/audio/sfx/scifi_ui_9.mp3")
const _SFX_CORRECT := preload("res://assets/audio/sfx/scifi_ui_30.mp3")

const _COLOR_BG        := Color(0.05, 0.08, 0.14, 0.97)
const _COLOR_BORDER    := Color(0.30, 0.70, 1.0, 0.80)
const _COLOR_BTN_TEXT  := Color(0.85, 0.95, 1.0)
const _DIAL_LABELS     := ["A", "B", "C", "D", "E", "F", "G", "H"]

var _combination: Array[int] = []
var _values: Array[int] = []
var _max_val: int = 9
var _value_labels: Array[Label] = []
var _status_lbl: Label = null
var _locked: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var combo_raw: Variant = get_param("combination", null)
	if not combo_raw is Array or (combo_raw as Array).is_empty():
		_build_error_ui()
		return

	for v: Variant in (combo_raw as Array):
		if not (str(v).is_valid_int()):
			_build_error_ui()
			return
		_combination.append(int(str(v)))

	_max_val = int(str(get_param("max", 9)))
	if _max_val < 1:
		_max_val = 9

	for _i: int in range(_combination.size()):
		_values.append(0)

	var labeled: bool = bool(get_param("labeled", true))
	_build_ui(labeled)


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
	hint.text = "Requires \"combination\" as an array of integers.\nExample: {\"combination\":[3,7,2],\"max\":9}"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	vbox.add_child(hint)

	var close_btn := _make_button("Close")
	close_btn.pressed.connect(func() -> void: complete_puzzle(false))
	vbox.add_child(close_btn)


# ── Main UI ───────────────────────────────────────────────────────────────────

func _build_ui(labeled: bool) -> void:
	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size
	add_child(center)

	var panel_w: float = maxf(320.0, float(_combination.size()) * 100.0 + 48.0)
	var panel := _make_panel(Vector2(panel_w, 0.0))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	# Status / feedback label at top
	_status_lbl = Label.new()
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.tag_primary(_status_lbl)
	_status_lbl.add_theme_font_size_override("font_size", 17)
	_status_lbl.add_theme_color_override("font_color", Color.WHITE)
	_status_lbl.custom_minimum_size = Vector2(0.0, 28.0)
	vbox.add_child(_status_lbl)

	var sep_top := HSeparator.new()
	sep_top.add_theme_color_override("color", _COLOR_BORDER)
	vbox.add_child(sep_top)

	# Dials row
	var dials_row := HBoxContainer.new()
	dials_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dials_row.add_theme_constant_override("separation", 12)
	vbox.add_child(dials_row)

	for i: int in range(_combination.size()):
		var dial_vbox := VBoxContainer.new()
		dial_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		dial_vbox.add_theme_constant_override("separation", 6)
		dials_row.add_child(dial_vbox)

		if labeled:
			var lbl := Label.new()
			lbl.text = _DIAL_LABELS[i % _DIAL_LABELS.size()]
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
			dial_vbox.add_child(lbl)

		# Up arrow
		var up_btn := _make_arrow_button("▲")
		var idx_up := i
		up_btn.pressed.connect(func() -> void: _change_dial(idx_up, 1))
		dial_vbox.add_child(up_btn)

		# Value display
		var val_lbl := Label.new()
		val_lbl.text = "0"
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_lbl.custom_minimum_size = Vector2(72.0, 52.0)
		FontManager.tag_primary(val_lbl)
		val_lbl.add_theme_font_size_override("font_size", 32)
		val_lbl.add_theme_color_override("font_color", _COLOR_BTN_TEXT)
		val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# Value background
		val_lbl.add_theme_stylebox_override("normal", _make_dial_bg())
		dial_vbox.add_child(val_lbl)
		_value_labels.append(val_lbl)

		# Down arrow
		var down_btn := _make_arrow_button("▼")
		var idx_down := i
		down_btn.pressed.connect(func() -> void: _change_dial(idx_down, -1))
		dial_vbox.add_child(down_btn)

	var sep_bot := HSeparator.new()
	sep_bot.add_theme_color_override("color", _COLOR_BORDER)
	vbox.add_child(sep_bot)

	# Confirm + Cancel row
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

func _change_dial(index: int, delta: int) -> void:
	if _locked:
		return
	SFXManager.play(_SFX_BTN)
	_values[index] = (_values[index] + delta + _max_val + 1) % (_max_val + 1)
	_value_labels[index].text = str(_values[index])


func _on_confirm() -> void:
	if _locked:
		return
	var correct: bool = true
	for i: int in range(_combination.size()):
		if _values[i] != _combination[i]:
			correct = false
			break

	_locked = true
	if correct:
		SFXManager.play(_SFX_CORRECT)
		_set_status("Combination correct!", Color(0.45, 1.0, 0.60))
		await get_tree().create_timer(2.0).timeout
		complete_puzzle(true)
	else:
		_set_status("Wrong combination.", Color(1.0, 0.45, 0.45))
		await get_tree().create_timer(1.5).timeout
		_set_status("", Color.WHITE)
		_locked = false


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


func _make_dial_bg() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.14, 0.26)
	sb.set_border_width_all(1)
	sb.border_color = _COLOR_BORDER
	sb.set_corner_radius_all(6)
	return sb


func _make_arrow_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(52.0, 36.0)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.55, 0.80, 1.0))

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.18, 0.32)
	sb.set_border_width_all(1)
	sb.border_color = _COLOR_BORDER
	sb.set_corner_radius_all(5)

	var hover_sb := StyleBoxFlat.new()
	hover_sb.bg_color = Color(0.18, 0.32, 0.55)
	hover_sb.set_border_width_all(1)
	hover_sb.border_color = Color(0.55, 0.85, 1.0)
	hover_sb.set_corner_radius_all(5)

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)
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
