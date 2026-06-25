class_name BattleLogFormat
## Compact unit/union labels for battle logs — effective stats, buffs, debuffs, flags, and status.


static func is_unit(card: GameState.CardInstance) -> bool:
	return card != null and card.card_type == "character" and not card.card_name.is_empty()


static func format_card(card: GameState.CardInstance, fallback_name: String = "") -> String:
	if is_unit(card):
		return format_unit(card)
	if card != null and card.card_type == "trap" and not card.card_name.is_empty():
		var trap_cost: String = _character_cost_part(card.crystal_cost, _database_trap_cost(card.card_name))
		if trap_cost.is_empty():
			return '"%s"' % card.card_name
		return '"%s" {%s}' % [card.card_name, trap_cost]
	if card != null and not card.card_name.is_empty():
		return '"%s"' % card.card_name
	if not fallback_name.is_empty():
		return '"%s"' % fallback_name
	return "?"


static func format_unit_at(player: int, row: int, col: int, fallback_name: String = "") -> String:
	return format_card(GameState.get_card(player, row, col), fallback_name)


## Human-readable status lines for the full-card detail overlay (right-side art labels).
static func format_overlay_status_lines(
		card: GameState.CardInstance,
		owner_player: int = -1,
		grid_pos: Vector2i = Vector2i(-1, -1)
) -> PackedStringArray:
	if card == null or card.was_destroyed:
		return PackedStringArray()

	var lines: PackedStringArray = PackedStringArray()

	if not card.face_up:
		lines.append("Face Down")

	if card.card_type == "character" and card.attacked_this_turn \
			and not is_decoy_puppet_blocked(card, owner_player) \
			and not is_echo_barrier_blocked(card, owner_player):
		lines.append("Waiting")

	if is_decoy_puppet_blocked(card, owner_player):
		lines.append("Decoy Puppet (cannot attack)")

	if is_echo_barrier_blocked(card, owner_player):
		lines.append("Echo Barrier (cannot attack)")

	if is_cannot_attack_locked(card):
		lines.append(format_cannot_attack_lock_overlay_line(card))

	if card.effect_nullified_until >= GameState.turn_number:
		lines.append("Effect Nullified (until turn %d)" % card.effect_nullified_until)

	if owner_player >= 0 and GameState.berserk_active[owner_player] == card:
		lines.append("Berserk Active")

	if grid_pos != Vector2i(-1, -1) and grid_pos in GameState.locked_attack_positions:
		lines.append("Cannot Be Attacked This Turn")

	for flag: String in _flag_parts(card):
		if flag in _ONCE_CONSUMPTION_FLAGS:
			continue
		lines.append(_overlay_flag_label(flag))

	_append_overlay_once_used_lines(lines, card)
	_append_overlay_buff_lines(lines, card)
	_append_overlay_debuff_lines(lines, card)

	if card.force_shielded:
		lines.append("Shielded")
	if card.halved:
		lines.append("Stats Halved")
	if card.atk_def_swapped:
		lines.append("ATK/DEF Swapped")
	if card.is_revived:
		if _is_resurrection_revive(card):
			lines.append("Revived via Resurrection")
			lines.append("ATK = 0, DEF = 0")
			lines.append("No ability")
		else:
			lines.append("Revived")
	if card.mutagen_attacked:
		lines.append("Mutagen Attack Used")
	if card.bonus_attack_pending:
		lines.append("Bonus Attack Ready")
	if card.has_pending_multi_attack_non_char():
		var chain_limit: int = card.get_multi_attack_non_char_chain_limit()
		lines.append("Multi-Attack (%d/%d)" % [card.multi_attack_count, chain_limit])
	elif card.multi_attack_count > 0:
		lines.append("Multi-Attack (%d used)" % card.multi_attack_count)

	return lines


