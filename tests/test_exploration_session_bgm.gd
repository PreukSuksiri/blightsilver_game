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
	test_saved_session_matches_launch_shared_graph()
	test_launch_params_not_cumulative_across_chapters()
	test_has_saved_session_for_chapter_rejects_foreign_snapshot()
	test_start_session_invalidates_stale_exploration_arcs()
	test_resume_saved_exploration_rejects_foreign_chapter()


func _end_test_session() -> void:
	if ExplorationManager.is_session_active:
		ExplorationManager.end_session(false, true)


func _start_test_session() -> void:
	ExplorationManager._apply_launch_params({"force_fresh": true})
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
	if ExplorationManager.is_session_active:
		ExplorationManager.end_session(false, true)

func test_saved_session_matches_launch_shared_graph() -> void:
	print("-- test_saved_session_matches_launch_shared_graph")
	var act1_save := {
		"active": true,
		"graph_path": GRAPH_PATH,
		"source_vn_scene": "res://campaign/scenes/ch1_s1_pre_DEMO_PART1.json",
		"vars": {"chapter": "act_1_ch_1"},
	}
	assert_true(not ExplorationManager._saved_session_matches_launch(
			act1_save,
			"res://campaign/scenes/ch0_s1_pre_DEMO_PART1.json",
			{}),
		"prologue launch must not resume Act I snapshot on shared graph")
	assert_true(ExplorationManager._saved_session_matches_launch(
			act1_save,
			"res://campaign/scenes/ch1_s1_pre_DEMO_PART1.json",
			{"chapter": "act_1_ch_1"}),
		"Act I launch may resume Act I snapshot")
	var prologue_save := {
		"active": true,
		"graph_path": GRAPH_PATH,
		"source_vn_scene": "res://campaign/scenes/ch0_s1_pre_DEMO_PART1.json",
		"vars": {},
	}
	assert_true(ExplorationManager._saved_session_matches_launch(
			prologue_save,
			"res://campaign/scenes/ch0_s1_pre_DEMO_PART1.json",
			{}),
		"prologue launch may resume prologue snapshot")
	assert_true(not ExplorationManager._saved_session_matches_launch(
			prologue_save,
			"res://campaign/scenes/ch1_s1_pre_DEMO_PART1.json",
			{"chapter": "act_1_ch_1"}),
		"Act I launch must not resume prologue snapshot")
	_end_test_session()


const PROLOGUE_VN := "res://campaign/scenes/ch0_s1_pre_DEMO_PART1.json"
const ACT1_VN := "res://campaign/scenes/ch1_s1_pre_DEMO_PART1.json"


func test_launch_params_not_cumulative_across_chapters() -> void:
	print("-- test_launch_params_not_cumulative_across_chapters")
	# Simulate Act I launch leaving chapter in launch_params (old merge bug).
	ExplorationManager._apply_launch_params({
		"force_fresh": true,
		"chapter": "act_1_ch_1",
		"surprise_factor": "2",
	})
	ExplorationManager.start_session(GRAPH_PATH, ACT1_VN)
	assert_eq(ExplorationManager.get_var("chapter"), "act_1_ch_1",
		"Act I seeds chapter=act_1_ch_1")
	_end_test_session()

	# Prologue force_fresh params omit chapter — must fully replace, not merge.
	ExplorationManager._apply_launch_params({
		"force_fresh": true,
		"surprise_factor": "1",
	})
	ExplorationManager.start_session(GRAPH_PATH, PROLOGUE_VN)
	assert_eq(ExplorationManager.get_var("chapter", ""), "",
		"Prologue force_fresh must not inherit Act I chapter var")
	assert_true(ExplorationManager.get_var("chapter", "") != "act_1_ch_1",
		"Gluey Key gate must see chapter != act_1_ch_1 on Prologue replay")
	_end_test_session()


