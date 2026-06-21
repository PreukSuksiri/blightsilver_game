class_name AIPlayer
extends Node
# "Training" personality AI for VS_AI and Campaign modes.

const BLUFF_ANIM_SECS: float = 0.42   # slightly over GameBoard.BLUFF_ANIM_DURATION (0.38s)

var player_index: int = 1    # which player this AI controls (0 or 1)
var opponent_index: int = 0  # the other player

func init_as(pi: int) -> void:
	player_index   = pi
	opponent_index = 1 - pi

# ─────────────────────────────────────────────────────────────
# E2E test helpers — only active when CardE2ERunner is running
# and this instance controls player 0 (the highlight card side).
# ─────────────────────────────────────────────────────────────

## True when this AI is the "highlight player" in an E2E test (P0 only).
func _e2e_is_highlight_player() -> bool:
	return player_index == 0 and CardE2ERunner.is_active()

## The card name the current E2E scenario is testing (empty outside E2E).
func _e2e_highlight_card() -> String:
	if not _e2e_is_highlight_player():
		return ""
	return str(CardE2ERunner.get_current_scenario().get("card_name", ""))

## The name of the P0 card that should be forced to attack in E2E mode.
## For character scenarios this equals card_name (the tested card IS the attacker).
## For trap scenarios card_name is the trap (on P1's side), so we use the first
## forced_cells_0 entry instead — that is P0's designated attacker (e.g. Ox Patrol).
func _e2e_forced_attacker_name() -> String:
	if not _e2e_is_highlight_player():
		return ""
	var fc0: Array = AIvsAIManager.forced_cells_0
	if not fc0.is_empty():
		return str((fc0[0] as Dictionary).get("card_name", ""))
	return _e2e_highlight_card()

## True when this AI player is allowed to play Tech cards in the current context.
## In E2E:
##   P0 — only allowed when the scenario IS testing a Tech card (card_type == "Tech").
##   P1 — never allowed (prevents Radar/Spy/Tease from disrupting P0's setup).
## Outside E2E: always allowed.
func _e2e_tech_allowed() -> bool:
	if not CardE2ERunner.is_active():
		return true
	if player_index == 0:
		if CardE2ERunner.get_current_scenario().get("card_type", "") == "Tech":
			return true
		# Also allow when the scenario specifies setup techs that must be played first.
		var fst: Array = CardE2ERunner.get_current_scenario().get("e2e_force_setup_tech", [])
		return not fst.is_empty()
	return false  # P1 never plays tech in E2E

# Pre-compiled regex for integer extraction in decide_trap_choice
var _int_regex: RegEx = RegEx.new()

func _ready() -> void:
	_int_regex.compile("\\d+")

signal ai_mode_chosen(mode: GameState.TurnMode)
signal ai_attack_chosen(attacker_pos: Vector2i, target_pos: Vector2i)
signal ai_tech_chosen(tech_name: String)
signal ai_target_chosen(pos: Vector2i)
signal ai_trap_choice(choice_index: int)
signal ai_end_turn
signal ai_union_chosen(union_name: String, zone_cells: Array, material_cells: Array)
signal ai_bluff(player: int, row: int, col: int, emoticon: String)

# Per-duel state
var _ai_turn_count: int = 0   # incremented at start of each decide_turn call
var _union_used:    bool = false
var _pending_death_bluff: Vector2i = Vector2i(-1, -1)  # set when AI card dies; flushed on next AI turn
var _aborted_attackers_this_turn: Array = []  # positions excluded after attack_aborted this turn
var _last_chosen_attacker_pos: Vector2i = Vector2i(-1, -1)

# Trailer personality flags (set by admin console; excluded from random pool)
var _trailer_offensive: bool = false
var _trailer_defensive: bool = false
var _trailer_social:    bool = false

# Personality names selected for this game (set by _pick_personalities; readable by AIvsAIManager)
var personality_defensive: String = ""
var personality_offensive: String = ""
var personality_social:    String = ""

# ── Personality system (assigned once per game in decide_setup) ──
var _def_zone:       String  = ""            # defensive formation zone key
var _union_concern:  String  = "normal"      # "none" | "normal" | "high"
var _attack_zone:    String  = "random_off"  # offensive zone key
var _expose_mode:    String  = "normal"      # "all" | "cautious" | "kill_triggered" | "normal"
var _skip_turns:     int     = 0             # skip N turns if opp has nothing revealed
var _bluff_freq:     float   = 0.30          # per-turn bluff probability
var _bluff_pool:     Array   = []            # weighted emoji pool (strings)
var _emoji_reactions: Dictionary = {}        # emoji -> int (-1 avoid / 0 neutral / 1 interested)
var _cluster_origin: Vector2i = Vector2i(1, 1)
var _line_axis:      int     = 0             # 0 = row line, 1 = column line
var _line_idx:       int     = 2             # which row or col index
var _zone_axis:      int     = 0             # current row/col for sweep zones
var _zone_dir:       int     = 1             # sweep direction (+1 or -1)
var _ai_kill_count:  int     = 0             # kills scored this game

func _game_is_over() -> bool:
	return GameState.current_phase == GameState.Phase.GAME_OVER


# Called at the start of each AI action opportunity (start of turn, after each attack, after tech).
func decide_turn() -> void:
	if _game_is_over():
		return
	_ai_turn_count += 1
	_aborted_attackers_this_turn.clear()
	await get_tree().create_timer(0.6).timeout

	# Tutorial: first two AI turns attack corners/center only — skip tech/union.
	if not _tutorial_early_attack_phase():
		# Rule 1: Tech priority — only enter TECH mode if a card actually scores > 0.
		# In E2E mode, tech is suppressed unless this scenario specifically tests a Tech card.
		if _e2e_tech_allowed() and GameState.has_playable_tech(player_index) and _has_useful_tech():
			emit_signal("ai_mode_chosen", GameState.TurnMode.TECH)
			await get_tree().create_timer(0.3).timeout
			_choose_tech()
			return

		# Rule 2: Union summon — hesitation eases over successive AI turns.
		# Turn 1: 10%, Turn 2: 35%, Turn 3: 60%, Turn 4+: 85%
		# In E2E mode all players summon immediately (100%) so unions are guaranteed.
		# Exception: P0 skips unions entirely in non-union E2E scenarios so the highlight
		# card is never accidentally consumed as union material.
		var _e2e_no_union: bool = CardE2ERunner.is_active() and player_index == 0 \
				and not CardE2ERunner.is_union_test()
		if not _e2e_no_union and not _trailer_offensive and not _union_used and GameState.battle_ai_union_enabled:
			var chance: float = 1.0 if CardE2ERunner.is_active() \
					else minf(0.85, 0.10 + (_ai_turn_count - 1) * 0.25)
			if randf() < chance:
				var unions: Array = _get_available_unions()
				if not unions.is_empty():
					# E2E: for union-test scenarios where the highlight card IS the union
					# (role contains "union"), restrict P0 to only summon that union so
					# competing unions cannot hijack the test.
					# For non-union highlight cards that merely need a union on field
					# (e.g. ATK_DEF_BONUS_IF_UNION_ON_FIELD), skip the filter so P0
					# can freely summon whatever union is available.
					if CardE2ERunner.is_active() and player_index == 0 and CardE2ERunner.is_union_test():
						var _e2e_role: String = str(CardE2ERunner.get_current_scenario().get("role", ""))
						if _e2e_role.contains("union"):
							var _e2e_union: String = str(CardE2ERunner.get_current_scenario().get("card_name", ""))
							if _e2e_union != "":
								unions = unions.filter(func(e: Dictionary) -> bool:
									return (e["union"] as UnionData).card_name == _e2e_union)
					if _tutorial_ai_active():
						unions = unions.filter(func(e: Dictionary) -> bool:
							return (e["union"] as UnionData).card_name == _TUTORIAL_AI_UNION_NAME)
					if not unions.is_empty():
						_union_used = true
						var picked: Dictionary = _pick_best_union(unions)
						var u: UnionData = picked["union"]
						emit_signal("ai_union_chosen", u.card_name, picked["zone_cells"], picked["material_cells"])
						return

	_do_attack_decision()

## Called when TurnManager aborts an attack the AI just attempted.
func register_attack_aborted(attacker_pos: Vector2i = Vector2i(-1, -1)) -> void:
	var pos: Vector2i = attacker_pos if attacker_pos.x >= 0 else _last_chosen_attacker_pos
	if pos.x < 0:
		return
	if pos not in _aborted_attackers_this_turn:
		_aborted_attackers_this_turn.append(pos)


## Continuation called by GameBoard after union summon resolves, so the AI
## can still attack in the same turn without re-incrementing the turn counter.
func continue_after_union() -> void:
	if _game_is_over():
		return
	# In E2E, the non-highlight player (P1) ends the turn immediately after
	# summoning a union.  This guarantees P0's highlight card can engage the
	# union on the following turn instead of being destroyed by it first.
	if CardE2ERunner.is_active() and player_index != 0:
		await get_tree().create_timer(0.3).timeout
		emit_signal("ai_end_turn")
		return
	await get_tree().create_timer(0.5).timeout
	if _game_is_over():
		return
	_do_attack_decision()

func _do_attack_decision() -> void:
	if _game_is_over():
		return
	if not GameState.can_player_attack(player_index):
		emit_signal("ai_end_turn")
		return
	# No attacks remaining — end turn unless a unit still has a bonus non-char attack.
	if GameState.attacks_remaining <= 0 and not _has_pending_multi_attack_attacker():
		emit_signal("ai_end_turn")
		return
	# Personality: skip early turns if opponent has nothing revealed yet
	# (bypassed for E2E highlight player and tutorial early attack phase)
	if not _tutorial_early_attack_phase() \
			and not _e2e_is_highlight_player() \
			and _skip_turns > 0 and _ai_turn_count <= _skip_turns \
			and _count_faceup(opponent_index) == 0:
		await get_tree().create_timer(2.0).timeout
		emit_signal("ai_end_turn")
		return
	# Personality: advance sweep/focus axis if current one is exhausted or blocked
	_maybe_advance_sweep_axis()
	var attack: Dictionary = _choose_best_attack()
	var attacker_pos: Vector2i = attack.get("attacker_pos", Vector2i(-1, -1))
	var target_pos: Vector2i = attack.get("target_pos", Vector2i(-1, -1))
	if attacker_pos.x == -1 or target_pos.x == -1:
		await get_tree().create_timer(2.0).timeout
		emit_signal("ai_end_turn")
		return
	_last_chosen_attacker_pos = attacker_pos
	emit_signal("ai_mode_chosen", GameState.TurnMode.ATTACK)
	await get_tree().create_timer(0.3).timeout
	emit_signal("ai_attack_chosen", attacker_pos, target_pos)

# ─────────────────────────────────────────────────────────────
# Attack selection — pick the best (attacker, target) pair jointly
# ─────────────────────────────────────────────────────────────
const _REVEAL_ATTACKER_PENALTY: int = 12  # cost of revealing a face-down attacker
const _EXPECTED_ATTACK_DICE: int = 3      # d6 re-roll-on-6 → uniform 1–5, mean 3
const _TUTORIAL_RESTRICTED_TURNS: int = 2 # tutorial AI: corner/center attacks only
const _TUTORIAL_AI_UNION_NAME: String = "Berserk Hyena" # tutorial AI: only this union


func _tutorial_ai_active() -> bool:
	return TutorialBattleManager.is_active and player_index == 1

func _tutorial_early_attack_phase() -> bool:
	return _tutorial_ai_active() and _ai_turn_count <= _TUTORIAL_RESTRICTED_TURNS

func _is_tutorial_priority_cell(pos: Vector2i) -> bool:
	var last: int = GameState.GRID_SIZE - 1
	var center: int = GameState.GRID_SIZE / 2
	var on_corner: bool = (pos.x == 0 or pos.x == last) and (pos.y == 0 or pos.y == last)
	var on_center: bool = pos.x == center and pos.y == center
	return on_corner or on_center


