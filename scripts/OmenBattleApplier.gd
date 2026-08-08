class_name OmenBattleApplier
extends RefCounted
## Applies exploration Omen effects during battle setup and runtime.

## Above-cell runes: visible during Setup and always shown on the cell.
## Under-cell runes: hidden until the cell's card is revealed (face_up).
const ABOVE_RUNES: Array[String] = ["berkano", "laguz", "mannaz", "algiz"]
const UNDER_RUNES: Array[String] = [
	"fehu", "uruz", "thurisaz", "hagalaz", "nauthiz", "isa", "jera",
]

## Elder Futhark glyphs shown in cell corners / on revealed cards.
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


static func is_above_rune(rune_id: String) -> bool:
	return rune_id.strip_edges().to_lower() in ABOVE_RUNES


static func is_under_rune(rune_id: String) -> bool:
	var id: String = rune_id.strip_edges().to_lower()
	return not id.is_empty() and id in UNDER_RUNES


## Visible glyph for UI: under-runes only after the cell is face-up.
static func visible_rune_glyph(player: int, row: int, col: int) -> String:
	var rune_id: String = get_cell_rune(player, row, col)
	if rune_id.is_empty():
		return ""
	if is_under_rune(rune_id):
		var card: GameState.CardInstance = GameState.get_card(player, row, col)
		if card == null or not card.face_up:
			return ""
	return rune_glyph(rune_id)


static func prepare_from_exploration() -> void:
	reset_runtime_fields()
	GameState.active_omens = ExplorationManager.get_active_omens()
	# Ensure player entries carry owner: 0 for ownership-aware matchers.
	for i: int in range(GameState.active_omens.size()):
		var held: Variant = GameState.active_omens[i]
		if held is Dictionary and not (held as Dictionary).has("owner"):
			(GameState.active_omens[i] as Dictionary)["owner"] = 0
	_build_anoint_effects_map()


static func clear() -> void:
	GameState.active_omens.clear()
	GameState.enemy_active_omens.clear()
	reset_runtime_fields()


static func reset_runtime_fields() -> void:
	GameState.cell_runes.clear()
	GameState.omen_intel_lines.clear()
	GameState.omen_intel.clear()
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


## Player + enemy held omen entries (each with owner 0|1).
static func all_held_omens() -> Array:
	var out: Array = []
	for held: Variant in GameState.active_omens:
		if not held is Dictionary:
			continue
		var d: Dictionary = (held as Dictionary).duplicate(true)
		if not d.has("owner"):
			d["owner"] = 0
		out.append(d)
	for held2: Variant in GameState.enemy_active_omens:
		if not held2 is Dictionary:
			continue
		var d2: Dictionary = (held2 as Dictionary).duplicate(true)
		d2["owner"] = int(d2.get("owner", 1))
		out.append(d2)
	return out


static func rebuild_anoint_effects_map() -> void:
	_build_anoint_effects_map()


## Append a rolled enemy omen entry and refresh the anoint map.
static func append_enemy_omen(omen_id: String, anointed_card: String = "") -> void:
	var entry: Dictionary = {
		"id": omen_id.strip_edges(),
		"anointed_card": anointed_card.strip_edges(),
		"owner": 1,
	}
	if entry["id"].is_empty():
		return
	GameState.enemy_active_omens.append(entry)
	_build_anoint_effects_map()


## Post-setup board/hand candidates for enemy anoint (P1 grid + tech pool).
static func build_enemy_anoint_candidates() -> Array:
	var candidates: Array = []
	var seen: Dictionary = {}
	# Board units/traps on the enemy grid.
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(1, r, c)
			if card.card_type == "dead_end" or card.card_name.is_empty():
				continue
			var key: String = card.card_name
			if seen.has(key):
				continue
			seen[key] = true
			var entry: Dictionary = OmenDatabase.deck_entry_from_name(card.card_name)
			entry["on_board"] = true
			entry["face_up"] = card.face_up
			candidates.append(entry)
	# Tech: live hand if dealt, otherwise forced / deck pool.
	var tech_names: Array = []
	if not GameState.tech_hands[1].is_empty():
		tech_names = GameState.tech_hands[1].duplicate()
	elif not GameState.battle_ai_forced_tech.is_empty():
		for t: Variant in GameState.battle_ai_forced_tech:
			var ts: String = str(t).strip_edges()
			if not ts.is_empty():
				tech_names.append(ts)
	elif GameState.battle_ai_deck != null:
		for t2: Variant in (GameState.battle_ai_deck as DeckData).techs:
			var ts2: String = str(t2).strip_edges()
			if not ts2.is_empty():
				tech_names.append(ts2)
	else:
		var forced_tech: Variant = GameState.campaign_enemy_config.get("forced_tech", null)
		if forced_tech is Array:
			for t3: Variant in forced_tech as Array:
				var ts3: String = str(t3).strip_edges()
				if not ts3.is_empty():
					tech_names.append(ts3)
	for tn: Variant in tech_names:
		var tname: String = str(tn).strip_edges()
		if tname.is_empty() or seen.has(tname):
			continue
		seen[tname] = true
		var tech_entry: Dictionary = OmenDatabase.deck_entry_from_name(tname)
		tech_entry["on_board"] = false
		candidates.append(tech_entry)
	return candidates


## Deterministic AI anoint pick from post-setup candidates.
static func choose_enemy_anoint_card(omen: Dictionary, candidates: Array) -> String:
	if omen.is_empty() or not OmenDatabase.is_anoint(omen):
		return ""
	var eligible: Array = OmenDatabase.get_eligible_deck_cards(omen, candidates)
	if eligible.is_empty():
		return ""
	var already_anointed: Dictionary = {}
	for held: Variant in all_held_omens():
		if not held is Dictionary:
			continue
		var ac: String = str((held as Dictionary).get("anointed_card", "")).strip_edges()
		if not ac.is_empty():
			already_anointed[ac] = true
	var fresh: Array = []
	var reused: Array = []
	for entry: Variant in eligible:
		if not entry is Dictionary:
			continue
		var name: String = str((entry as Dictionary).get("name", "")).strip_edges()
		if name.is_empty():
			continue
		if already_anointed.has(name):
			reused.append(entry)
		else:
			fresh.append(entry)
	var pool: Array = fresh if not fresh.is_empty() else reused
	if pool.is_empty():
		return ""
	pool.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _enemy_anoint_score(a as Dictionary) > _enemy_anoint_score(b as Dictionary))
	return str((pool[0] as Dictionary).get("name", "")).strip_edges()


static func _enemy_anoint_score(entry: Dictionary) -> int:
	var card_type: String = str(entry.get("type", "")).strip_edges().to_lower()
	var on_board: int = 100000 if bool(entry.get("on_board", false)) else 0
	var face_up: int = 1000 if bool(entry.get("face_up", false)) else 0
	if card_type == "unit" or card_type == "character":
		var atk: int = int(entry.get("atk", 0))
		var defv: int = int(entry.get("def", 0))
		var cost: int = int(entry.get("cost", 0))
		return on_board + face_up + (atk + defv) * 100 + atk * 10 + cost
	# Traps / tech: maximize crystal cost, prefer board when both exist.
	return on_board + face_up + int(entry.get("cost", 0)) * 100


## True when this player's held omens (or legacy P0 flags) block tech.
static func cannot_tech_for(player: int) -> bool:
	return _holder_has_effect(player, "cannot_tech")


static func cannot_union_for(player: int) -> bool:
	return _holder_has_effect(player, "cannot_union")


static func attack_crystal_cost_for(player: int) -> int:
	return _sum_holder_effect_int(player, "attack_crystal_cost")


