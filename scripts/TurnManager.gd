class_name TurnManager
extends Node
# Manages turn flow, delegates to GameState for state tracking.

signal mode_selected(player_index: int, mode)
signal attack_phase_started(player_index: int, max_attacks: int)
signal attack_completed(attacker_pos: Vector2i, target_pos: Vector2i, result)
signal tech_played(player_index: int, tech_name: String)
signal tech_resolved(player_index: int)
signal turn_ended(player_index: int)
signal awaiting_trap_choice(trap_name: String, choices: Array)
signal awaiting_target_selection(prompt: String, filter: String)
signal battle_preview_needed(attacker_player: int, attacker, defender, result)
signal battle_preview_done
signal battle_result_finalized(result)
signal crystal_animation_done
signal attack_aborted
signal card_effect_flash_done
signal card_reveal_animation_done
signal wait_badge_animation_requested(player_index: int, row: int, col: int)
signal wait_badge_animation_done
signal ability_choice_resolved(choice_index: int)
signal awaiting_blackmail_tech_select(player_index: int)
signal blackmail_choice_resolved(discarded_tech: String)
signal awaiting_defender_choice(prompt: String, choices: Array)
signal coin_flip_visual_requested(results: Array)
signal coin_flip_visual_done
signal ability_selection_done
signal archbishop_redirect_resolved
signal brainwash_redirect_resolved

func _wait_crystal_animation() -> void:
	await GameState.wait_crystal_animation()

# Pending choices for async UI flows
var _pending_trap_resolve: Callable
var _pending_target_resolve: Callable
var _siege_cannon_attacker_player: int = -1
# Pending trap/ability params for target-selection callbacks
var _pending_trap_def_boost: int = 0
var _pending_trap_def_boost_carry: bool = false
var _pending_trap_def_boost_attacker: int = -1
var _attack_reveal_pending: Array = []  # Vector3i(player, row, col)
var _standalone_reveal_wait: Vector3i = Vector3i(-1, -1, -1)
const WITNESS_VIEW_DELAY: float = 0.5
var _pending_trap_self_destruct_boost: int = 0
var _pending_trap_self_destruct_player: int = -1
var _pending_swap_attacker_pos: Vector2i = Vector2i(-1, -1)
var _pending_swap_owner_player: int = -1
var _pending_rebel_king_owner: int = -1
var _pending_rebel_king_foe_player: int = -1
var _pending_trap_hostage_lock: bool = false
var _pending_street_joke_crystal: int = 0
var _pending_lockpicker_owner: int = -1
var _pending_reveal_attacker_player: int = -1
var _pending_wk17_foe_player: int = -1
var _pending_wk17_mode: String = ""
var _pending_wk17_exclude_pick_pos: Vector2i = Vector2i(-1, -1)
var _pending_wk17_defender_pos: Vector2i = Vector2i(-1, -1)
var _wk17_friendly_fire: bool = false
var _wk17_friendly_fire_pos: Vector2i = Vector2i(-1, -1)
var _wk17_substitute_battle: bool = false
var _wk17_substitute_grid_player: int = -1
var _wk17_substitute_attacker_pos: Vector2i = Vector2i(-1, -1)
var _wk17_substitute_defender_pos: Vector2i = Vector2i(-1, -1)
var _wk17_initiating_attacker_pos: Vector2i = Vector2i(-1, -1)
var _field_destroy_remaining: int = 0
var _field_destroy_foe_no_cost: bool = false
var _pending_rg_attacker_player: int = -1
var _pending_rg_exclude_pos: Vector2i = Vector2i(-1, -1)
var _pending_rg_defender_pos: Vector2i = Vector2i(-1, -1)
var _rg_friendly_fire: bool = false
var _rg_friendly_fire_pos: Vector2i = Vector2i(-1, -1)

## Depth counter for async flows (target selection, brainwash, etc.) that must
## finish before turn/AI continuation is allowed.
var _flow_block_depth: int = 0

func is_flow_blocked() -> bool:
	return _flow_block_depth > 0

## UI-driven target selection (tech/trap grid picks) that TurnManager does not await.
func begin_ui_target_selection() -> void:
	_flow_block_depth += 1

func end_ui_target_selection() -> void:
	_flow_block_depth = maxi(0, _flow_block_depth - 1)

func resolve_ability_choice(choice_index: int) -> void:
	emit_signal("ability_choice_resolved", choice_index)

func resolve_blackmail_choice(discarded_tech: String) -> void:
	emit_signal("blackmail_choice_resolved", discarded_tech)

func resolve_coin_flip_visual() -> void:
	emit_signal("coin_flip_visual_done")

## Roll count coins (true=heads, false=tails), show the visual overlay, then return results.
## Optional source cell: Maria the Battle Priest forces heads for adjacent units' coin abilities.
func _do_coin_flips(
		count: int,
		source_player: int = -1,
		source_row: int = -1,
		source_col: int = -1,
		intercept_traps: bool = true
) -> Array:
	var force_heads: bool = false
	if source_player >= 0 and source_row >= 0 and source_col >= 0:
		force_heads = GameState.adjacent_force_coin_heads_active_for(
			source_player, source_row, source_col)
	var results: Array = []
	for _i in range(count):
		results.append(true if force_heads else randi() % 2 == 1)
	if intercept_traps:
		results = await _apply_foe_coin_flip_traps(results, source_player)
	if force_heads and count > 0:
		GameState.post_message("Maria the Battle Priest: Coin flip forced to heads!")
	emit_signal("coin_flip_visual_requested", results)
	await coin_flip_visual_done
	return results

func _pick_foe_coin_flip_trap(flipper_player: int) -> Dictionary:
	if flipper_player < 0:
		return {}
	var trap_owner: int = GameState.get_opponent(flipper_player)
	var candidates: Array = []
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var trap_card: GameState.CardInstance = GameState.get_card(trap_owner, r, c)
			if trap_card.card_type != "trap" or trap_card.face_up:
				continue
			var trap_data: TrapData = CardDatabase.get_trap(trap_card.card_name) as TrapData
			if trap_data == null:
				continue
			if not trap_data.effect_params.get("trigger_on_foe_coin_flip", false):
				continue
			candidates.append({
				"owner": trap_owner,
				"pos": Vector2i(r, c),
				"card": trap_card,
				"data": trap_data,
				"index": r * GameState.GRID_SIZE + c,
			})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ca: int = int((a["data"] as TrapData).crystal_cost)
		var cb: int = int((b["data"] as TrapData).crystal_cost)
		if ca != cb:
			return ca < cb
		return int(a.get("index", 0)) < int(b.get("index", 0)))
	return candidates[0]

func _apply_foe_coin_flip_traps(results: Array, source_player: int) -> Array:
	var flipper: int = source_player if source_player >= 0 else GameState.current_player
	var trap_entry: Dictionary = _pick_foe_coin_flip_trap(flipper)
	if trap_entry.is_empty():
		return results
	var trap_owner: int = int(trap_entry.get("owner", -1))
	var trap_pos: Vector2i = trap_entry.get("pos", Vector2i(-1, -1))
	var trap_data: TrapData = trap_entry.get("data") as TrapData
	if trap_owner < 0 or trap_pos.x < 0 or trap_data == null:
		return results
	GameState.reveal_card(trap_owner, trap_pos.x, trap_pos.y)
	if trap_data.crystal_cost > 0:
		GameState.lose_crystals(trap_owner, trap_data.crystal_cost, "trap")
		await _wait_crystal_animation()
	GameState.post_message("%s triggered!" % trap_data.card_name)
	var mode: String = str(trap_data.effect_params.get("coin_manipulation", ""))
	if mode == "force_tails":
		var forced: Array = []
		for _r in results:
			forced.append(false)
		GameState.post_message("%s: Foe's coin flip(s) land on Tails." % trap_data.card_name)
		return forced
	if mode == "flip_override":
		var override_flip: Array = await _do_coin_flips(1, trap_owner, trap_pos.x, trap_pos.y, false)
		if override_flip[0]:
			var inverted: Array = []
			for _r in results:
				inverted.append(false)
			GameState.post_message("%s: Heads — foe's coin flip(s) land on Tails." % trap_data.card_name)
			return inverted
		GameState.post_message("%s: Tails — no change to foe's coin flip(s)." % trap_data.card_name)
	return results

func _card_grid_pos(card: GameState.CardInstance) -> Dictionary:
	for p: int in range(2):
		var pos: Vector2i = GameState.find_card_position(p, card)
		if pos.x >= 0:
			return {"player": p, "pos": pos}
	return {"player": -1, "pos": Vector2i(-1, -1)}

func _coin_flips_for_card(card: GameState.CardInstance, count: int) -> Array:
	var loc: Dictionary = _card_grid_pos(card)
	return await _do_coin_flips(
		count, int(loc.get("player", -1)), loc["pos"].x, loc["pos"].y)

## Joseph / Grand Wizard: flip before Reckoning overlay so stats match the visual.
func _maybe_flip_reckoning_attacker_coins(attacker: GameState.CardInstance) -> Array:
	if attacker == null or attacker.card_type != "character":
		return []
	match attacker.ability_type:
		CharacterData.AbilityType.COIN_FLIP_ATK_BOOST, \
		CharacterData.AbilityType.COIN_FLIP_ATK_DEF_BOOST:
			var _rc_loc: Dictionary = _card_grid_pos(attacker)
			return await _do_coin_flips(
				1,
				int(_rc_loc.get("player", -1)),
				_rc_loc["pos"].x,
				_rc_loc["pos"].y)
		CharacterData.AbilityType.END_OF_TURN_COIN_FLIP_STAT_BOOST:
			if attacker.ability_params.get("in_reckoning", false):
				var _rc_n: int = maxi(1, int(attacker.ability_params.get("coin_flips", 1)))
				var _rc_loc2: Dictionary = _card_grid_pos(attacker)
				return await _do_coin_flips(
					_rc_n,
					int(_rc_loc2.get("player", -1)),
					_rc_loc2["pos"].x,
					_rc_loc2["pos"].y)
	return []

func start_turn(player_index: int) -> void:
	GameState.current_player = player_index
	GameState.turn_number += 1
	GameState.turn_changed.emit(player_index)
	GameState.current_mode = GameState.TurnMode.NONE
	GameState.attacks_remaining = 2

	# Frenzy Strike: +1 attack per turn for both players
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "frenzy_strike" in GameState.active_dungeon_modifiers:
		GameState.attacks_remaining = 3

	# Frenzy Madness: +3 attacks per turn for both players (stacks with Frenzy Strike)
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "frenzy_madness" in GameState.active_dungeon_modifiers:
		GameState.attacks_remaining += 3

	var _turn_cap: int = int(GameState.attack_cap_next_turn[player_index])
	if _turn_cap >= 0:
		GameState.attacks_remaining = mini(GameState.attacks_remaining, _turn_cap)
		GameState.attack_cap_next_turn[player_index] = -1

	# Clear per-turn state
	_clear_turn_state(player_index)

	# Burning Phoenix and similar: revive at the start of the owner's turn
	GameState.process_turn_start_revives(player_index)

	# Dimensional Gate: destroy unions summoned under this modifier on the next turn start.
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "dimensional_gate" in GameState.active_dungeon_modifiers:
		var _dg_pending: Array = DailyDungeonManager.pop_dimensional_gate_pending()
		for _dg_entry: Variant in _dg_pending:
			if _dg_entry is not Dictionary:
				continue
			var _dg_p: int = int((_dg_entry as Dictionary).get("player", -1))
			var _dg_r: int = int((_dg_entry as Dictionary).get("row", -1))
			var _dg_c: int = int((_dg_entry as Dictionary).get("col", -1))
			if _dg_p < 0 or _dg_r < 0 or _dg_c < 0:
				continue
			var _dg_card: GameState.CardInstance = GameState.get_card(_dg_p, _dg_r, _dg_c)
			if _dg_card.card_type != "character" or not _dg_card.is_union:
				continue
			GameState.post_message(
				"Dimensional Gate: %s is pulled back through the gate!" % _dg_card.display_name)
			CardRuleEngine.deactivate_rules_for(_dg_card)
			GameState.destroy_card(_dg_p, _dg_r, _dg_c, false)

	# Clear Force Shield on this player's own cards.
	# Shield granted during player X's turn lasts through the opponent's next turn
	# and expires at the start of player X's following turn.
	for _fs_r: int in range(GameState.GRID_SIZE):
		for _fs_c: int in range(GameState.GRID_SIZE):
			GameState.get_card(player_index, _fs_r, _fs_c).force_shielded = false

	# Turn-start per-card effects
	for _ts_r: int in range(GameState.GRID_SIZE):
		for _ts_c: int in range(GameState.GRID_SIZE):
			var _ts_card: GameState.CardInstance = GameState.get_card(player_index, _ts_r, _ts_c)
			if _ts_card.card_type != "character" or not _ts_card.face_up:
				continue
			match _ts_card.ability_type:
				CharacterData.AbilityType.TEMP_ATK_BOOST_OWN_TURN_START:
					await await_card_effect_flash(_ts_card.card_name)
					_ts_card.temp_atk_bonus += _ts_card.ability_params.get("atk", 5)
				CharacterData.AbilityType.TURN_START_REVEAL_OPPONENT_CELL:
					await _prompt_and_await_target_selection(
						"%s: Choose 1 opponent cell to reveal." % _ts_card.card_name,
						"ability_false_prophet_reveal")
				CharacterData.AbilityType.TURN_START_COIN_FLIP_FLAG:
					await await_card_effect_flash(_ts_card.card_name)
					var _p29_cf: Array = await _do_coin_flips(1, player_index, _ts_r, _ts_c)
					if not _plant29_has_valid_targets(player_index, _p29_cf[0]):
						GameState.post_message("%s: No valid targets — ability cancelled." % _ts_card.card_name)
						continue
					var _p29_filter: String = "ability_plant29_venom" if _p29_cf[0] else "ability_plant29_mutagen"
					var _p29_prompt: String = "Heads! Choose 1 exposed ally or foe for Venom." if _p29_cf[0] \
							else "Tails! Choose 1 of your units for Mutagen."
					await _prompt_and_await_target_selection(
						"%s: %s" % [_ts_card.card_name, _p29_prompt],
						_p29_filter)
				CharacterData.AbilityType.TURN_START_DESTROY_OR_LOSE_CRYSTALS:
					var _ts_loss: int = int(_ts_card.ability_params.get("crystal_loss", 500))
					var _has_unit: bool = false
					for _tu_r: int in range(GameState.GRID_SIZE):
						for _tu_c: int in range(GameState.GRID_SIZE):
							if GameState.get_card(player_index, _tu_r, _tu_c).card_type == "character":
								_has_unit = true
								break
						if _has_unit:
							break
					if not _has_unit:
						GameState.lose_crystals(player_index, _ts_loss, "ability")
						GameState.post_message("%s: No units to destroy — lost %d crystals!" % [
							_ts_card.card_name, _ts_loss])
						continue
					emit_signal("awaiting_trap_choice",
						"%s: Destroy 1 of your units or lose %d crystals?" % [
							_ts_card.card_name, _ts_loss],
						["Destroy 1 unit", "Lose %d crystals" % _ts_loss])
					var _ts_choice: int = await ability_choice_resolved
					if _ts_choice == 0:
						await _prompt_and_await_target_selection(
							"%s: Choose 1 of your units to destroy." % _ts_card.card_name,
							"own_character_destroy_no_cost")
					else:
						GameState.lose_crystals(player_index, _ts_loss, "ability")
						GameState.post_message("%s: Lost %d crystals!" % [_ts_card.card_name, _ts_loss])

	# Foe-turn-start abilities on opponent's field (e.g. Alluring Witch)
	var _opp_for_foe_start: int = GameState.get_opponent(player_index)
	for _fs_r: int in range(GameState.GRID_SIZE):
		for _fs_c: int in range(GameState.GRID_SIZE):
			var _fs_card: GameState.CardInstance = GameState.get_card(_opp_for_foe_start, _fs_r, _fs_c)
			if _fs_card.card_type != "character" or not _fs_card.face_up:
				continue
			if _fs_card.ability_type != CharacterData.AbilityType.LIMIT_FOE_ATTACKS_COIN_FLIP_ONCE:
				continue
			if "limit_foe_attacks_used" in _fs_card.flags:
				continue
			await await_card_effect_flash(_fs_card.card_name)
			var _lfa_cf: Array = await _do_coin_flips(1, _opp_for_foe_start, _fs_r, _fs_c)
			_fs_card.flags.append("limit_foe_attacks_used")
			if _lfa_cf[0]:
				GameState.attacks_remaining = mini(GameState.attacks_remaining, 1)
				GameState.post_message(
					"%s: Heads — Player %d can only attack once this turn!" % [
						_fs_card.card_name, player_index + 1])
			else:
				GameState.post_message("%s: Tails — no effect." % _fs_card.card_name)

	# Handle skip turn (Ceasefire)
	if GameState.skip_next_turn[player_index]:
		GameState.skip_next_turn[player_index] = false
		GameState.post_message("Player %d's turn is skipped!" % (player_index + 1))
		_end_turn(player_index)
		return

	# Apply end-of-turn permanent boosts for Hyperspeed Saucer (from previous turn)
	await _apply_end_of_turn_boosts(player_index)

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

	if mode == GameState.TurnMode.ATTACK and not GameState.can_player_attack(player):
		GameState.post_message("Player %d has no units that can attack." % (player + 1))
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
	emit_signal("attack_phase_started", player, GameState.attacks_remaining)
	GameState.post_message("Player %d: tap a unit to attack." % (player + 1))

func _battle_aborted() -> bool:
	return GameState.current_phase == GameState.Phase.GAME_OVER


func _reveal_for_attack(player_index: int, row: int, col: int) -> void:
	if GameState.get_card(player_index, row, col).face_up:
		return
	var key := Vector3i(player_index, row, col)
	if key not in _attack_reveal_pending:
		_attack_reveal_pending.append(key)
	GameState.reveal_card(player_index, row, col)


func _await_attack_reveal_animations() -> void:
	while not _attack_reveal_pending.is_empty():
		await card_reveal_animation_done


func notify_card_reveal_animation_done(player_index: int, row: int, col: int) -> void:
	var key := Vector3i(player_index, row, col)
	if key == _standalone_reveal_wait:
		_standalone_reveal_wait = Vector3i(-1, -1, -1)
		card_reveal_animation_done.emit()
		return
	if key not in _attack_reveal_pending:
		return
	_attack_reveal_pending.erase(key)
	card_reveal_animation_done.emit()


func _await_standalone_reveal_animation(player_index: int, row: int, col: int) -> void:
	_standalone_reveal_wait = Vector3i(player_index, row, col)
	await card_reveal_animation_done


## Reveal a hidden card so the opponent can see it, wait for flip animation, then pause briefly.
func _witness_card(player_index: int, row: int, col: int) -> void:
	var card: GameState.CardInstance = GameState.get_card(player_index, row, col)
	if card.card_type != "character" or card.face_up:
		return
	GameState.reveal_card(player_index, row, col)
	await _await_standalone_reveal_animation(player_index, row, col)


func _witness_pause() -> void:
	await get_tree().create_timer(WITNESS_VIEW_DELAY).timeout


func _should_play_wait_badge_animation(player_index: int, row: int, col: int) -> bool:
	if player_index != GameState.current_player:
		return false
	var card: GameState.CardInstance = GameState.get_card(player_index, row, col)
	return card != null \
		and card.card_type == "character" \
		and card.attacked_this_turn \
		and not card.was_destroyed


func _await_wait_badge_animation(player_index: int, row: int, col: int) -> void:
	if not _should_play_wait_badge_animation(player_index, row, col):
		return
	emit_signal("wait_badge_animation_requested", player_index, row, col)
	await wait_badge_animation_done