func _choose_best_attack() -> Dictionary:
	var none: Dictionary = {"attacker_pos": Vector2i(-1, -1), "target_pos": Vector2i(-1, -1)}
	var eligible: Array = _restrict_to_multi_attack_bonus_chain(_get_eligible_attackers())
	if eligible.is_empty():
		return none

	# E2E FORCED MODE: bypass scoring entirely.
	# If a highlight card exists and hasn't attacked yet, force it to attack the
	# first live forced P1 cell. The +score bias approach is unreliable because
	# face-up units (e.g. a freshly summoned union) naturally outscore face-down
	# highlight cards even with the bonus. Only falls back to normal scoring when
	# the highlight card is gone/already attacked, or no forced target remains.
	if CardE2ERunner.is_active():
		var hl := _e2e_forced_attacker_name()
		if hl != "":
			var forced := _e2e_forced_attack(hl)
			if forced.get("attacker_pos", Vector2i(-1, -1)).x != -1:
				return forced
			# For ability-gated scenarios (e.g. ATK_BONUS_VS_UNION waiting for P1
			# to summon), suppress all random attacks to preserve P1's setup cards.
			var ability: String = str(CardE2ERunner.get_current_scenario().get("ability_type", ""))
			if ability == "ATK_BONUS_VS_UNION" and _e2e_opponent_union_pos().x == -1:
				return none

	var best_attacker: Vector2i = Vector2i(-1, -1)
	var best_target: Vector2i = Vector2i(-1, -1)
	var best_score: int = -9999

	for entry: Dictionary in eligible:
		var attacker_pos: Vector2i = entry["pos"]
		var reveal_penalty: int = _REVEAL_ATTACKER_PENALTY if entry.get("needs_reveal", false) else 0
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var target_pos: Vector2i = Vector2i(r, c)
				if _tutorial_early_attack_phase() and not _is_tutorial_priority_cell(target_pos):
					continue
				if target_pos in GameState.locked_attack_positions:
					continue
				var target: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
				if target.was_destroyed:
					continue
				var sc: int = _score_attack(attacker_pos, target_pos) + randi() % 3 - reveal_penalty
				if sc > best_score:
					best_score = sc
					best_attacker = attacker_pos
					best_target = target_pos

	if best_attacker.x == -1:
		return none
	# Tutorial early turns: always take the best corner/center option (even a scout).
	if _tutorial_early_attack_phase():
		return {"attacker_pos": best_attacker, "target_pos": best_target}
	# Skip hopeless attacks when a better attacker exists but wasn't chosen due to noise —
	# and when every option is clearly bad (no kill, no worthwhile scout).
	if best_score < 0 and not _has_positive_attack_option(eligible):
		return none
	return {"attacker_pos": best_attacker, "target_pos": best_target}


## E2E helper: directly returns {attacker_pos, target_pos} for the highlight card.
## For ATK_BONUS_VS_UNION scenarios, waits until P1 has a union on the field
## before attacking (returns none if no P1 union yet). For all other scenarios,
## attacks the first live forced P1 cell immediately.
## Returns the empty-pos dict when conditions are not yet met or the highlight
## card has already attacked — in those cases _choose_best_attack ends the turn.
func _e2e_forced_attack(highlight_name: String) -> Dictionary:
	var none: Dictionary = {"attacker_pos": Vector2i(-1, -1), "target_pos": Vector2i(-1, -1)}

	# Find the highlight card on P0's grid.
	var hl_pos: Vector2i = Vector2i(-1, -1)
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_name == highlight_name \
					and card.card_type == "character" \
					and not card.was_destroyed \
					and not card.attacked_this_turn:
				hl_pos = Vector2i(r, c)
				break
		if hl_pos.x != -1:
			break
	if hl_pos.x == -1:
		return none  # not on field or already attacked

	# ATK_BONUS_VS_UNION: wait until P1 has summoned a union, then attack it.
	var ability: String = str(CardE2ERunner.get_current_scenario().get("ability_type", ""))
	if ability == "ATK_BONUS_VS_UNION":
		var union_pos: Vector2i = _e2e_opponent_union_pos()
		if union_pos.x == -1:
			return none  # P1 hasn't summoned union yet — end turn and wait
		return {"attacker_pos": hl_pos, "target_pos": union_pos}

	# Standard: attack the first live forced P1 cell.
	var target_pos: Vector2i = Vector2i(-1, -1)
	for _fc_v: Variant in AIvsAIManager.forced_cells_1:
		var _fc: Dictionary = _fc_v as Dictionary
		var r: int = int(_fc.get("row", -1))
		var c: int = int(_fc.get("col", -1))
		if r < 0 or c < 0:
			continue
		var tgt: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
		if not tgt.was_destroyed:
			target_pos = Vector2i(r, c)
			break
	if target_pos.x == -1:
		return none  # forced target already destroyed

	return {"attacker_pos": hl_pos, "target_pos": target_pos}


## E2E helper: find P1's union card position. Returns (-1,-1) if none.
func _e2e_opponent_union_pos() -> Vector2i:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
			if card.card_type == "character" and card.is_union and not card.was_destroyed:
				return Vector2i(r, c)
	return Vector2i(-1, -1)


## True if any eligible attacker has a non-negative target worth taking.
func _has_positive_attack_option(eligible: Array) -> bool:
	for entry: Dictionary in eligible:
		var attacker_pos: Vector2i = entry["pos"]
		var reveal_penalty: int = _REVEAL_ATTACKER_PENALTY if entry.get("needs_reveal", false) else 0
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var target_pos: Vector2i = Vector2i(r, c)
				if target_pos in GameState.locked_attack_positions:
					continue
				var target: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
				if target.was_destroyed:
					continue
				var attacker: GameState.CardInstance = GameState.get_card(
						player_index, attacker_pos.x, attacker_pos.y)
				if _score_attack(attacker_pos, target_pos) - reveal_penalty \
						- _attacker_quality_penalty_for_card(attacker) >= 0:
					return true
	return false


## Deprioritize 0-ATK walls and other units that cannot meaningfully fight.
func _attacker_quality_penalty(attacker_pos: Vector2i) -> int:
	var attacker: GameState.CardInstance = GameState.get_card(
			player_index, attacker_pos.x, attacker_pos.y)
	return _attacker_quality_penalty_for_card(attacker)


func _attacker_quality_penalty_for_card(attacker: GameState.CardInstance) -> int:
	var atk: int = attacker.get_effective_atk()
	if atk <= 0:
		return 40
	if atk < 20:
		return 15
	return 0


## Mirrors TurnManager pre-attack gates so the AI does not retry blocked units.
func _restrict_to_multi_attack_bonus_chain(eligible: Array) -> Array:
	var bonus_only: Array = []
	for entry: Dictionary in eligible:
		var pos: Vector2i = entry["pos"]
		var card: GameState.CardInstance = GameState.get_card(player_index, pos.x, pos.y)
		if card.has_pending_bonus_attack_chain():
			bonus_only.append(entry)
	if bonus_only.is_empty():
		return eligible
	return bonus_only


func _has_pending_multi_attack_attacker() -> bool:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.has_pending_bonus_attack_chain():
				return true
	return false


func _can_unit_attack(card: GameState.CardInstance) -> bool:
	if GameState.attack_cost_block_player == player_index \
			and GameState.attack_cost_block_max >= 0 \
			and card.crystal_cost <= GameState.attack_cost_block_max:
		return false
	if card.ability_type == CharacterData.AbilityType.CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD:
		var allowed: Array = card.ability_params.get("allowed", [])
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var ally: GameState.CardInstance = GameState.get_card(player_index, r, c)
				if ally == card or ally.card_type != "character" or not ally.face_up:
					continue
				if ally.affinity not in allowed:
					return false
	return true


## All characters that can attack this turn, respecting reveal limits.
func _get_eligible_attackers() -> Array:
	var opponent_faceup: int = _count_faceup(opponent_index)
	var ai_faceup: int = _count_faceup(player_index)
	var faceup_attackers: Array = []
	var facedown_attackers: Array = []

	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type != "character":
				continue
			if card.attacked_this_turn:
				continue
			if card.cannot_attack_until >= GameState.turn_number:
				continue
			if GameState.berserk_active[player_index] != null:
				if GameState.berserk_active[player_index] != card:
					continue
			var pos: Vector2i = Vector2i(r, c)
			if pos in _aborted_attackers_this_turn:
				continue
			if not _can_unit_attack(card):
				continue
			if GameState.attacks_remaining <= 0 and not card.has_pending_bonus_attack_chain():
				continue
			if card.face_up:
				faceup_attackers.append(pos)
			else:
				facedown_attackers.append(pos)

	var eligible: Array = []
	for pos_v in faceup_attackers:
		eligible.append({"pos": pos_v, "needs_reveal": false})

	if facedown_attackers.is_empty():
		return eligible

	var max_ai_faceup: int = _max_allowed_faceup(opponent_faceup)
	if ai_faceup >= max_ai_faceup:
		# E2E: even at the reveal limit, always allow the highlight card to attack.
		# Without this, a face-down highlight card is silently excluded once a
		# union (face-up) raises ai_faceup to the allowed ceiling.
		_e2e_force_highlight_into_eligible(facedown_attackers, eligible)
		return eligible

	# Prefer adjacent face-down attackers when several can be revealed (same as before).
	var adjacent: Array = []
	for pos_v in facedown_attackers:
		var pos: Vector2i = pos_v
		for ap_v in GameState.get_adjacent_positions(pos.x, pos.y):
			var ap: Vector2i = ap_v
			var neighbor: GameState.CardInstance = GameState.get_card(player_index, ap.x, ap.y)
			if neighbor.card_type == "character" and neighbor.face_up:
				adjacent.append(pos)
				break

	var reveal_pool: Array = adjacent if not adjacent.is_empty() else facedown_attackers
	for pos_v in reveal_pool:
		eligible.append({"pos": pos_v, "needs_reveal": true})
	return eligible


## E2E helper: if a face-down highlight card exists in facedown_attackers but is
## not yet in eligible, append it so the +2000 score bias can take effect.
func _e2e_force_highlight_into_eligible(facedown_attackers: Array, eligible: Array) -> void:
	var hl: String = _e2e_forced_attacker_name()
	if hl.is_empty():
		return
	for pos_v: Variant in facedown_attackers:
		var pos: Vector2i = pos_v
		var card: GameState.CardInstance = GameState.get_card(player_index, pos.x, pos.y)
		if card.card_name != hl:
			continue
		for e: Variant in eligible:
			if (e as Dictionary).get("pos", Vector2i(-1, -1)) == pos:
				return  # already present
		eligible.append({"pos": pos, "needs_reveal": true})
		return  # only one highlight card needed


func _max_allowed_faceup(opponent_faceup: int) -> int:
	match _expose_mode:
		"all":
			return 25
		"cautious":
			return randi_range(1, 2)
		"kill_triggered":
			return 25 if _ai_kill_count >= 1 else randi_range(1, 2)
		_:
			if opponent_faceup == 0:
				return randi_range(1, 2)
			return opponent_faceup


# Legacy helpers kept for readability in other code paths if needed.
func _choose_attacker() -> Vector2i:
	var attack: Dictionary = _choose_best_attack()
	return attack.get("attacker_pos", Vector2i(-1, -1))


func _choose_target_for(attacker_pos: Vector2i) -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_score: int = -9999

	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var pos: Vector2i = Vector2i(r, c)
			# Skip locked targets
			if pos in GameState.locked_attack_positions:
				continue
			var card: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
			# Skip visibly destroyed slots (was_destroyed is shown as an empty cell)
			if card.was_destroyed:
				continue
			var sc: int = _score_attack(attacker_pos, pos) + randi() % 3
			if sc > best_score:
				best_score = sc
				best_pos = pos

	return best_pos

## Score an attack from attacker_pos onto target_pos. Higher = more desirable.
func _score_attack(attacker_pos: Vector2i, target_pos: Vector2i) -> int:
	var attacker: GameState.CardInstance = GameState.get_card(player_index, attacker_pos.x, attacker_pos.y)
	var target: GameState.CardInstance   = GameState.get_card(opponent_index, target_pos.x, target_pos.y)

	var base: int
	if target.was_destroyed:
		base = -100  # visibly destroyed/empty cell — avoid
	elif not target.face_up:
		base = 25   # face-down unknown — treat all the same regardless of actual card type
	elif target.card_type == "trap":
		base = 15   # hitting a trap is risky but better than nothing
	else:
		# Revealed character — estimate outcome with ability-aware ATK
		var eff_atk: int = attacker.get_effective_atk() + _EXPECTED_ATTACK_DICE
		match attacker.ability_type:
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY:
				if target.affinity == attacker.ability_params.get("affinity", -1):
					eff_atk += attacker.ability_params.get("bonus", 0)
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY:
				if target.affinity == attacker.ability_params.get("affinity", -1):
					eff_atk += attacker.ability_params.get("atk", 0)
			CharacterData.AbilityType.ATK_BONUS_VS_TWO_AFFINITIES:
				if target.affinity == attacker.ability_params.get("aff1", -1) \
						or target.affinity == attacker.ability_params.get("aff2", -1):
					eff_atk += attacker.ability_params.get("bonus", 0)
			CharacterData.AbilityType.ATK_BONUS_IF_DICE_HIGH:
				eff_atk += attacker.ability_params.get("bonus", 0) / 2
			CharacterData.AbilityType.ATK_BOOST_VS_REVEALED:
				eff_atk += attacker.ability_params.get("bonus", 0)
			CharacterData.AbilityType.ATK_BONUS_VS_UNION:
				if target.is_union:
					eff_atk += attacker.ability_params.get("bonus", 0)
		var eff_def: int = target.get_effective_def()
		if eff_atk > eff_def:
			base = 80 + target.crystal_cost / 20
		elif eff_atk == eff_def:
			base = 20 - attacker.crystal_cost / 30
		else:
			base = -30 - attacker.crystal_cost / 20

	# Personality: offensive zone bias
	base += _score_pos_offensive(target_pos)

	# Personality: emoji reaction bias
	var opp_emoji: String = GameState.get_bluff(opponent_index, target_pos.x, target_pos.y)
	if opp_emoji == "💩":   # normalize NSFW variant to canonical key
		opp_emoji = "🖕"
	if _trailer_offensive:
		# Always attack 💩/🖕 cells first — massive priority override
		if opp_emoji == "🖕":
			base += 999
	elif opp_emoji != "" and _emoji_reactions.has(opp_emoji):
		base += (_emoji_reactions[opp_emoji] as int) * 15

	return base

