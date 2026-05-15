extends Control
# Setup Phase — visual card placement with drag-and-drop.
# Public API used by GameBoard.gd:
#   start_setup(player_index: int)
#   signal setup_complete()
#   visible (inherited)

const DeckData = preload("res://resources/DeckData.gd")
signal setup_complete()

const FULL_CARDS_DIR := "res://assets/textures/cards/full_cards/"
const GRID_N  : int   = 5
const CELL_W  : float = 100.0
const CELL_H  : float = 137.0
const CELL_GAP: int   = 5
const GAL_W   : float = 88.0
const GAL_H   : float = 121.0
const GAL_GAP : int   = 6

# ─────────────────────────────────────────────────────────────
# Inner class: gallery card (drag source + tap to preview)
# ─────────────────────────────────────────────────────────────
class DraggableCard extends TextureRect:
	var card_name:    String   = ""
	var card_type:    String   = ""
	var on_hover_cb:  Callable = Callable()
	var on_detail_cb: Callable = Callable()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mbe := event as InputEventMouseButton
			if mbe.button_index == MOUSE_BUTTON_LEFT and mbe.pressed and mbe.double_click:
				if on_detail_cb.is_valid():
					on_detail_cb.call(card_name, card_type)

	func _get_drag_data(_pos: Vector2) -> Variant:
		# Keep info panel updated while dragging
		if on_hover_cb.is_valid():
			on_hover_cb.call(card_name, card_type)
		var prev := TextureRect.new()
		prev.texture             = texture
		prev.custom_minimum_size = Vector2(88.0, 121.0)
		prev.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
		prev.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		prev.modulate            = Color(1.0, 1.0, 1.0, 0.82)
		set_drag_preview(prev)
		return {
			"card_name": card_name, "card_type": card_type,
			"from_grid": false, "grid_row": -1, "grid_col": -1
		}

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER and on_hover_cb.is_valid():
			on_hover_cb.call(card_name, card_type)

# ─────────────────────────────────────────────────────────────
# Inner class: grid cell (drop target + drag source + tap to preview)
# ─────────────────────────────────────────────────────────────
class GridCell extends Panel:
	var grid_row:      int      = 0
	var grid_col:      int      = 0
	var occupied_name: String   = ""
	var occupied_type: String   = ""
	var on_drop_cb:    Callable = Callable()
	var on_unplace_cb: Callable = Callable()
	var on_hover_cb:   Callable = Callable()
	var on_detail_cb:  Callable = Callable()
	var on_bluff_cb:   Callable = Callable()
	var _card_tex:     TextureRect = null
	var _emoticon_lbl: Label       = null
	var _drag_started: bool        = false

	func set_emoticon(emoji: String) -> void:
		if _emoticon_lbl == null:
			_emoticon_lbl = Label.new()
			_emoticon_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
			_emoticon_lbl.offset_top    = 2.0
			_emoticon_lbl.offset_bottom = 26.0
			_emoticon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_emoticon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_emoticon_lbl.z_index = 5
			add_child(_emoticon_lbl)
		_emoticon_lbl.text = emoji

	func occupy(p_name: String, p_type: String, tex: Texture2D) -> void:
		occupied_name = p_name
		occupied_type = p_type
		if _card_tex == null:
			_card_tex = TextureRect.new()
			_card_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_card_tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			_card_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			_card_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(_card_tex)
		_card_tex.texture = tex

	func vacate() -> void:
		occupied_name = ""
		occupied_type = ""
		if _card_tex != null:
			_card_tex.texture = null

	func _get_drag_data(_pos: Vector2) -> Variant:
		if occupied_name.is_empty():
			return null
		_drag_started = true
		# Keep info panel updated while dragging
		if on_hover_cb.is_valid():
			on_hover_cb.call(occupied_name, occupied_type)
		var prev := TextureRect.new()
		if _card_tex != null:
			prev.texture = _card_tex.texture
		prev.custom_minimum_size = Vector2(88.0, 121.0)
		prev.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
		prev.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		prev.modulate            = Color(1.0, 1.0, 1.0, 0.82)
		set_drag_preview(prev)
		return {
			"card_name": occupied_name, "card_type": occupied_type,
			"from_grid": true, "grid_row": grid_row, "grid_col": grid_col
		}

	func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
		return data is Dictionary and (data as Dictionary).has("card_name")

	func _drop_data(_pos: Vector2, data: Variant) -> void:
		if on_drop_cb.is_valid():
			on_drop_cb.call(grid_row, grid_col, data as Dictionary)

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton):
			return
		var mbe := event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT and mbe.pressed:
			_drag_started = false  # reset on every new press
			if mbe.double_click:
				if not occupied_name.is_empty() and on_detail_cb.is_valid():
					on_detail_cb.call(occupied_name, occupied_type)
		elif mbe.button_index == MOUSE_BUTTON_LEFT and not mbe.pressed and not mbe.double_click:
			# Release with no drag = tap
			if not _drag_started and on_bluff_cb.is_valid():
				on_bluff_cb.call(grid_row, grid_col)
		elif mbe.button_index == MOUSE_BUTTON_RIGHT and mbe.pressed:
			if not occupied_name.is_empty() and on_unplace_cb.is_valid():
				on_unplace_cb.call(grid_row, grid_col)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER and on_hover_cb.is_valid():
			if not occupied_name.is_empty():
				on_hover_cb.call(occupied_name, occupied_type)

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var current_setup_player: int = 0
var _chars_remaining: Array = []
var _traps_remaining: Array = []
var _grid_cells: Array = []          # [row][col] -> GridCell

