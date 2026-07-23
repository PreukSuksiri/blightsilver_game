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
const TUTORIAL_FORMATION_MSG := "Formation Change is unavailable in tutorial"
const SP_PORTRAIT_REF_H: float = 720.0
const SETUP_PANEL_SIDE_INSET: float = 172.0
const BOTTOM_PANEL_SIDE_INSET: float = SETUP_PANEL_SIDE_INSET
const BOTTOM_PANEL_H: float = 58.0
const BOTTOM_PANEL_BODY_GAP: float = 6.0
const FORMATION_BTN_MIN_W: float = 72.0
const FORMATION_BTN_MAX_W: float = 168.0
const ACTION_BTN_H: float = 34.0
const FORMATION_BTN_H: float = ACTION_BTN_H
const CONFIRM_BTN_H: float = 44.0
const CONFIRM_BTN_W: float = 260.0
# Setup UI text — labels stay B&W; buttons use yellow tone.
const TXT_PRIMARY := Color(0.96, 0.96, 0.96, 1.0)
const TXT_BODY := Color(0.82, 0.82, 0.82, 1.0)
const TXT_MUTED := Color(0.62, 0.62, 0.62, 1.0)
const TXT_ACCENT := Color(0.90, 0.90, 0.90, 1.0)
const TXT_BUTTON := Color(1.0, 0.88, 0.45, 1.0)
const TXT_BUTTON_HOVER := Color(1.0, 0.95, 0.70, 1.0)
const TXT_BUTTON_PRESSED := Color(0.92, 0.78, 0.35, 1.0)
const _METAL_SHEEN_SHADER: Shader = preload("res://assets/shaders/magitech_metal_reflect.gdshader")
const _SHEEN_IDLE: float = 2.0
const _SHEEN_DURATION: float = 0.55
const _SHEEN_INTERVAL_MIN: float = 3.6
const _SHEEN_INTERVAL_MAX: float = 6.8

# ─────────────────────────────────────────────────────────────
# Inner class: gallery card (drag source + tap to preview)
# ─────────────────────────────────────────────────────────────
class DraggableCard extends TextureRect:
	var card_name:    String   = ""
	var card_type:    String   = ""
	var on_hover_cb:  Callable = Callable()
	var on_detail_cb: Callable = Callable()
	var on_hold_drag_cb: Callable = Callable()
	var on_hold_hover_begin_cb: Callable = Callable()
	var on_hold_hover_exit_cb: Callable = Callable()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mbe := event as InputEventMouseButton
			if mbe.button_index == MOUSE_BUTTON_LEFT and mbe.pressed and mbe.double_click:
				if on_detail_cb.is_valid():
					on_detail_cb.call(card_name, card_type)

	func _get_drag_data(_pos: Vector2) -> Variant:
		if on_hold_drag_cb.is_valid():
			on_hold_drag_cb.call(true)
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
		if what == NOTIFICATION_MOUSE_ENTER:
			if on_hover_cb.is_valid():
				on_hover_cb.call(card_name, card_type)
			if on_hold_hover_begin_cb.is_valid():
				on_hold_hover_begin_cb.call(self, card_name, card_type)
		elif what == NOTIFICATION_MOUSE_EXIT:
			if on_hold_hover_exit_cb.is_valid():
				on_hold_hover_exit_cb.call()
		elif what == NOTIFICATION_DRAG_END and on_hold_drag_cb.is_valid():
			on_hold_drag_cb.call(false)

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
	var on_hold_drag_cb: Callable = Callable()
	var on_hold_hover_begin_cb: Callable = Callable()
	var on_hold_hover_exit_cb: Callable = Callable()
	var locked:         bool        = false  # forced placement — cannot be moved or removed
	var _card_tex:      TextureRect = null
	var _emoticon_lbl:  Label       = null
	var _flash_overlay: ColorRect   = null
	var _drag_started:  bool        = false

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
		if occupied_name.is_empty() or locked:
			return null
		if on_hold_drag_cb.is_valid():
			on_hold_drag_cb.call(true)
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
			if not occupied_name.is_empty() and on_unplace_cb.is_valid() and not locked:
				on_unplace_cb.call(grid_row, grid_col)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			if not occupied_name.is_empty():
				if on_hover_cb.is_valid():
					on_hover_cb.call(occupied_name, occupied_type)
				if on_hold_hover_begin_cb.is_valid():
					on_hold_hover_begin_cb.call(self, occupied_name, occupied_type)
		elif what == NOTIFICATION_MOUSE_EXIT:
			if on_hold_hover_exit_cb.is_valid():
				on_hold_hover_exit_cb.call()
		elif what == NOTIFICATION_DRAG_END and on_hold_drag_cb.is_valid():
			on_hold_drag_cb.call(false)

# ─────────────────────────────────────────────────────────────
# Inner class: union tile with hover-hold (no lambda capture on rebuild)
# ─────────────────────────────────────────────────────────────
class UnionHoverTile extends TextureRect:
	var union_name: String = ""
	var on_hold_hover_begin_cb: Callable = Callable()
	var on_hold_hover_exit_cb: Callable = Callable()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			if on_hold_hover_begin_cb.is_valid() and not union_name.is_empty():
				on_hold_hover_begin_cb.call(self, union_name, "union")
		elif what == NOTIFICATION_MOUSE_EXIT:
			if on_hold_hover_exit_cb.is_valid():
				on_hold_hover_exit_cb.call()

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var current_setup_player: int = 0
var _setup_working_deck: DeckData = null
var _chars_remaining: Array = []
var _traps_remaining: Array = []
var _grid_cells: Array = []          # [row][col] -> GridCell
var _grid_panel: Panel = null        # formation grid container
var _locked_cells: Array = []        # Array[Vector2i] — forced placement cells
var _tutorial_formation_overlay: Control = null
var _union_panel_node: Panel = null  # ref to the "POSSIBLE UNIONS" panel
var _formation_bar: HBoxContainer = null  # pre-defined formation buttons
var _bottom_panel: Panel = null           # formation + random + confirm chrome
var _bottom_vbox: VBoxContainer = null
var _body_hbox:     Control       = null  # body (grid + right panel)

var _player_lbl   : Label           = null
var _instr_lbl    : Label           = null
var _gallery_flow : HFlowContainer  = null
var _confirm_btn  : Button          = null
var _random_btn   : Button          = null
var _confirm_btn_pulse_tween: Tween = null
var _confirm_sheen_tween: Tween = null
var _confirm_sheen_mat: ShaderMaterial = null
const _CONFIRM_BTN_BRIGHT_REST := 1.0
const _CONFIRM_BTN_BRIGHT_PULSE := 1.28
const _BTN_FX_META := &"magitech_btn_fx_mat"
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