static func tech_cost_pct_for(player: int) -> float:
	return _sum_holder_effect_float(player, "tech_cost_pct")


static func trap_cost_pct_for(player: int) -> float:
	return _sum_holder_effect_float(player, "trap_cost_pct")


static func cannot_gain_crystals_for(player: int) -> bool:
	if _holder_has_effect(player, "cannot_gain_crystals"):
		return true
	# crystal_gain_pct <= -100 is an alternate "cannot gain" encoding.
	for entry: Variant in _holder_effects(player, "crystal_gain_pct"):
		if float((entry as Dictionary).get("value", 0.0)) <= -100.0:
			return true
	return false


static func crystal_gain_multiplier_for(player: int) -> float:
	if cannot_gain_crystals_for(player):
		return 0.0
	var mult: float = 1.0
	for entry: Variant in _holder_effects(player, "crystal_gain_pct"):
		var pct: float = float((entry as Dictionary).get("value", 0.0))
		mult *= maxf(0.0, 1.0 + pct / 100.0)
	return mult


static func crystal_loss_multiplier_for(player: int, reason: String = "", affinity: String = "") -> float:
	var mult: float = 1.0
	for effect_type: String in ["crystal_loss_multiplier", "crystal_loss_pct"]:
		for entry: Variant in _holder_effects(player, effect_type):
			var eff: Dictionary = entry as Dictionary
			if effect_type == "crystal_loss_multiplier":
				mult *= maxf(0.0, float(eff.get("value", 1.0)))
				continue
			var scope: String = str(eff.get("scope", "all")).strip_edges().to_lower()
			if scope == "unit_destroy" and reason != "card lost":
				continue
			if scope == "reckoning" and reason != "battle":
				continue
			if scope == "affinity" and (
					reason != "card lost"
					or str(eff.get("affinity", "")).strip_edges().to_upper() != affinity.to_upper()):
				continue
			mult *= maxf(0.0, 1.0 + float(eff.get("value", 0.0)) / 100.0)
	return mult


static func union_cost_multiplier_for(player: int) -> float:
	var mult: float = 1.0
	for entry: Variant in _holder_effects(player, "union_cost_multiplier"):
		mult *= maxf(0.0, float((entry as Dictionary).get("value", 1.0)))
	return mult


static func max_attacks_bonus_for(player: int, first_turn: bool) -> int:
	var total: int = 0
	for entry: Variant in _holder_effects(player, "max_attacks_bonus"):
		var eff: Dictionary = entry as Dictionary
		if bool(eff.get("first_turn_only", false)) and not first_turn:
			continue
		total += int(eff.get("value", 0))
	return total


static func cannot_attack_first_turn_for(player: int) -> bool:
	return _holder_has_effect(player, "cannot_attack_first_turn")


static func _holder_effects(player: int, effect_type: String) -> Array:
	var out: Array = []
	for held: Variant in all_held_omens():
		if not held is Dictionary:
			continue
		var held_d: Dictionary = held as Dictionary
		if int(held_d.get("owner", 0)) != player:
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str(held_d.get("id", "")))
		for effect: Variant in omen.get("effects", []):
			if effect is Dictionary and str((effect as Dictionary).get("type", "")) == effect_type:
				out.append(effect)
	return out


static func _holder_has_effect(player: int, effect_type: String) -> bool:
	var want: String = effect_type.strip_edges()
	for held: Variant in all_held_omens():
		if not held is Dictionary:
			continue
		var held_d: Dictionary = held as Dictionary
		if int(held_d.get("owner", 0)) != player:
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str(held_d.get("id", "")))
		if omen.is_empty():
			continue
		for effect: Variant in omen.get("effects", []):
			if not effect is Dictionary:
				continue
			var eff: Dictionary = effect as Dictionary
			if str(eff.get("type", "")) != want:
				continue
			if bool(eff.get("value", true)):
				return true
	return false


static func _sum_holder_effect_int(player: int, effect_type: String) -> int:
	var total: int = 0
	var want: String = effect_type.strip_edges()
	for held: Variant in all_held_omens():
		if not held is Dictionary:
			continue
		var held_d: Dictionary = held as Dictionary
		if int(held_d.get("owner", 0)) != player:
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str(held_d.get("id", "")))
		if omen.is_empty():
			continue
		for effect: Variant in omen.get("effects", []):
			if not effect is Dictionary:
				continue
			var eff: Dictionary = effect as Dictionary
			if str(eff.get("type", "")) == want:
				total += int(eff.get("value", 0))
	return total


static func _sum_holder_effect_float(player: int, effect_type: String) -> float:
	var total: float = 0.0
	var want: String = effect_type.strip_edges()
	for held: Variant in all_held_omens():
		if not held is Dictionary:
			continue
		var held_d: Dictionary = held as Dictionary
		if int(held_d.get("owner", 0)) != player:
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str(held_d.get("id", "")))
		if omen.is_empty():
			continue
		for effect: Variant in omen.get("effects", []):
			if not effect is Dictionary:
				continue
			var eff: Dictionary = effect as Dictionary
			if str(eff.get("type", "")) == want:
				total += float(eff.get("value", 0))
	return total


static func apply_pre_battle_crystal_and_flags() -> void:
	## Player omens only — enemy omens are rolled after setup; see apply_enemy_crystal_bonuses().
	if GameState.active_omens.is_empty():
		return
	for held: Variant in GameState.active_omens:
		if not held is Dictionary:
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str((held as Dictionary).get("id", "")))
		if omen.is_empty():
			continue
		var anointed: String = str((held as Dictionary).get("anointed_card", "")).strip_edges()
		var owner: int = int((held as Dictionary).get("owner", 0))
		for effect: Variant in omen.get("effects", []):
			if effect is Dictionary:
				_apply_pre_battle_effect(effect as Dictionary, anointed, owner)


## Starting crystal_bonus for enemy-held omens (Heavy Purse, etc.).
## Safe with force_starting_crystals — bonuses stack on top of the authored base.
## Idempotent via crystal_bonus_applied on each held entry.
static func apply_enemy_crystal_bonuses() -> void:
	for held_v: Variant in GameState.enemy_active_omens:
		if not held_v is Dictionary:
			continue
		var held: Dictionary = held_v as Dictionary
		if bool(held.get("crystal_bonus_applied", false)):
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str(held.get("id", "")))
		if omen.is_empty():
			held["crystal_bonus_applied"] = true
			continue
		var anointed: String = str(held.get("anointed_card", "")).strip_edges()
		var owner: int = int(held.get("owner", 1))
		for effect: Variant in omen.get("effects", []):
			if not effect is Dictionary:
				continue
			var eff: Dictionary = effect as Dictionary
			if str(eff.get("type", "")) != "crystal_bonus":
				continue
			var before: int = 0
			var target: int = _target_player_index(str(eff.get("target", "player")), owner)
			if target >= 0 and target < GameState.crystals.size():
				before = int(GameState.crystals[target])
			_apply_pre_battle_effect(eff, anointed, owner)
			if target >= 0 and target < GameState.crystals.size():
				var delta: int = int(GameState.crystals[target]) - before
				if delta != 0:
					var label: String = str(omen.get("label", omen.get("id", "Omen")))
					GameState.post_message("%s: %+d crystals (Player %d)." % [
						label, delta, target + 1])
		held["crystal_bonus_applied"] = true


