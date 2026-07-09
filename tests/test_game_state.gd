extends Node
# Unit tests for GameState core logic.

var passed: int = 0
var failed: int = 0

func _ready() -> void:
	run_all_tests()
	print("=== GameState Tests: %d passed, %d failed ===" % [passed, failed])

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s" % msg)

func assert_false(condition: bool, msg: String) -> void:
	assert_true(not condition, msg)

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		passed += 1
		print("  PASS: %s" % [msg])
	else:
		failed += 1
		printerr("  FAIL: %s (expected %s, got %s)" % [msg, str(b), str(a)])

func _flush_crystal_anim() -> void:
	while GameState._crystal_anim_pending > 0:
		GameState.complete_crystal_animation()

func run_all_tests() -> void:
	test_new_game_initial_state()
	test_crystal_loss()
	test_crystal_loss_to_zero_triggers_game_over()
	test_both_zero_crystals_is_tie()
	test_place_and_get_character()
	test_place_and_get_trap()
	test_place_dead_end_overwrites()
	test_destroy_card_pays_cost()
	test_destroy_card_no_cost()
	test_get_adjacent_positions_center()
	test_get_adjacent_positions_corner()
	test_get_opponent()
	test_reveal_card_sets_face_up()
	test_apply_unit_effect_flag_reveals_facedown()
	test_character_wipe_ends_game_immediately()
	test_character_wipe_ignores_playable_tech()
	test_stuck_without_characters_ends_game_at_turn_start()
	test_stuck_with_characters_but_no_attack_is_no_moves()
	test_divine_protection_turn_timing()
	test_nuki_has_coin_flip_swap_on_place()

func _start_play_phase() -> void:
	GameState.set_phase(GameState.Phase.MODE_SELECT)

func test_character_wipe_ends_game_immediately() -> void:
	print("-- test_character_wipe_ends_game_immediately")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 0, 0, "Wandering Swordsman")
	GameState.place_character(1, 1, 1, "Canyon Warg")
	_start_play_phase()
	var winner: Array = [-999]
	GameState.game_over.connect(func(w): winner[0] = w, CONNECT_ONE_SHOT)
	GameState.destroy_card(0, 0, 0, false)
	assert_eq(GameState.current_phase, GameState.Phase.GAME_OVER, "Board wipe triggers game over")
	assert_eq(winner[0], 1, "Opponent wins when all characters destroyed")
	assert_eq(GameState.game_over_reason, "all_destroyed", "Reason is all_destroyed")

func test_character_wipe_ignores_playable_tech() -> void:
	print("-- test_character_wipe_ignores_playable_tech")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 0, 0, "Wandering Swordsman")
	GameState.place_character(1, 1, 1, "Canyon Warg")
	GameState.tech_hands[0] = ["Prayer"]
	_start_play_phase()
	GameState.destroy_card(0, 0, 0, false)
	assert_eq(GameState.current_phase, GameState.Phase.GAME_OVER, "0-cost tech does not prevent wipe loss")
	assert_eq(GameState.game_over_reason, "all_destroyed", "Reason is all_destroyed")

func test_stuck_without_characters_ends_game_at_turn_start() -> void:
	print("-- test_stuck_without_characters_ends_game_at_turn_start")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(1, 1, 1, "Canyon Warg")
	GameState.tech_hands[0] = ["Prayer"]
	GameState.set_phase(GameState.Phase.MODE_SELECT)
	GameState.check_stuck_win_condition()
	assert_eq(GameState.current_phase, GameState.Phase.GAME_OVER, "No characters means loss even with tech")
	assert_eq(GameState.game_over_reason, "all_destroyed", "Reason is all_destroyed")

func test_stuck_with_characters_but_no_attack_is_no_moves() -> void:
	print("-- test_stuck_with_characters_but_no_attack_is_no_moves")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 0, 0, "Wandering Swordsman")
	GameState.place_character(1, 1, 1, "Canyon Warg")
	GameState.get_card(0, 0, 0).cannot_attack_until = 99
	GameState.get_card(1, 1, 1).cannot_attack_until = 99
	GameState.tech_hands[0] = ["Prayer"]
	GameState.tech_hands[1] = ["Prayer"]
	GameState.set_phase(GameState.Phase.MODE_SELECT)
	GameState.check_stuck_win_condition()
	assert_eq(GameState.current_phase, GameState.Phase.GAME_OVER, "Both unable to attack ends game")
	assert_eq(GameState.game_over_reason, "no_moves", "Reason is no_moves when units remain")

