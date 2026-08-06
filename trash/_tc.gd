extends Node
func _ready() -> void:
	var s: GDScript = load("res://scripts/ExplorationPlayer.gd")
	if s != null and s.can_instantiate():
		print("COMPILE OK")
	else:
		printerr("COMPILE FAIL")
	get_tree().quit()
