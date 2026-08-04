class_name OmenBattleApplier
extends RefCounted
## Applies exploration Omen effects during battle setup and runtime.

const SETUP_VISIBLE_RUNES: Array[String] = ["berkano", "laguz"]
const BEGIN_GAME_RUNES: Array[String] = ["uruz", "nauthiz", "isa", "mannaz"]

## Elder Futhark glyphs shown in cell corners.
const RUNE_GLYPHS: Dictionary = {
	"fehu": "ᚠ",
	"uruz": "ᚢ",
	"thurisaz": "ᚦ",
	"hagalaz": "ᚺ",
	"nauthiz": "ᚾ",
	"isa": "ᛁ",
	"jera": "ᛃ",
	"berkano": "ᛒ",
	"laguz": "ᛚ",
	"mannaz": "ᛗ",
	"algiz": "ᛉ",
}


static func rune_glyph(rune_id: String) -> String:
	return str(RUNE_GLYPHS.get(rune_id.strip_edges().to_lower(), ""))


static func prepare_from_exploration() -> void:
	reset_runtime_fields()
	GameState.active_omens = ExplorationManager.get_active_omens()
	_build_anoint_effects_map()


static func clear() -> void:
	GameState.active_omens.clear()
	reset_runtime_fields()


static func reset_runtime_fields() -> void:
	GameState.cell_runes.clear()
	GameState.omen_intel_lines.clear()
	GameState.omen_cannot_attack_first_turn = false
	GameState.omen_cannot_union = false
	GameState.omen_cannot_tech = false
	GameState.omen_max_attacks_bonus = 0
	GameState.omen_max_attacks_first_turn_only = 0
	GameState.omen_crystal_loss_pct = 0.0
	GameState.omen_unit_destroy_loss_pct = 0.0
	GameState.omen_crystal_gain_pct = 1.0
	GameState.omen_trap_cost_pct = 0.0
	GameState.omen_tech_cost_pct = 0.0
	GameState.omen_crystal_loss_multiplier = 1.0
	GameState.omen_reckoning_loss_pct = 0.0
	GameState.omen_affinity_destroy_loss.clear()
	GameState.omen_anoint_effects.clear()
	GameState.omen_union_cost_multiplier = 1.0
	GameState.omen_reward_credit_pct = 0.0
	GameState.omen_block_p0_first_turn_attacks = false
	GameState.omen_attack_crystal_cost = 0
	GameState.omen_max_tech_per_turn = 1
	GameState.omen_destruction_source = ""
	GameState.omen_stat_source_card = ""
	GameState.omen_escalating_toll_stacks = 0
	GameState.omen_force_heads_flips = 0


static func apply_pre_battle_crystal_and_flags() -> void:
	if GameState.active_omens.is_empty():
		return
	for held: Variant in GameState.active_omens:
		if not held is Dictionary:
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str((held as Dictionary).get("id", "")))
		if omen.is_empty():
			continue
		var anointed: String = str((held as Dictionary).get("anointed_card", "")).strip_edges()
		for effect: Variant in omen.get("effects", []):
			if effect is Dictionary:
				_apply_pre_battle_effect(effect as Dictionary, anointed)


static func apply_setup_runes() -> void:
	if GameState.active_omens.is_empty():
		return
	_ensure_cell_runes_grid()
	for held: Variant in GameState.active_omens:
		if not held is Dictionary:
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str((held as Dictionary).get("id", "")))
		if omen.is_empty():
			continue
		for effect: Variant in omen.get("effects", []):
			if not effect is Dictionary:
				continue
			var eff: Dictionary = effect as Dictionary
			if str(eff.get("type", "")) != "cell_runes":
				continue
			var placement: String = str(eff.get("placement", "")).strip_edges()
			if placement != "setup_visible":
				continue
			_place_cell_runes(eff, false)


static func apply_begin_game(board: Node) -> void:
	if GameState.active_omens.is_empty():
		return
	_ensure_cell_runes_grid()
	for held: Variant in GameState.active_omens:
		if not held is Dictionary:
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str((held as Dictionary).get("id", "")))
		if omen.is_empty():
			continue
		var anointed: String = str((held as Dictionary).get("anointed_card", "")).strip_edges()
		for effect: Variant in omen.get("effects", []):
			if not effect is Dictionary:
				continue
			var eff: Dictionary = effect as Dictionary
			match str(eff.get("type", "")):
				"reveal_cells":
					if str(eff.get("timing", "battle_start")).strip_edges() == "battle_start":
						_apply_reveal_cells(eff)
				"cell_runes":
					var placement: String = str(eff.get("placement", "")).strip_edges()
					if placement != "setup_visible":
						_place_cell_runes(eff, true)
				"unit_stat_flat", "unit_stat_pct":
					_apply_unit_stat_on_grid(eff)
				"affinity_override_all":
					_apply_affinity_override_all(eff)
	_apply_anoint_effects_on_grid()
	_apply_rune_card_effects()
	_apply_anoint_affinity_overrides()
	apply_begin_game_extra(board)
	if board != null and GameState.omen_intel_lines.is_empty():
		var ai: Node = board.get("ai_player") if board.get("ai_player") != null else null
		if ai != null:
			GameState.omen_intel_lines = collect_intel_lines(ai)
	BattleResolver.recalculate_all_field_bonuses()


static func collect_intel_lines(ai_player: Node) -> Array:
	var lines: PackedStringArray = PackedStringArray()
	if ai_player == null or GameState.active_omens.is_empty():
		return lines
	for held: Variant in GameState.active_omens:
		if not held is Dictionary:
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str((held as Dictionary).get("id", "")))
		if omen.is_empty():
			continue
		for effect: Variant in omen.get("effects", []):
			if not effect is Dictionary:
				continue
			var eff: Dictionary = effect as Dictionary
			match str(eff.get("type", "")):
				"reveal_enemy_bluff_preference":
					var pref_kind: String = str(eff.get("value", "interested")).strip_edges().to_lower()
					var pool: Array = []
					if ai_player.has_method("get_bluff_prefer_emojis") \
							and ai_player.has_method("get_bluff_avoid_emojis"):
						pool = ai_player.call("get_bluff_avoid_emojis") if pref_kind == "avoid" \
							else ai_player.call("get_bluff_prefer_emojis")
					if pool.is_empty():
						continue
					var emoji: String = str(pool[randi() % pool.size()])
					var verb: String = "drawn to" if pref_kind == "interested" else "avoids"
					lines.append("%s: foe %s %s" % [str(omen.get("label", omen.get("id", ""))), verb, emoji])
				"reveal_enemy_personality":
					var axis: String = str(eff.get("value", "offensive")).strip_edges().to_lower()
					var pname: String = ""
					if axis == "defensive":
						pname = str(ai_player.get("personality_defensive"))
					else:
						pname = str(ai_player.get("personality_offensive"))
					if pname.is_empty():
						continue
					var axis_label: String = "Defensive" if axis == "defensive" else "Offensive"
					lines.append("%s: foe %s — %s" % [
						str(omen.get("label", omen.get("id", ""))), axis_label, pname])
	return lines


