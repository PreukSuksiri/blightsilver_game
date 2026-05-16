extends Control
# Main game board — manages grids, selection, turn flow, and AI.

const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")
const MAX_CRYSTALS: int = 5000
const MAX_LOG_LINES: int = 60
const SFX_CRYSTAL: AudioStream = preload("res://assets/audio/sound_crystal_1.mp3")

# ── Grid containers
@onready var p1_grid: GridContainer = $MainLayout/P1Side/P1Grid
@onready var p2_grid: GridContainer = $MainLayout/P2Side/P2Grid

# ── Mode controls
@onready var mode_panel: Panel = $MainLayout/CenterPanel/ModePanel
@onready var attack_btn: Button = $MainLayout/CenterPanel/ModePanel/AttackBtn
@onready var tech_btn: Button = $MainLayout/CenterPanel/ModePanel/TechBtn
@onready var end_attack_btn: Button = $MainLayout/CenterPanel/ModePanel/EndAttackBtn

# ── Tech hand & action
@onready var tech_hand_container: HBoxContainer = $MainLayout/CenterPanel/TechHandContainer
@onready var action_panel: Panel = $MainLayout/CenterPanel/ActionPanel
@onready var action_label: Label = $MainLayout/CenterPanel/ActionPanel/ActionLabel

# ── Info displays
@onready var dice_display: Label = $MainLayout/CenterPanel/DiceDisplay
@onready var message_log: RichTextLabel = $MainLayout/CenterPanel/MessageLog

# (HUD panels removed — crystal/name/turn displays built in code below)

# ── Overlays
@onready var setup_phase: Control = $SetupPhase
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/ResultLabel
@onready var play_again_btn: Button = $GameOverPanel/PlayAgainBtn

var _player_names: Array[String] = ["Player 1", "Player 2"]

var turn_manager: TurnManager
var ai_player: AIPlayer

# Player portrait illustration nodes
var _p1_portrait: TextureRect = null
var _p2_portrait: TextureRect = null

# Corner crystal displays (icon + label, above portraits)
var _p1_bottom_crystal: Label = null
var _p2_bottom_crystal: Label = null
var _p1_crystal_row: Control = null   # VBoxContainer
var _p2_crystal_row: Control = null   # VBoxContainer
var _p1_name_lbl: Label = null
var _p2_name_lbl: Label = null
var _turn_number_lbl: Label = null
var _turn_number_bg: TextureRect = null

# Options menu & battle log
var _battle_log_lines: Array[String] = []
var _ai_watchdog: Timer = null
var _card_name_to_type: Dictionary = {}   # card_name -> "character"|"trap"|"tech"
var _options_panel: Control = null
var _options_btn: TextureButton = null
var _music_changed_this_turn: bool = false

# Setup-phase BGM player (started when placement begins, stopped at _begin_game)
var _setup_music: AudioStreamPlayer = null
# Battle BGM player (started at _begin_game, stopped at game over)
var _battle_music: AudioStreamPlayer = null

# Tech card fan (bottom of screen, active player only)
var _tech_fan: Control = null

# Tech card stacks (top-left P1, top-right P2) + shared overlay
var _p1_tech_stack: Control = null
var _p2_tech_stack: Control = null
var _p1_stack_count_lbl: Label = null
var _p2_stack_count_lbl: Label = null
var _tech_overlay_panel: Panel = null
var _tech_overlay_player: int = -1
var _tech_overlay_close_pending: bool = false

# Dump stacks (destroyed cards) + modal
var _void_piles: Array = [[], []]   # Array of {card_name, card_type} per player
var _p1_void_stack: Control = null
var _p2_void_stack: Control = null
var _p1_void_count_lbl: Label = null
var _p2_void_count_lbl: Label = null
var _void_modal: Control = null

# Crystal icon refs (for burst animation)
var _p1_crystal_icon: TextureRect = null
var _p2_crystal_icon: TextureRect = null
var _prev_crystals: Array[int] = [3000, 3000]

# Tax confirmation overlay
var _tax_confirm_panel: Control = null

# Peek (reveal preview) buttons
var _p1_reveal_btn: Button = null
var _p2_reveal_btn: Button = null
var _reveal_preview: Array[bool] = [false, false]
var _enemy_view_active: bool = false
var _tech_used_this_turn: Array[bool] = [false, false]
var _tech_reset_turn: int = -1   # turn_number when _tech_used_this_turn was last cleared

# Hover info panel (center column, battle phase only)
var _hover_panel: Control = null
var _hover_name_lbl: Label = null
var _hover_type_lbl: Label = null
var _hover_atk_lbl: Label = null
var _hover_def_lbl: Label = null
var _hover_aff_lbl: Label = null
var _hover_desc_lbl: Label = null
var _tech_hover_node: Control = null  # card node currently showing target hover highlight

# grid_nodes[player][row][col] -> Card control node
var grid_nodes: Array = [[], []]
# bluff_labels[player][row][col] -> Label overlaid on card node
var bluff_labels: Array = [[], []]

# ── Campaign return button (added to game_over_panel at runtime)
var _campaign_return_btn: Button = null

# ── End-game screen shake
var _shake_active: bool = false
var _shake_origin: Vector2 = Vector2.ZERO
var _shake_intensity: float = 5.0

# ── Hot Seat handoff overlay (built at runtime)
var _handoff_overlay: Control = null
var _handoff_player_lbl: Label = null
var _handoff_context_lbl: Label = null
var _handoff_crystals_lbl: Label = null
var _handoff_ready_btn: Button = null
var _handoff_callback: Callable = Callable()

enum SelectionState { NONE, SELECTING_ATTACKER, SELECTING_TARGET, CONFIRMING_ATTACK, SELECTING_TECH_TARGET, AWAITING_TRAP_CHOICE, SELECTING_UNION_MATERIALS }
var selection_state: SelectionState = SelectionState.NONE
var selected_attacker_pos: Vector2i = Vector2i(-1, -1)
var _confirm_target_pos: Vector2i = Vector2i(-1, -1)
var _confirm_target_player: int = -1
var _blink_tween: Tween = null
var _end_turn_blink_tween: Tween = null
var _attack_confirm_panel: Control = null
var _end_turn_btn: TextureButton = null
var _last_banner_turn: int = -1

# Card context menu (tap-to-open popup)
var _context_popup: Panel = null     # created fresh per open, freed on close
var _context_backdrop: Control = null # fullscreen click-catcher behind popup
var _last_click_pos: Vector2 = Vector2.ZERO  # updated on every press, used for popup placement
var _context_card_player: int = -1
var _context_card_pos: Vector2i = Vector2i(-1, -1)
var pending_tech_filter: String = ""
var pending_tech_name: String = ""
var _tech_reveals_remaining: int = 0   # for multi-reveal effects (e.g. Radar)
var _tech_reveals_total: int = 0

# Cursor-following guide box
var _guide_box: Control = null
var _guide_label: Label = null
var locked_positions: Array = []
# HOT_SEAT handoff tracking: avoid showing handoff again for the same player's continued turn
var _handoff_last_player: int = -1
var _handoff_last_turn: int = -1

func _input(event: InputEvent) -> void:
	# _input fires for ALL presses regardless of which GUI control consumed them.
	var is_left_press: bool = (
		(event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed) or
		(event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	)
	if not is_left_press:
		return
	var click_pos: Vector2
	if event is InputEventMouseButton:
		click_pos = (event as InputEventMouseButton).position
	else:
		click_pos = (event as InputEventScreenTouch).position
	_last_click_pos = click_pos

	# Dismiss context menu when clicking outside the popup
	if is_instance_valid(_context_popup):
		if not _context_popup.get_global_rect().has_point(click_pos):
			_hide_card_context()

	# Cancel attack-target selection when tapping outside the opponent's grid
	if selection_state == SelectionState.SELECTING_TARGET:
		var opponent := GameState.get_opponent(GameState.current_player)
		var opp_grid: GridContainer = p2_grid if opponent == 1 else p1_grid
		if not opp_grid.get_global_rect().has_point(click_pos):
			_clear_selection()
			_set_selection_state(SelectionState.SELECTING_ATTACKER)
			_highlight_attackable_chars()

	# Cancel union material selection when tapping outside own grid
	if selection_state == SelectionState.SELECTING_UNION_MATERIALS:
		var own_grid: GridContainer = p1_grid if _pending_union_player == 0 else p2_grid
		if not own_grid.get_global_rect().has_point(click_pos):
			_cancel_union_material_selection()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed:
		var ke := event as InputEventKey
		if ke.keycode == KEY_A and ke.ctrl_pressed and ke.shift_pressed:
			_toggle_admin_console()
			get_viewport().set_input_as_handled()
			return
	var is_left_press: bool = (
		(event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and event.pressed) or
		(event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	)
	if is_left_press:
		_hide_hover_info()
		_close_tech_overlay()

func _toggle_admin_console() -> void:
	const AdminConsoleScene: PackedScene = preload("res://scenes/admin_console.tscn")
	if get_node_or_null("AdminConsoleOverlay") != null:
		get_node("AdminConsoleOverlay").queue_free()
		return
	var overlay: Node = AdminConsoleScene.instantiate()
	overlay.name = "AdminConsoleOverlay"
	add_child(overlay)

func _ready() -> void:
	_setup_turn_manager()
	_setup_ai()
	_connect_signals()
	_build_grids()
	_setup_buttons()
	_build_handoff_overlay()
	_build_portraits()
	_build_hover_panel()
	_build_tech_stacks()
	_build_void_stacks()
	_build_reveal_buttons()
	_build_end_turn_button()
	_build_attack_confirm_panel()

	_build_card_name_lookup()
	_build_bottom_crystal_labels()
	_build_turn_number_label()
	_build_options_button()
	game_over_panel.visible = false
	mode_panel.visible = false
	action_panel.visible = false
	_start_game()
	CheckerTransition.fade_in()

# ─────────────────────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────────────────────
func _setup_turn_manager() -> void:
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	turn_manager.mode_selected.connect(_on_mode_selected)
	turn_manager.attack_phase_started.connect(_on_attack_phase_started)
	turn_manager.attack_completed.connect(_on_attack_completed)
	turn_manager.tech_played.connect(_on_tech_played)
	turn_manager.tech_resolved.connect(_on_tech_resolved)
	turn_manager.turn_ended.connect(_on_turn_ended)
	turn_manager.awaiting_trap_choice.connect(_on_awaiting_trap_choice)
	turn_manager.awaiting_target_selection.connect(_on_awaiting_target_selection)
	turn_manager.battle_preview_needed.connect(_on_battle_preview_needed)
	turn_manager.attack_aborted.connect(_on_attack_aborted)

func _setup_ai() -> void:
	ai_player = AIPlayer.new()
	add_child(ai_player)
	ai_player.ai_mode_chosen.connect(_on_ai_mode_chosen)
	ai_player.ai_attack_chosen.connect(_on_ai_attack_chosen)
	ai_player.ai_tech_chosen.connect(_on_ai_tech_chosen)
	ai_player.ai_end_turn.connect(func() -> void: turn_manager.end_attacks_early())

	# Watchdog timer — fires if bot goes idle for 5 s between decide_turn() and its first signal
	_ai_watchdog = Timer.new()
	_ai_watchdog.wait_time = 5.0
	_ai_watchdog.one_shot  = true
	_ai_watchdog.timeout.connect(_on_ai_watchdog_timeout)
	add_child(_ai_watchdog)

	# Intermediate AI signals → restart the 5 s window (bot is still active)
	ai_player.ai_mode_chosen.connect(func(_m: GameState.TurnMode) -> void: _ai_watchdog.start())
	ai_player.ai_attack_chosen.connect(func(_a: Vector2i, _t: Vector2i) -> void: _ai_watchdog.start())
	ai_player.ai_tech_chosen.connect(func(_n: String) -> void: _ai_watchdog.start())
	# Turn fully done → stop watchdog
	ai_player.ai_end_turn.connect(func() -> void: _ai_watchdog.stop())

func _on_ai_watchdog_timeout() -> void:
	var msg: String = "[AI WATCHDOG] Bot Player went idle for 5 s — no decision emitted."
	print(msg)
	GameState.post_message("[DEBUG] Bot Player timed out (5 s idle).")

func _connect_signals() -> void:
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.card_revealed.connect(_on_card_revealed)
	GameState.card_destroyed.connect(_on_card_destroyed)
	GameState.crystals_changed.connect(_on_crystals_changed)
	GameState.dice_rolled.connect(_on_dice_rolled)
	GameState.game_over.connect(_on_game_over)
	GameState.message_posted.connect(_on_message_posted)
	GameState.tech_card_used.connect(func(_p: int, _n: String) -> void:
		_update_tech_stacks()
		if _tech_overlay_panel != null and _tech_overlay_panel.visible:
			_rebuild_tech_overlay_content(_tech_overlay_player))
	GameState.card_effect_triggered.connect(_on_card_effect_triggered)

const GRID_LINE_W: int = 2
const GRID_LINE_COLOR: Color = Color(0.65, 0.88, 0.95, 0.9)  # silver-cyan

func _build_grids() -> void:
	for p in range(2):
		var grid_container := p1_grid if p == 0 else p2_grid
		grid_container.columns = GameState.GRID_SIZE
		grid_nodes[p] = []
		bluff_labels[p] = []
		for r in range(GameState.GRID_SIZE):
			var row_arr: Array = []
			var lbl_row: Array = []
			for c in range(GameState.GRID_SIZE):
				var card_node: Control = CARD_SCENE.instantiate()
				card_node.rarity_fx_enabled = false
				grid_container.add_child(card_node)
				card_node.card_clicked.connect(_on_card_node_clicked.bind(p, r, c))
				card_node.card_detail_requested.connect(_on_card_detail_requested)
				card_node.mouse_entered.connect(
					func() -> void: _on_grid_card_hovered(p, r, c))
				card_node.mouse_exited.connect(_hide_hover_info)
				# Bluff emoticon label — sits at the top edge of every cell
				var bluff_lbl := Label.new()
				bluff_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
				bluff_lbl.offset_top    = 2.0
				bluff_lbl.offset_bottom = 26.0
				bluff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				bluff_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				bluff_lbl.z_index = 5
				bluff_lbl.text = ""
				card_node.add_child(bluff_lbl)
				row_arr.append(card_node)
				lbl_row.append(bluff_lbl)
			grid_nodes[p].append(row_arr)
			bluff_labels[p].append(lbl_row)
	call_deferred("_add_grid_line_panels")
	call_deferred("_refresh_all_bluff_labels")

func _add_grid_line_panels() -> void:
	# Wait one extra frame so the GridContainer layout is fully computed
	await get_tree().process_frame
	var ml: Node = get_node("MainLayout")
	var ml_idx: int = ml.get_index()
	var lw: float = float(GRID_LINE_W)
	var sep: float = 4.0  # matches scene h_separation / v_separation

	for p in range(2):
		var gc: GridContainer = p1_grid if p == 0 else p2_grid
		var gpos: Vector2 = gc.global_position
		var gsz: Vector2  = gc.size

		# Build a list of (position, size) rects for each line strip
		var strips: Array = []

		# Outer border — 4 thin edges
		strips.append([Vector2(gpos.x - lw, gpos.y - lw), Vector2(gsz.x + lw * 2.0, lw)])  # top
		strips.append([Vector2(gpos.x - lw, gpos.y + gsz.y), Vector2(gsz.x + lw * 2.0, lw)])  # bottom
		strips.append([Vector2(gpos.x - lw, gpos.y), Vector2(lw, gsz.y)])  # left
		strips.append([Vector2(gpos.x + gsz.x, gpos.y), Vector2(lw, gsz.y)])  # right

		# Inner vertical lines — between each pair of columns
		for c in range(GameState.GRID_SIZE - 1):
			var card_node: Control = grid_nodes[p][0][c]
			var gap_x: float = card_node.global_position.x + card_node.size.x
			strips.append([Vector2(gap_x, gpos.y), Vector2(sep, gsz.y)])

		# Inner horizontal lines — between each pair of rows
		for r in range(GameState.GRID_SIZE - 1):
			var card_node: Control = grid_nodes[p][r][0]
			var gap_y: float = card_node.global_position.y + card_node.size.y
			strips.append([Vector2(gpos.x, gap_y), Vector2(gsz.x, sep)])

		# Spawn one ColorRect per strip
		for strip: Array in strips:
			var cr := ColorRect.new()
			cr.color = GRID_LINE_COLOR
			cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(cr)
			move_child(cr, ml_idx)
			cr.position = strip[0]
			cr.size    = strip[1]

func _setup_buttons() -> void:
	attack_btn.pressed.connect(_on_attack_btn)
	tech_btn.pressed.connect(_on_tech_btn)
	end_attack_btn.pressed.connect(_on_end_attack_btn)
	play_again_btn.pressed.connect(_on_play_again_btn)
	end_attack_btn.visible = false
	game_over_panel.z_index = 5

	# Campaign-only "Return to Map" button added below PlayAgainBtn
	if GameState.game_mode == GameState.GameMode.CAMPAIGN:
		# Shift PlayAgainBtn up to make room
		play_again_btn.offset_top    = -88.0
		play_again_btn.offset_bottom = -50.0
		_campaign_return_btn = Button.new()
		_campaign_return_btn.text = "RETURN TO MAP"
		_campaign_return_btn.layout_mode = 1
		_campaign_return_btn.anchor_left   = 0.5
		_campaign_return_btn.anchor_top    = 1.0
		_campaign_return_btn.anchor_right  = 0.5
		_campaign_return_btn.anchor_bottom = 1.0
		_campaign_return_btn.offset_left   = -140.0
		_campaign_return_btn.offset_top    = -16.0
		_campaign_return_btn.offset_right  =  140.0
		_campaign_return_btn.offset_bottom =  16.0
		_campaign_return_btn.visible = false
		_campaign_return_btn.pressed.connect(_on_return_to_map)
		game_over_panel.add_child(_campaign_return_btn)

func _build_handoff_overlay() -> void:
	# Fullscreen privacy screen shown between Hot Seat turns
	_handoff_overlay = Control.new()
	_handoff_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_handoff_overlay.visible = false
	_handoff_overlay.z_index = 5
	add_child(_handoff_overlay)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.96)
	_handoff_overlay.add_child(bg)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -250.0
	panel.offset_top  = -180.0
	panel.offset_right = 250.0
	panel.offset_bottom = 180.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.06, 0.14, 1.0)
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.38, 0.65, 1.0, 0.45)
	sb.corner_radius_top_left     = 8
	sb.corner_radius_top_right    = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left  = 8
	panel.add_theme_stylebox_override("panel", sb)
	_handoff_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   =  24.0
	vbox.offset_top    =  20.0
	vbox.offset_right  = -24.0
	vbox.offset_bottom = -20.0
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var pass_lbl := Label.new()
	pass_lbl.text = "PASS THE DEVICE"
	pass_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pass_lbl.add_theme_font_size_override("font_size", 16)
	pass_lbl.add_theme_color_override("font_color", Color(0.38, 0.65, 1.0, 0.65))
	vbox.add_child(pass_lbl)

	_handoff_player_lbl = Label.new()
	_handoff_player_lbl.text = "PLAYER 1"
	_handoff_player_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_handoff_player_lbl.add_theme_font_size_override("font_size", 44)
	_handoff_player_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	vbox.add_child(_handoff_player_lbl)

	_handoff_context_lbl = Label.new()
	_handoff_context_lbl.text = ""
	_handoff_context_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_handoff_context_lbl.add_theme_font_size_override("font_size", 15)
	_handoff_context_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0, 0.85))
	_handoff_context_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_handoff_context_lbl)

	_handoff_crystals_lbl = Label.new()
	_handoff_crystals_lbl.text = ""
	_handoff_crystals_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_handoff_crystals_lbl.add_theme_font_size_override("font_size", 14)
	_handoff_crystals_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.8))
	vbox.add_child(_handoff_crystals_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	_handoff_ready_btn = Button.new()
	_handoff_ready_btn.text = "I'M READY"
	_handoff_ready_btn.custom_minimum_size = Vector2(0, 48)
	_handoff_ready_btn.add_theme_font_size_override("font_size", 18)
	var rn := StyleBoxFlat.new()
	rn.bg_color = Color(0.06, 0.12, 0.28, 1.0)
	rn.border_width_left   = 2
	rn.border_width_top    = 2
	rn.border_width_right  = 2
	rn.border_width_bottom = 2
	rn.border_color = Color(0.38, 0.65, 1.0, 0.6)
	rn.corner_radius_top_left     = 6
	rn.corner_radius_top_right    = 6
	rn.corner_radius_bottom_right = 6
	rn.corner_radius_bottom_left  = 6
	var rh := rn.duplicate() as StyleBoxFlat
	rh.bg_color = Color(0.1, 0.2, 0.44, 1.0)
	rh.border_color = Color(0.38, 0.65, 1.0, 1.0)
	_handoff_ready_btn.add_theme_stylebox_override("normal", rn)
	_handoff_ready_btn.add_theme_stylebox_override("hover", rh)
	_handoff_ready_btn.add_theme_stylebox_override("pressed", rn)
	_handoff_ready_btn.add_theme_stylebox_override("focus", rn)
	_handoff_ready_btn.add_theme_color_override("font_color", Color(0.72, 0.9, 1.0, 1.0))
	_handoff_ready_btn.pressed.connect(_on_handoff_ready)
	vbox.add_child(_handoff_ready_btn)

func _build_portraits() -> void:
	# Scale each portrait to fill the full screen height at its natural aspect ratio,
	# so the inner edge (right for P1, left for P2) is never cropped.
	const REF_H: float = 720.0

	var p1_tex: Texture2D = load(GameState.player_portraits[0])
	if p1_tex:
		var sz := p1_tex.get_size()
		var pw: float = REF_H * sz.x / sz.y if sz.y > 0.0 else 300.0
		_p1_portrait = TextureRect.new()
		_p1_portrait.texture       = p1_tex
		_p1_portrait.layout_mode   = 1
		_p1_portrait.anchor_left   = 0.0
		_p1_portrait.anchor_top    = 1.0
		_p1_portrait.anchor_right  = 0.0
		_p1_portrait.anchor_bottom = 1.0
		_p1_portrait.offset_left   = -pw * 0.4
		_p1_portrait.offset_top    = -REF_H
		_p1_portrait.offset_right  = pw * 0.6
		_p1_portrait.offset_bottom = 0.0
		_p1_portrait.visible       = false
		_p1_portrait.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		_p1_portrait.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
		_p1_portrait.flip_h        = true
		_p1_portrait.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		_p1_portrait.z_index       = 3
		add_child(_p1_portrait)

	var p2_tex: Texture2D = load(GameState.player_portraits[1])
	if p2_tex:
		var sz := p2_tex.get_size()
		var pw: float = REF_H * sz.x / sz.y if sz.y > 0.0 else 300.0
		_p2_portrait = TextureRect.new()
		_p2_portrait.texture       = p2_tex
		_p2_portrait.layout_mode   = 1
		_p2_portrait.anchor_left   = 1.0
		_p2_portrait.anchor_top    = 1.0
		_p2_portrait.anchor_right  = 1.0
		_p2_portrait.anchor_bottom = 1.0
		_p2_portrait.offset_left   = -pw * 0.6
		_p2_portrait.offset_top    = -REF_H
		_p2_portrait.offset_right  = pw * 0.4
		_p2_portrait.offset_bottom = 0.0
		_p2_portrait.visible       = false
		_p2_portrait.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		_p2_portrait.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
		_p2_portrait.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		_p2_portrait.z_index       = 3
		add_child(_p2_portrait)

func _show_handoff(player: int, context: String, callback: Callable) -> void:
	_handoff_callback = callback
	_handoff_player_lbl.text = _player_names[player].to_upper()
	var p_color := Color(0.4, 0.8, 1.0, 1.0) if player == 0 else Color(0.3, 1.0, 0.65, 1.0)
	_handoff_player_lbl.add_theme_color_override("font_color", p_color)
	_handoff_context_lbl.text = context
	if GameState.turn_number > 0:
		_handoff_crystals_lbl.text = "P1: %d◆   P2: %d◆" % [
			GameState.crystals[0], GameState.crystals[1]]
	else:
		_handoff_crystals_lbl.text = ""
	_handoff_overlay.visible = true
	_handoff_ready_btn.grab_focus()
	if _options_btn:
		_options_btn.visible = false

func _on_handoff_ready() -> void:
	_handoff_overlay.visible = false
	if _handoff_callback.is_valid():
		_handoff_callback.call()
	_handoff_callback = Callable()

func _start_game() -> void:
	GameState.new_game(GameState.game_mode)
	# Apply campaign-supplied player names if VNPlayer set them
	if GameState.campaign_player_names.size() == 2:
		var n1: String = GameState.campaign_player_names[0]
		var n2: String = GameState.campaign_player_names[1]
		if not n1.is_empty():
			_player_names[0] = n1
		if not n2.is_empty():
			_player_names[1] = n2
		_apply_player_names()
		GameState.campaign_player_names = []
	_refresh_hud()
	if GameState.game_mode == GameState.GameMode.VS_AI:
		_player_names[1] = "Player 2 (Bot)"
		_apply_player_names()
	if GameState.game_mode == GameState.GameMode.HOT_SEAT:
		_start_setup_music()
		_show_name_entry()
	elif setup_phase:
		setup_phase.visible = true
		setup_phase.start_setup(0)
		setup_phase.setup_complete.connect(_on_setup_complete_p1, CONNECT_ONE_SHOT)
		_start_setup_music()

func _show_name_entry() -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 20
	add_child(overlay)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.92)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bg)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -280.0
	panel.offset_top    = -240.0
	panel.offset_right  =  280.0
	panel.offset_bottom =  240.0
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.04, 0.06, 0.15, 1.0)
	psb.border_width_left   = 2
	psb.border_width_top    = 2
	psb.border_width_right  = 2
	psb.border_width_bottom = 2
	psb.border_color = Color(0.38, 0.65, 1.0, 0.55)
	psb.corner_radius_top_left     = 10
	psb.corner_radius_top_right    = 10
	psb.corner_radius_bottom_right = 10
	psb.corner_radius_bottom_left  = 10
	panel.add_theme_stylebox_override("panel", psb)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   =  28.0
	vbox.offset_top    =  24.0
	vbox.offset_right  = -28.0
	vbox.offset_bottom = -24.0
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var heading := Label.new()
	heading.text = "ENTER PLAYER NAMES"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color(0.38, 0.75, 1.0))
	vbox.add_child(heading)

	var sub := Label.new()
	sub.text = "Leave blank to keep the default name."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.55, 0.65, 0.80))
	vbox.add_child(sub)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	# P1 name
	var p1_lbl := Label.new()
	p1_lbl.text = "Player 1 name"
	p1_lbl.add_theme_font_size_override("font_size", 13)
	p1_lbl.add_theme_color_override("font_color", Color(0.749, 0.878, 1.0))
	vbox.add_child(p1_lbl)

	var p1_edit := LineEdit.new()
	p1_edit.placeholder_text = "Player 1"
	p1_edit.text = _player_names[0] if _player_names[0] != "Player 1" else ""
	p1_edit.max_length = 20
	p1_edit.custom_minimum_size = Vector2(0, 40)
	p1_edit.add_theme_font_size_override("font_size", 16)
	vbox.add_child(p1_edit)

	# P2 name
	var p2_lbl := Label.new()
	p2_lbl.text = "Player 2 name"
	p2_lbl.add_theme_font_size_override("font_size", 13)
	p2_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.78))
	vbox.add_child(p2_lbl)

	var p2_edit := LineEdit.new()
	p2_edit.placeholder_text = "Player 2"
	p2_edit.text = _player_names[1] if _player_names[1] != "Player 2" else ""
	p2_edit.max_length = 20
	p2_edit.custom_minimum_size = Vector2(0, 40)
	p2_edit.add_theme_font_size_override("font_size", 16)
	vbox.add_child(p2_edit)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var start_btn := Button.new()
	start_btn.text = "START GAME"
	start_btn.custom_minimum_size = Vector2(0, 52)
	start_btn.add_theme_font_size_override("font_size", 18)
	start_btn.pressed.connect(func() -> void:
		var n1 := p1_edit.text.strip_edges()
		var n2 := p2_edit.text.strip_edges()
		_player_names[0] = n1 if not n1.is_empty() else "Player 1"
		_player_names[1] = n2 if not n2.is_empty() else "Player 2"
		_apply_player_names()
		overlay.queue_free()
		if setup_phase:
			setup_phase.visible = true
			setup_phase.start_setup(0)
			setup_phase.setup_complete.connect(_on_setup_complete_p1, CONNECT_ONE_SHOT)
			_start_setup_music())
	vbox.add_child(start_btn)

	p1_edit.grab_focus()

