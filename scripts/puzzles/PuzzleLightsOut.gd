extends ExplorationPuzzleBase
## Lights Out — toggle cells to turn all lights OFF. Each tap flips a cell and its 4 neighbours.
##
## Params (JSON in spot key field):
##   size  : int — grid dimension N×N (default 3, max 5)
##   moves : int — scramble depth from solved state (default 5)
##
## Example: {"size":3,"moves":5}

const _SFX_BTN     := preload("res://assets/audio/sfx/scifi_ui_9.mp3")
const _SFX_CORRECT := preload("res://assets/audio/sfx/scifi_ui_30.mp3")

const _COLOR_BG      := Color(0.05, 0.08, 0.14, 0.97)
const _COLOR_BORDER  := Color(0.30, 0.70, 1.0, 0.80)
const _COLOR_CELL_ON := Color(0.35, 0.75, 1.0)
const _COLOR_CELL_OFF:= Color(0.08, 0.16, 0.30)

var _size: int = 3
var _grid: Array = []        # Array of Array[bool]
var _cell_btns: Array = []   # Array of Array[Button]
var _status_lbl: Label = null
var _locked: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	_size = int(str(get_param("size", 3)))
	if _size < 2 or _size > 5:
		_size = 3

	var moves: int = int(str(get_param("moves", 5)))
	if moves < 1:
		moves = 5

	# Initialise all OFF, then scramble
	_grid = []
	_cell_btns = []
	for _r: int in range(_size):
		var row: Array[bool] = []
		var btn_row: Array[Button] = []
		for _c: int in range(_size):
			row.append(false)
			btn_row.append(null)
		_grid.append(row)
		_cell_btns.append(btn_row)

	_scramble(moves)
	# If scramble somehow produced all-OFF, force one toggle so there's something to solve
	if _all_off():
		_toggle(0, 0)

	_build_ui()


func _scramble(moves: int) -> void:
	for _i: int in range(moves):
		var r: int = randi() % _size
		var c: int = randi() % _size
		_toggle(r, c)


# ── Toggle logic ──────────────────────────────────────────────────────────────

func _toggle(r: int, c: int) -> void:
	var offsets: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(0, -1), Vector2i(0, 1),
	]
	for off: Vector2i in offsets:
		var nr: int = r + off.x
		var nc: int = c + off.y
		if nr >= 0 and nr < _size and nc >= 0 and nc < _size:
			_grid[nr][nc] = not _grid[nr][nc]


func _all_off() -> bool:
	for r: int in range(_size):
		for c: int in range(_size):
			if _grid[r][c]:
				return false
	return true


# ── Error UI ──────────────────────────────────────────────────────────────────
# (size/moves always have defaults so error UI is a safety fallback only)

func _build_error_ui() -> void:
	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size
	add_child(center)

	var panel := _make_panel(Vector2(320.0, 160.0))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var err_lbl := Label.new()
	err_lbl.text = "invalid parameter"
	err_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	err_lbl.add_theme_font_size_override("font_size", 22)
	err_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	vbox.add_child(err_lbl)

	var close_btn := _make_button("Close")
	close_btn.pressed.connect(func() -> void: complete_puzzle(false))
	vbox.add_child(close_btn)


# ── Main UI ───────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size
	add_child(center)

	var cell_size: float = maxf(52.0, 260.0 / float(_size))
	var panel_w: float = float(_size) * (cell_size + 8.0) + 48.0
	var panel := _make_panel(Vector2(panel_w, 0.0))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	_status_lbl = Label.new()
	_status_lbl.text = "Turn all lights off"
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.tag_primary(_status_lbl)
	_status_lbl.add_theme_font_size_override("font_size", 17)
	_status_lbl.add_theme_color_override("font_color", Color(0.65, 0.80, 1.0))
	vbox.add_child(_status_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", _COLOR_BORDER)
	vbox.add_child(sep)

	var grid := GridContainer.new()
	grid.columns = _size
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	for r: int in range(_size):
		for c: int in range(_size):
			var btn := _make_cell_button(cell_size)
			var cr := r
			var cc := c
			btn.pressed.connect(func() -> void: _on_cell_pressed(cr, cc))
			grid.add_child(btn)
			_cell_btns[r][c] = btn

	_refresh_all_cells()

	var cancel_btn := _make_button("Cancel")
	cancel_btn.pressed.connect(func() -> void: complete_puzzle(false))
	vbox.add_child(cancel_btn)


func _refresh_all_cells() -> void:
	for r: int in range(_size):
		for c: int in range(_size):
			_refresh_cell(r, c)


func _refresh_cell(r: int, c: int) -> void:
	var btn: Button = _cell_btns[r][c]
	var on: bool = _grid[r][c]
	btn.add_theme_stylebox_override("normal", _make_cell_sb(on))
	btn.add_theme_stylebox_override("hover", _make_cell_sb(on, true))
	btn.add_theme_stylebox_override("pressed", _make_cell_sb(on))
	btn.add_theme_stylebox_override("focus", _make_cell_sb(on))


# ── Input logic ───────────────────────────────────────────────────────────────

func _on_cell_pressed(r: int, c: int) -> void:
	if _locked:
		return
	SFXManager.play(_SFX_BTN)
	_toggle(r, c)
	_refresh_all_cells()

	if _all_off():
		_locked = true
		SFXManager.play(_SFX_CORRECT)
		if _status_lbl:
			_status_lbl.text = "All lights off!"
			_status_lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.60))
		await get_tree().create_timer(1.8).timeout
		complete_puzzle(true)


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


func _make_cell_button(cell_size: float) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(cell_size, cell_size)
	btn.add_theme_stylebox_override("focus", StyleBoxFlat.new())
	return btn


func _make_cell_sb(on: bool, hover: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if on:
		sb.bg_color = _COLOR_CELL_ON if not hover else Color(0.50, 0.85, 1.0)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.60, 0.90, 1.0)
	else:
		sb.bg_color = Color(0.10, 0.20, 0.38) if hover else _COLOR_CELL_OFF
		sb.set_border_width_all(1)
		sb.border_color = Color(0.18, 0.35, 0.58)
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