static func get_cell_rune(player: int, row: int, col: int) -> String:
	if player < 0 or player >= GameState.cell_runes.size():
		return ""
	var grid: Variant = GameState.cell_runes[player]
	if not grid is Array or row < 0 or row >= (grid as Array).size():
		return ""
	var row_arr: Variant = (grid as Array)[row]
	if not row_arr is Array or col < 0 or col >= (row_arr as Array).size():
		return ""
	return str((row_arr as Array)[col])


static func apply_reward_credit_bonus(base_amount: int) -> int:
	if base_amount <= 0 or GameState.omen_reward_credit_pct == 0.0:
		return base_amount
	return int(round(float(base_amount) * (1.0 + GameState.omen_reward_credit_pct / 100.0)))


static func get_anoint_lines_for_card(card_name: String) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if card_name.is_empty():
		return lines
	var effects: Variant = GameState.omen_anoint_effects.get(card_name, [])
	if effects is Array:
		for eff: Variant in effects as Array:
			if eff is Dictionary:
				var line: String = _format_anoint_effect_line(eff as Dictionary)
				if not line.is_empty():
					lines.append(line)
	if lines.is_empty() and ExplorationManager.is_session_active:
		for held: Variant in ExplorationManager.get_active_omens():
			if not held is Dictionary:
				continue
			var anointed: String = str((held as Dictionary).get("anointed_card", "")).strip_edges()
			if anointed != card_name:
				continue
			var omen: Dictionary = OmenDatabase.get_omen(str((held as Dictionary).get("id", "")))
			if omen.is_empty():
				continue
			lines.append(str(omen.get("label", omen.get("id", ""))))
	return lines


static func rune_biases_bluff_reaction(player: int, row: int, col: int) -> int:
	var rune: String = get_cell_rune(player, row, col)
	if rune == "berkano":
		return 1
	if rune == "laguz":
		return -1
	return 0


static func _build_anoint_effects_map() -> void:
	GameState.omen_anoint_effects.clear()
	for held: Variant in GameState.active_omens:
		if not held is Dictionary:
			continue
		var held_d: Dictionary = held as Dictionary
		var anointed: String = str(held_d.get("anointed_card", "")).strip_edges()
		if anointed.is_empty():
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str(held_d.get("id", "")))
		if omen.is_empty():
			continue
		var bucket: Array = GameState.omen_anoint_effects.get(anointed, [])
		if not bucket is Array:
			bucket = []
		for effect: Variant in omen.get("effects", []):
			if effect is Dictionary:
				var eff: Dictionary = (effect as Dictionary).duplicate(true)
				var etype: String = str(eff.get("type", ""))
				if etype.begins_with("anoint_") or etype in _ANPOINT_RUNTIME_TYPES:
					bucket.append(eff)
		if not bucket.is_empty():
			GameState.omen_anoint_effects[anointed] = bucket


static func _apply_pre_battle_effect(effect: Dictionary, _anointed: String) -> void:
	match str(effect.get("type", "")):
		"crystal_bonus":
			var target: int = _target_player_index(str(effect.get("target", "player")))
			if target >= 0:
				GameState.crystals[target] = maxi(0, GameState.crystals[target] + int(effect.get("value", 0)))
		"cannot_attack_first_turn":
			if bool(effect.get("value", true)):
				GameState.omen_cannot_attack_first_turn = true
				GameState.omen_block_p0_first_turn_attacks = true
		"cannot_union":
			if bool(effect.get("value", true)):
				GameState.omen_cannot_union = true
		"cannot_tech":
			if bool(effect.get("value", true)):
				GameState.omen_cannot_tech = true
		"crystal_loss_multiplier":
			GameState.omen_crystal_loss_multiplier *= float(effect.get("value", 1.0))
		"crystal_loss_pct":
			_accumulate_crystal_loss_pct(effect)
		"crystal_gain_pct":
			var pct: float = float(effect.get("value", 0))
			if pct <= -100.0:
				GameState.omen_crystal_gain_pct = 0.0
			else:
				GameState.omen_crystal_gain_pct *= (1.0 + pct / 100.0)
		"trap_cost_pct":
			GameState.omen_trap_cost_pct += float(effect.get("value", 0))
		"tech_cost_pct":
			GameState.omen_tech_cost_pct += float(effect.get("value", 0))
		"union_cost_multiplier":
			GameState.omen_union_cost_multiplier *= float(effect.get("value", 1.0))
		"max_attacks_bonus":
			var bonus: int = int(effect.get("value", 0))
			if bool(effect.get("first_turn_only", false)):
				GameState.omen_max_attacks_first_turn_only += bonus
			else:
				GameState.omen_max_attacks_bonus += bonus
		"reward_credit_pct":
			GameState.omen_reward_credit_pct += float(effect.get("value", 0))
		"attack_crystal_cost":
			GameState.omen_attack_crystal_cost += int(effect.get("value", 0))
		"extra_tech_per_turn":
			GameState.omen_max_tech_per_turn = maxi(
				GameState.omen_max_tech_per_turn, int(effect.get("value", 2)))


static func _accumulate_crystal_loss_pct(effect: Dictionary) -> void:
	var pct: float = float(effect.get("value", 0))
	var scope: String = str(effect.get("scope", "all")).strip_edges().to_lower()
	match scope:
		"unit_destroy":
			GameState.omen_unit_destroy_loss_pct += pct
		"affinity":
			var aff: String = str(effect.get("affinity", "")).strip_edges().to_upper()
			if aff.is_empty():
				return
			GameState.omen_affinity_destroy_loss[aff] = float(
				GameState.omen_affinity_destroy_loss.get(aff, 0.0)) + pct
		"reckoning":
			GameState.omen_reckoning_loss_pct += pct
		_:
			GameState.omen_crystal_loss_pct += pct


static func _apply_reveal_cells(effect: Dictionary) -> void:
	var target: int = _target_player_index(str(effect.get("target", "enemy")))
	if target < 0:
		return
	var count: int = maxi(0, int(effect.get("value", 0)))
	if count <= 0:
		return
	var hidden: Array = []
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(target, r, c)
			if card.card_type != "dead_end" and not card.face_up:
				hidden.append(Vector2i(r, c))
	hidden.shuffle()
	for i: int in range(mini(count, hidden.size())):
		var pos: Vector2i = hidden[i]
		GameState.reveal_card_by_ability(target, pos.x, pos.y)


static func _place_cell_runes(effect: Dictionary, occupied_only: bool) -> void:
	var target: int = _target_player_index(str(effect.get("target", "player")))
	if target < 0:
		return
	var rune: String = str(effect.get("rune", "")).strip_edges().to_lower()
	if rune.is_empty():
		return
	var count: int = maxi(0, int(effect.get("count", 1)))
	var candidates: Array = []
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			if not get_cell_rune(target, r, c).is_empty():
				continue
			var card: GameState.CardInstance = GameState.get_card(target, r, c)
			var has_card: bool = card.card_type != "dead_end"
			if occupied_only and not has_card:
				continue
			candidates.append(Vector2i(r, c))
	candidates.shuffle()
	for i: int in range(mini(count, candidates.size())):
		var pos: Vector2i = candidates[i]
		GameState.cell_runes[target][pos.x][pos.y] = rune


