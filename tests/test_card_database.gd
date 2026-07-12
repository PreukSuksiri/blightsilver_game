extends Node
# Unit tests for CardDatabase autoload.

var passed: int = 0
var failed: int = 0

func _ready() -> void:
	run_all_tests()
	print("=== CardDatabase Tests: %d passed, %d failed ===" % [passed, failed])

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s" % msg)

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		passed += 1
		print("  PASS: %s" % [msg])
	else:
		failed += 1
		printerr("  FAIL: %s (expected %s, got %s)" % [msg, str(b), str(a)])

func assert_not_null(val, msg: String) -> void:
	if val != null:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s — was null" % msg)

func run_all_tests() -> void:
	CardDatabase.bootstrap()
	test_characters_loaded()
	test_traps_loaded()
	test_tech_loaded()
	test_angel_gatekeeper_stats()
	test_pit_lord_stats()
	test_zero_cost_traps_exist()
	test_chain_tech_requirements()
	test_all_characters_have_valid_affinity()
	test_all_tech_have_descriptions()
	test_no_not_implemented_stubs()
	test_exact_card_counts()
	test_rename_cleanup()

func test_no_not_implemented_stubs() -> void:
	print("-- test_no_not_implemented_stubs")
	UnionDatabase.bootstrap()
	var ni_chars := 0
	var ni_traps := 0
	var ni_tech := 0
	for cname in CardDatabase.characters:
		var c: CharacterData = CardDatabase.characters[cname]
		if c.ability_type == CharacterData.AbilityType.NOT_IMPLEMENTED:
			ni_chars += 1
	for tname in CardDatabase.traps:
		var t: TrapData = CardDatabase.traps[tname]
		if t.effect_type == TrapData.TrapEffectType.NOT_IMPLEMENTED:
			ni_traps += 1
	for tname in CardDatabase.tech_cards:
		var t: TechCardData = CardDatabase.tech_cards[tname]
		if t.effect_type == TechCardData.TechEffectType.NOT_IMPLEMENTED:
			ni_tech += 1
	var ni_unions := 0
	for u: UnionData in UnionDatabase.get_all_unions():
		if u != null and u.ability_type == CharacterData.AbilityType.NOT_IMPLEMENTED:
			ni_unions += 1
	assert_eq(ni_chars, 0, "No character NOT_IMPLEMENTED stubs")
	assert_eq(ni_traps, 0, "No trap NOT_IMPLEMENTED stubs")
	assert_eq(ni_tech, 0, "No tech NOT_IMPLEMENTED stubs")
	assert_eq(ni_unions, 0, "No union NOT_IMPLEMENTED stubs")

func test_exact_card_counts() -> void:
	print("-- test_exact_card_counts")
	assert_eq(CardDatabase.characters.size(), 508, "508 characters")
	assert_eq(CardDatabase.traps.size(), 73, "73 traps")
	assert_eq(CardDatabase.tech_cards.size(), 127, "127 tech cards")
	UnionDatabase.bootstrap()
	assert_eq(UnionDatabase.get_all_unions().size(), 132, "132 unions")

func test_rename_cleanup() -> void:
	print("-- test_rename_cleanup")
	assert_not_null(CardDatabase.get_character("Spider Lady"), "Spider Lady exists")
	assert_eq(CardDatabase.get_character("Spider Woman"), null, "Spider Woman removed")
	assert_eq(CardDatabase.get_trap("Bounty"), null, "Bounty trap removed")
	assert_not_null(CardDatabase.get_trap("Rank C Bounty"), "Rank C Bounty exists")
	assert_not_null(CardDatabase.get_trap("Rank S Bounty"), "Rank S Bounty exists")
	var death_stag: CharacterData = CardDatabase.get_character("Death Stag")
	if death_stag:
		assert_eq(death_stag.ability_type, CharacterData.AbilityType.NONE, "Death Stag NONE")
	var asteroid: CharacterData = CardDatabase.get_character("Asteroid Trooper")
	if asteroid:
		assert_eq(asteroid.ability_type, CharacterData.AbilityType.NONE, "Asteroid Trooper NONE")

