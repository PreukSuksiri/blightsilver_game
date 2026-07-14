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
	test_resolve_play_group_first_match()
	test_resolve_play_group_no_match()
	test_resolve_play_group_and_conditions()
	test_resolve_play_group_or_conditions()
	test_enter_group_from_beat()
	test_play_group_branch_playback()
	test_nested_play_group_resumes_parent()
	test_silent_go_to_resolves_immediately()
	test_go_to_can_land_on_hidden_beat()
	test_linear_advance_skips_hidden_beats()

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

func test_resolve_play_group_first_match() -> void:
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"text": "trigger", "play_group": [
			{"group": 1, "conditions": []},
			{"group": 2, "conditions": []},
		]},
		{"group": 1, "text": "g1"},
		{"group": 2, "text": "g2"},
	]
	vn._build_group_maps()
	var beat: Dictionary = vn._beats[0] as Dictionary
	assert_eq(vn._resolve_play_group(beat), 1, "play_group returns first matching group")

func test_resolve_play_group_no_match() -> void:
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"text": "trigger", "play_group": [
			{"group": 1, "conditions": [
				{"type": "var_equals", "key": "missing", "value": "1"},
			]},
		]},
		{"group": 1, "text": "g1"},
	]
	vn._build_group_maps()
	var beat: Dictionary = vn._beats[0] as Dictionary
	assert_eq(vn._resolve_play_group(beat), -1, "play_group returns -1 when no rule matches")

func test_resolve_play_group_and_conditions() -> void:
	SaveManager.exploration_flags["pg_and_a"] = "1"
	SaveManager.exploration_flags["pg_and_b"] = "1"
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"text": "trigger", "play_group": [
			{"group": 1, "conditions_mode": "and", "conditions": [
				{"type": "flag_equals", "key": "pg_and_a", "value": "1"},
				{"type": "flag_equals", "key": "pg_and_b", "value": "1"},
			]},
			{"group": 2, "conditions": []},
		]},
		{"group": 1, "text": "g1"},
		{"group": 2, "text": "g2"},
	]
	vn._build_group_maps()
	assert_eq(vn._resolve_play_group(vn._beats[0] as Dictionary), 1, "play_group AND passes when all flags match")
	SaveManager.exploration_flags["pg_and_b"] = "0"
	assert_eq(vn._resolve_play_group(vn._beats[0] as Dictionary), 2, "play_group AND fails → next rule")
	SaveManager.exploration_flags.erase("pg_and_a")
	SaveManager.exploration_flags.erase("pg_and_b")

func test_resolve_play_group_or_conditions() -> void:
	SaveManager.exploration_flags["pg_or_a"] = "0"
	SaveManager.exploration_flags["pg_or_b"] = "1"
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"text": "trigger", "play_group": [
			{"group": 1, "conditions_mode": "or", "conditions": [
				{"type": "flag_equals", "key": "pg_or_a", "value": "1"},
				{"type": "flag_equals", "key": "pg_or_b", "value": "1"},
			]},
		]},
		{"group": 1, "text": "g1"},
	]
	vn._build_group_maps()
	assert_eq(vn._resolve_play_group(vn._beats[0] as Dictionary), 1, "play_group OR passes when any flag matches")
	SaveManager.exploration_flags.erase("pg_or_a")
	SaveManager.exploration_flags.erase("pg_or_b")

func test_enter_group_from_beat() -> void:
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"text": "mainline"},
		{"group": 1, "text": "g1a"},
		{"group": 1, "text": "g1b"},
		{"text": "continue"},
	]
	vn._build_group_maps()
	vn._beat_index = 0
	var ok: bool = vn._enter_group_from_beat(1, 0)
	assert_eq(ok, true, "enter_group_from_beat succeeds")
	assert_eq(vn._active_group_id, 1, "active group set")
	assert_eq(vn._beat_index, 1, "jumped to first group beat")
	assert_eq(vn._group_return_index, 3, "return index is next mainline after trigger")

func test_play_group_branch_playback() -> void:
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"text": "trigger", "play_group": [
			{"group": 1, "conditions": []},
		]},
		{"group": 1, "text": "g1_first"},
		{"group": 1, "text": "g1_second"},
		{"group": 2, "text": "other"},
		{"text": "mainline_continue"},
	]
	vn._build_group_maps()
	vn._active_group_id = 0
	vn._beat_index = 0
	vn._last_shown_beat_index = 0
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 4, "mainline cursor skips groups while inactive")
	var play_group_id: int = vn._resolve_play_group(vn._beats[0] as Dictionary)
	assert_eq(play_group_id, 1, "trigger resolves to group 1")
	vn._enter_group_from_beat(play_group_id, 0)
	assert_eq(vn._beat_index, 1, "entered group 1 first beat")
	vn._last_shown_beat_index = 1
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 2, "plays second group 1 beat")
	vn._last_shown_beat_index = 2
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 4, "returns to mainline after group 1")

