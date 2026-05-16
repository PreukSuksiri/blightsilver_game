extends Node
## CardRuleEngine — data-driven card rule evaluation bus.
##
## Usage:
##   CardRuleEngine.emit_trigger(CardRule.TriggerType.BATTLE_WIN_SELF, {
##       "source_player": player,
##       "source_card": card_instance,
##       ...
##   })
##
## Cards register their rules via CardInstance.active_rules (Array of CardRule).
## The engine iterates all cards on both grids, finds matching rules, and
## executes their effects.  BATTLE_PRE_RESOLVE rules are pushed onto a LIFO
## chain stack; call resolve_chain() after emit_trigger to drain it.

# ─────────────────────────────────────────────────────────────
# Chain stack
# ─────────────────────────────────────────────────────────────
## Each entry: { rule: CardRule, source_card: CardInstance, source_player: int, ctx: Dictionary }
var _chain_stack: Array = []

## Rules deactivated this tick (drained at end of emit_trigger)
var _to_deactivate: Array = []   # Array of { card: CardInstance, rule: CardRule }

# ─────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────

## Fire a trigger and execute all matching rule effects immediately.
## BATTLE_PRE_RESOLVE rules are pushed onto _chain_stack instead.
## ctx keys used by different triggers:
##   source_player   int — the player who owns the triggering card / action
##   source_card     CardInstance — the card that owns the rule (for SELF scope)
##   target_card     CardInstance — the other card in a battle / tech context
##   target_player   int
##   delta           int — crystal amount for CRYSTAL_* triggers
##   tech_name       String — for TECH_CARD_USED_* triggers
##   flag            String — for CARD_FLAG_* triggers
##   attacker        CardInstance — for BATTLE_* triggers
##   defender        CardInstance — for BATTLE_* triggers
##   dice_roll       int
func emit_trigger(trigger: CardRule.TriggerType, ctx: Dictionary) -> void:
	if GameState.current_phase == GameState.Phase.NONE:
		return

	var matches: Array = _collect_matches(trigger, ctx)
	# Sort by priority descending so higher-priority rules fire first
	matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["rule"] as CardRule).priority > (b["rule"] as CardRule).priority
	)

	for entry: Dictionary in matches:
		var rule: CardRule = entry["rule"]
		if rule.trigger == CardRule.TriggerType.BATTLE_PRE_RESOLVE:
			_chain_stack.push_back(entry)
		else:
			_execute_effect(rule, entry["source_card"], entry["source_player"], ctx)
			if rule.deactivation == CardRule.DeactivationType.ON_EFFECT_USED:
				_to_deactivate.append({"card": entry["source_card"], "rule": rule})

	# Drain deactivations
	for d: Dictionary in _to_deactivate:
		(d["card"] as GameState.CardInstance).active_rules.erase(d["rule"])
	_to_deactivate.clear()

## Drain the BATTLE_PRE_RESOLVE chain stack (LIFO — last in, first out).
## Call this inside TurnManager before applying BattleResult.
func resolve_chain(ctx: Dictionary) -> void:
	while not _chain_stack.is_empty():
		var entry: Dictionary = _chain_stack.pop_back()
		var rule: CardRule = entry["rule"]
		_execute_effect(rule, entry["source_card"], entry["source_player"], ctx)
		if rule.deactivation == CardRule.DeactivationType.ON_EFFECT_USED:
			(entry["source_card"] as GameState.CardInstance).active_rules.erase(rule)

## Call at the end of each player's turn to process TURN_END deactivations.
func tick_turn_end(player: int) -> void:
	_drain_turn_end_deactivations(player)

## Deactivate and remove all rules from a card (e.g. when the card is destroyed).
func deactivate_rules_for(card: GameState.CardInstance) -> void:
	card.active_rules.clear()

# ─────────────────────────────────────────────────────────────
# Matching
# ─────────────────────────────────────────────────────────────

func _collect_matches(trigger: CardRule.TriggerType, ctx: Dictionary) -> Array:
	var result: Array = []
	for p: int in [0, 1]:
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.grids[p][r][c]
				for rule: CardRule in card.active_rules:
					if rule.trigger != trigger:
						continue
					if not _scope_matches(rule, card, p, ctx):
						continue
					if rule.node_filter != null and not _node_filter_matches(rule.node_filter, card, p, ctx):
						continue
					if rule.stat_filter != null and not _stat_filter_matches(rule.stat_filter, ctx):
						continue
					if not _deactivation_allows(rule, card, p):
						continue
					result.append({
						"rule": rule,
						"source_card": card,
						"source_player": p,
					})
	return result