var _union_flow:  HBoxContainer  = null
var _flash_tween: Tween          = null
var _hover_hold_hint: CardHoverHoldHint = null
var _flash_cells: Array          = []
var _confirm_in_progress: bool = false
var _setup_complete_emitted: bool = false

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
	_setup_working_deck = null
	_confirm_in_progress = false
	_setup_complete_emitted = false
	_clear_tutorial_formation_lock()
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
	_sync_setup_button_chrome(_confirm_btn)
	_sync_setup_button_chrome(_random_btn)
	_clear_card_info()

	_reset_grid()

	var deck: DeckData = null
	if _uses_player_collection_deck():
		var active: DeckData = SaveManager.get_battle_deck()
		if active != null:
			_setup_working_deck = active.clone_for_edit()
			SaveManager.sanitize_deck_for_collection(_setup_working_deck)
			deck = _setup_working_deck
	else:
		deck = _active_setup_deck()

	if deck == null or not deck.is_valid():
		if _uses_player_collection_deck():
			_show_invalid_deck_abort_dialog()
		else:
			_instr_lbl.text = "No valid deck found. Please build a deck first."
			_confirm_btn.disabled = true
			_sync_setup_button_chrome(_confirm_btn)
		return

	_chars_remaining = deck.characters.duplicate()
	_traps_remaining = deck.traps.duplicate()
	GameState.tech_hands[player_index] = deck.techs.duplicate()
	_random_btn.visible = not _is_tutorial_setup()
	_random_btn.disabled = false
	_sync_setup_button_chrome(_random_btn)

	# Apply forced cell placements for this player
	_locked_cells.clear()
	var forced: Array = GameState.battle_player_forced_cells if player_index == 0 \
		else GameState.battle_ai_forced_cells
	_apply_forced_cells(forced)

	if not _is_tutorial_setup() and not deck.formations.is_empty():
		_apply_formation(deck.get_preferred_formation_index(), false)

	# Show/hide union panel: requires per-battle flag, plus either the global unlock
	# OR a free-play mode (VS_AI / LOCAL_2P / HOT_SEAT) where all features are open.
	var free_play_mode: bool = GameState.game_mode in [
		GameState.GameMode.VS_AI, GameState.GameMode.LOCAL_2P, GameState.GameMode.HOT_SEAT
	]
	var show_union: bool = GameState.battle_player_union_enabled and (
		SaveManager.union_mechanism_unlocked or free_play_mode
	)
	if _union_panel_node != null:
		_union_panel_node.visible = show_union

	_refresh_gallery()
	_stop_zone_flash()
	if show_union:
		_refresh_union_panel()
	_refresh_confirm()
	_refresh_formation_bar(deck)
	if _is_tutorial_setup():
		_apply_tutorial_formation_lock()

# ─────────────────────────────────────────────────────────────
# UI build
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ── Background (v3: setup-phase art; else solid + side margins) ──
	var setup_bg_tex: Texture2D = HudSkin.setup_phase_bg_tex()
	if setup_bg_tex != null:
		# Black underlay so letterbox/gap never shows through.
		var underlay := ColorRect.new()
		underlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		underlay.color = Color(0.0, 0.0, 0.0, 1.0)
		underlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(underlay)
		var bg := TextureRect.new()
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.texture = setup_bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Cropped plate → stretch edge-to-edge (may distort slightly).
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	else:
		var bg := ColorRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.offset_left  =  160.0
		bg.offset_right = -160.0
		bg.color = Color(0.04, 0.05, 0.12, 1.0)
		add_child(bg)
		var lm := ColorRect.new()
		lm.anchor_left    = 0.0;  lm.anchor_top    = 0.0
		lm.anchor_right   = 0.0;  lm.anchor_bottom = 1.0
		lm.offset_left    = 0.0;  lm.offset_top    = 0.0
		lm.offset_right   = 160.0; lm.offset_bottom = 0.0
		lm.color          = Color(0.0, 0.0, 0.0, 1.0)
		add_child(lm)
		var rm := ColorRect.new()
		rm.anchor_left    = 1.0;  rm.anchor_top    = 0.0
		rm.anchor_right   = 1.0;  rm.anchor_bottom = 1.0
		rm.offset_left    = -160.0; rm.offset_top  = 0.0
		rm.offset_right   = 0.0;  rm.offset_bottom = 0.0
		rm.color          = Color(0.0, 0.0, 0.0, 1.0)
		add_child(rm)

	# ── Header bar ──────────────────────────────────────────
	var header := Panel.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left   =  SETUP_PANEL_SIDE_INSET
	header.offset_right  = -SETUP_PANEL_SIDE_INSET
	header.offset_bottom = 72.0
	_skin_setup_panel(header, 0.0, false)
	add_child(header)

	_player_lbl = Label.new()
	_player_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_player_lbl.offset_top    = 8.0
	_player_lbl.offset_bottom = 42.0
	_player_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_lbl.add_theme_font_size_override("font_size", 24)
	_player_lbl.add_theme_color_override("font_color", TXT_PRIMARY)
	header.add_child(_player_lbl)

	_instr_lbl = Label.new()
	_instr_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_instr_lbl.offset_top    = 44.0
	_instr_lbl.offset_bottom = 70.0
	_instr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instr_lbl.add_theme_font_size_override("font_size", 13)
	_instr_lbl.add_theme_color_override("font_color", TXT_BODY)
	header.add_child(_instr_lbl)

	# ── Body (grid + right panel side by side) ──────────────
	var body := HBoxContainer.new()
	_body_hbox = body
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_top    = 76.0
	body.offset_bottom = -(BOTTOM_PANEL_H + BOTTOM_PANEL_BODY_GAP)
	body.offset_left   = SETUP_PANEL_SIDE_INSET
	body.offset_right  = -SETUP_PANEL_SIDE_INSET
	body.add_theme_constant_override("separation", 14)
	add_child(body)

	_build_grid_panel(body)
	_build_right_panel(body)
	_build_bottom_panel()

	# ── Player portrait illustrations (on top of all content) ─
	var _sp_p1_tex: Texture2D = GameState.load_portrait_texture(GameState.player_portraits[0])
	if _sp_p1_tex:
		var _sz := _sp_p1_tex.get_size()
		var _pw: float = SP_PORTRAIT_REF_H * _sz.x / _sz.y if _sz.y > 0.0 else 220.0
		var _p1p := TextureRect.new()
		_p1p.texture       = _sp_p1_tex
		_p1p.anchor_left   = 0.0;  _p1p.anchor_top    = 1.0
		_p1p.anchor_right  = 0.0;  _p1p.anchor_bottom = 1.0
		_p1p.offset_left   = -_pw * 0.4; _p1p.offset_top    = -SP_PORTRAIT_REF_H
		_p1p.offset_right  =  _pw * 0.6; _p1p.offset_bottom = 0.0
		_p1p.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		_p1p.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
		_p1p.flip_h        = true
		_p1p.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		_p1p.z_index       = 3
		add_child(_p1p)
		_sp_p1_portrait = _p1p

	var _sp_p2_tex: Texture2D = GameState.load_portrait_texture(GameState.player_portraits[1])
	if _sp_p2_tex:
		var _sz := _sp_p2_tex.get_size()
		var _pw: float = SP_PORTRAIT_REF_H * _sz.x / _sz.y if _sz.y > 0.0 else 220.0
		var _p2p := TextureRect.new()
		_p2p.texture       = _sp_p2_tex
		_p2p.anchor_left   = 1.0;  _p2p.anchor_top    = 1.0
		_p2p.anchor_right  = 1.0;  _p2p.anchor_bottom = 1.0
		_p2p.offset_left   = -_pw * 0.6; _p2p.offset_top    = -SP_PORTRAIT_REF_H
		_p2p.offset_right  =  _pw * 0.4; _p2p.offset_bottom = 0.0
		_p2p.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		_p2p.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
		_p2p.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		_p2p.z_index       = 3
		add_child(_p2p)
		_sp_p2_portrait = _p2p

	_hover_hold_hint = CardHoverHoldHint.new()
	add_child(_hover_hold_hint)

