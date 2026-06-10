extends Node
# Unit tests for BattleResolver.
# Run via: Project > Tools > GDUnit or manually attach to a test scene.

var passed: int = 0
var failed: int = 0

func _ready() -> void:
	run_all_tests()
	print("=== BattleResolver Tests: %d passed, %d failed ===" % [passed, failed])

func run_all_tests() -> void:
	test_atk_beats_def()
	test_def_beats_atk()
	test_equal_both_destroyed()
	test_vs_blank_nothing_happens()
	test_trap_nullified_immune()
	test_affinity_bonus_applied()
	test_defend_crystal_gain()
	test_defend_drain_attacker()
	test_armored_bee_preview_silent()
	test_reckoning_overlay_log_lines()
	test_reckoning_pills_copied_from_preview()

func _make_char(name: String, atk: int, def_val: int, cost: int,
		affinity: int = CharacterData.Affinity.ANIMA,
		ability: int = CharacterData.AbilityType.NONE,
		params: Dictionary = {}) -> GameState.CardInstance:
	var c := GameState.CardInstance.new()
	c.card_type = "character"
	c.card_name = name
	c.face_up = true
	c.current_atk = atk
	c.current_def = def_val
	c.base_atk = atk
	c.base_def = def_val
	c.crystal_cost = cost
	c.affinity = affinity
	c.ability_type = ability
	c.ability_params = params
	return c

func _make_dead_end() -> GameState.CardInstance:
	var c := GameState.CardInstance.new()
	c.card_type = "dead_end"
	return c

func _make_trap(name: String, cost: int) -> GameState.CardInstance:
	var c := GameState.CardInstance.new()
	c.card_type = "trap"
	c.card_name = name
	c.face_up = true
	c.crystal_cost = cost
	return c

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
		print("  PASS: %s (%s == %s)" % [msg, str(a), str(b)])
	else:
		failed += 1
		printerr("  FAIL: %s (expected %s, got %s)" % [msg, str(b), str(a)])

# ─────────────────────────────────────────────────────────────
func test_atk_beats_def() -> void:
	print("-- test_atk_beats_def")
	var attacker := _make_char("A", 80, 0, 500)
	var defender := _make_char("D", 0, 60, 400)
	var result := BattleResolver.resolve_battle(attacker, defender, 3, 0, 1)
	assert_true(result.defender_destroyed, "Defender should be destroyed (ATK 80 > DEF 60)")
	assert_true(not result.attacker_destroyed, "Attacker should survive")
	assert_eq(result.defender_crystal_loss, 400, "Defender loses crystal cost")
	assert_eq(result.attacker_crystal_loss, 0, "Attacker loses nothing")

func test_def_beats_atk() -> void:
	print("-- test_def_beats_atk")
	var attacker := _make_char("A", 40, 0, 500)
	var defender := _make_char("D", 0, 90, 800)
	var result := BattleResolver.resolve_battle(attacker, defender, 2, 0, 1)
	assert_true(not result.defender_destroyed, "Defender survives (DEF 90 > ATK 40)")
	assert_true(result.attacker_destroyed, "Attacker destroyed")
	assert_eq(result.attacker_crystal_loss, 500, "Attacker loses crystal cost")

func test_equal_both_destroyed() -> void:
	print("-- test_equal_both_destroyed")
	var attacker := _make_char("A", 60, 60, 600)
	var defender := _make_char("D", 60, 60, 600)
	var result := BattleResolver.resolve_battle(attacker, defender, 3, 0, 1)
	assert_true(result.attacker_destroyed, "Attacker destroyed on tie")
	assert_true(result.defender_destroyed, "Defender destroyed on tie")
	assert_eq(result.attacker_crystal_loss, 600, "Attacker pays own cost")
	assert_eq(result.defender_crystal_loss, 600, "Defender pays own cost")