func _scope_matches(rule: CardRule, card: GameState.CardInstance, owner_player: int, ctx: Dictionary) -> bool:
	match rule.scope:
		CardRule.Scope.SELF:
			# The triggering card must be this card itself
			var src_card: Variant = ctx.get("source_card", null)
			var att: Variant = ctx.get("attacker", null)
			var def_card: Variant = ctx.get("defender", null)
			# Accept match if any of the context cards IS this card
			if src_card == card:
				return true
			if att == card:
				return true
			if def_card == card:
				return true
			return false
		CardRule.Scope.FIELD:
			# Field scope: rule owner just needs to be on the field (any player)
			return true
		_:
			return false

func _node_filter_matches(f: CardNodeFilter, card: GameState.CardInstance, owner_player: int, ctx: Dictionary) -> bool:
	# Owner filter
	var src_player: int = ctx.get("source_player", -1)
	match f.owner:
		CardNodeFilter.OwnerFilter.SELF_PLAYER:
			if owner_player != src_player:
				return false
		CardNodeFilter.OwnerFilter.OPPONENT_PLAYER:
			if owner_player == src_player:
				return false

	# Type filter
	match f.type:
		CardNodeFilter.TypeFilter.CHARACTER:
			if card.card_type != "character":
				return false
		CardNodeFilter.TypeFilter.TRAP:
			if card.card_type != "trap":
				return false
		CardNodeFilter.TypeFilter.DEAD_END:
			if card.card_type != "dead_end":
				return false

	# Face filter
	match f.face:
		CardNodeFilter.FaceFilter.FACE_UP:
			if not card.face_up:
				return false
		CardNodeFilter.FaceFilter.FACE_DOWN:
			if card.face_up:
				return false

	# Rarity filter
	if f.rarity != CardNodeFilter.RarityFilter.ANY:
		var rarity_map: Dictionary = {
			CardNodeFilter.RarityFilter.COMMON: 0,
			CardNodeFilter.RarityFilter.UNCOMMON: 1,
			CardNodeFilter.RarityFilter.RARE: 2,
			CardNodeFilter.RarityFilter.LEGENDARY: 3,
		}
		if card.rarity != rarity_map.get(f.rarity, -1):
			return false

	# Flag filters
	if f.has_flag != "" and f.has_flag not in card.flags:
		return false
	if f.lacks_flag != "" and f.lacks_flag in card.flags:
		return false

	# Affinity filter
	if f.affinity != -1 and card.affinity != f.affinity:
		return false

	# ATK/DEF range filters
	if f.min_atk >= 0 and card.get_effective_atk() < f.min_atk:
		return false
	if f.max_atk >= 0 and card.get_effective_atk() > f.max_atk:
		return false
	if f.min_def >= 0 and card.get_effective_def() < f.min_def:
		return false
	if f.max_def >= 0 and card.get_effective_def() > f.max_def:
		return false

	return true

func _stat_filter_matches(f: CardBattleStatFilter, ctx: Dictionary) -> bool:
	var att: Variant = ctx.get("attacker", null)
	var def_card: Variant = ctx.get("defender", null)
	if att == null or def_card == null:
		return true  # no battle context — allow

	var eff_atk: int = (att as GameState.CardInstance).get_effective_atk()
	var eff_def: int = (def_card as GameState.CardInstance).get_effective_def()

	if f.attacker_min_atk >= 0 and eff_atk < f.attacker_min_atk:
		return false
	if f.attacker_max_atk >= 0 and eff_atk > f.attacker_max_atk:
		return false
	if f.defender_min_def >= 0 and eff_def < f.defender_min_def:
		return false
	if f.defender_max_def >= 0 and eff_def > f.defender_max_def:
		return false
	if f.atk_exceeds_def_by >= 0 and (eff_atk - eff_def) < f.atk_exceeds_def_by:
		return false
	if f.def_exceeds_atk_by >= 0 and (eff_def - eff_atk) < f.def_exceeds_atk_by:
		return false

	return true

func _deactivation_allows(rule: CardRule, card: GameState.CardInstance, _owner_player: int) -> bool:
	match rule.deactivation:
		CardRule.DeactivationType.ON_FLAG_PRESENT:
			var flag: String = rule.deactivation_params.get("flag", "")
			if flag != "" and flag in card.flags:
				return false
		CardRule.DeactivationType.ON_FLAG_ABSENT:
			var flag: String = rule.deactivation_params.get("flag", "")
			if flag != "" and flag not in card.flags:
				return false
	return true

# ─────────────────────────────────────────────────────────────
# Effect Execution
# ─────────────────────────────────────────────────────────────

