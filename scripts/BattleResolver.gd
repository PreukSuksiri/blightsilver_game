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
	# Post-battle pending actions for TurnManager
	var pending_reveal_opponent_cell: bool = false  # attacker should reveal 1 opp cell
	var pending_coin_flip_swap_position: bool = false  # attacker should coin-flip swap position

# ─────────────────────────────────────────────────────────────
# Main Resolution
# ─────────────────────────────────────────────────────────────
static func resolve_battle(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		dice_roll: int,
		attacker_player: int,
		defender_player: int,
		defender_was_exposed: bool = false,
		target_pos: Vector2i = Vector2i(-1, -1)
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
			_resolve_character_vs_character(
				attacker, defender, dice_roll, attacker_player, defender_player, target_pos, result)
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
		target_pos: Vector2i,
		result: BattleResult
) -> void:
	var base_atk: int = attacker.get_effective_atk()
	var eff_atk: int = _get_effective_atk(attacker, defender, dice_roll, attacker_player, target_pos)
	if eff_atk != base_atk:
		result.ability_triggered_attacker = true

	var base_def: int = defender.get_effective_def()
	var eff_def: int = _get_effective_def(defender, attacker, defender_player)
	if eff_def != base_def:
		result.ability_triggered_defender = true

	# Populate delta fields for overlay display
	result.attacker_atk_used  = eff_atk
	result.defender_def_used  = eff_def
	result.attacker_atk_delta = eff_atk - base_atk
	result.defender_def_delta = eff_def - base_def

	result.messages.append("%s ATK %d vs %s DEF %d" % [attacker.card_name, eff_atk, defender.card_name, eff_def])

	# DESTROY_SELF_VS_DIVINE_BOTH: Feral Vampire destroyed when battling Divine (either role)
	if defender.affinity == CharacterData.Affinity.DIVINE:
		if attacker.ability_type == CharacterData.AbilityType.DESTROY_SELF_VS_DIVINE_BOTH:
			result.ability_triggered_attacker = true
			result.attacker_destroyed = true
			result.attacker_crystal_loss = attacker.crystal_cost
			result.messages.append("%s is destroyed battling Divine!" % attacker.card_name)
			if eff_atk >= eff_def:
				result.defender_destroyed = true
				result.defender_crystal_loss = defender.crystal_cost
			return
	if attacker.affinity == CharacterData.Affinity.DIVINE:
		if defender.ability_type == CharacterData.AbilityType.DESTROY_SELF_VS_DIVINE_BOTH:
			result.ability_triggered_defender = true
			result.defender_destroyed = true
			result.defender_crystal_loss = defender.crystal_cost
			result.messages.append("%s is destroyed battling Divine!" % defender.card_name)
			# Normal comparison still happens
			if eff_atk <= eff_def:
				result.attacker_destroyed = true
				result.attacker_crystal_loss = attacker.crystal_cost
			return

	# DESTROY_IF_OPPONENT_AFFINITY: Goblin Poacher / Goddess of Virtue
	if attacker.ability_type == CharacterData.AbilityType.DESTROY_IF_OPPONENT_AFFINITY:
		if defender.affinity == attacker.ability_params.get("affinity", -1):
			result.ability_triggered_attacker = true
			result.defender_destroyed = true
			result.defender_crystal_loss = defender.crystal_cost
			result.messages.append("%s destroys %s by affinity!" % [attacker.card_name, defender.card_name])
			_apply_post_attack_effects(attacker, result)
			return

	# COIN_FLIP_2_DESTROY_NON_AFFINITY: Bleacher Squad / Blue Mage
	if attacker.ability_type == CharacterData.AbilityType.COIN_FLIP_2_DESTROY_NON_AFFINITY:
		if defender.affinity != attacker.ability_params.get("affinity", -1):
			var h1: bool = randf() >= 0.5
			var h2: bool = randf() >= 0.5
			result.ability_triggered_attacker = true
			if h1 and h2:
				result.messages.append("%s: Two heads — %s is destroyed!" % [attacker.card_name, defender.card_name])
				result.defender_destroyed = true
				result.defender_crystal_loss = defender.crystal_cost
				_apply_post_attack_effects(attacker, result)
				return
			else:
				result.messages.append("%s: Coin flip missed — normal battle." % attacker.card_name)

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
		_apply_post_attack_effects(attacker, result)
	elif eff_atk < eff_def:
		result.attacker_destroyed = true
		result.attacker_crystal_loss = attacker.crystal_cost
		result.messages.append("%s defends successfully!" % defender.card_name)
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
		attacker_player: int,
		_defender_player: int,
		result: BattleResult
) -> void:
	var trap_data: TrapData = CardDatabase.get_trap(trap.card_name)
	if trap_data == null:
		result.messages.append("Unknown trap: %s" % trap.card_name)
		return

	result.messages.append("Trap triggered: %s!" % trap.card_name)

	# NEGATE_ZERO_COST_TRAPS_BOTH: Electrogazer on either player's field negates all 0-cost traps
	if trap_data.crystal_cost == 0:
		for p in [0, 1]:
			for r in range(GameState.GRID_SIZE):
				for c in range(GameState.GRID_SIZE):
					var field_card: GameState.CardInstance = GameState.grids[p][r][c]
					if field_card.card_type == "character" and field_card.face_up:
						if field_card.ability_type == CharacterData.AbilityType.NEGATE_ZERO_COST_TRAPS_BOTH:
							result.messages.append("%s negates zero-cost traps!" % field_card.card_name)
							result.special_trigger = "trap_nullified"
							return

	# Immune to zero-cost traps
	if trap_data.crystal_cost == 0:
		if attacker.ability_type == CharacterData.AbilityType.IMMUNE_ZERO_COST_TRAPS:
			result.messages.append("%s is immune to 0-cost Traps!" % attacker.card_name)
			result.special_trigger = "trap_nullified"
			return
		if attacker.ability_type == CharacterData.AbilityType.IMMUNE_TO_TECH_DESTRUCTION:
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
	result.special_params = {"trap_name": trap.card_name, "trap_data": trap_data,
		"attacker_player": attacker_player}

