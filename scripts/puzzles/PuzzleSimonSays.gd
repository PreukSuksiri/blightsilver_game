extends ExplorationPuzzleBase
## Simon Says — watch the flashing sequence, then repeat it. Sequence grows each round.
##
## Params (JSON in spot key field):
##   length    : int   — total sequence length to win (required, 2–8)
##   flash_sec : float — panel flash duration in seconds (default 0.6)
##   panels    : int   — number of panels: 3 or 4 (default 4)
##
## Example: {"length":4,"flash_sec":0.6,"panels":4}

const _SFX_BTN     := preload("res://assets/audio/sfx/scifi_ui_9.mp3")
const _SFX_CORRECT := preload("res://assets/audio/sfx/scifi_ui_30.mp3")
const _FONT_CHIVO  := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")

const _COLOR_BG     := Color(0.05, 0.08, 0.14, 0.97)
const _COLOR_BORDER := Color(0.30, 0.70, 1.0, 0.80)

# Base colours for each panel (4 panels)
const _PANEL_COLORS_4: Array[Color] = [
	Color(0.75, 0.20, 0.20),  # 0 — Red
	Color(0.20, 0.40, 0.80),  # 1 — Blue
	Color(0.20, 0.65, 0.30),  # 2 — Green
	Color(0.70, 0.60, 0.10),  # 3 — Gold
]
# Base colours for 3-panel mode (uses first 3)
const _PANEL_COLORS_3: Array[Color] = [
	Color(0.75, 0.20, 0.20),
	Color(0.20, 0.40, 0.80),
	Color(0.20, 0.65, 0.30),
]

var _target_length: int = 4
var _flash_sec: float = 0.6
var _num_panels: int = 4
var _full_sequence: Array[int] = []
var _round: int = 1         # how many steps player must repeat this round
var _player_pos: int = 0
var _panel_btns: Array[Button] = []
var _panel_colors: Array[Color] = []
var _status_lbl: Label = null
var _locked: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var len_raw: Variant = get_param("length", null)
	if len_raw == null or not str(len_raw).is_valid_int():
		_build_error_ui()
		return

	_target_length = int(str(len_raw))
	if _target_length < 2 or _target_length > 8:
		_build_error_ui()
		return

	_flash_sec = float(str(get_param("flash_sec", 0.6)))
	if _flash_sec <= 0.0:
		_flash_sec = 0.6

	_num_panels = int(str(get_param("panels", 4)))
	if _num_panels < 3 or _num_panels > 4:
		_num_panels = 4

	_panel_colors = _PANEL_COLORS_4 if _num_panels == 4 else _PANEL_COLORS_3

	# Pre-generate the full random sequence
	for _i: int in range(_target_length):
		_full_sequence.append(randi() % _num_panels)

	_build_ui()


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
	hint.text = "Requires \"length\" (integer 2–8).\nExample: {\"length\":4,\"flash_sec\":0.6,\"panels\":4}"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	vbox.add_child(hint)

	var close_btn := _make_button("Close")
	close_btn.pressed.connect(func() -> void: complete_puzzle(false))
	vbox.add_child(close_btn)


# ── Main UI ───────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size
	add_child(center)

	var panel := _make_panel(Vector2(340.0, 0.0))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	_status_lbl = Label.new()
	_status_lbl.text = "Watch the sequence…"
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_override("font", _FONT_CHIVO)
	_status_lbl.add_theme_font_size_override("font_size", 17)
	_status_lbl.add_theme_color_override("font_color", Color(0.65, 0.80, 1.0))
	vbox.add_child(_status_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", _COLOR_BORDER)
	vbox.add_child(sep)

	# Panel grid — 2×2 for 4 panels, 1×3 for 3 panels
	if _num_panels == 4:
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		vbox.add_child(grid)
		for i: int in range(4):
			var btn := _make_panel_button(i)
			grid.add_child(btn)
			_panel_btns.append(btn)
	else:
		# 3 panels in one row
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)
		for i: int in range(3):
			var btn := _make_panel_button(i)
			btn.custom_minimum_size = Vector2(90.0, 120.0)
			hbox.add_child(btn)
			_panel_btns.append(btn)

	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("color", _COLOR_BORDER)
	vbox.add_child(sep2)

	var cancel_btn := _make_button("Cancel")
	cancel_btn.pressed.connect(func() -> void: complete_puzzle(false))
	vbox.add_child(cancel_btn)

	# Start the first round after a short delay
	_locked = true
	get_tree().create_timer(0.8).timeout.connect(_show_round)


# ── Game logic ────────────────────────────────────────────────────────────────

func _show_round() -> void:
	_locked = true
	_set_status("Watch carefully…", Color(0.65, 0.80, 1.0))
	await get_tree().create_timer(0.4).timeout

	for i: int in range(_round):
		var panel_idx: int = _full_sequence[i]
		_set_panel_lit(panel_idx, true)
		SFXManager.play(_SFX_BTN)
		await get_tree().create_timer(_flash_sec).timeout
		_set_panel_lit(panel_idx, false)
		if i < _round - 1:
			await get_tree().create_timer(0.18).timeout

	_player_pos = 0
	_locked = false
	_set_status("Your turn! (%d step%s)" % [_round, "s" if _round > 1 else ""], Color(0.85, 0.95, 1.0))


func _on_panel_pressed(index: int) -> void:
	if _locked:
		return
	SFXManager.play(_SFX_BTN)
	_set_panel_lit(index, true)
	await get_tree().create_timer(0.15).timeout
	_set_panel_lit(index, false)

	if index != _full_sequence[_player_pos]:
		# Wrong — restart from round 1
		_locked = true
		_set_status("Wrong! Starting over.", Color(1.0, 0.55, 0.30))
		await get_tree().create_timer(1.5).timeout
		_round = 1
		_show_round()
		return

	_player_pos += 1

	if _player_pos == _round:
		if _round == _target_length:
			# Win
			_locked = true
			SFXManager.play(_SFX_CORRECT)
			_set_status("Sequence matched!", Color(0.45, 1.0, 0.60))
			await get_tree().create_timer(2.0).timeout
			complete_puzzle(true)
		else:
			_round += 1
			_set_status("Correct!", Color(0.45, 1.0, 0.60))
			await get_tree().create_timer(0.8).timeout
			_show_round()


func _set_panel_lit(index: int, lit: bool) -> void:
	if index >= _panel_btns.size():
		return
	_panel_btns[index].modulate = Color(1.0, 1.0, 1.0) if lit else Color(0.35, 0.35, 0.35)


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


func _make_panel_button(index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(130.0, 120.0)
	btn.modulate = Color(0.35, 0.35, 0.35)

	var sb := StyleBoxFlat.new()
	sb.bg_color = _panel_colors[index]
	sb.set_corner_radius_all(8)

	var focus_sb := StyleBoxFlat.new()
	focus_sb.bg_color = Color(0, 0, 0, 0)

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", focus_sb)

	var cap := index
	btn.pressed.connect(func() -> void: _on_panel_pressed(cap))
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