func _apply_player_names() -> void:
	if _p1_name_lbl: _p1_name_lbl.text = _player_names[0]
	if _p2_name_lbl: _p2_name_lbl.text = _player_names[1]

# ─────────────────────────────────────────────────────────────
# Setup Phase Handlers
# ─────────────────────────────────────────────────────────────
func _on_setup_complete_p1() -> void:
	if GameState.game_mode == GameState.GameMode.VS_AI \
			or GameState.game_mode == GameState.GameMode.CAMPAIGN:
		_do_ai_setup()
		_begin_game()
	elif GameState.game_mode == GameState.GameMode.HOT_SEAT:
		_show_handoff(1,
			"Player 1 has finished placing their cards.\nPlayer 2, please set up your grid.",
			func() -> void:
				setup_phase.start_setup(1)
				setup_phase.setup_complete.connect(_on_setup_complete_p2, CONNECT_ONE_SHOT)
		)
	else:
		setup_phase.start_setup(1)
		setup_phase.setup_complete.connect(_on_setup_complete_p2, CONNECT_ONE_SHOT)

func _on_setup_complete_p2() -> void:
	_begin_game()

func _do_ai_setup() -> void:
	var placements := ai_player.decide_setup()
	for placement in placements:
		var pos: Vector2i = placement["pos"]
		if placement["card_type"] == "character":
			GameState.place_character(1, pos.x, pos.y, placement["card_name"])
		elif placement["card_type"] == "trap":
			GameState.place_trap(1, pos.x, pos.y, placement["card_name"])

func _begin_game() -> void:
	if setup_phase:
		setup_phase.visible = false
	_stop_setup_music()
	_refresh_all_bluff_labels()
	if _p1_portrait:
		_p1_portrait.visible = true
	if _p2_portrait:
		_p2_portrait.visible = true
	_start_battle_music()
	_deal_tech_cards(0, GameState.STARTING_TECH_HAND)
	_deal_tech_cards(1, GameState.STARTING_TECH_HAND)
	_update_tech_stacks()
	_update_void_stacks()
	_refresh_all_grids()
	_refresh_hud()
	var first_player: int = DiceRoller.flip_coin_first_player()
	var coin_result: String = "Heads" if first_player == 0 else "Tails"
	GameState.post_message("Coin flip — %s! Player %d goes first!" % [coin_result, first_player + 1])
	_show_coin_flip_and_start(first_player)

# ─────────────────────────────────────────────────────────────
# Battle music
# ─────────────────────────────────────────────────────────────
func _start_setup_music() -> void:
	if _setup_music != null:
		return
	var stream := load("res://assets/audio/bgm_placement_1.mp3") as AudioStream
	if stream == null:
		push_warning("GameBoard: failed to load setup BGM")
		return
	_setup_music = AudioStreamPlayer.new()
	_setup_music.stream = stream
	_setup_music.bus    = &"Music"
	_setup_music.finished.connect(func() -> void: _setup_music.play())  # loop
	add_child(_setup_music)
	_setup_music.play()

func _stop_setup_music() -> void:
	if _setup_music == null:
		return
	_setup_music.stop()
	_setup_music.queue_free()
	_setup_music = null

func _start_battle_music() -> void:
	var path: String = GameState.battle_bgm_path
	if path.is_empty():
		return
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("GameBoard: failed to load battle BGM '%s'" % path)
		return
	_battle_music = AudioStreamPlayer.new()
	_battle_music.stream    = stream
	_battle_music.bus       = &"Music"
	_battle_music.volume_db = -80.0 if GameState.battle_bgm_volume <= 0.0 \
		else linear_to_db(GameState.battle_bgm_volume / 100.0)
	_battle_music.finished.connect(func() -> void: _battle_music.play())  # loop
	add_child(_battle_music)
	_battle_music.play()

# ─────────────────────────────────────────────────────────────
# Tech card fan
# ─────────────────────────────────────────────────────────────
const _FAN_CARD_W  : float = 88.0
const _FAN_CARD_H  : float = 121.0
const _FAN_SPACING : float = 58.0   # horizontal center-to-center
const _FAN_ROT_DEG : float = 7.0    # rotation step between cards (degrees)
const _FAN_ARC_DIP : float = 7.0    # edge cards dip this many extra pixels below center
const _FAN_BASE_Y  : float = 672.0  # card center Y (720 screen height)
const _FAN_CENTER_X: float = 640.0  # horizontal center of screen
const _FAN_HOVER_RISE: float = 22.0 # pixels card rises on hover

func _build_tech_fan() -> void:
	if _tech_fan != null:
		_tech_fan.queue_free()
	_tech_fan = Control.new()
	_tech_fan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tech_fan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tech_fan.z_index = 2
	add_child(_tech_fan)
	_rebuild_tech_fan()

func _rebuild_tech_fan() -> void:
	if _tech_fan == null:
		return
	for ch in _tech_fan.get_children():
		ch.queue_free()

	var phase := GameState.current_phase
	if phase in [GameState.Phase.NONE, GameState.Phase.SETUP_P1,
			GameState.Phase.SETUP_P2, GameState.Phase.GAME_OVER]:
		_tech_fan.visible = false
		return

	var player := GameState.current_player
	# In VS_AI / Campaign the opponent is the AI — never show its hand
	if GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN] \
			and player != 0:
		_tech_fan.visible = false
		return

	var hand: Array = GameState.tech_hands[player]
	if hand.is_empty():
		_tech_fan.visible = false
		return

	_tech_fan.visible = true
	var n: int = hand.size()
	var center_i: float = (n - 1) / 2.0

	# Compute center from the actual CenterPanel position so the fan is always aligned
	var center_panel: Control = message_log.get_parent() as Control
	var fan_center_x: float = center_panel.global_position.x + center_panel.size.x * 0.5

	for i in range(n):
		var tech_name: String = str(hand[i])
		var offset: float = float(i) - center_i
		var pos_x: float = fan_center_x + offset * _FAN_SPACING - _FAN_CARD_W * 0.5
		var pos_y: float = _FAN_BASE_Y + absf(offset) * _FAN_ARC_DIP - _FAN_CARD_H * 0.5
		var rot: float = deg_to_rad(offset * _FAN_ROT_DEG)
		_add_fan_card(tech_name, player, pos_x, pos_y, rot)

func _add_fan_card(tech_name: String, player: int,
		pos_x: float, pos_y: float, rot: float) -> void:
	var card: Control = CARD_SCENE.instantiate()
	card.layout_mode = 0
	card.position = Vector2(pos_x, pos_y)
	card.size = Vector2(_FAN_CARD_W, _FAN_CARD_H)
	card.pivot_offset = Vector2(_FAN_CARD_W * 0.5, _FAN_CARD_H * 0.5)
	card.rotation = rot
	card.z_index = 1  # cards in fan stack left-to-right (later siblings on top)

	var inst := GameState.CardInstance.new()
	inst.card_type = "tech"
	inst.card_name = tech_name
	inst.face_up   = false
	var data: TechCardData = CardDatabase.get_tech(tech_name)
	if data:
		inst.rarity       = data.rarity
		inst.crystal_cost = data.crystal_cost
	card.set_card_data(inst, player, Vector2i(-1, -1))

	card.card_detail_requested.connect(
		func(cn: String, ct: String, _p: int, _r: int, _c: int) -> void: CardDetailOverlay.open(self, cn, ct))

	# Rise/lower on hover (tween position Y)
	var base_y: float = pos_y
	card.mouse_entered.connect(func() -> void:
		var tw := create_tween()
		tw.tween_property(card, "position:y", base_y - _FAN_HOVER_RISE, 0.10) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_show_hover_info(tech_name, "tech"))
	card.mouse_exited.connect(func() -> void:
		var tw := create_tween()
		tw.tween_property(card, "position:y", base_y, 0.10) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_hide_hover_info())

	_tech_fan.add_child(card)

# ─────────────────────────────────────────────────────────────
# Tech Card Stacks (top-left P1, top-right P2)
# ─────────────────────────────────────────────────────────────

func _build_tech_stacks() -> void:
	_p1_tech_stack = _create_tech_stack_indicator(0)
	_p2_tech_stack = _create_tech_stack_indicator(1)

	# Shared overlay panel — positioned when opened
	var ovl := Panel.new()
	ovl.layout_mode = 0
	ovl.visible = false
	ovl.z_index = 10
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.16, 0.97)
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.30, 0.85, 1.0, 0.55)
	sb.corner_radius_top_left     = 6
	sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_left  = 6
	sb.corner_radius_bottom_right = 6
	ovl.add_theme_stylebox_override("panel", sb)
	add_child(ovl)
	_tech_overlay_panel = ovl

	# Hover mechanism removed — overlay now opened by click only

func _create_tech_stack_indicator(player: int) -> Control:
	var container := Control.new()
	container.layout_mode = 1
	container.z_index = 4
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.visible = false
	# P1: anchored left at x=92 | P2: anchored right, 84–168px from right edge
	if player == 0:
		container.anchor_left   = 0.0
		container.anchor_right  = 0.0
		container.anchor_top    = 0.0
		container.anchor_bottom = 0.0
		container.offset_left   = 92.0
		container.offset_right  = 168.0
	else:
		container.anchor_left   = 1.0
		container.anchor_right  = 1.0
		container.anchor_top    = 0.0
		container.anchor_bottom = 0.0
		container.offset_left   = -160.0
		container.offset_right  = -84.0
	container.offset_top    = 100.0
	container.offset_bottom = 196.0
	add_child(container)

	# 3 stacked card panels (back to front)
	for i in range(3):
		var cp := Panel.new()
		cp.layout_mode = 0
		var off: float = float(2 - i) * 3.0
		cp.position = Vector2(off, off)
		cp.size = Vector2(60.0, 82.0)
		cp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color(0.05, 0.16, 0.07)
		csb.border_width_left   = 1
		csb.border_width_top    = 1
		csb.border_width_right  = 1
		csb.border_width_bottom = 1
		csb.border_color = Color(0.20, 0.90, 0.40, float(i + 1) * 0.28)
		csb.corner_radius_top_left     = 4
		csb.corner_radius_top_right    = 4
		csb.corner_radius_bottom_right = 4
		csb.corner_radius_bottom_left  = 4
		cp.add_theme_stylebox_override("panel", csb)
		container.add_child(cp)

	var tech_lbl := Label.new()
	tech_lbl.layout_mode = 0
	tech_lbl.position = Vector2(6.0, 28.0)
	tech_lbl.size = Vector2(48.0, 20.0)
	tech_lbl.text = "TECH"
	tech_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tech_lbl.add_theme_font_size_override("font_size", 10)
	tech_lbl.add_theme_color_override("font_color", Color(0.25, 0.92, 0.45, 0.90))
	tech_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(tech_lbl)

	var count_lbl := Label.new()
	count_lbl.layout_mode = 0
	count_lbl.position = Vector2(46.0, 62.0)
	count_lbl.size = Vector2(26.0, 26.0)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82))
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(count_lbl)

	if player == 0:
		_p1_stack_count_lbl = count_lbl
	else:
		_p2_stack_count_lbl = count_lbl

	# Click / tap to open modal (same mechanism as void stack)
	container.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) \
				or (ev is InputEventScreenTouch and ev.pressed):
			_open_tech_modal(player)
			get_viewport().set_input_as_handled())

	return container

func _open_tech_modal(player: int) -> void:
	if player != GameState.current_player:
		return
	_refresh_tech_hand()

func _update_tech_stacks() -> void:
	var phase := GameState.current_phase
	var in_battle := phase not in [GameState.Phase.NONE, GameState.Phase.SETUP_P1,
			GameState.Phase.SETUP_P2, GameState.Phase.GAME_OVER]
	for p in range(2):
		var stack: Control = _p1_tech_stack if p == 0 else _p2_tech_stack
		var lbl: Label     = _p1_stack_count_lbl if p == 0 else _p2_stack_count_lbl
		if stack:
			stack.visible = in_battle
			# Grey out when tech has already been used this turn
			stack.modulate = Color(0.38, 0.38, 0.38, 0.65) if _tech_used_this_turn[p] \
				else Color(1.0, 1.0, 1.0, 1.0)
		if lbl:
			lbl.text = str(GameState.tech_hands[p].size())

func _open_tech_overlay(player: int) -> void:
	_tech_overlay_player = player
	_rebuild_tech_overlay_content(player)
	# Position below the stack, pinned to the correct screen edge
	_tech_overlay_panel.layout_mode = 0
	var vp_w := get_viewport().get_visible_rect().size.x
	if player == 0:
		_tech_overlay_panel.position = Vector2(8.0, 202.0)
	else:
		# Right-align: overlay is 240px wide, 8px margin from right edge
		_tech_overlay_panel.position = Vector2(vp_w - 248.0, 202.0)
	_tech_overlay_panel.visible = true

func _close_tech_overlay() -> void:
	_tech_overlay_close_pending = false
	if _tech_overlay_panel:
		_tech_overlay_panel.visible = false
	_tech_overlay_player = -1