static func _apply_unit_stat_on_grid(effect: Dictionary) -> void:
	var target: int = _target_player_index(str(effect.get("target", "player")))
	if target < 0:
		return
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(target, r, c)
			if not _card_matches_unit_filter(card, effect.get("filter", {}), r, c):
				continue
			_apply_unit_stat_to_card(card, effect)


static func _apply_anoint_effects_on_grid() -> void:
	for card_name: Variant in GameState.omen_anoint_effects.keys():
		var effects: Variant = GameState.omen_anoint_effects[card_name]
		if not effects is Array:
			continue
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				for p: int in range(2):
					var card: GameState.CardInstance = GameState.get_card(p, r, c)
					if card.card_name != str(card_name):
						continue
					for eff_v: Variant in effects as Array:
						if eff_v is Dictionary:
							_apply_anoint_stat_to_card(card, eff_v as Dictionary)


static func _apply_rune_card_effects() -> void:
	for p: int in range(2):
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var rune: String = get_cell_rune(p, r, c)
				if rune.is_empty():
					continue
				var card: GameState.CardInstance = GameState.get_card(p, r, c)
				if card.card_type != "character":
					continue
				match rune:
					"uruz":
						card.perm_atk_bonus += 20
					"nauthiz":
						var cut: int = int(round(float(card.base_def) * 0.5))
						card.perm_def_bonus -= cut
					"isa":
						card.effect_nullified_until = 999999


static func _apply_unit_stat_to_card(card: GameState.CardInstance, effect: Dictionary) -> void:
	if str(effect.get("type", "")) == "unit_stat_flat":
		card.perm_atk_bonus += int(effect.get("atk", 0))
		card.perm_def_bonus += int(effect.get("def", 0))
	else:
		if effect.has("atk_pct"):
			var pct: float = float(effect.get("atk_pct", 0))
			card.perm_atk_bonus += int(round(float(card.base_atk) * pct / 100.0))
		if effect.has("def_pct"):
			var def_pct: float = float(effect.get("def_pct", 0))
			card.perm_def_bonus += int(round(float(card.base_def) * def_pct / 100.0))


static func _apply_anoint_stat_to_card(card: GameState.CardInstance, effect: Dictionary) -> void:
	match str(effect.get("type", "")):
		"anoint_stat_flat":
			card.perm_atk_bonus += int(effect.get("atk", 0))
			card.perm_def_bonus += int(effect.get("def", 0))
		"anoint_stat_pct":
			if effect.has("atk_pct"):
				var pct: float = float(effect.get("atk_pct", 0))
				card.perm_atk_bonus += int(round(float(card.base_atk) * pct / 100.0))
			if effect.has("def_pct"):
				var def_pct: float = float(effect.get("def_pct", 0))
				card.perm_def_bonus += int(round(float(card.base_def) * def_pct / 100.0))
		"anoint_set_def":
			var want: int = int(effect.get("value", card.base_def))
			card.perm_def_bonus += want - card.base_def
		"anoint_cost_multiplier":
			var mult: float = float(effect.get("value", 1.0))
			# 0.0 means free (cost ×0). Keep at least 0.
			card.temp_cost_multiplier = int(round(float(card.temp_cost_multiplier) * mult))
		"anoint_set_ability_none":
			card.ability_type = CharacterData.AbilityType.NONE
			card.ability_params = {}


static func _affinity_from_name(name: String) -> int:
	match name.strip_edges().to_upper():
		"DIVINE": return CharacterData.Affinity.DIVINE
		"CHAOS": return CharacterData.Affinity.CHAOS
		"ARCANE": return CharacterData.Affinity.ARCANE
		"BIO": return CharacterData.Affinity.BIO
		"NATURE": return CharacterData.Affinity.NATURE
		"COSMIC": return CharacterData.Affinity.COSMIC
		"ANIMA": return CharacterData.Affinity.ANIMA
	return -1


static func _apply_affinity_override_all(effect: Dictionary) -> void:
	var aff: int = _affinity_from_name(str(effect.get("affinity", "")))
	if aff < 0:
		return
	var target: int = _target_player_index(str(effect.get("target", "player")))
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(target, r, c)
			if card.card_type == "character":
				card.affinity = aff


static func _apply_anoint_affinity_overrides() -> void:
	for card_name: Variant in GameState.omen_anoint_effects.keys():
		var effects: Variant = GameState.omen_anoint_effects[card_name]
		if not effects is Array:
			continue
		for eff_v: Variant in effects as Array:
			if not eff_v is Dictionary:
				continue
			var eff: Dictionary = eff_v as Dictionary
			if str(eff.get("type", "")) != "affinity_override":
				continue
			var aff: int = _affinity_from_name(str(eff.get("affinity", "")))
			if aff < 0:
				continue
			for p: int in range(2):
				for r: int in range(GameState.GRID_SIZE):
					for c: int in range(GameState.GRID_SIZE):
						var card: GameState.CardInstance = GameState.get_card(p, r, c)
						if card.card_name == str(card_name) and card.card_type == "character":
							card.affinity = aff


static func _card_matches_unit_filter(
		card: GameState.CardInstance,
		filter: Variant,
		row: int,
		col: int) -> bool:
	if card.card_type != "character" or card.is_union:
		return false
	if filter is String:
		var fs: String = str(filter).strip_edges().to_lower()
		if fs == "all":
			return true
		if fs == "border":
			return row == 0 or row == GameState.GRID_SIZE - 1 \
				or col == 0 or col == GameState.GRID_SIZE - 1
		if fs == "center":
			var mid: int = int(GameState.GRID_SIZE / 2)
			return row == mid and col == mid
		return true
	if not filter is Dictionary:
		return true
	var filt: Dictionary = filter as Dictionary
	if filt.has("affinity"):
		var want_name: String = str(filt.get("affinity", "")).strip_edges().to_upper()
		var char_data: CharacterData = CardDatabase.get_character(card.card_name)
		if char_data == null:
			return false
		if char_data.get_affinity_name() != want_name:
			return false
	if filt.has("card_name"):
		if card.card_name != str(filt.get("card_name", "")):
			return false
	if filt.has("name_contains"):
		if not card.card_name.contains(str(filt.get("name_contains", ""))):
			return false
	if filt.has("name_contains_any"):
		var any_list: Variant = filt.get("name_contains_any", [])
		if any_list is Array:
			var matched: bool = false
			for fragment: Variant in any_list as Array:
				if card.card_name.contains(str(fragment)):
					matched = true
					break
			if not matched:
				return false
	if filt.has("cost_max"):
		if card.crystal_cost > int(filt.get("cost_max", 0)):
			return false
	if filt.has("cost_min"):
		if card.crystal_cost < int(filt.get("cost_min", 0)):
			return false
	if filt.has("stat_sum_max"):
		if card.base_atk + card.base_def > int(filt.get("stat_sum_max", 0)):
			return false
	if bool(filt.get("ability_none", false)):
		if card.ability_type != CharacterData.AbilityType.NONE:
			return false
	return true


static func _target_player_index(target: String) -> int:
	match str(target).strip_edges().to_lower():
		"player", "p0", "human":
			return 0
		"enemy", "foe", "p1", "ai":
			return 1
	return 0


