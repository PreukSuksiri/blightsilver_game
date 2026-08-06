extends Node

func _ready() -> void:
	var scripts: Array = [
		"res://scripts/ExplorationPlayer.gd",
		"res://scripts/ExplorationEditor.gd",
		"res://scripts/ExplorationItemManager.gd",
		"res://autoload/GameState.gd",
		"res://resources/ExplorationNode.gd",
	]
	var ok: int = 0
	for p: String in scripts:
		var s: GDScript = load(p)
		if s != null and s.can_instantiate():
			print("  COMPILE OK: %s" % p)
			ok += 1
		else:
			printerr("  COMPILE FAIL: %s" % p)
	print("=== Compile check: %d/%d ===" % [ok, scripts.size()])
	get_tree().quit(0 if ok == scripts.size() else 1)