## Above-cell runes (`placement` setup_visible / above) place during Setup so the
## player can see glyphs while arranging cards. Under-cell runes wait until begin_game.
static func _is_setup_visible_rune(effect: Dictionary) -> bool:
	var placement: String = str(effect.get("placement", "")).strip_edges().to_lower()
	return placement == "setup_visible" or placement == "above"


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
		var owner: int = int((held as Dictionary).get("owner", 0))
		for effect: Variant in omen.get("effects", []):
			if not effect is Dictionary:
				continue
			var eff: Dictionary = effect as Dictionary
			if str(eff.get("type", "")) != "cell_runes":
				continue
			if not _is_setup_visible_rune(eff):
				continue
			_place_cell_runes(eff, false, owner)


static func apply_begin_game(board: Node) -> void:
	var held_all: Array = all_held_omens()
	if held_all.is_empty():
		return
	# new_game() / reset_runtime_fields() wipe omen_anoint_effects; rebuild before
	# applying board stats (Keen Edge etc.) so anoint bonuses are not skipped when
	# no enemy omen roll rebuilds the map mid-setup.
	_build_anoint_effects_map()
	_ensure_cell_runes_grid()
	for held: Variant in held_all:
		if not held is Dictionary:
			continue
		var held_d: Dictionary = held as Dictionary
		var omen: Dictionary = OmenDatabase.get_omen(str(held_d.get("id", "")))
		if omen.is_empty():
			continue
		var anointed: String = str(held_d.get("anointed_card", "")).strip_edges()
		var owner: int = int(held_d.get("owner", 0))
		for effect: Variant in omen.get("effects", []):
			if not effect is Dictionary:
				continue
			var eff: Dictionary = effect as Dictionary
			match str(eff.get("type", "")):
				"reveal_cells":
					if str(eff.get("timing", "battle_start")).strip_edges() == "battle_start":
						_apply_reveal_cells(eff, owner)
				"cell_runes":
					# Already placed in Setup — do not re-roll at battle start.
					if not _is_setup_visible_rune(eff):
						_place_cell_runes(eff, true, owner)
				"unit_stat_flat", "unit_stat_pct":
					_apply_unit_stat_on_grid(eff, owner)
				"affinity_override_all":
					_apply_affinity_override_all(eff, owner)
	_apply_anoint_effects_on_grid()
	_apply_rune_card_effects()
	_apply_anoint_affinity_overrides()
	# Enemy omens roll post-setup — apply their starting crystal bonuses here if pending.
	apply_enemy_crystal_bonuses()
	apply_begin_game_extra(board)
	if board != null and GameState.omen_intel.is_empty():
		var ai: Node = board.get("ai_player") if board.get("ai_player") != null else null
		if ai != null:
			refresh_intel(ai, false)
	BattleResolver.recalculate_all_field_bonuses()


## Rebuild / merge player-facing insight intel from held omens.
## Bluff/personality revelations are sticky (same emoji for the duel).
## Board-dependent top-stats refresh when `include_board_stats` is true.
static func refresh_intel(ai_player: Node, include_board_stats: bool = false) -> void:
	var existing: Dictionary = {}
	for entry_v: Variant in GameState.omen_intel:
		if not entry_v is Dictionary:
			continue
		var e0: Dictionary = entry_v as Dictionary
		existing[_intel_key(e0)] = e0
	var out: Array = []
	if ai_player == null or GameState.active_omens.is_empty():
		GameState.omen_intel = out
		GameState.omen_intel_lines = []
		return
	if ai_player.has_method("ensure_personalities"):
		ai_player.call("ensure_personalities")
	for held: Variant in GameState.active_omens:
		if not held is Dictionary:
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str((held as Dictionary).get("id", "")))
		if omen.is_empty():
			continue
		var omen_id: String = str(omen.get("id", ""))
		var omen_label: String = str(omen.get("label", omen_id))
		for effect: Variant in omen.get("effects", []):
			if not effect is Dictionary:
				continue
			var eff: Dictionary = effect as Dictionary
			var etype: String = str(eff.get("type", ""))
			match etype:
				"reveal_enemy_bluff_preference":
					var pref_kind: String = str(eff.get("value", "interested")).strip_edges().to_lower()
					if pref_kind != "avoid":
						pref_kind = "interested"
					var key: String = "%s|%s|%s" % [omen_id, etype, pref_kind]
					var kept: Dictionary = existing.get(key, {}) as Dictionary
					var emoji: String = str(kept.get("emoji", "")).strip_edges()
					if emoji.is_empty():
						var pool: Array = []
						if ai_player.has_method("get_bluff_prefer_emojis") \
								and ai_player.has_method("get_bluff_avoid_emojis"):
							pool = ai_player.call("get_bluff_avoid_emojis") if pref_kind == "avoid" \
								else ai_player.call("get_bluff_prefer_emojis")
						if pool.is_empty():
							continue
						emoji = str(pool[randi() % pool.size()])
					var verb: String = "drawn to" if pref_kind == "interested" else "avoids"
					# Keep unicode out of display text — UI renders BluffEmoji art separately.
					var text: String = "%s: foe %s this bluff" % [omen_label, verb]
					out.append({
						"omen_id": omen_id,
						"omen_label": omen_label,
						"type": etype,
						"kind": pref_kind,
						"emoji": emoji,
						"text": text,
					})
				"reveal_enemy_personality":
					var axis: String = str(eff.get("value", "offensive")).strip_edges().to_lower()
					if axis != "defensive":
						axis = "offensive"
					var key2: String = "%s|%s|%s" % [omen_id, etype, axis]
					var kept2: Dictionary = existing.get(key2, {}) as Dictionary
					var pname: String = str(kept2.get("value", "")).strip_edges()
					if pname.is_empty():
						if axis == "defensive":
							pname = str(ai_player.get("personality_defensive"))
						else:
							pname = str(ai_player.get("personality_offensive"))
					if pname.is_empty():
						continue
					var axis_label: String = "Defensive" if axis == "defensive" else "Offensive"
					var text2: String = "%s: foe %s — %s" % [omen_label, axis_label, pname]
					out.append({
						"omen_id": omen_id,
						"omen_label": omen_label,
						"type": etype,
						"kind": axis,
						"value": pname,
						"text": text2,
					})
				"reveal_enemy_top_stats":
					if not include_board_stats:
						# Keep prior board reveal if any; otherwise skip until board exists.
						var kind: String = str(eff.get("kind", "strongest_unit")).strip_edges().to_lower()
						var key3: String = "%s|%s|%s" % [omen_id, etype, kind]
						if existing.has(key3):
							out.append((existing[key3] as Dictionary).duplicate(true))
						continue
					var kind2: String = str(eff.get("kind", "strongest_unit")).strip_edges().to_lower()
					var amount: int = maxi(1, int(eff.get("count", 1)))
					var intel_line: String = _build_enemy_top_stats_line(omen_label, kind2, amount)
					if intel_line.is_empty():
						continue
					out.append({
						"omen_id": omen_id,
						"omen_label": omen_label,
						"type": etype,
						"kind": kind2,
						"text": intel_line,
					})
	GameState.omen_intel = out
	var lines: PackedStringArray = PackedStringArray()
	for row_v: Variant in out:
		if row_v is Dictionary:
			var t: String = str((row_v as Dictionary).get("text", "")).strip_edges()
			if not t.is_empty():
				lines.append(t)
	GameState.omen_intel_lines = lines


static func _intel_key(entry: Dictionary) -> String:
	return "%s|%s|%s" % [
		str(entry.get("omen_id", "")),
		str(entry.get("type", "")),
		str(entry.get("kind", "")),
	]


## Intel rows for a specific omen id.
static func intel_for_omen(omen_id: String) -> Array:
	var want: String = omen_id.strip_edges()
	var rows: Array = []
	for entry_v: Variant in GameState.omen_intel:
		if not entry_v is Dictionary:
			continue
		if str((entry_v as Dictionary).get("omen_id", "")) == want:
			rows.append(entry_v)
	return rows


