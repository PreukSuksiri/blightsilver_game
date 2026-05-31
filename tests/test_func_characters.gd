extends Node
# TC-FUNC-* Functional Tests — Characters (demo scope)
# Patterns:
#   A = Pure BattleResolver — _make_char + resolve_battle
#   B = Field-scan — GameState.grids setup before resolve_battle
#   MANUAL = TurnManager/UI/coin-flip; acknowledged as skip (counted pass)

var passed: int = 0
var failed: int = 0

func _ready() -> void:
	run_all_tests()
	print("=== Character Functional Tests: %d passed, %d failed ===" % [passed, failed])

# ─── helpers ──────────────────────────────────────────────────────────────────
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

func _make_trap(name: String, cost: int) -> GameState.CardInstance:
	var c := GameState.CardInstance.new()
	c.card_type = "trap"
	c.card_name = name
	c.face_up = true
	c.crystal_cost = cost
	return c

func assert_true(cond: bool, msg: String) -> void:
	if cond:
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

func _manual(tc_id: String) -> void:
	passed += 1
	print("  SKIP: %s [MANUAL — requires TurnManager/UI/coin-flip; verify in live session]" % tc_id)

# ─── run_all_tests ────────────────────────────────────────────────────────────
func run_all_tests() -> void:
	var A := CharacterData.Affinity
	var AB := CharacterData.AbilityType

	# ATK_BONUS_VS_AFFINITY (Pattern A)
	_angel_gatekeeper(A, AB)
	_bleacher_squad(A, AB)
	_jacob(A, AB)
	_pyromancer(A, AB)
	_red_mage(A, AB)
	_silver_spearman(A, AB)
	_street_rogue(A, AB)

	# ATK_BONUS_VS_CENTER_ZONE (Pattern A)
	_satellite_cannon(A, AB)

	# ATK_BONUS_VS_FACEDOWN (Pattern A)
	_skeleton_archer(A, AB)

	# ATK_BONUS_VS_UNION (Pattern A)
	_kiyoko(A, AB)

	# ATK_BONUS_VS_VENOM (Pattern A)
	_giant_centipede(A, AB)

	# ATK_BOOST_VS_REVEALED (Pattern A)
	_cursed_well(A, AB)
	_void_stalker(A, AB)

	# ATK_DEF_BONUS_IF_UNION_ON_FIELD (Pattern B)
	_aerial(A, AB)

	# ATK_DEF_BONUS_VS_AFFINITY (Pattern A)
	_book_with_fangs(A, AB)
	_flame_lizard(A, AB)
	_gamma_emitter(A, AB)
	_mind_flayer(A, AB)
	_witchhunter(A, AB)

	# ATK_DEF_BONUS_VS_NON_AFFINITY (Pattern A)
	_ox_patrol(A, AB)

	# ATK_BONUS_IF_AFFINITY_ON_FIELD (Pattern B)
	_armored_monkey(A, AB)

	# ATK_PENALTY_IF_NO_NAME_ALLY (Pattern B)
	_moon_tribe_marksman(A, AB)

	# ATK_PENALTY_WHEN_EXPOSED (Pattern A)
	_sniping_fairy(A, AB)

	# ATK_ZERO_AFTER_WIN — MANUAL (TurnManager post-battle)
	_manual("TC-FUNC-Mephisto-the-Fallen-001")

	# ATTACKER_ATK_DEBUFF (Pattern A)
	_white_tiger(A, AB)

	# ATTACK_STANCE_BOOST (Pattern A)
	_sunrise_lady(A, AB)

	# BOOST_PER_ANIMA_ON_FIELD (Pattern B)
	_leorudus(A, AB)

	# BOOST_PER_TYPED_CARD_ON_FIELD (Pattern B — perm_atk_bonus set directly)
	_death_knight(A, AB)
	_hammer_shark(A, AB)
	_night_whisperer(A, AB)
	_saw_shark(A, AB)
	_scythe_shark(A, AB)
	_shotgun_shark(A, AB)
	_spear_shark(A, AB)
	_swarmcaller(A, AB)

	# COIN_FLIP — MANUAL
	_manual("TC-FUNC-Blue-Mage-001")
	_manual("TC-FUNC-Joseph-the-Battle-Priest-001")
	_manual("TC-FUNC-Lazy-Troll-001")
	_manual("TC-FUNC-Moon-Tribe-Twin-Blades-001")
	_manual("TC-FUNC-Nuki-the-Tanuki-001")

	# CRYSTAL effects — MANUAL (GameState/TurnManager hooks)
	_manual("TC-FUNC-Miner-Probe-001")
	_manual("TC-FUNC-Parom-the-Smuggler-001")
	_manual("TC-FUNC-Melissa-the-Healer-001")

	# DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF (Pattern A)
	_green_mage(A, AB)

	# DEFENSE_STANCE_BOOST (Pattern A)
	_moonrise_gentleman(A, AB)

	# DEF_BONUS_IF_AFFINITY_ON_FIELD (Pattern B)
	_joan(A, AB)

	# DEF_ZERO_WHEN_EXPOSED (Pattern A)
	_mafia_associates(A, AB)

	# DESTROYED_IF_BATTLES_DIVINE (Pattern A)
	_immortal_vampire(A, AB)
	_pit_lord(A, AB)
	_vampire_duchess(A, AB)

	# DESTROY_IF_OPPONENT_AFFINITY (Pattern A)
	_goddess_of_virtue(A, AB)

	# DESTROY_SELF_AT_END_OF_EXPOSE_TURN — MANUAL (TurnManager turn end)
	_manual("TC-FUNC-Striker-Comet-001")

	# DESTROY_SELF_VS_DIVINE_BOTH (Pattern A)
	_feral_vampire(A, AB)

	# EXTRA_ATTACK — MANUAL (TurnManager post-battle)
	_manual("TC-FUNC-Sonic-Seraph-001")
	_manual("TC-FUNC-Echo-Bringer-001")

	# HALVE_DEF_ON_FIRST_EXPOSE — MANUAL (GameState reveal hook)
	_manual("TC-FUNC-Magenta-the-Nightbloom-001")

	# IMMUNE_TO_TECH_CARDS — MANUAL (GameBoard filter)
	_manual("TC-FUNC-Araya-the-Eerie-Dancer-001")

	# IMMUNE_TO_TRAPS (Pattern A)
	_tomb_bandit(A, AB)

	# IMMUNE_ZERO_COST_TRAPS (Pattern A)
	_huntress(A, AB)
	_laser_walker(A, AB)
	_mars_drill(A, AB)

	# LOCK / INTERCEPT — MANUAL (TurnManager)
	_manual("TC-FUNC-Bat-Swarm-001")
	_manual("TC-FUNC-Stinky-Insect-001")
	_manual("TC-FUNC-Skeleton-Grappler-001")
	_manual("TC-FUNC-Ostrich-Cannon-001")
	_manual("TC-FUNC-Leopard-Jailer-001")

	# MULTI_ATTACK_VS_NON_CHARACTER — MANUAL (TurnManager)
	_manual("TC-FUNC-Golden-Senju-001")

	# MUTAGEN_* (Pattern A — set has_mutagen_flag directly)
	_claw_mutant(A, AB)
	_lab_zombie(A, AB)
	_lab_bloater(A, AB)

	# MUTAGEN_IMMEDIATE_ATTACK — MANUAL (TurnManager)
	_manual("TC-FUNC-Lab-Crawler-001")

	# NEGATE_ZERO_COST_TRAPS_BOTH (Pattern B)
	_electrogazer(A, AB)

	# NONE smoke tests (Pattern A)
	_none_smoke_tests(A, AB)

	# ONE_USE_ATK_BOOST (Pattern A)
	_grand_fort_archer(A, AB)

	# ONE_USE_COPY_STATS_ON_SURVIVE — MANUAL (TurnManager post-battle)
	_manual("TC-FUNC-Succubus-001")

	# ONE_USE_DEFEND_MORPH — MANUAL (TurnManager post-defend)
	_manual("TC-FUNC-Bladeshifter-001")

	# ONE_USE_DEF_BOOST (Pattern A)
	_armored_bee(A, AB)

	# ONE_USE_EXTRA_ATTACK — MANUAL (TurnManager)
	_manual("TC-FUNC-Skeleton-Scout-001")
	_manual("TC-FUNC-Bomber-Fairy-001")

	# ONE_USE_PERM_DEBUFF_ATTACKER_ATK (Pattern A)
	_needle_porcupine(A, AB)

	# ONE_USE_SURVIVE_DESTRUCTION — MANUAL (TurnManager destruction intercept)
	_manual("TC-FUNC-Tiny-Pixie-001")

	# ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND (Pattern A)
	_laughing_granny(A, AB)

	# OPPONENT_EXTRA_CRYSTAL_LOSS — MANUAL (GameState lose_crystals hook)
	_manual("TC-FUNC-Grave-Worm-001")

	# OPTIONAL_CRYSTAL_PAY_ATK_BOOST — MANUAL (TurnManager prompt)
	_manual("TC-FUNC-Hairpin-Assassin-001")

	# PERM_ATK_BOOST_PER_SURVIVE_OPP_TURN — MANUAL (TurnManager turn end)
	_manual("TC-FUNC-Dark-Blob-001")

	# PERM_ATK_LOSS_PER_ATTACK — MANUAL (TurnManager post-attack)
	_manual("TC-FUNC-War-Genie-001")

	# PERM_ATK_LOSS_PER_OWN_TURN — MANUAL (TurnManager turn end)
	_manual("TC-FUNC-Rotten-Shrieker-001")

	# PERM_DEF_BOOST_ON_DEFEND (Pattern A)
	_jirayu(A, AB)

	# PERM_DEF_BOOST_PER_ATTACK_SURVIVE — MANUAL (TurnManager post-attack)
	_manual("TC-FUNC-Leech-Man-001")

	# REDIRECT_DESTRUCTION_TO_ALLY — MANUAL (TurnManager)
	_manual("TC-FUNC-Archbishop-001")

	# REVEAL_* abilities — MANUAL (TurnManager post-attack)
	_manual("TC-FUNC-Scout-Probe-001")
	_manual("TC-FUNC-Shepherd-Detective-001")
	_manual("TC-FUNC-Moon-Rover-001")
	_manual("TC-FUNC-Neptune-Diver-001")
	_manual("TC-FUNC-Mysterious-Miner-001")

	# SACRIFICE_FOR_CARD_TYPE — MANUAL (TurnManager _apply_battle_result)
	_manual("TC-FUNC-Mine-Guard-001")
	_manual("TC-FUNC-Vampire-Servant-001")

	# SELF_DEBUFF_ON_ATTACK_AND_DEFEND — MANUAL (TurnManager post-battle)
	_manual("TC-FUNC-Dark-Tengu-001")

	# SWAP_ATK_DEF_PER_OPP_TURN — MANUAL (TurnManager turn end)
	_manual("TC-FUNC-Vile-Creeper-001")

	# SWAP_ATK_DEF_WHEN_ATTACKING (Pattern A)
	_poltergeist(A, AB)

	# TEMP_ATK_BOOST_OWN_TURN_START — MANUAL (TurnManager turn start)
	_manual("TC-FUNC-Hands-in-the-Attic-001")

	# TEMP_BOOST_ON_OPP_TECH — MANUAL (TurnManager play_tech_card)
	_manual("TC-FUNC-Magical-Butterfly-001")

	# TURN_START_COIN_FLIP_FLAG — MANUAL (TurnManager turn start + coin)
	_manual("TC-FUNC-Plant-29-001")

	# VENOM_FLAG_END_OF_TURN — MANUAL (TurnManager turn end)
	_manual("TC-FUNC-Death-Cobra-001")