func perform_attack(attacker_pos: Vector2i, target_pos: Vector2i, attacker_player: int = -1) -> void:
	if _battle_aborted():
		return
	var player := attacker_player if attacker_player >= 0 else GameState.current_player
	var opponent := GameState.get_opponent(player)

	if GameState.current_phase not in [GameState.Phase.MODE_SELECT, GameState.Phase.ATTACK]:
		return

	var attacker := GameState.get_card(player, attacker_pos.x, attacker_pos.y)
	var defender := GameState.get_card(opponent, target_pos.x, target_pos.y)

	if attacker.card_type != "character":
		GameState.post_message("You must attack with a Unit.")
		emit_signal("attack_aborted")
		return
	if attacker.attacked_this_turn:
		GameState.post_message("%s has already attacked this turn." % attacker.card_name)
		emit_signal("attack_aborted")
		return
	if GameState.attacks_remaining <= 0 and not attacker.has_pending_bonus_attack_chain():
		GameState.post_message("No attacks remaining this turn.")
		emit_signal("attack_aborted")
		return
	if attacker.cannot_attack_until >= GameState.turn_number:
		GameState.post_message("%s cannot attack yet." % attacker.card_name)
		emit_signal("attack_aborted")
		return

	var _target_check: Dictionary = BattleResolver.validate_attack_target(
		player, attacker_pos, attacker, opponent, target_pos, defender)
	if not _target_check.get("ok", false):
		GameState.post_message(_target_check.get("reason", "Invalid attack target."))
		emit_signal("attack_aborted")
		return

	if GameState.attack_cost_block_player == player \
			and GameState.attack_cost_block_max >= 0 \
			and attacker.crystal_cost <= GameState.attack_cost_block_max:
		GameState.post_message(
			"Decoy Puppet: Units costing %d or less cannot attack this turn." % GameState.attack_cost_block_max)
		emit_signal("attack_aborted")
		return

	# Berserk: only berserk card can attack
	if GameState.berserk_active[player] != null:
		if GameState.berserk_active[player] != attacker:
			GameState.post_message("Only the Berserk unit can attack!")
			emit_signal("attack_aborted")
			return

	# Pre-battle: CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD (Keeper of the Sun)
	if attacker.ability_type == CharacterData.AbilityType.CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD:
		var _allowed: Array = attacker.ability_params.get("allowed", [])
		for _cs_r: int in range(GameState.GRID_SIZE):
			for _cs_c: int in range(GameState.GRID_SIZE):
				var _cs_ally: GameState.CardInstance = GameState.get_card(player, _cs_r, _cs_c)
				if _cs_ally == attacker or _cs_ally.card_type != "character" or not _cs_ally.face_up:
					continue
				if _cs_ally.affinity not in _allowed:
					GameState.post_message("%s cannot attack — non-allowed affinity on own field!" % attacker.card_name)
					emit_signal("attack_aborted")
					return

	# Pre-battle: COIN_FLIP_CANCEL_ATTACK (Lazy Troll) — tails = own attack cancelled
	if attacker.ability_type == CharacterData.AbilityType.COIN_FLIP_CANCEL_ATTACK:
		# Reveal Lazy Troll face-up before the coin flip so the player sees who is flipping
		if not attacker.face_up:
			GameState.reveal_card(player, attacker_pos.x, attacker_pos.y)
			await _await_standalone_reveal_animation(player, attacker_pos.x, attacker_pos.y)
		await await_card_effect_flash(attacker.card_name)
		var _cca_results: Array = await _coin_flips_for_card(attacker, 1)
		if not _cca_results[0]:  # tails
			GameState.post_message("%s flips tails — too lazy to attack! It has to wait." % attacker.card_name)
			attacker.attacked_this_turn = true                  # shows hourglass icon on card
			GameState.attacks_remaining = maxi(0, GameState.attacks_remaining - 1)  # wasted attempt
			await _await_wait_badge_animation(player, attacker_pos.x, attacker_pos.y)
			emit_signal("attack_aborted")
			return

	# Pre-battle: INTERCEPT_ALLY_ATTACK (Armored Rhino / Bat Swarm) — may change target before reveals
	if defender.card_type == "character":
		var _ic_found: bool = false
		for _ic_r: int in range(GameState.GRID_SIZE):
			if _ic_found:
				break
			for _ic_c: int in range(GameState.GRID_SIZE):
				if Vector2i(_ic_r, _ic_c) == target_pos:
					continue
				var _ic_cand: GameState.CardInstance = GameState.get_card(opponent, _ic_r, _ic_c)
				if _ic_cand.card_type == "character" \
						and _ic_cand.ability_type == CharacterData.AbilityType.INTERCEPT_ALLY_ATTACK:
					var _ic_aff: int = _ic_cand.ability_params.get("affinity", -1)
					if _ic_aff == -1 or _ic_aff == defender.affinity:
						await _witness_card(opponent, _ic_r, _ic_c)
						await _witness_pause()
						await await_card_effect_flash(_ic_cand.card_name)
						emit_signal("awaiting_defender_choice",
							"%s can intercept for %s!" % [_ic_cand.card_name, defender.card_name],
							["Intercept", "Don't Intercept"])
						var _ic_choice: int = await ability_choice_resolved
						if _ic_choice == 0:
							target_pos = Vector2i(_ic_r, _ic_c)
							defender = _ic_cand
						_ic_found = true
						break

	# Dungeon: Weapon Tax (100) and Frenzy Madness (200) per-attack crystal cost
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON:
		var _mods_tax: Array = GameState.active_dungeon_modifiers
		var _atk_tax: int = 0
		if "weapon_tax" in _mods_tax: _atk_tax += 100
		if "frenzy_madness" in _mods_tax: _atk_tax += 200
		if _atk_tax > 0:
			GameState.lose_crystals(player, _atk_tax, "attack tax")
			await _wait_crystal_animation()

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

	# Exposed = already face-up BEFORE this attack began.
	var defender_was_exposed: bool = defender.face_up

	# Methanomancer: adjacent cell targeted → flip face-up + temp ATK/DEF
	for _mn_p: int in range(2):
		for _mn_r: int in range(GameState.GRID_SIZE):
			for _mn_c: int in range(GameState.GRID_SIZE):
				var _mn_card: GameState.CardInstance = GameState.get_card(_mn_p, _mn_r, _mn_c)
				if _mn_card.card_type != "character" \
						or _mn_card.ability_type != CharacterData.AbilityType.ADJACENT_ATTACK_FLIP_BUFF:
					continue
				var _mn_adj: Array = GameState.get_adjacent_positions(_mn_r, _mn_c)
				var _mn_pos: Vector2i = Vector2i(_mn_r, _mn_c)
				if target_pos in _mn_adj:
					await _witness_card(_mn_p, _mn_r, _mn_c)
					await _witness_pause()
					await await_card_effect_flash(_mn_card.card_name)
					_mn_card.temp_atk_bonus += _mn_card.ability_params.get("atk", 30)
					_mn_card.temp_def_bonus += _mn_card.ability_params.get("def", 30)
					GameState.post_message("%s: Surrounding attack — +%d ATK&DEF!" % [
						_mn_card.card_name,
						_mn_card.ability_params.get("atk", 30)])

	# Flip cards face-up now so the player sees revealed stats while deciding on optional prompts
	_attack_reveal_pending.clear()
	_reveal_for_attack(player, attacker_pos.x, attacker_pos.y)
	if defender.card_type != "dead_end":
		_reveal_for_attack(opponent, target_pos.x, target_pos.y)

	# Update field-based bonuses before battle
	BattleResolver.calculate_field_bonuses(player)
	BattleResolver.calculate_field_bonuses(opponent)

	await maybe_apply_on_expose_reveal_foe(player, attacker_pos.x, attacker_pos.y)
	if defender.card_type != "dead_end":
		await maybe_apply_on_expose_reveal_foe(opponent, target_pos.x, target_pos.y)

	var _wk17_out: Dictionary = await _apply_wk17_pre_battle(
		player, opponent, attacker, defender, attacker_pos, target_pos, defender_was_exposed)
	if _wk17_out.get("abort", false):
		emit_signal("attack_aborted")
		return
	target_pos = _wk17_out.get("target_pos", target_pos)
	defender_was_exposed = _wk17_out.get("defender_was_exposed", defender_was_exposed)
	defender = GameState.get_card(opponent, target_pos.x, target_pos.y)

	var _rg_out: Dictionary = await _apply_rift_guardian_pre_battle(
		player, opponent, attacker, defender, attacker_pos, target_pos)
	if _rg_out.get("abort", false):
		emit_signal("attack_aborted")
		return
	if _rg_friendly_fire and _rg_friendly_fire_pos != Vector2i(-1, -1):
		var _rg_ff_pos: Vector2i = _rg_friendly_fire_pos
		_rg_friendly_fire = false
		_rg_friendly_fire_pos = Vector2i(-1, -1)
		await resolve_rift_guardian_substitute(player, _rg_ff_pos, target_pos)
		return

	if _wk17_friendly_fire and _wk17_friendly_fire_pos != Vector2i(-1, -1):
		var _wk17_ff_pos: Vector2i = _wk17_friendly_fire_pos
		_wk17_friendly_fire = false
		_wk17_friendly_fire_pos = Vector2i(-1, -1)
		await resolve_brainwash_friendly_fire(player, _wk17_ff_pos)
		return

	if _wk17_substitute_battle \
			and _wk17_substitute_attacker_pos != Vector2i(-1, -1) \
			and _wk17_substitute_defender_pos != Vector2i(-1, -1):
		var _wk17_sub_att: Vector2i = _wk17_substitute_attacker_pos
		var _wk17_sub_def: Vector2i = _wk17_substitute_defender_pos
		var _wk17_sub_grid: int = _wk17_substitute_grid_player
		var _wk17_init_att: Vector2i = _wk17_initiating_attacker_pos
		_clear_wk17_substitute_state()
		await resolve_wk17_substitute_battle(player, _wk17_sub_grid, _wk17_sub_att, _wk17_sub_def, _wk17_init_att)
		return

	# OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT (X-Death Squad) — before overlay since it may abort
	if attacker.ability_type == CharacterData.AbilityType.OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT \
			and defender.card_type == "character":
		var _xd_cost: int = attacker.ability_params.get("cost", 1000)
		if GameState.crystals[player] >= _xd_cost:
			emit_signal("awaiting_trap_choice",
				"Pay %d Crystals to destroy %s? (no crystal loss to opponent)" % [_xd_cost, defender.card_name],
				["Pay %d Crystals" % _xd_cost, "Skip"])
			var _xd_choice: int = await ability_choice_resolved
			if _xd_choice == 0:
				GameState.lose_crystals(player, _xd_cost, "ability")
				await _wait_crystal_animation()
				GameState.post_message("%s: %s is destroyed!" % [attacker.card_name, defender.card_name])
				GameState.place_dead_end(opponent, target_pos.x, target_pos.y)
				emit_signal("attack_aborted")
				return

	GameState.defender_pos = target_pos
	GameState.set_phase(GameState.Phase.BATTLE)

	# Wait for attacker/defender flip animations before Reckoning overlay.
	if defender.card_type == "dead_end" and not defender_was_exposed:
		_reveal_for_attack(opponent, target_pos.x, target_pos.y)
		defender = GameState.get_card(opponent, target_pos.x, target_pos.y)
	await _await_attack_reveal_animations()

	if GameState.attacker_card != null \
			and GameState.attacker_card.card_type == "character" \
			and not GameState.attacker_card.was_destroyed:
		attacker = GameState.attacker_card
		attacker_pos = GameState.attacker_pos
	else:
		attacker = GameState.get_card(player, attacker_pos.x, attacker_pos.y)
	var _nuki_out: Dictionary = await _apply_nuki_pre_reckoning(player, attacker, attacker_pos, true)
	attacker = _nuki_out.get("card", attacker) as GameState.CardInstance
	attacker_pos = _nuki_out.get("pos", attacker_pos)
	GameState.attacker_card = attacker
	GameState.attacker_pos = attacker_pos

	if defender.card_type != "dead_end":
		defender = GameState.get_card(opponent, target_pos.x, target_pos.y)
		var _nuki_def_out: Dictionary = await _apply_nuki_pre_reckoning(
			opponent, defender, target_pos, false)
		target_pos = _nuki_def_out.get("pos", target_pos)
		defender = _nuki_def_out.get("card", defender) as GameState.CardInstance
		GameState.defender_pos = target_pos

	# Roll dice after Nuki swap (coin flip + optional reposition) and before Reckoning overlay.
	GameState.dice_result = DiceRoller.roll_attack_dice()
	GameState.emit_signal("dice_rolled", GameState.dice_result)
	if GameState.reroll_dice_available[player]:
		GameState.reroll_dice_available[player] = false
		emit_signal("awaiting_trap_choice",
			"Lucky Break: Re-roll dice? (current: %d)" % GameState.dice_result,
			["Re-roll", "Keep %d" % GameState.dice_result])
		var _rr_choice: int = await ability_choice_resolved
		if _rr_choice == 0:
			GameState.dice_result = DiceRoller.roll_attack_dice()
			GameState.emit_signal("dice_rolled", GameState.dice_result)
			GameState.post_message("Lucky Break: Re-rolled — new result: %d" % GameState.dice_result)

	var _pre_shown_reckoning_coins: Array = await _maybe_flip_reckoning_attacker_coins(attacker)
	if not _pre_shown_reckoning_coins.is_empty():
		BattleResolver.set_predetermined_coin_flips(_pre_shown_reckoning_coins)

	if defender.ability_type == CharacterData.AbilityType.NULLIFY_FOE_ABILITY_IN_RECKONING \
			and attacker.effect_nullified_until < GameState.turn_number:
		attacker.effect_nullified_until = 999999
		GameState.post_message("%s: %s's ability nullified in Reckoning!" % [defender.card_name, attacker.card_name])
	if attacker.ability_type == CharacterData.AbilityType.NULLIFY_FOE_ABILITY_IN_RECKONING \
			and defender.effect_nullified_until < GameState.turn_number:
		defender.effect_nullified_until = 999999
		GameState.post_message("%s: %s's ability nullified in Reckoning!" % [attacker.card_name, defender.card_name])

	BattleResolver.apply_swap_atk_def_when_attacking(attacker)

	# Compute a preview result (without optional crystal boosts) for the battle overlay display.
	# silent=true prevents ability messages from firing twice (they fire again on the real resolve).
	var preview_result := BattleResolver.resolve_battle(
		attacker, defender, GameState.dice_result, player, opponent, defender_was_exposed, target_pos, true
	)

	# Show the battle overlay — optional prompts will appear on top of it
	emit_signal("battle_preview_needed", player, attacker, defender, preview_result)

	# OPTIONAL_CRYSTAL_PAY_ATK_BOOST (Gryphon / Hairpin Assassin / Silver Dragon) — on top of battle overlay
	if attacker.ability_type == CharacterData.AbilityType.OPTIONAL_CRYSTAL_PAY_ATK_BOOST:
		var _pb_cost: int = attacker.ability_params.get("cost", 300)
		var _pb_boost: int = attacker.ability_params.get("atk", 5)
		var _pb_mandatory: bool = attacker.ability_params.get("mandatory", false)
		if _pb_mandatory or GameState.crystals[player] >= _pb_cost:
			if _pb_mandatory and GameState.crystals[player] < _pb_cost:
				GameState.post_message("%s: Cannot pay %d Crystals — attack cancelled!" % [attacker.card_name, _pb_cost])
				emit_signal("battle_resolved", preview_result)
				return
			if _pb_mandatory:
				GameState.lose_crystals(player, _pb_cost, "ability")
				await _wait_crystal_animation()
				GameState.post_message("%s: Paid %d Crystals to attack!" % [attacker.card_name, _pb_cost])
			elif GameState.crystals[player] >= _pb_cost:
				emit_signal("awaiting_trap_choice",
					"Pay %d Crystals for +%d ATK this battle?" % [_pb_cost, _pb_boost],
					["Pay %d Crystals" % _pb_cost, "Skip"])
				var _pb_choice: int = await ability_choice_resolved
				if _pb_choice == 0:
					GameState.lose_crystals(player, _pb_cost, "ability")
					await _wait_crystal_animation()
					attacker.temp_atk_bonus += _pb_boost
					GameState.post_message("%s: Paid %d Crystals for +%d ATK!" % [attacker.card_name, _pb_cost, _pb_boost])

	# OPTIONAL_CRYSTAL_PAY_DEF_BOOST (Armored Dino) — defender ability: fires when defending
	# Uses awaiting_defender_choice so the decision routes to the defending player
	if defender.card_type == "character" \
			and defender.ability_type == CharacterData.AbilityType.OPTIONAL_CRYSTAL_PAY_DEF_BOOST:
		var _dd_cost: int = defender.ability_params.get("cost", 1000)
		var _dd_boost: int = defender.ability_params.get("def", 60)
		if GameState.crystals[opponent] >= _dd_cost:
			emit_signal("awaiting_defender_choice",
				"%s: Pay %d Crystals for +%d DEF this battle?" % [defender.card_name, _dd_cost, _dd_boost],
				["Pay %d Crystals" % _dd_cost, "Skip"])
			var _dd_choice: int = await ability_choice_resolved
			if _dd_choice == 0:
				GameState.lose_crystals(opponent, _dd_cost, "ability")
				await _wait_crystal_animation()
				defender.temp_def_bonus += _dd_boost
				GameState.post_message("%s: Paid %d Crystals for +%d DEF!" % [defender.card_name, _dd_cost, _dd_boost])

	# Recompute with any applied temp bonuses and post final battle messages
	BattleResolver.reset_predetermined_coin_flip_index()
	var result := BattleResolver.resolve_battle(
		attacker, defender, GameState.dice_result, player, opponent, defender_was_exposed, target_pos
	)
	BattleResolver.clear_predetermined_coin_flips()
	# Pills freeze at preview time; badge/mod reflect the final resolve.
	BattleResolver.copy_reckoning_pills_from(preview_result, result)
	# Capture card names before any destruction so loggers that fire after destroy_card() can use them
	result.attacker_name = attacker.card_name
	result.defender_name = defender.card_name
	result.attacker_log_label = BattleLogFormat.format_unit(attacker)
	if defender.card_type == "character":
		result.defender_log_label = BattleLogFormat.format_unit(defender)
	elif defender.card_type == "trap":
		result.defender_log_label = BattleLogFormat.format_card(defender)
	for msg in result.messages:
		GameState.post_message(msg)
	_log_reckoning_ability_triggers(attacker, defender, result)

	# Force Shield: if the defender would be destroyed but is shielded, block the destruction
	if result.defender_destroyed and defender.card_type == "character" and defender.force_shielded:
		result.defender_destroyed = false
		result.defender_crystal_loss = 0
		result.destruction_blocked_defender = true
		defender.force_shielded = false
		GameState.post_message("Force Shield: %s blocked the attack!" % defender.card_name)

	# Divine Protection (attacker) — pre-apply before the overlay reads the result so the
	# Reckoning animation reflects the protected outcome (no shatter for the Divine unit).
	if result.attacker_destroyed and attacker.card_type == "character" \
			and GameState.divine_protection_active[player] \
			and attacker.affinity == CharacterData.Affinity.DIVINE:
		result.attacker_destroyed = false
		result.attacker_crystal_loss = 0
		result.destruction_blocked_attacker = true
		GameState.divine_protection_active[player] = false
		GameState.post_message("Prayer protected %s!" % attacker.card_name)

	# Divine Protection (defender) — same pre-apply so overlay shows correct outcome.
	if result.defender_destroyed and defender.card_type == "character" \
			and GameState.divine_protection_active[opponent] \
			and defender.affinity == CharacterData.Affinity.DIVINE:
		result.defender_destroyed = false
		result.defender_crystal_loss = 0
		result.destruction_blocked_defender = true
		GameState.divine_protection_active[opponent] = false
		GameState.post_message("Prayer protected %s!" % defender.card_name)

	_apply_princess_magic_reckoning(
		player, opponent, attacker, defender, result)

	_preview_destruction_survival(
		result, attacker, defender, player, opponent, attacker_pos, target_pos)

	await _maybe_resolve_sacrifice_for_card_type(
		result, player, opponent, attacker_pos, target_pos, attacker, defender)
	if _battle_aborted():
		return

	# Show coin flip visual for any flips that happened inside BattleResolver
	if not result.coin_flip_results.is_empty() and _pre_shown_reckoning_coins.is_empty():
		emit_signal("coin_flip_visual_requested", result.coin_flip_results)
		await coin_flip_visual_done
		if _battle_aborted():
			return

	# Signal the overlay to update its animation to match the final result, then resume
	emit_signal("battle_result_finalized", result)
	await battle_preview_done
	if _battle_aborted():
		return

	var _attack_completed_emitted := false

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
			if GameState.guerrilla_tactics_owner == opponent:
				var _gt_cf: Array = await _do_coin_flips(1)
				GameState.post_message("Guerrilla Tactics: %s." % ("Heads" if _gt_cf[0] else "Tails"))
				if _gt_cf[0]:
					GameState.lose_crystals(player, attacker.crystal_cost, "card lost")
					await _wait_crystal_animation()
					GameState.destroy_card(player, attacker_pos.x, attacker_pos.y, false)
					GameState.post_message("Guerrilla Tactics: %s destroyed!" % attacker.card_name)
					if not _battle_aborted():
						GameState.set_phase(GameState.Phase.MODE_SELECT)
					return
			# Blank slot hit — destroy directly, skip battle resolution (nothing to resolve)
			GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
			# Dungeon: Mining Tax and Hard Bang on dead-end attacks
			if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON:
				var _de_mods: Array = GameState.active_dungeon_modifiers
				if "mining_tax" in _de_mods:
					GameState.lose_crystals(player, 500, "mining tax")
					GameState.post_message("Mining Tax: lost 500 Crystals hitting a dead end.")
					await _wait_crystal_animation()
				if "hard_bang" in _de_mods:
					var _hb_loss: int = max(1, int(attacker.current_atk * 0.2))
					attacker.current_atk = max(0, attacker.current_atk - _hb_loss)
					GameState.post_message("Hard Bang: %s loses %d ATK permanently." % [attacker.display_name, _hb_loss])
			CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_ATTACK_DEAD_END_DONE,
				{"source_player": player, "source_card": attacker, "attacker": attacker})
			if GameState.opponent_crystal_on_dead_end > 0 \
					and GameState.opponent_crystal_on_dead_end_owner == player:
				var _oc_amt: int = GameState.opponent_crystal_on_dead_end
				GameState.gain_crystals(opponent, _oc_amt, "tech")
				GameState.post_message(
					"Compensation: Player %d gains %d Crystals for the dead-end attack!" % [
						opponent + 1, _oc_amt])
				await _wait_crystal_animation()
		else:
			# Fire PRE_RESOLVE chain, then resolve and apply
			CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_PRE_RESOLVE,
				{"source_player": player, "attacker": attacker, "defender": defender,
				 "dice_roll": GameState.dice_result})
			CardRuleEngine.resolve_chain(
				{"source_player": player, "attacker": attacker, "defender": defender})

			_apply_reckoning_perm_stat_penalties(attacker, defender)
			await _apply_battle_result(result, player, opponent, attacker_pos, target_pos, attacker, defender)
			if _battle_aborted():
				emit_signal("attack_completed", attacker_pos, target_pos, result)
				_attack_completed_emitted = true
				return

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

	# Post-battle ability effects — must run before modifying attacked_this_turn
	var _pb_extra: int = await _apply_post_battle_effects(result, player, opponent, attacker, defender, attacker_pos, target_pos)
	if _battle_aborted():
		return

	# MULTI_ATTACK_VS_NON_CHARACTER: allow this card to keep attacking non-char cells within limit
	# MULTI_ATTACK_ANY / MULTI_ATTACK_ANY_WITH_ATK_LOSS: allow multiple attacks any target
	var _skip_mark: bool = false
	var _consume_attack_slot: int = 1
	if attacker.ability_type == CharacterData.AbilityType.MULTI_ATTACK_VS_NON_CHARACTER \
			and defender.card_type != "character":
		attacker.multi_attack_count += 1
		var _chain_limit: int = attacker.get_multi_attack_non_char_chain_limit()
		if attacker.multi_attack_count < _chain_limit:
			_skip_mark = true
			# First non-char hit uses a turn attack; chain continuations do not.
			if attacker.multi_attack_count > 1:
				_consume_attack_slot = 0
	elif attacker.ability_type in [
			CharacterData.AbilityType.MULTI_ATTACK_ANY,
			CharacterData.AbilityType.MULTI_ATTACK_ANY_WITH_ATK_LOSS] \
			and not result.attacker_destroyed:
		var _ma_max2: int = attacker.ability_params.get("max_attacks", 2)
		if attacker.multi_attack_count < _ma_max2:
			_skip_mark = true
	elif _pb_extra > 0:
		attacker.bonus_attack_pending = true
		_skip_mark = true

	if not _skip_mark:
		attacker.attacked_this_turn = true
		if attacker.ability_type == CharacterData.AbilityType.MUTAGEN_IMMEDIATE_ATTACK \
				and attacker.has_mutagen_flag:
			attacker.mutagen_attacked = true
		attacker.bonus_attack_pending = false
		await _await_wait_badge_animation(player, attacker_pos.x, attacker_pos.y)

	attacker.last_attack_target = target_pos

	GameState.attacks_remaining = maxi(0, GameState.attacks_remaining - _consume_attack_slot + _pb_extra)
	if _consume_attack_slot > 0:
		GameState.attacks_used_this_turn += 1

	if not _attack_completed_emitted:
		emit_signal("attack_completed", attacker_pos, target_pos, result)

	# Post-attack target selection before MODE_SELECT so AI turn continuation cannot
	# advance current_player while the attacker still chooses reveal targets.
	if not _battle_aborted():
		await _emit_post_attack_target_selections(result, player, opponent, attacker, defender, attacker_pos, target_pos)

	# Return to mode select before Siege Cannon / follow-ups so non-attack destroys still log.
	if not _battle_aborted():
		GameState.set_phase(GameState.Phase.MODE_SELECT)

	# Check Pit Lord one_use_def_boost mark
	if defender.ability_type == CharacterData.AbilityType.ONE_USE_DEF_BOOST:
		defender.one_use_def_boost_used = true

	# Check Siege Cannon
	if GameState.siege_cannon_active[player]:
		if defender.card_type == "character" and not result.defender_destroyed:
			GameState.post_message(
				"Siege Cannon: %s at (%d,%d) destroyed after surviving the attack!" % [
					defender.card_name, target_pos.x, target_pos.y])
			GameState.mark_destroy_achievement_context(
				"tech", player, opponent, target_pos.x, target_pos.y)
			GameState.destroy_card(opponent, target_pos.x, target_pos.y)
			await _wait_crystal_animation()
			GameState.siege_cannon_active[player] = false