var _player_lbl   : Label           = null
var _instr_lbl    : Label           = null
var _gallery_flow : HFlowContainer  = null
var _confirm_btn  : Button          = null
var _random_btn   : Button          = null
var _sp_p1_portrait: TextureRect    = null
var _sp_p2_portrait: TextureRect    = null

# Card info strip
var _info_img       : TextureRect = null
var _info_name      : Label       = null
var _info_stats     : Label       = null
var _info_desc      : Label       = null
var _info_preview_btn: Button     = null
var _info_card_name : String      = ""
var _info_card_type : String      = ""

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()

# ─────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────
func start_setup(player_index: int) -> void:
	current_setup_player = player_index
	_player_lbl.text = "PLAYER %d  —  Place Your Cards" % (player_index + 1)
	if _sp_p1_portrait:
		_sp_p1_portrait.visible = (player_index == 0)
	if _sp_p2_portrait:
		_sp_p2_portrait.visible = (player_index == 1)

	# Restore interaction (may have been locked by the previous player's flip animation)
	_gallery_flow.mouse_filter = Control.MOUSE_FILTER_STOP
	for r in range(GRID_N):
		for c in range(GRID_N):
			var cell := _grid_cells[r][c] as GridCell
			cell.mouse_filter = Control.MOUSE_FILTER_STOP
			cell.scale = Vector2(1.0, 1.0)  # reset any leftover tween scale

	# Reset confirm button, random button, and info panel
	_confirm_btn.disabled = true
	_random_btn.disabled  = true
	_info_card_name = ""
	_info_card_type = ""
	_info_img.texture = null
	_info_name.text = "Hover over a card to preview"
	_info_stats.text = ""
	_info_desc.text = ""
	_info_preview_btn.disabled = true

	_reset_grid()

	var deck: DeckData = SaveManager.get_active_deck()
	if deck == null or not deck.is_valid():
		_instr_lbl.text = "No valid deck found. Please build a deck first."
		_confirm_btn.disabled = true
		return

	_chars_remaining = deck.characters.duplicate()
	_traps_remaining = deck.traps.duplicate()
	GameState.tech_hands[player_index] = deck.techs.duplicate()
	_random_btn.disabled = false
	_refresh_gallery()
	_refresh_confirm()

