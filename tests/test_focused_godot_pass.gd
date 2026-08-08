extends Node
# Focused Godot pass for residual audit cases (§9 / §10).
# Usage: godot --headless --path . res://tests/run_focused_godot_pass.tscn

signal finished(passed_count: int, failed_count: int)

var passed: int = 0
var failed: int = 0
var done: bool = false


func _ready() -> void:
	while not UnionDatabase.is_bootstrapped():
		await get_tree().process_frame
	print("\n=== Focused Godot Pass ===\n")
	_case_defensive_pheromone()
	_case_bunker_hostage_ai()
	await _case_bone_dragon_turn_end()
	_case_multi_owner_anoint()
	_case_enemy_omen_symmetry()
	_case_union_final_cost_stacked()
	print("\n=== Focused Godot Pass: %d passed, %d failed ===\n" % [passed, failed])
	if failed > 0:
		push_error("Focused Godot pass had failures")
	done = true
	finished.emit(passed, failed)


func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s" % msg)


func assert_false(condition: bool, msg: String) -> void:
	assert_true(not condition, msg)


func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s (expected %s, got %s)" % [msg, str(b), str(a)])


func _make_char(
		name: String, atk: int, defv: int, cost: int, affinity: int
) -> GameState.CardInstance:
	var card := GameState.CardInstance.new()
	card.card_type = "character"
	card.card_name = name
	card.display_name = name
	card.affinity = affinity
	card.base_atk = atk
	card.base_def = defv
	card.current_atk = atk
	card.current_def = defv
	card.crystal_cost = cost
	card.face_up = true
	return card


func _case_defensive_pheromone() -> void:
	print("-- Defensive Pheromone repeat Reckoning")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	var armored := _make_char(
		"Armored Test", 40, 50, 500, CharacterData.Affinity.NATURE)
	armored.face_up = false
	GameState.set_card(1, 1, 1, armored)
	var tm := TurnManager.new()
	add_child(tm)
	tm._pending_pheromone_owner = 1
	tm._pending_pheromone_target_pos = Vector2i(2, 2)
	assert_true(tm.resolve_defensive_pheromone_swap(1, Vector2i(1, 1)),
		"Pheromone: swap accepts own Armored Nature unit")
	assert_true(GameState.get_card(1, 2, 2) == armored,
		"Pheromone: unit lands in trap cell")
	assert_eq(GameState.get_card(1, 1, 1).card_type, "dead_end",
		"Pheromone: source cell becomes Dead End")
	assert_true(tm._pending_pheromone_swap_done,
		"Pheromone: queues repeat Reckoning via swap_done flag")
	tm.queue_free()


func _case_bunker_hostage_ai() -> void:
	print("-- Bunker/Hostage AI retarget")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.set_card(0, 0, 0, _make_char(
		"Retargeter", 50, 50, 700, CharacterData.Affinity.ANIMA))
	GameState.set_card(1, 4, 4, _make_char(
		"Only Target", 10, 10, 100, CharacterData.Affinity.ANIMA))
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			if Vector2i(r, c) != Vector2i(4, 4):
				GameState.locked_attack_positions.append(Vector2i(r, c))
	var ai := AIPlayer.new()
	ai.init_as(0)
	add_child(ai)
	assert_eq(ai.choose_retarget_for(Vector2i(0, 0)), Vector2i(4, 4),
		"Bunker/Hostage AI: retargets with same attacker to only legal cell")
	ai.queue_free()