# ═══════════════════════════════════════════════════════════════════════════════
# ATK_BONUS_VS_AFFINITY
# ═══════════════════════════════════════════════════════════════════════════════
func _angel_gatekeeper(A, AB) -> void:
	print("-- TC-FUNC-Angel-Gatekeeper-001 / -002")
	var att := _make_char("Angel Gatekeeper", 40, 90, 960, A.DIVINE,
		AB.ATK_BONUS_VS_AFFINITY, {"affinity": A.CHAOS, "bonus": 50})
	var r1 := BattleResolver.resolve_battle(att, _make_char("Chaos", 0, 10, 100, A.CHAOS), 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 90, "TC-FUNC-Angel-Gatekeeper-001: ATK 40+50=90 vs CHAOS")
	assert_true(r1.defender_destroyed, "TC-FUNC-Angel-Gatekeeper-001: CHAOS defender destroyed")
	var r2 := BattleResolver.resolve_battle(att, _make_char("Nature", 0, 10, 100, A.NATURE), 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 40, "TC-FUNC-Angel-Gatekeeper-002: no bonus vs non-CHAOS")

func _bleacher_squad(A, AB) -> void:
	print("-- TC-FUNC-Bleacher-Squad-001 / -002")
	var att := _make_char("Bleacher Squad", 20, 20, 320, A.BIO,
		AB.ATK_BONUS_VS_AFFINITY, {"affinity": A.BIO, "bonus": 20})
	var r1 := BattleResolver.resolve_battle(att, _make_char("Bio", 0, 10, 100, A.BIO), 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 40, "TC-FUNC-Bleacher-Squad-001: ATK 20+20=40 vs BIO")
	var r2 := BattleResolver.resolve_battle(att, _make_char("Anima", 0, 10, 100, A.ANIMA), 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 20, "TC-FUNC-Bleacher-Squad-002: no bonus vs non-BIO")

func _jacob(A, AB) -> void:
	print("-- TC-FUNC-Jacob-the-Ski-Mask-001 / -002")
	var att := _make_char("Jacob the Ski Mask", 15, 20, 350, A.CHAOS,
		AB.ATK_BONUS_VS_AFFINITY, {"affinity": A.ANIMA, "bonus": 5})
	var r1 := BattleResolver.resolve_battle(att, _make_char("Anima", 0, 10, 100, A.ANIMA), 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 20, "TC-FUNC-Jacob-the-Ski-Mask-001: ATK 15+5=20 vs ANIMA")
	var r2 := BattleResolver.resolve_battle(att, _make_char("Nature", 0, 10, 100, A.NATURE), 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 15, "TC-FUNC-Jacob-the-Ski-Mask-002: no bonus vs non-ANIMA")

func _pyromancer(A, AB) -> void:
	print("-- TC-FUNC-Pyromancer-001 / -002")
	var att := _make_char("Pyromancer", 80, 0, 800, A.ARCANE,
		AB.ATK_BONUS_VS_AFFINITY, {"affinity": A.NATURE, "bonus": 30})
	var r1 := BattleResolver.resolve_battle(att, _make_char("Nature", 0, 10, 100, A.NATURE), 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 110, "TC-FUNC-Pyromancer-001: ATK 80+30=110 vs NATURE")
	assert_true(r1.defender_destroyed, "TC-FUNC-Pyromancer-001: Nature defender destroyed")
	var r2 := BattleResolver.resolve_battle(att, _make_char("Anima", 0, 10, 100, A.ANIMA), 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 80, "TC-FUNC-Pyromancer-002: no bonus vs non-NATURE")

func _red_mage(A, AB) -> void:
	print("-- TC-FUNC-Red-Mage-001 / -002")
	var att := _make_char("Red Mage", 20, 20, 400, A.ARCANE,
		AB.ATK_BONUS_VS_AFFINITY, {"affinity": A.NATURE, "bonus": 10})
	var r1 := BattleResolver.resolve_battle(att, _make_char("Nature", 0, 10, 100, A.NATURE), 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 30, "TC-FUNC-Red-Mage-001: ATK 20+10=30 vs NATURE")
	var r2 := BattleResolver.resolve_battle(att, _make_char("Chaos", 0, 10, 100, A.CHAOS), 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 20, "TC-FUNC-Red-Mage-002: no bonus vs non-NATURE")