func _rebuild_tech_overlay_content(player: int) -> void:
	for ch in _tech_overlay_panel.get_children():
		ch.queue_free()

	var hand: Array = GameState.tech_hands[player]
	var is_tech_mode := GameState.current_phase == GameState.Phase.TECH \
			and player == GameState.current_player
	var crystals: int = GameState.crystals[player]

	# Card image dimensions — 819:1126 aspect ratio
	const CARD_W  : float = 72.0
	const CARD_H  : float = 99.0
	const GAP     : float = 4.0
	const PAD     : float = 8.0
	const TITLE_H : float = 30.0
	const BTN_H   : float = 24.0

	var n: int = hand.size()
	# Center cards horizontally within 240px
	var group_w: float = n * CARD_W + maxf(n - 1, 0) * GAP
	var start_x: float = PAD + (224.0 - group_w) * 0.5
	var card_y  : float = TITLE_H
	var btn_y   : float = card_y + CARD_H + 4.0
	var total_h : float = btn_y + (BTN_H + 4.0 if is_tech_mode else 0.0) + PAD

	_tech_overlay_panel.size = Vector2(240.0, maxf(total_h, TITLE_H + PAD))

	var title := Label.new()
	title.layout_mode = 0
	title.position = Vector2(PAD, 6.0)
	title.size = Vector2(224.0, 20.0)
	title.text = "TECH HAND  (%d)" % n
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.30, 0.85, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tech_overlay_panel.add_child(title)

	if n == 0:
		var empty := Label.new()
		empty.layout_mode = 0
		empty.position = Vector2(PAD, card_y)
		empty.size = Vector2(224.0, 20.0)
		empty.text = "No tech cards"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 10)
		empty.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tech_overlay_panel.add_child(empty)
		_tech_overlay_panel.size = Vector2(240.0, TITLE_H + 30.0)
		return

	for i in range(n):
		var tech_name: String = str(hand[i])
		var data: TechCardData = CardDatabase.get_tech(tech_name)
		var cx: float = start_x + i * (CARD_W + GAP)

		# Full card image
		var img := TextureRect.new()
		img.layout_mode = 0
		img.position = Vector2(cx, card_y)
		img.size = Vector2(CARD_W, CARD_H)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var snake: String = tech_name.to_lower() \
			.replace(" ", "_").replace("'", "").replace("-", "_")
		var path: String = "res://assets/textures/cards/full_cards/" + snake + ".png"
		if not ResourceLoader.exists(path):
			path = "res://assets/textures/cards/full_cards/tech_" + snake + ".png"
		if ResourceLoader.exists(path):
			img.texture = load(path)
		_tech_overlay_panel.add_child(img)

		# USE button — only in TECH mode
		if is_tech_mode and data != null:
			var use_btn := Button.new()
			use_btn.layout_mode = 0
			use_btn.position = Vector2(cx, btn_y)
			use_btn.size = Vector2(CARD_W, BTN_H)
			use_btn.text = "USE"
			use_btn.disabled = crystals < data.crystal_cost
			use_btn.add_theme_font_size_override("font_size", 10)
			var captured: String = tech_name
			use_btn.pressed.connect(func() -> void:
				_close_tech_overlay()
				_on_tech_card_btn(captured))
			_tech_overlay_panel.add_child(use_btn)

# ─────────────────────────────────────────────────────────────
# Dump Stacks
# ─────────────────────────────────────────────────────────────

func _build_void_stacks() -> void:
	# P1: Dump at x=8 (left of tech at x=92)
	# P2: Dump at x=1280 (right of tech at x=1196)
	_p1_void_stack = _create_void_stack_indicator(0)
	_p2_void_stack = _create_void_stack_indicator(1)

func _create_void_stack_indicator(player: int) -> Control:
	var container := Control.new()
	container.layout_mode = 1
	container.z_index = 4
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.visible = false
	# P1: anchored left at x=8 | P2: anchored right, 8–84px from right edge
	if player == 0:
		container.anchor_left   = 0.0
		container.anchor_right  = 0.0
		container.anchor_top    = 0.0
		container.anchor_bottom = 0.0
		container.offset_left   = 8.0
		container.offset_right  = 84.0
	else:
		container.anchor_left   = 1.0
		container.anchor_right  = 1.0
		container.anchor_top    = 0.0
		container.anchor_bottom = 0.0
		container.offset_left   = -80.0
		container.offset_right  = -4.0
	container.offset_top    = 100.0
	container.offset_bottom = 196.0
	add_child(container)

	# 3 stacked card backs (reddish tint)
	for i in range(3):
		var cp := Panel.new()
		cp.layout_mode = 0
		var off: float = float(2 - i) * 3.0
		cp.position = Vector2(off, off)
		cp.size = Vector2(60.0, 82.0)
		cp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color(0.10, 0.05, 0.18)
		csb.border_width_left   = 1
		csb.border_width_top    = 1
		csb.border_width_right  = 1
		csb.border_width_bottom = 1
		csb.border_color = Color(0.65, 0.30, 1.0, float(i + 1) * 0.28)
		csb.corner_radius_top_left     = 4
		csb.corner_radius_top_right    = 4
		csb.corner_radius_bottom_right = 4
		csb.corner_radius_bottom_left  = 4
		cp.add_theme_stylebox_override("panel", csb)
		container.add_child(cp)

	var dump_lbl := Label.new()
	dump_lbl.layout_mode = 0
	dump_lbl.position = Vector2(6.0, 28.0)
	dump_lbl.size = Vector2(48.0, 20.0)
	dump_lbl.text = "VOID"
	dump_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dump_lbl.add_theme_font_size_override("font_size", 10)
	dump_lbl.add_theme_color_override("font_color", Color(0.75, 0.40, 1.0, 0.90))
	dump_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(dump_lbl)

	var count_lbl := Label.new()
	count_lbl.layout_mode = 0
	count_lbl.position = Vector2(46.0, 62.0)
	count_lbl.size = Vector2(26.0, 26.0)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", Color(0.88, 0.72, 1.0))
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_lbl.text = "0"
	container.add_child(count_lbl)

	if player == 0:
		_p1_void_count_lbl = count_lbl
	else:
		_p2_void_count_lbl = count_lbl

	# Click opens void modal for own pile only
	container.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) \
				or (ev is InputEventScreenTouch and ev.pressed):
			_open_void_modal(player)
			get_viewport().set_input_as_handled())

	return container

func _update_void_stacks() -> void:
	var phase := GameState.current_phase
	var in_battle := phase not in [GameState.Phase.NONE, GameState.Phase.SETUP_P1,
			GameState.Phase.SETUP_P2, GameState.Phase.GAME_OVER]
	if _p1_void_stack:
		_p1_void_stack.visible = in_battle
		if _p1_void_count_lbl:
			_p1_void_count_lbl.text = str(_void_piles[0].size())
	if _p2_void_stack:
		_p2_void_stack.visible = in_battle
		if _p2_void_count_lbl:
			_p2_void_count_lbl.text = str(_void_piles[1].size())

func _open_void_modal(player: int) -> void:
	if _void_modal != null:
		_void_modal.queue_free()
		_void_modal = null

	_void_modal = Control.new()
	_void_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_void_modal.z_index = 10
	add_child(_void_modal)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.80)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed) \
				or (ev is InputEventScreenTouch and ev.pressed):
			if _void_modal != null:
				_void_modal.queue_free()
				_void_modal = null)
	_void_modal.add_child(dimmer)

	# Panel with margin
	var panel_c := PanelContainer.new()
	panel_c.layout_mode = 1
	panel_c.anchor_left   = 0.0
	panel_c.anchor_top    = 0.0
	panel_c.anchor_right  = 1.0
	panel_c.anchor_bottom = 1.0
	panel_c.offset_left   = 20.0
	panel_c.offset_top    = 20.0
	panel_c.offset_right  = -20.0
	panel_c.offset_bottom = -20.0
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.07, 0.04, 0.12, 0.98)
	psb.border_width_left   = 2
	psb.border_width_top    = 2
	psb.border_width_right  = 2
	psb.border_width_bottom = 2
	psb.border_color = Color(0.65, 0.30, 1.0, 0.55)
	psb.corner_radius_top_left     = 8
	psb.corner_radius_top_right    = 8
	psb.corner_radius_bottom_left  = 8
	psb.corner_radius_bottom_right = 8
	psb.content_margin_left   = 20
	psb.content_margin_right  = 20
	psb.content_margin_top    = 12
	psb.content_margin_bottom = 20
	panel_c.add_theme_stylebox_override("panel", psb)
	_void_modal.add_child(panel_c)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel_c.add_child(vbox)

	# Title row
	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)

	var title := Label.new()
	var p_name := _player_names[player]
	var pile: Array = _void_piles[player]
	title.text = "%s — Void Pile  (%d card%s)" % [p_name, pile.size(),
		"s" if pile.size() != 1 else ""]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.80, 0.50, 1.0))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(90.0, 36.0)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.pressed.connect(func() -> void:
		if _void_modal != null:
			_void_modal.queue_free()
			_void_modal = null)
	title_row.add_child(close_btn)

	# Scrollable card grid
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(flow)

	const CARD_W : float = 160.0
	const CARD_H : float = 220.0   # ≈ 819:1126 aspect

	if pile.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No cards destroyed yet."
		empty_lbl.add_theme_font_size_override("font_size", 16)
		empty_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		flow.add_child(empty_lbl)
	else:
		for entry: Variant in pile:
			var card_name: String = str(entry.get("card_name", ""))
			var card_type: String = str(entry.get("card_type", ""))
			var snake: String = card_name.to_lower() \
				.replace(" ", "_").replace("'", "").replace("-", "_")
			var path: String = "res://assets/textures/cards/full_cards/" + snake + ".png"
			if not ResourceLoader.exists(path):
				match card_type:
					"tech": path = "res://assets/textures/cards/full_cards/tech_" + snake + ".png"
					_:      path = ""

			var img := TextureRect.new()
			img.custom_minimum_size = Vector2(CARD_W, CARD_H)
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if ResourceLoader.exists(path):
				img.texture = load(path)
			flow.add_child(img)

# ─────────────────────────────────────────────────────────────
# Reveal (Peek) Buttons
# ─────────────────────────────────────────────────────────────

func _build_reveal_buttons() -> void:
	for player in range(2):
		var btn := Button.new()
		btn.text = "ENEMY VIEW"
		btn.layout_mode = 1
		btn.z_index = 4
		btn.visible = false
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		if player == 0:
			btn.anchor_left   = 0.0; btn.anchor_right  = 0.0
			btn.offset_left   = 8.0; btn.offset_right  = 168.0
		else:
			btn.anchor_left   = 1.0; btn.anchor_right  = 1.0
			btn.offset_left   = -168.0; btn.offset_right = -8.0
		btn.offset_top    = 202.0
		btn.offset_bottom = 232.0
		btn.anchor_top    = 0.0
		btn.anchor_bottom = 0.0
		# Style — silver-cyan border, dark translucent bg
		var sbox := StyleBoxFlat.new()
		sbox.bg_color = Color(0.05, 0.10, 0.14, 0.88)
		sbox.border_width_left = 1; sbox.border_width_right  = 1
		sbox.border_width_top  = 1; sbox.border_width_bottom = 1
		sbox.border_color = Color(0.55, 0.80, 0.90, 0.85)
		sbox.corner_radius_top_left     = 4; sbox.corner_radius_top_right    = 4
		sbox.corner_radius_bottom_left  = 4; sbox.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", sbox)
		var sbox_hover := sbox.duplicate() as StyleBoxFlat
		sbox_hover.bg_color = Color(0.10, 0.20, 0.28, 0.95)
		btn.add_theme_stylebox_override("hover", sbox_hover)
		var sbox_press := sbox.duplicate() as StyleBoxFlat
		sbox_press.bg_color = Color(0.15, 0.30, 0.40, 1.0)
		btn.add_theme_stylebox_override("pressed", sbox_press)
		btn.add_theme_color_override("font_color", Color(0.70, 0.92, 1.0, 1.0))
		btn.add_theme_font_size_override("font_size", 11)
		var p := player
		btn.pressed.connect(func() -> void: _toggle_reveal_preview(p))
		add_child(btn)
		if player == 0: _p1_reveal_btn = btn
		else:           _p2_reveal_btn = btn

func _toggle_reveal_preview(player: int) -> void:
	# Only the active player may toggle their own peek
	if player != GameState.current_player:
		return
	_reveal_preview[player] = not _reveal_preview[player]
	_enemy_view_active = not _reveal_preview[player]
	var btn: Button = _p1_reveal_btn if player == 0 else _p2_reveal_btn
	if btn:
		btn.text = "YOUR VIEW" if _reveal_preview[player] else "ENEMY VIEW"
	# Apply peek state and enemy-view flag to all cards
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			grid_nodes[player][r][c].set_preview_revealed(_reveal_preview[player])
	for p in range(2):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				grid_nodes[p][r][c].set_enemy_view(_enemy_view_active)
	if _enemy_view_active:
		_clear_highlights()

func _reset_reveal_previews() -> void:
	_enemy_view_active = false
	for p in range(2):
		var btn: Button = _p1_reveal_btn if p == 0 else _p2_reveal_btn
		if _reveal_preview[p]:
			_reveal_preview[p] = false
			if btn:
				btn.text = "ENEMY VIEW"
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				grid_nodes[p][r][c].set_preview_revealed(false)
				grid_nodes[p][r][c].set_enemy_view(false)

func _update_reveal_buttons() -> void:
	var in_battle: bool = GameState.current_phase not in [
		GameState.Phase.NONE, GameState.Phase.SETUP_P1,
		GameState.Phase.SETUP_P2, GameState.Phase.GAME_OVER
	]
	if _p1_reveal_btn:
		_p1_reveal_btn.visible = in_battle and GameState.current_player == 0
	if _p2_reveal_btn:
		var vs_ai: bool = GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN]
		_p2_reveal_btn.visible = in_battle and GameState.current_player == 1 and not vs_ai

# ─────────────────────────────────────────────────────────────
# End Turn Button (standalone, bottom-center)
# ─────────────────────────────────────────────────────────────

func _build_end_turn_button() -> void:
	# Image is 1216×832 → ratio ≈ 1.46 : 1
	# Display at 160×110 px, centered below turn number label
	_end_turn_btn = TextureButton.new()
	_end_turn_btn.texture_normal = load("res://assets/textures/ui/decorations/ui_end_turn.png")
	_end_turn_btn.ignore_texture_size = true
	_end_turn_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_end_turn_btn.layout_mode = 1
	_end_turn_btn.anchor_left   = 0.5
	_end_turn_btn.anchor_top    = 0.0
	_end_turn_btn.anchor_right  = 0.5
	_end_turn_btn.anchor_bottom = 0.0
	_end_turn_btn.offset_left   = -80.0
	_end_turn_btn.offset_top    = 78.0
	_end_turn_btn.offset_right  =  80.0
	_end_turn_btn.offset_bottom = 188.0
	_end_turn_btn.z_index = 4
	_end_turn_btn.visible = false
	_end_turn_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_end_turn_btn.pressed.connect(_on_end_turn_requested)
	add_child(_end_turn_btn)

# ─────────────────────────────────────────────────────────────
# Attack Confirm Panel (floating, shown during CONFIRMING_ATTACK)
# ─────────────────────────────────────────────────────────────

func _build_attack_confirm_panel() -> void:
	_attack_confirm_panel = Control.new()
	_attack_confirm_panel.layout_mode = 1
	_attack_confirm_panel.anchor_left   = 0.5
	_attack_confirm_panel.anchor_top    = 0.5
	_attack_confirm_panel.anchor_right  = 0.5
	_attack_confirm_panel.anchor_bottom = 0.5
	_attack_confirm_panel.offset_left   = -160.0
	_attack_confirm_panel.offset_top    = -65.0
	_attack_confirm_panel.offset_right  =  160.0
	_attack_confirm_panel.offset_bottom =  65.0
	_attack_confirm_panel.z_index = 6
	_attack_confirm_panel.visible = false
	add_child(_attack_confirm_panel)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.08, 0.18, 0.96)
	bg.border_width_left   = 2
	bg.border_width_top    = 2
	bg.border_width_right  = 2
	bg.border_width_bottom = 2
	bg.border_color = Color(1.0, 0.35, 0.25, 0.85)
	bg.corner_radius_top_left     = 8
	bg.corner_radius_top_right    = 8
	bg.corner_radius_bottom_right = 8
	bg.corner_radius_bottom_left  = 8
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", bg)
	_attack_confirm_panel.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   =  12.0
	vbox.offset_top    =  10.0
	vbox.offset_right  = -12.0
	vbox.offset_bottom = -10.0
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_attack_confirm_panel.add_child(vbox)

	var lbl := Label.new()
	lbl.text = "Confirm Attack?"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.6, 1.0))
	vbox.add_child(lbl)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var confirm_btn := Button.new()
	confirm_btn.text = "ATTACK"
	confirm_btn.custom_minimum_size = Vector2(100, 36)
	confirm_btn.add_theme_font_size_override("font_size", 14)
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.55, 0.12, 0.08, 1.0)
	csb.border_width_left   = 2; csb.border_width_top    = 2
	csb.border_width_right  = 2; csb.border_width_bottom = 2
	csb.border_color = Color(1.0, 0.35, 0.2, 0.9)
	csb.corner_radius_top_left = 5; csb.corner_radius_top_right = 5
	csb.corner_radius_bottom_right = 5; csb.corner_radius_bottom_left = 5
	confirm_btn.add_theme_stylebox_override("normal", csb)
	confirm_btn.pressed.connect(_confirm_attack)
	hbox.add_child(confirm_btn)

	var cancel_btn2 := Button.new()
	cancel_btn2.text = "CANCEL"
	cancel_btn2.custom_minimum_size = Vector2(100, 36)
	cancel_btn2.add_theme_font_size_override("font_size", 14)
	var xsb := StyleBoxFlat.new()
	xsb.bg_color = Color(0.08, 0.10, 0.22, 1.0)
	xsb.border_width_left   = 2; xsb.border_width_top    = 2
	xsb.border_width_right  = 2; xsb.border_width_bottom = 2
	xsb.border_color = Color(0.38, 0.65, 1.0, 0.6)
	xsb.corner_radius_top_left = 5; xsb.corner_radius_top_right = 5
	xsb.corner_radius_bottom_right = 5; xsb.corner_radius_bottom_left = 5
	cancel_btn2.add_theme_stylebox_override("normal", xsb)
	cancel_btn2.pressed.connect(_cancel_confirm_attack)
	hbox.add_child(cancel_btn2)

# ─────────────────────────────────────────────────────────────
# Card Context Menu
# ─────────────────────────────────────────────────────────────

const CTX_ICON_ATTACK: Texture2D = preload("res://assets/textures/ui/decorations/ui_context_menu_attack.png")
const CTX_ICON_INFO:   Texture2D = preload("res://assets/textures/ui/decorations/ui_context_menu_info.png")
const CTX_ICON_BLUFF:  Texture2D = preload("res://assets/textures/ui/decorations/ui_context_menu_bluff.png")
const CTX_ICON_UNION:  Texture2D = preload("res://assets/textures/ui/decorations/ui_icon_union.png")