## "interested" / "avoided" / "" for a bluff emoji revealed by insight omens.
static func bluff_intel_kind(emoji: String) -> String:
	var needle: String = BluffEmoji.canonical(emoji.strip_edges())
	if needle.is_empty():
		return ""
	var interested: bool = false
	var avoided: bool = false
	for entry_v: Variant in GameState.omen_intel:
		if not entry_v is Dictionary:
			continue
		var e: Dictionary = entry_v as Dictionary
		if str(e.get("type", "")) != "reveal_enemy_bluff_preference":
			continue
		if BluffEmoji.canonical(str(e.get("emoji", "")).strip_edges()) != needle:
			continue
		var kind: String = str(e.get("kind", "")).strip_edges().to_lower()
		if kind == "avoid":
			avoided = true
		else:
			interested = true
	if interested:
		return "interested"
	if avoided:
		return "avoided"
	return ""


## Pulse chrome + instant hover tip above bluff picker buttons for revealed prefs.
static func decorate_bluff_button(btn: Button, emoji: String) -> void:
	if btn == null:
		return
	var kind: String = bluff_intel_kind(emoji)
	if kind.is_empty():
		return
	var interested: bool = kind == "interested"
	var tip_text: String = "Interested by enemy" if interested else "Avoided by enemy"
	# Native tooltip_text has delay + OS placement — use an instant custom tip instead.
	btn.tooltip_text = ""
	var tint: Color = Color(0.28, 0.92, 0.55, 1.0) if interested \
			else Color(1.0, 0.42, 0.38, 1.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(tint.r, tint.g, tint.b, 0.22)
	sb.border_color = Color(tint.r, tint.g, tint.b, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state, sb)
	# Soft pulse on border alpha / modulate.
	var tw: Tween = btn.create_tween().set_loops()
	tw.tween_property(btn, "modulate", Color(1.15, 1.15, 1.15, 1.0), 0.55) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.55) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_attach_instant_bluff_tip(btn, tip_text, tint)


static func _attach_instant_bluff_tip(btn: Button, tip_text: String, tint: Color) -> void:
	var tip := PanelContainer.new()
	tip.name = "BluffIntelTip"
	tip.visible = false
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.z_index = 80
	tip.set_as_top_level(true)
	var tip_sb := StyleBoxFlat.new()
	tip_sb.bg_color = Color(0.06, 0.08, 0.14, 0.96)
	tip_sb.border_color = Color(tint.r, tint.g, tint.b, 0.9)
	tip_sb.set_border_width_all(1)
	tip_sb.set_corner_radius_all(6)
	tip_sb.content_margin_left = 10
	tip_sb.content_margin_right = 10
	tip_sb.content_margin_top = 5
	tip_sb.content_margin_bottom = 5
	tip.add_theme_stylebox_override("panel", tip_sb)
	var lbl := Label.new()
	lbl.text = tip_text
	lbl.add_theme_font_override("font", FontManager.make_font("primary", 600))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", tint.lightened(0.25))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_child(lbl)
	btn.add_child(tip)

	var place_tip := func() -> void:
		if tip == null or not is_instance_valid(tip) or not is_instance_valid(btn):
			return
		tip.reset_size()
		var br: Rect2 = btn.get_global_rect()
		var ts: Vector2 = tip.get_combined_minimum_size()
		if ts.x < 2.0:
			ts = tip.size
		const GAP: float = 6.0
		var tx: float = br.position.x + br.size.x * 0.5 - ts.x * 0.5
		var ty: float = br.position.y - ts.y - GAP
		var vp: Vector2 = btn.get_viewport_rect().size
		tip.global_position = Vector2(
			clampf(tx, 4.0, maxf(4.0, vp.x - ts.x - 4.0)),
			clampf(ty, 4.0, maxf(4.0, vp.y - ts.y - 4.0)))

	btn.mouse_entered.connect(func() -> void:
		if not is_instance_valid(tip):
			return
		tip.visible = true
		place_tip.call()
		# One-frame defer so size is correct after first show.
		btn.get_tree().process_frame.connect(place_tip, CONNECT_ONE_SHOT))
	btn.mouse_exited.connect(func() -> void:
		if is_instance_valid(tip):
			tip.visible = false)
	btn.tree_exiting.connect(func() -> void:
		if is_instance_valid(tip):
			tip.queue_free())


static func collect_intel_lines(ai_player: Node) -> Array:
	refresh_intel(ai_player, true)
	return GameState.omen_intel_lines


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
	for owner: int in range(2):
		for eff: Variant in _anoint_bucket(owner, card_name):
			if not eff is Dictionary:
				continue
			var eff_d: Dictionary = eff as Dictionary
			# Enemy anoint details only when the target is already public knowledge.
			if int(eff_d.get("omen_owner", 0)) == 1:
				var probe: Dictionary = {"owner": 1, "anointed_card": card_name}
				if not OmenVisuals.anoint_target_is_public(probe):
					continue
			var line: String = _format_anoint_effect_line(eff_d)
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
	for held: Variant in all_held_omens():
		if not held is Dictionary:
			continue
		var held_d: Dictionary = held as Dictionary
		var anointed: String = str(held_d.get("anointed_card", "")).strip_edges()
		if anointed.is_empty():
			continue
		var omen: Dictionary = OmenDatabase.get_omen(str(held_d.get("id", "")))
		if omen.is_empty():
			continue
		var owner: int = int(held_d.get("owner", 0))
		var key: String = _anoint_key(owner, anointed)
		var bucket: Array = GameState.omen_anoint_effects.get(key, [])
		if not bucket is Array:
			bucket = []
		for effect: Variant in omen.get("effects", []):
			if effect is Dictionary:
				var eff: Dictionary = (effect as Dictionary).duplicate(true)
				var etype: String = str(eff.get("type", ""))
				if etype.begins_with("anoint_") or etype in _ANPOINT_RUNTIME_TYPES:
					eff["omen_owner"] = owner
					eff["anointed_card"] = anointed
					bucket.append(eff)
		if not bucket.is_empty():
			GameState.omen_anoint_effects[key] = bucket


static func _anoint_key(owner: int, card_name: String) -> String:
	return "%d::%s" % [owner, card_name]


static func _anoint_bucket(owner: int, card_name: String) -> Array:
	var bucket: Variant = GameState.omen_anoint_effects.get(_anoint_key(owner, card_name), [])
	return bucket as Array if bucket is Array else []


static func _apply_pre_battle_effect(effect: Dictionary, _anointed: String, omen_owner: int = 0) -> void:
	# Pre-battle global flags accumulate on GameState for the omen holder (P0 path today).
	# Enemy omens roll after setup and use owner-aware helpers at gate points instead.
	if omen_owner != 0 and str(effect.get("type", "")) != "crystal_bonus":
		return
	match str(effect.get("type", "")):
		"crystal_bonus":
			var target: int = _target_player_index(str(effect.get("target", "player")), omen_owner)
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


static func _apply_reveal_cells(effect: Dictionary, omen_owner: int = 0) -> void:
	var target: int = _target_player_index(str(effect.get("target", "enemy")), omen_owner)
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


static func _place_cell_runes(effect: Dictionary, occupied_only: bool, omen_owner: int = 0) -> void:
	var target: int = _target_player_index(str(effect.get("target", "player")), omen_owner)
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


static func _apply_unit_stat_on_grid(effect: Dictionary, omen_owner: int = 0) -> void:
	var target: int = _target_player_index(str(effect.get("target", "player")), omen_owner)
	if target < 0:
		return
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(target, r, c)
			if not _card_matches_unit_filter(card, effect.get("filter", {}), r, c):
				continue
			_apply_unit_stat_to_card(card, effect)


