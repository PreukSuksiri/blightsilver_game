extends Node
# Regression: Pattern B hangs — overlays must emit completion so awaiters unlock.
# Run: godot --headless --path . res://tests/test_overlay_completion_signals.tscn

var passed: int = 0
var failed: int = 0

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s" % msg)

func _ready() -> void:
	print("\n=== Overlay Completion Signal Tests ===\n")
	await run_all_tests()
	print("\n=== Overlay Completion Tests: %d passed, %d failed ===\n" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func run_all_tests() -> void:
	test_pack_reroll_emits_reveal_finished()
	await test_checker_invalid_callback_clears_cover()

func test_pack_reroll_emits_reveal_finished() -> void:
	print("-- test_pack_reroll_emits_reveal_finished")
	# Do not add_child — avoids starting the full reveal animation.
	var overlay := PackOpeningOverlay.new()
	var emit_count: Array = [0]
	overlay.reveal_finished.connect(func() -> void: emit_count[0] = int(emit_count[0]) + 1)

	# Simulate the re-roll teardown path (emit before queue_free).
	overlay._emit_reveal_finished_once()
	assert_true(int(emit_count[0]) == 1,
		"reroll path emits reveal_finished so InventoryMenu await unlocks")

	overlay._emit_reveal_finished_once()
	assert_true(int(emit_count[0]) == 1,
		"reveal_finished emit is one-shot guarded")
	assert_true(overlay._anim_done,
		"emit marks animation done so later finish/reroll is a no-op")
	overlay.free()

func test_checker_invalid_callback_clears_cover() -> void:
	print("-- test_checker_invalid_callback_clears_cover")
	var invalid := Callable()
	assert_true(not invalid.is_valid(), "test uses an invalid Callable")
	await CheckerTransition.fade_out_to_battle(invalid)
	assert_true(not CheckerTransition.is_screen_covered(),
		"invalid fade_out callback clears checker cover (no black-screen freeze)")