func _show_card_context(ctx_player: int, row: int, col: int) -> void:
	# Close any existing popup first
	_hide_card_context()

	_context_card_player = ctx_player
	_context_card_pos = Vector2i(row, col)

	# ── Enemy-view simulation: only own cards get a "SWITCH VIEW" button ──
	if _enemy_view_active:
		if ctx_player != GameState.current_player:
			return  # no menu for opponent cards during simulation
		_build_enemy_view_context_popup(row, col)
		return

	var card: GameState.CardInstance = GameState.get_card(ctx_player, row, col)
	var current_player := GameState.current_player

	var can_attack: bool = (
		ctx_player == current_player
		and card.card_type == "character"
		and not card.attacked_this_turn
		and card.cannot_attack_until < GameState.turn_number
		and GameState.attacks_remaining > 0
		and (GameState.berserk_active[current_player] == null
			or GameState.berserk_active[current_player] == card)
	)
	var can_info: bool  = (card.card_type != "dead_end" and card.card_name != "")
	var can_bluff: bool = (ctx_player == current_player)
	var _union_phase_ok: bool = GameState.current_phase in [GameState.Phase.MODE_SELECT, GameState.Phase.ATTACK]
	var _available_unions: Array = UnionDatabase.find_available_unions(ctx_player, row, col) if (
		ctx_player == current_player
		and card.card_type == "character"
		and _union_phase_ok
	) else []
	var can_union: bool = _available_unions.size() > 0

	if not can_attack and not can_info and not can_bluff and not can_union:
		return

	# ── Fullscreen backdrop — catches outside clicks to dismiss ──
	var backdrop := Control.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.z_index = 9
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_hide_card_context())
	add_child(backdrop)
	_context_backdrop = backdrop

	# ── Build fresh popup node ────────────────────────────────
	var popup := Panel.new()
	popup.z_index = 10
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 0.97)
	sb.border_width_left   = 2; sb.border_width_top    = 2
	sb.border_width_right  = 2; sb.border_width_bottom = 2
	sb.border_color = Color(0.45, 0.70, 1.0, 0.70)
	sb.corner_radius_top_left     = 7; sb.corner_radius_top_right    = 7
	sb.corner_radius_bottom_right = 7; sb.corner_radius_bottom_left  = 7
	popup.add_theme_stylebox_override("panel", sb)
	add_child(popup)
	_context_popup = popup

	var hbox := HBoxContainer.new()
	hbox.layout_mode = 1
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 8.0; hbox.offset_top    = 8.0
	hbox.offset_right = -8.0; hbox.offset_bottom = -8.0
	hbox.add_theme_constant_override("separation", 6)
	popup.add_child(hbox)

	# Snapshot position BEFORE callbacks alter member vars
	var snap_player: int = ctx_player
	var snap_pos: Vector2i = Vector2i(row, col)

	if can_attack:
		var btn := _make_context_icon_btn(CTX_ICON_ATTACK)
		btn.pressed.connect(func() -> void:
			_hide_card_context()
			_clear_selection()
			selected_attacker_pos = snap_pos
			grid_nodes[snap_player][snap_pos.x][snap_pos.y].set_selected(true)
			_set_selection_state(SelectionState.SELECTING_TARGET)
			_highlight_valid_targets()
		)
		hbox.add_child(btn)

	if can_info:
		var card_name_snap: String = card.card_name
		var card_type_snap: String = card.card_type
		var player_snap: int = ctx_player
		var row_snap: int = row
		var col_snap: int = col
		var btn := _make_context_icon_btn(CTX_ICON_INFO)
		btn.pressed.connect(func() -> void:
			_hide_card_context()
			var inst_snap: Variant = GameState.get_card(player_snap, row_snap, col_snap)
			CardDetailOverlay.open(self, card_name_snap, card_type_snap, inst_snap)
		)
		hbox.add_child(btn)

	if can_bluff:
		var bluff_snap_player: int = ctx_player
		var bluff_snap_row: int = row
		var bluff_snap_col: int = col
		var btn := _make_context_icon_btn(CTX_ICON_BLUFF)
		btn.pressed.connect(func() -> void:
			_hide_card_context()
			_show_bluff_modal_board(bluff_snap_player, bluff_snap_row, bluff_snap_col)
		)
		hbox.add_child(btn)

	if can_union:
		var union_snap_player: int = ctx_player
		var union_snap_available: Array = _available_unions
		var ubtn := _make_context_icon_btn(CTX_ICON_UNION)
		ubtn.pressed.connect(func() -> void:
			_hide_card_context()
			_open_union_modal(union_snap_player, union_snap_available)
		)
		hbox.add_child(ubtn)

	# ── Size and position: horizontal strip above the cursor ──
	const ICON_SZ: float = 52.0
	const PAD: float     = 8.0
	const SEP: float     = 6.0
	var btn_count: int   = int(can_attack) + int(can_info) + int(can_bluff) + int(can_union)
	var popup_w: float   = btn_count * ICON_SZ + maxf(float(btn_count - 1), 0.0) * SEP + PAD * 2.0
	var popup_h: float   = ICON_SZ + PAD * 2.0

	var screen: Vector2 = get_viewport_rect().size
	var px: float = _last_click_pos.x - popup_w * 0.5
	px = clampf(px, 4.0, screen.x - popup_w - 4.0)
	var py: float = _last_click_pos.y - popup_h - 8.0
	if py < 4.0:
		py = _last_click_pos.y + 8.0
	py = clampf(py, 4.0, screen.y - popup_h - 4.0)

	popup.position = Vector2(px, py)
	popup.size     = Vector2(popup_w, popup_h)

func _make_context_icon_btn(tex: Texture2D) -> Button:
	var btn := Button.new()
	btn.icon = tex
	btn.expand_icon = false
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	btn.custom_minimum_size = Vector2(52.0, 52.0)
	btn.add_theme_constant_override("icon_max_width", 36)
	btn.add_theme_constant_override("h_separation", 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.24, 1.0)
	sb.corner_radius_top_left     = 6; sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_right = 6; sb.corner_radius_bottom_left  = 6
	btn.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(0.14, 0.22, 0.44, 1.0)
	btn.add_theme_stylebox_override("hover", sbh)
	var sbp := sbh.duplicate() as StyleBoxFlat
	sbp.bg_color = Color(0.20, 0.30, 0.56, 1.0)
	btn.add_theme_stylebox_override("pressed", sbp)
	return btn

func _make_context_btn(label: String, col: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0.0, 40.0)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", col)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.24, 1.0)
	sb.border_width_left   = 0; sb.border_width_top    = 0
	sb.border_width_right  = 0; sb.border_width_bottom = 1
	sb.border_color = Color(col.r, col.g, col.b, 0.25)
	sb.corner_radius_top_left     = 4; sb.corner_radius_top_right    = 4
	sb.corner_radius_bottom_right = 4; sb.corner_radius_bottom_left  = 4
	btn.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(0.10, 0.16, 0.36, 1.0)
	btn.add_theme_stylebox_override("hover", sbh)
	return btn

const BLUFF_EMOJIS_BOARD: Array = ["😃","🥺","🤣","😎","❤️","☠️","🧨","👍","🤝","🖕"]
func _get_bluff_emojis_board() -> Array:
	if SaveManager.nsfw_enabled:
		return BLUFF_EMOJIS_BOARD.map(func(e: String) -> String: return "💩" if e == "🖕" else e)
	return BLUFF_EMOJIS_BOARD

func _refresh_all_bluff_labels() -> void:
	for p in range(2):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				(bluff_labels[p][r][c] as Label).text = GameState.get_bluff(p, r, c)

func _refresh_bluff_label(player: int, row: int, col: int) -> void:
	(bluff_labels[player][row][col] as Label).text = GameState.get_bluff(player, row, col)

func _show_bluff_modal_board(player: int, row: int, col: int) -> void:
	# Remove any existing bluff modal
	var existing: Node = get_node_or_null("BluffModalBoard")
	if existing:
		existing.queue_free()

	var backdrop := Control.new()
	backdrop.name = "BluffModalBoard"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.z_index = 50
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(dim)

	backdrop.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			backdrop.queue_free())

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

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox)

	var snap_player: int = player
	var snap_row: int    = row
	var snap_col: int    = col

	for emoji in _get_bluff_emojis_board():
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
			GameState.set_bluff(snap_player, snap_row, snap_col, snap_emoji)
			_refresh_bluff_label(snap_player, snap_row, snap_col)
			backdrop.queue_free())
		hbox.add_child(btn)

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
		GameState.set_bluff(snap_player, snap_row, snap_col, "")
		_refresh_bluff_label(snap_player, snap_row, snap_col)
		backdrop.queue_free())
	vbox.add_child(clear_btn)

	panel.custom_minimum_size = Vector2(520.0, 130.0)
	await get_tree().process_frame
	var vs: Vector2 = get_viewport_rect().size
	panel.position = Vector2((vs.x - panel.size.x) * 0.5, (vs.y - panel.size.y) * 0.5)

func _hide_card_context() -> void:
	if is_instance_valid(_context_backdrop):
		_context_backdrop.queue_free()
	_context_backdrop = null
	if is_instance_valid(_context_popup):
		_context_popup.queue_free()
	_context_popup = null
	_context_card_player = -1
	_context_card_pos = Vector2i(-1, -1)

# ─────────────────────────────────────────────────────────────
# Union Summon
# ─────────────────────────────────────────────────────────────
var _union_modal: Node = null
var _union_highlighted_cells: Array = []
var _union_highlighted_player: int = -1
# Pending union material selection state
var _pending_union_data: UnionData = null
var _pending_union_player: int = -1
var _pending_union_zone_cells: Array = []
var _pending_union_conditions_remaining: Array = []
var _pending_union_selected_materials: Array = []   # Array[Vector2i]
var _union_flash_nodes: Array = []                  # Array[Card nodes]

func _open_union_modal(player: int, available: Array) -> void:
	var modal: UnionModal = UnionModal.open(self, player, available)
	_union_modal = modal
	modal.union_selected.connect(_on_union_selected)
	modal.union_cancelled.connect(_on_union_modal_cancelled)

func _on_union_modal_cancelled() -> void:
	_union_modal = null

func _on_union_selected(player: int, union_name: String, zone_cells: Array) -> void:
	_union_modal = null
	var u: UnionData = UnionDatabase.get_union(union_name)
	if u == null:
		push_error("Union not found: " + union_name)
		return
	if GameState.crystals[player] < u.summon_cost:
		GameState.post_message("Not enough crystals.")
		return
	_enter_union_material_selection(player, u, zone_cells)

func _enter_union_material_selection(player: int, u: UnionData, zone_cells: Array) -> void:
	_pending_union_player = player
	_pending_union_data = u
	_pending_union_zone_cells = zone_cells.duplicate()
	_pending_union_conditions_remaining = u.material_conditions.duplicate()
	_pending_union_selected_materials.clear()
	_set_selection_state(SelectionState.SELECTING_UNION_MATERIALS)
	_refresh_union_flash_cells()
	GameState.post_message("Tap %d material card(s) on the field." % u.material_conditions.size())

func _compute_flash_cells() -> Array:
	# Cards in zone_cells that satisfy at least one remaining condition
	var flash: Array = []
	for cell: Vector2i in _pending_union_zone_cells:
		if cell in _pending_union_selected_materials:
			continue
		var card: GameState.CardInstance = GameState.get_card(_pending_union_player, cell.x, cell.y)
		if card.card_type != "character":
			continue
		for cond: Dictionary in _pending_union_conditions_remaining:
			if UnionDatabase.card_satisfies_condition(card, cond):
				flash.append(cell)
				break
	return flash

func _refresh_union_flash_cells() -> void:
	_clear_union_flash_nodes()
	var cells: Array = _compute_flash_cells()
	for cell: Vector2i in cells:
		var node: Control = grid_nodes[_pending_union_player][cell.x][cell.y]
		if node.has_method("set_union_flash"):
			node.set_union_flash(true)
			_union_flash_nodes.append(node)

func _clear_union_flash_nodes() -> void:
	for node: Control in _union_flash_nodes:
		if is_instance_valid(node) and node.has_method("set_union_flash"):
			node.set_union_flash(false)
	_union_flash_nodes.clear()

func _on_union_material_tapped(pos: Vector2i) -> void:
	var card: GameState.CardInstance = GameState.get_card(_pending_union_player, pos.x, pos.y)
	# Find a remaining condition this card satisfies
	var matched_idx: int = -1
	for i: int in range(_pending_union_conditions_remaining.size()):
		if UnionDatabase.card_satisfies_condition(card, _pending_union_conditions_remaining[i]):
			matched_idx = i
			break
	if matched_idx < 0:
		return  # card doesn't satisfy any remaining condition, ignore tap
	_pending_union_selected_materials.append(pos)
	_pending_union_conditions_remaining.remove_at(matched_idx)
	if _pending_union_conditions_remaining.is_empty():
		_perform_pending_union()
	else:
		_refresh_union_flash_cells()
		GameState.post_message("%d more material(s) needed." % _pending_union_conditions_remaining.size())

func _perform_pending_union() -> void:
	_clear_union_flash_nodes()
	_set_selection_state(SelectionState.SELECTING_ATTACKER)
	var player: int = _pending_union_player
	var u: UnionData = _pending_union_data
	var first_cell: Vector2i = _pending_union_selected_materials[0]
	# Pay crystal cost
	GameState.lose_crystals(player, u.summon_cost)
	# Remove selected material cards (except the first which becomes the union)
	for i: int in range(1, _pending_union_selected_materials.size()):
		var cell: Vector2i = _pending_union_selected_materials[i]
		GameState.remove_union_material(player, cell.x, cell.y)
	# Place union at first selected cell
	GameState.place_union_card(player, first_cell.x, first_cell.y, u)
	# Record unlock (human players only)
	var human_player: bool = GameState.game_mode != GameState.GameMode.VS_AI or player == 0
	if human_player:
		SaveManager.unlock_union(u.card_name)
	# Clear pending state
	_pending_union_data = null
	_pending_union_player = -1
	_pending_union_zone_cells.clear()
	_pending_union_conditions_remaining.clear()
	_pending_union_selected_materials.clear()
	# Screen shake + refresh
	_do_union_shake()
	_refresh_all_grids()
	_highlight_attackable_chars()

func _cancel_union_material_selection() -> void:
	_clear_union_flash_nodes()
	_pending_union_data = null
	_pending_union_player = -1
	_pending_union_zone_cells.clear()
	_pending_union_conditions_remaining.clear()
	_pending_union_selected_materials.clear()
	_set_selection_state(SelectionState.SELECTING_ATTACKER)
	_highlight_attackable_chars()

func _set_union_zone_highlight(player: int, zone_cells: Array) -> void:
	_clear_union_zone_highlight()
	_union_highlighted_player = player
	for cell: Vector2i in zone_cells:
		grid_nodes[player][cell.x][cell.y].set_highlighted(true)
		_union_highlighted_cells.append(cell)

func _clear_union_zone_highlight() -> void:
	var p: int = _union_highlighted_player
	if p >= 0:
		for cell: Vector2i in _union_highlighted_cells:
			if cell.x >= 0 and cell.x < GameState.GRID_SIZE and cell.y >= 0 and cell.y < GameState.GRID_SIZE:
				grid_nodes[p][cell.x][cell.y].set_highlighted(false)
	_union_highlighted_cells.clear()
	_union_highlighted_player = -1

func _do_union_shake() -> void:
	var ml: Control = get_node("MainLayout")
	var origin: Vector2 = ml.position
	var t := create_tween()
	t.tween_property(ml, "position", origin + Vector2(8, 0), 0.04)
	t.tween_property(ml, "position", origin + Vector2(-8, 0), 0.04)
	t.tween_property(ml, "position", origin + Vector2(6, 0), 0.04)
	t.tween_property(ml, "position", origin + Vector2(-4, 0), 0.04)
	t.tween_property(ml, "position", origin, 0.04)

func _show_blank_context(ctx_player: int, row: int, col: int) -> void:
	_hide_card_context()

	# ── Fullscreen backdrop ───────────────────────────────────
	var backdrop := Control.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.z_index = 9
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_hide_card_context())
	add_child(backdrop)
	_context_backdrop = backdrop

	# ── Popup panel ───────────────────────────────────────────
	var popup := Panel.new()
	popup.z_index = 10
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 0.97)
	sb.border_width_left   = 2; sb.border_width_top    = 2
	sb.border_width_right  = 2; sb.border_width_bottom = 2
	sb.border_color = Color(0.45, 0.70, 1.0, 0.70)
	sb.corner_radius_top_left     = 7; sb.corner_radius_top_right    = 7
	sb.corner_radius_bottom_right = 7; sb.corner_radius_bottom_left  = 7
	popup.add_theme_stylebox_override("panel", sb)
	add_child(popup)
	_context_popup = popup

	var hbox := HBoxContainer.new()
	hbox.layout_mode = 1
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 8.0; hbox.offset_top    = 8.0
	hbox.offset_right = -8.0; hbox.offset_bottom = -8.0
	popup.add_child(hbox)

	var snap_player: int = ctx_player
	var snap_row: int    = row
	var snap_col: int    = col

	var btn := _make_context_icon_btn(CTX_ICON_BLUFF)
	btn.pressed.connect(func() -> void:
		_hide_card_context()
		_show_bluff_modal_board(snap_player, snap_row, snap_col))
	hbox.add_child(btn)

	# ── Size and position: icon strip above the cursor ────────
	var popup_w: float = 52.0 + 8.0 * 2.0
	var popup_h: float = 52.0 + 8.0 * 2.0

	var screen: Vector2 = get_viewport_rect().size
	var px: float = _last_click_pos.x - popup_w * 0.5
	px = clampf(px, 4.0, screen.x - popup_w - 4.0)
	var py: float = _last_click_pos.y - popup_h - 8.0
	if py < 4.0:
		py = _last_click_pos.y + 8.0
	py = clampf(py, 4.0, screen.y - popup_h - 4.0)

	popup.position = Vector2(px, py)
	popup.size     = Vector2(popup_w, popup_h)

func _build_enemy_view_context_popup(row: int, col: int) -> void:
	var backdrop := Control.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.z_index = 9
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_hide_card_context())
	add_child(backdrop)
	_context_backdrop = backdrop

	var popup := Panel.new()
	popup.z_index = 10
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 0.97)
	sb.border_width_left = 2; sb.border_width_top = 2
	sb.border_width_right = 2; sb.border_width_bottom = 2
	sb.border_color = Color(0.45, 0.70, 1.0, 0.70)
	sb.corner_radius_top_left = 7; sb.corner_radius_top_right = 7
	sb.corner_radius_bottom_right = 7; sb.corner_radius_bottom_left = 7
	popup.add_theme_stylebox_override("panel", sb)
	add_child(popup)
	_context_popup = popup

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 1
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 6.0; vbox.offset_top = 6.0
	vbox.offset_right = -6.0; vbox.offset_bottom = -6.0
	popup.add_child(vbox)

	var btn := _make_context_btn("YOUR VIEW", Color(0.65, 0.85, 1.0, 1.0))
	btn.pressed.connect(func() -> void:
		_hide_card_context()
		_toggle_reveal_preview(GameState.current_player))
	vbox.add_child(btn)

	var btn_h := 40.0
	var pad := 12.0
	var popup_h := btn_h + pad * 2.0
	var popup_w := 148.0
	var screen := get_viewport_rect().size
	var px := _last_click_pos.x - popup_w * 0.5
	px = clampf(px, 4.0, screen.x - popup_w - 4.0)
	var py := _last_click_pos.y - popup_h - 8.0
	if py < 4.0:
		py = _last_click_pos.y + 8.0
	py = clampf(py, 4.0, screen.y - popup_h - 4.0)
	popup.position = Vector2(px, py)
	popup.size = Vector2(popup_w, popup_h)

# ─────────────────────────────────────────────────────────────
# Corner Crystal Labels
# ─────────────────────────────────────────────────────────────

func _build_bottom_crystal_labels() -> void:
	const ICON_SIZE  : float = 48.0
	const FONT_SIZE  : int   = 40
	const NAME_SIZE  : int   = 14
	const TEXT_COLOR : Color = Color(0.85, 0.95, 1.0)
	const NAME_COLOR : Color = Color(0.7, 0.85, 1.0)
	const COL_H      : float = 88.0   # VBox height (name row + crystal row)
	const COL_W      : float = 300.0
	const MARGIN     : float = 12.0

	var crystal_tex: Texture2D = load(
		"res://assets/textures/ui/decorations/ui_crystal_indicator.png")

	# ── P1 — upper left ───────────────────────────────────────
	var p1_vbox := VBoxContainer.new()
	p1_vbox.layout_mode = 1
	p1_vbox.anchor_left   = 0.0; p1_vbox.anchor_right  = 0.0
	p1_vbox.anchor_top    = 0.0; p1_vbox.anchor_bottom = 0.0
	p1_vbox.offset_left   = MARGIN; p1_vbox.offset_right  = MARGIN + COL_W
	p1_vbox.offset_top    = MARGIN; p1_vbox.offset_bottom = MARGIN + COL_H
	p1_vbox.add_theme_constant_override("separation", 0)
	p1_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p1_vbox.z_index = 4
	p1_vbox.visible = false
	add_child(p1_vbox)
	_p1_crystal_row = p1_vbox

	_p1_name_lbl = Label.new()
	_p1_name_lbl.text = _player_names[0]
	_p1_name_lbl.add_theme_font_size_override("font_size", NAME_SIZE)
	_p1_name_lbl.add_theme_color_override("font_color", NAME_COLOR)
	_p1_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p1_vbox.add_child(_p1_name_lbl)

	var p1_crystal_hbox := HBoxContainer.new()
	p1_crystal_hbox.add_theme_constant_override("separation", 6)
	p1_crystal_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p1_vbox.add_child(p1_crystal_hbox)

	if crystal_tex:
		var icon := TextureRect.new()
		icon.texture = crystal_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN  # shifted upward
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p1_crystal_hbox.add_child(icon)
		_p1_crystal_icon = icon

	_p1_bottom_crystal = Label.new()
	_p1_bottom_crystal.text = str(GameState.crystals[0])
	_p1_bottom_crystal.add_theme_font_size_override("font_size", FONT_SIZE)
	_p1_bottom_crystal.add_theme_color_override("font_color", TEXT_COLOR)
	_p1_bottom_crystal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_p1_bottom_crystal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_p1_bottom_crystal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p1_crystal_hbox.add_child(_p1_bottom_crystal)

	# ── P2 — upper right ──────────────────────────────────────
	var p2_vbox := VBoxContainer.new()
	p2_vbox.layout_mode = 1
	p2_vbox.anchor_left   = 1.0; p2_vbox.anchor_right  = 1.0
	p2_vbox.anchor_top    = 0.0; p2_vbox.anchor_bottom = 0.0
	p2_vbox.offset_left   = -(MARGIN + COL_W); p2_vbox.offset_right  = -MARGIN
	p2_vbox.offset_top    = MARGIN;             p2_vbox.offset_bottom = MARGIN + COL_H
	p2_vbox.add_theme_constant_override("separation", 0)
	p2_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p2_vbox.z_index = 4
	p2_vbox.visible = false
	add_child(p2_vbox)
	_p2_crystal_row = p2_vbox

	_p2_name_lbl = Label.new()
	_p2_name_lbl.text = _player_names[1]
	_p2_name_lbl.add_theme_font_size_override("font_size", NAME_SIZE)
	_p2_name_lbl.add_theme_color_override("font_color", NAME_COLOR)
	_p2_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_p2_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p2_vbox.add_child(_p2_name_lbl)

	var p2_crystal_hbox := HBoxContainer.new()
	p2_crystal_hbox.alignment = BoxContainer.ALIGNMENT_END
	p2_crystal_hbox.add_theme_constant_override("separation", 6)
	p2_crystal_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p2_vbox.add_child(p2_crystal_hbox)

	_p2_bottom_crystal = Label.new()
	_p2_bottom_crystal.text = str(GameState.crystals[1])
	_p2_bottom_crystal.add_theme_font_size_override("font_size", FONT_SIZE)
	_p2_bottom_crystal.add_theme_color_override("font_color", TEXT_COLOR)
	_p2_bottom_crystal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_p2_bottom_crystal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_p2_bottom_crystal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p2_crystal_hbox.add_child(_p2_bottom_crystal)

	if crystal_tex:
		var icon2 := TextureRect.new()
		icon2.texture = crystal_tex
		icon2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon2.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon2.size_flags_vertical = Control.SIZE_SHRINK_BEGIN  # shifted upward
		icon2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p2_crystal_hbox.add_child(icon2)
		_p2_crystal_icon = icon2

