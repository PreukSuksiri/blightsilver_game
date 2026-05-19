class_name TurnManager
extends Node
# Manages turn flow, delegates to GameState for state tracking.

signal mode_selected(player_index: int, mode: GameState.TurnMode)
signal attack_phase_started(player_index: int, max_attacks: int)
signal attack_completed(attacker_pos: Vector2i, target_pos: Vector2i, result: BattleResolver.BattleResult)
signal tech_played(player_index: int, tech_name: String)
signal tech_resolved(player_index: int)
signal turn_ended(player_index: int)
signal awaiting_trap_choice(trap_name: String, choices: Array)
signal awaiting_target_selection(prompt: String, filter: String)
signal battle_preview_needed(attacker_player: int, attacker: GameState.CardInstance, defender: GameState.CardInstance, result: BattleResolver.BattleResult)
signal battle_preview_done
signal crystal_animation_done
signal attack_aborted
signal card_effect_flash_done

# Pending choices for async UI flows
var _pending_trap_resolve: Callable
var _pending_target_resolve: Callable
var _siege_cannon_attacker_player: int = -1

func start_turn(player_index: int) -> void:
	GameState.current_player = player_index
	GameState.turn_number += 1
	GameState.current_mode = GameState.TurnMode.NONE
	GameState.attacks_remaining = 2

	# Frenzy Strike: +1 attack per turn for both players
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "frenzy_strike" in GameState.active_dungeon_modifiers:
		GameState.attacks_remaining = 3

	# Dimensional Gate: destroy all pending unions at turn start
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "dimensional_gate" in GameState.active_dungeon_modifiers:
		for entry: Dictionary in DailyDungeonManager.pop_dimensional_gate_pending():
			var p: int = int(entry.get("player", 0))
			var r: int = int(entry.get("row", 0))
			var c: int = int(entry.get("col", 0))
			GameState.destroy_card(p, r, c)

	# Clear per-turn state
	_clear_turn_state(player_index)

	# Handle skip turn (Ceasefire)
	if GameState.skip_next_turn[player_index]:
		GameState.skip_next_turn[player_index] = false
		GameState.post_message("Player %d's turn is skipped!" % (player_index + 1))
		_end_turn(player_index)
		return

	# Apply end-of-turn permanent boosts for Hyperspeed Saucer (from previous turn)
	_apply_end_of_turn_boosts(player_index)

	# Check stuck condition
	GameState.check_stuck_win_condition()
	if GameState.current_phase == GameState.Phase.GAME_OVER:
		return

	# Fire TURN_START triggers
	CardRuleEngine.emit_trigger(CardRule.TriggerType.TURN_START_OWNER,
		{"source_player": player_index})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.TURN_START_OPPONENT,
		{"source_player": GameState.get_opponent(player_index)})

	GameState.set_phase(GameState.Phase.MODE_SELECT)
	GameState.post_message("Player %d's turn — play a Tech (optional) then Attack." % (player_index + 1))

func select_mode(mode: GameState.TurnMode) -> void:
	var player := GameState.current_player
	if GameState.current_phase != GameState.Phase.MODE_SELECT:
		return

	GameState.current_mode = mode
	emit_signal("mode_selected", player, mode)

	if mode == GameState.TurnMode.ATTACK:
		_start_attack_mode(player)

# ─────────────────────────────────────────────────────────────
# ATTACK MODE
# ─────────────────────────────────────────────────────────────
func _start_attack_mode(player: int) -> void:
	GameState.set_phase(GameState.Phase.ATTACK)
	emit_signal("attack_phase_started", player, 0)
	GameState.post_message("Player %d: tap a character to attack." % (player + 1))

