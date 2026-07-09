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
	var destruction_blocked_attacker: bool = false
	var destruction_blocked_defender: bool = false
	# Stat delta fields — difference between base and effective values entering battle
	var attacker_atk_used: int = 0   # effective ATK used
	var defender_def_used: int = 0   # effective DEF used
	var attacker_atk_delta: int = 0  # positive = bonus, negative = debuff
	var defender_def_delta: int = 0
	var attacker_def_delta: int = 0  # for future symmetric display
	var defender_atk_delta: int = 0
	# Frozen pill values at Reckoning open — captured at resolve time (cards may be destroyed before log)
	var attacker_pill_atk: int = 0
	var attacker_pill_def: int = 0
	var defender_pill_atk: int = 0
	var defender_pill_def: int = 0
	# Whether the defender was already face_up before this attack
	var defender_was_exposed: bool = false
	# Post-battle pending actions for TurnManager
	var pending_reveal_opponent_cell: bool = false  # attacker should reveal 1 opp cell
	var pending_coin_flip_swap_position: bool = false  # attacker should coin-flip swap position
	# Coin results accumulated during this battle resolution (for visual display in GameBoard)
	var coin_flip_results: Array = []  # Array of bool — true=heads, false=tails
	# Card names captured before destruction — used by loggers that fire after destroy_card()
	var attacker_name: String = ""
	var defender_name: String = ""
	# Full unit/union labels with buffs, debuffs, flags, and status (also captured pre-destruction)
	var attacker_log_label: String = ""
	var defender_log_label: String = ""

# ─────────────────────────────────────────────────────────────
# Coin-flip accumulator — reset at start of each resolve_battle call
# so _get_effective_atk helpers can append without carrying a result ref.
# ─────────────────────────────────────────────────────────────
static var _battle_coin_results: Array = []

# Pre-rolled coins from TurnManager (Reckoning visual runs before resolve_battle).
static var _predetermined_coin_flips: Array = []
static var _predetermined_coin_flip_index: int = 0
static var _coin_flip_source_card: GameState.CardInstance = null
static var _coin_flip_source_player: int = -1

static func set_coin_flip_source(card: GameState.CardInstance, player_index: int) -> void:
	_coin_flip_source_card = card
	_coin_flip_source_player = player_index

static func clear_coin_flip_source() -> void:
	_coin_flip_source_card = null
	_coin_flip_source_player = -1

static func set_predetermined_coin_flips(flips: Array) -> void:
	_predetermined_coin_flips = flips.duplicate()
	_predetermined_coin_flip_index = 0

static func reset_predetermined_coin_flip_index() -> void:
	_predetermined_coin_flip_index = 0

static func clear_predetermined_coin_flips() -> void:
	_predetermined_coin_flips = []
	_predetermined_coin_flip_index = 0

static func _roll_battle_coin() -> bool:
	if _predetermined_coin_flip_index < _predetermined_coin_flips.size():
		var r: bool = bool(_predetermined_coin_flips[_predetermined_coin_flip_index])
		_predetermined_coin_flip_index += 1
		return r
	if _coin_flip_source_card != null and _coin_flip_source_player >= 0:
		var _cf_pos: Vector2i = GameState.find_card_position(
			_coin_flip_source_player, _coin_flip_source_card)
		if _cf_pos.x >= 0 \
				and GameState.adjacent_force_coin_heads_active_for(
					_coin_flip_source_player, _cf_pos.x, _cf_pos.y):
			if not _silent_mode:
				GameState.post_message("Maria the Battle Priest: Coin flip forced to heads!")
			return true
	return randf() >= 0.5