func _bind_hover_hold_drag(paused: bool) -> void:
	if _hover_hold_hint != null:
		_hover_hold_hint.set_pause(&"drag", paused)

func _on_hold_hover_begin(control: Control, card_name: String, card_type: String) -> void:
	if _hover_hold_hint != null:
		_hover_hold_hint.begin(self, control, card_name, card_type)

func _on_hold_hover_exit() -> void:
	if _hover_hold_hint != null:
		_hover_hold_hint.on_hover_exited()

## Yellow magitech chrome for all setup actions.
func _skin_setup_button(btn: Button, wire_sfx: bool = true) -> void:
	if btn == null:
		return
	btn.add_theme_color_override("font_color", TXT_BUTTON)
	btn.add_theme_color_override("font_hover_color", TXT_BUTTON_HOVER)
	btn.add_theme_color_override("font_pressed_color", TXT_BUTTON_PRESSED)
	GameDialog.apply_button_chrome(btn, wire_sfx)
	_apply_yellow_button_fx(btn)


func _apply_yellow_button_fx(btn: Button) -> void:
	if btn == null or not btn.has_meta(_BTN_FX_META):
		return
	var mat: ShaderMaterial = btn.get_meta(_BTN_FX_META) as ShaderMaterial
	if mat == null:
		return
	if btn.disabled:
		mat.set_shader_parameter("fill_top", Color(0.14, 0.10, 0.04, 0.85))
		mat.set_shader_parameter("fill_bottom", Color(0.08, 0.06, 0.02, 0.85))
		mat.set_shader_parameter("border_a", Color(0.55, 0.42, 0.18, 0.45))
		mat.set_shader_parameter("border_b", Color(0.60, 0.48, 0.22, 0.40))
		mat.set_shader_parameter("brightness", 0.75)
	else:
		mat.set_shader_parameter("fill_top", Color(0.34, 0.24, 0.06, 0.97))
		mat.set_shader_parameter("fill_bottom", Color(0.18, 0.12, 0.03, 0.97))
		mat.set_shader_parameter("border_a", Color(1.0, 0.84, 0.28, 0.92))
		mat.set_shader_parameter("border_b", Color(0.95, 0.72, 0.28, 0.74))
		mat.set_shader_parameter("brightness", 1.0)


func _sync_setup_button_chrome(btn: Button) -> void:
	GameDialog.sync_button_chrome_disabled(btn)
	_apply_yellow_button_fx(btn)


## Black fill + white/grey frame. Circuit patrol only when enable_patrol.
func _skin_setup_panel(panel: Panel, content_margin: float = 12.0, enable_patrol: bool = false) -> void:
	if panel == null:
		return
	var sb := GameDialog.make_panel_stylebox(content_margin)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	GameDialog.attach_panel_fx(panel)
	var mat: ShaderMaterial = panel.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("fill_top", Color(0.0, 0.0, 0.0, 1.0))
	mat.set_shader_parameter("fill_bottom", Color(0.0, 0.0, 0.0, 1.0))
	mat.set_shader_parameter("border_a", Color(0.96, 0.96, 0.98, 0.92))
	mat.set_shader_parameter("border_b", Color(0.52, 0.54, 0.58, 0.70))
	mat.set_shader_parameter("border_px", 2.5 if enable_patrol else 2.0)
	mat.set_shader_parameter("rim_speed", 0.40 if enable_patrol else 0.0)
	mat.set_shader_parameter("rim_pulse", 0.68 if enable_patrol else 0.0)
	mat.set_shader_parameter("circuit_patrol", 1.0 if enable_patrol else 0.0)


## Bottom chrome: Random | formation chips | Confirm (hero).
func _build_bottom_panel() -> void:
	_bottom_panel = Panel.new()
	_bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_panel.offset_left = BOTTOM_PANEL_SIDE_INSET
	_bottom_panel.offset_right = -BOTTOM_PANEL_SIDE_INSET
	_bottom_panel.offset_top = -BOTTOM_PANEL_H
	_bottom_panel.offset_bottom = 0.0
	_skin_setup_panel(_bottom_panel, 0.0, false)
	add_child(_bottom_panel)

	_bottom_vbox = VBoxContainer.new()
	_bottom_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bottom_vbox.offset_left = 8.0
	_bottom_vbox.offset_right = -8.0
	_bottom_vbox.offset_top = 6.0
	_bottom_vbox.offset_bottom = -6.0
	_bottom_vbox.add_theme_constant_override("separation", 0)
	_bottom_panel.add_child(_bottom_vbox)

	var action_row := HBoxContainer.new()
	action_row.custom_minimum_size = Vector2(0.0, CONFIRM_BTN_H)
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_row.add_theme_constant_override("separation", 8)
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_bottom_vbox.add_child(action_row)

	_random_btn = Button.new()
	_random_btn.text = "RANDOM"
	_random_btn.custom_minimum_size = Vector2(120.0, ACTION_BTN_H)
	_random_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_random_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_random_btn.add_theme_font_size_override("font_size", 14)
	_random_btn.disabled = true
	_skin_setup_button(_random_btn)
	_random_btn.pressed.connect(_on_random_formation)
	action_row.add_child(_random_btn)

	_formation_bar = HBoxContainer.new()
	_formation_bar.custom_minimum_size = Vector2(0.0, FORMATION_BTN_H)
	_formation_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_formation_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_formation_bar.add_theme_constant_override("separation", 4)
	_formation_bar.visible = false
	action_row.add_child(_formation_bar)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_row.add_child(spacer)

	_confirm_btn = Button.new()
	_confirm_btn.text = "CONFIRM PLACEMENT"
	_confirm_btn.custom_minimum_size = Vector2(CONFIRM_BTN_W, CONFIRM_BTN_H)
	_confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_confirm_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_confirm_btn.add_theme_font_size_override("font_size", 18)
	_confirm_btn.disabled = true
	_skin_setup_button(_confirm_btn)
	_confirm_btn.pressed.connect(_on_confirm)
	action_row.add_child(_confirm_btn)
	_wire_confirm_metal_sheen()

	_sync_bottom_panel_layout(false)


func _sync_bottom_panel_layout(_show_formations: bool = false) -> void:
	if _bottom_panel != null:
		_bottom_panel.offset_top = -BOTTOM_PANEL_H
	if _body_hbox != null:
		_body_hbox.offset_bottom = -(BOTTOM_PANEL_H + BOTTOM_PANEL_BODY_GAP)
	if _bottom_vbox != null:
		# Keep Random flush to the left of the bottom panel.
		_bottom_vbox.offset_left = 8.0
		_bottom_vbox.offset_right = -8.0


func _make_grid_cell_style() -> StyleBoxFlat:
	var cell_sb := StyleBoxFlat.new()
	cell_sb.bg_color = Color(0.0, 0.0, 0.0, 1.0)
	cell_sb.border_color = Color(0.92, 0.92, 0.94, 0.70)
	cell_sb.set_border_width_all(MagitechTheme.BORDER_WIDTH_THIN)
	cell_sb.set_corner_radius_all(4)
	return cell_sb