func perform_attack(attacker_pos: Vector2i, target_pos: Vector2i) -> void:
	var player := GameState.current_player
	var opponent := GameState.get_opponent(player)

	if GameState.current_phase not in [GameState.Phase.MODE_SELECT, GameState.Phase.ATTACK]:
		return

	var attacker := GameState.get_card(player, attacker_pos.x, attacker_pos.y)
	var defender := GameState.get_card(opponent, target_pos.x, target_pos.y)

	if attacker.card_type != "character":
		GameState.post_message("You must attack with a Character.")
		emit_signal("attack_aborted")
		return
	if attacker.attacked_this_turn:
		GameState.post_message("%s has already attacked this turn." % attacker.card_name)
		emit_signal("attack_aborted")
		return
	if GameState.attacks_remaining <= 0:
		GameState.post_message("No attacks remaining this turn.")
		emit_signal("attack_aborted")
		return
	if attacker.cannot_attack_until >= GameState.turn_number:
		GameState.post_message("%s cannot attack yet." % attacker.card_name)
		emit_signal("attack_aborted")
		return

	# Berserk: only berserk card can attack
	if GameState.berserk_active[player] != null:
		if GameState.berserk_active[player] != attacker:
			GameState.post_message("Only the Berserk character can attack!")
			emit_signal("attack_aborted")
			return

	GameState.attacker_card = attacker
	GameState.attacker_pos = attacker_pos

	# Fire attack-initiated triggers
	CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_ATTACK_INITIATED_SELF,
		{"source_player": player, "source_card": attacker, "attacker": attacker, "defender": defender})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_ATTACK_INITIATED_ANY_OWNER,
		{"source_player": player, "attacker": attacker, "defender": defender})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_DEFEND_SELF,
		{"source_player": opponent, "source_card": defender, "attacker": attacker, "defender": defender})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_DEFEND_ANY_OWNER,
		{"source_player": opponent, "attacker": attacker, "defender": defender})
	# Emit GameState signal for target selection tracking
	GameState.emit_signal("attack_target_selected", player, opponent, target_pos.x, target_pos.y)

	# Exposed = already face-up BEFORE this attack began (whatever revealed it has fully resolved).
	# Revealed = this attack is what flips it — dust still in the air.
	var defender_was_exposed: bool = defender.face_up

	# Flip attacker face-up
	GameState.reveal_card(player, attacker_pos.x, attacker_pos.y)
	# Flip target face-up (skip for blank — it gets destroyed directly, no reveal needed)
	if defender.card_type != "dead_end":
		GameState.reveal_card(opponent, target_pos.x, target_pos.y)

	# Update field-based bonuses before battle
	BattleResolver.calculate_field_bonuses(player)
	BattleResolver.calculate_field_bonuses(opponent)

	GameState.set_phase(GameState.Phase.BATTLE)
	var result := BattleResolver.resolve_battle(
		attacker, defender, GameState.dice_result, player, opponent, defender_was_exposed
	)

	for msg in result.messages:
		GameState.post_message(msg)

	# Show damage calculation overlay and wait for it to dismiss
	emit_signal("battle_preview_needed", player, attacker, defender, result)
	await battle_preview_done

	# Handle trap special triggers
	if result.special_trigger == "trap_effect":
		await _handle_trap_effect(result.special_params, attacker, attacker_pos, target_pos, player, opponent)
		CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_ATTACK_TRAP_TRIGGERED,
			{"source_player": player, "source_card": attacker, "attacker": attacker, "defender": defender})
	elif result.special_trigger == "trap_nullified":
		# Trap becomes blank area regardless — animate destroy
		GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
	else:
		if defender.card_type == "dead_end":
			# Blank slot hit — destroy directly, skip battle resolution (nothing to resolve)
			GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
			CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_ATTACK_DEAD_END_DONE,
				{"source_player": player, "source_card": attacker, "attacker": attacker})
		else:
			# Fire PRE_RESOLVE chain, then resolve and apply
			CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_PRE_RESOLVE,
				{"source_player": player, "attacker": attacker, "defender": defender,
				 "dice_roll": GameState.dice_result})
			CardRuleEngine.resolve_chain(
				{"source_player": player, "attacker": attacker, "defender": defender})

			await _apply_battle_result(result, player, opponent, attacker_pos, target_pos, attacker, defender)

			# Fire exposed-card trigger if defender was already revealed
			if result.defender_was_exposed:
				CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_ATTACK_EXPOSED_CARD,
					{"source_player": player, "source_card": attacker,
					 "attacker": attacker, "defender": defender})

			# Fire win/lose/tie triggers
			var battle_ctx: Dictionary = {
				"source_player": player, "attacker": attacker, "defender": defender
			}
			if result.attacker_destroyed and result.defender_destroyed:
				CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_TIE_SELF, battle_ctx)
			elif result.defender_destroyed:
				CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_WIN_SELF,
					{"source_player": player, "source_card": attacker,
					 "attacker": attacker, "defender": defender})
				CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_WIN_ANY_OWNER,
					{"source_player": player, "attacker": attacker, "defender": defender})
				CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_LOSE_SELF,
					{"source_player": opponent, "source_card": defender,
					 "attacker": attacker, "defender": defender})
				CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_LOSE_ANY_OWNER,
					{"source_player": opponent, "attacker": attacker, "defender": defender})
			elif result.attacker_destroyed:
				CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_LOSE_SELF,
					{"source_player": player, "source_card": attacker,
					 "attacker": attacker, "defender": defender})
				CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_LOSE_ANY_OWNER,
					{"source_player": player, "attacker": attacker, "defender": defender})
				CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_WIN_ANY_OWNER,
					{"source_player": opponent, "attacker": attacker, "defender": defender})

	emit_signal("attack_completed", attacker_pos, target_pos, result)

	attacker.attacked_this_turn = true
	GameState.attacks_remaining -= 1

	# Check Pit Lord one_use_def_boost mark
	if defender.ability_type == CharacterData.AbilityType.ONE_USE_DEF_BOOST:
		defender.one_use_def_boost_used = true

	# Scout Probe: reveal adjacent after attack
	if attacker.ability_type == CharacterData.AbilityType.REVEAL_ADJACENT_AFTER_ATTACK:
		if not result.attacker_destroyed:
			emit_signal("awaiting_target_selection", "Scout Probe: Choose an adjacent square to reveal.", "adjacent")

	# Check Siege Cannon
	if GameState.siege_cannon_active[player]:
		if defender.card_type == "character" and not result.defender_destroyed:
			GameState.destroy_card(opponent, target_pos.x, target_pos.y)
			await crystal_animation_done
			GameState.siege_cannon_active[player] = false
			GameState.post_message("Siege Cannon: Defender destroyed!")

	# Return to active turn — player may continue attacking with other characters
	GameState.set_phase(GameState.Phase.MODE_SELECT)

