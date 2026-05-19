class_name AIPlayer
extends Node
# "Training" personality AI for VS_AI and Campaign modes.

const AI_PLAYER: int = 1
const HUMAN_PLAYER: int = 0
const BLUFF_ANIM_SECS: float = 0.42   # slightly over GameBoard.BLUFF_ANIM_DURATION (0.38s)

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
signal ai_bluff(row: int, col: int, emoticon: String)

# Per-duel state
var _ai_turn_count: int = 0   # incremented at start of each decide_turn call
var _union_used:    bool = false
var _pending_death_bluff: Vector2i = Vector2i(-1, -1)  # set when AI card dies; flushed on next AI turn

# Called at the start of each AI action opportunity (start of turn, after each attack, after tech).
func decide_turn() -> void:
	_ai_turn_count += 1
	await get_tree().create_timer(0.6).timeout

	# Rule 1: Tech priority — only enter TECH mode if a card actually scores > 0.
	if GameState.has_playable_tech(AI_PLAYER) and _has_useful_tech():
		emit_signal("ai_mode_chosen", GameState.TurnMode.TECH)
		await get_tree().create_timer(0.3).timeout
		_choose_tech()
		return

	# Rule 2: Union summon — hesitation eases over successive AI turns.
	# Turn 1: 10%, Turn 2: 35%, Turn 3: 60%, Turn 4+: 85%
	if not _union_used and GameState.battle_ai_union_enabled:
		var chance: float = minf(0.85, 0.10 + (_ai_turn_count - 1) * 0.25)
		if randf() < chance:
			var unions: Array = _get_available_unions()
			if not unions.is_empty():
				_union_used = true
				var picked: Dictionary = _pick_best_union(unions)
				var u: UnionData = picked["union"]
				emit_signal("ai_union_chosen", u.card_name, picked["zone_cells"], picked["material_cells"])
				return

	_do_attack_decision()

## Continuation called by GameBoard after union summon resolves, so the AI
## can still attack in the same turn without re-incrementing the turn counter.
func continue_after_union() -> void:
	await get_tree().create_timer(0.5).timeout
	_do_attack_decision()

func _do_attack_decision() -> void:
	var attacker_pos: Vector2i = _choose_attacker()
	if attacker_pos.x == -1:
		emit_signal("ai_end_turn")
		return
	var target_pos: Vector2i = _choose_target_for(attacker_pos)
	if target_pos.x == -1:
		emit_signal("ai_end_turn")
		return
	emit_signal("ai_mode_chosen", GameState.TurnMode.ATTACK)
	await get_tree().create_timer(0.3).timeout
	emit_signal("ai_attack_chosen", attacker_pos, target_pos)

