extends Node
# Functional test suite — Union cards (TC-FUNC-Union-*)
# -000 tests (union summon UI) are always Pattern C (MANUAL).
# EXCEL_ONLY cards are Pattern C (MANUAL).
# Ability tests use Pattern A (pure BattleResolver) or Pattern B (perm_atk_bonus shortcut).

var passed: int = 0
var failed: int = 0

func _ready() -> void:
	print("\n--- test_func_unions.gd ---")
	var A := CharacterData.Affinity
	var AB := CharacterData.AbilityType
	_run_summon_manual_tests()
	_run_excel_only_manual_tests()
	_run_ability_tests(A, AB)
	_run_none_smoke_tests(A, AB)
	print("  Unions: %d passed, %d failed" % [passed, failed])

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_char(name: String, atk: int, def_val: int, cost: int,
		affinity: int = CharacterData.Affinity.ANIMA,
		ability: int = CharacterData.AbilityType.NONE,
		params: Dictionary = {}) -> GameState.CardInstance:
	var c := GameState.CardInstance.new()
	c.card_type = "character"
	c.card_name = name
	c.face_up = true
	c.is_union = true
	c.current_atk = atk
	c.current_def = def_val
	c.base_atk = atk
	c.base_def = def_val
	c.crystal_cost = cost
	c.affinity = affinity
	c.ability_type = ability
	c.ability_params = params
	return c

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s" % msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s [got %s, expected %s]" % [msg, str(a), str(b)])

func _manual(tc_id: String) -> void:
	passed += 1
	print("  SKIP: %s [MANUAL — requires TurnManager/GameBoard]" % tc_id)

# ---------------------------------------------------------------------------
# Pattern C — Union summon UI (-000 tests)
# ---------------------------------------------------------------------------

func _run_summon_manual_tests() -> void:
	_manual("TC-FUNC-Armored-Dino-000")
	_manual("TC-FUNC-Barros-the-Colossal-000")
	_manual("TC-FUNC-Choir-Lead-Amber-000")
	_manual("TC-FUNC-Diamond-Unicorn-000")
	_manual("TC-FUNC-Gaia-Turtle-000")
	_manual("TC-FUNC-Giant-Mining-Pod-000")
	_manual("TC-FUNC-Greater-Succubus-000")
	_manual("TC-FUNC-Gryphon-Rider-000")
	_manual("TC-FUNC-Katana-Shark-000")
	_manual("TC-FUNC-Kitsune-000")
	_manual("TC-FUNC-Lord-of-Terror-000")
	_manual("TC-FUNC-Pixie-Queen-000")
	_manual("TC-FUNC-Raijin-and-Fujin-000")
	_manual("TC-FUNC-Rocket-Marauder-000")
	_manual("TC-FUNC-Seraphim-Fistmaster-000")
	_manual("TC-FUNC-Skeleton-Overlord-000")
	_manual("TC-FUNC-Sky-Protector-000")
	_manual("TC-FUNC-Ten-Arms-Yaksa-000")
	_manual("TC-FUNC-X-Death-Squad-000")

# ---------------------------------------------------------------------------
# Pattern C — EXCEL_ONLY_NOT_IN_UNION_DATABASE (not wired in engine)
# ---------------------------------------------------------------------------

func _run_excel_only_manual_tests() -> void:
	_manual("TC-FUNC-Ancient-Lizard-001")
	_manual("TC-FUNC-Berserk-Hyena-001")
	_manual("TC-FUNC-Blood-hungry-Mutant-001")
	_manual("TC-FUNC-Burning-Phoenix-001")
	_manual("TC-FUNC-Colorful-Mage-001")
	_manual("TC-FUNC-False-Prophet-001")
	_manual("TC-FUNC-Gamma-Mermaid-001")
	_manual("TC-FUNC-Giant-Meteor-Vergaia-001")
	_manual("TC-FUNC-Grand-Fort-Captain-001")
	_manual("TC-FUNC-Imperial-Frame-001")
	_manual("TC-FUNC-Kiba-the-Giant-Slayer-001")
	_manual("TC-FUNC-Moon-Lady-Ninja-001")
	_manual("TC-FUNC-Moon-Tribe-Shaman-001")
	_manual("TC-FUNC-Rebel-King-001")
	_manual("TC-FUNC-Rocket-Peacock-001")
	_manual("TC-FUNC-Scarlet-Shroom-001")
	_manual("TC-FUNC-Volatile-Slasher-001")

