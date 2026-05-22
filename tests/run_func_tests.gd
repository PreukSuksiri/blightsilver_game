extends Node
# Minimal runner for functional test suites only.
# Usage (via scene): godot --headless --path . res://tests/run_func_tests.tscn

func _ready() -> void:
	print("\n============================================================")
	print("  BLIGHTSILVER — Functional Test Runner")
	print("============================================================\n")

	var suites: Array = [
		"res://tests/test_func_characters.gd",
		"res://tests/test_func_traps.gd",
		"res://tests/test_func_techs.gd",
		"res://tests/test_func_unions.gd",
	]

	var total_pass: int = 0
	var total_fail: int = 0

	for suite_path in suites:
		print("\n>>> Running: %s" % suite_path)
		var script: GDScript = load(suite_path)
		if script == null:
			printerr("Failed to load: %s" % suite_path)
			continue
		var instance: Node = script.new()
		add_child(instance)
		await get_tree().process_frame
		total_pass += instance.passed
		total_fail += instance.failed
		instance.queue_free()

	print("\n============================================================")
	print("  Functional tests complete: %d passed, %d failed" % [total_pass, total_fail])
	print("============================================================\n")
	get_tree().quit()
