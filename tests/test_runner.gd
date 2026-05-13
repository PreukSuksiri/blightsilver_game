extends Node
# Runs all unit tests. Attach to a scene or run headless.
# Usage: godot --headless --script tests/test_runner.gd

func _ready() -> void:
	print("\n============================================================")
	print("  BLIGHTSILVER — Unit Test Runner")
	print("============================================================\n")

	var suites: Array = [
		"res://tests/test_dice_roller.gd",
		"res://tests/test_card_database.gd",
		"res://tests/test_game_state.gd",
		"res://tests/test_battle_resolver.gd",
	]

	for suite_path in suites:
		print("\n>>> Running: %s" % suite_path)
		var script: GDScript = load(suite_path)
		if script == null:
			printerr("Failed to load: %s" % suite_path)
			continue
		var instance: Node = script.new()
		add_child(instance)
		# Tests run in _ready of each suite
		await get_tree().process_frame
		instance.queue_free()

	print("\n============================================================")
	print("  All test suites completed.")
	print("============================================================\n")
	get_tree().quit()