func end_attacks_early() -> void:
	if _battle_aborted():
		return
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

	# Gemina the Supreme Queen: block tech while exposed
	for _gt_p: int in range(2):
		for _gt_r: int in range(GameState.GRID_SIZE):
			for _gt_c: int in range(GameState.GRID_SIZE):
				var _gt_u: GameState.CardInstance = GameState.get_card(_gt_p, _gt_r, _gt_c)
				if _gt_u.is_union and _gt_u.face_up \
						and _gt_u.ability_type == CharacterData.AbilityType.IMMUNE_TO_TRAPS \
						and _gt_u.ability_params.get("block_tech_both_sides", false):
					GameState.post_message("%s: Tech cannot be used while this union is exposed!" % _gt_u.card_name)
					return

	var data = CardDatabase.get_tech(tech_name) as TechCardData
	if data == null:
		GameState.post_message("Unknown Tech Card: %s" % tech_name)
		return

	if not tech_name in GameState.tech_hands[player]:
		GameState.post_message("You don't have %s." % tech_name)
		return

	# Compute effective tech cost (dungeon modifiers)
	var _eff_tech_cost: int = data.crystal_cost
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON:
		var _tm: Array = GameState.active_dungeon_modifiers
		if "tech_broker" in _tm: _eff_tech_cost = 0
		elif "tech_dealer" in _tm: _eff_tech_cost = int(_eff_tech_cost * 0.5)
		if "intelligence_tax" in _tm: _eff_tech_cost += 500

	if GameState.crystals[player] < _eff_tech_cost:
		GameState.post_message("Not enough Crystals to play %s." % tech_name)
		return

	# Check chain requirement
	if data.required_prior_card != "":
		if not GameState.tech_name_played_this_game(player, data.required_prior_card):
			GameState.post_message("%s requires %s to have been played first." % [tech_name, data.required_prior_card])
			return

	# Pay cost
	GameState.lose_crystals(player, _eff_tech_cost, "tech cost")
	await _wait_crystal_animation()
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

	# TEMP_BOOST_ON_OPP_TECH: opponent's cards get a permanent ATK/DEF boost when player plays tech
	var _tech_opp: int = GameState.get_opponent(player)
	for _tbt_r: int in range(GameState.GRID_SIZE):
		for _tbt_c: int in range(GameState.GRID_SIZE):
			var _tbt_card: GameState.CardInstance = GameState.get_card(_tech_opp, _tbt_r, _tbt_c)
			if _tbt_card.card_type == "character" \
					and _tbt_card.ability_type == CharacterData.AbilityType.TEMP_BOOST_ON_OPP_TECH:
				var _tbt_atk: int = _tbt_card.ability_params.get("atk", 5)
				var _tbt_def: int = _tbt_card.ability_params.get("def", 5)
				await _witness_card(_tech_opp, _tbt_r, _tbt_c)
				await _witness_pause()
				await await_card_effect_flash(_tbt_card.card_name)
				_tbt_card.perm_atk_bonus += _tbt_atk
				_tbt_card.perm_def_bonus += _tbt_def
				GameState.post_message("%s: +%d ATK & +%d DEF permanently!" % [
					_tbt_card.card_name, _tbt_atk, _tbt_def])

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
			emit_signal("awaiting_target_selection", "Tease: Choose 1 of your face-down units to reveal.", "self_squares_1_opponent_turn")

		TechCardData.TechEffectType.OPPONENT_REVEALS_OR_GAINS:
			emit_signal("awaiting_target_selection", "Bribe: Reveal a creature for 700 Crystals or pass.", "bribe")

		TechCardData.TechEffectType.BOTH_SKIP_TURN:
			GameState.skip_next_turn[0] = true
			GameState.skip_next_turn[1] = true
			GameState.skip_counts[0] += 1
			GameState.skip_counts[1] += 1
			GameState.post_message("Ceasefire! Both players skip their next turn (attack tax applies).")
			_end_turn(player)
			return

		TechCardData.TechEffectType.BOTH_LOCK_CHOSEN_MONSTER:
			emit_signal("awaiting_target_selection", "Make Friend: Choose 1 of your monsters to lock.", "lock_own_monster")

		TechCardData.TechEffectType.ADD_MUTAGEN_FLAG:
			emit_signal("awaiting_target_selection", "Release Mutagen: Choose 1 of your units to flag.", "own_faceup_character")

		TechCardData.TechEffectType.DIVINE_PROTECTION:
			var _dp_tokens: Array = _tech_name_tokens(data)
			if not _dp_tokens.is_empty():
				GameState.destruction_immune_name_tokens.append({
					"owner": player,
					"tokens": _dp_tokens,
				})
				GameState.post_message(
					"%s: Matching units cannot be destroyed until foe's turn ends." % data.card_name)
			else:
				GameState.divine_protection_active[player] = true
				GameState.post_message("Prayer: Divine Units protected until opponent's turn ends.")
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.DESTROY_ALL_REVEALED_OPPONENT:
			_resolve_arcane_nova(player)
			return

		TechCardData.TechEffectType.DESTROY_ROW_OR_COLUMN:
			emit_signal("awaiting_target_selection", "Rift Strike: Choose a row or column.", "row_or_column")

		TechCardData.TechEffectType.DESTROY_ROW_AROUND_TARGET:
			emit_signal("awaiting_target_selection",
				"Rift Strike: Choose 1 face-up opponent unit.", "rift_strike_anchor")

		TechCardData.TechEffectType.GUERRILLA_TACTICS:
			GameState.guerrilla_tactics_owner = player
			GameState.post_message(
				"Guerrilla Tactics active until end of opponent's turn — dead-end attacks may backfire.")
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.LIMIT_FOE_ATTACKS_NEXT_TURN:
			var _lf_max: int = int(data.effect_params.get("max_attacks", 1))
			GameState.attack_cap_next_turn[GameState.get_opponent(player)] = _lf_max
			GameState.post_message(
				"%s: Player %d can attack at most %d time(s) next turn!" % [
					data.card_name, GameState.get_opponent(player) + 1, _lf_max])
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.OPPONENT_CRYSTAL_GAIN_ON_DEAD_END:
			var _oc_amt2: int = int(data.effect_params.get("amount", 20))
			GameState.opponent_crystal_on_dead_end = _oc_amt2
			GameState.opponent_crystal_on_dead_end_owner = player
			GameState.post_message(
				"%s: Foe gains %d Crystals per dead-end attack this turn!" % [data.card_name, _oc_amt2])
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.REVEAL_ALL_OWN_CHARACTERS:
			var _gd_count: int = maxi(1, int(data.effect_params.get("count", 5)))
			emit_signal("awaiting_target_selection",
				"Select up to %d of your units and reveal them." % _gd_count,
				"own_units_up_to_%d" % _gd_count)
			return

		TechCardData.TechEffectType.PERM_BOOST_ALL_FACEUP:
			_boost_all_faceup(player, data.effect_params.get("atk", 0), data.effect_params.get("def", 0))
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.PERM_ATK_BOOST_ONE, \
		TechCardData.TechEffectType.PERM_DEF_BOOST_ONE, \
		TechCardData.TechEffectType.TEMP_ATK_BOOST_ATTACK_NOW:
			if not _tech_name_tokens(data).is_empty():
				emit_signal("awaiting_target_selection",
					"Choose 1 of your matching units.", "own_faceup_name_character")
			else:
				emit_signal("awaiting_target_selection", "Choose 1 of your units to boost.", "own_faceup_character")

		TechCardData.TechEffectType.TEMP_DEF_BOOST_ALL:
			var _garrison_def: int = data.effect_params.get("def", 0)
			_temp_boost_all(player, 0, _garrison_def, true)
			GameState.post_message("%s: All face-up units gain +%d DEF until end of next turn." % [data.card_name, _garrison_def])
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.TEMP_ATK_DEF_BOOST_ALL:
			var _ws_atk: int = data.effect_params.get("atk", 0)
			var _ws_def: int = data.effect_params.get("def", 0)
			_temp_boost_all(player, _ws_atk, _ws_def, false)
			GameState.post_message("%s: All face-up units gain +%d ATK & DEF until end of turn." % [data.card_name, _ws_atk])
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

		TechCardData.TechEffectType.DESTROY_VENOM_DOUBLE_COST:
			emit_signal("awaiting_target_selection",
				"Potent Poison: Choose 1 card with Venom Flag.", "venom_flagged_card")

		TechCardData.TechEffectType.MULTI_ATTACK_ONE:
			emit_signal("awaiting_target_selection", "Berserk: Choose 1 face-up unit.", "own_faceup_character_berserk")

		TechCardData.TechEffectType.REVEAL_OWN_AND_OPPONENT_REVEALS:
			emit_signal("awaiting_target_selection", "Choose 1 of your face-down units.", "own_facedown_character")

		TechCardData.TechEffectType.MOVE_BUFFS_BETWEEN_CHARACTERS:
			emit_signal("awaiting_target_selection", "Essence Transfer: Choose source unit.", "own_faceup_character_source")

		TechCardData.TechEffectType.DESTROY_OWN_BASE_ZERO_OPPONENT:
			emit_signal("awaiting_target_selection", "Blood Ritual: Choose 1 card on your side to destroy.", "own_faceup_card_sacrifice")

		TechCardData.TechEffectType.CLONE_CHARACTER_AS_TOKEN:
			emit_signal("awaiting_target_selection", "Arcane Duplication: Choose 1 of your units.", "own_faceup_character")

		TechCardData.TechEffectType.REVIVE_CHARACTER_FULL, \
		TechCardData.TechEffectType.REVIVE_CHARACTER_NO_ATK:
			emit_signal("awaiting_target_selection",
				"Choose where to place the revived unit.", "graveyard")

		TechCardData.TechEffectType.VIEW_OPPONENT_TECH:
			emit_signal("awaiting_target_selection", "Tech Copy: View opponent's hand?", "view_opponent_hand")

		TechCardData.TechEffectType.FORCE_SHIELD_ONE_CARD:
			emit_signal("awaiting_target_selection", "Force Shield: Choose 1 of your cards to protect.", "own_any_card")

		TechCardData.TechEffectType.DESTROY_WISPS_REVEAL_OPPONENT:
			var _dwro_opp: int = GameState.get_opponent(player)
			var _wisp_slots: Array = []
			for _dwro_r: int in range(GameState.GRID_SIZE):
				for _dwro_c: int in range(GameState.GRID_SIZE):
					var _dwro_card: GameState.CardInstance = GameState.get_card(player, _dwro_r, _dwro_c)
					if _dwro_card.card_type == "character" \
							and "wisp" in _dwro_card.card_name.to_lower():
						_wisp_slots.append(Vector2i(_dwro_r, _dwro_c))
			if not _wisp_slots.is_empty():
				for _wisp_pos: Vector2i in _wisp_slots:
					await _witness_card(player, _wisp_pos.x, _wisp_pos.y)
					await _witness_pause()
				for _wisp_pos: Vector2i in _wisp_slots:
					GameState.destroy_card(player, _wisp_pos.x, _wisp_pos.y, false)
				var _dwro_hidden: Array = []
				for _dwro_r2: int in range(GameState.GRID_SIZE):
					for _dwro_c2: int in range(GameState.GRID_SIZE):
						var _dwro_hcard: GameState.CardInstance = GameState.get_card(_dwro_opp, _dwro_r2, _dwro_c2)
						if not _dwro_hcard.face_up and _dwro_hcard.card_type != "dead_end":
							_dwro_hidden.append(Vector2i(_dwro_r2, _dwro_c2))
				_dwro_hidden.shuffle()
				var _dwro_revealed: int = 0
				for _dwro_i: int in range(mini(_wisp_slots.size(), _dwro_hidden.size())):
					var _rev_pos: Vector2i = _dwro_hidden[_dwro_i]
					GameState.reveal_card_by_ability(_dwro_opp, _rev_pos.x, _rev_pos.y)
					await _await_standalone_reveal_animation(_dwro_opp, _rev_pos.x, _rev_pos.y)
					await _witness_pause()
					_dwro_revealed += 1
				GameState.post_message("Wisp Light: %d Wisps destroyed, %d squares revealed." % [
					_wisp_slots.size(), _dwro_revealed])
			else:
				GameState.post_message("Wisp Light: No Wisps on your field.")
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.TEMP_REROLL_DICE:
			if data.effect_params.has("coin_reward"):
				var _ld_r: Array = await _do_coin_flips(1)
				if _ld_r[0]:
					var _reward: int = int(data.effect_params.get("coin_reward", 600))
					GameState.gain_crystals(player, _reward, "tech")
					GameState.post_message("%s: Heads! Gained %d Crystals." % [data.card_name, _reward])
					await _wait_crystal_animation()
				else:
					GameState.post_message("%s: Tails — no Crystals gained." % data.card_name)
			else:
				GameState.reroll_dice_available[player] = true
				GameState.post_message("Lucky Break: You may re-roll the dice once before your next attack.")
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.CRYSTAL_GAIN_IF_OWN_NAME_FACE_UP:
			var _med_tokens: Array = _tech_name_tokens(data)
			if not GameState.has_face_up_name_on_field(player, _med_tokens):
				GameState.post_message("%s: No matching face-up unit — no effect." % data.card_name)
			else:
				var _med_gain: int = int(data.effect_params.get("crystal_gain", 0))
				GameState.gain_crystals(player, _med_gain, "tech")
				GameState.post_message("%s: Gained %d Crystals!" % [data.card_name, _med_gain])
				await _wait_crystal_animation()
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.DESTROY_OWN_NAME_FOR_CRYSTALS:
			emit_signal("awaiting_target_selection",
				"Choose 1 of your face-up matching units to recycle.", "own_faceup_name_character")
			return

		TechCardData.TechEffectType.ADD_FLAG_UP_TO:
			var _flag_cap: int = maxi(1, int(data.effect_params.get("count", 1)))
			emit_signal("awaiting_target_selection",
				"Put up to %d flag(s) on your units." % _flag_cap,
				"own_units_flag_up_to_%d" % _flag_cap)
			return

		TechCardData.TechEffectType.CONDITIONAL_DESTROY_FIELD:
			var _db_tokens: Array = _tech_name_tokens(data)
			if not GameState.has_face_up_name_on_field(player, _db_tokens):
				GameState.post_message("%s: No matching face-up unit — no effect." % data.card_name)
				after_tech_resolved(player)
				return
			_field_destroy_remaining = maxi(1, int(data.effect_params.get("destroy_count", 1)))
			_field_destroy_foe_no_cost = bool(data.effect_params.get("foe_no_cost", false))
			emit_signal("awaiting_target_selection",
				"%s: Choose card 1 of %d to destroy on the field." % [
					data.card_name, _field_destroy_remaining],
				"any_field_card_destroy")
			return

		TechCardData.TechEffectType.TEMP_ATK_DEF_BOOST_NAME_FILTER:
			_apply_temp_name_buff_tech(player, data)
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.PROTECT_CORNER_CELLS_UNTIL_FOE_TURN:
			GameState.add_protected_cells(player, _corner_cells_for_player())
			GameState.post_message("%s: Corner cells protected until foe's turn ends." % data.card_name)
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.PROTECT_CELL_UNTIL_FOE_TURN:
			emit_signal("awaiting_target_selection",
				"Safe House: Choose 1 cell on your grid to protect.", "own_cell_protect")
			return

		TechCardData.TechEffectType.DESTROY_ALL_REVIVED_AND_TOKENS:
			_destroy_all_revived_and_tokens()
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.PRINCESS_MAGIC_RECKONING:
			GameState.princess_magic_active[player] = true
			GameState.post_message("Princess Magic active for one Reckoning!")
			after_tech_resolved(player)
			return

		TechCardData.TechEffectType.NOT_IMPLEMENTED:
			GameState.show_center_message("Ability not implemented: " + data.card_name)
			after_tech_resolved(player)

# ─────────────────────────────────────────────────────────────
# Tech helpers
# ─────────────────────────────────────────────────────────────
func _resolve_arcane_nova(player: int) -> void:
	var opponent := GameState.get_opponent(player)
	var limit: int = int(CardDatabase.get_tech("Arcane Nova").effect_params.get("count", 5)) \
		if CardDatabase.get_tech("Arcane Nova") else 5
	var destroyed: int = 0
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			if destroyed >= limit:
				break
			var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
			if card.card_type == "character" and card.face_up:
				GameState.mark_destroy_achievement_context("tech", player, opponent, r, c)
				GameState.destroy_card(opponent, r, c, false)
				destroyed += 1
				await _wait_crystal_animation()
		if destroyed >= limit:
			break
	GameState.tech_hands[player].clear()
	GameState.post_message(
		"Arcane Nova! %d opponent unit(s) destroyed. Your Tech Cards discarded." % destroyed)
	after_tech_resolved(player)