# When true, suppress inline GameState.post_message() calls inside helpers.
# Used by the preview (first) resolve_battle call in perform_attack() so that
# ability messages only fire once — during the real resolution.
static var _silent_mode: bool = false

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
		target_pos: Vector2i = Vector2i(-1, -1),
		silent: bool = false
) -> BattleResult:
	_silent_mode = silent
	_battle_coin_results = []
	var result := BattleResult.new()
	result.defender_was_exposed = defender_was_exposed

	match defender.card_type:
		"dead_end":
			result.messages.append("Nothing happens — Dead End.")
			if attacker.card_type == "character":
				_populate_attacker_reckoning_fields(
					attacker, defender, dice_roll, attacker_player, defender_was_exposed, target_pos, result)
			return result

		"trap":
			_resolve_trap(
				attacker, defender, attacker_player, defender_player, dice_roll,
				defender_was_exposed, target_pos, result)
			return result

		"character":
			_resolve_character_vs_character(
				attacker, defender, dice_roll, attacker_player, defender_player, target_pos,
				result, defender_was_exposed)
			result.coin_flip_results = _battle_coin_results.duplicate()
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
		result: BattleResult,
		defender_was_exposed: bool = false
) -> void:
	# DESTROY_SELF_VS_DIVINE_BOTH: Vampire Duchess / Immortal Vampire / Feral Vampire —
	# self-destruct before Reckoning when either role battles Divine (no ATK/DEF compare).
	if _try_destroy_self_vs_divine_before_calc(attacker, defender, result):
		return

	_apply_pre_battle_perm_debuffs(attacker, defender, attacker_player, defender_player, result)

	var base_atk: int = attacker.get_effective_atk()
	var eff_atk: int = _get_effective_atk(
		attacker, defender, dice_roll, attacker_player, target_pos, defender_was_exposed)
	if eff_atk != base_atk:
		result.ability_triggered_attacker = true

	var base_def: int = defender.get_effective_def()
	var eff_def: int = _get_effective_def(defender, attacker, defender_player)
	if eff_def != base_def:
		result.ability_triggered_defender = true

	# Populate delta and frozen pill fields for overlay display / E2E log
	result.attacker_atk_used  = eff_atk
	result.defender_def_used  = eff_def
	result.attacker_atk_delta = eff_atk - base_atk
	result.defender_def_delta = eff_def - base_def
	result.attacker_pill_atk  = base_atk
	result.attacker_pill_def  = attacker.get_effective_def()
	result.defender_pill_atk  = defender.get_effective_atk()
	result.defender_pill_def  = base_def

	# One-time defense boosts apply whenever this card is attacked — spend before outcome.
	if not _silent_mode:
		_spend_one_use_defense_boosts(defender, result)

	# Vampire Duchess: permanently drain defender ATK/DEF into attacker at battle calculation.
	if _apply_attacker_battle_drain(attacker, defender, result):
		base_atk = attacker.get_effective_atk()
		eff_atk = _get_effective_atk(
			attacker, defender, dice_roll, attacker_player, target_pos, defender_was_exposed)
		base_def = defender.get_effective_def()
		eff_def = _get_effective_def(defender, attacker, defender_player)
		result.attacker_atk_used = eff_atk
		result.defender_def_used = eff_def
		result.attacker_atk_delta = eff_atk - base_atk
		result.defender_def_delta = eff_def - base_def
		result.attacker_pill_atk = base_atk
		result.attacker_pill_def = attacker.get_effective_def()
		result.defender_pill_atk = defender.get_effective_atk()
		result.defender_pill_def = base_def

	result.messages.append("%s ATK %d vs %s DEF %d" % [attacker.card_name, eff_atk, defender.card_name, eff_def])

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
			set_coin_flip_source(attacker, attacker_player)
			var h1: bool = _roll_battle_coin()
			var h2: bool = _roll_battle_coin()
			clear_coin_flip_source()
			_battle_coin_results.append(h1)
			_battle_coin_results.append(h2)
			result.ability_triggered_attacker = true
			if h1 and h2:
				result.messages.append("%s: Two heads — %s is destroyed!" % [attacker.card_name, defender.card_name])
				result.defender_destroyed = true
				result.defender_crystal_loss = defender.crystal_cost
				_apply_post_attack_effects(attacker, result)
				return
			else:
				result.messages.append("%s: Coin flip missed — normal battle." % attacker.card_name)

	# ONE_USE_DESTROY_BY_AFFINITY: Genesis Mech — once, destroy a card matching aff1 or aff2
	if attacker.ability_type == CharacterData.AbilityType.ONE_USE_DESTROY_BY_AFFINITY \
			and not attacker.one_use_atk_boost_used:
		var _a1: int = attacker.ability_params.get("aff1", -1)
		var _a2: int = attacker.ability_params.get("aff2", -1)
		if defender.affinity == _a1 or defender.affinity == _a2:
			if not _silent_mode:
				attacker.one_use_atk_boost_used = true
			result.ability_triggered_attacker = true
			result.defender_destroyed = true
			result.defender_crystal_loss = 0  # no crystal loss to defender
			result.messages.append("%s: once-per-card destroy of %s!" % [attacker.card_name, defender.card_name])
			_apply_post_attack_effects(attacker, result)
			return

	# COIN_FLIP_NULLIFY_ON_DEFEND: Keeper of the Afterlife — flip coin; heads = nullify attack
	if defender.ability_type == CharacterData.AbilityType.COIN_FLIP_NULLIFY_ON_DEFEND:
		result.ability_triggered_defender = true
		set_coin_flip_source(defender, defender_player)
		var _nullify_heads: bool = _roll_battle_coin()
		clear_coin_flip_source()
		_battle_coin_results.append(_nullify_heads)
		if _nullify_heads:
			result.messages.append("%s coin flip: heads — attack nullified!" % defender.card_name)
			return  # no destruction, no damage
		else:
			result.messages.append("%s coin flip: tails — attack proceeds normally." % defender.card_name)

	# Dungeon: Divine Triumph / Chaos Triumph — force outcome between Divine and Chaos
	# If both are active simultaneously they cancel out.
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON:
		var _tri_mods: Array = GameState.active_dungeon_modifiers
		var _has_div_tri: bool = "divine_triumph" in _tri_mods
		var _has_chao_tri: bool = "chaos_triumph" in _tri_mods
		if _has_div_tri != _has_chao_tri:
			const _DIVINE_AFF: int = 0
			const _CHAOS_AFF: int  = 1
			if _has_div_tri:
				if attacker.affinity == _DIVINE_AFF and defender.affinity == _CHAOS_AFF:
					result.defender_destroyed = true
					result.defender_crystal_loss = defender.crystal_cost
					result.messages.append("Divine Triumph: %s conquers Chaos!" % attacker.card_name)
					_apply_post_attack_effects(attacker, result)
					return
				elif attacker.affinity == _CHAOS_AFF and defender.affinity == _DIVINE_AFF:
					result.attacker_destroyed = true
					result.attacker_crystal_loss = attacker.crystal_cost
					result.messages.append("Divine Triumph: Divine resists Chaos!")
					_apply_defend_effects(defender, attacker, result, defender_player)
					return
			if _has_chao_tri:
				if attacker.affinity == _CHAOS_AFF and defender.affinity == _DIVINE_AFF:
					result.defender_destroyed = true
					result.defender_crystal_loss = defender.crystal_cost
					result.messages.append("Chaos Triumph: %s conquers Divine!" % attacker.card_name)
					_apply_post_attack_effects(attacker, result)
					return
				elif attacker.affinity == _DIVINE_AFF and defender.affinity == _CHAOS_AFF:
					result.attacker_destroyed = true
					result.attacker_crystal_loss = attacker.crystal_cost
					result.messages.append("Chaos Triumph: Chaos resists Divine!")
					_apply_defend_effects(defender, attacker, result, defender_player)
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

	# "When this card defends" — fire regardless of battle outcome (win/loss/tie).
	_apply_on_defend_triggers(defender, attacker, result, defender_player)

	# IMMUNE_DESTROY_BY_NON_UNION: only union attackers can destroy this defender
	if result.defender_destroyed and defender.is_union \
			and defender.ability_type == CharacterData.AbilityType.IMMUNE_DESTROY_BY_NON_UNION \
			and not attacker.is_union:
		result.defender_destroyed = false
		result.defender_crystal_loss = 0
		result.destruction_blocked_defender = true
		result.messages.append("%s: only a Union card can destroy %s!" % [attacker.card_name, defender.card_name])

	# IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP: Helios — cannot be destroyed while another own card of same affinity is face-up
	if result.defender_destroyed and defender.ability_type == CharacterData.AbilityType.IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP:
		var _immune_aff: int = defender.ability_params.get("affinity", -1)
		for _im_r in range(GameState.GRID_SIZE):
			for _im_c in range(GameState.GRID_SIZE):
				var _im_card: GameState.CardInstance = GameState.grids[defender_player][_im_r][_im_c]
				if _im_card == defender or not _im_card.face_up or _im_card.card_type != "character":
					continue
				if _im_card.affinity == _immune_aff:
					result.defender_destroyed = false
					result.defender_crystal_loss = 0
					result.destruction_blocked_defender = true
					result.messages.append("%s: protected by another %s ally!" % [
						defender.card_name, CharacterData.Affinity.keys()[_immune_aff]])
					result.ability_triggered_defender = true
					break

	# Lab Bloater Mutagen effect (overrides normal if defender survives)
	if defender.has_mutagen_flag \
			and defender.ability_type == CharacterData.AbilityType.MUTAGEN_DESTROY_ATTACKER:
		result.ability_triggered_defender = true
		if defender.ability_params.get("both_pay_no_cost", false):
			result.attacker_destroyed = true
			result.defender_destroyed = true
			result.attacker_crystal_loss = 0
			result.defender_crystal_loss = 0
			result.messages.append("Lab Bloater Mutagen: Both units destroyed — no crystal cost!")
		elif not result.defender_destroyed:
			result.attacker_destroyed = true
			result.attacker_crystal_loss = attacker.crystal_cost
			result.defender_crystal_loss = 0  # no crystal loss for bloater
			result.messages.append("Lab Bloater Mutagen: Attacker destroyed!")

	# Venom Toad: destroy foe with venom flag during reckoning
	_apply_venom_toad_reckoning_destroy(attacker, defender, result)

	# Pit Lord: destroyed after Reckoning with Divine regardless of role or outcome.
	_apply_destroy_after_divine_battle(attacker, defender, result)

# ─────────────────────────────────────────────────────────────
# Divine battle ability helpers
# ─────────────────────────────────────────────────────────────
static func _apply_pre_battle_perm_debuffs(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		_attacker_player: int,
		_defender_player: int,
		result: BattleResult
) -> void:
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers:
		return
	for _pb_src: GameState.CardInstance in [attacker, defender]:
		if _pb_src.card_type != "character":
			continue
		if _pb_src.ability_type != CharacterData.AbilityType.PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY:
			continue
		var _pb_aff: int = _pb_src.ability_params.get("affinity", -1)
		var _pb_def_loss: int = _pb_src.ability_params.get("def", 5)
		var _pb_foe: GameState.CardInstance = defender if _pb_src == attacker else attacker
		if _pb_foe.card_type != "character" or _pb_foe.affinity != _pb_aff:
			continue
		_pb_foe.current_def = max(0, _pb_foe.current_def - _pb_def_loss)
		result.messages.append("%s: %s permanently loses %d DEF before Reckoning!" % [
			_pb_src.card_name, _pb_foe.card_name, _pb_def_loss])