static func is_decoy_puppet_blocked(card: GameState.CardInstance, owner_player: int) -> bool:
	if card == null or card.card_type != "character" or card.was_destroyed:
		return false
	if owner_player < 0 or GameState.attack_cost_block_player != owner_player:
		return false
	if GameState.attack_cost_block_max < 0:
		return false
	return card.crystal_cost <= GameState.attack_cost_block_max


static func is_echo_barrier_blocked(card: GameState.CardInstance, owner_player: int) -> bool:
	if card == null or card.card_type != "character" or card.was_destroyed:
		return false
	if owner_player < 0:
		return false
	return GameState.echo_barrier_player == owner_player


static func is_cannot_attack_locked(card: GameState.CardInstance) -> bool:
	if card == null or card.card_type != "character" or card.was_destroyed:
		return false
	return card.cannot_attack_until >= GameState.turn_number


static func format_cannot_attack_lock_overlay_line(card: GameState.CardInstance) -> String:
	return "Cannot attack until turn %d ends" % card.cannot_attack_until


static func should_show_wait_icon(card: GameState.CardInstance, owner_player: int) -> bool:
	if card == null or card.card_type != "character" or card.was_destroyed:
		return false
	if card.attacked_this_turn:
		return true
	if is_decoy_puppet_blocked(card, owner_player):
		return true
	if is_echo_barrier_blocked(card, owner_player):
		return true
	if is_cannot_attack_locked(card):
		return true
	return false


## Turn-based attack locks stay visible across turns; same-turn waits only on the owner's turn.
static func should_show_wait_icon_on_board(
		card: GameState.CardInstance,
		owner_player: int,
		is_owners_turn: bool
) -> bool:
	if not should_show_wait_icon(card, owner_player):
		return false
	if is_cannot_attack_locked(card):
		return true
	return is_owners_turn


static func format_unit(card: GameState.CardInstance) -> String:
	if not is_unit(card):
		return format_card(card)

	var kind: String = "Union" if card.is_union else ("Token" if card.is_token else "Unit")
	var parts: PackedStringArray = PackedStringArray()
	parts.append("%s ATK%d DEF%d" % [kind, card.get_effective_atk(), card.get_effective_def()])

	var cost_label: String = _cost_part(card)
	if not cost_label.is_empty():
		parts.append(cost_label)

	var affinity_label: String = _affinity_part(card)
	if not affinity_label.is_empty():
		parts.append(affinity_label)

	if card.current_atk != card.base_atk or card.current_atk != card.get_effective_atk() \
			or card.current_def != card.base_def:
		parts.append("base %d/%d" % [card.current_atk, card.current_def])

	var buffs: PackedStringArray = _nonzero_buff_parts(card)
	if not buffs.is_empty():
		parts.append("buff " + ", ".join(buffs))

	if card.atk_debuff > 0:
		parts.append("debuff -ATK%d" % card.atk_debuff)

	var flags: PackedStringArray = _flag_parts(card)
	if not flags.is_empty():
		parts.append("flags:" + ",".join(flags))

	var status: PackedStringArray = _status_parts(card)
	if not status.is_empty():
		parts.append(",".join(status))

	return '"%s" {%s}' % [card.card_name, " | ".join(parts)]


static func attack_side_label(result: BattleResolver.BattleResult, is_attacker: bool) -> String:
	if is_attacker:
		if not result.attacker_log_label.is_empty():
			return result.attacker_log_label
		if result.attacker_name.is_empty():
			return "(self-destroyed)" if result.attacker_destroyed else "?"
		return '"%s"' % result.attacker_name

	if not result.defender_log_label.is_empty():
		return result.defender_log_label
	if result.defender_name.is_empty():
		return "(destroyed)" if result.defender_destroyed else "?"
	return '"%s"' % result.defender_name


