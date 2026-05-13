extends Node
# Unit tests for DiceRoller.

var passed: int = 0
var failed: int = 0

func _ready() -> void:
	run_all_tests()
	print("=== DiceRoller Tests: %d passed, %d failed ===" % [passed, failed])

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s" % msg)

func run_all_tests() -> void:
	test_attack_roll_never_six()
	test_attack_roll_always_1_to_5()
	test_first_player_roll_binary()
	test_d6_range()

func test_attack_roll_never_six() -> void:
	print("-- test_attack_roll_never_six (1000 rolls)")
	var got_six := false
	for i in range(1000):
		if DiceRoller.roll_attack_dice() == 6:
			got_six = true
			break
	assert_true(not got_six, "Attack dice never returns 6 in 1000 rolls")

func test_attack_roll_always_1_to_5() -> void:
	print("-- test_attack_roll_always_1_to_5 (1000 rolls)")
	var in_range := true
	for i in range(1000):
		var r := DiceRoller.roll_attack_dice()
		if r < 1 or r > 5:
			in_range = false
			break
	assert_true(in_range, "Attack dice always returns 1-5")

func test_first_player_roll_binary() -> void:
	print("-- test_first_player_roll_binary")
	var results := {}
	for i in range(200):
		var r := DiceRoller.roll_first_player()
		results[r] = true
	assert_true(results.has(0), "First player roll can return 0")
	assert_true(results.has(1), "First player roll can return 1")
	assert_true(results.size() == 2, "First player roll only returns 0 or 1")

func test_d6_range() -> void:
	print("-- test_d6_range (500 rolls)")
	var seen := {}
	var all_in_range := true
	for i in range(500):
		var r := DiceRoller.roll_d6()
		if r < 1 or r > 6:
			all_in_range = false
		seen[r] = true
	assert_true(all_in_range, "D6 always returns 1-6")
	assert_true(seen.size() == 6, "D6 returns all values 1-6 in 500 rolls")
