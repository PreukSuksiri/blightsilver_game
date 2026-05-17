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
enum GameMode { LOCAL_2P, VS_AI, HOT_SEAT, CAMPAIGN }

# ─────────────────────────────────────────────────────────────
# Signals
# ─────────────────────────────────────────────────────────────
signal phase_changed(new_phase: Phase)
signal turn_changed(player_index: int)
signal crystals_changed(player_index: int, new_amount: int)
signal card_revealed(player_index: int, row: int, col: int)
signal card_destroyed(player_index: int, row: int, col: int)
signal dice_rolled(result: int)
signal game_over(winner: int)  # -1 = tie, 0 = player 1, 1 = player 2
signal tech_card_used(player_index: int, card_name: String)
signal card_effect_triggered(card_name: String, card_type: String)
signal attack_used(player_index: int, attacks_remaining: int)
signal message_posted(text: String)
signal card_flag_added(player_index: int, row: int, col: int, flag: String)
signal card_flag_removed(player_index: int, row: int, col: int, flag: String)
signal card_atk_changed(player_index: int, row: int, col: int, old_val: int, new_val: int)
signal card_def_changed(player_index: int, row: int, col: int, old_val: int, new_val: int)
signal bluff_changed(player_index: int, row: int, col: int, emoticon: String)
signal attack_target_selected(attacker_player: int, target_player: int, row: int, col: int)
signal tech_target_selected(user_player: int, target_player: int, row: int, col: int)

# ─────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────
const GRID_SIZE: int = 5
const STARTING_CRYSTALS: int = 5000
const STARTING_TECH_HAND: int = 3
const MIN_CHARACTERS: int = 8
const MAX_CHARACTERS: int = 12
const MIN_TRAPS: int = 4
const MAX_TRAPS: int = 6

# ─────────────────────────────────────────────────────────────
# CardInstance – Runtime card state on the grid
# ─────────────────────────────────────────────────────────────
class CardInstance:
	var card_type: String = ""       # "character", "trap", "dead_end"
	var was_destroyed: bool = false  # true when this slot was cleared by destroy_card
	var card_name: String = ""
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
	var attacked_this_turn: bool = false
	var cannot_attack_until: int = -1  # Turn number when restriction lifts
	var effect_nullified_until: int = -1
	var one_use_def_boost_used: bool = false
	var perm_atk_bonus: int = 0
	var perm_def_bonus: int = 0
	var temp_atk_bonus: int = 0
	var temp_def_bonus: int = 0
	var force_shielded: bool = false
	var halved: bool = false
	var mutagen_attacked: bool = false # Mutagen immediate attack used
	var atk_debuff: int = 0
	var revealed_on_turn: int = -1       # set to turn_number when flipped face-up; -1 = never
	var flags: Array[String] = []        # string tags: "bio", "cosmic", "mutagen", etc.
	var active_rules: Array = []         # Array of CardRule — populated by CardRuleEngine

	func get_effective_atk() -> int:
		return max(0, current_atk + perm_atk_bonus + temp_atk_bonus - atk_debuff)

	func get_effective_def() -> int:
		return max(0, current_def + perm_def_bonus + temp_def_bonus)

	func clear_temp_buffs() -> void:
		temp_atk_bonus = 0
		temp_def_bonus = 0
		atk_debuff = 0

	func halve_stats() -> void:
		if not halved:
			current_atk = current_atk / 2
			current_def = current_def / 2
			halved = true

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

var crystals: Array = [STARTING_CRYSTALS, STARTING_CRYSTALS]
var grids: Array = []           # grids[player][row][col] -> CardInstance
var bluff_emoticons: Array = []  # bluff_emoticons[player][row][col] -> String ("")
var tech_hands: Array = [[], []]  # tech_hands[player] -> Array of TechCardData names
var dice_result: int = 0
var attacks_remaining: int = 0
var current_mode: TurnMode = TurnMode.NONE
var attacker_card: CardInstance = null
var attacker_pos: Vector2i = Vector2i(-1, -1)

# Track which tech cards have been played (for chain requirements)
var tech_cards_played_this_game: Array = [[], []]

# Special global flags
# VN-driven battle outcome routing (set by VNPlayer after new_game(), persists across scene change)
var vn_on_win: String = ""
var vn_on_lose: String = ""
var portrait_p1_offset: Vector2 = Vector2.ZERO
var portrait_p1_size:   float   = 1.0
var portrait_p2_offset: Vector2 = Vector2.ZERO
var portrait_p2_size:   float   = 1.0

# Battle BGM (set by VNPlayer or defaults; not reset by new_game())
var battle_bgm_path: String = "res://assets/audio/bgm_battle_2.mp3"
var battle_bgm_volume: float = 100.0   # percentage  (100 = 0 dB)

# Battle placement/summon config — set by VNPlayer before scene change.
# _vn_battle_pending = true tells new_game() to preserve these values instead of resetting them.
var _vn_battle_pending: bool = false
var battle_ai_union_enabled: bool = true
var battle_player_union_enabled: bool = true
var battle_player_forced_cells: Array = []  # Array[Dictionary{card_name, row, col}]
var battle_ai_forced_cells: Array = []      # Array[Dictionary{card_name, row, col}]

var divine_protection_active: Array = [false, false]
var siege_cannon_active: Array = [false, false]
var berserk_active: Array = [null, null]     # CardInstance or null
var skip_next_turn: Array = [false, false]
var hypnotized_cards: Array = [[], []]       # List of CardInstances that can't attack
var skip_counts: Array = [0, 0]              # Consecutive no-attack turns per player (for doubling tax)

func _ready() -> void:
	_init_grids()
	_apply_custom_cursor()