func _boost_all_faceup(player: int, atk_bonus: int, def_bonus: int) -> void:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character" and card.face_up:
				card.perm_atk_bonus += atk_bonus
				card.perm_def_bonus += def_bonus

func _temp_boost_all(player: int, atk_bonus: int, def_bonus: int, carry: bool = false) -> void:
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character" and card.face_up:
				card.temp_atk_bonus += atk_bonus
				if carry:
					card.carry_def_bonus += def_bonus
				else:
					card.temp_def_bonus += def_bonus

# ─────────────────────────────────────────────────────────────
# Apply battle results to game state
# ─────────────────────────────────────────────────────────────
func _preview_destruction_survival(
		result: BattleResolver.BattleResult,
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		player: int,
		opponent: int,
		attacker_pos: Vector2i,
		target_pos: Vector2i
) -> void:
	if result.defender_destroyed and defender.card_type == "character" \
			and GameState.would_block_destruction(opponent, target_pos.x, target_pos.y):
		result.destruction_blocked_defender = true
		result.defender_crystal_loss = 0
	if result.attacker_destroyed and attacker.card_type == "character" \
			and GameState.would_block_destruction(player, attacker_pos.x, attacker_pos.y):
		result.destruction_blocked_attacker = true
		result.attacker_crystal_loss = 0


func _card_has_sacrifice_for_card_type(card: GameState.CardInstance) -> bool:
	if card == null or card.card_type != "character":
		return false
	if card.ability_type == CharacterData.AbilityType.SACRIFICE_FOR_CARD_TYPE:
		return true
	var data: CharacterData = CardDatabase.get_character(card.card_name)
	return data != null and data.ability_type == CharacterData.AbilityType.SACRIFICE_FOR_CARD_TYPE


func _sacrifice_name_filter(card: GameState.CardInstance) -> String:
	if card.ability_type == CharacterData.AbilityType.SACRIFICE_FOR_CARD_TYPE:
		var from_params: String = str(card.ability_params.get("name_contains", ""))
		if not from_params.is_empty():
			return from_params
	var data: CharacterData = CardDatabase.get_character(card.card_name)
	if data != null and data.ability_type == CharacterData.AbilityType.SACRIFICE_FOR_CARD_TYPE:
		return str(data.ability_params.get("name_contains", ""))
	return ""


func _sync_sacrifice_ability_meta(card: GameState.CardInstance) -> void:
	var data: CharacterData = CardDatabase.get_character(card.card_name)
	if data == null or data.ability_type != CharacterData.AbilityType.SACRIFICE_FOR_CARD_TYPE:
		return
	card.ability_type = data.ability_type
	card.ability_params = data.ability_params.duplicate()


## SACRIFICE_FOR_CARD_TYPE — usable face-down; resolve before Reckoning overlay so the
## animation reflects the final destruction outcome.
func _maybe_resolve_sacrifice_for_card_type(
		result: BattleResolver.BattleResult,
		player: int,
		opponent: int,
		attacker_pos: Vector2i,
		target_pos: Vector2i,
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance
) -> void:
	var dying_card: GameState.CardInstance = null
	var dying_pos: Vector2i = Vector2i(-1, -1)
	var field_owner: int = -1
	var use_defender_choice: bool = true
	if result.defender_destroyed and defender.card_type == "character":
		dying_card = defender
		dying_pos = target_pos
		field_owner = opponent
	elif result.attacker_destroyed and attacker.card_type == "character":
		dying_card = attacker
		dying_pos = attacker_pos
		field_owner = player
		use_defender_choice = false
	else:
		return

	var dying_name: String = dying_card.card_name
	for _sac_r: int in range(GameState.GRID_SIZE):
		for _sac_c: int in range(GameState.GRID_SIZE):
			var sac_pos: Vector2i = Vector2i(_sac_r, _sac_c)
			if sac_pos == dying_pos:
				continue
			var sac_cand: GameState.CardInstance = GameState.get_card(field_owner, _sac_r, _sac_c)
			if not _card_has_sacrifice_for_card_type(sac_cand):
				continue
			_sync_sacrifice_ability_meta(sac_cand)
			var sac_name_filter: String = _sacrifice_name_filter(sac_cand)
			if sac_name_filter.is_empty() or sac_name_filter not in dying_name:
				continue
			var sac_label: String = sac_cand.card_name
			await await_card_effect_flash(sac_label)
			var _sac_prompt: String = "%s sacrifices itself to save %s?" % [sac_label, dying_name]
			var _sac_choices: Array = ["Sacrifice", "Let it be destroyed"]
			if use_defender_choice:
				emit_signal("awaiting_defender_choice", _sac_prompt, _sac_choices)
			else:
				emit_signal("awaiting_trap_choice", _sac_prompt, _sac_choices)
			var sac_choice: int = await ability_choice_resolved
			if sac_choice == 0:
				if dying_card == defender:
					result.defender_destroyed = false
					result.defender_crystal_loss = 0
					result.destruction_blocked_defender = false
				elif dying_card == attacker:
					result.attacker_destroyed = false
					result.attacker_crystal_loss = 0
					result.destruction_blocked_attacker = false
				sac_cand = GameState.get_card(field_owner, _sac_r, _sac_c)
				if sac_cand.card_type == "character" and _card_has_sacrifice_for_card_type(sac_cand):
					if not sac_cand.face_up:
						GameState.reveal_card(field_owner, _sac_r, _sac_c)
					GameState.destroy_card(field_owner, _sac_r, _sac_c)
					await _wait_crystal_animation()
					GameState.post_message("%s sacrificed itself to save %s!" % [sac_label, dying_name])
			return


func _apply_battle_result(
		result: BattleResolver.BattleResult,
		player: int,
		opponent: int,
		attacker_pos: Vector2i,
		target_pos: Vector2i,
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance
) -> void:
	if _battle_aborted():
		return
	if result.attacker_crystal_loss > 0:
		# Divine Protection for attacker
		if attacker.card_type == "character" and GameState.divine_protection_active[player]:
			if attacker.affinity == CharacterData.Affinity.DIVINE:
				result.attacker_destroyed = false
				result.attacker_crystal_loss = 0
				GameState.divine_protection_active[player] = false
				GameState.post_message("Prayer protected %s!" % attacker.card_name)
			else:
				GameState.lose_crystals(player, result.attacker_crystal_loss, "battle")
				await _wait_crystal_animation()
		else:
			GameState.lose_crystals(player, result.attacker_crystal_loss, "battle")
			await _wait_crystal_animation()
		if _battle_aborted():
			return

	# Archbishop redirect — defer defender crystal loss; redirect target pays on destroy.
	if result.defender_destroyed and defender.card_type == "character" \
			and defender.ability_type == CharacterData.AbilityType.REDIRECT_DESTRUCTION_TO_ALLY \
			and _has_archbishop_redirect_target(opponent, target_pos):
		emit_signal("awaiting_target_selection",
			"Archbishop: Destroy 1 other Divine Unit instead?",
			"own_divine_character_redirect")
		await archbishop_redirect_resolved
		result.defender_destroyed = false
		result.defender_crystal_loss = 0
		return

	if result.defender_crystal_loss > 0:
		# Divine Protection
		if defender.card_type == "character" and GameState.divine_protection_active[opponent]:
			if defender.affinity == CharacterData.Affinity.DIVINE:
				result.defender_destroyed = false
				result.defender_crystal_loss = 0
				GameState.divine_protection_active[opponent] = false
				GameState.post_message("Prayer protected %s!" % defender.card_name)
			else:
				GameState.lose_crystals(opponent, result.defender_crystal_loss, "battle")
				await _wait_crystal_animation()
		else:
			GameState.lose_crystals(opponent, result.defender_crystal_loss, "battle")
			await _wait_crystal_animation()
		if _battle_aborted():
			return

	if result.attacker_crystal_gain > 0:
		GameState.gain_crystals(player, result.attacker_crystal_gain, "battle")
	if result.defender_crystal_gain > 0:
		GameState.gain_crystals(opponent, result.defender_crystal_gain, "battle")
	if result.attacker_crystal_gain > 0 or result.defender_crystal_gain > 0:
		await _wait_crystal_animation()

	# Dark Blob: survived Reckoning → eligible for +ATK at foe turn end
	for _db_card: GameState.CardInstance in [attacker, defender]:
		if _db_card.card_type != "character":
			continue
		if _db_card.ability_type != CharacterData.AbilityType.PERM_ATK_BOOST_PER_SURVIVE_OPP_TURN:
			continue
		var _db_dead: bool = result.attacker_destroyed if _db_card == attacker else result.defender_destroyed
		if not _db_dead and "reckoning_participated" not in _db_card.flags:
			_db_card.flags.append("reckoning_participated")

	if result.attacker_destroyed:
		GameState.destroy_card(player, attacker_pos.x, attacker_pos.y, false)
	if result.defender_destroyed:
		GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
	elif defender.card_type == "trap":
		# Trap triggered → animate destroy
		GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)

func resolve_trap_temp_def_boost(player: int, target_pos: Vector2i) -> void:
	var card: GameState.CardInstance = GameState.get_card(player, target_pos.x, target_pos.y)
	if card.card_type == "character":
		if _pending_trap_def_boost_carry:
			card.apply_trap_carry_def(_pending_trap_def_boost, _pending_trap_def_boost_attacker)
			GameState.post_message("%s: +%d DEF until attacker's next turn ends." % [card.card_name, _pending_trap_def_boost])
		else:
			card.temp_def_bonus += _pending_trap_def_boost
			GameState.post_message("%s: +%d DEF until end of turn." % [card.card_name, _pending_trap_def_boost])
	_pending_trap_def_boost = 0
	_pending_trap_def_boost_carry = false
	_pending_trap_def_boost_attacker = -1

func _expire_trap_carry_def_at_turn_end(ending_player: int) -> void:
	for _p: int in range(2):
		for _r: int in range(GameState.GRID_SIZE):
			for _c: int in range(GameState.GRID_SIZE):
				var _card: GameState.CardInstance = GameState.get_card(_p, _r, _c)
				if _card.trap_carry_def_clear_attacker != ending_player:
					continue
				if _card.trap_carry_def_ends_after_attacker_turns <= 0:
					continue
				_card.trap_carry_def_ends_after_attacker_turns -= 1
				if _card.trap_carry_def_ends_after_attacker_turns == 0:
					_card.clear_trap_carry_def()

func resolve_trap_self_destruct(player: int, target_pos: Vector2i) -> void:
	var card: GameState.CardInstance = GameState.get_card(player, target_pos.x, target_pos.y)
	if card.card_type == "character":
		if not card.face_up:
			GameState.reveal_card(player, target_pos.x, target_pos.y)
		card.temp_atk_bonus += _pending_trap_self_destruct_boost
		if "self_destruct_next_turn" not in card.flags:
			card.flags.append("self_destruct_next_turn")
		GameState.post_message("%s: +%d ATK until end of next turn, then destroyed." % [card.card_name, _pending_trap_self_destruct_boost])
	_pending_trap_self_destruct_boost = 0
	_pending_trap_self_destruct_player = -1

func complete_archbishop_redirect() -> void:
	emit_signal("archbishop_redirect_resolved")

func complete_brainwash_redirect() -> void:
	emit_signal("brainwash_redirect_resolved")

func _clear_wk17_substitute_state() -> void:
	_wk17_substitute_battle = false
	_wk17_substitute_grid_player = -1
	_wk17_substitute_attacker_pos = Vector2i(-1, -1)
	_wk17_substitute_defender_pos = Vector2i(-1, -1)
	_wk17_initiating_attacker_pos = Vector2i(-1, -1)

func resolve_wk17_substitute_battle(
		initiating_player: int,
		grid_player: int,
		substitute_pos: Vector2i,
		defender_pos: Vector2i,
		initiating_attacker_pos: Vector2i
) -> void:
	var substitute: GameState.CardInstance = GameState.get_card(grid_player, substitute_pos.x, substitute_pos.y)
	var defender: GameState.CardInstance = GameState.get_card(grid_player, defender_pos.x, defender_pos.y)
	if substitute.card_type != "character" or defender.was_destroyed:
		GameState.post_message("WK-17: Invalid substitute — effect fizzles.")
		GameState.set_phase(GameState.Phase.MODE_SELECT)
		return

	var defender_was_exposed: bool = defender.face_up
	if not substitute.face_up:
		GameState.reveal_card_by_ability(grid_player, substitute_pos.x, substitute_pos.y)
		substitute = GameState.get_card(grid_player, substitute_pos.x, substitute_pos.y)
	if defender.card_type != "dead_end" and not defender.face_up:
		GameState.reveal_card_by_ability(grid_player, defender_pos.x, defender_pos.y)
		defender = GameState.get_card(grid_player, defender_pos.x, defender_pos.y)
		defender_was_exposed = false

	GameState.post_message("WK-17: %s fights in place of the attacker!" % substitute.card_name)
	GameState.defender_pos = defender_pos
	BattleResolver.calculate_field_bonuses(grid_player)
	BattleResolver.calculate_field_bonuses(GameState.get_opponent(grid_player))

	GameState.dice_result = DiceRoller.roll_attack_dice()
	GameState.emit_signal("dice_rolled", GameState.dice_result)

	var _pre_shown_reckoning_coins: Array = await _maybe_flip_reckoning_attacker_coins(substitute)
	if not _pre_shown_reckoning_coins.is_empty():
		BattleResolver.set_predetermined_coin_flips(_pre_shown_reckoning_coins)

	BattleResolver.apply_swap_atk_def_when_attacking(substitute)

	var preview_result := BattleResolver.resolve_battle(
		substitute, defender, GameState.dice_result, grid_player, grid_player,
		defender_was_exposed, defender_pos, true)
	emit_signal("battle_preview_needed", grid_player, substitute, defender, preview_result)

	BattleResolver.reset_predetermined_coin_flip_index()
	var result := BattleResolver.resolve_battle(
		substitute, defender, GameState.dice_result, grid_player, grid_player,
		defender_was_exposed, defender_pos)
	BattleResolver.clear_predetermined_coin_flips()
	BattleResolver.copy_reckoning_pills_from(preview_result, result)
	result.attacker_name = substitute.card_name
	result.defender_name = defender.card_name
	result.attacker_log_label = BattleLogFormat.format_unit(substitute)
	if defender.card_type == "character":
		result.defender_log_label = BattleLogFormat.format_unit(defender)
	elif defender.card_type == "trap":
		result.defender_log_label = BattleLogFormat.format_card(defender)
	for msg in result.messages:
		GameState.post_message(msg)
	_log_reckoning_ability_triggers(substitute, defender, result)

	if result.defender_destroyed and defender.card_type == "character" and defender.force_shielded:
		result.defender_destroyed = false
		result.defender_crystal_loss = 0
		defender.force_shielded = false
		GameState.post_message("Force Shield: %s blocked the attack!" % defender.card_name)

	if not result.coin_flip_results.is_empty() and _pre_shown_reckoning_coins.is_empty():
		emit_signal("coin_flip_visual_requested", result.coin_flip_results)
		await coin_flip_visual_done
		if _battle_aborted():
			GameState.set_phase(GameState.Phase.MODE_SELECT)
			return

	emit_signal("battle_result_finalized", result)
	await battle_preview_done
	if _battle_aborted():
		GameState.set_phase(GameState.Phase.MODE_SELECT)
		return

	await _apply_friendly_fire_battle_result(
		result, grid_player, substitute_pos, defender_pos, substitute, defender)

	var initiating_attacker: GameState.CardInstance = GameState.get_card(
		initiating_player, initiating_attacker_pos.x, initiating_attacker_pos.y)
	if initiating_attacker.card_type == "character":
		initiating_attacker.attacked_this_turn = true
		await _await_wait_badge_animation(initiating_player, initiating_attacker_pos.x, initiating_attacker_pos.y)
	GameState.attacks_remaining = maxi(0, GameState.attacks_remaining - 1)

	emit_signal("attack_completed", initiating_attacker_pos, defender_pos, result)
	GameState.set_phase(GameState.Phase.MODE_SELECT)

static func _has_brainwash_target(player: int, exclude_pos: Vector2i) -> bool:
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			if Vector2i(r, c) == exclude_pos:
				continue
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character":
				return true
	return false

func resolve_brainwash_friendly_fire(attacker_player: int, friendly_pos: Vector2i) -> void:
	var attacker_pos: Vector2i = GameState.attacker_pos
	var attacker: GameState.CardInstance = GameState.attacker_card
	if attacker == null:
		complete_brainwash_redirect()
		return
	var ally: GameState.CardInstance = GameState.get_card(attacker_player, friendly_pos.x, friendly_pos.y)
	if ally.card_type != "character" or friendly_pos == attacker_pos:
		GameState.post_message("Brainwash: Invalid target — effect fizzles.")
		complete_brainwash_redirect()
		return

	var defender_was_exposed: bool = ally.face_up
	if not ally.face_up:
		GameState.reveal_card(attacker_player, friendly_pos.x, friendly_pos.y)

	GameState.post_message("Brainwash: %s attacks %s!" % [attacker.card_name, ally.card_name])
	GameState.defender_pos = friendly_pos
	BattleResolver.calculate_field_bonuses(attacker_player)
	BattleResolver.calculate_field_bonuses(GameState.get_opponent(attacker_player))

	var _pre_shown_reckoning_coins: Array = await _maybe_flip_reckoning_attacker_coins(attacker)
	if not _pre_shown_reckoning_coins.is_empty():
		BattleResolver.set_predetermined_coin_flips(_pre_shown_reckoning_coins)

	var preview_result := BattleResolver.resolve_battle(
		attacker, ally, GameState.dice_result, attacker_player, attacker_player,
		defender_was_exposed, friendly_pos, true)
	emit_signal("battle_preview_needed", attacker_player, attacker, ally, preview_result)

	BattleResolver.reset_predetermined_coin_flip_index()
	var result := BattleResolver.resolve_battle(
		attacker, ally, GameState.dice_result, attacker_player, attacker_player,
		defender_was_exposed, friendly_pos)
	BattleResolver.clear_predetermined_coin_flips()
	BattleResolver.copy_reckoning_pills_from(preview_result, result)
	result.attacker_name = attacker.card_name
	result.defender_name = ally.card_name
	result.attacker_log_label = BattleLogFormat.format_unit(attacker)
	result.defender_log_label = BattleLogFormat.format_unit(ally)
	for msg in result.messages:
		GameState.post_message(msg)
	_log_reckoning_ability_triggers(attacker, ally, result)

	if result.defender_destroyed and ally.force_shielded:
		result.defender_destroyed = false
		result.defender_crystal_loss = 0
		ally.force_shielded = false
		GameState.post_message("Force Shield: %s blocked the attack!" % ally.card_name)

	if not result.coin_flip_results.is_empty() and _pre_shown_reckoning_coins.is_empty():
		emit_signal("coin_flip_visual_requested", result.coin_flip_results)
		await coin_flip_visual_done
		if _battle_aborted():
			complete_brainwash_redirect()
			return

	emit_signal("battle_result_finalized", result)
	await battle_preview_done
	if _battle_aborted():
		complete_brainwash_redirect()
		return

	await _apply_friendly_fire_battle_result(
		result, attacker_player, attacker_pos, friendly_pos, attacker, ally)
	# Log the redirected combat in standard Attack format (the original Brainwash trap
	# hit was already logged as "Trap: triggered"; this adds the friendly-fire resolution).
	emit_signal("attack_completed", attacker_pos, friendly_pos, result)
	complete_brainwash_redirect()

func _apply_friendly_fire_battle_result(
		result: BattleResolver.BattleResult,
		player: int,
		attacker_pos: Vector2i,
		friendly_pos: Vector2i,
		attacker: GameState.CardInstance,
		ally: GameState.CardInstance
) -> void:
	if _battle_aborted():
		return
	if result.attacker_crystal_loss > 0:
		GameState.lose_crystals(player, result.attacker_crystal_loss, "battle")
		await _wait_crystal_animation()
		if _battle_aborted():
			return
	if result.defender_crystal_loss > 0:
		GameState.lose_crystals(player, result.defender_crystal_loss, "battle")
		await _wait_crystal_animation()
		if _battle_aborted():
			return
	if result.attacker_crystal_gain > 0:
		GameState.gain_crystals(player, result.attacker_crystal_gain, "battle")
	if result.defender_crystal_gain > 0:
		GameState.gain_crystals(player, result.defender_crystal_gain, "battle")
	if result.attacker_crystal_gain > 0 or result.defender_crystal_gain > 0:
		await _wait_crystal_animation()
	if result.attacker_destroyed:
		GameState.destroy_card(player, attacker_pos.x, attacker_pos.y, false)
	if result.defender_destroyed:
		GameState.destroy_card(player, friendly_pos.x, friendly_pos.y, false)

