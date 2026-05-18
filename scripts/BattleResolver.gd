class_name BattleResolver
# Pure battle logic - no scene dependencies, fully testable.

# ─────────────────────────────────────────────────────────────
# Battle Result
# ─────────────────────────────────────────────────────────────
class BattleResult:
	var attacker_destroyed: bool = false
	var defender_destroyed: bool = false
	var attacker_crystal_loss: int = 0
	var defender_crystal_loss: int = 0
	var attacker_crystal_gain: int = 0
	var defender_crystal_gain: int = 0
	var messages: Array = []
	var special_trigger: String = ""
	var special_params: Dictionary = {}
	var ability_triggered_attacker: bool = false
	var ability_triggered_defender: bool = false
	# Stat delta fields — difference between base and effective values entering battle
	var attacker_atk_used: int = 0   # effective ATK used
	var defender_def_used: int = 0   # effective DEF used
	var attacker_atk_delta: int = 0  # positive = bonus, negative = debuff
	var defender_def_delta: int = 0
	var attacker_def_delta: int = 0  # for future symmetric display
	var defender_atk_delta: int = 0
	# Whether the defender was already face_up before this attack
	var defender_was_exposed: bool = false

# ─────────────────────────────────────────────────────────────
# Main Resolution
# ─────────────────────────────────────────────────────────────
static func resolve_battle(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		dice_roll: int,
		attacker_player: int,
		defender_player: int,
		defender_was_exposed: bool = false
) -> BattleResult:
	var result := BattleResult.new()
	result.defender_was_exposed = defender_was_exposed

	match defender.card_type:
		"dead_end":
			result.messages.append("Nothing happens — Dead End.")
			return result

		"trap":
			_resolve_trap(attacker, defender, attacker_player, defender_player, result)
			return result

		"character":
			_resolve_character_vs_character(attacker, defender, dice_roll, attacker_player, defender_player, result)
			return result

	return result

# ─────────────────────────────────────────────────────────────
# Character vs Character
# ─────────────────────────────────────────────────────────────
static func _resolve_character_vs_character(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		dice_roll: int,
		attacker_player: int,
		defender_player: int,
		result: BattleResult
) -> void:
	var base_atk: int = attacker.get_effective_atk()
	var eff_atk: int = _get_effective_atk(attacker, defender, dice_roll)
	if eff_atk != base_atk:
		result.ability_triggered_attacker = true

	var base_def: int = defender.get_effective_def()
	var eff_def: int = _get_effective_def(defender, attacker)
	if eff_def != base_def:
		result.ability_triggered_defender = true

	# Populate delta fields for overlay display
	result.attacker_atk_used  = eff_atk
	result.defender_def_used  = eff_def
	result.attacker_atk_delta = eff_atk - base_atk
	result.defender_def_delta = eff_def - base_def

	result.messages.append("%s ATK %d vs %s DEF %d" % [attacker.card_name, eff_atk, defender.card_name, eff_def])

	# Check Pit Lord destroyed-by-divine rule
	if attacker.ability_type == CharacterData.AbilityType.DESTROYED_IF_BATTLES_DIVINE:
		if defender.affinity == CharacterData.Affinity.DIVINE:
			result.ability_triggered_attacker = true
			result.attacker_destroyed = true
			result.attacker_crystal_loss = attacker.crystal_cost
			result.messages.append("%s is destroyed by Divine!" % attacker.card_name)
			# Still compare normally for defender
			if eff_atk > eff_def:
				result.defender_destroyed = true
				result.defender_crystal_loss = defender.crystal_cost
			elif eff_atk == eff_def:
				result.defender_destroyed = true
				result.defender_crystal_loss = defender.crystal_cost
			return

	# Normal ATK vs DEF comparison
	if eff_atk > eff_def:
		result.defender_destroyed = true
		result.defender_crystal_loss = defender.crystal_cost
		result.messages.append("%s wins!" % attacker.card_name)
		# Attacker halve-after-attack (Pit Lord)
		_apply_post_attack_effects(attacker, result)
	elif eff_atk < eff_def:
		result.attacker_destroyed = true
		result.attacker_crystal_loss = attacker.crystal_cost
		result.messages.append("%s defends successfully!" % defender.card_name)
		# Defender gains crystals on successful defend
		_apply_defend_effects(defender, attacker, result, defender_player)
	else:
		# Equal — both destroyed
		result.attacker_destroyed = true
		result.defender_destroyed = true
		result.attacker_crystal_loss = attacker.crystal_cost
		result.defender_crystal_loss = defender.crystal_cost
		result.messages.append("Both cards are destroyed!")

	# Lab Bloater Mutagen effect (overrides normal if defender survives)
	if not result.defender_destroyed and defender.has_mutagen_flag:
		if defender.ability_type == CharacterData.AbilityType.MUTAGEN_DESTROY_ATTACKER:
			result.ability_triggered_defender = true
			result.attacker_destroyed = true
			result.attacker_crystal_loss = attacker.crystal_cost
			result.defender_crystal_loss = 0  # no crystal loss for bloater
			result.messages.append("Lab Bloater Mutagen: Attacker destroyed!")

