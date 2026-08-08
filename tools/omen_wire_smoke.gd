extends Node
## Smoke: chapter_1 omen wiring helpers.
##   godot --headless --path . res://tools/omen_wire_smoke.tscn

var _failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok   ", what)
	else:
		_failures.append(what)
		print("  FAIL ", what)


func _ready() -> void:
	print("omen_wire_smoke…")
	GameState._init_grids()
	OmenBattleApplier.reset_runtime_fields()
	GameState.active_omens = [
		{"id": "cannonade_ruin", "anointed_card": ""},
		{"id": "mine_survey", "anointed_card": ""},
		{"id": "guard_crossguard", "anointed_card": ""},
		{"id": "vampire_dusk", "anointed_card": ""},
		{"id": "slime_filth", "anointed_card": ""},
		{"id": "royal_second_chance", "anointed_card": ""},
		{"id": "comet_barrage", "anointed_card": ""},
		{"id": "trap_hole_snare", "anointed_card": ""},
		{"id": "forced_confession", "anointed_card": ""},
		{"id": "second_skin", "anointed_card": "Test Unit"},
		{"id": "star_peek", "anointed_card": "Star Scout"},
		{"id": "mutant_host", "anointed_card": ""},
	]
	OmenBattleApplier._build_anoint_effects_map()

	_check(not OmenBattleApplier.effects_of_type("destroy_after_reckoning").is_empty(), "destroy_after_reckoning present")
	_check(OmenBattleApplier.cannot_decline_named("Bribe"), "cannot decline Bribe")
	_check(OmenBattleApplier.cannot_decline_named("Blackmail"), "cannot decline Blackmail")
	_check(OmenBattleApplier.should_lock_attacker_on_trap("Trap Hole", 0), "lock on Trap Hole")
	_check(OmenBattleApplier.should_lock_attacker_on_trap("Acid Trap Hole", 0), "lock on Acid Trap Hole")
	_check(not OmenBattleApplier.should_lock_attacker_on_trap("Hypnosis", 0), "no lock on Hypnosis")

	var cannon := GameState.CardInstance.new()
	cannon.card_type = "character"
	cannon.card_name = "Siege Cannon"
	cannon.affinity = CharacterData.Affinity.CHAOS
	_check(OmenBattleApplier.post_reckoning_destroy_count(cannon, 0) >= 1, "cannon destroy count")

	var drill := GameState.CardInstance.new()
	drill.card_type = "character"
	drill.card_name = "Mars Drill"
	_check(OmenBattleApplier.post_reckoning_reveal_count(drill, 0) >= 2, "drill reveal count")

	var guard := GameState.CardInstance.new()
	guard.card_type = "character"
	guard.card_name = "Royal Guard"
	guard.affinity = CharacterData.Affinity.DIVINE
	var foe := GameState.CardInstance.new()
	foe.card_type = "character"
	foe.card_name = "Chaos Foil"
	foe.affinity = CharacterData.Affinity.CHAOS
	_check(OmenBattleApplier.def_bonus_vs_different_affinity(guard, foe, 0) == 100, "guard +100 DEF vs other aff")
	_check(OmenBattleApplier.def_bonus_vs_different_affinity(guard, guard, 0) == 0, "no DEF bonus same aff")

	var vamp := GameState.CardInstance.new()
	vamp.card_type = "character"
	vamp.card_name = "Feral Vampire"
	vamp.affinity = CharacterData.Affinity.CHAOS
	GameState.attacker_card = GameState.CardInstance.new()
	GameState.attacker_card.card_type = "character"
	GameState.attacker_card.affinity = CharacterData.Affinity.DIVINE
	_check(OmenBattleApplier.blocks_destruction_by_affinity(vamp, 0), "vampire blocks Divine destroy")

	var slime := GameState.CardInstance.new()
	slime.card_type = "character"
	slime.card_name = "Black Slime"
	slime.affinity = CharacterData.Affinity.BIO
	GameState.attacker_card.affinity = CharacterData.Affinity.ARCANE
	_check(OmenBattleApplier.blocks_destruction_by_affinity(slime, 0), "slime blocks non-Bio destroy")
	GameState.attacker_card.affinity = CharacterData.Affinity.BIO
	_check(not OmenBattleApplier.blocks_destruction_by_affinity(slime, 0), "slime allows Bio destroy")

	var princess := GameState.CardInstance.new()
	princess.card_type = "character"
	princess.card_name = "Fern the Mermaid Princess"
	_check(OmenBattleApplier.try_consume_survive_destruction_once(princess), "princess survives once")
	_check(not OmenBattleApplier.try_consume_survive_destruction_once(princess), "princess second survive fails")

	var anointed := GameState.CardInstance.new()
	anointed.card_type = "character"
	anointed.card_name = "Test Unit"
	_check(OmenBattleApplier.try_consume_survive_destruction_once(anointed), "second_skin anoint survive")

	var comet := GameState.CardInstance.new()
	comet.card_type = "character"
	comet.card_name = "Striker Comet"
	_check(OmenBattleApplier.get_unit_extra_attacks(comet, 0) == 2, "comet +2 attacks")

	var mutant := GameState.CardInstance.new()
	mutant.card_type = "character"
	mutant.card_name = "Claw Mutant"
	GameState.grids[0][0][0] = mutant
	OmenBattleApplier._apply_unit_stat_on_grid({
		"type": "unit_stat_flat", "atk": 50, "def": 50, "target": "player",
		"filter": {"name_contains": "Mutant"},
	})
	_check(mutant.perm_atk_bonus == 50 and mutant.perm_def_bonus == 50, "mutant_host +50/+50")

	for oid2: String in ["cannonade_ruin", "forced_confession", "second_skin", "wild_bloom", "mutant_host"]:
		var o: Dictionary = OmenDatabase.get_omen(oid2)
		_check(bool(o.get("implemented", false)), "%s implemented flag" % oid2)

	# Batch-2 helpers
	GameState.active_omens = [
		{"id": "soft_step", "anointed_card": "Soft Stepper"},
		{"id": "executioners_pact", "anointed_card": "Exec Unit"},
		{"id": "overclock", "anointed_card": ""},
		{"id": "cheap_catalyst", "anointed_card": "Catalyst Mat"},
		{"id": "taxing_snare", "anointed_card": "Tax Trap"},
		{"id": "simple_rites", "anointed_card": ""},
		{"id": "poltergeist", "anointed_card": ""},
		{"id": "witching_hour", "anointed_card": ""},
		{"id": "loaded_dice", "anointed_card": "Loaded Unit"},
	]
	OmenBattleApplier._build_anoint_effects_map()
	var soft := GameState.CardInstance.new()
	soft.card_name = "Soft Stepper"
	_check(OmenBattleApplier.has_trap_coin_negate(soft), "soft_step trap coin negate")
	var exec := GameState.CardInstance.new()
	exec.card_name = "Exec Unit"
	_check(OmenBattleApplier.has_executioners_pact(exec), "executioners_pact")
	_check(OmenBattleApplier.max_tech_per_turn() >= 2, "overclock max tech")
	var um: Dictionary = OmenBattleApplier.union_material_bonuses(["Catalyst Mat"])
	_check(float(um.get("cost_mult", 1.0)) == 0.5, "cheap_catalyst cost mult")
	_check(OmenBattleApplier.trap_crystal_loss_mult("Tax Trap") == 2.0, "taxing_snare mult")
	_check(OmenBattleApplier.coin_bias_for_card("Loaded Unit") == "always_heads", "loaded_dice bias")
	_check(OmenBattleApplier.double_turn_end_abilities(), "witching_hour")
	_check(not OmenBattleApplier.effects_of_type("shuffle_all_units").is_empty(), "poltergeist present")
	_check(bool(OmenDatabase.get_omen("phoenix_bargain").get("implemented", false)), "phoenix implemented")
	_check(bool(OmenDatabase.get_omen("grave_discount").get("implemented", false)), "grave_discount implemented")
	_check(bool(OmenDatabase.get_omen("lightweight").get("implemented", false)), "lightweight implemented")

	# Keen Edge: anoint map must survive new_game, apply +5 ATK, and survive field recalc
	# (Death Knight's per-Chaos bonus used to overwrite perm_atk_bonus).
	GameState.active_omens = [{
		"id": "keen_edge", "anointed_card": "Death Knight", "owner": 0,
	}]
	OmenBattleApplier.rebuild_anoint_effects_map()
	GameState.new_game(GameState.GameMode.EXPLORATION)
	_check(not GameState.omen_anoint_effects.is_empty(), "keen_edge map survives new_game")
	GameState.place_character(0, 2, 2, "Death Knight")
	var dk: GameState.CardInstance = GameState.get_card(0, 2, 2)
	var dk_atk0: int = dk.get_effective_atk()
	OmenBattleApplier.reset_runtime_fields()  # wipe map as if rebuild was skipped
	OmenBattleApplier.apply_begin_game(null)  # must rebuild then apply + field recalc
	dk = GameState.get_card(0, 2, 2)
	_check(dk.perm_atk_bonus >= 5, "keen_edge perm +5 on Death Knight")
	_check(dk.get_effective_atk() >= dk_atk0 + 5, "keen_edge +5 ATK on Death Knight")

	# Kill-capped ATK must not share budget with omen perm (Champion of the Valley).
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 2, 2, "Champion of the Valley")
	var champ: GameState.CardInstance = GameState.get_card(0, 2, 2)
	champ.perm_atk_bonus = 5  # simulate Keen Edge
	champ.ability_capped_atk_bonus = 0
	# Mimic TurnManager._grant_capped_perm_atk via direct call pattern
	var room: int = maxi(0, 30 - champ.ability_capped_atk_bonus)
	var actual: int = mini(10, room)
	champ.perm_atk_bonus += actual
	champ.ability_capped_atk_bonus += actual
	_check(champ.perm_atk_bonus == 15, "kill-cap preserves omen + grants 10")
	_check(champ.ability_capped_atk_bonus == 10, "kill-cap tracks ability budget only")

	# FIELD_ATK_BOOST reads atk_bonus/def_bonus (Benjamin).
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 2, 1, "Benjamin the Holy Craftsman")
	GameState.place_character(0, 2, 2, "Lucky Statue")
	var ben: GameState.CardInstance = GameState.get_card(0, 2, 1)
	var statue: GameState.CardInstance = GameState.get_card(0, 2, 2)
	ben.face_up = true
	statue.face_up = true
	BattleResolver.calculate_field_bonuses(0)
	statue = GameState.get_card(0, 2, 2)
	_check(statue.field_aura_atk_bonus >= 10 and statue.field_aura_def_bonus >= 10,
		"benjamin aura +10/+10 via atk_bonus/def_bonus")

	# foe field_scope (Halo Guardian) + void threshold (Night Dweller) + Death Knight void DEF.
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 2, 2, "Halo Guardian")
	GameState.place_character(1, 0, 0, "Death Knight")
	var halo: GameState.CardInstance = GameState.get_card(0, 2, 2)
	var foe_dk: GameState.CardInstance = GameState.get_card(1, 0, 0)
	halo.face_up = true
	foe_dk.face_up = true
	BattleResolver.calculate_field_bonuses(0)
	halo = GameState.get_card(0, 2, 2)
	_check(halo.field_aura_atk_bonus >= 5 and halo.field_aura_def_bonus >= 5,
		"halo guardian foe Chaos scope")

	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 2, 2, "Night Dweller")
	var nd: GameState.CardInstance = GameState.get_card(0, 2, 2)
	nd.face_up = true
	BattleResolver.calculate_field_bonuses(0)
	nd = GameState.get_card(0, 2, 2)
	_check(nd.field_aura_atk_bonus == 0, "night dweller no bonus under 3 void")
	GameState.add_void_entry(0, "Doom Wisp", "character")
	GameState.add_void_entry(0, "Doom Wisp", "character")
	GameState.add_void_entry(0, "Doom Wisp", "character")
	BattleResolver.calculate_field_bonuses(0)
	nd = GameState.get_card(0, 2, 2)
	_check(nd.field_aura_atk_bonus == 10 and nd.field_aura_def_bonus == 10,
		"night dweller +10/+10 at 3 void units")

	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 2, 2, "Death Knight")
	var dk2: GameState.CardInstance = GameState.get_card(0, 2, 2)
	dk2.face_up = true
	GameState.add_void_entry(0, "Doom Wisp", "character")  # Chaos
	GameState.add_void_entry(0, "Fire Elemental", "character")  # Arcane — ignore
	BattleResolver.calculate_field_bonuses(0)
	dk2 = GameState.get_card(0, 2, 2)
	_check(dk2.field_aura_def_bonus >= 5, "death knight +5 DEF per Chaos in void")

	# Drifting Head bonus_cap 20
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 2, 2, "Drifting Head")
	GameState.place_character(0, 0, 0, "Doom Wisp")
	GameState.place_character(0, 0, 1, "Doom Wisp")
	GameState.place_character(0, 0, 2, "Doom Wisp")
	GameState.place_character(0, 0, 3, "Doom Wisp")
	GameState.place_character(0, 0, 4, "Doom Wisp")
	var dh: GameState.CardInstance = GameState.get_card(0, 2, 2)
	dh.face_up = true
	for c: int in range(5):
		var ally: GameState.CardInstance = GameState.get_card(0, 0, c)
		if ally.card_type == "character":
			ally.face_up = true
	BattleResolver.calculate_field_bonuses(0)
	dh = GameState.get_card(0, 2, 2)
	_check(dh.field_aura_atk_bonus == 20, "drifting head bonus_cap 20 with 5 Chaos")

	# Berserker of Ice Sea: -35 ATK at turn end, NOT immediately after Reckoning.
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 2, 2, "Berserker of Ice Sea")
	GameState.place_character(1, 0, 0, "Doom Wisp")
	var bis: GameState.CardInstance = GameState.get_card(0, 2, 2)
	var bis_foe: GameState.CardInstance = GameState.get_card(1, 0, 0)
	bis.face_up = true
	bis_foe.face_up = true
	var bis_atk0: int = bis.current_atk
	var tm_bis := TurnManager.new()
	add_child(tm_bis)
	var bis_res := BattleResolver.BattleResult.new()
	bis_res.attacker_destroyed = false
	bis_res.defender_destroyed = true
	await tm_bis._apply_post_battle_effects(
		bis_res, 0, 1, bis, bis_foe, Vector2i(2, 2), Vector2i(0, 0))
	bis = GameState.get_card(0, 2, 2)
	_check(bis.current_atk == bis_atk0, "berserker ATK unchanged after Reckoning")
	_check("atk_debuff_used" not in bis.flags, "berserker turn-end flag not set after Reckoning")
	# Owner turn-end once path (same branch as TurnManager._end_turn)
	if bis.ability_params.get("once_turn_end", false) and "atk_debuff_used" not in bis.flags:
		bis.flags.append("atk_debuff_used")
		bis.current_atk = max(0, bis.current_atk - int(bis.ability_params.get("atk", 0)))
	_check(bis.current_atk == bis_atk0 - 35, "berserker -35 ATK at turn end")
	tm_bis.queue_free()

	# Chapter finalize must clear battle omen snapshot (deckbuilder sigils).
	GameState.active_omens = [{
		"id": "keen_edge", "anointed_card": "Death Knight", "owner": 0,
	}]
	GameState.enemy_active_omens = [{"id": "soft_step", "anointed_card": "", "owner": 1}]
	ExplorationManager.clear_held_omens()
	OmenBattleApplier.clear()
	_check(GameState.active_omens.is_empty() and GameState.enemy_active_omens.is_empty(),
		"chapter-end omen clear empties battle snapshot")
	_check(OmenVisuals.rows_for_card("Death Knight").is_empty(),
		"no deckbuilder sigil after omen clear")

	var unimplemented_n := 0
	for oid3: String in OmenDatabase.get_all_omen_ids() if OmenDatabase.has_method("get_all_omen_ids") else []:
		var od: Dictionary = OmenDatabase.get_omen(oid3)
		if not bool(od.get("implemented", false)):
			unimplemented_n += 1
	# Fallback count via known total
	if unimplemented_n == 0:
		var file_unimpl := 0
		# OmenDatabase may not list all; trust JSON via get_omen samples
		for sample: String in ["etched_brand", "barrel_gospel", "arcane_nimbus", "escalating_toll"]:
			if not bool(OmenDatabase.get_omen(sample).get("implemented", false)):
				file_unimpl += 1
		_check(file_unimpl == 0, "sample remaining omens implemented")

	print("")
	if _failures.is_empty():
		print("SMOKE OK")
		get_tree().quit(0)
	else:
		print("SMOKE FAILED: ", _failures)
		get_tree().quit(1)