static func _ensure_cell_runes_grid() -> void:
	if GameState.cell_runes.size() != 2:
		GameState.cell_runes = [[], []]
	for p: int in range(2):
		if GameState.cell_runes[p].size() != GameState.GRID_SIZE:
			var grid: Array = []
			for _r: int in range(GameState.GRID_SIZE):
				var row: Array = []
				for _c: int in range(GameState.GRID_SIZE):
					row.append("")
				grid.append(row)
			GameState.cell_runes[p] = grid


static func _format_anoint_effect_line(effect: Dictionary) -> String:
	match str(effect.get("type", "")):
		"anoint_stat_flat":
			var parts: PackedStringArray = PackedStringArray()
			if int(effect.get("atk", 0)) != 0:
				parts.append("%+d ATK" % int(effect.get("atk", 0)))
			if int(effect.get("def", 0)) != 0:
				parts.append("%+d DEF" % int(effect.get("def", 0)))
			return ", ".join(parts)
		"anoint_stat_pct":
			var pct_parts: PackedStringArray = PackedStringArray()
			if effect.has("atk_pct"):
				pct_parts.append("%+d%% ATK" % int(effect.get("atk_pct", 0)))
			if effect.has("def_pct"):
				pct_parts.append("%+d%% DEF" % int(effect.get("def_pct", 0)))
			return ", ".join(pct_parts)
		"anoint_cost_multiplier":
			return "Cost ×%.2f" % float(effect.get("value", 1.0))
		"anoint_set_def":
			return "DEF set to %d" % int(effect.get("value", 0))
	return ""


## Mid-battle anoint effect types stored on omen_anoint_effects (beyond anoint_*).
const _ANPOINT_RUNTIME_TYPES: Array[String] = [
	"coin_flip_reckoning_stat",
	"survive_destruction_once",
	"grant_flag_on_reveal",
	"reveal_after_reckoning",
	"reveal_after_trap_or_dead_end",
	"reveal_adjacent_on_attack",
	"extra_attack_on_card",
	"extra_attack_on_kill",
	"lock_target_on_attack",
	"lock_attacker_on_trap",
	"reckoning_survival_vs_non_affinity",
	"destruction_immunity_vs_affinity",
	"destruction_immunity_vs_non_affinity",
	"bane_counter_kill",
	"apply_venom_in_reckoning",
	"apply_venom_pre_reckoning",
	"nullify_foe_ability_in_reckoning",
	"nullify_defender_first_attack",
	"conditional_stat_with_flag",
	"conditional_stat_vs_bluff",
	"conditional_survival",
	"refund_dead_end_attack",
	"zero_crystal_loss_on_destroy",
	"foe_crystal_loss_multiplier_on_kill",
	"crystal_on_kill",
	"negate_zero_cost_traps",
	"trap_immunity_on_bluff_cell",
	"survive_reckoning_vs_bluff_once",
	"taunt",
	"discard_tech_destroy_foe",
	"effect_override",
	"union_material_cost_multiplier",
	"union_material_stat_boost",
	"union_material_crystal_gain",
	"mutagen_immunity",
	"ability_immunity_vs_units",
	"stat_per_void_card",
	"stat_per_field_affinity",
	"revive_once_end_of_turn",
	"anoint_set_ability_none",
	"conditional_revive_omen_or_self",
	"affinity_override",
	"scout_brand",
	"coin_bias",
	"stat_duration",
	"trap_coin_negate",
	"trap_crystal_loss_multiplier",
	"reveal_after_tech",
	"tech_returns_to_hand_once",
	"ignore_trap_affinity",
	"reveal_on_trap_trigger",
	"destroy_reckoning_winner",
	"destroy_at_expose_turn_end",
	"spend_mutagen_revive",
	"survive_reckoning_ties",
	"adjacent_aura",
]


static func effects_of_type(type_name: String) -> Array:
	var out: Array = []
	var want: String = type_name.strip_edges()
	if want.is_empty() or GameState.active_omens.is_empty():
		return out
	for held: Variant in GameState.active_omens:
		if not held is Dictionary:
			continue
		var held_d: Dictionary = held as Dictionary
		var omen: Dictionary = OmenDatabase.get_omen(str(held_d.get("id", "")))
		if omen.is_empty():
			continue
		var anointed: String = str(held_d.get("anointed_card", "")).strip_edges()
		for effect: Variant in omen.get("effects", []):
			if not effect is Dictionary:
				continue
			var eff: Dictionary = effect as Dictionary
			if str(eff.get("type", "")) != want:
				continue
			out.append({
				"omen_id": str(omen.get("id", "")),
				"anointed": anointed,
				"effect": eff,
			})
	return out


static func name_matches_filter(card_name: String, filter: Variant) -> bool:
	if filter == null:
		return true
	if filter is String:
		var fs: String = str(filter).strip_edges().to_lower()
		return fs.is_empty() or fs == "all" or card_name.contains(str(filter))
	if not filter is Dictionary:
		return true
	var filt: Dictionary = filter as Dictionary
	if filt.is_empty():
		return true
	if filt.has("card_name"):
		if card_name != str(filt.get("card_name", "")):
			return false
	if filt.has("name_contains"):
		if not card_name.contains(str(filt.get("name_contains", ""))):
			return false
	if filt.has("name_contains_any"):
		var any_list: Variant = filt.get("name_contains_any", [])
		if any_list is Array:
			var matched: bool = false
			for fragment: Variant in any_list as Array:
				if card_name.contains(str(fragment)):
					matched = true
					break
			if not matched:
				return false
	return true


static func _affinity_name(affinity: int) -> String:
	match affinity:
		CharacterData.Affinity.DIVINE: return "DIVINE"
		CharacterData.Affinity.CHAOS: return "CHAOS"
		CharacterData.Affinity.ARCANE: return "ARCANE"
		CharacterData.Affinity.BIO: return "BIO"
		CharacterData.Affinity.NATURE: return "NATURE"
		CharacterData.Affinity.COSMIC: return "COSMIC"
		CharacterData.Affinity.ANIMA: return "ANIMA"
	return ""


static func _card_matches_effect_unit(
		card: GameState.CardInstance,
		entry: Dictionary,
		owner_player: int) -> bool:
	if card == null or card.card_type != "character":
		return false
	var anointed: String = str(entry.get("anointed", "")).strip_edges()
	if not anointed.is_empty():
		return card.card_name == anointed
	var eff: Dictionary = entry.get("effect", {}) as Dictionary
	# Field-wide filters: owner must be the omen holder (player 0) unless target says otherwise.
	var target: String = str(eff.get("target", "player")).strip_edges().to_lower()
	var want_owner: int = _target_player_index(target if not target.is_empty() else "player")
	if owner_player != want_owner:
		return false
	# Allow unions for name filters (totems normally skip unions via _card_matches_unit_filter).
	var filt: Variant = eff.get("filter", {})
	if card.is_union:
		return name_matches_filter(card.card_name, filt)
	return _card_matches_unit_filter(card, filt, 0, 0)