static func _try_destroy_self_vs_divine_before_calc(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		result: BattleResult
) -> bool:
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers:
		return false
	if defender.affinity == CharacterData.Affinity.DIVINE \
			and attacker.ability_type == CharacterData.AbilityType.DESTROY_SELF_VS_DIVINE_BOTH:
		result.ability_triggered_attacker = true
		result.attacker_destroyed = true
		result.attacker_crystal_loss = attacker.crystal_cost
		result.messages.append("%s is destroyed battling Divine!" % attacker.card_name)
		return true
	if attacker.affinity == CharacterData.Affinity.DIVINE \
			and defender.ability_type == CharacterData.AbilityType.DESTROY_SELF_VS_DIVINE_BOTH:
		result.ability_triggered_defender = true
		result.defender_destroyed = true
		result.defender_crystal_loss = defender.crystal_cost
		result.messages.append("%s is destroyed battling Divine!" % defender.card_name)
		return true
	return false


static func _apply_venom_toad_reckoning_destroy(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		result: BattleResult
) -> void:
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers:
		return
	if attacker.ability_type == CharacterData.AbilityType.VENOM_TOAD_RECKONING \
			and defender.card_type == "character" \
			and "venom" in defender.flags:
		result.ability_triggered_attacker = true
		result.defender_destroyed = true
		result.defender_crystal_loss = defender.crystal_cost
		result.messages.append("Venom Toad: %s destroyed by venom!" % defender.card_name)
	elif defender.ability_type == CharacterData.AbilityType.VENOM_TOAD_RECKONING \
			and attacker.card_type == "character" \
			and "venom" in attacker.flags:
		result.ability_triggered_defender = true
		result.attacker_destroyed = true
		result.attacker_crystal_loss = attacker.crystal_cost
		result.messages.append("Venom Toad: %s destroyed by venom!" % attacker.card_name)


static func _apply_destroy_after_divine_battle(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		result: BattleResult
) -> void:
	if _silent_mode:
		return
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers:
		return
	var _divine_battle: bool = attacker.affinity == CharacterData.Affinity.DIVINE \
			or defender.affinity == CharacterData.Affinity.DIVINE
	if not _divine_battle:
		return
	if attacker.ability_type == CharacterData.AbilityType.DESTROYED_IF_BATTLES_DIVINE \
			and not result.attacker_destroyed:
		result.ability_triggered_attacker = true
		result.attacker_destroyed = true
		result.attacker_crystal_loss = attacker.crystal_cost
		result.messages.append("%s is destroyed by Divine!" % attacker.card_name)
	if defender.ability_type == CharacterData.AbilityType.DESTROYED_IF_BATTLES_DIVINE \
			and not result.defender_destroyed:
		result.ability_triggered_defender = true
		result.defender_destroyed = true
		result.defender_crystal_loss = defender.crystal_cost
		result.messages.append("%s is destroyed by Divine!" % defender.card_name)


static func _apply_attacker_battle_drain(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		result: BattleResult
) -> bool:
	if not attacker.ability_params.has("drain_atk") and not attacker.ability_params.has("drain_def"):
		return false
	var drain_atk: int = int(attacker.ability_params.get("drain_atk", 0))
	var drain_def: int = int(attacker.ability_params.get("drain_def", drain_atk))
	if drain_atk <= 0 and drain_def <= 0:
		return false
	if _silent_mode:
		return false
	result.ability_triggered_attacker = true
	defender.current_atk = max(0, defender.current_atk - drain_atk)
	defender.current_def = max(0, defender.current_def - drain_def)
	attacker.current_atk += drain_atk
	attacker.current_def += drain_def
	result.messages.append("%s drains %d ATK & %d DEF from %s!" % [
		attacker.card_name, drain_atk, drain_def, defender.card_name])
	return true

# ─────────────────────────────────────────────────────────────
# Trap Resolution (returns special trigger for complex effects)
# ─────────────────────────────────────────────────────────────
static func apply_swap_atk_def_when_attacking(attacker: GameState.CardInstance) -> void:
	if attacker.card_type != "character":
		return
	if attacker.ability_type != CharacterData.AbilityType.SWAP_ATK_DEF_WHEN_ATTACKING:
		return
	var tmp: int = attacker.current_atk
	attacker.current_atk = attacker.current_def
	attacker.current_def = tmp


static func _resolve_trap(
		attacker: GameState.CardInstance,
		trap: GameState.CardInstance,
		attacker_player: int,
		_defender_player: int,
		dice_roll: int,
		defender_was_exposed: bool,
		target_pos: Vector2i,
		result: BattleResult
) -> void:
	var trap_data = CardDatabase.get_trap(trap.card_name) as TrapData
	if trap_data == null:
		result.messages.append("Unknown trap: %s" % trap.card_name)
		return

	_populate_attacker_reckoning_fields(
		attacker, trap, dice_roll, attacker_player, defender_was_exposed, target_pos, result)

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
		if not _silent_mode:
			attacker.current_def = max(0, attacker.current_def - 20)
			result.messages.append("%s permanently loses 20 DEF from trap attack!" % attacker.card_name)
		result.special_trigger = "trap_nullified"
		return

	# Trap crystal loss to trap owner (defender pays trap cost); apply dungeon discounts
	var _tc_eff: int = trap_data.crystal_cost
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON:
		var _tc_mods: Array = GameState.active_dungeon_modifiers
		if "trap_broker" in _tc_mods: _tc_eff = 0
		elif "trap_dealer" in _tc_mods: _tc_eff = int(_tc_eff * 0.5)
	result.defender_crystal_loss = _tc_eff
	result.special_trigger = "trap_effect"
	result.special_params = {"trap_name": trap.card_name, "trap_data": trap_data,
		"attacker_player": attacker_player}

# ─────────────────────────────────────────────────────────────
# ATK / DEF Calculation
# ─────────────────────────────────────────────────────────────
static func _average_field_atk_def(player: int) -> Dictionary:
	var sum_atk: int = 0
	var sum_def: int = 0
	var count: int = 0
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character":
				sum_atk += card.get_effective_atk()
				sum_def += card.get_effective_def()
				count += 1
	if count <= 0:
		return {"atk": 0, "def": 0}
	return {"atk": int(sum_atk / count), "def": int(sum_def / count)}

static func _populate_attacker_reckoning_fields(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		dice_roll: int,
		attacker_player: int,
		defender_was_exposed: bool,
		target_pos: Vector2i,
		result: BattleResult) -> void:
	var pill_atk: int = attacker.get_effective_atk()
	var pill_def: int = attacker.get_effective_def()
	result.attacker_pill_atk = pill_atk
	result.attacker_pill_def = pill_def
	var used_atk: int = pill_atk
	if defender.card_type == "character":
		used_atk = _get_effective_atk(
			attacker, defender, dice_roll, attacker_player, target_pos, defender_was_exposed)
	else:
		used_atk = _get_effective_atk_for_non_unit_target(
			attacker, dice_roll, attacker_player, target_pos)
	result.attacker_atk_used = used_atk
	result.attacker_atk_delta = used_atk - pill_atk


