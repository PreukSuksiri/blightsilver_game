class_name DiceRoller
# Pure dice logic - no scene dependencies.

static func roll_attack_dice() -> int:
	# Roll d6; if 6, re-roll until result is 1-5
	var result := randi_range(1, 6)
	while result == 6:
		result = randi_range(1, 6)
	return result

static func roll_d6() -> int:
	return randi_range(1, 6)

static func flip_coin_first_player() -> int:
	# Returns 0 (heads) or 1 (tails)
	return randi() % 2
