extends ExplorationPuzzleBase
## Number lock puzzle — tap the correct digit sequence on the numpad to solve.
##
## Params (JSON in spot key field):
##   code   : string — the correct digit sequence, e.g. "1492" (required, digits only)
##   digits : int    — expected input length (optional; defaults to code length)
##
## Example spot key: {"code":"1234","digits":4}
## If params are missing or invalid, an error screen is shown instead of the numpad.

const _SFX_BTN     := preload("res://assets/audio/sfx/scifi_ui_9.mp3")
const _SFX_CORRECT := preload("res://assets/audio/sfx/scifi_ui_30.mp3")

const _COLOR_BG        := Color(0.05, 0.08, 0.14, 0.97)
const _COLOR_BORDER    := Color(0.30, 0.70, 1.0, 0.80)
const _COLOR_BTN_TEXT  := Color(0.85, 0.95, 1.0)
const _COLOR_DEL_TEXT  := Color(1.0, 0.55, 0.55)
const _COLOR_DOT_FILL  := Color(0.40, 0.85, 1.0)
const _COLOR_DOT_EMPTY := Color(0.25, 0.35, 0.50)

var _correct_code: String = ""
var _digit_count: int = 0
var _current_input: String = ""
var _dot_labels: Array[Label] = []
var _dot_row: HBoxContainer = null
var _feedback_label: Label = null
var _locked: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var code_raw: Variant = get_param("code", null)
	var digits_raw: Variant = get_param("digits", null)

	var code_str: String = ""
	if code_raw != null:
		code_str = str(code_raw).strip_edges()

	var code_valid: bool = _is_digit_string(code_str)

	if not code_valid:
		_build_error_ui()
		return

	_correct_code = code_str

	if digits_raw != null:
		var d: int = int(str(digits_raw))
		_digit_count = d if d > 0 else code_str.length()
	else:
		_digit_count = code_str.length()

	_build_numpad_ui()


static func _is_digit_string(s: String) -> bool:
	if s.is_empty():
		return false
	for ch: String in s:
		if ch < "0" or ch > "9":
			return false
	return true


# ── Error UI ──────────────────────────────────────────────────────────────────

func _build_error_ui() -> void:
	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size
	add_child(center)

	var panel := _make_panel(Vector2(360.0, 180.0))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var err_label := Label.new()
	err_label.text = "invalid parameter"
	err_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	err_label.add_theme_font_size_override("font_size", 22)
	err_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	vbox.add_child(err_label)

	var sub := Label.new()
	sub.text = "Spot key must include a valid \"code\" (digits only).\nExample: {\"code\":\"1234\"}"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	vbox.add_child(sub)

	var close_btn := _make_button("Close")
	close_btn.pressed.connect(func() -> void: complete_puzzle(false))
	vbox.add_child(close_btn)


# ── Numpad UI ─────────────────────────────────────────────────────────────────

func _build_numpad_ui() -> void:
	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size
	add_child(center)

	var panel := _make_panel(Vector2(340.0, 0.0))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Bead slot — CenterContainer holds both the dot row and the feedback label.
	# Only one is visible at a time; CenterContainer centres whichever is shown.
	var bead_slot := CenterContainer.new()
	bead_slot.custom_minimum_size = Vector2(0.0, 48.0)
	vbox.add_child(bead_slot)

	_dot_row = HBoxContainer.new()
	_dot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dot_row.add_theme_constant_override("separation", 10)
	bead_slot.add_child(_dot_row)

	for _i: int in range(_digit_count):
		var dot := Label.new()
		dot.text = "○"
		dot.add_theme_font_size_override("font_size", 28)
		dot.add_theme_color_override("font_color", _COLOR_DOT_EMPTY)
		_dot_row.add_child(dot)
		_dot_labels.append(dot)

	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.tag_primary(_feedback_label)
	_feedback_label.add_theme_font_size_override("font_size", 18)
	_feedback_label.add_theme_color_override("font_color", Color.WHITE)
	_feedback_label.visible = false
	bead_slot.add_child(_feedback_label)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", _COLOR_BORDER)
	vbox.add_child(sep)

	# Numpad grid (3 columns)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	var numpad_order: Array[String] = ["7", "8", "9", "4", "5", "6", "1", "2", "3", "⌫", "0", ""]
	for key: String in numpad_order:
		if key == "":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(72.0, 52.0)
			grid.add_child(spacer)
			continue

		var btn := _make_numpad_button(key)
		if key == "⌫":
			btn.add_theme_color_override("font_color", _COLOR_DEL_TEXT)
		btn.pressed.connect(_on_numpad_pressed.bind(key))
		grid.add_child(btn)

	# Cancel row
	var cancel_btn := _make_button("Cancel")
	cancel_btn.pressed.connect(func() -> void: complete_puzzle(false))
	vbox.add_child(cancel_btn)


# ── Input handling ────────────────────────────────────────────────────────────

func _on_numpad_pressed(key: String) -> void:
	if _locked:
		return

	if key == "⌫":
		if _current_input.is_empty():
			return
		SFXManager.play(_SFX_BTN)
		_current_input = _current_input.left(_current_input.length() - 1)
		_update_dot_display()
		return

	if _current_input.length() >= _digit_count:
		return

	SFXManager.play(_SFX_BTN)
	_current_input += key
	_update_dot_display()

	if _current_input.length() == _digit_count:
		_check_answer()


func _update_dot_display() -> void:
	for i: int in range(_dot_labels.size()):
		var dot: Label = _dot_labels[i]
		if i < _current_input.length():
			dot.text = "●"
			dot.add_theme_color_override("font_color", _COLOR_DOT_FILL)
		else:
			dot.text = "○"
			dot.add_theme_color_override("font_color", _COLOR_DOT_EMPTY)


func _check_answer() -> void:
	_locked = true
	var success: bool = (_current_input == _correct_code)
	if success:
		SFXManager.play(_SFX_CORRECT)
	_show_inline_feedback("The password is correct" if success else "The password is incorrect")
	await get_tree().create_timer(2.0).timeout
	_hide_inline_feedback()
	if success:
		complete_puzzle(true)
	else:
		_reset_input()
		_locked = false


func _reset_input() -> void:
	_current_input = ""
	_update_dot_display()


# ── Inline feedback (replaces beads in-place) ─────────────────────────────────

func _show_inline_feedback(message: String) -> void:
	if _dot_row != null:
		_dot_row.visible = false
	if _feedback_label != null:
		_feedback_label.text = message
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


func _make_numpad_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(72.0, 52.0)
	btn.add_theme_font_size_override("font_size", 22)
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