## Apply held unit_stat_flat / unit_stat_pct omens to one card (e.g. a just-summoned union).
## Optional row/col override position filters (border / center); defaults to card.grid_*.
static func apply_matching_unit_stats_to_card(
		card: GameState.CardInstance,
		owner_player: int,
		row: int = -1,
		col: int = -1) -> void:
	if card == null or card.card_type != "character":
		return
	var r: int = row if row >= 0 else int(card.grid_row)
	var c: int = col if col >= 0 else int(card.grid_col)
	for type_name: String in ["unit_stat_flat", "unit_stat_pct"]:
		for entry_v: Variant in effects_of_type(type_name):
			if not entry_v is Dictionary:
				continue
			var entry: Dictionary = entry_v as Dictionary
			if not _card_matches_effect_unit(card, entry, owner_player, r, c):
				continue
			var eff: Dictionary = entry.get("effect", {}) as Dictionary
			_apply_unit_stat_to_card(card, eff)


static func _apply_anoint_effects_on_grid() -> void:
	for key: Variant in GameState.omen_anoint_effects.keys():
		var effects: Variant = GameState.omen_anoint_effects[key]
		if not effects is Array:
			continue
		for eff_v: Variant in effects as Array:
			if not eff_v is Dictionary:
				continue
			var eff: Dictionary = eff_v as Dictionary
			var owner: int = int(eff.get("omen_owner", -1))
			var card_name: String = str(eff.get("anointed_card", ""))
			if owner < 0 or card_name.is_empty():
				continue
			for r: int in range(GameState.GRID_SIZE):
				for c: int in range(GameState.GRID_SIZE):
					var card: GameState.CardInstance = GameState.get_card(owner, r, c)
					if card.card_name == card_name:
						_apply_anoint_stat_to_card(card, eff)


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


static func _apply_affinity_override_all(effect: Dictionary, omen_owner: int = 0) -> void:
	var aff: int = _affinity_from_name(str(effect.get("affinity", "")))
	if aff < 0:
		return
	var target: int = _target_player_index(str(effect.get("target", "player")), omen_owner)
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(target, r, c)
			if card.card_type == "character":
				card.affinity = aff


static func _apply_anoint_affinity_overrides() -> void:
	for key: Variant in GameState.omen_anoint_effects.keys():
		var effects: Variant = GameState.omen_anoint_effects[key]
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
			var owner: int = int(eff.get("omen_owner", -1))
			var card_name: String = str(eff.get("anointed_card", ""))
			for r: int in range(GameState.GRID_SIZE):
				for c: int in range(GameState.GRID_SIZE):
					var card: GameState.CardInstance = GameState.get_card(owner, r, c)
					if card.card_name == card_name and card.card_type == "character":
						card.affinity = aff


static func _card_matches_unit_filter(
		card: GameState.CardInstance,
		filter: Variant,
		row: int,
		col: int) -> bool:
	## Unions count as units for every field filter (name / affinity / position / trait).
	if card == null or card.card_type != "character":
		return false
	if filter is String:
		var fs: String = str(filter).strip_edges().to_lower()
		if fs.is_empty() or fs == "all":
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
		# Live affinity (covers unions + Mass Transfiguration overrides).
		if _affinity_name(card.affinity) != want_name:
			return false
	if filt.has("card_name"):
		if card.card_name != str(filt.get("card_name", "")):
			return false
	if filt.has("name_contains"):
		var needle: String = str(filt.get("name_contains", ""))
		if not card.card_name.to_lower().contains(needle.to_lower()):
			return false
	if filt.has("name_contains_any"):
		var any_list: Variant = filt.get("name_contains_any", [])
		if any_list is Array:
			var matched: bool = false
			var hay: String = card.card_name.to_lower()
			for fragment: Variant in any_list as Array:
				if hay.contains(str(fragment).to_lower()):
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


static func _target_player_index(target: String, omen_owner: int = 0) -> int:
	## "player" / holder = omen owner; "enemy" / foe = the opposite side.
	match str(target).strip_edges().to_lower():
		"player", "p0", "human", "holder", "self":
			return omen_owner
		"enemy", "foe", "p1", "ai", "opponent":
			return 1 - omen_owner
	return omen_owner


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
		"anoint_bonus_vs_same_affinity":
			return "+%d ATK / +%d DEF vs same affinity" % [
				int(effect.get("atk", 0)), int(effect.get("def", 0))]
		"anoint_bonus_vs_facedown":
			return "+%d ATK vs face-down" % int(effect.get("atk", 0))
		"anoint_turn_start_coin_atk":
			return "Turn start: %d coin(s), +%d ATK per heads" % [
				int(effect.get("coins", 3)), int(effect.get("atk_per_head", 25))]
		"anoint_foe_turn_start_coin_def":
			return "Foe turn start: %d coin(s), +%d DEF per heads" % [
				int(effect.get("coins", 3)), int(effect.get("def_per_head", 25))]
		"anoint_on_defend_success_gain_def":
			return "Defend success: +%d DEF" % int(effect.get("def", 0))
		"anoint_on_attack_success_gain_atk":
			return "Attack success: +%d ATK" % int(effect.get("atk", 0))
		"anoint_post_attack_half_stats":
			return "After attack: halve own ATK/DEF"
		"post_attack_coin_extra_attack":
			return "After attack: coin heads => extra attack"
		"post_attack_coin_reveal_adjacent":
			return "After attack: coin reveal adjacent"
		"adjacent_aura_flat":
			return "Adjacent allies: %+d ATK, %+d DEF" % [
				int(effect.get("atk", 0)), int(effect.get("def", 0))]
		"adjacent_aura_survive_once":
			return "Adjacent allies survive destruction once"
		"adjacent_aura_cost_multiplier_once":
			return "Adjacent allies cost ×%.2f (once)" % float(effect.get("value", 1.0))
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
	"union_material_wildcard",
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
	"post_attack_coin_extra_attack",
	"post_attack_coin_reveal_adjacent",
	"anoint_bonus_vs_same_affinity",
	"anoint_bonus_vs_facedown",
	"anoint_post_attack_half_stats",
	"anoint_turn_start_coin_atk",
	"anoint_foe_turn_start_coin_def",
	"anoint_on_defend_success_gain_def",
	"anoint_on_attack_success_gain_atk",
	"adjacent_aura_flat",
	"adjacent_aura_survive_once",
	"adjacent_aura_cost_multiplier_once",
	"reveal_enemy_top_stats",
]


static func effects_of_type(type_name: String) -> Array:
	var out: Array = []
	var want: String = type_name.strip_edges()
	var held_all: Array = all_held_omens()
	if want.is_empty() or held_all.is_empty():
		return out
	for held: Variant in held_all:
		if not held is Dictionary:
			continue
		var held_d: Dictionary = held as Dictionary
		var omen: Dictionary = OmenDatabase.get_omen(str(held_d.get("id", "")))
		if omen.is_empty():
			continue
		var anointed: String = str(held_d.get("anointed_card", "")).strip_edges()
		var owner: int = int(held_d.get("owner", 0))
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
				"owner": owner,
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
		var needle: String = str(filt.get("name_contains", ""))
		if not card_name.to_lower().contains(needle.to_lower()):
			return false
	if filt.has("name_contains_any"):
		var any_list: Variant = filt.get("name_contains_any", [])
		if any_list is Array:
			var matched: bool = false
			var hay: String = card_name.to_lower()
			for fragment: Variant in any_list as Array:
				if hay.contains(str(fragment).to_lower()):
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
		owner_player: int,
		row: int = -1,
		col: int = -1) -> bool:
	if card == null or card.card_type != "character":
		return false
	var anointed: String = str(entry.get("anointed", "")).strip_edges()
	if not anointed.is_empty():
		return card.card_name == anointed and owner_player == int(entry.get("owner", -1))
	var eff: Dictionary = entry.get("effect", {}) as Dictionary
	# Field-wide filters: owner must match omen holder resolved via target.
	var target: String = str(eff.get("target", "player")).strip_edges().to_lower()
	var omen_owner: int = int(entry.get("owner", 0))
	var want_owner: int = _target_player_index(target if not target.is_empty() else "player", omen_owner)
	if owner_player != want_owner:
		return false
	var filt: Variant = eff.get("filter", {})
	var r: int = row if row >= 0 else int(card.grid_row)
	var c: int = col if col >= 0 else int(card.grid_col)
	return _card_matches_unit_filter(card, filt, r, c)


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


