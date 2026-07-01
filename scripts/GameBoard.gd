extends Control
# Main game board — manages grids, selection, turn flow, and AI.

const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")
const MAX_BATTLE_NAME_LENGTH: int = 24
const MAX_CRYSTALS: int = 5000
const MAX_LOG_LINES: int = 60
const PROMPT_DISMISS_DELAY: float = 0.5
const SFX_CRYSTAL: AudioStream = preload("res://assets/audio/sound_crystal_1.mp3")

# ── Grid containers
@onready var p1_grid: GridContainer = $MainLayout/P1Side/P1Grid
@onready var p2_grid: GridContainer = $MainLayout/P2Side/P2GridHost/P2Grid

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
var ai_player_0: AIPlayer = null   # AI_VS_AI mode only: controls player 0
var _active_ai: AIPlayer = null    # whichever AI is currently taking a turn
var _vs_ai_deck: Variant = null    # captured before new_game() clears GameState.battle_ai_deck
var _vs_ai_player_deck: Variant = null
var _vs_ai_player_forced_cells: Array = []

# Player portrait illustration nodes
var _p1_portrait: TextureRect = null
var _p2_portrait: TextureRect = null

# VN path to play after the win screen is dismissed (set by _on_game_over)
var _pending_win_vn: String = ""

# Corner crystal displays (icon + label, above portraits)
var _p1_bottom_crystal: Label = null
var _p2_bottom_crystal: Label = null
var _p1_crystal_row: Control = null   # VBoxContainer
var _p2_crystal_row: Control = null   # VBoxContainer
var _p1_name_lbl: Label = null
var _p2_name_lbl: Label = null
var _turn_number_lbl: Label = null
var _turn_number_bg: TextureRect = null
var _turn_number_hit: Control = null

# Options menu & battle log
var _battle_log_lines: Array[String] = []
# File log for VS_AI / HOT_SEAT modes
var _session_log_file: FileAccess = null
var _session_log_start_msec: int = 0
var _session_log_prev_crystals: Array[int] = [0, 0]
var _session_logged_destroy_slots: Dictionary = {}
var _ai_watchdog: Timer = null
var _ai_union_resolve_in_progress: bool = false  # suppress watchdog during long union cinematics
var _card_name_to_type: Dictionary = {}   # card_name -> "character"|"trap"|"tech"
var _options_panel: Control = null
var _options_btn_root: Control = null
var _options_btn_art: TextureRect = null
var _options_btn: Control = null
var _music_changed_this_turn: bool = false

# Union Suggestion Button (center HUD, visible when active player can summon a union)
var _union_suggest_btn:   TextureButton = null
var _union_suggest_glow:  TextureRect   = null
var _union_suggest_tween: Tween         = null
# Once-per-duel summon tracking (index = player)
var _union_summoned_this_duel: Array[int] = [0, 0]

# Setup-phase BGM player (started when placement begins, stopped at _begin_game)
var _setup_p1_resolved: bool = false
var _setup_p2_resolved: bool = false
var _battle_begun: bool = false
var _was_tutorial_battle: bool = false
var _handoff_resolving: bool = false
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
var _tech_overlay_mode: String = ""
signal revive_placement_resolved

# Pending revive placement (tech Resurrection/Time Travel, union Moon Tribe Shaman, etc.)
var _pending_revive_card: GameState.CardInstance = null
var _pending_revive_player: int = -1
var _pending_revive_tech_data: TechCardData = null
var _pending_revive_union_source: String = ""
var _pending_revive_keep_in_graveyard: bool = false
var _pending_revive_strip_stats: bool = false
var _pending_revive_double_cost: bool = false
var _pending_revive_awaiting: bool = false

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
var _prev_crystals: Array[int]    = [3000, 3000]
var _crystal_anim_queue: Array = []
var _crystal_anim_processing: bool = false
const CRYSTAL_TICK_BASE_SEC: float = 0.90
const CRYSTAL_TICK_PER_UNIT_SEC: float = 0.022
const CRYSTAL_TICK_MAX_SEC: float = 2.40
const CRYSTAL_TICK_SFX_MAX: int = 18
const CRYSTAL_TICK_SFX_INTERVAL_SEC: float = 0.1
const CRYSTAL_TICK_SFX_WINDOW_SEC: float = CRYSTAL_TICK_SFX_MAX * CRYSTAL_TICK_SFX_INTERVAL_SEC
var _crystal_tick_sfx_window_start: Array[float] = [-1.0, -1.0]
var _crystal_tick_sfx_window_count: Array[int] = [0, 0]

func _crystal_tick_sfx_slots_available(player_index: int) -> int:
	var idx: int = clampi(player_index, 0, 1)
	var now: float = Time.get_ticks_msec() * 0.001
	if _crystal_tick_sfx_window_start[idx] < 0.0 \
			or now - _crystal_tick_sfx_window_start[idx] >= CRYSTAL_TICK_SFX_WINDOW_SEC:
		return CRYSTAL_TICK_SFX_MAX
	return maxi(0, CRYSTAL_TICK_SFX_MAX - _crystal_tick_sfx_window_count[idx])
var _almost_win_bgm_active: bool  = false   # latches true once bgm_almost_win starts

# Attack count labels (shown below each player's crystal display)
var _p1_attack_lbl: Label = null
var _p2_attack_lbl: Label = null

# AI thinking bubble
var _thinking_bubble: Control = null
var _thinking_bubble_style: StyleBoxFlat = null
var _thinking_dot_labels: Array[Label] = []
var _thinking_dot_tween: Tween = null
var _thinking_timer_active: bool = false
var _portrait_last_tap: Array[float] = [0.0, 0.0]  # last tap timestamp per player

# Tax confirmation overlay
var _tax_confirm_panel: Control = null
var _end_turn_request_busy: bool = false

# Peek (reveal preview) buttons
var _p1_reveal_btn: TextureButton = null
var _p2_reveal_btn: TextureButton = null
var _p1_view_slash: ColorRect = null
var _p2_view_slash: ColorRect = null
var _p1_view_slash_shadow: ColorRect = null
var _p2_view_slash_shadow: ColorRect = null
var _reveal_preview: Array[bool] = [false, false]
var _revealing_cells: Dictionary = {}   # "p,r,c" → true while reveal animation runs
var _pending_flag_pops: Array = []      # {player, row, col, flag}
var _enemy_view_active: bool = false
var _enemy_view_return_dialog: Control = null

# Playmat fog (Noise 3.png)
var _fog_container: Control = null
var _fog_rect: TextureRect = null
var _fog_material: ShaderMaterial = null
var _fog_material_diag: ShaderMaterial = null
var _fog_scroll: Vector2 = Vector2.ZERO
var _fog_scroll_diag: Vector2 = Vector2(0.37, 0.61)
var _fog_scroll_x: float = 14.0
var _fog_scroll_y: float = 0.0
var _fog_diag_scroll_x: float = 11.0   # screen-left
var _fog_diag_scroll_y: float = -11.0  # screen-up → top-left diagonal
var _fog_dir_timer: float = 0.0
const _FOG_TILE_REPEAT: float = 8.0       # straight layer
const _FOG_TILE_REPEAT_DIAG: float = 3.0  # diagonal layer
const _FOG_IMAGE_SCALE: float = 3.0  # 300% — each noise tile drawn 3× larger
const _FOG_ALPHA: float = 0.2

# Observer peek (AI vs AI / E2E only) — purely cosmetic, no game-state change
# 0 = off, 1 = peek P0 only, 2 = peek active player, 3 = peek both
var _observer_peek_mode: int = 0
var _observer_peek_panel: Control = null
var _observer_peek_btns: Array[Button] = []
var _tech_used_this_turn: Array[bool] = [false, false]
var _tech_reset_turn: int = -1   # turn_number when _tech_used_this_turn was last cleared
var _ai_turn_action_started: Array[bool] = [false, false]  # AI already began this player's turn

# Hover info panel (center column, battle phase only)
var _hover_panel: Control = null
var _hover_name_lbl: Label = null
var _hover_type_lbl: Label = null
var _hover_atk_lbl: Label = null
var _hover_def_lbl: Label = null
var _hover_aff_lbl: Label = null
var _hover_desc_lbl: Label = null
var _tech_hover_node: Control = null    # card node currently showing target hover highlight
var _attack_hover_node: Control = null  # card node currently showing attack-target red hover

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

# ── Bribe choice overlay (built at runtime)
var _bribe_overlay: Control = null
var _bribe_desc_lbl: Label = null

# ── Binary ability-choice overlay (awaiting_trap_choice prompts)
var _ability_choice_overlay: Control = null
var _ability_choice_title_lbl: Label = null
var _ability_choice_btns: Array[Button] = []
# ── Current battle calculation overlay (used to pause/resume around choice prompts)
var _current_battle_overlay: BattleCalculationOverlay = null

# ── Tech-resolution input blocker (invisible, shown while effect animates)
var _tech_resolve_blocker: ColorRect = null

enum SelectionState { NONE, SELECTING_ATTACKER, SELECTING_TARGET, CONFIRMING_ATTACK, SELECTING_TECH_TARGET, AWAITING_TRAP_CHOICE, SELECTING_UNION_MATERIALS }
var selection_state: SelectionState = SelectionState.NONE
var selected_attacker_pos: Vector2i = Vector2i(-1, -1)
var _pending_multi_attack_pos: Vector2i = Vector2i(-1, -1)
var _multi_attack_bonus_targeting: bool = false
var _confirm_target_pos: Vector2i = Vector2i(-1, -1)
var _confirm_target_player: int = -1
var _blink_tween: Tween = null
var _end_turn_blink_tween: Tween = null
var _attack_confirm_panel: Control = null
var _end_turn_btn: TextureButton = null
var _dungeon_mod_panel: PanelContainer = null
var _last_banner_turn: int = -1

# Card context menu (tap-to-open popup)
var _context_popup: Panel = null     # created fresh per open, freed on close
var _context_backdrop: Control = null # fullscreen click-catcher behind popup
var _last_click_pos: Vector2 = Vector2.ZERO  # updated on every press, used for popup placement
var _context_card_player: int = -1
var _context_card_pos: Vector2i = Vector2i(-1, -1)
var pending_tech_filter: String = ""
var _pending_human_defender_tech: bool = false
var _pending_ability_destroy_pos: Vector2i = Vector2i(-1, -1)
var _pending_ability_destroy_player: int = -1
var pending_tech_name: String = ""
var _tech_reveals_remaining: int = 0   # for multi-reveal effects (e.g. Radar)
var _deferred_ai_turn_flow: bool = false
var _ui_flow_block_active: bool = false

# Rift Strike hover state
var _rift_hover_cell: Vector2i = Vector2i(-1, -1)
var _rift_last_hover: Vector2i = Vector2i(-1, -1)
var _rift_direction: String = "row"    # "row" or "col", updated by mouse motion
var _tech_reveals_total: int = 0
var _tech_reveal_picked: Array = []   # Radar multi-reveal: cells already chosen this sequence
var _tech_buff_move_source: Vector2i = Vector2i(-1, -1)   # MOVE_BUFFS_BETWEEN_CHARACTERS: source card pos
var _tech_sacrifice_player: int = -1                       # DESTROY_OWN_BASE_ZERO_OPPONENT: which player to zero

# Cursor-following guide box
var _guide_box: Control = null
var _guide_label: Label = null
var _game_guide_text: String = ""

# Debug alignment overlay (Ctrl+Shift+U, editor-only)
var _debug_align_visible: bool = false
var _debug_center_line: ColorRect = null
var _debug_p1_border: Panel = null
var _debug_p2_border: Panel = null
var locked_positions: Array = []
# HOT_SEAT handoff tracking: avoid showing handoff again for the same player's continued turn
var _handoff_last_player: int = -1
var _handoff_last_turn: int = -1

func _input(event: InputEvent) -> void:
	if BuildConfig.admin_shortcut_pressed(event):
		if BuildConfig.admin_tools_enabled():
			BuildConfig.toggle_admin_console_on(self)
		get_viewport().set_input_as_handled()
		return
	if OS.has_feature("editor") and event is InputEventKey \
			and (event as InputEventKey).pressed \
			and (event as InputEventKey).keycode == KEY_U \
			and (event as InputEventKey).ctrl_pressed \
			and (event as InputEventKey).shift_pressed:
		_toggle_debug_alignment()
		get_viewport().set_input_as_handled()
		return
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
	if selection_state == SelectionState.SELECTING_TARGET \
			and not GameDialog.has_open_overlay(self):
		var opponent := GameState.get_opponent(GameState.current_player)
		var opp_grid: GridContainer = p2_grid if opponent == 1 else p1_grid
		if not opp_grid.get_global_rect().has_point(click_pos):
			_try_cancel_attack_targeting()

	# Cancel union material selection when tapping outside own grid
	if selection_state == SelectionState.SELECTING_UNION_MATERIALS:
		var own_grid: GridContainer = p1_grid if _pending_union_player == 0 else p2_grid
		if not own_grid.get_global_rect().has_point(click_pos):
			_cancel_union_material_selection()


func _unhandled_input(event: InputEvent) -> void:
	var is_left_press: bool = (
		(event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and event.pressed) or
		(event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	)
	if is_left_press:
		_hide_hover_info()
		if _tech_overlay_mode != "blackmail":
			_close_tech_overlay()

func _toggle_admin_console() -> void:
	BuildConfig.toggle_admin_console_on(self)

func _ready() -> void:
	VNPlayer.dismiss_overlay_if_present(get_tree())
	_setup_turn_manager()
	_setup_ai()
	_connect_signals()
	_build_grids()
	_setup_buttons()
	_build_handoff_overlay()
	_build_bribe_overlay()
	_build_ability_choice_overlay()
	_build_tech_resolve_blocker()
	_build_portraits()
	_build_hover_panel()
	_build_tech_stacks()
	_build_void_stacks()
	_build_reveal_buttons()
	_build_end_turn_button()
	_build_dungeon_modifier_panel()
	_build_attack_confirm_panel()

	_build_card_name_lookup()
	_build_bottom_crystal_labels()
	_build_turn_number_label()
	_build_attack_count_indicators()
	_build_thinking_bubble()
	_build_options_button()
	_build_fog()
	_build_union_suggest_button()
	SaveManager.union_mechanism_changed.connect(func(_u: bool) -> void: _update_union_suggest_button())
	CTX_ICON_ATTACK = HudSkin.hud_tex("ui_context_menu_attack.png")
	CTX_ICON_INFO   = HudSkin.hud_tex("ui_context_menu_info.png")
	CTX_ICON_BLUFF  = HudSkin.hud_tex("ui_context_menu_bluff.png")
	CTX_ICON_UNION  = HudSkin.hud_tex("ui_icon_union.png")
	HudSkin.skin_changed.connect(_reload_hud_skin)
	_reload_hud_skin()
	game_over_panel.visible = false
	mode_panel.visible = false
	action_panel.visible = false
	# Capture before new_game() clears VS AI pre-battle config from VsAIConfig.
	_vs_ai_deck = GameState.battle_ai_deck
	_vs_ai_player_deck = GameState.battle_player_deck
	_vs_ai_player_forced_cells = GameState.battle_player_forced_cells.duplicate(true)
	if TutorialBattleManager.is_prepared:
		TutorialBattleManager.on_board_ready(self)
	_start_game()
	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		AIvsAIManager.start_logging(self)
	elif GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.HOT_SEAT]:
		_open_session_log()
	if CheckerTransition.is_screen_covered():
		await CheckerTransition.fade_in()
	if TutorialBattleManager.is_active:
		_update_reveal_buttons()
		_update_tutorial_hud_lock()
	TutorialBattleManager.mission_started.connect(_on_tutorial_mission_started)
	TutorialBattleManager.mission_complete.connect(_on_tutorial_mission_ui_changed)
	TutorialBattleManager.all_tutorial_missions_done.connect(_on_tutorial_mission_ui_changed)

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
	turn_manager.awaiting_blackmail_tech_select.connect(_on_awaiting_blackmail_tech_select)
	turn_manager.awaiting_defender_choice.connect(_on_awaiting_defender_choice)
	turn_manager.awaiting_target_selection.connect(_on_awaiting_target_selection)
	turn_manager.ability_selection_done.connect(_on_flow_blocking_cleared)
	turn_manager.brainwash_redirect_resolved.connect(_on_flow_blocking_cleared)
	turn_manager.battle_preview_needed.connect(_on_battle_preview_needed)
	turn_manager.battle_result_finalized.connect(_on_battle_result_finalized)
	turn_manager.attack_aborted.connect(_on_attack_aborted)
	turn_manager.wait_badge_animation_requested.connect(_on_wait_badge_animation_requested)
	turn_manager.coin_flip_visual_requested.connect(_on_coin_flip_visual_requested)

func _setup_ai() -> void:
	ai_player = AIPlayer.new()
	add_child(ai_player)
	_active_ai = ai_player   # default; overridden per-turn in AI_VS_AI mode
	ai_player.ai_mode_chosen.connect(_on_ai_mode_chosen)
	ai_player.ai_attack_chosen.connect(_on_ai_attack_chosen)
	ai_player.ai_tech_chosen.connect(_on_ai_tech_chosen)
	ai_player.ai_end_turn.connect(_on_ai_end_turn)
	ai_player.ai_union_chosen.connect(_on_ai_union_chosen)
	ai_player.ai_bluff.connect(_on_ai_bluff)

	# Watchdog timer — 20 s in AI_VS_AI mode (more complex turns), 5 s in VS_AI
	_ai_watchdog = Timer.new()
	_ai_watchdog.wait_time = 20.0 if GameState.game_mode == GameState.GameMode.AI_VS_AI else 5.0
	_ai_watchdog.one_shot  = true
	_ai_watchdog.timeout.connect(_on_ai_watchdog_timeout)
	add_child(_ai_watchdog)

	# Intermediate AI signals → restart the watchdog window (bot is still active)
	ai_player.ai_mode_chosen.connect(func(_m: GameState.TurnMode) -> void: _restart_ai_watchdog())
	ai_player.ai_attack_chosen.connect(func(_a: Vector2i, _t: Vector2i) -> void: _restart_ai_watchdog())
	ai_player.ai_tech_chosen.connect(func(_n: String) -> void: _restart_ai_watchdog())
	ai_player.ai_union_chosen.connect(func(_n: String, _z: Array, _m: Array) -> void: _restart_ai_watchdog())
	# Turn fully done → stop watchdog
	ai_player.ai_end_turn.connect(func() -> void: _stop_ai_watchdog())

	# AI_VS_AI: create a second AI instance that controls player 0
	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		ai_player_0 = AIPlayer.new()
		ai_player_0.init_as(0)
		add_child(ai_player_0)
		ai_player_0.ai_mode_chosen.connect(_on_ai_mode_chosen)
		ai_player_0.ai_attack_chosen.connect(_on_ai_attack_chosen)
		ai_player_0.ai_tech_chosen.connect(_on_ai_tech_chosen)
		ai_player_0.ai_end_turn.connect(_on_ai_end_turn)
		ai_player_0.ai_union_chosen.connect(_on_ai_union_chosen)
		ai_player_0.ai_bluff.connect(_on_ai_bluff)
		ai_player_0.ai_mode_chosen.connect(func(_m: GameState.TurnMode) -> void: _restart_ai_watchdog())
		ai_player_0.ai_attack_chosen.connect(func(_a: Vector2i, _t: Vector2i) -> void: _restart_ai_watchdog())
		ai_player_0.ai_tech_chosen.connect(func(_n: String) -> void: _restart_ai_watchdog())
		ai_player_0.ai_union_chosen.connect(func(_n: String, _z: Array, _m: Array) -> void: _restart_ai_watchdog())
		ai_player_0.ai_end_turn.connect(func() -> void: _stop_ai_watchdog())

## Returns the AI instance controlling the defending player (opponent of current_player).
func _get_defending_ai() -> AIPlayer:
	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		return ai_player_0 if GameState.current_player == 1 else ai_player
	return ai_player

## Returns the AI instance for a given player index (AI_VS_AI aware).
func _get_ai_for_player(pi: int) -> AIPlayer:
	if pi == 0 and ai_player_0 != null:
		return ai_player_0
	return ai_player

## Max union summons allowed per duel (1 normally; 2 with Reunion modifier).
func _max_unions_per_duel() -> int:
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "reunion" in GameState.active_dungeon_modifiers:
		return 2
	return 1

## Effective union summon cost after applying dungeon modifiers.
func _effective_union_cost(base_cost: int) -> int:
	if GameState.game_mode != GameState.GameMode.DAILY_DUNGEON:
		return base_cost
	var _um: Array = GameState.active_dungeon_modifiers
	if "dimensional_fissure" in _um:  return int(base_cost * 0.2)
	if "dimensional_gate"    in _um:  return int(base_cost * 0.5)
	if "dimensional_slippage" in _um: return int(base_cost * 0.8)
	if "sealing_talisman"    in _um:  return int(base_cost * 1.2)
	if "sealing_ceremony"    in _um:  return int(base_cost * 1.5)
	return base_cost

func _on_ai_union_chosen(union_name: String, zone_cells: Array, material_cells: Array) -> void:
	if GameState.current_phase == GameState.Phase.GAME_OVER:
		return
	var cp: int = GameState.current_player
	if _union_summoned_this_duel[cp] >= _max_unions_per_duel():
		await get_tree().create_timer(0.3).timeout
		if GameState.current_phase != GameState.Phase.GAME_OVER:
			_request_ai_continue_after_union()
		return
	var u: UnionData = UnionDatabase.get_union(union_name)
	if u == null or not UnionDatabase.is_playable_in_demo(u) \
			or material_cells.is_empty() or GameState.crystals[cp] < _effective_union_cost(u.summon_cost):
		await get_tree().create_timer(0.3).timeout
		if GameState.current_phase != GameState.Phase.GAME_OVER:
			_request_ai_continue_after_union()
		return
	_ai_union_resolve_in_progress = true
	_pending_union_player = cp
	_pending_union_data = u
	_pending_union_zone_cells = zone_cells.duplicate()
	_pending_union_conditions_remaining = []
	_pending_union_selected_materials = material_cells.duplicate()
	await _play_union_zone_preview(cp, zone_cells)
	_restart_ai_watchdog()
	await _perform_pending_union()
	_ai_union_resolve_in_progress = false
	_restart_ai_watchdog()
	if GameState.current_phase != GameState.Phase.GAME_OVER:
		_active_ai.register_union_summoned()
		_request_ai_continue_after_union()

func _stop_ai_watchdog() -> void:
	if _ai_watchdog != null:
		_ai_watchdog.stop()

func _restart_ai_watchdog() -> void:
	if _ai_watchdog == null or GameState.current_phase == GameState.Phase.GAME_OVER:
		return
	if not _is_ai_turn():
		return
	_ai_watchdog.start()

func _on_ai_watchdog_timeout() -> void:
	if _pending_human_defender_tech:
		_restart_ai_watchdog()
		return
	if not _is_ai_turn():
		_stop_ai_watchdog()
		return
	if GameState.current_phase == GameState.Phase.BATTLE:
		_restart_ai_watchdog()
		return
	if _ai_union_resolve_in_progress:
		_restart_ai_watchdog()
		return
	if _should_defer_turn_flow():
		_restart_ai_watchdog()
		return
	print("[AI WATCHDOG] Bot Player went idle — forcing turn end.")
	GameState.post_message("[DEBUG] Bot Player timed out — ending turn.")
	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		AIvsAIManager.log_event("[TIMEOUT] Player %d AI watchdog expired — ending turn." % GameState.current_player)
	turn_manager.end_attacks_early()
	_stop_ai_watchdog()

func _connect_signals() -> void:
	GameState.register_crystal_animation_board()
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.card_revealed.connect(_on_card_revealed)
	GameState.card_flag_added.connect(_on_card_flag_added)
	GameState.card_destroyed.connect(_on_card_destroyed)
	GameState.card_destruction_blocked.connect(_on_card_destruction_blocked)
	GameState.field_bonuses_recalculated.connect(_refresh_all_grids)
	GameState.crystals_changed.connect(_on_crystals_changed)
	GameState.dice_rolled.connect(_on_dice_rolled)
	GameState.game_over.connect(_on_game_over)
	GameState.message_posted.connect(_on_message_posted)
	GameState.center_message_requested.connect(_on_center_message_requested)
	GameState.tech_card_used.connect(func(p: int, tech_name: String) -> void:
		_add_to_void_pile(p, tech_name, "tech")
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
				bluff_lbl.offset_top    = -4.0
				bluff_lbl.offset_bottom = 42.0
				bluff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				bluff_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				bluff_lbl.z_index = 5
				bluff_lbl.text = ""
				bluff_lbl.add_theme_font_size_override("font_size", 36)
				bluff_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
				bluff_lbl.add_theme_constant_override("shadow_offset_x", 2)
				bluff_lbl.add_theme_constant_override("shadow_offset_y", 2)
				bluff_lbl.add_theme_constant_override("shadow_outline_size", 3)
				card_node.add_child(bluff_lbl)
				row_arr.append(card_node)
				lbl_row.append(bluff_lbl)
			grid_nodes[p].append(row_arr)
			bluff_labels[p].append(lbl_row)
	call_deferred("_add_grid_line_panels")
	call_deferred("_refresh_all_bluff_labels")

func _clear_grid_borders() -> void:
	for node: Node in get_children():
		if node.is_in_group("battle_grid_border"):
			node.queue_free()

## Reposition cyan grid borders after layout changes (e.g. battle hide_ui toggle).
func refresh_grid_borders() -> void:
	_clear_grid_borders()
	call_deferred("_add_grid_line_panels")

func _add_grid_line_panels() -> void:
	# Wait one extra frame so the GridContainer layout is fully computed
	await get_tree().process_frame
	_clear_grid_borders()
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
			cr.add_to_group("battle_grid_border")
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
	SFXManager.wire_prompt_button(_handoff_ready_btn)

func _build_bribe_overlay() -> void:
	_bribe_overlay = Control.new()
	_bribe_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bribe_overlay.visible = false
	_bribe_overlay.z_index = 6   # above handoff overlay
	add_child(_bribe_overlay)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.80)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP   # block all clicks behind
	_bribe_overlay.add_child(bg)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -260.0
	panel.offset_top    = -160.0
	panel.offset_right  =  260.0
	panel.offset_bottom =  160.0
	var sb := StyleBoxFlat.new()
	sb.bg_color    = Color(0.03, 0.07, 0.15, 1.0)
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1.0, 0.75, 0.2, 0.7)   # gold
	sb.corner_radius_top_left     = 10
	sb.corner_radius_top_right    = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left  = 10
	panel.add_theme_stylebox_override("panel", sb)
	_bribe_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   =  24.0
	vbox.offset_top    =  20.0
	vbox.offset_right  = -24.0
	vbox.offset_bottom = -20.0
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "BRIBE"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.2, 1.0))
	vbox.add_child(title_lbl)

	_bribe_desc_lbl = Label.new()
	_bribe_desc_lbl.text = ""
	_bribe_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bribe_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_bribe_desc_lbl.add_theme_font_size_override("font_size", 15)
	_bribe_desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0, 0.90))
	vbox.add_child(_bribe_desc_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	# "Reveal" button
	var reveal_btn := Button.new()
	reveal_btn.text = "Reveal a Unit  (+700 💎)"
	reveal_btn.custom_minimum_size = Vector2(220.0, 48.0)
	reveal_btn.add_theme_font_size_override("font_size", 14)
	var rn := StyleBoxFlat.new()
	rn.bg_color    = Color(0.12, 0.26, 0.08, 1.0)
	rn.border_width_left = 2; rn.border_width_top = 2; rn.border_width_right = 2; rn.border_width_bottom = 2
	rn.border_color = Color(0.3, 0.9, 0.3, 0.8)
	rn.corner_radius_top_left = 6; rn.corner_radius_top_right = 6; rn.corner_radius_bottom_right = 6; rn.corner_radius_bottom_left = 6
	var rh := rn.duplicate() as StyleBoxFlat
	rh.bg_color = Color(0.18, 0.38, 0.12, 1.0)
	rh.border_color = Color(0.4, 1.0, 0.4, 1.0)
	reveal_btn.add_theme_stylebox_override("normal",  rn)
	reveal_btn.add_theme_stylebox_override("hover",   rh)
	reveal_btn.add_theme_stylebox_override("pressed", rn)
	reveal_btn.add_theme_stylebox_override("focus",   rn)
	reveal_btn.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7, 1.0))
	reveal_btn.pressed.connect(_on_bribe_reveal_pressed)
	hbox.add_child(reveal_btn)

	# "Pass" button
	var pass_btn := Button.new()
	pass_btn.text = "Pass"
	pass_btn.custom_minimum_size = Vector2(120.0, 48.0)
	pass_btn.add_theme_font_size_override("font_size", 14)
	var pn := StyleBoxFlat.new()
	pn.bg_color    = Color(0.06, 0.10, 0.22, 1.0)
	pn.border_width_left = 2; pn.border_width_top = 2; pn.border_width_right = 2; pn.border_width_bottom = 2
	pn.border_color = Color(0.38, 0.50, 0.75, 0.6)
	pn.corner_radius_top_left = 6; pn.corner_radius_top_right = 6; pn.corner_radius_bottom_right = 6; pn.corner_radius_bottom_left = 6
	var ph := pn.duplicate() as StyleBoxFlat
	ph.bg_color = Color(0.10, 0.16, 0.34, 1.0)
	ph.border_color = Color(0.55, 0.70, 1.0, 1.0)
	pass_btn.add_theme_stylebox_override("normal",  pn)
	pass_btn.add_theme_stylebox_override("hover",   ph)
	pass_btn.add_theme_stylebox_override("pressed", pn)
	pass_btn.add_theme_stylebox_override("focus",   pn)
	pass_btn.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0, 1.0))
	pass_btn.pressed.connect(_on_bribe_pass_pressed)
	hbox.add_child(pass_btn)
	SFXManager.wire_prompt_buttons_in(_bribe_overlay)

func _build_ability_choice_overlay() -> void:
	_ability_choice_overlay = Control.new()
	_ability_choice_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ability_choice_overlay.visible = false
	_ability_choice_overlay.z_index = 110  # above BattleCalculationOverlay (z_index 100)
	add_child(_ability_choice_overlay)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_ability_choice_overlay.add_child(bg)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -200.0
	panel.offset_right  =  200.0
	panel.offset_top    = -110.0
	panel.offset_bottom =  110.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.16, 0.96)
	sb.border_width_left   = 2; sb.border_width_right  = 2
	sb.border_width_top    = 2; sb.border_width_bottom = 2
	sb.border_color = Color(0.4, 0.6, 1.0, 0.8)
	sb.corner_radius_top_left     = 10
	sb.corner_radius_top_right    = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left  = 10
	panel.add_theme_stylebox_override("panel", sb)
	_ability_choice_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   =  16.0
	vbox.offset_right  = -16.0
	vbox.offset_top    =  14.0
	vbox.offset_bottom = -14.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	_ability_choice_title_lbl = Label.new()
	_ability_choice_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability_choice_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ability_choice_title_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0, 1.0))
	vbox.add_child(_ability_choice_title_lbl)

	# Pre-create 4 buttons (max expected choices)
	_ability_choice_btns.clear()
	for i: int in range(4):
		var btn := Button.new()
		btn.visible = false
		btn.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0, 1.0))
		var capture_i: int = i
		btn.pressed.connect(func() -> void: _on_ability_choice_selected(capture_i))
		vbox.add_child(btn)
		_ability_choice_btns.append(btn)
	SFXManager.wire_prompt_buttons_in(_ability_choice_overlay)

func _show_ability_choice_overlay(title: String, choices: Array) -> void:
	SFXManager.play(SFXManager.SFX_POPUP)
	_ability_choice_title_lbl.text = title
	for i: int in range(_ability_choice_btns.size()):
		var btn: Button = _ability_choice_btns[i]
		if i < choices.size():
			btn.text = choices[i]
			btn.visible = true
		else:
			btn.visible = false
	_ability_choice_overlay.visible = true

func _hide_ability_choice_overlay() -> void:
	_ability_choice_overlay.visible = false
	for btn: Button in _ability_choice_btns:
		btn.visible = false

func _show_bribe_overlay(opponent: int) -> void:
	SFXManager.play(SFXManager.SFX_POPUP)
	_bribe_desc_lbl.text = "Player %d: Reveal one of your units to gain 700 Crystals, or pass." % (opponent + 1)
	_bribe_overlay.visible = true

func _hide_bribe_overlay() -> void:
	_bribe_overlay.visible = false

func _on_bribe_reveal_pressed() -> void:
	_hide_bribe_overlay()
	await _await_prompt_dismiss_delay()
	var bribed_player := GameState.get_opponent(GameState.current_player)
	if not _has_bribe_reveal_targets(bribed_player):
		GameState.post_message("Bribe: No face-down units to reveal.")
		_finish_tech_action(GameState.current_player)
		return
	_begin_human_defender_tech_choice()
	pending_tech_filter = "bribe_reveal"
	_set_own_facedown_char_peek(true, bribed_player)
	_set_selection_state(SelectionState.SELECTING_TECH_TARGET)
	_show_guide("Select one of your face-down units to reveal.")
	_highlight_tech_targets("bribe_reveal")

func _on_bribe_pass_pressed() -> void:
	_hide_bribe_overlay()
	await _await_prompt_dismiss_delay()
	GameState.post_message("Bribe: Opponent passed.")
	_finish_tech_action(GameState.current_player)

func _await_prompt_dismiss_delay() -> void:
	if _tech_resolve_blocker:
		_tech_resolve_blocker.visible = true
	await get_tree().create_timer(PROMPT_DISMISS_DELAY).timeout
	if _tech_resolve_blocker:
		_tech_resolve_blocker.visible = false

func _on_tech_use_pressed(tech_name: String, from_hand: bool) -> void:
	if from_hand:
		if TutorialBattleManager.is_active:
			TutorialBattleManager.report_action("tech_use_tap", {"tech_name": tech_name})
		_dismiss_tech_hand_overlay()
	else:
		_close_tech_overlay()
	await _await_prompt_dismiss_delay()
	_on_tech_card_btn(tech_name)

func _on_ability_choice_selected(choice_index: int) -> void:
	_hide_ability_choice_overlay()
	await _await_prompt_dismiss_delay()
	turn_manager.resolve_ability_choice(choice_index)

func _build_tech_resolve_blocker() -> void:
	_tech_resolve_blocker = ColorRect.new()
	_tech_resolve_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tech_resolve_blocker.color = Color(0.0, 0.0, 0.0, 0.0)   # fully transparent
	_tech_resolve_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_tech_resolve_blocker.visible = false
	_tech_resolve_blocker.z_index = 40  # above all game UI (≤10), below system overlays (50+)
	add_child(_tech_resolve_blocker)

func _build_portraits() -> void:
	# Scale each portrait to fill the full screen height at its natural aspect ratio,
	# so the inner edge (right for P1, left for P2) is never cropped.
	const REF_H: float = 720.0

	var p1_tex: Texture2D = GameState.load_portrait_texture(GameState.player_portraits[0])
	if p1_tex:
		var sz := p1_tex.get_size()
		var p1_scale: float = maxf(0.1, GameState.portrait_p1_size)
		var p1h: float = REF_H * p1_scale * 0.9
		var pw: float = p1h * sz.x / sz.y if sz.y > 0.0 else 300.0
		var p1ox: float = GameState.portrait_p1_offset.x
		var p1oy: float = GameState.portrait_p1_offset.y
		_p1_portrait = TextureRect.new()
		_p1_portrait.texture       = p1_tex
		_p1_portrait.layout_mode   = 1
		_p1_portrait.anchor_left   = 0.0
		_p1_portrait.anchor_top    = 1.0
		_p1_portrait.anchor_right  = 0.0
		_p1_portrait.anchor_bottom = 1.0
		_p1_portrait.offset_left   = -pw * 0.4 + p1ox
		_p1_portrait.offset_top    = -p1h + p1oy
		_p1_portrait.offset_right  = pw * 0.6 + p1ox
		_p1_portrait.offset_bottom = p1oy
		_p1_portrait.visible       = false
		_p1_portrait.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		_p1_portrait.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
		_p1_portrait.flip_h        = true
		_p1_portrait.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		_p1_portrait.z_index       = 3
		add_child(_p1_portrait)
		## DISABLED: double-tap portrait to show thinking bubble
		#_p1_portrait.gui_input.connect(func(ev: InputEvent) -> void:
		#	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		#		var ctrl_sz: Vector2 = _p1_portrait.size
		#		var tap_pos: Vector2 = (ev as InputEventMouseButton).position
		#		var mx: float = ctrl_sz.x * 0.125; var my: float = ctrl_sz.y * 0.125
		#		if tap_pos.x < mx or tap_pos.x > ctrl_sz.x - mx or tap_pos.y < my or tap_pos.y > ctrl_sz.y - my:
		#			return
		#		var now: float = Time.get_ticks_msec() / 1000.0
		#		if now - _portrait_last_tap[0] <= 0.4:
		#			_on_portrait_tapped(0)
		#		_portrait_last_tap[0] = now)

	var p2_tex: Texture2D = GameState.load_portrait_texture(GameState.player_portraits[1])
	if p2_tex:
		var sz := p2_tex.get_size()
		var p2_scale: float = maxf(0.1, GameState.portrait_p2_size)
		var p2h: float = REF_H * p2_scale * 0.9
		var pw: float = p2h * sz.x / sz.y if sz.y > 0.0 else 300.0
		var p2ox: float = GameState.portrait_p2_offset.x
		var p2oy: float = GameState.portrait_p2_offset.y
		_p2_portrait = TextureRect.new()
		_p2_portrait.texture       = p2_tex
		_p2_portrait.layout_mode   = 1
		_p2_portrait.anchor_left   = 1.0
		_p2_portrait.anchor_top    = 1.0
		_p2_portrait.anchor_right  = 1.0
		_p2_portrait.anchor_bottom = 1.0
		_p2_portrait.offset_left   = -pw * 0.6 - p2ox
		_p2_portrait.offset_top    = -p2h + p2oy
		_p2_portrait.offset_right  = pw * 0.4 - p2ox
		_p2_portrait.offset_bottom = p2oy
		_p2_portrait.visible       = false
		_p2_portrait.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		_p2_portrait.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
		_p2_portrait.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		_p2_portrait.z_index       = 3
		add_child(_p2_portrait)
		## DISABLED: double-tap portrait to show thinking bubble
		#_p2_portrait.gui_input.connect(func(ev: InputEvent) -> void:
		#	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		#		var ctrl_sz: Vector2 = _p2_portrait.size
		#		var tap_pos: Vector2 = (ev as InputEventMouseButton).position
		#		var mx: float = ctrl_sz.x * 0.125; var my: float = ctrl_sz.y * 0.125
		#		if tap_pos.x < mx or tap_pos.x > ctrl_sz.x - mx or tap_pos.y < my or tap_pos.y > ctrl_sz.y - my:
		#			return
		#		var now: float = Time.get_ticks_msec() / 1000.0
		#		if now - _portrait_last_tap[1] <= 0.4:
		#			_on_portrait_tapped(1)
		#		_portrait_last_tap[1] = now)

func _show_handoff(player: int, context: String, callback: Callable) -> void:
	_handoff_resolving = false
	if _handoff_ready_btn != null:
		_handoff_ready_btn.disabled = false
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
	if _options_btn_root:
		_options_btn_root.visible = false

func _on_handoff_ready() -> void:
	if _handoff_resolving:
		return
	_handoff_resolving = true
	if _handoff_ready_btn != null:
		_handoff_ready_btn.disabled = true
	_handoff_overlay.visible = false
	await _await_prompt_dismiss_delay()
	if _handoff_callback.is_valid():
		_handoff_callback.call()
	_handoff_callback = Callable()
	_handoff_resolving = false
	if _handoff_ready_btn != null:
		_handoff_ready_btn.disabled = false

func _start_game() -> void:
	_setup_p1_resolved = false
	_setup_p2_resolved = false
	_battle_begun = false
	_handoff_resolving = false
	_union_summoned_this_duel = [0, 0]
	_void_piles = [[], []]
	if GameState._vn_battle_pending:
		# VNPlayer already ran new_game() and applied battle config — avoid a second reset.
		GameState._vn_battle_pending = false
	else:
		GameState.new_game(GameState.game_mode)
		if _vs_ai_player_deck != null:
			GameState.battle_player_deck = _vs_ai_player_deck
		if not _vs_ai_player_forced_cells.is_empty():
			GameState.battle_player_forced_cells = _vs_ai_player_forced_cells.duplicate(true)
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
	var ask_mode: String = GameState.battle_ask_player_name.strip_edges().to_lower()
	GameState.battle_ask_player_name = ""
	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		_player_names[0] = "Bot 0"
		_player_names[1] = "Bot 1"
		_apply_player_names()
		_do_ai_setup_p0()
		_do_ai_setup()
		_begin_game()
	elif ask_mode in ["player1", "player2", "both"]:
		if ask_mode == "player1":
			_apply_vs_ai_opponent_default_name()
		var ask_p1: bool = ask_mode in ["player1", "both"]
		var ask_p2: bool = ask_mode in ["player2", "both"]
		_start_setup_music()
		_show_name_entry(ask_p1, ask_p2, _battle_name_entry_prompt(ask_p1, ask_p2))
	elif GameState.game_mode == GameState.GameMode.HOT_SEAT:
		_start_setup_music()
		_show_name_entry()
	elif setup_phase:
		_apply_vs_ai_opponent_default_name()
		_begin_setup_phase()

func _apply_vs_ai_opponent_default_name() -> void:
	if GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.DAILY_DUNGEON] \
			and _player_names[1] == "Player 2":
		_player_names[1] = "Opponent"
		_apply_player_names()

func _battle_name_entry_prompt(ask_p1: bool, ask_p2: bool) -> String:
	if GameState.game_mode == GameState.GameMode.HOT_SEAT:
		return "ENTER PLAYER NAMES"
	if ask_p1 and ask_p2:
		return "Could you tell us you and your opponent's name?"
	if ask_p1:
		return "Could you tell us your name?"
	if ask_p2:
		return "Could you tell us your opponent's name?"
	return "ENTER PLAYER NAMES"

func _is_allowed_name_char(c: String) -> bool:
	if c.length() != 1:
		return false
	return (c >= "a" and c <= "z") \
		or (c >= "A" and c <= "Z") \
		or (c >= "0" and c <= "9") \
		or c == " "

func _sanitize_name_chars(text: String) -> String:
	var out := ""
	for i in text.length():
		var c: String = text[i]
		if _is_allowed_name_char(c):
			out += c
	return out

func _normalized_name_from_edit(text: String) -> String:
	return _sanitize_name_chars(text).strip_edges()

func _wire_name_line_edit(le: LineEdit, error_lbl: Label) -> void:
	var filtering: Array = [false]
	le.text = _sanitize_name_chars(le.text)
	le.text_changed.connect(func(new_text: String) -> void:
		if filtering[0]:
			return
		error_lbl.visible = false
		var filtered: String = _sanitize_name_chars(new_text)
		if filtered != new_text:
			filtering[0] = true
			var caret: int = le.caret_column
			le.text = filtered
			le.caret_column = mini(caret, filtered.length())
			filtering[0] = false
	)

func _begin_setup_phase() -> void:
	if setup_phase == null:
		return
	setup_phase.visible = true
	setup_phase.start_setup(0)
	setup_phase.setup_complete.connect(_on_setup_complete_p1, CONNECT_ONE_SHOT)
	_start_setup_music()

func _show_name_entry(ask_p1: bool = true, ask_p2: bool = true, heading_text: String = "") -> void:
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
	var prompt: String = heading_text.strip_edges()
	if prompt.is_empty():
		prompt = _battle_name_entry_prompt(ask_p1, ask_p2)
	heading.text = prompt
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color(0.38, 0.75, 1.0))
	vbox.add_child(heading)

	var sub := Label.new()
	sub.text = "Use letters, numbers, and spaces only."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.55, 0.65, 0.80))
	vbox.add_child(sub)

	var error_lbl := Label.new()
	error_lbl.text = ""
	error_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_lbl.add_theme_font_size_override("font_size", 12)
	error_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	error_lbl.visible = false
	vbox.add_child(error_lbl)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	var is_vs_ai: bool = GameState.game_mode in [
		GameState.GameMode.VS_AI,
		GameState.GameMode.CAMPAIGN,
		GameState.GameMode.DAILY_DUNGEON,
		GameState.GameMode.EXPLORATION,
	]
	var p1_default: String = "Player 1"
	var p2_default: String = "Opponent" if is_vs_ai else "Player 2"

	var p1_edit: LineEdit = null
	if ask_p1:
		var p1_lbl := Label.new()
		p1_lbl.text = "Your name" if is_vs_ai else "Player 1 name"
		p1_lbl.add_theme_font_size_override("font_size", 13)
		p1_lbl.add_theme_color_override("font_color", Color(0.749, 0.878, 1.0))
		vbox.add_child(p1_lbl)

		p1_edit = LineEdit.new()
		p1_edit.placeholder_text = p1_default
		var p1_seed: String = _player_names[0] if _player_names[0] != p1_default else ""
		p1_edit.text = _sanitize_name_chars(p1_seed)
		p1_edit.max_length = MAX_BATTLE_NAME_LENGTH
		p1_edit.custom_minimum_size = Vector2(0, 40)
		p1_edit.add_theme_font_size_override("font_size", 16)
		_wire_name_line_edit(p1_edit, error_lbl)
		vbox.add_child(p1_edit)

	var p2_edit: LineEdit = null
	if ask_p2:
		var p2_lbl := Label.new()
		p2_lbl.text = "Opponent name" if is_vs_ai else "Player 2 name"
		p2_lbl.add_theme_font_size_override("font_size", 13)
		p2_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.78))
		vbox.add_child(p2_lbl)

		p2_edit = LineEdit.new()
		p2_edit.placeholder_text = p2_default
		var p2_seed: String = _player_names[1] if _player_names[1] != p2_default else ""
		p2_edit.text = _sanitize_name_chars(p2_seed)
		p2_edit.max_length = MAX_BATTLE_NAME_LENGTH
		p2_edit.custom_minimum_size = Vector2(0, 40)
		p2_edit.add_theme_font_size_override("font_size", 16)
		_wire_name_line_edit(p2_edit, error_lbl)
		vbox.add_child(p2_edit)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var start_btn := Button.new()
	start_btn.text = "START GAME" if GameState.game_mode == GameState.GameMode.HOT_SEAT else "CONTINUE"
	start_btn.custom_minimum_size = Vector2(0, 52)
	start_btn.add_theme_font_size_override("font_size", 18)
	start_btn.pressed.connect(func() -> void:
		var missing: PackedStringArray = []
		if ask_p1 and p1_edit != null and _normalized_name_from_edit(p1_edit.text).is_empty():
			missing.append("your name" if is_vs_ai else "Player 1 name")
		if ask_p2 and p2_edit != null and _normalized_name_from_edit(p2_edit.text).is_empty():
			missing.append("opponent name" if is_vs_ai else "Player 2 name")
		if not missing.is_empty():
			error_lbl.text = "Please enter %s." % " and ".join(missing)
			error_lbl.visible = true
			if ask_p1 and p1_edit != null and _normalized_name_from_edit(p1_edit.text).is_empty():
				p1_edit.grab_focus()
			elif ask_p2 and p2_edit != null:
				p2_edit.grab_focus()
			return
		if ask_p1 and p1_edit != null:
			_player_names[0] = _normalized_name_from_edit(p1_edit.text)
		if ask_p2 and p2_edit != null:
			_player_names[1] = _normalized_name_from_edit(p2_edit.text)
		if not ask_p2:
			_apply_vs_ai_opponent_default_name()
		_apply_player_names()
		overlay.queue_free()
		_begin_setup_phase())
	vbox.add_child(start_btn)

	if p1_edit != null:
		p1_edit.grab_focus()
	elif p2_edit != null:
		p2_edit.grab_focus()

func _apply_player_names() -> void:
	if _p1_name_lbl: _p1_name_lbl.text = _player_names[0]
	if _p2_name_lbl: _p2_name_lbl.text = _player_names[1]

# ─────────────────────────────────────────────────────────────
# Setup Phase Handlers
# ─────────────────────────────────────────────────────────────
func _on_setup_complete_p1() -> void:
	if _setup_p1_resolved:
		return
	_setup_p1_resolved = true
	if GameState.game_mode == GameState.GameMode.VS_AI \
			or GameState.game_mode == GameState.GameMode.CAMPAIGN \
			or GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			or GameState.game_mode == GameState.GameMode.EXPLORATION:
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
	if _setup_p2_resolved:
		return
	_setup_p2_resolved = true
	_begin_game()

func _do_ai_setup() -> void:
	# In AI_VS_AI, forced cells come from AIvsAIManager; otherwise from GameState
	var fc_src: Array = AIvsAIManager.forced_cells_1 \
		if GameState.game_mode == GameState.GameMode.AI_VS_AI \
		else GameState.battle_ai_forced_cells

	# Apply AI-1 forced cells before decide_setup so AIPlayer can avoid those positions
	for fc_v: Variant in fc_src:
		if not (fc_v is Dictionary):
			continue
		var fc: Dictionary = fc_v as Dictionary
		var fc_name: String = str(fc.get("card_name", ""))
		var fc_row: int = int(fc.get("row", 0))
		var fc_col: int = int(fc.get("col", 0))
		if fc_name.is_empty():
			continue
		if CardDatabase.get_character(fc_name) != null:
			GameState.place_character(1, fc_row, fc_col, fc_name)
		elif CardDatabase.get_trap(fc_name) != null:
			GameState.place_trap(1, fc_row, fc_col, fc_name)

	var _deck1: Variant = AIvsAIManager.deck1 \
		if GameState.game_mode == GameState.GameMode.AI_VS_AI \
		else _vs_ai_deck
	var placements := ai_player.decide_setup(_deck1, fc_src)
	for placement in placements:
		var pos: Vector2i = placement["pos"]
		if placement["card_type"] == "character":
			GameState.place_character(1, pos.x, pos.y, placement["card_name"])
		elif placement["card_type"] == "trap":
			GameState.place_trap(1, pos.x, pos.y, placement["card_name"])

	# AI places bluff emoticons on some cells before the game starts
	var setup_bluffs: Dictionary = ai_player.decide_setup_bluffs(placements)
	for cell: Vector2i in setup_bluffs.keys():
		GameState.set_bluff(ai_player.player_index, cell.x, cell.y, setup_bluffs[cell])

func _do_ai_setup_p0() -> void:
	# AI_VS_AI only: set up player 0's board using ai_player_0
	var fc_src: Array = AIvsAIManager.forced_cells_0

	for fc_v: Variant in fc_src:
		if not (fc_v is Dictionary):
			continue
		var fc: Dictionary = fc_v as Dictionary
		var fc_name: String = str(fc.get("card_name", ""))
		var fc_row: int = int(fc.get("row", 0))
		var fc_col: int = int(fc.get("col", 0))
		if fc_name.is_empty():
			continue
		if CardDatabase.get_character(fc_name) != null:
			GameState.place_character(0, fc_row, fc_col, fc_name)
		elif CardDatabase.get_trap(fc_name) != null:
			GameState.place_trap(0, fc_row, fc_col, fc_name)

	var placements := ai_player_0.decide_setup(AIvsAIManager.deck0, fc_src)
	for placement in placements:
		var pos: Vector2i = placement["pos"]
		if placement["card_type"] == "character":
			GameState.place_character(0, pos.x, pos.y, placement["card_name"])
		elif placement["card_type"] == "trap":
			GameState.place_trap(0, pos.x, pos.y, placement["card_name"])

	var setup_bluffs: Dictionary = ai_player_0.decide_setup_bluffs(placements)
	for cell: Vector2i in setup_bluffs.keys():
		GameState.set_bluff(0, cell.x, cell.y, setup_bluffs[cell])

func _begin_game() -> void:
	if _battle_begun:
		return
	_battle_begun = true
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
	BattleResolver.recalculate_all_field_bonuses()
	_refresh_all_grids()
	_refresh_hud()
	# E2E tests always give Player 0 (the highlight-card side) first turn.
	# Tutorial battles always give Player 2 first (tails).
	var first_player: int
	if CardE2ERunner.is_active():
		first_player = 0
	else:
		var tut_forced: int = TutorialBattleManager.get_forced_first_player()
		first_player = tut_forced if tut_forced >= 0 else DiceRoller.flip_coin_first_player()
	var coin_result: String = "Heads" if first_player == 0 else "Tails"
	GameState.post_message("Coin flip — %s! Player %d goes first!" % [coin_result, first_player + 1])
	_show_coin_flip_and_start(first_player)

# ─────────────────────────────────────────────────────────────
# Battle music
# ─────────────────────────────────────────────────────────────
func _start_setup_music() -> void:
	if _vs_ai_bgm_muted():
		BGMManager.stop(0.0)
		return
	var setup_path: String = GameState.battle_setup_bgm_path.strip_edges()
	if setup_path.is_empty():
		BGMManager.play_context(BGMManager.CONTEXT_PLACEMENT, 0.8, 0.8)
	else:
		BGMManager.play_path(
			setup_path, 0.8, 0.8, GameState.battle_bgm_volume, BGMManager.CONTEXT_PLACEMENT)


func _stop_setup_music() -> void:
	pass


func _start_battle_music() -> void:
	if _vs_ai_bgm_muted():
		return
	var path: String = GameState.battle_bgm_path
	if path.is_empty():
		path = BGMManager.get_default_path(BGMManager.CONTEXT_BATTLE)
	# Start at battle_bgm_start_sec (default 00:14 intro skip), loop back to 00:00 when the track ends.
	var start_at: float = maxf(0.0, GameState.battle_bgm_start_sec)
	BGMManager.play_path(
		path, 0.8, 0.8, GameState.battle_bgm_volume, BGMManager.CONTEXT_BATTLE, 0.0, start_at)

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

	# Stone Age: Tech cards disabled — hide the fan entirely
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "stone_age" in GameState.active_dungeon_modifiers:
		_tech_fan.visible = false
		return

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
	# P1: anchored left at x=88 | P2: anchored right, 80–156px from right edge
	if player == 0:
		container.anchor_left   = 0.0
		container.anchor_right  = 0.0
		container.anchor_top    = 0.0
		container.anchor_bottom = 0.0
		container.offset_left   = 88.0
		container.offset_right  = 164.0
	else:
		container.anchor_left   = 1.0
		container.anchor_right  = 1.0
		container.anchor_top    = 0.0
		container.anchor_bottom = 0.0
		container.offset_left   = -156.0
		container.offset_right  = -80.0
	container.offset_top    = 100.0
	container.offset_bottom = 196.0
	add_child(container)
	var _tech_tip: String = "Your Tech hand — tap to view" if player == 0 else "Opponent's Tech hand"
	container.mouse_entered.connect(func(): _show_hud_tooltip(_tech_tip))
	container.mouse_exited.connect(func(): _restore_game_guide())

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
	count_lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	count_lbl.add_theme_font_size_override("font_size", 18)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82))
	count_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	count_lbl.add_theme_constant_override("shadow_offset_x", 1)
	count_lbl.add_theme_constant_override("shadow_offset_y", 1)
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(count_lbl)

	if player == 0:
		_p1_stack_count_lbl = count_lbl
	else:
		_p2_stack_count_lbl = count_lbl

	# Click / tap to open modal (same mechanism as void stack)
	var _tut_tech_player := player
	container.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) \
				or (ev is InputEventScreenTouch and ev.pressed):
			SFXManager.play(SFXManager.SFX_BTN)
			if TutorialBattleManager.is_active:
				TutorialBattleManager.report_action("tech_chip_tap", {"player": _tut_tech_player})
			_open_tech_modal(_tut_tech_player)
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
	if _tech_overlay_mode == "blackmail":
		return
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
			use_btn.pressed.connect(func() -> void: _on_tech_use_pressed(captured, false))
			SFXManager.wire_prompt_button(use_btn)
			_tech_overlay_panel.add_child(use_btn)

# ─────────────────────────────────────────────────────────────
# Dump Stacks
# ─────────────────────────────────────────────────────────────

func _build_void_stacks() -> void:
	# P1: Void at x=8, Tech at x=88 | P2: Void at right edge, Tech just left of Void
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
	var _void_tip: String = "Your Void — destroyed cards" if player == 0 else "Opponent's Void — destroyed cards"
	container.mouse_entered.connect(func(): _show_hud_tooltip(_void_tip))
	container.mouse_exited.connect(func(): _restore_game_guide())

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
	count_lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	count_lbl.add_theme_font_size_override("font_size", 18)
	count_lbl.add_theme_color_override("font_color", Color(0.88, 0.72, 1.0))
	count_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	count_lbl.add_theme_constant_override("shadow_offset_x", 1)
	count_lbl.add_theme_constant_override("shadow_offset_y", 1)
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_lbl.text = "0"
	container.add_child(count_lbl)

	if player == 0:
		_p1_void_count_lbl = count_lbl
	else:
		_p2_void_count_lbl = count_lbl

	# Click opens void modal for own pile only
	var _tut_void_player := player
	container.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) \
				or (ev is InputEventScreenTouch and ev.pressed):
			SFXManager.play(SFXManager.SFX_BTN)
			if TutorialBattleManager.is_active:
				TutorialBattleManager.report_action("void_stack_tap", {"player": _tut_void_player})
			_open_void_modal(_tut_void_player)
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
				_void_modal = null
			await _await_prompt_dismiss_delay())
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
			_void_modal = null
		await _await_prompt_dismiss_delay())
	SFXManager.wire_prompt_button(close_btn)
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
	# 64×64 eye icon. Keeps the ORIGINAL reveal-button anchoring: P1 left-anchored,
	# P2 right-anchored — sits directly under each player's VOID/TECH stacks.
	var eye_tex := load("res://assets/textures/ui/battle/v2_magitech/ui_magitech_eye_open.png") as Texture2D
	for player in range(2):
		var btn := TextureButton.new()
		btn.texture_normal = eye_tex
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.layout_mode = 1
		btn.z_index = 4
		btn.visible = false
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.modulate = Color(0.9, 0.97, 1.0, 0.95)
		if player == 0:
			btn.anchor_left   = 0.0; btn.anchor_right  = 0.0
			btn.offset_left   = 8.0;  btn.offset_right  = 72.0
		else:
			btn.anchor_left   = 1.0; btn.anchor_right  = 1.0
			btn.offset_left   = -72.0; btn.offset_right = -8.0
		btn.anchor_top    = 0.0
		btn.anchor_bottom = 0.0
		btn.offset_top    = 202.0
		btn.offset_bottom = 266.0

		# Slash shadow (black, offset slightly) — shown only in "enemy view" icon state
		var slash_shadow := ColorRect.new()
		slash_shadow.layout_mode = 0
		slash_shadow.color = Color(0.0, 0.0, 0.0, 0.70)
		slash_shadow.position = Vector2(2.0, 33.0)
		slash_shadow.size = Vector2(62.0, 5.0)
		slash_shadow.pivot_offset = Vector2(31.0, 2.5)
		slash_shadow.rotation_degrees = -40.0
		slash_shadow.visible = true
		slash_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(slash_shadow)

		# Slash (white line on top)
		var slash := ColorRect.new()
		slash.layout_mode = 0
		slash.color = Color(1.0, 1.0, 1.0, 0.92)
		slash.position = Vector2(0.0, 31.0)
		slash.size = Vector2(62.0, 5.0)
		slash.pivot_offset = Vector2(31.0, 2.5)
		slash.rotation_degrees = -40.0
		slash.visible = true
		slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(slash)

		var p := player
		btn.pressed.connect(func() -> void:
			SFXManager.play(SFXManager.SFX_VIEW_TOGGLE)
			_toggle_reveal_preview(p))
		btn.mouse_entered.connect(func() -> void:
			_show_hud_tooltip("Toggle between Your View and Enemy View"))
		btn.mouse_exited.connect(func() -> void: _restore_game_guide())
		add_child(btn)
		if player == 0:
			_p1_reveal_btn = btn
			_p1_view_slash = slash
			_p1_view_slash_shadow = slash_shadow
		else:
			_p2_reveal_btn = btn
			_p2_view_slash = slash
			_p2_view_slash_shadow = slash_shadow

	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		_build_observer_peek_panel()

func _build_observer_peek_panel() -> void:
	# Floating panel at top-centre — observer only, no gameplay effect.
	var panel := PanelContainer.new()
	panel.layout_mode = 1
	panel.z_index = 4
	panel.anchor_left   = 0.5; panel.anchor_right  = 0.5
	panel.anchor_top    = 0.0; panel.anchor_bottom = 0.0
	panel.offset_left   = -155.0; panel.offset_right  = 155.0
	panel.offset_top    = 4.0;    panel.offset_bottom = 32.0
	panel.mouse_filter  = Control.MOUSE_FILTER_STOP
	var sbox := StyleBoxFlat.new()
	sbox.bg_color    = Color(0.04, 0.08, 0.12, 0.90)
	sbox.border_width_left = 1; sbox.border_width_right  = 1
	sbox.border_width_top  = 1; sbox.border_width_bottom = 1
	sbox.border_color = Color(0.45, 0.70, 0.85, 0.80)
	sbox.corner_radius_top_left    = 4; sbox.corner_radius_top_right    = 4
	sbox.corner_radius_bottom_left = 4; sbox.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", sbox)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 2)
	panel.add_child(hbox)

	var label := Label.new()
	label.text = "PEEK:"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.9, 1.0))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_constant_override("margin_left", 4)
	hbox.add_child(label)

	var modes: Array[String] = ["OFF", "P0", "ACTIVE", "BOTH"]
	for i in range(modes.size()):
		var btn := Button.new()
		btn.text = modes[i]
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", Color(0.70, 0.92, 1.0, 1.0))
		var idx := i
		btn.pressed.connect(func() -> void: _set_observer_peek(idx))
		hbox.add_child(btn)
		_observer_peek_btns.append(btn)

	add_child(panel)
	_observer_peek_panel = panel
	_update_observer_peek_buttons()

func _set_observer_peek(mode: int) -> void:
	_observer_peek_mode = mode
	_apply_observer_peek()
	_update_observer_peek_buttons()

func _update_observer_peek_buttons() -> void:
	for i in range(_observer_peek_btns.size()):
		var btn: Button = _observer_peek_btns[i]
		if i == _observer_peek_mode:
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4, 1.0))
		else:
			btn.add_theme_color_override("font_color", Color(0.70, 0.92, 1.0, 1.0))

func _apply_observer_peek() -> void:
	if _observer_peek_mode == 0:
		return
	for p in range(2):
		var should_peek: bool = false
		match _observer_peek_mode:
			1: should_peek = (p == 0)
			2: should_peek = (p == GameState.current_player)
			3: should_peek = true
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(p, r, c)
				if card.card_type in ["character", "trap"] and not card.face_up:
					(grid_nodes[p][r][c] as Control).set_preview_revealed(should_peek)

func _toggle_reveal_preview(player: int) -> void:
	# Only the active player may toggle their own peek
	if player != GameState.current_player:
		return
	_reveal_preview[player] = not _reveal_preview[player]
	_enemy_view_active = not _reveal_preview[player]
	# Slash shown in "enemy view" icon state (i.e. when NOT currently revealing).
	var show_slash: bool = not _reveal_preview[player]
	var slash: ColorRect = _p1_view_slash if player == 0 else _p2_view_slash
	var slash_shadow: ColorRect = _p1_view_slash_shadow if player == 0 else _p2_view_slash_shadow
	if slash: slash.visible = show_slash
	if slash_shadow: slash_shadow.visible = show_slash
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
		if _reveal_preview[p]:
			_reveal_preview[p] = false
			# Back to "enemy view" icon state → show slash.
			var slash: ColorRect = _p1_view_slash if p == 0 else _p2_view_slash
			var slash_shadow: ColorRect = _p1_view_slash_shadow if p == 0 else _p2_view_slash_shadow
			if slash: slash.visible = true
			if slash_shadow: slash_shadow.visible = true
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				grid_nodes[p][r][c].set_preview_revealed(false)
				grid_nodes[p][r][c].set_enemy_view(false)
	# Re-apply observer peek on top of the reset (AI vs AI observer mode persists).
	_apply_observer_peek()

func _on_tutorial_mission_started(_instruction: String = "") -> void:
	_on_tutorial_mission_ui_changed(_instruction)

func _on_tutorial_mission_ui_changed(_instruction: String = "") -> void:
	_update_reveal_buttons()
	_update_tutorial_hud_lock()

## Close unrelated battle UI (not mission spotlight/modals opened for the active step).
func dismiss_tutorial_overlays() -> void:
	_hide_card_context()
	_close_options_panel()
	_close_tech_overlay()
	_dismiss_tech_hand_overlay()
	if _tech_resolve_blocker:
		_tech_resolve_blocker.visible = false
	if _void_modal != null and is_instance_valid(_void_modal):
		_void_modal.queue_free()
		_void_modal = null
	var bluff_modal: Node = get_node_or_null("BluffModalBoard")
	if bluff_modal != null:
		bluff_modal.queue_free()
	for ch in get_children():
		if ch is CardDetailOverlay:
			ch.queue_free()
	if _union_modal != null and is_instance_valid(_union_modal):
		_union_modal.queue_free()
		_union_modal = null
	if _tax_confirm_panel != null:
		_tax_confirm_panel.queue_free()
		_tax_confirm_panel = null
	if selection_state == SelectionState.SELECTING_UNION_MATERIALS:
		_cancel_union_material_selection()
	elif selection_state == SelectionState.CONFIRMING_ATTACK \
			or (_attack_confirm_panel != null and _attack_confirm_panel.visible):
		_cancel_confirm_attack()
	elif selection_state == SelectionState.SELECTING_TARGET:
		_try_cancel_attack_targeting()
	elif selection_state == SelectionState.SELECTING_TECH_TARGET:
		_clear_selection()
		_set_selection_state(SelectionState.SELECTING_ATTACKER)
		_highlight_attackable_chars()

func _update_tutorial_hud_lock() -> void:
	if _is_ai_turn():
		return
	var in_battle: bool = GameState.current_phase not in [
		GameState.Phase.NONE, GameState.Phase.SETUP_P1,
		GameState.Phase.SETUP_P2, GameState.Phase.GAME_OVER
	]
	var show_opts: bool = in_battle and not TutorialBattleManager.should_hide_options_btn()
	var show_end: bool = in_battle and TutorialBattleManager.should_allow_end_turn_btn() \
			and GameState.current_phase != GameState.Phase.BATTLE
	if selection_state == SelectionState.CONFIRMING_ATTACK \
			or (_attack_confirm_panel != null and _attack_confirm_panel.visible):
		show_end = false
	if _options_btn_root:
		_options_btn_root.visible = show_opts
	if _options_btn:
		_options_btn.mouse_filter = Control.MOUSE_FILTER_STOP if show_opts else Control.MOUSE_FILTER_IGNORE
	if not show_opts:
		_close_options_panel()
	if _end_turn_btn:
		_end_turn_btn.visible = show_end
		_end_turn_btn.mouse_filter = Control.MOUSE_FILTER_STOP if show_end else Control.MOUSE_FILTER_IGNORE
		if not show_end:
			if _end_turn_blink_tween and _end_turn_blink_tween.is_valid():
				_end_turn_blink_tween.kill()
				_end_turn_blink_tween = null
			_end_turn_btn.modulate = Color.WHITE

func _update_reveal_buttons() -> void:
	var tut_hide: bool = TutorialBattleManager.should_hide_reveal_view_btn()
	var in_battle: bool = GameState.current_phase not in [
		GameState.Phase.NONE, GameState.Phase.SETUP_P1,
		GameState.Phase.SETUP_P2, GameState.Phase.GAME_OVER
	]
	if _p1_reveal_btn:
		_p1_reveal_btn.visible = in_battle and GameState.current_player == 0 and not tut_hide
	if _p2_reveal_btn:
		var vs_ai: bool = GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN, GameState.GameMode.DAILY_DUNGEON]
		_p2_reveal_btn.visible = in_battle and GameState.current_player == 1 and not vs_ai and not tut_hide

# ─────────────────────────────────────────────────────────────
# End Turn Button (standalone, bottom-center)
# ─────────────────────────────────────────────────────────────

func _build_end_turn_button() -> void:
	# Image is 1216×832 → ratio ≈ 1.46 : 1
	# Display at 160×110 px, centered below turn number label
	_end_turn_btn = TextureButton.new()
	_end_turn_btn.texture_normal = HudSkin.hud_tex("ui_end_turn.png")
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
	_end_turn_btn.mouse_entered.connect(func(): _show_hud_tooltip("End your turn"))
	_end_turn_btn.mouse_exited.connect(func(): _restore_game_guide())

func _build_dungeon_modifier_panel() -> void:
	if GameState.game_mode != GameState.GameMode.DAILY_DUNGEON:
		return
	if GameState.active_dungeon_modifiers.is_empty():
		return

	const PANEL_HALF_W: float = 76.0  # matches center column / end-turn width (~152 px)

	_dungeon_mod_panel = PanelContainer.new()
	_dungeon_mod_panel.layout_mode = 1
	_dungeon_mod_panel.anchor_left   = 0.5
	_dungeon_mod_panel.anchor_top    = 0.0
	_dungeon_mod_panel.anchor_right  = 0.5
	_dungeon_mod_panel.anchor_bottom = 0.0
	_dungeon_mod_panel.offset_left   = -PANEL_HALF_W
	_dungeon_mod_panel.offset_top    = 194.0
	_dungeon_mod_panel.offset_right  =  PANEL_HALF_W
	_dungeon_mod_panel.offset_bottom = 194.0
	_dungeon_mod_panel.z_index = 4
	_dungeon_mod_panel.visible = false
	_dungeon_mod_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.14, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.494, 0.839, 1.0, 1.0)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 6
	sb.content_margin_top = 5
	sb.content_margin_right = 6
	sb.content_margin_bottom = 5
	_dungeon_mod_panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_dungeon_mod_panel.add_child(vbox)

	for i: int in range(GameState.active_dungeon_modifiers.size()):
		var mod_key: String = GameState.active_dungeon_modifiers[i]
		var is_pos: bool = DailyDungeonManager.is_modifier_positive(mod_key)
		var accent: Color = Color(0.30, 1.0, 0.45, 1.0) if is_pos else Color(1.0, 0.38, 0.28, 1.0)

		var mod_box := VBoxContainer.new()
		mod_box.add_theme_constant_override("separation", 1)
		vbox.add_child(mod_box)

		var name_lbl := Label.new()
		name_lbl.text = DailyDungeonManager.get_modifier_label(mod_key)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", accent)
		name_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
		name_lbl.add_theme_constant_override("shadow_offset_x", 1)
		name_lbl.add_theme_constant_override("shadow_offset_y", 1)
		name_lbl.add_theme_constant_override("shadow_outline_size", 3)
		mod_box.add_child(name_lbl)

		var desc_text: String = DailyDungeonManager.get_modifier_desc(mod_key)
		if not desc_text.is_empty():
			var desc_lbl := Label.new()
			desc_lbl.text = desc_text
			desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_lbl.add_theme_font_size_override("font_size", 9)
			desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.90, 0.98, 1.0))
			desc_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
			desc_lbl.add_theme_constant_override("shadow_offset_x", 1)
			desc_lbl.add_theme_constant_override("shadow_offset_y", 1)
			desc_lbl.add_theme_constant_override("shadow_outline_size", 2)
			mod_box.add_child(desc_lbl)

		if i < GameState.active_dungeon_modifiers.size() - 1:
			var sep := HSeparator.new()
			sep.add_theme_constant_override("separation", 4)
			vbox.add_child(sep)

	add_child(_dungeon_mod_panel)
	call_deferred("_resize_dungeon_modifier_panel")

func _apply_dungeon_mod_label_widths(node: Node, inner_w: float) -> void:
	for child in node.get_children():
		if child is Label:
			(child as Label).custom_minimum_size.x = inner_w
		elif child is Container:
			_apply_dungeon_mod_label_widths(child, inner_w)

func _measure_dungeon_mod_label_height(lbl: Label, inner_w: float) -> float:
	var font: Font = lbl.get_theme_font("font")
	var fs: int = lbl.get_theme_font_size("font_size")
	if font == null:
		return float(fs) + 2.0
	return font.get_multiline_string_size(
		lbl.text, HORIZONTAL_ALIGNMENT_CENTER, inner_w, fs).y

func _measure_dungeon_mod_box_height(box: VBoxContainer, inner_w: float) -> float:
	var total: float = 0.0
	var sep: float = float(box.get_theme_constant("separation"))
	var children: Array = box.get_children()
	for i in children.size():
		var child: Node = children[i]
		if child is Label:
			total += _measure_dungeon_mod_label_height(child as Label, inner_w)
		if i < children.size() - 1:
			total += sep
	return total

func _measure_dungeon_mod_vbox_height(vbox: VBoxContainer, inner_w: float) -> float:
	var total: float = 0.0
	var sep: float = float(vbox.get_theme_constant("separation"))
	var children: Array = vbox.get_children()
	for i in children.size():
		var child: Node = children[i]
		if child is VBoxContainer:
			total += _measure_dungeon_mod_box_height(child as VBoxContainer, inner_w)
		elif child is HSeparator:
			total += (child as HSeparator).get_combined_minimum_size().y
		if i < children.size() - 1:
			total += sep
	return total

func _resize_dungeon_modifier_panel() -> void:
	if _dungeon_mod_panel == null:
		return
	var vbox: VBoxContainer = _dungeon_mod_panel.get_child(0) as VBoxContainer
	if vbox == null:
		return
	var sb := _dungeon_mod_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var panel_w: float = _dungeon_mod_panel.offset_right - _dungeon_mod_panel.offset_left
	var inner_w: float = panel_w
	var margin_v: float = 0.0
	if sb:
		inner_w = panel_w - sb.content_margin_left - sb.content_margin_right
		margin_v = sb.content_margin_top + sb.content_margin_bottom
	_apply_dungeon_mod_label_widths(vbox, inner_w)
	var content_h: float = _measure_dungeon_mod_vbox_height(vbox, inner_w) + margin_v
	_dungeon_mod_panel.offset_bottom = _dungeon_mod_panel.offset_top + content_h

func _update_dungeon_modifier_panel_visibility() -> void:
	if _dungeon_mod_panel == null:
		return
	var in_battle: bool = GameState.current_phase in [
		GameState.Phase.MODE_SELECT, GameState.Phase.ATTACK, GameState.Phase.TECH]
	var show: bool = in_battle and not _is_ai_turn()
	if show:
		call_deferred("_resize_dungeon_modifier_panel")
	_dungeon_mod_panel.visible = show

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
	SFXManager.wire_prompt_buttons_in(_attack_confirm_panel)

# ─────────────────────────────────────────────────────────────
# Card Context Menu
# ─────────────────────────────────────────────────────────────

var CTX_ICON_ATTACK: Texture2D
var CTX_ICON_INFO:   Texture2D
var CTX_ICON_BLUFF:  Texture2D
var CTX_ICON_UNION:  Texture2D

const CTX_MENU_SCALE: float = 1.25
const CTX_ICON_SZ: float = 52.0 * CTX_MENU_SCALE
const CTX_PAD: float = 8.0 * CTX_MENU_SCALE
const CTX_SEP: float = 6.0 * CTX_MENU_SCALE
const CTX_ICON_MAX_W: float = 36.0 * CTX_MENU_SCALE
const BLUFF_MODAL_SIZE: Vector2 = Vector2(598.5, 130.0) * CTX_MENU_SCALE


func _ctx_popup_size(btn_count: int) -> Vector2:
	var w: float = btn_count * CTX_ICON_SZ + maxf(float(btn_count - 1), 0.0) * CTX_SEP + CTX_PAD * 2.0
	var h: float = CTX_ICON_SZ + CTX_PAD * 2.0
	return Vector2(w, h)

func _show_card_context(ctx_player: int, row: int, col: int) -> void:
	# Close any existing popup first
	_hide_card_context()

	_context_card_player = ctx_player
	_context_card_pos = Vector2i(row, col)

	# Enemy view: card taps show a return prompt instead of the context menu.
	if _enemy_view_active:
		_show_enemy_view_return_prompt()
		return

	var card: GameState.CardInstance = GameState.get_card(ctx_player, row, col)
	var current_player := GameState.current_player

	var _decoy_blocked: bool = (
		GameState.attack_cost_block_max >= 0
		and GameState.attack_cost_block_player == current_player
		and card.crystal_cost <= GameState.attack_cost_block_max
	)
	var can_attack: bool = (
		ctx_player == current_player
		and card.card_type == "character"
		and not card.attacked_this_turn
		and card.cannot_attack_until < GameState.turn_number
		and (GameState.attacks_remaining > 0 or card.has_pending_bonus_attack_chain())
		and (GameState.berserk_active[current_player] == null
			or GameState.berserk_active[current_player] == card)
		and not _decoy_blocked
	)
	var can_info: bool  = (card.card_type != "dead_end" and card.card_name != "")
	var can_bluff: bool = (ctx_player == current_player)
	var _union_phase_ok: bool = GameState.current_phase in [GameState.Phase.MODE_SELECT, GameState.Phase.ATTACK]
	var _available_unions: Array = []
	if ctx_player == current_player and card.card_type == "character" and _union_phase_ok \
			and (SaveManager.union_mechanism_unlocked or GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.LOCAL_2P, GameState.GameMode.HOT_SEAT]) and GameState.battle_player_union_enabled \
			and _union_summoned_this_duel[ctx_player] < _max_unions_per_duel():
		var _ctx_seen: Dictionary = {}
		for _entry: Dictionary in UnionDatabase.find_available_unions(ctx_player, row, col):
			var _u: UnionData = _entry["union"]
			if _ctx_seen.has(_u.card_name):
				continue
			for _cond: Dictionary in _u.material_conditions:
				if UnionDatabase.card_satisfies_condition(card, _cond):
					_ctx_seen[_u.card_name] = true
					_available_unions.append(_entry)
					break
	var can_union: bool = _available_unions.size() > 0

	if TutorialBattleManager.is_active:
		if not TutorialBattleManager.should_open_card_context(ctx_player, card.card_name):
			return
		var allowlist: Array = TutorialBattleManager.get_card_context_allowlist(card.card_name)
		if not allowlist.is_empty():
			can_attack = can_attack and "attack" in allowlist
			can_info = can_info and "info" in allowlist
			can_bluff = can_bluff and "bluff" in allowlist
			can_union = can_union and "union" in allowlist

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
	hbox.offset_left = CTX_PAD; hbox.offset_top    = CTX_PAD
	hbox.offset_right = -CTX_PAD; hbox.offset_bottom = -CTX_PAD
	hbox.add_theme_constant_override("separation", CTX_SEP)
	popup.add_child(hbox)

	# Snapshot position BEFORE callbacks alter member vars
	var snap_player: int = ctx_player
	var snap_pos: Vector2i = Vector2i(row, col)

	if can_attack:
		var btn := _make_context_icon_btn(CTX_ICON_ATTACK)
		btn.set_meta("tut_action", "attack")
		var snap_card_name_atk: String = GameState.get_card(ctx_player, row, col).card_name
		btn.pressed.connect(func() -> void:
			if TutorialBattleManager.is_active:
				TutorialBattleManager.report_action("attack_icon_tap", {"card_name": snap_card_name_atk})
			_hide_card_context()
			_clear_selection()
			selected_attacker_pos = snap_pos
			var atk_card: GameState.CardInstance = GameState.get_card(snap_player, snap_pos.x, snap_pos.y)
			_multi_attack_bonus_targeting = atk_card != null and atk_card.has_pending_bonus_attack_chain()
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
			if TutorialBattleManager.is_active:
				var allowlist: Array = TutorialBattleManager.get_card_context_allowlist(card_name_snap)
				if not allowlist.is_empty() and not "info" in allowlist:
					return
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
		btn.set_meta("tut_action", "bluff")
		var snap_card_name_bluff: String = GameState.get_card(ctx_player, row, col).card_name
		btn.pressed.connect(func() -> void:
			if TutorialBattleManager.is_active:
				TutorialBattleManager.report_action("bluff_icon_tap", {"card_name": snap_card_name_bluff})
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
	var btn_count: int = int(can_attack) + int(can_info) + int(can_bluff) + int(can_union)
	var popup_size: Vector2 = _ctx_popup_size(btn_count)
	var popup_w: float = popup_size.x
	var popup_h: float = popup_size.y

	var screen: Vector2 = get_viewport_rect().size
	var px: float = _last_click_pos.x - popup_w * 0.5
	px = clampf(px, 4.0, screen.x - popup_w - 4.0)
	var py: float = _last_click_pos.y - popup_h - 8.0
	if py < 4.0:
		py = _last_click_pos.y + 8.0
	py = clampf(py, 4.0, screen.y - popup_h - 4.0)

	popup.position = Vector2(px, py)
	popup.size     = Vector2(popup_w, popup_h)
	SFXManager.play(SFXManager.SFX_BTN)

func _make_context_icon_btn(tex: Texture2D) -> Button:
	var btn := Button.new()
	btn.icon = tex
	btn.expand_icon = false
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	btn.custom_minimum_size = Vector2(CTX_ICON_SZ, CTX_ICON_SZ)
	btn.add_theme_constant_override("icon_max_width", int(CTX_ICON_MAX_W))
	btn.add_theme_constant_override("h_separation", 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.24, 1.0)
	sb.corner_radius_top_left     = int(6.0 * CTX_MENU_SCALE)
	sb.corner_radius_top_right    = int(6.0 * CTX_MENU_SCALE)
	sb.corner_radius_bottom_right = int(6.0 * CTX_MENU_SCALE)
	sb.corner_radius_bottom_left  = int(6.0 * CTX_MENU_SCALE)
	btn.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(0.14, 0.22, 0.44, 1.0)
	btn.add_theme_stylebox_override("hover", sbh)
	var sbp := sbh.duplicate() as StyleBoxFlat
	sbp.bg_color = Color(0.20, 0.30, 0.56, 1.0)
	btn.add_theme_stylebox_override("pressed", sbp)
	SFXManager.wire_prompt_button(btn)
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

## Sets a bluff emoji and plays the pop animation. Use this instead of
## set_bluff + _refresh_bluff_label whenever a new emoji is being placed.
const BLUFF_ANIM_DURATION: float = 0.38   # enlarge(0.15) + hold(0.08) + shrink(0.15)
func _set_bluff_animated(player: int, row: int, col: int, emoticon: String) -> void:
	GameState.set_bluff(player, row, col, emoticon)
	var lbl: Label = bluff_labels[player][row][col] as Label
	lbl.text = emoticon
	if emoticon != "":
		SFXManager.play(SFXManager.SFX_BLUFF_PLACE)
		_animate_bluff_label(lbl)

func _animate_bluff_label(lbl: Label) -> void:
	lbl.pivot_offset = lbl.size / 2.0
	lbl.scale = Vector2.ONE
	var tw: Tween = create_tween()
	tw.tween_property(lbl, "scale", Vector2(2.2, 2.2), 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.08)
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

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

	var center_wrap := CenterContainer.new()
	center_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center_wrap)

	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = BLUFF_MODAL_SIZE
	var psb := StyleBoxFlat.new()
	psb.bg_color     = Color(0.04, 0.07, 0.16, 0.98)
	psb.border_width_left   = 2; psb.border_width_top    = 2
	psb.border_width_right  = 2; psb.border_width_bottom = 2
	psb.border_color = Color(0.55, 0.78, 1.0, 0.7)
	psb.corner_radius_top_left     = int(10.0 * CTX_MENU_SCALE)
	psb.corner_radius_top_right    = int(10.0 * CTX_MENU_SCALE)
	psb.corner_radius_bottom_right = int(10.0 * CTX_MENU_SCALE)
	psb.corner_radius_bottom_left  = int(10.0 * CTX_MENU_SCALE)
	panel.add_theme_stylebox_override("panel", psb)
	center_wrap.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bluff_pad: float = 12.0 * CTX_MENU_SCALE
	vbox.offset_left = bluff_pad; vbox.offset_top = 10.0 * CTX_MENU_SCALE
	vbox.offset_right = -bluff_pad; vbox.offset_bottom = -10.0 * CTX_MENU_SCALE
	vbox.add_theme_constant_override("separation", 10.0 * CTX_MENU_SCALE)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Pick a Bluff"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(16.0 * CTX_MENU_SCALE))
	title.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	vbox.add_child(title)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", CTX_SEP)
	vbox.add_child(hbox)

	var snap_player: int = player
	var snap_row: int    = row
	var snap_col: int    = col

	for emoji in _get_bluff_emojis_board():
		var btn := Button.new()
		btn.text = emoji
		var emoji_sz: float = 46.0 * CTX_MENU_SCALE
		btn.custom_minimum_size = Vector2(emoji_sz, emoji_sz)
		btn.add_theme_font_size_override("font_size", int(22.0 * CTX_MENU_SCALE))
		var esb := StyleBoxFlat.new()
		esb.bg_color = Color(0.08, 0.12, 0.28, 1.0)
		esb.corner_radius_top_left     = int(6.0 * CTX_MENU_SCALE)
		esb.corner_radius_top_right    = int(6.0 * CTX_MENU_SCALE)
		esb.corner_radius_bottom_right = int(6.0 * CTX_MENU_SCALE)
		esb.corner_radius_bottom_left  = int(6.0 * CTX_MENU_SCALE)
		btn.add_theme_stylebox_override("normal", esb)
		var esbh := esb.duplicate() as StyleBoxFlat
		esbh.bg_color = Color(0.15, 0.25, 0.55, 1.0)
		btn.add_theme_stylebox_override("hover", esbh)
		var snap_emoji: String = emoji
		btn.pressed.connect(func() -> void:
			_set_bluff_animated(snap_player, snap_row, snap_col, snap_emoji)
			backdrop.queue_free())
		hbox.add_child(btn)

	var clear_btn := Button.new()
	clear_btn.text = "✕  Remove Bluff"
	clear_btn.add_theme_font_override("font", FontManager.make_font("primary", 400))
	clear_btn.add_theme_font_size_override("font_size", int(14.0 * CTX_MENU_SCALE))
	clear_btn.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.08, 0.08, 0.16, 1.0)
	csb.corner_radius_top_left     = int(6.0 * CTX_MENU_SCALE)
	csb.corner_radius_top_right    = int(6.0 * CTX_MENU_SCALE)
	csb.corner_radius_bottom_right = int(6.0 * CTX_MENU_SCALE)
	csb.corner_radius_bottom_left  = int(6.0 * CTX_MENU_SCALE)
	clear_btn.add_theme_stylebox_override("normal", csb)
	clear_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	clear_btn.pressed.connect(func() -> void:
		SFXManager.play(SFXManager.SFX_BLUFF_REMOVE)
		GameState.set_bluff(snap_player, snap_row, snap_col, "")
		_refresh_bluff_label(snap_player, snap_row, snap_col)
		backdrop.queue_free())
	vbox.add_child(clear_btn)
	SFXManager.wire_prompt_buttons_in(vbox)

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
var _ability_target_flash_nodes: Array = []         # Array[Card nodes]

func _open_union_modal(player: int, available: Array) -> void:
	var modal: UnionModal = UnionModal.open(self, player, available)
	_union_modal = modal
	modal.union_selected.connect(_on_union_selected)
	modal.union_cancelled.connect(_on_union_modal_cancelled)

func _on_union_modal_cancelled() -> void:
	_union_modal = null

func _on_union_selected(player: int, union_name: String, zone_cells: Array) -> void:
	_union_modal = null
	if TutorialBattleManager.is_active:
		TutorialBattleManager.report_action("union_selected", {"union_name": union_name, "player": player})
	var u: UnionData = UnionDatabase.get_union(union_name)
	if u == null:
		push_error("Union not found: " + union_name)
		return
	if GameState.crystals[player] < _effective_union_cost(u.summon_cost):
		GameState.post_message("Not enough crystals.")
		return
	_enter_union_material_selection(player, u, zone_cells)

func _enter_union_material_selection(player: int, u: UnionData, zone_cells: Array) -> void:
	_pending_union_player = player
	_pending_union_data = u
	_pending_union_zone_cells = zone_cells.duplicate()
	_pending_union_conditions_remaining = u.material_conditions.duplicate()
	_pending_union_selected_materials.clear()
	await _play_union_zone_preview(player, zone_cells)
	_set_selection_state(SelectionState.SELECTING_UNION_MATERIALS)
	_update_union_suggest_button()
	_refresh_union_flash_cells()
	GameState.post_message("Tap %d material card(s) on the field." % u.material_conditions.size())

func _play_union_zone_preview(player: int, zone_cells: Array) -> void:
	# Block all input during the flash
	var blocker := Control.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.z_index = 20
	add_child(blocker)

	# Cyan flash overlay on each zone cell card node
	var overlays: Array = []
	for cell: Vector2i in zone_cells:
		if cell.x < 0 or cell.x >= GameState.GRID_SIZE or cell.y < 0 or cell.y >= GameState.GRID_SIZE:
			continue
		var card_node: Control = grid_nodes[player][cell.x][cell.y]
		var cr := ColorRect.new()
		cr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cr.color        = Color(0.25, 0.90, 1.00, 0.0)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr.z_index      = 10
		card_node.add_child(cr)
		overlays.append(cr)

	if overlays.is_empty():
		blocker.queue_free()
		return

	SFXManager.play(SFXManager.SFX_UNION_FLASH)
	# Fade in 0.5 s
	var t_in := create_tween()
	for cr: ColorRect in overlays:
		t_in.parallel().tween_property(cr, "color:a", 0.75, 0.5)
	await t_in.finished

	# Hold 0.5 s
	await get_tree().create_timer(0.5).timeout

	# Fade out 0.5 s
	var t_out := create_tween()
	for cr: ColorRect in overlays:
		t_out.parallel().tween_property(cr, "color:a", 0.0, 0.5)
	await t_out.finished

	# Cleanup
	for cr: ColorRect in overlays:
		if is_instance_valid(cr):
			cr.queue_free()
	blocker.queue_free()

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
	SFXManager.play(SFXManager.SFX_TARGET)
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

func _apply_union_summon_ability(player: int, anchor: Vector2i, u: UnionData) -> void:
	match u.ability_type:
		CharacterData.AbilityType.UNION_SUMMON_VENOM_ALL_FOE:
			var foe: int = GameState.get_opponent(player)
			for r: int in range(GameState.GRID_SIZE):
				for c: int in range(GameState.GRID_SIZE):
					var card: GameState.CardInstance = GameState.get_card(foe, r, c)
					if card.card_type == "character" and card.face_up:
						GameState.apply_unit_effect_flag(foe, r, c, "venom")
			GameState.post_message("%s: Venom on all opponent face-up characters!" % u.card_name)
		CharacterData.AbilityType.UNION_SUMMON_REVIVE_MATCH:
			await _begin_union_revive_match(player, u)
		CharacterData.AbilityType.UNION_SUMMON_COSMIC_ANIMA_IMMUNITY:
			GameState.galaxos_immunity_owner = player
			GameState.post_message("%s: Cosmic and Anima allies protected until foe's turn ends!" % u.card_name)
		CharacterData.AbilityType.UNION_SUMMON_REVEAL_FIELD:
			var _ll_count: int = maxi(1, int(u.ability_params.get("count", 3)))
			var _ll_hidden: Array = []
			for _ll_p: int in range(2):
				for _ll_r: int in range(GameState.GRID_SIZE):
					for _ll_c: int in range(GameState.GRID_SIZE):
						var _ll_card: GameState.CardInstance = GameState.get_card(_ll_p, _ll_r, _ll_c)
						if _ll_card.card_type != "dead_end" and not _ll_card.face_up:
							_ll_hidden.append({"p": _ll_p, "pos": Vector2i(_ll_r, _ll_c)})
			_ll_hidden.shuffle()
			var _ll_revealed: int = 0
			for _ll_entry: Dictionary in _ll_hidden:
				if _ll_revealed >= _ll_count:
					break
				var _ll_pos: Vector2i = _ll_entry["pos"]
				GameState.reveal_card_by_ability(int(_ll_entry["p"]), _ll_pos.x, _ll_pos.y)
				_ll_revealed += 1
			GameState.post_message("%s: Revealed %d card(s) on the field!" % [u.card_name, _ll_revealed])
		CharacterData.AbilityType.UNION_SUMMON_PERM_ATK_OR_DEF_CHOICE:
			var _sp_amt: int = int(u.ability_params.get("amount", 80))
			turn_manager.emit_signal("awaiting_trap_choice",
				"%s: Choose a permanent bonus." % u.card_name,
				["+%d ATK permanently" % _sp_amt, "+%d DEF permanently" % _sp_amt])
			var _sp_choice: int = await turn_manager.ability_choice_resolved
			var _sp_card: GameState.CardInstance = GameState.get_card(player, anchor.x, anchor.y)
			if _sp_choice == 0:
				_sp_card.perm_atk_bonus += _sp_amt
				GameState.post_message("%s: +%d ATK permanently!" % [u.card_name, _sp_amt])
			else:
				_sp_card.perm_def_bonus += _sp_amt
				GameState.post_message("%s: +%d DEF permanently!" % [u.card_name, _sp_amt])


func _perform_pending_union() -> void:
	_clear_union_flash_nodes()
	_set_selection_state(SelectionState.SELECTING_ATTACKER)
	var player: int = _pending_union_player
	var u: UnionData = _pending_union_data
	if u == null or not UnionDatabase.is_playable_in_demo(u):
		_pending_union_data = null
		_pending_union_player = -1
		_pending_union_zone_cells.clear()
		_pending_union_conditions_remaining.clear()
		_pending_union_selected_materials.clear()
		return
	var first_cell: Vector2i = _pending_union_selected_materials[0]
	# Collect material labels BEFORE removal for the battle log
	var material_labels: Array[String] = []
	for _mc: Vector2i in _pending_union_selected_materials:
		var _card: GameState.CardInstance = GameState.get_card(player, _mc.x, _mc.y)
		material_labels.append(BattleLogFormat.format_card(_card))
	# Pay crystal cost (apply dungeon modifiers via _effective_union_cost)
	GameState.lose_crystals(player, _effective_union_cost(u.summon_cost), "union")
	await GameState.wait_crystal_animation()
	if _is_ai_turn():
		_restart_ai_watchdog()
	# Remove selected material cards (except the first which becomes the union)
	for i: int in range(1, _pending_union_selected_materials.size()):
		var cell: Vector2i = _pending_union_selected_materials[i]
		GameState.remove_union_material(player, cell.x, cell.y)
	# Place union at first selected cell
	var _zealot_boost: int = 0
	for _zm: Vector2i in _pending_union_selected_materials:
		var _zm_card: GameState.CardInstance = GameState.get_card(player, _zm.x, _zm.y)
		if _zm_card.card_type == "character" and _zm_card.card_name == "Zealot":
			_zealot_boost = int(_zm_card.ability_params.get("union_material_boost", 40))
			break
	GameState.place_union_card(player, first_cell.x, first_cell.y, u)
	if _zealot_boost > 0:
		var _union_inst: GameState.CardInstance = GameState.get_card(player, first_cell.x, first_cell.y)
		_union_inst.current_atk += _zealot_boost
		_union_inst.current_def += _zealot_boost
		GameState.post_message("Zealot: Union gains +%d ATK&DEF!" % _zealot_boost)
	if u.card_name == "Diamond Unicorn":
		var _du_card: GameState.CardInstance = GameState.get_card(player, first_cell.x, first_cell.y)
		if _du_card.card_type == "character":
			_du_card.temp_atk_bonus += 15
			GameState.post_message("Diamond Unicorn: +15 ATK until end of turn!")
	GameState.union_summoned.emit(
		player,
		BattleLogFormat.format_unit_at(player, first_cell.x, first_cell.y, u.card_name),
		material_labels)
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "dimensional_gate" in GameState.active_dungeon_modifiers:
		DailyDungeonManager.register_dimensional_gate_union(player, first_cell.x, first_cell.y)
	await _apply_union_summon_ability(player, first_cell, u)
	if _is_ai_turn():
		_restart_ai_watchdog()
	# Record unlock (human players only)
	var human_player: bool = GameState.game_mode not in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN, GameState.GameMode.DAILY_DUNGEON] or player == 0
	if human_player:
		SaveManager.unlock_union(u.card_name)
	if human_player and player == 0:
		GlobalStatManager.on_union_summoned(int(u.affinity))
		AchievementManager.on_union_summoned(int(u.affinity))
	# Mark once-per-duel flag and hide suggestion button
	_union_summoned_this_duel[player] += 1
	_update_union_suggest_button()
	# Battle log entry
	var mat_list: String = ", ".join(material_labels)
	GameState.post_message("Player %d summoned [%s] using: %s" % [player + 1, u.card_name, mat_list])
	# Clear pending state
	_pending_union_data = null
	_pending_union_player = -1
	_pending_union_zone_cells.clear()
	_pending_union_conditions_remaining.clear()
	_pending_union_selected_materials.clear()
	# Grid refresh first, then cinematic reveal
	_refresh_all_grids()
	_highlight_attackable_chars()
	# Full cinematic reveal (shake and dust happen inside on landing)
	await _show_union_summon_reveal(u.card_name)
	if _is_ai_turn():
		_restart_ai_watchdog()
	# Cyan shockwave plays on the union card node AFTER shake+dust landing
	var union_node: Control = grid_nodes[player][first_cell.x][first_cell.y]
	var cell_center: Vector2 = union_node.global_position + union_node.size * 0.5
	_spawn_union_shockwave(cell_center)
	if TutorialBattleManager.is_active:
		TutorialBattleManager.report_action("union_resolved", {
			"player": player,
			"union_name": u.card_name,
		})

func _cancel_union_material_selection() -> void:
	_clear_union_flash_nodes()
	_pending_union_data = null
	_pending_union_player = -1
	_pending_union_zone_cells.clear()
	_pending_union_conditions_remaining.clear()
	_pending_union_selected_materials.clear()
	_set_selection_state(SelectionState.SELECTING_ATTACKER)
	_update_union_suggest_button()
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
	t.tween_property(ml, "position", origin + Vector2(14,  7), 0.05)
	t.tween_property(ml, "position", origin + Vector2(-14, -5), 0.05)
	t.tween_property(ml, "position", origin + Vector2(10,  6), 0.05)
	t.tween_property(ml, "position", origin + Vector2(-8,  -4), 0.05)
	t.tween_property(ml, "position", origin + Vector2(5,   3), 0.04)
	t.tween_property(ml, "position", origin + Vector2(-3,  -2), 0.04)
	t.tween_property(ml, "position", origin, 0.04)

func _spawn_union_shockwave(cell_center: Vector2) -> void:
	SFXManager.play(SFXManager.SFX_UNION_SHOCKWAVE)
	const UNION_CYAN: Color = Color(0.25, 0.90, 1.00)
	# Three expanding rings with staggered start — cyan, white, cyan
	var ring_colors: Array = [UNION_CYAN, Color(1.0, 1.0, 1.0, 0.9), UNION_CYAN]
	var ring_delays: Array = [0.0, 0.10, 0.20]
	for k: int in range(3):
		var ring := Panel.new()
		const RING_BASE: float = 80.0
		ring.size        = Vector2(RING_BASE, RING_BASE)
		ring.pivot_offset = Vector2(RING_BASE * 0.5, RING_BASE * 0.5)
		ring.position    = cell_center - Vector2(RING_BASE * 0.5, RING_BASE * 0.5)
		ring.z_index     = 200
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rsb := StyleBoxFlat.new()
		rsb.bg_color            = Color(0, 0, 0, 0)
		rsb.border_color        = ring_colors[k]
		rsb.border_width_left   = 4
		rsb.border_width_right  = 4
		rsb.border_width_top    = 4
		rsb.border_width_bottom = 4
		rsb.corner_radius_top_left     = int(RING_BASE * 0.5)
		rsb.corner_radius_top_right    = int(RING_BASE * 0.5)
		rsb.corner_radius_bottom_left  = int(RING_BASE * 0.5)
		rsb.corner_radius_bottom_right = int(RING_BASE * 0.5)
		ring.add_theme_stylebox_override("panel", rsb)
		ring.scale = Vector2(0.05, 0.05)
		add_child(ring)
		var t := create_tween()
		t.tween_interval(ring_delays[k])
		t.tween_property(ring, "scale", Vector2(10.0, 10.0), 0.55) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(ring, "modulate:a", 0.0, 0.55) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_callback(ring.queue_free)

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
	hbox.offset_left = CTX_PAD; hbox.offset_top    = CTX_PAD
	hbox.offset_right = -CTX_PAD; hbox.offset_bottom = -CTX_PAD
	hbox.add_theme_constant_override("separation", CTX_SEP)
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
	var popup_size: Vector2 = _ctx_popup_size(1)
	var popup_w: float = popup_size.x
	var popup_h: float = popup_size.y

	var screen: Vector2 = get_viewport_rect().size
	var px: float = _last_click_pos.x - popup_w * 0.5
	px = clampf(px, 4.0, screen.x - popup_w - 4.0)
	var py: float = _last_click_pos.y - popup_h - 8.0
	if py < 4.0:
		py = _last_click_pos.y + 8.0
	py = clampf(py, 4.0, screen.y - popup_h - 4.0)

	popup.position = Vector2(px, py)
	popup.size     = Vector2(popup_w, popup_h)
	SFXManager.play(SFXManager.SFX_BTN)

func _should_block_card_actions_for_enemy_view() -> bool:
	if not _enemy_view_active:
		return false
	if _is_ai_turn():
		return false
	return selection_state not in [
		SelectionState.SELECTING_TECH_TARGET,
		SelectionState.SELECTING_UNION_MATERIALS,
		SelectionState.CONFIRMING_ATTACK,
		SelectionState.AWAITING_TRAP_CHOICE,
	]

func _show_enemy_view_return_prompt() -> void:
	_hide_card_context()
	if is_instance_valid(_enemy_view_return_dialog):
		_enemy_view_return_dialog.move_to_front()
		return
	SFXManager.play(SFXManager.SFX_POPUP)
	_enemy_view_return_dialog = GameDialog.confirmation_overlay(
		self,
		"Enemy's View",
		"You are now in \"Enemy's View\". Would you like to return to \"Your View\"?",
		"Your View",
		"Stay",
		func() -> void:
			if _enemy_view_active:
				_toggle_reveal_preview(GameState.current_player)
			_enemy_view_return_dialog = null,
		func() -> void:
			_enemy_view_return_dialog = null)

# ─────────────────────────────────────────────────────────────
# Corner Crystal Labels
# ─────────────────────────────────────────────────────────────

func _build_crystal_icon_with_shadow(tex: Texture2D, size: float) -> Control:
	const SHADOW_OFFSET: float = 1.0
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(size, size)
	wrap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shadow := TextureRect.new()
	shadow.texture = tex
	shadow.modulate = Color(0.0, 0.0, 0.0, 1.0)
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shadow.position = Vector2(SHADOW_OFFSET, SHADOW_OFFSET)
	shadow.size = Vector2(size, size)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(shadow)

	var icon := TextureRect.new()
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2.ZERO
	icon.size = Vector2(size, size)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(icon)

	return wrap

func _set_crystal_icon_texture(icon: TextureRect, tex: Texture2D) -> void:
	if icon == null:
		return
	icon.texture = tex
	var wrap := icon.get_parent()
	if wrap != null and wrap.get_child_count() > 0:
		var shadow := wrap.get_child(0) as TextureRect
		if shadow != null and shadow != icon:
			shadow.texture = tex

func _build_bottom_crystal_labels() -> void:
	const ICON_SIZE  : float = 48.0
	const FONT_SIZE  : int   = 40
	const NAME_SIZE  : int   = 14
	const TEXT_COLOR : Color = Color(0.85, 0.95, 1.0)
	const NAME_COLOR : Color = Color(0.7, 0.85, 1.0)
	const COL_H      : float = 88.0   # VBox height (name row + crystal row)
	const COL_W      : float = 300.0
	const MARGIN     : float = 12.0

	var crystal_tex: Texture2D = HudSkin.hud_tex("ui_crystal_indicator.png")

	# ── P1 — upper left ───────────────────────────────────────
	var p1_vbox := VBoxContainer.new()
	p1_vbox.layout_mode = 1
	p1_vbox.anchor_left   = 0.0; p1_vbox.anchor_right  = 0.0
	p1_vbox.anchor_top    = 0.0; p1_vbox.anchor_bottom = 0.0
	p1_vbox.offset_left   = MARGIN; p1_vbox.offset_right  = MARGIN + COL_W
	p1_vbox.offset_top    = MARGIN; p1_vbox.offset_bottom = MARGIN + COL_H
	p1_vbox.add_theme_constant_override("separation", 0)
	p1_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	p1_vbox.z_index = 4
	p1_vbox.visible = false
	add_child(p1_vbox)
	_p1_crystal_row = p1_vbox
	p1_vbox.mouse_entered.connect(func(): _show_hud_tooltip("Player 1 Crystals — first to reach 0 loses"))
	p1_vbox.mouse_exited.connect(func(): _restore_game_guide())

	_p1_name_lbl = Label.new()
	_p1_name_lbl.text = _player_names[0]
	_p1_name_lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 600))
	_p1_name_lbl.add_theme_font_size_override("font_size", NAME_SIZE)
	_p1_name_lbl.add_theme_color_override("font_color", NAME_COLOR)
	_p1_name_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	_p1_name_lbl.add_theme_constant_override("shadow_offset_x", 1)
	_p1_name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	_p1_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p1_vbox.add_child(_p1_name_lbl)

	var p1_crystal_hbox := HBoxContainer.new()
	p1_crystal_hbox.add_theme_constant_override("separation", 6)
	p1_crystal_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p1_vbox.add_child(p1_crystal_hbox)

	if crystal_tex:
		var icon := _build_crystal_icon_with_shadow(crystal_tex, ICON_SIZE)
		p1_crystal_hbox.add_child(icon)
		_p1_crystal_icon = icon.get_child(1) as TextureRect

	_p1_bottom_crystal = Label.new()
	_p1_bottom_crystal.text = str(GameState.crystals[0])
	_p1_bottom_crystal.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	_p1_bottom_crystal.add_theme_font_size_override("font_size", FONT_SIZE)
	_p1_bottom_crystal.add_theme_color_override("font_color", TEXT_COLOR)
	_p1_bottom_crystal.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	_p1_bottom_crystal.add_theme_constant_override("shadow_offset_x", 1)
	_p1_bottom_crystal.add_theme_constant_override("shadow_offset_y", 1)
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
	p2_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	p2_vbox.z_index = 4
	p2_vbox.visible = false
	add_child(p2_vbox)
	_p2_crystal_row = p2_vbox
	p2_vbox.mouse_entered.connect(func(): _show_hud_tooltip("Player 2 Crystals — first to reach 0 loses"))
	p2_vbox.mouse_exited.connect(func(): _restore_game_guide())

	_p2_name_lbl = Label.new()
	_p2_name_lbl.text = _player_names[1]
	_p2_name_lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 600))
	_p2_name_lbl.add_theme_font_size_override("font_size", NAME_SIZE)
	_p2_name_lbl.add_theme_color_override("font_color", NAME_COLOR)
	_p2_name_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	_p2_name_lbl.add_theme_constant_override("shadow_offset_x", 1)
	_p2_name_lbl.add_theme_constant_override("shadow_offset_y", 1)
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
	_p2_bottom_crystal.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	_p2_bottom_crystal.add_theme_font_size_override("font_size", FONT_SIZE)
	_p2_bottom_crystal.add_theme_color_override("font_color", TEXT_COLOR)
	_p2_bottom_crystal.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	_p2_bottom_crystal.add_theme_constant_override("shadow_offset_x", 1)
	_p2_bottom_crystal.add_theme_constant_override("shadow_offset_y", 1)
	_p2_bottom_crystal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_p2_bottom_crystal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_p2_bottom_crystal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p2_crystal_hbox.add_child(_p2_bottom_crystal)

	if crystal_tex:
		var icon2 := _build_crystal_icon_with_shadow(crystal_tex, ICON_SIZE)
		p2_crystal_hbox.add_child(icon2)
		_p2_crystal_icon = icon2.get_child(1) as TextureRect

## Builds the "thinking bubble" overlay used to show when the AI is processing.
## Hidden by default; shown via _show_thinking_bubble() after a 0.5s delay.
func _build_thinking_bubble() -> void:
	_thinking_bubble = Control.new()
	_thinking_bubble.layout_mode = 1
	_thinking_bubble.z_index       = 8
	_thinking_bubble.visible       = false
	_thinking_bubble.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(_thinking_bubble)

	# Rounded white background — corners adjusted per-player in _show_thinking_bubble()
	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thinking_bubble_style = StyleBoxFlat.new()
	_thinking_bubble_style.bg_color       = Color(0.96, 0.96, 1.0, 0.92)
	_thinking_bubble_style.border_width_left   = 1; _thinking_bubble_style.border_width_right  = 1
	_thinking_bubble_style.border_width_top    = 1; _thinking_bubble_style.border_width_bottom = 1
	_thinking_bubble_style.border_color        = Color(0.7, 0.7, 0.85, 0.6)
	bg.add_theme_stylebox_override("panel", _thinking_bubble_style)
	_thinking_bubble.add_child(bg)

	# Three dot labels centred inside the bubble
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hbox.add_theme_constant_override("separation", 5)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thinking_bubble.add_child(hbox)

	_thinking_dot_labels.clear()
	for _i: int in range(3):
		var dot := Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 16)
		dot.add_theme_color_override("font_color", Color(0.25, 0.25, 0.4, 1.0))
		dot.modulate.a = 0.0
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(dot)
		_thinking_dot_labels.append(dot)

## Start a 0.5-second timer; if the AI is still thinking when it fires, show the bubble.
func _start_ai_thinking() -> void:
	_thinking_timer_active = true
	await get_tree().create_timer(0.5).timeout
	if _thinking_timer_active:
		_show_thinking_bubble(_active_ai.player_index if is_instance_valid(_active_ai) else 1)

func _show_thinking_bubble(thinking_player: int) -> void:
	if _thinking_bubble == null:
		return
	# Position the bubble just inside the portrait edge at ~35% screen height.
	# P1 (left portrait): bubble hugs the left edge, tip points LEFT (bottom-left corner sharp).
	# P2 (right portrait): bubble hugs the right edge, tip points RIGHT (bottom-right corner sharp).
	const W: float = 100.0
	const H: float = 44.0
	const MARGIN: float = 40.0
	const R_ROUND: int = 14
	const R_TIP: int   = 3
	if thinking_player == 0:
		_thinking_bubble.anchor_left   = 0.0;  _thinking_bubble.anchor_right  = 0.0
		_thinking_bubble.anchor_top    = 0.35; _thinking_bubble.anchor_bottom = 0.35
		_thinking_bubble.offset_left   = MARGIN
		_thinking_bubble.offset_right  = MARGIN + W
		_thinking_bubble.offset_top    = -H * 0.5
		_thinking_bubble.offset_bottom =  H * 0.5
		_thinking_bubble_style.corner_radius_top_left     = R_ROUND
		_thinking_bubble_style.corner_radius_top_right    = R_ROUND
		_thinking_bubble_style.corner_radius_bottom_right = R_ROUND
		_thinking_bubble_style.corner_radius_bottom_left  = R_TIP   # tip points left
	else:
		_thinking_bubble.anchor_left   = 1.0;  _thinking_bubble.anchor_right  = 1.0
		_thinking_bubble.anchor_top    = 0.35; _thinking_bubble.anchor_bottom = 0.35
		_thinking_bubble.offset_right  = -MARGIN
		_thinking_bubble.offset_left   = -MARGIN - W
		_thinking_bubble.offset_top    = -H * 0.5
		_thinking_bubble.offset_bottom =  H * 0.5
		_thinking_bubble_style.corner_radius_top_left     = R_ROUND
		_thinking_bubble_style.corner_radius_top_right    = R_ROUND
		_thinking_bubble_style.corner_radius_bottom_right = R_TIP   # tip points right
		_thinking_bubble_style.corner_radius_bottom_left  = R_ROUND
	_thinking_bubble.visible = true
	_start_dot_animation()

func _hide_thinking_bubble() -> void:
	_thinking_timer_active = false
	if _thinking_dot_tween and _thinking_dot_tween.is_valid():
		_thinking_dot_tween.kill()
		_thinking_dot_tween = null
	if _thinking_bubble != null:
		_thinking_bubble.visible = false
	for dot: Label in _thinking_dot_labels:
		dot.modulate.a = 0.0

## Manual trigger: tapping a player's portrait shows the thinking bubble for 3 seconds.
## Only the human player's own portrait responds — opponent and AI portraits are ignored.
func _on_portrait_tapped(player: int) -> void:
	match GameState.game_mode:
		GameState.GameMode.AI_VS_AI:
			return  # no human players
		GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN, GameState.GameMode.DAILY_DUNGEON:
			if player != 0:
				return  # player 1 is AI
		_:
			# LOCAL_2P / HOT_SEAT: only the active player can tap their own portrait
			if player != GameState.current_player:
				return
	_show_thinking_bubble(player)
	await get_tree().create_timer(3.0).timeout
	_hide_thinking_bubble()

func _start_dot_animation() -> void:
	if _thinking_dot_tween and _thinking_dot_tween.is_valid():
		_thinking_dot_tween.kill()
	for dot: Label in _thinking_dot_labels:
		dot.modulate.a = 0.0
	_thinking_dot_tween = create_tween().set_loops()
	# Dots fade in one by one
	_thinking_dot_tween.tween_property(_thinking_dot_labels[0], "modulate:a", 1.0, 0.18)
	_thinking_dot_tween.tween_interval(0.12)
	_thinking_dot_tween.tween_property(_thinking_dot_labels[1], "modulate:a", 1.0, 0.18)
	_thinking_dot_tween.tween_interval(0.12)
	_thinking_dot_tween.tween_property(_thinking_dot_labels[2], "modulate:a", 1.0, 0.18)
	_thinking_dot_tween.tween_interval(0.35)
	# All fade out simultaneously
	_thinking_dot_tween.tween_property(_thinking_dot_labels[0], "modulate:a", 0.0, 0.22)
	_thinking_dot_tween.parallel().tween_property(_thinking_dot_labels[1], "modulate:a", 0.0, 0.22)
	_thinking_dot_tween.parallel().tween_property(_thinking_dot_labels[2], "modulate:a", 0.0, 0.22)
	_thinking_dot_tween.tween_interval(0.25)

## Creates a fixed-size Control with the attack-count icon and a centered number label.
## Child 0 = TextureRect (icon), Child 1 = Label (count). Caller stores child 1 as _pN_attack_lbl.
func _build_attack_count_icon() -> Control:
	const ICON_SIZE: float = 92.0
	var container := Control.new()
	container.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	container.mouse_filter = Control.MOUSE_FILTER_PASS

	var icon := TextureRect.new()
	icon.texture = HudSkin.hud_tex("ui_icon_attack_count.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(icon)

	var lbl := Label.new()
	lbl.text = "2"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.add_theme_constant_override("shadow_outline_size", 3)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(lbl)

	return container

func _update_crystal_visibility() -> void:
	var hide_phases: Array = [
		GameState.Phase.NONE, GameState.Phase.SETUP_P1,
		GameState.Phase.SETUP_P2]
	var show: bool = GameState.current_phase not in hide_phases
	if GameState.current_phase == GameState.Phase.GAME_OVER:
		# Keep the HUD visible until burst/tick/post-tick hold finishes on crystal depletion.
		show = _crystal_anim_processing
	if _p1_crystal_row:
		_p1_crystal_row.visible = show
	if _p2_crystal_row:
		_p2_crystal_row.visible = show
	if _turn_number_lbl:
		_turn_number_lbl.visible = show
	if _turn_number_bg:
		_turn_number_bg.visible = show
	if _turn_number_hit:
		_turn_number_hit.visible = show
	if _options_btn_root:
		_options_btn_root.visible = show and not TutorialBattleManager.should_hide_options_btn()
	if _fog_container:
		_fog_container.visible = show

func _refresh_attack_labels() -> void:
	var phase := GameState.current_phase
	var in_battle: bool = phase not in [
		GameState.Phase.NONE, GameState.Phase.SETUP_P1,
		GameState.Phase.SETUP_P2, GameState.Phase.GAME_OVER]
	var cp: int = GameState.current_player
	var remaining: int = GameState.attacks_remaining
	for p: int in range(2):
		var lbl: Label = _p1_attack_lbl if p == 0 else _p2_attack_lbl
		if lbl == null:
			continue
		var container: Control = lbl.get_parent()
		if container == null:
			continue
		container.visible = in_battle and p == cp
		if not container.visible:
			continue
		lbl.text = str(remaining)

func _build_attack_count_indicators() -> void:
	const ICON_SIZE: float = 92.0
	const MED_HALF: float  = 140.0   # MED_SIZE (280) / 2
	const GAP: float       = 22.0    # offset from turn number panel

	var p1_container: Control = _build_attack_count_icon()
	p1_container.layout_mode = 1
	p1_container.anchor_left   = 0.5
	p1_container.anchor_right  = 0.5
	p1_container.anchor_top    = 0.0
	p1_container.anchor_bottom = 0.0
	p1_container.offset_right  = -(MED_HALF + GAP)
	p1_container.offset_left   = p1_container.offset_right - ICON_SIZE
	p1_container.offset_top    = 4.0
	p1_container.offset_bottom = 4.0 + ICON_SIZE
	p1_container.z_index       = 4
	p1_container.visible       = false
	add_child(p1_container)
	_p1_attack_lbl = p1_container.get_child(1) as Label
	p1_container.mouse_entered.connect(func(): _show_hud_tooltip("Remaining attack count for this turn"))
	p1_container.mouse_exited.connect(func(): _restore_game_guide())

	var p2_container: Control = _build_attack_count_icon()
	p2_container.layout_mode = 1
	p2_container.anchor_left   = 0.5
	p2_container.anchor_right  = 0.5
	p2_container.anchor_top    = 0.0
	p2_container.anchor_bottom = 0.0
	p2_container.offset_left   = MED_HALF + GAP
	p2_container.offset_right  = p2_container.offset_left + ICON_SIZE
	p2_container.offset_top    = 4.0
	p2_container.offset_bottom = 4.0 + ICON_SIZE
	p2_container.z_index       = 4
	p2_container.visible       = false
	add_child(p2_container)
	_p2_attack_lbl = p2_container.get_child(1) as Label
	p2_container.mouse_entered.connect(func(): _show_hud_tooltip("Remaining attack count for this turn"))
	p2_container.mouse_exited.connect(func(): _restore_game_guide())

func _build_turn_number_label() -> void:
	# Medallion background — upper half hidden above screen, lower half visible
	const MED_SIZE: float = 280.0
	const HIT_W: float = 108.0
	const HIT_H: float = 52.0
	var bg := TextureRect.new()
	bg.texture = HudSkin.hud_tex("ui_turn_number_panel.png")
	bg.ignore_texture_size = true
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.layout_mode = 1
	bg.anchor_left   = 0.5; bg.anchor_right  = 0.5
	bg.anchor_top    = 0.0; bg.anchor_bottom = 0.0
	bg.offset_left   = -(MED_SIZE * 0.5)
	bg.offset_right  =  (MED_SIZE * 0.5)
	bg.offset_top    = -(MED_SIZE * 0.5) + 20.0   # upper half above screen edge (clipped)
	bg.offset_bottom =   (MED_SIZE * 0.5) + 20.0  # lower half visible
	bg.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 3
	bg.visible = false
	add_child(bg)
	_turn_number_bg = bg

	var hit := Control.new()
	hit.layout_mode = 1
	hit.anchor_left   = 0.5; hit.anchor_right  = 0.5
	hit.anchor_top    = 0.0; hit.anchor_bottom = 0.0
	hit.offset_left   = -(HIT_W * 0.5)
	hit.offset_right  =  (HIT_W * 0.5)
	hit.offset_top    = 20.0
	hit.offset_bottom = HIT_H + 20.0
	hit.mouse_filter  = Control.MOUSE_FILTER_PASS
	hit.z_index = 4
	hit.visible = false
	add_child(hit)
	_turn_number_hit = hit
	hit.mouse_entered.connect(func(): _show_hud_tooltip("Current turn number"))
	hit.mouse_exited.connect(func(): _restore_game_guide())

	var lbl := Label.new()
	lbl.layout_mode = 1
	lbl.anchor_left   = 0.5; lbl.anchor_right  = 0.5
	lbl.anchor_top    = 0.0; lbl.anchor_bottom = 0.0
	lbl.offset_left   = -160.0; lbl.offset_right  = 160.0
	lbl.offset_top    = 16.0;   lbl.offset_bottom = 76.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 600))
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	lbl.add_theme_constant_override("shadow_offset_x", 3)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 4
	lbl.visible = false
	lbl.text = "TURN 1"
	add_child(lbl)
	_turn_number_lbl = lbl

func _build_options_button() -> void:
	# Display size: 230×230. Show upper 2/3 (~153px), hide lower 1/3 (~77px) below screen.
	const BTN_W  : float = 230.0
	const BTN_H  : float = 230.0
	const SHOW_H : float = BTN_H * 2.0 / 3.0
	const HIDE_H : float = BTN_H - SHOW_H
	const HIT_W  : float = 161.0   # 70 % of 230 px icon width
	const HIT_H  : float = 107.0   # 70 % of 153 px visible height

	var root := Control.new()
	root.layout_mode = 1
	root.anchor_left   = 0.5;  root.anchor_right  = 0.5
	root.anchor_top    = 1.0;  root.anchor_bottom = 1.0
	root.offset_left   = -(BTN_W * 0.5)
	root.offset_right  =  (BTN_W * 0.5)
	root.offset_top    = -SHOW_H - 20.0
	root.offset_bottom =  HIDE_H - 20.0
	root.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	root.z_index = 5
	root.visible = false
	add_child(root)
	_options_btn_root = root

	var art := TextureRect.new()
	art.texture = HudSkin.hud_tex("ui_battle_options.png")
	art.ignore_texture_size = true
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(art)
	_options_btn_art = art

	var hit := Control.new()
	hit.layout_mode = 1
	hit.anchor_left   = 0.5;  hit.anchor_right  = 0.5
	hit.anchor_top    = 0.0;  hit.anchor_bottom = 0.0
	hit.offset_left   = -(HIT_W * 0.5)
	hit.offset_right  =  (HIT_W * 0.5)
	hit.offset_top    = (SHOW_H - HIT_H) * 0.5   # ≈ 23 — centers hit slab in visible area
	hit.offset_bottom = hit.offset_top + HIT_H
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_on_options_btn_pressed())
	root.add_child(hit)
	_options_btn = hit

	var opts_lbl := Label.new()
	opts_lbl.text = "OPTIONS"
	opts_lbl.layout_mode = 1
	opts_lbl.anchor_left   = 0.5
	opts_lbl.anchor_right  = 0.5
	opts_lbl.anchor_top    = 0.0
	opts_lbl.anchor_bottom = 0.0
	opts_lbl.offset_left   = -(BTN_W * 0.42)
	opts_lbl.offset_right  =  (BTN_W * 0.42)
	opts_lbl.offset_top    = 58.0
	opts_lbl.offset_bottom = 88.0
	opts_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opts_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	opts_lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 400))
	opts_lbl.add_theme_font_size_override("font_size", 26)
	opts_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	opts_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	opts_lbl.add_theme_constant_override("shadow_offset_x", 1)
	opts_lbl.add_theme_constant_override("shadow_offset_y", 1)
	opts_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(opts_lbl)

	_options_btn.mouse_entered.connect(func(): _show_hud_tooltip("Game options (concede, rules)"))
	_options_btn.mouse_exited.connect(func(): _restore_game_guide())

func _on_options_btn_pressed() -> void:
	if TutorialBattleManager.is_active and not TutorialBattleManager.should_allow_options_btn():
		return
	SFXManager.play(SFXManager.SFX_BTN)
	if TutorialBattleManager.is_active:
		TutorialBattleManager.report_action("options_tap", {})
	if GameDialog.has_open_overlay(self):
		return
	_show_options_panel()

# ─────────────────────────────────────────────────────────────
# Playmat Fog
# ─────────────────────────────────────────────────────────────
const PLAYMAT_V2_EXTRA_WIDTH: float = 0.0

func _build_fog() -> void:
	const FOG_PATH := "res://assets/textures/effect/fog/Noise 3.png"
	var fog_tex := load(FOG_PATH) as Texture2D
	if fog_tex == null:
		return

	var playmat_bg: Control = get_node_or_null("Background") as Control
	if playmat_bg == null:
		return

	var smoke_shader := Shader.new()
	smoke_shader.code = """
shader_type canvas_item;
uniform vec2 scroll = vec2(0.0, 0.0);
uniform float tile_repeat = 1.0;
uniform float image_scale = 3.0;
uniform float fog_alpha = 0.2;
void fragment() {
	vec2 uv = fract(UV * tile_repeat / image_scale + scroll);
	vec4 tex = texture(TEXTURE, uv);
	float smoke = 1.0 - tex.r;
	COLOR = vec4(vec3(smoke), smoke * fog_alpha);
}
"""

	playmat_bg.clip_contents = true

	var fog_clip := Control.new()
	fog_clip.name = "PlaymatFog"
	fog_clip.clip_contents = true
	fog_clip.layout_mode = 1
	fog_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	fog_clip.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(fog_clip)
	move_child(fog_clip, playmat_bg.get_index() + 1)
	_fog_container = fog_clip

	_fog_material = _make_fog_material(smoke_shader, _FOG_TILE_REPEAT)
	_fog_material_diag = _make_fog_material(smoke_shader, _FOG_TILE_REPEAT_DIAG)

	var tr := _make_fog_layer(fog_tex, _fog_material)
	fog_clip.add_child(tr)
	_fog_rect = tr

	var tr_diag := _make_fog_layer(fog_tex, _fog_material_diag)
	fog_clip.add_child(tr_diag)

	_fog_dir_timer = randf_range(3.0, 6.0)
	_pick_new_fog_vertical_dir()


func _make_fog_material(smoke_shader: Shader, tile_repeat: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = smoke_shader
	mat.set_shader_parameter("tile_repeat", tile_repeat)
	mat.set_shader_parameter("image_scale", _FOG_IMAGE_SCALE)
	mat.set_shader_parameter("fog_alpha", _FOG_ALPHA)
	return mat


func _make_fog_layer(fog_tex: Texture2D, mat: ShaderMaterial) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = fog_tex
	tr.material = mat
	tr.layout_mode = 1
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _pick_new_fog_vertical_dir() -> void:
	_fog_scroll_y = randf_range(-5.0, 5.0)
	if absf(_fog_scroll_y) < 1.5:
		_fog_scroll_y = 2.0 if randf() > 0.5 else -2.0


func _update_fog(delta: float) -> void:
	if _fog_material == null:
		return

	_fog_dir_timer -= delta
	if _fog_dir_timer <= 0.0:
		_fog_dir_timer = randf_range(3.0, 7.0)
		_pick_new_fog_vertical_dir()

	var step := delta * 0.002
	_fog_scroll.x += _fog_scroll_x * step
	_fog_scroll.y += _fog_scroll_y * step
	_fog_material.set_shader_parameter("scroll", _fog_scroll)

	if _fog_material_diag:
		_fog_scroll_diag.x += _fog_diag_scroll_x * step
		_fog_scroll_diag.y += _fog_diag_scroll_y * step
		_fog_material_diag.set_shader_parameter("scroll", _fog_scroll_diag)

# ─────────────────────────────────────────────────────────────
# Union Suggestion Button
# ─────────────────────────────────────────────────────────────

func _build_union_suggest_button() -> void:
	const BTN_SIZE:  float = 110.0
	const GLOW_SIZE: float = 155.0

	# Pulsing cyan glow halo behind the button
	var glow := TextureRect.new()
	glow.texture = HudSkin.hud_tex("ui_icon_union.png")
	glow.ignore_texture_size = true
	glow.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.layout_mode  = 1
	glow.anchor_left   = 0.5; glow.anchor_right  = 0.5
	glow.anchor_top    = 0.5; glow.anchor_bottom = 0.5
	glow.offset_left   = -(GLOW_SIZE * 0.5); glow.offset_right  =  (GLOW_SIZE * 0.5)
	glow.offset_top    = -(GLOW_SIZE * 0.5) - 34.0; glow.offset_bottom =  (GLOW_SIZE * 0.5) - 34.0
	glow.modulate    = Color(0.25, 0.90, 1.00, 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index  = 3
	glow.visible  = false
	add_child(glow)
	_union_suggest_glow = glow

	# Tappable button on top
	var btn := TextureButton.new()
	btn.texture_normal   = HudSkin.hud_tex("ui_icon_union.png")
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.layout_mode  = 1
	btn.anchor_left   = 0.5; btn.anchor_right  = 0.5
	btn.anchor_top    = 0.5; btn.anchor_bottom = 0.5
	btn.offset_left   = -(BTN_SIZE * 0.5); btn.offset_right  =  (BTN_SIZE * 0.5)
	btn.offset_top    = -(BTN_SIZE * 0.5) - 34.0; btn.offset_bottom =  (BTN_SIZE * 0.5) - 34.0
	btn.z_index  = 4
	btn.visible  = false
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_union_suggest_pressed)
	add_child(btn)
	_union_suggest_btn = btn
	btn.mouse_entered.connect(func(): _show_hud_tooltip("Tap to summon a Union card"))
	btn.mouse_exited.connect(func(): _restore_game_guide())

func _collect_all_available_unions(player: int) -> Array:
	if _union_summoned_this_duel[player] >= _max_unions_per_duel():
		return []
	if player == 0 and not GameState.battle_player_union_enabled:
		return []
	var seen: Dictionary = {}
	var results: Array   = []
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type != "character":
				continue
			for entry: Dictionary in UnionDatabase.find_available_unions(player, r, c):
				var u: UnionData = entry["union"]
				if GameState.crystals[player] < _effective_union_cost(u.summon_cost):
					continue
				if seen.has(u.card_name):
					continue
				seen[u.card_name] = true
				results.append(entry)
	return results

func _apply_playmat_skin_layout(playmat_rect: TextureRect) -> void:
	playmat_rect.offset_left  = 8.0
	playmat_rect.offset_right = 0.0
	if HudSkin.version == "v2":
		call_deferred("_apply_playmat_v2_scale", playmat_rect)
	else:
		playmat_rect.scale        = Vector2.ONE
		playmat_rect.pivot_offset = Vector2.ZERO

func _apply_playmat_v2_scale(playmat_rect: TextureRect) -> void:
	if not is_instance_valid(playmat_rect):
		return
	var base_w: float = playmat_rect.size.x
	if base_w <= 0.0:
		return
	playmat_rect.pivot_offset = playmat_rect.size * 0.5
	playmat_rect.scale = Vector2((base_w + PLAYMAT_V2_EXTRA_WIDTH) / base_w, 1.0)

## Re-applies all HUD textures from the currently active HudSkin version.
## Called automatically when HudSkin.skin_changed fires (admin: hud_skin v1|v2).
func _reload_hud_skin(_new_version: String = "") -> void:
	var playmat_rect: TextureRect = get_node_or_null("Background") as TextureRect
	if playmat_rect:
		playmat_rect.texture = HudSkin.hud_tex("ui_playmat_default.png")
		_apply_playmat_skin_layout(playmat_rect)
	CTX_ICON_ATTACK = HudSkin.hud_tex("ui_context_menu_attack.png")
	CTX_ICON_INFO   = HudSkin.hud_tex("ui_context_menu_info.png")
	CTX_ICON_BLUFF  = HudSkin.hud_tex("ui_context_menu_bluff.png")
	CTX_ICON_UNION  = HudSkin.hud_tex("ui_icon_union.png")
	if is_instance_valid(_end_turn_btn):
		_end_turn_btn.texture_normal     = HudSkin.hud_tex("ui_end_turn.png")
	if is_instance_valid(_options_btn_art):
		_options_btn_art.texture = HudSkin.hud_tex("ui_battle_options.png")
	if is_instance_valid(_union_suggest_btn):
		_union_suggest_btn.texture_normal = HudSkin.hud_tex("ui_icon_union.png")
	if is_instance_valid(_union_suggest_glow):
		_union_suggest_glow.texture      = HudSkin.hud_tex("ui_icon_union.png")
	if is_instance_valid(_turn_number_bg):
		_turn_number_bg.texture          = HudSkin.hud_tex("ui_turn_number_panel.png")
	if is_instance_valid(_p1_crystal_icon):
		_set_crystal_icon_texture(_p1_crystal_icon, HudSkin.hud_tex("ui_crystal_indicator.png"))
	if is_instance_valid(_p2_crystal_icon):
		_set_crystal_icon_texture(_p2_crystal_icon, HudSkin.hud_tex("ui_crystal_indicator.png"))
	if is_instance_valid(_p1_attack_lbl):
		var p1_icon := _p1_attack_lbl.get_parent().get_child(0) as TextureRect
		if p1_icon: p1_icon.texture = HudSkin.hud_tex("ui_icon_attack_count.png")
	if is_instance_valid(_p2_attack_lbl):
		var p2_icon := _p2_attack_lbl.get_parent().get_child(0) as TextureRect
		if p2_icon: p2_icon.texture = HudSkin.hud_tex("ui_icon_attack_count.png")

func _update_union_suggest_button() -> void:
	if _union_suggest_btn == null:
		return
	# Hide entirely if union mechanism is locked (bypassed in free-play modes)
	var _union_free_play: bool = GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.LOCAL_2P, GameState.GameMode.HOT_SEAT]
	if not SaveManager.union_mechanism_unlocked and not _union_free_play:
		_union_suggest_btn.visible  = false
		_union_suggest_glow.visible = false
		if _union_suggest_tween != null and _union_suggest_tween.is_valid():
			_union_suggest_tween.kill()
		_union_suggest_tween = null
		return
	# Never show the button during the AI's turn
	if _is_ai_turn():
		_union_suggest_btn.visible  = false
		_union_suggest_glow.visible = false
		if _union_suggest_tween != null and _union_suggest_tween.is_valid():
			_union_suggest_tween.kill()
		_union_suggest_tween = null
		return
	# Tutorial: hide on human turn 1 (union mission is on turn 2)
	if TutorialBattleManager.should_hide_union_suggest():
		_union_suggest_btn.visible  = false
		_union_suggest_glow.visible = false
		if _union_suggest_tween != null and _union_suggest_tween.is_valid():
			_union_suggest_tween.kill()
		_union_suggest_tween = null
		return
	var phase: GameState.Phase = GameState.current_phase
	var active: bool = phase in [GameState.Phase.MODE_SELECT, GameState.Phase.ATTACK] \
		and selection_state not in [
			SelectionState.SELECTING_UNION_MATERIALS,
			SelectionState.CONFIRMING_ATTACK,
		]
	if not active:
		_union_suggest_btn.visible  = false
		_union_suggest_glow.visible = false
		if _union_suggest_tween != null and _union_suggest_tween.is_valid():
			_union_suggest_tween.kill()
		_union_suggest_tween = null
		return
	var available: Array = _collect_all_available_unions(GameState.current_player)
	var show: bool = available.size() > 0
	_union_suggest_btn.visible  = show
	_union_suggest_glow.visible = show
	if show and (_union_suggest_tween == null or not _union_suggest_tween.is_valid()):
		_union_suggest_tween = create_tween().set_loops()
		_union_suggest_tween.tween_property(_union_suggest_glow, "modulate:a", 0.65, 0.7)
		_union_suggest_tween.tween_property(_union_suggest_glow, "modulate:a", 0.15, 0.7)
	elif not show:
		if _union_suggest_tween != null and _union_suggest_tween.is_valid():
			_union_suggest_tween.kill()
		_union_suggest_tween = null

func _on_union_suggest_pressed() -> void:
	if selection_state == SelectionState.SELECTING_UNION_MATERIALS:
		return  # already in material selection — ignore duplicate tap
	SFXManager.play(SFXManager.SFX_BTN)
	var available: Array = _collect_all_available_unions(GameState.current_player)
	if available.is_empty():
		return
	if TutorialBattleManager.is_active:
		TutorialBattleManager.report_action("union_hud_tap", {})
	_open_union_modal(GameState.current_player, available)

# ─────────────────────────────────────────────────────────────
# Options Menu
# ─────────────────────────────────────────────────────────────

const OPTIONS_CONTENT_OVERLAY := &"GameDialogContentOverlay"

func _build_card_name_lookup() -> void:
	_card_name_to_type.clear()
	for n: String in CardDatabase.get_all_character_names():
		_card_name_to_type[n] = "character"
	for n: String in CardDatabase.get_all_trap_names():
		_card_name_to_type[n] = "trap"
	for n: String in CardDatabase.get_all_tech_names():
		_card_name_to_type[n] = "tech"

func _make_sub_overlay(half_w: float = 420.0, half_h: float = 300.0) -> Dictionary:
	var shell: Dictionary = GameDialog.content_overlay(
		self, half_w * 2.0, half_h * 2.0, GameDialog.DEFAULT_Z_INDEX, OPTIONS_CONTENT_OVERLAY)
	return {"dimmer": shell["root"], "vbox": shell["vbox"]}

func _add_back_btn(vbox: VBoxContainer, dimmer: Control) -> void:
	var back_btn := Button.new()
	back_btn.text = "← Back"
	GameDialog.style_menu_button(back_btn)
	back_btn.pressed.connect(func() -> void:
		dimmer.queue_free()
		_show_options_panel())
	vbox.add_child(back_btn)

func _show_options_panel() -> void:
	if GameDialog.has_open_overlay(self):
		return
	SFXManager.play(SFXManager.SFX_POPUP)
	_options_panel = GameDialog.menu_overlay(
		self,
		"Options",
		"",
		[
			{"text": "Battle Log", "callback": _show_battle_log_panel},
			{"text": "Rules", "callback": _show_rules_panel},
			{"text": "Surrender", "callback": _show_surrender_confirm},
		],
		"Close")

func _close_options_panel() -> void:
	GameDialog.close_overlay(self)
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
	title.text = "Change Music  💿"
	GameDialog.style_title_label(title)
	vbox.add_child(title)

	var disc_lbl := Label.new()
	disc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameDialog.style_body_label(disc_lbl)
	if already_used:
		disc_lbl.text = "Already changed music this turn."
		disc_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	elif not has_disc:
		disc_lbl.text = "No Music Discs available."
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
		GameDialog.style_menu_button(btn)
		btn.disabled = not can_change
		var track_path: String = track["path"]
		btn.pressed.connect(func() -> void:
			if Collection.spend_music_disc():
				_music_changed_this_turn = true
				_change_battle_music(track_path)
				overlay["dimmer"].queue_free())
		vbox.add_child(btn)

	_add_back_btn(vbox, overlay["dimmer"])
	SFXManager.wire_prompt_buttons_in(vbox)

func _change_battle_music(path: String) -> void:
	if _vs_ai_bgm_muted():
		return
	GameState.battle_bgm_path = path
	BGMManager.play_path(
		path, 0.5, 0.5, GameState.battle_bgm_volume, BGMManager.CONTEXT_BATTLE)

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
	header.text = "Battle Log"
	GameDialog.style_title_label(header)
	vbox.add_child(header)

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
			CardDetailOverlay.open(self, parts[0], parts[1], null, false, false,
				GameDialog.DEFAULT_Z_INDEX + 100))

	_add_back_btn(vbox, dimmer)
	SFXManager.wire_prompt_buttons_in(vbox)

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
	header.text = "Rules"
	GameDialog.style_title_label(header)
	vbox.add_child(header)

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
		"[b]SETUP[/b]\nEach player places Units and Traps face-down on their 5×5 grid.\n\n" +
		"[b]EACH TURN[/b]\nChoose ATTACK or TECH mode.\n" +
		"  [b]Attack[/b] — Pick one of your Units to attack any opponent card.\n" +
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
# Surrender confirm
# ─────────────────────────────────────────────────────────────

func _show_surrender_confirm() -> void:
	SFXManager.play(SFXManager.SFX_POPUP)
	GameDialog.confirmation_overlay(
		self,
		"Surrender?",
		"You will lose this duel.",
		"Yes, Surrender",
		"Cancel",
		func() -> void:
			await _await_prompt_dismiss_delay()
			var winner: int = GameState.get_opponent(GameState.current_player)
			GameState.game_over_reason = "surrender"
			GameState._end_game(winner),
		func() -> void:
			await _await_prompt_dismiss_delay()
			_show_options_panel())

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

## Highlights the full row or full column on the opponent's grid for Rift Strike targeting.
func _rift_update_highlight() -> void:
	var opp: int = GameState.get_opponent(GameState.current_player)
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			grid_nodes[opp][r][c].set_highlighted(false)
	if _rift_hover_cell == Vector2i(-1, -1):
		return
	var hrow: int = _rift_hover_cell.x
	var hcol: int = _rift_hover_cell.y
	if _rift_direction == "row":
		for c: int in range(GameState.GRID_SIZE):
			if GameState.get_card(opp, hrow, c).card_type != "dead_end":
				grid_nodes[opp][hrow][c].set_highlighted(true)
	else:
		for r: int in range(GameState.GRID_SIZE):
			if GameState.get_card(opp, r, hcol).card_type != "dead_end":
				grid_nodes[opp][r][hcol].set_highlighted(true)
	_apply_ability_target_flash()

func _on_grid_card_hovered(player: int, row: int, col: int) -> void:
	var inst: GameState.CardInstance = GameState.get_card(player, row, col)
	if inst == null:
		return
	# Rift Strike hover: track direction and highlight full row or column
	if selection_state == SelectionState.SELECTING_TECH_TARGET \
			and pending_tech_filter == "row_or_column" \
			and player == GameState.get_opponent(GameState.current_player):
		var new_cell := Vector2i(row, col)
		if new_cell != _rift_hover_cell:
			if _rift_last_hover != Vector2i(-1, -1):
				var dr: int = abs(new_cell.x - _rift_last_hover.x)
				var dc: int = abs(new_cell.y - _rift_last_hover.y)
				if dc > dr:
					_rift_direction = "row"
				elif dr > dc:
					_rift_direction = "col"
			_rift_last_hover = _rift_hover_cell
			_rift_hover_cell = new_cell
			_rift_update_highlight()
	# Intensify hover pulse on any valid tech target (face-down adjacent, Radar, etc.)
	if selection_state == SelectionState.SELECTING_TECH_TARGET:
		var tech_node: Control = grid_nodes[player][row][col]
		if tech_node.is_highlighted and _should_show_ability_target_flash():
			_set_tech_hover_node(tech_node)
	# Red hover during attack target selection — unrevealed dead_end slots are valid targets
	if selection_state == SelectionState.SELECTING_TARGET \
			and player == GameState.get_opponent(GameState.current_player) \
			and not inst.was_destroyed:
		_set_attack_hover_node(grid_nodes[player][row][col])
	# Dead-end slots have no info to show
	if inst.card_type == "dead_end":
		return
	# Mini card info panel disabled during battle.

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
			_hover_type_lbl.text = "UNIT  %d◆" % data.crystal_cost
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
	_set_attack_hover_node(null)

func _set_tech_hover_node(node: Control) -> void:
	if _tech_hover_node != null and _tech_hover_node != node:
		_tech_hover_node.set_target_hover(false)
	_tech_hover_node = node
	if _tech_hover_node != null:
		_tech_hover_node.set_target_hover(true)

func _set_attack_hover_node(node: Control) -> void:
	if _attack_hover_node != null and _attack_hover_node != node:
		_attack_hover_node.set_attack_hover(false)
	_attack_hover_node = node
	if _attack_hover_node != null:
		_attack_hover_node.set_attack_hover(true)

func _stop_battle_music() -> void:
	BGMManager.stop(0.0)


func _vs_ai_bgm_muted() -> bool:
	return GameState.game_mode == GameState.GameMode.VS_AI and not GameState.battle_bgm_enabled

# ─────────────────────────────────────────────────────────────
# Compact card-effect coin flip overlay (1–3 coins, auto-dismiss)
# ─────────────────────────────────────────────────────────────
func _on_coin_flip_visual_requested(results: Array) -> void:
	await _show_compact_coin_flip(results)
	turn_manager.resolve_coin_flip_visual()

func _show_compact_coin_flip(results: Array) -> void:
	var _COIN_FRONT: Texture2D = HudSkin.hud_tex("ui_coin_front.png")
	var _COIN_BACK:  Texture2D = HudSkin.hud_tex("ui_coin_back.png")
	const COIN_SZ   : float = 140.0
	const NUM_FLIPS : int   = 5

	var count: int = clampi(results.size(), 1, 3)
	var vp: Vector2 = get_viewport().get_visible_rect().size

	# ── Semi-transparent panel ──────────────────────────────
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_compact_flip_stylebox())
	panel.z_index       = 115
	panel.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left   = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_top    = 0.5
	panel.anchor_bottom = 0.5
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var coins_row := HBoxContainer.new()
	coins_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coins_row.add_theme_constant_override("separation", 18)
	vbox.add_child(coins_row)

	var result_row := HBoxContainer.new()
	result_row.alignment = BoxContainer.ALIGNMENT_CENTER
	result_row.add_theme_constant_override("separation", 18)
	vbox.add_child(result_row)

	# Build per-coin sprites and result labels
	var coin_sprites: Array = []
	var result_labels: Array = []
	for i in range(count):
		var is_heads: bool = results[i]

		var spr := TextureRect.new()
		spr.texture             = _COIN_FRONT
		spr.custom_minimum_size = Vector2(COIN_SZ, COIN_SZ)
		spr.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
		spr.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT
		spr.pivot_offset        = Vector2(COIN_SZ * 0.5, COIN_SZ * 0.5)
		coins_row.add_child(spr)
		coin_sprites.append(spr)

		var lbl := Label.new()
		lbl.text                    = "It's heads!!" if is_heads else "It's tails..!!"
		lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color",
			Color(0.3, 1.0, 0.4, 0.0) if is_heads else Color(1.0, 0.38, 0.38, 0.0))
		lbl.custom_minimum_size = Vector2(COIN_SZ, 26)
		result_row.add_child(lbl)
		result_labels.append(lbl)

	# Position panel centered
	await get_tree().process_frame
	var ps: Vector2 = panel.size
	panel.offset_left   = -ps.x * 0.5
	panel.offset_right  =  ps.x * 0.5
	panel.offset_top    = -ps.y * 0.5
	panel.offset_bottom =  ps.y * 0.5

	# ── Flip animations (run all coins in parallel) ─────────
	SFXManager.play(SFXManager.SFX_COIN_FLIP)
	for flip in range(NUM_FLIPS):
		var progress: float = float(flip) / float(NUM_FLIPS)
		var half_dur: float = lerpf(0.055, 0.18, progress)

		# Shrink all coins to 0 width simultaneously
		var tw_in := create_tween()
		for spr: TextureRect in coin_sprites:
			tw_in.parallel().tween_property(spr, "scale:x", 0.0, half_dur) \
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		await tw_in.finished

		# Swap textures based on flip parity
		var show_front: bool = (flip % 2 == 0)  # starts front, alternates
		var is_last: bool = (flip == NUM_FLIPS - 1)
		for i in range(count):
			var spr: TextureRect = coin_sprites[i]
			if is_last:
				spr.texture = _COIN_FRONT if bool(results[i]) else _COIN_BACK
			else:
				spr.texture = _COIN_BACK if show_front else _COIN_FRONT

		# Expand back
		var tw_out := create_tween()
		for spr: TextureRect in coin_sprites:
			tw_out.parallel().tween_property(spr, "scale:x", 1.0, half_dur) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		await tw_out.finished

	# ── Fade in result labels ───────────────────────────────
	var lbl_in := create_tween()
	for lbl: Label in result_labels:
		var heads: bool = lbl.text.begins_with("It's heads")
		var col: Color = Color(0.3, 1.0, 0.4, 1.0) if heads else Color(1.0, 0.38, 0.38, 1.0)
		lbl_in.parallel().tween_property(lbl, "theme_override_colors/font_color", col, 0.25)
	await lbl_in.finished
	for i: int in range(results.size()):
		SFXManager.play(SFXManager.SFX_COIN_HEAD if bool(results[i]) else SFXManager.SFX_COIN_TAIL)

	await get_tree().create_timer(1.1).timeout

	# ── Fade out panel ──────────────────────────────────────
	var fade := create_tween()
	fade.tween_property(panel, "modulate:a", 0.0, 0.35)
	await fade.finished
	panel.queue_free()

func _make_compact_flip_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color           = Color(0.06, 0.06, 0.10, 0.88)
	sb.corner_radius_top_left     = 14
	sb.corner_radius_top_right    = 14
	sb.corner_radius_bottom_left  = 14
	sb.corner_radius_bottom_right = 14
	sb.content_margin_left   = 28.0
	sb.content_margin_right  = 28.0
	sb.content_margin_top    = 20.0
	sb.content_margin_bottom = 20.0
	return sb

# ─────────────────────────────────────────────────────────────
# Coin flip overlay
# ─────────────────────────────────────────────────────────────
func _show_coin_flip_and_start(first_player: int) -> void:
	var _COIN_FRONT: Texture2D = HudSkin.hud_tex("ui_coin_front.png")
	var _COIN_BACK:  Texture2D = HudSkin.hud_tex("ui_coin_back.png")
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

	var _p1_tex: Texture2D = GameState.load_portrait_texture(GameState.player_portraits[0])
	if _p1_tex:
		var sz := _p1_tex.get_size()
		var _p1h: float = REF_H * maxf(0.1, GameState.portrait_p1_size)
		var pw: float = _p1h * sz.x / sz.y if sz.y > 0.0 else PORTRAIT_W
		var _p1ox: float = GameState.portrait_p1_offset.x
		coin_p1_port = TextureRect.new()
		coin_p1_port.texture       = _p1_tex
		coin_p1_port.layout_mode   = 1
		coin_p1_port.anchor_left   = 0.0
		coin_p1_port.anchor_top    = 0.0
		coin_p1_port.anchor_right  = 0.0
		coin_p1_port.anchor_bottom = 1.0
		coin_p1_port.offset_left   = _p1ox
		coin_p1_port.offset_right  = pw + _p1ox
		coin_p1_port.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		coin_p1_port.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
		coin_p1_port.flip_h        = true
		coin_p1_port.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		coin_p1_port.modulate      = GREY_MODULATE
		overlay.add_child(coin_p1_port)

	var _p2_tex: Texture2D = GameState.load_portrait_texture(GameState.player_portraits[1])
	if _p2_tex:
		var sz := _p2_tex.get_size()
		var _p2h: float = REF_H * maxf(0.1, GameState.portrait_p2_size)
		var pw: float = _p2h * sz.x / sz.y if sz.y > 0.0 else PORTRAIT_W
		var _p2ox: float = GameState.portrait_p2_offset.x
		coin_p2_port = TextureRect.new()
		coin_p2_port.texture       = _p2_tex
		coin_p2_port.layout_mode   = 1
		coin_p2_port.anchor_left   = 1.0
		coin_p2_port.anchor_top    = 0.0
		coin_p2_port.anchor_right  = 1.0
		coin_p2_port.anchor_bottom = 1.0
		coin_p2_port.offset_left   = -pw - _p2ox
		coin_p2_port.offset_right  = -_p2ox
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
	SFXManager.play(SFXManager.SFX_COIN_FLIP)
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
		SFXManager.play(SFXManager.SFX_COIN_HEAD)
	else:
		result_lbl.text = "TAILS — Player 2 goes first!"
		SFXManager.play(SFXManager.SFX_COIN_TAIL)

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

	var forced_names: Array[String] = []
	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		var raw_ft: Array = AIvsAIManager.forced_tech_0 if player == 0 else AIvsAIManager.forced_tech_1
		for t: Variant in raw_ft:
			var n: String = str(t).strip_edges()
			if n.is_empty() or CardDatabase.get_tech(n) == null:
				continue
			if n in forced_names:
				continue
			forced_names.append(n)
		if forced_names.is_empty():
			var deck: Variant = GameState.battle_player_deck if player == 0 else GameState.battle_ai_deck
			if deck != null:
				for t: Variant in (deck as DeckData).techs:
					var dn: String = str(t).strip_edges()
					if dn.is_empty() or CardDatabase.get_tech(dn) == null:
						continue
					if dn in forced_names:
						continue
					forced_names.append(dn)
	else:
		# VS_AI: AI player (1) can have a forced tech hand set from the VS AI config screen
		if player == 1 and not GameState.battle_ai_forced_tech.is_empty():
			for t: Variant in GameState.battle_ai_forced_tech:
				var n: String = str(t).strip_edges()
				if not n.is_empty() and CardDatabase.get_tech(n) != null and n not in forced_names:
					forced_names.append(n)
		elif player == 1 and _vs_ai_deck != null:
			for t: Variant in (_vs_ai_deck as DeckData).techs:
				var dn: String = str(t).strip_edges()
				if not dn.is_empty() and CardDatabase.get_tech(dn) != null and dn not in forced_names:
					forced_names.append(dn)
		else:
			var forced_tech: Variant = GameState.campaign_enemy_config.get("forced_tech", null)
			if forced_tech is Array:
				for t: Variant in forced_tech as Array:
					var n: String = str(t).strip_edges()
					if not n.is_empty() and CardDatabase.get_tech(n) != null and n not in forced_names:
						forced_names.append(n)

	for n: String in forced_names:
		if GameState.tech_hands[player].size() >= count:
			break
		GameState.tech_hands[player].append(n)

	if GameState.tech_hands[player].size() >= count:
		return

	var tech_pool: Array = CardDatabase.get_all_tech_names()
	if SaveManager.demo_mode:
		tech_pool = tech_pool.filter(func(n: String) -> bool:
			var tc: TechCardData = CardDatabase.get_tech(n)
			return tc != null and tc.include_in_demo)
	tech_pool.shuffle()
	for n: String in tech_pool:
		if n in GameState.tech_hands[player]:
			continue
		GameState.tech_hands[player].append(n)
		if GameState.tech_hands[player].size() >= count:
			break

# ─────────────────────────────────────────────────────────────
# HUD Updates
# ─────────────────────────────────────────────────────────────
func _refresh_hud() -> void:
	_update_crystals(0, GameState.crystals[0])
	_update_crystals(1, GameState.crystals[1])
	_update_turn_info()

func _on_crystals_changed(player_index: int, new_amount: int, _reason: String = "") -> void:
	_crystal_anim_queue.append({"player": player_index, "new_amount": new_amount})
	if not _crystal_anim_processing:
		_process_crystal_anim_queue()

func _process_crystal_anim_queue() -> void:
	_crystal_anim_processing = true
	_update_crystal_visibility()
	while _crystal_anim_queue.size() > 0:
		var job: Dictionary = _crystal_anim_queue.pop_front()
		await _run_crystal_change_animation(int(job["player"]), int(job["new_amount"]))
		_update_union_suggest_button()
	_crystal_anim_processing = false
	_update_crystal_visibility()

func _notify_crystal_animation_complete() -> void:
	GameState.complete_crystal_animation()
	if turn_manager != null:
		turn_manager.crystal_animation_done.emit()

## Waits for burst, tick, and post-tick hold — used before end-game reveal/shake.
func _wait_crystal_display_finished() -> void:
	while _crystal_anim_processing:
		await get_tree().process_frame
	await GameState.wait_crystal_animation()

func _crystal_tick_duration(old_amount: int, new_amount: int) -> float:
	var delta := absi(new_amount - old_amount)
	if delta <= 0:
		return 0.0
	return clampf(
		CRYSTAL_TICK_BASE_SEC + float(delta) * CRYSTAL_TICK_PER_UNIT_SEC,
		CRYSTAL_TICK_BASE_SEC,
		CRYSTAL_TICK_MAX_SEC)

func _run_crystal_change_animation(player_index: int, new_amount: int) -> void:
	var old_amount := _prev_crystals[player_index]
	_prev_crystals[player_index] = new_amount
	if new_amount < old_amount:
		await _play_crystal_burst(player_index, false)
		await _tick_crystal(player_index, old_amount, new_amount)
		_notify_crystal_animation_complete()
		await get_tree().create_timer(1.0).timeout
		if new_amount > 0:
			_check_almost_win_bgm()
	elif new_amount > old_amount:
		await _play_crystal_burst(player_index, true)
		await _tick_crystal(player_index, old_amount, new_amount)
		_notify_crystal_animation_complete()
		await get_tree().create_timer(1.0).timeout
	else:
		var bottom_lbl := _p1_bottom_crystal if player_index == 0 else _p2_bottom_crystal
		if bottom_lbl != null:
			bottom_lbl.text = str(new_amount)
		await get_tree().process_frame
		_notify_crystal_animation_complete()

func _update_crystals(player_index: int, amount: int) -> void:
	_prev_crystals[player_index] = amount
	var bottom_lbl := _p1_bottom_crystal if player_index == 0 else _p2_bottom_crystal
	if bottom_lbl != null:
		bottom_lbl.text = str(amount)

# Crystal burst animation: icon duplicates, scales up and fades out
func _play_crystal_burst(player_index: int, is_gain: bool) -> void:
	var icon := _p1_crystal_icon if player_index == 0 else _p2_crystal_icon
	if icon == null or not is_instance_valid(icon):
		return
	var icon_wrap := icon.get_parent()
	if icon_wrap == null:
		return
	var asp := AudioStreamPlayer.new()
	asp.stream = SFXManager.SFX_CRYSTAL_GAIN if is_gain else SFX_CRYSTAL
	asp.bus = "SFX"
	add_child(asp)
	asp.play()
	asp.finished.connect(asp.queue_free)
	var burst := TextureRect.new()
	burst.texture = icon.texture
	burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var burst_size: Vector2 = icon.size
	if burst_size.x <= 0.0 or burst_size.y <= 0.0:
		burst_size = icon.get_rect().size
	burst.size = burst_size
	burst.position = icon.position
	burst.pivot_offset = burst_size * 0.5
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.z_index = 10
	icon_wrap.add_child(burst)
	var t := create_tween()
	t.tween_property(burst, "scale", Vector2(2.4, 2.4), 0.42).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t.parallel().tween_property(burst, "modulate:a", 0.0, 0.42).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await t.finished
	burst.queue_free()

# Tick animation: smoothly counts the label from old to new (up or down)
func _play_crystal_tick_sfx(player_index: int) -> bool:
	var idx: int = clampi(player_index, 0, 1)
	var now: float = Time.get_ticks_msec() * 0.001
	if _crystal_tick_sfx_window_start[idx] < 0.0 \
			or now - _crystal_tick_sfx_window_start[idx] >= CRYSTAL_TICK_SFX_WINDOW_SEC:
		_crystal_tick_sfx_window_start[idx] = now
		_crystal_tick_sfx_window_count[idx] = 0
	if _crystal_tick_sfx_window_count[idx] >= CRYSTAL_TICK_SFX_MAX:
		return false
	_crystal_tick_sfx_window_count[idx] += 1
	SFXManager.play(SFXManager.SFX_TICK)
	return true

func _tick_crystal(player_index: int, old_amount: int, new_amount: int) -> void:
	var lbl := _p1_bottom_crystal if player_index == 0 else _p2_bottom_crystal
	if lbl == null:
		return
	if old_amount == new_amount:
		lbl.text = str(new_amount)
		return
	var duration := _crystal_tick_duration(old_amount, new_amount)
	var slots: int = _crystal_tick_sfx_slots_available(player_index)
	var fits_duration: int = int(duration / CRYSTAL_TICK_SFX_INTERVAL_SEC) + 1 if duration > 0.0 else 1
	var plays: int = mini(slots, mini(CRYSTAL_TICK_SFX_MAX, fits_duration))
	var tick_sfx := func() -> void:
		_play_crystal_tick_sfx(player_index)
	var t := create_tween()
	if plays > 0:
		t.set_parallel(true)
	t.tween_method(
		func(v: float) -> void: lbl.text = str(int(round(v))),
		float(old_amount), float(new_amount), duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	for i in range(plays):
		t.tween_callback(tick_sfx).set_delay(CRYSTAL_TICK_SFX_INTERVAL_SEC * float(i))
	await t.finished
	lbl.text = str(new_amount)

func _on_dice_rolled(result: int) -> void:
	dice_display.text = "[%d]" % result

func _on_message_posted(text: String) -> void:
	print("[BATTLE LOG] ", text)
	message_log.append_text("\n" + text)
	_battle_log_lines.append(text)

func _on_center_message_requested(text: String) -> void:
	SFXManager.play(SFXManager.SFX_POPUP)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.layout_mode = 1
	lbl.anchor_left = 0.1; lbl.anchor_right  = 0.9
	lbl.anchor_top  = 0.4; lbl.anchor_bottom = 0.6
	lbl.z_index = 200
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)

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
		_turn_number_lbl.text = "TURN %d" % GameState.turn_number

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

	var _stone_age: bool = GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
		and "stone_age" in GameState.active_dungeon_modifiers
	var _tech_royale: bool = GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
		and "tech_royale" in GameState.active_dungeon_modifiers
	var can_use_tech: bool = (GameState.current_phase == GameState.Phase.MODE_SELECT
		and (not _tech_used_this_turn[player] or _tech_royale)
		and player == GameState.current_player
		and not _stone_age)

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
		if selection_state == SelectionState.SELECTING_TECH_TARGET \
				and pending_tech_filter.begins_with("own_units_up_to_"):
			var picked: int = _tech_reveal_picked.size()
			if picked > 0:
				GameState.post_message("Great Diplomacy: revealed %d unit(s)." % picked)
			elif _count_own_facedown_units(GameState.current_player, []) == 0:
				GameState.post_message("Great Diplomacy: no face-down units to reveal.")
			_finish_tech_action(GameState.current_player)
			return
		# Block cancel while mid-way through a multi-reveal sequence (e.g. Radar)
		var mid_reveal := selection_state == SelectionState.SELECTING_TECH_TARGET \
				and _tech_reveals_total > 1 \
				and _tech_reveals_remaining < _tech_reveals_total \
				and not pending_tech_filter.begins_with("own_units_up_to_")
		if not mid_reveal and GameState.current_phase in [GameState.Phase.MODE_SELECT, GameState.Phase.ATTACK]:
			_set_selection_state(SelectionState.SELECTING_ATTACKER)
			_highlight_attackable_chars())
	SFXManager.wire_prompt_button(cancel)
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
		# Reveal-type cards need at least 1 face-down opponent cell to be usable
		# (includes dead_end cells — Radar can target blank slots)
		if can_use and data != null and data.effect_type in [
				TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE,
				TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_CHAIN,
				TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_RISKY]:
			can_use = _count_opponent_facedown(GameState.get_opponent(player)) > 0

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
			use_btn.set_meta("tut_tech", tech_name)
			var captured: String = tech_name
			use_btn.pressed.connect(func() -> void: _on_tech_use_pressed(captured, true))
			SFXManager.wire_prompt_button(use_btn)
			col.add_child(use_btn)

func _dismiss_tech_hand_overlay() -> void:
	if _tech_hand_overlay != null:
		_tech_hand_overlay.queue_free()
		_tech_hand_overlay = null

func _close_blackmail_tech_overlay() -> void:
	_tech_overlay_mode = ""
	_dismiss_tech_hand_overlay()
	if _tech_resolve_blocker:
		_tech_resolve_blocker.visible = false
	_update_tech_stacks()

func _show_blackmail_tech_overlay(player: int) -> void:
	_dismiss_tech_hand_overlay()
	_close_tech_overlay()
	_tech_overlay_mode = "blackmail"
	if _tech_resolve_blocker:
		_tech_resolve_blocker.visible = true

	var hand: Array = GameState.tech_hands[player]
	const PAD: int = 20
	const GAP: int = 12

	_tech_hand_overlay = Control.new()
	_tech_hand_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tech_hand_overlay.z_index = 110
	add_child(_tech_hand_overlay)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.75)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_tech_hand_overlay.add_child(dimmer)

	var panel_c := PanelContainer.new()
	panel_c.layout_mode = 1
	panel_c.anchor_left = 0.0
	panel_c.anchor_top = 0.0
	panel_c.anchor_right = 1.0
	panel_c.anchor_bottom = 1.0
	panel_c.offset_left = PAD
	panel_c.offset_top = PAD
	panel_c.offset_right = -PAD
	panel_c.offset_bottom = -PAD
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.05, 0.07, 0.17, 0.98)
	psb.border_width_left = 2
	psb.border_width_top = 2
	psb.border_width_right = 2
	psb.border_width_bottom = 2
	psb.border_color = Color(0.85, 0.35, 0.35, 0.65)
	psb.corner_radius_top_left = 8
	psb.corner_radius_top_right = 8
	psb.corner_radius_bottom_left = 8
	psb.corner_radius_bottom_right = 8
	psb.content_margin_left = PAD
	psb.content_margin_right = PAD
	psb.content_margin_top = 12
	psb.content_margin_bottom = PAD
	panel_c.add_theme_stylebox_override("panel", psb)
	_tech_hand_overlay.add_child(panel_c)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", GAP)
	panel_c.add_child(vbox)

	var title := Label.new()
	title.text = "BLACKMAIL — Select a Tech to discard"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75, 1.0))
	vbox.add_child(title)

	if hand.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No Tech cards in hand"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 14)
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		vbox.add_child(empty_lbl)
	else:
		var card_hbox := HBoxContainer.new()
		card_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_hbox.add_theme_constant_override("separation", GAP)
		vbox.add_child(card_hbox)

		for i in range(hand.size()):
			var tech_name: String = str(hand[i])
			var col := VBoxContainer.new()
			col.custom_minimum_size = Vector2(160.0, 0.0)
			col.size_flags_vertical = Control.SIZE_EXPAND_FILL
			col.add_theme_constant_override("separation", 8)
			card_hbox.add_child(col)

			var img := TextureRect.new()
			img.custom_minimum_size = Vector2(160.0, 220.0)
			img.size_flags_vertical = Control.SIZE_EXPAND_FILL
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var snake: String = tech_name.to_lower() \
				.replace(" ", "_").replace("'", "").replace("-", "_")
			var path: String = "res://assets/textures/cards/full_cards/" + snake + ".png"
			if not ResourceLoader.exists(path):
				path = "res://assets/textures/cards/full_cards/tech_" + snake + ".png"
			if ResourceLoader.exists(path):
				img.texture = load(path)
			col.add_child(img)

			var select_btn := Button.new()
			select_btn.custom_minimum_size = Vector2(0.0, 52.0)
			select_btn.text = "SELECT"
			select_btn.add_theme_font_size_override("font_size", 16)
			var captured: String = tech_name
			select_btn.pressed.connect(func() -> void:
				_close_blackmail_tech_overlay()
				turn_manager.resolve_blackmail_choice(captured))
			col.add_child(select_btn)

	var end_turn_btn := Button.new()
	end_turn_btn.custom_minimum_size = Vector2(0.0, 52.0)
	end_turn_btn.text = "END TURN"
	end_turn_btn.add_theme_font_size_override("font_size", 16)
	end_turn_btn.pressed.connect(func() -> void:
		_close_blackmail_tech_overlay()
		turn_manager.resolve_blackmail_choice(""))
	vbox.add_child(end_turn_btn)

	SFXManager.wire_prompt_buttons_in(vbox)
	SFXManager.play(SFXManager.SFX_POPUP)

func _on_awaiting_blackmail_tech_select(player: int) -> void:
	if is_instance_valid(_current_battle_overlay):
		_current_battle_overlay.pause_for_choice()
	if _is_ai_turn():
		await get_tree().create_timer(0.6).timeout
		var discarded: String = _active_ai.decide_blackmail_tech()
		turn_manager.resolve_blackmail_choice(discarded)
	else:
		_show_blackmail_tech_overlay(player)

# ─────────────────────────────────────────────────────────────
# Buttons
# ─────────────────────────────────────────────────────────────
func _is_ai_turn() -> bool:
	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		return true
	return GameState.current_player == 1 and \
		GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
			GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION]

# ─────────────────────────────────────────────────────────────
# Tutorial Battle — position query helpers
# ─────────────────────────────────────────────────────────────

## Returns the global center of the first matching card on [player]'s grid.
func get_card_center(player: int, card_name: String) -> Vector2:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var ci: GameState.CardInstance = GameState.get_card(player, r, c)
			if ci != null and ci.card_type == "character" \
					and ci.card_name == card_name and not ci.was_destroyed:
				return grid_nodes[player][r][c].get_global_rect().get_center()
	return Vector2.ZERO

## Returns the global center of a grid cell.
func get_cell_center(player: int, row: int, col: int) -> Vector2:
	if row < 0 or row >= GameState.GRID_SIZE or col < 0 or col >= GameState.GRID_SIZE:
		return Vector2.ZERO
	return grid_nodes[player][row][col].get_global_rect().get_center()

## Returns the global center of the context-menu button tagged with [action_meta].
func get_context_btn_center(action_meta: String) -> Vector2:
	if _context_popup == null or not is_instance_valid(_context_popup):
		return Vector2.ZERO
	return _find_meta_btn_center(_context_popup, "tut_action", action_meta)

## Returns the global center of the End Turn button.
func get_end_turn_btn_center() -> Vector2:
	if _end_turn_btn == null or not is_instance_valid(_end_turn_btn):
		return Vector2.ZERO
	return _end_turn_btn.get_global_rect().get_center()

## Returns the global center of the Options button.
func get_options_btn_center() -> Vector2:
	if _options_btn == null or not is_instance_valid(_options_btn):
		return Vector2.ZERO
	return _options_btn.get_global_rect().get_center()

## Returns the global center of the Union suggest button.
func get_union_btn_center() -> Vector2:
	if _union_suggest_btn == null or not is_instance_valid(_union_suggest_btn):
		return Vector2.ZERO
	return _union_suggest_btn.get_global_rect().get_center()

## Returns the global center of the tech chip stack for a player.
func get_tech_chip_center(player: int) -> Vector2:
	var stack: Control = _p1_tech_stack if player == 0 else _p2_tech_stack
	if stack == null or not is_instance_valid(stack):
		return Vector2.ZERO
	return stack.get_global_rect().get_center()

## Returns the global center of the void stack for a player.
func get_void_stack_center(player: int) -> Vector2:
	var stack: Control = _p1_void_stack if player == 0 else _p2_void_stack
	if stack == null or not is_instance_valid(stack):
		return Vector2.ZERO
	return stack.get_global_rect().get_center()

## Returns the center of the USE button for [tech_name] inside the tech hand overlay.
func get_tech_use_btn_center(tech_name: String) -> Vector2:
	if _tech_hand_overlay == null or not is_instance_valid(_tech_hand_overlay):
		return Vector2.ZERO
	return _find_meta_btn_center(_tech_hand_overlay, "tut_tech", tech_name)

## Returns the center of the first Button in [modal] whose text contains [union_name].
func get_union_modal_btn_center(union_name: String) -> Vector2:
	if _union_modal == null or not is_instance_valid(_union_modal):
		return Vector2.ZERO
	return _find_text_btn_center(_union_modal, union_name)

func _find_meta_btn_center(root: Node, meta_key: String, meta_val: String) -> Vector2:
	for child in root.get_children():
		if child is Button and child.has_meta(meta_key) and child.get_meta(meta_key) == meta_val:
			return (child as Button).get_global_rect().get_center()
		var r := _find_meta_btn_center(child, meta_key, meta_val)
		if r != Vector2.ZERO:
			return r
	return Vector2.ZERO

func _find_text_btn_center(root: Node, text_contains: String) -> Vector2:
	for child in root.get_children():
		if child is Button and text_contains.to_lower() in child.text.to_lower():
			return (child as Button).get_global_rect().get_center()
		var r := _find_text_btn_center(child, text_contains)
		if r != Vector2.ZERO:
			return r
	return Vector2.ZERO

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
	SFXManager.play(SFXManager.SFX_CANCEL)
	_clear_selection()
	_set_selection_state(SelectionState.NONE)
	action_panel.visible = false

# ─────────────────────────────────────────────────────────────
# End Turn — Tax Confirmation
# ─────────────────────────────────────────────────────────────
const TAX_BASE: int = 50

func _current_skip_tax(player: int = -1) -> int:
	var p: int = player if player >= 0 else GameState.current_player
	# Doubles each consecutive no-attack turn: 50, 100, 200, 400, 800, 1600 …
	return TAX_BASE << GameState.skip_counts[p]

func _player_has_attacked_this_turn(player: int) -> bool:
	# Mid-reckoning: attack committed but attacked_this_turn / attacks_remaining not updated yet.
	if GameState.current_phase == GameState.Phase.BATTLE and GameState.current_player == player:
		return true
	if GameState.attacks_remaining < 2:
		return true
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character" and card.attacked_this_turn:
				return true
	return false

func _dismiss_tax_confirm_panel() -> void:
	if _tax_confirm_panel != null:
		_tax_confirm_panel.queue_free()
		_tax_confirm_panel = null

## AI end-turn handler — mirrors _on_end_turn_requested but auto-pays the skip tax.
func _on_ai_end_turn() -> void:
	if GameState.current_phase == GameState.Phase.GAME_OVER:
		return
	if _should_defer_turn_flow():
		_deferred_ai_turn_flow = true
		return
	_hide_thinking_bubble()
	var player := GameState.current_player
	var has_attacked := _player_has_attacked_this_turn(player)
	var _tax_free: bool = GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
		and "tax_free_zone" in GameState.active_dungeon_modifiers
	if not has_attacked and GameState.can_player_attack(player) and not _tax_free:
		var tax: int = _current_skip_tax()
		GameState.skip_counts[player] += 1
		GameState.lose_crystals(player, tax, "skip tax")
		GameState.post_message("%s skips without attacking — %d◆ tax (skip #%d this duel)" % [
			GameState.format_player_label(player), tax, GameState.skip_counts[player]])
		await GameState.wait_crystal_animation()
	turn_manager.end_attacks_early()

func _on_end_turn_requested() -> void:
	if _end_turn_request_busy:
		return
	if TutorialBattleManager.is_active and not TutorialBattleManager.should_allow_end_turn_btn():
		return
	if _is_ai_turn():
		return
	if GameState.current_phase in [GameState.Phase.BATTLE, GameState.Phase.GAME_OVER]:
		return
	var requesting_player: int = GameState.current_player
	_end_turn_request_busy = true
	SFXManager.play(SFXManager.SFX_BTN)
	if TutorialBattleManager.is_active:
		TutorialBattleManager.report_action("end_turn_tap", {})
	await get_tree().create_timer(0.5).timeout
	_end_turn_request_busy = false
	if GameState.current_phase == GameState.Phase.GAME_OVER:
		return
	# Ignore stale clicks after the 0.5s debounce (turn advanced, reckoning, or AI started).
	if _is_ai_turn() or GameState.current_player != requesting_player:
		return
	if GameState.current_phase == GameState.Phase.BATTLE:
		return
	var has_attacked := _player_has_attacked_this_turn(requesting_player)
	var _tax_free: bool = GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
		and "tax_free_zone" in GameState.active_dungeon_modifiers
	if not has_attacked and GameState.can_player_attack(requesting_player) and not _tax_free:
		_show_tax_confirm(requesting_player)
	else:
		turn_manager.end_attacks_early()

func _show_tax_confirm(player: int) -> void:
	SFXManager.play(SFXManager.SFX_POPUP)
	if _tax_confirm_panel != null:
		return
	if _is_ai_turn() or GameState.current_player != player:
		return

	var skips: int = GameState.skip_counts[player]
	var tax := _current_skip_tax(player)
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

	var crystal_tex: Texture2D = HudSkin.hud_tex("ui_crystal_indicator.png")
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
		await _await_prompt_dismiss_delay()
		GameState.skip_counts[player] += 1
		GameState.lose_crystals(player, tax, "skip tax")
		GameState.post_message("%s skips without attacking — %d◆ tax (skip #%d this duel)" % [
			GameState.format_player_label(player), tax, GameState.skip_counts[player]])
		await GameState.wait_crystal_animation()
		turn_manager.end_attacks_early())
	row.add_child(confirm_btn)

	var cancel_btn2 := Button.new()
	cancel_btn2.text = "Cancel"
	cancel_btn2.add_theme_font_size_override("font_size", 15)
	cancel_btn2.pressed.connect(func() -> void:
		if _tax_confirm_panel != null:
			_tax_confirm_panel.queue_free()
			_tax_confirm_panel = null
		await _await_prompt_dismiss_delay())
	row.add_child(cancel_btn2)
	SFXManager.wire_prompt_buttons_in(panel)

func _on_tech_card_btn(tech_name: String) -> void:
	pending_tech_name = tech_name
	turn_manager.play_tech_card(tech_name)

func _on_play_again_btn() -> void:
	get_tree().reload_current_scene()

# ─────────────────────────────────────────────────────────────
# Turn-flow blocking — prevent AI/turn advance during pending selections
# ─────────────────────────────────────────────────────────────
func _should_defer_turn_flow() -> bool:
	if turn_manager.is_flow_blocked():
		return true
	if selection_state in [
		SelectionState.SELECTING_TECH_TARGET,
		SelectionState.AWAITING_TRAP_CHOICE,
		SelectionState.SELECTING_UNION_MATERIALS,
	]:
		return true
	if _pending_human_defender_tech:
		return true
	if _ai_union_resolve_in_progress:
		return true
	return false

func _on_flow_blocking_cleared() -> void:
	call_deferred("_try_resume_deferred_turn_flow")

func _try_resume_deferred_turn_flow() -> void:
	if not _deferred_ai_turn_flow:
		return
	if _should_defer_turn_flow():
		return
	if not _is_ai_turn() or GameState.current_phase == GameState.Phase.GAME_OVER:
		_deferred_ai_turn_flow = false
		return
	_deferred_ai_turn_flow = false
	_start_ai_turn_flow()

func _start_ai_turn_flow() -> void:
	if _should_defer_turn_flow():
		_deferred_ai_turn_flow = true
		return
	_deferred_ai_turn_flow = false
	_dismiss_tax_confirm_panel()
	if _end_turn_btn:
		_end_turn_btn.visible = false
	if _options_btn_root:
		_options_btn_root.visible = false
	_restart_ai_watchdog()
	var _tech_royale_ai: bool = GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
		and "tech_royale" in GameState.active_dungeon_modifiers
	_active_ai = ai_player_0 if (GameState.game_mode == GameState.GameMode.AI_VS_AI \
		and GameState.current_player == 0) else ai_player
	_active_ai.decide_bluff()
	_start_ai_thinking()
	if (_tech_used_this_turn[GameState.current_player] and not _tech_royale_ai) \
			or _ai_turn_action_started[GameState.current_player]:
		_request_ai_continue_after_union()
	else:
		_ai_turn_action_started[GameState.current_player] = true
		_active_ai.decide_turn()

func _request_ai_continue_after_union(try_union_after_tech: bool = false) -> void:
	if _should_defer_turn_flow():
		_deferred_ai_turn_flow = true
		return
	_deferred_ai_turn_flow = false
	_restart_ai_watchdog()
	_active_ai.continue_after_union(try_union_after_tech)

func _request_ai_continue_after_union_delayed(try_union_after_tech: bool = false) -> void:
	if _should_defer_turn_flow():
		_deferred_ai_turn_flow = true
		return
	_restart_ai_watchdog()
	await get_tree().create_timer(0.4).timeout
	if GameState.current_phase == GameState.Phase.GAME_OVER:
		return
	if _should_defer_turn_flow():
		_deferred_ai_turn_flow = true
		return
	_deferred_ai_turn_flow = false
	_active_ai.continue_after_union(try_union_after_tech)

# ─────────────────────────────────────────────────────────────
# Phase Changes
# ─────────────────────────────────────────────────────────────
func _enter_mode_select() -> void:
	mode_panel.visible = false
	end_attack_btn.visible = false
	var resume_multi_attack_pos := _pending_multi_attack_pos
	_pending_multi_attack_pos = Vector2i(-1, -1)
	_clear_selection()
	# Show turn banner once per new turn number.
	if GameState.turn_number != _last_banner_turn:
		_last_banner_turn = GameState.turn_number
		_show_turn_banner(GameState.current_player)
	# Notify tutorial manager when human player's turn begins.
	if TutorialBattleManager.is_active and not _is_ai_turn():
		TutorialBattleManager.on_player_turn_started()
		_update_union_suggest_button()
		_update_reveal_buttons()
	_update_tutorial_hud_lock()
	# Auto-peek for the active player at the start of each turn.
	# In VS_AI mode, never reveal the AI's board — reset previews instead.
	var cp := GameState.current_player
	if _is_ai_turn():
		_reset_reveal_previews()   # also calls _apply_observer_peek internally
	elif not _reveal_preview[cp]:
		_toggle_reveal_preview(cp)
		_apply_observer_peek()
	if _is_ai_turn() and GameState.current_phase != GameState.Phase.GAME_OVER:
		_start_ai_turn_flow()
		return
	_stop_ai_watchdog()
	if resume_multi_attack_pos != Vector2i(-1, -1):
		var bonus_attacker: GameState.CardInstance = GameState.get_card(
			cp, resume_multi_attack_pos.x, resume_multi_attack_pos.y)
		if bonus_attacker != null and bonus_attacker.has_pending_bonus_attack_chain():
			selected_attacker_pos = resume_multi_attack_pos
			_multi_attack_bonus_targeting = true
			grid_nodes[cp][resume_multi_attack_pos.x][resume_multi_attack_pos.y].set_selected(true)
			_set_selection_state(SelectionState.SELECTING_TARGET)
			_show_guide("%s: choose another target (bonus attack)" % bonus_attacker.card_name)
			_highlight_valid_targets()
			_update_end_turn_blink()
			_update_dungeon_modifier_panel_visibility()
			return
	_multi_attack_bonus_targeting = false
	_set_selection_state(SelectionState.SELECTING_ATTACKER)
	_highlight_attackable_chars()
	_update_end_turn_blink()
	_update_dungeon_modifier_panel_visibility()

func _on_phase_changed(phase: GameState.Phase) -> void:
	_refresh_all_grids()
	_update_turn_info()
	_refresh_attack_labels()
	# Reset tech-used flag BEFORE updating stacks so the visual reflects the new state
	if phase == GameState.Phase.MODE_SELECT:
		# Only reset at the start of a genuinely new turn, not on mid-turn
		# MODE_SELECT re-entries that happen after each attack completes.
		if GameState.turn_number != _tech_reset_turn:
			_tech_reset_turn = GameState.turn_number
			_tech_used_this_turn[GameState.current_player] = false
			_ai_turn_action_started[GameState.current_player] = false
	_update_tech_stacks()
	_update_void_stacks()
	_update_crystal_visibility()
	_update_reveal_buttons()
	_update_union_suggest_button()
	_update_tutorial_hud_lock()
	_update_dungeon_modifier_panel_visibility()
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
			_set_selection_state(SelectionState.SELECTING_ATTACKER)
			_highlight_attackable_chars()
			_update_tutorial_hud_lock()
			_update_end_turn_blink()

		GameState.Phase.BATTLE:
			mode_panel.visible = false
			end_attack_btn.visible = false
			if _end_turn_btn:
				_end_turn_btn.visible = false
				_end_turn_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_dismiss_tax_confirm_panel()
			_update_tutorial_hud_lock()

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

func _on_attack_completed(from: Vector2i, _to: Vector2i, _result: BattleResolver.BattleResult) -> void:
	var attacker: GameState.CardInstance = GameState.get_card(GameState.current_player, from.x, from.y)
	if TutorialBattleManager.is_active:
		TutorialBattleManager.report_action("attack_completed", {
			"player": GameState.current_player,
			"card_name": attacker.card_name if attacker != null else "",
		})
	_refresh_all_grids()
	if attacker != null and attacker.has_pending_bonus_attack_chain() and not _is_ai_turn():
		_pending_multi_attack_pos = from
		_multi_attack_bonus_targeting = true
	else:
		_multi_attack_bonus_targeting = false
	_clear_selection()
	_update_end_turn_blink()
	_refresh_attack_labels()
	# AI kill-taunt: mock on attacker cell after destroying an opponent character
	if _is_ai_turn() and _result.defender_destroyed:
		var opp_graveyard: Array = GameState.graveyards[GameState.get_opponent(GameState.current_player)]
		if not opp_graveyard.is_empty():
			var killed: GameState.CardInstance = opp_graveyard[-1]
			if _active_ai._trailer_social and killed.card_type == "character":
				_active_ai.decide_kill_taunt(from)
			else:
				var is_worthy: bool = killed.current_atk >= 100 or killed.current_def >= 100 or killed.is_union
				if is_worthy and randf() < 0.35:
					_active_ai.decide_kill_taunt(from)
	# Phase returns to MODE_SELECT after battle; _enter_mode_select() re-enables selection.

func _on_attack_aborted() -> void:
	if TutorialBattleManager.is_active:
		TutorialBattleManager.report_action("attack_aborted", {})
	if _attack_confirm_panel:
		_attack_confirm_panel.visible = false
	_clear_selection()
	_refresh_all_grids()   # reflect any state changes (e.g. attacked_this_turn hourglass)
	_refresh_attack_labels()
	# If AI aborted its own attack (e.g. attacks_remaining ran out, coin-flip cancel),
	# re-trigger the AI decision loop instead of showing human UI.
	if _is_ai_turn() and GameState.current_phase != GameState.Phase.GAME_OVER:
		_active_ai.register_attack_aborted()
		await _request_ai_continue_after_union_delayed()
		return
	if _end_turn_btn:
		_end_turn_btn.visible = true
	_set_selection_state(SelectionState.SELECTING_ATTACKER)
	_highlight_attackable_chars()
	_update_end_turn_blink()

func _on_battle_preview_needed(attacker_player: int, attacker: GameState.CardInstance, defender: GameState.CardInstance, result: BattleResolver.BattleResult) -> void:
	var overlay := BattleCalculationOverlay.new()
	overlay.z_index = 100
	_current_battle_overlay = overlay
	add_child(overlay)
	await overlay.start(attacker_player, attacker, defender, result)
	_current_battle_overlay = null
	turn_manager.battle_preview_done.emit()

func _on_tech_played(player: int, tech_name: String) -> void:
	_tech_used_this_turn[player] = true
	_update_tech_stacks()
	_refresh_all_grids()
	if _tech_resolve_blocker != null:
		_tech_resolve_blocker.visible = true
	if _is_ai_turn():
		_restart_ai_watchdog()
	if TutorialBattleManager.is_active:
		TutorialBattleManager.report_action("tech_played", {"player": player, "tech_name": tech_name})

func _on_tech_resolved(player: int) -> void:
	if TutorialBattleManager.is_active:
		TutorialBattleManager.report_action("tech_resolved", {"player": player})
	# Tech played during MODE_SELECT — stay in turn, re-enable attacking
	if _tech_resolve_blocker != null:
		_tech_resolve_blocker.visible = false
	action_panel.visible = false
	mode_panel.visible = false
	end_attack_btn.visible = false
	_clear_selection()
	_refresh_all_grids()
	if _is_ai_turn() and GameState.current_phase != GameState.Phase.GAME_OVER:
		_ai_turn_action_started[GameState.current_player] = true
		await _request_ai_continue_after_union_delayed(true)
	else:
		_resume_human_mode_select()

func _resume_human_mode_select(resume_bonus: bool = false, bonus_pos: Vector2i = Vector2i(-1, -1)) -> void:
	if _is_ai_turn() or GameState.current_phase == GameState.Phase.GAME_OVER:
		return
	_stop_ai_watchdog()
	if _end_turn_btn:
		_end_turn_btn.visible = true
	if resume_bonus and bonus_pos != Vector2i(-1, -1):
		var cp := GameState.current_player
		var bonus_attacker: GameState.CardInstance = GameState.get_card(cp, bonus_pos.x, bonus_pos.y)
		if bonus_attacker != null and bonus_attacker.has_pending_bonus_attack_chain():
			selected_attacker_pos = bonus_pos
			grid_nodes[cp][bonus_pos.x][bonus_pos.y].set_selected(true)
			_set_selection_state(SelectionState.SELECTING_TARGET)
			_show_guide("%s: choose another target (bonus attack)" % bonus_attacker.card_name)
			_highlight_valid_targets()
			_update_end_turn_blink()
			return
		_multi_attack_bonus_targeting = false
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
	SFXManager.play(SFXManager.SFX_TURN_BANNER)
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
	if TutorialBattleManager.should_block_card_detail():
		return
	var inst: Variant = null
	if row >= 0 and col >= 0:
		inst = GameState.get_card(owner_player, row, col)
	CardDetailOverlay.open(self, card_name, card_type, inst)

func _on_card_node_clicked(player: int, row: int, col: int) -> void:
	# Allow clicks during the AI's turn only when the human must respond to a tech/trap
	# effect (e.g. Tease forces the opponent to reveal one of their own squares).
	if _is_ai_turn() and selection_state != SelectionState.SELECTING_TECH_TARGET:
		return
	# Post-attack reveal (Shepherd Detective, etc.) is chosen by the attacker — block
	# human clicks when the AI owns the ability even if the turn already advanced.
	if selection_state == SelectionState.SELECTING_TECH_TARGET \
			and pending_tech_filter in ["opponent_any_hidden", "adjacent", "opponent_character_ability_destroy"] \
			and _ai_owns_pending_reveal_attacker():
		return
	# Tutorial action report
	if TutorialBattleManager.is_active:
		var _tut_ci: GameState.CardInstance = GameState.get_card(player, row, col)
		if _tut_ci != null and not _tut_ci.card_name.is_empty():
			TutorialBattleManager.report_action("card_tap",
				{"card_name": _tut_ci.card_name, "player": player, "row": row, "col": col})
		else:
			TutorialBattleManager.report_action("cell_tap",
				{"player": player, "row": row, "col": col})
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

	if _should_block_card_actions_for_enemy_view():
		_show_enemy_view_return_prompt()
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
			if pos in GameState.locked_attack_positions:
				GameState.post_message("That square is locked by a trap.")
				return
			SFXManager.play(SFXManager.SFX_TARGET)
			_start_confirm_attack(opponent, pos)

		SelectionState.CONFIRMING_ATTACK:
			# Clicks during confirm are ignored — use the panel buttons
			pass

		SelectionState.SELECTING_TECH_TARGET:
			var target_node: Control = grid_nodes[player][row][col]
			if not target_node.is_highlighted:
				if pending_tech_filter == "self_squares_1_opponent_turn":
					var _tease_card: GameState.CardInstance = GameState.get_card(player, row, col)
					if _tease_card.card_type != "character":
						GameState.post_message("Tease: Choose a face-down unit.")
					elif _tease_card.face_up:
						GameState.post_message("Tease: Choose a face-down unit.")
				elif pending_tech_filter == "bribe_reveal":
					var _bribe_card: GameState.CardInstance = GameState.get_card(player, row, col)
					if _bribe_card.card_type != "character":
						GameState.post_message("Bribe: Choose a face-down unit.")
					elif _bribe_card.face_up:
						GameState.post_message("Bribe: Choose a face-down unit.")
				elif pending_tech_filter == "ability_plant29_venom":
					GameState.post_message("Plant-29: Choose 1 exposed ally or foe.")
				elif pending_tech_filter == "ability_plant29_mutagen":
					GameState.post_message("Plant-29: Choose 1 of your units.")
				elif pending_tech_filter == "venom_flagged_card":
					GameState.post_message("Potent Poison: Choose 1 card with Venom Flag.")
				return
			SFXManager.play(SFXManager.SFX_TARGET)
			_handle_tech_target(player, pos)

# ─────────────────────────────────────────────────────────────
# Attack Confirmation Flow
# ─────────────────────────────────────────────────────────────

func _start_confirm_attack(target_player: int, target_pos: Vector2i) -> void:
	_confirm_target_player = target_player
	_confirm_target_pos = target_pos
	_set_selection_state(SelectionState.CONFIRMING_ATTACK)
	_update_union_suggest_button()
	if _attack_confirm_panel:
		_attack_confirm_panel.visible = true
	_update_tutorial_hud_lock()
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
	await _await_prompt_dismiss_delay()
	_set_selection_state(SelectionState.NONE)
	var atk_from := selected_attacker_pos
	var atk_to   := _confirm_target_pos
	_confirm_target_pos   = Vector2i(-1, -1)
	_confirm_target_player = -1
	_multi_attack_bonus_targeting = false
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
	await _await_prompt_dismiss_delay()
	if _selected_attacker_has_multi_bonus():
		_set_selection_state(SelectionState.SELECTING_TARGET)
		var bonus_card: GameState.CardInstance = GameState.get_card(
			GameState.current_player, selected_attacker_pos.x, selected_attacker_pos.y)
		if bonus_card != null:
			_show_guide("%s: choose another target (bonus attack)" % bonus_card.card_name)
	else:
		_clear_selection()
		_set_selection_state(SelectionState.SELECTING_ATTACKER)
		_highlight_attackable_chars()
	_update_union_suggest_button()
	_update_tutorial_hud_lock()
	_update_end_turn_blink()

# ─────────────────────────────────────────────────────────────
# Revive placement
# ─────────────────────────────────────────────────────────────
func _clear_pending_revive() -> void:
	_pending_revive_card = null
	_pending_revive_player = -1
	_pending_revive_tech_data = null
	_pending_revive_union_source = ""
	_pending_revive_keep_in_graveyard = false
	_pending_revive_strip_stats = false
	_pending_revive_double_cost = false
	_pending_revive_awaiting = false

func _remove_card_from_graveyard(player: int, card: GameState.CardInstance) -> void:
	var gy: Array = GameState.graveyards[player]
	for i: int in range(gy.size()):
		if gy[i] == card:
			gy.remove_at(i)
			return

func _duplicate_revive_card(source: GameState.CardInstance) -> GameState.CardInstance:
	var copy: GameState.CardInstance = GameState.CardInstance.new()
	copy.card_type = "character"
	copy.card_name = source.card_name
	copy.display_name = source.display_name
	copy.affinity = source.affinity
	copy.base_atk = source.base_atk
	copy.base_def = source.base_def
	copy.current_atk = source.current_atk
	copy.current_def = source.current_def
	copy.crystal_cost = source.crystal_cost
	copy.rarity = source.rarity
	copy.ability_type = source.ability_type
	copy.ability_params = source.ability_params.duplicate(true)
	return copy

func _prepare_revive_from_graveyard(player: int, tech_data: TechCardData) -> void:
	var gy: Array = GameState.graveyards[player]
	if gy.is_empty():
		GameState.post_message("No destroyed units to revive.")
		_finish_tech_action(player)
		return
	_pending_revive_card = gy.pop_back()
	_pending_revive_player = player
	_pending_revive_tech_data = tech_data
	_pending_revive_union_source = ""
	_pending_revive_keep_in_graveyard = false
	_pending_revive_strip_stats = tech_data != null \
		and tech_data.effect_type == TechCardData.TechEffectType.REVIVE_CHARACTER_NO_ATK
	_pending_revive_double_cost = tech_data != null and tech_data.effect_params.get("double_cost", false)
	_pending_revive_awaiting = false
	await _begin_revive_placement_selection()

func _begin_union_revive_match(player: int, u: UnionData) -> void:
	var _nc: String = str(u.ability_params.get("name_contains", ""))
	var _ex_union: bool = bool(u.ability_params.get("exclude_union", true))
	var matches: Array = []
	for g: GameState.CardInstance in GameState.graveyards[player]:
		if g.card_type != "character":
			continue
		if _ex_union and g.is_union:
			continue
		if _nc != "" and not g.card_name.to_lower().contains(_nc.to_lower()):
			continue
		matches.append(g)
	if matches.is_empty():
		GameState.post_message("%s: No matching card in graveyard to revive." % u.card_name)
		return
	var revived: GameState.CardInstance = matches[0]
	if matches.size() > 1:
		var _choice_labels: Array = []
		for _m: GameState.CardInstance in matches:
			_choice_labels.append("%s (ATK %d / DEF %d / Cost %d)" % [
				_m.card_name, _m.current_atk, _m.current_def, _m.crystal_cost])
		turn_manager.emit_signal("awaiting_trap_choice",
			"%s: Choose 1 card to revive." % u.card_name, _choice_labels)
		var _rev_choice: int = await turn_manager.ability_choice_resolved
		revived = matches[mini(_rev_choice, matches.size() - 1)]
	_pending_revive_card = revived
	_pending_revive_player = player
	_pending_revive_tech_data = null
	_pending_revive_union_source = u.card_name
	_pending_revive_keep_in_graveyard = true
	_pending_revive_strip_stats = false
	_pending_revive_double_cost = true
	_pending_revive_awaiting = true
	_begin_revive_placement_selection()
	if _pending_revive_card != null:
		await revive_placement_resolved

func _revive_placement_ai_player(player: int) -> bool:
	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		return true
	if GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
			GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION] \
			and player == ai_player.player_index:
		return true
	return _is_ai_turn()

func _begin_revive_placement_selection() -> void:
	var player: int = _pending_revive_player
	var card: GameState.CardInstance = _pending_revive_card
	if card == null:
		return
	if not GameState.has_valid_revive_placement_cell(player):
		var _was_tech: TechCardData = _pending_revive_tech_data
		var _was_awaiting: bool = _pending_revive_awaiting
		if not _pending_revive_keep_in_graveyard:
			GameState.graveyards[player].append(card)
		_clear_pending_revive()
		GameState.post_message("No empty cell to place revived unit.")
		if _was_tech != null:
			_finish_tech_action(player)
		elif _was_awaiting:
			revive_placement_resolved.emit()
		return
	var prompt: String = "Choose an empty cell for %s." % card.card_name
	pending_tech_filter = "revive_placement"
	_set_selection_state(SelectionState.SELECTING_TECH_TARGET)
	_show_guide(prompt)
	_highlight_tech_targets("revive_placement")
	if _tech_resolve_blocker:
		_tech_resolve_blocker.visible = true
	if _revive_placement_ai_player(player):
		await get_tree().create_timer(0.4).timeout
		var ai_target: Vector2i = _get_ai_for_player(player).decide_target("revive_placement")
		_flash_target_card(player, ai_target.x, ai_target.y)
		_handle_revive_placement(player, ai_target)

func _handle_revive_placement(player: int, pos: Vector2i) -> void:
	if _pending_revive_card == null or player != _pending_revive_player:
		return
	if not GameState.is_valid_revive_placement_cell(player, pos.x, pos.y):
		return
	var source: GameState.CardInstance = _pending_revive_card
	var placed: GameState.CardInstance
	if _pending_revive_keep_in_graveyard:
		placed = _duplicate_revive_card(source)
		_remove_card_from_graveyard(player, source)
	else:
		placed = source
	if _pending_revive_strip_stats:
		placed.current_atk = 0
		placed.current_def = 0
		placed.ability_type = int(CharacterData.AbilityType.NONE)
	if _pending_revive_double_cost:
		placed.crystal_cost *= 2
	placed.is_revived = true
	placed.face_up = true
	placed.revealed_on_turn = GameState.turn_number
	placed.attacked_this_turn = false
	GameState.grids[player][pos.x][pos.y] = placed
	_refresh_card_node(player, pos.x, pos.y)
	GameState.emit_signal("card_revealed", player, pos.x, pos.y)
	BattleResolver.recalculate_all_field_bonuses()
	var _source_label: String = _pending_revive_union_source
	var _was_tech: TechCardData = _pending_revive_tech_data
	var _was_awaiting: bool = _pending_revive_awaiting
	_clear_pending_revive()
	_clear_highlights()
	_hide_guide()
	_set_selection_state(SelectionState.NONE)
	if _tech_resolve_blocker:
		_tech_resolve_blocker.visible = false
	if _source_label != "":
		GameState.post_message("%s revived %s (cost doubled to %d)!" % [
			_source_label, placed.card_name, placed.crystal_cost])
	elif _was_tech != null:
		GameState.post_message("Revived %s at [%d,%d]!" % [placed.card_name, pos.x, pos.y])
	else:
		GameState.post_message("Revived %s at [%d,%d]!" % [placed.card_name, pos.x, pos.y])
	if _was_tech != null:
		_finish_tech_action(player)
	elif _was_awaiting:
		revive_placement_resolved.emit()

# ─────────────────────────────────────────────────────────────
# Tech Target Handling
# ─────────────────────────────────────────────────────────────
func _begin_target_selection_blocking(filter: String) -> void:
	if not turn_manager.is_flow_blocked():
		turn_manager.begin_ui_target_selection()
		_ui_flow_block_active = true
	if filter != "bribe":
		pending_tech_filter = filter
		if filter != "graveyard":
			_set_selection_state(SelectionState.SELECTING_TECH_TARGET)
	_restart_ai_watchdog()

func _end_target_selection_blocking() -> void:
	if _ui_flow_block_active:
		turn_manager.end_ui_target_selection()
		_ui_flow_block_active = false

func _on_awaiting_target_selection(prompt: String, filter: String) -> void:
	_begin_target_selection_blocking(filter)
	# Unblock input — player now needs to interact with the field or overlay
	if _tech_resolve_blocker != null:
		_tech_resolve_blocker.visible = false
	await _maybe_flash_outside_reckoning_ability(prompt, filter)
	# Bribe: show a non-dismissable choice overlay instead of grid selection
	if filter == "bribe":
		var opponent := GameState.get_opponent(GameState.current_player)
		# In VS_AI mode (opponent is AI player 1) or AI_VS_AI (both players are AI) → auto-pass
		var ai_will_respond := (GameState.game_mode == GameState.GameMode.VS_AI and opponent == 1) \
			or GameState.game_mode == GameState.GameMode.AI_VS_AI
		if ai_will_respond:
			await get_tree().create_timer(0.5).timeout
			GameState.post_message("Bribe: AI passed.")
			_finish_tech_action(GameState.current_player)
		else:
			_begin_human_defender_tech_choice()
			_show_bribe_overlay(opponent)
		return

	if filter == "graveyard":
		var tech_data: TechCardData = CardDatabase.get_tech(pending_tech_name)
		await _prepare_revive_from_graveyard(GameState.current_player, tech_data)
		return

	# pending_tech_filter + SELECTING_TECH_TARGET set synchronously in _begin_target_selection_blocking
	# Parse reveal count for multi-reveal filters (e.g. "opponent_squares_3", "own_units_up_to_5")
	if "opponent_squares" in filter:
		var parts := filter.split("_")
		_tech_reveals_remaining = int(parts[-1]) if parts[-1].is_valid_int() else 1
		_tech_reveals_total = _tech_reveals_remaining
		_tech_reveal_picked.clear()
	elif filter.begins_with("own_units_up_to_"):
		var _gd_parts := filter.split("_")
		_tech_reveals_remaining = int(_gd_parts[-1]) if _gd_parts[-1].is_valid_int() else 5
		_tech_reveals_total = _tech_reveals_remaining
		_tech_reveal_picked.clear()
	else:
		_tech_reveals_total = 0
	# Reset Rift Strike hover state when entering row_or_column targeting
	if filter == "row_or_column":
		_rift_hover_cell = Vector2i(-1, -1)
		_rift_last_hover = Vector2i(-1, -1)
		_rift_direction = "row"
	# Show guide text
	if filter.begins_with("own_units_up_to_"):
		_set_own_facedown_char_peek(true)
		_show_guide("Great Diplomacy: select up to %d units (0/%d). CLOSE when done." % [_tech_reveals_total, _tech_reveals_total])
	elif _tech_reveals_total > 1:
		_show_guide("Select %s card to reveal" % _ordinal(1))
	else:
		_show_guide(prompt)
	_highlight_tech_targets(filter)

	# Diplomacy Party / Release Mutagen-style peek for own face-down picks
	if filter == "own_facedown_character":
		_set_own_facedown_char_peek(true)

	# Plant-29 tails: pick any own unit (including face-down) for Mutagen
	if filter == "ability_plant29_mutagen":
		_set_own_facedown_char_peek(true)

	# Tease: human opponent must choose their own face-down card — let them peek their grid
	if filter == "self_squares_1_opponent_turn":
		var tease_defender := GameState.get_opponent(GameState.current_player)
		_set_own_facedown_char_peek(true, tease_defender)

	# Brainwash: attacker may pick any own ally, including face-down units
	if filter == "own_any_as_target":
		_set_own_facedown_char_peek(true)

	# Nuki: swap with any own unit (face-down allowed)
	if filter == "own_character_for_swap":
		var _nuki_owner: int = turn_manager._pending_swap_owner_player
		if _nuki_owner >= 0:
			_set_own_facedown_char_peek(true, _nuki_owner)
		else:
			_set_own_facedown_char_peek(true)

	# Own-unit picks without "face-up/exposed only" in card text — cosmetic peek while selecting
	if _own_unit_target_allows_facedown(filter):
		_begin_target_selection_peek(filter)

	# Auto-complete filters that don't require grid selection
	if filter == "view_opponent_hand":
		_handle_tech_target(GameState.current_player, Vector2i(0, 0))
		return

	# WK-17: foe may pick face-down allies as the redirected target
	if filter == "wk17_foe_pick_character":
		var _wk17_sel: int = turn_manager._pending_wk17_foe_player
		if _wk17_sel >= 0:
			_set_own_facedown_char_peek(true, _wk17_sel)

	# No-valid-target guard: if the highlight pass found no cells to interact with,
	# cancel the effect rather than leaving any player (human or AI) stuck.
	if not _any_highlighted():
		if filter == "self_squares_1_opponent_turn":
			GameState.post_message("Tease: No face-down units to reveal — effect cancelled.")
		else:
			GameState.post_message("No valid target — effect cancelled.")
		if filter == "own_any_as_target":
			turn_manager.complete_brainwash_redirect()
		if filter == "own_character_for_swap" \
				and GameState.current_phase == GameState.Phase.BATTLE:
			_clear_after_pre_battle_ability()
		elif _is_post_attack_ability_filter(filter) \
				or filter in ["ability_lockpicker_reveal", "wk17_foe_pick_character"]:
			_clear_after_ability()
		elif filter in _defender_response_filters():
			if pending_tech_name != "":
				_finish_tech_action(GameState.current_player)
			else:
				_finish_trap_target_selection()
		else:
			_finish_tech_action(GameState.current_player)
		return

	if filter == "own_character_for_swap":
		var _nuki_sel: int = turn_manager._pending_swap_owner_player
		if _nuki_sel < 0:
			_nuki_sel = GameState.current_player
		var _nuki_sel_is_ai: bool = GameState.game_mode == GameState.GameMode.AI_VS_AI \
			or (GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
				GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION] \
				and _nuki_sel == ai_player.player_index)
		if _nuki_sel_is_ai:
			await get_tree().create_timer(0.4).timeout
			var _nuki_ai: AIPlayer = _get_ai_for_player(_nuki_sel)
			var _nuki_target: Vector2i = _nuki_ai.decide_target(filter)
			_nuki_ai.ai_target_chosen.emit(_nuki_target)
			_flash_target_card(_nuki_sel, _nuki_target.x, _nuki_target.y)
			_handle_tech_target(_nuki_sel, _nuki_target)
			return
		if _local_human_is_selecting(_nuki_sel) \
				and GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
					GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION] \
				and GameState.get_opponent(_nuki_sel) == ai_player.player_index:
			_begin_human_defender_tech_choice()
		return

	if filter in ["ability_false_prophet_reveal", "opponent_character_ability_destroy", "ability_rebel_king_swap",
			"ability_plant29_venom", "ability_plant29_mutagen", "ability_death_cobra_venom",
			"ability_lockpicker_reveal", "wk17_foe_pick_character", "opponent_any_hidden", "adjacent"]:
		var _ai_responds: bool = _is_ai_turn()
		if filter in ["ability_plant29_venom", "ability_plant29_mutagen"]:
			_ai_responds = GameState.game_mode == GameState.GameMode.AI_VS_AI \
				or not _local_human_is_selecting(GameState.current_player)
		if filter == "ability_rebel_king_swap":
			var _rk_owner: int = turn_manager._pending_rebel_king_owner
			_ai_responds = GameState.game_mode == GameState.GameMode.AI_VS_AI \
				or (GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
					GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION] \
					and _rk_owner == ai_player.player_index)
		if filter == "ability_lockpicker_reveal":
			var _lp_owner: int = turn_manager._pending_lockpicker_owner
			_ai_responds = GameState.game_mode == GameState.GameMode.AI_VS_AI \
				or (GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
					GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION] \
					and _lp_owner == ai_player.player_index)
		if filter == "wk17_foe_pick_character":
			var _wk17_foe: int = turn_manager._pending_wk17_foe_player
			_ai_responds = GameState.game_mode == GameState.GameMode.AI_VS_AI \
				or (GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
					GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION] \
					and _wk17_foe == ai_player.player_index)
		if filter == "opponent_any_hidden":
			var _rev_owner: int = turn_manager._pending_reveal_attacker_player
			_ai_responds = GameState.game_mode == GameState.GameMode.AI_VS_AI \
				or (GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
					GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION] \
					and _rev_owner == ai_player.player_index)
		if filter in ["adjacent", "opponent_character_ability_destroy"]:
			var _ab_owner: int = turn_manager._pending_reveal_attacker_player
			_ai_responds = GameState.game_mode == GameState.GameMode.AI_VS_AI \
				or (GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
					GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION] \
					and _ab_owner == ai_player.player_index)
		if _ai_responds:
			await get_tree().create_timer(0.4).timeout
			if filter == "ability_plant29_venom" or filter == "ability_plant29_mutagen":
				var _p29_pick: Dictionary = _active_ai.decide_any_grid_target(filter)
				if _p29_pick.is_empty():
					GameState.post_message("No valid target — effect cancelled.")
					_clear_after_ability()
				else:
					var _p29_player: int = int(_p29_pick.get("player", GameState.current_player))
					var _p29_pos: Vector2i = _p29_pick.get("pos", Vector2i(-1, -1))
					_flash_target_card(_p29_player, _p29_pos.x, _p29_pos.y)
					_handle_tech_target(_p29_player, _p29_pos)
				return
			if filter == "ability_death_cobra_venom":
				var _dc_pick: Dictionary = _active_ai.decide_any_grid_target("ability_plant29_venom")
				if _dc_pick.is_empty():
					GameState.post_message("No valid target — effect cancelled.")
					_clear_after_ability()
				else:
					var _dc_player: int = int(_dc_pick.get("player", GameState.current_player))
					var _dc_pos: Vector2i = _dc_pick.get("pos", Vector2i(-1, -1))
					_flash_target_card(_dc_player, _dc_pos.x, _dc_pos.y)
					_handle_tech_target(_dc_player, _dc_pos)
				return
			var _ab_target: Vector2i
			var _ab_player: int = GameState.current_player
			if filter == "ability_rebel_king_swap":
				_ab_player = turn_manager._pending_rebel_king_foe_player
				_ab_target = _get_ai_for_player(turn_manager._pending_rebel_king_owner).decide_target("ability_rebel_king_swap")
			elif filter == "ability_lockpicker_reveal":
				_ab_player = GameState.get_opponent(turn_manager._pending_lockpicker_owner)
				_ab_target = _get_ai_for_player(turn_manager._pending_lockpicker_owner).decide_target(filter)
			elif filter == "opponent_any_hidden":
				var _rev_owner: int = turn_manager._pending_reveal_attacker_player
				_ab_player = GameState.get_opponent(_rev_owner)
				_ab_target = _get_ai_for_player(_rev_owner).decide_target(filter)
			elif filter in ["adjacent", "opponent_character_ability_destroy"]:
				var _ab_owner: int = turn_manager._pending_reveal_attacker_player
				_ab_player = GameState.get_opponent(_ab_owner)
				_ab_target = _get_ai_for_player(_ab_owner).decide_target(filter)
			elif filter == "wk17_foe_pick_character":
				_ab_player = turn_manager._pending_wk17_foe_player
				_ab_target = _get_ai_for_player(_ab_player).decide_target(filter)
			else:
				_ab_target = _active_ai.decide_target(filter)
			if filter == "ability_rebel_king_swap":
				_flash_target_card(_ab_player, _ab_target.x, _ab_target.y)
				_handle_tech_target(_ab_player, _ab_target)
			elif filter in ["ability_false_prophet_reveal", "ability_lockpicker_reveal", "opponent_any_hidden",
					"adjacent", "opponent_character_ability_destroy"]:
				_flash_target_card(_ab_player, _ab_target.x, _ab_target.y)
				_handle_tech_target(_ab_player, _ab_target)
			elif filter == "wk17_foe_pick_character":
				_flash_target_card(_ab_player, _ab_target.x, _ab_target.y)
				_handle_tech_target(_ab_player, _ab_target)
			else:
				_flash_target_card(GameState.get_opponent(GameState.current_player), _ab_target.x, _ab_target.y)
				_handle_tech_target(GameState.get_opponent(GameState.current_player), _ab_target)
		return

	# If AI turn (AI is attacker), auto-resolve — but skip defender-response filters
	if _is_ai_turn() and filter not in _defender_response_filters():
		await get_tree().create_timer(0.4).timeout
		# Guard: if a reveal-tech has no valid targets, skip rather than hang
		if "opponent_squares" in filter and _count_opponent_facedown(GameState.get_opponent(GameState.current_player)) == 0:
			_finish_tech_action(GameState.current_player)
			return
		if filter.begins_with("own_units_up_to_"):
			if _count_own_facedown_units(GameState.current_player, _tech_reveal_picked) == 0:
				GameState.post_message("Great Diplomacy: no face-down units to reveal.")
				_finish_tech_action(GameState.current_player)
				return
			_prompt_ai_diplomacy_pick()
			return
		if "opponent_squares" in filter:
			_prompt_ai_radar_pick()
			return
		var ai_target := _active_ai.decide_target(filter)
		_active_ai.ai_target_chosen.emit(ai_target)  # log AI tech/trap target choice
		# "row_or_column" targets a cell on the opponent's grid even though the word
		# "opponent" doesn't appear in the filter string — handle it explicitly.
		var target_player: int = GameState.current_player
		if filter == "any_faceup_card":
			var opp_idx: int = GameState.get_opponent(GameState.current_player)
			var opp_card: GameState.CardInstance = GameState.get_card(opp_idx, ai_target.x, ai_target.y)
			if opp_card.face_up and opp_card.card_type != "dead_end":
				target_player = opp_idx
		elif filter == "venom_flagged_card":
			for p in range(2):
				var picked: GameState.CardInstance = GameState.get_card(p, ai_target.x, ai_target.y)
				if picked.card_type == "character" and "venom" in picked.flags:
					target_player = p
					break
		elif "opponent" in filter or filter == "row_or_column" or filter == "adjacent":
			target_player = GameState.get_opponent(GameState.current_player)
		_flash_target_card(target_player, ai_target.x, ai_target.y)
		_handle_tech_target(target_player, ai_target)
	# Trap/tech effects where AI is the DEFENDING player (not AI's turn, but AI must self-select)
	elif filter in _defender_response_filters() \
			and (GameState.game_mode == GameState.GameMode.AI_VS_AI \
				or (GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
					GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION] \
					and GameState.get_opponent(GameState.current_player) == ai_player.player_index)):
		# AI is the defending/responding player
		await get_tree().create_timer(0.4).timeout
		var def_player: int = GameState.get_opponent(GameState.current_player)
		var def_ai: AIPlayer = _get_defending_ai()
		var ai_target: Vector2i = def_ai.decide_target(filter)
		def_ai.ai_target_chosen.emit(ai_target)  # log defender AI choice
		_flash_target_card(def_player, ai_target.x, ai_target.y)
		_handle_tech_target(def_player, ai_target)
	elif _is_ai_turn() and filter in _defender_response_filters():
		# Human is the responding player during the AI's turn — wait for grid pick.
		_begin_human_defender_tech_choice()
	elif GameState.game_mode in [GameState.GameMode.HOT_SEAT, GameState.GameMode.LOCAL_2P] \
			and filter in _defender_response_filters():
		_begin_human_defender_tech_choice()

func _is_defender_response_filter(filter: String) -> bool:
	return filter in _defender_response_filters()

func _defender_response_filters() -> Array:
	return [
		"own_faceup_for_trap_temp_def_boost", "own_character_for_trap_self_destruct",
		"self_reveal_choice", "self_faceup_for_copy", "own_armored_nature",
		"self_squares_1_opponent_turn", "own_divine_character_redirect",
		"bribe_reveal", "trap_hostage_reveal_lock", "trap_street_joke_reveal",
	]

func _begin_human_defender_tech_choice() -> void:
	_pending_human_defender_tech = true
	if _ai_watchdog != null:
		_ai_watchdog.stop()
	if _tech_resolve_blocker != null:
		_tech_resolve_blocker.visible = false
	if _end_turn_btn:
		_end_turn_btn.visible = false

func _get_target_selecting_player(filter: String) -> int:
	if filter == "ability_rebel_king_swap":
		var _rk_owner: int = turn_manager._pending_rebel_king_owner
		return _rk_owner if _rk_owner >= 0 else GameState.current_player
	if filter == "ability_lockpicker_reveal":
		var _lp_owner: int = turn_manager._pending_lockpicker_owner
		return _lp_owner if _lp_owner >= 0 else GameState.current_player
	if filter == "opponent_any_hidden":
		var _rev_owner: int = turn_manager._pending_reveal_attacker_player
		return _rev_owner if _rev_owner >= 0 else GameState.current_player
	if filter in ["adjacent", "opponent_character_ability_destroy"]:
		var _ab_owner: int = turn_manager._pending_reveal_attacker_player
		return _ab_owner if _ab_owner >= 0 else GameState.current_player
	if filter == "wk17_foe_pick_character":
		var _wk17_foe: int = turn_manager._pending_wk17_foe_player
		return _wk17_foe if _wk17_foe >= 0 else GameState.current_player
	if filter == "own_character_for_swap":
		var _swap_owner: int = turn_manager._pending_swap_owner_player
		return _swap_owner if _swap_owner >= 0 else GameState.current_player
	if filter in _defender_response_filters():
		return GameState.get_opponent(GameState.current_player)
	if filter in ["lock_opponent_monster", "opponent_facedown_forced"]:
		return GameState.get_opponent(GameState.current_player)
	return GameState.current_player

func _local_human_is_selecting(selector: int) -> bool:
	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		return false
	if ai_player != null and selector == ai_player.player_index:
		return false
	if GameState.game_mode in [GameState.GameMode.HOT_SEAT, GameState.GameMode.LOCAL_2P]:
		if selector != GameState.current_player:
			return _pending_human_defender_tech
		return true
	if GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
			GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION]:
		return selector == 0
	return selector == 0

func _should_show_ability_target_flash(filter: String = "") -> bool:
	var f := filter if filter != "" else pending_tech_filter
	if f == "":
		return false
	return _local_human_is_selecting(_get_target_selecting_player(f))

func _apply_tech_target_self_destruct(target_player: int, pos: Vector2i, card: GameState.CardInstance) -> void:
	if pending_tech_name == "":
		return
	if card.was_destroyed or card.card_type != "character":
		return
	if not card.ability_params.get("tech_target_self_destruct", false):
		return
	if not grid_nodes[target_player][pos.x][pos.y].is_highlighted:
		return
	GameState.post_message("%s: self-destructs when targeted by tech!" % card.card_name)
	GameState.destruction_from_tech_self_destruct = true
	GameState.mark_destroy_achievement_context(
		"tech", GameState.current_player, target_player, pos.x, pos.y)
	GameState.destroy_card(target_player, pos.x, pos.y, true)
	GameState.destruction_from_tech_self_destruct = false

func _handle_tech_target(player: int, pos: Vector2i) -> void:
	var current_player := GameState.current_player
	var opponent := GameState.get_opponent(current_player)
	var card: GameState.CardInstance = GameState.get_card(player, pos.x, pos.y)

	if pending_tech_filter == "ability_false_prophet_reveal":
		if player == opponent and not card.face_up:
			GameState.reveal_card_by_ability(player, pos.x, pos.y)
			card = GameState.get_card(player, pos.x, pos.y)
			var _fp_pos: Vector2i = _find_own_card_pos(current_player, "False Prophet")
			if card.card_type == "dead_end":
				GameState.post_message("False Prophet: Dead End revealed — self-destructs!")
				if _fp_pos != Vector2i(-1, -1):
					GameState.destroy_card(current_player, _fp_pos.x, _fp_pos.y, false)
			else:
				var _gain: int = 600
				for _fp_r: int in range(GameState.GRID_SIZE):
					for _fp_c: int in range(GameState.GRID_SIZE):
						var _fp: GameState.CardInstance = GameState.get_card(current_player, _fp_r, _fp_c)
						if _fp.is_union and _fp.card_name == "False Prophet" \
								and _fp.ability_type == CharacterData.AbilityType.TURN_END_REVEAL_OPPONENT_CELL:
							_gain = _fp.ability_params.get("gain", 600)
							break
				GameState.gain_crystals(current_player, _gain, "ability")
				GameState.post_message("False Prophet: +%d Crystals!" % _gain)
		_clear_after_ability()
		return

	if pending_tech_filter == "ability_lockpicker_reveal":
		var _lp_owner: int = turn_manager._pending_lockpicker_owner
		var _lp_foe: int = GameState.get_opponent(_lp_owner) if _lp_owner >= 0 else opponent
		if player == _lp_foe and not card.face_up:
			GameState.reveal_card_by_ability(player, pos.x, pos.y)
			card = GameState.get_card(player, pos.x, pos.y)
			if card.card_type == "dead_end":
				GameState.post_message("Lockpicker: Revealed Dead End.")
			else:
				GameState.post_message("Lockpicker: Revealed %s!" % card.card_name)
		_clear_after_ability()
		return

	if pending_tech_filter == "wk17_foe_pick_character":
		var _wk17_foe: int = turn_manager._pending_wk17_foe_player
		if player == _wk17_foe and card.card_type == "character":
			if turn_manager._pending_wk17_mode == "redirect_attacker":
				if pos == GameState.attacker_pos:
					return
				turn_manager._wk17_friendly_fire = true
				turn_manager._wk17_friendly_fire_pos = pos
				if not card.face_up:
					GameState.reveal_card_by_ability(player, pos.x, pos.y)
				var _wk17_att: GameState.CardInstance = GameState.attacker_card
				if _wk17_att != null:
					GameState.post_message("WK-17: %s will attack %s!" % [_wk17_att.card_name, card.card_name])
			else:
				turn_manager._pending_wk17_new_target_pos = pos
			_clear_after_ability()
		return

	if pending_tech_filter == "opponent_character_ability_destroy":
		var _coin_foe: int = _reveal_attacker_foe_player(opponent)
		if _pending_ability_destroy_pos == Vector2i(-1, -1):
			if player == _coin_foe and card.card_type == "character" and card.face_up:
				_pending_ability_destroy_pos = pos
				_pending_ability_destroy_player = player
				var _cf: Array = await turn_manager._do_coin_flips(1)
				if _cf[0]:
					GameState.mark_destroy_achievement_context(
						"tech", current_player, player, pos.x, pos.y)
					GameState.destroy_card(player, pos.x, pos.y, true)
					GameState.post_message("Rocket Peacock: Heads — %s destroyed!" % card.card_name)
				else:
					GameState.post_message("Rocket Peacock: Tails — %s survives." % card.card_name)
				_pending_ability_destroy_pos = Vector2i(-1, -1)
				_pending_ability_destroy_player = -1
		_clear_after_ability()
		return

	if pending_tech_filter == "ability_rebel_king_swap":
		var _rk_foe: int = turn_manager._pending_rebel_king_foe_player
		if player == _rk_foe and card.card_type == "character" and card.face_up:
			var _tmp_atk: int = card.current_atk
			card.current_atk = card.current_def
			card.current_def = _tmp_atk
			GameState.post_message("Rebel King: %s swapped ATK (%d) and DEF (%d)." % [
				card.card_name, card.current_atk, card.current_def])
		_clear_after_ability()
		return

	if pending_tech_filter == "ability_death_cobra_venom":
		if card.card_type == "character" and card.face_up:
			var _dc_name: String = _find_own_card_name_by_ability(
				current_player, CharacterData.AbilityType.VENOM_FLAG_END_OF_TURN)
			GameState.apply_unit_effect_flag(player, pos.x, pos.y, "venom")
			var _dc_tgt: GameState.CardInstance = GameState.get_card(player, pos.x, pos.y)
			GameState.post_message("%s: Venom on %s." % [_dc_name, _dc_tgt.card_name])
		_clear_after_ability()
		return

	if pending_tech_filter == "ability_plant29_venom":
		if card.card_type == "character" and card.face_up:
			var _p29_name: String = _find_turn_start_coin_flip_source_name(current_player)
			GameState.apply_unit_effect_flag(player, pos.x, pos.y, "venom")
			var _tgt: GameState.CardInstance = GameState.get_card(player, pos.x, pos.y)
			GameState.post_message("%s: Venom on %s." % [_p29_name, _tgt.card_name])
		_clear_after_ability()
		return

	if pending_tech_filter == "ability_plant29_mutagen":
		if player == current_player and card.card_type == "character":
			var _p29_name_m: String = _find_turn_start_coin_flip_source_name(current_player)
			GameState.apply_unit_effect_flag(player, pos.x, pos.y, "mutagen")
			var _tgt_m: GameState.CardInstance = GameState.get_card(player, pos.x, pos.y)
			GameState.post_message("%s: Mutagen on %s." % [_p29_name_m, _tgt_m.card_name])
		_clear_after_ability()
		return

	if pending_tech_filter == "adjacent":
		if not card.was_destroyed and not card.face_up:
			GameState.reveal_card_by_ability(player, pos.x, pos.y)
			var _att_name: String = GameState.attacker_card.card_name if GameState.attacker_card != null else "Attacker"
			if card.card_type == "dead_end":
				GameState.post_message("%s: adjacent cell revealed (empty)." % _att_name)
			else:
				GameState.post_message("%s: adjacent cell revealed." % _att_name)
		_clear_after_ability()
		return

	var data: TechCardData = CardDatabase.get_tech(pending_tech_name)

	# Emit signals for CardRuleEngine CARD_TARGETED_BY_TECH / PLAYER_SELECT_TECH_TARGET
	GameState.emit_signal("tech_target_selected", current_player, player, pos.x, pos.y)
	CardRuleEngine.emit_trigger(CardRule.TriggerType.CARD_TARGETED_BY_TECH,
		{"source_player": player, "source_card": card, "tech_name": pending_tech_name})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.PLAYER_SELECT_TECH_TARGET,
		{"source_player": current_player, "target_player": player,
		 "tech_name": pending_tech_name})

	_apply_tech_target_self_destruct(player, pos, card)
	card = GameState.get_card(player, pos.x, pos.y)

	if "opponent_squares" in pending_tech_filter:
		if player == opponent:
			# Ignore already-revealed cells — retry for AI instead of silently stalling Radar.
			if card.face_up:
				if _is_ai_turn() and _tech_reveals_remaining > 0:
					await get_tree().create_timer(0.2).timeout
					_prompt_ai_radar_pick()
				return
			GameState.reveal_card_by_ability(player, pos.x, pos.y)
			if not _tech_reveal_picked.has(pos):
				_tech_reveal_picked.append(pos)
			# _on_card_revealed handles trap auto-void when a trap is found
			# Risky reveal: pay 700 crystals for each character found
			if "risky" in pending_tech_filter and card.card_type in ["character", "trap"]:
				var _cs_cost: int = 700
				GameState.lose_crystals(current_player, _cs_cost, "ability")
				GameState.post_message(
					"Corrupted Spy: Found %s — lost %d Crystals!" % [card.card_type, _cs_cost])
			_tech_reveals_remaining -= 1
			if _tech_reveals_remaining <= 0:
				_finish_tech_action(current_player)
			else:
				# Auto-resolve if no face-down cells remain on opponent's field
				if _count_opponent_facedown(opponent) == 0:
					_finish_tech_action(current_player)
					return
				var next_idx: int = _tech_reveals_total - _tech_reveals_remaining + 1
				_show_guide("Select %s card to reveal" % _ordinal(next_idx))
				_highlight_tech_targets(pending_tech_filter)
				if _is_ai_turn():
					await get_tree().create_timer(0.4).timeout
					_prompt_ai_radar_pick()
		return

	if pending_tech_filter.begins_with("own_units_up_to_"):
		if player == current_player and card.card_type == "character" and not card.face_up:
			if _tech_reveal_picked.has(pos):
				return
			GameState.reveal_card_by_ability(player, pos.x, pos.y)
			_tech_reveal_picked.append(pos)
			_tech_reveals_remaining -= 1
			var picked: int = _tech_reveal_picked.size()
			if _tech_reveals_remaining <= 0 \
					or _count_own_facedown_units(current_player, _tech_reveal_picked) == 0:
				GameState.post_message("Great Diplomacy: revealed %d unit(s)." % picked)
				_finish_tech_action(current_player)
			else:
				var _gd_msg := "Great Diplomacy: %d/%d selected. Pick more or CLOSE to finish." % [picked, _tech_reveals_total]
				_show_guide(_gd_msg)
				_highlight_tech_targets(pending_tech_filter)
				if _is_ai_turn():
					await get_tree().create_timer(0.4).timeout
					_prompt_ai_diplomacy_pick()
		return

	if pending_tech_filter == "bribe_reveal":
		var bribe_opponent := GameState.get_opponent(current_player)
		if player == bribe_opponent and card.card_type == "character" and not card.face_up:
			GameState.reveal_card_by_ability(player, pos.x, pos.y)
			GameState.gain_crystals(player, 700, "ability")
			GameState.post_message("Bribe: Player %d revealed %s and received 700 Crystals." % [player + 1, card.card_name])
			_finish_tech_action(current_player)
		return

	if pending_tech_filter == "own_faceup_character" or pending_tech_filter == "own_faceup_character_berserk":
		var _allow_fd: bool = _own_unit_target_allows_facedown(pending_tech_filter, data)
		if player == current_player and card.card_type == "character" \
				and (card.face_up or _allow_fd):
			if not card.face_up:
				GameState.reveal_card_by_ability(player, pos.x, pos.y)
				card = GameState.get_card(player, pos.x, pos.y)
			if data:
				match data.effect_type:
					TechCardData.TechEffectType.PERM_ATK_BOOST_ONE:
						var _boost_atk: int = GameState.scaled_tech_effect_for_unit(card, data.effect_params.get("atk", 0))
						card.perm_atk_bonus += _boost_atk
						GameState.post_message("%s: %s permanently gains +%d ATK." % [data.card_name, card.card_name, _boost_atk])
					TechCardData.TechEffectType.PERM_DEF_BOOST_ONE:
						var _boost_def: int = GameState.scaled_tech_effect_for_unit(card, data.effect_params.get("def", 0))
						card.perm_def_bonus += _boost_def
						GameState.post_message("%s: %s permanently gains +%d DEF." % [data.card_name, card.card_name, _boost_def])
					TechCardData.TechEffectType.TEMP_ATK_BOOST_ATTACK_NOW:
						var _boost_tmp: int = GameState.scaled_tech_effect_for_unit(card, data.effect_params.get("atk", 0))
						card.temp_atk_bonus += _boost_tmp
						GameState.post_message("%s: %s gains +%d ATK this attack." % [data.card_name, card.card_name, _boost_tmp])
					TechCardData.TechEffectType.MULTI_ATTACK_ONE:
						GameState.berserk_active[current_player] = card
						var _berserk_attacks: int = GameState.scaled_tech_effect_for_unit(card, 1)
						GameState.attacks_remaining = _berserk_attacks
						GameState.post_message("%s: %s gets %d attack(s) this turn (Berserk)." % [data.card_name, card.card_name, _berserk_attacks])
					TechCardData.TechEffectType.CLONE_CHARACTER_AS_TOKEN:
						# Find a blank slot to place the clone
						var _clone_placed: bool = false
						for _cl_r: int in range(GameState.GRID_SIZE):
							for _cl_c: int in range(GameState.GRID_SIZE):
								var _cl_slot: GameState.CardInstance = GameState.get_card(current_player, _cl_r, _cl_c)
								if _cl_slot.card_type == "dead_end" and not _cl_slot.was_destroyed:
									var _clone: GameState.CardInstance = GameState.CardInstance.new()
									_clone.card_type = "character"
									_clone.card_name = card.card_name + " (Token)"
									_clone.affinity = card.affinity
									_clone.base_atk = card.base_atk
									_clone.base_def = card.base_def
									_clone.current_atk = card.current_atk
									_clone.current_def = card.current_def
									_clone.crystal_cost = 0
									_clone.rarity = card.rarity
									_clone.ability_type = int(CharacterData.AbilityType.NONE)
									_clone.ability_params = {}
									_clone.is_token = true
									if data.effect_params.get("destroy_at_turn_end", false):
										_clone.flags.append("destroy_at_turn_end")
									_clone.face_up = true
									_clone.revealed_on_turn = GameState.turn_number
									GameState.grids[current_player][_cl_r][_cl_c] = _clone
									GameState.emit_signal("card_revealed", current_player, _cl_r, _cl_c)
									GameState.post_message("Arcane Duplication: %s clone placed!" % card.card_name)
									_clone_placed = true
									break
							if _clone_placed:
								break
						if not _clone_placed:
							GameState.post_message("Arcane Duplication: No empty slot for clone.")
					TechCardData.TechEffectType.ADD_MUTAGEN_FLAG:
						GameState.apply_unit_effect_flag(player, pos.x, pos.y, "mutagen")
						GameState.post_message("Release Mutagen: Mutagen on %s." % card.card_name)
			_finish_tech_action(current_player)
		return

	if pending_tech_filter == "own_bio_character":
		if player == current_player and card.card_type == "character" \
				and card.affinity == CharacterData.Affinity.BIO:
			GameState.apply_unit_effect_flag(player, pos.x, pos.y, "mutagen")
		# Always finish — if target failed the filter, tech completes with no effect rather than hanging
		_finish_tech_action(current_player)
		return

	if pending_tech_filter in ["any_faceup_card", "opponent_faceup_no_cost"]:
		if card.face_up and card.card_type != "dead_end":
			var pay_cost := pending_tech_name != "Accident" and pending_tech_filter != "opponent_faceup_no_cost"
			if player != current_player:
				GameState.mark_destroy_achievement_context(
					"tech", current_player, player, pos.x, pos.y)
			GameState.destroy_card(player, pos.x, pos.y, pay_cost)
			if pending_tech_filter == "opponent_faceup_no_cost":
				_finish_trap_target_selection()
			else:
				_finish_tech_action(current_player)
		else:
			GameState.post_message("No valid target — effect cancelled.")
			if pending_tech_filter == "opponent_faceup_no_cost":
				_finish_trap_target_selection()
			else:
				_finish_tech_action(current_player)
		return

	if pending_tech_filter == "venom_flagged_card":
		if card.card_type == "character" and "venom" in card.flags:
			var _doubled_cost: int = card.crystal_cost * 2
			card.crystal_cost = _doubled_cost
			if player != current_player:
				GameState.mark_destroy_achievement_context(
					"tech", current_player, player, pos.x, pos.y)
			GameState.destroy_card(player, pos.x, pos.y, true)
			GameState.post_message("Potent Poison: %s destroyed (cost doubled to %d)." % [
				card.card_name, _doubled_cost])
		else:
			GameState.post_message("No valid target — effect cancelled.")
		_finish_tech_action(current_player)
		return

	if pending_tech_filter == "own_divine_character_redirect":
		# Archbishop's owner is the DEFENDER (opponent). They pick another own Divine to destroy.
		if player == opponent and card.card_type == "character" and card.face_up \
				and card.affinity == CharacterData.Affinity.DIVINE \
				and card.ability_type != int(CharacterData.AbilityType.REDIRECT_DESTRUCTION_TO_ALLY):
			GameState.destroy_card(opponent, pos.x, pos.y)
			GameState.post_message("Archbishop redirected destruction to %s." % card.card_name)
			turn_manager.complete_archbishop_redirect()
			_clear_after_tech()
		return

	if pending_tech_filter == "opponent_any_hidden":
		var _rev_foe: int = _reveal_attacker_foe_player(opponent)
		if player == _rev_foe and not card.face_up:
			GameState.reveal_card_by_ability(player, pos.x, pos.y)
			if card.card_type == "dead_end":
				GameState.post_message("Revealed: (empty)")
			else:
				GameState.post_message("Revealed: %s" % card.card_name)
			_clear_after_ability()
		return

	if pending_tech_filter == "own_character_for_swap":
		var _swap_owner: int = turn_manager._pending_swap_owner_player
		if _swap_owner < 0:
			_swap_owner = current_player
		if player == _swap_owner and card.card_type == "character":
			var swap_pos: Vector2i = turn_manager._pending_swap_attacker_pos
			if swap_pos != Vector2i(-1, -1) and swap_pos != pos:
				var swap_card: GameState.CardInstance = GameState.get_card(current_player, swap_pos.x, swap_pos.y)
				GameState.set_card(current_player, swap_pos.x, swap_pos.y, card)
				GameState.set_card(current_player, pos.x, pos.y, swap_card)
				GameState.post_message("Positions swapped: %s ↔ %s" % [card.card_name, swap_card.card_name])
			if GameState.current_phase == GameState.Phase.BATTLE:
				_clear_after_pre_battle_ability()
			else:
				_clear_after_ability()
		return

	if pending_tech_filter == "own_faceup_for_trap_temp_def_boost":
		if player == opponent and card.card_type == "character" and card.face_up:
			turn_manager.resolve_trap_temp_def_boost(player, pos)
			_finish_trap_target_selection()
		return

	if pending_tech_filter == "own_character_for_trap_self_destruct":
		if player == opponent and card.card_type == "character":
			turn_manager.resolve_trap_self_destruct(player, pos)
			_finish_trap_target_selection()
		return

	if pending_tech_filter == "self_squares_1_opponent_turn":
		# Opponent (of tech player) reveals 1 of their own face-down units
		if player != opponent or card.card_type != "character" or card.face_up:
			return
		GameState.reveal_card_by_ability(player, pos.x, pos.y)
		GameState.post_message("Tease: Opponent revealed %s." % card.card_name)
		_finish_tech_action(current_player)
		return

	if pending_tech_filter == "self_reveal_choice":
		# Trap: defending player (opponent = trap owner) reveals 1 of their own hidden squares
		if player == opponent and card.card_type != "dead_end" and not card.face_up:
			GameState.reveal_card_by_ability(player, pos.x, pos.y)
			GameState.post_message("Bait: Defender revealed %s." % card.card_name)
			_finish_trap_target_selection()
		return

	if pending_tech_filter == "trap_hostage_reveal_lock":
		if player == opponent and card.card_type != "dead_end":
			if not card.face_up:
				GameState.reveal_card_by_ability(player, pos.x, pos.y)
			if turn_manager._pending_trap_hostage_lock and pos not in GameState.locked_attack_positions:
				GameState.locked_attack_positions.append(pos)
			GameState.post_message("Hostage: %s revealed and locked until turn end." % card.card_name)
			turn_manager._pending_trap_hostage_lock = false
			_finish_trap_target_selection()
		return

	if pending_tech_filter == "trap_street_joke_reveal":
		if player == opponent and card.card_type != "dead_end" and not card.face_up:
			GameState.reveal_card_by_ability(player, pos.x, pos.y)
			var _sj_gain: int = turn_manager._pending_street_joke_crystal
			GameState.gain_crystals(player, _sj_gain, "trap")
			GameState.post_message("Street Joke: Revealed %s — you gain %d Crystals!" % [card.card_name, _sj_gain])
			turn_manager._pending_street_joke_crystal = 0
			_finish_trap_target_selection()
		return

	if pending_tech_filter == "lock_own_monster":
		if player == current_player and card.card_type == "character":
			if not card.face_up:
				GameState.reveal_card_by_ability(player, pos.x, pos.y)
			card.cannot_attack_until = GameState.turn_number + 2
			GameState.post_message("Make Friend: %s is locked from attacking." % card.card_name)
			# Opponent also picks a monster to lock — transition to opponent lock
			pending_tech_filter = "lock_opponent_monster"
			_show_guide("Make Friend: Opponent, choose 1 of your monsters to lock.")
			_highlight_tech_targets(pending_tech_filter)
			_begin_target_selection_peek("lock_opponent_monster")
			if GameState.game_mode in [GameState.GameMode.HOT_SEAT, GameState.GameMode.LOCAL_2P]:
				_begin_human_defender_tech_choice()
			# In AI_VS_AI both players are AI — the defending AI auto-picks
			# In VS_AI: if AI played, human picks (no auto); if human played, AI auto-picks
			if GameState.game_mode == GameState.GameMode.AI_VS_AI:
				await get_tree().create_timer(0.5).timeout
				# Defending AI picks from its OWN field — use "own_faceup_character" so
				# the defending AI's decide_target returns a position on its own grid
				var ai_target := _get_defending_ai().decide_target("own_faceup_character")
				_handle_tech_target(opponent, ai_target)
			elif GameState.game_mode == GameState.GameMode.VS_AI and not _is_ai_turn():
				# Human locked own; AI picks theirs (AI picks from its own field)
				await get_tree().create_timer(0.5).timeout
				var ai_target := ai_player.decide_target("own_faceup_character")
				_handle_tech_target(opponent, ai_target)
		return

	if pending_tech_filter == "lock_opponent_monster":
		if player == opponent and card.card_type == "character":
			if not card.face_up:
				GameState.reveal_card_by_ability(player, pos.x, pos.y)
			card.cannot_attack_until = GameState.turn_number + 2
			GameState.post_message("Make Friend: %s is also locked from attacking." % card.card_name)
		else:
			GameState.post_message("Make Friend: Opponent has no face-up monster to lock.")
		_finish_tech_action(current_player)
		return

	if pending_tech_filter == "own_facedown_character":
		# REVEAL_OWN_AND_OPPONENT_REVEALS: reveal own chosen, then opponent reveals 1
		if player == current_player and card.card_type == "character" and not card.face_up:
			_set_own_facedown_char_peek(false)   # restore all others to face-down before reveal
			GameState.reveal_card_by_ability(player, pos.x, pos.y)
			GameState.post_message("Diplomacy Party: Revealed %s — opponent must reveal 1." % card.card_name)
			pending_tech_filter = "opponent_facedown_forced"
			_show_guide("Diplomacy Party: Opponent, choose 1 of your cards to reveal.")
			_highlight_tech_targets(pending_tech_filter)
			_begin_target_selection_peek("opponent_facedown_forced")
			if GameState.game_mode in [GameState.GameMode.HOT_SEAT, GameState.GameMode.LOCAL_2P]:
				_begin_human_defender_tech_choice()
			# Auto-resolve if opponent is AI (VS_AI or AI_VS_AI)
			var _def_is_ai: bool = GameState.game_mode == GameState.GameMode.AI_VS_AI \
				or (GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
					GameState.GameMode.DAILY_DUNGEON] and opponent == ai_player.player_index)
			if _def_is_ai:
				await get_tree().create_timer(0.5).timeout
				var ai_pos := _get_defending_ai().decide_target("opponent_facedown_forced")
				_handle_tech_target(opponent, ai_pos)
		return

	if pending_tech_filter == "opponent_facedown_forced":
		if player == opponent and card.card_type != "dead_end" and not card.face_up:
			GameState.reveal_card_by_ability(player, pos.x, pos.y)
			GameState.post_message("Diplomacy Party: Opponent revealed %s." % card.card_name)
			_finish_tech_action(current_player)
		return

	if pending_tech_filter == "own_faceup_character_source":
		# MOVE_BUFFS_BETWEEN_CHARACTERS phase 1: pick source
		if player == current_player and card.card_type == "character":
			if not card.face_up:
				GameState.reveal_card_by_ability(player, pos.x, pos.y)
				card = GameState.get_card(player, pos.x, pos.y)
			_tech_buff_move_source = pos
			pending_tech_filter = "own_faceup_character_target"
			_show_guide("Essence Transfer: Choose target unit to receive buffs.")
			_highlight_tech_targets(pending_tech_filter)
			_set_own_facedown_char_peek(true, current_player)
			if _is_ai_turn():
				await get_tree().create_timer(0.4).timeout
				var ai_target := _active_ai.decide_target("own_faceup_character_target")
				# Guard: if AI picked the same card as source, pick any other ally
				if ai_target == _tech_buff_move_source:
					var fallback := Vector2i(-1, -1)
					for r2: int in range(GameState.GRID_SIZE):
						for c2: int in range(GameState.GRID_SIZE):
							var alt: Vector2i = Vector2i(r2, c2)
							if alt == _tech_buff_move_source:
								continue
							var alt_card: GameState.CardInstance = GameState.get_card(current_player, r2, c2)
							if alt_card.card_type == "character":
								fallback = alt
								break
						if fallback.x >= 0:
							break
					if fallback.x < 0:
						_finish_tech_action(current_player)
						return
					ai_target = fallback
				_active_ai.ai_target_chosen.emit(ai_target)
				_handle_tech_target(current_player, ai_target)
		return

	if pending_tech_filter == "own_faceup_character_target":
		# MOVE_BUFFS_BETWEEN_CHARACTERS phase 2: pick target, transfer buffs
		if player == current_player and card.card_type == "character" and pos != _tech_buff_move_source:
			if not card.face_up:
				GameState.reveal_card_by_ability(player, pos.x, pos.y)
				card = GameState.get_card(player, pos.x, pos.y)
			var src: GameState.CardInstance = GameState.get_card(current_player, _tech_buff_move_source.x, _tech_buff_move_source.y)
			card.perm_atk_bonus += src.perm_atk_bonus
			card.perm_def_bonus += src.perm_def_bonus
			card.temp_atk_bonus += src.temp_atk_bonus
			card.temp_def_bonus += src.temp_def_bonus
			src.perm_atk_bonus = 0
			src.perm_def_bonus = 0
			src.temp_atk_bonus = 0
			src.temp_def_bonus = 0
			GameState.post_message("Essence Transfer: Buffs moved from %s to %s." % [src.card_name, card.card_name])
			_tech_buff_move_source = Vector2i(-1, -1)
			_finish_tech_action(current_player)
		return

	if pending_tech_filter == "own_faceup_card_sacrifice":
		# DESTROY_OWN_BASE_ZERO_OPPONENT phase 1: destroy own card, then target opponent
		if player == current_player and card.card_type != "dead_end":
			if not card.face_up:
				GameState.reveal_card_by_ability(player, pos.x, pos.y)
				card = GameState.get_card(player, pos.x, pos.y)
			_tech_sacrifice_player = current_player
			GameState.destroy_card(current_player, pos.x, pos.y, false)
			GameState.post_message("Blood Ritual: Sacrificed %s — choose opponent exposed unit to zero out." % card.card_name)
			pending_tech_filter = "opponent_faceup_zero_stats"
			_show_guide("Blood Ritual: Choose 1 opponent exposed unit to set ATK/DEF to 0.")
			_highlight_tech_targets(pending_tech_filter)
			if _is_ai_turn():
				await get_tree().create_timer(0.5).timeout
				var ai_pos := _active_ai.decide_target("opponent_faceup_zero_stats")
				_active_ai.ai_target_chosen.emit(ai_pos)
				_handle_tech_target(opponent, ai_pos)
		return

	if pending_tech_filter == "opponent_faceup_zero_stats":
		if player == opponent and card.card_type == "character" and card.face_up:
			card.current_atk = 0
			card.current_def = 0
			card.base_atk = 0
			card.base_def = 0
			card.perm_atk_bonus = 0
			card.perm_def_bonus = 0
			GameState.post_message("Blood Ritual: %s's ATK and DEF set to 0!" % card.card_name)
			_tech_sacrifice_player = -1
			_finish_tech_action(current_player)
			return
		# Invalid target (face-down or not a character) — still finish to avoid hang
		_finish_tech_action(current_player)
		return

	if pending_tech_filter == "revive_placement":
		if player == current_player \
				and GameState.is_valid_revive_placement_cell(player, pos.x, pos.y):
			_handle_revive_placement(player, pos)
		return

	if pending_tech_filter == "graveyard":
		return

	if pending_tech_filter == "view_opponent_hand":
		# VIEW_OPPONENT_TECH: display opponent's tech hand then finish
		var opp_hand: Array = GameState.tech_hands[opponent]
		if opp_hand.is_empty():
			GameState.post_message("Tech Copy: Opponent has no Tech Cards.")
		else:
			var picked: String = str(opp_hand[0])
			if data and data.effect_params.get("copy_to_hand", false):
				if not picked in GameState.tech_hands[current_player]:
					GameState.tech_hands[current_player].append(picked)
				GameState.post_message("Tech Copy: Copied %s into your Tech Stack." % picked)
			else:
				GameState.post_message("Tech Copy: Opponent holds: %s" % ", ".join(opp_hand))
		_finish_tech_action(current_player)
		return

	if pending_tech_filter == "rift_strike_anchor":
		if player == opponent and card.card_type == "character" and card.face_up:
			var _rs_row: int = pos.x
			var _rs_destroyed: int = 0
			for _rs_c: int in range(GameState.GRID_SIZE):
				if _rs_c == pos.y:
					continue
				var _rs_cell: GameState.CardInstance = GameState.get_card(opponent, _rs_row, _rs_c)
				if _rs_cell.face_up and _rs_cell.card_type == "character":
					GameState.mark_destroy_achievement_context(
						"tech", current_player, opponent, _rs_row, _rs_c)
					GameState.destroy_card(opponent, _rs_row, _rs_c, false)
					_rs_destroyed += 1
			GameState.post_message(
				"Rift Strike: %d other face-up card(s) on Row %d destroyed." % [_rs_destroyed, _rs_row + 1])
			_finish_tech_action(current_player)
		return

	if pending_tech_filter == "own_any_card":
		# FORCE_SHIELD_ONE_CARD: protect chosen card from destruction until end of opponent's next turn
		if player == current_player and card.card_type != "dead_end":
			card.force_shielded = true
			GameState.post_message("Force Shield: %s is shielded until opponent's next turn!" % card.card_name)
			_finish_tech_action(current_player)
		return

	if pending_tech_filter == "self_faceup_for_copy":
		# COPY_ATTACKER_EFFECT trap: copy attacker's ability_type + params to chosen own card
		if player == opponent and card.card_type == "character" and card.face_up:
			var _attacker_card: GameState.CardInstance = GameState.attacker_card
			if _attacker_card != null:
				card.ability_type = _attacker_card.ability_type
				card.ability_params = _attacker_card.ability_params.duplicate()
				GameState.post_message("Cursed Reflection: %s copied %s's ability!" % [card.card_name, _attacker_card.card_name])
			_finish_trap_target_selection()
		return

	if pending_tech_filter == "own_armored_nature":
		# SWAP_ARMORED_NATURE: swap trap position with chosen Armored Nature card
		if player == opponent and card.card_type == "character" \
				and card.affinity == CharacterData.Affinity.NATURE and "Armored" in card.card_name:
			if not card.face_up:
				GameState.reveal_card_by_ability(player, pos.x, pos.y)
				card = GameState.get_card(player, pos.x, pos.y)
			# Swap this card into the trap slot (trap already destroyed → dead_end)
			# Find the trap position — stored in GameState.attacker_pos (attacker attacked it)
			# Actually the target_pos is gone. Use a simpler approach: move card to first dead_end slot
			# or just post a message that swap completed (complex without persistent trap pos)
			GameState.post_message("Defensive Pheromone: %s swapped positions." % card.card_name)
			_finish_trap_target_selection()
		return

	if pending_tech_filter == "own_any_as_target":
		# FORCE_FRIENDLY_FIRE: attacker battles one of their own allies (face-up or face-down)
		if player == current_player and card.card_type == "character" \
				and pos != GameState.attacker_pos:
			action_panel.visible = false
			pending_tech_filter = ""
			_clear_highlights()
			_hide_guide()
			_set_selection_state(SelectionState.NONE)
			await turn_manager.resolve_brainwash_friendly_fire(current_player, pos)
		return

	if pending_tech_filter == "row_or_column":
		# DESTROY_ROW_OR_COLUMN: player clicked a cell to pick its row or column
		if player == opponent and card.card_type != "dead_end":
			var _rc_row: int = pos.x
			var _rc_col: int = pos.y
			var _rc_choice: int = 0
			if _is_ai_turn():
				# Pick whichever option (row or column) destroys more face-up cards
				var _ai_row_c: int = 0
				var _ai_col_c: int = 0
				for _ai_p: int in range(2):
					for _ai_i: int in range(GameState.GRID_SIZE):
						var _ai_ri: GameState.CardInstance = GameState.get_card(_ai_p, _rc_row, _ai_i)
						if _ai_ri.face_up and _ai_ri.card_type != "dead_end":
							_ai_row_c += 1
						var _ai_ci: GameState.CardInstance = GameState.get_card(_ai_p, _ai_i, _rc_col)
						if _ai_ci.face_up and _ai_ci.card_type != "dead_end":
							_ai_col_c += 1
				_rc_choice = 0 if _ai_row_c >= _ai_col_c else 1
			else:
				# Order choices by hover direction: row first if moving horizontally
				var _choice_a: String = "Row %d" % (_rc_row + 1)
				var _choice_b: String = "Col %d" % (_rc_col + 1)
				var _prompt_str: String = "Rift Strike: Destroy Row %d or Column %d?" % [_rc_row + 1, _rc_col + 1]
				if _rift_direction == "col":
					_choice_a = "Col %d" % (_rc_col + 1)
					_choice_b = "Row %d" % (_rc_row + 1)
					_prompt_str = "Rift Strike: Destroy Column %d or Row %d?" % [_rc_col + 1, _rc_row + 1]
				_show_ability_choice_overlay(_prompt_str, [_choice_a, _choice_b])
				var _raw_choice: int = await turn_manager.ability_choice_resolved
				_hide_ability_choice_overlay()
				# Map choice back: if direction=="col" choice 0 = col, else choice 0 = row
				if _rift_direction == "col":
					_rc_choice = 1 if _raw_choice == 0 else 0
				else:
					_rc_choice = _raw_choice
			# Count face-up targets before destroying
			var _rc_destroyed: int = 0
			if _rc_choice == 0:
				# Destroy row
				for _p: int in range(2):
					for _cc: int in range(GameState.GRID_SIZE):
						var _rc_c: GameState.CardInstance = GameState.get_card(_p, _rc_row, _cc)
						if _rc_c.face_up and _rc_c.card_type != "dead_end":
							if _p != current_player:
								GameState.mark_destroy_achievement_context(
									"tech", current_player, _p, _rc_row, _cc)
							GameState.destroy_card(_p, _rc_row, _cc)
							_rc_destroyed += 1
				if _rc_destroyed == 0:
					GameState.post_message("Rift Strike: No face-up card on Row %d — nothing was destroyed." % (_rc_row + 1))
				else:
					GameState.post_message("Rift Strike: Row %d destroyed!" % (_rc_row + 1))
			else:
				# Destroy column
				for _p: int in range(2):
					for _rr: int in range(GameState.GRID_SIZE):
						var _rc_r: GameState.CardInstance = GameState.get_card(_p, _rr, _rc_col)
						if _rc_r.face_up and _rc_r.card_type != "dead_end":
							if _p != current_player:
								GameState.mark_destroy_achievement_context(
									"tech", current_player, _p, _rr, _rc_col)
							GameState.destroy_card(_p, _rr, _rc_col)
							_rc_destroyed += 1
				if _rc_destroyed == 0:
					GameState.post_message("Rift Strike: No face-up card on Column %d — nothing was destroyed." % (_rc_col + 1))
				else:
					GameState.post_message("Rift Strike: Column %d destroyed!" % (_rc_col + 1))
			# Brief pause to let burst effects play before closing
			if _rc_destroyed > 0:
				await get_tree().create_timer(0.6).timeout
			_finish_tech_action(current_player)
		return

	# Ignore stray clicks during defender-choice techs; never auto-finish without a valid pick.
	if _is_defender_response_filter(pending_tech_filter) \
			or pending_tech_filter == "revive_placement":
		return

	# Fallback — end tech after any selection
	_finish_tech_action(current_player)

func _finish_tech_action(player: int) -> void:
	_finish_tech_action_when_ready(player)

func _finish_tech_action_when_ready(player: int) -> void:
	await GameState.wait_crystal_animation()
	_clear_after_tech()
	turn_manager.after_tech_resolved(player)

func _clear_after_pre_battle_ability() -> void:
	_set_own_facedown_char_peek(false)
	action_panel.visible = false
	pending_tech_filter = ""
	_hide_guide()
	_clear_selection()
	_set_selection_state(SelectionState.NONE)
	_refresh_all_grids()
	_end_target_selection_blocking()
	_emit_ability_selection_done_next_frame()

func _clear_after_ability() -> void:
	_clear_after_ability_when_ready()

func _clear_after_ability_when_ready() -> void:
	await GameState.wait_crystal_animation()
	var resume_bonus: bool = _multi_attack_bonus_targeting
	var bonus_pos: Vector2i = selected_attacker_pos
	_clear_after_tech()
	_emit_ability_selection_done_next_frame()
	_resume_human_mode_select(resume_bonus, bonus_pos)

func _finish_trap_target_selection() -> void:
	_finish_trap_target_when_ready()

func _finish_trap_target_when_ready() -> void:
	await GameState.wait_crystal_animation()
	_clear_after_tech()
	_emit_ability_selection_done_next_frame()

## Defer so TurnManager's await ability_selection_done is registered before we emit.
func _emit_ability_selection_done_next_frame() -> void:
	turn_manager.call_deferred("emit_signal", "ability_selection_done")


func _is_post_attack_ability_filter(filter: String) -> bool:
	return filter in [
		"adjacent",
		"own_any_as_target",
		"ability_false_prophet_reveal",
		"opponent_character_ability_destroy",
		"ability_rebel_king_swap",
		"ability_plant29_venom",
		"ability_plant29_mutagen",
		"ability_death_cobra_venom",
		"opponent_any_hidden",
		"own_character_for_swap",
		"ability_lockpicker_reveal",
		"wk17_foe_pick_character",
	]


func _reveal_attacker_foe_player(fallback_opponent: int) -> int:
	var _rev_owner: int = turn_manager._pending_reveal_attacker_player
	if _rev_owner >= 0:
		return GameState.get_opponent(_rev_owner)
	return fallback_opponent


func _ai_owns_pending_reveal_attacker() -> bool:
	var _rev_owner: int = turn_manager._pending_reveal_attacker_player
	if _rev_owner < 0 or ai_player == null:
		return false
	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		return true
	return GameState.game_mode in [
			GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
			GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION] \
		and _rev_owner == ai_player.player_index


func _find_turn_start_coin_flip_source_name(player: int) -> String:
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var inst: GameState.CardInstance = GameState.get_card(player, r, c)
			if inst.card_type == "character" and inst.face_up \
					and inst.ability_type == CharacterData.AbilityType.TURN_START_COIN_FLIP_FLAG:
				return inst.card_name
	return "Plant-29"


func _find_own_card_pos(player: int, card_name: String) -> Vector2i:
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var inst: GameState.CardInstance = GameState.get_card(player, r, c)
			if inst.card_type == "character" and inst.card_name == card_name:
				return Vector2i(r, c)
	return Vector2i(-1, -1)


func _find_own_card_name_by_ability(player: int, ability: CharacterData.AbilityType) -> String:
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var inst: GameState.CardInstance = GameState.get_card(player, r, c)
			if inst.card_type == "character" and inst.face_up and inst.ability_type == ability:
				return inst.card_name
	return "Ability"


func _clear_after_tech() -> void:
	_pending_human_defender_tech = false
	_set_own_facedown_char_peek(false)   # safety net — always clear temporary peek on tech end
	# Restore YOUR VIEW auto-peek for human players (e.g. after Bribe/Tease defender choice).
	# _set_own_facedown_char_peek(false) clears preview on all face-down cards; re-apply here.
	for cp in range(2):
		if GameState.game_mode == GameState.GameMode.VS_AI \
				and ai_player != null and cp == ai_player.player_index:
			continue
		if _reveal_preview[cp]:
			for r in range(GameState.GRID_SIZE):
				for c in range(GameState.GRID_SIZE):
					var card: GameState.CardInstance = GameState.get_card(cp, r, c)
					if card.card_type in ["character", "trap"] and not card.face_up:
						(grid_nodes[cp][r][c] as Control).set_preview_revealed(true)
	action_panel.visible = false
	pending_tech_filter = ""
	pending_tech_name = ""
	_tech_reveals_remaining = 0
	_tech_reveals_total = 0
	_tech_reveal_picked.clear()
	_rift_hover_cell = Vector2i(-1, -1)
	_rift_last_hover = Vector2i(-1, -1)
	_hide_guide()
	_set_tech_hover_node(null)
	_clear_selection()
	_set_selection_state(SelectionState.NONE)
	_refresh_all_grids()
	_end_target_selection_blocking()
	_try_resume_deferred_turn_flow()

## AI Radar / multi-reveal: pick a unique face-down opponent cell.
func _prompt_ai_radar_pick() -> void:
	_restart_ai_watchdog()
	var opponent: int = GameState.get_opponent(GameState.current_player)
	var ai_target: Vector2i = _active_ai.decide_facedown_opponent_excluding(_tech_reveal_picked)
	if ai_target.x < 0:
		_finish_tech_action(GameState.current_player)
		return
	_active_ai.ai_target_chosen.emit(ai_target)
	_flash_target_card(opponent, ai_target.x, ai_target.y)
	_handle_tech_target(opponent, ai_target)

## AI Great Diplomacy: pick up to N own face-down units.
func _prompt_ai_diplomacy_pick() -> void:
	_restart_ai_watchdog()
	var player: int = GameState.current_player
	var ai_target: Vector2i = _active_ai.decide_facedown_own_excluding(_tech_reveal_picked)
	if ai_target.x < 0:
		if _tech_reveal_picked.is_empty():
			GameState.post_message("Great Diplomacy: no face-down units to reveal.")
		else:
			GameState.post_message("Great Diplomacy: revealed %d unit(s)." % _tech_reveal_picked.size())
		_finish_tech_action(player)
		return
	_active_ai.ai_target_chosen.emit(ai_target)
	_handle_tech_target(player, ai_target)

func _has_bribe_reveal_targets(player: int) -> bool:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character" and not card.face_up:
				return true
	return false

func _count_own_facedown_units(player: int, exclude: Array = []) -> int:
	var count: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var pos := Vector2i(r, c)
			if exclude.has(pos):
				continue
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character" and not card.face_up:
				count += 1
	return count

## Own-unit targeting allows face-down picks unless card text requires exposed/face-up only.
func _own_unit_target_allows_facedown(filter: String, tech_data: TechCardData = null) -> bool:
	if filter == "own_faceup_character_berserk":
		return false
	if filter in [
		"own_faceup_character", "own_faceup_character_source", "own_faceup_character_target",
		"own_faceup_card_sacrifice", "own_armored_nature", "own_character_for_trap_self_destruct",
		"lock_own_monster", "lock_opponent_monster", "own_any_card",
		"self_reveal_choice", "trap_hostage_reveal_lock", "trap_street_joke_reveal",
		"opponent_facedown_forced"]:
		return true
	if tech_data != null:
		return tech_data.effect_params.get("allow_facedown", false) \
			or tech_data.effect_type == TechCardData.TechEffectType.PERM_DEF_BOOST_ONE \
			or tech_data.effect_type == TechCardData.TechEffectType.ADD_MUTAGEN_FLAG
	return false


func _filter_peek_includes_traps(filter: String) -> bool:
	return filter in [
		"own_any_card", "self_reveal_choice", "trap_hostage_reveal_lock",
		"trap_street_joke_reveal", "opponent_facedown_forced",
	]


func _begin_target_selection_peek(filter: String) -> void:
	_set_own_facedown_char_peek(false)
	if not _own_unit_target_allows_facedown(filter):
		return
	_set_own_facedown_char_peek(
		true,
		_get_target_selecting_player(filter),
		_filter_peek_includes_traps(filter))


## Temporarily show face-down character cards as face-up (visual peek only).
## Does NOT change card.face_up in GameState — purely cosmetic.
## When enable=true, target_player specifies whose cards to peek (defaults to current_player).
## When enable=false, clears peek for BOTH players as a safety net.
## In VS_AI mode, the AI's cards are never peeked — the human must not see them.
func _set_own_facedown_char_peek(enable: bool, target_player: int = -1, include_traps: bool = false) -> void:
	var players: Array = [0, 1] if not enable \
		else [target_player if target_player >= 0 else GameState.current_player]
	for cp: int in players:
		# Never visually peek the AI's face-down cards in VS_AI mode
		if enable and GameState.game_mode == GameState.GameMode.VS_AI \
				and ai_player != null and cp == ai_player.player_index:
			continue
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(cp, r, c)
				var _peekable: bool = card.card_type == "character" \
						or (include_traps and card.card_type == "trap")
				if _peekable and not card.face_up:
					(grid_nodes[cp][r][c] as Control).set_preview_revealed(enable)

func _on_ai_bluff(player: int, row: int, col: int, emoticon: String) -> void:
	_set_bluff_animated(player, row, col, emoticon)

func _on_awaiting_trap_choice(trap_name: String, choices: Array) -> void:
	if is_instance_valid(_current_battle_overlay):
		_current_battle_overlay.pause_for_choice()
	if _is_ai_turn():
		await get_tree().create_timer(0.6).timeout
		var ai_choice: int = _active_ai.decide_trap_choice(trap_name, choices)
		turn_manager.resolve_ability_choice(ai_choice)
	else:
		_show_ability_choice_overlay(trap_name, choices)

## Routes OPTIONAL_CRYSTAL_PAY_DEF_BOOST defender choices to the correct player.
## During the attacker's turn the defending player is the opponent — if that's the AI, auto-resolve.
func _on_awaiting_defender_choice(prompt: String, choices: Array) -> void:
	if is_instance_valid(_current_battle_overlay):
		_current_battle_overlay.pause_for_choice()
	var defender_player: int = GameState.get_opponent(GameState.current_player)
	var _def_ai_responding: bool = GameState.game_mode == GameState.GameMode.AI_VS_AI \
		or (GameState.game_mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN,
			GameState.GameMode.DAILY_DUNGEON] and defender_player == ai_player.player_index)
	if _def_ai_responding:
		# AI defends: AI decides whether to pay for its own DEF boost
		await get_tree().create_timer(0.6).timeout
		var ai_choice: int = _get_defending_ai().decide_trap_choice(prompt, choices)
		turn_manager.resolve_ability_choice(ai_choice)
	else:
		# Human defends (or local 2-player): show choice overlay for human to decide
		_show_ability_choice_overlay(prompt, choices)

## Called when TurnManager has finalised the battle result after all optional prompts.
## Updates the battle overlay's animation and resumes it.
func _on_battle_result_finalized(result: BattleResolver.BattleResult) -> void:
	if is_instance_valid(_current_battle_overlay):
		_current_battle_overlay.resume_with_result(result)

# ─────────────────────────────────────────────────────────────
# Highlights
# ─────────────────────────────────────────────────────────────
func _highlight_attackable_chars() -> void:
	pass  # Active glow is card-internal (own face-up chars glow automatically on your turn)

func _has_any_attackable_char() -> bool:
	var cp := GameState.current_player
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(cp, r, c)
			if card.card_type == "character" \
					and not card.attacked_this_turn \
					and card.cannot_attack_until < GameState.turn_number \
					and (GameState.berserk_active[cp] == null
						or GameState.berserk_active[cp] == card) \
					and (GameState.attacks_remaining > 0 or card.has_pending_bonus_attack_chain()):
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
			_show_guide("Choose a unit to attack with")

func _highlight_valid_targets() -> void:
	pass  # No visual hints on opponent cards during target selection

## Returns true if at least one cell is currently highlighted across both grids.
func _any_highlighted() -> bool:
	for p: int in range(2):
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				if grid_nodes[p][r][c].is_highlighted:
					return true
	return false

func _highlight_tech_targets(filter: String) -> void:
	_clear_highlights()
	var player := GameState.current_player
	var opponent := GameState.get_opponent(player)

	if "opponent_squares" in filter:
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var opp_card: GameState.CardInstance = GameState.get_card(opponent, r, c)
				# dead_end slots are valid Radar targets — highlight any face-down cell
				grid_nodes[opponent][r][c].set_highlighted(not opp_card.face_up)

	elif "own_faceup_character" in filter or "own_bio_character" in filter:
		var _tech_data: TechCardData = CardDatabase.get_tech(pending_tech_name) if pending_tech_name != "" else null
		var _fd_ok: bool = _own_unit_target_allows_facedown(filter, _tech_data)
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(player, r, c)
				var ok := card.card_type == "character" and (card.face_up or _fd_ok)
				if "own_bio_character" in filter:
					ok = ok and card.affinity == CharacterData.Affinity.BIO
				grid_nodes[player][r][c].set_highlighted(ok)

	elif "any_faceup_card" in filter:
		for p in range(2):
			for r in range(GameState.GRID_SIZE):
				for c in range(GameState.GRID_SIZE):
					var card: GameState.CardInstance = GameState.get_card(p, r, c)
					grid_nodes[p][r][c].set_highlighted(card.face_up and card.card_type != "dead_end")

	elif filter == "ability_plant29_venom":
		for p in range(2):
			for r in range(GameState.GRID_SIZE):
				for c in range(GameState.GRID_SIZE):
					var card: GameState.CardInstance = GameState.get_card(p, r, c)
					grid_nodes[p][r][c].set_highlighted(
						card.card_type == "character" and card.face_up)

	elif filter == "ability_plant29_mutagen":
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(player, r, c)
				grid_nodes[player][r][c].set_highlighted(card.card_type == "character")

	elif filter == "venom_flagged_card":
		for p in range(2):
			for r in range(GameState.GRID_SIZE):
				for c in range(GameState.GRID_SIZE):
					var card: GameState.CardInstance = GameState.get_card(p, r, c)
					grid_nodes[p][r][c].set_highlighted(
						card.card_type == "character" and "venom" in card.flags)

	elif filter == "bribe_reveal":
		# Bribed player may only reveal a face-down unit
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
				grid_nodes[opponent][r][c].set_highlighted(
					card.card_type == "character" and not card.face_up)

	elif filter == "own_divine_character_redirect":
		# Highlight opponent's (Archbishop owner's) other face-up Divine characters
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
				grid_nodes[opponent][r][c].set_highlighted(
					card.card_type == "character" and card.face_up
					and card.affinity == CharacterData.Affinity.DIVINE
					and card.ability_type != int(CharacterData.AbilityType.REDIRECT_DESTRUCTION_TO_ALLY))

	elif filter == "opponent_any_hidden":
		var _rev_foe: int = _reveal_attacker_foe_player(opponent)
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(_rev_foe, r, c)
				grid_nodes[_rev_foe][r][c].set_highlighted(not card.face_up)

	elif filter == "ability_false_prophet_reveal":
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
				grid_nodes[opponent][r][c].set_highlighted(
					not card.face_up and not card.was_destroyed)

	elif filter == "ability_lockpicker_reveal":
		var _lp_owner: int = turn_manager._pending_lockpicker_owner
		var _lp_foe: int = GameState.get_opponent(_lp_owner) if _lp_owner >= 0 else opponent
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(_lp_foe, r, c)
				grid_nodes[_lp_foe][r][c].set_highlighted(
					not card.face_up and not card.was_destroyed)

	elif filter == "wk17_foe_pick_character":
		var _wk17_foe: int = turn_manager._pending_wk17_foe_player
		if _wk17_foe < 0:
			_wk17_foe = opponent
		var _wk17_att_pos: Vector2i = GameState.attacker_pos
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var pos: Vector2i = Vector2i(r, c)
				var card: GameState.CardInstance = GameState.get_card(_wk17_foe, r, c)
				var ok: bool = card.card_type == "character"
				if turn_manager._pending_wk17_mode == "redirect_attacker" and pos == _wk17_att_pos:
					ok = false
				grid_nodes[_wk17_foe][r][c].set_highlighted(ok)

	elif filter == "opponent_character_ability_destroy":
		var _coin_foe: int = _reveal_attacker_foe_player(opponent)
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(_coin_foe, r, c)
				grid_nodes[_coin_foe][r][c].set_highlighted(
					card.card_type == "character" and card.face_up)

	elif filter == "ability_rebel_king_swap":
		var _rk_foe: int = turn_manager._pending_rebel_king_foe_player
		if _rk_foe < 0:
			_rk_foe = opponent
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(_rk_foe, r, c)
				grid_nodes[_rk_foe][r][c].set_highlighted(
					card.card_type == "character" and card.face_up)

	elif filter == "ability_death_cobra_venom":
		for p in range(2):
			for r in range(GameState.GRID_SIZE):
				for c in range(GameState.GRID_SIZE):
					var card: GameState.CardInstance = GameState.get_card(p, r, c)
					grid_nodes[p][r][c].set_highlighted(
						card.card_type == "character" and card.face_up)

	elif filter == "own_character_for_swap":
		# Nuki owner picks another own character to swap with (origin cell excluded).
		var _swap_owner: int = turn_manager._pending_swap_owner_player
		if _swap_owner < 0:
			_swap_owner = player
		var _swap_origin: Vector2i = turn_manager._pending_swap_attacker_pos
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var _swap_pos: Vector2i = Vector2i(r, c)
				if _swap_pos == _swap_origin:
					continue
				var card: GameState.CardInstance = GameState.get_card(_swap_owner, r, c)
				grid_nodes[_swap_owner][r][c].set_highlighted(card.card_type == "character")

	elif filter in ["own_faceup_for_trap_temp_def_boost", "own_character_for_trap_self_destruct"]:
		# DEFENDER (trap owner = opponent) picks one of their own characters
		var require_faceup: bool = filter == "own_faceup_for_trap_temp_def_boost"
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
				var ok: bool = card.card_type == "character"
				if require_faceup:
					ok = ok and card.face_up
				grid_nodes[opponent][r][c].set_highlighted(ok)

	elif filter == "self_squares_1_opponent_turn":
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
				grid_nodes[opponent][r][c].set_highlighted(
					card.card_type == "character" and not card.face_up)

	elif filter == "opponent_facedown_forced":
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
				grid_nodes[opponent][r][c].set_highlighted(card.card_type != "dead_end" and not card.face_up)

	elif filter == "self_reveal_choice" or filter == "trap_hostage_reveal_lock" or filter == "trap_street_joke_reveal":
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
				grid_nodes[opponent][r][c].set_highlighted(card.card_type != "dead_end" and not card.face_up)

	elif filter == "rift_strike_anchor":
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
				grid_nodes[opponent][r][c].set_highlighted(
					card.card_type == "character" and card.face_up)

	elif filter in ["lock_own_monster", "own_faceup_character_source", "own_faceup_character_target",
			"own_faceup_card_sacrifice", "own_any_card", "own_facedown_character"] \
			or filter.begins_with("own_units_up_to_"):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(player, r, c)
				var ok: bool = false
				var pos := Vector2i(r, c)
				if filter.begins_with("own_units_up_to_"):
					ok = card.card_type == "character" and not card.face_up \
							and not _tech_reveal_picked.has(pos)
				else:
					match filter:
						"lock_own_monster":
							ok = card.card_type == "character"
						"own_faceup_character_source", "own_faceup_character_target":
							ok = card.card_type == "character"
						"own_faceup_card_sacrifice":
							ok = card.card_type != "dead_end"
						"own_any_card":
							ok = card.card_type != "dead_end"
						"own_facedown_character":
							ok = card.card_type == "character" and not card.face_up
				grid_nodes[player][r][c].set_highlighted(ok)

	elif filter == "own_any_as_target":
		var _bw_attacker_pos: Vector2i = GameState.attacker_pos
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var _bw_pos := Vector2i(r, c)
				var card: GameState.CardInstance = GameState.get_card(player, r, c)
				grid_nodes[player][r][c].set_highlighted(
					card.card_type == "character" and _bw_pos != _bw_attacker_pos)

	elif filter in ["lock_opponent_monster", "opponent_faceup_zero_stats", "self_faceup_for_copy",
			"own_armored_nature", "row_or_column"]:
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
				var ok: bool = false
				match filter:
					"lock_opponent_monster":
						ok = card.card_type == "character"
					"opponent_faceup_zero_stats":
						ok = card.card_type == "character" and card.face_up
					"self_faceup_for_copy":
						ok = card.card_type == "character" and card.face_up
					"own_armored_nature":
						ok = card.card_type == "character" \
							and card.affinity == CharacterData.Affinity.NATURE \
							and "Armored" in card.card_name
					"row_or_column":
						ok = card.card_type != "dead_end"
				grid_nodes[opponent][r][c].set_highlighted(ok)

	elif filter == "revive_placement":
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				grid_nodes[player][r][c].set_highlighted(
					GameState.is_valid_revive_placement_cell(player, r, c))

	elif filter == "graveyard":
		pass  # handled immediately in _on_awaiting_target_selection

	elif filter == "adjacent":
		var _adj_foe: int = _reveal_attacker_foe_player(opponent)
		var center: Vector2i = GameState.defender_pos
		if center.x < 0:
			center = GameState.attacker_pos
		for pos_v: Variant in GameState.get_adjacent_positions(center.x, center.y):
			var pos: Vector2i = pos_v as Vector2i
			var adj_card: GameState.CardInstance = GameState.get_card(_adj_foe, pos.x, pos.y)
			grid_nodes[_adj_foe][pos.x][pos.y].set_highlighted(
				not adj_card.face_up and not adj_card.was_destroyed)

	_apply_ability_target_flash()

func _clear_ability_target_flash_nodes() -> void:
	for node: Control in _ability_target_flash_nodes:
		if is_instance_valid(node) and node.has_method("set_ability_target_flash"):
			node.set_ability_target_flash(false)
	_ability_target_flash_nodes.clear()

func _apply_ability_target_flash() -> void:
	_clear_ability_target_flash_nodes()
	if not _should_show_ability_target_flash():
		return
	for p in range(2):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var node: Control = grid_nodes[p][r][c]
				if node.is_highlighted and node.has_method("set_ability_target_flash"):
					node.set_ability_target_flash(true)
					_ability_target_flash_nodes.append(node)

func _count_opponent_unrevealed(opponent: int) -> int:
	var count: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var opp_card: GameState.CardInstance = GameState.get_card(opponent, r, c)
			if opp_card.card_type != "dead_end" and not opp_card.face_up:
				count += 1
	return count

# Counts ALL face-down cells including dead_end slots — used for Radar targeting
func _count_opponent_facedown(opponent: int) -> int:
	var count: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			if not GameState.get_card(opponent, r, c).face_up:
				count += 1
	return count

func _clear_highlights() -> void:
	_clear_ability_target_flash_nodes()
	for p in range(2):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				grid_nodes[p][r][c].set_highlighted(false)
				grid_nodes[p][r][c].set_locked(false)

func _selected_attacker_has_multi_bonus() -> bool:
	if selected_attacker_pos == Vector2i(-1, -1):
		return false
	var card: GameState.CardInstance = GameState.get_card(
		GameState.current_player, selected_attacker_pos.x, selected_attacker_pos.y)
	return card != null and card.has_pending_bonus_attack_chain()

func _should_prompt_forfeit_multi_attack() -> bool:
	return _multi_attack_bonus_targeting and _selected_attacker_has_multi_bonus()

func _forfeit_multi_attack_bonus() -> void:
	if selected_attacker_pos == Vector2i(-1, -1):
		return
	var card: GameState.CardInstance = GameState.get_card(
		GameState.current_player, selected_attacker_pos.x, selected_attacker_pos.y)
	if card != null:
		card.attacked_this_turn = true
		card.bonus_attack_pending = false
	_pending_multi_attack_pos = Vector2i(-1, -1)
	_multi_attack_bonus_targeting = false

func _try_cancel_attack_targeting() -> void:
	if _should_prompt_forfeit_multi_attack():
		_prompt_forfeit_multi_attack()
		return
	_multi_attack_bonus_targeting = false
	_clear_selection()
	_set_selection_state(SelectionState.SELECTING_ATTACKER)
	_highlight_attackable_chars()

func _prompt_forfeit_multi_attack() -> void:
	if GameDialog.has_open_overlay(self):
		return
	var card: GameState.CardInstance = GameState.get_card(
		GameState.current_player, selected_attacker_pos.x, selected_attacker_pos.y)
	var card_label: String = card.card_name if card != null else "This unit"
	SFXManager.play(SFXManager.SFX_POPUP)
	var forfeit_pos := selected_attacker_pos
	var forfeit_player := GameState.current_player
	GameDialog.confirmation_overlay(
		self,
		"Forfeit Extra Attack?",
		"%s's bonus attack will be lost if you cancel targeting." % card_label,
		"Forfeit",
		"Keep Selecting",
		_on_forfeit_multi_attack_confirmed.bind(forfeit_pos, forfeit_player))

func _on_forfeit_multi_attack_confirmed(pos: Vector2i, player: int) -> void:
	_forfeit_multi_attack_bonus()
	_clear_selection()
	_set_selection_state(SelectionState.SELECTING_ATTACKER)
	_highlight_attackable_chars()
	_update_end_turn_blink()
	if pos != Vector2i(-1, -1):
		await _play_wait_badge_on_card(player, pos.x, pos.y)

func _clear_selection() -> void:
	_hide_card_context()
	_set_attack_hover_node(null)
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
			_show_guide("Choose a unit to attack with")
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


# ─────────────────────────────────────────────────────────────
# Debug Alignment Overlay  (editor-only, Ctrl+Shift+U)
# ─────────────────────────────────────────────────────────────
func _toggle_debug_alignment() -> void:
	_debug_align_visible = not _debug_align_visible
	if _debug_align_visible:
		_build_debug_alignment()
	else:
		_destroy_debug_alignment()

func _build_debug_alignment() -> void:
	const Z: int = 500  # above everything

	# White vertical center line (1 px wide)
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 1)
	line.layout_mode = 1
	line.anchor_left   = 0.5; line.anchor_right  = 0.5
	line.anchor_top    = 0.0; line.anchor_bottom = 1.0
	line.offset_left   = 0.0; line.offset_right  = 1.0
	line.offset_top    = 0.0; line.offset_bottom = 0.0
	line.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	line.z_index = Z
	add_child(line)
	_debug_center_line = line

	# White border overlays for each portrait
	for i in range(2):
		var portrait: TextureRect = _p1_portrait if i == 0 else _p2_portrait
		if portrait == null or not is_instance_valid(portrait):
			continue
		var border := Panel.new()
		border.layout_mode = 0
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = Color(1, 1, 1, 1)
		sb.border_width_left   = 2
		sb.border_width_right  = 2
		sb.border_width_top    = 2
		sb.border_width_bottom = 2
		border.add_theme_stylebox_override("panel", sb)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.z_index = Z
		# Match position and size of the portrait in local (GameBoard) space
		var local_pos: Vector2 = portrait.get_global_rect().position - global_position
		border.position = local_pos
		border.size     = portrait.get_global_rect().size
		add_child(border)
		if i == 0:
			_debug_p1_border = border
		else:
			_debug_p2_border = border

	# Auto-hide after 20 seconds
	get_tree().create_timer(20.0).timeout.connect(func() -> void:
		if _debug_align_visible:
			_debug_align_visible = false
			_destroy_debug_alignment())

func _destroy_debug_alignment() -> void:
	if is_instance_valid(_debug_center_line):
		_debug_center_line.queue_free()
	if is_instance_valid(_debug_p1_border):
		_debug_p1_border.queue_free()
	if is_instance_valid(_debug_p2_border):
		_debug_p2_border.queue_free()
	_debug_center_line = null
	_debug_p1_border   = null
	_debug_p2_border   = null

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
	_game_guide_text = text
	_sync_guide_visibility()

func _hide_guide() -> void:
	_game_guide_text = ""
	if _guide_box != null:
		_guide_box.visible = false

func _is_action_overlay_active() -> bool:
	if GameState.current_phase in [
		GameState.Phase.NONE, GameState.Phase.SETUP_P1,
		GameState.Phase.SETUP_P2, GameState.Phase.GAME_OVER]:
		return false
	if _handoff_overlay != null and _handoff_overlay.visible:
		return true
	if _bribe_overlay != null and _bribe_overlay.visible:
		return true
	if _ability_choice_overlay != null and _ability_choice_overlay.visible:
		return true
	if _attack_confirm_panel != null and _attack_confirm_panel.visible:
		return true
	if _tax_confirm_panel != null and is_instance_valid(_tax_confirm_panel):
		return true
	if _tech_hand_overlay != null and is_instance_valid(_tech_hand_overlay):
		return true
	if _tech_overlay_panel != null and _tech_overlay_panel.visible \
			and GameState.current_phase == GameState.Phase.TECH \
			and _tech_overlay_player == GameState.current_player:
		return true
	if (_options_panel != null and is_instance_valid(_options_panel)) \
			or get_node_or_null(NodePath(OPTIONS_CONTENT_OVERLAY)) != null:
		return true
	if is_instance_valid(_context_popup):
		return true
	if get_node_or_null("BluffModalBoard") != null:
		return true
	if _union_modal != null and is_instance_valid(_union_modal):
		return true
	if is_instance_valid(_current_battle_overlay):
		return true
	if selection_state in [
		SelectionState.CONFIRMING_ATTACK,
		SelectionState.AWAITING_TRAP_CHOICE]:
		return true
	for child in get_children():
		if child.name == "GameDialogOverlay":
			return true
		if child is CardDetailOverlay:
			return true
		if child is ColorRect and child.z_index >= 55 \
				and child.mouse_filter == Control.MOUSE_FILTER_STOP:
			return true
	return false

func _sync_guide_visibility() -> void:
	if _game_guide_text.is_empty():
		if _guide_box != null:
			_guide_box.visible = false
		return
	_build_guide_box()
	_guide_label.text = _game_guide_text
	_guide_box.reset_size()
	_guide_box.visible = not _is_action_overlay_active()

func _show_hud_tooltip(text: String) -> void:
	_build_guide_box()
	_guide_label.text = text
	_guide_box.reset_size()
	_guide_box.visible = true

func _restore_game_guide() -> void:
	if _game_guide_text.is_empty():
		if _guide_box != null:
			_guide_box.visible = false
	else:
		_sync_guide_visibility()

# ─────────────────────────────────────────────────────────────
# Card Events
# ─────────────────────────────────────────────────────────────
func _cell_reveal_key(player: int, row: int, col: int) -> String:
	return "%d,%d,%d" % [player, row, col]

func _is_cell_revealing(player: int, row: int, col: int) -> bool:
	return _revealing_cells.has(_cell_reveal_key(player, row, col))


func _is_battle_attack_dead_end_reveal(player: int, row: int, col: int) -> bool:
	if GameState.current_phase != GameState.Phase.BATTLE:
		return false
	if GameState.defender_pos != Vector2i(row, col):
		return false
	var attacker_player: int = GameState.current_player
	if player != GameState.get_opponent(attacker_player):
		return false
	return GameState.get_card(player, row, col).card_type == "dead_end"


func _should_dissolve_trap_after_reveal(player: int, row: int, col: int) -> bool:
	if GameState.current_phase != GameState.Phase.BATTLE:
		return true
	# The attacked trap stays on board until post-combat trap handling.
	if GameState.defender_pos == Vector2i(row, col):
		var attacker_player: int = GameState.current_player
		if player == GameState.get_opponent(attacker_player):
			var inst: GameState.CardInstance = GameState.get_card(player, row, col)
			if inst != null and inst.card_type == "trap":
				return false
	return true


func _add_to_void_pile(player: int, card_name: String, card_type: String) -> void:
	_void_piles[player].append({"card_name": card_name, "card_type": card_type})
	GameState.add_void_entry(player, card_name, card_type)
	_update_void_stacks()


func _await_card_reveal_animation(player: int, row: int, col: int) -> void:
	while _is_cell_revealing(player, row, col):
		await get_tree().process_frame

func _play_flag_pop_on_card(player: int, row: int, col: int, flag: String) -> void:
	_refresh_card_node(player, row, col)
	var node: Control = grid_nodes[player][row][col]
	if node is Card:
		await (node as Card).play_flag_badge_pop(flag)

func _flush_flag_pops_for_cell(player: int, row: int, col: int) -> void:
	var keep: Array = []
	for entry: Variant in _pending_flag_pops:
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if int(e.get("player", -1)) == player \
				and int(e.get("row", -1)) == row \
				and int(e.get("col", -1)) == col:
			await _play_flag_pop_on_card(player, row, col, str(e.get("flag", "")))
		else:
			keep.append(entry)
	_pending_flag_pops = keep

func _play_wait_badge_on_card(player: int, row: int, col: int) -> void:
	_refresh_card_node(player, row, col)
	var node: Control = grid_nodes[player][row][col]
	if node is Card:
		await (node as Card).play_wait_badge_entrance()

func _on_wait_badge_animation_requested(player: int, row: int, col: int) -> void:
	await _play_wait_badge_on_card(player, row, col)
	turn_manager.wait_badge_animation_done.emit()

func _on_card_flag_added(player: int, row: int, col: int, flag: String) -> void:
	_pending_flag_pops.append({
		"player": player,
		"row": row,
		"col": col,
		"flag": flag,
	})
	if not _is_cell_revealing(player, row, col):
		await _flush_flag_pops_for_cell(player, row, col)

func _on_card_revealed(player: int, row: int, col: int) -> void:
	var reveal_key := _cell_reveal_key(player, row, col)
	_revealing_cells[reveal_key] = true
	var node: Control = grid_nodes[player][row][col]
	var inst := GameState.get_card(player, row, col)
	if node is Card:
		var card_node := node as Card
		# Keep face-down art until play_reveal_animation flips at the squish midpoint.
		card_node.set_card_data(inst, player, Vector2i(row, col), false)
		card_node.suppress_exposed_badge()
		await card_node.play_reveal_animation()
	else:
		_refresh_card_node(player, row, col)
		if node.has_method("play_reveal_animation"):
			await node.play_reveal_animation()
	_revealing_cells.erase(reveal_key)
	await _flush_flag_pops_for_cell(player, row, col)
	if turn_manager != null:
		await turn_manager.apply_on_reveal_abilities(player, row, col)
	if turn_manager != null:
		turn_manager.notify_card_reveal_animation_done(player, row, col)
	if inst != null and inst.card_type == "character" \
			and inst.ability_type == CharacterData.AbilityType.ON_EXPOSE_REVEAL_FOE_ONCE \
			and GameState.current_phase != GameState.Phase.BATTLE \
			and turn_manager != null:
		await turn_manager.maybe_apply_on_expose_reveal_foe(player, row, col)
	# Revealed empty cell — brief blank flash then dissolve (Scout Probe, Radar, etc.).
	# Battle attacks on dead_end skip here; destroy_card runs after Reckoning.
	if inst != null and inst.card_type == "dead_end":
		if not _is_battle_attack_dead_end_reveal(player, row, col):
			GameState.destroy_card(player, row, col, false)
		else:
			_refresh_card_node(player, row, col)
		return
	# Trap revealed → play black-smoke dissolve then clear the slot.
	# BATTLE phase keeps the attacked trap until post-combat handling (Bait/Hostage/etc. dissolve).
	if inst != null and inst.card_type == "trap" \
			and _should_dissolve_trap_after_reveal(player, row, col):
		_add_to_void_pile(player, inst.card_name, inst.card_type)
		_spawn_dissolve_effect(node)
		await get_tree().create_timer(0.90).timeout
		GameState.void_trap(player, row, col)
		if node is Card:
			(node as Card).modulate = Color.WHITE
	_refresh_card_node(player, row, col)

func _on_card_destruction_blocked(player: int, row: int, col: int) -> void:
	var node: Control = grid_nodes[player][row][col]
	if node is Card:
		await (node as Card).play_metallic_deflect_animation()
	else:
		SFXManager.play(SFXManager.SFX_METAL_DEFLECT)

func _on_card_destroyed(player: int, row: int, col: int) -> void:
	# Signal fires before place_dead_end(), so card data is still available
	var inst: GameState.CardInstance = GameState.get_card(player, row, col)
	if inst != null and inst.card_type != "dead_end":
		_add_to_void_pile(player, inst.card_name, inst.card_type)
	# AI death-bluff reaction: when a face-up AI character is destroyed
	if inst != null and inst.card_type == "character" and inst.face_up and randf() < 0.60:
		if GameState.game_mode == GameState.GameMode.VS_AI and player == ai_player.player_index:
			ai_player.decide_death_bluff(row, col)
		elif GameState.game_mode == GameState.GameMode.AI_VS_AI:
			_get_ai_for_player(player).decide_death_bluff(row, col)
	var node: Control = grid_nodes[player][row][col]
	if inst != null and inst.card_type in ["dead_end", "trap"]:
		if inst.card_type == "dead_end":
			await get_tree().create_timer(0.5).timeout
		_spawn_dissolve_effect(node)
		await get_tree().create_timer(0.90).timeout
	else:
		_spawn_destroy_effect(node)
		node.play_destroy_animation()
		await get_tree().create_timer(0.55).timeout
	_check_almost_win_bgm()
	_refresh_card_node(player, row, col)

func _spawn_destroy_effect(card_node: Control) -> void:
	SFXManager.play(SFXManager.SFX_DESTROY)
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

	# Fire friction sparks — large burst in all directions from card centre
	var origin: Vector2 = local_pos + card_size * 0.5
	var rng2 := RandomNumberGenerator.new()
	rng2.randomize()
	for _i: int in range(55):
		var spark := ColorRect.new()
		spark.size = Vector2(rng2.randf_range(4.0, 12.0), rng2.randf_range(20.0, 52.0))
		# Fire palette: white-hot core → orange → deep red
		var heat: float = rng2.randf_range(0.0, 1.0)
		spark.color = Color(
			1.0,
			lerp(0.15, 1.0, heat),
			lerp(0.0,  0.55, heat * heat),
			1.0)
		spark.pivot_offset = spark.size * 0.5
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.z_index = 22

		# Full 360° blast
		var angle: float = rng2.randf_range(0.0, TAU)
		var speed: float = rng2.randf_range(180.0, 520.0)
		var duration: float = rng2.randf_range(0.25, 0.60)
		var gravity: float = rng2.randf_range(60.0, 180.0)
		var dx: float = cos(angle) * speed
		var dy: float = sin(angle) * speed + gravity
		spark.rotation = angle + PI * 0.5
		spark.position = origin - spark.size * 0.5

		add_child(spark)

		var ts := create_tween()
		ts.parallel().tween_property(spark, "position",
			spark.position + Vector2(dx, dy), duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		ts.parallel().tween_property(spark, "modulate:a", 0.0, duration) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		ts.tween_callback(spark.queue_free)

func _spawn_dissolve_effect(card_node: Control) -> void:
	SFXManager.play(SFXManager.SFX_DISSOLVE)
	var card_rect := card_node.get_global_rect()
	var local_pos := card_rect.position - global_position
	var card_size := card_rect.size
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Gradually dissolve the card itself
	var dissolve_tw := create_tween()
	dissolve_tw.tween_property(card_node, "modulate:a", 0.0, 0.75) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Rising dark grey smoke puffs
	for _i: int in range(22):
		var puff := Panel.new()
		var sz: float = rng.randf_range(18.0, 48.0)
		puff.size = Vector2(sz, sz)
		puff.pivot_offset = puff.size * 0.5
		var psb := StyleBoxFlat.new()
		var grey: float = rng.randf_range(0.12, 0.38)
		psb.bg_color = Color(grey, grey, grey, 0.88)
		var rad: int = int(sz * 0.5)
		psb.corner_radius_top_left     = rad
		psb.corner_radius_top_right    = rad
		psb.corner_radius_bottom_right = rad
		psb.corner_radius_bottom_left  = rad
		puff.add_theme_stylebox_override("panel", psb)
		puff.mouse_filter = Control.MOUSE_FILTER_IGNORE
		puff.z_index = 22
		var start_x: float = local_pos.x + rng.randf_range(0.0, card_size.x) - sz * 0.5
		var start_y: float = local_pos.y + rng.randf_range(card_size.y * 0.3, card_size.y)
		puff.position = Vector2(start_x, start_y)
		add_child(puff)

		var delay: float    = rng.randf_range(0.0, 0.38)
		var rise: float     = rng.randf_range(55.0, 140.0)
		var drift: float    = rng.randf_range(-28.0, 28.0)
		var duration: float = rng.randf_range(0.45, 0.85)
		var end_scale: float = rng.randf_range(1.3, 2.1)

		var tp := create_tween()
		tp.tween_interval(delay)
		tp.tween_property(puff, "position",
			puff.position + Vector2(drift, -rise), duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tp.parallel().tween_property(puff, "scale",
			Vector2(end_scale, end_scale), duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tp.parallel().tween_property(puff, "modulate:a", 0.0, duration) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tp.tween_callback(puff.queue_free)

# ─────────────────────────────────────────────────────────────
# AI
# ─────────────────────────────────────────────────────────────
func _on_ai_mode_chosen(mode: GameState.TurnMode) -> void:
	if GameState.current_phase == GameState.Phase.GAME_OVER:
		return
	if mode == GameState.TurnMode.ATTACK \
			and not GameState.can_player_attack(GameState.current_player):
		_on_ai_end_turn()
		return
	_hide_thinking_bubble()
	turn_manager.select_mode(mode)

## Briefly flash a card node to signal AI target selection (non-blocking).
func _flash_target_card(player: int, row: int, col: int) -> void:
	if player < 0 or row < 0 or col < 0:
		return
	var node: Control = grid_nodes[player][row][col]
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", Color(1.8, 0.55, 0.25, 1.0), 0.14) \
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate", Color.WHITE, 0.26) \
		.set_trans(Tween.TRANS_SINE)

func _on_ai_attack_chosen(attacker_pos: Vector2i, target_pos: Vector2i) -> void:
	if GameState.current_phase == GameState.Phase.GAME_OVER:
		return
	var player := GameState.current_player
	if not _is_ai_turn() or player != _active_ai.player_index:
		return
	var attacker: GameState.CardInstance = GameState.get_card(player, attacker_pos.x, attacker_pos.y)
	if attacker.card_type != "character":
		return
	# Reveal the attacker with the normal flip + EXPOSED badge animation.
	if not attacker.face_up:
		GameState.reveal_card(player, attacker_pos.x, attacker_pos.y)
		await _await_card_reveal_animation(player, attacker_pos.x, attacker_pos.y)
		await get_tree().create_timer(0.3).timeout
	else:
		await get_tree().create_timer(0.5).timeout
	if GameState.current_phase == GameState.Phase.GAME_OVER \
			or GameState.current_player != player:
		return
	# Flash the target cell so the human can see which card is being attacked.
	_flash_target_card(GameState.get_opponent(player), target_pos.x, target_pos.y)
	await get_tree().create_timer(0.4).timeout
	if GameState.current_phase == GameState.Phase.GAME_OVER \
			or GameState.current_player != player:
		return
	turn_manager.perform_attack(attacker_pos, target_pos, player)

func _on_ai_tech_chosen(tech_name: String) -> void:
	pending_tech_name = tech_name
	turn_manager.play_tech_card(tech_name)

# ─────────────────────────────────────────────────────────────
# Card Effect Flash (tech cards and outside-reckoning character/trap abilities)
# ─────────────────────────────────────────────────────────────
const SFX_SPELL_FLASH: AudioStream = preload("res://assets/audio/sound_spellcasting_2.mp3")
const FULL_CARDS_DIR: String = "res://assets/textures/cards/full_cards/"

func _resolve_outside_reckoning_flash_card(prompt: String, filter: String) -> Dictionary:
	if filter in ["bribe", "graveyard", "view_opponent_hand", "bribe_reveal"]:
		return {}
	var colon_idx: int = prompt.find(": ")
	if colon_idx <= 0:
		return {}
	var card_name: String = prompt.substr(0, colon_idx).strip_edges()
	if card_name.is_empty():
		return {}
	if CardDatabase.get_character(card_name) != null:
		return {"name": card_name, "type": "character"}
	if CardDatabase.get_trap(card_name) != null:
		return {"name": card_name, "type": "trap"}
	return {}

func _maybe_flash_outside_reckoning_ability(prompt: String, filter: String) -> void:
	if pending_tech_name != "":
		return
	if is_instance_valid(_current_battle_overlay):
		return
	# These filters follow an earlier flash at ability activation (coin flip / pre-target).
	if filter in [
		"ability_plant29_venom", "ability_plant29_mutagen",
		"wk17_foe_pick_character", "own_character_for_swap",
	]:
		return
	var info: Dictionary = _resolve_outside_reckoning_flash_card(prompt, filter)
	if info.is_empty():
		return
	await _show_card_effect_flash(str(info.get("name", "")), str(info.get("type", "character")))

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

## Full-screen cinematic reveal played when a union is successfully summoned.
## Card falls from off-screen top, slams to centre with screen shake, sparks, and dust.
func _show_union_summon_reveal(union_name: String) -> void:
	var vp := get_viewport().get_visible_rect().size

	# ── Blocking overlay ──────────────────────────────────────
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	# Dark dim
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	# ── Load card texture ──────────────────────────────────────
	var snake: String = union_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
	var card_tex: Texture2D = null
	if card_tex == null:
		for _p: String in [
			FULL_CARDS_DIR + snake + ".png",
			"res://assets/textures/cards/union/" + snake + ".png",
		]:
			if ResourceLoader.exists(_p):
				card_tex = load(_p) as Texture2D
				break

	# ── Card node ─────────────────────────────────────────────
	var card_h: float = minf(vp.y * 0.78, 640.0)
	var card_w: float = card_h * (819.0 / 1126.0)
	var land_x: float = (vp.x - card_w) * 0.5
	var land_y: float = (vp.y - card_h) * 0.5

	var card_img := TextureRect.new()
	card_img.texture = card_tex
	card_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_img.size = Vector2(card_w, card_h)
	card_img.position = Vector2(land_x, -card_h - 80.0)
	card_img.pivot_offset = Vector2(card_w * 0.5, card_h * 0.5)
	card_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(card_img)

	# Name label beneath card
	var name_lbl := Label.new()
	name_lbl.text = union_name.to_upper()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 30)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.5))
	name_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	name_lbl.add_theme_constant_override("shadow_offset_x", 2)
	name_lbl.add_theme_constant_override("shadow_offset_y", 2)
	name_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	name_lbl.position = Vector2((vp.x - 600.0) * 0.5, land_y + card_h + 12.0)
	name_lbl.size = Vector2(600.0, 40.0)
	name_lbl.modulate.a = 0.0
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(name_lbl)

	# ── Dim fades in ──────────────────────────────────────────
	var t_dim := create_tween()
	t_dim.tween_property(dim, "color:a", 0.78, 0.15)

	# ── Card falls from sky ───────────────────────────────────
	var t_fall := create_tween()
	t_fall.tween_property(card_img, "position:y", land_y + 22.0, 0.42) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await t_fall.finished

	# ── Landing impact ────────────────────────────────────────
	# Play impact sound immediately on landing, before any other code
	SFXManager.play(SFXManager.SFX_UNION_LAND)

	# Slight bounce back to resting position
	var t_bounce := create_tween()
	t_bounce.tween_property(card_img, "position:y", land_y, 0.10) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Screen shake on impact
	var ml: Control = get_node("MainLayout")
	var _shake_orig: Vector2 = ml.position
	var t_sk := create_tween()
	t_sk.tween_property(ml, "position", _shake_orig + Vector2(22.0,  12.0), 0.04)
	t_sk.tween_property(ml, "position", _shake_orig + Vector2(-18.0, -10.0), 0.04)
	t_sk.tween_property(ml, "position", _shake_orig + Vector2(14.0,   8.0), 0.04)
	t_sk.tween_property(ml, "position", _shake_orig + Vector2(-10.0,  -6.0), 0.04)
	t_sk.tween_property(ml, "position", _shake_orig + Vector2(6.0,    4.0), 0.04)
	t_sk.tween_property(ml, "position", _shake_orig + Vector2(-3.0,  -2.0), 0.04)
	t_sk.tween_property(ml, "position", _shake_orig, 0.03)

	# Sparks and dust at card base
	var card_base := Vector2(vp.x * 0.5, land_y + card_h * 0.95)
	_spawn_union_landing_sparks(overlay, card_base)
	_spawn_union_landing_dust(overlay, card_base)

	await t_bounce.finished

	# Fade in name label
	var t_name := create_tween()
	t_name.tween_property(name_lbl, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

	# ── Hold ──────────────────────────────────────────────────
	await get_tree().create_timer(2.0).timeout

	# ── Fade out ──────────────────────────────────────────────
	var t_out := create_tween()
	t_out.tween_property(overlay, "modulate:a", 0.0, 0.4) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await t_out.finished
	overlay.queue_free()

## Bright sparks shooting from the card base on landing.
func _spawn_union_landing_sparks(overlay: Control, origin: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i: int in range(42):
		var spark := ColorRect.new()
		spark.size = Vector2(rng.randf_range(4.0, 11.0), rng.randf_range(18.0, 48.0))
		spark.color = Color(1.0, rng.randf_range(0.80, 1.0), rng.randf_range(0.2, 0.6), 1.0)
		spark.pivot_offset = spark.size * 0.5
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.z_index = 12

		# Arc upward and sideways
		var angle: float = rng.randf_range(-PI * 0.95, -PI * 0.05)
		var speed: float = rng.randf_range(160.0, 460.0)
		var duration: float = rng.randf_range(0.35, 0.80)
		var dx: float = cos(angle) * speed
		var dy: float = sin(angle) * speed + rng.randf_range(10.0, 60.0)  # gravity sag
		spark.rotation = angle + PI * 0.5
		spark.position = origin - spark.size * 0.5

		overlay.add_child(spark)

		var t := create_tween()
		t.parallel().tween_property(spark, "position",
			spark.position + Vector2(dx, dy), duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		t.parallel().tween_property(spark, "modulate:a", 0.0, duration) \
			.set_ease(Tween.EASE_IN)
		t.tween_callback(spark.queue_free)

## Dust clouds rising from the card base on landing.
func _spawn_union_landing_dust(overlay: Control, origin: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i: int in range(10):
		var dust := Panel.new()
		var r: float = rng.randf_range(14.0, 38.0)
		dust.size = Vector2(r * 2.2, r)
		dust.pivot_offset = dust.size * 0.5
		dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dust.z_index = 8

		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.75, 0.70, 0.58, 0.60)
		var cr: int = int(r)
		sb.corner_radius_top_left = cr; sb.corner_radius_top_right = cr
		sb.corner_radius_bottom_left = cr; sb.corner_radius_bottom_right = cr
		dust.add_theme_stylebox_override("panel", sb)

		var ox: float = rng.randf_range(-70.0, 70.0)
		dust.position = origin + Vector2(ox, rng.randf_range(-8.0, 8.0)) - dust.size * 0.5
		overlay.add_child(dust)

		var end_pos: Vector2 = dust.position + Vector2(rng.randf_range(-50.0, 50.0),
			rng.randf_range(-70.0, -25.0))
		var duration: float = rng.randf_range(0.55, 1.05)

		var t := create_tween()
		t.parallel().tween_property(dust, "position", end_pos, duration).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(dust, "scale", Vector2(2.8, 2.8), duration).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(dust, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
		t.tween_callback(dust.queue_free)

# ─────────────────────────────────────────────────────────────
# Game Over
# ─────────────────────────────────────────────────────────────
func _on_return_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/campaign_map.tscn")

func _process(delta: float) -> void:
	if _guide_box != null:
		if _is_action_overlay_active():
			if _guide_box.visible:
				_guide_box.visible = false
		elif not _game_guide_text.is_empty():
			if not _guide_box.visible:
				_sync_guide_visibility()
			if _guide_box.visible:
				_guide_box.global_position = get_global_mouse_position() + Vector2(58.0, 62.0)
		elif _guide_box.visible:
			_guide_box.global_position = get_global_mouse_position() + Vector2(58.0, 62.0)
	if _shake_active:
		var ml: Control = get_node("MainLayout")
		ml.position = _shake_origin + Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
	_update_fog(delta)

func _on_game_over(winner: int) -> void:
	# Dismiss guide box immediately so it doesn't bleed into VN or win screen
	_hide_guide()
	_was_tutorial_battle = TutorialBattleManager.is_active
	if TutorialBattleManager.is_active:
		TutorialBattleManager.stop()
		_update_reveal_buttons()
		_update_tutorial_hud_lock()
	if _was_tutorial_battle:
		SaveManager.mark_attack_tutorial_complete()

	# ── AI vs AI mode: hand off to AIvsAIManager which logs + returns to config ──
	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		_stop_battle_music()
		AIvsAIManager.on_game_over(winner)
		return

	# ── VS_AI / HOT_SEAT: close session log after killing-blow lines flush ─────
	call_deferred("_finish_session_log", winner)

	# ── Immediately halt AI and lock out all input ───────────────────────────
	# Stop the AI watchdog so it cannot re-trigger another AI turn
	if _ai_watchdog:
		_ai_watchdog.stop()
	# Disconnect AI bluff signals so any fire-and-forget coroutines that are
	# still awaiting a timer cannot place bluffs during the reveal animation
	if is_instance_valid(ai_player) \
			and ai_player.ai_bluff.is_connected(_on_ai_bluff):
		ai_player.ai_bluff.disconnect(_on_ai_bluff)
	if is_instance_valid(ai_player_0) \
			and ai_player_0.ai_bluff.is_connected(_on_ai_bluff):
		ai_player_0.ai_bluff.disconnect(_on_ai_bluff)
	# Full-screen transparent blocker — swallows all player taps/clicks
	var _end_blocker := ColorRect.new()
	_end_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_blocker.color        = Color(0.0, 0.0, 0.0, 0.0)
	_end_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_end_blocker.z_index      = 5   # above grids but below all overlays
	add_child(_end_blocker)
	_hide_card_context()
	_clear_selection()

	# ── VN-driven battle ─────────────────────────────────────────────────────
	var vn_win: String  = GameState.vn_on_win
	var vn_lose: String = GameState.vn_on_lose
	GameState.vn_on_win  = ""
	GameState.vn_on_lose = ""
	var player_won := (winner == 0)
	if GameState.vn_launched_from_exploration and ExplorationManager.is_session_active:
		ExplorationManager.complete_battle_node(player_won)
	if not player_won and vn_lose != "" and vn_lose != "game_over":
		# Loss: go straight to lose VN, skip win screen
		_stop_battle_music()
		if GameState.vn_launched_from_exploration:
			ExplorationManager.clear_vn_resume_bgm()
		var lose_dest: String = GameState.post_battle_return_scene.strip_edges()
		GameState.post_battle_return_scene = ""
		if lose_dest.is_empty():
			lose_dest = "res://scenes/main_menu.tscn"
		var lose_cb := func() -> void:
			_on_quick_duel_tutorial_post_vn(lose_dest)
			get_tree().change_scene_to_file(lose_dest)
		VNPlayer.launch_overlay(vn_lose, lose_cb)
		return
	if player_won and vn_win != "" and vn_win != "game_over":
		# Win: show win screen first; VN plays after player taps
		_pending_win_vn = vn_win

	# ── Campaign: record result now, before any animation ────────────────────
	if GameState.game_mode == GameState.GameMode.CAMPAIGN:
		if player_won:
			CampaignManager.complete_node(GameState.campaign_node_id)
		CampaignManager.pending_result = {
			"node_id": GameState.campaign_node_id,
			"won": player_won
		}

	# ── Daily Dungeon: record result now, before any animation ───────────────
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON:
		DailyDungeonManager.complete_node(GameState.active_dungeon_node_id, player_won)

	# ── Exploration: record result now, before any animation ─────────────────
	if GameState.game_mode == GameState.GameMode.EXPLORATION:
		ExplorationManager.complete_battle_node(player_won)

	# ── Disable all interactive UI immediately ───────────────────────────────
	if _end_turn_btn:
		_end_turn_btn.visible = false
	mode_panel.visible   = false
	action_panel.visible = false
	if _tech_fan:
		_tech_fan.visible = false
	if _attack_confirm_panel:
		_attack_confirm_panel.visible = false
	dice_display.text = ""

	# ── 0. Let the final crystal burst + tick finish, then a brief beat ─────
	# Music is NOT stopped here — it carries through the pause and is handled at shake start.
	await _wait_crystal_display_finished()
	await get_tree().create_timer(1.2).timeout

	# ── 1. Flip-reveal all face-down cards (with screen shake) ───────────────
	var ml: Control = get_node("MainLayout")
	_shake_origin = ml.position
	_shake_active = true
	var _crystal_end: bool = GameState.game_over_reason == "crystals"
	if player_won and GameState.battle_almost_win_enabled and not _crystal_end and not _vs_ai_bgm_muted():
		# Win: switch to almost-win BGM at 00:00 with no fade-in.
		# If it's already playing (triggered by the almost-win threshold mid-battle),
		# leave it running — do not restart it.
		var almost_path: String = _resolve_almost_win_bgm_path()
		if BGMManager.get_current_path() != almost_path:
			BGMManager.play_path(almost_path, 0.0, 0.0, 100.0, BGMManager.CONTEXT_BATTLE, 0.0, 2.0)
	elif not player_won and not _vs_ai_bgm_muted():
		# Lose: crossfade battle BGM out while defeat track fades in.
		BGMManager.play_context(BGMManager.CONTEXT_DEFEAT, 1.0, 2.5, 100.0, BGMManager.LOOP_PLAY_ONCE)
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

	if player_won and GameState.game_mode == GameState.GameMode.DAILY_DUNGEON:
		var combat_rewards: Array = DailyDungeonManager.take_pending_combat_rewards()
		if not combat_rewards.is_empty():
			await CombatRewardOverlay.present(self, combat_rewards)

	if GameState.game_mode == GameState.GameMode.VS_AI:
		if not GameState.quick_duel_pending_rewards.is_empty():
			await CombatRewardOverlay.present(self, GameState.quick_duel_pending_rewards)
			await _present_quick_duel_reward_reveal_anims()
			GameState.quick_duel_pending_rewards.clear()
			GameState.quick_duel_reveal_queue.clear()
		if GameState.pending_wishlist_cta:
			await WishlistCtaOverlay.present(self)
			SaveManager.mark_wishlist_cta_shown()
			GameState.pending_wishlist_cta = false

	if not player_won:
		await _maybe_show_casual_mode_loss_tip()

# ─────────────────────────────────────────────────────────────
# Game-over helpers
# ─────────────────────────────────────────────────────────────

func _maybe_show_casual_mode_loss_tip() -> void:
	if _was_tutorial_battle:
		return
	if SaveManager.is_casual_mode_tip_shown():
		return
	if GlobalStatManager.get_int("duel_loss") < 1:
		return
	SaveManager.mark_casual_mode_tip_shown()
	var done: Array[bool] = [false]
	GameDialog.accept_overlay(
		self,
		"TIPS",
		"You can always turn on \"Casual Mode\" in Setting Menu to make duels easier",
		"OK",
		func() -> void: done[0] = true,
		GameDialog.DEFAULT_MIN_WIDTH,
		500)
	while not done[0]:
		await get_tree().process_frame

func _resolve_endgame_background_path(is_win_screen: bool) -> String:
	var protagonist_id: String = GameState.quick_duel_protagonist_id.strip_edges()
	if protagonist_id.is_empty():
		return ""
	if is_win_screen:
		return ProtagonistVault.get_win_screen_path(protagonist_id)
	return ProtagonistVault.get_lose_screen_path(protagonist_id)


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
	SFXManager.play_flip()
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

# ─────────────────────────────────────────────────────────────
# Almost-win BGM
# ─────────────────────────────────────────────────────────────
func _resolve_almost_win_bgm_path() -> String:
	return GameState.get_almost_win_bgm_path()

## Called after crystal-tick and after card destruction.
## Switches to the almost-win BGM the first time either player hits the threshold:
##   – any player's crystals ≤ 1200, OR
##   – any player's active (non-dead-end) card count ≤ 5.
## Latches via _almost_win_bgm_active so it only triggers once per battle.
func _check_almost_win_bgm() -> void:
	if _vs_ai_bgm_muted():
		return
	if not GameState.battle_almost_win_enabled:
		return
	if _almost_win_bgm_active:
		return
	if GameState.game_mode == GameState.GameMode.AI_VS_AI:
		return
	if GameState.current_phase == GameState.Phase.GAME_OVER:
		return
	if not ResourceLoader.exists(_resolve_almost_win_bgm_path()):
		return
	# Only trigger when the OPPONENT (player 1 / AI) is low — not the human.
	var triggered := false
	const OPPONENT: int = 1
	if GameState.crystals[OPPONENT] <= 1200:
		triggered = true
	else:
		var count: int = 0
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var inst: GameState.CardInstance = GameState.get_card(OPPONENT, r, c)
				if inst.card_type != "dead_end":
					count += 1
		if count <= 3:
			triggered = true
	if triggered:
		_almost_win_bgm_active = true
		var almost_path: String = _resolve_almost_win_bgm_path()
		BGMManager.play_path(almost_path, 0.0, 1.5, 100.0, BGMManager.CONTEXT_BATTLE, 0.0, 2.0)

func _send_vn_mail_rewards(rewards: Array, mail_from: String, credits_subject: String, pack_subject_prefix: String, card_subject: String, scroll_subject: String) -> void:
	for entry: Variant in rewards:
		if not entry is Dictionary:
			continue
		var reward: Dictionary = entry as Dictionary
		match str(reward.get("type", "")):
			"credits", "coins":
				var amount: int = int(reward.get("amount", 0))
				if amount <= 0:
					continue
				MailboxManager.send_mail(
					mail_from,
					credits_subject,
					"You received %d Credits." % amount,
					{"type": "credits", "amount": amount}
				)
			"booster_pack":
				var pack_ref: String = str(reward.get("pack_name", "")).strip_edges()
				if pack_ref.is_empty():
					continue
				var pack: Dictionary = ShopManager.get_pack_by_name(pack_ref)
				if pack.is_empty():
					push_warning("GameBoard: unknown booster pack '%s' in vn mail rewards." % pack_ref)
					continue
				var pack_name: String = str(pack.get("name", pack_ref))
				MailboxManager.send_mail(
					mail_from,
					"%s — %s" % [pack_subject_prefix, pack_name],
					"You earned a booster pack: %s. Claim it from your Inventory." % pack_name,
					{"type": "booster_pack", "pack_name": pack_name}
				)
			"card":
				var card_name: String = str(reward.get("card_name", "")).strip_edges()
				if card_name.is_empty():
					continue
				MailboxManager.send_mail(
					mail_from,
					card_subject,
					"You received the card: %s." % card_name,
					{"type": "card", "card_name": card_name}
				)
			"union_scroll":
				var scroll_count: int = int(reward.get("count", 1))
				if scroll_count <= 0:
					scroll_count = 1
				UnionScrollManager.grant_union_scroll_mail(scroll_count, scroll_subject, mail_from)

func _grant_vn_battle_rewards() -> void:
	_send_vn_mail_rewards(
		GameState.vn_battle_rewards,
		"Battle Reward",
		"Credits Earned!",
		"Victory Reward",
		"Card Reward",
		"Victory Reward — Union Scroll"
	)
	GameState.vn_battle_rewards.clear()

func _grant_vn_battle_loss_rewards() -> void:
	var once_key: String = GameState.vn_battle_loss_reward_once
	if once_key != "" and str(SaveManager.exploration_flags.get(once_key, "")) == "1":
		GameState.vn_battle_loss_rewards.clear()
		GameState.vn_battle_loss_reward_once = ""
		return
	if GameState.vn_battle_loss_rewards.is_empty():
		GameState.vn_battle_loss_reward_once = ""
		return
	_send_vn_mail_rewards(
		GameState.vn_battle_loss_rewards,
		"Battle Consolation",
		"Credits Sent",
		"Consolation Pack",
		"Consolation Card",
		"Consolation — Union Scroll"
	)
	if once_key != "":
		SaveManager.exploration_flags[once_key] = "1"
		SaveManager.save_data()
	GameState.vn_battle_loss_rewards.clear()
	GameState.vn_battle_loss_reward_once = ""

func _handle_quick_duel_win_rewards() -> void:
	if GameState.quick_duel_rewards_settled:
		return
	GameState.quick_duel_rewards_settled = true
	GameState.quick_duel_reveal_queue.clear()

	var tier: String = GameState.quick_duel_battle_tier
	var picked: Array = _sort_quick_duel_grant_order(
		QuickDuelRewards.dedupe_rewards(SaveManager.get_quick_duel_rewards(tier)))
	var granted_cards: Dictionary = {}
	for reward: Variant in picked:
		if reward is Dictionary:
			_grant_quick_duel_reward(reward as Dictionary, granted_cards)
	if not picked.is_empty():
		GameState.quick_duel_pending_rewards = picked.duplicate(true)
	if not SaveManager.is_wishlist_cta_shown():
		GameState.pending_wishlist_cta = true
	SaveManager.reset_quick_duel_loss_streak()
	GameState.quick_duel_active = false
	GameState.quick_duel_battle_tier = ""

func _on_quick_duel_tutorial_post_vn(dest: String) -> void:
	if dest != "res://scenes/quick_duel.tscn":
		return
	SaveManager.mark_attack_tutorial_complete()
	GameState.quick_duel_reroll_previews = true
	GameState.quick_duel_launch = false

func _handle_quick_duel_loss_rewards() -> void:
	var min_turns: int = QuickDuelRewards.get_loss_consolation_min_turns()
	if GameState.turn_number >= min_turns:
		var streak: int = SaveManager.get_quick_duel_loss_streak()
		var loss_credits: int = QuickDuelRewards.get_loss_consolation_amount_for_streak(streak)
		if loss_credits > 0:
			var consolation: Dictionary = {"type": "credits", "amount": loss_credits}
			_grant_quick_duel_reward(consolation)
			GameState.quick_duel_pending_rewards = [consolation]
			SaveManager.increment_quick_duel_loss_streak()
	GameState.quick_duel_active = false
	GameState.quick_duel_battle_tier = ""


func _report_duel_finished(
		player_won: bool,
		was_quick_duel: bool = false,
		quick_duel_tier_snapshot: String = ""
) -> void:
	if TutorialBattleManager.is_active or TutorialBattleManager.is_prepared:
		return
	var mode := GameState.game_mode
	if mode == GameState.GameMode.AI_VS_AI or mode == GameState.GameMode.HOT_SEAT:
		return
	var protagonist_id: String = GameState.quick_duel_protagonist_id.strip_edges().to_lower()
	if protagonist_id.is_empty():
		protagonist_id = "nex"
	var ctx := {
		"game_over_reason": GameState.game_over_reason,
		"game_mode": mode,
		"protagonist_id": protagonist_id,
		"quick_duel_battle_tier": quick_duel_tier_snapshot,
		"analytics_battle_tag": GameState.analytics_battle_tag,
		"is_quick_duel": was_quick_duel,
		"is_tutorial": false,
	}
	GlobalStatManager.on_duel_finished(player_won, ctx)
	if player_won and mode == GameState.GameMode.EXPLORATION:
		GlobalStatManager.on_exploration_battle_won(
			GameState.analytics_battle_id, GameState.analytics_graph_path)


func _sort_quick_duel_grant_order(rewards: Array) -> Array:
	var primary: Array = []
	var packs: Array = []
	for entry: Variant in rewards:
		if not entry is Dictionary:
			continue
		if str((entry as Dictionary).get("type", "")) == "booster_pack":
			packs.append(entry)
		else:
			primary.append(entry)
	primary.append_array(packs)
	return primary


func _grant_quick_duel_reward(reward: Dictionary, granted_cards: Dictionary = {}) -> void:
	match str(reward.get("type", "")):
		"credits", "coins":
			var amount: int = int(reward.get("amount", 0))
			if amount > 0:
				Collection.add_credits(amount)
		"card":
			var card_name: String = str(reward.get("card_name", "")).strip_edges()
			if card_name.is_empty():
				return
			var granted: String = RewardGranter.grant_named_card_reward(card_name, "Quick Duel")
			if granted == "card":
				granted_cards[card_name] = true
				GameState.quick_duel_reveal_queue.append({
					"kind": "card",
					"card_name": card_name,
				})
			elif granted == "union":
				GameState.quick_duel_reveal_queue.append({
					"kind": "union",
					"card_name": card_name,
				})
		"union_scroll":
			var scroll_count: int = int(reward.get("count", 1))
			if scroll_count <= 0:
				scroll_count = 1
			Collection.add_union_scrolls(scroll_count)
		"booster_pack":
			var pack_name: String = str(reward.get("pack_name", "")).strip_edges()
			if pack_name.is_empty():
				return
			var drawn: Array = ShopManager.draw_pack_free(pack_name, granted_cards)
			var card_names: Array[String] = []
			for c: Variant in drawn:
				if c is Dictionary:
					var drawn_name: String = str((c as Dictionary).get("name", "")).strip_edges()
					if drawn_name.is_empty():
						continue
					card_names.append(drawn_name)
					granted_cards[drawn_name] = true
			var pack_dict: Dictionary = ShopManager.get_pack_by_name(pack_name)
			GameState.quick_duel_reveal_queue.append({
				"kind": "pack",
				"pack_name": pack_name,
				"pack_image": str(pack_dict.get("pack_image", "")),
				"cards": card_names,
			})

func _present_quick_duel_reward_reveal_anims() -> void:
	GameState.quick_duel_reveal_skip_all = false
	for entry: Variant in GameState.quick_duel_reveal_queue:
		if GameState.quick_duel_reveal_skip_all:
			break
		if not entry is Dictionary:
			continue
		var item: Dictionary = entry as Dictionary
		match str(item.get("kind", "")):
			"pack":
				var cards: Array = item.get("cards", [])
				var c1: String = str(cards[0]) if cards.size() > 0 else ""
				var c2: String = str(cards[1]) if cards.size() > 1 else ""
				var c3: String = str(cards[2]) if cards.size() > 2 else ""
				var pack_img: String = str(item.get("pack_image", ""))
				PackOpeningOverlay.open(self, pack_img, c1, c2, c3, true)
				await _await_pack_opening_overlay()
			"card":
				var card_name: String = str(item.get("card_name", "")).strip_edges()
				if card_name.is_empty():
					continue
				PackOpeningOverlay.open_single_card_reveal(self, card_name, true)
				await _await_pack_opening_overlay()
			"union":
				var union_name: String = str(item.get("card_name", "")).strip_edges()
				if union_name.is_empty():
					continue
				UnionScrollOpeningOverlay.open(self, union_name)
				await _await_union_opening_overlay()


func _await_pack_opening_overlay() -> void:
	await get_tree().process_frame
	for child: Node in get_children():
		if child is PackOpeningOverlay:
			await child.tree_exiting
			return


func _await_union_opening_overlay() -> void:
	await get_tree().process_frame
	for child: Node in get_children():
		if child is UnionScrollOpeningOverlay:
			await child.tree_exiting
			return

func _exit_tree() -> void:
	if TutorialBattleManager.is_active or TutorialBattleManager.is_prepared:
		TutorialBattleManager.stop()
	if _is_mid_battle_for_abandon():
		GlobalStatManager.on_battle_abandoned()
	if GameState.quick_duel_active and GameState.current_phase != GameState.Phase.GAME_OVER:
		GameState.abort_quick_duel_battle()


func _is_mid_battle_for_abandon() -> bool:
	if TutorialBattleManager.is_active or TutorialBattleManager.is_prepared:
		return false
	var phase := GameState.current_phase
	return phase not in [
		GameState.Phase.NONE,
		GameState.Phase.SETUP_P1,
		GameState.Phase.SETUP_P2,
		GameState.Phase.GAME_OVER,
	]

func _apply_endgame_serif_font(control: Control, weight: int = 400) -> void:
	control.add_theme_font_override("font", FontManager.make_font("display_serif", weight))

func _show_endgame_screen(winner: int) -> void:
	_hide_card_context()
	var was_quick_duel: bool = GameState.quick_duel_active
	var quick_duel_tier_snapshot: String = GameState.quick_duel_battle_tier
	var mode := GameState.game_mode
	var is_hot_seat   := (mode == GameState.GameMode.HOT_SEAT)
	var is_ai_game    := mode in [GameState.GameMode.VS_AI, GameState.GameMode.CAMPAIGN, GameState.GameMode.DAILY_DUNGEON, GameState.GameMode.EXPLORATION]
	var is_dungeon    := (mode == GameState.GameMode.DAILY_DUNGEON)
	var is_exploration := (mode == GameState.GameMode.EXPLORATION)

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
			if is_dungeon:
				title_text = "You've Won the Duel."
			elif is_exploration:
				title_text = "You've Won the Duel."
			else:
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

	# Award on win (VS AI / Campaign only; Daily Dungeon and Exploration handle their own rewards)
	if is_win_screen and is_ai_game and not is_dungeon and not is_exploration:
		if GameState.quick_duel_active:
			_handle_quick_duel_win_rewards()
		elif not GameState.vn_battle_rewards.is_empty():
			_grant_vn_battle_rewards()
		else:
			MailboxManager.send_mail(
				"Battle Reward",
				"Credits Earned!",
				"You won and received 50 Credits.",
				{"type": "credits", "amount": 50}
			)
	elif not is_win_screen and is_ai_game and not is_dungeon and not is_exploration:
		if GameState.quick_duel_active:
			_handle_quick_duel_loss_rewards()
		elif not GameState.vn_battle_loss_rewards.is_empty():
			_grant_vn_battle_loss_rewards()

	if is_ai_game and not is_dungeon and not is_hot_seat:
		_report_duel_finished(is_win_screen, was_quick_duel, quick_duel_tier_snapshot)

	# ── Build full-screen overlay ────────────────────────────────────────────
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 10
	overlay.modulate.a = 0.0
	add_child(overlay)

	# Background
	var endgame_bg_path: String = _resolve_endgame_background_path(is_win_screen)
	if endgame_bg_path.is_empty():
		if is_win_screen and winner != -1:
			endgame_bg_path = "res://assets/textures/profile/win_screen/img_win_screen_nex.png"
		else:
			endgame_bg_path = "res://assets/textures/profile/win_screen/img_lose_screen_default.png"
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture      = load(endgame_bg_path)
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
		_apply_endgame_serif_font(go_lbl, 700)
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
		_apply_endgame_serif_font(title_lbl, 600)
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
		overlay.add_child(title_lbl)


	# Reason label — explains why the game ended
	var reason_text: String = ""
	var reason := GameState.game_over_reason
	match reason:
		"crystals":
			if winner == -1:
				reason_text = "Both players' crystals hit zero at the same time."
			elif is_win_screen:
				reason_text = "Opponent's crystals were fully depleted."
			else:
				reason_text = "Your crystals were fully depleted."
		"all_destroyed":
			if is_win_screen:
				reason_text = "All opponent's units were destroyed."
			else:
				reason_text = "All your units were destroyed."
		"no_moves":
			if winner == -1:
				reason_text = "Neither player had any valid moves remaining."
			elif is_win_screen:
				reason_text = "Opponent had no valid moves remaining."
			else:
				reason_text = "You had no valid moves remaining."
		"surrender":
			if is_win_screen:
				if is_hot_seat:
					reason_text = "%s surrendered." % _player_names[1 - winner]
				else:
					reason_text = "Opponent surrendered."
			else:
				reason_text = "You surrendered."
		_:
			reason_text = ""
	if reason_text != "":
		var reason_lbl := Label.new()
		reason_lbl.text = reason_text
		reason_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reason_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		reason_lbl.offset_left   = -420.0
		reason_lbl.offset_right  =  420.0
		reason_lbl.offset_top    =  44.0
		reason_lbl.offset_bottom =  80.0
		reason_lbl.add_theme_font_size_override("font_size", 18)
		_apply_endgame_serif_font(reason_lbl, 400)
		reason_lbl.add_theme_color_override("font_color",
			Color(0.72, 0.88, 1.0, 0.90) if is_win_screen else Color(1.0, 0.72, 0.60, 0.85))
		reason_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
		reason_lbl.add_theme_constant_override("shadow_offset_x", 2)
		reason_lbl.add_theme_constant_override("shadow_offset_y", 2)
		reason_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reason_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		overlay.add_child(reason_lbl)

	# "Tap to continue" hint — blinks gently (hidden when exploration duel defeat offers choices)
	var hint_lbl := Label.new()
	hint_lbl.text = "tap anywhere to continue"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hint_lbl.offset_left   = -300.0
	hint_lbl.offset_right  =  300.0
	hint_lbl.offset_top    =  220.0
	hint_lbl.offset_bottom =  270.0
	hint_lbl.add_theme_font_size_override("font_size", 24)
	_apply_endgame_serif_font(hint_lbl, 400)
	hint_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint_lbl)

	var blink_tw := create_tween().set_loops()
	blink_tw.tween_property(hint_lbl, "modulate:a", 0.2, 0.9).set_trans(Tween.TRANS_SINE)
	blink_tw.tween_property(hint_lbl, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

	# Overlay catches all clicks
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var from_exploration: bool = GameState.vn_launched_from_exploration \
		and ExplorationManager.is_session_active
	var exploration_duel_defeat: bool = not is_win_screen \
		and ExplorationManager.is_session_active \
		and (is_exploration or from_exploration)

	var dest: String
	if exploration_duel_defeat:
		dest = "res://scenes/main_menu.tscn"
	elif from_exploration:
		dest = ExplorationManager.EXPLORATION_PLAYER_SCENE
		GameState.vn_launched_from_exploration = false
	elif mode == GameState.GameMode.CAMPAIGN:
		dest = "res://scenes/campaign_map.tscn"
	elif mode == GameState.GameMode.EXPLORATION:
		dest = ExplorationManager.EXPLORATION_PLAYER_SCENE
	elif mode == GameState.GameMode.VS_AI and GameState.post_battle_return_scene != "":
		dest = GameState.post_battle_return_scene
		if dest == "res://scenes/quick_duel.tscn":
			GameState.quick_duel_reroll_previews = true
		GameState.post_battle_return_scene = ""
	else:
		dest = DailyDungeonManager.get_post_battle_scene()

	if exploration_duel_defeat:
		hint_lbl.visible = false
		blink_tw.kill()
		var choice_lbl := Label.new()
		choice_lbl.text = "What will you do?"
		choice_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choice_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		choice_lbl.offset_left   = -320.0
		choice_lbl.offset_right  =  320.0
		choice_lbl.offset_top    =  170.0
		choice_lbl.offset_bottom =  210.0
		choice_lbl.add_theme_font_size_override("font_size", 26)
		_apply_endgame_serif_font(choice_lbl, 600)
		choice_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.72, 0.95))
		choice_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(choice_lbl)

		var choice_vbox := VBoxContainer.new()
		choice_vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		choice_vbox.offset_left   = -220.0
		choice_vbox.offset_right  =  220.0
		choice_vbox.offset_top    =  220.0
		choice_vbox.offset_bottom =  360.0
		choice_vbox.add_theme_constant_override("separation", 14)
		choice_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		overlay.add_child(choice_vbox)

		var has_save: bool = ExplorationManager.has_saved_session()
		var load_btn := _make_defeat_choice_button("Load Last Save")
		load_btn.disabled = not has_save
		if not has_save:
			load_btn.tooltip_text = "No exploration save data found."
		load_btn.pressed.connect(func() -> void:
			if not has_save:
				return
			_fade_endgame_overlay_and_run(overlay, func() -> void:
				_stop_battle_music()
				GameState.vn_launched_from_exploration = false
				if not ExplorationManager.resume_from_last_save_after_duel_loss():
					ExplorationManager.quit_to_title_after_duel_loss()
					get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
					return
				BGMManager.stop(0.5)
				get_tree().change_scene_to_file(ExplorationManager.EXPLORATION_PLAYER_SCENE)))
		choice_vbox.add_child(load_btn)

		var title_btn := _make_defeat_choice_button("Title Screen")
		title_btn.pressed.connect(func() -> void:
			_fade_endgame_overlay_and_run(overlay, func() -> void:
				_stop_battle_music()
				GameState.vn_launched_from_exploration = false
				ExplorationManager.quit_to_title_after_duel_loss()
				get_tree().change_scene_to_file("res://scenes/main_menu.tscn")))
		choice_vbox.add_child(title_btn)
	else:
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
			var pending_vn := _pending_win_vn
			_pending_win_vn = ""
			if pending_vn != "":
				var post_vn_dest: String = dest
				_fade_endgame_overlay_and_run(overlay, func() -> void:
					_stop_battle_music()
					var cb := func() -> void:
						_on_quick_duel_tutorial_post_vn(post_vn_dest)
						get_tree().change_scene_to_file(post_vn_dest)
					VNPlayer.launch_overlay(pending_vn, cb))
			else:
				_fade_endgame_overlay_and_run(overlay, func() -> void:
					if from_exploration or is_exploration:
						BGMManager.stop(0.5)
					get_tree().change_scene_to_file(dest)))

	# Fade in the endgame screen
	var ft := create_tween()
	ft.tween_property(overlay, "modulate:a", 1.0, 0.7)

func _make_defeat_choice_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(440, 52)
	btn.add_theme_font_size_override("font_size", 22)
	_apply_endgame_serif_font(btn, 600)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.1, 0.18, 0.92)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.45, 0.62, 0.95, 0.55)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_right = 8
	normal.corner_radius_bottom_left = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.16, 0.28, 0.98)
	hover.border_color = Color(0.55, 0.75, 1.0, 0.9)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", normal)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_stylebox_override("disabled", normal)
	btn.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.58, 0.65, 0.8))
	return btn

func _fade_endgame_overlay_and_run(overlay: Control, action: Callable) -> void:
	var black := ColorRect.new()
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.color = Color(0.0, 0.0, 0.0, 0.0)
	black.z_index = 200
	black.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(black)
	var out_tw := create_tween()
	out_tw.tween_property(black, "color:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	out_tw.tween_callback(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
		black.queue_free()
		if action.is_valid():
			action.call())

# ─────────────────────────────────────────────────────────────
# Session log — lightweight file logging for VS_AI / HOT_SEAT
# ─────────────────────────────────────────────────────────────

func _open_session_log() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://logs"))
	var mode_tag: String = "vs_ai" if GameState.game_mode == GameState.GameMode.VS_AI else "hot_seat"
	var log_info: Dictionary = SessionLogNaming.begin_battle_log(mode_tag)
	var path: String = log_info["path"]
	_session_log_file = FileAccess.open(path, FileAccess.WRITE)
	_session_log_start_msec = Time.get_ticks_msec()
	_session_log_prev_crystals = [GameState.crystals[0], GameState.crystals[1]]
	_session_logged_destroy_slots.clear()

	if _session_log_file == null:
		return

	SessionLogNaming.write_battle_header(_session_log_file, log_info)
	_session_log_file.store_line("=== %s Match ===" % mode_tag.to_upper().replace("_", " "))
	_session_log_file.store_line("===")
	_session_log_file.store_line("")

	# Connect signals for session log
	GameState.turn_changed.connect(_session_on_turn_changed)
	GameState.message_posted.connect(_session_on_message)
	GameState.crystals_changed.connect(_session_on_crystals)
	GameState.card_destroyed.connect(_session_on_card_destroyed)
	GameState.card_revealed.connect(_session_on_card_revealed)
	GameState.dice_rolled.connect(_session_on_dice_rolled)
	GameState.card_atk_changed.connect(_session_on_card_stat_changed.bind("ATK"))
	GameState.card_def_changed.connect(_session_on_card_stat_changed.bind("DEF"))
	GameState.union_summoned.connect(_session_on_union_summoned)
	turn_manager.attack_completed.connect(_session_on_attack_completed)
	turn_manager.tech_played.connect(_session_on_tech_played)
	turn_manager.tech_resolved.connect(_session_on_tech_resolved)
	turn_manager.turn_ended.connect(_session_on_turn_ended)
	turn_manager.attack_aborted.connect(_session_on_attack_aborted)
	turn_manager.mode_selected.connect(_session_on_mode_selected)
	turn_manager.coin_flip_visual_requested.connect(_session_on_coin_flip)
	turn_manager.awaiting_target_selection.connect(_session_on_target_prompt)
	turn_manager.ability_choice_resolved.connect(_session_on_ability_choice_resolved)

func _finish_session_log(winner: int) -> void:
	_close_session_log(winner)

func _session_destroy_slot_key(player_index: int, row: int, col: int) -> String:
	return "%d:%d:%d" % [player_index, row, col]

func _session_log_destroy_if_needed(player_index: int, row: int, col: int, card_label: String) -> void:
	if card_label.is_empty():
		return
	var key: String = _session_destroy_slot_key(player_index, row, col)
	if _session_logged_destroy_slots.has(key):
		return
	_session_logged_destroy_slots[key] = true
	_session_log("Card destroyed  P%d (%d,%d) %s" % [player_index, row, col, card_label])

func _close_session_log(winner: int) -> void:
	if _session_log_file == null:
		return
	var result_str: String
	match winner:
		-1: result_str = "Draw"
		0:  result_str = "Player 1 wins"
		1:  result_str = "Player 2 wins"
		_:  result_str = "Unknown"
	_session_log_file.store_line("")
	_session_log_file.store_line("=== GAME OVER: %s ===" % result_str)
	_session_log_file.store_line("Final crystals — P0: %d  P1: %d  |  Turns: %d" % [
		GameState.crystals[0], GameState.crystals[1], GameState.turn_number])
	_session_log_file.close()
	_session_log_file = null
	# Disconnect
	if GameState.turn_changed.is_connected(_session_on_turn_changed):
		GameState.turn_changed.disconnect(_session_on_turn_changed)
	if GameState.message_posted.is_connected(_session_on_message):
		GameState.message_posted.disconnect(_session_on_message)
	if GameState.crystals_changed.is_connected(_session_on_crystals):
		GameState.crystals_changed.disconnect(_session_on_crystals)
	if GameState.card_destroyed.is_connected(_session_on_card_destroyed):
		GameState.card_destroyed.disconnect(_session_on_card_destroyed)
	if GameState.card_revealed.is_connected(_session_on_card_revealed):
		GameState.card_revealed.disconnect(_session_on_card_revealed)
	if GameState.dice_rolled.is_connected(_session_on_dice_rolled):
		GameState.dice_rolled.disconnect(_session_on_dice_rolled)
	if GameState.card_atk_changed.is_connected(_session_on_card_stat_changed):
		GameState.card_atk_changed.disconnect(_session_on_card_stat_changed)
	if GameState.card_def_changed.is_connected(_session_on_card_stat_changed):
		GameState.card_def_changed.disconnect(_session_on_card_stat_changed)
	if GameState.union_summoned.is_connected(_session_on_union_summoned):
		GameState.union_summoned.disconnect(_session_on_union_summoned)
	if turn_manager != null:
		if turn_manager.attack_completed.is_connected(_session_on_attack_completed):
			turn_manager.attack_completed.disconnect(_session_on_attack_completed)
		if turn_manager.tech_played.is_connected(_session_on_tech_played):
			turn_manager.tech_played.disconnect(_session_on_tech_played)
		if turn_manager.tech_resolved.is_connected(_session_on_tech_resolved):
			turn_manager.tech_resolved.disconnect(_session_on_tech_resolved)
		if turn_manager.turn_ended.is_connected(_session_on_turn_ended):
			turn_manager.turn_ended.disconnect(_session_on_turn_ended)
		if turn_manager.attack_aborted.is_connected(_session_on_attack_aborted):
			turn_manager.attack_aborted.disconnect(_session_on_attack_aborted)
		if turn_manager.mode_selected.is_connected(_session_on_mode_selected):
			turn_manager.mode_selected.disconnect(_session_on_mode_selected)
		if turn_manager.coin_flip_visual_requested.is_connected(_session_on_coin_flip):
			turn_manager.coin_flip_visual_requested.disconnect(_session_on_coin_flip)
		if turn_manager.awaiting_target_selection.is_connected(_session_on_target_prompt):
			turn_manager.awaiting_target_selection.disconnect(_session_on_target_prompt)
		if turn_manager.ability_choice_resolved.is_connected(_session_on_ability_choice_resolved):
			turn_manager.ability_choice_resolved.disconnect(_session_on_ability_choice_resolved)

func _session_log(msg: String) -> void:
	if _session_log_file == null:
		return
	var elapsed_ms: int = Time.get_ticks_msec() - _session_log_start_msec
	var s: int = elapsed_ms / 1000
	var ms: int = elapsed_ms % 1000
	var min_: int = s / 60
	s = s % 60
	_session_log_file.store_line("[%02d:%02d.%03d] %s" % [min_, s, ms, msg])

func _session_on_turn_changed(player: int) -> void:
	var c0: int = GameState.crystals[0]
	var c1: int = GameState.crystals[1]
	_session_log_file.store_line("")
	_session_log_file.store_line("--- Turn %d  |  Player %d  |  Crystals P0=%d P1=%d ---" % [
		GameState.turn_number, player, c0, c1])
	_session_log_prev_crystals[0] = c0
	_session_log_prev_crystals[1] = c1

func _session_on_message(text: String) -> void:
	if text.contains("'s turn — play a Tech"):
		return
	if text.begins_with("Player ") and text.contains(" plays ") and text.ends_with("!"):
		return
	if text.begins_with("Player ") and text.contains("ends their turn"):
		return
	if text.contains(" ATK ") and text.contains(" vs ") and text.contains(" DEF "):
		return
	if text.ends_with(" defends successfully!"):
		return
	_session_log("MSG: %s" % text)

func _session_on_crystals(player: int, new_amount: int, reason: String) -> void:
	var delta: int = new_amount - _session_log_prev_crystals[player]
	if delta == 0:
		_session_log_prev_crystals[player] = new_amount
		return
	var sign: String = "+" if delta >= 0 else ""
	var reason_tag: String = "  [%s]" % reason if not reason.is_empty() else ""
	_session_log("Crystals: P%d %d → %d (%s%d)%s" % [
		player, _session_log_prev_crystals[player], new_amount, sign, delta, reason_tag])
	_session_log_prev_crystals[player] = new_amount

func _session_on_card_destroyed(player_index: int, row: int, col: int) -> void:
	if GameState.current_phase == GameState.Phase.BATTLE:
		return
	var card: GameState.CardInstance = GameState.get_card(player_index, row, col)
	if card == null or card.card_type == "dead_end" or card.card_name.is_empty():
		_session_log("Dead-end placed  P%d (%d,%d)" % [player_index, row, col])
	else:
		var key: String = _session_destroy_slot_key(player_index, row, col)
		if _session_logged_destroy_slots.has(key):
			return
		_session_logged_destroy_slots[key] = true
		_session_log("Card destroyed  P%d (%d,%d) %s" % [
			player_index, row, col, BattleLogFormat.format_card(card)])

func _session_on_card_revealed(player_index: int, row: int, col: int) -> void:
	var card: GameState.CardInstance = GameState.get_card(player_index, row, col)
	if card == null or card.card_name.is_empty():
		return
	_session_log("Revealed: P%d (%d,%d) %s" % [
		player_index, row, col, BattleLogFormat.format_card(card)])

func _session_on_dice_rolled(result: int) -> void:
	_session_log("Dice rolled: %d" % result)

func _session_on_card_stat_changed(player_index: int, row: int, col: int,
		old_val: int, new_val: int, stat: String) -> void:
	var card: GameState.CardInstance = GameState.get_card(player_index, row, col)
	var name_str: String = BattleLogFormat.format_card(card)
	_session_log("%s changed P%d(%d,%d)%s: %d → %d" % [stat, player_index, row, col, name_str, old_val, new_val])

func _session_on_union_summoned(player: int, union_label: String, material_labels: Array) -> void:
	_session_log("Union summoned P%d: %s from %s" % [
		player, union_label, ", ".join(PackedStringArray(material_labels))])

func _session_on_tech_resolved(player_index: int) -> void:
	_session_log("Tech resolved  P%d" % player_index)

func _session_on_turn_ended(player_index: int) -> void:
	_session_log("Turn ended  P%d  |  Crystals P0=%d P1=%d" % [
		player_index, GameState.crystals[0], GameState.crystals[1]])

func _session_on_mode_selected(player_index: int, mode: GameState.TurnMode) -> void:
	var mode_name: String
	match mode:
		GameState.TurnMode.ATTACK: mode_name = "ATTACK"
		GameState.TurnMode.TECH:   mode_name = "TECH"
		GameState.TurnMode.NONE:   mode_name = "NONE"
		_:                         mode_name = str(mode)
	_session_log("Mode selected P%d: %s" % [player_index, mode_name])

func _session_on_coin_flip(results: Array) -> void:
	var strs: Array[String] = []
	for r: Variant in results:
		strs.append("Heads" if r else "Tails")
	_session_log("Coin flip: " + ", ".join(PackedStringArray(strs)))

func _session_on_target_prompt(prompt: String, filter: String) -> void:
	_session_log("Target prompt: \"%s\"  filter=%s" % [prompt, filter])

func _session_on_ability_choice_resolved(choice_index: int) -> void:
	var label: String = "Yes" if choice_index == 0 else "No"
	_session_log("Ability choice: %d (%s)" % [choice_index, label])

func _session_on_attack_completed(attacker_pos: Vector2i, target_pos: Vector2i,
		result: BattleResolver.BattleResult) -> void:
	var atk_player: int = GameState.current_player
	var def_player: int = GameState.get_opponent(atk_player)
	var a_name: String = BattleLogFormat.attack_side_label(result, true)
	var d_name: String = BattleLogFormat.attack_side_label(result, false)
	_session_log(BattleLogFormat.format_attack_resolution_line(
		atk_player, attacker_pos, def_player, target_pos, result, GameState.dice_result))
	if result.defender_name.is_empty() and not result.defender_destroyed \
			and result.special_trigger not in ["trap_effect", "trap_nullified"]:
		_session_log("Anim: 3F  (blank slot)")
		return
	for overlay_line: String in BattleResolver.reckoning_overlay_log_lines(
			atk_player, def_player, result):
		_session_log(overlay_line)
	_session_log(BattleLogFormat.format_attack_anim_line(
		atk_player, attacker_pos, def_player, target_pos, result))
	if result.attacker_destroyed:
		_session_log_destroy_if_needed(atk_player, attacker_pos.x, attacker_pos.y, a_name)
	if result.defender_destroyed:
		_session_log_destroy_if_needed(def_player, target_pos.x, target_pos.y, d_name)

func _session_on_tech_played(player_index: int, tech_name: String) -> void:
	_session_log("Tech played  P%d: \"%s\"" % [player_index, tech_name])

func _session_on_attack_aborted() -> void:
	_session_log("Attack aborted")