static func _has_archbishop_redirect_target(opponent: int, exclude_pos: Vector2i) -> bool:
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			if Vector2i(r, c) == exclude_pos:
				continue
			var card: GameState.CardInstance = GameState.get_card(opponent, r, c)
			if card.card_type == "character" and card.face_up \
					and card.affinity == CharacterData.Affinity.DIVINE \
					and card.ability_type != CharacterData.AbilityType.REDIRECT_DESTRUCTION_TO_ALLY:
				return true
	return false

func resolve_archbishop_redirect(player: int, redirect_pos: Vector2i, original_defender_pos: Vector2i) -> void:
	# Player chose to destroy another Divine instead
	GameState.destroy_card(player, redirect_pos.x, redirect_pos.y)
	await _wait_crystal_animation()
	# Defender (Archbishop) survives, so no blank placed at original_defender_pos
	GameState.post_message("Archbishop redirected destruction to another card.")
	complete_archbishop_redirect()

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
	var trap_data = params.get("trap_data") as TrapData
	if trap_data == null:
		return

	# Traps that destroy the attacker defer their own destruction until after
	# the character card has visually disappeared.
	var _destroys_attacker: bool = trap_data.effect_type in [
		TrapData.TrapEffectType.DESTROY_ATTACKER,
		TrapData.TrapEffectType.DESTROY_ATTACKER_CHOICE_DESTROY,
		TrapData.TrapEffectType.DESTROY_ATTACKER_DEFENDER_PAYS,
	]

	# Trap always becomes blank after triggering — animate destroy.
	# For attacker-destroying traps this is deferred to after the character is gone.
	if not _destroys_attacker:
		GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
	var _eff_trap_cost: int = trap_data.crystal_cost
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON:
		var _trap_mods: Array = GameState.active_dungeon_modifiers
		if "trap_broker" in _trap_mods: _eff_trap_cost = 0
		elif "trap_dealer" in _trap_mods: _eff_trap_cost = int(_eff_trap_cost * 0.5)
	GameState.lose_crystals(opponent, _eff_trap_cost, "trap cost")
	await _wait_crystal_animation()

	# Honored Duel: trap is consumed but its effect is cancelled
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "honored_duel" in GameState.active_dungeon_modifiers:
		GameState.post_message("Honored Duel: %s's effect is cancelled!" % trap_data.card_name)
		if _destroys_attacker:
			GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
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
			var _hst_adj: Array = GameState.get_adjacent_positions(target_pos.x, target_pos.y)
			for _hst_pos: Vector2i in _hst_adj:
				GameState.reveal_card_by_ability(opponent, _hst_pos.x, _hst_pos.y)
				if _hst_pos not in GameState.locked_attack_positions:
					GameState.locked_attack_positions.append(_hst_pos)

		TrapData.TrapEffectType.NULLIFY_ATTACK_REVEAL_DEFENDER_CHOICE:
			GameState.post_message("Hostage: Attack nullified — choose a cell to reveal and lock.")
			_pending_trap_hostage_lock = true
			await _prompt_and_await_target_selection(
				"Hostage: Choose 1 of your cells to reveal and lock until turn end.",
				"trap_hostage_reveal_lock")

		TrapData.TrapEffectType.NULLIFY_ATTACK_CHOICE:
			emit_signal("awaiting_trap_choice",
				"Checkpoint",
				["Lose 500 Crystals", "Destroy your attacking unit"])
			var _nac_choice: int = await ability_choice_resolved
			if _nac_choice == 0:
				GameState.lose_crystals(player, 500, "trap")
				await _wait_crystal_animation()
				GameState.post_message("Checkpoint: Lost 500 Crystals.")
			else:
				GameState.mark_destroy_achievement_context(
					"trap", opponent, player, attacker_pos.x, attacker_pos.y)
				GameState.destroy_card(player, attacker_pos.x, attacker_pos.y, false)
				GameState.post_message("Checkpoint: %s destroyed!" % attacker.card_name)

		TrapData.TrapEffectType.REVEAL_DEFENDING_CHOICE:
			await _prompt_and_await_target_selection(
				"Bait: Choose a square on your field to reveal.", "self_reveal_choice")

		TrapData.TrapEffectType.ATTACKER_DISCARD_OR_END_TURN:
			emit_signal("awaiting_blackmail_tech_select", player)
			var _bm_discarded: String = await blackmail_choice_resolved
			if _bm_discarded != "":
				var _bm_hand: Array = GameState.tech_hands[player]
				if _bm_discarded in _bm_hand:
					_bm_hand.erase(_bm_discarded)
					GameState.post_message("Blackmail: Discarded %s." % _bm_discarded)
				else:
					GameState.attacks_remaining = 0
					GameState.post_message("Blackmail: No Tech Cards — turn ended.")
			else:
				GameState.attacks_remaining = 0
				GameState.post_message("Blackmail: %s ended attacker's turn!" % trap_data.card_name)

		TrapData.TrapEffectType.COPY_ATTACKER_EFFECT:
			GameState.post_message("Cursed Reflection: Choose one of your face-up units to copy %s's effect." % attacker.card_name)
			await _prompt_and_await_target_selection(
				"Cursed Reflection: Choose target.", "self_faceup_for_copy")

		TrapData.TrapEffectType.DESTROY_ATTACKER_CHOICE_DESTROY:
			if trap_data.effect_params.get("requires_faceup_defender", false):
				if GameState.get_all_face_up_characters(opponent).is_empty():
					GameState.post_message("Explosive Barrels: No face-up defender — trap fizzles.")
					GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
					return
			GameState.lose_crystals(player, attacker.crystal_cost, "card lost")
			await _wait_crystal_animation()
			GameState.mark_destroy_achievement_context(
				"trap", opponent, player, attacker_pos.x, attacker_pos.y)
			GameState.destroy_card(player, attacker_pos.x, attacker_pos.y, false)
			await get_tree().create_timer(0.65).timeout
			GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
			await _prompt_and_await_target_selection(
				"Explosive Barrels: Choose 1 revealed card on defender's field to destroy (no crystal loss).",
				"opponent_faceup_no_cost")

		TrapData.TrapEffectType.HYPNOTIZE_ATTACKER:
			var _hyp_aff: int = trap_data.effect_params.get("required_attacker_affinity", -1)
			if _hyp_aff >= 0 and attacker.affinity != _hyp_aff:
				GameState.post_message("%s: Attacker affinity mismatch — no effect." % trap_data.card_name)
				return
			if trap_data.effect_params.get("requires_union_attacker", false) and not attacker.is_union:
				GameState.post_message("%s: Attacker is not a Union — no effect." % trap_data.card_name)
				return
			# +2 so the lock survives opponent's turn and blocks attacker's next turn
			# (same cadence as LOCK_SELF_AFTER_ATTACK / COIN_FLIP_2_LOCK_ATTACKER; +1 expired before they act again).
			attacker.cannot_attack_until = GameState.turn_number + 2
			GameState.post_message("Hypnosis: %s cannot attack until end of next turn." % attacker.card_name)

		TrapData.TrapEffectType.DESTROY_ATTACKER:
			var _da_max_atk: int = int(trap_data.effect_params.get("max_attacker_atk", -1))
			var _da_max_def: int = int(trap_data.effect_params.get("max_attacker_def", -1))
			if _da_max_atk >= 0 and attacker.current_atk > _da_max_atk:
				GameState.post_message("%s: Attacker ATK > %d — no effect." % [trap_data.card_name, _da_max_atk])
				if _destroys_attacker:
					GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
				return
			if _da_max_def >= 0 and attacker.current_def > _da_max_def:
				GameState.post_message("%s: Attacker DEF > %d — no effect." % [trap_data.card_name, _da_max_def])
				if _destroys_attacker:
					GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
				return
			if trap_data.effect_params.get("dead_end_surround", false):
				var _dg_hit: bool = false
				for _dg_adj: Vector2i in GameState.get_adjacent_positions(target_pos.x, target_pos.y):
					var _dg_cell: GameState.CardInstance = GameState.get_card(opponent, _dg_adj.x, _dg_adj.y)
					if _dg_cell.card_type == "dead_end" \
							and attacker_pos.x == _dg_adj.x and attacker_pos.y == _dg_adj.y:
						_dg_hit = true
						break
				if not _dg_hit:
					GameState.post_message("%s: No adjacent dead-end under attack — no effect." % trap_data.card_name)
					if _destroys_attacker:
						GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
					return
			var _da_no_cost: bool = trap_data.effect_params.get("no_destroy_cost", false)
			if not _da_no_cost:
				GameState.lose_crystals(player, attacker.crystal_cost, "card lost")
				await _wait_crystal_animation()
			GameState.mark_destroy_achievement_context(
				"trap", opponent, player, attacker_pos.x, attacker_pos.y)
			GameState.destroy_card(player, attacker_pos.x, attacker_pos.y, false)
			await get_tree().create_timer(0.65).timeout
			GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
			GameState.post_message("%s: %s destroyed!" % [trap_data.card_name, attacker.card_name])
			if trap_data.effect_params.get("refund_half_cost_on_kill", false):
				var _refund: int = int(attacker.crystal_cost / 2)
				GameState.gain_crystals(opponent, _refund, "trap")
				GameState.post_message("%s: Defender gains %d Crystals (half unit cost)." % [trap_data.card_name, _refund])
				await _wait_crystal_animation()

		TrapData.TrapEffectType.LOCK_ATTACKER_REMAINING_ATTACKS:
			GameState.attacks_remaining = 0
			GameState.echo_barrier_player = player
			GameState.post_message("Echo Barrier: Attacking player cannot attack again this turn!")

		TrapData.TrapEffectType.DRAIN_ATTACKER_CRYSTALS:
			var _req_aff_d: int = trap_data.effect_params.get("required_attacker_affinity", -1)
			if _req_aff_d >= 0 and attacker.affinity != _req_aff_d:
				GameState.post_message("%s: Attacker affinity mismatch — no effect." % trap_data.card_name)
				return
			var amount: int = trap_data.effect_params.get("amount", 800)
			if trap_data.effect_params.get("per_void_unit", false):
				var _void_n: int = GameState.void_pile_entries[player].size()
				amount = amount * maxi(1, _void_n)
			if trap_data.effect_params.has("average_crystals_if_lte"):
				var _thresh: int = int(trap_data.effect_params.get("average_crystals_if_lte", 1000))
				if GameState.crystals[player] <= _thresh:
					amount = int((GameState.crystals[player] + GameState.crystals[opponent]) / 2)
			var coin_count: int = int(trap_data.effect_params.get("coin_count", 0))
			var transfer: bool = trap_data.effect_params.get("transfer_to_defender", false)
			if coin_count > 0 and not transfer:
				var _cf_r: Array = await _do_coin_flips(coin_count)
				var _cf_parts: PackedStringArray = []
				var _heads: int = 0
				for r in _cf_r:
					_cf_parts.append("Heads" if r else "Tails")
					if r:
						_heads += 1
				GameState.post_message("%s: %s." % [trap_data.card_name, ", ".join(_cf_parts)])
				if _heads > 0:
					var total: int = amount * _heads
					GameState.lose_crystals(player, total, "trap")
					await _wait_crystal_animation()
					GameState.post_message(
						"%s: %d head(s) — Player %d loses %d Crystals!" % [
							trap_data.card_name, _heads, player + 1, total])
				else:
					GameState.post_message("%s: No heads — no crystal loss." % trap_data.card_name)
			else:
				GameState.lose_crystals(player, amount, "trap")
				if transfer:
					GameState.gain_crystals(opponent, amount, "trap")
				await _wait_crystal_animation()
				if transfer:
					GameState.post_message(
						"%s: Player %d loses %d Crystals; defender gains %d!" % [
							trap_data.card_name, player + 1, amount, amount])
				else:
					GameState.post_message("%s: Player %d loses %d Crystals!" % [trap_data.card_name, player + 1, amount])

		TrapData.TrapEffectType.CANCEL_ATTACKER_ATTACK:
			var _dp_max: int = int(trap_data.effect_params.get("max_attack_cost", -1))
			if _dp_max >= 0:
				GameState.attack_cost_block_player = player
				GameState.attack_cost_block_max = _dp_max
				GameState.post_message(
					"%s: Foe cannot attack with units costing %d or less this turn!" % [trap_data.card_name, _dp_max])
			else:
				GameState.post_message("%s: %s's attack is cancelled!" % [trap_data.card_name, attacker.card_name])

		TrapData.TrapEffectType.SWAP_ARMORED_NATURE:
			await _prompt_and_await_target_selection(
				"Defensive Pheromone: Choose an 'Armored' Nature card to swap.",
				"own_armored_nature")

		TrapData.TrapEffectType.PERMANENT_ATK_DEBUFF:
			var _pad_aff: int = trap_data.effect_params.get("required_attacker_affinity", -1)
			if _pad_aff >= 0 and attacker.affinity != _pad_aff:
				GameState.post_message("%s: Attacker affinity mismatch — no effect." % trap_data.card_name)
				return
			var amount: int = trap_data.effect_params.get("amount", 10)
			if trap_data.effect_params.get("per_void_unit", false):
				var _void_n2: int = GameState.void_pile_entries[opponent].size()
				amount = amount * maxi(1, _void_n2)
			var _pad_coin_count: int = int(trap_data.effect_params.get("coin_count", 0))
			if _pad_coin_count > 0 and trap_data.effect_params.get("per_head", false):
				var _pad_cf: Array = await _do_coin_flips(_pad_coin_count)
				var _pad_heads: int = 0
				for _ph in _pad_cf:
					if _ph:
						_pad_heads += 1
				if _pad_heads > 0:
					var _def_temp: int = int(trap_data.effect_params.get("def_debuff_temp", 0)) * _pad_heads
					if _def_temp > 0:
						attacker.temp_def_bonus -= _def_temp
						GameState.post_message("%s: %d head(s) — %s -%d DEF this turn!" % [
							trap_data.card_name, _pad_heads, attacker.card_name, _def_temp])
				else:
					GameState.post_message("%s: No heads — no effect." % trap_data.card_name)
				if _destroys_attacker:
					GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
				return
			if trap_data.effect_params.get("double_cost_until_turn_end", false):
				attacker.temp_cost_multiplier = 2
				GameState.post_message("%s: %s's cost doubled until your turn ends!" % [trap_data.card_name, attacker.card_name])
				if _destroys_attacker:
					GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
				return
			if amount > 0:
				attacker.current_atk = max(0, attacker.current_atk - amount)
			var _def_deb: int = int(trap_data.effect_params.get("def_debuff", 0))
			if _def_deb > 0:
				attacker.current_def = max(0, attacker.current_def - _def_deb)
			var _def_deb_temp: int = int(trap_data.effect_params.get("def_debuff_temp", 0))
			if _def_deb_temp > 0:
				attacker.temp_def_bonus -= _def_deb_temp
			if trap_data.effect_params.get("also_def", false) and amount > 0:
				attacker.current_def = max(0, attacker.current_def - amount)
			GameState.post_message("%s: %s debuffed!" % [trap_data.card_name, attacker.card_name])

		TrapData.TrapEffectType.NULLIFY_ATTACKER_EFFECT:
			# Attacker-targeted "next turn" effects need +2 (see HYPNOTIZE_ATTACKER).
			attacker.effect_nullified_until = GameState.turn_number + 2
			GameState.post_message("Snare Trap: %s's effect nullified until end of next turn!" % attacker.card_name)

		TrapData.TrapEffectType.FORCE_FRIENDLY_FIRE:
			if not _has_brainwash_target(player, attacker_pos):
				GameState.post_message("Brainwash: No ally to redirect — effect fizzles.")
				return
			_flow_block_depth += 1
			emit_signal("awaiting_target_selection",
				"Brainwash: Choose one of your own allies as the attack target.",
				"own_any_as_target")
			await brainwash_redirect_resolved
			_flow_block_depth -= 1

		TrapData.TrapEffectType.NULLIFY_BLOCK_ADJACENT:
			GameState.post_message("Bunker: Adjacent squares cannot be targeted this turn.")
			var _bunk_adj: Array = GameState.get_adjacent_positions(target_pos.x, target_pos.y)
			for _bunk_pos: Vector2i in _bunk_adj:
				if _bunk_pos not in GameState.locked_attack_positions:
					GameState.locked_attack_positions.append(_bunk_pos)

		TrapData.TrapEffectType.FIELD_BOOST_AFFINITY_DEF:
			var _fb_aff: int = trap_data.effect_params.get("affinity", -1)
			var _fb_atk: int = trap_data.effect_params.get("atk", 0)
			var _fb_def: int = trap_data.effect_params.get("def", 5)
			for _fb_r: int in range(GameState.GRID_SIZE):
				for _fb_c: int in range(GameState.GRID_SIZE):
					var _fb_card: GameState.CardInstance = GameState.get_card(opponent, _fb_r, _fb_c)
					if _fb_card.card_type == "character" and _fb_card.face_up:
						if _fb_aff == -1 or _fb_card.affinity == _fb_aff:
							_fb_card.temp_atk_bonus += _fb_atk
							_fb_card.temp_def_bonus += _fb_def
			var _fb_aff_name: String = CharacterData.Affinity.keys()[_fb_aff] if _fb_aff >= 0 else "face-up"
			if _fb_atk > 0 and _fb_def > 0:
				GameState.post_message("%s: +%d ATK & +%d DEF to all %s units this turn!" % [
					trap_data.card_name, _fb_atk, _fb_def, _fb_aff_name])
			else:
				GameState.post_message("%s: +%d DEF to all %s units this turn!" % [trap_data.card_name, _fb_def, _fb_aff_name])

		TrapData.TrapEffectType.SWAP_ATTACKER_ATK_DEF_TEMP:
			attacker.apply_atk_def_swap_until_player_turn_end(opponent)
			GameState.post_message("%s: %s's ATK and DEF swapped until end of defender's turn!" % [trap_data.card_name, attacker.card_name])

		TrapData.TrapEffectType.DESTROY_ATTACKER_DEFENDER_PAYS:
			GameState.lose_crystals(player, attacker.crystal_cost, "card lost")
			await _wait_crystal_animation()
			GameState.mark_destroy_achievement_context(
				"trap", opponent, player, attacker_pos.x, attacker_pos.y)
			GameState.destroy_card(player, attacker_pos.x, attacker_pos.y, false)
			await get_tree().create_timer(0.65).timeout
			GameState.destroy_card(opponent, target_pos.x, target_pos.y, false)
			var _dap_cost: int = trap_data.effect_params.get("amount", attacker.crystal_cost)
			GameState.lose_crystals(opponent, _dap_cost, "trap")
			await _wait_crystal_animation()
			GameState.post_message("%s: %s destroyed! Defender loses %d Crystals." % [trap_data.card_name, attacker.card_name, _dap_cost])

		TrapData.TrapEffectType.TEMP_DEBUFF_ALL_ATTACKER_CHARS:
			var _tda_amount: int = trap_data.effect_params.get("amount", 5)
			for _tda_r: int in range(GameState.GRID_SIZE):
				for _tda_c: int in range(GameState.GRID_SIZE):
					var _tda_card: GameState.CardInstance = GameState.get_card(player, _tda_r, _tda_c)
					if _tda_card.card_type == "character" and _tda_card.face_up:
						_tda_card.temp_atk_bonus -= _tda_amount
			GameState.post_message("%s: All of Player %d's units -%d ATK this turn!" % [trap_data.card_name, player + 1, _tda_amount])

		TrapData.TrapEffectType.TEMP_DEF_BOOST_ONE_OWN:
			var _td_def: int = trap_data.effect_params.get("def", 10)
			var _td_carry: bool = trap_data.effect_params.get("carry_def", trap_data.effect_params.get("all_own_units", false))
			if trap_data.effect_params.get("all_own_units", false):
				for _td_r: int in range(GameState.GRID_SIZE):
					for _td_c: int in range(GameState.GRID_SIZE):
						var _td_card: GameState.CardInstance = GameState.get_card(opponent, _td_r, _td_c)
						if _td_card.card_type == "character":
							if _td_carry:
								_td_card.apply_trap_carry_def(_td_def, player)
							else:
								_td_card.temp_def_bonus += _td_def
				if _td_carry:
					GameState.post_message(
						"%s: All your units gain +%d DEF in Reckoning until attacker's next turn ends!" % [
							trap_data.card_name, _td_def])
				else:
					GameState.post_message(
						"%s: All your units gain +%d DEF in Reckoning this turn!" % [
							trap_data.card_name, _td_def])
			else:
				_pending_trap_def_boost = _td_def
				_pending_trap_def_boost_carry = _td_carry
				_pending_trap_def_boost_attacker = player
				await _prompt_and_await_target_selection(
					"%s: Choose 1 of your units for +%d DEF this turn." % [trap_data.card_name, _pending_trap_def_boost],
					"own_faceup_for_trap_temp_def_boost")

		TrapData.TrapEffectType.COIN_FLIP_2_ATK_DEBUFF:
			var _cf2d_amount: int = trap_data.effect_params.get("amount", 10)
			var _cf2d_per_head: bool = trap_data.effect_params.get("per_head", false)
			var _cf2d_carry: bool = trap_data.effect_params.get("carry_atk_debuff", false)
			var _cf2d_n: int = maxi(2, int(trap_data.effect_params.get("coin_count", 2)))
			var _cf2d_r: Array = await _do_coin_flips(_cf2d_n)
			GameState.post_message("%s: %s, %s." % [trap_data.card_name,
				"Heads" if _cf2d_r[0] else "Tails", "Heads" if _cf2d_r[1] else "Tails"])
			var _cf2d_heads: int = 0
			for _cf2d_h in _cf2d_r:
				if _cf2d_h:
					_cf2d_heads += 1
			if _cf2d_per_head and _cf2d_heads > 0:
				var _cf2d_total: int = _cf2d_amount * _cf2d_heads
				if _cf2d_carry:
					attacker.carry_atk_debuff += _cf2d_total
					GameState.post_message("%s: %d head(s) — %s -%d ATK until next turn ends!" % [
						trap_data.card_name, _cf2d_heads, attacker.card_name, _cf2d_total])
				else:
					attacker.current_atk = max(0, attacker.current_atk - _cf2d_total)
					GameState.post_message("%s: %d head(s) — %s -%d ATK permanently!" % [
						trap_data.card_name, _cf2d_heads, attacker.card_name, _cf2d_total])
			elif not _cf2d_per_head and _cf2d_r[0] and _cf2d_r[1]:
				attacker.current_atk = max(0, attacker.current_atk - _cf2d_amount)
				GameState.post_message("Both heads! %s -%d ATK permanently!" % [attacker.card_name, _cf2d_amount])
			else:
				GameState.post_message("Not both heads — no effect." if not _cf2d_per_head else "No heads — no effect.")

		TrapData.TrapEffectType.COIN_FLIP_2_LOCK_ATTACKER:
			var _cf2l_r: Array = await _do_coin_flips(2)
			GameState.post_message("%s: %s, %s." % [trap_data.card_name,
				"Heads" if _cf2l_r[0] else "Tails", "Heads" if _cf2l_r[1] else "Tails"])
			if _cf2l_r[0] and _cf2l_r[1]:
				# +2 so the lock survives opponent's turn and blocks attacker's next turn
				# (same cadence as LOCK_SELF_AFTER_ATTACK; +1 expired before they act again).
				attacker.cannot_attack_until = GameState.turn_number + 2
				GameState.post_message("Both heads! %s cannot attack next turn!" % attacker.card_name)
			else:
				GameState.post_message("Not both heads — no effect.")

		TrapData.TrapEffectType.SELF_DESTROY_TEMP_ATK_BOOST:
			_pending_trap_self_destruct_boost = trap_data.effect_params.get("atk", 15)
			_pending_trap_self_destruct_player = opponent
			await _prompt_and_await_target_selection(
				"%s: Choose 1 of your units for +%d ATK until end of next turn (then destroyed)." % [trap_data.card_name, _pending_trap_self_destruct_boost],
				"own_character_for_trap_self_destruct")

		TrapData.TrapEffectType.REVEAL_OWN_GAIN_CRYSTAL:
			var _rogc_amount: int = trap_data.effect_params.get("amount", 300)
			_pending_street_joke_crystal = _rogc_amount
			await _prompt_and_await_target_selection(
				"%s: Choose 1 of your cells to reveal." % trap_data.card_name,
				"trap_street_joke_reveal")

		TrapData.TrapEffectType.AFFINITY_COIN_FLIP_DESTROY_ATTACKER:
			var _acf_aff: int = trap_data.effect_params.get("affinity", -1)
			var _acf_thresh: int = int(trap_data.effect_params.get("crystal_threshold", 1000))
			if _acf_aff >= 0 and attacker.affinity != _acf_aff:
				GameState.post_message("%s: Attacker affinity mismatch — no effect." % trap_data.card_name)
				return
			var _acf_heads: bool = GameState.crystals[opponent] <= _acf_thresh
			if not _acf_heads:
				var _acf_r: Array = await _do_coin_flips(1)
				_acf_heads = bool(_acf_r[0])
			if _acf_heads:
				GameState.mark_destroy_achievement_context(
					"trap", opponent, player, attacker_pos.x, attacker_pos.y)
				GameState.destroy_card(player, attacker_pos.x, attacker_pos.y, false)
				GameState.post_message("%s: %s destroyed!" % [trap_data.card_name, attacker.card_name])
			else:
				GameState.post_message("%s: Tails — attacker survives." % trap_data.card_name)

		TrapData.TrapEffectType.END_ATTACKER_TURN_IF_AFFINITY:
			var _eat_aff: int = trap_data.effect_params.get("affinity", -1)
			if _eat_aff >= 0 and attacker.affinity != _eat_aff:
				GameState.post_message("%s: Attacker affinity mismatch — no effect." % trap_data.card_name)
				return
			if trap_data.effect_params.get("clear_flags", false):
				for _f: String in attacker.flags.duplicate():
					attacker.flags.erase(_f)
			GameState.attacks_remaining = 0
			GameState.post_message("%s: Attacker's turn ends immediately!" % trap_data.card_name)

		TrapData.TrapEffectType.DESTROY_ATTACKER_IF_FIRST_ATTACK:
			if GameState.attacks_used_this_turn == 0:
				GameState.mark_destroy_achievement_context(
					"trap", opponent, player, attacker_pos.x, attacker_pos.y)
				GameState.destroy_card(player, attacker_pos.x, attacker_pos.y, false)
				GameState.post_message("%s: First attack — %s destroyed!" % [trap_data.card_name, attacker.card_name])
			else:
				GameState.post_message("%s: Not the first attack — no effect." % trap_data.card_name)

		TrapData.TrapEffectType.NOT_IMPLEMENTED:
			GameState.show_center_message("Ability not implemented: " + trap_data.card_name)