# ─────────────────────────────────────────────────────────────
# UI build
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ── Solid background (center only, margins handled separately) ──
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left  =  160.0
	bg.offset_right = -160.0
	bg.color = Color(0.04, 0.05, 0.12, 1.0)
	add_child(bg)

	# ── Black margin strips ───────────────────────────────────
	var lm := ColorRect.new()
	lm.layout_mode    = 1
	lm.anchor_left    = 0.0;  lm.anchor_top    = 0.0
	lm.anchor_right   = 0.0;  lm.anchor_bottom = 1.0
	lm.offset_left    = 0.0;  lm.offset_top    = 0.0
	lm.offset_right   = 160.0; lm.offset_bottom = 0.0
	lm.color          = Color(0.0, 0.0, 0.0, 1.0)
	add_child(lm)

	var rm := ColorRect.new()
	rm.layout_mode    = 1
	rm.anchor_left    = 1.0;  rm.anchor_top    = 0.0
	rm.anchor_right   = 1.0;  rm.anchor_bottom = 1.0
	rm.offset_left    = -160.0; rm.offset_top  = 0.0
	rm.offset_right   = 0.0;  rm.offset_bottom = 0.0
	rm.color          = Color(0.0, 0.0, 0.0, 1.0)
	add_child(rm)

	# ── Header bar ──────────────────────────────────────────
	var header := Panel.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left   =  160.0
	header.offset_right  = -160.0
	header.offset_bottom = 72.0
	var hdr_sb := StyleBoxFlat.new()
	hdr_sb.bg_color            = Color(0.05, 0.07, 0.16, 1.0)
	hdr_sb.border_width_bottom = 1
	hdr_sb.border_color        = Color(0.35, 0.6, 1.0, 0.45)
	header.add_theme_stylebox_override("panel", hdr_sb)
	add_child(header)

	_player_lbl = Label.new()
	_player_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_player_lbl.offset_top    = 8.0
	_player_lbl.offset_bottom = 42.0
	_player_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_lbl.add_theme_font_size_override("font_size", 24)
	_player_lbl.add_theme_color_override("font_color", Color(0.5, 0.88, 1.0))
	header.add_child(_player_lbl)

	_instr_lbl = Label.new()
	_instr_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_instr_lbl.offset_top    = 44.0
	_instr_lbl.offset_bottom = 70.0
	_instr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instr_lbl.add_theme_font_size_override("font_size", 13)
	_instr_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	header.add_child(_instr_lbl)

	# ── Body (grid + right panel side by side) ──────────────
	var body := HBoxContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_top    = 76.0
	body.offset_bottom = -62.0
	body.offset_left   = 172.0
	body.offset_right  = -172.0
	body.add_theme_constant_override("separation", 14)
	add_child(body)

	_build_grid_panel(body)
	_build_right_panel(body)

	# ── Bottom bar: Random + Confirm ─────────────────────────
	_random_btn = Button.new()
	_random_btn.layout_mode    = 1
	_random_btn.anchor_left    = 0.0;  _random_btn.anchor_top    = 1.0
	_random_btn.anchor_right   = 0.0;  _random_btn.anchor_bottom = 1.0
	_random_btn.offset_left    = 172.0; _random_btn.offset_top   = -54.0
	_random_btn.offset_right   = 476.0; _random_btn.offset_bottom = -8.0
	_random_btn.text = "⚄ RANDOM FORMATION"
	_random_btn.add_theme_font_size_override("font_size", 16)
	_random_btn.disabled = true
	_random_btn.pressed.connect(_on_random_formation)
	add_child(_random_btn)

	_confirm_btn = Button.new()
	_confirm_btn.layout_mode    = 1
	_confirm_btn.anchor_left    = 0.0;  _confirm_btn.anchor_top    = 1.0
	_confirm_btn.anchor_right   = 1.0;  _confirm_btn.anchor_bottom = 1.0
	_confirm_btn.offset_left    = 484.0; _confirm_btn.offset_top   = -54.0
	_confirm_btn.offset_right   = -172.0; _confirm_btn.offset_bottom = -8.0
	_confirm_btn.text = "CONFIRM PLACEMENT"
	_confirm_btn.add_theme_font_size_override("font_size", 20)
	_confirm_btn.disabled = true
	_confirm_btn.pressed.connect(_on_confirm)
	add_child(_confirm_btn)

	# ── Player portrait illustrations (on top of all content) ─
	const _SP_REF_H: float = 720.0
	var _sp_p1_tex: Texture2D = load(GameState.player_portraits[0])
	if _sp_p1_tex:
		var _sz := _sp_p1_tex.get_size()
		var _pw: float = _SP_REF_H * _sz.x / _sz.y if _sz.y > 0.0 else 220.0
		var _p1p := TextureRect.new()
		_p1p.texture       = _sp_p1_tex
		_p1p.layout_mode   = 1
		_p1p.anchor_left   = 0.0;  _p1p.anchor_top    = 1.0
		_p1p.anchor_right  = 0.0;  _p1p.anchor_bottom = 1.0
		_p1p.offset_left   = -_pw * 0.4; _p1p.offset_top    = -_SP_REF_H
		_p1p.offset_right  =  _pw * 0.6; _p1p.offset_bottom = 0.0
		_p1p.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		_p1p.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
		_p1p.flip_h        = true
		_p1p.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		_p1p.z_index       = 3
		add_child(_p1p)
		_sp_p1_portrait = _p1p

	var _sp_p2_tex: Texture2D = load(GameState.player_portraits[1])
	if _sp_p2_tex:
		var _sz := _sp_p2_tex.get_size()
		var _pw: float = _SP_REF_H * _sz.x / _sz.y if _sz.y > 0.0 else 220.0
		var _p2p := TextureRect.new()
		_p2p.texture       = _sp_p2_tex
		_p2p.layout_mode   = 1
		_p2p.anchor_left   = 1.0;  _p2p.anchor_top    = 1.0
		_p2p.anchor_right  = 1.0;  _p2p.anchor_bottom = 1.0
		_p2p.offset_left   = -_pw * 0.6; _p2p.offset_top    = -_SP_REF_H
		_p2p.offset_right  =  _pw * 0.4; _p2p.offset_bottom = 0.0
		_p2p.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		_p2p.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
		_p2p.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		_p2p.z_index       = 3
		add_child(_p2p)
		_sp_p2_portrait = _p2p