func _case_bone_dragon_turn_end() -> void:
	print("-- Bone Dragon foe-turn-end coin revive")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 0, 0, "Bone Dragon")
	GameState.place_character(0, 0, 1, "Dark Monk")
	GameState.place_character(1, 1, 1, "Canyon Warg")
	var union_destroyer: GameState.CardInstance = GameState.get_card(1, 1, 1)
	union_destroyer.is_union = true
	GameState.attacker_card = union_destroyer
	GameState.destroy_card(0, 0, 0, false)
	assert_eq(GameState.foe_turn_end_revives.size(), 1,
		"Bone Dragon: queues foe-turn-end revival after Union destroy")
	assert_eq(GameState.turn_start_revives.size(), 0,
		"Bone Dragon: does not queue owner-turn-start revival")

	# Exercise TurnManager revive path with Heads already decided (skip UI coin).
	var entry: Dictionary = GameState.foe_turn_end_revives[0]
	entry["coin_passed"] = true
	GameState.foe_turn_end_revives[0] = entry
	var tm := TurnManager.new()
	add_child(tm)
	# Ending player must be the foe of the Bone Dragon owner (P0) → P1.
	await tm._process_foe_turn_end_revives(1)
	assert_eq(GameState.get_card(0, 0, 0).card_name, "Bone Dragon",
		"Bone Dragon: TurnManager Heads path restores into original cell")
	assert_eq(GameState.foe_turn_end_revives.size(), 0,
		"Bone Dragon: revive queue cleared after successful revive")
	tm.queue_free()


func _case_multi_owner_anoint() -> void:
	print("-- Multi-owner anoint (duplicate card names)")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 0, 0, "Ox Patrol")
	GameState.place_character(1, 0, 0, "Ox Patrol")
	GameState.active_omens = [{
		"id": "etched_brand",
		"anointed_card": "Ox Patrol",
		"owner": 0,
	}]
	GameState.enemy_active_omens = [{
		"id": "substitute_seal",
		"anointed_card": "Ox Patrol",
		"owner": 1,
	}]
	OmenBattleApplier.rebuild_anoint_effects_map()

	assert_true(
		OmenBattleApplier.anoint_has_type("Ox Patrol", "stat_duration", 0),
		"Anoint: P0 Ox Patrol has Etched Brand stat_duration")
	assert_false(
		OmenBattleApplier.anoint_has_type("Ox Patrol", "stat_duration", 1),
		"Anoint: P1 Ox Patrol does NOT inherit P0 Etched Brand")
	assert_true(
		OmenBattleApplier.union_material_wildcard_for("Ox Patrol", 1),
		"Anoint: P1 Ox Patrol has Substitute Seal wildcard")
	assert_false(
		OmenBattleApplier.union_material_wildcard_for("Ox Patrol", 0),
		"Anoint: P0 Ox Patrol does NOT inherit P1 Substitute Seal")

	# Etched Brand routed path: Tech/Trap-sourced deltas become permanent for P0 source only.
	var target := _make_char("Target", 10, 10, 100, CharacterData.Affinity.ANIMA)
	OmenBattleApplier.apply_stat_change_from_source(target, 5, 7, "Ox Patrol", 0)
	assert_eq(target.perm_atk_bonus, 5,
		"Etched Brand: P0-anointed source writes permanent ATK")
	assert_eq(target.perm_def_bonus, 7,
		"Etched Brand: P0-anointed source writes permanent DEF")
	assert_eq(target.temp_atk_bonus, 0,
		"Etched Brand: permanent mode does not also write temp ATK")

	var target2 := _make_char("Target2", 10, 10, 100, CharacterData.Affinity.ANIMA)
	OmenBattleApplier.apply_stat_change_from_source(target2, 5, 7, "Ox Patrol", 1)
	assert_eq(target2.perm_atk_bonus, 0,
		"Etched Brand: P1 same-name source without anoint stays temporary (no perm)")
	assert_eq(target2.temp_atk_bonus, 5,
		"Etched Brand: P1 same-name source writes temp ATK")