## Attack-only ATK modifiers for trap / dead-end reckoning (no defender unit to compare).
static func _get_effective_atk_for_non_unit_target(
		attacker: GameState.CardInstance,
		dice_roll: int,
		attacker_player: int,
		target_pos: Vector2i) -> int:
	var atk: int = attacker.get_effective_atk()
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers:
		var _bhb_mods: Array = GameState.active_dungeon_modifiers
		if "offensive_game" in _bhb_mods:
			atk += 5
		return atk
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "offensive_game" in GameState.active_dungeon_modifiers:
		atk += 5
	match attacker.ability_type:
		CharacterData.AbilityType.ATTACK_STANCE_BOOST:
			atk += attacker.ability_params.get("atk", attacker.ability_params.get("atk_bonus", 0))
		CharacterData.AbilityType.ONE_USE_ATK_BOOST:
			if not attacker.one_use_atk_boost_used:
				atk += attacker.ability_params.get("bonus", 0)
		CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND:
			if not attacker.one_use_atk_boost_used:
				atk += attacker.ability_params.get("atk_bonus", attacker.ability_params.get("atk", 0))
		CharacterData.AbilityType.ATK_BONUS_VS_CENTER_ZONE:
			if target_pos.x >= 0:
				var in_center_zone: bool = (target_pos.x >= 1 and target_pos.x <= 3
					and target_pos.y >= 1 and target_pos.y <= 3)
				var in_very_center: bool = (target_pos.x == 2 and target_pos.y == 2)
				if in_center_zone:
					atk += attacker.ability_params.get("zone_bonus", 20)
				if in_very_center:
					atk += attacker.ability_params.get("center_bonus", 40)
		CharacterData.AbilityType.STANCE_FIXED_STATS:
			atk = attacker.ability_params.get("atk_atk", 60)
	if attacker.has_mutagen_flag:
		atk += attacker.ability_params.get("mutagen_atk", 0)
	return atk