static func try_consume_survive_destruction_once(
		card: GameState.CardInstance, owner_player: int) -> bool:
	if card == null or card.card_type != "character":
		return false
	if "omen_survive_used" in card.flags:
		return false
	# Anoint map
	if anoint_has_type(card.card_name, "survive_destruction_once", owner_player):
		card.flags.append("omen_survive_used")
		return true
	# Field-wide omens (owner = player 0)
	for entry: Variant in effects_of_type("survive_destruction_once"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if _card_matches_effect_unit(card, e, owner_player):
			card.flags.append("omen_survive_used")
			return true
	# Adjacent aura once: if this card is adjacent to an anointed hub.
	for entry2: Variant in effects_of_type("adjacent_aura_survive_once"):
		if not entry2 is Dictionary:
			continue
		var e2: Dictionary = entry2 as Dictionary
		var anointed: String = str(e2.get("anointed", "")).strip_edges()
		if anointed.is_empty():
			continue
		for p: int in range(2):
			for r: int in range(GameState.GRID_SIZE):
				for c: int in range(GameState.GRID_SIZE):
					var hub: GameState.CardInstance = GameState.get_card(p, r, c)
					if hub.card_type != "character" or hub.card_name != anointed:
						continue
					for adj: Vector2i in GameState.get_adjacent_positions(r, c):
						var ally: GameState.CardInstance = GameState.get_card(p, adj.x, adj.y)
						if ally == card:
							card.flags.append("omen_survive_used")
							return true
	return false


static func _build_enemy_top_stats_line(omen_label: String, kind: String, amount: int) -> String:
	var enemy: int = 1
	var unit_rows: Array[Dictionary] = []
	var trap_rows: Array[Dictionary] = []
	var tech_rows: Array[Dictionary] = []
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(enemy, r, c)
			if card.card_type == "character":
				unit_rows.append({
					"name": card.card_name,
					"atk": card.base_atk,
					"def": card.base_def,
					"sum": card.base_atk + card.base_def,
					"is_union": card.is_union,
				})
			elif card.card_type == "trap":
				trap_rows.append({
					"name": card.card_name,
					"cost": card.crystal_cost,
				})
	for tech_name_v: Variant in GameState.tech_hands[enemy]:
		var tech_name: String = str(tech_name_v)
		var td: TechCardData = CardDatabase.get_tech(tech_name)
		if td != null:
			tech_rows.append({"name": tech_name, "cost": td.crystal_cost})
	if kind == "strongest_unit":
		unit_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("sum", 0)) > int(b.get("sum", 0)))
		var top_units: PackedStringArray = PackedStringArray()
		for i: int in range(mini(amount, unit_rows.size())):
			var u: Dictionary = unit_rows[i]
			top_units.append("%s(%d/%d)" % [str(u.get("name", "")), int(u.get("atk", 0)), int(u.get("def", 0))])
		if top_units.is_empty():
			return ""
		return "%s: foe strongest unit(s) — %s" % [omen_label, ", ".join(top_units)]
	if kind == "highest_cost_tech":
		tech_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("cost", 0)) > int(b.get("cost", 0)))
		var top_techs: PackedStringArray = PackedStringArray()
		for i2: int in range(mini(amount, tech_rows.size())):
			var t: Dictionary = tech_rows[i2]
			top_techs.append("%s(%d)" % [str(t.get("name", "")), int(t.get("cost", 0))])
		if top_techs.is_empty():
			return ""
		return "%s: foe highest-cost tech — %s" % [omen_label, ", ".join(top_techs)]
	if kind == "highest_cost_trap":
		trap_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("cost", 0)) > int(b.get("cost", 0)))
		var top_traps: PackedStringArray = PackedStringArray()
		for i3: int in range(mini(amount, trap_rows.size())):
			var tr: Dictionary = trap_rows[i3]
			top_traps.append("%s(%d)" % [str(tr.get("name", "")), int(tr.get("cost", 0))])
		if top_traps.is_empty():
			return ""
		return "%s: foe highest-cost trap — %s" % [omen_label, ", ".join(top_traps)]
	if kind == "strongest_unit_and_union":
		unit_rows.sort_custom(func(a2: Dictionary, b2: Dictionary) -> bool: return int(a2.get("sum", 0)) > int(b2.get("sum", 0)))
		var strongest_unit: String = ""
		if not unit_rows.is_empty():
			var uu: Dictionary = unit_rows[0]
			strongest_unit = "%s(%d/%d)" % [str(uu.get("name", "")), int(uu.get("atk", 0)), int(uu.get("def", 0))]
		var unions: Array[Dictionary] = []
		for row: Dictionary in unit_rows:
			if bool(row.get("is_union", false)):
				unions.append(row)
		unions.sort_custom(func(a3: Dictionary, b3: Dictionary) -> bool: return int(a3.get("sum", 0)) > int(b3.get("sum", 0)))
		var strongest_union: String = ""
		if not unions.is_empty():
			var un: Dictionary = unions[0]
			strongest_union = "%s(%d/%d)" % [str(un.get("name", "")), int(un.get("atk", 0)), int(un.get("def", 0))]
		if strongest_unit.is_empty() and strongest_union.is_empty():
			return ""
		if strongest_union.is_empty():
			return "%s: foe strongest unit — %s (no union found)" % [omen_label, strongest_unit]
		return "%s: foe strongest unit/union — %s | %s" % [omen_label, strongest_unit, strongest_union]
	return ""


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
	for entry: Variant in effects_of_type("lock_attacker_on_trap"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		var omen_owner: int = int(e.get("owner", 0))
		var anointed: String = str(e.get("anointed", "")).strip_edges()
		if not anointed.is_empty():
			if trap_card_name == anointed and trap_owner == omen_owner:
				return true
			continue
		var eff: Dictionary = e.get("effect", {}) as Dictionary
		var owner: int = int(e.get("owner", -1))
		if trap_owner != _target_player_index(str(eff.get("target", "player")), omen_owner):
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


static func post_reckoning_reveal_targets_field(
		attacker: GameState.CardInstance,
		attacker_player: int) -> bool:
	for entry: Variant in effects_of_type("reveal_after_reckoning"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		if _card_matches_effect_unit(attacker, e, attacker_player) \
				and str((e.get("effect", {}) as Dictionary).get(
					"target", "enemy")).strip_edges().to_lower() == "field":
			return true
	return false


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


static func anoint_cost_multiplier_for(card_name: String, owner: int) -> float:
	var mult: float = 1.0
	for eff_v: Variant in _anoint_bucket(owner, card_name):
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


static func same_affinity_atk_bonus(
		attacker: GameState.CardInstance,
		defender: GameState.CardInstance,
		attacker_player: int) -> int:
	if attacker == null or defender == null:
		return 0
	if attacker.affinity != defender.affinity:
		return 0
	var bonus: int = 0
	for entry: Variant in effects_of_type("anoint_bonus_vs_same_affinity"):
		if not entry is Dictionary:
			continue
		if _card_matches_effect_unit(attacker, entry as Dictionary, attacker_player):
			bonus += int((entry as Dictionary).get("effect", {}).get("atk", 0))
	return bonus


static func same_affinity_def_bonus(
		defender: GameState.CardInstance,
		attacker: GameState.CardInstance,
		defender_player: int) -> int:
	if attacker == null or defender == null:
		return 0
	if attacker.affinity != defender.affinity:
		return 0
	var bonus: int = 0
	for entry: Variant in effects_of_type("anoint_bonus_vs_same_affinity"):
		if not entry is Dictionary:
			continue
		if _card_matches_effect_unit(defender, entry as Dictionary, defender_player):
			bonus += int((entry as Dictionary).get("effect", {}).get("def", 0))
	return bonus


static func facedown_atk_bonus(
		attacker: GameState.CardInstance,
		attacker_player: int,
		defender_was_exposed: bool) -> int:
	if attacker == null or defender_was_exposed:
		return 0
	var bonus: int = 0
	for entry: Variant in effects_of_type("anoint_bonus_vs_facedown"):
		if not entry is Dictionary:
			continue
		if _card_matches_effect_unit(attacker, entry as Dictionary, attacker_player):
			bonus += int((entry as Dictionary).get("effect", {}).get("atk", 0))
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


static func anoint_has_type(card_name: String, type_name: String, owner: int) -> bool:
	for eff_v: Variant in _anoint_bucket(owner, card_name):
		if eff_v is Dictionary and str((eff_v as Dictionary).get("type", "")) == type_name:
			return true
	return false


static func anoint_effect(card_name: String, type_name: String, owner: int) -> Dictionary:
	for eff_v: Variant in _anoint_bucket(owner, card_name):
		if eff_v is Dictionary and str((eff_v as Dictionary).get("type", "")) == type_name:
			return eff_v as Dictionary
	return {}

static func union_material_wildcard_for(card_name: String, owner: int) -> bool:
	return anoint_has_type(card_name, "union_material_wildcard", owner)


static func coin_bias_for_card(card_name: String, owner: int) -> String:
	var eff: Dictionary = anoint_effect(card_name, "coin_bias", owner)
	return str(eff.get("value", "")).strip_edges()


static func biased_coin_result(card_name: String, owner: int) -> int:
	## Returns 1=heads, 0=tails, -1=no bias.
	var bias: String = coin_bias_for_card(card_name, owner)
	if bias == "always_heads":
		return 1
	if bias == "soft_heads":
		return 1 if randf() < 0.75 else 0
	return -1


## Apply ATK/DEF deltas with anointed stat_duration (Etched Brand etc.).
## Routed: trap field/one-unit temp boosts, tech TEMP_ATK_BOOST_ATTACK_NOW,
## trap TEMP_DEBUFF_ALL_ATTACKER_CHARS, trap self-destruct temp boost.
## Gaps (unit ability self-buffs, carry-def traps, perm tech boosts, coin omen
## turn-start ATK): still write temp/perm directly — Etched Brand will not rewrite those.
static func apply_stat_change_from_source(
		target: GameState.CardInstance,
		atk_delta: int,
		def_delta: int,
		source_card_name: String,
		source_owner: int) -> void:
	if target == null:
		return
	var dur: Dictionary = anoint_effect(source_card_name, "stat_duration", source_owner)
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


static func has_trap_coin_negate(attacker: GameState.CardInstance, owner: int) -> bool:
	return attacker != null and anoint_has_type(attacker.card_name, "trap_coin_negate", owner)


static func has_negate_zero_cost_traps(attacker: GameState.CardInstance, owner: int) -> bool:
	return attacker != null and anoint_has_type(attacker.card_name, "negate_zero_cost_traps", owner)


static func has_full_trap_tech_immunity(attacker: GameState.CardInstance, owner: int) -> bool:
	if attacker == null:
		return false
	if anoint_has_type(attacker.card_name, "mutagen_immunity", owner):
		if attacker.has_mutagen_flag or "mutagen" in attacker.flags:
			return true
	# null_aegis: extend existing 0-cost trap immunity to all traps/tech
	for entry: Variant in effects_of_type("extend_trap_immunity"):
		if entry is Dictionary and int((entry as Dictionary).get("owner", -1)) == owner \
				and (attacker.ability_type in [
				CharacterData.AbilityType.IMMUNE_ZERO_COST_TRAPS,
				CharacterData.AbilityType.IMMUNE_TO_TECH_DESTRUCTION] \
				or has_negate_zero_cost_traps(attacker, owner)):
			return true
	return false


static func has_ability_immunity_vs_units(card: GameState.CardInstance, owner: int) -> bool:
	return card != null and anoint_has_type(card.card_name, "ability_immunity_vs_units", owner)


static func has_trap_immunity_on_bluff(
		attacker: GameState.CardInstance,
		attacker_player: int,
		attacker_pos: Vector2i) -> bool:
	if attacker == null or not anoint_has_type(
			attacker.card_name, "trap_immunity_on_bluff_cell", attacker_player):
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
	if anoint_has_type(card.card_name, "survive_reckoning_ties", owner_player):
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
		owner_player: int,
		cell_has_bluff: bool) -> bool:
	if card == null or not cell_has_bluff:
		return false
	if "omen_gambler_used" in card.flags:
		return false
	if anoint_has_type(card.card_name, "survive_reckoning_vs_bluff_once", owner_player):
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
		attacker_player: int,
		defender_player: int,
		target_pos: Vector2i) -> int:
	if attacker == null or not anoint_has_type(
			attacker.card_name, "conditional_stat_vs_bluff", attacker_player):
		return 0
	if GameState.get_bluff(defender_player, target_pos.x, target_pos.y).is_empty():
		return 0
	var eff: Dictionary = anoint_effect(
		attacker.card_name, "conditional_stat_vs_bluff", attacker_player)
	return int(eff.get("atk", 0))