# ─────────────────────────────────────────────────────────────
# Tech selection
# ─────────────────────────────────────────────────────────────
func _choose_tech() -> void:
	var snap: Dictionary = _board_snapshot()
	var best_name: String = ""
	var best_score: int = -1

	# E2E: always play the tested tech card first for Tech scenarios, then forced
	# setup techs, before falling back to normal scoring.
	if CardE2ERunner.is_active() and player_index == 0:
		var _scenario := CardE2ERunner.get_current_scenario()
		# For Tech-type scenarios, the card being tested IS the tech to play.
		if _scenario.get("card_type", "") == "Tech":
			var _tname: String = str(_scenario.get("card_name", ""))
			if _tname != "" and _tname in GameState.tech_hands[player_index]:
				var _tdata: TechCardData = CardDatabase.get_tech(_tname)
				if _tdata != null and GameState.crystals[player_index] >= _tdata.crystal_cost:
					emit_signal("ai_tech_chosen", _tname)
					return
		# Forced setup techs (e.g. Great Diplomacy before an ability attack).
		var fst: Array = _scenario.get("e2e_force_setup_tech", [])
		for fst_v: Variant in fst:
			var fst_name: String = str(fst_v)
			if fst_name in GameState.tech_hands[player_index]:
				var fst_data: TechCardData = CardDatabase.get_tech(fst_name)
				if fst_data != null and GameState.crystals[player_index] >= fst_data.crystal_cost:
					emit_signal("ai_tech_chosen", fst_name)
					return

	for tech_name: String in GameState.tech_hands[player_index]:
		var data: TechCardData = CardDatabase.get_tech(tech_name)
		if data == null:
			continue
		if GameState.crystals[player_index] < data.crystal_cost:
			continue
		if data.required_prior_card != "" and not GameState.tech_name_played_this_game(player_index, data.required_prior_card):
			continue
		var base_score: int = _score_tech(tech_name, snap)
		if base_score <= 0:
			continue
		var sc: int = base_score + randi() % 5
		if sc > best_score:
			best_score = sc
			best_name = tech_name

	if best_name == "":
		_do_attack_decision()
		return

	emit_signal("ai_tech_chosen", best_name)

## Returns true if at least one affordable tech card scores > 0 on the current board.
func _has_useful_tech() -> bool:
	var snap: Dictionary = _board_snapshot()
	for tech_name: String in GameState.tech_hands[player_index]:
		var data: TechCardData = CardDatabase.get_tech(tech_name)
		if data == null or GameState.crystals[player_index] < data.crystal_cost:
			continue
		if data.required_prior_card != "" and not GameState.tech_name_played_this_game(player_index, data.required_prior_card):
			continue
		if _score_tech(tech_name, snap) > 0:
			return true
	return false

## Score a tech card given the current board snapshot. Returns 0 to skip, >0 to play.
func _score_tech(tech_name: String, snap: Dictionary) -> int:
	var data: TechCardData = CardDatabase.get_tech(tech_name)
	if data == null or data.effect_type == TechCardData.TechEffectType.NOT_IMPLEMENTED:
		return 0

	# Trailer Offensive: only play ATK-boosting techs; ignore everything else
	if _trailer_offensive:
		var atk_types: Array = [
			TechCardData.TechEffectType.PERM_ATK_BOOST_ONE,
			TechCardData.TechEffectType.TEMP_ATK_BOOST_ATTACK_NOW,
			TechCardData.TechEffectType.PERM_BOOST_ALL_FACEUP,
		]
		if data.effect_type in atk_types and snap["ai_faceup"] > 0:
			return 999
		return 0

	var ai_faceup: int  = snap["ai_faceup"]
	var opp_rev: int    = snap["opp_revealed"]
	var opp_hidden: int = snap["opp_hidden"]

	match data.effect_type:
		TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE, \
		TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_CHAIN:
			if opp_hidden == 0:
				return 0
			return 60 + opp_hidden * 8

		TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_RISKY:
			if opp_hidden == 0:
				return 0
			var count: int = data.effect_params.get("count", 3)
			if snap["ai_crystals"] < count * 700 + 500:
				return 0
			return 40 + opp_hidden * 5

		TechCardData.TechEffectType.OPPONENT_REVEALS_SQUARE, \
		TechCardData.TechEffectType.OPPONENT_REVEALS_OR_GAINS:
			if opp_hidden == 0:
				return 0
			return 30

		TechCardData.TechEffectType.PERM_BOOST_ALL_FACEUP:
			if ai_faceup == 0:
				return 0
			return 50 + ai_faceup * 15

		TechCardData.TechEffectType.PERM_ATK_BOOST_ONE:
			if ai_faceup == 0:
				return 0
			return 40 + _count_beatables_with_boost(data.effect_params.get("atk", 5)) * 20

		TechCardData.TechEffectType.TEMP_ATK_BOOST_ATTACK_NOW:
			if ai_faceup == 0:
				return 0
			return 55 + _count_beatables_with_boost(data.effect_params.get("atk", 5)) * 15

		TechCardData.TechEffectType.TEMP_DEF_BOOST_ALL:
			if ai_faceup == 0:
				return 0
			return 35 + ai_faceup * 8

		TechCardData.TechEffectType.PERM_DEF_BOOST_ONE:
			if ai_faceup == 0:
				return 0
			return 30

		TechCardData.TechEffectType.OPPONENT_NEXT_DEFENDER_DESTROYED:
			if opp_rev == 0:
				return 0
			return 55

		TechCardData.TechEffectType.DESTROY_ALL_REVEALED_OPPONENT:
			if opp_rev == 0:
				return 0
			return 40 + opp_rev * 35

		TechCardData.TechEffectType.DESTROY_ROW_OR_COLUMN:
			if opp_rev == 0:
				return 0
			return 30 + opp_rev * 20

		TechCardData.TechEffectType.DESTROY_FACEUP_CARD, \
		TechCardData.TechEffectType.DESTROY_FACEUP_NO_CRYSTAL_LOSS:
			if opp_rev == 0:
				return 0
			return 60 + _strongest_opp_def() / 3

		TechCardData.TechEffectType.DESTROY_VENOM_DOUBLE_COST:
			if not _any_venom_flagged_character():
				return 0
			return 75 + _strongest_venom_target_cost() / 4

		TechCardData.TechEffectType.DESTROY_OWN_BASE_ZERO_OPPONENT:
			if opp_rev == 0 or ai_faceup < 2:
				return 0
			return 70

		TechCardData.TechEffectType.MULTI_ATTACK_ONE:
			if ai_faceup == 0:
				return 0
			return 50

		TechCardData.TechEffectType.CLONE_CHARACTER_AS_TOKEN:
			if ai_faceup == 0:
				return 0
			return 45

		TechCardData.TechEffectType.REVIVE_CHARACTER_FULL, \
		TechCardData.TechEffectType.REVIVE_CHARACTER_NO_ATK:
			if not snap["has_graveyard"]:
				return 0
			return 55

		TechCardData.TechEffectType.BOTH_SKIP_TURN:
			# Useful when opponent has more revealed cards than us
			if opp_rev >= ai_faceup + 2:
				return 60
			return 10

		TechCardData.TechEffectType.BOTH_LOCK_CHOSEN_MONSTER:
			if opp_rev == 0:
				return 0
			return 40

		TechCardData.TechEffectType.ADD_MUTAGEN_FLAG:
			if not snap["has_bio_char"]:
				return 0
			return 35

		TechCardData.TechEffectType.DIVINE_PROTECTION:
			if not snap["has_divine_char"]:
				return 0
			return 50

		TechCardData.TechEffectType.REVEAL_ALL_OWN_CHARACTERS:
			var ai_hidden: int = _count_hidden(player_index)
			if ai_hidden == 0:
				return 0
			var cap: int = int(data.effect_params.get("count", ai_hidden))
			if cap <= 0:
				cap = ai_hidden
			return 25 + mini(ai_hidden, cap) * 5

		TechCardData.TechEffectType.REVEAL_OWN_AND_OPPONENT_REVEALS:
			if opp_hidden == 0:
				return 0
			return 35

		TechCardData.TechEffectType.MOVE_BUFFS_BETWEEN_CHARACTERS:
			if ai_faceup < 2:
				return 0
			return 20

		TechCardData.TechEffectType.FORCE_SHIELD_ONE_CARD:
			if ai_faceup == 0:
				return 0
			return 30

		TechCardData.TechEffectType.VIEW_OPPONENT_TECH:
			return 20

		TechCardData.TechEffectType.DESTROY_WISPS_REVEAL_OPPONENT:
			if not snap["has_wisps"] or opp_hidden == 0:
				return 0
			return 50

		TechCardData.TechEffectType.TEMP_REROLL_DICE:
			return 25

	return 0

# ─────────────────────────────────────────────────────────────
# Target decision for tech/trap effects
# ─────────────────────────────────────────────────────────────
func decide_target(filter: String) -> Vector2i:
	match filter:
		# opponent_squares: Radar/spy techs — can target dead_end slots too
		"opponent_squares_1", "opponent_squares_2", "opponent_squares_3", \
				"opponent_squares_3_risky":
			return decide_facedown_opponent_excluding([])
		"opponent_any_hidden", "ability_false_prophet_reveal", "ability_lockpicker_reveal", "lock_opponent_monster":
			return _random_unrevealed_opponent()
		"opponent_character_ability_destroy":
			return _random_faceup_opponent()
		"ability_rebel_king_swap":
			return _strongest_opp_faceup_pos()
		"row_or_column":
			return _best_rift_strike_cell()
		"opponent_faceup_zero_stats":
			return _random_faceup_opponent()
		"own_faceup_character_berserk", "own_faceup_for_trap_temp_def_boost", \
				"self_faceup_for_copy", "own_character_for_swap":
			return _best_own_faceup()
		"own_faceup_character", "own_faceup_character_source", "own_faceup_character_target", \
				"own_faceup_card_sacrifice", "own_any_card", \
				"own_character_for_trap_self_destruct", "lock_own_monster":
			return _best_own_character()
		"own_armored_nature":
			return _best_own_armored_nature()
		"own_bio_character":
			return _best_own_faceup_bio()
		"self_squares_1_opponent_turn", "own_facedown_character":
			return _random_unrevealed_self_character()
		"self_reveal_choice", "opponent_facedown_forced", \
				"trap_hostage_reveal_lock", "trap_street_joke_reveal":
			return _random_unrevealed_self()
		"own_any_as_target":
			return _worst_own_ally_excluding(GameState.attacker_pos)
		"wk17_foe_pick_character":
			return _worst_own_ally_excluding(GameState.attacker_pos)
		"graveyard":
			return _first_own_revive_slot()
		"revive_placement":
			return _first_own_revive_slot()
		"own_divine_character_redirect":
			return _best_own_divine_sacrifice()
		"any_faceup_card":
			# Prefer strongest opponent face-up; fall back to own weakest if none
			var opp_pos := _strongest_opp_faceup_pos()
			var opp_card := GameState.get_card(opponent_index, opp_pos.x, opp_pos.y)
			if opp_card.face_up:
				return opp_pos
			return _best_own_faceup()
		"venom_flagged_card":
			return _strongest_venom_flagged_pos()
		"opponent_faceup_no_cost":
			return _strongest_opp_faceup_pos()
		"adjacent":
			# Post-attack reveal (Scout Probe, etc.) — pick unrevealed cell adjacent to defender
			return _random_adjacent_unrevealed_to(GameState.defender_pos, opponent_index)
		_:
			return _random_unrevealed_opponent()

## Plant-29 turn-start targeting after coin flip — venom on exposed ally/foe or mutagen on own unit.
func decide_any_grid_target(filter: String) -> Dictionary:
	var best_player: int = -1
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_score: int = -999999
	for p: int in range(2):
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(p, r, c)
				if card.card_type != "character" or card.was_destroyed:
					continue
				var score: int = _plant29_target_score(p, card, filter)
				if score > best_score:
					best_score = score
					best_player = p
					best_pos = Vector2i(r, c)
	if best_player < 0:
		return {}
	return {"player": best_player, "pos": best_pos}