static func format_attack_resolution_line(
		atk_player: int,
		attacker_pos: Vector2i,
		def_player: int,
		target_pos: Vector2i,
		result: BattleResolver.BattleResult,
		dice: int
) -> String:
	var a_name: String = attack_side_label(result, true)
	var d_name: String = attack_side_label(result, false)
	if result.special_trigger == "trap_effect":
		return "Attack P%d(%d,%d)%s → P%d(%d,%d)%s  Dice=%d  → Unit vs Trap" % [
			atk_player, attacker_pos.x, attacker_pos.y, a_name,
			def_player, target_pos.x, target_pos.y, d_name, dice]
	if result.special_trigger == "trap_nullified":
		return "Attack P%d(%d,%d)%s → P%d(%d,%d)%s  Dice=%d  → Unit vs Trap (nullified)" % [
			atk_player, attacker_pos.x, attacker_pos.y, a_name,
			def_player, target_pos.x, target_pos.y, d_name, dice]
	if result.defender_name.is_empty() and not result.defender_destroyed:
		return "Attack P%d(%d,%d)%s → P%d(%d,%d)(empty)  Dice=%d  → DEAD_END" % [
			atk_player, attacker_pos.x, attacker_pos.y, a_name,
			def_player, target_pos.x, target_pos.y, dice]
	var outcome: String = "WIN" if result.defender_destroyed and not result.attacker_destroyed \
		else "LOSE" if result.attacker_destroyed and not result.defender_destroyed else "TIE"
	return "Attack P%d(%d,%d)%s → P%d(%d,%d)%s  Dice=%d  ATK=%d vs DEF=%d  → %s" % [
		atk_player, attacker_pos.x, attacker_pos.y, a_name,
		def_player, target_pos.x, target_pos.y, d_name,
		dice, result.attacker_atk_used, result.defender_def_used, outcome]


static func format_attack_anim_line(
		atk_player: int,
		attacker_pos: Vector2i,
		def_player: int,
		target_pos: Vector2i,
		result: BattleResolver.BattleResult
) -> String:
	if result.special_trigger == "trap_nullified":
		return "Anim: 3D  (attacker survives)"
	if result.special_trigger == "trap_effect":
		var trap: Variant = result.special_params.get("trap_data", null)
		if trap is TrapData:
			var td: TrapData = trap as TrapData
			if td.effect_type in [
				TrapData.TrapEffectType.DESTROY_ATTACKER,
				TrapData.TrapEffectType.DESTROY_ATTACKER_CHOICE_DESTROY,
				TrapData.TrapEffectType.DESTROY_ATTACKER_DEFENDER_PAYS,
			]:
				return "Anim: 3E  △ P%d(%d,%d)" % [atk_player, attacker_pos.x, attacker_pos.y]
		return "Anim: 3D  (attacker survives)"
	if result.defender_name.is_empty() and not result.defender_destroyed:
		return "Anim: 3F  (blank slot)"
	if result.attacker_destroyed and result.defender_destroyed:
		return "Anim: 3C  △ P%d(%d,%d) + △ P%d(%d,%d)" % [
			atk_player, attacker_pos.x, attacker_pos.y,
			def_player, target_pos.x, target_pos.y]
	if result.defender_destroyed:
		return "Anim: 3A  △ P%d(%d,%d)" % [def_player, target_pos.x, target_pos.y]
	if result.attacker_destroyed:
		return "Anim: 3B  △ P%d(%d,%d)" % [atk_player, attacker_pos.x, attacker_pos.y]
	return "Anim: exchange  (no destruction)"


const _ONCE_CONSUMPTION_FLAGS: Array[String] = [
	"indestructible_used",
	"copy_stats_used",
	"extra_kill_used",
	"extra_vs_revealed_used",
	"extra_deadend_used",
	"extra_deadend_turn",
	"atk_debuff_used",
	"expose_reveal_used",
	"turn_end_reveal_used",
	"anima_triumph_extra_used",
]