func test_vs_blank_nothing_happens() -> void:
	print("-- test_vs_dead_end_nothing_happens")
	var attacker := _make_char("A", 80, 0, 500)
	var blank := _make_dead_end()
	var result := BattleResolver.resolve_battle(attacker, blank, 3, 0, 1)
	assert_true(not result.attacker_destroyed, "Attacker not destroyed vs dead end")
	assert_true(not result.defender_destroyed, "No defender vs blank")
	assert_eq(result.attacker_crystal_loss, 0, "No crystal loss vs blank")

func test_trap_nullified_immune() -> void:
	print("-- test_trap_nullified_immune (Immune to 0-cost traps)")
	var attacker := _make_char("Huntress", 50, 50, 800,
		CharacterData.Affinity.ANIMA,
		CharacterData.AbilityType.IMMUNE_ZERO_COST_TRAPS)
	var trap := _make_trap("Trap Hole", 0)
	var result := BattleResolver.resolve_battle(attacker, trap, 3, 0, 1)
	assert_eq(result.special_trigger, "trap_nullified", "0-cost trap nullified for immune attacker")

func test_affinity_bonus_applied() -> void:
	print("-- test_affinity_bonus_applied (Angel Gatekeeper vs Chaos)")
	var attacker := _make_char("Angel Gatekeeper", 40, 90, 1000,
		CharacterData.Affinity.DIVINE,
		CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
		{"affinity": CharacterData.Affinity.CHAOS, "bonus": 60})
	var defender := _make_char("Chaotic Wisp", 20, 0, 100, CharacterData.Affinity.CHAOS)
	var result := BattleResolver.resolve_battle(attacker, defender, 3, 0, 1)
	# ATK 40 + 60 bonus = 100 > DEF 0
	assert_true(result.defender_destroyed, "Defender destroyed with affinity bonus")
	assert_true(not result.attacker_destroyed, "Attacker survives")

func test_defend_crystal_gain() -> void:
	print("-- test_defend_crystal_gain (Fierce Gladiator)")
	var attacker := _make_char("Attacker", 40, 0, 400)
	var defender := _make_char("Fierce Gladiator", 70, 90, 1300,
		CharacterData.Affinity.ANIMA,
		CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND,
		{"amount": 500})
	var result := BattleResolver.resolve_battle(attacker, defender, 3, 0, 1)
	# ATK 40 < DEF 90 → defender wins
	assert_true(result.attacker_destroyed, "Attacker destroyed")
	assert_eq(result.defender_crystal_gain, 500, "Defender gains 500 crystals on defend")

func test_defend_drain_attacker() -> void:
	print("-- test_defend_drain_attacker (Aether Warden)")
	var attacker := _make_char("Attacker", 20, 0, 300)
	var defender := _make_char("Aether Warden", 30, 110, 950,
		CharacterData.Affinity.DIVINE,
		CharacterData.AbilityType.DEFEND_DRAIN_ATTACKER,
		{"drain_amount": 300})
	var result := BattleResolver.resolve_battle(attacker, defender, 3, 0, 1)
	# ATK 20 < DEF 110 → defender wins, attacker drained
	assert_true(result.attacker_destroyed, "Attacker destroyed")
	assert_eq(result.attacker_crystal_loss, 300 + 300, "Attacker loses own cost + 300 drain")

func test_armored_bee_preview_silent() -> void:
	print("-- test_armored_bee_preview_silent")
	var attacker := _make_char("Shepherd Detective", 40, 25, 400)
	var defender := _make_char("Armored Bee", 30, 0, 480,
		CharacterData.Affinity.NATURE,
		CharacterData.AbilityType.ONE_USE_DEF_BOOST,
		{"bonus": 60})
	defender.one_use_def_boost_used = false
	var preview := BattleResolver.resolve_battle(
		attacker, defender, 5, 0, 1, false, Vector2i(-1, -1), true)
	assert_eq(preview.defender_def_used, 60, "Preview shows +60 DEF")
	assert_true(not preview.defender_destroyed, "Preview: Armored Bee survives 45 vs 60")
	assert_true(not defender.one_use_def_boost_used, "Preview must not spend one-use DEF boost")
	var real := BattleResolver.resolve_battle(attacker, defender, 5, 0, 1)
	assert_eq(real.defender_def_used, 60, "Real battle uses +60 DEF")
	assert_true(not real.defender_destroyed, "Real battle: Shepherd Detective loses 45 vs 60")
	assert_true(real.attacker_destroyed, "Real battle: attacker destroyed")
	assert_true(defender.one_use_def_boost_used, "One-use DEF boost spent after real battle")