func _plant29_target_score(player: int, card: GameState.CardInstance, filter: String) -> int:
	if filter == "ability_plant29_venom":
		if not card.face_up:
			return -999999
	elif filter == "ability_plant29_mutagen":
		if player != player_index:
			return -999999
	var score: int = card.get_effective_atk() + card.get_effective_def()
	if player == opponent_index:
		score += 1000
	if filter == "ability_plant29_mutagen" and not card.face_up:
		score += 200
	return score

func _any_venom_flagged_character() -> bool:
	for p: int in range(2):
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(p, r, c)
				if card.card_type == "character" and "venom" in card.flags:
					return true
	return false

func _strongest_venom_target_cost() -> int:
	var best: int = 0
	for p: int in range(2):
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(p, r, c)
				if card.card_type == "character" and "venom" in card.flags:
					best = maxi(best, card.crystal_cost)
	return best

func _strongest_venom_flagged_pos() -> Vector2i:
	var best_player: int = opponent_index
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_score: int = -1
	for p: int in range(2):
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(p, r, c)
				if card.card_type != "character" or "venom" not in card.flags:
					continue
				var score: int = card.crystal_cost
				if p == opponent_index:
					score += 10000
				if score > best_score:
					best_score = score
					best_player = p
					best_pos = Vector2i(r, c)
	if best_pos == Vector2i(-1, -1):
		return Vector2i(0, 0)
	return best_pos

## Intelligent binary choice handler for awaiting_trap_choice prompts.
## prompt is the trap_name/title string; choices is the array of choice labels.
## Returns the chosen index (0 or 1).
func decide_trap_choice(prompt: String, choices: Array) -> int:
	# OPTIONAL_CRYSTAL_PAY_ATK_BOOST — "Pay N Crystals for +M ATK this battle?"
	if "ATK this battle" in prompt:
		var cost: int = _extract_first_int(prompt)
		var boost: int = _extract_second_int(prompt)
		if GameState.crystals[player_index] >= cost:
			var att: GameState.CardInstance = _get_current_attacker()
			var tgt: GameState.CardInstance = _get_current_target()
			if att != null and tgt != null:
				var cur_atk: int = att.get_effective_atk()
				var def_val: int = tgt.get_effective_def()
				# Pay only if the boost flips a losing/tying battle into a win
				if cur_atk <= def_val and (cur_atk + boost) > def_val:
					return 0
		return 1

	# OPTIONAL_CRYSTAL_PAY_DEF_BOOST — "Pay N Crystals for +M DEF this battle?"
	if "DEF this battle" in prompt:
		var cost: int = _extract_first_int(prompt)
		var boost: int = _extract_second_int(prompt)
		if GameState.crystals[player_index] >= cost:
			var def_card: GameState.CardInstance = _get_current_target()  # AI's card is the defender
			var opp_atk: int = _estimate_opponent_atk()
			if def_card != null:
				var cur_def: int = def_card.get_effective_def()
				if cur_def < opp_atk and (cur_def + boost) >= opp_atk:
					return 0
		return 1

	# OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT — "Pay N Crystals to destroy..."
	if "Crystals to destroy" in prompt:
		var cost: int = _extract_first_int(prompt)
		if GameState.crystals[player_index] >= cost:
			var att: GameState.CardInstance = _get_current_attacker()
			var tgt: GameState.CardInstance = _get_current_target()
			if att != null and tgt != null:
				# Pay if we'd otherwise lose or tie
				if att.get_effective_atk() <= tgt.get_effective_def():
					return 0
		return 1

	# INTERCEPT_ALLY_ATTACK — "X can intercept for Y!"
	if "intercept" in prompt.to_lower():
		# Intercept (choice 0) if we have enough other cards to spare
		if _count_faceup(player_index) >= 3:
			return 0
		return 1

	# TEMP_REROLL_DICE — "Lucky Break: Re-roll dice? (current: N)"
	if "Re-roll dice" in prompt:
		var current_roll: int = GameState.dice_result
		var att: GameState.CardInstance = _get_current_attacker()
		if att != null and att.ability_type == int(CharacterData.AbilityType.ATK_BONUS_IF_DICE_HIGH):
			var threshold: int = att.ability_params.get("threshold", 4)
			if current_roll < threshold:
				return 0  # re-roll — below threshold
		if current_roll <= 2:
			return 0  # generic: poor roll, re-roll
		return 1

	# SACRIFICE_FOR_CARD_TYPE — "X sacrifices itself to save Y?"
	if "sacrifices itself to save" in prompt:
		if _count_faceup(player_index) >= 3:
			return 0  # sacrifice weaker card to save the target
		return 1

	# NULLIFY_ATTACK_CHOICE — legacy trap removed from demo roster
	if "Lose 500 Crystals" in prompt or "NULLIFY_ATTACK_CHOICE" in prompt:
		var att: GameState.CardInstance = _get_current_attacker()
		if att != null and GameState.crystals[player_index] >= 500:
			# Pay crystals if attacker is high-value (ATK+DEF >= 40)
			if att.get_effective_atk() + att.get_effective_def() >= 40:
				return 0
		return 1  # let attacker be destroyed

	# ATTACKER_DISCARD_OR_END_TURN (Blackmail trap) — discard a tech or end turn
	if "Blackmail" in prompt:
		if GameState.attacks_remaining > 0 and not GameState.tech_hands[player_index].is_empty():
			return 0  # discard tech, keep attacking
		return 1

	return 0  # unknown prompt — default to first choice

func decide_blackmail_tech() -> String:
	# Returns tech name to discard, or "" to end the turn.
	if GameState.attacks_remaining <= 0 or GameState.tech_hands[player_index].is_empty():
		return ""
	var hand: Array = GameState.tech_hands[player_index]
	return str(hand[hand.size() - 1])

func _random_adjacent_unrevealed_to(center: Vector2i, target_player: int) -> Vector2i:
	var adj: Array = GameState.get_adjacent_positions(center.x, center.y)
	var options: Array = []
	for pos_v: Variant in adj:
		var pos: Vector2i = pos_v as Vector2i
		var card: GameState.CardInstance = GameState.get_card(target_player, pos.x, pos.y)
		if not card.face_up and not card.was_destroyed:
			options.append(pos)
	if options.is_empty():
		# No unrevealed adjacents — fall back to any unrevealed opponent cell
		return _random_unrevealed_opponent()
	return options[randi() % options.size()]

func _random_unrevealed_self() -> Vector2i:
	var options: Array = []
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if not card.face_up and card.card_type != "dead_end":
				options.append(Vector2i(r, c))
	if options.is_empty():
		return Vector2i(0, 0)
	return options[randi() % options.size()]

func _random_unrevealed_self_character() -> Vector2i:
	var options: Array = []
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type == "character" and not card.face_up:
				options.append(Vector2i(r, c))
	if options.is_empty():
		return Vector2i(0, 0)
	return options[randi() % options.size()]

func _worst_own_faceup() -> Vector2i:
	return _worst_own_faceup_excluding(Vector2i(-1, -1))

func _worst_own_faceup_excluding(exclude_pos: Vector2i) -> Vector2i:
	# Pick the weakest own face-up card to sacrifice
	var worst_pos: Vector2i = Vector2i(-1, -1)
	var worst_atk: int = 99999
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var pos := Vector2i(r, c)
			if pos == exclude_pos:
				continue
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type == "character" and card.face_up and card.current_atk < worst_atk:
				worst_atk = card.current_atk
				worst_pos = pos
	if worst_pos == Vector2i(-1, -1):
		return Vector2i(0, 0)
	return worst_pos

func _worst_own_ally_excluding(exclude_pos: Vector2i) -> Vector2i:
	# Brainwash: pick the weakest own ally, including face-down units
	var worst_pos: Vector2i = Vector2i(-1, -1)
	var worst_atk: int = 99999
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var pos := Vector2i(r, c)
			if pos == exclude_pos:
				continue
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type == "character" and card.current_atk < worst_atk:
				worst_atk = card.current_atk
				worst_pos = pos
	if worst_pos == Vector2i(-1, -1):
		return Vector2i(0, 0)
	return worst_pos

func _best_own_divine_sacrifice() -> Vector2i:
	# Pick a face-up Divine card that is NOT Archbishop (lowest ATK to minimize loss)
	var best_pos: Vector2i = Vector2i(-1, -1)
	var lowest_atk: int = 99999
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type == "character" and card.face_up \
					and card.affinity == CharacterData.Affinity.DIVINE \
					and card.ability_type != int(CharacterData.AbilityType.REDIRECT_DESTRUCTION_TO_ALLY) \
					and card.current_atk < lowest_atk:
				lowest_atk = card.current_atk
				best_pos = Vector2i(r, c)
	if best_pos == Vector2i(-1, -1):
		return Vector2i(0, 0)
	return best_pos

func _first_own_revive_slot() -> Vector2i:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			if GameState.is_valid_revive_placement_cell(player_index, r, c):
				return Vector2i(r, c)
	return Vector2i(0, 0)

func _first_own_empty_slot() -> Vector2i:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type == "dead_end" and not card.was_destroyed:
				return Vector2i(r, c)
	return Vector2i(0, 0)

## Returns the opponent's face-up cell with the highest combined ATK+DEF (best to destroy).
func _strongest_opp_faceup_pos() -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_score: int = -1
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
			if card.face_up and card.card_type != "dead_end":
				var sc: int = card.get_effective_atk() + card.get_effective_def()
				if sc > best_score:
					best_score = sc
					best_pos = Vector2i(r, c)
	if best_pos == Vector2i(-1, -1):
		return Vector2i(0, 0)
	return best_pos

func _random_unrevealed_opponent() -> Vector2i:
	var options: Array = []
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
			if not card.face_up and not card.was_destroyed:
				options.append(Vector2i(r, c))
	if options.is_empty():
		return Vector2i(0, 0)
	return options[randi() % options.size()]

# Like _random_unrevealed_opponent but includes dead_end slots — for Radar targeting
func decide_facedown_opponent_excluding(exclude: Array) -> Vector2i:
	var options: Array = []
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var pos := Vector2i(r, c)
			if pos in exclude:
				continue
			var card: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
			if not card.face_up:
				options.append(pos)
	if options.is_empty():
		return Vector2i(-1, -1)
	return options[randi() % options.size()]

## Great Diplomacy — pick own face-down units (prefer higher ATK for synergy reveals).
func decide_facedown_own_excluding(exclude: Array) -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_atk: int = -1
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var pos := Vector2i(r, c)
			if pos in exclude:
				continue
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type == "character" and not card.face_up:
				var atk: int = card.current_atk
				if atk > best_atk:
					best_atk = atk
					best_pos = pos
	return best_pos

func _random_facedown_opponent() -> Vector2i:
	return decide_facedown_opponent_excluding([])

func _random_faceup_opponent() -> Vector2i:
	var options: Array = []
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
			if card.card_type == "character" and card.face_up:
				options.append(Vector2i(r, c))
	if options.is_empty():
		return Vector2i(0, 0)
	return options[randi() % options.size()]

func _best_own_character() -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_atk: int = -1
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type == "character":
				if card.get_effective_atk() > best_atk:
					best_atk = card.get_effective_atk()
					best_pos = Vector2i(r, c)
	return best_pos

func _best_own_armored_nature() -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_atk: int = -1
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type == "character" \
					and card.affinity == CharacterData.Affinity.NATURE \
					and "Armored" in card.card_name:
				if card.get_effective_atk() > best_atk:
					best_atk = card.get_effective_atk()
					best_pos = Vector2i(r, c)
	return best_pos

func _best_own_faceup() -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_atk: int = -1
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type == "character" and card.face_up:
				if card.get_effective_atk() > best_atk:
					best_atk = card.get_effective_atk()
					best_pos = Vector2i(r, c)
	return best_pos

func _best_own_faceup_bio() -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_atk: int = -1
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type == "character" and card.face_up \
					and card.affinity == CharacterData.Affinity.BIO:
				if card.get_effective_atk() > best_atk:
					best_atk = card.get_effective_atk()
					best_pos = Vector2i(r, c)
	return best_pos

## Returns the intersection of the opponent's best row and best column for Rift Strike.
## GameBoard picks whichever (row or col) destroys more after receiving this cell.
func _best_rift_strike_cell() -> Vector2i:
	var opp: int = GameState.get_opponent(player_index)
	var best_row: int = 0
	var best_row_count: int = -1
	var best_col: int = 0
	var best_col_count: int = -1
	for r: int in range(GameState.GRID_SIZE):
		var count: int = 0
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opp, r, c)
			if card.face_up and card.card_type != "dead_end":
				count += 1
		if count > best_row_count:
			best_row_count = count
			best_row = r
	for c: int in range(GameState.GRID_SIZE):
		var count: int = 0
		for r: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opp, r, c)
			if card.face_up and card.card_type != "dead_end":
				count += 1
		if count > best_col_count:
			best_col_count = count
			best_col = c
	return Vector2i(best_row, best_col)