func end_attacks_early() -> void:
	var player := GameState.current_player
	if GameState.current_phase in [GameState.Phase.MODE_SELECT, GameState.Phase.ATTACK]:
		GameState.post_message("Player %d ends their turn." % (player + 1))
		_end_turn(player)

# ─────────────────────────────────────────────────────────────
# TECH MODE
# ─────────────────────────────────────────────────────────────
func after_tech_resolved(player: int) -> void:
	emit_signal("tech_resolved", player)

func play_tech_card(tech_name: String) -> void:
	var player := GameState.current_player
	if GameState.current_phase != GameState.Phase.MODE_SELECT:
		return

	var data: TechCardData = CardDatabase.get_tech(tech_name)
	if data == null:
		GameState.post_message("Unknown Tech Card: %s" % tech_name)
		return

	if not tech_name in GameState.tech_hands[player]:
		GameState.post_message("You don't have %s." % tech_name)
		return

	if GameState.crystals[player] < data.crystal_cost:
		GameState.post_message("Not enough Crystals to play %s." % tech_name)
		return

	# Check chain requirement
	if data.required_prior_card != "":
		if not GameState.tech_name_played_this_game(player, data.required_prior_card):
			GameState.post_message("%s requires %s to have been played first." % [tech_name, data.required_prior_card])
			return

	# Pay cost
	GameState.lose_crystals(player, data.crystal_cost)
	await crystal_animation_done
	GameState.tech_hands[player].erase(tech_name)
	GameState.tech_cards_played_this_game[player].append(tech_name)

	emit_signal("tech_played", player, tech_name)
	GameState.emit_signal("tech_card_used", player, tech_name)
	CardRuleEngine.emit_trigger(CardRule.TriggerType.TECH_CARD_USED_OWNER,
		{"source_player": player, "tech_name": tech_name})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.TECH_CARD_USED_OPPONENT,
		{"source_player": GameState.get_opponent(player), "tech_name": tech_name})
	GameState.post_message("Player %d plays %s!" % [player + 1, tech_name])
	GameState.emit_signal("card_effect_triggered", tech_name, "tech")
	await card_effect_flash_done

	# Effects that resolve immediately without needing targets
	match data.effect_type:
		TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE, \
		TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_CHAIN:
			emit_signal("awaiting_target_selection",
				"Choose %d square(s) to reveal on opponent's field." % data.effect_params.get("count", 1),
				"opponent_squares_%d" % data.effect_params.get("count", 1))

		TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_RISKY:
			emit_signal("awaiting_target_selection",
				"Choose 3 squares to reveal (Corrupted Spy).",
				"opponent_squares_3_risky")

		TechCardData.TechEffectType.OPPONENT_REVEALS_SQUARE:
			GameState.post_message("Opponent must choose and reveal 1 of their squares.")
			emit_signal("awaiting_target_selection", "Tease: Choose 1 of your squares to reveal.", "self_squares_1_opponent_turn")

		TechCardData.TechEffectType.OPPONENT_REVEALS_OR_GAINS:
			emit_signal("awaiting_target_selection", "Bribe: Reveal a creature for 700 Crystals or pass.", "bribe")

		TechCardData.TechEffectType.BOTH_SKIP_TURN:
			GameState.skip_next_turn[0] = true
			GameState.skip_next_turn[1] = true
			GameState.post_message("Ceasefire! Both players skip their next turn.")
			_end_turn(player)
			return

		TechCardData.TechEffectType.BOTH_LOCK_CHOSEN_MONSTER:
			emit_signal("awaiting_target_selection", "Make Friend: Choose 1 of your monsters to lock.", "lock_own_monster")

		TechCardData.TechEffectType.ADD_MUTAGEN_FLAG:
			emit_signal("awaiting_target_selection", "Release Mutagen: Choose a Bio Character to flag.", "own_bio_character")

		TechCardData.TechEffectType.DIVINE_PROTECTION:
			GameState.divine_protection_active[player] = true
			GameState.post_message("Prayer: Divine Characters protected until your next turn.")
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.DESTROY_ALL_REVEALED_OPPONENT:
			_resolve_arcane_nova(player)
			return

		TechCardData.TechEffectType.DESTROY_ROW_OR_COLUMN:
			emit_signal("awaiting_target_selection", "Rift Strike: Choose a row or column.", "row_or_column")

		TechCardData.TechEffectType.REVEAL_ALL_OWN_CHARACTERS:
			_reveal_all_own(player)
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.PERM_BOOST_ALL_FACEUP:
			_boost_all_faceup(player, data.effect_params.get("atk", 0), data.effect_params.get("def", 0))
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.PERM_ATK_BOOST_ONE, \
		TechCardData.TechEffectType.PERM_DEF_BOOST_ONE, \
		TechCardData.TechEffectType.TEMP_ATK_BOOST_ATTACK_NOW:
			emit_signal("awaiting_target_selection", "Choose 1 face-up character to boost.", "own_faceup_character")

		TechCardData.TechEffectType.TEMP_DEF_BOOST_ALL:
			_temp_boost_all(player, 0, data.effect_params.get("def", 0))
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.OPPONENT_NEXT_DEFENDER_DESTROYED:
			GameState.siege_cannon_active[player] = true
			GameState.post_message("Siege Cannon active!")
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.DESTROY_FACEUP_CARD, \
		TechCardData.TechEffectType.DESTROY_FACEUP_NO_CRYSTAL_LOSS:
			emit_signal("awaiting_target_selection", "Choose 1 face-up card to destroy.", "any_faceup_card")

		TechCardData.TechEffectType.MULTI_ATTACK_ONE:
			emit_signal("awaiting_target_selection", "Berserk: Choose 1 face-up character.", "own_faceup_character_berserk")

		TechCardData.TechEffectType.REVEAL_OWN_AND_OPPONENT_REVEALS:
			emit_signal("awaiting_target_selection", "Diplomacy Party: Choose 1 of your face-down characters.", "own_facedown_character")

		TechCardData.TechEffectType.MOVE_BUFFS_BETWEEN_CHARACTERS:
			emit_signal("awaiting_target_selection", "Essence Transfer: Choose source character.", "own_faceup_character_source")

		TechCardData.TechEffectType.DESTROY_OWN_BASE_ZERO_OPPONENT:
			emit_signal("awaiting_target_selection", "Blood Ritual: Choose 1 of your face-up cards to destroy.", "own_faceup_card_sacrifice")

		TechCardData.TechEffectType.CLONE_CHARACTER_AS_TOKEN:
			emit_signal("awaiting_target_selection", "Arcane Duplication: Choose 1 of your face-up characters.", "own_faceup_character")

		TechCardData.TechEffectType.REVIVE_CHARACTER_FULL, \
		TechCardData.TechEffectType.REVIVE_CHARACTER_NO_ATK:
			emit_signal("awaiting_target_selection", "Choose a destroyed character to revive.", "graveyard")

		TechCardData.TechEffectType.VIEW_OPPONENT_TECH:
			emit_signal("awaiting_target_selection", "Tech Copy: View opponent's hand?", "view_opponent_hand")

		TechCardData.TechEffectType.FORCE_SHIELD_ONE_CARD:
			emit_signal("awaiting_target_selection", "Force Shield: Choose 1 of your cards to protect.", "own_any_card")

		TechCardData.TechEffectType.NOT_IMPLEMENTED:
			GameState.show_center_message("Ability not implemented: " + data.card_name)
			after_tech_resolved(player)