# ─────────────────────────────────────────────────────────────
# Attacker selection (Training rules)
# ─────────────────────────────────────────────────────────────
func _choose_attacker() -> Vector2i:
	var opponent_faceup: int = _count_faceup(HUMAN_PLAYER)
	var ai_faceup: int = _count_faceup(AI_PLAYER)

	var faceup_attackers: Array = []
	var facedown_attackers: Array = []

	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(AI_PLAYER, r, c)
			if card.card_type != "character":
				continue
			if card.attacked_this_turn:
				continue
			if card.cannot_attack_until >= GameState.turn_number:
				continue
			# Berserk constraint: only the berserk card may attack.
			if GameState.berserk_active[AI_PLAYER] != null:
				if GameState.berserk_active[AI_PLAYER] != card:
					continue
			if card.face_up:
				faceup_attackers.append(Vector2i(r, c))
			else:
				facedown_attackers.append(Vector2i(r, c))

	# Rule 5: always use face-up characters first (pick highest ATK).
	if not faceup_attackers.is_empty():
		var best_pos: Vector2i = faceup_attackers[0]
		var best_atk: int = GameState.get_card(AI_PLAYER, best_pos.x, best_pos.y).get_effective_atk()
		for pos in faceup_attackers:
			var atk: int = GameState.get_card(AI_PLAYER, pos.x, pos.y).get_effective_atk()
			if atk > best_atk:
				best_atk = atk
				best_pos = pos
		return best_pos

	# No face-up attackers — consider revealing a face-down card.
	if facedown_attackers.is_empty():
		return Vector2i(-1, -1)

	# Rules 2 & 3: Revelation control.
	# When opponent has nothing revealed: only reveal 1-2 chars in total.
	# When opponent has revealed chars: reveal at most as many as they have.
	var max_ai_faceup: int
	if opponent_faceup == 0:
		max_ai_faceup = randi_range(1, 2)
	else:
		max_ai_faceup = opponent_faceup

	if ai_faceup >= max_ai_faceup:
		return Vector2i(-1, -1)

	# Rule 6: prefer face-down attackers adjacent to already-revealed AI characters.
	var adjacent: Array = []
	for pos_v in facedown_attackers:
		var pos: Vector2i = pos_v
		var adj: Array = GameState.get_adjacent_positions(pos.x, pos.y)
		for ap_v in adj:
			var ap: Vector2i = ap_v
			var neighbor: GameState.CardInstance = GameState.get_card(AI_PLAYER, ap.x, ap.y)
			if neighbor.card_type == "character" and neighbor.face_up:
				adjacent.append(pos)
				break

	if not adjacent.is_empty():
		return adjacent[randi() % adjacent.size()]
	return facedown_attackers[randi() % facedown_attackers.size()]

# ─────────────────────────────────────────────────────────────
# Target selection (Training rules)
# ─────────────────────────────────────────────────────────────
func _choose_target_for(attacker_pos: Vector2i) -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_score: int = -9999

	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var pos: Vector2i = Vector2i(r, c)
			# Skip locked targets
			if pos in GameState.locked_attack_positions:
				continue
			var card: GameState.CardInstance = GameState.get_card(HUMAN_PLAYER, r, c)
			# Skip destroyed slots
			if card.card_type == "dead_end" and card.was_destroyed:
				continue
			var sc: int = _score_attack(attacker_pos, pos) + randi() % 3
			if sc > best_score:
				best_score = sc
				best_pos = pos

	return best_pos

## Score an attack from attacker_pos onto target_pos. Higher = more desirable.
func _score_attack(attacker_pos: Vector2i, target_pos: Vector2i) -> int:
	var attacker: GameState.CardInstance = GameState.get_card(AI_PLAYER, attacker_pos.x, attacker_pos.y)
	var target: GameState.CardInstance   = GameState.get_card(HUMAN_PLAYER, target_pos.x, target_pos.y)

	if target.card_type == "dead_end":
		return 10   # clears slot but no crystal gain

	if not target.face_up:
		return 25   # probe unrevealed — medium priority

	if target.card_type == "trap":
		return 15   # hitting a trap is risky but better than nothing

	# Revealed character — estimate outcome with ability-aware ATK
	var eff_atk: int = attacker.get_effective_atk()

	# Inline ability adjustments (safe — no side effects)
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
			# ~50% expected value
			eff_atk += attacker.ability_params.get("bonus", 0) / 2
		CharacterData.AbilityType.ATK_BOOST_VS_REVEALED:
			eff_atk += attacker.ability_params.get("bonus", 0)

	var eff_def: int = target.get_effective_def()

	if eff_atk > eff_def:
		# Win — reward scales with how valuable the destroyed card is
		return 80 + target.crystal_cost / 20
	elif eff_atk == eff_def:
		# Tie — both destroyed; slight penalty proportional to our card's cost
		return 20 - attacker.crystal_cost / 30
	else:
		# Loss — penalty; prefer not to sacrifice expensive attackers
		return -30 - attacker.crystal_cost / 20