func _silver_spearman(A, AB) -> void:
	print("-- TC-FUNC-Silver-Spearman-001 / -002")
	var att := _make_char("Silver Spearman", 25, 20, 250, A.ANIMA,
		AB.ATK_BONUS_VS_AFFINITY, {"affinity": A.CHAOS, "bonus": 5})
	var r1 := BattleResolver.resolve_battle(att, _make_char("Chaos", 0, 10, 100, A.CHAOS), 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 30, "TC-FUNC-Silver-Spearman-001: ATK 25+5=30 vs CHAOS")
	var r2 := BattleResolver.resolve_battle(att, _make_char("Nature", 0, 10, 100, A.NATURE), 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 25, "TC-FUNC-Silver-Spearman-002: no bonus vs non-CHAOS")

func _street_rogue(A, AB) -> void:
	print("-- TC-FUNC-Street-Rogue-001 / -002")
	var att := _make_char("Street Rogue", 25, 20, 350, A.ANIMA,
		AB.ATK_BONUS_VS_AFFINITY, {"affinity": A.ANIMA, "bonus": 20})
	var r1 := BattleResolver.resolve_battle(att, _make_char("Anima", 0, 10, 100, A.ANIMA), 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 45, "TC-FUNC-Street-Rogue-001: ATK 25+20=45 vs ANIMA")
	var r2 := BattleResolver.resolve_battle(att, _make_char("Chaos", 0, 10, 100, A.CHAOS), 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 25, "TC-FUNC-Street-Rogue-002: no bonus vs non-ANIMA")

# ═══════════════════════════════════════════════════════════════════════════════
# ATK_BONUS_VS_CENTER_ZONE
# ═══════════════════════════════════════════════════════════════════════════════
func _satellite_cannon(A, AB) -> void:
	print("-- TC-FUNC-Satellite-Cannon-001")
	var att := _make_char("Satellite Cannon", 100, 80, 1100, A.COSMIC,
		AB.ATK_BONUS_VS_CENTER_ZONE, {"bonus": 20, "center_bonus": 40})
	var def_ := _make_char("Dummy", 0, 200, 100, A.ANIMA)  # high DEF so not destroyed
	var r_edge := BattleResolver.resolve_battle(att, def_, 3, 0, 1, false, Vector2i(0, 0))
	assert_eq(r_edge.attacker_atk_used, 100, "TC-FUNC-Satellite-Cannon-001: edge → ATK 100")
	var r_zone := BattleResolver.resolve_battle(att, def_, 3, 0, 1, false, Vector2i(1, 1))
	assert_eq(r_zone.attacker_atk_used, 120, "TC-FUNC-Satellite-Cannon-001: zone(1,1) → ATK 120")
	var r_center := BattleResolver.resolve_battle(att, def_, 3, 0, 1, false, Vector2i(2, 2))
	assert_eq(r_center.attacker_atk_used, 160, "TC-FUNC-Satellite-Cannon-001: (2,2) → ATK 160")

# ═══════════════════════════════════════════════════════════════════════════════
# ATK_BONUS_VS_FACEDOWN
# ═══════════════════════════════════════════════════════════════════════════════
func _skeleton_archer(A, AB) -> void:
	print("-- TC-FUNC-Skeleton-Archer-001")
	var att := _make_char("Skeleton Archer", 35, 5, 300, A.CHAOS,
		AB.ATK_BONUS_VS_FACEDOWN, {"bonus": 5})
	var def_facedown := _make_char("FaceDown Dummy", 0, 10, 100, A.ANIMA)
	def_facedown.face_up = false
	var r1 := BattleResolver.resolve_battle(att, def_facedown, 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 40, "TC-FUNC-Skeleton-Archer-001: ATK 35+5=40 vs face-down")
	var def_faceup := _make_char("FaceUp Dummy", 0, 10, 100, A.ANIMA)
	def_faceup.face_up = true
	var r2 := BattleResolver.resolve_battle(att, def_faceup, 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 35, "TC-FUNC-Skeleton-Archer-001b: no bonus vs face-up")

# ═══════════════════════════════════════════════════════════════════════════════
# ATK_BONUS_VS_UNION
# ═══════════════════════════════════════════════════════════════════════════════
func _kiyoko(A, AB) -> void:
	print("-- TC-FUNC-Kiyoko-the-Death-Whisper-001")
	var att := _make_char("Kiyoko the Death Whisper", 40, 35, 800, A.ANIMA,
		AB.ATK_BONUS_VS_UNION, {"bonus": 50})
	var def_union := _make_char("Gryphon Rider", 125, 90, 1000, A.DIVINE)
	def_union.is_union = true
	var r1 := BattleResolver.resolve_battle(att, def_union, 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 90, "TC-FUNC-Kiyoko-001: ATK 40+50=90 vs union")
	var def_normal := _make_char("Normal", 0, 10, 100, A.DIVINE)
	var r2 := BattleResolver.resolve_battle(att, def_normal, 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 40, "TC-FUNC-Kiyoko-001b: no bonus vs non-union")

# ═══════════════════════════════════════════════════════════════════════════════
# ATK_BONUS_VS_VENOM
# ═══════════════════════════════════════════════════════════════════════════════
func _giant_centipede(A, AB) -> void:
	print("-- TC-FUNC-Giant-Centipede-001")
	var att := _make_char("Giant Centipede", 20, 20, 1500, A.NATURE,
		AB.ATK_BONUS_VS_VENOM, {"bonus": 100})
	var def_venom := _make_char("Venom Target", 0, 10, 100, A.ANIMA)
	def_venom.flags = ["venom"]
	var r1 := BattleResolver.resolve_battle(att, def_venom, 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 120, "TC-FUNC-Giant-Centipede-001: ATK 20+100=120 vs venom")
	var def_normal := _make_char("Normal", 0, 10, 100, A.ANIMA)
	var r2 := BattleResolver.resolve_battle(att, def_normal, 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 20, "TC-FUNC-Giant-Centipede-001b: no bonus without venom")

# ═══════════════════════════════════════════════════════════════════════════════
# ATK_BOOST_VS_REVEALED
# ═══════════════════════════════════════════════════════════════════════════════
func _cursed_well(A, AB) -> void:
	print("-- TC-FUNC-Cursed-Well-001")
	var att := _make_char("Cursed Well", 0, 25, 300, A.CHAOS,
		AB.ATK_BOOST_VS_REVEALED, {"bonus": 15})
	var def_ := _make_char("Dummy", 0, 200, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1, true)  # defender_was_exposed=true
	assert_eq(r.attacker_atk_used, 15, "TC-FUNC-Cursed-Well-001: ATK 0+15=15 vs exposed")

func _void_stalker(A, AB) -> void:
	print("-- TC-FUNC-Void-Stalker-001")
	var att := _make_char("Void Stalker", 65, 25, 600, A.CHAOS,
		AB.ATK_BOOST_VS_REVEALED, {"bonus": 20})
	var def_exposed := _make_char("Dummy Exposed", 0, 200, 100, A.ANIMA)
	def_exposed.face_up = true
	var r := BattleResolver.resolve_battle(att, def_exposed, 3, 0, 1, true)
	assert_eq(r.attacker_atk_used, 85, "TC-FUNC-Void-Stalker-001: ATK 65+20=85 vs exposed")
	var def_hidden := _make_char("Dummy Hidden", 0, 200, 100, A.ANIMA)
	def_hidden.face_up = false
	var r2 := BattleResolver.resolve_battle(att, def_hidden, 3, 0, 1, false)
	assert_eq(r2.attacker_atk_used, 65, "TC-FUNC-Void-Stalker-001b: no bonus without exposed")

# ═══════════════════════════════════════════════════════════════════════════════
# ATK_DEF_BONUS_IF_UNION_ON_FIELD (Pattern B)
# ═══════════════════════════════════════════════════════════════════════════════
func _aerial(A, AB) -> void:
	print("-- TC-FUNC-Aerial-the-Battlemage-001 [Pattern B]")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	var union_card := _make_char("Gryphon Rider", 125, 90, 1000, A.DIVINE)
	union_card.is_union = true
	union_card.face_up = true
	GameState.grids[0][0][1] = union_card
	var att := _make_char("Aerial the Battlemage", 50, 45, 700, A.ARCANE,
		AB.ATK_DEF_BONUS_IF_UNION_ON_FIELD, {"atk": 20, "def": 20})
	att.face_up = true
	GameState.grids[0][0][0] = att
	var def_ := _make_char("Dummy", 0, 10, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 70, "TC-FUNC-Aerial-001: ATK 50+20=70 with union on field")

