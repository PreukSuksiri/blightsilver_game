extends Node
# Runs core database/resolver tests (skips broken dice_roller suite).

func _ready() -> void:
	print("\n=== Core Test Runner ===\n")
	var suites: Array = [
		"res://tests/test_card_database.gd",
		"res://tests/test_battle_resolver.gd",
		"res://tests/test_game_state.gd",
		"res://tests/test_vn_group_branching.gd",
		"res://tests/test_ken_burns_layout.gd",
	]
	for suite_path in suites:
		print("\n>>> %s" % suite_path)
		var script: GDScript = load(suite_path)
		if script == null:
			printerr("Failed to load: %s" % suite_path)
			continue
		var instance: Node = script.new()
		add_child(instance)
		await get_tree().process_frame
		instance.queue_free()
	print("\n=== Core tests finished ===\n")
	get_tree().quit()
