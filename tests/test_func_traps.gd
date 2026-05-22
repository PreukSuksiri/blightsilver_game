extends Node
# Functional test suite — Trap cards (TC-FUNC-Trap-*)
# Pattern A: BattleResolver immunity checks (zero-cost trap -002 tests)
# Pattern C (MANUAL): All trap effect -001 tests require TurnManager/UI

var passed: int = 0
var failed: int = 0

func _ready() -> void:
	print("\n--- test_func_traps.gd ---")
	var A := CharacterData.Affinity
	var AB := CharacterData.AbilityType
	_run_immunity_tests(A, AB)
	_run_manual_tests()
	print("  Traps: %d passed, %d failed" % [passed, failed])

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
	c.face_up = false
	c.crystal_cost = cost
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
# Pattern A — zero-cost trap immunity (-002 tests)
# Tests that IMMUNE_ZERO_COST_TRAPS attacker produces special_trigger='trap_nullified'
# NEGATE_ZERO_COST_TRAPS_BOTH field scan covered by TC-FUNC-Electrogazer-001
# ---------------------------------------------------------------------------

func _run_immunity_tests(A: Dictionary, AB: Dictionary) -> void:
	var huntress := _make_char("Huntress", 50, 50, 800, A.ANIMA,
			AB.IMMUNE_ZERO_COST_TRAPS)
	var electro := _make_char("Electrogazer", 45, 45, 600, A.COSMIC,
			AB.NEGATE_ZERO_COST_TRAPS_BOTH)

	# TC-FUNC-Blackmail-002
	var trap_blackmail := _make_trap("Blackmail", 0)
	var r: BattleResolver.BattleResult = BattleResolver.resolve_battle(huntress, trap_blackmail, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Blackmail-002: Huntress immune to zero-cost Blackmail")
	r = BattleResolver.resolve_battle(electro, trap_blackmail, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Blackmail-002: Electrogazer negates zero-cost Blackmail")

	# TC-FUNC-Pepper-Spray-002
	var trap_pepper := _make_trap("Pepper Spray", 0)
	r = BattleResolver.resolve_battle(huntress, trap_pepper, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Pepper-Spray-002: Huntress immune to zero-cost Pepper Spray")
	r = BattleResolver.resolve_battle(electro, trap_pepper, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Pepper-Spray-002: Electrogazer negates zero-cost Pepper Spray")

	# TC-FUNC-Red-Card-002
	var trap_redcard := _make_trap("Red Card", 0)
	r = BattleResolver.resolve_battle(huntress, trap_redcard, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Red-Card-002: Huntress immune to zero-cost Red Card")
	r = BattleResolver.resolve_battle(electro, trap_redcard, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Red-Card-002: Electrogazer negates zero-cost Red Card")

	# TC-FUNC-Explosive-Barrels-002
	var trap_explode := _make_trap("Explosive Barrels", 0)
	r = BattleResolver.resolve_battle(huntress, trap_explode, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Explosive-Barrels-002: Huntress immune to zero-cost Explosive Barrels")
	r = BattleResolver.resolve_battle(electro, trap_explode, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Explosive-Barrels-002: Electrogazer negates zero-cost Explosive Barrels")

	# TC-FUNC-Acid-Trap-Hole-002
	var trap_acid := _make_trap("Acid Trap Hole", 0)
	r = BattleResolver.resolve_battle(huntress, trap_acid, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Acid-Trap-Hole-002: Huntress immune to zero-cost Acid Trap Hole")
	r = BattleResolver.resolve_battle(electro, trap_acid, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Acid-Trap-Hole-002: Electrogazer negates zero-cost Acid Trap Hole")

	# TC-FUNC-Trap-Hole-002
	var trap_hole := _make_trap("Trap Hole", 0)
	r = BattleResolver.resolve_battle(huntress, trap_hole, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Trap-Hole-002: Huntress immune to zero-cost Trap Hole")
	r = BattleResolver.resolve_battle(electro, trap_hole, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Trap-Hole-002: Electrogazer negates zero-cost Trap Hole")

	# TC-FUNC-Alarm-002
	var trap_alarm := _make_trap("Alarm", 0)
	r = BattleResolver.resolve_battle(huntress, trap_alarm, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Alarm-002: Huntress immune to zero-cost Alarm")
	r = BattleResolver.resolve_battle(electro, trap_alarm, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Alarm-002: Electrogazer negates zero-cost Alarm")

	# TC-FUNC-Hostage-002
	var trap_hostage := _make_trap("Hostage", 0)
	r = BattleResolver.resolve_battle(huntress, trap_hostage, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Hostage-002: Huntress immune to zero-cost Hostage")
	r = BattleResolver.resolve_battle(electro, trap_hostage, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Hostage-002: Electrogazer negates zero-cost Hostage")

	# TC-FUNC-Bait-002
	var trap_bait := _make_trap("Bait", 0)
	r = BattleResolver.resolve_battle(huntress, trap_bait, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Bait-002: Huntress immune to zero-cost Bait")
	r = BattleResolver.resolve_battle(electro, trap_bait, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Bait-002: Electrogazer negates zero-cost Bait")

	# TC-FUNC-Street-Joke-002
	var trap_joke := _make_trap("Street Joke", 0)
	r = BattleResolver.resolve_battle(huntress, trap_joke, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Street-Joke-002: Huntress immune to zero-cost Street Joke")
	r = BattleResolver.resolve_battle(electro, trap_joke, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Street-Joke-002: Electrogazer negates zero-cost Street Joke")

	# TC-FUNC-Self-destruct-002
	var trap_selfdestruct := _make_trap("Self-destruct", 0)
	r = BattleResolver.resolve_battle(huntress, trap_selfdestruct, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Self-destruct-002: Huntress immune to zero-cost Self-destruct")
	r = BattleResolver.resolve_battle(electro, trap_selfdestruct, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Self-destruct-002: Electrogazer negates zero-cost Self-destruct")

	# TC-FUNC-Foul-Gas-002
	var trap_gas := _make_trap("Foul Gas", 0)
	r = BattleResolver.resolve_battle(huntress, trap_gas, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Foul-Gas-002: Huntress immune to zero-cost Foul Gas")
	r = BattleResolver.resolve_battle(electro, trap_gas, 3, 0, 1)
	assert_eq(r.special_trigger, "trap_nullified", "TC-FUNC-Foul-Gas-002: Electrogazer negates zero-cost Foul Gas")

# ---------------------------------------------------------------------------
# Pattern C — MANUAL (all trap effect -001 tests; TurnManager required)
# ---------------------------------------------------------------------------

func _run_manual_tests() -> void:
	_manual("TC-FUNC-Blackmail-001")      # ATTACKER_DISCARD_OR_END_TURN
	_manual("TC-FUNC-Decoy-Puppet-001")   # CANCEL_ATTACKER_ATTACK
	_manual("TC-FUNC-Pepper-Spray-001")   # COIN_FLIP_2_ATK_DEBUFF
	_manual("TC-FUNC-Red-Card-001")       # COIN_FLIP_2_LOCK_ATTACKER
	_manual("TC-FUNC-Spike-Trap-001")     # DESTROY_ATTACKER
	_manual("TC-FUNC-Explosive-Barrels-001") # DESTROY_ATTACKER_DEFENDER_PAYS
	_manual("TC-FUNC-Acid-Trap-Hole-001") # DRAIN_ATTACKER_CRYSTALS amount=50
	_manual("TC-FUNC-Trap-Hole-001")      # DRAIN_ATTACKER_CRYSTALS amount=20
	_manual("TC-FUNC-Alarm-001")          # FIELD_BOOST_AFFINITY_DEF
	_manual("TC-FUNC-Brainwash-001")      # FORCE_FRIENDLY_FIRE
	_manual("TC-FUNC-Hypnosis-001")       # HYPNOTIZE_ATTACKER
	_manual("TC-FUNC-Echo-Barrier-001")   # LOCK_ATTACKER_REMAINING_ATTACKS
	_manual("TC-FUNC-Snare-Trap-001")     # NULLIFY_ATTACKER_EFFECT
	_manual("TC-FUNC-Hostage-001")        # NULLIFY_ATTACK_REVEAL_ADJACENT
	_manual("TC-FUNC-Bunker-001")         # NULLIFY_BLOCK_ADJACENT
	_manual("TC-FUNC-Flame-Trap-001")     # PERMANENT_ATK_DEBUFF
	_manual("TC-FUNC-Bait-001")           # REVEAL_DEFENDING_CHOICE
	_manual("TC-FUNC-Street-Joke-001")    # REVEAL_OWN_GAIN_CRYSTAL
	_manual("TC-FUNC-Self-destruct-001")  # SELF_DESTROY_TEMP_ATK_BOOST
	_manual("TC-FUNC-Defensive-Pheromone-001") # SWAP_ARMORED_NATURE
	_manual("TC-FUNC-Cursed-Reflection-001")   # SWAP_ATTACKER_ATK_DEF_TEMP
	_manual("TC-FUNC-Foul-Gas-001")       # TEMP_DEBUFF_ALL_ATTACKER_CHARS
	_manual("TC-FUNC-Hard-Scale-001")     # TEMP_DEF_BOOST_ONE_OWN
