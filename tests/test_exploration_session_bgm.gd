extends Node
# Tests exploration session BGM snapshot preservation across Save and Exit.
# Run: godot --headless --path . res://tests/test_exploration_session_bgm.tscn

const GRAPH_PATH := "res://exploration/graphs/ch0_s1_blackout_library.json"
const EXPLORATION_BGM := "res://assets/audio/bgm_storytelling_2.mp3"

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
	print("\n=== Exploration Session BGM Tests ===\n")
	run_all_tests()
	print("\n=== Exploration Session BGM Tests: %d passed, %d failed ===\n" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func run_all_tests() -> void:
	test_session_bgm_preserved_after_title_menu_audio()
	test_restore_queues_saved_session_bgm()

func _start_test_session() -> void:
	ExplorationManager.launch_params = {"force_fresh": true}
	ExplorationManager.start_session(GRAPH_PATH)
	assert_true(ExplorationManager.is_session_active, "session starts for BGM tests")

func test_session_bgm_preserved_after_title_menu_audio() -> void:
	print("-- test_session_bgm_preserved_after_title_menu_audio")
	_start_test_session()
	SaveManager.exploration_session = SaveManager.exploration_session.duplicate(true)
	SaveManager.exploration_session["bgm_path"] = EXPLORATION_BGM
	SaveManager.exploration_session["bgm_context"] = BGMManager.CONTEXT_VN
	SaveManager.exploration_session["bgm_position"] = 42.5
	SaveManager.exploration_session["bgm_loop_from_sec"] = -1.0

	BGMManager.play_context(BGMManager.CONTEXT_MAIN_MENU, 0.0, 0.0)
	ExplorationManager.set_var("_bgm_test_ping", "1")

	var sd: Dictionary = SaveManager.exploration_session
	assert_eq(str(sd.get("bgm_path", "")), EXPLORATION_BGM,
		"auto-save keeps exploration BGM after title menu audio takes over")
	assert_eq(float(sd.get("bgm_position", -1.0)), 42.5,
		"auto-save keeps exploration BGM playback position")

func test_restore_queues_saved_session_bgm() -> void:
	print("-- test_restore_queues_saved_session_bgm")
	SaveManager.exploration_session = {
		"active": true,
		"graph_path": GRAPH_PATH,
		"current_node_id": "node_quiet_study",
		"history": ["node_exhibition", "node_quiet_study"],
		"inventory": [],
		"vars": {"toilet_front_password_correct": "1"},
		"played_vn_scenes": [],
		"interacted_spots": [],
		"talked_characters": [],
		"rewards": {"credits": 0, "flags": {}},
		"return_scene": "res://scenes/main_menu.tscn",
		"pending_return_vn": "",
		"source_vn_scene": "",
		"bgm_path": EXPLORATION_BGM,
		"bgm_context": BGMManager.CONTEXT_VN,
		"bgm_position": 12.0,
		"bgm_loop_from_sec": -1.0,
	}
	assert_true(ExplorationManager.restore_saved_session(), "restore_saved_session succeeds")
	var pending: Dictionary = ExplorationManager.take_pending_restored_bgm()
	assert_eq(str(pending.get("path", "")), EXPLORATION_BGM,
		"restore queues saved exploration BGM path")
	assert_eq(float(pending.get("position", -1.0)), 12.0,
		"restore queues saved exploration BGM position")