func test_characters_loaded() -> void:
	print("-- test_characters_loaded")
	assert_true(CardDatabase.characters.size() > 0, "Characters dict not empty")
	assert_true(CardDatabase.characters.size() >= 450, "At least 450 characters defined")

func test_traps_loaded() -> void:
	print("-- test_traps_loaded")
	assert_true(CardDatabase.traps.size() >= 55, "At least 55 traps defined")

func test_tech_loaded() -> void:
	print("-- test_tech_loaded")
	assert_true(CardDatabase.tech_cards.size() >= 100, "At least 100 tech cards defined")

func test_angel_gatekeeper_stats() -> void:
	print("-- test_angel_gatekeeper_stats")
	var data: CharacterData = CardDatabase.get_character("Angel Gatekeeper")
	assert_not_null(data, "Angel Gatekeeper exists")
	if data:
		assert_eq(data.base_atk, 40, "Angel Gatekeeper ATK = 40")
		assert_eq(data.base_def, 90, "Angel Gatekeeper DEF = 90")
		assert_eq(data.crystal_cost, 1000, "Angel Gatekeeper cost = 1000")
		assert_eq(data.affinity, CharacterData.Affinity.DIVINE, "Angel Gatekeeper affinity = Divine")
		assert_eq(data.ability_type, CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY, "Angel Gatekeeper ability correct")
		assert_eq(data.ability_params.get("bonus", 0), 50, "Angel Gatekeeper bonus = 50")

func test_pit_lord_stats() -> void:
	print("-- test_pit_lord_stats")
	var data: CharacterData = CardDatabase.get_character("Pit Lord")
	assert_not_null(data, "Pit Lord exists")
	if data:
		assert_eq(data.base_atk, 120, "Pit Lord ATK = 120")
		assert_eq(data.base_def, 100, "Pit Lord DEF = 100")
		assert_eq(data.affinity, CharacterData.Affinity.CHAOS, "Pit Lord affinity = Chaos")
		assert_true(data.ability_params.get("also_halve_after_attack", false),
			"Pit Lord also_halve_after_attack param set")

func test_zero_cost_traps_exist() -> void:
	print("-- test_zero_cost_traps_exist")
	var zero_cost_traps: Array = []
	for trap_name in CardDatabase.traps:
		var t: TrapData = CardDatabase.traps[trap_name]
		if t.crystal_cost == 0:
			zero_cost_traps.append(trap_name)
	assert_true(zero_cost_traps.size() >= 5, "At least 5 zero-cost traps exist")
	print("  Zero-cost traps: %s" % str(zero_cost_traps))

func test_chain_tech_requirements() -> void:
	print("-- test_chain_tech_requirements")
	var double_spy: TechCardData = CardDatabase.get_tech("Double Spy")
	assert_not_null(double_spy, "Double Spy exists")
	if double_spy:
		assert_eq(double_spy.required_prior_card, "Spy", "Double Spy requires Spy")

	var invis_spy: TechCardData = CardDatabase.get_tech("Invisible Spy")
	assert_not_null(invis_spy, "Invisible Spy exists")
	if invis_spy:
		assert_eq(invis_spy.required_prior_card, "Double Spy", "Invisible Spy requires Double Spy")

func test_all_characters_have_valid_affinity() -> void:
	print("-- test_all_characters_have_valid_affinity")
	var valid_affinities := CharacterData.Affinity.values()
	var all_valid := true
	for char_name in CardDatabase.characters:
		var data: CharacterData = CardDatabase.characters[char_name]
		if not data.affinity in valid_affinities:
			printerr("  Invalid affinity for: %s" % char_name)
			all_valid = false
	assert_true(all_valid, "All characters have valid affinities")

func test_all_tech_have_descriptions() -> void:
	print("-- test_all_tech_have_descriptions")
	var all_ok := true
	for tech_name in CardDatabase.tech_cards:
		var data: TechCardData = CardDatabase.tech_cards[tech_name]
		if data.effect_description == "":
			printerr("  Missing description for tech: %s" % tech_name)
			all_ok = false
	assert_true(all_ok, "All tech cards have descriptions")