func test_nested_play_group_resumes_parent() -> void:
	# Mirrors ch0 beats: G10 → nested G11 → remaining G10 (go_to) → mainline
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"text": "trigger"},                                          # 0
		{"group": 10, "text": "g10_a"},                               # 1
		{"group": 10, "play_group": [{"group": 11, "conditions": []}]}, # 2 silent nest
		{"group": 11, "text": "g11_only"},                            # 3
		{"group": 10, "text": "g10_after"},                           # 4
		{"group": 10, "go_to": [{"beat_name": "loop_here"}]},         # 5 silent go_to
		{"text": "mainline"},                                         # 6
		{"beat_name": "loop_here", "text": "loop target"},            # 7
	]
	vn._build_group_maps()
	vn._build_beat_name_index()
	vn._enter_group_from_beat(10, 0, false)
	assert_eq(vn._beat_index, 1, "start G10")
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 2, "reach nest play_group beat")
	vn._enter_group_from_beat(11, 2, true)
	assert_eq(vn._active_group_id, 11, "now in G11")
	assert_eq(vn._group_stack.size(), 1, "parent G10 stacked")
	assert_eq(vn._beat_index, 3, "show G11 beat")
	vn._advance_beat_cursor()
	assert_eq(vn._active_group_id, 10, "resumed parent G10 after G11 ended")
	assert_eq(vn._beat_index, 4, "continues remaining G10 beats")
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 5, "reaches G10 go_to beat")

func test_silent_go_to_resolves_immediately() -> void:
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"text": "before"},
		{"group": 10, "go_to": [{"beat_name": "retry"}]},
		{"text": "should_skip_mainline"},
		{"beat_name": "retry", "text": "retry target"},
	]
	vn._build_group_maps()
	vn._build_beat_name_index()
	vn._enter_group_from_beat(10, 0, false)
	assert_eq(vn._beat_index, 1, "landed on silent go_to beat")
	# Mimic landing resolver in _show_beat
	var hops: int = 0
	while hops < 4 and vn._beat_index < vn._beats.size():
		var cand: Dictionary = vn._beats[vn._beat_index] as Dictionary
		if not vn._is_silent_redirect_beat(cand):
			break
		var g_idx: int = vn._resolve_go_to(cand)
		assert_eq(g_idx >= 0, true, "silent go_to resolves")
		vn._beat_index = g_idx
		vn._restore_group_state_for_index(vn._beat_index)
		hops += 1
	assert_eq(vn._beat_index, 3, "jumped to named retry beat")
	assert_eq(vn._active_group_id, 0, "group cleared on mainline target")

func test_go_to_can_land_on_hidden_beat() -> void:
	# Mirrors ch0: wrong-answer group ends with go_to → hidden named beat.
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"text": "before"},
		{"group": 10, "go_to": [{"beat_name": "retry_hidden"}]},
		{"text": "success_mainline"},
		{"beat_name": "retry_hidden", "hidden": true, "text": "tap the notebook"},
		{"text": "after_retry"},
	]
	vn._build_group_maps()
	vn._build_beat_name_index()
	assert_eq(vn._beat_name_index.has("retry_hidden"), true, "hidden name is indexed")
	var goto_idx: int = vn._resolve_go_to(vn._beats[1] as Dictionary)
	assert_eq(goto_idx, 3, "go_to resolves to hidden named beat")
	vn._beat_index = goto_idx
	vn._restore_group_state_for_index(vn._beat_index)
	assert_eq(vn._beat_index, 3, "lands on hidden beat")
	assert_eq(vn._active_group_id, 0, "hidden mainline target clears group")

func test_linear_advance_skips_hidden_beats() -> void:
	var vn: VNPlayer = _make_player()
	vn._beats = [
		{"text": "visible_a"},
		{"hidden": true, "text": "skipped"},
		{"beat_name": "named_hidden", "hidden": true, "text": "also skipped linearly"},
		{"text": "visible_b"},
	]
	vn._build_group_maps()
	vn._build_beat_name_index()
	vn._active_group_id = 0
	vn._beat_index = 0
	vn._advance_beat_cursor()
	assert_eq(vn._beat_index, 3, "linear advance skips hidden beats")
	vn._skip_leading_unplayable_beats()
	assert_eq(vn._beat_index, 3, "leading skip leaves playable beat")
	# Fresh start on hidden: skip to first visible
	vn._beat_index = 1
	vn._skip_leading_unplayable_beats()
	assert_eq(vn._beat_index, 3, "skip_leading jumps past hidden")
