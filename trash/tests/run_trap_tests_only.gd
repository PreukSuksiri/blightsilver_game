extends SceneTree

func _init() -> void:
	print("\n>>> Running: res://tests/test_func_traps.gd")
	var script: GDScript = load("res://tests/test_func_traps.gd")
	var instance: Node = script.new()
	root.add_child(instance)
	await process_frame
	instance.queue_free()
	quit()