func _update_crystal_visibility() -> void:
	var show := GameState.current_phase not in [
		GameState.Phase.NONE, GameState.Phase.SETUP_P1,
		GameState.Phase.SETUP_P2, GameState.Phase.GAME_OVER]
	if _p1_crystal_row:
		_p1_crystal_row.visible = show
	if _p2_crystal_row:
		_p2_crystal_row.visible = show
	if _turn_number_lbl:
		_turn_number_lbl.visible = show
	if _turn_number_bg:
		_turn_number_bg.visible = show
	if _options_btn:
		_options_btn.visible = show

func _build_turn_number_label() -> void:
	# Medallion background — upper half hidden above screen, lower half visible
	const MED_SIZE: float = 280.0
	var bg := TextureRect.new()
	bg.texture = load("res://assets/textures/ui/decorations/ui_turn_number_panel.png")
	bg.ignore_texture_size = true
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.layout_mode = 1
	bg.anchor_left   = 0.5; bg.anchor_right  = 0.5
	bg.anchor_top    = 0.0; bg.anchor_bottom = 0.0
	bg.offset_left   = -(MED_SIZE * 0.5)
	bg.offset_right  =  (MED_SIZE * 0.5)
	bg.offset_top    = -(MED_SIZE * 0.5)   # upper half above screen edge (clipped)
	bg.offset_bottom =   (MED_SIZE * 0.5)  # lower half visible
	bg.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 3
	bg.visible = false
	add_child(bg)
	_turn_number_bg = bg

	var lbl := Label.new()
	lbl.layout_mode = 1
	lbl.anchor_left   = 0.5; lbl.anchor_right  = 0.5
	lbl.anchor_top    = 0.0; lbl.anchor_bottom = 0.0
	lbl.offset_left   = -160.0; lbl.offset_right  = 160.0
	lbl.offset_top    = 10.0;   lbl.offset_bottom = 72.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 44)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	lbl.add_theme_constant_override("shadow_offset_x", 3)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 4
	lbl.visible = false
	lbl.text = "Turn 1"
	add_child(lbl)
	_turn_number_lbl = lbl

func _build_options_button() -> void:
	# Display size: 230×230. Show upper 2/3 (~153px), hide lower 1/3 (~77px) below screen.
	const BTN_W  : float = 230.0
	const BTN_H  : float = 230.0
	const SHOW_H : float = BTN_H * 2.0 / 3.0   # 120 px visible above bottom edge
	const HIDE_H : float = BTN_H - SHOW_H        # 60 px below screen edge (clipped)

	var btn := TextureButton.new()
	btn.texture_normal = load("res://assets/textures/ui/decorations/ui_battle_options.png")
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.layout_mode = 1
	btn.anchor_left   = 0.5;  btn.anchor_right  = 0.5
	btn.anchor_top    = 1.0;  btn.anchor_bottom = 1.0
	btn.offset_left   = -(BTN_W * 0.5)
	btn.offset_right  =  (BTN_W * 0.5)
	btn.offset_top    = -SHOW_H   # top edge = 120px above screen bottom
	btn.offset_bottom =  HIDE_H   # bottom edge = 60px below screen bottom (clipped)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.z_index = 5
	btn.visible = false
	btn.pressed.connect(_on_options_btn_pressed)
	add_child(btn)
	_options_btn = btn

func _on_options_btn_pressed() -> void:
	if _options_panel != null:
		return
	_show_options_panel()

# ─────────────────────────────────────────────────────────────
# Options Menu
# ─────────────────────────────────────────────────────────────

func _build_card_name_lookup() -> void:
	_card_name_to_type.clear()
	for n: String in CardDatabase.get_all_character_names():
		_card_name_to_type[n] = "character"
	for n: String in CardDatabase.get_all_trap_names():
		_card_name_to_type[n] = "trap"
	for n: String in CardDatabase.get_all_tech_names():
		_card_name_to_type[n] = "tech"

func _make_panel_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.12, 0.97)
	sb.border_color = Color(0.55, 0.75, 1.0, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(24)
	return sb

# Returns {dimmer, vbox}. Caller fills vbox, then calls _add_back_btn(vbox, dimmer).
func _make_sub_overlay(half_w: float = 420.0, half_h: float = 300.0) -> Dictionary:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.z_index = 55
	add_child(dimmer)

	var panel := PanelContainer.new()
	panel.layout_mode = 1
	panel.anchor_left = 0.5; panel.anchor_right  = 0.5
	panel.anchor_top  = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -half_w; panel.offset_right  =  half_w
	panel.offset_top  = -half_h; panel.offset_bottom =  half_h
	panel.add_theme_stylebox_override("panel", _make_panel_stylebox())
	dimmer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	return {"dimmer": dimmer, "vbox": vbox}

func _add_back_btn(vbox: VBoxContainer, dimmer: Control) -> void:
	var back_btn := Button.new()
	back_btn.text = "← BACK"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	back_btn.pressed.connect(func() -> void:
		dimmer.queue_free()
		_show_options_panel())
	vbox.add_child(back_btn)

func _show_options_panel() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.z_index = 50
	add_child(dimmer)
	_options_panel = dimmer

	var panel := PanelContainer.new()
	panel.layout_mode = 1
	panel.anchor_left = 0.5; panel.anchor_right  = 0.5
	panel.anchor_top  = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -190.0; panel.offset_right  = 190.0
	panel.offset_top  = -240.0; panel.offset_bottom = 240.0
	panel.add_theme_stylebox_override("panel", _make_panel_stylebox())
	dimmer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "OPTIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	var entries: Array = [
		["BATTLE LOG",    _show_battle_log_panel],
		["RULES",         _show_rules_panel],
		["SETTINGS",      _show_settings_panel],
		["CHANGE MUSIC",  _show_change_music_panel],
		["SURRENDER",     _show_surrender_confirm],
	]
	for entry: Array in entries:
		var btn := Button.new()
		btn.text = entry[0] as String
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 18)
		var cb: Callable = entry[1] as Callable
		btn.pressed.connect(func() -> void:
			_close_options_panel()
			cb.call())
		vbox.add_child(btn)

	vbox.add_child(HSeparator.new())

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(0, 38)
	close_btn.add_theme_font_size_override("font_size", 15)
	close_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	close_btn.pressed.connect(_close_options_panel)
	vbox.add_child(close_btn)

func _close_options_panel() -> void:
	if _options_panel != null:
		_options_panel.queue_free()
		_options_panel = null

# ─────────────────────────────────────────────────────────────
# Change Music sub-panel
# ─────────────────────────────────────────────────────────────
const MUSIC_TRACKS: Array = [
	{"label": "Battle Theme",     "path": "res://assets/audio/bgm_battle_1.mp3"},
	{"label": "Blind Cross (OST)","path": "res://assets/audio/bgm_ost_blind_cross.mp3"},
	{"label": "Heroic",           "path": "res://assets/audio/bgm_heroic.mp3"},
	{"label": "Boss Theme",       "path": "res://assets/audio/bgm_boss_1.mp3"},
	{"label": "Calm",             "path": "res://assets/audio/bgm_calm_1.mp3"},
	{"label": "Calm 2",           "path": "res://assets/audio/bgm_calm_2.mp3"},
	{"label": "Relaxed",          "path": "res://assets/audio/bgm_relaxed_1.mp3"},
	{"label": "Horror",           "path": "res://assets/audio/bgm_horror_1.mp3"},
]

func _show_change_music_panel() -> void:
	var has_disc := Collection.music_discs > 0
	var already_used := _music_changed_this_turn

	var overlay := _make_sub_overlay(340.0, 380.0)
	var vbox: VBoxContainer = overlay["vbox"]

	var title := Label.new()
	title.text = "CHANGE MUSIC  💿"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))
	vbox.add_child(title)

	var disc_lbl := Label.new()
	disc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disc_lbl.add_theme_font_size_override("font_size", 13)
	if already_used:
		disc_lbl.text = "Already changed music this turn."
		disc_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	elif not has_disc:
		disc_lbl.text = "No Music Discs available.\nBuy them in the Shop."
		disc_lbl.add_theme_color_override("font_color", Color(0.7, 0.5, 0.4))
	else:
		disc_lbl.text = "Owned: %d disc%s  — costs 1 to change" % [
			Collection.music_discs, "s" if Collection.music_discs != 1 else ""]
		disc_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.75))
	vbox.add_child(disc_lbl)

	vbox.add_child(HSeparator.new())

	var can_change := has_disc and not already_used
	for track: Dictionary in MUSIC_TRACKS:
		var btn := Button.new()
		btn.text = track["label"] as String
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 15)
		btn.disabled = not can_change
		var track_path: String = track["path"]
		btn.pressed.connect(func() -> void:
			if Collection.spend_music_disc():
				_music_changed_this_turn = true
				_change_battle_music(track_path)
				overlay["dimmer"].queue_free())
		vbox.add_child(btn)

	_add_back_btn(vbox, overlay["dimmer"])

func _change_battle_music(path: String) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if _battle_music != null:
		var fade := create_tween()
		fade.tween_property(_battle_music, "volume_db", -80.0, 0.5)
		await fade.finished
		_battle_music.stop()
		_battle_music.stream = stream
		_battle_music.play()
		var unfade := create_tween()
		unfade.tween_property(_battle_music, "volume_db",
			linear_to_db(GameState.battle_bgm_volume / 100.0), 0.5)
	GameState.battle_bgm_path = path

# ─────────────────────────────────────────────────────────────
# Battle Log sub-panel
# ─────────────────────────────────────────────────────────────

func _format_log_line(line: String) -> String:
	# Walk character-by-character; replace card names with BBCode [url] links.
	# Sort longest-first so "Iron Golem King" beats "Iron Golem".
	var sorted_names: Array = _card_name_to_type.keys()
	sorted_names.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	var result := ""
	var i := 0
	while i < line.length():
		var matched := false
		for cname: String in sorted_names:
			if line.substr(i, cname.length()) == cname:
				var ctype: String = _card_name_to_type[cname]
				result += "[url=%s|%s][color=#88CCFF][b]%s[/b][/color][/url]" % [cname, ctype, cname]
				i += cname.length()
				matched = true
				break
		if not matched:
			result += line[i]
			i += 1
	return result

func _show_battle_log_panel() -> void:
	var ovl: Dictionary = _make_sub_overlay(460.0, 340.0)
	var dimmer: Control = ovl["dimmer"]
	var vbox: VBoxContainer = ovl["vbox"]

	var header := Label.new()
	header.text = "BATTLE LOG"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(header)
	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.add_theme_font_size_override("normal_font_size", 14)
	rtl.add_theme_color_override("default_color", Color(0.88, 0.88, 0.92))
	scroll.add_child(rtl)

	if _battle_log_lines.is_empty():
		rtl.append_text("[color=#888888](No log entries yet.)[/color]")
	else:
		for line: String in _battle_log_lines:
			rtl.append_text(_format_log_line(line) + "\n")

	rtl.meta_clicked.connect(func(meta: Variant) -> void:
		var parts: PackedStringArray = str(meta).split("|")
		if parts.size() == 2:
			CardDetailOverlay.open(self, parts[0], parts[1]))

	_add_back_btn(vbox, dimmer)

	# Scroll to bottom after layout settles
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

# ─────────────────────────────────────────────────────────────
# Rules sub-panel
# ─────────────────────────────────────────────────────────────

func _show_rules_panel() -> void:
	var ovl: Dictionary = _make_sub_overlay(460.0, 340.0)
	var dimmer: Control = ovl["dimmer"]
	var vbox: VBoxContainer = ovl["vbox"]

	var header := Label.new()
	header.text = "RULES"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(header)
	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.add_theme_font_size_override("normal_font_size", 14)
	rtl.add_theme_color_override("default_color", Color(0.88, 0.88, 0.92))
	rtl.append_text(
		"[b]OBJECTIVE[/b]\nReduce your opponent's Crystals to 0.\n\n" +
		"[b]SETUP[/b]\nEach player places Characters and Traps face-down on their 5×5 grid.\n\n" +
		"[b]EACH TURN[/b]\nChoose ATTACK or TECH mode.\n" +
		"  [b]Attack[/b] — Pick one of your Characters to attack any opponent card.\n" +
		"  [b]Tech[/b]   — Play one Tech card from your hand.\n\n" +
		"[b]BATTLE RESOLUTION[/b]\nAttacker ATK vs Defender DEF.\n" +
		"Loser pays Crystal cost. Attacker wins ties.\n\n" +
		"[b]SKIP TAX[/b]\nEnding your turn without attacking costs Crystals.\n" +
		"The tax doubles with every skip (50 → 100 → 200 → …).\n\n" +
		"[b]TRAPS[/b]\nTriggered when attacked. Each trap has a unique effect.\n\n" +
		"[b]TECH CARDS[/b]\nSpecial abilities: buffs, debuffs, shields, and more.\n\n" +
		"[b]WINNING[/b]\nForce your opponent's Crystals to 0, or leave them with no valid moves."
	)
	scroll.add_child(rtl)

	_add_back_btn(vbox, dimmer)

# ─────────────────────────────────────────────────────────────
# Settings sub-panel (placeholder)
# ─────────────────────────────────────────────────────────────

func _show_settings_panel() -> void:
	var ovl: Dictionary = _make_sub_overlay(380.0, 220.0)
	var dimmer: Control = ovl["dimmer"]
	var vbox: VBoxContainer = ovl["vbox"]

	var header := Label.new()
	header.text = "SETTINGS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(header)
	vbox.add_child(HSeparator.new())

	var placeholder := Label.new()
	placeholder.text = "Settings coming soon."
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_font_size_override("font_size", 15)
	placeholder.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(placeholder)

	_add_back_btn(vbox, dimmer)

# ─────────────────────────────────────────────────────────────
# Surrender confirm
# ─────────────────────────────────────────────────────────────

func _show_surrender_confirm() -> void:
	var ovl: Dictionary = _make_sub_overlay(300.0, 210.0)
	var dimmer: Control = ovl["dimmer"]
	var vbox: VBoxContainer = ovl["vbox"]

	var lbl := Label.new()
	lbl.text = "Surrender?"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
	vbox.add_child(lbl)

	var body := Label.new()
	body.text = "You will lose this duel."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(body)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vbox.add_child(row)

	var yes_btn := Button.new()
	yes_btn.text = "Yes, Surrender"
	yes_btn.add_theme_font_size_override("font_size", 15)
	yes_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	yes_btn.custom_minimum_size = Vector2(140, 40)
	yes_btn.pressed.connect(func() -> void:
		dimmer.queue_free()
		var winner: int = GameState.get_opponent(GameState.current_player)
		GameState._end_game(winner))
	row.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "Cancel"
	no_btn.add_theme_font_size_override("font_size", 15)
	no_btn.custom_minimum_size = Vector2(80, 40)
	no_btn.pressed.connect(func() -> void:
		dimmer.queue_free()
		_show_options_panel())
	row.add_child(no_btn)

# ─────────────────────────────────────────────────────────────
# Hover Info Panel
# ─────────────────────────────────────────────────────────────

func _build_hover_panel() -> void:
	_hover_panel = Panel.new()
	_hover_panel.layout_mode = 1
	_hover_panel.anchor_left = 0.5
	_hover_panel.anchor_right = 0.5
	_hover_panel.anchor_top = 0.0
	_hover_panel.anchor_bottom = 0.0
	_hover_panel.offset_left = -82.0
	_hover_panel.offset_right = 82.0
	_hover_panel.offset_top = 148.0
	_hover_panel.offset_bottom = 518.0
	_hover_panel.visible = false
	_hover_panel.z_index = 3
	_hover_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.16, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.35, 0.60, 1.0, 0.5)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	_hover_panel.add_theme_stylebox_override("panel", sb)
	add_child(_hover_panel)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 1
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8.0
	vbox.offset_top = 8.0
	vbox.offset_right = -8.0
	vbox.offset_bottom = -8.0
	vbox.add_theme_constant_override("separation", 4)
	_hover_panel.add_child(vbox)

	_hover_name_lbl = Label.new()
	_hover_name_lbl.add_theme_font_size_override("font_size", 13)
	_hover_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82))
	_hover_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_hover_name_lbl)

	_hover_type_lbl = Label.new()
	_hover_type_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(_hover_type_lbl)

	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 6)
	vbox.add_child(stat_row)

	_hover_atk_lbl = Label.new()
	_hover_atk_lbl.add_theme_font_size_override("font_size", 10)
	_hover_atk_lbl.add_theme_color_override("font_color", Color(1.0, 0.62, 0.30))
	stat_row.add_child(_hover_atk_lbl)

	_hover_def_lbl = Label.new()
	_hover_def_lbl.add_theme_font_size_override("font_size", 10)
	_hover_def_lbl.add_theme_color_override("font_color", Color(0.38, 0.68, 1.0))
	stat_row.add_child(_hover_def_lbl)

	_hover_aff_lbl = Label.new()
	_hover_aff_lbl.add_theme_font_size_override("font_size", 10)
	_hover_aff_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))
	vbox.add_child(_hover_aff_lbl)

	vbox.add_child(HSeparator.new())

	_hover_desc_lbl = Label.new()
	_hover_desc_lbl.add_theme_font_size_override("font_size", 10)
	_hover_desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.88, 0.98))
	_hover_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hover_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_hover_desc_lbl)

func _on_grid_card_hovered(player: int, row: int, col: int) -> void:
	var inst: GameState.CardInstance = GameState.get_card(player, row, col)
	if inst == null or inst.card_type == "dead_end":
		return
	# Flash hover during tech target selection even if card is face-down
	if selection_state == SelectionState.SELECTING_TECH_TARGET \
			and "opponent_squares" in pending_tech_filter \
			and player == GameState.get_opponent(GameState.current_player):
		_set_tech_hover_node(grid_nodes[player][row][col])
	var is_own := (player == GameState.current_player)
	if not (is_own or inst.face_up):
		return
	_show_hover_info(inst.card_name, inst.card_type)

func _show_hover_info(card_name: String, card_type: String) -> void:
	if _hover_panel == null:
		return
	var phase := GameState.current_phase
	if phase in [GameState.Phase.NONE, GameState.Phase.SETUP_P1,
			GameState.Phase.SETUP_P2, GameState.Phase.GAME_OVER]:
		return
	match card_type:
		"character":
			var data: CharacterData = CardDatabase.get_character(card_name)
			if not data:
				return
			_hover_name_lbl.text = card_name
			_hover_type_lbl.text = "CHARACTER  %d◆" % data.crystal_cost
			_hover_type_lbl.add_theme_color_override("font_color", Color(1.0, 0.71, 0.2))
			_hover_atk_lbl.text = "ATK %d" % data.base_atk
			_hover_def_lbl.text = "DEF %d" % data.base_def
			_hover_atk_lbl.visible = true
			_hover_def_lbl.visible = true
			_hover_aff_lbl.text = CharacterData.Affinity.keys()[data.affinity].capitalize()
			_hover_desc_lbl.text = data.get_ability_description()
		"trap":
			var data: TrapData = CardDatabase.get_trap(card_name)
			if not data:
				return
			_hover_name_lbl.text = card_name
			_hover_type_lbl.text = "TRAP  %d◆" % data.crystal_cost
			_hover_type_lbl.add_theme_color_override("font_color", Color(1.0, 0.263, 0.345))
			_hover_atk_lbl.visible = false
			_hover_def_lbl.visible = false
			_hover_aff_lbl.text = ""
			_hover_desc_lbl.text = data.get_effect_description()
		"tech":
			var data: TechCardData = CardDatabase.get_tech(card_name)
			if not data:
				return
			_hover_name_lbl.text = card_name
			_hover_type_lbl.text = "TECH  %d◆" % data.crystal_cost
			_hover_type_lbl.add_theme_color_override("font_color", Color(0.18, 0.764, 0.341))
			_hover_atk_lbl.visible = false
			_hover_def_lbl.visible = false
			_hover_aff_lbl.text = ""
			_hover_desc_lbl.text = data.get_effect_description()
		_:
			return
	_hover_panel.visible = true