# ─────────────────────────────────────────────────────────────
# Tech selection
# ─────────────────────────────────────────────────────────────
func _choose_tech() -> void:
	var snap: Dictionary = _board_snapshot()
	var best_name: String = ""
	var best_score: int = -1

	for tech_name: String in GameState.tech_hands[AI_PLAYER]:
		var data: TechCardData = CardDatabase.get_tech(tech_name)
		if data == null:
			continue
		if GameState.crystals[AI_PLAYER] < data.crystal_cost:
			continue
		if data.required_prior_card != "" and not GameState.tech_name_played_this_game(AI_PLAYER, data.required_prior_card):
			continue
		var base_score: int = _score_tech(tech_name, snap)
		if base_score <= 0:
			continue
		var sc: int = base_score + randi() % 5
		if sc > best_score:
			best_score = sc
			best_name = tech_name

	if best_name == "":
		return   # nothing worth playing

	emit_signal("ai_tech_chosen", best_name)

## Returns true if at least one affordable tech card scores > 0 on the current board.
func _has_useful_tech() -> bool:
	var snap: Dictionary = _board_snapshot()
	for tech_name: String in GameState.tech_hands[AI_PLAYER]:
		var data: TechCardData = CardDatabase.get_tech(tech_name)
		if data == null or GameState.crystals[AI_PLAYER] < data.crystal_cost:
			continue
		if data.required_prior_card != "" and not GameState.tech_name_played_this_game(AI_PLAYER, data.required_prior_card):
			continue
		if _score_tech(tech_name, snap) > 0:
			return true
	return false

## Score a tech card given the current board snapshot. Returns 0 to skip, >0 to play.
func _score_tech(tech_name: String, snap: Dictionary) -> int:
	var data: TechCardData = CardDatabase.get_tech(tech_name)
	if data == null or data.effect_type == TechCardData.TechEffectType.NOT_IMPLEMENTED:
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
			var ai_hidden: int = _count_hidden(AI_PLAYER)
			if ai_hidden == 0:
				return 0
			return 25 + ai_hidden * 5

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
		"opponent_squares_1", "opponent_squares_2", "opponent_squares_3", \
				"opponent_squares_3_risky", "opponent_any_hidden", \
				"lock_opponent_monster", "opponent_faceup_zero_stats", "row_or_column":
			return _random_unrevealed_opponent()
		"own_faceup_character", "own_character_for_swap", \
				"own_faceup_for_trap_temp_def_boost", "own_character_for_trap_self_destruct", \
				"lock_own_monster", "own_faceup_character_source", "own_faceup_character_target", \
				"self_faceup_for_copy", "own_armored_nature":
			return _best_own_faceup()
		"self_squares_1_opponent_turn", "self_reveal_choice", "own_facedown_character", \
				"opponent_facedown_forced":
			return _random_unrevealed_self()
		"own_faceup_card_sacrifice", "own_any_card":
			return _best_own_faceup()
		"own_any_as_target":
			return _worst_own_faceup()
		"graveyard":
			return _first_own_empty_slot()
		"own_divine_character_redirect":
			return _best_own_divine_sacrifice()
		"any_faceup_card", "opponent_faceup_no_cost":
			return _strongest_opp_faceup_pos()
		_:
			return _random_unrevealed_opponent()