func _build_grid_panel(parent: Control) -> void:
	var grid_w: float = CELL_W * GRID_N + float(CELL_GAP) * (GRID_N - 1) + 24.0
	var grid_h: float = CELL_H * GRID_N + float(CELL_GAP) * (GRID_N - 1) + 24.0

	var grid_panel := Panel.new()
	_grid_panel = grid_panel
	grid_panel.custom_minimum_size = Vector2(grid_w, grid_h)
	# Modest horizontal grow — leave most leftover width for the right column.
	grid_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_panel.size_flags_stretch_ratio = 0.72
	_skin_setup_panel(grid_panel, 12.0, true)
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
			cell.add_theme_stylebox_override("panel", _make_grid_cell_style())
			var flash_cr := ColorRect.new()
			flash_cr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			flash_cr.color        = Color(0.25, 0.90, 1.00, 0.0)
			flash_cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			flash_cr.z_index      = 5
			cell._flash_overlay   = flash_cr
			cell.add_child(flash_cr)
			cell.on_hold_drag_cb = Callable(self, "_bind_hover_hold_drag")
			cell.on_hold_hover_begin_cb = Callable(self, "_on_hold_hover_begin")
			cell.on_hold_hover_exit_cb = Callable(self, "_on_hold_hover_exit")
			grid_cont.add_child(cell)
			row_arr.append(cell)
		_grid_cells.append(row_arr)

# Right panel = VBox: gallery scroll (top, expands) + card info strip (bottom, fixed)
func _build_right_panel(parent: Control) -> void:
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_stretch_ratio = 1.45
	right_vbox.custom_minimum_size = Vector2(520.0, 0.0)
	right_vbox.add_theme_constant_override("separation", 8)
	parent.add_child(right_vbox)

	_build_gallery_panel(right_vbox)
	_build_union_panel(right_vbox)
	_build_info_panel(right_vbox)

func _build_gallery_panel(parent: Control) -> void:
	# Fixed height for exactly 2 rows: 2×(card+label) + 1 gap + header + padding
	const TWO_ROW_H: float = (GAL_H + 22.0) * 2.0 + GAL_GAP + 38.0
	var gal_panel := Panel.new()
	gal_panel.custom_minimum_size   = Vector2(0.0, TWO_ROW_H)
	gal_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skin_setup_panel(gal_panel, 8.0, false)
	parent.add_child(gal_panel)

	var gal_lbl := Label.new()
	gal_lbl.text = "YOUR DECK  —  drag onto grid  |  right-click placed card to retrieve"
	gal_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	gal_lbl.offset_top    = 6.0
	gal_lbl.offset_bottom = 28.0
	gal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gal_lbl.add_theme_font_size_override("font_size", 12)
	gal_lbl.add_theme_color_override("font_color", TXT_MUTED)
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

func _build_union_panel(parent: Control) -> void:
	const ONE_ROW_H: float = (GAL_H + 22.0) + GAL_GAP + 38.0
	var panel := Panel.new()
	_union_panel_node = panel
	panel.custom_minimum_size   = Vector2(0.0, ONE_ROW_H)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skin_setup_panel(panel, 8.0, false)
	parent.add_child(panel)

	var hdr := Label.new()
	hdr.text = "POSSIBLE UNIONS  —  tap to highlight zone, hold for card info"
	hdr.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hdr.offset_top    = 6.0
	hdr.offset_bottom = 28.0
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 12)
	hdr.add_theme_color_override("font_color", TXT_ACCENT)
	panel.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = 30.0
	scroll.offset_left   = 8.0
	scroll.offset_right  = -8.0
	scroll.offset_bottom = -8.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	_union_flow = HBoxContainer.new()
	_union_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_union_flow.add_theme_constant_override("separation", GAL_GAP)
	scroll.add_child(_union_flow)

func _build_info_panel(parent: Control) -> void:
	var info_panel := Panel.new()
	info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_skin_setup_panel(info_panel, 8.0, false)
	info_panel.clip_contents = true
	parent.add_child(info_panel)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left   = 10.0
	row.offset_right  = -10.0
	row.offset_top    = 8.0
	row.offset_bottom = -16.0
	row.add_theme_constant_override("separation", 12)
	info_panel.add_child(row)

	# Left: card thumbnail — fills available height, never overflows panel
	_info_img = TextureRect.new()
	_info_img.custom_minimum_size = Vector2(100.0, 0.0)
	_info_img.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	_info_img.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT
	_info_img.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_info_img)

	# Right: text
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 6)
	row.add_child(text_col)

	_info_name = Label.new()
	_info_name.add_theme_font_size_override("font_size", 22)
	_info_name.add_theme_color_override("font_color", TXT_PRIMARY)
	text_col.add_child(_info_name)

	_info_stats = Label.new()
	_info_stats.add_theme_font_size_override("font_size", 16)
	_info_stats.add_theme_color_override("font_color", TXT_ACCENT)
	text_col.add_child(_info_stats)

	_info_desc = Label.new()
	_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_desc.add_theme_font_size_override("font_size", 14)
	_info_desc.add_theme_color_override("font_color", TXT_BODY)
	text_col.add_child(_info_desc)

	_info_preview_btn = Button.new()
	_info_preview_btn.text = "VIEW FULL CARD"
	_info_preview_btn.visible = false
	_info_preview_btn.disabled = true
	_info_preview_btn.add_theme_font_size_override("font_size", 14)
	_skin_setup_button(_info_preview_btn)
	_info_preview_btn.pressed.connect(_on_preview_btn)
	text_col.add_child(_info_preview_btn)

# ─────────────────────────────────────────────────────────────
# Card info display
# ─────────────────────────────────────────────────────────────
func _on_preview_btn() -> void:
	if _info_card_name != "":
		CardDetailOverlay.open(self, _info_card_name, _info_card_type)

func _clear_card_info() -> void:
	_info_card_name = ""
	_info_card_type = ""
	if _info_img != null:
		_info_img.texture = null
	if _info_name != null:
		_info_name.text = ""
	if _info_stats != null:
		_info_stats.text = ""
	if _info_desc != null:
		_info_desc.text = ""
	if _info_preview_btn != null:
		_info_preview_btn.visible = false
		_info_preview_btn.disabled = true
		_sync_setup_button_chrome(_info_preview_btn)

func _open_card_detail(card_name: String, card_type: String) -> void:
	CardDetailOverlay.open(self, card_name, card_type)

