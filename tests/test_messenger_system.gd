extends Node
# Smoke tests for the messenger evidence system:
# MessengerVault autoload, MessengerOverlay viewer, MessengerVaultManager editor,
# and the VNPlayer "show_messenger" beat wiring.
# Run: godot --headless --path . res://tests/test_messenger_system.tscn

var passed: int = 0
var failed: int = 0

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s" % msg)

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s (expected %s, got %s)" % [msg, str(b), str(a)])

func _ready() -> void:
	print("\n=== Messenger System Tests ===\n")
	await run_all_tests()
	print("\n=== Messenger Tests: %d passed, %d failed ===\n" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func run_all_tests() -> void:
	test_scripts_compile()
	test_vault_loads_sample()
	await test_overlay_all_mode()
	await test_overlay_tap_mode()
	test_emoji_picker_insert()
	test_vn_beat_wiring()
	test_test_scene_json()

func test_scripts_compile() -> void:
	for path: String in [
		"res://scripts/MessengerOverlay.gd",
		"res://scripts/MessengerVaultManager.gd",
		"res://scripts/MessengerEmojiPicker.gd",
		"res://autoload/MessengerVault.gd",
		"res://scripts/VNPlayer.gd",
		"res://scripts/VNEditor.gd",
		"res://autoload/MailboxManager.gd",
	]:
		var script: GDScript = load(path)
		assert_true(script != null and script.can_instantiate(),
			"script compiles: %s" % path)

func test_vault_loads_sample() -> void:
	MessengerVault.reload()
	var ids: Array = MessengerVault.get_all_ids()
	assert_true(ids.has("sample_chat"), "vault contains sample_chat id")
	var conv: Dictionary = MessengerVault.get_conversation("sample_chat")
	assert_true(not conv.is_empty(), "sample_chat conversation loads")
	assert_eq((conv.get("participants", []) as Array).size(), 3,
		"sample_chat has 3 participants")
	assert_eq((conv.get("messages", []) as Array).size(), 5,
		"sample_chat has 5 messages")
	assert_eq(str(conv.get("right_side", "")), "Nex", "right_side is Nex")
	assert_true(MessengerVault.get_conversation("no_such_id").is_empty(),
		"unknown id returns empty dict")

func test_overlay_all_mode() -> void:
	var conv: Dictionary = MessengerVault.get_conversation("sample_chat")
	var overlay: MessengerOverlay = MessengerOverlay.open_with_data(self, conv)
	await get_tree().process_frame
	assert_true(is_instance_valid(overlay), "overlay (all mode) opens")
	assert_eq(overlay._msg_vbox.get_child_count(), 5,
		"all mode shows every message immediately")
	var closed_seen: Array = [false]
	overlay.closed.connect(func() -> void: closed_seen[0] = true)
	overlay._close()
	await get_tree().process_frame
	assert_true(closed_seen[0], "closed signal emitted on close")

func test_overlay_tap_mode() -> void:
	var conv: Dictionary = MessengerVault.get_conversation("sample_chat")
	conv["reveal_mode"] = "tap"
	var overlay: MessengerOverlay = MessengerOverlay.open_with_data(self, conv)
	await get_tree().process_frame
	assert_eq(overlay._msg_vbox.get_child_count(), 1,
		"tap mode starts with first message only")
	overlay._reveal_next_message()
	overlay._reveal_next_message()
	assert_eq(overlay._msg_vbox.get_child_count(), 3,
		"tap mode reveals one message per tap")
	overlay._close()
	await get_tree().process_frame

func test_emoji_picker_insert() -> void:
	var host := Control.new()
	add_child(host)
	var le := LineEdit.new()
	le.text = "Hello "
	le.caret_column = le.text.length()
	host.add_child(le)
	MessengerEmojiPicker._insert_at_caret(le, "😀")
	assert_eq(le.text, "Hello 😀", "emoji picker inserts at caret")
	assert_eq(le.caret_column, "Hello 😀".length(), "caret moves after inserted emoji")
	host.queue_free()


func test_vn_beat_wiring() -> void:
	var vn: Control = load("res://scripts/VNPlayer.gd").new()
	assert_true(vn._beat_has_deferred_actions({"show_messenger": "sample_chat"}),
		"show_messenger beat counts as deferred action")
	assert_true(not vn._beat_has_deferred_actions({"text": "hi"}),
		"plain text beat is not deferred")
	vn.free()

func test_test_scene_json() -> void:
	var f := FileAccess.open("res://campaign/scenes/vn_messenger_test.json", FileAccess.READ)
	assert_true(f != null, "vn_messenger_test.json exists")
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	assert_true(parsed is Array, "test scene JSON is a beat array")
	var found: String = ""
	for beat: Variant in (parsed as Array):
		if beat is Dictionary and (beat as Dictionary).has("show_messenger"):
			found = str((beat as Dictionary)["show_messenger"])
	assert_eq(found, "sample_chat", "test scene references sample_chat")
	assert_true(not MessengerVault.get_conversation(found).is_empty(),
		"referenced conversation exists in vault")