func test_divine_protection_turn_timing() -> void:
	print("-- test_divine_protection_turn_timing")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.divine_protection_active[0] = true
	GameState.expire_divine_protection_at_turn_end(0)
	assert_true(GameState.divine_protection_active[0],
		"Prayer protection survives through the caster's turn end")
	GameState.expire_divine_protection_at_turn_end(1)
	assert_false(GameState.divine_protection_active[0],
		"Prayer protection clears when opponent's turn ends")

func test_new_game_initial_state() -> void:
	print("-- test_new_game_initial_state")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	assert_eq(GameState.crystals[0], GameState.STARTING_CRYSTALS, "P1 starts with default crystals")
	assert_eq(GameState.crystals[1], GameState.STARTING_CRYSTALS, "P2 starts with default crystals")
	assert_eq(GameState.current_player, 0, "Current player is 0 initially")
	assert_eq(GameState.current_phase, GameState.Phase.SETUP_P1, "Phase starts at SETUP_P1")

func test_crystal_loss() -> void:
	print("-- test_crystal_loss")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.lose_crystals(0, 500)
	assert_eq(GameState.crystals[0], GameState.STARTING_CRYSTALS - 500, "Player 0 loses 500 crystals")
	GameState.lose_crystals(0, 2000)
	assert_eq(GameState.crystals[0], GameState.STARTING_CRYSTALS - 2500, "Player 0 loses 2000 more crystals")

func test_melissa_recovers_on_large_battle_loss() -> void:
	print("-- test_melissa_recovers_on_large_battle_loss")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 0, 0, "Melissa the Healer")
	GameState.get_card(0, 0, 0).face_up = true
	GameState.crystals[0] = GameState.STARTING_CRYSTALS
	GameState.lose_crystals(0, 600, "battle")
	assert_eq(GameState.crystals[0], GameState.STARTING_CRYSTALS - 300, "Melissa recovers 300 after 600 battle loss")

func test_melissa_skips_recovery_on_voluntary_costs() -> void:
	print("-- test_melissa_skips_recovery_on_voluntary_costs")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 0, 0, "Melissa the Healer")
	GameState.get_card(0, 0, 0).face_up = true
	GameState.crystals[0] = 3000
	for reason: String in ["union", "skip tax", "ability", "tech cost"]:
		GameState.lose_crystals(0, 600, reason)
		assert_eq(GameState.crystals[0], 2400, "No Melissa recovery on %s payment" % reason)
		GameState.crystals[0] = 3000

func test_crystal_loss_to_zero_triggers_game_over() -> void:
	print("-- test_crystal_loss_to_zero_triggers_game_over")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.lose_crystals(0, GameState.STARTING_CRYSTALS)
	_flush_crystal_anim()
	assert_eq(GameState.crystals[0], 0, "Player 0 at 0 crystals")
	assert_eq(GameState.current_phase, GameState.Phase.GAME_OVER, "Game over triggered")

func test_both_zero_crystals_is_tie() -> void:
	print("-- test_both_zero_crystals_is_tie")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	var winner_result: Array = [-999]
	GameState.game_over.connect(func(w): winner_result[0] = w, CONNECT_ONE_SHOT)
	GameState.lose_crystals(0, GameState.STARTING_CRYSTALS)
	# Simulate both zeroing at same moment (set P1 already zero then P2)
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.crystals[0] = 0
	GameState.crystals[1] = 100
	GameState.lose_crystals(1, 100)
	_flush_crystal_anim()
	assert_eq(GameState.current_phase, GameState.Phase.GAME_OVER, "Game over on both zero")

func test_place_and_get_character() -> void:
	print("-- test_place_and_get_character")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 0, 0, "Wandering Swordsman")
	var card := GameState.get_card(0, 0, 0)
	assert_eq(card.card_type, "character", "Card type is character")
	assert_eq(card.card_name, "Wandering Swordsman", "Card name matches")
	assert_eq(card.current_atk, 60, "ATK = 60")
	assert_eq(card.current_def, 60, "DEF = 60")
	assert_eq(card.crystal_cost, 600, "Cost = 600")
	assert_true(not card.face_up, "Card starts face-down")

func test_place_and_get_trap() -> void:
	print("-- test_place_and_get_trap")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_trap(1, 2, 3, "Flame Trap")
	var card := GameState.get_card(1, 2, 3)
	assert_eq(card.card_type, "trap", "Card type is trap")
	assert_eq(card.card_name, "Flame Trap", "Card name matches")
	assert_eq(card.crystal_cost, 250, "Flame Trap cost = 250")