static func def_bonus_vs_different_affinity(
		defender: GameState.CardInstance,
		attacker: GameState.CardInstance,
		defender_player: int) -> int:
	if defender == null or attacker == null:
		return 0
	if defender.affinity == attacker.affinity:
		return 0
	var bonus: int = 0
	for entry: Variant in effects_of_type("unit_def_vs_different_affinity"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if not _card_matches_effect_unit(defender, e, defender_player):
			continue
		var eff: Dictionary = e.get("effect", {}) as Dictionary
		bonus += int(eff.get("def", 0))
	return bonus


static func blocks_destruction_by_affinity(
		victim: GameState.CardInstance,
		victim_player: int) -> bool:
	if victim == null or victim.card_type != "character":
		return false
	var destroyer: GameState.CardInstance = GameState.attacker_card
	if destroyer == null or destroyer.card_type != "character":
		return false
	var destroyer_aff: String = _affinity_name(destroyer.affinity)
	for entry: Variant in effects_of_type("destruction_immunity_vs_affinity"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if not _card_matches_effect_unit(victim, e, victim_player):
			continue
		var want: String = str((e.get("effect", {}) as Dictionary).get("affinity", "")).to_upper()
		if want != "" and destroyer_aff == want:
			return true
	for entry2: Variant in effects_of_type("destruction_immunity_vs_non_affinity"):
		if not entry2 is Dictionary:
			continue
		var e2: Dictionary = entry2 as Dictionary
		if not _card_matches_effect_unit(victim, e2, victim_player):
			continue
		var keep: String = str((e2.get("effect", {}) as Dictionary).get("affinity", "")).to_upper()
		if keep != "" and destroyer_aff != keep:
			return true
	# Anoint reckoning_survival_vs_non_affinity (e.g. Arcane Absolute)
	for entry3: Variant in effects_of_type("reckoning_survival_vs_non_affinity"):
		if not entry3 is Dictionary:
			continue
		var e3: Dictionary = entry3 as Dictionary
		if not _card_matches_effect_unit(victim, e3, victim_player):
			continue
		var keep3: String = str((e3.get("effect", {}) as Dictionary).get("affinity", "")).to_upper()
		if keep3 != "" and destroyer_aff != keep3:
			return true
	return false


static func try_consume_survive_destruction_once(card: GameState.CardInstance) -> bool:
	if card == null or card.card_type != "character":
		return false
	if "omen_survive_used" in card.flags:
		return false
	# Anoint map
	var anoint_bucket: Variant = GameState.omen_anoint_effects.get(card.card_name, [])
	if anoint_bucket is Array:
		for eff_v: Variant in anoint_bucket as Array:
			if eff_v is Dictionary and str((eff_v as Dictionary).get("type", "")) == "survive_destruction_once":
				card.flags.append("omen_survive_used")
				return true
	# Field-wide omens (owner = player 0)
	for entry: Variant in effects_of_type("survive_destruction_once"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		# Prefer matching against both owners; field filters use target player.
		for owner_guess: int in [0, 1]:
			if _card_matches_effect_unit(card, e, owner_guess):
				card.flags.append("omen_survive_used")
				return true
	return false


static func get_unit_extra_attacks(card: GameState.CardInstance, owner_player: int) -> int:
	if card == null or card.card_type != "character":
		return 0
	var best: int = 0
	for entry: Variant in effects_of_type("unit_extra_attacks"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if not _card_matches_effect_unit(card, e, owner_player):
			continue
		best = maxi(best, int((e.get("effect", {}) as Dictionary).get("value", 0)))
	# Anoint extra_attack_on_card
	for entry2: Variant in effects_of_type("extra_attack_on_card"):
		if not entry2 is Dictionary:
			continue
		var e2: Dictionary = entry2 as Dictionary
		if not _card_matches_effect_unit(card, e2, owner_player):
			continue
		best = maxi(best, int((e2.get("effect", {}) as Dictionary).get("value", 1)))
	return best


static func should_lock_attacker_on_trap(trap_card_name: String, trap_owner: int) -> bool:
	# Omen holder is player 0; trap must be theirs unless anointed trap name matches.
	for entry: Variant in effects_of_type("lock_attacker_on_trap"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		var anointed: String = str(e.get("anointed", "")).strip_edges()
		if not anointed.is_empty():
			if trap_card_name == anointed and trap_owner == 0:
				return true
			continue
		var eff: Dictionary = e.get("effect", {}) as Dictionary
		if trap_owner != _target_player_index(str(eff.get("target", "player"))):
			# Default: omen protects the holder's traps (player).
			if trap_owner != 0:
				continue
		if name_matches_filter(trap_card_name, eff.get("filter", {})):
			return true
	return false


static func cannot_decline_named(card_name: String) -> bool:
	for entry: Variant in effects_of_type("cannot_decline_tech"):
		if not entry is Dictionary:
			continue
		var eff: Dictionary = (entry as Dictionary).get("effect", {}) as Dictionary
		if name_matches_filter(card_name, eff.get("filter", {})):
			return true
	return false


static func post_reckoning_reveal_count(
		attacker: GameState.CardInstance,
		attacker_player: int) -> int:
	var count: int = 0
	for entry: Variant in effects_of_type("reveal_after_reckoning"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if not _card_matches_effect_unit(attacker, e, attacker_player):
			continue
		count = maxi(count, int((e.get("effect", {}) as Dictionary).get("value", 1)))
	return count


static func post_reckoning_destroy_count(
		attacker: GameState.CardInstance,
		attacker_player: int) -> int:
	var count: int = 0
	for entry: Variant in effects_of_type("destroy_after_reckoning"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if not _card_matches_effect_unit(attacker, e, attacker_player):
			continue
		count = maxi(count, int((e.get("effect", {}) as Dictionary).get("value", 1)))
	return count


static func anoint_cost_multiplier_for(card_name: String) -> float:
	var mult: float = 1.0
	var bucket: Variant = GameState.omen_anoint_effects.get(card_name, [])
	if bucket is Array:
		for eff_v: Variant in bucket as Array:
			if not eff_v is Dictionary:
				continue
			var eff: Dictionary = eff_v as Dictionary
			if str(eff.get("type", "")) == "anoint_cost_multiplier":
				mult *= float(eff.get("value", 1.0))
	return mult


static func conditional_atk_bonus(card: GameState.CardInstance, owner_player: int) -> int:
	var bonus: int = 0
	for entry: Variant in effects_of_type("conditional_stat_with_flag"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if not _card_matches_effect_unit(card, e, owner_player):
			continue
		var eff: Dictionary = e.get("effect", {}) as Dictionary
		var flag: String = str(eff.get("flag", ""))
		if flag == "mutagen":
			if not card.has_mutagen_flag and "mutagen" not in card.flags:
				continue
		elif flag != "" and flag not in card.flags:
			continue
		bonus += int(eff.get("atk", 0))
	# coin_flip_reckoning_stat — roll once per call; store on card meta via flags for the turn
	for entry2: Variant in effects_of_type("coin_flip_reckoning_stat"):
		if not entry2 is Dictionary:
			continue
		var e2: Dictionary = entry2 as Dictionary
		if not _card_matches_effect_unit(card, e2, owner_player):
			continue
		var key: String = "omen_coin_bloom_%s_t%d" % [str(e2.get("omen_id", "")), GameState.turn_number]
		if key + "_rolled" not in card.flags:
			card.flags.append(key + "_rolled")
			var heads: bool = randf() < 0.5
			if heads:
				card.flags.append(key + "_heads")
				GameState.post_message("Omen: coin Heads — bloom stats!")
			else:
				GameState.post_message("Omen: coin Tails — no bloom.")
		if key + "_heads" in card.flags:
			bonus += int((e2.get("effect", {}) as Dictionary).get("atk", 0))
	return bonus


static func conditional_def_bonus(card: GameState.CardInstance, owner_player: int) -> int:
	var bonus: int = 0
	for entry: Variant in effects_of_type("conditional_stat_with_flag"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if not _card_matches_effect_unit(card, e, owner_player):
			continue
		var eff: Dictionary = e.get("effect", {}) as Dictionary
		var flag: String = str(eff.get("flag", ""))
		if flag == "mutagen":
			if not card.has_mutagen_flag and "mutagen" not in card.flags:
				continue
		elif flag != "" and flag not in card.flags:
			continue
		bonus += int(eff.get("def", 0))
	for entry2: Variant in effects_of_type("coin_flip_reckoning_stat"):
		if not entry2 is Dictionary:
			continue
		var e2: Dictionary = entry2 as Dictionary
		if not _card_matches_effect_unit(card, e2, owner_player):
			continue
		var key: String = "omen_coin_bloom_%s_t%d" % [str(e2.get("omen_id", "")), GameState.turn_number]
		if key + "_heads" in card.flags:
			bonus += int((e2.get("effect", {}) as Dictionary).get("def", 0))
	return bonus


static func apply_pre_reckoning_effects(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		attacker_player: int,
		defender_player: int) -> void:
	for entry: Variant in effects_of_type("apply_venom_pre_reckoning"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if _card_matches_effect_unit(attacker, e, attacker_player) \
				and defender != null and defender.card_type == "character" \
				and "venom" not in defender.flags:
			defender.flags.append("venom")
			GameState.post_message("Omen: %s is primed with Venom!" % defender.card_name)
	for entry2: Variant in effects_of_type("apply_venom_in_reckoning"):
		if not entry2 is Dictionary:
			continue
		var e2: Dictionary = entry2 as Dictionary
		if _card_matches_effect_unit(attacker, e2, attacker_player) \
				and defender != null and defender.card_type == "character" \
				and "venom" not in defender.flags:
			defender.flags.append("venom")
			GameState.post_message("Omen: %s is laced with Venom!" % defender.card_name)
		if _card_matches_effect_unit(defender, e2, defender_player) \
				and attacker != null and attacker.card_type == "character" \
				and "venom" not in attacker.flags:
			attacker.flags.append("venom")
			GameState.post_message("Omen: %s is laced with Venom!" % attacker.card_name)


static func anoint_has_type(card_name: String, type_name: String) -> bool:
	var bucket: Variant = GameState.omen_anoint_effects.get(card_name, [])
	if bucket is Array:
		for eff_v: Variant in bucket as Array:
			if eff_v is Dictionary and str((eff_v as Dictionary).get("type", "")) == type_name:
				return true
	return false


static func anoint_effect(card_name: String, type_name: String) -> Dictionary:
	var bucket: Variant = GameState.omen_anoint_effects.get(card_name, [])
	if bucket is Array:
		for eff_v: Variant in bucket as Array:
			if eff_v is Dictionary and str((eff_v as Dictionary).get("type", "")) == type_name:
				return eff_v as Dictionary
	return {}


static func coin_bias_for_card(card_name: String) -> String:
	var eff: Dictionary = anoint_effect(card_name, "coin_bias")
	return str(eff.get("value", "")).strip_edges()


static func biased_coin_result(card_name: String) -> int:
	## Returns 1=heads, 0=tails, -1=no bias.
	var bias: String = coin_bias_for_card(card_name)
	if bias == "always_heads":
		return 1
	if bias == "soft_heads":
		return 1 if randf() < 0.75 else 0
	return -1


static func apply_stat_change_from_source(
		target: GameState.CardInstance,
		atk_delta: int,
		def_delta: int,
		source_card_name: String) -> void:
	if target == null:
		return
	var dur: Dictionary = anoint_effect(source_card_name, "stat_duration")
	var mode: String = str(dur.get("mode", "")).strip_edges()
	if mode == "permanent":
		target.perm_atk_bonus += atk_delta
		target.perm_def_bonus += def_delta
		return
	target.temp_atk_bonus += atk_delta
	target.temp_def_bonus += def_delta
	if mode == "extend":
		var turns: int = maxi(1, int(dur.get("turns", 1)))
		target.flags.append("omen_temp_extend_%d" % turns)


static func has_trap_coin_negate(attacker: GameState.CardInstance) -> bool:
	return attacker != null and anoint_has_type(attacker.card_name, "trap_coin_negate")


static func has_negate_zero_cost_traps(attacker: GameState.CardInstance) -> bool:
	return attacker != null and anoint_has_type(attacker.card_name, "negate_zero_cost_traps")


static func has_full_trap_tech_immunity(attacker: GameState.CardInstance) -> bool:
	if attacker == null:
		return false
	if anoint_has_type(attacker.card_name, "mutagen_immunity"):
		if attacker.has_mutagen_flag or "mutagen" in attacker.flags:
			return true
	# null_aegis: extend existing 0-cost trap immunity to all traps/tech
	if not effects_of_type("extend_trap_immunity").is_empty():
		if attacker.ability_type in [
				CharacterData.AbilityType.IMMUNE_ZERO_COST_TRAPS,
				CharacterData.AbilityType.IMMUNE_TO_TECH_DESTRUCTION] \
				or has_negate_zero_cost_traps(attacker):
			return true
	return false


static func has_ability_immunity_vs_units(card: GameState.CardInstance) -> bool:
	return card != null and anoint_has_type(card.card_name, "ability_immunity_vs_units")


static func has_trap_immunity_on_bluff(
		attacker: GameState.CardInstance,
		attacker_player: int,
		attacker_pos: Vector2i) -> bool:
	if attacker == null or not anoint_has_type(attacker.card_name, "trap_immunity_on_bluff_cell"):
		return false
	return not GameState.get_bluff(attacker_player, attacker_pos.x, attacker_pos.y).is_empty()


static func omen_taunt_target(defender_player: int) -> GameState.CardInstance:
	for entry: Variant in effects_of_type("taunt"):
		if not entry is Dictionary:
			continue
		var anointed: String = str((entry as Dictionary).get("anointed", ""))
		if anointed.is_empty():
			continue
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(defender_player, r, c)
				if card.card_name == anointed and card.card_type == "character" and card.face_up:
					return card
	return null


static func should_survive_reckoning_tie(card: GameState.CardInstance, owner_player: int) -> bool:
	if card == null:
		return false
	if anoint_has_type(card.card_name, "survive_reckoning_ties"):
		return true
	for entry: Variant in effects_of_type("survive_reckoning_ties"):
		if entry is Dictionary and _card_matches_effect_unit(card, entry as Dictionary, owner_player):
			return true
	return false


static func conditional_survival_blocks(card: GameState.CardInstance, owner_player: int) -> bool:
	if card == null:
		return false
	for entry: Variant in effects_of_type("conditional_survival"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if not _card_matches_effect_unit(card, e, owner_player):
			continue
		var cond: String = str((e.get("effect", {}) as Dictionary).get("condition", ""))
		if cond == "ally_divine_on_field":
			for r: int in range(GameState.GRID_SIZE):
				for c: int in range(GameState.GRID_SIZE):
					var ally: GameState.CardInstance = GameState.get_card(owner_player, r, c)
					if ally != card and ally.card_type == "character" \
							and ally.affinity == CharacterData.Affinity.DIVINE:
						return true
	return false


static func try_survive_reckoning_vs_bluff(
		card: GameState.CardInstance,
		cell_has_bluff: bool) -> bool:
	if card == null or not cell_has_bluff:
		return false
	if "omen_gambler_used" in card.flags:
		return false
	if anoint_has_type(card.card_name, "survive_reckoning_vs_bluff_once"):
		card.flags.append("omen_gambler_used")
		return true
	return false


static func dynamic_stat_bonuses(card: GameState.CardInstance, owner_player: int) -> Vector2i:
	var atk: int = 0
	var def: int = 0
	for entry: Variant in effects_of_type("stat_per_field_affinity"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if not _card_matches_effect_unit(card, e, owner_player):
			continue
		var eff: Dictionary = e.get("effect", {}) as Dictionary
		var aff: int = _affinity_from_name(str(eff.get("affinity", "")))
		if aff < 0:
			continue
		var count: int = 0
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var ally: GameState.CardInstance = GameState.get_card(owner_player, r, c)
				if ally.card_type == "character" and ally.face_up and ally.affinity == aff:
					count += 1
		atk += int(eff.get("atk", 0)) * count
		def += int(eff.get("def", 0)) * count
	for entry2: Variant in effects_of_type("stat_per_void_card"):
		if not entry2 is Dictionary:
			continue
		var e2: Dictionary = entry2 as Dictionary
		if not _card_matches_effect_unit(card, e2, owner_player):
			continue
		var void_n: int = 0
		if owner_player >= 0 and owner_player < GameState.void_pile_entries.size():
			void_n = (GameState.void_pile_entries[owner_player] as Array).size()
		var eff2: Dictionary = e2.get("effect", {}) as Dictionary
		atk += int(eff2.get("atk", 0)) * void_n
		def += int(eff2.get("def", 0)) * void_n
	return Vector2i(atk, def)


static func bluff_atk_bonus(
		attacker: GameState.CardInstance,
		defender_player: int,
		target_pos: Vector2i) -> int:
	if attacker == null or not anoint_has_type(attacker.card_name, "conditional_stat_vs_bluff"):
		return 0
	if GameState.get_bluff(defender_player, target_pos.x, target_pos.y).is_empty():
		return 0
	var eff: Dictionary = anoint_effect(attacker.card_name, "conditional_stat_vs_bluff")
	return int(eff.get("atk", 0))


static func effect_override_for(card_name: String) -> Dictionary:
	return anoint_effect(card_name, "effect_override")


static func barrel_gospel_active(trap_owner: int) -> bool:
	if trap_owner != 0:
		return false
	return not effects_of_type("trap_effect_override_all").is_empty()


static func max_tech_per_turn() -> int:
	var n: int = 1
	for entry: Variant in effects_of_type("extra_tech_per_turn"):
		if entry is Dictionary:
			n = maxi(n, int((entry as Dictionary).get("effect", {}).get("value", 2)))
	return n


static func rune_crystal_loss_multiplier(player: int, row: int, col: int) -> float:
	var rune: String = get_cell_rune(player, row, col)
	match rune:
		"fehu": return 0.5
		"hagalaz": return 2.0
	return 1.0


static func rune_thurisaz_revive(player: int, row: int, col: int, card: GameState.CardInstance) -> bool:
	if get_cell_rune(player, row, col) != "thurisaz":
		return false
	if card == null or "thurisaz_revive_used" in card.flags:
		return false
	card.flags.append("thurisaz_revive_used")
	return true


static func apply_unit_destroy_cost_multipliers() -> void:
	for entry: Variant in effects_of_type("unit_destroy_cost_multiplier"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		var eff: Dictionary = e.get("effect", {}) as Dictionary
		var mult: float = float(eff.get("value", 1.0))
		var target: int = _target_player_index(str(eff.get("target", "player")))
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(target, r, c)
				if not _card_matches_unit_filter(card, eff.get("filter", {}), r, c):
					continue
				card.crystal_cost = int(round(float(card.crystal_cost) * mult))


static func union_material_bonuses(material_names: Array) -> Dictionary:
	var cost_mult: float = 1.0
	var atk: int = 0
	var defv: int = 0
	var crystals: int = 0
	for name_v: Variant in material_names:
		var name: String = str(name_v)
		var cm: Dictionary = anoint_effect(name, "union_material_cost_multiplier")
		if not cm.is_empty():
			cost_mult *= float(cm.get("value", 1.0))
		var st: Dictionary = anoint_effect(name, "union_material_stat_boost")
		if not st.is_empty():
			atk += int(st.get("atk", 0))
			defv += int(st.get("def", 0))
		var cg: Dictionary = anoint_effect(name, "union_material_crystal_gain")
		if not cg.is_empty():
			crystals += int(cg.get("value", 0))
	return {"cost_mult": cost_mult, "atk": atk, "def": defv, "crystals": crystals}


static func should_refund_dead_end(attacker: GameState.CardInstance) -> bool:
	return attacker != null and anoint_has_type(attacker.card_name, "refund_dead_end_attack")


static func foe_kill_crystal_mult(attacker: GameState.CardInstance) -> float:
	if attacker == null:
		return 1.0
	var eff: Dictionary = anoint_effect(attacker.card_name, "foe_crystal_loss_multiplier_on_kill")
	if eff.is_empty():
		return 1.0
	return float(eff.get("value", 1.0))


static func trap_crystal_loss_mult(trap_name: String) -> float:
	var eff: Dictionary = anoint_effect(trap_name, "trap_crystal_loss_multiplier")
	if eff.is_empty():
		return 1.0
	return float(eff.get("value", 1.0))


static func has_executioners_pact(attacker: GameState.CardInstance) -> bool:
	return attacker != null and anoint_has_type(attacker.card_name, "discard_tech_destroy_foe")


static func has_hex_seal(attacker: GameState.CardInstance) -> bool:
	return attacker != null and anoint_has_type(attacker.card_name, "nullify_defender_first_attack")


static func has_silence_brand(card: GameState.CardInstance) -> bool:
	return card != null and anoint_has_type(card.card_name, "nullify_foe_ability_in_reckoning")


static func queue_divine_return(card: GameState.CardInstance, player: int, row: int, col: int) -> void:
	if card == null or not anoint_has_type(card.card_name, "revive_once_end_of_turn"):
		return
	if "divine_return_used" in card.flags:
		return
	card.flags.append("divine_return_used")
	GameState.turn_start_revives.append({
		"player": player, "row": row, "col": col, "card_name": card.card_name,
		"omen_divine_return": true,
	})


static func should_phoenix_revive(card: GameState.CardInstance, destroy_source: String) -> bool:
	## destroy_source: "own_tech" | "own_ability" | "omen" | "foe" | "other"
	if card == null or not anoint_has_type(card.card_name, "conditional_revive_omen_or_self"):
		return false
	return destroy_source in ["own_tech", "own_ability", "omen"]


static func apply_begin_game_extra(board: Node) -> void:
	apply_unit_destroy_cost_multipliers()
	# Mark destroy_at_expose_turn_end anointed units
	for card_name: Variant in GameState.omen_anoint_effects.keys():
		if anoint_has_type(str(card_name), "destroy_at_expose_turn_end"):
			for p: int in range(2):
				for r: int in range(GameState.GRID_SIZE):
					for c: int in range(GameState.GRID_SIZE):
						var card: GameState.CardInstance = GameState.get_card(p, r, c)
						if card.card_name == str(card_name):
							card.flags.append("omen_burn_on_expose_eot")
	apply_adjacent_auras()
	shuffle_all_units_if_needed()
	if board != null:
		pass


static func apply_grant_flag_on_reveal(
		card: GameState.CardInstance, owner_player: int, _row: int, _col: int) -> void:
	if card == null or card.card_type != "character":
		return
	var flags_to_grant: Array = []
	var bucket: Variant = GameState.omen_anoint_effects.get(card.card_name, [])
	if bucket is Array:
		for oe: Variant in bucket as Array:
			if oe is Dictionary and str((oe as Dictionary).get("type", "")) == "grant_flag_on_reveal":
				flags_to_grant.append(str((oe as Dictionary).get("flag", "")))
	for entry: Variant in effects_of_type("grant_flag_on_reveal"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if not _card_matches_effect_unit(card, e, owner_player):
			continue
		flags_to_grant.append(str((e.get("effect", {}) as Dictionary).get("flag", e.get("flag", ""))))
	for flag_v: Variant in flags_to_grant:
		var flag: String = str(flag_v).strip_edges()
		if flag.is_empty():
			continue
		if flag == "mutagen":
			if not card.has_mutagen_flag:
				GameState.apply_mutagen_flag(card)
				GameState.post_message("Omen: %s receives Mutagen!" % card.card_name)
		elif flag not in card.flags:
			card.flags.append(flag)
			GameState.post_message("Omen: %s receives %s!" % [card.card_name, flag.capitalize()])
			GameState.emit_signal("card_flag_added", owner_player, _row, _col, flag)


static func apply_adjacent_auras() -> void:
	for entry: Variant in effects_of_type("adjacent_aura"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		var anointed: String = str(e.get("anointed", ""))
		if anointed.is_empty():
			continue
		var eff: Dictionary = e.get("effect", {}) as Dictionary
		var want_aff: int = _affinity_from_name(str(eff.get("affinity", "")))
		var atk_pct: float = float(eff.get("atk_pct", 0))
		var def_pct: float = float(eff.get("def_pct", 0))
		for p: int in range(2):
			for r: int in range(GameState.GRID_SIZE):
				for c: int in range(GameState.GRID_SIZE):
					var hub: GameState.CardInstance = GameState.get_card(p, r, c)
					if hub.card_name != anointed or hub.card_type != "character":
						continue
					for adj: Vector2i in GameState.get_adjacent_positions(r, c):
						var ally: GameState.CardInstance = GameState.get_card(p, adj.x, adj.y)
						if ally.card_type != "character":
							continue
						if want_aff >= 0 and ally.affinity != want_aff:
							continue
						ally.perm_atk_bonus += int(round(float(ally.base_atk) * atk_pct / 100.0))
						ally.perm_def_bonus += int(round(float(ally.base_def) * def_pct / 100.0))


static func shuffle_all_units_if_needed() -> void:
	if effects_of_type("shuffle_all_units").is_empty():
		return
	for p: int in range(2):
		var units: Array = []
		var cells: Array = []
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(p, r, c)
				if card.card_type == "character":
					units.append(card)
					cells.append(Vector2i(r, c))
					GameState.place_dead_end(p, r, c)
		cells.shuffle()
		for i: int in range(units.size()):
			var pos: Vector2i = cells[i]
			GameState.grids[p][pos.x][pos.y] = units[i]
			(units[i] as GameState.CardInstance).grid_row = pos.x
			(units[i] as GameState.CardInstance).grid_col = pos.y
	GameState.post_message("Omen Poltergeist: All units shuffled!")


static func ignores_trap_affinity(trap_name: String) -> bool:
	return anoint_has_type(trap_name, "ignore_trap_affinity")


static func should_reveal_on_trap_trigger(trap_name: String) -> bool:
	return anoint_has_type(trap_name, "reveal_on_trap_trigger")


static func attack_lock_defender_turns() -> int:
	var n: int = 0
	for entry: Variant in effects_of_type("attack_lock_defender_turns"):
		if entry is Dictionary:
			n = maxi(n, int((entry as Dictionary).get("effect", {}).get("value", 0)))
	return n


static func has_escalating_toll() -> bool:
	return not effects_of_type("escalating_foe_crystal_loss").is_empty()


static func try_spend_mutagen_revive(card: GameState.CardInstance) -> bool:
	if card == null or not anoint_has_type(card.card_name, "spend_mutagen_revive"):
		return false
	if not card.has_mutagen_flag and "mutagen" not in card.flags:
		return false
	if "omen_mutagen_revive_used" in card.flags:
		return false
	card.flags.append("omen_mutagen_revive_used")
	card.has_mutagen_flag = false
	card.flags.erase("mutagen")
	return true


static func tech_returns_to_hand(tech_name: String) -> bool:
	if not anoint_has_type(tech_name, "tech_returns_to_hand_once"):
		return false
	var key: String = "omen_second_charge_%s" % tech_name
	# Track on GameState via intel lines isn't ideal; use anoint effects map side channel.
	if GameState.omen_anoint_effects.has(key):
		return false
	GameState.omen_anoint_effects[key] = [{"type": "used"}]
	return true


static func double_turn_end_abilities() -> bool:
	return not effects_of_type("double_turn_end_abilities").is_empty()


static func jera_loses_to_divine(
		card: GameState.CardInstance, owner_player: int, foe: GameState.CardInstance) -> bool:
	if card == null or foe == null or foe.affinity != CharacterData.Affinity.DIVINE:
		return false
	var pos: Vector2i = GameState.find_card_position(owner_player, card)
	if pos.x < 0:
		return false
	return get_cell_rune(owner_player, pos.x, pos.y) == "jera"


static func algiz_protects_material(player: int, row: int, col: int) -> bool:
	return get_cell_rune(player, row, col) == "algiz"


static func try_oracle_sacrifice_for_heads(player: int) -> bool:
	## Destroy anointed oracle unit to force upcoming coin flips Heads.
	for entry: Variant in effects_of_type("sacrifice_force_heads"):
		if not entry is Dictionary:
			continue
		var anointed: String = str((entry as Dictionary).get("anointed", ""))
		if anointed.is_empty():
			continue
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(player, r, c)
				if card.card_name != anointed or card.card_type != "character":
					continue
				if "omen_oracle_used" in card.flags:
					continue
				card.flags.append("omen_oracle_used")
				GameState.omen_destruction_source = "omen"
				GameState.destroy_card(player, r, c, true)
				GameState.omen_destruction_source = ""
				GameState.omen_force_heads_flips = 99
				GameState.post_message("Omen Oracle's Sacrifice: coins forced Heads!")
				return true
	return false


static func consume_force_heads() -> bool:
	if GameState.omen_force_heads_flips > 0:
		GameState.omen_force_heads_flips -= 1
		return true
	return false

