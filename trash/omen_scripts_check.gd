extends SceneTree

func _init() -> void:
	var paths: Array = [
		"res://scripts/OmenSelectOverlay.gd",
		"res://scripts/OmenAnointPicker.gd",
		"res://scripts/OmenEditorOverlay.gd",
		"res://scripts/OmenListPanel.gd",
	]
	for path: String in paths:
		var s: Variant = load(path)
		if s == null:
			push_error("FAILED %s" % path)
			quit(1)
		print("OK %s" % path)
	quit(0)
