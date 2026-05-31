extends Node
## CardE2ERunner — card-by-card full UI/battle E2E via AI vs AI mode.
##
## Loads scenarios from test_case/e2e/scenarios.json, runs them sequentially through
## AIvsAIManager, scores battle logs, and tracks progress until every card is tested.

signal suite_progress(completed: int, total: int, scenario_id: String, passed: bool)
signal suite_finished(summary: Dictionary)

const DeckData = preload("res://resources/DeckData.gd")
const SCENARIOS_PATH := "res://test_case/e2e/scenarios.json"
const PROGRESS_PATH := "user://card_e2e_progress.json"

var _active: bool = false
var _scenarios: Array = []
var _all_scenarios: Array = []
var _tier_filter: int = 0  # 0=all, 1=tier1 only, 2=tier2 only
var _index: int = 0
var _results: Array = []
var _passed_ids: Dictionary = {}
var _current: Dictionary = {}
var _summary_text: String = ""


func is_active() -> bool:
	return _active


func get_current_scenario() -> Dictionary:
	return _current.duplicate(true)


func build_scenario_log_header(scenario: Dictionary = {}) -> PackedStringArray:
	if scenario.is_empty():
		scenario = _current
	if scenario.is_empty():
		return PackedStringArray()

	var lines: PackedStringArray = PackedStringArray()
	var sid: String = str(scenario.get("id", ""))
	var card_name: String = str(scenario.get("card_name", ""))
	var card_type: String = str(scenario.get("card_type", ""))
	var tier: int = int(scenario.get("tier", 1))
	var ability: String = str(scenario.get("ability_type", ""))
	var ability_desc: String = str(scenario.get("ability_description", ""))
	var role: String = str(scenario.get("role", ""))
	var notes: String = str(scenario.get("notes", ""))

	lines.append("=== Card E2E Test ===")
	lines.append("Scenario ID:  %s" % sid)
	lines.append("Tier:         %s" % _tier_label(tier))
	lines.append("Scenario def: res://test_case/e2e/scenarios.json")
	if card_name != "":
		lines.append("Related spec: %s  (%s)" % [
			_functional_test_id(card_name),
			_functional_test_doc(card_type),
		])
	lines.append("Highlight:    %s" % _format_highlight(scenario))
	if ability != "" and ability != "NONE":
		var ability_line := "Ability:      %s" % ability
		if ability_desc != "":
			ability_line += " — %s" % ability_desc
		lines.append(ability_line)
	if role != "":
		lines.append("Setup role:   %s" % role)
	lines.append("Verifies:")
	for bullet: String in _verification_bullets(scenario):
		lines.append("  - %s" % bullet)
	if notes != "":
		lines.append("Notes:        %s" % notes)
	lines.append("===")
	return lines