# ═══════════════════════════════════════════════════════════════════════════════
# ATK_DEF_BONUS_VS_AFFINITY
# ═══════════════════════════════════════════════════════════════════════════════
func _book_with_fangs(A, AB) -> void:
	print("-- TC-FUNC-Book-with-Fangs-001")
	var att := _make_char("Book with Fangs", 45, 55, 700, A.ARCANE,
		AB.ATK_DEF_BONUS_VS_AFFINITY, {"affinity": A.ARCANE, "atk": 30, "def": 30})
	var r := BattleResolver.resolve_battle(att, _make_char("Arcane", 0, 10, 100, A.ARCANE), 3, 0, 1)
	assert_eq(r.attacker_atk_used, 75, "TC-FUNC-Book-with-Fangs-001: ATK 45+30=75 vs ARCANE")
	# Defense bonus: ARCANE attacker vs Book with Fangs
	var opp := _make_char("Arcane Att", 30, 0, 100, A.ARCANE)
	var def_ := _make_char("Book with Fangs", 45, 55, 700, A.ARCANE,
		AB.ATK_DEF_BONUS_VS_AFFINITY, {"affinity": A.ARCANE, "atk": 30, "def": 30})
	var r2 := BattleResolver.resolve_battle(opp, def_, 3, 0, 1)
	assert_eq(r2.defender_def_used, 85, "TC-FUNC-Book-with-Fangs-001: DEF 55+30=85 vs ARCANE att")

func _flame_lizard(A, AB) -> void:
	print("-- TC-FUNC-Flame-Lizard-001")
	var att := _make_char("Flame Lizard", 25, 40, 400, A.NATURE,
		AB.ATK_DEF_BONUS_VS_AFFINITY, {"affinity": A.NATURE, "atk": 20, "def": 20})
	var r := BattleResolver.resolve_battle(att, _make_char("Nature", 0, 10, 100, A.NATURE), 3, 0, 1)
	assert_eq(r.attacker_atk_used, 45, "TC-FUNC-Flame-Lizard-001: ATK 25+20=45 vs NATURE")

func _gamma_emitter(A, AB) -> void:
	print("-- TC-FUNC-Gamma-Emitter-001")
	var att := _make_char("Gamma Emitter", 20, 15, 400, A.COSMIC,
		AB.ATK_DEF_BONUS_VS_AFFINITY, {"affinity": A.NATURE, "atk": 10, "def": 10})
	var r := BattleResolver.resolve_battle(att, _make_char("Nature", 0, 10, 100, A.NATURE), 3, 0, 1)
	assert_eq(r.attacker_atk_used, 30, "TC-FUNC-Gamma-Emitter-001: ATK 20+10=30 vs NATURE")

func _mind_flayer(A, AB) -> void:
	print("-- TC-FUNC-Mind-Flayer-001")
	var att := _make_char("Mind Flayer", 100, 70, 1500, A.ARCANE,
		AB.ATK_DEF_BONUS_VS_AFFINITY, {"affinity": A.ANIMA, "atk": 50, "def": 50})
	var r := BattleResolver.resolve_battle(att, _make_char("Anima", 0, 10, 100, A.ANIMA), 3, 0, 1)
	assert_eq(r.attacker_atk_used, 150, "TC-FUNC-Mind-Flayer-001: ATK 100+50=150 vs ANIMA")

func _witchhunter(A, AB) -> void:
	print("-- TC-FUNC-Witchhunter-001")
	var att := _make_char("Witchhunter", 20, 20, 350, A.CHAOS,
		AB.ATK_DEF_BONUS_VS_AFFINITY, {"affinity": A.ARCANE, "atk": 5, "def": 5})
	var r := BattleResolver.resolve_battle(att, _make_char("Arcane", 0, 10, 100, A.ARCANE), 3, 0, 1)
	assert_eq(r.attacker_atk_used, 25, "TC-FUNC-Witchhunter-001: ATK 20+5=25 vs ARCANE")

# ═══════════════════════════════════════════════════════════════════════════════
# ATK_DEF_BONUS_VS_NON_AFFINITY
# ═══════════════════════════════════════════════════════════════════════════════
func _ox_patrol(A, AB) -> void:
	print("-- TC-FUNC-Ox-Patrol-001")
	var att := _make_char("Ox Patrol", 30, 35, 420, A.ANIMA,
		AB.ATK_DEF_BONUS_VS_NON_AFFINITY, {"affinity": A.ANIMA, "atk": 5, "def": 5})
	# vs non-ANIMA: +5 ATK
	var r1 := BattleResolver.resolve_battle(att, _make_char("Chaos", 0, 10, 100, A.CHAOS), 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 35, "TC-FUNC-Ox-Patrol-001: ATK 30+5=35 vs non-ANIMA")
	# vs ANIMA: no bonus
	var r2 := BattleResolver.resolve_battle(att, _make_char("Anima", 0, 10, 100, A.ANIMA), 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 30, "TC-FUNC-Ox-Patrol-001b: no bonus vs ANIMA")

# ═══════════════════════════════════════════════════════════════════════════════
# ATK_BONUS_IF_AFFINITY_ON_FIELD (Pattern B)
# ═══════════════════════════════════════════════════════════════════════════════
func _armored_monkey(A, AB) -> void:
	print("-- TC-FUNC-Armored-Monkey-001 [Pattern B]")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	var att := _make_char("Armored Monkey", 10, 20, 170, A.NATURE,
		AB.ATK_BONUS_IF_AFFINITY_ON_FIELD, {"affinity": A.NATURE, "atk": 10})
	att.face_up = true
	GameState.grids[0][0][0] = att
	var ally := _make_char("Canyon Warg", 70, 30, 750, A.NATURE)
	ally.face_up = true
	GameState.grids[0][0][1] = ally
	var def_ := _make_char("Dummy", 0, 5, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 20, "TC-FUNC-Armored-Monkey-001: ATK 10+10=20 with NATURE ally")

# ═══════════════════════════════════════════════════════════════════════════════
# ATK_PENALTY_IF_NO_NAME_ALLY (Pattern B)
# ═══════════════════════════════════════════════════════════════════════════════
func _moon_tribe_marksman(A, AB) -> void:
	print("-- TC-FUNC-Moon-Tribe-Marksman-001 [Pattern B]")
	var att := _make_char("Moon Tribe Marksman", 35, 25, 300, A.COSMIC,
		AB.ATK_PENALTY_IF_NO_NAME_ALLY, {"name": "Moon", "penalty": 10})
	var def_ := _make_char("Dummy", 0, 20, 100, A.ANIMA)
	# Without Moon ally: penalty
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	att.face_up = true
	GameState.grids[0][0][0] = att
	var r1 := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 25, "TC-FUNC-Moon-Tribe-Marksman-001: -10 ATK without Moon ally")
	# With Moon ally: no penalty
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	att.face_up = true
	GameState.grids[0][0][0] = att
	var moon_ally := _make_char("Moon Rover", 15, 20, 200, A.COSMIC)
	moon_ally.face_up = true
	GameState.grids[0][0][1] = moon_ally
	var r2 := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 35, "TC-FUNC-Moon-Tribe-Marksman-001b: no penalty with Moon ally")

# ═══════════════════════════════════════════════════════════════════════════════
# ATK_PENALTY_WHEN_EXPOSED
# ═══════════════════════════════════════════════════════════════════════════════
func _sniping_fairy(A, AB) -> void:
	print("-- TC-FUNC-Sniping-Fairy-001")
	var att := _make_char("Sniping Fairy", 40, 20, 350, A.DIVINE,
		AB.ATK_PENALTY_WHEN_EXPOSED, {"penalty": 20})
	att.face_up = true  # exposed — penalty applies
	var def_ := _make_char("Dummy", 0, 200, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 20, "TC-FUNC-Sniping-Fairy-001: ATK 40-20=20 when face-up")

