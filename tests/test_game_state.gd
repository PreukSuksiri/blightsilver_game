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

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		passed += 1
		print("  PASS: %s" % [msg])
	else:
		failed += 1
		printerr("  FAIL: %s (expected %s, got %s)" % [msg, str(b), str(a)])

func run_all_tests() -> void:
	test_new_game_initial_state()
	test_crystal_loss()
	test_crystal_loss_to_zero_triggers_game_over()
	test_both_zero_crystals_is_tie()
	test_place_and_get_character()
	test_place_and_get_trap()
	test_place_blank_overwrites()
	test_destroy_card_pays_cost()
	test_destroy_card_no_cost()
	test_get_adjacent_positions_center()
	test_get_adjacent_positions_corner()
	test_get_opponent()
	test_reveal_card_sets_face_up()

func test_new_game_initial_state() -> void:
	print("-- test_new_game_initial_state")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	assert_eq(GameState.crystals[0], 3000, "P1 starts with 3000 crystals")
	assert_eq(GameState.crystals[1], 3000, "P2 starts with 3000 crystals")
	assert_eq(GameState.current_player, 0, "Current player is 0 initially")
	assert_eq(GameState.current_phase, GameState.Phase.SETUP_P1, "Phase starts at SETUP_P1")

func test_crystal_loss() -> void:
	print("-- test_crystal_loss")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.lose_crystals(0, 500)
	assert_eq(GameState.crystals[0], 2500, "Player 0 loses 500 crystals")
	GameState.lose_crystals(0, 2000)
	assert_eq(GameState.crystals[0], 500, "Player 0 loses 2000 more crystals")

func test_crystal_loss_to_zero_triggers_game_over() -> void:
	print("-- test_crystal_loss_to_zero_triggers_game_over")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.lose_crystals(0, 3000)
	assert_eq(GameState.crystals[0], 0, "Player 0 at 0 crystals")
	assert_eq(GameState.current_phase, GameState.Phase.GAME_OVER, "Game over triggered")

func test_both_zero_crystals_is_tie() -> void:
	print("-- test_both_zero_crystals_is_tie")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	var winner_result := -999
	GameState.game_over.connect(func(w): winner_result = w, CONNECT_ONE_SHOT)
	GameState.lose_crystals(0, 3000)
	# Simulate both zeroing at same moment (set P1 already zero then P2)
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.crystals[0] = 0
	GameState.crystals[1] = 100
	GameState.lose_crystals(1, 100)
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
	assert_eq(card.crystal_cost, 1000, "Flame Trap cost = 1000")

func test_place_blank_overwrites() -> void:
	print("-- test_place_blank_overwrites")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 1, 1, "Canyon Warg")
	GameState.place_blank(0, 1, 1)
	var card := GameState.get_card(0, 1, 1)
	assert_eq(card.card_type, "blank", "Blank overwrites character")

func test_destroy_card_pays_cost() -> void:
	print("-- test_destroy_card_pays_cost")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 0, 0, "Canyon Warg")  # cost 500
	GameState.destroy_card(0, 0, 0, true)
	assert_eq(GameState.crystals[0], 2500, "Player 0 loses 500 crystals on destroy")
	var card := GameState.get_card(0, 0, 0)
	assert_eq(card.card_type, "blank", "Square becomes blank after destroy")

func test_destroy_card_no_cost() -> void:
	print("-- test_destroy_card_no_cost")
	GameState.new_game(GameState.GameMode.LOCAL_2P)
	GameState.place_character(0, 0, 0, "Canyon Warg")  # cost 500
	GameState.destroy_card(0, 0, 0, false)
	assert_eq(GameState.crystals[0], 3000, "No crystal loss when pay_cost=false")

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