# ─────────────────────────────────────────────────────────────
# Trap Resolution (returns special trigger for complex effects)
# ─────────────────────────────────────────────────────────────
static func _resolve_trap(
		attacker: GameState.CardInstance,
		trap: GameState.CardInstance,
		_attacker_player: int,
		_defender_player: int,
		result: BattleResult
) -> void:
	var trap_data: TrapData = CardDatabase.get_trap(trap.card_name)
	if trap_data == null:
		result.messages.append("Unknown trap: %s" % trap.card_name)
		return

	result.messages.append("Trap triggered: %s!" % trap.card_name)

	# Immune to zero-cost traps
	if trap_data.crystal_cost == 0:
		if attacker.ability_type == CharacterData.AbilityType.IMMUNE_ZERO_COST_TRAPS:
			result.messages.append("%s is immune to 0-cost Traps!" % attacker.card_name)
			result.special_trigger = "trap_nullified"
			return
		if attacker.ability_type == CharacterData.AbilityType.IMMUNE_TO_TECH_DESTRUCTION:
			# Ironclad Sentinel is immune to 0-cost traps too
			result.messages.append("%s is immune to 0-cost Traps!" % attacker.card_name)
			result.special_trigger = "trap_nullified"
			return

	# Immune to all traps
	if attacker.ability_type == CharacterData.AbilityType.IMMUNE_TO_TRAPS:
		result.messages.append("%s cannot be destroyed by Traps!" % attacker.card_name)
		result.special_trigger = "trap_nullified"
		return

	# Trap crystal loss to trap owner (defender pays trap cost)
	result.defender_crystal_loss = trap_data.crystal_cost
	result.special_trigger = "trap_effect"
	result.special_params = {"trap_name": trap.card_name, "trap_data": trap_data}

# ─────────────────────────────────────────────────────────────
# ATK / DEF Calculation
# ─────────────────────────────────────────────────────────────
static func _get_effective_atk(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		dice_roll: int
) -> int:
	var atk: int = attacker.get_effective_atk()

	# Bare Hands Brawling: character abilities are cancelled
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers:
		return atk

	match attacker.ability_type:
		CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY:
			if defender.affinity == attacker.ability_params.get("affinity", -1):
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY:
			if defender.affinity == attacker.ability_params.get("affinity", -1):
				atk += attacker.ability_params.get("atk", 0)

		CharacterData.AbilityType.ATK_BONUS_VS_TWO_AFFINITIES:
			var a1 = attacker.ability_params.get("aff1", -1)
			var a2 = attacker.ability_params.get("aff2", -1)
			if defender.affinity == a1 or defender.affinity == a2:
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_BONUS_IF_DICE_HIGH:
			if dice_roll >= attacker.ability_params.get("threshold", 4):
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_BOOST_VS_REVEALED:
			if defender.face_up:
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES:
			if attacker.has_mutagen_flag:
				var affinities = attacker.ability_params.get("affinities", [])
				if defender.affinity in affinities:
					atk += attacker.ability_params.get("bonus", 0)

	# Nullified effect
	if attacker.effect_nullified_until >= GameState.turn_number:
		# don't apply ability bonus already added above — restore base
		atk = attacker.get_effective_atk()

	return atk