static func effect_override_for(card_name: String, owner: int) -> Dictionary:
	return anoint_effect(card_name, "effect_override", owner)


static func barrel_gospel_active(trap_owner: int) -> bool:
	for entry: Variant in effects_of_type("trap_effect_override_all"):
		if entry is Dictionary and int((entry as Dictionary).get("owner", -1)) == trap_owner:
			return true
	return false


static func max_tech_per_turn(player: int) -> int:
	var n: int = 1
	for entry: Variant in effects_of_type("extra_tech_per_turn"):
		if entry is Dictionary and int((entry as Dictionary).get("owner", -1)) == player:
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
		var target: int = _target_player_index(str(eff.get("target", "player")), int(e.get("owner", 0)))
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(target, r, c)
				if not _card_matches_unit_filter(card, eff.get("filter", {}), r, c):
					continue
				card.crystal_cost = int(round(float(card.crystal_cost) * mult))


static func _anoint_effect_for_owner(card_name: String, type_name: String, owner: int) -> Dictionary:
	return anoint_effect(card_name, type_name, owner)


static func union_material_bonuses(material_names: Array, owner: int = 0) -> Dictionary:
	var cost_mult: float = 1.0
	var atk: int = 0
	var defv: int = 0
	var crystals: int = 0
	for name_v: Variant in material_names:
		var name: String = str(name_v)
		var cm: Dictionary = _anoint_effect_for_owner(
			name, "union_material_cost_multiplier", owner)
		if not cm.is_empty():
			cost_mult *= float(cm.get("value", 1.0))
		var st: Dictionary = _anoint_effect_for_owner(
			name, "union_material_stat_boost", owner)
		if not st.is_empty():
			atk += int(st.get("atk", 0))
			defv += int(st.get("def", 0))
		var cg: Dictionary = _anoint_effect_for_owner(
			name, "union_material_crystal_gain", owner)
		if not cg.is_empty():
			crystals += int(cg.get("value", 0))
	return {"cost_mult": cost_mult, "atk": atk, "def": defv, "crystals": crystals}