func test_reckoning_overlay_log_lines() -> void:
	print("-- test_reckoning_overlay_log_lines")
	var attacker := _make_char("Angel Gatekeeper", 40, 12, 1000,
		CharacterData.Affinity.DIVINE,
		CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
		{"affinity": CharacterData.Affinity.CHAOS, "bonus": 60})
	var defender := _make_char("Chaotic Wisp", 20, 30, 100, CharacterData.Affinity.CHAOS)
	var result := BattleResolver.resolve_battle(attacker, defender, 3, 0, 1)
	result.attacker_name = attacker.card_name
	result.defender_name = defender.card_name
	assert_eq(result.attacker_pill_atk, 40, "Attacker ATK pill frozen at resolve")
	assert_eq(result.attacker_pill_def, 12, "Attacker DEF pill frozen at resolve")
	assert_eq(result.defender_pill_atk, 20, "Defender ATK pill frozen at resolve")
	assert_eq(result.defender_pill_def, 30, "Defender DEF pill frozen at resolve")
	assert_eq(result.attacker_atk_used, 100, "Attacker badge = pill + mod")
	assert_eq(result.attacker_atk_delta, 60, "Attacker ATK mod")
	var lines: PackedStringArray = BattleResolver.reckoning_overlay_log_lines(0, 1, result)
	assert_eq(lines.size(), 2, "Always two reckoning overlay lines")
	assert_true(lines[0].begins_with("Reckoning overlay: P0 "), "Attacker line prefix")
	assert_true("badge=100" in lines[0], "Attacker badge in log")
	assert_true("ATK pill=40" in lines[0], "Attacker ATK pill in log")
	assert_true("DEF pill=12" in lines[0], "Attacker DEF pill in log")
	assert_true("mod=+ATK 60" in lines[0], "Attacker mod in log")
	assert_true("(40+60=100)" in lines[0], "Attacker verification in log")
	assert_true(" MISMATCH" not in lines[0], "Attacker verification passes")
	assert_true(lines[1].begins_with("Reckoning overlay: P1 "), "Defender line prefix")
	assert_true("badge=30" in lines[1], "Defender badge in log")
	assert_true("mod=+DEF 0" in lines[1], "Defender zero mod in log")
	assert_true("(30+0=30)" in lines[1], "Defender verification in log")

func test_reckoning_pills_copied_from_preview() -> void:
	print("-- test_reckoning_pills_copied_from_preview")
	var attacker := _make_char("Gryphon", 30, 20, 500)
	var defender := _make_char("Shield Wall", 10, 40, 200)
	var preview := BattleResolver.resolve_battle(attacker, defender, 3, 0, 1, false, Vector2i(-1, -1), true)
	attacker.temp_atk_bonus += 5
	var final := BattleResolver.resolve_battle(attacker, defender, 3, 0, 1)
	BattleResolver.copy_reckoning_pills_from(preview, final)
	assert_eq(final.attacker_pill_atk, preview.attacker_pill_atk, "Preview ATK pill preserved")
	assert_eq(final.attacker_pill_def, preview.attacker_pill_def, "Preview DEF pill preserved")
	assert_eq(final.defender_pill_atk, preview.defender_pill_atk, "Preview defender ATK pill preserved")
	assert_eq(final.defender_pill_def, preview.defender_pill_def, "Preview defender DEF pill preserved")
	assert_eq(final.attacker_atk_used, 35, "Final badge includes temp boost")
	assert_eq(final.attacker_atk_delta, 0, "Final mod excludes pill-only temp boost")
	var lines: PackedStringArray = BattleResolver.reckoning_overlay_log_lines(0, 1, final)
	assert_true(" MISMATCH" in lines[0], "Optional pay after preview flags mismatch")