func _execute_effect(rule: CardRule, source_card: GameState.CardInstance, owner_player: int, ctx: Dictionary) -> void:
	var params: Dictionary = rule.effect_params
	var opponent_player: int = GameState.get_opponent(owner_player)

	match rule.effect:
		CardRule.EffectType.ATK_MOD:
			var amount: int = params.get("amount", 0)
			var target_cards: Array = _resolve_target_cards(params.get("target", "self"), source_card, owner_player, ctx)
			for tc: GameState.CardInstance in target_cards:
				tc.temp_atk_bonus += amount

		CardRule.EffectType.DEF_MOD:
			var amount: int = params.get("amount", 0)
			var target_cards: Array = _resolve_target_cards(params.get("target", "self"), source_card, owner_player, ctx)
			for tc: GameState.CardInstance in target_cards:
				tc.temp_def_bonus += amount

		CardRule.EffectType.ATK_DEBUFF:
			var amount: int = params.get("amount", 0)
			var target_cards: Array = _resolve_target_cards(params.get("target", "self"), source_card, owner_player, ctx)
			for tc: GameState.CardInstance in target_cards:
				tc.atk_debuff += amount

		CardRule.EffectType.GAIN_CRYSTALS:
			var amount: int = params.get("amount", 0)
			var p: int = _resolve_player(params.get("player", "owner"), owner_player)
			GameState.gain_crystals(p, amount)

		CardRule.EffectType.LOSE_CRYSTALS:
			var amount: int = params.get("amount", 0)
			var p: int = _resolve_player(params.get("player", "owner"), owner_player)
			GameState.lose_crystals(p, amount)

		CardRule.EffectType.SKIP_TURN:
			var p: int = _resolve_player(params.get("player", "opponent"), owner_player)
			GameState.skip_next_turn[p] = true

		CardRule.EffectType.CANNOT_ATTACK:
			var turns: int = params.get("turns", 1)
			var target_cards: Array = _resolve_target_cards(params.get("target", "self"), source_card, owner_player, ctx)
			for tc: GameState.CardInstance in target_cards:
				tc.cannot_attack_until = GameState.turn_number + turns

		CardRule.EffectType.NULLIFY_EFFECT:
			var turns: int = params.get("turns", 1)
			var target_cards: Array = _resolve_target_cards(params.get("target", "self"), source_card, owner_player, ctx)
			for tc: GameState.CardInstance in target_cards:
				tc.effect_nullified_until = GameState.turn_number + turns

		CardRule.EffectType.APPLY_FLAG:
			var flag: String = params.get("flag", "")
			if flag == "":
				return
			var target_cards: Array = _resolve_target_cards(params.get("target", "self"), source_card, owner_player, ctx)
			for tc: GameState.CardInstance in target_cards:
				var pos: Vector2i = GameState.find_card_position(owner_player, tc)
				if pos.x >= 0:
					GameState.add_flag(owner_player, pos.x, pos.y, flag)
				elif pos.x < 0:
					var pos2: Vector2i = GameState.find_card_position(opponent_player, tc)
					if pos2.x >= 0:
						GameState.add_flag(opponent_player, pos2.x, pos2.y, flag)

		CardRule.EffectType.REMOVE_FLAG:
			var flag: String = params.get("flag", "")
			if flag == "":
				return
			var target_cards: Array = _resolve_target_cards(params.get("target", "self"), source_card, owner_player, ctx)
			for tc: GameState.CardInstance in target_cards:
				var pos: Vector2i = GameState.find_card_position(owner_player, tc)
				if pos.x >= 0:
					GameState.remove_flag(owner_player, pos.x, pos.y, flag)
				elif pos.x < 0:
					var pos2: Vector2i = GameState.find_card_position(opponent_player, tc)
					if pos2.x >= 0:
						GameState.remove_flag(opponent_player, pos2.x, pos2.y, flag)

		CardRule.EffectType.FORCE_SHIELD:
			var target_cards: Array = _resolve_target_cards(params.get("target", "self"), source_card, owner_player, ctx)
			for tc: GameState.CardInstance in target_cards:
				tc.force_shielded = true

		CardRule.EffectType.HALVE_STATS:
			var target_cards: Array = _resolve_target_cards(params.get("target", "self"), source_card, owner_player, ctx)
			for tc: GameState.CardInstance in target_cards:
				tc.halve_stats()

		CardRule.EffectType.POST_MESSAGE:
			var text: String = params.get("text", "")
			if text != "":
				GameState.post_message(text)

		CardRule.EffectType.DESTROY_CARD:
			var pay_cost: bool = params.get("pay_cost", true)
			var target_cards: Array = _resolve_target_cards(params.get("target", "self"), source_card, owner_player, ctx)
			for tc: GameState.CardInstance in target_cards:
				var pos: Vector2i = GameState.find_card_position(owner_player, tc)
				if pos.x >= 0:
					GameState.destroy_card(owner_player, pos.x, pos.y, pay_cost)
				else:
					var pos2: Vector2i = GameState.find_card_position(opponent_player, tc)
					if pos2.x >= 0:
						GameState.destroy_card(opponent_player, pos2.x, pos2.y, pay_cost)

		CardRule.EffectType.REVEAL_CARD:
			var target_cards: Array = _resolve_target_cards(params.get("target", "self"), source_card, owner_player, ctx)
			for tc: GameState.CardInstance in target_cards:
				var pos: Vector2i = GameState.find_card_position(owner_player, tc)
				if pos.x >= 0:
					GameState.reveal_card(owner_player, pos.x, pos.y)
				else:
					var pos2: Vector2i = GameState.find_card_position(opponent_player, tc)
					if pos2.x >= 0:
						GameState.reveal_card(opponent_player, pos2.x, pos2.y)

		CardRule.EffectType.DRAW_TECH:
			var count: int = params.get("count", 1)
			var p: int = _resolve_player(params.get("player", "owner"), owner_player)
			# Drawing tech cards requires CardDatabase — add named cards from DB
			# Simplified: increase hand count (full deck draw logic is in SetupPhase)
			GameState.post_message("Player %d draws %d Tech Card(s)." % [p + 1, count])

		CardRule.EffectType.RECALCULATE_BATTLE:
			# Signal to TurnManager to recalculate — handled by caller after chain resolves
			GameState.post_message("Battle recalculated by card effect.")

