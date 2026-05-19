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
signal ai_union_chosen(union_name: String, zone_cells: Array, material_cells: Array)

# Per-duel state
var _ai_turn_count: int = 0   # incremented at start of each decide_turn call
var _union_used:    bool = false

# Called at the start of each AI action opportunity (start of turn, after each attack, after tech).
func decide_turn() -> void:
	_ai_turn_count += 1
	await get_tree().create_timer(0.6).timeout

	# Rule 1: Tech priority — play tech card before attacking if one is available.
	if GameState.has_playable_tech(AI_PLAYER):
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
				var picked: Dictionary = unions[randi() % unions.size()]
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
	var attacker: GameState.CardInstance = GameState.get_card(AI_PLAYER, attacker_pos.x, attacker_pos.y)

	var revealed_chars: Array = []
	var unrevealed: Array = []   # face-down characters, traps (not blank slots)

	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(HUMAN_PLAYER, r, c)
			if card.card_type == "character" and card.face_up:
				revealed_chars.append(Vector2i(r, c))
			elif card.card_type != "dead_end":
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
		"opponent_squares_1", "opponent_squares_2", "opponent_squares_3", "opponent_any_hidden":
			return _random_unrevealed_opponent()
		"own_faceup_character", "own_character_for_swap", \
				"own_faceup_for_trap_temp_def_boost", "own_character_for_trap_self_destruct":
			return _best_own_faceup()
		_:
			return _random_unrevealed_opponent()

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