static func _get_effective_def(
		defender: GameState.CardInstance,
		attacker: GameState.CardInstance
) -> int:
	var def_val: int = defender.get_effective_def()

	# Bare Hands Brawling: character abilities are cancelled
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers:
		return def_val

	match defender.ability_type:
		CharacterData.AbilityType.DEF_BONUS_VS_AFFINITY:
			if attacker.affinity == defender.ability_params.get("affinity", -1):
				def_val += defender.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY:
			if attacker.affinity == defender.ability_params.get("affinity", -1):
				def_val += defender.ability_params.get("def", 0)

		CharacterData.AbilityType.ONE_USE_DEF_BOOST:
			if not defender.one_use_def_boost_used:
				def_val += defender.ability_params.get("bonus", 0)

	return def_val

static func _apply_post_attack_effects(
		attacker: GameState.CardInstance,
		_result: BattleResult
) -> void:
	# Pit Lord halves stats after attacking
	var also_halve: bool = attacker.ability_params.get("also_halve_after_attack", false)
	if attacker.ability_type == CharacterData.AbilityType.DESTROYED_IF_BATTLES_DIVINE or also_halve:
		attacker.halve_stats()

static func _apply_defend_effects(
		defender: GameState.CardInstance,
		_attacker: GameState.CardInstance,
		result: BattleResult,
		_defender_player: int
) -> void:
	# Bare Hands Brawling: character abilities are cancelled
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers:
		return
	match defender.ability_type:
		CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND:
			result.ability_triggered_defender = true
			result.defender_crystal_gain += defender.ability_params.get("amount", 0)
			result.messages.append("%s gains %d Crystals!" % [
				defender.card_name,
				defender.ability_params.get("amount", 0)
			])
		CharacterData.AbilityType.DEFEND_DRAIN_ATTACKER:
			result.ability_triggered_defender = true
			result.attacker_crystal_loss += defender.ability_params.get("drain_amount", 0)
			result.messages.append("%s drains %d Crystals from attacker!" % [
				defender.card_name,
				defender.ability_params.get("drain_amount", 0)
			])
		CharacterData.AbilityType.ONE_USE_DEF_BOOST:
			if not defender.one_use_def_boost_used:
				result.ability_triggered_defender = true
				defender.one_use_def_boost_used = true

# ─────────────────────────────────────────────────────────────
# Field-based stat calculation (called before each battle)
# ─────────────────────────────────────────────────────────────
static func calculate_field_bonuses(player_index: int) -> void:
	var all_chars := GameState.get_all_characters(player_index)
	for entry in all_chars:
		var card: GameState.CardInstance = entry["card"]
		_apply_field_ability_bonus(card, player_index)

static func _apply_field_ability_bonus(
		card: GameState.CardInstance,
		player_index: int
) -> void:
	match card.ability_type:
		CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD:
			var count := _count_matching_cards(player_index, card)
			card.perm_atk_bonus = card.ability_params.get("atk_bonus", 0) * count
			card.perm_def_bonus = card.ability_params.get("def_bonus", 0) * count

		CharacterData.AbilityType.BOOST_PER_ANIMA_ON_FIELD:
			var count := _count_anima_cards(player_index, card)
			card.perm_atk_bonus = card.ability_params.get("atk_bonus", 0) * count
			card.perm_def_bonus = card.ability_params.get("def_bonus", 0) * count

static func _count_matching_cards(player_index: int, source_card: GameState.CardInstance) -> int:
	var count := 0
	var name_filter: String = source_card.ability_params.get("card_name_contains", "").to_lower()
	var affinity_filter: int = source_card.ability_params.get("affinity", -1)

	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.grids[player_index][r][c]
			if card == source_card:
				continue
			if card.card_type != "character":
				continue
			if name_filter != "" and name_filter in card.card_name.to_lower():
				if card.face_up:
					count += 1
			elif affinity_filter != -1 and card.affinity == affinity_filter:
				if card.face_up:
					count += 1
	return count

static func _count_anima_cards(player_index: int, source_card: GameState.CardInstance) -> int:
	var count := 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.grids[player_index][r][c]
			if card == source_card:
				continue
			if card.card_type == "character" and card.face_up:
				if card.affinity == CharacterData.Affinity.ANIMA:
					count += 1
	return count
