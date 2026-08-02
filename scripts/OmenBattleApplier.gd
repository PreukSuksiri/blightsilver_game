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
	_apply_anoint_effects_on_grid()
	_apply_rune_card_effects()
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
				if etype.begins_with("anoint_") or etype in [
					"coin_flip_reckoning_stat", "survive_destruction_once", "grant_flag_on_reveal"]:
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
			card.temp_cost_multiplier = int(round(float(card.temp_cost_multiplier) * mult))


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