static func _get_effective_atk(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		dice_roll: int,
		attacker_player: int,
		target_pos: Vector2i = Vector2i(-1, -1),
		defender_was_exposed: bool = false
) -> int:
	var atk: int = attacker.get_effective_atk()
	set_coin_flip_source(attacker, attacker_player)

	# Bare Hands Brawling: character abilities are cancelled
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers:
		# Still apply dungeon modifiers that aren't card-ability based
		var _bhb_mods: Array = GameState.active_dungeon_modifiers
		if "offensive_game" in _bhb_mods: atk += 5
		return atk

	# Dungeon: Offensive Game (+5 ATK for attacker) and Arcane Triumph (+20% vs non-Arcane)
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON:
		var _dm: Array = GameState.active_dungeon_modifiers
		if "offensive_game" in _dm:
			atk += 5
		if "arcane_triumph" in _dm \
				and attacker.affinity == CharacterData.Affinity.ARCANE \
				and defender.affinity != CharacterData.Affinity.ARCANE:
			atk = int(atk * 1.2)

	if defender.ability_type == CharacterData.AbilityType.AVERAGE_FOE_STATS_IN_RECKONING \
			and attacker_player >= 0:
		var _avg_atk: Dictionary = _average_field_atk_def(attacker_player)
		atk = int(_avg_atk.get("atk", atk))

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

		CharacterData.AbilityType.ATK_BONUS_IF_TECH_PLAYED:
			var _tech_needed: String = attacker.ability_params.get("tech_name", "")
			if _tech_needed != "" \
					and GameState.void_contains_card(attacker_player, _tech_needed, "tech"):
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_BOOST_VS_REVEALED:
			if defender_was_exposed:
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_BONUS_VS_FACEDOWN:
			if not defender_was_exposed:
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_BONUS_VS_UNION:
			if defender.is_union:
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_BONUS_VS_VENOM:
			if "venom" in defender.flags:
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_DEF_BONUS_VS_VENOM:
			if "venom" in defender.flags:
				atk += attacker.ability_params.get("atk", 0)
			if "venom" in attacker.flags:
				atk += attacker.ability_params.get("self_venom_atk", 0)

		CharacterData.AbilityType.ATK_DEF_BONUS_VS_NON_AFFINITY:
			var _non_aff: int = attacker.ability_params.get("affinity", -2)
			if _non_aff == -2 or defender.affinity != _non_aff:
				atk += attacker.ability_params.get("atk", attacker.ability_params.get("bonus", 0))

		CharacterData.AbilityType.ATK_BONUS_IF_AFFINITY_ON_FIELD:
			var needed_aff: int = attacker.ability_params.get("affinity", -1)
			for p: int in _field_players(attacker_player, attacker.ability_params):
				var found := false
				for r in range(GameState.GRID_SIZE):
					for c in range(GameState.GRID_SIZE):
						var ally: GameState.CardInstance = GameState.grids[p][r][c]
						if ally == attacker:
							continue
						if ally.card_type == "character" and ally.face_up and ally.affinity == needed_aff:
							atk += attacker.ability_params.get("atk", attacker.ability_params.get("bonus", 0))
							found = true
							break
					if found:
						break
				if found:
					break

		CharacterData.AbilityType.ATK_DEF_BONUS_IF_UNION_ON_FIELD:
			for r in range(GameState.GRID_SIZE):
				for c in range(GameState.GRID_SIZE):
					var ally: GameState.CardInstance = GameState.grids[attacker_player][r][c]
					if ally.is_union and ally.face_up:
						atk += attacker.ability_params.get("atk", 0)
						break

		CharacterData.AbilityType.ATTACK_STANCE_BOOST:
			atk += attacker.ability_params.get("atk", attacker.ability_params.get("atk_bonus", 0))

		CharacterData.AbilityType.COIN_FLIP_ATK_BOOST:
			var _cfab_heads: bool = _roll_battle_coin()
			_battle_coin_results.append(_cfab_heads)
			if _cfab_heads:
				atk += attacker.ability_params.get("bonus", 0)
				GameState.post_message("%s coin flip: heads! +%d ATK" % [attacker.card_name, attacker.ability_params.get("bonus", 0)])
			else:
				GameState.post_message("%s coin flip: tails — no bonus." % attacker.card_name)

		CharacterData.AbilityType.COIN_FLIP_ATK_DEF_BOOST:
			var _cfadb_heads: bool = _roll_battle_coin()
			_battle_coin_results.append(_cfadb_heads)
			var _cfadb_bonus: int = attacker.ability_params.get("bonus", 0)
			if _cfadb_heads:
				atk += _cfadb_bonus
				if not _silent_mode:
					attacker.temp_def_bonus += _cfadb_bonus
				GameState.post_message("%s coin flip: heads! +%d ATK & DEF this turn!" % [attacker.card_name, _cfadb_bonus])
			else:
				GameState.post_message("%s coin flip: tails — no bonus." % attacker.card_name)

		CharacterData.AbilityType.END_OF_TURN_COIN_FLIP_STAT_BOOST:
			if attacker.ability_params.get("in_reckoning", false):
				var _rc_flips: int = maxi(1, int(attacker.ability_params.get("coin_flips", 1)))
				var _rc_heads: int = 0
				var _rc_tails: int = 0
				for _rc_i in range(_rc_flips):
					var _rc_h: bool = _roll_battle_coin()
					_battle_coin_results.append(_rc_h)
					if _rc_h:
						_rc_heads += 1
					else:
						_rc_tails += 1
				if attacker.ability_params.get("per_head_atk", false):
					var _rc_atk: int = int(attacker.ability_params.get("atk", 5)) * _rc_heads
					atk += _rc_atk
					if attacker.ability_params.get("per_tail_def", false):
						var _rc_def: int = int(attacker.ability_params.get("def", 5)) * _rc_tails
						if not _silent_mode:
							attacker.temp_def_bonus += _rc_def
						GameState.post_message("%s: %d heads +%d ATK, %d tails +%d DEF (Reckoning)!" % [
							attacker.card_name, _rc_heads, _rc_atk, _rc_tails, _rc_def])
				elif attacker.ability_params.get("all_tails_penalty", false) and _rc_tails == _rc_flips:
					var _pen: int = int(attacker.ability_params.get("penalty_atk_def", 15))
					atk = max(0, atk - _pen)
					if not _silent_mode:
						attacker.temp_def_bonus -= _pen
					GameState.post_message("%s: All tails — -%d ATK&DEF!" % [attacker.card_name, _pen])
				elif attacker.ability_params.get("heads_atk", false) and _rc_heads > 0:
					var _ha: int = int(attacker.ability_params.get("atk", 50))
					atk += _ha
					GameState.post_message("%s: Heads — +%d ATK permanently!" % [attacker.card_name, _ha])

		CharacterData.AbilityType.TEMP_ATK_HALF_TARGET:
			var _half_atk: int = int(defender.get_effective_atk() / 2)
			atk += _half_atk
			GameState.post_message("%s: +%d ATK (half of %s's ATK)" % [attacker.card_name, _half_atk, defender.card_name])

		CharacterData.AbilityType.ONE_USE_ATK_BOOST:
			if not attacker.one_use_atk_boost_used:
				atk += attacker.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND:
			if not attacker.one_use_atk_boost_used:
				atk += attacker.ability_params.get("atk_bonus", attacker.ability_params.get("atk", 0))

		CharacterData.AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES:
			if attacker.has_mutagen_flag:
				var affinities = attacker.ability_params.get("affinities", [])
				if affinities.is_empty() or defender.affinity in affinities:
					atk += attacker.ability_params.get("atk", attacker.ability_params.get("bonus", 0))

		CharacterData.AbilityType.ATK_BONUS_VS_CENTER_ZONE:
			if target_pos.x >= 0:
				var in_center_zone: bool = (target_pos.x >= 1 and target_pos.x <= 3
					and target_pos.y >= 1 and target_pos.y <= 3)
				var in_very_center: bool = (target_pos.x == 2 and target_pos.y == 2)
				if in_center_zone:
					atk += attacker.ability_params.get("zone_bonus", 20)
				if in_very_center:
					atk += attacker.ability_params.get("center_bonus", 40)

		CharacterData.AbilityType.DOUBLE_STATS_VS_AFFINITY:
			if defender.affinity == attacker.ability_params.get("affinity", -1):
				atk = attacker.get_effective_atk() * 2

		CharacterData.AbilityType.STANCE_FIXED_STATS:
			atk = attacker.ability_params.get("atk_atk", 60)

		CharacterData.AbilityType.ATK_DEF_BONUS_IF_OWN_REVEALED_GTE:
			var _rev_count: int = 0
			for _r in range(GameState.GRID_SIZE):
				for _c in range(GameState.GRID_SIZE):
					var _cell: GameState.CardInstance = GameState.grids[attacker_player][_r][_c]
					if _cell.face_up and _cell.card_type != "dead_end":
						_rev_count += 1
			if attacker.ability_params.get("per_revealed", false):
				atk += _rev_count * attacker.ability_params.get("atk", 10)
			elif _rev_count >= attacker.ability_params.get("min_revealed", 15):
				atk += attacker.ability_params.get("atk", 100)

		CharacterData.AbilityType.ATK_BONUS_WHEN_CAN_DESTROY:
			var _base_def: int = defender.get_effective_def()
			if atk > _base_def:
				atk += int(attacker.ability_params.get("bonus", 0))

		CharacterData.AbilityType.ATK_BONUS_UNION_ZONE_PATTERN:
			if target_pos.x >= 0 and attacker.is_union:
				var _ud: UnionData = UnionDatabase.get_union(attacker.card_name)
				if _ud != null and _target_in_union_zone(attacker.grid_row, attacker.grid_col, target_pos, _ud.union_zone):
					atk += int(attacker.ability_params.get("bonus", 0))

		CharacterData.AbilityType.BOOST_PER_FIELD_UNIT:
			var _unit_count: int = 0
			for _bp in range(2):
				for _br in range(GameState.GRID_SIZE):
					for _bc in range(GameState.GRID_SIZE):
						if GameState.get_card(_bp, _br, _bc).card_type == "character":
							_unit_count += 1
			var _bpf_atk: int = int(attacker.ability_params.get("atk", 0)) * _unit_count
			atk += _bpf_atk

		CharacterData.AbilityType.NOT_IMPLEMENTED:
			GameState.show_center_message("Ability not implemented: " + attacker.card_name)

	# FIELD_ATK_BOOST_OWN_AFFINITY is applied via calculate_field_bonuses() → field_aura_atk_bonus.

	if attacker.has_mutagen_flag:
		atk += attacker.ability_params.get("mutagen_atk", 0)

	# Check defender abilities that debuff attacker ATK
	if defender.ability_type == CharacterData.AbilityType.ATTACKER_ATK_DEBUFF:
		if defender.effect_nullified_until == 0 or defender.effect_nullified_until < GameState.turn_number:
			var debuff_amount: int = defender.ability_params.get("atk", defender.ability_params.get("amount", 0))
			atk = max(0, atk - debuff_amount)
			if not BattleResolver._silent_mode:
				GameState.post_message("%s: Attacker loses %d ATK!" % [defender.card_name, debuff_amount])

	# Nullified effect — restore base ATK
	if attacker.effect_nullified_until >= GameState.turn_number:
		atk = attacker.get_effective_atk()

	clear_coin_flip_source()
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
		var _bhb_mods2: Array = GameState.active_dungeon_modifiers
		if "defensive_game" in _bhb_mods2: def_val += 5
		return def_val

	# Dungeon: Defensive Game (+5 DEF for defender) and Arcane Triumph (+20% DEF vs non-Arcane)
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON:
		var _dm2: Array = GameState.active_dungeon_modifiers
		if "defensive_game" in _dm2:
			def_val += 5
		if "arcane_triumph" in _dm2 \
				and defender.affinity == CharacterData.Affinity.ARCANE \
				and attacker.affinity != CharacterData.Affinity.ARCANE:
			def_val = int(def_val * 1.2)

	if attacker.ability_type == CharacterData.AbilityType.AVERAGE_FOE_STATS_IN_RECKONING \
			and defender_player >= 0:
		var _def_avg: Dictionary = _average_field_atk_def(defender_player)
		def_val = int(_def_avg.get("def", def_val))

	match defender.ability_type:
		CharacterData.AbilityType.DEF_BONUS_VS_AFFINITY:
			if attacker.affinity == defender.ability_params.get("affinity", -1):
				def_val += defender.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY:
			if attacker.affinity == defender.ability_params.get("affinity", -1):
				def_val += defender.ability_params.get("def", 0)

		CharacterData.AbilityType.ATK_DEF_BONUS_VS_VENOM:
			if "venom" in attacker.flags:
				def_val += defender.ability_params.get("def", 0)

		CharacterData.AbilityType.ATK_DEF_BONUS_VS_NON_AFFINITY:
			var _non_aff_d: int = defender.ability_params.get("affinity", -2)
			if _non_aff_d == -2 or attacker.affinity != _non_aff_d:
				def_val += defender.ability_params.get("def", defender.ability_params.get("bonus", 0))

		CharacterData.AbilityType.ONE_USE_DEF_BOOST:
			if not defender.one_use_def_boost_used:
				def_val += defender.ability_params.get("bonus", 0)

		CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND:
			if not defender.one_use_def_boost_used:
				def_val += defender.ability_params.get("def_bonus", defender.ability_params.get("def", 0))

		CharacterData.AbilityType.DEFENSE_STANCE_BOOST:
			def_val += defender.ability_params.get("def", defender.ability_params.get("def_bonus", 0))

		CharacterData.AbilityType.DEF_BONUS_IF_AFFINITY_ON_FIELD:
			if defender_player >= 0:
				var needed_aff: int = defender.ability_params.get("affinity", -1)
				var bonus_applied := false
				for p: int in _field_players(defender_player, defender.ability_params):
					for r in range(GameState.GRID_SIZE):
						for c in range(GameState.GRID_SIZE):
							var field_card: GameState.CardInstance = GameState.grids[p][r][c]
							if field_card == defender:
								continue
							if field_card.card_type == "character" and field_card.face_up \
									and field_card.affinity == needed_aff:
								def_val += defender.ability_params.get("def", defender.ability_params.get("bonus", 0))
								bonus_applied = true
								break
						if bonus_applied:
							break
					if bonus_applied:
						break

		CharacterData.AbilityType.DOUBLE_STATS_VS_AFFINITY:
			if attacker.affinity == defender.ability_params.get("affinity", -1):
				def_val = defender.get_effective_def() * 2

		CharacterData.AbilityType.STANCE_FIXED_STATS:
			def_val = defender.ability_params.get("def_def", 60)

		CharacterData.AbilityType.ATK_DEF_BONUS_IF_OWN_REVEALED_GTE:
			if defender_player >= 0:
				var _rev_d: int = 0
				for _r in range(GameState.GRID_SIZE):
					for _c in range(GameState.GRID_SIZE):
						var _cell: GameState.CardInstance = GameState.grids[defender_player][_r][_c]
						if _cell.face_up and _cell.card_type != "dead_end":
							_rev_d += 1
				if defender.ability_params.get("per_revealed", false):
					def_val += _rev_d * defender.ability_params.get("def", 10)
				elif _rev_d >= defender.ability_params.get("min_revealed", 15):
					def_val += defender.ability_params.get("def", 100)

		CharacterData.AbilityType.BOOST_PER_FIELD_UNIT:
			var _unit_count_d: int = 0
			for _bp in range(2):
				for _br in range(GameState.GRID_SIZE):
					for _bc in range(GameState.GRID_SIZE):
						if GameState.get_card(_bp, _br, _bc).card_type == "character":
							_unit_count_d += 1
			def_val += int(defender.ability_params.get("def", 0)) * _unit_count_d
			var _pen_aff_name: String = str(defender.ability_params.get("def_penalty_vs_affinity", ""))
			if _pen_aff_name != "" and attacker.affinity == CharacterData.Affinity.get(_pen_aff_name, -99):
				def_val = max(0, def_val - int(defender.ability_params.get("def_penalty", 0)))

		CharacterData.AbilityType.COIN_FLIP_NULLIFY_ON_DEFEND:
			# Handled directly in _resolve_character_vs_character before ATK vs DEF comparison
			pass

		CharacterData.AbilityType.NOT_IMPLEMENTED:
			GameState.show_center_message("Ability not implemented: " + defender.card_name)

	# DEF_PENALTY_VS_NON_AFFINITY (Gamma Mermaid): attacker reduces non-matching defender DEF
	if attacker.ability_type == CharacterData.AbilityType.DEF_PENALTY_VS_NON_AFFINITY:
		var _ap_aff: int = attacker.ability_params.get("affinity", -1)
		if _ap_aff == -1 or defender.affinity != _ap_aff:
			var _ap_amt: int = attacker.ability_params.get("def", 20)
			def_val = max(0, def_val - _ap_amt)
			if not BattleResolver._silent_mode:
				GameState.post_message("%s: -%d DEF vs non-%s defender!" % [
					attacker.card_name, _ap_amt, CharacterData.Affinity.keys()[_ap_aff]])

	# Death Cobra aura: foe units with venom get -50 DEF while Death Cobra is on field
	if defender_player >= 0 and "venom" in defender.flags:
		def_val = max(0, def_val - _death_cobra_venom_def_penalty(defender_player))

	return def_val

