extends Node
# Tests Ken Burns expanded fit-width layout helpers.
# Run: godot --headless --path . res://tests/test_ken_burns_layout.tscn

var passed: int = 0
var failed: int = 0

const VIEWPORT := Vector2(1600.0, 900.0)

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s (expected %s, got %s)" % [msg, str(b), str(a)])

func assert_near(a: float, b: float, msg: String, eps: float = 0.01) -> void:
	if absf(a - b) <= eps:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s (expected %.4f, got %.4f)" % [msg, b, a])

func _ready() -> void:
	print("\n=== Ken Burns Layout Tests ===\n")
	run_all_tests()
	print("\n=== Ken Burns Layout: %d passed, %d failed ===\n" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func run_all_tests() -> void:
	test_tall_image_layout()
	test_wide_image_layout()
	test_stage_aspect_layout()
	test_pan_offset_helpers()
	test_apply_expanded_layout_on_texture_rect()

func _make_tex(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	return ImageTexture.create_from_image(img)

func test_tall_image_layout() -> void:
	var tex := _make_tex(1600, 1800)
	var layout: Dictionary = KenBurnsUtil.fit_width_layout(tex, VIEWPORT)
	var layout_size: Vector2 = layout["layout_size"]
	var base_pos: Vector2 = layout["base_position"]
	assert_eq(layout_size, Vector2(1600.0, 1800.0), "tall image keeps full height at stage width")
	assert_near(base_pos.y, -450.0, "tall image centers vertically on stage")

func test_wide_image_layout() -> void:
	var tex := _make_tex(3200, 900)
	var layout: Dictionary = KenBurnsUtil.fit_width_layout(tex, VIEWPORT)
	var layout_size: Vector2 = layout["layout_size"]
	var base_pos: Vector2 = layout["base_position"]
	assert_eq(layout_size, Vector2(1600.0, 450.0), "wide image fits width and shortens height")
	assert_near(base_pos.y, 225.0, "wide image centers with vertical margin")

func test_stage_aspect_layout() -> void:
	var tex := _make_tex(1600, 900)
	var layout: Dictionary = KenBurnsUtil.fit_width_layout(tex, VIEWPORT)
	assert_eq(layout["layout_size"], VIEWPORT, "16:9 image matches stage size")
	assert_eq(layout["base_position"], Vector2.ZERO, "16:9 image needs no offset")

func test_pan_offset_helpers() -> void:
	var kb := {
		"pan_x": 12.0,
		"pan_y": -34.0,
		"start_pan_x": 5.0,
		"start_pan_y": -9.0,
	}
	assert_eq(KenBurnsUtil.pan_offset(kb, false), Vector2(12.0, -34.0), "end pan offset")
	assert_eq(KenBurnsUtil.pan_offset(kb, true), Vector2(5.0, -9.0), "start pan offset")
	var base := Vector2(0.0, -100.0)
	assert_eq(
		KenBurnsUtil.effective_position(base, kb, true),
		Vector2(5.0, -109.0),
		"effective start position adds base offset")

func test_apply_expanded_layout_on_texture_rect() -> void:
	var tex := _make_tex(1600, 1800)
	var rect := TextureRect.new()
	add_child(rect)
	var layout: Dictionary = KenBurnsUtil.apply_expanded_layout(rect, tex, VIEWPORT)
	assert_eq(rect.stretch_mode, TextureRect.STRETCH_SCALE, "expanded layout uses scale stretch")
	assert_eq(rect.size, layout["layout_size"], "expanded rect uses layout size")
	assert_eq(rect.position, layout["base_position"], "expanded rect uses base position")
	rect.queue_free()