func _hide_hover_info() -> void:
	if _hover_panel != null:
		_hover_panel.visible = false
	_set_tech_hover_node(null)

func _set_tech_hover_node(node: Control) -> void:
	if _tech_hover_node != null and _tech_hover_node != node:
		_tech_hover_node.set_target_hover(false)
	_tech_hover_node = node
	if _tech_hover_node != null:
		_tech_hover_node.set_target_hover(true)

func _stop_battle_music() -> void:
	if _battle_music != null:
		_battle_music.stop()
		_battle_music.queue_free()
		_battle_music = null

# ─────────────────────────────────────────────────────────────
# Coin flip overlay
# ─────────────────────────────────────────────────────────────
func _show_coin_flip_and_start(first_player: int) -> void:
	var _COIN_FRONT: Texture2D = load("res://assets/textures/ui/decorations/ui_coin_front.png")
	var _COIN_BACK:  Texture2D = load("res://assets/textures/ui/decorations/ui_coin_back.png")
	const COIN_SIZE    : float = 420.0
	const NUM_FLIPS    : int   = 10   # even → lands on same side it started
	const PORTRAIT_W   : float = 260.0
	const GREY_MODULATE: Color = Color(0.3, 0.3, 0.35, 1.0)

	# ── Overlay ────────────────────────────────────────────────
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index      = 60
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 1.0)
	overlay.add_child(bg)

	# ── Player portraits (greyed until result) ─────────────────
	const REF_H: float = 720.0
	var coin_p1_port: TextureRect = null
	var coin_p2_port: TextureRect = null

	var _p1_tex: Texture2D = load(GameState.player_portraits[0])
	if _p1_tex:
		var sz := _p1_tex.get_size()
		var pw: float = REF_H * sz.x / sz.y if sz.y > 0.0 else PORTRAIT_W
		coin_p1_port = TextureRect.new()
		coin_p1_port.texture       = _p1_tex
		coin_p1_port.layout_mode   = 1
		coin_p1_port.anchor_left   = 0.0
		coin_p1_port.anchor_top    = 0.0
		coin_p1_port.anchor_right  = 0.0
		coin_p1_port.anchor_bottom = 1.0
		coin_p1_port.offset_right  = pw
		coin_p1_port.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		coin_p1_port.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
		coin_p1_port.flip_h        = true
		coin_p1_port.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		coin_p1_port.modulate      = GREY_MODULATE
		overlay.add_child(coin_p1_port)

	var _p2_tex: Texture2D = load(GameState.player_portraits[1])
	if _p2_tex:
		var sz := _p2_tex.get_size()
		var pw: float = REF_H * sz.x / sz.y if sz.y > 0.0 else PORTRAIT_W
		coin_p2_port = TextureRect.new()
		coin_p2_port.texture       = _p2_tex
		coin_p2_port.layout_mode   = 1
		coin_p2_port.anchor_left   = 1.0
		coin_p2_port.anchor_top    = 0.0
		coin_p2_port.anchor_right  = 1.0
		coin_p2_port.anchor_bottom = 1.0
		coin_p2_port.offset_left   = -pw
		coin_p2_port.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		coin_p2_port.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
		coin_p2_port.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		coin_p2_port.modulate      = GREY_MODULATE
		overlay.add_child(coin_p2_port)

	# ── CenterContainer ensures true centering regardless of VBox size ──
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "COIN FLIP"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	vbox.add_child(title_lbl)

	var coin := TextureRect.new()
	coin.texture               = _COIN_FRONT if first_player == 0 else _COIN_BACK
	coin.custom_minimum_size   = Vector2(COIN_SIZE, COIN_SIZE)
	coin.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT
	coin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coin.pivot_offset          = Vector2(COIN_SIZE * 0.5, COIN_SIZE * 0.5)
	vbox.add_child(coin)

	var result_lbl := Label.new()
	result_lbl.text = ""
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.add_theme_font_size_override("font_size", 28)
	result_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	vbox.add_child(result_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = "tap to continue"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 14)
	hint_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.0))
	vbox.add_child(hint_lbl)

	# ── Flip animation ────────────────────────────────────────
	var is_front: bool = (first_player == 0)

	for i in range(NUM_FLIPS):
		var progress: float  = float(i) / float(NUM_FLIPS)
		var half_dur: float  = lerpf(0.055, 0.21, progress)

		var tw1 := create_tween()
		tw1.tween_property(coin, "scale:x", 0.0, half_dur).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		await tw1.finished

		is_front = not is_front
		coin.texture = _COIN_FRONT if is_front else _COIN_BACK

		var tw2 := create_tween()
		tw2.tween_property(coin, "scale:x", 1.0, half_dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		await tw2.finished

	# ── Show result ───────────────────────────────────────────
	if first_player == 0:
		result_lbl.text = "HEADS — Player 1 goes first!"
	else:
		result_lbl.text = "TAILS — Player 2 goes first!"

	# Reveal winner portrait
	var winner_port: TextureRect = coin_p1_port if first_player == 0 else coin_p2_port
	if winner_port:
		var reveal_tw := create_tween()
		reveal_tw.tween_property(winner_port, "modulate",
			Color(1.0, 1.0, 1.0, 1.0), 0.45).set_trans(Tween.TRANS_SINE)

	# Fade in hint and allow tap-to-dismiss
	# Use Array so the lambda captures by reference (bool would be by value)
	var done := [false]
	var hint_tw := create_tween()
	hint_tw.tween_property(hint_lbl, "theme_override_colors/font_color",
		Color(0.5, 0.5, 0.6, 0.65), 0.4)

	bg.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and not done[0]:
			done[0] = true
			overlay.queue_free()
			turn_manager.start_turn(first_player))

	# Auto-dismiss after 2.2 s
	await get_tree().create_timer(2.2).timeout
	if not done[0]:
		done[0] = true
		overlay.queue_free()
		turn_manager.start_turn(first_player)

func _deal_tech_cards(player: int, count: int) -> void:
	# SetupPhase already populates tech_hands from the player's deck — skip if done
	if not GameState.tech_hands[player].is_empty():
		return
	# AI player (no setup phase): use forced tech list if set, otherwise random
	var forced_tech: Variant = GameState.campaign_enemy_config.get("forced_tech", null)
	var tech_pool: Array
	if forced_tech is Array and not (forced_tech as Array).is_empty():
		tech_pool = (forced_tech as Array).duplicate()
	else:
		tech_pool = CardDatabase.get_all_tech_names()
		tech_pool.shuffle()
	for i in range(min(count, tech_pool.size())):
		GameState.tech_hands[player].append(tech_pool[i])

# ─────────────────────────────────────────────────────────────
# HUD Updates
# ─────────────────────────────────────────────────────────────
func _refresh_hud() -> void:
	_update_crystals(0, GameState.crystals[0])
	_update_crystals(1, GameState.crystals[1])
	_update_turn_info()

func _on_crystals_changed(player_index: int, new_amount: int) -> void:
	var old_amount := _prev_crystals[player_index]
	_prev_crystals[player_index] = new_amount
	if new_amount < old_amount:
		# Animated deduction: burst icon + tick-down + 1s hold
		_play_crystal_burst(player_index)
		await _tick_down_crystal(player_index, old_amount, new_amount)
		await get_tree().create_timer(1.0).timeout
		if new_amount <= 0:
			_fade_out_battle_music(0.5)
	else:
		var bottom_lbl := _p1_bottom_crystal if player_index == 0 else _p2_bottom_crystal
		if bottom_lbl != null:
			bottom_lbl.text = str(new_amount)
		# Yield one frame so TurnManager can reach its await before the signal fires.
		# Without this, crystal_animation_done emits synchronously during lose_crystals,
		# before TurnManager executes `await crystal_animation_done`, causing a hang.
		await get_tree().process_frame
	# Unblock TurnManager (or whoever is awaiting after lose_crystals)
	if turn_manager != null:
		turn_manager.crystal_animation_done.emit()

func _update_crystals(player_index: int, amount: int) -> void:
	_prev_crystals[player_index] = amount
	var bottom_lbl := _p1_bottom_crystal if player_index == 0 else _p2_bottom_crystal
	if bottom_lbl != null:
		bottom_lbl.text = str(amount)

# Crystal burst animation: icon duplicates, scales up and fades out
func _play_crystal_burst(player_index: int) -> void:
	var icon := _p1_crystal_icon if player_index == 0 else _p2_crystal_icon
	if icon == null or not is_instance_valid(icon):
		return
	var asp := AudioStreamPlayer.new()
	asp.stream = SFX_CRYSTAL
	asp.bus = "SFX"
	add_child(asp)
	asp.play()
	asp.finished.connect(asp.queue_free)
	var burst := TextureRect.new()
	burst.texture = icon.texture
	burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	burst.custom_minimum_size = icon.custom_minimum_size
	burst.size = icon.size
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.z_index = 10
	var gpos := icon.get_global_rect().position
	burst.position = gpos
	burst.pivot_offset = icon.custom_minimum_size * 0.5
	add_child(burst)
	var t := create_tween()
	t.tween_property(burst, "scale", Vector2(2.4, 2.4), 0.42).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t.parallel().tween_property(burst, "modulate:a", 0.0, 0.42).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await t.finished
	burst.queue_free()

# Tick-down animation: smoothly counts the label from old to new
func _tick_down_crystal(player_index: int, old_amount: int, new_amount: int) -> void:
	var lbl := _p1_bottom_crystal if player_index == 0 else _p2_bottom_crystal
	if lbl == null:
		return
	var t := create_tween()
	t.tween_method(
		func(v: float) -> void: lbl.text = str(int(v)),
		float(old_amount), float(new_amount), 0.38)
	await t.finished

func _on_dice_rolled(result: int) -> void:
	dice_display.text = "[%d]" % result

func _on_message_posted(text: String) -> void:
	print("[BATTLE LOG] ", text)
	message_log.append_text("\n" + text)
	_battle_log_lines.append(text)

func _update_portrait_dims() -> void:
	if _p1_portrait == null or _p2_portrait == null:
		return
	var active := GameState.current_player
	_p1_portrait.modulate = Color(1.0, 1.0, 1.0, 1.0) if active == 0 \
		else Color(0.3, 0.3, 0.35, 1.0)
	_p2_portrait.modulate = Color(1.0, 1.0, 1.0, 1.0) if active == 1 \
		else Color(0.3, 0.3, 0.35, 1.0)

func _update_turn_info() -> void:
	_update_portrait_dims()
	_update_crystal_visibility()
	if _turn_number_lbl:
		_turn_number_lbl.text = "Turn %d" % GameState.turn_number

# ─────────────────────────────────────────────────────────────
# Grid
# ─────────────────────────────────────────────────────────────
func _refresh_all_grids() -> void:
	for p in range(2):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				_refresh_card_node(p, r, c)

func _refresh_card_node(player: int, row: int, col: int) -> void:
	var node: Control = grid_nodes[player][row][col]
	var inst := GameState.get_card(player, row, col)
	node.set_card_data(inst, player, Vector2i(row, col))

var _tech_hand_overlay: Control = null

func _refresh_tech_hand() -> void:
	_dismiss_tech_hand_overlay()

	var player   := GameState.current_player
	var crystals : int   = GameState.crystals[player]
	var hand     : Array = GameState.tech_hands[player]

	const PAD : int = 20
	const GAP : int = 12

	# ── Fullscreen overlay ───────────────────────────────────────
	_tech_hand_overlay = Control.new()
	_tech_hand_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tech_hand_overlay.z_index = 8
	add_child(_tech_hand_overlay)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_tech_hand_overlay.add_child(dimmer)

	# ── Panel filling screen (with small margin) ─────────────────
	var panel_c := PanelContainer.new()
	panel_c.layout_mode = 1
	panel_c.anchor_left   = 0.0
	panel_c.anchor_top    = 0.0
	panel_c.anchor_right  = 1.0
	panel_c.anchor_bottom = 1.0
	panel_c.offset_left   = PAD
	panel_c.offset_top    = PAD
	panel_c.offset_right  = -PAD
	panel_c.offset_bottom = -PAD
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.05, 0.07, 0.17, 0.98)
	psb.border_width_left   = 2
	psb.border_width_top    = 2
	psb.border_width_right  = 2
	psb.border_width_bottom = 2
	psb.border_color = Color(0.30, 0.85, 1.0, 0.50)
	psb.corner_radius_top_left     = 8
	psb.corner_radius_top_right    = 8
	psb.corner_radius_bottom_left  = 8
	psb.corner_radius_bottom_right = 8
	psb.content_margin_left   = PAD
	psb.content_margin_right  = PAD
	psb.content_margin_top    = 12
	psb.content_margin_bottom = PAD
	panel_c.add_theme_stylebox_override("panel", psb)
	_tech_hand_overlay.add_child(panel_c)

	# ── VBox: title row + card row ───────────────────────────────
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", GAP)
	panel_c.add_child(vbox)

	# Title row
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)

	var can_use_tech: bool = (GameState.current_phase == GameState.Phase.MODE_SELECT
		and not _tech_used_this_turn[player]
		and player == GameState.current_player)

	var title := Label.new()
	title.text = "TECH HAND  —  Choose a card to play" if can_use_tech else "TECH HAND  —  Viewing cards"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.30, 0.85, 1.0))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(title)

	var cancel := Button.new()
	cancel.text = "CLOSE"
	cancel.custom_minimum_size = Vector2(100.0, 36.0)
	cancel.add_theme_font_size_override("font_size", 13)
	cancel.pressed.connect(func() -> void:
		_dismiss_tech_hand_overlay()
		if GameState.current_phase in [GameState.Phase.MODE_SELECT, GameState.Phase.ATTACK]:
			_set_selection_state(SelectionState.SELECTING_ATTACKER)
			_highlight_attackable_chars())
	title_row.add_child(cancel)

	# Card row — each card column grows to fill remaining height
	# Wrap in scroll container + optional arrows when hand has more than 3 cards
	var show_scroll: bool = hand.size() > 3
	var tech_scroll_c: ScrollContainer = null

	if show_scroll:
		var scroll_row := HBoxContainer.new()
		scroll_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_row.add_theme_constant_override("separation", 4)
		vbox.add_child(scroll_row)

		var left_arr := Button.new()
		left_arr.text = "<"
		left_arr.custom_minimum_size = Vector2(40.0, 0.0)
		left_arr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		left_arr.add_theme_font_size_override("font_size", 22)
		scroll_row.add_child(left_arr)

		tech_scroll_c = ScrollContainer.new()
		tech_scroll_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tech_scroll_c.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		tech_scroll_c.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		tech_scroll_c.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
		scroll_row.add_child(tech_scroll_c)

		var right_arr := Button.new()
		right_arr.text = ">"
		right_arr.custom_minimum_size = Vector2(40.0, 0.0)
		right_arr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right_arr.add_theme_font_size_override("font_size", 22)
		scroll_row.add_child(right_arr)

		left_arr.pressed.connect(func() -> void:
			tech_scroll_c.scroll_horizontal = maxi(tech_scroll_c.scroll_horizontal - 220, 0))
		right_arr.pressed.connect(func() -> void:
			tech_scroll_c.scroll_horizontal += 220)

	var card_hbox := HBoxContainer.new()
	card_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_hbox.add_theme_constant_override("separation", GAP)
	if show_scroll and tech_scroll_c != null:
		tech_scroll_c.add_child(card_hbox)
	else:
		vbox.add_child(card_hbox)

	for i in range(hand.size()):
		var tech_name: String = str(hand[i])
		var data: TechCardData = CardDatabase.get_tech(tech_name)
		var can_use := data != null and crystals >= data.crystal_cost

		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 8)
		card_hbox.add_child(col)

		var img := TextureRect.new()
		img.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		img.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not can_use:
			img.modulate = Color(0.5, 0.5, 0.5, 0.8)
		var snake: String = tech_name.to_lower() \
			.replace(" ", "_").replace("'", "").replace("-", "_")
		var path: String = "res://assets/textures/cards/full_cards/" + snake + ".png"
		if not ResourceLoader.exists(path):
			path = "res://assets/textures/cards/full_cards/tech_" + snake + ".png"
		if ResourceLoader.exists(path):
			img.texture = load(path)
		col.add_child(img)

		if can_use_tech:
			var use_btn := Button.new()
			use_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			use_btn.custom_minimum_size = Vector2(0.0, 52.0)
			use_btn.text = "USE  (%d◆)" % (data.crystal_cost if data else 0)
			use_btn.disabled = not can_use
			use_btn.add_theme_font_size_override("font_size", 16)
			var captured: String = tech_name
			use_btn.pressed.connect(func() -> void:
				_dismiss_tech_hand_overlay()
				_on_tech_card_btn(captured))
			col.add_child(use_btn)

func _dismiss_tech_hand_overlay() -> void:
	if _tech_hand_overlay != null:
		_tech_hand_overlay.queue_free()
		_tech_hand_overlay = null

# ─────────────────────────────────────────────────────────────
# Buttons
# ─────────────────────────────────────────────────────────────
func _is_ai_turn() -> bool:
	return GameState.current_player == 1 and \
		GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN]

func _on_attack_btn() -> void:
	if GameState.current_phase != GameState.Phase.MODE_SELECT:
		return
	if _is_ai_turn():
		return
	turn_manager.select_mode(GameState.TurnMode.ATTACK)

func _on_tech_btn() -> void:
	if GameState.current_phase != GameState.Phase.MODE_SELECT:
		return
	if _is_ai_turn():
		return
	turn_manager.select_mode(GameState.TurnMode.TECH)

func _on_end_attack_btn() -> void:
	_on_end_turn_requested()

func _on_cancel_btn() -> void:
	_clear_selection()
	_set_selection_state(SelectionState.NONE)
	action_panel.visible = false

# ─────────────────────────────────────────────────────────────
# End Turn — Tax Confirmation
# ─────────────────────────────────────────────────────────────
const TAX_BASE: int = 50

func _current_skip_tax() -> int:
	# Doubles each consecutive no-attack turn: 50, 100, 200, 400, 800, 1600 …
	return TAX_BASE << GameState.skip_counts[GameState.current_player]

func _on_end_turn_requested() -> void:
	# Check if this player attacked at all this turn.
	# Two sources: surviving characters with attacked_this_turn=true, OR
	# attacks_remaining dropped below 2 (covers destroyed attackers whose flag is gone).
	var player := GameState.current_player
	var has_attacked := GameState.attacks_remaining < 2
	if not has_attacked:
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(player, r, c)
				if card.card_type == "character" and card.attacked_this_turn:
					has_attacked = true
					break
			if has_attacked:
				break
	if not has_attacked and GameState.can_player_attack(player):
		_show_tax_confirm()
	else:
		turn_manager.end_attacks_early()