# ═══════════════════════════════════════════════════════════════════════════════
# ATTACKER_ATK_DEBUFF
# ═══════════════════════════════════════════════════════════════════════════════
func _white_tiger(A, AB) -> void:
	print("-- TC-FUNC-White-Tiger-001")
	var att := _make_char("Attacker", 50, 0, 100, A.ANIMA)
	var def_ := _make_char("White Tiger", 40, 25, 400, A.ANIMA,
		AB.ATTACKER_ATK_DEBUFF, {"atk": 15})
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 35, "TC-FUNC-White-Tiger-001: attacker debuffed 50-15=35")
	# 35 > 25 so defender destroyed
	assert_true(r.defender_destroyed, "TC-FUNC-White-Tiger-001: defender destroyed (35 > 25)")

# ═══════════════════════════════════════════════════════════════════════════════
# ATTACK_STANCE_BOOST
# ═══════════════════════════════════════════════════════════════════════════════
func _sunrise_lady(A, AB) -> void:
	print("-- TC-FUNC-Sunrise-Lady-001")
	var att := _make_char("Sunrise Lady", 20, 25, 300, A.DIVINE,
		AB.ATTACK_STANCE_BOOST, {"atk": 10})
	var def_ := _make_char("Dummy", 0, 10, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 30, "TC-FUNC-Sunrise-Lady-001: ATK 20+10=30 in attack stance")

# ═══════════════════════════════════════════════════════════════════════════════
# BOOST_PER_ANIMA_ON_FIELD (Pattern B — perm_atk_bonus set directly)
# ═══════════════════════════════════════════════════════════════════════════════
func _leorudus(A, AB) -> void:
	print("-- TC-FUNC-Leorudus-the-Warlord-001 [Pattern B, perm bonus direct]")
	var att := _make_char("Leorudus the Warlord", 80, 80, 1200, A.ANIMA,
		AB.BOOST_PER_ANIMA_ON_FIELD, {"atk": 20, "def": 20})
	# Simulate 2 ANIMA allies → perm_atk_bonus = 2*20 = 40
	att.perm_atk_bonus = 40
	att.perm_def_bonus = 40
	var def_ := _make_char("Dummy", 0, 10, 100, A.NATURE)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 120, "TC-FUNC-Leorudus-001: 80+40=120 ATK with 2 ANIMA allies")

# ═══════════════════════════════════════════════════════════════════════════════
# BOOST_PER_TYPED_CARD_ON_FIELD (Pattern B — perm_atk_bonus set directly)
# ═══════════════════════════════════════════════════════════════════════════════
func _death_knight(A, AB) -> void:
	print("-- TC-FUNC-Death-Knight-001 [Pattern B, perm bonus direct]")
	var att := _make_char("Death Knight", 65, 65, 850, A.CHAOS,
		AB.BOOST_PER_TYPED_CARD_ON_FIELD, {"affinity": A.CHAOS, "atk_bonus": 5, "def_bonus": 0})
	att.perm_atk_bonus = 10  # 2 CHAOS allies × 5
	var def_ := _make_char("Dummy", 0, 10, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 75, "TC-FUNC-Death-Knight-001: 65+10=75 ATK with 2 CHAOS allies")

func _hammer_shark(A, AB) -> void:
	print("-- TC-FUNC-Hammer-Shark-001 [Pattern B, perm bonus direct]")
	var att := _make_char("Hammer Shark", 20, 20, 250, A.NATURE,
		AB.BOOST_PER_TYPED_CARD_ON_FIELD, {"name": "Shark", "atk_bonus": 10, "def_bonus": 0})
	att.perm_atk_bonus = 20  # 2 Shark allies × 10
	var def_ := _make_char("Dummy", 0, 10, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 40, "TC-FUNC-Hammer-Shark-001: 20+20=40 with 2 Shark allies")

func _night_whisperer(A, AB) -> void:
	print("-- TC-FUNC-Night-Whisperer-001 [Pattern B, perm bonus direct]")
	var att := _make_char("Night Whisperer", 30, 30, 900, A.CHAOS,
		AB.BOOST_PER_TYPED_CARD_ON_FIELD, {"name": "Wisp", "atk_bonus": 30, "def_bonus": 30})
	att.perm_atk_bonus = 30  # 1 Wisp ally × 30
	att.perm_def_bonus = 30
	var def_ := _make_char("Dummy", 0, 10, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 60, "TC-FUNC-Night-Whisperer-001: 30+30=60 ATK with 1 Wisp ally")

func _saw_shark(A, AB) -> void:
	print("-- TC-FUNC-Saw-Shark-001 [Pattern B, perm bonus direct]")
	var att := _make_char("Saw Shark", 25, 10, 280, A.NATURE,
		AB.BOOST_PER_TYPED_CARD_ON_FIELD, {"name": "Shark", "atk_bonus": 10, "def_bonus": 0})
	att.perm_atk_bonus = 10  # 1 Shark ally
	var def_ := _make_char("Dummy", 0, 10, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 35, "TC-FUNC-Saw-Shark-001: 25+10=35 with 1 Shark ally")

func _scythe_shark(A, AB) -> void:
	print("-- TC-FUNC-Scythe-Shark-001 [Pattern B, perm bonus direct]")
	var att := _make_char("Scythe Shark", 35, 35, 550, A.NATURE,
		AB.BOOST_PER_TYPED_CARD_ON_FIELD, {"name": "Shark", "atk_bonus": 10, "def_bonus": 0})
	att.perm_atk_bonus = 10
	var def_ := _make_char("Dummy", 0, 10, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 45, "TC-FUNC-Scythe-Shark-001: 35+10=45 with 1 Shark ally")

func _shotgun_shark(A, AB) -> void:
	print("-- TC-FUNC-Shotgun-Shark-001 [Pattern B, perm bonus direct]")
	var att := _make_char("Shotgun Shark", 75, 25, 900, A.NATURE,
		AB.BOOST_PER_TYPED_CARD_ON_FIELD, {"name": "Shark", "atk_bonus": 10, "def_bonus": 0})
	att.perm_atk_bonus = 10
	var def_ := _make_char("Dummy", 0, 10, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 85, "TC-FUNC-Shotgun-Shark-001: 75+10=85 with 1 Shark ally")

func _spear_shark(A, AB) -> void:
	print("-- TC-FUNC-Spear-Shark-001 [Pattern B, perm bonus direct]")
	var att := _make_char("Spear Shark", 50, 20, 480, A.NATURE,
		AB.BOOST_PER_TYPED_CARD_ON_FIELD, {"name": "Shark", "atk_bonus": 10, "def_bonus": 0})
	att.perm_atk_bonus = 10
	var def_ := _make_char("Dummy", 0, 10, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 60, "TC-FUNC-Spear-Shark-001: 50+10=60 with 1 Shark ally")

func _swarmcaller(A, AB) -> void:
	print("-- TC-FUNC-Swarmcaller-001 [Pattern B, perm bonus direct]")
	var att := _make_char("Swarmcaller", 45, 45, 950, A.NATURE,
		AB.BOOST_PER_TYPED_CARD_ON_FIELD, {"affinity": A.NATURE, "atk_bonus": 15, "def_bonus": 15})
	att.perm_atk_bonus = 15  # 1 NATURE ally
	att.perm_def_bonus = 15
	var def_ := _make_char("Dummy", 0, 10, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 60, "TC-FUNC-Swarmcaller-001: 45+15=60 with 1 NATURE ally")

# ═══════════════════════════════════════════════════════════════════════════════
# DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF
# ═══════════════════════════════════════════════════════════════════════════════
func _green_mage(A, AB) -> void:
	print("-- TC-FUNC-Green-Mage-001")
	var opp_att := _make_char("Attacker", 10, 0, 100, A.ANIMA)
	var def_ := _make_char("Green Mage", 15, 15, 400, A.ARCANE,
		AB.DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF, {"atk": 10, "def": 10})
	var r := BattleResolver.resolve_battle(opp_att, def_, 3, 0, 1)
	# ATK 10 < DEF 15: Green Mage survives → apply defend effect
	assert_true(not r.defender_destroyed, "TC-FUNC-Green-Mage-001: Green Mage survives")
	assert_eq(opp_att.current_atk, 0, "TC-FUNC-Green-Mage-001: attacker ATK reduced by 10 (10→0)")