func _build_grid_panel(parent: Control) -> void:
	var grid_w: float = CELL_W * GRID_N + float(CELL_GAP) * (GRID_N - 1) + 24.0
	var grid_h: float = CELL_H * GRID_N + float(CELL_GAP) * (GRID_N - 1) + 24.0

	var grid_panel := Panel.new()
	grid_panel.custom_minimum_size = Vector2(grid_w, grid_h)
	grid_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var gp_sb := StyleBoxFlat.new()
	gp_sb.bg_color                   = Color(0.06, 0.08, 0.18, 1.0)
	gp_sb.border_color               = Color(0.35, 0.6, 1.0, 0.45)
	gp_sb.border_width_left          = 1
	gp_sb.border_width_right         = 1
	gp_sb.border_width_top           = 1
	gp_sb.border_width_bottom        = 1
	gp_sb.corner_radius_top_left     = 8
	gp_sb.corner_radius_top_right    = 8
	gp_sb.corner_radius_bottom_left  = 8
	gp_sb.corner_radius_bottom_right = 8
	grid_panel.add_theme_stylebox_override("panel", gp_sb)
	parent.add_child(grid_panel)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid_panel.add_child(center)

	var grid_cont := GridContainer.new()
	grid_cont.columns = GRID_N
	grid_cont.add_theme_constant_override("h_separation", CELL_GAP)
	grid_cont.add_theme_constant_override("v_separation", CELL_GAP)
	center.add_child(grid_cont)

	_grid_cells = []
	for r in range(GRID_N):
		var row_arr: Array = []
		for c in range(GRID_N):
			var cell := GridCell.new()
			cell.grid_row      = r
			cell.grid_col      = c
			cell.on_drop_cb    = _on_card_dropped
			cell.on_unplace_cb = _on_cell_unplace
			cell.on_hover_cb   = _show_card_info
			cell.on_detail_cb  = _open_card_detail
			cell.on_bluff_cb   = _on_cell_bluff_tap
			cell.custom_minimum_size = Vector2(CELL_W, CELL_H)
			var cell_sb := StyleBoxFlat.new()
			cell_sb.bg_color                   = Color(0.08, 0.10, 0.24, 1.0)
			cell_sb.border_color               = Color(0.28, 0.48, 0.9, 0.55)
			cell_sb.border_width_left          = 1
			cell_sb.border_width_right         = 1
			cell_sb.border_width_top           = 1
			cell_sb.border_width_bottom        = 1
			cell_sb.corner_radius_top_left     = 4
			cell_sb.corner_radius_top_right    = 4
			cell_sb.corner_radius_bottom_left  = 4
			cell_sb.corner_radius_bottom_right = 4
			cell.add_theme_stylebox_override("panel", cell_sb)
			grid_cont.add_child(cell)
			row_arr.append(cell)
		_grid_cells.append(row_arr)

# Right panel = VBox: gallery scroll (top, expands) + card info strip (bottom, fixed)
func _build_right_panel(parent: Control) -> void:
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 8)
	parent.add_child(right_vbox)

	_build_gallery_panel(right_vbox)
	_build_info_panel(right_vbox)

func _build_gallery_panel(parent: Control) -> void:
	# Fixed height for exactly 2 rows: 2×(card+label) + 1 gap + header + padding
	const TWO_ROW_H: float = (GAL_H + 22.0) * 2.0 + GAL_GAP + 38.0
	var gal_panel := Panel.new()
	gal_panel.custom_minimum_size   = Vector2(0.0, TWO_ROW_H)
	gal_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var gal_sb := StyleBoxFlat.new()
	gal_sb.bg_color                   = Color(0.05, 0.07, 0.16, 1.0)
	gal_sb.border_color               = Color(0.35, 0.6, 1.0, 0.35)
	gal_sb.border_width_left          = 1
	gal_sb.border_width_right         = 1
	gal_sb.border_width_top           = 1
	gal_sb.border_width_bottom        = 1
	gal_sb.corner_radius_top_left     = 8
	gal_sb.corner_radius_top_right    = 8
	gal_sb.corner_radius_bottom_left  = 8
	gal_sb.corner_radius_bottom_right = 8
	gal_panel.add_theme_stylebox_override("panel", gal_sb)
	parent.add_child(gal_panel)

	var gal_lbl := Label.new()
	gal_lbl.text = "YOUR DECK  —  drag onto grid  |  right-click placed card to retrieve"
	gal_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	gal_lbl.offset_top    = 6.0
	gal_lbl.offset_bottom = 28.0
	gal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gal_lbl.add_theme_font_size_override("font_size", 12)
	gal_lbl.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0, 0.85))
	gal_panel.add_child(gal_lbl)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = 30.0
	scroll.offset_left   = 8.0
	scroll.offset_right  = -8.0
	scroll.offset_bottom = -8.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gal_panel.add_child(scroll)

	_gallery_flow = HFlowContainer.new()
	_gallery_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gallery_flow.add_theme_constant_override("h_separation", GAL_GAP)
	_gallery_flow.add_theme_constant_override("v_separation", GAL_GAP)
	scroll.add_child(_gallery_flow)

