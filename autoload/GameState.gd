extends Node

# ─────────────────────────────────────────────────────────────
# Enums
# ─────────────────────────────────────────────────────────────
enum Phase {
	NONE,
	SETUP_P1,   # Player 1 places cards
	SETUP_P2,   # Player 2 places cards
	MODE_SELECT,# Current player picks Attack or Tech Mode
	ATTACK,     # Attack mode active
	TECH,       # Tech mode active
	BATTLE,     # Resolving a single battle
	GAME_OVER
}

enum TurnMode { NONE, ATTACK, TECH }
enum GameMode { LOCAL_2P, VS_AI, HOT_SEAT, CAMPAIGN, DAILY_DUNGEON, AI_VS_AI, EXPLORATION }

# ─────────────────────────────────────────────────────────────
# Signals
# ─────────────────────────────────────────────────────────────
signal phase_changed(new_phase: Phase)
signal turn_changed(player_index: int)
signal crystals_changed(player_index: int, new_amount: int, reason: String)
signal card_placed(player_index: int, row: int, col: int)
signal card_revealed(player_index: int, row: int, col: int)
signal card_destroyed(player_index: int, row: int, col: int)
signal dice_rolled(result: int)
signal game_over(winner: int)  # -1 = tie, 0 = player 1, 1 = player 2
signal tech_card_used(player_index: int, card_name: String)
signal card_effect_triggered(card_name: String, card_type: String)
signal attack_used(player_index: int, attacks_remaining: int)
signal message_posted(text: String)
signal center_message_requested(text: String)
signal card_flag_added(player_index: int, row: int, col: int, flag: String)
signal card_flag_removed(player_index: int, row: int, col: int, flag: String)
signal card_atk_changed(player_index: int, row: int, col: int, old_val: int, new_val: int)
signal card_def_changed(player_index: int, row: int, col: int, old_val: int, new_val: int)
signal bluff_changed(player_index: int, row: int, col: int, emoticon: String)
signal attack_target_selected(attacker_player: int, target_player: int, row: int, col: int)
signal tech_target_selected(user_player: int, target_player: int, row: int, col: int)
signal union_summoned(player: int, union_label: String, material_labels: Array)
signal field_bonuses_recalculated()

# ─────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────
const GRID_SIZE: int = 5
const STARTING_CRYSTALS: int = 5000

# Maps affinity name strings (used by DailyDungeonManager) to CharacterData.Affinity int values.
const DUNGEON_AFFINITY_TO_INT: Dictionary = {
	"DIVINE": 0, "CHAOS": 1, "NATURE": 2, "ARCANE": 3, "COSMIC": 4, "BIO": 5, "ANIMA": 6
}
const STARTING_TECH_HAND: int = 3
const MIN_CHARACTERS: int = 8
const MAX_CHARACTERS: int = 12
const MIN_TRAPS: int = 4
const MAX_TRAPS: int = 6

# Decoy Puppet / Guerrilla Tactics battle flow (declared before inner class)
var attack_cost_block_max: int = -1
var attack_cost_block_player: int = -1
var guerrilla_tactics_owner: int = -1