## Intelligent binary choice handler for awaiting_trap_choice prompts.
## prompt is the trap_name/title string; choices is the array of choice labels.
## Returns the chosen index (0 or 1).
func decide_trap_choice(prompt: String, choices: Array) -> int:
	# OPTIONAL_CRYSTAL_PAY_ATK_BOOST — "Pay N Crystals for +M ATK this battle?"
	if "ATK this battle" in prompt:
		var cost: int = _extract_first_int(prompt)
		var boost: int = _extract_second_int(prompt)
		if GameState.crystals[AI_PLAYER] >= cost:
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
		if GameState.crystals[AI_PLAYER] >= cost:
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
		if GameState.crystals[AI_PLAYER] >= cost:
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
		if _count_faceup(AI_PLAYER) >= 3:
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
		if _count_faceup(AI_PLAYER) >= 3:
			return 0  # sacrifice weaker card to save the target
		return 1

	# NULLIFY_ATTACK_CHOICE (Checkpoint trap) — choices: [lose crystals, destroy attacker]
	if "Checkpoint" in prompt:
		var att: GameState.CardInstance = _get_current_attacker()
		if att != null and GameState.crystals[AI_PLAYER] >= 500:
			# Pay crystals if attacker is high-value (ATK+DEF >= 40)
			if att.get_effective_atk() + att.get_effective_def() >= 40:
				return 0
		return 1  # let attacker be destroyed

	# ATTACKER_DISCARD_OR_END_TURN (Blackmail trap) — choices: [discard tech, end turn]
	if "Blackmail" in prompt:
		if GameState.attacks_remaining > 0 and not GameState.tech_hands[AI_PLAYER].is_empty():
			return 0  # discard tech, keep attacking
		return 1

	return 0  # safe default

func _random_unrevealed_self() -> Vector2i:
	var options: Array = []
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(AI_PLAYER, r, c)
			if not card.face_up and card.card_type != "dead_end":
				options.append(Vector2i(r, c))
	if options.is_empty():
		return Vector2i(0, 0)
	return options[randi() % options.size()]

func _worst_own_faceup() -> Vector2i:
	# Pick the weakest own face-up card to sacrifice
	var worst_pos: Vector2i = Vector2i(-1, -1)
	var worst_atk: int = 99999
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(AI_PLAYER, r, c)
			if card.card_type == "character" and card.face_up and card.current_atk < worst_atk:
				worst_atk = card.current_atk
				worst_pos = Vector2i(r, c)
	if worst_pos == Vector2i(-1, -1):
		return Vector2i(0, 0)
	return worst_pos

func _best_own_divine_sacrifice() -> Vector2i:
	# Pick a face-up Divine card that is NOT Archbishop (lowest ATK to minimize loss)
	var best_pos: Vector2i = Vector2i(-1, -1)
	var lowest_atk: int = 99999
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(AI_PLAYER, r, c)
			if card.card_type == "character" and card.face_up \
					and card.affinity == CharacterData.Affinity.DIVINE \
					and card.ability_type != int(CharacterData.AbilityType.REDIRECT_DESTRUCTION_TO_ALLY) \
					and card.current_atk < lowest_atk:
				lowest_atk = card.current_atk
				best_pos = Vector2i(r, c)
	if best_pos == Vector2i(-1, -1):
		return Vector2i(0, 0)
	return best_pos

func _first_own_empty_slot() -> Vector2i:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(AI_PLAYER, r, c)
			if card.card_type == "dead_end" and not card.was_destroyed:
				return Vector2i(r, c)
	return Vector2i(0, 0)

## Returns the opponent's face-up cell with the highest combined ATK+DEF (best to destroy).
func _strongest_opp_faceup_pos() -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_score: int = -1
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(HUMAN_PLAYER, r, c)
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
			var card: GameState.CardInstance = GameState.get_card(HUMAN_PLAYER, r, c)
			if not card.face_up and card.card_type != "dead_end":
				options.append(Vector2i(r, c))
	if options.is_empty():
		return Vector2i(0, 0)
	return options[randi() % options.size()]