func _build_info_panel(parent: Control) -> void:
	var info_panel := Panel.new()
	info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var ip_sb := StyleBoxFlat.new()
	ip_sb.bg_color                   = Color(0.04, 0.06, 0.14, 1.0)
	ip_sb.border_color               = Color(0.35, 0.6, 1.0, 0.35)
	ip_sb.border_width_left          = 1
	ip_sb.border_width_right         = 1
	ip_sb.border_width_top           = 1
	ip_sb.border_width_bottom        = 1
	ip_sb.corner_radius_top_left     = 8
	ip_sb.corner_radius_top_right    = 8
	ip_sb.corner_radius_bottom_left  = 8
	ip_sb.corner_radius_bottom_right = 8
	info_panel.add_theme_stylebox_override("panel", ip_sb)
	parent.add_child(info_panel)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left   = 10.0
	row.offset_right  = -10.0
	row.offset_top    = 8.0
	row.offset_bottom = -8.0
	row.add_theme_constant_override("separation", 12)
	info_panel.add_child(row)

	# Left: card thumbnail (larger)
	_info_img = TextureRect.new()
	_info_img.custom_minimum_size = Vector2(160.0, 220.0)
	_info_img.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	_info_img.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT
	_info_img.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_info_img)

	# Right: text
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 6)
	row.add_child(text_col)

	_info_name = Label.new()
	_info_name.text = "Hover over a card to preview"
	_info_name.add_theme_font_size_override("font_size", 22)
	_info_name.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	text_col.add_child(_info_name)

	_info_stats = Label.new()
	_info_stats.add_theme_font_size_override("font_size", 16)
	_info_stats.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	text_col.add_child(_info_stats)

	_info_desc = Label.new()
	_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_desc.add_theme_font_size_override("font_size", 14)
	_info_desc.add_theme_color_override("font_color", Color(0.78, 0.78, 0.85))
	text_col.add_child(_info_desc)

	_info_preview_btn = Button.new()
	_info_preview_btn.text = "VIEW FULL CARD"
	_info_preview_btn.disabled = true
	_info_preview_btn.add_theme_font_size_override("font_size", 14)
	_info_preview_btn.add_theme_color_override("font_color", Color(0.5, 0.88, 1.0))
	_info_preview_btn.pressed.connect(_on_preview_btn)
	text_col.add_child(_info_preview_btn)

# ─────────────────────────────────────────────────────────────
# Card info display
# ─────────────────────────────────────────────────────────────
func _on_preview_btn() -> void:
	if _info_card_name != "":
		CardDetailOverlay.open(self, _info_card_name, _info_card_type)

func _open_card_detail(card_name: String, card_type: String) -> void:
	CardDetailOverlay.open(self, card_name, card_type)

func _show_card_info(card_name: String, card_type: String) -> void:
	_info_card_name = card_name
	_info_card_type = card_type
	_info_preview_btn.disabled = false

	var tex: Texture2D = _load_card_tex(card_name, card_type)
	_info_img.texture = tex

	_info_name.text = card_name

	match card_type:
		"character":
			_info_name.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
			_info_stats.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
			var data: Variant = CardDatabase.get_character(card_name)
			if data != null:
				var cd := data as CharacterData
				_info_stats.text = "[%s]  ATK %d  DEF %d  %d◆" % [
					cd.get_affinity_name(), cd.base_atk, cd.base_def, cd.crystal_cost]
				_info_desc.text = cd.ability_description
			else:
				_info_stats.text = "Character"
				_info_desc.text  = ""
		"trap":
			_info_name.add_theme_color_override("font_color", Color(1.0, 0.38, 0.38))
			_info_stats.add_theme_color_override("font_color", Color(1.0, 0.38, 0.38))
			var data: Variant = CardDatabase.get_trap(card_name)
			if data != null:
				var td := data as TrapData
				_info_stats.text = "Trap  %d◆" % td.crystal_cost
				_info_desc.text  = td.effect_description
			else:
				_info_stats.text = "Trap"
				_info_desc.text  = ""
		"tech":
			_info_name.add_theme_color_override("font_color", Color(0.3, 1.0, 0.65))
			_info_stats.add_theme_color_override("font_color", Color(0.3, 1.0, 0.65))
			var data: Variant = CardDatabase.get_tech(card_name)
			if data != null:
				var tc := data as TechCardData
				_info_stats.text = "Tech  %d◆" % tc.crystal_cost
				_info_desc.text  = tc.get_effect_description()
			else:
				_info_stats.text = "Tech"
				_info_desc.text  = ""

