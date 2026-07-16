extends Node
# Tests for the Detective Tool exploration feature:
#   - detective_tool item round-trip through ExplorationItemDatabase
#   - GameState cursor override API toggles state
#   - requires_tool spot gating decision (matches ExplorationPlayer._spawn_spot)
# Run: godot --headless --path . res://tests/test_detective_tool.tscn

var passed: int = 0
var failed: int = 0

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s" % msg)

func assert_false(condition: bool, msg: String) -> void:
	assert_true(not condition, msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s (expected %s, got %s)" % [msg, str(b), str(a)])

func _ready() -> void:
	print("\n=== Detective Tool Tests ===\n")
	run_all_tests()
	print("\n=== Detective Tool Tests: %d passed, %d failed ===\n" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func run_all_tests() -> void:
	test_tool_items_present()
	test_non_tool_item_not_flagged()
	test_cursor_override_toggle()
	test_requires_tool_gating()

# The four shipped detective tools should be flagged and point at real icons.
func test_tool_items_present() -> void:
	print("-- test_tool_items_present")
	var ids: Array = [
		"tool_polaroid_camera", "tool_etf_meter", "tool_thermometer", "tool_translator",
	]
	for id: String in ids:
		var item: Dictionary = ExplorationItemDatabase.get_item(id)
		assert_false(item.is_empty(), "item '%s' exists" % id)
		assert_true(bool(item.get("detective_tool", false)), "item '%s' is detective_tool" % id)
		var icon: String = str(item.get("icon", ""))
		assert_true(ResourceLoader.exists(icon), "item '%s' icon exists: %s" % [id, icon])

# A regular key item must not be treated as a detective tool.
func test_non_tool_item_not_flagged() -> void:
	print("-- test_non_tool_item_not_flagged")
	var item: Dictionary = ExplorationItemDatabase.get_item("item_secluded_study_key")
	if item.is_empty():
		print("  (skip: sample key item not present)")
		return
	assert_false(bool(item.get("detective_tool", false)), "key item is not a detective tool")

# set_cursor_override / clear_cursor_override should toggle the override texture.
func test_cursor_override_toggle() -> void:
	print("-- test_cursor_override_toggle")
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	assert_true(GameState._cursor_override_tex == null, "no override initially")
	GameState.set_cursor_override(tex, Vector2(4, 4), Vector2(48, 48))
	assert_true(GameState._cursor_override_tex == tex, "override texture set")
	assert_eq(GameState._cursor_override_size, Vector2(48, 48), "override size set")
	assert_eq(GameState._cursor_override_hotspot, Vector2(4, 4), "override hotspot set")
	GameState.clear_cursor_override()
	assert_true(GameState._cursor_override_tex == null, "override cleared")
	# Passing null should behave like clear (and not crash).
	GameState.set_cursor_override(null, Vector2.ZERO, Vector2.ZERO)
	assert_true(GameState._cursor_override_tex == null, "null override stays cleared")

# Mirror of the gating rule in ExplorationPlayer._spawn_spot.
func _spot_shown(spot: Dictionary, active_tool_id: String) -> bool:
	var required: String = str(spot.get("requires_tool", "")).strip_edges()
	if active_tool_id.is_empty():
		return required.is_empty()
	return required == active_tool_id

func test_requires_tool_gating() -> void:
	print("-- test_requires_tool_gating")
	var normal_spot: Dictionary = {"x_norm": 0.5, "y_norm": 0.5}
	var gated_spot: Dictionary = {"x_norm": 0.5, "y_norm": 0.5, "requires_tool": "tool_thermometer"}
	assert_true(_spot_shown(normal_spot, ""), "normal spot shown with no tool")
	assert_false(_spot_shown(normal_spot, "tool_thermometer"), "normal spot hidden while tool active")
	assert_false(_spot_shown(gated_spot, ""), "gated spot hidden with no tool")
	assert_false(_spot_shown(gated_spot, "tool_translator"), "gated spot hidden with wrong tool")
	assert_true(_spot_shown(gated_spot, "tool_thermometer"), "gated spot shown with matching tool")