func _show_card_info(card_name: String, card_type: String) -> void:
	_info_card_name = card_name
	_info_card_type = card_type
	_info_preview_btn.visible = true
	_info_preview_btn.disabled = false
	_sync_setup_button_chrome(_info_preview_btn)

	var subfolder: String
	match card_type:
		"character": subfolder = "characters"
		"trap":      subfolder = "traps"
		"tech":      subfolder = "tech"
		"union":     subfolder = "union"
		_:           subfolder = "characters"
	var art_path: String = CardDatabase.find_artwork(card_name, subfolder)
	if art_path != "":
		_info_img.texture = load(art_path) as Texture2D
	else:
		_info_img.texture = _load_card_tex(card_name, card_type)

	match card_type:
		"character":
			_info_name.add_theme_color_override("font_color", TXT_PRIMARY)
			_info_stats.add_theme_color_override("font_color", TXT_ACCENT)
			var data: Variant = CardDatabase.get_character(card_name)
			_info_name.text = (data as CharacterData).display_name \
				if data != null and not (data as CharacterData).display_name.is_empty() \
				else card_name
			if data != null:
				var cd := data as CharacterData
				_info_stats.text = "[%s]  ATK %d  DEF %d  %d◆" % [
					cd.get_affinity_name(), cd.base_atk, cd.base_def, cd.crystal_cost]
				_info_desc.text = cd.ability_description
			else:
				_info_stats.text = "Unit"
				_info_desc.text  = ""
		"trap":
			_info_name.add_theme_color_override("font_color", TXT_PRIMARY)
			_info_stats.add_theme_color_override("font_color", TXT_ACCENT)
			var data: Variant = CardDatabase.get_trap(card_name)
			_info_name.text = (data as TrapData).display_name \
				if data != null and not (data as TrapData).display_name.is_empty() \
				else card_name
			if data != null:
				var td := data as TrapData
				_info_stats.text = "Trap  %d◆" % td.crystal_cost
				_info_desc.text  = td.effect_description
			else:
				_info_stats.text = "Trap"
				_info_desc.text  = ""
		"tech":
			_info_name.add_theme_color_override("font_color", TXT_PRIMARY)
			_info_stats.add_theme_color_override("font_color", TXT_ACCENT)
			var data: Variant = CardDatabase.get_tech(card_name)
			_info_name.text = (data as TechCardData).display_name \
				if data != null and not (data as TechCardData).display_name.is_empty() \
				else card_name
			if data != null:
				var tc := data as TechCardData
				_info_stats.text = "Tech  %d◆" % tc.crystal_cost
				_info_desc.text  = tc.get_effect_description()
			else:
				_info_stats.text = "Tech"
				_info_desc.text  = ""
		"union":
			_info_name.add_theme_color_override("font_color", TXT_PRIMARY)
			_info_stats.add_theme_color_override("font_color", TXT_ACCENT)
			var u: UnionData = UnionDatabase.get_union(card_name)
			_info_name.text = u.display_name \
				if u != null and not u.display_name.is_empty() \
				else card_name
			if u != null:
				var aff_keys: Array = CharacterData.Affinity.keys()
				var aff_name: String = aff_keys[int(u.affinity)].capitalize() \
					if int(u.affinity) < aff_keys.size() else ""
				_info_stats.text = "[%s]  ATK %d  DEF %d  %d◆" % [
					aff_name, u.base_atk, u.base_def, u.summon_cost]
				_info_desc.text = u.formula_description + "\n" + u.ability_description
			else:
				_info_stats.text = "Union"
				_info_desc.text  = ""

# ─────────────────────────────────────────────────────────────
# Grid management
# ─────────────────────────────────────────────────────────────
func _reset_grid() -> void:
	for r in range(GRID_N):
		for c in range(GRID_N):
			var cell: GridCell = _grid_cells[r][c]
			cell.vacate()
			cell.locked = false
			cell.modulate = Color(1.0, 1.0, 1.0, 1.0)
			cell.set_emoticon("")
			GameState.place_dead_end(current_setup_player, r, c)

func _load_card_tex(card_name: String, card_type: String = "") -> Texture2D:
	var snake: String = _card_name_to_snake(card_name)
	var path: String = FULL_CARDS_DIR + snake + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

# ─────────────────────────────────────────────────────────────
# Gallery
# ─────────────────────────────────────────────────────────────
func _refresh_gallery() -> void:
	if _hover_hold_hint != null:
		_hover_hold_hint.end()
	for ch in _gallery_flow.get_children():
		ch.queue_free()
	for card_name: String in _chars_remaining:
		_add_gallery_card(card_name, "character")
	for card_name: String in _traps_remaining:
		_add_gallery_card(card_name, "trap")

# ─────────────────────────────────────────────────────────────
# Union panel
# ─────────────────────────────────────────────────────────────
func _refresh_union_panel() -> void:
	if _hover_hold_hint != null:
		_hover_hold_hint.end()
	for ch in _union_flow.get_children():
		ch.queue_free()
	var deck: DeckData = _active_setup_deck()
	if deck == null:
		return
	for u: UnionData in _find_possible_unions(deck.characters):
		_union_flow.add_child(_make_union_tile(u))

func _find_possible_unions(char_names: Array) -> Array:
	var result: Array = []
	for u: UnionData in UnionDatabase.get_all_unions():
		if not UnionDatabase.is_playable_in_demo(u):
			continue
		if SaveManager.is_union_unlocked(u.card_name) and UnionDatabase.deck_can_form_union(char_names, u):
			result.append(u)
	return result


func _make_union_tile(u: UnionData) -> Control:
	var wrap := VBoxContainer.new()
	wrap.custom_minimum_size = Vector2(GAL_W, GAL_H + 22.0)
	wrap.add_theme_constant_override("separation", 2)

	var img := UnionHoverTile.new()
	img.union_name            = u.card_name
	img.on_hold_hover_begin_cb = Callable(self, "_on_hold_hover_begin")
	img.on_hold_hover_exit_cb  = Callable(self, "_on_hold_hover_exit")
	img.custom_minimum_size   = Vector2(GAL_W, GAL_H)
	img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	img.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tex: Texture2D = _load_card_tex(u.card_name, "union")
	if tex != null:
		img.texture = tex
	else:
		img.modulate = Color(0.25, 0.90, 1.00)
	var captured_u: UnionData = u
	img.mouse_filter = Control.MOUSE_FILTER_STOP
	var want_detail_ref: Array = [false]
	img.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mbe := ev as InputEventMouseButton
			if mbe.button_index == MOUSE_BUTTON_LEFT:
				if mbe.pressed:
					if mbe.double_click:
						want_detail_ref[0] = false
						CardDetailOverlay.open(self, captured_u.card_name, "union")
					else:
						want_detail_ref[0] = true
						img.get_tree().create_timer(0.5).timeout.connect(func() -> void:
							if want_detail_ref[0]:
								want_detail_ref[0] = false
								CardDetailOverlay.open(self, captured_u.card_name, "union"))
				else:
					if want_detail_ref[0]:
						want_detail_ref[0] = false
						_start_zone_flash(captured_u))
	wrap.add_child(img)

	var lbl := Label.new()
	lbl.text                 = u.card_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", TXT_ACCENT)
	wrap.add_child(lbl)
	return wrap

func _start_zone_flash(u: UnionData) -> void:
	_stop_zone_flash()
	if _hover_hold_hint != null:
		_hover_hold_hint.set_pause(&"union_flash", true)
	_show_card_info(u.card_name, "union")

	_flash_cells = []
	for zv: Vector2i in u.union_zone:
		if zv.x >= 0 and zv.x < GRID_N and zv.y >= 0 and zv.y < GRID_N:
			_flash_cells.append(_grid_cells[zv.x][zv.y] as GridCell)

	if _flash_cells.is_empty():
		if _hover_hold_hint != null:
			_hover_hold_hint.set_pause(&"union_flash", false)
		return

	# 3 blink cycles (fade in + fade out), then auto-stop
	_flash_tween = create_tween().set_loops(3)
	var first: bool = true
	for cell: GridCell in _flash_cells:
		if first:
			_flash_tween.tween_property(cell._flash_overlay, "color:a", 0.45, 0.30)
			first = false
		else:
			_flash_tween.parallel().tween_property(cell._flash_overlay, "color:a", 0.45, 0.30)
	first = true
	for cell: GridCell in _flash_cells:
		if first:
			_flash_tween.tween_property(cell._flash_overlay, "color:a", 0.0, 0.30)
			first = false
		else:
			_flash_tween.parallel().tween_property(cell._flash_overlay, "color:a", 0.0, 0.30)
	_flash_tween.finished.connect(_stop_zone_flash)