# ─────────────────────────────────────────────────────────────
# ATK / DEF Calculation
# ─────────────────────────────────────────────────────────────
static func _get_effective_atk(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		dice_roll: int,
		attacker_player: int,
		target_pos: Vector2i = Vector2i(-1, -1)
) -> int:
	var atk: int = attacker.get_effective_atk()

	# Bare Hands Brawling: character abilities are cancelled
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers:
		return atk

	# DEF_ZERO_WHEN_EXPOSED: attacker's DEF = 0 when face-up (doesn't affect ATK, skip)
	# ATK_PENALTY_WHEN_EXPOSED: attacker's own ATK is penalised when face-up
	if attacker.face_up and attacker.ability_type == CharacterData.AbilityType.ATK_PENALTY_WHEN_EXPOSED:
		atk = max(0, atk - attacker.ability_params.get("amount", 0))

	# ATK_PENALTY_IF_NO_NAME_ALLY: e.g. Moon Tribe Marksman
	if attacker.ability_type == CharacterData.AbilityType.ATK_PENALTY_IF_NO_NAME_ALLY:
		var name_filter: String = attacker.ability_params.get("name_contains", "").to_lower()
		var found_ally: bool = false
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var ally: GameState.CardInstance = GameState.grids[attacker_player][r][c]
				if ally == attacker:
					continue
				if ally.card_type == "character" and name_filter in ally.card_name.to_lower():
					found_ally = true
					break
		if not found_ally:
			atk = max(0, atk - attacker.ability_params.get("penalty", 0))

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

		CharacterData.AbilityType.ATK_BONUS_VS_FACEDOWN:
			if not defender.face_up:
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_BONUS_VS_UNION:
			if defender.is_union:
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_BONUS_VS_VENOM:
			if "venom" in defender.flags:
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_DEF_BONUS_VS_NON_AFFINITY:
			if defender.affinity != attacker.ability_params.get("affinity", -1):
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_BONUS_IF_AFFINITY_ON_FIELD:
			var needed_aff: int = attacker.ability_params.get("affinity", -1)
			for r in range(GameState.GRID_SIZE):
				for c in range(GameState.GRID_SIZE):
					var ally: GameState.CardInstance = GameState.grids[attacker_player][r][c]
					if ally.card_type == "character" and ally.face_up and ally.affinity == needed_aff:
						atk += attacker.ability_params.get("bonus", 0)
						break

		CharacterData.AbilityType.ATK_DEF_BONUS_IF_UNION_ON_FIELD:
			for r in range(GameState.GRID_SIZE):
				for c in range(GameState.GRID_SIZE):
					var ally: GameState.CardInstance = GameState.grids[attacker_player][r][c]
					if ally.is_union and ally.face_up:
						atk += attacker.ability_params.get("atk", 0)
						break

		CharacterData.AbilityType.ATTACK_STANCE_BOOST:
			atk += attacker.ability_params.get("atk_bonus", 0)

		CharacterData.AbilityType.COIN_FLIP_ATK_BOOST:
			if randf() >= 0.5:
				atk += attacker.ability_params.get("bonus", 0)
				GameState.post_message("%s coin flip: heads! +%d ATK" % [attacker.card_name, attacker.ability_params.get("bonus", 0)])
			else:
				GameState.post_message("%s coin flip: tails — no bonus." % attacker.card_name)

		CharacterData.AbilityType.SWAP_ATK_DEF_WHEN_ATTACKING:
			atk = attacker.get_effective_def()  # use DEF as ATK

		CharacterData.AbilityType.ONE_USE_ATK_BOOST:
			if not attacker.one_use_atk_boost_used:
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND:
			if not attacker.one_use_atk_boost_used:
				atk += attacker.ability_params.get("atk_bonus", 0)

		CharacterData.AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES:
			if attacker.has_mutagen_flag:
				var affinities = attacker.ability_params.get("affinities", [])
				if defender.affinity in affinities:
					atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_BONUS_VS_CENTER_ZONE:
			if target_pos.x >= 0:
				var in_center_zone: bool = (target_pos.x >= 1 and target_pos.x <= 3
					and target_pos.y >= 1 and target_pos.y <= 3)
				var in_very_center: bool = (target_pos.x == 2 and target_pos.y == 2)
				if in_center_zone:
					atk += attacker.ability_params.get("zone_bonus", 20)
				if in_very_center:
					atk += attacker.ability_params.get("center_bonus", 40)

		CharacterData.AbilityType.NOT_IMPLEMENTED:
			GameState.show_center_message("Ability not implemented: " + attacker.card_name)

	# Check defender abilities that debuff attacker ATK
	if defender.ability_type == CharacterData.AbilityType.ATTACKER_ATK_DEBUFF:
		if defender.effect_nullified_until < GameState.turn_number:
			var debuff_amount: int = defender.ability_params.get("amount", 0)
			atk = max(0, atk - debuff_amount)
			GameState.post_message("%s: Attacker loses %d ATK!" % [defender.card_name, debuff_amount])

	# Nullified effect — restore base ATK
	if attacker.effect_nullified_until >= GameState.turn_number:
		atk = attacker.get_effective_atk()

	return atk