static func _append_overlay_once_used_lines(lines: PackedStringArray, card: GameState.CardInstance) -> void:
	if card.card_type != "character":
		return
	if "indestructible_used" in card.flags:
		_append_unique_overlay_line(lines, _survive_once_used_label(card))
	if card.one_use_atk_boost_used:
		_append_unique_overlay_line(lines, _once_atk_consumed_label(card))
	if card.one_use_def_boost_used:
		_append_unique_overlay_line(lines, _once_def_consumed_label(card))
	if "copy_stats_used" in card.flags:
		_append_unique_overlay_line(lines, "Once Copy Stats Used")
	if "extra_kill_used" in card.flags:
		_append_unique_overlay_line(lines, "Once Extra Attack (Kill) Used")
	if "extra_vs_revealed_used" in card.flags:
		_append_unique_overlay_line(lines, "Once Extra Attack (Revealed) Used")
	if "extra_deadend_used" in card.flags:
		_append_unique_overlay_line(lines, "Once Extra Attack (Dead End) Used")
	if "extra_deadend_turn" in card.flags:
		_append_unique_overlay_line(lines, "Extra Attack (Dead End) Used This Turn")
	if "atk_debuff_used" in card.flags \
			and card.ability_type == CharacterData.AbilityType.SELF_DEBUFF_ON_ATTACK_AND_DEFEND:
		_append_unique_overlay_line(lines, "Once Self ATK Debuff Used")
	if "expose_reveal_used" in card.flags:
		_append_unique_overlay_line(lines, "Once Reveal Foe Used")
	if "turn_end_reveal_used" in card.flags:
		_append_unique_overlay_line(lines, "Once Turn-End Reveal Used")
	if "anima_triumph_extra_used" in card.flags:
		_append_unique_overlay_line(lines, "Once Extra Attack Used")


static func _append_unique_overlay_line(lines: PackedStringArray, text: String) -> void:
	if text.is_empty() or text in lines:
		return
	lines.append(text)


static func _survive_once_used_label(card: GameState.CardInstance) -> String:
	if card.ability_type == CharacterData.AbilityType.ONE_USE_SURVIVE_DESTRUCTION:
		var affinities: Array = card.ability_params.get("destroyer_affinities", [])
		if affinities.is_empty():
			var req_aff: int = int(card.ability_params.get("destroyer_affinity", -1))
			if req_aff >= 0:
				affinities = [req_aff]
		if not affinities.is_empty():
			var names: PackedStringArray = []
			for aff: Variant in affinities:
				if int(aff) >= 0 and int(aff) < CharacterData.Affinity.size():
					names.append(_affinity_name(int(aff)))
			if not names.is_empty():
				return "Once Survive vs %s Used" % " / ".join(names)
		return "Survive Once Used"
	return "Survive Once Used"


static func _once_atk_consumed_label(card: GameState.CardInstance) -> String:
	match card.ability_type:
		CharacterData.AbilityType.ONE_USE_ATK_BOOST:
			return "Once ATK Boost Used"
		CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND:
			return "Once ATK Boost Used"
		CharacterData.AbilityType.ONE_USE_DESTROY_BY_AFFINITY:
			return "Once Destroy Used"
		CharacterData.AbilityType.PERM_ATK_BOOST_ONCE_PER_AFFINITY:
			return "Once ATK Gain Used"
		CharacterData.AbilityType.GAIN_HALF_STATS_ON_SURVIVE:
			return "Once Half Stats Gain Used"
		_:
			return "One-Use ATK Used"


static func _once_def_consumed_label(card: GameState.CardInstance) -> String:
	match card.ability_type:
		CharacterData.AbilityType.ONE_USE_DEF_BOOST:
			return "Once DEF Boost Used"
		CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND:
			return "Once DEF Boost Used"
		CharacterData.AbilityType.ONE_USE_DEFEND_MORPH:
			return "Once Defend Morph Used"
		CharacterData.AbilityType.ONE_USE_PERM_DEBUFF_ATTACKER_ATK:
			return "Once Perm ATK Debuff Used"
		CharacterData.AbilityType.SELF_DEBUFF_ON_ATTACK_AND_DEFEND:
			return "Once Self DEF Debuff Used"
		_:
			return "One-Use DEF Used"