func _stop_zone_flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = null
	for cell: GridCell in _flash_cells:
		if cell._flash_overlay != null:
			cell._flash_overlay.color.a = 0.0
	_flash_cells.clear()
	if _hover_hold_hint != null:
		_hover_hold_hint.set_pause(&"union_flash", false)

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
	dc.on_hold_drag_cb       = Callable(self, "_bind_hover_hold_drag")
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
	lbl.add_theme_color_override("font_color", TXT_BODY)
	wrap.add_child(lbl)

# ─────────────────────────────────────────────────────────────
# Drop / unplace handlers
# ─────────────────────────────────────────────────────────────
func _on_card_dropped(r: int, c: int, data: Dictionary) -> void:
	if _is_tutorial_setup():
		return
	var card_name: String = str(data["card_name"])
	var card_type: String = str(data["card_type"])
	var from_grid: bool   = bool(data.get("from_grid", false))
	var src_r: int        = int(data.get("grid_row", -1))
	var src_c: int        = int(data.get("grid_col", -1))

	if from_grid and src_r == r and src_c == c:
		return

	var target_cell: GridCell = _grid_cells[r][c]
	# Cannot drop onto a locked (forced) cell
	if target_cell.locked:
		return
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
	SFXManager.play(SFXManager.SFX_PLACE)
	_refresh_gallery()
	_refresh_confirm()

func _on_cell_unplace(r: int, c: int) -> void:
	if _is_tutorial_setup():
		return
	var cell: GridCell = _grid_cells[r][c]
	if cell.occupied_name.is_empty() or cell.locked:
		return
	SFXManager.play(SFXManager.SFX_REMOVE)
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

func _apply_forced_cells(forced_cells: Array) -> void:
	for fc_v: Variant in forced_cells:
		if not (fc_v is Dictionary):
			continue
		var fc: Dictionary = fc_v as Dictionary
		var card_name: String = str(fc.get("card_name", ""))
		var row: int = int(fc.get("row", 0))
		var col: int = int(fc.get("col", 0))
		if card_name.is_empty():
			continue
		# Determine card type
		var card_type: String = ""
		if _chars_remaining.has(card_name):
			card_type = "character"
		elif _traps_remaining.has(card_name):
			card_type = "trap"
		else:
			continue  # card not in this player's deck — skip
		# Skip if cell already locked or occupied
		var target_pos := Vector2i(row, col)
		if _locked_cells.has(target_pos):
			continue
		var cell: GridCell = _grid_cells[row][col]
		if not cell.occupied_name.is_empty():
			continue  # cell already occupied — skip
		# Place the card
		if card_type == "character":
			_chars_remaining.erase(card_name)
			GameState.place_character(current_setup_player, row, col, card_name)
		else:
			_traps_remaining.erase(card_name)
			GameState.place_trap(current_setup_player, row, col, card_name)
		cell.occupy(card_name, card_type, _load_card_tex(card_name, card_type))
		cell.locked = true
		_locked_cells.append(target_pos)
		# Optional: start card face-up or with pre-applied flags (E2E setup support)
		var card_inst: GameState.CardInstance = GameState.get_card(current_setup_player, row, col)
		if fc.get("face_up", false):
			card_inst.face_up = true
		var init_flags: Array = fc.get("flags", [])
		for flag_v: Variant in init_flags:
			var flag_s: String = str(flag_v)
			if flag_s != "" and flag_s not in card_inst.flags:
				card_inst.flags.append(flag_s)

# ─────────────────────────────────────────────────────────────
# Formation selector
# ─────────────────────────────────────────────────────────────
func _active_setup_deck() -> DeckData:
	if GameState.game_mode == GameState.GameMode.VS_AI and current_setup_player == 1 \
			and GameState.battle_ai_deck != null:
		return GameState.battle_ai_deck as DeckData
	if GameState.game_mode == GameState.GameMode.VS_AI and current_setup_player == 0 \
			and GameState.battle_player_deck != null:
		return GameState.battle_player_deck as DeckData
	if _setup_working_deck != null:
		return _setup_working_deck
	return SaveManager.get_battle_deck()

func _uses_player_collection_deck() -> bool:
	if GameState.game_mode == GameState.GameMode.VS_AI and current_setup_player == 1 \
			and GameState.battle_ai_deck != null:
		return false
	if GameState.game_mode == GameState.GameMode.VS_AI and current_setup_player == 0 \
			and GameState.battle_player_deck != null:
		return false
	return true

func _show_invalid_deck_abort_dialog() -> void:
	if GameDialog.has_open_overlay(self):
		return
	_instr_lbl.text = "No valid deck found. Please build a deck first."
	_confirm_btn.disabled = true
	_sync_setup_button_chrome(_confirm_btn)
	var body: String = (
		"Some cards in this deck are not in your collection, "
		+ "and the deck no longer meets requirements.\n\n"
		+ SaveManager.get_active_deck_warning_message())
	GameDialog.accept_overlay(
		self,
		"Deck Not Ready",
		body,
		"OK",
		func() -> void:
			MainMenuReturnLoader.go_to_scene(SaveManager.get_setup_abort_return_scene()))

func _refresh_formation_bar(deck: DeckData) -> void:
	if _formation_bar == null:
		return
	if _is_tutorial_setup():
		_formation_bar.visible = false
		_sync_bottom_panel_layout(false)
		return
	for child in _formation_bar.get_children():
		child.queue_free()

	var formations: Array = deck.formations if deck != null else []
	_formation_bar.visible = not formations.is_empty()
	_sync_bottom_panel_layout(_formation_bar.visible)
	if not _formation_bar.visible:
		return

	var lbl := Label.new()
	lbl.text = "Form:"
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", TXT_MUTED)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_formation_bar.add_child(lbl)

	for i in range(formations.size()):
		var fd: Dictionary = formations[i] as Dictionary
		var btn := Button.new()
		var raw_name: String = str(fd.get("name", "F%d" % (i + 1))).strip_edges()
		btn.text = raw_name
		btn.tooltip_text = raw_name
		btn.add_theme_font_size_override("font_size", 12)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.clip_text = true
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_skin_setup_button(btn)
		var font: Font = btn.get_theme_font("font")
		var text_w: float = 96.0
		if font != null:
			text_w = font.get_string_size(
				raw_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12).x
		btn.custom_minimum_size = Vector2(
			clampf(text_w + 36.0, FORMATION_BTN_MIN_W, FORMATION_BTN_MAX_W),
			FORMATION_BTN_H)
		var idx := i
		btn.pressed.connect(func() -> void: _apply_formation(idx))
		_formation_bar.add_child(btn)