# ─────────────────────────────────────────────────────────────
# CardInstance – Runtime card state on the grid
# ─────────────────────────────────────────────────────────────
class CardInstance:
	var card_type: String = ""       # "character", "trap", "dead_end"
	var was_destroyed: bool = false  # true when this slot was cleared by destroy_card
	var card_name: String = ""
	var display_name: String = ""    # Human-readable name; use this for all UI/messages
	var rarity: int = 0  # CharacterData.Rarity.COMMON
	var face_up: bool = false
	var current_atk: int = 0
	var current_def: int = 0
	var base_atk: int = 0
	var base_def: int = 0
	var crystal_cost: int = 0
	var affinity: int = -1           # CharacterData.Affinity value
	var ability_type: int = 0        # CharacterData.AbilityType value
	var ability_params: Dictionary = {}
	var has_mutagen_flag: bool = false
	var is_token: bool = false
	var is_union: bool = false       # true when this card is a Union monster
	var is_revived: bool = false     # true when placed on field via a revive effect
	var attacked_this_turn: bool = false
	var cannot_attack_until: int = -1  # Turn number when restriction lifts
	var effect_nullified_until: int = -1
	var one_use_def_boost_used: bool = false
	var one_use_atk_boost_used: bool = false  # for ONE_USE_ATK_BOOST and ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND ATK half
	var multi_attack_count: int = 0            # for MULTI_ATTACK_VS_NON_CHARACTER — attacks used this turn
	var bonus_attack_pending: bool = false     # dead-end extra attack granted, bonus not yet used
	var perm_atk_bonus: int = 0
	var perm_def_bonus: int = 0
	var field_aura_atk_bonus: int = 0  # passive ATK from allied field auras (e.g. Amber)
	var temp_atk_bonus: int = 0
	var temp_def_bonus: int = 0
	var carry_def_bonus: int = 0   # DEF bonus that survives end-of-turn clear; wiped at start of player's own next turn
	var atk_def_swapped: bool = false  # Cursed Reflection: effective ATK/DEF swapped until defender's turn ends
	var atk_def_swap_clear_on_player_end: int = -1
	var force_shielded: bool = false
	var halved: bool = false
	var mutagen_attacked: bool = false # Mutagen immediate attack used
	var atk_debuff: int = 0
	var revealed_on_turn: int = -1       # set to turn_number when flipped face-up; -1 = never
	var flags: Array[String] = []        # string tags: "bio", "cosmic", "mutagen", etc.
	var active_rules: Array = []         # Array of CardRule — populated by CardRuleEngine
	var grid_row: int = -1  # updated by GameState when placed; used for position modifiers
	var grid_col: int = -1

	# Affinity-index → day/great-day/tragedy/great-tragedy modifier key
	# Order mirrors CharacterData.Affinity: DIVINE=0,CHAOS=1,NATURE=2,ARCANE=3,COSMIC=4,BIO=5,ANIMA=6
	const _AFF_DAY: Array = [
		"divine_day","chaos_day","nature_day","arcane_day","cosmic_day","bio_day","anima_day"]
	const _AFF_GREAT_DAY: Array = [
		"great_divine_day","great_chaos_day","great_nature_day","great_arcane_day",
		"great_cosmic_day","great_bio_day","great_anima_day"]
	const _AFF_TRAG: Array = [
		"divine_tragedy","chaos_tragedy","nature_tragedy","arcane_tragedy",
		"cosmic_tragedy","bio_tragedy","anima_tragedy"]
	const _AFF_GREAT_TRAG: Array = [
		"great_divine_tragedy","great_chaos_tragedy","great_nature_tragedy","great_arcane_tragedy",
		"great_cosmic_tragedy","great_bio_tragedy","great_anima_tragedy"]

	func get_effective_atk() -> int:
		if atk_def_swapped:
			return _calc_effective_def()
		return _calc_effective_atk()

	func get_effective_def() -> int:
		if atk_def_swapped:
			return _calc_effective_atk()
		return _calc_effective_def()

	func _calc_effective_atk() -> int:
		var base: int = max(0, current_atk + perm_atk_bonus + field_aura_atk_bonus + temp_atk_bonus - atk_debuff)
		if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON:
			var mods: Array = GameState.active_dungeon_modifiers
			if "monster_overload" in mods:
				base = int(base * 1.5)
			if "kaiju_fight" in mods and is_union:
				base = int(base * 3.0)   # +200% = ×3
			if affinity >= 0 and affinity <= 6:
				if _AFF_DAY[affinity] in mods:       base = int(base * 1.2)
				if _AFF_GREAT_DAY[affinity] in mods: base = int(base * 1.5)
				if _AFF_TRAG[affinity] in mods:      base = int(base * 0.8)
				if _AFF_GREAT_TRAG[affinity] in mods: base = int(base * 0.5)
			# Position-based modifiers (require grid_row/grid_col to be set)
			if grid_row >= 0 and grid_col >= 0:
				var _is_border: bool = (grid_row == 0 or grid_row == 4 or grid_col == 0 or grid_col == 4)
				var _is_c3: bool = (grid_row in [1,2,3] and grid_col in [1,2,3])
				var _is_center: bool = (grid_row == 2 and grid_col == 2)
				if _is_center and "absolute_monarchy" in mods:   base = int(base * 2.0)
				if _is_c3   and "mixed_monarchy" in mods:        base = int(base * 1.2)
				if _is_c3   and "corrupted_nobles" in mods:      base = int(base * 0.8)
		return base

	func _calc_effective_def() -> int:
		var base: int = max(0, current_def + perm_def_bonus + temp_def_bonus + carry_def_bonus)
		if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON:
			var mods: Array = GameState.active_dungeon_modifiers
			if "monster_overload" in mods:
				base = int(base * 1.5)
			if "kaiju_fight" in mods and is_union:
				base = int(base * 3.0)
			if affinity >= 0 and affinity <= 6:
				if _AFF_DAY[affinity] in mods:       base = int(base * 1.2)
				if _AFF_GREAT_DAY[affinity] in mods: base = int(base * 1.5)
				if _AFF_TRAG[affinity] in mods:      base = int(base * 0.8)
				if _AFF_GREAT_TRAG[affinity] in mods: base = int(base * 0.5)
			if grid_row >= 0 and grid_col >= 0:
				var _is_border: bool = (grid_row == 0 or grid_row == 4 or grid_col == 0 or grid_col == 4)
				var _is_c3: bool = (grid_row in [1,2,3] and grid_col in [1,2,3])
				var _is_center: bool = (grid_row == 2 and grid_col == 2)
				if _is_center and "absolute_monarchy" in mods:   base = int(base * 2.0)
				if _is_border and "great_wall"        in mods:   base = int(base * 1.2)
				if _is_border and "broken_wall"       in mods:   base = int(base * 0.8)
				if _is_c3   and "mixed_monarchy" in mods:        base = int(base * 1.2)
				if _is_c3   and "corrupted_nobles" in mods:      base = int(base * 0.8)
		return base

	func clear_temp_buffs() -> void:
		temp_atk_bonus = 0
		temp_def_bonus = 0
		atk_debuff = 0

	func apply_atk_def_swap_until_player_turn_end(clear_when_player_ends: int) -> void:
		atk_def_swapped = true
		atk_def_swap_clear_on_player_end = clear_when_player_ends

	func clear_atk_def_swap() -> void:
		atk_def_swapped = false
		atk_def_swap_clear_on_player_end = -1

	func halve_stats() -> void:
		if not halved:
			current_atk = current_atk / 2
			current_def = current_def / 2
			halved = true

	## Total non-character attacks allowed per chain (initial hit + bonus_attacks).
	func get_multi_attack_non_char_chain_limit() -> int:
		if ability_type != CharacterData.AbilityType.MULTI_ATTACK_VS_NON_CHARACTER:
			return 0
		var bonus_attacks: int = int(ability_params.get(
			"bonus_attacks", ability_params.get("max_attacks", 3) - 1))
		return 1 + maxi(0, bonus_attacks)

	## Golden Senju (MULTI_ATTACK_VS_NON_CHARACTER): bonus non-unit attack still available.
	func has_pending_multi_attack_non_char() -> bool:
		if card_type != "character" or attacked_this_turn:
			return false
		if ability_type != CharacterData.AbilityType.MULTI_ATTACK_VS_NON_CHARACTER:
			return false
		var chain_limit: int = get_multi_attack_non_char_chain_limit()
		return multi_attack_count > 0 and multi_attack_count < chain_limit

	## Golden Senju chain or Sonic Seraph dead-end bonus attack still available.
	func has_pending_bonus_attack_chain() -> bool:
		return has_pending_multi_attack_non_char() or bonus_attack_pending