static func should_refund_dead_end(attacker: GameState.CardInstance, owner: int) -> bool:
	return attacker != null and anoint_has_type(attacker.card_name, "refund_dead_end_attack", owner)


static func foe_kill_crystal_mult(attacker: GameState.CardInstance, owner: int) -> float:
	if attacker == null:
		return 1.0
	var eff: Dictionary = anoint_effect(
		attacker.card_name, "foe_crystal_loss_multiplier_on_kill", owner)
	if eff.is_empty():
		return 1.0
	return float(eff.get("value", 1.0))


static func trap_crystal_loss_mult(trap_name: String, owner: int) -> float:
	var eff: Dictionary = anoint_effect(trap_name, "trap_crystal_loss_multiplier", owner)
	if eff.is_empty():
		return 1.0
	return float(eff.get("value", 1.0))


static func has_executioners_pact(attacker: GameState.CardInstance, owner: int) -> bool:
	return attacker != null and anoint_has_type(
		attacker.card_name, "discard_tech_destroy_foe", owner)


static func has_hex_seal(attacker: GameState.CardInstance, owner: int) -> bool:
	return attacker != null and anoint_has_type(
		attacker.card_name, "nullify_defender_first_attack", owner)


static func has_silence_brand(card: GameState.CardInstance, owner: int) -> bool:
	return card != null and anoint_has_type(
		card.card_name, "nullify_foe_ability_in_reckoning", owner)


static func queue_divine_return(card: GameState.CardInstance, player: int, row: int, col: int) -> void:
	if card == null or not anoint_has_type(card.card_name, "revive_once_end_of_turn", player):
		return
	if "divine_return_used" in card.flags:
		return
	card.flags.append("divine_return_used")
	GameState.turn_start_revives.append({
		"player": player, "row": row, "col": col, "card_name": card.card_name,
		"omen_divine_return": true,
	})


static func should_phoenix_revive(
		card: GameState.CardInstance, owner: int, destroy_source: String) -> bool:
	## destroy_source: "own_tech" | "own_ability" | "omen" | "foe" | "other"
	if card == null or not anoint_has_type(
			card.card_name, "conditional_revive_omen_or_self", owner):
		return false
	return destroy_source in ["own_tech", "own_ability", "omen"]


static func apply_begin_game_extra(board: Node) -> void:
	apply_unit_destroy_cost_multipliers()
	# Mark destroy_at_expose_turn_end anointed units
	for p: int in range(2):
		for r: int in range(GameState.GRID_SIZE):
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(p, r, c)
				if anoint_has_type(card.card_name, "destroy_at_expose_turn_end", p):
					card.flags.append("omen_burn_on_expose_eot")
	apply_adjacent_auras()
	apply_adjacent_flat_auras()
	apply_adjacent_cost_auras_once()
	shuffle_all_units_if_needed()
	if board != null:
		pass


static func apply_grant_flag_on_reveal(
		card: GameState.CardInstance, owner_player: int, _row: int, _col: int) -> void:
	if card == null or card.card_type != "character":
		return
	var flags_to_grant: Array = []
	for oe: Variant in _anoint_bucket(owner_player, card.card_name):
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
		var owner: int = int(e.get("owner", -1))
		var want_aff: int = _affinity_from_name(str(eff.get("affinity", "")))
		var atk_pct: float = float(eff.get("atk_pct", 0))
		var def_pct: float = float(eff.get("def_pct", 0))
		for p: int in [owner]:
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


static func apply_adjacent_flat_auras() -> void:
	for entry: Variant in effects_of_type("adjacent_aura_flat"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		var anointed: String = str(e.get("anointed", ""))
		if anointed.is_empty():
			continue
		var eff: Dictionary = e.get("effect", {}) as Dictionary
		var owner: int = int(e.get("owner", -1))
		var add_atk: int = int(eff.get("atk", 0))
		var add_def: int = int(eff.get("def", 0))
		for p: int in [owner]:
			for r: int in range(GameState.GRID_SIZE):
				for c: int in range(GameState.GRID_SIZE):
					var hub: GameState.CardInstance = GameState.get_card(p, r, c)
					if hub.card_name != anointed or hub.card_type != "character":
						continue
					for adj: Vector2i in GameState.get_adjacent_positions(r, c):
						var ally: GameState.CardInstance = GameState.get_card(p, adj.x, adj.y)
						if ally.card_type != "character":
							continue
						ally.perm_atk_bonus += add_atk
						ally.perm_def_bonus += add_def


static func apply_adjacent_cost_auras_once() -> void:
	for entry: Variant in effects_of_type("adjacent_aura_cost_multiplier_once"):
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry as Dictionary
		var anointed: String = str(e.get("anointed", ""))
		if anointed.is_empty():
			continue
		var eff: Dictionary = e.get("effect", {}) as Dictionary
		var owner: int = int(e.get("owner", -1))
		var mult: float = maxf(0.0, float(eff.get("value", 1.0)))
		for p: int in [owner]:
			for r: int in range(GameState.GRID_SIZE):
				for c: int in range(GameState.GRID_SIZE):
					var hub: GameState.CardInstance = GameState.get_card(p, r, c)
					if hub.card_name != anointed or hub.card_type != "character":
						continue
					for adj: Vector2i in GameState.get_adjacent_positions(r, c):
						var ally: GameState.CardInstance = GameState.get_card(p, adj.x, adj.y)
						if ally.card_type != "character":
							continue
						ally.crystal_cost = int(round(float(ally.crystal_cost) * mult))


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


static func ignores_trap_affinity(trap_name: String, owner: int) -> bool:
	return anoint_has_type(trap_name, "ignore_trap_affinity", owner)


static func should_reveal_on_trap_trigger(trap_name: String, owner: int) -> bool:
	return anoint_has_type(trap_name, "reveal_on_trap_trigger", owner)


static func attack_lock_defender_turns() -> int:
	var n: int = 0
	for entry: Variant in effects_of_type("attack_lock_defender_turns"):
		if entry is Dictionary:
			n = maxi(n, int((entry as Dictionary).get("effect", {}).get("value", 0)))
	return n


static func has_escalating_toll(for_owner: int = -1) -> bool:
	for entry: Variant in effects_of_type("escalating_foe_crystal_loss"):
		if not entry is Dictionary:
			continue
		if for_owner < 0 or int((entry as Dictionary).get("owner", 0)) == for_owner:
			return true
	return false


static func try_spend_mutagen_revive(card: GameState.CardInstance, owner: int) -> bool:
	if card == null or not anoint_has_type(card.card_name, "spend_mutagen_revive", owner):
		return false
	if not card.has_mutagen_flag and "mutagen" not in card.flags:
		return false
	if "omen_mutagen_revive_used" in card.flags:
		return false
	card.flags.append("omen_mutagen_revive_used")
	card.has_mutagen_flag = false
	card.flags.erase("mutagen")
	return true


static func tech_returns_to_hand(tech_name: String, owner: int) -> bool:
	if not anoint_has_type(tech_name, "tech_returns_to_hand_once", owner):
		return false
	var key: String = "omen_second_charge_%d_%s" % [owner, tech_name]
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