static func _is_resurrection_revive(card: GameState.CardInstance) -> bool:
	if not card.is_revived or card.card_type != "character":
		return false
	return card.ability_type == int(CharacterData.AbilityType.NONE) \
		and card.current_atk == 0 \
		and card.current_def == 0


static func _overlay_flag_label(flag: String) -> String:
	match flag:
		"venom": return "Venom Flag"
		"mutagen": return "Mutagen Flag"
		"berserk": return "Berserk Flag"
		"expose_destroy_pending": return "Expose Destroy Pending"
		"indestructible_used": return "Indestructible Used"
		_: return "%s Flag" % flag.capitalize().replace("_", " ")


static func _append_overlay_buff_lines(lines: PackedStringArray, card: GameState.CardInstance) -> void:
	_append_signed_overlay_line(lines, "ATK", card.perm_atk_bonus, "permanent")
	_append_signed_overlay_line(lines, "DEF", card.perm_def_bonus, "permanent")
	_append_signed_overlay_line(lines, "ATK", card.field_aura_atk_bonus, "aura")
	_append_signed_overlay_line(lines, "DEF", card.field_aura_def_bonus, "aura")
	_append_signed_overlay_line(lines, "ATK", card.temp_atk_bonus, "temp")
	_append_signed_overlay_line(lines, "DEF", card.temp_def_bonus, "temp")
	_append_signed_overlay_line(lines, "DEF", card.carry_def_bonus, "carry")
	_append_signed_overlay_line(lines, "DEF", card.trap_carry_def_bonus, "trap carry")


static func _append_overlay_debuff_lines(lines: PackedStringArray, card: GameState.CardInstance) -> void:
	if card.atk_debuff > 0:
		lines.append("ATK Debuff -%d" % card.atk_debuff)
	if card.carry_atk_debuff > 0:
		lines.append("ATK Debuff -%d (carry)" % card.carry_atk_debuff)


static func _append_signed_overlay_line(
		lines: PackedStringArray,
		stat: String,
		value: int,
		kind: String
) -> void:
	if value == 0:
		return
	var sign: String = "+" if value > 0 else "-"
	lines.append("%s %s%d (%s)" % [stat, sign, abs(value), kind])


static func _nonzero_buff_parts(card: GameState.CardInstance) -> PackedStringArray:
	var parts: PackedStringArray = PackedStringArray()
	_append_signed_stat(parts, "permATK", card.perm_atk_bonus)
	_append_signed_stat(parts, "permDEF", card.perm_def_bonus)
	_append_signed_stat(parts, "auraATK", card.field_aura_atk_bonus)
	_append_signed_stat(parts, "auraDEF", card.field_aura_def_bonus)
	_append_signed_stat(parts, "tempATK", card.temp_atk_bonus)
	_append_signed_stat(parts, "tempDEF", card.temp_def_bonus)
	_append_signed_stat(parts, "carryDEF", card.carry_def_bonus)
	return parts


static func _append_signed_stat(parts: PackedStringArray, label: String, value: int) -> void:
	if value == 0:
		return
	var sign: String = "+" if value > 0 else "-"
	parts.append("%s%s%d" % [sign, label, abs(value)])


static func _flag_parts(card: GameState.CardInstance) -> PackedStringArray:
	var flags: PackedStringArray = PackedStringArray()
	for flag: String in card.flags:
		if not flag.is_empty() and flag not in flags:
			flags.append(flag)
	if card.has_mutagen_flag and "mutagen" not in flags:
		flags.append("mutagen")
	return flags