# ─────────────────────────────────────────────────────────────
# Union awareness
# ─────────────────────────────────────────────────────────────

## Returns all unions the AI can currently summon, each as:
##   { union: UnionData, zone_cells: Array[Vector2i], material_cells: Array[Vector2i] }
func _get_available_unions() -> Array:
	var results: Array = []
	var seen: Dictionary = {}
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type != "character" or card.is_union:
				continue
			for entry: Dictionary in UnionDatabase.find_available_unions(player_index, r, c):
				var u: UnionData = entry["union"]
				if seen.has(u.card_name):
					continue
				if GameState.crystals[player_index] < u.summon_cost:
					continue
				seen[u.card_name] = true
				var mats: Array = _solve_materials(u, entry["zone_cells"])
				if mats.is_empty() and not u.material_conditions.is_empty():
					continue
				results.append({
					"union": u,
					"zone_cells": entry["zone_cells"],
					"material_cells": mats,
				})
	return results

## Pick the best-scoring union from a list of candidates.
func _featured_union_preference() -> String:
	var arr: Variant = GameState.battle_featured_unions
	if arr is Array and player_index >= 0 and player_index < (arr as Array).size():
		var from_arr: String = str((arr as Array)[player_index]).strip_edges()
		if not from_arr.is_empty():
			return from_arr
	if player_index == 1:
		return str(GameState.battle_ai_featured_union).strip_edges()
	return ""


func _pick_best_union(unions: Array) -> Dictionary:
	var featured := _featured_union_preference()
	if not featured.is_empty():
		for entry: Dictionary in unions:
			var u: UnionData = entry["union"]
			if u.card_name == featured:
				return entry
	var best_entry: Dictionary = unions[0]
	var best_score: int = -1
	for entry: Dictionary in unions:
		var u: UnionData = entry["union"]
		var sc: int = _score_union(u) + randi() % 5
		if sc > best_score:
			best_score = sc
			best_entry = entry
	return best_entry

## Score a union for how desirable it is to summon right now.
func _score_union(u: UnionData) -> int:
	var score: int = u.base_atk + u.base_def

	var featured := _featured_union_preference()
	if not featured.is_empty() and u.card_name == featured:
		score += 250

	# Ability bonuses
	match u.ability_type:
		CharacterData.AbilityType.MULTI_ATTACK_ANY, \
		CharacterData.AbilityType.MULTI_ATTACK_ANY_WITH_ATK_LOSS:
			score += 40
		CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY, \
		CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY:
			var aff: int = u.ability_params.get("affinity", -1)
			if aff >= 0 and _opponent_has_affinity_revealed(aff):
				score += 30
		CharacterData.AbilityType.DESTROY_IF_OPPONENT_AFFINITY:
			var aff: int = u.ability_params.get("affinity", -1)
			if aff >= 0 and _opponent_has_affinity_revealed(aff):
				score += 50
		CharacterData.AbilityType.NONE:
			pass
		_:
			score += 15   # mild bonus for having any ability

	# Bonus if this union can beat the strongest revealed opponent card
	if u.base_atk > _strongest_opp_def():
		score += 30

	return score

## Greedy material-cell solver: returns the ordered list of Vector2i positions
## that satisfy u.material_conditions from the given zone_cells.
## Returns [] if any condition cannot be satisfied.
func _solve_materials(u: UnionData, zone_cells: Array) -> Array:
	var conditions: Array = UnionDatabase.sort_material_conditions(
		u.material_conditions.duplicate())
	var used: Array = []
	used.resize(zone_cells.size())
	used.fill(false)
	var selected: Array = []
	for cond: Dictionary in conditions:
		var found_idx: int = -1
		for i: int in range(zone_cells.size()):
			if used[i]:
				continue
			var pos: Vector2i = zone_cells[i]
			var card: GameState.CardInstance = GameState.get_card(player_index, pos.x, pos.y)
			if UnionDatabase.card_satisfies_condition(card, cond):
				found_idx = i
				break
		if found_idx < 0:
			return []
		used[found_idx] = true
		selected.append(zone_cells[found_idx])
	return selected

# ─────────────────────────────────────────────────────────────
# Setup phase placement
# ─────────────────────────────────────────────────────────────
func decide_setup(deck_override: Variant = null, forced_cells_src: Array = []) -> Array:
	_ai_turn_count = 0
	_union_used    = false
	_ai_kill_count = 0
	_pick_personalities()

	var placements: Array = []

	var char_pool: Array
	var trap_pool: Array
	var num_chars: int
	var num_traps: int
	var is_forced: bool = false

	if deck_override != null:
		# AI_VS_AI: use the provided deck directly
		char_pool = (deck_override.characters as Array).duplicate()
		char_pool.shuffle()
		trap_pool = (deck_override.traps as Array).duplicate()
		trap_pool.shuffle()
		num_chars = char_pool.size()
		num_traps = trap_pool.size()
	else:
		var cfg: Dictionary = GameState.campaign_enemy_config \
			if not GameState.campaign_enemy_config.is_empty() else {}

		var forced_chars: Variant = cfg.get("forced_characters", null)
		is_forced = forced_chars is Array and not (forced_chars as Array).is_empty()

		if is_forced:
			char_pool = (forced_chars as Array).duplicate()
		else:
			char_pool = CardDatabase.get_all_character_names().duplicate()
			if SaveManager.ai_exclude_placeholder:
				char_pool = char_pool.filter(func(n: String) -> bool:
					var cd: CharacterData = CardDatabase.get_character(n)
					return cd != null and not cd.placeholder_art)
			char_pool.shuffle()

		var forced_traps: Variant = cfg.get("forced_traps", null)
		if forced_traps is Array and not (forced_traps as Array).is_empty():
			trap_pool = (forced_traps as Array).duplicate()
		else:
			trap_pool = CardDatabase.get_all_trap_names().duplicate()
			if SaveManager.ai_exclude_placeholder:
				trap_pool = trap_pool.filter(func(n: String) -> bool:
					var td: TrapData = CardDatabase.get_trap(n)
					return td != null and not td.placeholder_art)
			trap_pool.shuffle()

		if is_forced:
			num_chars = char_pool.size()
		else:
			num_chars = randi_range(
				cfg.get("min_chars", GameState.MIN_CHARACTERS),
				cfg.get("max_chars", GameState.MAX_CHARACTERS))
		if forced_traps is Array and not (forced_traps as Array).is_empty():
			num_traps = min(trap_pool.size(), 25 - num_chars)
		else:
			num_traps = randi_range(
				cfg.get("min_traps", GameState.MIN_TRAPS),
				min(cfg.get("max_traps", GameState.MAX_TRAPS), 25 - num_chars))

	# ── Demo mode filter — only allow demo-flagged cards ──────────────────────
	if SaveManager.demo_mode:
		char_pool = char_pool.filter(func(n: String) -> bool:
			var cd: CharacterData = CardDatabase.get_character(n)
			return cd != null and cd.include_in_demo)
		trap_pool = trap_pool.filter(func(n: String) -> bool:
			var td: TrapData = CardDatabase.get_trap(n)
			return td != null and td.include_in_demo)
		# Clamp counts to what's actually available after filtering
		num_chars = min(num_chars, char_pool.size())
		num_traps = min(num_traps, trap_pool.size())

	# ── Strategic union zone placement (non-forced decks only) ──
	# Find the best union achievable from the char pool and pre-assign
	# the required material cards to their correct zone cells.
	var zone_assignments: Dictionary = {}   # Vector2i → char_name
	if not is_forced and _union_concern != "none":
		var strategic: Dictionary = _find_best_setup_union(char_pool, num_chars)
		if not strategic.is_empty():
			zone_assignments = strategic["assignments"]

	# Build placements — zone-assigned chars first, then remaining chars, then traps.
	var used_positions: Dictionary = {}
	var used_chars:     Dictionary = {}

	# Pre-occupy positions already filled by forced cells (placed by GameBoard)
	# used_chars stores counts so duplicate card names (e.g. Church Guard ×8) are
	# reserved/consumed correctly rather than blocking all copies at once.
	var _my_forced_cells: Array = forced_cells_src if not forced_cells_src.is_empty() \
		else GameState.battle_ai_forced_cells
	for fc_v: Variant in _my_forced_cells:
		if not (fc_v is Dictionary):
			continue
		var fc_d: Dictionary = fc_v as Dictionary
		used_positions[Vector2i(int(fc_d.get("row", 0)), int(fc_d.get("col", 0)))] = true
		var fc_name: String = str(fc_d.get("card_name", ""))
		if fc_name != "":
			used_chars[fc_name] = int(used_chars.get(fc_name, 0)) + 1
	# Filter zone_assignments to avoid forced cell conflicts
	for fp: Vector2i in used_positions.keys():
		zone_assignments.erase(fp)

	for cell: Vector2i in zone_assignments.keys():
		var cname: String = zone_assignments[cell]
		placements.append({"pos": cell, "card_type": "character", "card_name": cname})
		used_positions[cell] = true
		used_chars[cname]    = int(used_chars.get(cname, 0)) + 1

	# Pool of remaining grid positions (shuffled)
	var remaining_pos: Array = []
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			if not used_positions.has(Vector2i(r, c)):
				remaining_pos.append(Vector2i(r, c))
	remaining_pos.shuffle()
	# Personality: sort preferred formation positions to the front so characters
	# fill those cells first; traps naturally take the remaining positions.
	if _def_zone != "" and _def_zone != "random_def":
		remaining_pos.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return _score_pos_defensive(a) > _score_pos_defensive(b))

	var pos_idx: int = 0
	# Remaining characters
	var chars_still_needed: int = num_chars - zone_assignments.size()
	for i: int in range(char_pool.size()):
		if chars_still_needed <= 0 or pos_idx >= remaining_pos.size():
			break
		var cname: String = char_pool[i]
		var reserved: int = int(used_chars.get(cname, 0))
		if reserved > 0:
			# Consume one reservation for this copy; remaining copies can be placed.
			used_chars[cname] = reserved - 1
			continue
		placements.append({"pos": remaining_pos[pos_idx], "card_type": "character", "card_name": cname})
		pos_idx += 1
		chars_still_needed -= 1

	# Traps
	for i: int in range(num_traps):
		if pos_idx >= remaining_pos.size():
			break
		placements.append({"pos": remaining_pos[pos_idx], "card_type": "trap",
			"card_name": trap_pool[i % trap_pool.size()]})
		pos_idx += 1

	if _trailer_defensive:
		placements = _trailer_defensive_post_process(placements, trap_pool)

	return placements