# ─────────────────────────────────────────────────────────────
# Runtime State
# ─────────────────────────────────────────────────────────────
var current_phase: Phase = Phase.NONE
var current_player: int = 0     # 0 or 1
var game_mode: GameMode = GameMode.LOCAL_2P
var turn_number: int = 0

# Player portrait paths — set before entering the battle scene
var player_portraits: Array[String] = [
	"res://assets/textures/ui/portraits/profile_player_1_default.png",
	"res://assets/textures/ui/portraits/profile_player_2_default.png"
]

# Campaign-specific state (only meaningful when game_mode == CAMPAIGN)
var campaign_node_id: String = ""
var campaign_enemy_config: Dictionary = {}
var campaign_player_names: Array[String] = []   # [p1_name, p2_name] — set by VNPlayer before battle

# Daily Dungeon state (only meaningful when game_mode == DAILY_DUNGEON)
var active_dungeon_node_id: String = ""
var active_dungeon_modifiers: Array = []

var crystals: Array = [STARTING_CRYSTALS, STARTING_CRYSTALS]
var grids: Array = []           # grids[player][row][col] -> CardInstance
var bluff_emoticons: Array = []  # bluff_emoticons[player][row][col] -> String ("")
var tech_hands: Array = [[], []]  # tech_hands[player] -> Array of TechCardData names
var dice_result: int = 0
var attacks_remaining: int = 0
var current_mode: TurnMode = TurnMode.NONE
var attacker_card: CardInstance = null
var attacker_pos: Vector2i = Vector2i(-1, -1)
var defender_pos: Vector2i = Vector2i(-1, -1)

# Track which tech cards have been played (for chain requirements)
var tech_cards_played_this_game: Array = [[], []]

# Special global flags
# VN-driven battle outcome routing (set by VNPlayer after new_game(), persists across scene change)
var open_campaign_gallery_on_menu: bool = false
var vn_on_win: String = ""
var vn_on_lose: String = ""
var vn_battle_rewards: Array = []  # VN start_battle beat rewards — granted to mailbox on win
var vn_launched_from_exploration: bool = false
var game_over_reason: String = ""  # "crystals" | "all_destroyed" | "no_moves" | "surrender"
var portrait_p1_offset: Vector2 = Vector2.ZERO
var portrait_p1_size:   float   = 1.0
var portrait_p2_offset: Vector2 = Vector2.ZERO
var portrait_p2_size:   float   = 1.0

# Battle BGM (set by VNPlayer or defaults; not reset by new_game())
var battle_bgm_path: String = ""
var battle_bgm_volume: float = 100.0   # percentage  (100 = 0 dB)
var battle_setup_bgm_path: String = ""       # placement/setup phase; blank = manage_bgm placement default
var battle_almost_win_bgm_path: String = ""  # endgame threshold; blank = manage_bgm almost_win default
var battle_bgm_start_sec: float = 14.0       # first-play offset; loops back to 00:00
var battle_almost_win_enabled: bool = true     # mid-battle / win-reveal almost-win track switch

const DEFAULT_BATTLE_BGM_START_SEC: float = 14.0

## Apply battle audio paths from a VN beat dict or exploration BATTLE node dict.
## Keys: battle_bgm, battle_bgm_volume, setup_bgm, almost_win_bgm,
##       battle_bgm_start_sec, almost_win_bgm_enabled.
## Blank battle_bgm resolves via manage_bgm default for default_battle_context
## (VN start_battle and exploration BATTLE nodes both use battle context when blank).
func apply_battle_audio_config(
		source: Dictionary,
		default_battle_context: String = BGMManager.CONTEXT_BATTLE) -> void:
	var bgm := str(source.get("battle_bgm", "")).strip_edges()
	if bgm.is_empty():
		bgm = BGMManager.get_default_path(default_battle_context)
	battle_bgm_path = bgm
	battle_bgm_volume = float(source.get("battle_bgm_volume", 100.0))
	battle_setup_bgm_path = str(source.get("setup_bgm", "")).strip_edges()
	battle_almost_win_bgm_path = str(source.get("almost_win_bgm", "")).strip_edges()
	battle_bgm_start_sec = maxf(0.0, float(source.get("battle_bgm_start_sec", DEFAULT_BATTLE_BGM_START_SEC)))
	battle_almost_win_enabled = bool(source.get("almost_win_bgm_enabled", true))