static func _death_cobra_venom_def_penalty(defender_player: int) -> int:
	for p: int in range(2):
		if p == defender_player:
			continue
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.grids[p][r][c]
				if card.card_type == "character" and card.face_up \
						and card.ability_type == CharacterData.AbilityType.VENOM_FLAG_END_OF_TURN:
					return 50
	return 0

static func _apply_post_attack_effects(
		attacker: GameState.CardInstance,
		_result: BattleResult
) -> void:
	if _silent_mode:
		return
	# Pit Lord: halve stats after attacking (skip during silent preview — avoids permanent mutation)
	var also_halve: bool = attacker.ability_params.get("also_halve_after_attack", false)
	if attacker.ability_type == CharacterData.AbilityType.HALVE_STATS_AFTER_ATTACK or also_halve:
		attacker.halve_stats()


static func _spend_one_use_defense_boosts(
		defender: GameState.CardInstance,
		result: BattleResult
) -> void:
	if defender.one_use_def_boost_used:
		return
	match defender.ability_type:
		CharacterData.AbilityType.ONE_USE_DEF_BOOST, \
		CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND:
			defender.one_use_def_boost_used = true
			result.ability_triggered_defender = true


static func _apply_on_defend_triggers(
		defender: GameState.CardInstance,
		attacker: GameState.CardInstance,
		result: BattleResult,
		_defender_player: int
) -> void:
	# Bare Hands Brawling: character abilities are cancelled
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers:
		return
	var mutate: bool = not _silent_mode
	match defender.ability_type:
		CharacterData.AbilityType.ONE_USE_PERM_DEBUFF_ATTACKER_ATK:
			if not defender.one_use_def_boost_used:
				result.ability_triggered_defender = true
				if mutate:
					defender.one_use_def_boost_used = true
					var _debuff_atk: int = defender.ability_params.get(
							"atk", defender.ability_params.get("amount", 0))
					attacker.current_atk = max(0, attacker.current_atk - _debuff_atk)
				result.messages.append("%s: %s permanently loses %d ATK!" % [
					defender.card_name, attacker.card_name,
					defender.ability_params.get("atk", defender.ability_params.get("amount", 0))])

		CharacterData.AbilityType.DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF:
			result.ability_triggered_defender = true
			var _debuff_a: int = defender.ability_params.get("atk", defender.ability_params.get("amount", 0))
			var _debuff_d: int = defender.ability_params.get("def", _debuff_a)
			if mutate:
				attacker.current_atk = max(0, attacker.current_atk - _debuff_a)
				attacker.current_def = max(0, attacker.current_def - _debuff_d)
			result.messages.append("%s: %s permanently loses %d ATK and DEF!" % [
				defender.card_name, attacker.card_name, _debuff_a])


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
	var mutate: bool = not _silent_mode
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
		CharacterData.AbilityType.ONE_USE_DEF_BOOST, \
		CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND:
			pass  # spent in _spend_one_use_defense_boosts when attacked

		CharacterData.AbilityType.PERM_DEF_BOOST_ON_DEFEND:
			result.ability_triggered_defender = true
			var _perm_def: int = defender.ability_params.get("def", defender.ability_params.get("bonus", 0))
			if mutate:
				defender.current_def += _perm_def
			result.messages.append("%s gains +%d DEF permanently!" % [defender.card_name, _perm_def])

		CharacterData.AbilityType.ONE_USE_DEFEND_MORPH:
			if not defender.one_use_def_boost_used:
				result.ability_triggered_defender = true
				if mutate:
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
				if mutate:
					defender.one_use_def_boost_used = true
					var def_debuff: int = defender.ability_params.get("def_amount", 5)
					defender.current_def = max(0, defender.current_def - def_debuff)
					result.messages.append("%s: permanently -%d DEF from defending." % [
						defender.card_name, def_debuff])

		CharacterData.AbilityType.HALVE_ATK_ADD_TO_DEF_ON_DEFEND:
			result.ability_triggered_defender = true
			var _halved: int = defender.current_atk / 2
			if mutate:
				defender.current_atk = max(0, defender.current_atk - _halved)
				defender.current_def += _halved
			result.messages.append("%s: halved ATK, -%d ATK +%d DEF permanently!" % [
				defender.card_name, _halved, _halved])

		CharacterData.AbilityType.LOCK_ATTACKER_ON_DEFEND:
			if not result.defender_destroyed:
				result.ability_triggered_defender = true
				if mutate:
					attacker.cannot_attack_until = GameState.turn_number + 2
				result.messages.append("%s: %s cannot attack until end of next turn!" % [
					defender.card_name, attacker.card_name])