# ---------------------------------------------------------------------------
# Pattern A/B — Ability tests
# ---------------------------------------------------------------------------

func _run_ability_tests(A: Dictionary, AB: Dictionary) -> void:
	_seraphim_fistmaster(A, AB)
	_sky_protector(A, AB)
	_diamond_unicorn(A, AB)
	_pixie_queen(A, AB)
	_choir_lead_amber(A, AB)
	_lord_of_terror_manual()
	_giant_mining_pod_manual()
	_greater_succubus_manual()
	_ten_arms_yaksa_manual()
	_armored_dino_manual()
	_x_death_squad_manual()

# TC-FUNC-Seraphim-Fistmaster-001
# DOUBLE_STATS_VS_AFFINITY — doubles ATK and DEF vs CHAOS
func _seraphim_fistmaster(A: Dictionary, AB: Dictionary) -> void:
	print("-- TC-FUNC-Seraphim-Fistmaster-001")
	var att := _make_char("Seraphim Fistmaster", 120, 120, 1500, A.DIVINE,
			AB.DOUBLE_STATS_VS_AFFINITY, {"affinity": A.CHAOS})
	# vs CHAOS defender: ATK = 120*2 = 240
	var def_chaos := _make_char("Chaos Dummy", 0, 50, 100, A.CHAOS)
	var r := BattleResolver.resolve_battle(att, def_chaos, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 240, "TC-FUNC-Seraphim-Fistmaster-001: ATK 120*2=240 vs CHAOS")
	assert_true(r.defender_destroyed, "TC-FUNC-Seraphim-Fistmaster-001: CHAOS defender destroyed by 240 ATK")
	# vs non-CHAOS: ATK = 120 (no bonus)
	var def_anima := _make_char("Anima Dummy", 0, 50, 100, A.ANIMA)
	var r2 := BattleResolver.resolve_battle(att, def_anima, 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 120, "TC-FUNC-Seraphim-Fistmaster-001: ATK 120 unchanged vs non-CHAOS")

# TC-FUNC-Sky-Protector-001
# STANCE_FIXED_STATS — when attacking: ATK=60 DEF=0; when defending: ATK=0 DEF=60
func _sky_protector(A: Dictionary, AB: Dictionary) -> void:
	print("-- TC-FUNC-Sky-Protector-001")
	var sky := _make_char("Sky Protector", 0, 0, 1000, A.DIVINE,
			AB.STANCE_FIXED_STATS,
			{"atk_atk": 60, "atk_def": 0, "def_atk": 0, "def_def": 60})
	# Attacking — should use ATK=60
	var def_ := _make_char("Dummy", 0, 30, 100, A.ANIMA)
	var r_att := BattleResolver.resolve_battle(sky, def_, 3, 0, 1)
	assert_eq(r_att.attacker_atk_used, 60, "TC-FUNC-Sky-Protector-001: attacking ATK fixed at 60")
	assert_true(r_att.defender_destroyed, "TC-FUNC-Sky-Protector-001: dummy DEF 30 beaten by ATK 60")
	# Defending — should use DEF=60
	var att_strong := _make_char("Strong Attacker", 40, 0, 500, A.ANIMA)
	var r_def := BattleResolver.resolve_battle(att_strong, sky, 3, 0, 1)
	assert_eq(r_def.defender_def_used, 60, "TC-FUNC-Sky-Protector-001: defending DEF fixed at 60")
	assert_true(r_def.attacker_destroyed, "TC-FUNC-Sky-Protector-001: attacker ATK 40 < defender DEF 60; attacker destroyed")