## Optional per-side starting crystals from a VN start_battle beat.
## Keys: starting_crystals_p1, starting_crystals_p2  (omit = STARTING_CRYSTALS).
func apply_battle_start_crystals(source: Dictionary) -> void:
	if source.has("starting_crystals_p1"):
		crystals[0] = maxi(0, int(source.get("starting_crystals_p1", STARTING_CRYSTALS)))
	if source.has("starting_crystals_p2"):
		crystals[1] = maxi(0, int(source.get("starting_crystals_p2", STARTING_CRYSTALS)))


func get_almost_win_bgm_path() -> String:
	var path := battle_almost_win_bgm_path.strip_edges()
	if not path.is_empty():
		return path
	return BGMManager.get_default_path(BGMManager.CONTEXT_ALMOST_WIN)

# Battle placement/summon config — set by VNPlayer before scene change.
# _vn_battle_pending = true tells new_game() to preserve these values instead of resetting them.
var _vn_battle_pending: bool = false
var battle_ai_union_enabled: bool = true
var battle_player_union_enabled: bool = true
var battle_player_forced_cells: Array = []  # Array[Dictionary{card_name, row, col}]
var battle_ai_forced_cells: Array = []      # Array[Dictionary{card_name, row, col}]
var battle_player_deck: Variant = null      # DeckData or null — AI_VS_AI: deck for player 0
var battle_ai_deck:     Variant = null      # DeckData or null — AI_VS_AI: deck for player 1
var battle_ai_forced_tech: Array = []       # Array[String] — VS_AI: forced tech hand for the AI

var divine_protection_active: Array = [false, false]
var siege_cannon_active: Array = [false, false]
var berserk_active: Array = [null, null]     # CardInstance or null
var skip_next_turn: Array = [false, false]
var hypnotized_cards: Array = [[], []]       # List of CardInstances that can't attack
var skip_counts: Array = [0, 0]              # Consecutive no-attack turns per player (for doubling tax)
var reroll_dice_available: Array = [false, false]   # TEMP_REROLL_DICE tech: may reroll once before next attack
var graveyards: Array = [[], []]                    # graveyards[player] -> Array of destroyed CardInstances
var locked_attack_positions: Array = []             # Vector2i positions current player cannot attack this turn

const CURSOR_PATH: String = "res://assets/textures/ui/decorations/ui_cursor_finger_64.png"
const CURSOR_HOTSPOT: Vector2 = Vector2(4.0, 4.0)
const CURSOR_LAYER: int = 256
const POPUP_CURSOR_LAYER: int = 4096

var _cursor_tex: Texture2D = null
var _cursor_layer: CanvasLayer = null
var _cursor_sprite: TextureRect = null
var _software_cursor_ready: bool = false
var _app_focused: bool = true
var _mouse_over_game: bool = true
var _finger_cursor_active: bool = false
var _popup_cursors: Dictionary = {}  # Window -> TextureRect

func _ready() -> void:
	_init_grids()
	_load_cursor_texture()
	_setup_software_cursor()
	set_process(true)
	var tree := get_tree()
	if not tree.node_added.is_connected(_on_node_added_cursor):
		tree.node_added.connect(_on_node_added_cursor)
	if not tree.scene_changed.is_connected(_on_scene_changed_reapply_cursor):
		tree.scene_changed.connect(_on_scene_changed_reapply_cursor)
	_bind_window_mouse_tracking()
	call_deferred("_activate_software_cursor")

func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_app_focused = false
		_refresh_cursor_mode()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_app_focused = true
		call_deferred("_refresh_cursor_mode")

func _on_node_added_cursor(node: Node) -> void:
	if node is Window:
		call_deferred("_attach_popup_cursor", node)

## Attach the finger cursor overlay to an editor/tool popup Window.
func attach_popup_cursor(win: Window) -> void:
	call_deferred("_attach_popup_cursor", win)

func _attach_popup_cursor(win: Window) -> void:
	if not _software_cursor_ready or _cursor_tex == null:
		return
	if not is_instance_valid(win) or win == get_tree().root:
		return
	if _popup_cursors.has(win):
		return
	var layer := CanvasLayer.new()
	layer.layer = POPUP_CURSOR_LAYER
	layer.follow_viewport_enabled = true
	win.add_child(layer)
	win.move_child(layer, -1)
	var sprite := _make_cursor_sprite()
	sprite.z_index = POPUP_CURSOR_LAYER
	sprite.visible = false
	layer.add_child(sprite)
	_popup_cursors[win] = sprite
	win.tree_exiting.connect(func() -> void:
		_popup_cursors.erase(win)
	)

func _on_scene_changed_reapply_cursor() -> void:
	call_deferred("_bind_window_mouse_tracking")
	call_deferred("_refresh_cursor_mode")

func _bind_window_mouse_tracking() -> void:
	var win := get_window()
	if not win.mouse_entered.is_connected(_on_game_window_mouse_entered):
		win.mouse_entered.connect(_on_game_window_mouse_entered)
	if not win.mouse_exited.is_connected(_on_game_window_mouse_exited):
		win.mouse_exited.connect(_on_game_window_mouse_exited)

func _on_game_window_mouse_entered() -> void:
	_mouse_over_game = true
	_refresh_cursor_mode()

func _on_game_window_mouse_exited() -> void:
	_mouse_over_game = false
	_refresh_cursor_mode()

func _setup_software_cursor() -> void:
	if _cursor_tex == null:
		return
	_cursor_layer = CanvasLayer.new()
	_cursor_layer.layer = CURSOR_LAYER
	add_child(_cursor_layer)
	_cursor_sprite = _make_cursor_sprite()
	_cursor_layer.add_child(_cursor_sprite)
	_software_cursor_ready = true