# ─────────────────────────────────────────────────────────────
# Grid management
# ─────────────────────────────────────────────────────────────
func _reset_grid() -> void:
	for r in range(GRID_N):
		for c in range(GRID_N):
			var cell: GridCell = _grid_cells[r][c]
			cell.vacate()
			cell.set_emoticon("")
			GameState.place_dead_end(current_setup_player, r, c)

func _load_card_tex(card_name: String, card_type: String = "") -> Texture2D:
	var snake: String = _card_name_to_snake(card_name)
	# 1. Canonical name
	var path: String = FULL_CARDS_DIR + snake + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	# 2. Type-prefixed name (CardExporter collision-guard output)
	if card_type != "":
		path = FULL_CARDS_DIR + card_type + "_" + snake + ".png"
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

# ─────────────────────────────────────────────────────────────
# Gallery
# ─────────────────────────────────────────────────────────────
func _refresh_gallery() -> void:
	for ch in _gallery_flow.get_children():
		ch.queue_free()
	for card_name: String in _chars_remaining:
		_add_gallery_card(card_name, "character")
	for card_name: String in _traps_remaining:
		_add_gallery_card(card_name, "trap")

func _add_gallery_card(card_name: String, card_type: String) -> void:
	var wrap := VBoxContainer.new()
	wrap.custom_minimum_size = Vector2(GAL_W, GAL_H + 22.0)
	wrap.add_theme_constant_override("separation", 2)
	_gallery_flow.add_child(wrap)

	var dc := DraggableCard.new()
	dc.card_name             = card_name
	dc.card_type             = card_type
	dc.on_hover_cb           = _show_card_info
	dc.on_detail_cb          = _open_card_detail
	dc.custom_minimum_size   = Vector2(GAL_W, GAL_H)
	dc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dc.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
	dc.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tex: Texture2D = _load_card_tex(card_name, card_type)
	if tex != null:
		dc.texture = tex
	else:
		dc.modulate = Color(0.35, 0.55, 1.0) if card_type == "character" \
			else Color(1.0, 0.38, 0.38)
	wrap.add_child(dc)

	var lbl := Label.new()
	lbl.text                 = card_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	wrap.add_child(lbl)

# ─────────────────────────────────────────────────────────────
# Drop / unplace handlers
# ─────────────────────────────────────────────────────────────
func _on_card_dropped(r: int, c: int, data: Dictionary) -> void:
	var card_name: String = str(data["card_name"])
	var card_type: String = str(data["card_type"])
	var from_grid: bool   = bool(data.get("from_grid", false))
	var src_r: int        = int(data.get("grid_row", -1))
	var src_c: int        = int(data.get("grid_col", -1))

	if from_grid and src_r == r and src_c == c:
		return

	var target_cell: GridCell = _grid_cells[r][c]
	if not target_cell.occupied_name.is_empty():
		_return_to_pool(target_cell.occupied_name, target_cell.occupied_type)

	if from_grid and src_r >= 0 and src_c >= 0:
		var src_cell: GridCell = _grid_cells[src_r][src_c]
		src_cell.vacate()
		GameState.place_dead_end(current_setup_player, src_r, src_c)
	else:
		if card_type == "character":
			_chars_remaining.erase(card_name)
		else:
			_traps_remaining.erase(card_name)

	match card_type:
		"character": GameState.place_character(current_setup_player, r, c, card_name)
		"trap":      GameState.place_trap(current_setup_player, r, c, card_name)

	var tex: Texture2D = _load_card_tex(card_name, card_type)
	target_cell.occupy(card_name, card_type, tex)
	_refresh_gallery()
	_refresh_confirm()

