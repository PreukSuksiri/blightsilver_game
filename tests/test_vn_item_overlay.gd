extends Node
# Tests VN give_item beats waiting on ExplorationPlayer item-obtained overlays.
# Run: godot --headless --path . res://tests/test_vn_item_overlay.tscn

var passed: int = 0
var failed: int = 0

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s" % msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s (expected %s, got %s)" % [msg, str(b), str(a)])

func _ready() -> void:
	print("\n=== VN Item Overlay Tests ===\n")
	run_all_tests()
	print("\n=== VN Item Overlay Tests: %d passed, %d failed ===\n" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func run_all_tests() -> void:
	test_apply_exploration_actions_detects_give_item()
	test_item_overlay_idle_signal()
	test_vn_beat_waits_on_give_item()

func test_apply_exploration_actions_detects_give_item() -> void:
	print("-- test_apply_exploration_actions_detects_give_item")
	var vn: VNPlayer = load("res://scripts/VNPlayer.gd").new()
	var only_var: Array = [{"action": "set_var", "key": "foo", "value": "bar"}]
	assert_true(not vn._apply_exploration_actions(only_var),
		"set_var-only actions are not item grants")
	var with_item: Array = [{"action": "give_item", "key": "tool_translator", "value": ""}]
	assert_true(vn._apply_exploration_actions(with_item),
		"give_item action is detected")
	vn.free()

func test_item_overlay_idle_signal() -> void:
	print("-- test_item_overlay_idle_signal")
	var idle_seen: Array[bool] = [false]
	var cb := func() -> void: idle_seen[0] = true
	ExplorationManager.item_obtained_overlay_idle.connect(cb)
	ExplorationManager.mark_item_obtained_overlay_busy()
	assert_true(ExplorationManager.is_item_obtained_overlay_busy(),
		"overlay marked busy")
	ExplorationManager.mark_item_obtained_overlay_idle()
	assert_true(not ExplorationManager.is_item_obtained_overlay_busy(),
		"overlay marked idle")
	assert_true(idle_seen[0], "idle signal emitted once")
	ExplorationManager.mark_item_obtained_overlay_idle()
	assert_true(not ExplorationManager.is_item_obtained_overlay_busy(),
		"duplicate idle call is harmless")
	if ExplorationManager.item_obtained_overlay_idle.is_connected(cb):
		ExplorationManager.item_obtained_overlay_idle.disconnect(cb)

func test_vn_beat_waits_on_give_item() -> void:
	print("-- test_vn_beat_waits_on_give_item")
	var vn: VNPlayer = load("res://scripts/VNPlayer.gd").new()
	assert_true(vn._beat_has_side_effect_deferred(
			{"exploration_actions": [{"action": "give_item", "key": "tool_translator"}]}),
		"give_item beat counts as deferred side effect")
	vn.free()