func _show_tax_confirm() -> void:
	if _tax_confirm_panel != null:
		return

	var player := GameState.current_player
	var skips: int = GameState.skip_counts[player]
	var tax := _current_skip_tax()
	var is_consecutive := skips >= 1

	var panel := PanelContainer.new()
	panel.z_index = 20
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.10, 0.96)
	sb.border_color = Color(0.85, 0.68, 0.18)
	sb.border_width_left   = 2; sb.border_width_right  = 2
	sb.border_width_top    = 2; sb.border_width_bottom = 2
	sb.corner_radius_top_left     = 10; sb.corner_radius_top_right    = 10
	sb.corner_radius_bottom_left  = 10; sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 28; sb.content_margin_right  = 28
	sb.content_margin_top  = 22; sb.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", sb)
	panel.layout_mode = 1
	panel.anchor_left   = 0.5; panel.anchor_right  = 0.5
	panel.anchor_top    = 0.5; panel.anchor_bottom = 0.5
	var h_half: float = 130.0 + (40.0 if is_consecutive else 0.0)
	panel.offset_left   = -220.0; panel.offset_right  = 220.0
	panel.offset_top    = -h_half; panel.offset_bottom = h_half
	add_child(panel)
	_tax_confirm_panel = panel

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "End Turn Without Attacking?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	vbox.add_child(title)

	# Consecutive-skip doubling warning
	if is_consecutive:
		var warn_lbl := Label.new()
		warn_lbl.text = "⚠ Tax doubles every time you skip! (Skip #%d)" % (skips + 1)
		warn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warn_lbl.add_theme_font_size_override("font_size", 13)
		warn_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.25))
		vbox.add_child(warn_lbl)

	var body_top := Label.new()
	body_top.text = "You will be taxed"
	body_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_top.add_theme_font_size_override("font_size", 14)
	body_top.add_theme_color_override("font_color", Color(0.82, 0.82, 0.90))
	vbox.add_child(body_top)

	var cost_row := HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.add_theme_constant_override("separation", 6)
	vbox.add_child(cost_row)

	var crystal_tex: Texture2D = load("res://assets/textures/ui/decorations/ui_crystal_indicator.png")
	if crystal_tex:
		var crystal_icon := TextureRect.new()
		crystal_icon.texture = crystal_tex
		crystal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crystal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crystal_icon.custom_minimum_size = Vector2(28, 28)
		crystal_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		crystal_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_row.add_child(crystal_icon)

	var cost_lbl := Label.new()
	cost_lbl.text = "%d Crystals" % tax
	cost_lbl.add_theme_font_size_override("font_size", 20)
	cost_lbl.add_theme_color_override("font_color", Color(0.38, 0.82, 1.0))
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cost_row.add_child(cost_lbl)

	var body_bot := Label.new()
	body_bot.text = "for ending your turn without attacking."
	body_bot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_bot.add_theme_font_size_override("font_size", 14)
	body_bot.add_theme_color_override("font_color", Color(0.82, 0.82, 0.90))
	vbox.add_child(body_bot)

	# Next-skip preview (only when consecutive)
	if is_consecutive:
		var next_lbl := Label.new()
		next_lbl.text = "Next skip will cost %d◆" % (tax * 2)
		next_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		next_lbl.add_theme_font_size_override("font_size", 12)
		next_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3, 0.85))
		vbox.add_child(next_lbl)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vbox.add_child(row)

	var confirm_btn := Button.new()
	confirm_btn.text = "End Turn  (−%d◆)" % tax
	confirm_btn.add_theme_font_size_override("font_size", 15)
	confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.3))
	confirm_btn.pressed.connect(func() -> void:
		if _tax_confirm_panel != null:
			_tax_confirm_panel.queue_free()
			_tax_confirm_panel = null
		GameState.skip_counts[player] += 1
		GameState.lose_crystals(player, tax)
		GameState.post_message("Player %d skips without attacking — %d◆ tax (skip #%d this duel)" % [player + 1, tax, GameState.skip_counts[player]])
		await turn_manager.crystal_animation_done
		turn_manager.end_attacks_early())
	row.add_child(confirm_btn)

	var cancel_btn2 := Button.new()
	cancel_btn2.text = "Cancel"
	cancel_btn2.add_theme_font_size_override("font_size", 15)
	cancel_btn2.pressed.connect(func() -> void:
		if _tax_confirm_panel != null:
			_tax_confirm_panel.queue_free()
			_tax_confirm_panel = null)
	row.add_child(cancel_btn2)

func _on_tech_card_btn(tech_name: String) -> void:
	pending_tech_name = tech_name
	turn_manager.play_tech_card(tech_name)

func _on_play_again_btn() -> void:
	get_tree().reload_current_scene()

# ─────────────────────────────────────────────────────────────
# Phase Changes
# ─────────────────────────────────────────────────────────────
func _enter_mode_select() -> void:
	mode_panel.visible = false
	end_attack_btn.visible = false
	if _end_turn_btn:
		_end_turn_btn.visible = true
	if _options_btn:
		_options_btn.visible = true
	_clear_selection()
	# Show turn banner once per new turn number.
	if GameState.turn_number != _last_banner_turn:
		_last_banner_turn = GameState.turn_number
		_show_turn_banner(GameState.current_player)
	# Auto-peek for the active player at the start of each turn.
	# In VS_AI mode, never reveal the AI's board — reset previews instead.
	var cp := GameState.current_player
	if _is_ai_turn():
		_reset_reveal_previews()
	elif not _reveal_preview[cp]:
		_toggle_reveal_preview(cp)
	if _is_ai_turn():
		if _end_turn_btn:
			_end_turn_btn.visible = false
		if _options_btn:
			_options_btn.visible = false
		_ai_watchdog.start()
		ai_player.decide_turn()
		return
	_set_selection_state(SelectionState.SELECTING_ATTACKER)
	_highlight_attackable_chars()
	_update_end_turn_blink()

func _on_phase_changed(phase: GameState.Phase) -> void:
	_refresh_all_grids()
	_update_turn_info()
	_update_tech_stacks()
	_update_void_stacks()
	_update_crystal_visibility()
	_update_reveal_buttons()
	if phase == GameState.Phase.MODE_SELECT:
		# Only reset at the start of a genuinely new turn, not on mid-turn
		# MODE_SELECT re-entries that happen after each attack completes.
		if GameState.turn_number != _tech_reset_turn:
			_tech_reset_turn = GameState.turn_number
			_tech_used_this_turn[GameState.current_player] = false
	if _tech_overlay_panel != null and _tech_overlay_panel.visible:
		_rebuild_tech_overlay_content(_tech_overlay_player)
	match phase:
		GameState.Phase.MODE_SELECT:
			if GameState.game_mode == GameState.GameMode.HOT_SEAT:
				# Only show the "pass the device" handoff when the player actually changes.
				# Mid-turn returns to MODE_SELECT (after each attack) skip straight to
				# _enter_mode_select() so cards stay visible for the continuing player.
				var is_new_player_turn: bool = (
					GameState.current_player != _handoff_last_player or
					GameState.turn_number != _handoff_last_turn
				)
				if is_new_player_turn:
					_reset_reveal_previews()
					_handoff_last_player = GameState.current_player
					_handoff_last_turn = GameState.turn_number
					var ctx: String
					if GameState.turn_number == 0:
						ctx = "It's your turn to begin."
					else:
						ctx = "Turn %d  ·  You have %d◆" % [
							GameState.turn_number + 1,
							GameState.crystals[GameState.current_player]
						]
					_show_handoff(GameState.current_player, ctx, _enter_mode_select)
					return
			_enter_mode_select()
			return

		GameState.Phase.ATTACK:
			mode_panel.visible = false
			end_attack_btn.visible = false
			if _end_turn_btn:
				_end_turn_btn.visible = true
			_set_selection_state(SelectionState.SELECTING_ATTACKER)
			_highlight_attackable_chars()
			_update_end_turn_blink()

		GameState.Phase.GAME_OVER:
			mode_panel.visible = false
			end_attack_btn.visible = false
			if _end_turn_btn:
				_end_turn_btn.visible = false
			if _attack_confirm_panel:
				_attack_confirm_panel.visible = false
			action_panel.visible = false

func _on_mode_selected(_player: int, _mode: GameState.TurnMode) -> void:
	pass

func _on_attack_phase_started(_player: int, _max_attacks: int) -> void:
	_refresh_all_grids()

func _on_attack_completed(_from: Vector2i, _to: Vector2i, _result: BattleResolver.BattleResult) -> void:
	_refresh_all_grids()
	_clear_selection()
	_update_end_turn_blink()
	# Phase returns to MODE_SELECT after battle; _enter_mode_select() re-enables selection.

func _on_attack_aborted() -> void:
	if _attack_confirm_panel:
		_attack_confirm_panel.visible = false
	if _end_turn_btn:
		_end_turn_btn.visible = true
	_clear_selection()
	_set_selection_state(SelectionState.SELECTING_ATTACKER)
	_highlight_attackable_chars()
	_update_end_turn_blink()

func _on_battle_preview_needed(attacker_player: int, attacker: GameState.CardInstance, defender: GameState.CardInstance, result: BattleResolver.BattleResult) -> void:
	var overlay := BattleCalculationOverlay.new()
	overlay.z_index = 100
	add_child(overlay)
	await overlay.start(attacker_player, attacker, defender, result)
	turn_manager.battle_preview_done.emit()

func _on_tech_played(player: int, _tech_name: String) -> void:
	_tech_used_this_turn[player] = true
	_update_tech_stacks()
	_refresh_all_grids()

func _on_tech_resolved(_player: int) -> void:
	# Tech played during MODE_SELECT — stay in turn, re-enable attacking
	action_panel.visible = false
	mode_panel.visible = false
	end_attack_btn.visible = false
	_clear_selection()
	_refresh_all_grids()
	if _is_ai_turn():
		await get_tree().create_timer(0.4).timeout
		_ai_watchdog.start()
		ai_player.decide_turn()
	else:
		if _end_turn_btn:
			_end_turn_btn.visible = true
		_set_selection_state(SelectionState.SELECTING_ATTACKER)
		_highlight_attackable_chars()
		_update_end_turn_blink()

func _on_turn_ended(_player: int) -> void:
	if _ai_watchdog != null:
		_ai_watchdog.stop()
	_music_changed_this_turn = false
	if _end_turn_blink_tween and _end_turn_blink_tween.is_valid():
		_end_turn_blink_tween.kill()
		_end_turn_blink_tween = null
	if _end_turn_btn:
		_end_turn_btn.modulate = Color.WHITE
	_refresh_all_grids()
	_clear_selection()

func _show_turn_banner(player: int) -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	const BANNER_H: float = 80.0
	const FONT_SIZE: int = 52

	var fv := FontVariation.new()
	fv.base_font = load("res://assets/fonts/Chivo-Italic-VariableFont_wght.ttf")
	fv.variation_opentype = {"wght": 700}

	var lbl := Label.new()
	lbl.text = "%s's Turn" % _player_names[player]
	lbl.add_theme_font_override("font", fv)
	lbl.add_theme_font_size_override("font_size", FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.layout_mode = 0
	lbl.size = Vector2(vp.x, BANNER_H)
	lbl.position = Vector2(-vp.x, (vp.y - BANNER_H) * 0.5)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 50
	add_child(lbl)

	var tw := create_tween()
	# Fly in from left to center
	tw.tween_property(lbl, "position:x", 0.0, 0.45) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Hold at center
	tw.tween_interval(0.9)
	# Fly out to right
	tw.tween_property(lbl, "position:x", vp.x, 0.35) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(lbl.queue_free)

# ─────────────────────────────────────────────────────────────
# Card Click Handling
# ─────────────────────────────────────────────────────────────
func _on_card_detail_requested(card_name: String, card_type: String, owner_player: int, row: int, col: int) -> void:
	var inst: Variant = null
	if row >= 0 and col >= 0:
		inst = GameState.get_card(owner_player, row, col)
	CardDetailOverlay.open(self, card_name, card_type, inst)

func _on_card_node_clicked(player: int, row: int, col: int) -> void:
	if _is_ai_turn():
		return
	var pos := Vector2i(row, col)
	var current_player := GameState.current_player
	var opponent := GameState.get_opponent(current_player)

	# During union material selection: any tap on own grid is handled here
	if selection_state == SelectionState.SELECTING_UNION_MATERIALS:
		if player != _pending_union_player:
			_cancel_union_material_selection()
			return
		# Check this cell is in the valid zone and is a character
		if pos not in _pending_union_zone_cells:
			_cancel_union_material_selection()
			return
		if pos in _pending_union_selected_materials:
			return  # already selected
		var mat_card: GameState.CardInstance = GameState.get_card(player, row, col)
		if mat_card.card_type != "character":
			_cancel_union_material_selection()
			return
		_on_union_material_tapped(pos)
		return

	# Own blank/empty cell → show blank context menu (with BLUFF option)
	var clicked_card: GameState.CardInstance = GameState.get_card(player, row, col)
	var _in_targeting: bool = selection_state in [
		SelectionState.SELECTING_TARGET,
		SelectionState.CONFIRMING_ATTACK,
		SelectionState.SELECTING_TECH_TARGET,
	]
	if clicked_card.card_type == "dead_end" and player == current_player and not _in_targeting:
		_show_blank_context(player, row, col)
		return

	match selection_state:
		SelectionState.SELECTING_ATTACKER:
			var card: GameState.CardInstance = GameState.get_card(player, row, col)
			var is_own: bool = (player == current_player)
			var is_face_up_opp: bool = (player == opponent and card.face_up)
			if not is_own and not is_face_up_opp:
				return
			_show_card_context(player, row, col)

		SelectionState.SELECTING_TARGET:
			if player != opponent:
				return  # own-cell taps handled by _input cancel logic
			var target_card: GameState.CardInstance = GameState.get_card(player, row, col)
			if target_card.was_destroyed:
				GameState.post_message("Cannot target an empty cell.")
				return
			if pos in locked_positions:
				GameState.post_message("That square is locked.")
				return
			_start_confirm_attack(opponent, pos)

		SelectionState.CONFIRMING_ATTACK:
			# Clicks during confirm are ignored — use the panel buttons
			pass

		SelectionState.SELECTING_TECH_TARGET:
			_handle_tech_target(player, pos)

# ─────────────────────────────────────────────────────────────
# Attack Confirmation Flow
# ─────────────────────────────────────────────────────────────

func _start_confirm_attack(target_player: int, target_pos: Vector2i) -> void:
	_confirm_target_player = target_player
	_confirm_target_pos = target_pos
	_set_selection_state(SelectionState.CONFIRMING_ATTACK)
	if _end_turn_btn:
		_end_turn_btn.visible = false
	if _attack_confirm_panel:
		_attack_confirm_panel.visible = true
	# Blink the target card red
	var target_node: Control = grid_nodes[target_player][target_pos.x][target_pos.y]
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(target_node, "modulate",
		Color(1.8, 0.4, 0.4, 1.0), 0.35)
	_blink_tween.tween_property(target_node, "modulate",
		Color(1.0, 1.0, 1.0, 1.0), 0.35)

func _confirm_attack() -> void:
	# Stop blink and restore target colour
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
		_blink_tween = null
	if _confirm_target_player >= 0 and _confirm_target_pos != Vector2i(-1, -1):
		var target_node: Control = grid_nodes[_confirm_target_player][_confirm_target_pos.x][_confirm_target_pos.y]
		target_node.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if _attack_confirm_panel:
		_attack_confirm_panel.visible = false
	_set_selection_state(SelectionState.NONE)
	var atk_from := selected_attacker_pos
	var atk_to   := _confirm_target_pos
	_confirm_target_pos   = Vector2i(-1, -1)
	_confirm_target_player = -1
	turn_manager.perform_attack(atk_from, atk_to)

func _cancel_confirm_attack() -> void:
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
		_blink_tween = null
	if _confirm_target_player >= 0 and _confirm_target_pos != Vector2i(-1, -1):
		var target_node: Control = grid_nodes[_confirm_target_player][_confirm_target_pos.x][_confirm_target_pos.y]
		target_node.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_confirm_target_pos   = Vector2i(-1, -1)
	_confirm_target_player = -1
	if _attack_confirm_panel:
		_attack_confirm_panel.visible = false
	if _end_turn_btn:
		_end_turn_btn.visible = true
	_clear_selection()
	_set_selection_state(SelectionState.SELECTING_ATTACKER)
	_highlight_attackable_chars()
	_update_end_turn_blink()

# ─────────────────────────────────────────────────────────────
# Tech Target Handling
# ─────────────────────────────────────────────────────────────
func _on_awaiting_target_selection(prompt: String, filter: String) -> void:
	action_label.text = prompt
	action_panel.visible = true
	pending_tech_filter = filter
	# Parse reveal count for multi-reveal filters (e.g. "opponent_squares_3")
	if "opponent_squares" in filter:
		var parts := filter.split("_")
		_tech_reveals_remaining = int(parts[-1]) if parts[-1].is_valid_int() else 1
		_tech_reveals_total = _tech_reveals_remaining
	else:
		_tech_reveals_total = 0
	_set_selection_state(SelectionState.SELECTING_TECH_TARGET)
	# Show guide text
	if _tech_reveals_total > 1:
		_show_guide("Select %s card to reveal" % _ordinal(1))
	else:
		_show_guide(prompt)
	_highlight_tech_targets(filter)

	# If AI turn, auto-resolve target
	if _is_ai_turn():
		await get_tree().create_timer(0.4).timeout
		var ai_target := ai_player.decide_target(filter)
		var target_player := GameState.get_opponent(1) if "opponent" in filter else 1
		_handle_tech_target(target_player, ai_target)

func _handle_tech_target(player: int, pos: Vector2i) -> void:
	var current_player := GameState.current_player
	var opponent := GameState.get_opponent(current_player)
	var card: GameState.CardInstance = GameState.get_card(player, pos.x, pos.y)
	var data: TechCardData = CardDatabase.get_tech(pending_tech_name)

	# Emit signals for CardRuleEngine CARD_TARGETED_BY_TECH / PLAYER_SELECT_TECH_TARGET
	GameState.emit_signal("tech_target_selected", current_player, player, pos.x, pos.y)
	CardRuleEngine.emit_trigger(CardRule.TriggerType.CARD_TARGETED_BY_TECH,
		{"source_player": player, "source_card": card, "tech_name": pending_tech_name})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.PLAYER_SELECT_TECH_TARGET,
		{"source_player": current_player, "target_player": player,
		 "tech_name": pending_tech_name})

	if "opponent_squares" in pending_tech_filter:
		if player == opponent:
			GameState.reveal_card(player, pos.x, pos.y)
			_tech_reveals_remaining -= 1
			if _tech_reveals_remaining <= 0:
				_finish_tech_action(current_player)
			else:
				var next_idx: int = _tech_reveals_total - _tech_reveals_remaining + 1
				_show_guide("Select %s card to reveal" % _ordinal(next_idx))
				if _is_ai_turn():
					await get_tree().create_timer(0.4).timeout
					var ai_target := ai_player.decide_target(pending_tech_filter)
					_handle_tech_target(opponent, ai_target)
		return

	if pending_tech_filter == "own_faceup_character" or pending_tech_filter == "own_faceup_character_berserk":
		if player == current_player and card.card_type == "character" and card.face_up:
			if data:
				match data.effect_type:
					TechCardData.TechEffectType.PERM_ATK_BOOST_ONE:
						card.perm_atk_bonus += data.effect_params.get("atk", 0)
					TechCardData.TechEffectType.PERM_DEF_BOOST_ONE:
						card.perm_def_bonus += data.effect_params.get("def", 0)
					TechCardData.TechEffectType.TEMP_ATK_BOOST_ATTACK_NOW:
						card.temp_atk_bonus += data.effect_params.get("atk", 0)
					TechCardData.TechEffectType.MULTI_ATTACK_ONE:
						GameState.berserk_active[current_player] = card
			_finish_tech_action(current_player)
		return

	if pending_tech_filter == "own_bio_character":
		if player == current_player and card.card_type == "character" and card.affinity == CharacterData.Affinity.BIO:
			card.has_mutagen_flag = true
			GameState.reveal_card(player, pos.x, pos.y)
			_finish_tech_action(current_player)
		return

	if pending_tech_filter in ["any_faceup_card", "opponent_faceup_no_cost"]:
		if card.face_up and card.card_type != "dead_end":
			var pay_cost := pending_tech_name != "Accident" and pending_tech_filter != "opponent_faceup_no_cost"
			GameState.destroy_card(player, pos.x, pos.y, pay_cost)
			_finish_tech_action(current_player)
		return

	if pending_tech_filter == "own_divine_character_redirect":
		if player == current_player and card.card_type == "character" and card.affinity == CharacterData.Affinity.DIVINE:
			GameState.destroy_card(current_player, pos.x, pos.y)
			GameState.post_message("Archbishop redirected destruction.")
			_clear_after_tech()
		return

	# Fallback — end tech after any selection
	_finish_tech_action(current_player)

func _finish_tech_action(player: int) -> void:
	_clear_after_tech()
	turn_manager.after_tech_resolved(player)

func _clear_after_tech() -> void:
	action_panel.visible = false
	pending_tech_filter = ""
	pending_tech_name = ""
	_tech_reveals_remaining = 0
	_tech_reveals_total = 0
	_hide_guide()
	_set_tech_hover_node(null)
	_clear_selection()
	_set_selection_state(SelectionState.NONE)
	_refresh_all_grids()

func _on_awaiting_trap_choice(trap_name: String, choices: Array) -> void:
	action_label.text = "%s:\n1) %s\n2) %s\n\n(Click a grid square to continue)" % [trap_name, choices[0], choices[1]]
	action_panel.visible = true

# ─────────────────────────────────────────────────────────────
# Highlights
# ─────────────────────────────────────────────────────────────
func _highlight_attackable_chars() -> void:
	pass  # Active glow is card-internal (own face-up chars glow automatically on your turn)

func _has_any_attackable_char() -> bool:
	if GameState.attacks_remaining <= 0:
		return false
	var cp := GameState.current_player
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(cp, r, c)
			if card.card_type == "character" \
					and not card.attacked_this_turn \
					and card.cannot_attack_until < GameState.turn_number \
					and (GameState.berserk_active[cp] == null
						or GameState.berserk_active[cp] == card):
				return true
	return false