func _on_cell_unplace(r: int, c: int) -> void:
	var cell: GridCell = _grid_cells[r][c]
	if cell.occupied_name.is_empty():
		return
	_return_to_pool(cell.occupied_name, cell.occupied_type)
	cell.vacate()
	GameState.place_dead_end(current_setup_player, r, c)
	_refresh_gallery()
	_refresh_confirm()

func _return_to_pool(card_name: String, card_type: String) -> void:
	if card_type == "character":
		_chars_remaining.append(card_name)
	else:
		_traps_remaining.append(card_name)

# ─────────────────────────────────────────────────────────────
# Random formation
# ─────────────────────────────────────────────────────────────
func _on_random_formation() -> void:
	# Return all currently placed cards back to the pool and clear the grid
	for r in range(GRID_N):
		for c in range(GRID_N):
			var cell: GridCell = _grid_cells[r][c]
			if not cell.occupied_name.is_empty():
				_return_to_pool(cell.occupied_name, cell.occupied_type)
				cell.vacate()
			GameState.place_dead_end(current_setup_player, r, c)

	# Build a shuffled list of all 25 positions
	var positions: Array = []
	for r in range(GRID_N):
		for c in range(GRID_N):
			positions.append(Vector2i(r, c))
	positions.shuffle()

	# Place all characters first, then traps, into random positions
	var pos_idx: int = 0
	for char_name in _chars_remaining.duplicate():
		var pos: Vector2i = positions[pos_idx]
		pos_idx += 1
		GameState.place_character(current_setup_player, pos.x, pos.y, char_name)
		(_grid_cells[pos.x][pos.y] as GridCell).occupy(char_name, "character", _load_card_tex(char_name, "character"))
	_chars_remaining.clear()

	for trap_name in _traps_remaining.duplicate():
		var pos: Vector2i = positions[pos_idx]
		pos_idx += 1
		GameState.place_trap(current_setup_player, pos.x, pos.y, trap_name)
		(_grid_cells[pos.x][pos.y] as GridCell).occupy(trap_name, "trap", _load_card_tex(trap_name, "trap"))
	_traps_remaining.clear()

	_refresh_gallery()
	_refresh_confirm()

# ─────────────────────────────────────────────────────────────
# Confirm + flip animation
# ─────────────────────────────────────────────────────────────
func _on_confirm() -> void:
	if not _chars_remaining.is_empty():
		_instr_lbl.text = "Place all Characters first (%d left)." % _chars_remaining.size()
		return
	if not _traps_remaining.is_empty():
		_instr_lbl.text = "Place all Traps first (%d left)." % _traps_remaining.size()
		return
	_confirm_btn.disabled = true
	_instr_lbl.text = "Locking in your formation..."
	# Disable all interaction during the animation
	_gallery_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for r in range(GRID_N):
		for c in range(GRID_N):
			(_grid_cells[r][c] as GridCell).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flip_sequence()

func _flip_sequence() -> void:
	var facedown_tex: Texture2D = load("res://assets/textures/cards/frames/facedown_frame.png")

	# Collect occupied cells row-by-row
	var occupied: Array = []
	for r in range(GRID_N):
		for c in range(GRID_N):
			var cell: GridCell = _grid_cells[r][c]
			if not cell.occupied_name.is_empty():
				occupied.append(cell)

	const STAGGER : float = 0.09
	const HALF_DUR: float = 0.13

	# Fire all flips in parallel, each delayed by its index * stagger
	for i in range(occupied.size()):
		_flip_one_cell(occupied[i], facedown_tex, float(i) * STAGGER, HALF_DUR)

	# Wait for all to finish, then signal
	var total: float = float(occupied.size()) * STAGGER + HALF_DUR * 2.0
	await get_tree().create_timer(total + 0.35).timeout
	emit_signal("setup_complete")