# ─────────────────────────────────────────────────────────────
# Field scope — ability_params.field_scope (see CONTENT_EDITING_GUIDE.md)
#
# Text rule: bare "on the field" (no possessive) → scope "all" (both players).
# "its side", "your field", "their own field", etc. → scope "owner" (default).
#
# Values: "owner" (default) | "all" (aliases: global, both, field)
# Handler: _field_players() — used by field-count / field-presence abilities.
# ─────────────────────────────────────────────────────────────
static func _field_players(owner_player: int, ability_params: Dictionary) -> Array:
	var scope := str(ability_params.get("field_scope", "owner")).to_lower()
	if scope in ["all", "global", "both", "field"]:
		return [0, 1]
	if owner_player < 0:
		return []
	return [owner_player]

static func _apply_per_field_count_bonus(
		card: GameState.CardInstance,
		count: int
) -> void:
	var atk_bonus: int = card.ability_params.get("atk_bonus", 0) * count
	var def_bonus: int = card.ability_params.get("def_bonus", 0) * count
	var cap: int = int(card.ability_params.get("bonus_cap", -1))
	if cap >= 0:
		atk_bonus = mini(atk_bonus, cap)
		def_bonus = mini(def_bonus, cap)
	card.perm_atk_bonus = atk_bonus
	card.perm_def_bonus = def_bonus

# ─────────────────────────────────────────────────────────────
# Field-based stat calculation (called before each battle and when field composition changes)
# ─────────────────────────────────────────────────────────────
static func recalculate_all_field_bonuses() -> void:
	calculate_field_bonuses(0)
	calculate_field_bonuses(1)
	_apply_venom_queen_global_debuff()
	GameState.emit_signal("field_bonuses_recalculated")

static func calculate_field_bonuses(player_index: int) -> void:
	# Clear aura bonuses, then rebuild from current face-up field state.
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.grids[player_index][r][c]
			if card.card_type == "character":
				card.field_aura_atk_bonus = 0
				card.field_aura_def_bonus = 0

	var all_chars := GameState.get_all_characters(player_index)
	for entry in all_chars:
		var card: GameState.CardInstance = entry["card"]
		_apply_field_ability_bonus(card, player_index)

	_apply_field_aura_bonuses(player_index)

static func _apply_field_aura_bonuses(player_index: int) -> void:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var source: GameState.CardInstance = GameState.grids[player_index][r][c]
			if source.card_type != "character" or not source.face_up:
				continue
			if source.ability_type == CharacterData.AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY:
				var target_affinity: int = source.ability_params.get("affinity", -1)
				var name_filter: String = str(source.ability_params.get("name_contains", "")).to_lower()
				var atk_boost: int = source.ability_params.get("atk", 0)
				if atk_boost != 0 and (target_affinity >= 0 or not name_filter.is_empty()):
					for r2 in range(GameState.GRID_SIZE):
						for c2 in range(GameState.GRID_SIZE):
							var ally: GameState.CardInstance = GameState.grids[player_index][r2][c2]
							if ally == source or ally.card_type != "character" or not ally.face_up:
								continue
							var name_match: bool = not name_filter.is_empty() \
									and name_filter in ally.card_name.to_lower()
							var aff_match: bool = target_affinity >= 0 and ally.affinity == target_affinity
							if name_match or aff_match:
								ally.field_aura_atk_bonus += atk_boost
			if source.ability_type == CharacterData.AbilityType.MOON_ALLY_FIELD_AURA:
				var _moon_filter: String = str(source.ability_params.get("name_contains", "moon")).to_lower()
				var _moon_atk: int = source.ability_params.get("atk", 15)
				var _moon_def: int = source.ability_params.get("def", 15)
				var _moon_self_atk: int = source.ability_params.get("self_atk", 30)
				var _moon_ally_found: bool = false
				for r2 in range(GameState.GRID_SIZE):
					for c2 in range(GameState.GRID_SIZE):
						var ally: GameState.CardInstance = GameState.grids[player_index][r2][c2]
						if ally.card_type != "character" or not ally.face_up:
							continue
						if _moon_filter in ally.card_name.to_lower():
							if ally != source:
								_moon_ally_found = true
							ally.field_aura_atk_bonus += _moon_atk
							ally.field_aura_def_bonus += _moon_def
				if _moon_ally_found:
					source.field_aura_atk_bonus += _moon_self_atk
			if source.ability_type == CharacterData.AbilityType.UNION_ZONE_ALLY_DEF_AURA and source.is_union:
				var _ud: UnionData = UnionDatabase.get_union(source.card_name)
				if _ud != null:
					var _def_aura: int = int(source.ability_params.get("def", 0))
					for off: Variant in _ud.union_zone:
						var ov: Vector2i = off as Vector2i if off is Vector2i else Vector2i(int(off.x), int(off.y))
						var _ar: int = source.grid_row + ov.x
						var _ac: int = source.grid_col + ov.y
						if _ar < 0 or _ar >= GameState.GRID_SIZE or _ac < 0 or _ac >= GameState.GRID_SIZE:
							continue
						var ally: GameState.CardInstance = GameState.grids[player_index][_ar][_ac]
						if ally.card_type == "character" and ally != source:
							ally.field_aura_def_bonus += _def_aura
			if source.ability_type == CharacterData.AbilityType.DEF_PENALTY_VS_NON_AFFINITY \
					and source.has_mutagen_flag:
				var party_atk: int = source.ability_params.get("mutagen_party_atk", 0)
				var party_def: int = source.ability_params.get("mutagen_party_def", 0)
				var party_aff: int = source.ability_params.get(
					"mutagen_party_affinity", source.ability_params.get("affinity", -1))
				if party_atk != 0 or party_def != 0:
					for r2 in range(GameState.GRID_SIZE):
						for c2 in range(GameState.GRID_SIZE):
							var ally: GameState.CardInstance = GameState.grids[player_index][r2][c2]
							if ally.card_type != "character" or not ally.face_up:
								continue
							if ally.affinity == party_aff:
								ally.field_aura_atk_bonus += party_atk
								ally.field_aura_def_bonus += party_def

static func _apply_venom_queen_global_debuff() -> void:
	var total_atk_penalty: int = 0
	var total_def_penalty: int = 0
	for p in range(2):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var source: GameState.CardInstance = GameState.grids[p][r][c]
				if source.card_type != "character" or not source.face_up:
					continue
				if source.ability_type != CharacterData.AbilityType.FIELD_DEBUFF_ALL_VENOM_CARDS:
					continue
				total_atk_penalty += source.ability_params.get("atk", 15)
				total_def_penalty += source.ability_params.get("def", 15)
	if total_atk_penalty == 0 and total_def_penalty == 0:
		return
	for p in range(2):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.grids[p][r][c]
				if card.card_type != "character" or "venom" not in card.flags:
					continue
				card.field_aura_atk_bonus -= total_atk_penalty
				card.field_aura_def_bonus -= total_def_penalty

static func _apply_field_ability_bonus(
		card: GameState.CardInstance,
		player_index: int
) -> void:
	match card.ability_type:
		CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD:
			var count := _count_matching_cards(player_index, card)
			_apply_per_field_count_bonus(card, count)

		CharacterData.AbilityType.BOOST_PER_ANIMA_ON_FIELD:
			var count := _count_anima_cards(player_index, card)
			_apply_per_field_count_bonus(card, count)

		CharacterData.AbilityType.ATK_PENALTY_IF_NO_NAME_ALLY:
			if not _has_name_ally_on_field(player_index, card):
				card.field_aura_atk_bonus -= card.ability_params.get("penalty", 0)

		CharacterData.AbilityType.DESTROY_SELF_VS_DIVINE_BOTH:
			if card.ability_params.has("atk_bonus") or card.ability_params.has("affinity"):
				var count := _count_matching_cards(player_index, card)
				_apply_per_field_count_bonus(card, count)

