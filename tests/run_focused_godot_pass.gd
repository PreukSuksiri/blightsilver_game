extends Node
# Runner for residual audit Godot pass.
# Usage: godot --headless --path . res://tests/run_focused_godot_pass.tscn

func _ready() -> void:
	print("\n============================================================")
	print("  BLIGHTSILVER — Focused Godot Pass Runner")
	print("============================================================\n")
	while not UnionDatabase.is_bootstrapped():
		await get_tree().process_frame
	var script: GDScript = load("res://tests/test_focused_godot_pass.gd")
	if script == null:
		printerr("Failed to load focused godot pass suite")
		get_tree().quit(1)
		return
	var instance: Node = script.new()
	add_child(instance)
	var guard: int = 0
	while not bool(instance.get("done")) and guard < 600:
		await get_tree().process_frame
		guard += 1
	var pass_n: int = int(instance.get("passed"))
	var fail_n: int = int(instance.get("failed"))
	print("\n============================================================")
	print("  Focused Godot pass complete: %d passed, %d failed" % [pass_n, fail_n])
	print("============================================================\n")
	instance.queue_free()
	get_tree().quit(1 if fail_n > 0 else 0)