func build_scenario_log_footer(scenario: Dictionary, score: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray([
		"",
		"=== Card E2E Result ===",
		"Scenario:  %s" % str(scenario.get("id", "")),
		"Highlight: %s" % _format_highlight(scenario),
		"Result:    %s" % ("PASS" if score.get("passed", false) else "FAIL"),
		"Detail:    %s" % str(score.get("reason", "")),
		"Turns:     %d  |  AI timeouts: %d" % [
			int(score.get("turns", 0)),
			int(score.get("timeouts", 0)),
		],
		"===",
	])
	return lines


func get_summary_text() -> String:
	return _summary_text


func get_progress_text() -> String:
	if _all_scenarios.is_empty():
		_load_scenarios(0)
	if _passed_ids.is_empty() and FileAccess.file_exists(PROGRESS_PATH):
		_load_progress()
	if _all_scenarios.is_empty():
		return "No E2E scenarios loaded."
	var t1_total := 0
	var t2_total := 0
	var t1_done := 0
	var t2_done := 0
	for s: Variant in _all_scenarios:
		if not (s is Dictionary):
			continue
		var sid: String = str(s.get("id", ""))
		var tier: int = int(s.get("tier", 1))
		if tier == 2:
			t2_total += 1
			if _passed_ids.has(sid):
				t2_done += 1
		else:
			t1_total += 1
			if _passed_ids.has(sid):
				t1_done += 1
	var filter_label := ""
	match _tier_filter:
		1: filter_label = " [T1 only]"
		2: filter_label = " [T2 only]"
	return "E2E: T1 %d/%d  T2 %d/%d  (queue %d%s)" % [
		t1_done, t1_total, t2_done, t2_total, _scenarios.size(), filter_label]


func reset_progress(tier: int = 0) -> void:
	if tier == 0:
		_passed_ids.clear()
	else:
		var to_remove: Array[String] = []
		for s: Variant in _all_scenarios:
			if s is Dictionary and int(s.get("tier", 1)) == tier:
				var sid: String = str(s.get("id", ""))
				if _passed_ids.has(sid):
					to_remove.append(sid)
		for sid: String in to_remove:
			_passed_ids.erase(sid)
	_save_progress()
	_summary_text = "E2E progress reset (tier filter=%d)." % tier


func start_suite(resume: bool = true, tier_filter: int = 0) -> String:
	if _active:
		return "E2E suite already running."
	_tier_filter = tier_filter
	var err := _load_scenarios(tier_filter)
	if err != "":
		return err
	if resume:
		_load_progress()
	elif tier_filter == 0:
		_passed_ids.clear()
		_save_progress()
	elif tier_filter > 0:
		reset_progress(tier_filter)
	_index = 0
	while _index < _scenarios.size():
		var sid: String = str(_scenarios[_index].get("id", ""))
		if sid.is_empty() or not _passed_ids.has(sid):
			break
		_index += 1
	if _index >= _scenarios.size():
		return "All %d queued scenarios already passed. Reset progress to re-run." % _scenarios.size()

	_active = true
	_results.clear()
	SaveManager.set_union_mechanism_unlocked(true)
	_launch_current()
	var tier_name := "all tiers" if tier_filter == 0 else "tier %d" % tier_filter
	return "Started E2E (%s) at %s (%d remaining in queue)." % [
		tier_name,
		str(_scenarios[_index].get("id", "?")),
		_scenarios.size() - _count_passed_in_queue(),
	]


func on_battle_finished(log_path: String, log_lines: PackedStringArray) -> void:
	if not _active:
		get_tree().change_scene_to_file("res://scenes/ai_vs_ai_config.tscn")
		return

	var log_text := "\n".join(log_lines)
	var score: Dictionary = _score_log(log_text, _current)
	score["log_path"] = log_path
	score["scenario_id"] = str(_current.get("id", ""))
	score["card_name"] = str(_current.get("card_name", ""))
	score["tier"] = int(_current.get("tier", 1))
	_append_lines_to_log(log_path, build_scenario_log_footer(_current, score))
	_results.append(score)

	var passed: bool = bool(score.get("passed", false))
	if passed:
		_passed_ids[str(_current.get("id", ""))] = true
		_save_progress()
	emit_signal("suite_progress", _passed_ids.size(), _scenarios.size(),
		str(_current.get("id", "")), passed)

	_index += 1
	if _index < _scenarios.size():
		call_deferred("_launch_current")
		return

	_finish_suite()


func _finish_suite() -> void:
	_active = false
	var passed_count := 0
	var failed: Array[String] = []
	for r: Variant in _results:
		if r is Dictionary and r.get("passed", false):
			passed_count += 1
		elif r is Dictionary:
			failed.append("%s: %s" % [r.get("scenario_id", "?"), r.get("reason", "?")])

	var summary := {
		"total": _scenarios.size(),
		"tier_filter": _tier_filter,
		"run_this_session": _results.size(),
		"passed_this_session": passed_count,
		"failed_this_session": _results.size() - passed_count,
		"cumulative_passed": _passed_ids.size(),
		"failed_ids": failed,
	}
	_summary_text = _format_summary(summary)
	_write_session_summary(summary)
	emit_signal("suite_finished", summary)
	get_tree().change_scene_to_file("res://scenes/ai_vs_ai_config.tscn")


func _launch_current() -> void:
	if _index >= _scenarios.size():
		_finish_suite()
		return
	_current = _scenarios[_index] as Dictionary
	GameState.battle_player_union_enabled = bool(_current.get("union_enabled", false))
	GameState.battle_ai_union_enabled = bool(_current.get("union_enabled", false))

	var deck0 := _deck_from_dict(_current.get("deck0", {}))
	var deck1 := _deck_from_dict(_current.get("deck1", {}))
	var fc0: Array = _current.get("forced_cells_0", [])
	var fc1: Array = _current.get("forced_cells_1", [])
	var ft0: Array = _current.get("forced_tech_0", [])
	var ft1: Array = _current.get("forced_tech_1", [])

	AIvsAIManager.configure(deck0, fc0, deck1, fc1, ft0, ft1)
	AIvsAIManager.start_batch(1)
	AIvsAIManager.launch_battle()


func _deck_from_dict(d: Variant) -> DeckData:
	var deck: DeckData = DeckData.new()
	if d is Dictionary:
		deck.load_from_dict(d)
	if not deck.is_valid():
		# Fallback — should not happen for generated scenarios
		deck = _default_deck()
	return deck


func _default_deck() -> DeckData:
	var deck: DeckData = DeckData.new()
	deck.deck_name = "E2E Fallback"
	deck.characters = [
		"Chaotic Wisp", "Foul Wisp", "Doom Wisp", "Church Guard", "Big Thug",
		"Dark Monk", "Ox Patrol", "Wandering Swordsman",
	]
	deck.traps = ["Trap Hole", "Trap Hole", "Hypnosis", "Spike Trap"]
	deck.techs = ["Radar", "Spy", "Bribe"]
	return deck


func _load_scenarios(tier_filter: int = 0) -> String:
	_all_scenarios.clear()
	_scenarios.clear()
	if not FileAccess.file_exists(SCENARIOS_PATH):
		return "Missing %s — run: python3 test_case/e2e/generate_e2e_scenarios.py" % SCENARIOS_PATH
	var text := FileAccess.get_file_as_string(SCENARIOS_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		return "Invalid JSON in scenarios file."
	var list: Variant = parsed.get("scenarios", [])
	if not (list is Array) or list.is_empty():
		return "No scenarios in file."
	_all_scenarios = list.duplicate(true)
	for s: Variant in _all_scenarios:
		if not (s is Dictionary):
			continue
		var tier: int = int(s.get("tier", 1))
		if tier_filter == 0 or tier == tier_filter:
			_scenarios.append(s)
	if _scenarios.is_empty():
		return "No scenarios for tier filter %d." % tier_filter
	return ""


func _count_passed_in_queue() -> int:
	var n := 0
	for s: Variant in _scenarios:
		if s is Dictionary and _passed_ids.has(str(s.get("id", ""))):
			n += 1
	return n


func _load_progress() -> void:
	_passed_ids.clear()
	if not FileAccess.file_exists(PROGRESS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROGRESS_PATH))
	if parsed is Dictionary:
		for sid: Variant in parsed.get("passed_ids", []):
			_passed_ids[str(sid)] = true


func _save_progress() -> void:
	var ids: Array[String] = []
	for sid: String in _passed_ids.keys():
		ids.append(sid)
	ids.sort()
	var payload := {
		"passed_ids": ids,
		"passed_count": ids.size(),
		"updated_at": Time.get_datetime_string_from_system(true),
	}
	var f := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()


func _score_log(log_text: String, scenario: Dictionary) -> Dictionary:
	var reasons: Array[String] = []

	for bad: Variant in scenario.get("expect_log_not_contains", []):
		var needle := str(bad)
		if needle != "" and needle in log_text:
			reasons.append("Forbidden log text: %s" % needle)

	for good: Variant in scenario.get("expect_log_contains", []):
		var needle := str(good)
		if needle != "" and needle not in log_text:
			reasons.append("Missing expected log text: %s" % needle)

	for pattern: Variant in scenario.get("expect_log_regex", []):
		var pat := str(pattern)
		if pat.is_empty():
			continue
		var rx := RegEx.new()
		if rx.compile(pat) != OK:
			reasons.append("Invalid regex in scenario: %s" % pat)
			continue
		if rx.search(log_text) == null:
			reasons.append("Regex not matched: %s" % pat)

	var any_list: Array = scenario.get("expect_log_any", [])
	if not any_list.is_empty():
		var hit := false
		for opt: Variant in any_list:
			if str(opt) != "" and str(opt) in log_text:
				hit = true
				break
		if not hit:
			reasons.append("None of expect_log_any matched: %s" % str(any_list))

	var max_timeouts: int = int(scenario.get("max_watchdog_timeouts", 5))
	var timeout_count := log_text.count("[TIMEOUT]")
	if timeout_count > max_timeouts:
		reasons.append("Too many AI watchdog timeouts (%d > %d)" % [timeout_count, max_timeouts])

	var max_turns: int = int(scenario.get("max_turns", 50))
	var turns := _parse_turn_count(log_text)
	if turns > max_turns:
		reasons.append("Exceeded max turns (%d > %d)" % [turns, max_turns])

	if "GAME OVER" not in log_text:
		reasons.append("Battle did not reach GAME OVER")

	var card_name := str(scenario.get("card_name", ""))
	var role := str(scenario.get("role", ""))
	var skip_name := role in ["union_summon", "t1_union", "t2_union"]
	if card_name != "" and not skip_name and card_name not in log_text:
		reasons.append("Card name never appeared in log: %s" % card_name)

	return {
		"passed": reasons.is_empty(),
		"reason": "; ".join(reasons) if not reasons.is_empty() else "ok",
		"turns": turns,
		"timeouts": timeout_count,
	}


func _parse_turn_count(log_text: String) -> int:
	var re := RegEx.new()
	re.compile(r"Turns:\s*(\d+)")
	var m := re.search(log_text)
	if m:
		return int(m.get_string(1))
	return 0


func _format_summary(summary: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray([
		"=== Card E2E Suite Complete ===",
		"Cumulative passed: %d / %d" % [summary.get("cumulative_passed", 0), summary.get("total", 0)],
		"This session: %d passed, %d failed (of %d run)" % [
			summary.get("passed_this_session", 0),
			summary.get("failed_this_session", 0),
			summary.get("run_this_session", 0),
		],
	])
	var failed: Array = summary.get("failed_ids", [])
	if not failed.is_empty():
		lines.append("")
		lines.append("Failures:")
		for f: Variant in failed:
			lines.append("  - %s" % str(f))
	return "\n".join(lines)


func _count_tier_passed(tier: int) -> int:
	var n := 0
	for s: Variant in _all_scenarios:
		if s is Dictionary and int(s.get("tier", 1)) == tier:
			if _passed_ids.has(str(s.get("id", ""))):
				n += 1
	return n


func _write_session_summary(summary: Dictionary) -> void:
	var folder := SessionLogNaming.session_folder_path
	if folder.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var path := "%s/card_e2e_summary.json" % folder
	var payload := summary.duplicate(true)
	payload["results"] = _results.duplicate(true)
	payload["tier1_passed"] = _count_tier_passed(1)
	payload["tier2_passed"] = _count_tier_passed(2)
	payload["completed_at"] = Time.get_datetime_string_from_system(true)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()


func _tier_label(tier: int) -> String:
	match tier:
		1: return "1 — Smoke (battle completes, card in log, no crashes)"
		2: return "2 — Ability (forced setup + log assertions)"
		_: return str(tier)


func _functional_test_id(card_name: String) -> String:
	return "TC-FUNC-%s-001" % card_name.replace(" ", "-")


func _functional_test_doc(card_type: String) -> String:
	match card_type.to_lower():
		"character": return "test_case/functional/character_functional_tests.md"
		"trap": return "test_case/functional/trap_functional_tests.md"
		"tech": return "test_case/functional/tech_functional_tests.md"
		"union": return "test_case/functional/union_functional_tests.md"
		_: return "test_case/functional/"


func _format_highlight(scenario: Dictionary) -> String:
	var card_name: String = str(scenario.get("card_name", ""))
	var card_type: String = str(scenario.get("card_type", ""))
	if card_name == "":
		return "(unknown)"
	var setup: Array[String] = []
	for name: String in _setup_card_names(scenario):
		if name != card_name and name not in setup:
			setup.append(name)
	if setup.is_empty():
		return "%s (%s)" % [card_name, card_type]
	return "%s (%s)  [setup: %s]" % [card_name, card_type, ", ".join(PackedStringArray(setup))]


func _setup_card_names(scenario: Dictionary) -> Array[String]:
	var names: Array[String] = []
	for key: String in ["forced_cells_0", "forced_cells_1", "forced_tech_0", "forced_tech_1"]:
		for entry: Variant in scenario.get(key, []):
			if entry is Dictionary:
				var n: String = str((entry as Dictionary).get("card_name", "")).strip_edges()
				if n != "" and n not in names:
					names.append(n)
			else:
				var n2: String = str(entry).strip_edges()
				if n2 != "" and n2 not in names:
					names.append(n2)
	return names


func _verification_bullets(scenario: Dictionary) -> Array[String]:
	var bullets: Array[String] = []
	var tier: int = int(scenario.get("tier", 1))
	var card_name: String = str(scenario.get("card_name", ""))
	if tier == 1:
		bullets.append(
			"Smoke: \"%s\" appears in the battle log and the match reaches GAME OVER" % card_name)
		bullets.append("No script errors, invalid calls, or stack traces in log")
	else:
		bullets.append(
			"Ability: \"%s\" is exercised via forced board/tech setup (%s)" % [
				card_name, str(scenario.get("role", "t2"))])
		bullets.append("Full battle reaches GAME OVER without script errors")

	for needle: Variant in scenario.get("expect_log_contains", []):
		var text := str(needle)
		if text != "":
			bullets.append("Log must contain: %s" % text)

	for pattern: Variant in scenario.get("expect_log_regex", []):
		var pat := str(pattern)
		if pat != "":
			bullets.append("Log must match regex: %s" % pat)

	var any_list: Array = scenario.get("expect_log_any", [])
	if not any_list.is_empty():
		var any_parts: PackedStringArray = PackedStringArray()
		for opt: Variant in any_list:
			any_parts.append(str(opt))
		bullets.append("Log must contain at least one of: %s" % ", ".join(any_parts))

	for bad: Variant in scenario.get("expect_log_not_contains", []):
		var text := str(bad)
		if text != "":
			bullets.append("Log must NOT contain: %s" % text)

	if card_name != "":
		var role: String = str(scenario.get("role", ""))
		if role not in ["union_summon", "t1_union", "t2_union"]:
			bullets.append("Highlight card name must appear somewhere in log")

	bullets.append("Within %d turns and <= %d AI watchdog timeouts" % [
		int(scenario.get("max_turns", 50)),
		int(scenario.get("max_watchdog_timeouts", 5)),
	])
	return bullets


func _append_lines_to_log(log_path: String, lines: PackedStringArray) -> void:
	if log_path.is_empty() or lines.is_empty():
		return
	var f := FileAccess.open(log_path, FileAccess.READ_WRITE)
	if f == null:
		return
	f.seek_end()
	if f.get_length() > 0:
		f.store_line("")
	for line: String in lines:
		f.store_line(line)
	f.close()