# ─────────────────────────────────────────────────────────────
# Tech helpers
# ─────────────────────────────────────────────────────────────
func _resolve_arcane_nova(player: int) -> void:
	var opponent := GameState.get_opponent(player)
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
			if card.card_type == "character" and card.face_up:
				GameState.destroy_card(opponent, r, c)
				await crystal_animation_done
	# Discard all own tech
	GameState.tech_hands[player].clear()
	GameState.post_message("Arcane Nova! All revealed opponent characters destroyed. Your Tech Cards discarded.")
	after_tech_resolved(player)

func _reveal_all_own(player: int) -> void:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character" and not card.face_up:
				GameState.reveal_card(player, r, c)

func _boost_all_faceup(player: int, atk_bonus: int, def_bonus: int) -> void:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character" and card.face_up:
				card.perm_atk_bonus += atk_bonus
				card.perm_def_bonus += def_bonus

func _temp_boost_all(player: int, atk_bonus: int, def_bonus: int) -> void:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character" and card.face_up:
				card.temp_atk_bonus += atk_bonus
				card.temp_def_bonus += def_bonus

# ─────────────────────────────────────────────────────────────
# Apply battle results to game state
# ─────────────────────────────────────────────────────────────
func _apply_battle_result(
		result: BattleResolver.BattleResult,
		player: int,
		opponent: int,
		attacker_pos: Vector2i,
		target_pos: Vector2i,
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance
) -> void:
	if result.attacker_crystal_loss > 0:
		GameState.lose_crystals(player, result.attacker_crystal_loss)
		await crystal_animation_done
	if result.defender_crystal_loss > 0:
		# Divine Protection
		if defender.card_type == "character" and GameState.divine_protection_active[opponent]:
			if defender.affinity == CharacterData.Affinity.DIVINE:
				result.defender_destroyed = false
				result.defender_crystal_loss = 0
				GameState.divine_protection_active[opponent] = false
				GameState.post_message("Prayer protected %s!" % defender.card_name)
			else:
				GameState.lose_crystals(opponent, result.defender_crystal_loss)
				await crystal_animation_done
		else:
			GameState.lose_crystals(opponent, result.defender_crystal_loss)
			await crystal_animation_done

	if result.attacker_crystal_gain > 0:
		GameState.gain_crystals(player, result.attacker_crystal_gain)
	if result.defender_crystal_gain > 0:
		GameState.gain_crystals(opponent, result.defender_crystal_gain)

	# Archbishop redirect
	if result.defender_destroyed:
		if defender.ability_type == CharacterData.AbilityType.REDIRECT_DESTRUCTION_TO_ALLY:
			emit_signal("awaiting_target_selection",
				"Archbishop: Destroy 1 other Divine Character instead?",
				"own_divine_character_redirect")
			return  # Will be resolved by UI callback

	if result.attacker_destroyed:
		GameState.destroy_card(player, attacker_pos.x, attacker_pos.y, false)
	if result.defender_destroyed:
		GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
	elif defender.card_type == "trap":
		# Trap triggered → animate destroy
		GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)

