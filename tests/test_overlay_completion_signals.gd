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
	await test_fit_verdict_map_no_resize_spin()
	await test_stamp_view_fit_stays_bounded()
	await test_stamp_view_tiny_host_scrollbar_churn()

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

func test_fit_verdict_map_no_resize_spin() -> void:
	print("-- test_fit_verdict_map_no_resize_spin")
	DetectiveNoteManager.reset_all()
	DetectiveNoteManager.unlock_topic("ch0_demo", "library_lights")
	var host := Control.new()
	host.size = Vector2(1600, 900)
	add_child(host)
	var overlay: DetectiveNoteOverlay = DetectiveNoteOverlay.open_for_chapter(host, "ch0_demo")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(is_instance_valid(overlay), "overlay opens for fit spin test")
	overlay._fit_call_count = 0
	# Simulate export resize churn that used to recurse fit → resized → fit.
	for _i: int in range(40):
		overlay._fit_verdict_map()
		if overlay._map_scroll != null and is_instance_valid(overlay._map_scroll):
			overlay._map_scroll.size = Vector2(
				800.0 + float(_i % 3), 500.0 + float(_i % 2))
			overlay._fit_verdict_map()
	assert_true(overlay._fit_call_count < 200,
		"fit_verdict_map stays bounded under resize churn (no main-thread spin)")
	assert_true(not overlay._fitting_map,
		"fitting flag clears after fit returns")
	overlay._close()
	host.queue_free()
	await get_tree().process_frame
	DetectiveNoteManager.reset_all()

func test_stamp_view_fit_stays_bounded() -> void:
	print("-- test_stamp_view_fit_stays_bounded")
	DetectiveNoteManager.reset_all()
	DetectiveNoteManager.unlock_topic("ch0_demo", "library_lights")
	DetectiveNoteManager.apply_stamp("ch0_demo", "library_lights", "stamp_kelly")
	var host := Control.new()
	host.size = Vector2(1600, 900)
	add_child(host)
	var stamp_view: DetectiveNoteOverlay = DetectiveNoteOverlay.open_stamp_view(
		host, "ch0_demo", "library_lights")
	# Several frames must complete — a hard-freeze would never get here.
	for _i: int in range(8):
		await get_tree().process_frame
	assert_true(is_instance_valid(stamp_view),
		"stamp view still alive after several frames (no hard freeze)")
	assert_true(stamp_view._map_scroll == null,
		"stamp view has no ScrollContainer (pack-style flat overlay)")
	assert_true(stamp_view._fit_call_count == 0,
		"stamp view never calls scroll fit_verdict_map")
	stamp_view._close()
	host.queue_free()
	await get_tree().process_frame
	DetectiveNoteManager.reset_all()

func test_stamp_view_tiny_host_scrollbar_churn() -> void:
	print("-- test_stamp_view_tiny_host_scrollbar_churn")
	DetectiveNoteManager.reset_all()
	DetectiveNoteManager.unlock_topic("ch0_demo", "library_lights")
	DetectiveNoteManager.apply_stamp("ch0_demo", "library_lights", "stamp_kelly")
	var host := Control.new()
	# Tight viewport — old path would thrash ScrollContainer; stamp must stay flat.
	host.size = Vector2(900, 500)
	add_child(host)
	var stamp_view: DetectiveNoteOverlay = DetectiveNoteOverlay.open_stamp_view(
		host, "ch0_demo", "library_lights")
	for _i: int in range(4):
		await get_tree().process_frame
	assert_true(is_instance_valid(stamp_view), "stamp view opens on tiny host")
	assert_true(stamp_view._map_scroll == null,
		"stamp UI bypasses ScrollContainer on tiny host")
	assert_true(stamp_view._fit_call_count == 0,
		"stamp open never runs fit_verdict_map")
	assert_true(stamp_view._map != null and is_instance_valid(stamp_view._map),
		"stamp map exists")
	# Force host size churn that used to toggle scrollbar width.
	if stamp_view._map_host != null and is_instance_valid(stamp_view._map_host):
		var base: Vector2 = stamp_view._map_host.size
		for i: int in range(12):
			var delta: float = 16.0 if (i % 2) == 0 else -16.0
			stamp_view._map_host.size = Vector2(maxf(64.0, base.x + delta), base.y)
			stamp_view._layout_stamp_map()
			await get_tree().process_frame
	assert_true(is_instance_valid(stamp_view),
		"stamp view survives host-size churn")
	assert_true(stamp_view._fit_call_count == 0,
		"layout_stamp_map never arms scroll fit")
	assert_true(not stamp_view._fitting_map, "fitting flag stays clear")
	assert_true(stamp_view.process_mode == Node.PROCESS_MODE_ALWAYS,
		"stamp overlay uses PROCESS_MODE_ALWAYS")
	stamp_view._close()
	host.queue_free()
	await get_tree().process_frame
	DetectiveNoteManager.reset_all()
