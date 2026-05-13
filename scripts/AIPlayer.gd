class_name AIPlayer
extends Node
# "Training" personality AI for VS_AI and Campaign modes.

const AI_PLAYER: int = 1
const HUMAN_PLAYER: int = 0

signal ai_mode_chosen(mode: GameState.TurnMode)
signal ai_attack_chosen(attacker_pos: Vector2i, target_pos: Vector2i)
signal ai_tech_chosen(tech_name: String)
signal ai_target_chosen(pos: Vector2i)
signal ai_trap_choice(choice_index: int)
signal ai_end_turn

# Called at the start of each AI action opportunity (start of turn, after each attack, after tech).
func decide_turn() -> void:
	await get_tree().create_timer(0.6).timeout

	# Rule 1: Tech priority — play tech card before attacking if one is available.
	if GameState.has_playable_tech(AI_PLAYER):
		emit_signal("ai_mode_chosen", GameState.TurnMode.TECH)
		await get_tree().create_timer(0.3).timeout
		_choose_tech()
		return

	# Find best attacker according to Training rules.
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
	var attacker: GameState.CardInstance = GameState.get_card(AI_PLAYER, attacker_pos.x, attacker_pos.y)

	var revealed_chars: Array = []
	var unrevealed: Array = []   # face-down characters, traps (not blank slots)

	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(HUMAN_PLAYER, r, c)
			if card.card_type == "character" and card.face_up:
				revealed_chars.append(Vector2i(r, c))
			elif card.card_type != "blank":
				unrevealed.append(Vector2i(r, c))

	# No revealed targets — attack a random unrevealed cell (rule 3).
	if revealed_chars.is_empty():
		if unrevealed.is_empty():
			return Vector2i(-1, -1)
		return unrevealed[randi() % unrevealed.size()]

	# There are revealed targets.
	var atk: int = attacker.get_effective_atk()

	# Rule 4: pick the weakest-DEF revealed target we can beat (ATK > DEF).
	var beatable: Array = []
	for pos in revealed_chars:
		var def_val: int = GameState.get_card(HUMAN_PLAYER, pos.x, pos.y).get_effective_def()
		if atk > def_val:
			beatable.append(pos)

	if not beatable.is_empty():
		var best: Vector2i = beatable[0]
		var best_def: int = GameState.get_card(HUMAN_PLAYER, best.x, best.y).get_effective_def()
		for pos in beatable:
			var def_val: int = GameState.get_card(HUMAN_PLAYER, pos.x, pos.y).get_effective_def()
			if def_val < best_def:
				best_def = def_val
				best = pos
		return best

	# Cannot beat any revealed char — prefer attacking an unrevealed cell to avoid losing our card.
	if not unrevealed.is_empty():
		return unrevealed[randi() % unrevealed.size()]

	# Last resort: attack the weakest revealed (accept potential crystal loss).
	var weakest: Vector2i = revealed_chars[0]
	var min_def: int = GameState.get_card(HUMAN_PLAYER, weakest.x, weakest.y).get_effective_def()
	for pos in revealed_chars:
		var def_val: int = GameState.get_card(HUMAN_PLAYER, pos.x, pos.y).get_effective_def()
		if def_val < min_def:
			min_def = def_val
			weakest = pos
	return weakest

# ─────────────────────────────────────────────────────────────
# Tech selection
# ─────────────────────────────────────────────────────────────
func _choose_tech() -> void:
	var affordable: Array = []
	for tech_name in GameState.tech_hands[AI_PLAYER]:
		var data: TechCardData = CardDatabase.get_tech(tech_name)
		if data == null:
			continue
		if GameState.crystals[AI_PLAYER] < data.crystal_cost:
			continue
		if data.required_prior_card != "" and not GameState.tech_name_played_this_game(AI_PLAYER, data.required_prior_card):
			continue
		affordable.append(tech_name)

	if affordable.is_empty():
		return

	var chosen: String = affordable[randi() % affordable.size()]
	emit_signal("ai_tech_chosen", chosen)

# ─────────────────────────────────────────────────────────────
# Target decision for tech/trap effects
# ─────────────────────────────────────────────────────────────
func decide_target(filter: String) -> Vector2i:
	match filter:
		"opponent_squares_1", "opponent_squares_2", "opponent_squares_3":
			return _random_unrevealed_opponent()
		"own_faceup_character":
			return _best_own_faceup()
		_:
			return _random_unrevealed_opponent()

func _random_unrevealed_opponent() -> Vector2i:
	var options: Array = []
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(HUMAN_PLAYER, r, c)
			if not card.face_up:
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
# Setup phase placement
# ─────────────────────────────────────────────────────────────
func decide_setup() -> Array:
	var placements: Array = []

	var cfg: Dictionary = GameState.campaign_enemy_config \
		if not GameState.campaign_enemy_config.is_empty() else {}

	var forced_chars: Variant = cfg.get("forced_characters", null)
	var char_pool: Array
	if forced_chars is Array and not (forced_chars as Array).is_empty():
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
	if forced_chars is Array and not (forced_chars as Array).is_empty():
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

	var positions: Array = []
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			positions.append(Vector2i(r, c))
	positions.shuffle()

	var idx: int = 0
	for i in range(num_chars):
		if idx >= positions.size():
			break
		placements.append({
			"pos": positions[idx],
			"card_type": "character",
			"card_name": char_pool[i % char_pool.size()]
		})
		idx += 1

	for i in range(num_traps):
		if idx >= positions.size():
			break
		placements.append({
			"pos": positions[idx],
			"card_type": "trap",
			"card_name": trap_pool[i % trap_pool.size()]
		})
		idx += 1

	return placements

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