# Coroutine: flip a single cell face-down after an optional delay.
# Called without await so all instances run concurrently.
func _flip_one_cell(cell: GridCell, facedown_tex: Texture2D,
		delay: float, half_dur: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	# First half — squeeze X to 0 (card turning away)
	var tw1 := create_tween()
	tw1.set_ease(Tween.EASE_IN)
	tw1.set_trans(Tween.TRANS_SINE)
	tw1.tween_property(cell, "scale:x", 0.0, half_dur)
	await tw1.finished

	# Swap texture at midpoint
	if cell._card_tex != null:
		cell._card_tex.texture = facedown_tex

	# Second half — expand X back to 1 (card face-down revealed)
	var tw2 := create_tween()
	tw2.set_ease(Tween.EASE_OUT)
	tw2.set_trans(Tween.TRANS_SINE)
	tw2.tween_property(cell, "scale:x", 1.0, half_dur)

func _refresh_confirm() -> void:
	var all_placed: bool = _chars_remaining.is_empty() and _traps_remaining.is_empty()
	_confirm_btn.disabled = not all_placed
	if all_placed:
		_instr_lbl.text = "All cards placed! Press CONFIRM to begin."
	else:
		_instr_lbl.text = "Drag cards onto the grid  |  right-click a placed card to retrieve  |  %d chars  %d traps remaining" % [
			_chars_remaining.size(), _traps_remaining.size()
		]

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _card_name_to_snake(p_name: String) -> String:
	return p_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")

# ─────────────────────────────────────────────────────────────
# Bluff emoticon
# ─────────────────────────────────────────────────────────────
const BLUFF_EMOJIS: Array = ["😃","🥺","🤣","😎","❤️","☠️","🧨","👍","🤝","🖕"]
func _get_bluff_emojis() -> Array:
	if SaveManager.nsfw_enabled:
		return BLUFF_EMOJIS.map(func(e: String) -> String: return "💩" if e == "🖕" else e)
	return BLUFF_EMOJIS

func _on_cell_bluff_tap(row: int, col: int) -> void:
	_show_bluff_modal(row, col)

func _show_bluff_modal(row: int, col: int) -> void:
	# Remove any existing modal first
	var existing: Node = get_node_or_null("BluffModal")
	if existing:
		existing.queue_free()

	# Fullscreen backdrop
	var backdrop := Control.new()
	backdrop.name = "BluffModal"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.z_index = 50
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(dim)

	# Close on backdrop click
	backdrop.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			backdrop.queue_free())

	# Panel
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var psb := StyleBoxFlat.new()
	psb.bg_color     = Color(0.04, 0.07, 0.16, 0.98)
	psb.border_width_left   = 2; psb.border_width_top    = 2
	psb.border_width_right  = 2; psb.border_width_bottom = 2
	psb.border_color = Color(0.55, 0.78, 1.0, 0.7)
	psb.corner_radius_top_left     = 10; psb.corner_radius_top_right    = 10
	psb.corner_radius_bottom_right = 10; psb.corner_radius_bottom_left  = 10
	panel.add_theme_stylebox_override("panel", psb)
	backdrop.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12.0; vbox.offset_top = 10.0
	vbox.offset_right = -12.0; vbox.offset_bottom = -10.0
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Pick a Bluff"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	vbox.add_child(title)

	# Emoji row
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox)

	var snap_row: int = row
	var snap_col: int = col

	for emoji in _get_bluff_emojis():
		var btn := Button.new()
		btn.text = emoji
		btn.custom_minimum_size = Vector2(46.0, 46.0)
		btn.add_theme_font_size_override("font_size", 22)
		var esb := StyleBoxFlat.new()
		esb.bg_color = Color(0.08, 0.12, 0.28, 1.0)
		esb.corner_radius_top_left     = 6; esb.corner_radius_top_right    = 6
		esb.corner_radius_bottom_right = 6; esb.corner_radius_bottom_left  = 6
		btn.add_theme_stylebox_override("normal", esb)
		var esbh := esb.duplicate() as StyleBoxFlat
		esbh.bg_color = Color(0.15, 0.25, 0.55, 1.0)
		btn.add_theme_stylebox_override("hover", esbh)
		var snap_emoji: String = emoji
		btn.pressed.connect(func() -> void:
			GameState.set_bluff(current_setup_player, snap_row, snap_col, snap_emoji)
			(_grid_cells[snap_row][snap_col] as GridCell).set_emoticon(snap_emoji)
			backdrop.queue_free())
		hbox.add_child(btn)

	# Clear button
	var clear_btn := Button.new()
	clear_btn.text = "✕  Remove Bluff"
	clear_btn.add_theme_font_size_override("font_size", 14)
	clear_btn.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.08, 0.08, 0.16, 1.0)
	csb.corner_radius_top_left     = 6; csb.corner_radius_top_right    = 6
	csb.corner_radius_bottom_right = 6; csb.corner_radius_bottom_left  = 6
	clear_btn.add_theme_stylebox_override("normal", csb)
	clear_btn.pressed.connect(func() -> void:
		GameState.set_bluff(current_setup_player, snap_row, snap_col, "")
		(_grid_cells[snap_row][snap_col] as GridCell).set_emoticon("")
		backdrop.queue_free())
	vbox.add_child(clear_btn)

	# Size and center the panel
	panel.custom_minimum_size = Vector2(520.0, 130.0)
	await get_tree().process_frame
	var vs: Vector2 = get_viewport_rect().size
	panel.position = Vector2((vs.x - panel.size.x) * 0.5, (vs.y - panel.size.y) * 0.5)