func _update_end_turn_blink() -> void:
	if _end_turn_btn == null or not _end_turn_btn.visible:
		if _end_turn_blink_tween and _end_turn_blink_tween.is_valid():
			_end_turn_blink_tween.kill()
			_end_turn_blink_tween = null
		if _end_turn_btn:
			_end_turn_btn.modulate = Color.WHITE
		if selection_state == SelectionState.SELECTING_ATTACKER:
			_hide_guide()
		return
	if not _has_any_attackable_char():
		if _end_turn_blink_tween == null or not _end_turn_blink_tween.is_valid():
			_end_turn_blink_tween = create_tween().set_loops()
			_end_turn_blink_tween.tween_property(_end_turn_btn, "modulate",
				Color(1.0, 1.0, 0.3, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_end_turn_blink_tween.tween_property(_end_turn_btn, "modulate",
				Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if selection_state == SelectionState.SELECTING_ATTACKER:
			_show_guide("No more attacks — End your turn")
	else:
		if _end_turn_blink_tween and _end_turn_blink_tween.is_valid():
			_end_turn_blink_tween.kill()
			_end_turn_blink_tween = null
		_end_turn_btn.modulate = Color.WHITE
		if selection_state == SelectionState.SELECTING_ATTACKER:
			_show_guide("Choose a character to attack with")

func _highlight_valid_targets() -> void:
	pass  # No visual hints on opponent cards during target selection

func _highlight_tech_targets(filter: String) -> void:
	_clear_highlights()
	var player := GameState.current_player
	var opponent := GameState.get_opponent(player)

	if "opponent_squares" in filter:
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				grid_nodes[opponent][r][c].set_highlighted(true)

	elif "own_faceup_character" in filter or "own_bio_character" in filter:
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(player, r, c)
				var ok := card.card_type == "character" and card.face_up
				if "own_bio_character" in filter:
					ok = ok and card.affinity == CharacterData.Affinity.BIO
				grid_nodes[player][r][c].set_highlighted(ok)

	elif "any_faceup_card" in filter:
		for p in range(2):
			for r in range(GameState.GRID_SIZE):
				for c in range(GameState.GRID_SIZE):
					var card: GameState.CardInstance = GameState.get_card(p, r, c)
					grid_nodes[p][r][c].set_highlighted(card.face_up and card.card_type != "dead_end")

func _clear_highlights() -> void:
	for p in range(2):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				grid_nodes[p][r][c].set_highlighted(false)
				grid_nodes[p][r][c].set_locked(false)

func _clear_selection() -> void:
	_hide_card_context()
	for p in range(2):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				grid_nodes[p][r][c].set_selected(false)
				grid_nodes[p][r][c].set_highlighted(false)
				grid_nodes[p][r][c].set_locked(false)
	selected_attacker_pos = Vector2i(-1, -1)
	locked_positions.clear()

func _set_selection_state(state: SelectionState) -> void:
	selection_state = state
	match state:
		SelectionState.SELECTING_ATTACKER:
			_show_guide("Choose a character to attack with")
		SelectionState.SELECTING_TARGET:
			_show_guide("Choose a target to attack")
		SelectionState.SELECTING_TECH_TARGET:
			pass  # guide text set by _on_awaiting_target_selection
		SelectionState.SELECTING_UNION_MATERIALS:
			_show_guide("Tap a valid material card on the field (or tap elsewhere to cancel)")
		_:
			_hide_guide()

func _ordinal(n: int) -> String:
	match n:
		1: return "1st"
		2: return "2nd"
		3: return "3rd"
		_: return "%dth" % n


func _build_guide_box() -> void:
	if _guide_box != null:
		return
	var panel := PanelContainer.new()
	panel.z_index = 210
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.72)
	sb.border_width_left = 1; sb.border_width_right  = 1
	sb.border_width_top  = 1; sb.border_width_bottom = 1
	sb.border_color = Color(0.9, 0.85, 0.6, 0.85)
	sb.corner_radius_top_left     = 5
	sb.corner_radius_top_right    = 5
	sb.corner_radius_bottom_right = 5
	sb.corner_radius_bottom_left  = 5
	sb.content_margin_left   = 10.0
	sb.content_margin_right  = 10.0
	sb.content_margin_top    = 6.0
	sb.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.75))
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)
	add_child(panel)
	_guide_box = panel
	_guide_label = lbl

func _show_guide(text: String) -> void:
	_build_guide_box()
	_guide_label.text = text
	_guide_box.visible = true

func _hide_guide() -> void:
	if _guide_box != null:
		_guide_box.visible = false

# ─────────────────────────────────────────────────────────────
# Card Events
# ─────────────────────────────────────────────────────────────
func _on_card_revealed(player: int, row: int, col: int) -> void:
	var node: Control = grid_nodes[player][row][col]
	var inst := GameState.get_card(player, row, col)
	node.play_reveal_animation()
	# Dead-end reveal plays a 0.5s hold before disappearing — wait for that to finish
	var delay := 0.75 if (inst != null and inst.card_type == "dead_end") else 0.3
	await get_tree().create_timer(delay).timeout
	_refresh_card_node(player, row, col)

func _on_card_destroyed(player: int, row: int, col: int) -> void:
	# Signal fires before place_dead_end(), so card data is still available
	var inst: GameState.CardInstance = GameState.get_card(player, row, col)
	if inst != null and inst.card_type != "dead_end":
		_void_piles[player].append({"card_name": inst.card_name, "card_type": inst.card_type})
		_update_void_stacks()
	var node: Control = grid_nodes[player][row][col]
	_spawn_destroy_effect(node)
	node.play_destroy_animation()
	await get_tree().create_timer(0.55).timeout
	_refresh_card_node(player, row, col)

func _spawn_destroy_effect(card_node: Control) -> void:
	var card_rect := card_node.get_global_rect()
	var local_pos := card_rect.position - global_position
	var card_size := card_rect.size

	# Bright flash overlay on the card itself
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.55, 0.1, 0.85)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 5
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_node.add_child(flash)

	var fw := create_tween()
	fw.tween_property(flash, "color:a", 0.0, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	fw.tween_callback(flash.queue_free)

	# Expanding ring centred on the card
	var ring := Panel.new()
	ring.size = card_size
	ring.position = local_pos
	ring.pivot_offset = card_size * 0.5
	ring.z_index = 20
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	sb.border_width_left = 3; sb.border_width_right  = 3
	sb.border_width_top  = 3; sb.border_width_bottom = 3
	sb.border_color = Color(1.0, 0.55, 0.12, 1.0)
	sb.corner_radius_top_left     = int(card_size.x * 0.1)
	sb.corner_radius_top_right    = int(card_size.x * 0.1)
	sb.corner_radius_bottom_right = int(card_size.x * 0.1)
	sb.corner_radius_bottom_left  = int(card_size.x * 0.1)
	ring.add_theme_stylebox_override("panel", sb)
	add_child(ring)

	var rw := create_tween()
	rw.tween_property(ring, "scale", Vector2(2.6, 2.6), 0.42) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	rw.parallel().tween_property(ring, "modulate:a", 0.0, 0.42) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	rw.tween_callback(ring.queue_free)

# ─────────────────────────────────────────────────────────────
# AI
# ─────────────────────────────────────────────────────────────
func _on_ai_mode_chosen(mode: GameState.TurnMode) -> void:
	turn_manager.select_mode(mode)

func _on_ai_attack_chosen(attacker_pos: Vector2i, target_pos: Vector2i) -> void:
	await get_tree().create_timer(0.3).timeout
	turn_manager.perform_attack(attacker_pos, target_pos)

func _on_ai_tech_chosen(tech_name: String) -> void:
	pending_tech_name = tech_name
	turn_manager.play_tech_card(tech_name)

# ─────────────────────────────────────────────────────────────
# Card Effect Flash (tech cards, outside battle overlay)
# ─────────────────────────────────────────────────────────────
const SFX_SPELL_FLASH: AudioStream = preload("res://assets/audio/sound_spellcasting_2.mp3")
const FULL_CARDS_DIR: String = "res://assets/textures/cards/full_cards/"

func _on_card_effect_triggered(card_name: String, card_type: String) -> void:
	await _show_card_effect_flash(card_name, card_type)
	turn_manager.emit_signal("card_effect_flash_done")

func _show_card_effect_flash(card_name: String, card_type: String) -> void:
	# Build full-screen overlay
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 50
	add_child(overlay)

	# Semi-transparent dim
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	# Load card image (same slug logic as DeckBuilder)
	var snake: String = card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
	var card_tex: Texture2D = null
	if SaveManager.nsfw_enabled:
		var nsfw: String = FULL_CARDS_DIR + snake + "_nsfw.png"
		if ResourceLoader.exists(nsfw):
			card_tex = load(nsfw) as Texture2D
		if card_tex == null:
			nsfw = FULL_CARDS_DIR + card_type + "_" + snake + "_nsfw.png"
			if ResourceLoader.exists(nsfw):
				card_tex = load(nsfw) as Texture2D
	if card_tex == null:
		var p: String = FULL_CARDS_DIR + snake + ".png"
		if ResourceLoader.exists(p):
			card_tex = load(p) as Texture2D
	if card_tex == null:
		var p: String = FULL_CARDS_DIR + card_type + "_" + snake + ".png"
		if ResourceLoader.exists(p):
			card_tex = load(p) as Texture2D

	var vp := get_viewport().get_visible_rect().size
	var card_h: float = minf(vp.y * 0.75, 600.0)
	var card_w: float = card_h * (819.0 / 1126.0)

	var card_img := TextureRect.new()
	card_img.texture = card_tex
	card_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_img.size = Vector2(card_w, card_h)
	card_img.position = Vector2((vp.x - card_w) * 0.5, (vp.y - card_h) * 0.5)
	card_img.pivot_offset = Vector2(card_w * 0.5, card_h * 0.5)
	card_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(card_img)

	# Burst ring around card
	var ring := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	sb.border_color = Color(1.0, 0.92, 0.5, 0.95)
	var bw: int = 10
	sb.border_width_left = bw; sb.border_width_right  = bw
	sb.border_width_top  = bw; sb.border_width_bottom = bw
	var cr: int = 24
	sb.corner_radius_top_left = cr; sb.corner_radius_top_right  = cr
	sb.corner_radius_bottom_left = cr; sb.corner_radius_bottom_right = cr
	ring.add_theme_stylebox_override("panel", sb)
	ring.size = Vector2(card_w, card_h)
	ring.position = card_img.position
	ring.pivot_offset = Vector2(card_w * 0.5, card_h * 0.5)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(ring)

	# Screen flash
	var flash := ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 1.0, 1.0, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(flash)

	# Spellcasting SFX
	var sfx := AudioStreamPlayer.new()
	sfx.stream = SFX_SPELL_FLASH
	sfx.bus = "SFX"
	add_child(sfx)
	sfx.finished.connect(sfx.queue_free)

	# Fade in overlay + card
	overlay.modulate.a = 0.0
	card_img.scale = Vector2(0.85, 0.85)
	var tin := create_tween()
	tin.tween_property(overlay, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tin.parallel().tween_property(dim, "color:a", 0.65, 0.2)
	tin.parallel().tween_property(card_img, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tin.finished

	sfx.play()

	# Burst ring expand + fade
	var t_ring := create_tween()
	t_ring.tween_property(ring, "scale", Vector2(1.5, 1.5), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t_ring.parallel().tween_property(ring, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

	# Screen flash
	var t_flash := create_tween()
	t_flash.tween_property(flash, "color:a", 0.7, 0.06).set_trans(Tween.TRANS_LINEAR)
	t_flash.tween_property(flash, "color:a", 0.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Linger
	await get_tree().create_timer(1.0).timeout

	# Fade out
	var tout := create_tween()
	tout.tween_property(overlay, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tout.finished

	overlay.queue_free()

# ─────────────────────────────────────────────────────────────
# Game Over
# ─────────────────────────────────────────────────────────────
func _on_return_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/campaign_map.tscn")

func _process(_delta: float) -> void:
	if _guide_box != null and _guide_box.visible:
		_guide_box.global_position = get_global_mouse_position() + Vector2(4.0, 112.0)
	if _shake_active:
		var ml: Control = get_node("MainLayout")
		ml.position = _shake_origin + Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)

func _on_game_over(winner: int) -> void:
	# ── VN-driven battle: skip the new sequence, go straight to VN ──────────
	var vn_win: String  = GameState.vn_on_win
	var vn_lose: String = GameState.vn_on_lose
	if vn_win != "" or vn_lose != "":
		GameState.vn_on_win  = ""
		GameState.vn_on_lose = ""
		_stop_battle_music()
		var player_won := (winner == 0)
		var vn_path: String = vn_win if player_won else vn_lose
		if vn_path != "" and vn_path != "game_over":
			var vn := preload("res://scenes/vn_player.tscn").instantiate()
			add_child(vn)
			var cb := func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			vn.play_scene(vn_path, cb)
			return

	# ── Campaign: record result now, before any animation ────────────────────
	if GameState.game_mode == GameState.GameMode.CAMPAIGN:
		var player_won := (winner == 0)
		if player_won:
			CampaignManager.complete_node(GameState.campaign_node_id)
		CampaignManager.pending_result = {
			"node_id": GameState.campaign_node_id,
			"won": player_won
		}

	# ── Disable all interactive UI immediately ───────────────────────────────
	if _end_turn_btn:
		_end_turn_btn.visible = false
	mode_panel.visible   = false
	action_panel.visible = false
	if _tech_fan:
		_tech_fan.visible = false
	if _attack_confirm_panel:
		_attack_confirm_panel.visible = false

	# ── 0. Brief pause so the crystal-hit-zero moment lands before the chaos ──
	await get_tree().create_timer(1.2).timeout

	# ── 1. Flip-reveal all face-down cards (with screen shake) ───────────────
	var ml: Control = get_node("MainLayout")
	_shake_origin = ml.position
	_shake_active = true
	# Fade battle music out; start result music immediately at shake
	_fade_out_battle_music(0.5)
	var result_music := AudioStreamPlayer.new()
	result_music.stream = load("res://assets/audio/bgm_ost_even_if_everything_flips.mp3") as AudioStream
	result_music.bus = &"Music"
	result_music.volume_db = -80.0
	result_music.finished.connect(func() -> void: result_music.play(68.0))
	add_child(result_music)
	result_music.play(68.0)
	var result_fade := create_tween()
	result_fade.tween_property(result_music, "volume_db", 0.0, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await _flip_reveal_all_cards()
	_shake_active = false
	ml.position = _shake_origin

	# ── 2. White flash fade-out ───────────────────────────────────────────────
	var white_overlay: ColorRect = await _fade_to_white()

	# ── 4. Build endgame screen while white covers it ─────────────────────────
	_show_endgame_screen(winner)

	# ── 5. Fade white overlay out to reveal endgame screen ───────────────────
	var t_reveal := create_tween()
	t_reveal.tween_property(white_overlay, "color:a", 0.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await t_reveal.finished
	white_overlay.queue_free()

# ─────────────────────────────────────────────────────────────
# Game-over helpers
# ─────────────────────────────────────────────────────────────

func _flip_reveal_all_cards() -> void:
	for p in range(2):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var inst := GameState.get_card(p, r, c)
				if not inst.face_up:
					await _flip_card_reveal(p, r, c)
					await get_tree().create_timer(0.030).timeout

func _flip_card_reveal(player: int, row: int, col: int) -> void:
	var node: Control = grid_nodes[player][row][col]
	# Squish inward (scale X: 1 → 0)
	var t1 := create_tween()
	t1.tween_property(node, "scale:x", 0.0, 0.06).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await t1.finished
	# Reveal state and refresh visual while invisible
	GameState.get_card(player, row, col).face_up = true
	_refresh_card_node(player, row, col)
	# Expand back (scale X: 0 → 1)
	var t2 := create_tween()
	t2.tween_property(node, "scale:x", 1.0, 0.06).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await t2.finished

func _fade_to_white() -> ColorRect:
	var overlay := ColorRect.new()
	overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	overlay.z_index = 100
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var t := create_tween()
	t.tween_property(overlay, "color:a", 1.0, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await t.finished
	return overlay

func _fade_out_battle_music(duration: float) -> void:
	if _battle_music == null:
		return
	var t := create_tween()
	t.tween_property(_battle_music, "volume_db", -80.0, duration)
	await t.finished
	_stop_battle_music()

func _show_endgame_screen(winner: int) -> void:
	var mode := GameState.game_mode
	var is_hot_seat := (mode == GameState.GameMode.HOT_SEAT)
	var is_ai_game  := mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN]

	# Determine win vs lose screen from the human player's perspective
	var is_win_screen: bool
	if winner == -1:
		is_win_screen = false  # draw → shown as defeat panel
	elif is_ai_game:
		is_win_screen = (winner == 0)
	else:
		is_win_screen = true   # LOCAL_2P and HOT_SEAT: one human always wins

	# Portrait visibility
	if winner != -1:
		if is_win_screen:
			var loser := 1 - winner
			if loser == 0 and _p1_portrait: _p1_portrait.visible = false
			if loser == 1 and _p2_portrait: _p2_portrait.visible = false
		else:
			# Lose screen: hide winner's (AI/opponent) portrait
			if winner == 0 and _p1_portrait: _p1_portrait.visible = false
			if winner == 1 and _p2_portrait: _p2_portrait.visible = false

	# Title text
	var title_text: String
	if winner == -1:
		title_text = "DRAW"
	elif is_win_screen:
		if is_hot_seat:
			title_text = "%s Wins!" % _player_names[winner]
		elif is_ai_game and winner == 0:
			var node_data: Variant = CampaignManager.get_node_data(GameState.campaign_node_id) \
				if mode == GameState.GameMode.CAMPAIGN else null
			var reward: int = node_data.data.get("reward_credits", 0) \
				if node_data != null else 0
			title_text = "You've Won the Duel." if reward == 0 \
				else "You've Won the Duel.  +%d cr" % reward
		else:
			title_text = "You've Won the Duel."
	else:
		title_text = "Defeat."

	# Award credits on win (VS AI / Campaign only)
	if is_win_screen and is_ai_game:
		MailboxManager.send_mail(
			"Battle Reward",
			"Credits Earned!",
			"You won and received 50 Credits.",
			{"type": "credits", "amount": 50}
		)

	# ── Build full-screen overlay ────────────────────────────────────────────
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 10
	overlay.modulate.a = 0.0
	add_child(overlay)

	# Background
	if is_win_screen and winner != -1:
		var bg := TextureRect.new()
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.texture      = load("res://assets/textures/ui/backgrounds/bg_win_battle.png")
		bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(bg)
	else:
		var bg := TextureRect.new()
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.texture      = load("res://assets/textures/ui/backgrounds/bg_game_over_2.png")
		bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(bg)

	# Dark vignette so text stays readable over the background image
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color        = Color(0.0, 0.0, 0.0, 0.50)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(vignette)

	# "Game Over" fade-in text (lose screen only)
	if not is_win_screen:
		var go_lbl := Label.new()
		go_lbl.text               = "Game Over"
		go_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		go_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		go_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		go_lbl.offset_left  = -600.0
		go_lbl.offset_right =  600.0
		go_lbl.offset_top   = -160.0
		go_lbl.offset_bottom =  60.0
		go_lbl.add_theme_font_size_override("font_size", 96)
		go_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		go_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		go_lbl.add_theme_constant_override("shadow_offset_x", 4)
		go_lbl.add_theme_constant_override("shadow_offset_y", 4)
		go_lbl.add_theme_constant_override("shadow_outline_size", 2)
		go_lbl.modulate.a = 0.0
		overlay.add_child(go_lbl)
		var go_tw := create_tween()
		go_tw.tween_property(go_lbl, "modulate:a", 1.0, 1.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# Title label
	if is_win_screen:
		var title_lbl := Label.new()
		title_lbl.text                 = title_text
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		title_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		title_lbl.offset_left  = -500.0
		title_lbl.offset_right =  500.0
		title_lbl.offset_top   = -80.0
		title_lbl.offset_bottom =  40.0
		title_lbl.add_theme_font_size_override("font_size", 52)
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
		overlay.add_child(title_lbl)

	# "Tap to continue" hint — blinks gently
	var hint_lbl := Label.new()
	hint_lbl.text = "tap anywhere to continue"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hint_lbl.offset_left   = -300.0
	hint_lbl.offset_right  =  300.0
	hint_lbl.offset_top    =  80.0
	hint_lbl.offset_bottom =  120.0
	hint_lbl.add_theme_font_size_override("font_size", 16)
	hint_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint_lbl)

	var blink_tw := create_tween().set_loops()
	blink_tw.tween_property(hint_lbl, "modulate:a", 0.2, 0.9).set_trans(Tween.TRANS_SINE)
	blink_tw.tween_property(hint_lbl, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

	# Overlay catches all clicks
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var dest: String = "res://scenes/campaign_map.tscn" \
		if mode == GameState.GameMode.CAMPAIGN \
		else "res://scenes/main_menu.tscn"

	var _clicked := [false]
	overlay.gui_input.connect(func(ev: InputEvent) -> void:
		if _clicked[0]:
			return
		var is_press: bool = \
			(ev is InputEventMouseButton \
				and (ev as InputEventMouseButton).pressed \
				and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
			or (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed)
		if not is_press:
			return
		_clicked[0] = true
		blink_tw.kill()
		var black := ColorRect.new()
		black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		black.color = Color(0.0, 0.0, 0.0, 0.0)
		black.z_index = 200
		black.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(black)
		var out_tw := create_tween()
		out_tw.tween_property(black, "color:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
		out_tw.tween_callback(func() -> void: get_tree().change_scene_to_file(dest)))

	# Fade in the endgame screen
	var ft := create_tween()
	ft.tween_property(overlay, "modulate:a", 1.0, 0.7)