## Post-process placements for Trailer Defensive:
##  1. Force a trap (Explosive Barrels if available, else any trap) into the centre cell (2,2).
##  2. Move the strongest characters to border cells.
func _trailer_defensive_post_process(placements: Array, trap_pool: Array) -> Array:
	const CENTRE: Vector2i = Vector2i(2, 2)

	# ── Step 1: ensure a trap is at the centre ──────────────────────────────
	var centre_idx: int = -1
	var has_centre_trap: bool = false
	for i: int in range(placements.size()):
		var p: Dictionary = placements[i] as Dictionary
		if (p["pos"] as Vector2i) == CENTRE:
			centre_idx = i
			if (p["card_type"] as String) == "trap":
				has_centre_trap = true
			break

	if not has_centre_trap:
		# Find "Explosive Barrels" in the trap pool, else pick the first available trap
		var trap_name: String = ""
		for tname: String in trap_pool:
			if tname.to_lower().contains("explosive") and tname.to_lower().contains("barrel"):
				trap_name = tname
				break
		if trap_name == "" and not trap_pool.is_empty():
			trap_name = trap_pool[0]

		if trap_name != "":
			# Find a spare trap placement elsewhere to swap with centre
			var spare_trap_idx: int = -1
			for i: int in range(placements.size()):
				var p: Dictionary = placements[i] as Dictionary
				if (p["card_type"] as String) == "trap" and (p["pos"] as Vector2i) != CENTRE:
					spare_trap_idx = i
					break

			if centre_idx >= 0:
				# centre occupied by a non-trap — swap that card with a spare trap
				if spare_trap_idx >= 0:
					var centre_card: Dictionary = placements[centre_idx].duplicate()
					var spare_trap: Dictionary = placements[spare_trap_idx].duplicate()
					placements[centre_idx] = {"pos": CENTRE, "card_type": "trap", "card_name": trap_name}
					placements[spare_trap_idx] = {"pos": centre_card["pos"], "card_type": centre_card["card_type"], "card_name": centre_card["card_name"]}
				else:
					placements[centre_idx] = {"pos": CENTRE, "card_type": "trap", "card_name": trap_name}
			else:
				# centre is empty (dead_end slot) — add the trap there
				placements.append({"pos": CENTRE, "card_type": "trap", "card_name": trap_name})

	# ── Step 2: move strongest characters to border cells ────────────────────
	# Collect character placement indices, separate border vs inner positions
	var char_indices: Array = []
	for i: int in range(placements.size()):
		var p: Dictionary = placements[i] as Dictionary
		if (p["card_type"] as String) == "character":
			char_indices.append(i)

	if char_indices.size() < 2:
		return placements  # not enough chars to bother

	# Score each char by ATK+DEF (needs the card to be placed so GameState has it, but during
	# setup the cards aren't on the board yet — use CardDatabase instead)
	var char_scores: Array = []
	for i: int in char_indices:
		var p: Dictionary = placements[i] as Dictionary
		var cname: String = p["card_name"] as String
		var cd: CharacterData = CardDatabase.get_character(cname)
		var score: int = (cd.base_atk + cd.base_def) if cd != null else 0
		char_scores.append({"idx": i, "score": score, "pos": p["pos"] as Vector2i})

	# Sort by score descending (strongest first)
	char_scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["score"] as int) > (b["score"] as int))

	# Separate positions into border vs inner
	var border_positions: Array = []
	var inner_positions: Array = []
	for entry: Dictionary in char_scores:
		var pos: Vector2i = entry["pos"] as Vector2i
		if pos.x == 0 or pos.x == 4 or pos.y == 0 or pos.y == 4:
			border_positions.append(entry)
		else:
			inner_positions.append(entry)

	# We want the strongest chars at border positions.
	# Collect all positions and all card names, then assign strongest to border.
	var all_positions: Array = []
	var all_names: Array = []
	for entry: Dictionary in char_scores:
		all_positions.append(entry["pos"])
		all_names.append((placements[entry["idx"] as int] as Dictionary)["card_name"])

	# Sort positions: border first
	all_positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_border: bool = (a.x == 0 or a.x == 4 or a.y == 0 or a.y == 4)
		var b_border: bool = (b.x == 0 or b.x == 4 or b.y == 0 or b.y == 4)
		return a_border and not b_border)

	# Reassign: strongest char → first (border) position, etc.
	for j: int in range(char_scores.size()):
		var target_idx: int = char_scores[j]["idx"] as int
		placements[target_idx] = {
			"pos": all_positions[j] as Vector2i,
			"card_type": "character",
			"card_name": all_names[j] as String,
		}

	return placements

## Finds the highest-scoring union (ATK+DEF) whose material conditions can all be
## satisfied by cards in char_pool[:num_chars], and returns zone cell → char_name
## assignments for those material cards.
func _find_best_setup_union(char_pool: Array, num_chars: int) -> Dictionary:
	var available: Array = char_pool.slice(0, mini(num_chars, char_pool.size()))
	var best: Dictionary = {}
	var best_score: int  = -1

	var all_unions: Array = UnionDatabase.get_all_unions()
	all_unions.shuffle()   # randomise tie-breaking

	for u: UnionData in all_unions:
		if not UnionDatabase.is_playable_in_demo(u):
			continue
		if u.material_conditions.is_empty():
			continue
		var assignment: Dictionary = _try_assign_setup_union(u, available)
		if assignment.is_empty():
			continue
		var score: int = u.base_atk + u.base_def
		if score > best_score:
			best_score = score
			best = {"union": u, "assignments": assignment}

	return best

## Tries to assign chars from available_chars to the union's material conditions.
## Returns {Vector2i zone_cell → char_name} on success, {} on failure.
func _try_assign_setup_union(u: UnionData, available_chars: Array) -> Dictionary:
	var conditions: Array = UnionDatabase.sort_material_conditions(
		u.material_conditions.duplicate())

	var used_chars: Dictionary = {}
	var matched: Array = []   # char_names in condition order

	for cond: Dictionary in conditions:
		var found: String = ""
		for cname: String in available_chars:
			if used_chars.has(cname):
				continue
			var cd: CharacterData = CardDatabase.get_character(cname)
			if cd == null:
				continue
			if _setup_char_satisfies(cname, cd, cond):
				found = cname
				break
		if found == "":
			return {}
		used_chars[found] = true
		matched.append(found)

	# Assign each matched char to the first N zone cells (order doesn't matter —
	# any character in any zone cell satisfies the material validator).
	var assignment: Dictionary = {}
	var zone: Array = u.union_zone
	for i: int in range(matched.size()):
		assignment[zone[i % zone.size()]] = matched[i]
	return assignment

func _setup_char_satisfies(cname: String, cd: CharacterData, cond: Dictionary) -> bool:
	if cond.is_empty():
		return true
	var cn: Variant = cond.get("card_name", "")
	if cn is String and (cn as String) != "" and cname != (cn as String):
		return false
	var nc: Variant = cond.get("name_contains", "")
	if nc is String and (nc as String) != "" and not cname.to_lower().contains(nc as String):
		return false
	var aff: Variant = cond.get("affinity", -1)
	if aff is int and (aff as int) >= 0 and int(cd.affinity) != (aff as int):
		return false
	var mc: Variant = cond.get("min_cost", 0)
	if mc is int and cd.crystal_cost < (mc as int):
		return false
	var ma: Variant = cond.get("min_atk", 0)
	if ma is int and cd.base_atk < (ma as int):
		return false
	var md: Variant = cond.get("min_def", 0)
	if md is int and cd.base_def < (md as int):
		return false
	return true

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _count_faceup(player: int) -> int:
	var count: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character" and card.face_up:
				count += 1
	return count

func _count_hidden(player: int) -> int:
	var count: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if not card.face_up and card.card_type != "dead_end":
				count += 1
	return count

func _has_affinity_faceup(player: int, aff: CharacterData.Affinity) -> bool:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character" and card.face_up and card.affinity == int(aff):
				return true
	return false

func _count_name_contains(player: int, fragment: String) -> int:
	var n: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character" and fragment in card.card_name.to_lower():
				n += 1
	return n

func _strongest_opp_def() -> int:
	var max_def: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
			if card.card_type == "character" and card.face_up:
				max_def = maxi(max_def, card.get_effective_def())
	return max_def

func _opponent_has_affinity_revealed(aff: int) -> bool:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
			if card.card_type == "character" and card.face_up and card.affinity == aff:
				return true
	return false

## How many currently revealed opponent chars become beatable if our best attacker gets +atk_boost
func _count_beatables_with_boost(atk_boost: int) -> int:
	var best_atk: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type == "character" and card.face_up:
				best_atk = maxi(best_atk, card.get_effective_atk())
	var count: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
			if card.card_type == "character" and card.face_up:
				var def_val: int = card.get_effective_def()
				if best_atk <= def_val and (best_atk + atk_boost) > def_val:
					count += 1
	return count

func _get_current_attacker() -> GameState.CardInstance:
	var ap: Vector2i = GameState.attacker_pos
	if ap.x >= 0:
		return GameState.get_card(GameState.current_player, ap.x, ap.y)
	return null

func _get_current_target() -> GameState.CardInstance:
	var dp: Vector2i = GameState.defender_pos
	if dp.x >= 0:
		var opp: int = 1 - GameState.current_player
		return GameState.get_card(opp, dp.x, dp.y)
	return null

func _estimate_opponent_atk() -> int:
	var best: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
			if card.card_type == "character" and card.face_up:
				best = maxi(best, card.get_effective_atk())
	return best

func _extract_first_int(s: String) -> int:
	var match: Variant = _int_regex.search(s)
	if match != null:
		return (match as RegExMatch).get_string().to_int()
	return 0

func _extract_second_int(s: String) -> int:
	var results: Variant = _int_regex.search_all(s)
	if results != null:
		var arr: Array = results as Array
		if arr.size() >= 2:
			return (arr[1] as RegExMatch).get_string().to_int()
	return 0

func _board_snapshot() -> Dictionary:
	return {
		"ai_faceup": _count_faceup(player_index),
		"opp_revealed": _count_faceup(opponent_index),
		"opp_hidden": _count_hidden(opponent_index),
		"ai_crystals": GameState.crystals[player_index],
		"has_graveyard": not GameState.graveyards[player_index].is_empty(),
		"has_bio_char": _has_affinity_faceup(player_index, CharacterData.Affinity.BIO),
		"has_divine_char": _has_affinity_faceup(player_index, CharacterData.Affinity.DIVINE),
		"has_wisps": _count_name_contains(player_index, "wisp") > 0,
	}

# ─────────────────────────────────────────────────────────────
# Bluff system
# ─────────────────────────────────────────────────────────────

## Fire-and-forget bluff decision at the start of each AI turn.
## Called without await so it doesn't block the attack flow.
func decide_bluff() -> void:
	# Flush any pending death-bluff from the previous (opponent's) turn
	if _pending_death_bluff.x >= 0:
		var dp: Vector2i = _pending_death_bluff
		_pending_death_bluff = Vector2i(-1, -1)
		await get_tree().create_timer(randf_range(0.4, 1.0)).timeout
		var use_poop: bool = SaveManager.nsfw_enabled
		var death_emojis: Array = ["🤣", "💩" if use_poop else "🖕", "☠️", "🥺"]
		emit_signal("ai_bluff", player_index, dp.x, dp.y, death_emojis[randi() % death_emojis.size()])
		await get_tree().create_timer(BLUFF_ANIM_SECS).timeout   # wait for pop animation

	if randf() > _bluff_freq:
		return   # personality frequency gate
	await get_tree().create_timer(randf_range(0.5, 2.5)).timeout

	var roll: float = randf()

	if roll < 0.45:
		# Taunt: put a confident emoji on a face-down high-DEF card or trap
		var pos: Vector2i = _bluff_pick_taunting_cell()
		if pos.x >= 0:
			emit_signal("ai_bluff", player_index, pos.x, pos.y, _pick_bluff_emoji())

	elif roll < 0.65:
		# Misdirect: put a luring emoji on a dead-end cell to waste human attacks
		var pos: Vector2i = _bluff_pick_dead_end_cell()
		if pos.x >= 0:
			emit_signal("ai_bluff", player_index, pos.x, pos.y, _pick_bluff_emoji())

	else:
		# Confident bluff: just act tough on a random face-down card
		var pos: Vector2i = _random_unrevealed_self()
		if pos.x >= 0:
			emit_signal("ai_bluff", player_index, pos.x, pos.y, _pick_bluff_emoji())

## Called when one of AI's face-up characters is destroyed.
## Queues a mourning bluff to be shown at the start of the AI's next turn.
func decide_death_bluff(row: int, col: int) -> void:
	_pending_death_bluff = Vector2i(row, col)

## Called when AI destroys a strong (100+ ATK/DEF) or union opponent card.
## Places a taunting emoji on the attacker's cell after a short delay.
## For Trailer Social: called on ANY character kill and always uses 🤣.
func decide_kill_taunt(attacker_pos: Vector2i) -> void:
	_ai_kill_count += 1   # track kills for kill_triggered expose mode
	await get_tree().create_timer(randf_range(0.3, 0.9)).timeout
	if _trailer_social:
		emit_signal("ai_bluff", player_index, attacker_pos.x, attacker_pos.y, "🤣")
		return
	var use_poop: bool = SaveManager.nsfw_enabled
	var emojis: Array = ["🤣", "💩" if use_poop else "🖕"]
	emit_signal("ai_bluff", player_index, attacker_pos.x, attacker_pos.y, emojis[randi() % emojis.size()])

## Returns the face-down cell with the highest DEF (or a trap) — good for taunting.
func _bluff_pick_taunting_cell() -> Vector2i:
	var best: Vector2i = Vector2i(-1, -1)
	var best_score: int = -1
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.face_up:
				continue
			var sc: int = -1
			if card.card_type == "trap":
				sc = 1000   # traps are the best to bluff on
			elif card.card_type == "character":
				sc = card.get_effective_def()
			if sc > best_score:
				best_score = sc
				best = Vector2i(r, c)
	return best

## Returns a random dead-end cell to misdirect the opponent.
func _bluff_pick_dead_end_cell() -> Vector2i:
	var options: Array = []
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if card.card_type == "dead_end" and not card.face_up:
				options.append(Vector2i(r, c))
	if options.is_empty():
		return Vector2i(-1, -1)
	return options[randi() % options.size()]

# ─────────────────────────────────────────────────────────────
# Personality system
# ─────────────────────────────────────────────────────────────