func test_has_saved_session_for_chapter_rejects_foreign_snapshot() -> void:
	print("-- test_has_saved_session_for_chapter_rejects_foreign_snapshot")
	SaveManager.exploration_session = {
		"active": true,
		"graph_path": GRAPH_PATH,
		"source_vn_scene": ACT1_VN,
		"vars": {"chapter": "act_1_ch_1"},
	}
	var prologue_card := {
		"vn_scene": PROLOGUE_VN,
		"exploration_graph": GRAPH_PATH,
	}
	var act1_card := {
		"vn_scene": ACT1_VN,
		"exploration_graph": GRAPH_PATH,
		"exploration_save_var": "chapter",
		"exploration_save_value": "act_1_ch_1",
	}
	assert_true(ExplorationManager.has_saved_session_for_chapter(
			ACT1_VN, GRAPH_PATH, act1_card),
		"Act I owns Act I snapshot")
	assert_true(not ExplorationManager.has_saved_session_for_chapter(
			PROLOGUE_VN, GRAPH_PATH, prologue_card),
		"Prologue must not claim Act I snapshot on shared graph")
	SaveManager.exploration_session = {}


func test_start_session_invalidates_stale_exploration_arcs() -> void:
	print("-- test_start_session_invalidates_stale_exploration_arcs")
	SaveManager.chapter_arc_progress = {
		PROLOGUE_VN: {
			"segment": "exploration",
			"exploration_graph": GRAPH_PATH,
			"pending_return_vn": "",
			"source_vn": PROLOGUE_VN,
			"source_beat_index": 0,
		},
	}
	ExplorationManager._apply_launch_params({
		"force_fresh": true,
		"chapter": "act_1_ch_1",
	})
	ExplorationManager.start_session(GRAPH_PATH, ACT1_VN)
	assert_true(not SaveManager.has_chapter_arc_progress(PROLOGUE_VN),
		"starting Act I exploration clears Prologue Continue arc on shared graph")
	assert_true(ExplorationManager.has_saved_session_for_chapter(
			ACT1_VN, GRAPH_PATH, {
				"vn_scene": ACT1_VN,
				"exploration_save_var": "chapter",
				"exploration_save_value": "act_1_ch_1",
			}),
		"Act I snapshot remains owned by Act I")
	_end_test_session()
	SaveManager.chapter_arc_progress = {}
	SaveManager.exploration_session = {}


func test_resume_saved_exploration_rejects_foreign_chapter() -> void:
	print("-- test_resume_saved_exploration_rejects_foreign_chapter")
	SaveManager.exploration_session = {
		"active": true,
		"graph_path": GRAPH_PATH,
		"current_node_id": "node_book_repair_unit",
		"history": [],
		"inventory": [],
		"vars": {"chapter": "act_1_ch_1"},
		"played_vn_scenes": [],
		"interacted_spots": [],
		"talked_characters": [],
		"rewards": {"credits": 0, "flags": {}},
		"return_scene": "res://scenes/main_menu.tscn",
		"pending_return_vn": "",
		"source_vn_scene": ACT1_VN,
	}
	SaveManager.chapter_arc_progress = {
		PROLOGUE_VN: {
			"segment": "exploration",
			"exploration_graph": GRAPH_PATH,
		},
	}
	var prologue_card := {
		"vn_scene": PROLOGUE_VN,
		"exploration_graph": GRAPH_PATH,
	}
	var ok: bool = ExplorationManager.resume_saved_exploration(
		GRAPH_PATH,
		"res://scenes/main_menu.tscn",
		PROLOGUE_VN,
		prologue_card)
	assert_true(not ok,
		"resume must refuse Act I snapshot when Continue is for Prologue")
	assert_true(not SaveManager.has_chapter_arc_progress(PROLOGUE_VN),
		"stale Prologue arc is cleared on ownership mismatch")
	assert_true(not ExplorationManager.is_session_active,
		"ownership mismatch must not restore a live session")
	SaveManager.exploration_session = {}
	SaveManager.chapter_arc_progress = {}