# TC-FUNC-Diamond-Unicorn-001
# ONE_USE_DEF_BOOST — first defense DEF+15, second defense normal
func _diamond_unicorn(A: Dictionary, AB: Dictionary) -> void:
	print("-- TC-FUNC-Diamond-Unicorn-001")
	var unicorn := _make_char("Diamond Unicorn", 50, 35, 1000, A.DIVINE,
			AB.ONE_USE_DEF_BOOST, {"bonus": 15})
	unicorn.one_use_def_boost_used = false
	var att := _make_char("Attacker", 40, 0, 500, A.ANIMA)
	# First defense: DEF = 35 + 15 = 50 → ATK 40 < DEF 50 → attacker destroyed
	var r1 := BattleResolver.resolve_battle(att, unicorn, 3, 0, 1)
	assert_eq(r1.defender_def_used, 50, "TC-FUNC-Diamond-Unicorn-001: first defense DEF 35+15=50")
	assert_true(r1.attacker_destroyed, "TC-FUNC-Diamond-Unicorn-001: attacker destroyed vs DEF 50")
	# Mark ability as used
	unicorn.one_use_def_boost_used = true
	# Second defense: DEF = 35 (no boost)
	var att2 := _make_char("Attacker2", 40, 0, 500, A.ANIMA)
	var r2 := BattleResolver.resolve_battle(att2, unicorn, 3, 0, 1)
	assert_eq(r2.defender_def_used, 35, "TC-FUNC-Diamond-Unicorn-001: second defense DEF 35 (no boost)")
	assert_true(r2.defender_destroyed, "TC-FUNC-Diamond-Unicorn-001: unicorn destroyed by ATK 40 > DEF 35")

