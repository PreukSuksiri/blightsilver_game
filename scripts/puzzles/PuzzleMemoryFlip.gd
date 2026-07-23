extends ExplorationPuzzleBase
## Memory Card Flip — find all matching pairs by flipping cards two at a time.
##
## Params (JSON in spot key field):
##   pairs : int — number of matching pairs (2–8, required)
##   cols  : int — grid columns (default 4)
##
## Example: {"pairs":4,"cols":4}

const _SFX_BTN     := preload("res://assets/audio/sfx/scifi_ui_9.mp3")
const _SFX_CORRECT := preload("res://assets/audio/sfx/scifi_ui_30.mp3")

const _COLOR_BG     := Color(0.05, 0.08, 0.14, 0.97)
const _COLOR_BORDER := Color(0.30, 0.70, 1.0, 0.80)
const _SYMBOL_POOL  := ["★", "♦", "♥", "◆", "☽", "◎", "♛", "✦"]

var _num_pairs: int = 0
var _cols: int = 4
var _symbols: Array[String] = []       # symbol per card index
var _matched: Array[bool] = []
var _revealed: Array[bool] = []
var _card_btns: Array[Button] = []
var _first_pick: int = -1
var _locked: bool = false
var _status_lbl: Label = null
var _match_count: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var pairs_raw: Variant = get_param("pairs", null)
	if pairs_raw == null or not str(pairs_raw).is_valid_int():
		_build_error_ui()
		return

	_num_pairs = int(str(pairs_raw))
	if _num_pairs < 2 or _num_pairs > 8:
		_build_error_ui()
		return

	_cols = int(str(get_param("cols", 4)))
	if _cols < 2 or _cols > 6:
		_cols = 4

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
	hint.text = "Requires \"pairs\" (integer 2–8).\nExample: {\"pairs\":4,\"cols\":4}"
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
	# Build and shuffle card array
	var deck: Array[String] = []
	for i: int in range(_num_pairs):
		var sym: String = _SYMBOL_POOL[i % _SYMBOL_POOL.size()]
		deck.append(sym)
		deck.append(sym)
	deck.shuffle()

	var total: int = deck.size()
	for s: String in deck:
		_symbols.append(s)
		_matched.append(false)
		_revealed.append(false)

	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size
	add_child(center)

	var panel_w: float = maxf(300.0, float(_cols) * 72.0 + 48.0)
	var panel := _make_panel(Vector2(panel_w, 0.0))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	_status_lbl = Label.new()
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.tag_primary(_status_lbl)
	_status_lbl.add_theme_font_size_override("font_size", 17)
	_status_lbl.add_theme_color_override("font_color", Color(0.65, 0.80, 1.0))
	_status_lbl.text = "Find all matching pairs"
	vbox.add_child(_status_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", _COLOR_BORDER)
	vbox.add_child(sep)

	var grid := GridContainer.new()
	grid.columns = _cols
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	for i: int in range(total):
		var btn := _make_card_button()
		var cap := i
		btn.pressed.connect(func() -> void: _on_card_pressed(cap))
		grid.add_child(btn)
		_card_btns.append(btn)

	var cancel_btn := _make_button("Cancel")
	cancel_btn.pressed.connect(func() -> void: complete_puzzle(false))
	vbox.add_child(cancel_btn)


# ── Input logic ───────────────────────────────────────────────────────────────

func _on_card_pressed(index: int) -> void:
	if _locked or _revealed[index] or _matched[index]:
		return
	SFXManager.play(_SFX_BTN)

	_revealed[index] = true
	_card_btns[index].text = _symbols[index]
	_card_btns[index].add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	_card_btns[index].add_theme_stylebox_override("normal", _make_card_revealed_sb())
	_card_btns[index].add_theme_stylebox_override("hover", _make_card_revealed_sb())

	if _first_pick == -1:
		_first_pick = index
		return

	# Second card picked — evaluate
	_locked = true
	var first: int = _first_pick
	_first_pick = -1

	await get_tree().create_timer(0.7).timeout

	if _symbols[first] == _symbols[index]:
		# Match
		_matched[first] = true
		_matched[index] = true
		_card_btns[first].add_theme_stylebox_override("normal", _make_card_matched_sb())
		_card_btns[index].add_theme_stylebox_override("normal", _make_card_matched_sb())
		_match_count += 1

		if _match_count == _num_pairs:
			SFXManager.play(_SFX_CORRECT)
			if _status_lbl:
				_status_lbl.text = "All pairs found!"
				_status_lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.60))
			await get_tree().create_timer(1.5).timeout
			complete_puzzle(true)
			return
		else:
			if _status_lbl:
				_status_lbl.text = "Match! %d / %d pairs" % [_match_count, _num_pairs]
	else:
		# No match — flip back
		_revealed[first] = false
		_revealed[index] = false
		_card_btns[first].text = "?"
		_card_btns[index].text = "?"
		_card_btns[first].add_theme_color_override("font_color", Color(0.30, 0.55, 0.85))
		_card_btns[index].add_theme_color_override("font_color", Color(0.30, 0.55, 0.85))
		_card_btns[first].add_theme_stylebox_override("normal", _make_card_hidden_sb())
		_card_btns[index].add_theme_stylebox_override("normal", _make_card_hidden_sb())
		_card_btns[first].add_theme_stylebox_override("hover", _make_card_hover_sb())
		_card_btns[index].add_theme_stylebox_override("hover", _make_card_hover_sb())

	_locked = false


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


func _make_card_button() -> Button:
	var btn := Button.new()
	btn.text = "?"
	btn.custom_minimum_size = Vector2(60.0, 60.0)
	btn.add_theme_font_size_override("font_size", 26)
	btn.add_theme_color_override("font_color", Color(0.30, 0.55, 0.85))
	btn.add_theme_stylebox_override("normal", _make_card_hidden_sb())
	btn.add_theme_stylebox_override("hover", _make_card_hover_sb())
	btn.add_theme_stylebox_override("pressed", _make_card_hidden_sb())
	btn.add_theme_stylebox_override("focus", _make_card_hidden_sb())
	return btn


func _make_card_hidden_sb() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.15, 0.30)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.20, 0.40, 0.70)
	sb.set_corner_radius_all(6)
	return sb


func _make_card_hover_sb() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.25, 0.48)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.40, 0.65, 1.0)
	sb.set_corner_radius_all(6)
	return sb


func _make_card_revealed_sb() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.22, 0.40)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.50, 0.80, 1.0)
	sb.set_corner_radius_all(6)
	return sb


func _make_card_matched_sb() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.22, 0.12)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.30, 0.85, 0.50)
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