func _make_cursor_sprite() -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture = _cursor_tex
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.custom_minimum_size = Vector2(64.0, 64.0)
	sprite.size = Vector2(64.0, 64.0)
	return sprite

func _activate_software_cursor() -> void:
	_refresh_cursor_mode()

func _has_open_file_dialog() -> bool:
	var stack: Array[Node] = [get_tree().root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is FileDialog and (node as FileDialog).visible:
			return true
		for child: Node in node.get_children():
			stack.append(child)
	return false

func _should_use_finger_cursor() -> bool:
	return _app_focused \
		and _mouse_over_game \
		and not _has_open_file_dialog()

func _refresh_cursor_mode() -> void:
	if not _software_cursor_ready or _cursor_sprite == null:
		return
	var screen_mouse := Vector2(DisplayServer.mouse_get_position())
	var active_popup_sprite: TextureRect = null
	var stale: Array[Window] = []
	for win: Window in _popup_cursors.keys():
		if not is_instance_valid(win):
			stale.append(win)
			continue
		var popup_sprite: TextureRect = _popup_cursors[win]
		if not win.visible or not _app_focused:
			popup_sprite.visible = false
			continue
		var local_mouse := win.get_mouse_position()
		var win_size := Vector2(win.size)
		var on_popup := win_size.x > 0.0 and win_size.y > 0.0 \
			and Rect2(Vector2.ZERO, win_size).has_point(local_mouse)
		if not on_popup:
			# Fallback for separate native windows where local coords can lag.
			on_popup = Rect2(win.position, win.size).has_point(screen_mouse)
		if on_popup:
			active_popup_sprite = popup_sprite
			popup_sprite.visible = true
			popup_sprite.position = local_mouse - CURSOR_HOTSPOT
		else:
			popup_sprite.visible = false
	for win in stale:
		_popup_cursors.erase(win)
	var use_main_finger := active_popup_sprite == null and _should_use_finger_cursor()
	var use_finger := use_main_finger or active_popup_sprite != null
	_cursor_sprite.visible = use_main_finger
	if use_main_finger:
		_update_cursor_position()
	if use_finger:
		if not _finger_cursor_active:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		_finger_cursor_active = true
	else:
		if _finger_cursor_active:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_finger_cursor_active = false
		_cursor_sprite.visible = false
		for sprite: Variant in _popup_cursors.values():
			if sprite is TextureRect:
				(sprite as TextureRect).visible = false

func _process(_delta: float) -> void:
	if not _software_cursor_ready:
		return
	_refresh_cursor_mode()

func _update_cursor_position() -> void:
	_cursor_sprite.position = get_viewport().get_mouse_position() - CURSOR_HOTSPOT

func _load_cursor_texture() -> void:
	if _cursor_tex != null:
		return
	var loaded: Texture2D = load(CURSOR_PATH) as Texture2D
	if loaded != null:
		_cursor_tex = loaded
		return
	var img := Image.new()
	var global_path: String = ProjectSettings.globalize_path(CURSOR_PATH)
	if img.load(global_path) != OK or img.is_empty():
		push_warning("GameState: could not load cursor image at '%s'" % CURSOR_PATH)
		return
	if img.get_width() != 64 or img.get_height() != 64:
		img.resize(64, 64, Image.INTERPOLATE_LANCZOS)
	_cursor_tex = ImageTexture.create_from_image(img)

func _init_grids() -> void:
	grids = []
	bluff_emoticons = []
	for _p in range(2):
		var player_grid: Array = []
		var player_bluffs: Array = []
		for _r in range(GRID_SIZE):
			var row: Array = []
			var bluff_row: Array = []
			for _c in range(GRID_SIZE):
				var blank := CardInstance.new()
				blank.card_type = "dead_end"
				row.append(blank)
				bluff_row.append("")
			player_grid.append(row)
			player_bluffs.append(bluff_row)
		grids.append(player_grid)
		bluff_emoticons.append(player_bluffs)

func set_bluff(player: int, row: int, col: int, emoticon: String) -> void:
	bluff_emoticons[player][row][col] = emoticon

func get_bluff(player: int, row: int, col: int) -> String:
	return bluff_emoticons[player][row][col] as String

# ─────────────────────────────────────────────────────────────
# Phase Management
# ─────────────────────────────────────────────────────────────
func set_phase(new_phase: Phase) -> void:
	current_phase = new_phase
	emit_signal("phase_changed", new_phase)

# ─────────────────────────────────────────────────────────────
# Crystal Management
# ─────────────────────────────────────────────────────────────
func lose_crystals(player_index: int, amount: int, reason: String = "") -> void:
	# Risk & Reward: crystal losses cost 25% more in Daily Dungeon
	if game_mode == GameMode.DAILY_DUNGEON and "risk_and_reward" in active_dungeon_modifiers:
		amount = int(amount * 1.25)

	# OPPONENT_EXTRA_CRYSTAL_LOSS: opponent's face-up card makes this player lose extra crystals
	var extra_loss: int = 0
	var opponent_idx: int = get_opponent(player_index)
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			var opp_card: CardInstance = grids[opponent_idx][r][c]
			if opp_card.card_type == "character" and opp_card.face_up:
				if opp_card.ability_type == CharacterData.AbilityType.OPPONENT_EXTRA_CRYSTAL_LOSS:
					extra_loss += opp_card.ability_params.get("amount", 0)
	amount += extra_loss

	crystals[player_index] = max(0, crystals[player_index] - amount)
	emit_signal("crystals_changed", player_index, crystals[player_index], reason)

	# CRYSTAL_RECOVER_ON_BIG_LOSS: if this player's loss was large, recover some crystals
	if amount > 0:
		for r in range(GRID_SIZE):
			for c in range(GRID_SIZE):
				var own_card: CardInstance = grids[player_index][r][c]
				if own_card.card_type == "character" and own_card.face_up:
					if own_card.ability_type == CharacterData.AbilityType.CRYSTAL_RECOVER_ON_BIG_LOSS:
						var threshold: int = own_card.ability_params.get("threshold", 500)
						var recover: int = own_card.ability_params.get("recover", 300)
						if amount >= threshold:
							crystals[player_index] = min(crystals[player_index] + recover, crystals[player_index] + recover)
							emit_signal("crystals_changed", player_index, crystals[player_index], "recovery")
							post_message("%s: Recovered %d Crystals!" % [own_card.card_name, recover])

	_check_crystal_win_condition()

func gain_crystals(player_index: int, amount: int, reason: String = "") -> void:
	crystals[player_index] += amount
	emit_signal("crystals_changed", player_index, crystals[player_index], reason)
	SFXManager.play(SFXManager.SFX_CRYSTAL_GAIN)

func _check_crystal_win_condition() -> void:
	var p0_zero: bool = crystals[0] <= 0
	var p1_zero: bool = crystals[1] <= 0
	if p0_zero and p1_zero:
		game_over_reason = "crystals"
		_end_game(-1)  # tie
	elif p0_zero:
		game_over_reason = "crystals"
		_end_game(1)
	elif p1_zero:
		game_over_reason = "crystals"
		_end_game(0)

# ─────────────────────────────────────────────────────────────
# Grid Operations
# ─────────────────────────────────────────────────────────────
func get_card(player_index: int, row: int, col: int) -> CardInstance:
	return grids[player_index][row][col]

func set_card(player_index: int, row: int, col: int, card: CardInstance) -> void:
	card.grid_row = row
	card.grid_col = col
	grids[player_index][row][col] = card

func place_character(player_index: int, row: int, col: int, char_name: String) -> void:
	var data: CharacterData = CardDatabase.get_character(char_name)
	if data == null:
		return
	var inst := CardInstance.new()
	inst.card_type = "character"
	inst.card_name = char_name
	inst.display_name = data.display_name
	inst.face_up = false
	inst.current_atk = data.base_atk
	inst.current_def = data.base_def
	inst.base_atk = data.base_atk
	inst.base_def = data.base_def
	inst.crystal_cost = data.crystal_cost
	inst.affinity = data.affinity
	inst.ability_type = data.ability_type
	inst.ability_params = data.ability_params.duplicate()
	inst.rarity = data.rarity
	inst.grid_row = row
	inst.grid_col = col
	grids[player_index][row][col] = inst
	emit_signal("card_placed", player_index, row, col)

func place_trap(player_index: int, row: int, col: int, trap_name: String) -> void:
	var data: TrapData = CardDatabase.get_trap(trap_name)
	if data == null:
		return
	var inst := CardInstance.new()
	inst.card_type = "trap"
	inst.card_name = trap_name
	inst.display_name = data.display_name
	inst.face_up = false
	inst.crystal_cost = data.crystal_cost
	inst.rarity = data.rarity
	inst.grid_row = row
	inst.grid_col = col
	grids[player_index][row][col] = inst
	emit_signal("card_placed", player_index, row, col)

func place_dead_end(player_index: int, row: int, col: int) -> void:
	var inst := CardInstance.new()
	inst.card_type = "dead_end"
	inst.grid_row = row
	inst.grid_col = col
	grids[player_index][row][col] = inst

func reveal_card(player_index: int, row: int, col: int) -> void:
	var card: CardInstance = get_card(player_index, row, col)
	if not card.face_up:
		card.face_up = true
		card.revealed_on_turn = turn_number
		if card.card_type == "character":
			BattleResolver.recalculate_all_field_bonuses()
		emit_signal("card_revealed", player_index, row, col)

		# CRYSTAL_GAIN_ON_OPP_REVEAL: opponent gains crystals when this player's card is revealed
		var opponent_idx: int = get_opponent(player_index)
		for r in range(GRID_SIZE):
			for c in range(GRID_SIZE):
				var opp_card: CardInstance = grids[opponent_idx][r][c]
				if opp_card.card_type == "character" and opp_card.face_up:
					if opp_card.ability_type == CharacterData.AbilityType.CRYSTAL_GAIN_ON_OPP_REVEAL:
						var amt: int = opp_card.ability_params.get("amount", 40)
						gain_crystals(opponent_idx, amt, "ability")
						post_message("%s: Gained %d Crystals from reveal!" % [opp_card.card_name, amt])

		# Dungeon: Bio Triumph — Bio characters receive Mutagen flag on reveal
		# Dungeon: Nature Triumph — Nature characters receive Venom flag on reveal
		if card.card_type == "character" and game_mode == GameMode.DAILY_DUNGEON:
			if "bio_triumph" in active_dungeon_modifiers \
					and card.affinity == CharacterData.Affinity.BIO \
					and not card.has_mutagen_flag:
				apply_mutagen_flag(card)
				post_message("Bio Triumph: %s receives Mutagen flag!" % card.display_name)
			if "nature_triumph" in active_dungeon_modifiers \
					and card.affinity == CharacterData.Affinity.NATURE \
					and "venom" not in card.flags:
				card.flags.append("venom")
				post_message("Nature Triumph: %s receives Venom flag!" % card.display_name)

		# HALVE_DEF_ON_FIRST_EXPOSE: halve DEF when this card first becomes face-up
		if card.card_type == "character":
			if card.ability_type == CharacterData.AbilityType.HALVE_DEF_ON_FIRST_EXPOSE:
				card.current_def = card.current_def / 2
				post_message("%s's DEF is halved upon reveal!" % card.card_name)
			# DESTROY_SELF_AT_END_OF_EXPOSE_TURN: mark for end-of-turn self-destruction
			elif card.ability_type == CharacterData.AbilityType.DESTROY_SELF_AT_END_OF_EXPOSE_TURN:
				if "expose_destroy_pending" not in card.flags:
					card.flags.append("expose_destroy_pending")

func destroy_card(player_index: int, row: int, col: int, pay_cost: bool = true) -> void:
	var card: CardInstance = get_card(player_index, row, col)
	var was_character: bool = card.card_type == "character"
	# ONE_USE_SURVIVE_DESTRUCTION: card survives once
	if was_character:
		if card.ability_type == CharacterData.AbilityType.ONE_USE_SURVIVE_DESTRUCTION:
			if "indestructible_used" not in card.flags:
				card.flags.append("indestructible_used")
				post_message("%s survives destruction!" % card.card_name)
				return
		# Track destroyed characters in graveyard
		graveyards[player_index].append(card)
	if pay_cost and card.card_type != "dead_end":
		var _dc_cost: int = card.crystal_cost
		if game_mode == GameMode.DAILY_DUNGEON:
			if "coffin_broker" in active_dungeon_modifiers: _dc_cost = 0
			elif "coffin_dealer" in active_dungeon_modifiers: _dc_cost = int(_dc_cost * 0.5)
		lose_crystals(player_index, _dc_cost, "card lost")
	emit_signal("card_destroyed", player_index, row, col)
	place_dead_end(player_index, row, col)
	# Mark the resulting slot as revealed and destroyed so it can't be re-targeted
	grids[player_index][row][col].face_up = true
	grids[player_index][row][col].was_destroyed = true
	if was_character:
		BattleResolver.recalculate_all_field_bonuses()
		check_character_wipe_win_condition()

## Remove a trap card silently when revealed (no crystal cost, no was_destroyed flag).
## The slot becomes a plain blank dead_end — completely empty, re-targetable.
func void_trap(player_index: int, row: int, col: int) -> void:
	var blank := CardInstance.new()
	blank.card_type = "dead_end"
	blank.face_up = true
	grids[player_index][row][col] = blank

## Remove a Union material card silently (no crystal loss, no card_destroyed signal,
## no was_destroyed flag). The slot becomes a normal blank dead_end.
func remove_union_material(player_index: int, row: int, col: int) -> void:
	place_dead_end(player_index, row, col)
	# Mark face_up so it can be attacked as a normal blank slot
	grids[player_index][row][col].face_up = true

## Place a Union monster at (row, col) for player.
## The card appears face-up and behaves like a character card.
func place_union_card(player_index: int, row: int, col: int, u: UnionData) -> void:
	var inst := CardInstance.new()
	inst.card_type    = "character"
	inst.is_union     = true
	inst.card_name    = u.card_name
	inst.display_name = u.display_name
	inst.affinity     = int(u.affinity)
	inst.base_atk     = u.base_atk
	inst.base_def     = u.base_def
	inst.current_atk  = u.base_atk
	inst.current_def  = u.base_def
	inst.crystal_cost = 0   # summon cost paid at summon time; no extra loss on destroy
	inst.rarity       = int(u.rarity)
	inst.ability_type = int(u.ability_type)
	inst.ability_params = u.ability_params
	inst.face_up      = true
	inst.revealed_on_turn = turn_number
	inst.grid_row = row
	inst.grid_col = col
	grids[player_index][row][col] = inst
	emit_signal("card_revealed", player_index, row, col)
	BattleResolver.recalculate_all_field_bonuses()

func get_adjacent_positions(row: int, col: int) -> Array:
	var result: Array = []
	var dirs := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for d: Vector2i in dirs:
		var nr: int = row + d.x
		var nc: int = col + d.y
		if nr >= 0 and nr < GRID_SIZE and nc >= 0 and nc < GRID_SIZE:
			result.append(Vector2i(nr, nc))
	return result

func find_card_position(player_index: int, card_inst: CardInstance) -> Vector2i:
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if grids[player_index][r][c] == card_inst:
				return Vector2i(r, c)
	return Vector2i(-1, -1)

func get_all_face_up_characters(player_index: int) -> Array:
	var result: Array = []
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			var card: CardInstance = grids[player_index][r][c]
			if card.card_type == "character" and card.face_up:
				result.append({"card": card, "pos": Vector2i(r, c)})
	return result

func get_all_characters(player_index: int) -> Array:
	var result: Array = []
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			var card: CardInstance = grids[player_index][r][c]
			if card.card_type == "character":
				result.append({"card": card, "pos": Vector2i(r, c)})
	return result

# ─────────────────────────────────────────────────────────────
# Turn helpers
# ─────────────────────────────────────────────────────────────
func get_opponent(player_index: int) -> int:
	return 1 - player_index

## Prayer (DIVINE_PROTECTION): clears when the protected player's opponent finishes a turn.
func expire_divine_protection_at_turn_end(turn_ending_player: int) -> void:
	divine_protection_active[get_opponent(turn_ending_player)] = false

## Human-facing label: "AI Player 0/1" in AI vs AI logs, "Player 1/2" elsewhere.
func format_player_label(player_index: int) -> String:
	if game_mode == GameMode.AI_VS_AI:
		return "AI Player %d" % player_index
	return "Player %d" % (player_index + 1)

func can_player_attack(player_index: int) -> bool:
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			var card: CardInstance = grids[player_index][r][c]
			if card.card_type == "character":
				if not card.attacked_this_turn:
					if card.cannot_attack_until < turn_number:
						return true
	return false

func has_playable_tech(player_index: int) -> bool:
	for tech_name in tech_hands[player_index]:
		var data: TechCardData = CardDatabase.get_tech(tech_name)
		if data == null:
			continue
		if crystals[player_index] >= data.crystal_cost:
			# Check chain requirement
			if data.required_prior_card != "":
				if not tech_name_played_this_game(player_index, data.required_prior_card):
					continue
			return true
	return false

func tech_name_played_this_game(player_index: int, tech_name: String) -> bool:
	return tech_name in tech_cards_played_this_game[player_index]

## True when the player has no character that can attack this turn.
## Playable tech no longer prevents a stuck loss — only attack capability matters.
func is_stuck(player_index: int) -> bool:
	return not can_player_attack(player_index)

func _end_game(winner: int) -> void:
	set_phase(Phase.GAME_OVER)
	emit_signal("game_over", winner)

func force_game_over(winner: int) -> void:
	if current_phase == Phase.GAME_OVER or current_phase == Phase.NONE:
		return
	_end_game(winner)

func has_any_character(player_index: int) -> bool:
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if grids[player_index][r][c].card_type == "character":
				return true
	return false

## Ends the duel when either side has zero characters on the board.
func check_character_wipe_win_condition() -> void:
	if current_phase == Phase.GAME_OVER:
		return
	var p0_has: bool = has_any_character(0)
	var p1_has: bool = has_any_character(1)
	if p0_has and p1_has:
		return
	if not p0_has and not p1_has:
		game_over_reason = "all_destroyed"
		_end_game(-1)
	elif not p0_has:
		game_over_reason = "all_destroyed"
		_end_game(1)
	else:
		game_over_reason = "all_destroyed"
		_end_game(0)

func check_stuck_win_condition() -> void:
	if current_phase == Phase.GAME_OVER:
		return
	check_character_wipe_win_condition()
	if current_phase == Phase.GAME_OVER:
		return
	var p0_stuck := is_stuck(0)
	var p1_stuck := is_stuck(1)
	if p0_stuck and p1_stuck:
		game_over_reason = "no_moves"
		_end_game(-1)  # tie
	elif p0_stuck:
		game_over_reason = "no_moves"
		_end_game(1)
	elif p1_stuck:
		game_over_reason = "no_moves"
		_end_game(0)

# ─────────────────────────────────────────────────────────────
# New game / reset
# ─────────────────────────────────────────────────────────────
func new_game(mode: GameMode = GameMode.LOCAL_2P) -> void:
	game_mode = mode
	current_player = 0
	turn_number = 0
	crystals = [STARTING_CRYSTALS, STARTING_CRYSTALS]
	# Sudden Death: both players start with only 3 000 crystals
	if mode == GameMode.DAILY_DUNGEON and "sudden_death" in active_dungeon_modifiers:
		crystals = [3000, 3000]
	tech_hands = [[], []]
	tech_cards_played_this_game = [[], []]
	dice_result = 0
	attacks_remaining = 0
	current_mode = TurnMode.NONE
	attacker_card = null
	attacker_pos = Vector2i(-1, -1)
	defender_pos = Vector2i(-1, -1)
	divine_protection_active = [false, false]
	siege_cannon_active = [false, false]
	berserk_active = [null, null]
	skip_next_turn = [false, false]
	hypnotized_cards = [[], []]
	skip_counts = [0, 0]
	reroll_dice_available = [false, false]
	graveyards = [[], []]
	locked_attack_positions = []
	attack_cost_block_max = -1
	attack_cost_block_player = -1
	guerrilla_tactics_owner = -1
	if not _vn_battle_pending:
		battle_ai_union_enabled = true
		battle_player_union_enabled = true
		battle_player_forced_cells.clear()
		battle_ai_forced_cells.clear()
		battle_player_deck = null
		battle_ai_deck     = null
		battle_ai_forced_tech.clear()
		vn_launched_from_exploration = false
		vn_battle_rewards.clear()
	_vn_battle_pending = false
	game_over_reason = ""
	_init_grids()
	set_phase(Phase.SETUP_P1)

func apply_mutagen_flag(card: CardInstance) -> void:
	if card == null or card.card_type != "character":
		return
	card.has_mutagen_flag = true
	if "mutagen" not in card.flags:
		card.flags.append("mutagen")

func add_flag(player_index: int, row: int, col: int, flag: String) -> void:
	var card: CardInstance = get_card(player_index, row, col)
	if flag not in card.flags:
		card.flags.append(flag)
		emit_signal("card_flag_added", player_index, row, col, flag)

func remove_flag(player_index: int, row: int, col: int, flag: String) -> void:
	var card: CardInstance = get_card(player_index, row, col)
	card.flags.erase(flag)
	emit_signal("card_flag_removed", player_index, row, col, flag)

func post_message(text: String) -> void:
	emit_signal("message_posted", text)

func show_center_message(text: String) -> void:
	emit_signal("message_posted", text)
	emit_signal("center_message_requested", text)