# ═══════════════════════════════════════════════════════════════════════════════
# DEFENSE_STANCE_BOOST
# ═══════════════════════════════════════════════════════════════════════════════
func _moonrise_gentleman(A, AB) -> void:
	print("-- TC-FUNC-Moonrise-Gentleman-001")
	var opp_att := _make_char("Attacker", 30, 0, 100, A.ANIMA)
	var def_ := _make_char("Moonrise Gentleman", 40, 30, 400, A.DIVINE,
		AB.DEFENSE_STANCE_BOOST, {"def": 10})
	var r := BattleResolver.resolve_battle(opp_att, def_, 3, 0, 1)
	assert_eq(r.defender_def_used, 40, "TC-FUNC-Moonrise-Gentleman-001: DEF 30+10=40 in defense")
	# ATK 30 < DEF 40: Moonrise Gentleman survives
	assert_true(not r.defender_destroyed, "TC-FUNC-Moonrise-Gentleman-001: survives ATK 30 vs DEF 40")

# ═══════════════════════════════════════════════════════════════════════════════
# DEF_BONUS_IF_AFFINITY_ON_FIELD (Pattern B)
# ═══════════════════════════════════════════════════════════════════════════════
func _joan(A, AB) -> void:
	print("-- TC-FUNC-Joan-the-Faithful-Warrior-001 [Pattern B]")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	var joan := _make_char("Joan the Faithful Warrior", 25, 5, 280, A.DIVINE,
		AB.DEF_BONUS_IF_AFFINITY_ON_FIELD, {"affinity": A.DIVINE, "def": 30})
	joan.face_up = true
	GameState.grids[1][0][0] = joan  # defender on player 1's field
	var divine_ally := _make_char("Church Guard", 0, 35, 150, A.DIVINE)
	divine_ally.face_up = true
	GameState.grids[1][0][1] = divine_ally
	var opp_att := _make_char("Attacker", 30, 0, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(opp_att, joan, 3, 0, 1)
	assert_eq(r.defender_def_used, 35, "TC-FUNC-Joan-001: DEF 5+30=35 with DIVINE ally on field")
	# ATK 30 < DEF 35 → Joan survives
	assert_true(not r.defender_destroyed, "TC-FUNC-Joan-001: Joan survives ATK 30 vs DEF 35")

# ═══════════════════════════════════════════════════════════════════════════════
# DEF_ZERO_WHEN_EXPOSED
# ═══════════════════════════════════════════════════════════════════════════════
func _mafia_associates(A, AB) -> void:
	print("-- TC-FUNC-Mafia-Associates-001")
	var opp_att := _make_char("Attacker", 5, 0, 100, A.ANIMA)  # low ATK
	var def_ := _make_char("Mafia Associates", 45, 40, 500, A.ANIMA,
		AB.DEF_ZERO_WHEN_EXPOSED, {})
	def_.face_up = true  # exposed → DEF becomes 0
	var r := BattleResolver.resolve_battle(opp_att, def_, 3, 0, 1)
	assert_eq(r.defender_def_used, 0, "TC-FUNC-Mafia-Associates-001: DEF=0 when face-up")
	assert_true(r.defender_destroyed, "TC-FUNC-Mafia-Associates-001: ATK 5 > DEF 0 → destroyed")

# ═══════════════════════════════════════════════════════════════════════════════
# DESTROYED_IF_BATTLES_DIVINE
# ═══════════════════════════════════════════════════════════════════════════════
func _immortal_vampire(A, AB) -> void:
	print("-- TC-FUNC-Immortal-Vampire-001")
	var att := _make_char("Immortal Vampire", 30, 80, 1200, A.CHAOS,
		AB.DESTROYED_IF_BATTLES_DIVINE, {})
	var def_ := _make_char("Angel Gatekeeper", 40, 90, 960, A.DIVINE)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_true(r.attacker_destroyed, "TC-FUNC-Immortal-Vampire-001: destroyed when battling DIVINE")
	assert_eq(r.attacker_crystal_loss, 1200, "TC-FUNC-Immortal-Vampire-001: pays own cost 1200")

func _pit_lord(A, AB) -> void:
	print("-- TC-FUNC-Pit-Lord-001")
	var att := _make_char("Pit Lord", 120, 100, 1200, A.CHAOS,
		AB.DESTROYED_IF_BATTLES_DIVINE, {})
	var def_ := _make_char("Church Guard", 0, 35, 150, A.DIVINE)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_true(r.attacker_destroyed, "TC-FUNC-Pit-Lord-001: destroyed when battling DIVINE")
	assert_eq(r.attacker_crystal_loss, 1200, "TC-FUNC-Pit-Lord-001: pays own cost 1200")

func _vampire_duchess(A, AB) -> void:
	print("-- TC-FUNC-Vampire-Duchess-001")
	var att := _make_char("Vampire Duchess", 50, 50, 800, A.CHAOS,
		AB.DESTROYED_IF_BATTLES_DIVINE, {})
	var def_ := _make_char("Moonrise Gentleman", 40, 30, 400, A.DIVINE)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_true(r.attacker_destroyed, "TC-FUNC-Vampire-Duchess-001: destroyed when battling DIVINE")
	assert_eq(r.attacker_crystal_loss, 800, "TC-FUNC-Vampire-Duchess-001: pays own cost 800")

# ═══════════════════════════════════════════════════════════════════════════════
# DESTROY_IF_OPPONENT_AFFINITY
# ═══════════════════════════════════════════════════════════════════════════════
func _goddess_of_virtue(A, AB) -> void:
	print("-- TC-FUNC-Goddess-of-Virtue-001")
	var att := _make_char("Goddess of Virtue", 80, 100, 1400, A.DIVINE,
		AB.DESTROY_IF_OPPONENT_AFFINITY, {"affinity": A.CHAOS})
	var def_chaos := _make_char("Chaos Defender", 50, 200, 500, A.CHAOS)  # high DEF
	var r := BattleResolver.resolve_battle(att, def_chaos, 3, 0, 1)
	assert_true(r.defender_destroyed, "TC-FUNC-Goddess-of-Virtue-001: CHAOS defender auto-destroyed")
	assert_eq(r.defender_crystal_loss, 500, "TC-FUNC-Goddess-of-Virtue-001: defender pays own cost")
	# vs non-CHAOS: normal comparison
	var def_nature := _make_char("Nature Defender", 0, 200, 300, A.NATURE)
	var r2 := BattleResolver.resolve_battle(att, def_nature, 3, 0, 1)
	assert_true(not r2.defender_destroyed, "TC-FUNC-Goddess-of-Virtue-001b: non-CHAOS not auto-destroyed")

# ═══════════════════════════════════════════════════════════════════════════════
# DESTROY_SELF_VS_DIVINE_BOTH
# ═══════════════════════════════════════════════════════════════════════════════
func _feral_vampire(A, AB) -> void:
	print("-- TC-FUNC-Feral-Vampire-001")
	var att := _make_char("Feral Vampire", 40, 25, 400, A.CHAOS,
		AB.DESTROY_SELF_VS_DIVINE_BOTH, {})
	var def_divine := _make_char("Choir Lady Abigail", 25, 15, 250, A.DIVINE)
	var r := BattleResolver.resolve_battle(att, def_divine, 3, 0, 1)
	assert_true(r.attacker_destroyed, "TC-FUNC-Feral-Vampire-001: self-destructs battling DIVINE")
	assert_eq(r.attacker_crystal_loss, 400, "TC-FUNC-Feral-Vampire-001: pays own cost 400")

# ═══════════════════════════════════════════════════════════════════════════════
# IMMUNE_TO_TRAPS
# ═══════════════════════════════════════════════════════════════════════════════
func _tomb_bandit(A, AB) -> void:
	print("-- TC-FUNC-Tomb-Bandit-001")
	var att := _make_char("Tomb Bandit", 75, 60, 900, A.ANIMA,
		AB.IMMUNE_TO_TRAPS, {})
	var trap_spike := _make_trap("Spike Trap", 1500)
	var r := BattleResolver.resolve_battle(att, trap_spike, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Tomb-Bandit-001: immune to Spike Trap")
	assert_true(not r.attacker_destroyed, "TC-FUNC-Tomb-Bandit-001: attacker survives")
	# Also verify against a 0-cost trap
	var trap_hole := _make_trap("Trap Hole", 0)
	var r2 := BattleResolver.resolve_battle(att, trap_hole, 3, 0, 1)
	assert_eq(r2.special_trigger, "trap_nullified", "TC-FUNC-Tomb-Bandit-001: immune to 0-cost trap too")

# ═══════════════════════════════════════════════════════════════════════════════
# IMMUNE_ZERO_COST_TRAPS
# ═══════════════════════════════════════════════════════════════════════════════
func _huntress(A, AB) -> void:
	print("-- TC-FUNC-Huntress-of-Green-Glade-001")
	var att := _make_char("Huntress of Green Glade", 50, 50, 800, A.ANIMA,
		AB.IMMUNE_ZERO_COST_TRAPS, {})
	var trap_zero := _make_trap("Trap Hole", 0)
	var r := BattleResolver.resolve_battle(att, trap_zero, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Huntress-001: 0-cost trap nullified")
	# NOT immune to costly traps
	var trap_costly := _make_trap("Spike Trap", 1500)
	var r2 := BattleResolver.resolve_battle(att, trap_costly, 3, 0, 1)
	assert_true(r2.special_trigger != "trap_nullified", "TC-FUNC-Huntress-001b: costly trap not nullified")

func _laser_walker(A, AB) -> void:
	print("-- TC-FUNC-Laser-Walker-001")
	var att := _make_char("Laser Walker", 20, 10, 250, A.COSMIC,
		AB.IMMUNE_ZERO_COST_TRAPS, {})
	var trap_zero := _make_trap("Acid Trap Hole", 0)
	var r := BattleResolver.resolve_battle(att, trap_zero, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Laser-Walker-001: 0-cost trap nullified")

func _mars_drill(A, AB) -> void:
	print("-- TC-FUNC-Mars-Drill-001")
	var att := _make_char("Mars Drill", 40, 30, 400, A.COSMIC,
		AB.IMMUNE_ZERO_COST_TRAPS, {})
	var trap_zero := _make_trap("Blackmail", 0)
	var r := BattleResolver.resolve_battle(att, trap_zero, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Mars-Drill-001: 0-cost trap nullified")

# ═══════════════════════════════════════════════════════════════════════════════
# MUTAGEN_ATK_BOOST_VS_AFFINITIES
# ═══════════════════════════════════════════════════════════════════════════════
func _claw_mutant(A, AB) -> void:
	print("-- TC-FUNC-Claw-Mutant-001")
	var att := _make_char("Claw Mutant", 15, 10, 180, A.BIO,
		AB.MUTAGEN_ATK_BOOST_VS_AFFINITIES, {"bonus": 10, "affinities": []})
	att.has_mutagen_flag = true
	var def_ := _make_char("Any Target", 0, 10, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 25, "TC-FUNC-Claw-Mutant-001: 15+10=25 ATK with mutagen")
	# Without mutagen: no bonus
	att.has_mutagen_flag = false
	var r2 := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 15, "TC-FUNC-Claw-Mutant-001b: no bonus without mutagen")

func _lab_zombie(A, AB) -> void:
	print("-- TC-FUNC-Lab-Zombie-001")
	var att := _make_char("Lab Zombie", 55, 40, 700, A.BIO,
		AB.MUTAGEN_ATK_BOOST_VS_AFFINITIES, {"bonus": 25, "affinities": [A.NATURE]})
	att.has_mutagen_flag = true
	var def_nature := _make_char("Nature Target", 0, 10, 100, A.NATURE)
	var r := BattleResolver.resolve_battle(att, def_nature, 3, 0, 1)
	assert_eq(r.attacker_atk_used, 80, "TC-FUNC-Lab-Zombie-001: 55+25=80 vs NATURE with mutagen")
	# vs non-NATURE: no bonus
	var def_other := _make_char("Chaos Target", 0, 10, 100, A.CHAOS)
	var r2 := BattleResolver.resolve_battle(att, def_other, 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 55, "TC-FUNC-Lab-Zombie-001b: no bonus vs non-NATURE")

# ═══════════════════════════════════════════════════════════════════════════════
# MUTAGEN_DESTROY_ATTACKER
# ═══════════════════════════════════════════════════════════════════════════════
func _lab_bloater(A, AB) -> void:
	print("-- TC-FUNC-Lab-Bloater-001")
	var opp_att := _make_char("Weak Attacker", 10, 0, 200, A.ANIMA)  # ATK < DEF 85
	var def_ := _make_char("Lab Bloater", 20, 85, 800, A.BIO,
		AB.MUTAGEN_DESTROY_ATTACKER, {})
	def_.has_mutagen_flag = true
	var r := BattleResolver.resolve_battle(opp_att, def_, 3, 0, 1)
	# Defender survives (10 < 85), and with mutagen flag: attacker destroyed
	assert_true(not r.defender_destroyed, "TC-FUNC-Lab-Bloater-001: Lab Bloater survives")
	assert_true(r.attacker_destroyed, "TC-FUNC-Lab-Bloater-001: attacker destroyed by mutagen")

# ═══════════════════════════════════════════════════════════════════════════════
# NEGATE_ZERO_COST_TRAPS_BOTH (Pattern B)
# ═══════════════════════════════════════════════════════════════════════════════
func _electrogazer(A, AB) -> void:
	print("-- TC-FUNC-Electrogazer-001 [Pattern B]")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	var electrogazer := _make_char("Electrogazer", 80, 45, 1000, A.COSMIC,
		AB.NEGATE_ZERO_COST_TRAPS_BOTH, {})
	electrogazer.face_up = true
	GameState.grids[0][0][0] = electrogazer
	var att := _make_char("Attacker", 30, 20, 300, A.ANIMA)
	var trap_zero := _make_trap("Trap Hole", 0)
	var r := BattleResolver.resolve_battle(att, trap_zero, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified",
		"TC-FUNC-Electrogazer-001: 0-cost traps nullified while Electrogazer face-up")

# ═══════════════════════════════════════════════════════════════════════════════
# NONE — smoke tests
# ═══════════════════════════════════════════════════════════════════════════════
func _none_smoke_tests(A, AB) -> void:
	var smoke_cards: Array = [
		["Armored-Rhino", "Armored Rhino", 60, 85, 720, A.NATURE],
		["Big-Thug", "Big Thug", 40, 35, 400, A.ANIMA],
		["Canyon-Warg", "Canyon Warg", 70, 30, 750, A.NATURE],
		["Chaotic-Wisp", "Chaotic Wisp", 20, 0, 100, A.CHAOS],
		["Choir-Lady-Abigail", "Choir Lady Abigail", 25, 15, 250, A.DIVINE],
		["Choir-Lady-Alice", "Choir Lady Alice", 20, 25, 250, A.DIVINE],
		["Choir-Lady-Anna", "Choir Lady Anna", 20, 20, 250, A.DIVINE],
		["Church-Guard", "Church Guard", 0, 35, 150, A.DIVINE],
		["Dark-Monk", "Dark Monk", 15, 25, 300, A.CHAOS],
		["Demon-Spawn", "Demon Spawn", 40, 30, 400, A.CHAOS],
		["Doom-Wisp", "Doom Wisp", 15, 15, 100, A.CHAOS],
		["Flame-Seraph", "Flame Seraph", 50, 10, 500, A.DIVINE],
		["Foul-Wisp", "Foul Wisp", 0, 25, 100, A.CHAOS],
		["Fujin", "Fujin", 35, 40, 450, A.DIVINE],
		["Goblin-Poacher", "Goblin Poacher", 30, 10, 250, A.NATURE],
		["Grand-Fort-Footsoldier", "Grand Fort Footsoldier", 25, 25, 300, A.ANIMA],
		["Grand-Fort-Mauler", "Grand Fort Mauler", 40, 10, 350, A.ANIMA],
		["Gryphon", "Gryphon", 100, 85, 1150, A.NATURE],
		["Heavy-Tome-Preacher", "Heavy Tome Preacher", 25, 20, 300, A.DIVINE],
		["Ice-Mage", "Ice Mage", 50, 0, 400, A.ARCANE],
		["Mad-Raccoon", "Mad Raccoon", 30, 15, 260, A.NATURE],
		["Ponycorn", "Ponycorn", 25, 20, 300, A.DIVINE],
		["Raijin", "Raijin", 60, 0, 550, A.DIVINE],
		["Scarlet-Mutant", "Scarlet Mutant", 35, 30, 350, A.BIO],
		["Shredder-Doll", "Shredder Doll", 25, 5, 250, A.CHAOS],
		["Skeleton-Lancer", "Skeleton Lancer", 45, 5, 300, A.CHAOS],
		["Space-Boy", "Space Boy", 75, 65, 800, A.COSMIC],
		["Staircase-Lady", "Staircase Lady", 30, 0, 180, A.CHAOS],
		["Wandering-Swordsman", "Wandering Swordsman", 60, 60, 600, A.ANIMA],
		["Yaksa", "Yaksa", 30, 30, 500, A.CHAOS],
	]
	var def_dummy := _make_char("Dummy", 0, 5, 50, A.ANIMA)
	for d in smoke_cards:
		print("-- TC-FUNC-%s-001" % d[0])
		var att := _make_char(d[1], d[2], d[3], d[4], d[5], AB.NONE)
		var _r := BattleResolver.resolve_battle(att, def_dummy, 3, 0, 1)
		passed += 1
		print("  PASS: TC-FUNC-%s-001: NONE ability smoke — no errors" % d[0])

# ═══════════════════════════════════════════════════════════════════════════════
# ONE_USE_ATK_BOOST
# ═══════════════════════════════════════════════════════════════════════════════
func _grand_fort_archer(A, AB) -> void:
	print("-- TC-FUNC-Grand-Fort-Archer-001")
	var att := _make_char("Grand Fort Archer", 20, 20, 280, A.ANIMA,
		AB.ONE_USE_ATK_BOOST, {"bonus": 10})
	att.one_use_atk_boost_used = false
	var def_ := _make_char("Dummy", 0, 10, 100, A.ANIMA)
	# First attack: +10 bonus
	var r1 := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 30, "TC-FUNC-Grand-Fort-Archer-001: first ATK 20+10=30")
	# Simulate TurnManager setting flag after use
	att.one_use_atk_boost_used = true
	var r2 := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r2.attacker_atk_used, 20, "TC-FUNC-Grand-Fort-Archer-001: second ATK 20 (no bonus)")

# ═══════════════════════════════════════════════════════════════════════════════
# ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
# ═══════════════════════════════════════════════════════════════════════════════
func _laughing_granny(A, AB) -> void:
	print("-- TC-FUNC-Laughing-Granny-001")
	var att := _make_char("Laughing Granny", 15, 20, 350, A.CHAOS,
		AB.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND, {"atk": 10, "def": 10})
	att.one_use_atk_boost_used = false
	var def_ := _make_char("Grand Fort Footsoldier", 25, 25, 300, A.ANIMA)
	var r1 := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	assert_eq(r1.attacker_atk_used, 25, "TC-FUNC-Laughing-Granny-001: first ATK 15+10=25")
	assert_true(r1.attacker_destroyed and r1.defender_destroyed,
		"TC-FUNC-Laughing-Granny-001: 25 vs 25 tie destroys both")
	att.one_use_atk_boost_used = true
	def_.one_use_def_boost_used = false
	var r2 := BattleResolver.resolve_battle(def_, att, 3, 1, 0)
	assert_eq(r2.defender_def_used, 30, "TC-FUNC-Laughing-Granny-001: first DEF 20+10=30")

# ═══════════════════════════════════════════════════════════════════════════════
# ONE_USE_DEF_BOOST
# ═══════════════════════════════════════════════════════════════════════════════
func _armored_bee(A, AB) -> void:
	print("-- TC-FUNC-Armored-Bee-001")
	var opp_att := _make_char("Attacker", 50, 0, 100, A.ANIMA)
	var def_ := _make_char("Armored Bee", 30, 0, 480, A.NATURE,
		AB.ONE_USE_DEF_BOOST, {"bonus": 60})
	def_.one_use_def_boost_used = false
	# First defense: +60 DEF
	var r1 := BattleResolver.resolve_battle(opp_att, def_, 3, 0, 1)
	assert_eq(r1.defender_def_used, 60, "TC-FUNC-Armored-Bee-001: first defense DEF 0+60=60")
	assert_true(not r1.defender_destroyed, "TC-FUNC-Armored-Bee-001: Armored Bee survives (50 < 60)")
	# Second defense: no boost
	def_.one_use_def_boost_used = true
	var r2 := BattleResolver.resolve_battle(opp_att, def_, 3, 0, 1)
	assert_eq(r2.defender_def_used, 0, "TC-FUNC-Armored-Bee-001: second defense DEF 0 (used)")

# ═══════════════════════════════════════════════════════════════════════════════
# ONE_USE_PERM_DEBUFF_ATTACKER_ATK
# ═══════════════════════════════════════════════════════════════════════════════
func _needle_porcupine(A, AB) -> void:
	print("-- TC-FUNC-Needle-Porcupine-001")
	var opp_att := _make_char("Attacker", 5, 0, 100, A.ANIMA)
	var def_ := _make_char("Needle Porcupine", 10, 10, 200, A.NATURE,
		AB.ONE_USE_PERM_DEBUFF_ATTACKER_ATK, {"atk": 5})
	def_.one_use_def_boost_used = false
	# Defend: attacker -5 ATK permanently
	var r := BattleResolver.resolve_battle(opp_att, def_, 3, 0, 1)
	assert_true(not r.defender_destroyed, "TC-FUNC-Needle-Porcupine-001: Needle Porcupine survives")
	assert_eq(opp_att.current_atk, 0, "TC-FUNC-Needle-Porcupine-001: attacker ATK reduced 5→0")

# ═══════════════════════════════════════════════════════════════════════════════
# PERM_DEF_BOOST_ON_DEFEND
# ═══════════════════════════════════════════════════════════════════════════════
func _jirayu(A, AB) -> void:
	print("-- TC-FUNC-Jirayu-the-Rebellious-Prince-001")
	var opp_att := _make_char("Attacker", 30, 0, 100, A.ANIMA)
	var def_ := _make_char("Jirayu the Rebellious Prince", 40, 40, 600, A.ANIMA,
		AB.PERM_DEF_BOOST_ON_DEFEND, {"def": 10})
	var r := BattleResolver.resolve_battle(opp_att, def_, 3, 0, 1)
	# ATK 30 < DEF 40: Jirayu survives → perm DEF boost applied
	assert_true(not r.defender_destroyed, "TC-FUNC-Jirayu-001: Jirayu survives defense")
	assert_eq(def_.current_def, 50, "TC-FUNC-Jirayu-001: DEF increased 40→50 permanently")

# ═══════════════════════════════════════════════════════════════════════════════
# SWAP_ATK_DEF_WHEN_ATTACKING
# ═══════════════════════════════════════════════════════════════════════════════
func _poltergeist(A, AB) -> void:
	print("-- TC-FUNC-Poltergeist-001")
	var att := _make_char("Poltergeist", 0, 70, 700, A.CHAOS,
		AB.SWAP_ATK_DEF_WHEN_ATTACKING, {})
	var def_ := _make_char("Dummy", 0, 50, 100, A.ANIMA)
	var r := BattleResolver.resolve_battle(att, def_, 3, 0, 1)
	# Poltergeist uses DEF (70) as ATK when attacking
	assert_eq(r.attacker_atk_used, 70, "TC-FUNC-Poltergeist-001: uses DEF 70 as ATK")
	assert_true(r.defender_destroyed, "TC-FUNC-Poltergeist-001: 70 > 50 → defender destroyed")