func _best_own_faceup() -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_atk: int = -1
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(AI_PLAYER, r, c)
			if card.card_type == "character" and card.face_up:
				if card.get_effective_atk() > best_atk:
					best_atk = card.get_effective_atk()
					best_pos = Vector2i(r, c)
	return best_pos

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
			var card: GameState.CardInstance = GameState.get_card(AI_PLAYER, r, c)
			if card.card_type != "character" or card.is_union:
				continue
			for entry: Dictionary in UnionDatabase.find_available_unions(AI_PLAYER, r, c):
				var u: UnionData = entry["union"]
				if seen.has(u.card_name):
					continue
				if GameState.crystals[AI_PLAYER] < u.summon_cost:
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
func _pick_best_union(unions: Array) -> Dictionary:
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
	var conditions: Array = u.material_conditions.duplicate()
	conditions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.size() > b.size())
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
			var card: GameState.CardInstance = GameState.get_card(AI_PLAYER, pos.x, pos.y)
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
func decide_setup() -> Array:
	_ai_turn_count = 0
	_union_used    = false

	var placements: Array = []

	var cfg: Dictionary = GameState.campaign_enemy_config \
		if not GameState.campaign_enemy_config.is_empty() else {}

	var forced_chars: Variant = cfg.get("forced_characters", null)
	var is_forced: bool = forced_chars is Array and not (forced_chars as Array).is_empty()

	var char_pool: Array
	if is_forced:
		char_pool = (forced_chars as Array).duplicate()
	else:
		char_pool = CardDatabase.get_all_character_names().duplicate()
		char_pool.shuffle()

	var forced_traps: Variant = cfg.get("forced_traps", null)
	var trap_pool: Array
	if forced_traps is Array and not (forced_traps as Array).is_empty():
		trap_pool = (forced_traps as Array).duplicate()
	else:
		trap_pool = CardDatabase.get_all_trap_names().duplicate()
		trap_pool.shuffle()

	var num_chars: int
	var num_traps: int
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

	# ── Strategic union zone placement (non-forced decks only) ──
	# Find the best union achievable from the char pool and pre-assign
	# the required material cards to their correct zone cells.
	var zone_assignments: Dictionary = {}   # Vector2i → char_name
	if not is_forced:
		var strategic: Dictionary = _find_best_setup_union(char_pool, num_chars)
		if not strategic.is_empty():
			zone_assignments = strategic["assignments"]

	# Build placements — zone-assigned chars first, then remaining chars, then traps.
	var used_positions: Dictionary = {}
	var used_chars:     Dictionary = {}

	# Pre-occupy positions already filled by AI forced cells (placed by GameBoard)
	for fc_v: Variant in GameState.battle_ai_forced_cells:
		if not (fc_v is Dictionary):
			continue
		var fc_d: Dictionary = fc_v as Dictionary
		used_positions[Vector2i(int(fc_d.get("row", 0)), int(fc_d.get("col", 0)))] = true
		var fc_name: String = str(fc_d.get("card_name", ""))
		if fc_name != "":
			used_chars[fc_name] = true
	# Filter zone_assignments to avoid forced cell conflicts
	for fp: Vector2i in used_positions.keys():
		zone_assignments.erase(fp)

	for cell: Vector2i in zone_assignments.keys():
		var cname: String = zone_assignments[cell]
		placements.append({"pos": cell, "card_type": "character", "card_name": cname})
		used_positions[cell] = true
		used_chars[cname]    = true

	# Pool of remaining grid positions (shuffled)
	var remaining_pos: Array = []
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			if not used_positions.has(Vector2i(r, c)):
				remaining_pos.append(Vector2i(r, c))
	remaining_pos.shuffle()

	var pos_idx: int = 0
	# Remaining characters
	var chars_still_needed: int = num_chars - zone_assignments.size()
	for i: int in range(char_pool.size()):
		if chars_still_needed <= 0 or pos_idx >= remaining_pos.size():
			break
		var cname: String = char_pool[i]
		if used_chars.has(cname):
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
	var conditions: Array = u.material_conditions.duplicate()
	conditions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.size() > b.size())

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
			var card: GameState.CardInstance = GameState.get_card(HUMAN_PLAYER, r, c)
			if card.card_type == "character" and card.face_up:
				max_def = maxi(max_def, card.get_effective_def())
	return max_def

func _opponent_has_affinity_revealed(aff: int) -> bool:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(HUMAN_PLAYER, r, c)
			if card.card_type == "character" and card.face_up and card.affinity == aff:
				return true
	return false