static func _get_effective_def(
		defender: GameState.CardInstance,
		attacker: GameState.CardInstance,
		defender_player: int = -1
) -> int:
	var def_val: int = defender.get_effective_def()

	# Bare Hands Brawling: character abilities are cancelled
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers:
		return def_val

	# DEF_ZERO_WHEN_EXPOSED: DEF = 0 when face-up
	if defender.face_up and defender.ability_type == CharacterData.AbilityType.DEF_ZERO_WHEN_EXPOSED:
		return 0

	match defender.ability_type:
		CharacterData.AbilityType.DEF_BONUS_VS_AFFINITY:
			if attacker.affinity == defender.ability_params.get("affinity", -1):
				def_val += defender.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY:
			if attacker.affinity == defender.ability_params.get("affinity", -1):
				def_val += defender.ability_params.get("def", 0)

		CharacterData.AbilityType.ATK_DEF_BONUS_VS_NON_AFFINITY:
			if attacker.affinity != defender.ability_params.get("affinity", -1):
				def_val += defender.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ONE_USE_DEF_BOOST:
			if not defender.one_use_def_boost_used:
				def_val += defender.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND:
			if not defender.one_use_def_boost_used:
				def_val += defender.ability_params.get("def_bonus", 0)

		CharacterData.AbilityType.DEFENSE_STANCE_BOOST:
			def_val += defender.ability_params.get("def_bonus", 0)

		CharacterData.AbilityType.DEF_BONUS_IF_AFFINITY_ON_FIELD:
			if defender_player >= 0:
				var needed_aff: int = defender.ability_params.get("affinity", -1)
				for r in range(GameState.GRID_SIZE):
					for c in range(GameState.GRID_SIZE):
						var ally: GameState.CardInstance = GameState.grids[defender_player][r][c]
						if ally.card_type == "character" and ally.face_up and ally.affinity == needed_aff:
							def_val += defender.ability_params.get("bonus", 0)
							break

		CharacterData.AbilityType.NOT_IMPLEMENTED:
			GameState.show_center_message("Ability not implemented: " + defender.card_name)

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
		attacker: GameState.CardInstance,
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

		CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND:
			if not defender.one_use_def_boost_used:
				result.ability_triggered_defender = true
				defender.one_use_def_boost_used = true

		CharacterData.AbilityType.PERM_DEF_BOOST_ON_DEFEND:
			result.ability_triggered_defender = true
			defender.current_def += defender.ability_params.get("bonus", 0)
			result.messages.append("%s gains +%d DEF permanently!" % [
				defender.card_name, defender.ability_params.get("bonus", 0)])

		CharacterData.AbilityType.ONE_USE_PERM_DEBUFF_ATTACKER_ATK:
			if not defender.one_use_def_boost_used:
				result.ability_triggered_defender = true
				defender.one_use_def_boost_used = true
				attacker.current_atk = max(0, attacker.current_atk - defender.ability_params.get("amount", 0))
				result.messages.append("%s: %s permanently loses %d ATK!" % [
					defender.card_name, attacker.card_name, defender.ability_params.get("amount", 0)])

		CharacterData.AbilityType.DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF:
			result.ability_triggered_defender = true
			var debuff: int = defender.ability_params.get("amount", 0)
			attacker.current_atk = max(0, attacker.current_atk - debuff)
			attacker.current_def = max(0, attacker.current_def - debuff)
			result.messages.append("%s: %s permanently loses %d ATK and DEF!" % [
				defender.card_name, attacker.card_name, debuff])

		CharacterData.AbilityType.ONE_USE_DEFEND_MORPH:
			if not defender.one_use_def_boost_used:
				result.ability_triggered_defender = true
				defender.one_use_def_boost_used = true
				var def_loss: int = defender.ability_params.get("def_loss", 40)
				var atk_gain: int = defender.ability_params.get("atk_gain", 40)
				defender.current_def = max(0, defender.current_def - def_loss)
				defender.current_atk += atk_gain
				result.messages.append("%s morphs: -%d DEF, +%d ATK permanently!" % [
					defender.card_name, def_loss, atk_gain])

		CharacterData.AbilityType.SELF_DEBUFF_ON_ATTACK_AND_DEFEND:
			if not defender.one_use_def_boost_used:
				result.ability_triggered_defender = true
				defender.one_use_def_boost_used = true
				var def_debuff: int = defender.ability_params.get("def_amount", 5)
				defender.current_def = max(0, defender.current_def - def_debuff)
				result.messages.append("%s: permanently -%d DEF from defending." % [
					defender.card_name, def_debuff])

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