static func _has_name_ally_on_field(player_index: int, source_card: GameState.CardInstance) -> bool:
	var name_filter: String = source_card.ability_params.get(
		"name", source_card.ability_params.get("name_contains", "")).to_lower()
	if name_filter.is_empty():
		return false
	for p: int in _field_players(player_index, source_card.ability_params):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var ally: GameState.CardInstance = GameState.grids[p][r][c]
				if ally == source_card:
					continue
				if ally.card_type == "character" and ally.face_up \
						and name_filter in ally.card_name.to_lower():
					return true
	return false

static func _count_matching_cards(player_index: int, source_card: GameState.CardInstance) -> int:
	var count := 0
	var name_filter: String = source_card.ability_params.get(
		"card_name_contains", source_card.ability_params.get("name", "")).to_lower()
	var affinity_filter: int = source_card.ability_params.get("affinity", -1)

	for p: int in _field_players(player_index, source_card.ability_params):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.grids[p][r][c]
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
	for p: int in _field_players(player_index, source_card.ability_params):
		for r in range(GameState.GRID_SIZE):
			for c in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.grids[p][r][c]
				if card == source_card:
					continue
				if card.card_type == "character" and card.face_up:
					if card.affinity == CharacterData.Affinity.ANIMA:
						count += 1
	return count


## Overlay pills freeze at preview resolve; badge/mod come from final resolve.
static func copy_reckoning_pills_from(preview: BattleResult, final: BattleResult) -> void:
	final.attacker_pill_atk = preview.attacker_pill_atk
	final.attacker_pill_def = preview.attacker_pill_def
	final.defender_pill_atk = preview.defender_pill_atk
	final.defender_pill_def = preview.defender_pill_def


static func reckoning_overlay_log_lines(
		attacker_player: int,
		defender_player: int,
		result: BattleResult
) -> PackedStringArray:
	var lines: PackedStringArray = []
	if result.special_trigger in ["trap_effect", "trap_nullified"]:
		lines.append(_reckoning_overlay_combatant_line(
			attacker_player,
			BattleLogFormat.attack_side_label(result, true),
			result.attacker_atk_used,
			result.attacker_pill_atk,
			result.attacker_pill_def,
			result.attacker_atk_delta,
			"ATK",
			result.attacker_pill_atk))
		return lines
	lines.append(_reckoning_overlay_combatant_line(
		attacker_player,
		BattleLogFormat.attack_side_label(result, true),
		result.attacker_atk_used,
		result.attacker_pill_atk,
		result.attacker_pill_def,
		result.attacker_atk_delta,
		"ATK",
		result.attacker_pill_atk))
	lines.append(_reckoning_overlay_combatant_line(
		defender_player,
		BattleLogFormat.attack_side_label(result, false),
		result.defender_def_used,
		result.defender_pill_atk,
		result.defender_pill_def,
		result.defender_def_delta,
		"DEF",
		result.defender_pill_def))
	return lines


static func _reckoning_mod_label(stat: String, delta: int) -> String:
	if delta == 0:
		return "mod=+%s 0" % stat
	if delta > 0:
		return "mod=+%s %d" % [stat, delta]
	return "mod=-%s %d" % [stat, absi(delta)]


static func _reckoning_overlay_combatant_line(
		player: int,
		card_label: String,
		badge: int,
		atk_pill: int,
		def_pill: int,
		mod_delta: int,
		mod_stat: String,
		verify_pill: int
) -> String:
	var name_str: String = card_label if not card_label.is_empty() else "?"
	var verify_sum: int = verify_pill + mod_delta
	var mismatch: String = "" if verify_sum == badge else " MISMATCH"
	return "Reckoning overlay: P%d %s badge=%d ATK pill=%d DEF pill=%d %s (%d%+d=%d)%s" % [
		player, name_str, badge, atk_pill, def_pill,
		_reckoning_mod_label(mod_stat, mod_delta),
		verify_pill, mod_delta, badge, mismatch]


static func _target_in_union_zone(anchor_r: int, anchor_c: int, target: Vector2i, zone: Array) -> bool:
	if zone.is_empty() or anchor_r < 0 or anchor_c < 0:
		return false
	for off: Variant in zone:
		var ov: Vector2i = off as Vector2i if off is Vector2i else Vector2i(int(off.x), int(off.y))
		if Vector2i(anchor_r + ov.x, anchor_c + ov.y) == target:
			return true
	return false


static func _union_zone_for_card(card: GameState.CardInstance) -> Array:
	if not card.is_union:
		return []
	var u: UnionData = UnionDatabase.get_union(card.card_name)
	return u.union_zone if u != null else []


static func _is_taunt_non_arcane_card(card: GameState.CardInstance) -> bool:
	return card.card_type == "character" \
			and card.face_up \
			and card.ability_type == CharacterData.AbilityType.TAUNT_NON_ARCANE


static func opponent_has_taunt_non_arcane(defender_player: int) -> bool:
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			if _is_taunt_non_arcane_card(GameState.get_card(defender_player, r, c)):
				return true
	return false


## Returns {ok: bool, reason: String} for attack target legality (Magnet taunt, Death Colony pattern, etc.).
static func validate_attack_target(
		attacker_player: int,
		attacker_pos: Vector2i,
		attacker: GameState.CardInstance,
		defender_player: int,
		target_pos: Vector2i,
		defender: GameState.CardInstance
) -> Dictionary:
	if defender.was_destroyed:
		return {"ok": false, "reason": "Cannot target an empty cell."}
	if target_pos in GameState.locked_attack_positions:
		return {"ok": false, "reason": "That square is locked by a trap."}

	if attacker.ability_type == CharacterData.AbilityType.ATTACK_ONLY_UNION_ZONE_PATTERN:
		var zone: Array = _union_zone_for_card(attacker)
		if zone.is_empty():
			zone = attacker.ability_params.get("union_zone", [])
		if not zone.is_empty() \
				and not _target_in_union_zone(attacker_pos.x, attacker_pos.y, target_pos, zone):
			return {
				"ok": false,
				"reason": "%s can only attack targets in its Union Zone pattern." % attacker.card_name,
			}

	if attacker.card_type == "character" \
			and attacker.affinity != CharacterData.Affinity.ARCANE \
			and opponent_has_taunt_non_arcane(defender_player):
		if defender.card_type == "character" and defender.face_up \
				and not _is_taunt_non_arcane_card(defender):
			return {
				"ok": false,
				"reason": "Magnet Elemental: Non-Arcane units must target it instead of other exposed units.",
			}

	return {"ok": true, "reason": ""}


static func is_attack_target_allowed(
		attacker_player: int,
		attacker_pos: Vector2i,
		attacker: GameState.CardInstance,
		defender_player: int,
		target_pos: Vector2i,
		defender: GameState.CardInstance
) -> bool:
	return bool(validate_attack_target(
		attacker_player, attacker_pos, attacker, defender_player, target_pos, defender).get("ok", false))


static func attacker_has_any_legal_target(
		attacker_player: int,
		attacker_pos: Vector2i,
		attacker: GameState.CardInstance
) -> bool:
	var defender_player: int = GameState.get_opponent(attacker_player)
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var pos: Vector2i = Vector2i(r, c)
			if pos in GameState.locked_attack_positions:
				continue
			var defender: GameState.CardInstance = GameState.get_card(defender_player, r, c)
			if is_attack_target_allowed(
					attacker_player, attacker_pos, attacker, defender_player, pos, defender):
				return true
	return false