func _case_enemy_omen_symmetry() -> void:
	print("-- Enemy-held global Omen symmetry")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.crystals[0] = 1000
	GameState.crystals[1] = 1000
	GameState.active_omens.clear()
	GameState.enemy_active_omens = [{
		"id": "quiet_funeral_lock",
		"anointed_card": "",
		"owner": 1,
	}]
	assert_true(OmenBattleApplier.cannot_gain_crystals_for(1),
		"Enemy omen: quiet_funeral_lock blocks P1 crystal gain")
	assert_false(OmenBattleApplier.cannot_gain_crystals_for(0),
		"Enemy omen: quiet_funeral_lock does not block P0 crystal gain")
	GameState.gain_crystals(1, 200, "test")
	assert_eq(GameState.crystals[1], 1000,
		"Enemy omen: P1 gain_crystals is a no-op under lock")
	GameState.gain_crystals(0, 200, "test")
	assert_eq(GameState.crystals[0], 1200,
		"Enemy omen: P0 still gains crystals while P1 is locked")

	# Null Aegis on enemy holder + 0-cost trap immune unit → tech immunity for P1 only.
	GameState.enemy_active_omens = [{
		"id": "null_aegis",
		"anointed_card": "",
		"owner": 1,
	}]
	GameState.place_character(1, 2, 2, "Huntress of Green Glade")
	GameState.place_character(0, 2, 2, "Huntress of Green Glade")
	var p1_hunt: GameState.CardInstance = GameState.get_card(1, 2, 2)
	var p0_hunt: GameState.CardInstance = GameState.get_card(0, 2, 2)
	assert_true(GameState.is_immune_to_tech_cards(p1_hunt, 1),
		"Enemy omen: Null Aegis grants P1 Huntress full trap/tech immunity")
	assert_false(GameState.is_immune_to_tech_cards(p0_hunt, 0),
		"Enemy omen: Null Aegis does not grant P0 Huntress the extension")

	# Golden Reckoning held by enemy: Cosmic win match is owner-aware for P1.
	GameState.enemy_active_omens = [{
		"id": "golden_reckoning",
		"anointed_card": "",
		"owner": 1,
	}]
	GameState.active_omens.clear()
	var entries: Array = OmenBattleApplier.effects_of_type("crystal_on_reckoning_win")
	assert_eq(entries.size(), 1,
		"Enemy omen: golden_reckoning is visible in effects_of_type")
	assert_eq(int((entries[0] as Dictionary).get("owner", -1)), 1,
		"Enemy omen: golden_reckoning owner is P1")
	var cosmic := _make_char(
		"Cosmic Probe", 40, 40, 500, CharacterData.Affinity.COSMIC)
	var anima := _make_char(
		"Anima Probe", 40, 40, 500, CharacterData.Affinity.ANIMA)
	assert_true(
		OmenBattleApplier._card_matches_effect_unit(
			cosmic, entries[0] as Dictionary, 1),
		"Enemy omen: P1 Cosmic attacker matches Golden Reckoning")
	assert_false(
		OmenBattleApplier._card_matches_effect_unit(
			cosmic, entries[0] as Dictionary, 0),
		"Enemy omen: P0 Cosmic attacker does not match enemy Golden Reckoning")
	assert_false(
		OmenBattleApplier._card_matches_effect_unit(
			anima, entries[0] as Dictionary, 1),
		"Enemy omen: P1 non-Cosmic attacker does not match Golden Reckoning")


func _case_union_final_cost_stacked() -> void:
	print("-- Union final cost under stacked omens")
	GameState.new_game(GameState.GameMode.DAILY_DUNGEON)
	GameState.active_omens = [{"id": "test", "owner": 0}]
	GameState.active_dungeon_modifiers = ["risk_and_reward", "reunion"]
	GameState.omen_anoint_effects.clear()
	GameState.omen_anoint_effects["0::Wrong Material"] = [{
		"type": "union_material_cost_multiplier",
		"value": 1.5,
		"omen_owner": 0,
	}]
	# 1000 * 1.5 material anoint = 1500; *1.25 Risk&Reward = 1875
	assert_eq(GameState.final_union_summon_cost(
		1000, 0, ["Wrong Material"]), 1875,
		"Union cost: material anoint + Risk&Reward produce one final cost 1875")

	# Enemy material anoint must not affect P0 cost.
	GameState.omen_anoint_effects["1::Wrong Material"] = [{
		"type": "union_material_cost_multiplier",
		"value": 2.0,
		"omen_owner": 1,
	}]
	assert_eq(GameState.final_union_summon_cost(
		1000, 0, ["Wrong Material"]), 1875,
		"Union cost: enemy material anoint does not change P0 final cost")
	# 1000 * 2.0 enemy material anoint * 1.25 Risk&Reward = 2500
	assert_eq(GameState.final_union_summon_cost(
		1000, 1, ["Wrong Material"]), 2500,
		"Union cost: P1 sees own material anoint + Risk&Reward (1000*2.0*1.25=2500)")