func _apply_custom_cursor() -> void:
	var img := Image.load_from_file(
		ProjectSettings.globalize_path("res://assets/textures/ui/decorations/ui_cursor_64.png"))
	if img == null:
		return
	var tex := ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2(2.0, 2.0))

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
func lose_crystals(player_index: int, amount: int) -> void:
	crystals[player_index] = max(0, crystals[player_index] - amount)
	emit_signal("crystals_changed", player_index, crystals[player_index])
	_check_crystal_win_condition()

func gain_crystals(player_index: int, amount: int) -> void:
	crystals[player_index] += amount
	emit_signal("crystals_changed", player_index, crystals[player_index])

func _check_crystal_win_condition() -> void:
	var p0_zero: bool = crystals[0] <= 0
	var p1_zero: bool = crystals[1] <= 0
	if p0_zero and p1_zero:
		_end_game(-1)  # tie
	elif p0_zero:
		_end_game(1)
	elif p1_zero:
		_end_game(0)

# ─────────────────────────────────────────────────────────────
# Grid Operations
# ─────────────────────────────────────────────────────────────
func get_card(player_index: int, row: int, col: int) -> CardInstance:
	return grids[player_index][row][col]

func set_card(player_index: int, row: int, col: int, card: CardInstance) -> void:
	grids[player_index][row][col] = card

func place_character(player_index: int, row: int, col: int, char_name: String) -> void:
	var data: CharacterData = CardDatabase.get_character(char_name)
	if data == null:
		return
	var inst := CardInstance.new()
	inst.card_type = "character"
	inst.card_name = char_name
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
	grids[player_index][row][col] = inst

func place_trap(player_index: int, row: int, col: int, trap_name: String) -> void:
	var data: TrapData = CardDatabase.get_trap(trap_name)
	if data == null:
		return
	var inst := CardInstance.new()
	inst.card_type = "trap"
	inst.card_name = trap_name
	inst.face_up = false
	inst.crystal_cost = data.crystal_cost
	inst.rarity = data.rarity
	grids[player_index][row][col] = inst

func place_dead_end(player_index: int, row: int, col: int) -> void:
	var inst := CardInstance.new()
	inst.card_type = "dead_end"
	grids[player_index][row][col] = inst

func reveal_card(player_index: int, row: int, col: int) -> void:
	var card: CardInstance = get_card(player_index, row, col)
	if not card.face_up:
		card.face_up = true
		card.revealed_on_turn = turn_number
		emit_signal("card_revealed", player_index, row, col)

func destroy_card(player_index: int, row: int, col: int, pay_cost: bool = true) -> void:
	var card: CardInstance = get_card(player_index, row, col)
	if pay_cost and card.card_type != "dead_end":
		lose_crystals(player_index, card.crystal_cost)
	emit_signal("card_destroyed", player_index, row, col)
	place_dead_end(player_index, row, col)
	# Mark the resulting slot as revealed and destroyed so it can't be re-targeted
	grids[player_index][row][col].face_up = true
	grids[player_index][row][col].was_destroyed = true

## Remove a trap card silently when revealed (no crystal cost, no was_destroyed flag).
## The slot becomes a plain blank dead_end — completely empty, re-targetable.
func void_trap(player_index: int, row: int, col: int) -> void:
	var blank := CardInstance.new()
	blank.card_type = "dead_end"
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
	inst.affinity     = int(u.affinity)
	inst.base_atk     = u.base_atk
	inst.base_def     = u.base_def
	inst.current_atk  = u.base_atk
	inst.current_def  = u.base_def
	inst.crystal_cost = u.summon_cost   # crystal loss = summon cost if destroyed
	inst.rarity       = int(u.rarity)
	inst.ability_type = int(u.ability_type)
	inst.ability_params = u.ability_params
	inst.face_up      = true
	inst.revealed_on_turn = turn_number
	grids[player_index][row][col] = inst
	emit_signal("card_revealed", player_index, row, col)

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

func is_stuck(player_index: int) -> bool:
	return not can_player_attack(player_index) and not has_playable_tech(player_index)

func _end_game(winner: int) -> void:
	set_phase(Phase.GAME_OVER)
	emit_signal("game_over", winner)

func force_game_over(winner: int) -> void:
	if current_phase == Phase.GAME_OVER or current_phase == Phase.NONE:
		return
	_end_game(winner)

func check_stuck_win_condition() -> void:
	var p0_stuck := is_stuck(0)
	var p1_stuck := is_stuck(1)
	if p0_stuck and p1_stuck:
		_end_game(-1)  # tie
	elif p0_stuck:
		_end_game(1)
	elif p1_stuck:
		_end_game(0)

# ─────────────────────────────────────────────────────────────
# New game / reset
# ─────────────────────────────────────────────────────────────
func new_game(mode: GameMode = GameMode.LOCAL_2P) -> void:
	game_mode = mode
	current_player = 0
	turn_number = 0
	crystals = [STARTING_CRYSTALS, STARTING_CRYSTALS]
	tech_hands = [[], []]
	tech_cards_played_this_game = [[], []]
	dice_result = 0
	attacks_remaining = 0
	current_mode = TurnMode.NONE
	attacker_card = null
	attacker_pos = Vector2i(-1, -1)
	divine_protection_active = [false, false]
	siege_cannon_active = [false, false]
	berserk_active = [null, null]
	skip_next_turn = [false, false]
	hypnotized_cards = [[], []]
	skip_counts = [0, 0]
	if not _vn_battle_pending:
		battle_ai_union_enabled = true
		battle_player_union_enabled = true
		battle_player_forced_cells.clear()
		battle_ai_forced_cells.clear()
	_vn_battle_pending = false
	_init_grids()
	set_phase(Phase.SETUP_P1)

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