static func _status_parts(card: GameState.CardInstance) -> PackedStringArray:
	var parts: PackedStringArray = PackedStringArray()
	if not card.face_up:
		parts.append("face-down")
	if card.force_shielded:
		parts.append("shield")
	if card.halved:
		parts.append("halved")
	if card.one_use_atk_boost_used:
		parts.append("1xATK-used")
	if card.one_use_def_boost_used:
		parts.append("1xDEF-used")
	if card.mutagen_attacked:
		parts.append("mutagen-attack-used")
	if card.attacked_this_turn:
		parts.append("attacked")
	if card.multi_attack_count > 0:
		parts.append("multi-atk:%d" % card.multi_attack_count)
	if card.cannot_attack_until >= 0:
		parts.append("cannot-atk≤T%d" % card.cannot_attack_until)
	if card.effect_nullified_until >= 0:
		parts.append("nullified≤T%d" % card.effect_nullified_until)
	return parts


static func _cost_part(card: GameState.CardInstance) -> String:
	if card.is_union:
		var union_data: UnionData = UnionDatabase.get_union(card.card_name)
		var base_summon: int = union_data.summon_cost if union_data != null else 0
		var eff_summon: int = _effective_union_summon_cost(base_summon)
		var destroy_cost: String = _character_cost_part(card.crystal_cost, 0)
		var summon_cost: String = _character_cost_part(eff_summon, base_summon)
		if destroy_cost.is_empty() and summon_cost.is_empty():
			return ""
		if destroy_cost.is_empty():
			return summon_cost.replace("cost ", "summon-cost ")
		if summon_cost.is_empty():
			return destroy_cost.replace("cost ", "destroy-cost ")
		return "%s | %s" % [
			destroy_cost.replace("cost ", "destroy-cost "),
			summon_cost.replace("cost ", "summon-cost "),
		]

	var base_cost: int = _database_character_cost(card.card_name)
	return _character_cost_part(card.crystal_cost, base_cost)


static func _affinity_part(card: GameState.CardInstance) -> String:
	if card.affinity < 0:
		return ""
	var current_name: String = _affinity_name(card.affinity)
	var base_affinity: int = _database_affinity(card)
	if base_affinity >= 0 and base_affinity != card.affinity:
		return "affinity %s (base %s)" % [current_name, _affinity_name(base_affinity)]
	return "affinity %s" % current_name


static func _affinity_name(affinity: int) -> String:
	if affinity < 0 or affinity >= CharacterData.Affinity.size():
		return "?"
	return CharacterData.Affinity.keys()[affinity].capitalize()


static func _database_affinity(card: GameState.CardInstance) -> int:
	if card.is_union:
		var union_data: UnionData = UnionDatabase.get_union(card.card_name)
		return int(union_data.affinity) if union_data != null else -1
	var data: CharacterData = CardDatabase.get_character(card.card_name)
	return int(data.affinity) if data != null else -1


static func _character_cost_part(current_cost: int, base_cost: int) -> String:
	if base_cost >= 0 and base_cost != current_cost:
		return "cost %d (base %d)" % [current_cost, base_cost]
	return "cost %d" % current_cost


static func _database_character_cost(card_name: String) -> int:
	var data: CharacterData = CardDatabase.get_character(card_name)
	return data.crystal_cost if data != null else -1


static func _database_trap_cost(trap_name: String) -> int:
	var data: TrapData = CardDatabase.get_trap(trap_name)
	return data.crystal_cost if data != null else -1


static func _effective_union_summon_cost(base_cost: int) -> int:
	if GameState.game_mode != GameState.GameMode.DAILY_DUNGEON:
		return base_cost
	var mods: Array = GameState.active_dungeon_modifiers
	if "dimensional_fissure" in mods:
		return int(base_cost * 0.2)
	if "dimensional_gate" in mods:
		return int(base_cost * 0.5)
	if "dimensional_slippage" in mods:
		return int(base_cost * 0.8)
	if "sealing_talisman" in mods:
		return int(base_cost * 1.2)
	if "sealing_ceremony" in mods:
		return int(base_cost * 1.5)
	return base_cost