func resolve_archbishop_redirect(player: int, redirect_pos: Vector2i, original_defender_pos: Vector2i) -> void:
	# Player chose to destroy another Divine instead
	GameState.destroy_card(player, redirect_pos.x, redirect_pos.y)
	await crystal_animation_done
	# Defender (Archbishop) survives, so no blank placed at original_defender_pos
	GameState.post_message("Archbishop redirected destruction to another card.")

# ─────────────────────────────────────────────────────────────
# Trap effect resolution (async)
# ─────────────────────────────────────────────────────────────
func _handle_trap_effect(
		params: Dictionary,
		attacker: GameState.CardInstance,
		attacker_pos: Vector2i,
		target_pos: Vector2i,
		player: int,
		opponent: int
) -> void:
	var trap_data: TrapData = params.get("trap_data", null)
	if trap_data == null:
		return

	# Trap always becomes blank after triggering — animate destroy
	GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
	GameState.lose_crystals(opponent, trap_data.crystal_cost)
	await crystal_animation_done

	# Honored Duel: trap is consumed but its effect is cancelled
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "honored_duel" in GameState.active_dungeon_modifiers:
		GameState.post_message("Honored Duel: %s's effect is cancelled!" % trap_data.card_name)
		return

	match trap_data.effect_type:
		TrapData.TrapEffectType.NULLIFY_ATTACK:
			GameState.post_message("Attack nullified by %s." % trap_data.card_name)

		TrapData.TrapEffectType.NULLIFY_ATTACK_ATK_DEBUFF:
			var debuff: int = trap_data.effect_params.get("atk_debuff", 5)
			# Apply debuff to all currently attacking character (just attacker in this turn)
			attacker.atk_debuff += debuff
			GameState.post_message("Trap Hole: Attacker gets -%d ATK this turn." % debuff)

		TrapData.TrapEffectType.NULLIFY_ATTACK_REVEAL_ADJACENT:
			GameState.post_message("Hostage: Adjacent squares revealed and locked.")
			var adj := GameState.get_adjacent_positions(target_pos.x, target_pos.y)
			for pos in adj:
				GameState.reveal_card(opponent, pos.x, pos.y)
			# Lock adjacent squares as targets (handled by UI via emit)
			emit_signal("awaiting_target_selection", "Hostage active.", "hostage_lock")

		TrapData.TrapEffectType.NULLIFY_ATTACK_CHOICE:
			emit_signal("awaiting_trap_choice",
				"Checkpoint",
				["Lose 500 Crystals", "Destroy your attacking character"])

		TrapData.TrapEffectType.REVEAL_DEFENDING_CHOICE:
			emit_signal("awaiting_target_selection", "Bait: Choose a square on your field to reveal.", "self_reveal_choice")

		TrapData.TrapEffectType.ATTACKER_DISCARD_OR_END_TURN:
			emit_signal("awaiting_trap_choice",
				"Blackmail",
				["Discard 1 Tech Card", "End your turn"])

		TrapData.TrapEffectType.COPY_ATTACKER_EFFECT:
			GameState.post_message("Cursed Reflection: Choose one of your face-up characters to copy %s's effect." % attacker.card_name)
			emit_signal("awaiting_target_selection", "Cursed Reflection: Choose target.", "self_faceup_for_copy")

		TrapData.TrapEffectType.DESTROY_ATTACKER_CHOICE_DESTROY:
			if trap_data.effect_params.get("requires_faceup_defender", false):
				if GameState.get_all_face_up_characters(opponent).is_empty():
					GameState.post_message("Explosive Barrels: No face-up defender — trap fizzles.")
					return
			GameState.lose_crystals(player, attacker.crystal_cost)
			await crystal_animation_done
			GameState.place_dead_end(player, attacker_pos.x, attacker_pos.y)
			emit_signal("awaiting_target_selection",
				"Explosive Barrels: Choose 1 revealed card on defender's field to destroy (no crystal loss).",
				"opponent_faceup_no_cost")

		TrapData.TrapEffectType.HYPNOTIZE_ATTACKER:
			attacker.cannot_attack_until = GameState.turn_number + 1
			GameState.post_message("Hypnosis: %s cannot attack until end of next turn." % attacker.card_name)

		TrapData.TrapEffectType.DESTROY_ATTACKER:
			GameState.lose_crystals(player, attacker.crystal_cost)
			await crystal_animation_done
			GameState.place_dead_end(player, attacker_pos.x, attacker_pos.y)
			GameState.post_message("Flame Trap: %s destroyed!" % attacker.card_name)

		TrapData.TrapEffectType.LOCK_ATTACKER_REMAINING_ATTACKS:
			GameState.attacks_remaining = 0
			GameState.post_message("Echo Barrier: Attacking player cannot attack again this turn!")

		TrapData.TrapEffectType.DRAIN_ATTACKER_CRYSTALS:
			var amount: int = trap_data.effect_params.get("amount", 800)
			GameState.lose_crystals(player, amount)
			await crystal_animation_done
			GameState.post_message("Mana Drain: Player %d loses %d Crystals!" % [player + 1, amount])

		TrapData.TrapEffectType.SWAP_ARMORED_NATURE:
			emit_signal("awaiting_target_selection",
				"Defensive Pheromone: Choose an 'Armored' Nature card to swap.",
				"own_armored_nature")

		TrapData.TrapEffectType.PERMANENT_ATK_DEBUFF:
			var amount: int = trap_data.effect_params.get("amount", 10)
			attacker.current_atk = max(0, attacker.current_atk - amount)
			GameState.post_message("Spike Trap: %s permanently loses %d ATK!" % [attacker.card_name, amount])

		TrapData.TrapEffectType.NULLIFY_ATTACKER_EFFECT:
			attacker.effect_nullified_until = GameState.turn_number + 1
			GameState.post_message("Snare Trap: %s's effect nullified until end of next turn!" % attacker.card_name)

		TrapData.TrapEffectType.FORCE_FRIENDLY_FIRE:
			emit_signal("awaiting_target_selection",
				"Brainwash: Choose one of your own cards as the attack target.",
				"own_any_as_target")

		TrapData.TrapEffectType.NULLIFY_BLOCK_ADJACENT:
			GameState.post_message("Bunker: Adjacent squares cannot be targeted this turn.")
			emit_signal("awaiting_target_selection", "Bunker active.", "bunker_lock")

		TrapData.TrapEffectType.NOT_IMPLEMENTED:
			GameState.show_center_message("Ability not implemented: " + trap_data.card_name)

