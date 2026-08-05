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