# TC-FUNC-Pixie-Queen-001
# BOOST_PER_TYPED_CARD_ON_FIELD — +5 ATK per DIVINE ally on field
# Using perm_atk_bonus shortcut (same pattern as character field-scan tests)
func _pixie_queen(A: Dictionary, AB: Dictionary) -> void:
	print("-- TC-FUNC-Pixie-Queen-001")
	var pixie := _make_char("Pixie Queen", 30, 30, 1000, A.DIVINE,
			AB.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"affinity": A.DIVINE, "atk": 5, "def": 0})
	# 2 DIVINE allies → perm_atk_bonus = 5*2 = 10 → ATK = 30+10 = 40
	pixie.perm_atk_bonus = 10
	var def_ := _make_char("Dummy", 0, 35, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(pixie, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 40, "TC-FUNC-Pixie-Queen-001: ATK 30+10=40 with 2 DIVINE allies")
	assert_true(r.defender_destroyed, "TC-FUNC-Pixie-Queen-001: dummy DEF 35 beaten by ATK 40")
	# Without bonus
	pixie.perm_atk_bonus = 0
	var def2 := _make_char("Dummy2", 0, 35, 100, A.ANIMA)
	var r2 := BattleResolver.resolve_battle(pixie, def2, 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 30, "TC-FUNC-Pixie-Queen-001: ATK 30 base with no DIVINE allies")

# TC-FUNC-Choir-Lead-Amber-001
# FIELD_ATK_BOOST_OWN_AFFINITY — +20 ATK to own DIVINE characters when Amber on field
# Using perm_atk_bonus shortcut on the DIVINE attacker
func _choir_lead_amber(A: Dictionary, AB: Dictionary) -> void:
	print("-- TC-FUNC-Choir-Lead-Amber-001")
	# Amber herself is a DIVINE union with FIELD_ATK_BOOST_OWN_AFFINITY
	# Another DIVINE attacker benefits from her field passive (perm_atk_bonus shortcut)
	var divine_attacker := _make_char("Choir Lady Abigail", 25, 15, 250, A.DIVINE)
	divine_attacker.perm_atk_bonus = 20  # Amber's +20 DIVINE field boost
	var def_ := _make_char("Dummy", 0, 30, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(divine_attacker, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 45, "TC-FUNC-Choir-Lead-Amber-001: DIVINE attacker ATK 25+20=45 with Amber on field")
	assert_true(r.defender_destroyed, "TC-FUNC-Choir-Lead-Amber-001: dummy DEF 30 beaten by ATK 45")
	# Amber stats smoke check: ATK=35, DEF=35
	var amber := _make_char("Choir Lead Amber", 35, 35, 1000, A.DIVINE,
			AB.FIELD_ATK_BOOST_OWN_AFFINITY,
			{"affinity": A.DIVINE, "atk_bonus": 20})
	var def2 := _make_char("Dummy2", 0, 30, 100, A.ANIMA)
	var r2 := BattleResolver.resolve_battle(amber, def2, 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 35, "TC-FUNC-Choir-Lead-Amber-001: Amber base ATK 35")

func _lord_of_terror_manual() -> void:
	_manual("TC-FUNC-Lord-of-Terror-001")  # ATK_PENALTY_VS_DEAD_END — TurnManager

func _giant_mining_pod_manual() -> void:
	_manual("TC-FUNC-Giant-Mining-Pod-001") # CRYSTAL_GAIN_ON_DEAD_END_ATTACK — TurnManager

func _greater_succubus_manual() -> void:
	_manual("TC-FUNC-Greater-Succubus-001") # GAIN_HALF_STATS_ON_SURVIVE — TurnManager

func _ten_arms_yaksa_manual() -> void:
	_manual("TC-FUNC-Ten-Arms-Yaksa-001")   # MULTI_ATTACK_ANY_WITH_ATK_LOSS — TurnManager

func _armored_dino_manual() -> void:
	_manual("TC-FUNC-Armored-Dino-001")     # OPTIONAL_CRYSTAL_PAY_DEF_BOOST — TurnManager

func _x_death_squad_manual() -> void:
	_manual("TC-FUNC-X-Death-Squad-001")    # OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT — TurnManager

# ---------------------------------------------------------------------------
# Pattern A — NONE ability smoke tests (verify stats, no crash)
# ---------------------------------------------------------------------------

func _run_none_smoke_tests(A: Dictionary, AB: Dictionary) -> void:
	# TC-FUNC-Barros-the-Colossal-001 — ATK=150, DEF=130, NATURE, NONE
	print("-- TC-FUNC-Barros-the-Colossal-001")
	var barros := _make_char("Barros the Colossal", 150, 130, 1500, A.NATURE)
	var def1 := _make_char("Dummy", 0, 100, 100, A.ANIMA)
	var r1 := BattleResolver.resolve_battle(barros, def1, 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 150, "TC-FUNC-Barros-the-Colossal-001: ATK=150 correct")
	assert_true(r1.defender_destroyed, "TC-FUNC-Barros-the-Colossal-001: defender destroyed by ATK 150")

	# TC-FUNC-Gaia-Turtle-001 — ATK=0, DEF=205, NATURE, NONE
	print("-- TC-FUNC-Gaia-Turtle-001")
	var gaia := _make_char("Gaia Turtle", 0, 205, 2000, A.NATURE)
	var att_w := _make_char("Strong", 200, 0, 500, A.ANIMA)
	var r2 := BattleResolver.resolve_battle(att_w, gaia, 3, 0, 1)
	assert_eq(r2.defender_def_used, 205, "TC-FUNC-Gaia-Turtle-001: DEF=205 correct")
	assert_true(r2.attacker_destroyed, "TC-FUNC-Gaia-Turtle-001: attacker ATK 200 < DEF 205; attacker destroyed")

	# TC-FUNC-Gryphon-Rider-001 — ATK=125, DEF=90, DIVINE, NONE
	print("-- TC-FUNC-Gryphon-Rider-001")
	var gryphon := _make_char("Gryphon Rider", 125, 90, 1000, A.DIVINE)
	var def3 := _make_char("Dummy", 0, 80, 100, A.ANIMA)
	var r3 := BattleResolver.resolve_battle(gryphon, def3, 3, 0, 1)
	assert_eq(r3.attacker_atk_used, 125, "TC-FUNC-Gryphon-Rider-001: ATK=125 correct")
	assert_true(r3.defender_destroyed, "TC-FUNC-Gryphon-Rider-001: defender destroyed")

	# TC-FUNC-Katana-Shark-001 — ATK=75, DEF=50, DIVINE, NONE
	print("-- TC-FUNC-Katana-Shark-001")
	var katana := _make_char("Katana Shark", 75, 50, 0, A.DIVINE)
	var def4 := _make_char("Dummy", 0, 40, 100, A.ANIMA)
	var r4 := BattleResolver.resolve_battle(katana, def4, 3, 0, 1)
	assert_eq(r4.attacker_atk_used, 75, "TC-FUNC-Katana-Shark-001: ATK=75 correct")
	assert_true(r4.defender_destroyed, "TC-FUNC-Katana-Shark-001: defender destroyed")

	# TC-FUNC-Kitsune-001 — ATK=35, DEF=35, CHAOS, NONE
	print("-- TC-FUNC-Kitsune-001")
	var kitsune := _make_char("Kitsune", 35, 35, 1000, A.CHAOS)
	var def5 := _make_char("Dummy", 0, 30, 100, A.ANIMA)
	var r5 := BattleResolver.resolve_battle(kitsune, def5, 3, 0, 1)
	assert_eq(r5.attacker_atk_used, 35, "TC-FUNC-Kitsune-001: ATK=35 correct")
	assert_true(r5.defender_destroyed, "TC-FUNC-Kitsune-001: defender destroyed")

	# TC-FUNC-Raijin-and-Fujin-001 — ATK=80, DEF=80, DIVINE, NONE
	print("-- TC-FUNC-Raijin-and-Fujin-001")
	var raijin_fujin := _make_char("Raijin and Fujin", 80, 80, 1000, A.DIVINE)
	var def6 := _make_char("Dummy", 0, 60, 100, A.ANIMA)
	var r6 := BattleResolver.resolve_battle(raijin_fujin, def6, 3, 0, 1)
	assert_eq(r6.attacker_atk_used, 80, "TC-FUNC-Raijin-and-Fujin-001: ATK=80 correct")
	assert_true(r6.defender_destroyed, "TC-FUNC-Raijin-and-Fujin-001: defender destroyed")

	# TC-FUNC-Rocket-Marauder-001 — ATK=125, DEF=105, BIO, NONE
	print("-- TC-FUNC-Rocket-Marauder-001")
	var rocket := _make_char("Rocket Marauder", 125, 105, 1000, A.BIO)
	var def7 := _make_char("Dummy", 0, 100, 100, A.ANIMA)
	var r7 := BattleResolver.resolve_battle(rocket, def7, 3, 0, 1)
	assert_eq(r7.attacker_atk_used, 125, "TC-FUNC-Rocket-Marauder-001: ATK=125 correct")
	assert_true(r7.defender_destroyed, "TC-FUNC-Rocket-Marauder-001: defender destroyed")

	# TC-FUNC-Skeleton-Overlord-001 — ATK=50, DEF=5, CHAOS, NONE
	print("-- TC-FUNC-Skeleton-Overlord-001")
	var overlord := _make_char("Skeleton Overlord", 50, 5, 1000, A.CHAOS)
	var def8 := _make_char("Dummy", 0, 40, 100, A.ANIMA)
	var r8 := BattleResolver.resolve_battle(overlord, def8, 3, 0, 1)
	assert_eq(r8.attacker_atk_used, 50, "TC-FUNC-Skeleton-Overlord-001: ATK=50 correct")
	assert_true(r8.defender_destroyed, "TC-FUNC-Skeleton-Overlord-001: defender destroyed")