# ─────────────────────────────────────────────────────────────
# End Turn
# ─────────────────────────────────────────────────────────────
func _blast_adjacent_foe_faceup(opponent: int, row: int, col: int) -> void:
	var deltas: Array = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for d: Vector2i in deltas:
		var ar: int = row + d.x
		var ac: int = col + d.y
		if ar < 0 or ar >= GameState.GRID_SIZE or ac < 0 or ac >= GameState.GRID_SIZE:
			continue
		var foe: GameState.CardInstance = GameState.get_card(opponent, ar, ac)
		if foe.card_type == "character" and foe.face_up:
			GameState.destroy_card(opponent, ar, ac, true)
			GameState.post_message("Adjacent blast destroyed %s!" % foe.card_name)


func end_turn(player: int) -> void:
	_end_turn(player)

func _end_turn(player: int) -> void:
	# Clear Guerrilla Tactics after the opponent's turn ends.
	var _gt_owner: int = GameState.guerrilla_tactics_owner
	if _gt_owner >= 0 and player == GameState.get_opponent(_gt_owner):
		GameState.guerrilla_tactics_owner = -1

	# Clear Decoy Puppet attack-cost block at end of blocked player's turn.
	if GameState.attack_cost_block_player == player:
		GameState.attack_cost_block_player = -1
		GameState.attack_cost_block_max = -1
	if GameState.echo_barrier_player == player:
		GameState.echo_barrier_player = -1
	# Destroy Arcane Duplication tokens flagged for end-of-turn cleanup.
	for _tok_p: int in range(2):
		for _tok_r: int in range(GameState.GRID_SIZE):
			for _tok_c: int in range(GameState.GRID_SIZE):
				var _tok: GameState.CardInstance = GameState.get_card(_tok_p, _tok_r, _tok_c)
				if _tok.is_token and "destroy_at_turn_end" in _tok.flags:
					GameState.destroy_card(_tok_p, _tok_r, _tok_c, false)
					GameState.post_message("Arcane Duplication token fades away.")
	CardRuleEngine.emit_trigger(CardRule.TriggerType.TURN_END_OWNER,
		{"source_player": player})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.TURN_END_OPPONENT,
		{"source_player": GameState.get_opponent(player)})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.TURN_END_OWNER_NTH,
		{"source_player": player})
	CardRuleEngine.emit_trigger(CardRule.TriggerType.TURN_END_OPPONENT_NTH,
		{"source_player": GameState.get_opponent(player)})
	CardRuleEngine.tick_turn_end(player)

	GameState.process_turn_end_material_revives(player)

	# Rebel King: when this player ends their turn, they swap ATK/DEF on one own card
	var _rk_opp: int = GameState.get_opponent(player)
	var _rebel_king_active: bool = false
	for _rk_r: int in range(GameState.GRID_SIZE):
		for _rk_c: int in range(GameState.GRID_SIZE):
			var _rk: GameState.CardInstance = GameState.get_card(_rk_opp, _rk_r, _rk_c)
			if _rk.card_type == "character" and _rk.face_up and _rk.is_union \
					and _rk.ability_type == CharacterData.AbilityType.OPPONENT_TURN_END_SWAP_ATK_DEF:
				_rebel_king_active = true
				break
		if _rebel_king_active:
			break
	if _rebel_king_active:
		_pending_rebel_king_owner = _rk_opp
		_pending_rebel_king_foe_player = player
		var _rk_saved_cp: int = GameState.current_player
		GameState.current_player = _rk_opp
		await _prompt_and_await_target_selection(
			"Rebel King: Choose 1 of the opponent's face-up units to swap ATK & DEF.",
			"ability_rebel_king_swap")
		GameState.current_player = _rk_saved_cp
		_pending_rebel_king_owner = -1
		_pending_rebel_king_foe_player = -1

	# Turn-end per-card effects (current player's cards)
	var _opp_end: int = GameState.get_opponent(player)
	for _te_r: int in range(GameState.GRID_SIZE):
		for _te_c: int in range(GameState.GRID_SIZE):
			var _te_card: GameState.CardInstance = GameState.get_card(player, _te_r, _te_c)
			if _te_card.card_type != "character" or not _te_card.face_up:
				continue
			match _te_card.ability_type:
				CharacterData.AbilityType.PERM_ATK_LOSS_PER_OWN_TURN:
					if not _te_card.has_mutagen_flag:
						await await_card_effect_flash(_te_card.card_name)
						var _atk_loss: int = int(_te_card.ability_params.get("amount", 10))
						_te_card.current_atk = max(0, _te_card.current_atk - _atk_loss)
				CharacterData.AbilityType.END_OF_TURN_COIN_FLIP_STAT_BOOST:
					if _te_card.ability_params.get("flat_boost", false):
						var _fb_atk: int = int(_te_card.ability_params.get("atk", 0))
						if _fb_atk > 0:
							await await_card_effect_flash(_te_card.card_name)
							await _witness_pause()
							_te_card.current_atk += _fb_atk
							_te_card.eot_atk_bonus += _fb_atk
							GameState.post_message("%s: +%d ATK at end of turn." % [_te_card.card_name, _fb_atk])
						continue
					await await_card_effect_flash(_te_card.card_name)
					var _cfst_r: Array = await _do_coin_flips(1)
					if _cfst_r[0]:  # heads
						var _cf_atk: int = _te_card.ability_params.get("atk", 10)
						_te_card.current_atk += _cf_atk
						GameState.post_message("%s: Heads! +%d ATK permanently." % [_te_card.card_name, _cf_atk])
					else:
						var _cf_def: int = _te_card.ability_params.get("def", 10)
						_te_card.current_def += _cf_def
						GameState.post_message("%s: Tails! +%d DEF permanently." % [_te_card.card_name, _cf_def])
				CharacterData.AbilityType.DESTROY_END_TURN_BLAST_ADJACENT:
					await await_card_effect_flash(_te_card.card_name)
					var _blast_row: int = _te_r
					var _blast_col: int = _te_c
					if _te_card.last_attack_target != Vector2i(-1, -1):
						_blast_row = _te_card.last_attack_target.x
						_blast_col = _te_card.last_attack_target.y
					_blast_adjacent_foe_faceup(_opp_end, _blast_row, _blast_col)
					GameState.post_message("%s self-destructs at end of turn!" % _te_card.card_name)
					GameState.destroy_card(player, _te_r, _te_c, false)
				CharacterData.AbilityType.VENOM_FLAG_END_OF_TURN:
					await _prompt_and_await_target_selection(
						"%s: Choose 1 exposed card (either side) for Venom." % _te_card.card_name,
						"ability_death_cobra_venom")
				CharacterData.AbilityType.TURN_END_REVEAL_OPPONENT_CELL:
					await _prompt_and_await_target_selection(
						"%s: Choose 1 opponent cell to reveal." % _te_card.card_name,
						"ability_false_prophet_reveal")
				CharacterData.AbilityType.TURN_END_REVEAL_OPPONENT_CELLS_ONCE:
					if "turn_end_reveal_used" not in _te_card.flags:
						_te_card.flags.append("turn_end_reveal_used")
						var _nr_count: int = maxi(1, int(_te_card.ability_params.get("count", 2)))
						await _prompt_and_await_target_selection(
							"%s: Choose %d opponent cell(s) to reveal." % [_te_card.card_name, _nr_count],
							"opponent_squares_%d" % _nr_count)
				CharacterData.AbilityType.TURN_END_FOE_CRYSTAL_PER_MUTAGEN:
					var _bw_mutagen_count: int = 0
					for _bw_p: int in range(2):
						for _bw_r: int in range(GameState.GRID_SIZE):
							for _bw_c: int in range(GameState.GRID_SIZE):
								var _bw_card: GameState.CardInstance = GameState.get_card(_bw_p, _bw_r, _bw_c)
								if _bw_card.card_type == "character" and _bw_card.has_mutagen_flag:
									_bw_mutagen_count += 1
					if _bw_mutagen_count > 0:
						await await_card_effect_flash(_te_card.card_name)
						var _bw_loss: int = _bw_mutagen_count * _te_card.ability_params.get("amount", 300)
						GameState.lose_crystals(_opp_end, _bw_loss, "ability")
						GameState.post_message("%s: Foe loses %d Crystals (%d Mutagen on field)!" % [
							_te_card.card_name, _bw_loss, _bw_mutagen_count])
						await _wait_crystal_animation()

	# Wood Elemental / PERM_DEF_ON_FOE_TURN_END: when this player (foe) ends turn, boost opponent's cards
	var _wo_owner: int = GameState.get_opponent(player)
	for _wo_r: int in range(GameState.GRID_SIZE):
		for _wo_c: int in range(GameState.GRID_SIZE):
			var _wo_card: GameState.CardInstance = GameState.get_card(_wo_owner, _wo_r, _wo_c)
			if _wo_card.card_type == "character" and _wo_card.face_up \
					and _wo_card.ability_type == CharacterData.AbilityType.PERM_DEF_ON_FOE_TURN_END:
				var _wo_def: int = _wo_card.ability_params.get("def", 5)
				await await_card_effect_flash(_wo_card.card_name)
				_wo_card.current_def += _wo_def
				GameState.post_message("%s: +%d DEF permanently at foe's turn end." % [_wo_card.card_name, _wo_def])

	# expose_destroy_pending: destroy cards that became face-up this turn
	for _pi: int in range(2):
		for _ep_r: int in range(GameState.GRID_SIZE):
			for _ep_c: int in range(GameState.GRID_SIZE):
				var _ep_card: GameState.CardInstance = GameState.get_card(_pi, _ep_r, _ep_c)
				if "expose_destroy_pending" in _ep_card.flags \
						and _ep_card.revealed_on_turn == GameState.turn_number:
					await await_card_effect_flash(_ep_card.card_name)
					GameState.post_message("%s self-destructs at end of turn!" % _ep_card.card_name)
					GameState.destroy_card(_pi, _ep_r, _ep_c)

	# End-of-expose-turn stat penalties (Mafia Associates, Sniping Fairy, etc.)
	for _pi: int in range(2):
		for _ep_r: int in range(GameState.GRID_SIZE):
			for _ep_c: int in range(GameState.GRID_SIZE):
				var _ep_card: GameState.CardInstance = GameState.get_card(_pi, _ep_r, _ep_c)
				if _ep_card.card_type != "character" or not _ep_card.face_up:
					continue
				if _ep_card.revealed_on_turn != GameState.turn_number:
					continue
				match _ep_card.ability_type:
					CharacterData.AbilityType.DEF_ZERO_WHEN_EXPOSED:
						await await_card_effect_flash(_ep_card.card_name)
						_ep_card.current_def = 0
						GameState.post_message(
							"%s: DEF becomes 0 at end of expose turn." % _ep_card.card_name)
					CharacterData.AbilityType.ATK_PENALTY_WHEN_EXPOSED:
						var _pen: int = _ep_card.ability_params.get(
							"penalty", _ep_card.ability_params.get("amount", 20))
						await await_card_effect_flash(_ep_card.card_name)
						_ep_card.current_atk = max(0, _ep_card.current_atk - _pen)
						GameState.post_message(
							"%s: -%d ATK at end of expose turn." % [_ep_card.card_name, _pen])
					CharacterData.AbilityType.PERM_ATK_BOOST_WHEN_EXPOSED:
						var _boost: int = _ep_card.ability_params.get(
							"amount", _ep_card.ability_params.get("atk", 15))
						await await_card_effect_flash(_ep_card.card_name)
						_ep_card.perm_atk_bonus += _boost
						GameState.post_message(
							"%s: +%d ATK permanently at end of expose turn." % [_ep_card.card_name, _boost])

	# SELF_DESTROY_TEMP_ATK_BOOST: destroy cards scheduled for end-of-next-turn destruction
	for _sd_r: int in range(GameState.GRID_SIZE):
		for _sd_c: int in range(GameState.GRID_SIZE):
			var _sd_card: GameState.CardInstance = GameState.get_card(player, _sd_r, _sd_c)
			if "self_destruct_next_turn" in _sd_card.flags:
				_sd_card.flags.erase("self_destruct_next_turn")
				GameState.post_message("%s is destroyed by self-destruct trap!" % _sd_card.card_name)
				GameState.destroy_card(player, _sd_r, _sd_c)

	# Clear per-turn flags
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character":
				card.attacked_this_turn = false
				card.last_attack_target = Vector2i(-1, -1)
				card.clear_temp_buffs()

	# Cursed Reflection: clear ATK/DEF swap when the defending player's turn ends.
	for _cr_p: int in range(2):
		for _cr_r: int in range(GameState.GRID_SIZE):
			for _cr_c: int in range(GameState.GRID_SIZE):
				var _cr_card: GameState.CardInstance = GameState.get_card(_cr_p, _cr_r, _cr_c)
				if _cr_card.atk_def_swap_clear_on_player_end == player:
					_cr_card.clear_atk_def_swap()

	_expire_trap_carry_def_at_turn_end(player)

	# Prayer: protection for the opponent of this player expires when this turn ends.
	GameState.expire_divine_protection_at_turn_end(player)
	GameState.clear_protected_cells_when_foe_turn_ends(player)
	GameState.clear_tech_temp_name_buffs_when_foe_turn_ends(player)
	GameState.clear_destruction_immune_when_foe_turn_ends(player)
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
	GameState.locked_attack_positions.clear()
	GameState.attacks_used_this_turn = 0
	GameState.opponent_crystal_on_dead_end = 0
	GameState.opponent_crystal_on_dead_end_owner = -1
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type == "character":
				card.attacked_this_turn = false
				# Clear carry_def_bonus (Garrison-type: until end of foe's turn / start of own next turn).
				# Hard Scale uses trap_carry_def_bonus instead — see _expire_trap_carry_def_at_turn_end().
				card.carry_def_bonus = 0
				card.carry_atk_debuff = 0
				# Clear per-turn "once per turn" ability flags
				card.flags.erase("extra_vs_revealed_used")
				card.flags.erase("extra_deadend_turn")
				card.multi_attack_count = 0
				card.bonus_attack_pending = false

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
	GameState.reveal_card_by_ability(opponent, cell.x, cell.y)
	GameState.post_message("Lighthouse: One of Player %d's cards is revealed!" % (opponent + 1))


## PERM_STAT_PENALTY_VS_NON_AFFINITY (Colorful Mage, Dimensional Virus, etc.)
## Applies during Reckoning before destroy so it still fires when the source card is destroyed.
func _apply_reckoning_perm_stat_penalties(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance
) -> void:
	if attacker.card_type == "character" \
			and attacker.ability_type == CharacterData.AbilityType.PERM_STAT_PENALTY_VS_NON_AFFINITY \
			and attacker.effect_nullified_until < GameState.turn_number \
			and defender.card_type == "character":
		_try_apply_perm_stat_penalty_vs_non_affinity(attacker, defender)
	if defender.card_type == "character" \
			and defender.ability_type == CharacterData.AbilityType.PERM_STAT_PENALTY_VS_NON_AFFINITY \
			and defender.effect_nullified_until < GameState.turn_number \
			and attacker.card_type == "character":
		_try_apply_perm_stat_penalty_vs_non_affinity(defender, attacker)