func _apply_formation(idx: int, play_sfx: bool = true) -> void:
	if _is_tutorial_setup():
		return
	var deck: DeckData = _active_setup_deck()
	if deck == null or idx < 0 or idx >= deck.formations.size():
		return
	var fd: Dictionary = deck.formations[idx] as Dictionary
	var pls: Variant = fd.get("placements", [])
	if not pls is Array:
		return

	# Clear non-locked cells and return their cards to the pool
	for r in range(GRID_N):
		for c in range(GRID_N):
			var cell: GridCell = _grid_cells[r][c] as GridCell
			if cell.locked or cell.occupied_name.is_empty():
				continue
			_return_to_pool(cell.occupied_name, cell.occupied_type)
			cell.vacate()
			GameState.place_dead_end(current_setup_player, r, c)

	# Apply formation placements — only if the card is available in the remaining pool
	for pl: Variant in (pls as Array):
		if not pl is Dictionary: continue
		var p: Dictionary = pl as Dictionary
		var r: int = int(p.get("r", -1))
		var c: int = int(p.get("c", -1))
		var card_name: String = str(p.get("name", ""))
		var card_type: String = str(p.get("type", "character"))
		if r < 0 or r > 4 or c < 0 or c > 4 or card_name.is_empty():
			continue
		var target_cell: GridCell = _grid_cells[r][c] as GridCell
		if target_cell.locked or not target_cell.occupied_name.is_empty():
			continue
		var pool: Array = _chars_remaining if card_type == "character" else _traps_remaining
		var pool_idx: int = pool.find(card_name)
		if pool_idx < 0:
			continue  # card not available
		pool.remove_at(pool_idx)
		match card_type:
			"character": GameState.place_character(current_setup_player, r, c, card_name)
			"trap":      GameState.place_trap(current_setup_player, r, c, card_name)
		var tex: Texture2D = _load_card_tex(card_name, card_type)
		target_cell.occupy(card_name, card_type, tex)

	if play_sfx:
		SFXManager.play(SFXManager.SFX_PLACE)
	_refresh_gallery()
	_refresh_confirm()

# ─────────────────────────────────────────────────────────────
# Random formation
# ─────────────────────────────────────────────────────────────
func _on_random_formation() -> void:
	if _is_tutorial_setup():
		return
	# Return all non-locked placed cards back to the pool and clear non-locked cells
	for r in range(GRID_N):
		for c in range(GRID_N):
			var cell: GridCell = _grid_cells[r][c]
			if cell.locked:
				continue  # forced card stays
			if not cell.occupied_name.is_empty():
				_return_to_pool(cell.occupied_name, cell.occupied_type)
				cell.vacate()
			GameState.place_dead_end(current_setup_player, r, c)

	# Build a shuffled list of non-locked positions
	var positions: Array = []
	for r in range(GRID_N):
		for c in range(GRID_N):
			if not (_grid_cells[r][c] as GridCell).locked:
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
	if _confirm_in_progress:
		return
	if not _chars_remaining.is_empty():
		_instr_lbl.text = "Place all Units first (%d left)." % _chars_remaining.size()
		return
	if not _traps_remaining.is_empty():
		_instr_lbl.text = "Place all Traps first (%d left)." % _traps_remaining.size()
		return
	_confirm_in_progress = true
	_setup_complete_emitted = false
	_lock_confirm_ui()
	_stop_tutorial_confirm_pulse()
	_instr_lbl.text = "Locking in your formation..."
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

	# Wait for all to finish, then signal once.
	var total: float = float(occupied.size()) * STAGGER + HALF_DUR * 2.0
	await get_tree().create_timer(total + 0.35).timeout
	if _setup_complete_emitted:
		return
	_setup_complete_emitted = true
	emit_signal("setup_complete")

# Coroutine: flip a single cell face-down after an optional delay.
# Called without await so all instances run concurrently.
func _flip_one_cell(cell: GridCell, facedown_tex: Texture2D,
		delay: float, half_dur: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	SFXManager.play_flip()
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
	if _confirm_in_progress:
		_lock_confirm_ui()
		return
	var all_placed: bool = _chars_remaining.is_empty() and _traps_remaining.is_empty()
	_confirm_btn.disabled = not all_placed
	_sync_setup_button_chrome(_confirm_btn)
	if _is_tutorial_setup():
		_start_tutorial_confirm_pulse()
		if all_placed:
			_instr_lbl.text = "Tutorial formation is preset. Press CONFIRM to begin."
		else:
			_instr_lbl.text = "Tutorial formation is incomplete — check tutorial config."
	else:
		_stop_tutorial_confirm_pulse()
		if all_placed:
			_instr_lbl.text = "All cards placed! Press CONFIRM to begin."
		else:
			_instr_lbl.text = "Drag cards onto the grid  |  right-click a placed card to retrieve  |  %d units  %d traps remaining" % [
				_chars_remaining.size(), _traps_remaining.size()
			]

func _lock_confirm_ui() -> void:
	if _confirm_btn != null:
		_confirm_btn.disabled = true
		_sync_setup_button_chrome(_confirm_btn)
	if _random_btn != null:
		_random_btn.disabled = true
		_sync_setup_button_chrome(_random_btn)
	if _gallery_flow != null:
		_gallery_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _formation_bar != null:
		_formation_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for r in range(GRID_N):
		for c in range(GRID_N):
			(_grid_cells[r][c] as GridCell).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _confirm_btn_fx_mat() -> ShaderMaterial:
	if _confirm_btn == null or not _confirm_btn.has_meta(_BTN_FX_META):
		return null
	return _confirm_btn.get_meta(_BTN_FX_META) as ShaderMaterial

func _start_tutorial_confirm_pulse() -> void:
	var mat: ShaderMaterial = _confirm_btn_fx_mat()
	if mat == null:
		return
	if _confirm_btn_pulse_tween != null and _confirm_btn_pulse_tween.is_valid():
		return
	mat.set_shader_parameter("brightness", _CONFIRM_BTN_BRIGHT_REST)
	_confirm_btn_pulse_tween = create_tween().set_loops()
	_confirm_btn_pulse_tween.tween_method(
		func(v: float) -> void:
			var m: ShaderMaterial = _confirm_btn_fx_mat()
			if m != null:
				m.set_shader_parameter("brightness", v),
		_CONFIRM_BTN_BRIGHT_REST, _CONFIRM_BTN_BRIGHT_PULSE, 0.90) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_confirm_btn_pulse_tween.tween_method(
		func(v: float) -> void:
			var m: ShaderMaterial = _confirm_btn_fx_mat()
			if m != null:
				m.set_shader_parameter("brightness", v),
		_CONFIRM_BTN_BRIGHT_PULSE, _CONFIRM_BTN_BRIGHT_REST, 0.90) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_tutorial_confirm_pulse() -> void:
	if _confirm_btn_pulse_tween != null and _confirm_btn_pulse_tween.is_valid():
		_confirm_btn_pulse_tween.kill()
	_confirm_btn_pulse_tween = null
	var mat: ShaderMaterial = _confirm_btn_fx_mat()
	if mat != null:
		mat.set_shader_parameter("brightness", _CONFIRM_BTN_BRIGHT_REST)


func _wire_confirm_metal_sheen() -> void:
	if _confirm_btn == null:
		return
	var existing := _confirm_btn.get_node_or_null("MetalSheen") as TextureRect
	if existing != null:
		existing.queue_free()
	var sheen := TextureRect.new()
	sheen.name = "MetalSheen"
	sheen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheen.show_behind_parent = true
	sheen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheen.stretch_mode = TextureRect.STRETCH_SCALE
	# Soft plate — mostly invisible until the sheen band sweeps across.
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.95, 0.70, 0.18))
	sheen.texture = ImageTexture.create_from_image(img)
	var mat := ShaderMaterial.new()
	mat.shader = _METAL_SHEEN_SHADER
	mat.set_shader_parameter("progress", _SHEEN_IDLE)
	mat.set_shader_parameter("band_width", 0.22)
	mat.set_shader_parameter("intensity", 1.55)
	mat.set_shader_parameter("shine_color", Color(1.0, 0.97, 0.78, 1.0))
	sheen.material = mat
	_confirm_sheen_mat = mat
	_confirm_btn.add_child(sheen)
	# Keep sheen above the chrome ColorRect but still behind label text.
	var fx := _confirm_btn.get_node_or_null("MagitechBtnFx")
	if fx != null:
		_confirm_btn.move_child(sheen, fx.get_index() + 1)
	_schedule_confirm_metal_sheen(randf_range(0.6, 1.8))