# Canonical name lists — order must match the def_list / off_list / soc_list arrays below.
const DEF_PERSONALITY_NAMES: Array = [
	"Frontline","Fortress","Watch Tower","Mine Field","Tomb Trap","Bait Trap",
	"Diagonal Shield","Cluster Defender","Checker","Straightforward","Midwit",
	"Symmetric Defender","Random Defender","Religious","Zoro","Helios",
	"Helios 2","Zoro 2","Tomb Trap (Hard)","Frontline (Hard)",
	# ── Trailer (not in random pool) ──
	"Trailer Defensive",
]
const OFF_PERSONALITY_NAMES: Array = [
	"Center Hoarder","Border Guard","Corner Assassin","Melee Fighter","Sniper",
	"Leftist","Rightist","X Sabre","Crusader","Column Crusher","Row Ripper",
	"Revealed Hunter","Explorer","Tinkerer","Berserker","Shadow Lurker",
	"Sleeping Dragon","Rambo","Spy","X Alien","Technophobia","Witchhunter",
	# ── Trailer (not in random pool) ──
	"Trailer Offensive",
]
const SOC_PERSONALITY_NAMES: Array = [
	"Degen","Talkative","Fiddly","Flirty","Bully","Fun Guy","Daredevil",
	"Vengeful","Paranoid","Skeptical","Ungrateful","Monk","Eager","Introvert",
	# ── Trailer (not in random pool) ──
	"Trailer Social",
]
# Number of entries before the trailer entries (keeps them out of the random pool)
const DEF_RANDOM_COUNT: int = 20
const OFF_RANDOM_COUNT: int = 22
const SOC_RANDOM_COUNT: int = 14

## Pick one random personality per dimension and cache derived trait values.
## Call once at the start of each game (from decide_setup).
func _pick_personalities() -> void:
	# ── Defensive personalities ──
	var def_list: Array = [
		{"zone": "border",        "union": "none"},     # Frontline
		{"zone": "center",        "union": "normal"},   # Fortress
		{"zone": "corners",       "union": "none"},     # Watch Tower
		{"zone": "center",        "union": "none"},     # Mine Field
		{"zone": "center",        "union": "normal"},   # Tomb Trap
		{"zone": "corners",       "union": "normal"},   # Bait Trap
		{"zone": "diagonals",     "union": "high"},     # Diagonal Shield
		{"zone": "cluster",       "union": "normal"},   # Cluster Defender
		{"zone": "checker",       "union": "high"},     # Checker
		{"zone": "line",          "union": "none"},     # Straightforward
		{"zone": "second_border", "union": "normal"},   # Midwit
		{"zone": "symmetric",     "union": "normal"},   # Symmetric Defender
		{"zone": "random_def",    "union": "high"},     # Random Defender
		{"zone": "cross",         "union": "none"},     # Religious
		{"zone": "z_pattern",     "union": "normal"},   # Zoro
		{"zone": "h_pattern",     "union": "normal"},   # Helios
		{"zone": "h_pattern",     "union": "high"},     # Helios 2
		{"zone": "z_pattern",     "union": "high"},     # Zoro 2
		{"zone": "center",        "union": "high"},     # Tomb Trap (Hard)
		{"zone": "border",        "union": "high"},     # Frontline (Hard)
	]

	# ── Offensive personalities ──
	var off_list: Array = [
		{"zone": "center",       "expose": "all",           "skip": 0},  # Center Hoarder
		{"zone": "border",       "expose": "all",           "skip": 0},  # Border Guard
		{"zone": "corners",      "expose": "cautious",      "skip": 2},  # Corner Assassin
		{"zone": "top_sweep",    "expose": "cautious",      "skip": 0},  # Melee Fighter
		{"zone": "bot_sweep",    "expose": "cautious",      "skip": 0},  # Sniper
		{"zone": "left_sweep",   "expose": "kill_triggered","skip": 0},  # Leftist
		{"zone": "right_sweep",  "expose": "kill_triggered","skip": 0},  # Rightist
		{"zone": "diagonals",    "expose": "all",           "skip": 0},  # X Sabre
		{"zone": "cross",        "expose": "all",           "skip": 0},  # Crusader
		{"zone": "col_focus",    "expose": "cautious",      "skip": 0},  # Column Crusher
		{"zone": "row_focus",    "expose": "cautious",      "skip": 0},  # Row Ripper
		{"zone": "near_revealed","expose": "kill_triggered","skip": 0},  # Revealed Hunter
		{"zone": "far_revealed", "expose": "cautious",      "skip": 0},  # Explorer
		{"zone": "near_trap",    "expose": "all",           "skip": 0},  # Tinkerer
		{"zone": "near_monster", "expose": "all",           "skip": 0},  # Berserker
		{"zone": "random_off",   "expose": "cautious",      "skip": 2},  # Shadow Lurker
		{"zone": "near_monster", "expose": "all",           "skip": 2},  # Sleeping Dragon
		{"zone": "random_off",   "expose": "all",           "skip": 0},  # Rambo
		{"zone": "avoid_border", "expose": "cautious",      "skip": 2},  # Spy
		{"zone": "diagonals",    "expose": "kill_triggered","skip": 2},  # X Alien
		{"zone": "far_trap",     "expose": "cautious",      "skip": 2},  # Technophobia
		{"zone": "cross_far_char","expose": "cautious",     "skip": 0},  # Witchhunter
	]

	# ── Social personalities ──
	var soc_list: Array = [
		# Degen
		{"freq": 0.55, "prefer": ["🧨","☠️","🖕"], "avoid_emoji": ["🤝","👍","🥺","❤️","😃"],
		 "reactions": {"😎":0,"🤣":0,"🤝":-1,"👍":-1,"🥺":-1,"🧨":1,"🖕":1,"😃":0,"❤️":0,"☠️":1}},
		# Talkative
		{"freq": 0.85, "prefer": ["😎","😃","🤣"], "avoid_emoji": ["🖕","🧨","☠️"],
		 "reactions": {"😎":1,"🤣":1,"🤝":0,"👍":0,"🥺":0,"🧨":-1,"🖕":0,"😃":1,"❤️":1,"☠️":-1}},
		# Fiddly
		{"freq": 0.55, "prefer": ["🤝","👍","🖕"], "avoid_emoji": [],
		 "reactions": {"😎":0,"🤣":0,"🤝":1,"👍":1,"🥺":0,"🧨":0,"🖕":1,"😃":0,"❤️":0,"☠️":0}},
		# Flirty
		{"freq": 0.55, "prefer": ["❤️","🥺"], "avoid_emoji": ["🖕","🧨","☠️"],
		 "reactions": {"😎":1,"🤣":0,"🤝":0,"👍":0,"🥺":0,"🧨":-1,"🖕":-1,"😃":0,"❤️":1,"☠️":-1}},
		# Bully
		{"freq": 0.15, "prefer": ["🖕","🧨"], "avoid_emoji": ["❤️"],
		 "reactions": {"😎":0,"🤣":0,"🤝":1,"👍":0,"🥺":1,"🧨":0,"🖕":1,"😃":0,"❤️":-1,"☠️":0}},
		# Fun Guy
		{"freq": 0.85, "prefer": ["🤣","😃","👍","🤝"], "avoid_emoji": ["🖕","☠️"],
		 "reactions": {"😎":0,"🤣":1,"🤝":0,"👍":0,"🥺":0,"🧨":0,"🖕":-1,"😃":1,"❤️":0,"☠️":-1}},
		# Daredevil
		{"freq": 0.85, "prefer": ["🧨","☠️"], "avoid_emoji": [],
		 "reactions": {"😎":0,"🤣":0,"🤝":0,"👍":0,"🥺":0,"🧨":1,"🖕":1,"😃":1,"❤️":0,"☠️":1}},
		# Vengeful
		{"freq": 0.15, "prefer": ["🖕","☠️"], "avoid_emoji": ["❤️","🤝","😃","🥺"],
		 "reactions": {"😎":0,"🤣":1,"🤝":-1,"👍":-1,"🥺":-1,"🧨":1,"🖕":1,"😃":0,"❤️":-1,"☠️":1}},
		# Paranoid
		{"freq": 0.0,  "prefer": [], "avoid_emoji": ["😎","☠️","🧨","👍","🤣","🖕","😃","❤️","🥺","🤝"],
		 "reactions": {"😎":-1,"🤣":-1,"🤝":-1,"👍":-1,"🥺":-1,"🧨":-1,"🖕":-1,"😃":-1,"❤️":-1,"☠️":-1}},
		# Skeptical
		{"freq": 0.0,  "prefer": [], "avoid_emoji": ["😎","☠️","🧨","👍","🤣","🖕","😃","❤️","🥺","🤝"],
		 "reactions": {"😎":1,"🤣":1,"🤝":-1,"👍":-1,"🥺":-1,"🧨":1,"🖕":0,"😃":-1,"❤️":-1,"☠️":1}},
		# Ungrateful
		{"freq": 0.15, "prefer": [], "avoid_emoji": ["👍"],
		 "reactions": {"😎":0,"🤣":0,"🤝":-1,"👍":-1,"🥺":0,"🧨":0,"🖕":1,"😃":0,"❤️":0,"☠️":0}},
		# Monk
		{"freq": 0.15, "prefer": ["👍","🤝"], "avoid_emoji": [],
		 "reactions": {"😎":0,"🤣":0,"🤝":0,"👍":0,"🥺":0,"🧨":0,"🖕":0,"😃":0,"❤️":0,"☠️":0}},
		# Eager
		{"freq": 0.55, "prefer": ["😎","☠️","🧨","👍","🤣","🖕","😃","❤️","🥺","🤝"], "avoid_emoji": [],
		 "reactions": {"😎":1,"🤣":1,"🤝":1,"👍":1,"🥺":1,"🧨":1,"🖕":1,"😃":1,"❤️":1,"☠️":1}},
		# Introvert
		{"freq": 0.0,  "prefer": [], "avoid_emoji": ["😎","🤣","😃"],
		 "reactions": {"😎":-1,"🤣":-1,"🤝":0,"👍":0,"🥺":0,"🧨":-1,"🖕":0,"😃":-1,"❤️":0,"☠️":-1}},
	]

	# Reset trailer flags
	_trailer_offensive = false
	_trailer_defensive = false
	_trailer_social    = false

	# If campaign/dungeon config overrides a personality, use it; otherwise pick randomly.
	# Random range is limited to *_RANDOM_COUNT so trailer entries never appear by chance.
	var _cfg: Dictionary = GameState.campaign_enemy_config
	var def_idx: int = randi() % DEF_RANDOM_COUNT
	var cfg_def: String = str(_cfg.get("ai_personality_defensive", ""))
	if cfg_def != "":
		var oi: int = DEF_PERSONALITY_NAMES.find(cfg_def)
		if oi >= 0:
			def_idx = oi

	var off_idx: int = randi() % OFF_RANDOM_COUNT
	var cfg_off: String = str(_cfg.get("ai_personality_offensive", ""))
	if cfg_off != "":
		var oi: int = OFF_PERSONALITY_NAMES.find(cfg_off)
		if oi >= 0:
			off_idx = oi

	var soc_idx: int = randi() % SOC_RANDOM_COUNT
	var cfg_soc: String = str(_cfg.get("ai_personality_social", ""))
	if cfg_soc != "":
		var oi: int = SOC_PERSONALITY_NAMES.find(cfg_soc)
		if oi >= 0:
			soc_idx = oi

	# ── Handle Trailer personalities ──
	if cfg_def == "Trailer Defensive":
		_trailer_defensive = true
		personality_defensive = "Trailer Defensive"
		_def_zone      = "border"
		_union_concern = "none"
	if cfg_off == "Trailer Offensive":
		_trailer_offensive = true
		personality_offensive = "Trailer Offensive"
		_attack_zone  = "random_off"
		_expose_mode  = "all"
		_skip_turns   = 0
		_union_concern = "none"
	if cfg_soc == "Trailer Social":
		_trailer_social = true
		personality_social = "Trailer Social"
		_bluff_freq   = 0.0   # suppress random bluffs; laughs are triggered by kills only
		_bluff_pool   = ["🤣"]

	# If any trailer personality was set, apply its traits and skip normal trait application
	if _trailer_offensive or _trailer_defensive or _trailer_social:
		# Fill any un-overridden dimensions with normal random picks
		if not _trailer_defensive:
			var def_pick: Dictionary = def_list[def_idx]
			_def_zone      = def_pick["zone"] as String
			_union_concern = def_pick["union"] as String
			personality_defensive = DEF_PERSONALITY_NAMES[def_idx] as String
			if _def_zone == "cluster":
				_cluster_origin = Vector2i(randi() % 3, randi() % 3)
			elif _def_zone == "line":
				_line_axis = randi() % 2
				_line_idx  = randi() % GameState.GRID_SIZE
		if not _trailer_offensive:
			var off_pick: Dictionary = off_list[off_idx]
			_attack_zone  = off_pick["zone"] as String
			_expose_mode  = off_pick["expose"] as String
			_skip_turns   = off_pick["skip"] as int
			personality_offensive = OFF_PERSONALITY_NAMES[off_idx] as String
			match _attack_zone:
				"top_sweep":    _zone_axis = 0; _zone_dir = 1
				"bot_sweep":    _zone_axis = GameState.GRID_SIZE - 1; _zone_dir = -1
				"left_sweep":   _zone_axis = 0; _zone_dir = 1
				"right_sweep":  _zone_axis = GameState.GRID_SIZE - 1; _zone_dir = -1
				"col_focus":    _zone_axis = randi() % GameState.GRID_SIZE; _zone_dir = 1
				"row_focus":    _zone_axis = randi() % GameState.GRID_SIZE; _zone_dir = 1
				_:              _zone_axis = 0; _zone_dir = 1
		if not _trailer_social:
			var soc_pick: Dictionary = soc_list[soc_idx]
			_bluff_freq      = soc_pick["freq"] as float
			_emoji_reactions = soc_pick["reactions"] as Dictionary
			_bluff_pool      = _build_bluff_pool(soc_pick["prefer"] as Array, soc_pick["avoid_emoji"] as Array)
			personality_social = SOC_PERSONALITY_NAMES[soc_idx] as String
		return   # skip normal trait application below

	var def_pick: Dictionary = def_list[def_idx]
	var off_pick: Dictionary = off_list[off_idx]
	var soc_pick: Dictionary = soc_list[soc_idx]

	# ── Apply defensive traits ──
	_def_zone      = def_pick["zone"] as String
	_union_concern = def_pick["union"] as String
	# Initialize zone-specific params
	if _def_zone == "cluster":
		_cluster_origin = Vector2i(randi() % 3, randi() % 3)  # top-left of a 3×3 area (0-2)
	elif _def_zone == "line":
		_line_axis = randi() % 2          # 0 = horizontal row, 1 = vertical column
		_line_idx  = randi() % GameState.GRID_SIZE

	# ── Apply offensive traits ──
	_attack_zone  = off_pick["zone"] as String
	_expose_mode  = off_pick["expose"] as String
	_skip_turns   = off_pick["skip"] as int
	match _attack_zone:
		"top_sweep":
			_zone_axis = 0; _zone_dir = 1
		"bot_sweep":
			_zone_axis = GameState.GRID_SIZE - 1; _zone_dir = -1
		"left_sweep":
			_zone_axis = 0; _zone_dir = 1
		"right_sweep":
			_zone_axis = GameState.GRID_SIZE - 1; _zone_dir = -1
		"col_focus":
			_zone_axis = randi() % GameState.GRID_SIZE; _zone_dir = 1
		"row_focus":
			_zone_axis = randi() % GameState.GRID_SIZE; _zone_dir = 1
		_:
			_zone_axis = 0; _zone_dir = 1

	# ── Apply social traits ──
	_bluff_freq      = soc_pick["freq"] as float
	_emoji_reactions = soc_pick["reactions"] as Dictionary
	_bluff_pool      = _build_bluff_pool(
		soc_pick["prefer"] as Array,
		soc_pick["avoid_emoji"] as Array)

	# Store names for external logging
	personality_defensive = DEF_PERSONALITY_NAMES[def_idx] as String
	personality_offensive = OFF_PERSONALITY_NAMES[off_idx] as String
	personality_social    = SOC_PERSONALITY_NAMES[soc_idx] as String