# ─────────────────────────────────────────────────────────────
# Target resolution
# ─────────────────────────────────────────────────────────────

## Resolve a target string into an Array of CardInstance references.
## target strings: "self", "attacker", "defender",
##   "owner_all", "opponent_all", "owner_random", "opponent_random"
func _resolve_target_cards(target: String, source_card: GameState.CardInstance, owner_player: int, ctx: Dictionary) -> Array:
	var opponent_player: int = GameState.get_opponent(owner_player)
	match target:
		"self":
			return [source_card]
		"attacker":
			var att: Variant = ctx.get("attacker", null)
			if att != null:
				return [att as GameState.CardInstance]
			return []
		"defender":
			var def_card: Variant = ctx.get("defender", null)
			if def_card != null:
				return [def_card as GameState.CardInstance]
			return []
		"owner_all":
			return _get_all_cards(owner_player)
		"opponent_all":
			return _get_all_cards(opponent_player)
		"owner_random":
			var all := _get_all_cards(owner_player)
			if all.is_empty():
				return []
			return [all[randi() % all.size()]]
		"opponent_random":
			var all := _get_all_cards(opponent_player)
			if all.is_empty():
				return []
			return [all[randi() % all.size()]]
		_:
			return [source_card]

func _get_all_cards(player: int) -> Array:
	var result: Array = []
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.grids[player][r][c]
			if card.card_type != "dead_end":
				result.append(card)
	return result

func _resolve_player(target: String, owner_player: int) -> int:
	match target:
		"owner":
			return owner_player
		"opponent":
			return GameState.get_opponent(owner_player)
		"player_0":
			return 0
		"player_1":
			return 1
		_:
			return owner_player

# ─────────────────────────────────────────────────────────────
# Deactivation tick
# ─────────────────────────────────────────────────────────────

func _drain_turn_end_deactivations(player: int) -> void:
	for p: int in [0, 1]:
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.grids[p][r][c]
				var to_remove: Array = []
				for rule: CardRule in card.active_rules:
					if _should_deactivate_on_turn_end(rule, p, player):
						to_remove.append(rule)
				for rule: CardRule in to_remove:
					card.active_rules.erase(rule)

func _should_deactivate_on_turn_end(rule: CardRule, owner_player: int, ending_player: int) -> bool:
	match rule.deactivation:
		CardRule.DeactivationType.TURN_END_OWNER:
			return owner_player == ending_player
		CardRule.DeactivationType.TURN_END_OPPONENT:
			return owner_player != ending_player
		CardRule.DeactivationType.TURN_END_OWNER_NTH:
			if owner_player != ending_player:
				return false
			var n: int = rule.deactivation_params.get("n", 1)
			return GameState.turn_number >= n
		CardRule.DeactivationType.TURN_END_OPPONENT_NTH:
			if owner_player == ending_player:
				return false
			var n: int = rule.deactivation_params.get("n", 1)
			return GameState.turn_number >= n
	return false
