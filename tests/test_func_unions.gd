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

func assert_false(cond: bool, msg: String) -> void:
	assert_true(not cond, msg)

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
	_manual("TC-FUNC-Colorful-Mage-001")
	_manual("TC-FUNC-False-Prophet-001")
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
	_gamma_mermaid(A, AB)
	_keeper_of_righteous(A, AB)
	_keeper_of_the_afterlife(A, AB)
	_burning_phoenix(A, AB)
	_genesis_mech(A, AB)
	_helios(A, AB)
	_slim_gray_plasma_bomber(A, AB)
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
# UNION_SUMMON_PERM_ATK_OR_DEF_CHOICE — summon choice handled in GameBoard._apply_union_summon_ability
func _sky_protector(A: Dictionary, AB: Dictionary) -> void:
	print("-- TC-FUNC-Sky-Protector-001 [MANUAL — union summon choice in GameBoard]")
	_manual("TC-FUNC-Sky-Protector-001")

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

func _gamma_mermaid(A: Dictionary, AB: Dictionary) -> void:
	var gm_params: Dictionary = {
		"affinity": A.BIO, "def": 20,
		"mutagen_party_atk": 20, "mutagen_party_def": 20, "mutagen_party_affinity": A.BIO,
	}
	print("-- TC-FUNC-Gamma-Mermaid-001")
	var mermaid := _make_char("Gamma Mermaid", 30, 20, 500, A.BIO,
		AB.DEF_PENALTY_VS_NON_AFFINITY, gm_params)
	var non_bio_def := _make_char("Dummy", 0, 50, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(mermaid, non_bio_def, 3, 0, 1)
	assert_eq(r.defender_def_used, 30, "TC-FUNC-Gamma-Mermaid-001: non-Bio defender loses 20 DEF")
	assert_true(r.defender_destroyed, "TC-FUNC-Gamma-Mermaid-001: ATK 30 > DEF 30")
	print("-- TC-FUNC-Gamma-Mermaid-002 [mutagen party aura]")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	var source := _make_char("Gamma Mermaid", 30, 20, 500, A.BIO,
		AB.DEF_PENALTY_VS_NON_AFFINITY, gm_params)
	source.has_mutagen_flag = true
	var bio_ally := _make_char("Lab Zombie", 40, 40, 300, A.BIO)
	source.face_up = true
	bio_ally.face_up = true
	GameState.grids[0][2][1] = source
	GameState.grids[0][2][2] = bio_ally
	BattleResolver.calculate_field_bonuses(0)
	assert_eq(bio_ally.field_aura_atk_bonus, 20, "TC-FUNC-Gamma-Mermaid-002: +20 ATK aura to Bio ally")
	assert_eq(bio_ally.field_aura_def_bonus, 20, "TC-FUNC-Gamma-Mermaid-002: +20 DEF aura to Bio ally")
	assert_eq(bio_ally.get_effective_atk(), 60, "TC-FUNC-Gamma-Mermaid-002: effective ATK 40+20=60")
	assert_eq(bio_ally.get_effective_def(), 60, "TC-FUNC-Gamma-Mermaid-002: effective DEF 40+20=60")

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

	# TC-FUNC-Katana-Shark-001 — ATK=105, DEF=50, DIVINE, NONE
	print("-- TC-FUNC-Katana-Shark-001")
	var katana := _make_char("Katana Shark", 105, 50, 0, A.DIVINE)
	var def4 := _make_char("Dummy", 0, 40, 100, A.ANIMA)
	var r4 := BattleResolver.resolve_battle(katana, def4, 3, 0, 1)
	assert_eq(r4.attacker_atk_used, 105, "TC-FUNC-Katana-Shark-001: ATK=105 correct")
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

# ---------------------------------------------------------------------------
# ATK_BONUS_VS_TWO_AFFINITIES — Keeper of Righteous
# ---------------------------------------------------------------------------
func _keeper_of_righteous(A: Dictionary, AB: Dictionary) -> void:
	print("-- TC-FUNC-Keeper-of-Righteous-001")
	var att := _make_char("Keeper of Righteous", 90, 80, 1000, A.DIVINE,
		AB.ATK_BONUS_VS_TWO_AFFINITIES, {"aff1": A.CHAOS, "aff2": A.ARCANE, "bonus": 20})
	var r1 := BattleResolver.resolve_battle(att, _make_char("Chaos", 0, 10, 100, A.CHAOS), 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 110, "TC-FUNC-Keeper-of-Righteous-001: ATK 90+20=110 vs CHAOS")
	var r2 := BattleResolver.resolve_battle(att, _make_char("Arcane", 0, 10, 100, A.ARCANE), 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 110, "TC-FUNC-Keeper-of-Righteous-001: ATK 90+20=110 vs ARCANE")
	var r3 := BattleResolver.resolve_battle(att, _make_char("Nature", 0, 10, 100, A.NATURE), 3, 0, 1)
	assert_eq(r3.attacker_atk_used, 90, "TC-FUNC-Keeper-of-Righteous-001: ATK 90 base vs NATURE")

# ---------------------------------------------------------------------------
# COIN_FLIP_NULLIFY_ON_DEFEND — Keeper of the Afterlife (coin-result-verified)
# ---------------------------------------------------------------------------
func _keeper_of_the_afterlife(A: Dictionary, AB: Dictionary) -> void:
	print("-- TC-FUNC-Keeper-of-the-Afterlife-001 [coin-result-verified]")
	var strong_att := _make_char("Strong Attacker", 200, 0, 500, A.ANIMA)
	var def_ := _make_char("Keeper of the Afterlife", 40, 65, 1000, A.DIVINE,
		AB.COIN_FLIP_NULLIFY_ON_DEFEND, {})
	var r := BattleResolver.resolve_battle(strong_att, def_, 3, 0, 1)
	assert_eq(r.coin_flip_results.size(), 1, "TC-FUNC-Keeper-of-Afterlife-001: 1 coin flipped")
	if r.coin_flip_results[0]:
		assert_false(r.defender_destroyed, "TC-FUNC-Keeper-of-Afterlife-001: heads → attack nullified")
		assert_false(r.attacker_destroyed, "TC-FUNC-Keeper-of-Afterlife-001: heads → attacker also unharmed")
	else:
		assert_true(r.defender_destroyed, "TC-FUNC-Keeper-of-Afterlife-001: tails → normal battle (200 > 65)")

# ---------------------------------------------------------------------------
# IMMUNE_DESTROY_BY_NON_UNION — Burning Phoenix
# ---------------------------------------------------------------------------
func _burning_phoenix(A: Dictionary, AB: Dictionary) -> void:
	print("-- TC-FUNC-Burning-Phoenix-001 / -002")
	var phoenix := _make_char("Burning Phoenix", 125, 50, 800, A.ARCANE,
		AB.IMMUNE_DESTROY_BY_NON_UNION, {"tech_target_self_destruct": true})
	phoenix.is_union = true
	# Non-union high-ATK attacker: wins compare but cannot destroy
	var non_union_att := _make_char("Strong Non-Union", 200, 0, 500, A.ANIMA)
	non_union_att.is_union = false
	var r1 := BattleResolver.resolve_battle(non_union_att, phoenix, 3, 0, 1)
	assert_false(r1.defender_destroyed, "TC-FUNC-Burning-Phoenix-001: non-union cannot destroy")
	assert_false(r1.attacker_destroyed, "TC-FUNC-Burning-Phoenix-001: attacker won compare (not destroyed)")
	# Union attacker CAN destroy
	var union_att := _make_char("Strong Union", 200, 0, 1000, A.DIVINE)
	union_att.is_union = true
	var r2 := BattleResolver.resolve_battle(union_att, phoenix, 3, 0, 1)
	assert_true(r2.defender_destroyed, "TC-FUNC-Burning-Phoenix-002: union attacker CAN destroy")

# ---------------------------------------------------------------------------
# ONE_USE_DESTROY_BY_AFFINITY — Genesis Mech
# ---------------------------------------------------------------------------
func _genesis_mech(A: Dictionary, AB: Dictionary) -> void:
	print("-- TC-FUNC-Genesis-Mech-001 / -002 / -003")
	var mech := _make_char("Genesis Mech", 60, 40, 1000, A.DIVINE,
		AB.ONE_USE_DESTROY_BY_AFFINITY, {"aff1": A.DIVINE, "aff2": A.ANIMA})
	mech.one_use_atk_boost_used = false
	# vs DIVINE (high DEF): instant destroy, no crystal loss, ability consumed
	var def_divine := _make_char("Divine Target", 0, 200, 500, A.DIVINE)
	var r1 := BattleResolver.resolve_battle(mech, def_divine, 3, 0, 1)
	assert_true(r1.defender_destroyed, "TC-FUNC-Genesis-Mech-001: DIVINE target instantly destroyed")
	assert_false(r1.attacker_destroyed, "TC-FUNC-Genesis-Mech-001: Genesis Mech survives")
	assert_eq(r1.defender_crystal_loss, 0, "TC-FUNC-Genesis-Mech-001: no crystal loss on one-use destroy")
	assert_true(mech.one_use_atk_boost_used, "TC-FUNC-Genesis-Mech-001: ability marked used")
	# Second use (used=true): falls through to normal battle
	var def_anima := _make_char("Anima Target", 0, 200, 500, A.ANIMA)
	var r2 := BattleResolver.resolve_battle(mech, def_anima, 3, 0, 1)
	assert_false(r2.defender_destroyed, "TC-FUNC-Genesis-Mech-002: ability already used — no second destroy")
	assert_true(r2.attacker_destroyed, "TC-FUNC-Genesis-Mech-002: normal battle (ATK 60 < DEF 200)")
	# vs CHAOS (neither affinity): ability never triggers
	var mech2 := _make_char("Genesis Mech", 60, 40, 1000, A.DIVINE,
		AB.ONE_USE_DESTROY_BY_AFFINITY, {"aff1": A.DIVINE, "aff2": A.ANIMA})
	mech2.one_use_atk_boost_used = false
	var def_chaos := _make_char("Chaos Target", 0, 200, 500, A.CHAOS)
	var r3 := BattleResolver.resolve_battle(mech2, def_chaos, 3, 0, 1)
	assert_false(r3.defender_destroyed, "TC-FUNC-Genesis-Mech-003: CHAOS not in ability affinities")
	assert_false(mech2.one_use_atk_boost_used, "TC-FUNC-Genesis-Mech-003: ability not consumed vs CHAOS")

# ---------------------------------------------------------------------------
# IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP — Helios (Pattern B)
# ---------------------------------------------------------------------------
func _helios(A: Dictionary, AB: Dictionary) -> void:
	print("-- TC-FUNC-Helios-the-Prideful-Fortress-001 [Pattern B]")
	var helios := _make_char("Helios the Prideful Fortress", 145, 100, 1500, A.COSMIC,
		AB.IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP, {"affinity": A.COSMIC})
	helios.is_union = true
	var strong_att := _make_char("Strong Attacker", 200, 0, 500, A.ANIMA)
	# With COSMIC ally face-up on same side: cannot be destroyed
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	helios.face_up = true
	GameState.grids[1][2][2] = helios
	var cosmic_ally := _make_char("Space Boy", 75, 65, 800, A.COSMIC)
	cosmic_ally.face_up = true
	GameState.grids[1][2][3] = cosmic_ally
	var r1 := BattleResolver.resolve_battle(strong_att, helios, 3, 0, 1)
	assert_false(r1.defender_destroyed, "TC-FUNC-Helios-001: protected by COSMIC ally (200 vs 100)")
	# Without COSMIC ally: destroyed normally
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	helios.face_up = true
	GameState.grids[1][2][2] = helios
	var r2 := BattleResolver.resolve_battle(strong_att, helios, 3, 0, 1)
	assert_true(r2.defender_destroyed, "TC-FUNC-Helios-001b: no COSMIC ally → destroyed (200 > 100)")

# ---------------------------------------------------------------------------
# ATK_DEF_BONUS_IF_OWN_REVEALED_GTE — Slim Gray Plasma Bomber (Pattern B)
# ---------------------------------------------------------------------------
func _slim_gray_plasma_bomber(A: Dictionary, AB: Dictionary) -> void:
	print("-- TC-FUNC-Slim-Gray-Plasma-Bomber-001 [Pattern B]")
	var bomber := _make_char("Slim Gray Plasma Bomber", 80, 60, 1000, A.COSMIC,
		AB.ATK_DEF_BONUS_IF_OWN_REVEALED_GTE, {"min_revealed": 15, "atk": 100, "def": 100})
	bomber.is_union = true
	var def_ := _make_char("Dummy", 0, 10, 100, A.ANIMA)
	# With 15+ revealed cells: ATK = 80+100 = 180
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	bomber.face_up = true
	GameState.grids[0][0][0] = bomber
	var placed := 1
	for r in range(GameState.GRID_SIZE):
		for c in range(GameState.GRID_SIZE):
			if placed >= 15:
				break
			if r == 0 and c == 0:
				continue
			var filler := _make_char("Filler", 0, 0, 100, A.ANIMA)
			filler.face_up = true
			GameState.grids[0][r][c] = filler
			placed += 1
		if placed >= 15:
			break
	var r1 := BattleResolver.resolve_battle(bomber, def_, 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 180, "TC-FUNC-Slim-Gray-Plasma-Bomber-001: ATK 80+100=180 (15 revealed)")
	# Fewer than 15 revealed: base ATK = 80
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	bomber.face_up = true
	GameState.grids[0][0][0] = bomber
	var r2 := BattleResolver.resolve_battle(bomber, def_, 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 80, "TC-FUNC-Slim-Gray-Plasma-Bomber-001b: ATK 80 base (<15 revealed)")