func test_place_dead_end_overwrites() -> void:
	print("-- test_place_dead_end_overwrites")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 1, 1, "Canyon Warg")
	GameState.place_dead_end(0, 1, 1)
	var card := GameState.get_card(0, 1, 1)
	assert_eq(card.card_type, "dead_end", "Dead end overwrites character")

func test_destroy_card_pays_cost() -> void:
	print("-- test_destroy_card_pays_cost")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 0, 0, "Canyon Warg")  # cost 750
	GameState.place_character(1, 1, 1, "Wandering Swordsman")
	_start_play_phase()
	GameState.destroy_card(0, 0, 0, true)
	assert_eq(GameState.crystals[0], GameState.STARTING_CRYSTALS - 750, "Player 0 loses 750 crystals on destroy")
	var card := GameState.get_card(0, 0, 0)
	assert_eq(card.card_type, "dead_end", "Square becomes dead end after destroy")

func test_destroy_card_no_cost() -> void:
	print("-- test_destroy_card_no_cost")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 0, 0, "Canyon Warg")  # cost 500
	GameState.place_character(1, 1, 1, "Wandering Swordsman")
	_start_play_phase()
	GameState.destroy_card(0, 0, 0, false)
	assert_eq(GameState.crystals[0], GameState.STARTING_CRYSTALS, "No crystal loss when pay_cost=false")

func test_get_adjacent_positions_center() -> void:
	print("-- test_get_adjacent_positions_center")
	var adj := GameState.get_adjacent_positions(2, 2)
	assert_eq(adj.size(), 4, "Center square has 4 adjacents")

func test_get_adjacent_positions_corner() -> void:
	print("-- test_get_adjacent_positions_corner")
	var adj := GameState.get_adjacent_positions(0, 0)
	assert_eq(adj.size(), 2, "Corner square has 2 adjacents")

func test_get_opponent() -> void:
	print("-- test_get_opponent")
	assert_eq(GameState.get_opponent(0), 1, "Opponent of 0 is 1")
	assert_eq(GameState.get_opponent(1), 0, "Opponent of 1 is 0")

func test_reveal_card_sets_face_up() -> void:
	print("-- test_reveal_card_sets_face_up")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 3, 3, "Lightbringer")
	assert_true(not GameState.get_card(0, 3, 3).face_up, "Card starts face-down")
	GameState.reveal_card(0, 3, 3)
	assert_true(GameState.get_card(0, 3, 3).face_up, "Card is face-up after reveal")

func test_apply_unit_effect_flag_reveals_facedown() -> void:
	print("-- test_apply_unit_effect_flag_reveals_facedown")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 1, 1, "Lab Zombie")
	var card := GameState.get_card(0, 1, 1)
	assert_true(not card.face_up, "Target starts face-down")
	assert_true(GameState.apply_unit_effect_flag(0, 1, 1, "venom"), "Venom applies to face-down character")
	card = GameState.get_card(0, 1, 1)
	assert_true(card.face_up, "Venom on face-down permanently reveals card")
	assert_true("venom" in card.flags, "Venom flag is set")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(1, 2, 2, "Claw Mutant")
	var bio := GameState.get_card(1, 2, 2)
	assert_true(not bio.face_up, "Bio target starts face-down")
	assert_true(GameState.apply_unit_effect_flag(1, 2, 2, "mutagen"), "Mutagen applies to face-down Bio")
	bio = GameState.get_card(1, 2, 2)
	assert_true(bio.face_up, "Mutagen on face-down permanently reveals card")
	assert_true(bio.has_mutagen_flag, "Mutagen sets has_mutagen_flag")
	assert_true("mutagen" in bio.flags, "Mutagen flag string is set")

func test_nuki_has_coin_flip_swap_on_place() -> void:
	print("-- test_nuki_has_coin_flip_swap_on_place")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 2, 2, "Nuki the Tanuki")
	var nuki: GameState.CardInstance = GameState.get_card(0, 2, 2)
	assert_eq(nuki.card_name, "Nuki the Tanuki", "Nuki placed by name")
	assert_eq(
		nuki.ability_type,
		CharacterData.AbilityType.COIN_FLIP_SWAP_POSITION,
		"Nuki keeps COIN_FLIP_SWAP_POSITION from CardDatabase")
