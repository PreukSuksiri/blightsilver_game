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


static func _nonzero_buff_parts(card: GameState.CardInstance) -> PackedStringArray:
	var parts: PackedStringArray = PackedStringArray()
	_append_signed_stat(parts, "permATK", card.perm_atk_bonus)
	_append_signed_stat(parts, "permDEF", card.perm_def_bonus)
	_append_signed_stat(parts, "auraATK", card.field_aura_atk_bonus)
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