func _schedule_confirm_metal_sheen(delay: float) -> void:
	if _confirm_sheen_tween != null and _confirm_sheen_tween.is_valid():
		_confirm_sheen_tween.kill()
	_confirm_sheen_tween = null
	if _confirm_btn == null or not is_instance_valid(_confirm_btn) or _confirm_sheen_mat == null:
		return
	var tw := create_tween()
	_confirm_sheen_tween = tw
	tw.tween_interval(delay)
	tw.tween_callback(_play_confirm_metal_sheen_once)


func _play_confirm_metal_sheen_once() -> void:
	if _confirm_btn == null or not is_instance_valid(_confirm_btn) or _confirm_sheen_mat == null:
		return
	if _confirm_sheen_tween != null and _confirm_sheen_tween.is_valid():
		_confirm_sheen_tween.kill()
	var mat: ShaderMaterial = _confirm_sheen_mat
	var tw := create_tween()
	_confirm_sheen_tween = tw
	tw.tween_method(
		func(v: float) -> void:
			if mat != null:
				mat.set_shader_parameter("progress", v),
		-0.15, 1.15, _SHEEN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		if mat != null:
			mat.set_shader_parameter("progress", _SHEEN_IDLE)
		_schedule_confirm_metal_sheen(randf_range(_SHEEN_INTERVAL_MIN, _SHEEN_INTERVAL_MAX)))


func _stop_confirm_metal_sheen() -> void:
	if _confirm_sheen_tween != null and _confirm_sheen_tween.is_valid():
		_confirm_sheen_tween.kill()
	_confirm_sheen_tween = null
	if _confirm_sheen_mat != null:
		_confirm_sheen_mat.set_shader_parameter("progress", _SHEEN_IDLE)


func _exit_tree() -> void:
	_stop_tutorial_confirm_pulse()
	_stop_confirm_metal_sheen()

# ─────────────────────────────────────────────────────────────
# Tutorial formation lock
# ─────────────────────────────────────────────────────────────
func _is_tutorial_setup() -> bool:
	# Only is_active counts — is_prepared is cleared before setup begins; a stale
	# is_prepared flag would block deckbuilder formations in Quick Duel / VS AI.
	return current_setup_player == 0 and TutorialBattleManager.is_active

func _clear_tutorial_formation_lock() -> void:
	if _tutorial_formation_overlay != null:
		_tutorial_formation_overlay.queue_free()
		_tutorial_formation_overlay = null

func _apply_tutorial_formation_lock() -> void:
	if not _is_tutorial_setup() or _grid_panel == null:
		return

	_random_btn.visible = false
	_gallery_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for r in range(GRID_N):
		for c in range(GRID_N):
			var cell: GridCell = _grid_cells[r][c] as GridCell
			cell.locked = true
			cell.modulate = Color(0.62, 0.62, 0.68, 1.0)

	_clear_tutorial_formation_lock()

	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 10
	_grid_panel.add_child(overlay)
	_tutorial_formation_overlay = overlay

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.42)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	var msg := Label.new()
	msg.text = TUTORIAL_FORMATION_MSG
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	msg.offset_left = 14.0
	msg.offset_right = -14.0
	msg.add_theme_font_size_override("font_size", 14)
	msg.add_theme_color_override("font_color", TXT_PRIMARY)
	msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(msg)

	_refresh_confirm()

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _card_name_to_snake(p_name: String) -> String:
	return p_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")

# ─────────────────────────────────────────────────────────────
# Bluff emoticon
# ─────────────────────────────────────────────────────────────
const BLUFF_EMOJIS: Array = ["😃","🥺","🤣","😎","❤️","☠️","🧨","👍","🤝","🖕"]
const BLUFF_MODAL_SIZE := Vector2(598.5, 130.0)  # 570px width + 5%
func _get_bluff_emojis() -> Array:
	if SaveManager.nsfw_enabled:
		return BLUFF_EMOJIS.map(func(e: String) -> String: return "💩" if e == "🖕" else e)
	return BLUFF_EMOJIS

func _on_cell_bluff_tap(row: int, col: int) -> void:
	if _is_tutorial_setup():
		return
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

	var center_wrap := CenterContainer.new()
	center_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center_wrap)

	# Panel
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = BLUFF_MODAL_SIZE
	var psb := StyleBoxFlat.new()
	psb.bg_color     = Color(0.04, 0.07, 0.16, 0.98)
	psb.border_width_left   = 2; psb.border_width_top    = 2
	psb.border_width_right  = 2; psb.border_width_bottom = 2
	psb.border_color = Color(0.55, 0.78, 1.0, 0.7)
	psb.corner_radius_top_left     = 10; psb.corner_radius_top_right    = 10
	psb.corner_radius_bottom_right = 10; psb.corner_radius_bottom_left  = 10
	panel.add_theme_stylebox_override("panel", psb)
	center_wrap.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12.0; vbox.offset_top = 10.0
	vbox.offset_right = -12.0; vbox.offset_bottom = -10.0
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Pick a Bluff"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", TXT_PRIMARY)
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
		_skin_setup_button(btn)
		var snap_emoji: String = emoji
		btn.pressed.connect(func() -> void:
			SFXManager.play(SFXManager.SFX_BLUFF_PLACE)
			GameState.set_bluff(current_setup_player, snap_row, snap_col, snap_emoji)
			(_grid_cells[snap_row][snap_col] as GridCell).set_emoticon(snap_emoji)
			backdrop.queue_free())
		hbox.add_child(btn)

	# Clear button
	var clear_btn := Button.new()
	clear_btn.text = "✕  Remove Bluff"
	clear_btn.add_theme_font_override("font", FontManager.make_font("primary", 400))
	clear_btn.add_theme_font_size_override("font_size", 14)
	clear_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_skin_setup_button(clear_btn)
	clear_btn.pressed.connect(func() -> void:
		SFXManager.play(SFXManager.SFX_BLUFF_REMOVE)
		GameState.set_bluff(current_setup_player, snap_row, snap_col, "")
		(_grid_cells[snap_row][snap_col] as GridCell).set_emoticon("")
		backdrop.queue_free())
	vbox.add_child(clear_btn)
