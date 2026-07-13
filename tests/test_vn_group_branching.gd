extends Node
# Tests VN choice-branch playback when group beats are separated by mainline.
# Run: godot --headless --path . res://tests/test_vn_group_branching.tscn

var passed: int = 0
var failed: int = 0

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		passed += 1
		print("  PASS: %s" % msg)
	else:
		failed += 1
		printerr("  FAIL: %s (expected %s, got %s)" % [msg, str(b), str(a)])

func _ready() -> void:
	print("\n=== VN Group Branching Tests ===\n")
	run_all_tests()
	print("\n=== VN Group Branching: %d passed, %d failed ===\n" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func run_all_tests() -> void:
	test_mainline_skips_all_groups()
	test_active_branch_resumes_separated_group_beats()
	test_active_branch_skips_other_groups()

func _make_player() -> VNPlayer:
	var vn: VNPlayer = load("res://scripts/VNPlayer.gd").new()
	return vn

func test_mainline_skips_all_groups() -> void:
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"text": "intro"},
		{"group": 1, "text": "branch_a"},
		{"group": 2, "text": "branch_b"},
		{"text": "continue"},
	]
	vn._build_group_maps()
	vn._active_group_id = 0
	vn._beat_index = 0
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 3, "mainline skips intervening group beats")

func test_active_branch_resumes_separated_group_beats() -> void:
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"text": "choice"},
		{"group": 1, "text": "g1_first"},
		{"group": 1, "text": "g1_second"},
		{"group": 2, "text": "other_branch"},
		{"text": "mainline_mid"},
		{"text": "mainline_late"},
		{"group": 1, "text": "g1_separated"},
	]
	vn._build_group_maps()
	vn._active_group_id = 1
	vn._beat_index = 1
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 2, "branch plays second contiguous group beat")
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 4, "branch skips other group and resumes mainline")
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 5, "branch continues mainline")
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 6, "branch reaches separated group beat")
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 7, "branch ends after final group beat")

func test_active_branch_skips_other_groups() -> void:
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"group": 2, "text": "g2a"},
		{"group": 3, "text": "g3a"},
		{"text": "shared_mainline"},
		{"group": 2, "text": "g2b"},
		{"group": 3, "text": "g3b"},
	]
	vn._build_group_maps()
	vn._active_group_id = 2
	vn._beat_index = 0
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 2, "group 2 path skips group 3 to mainline")
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 3, "group 2 path plays separated group 2 beat")
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 5, "group 2 path skips trailing other-group beats")
