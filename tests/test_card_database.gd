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
	test_characters_loaded()
	test_traps_loaded()
	test_tech_loaded()
	test_angel_gatekeeper_stats()
	test_pit_lord_stats()
	test_zero_cost_traps_exist()
	test_chain_tech_requirements()
	test_all_characters_have_valid_affinity()
	test_all_tech_have_descriptions()

func test_characters_loaded() -> void:
	print("-- test_characters_loaded")
	assert_true(CardDatabase.characters.size() > 0, "Characters dict not empty")
	assert_true(CardDatabase.characters.size() >= 20, "At least 20 characters defined")

func test_traps_loaded() -> void:
	print("-- test_traps_loaded")
	assert_true(CardDatabase.traps.size() >= 10, "At least 10 traps defined")

func test_tech_loaded() -> void:
	print("-- test_tech_loaded")
	assert_true(CardDatabase.tech_cards.size() >= 20, "At least 20 tech cards defined")

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
		assert_eq(data.ability_params.get("bonus", 0), 60, "Angel Gatekeeper bonus = 60")

func test_pit_lord_stats() -> void:
	print("-- test_pit_lord_stats")
	var data: CharacterData = CardDatabase.get_character("Pit Lord")
	assert_not_null(data, "Pit Lord exists")
	if data:
		assert_eq(data.base_atk, 120, "Pit Lord ATK = 120")
		assert_eq(data.base_def, 100, "Pit Lord DEF = 100")
		assert_eq(data.affinity, CharacterData.Affinity.CHAOS, "Pit Lord affinity = Chaos")

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