func _try_apply_perm_stat_penalty_vs_non_affinity(
		source: GameState.CardInstance,
		foe: GameState.CardInstance
) -> void:
	if foe.card_type != "character":
		return
	var target_affs: Variant = source.ability_params.get("target_affinities", [])
	if target_affs is Array and not target_affs.is_empty():
		if foe.affinity not in target_affs:
			return
	else:
		var req_aff: int = int(source.ability_params.get("affinity", -1))
		if req_aff != -1 and foe.affinity == req_aff:
			return
	var patk: int = int(source.ability_params.get("atk", 10))
	var pdef: int = int(source.ability_params.get("def", 10))
	foe.current_atk = maxi(0, foe.current_atk - patk)
	foe.current_def = maxi(0, foe.current_def - pdef)
	var scope_label: String = "MATCHING"
	if target_affs is Array and not target_affs.is_empty():
		var labels: PackedStringArray = []
		for aff_val in target_affs:
			var aff_int: int = int(aff_val)
			if aff_int >= 0 and aff_int < CharacterData.Affinity.size():
				labels.append(CharacterData.Affinity.keys()[aff_int])
		scope_label = "/".join(labels) if not labels.is_empty() else "TARGET"
	else:
		var req_aff: int = int(source.ability_params.get("affinity", -1))
		scope_label = "non-%s" % CharacterData.Affinity.keys()[req_aff] if req_aff >= 0 else "MATCHING"
	GameState.post_message("%s: -%d ATK & -%d DEF permanently (%s battle)." % [
		foe.card_name, patk, pdef, scope_label])


func _apply_post_battle_effects(
		result: BattleResolver.BattleResult,
		player: int, opponent: int,
		attacker: GameState.CardInstance, defender: GameState.CardInstance,
		attacker_pos: Vector2i, target_pos: Vector2i
) -> int:
	var extra: int = 0
	if attacker.card_type != "character":
		return extra

	# Skip ability effects if nullified (post-attack target prompts emitted later)
	if attacker.effect_nullified_until >= GameState.turn_number:
		return extra

	if attacker.ability_params.get("reset_on_attack", false) and attacker.eot_atk_bonus > 0:
		var _eot_reset: int = attacker.eot_atk_bonus
		attacker.current_atk = maxi(attacker.base_atk, attacker.current_atk - _eot_reset)
		attacker.eot_atk_bonus = 0
		GameState.post_message("%s: ATK bonus reset after attack (-%d)." % [
			attacker.card_name, _eot_reset])

	match attacker.ability_type:
		CharacterData.AbilityType.PERM_DEF_BOOST_PER_ATTACK_SURVIVE:
			if not result.attacker_destroyed and defender.card_type == "character":
				attacker.perm_def_bonus += attacker.ability_params.get("def", 2)

		CharacterData.AbilityType.ATTACK_STANCE_BOOST:
			var _as_atk: int = attacker.ability_params.get("atk", attacker.ability_params.get("atk_bonus", 0))
			var _as_def_loss: int = attacker.ability_params.get("def_penalty", _as_atk)
			attacker.current_atk += _as_atk
			attacker.current_def = maxi(0, attacker.current_def - _as_def_loss)
			GameState.post_message("%s: +%d ATK, -%d DEF permanently (if possible)." % [
				attacker.card_name, _as_atk, _as_def_loss])

		CharacterData.AbilityType.PERM_ATK_LOSS_PER_ATTACK:
			attacker.current_atk = max(0, attacker.current_atk - attacker.ability_params.get("amount", 5))

		CharacterData.AbilityType.ATK_ZERO_AFTER_WIN:
			if result.defender_destroyed:
				attacker.current_atk = 0

		CharacterData.AbilityType.ONE_USE_COPY_STATS_ON_SURVIVE:
			if not result.attacker_destroyed and not result.defender_destroyed \
					and defender.card_type == "character" \
					and "copy_stats_used" not in attacker.flags:
				attacker.flags.append("copy_stats_used")
				attacker.perm_atk_bonus += defender.current_atk
				attacker.perm_def_bonus += defender.current_def
				GameState.post_message("%s copies %s's stats!" % [attacker.card_name, defender.card_name])

		CharacterData.AbilityType.LOCK_TARGET_ON_ATTACK:
			if not result.defender_destroyed and defender.card_type == "character":
				defender.cannot_attack_until = GameState.turn_number + 1
				GameState.post_message("%s locked — cannot attack until end of next turn." % defender.card_name)

		CharacterData.AbilityType.LOCK_SELF_AFTER_ATTACK:
			attacker.cannot_attack_until = GameState.turn_number + 2
			GameState.post_message("%s locks itself until next turn." % attacker.card_name)

		CharacterData.AbilityType.ONE_USE_EXTRA_ATTACK_ON_KILL:
			if result.defender_destroyed and "extra_kill_used" not in attacker.flags:
				attacker.flags.append("extra_kill_used")
				extra += 1
				GameState.post_message("%s: Kill bonus — extra attack!" % attacker.card_name)

		CharacterData.AbilityType.EXTRA_ATTACK_VS_REVEALED:
			if result.defender_was_exposed and "extra_vs_revealed_used" not in attacker.flags:
				attacker.flags.append("extra_vs_revealed_used")
				extra += 1
				GameState.post_message("%s: Bonus attack for targeting revealed card!" % attacker.card_name)

		CharacterData.AbilityType.ONE_USE_EXTRA_ATTACK_ON_DEAD_END:
			if defender.card_type == "dead_end" and "extra_deadend_used" not in attacker.flags:
				attacker.flags.append("extra_deadend_used")
				extra += 1
				GameState.post_message("%s: Bonus attack for hitting dead end!" % attacker.card_name)

		CharacterData.AbilityType.EXTRA_ATTACK_ON_DEAD_END:
			if defender.card_type == "dead_end" and "extra_deadend_turn" not in attacker.flags:
				attacker.flags.append("extra_deadend_turn")
				extra += 1
				GameState.post_message("%s: Bonus attack for hitting dead end!" % attacker.card_name)

		CharacterData.AbilityType.COIN_FLIP_EXTRA_ATTACK:
			var _coin_count: int = maxi(1, int(attacker.ability_params.get("coin_flips", 1)))
			var _cfea_r: Array = await _do_coin_flips(_coin_count)
			var _heads: int = 0
			for _h: Variant in _cfea_r:
				if bool(_h):
					_heads += 1
			if _heads > 0:
				extra += _heads
				if _coin_count > 1:
					GameState.post_message(
						"%s: %d head(s) on %d coins — %d extra attack(s)!" % [
							attacker.card_name, _heads, _coin_count, _heads])
				else:
					GameState.post_message("%s: Coin flip heads — extra attack!" % attacker.card_name)
			elif _coin_count > 1:
				GameState.post_message("%s: No heads — no extra attack." % attacker.card_name)
			else:
				GameState.post_message("%s: Coin flip tails — no extra attack." % attacker.card_name)

		CharacterData.AbilityType.COIN_FLIP_2_EXTRA_ATTACK:
			var _cf2ea_r: Array = await _do_coin_flips(2)
			if _cf2ea_r[0] and _cf2ea_r[1]:
				extra += 1
				GameState.post_message("%s: Both coins heads — extra attack!" % attacker.card_name)
			else:
				GameState.post_message("%s: Coin flip failed — no extra attack." % attacker.card_name)

		CharacterData.AbilityType.SELF_DEBUFF_ON_ATTACK_AND_DEFEND:
			if attacker.ability_params.get("once_in_reckoning", false):
				if "reckoning_buff_used" not in attacker.flags:
					attacker.flags.append("reckoning_buff_used")
					var _sw_atk: int = int(attacker.ability_params.get("atk", 0))
					var _sw_def: int = int(attacker.ability_params.get("def", 0))
					attacker.current_atk += _sw_atk
					attacker.current_def += _sw_def
					GameState.post_message("%s: +%d ATK / %+d DEF permanently!" % [
						attacker.card_name, _sw_atk, _sw_def])
			elif "atk_debuff_used" not in attacker.flags:
				attacker.flags.append("atk_debuff_used")
				attacker.current_atk = max(0, attacker.current_atk - attacker.ability_params.get("atk", 3))
				GameState.post_message("%s: Self ATK debuff applied." % attacker.card_name)

		CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEAD_END_ATTACK:
			if defender.card_type == "dead_end":
				var _crys: int = attacker.ability_params.get("amount", 300)
				GameState.gain_crystals(player, _crys, "ability")
				GameState.post_message("%s: Gained %d Crystals!" % [attacker.card_name, _crys])
				await _wait_crystal_animation()

		CharacterData.AbilityType.ONE_USE_ATK_BOOST, \
		CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND:
			attacker.one_use_atk_boost_used = true

		CharacterData.AbilityType.DESTROY_SELF_AFTER_BATTLE:
			if not result.attacker_destroyed:
				GameState.destroy_card(player, attacker_pos.x, attacker_pos.y, false)
				GameState.post_message("%s: self-destroyed after battle (no crystal loss)!" % attacker.card_name)

		CharacterData.AbilityType.CRYSTAL_GAIN_ON_DESTROY:
			if result.defender_destroyed and defender.card_type == "character":
				var _cgd: int = attacker.ability_params.get("amount", 80)
				GameState.gain_crystals(player, _cgd, "ability")
				GameState.post_message("%s: +%d Crystals for destroying %s!" % [
					attacker.card_name, _cgd, defender.card_name])
				await _wait_crystal_animation()

		CharacterData.AbilityType.PERM_ATK_BOOST_ONCE_PER_AFFINITY:
			if not result.attacker_destroyed and defender.card_type == "character" \
					and not attacker.one_use_atk_boost_used:
				var _req_aff: int = attacker.ability_params.get("affinity", -1)
				if _req_aff == -1 or defender.affinity != _req_aff:
					attacker.one_use_atk_boost_used = true
					var _pa_gain: int = attacker.ability_params.get("atk", 50)
					attacker.current_atk += _pa_gain
					GameState.post_message("%s: +%d ATK permanently vs %s!" % [
						attacker.card_name, _pa_gain,
						CharacterData.Affinity.keys()[defender.affinity]])

		CharacterData.AbilityType.GAIN_HALF_STATS_ON_SURVIVE:
			if not result.attacker_destroyed and defender.card_type == "character" \
					and not attacker.one_use_atk_boost_used:
				attacker.one_use_atk_boost_used = true
				var _hs_atk: int = defender.current_atk / 2
				var _hs_def: int = defender.current_def / 2
				attacker.current_atk += _hs_atk
				attacker.current_def += _hs_def
				GameState.post_message("%s: gains +%d ATK +%d DEF from battle!" % [attacker.card_name, _hs_atk, _hs_def])

		CharacterData.AbilityType.ATK_PENALTY_VS_DEAD_END:
			if defender.card_type == "dead_end":
				var _ded_pen: int = attacker.ability_params.get("penalty", 50)
				attacker.current_atk = max(0, attacker.current_atk - _ded_pen)
				GameState.post_message("%s: -%d ATK permanently from dead-end attack!" % [attacker.card_name, _ded_pen])

		CharacterData.AbilityType.PERM_ATK_BOOST_ON_KILL_CAPPED:
			if result.defender_destroyed and defender.card_type == "character":
				var _cov_gain: int = attacker.ability_params.get("atk", 10)
				var _cov_max: int = attacker.ability_params.get("max_bonus", 30)
				var _cov_new: int = min(attacker.perm_atk_bonus + _cov_gain, _cov_max)
				var _cov_actual: int = _cov_new - attacker.perm_atk_bonus
				if _cov_actual > 0:
					attacker.perm_atk_bonus = _cov_new
					GameState.post_message("%s: +%d ATK permanently! (bonus: %d/%d)" % [
						attacker.card_name, _cov_actual, _cov_new, _cov_max])

	if defender.card_type == "character" \
			and defender.effect_nullified_until < GameState.turn_number \
			and defender.ability_type == CharacterData.AbilityType.DEFENSE_STANCE_BOOST \
			and attacker.card_type == "character":
		var _ds_def: int = defender.ability_params.get("def", defender.ability_params.get("def_bonus", 0))
		var _ds_atk_loss: int = defender.ability_params.get("atk_penalty", _ds_def)
		defender.current_def += _ds_def
		defender.current_atk = maxi(0, defender.current_atk - _ds_atk_loss)
		GameState.post_message("%s: +%d DEF, -%d ATK permanently (if possible)." % [
			defender.card_name, _ds_def, _ds_atk_loss])

	# VENOM_TOAD_RECKONING: after reckoning, surviving foe receives venom (either battle role)
	if not (GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "bare_hands_brawling" in GameState.active_dungeon_modifiers):
		var _vt_src: GameState.CardInstance = null
		if attacker.card_type == "character" \
				and attacker.ability_type == CharacterData.AbilityType.VENOM_TOAD_RECKONING \
				and attacker.effect_nullified_until < GameState.turn_number:
			_vt_src = attacker
		elif defender.card_type == "character" \
				and defender.ability_type == CharacterData.AbilityType.VENOM_TOAD_RECKONING \
				and defender.effect_nullified_until < GameState.turn_number:
			_vt_src = defender
		if _vt_src != null:
			var _vt_foe: GameState.CardInstance = defender if _vt_src == attacker else attacker
			var _vt_foe_p: int = opponent if _vt_src == attacker else player
			var _vt_foe_pos: Vector2i = target_pos if _vt_src == attacker else attacker_pos
			var _vt_foe_dead: bool = result.defender_destroyed if _vt_src == attacker else result.attacker_destroyed
			if _vt_foe.card_type == "character" and not _vt_foe_dead:
				GameState.apply_unit_effect_flag(_vt_foe_p, _vt_foe_pos.x, _vt_foe_pos.y, "venom")
				GameState.post_message("%s: Venom on %s." % [_vt_src.card_name, _vt_foe.card_name])

	# COPY_ALLY_STATS_ON_DESTROY: Ectoplasm — triggered when an ally is destroyed in battle
	if result.defender_destroyed and defender.card_type == "character" \
			and defender.ability_type != CharacterData.AbilityType.COPY_ALLY_STATS_ON_DESTROY:
		for _ecr: int in range(GameState.GRID_SIZE):
			for _ecc: int in range(GameState.GRID_SIZE):
				var _ecto: GameState.CardInstance = GameState.get_card(opponent, _ecr, _ecc)
				if _ecto.card_type == "character" \
						and _ecto.ability_type == CharacterData.AbilityType.COPY_ALLY_STATS_ON_DESTROY \
						and not _ecto.was_destroyed:
					await _witness_card(opponent, _ecr, _ecc)
					await _witness_pause()
					emit_signal("awaiting_trap_choice",
						"Ectoplasm: Absorb %s's stats? (ATK %d / DEF %d / Cost %d)" % [
							defender.card_name, defender.current_atk, defender.current_def, defender.crystal_cost],
						["Absorb", "Decline"])
					var _ec_choice: int = await ability_choice_resolved
					if _ec_choice == 0:
						_ecto.current_atk = defender.current_atk
						_ecto.perm_atk_bonus = 0
						_ecto.current_def = defender.current_def
						_ecto.perm_def_bonus = 0
						_ecto.crystal_cost = defender.crystal_cost
						GameState.post_message("Ectoplasm absorbs %s's stats!" % defender.card_name)
					break

	# MULTI_ATTACK_ANY: Twin Axe Saintess / Tendrill Tyrant — grant extra attacks up to max
	if attacker.ability_type in [
			CharacterData.AbilityType.MULTI_ATTACK_ANY,
			CharacterData.AbilityType.MULTI_ATTACK_ANY_WITH_ATK_LOSS]:
		var _ma_max: int = attacker.ability_params.get("max_attacks", 2)
		attacker.multi_attack_count += 1
		if attacker.ability_type == CharacterData.AbilityType.MULTI_ATTACK_ANY_WITH_ATK_LOSS:
			var _ma_loss: int = attacker.ability_params.get("atk_loss", 5)
			var _loss_from: int = attacker.ability_params.get("atk_loss_from_attack", 0)
			var _loss_if_unit: bool = attacker.ability_params.get("atk_loss_if_unit", false)
			var _apply_loss: bool = _ma_loss > 0
			if _loss_from > 0:
				_apply_loss = attacker.multi_attack_count >= _loss_from
			if _loss_if_unit and defender.card_type != "character":
				_apply_loss = false
			if _apply_loss:
				attacker.current_atk = max(0, attacker.current_atk - _ma_loss)
				GameState.post_message("%s: -%d ATK after attack." % [attacker.card_name, _ma_loss])
		if attacker.multi_attack_count < _ma_max and not result.attacker_destroyed:
			extra += 1

	# LOCK_ATTACKER_ON_DESTROYED: defender destroys attacker → lock further attacks this turn
	if result.attacker_destroyed and defender.card_type == "character":
		if defender.ability_type == CharacterData.AbilityType.LOCK_ATTACKER_ON_DESTROYED:
			GameState.attacks_remaining = 0
			GameState.post_message("%s: Attacker cannot attack again this turn!" % defender.card_name)

	# Dungeon: Anima Triumph — winning Anima attacker gets one extra attack per turn
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "anima_triumph" in GameState.active_dungeon_modifiers:
		if result.defender_destroyed and not result.attacker_destroyed \
				and attacker.affinity == CharacterData.Affinity.ANIMA \
				and "anima_triumph_extra_used" not in attacker.flags:
			attacker.flags.append("anima_triumph_extra_used")
			extra += 1
			GameState.post_message("Anima Triumph: %s earns an extra attack!" % attacker.display_name)

	# Dungeon: Cosmic Triumph — winning Cosmic attacker grants 200 Crystals
	if GameState.game_mode == GameState.GameMode.DAILY_DUNGEON \
			and "cosmic_triumph" in GameState.active_dungeon_modifiers:
		if result.defender_destroyed and not result.attacker_destroyed \
				and attacker.affinity == CharacterData.Affinity.COSMIC:
			GameState.gain_crystals(player, 200, "cosmic triumph")
			GameState.post_message("Cosmic Triumph: %s wins — gain 200 Crystals!" % attacker.display_name)
			await _wait_crystal_animation()

	return extra

func await_card_effect_flash(card_name: String, card_type: String = "character") -> void:
	if card_name.is_empty():
		return
	BattleLogFormat.log_ability_trigger(card_name, card_type)
	if GameState.card_effect_triggered.get_connections().is_empty():
		return
	GameState.emit_signal("card_effect_triggered", card_name, card_type)
	await card_effect_flash_done


func _log_reckoning_ability_triggers(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		result: BattleResolver.BattleResult
) -> void:
	if result.special_trigger in ["trap_effect", "trap_nullified"]:
		return
	if result.ability_triggered_attacker \
			and attacker != null \
			and attacker.card_type == "character" \
			and not BattleLogFormat.result_has_card_ability_message(result, attacker.card_name):
		var att_detail: String = BattleLogFormat.reckoning_ability_detail(attacker, result, true)
		if not att_detail.is_empty():
			GameState.post_message(BattleLogFormat.format_ability_trigger(attacker, att_detail))
	if result.ability_triggered_defender \
			and defender != null \
			and defender.card_type == "character" \
			and not BattleLogFormat.result_has_card_ability_message(result, defender.card_name):
		var def_detail: String = BattleLogFormat.reckoning_ability_detail(defender, result, false)
		if not def_detail.is_empty():
			GameState.post_message(BattleLogFormat.format_ability_trigger(defender, def_detail))


func apply_on_reveal_abilities(player: int, row: int, col: int) -> void:
	var card: GameState.CardInstance = GameState.get_card(player, row, col)
	if card.card_type != "character" or not card.face_up:
		return
	match card.ability_type:
		CharacterData.AbilityType.HALVE_DEF_ON_FIRST_EXPOSE:
			if "halve_def_applied" in card.flags:
				return
			await await_card_effect_flash(card.card_name)
			card.flags.append("halve_def_applied")
			card.current_def = card.current_def / 2
			GameState.post_message("%s's DEF is halved upon reveal!" % card.card_name)
		CharacterData.AbilityType.DESTROY_SELF_AT_END_OF_EXPOSE_TURN:
			if "expose_destroy_pending" in card.flags:
				return
			await await_card_effect_flash(card.card_name)
			card.flags.append("expose_destroy_pending")


func _has_own_character_to_swap(player: int, exclude_pos: Vector2i) -> bool:
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			if Vector2i(r, c) == exclude_pos:
				continue
			if GameState.get_card(player, r, c).card_type == "character":
				return true
	return false


func _character_has_coin_flip_swap_ability(card: GameState.CardInstance) -> bool:
	if card == null or card.card_type != "character":
		return false
	if card.effect_nullified_until >= GameState.turn_number:
		return false
	if card.ability_type == CharacterData.AbilityType.COIN_FLIP_SWAP_POSITION:
		return true
	var data: CharacterData = CardDatabase.get_character(card.card_name)
	if data == null or data.ability_type != CharacterData.AbilityType.COIN_FLIP_SWAP_POSITION:
		return false
	# Self-heal stale runtime copies that lost ability metadata (copy/revive/transform).
	card.ability_type = data.ability_type
	card.ability_params = data.ability_params.duplicate()
	return true