# ─────────────────────────────────────────────────────────────
# End Turn
# ─────────────────────────────────────────────────────────────
func end_turn(player: int) -> void:
	_end_turn(player)

func _end_turn(player: int) -> void:
	# Fire TURN_END triggers before clearing state
	CardRuleEngine.emit_trigger(CardRule.TriggerType.TURN_END_OWNER,
		{"source_player": player})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.TURN_END_OPPONENT,
		{"source_player": GameState.get_opponent(player)})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.TURN_END_OWNER_NTH,
		{"source_player": player})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.TURN_END_OPPONENT_NTH,
		{"source_player": GameState.get_opponent(player)})
	CardRuleEngine.tick_turn_end(player)

	# Clear per-turn flags
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character":
				card.attacked_this_turn = false
				card.clear_temp_buffs()

	# Clear divine protection if it was this player's turn
	GameState.divine_protection_active[player] = false
	# Clear berserk if it's now ending
	if GameState.berserk_active[player] != null:
		GameState.berserk_active[player] = null

	# Lighthouse: reveal 1 random hidden opponent card at end of turn
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "lighthouse" in GameState.active_dungeon_modifiers:
		_lighthouse_reveal(player)

	emit_signal("turn_ended", player)

	var next_player := GameState.get_opponent(player)
	start_turn(next_player)

func _clear_turn_state(player: int) -> void:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character":
				card.attacked_this_turn = false

func _lighthouse_reveal(player: int) -> void:
	var opponent: int = GameState.get_opponent(player)
	var hidden_cells: Array = []
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
			if card.card_type == "character" and not card.face_up:
				hidden_cells.append(Vector2i(r, c))
	if hidden_cells.is_empty():
		return
	hidden_cells.shuffle()
	var cell: Vector2i = hidden_cells[0]
	GameState.reveal_card(opponent, cell.x, cell.y)
	GameState.post_message("Lighthouse: One of Player %d's cards is revealed!" % (opponent + 1))

func _apply_end_of_turn_boosts(player: int) -> void:
	# Hyperspeed Saucer permanent boost
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character" and card.face_up:
				if card.ability_type == CharacterData.AbilityType.PERM_BOOST_END_OF_TURN:
					card.current_atk += card.ability_params.get("atk", 0)
					card.current_def += card.ability_params.get("def", 0)