## How many currently revealed opponent chars become beatable if our best attacker gets +atk_boost
func _count_beatables_with_boost(atk_boost: int) -> int:
	var best_atk: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(AI_PLAYER, r, c)
			if card.card_type == "character" and card.face_up:
				best_atk = maxi(best_atk, card.get_effective_atk())
	var count: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(HUMAN_PLAYER, r, c)
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
			var card: GameState.CardInstance = GameState.get_card(HUMAN_PLAYER, r, c)
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
		"ai_faceup": _count_faceup(AI_PLAYER),
		"opp_revealed": _count_faceup(HUMAN_PLAYER),
		"opp_hidden": _count_hidden(HUMAN_PLAYER),
		"ai_crystals": GameState.crystals[AI_PLAYER],
		"has_graveyard": not GameState.graveyards[AI_PLAYER].is_empty(),
		"has_bio_char": _has_affinity_faceup(AI_PLAYER, CharacterData.Affinity.BIO),
		"has_divine_char": _has_affinity_faceup(AI_PLAYER, CharacterData.Affinity.DIVINE),
		"has_wisps": _count_name_contains(AI_PLAYER, "wisp") > 0,
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
		emit_signal("ai_bluff", dp.x, dp.y, death_emojis[randi() % death_emojis.size()])
		await get_tree().create_timer(BLUFF_ANIM_SECS).timeout   # wait for pop animation

	if randf() > 0.30:
		return   # 70% of turns AI stays silent
	await get_tree().create_timer(randf_range(0.5, 2.5)).timeout

	var roll: float = randf()

	if roll < 0.45:
		# Taunt: put a confident emoji on a face-down high-DEF card or trap
		var pos: Vector2i = _bluff_pick_taunting_cell()
		if pos.x >= 0:
			var emojis: Array = ["😎", "☠️", "❤️", "👍", "🧨"]
			emit_signal("ai_bluff", pos.x, pos.y, emojis[randi() % emojis.size()])

	elif roll < 0.65:
		# Misdirect: put a luring emoji on a dead-end cell to waste human attacks
		var pos: Vector2i = _bluff_pick_dead_end_cell()
		if pos.x >= 0:
			var emojis: Array = ["😃", "🤣", "❤️", "😎"]
			emit_signal("ai_bluff", pos.x, pos.y, emojis[randi() % emojis.size()])

	else:
		# Confident bluff: just act tough on a random face-down card
		var pos: Vector2i = _random_unrevealed_self()
		if pos.x >= 0:
			var emojis: Array = ["😎", "👍", "😃"]
			emit_signal("ai_bluff", pos.x, pos.y, emojis[randi() % emojis.size()])

## Called when one of AI's face-up characters is destroyed.
## Queues a mourning bluff to be shown at the start of the AI's next turn.
func decide_death_bluff(row: int, col: int) -> void:
	_pending_death_bluff = Vector2i(row, col)

## Called when AI destroys a strong (100+ ATK/DEF) or union opponent card.
## Places a taunting emoji on the attacker's cell after a short delay.
func decide_kill_taunt(attacker_pos: Vector2i) -> void:
	await get_tree().create_timer(randf_range(0.3, 0.9)).timeout
	var use_poop: bool = SaveManager.nsfw_enabled
	var emojis: Array = ["🤣", "💩" if use_poop else "🖕"]
	emit_signal("ai_bluff", attacker_pos.x, attacker_pos.y, emojis[randi() % emojis.size()])

## Returns the face-down cell with the highest DEF (or a trap) — good for taunting.
func _bluff_pick_taunting_cell() -> Vector2i:
	var best: Vector2i = Vector2i(-1, -1)
	var best_score: int = -1
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(AI_PLAYER, r, c)
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
			var card: GameState.CardInstance = GameState.get_card(AI_PLAYER, r, c)
			if card.card_type == "dead_end" and not card.face_up:
				options.append(Vector2i(r, c))
	if options.is_empty():
		return Vector2i(-1, -1)
	return options[randi() % options.size()]