## Nuki the Tanuki: coin flip after reveal animations, before Reckoning overlay.
func _apply_nuki_pre_reckoning(
		owner_player: int,
		nuki_card: GameState.CardInstance,
		nuki_pos: Vector2i,
		is_attacker_unit: bool
) -> Dictionary:
	if not _character_has_coin_flip_swap_ability(nuki_card):
		return {"card": nuki_card, "pos": nuki_pos}
	await await_card_effect_flash(nuki_card.card_name)
	await _witness_pause()
	var _nuki_cf: Array = await _do_coin_flips(1, owner_player, nuki_pos.x, nuki_pos.y)
	var _flip_label: String = "Heads" if _nuki_cf[0] else "Tails"
	GameState.post_message("%s: Coin flip — %s." % [nuki_card.card_name, _flip_label])
	if not _nuki_cf[0]:
		return {"card": nuki_card, "pos": nuki_pos}
	if not _has_own_character_to_swap(owner_player, nuki_pos):
		GameState.post_message("%s: Heads — but no other unit to swap with." % nuki_card.card_name)
		return {"card": nuki_card, "pos": nuki_pos}
	var _nuki_origin: Vector2i = nuki_pos
	_pending_swap_owner_player = owner_player
	_pending_swap_attacker_pos = nuki_pos
	await _await_attacker_anchored_target_selection(
		owner_player,
		"%s: Heads! Choose 1 of your units to swap position with." % nuki_card.card_name,
		"own_character_for_swap")
	nuki_pos = _nuki_origin
	nuki_card = GameState.get_card(owner_player, nuki_pos.x, nuki_pos.y)
	_pending_swap_attacker_pos = Vector2i(-1, -1)
	_pending_swap_owner_player = -1
	if is_attacker_unit:
		GameState.attacker_card = nuki_card
		GameState.attacker_pos = nuki_pos
	BattleResolver.calculate_field_bonuses(owner_player)
	BattleResolver.calculate_field_bonuses(GameState.get_opponent(owner_player))
	return {"card": nuki_card, "pos": nuki_pos}


func _prompt_and_await_target_selection(prompt: String, filter: String) -> void:
	_flow_block_depth += 1
	emit_signal("awaiting_target_selection", prompt, filter)
	await ability_selection_done
	_flow_block_depth -= 1

func _await_attacker_anchored_target_selection(
		attacker_player: int, prompt: String, filter: String) -> void:
	var _saved_cp: int = GameState.current_player
	_pending_reveal_attacker_player = attacker_player
	GameState.current_player = attacker_player
	await _prompt_and_await_target_selection(prompt, filter)
	GameState.current_player = _saved_cp
	_pending_reveal_attacker_player = -1

func _await_reveal_opponent_hidden_selection(attacker: GameState.CardInstance, attacker_player: int) -> void:
	var foe: int = GameState.get_opponent(attacker_player)
	if not _has_hidden_cells(foe):
		GameState.post_message("%s: No hidden foe cells to reveal." % attacker.card_name)
		return
	await _await_attacker_anchored_target_selection(
		attacker_player,
		"%s: Choose 1 opponent cell to reveal." % attacker.card_name,
		"opponent_any_hidden")

func maybe_apply_on_expose_reveal_foe(owner_player: int, row: int, col: int) -> void:
	var card: GameState.CardInstance = GameState.get_card(owner_player, row, col)
	if card.card_type != "character" or not card.face_up:
		return
	if card.ability_type != CharacterData.AbilityType.ON_EXPOSE_REVEAL_FOE_ONCE:
		return
	if "expose_reveal_used" in card.flags:
		return
	card.flags.append("expose_reveal_used")
	var foe: int = GameState.get_opponent(owner_player)
	if not _has_hidden_cells(foe):
		GameState.post_message("%s: No hidden foe cells to reveal." % card.card_name)
		return
	_pending_lockpicker_owner = owner_player
	var _saved_cp: int = GameState.current_player
	GameState.current_player = owner_player
	await _prompt_and_await_target_selection(
		"%s: Choose 1 foe cell to reveal." % card.card_name,
		"ability_lockpicker_reveal")
	GameState.current_player = _saved_cp
	_pending_lockpicker_owner = -1

static func _has_hidden_cells(player_index: int) -> bool:
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var inst: GameState.CardInstance = GameState.get_card(player_index, r, c)
			if not inst.face_up and not inst.was_destroyed:
				return true
	return false

static func _has_wk17_foe_pick_target(
		foe_player: int, mode: String, attacker_pos: Vector2i, target_pos: Vector2i) -> bool:
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var pos: Vector2i = Vector2i(r, c)
			if mode == "redirect_attacker" and pos == attacker_pos:
				continue
			if mode == "substitute_foe_attacker" and pos == target_pos:
				continue
			var inst: GameState.CardInstance = GameState.get_card(foe_player, r, c)
			if inst.card_type == "character":
				return true
	return false

func _apply_wk17_pre_battle(
		player: int, opponent: int,
		attacker: GameState.CardInstance, defender: GameState.CardInstance,
		attacker_pos: Vector2i, target_pos: Vector2i,
		defender_was_exposed: bool
) -> Dictionary:
	_wk17_friendly_fire = false
	_wk17_friendly_fire_pos = Vector2i(-1, -1)
	var wk17_player: int = -1
	var wk17_pos: Vector2i = Vector2i(-1, -1)
	var wk17_as_defender: bool = false
	if attacker.ability_type == CharacterData.AbilityType.PRE_BATTLE_COIN_FLIP_2_REDIRECT_OR_DESTROY:
		wk17_player = player
		wk17_pos = attacker_pos
	elif defender.card_type == "character" \
			and defender.ability_type == CharacterData.AbilityType.PRE_BATTLE_COIN_FLIP_2_REDIRECT_OR_DESTROY:
		wk17_player = opponent
		wk17_pos = target_pos
		wk17_as_defender = true
	else:
		return {"abort": false, "target_pos": target_pos, "defender_was_exposed": defender_was_exposed}

	var wk17_card: GameState.CardInstance = GameState.get_card(wk17_player, wk17_pos.x, wk17_pos.y)
	var wk17_name: String = wk17_card.card_name
	await await_card_effect_flash(wk17_name)
	var _wk17_cf: Array = await _do_coin_flips(2)
	var _heads: int = 0
	for _h in _wk17_cf:
		if _h:
			_heads += 1

	if _heads == 0:
		GameState.post_message("%s: Both tails — destroyed!" % wk17_name)
		GameState.destroy_card(wk17_player, wk17_pos.x, wk17_pos.y, false)
		if wk17_as_defender:
			defender_was_exposed = true
			return {"abort": false, "target_pos": target_pos, "defender_was_exposed": defender_was_exposed}
		return {"abort": true, "target_pos": target_pos, "defender_was_exposed": defender_was_exposed}

	if _heads == 2:
		var wk17_foe: int = GameState.get_opponent(wk17_player)
		_pending_wk17_foe_player = wk17_foe
		_pending_wk17_mode = "redirect_attacker" if wk17_as_defender else "substitute_foe_attacker"
		_pending_wk17_exclude_pick_pos = attacker_pos if wk17_as_defender else target_pos
		_pending_wk17_defender_pos = target_pos
		if wk17_as_defender:
			_wk17_initiating_attacker_pos = attacker_pos
		if not _has_wk17_foe_pick_target(
				wk17_foe, _pending_wk17_mode, attacker_pos, target_pos):
			GameState.post_message("%s: Both heads — no valid ally to target." % wk17_name)
			_pending_wk17_foe_player = -1
			_pending_wk17_mode = ""
			_pending_wk17_exclude_pick_pos = Vector2i(-1, -1)
			_pending_wk17_defender_pos = Vector2i(-1, -1)
			return {"abort": false, "target_pos": target_pos, "defender_was_exposed": defender_was_exposed}
		var _saved_cp: int = GameState.current_player
		GameState.current_player = wk17_foe
		var _wk17_prompt: String
		if _pending_wk17_mode == "substitute_foe_attacker":
			_wk17_prompt = "%s: Both heads! Choose one of your allies to fight in place of %s." % [
				wk17_name, wk17_name]
			_wk17_initiating_attacker_pos = attacker_pos
		else:
			_wk17_prompt = "%s: Both heads! Choose one of your allies as the target." % wk17_name
		await _prompt_and_await_target_selection(_wk17_prompt, "wk17_foe_pick_character")
		GameState.current_player = _saved_cp
		_pending_wk17_foe_player = -1
		_pending_wk17_mode = ""
		_pending_wk17_exclude_pick_pos = Vector2i(-1, -1)
		_pending_wk17_defender_pos = Vector2i(-1, -1)

	return {"abort": false, "target_pos": target_pos, "defender_was_exposed": defender_was_exposed}

static func _tech_name_tokens(data: TechCardData) -> Array:
	if data == null:
		return []
	if data.effect_params.has("name_tokens"):
		return data.effect_params.get("name_tokens", [])
	var _nc: String = str(data.effect_params.get("name_contains", "")).strip_edges()
	if _nc.is_empty():
		return []
	return [_nc.to_lower()]

static func _corner_cells_for_player() -> Array:
	var _last: int = GameState.GRID_SIZE - 1
	return [
		Vector2i(0, 0),
		Vector2i(0, _last),
		Vector2i(_last, 0),
		Vector2i(_last, _last),
	]

func _apply_temp_name_buff_tech(player: int, data: TechCardData) -> void:
	var _tokens: Array = _tech_name_tokens(data)
	var _atk: int = int(data.effect_params.get("atk", 0))
	var _def: int = int(data.effect_params.get("def", 0))
	var _buffed: int = 0
	for _r: int in range(GameState.GRID_SIZE):
		for _c: int in range(GameState.GRID_SIZE):
			var _card: GameState.CardInstance = GameState.get_card(player, _r, _c)
			if _card.card_type != "character" or not _card.face_up:
				continue
			if not GameState.card_name_has_any_token(_card.card_name, _tokens):
				continue
			_card.temp_atk_bonus += _atk
			_card.temp_def_bonus += _def
			_buffed += 1
	if bool(data.effect_params.get("until_foe_turn_end", false)):
		GameState.tech_temp_name_buffs.append({
			"owner": player,
			"tokens": _tokens,
			"atk": _atk,
			"def": _def,
		})
	GameState.post_message("%s: %d matching unit(s) gain +%d ATK & +%d DEF." % [
		data.card_name, _buffed, _atk, _def])

func _destroy_all_revived_and_tokens() -> void:
	var _destroyed: int = 0
	for _p: int in range(2):
		for _r: int in range(GameState.GRID_SIZE):
			for _c: int in range(GameState.GRID_SIZE):
				var _card: GameState.CardInstance = GameState.get_card(_p, _r, _c)
				if _card.card_type != "character":
					continue
				if not _card.is_revived and not _card.is_token:
					continue
				GameState.destroy_card(_p, _r, _c, false)
				_destroyed += 1
	GameState.post_message("Cremation: %d revived/token unit(s) destroyed." % _destroyed)

func _apply_princess_magic_reckoning(
		attacker_player: int,
		defender_player: int,
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		result: BattleResolver.BattleResult
) -> void:
	for _pm_owner: int in range(2):
		if not GameState.princess_magic_active[_pm_owner]:
			continue
		var _pm_foe: int = GameState.get_opponent(_pm_owner)
		var _princess_card: GameState.CardInstance = null
		if defender.card_type == "character" \
				and defender_player == _pm_foe \
				and "princess" in defender.flags:
			_princess_card = defender
		elif attacker.card_type == "character" \
				and attacker_player == _pm_foe \
				and "princess" in attacker.flags:
			_princess_card = attacker
		if _princess_card == null:
			continue
		if _princess_card == defender:
			result.defender_destroyed = true
			result.defender_crystal_loss = 0
		else:
			result.attacker_destroyed = true
			result.attacker_crystal_loss = 0
		GameState.princess_magic_active[_pm_owner] = false
		GameState.post_message("Princess Magic: %s is destroyed!" % _princess_card.card_name)

static func _has_rg_foe_pick_target(attacker_player: int, exclude_pos: Vector2i) -> bool:
	for _r: int in range(GameState.GRID_SIZE):
		for _c: int in range(GameState.GRID_SIZE):
			var _pos: Vector2i = Vector2i(_r, _c)
			if _pos == exclude_pos:
				continue
			var _card: GameState.CardInstance = GameState.get_card(attacker_player, _r, _c)
			if _card.card_type == "character":
				return true
	return false

func _apply_rift_guardian_pre_battle(
		player: int,
		opponent: int,
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		attacker_pos: Vector2i,
		target_pos: Vector2i
) -> Dictionary:
	_rg_friendly_fire = false
	_rg_friendly_fire_pos = Vector2i(-1, -1)
	if defender.card_type != "character" or not defender.is_union:
		return {"abort": false}
	if defender.ability_type != CharacterData.AbilityType.RECKONING_FOE_DEFENDER_SUBSTITUTE:
		return {"abort": false}
	if defender.affinity != CharacterData.Affinity.ARCANE:
		return {"abort": false}
	if defender.ability_params.get("requires_revived_or_token", true) \
			and not GameState.field_has_revived_or_token():
		return {"abort": false}
	await await_card_effect_flash(defender.card_name)
	if not _has_rg_foe_pick_target(player, attacker_pos):
		GameState.post_message("%s: No valid substitute — effect fizzles." % defender.card_name)
		return {"abort": false}
	_pending_rg_attacker_player = player
	_pending_rg_exclude_pos = attacker_pos
	_pending_rg_defender_pos = target_pos
	var _saved_cp: int = GameState.current_player
	GameState.current_player = player
	await _prompt_and_await_target_selection(
		"%s: Choose 1 of your units to fight in place of %s." % [
			defender.card_name, defender.card_name],
		"rift_guardian_foe_pick")
	GameState.current_player = _saved_cp
	_pending_rg_attacker_player = -1
	_pending_rg_exclude_pos = Vector2i(-1, -1)
	_pending_rg_defender_pos = Vector2i(-1, -1)
	return {"abort": false}

func resolve_rift_guardian_substitute(
		attacker_player: int,
		substitute_pos: Vector2i,
		rg_defender_pos: Vector2i
) -> void:
	var _rg_name: String = "Rift Guardian"
	var _rg_card: GameState.CardInstance = GameState.get_card(
		GameState.get_opponent(attacker_player), rg_defender_pos.x, rg_defender_pos.y)
	if _rg_card != null and _rg_card.card_type == "character":
		_rg_name = _rg_card.card_name
	GameState.post_message("%s: Substitute fights in place of %s!" % [_rg_name, _rg_name])
	await resolve_brainwash_friendly_fire(attacker_player, substitute_pos)

func resolve_ancestral_spirit_revive() -> void:
	var pending: Dictionary = GameState._pending_ancestral_revive
	if pending.is_empty():
		return
	var owner: int = int(pending.get("owner", -1))
	var trap_row: int = int(pending.get("trap_row", -1))
	var trap_col: int = int(pending.get("trap_col", -1))
	var destroy_row: int = int(pending.get("destroy_row", -1))
	var destroy_col: int = int(pending.get("destroy_col", -1))
	var revived_src: GameState.CardInstance = pending.get("card", null)
	GameState._pending_ancestral_revive = {}
	if owner < 0 or revived_src == null:
		return
	var trap_data: TrapData = CardDatabase.get_trap("Ancestral Spirit")
	emit_signal("awaiting_trap_choice",
		"Ancestral Spirit: Revive %s?" % revived_src.card_name,
		["Revive", "Decline"])
	var _choice: int = await ability_choice_resolved
	if _choice != 0:
		return
	if trap_row >= 0 and trap_col >= 0:
		var trap_card: GameState.CardInstance = GameState.get_card(owner, trap_row, trap_col)
		if trap_card.card_type == "trap":
			GameState.reveal_card_by_ability(owner, trap_row, trap_col)
			await await_card_effect_flash(trap_data.card_name if trap_data else trap_card.card_name, "trap")
			GameState.void_trap(owner, trap_row, trap_col)
	if not GameState.is_valid_revive_placement_cell(owner, destroy_row, destroy_col):
		GameState.post_message("Ancestral Spirit: No valid cell to revive.")
		return
	var placed: GameState.CardInstance = GameState._clone_card_for_revive(revived_src)
	placed.is_revived = true
	placed.face_up = true
	placed.revealed_on_turn = GameState.turn_number
	placed.attacked_this_turn = false
	GameState.grids[owner][destroy_row][destroy_col] = placed
	GameState.emit_signal("card_revealed", owner, destroy_row, destroy_col)
	BattleResolver.recalculate_all_field_bonuses()
	GameState.post_message("Ancestral Spirit revived %s!" % placed.card_name)

func _emit_post_attack_target_selections(
		result: BattleResolver.BattleResult,
		player: int, opponent: int,
		attacker: GameState.CardInstance, defender: GameState.CardInstance,
		attacker_pos: Vector2i, target_pos: Vector2i
) -> void:
	if attacker.card_type != "character":
		return

	# Pending reveals from BattleResolver (e.g. COIN_FLIP_2_DESTROY_NON_AFFINITY win)
	if result.pending_reveal_opponent_cell:
		await _await_reveal_opponent_hidden_selection(attacker, player)

	if attacker.effect_nullified_until >= GameState.turn_number:
		return

	match attacker.ability_type:
		CharacterData.AbilityType.REVEAL_ON_WIN:
			if result.defender_destroyed:
				await _await_reveal_opponent_hidden_selection(attacker, player)

		CharacterData.AbilityType.REVEAL_ON_ANY_ATTACK:
			await _await_reveal_opponent_hidden_selection(attacker, player)

		CharacterData.AbilityType.REVEAL_ON_DEAD_END_ATTACK:
			if defender.card_type == "dead_end":
				await _await_reveal_opponent_hidden_selection(attacker, player)

		CharacterData.AbilityType.REVEAL_ON_TRAP_ATTACK:
			if result.special_trigger in ["trap_effect", "trap_nullified"]:
				await _await_reveal_opponent_hidden_selection(attacker, player)

		CharacterData.AbilityType.REVEAL_ADJACENT_AFTER_ATTACK:
			await _await_attacker_anchored_target_selection(
				player,
				"Scout Probe: Choose an adjacent square to reveal.",
				"adjacent")

		CharacterData.AbilityType.POST_BATTLE_COIN_FLIP_DESTROY:
			if not result.attacker_destroyed:
				await _await_attacker_anchored_target_selection(
					player,
					"%s: Choose 1 opponent unit to flip a coin on." % attacker.card_name,
					"opponent_character_ability_destroy")

		CharacterData.AbilityType.POST_ATTACK_DESTROY_FIELD_ONCE:
			if result.attacker_destroyed:
				return
			if "post_attack_destroy_used" in attacker.flags:
				return
			attacker.flags.append("post_attack_destroy_used")
			await _await_attacker_anchored_target_selection(
				player,
				"%s: Choose 1 card on the field to destroy." % attacker.card_name,
				"any_field_card_destroy")

func _plant29_has_valid_targets(player: int, heads: bool) -> bool:
	if heads:
		for p: int in range(2):
			for r: int in range(GameState.GRID_SIZE):
				for c: int in range(GameState.GRID_SIZE):
					var card: GameState.CardInstance = GameState.get_card(p, r, c)
					if card.card_type == "character" and card.face_up:
						return true
		return false
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var own: GameState.CardInstance = GameState.get_card(player, r, c)
			if own.card_type == "character":
				return true
	return false


func _apply_end_of_turn_boosts(player: int) -> void:
	# Applied at start of own turn = "end of opponent's turn"
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player, r, c)
			if card.card_type != "character" or not card.face_up:
				continue
			match card.ability_type:
				CharacterData.AbilityType.PERM_BOOST_END_OF_TURN:
					if card.ability_params.get("on_crystal_gain", false) \
							or card.ability_params.get("vs_trap", false):
						continue
					var _hs_atk: int = card.ability_params.get("atk", 0)
					var _hs_def: int = card.ability_params.get("def", 0)
					var _max_bonus: int = int(card.ability_params.get("max_atk", -1))
					if _max_bonus >= 0:
						var _gained: int = maxi(0, card.current_atk - card.base_atk)
						if _gained >= _max_bonus:
							continue
						_hs_atk = mini(_hs_atk, _max_bonus - _gained)
						if _hs_atk <= 0:
							continue
					await await_card_effect_flash(card.card_name)
					await _witness_pause()
					card.current_atk += _hs_atk
					card.current_def += _hs_def
					GameState.post_message("%s: +%d ATK & +%d DEF permanently." % [
						card.card_name, _hs_atk, _hs_def])
				CharacterData.AbilityType.PERM_ATK_BOOST_PER_SURVIVE_OPP_TURN:
					if "reckoning_participated" not in card.flags:
						continue
					card.flags.erase("reckoning_participated")
					var _db_atk: int = card.ability_params.get("atk", 2)
					await await_card_effect_flash(card.card_name)
					await _witness_pause()
					card.current_atk += _db_atk
					GameState.post_message("%s: +%d ATK permanently after surviving Reckoning." % [
						card.card_name, _db_atk])
				CharacterData.AbilityType.SWAP_ATK_DEF_PER_OPP_TURN:
					await await_card_effect_flash(card.card_name)
					await _witness_pause()
					var _vc_atk: int = card.current_atk
					var _vc_def: int = card.current_def
					card.current_atk = _vc_def
					card.current_def = _vc_atk
					GameState.post_message("%s: ATK & DEF swapped (%d / %d)." % [
						card.card_name, card.current_atk, card.current_def])