## Build a weighted emoji pool. Preferred emojis appear 3×, avoided emojis are excluded.
func _build_bluff_pool(prefer: Array, avoid_list: Array) -> Array:
	var all_emojis: Array = ["😎","☠️","🧨","👍","🤣","🖕","😃","❤️","🥺","🤝"]
	var pool: Array = []
	for e: Variant in all_emojis:
		var emoji: String = e as String
		if emoji in avoid_list:
			continue
		if emoji in prefer:
			pool.append(emoji); pool.append(emoji); pool.append(emoji)
		else:
			pool.append(emoji)
	if pool.is_empty():
		pool.append("😎")   # always have a fallback
	return pool


## Pick one emoji from the personality pool, substituting NSFW variant if enabled.
func _pick_bluff_emoji() -> String:
	if _bluff_pool.is_empty():
		return "😎"
	var e: String = _bluff_pool[randi() % _bluff_pool.size()] as String
	if e == "🖕" and SaveManager.nsfw_enabled:
		return "💩"
	return e


## Advance the sweep or focus axis when the current one is exhausted or trapped.
func _maybe_advance_sweep_axis() -> void:
	var n: int = GameState.GRID_SIZE
	match _attack_zone:
		"top_sweep", "bot_sweep":
			# Advance row when no valid (non-destroyed) targets remain in current row
			var has_target: bool = false
			for c in range(n):
				var card: GameState.CardInstance = GameState.get_card(opponent_index, _zone_axis, c)
				if not (card.card_type == "dead_end" and card.was_destroyed):
					has_target = true
					break
			if not has_target:
				_zone_axis = clampi(_zone_axis + _zone_dir, 0, n - 1)
		"left_sweep", "right_sweep":
			var has_target: bool = false
			for r in range(n):
				var card: GameState.CardInstance = GameState.get_card(opponent_index, r, _zone_axis)
				if not (card.card_type == "dead_end" and card.was_destroyed):
					has_target = true
					break
			if not has_target:
				_zone_axis = clampi(_zone_axis + _zone_dir, 0, n - 1)
		"col_focus":
			# Change column if a trap has been revealed there
			var found_trap: bool = false
			for r in range(n):
				var card: GameState.CardInstance = GameState.get_card(opponent_index, r, _zone_axis)
				if card.card_type == "trap" and card.face_up:
					found_trap = true; break
			if found_trap:
				_zone_axis = (_zone_axis + 1) % n
		"row_focus":
			var found_trap: bool = false
			for c in range(n):
				var card: GameState.CardInstance = GameState.get_card(opponent_index, _zone_axis, c)
				if card.card_type == "trap" and card.face_up:
					found_trap = true; break
			if found_trap:
				_zone_axis = (_zone_axis + 1) % n


## Score a target position for the active defensive formation (for setup placement sorting).
func _score_pos_defensive(pos: Vector2i) -> int:
	var r: int = pos.x
	var c: int = pos.y
	match _def_zone:
		"border":
			return 10 if (r == 0 or r == 4 or c == 0 or c == 4) else 0
		"center":
			return 10 if (r >= 1 and r <= 3 and c >= 1 and c <= 3) else 0
		"corners":
			return 10 if ((r == 0 or r == 4) and (c == 0 or c == 4)) else 0
		"diagonals":
			return 10 if (r == c or r + c == 4) else 0
		"cross":
			return 10 if (r == 2 or c == 2) else 0
		"second_border":
			var on_second: bool = (r == 1 or r == 3 or c == 1 or c == 3)
			var on_outer:  bool = (r == 0 or r == 4 or c == 0 or c == 4)
			return 10 if (on_second and not on_outer) else 0
		"z_pattern":
			# Top row + anti-diagonal interior + bottom row
			return 10 if (r == 0 or r == 4 or (r + c == 4 and r > 0 and r < 4)) else 0
		"h_pattern":
			# Left column + right column + middle row
			return 10 if (c == 0 or c == 4 or r == 2) else 0
		"checker":
			return 10 if ((r + c) % 2 == 0) else 0
		"cluster":
			var cr: int = _cluster_origin.x
			var cc: int = _cluster_origin.y
			return 10 if (r >= cr and r <= cr + 2 and c >= cc and c <= cc + 2) else 0
		"line":
			return 10 if (_line_axis == 0 and r == _line_idx) \
					  or (_line_axis == 1 and c == _line_idx) else 0
		"symmetric":
			return 10 if (c == 0 or c == 2 or c == 4) else 0
		_:  # "random_def" or unknown
			return 0


## Additive score bias for attack target position based on offensive personality.
func _score_pos_offensive(pos: Vector2i) -> int:
	var r: int = pos.x
	var c: int = pos.y
	match _attack_zone:
		"center":
			return 15 if (r >= 1 and r <= 3 and c >= 1 and c <= 3) else -5
		"border":
			return 15 if (r == 0 or r == 4 or c == 0 or c == 4) else -5
		"corners":
			return 20 if ((r == 0 or r == 4) and (c == 0 or c == 4)) else -5
		"diagonals":
			return 15 if (r == c or r + c == 4) else -5
		"cross":
			return 15 if (r == 2 or c == 2) else -5
		"avoid_border":
			return -15 if (r == 0 or r == 4 or c == 0 or c == 4) else 5
		"top_sweep", "bot_sweep":
			if r == _zone_axis:
				return 20
			if r == _zone_axis + _zone_dir:
				return 5
			return -5
		"left_sweep", "right_sweep":
			if c == _zone_axis:
				return 20
			if c == _zone_axis + _zone_dir:
				return 5
			return -5
		"col_focus":
			return 20 if c == _zone_axis else -5
		"row_focus":
			return 20 if r == _zone_axis else -5
		"near_revealed":
			return _near_revealed_score(pos)
		"far_revealed":
			return -_near_revealed_score(pos)
		"near_trap":
			return _near_type_score(pos, "trap")
		"far_trap":
			return -_near_type_score(pos, "trap")
		"near_monster":
			return _near_type_score(pos, "character")
		"cross_far_char":
			var cross_bonus: int = 15 if (r == 2 or c == 2) else -5
			return cross_bonus - _near_type_score(pos, "character")
		_:  # "random_off"
			return 0


## Proximity score: how close pos is to any revealed card of the given type on opponent's field.
func _near_type_score(pos: Vector2i, card_type: String) -> int:
	var best: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
			if card.card_type == card_type and card.face_up:
				var dist: int = abs(pos.x - r) + abs(pos.y - c)
				best = maxi(best, maxi(0, 12 - dist * 4))
	return best


## Proximity score: how close pos is to any revealed (non-dead-end) cell on opponent's field.
func _near_revealed_score(pos: Vector2i) -> int:
	var best: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opponent_index, r, c)
			if card.face_up and card.card_type != "dead_end":
				var dist: int = abs(pos.x - r) + abs(pos.y - c)
				best = maxi(best, maxi(0, 12 - dist * 4))
	return best


## Called after AI setup placements are applied.
## Returns {Vector2i → emoji_string} for cells to bluff on before the game starts.
## ~45% chance: no bluffs. ~30%: taunt (trap / high-DEF char cells). ~25%: mislead (dead-end cells).
func decide_setup_bluffs(placements: Array) -> Dictionary:
	var result: Dictionary = {}

	if randf() >= _bluff_freq:
		return result  # personality frequency gate — no bluffs this game

	# Build a set of placed positions for quick lookup
	var placed_set: Dictionary = {}
	for entry: Variant in placements:
		var p: Dictionary = entry as Dictionary
		var pos: Vector2i = p["pos"] as Vector2i
		placed_set[pos] = true

	if randf() < 0.60:
		# ── Taunt / act tough (60%) ──
		# Prefer trap cells, then high-DEF character cells
		var trap_cells: Array = []
		var tough_chars: Array = []

		for entry: Variant in placements:
			var p: Dictionary = entry as Dictionary
			var pos: Vector2i = p["pos"] as Vector2i
			var ct: String = p["card_type"] as String
			if ct == "trap":
				trap_cells.append(pos)
			elif ct == "character":
				var card: GameState.CardInstance = GameState.get_card(player_index, pos.x, pos.y)
				if card.get_effective_def() >= 60:
					tough_chars.append(pos)

		var candidates: Array = trap_cells + tough_chars
		if candidates.is_empty():
			return result

		candidates.shuffle()
		var count: int = 1 + (1 if randf() < 0.35 else 0)
		for i in range(mini(count, candidates.size())):
			var chosen_pos: Vector2i = candidates[i] as Vector2i
			result[chosen_pos] = _pick_bluff_emoji()
	else:
		# ── Mislead / lure (40%) ──
		var de_candidates: Array = []
		var low_candidates: Array = []

		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var pos: Vector2i = Vector2i(r, c)
				if not placed_set.has(pos):
					de_candidates.append(pos)

		for entry: Variant in placements:
			var p: Dictionary = entry as Dictionary
			if (p["card_type"] as String) == "character":
				var pos: Vector2i = p["pos"] as Vector2i
				var card: GameState.CardInstance = GameState.get_card(player_index, pos.x, pos.y)
				if card.get_effective_atk() + card.get_effective_def() < 50:
					low_candidates.append(pos)

		var candidates: Array = de_candidates + low_candidates
		if candidates.is_empty():
			return result

		candidates.shuffle()
		result[candidates[0] as Vector2i] = _pick_bluff_emoji()

	return result
