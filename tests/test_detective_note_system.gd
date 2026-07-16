extends Node
# Smoke tests for the detective note data layer:
# DetectiveNoteVault autoload (authored content) and
# DetectiveNoteManager autoload (player progress + variable output).
# Run: godot --headless --path . res://tests/test_detective_note_system.tscn

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

func assert_false(condition: bool, msg: String) -> void:
	assert_true(not condition, msg)

func _ready() -> void:
	print("\n=== Detective Note System Tests ===\n")
	await run_all_tests()
	print("\n=== Detective Note Tests: %d passed, %d failed ===\n" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func run_all_tests() -> void:
	test_scripts_compile()
	test_vault_loads_sample()
	test_level_filtering()
	test_loc_text()
	test_context_resolution()
	test_start_clues()
	test_messenger_clues()
	test_clue_groups()
	test_clue_progress()
	test_clue_new_badge_tracking()
	test_clue_discovery_order()
	test_clue_discovery_order_from_save()
	test_topic_progress()
	test_preferred_topic()
	test_hidden_chapter_and_topic()
	test_chapter_unlock_for_inventory()
	test_placements()
	test_stamps()
	test_save_roundtrip()
	await test_vault_manager_overlay()
	test_admin_command_registered()
	await test_verdict_map_renderer()
	await test_note_overlay()
	await test_layout_editor_writeback()
	test_exploration_note_actions()
	await test_note_toaster()
	test_vn_note_beats()
	await test_inventory_note_tab()
	test_note_test_scene_json()

func test_scripts_compile() -> void:
	for path: String in [
		"res://autoload/DetectiveNoteVault.gd",
		"res://autoload/DetectiveNoteManager.gd",
		"res://scripts/DetectiveNoteVaultManager.gd",
		"res://scripts/DetectiveNoteVerdictMap.gd",
		"res://scripts/DetectiveNoteOverlay.gd",
		"res://autoload/MailboxManager.gd",
		"res://autoload/DetectiveNoteToaster.gd",
		"res://autoload/ExplorationManager.gd",
		"res://scripts/ExplorationPlayer.gd",
		"res://scripts/ExplorationEditor.gd",
		"res://scripts/VNPlayer.gd",
		"res://scripts/VNEditor.gd",
		"res://scripts/InventoryMenu.gd",
	]:
		var script: GDScript = load(path)
		assert_true(script != null and script.can_instantiate(),
			"script compiles: %s" % path)

func test_vault_loads_sample() -> void:
	DetectiveNoteVault.reload()
	assert_true(DetectiveNoteVault.get_chapter_ids().has("ch0_demo"),
		"vault contains ch0_demo chapter")
	var chapter: Dictionary = DetectiveNoteVault.get_chapter("ch0_demo")
	assert_true(not chapter.is_empty(), "ch0_demo chapter loads")
	assert_eq(DetectiveNoteVault.get_topic_ids("ch0_demo"), ["library_lights"],
		"ch0_demo has library_lights topic")
	var topic: Dictionary = DetectiveNoteVault.get_topic("ch0_demo", "library_lights")
	assert_eq((topic.get("nodes", []) as Array).size(), 3, "topic has 3 nodes")
	assert_eq((topic.get("edges", []) as Array).size(), 2, "topic has 2 edges")
	assert_eq(DetectiveNoteVault.get_clue_ids().size(), 11, "vault has 11 clues")
	assert_true(DetectiveNoteVault.get_clue_ids().has("chat_study_group"),
		"vault contains messenger clue chat_study_group")
	assert_eq(DetectiveNoteVault.get_clue_kind("person_kelly"), "individual",
		"person_kelly is an individual")
	assert_eq(DetectiveNoteVault.get_clue_kind("object_library_photo"), "object",
		"object_library_photo is an object")
	assert_true(DetectiveNoteVault.get_clue("no_such_clue").is_empty(),
		"unknown clue returns empty dict")

func test_level_filtering() -> void:
	var topic: Dictionary = DetectiveNoteVault.get_topic("ch0_demo", "library_lights")
	assert_eq(DetectiveNoteVault.topic_max_level(topic), 2, "topic max level is 2")
	assert_eq(DetectiveNoteVault.nodes_for_level(topic, 1).size(), 2,
		"level 1 shows 2 nodes")
	assert_eq(DetectiveNoteVault.nodes_for_level(topic, 2).size(), 3,
		"level 2 shows all 3 nodes")
	assert_eq(DetectiveNoteVault.edges_for_level(topic, 1).size(), 1,
		"level 1 shows 1 edge")
	assert_eq(DetectiveNoteVault.edges_for_level(topic, 2).size(), 2,
		"level 2 shows both edges")

func test_loc_text() -> void:
	assert_eq(DetectiveNoteVault.loc_text("plain"), "plain", "plain string passes through")
	assert_eq(DetectiveNoteVault.loc_text({"en": "hello", "th": "สวัสดี"}, "th"),
		"สวัสดี", "th locale resolves")
	assert_eq(DetectiveNoteVault.loc_text({"en": "hello"}, "th"),
		"hello", "missing locale falls back to first available")
	assert_eq(DetectiveNoteVault.node_label_side({}), "top", "node label side defaults to top")
	assert_eq(DetectiveNoteVault.node_label_side({"label_side": "right"}), "right",
		"node label side reads authored value")
	assert_eq(DetectiveNoteVault.node_label_side({"label_side": "diagonal"}), "top",
		"unknown node label side falls back to top")

func test_context_resolution() -> void:
	assert_eq(DetectiveNoteVault.resolve_chapter_for_context(
		"res://campaign/scenes/ch0_s1_pre_DEMO_PART1.json", ""),
		"ch0_demo", "VN scene resolves to ch0_demo")
	assert_eq(DetectiveNoteVault.resolve_chapter_for_context(
		"", "res://exploration/graphs/ch0_s1_blackout_library.json"),
		"ch0_demo", "exploration graph resolves to ch0_demo")
	assert_eq(DetectiveNoteVault.resolve_chapter_for_context("res://nope.json", ""),
		"", "unknown context resolves to empty")

func test_start_clues() -> void:
	DetectiveNoteVault.reload()
	assert_eq(DetectiveNoteVault.get_chapter_start_clues("ch0_demo"),
		["info_blackout_schedule"], "ch0_demo has authored start_clues")
	assert_eq(DetectiveNoteVault.get_chapter_start_clues("nope"), [],
		"unknown chapter has no start_clues")
	DetectiveNoteManager.reset_all()
	var q_before: int = DetectiveNoteToaster._queue.size()
	DetectiveNoteManager.apply_start_clues("ch0_demo")
	assert_true(DetectiveNoteManager.has_clue("ch0_demo", "info_blackout_schedule"),
		"apply_start_clues grants start clue")
	assert_eq(DetectiveNoteToaster._queue.size(), q_before,
		"start clue grant is silent (no toast queued)")
	DetectiveNoteManager.apply_start_clues("ch0_demo")
	assert_eq(DetectiveNoteManager.get_discovered_clues("ch0_demo").size(), 1,
		"apply_start_clues is idempotent")
	DetectiveNoteManager.reset_all()

func test_messenger_clues() -> void:
	DetectiveNoteVault.reload()
	var clue: Dictionary = DetectiveNoteVault.get_clue("chat_study_group")
	assert_true(DetectiveNoteVault.clue_is_messenger(clue),
		"chat_study_group is a messenger clue")
	assert_eq(DetectiveNoteVault.get_clue_conversation_id("chat_study_group"),
		"sample_chat", "messenger clue references sample_chat")
	assert_eq(DetectiveNoteVault.clue_display_name(clue), "Study group chat",
		"display name from clue name")
	var nameless: Dictionary = clue.duplicate(true)
	nameless["name"] = ""
	assert_true(not DetectiveNoteVault.clue_display_name(nameless).is_empty(),
		"nameless messenger clue falls back to conversation title")
	assert_true(not DetectiveNoteVault.clue_is_postit(clue),
		"messenger clue is not postit")

	# Vault manager validation accepts messenger clue with real conversation.
	var host := Control.new()
	add_child(host)
	DetectiveNoteVaultManager.open(host)
	await get_tree().process_frame
	var mgr: DetectiveNoteVaultManager = \
		host.get_node_or_null("DetectiveNoteVaultManagerOverlay") as DetectiveNoteVaultManager
	assert_true(mgr != null, "vault manager opens for messenger test")
	if mgr != null:
		var clue_problems: Array = mgr._validate().filter(
			func(p: Variant) -> bool:
				return "chat_study_group" in str(p))
		assert_true(clue_problems.is_empty(),
			"sample messenger clue passes validation")
		host.queue_free()
	await get_tree().process_frame

func test_clue_groups() -> void:
	DetectiveNoteVault.reload()
	var bare: Dictionary = {"id": "x", "kind": "object", "name": "X"}
	assert_eq(DetectiveNoteVault.clue_group(bare), "",
		"missing group field reads as empty")
	assert_eq(DetectiveNoteVault.clue_group_label(bare),
		DetectiveNoteVault.CLUE_GROUP_UNGROUPED,
		"empty group displays as Ungrouped")
	assert_eq(DetectiveNoteVault.clue_group({"group": "  Prologue  "}), "Prologue",
		"group is stripped")
	assert_eq(DetectiveNoteVault.clue_group_label({"group": "Prologue"}), "Prologue",
		"named group label is itself")
	# Mutate in-memory vault for get_clue_groups (restore via reload).
	assert_true(not DetectiveNoteVault._clues.is_empty(), "vault has clues for group test")
	var c0: Dictionary = DetectiveNoteVault._clues[0] as Dictionary
	var orig: Variant = c0.get("group", null)
	c0["group"] = "Z_TestFolder"
	var groups: Array = DetectiveNoteVault.get_clue_groups()
	assert_true(groups.has("Z_TestFolder"), "get_clue_groups includes authored group")
	assert_true(not groups.has(DetectiveNoteVault.CLUE_GROUP_UNGROUPED),
		"Ungrouped is not a persisted group name")
	if orig == null:
		c0.erase("group")
	else:
		c0["group"] = orig
	DetectiveNoteVault.reload()

func test_clue_progress() -> void:
	DetectiveNoteManager.reset_all()
	assert_true(DetectiveNoteManager.add_clue("ch0_demo", "person_kelly"),
		"add_clue succeeds for known clue")
	assert_true(not DetectiveNoteManager.add_clue("ch0_demo", "person_kelly"),
		"duplicate add_clue returns false")
	assert_true(not DetectiveNoteManager.add_clue("ch0_demo", "no_such_clue"),
		"unknown clue rejected")
	assert_true(DetectiveNoteManager.has_clue("ch0_demo", "person_kelly"),
		"has_clue sees added clue")
	DetectiveNoteManager.add_clue("ch0_demo", "object_library_photo")
	assert_eq(DetectiveNoteManager.get_discovered_clues_by_kind("ch0_demo", "individual"),
		["person_kelly"], "kind filter returns only individuals")
	assert_true(DetectiveNoteManager.chapter_has_content("ch0_demo"),
		"chapter has content after clue")
	assert_true(not DetectiveNoteManager.chapter_has_content("other_ch"),
		"untouched chapter has no content")

func test_clue_discovery_order() -> void:
	DetectiveNoteManager.reset_all()
	# Grant in non-alphabetical order (ids would sort as chat_, object_, person_).
	DetectiveNoteManager.add_clue("ch0_demo", "person_mayu")
	DetectiveNoteManager.add_clue("ch0_demo", "chat_study_group")
	DetectiveNoteManager.add_clue("ch0_demo", "object_library_photo")
	assert_eq(DetectiveNoteManager.get_discovered_clues("ch0_demo"),
		["person_mayu", "chat_study_group", "object_library_photo"],
		"clues listed in discovery order, not alphabetically")
	assert_eq(DetectiveNoteManager.get_discovered_clues_by_kind("ch0_demo", "individual"),
		["person_mayu"], "kind filter keeps discovery order among matches")

func test_clue_discovery_order_from_save() -> void:
	DetectiveNoteManager.reset_all()
	DetectiveNoteManager.load_from_save({
		"detective_notes": {
			"ch0_demo": {
				"clues": ["object_library_photo", "person_mayu", "chat_study_group"],
				"topics": {},
			},
		},
	})
	assert_eq(DetectiveNoteManager.get_discovered_clues("ch0_demo"),
		["object_library_photo", "person_mayu", "chat_study_group"],
		"legacy saves without clue_at keep clues-array order")

func test_clue_new_badge_tracking() -> void:
	DetectiveNoteManager.reset_all()
	DetectiveNoteManager.add_clue("ch0_demo", "person_kelly")
	assert_true(DetectiveNoteManager.is_clue_new("ch0_demo", "person_kelly"),
		"freshly added clue is marked New")
	assert_true(DetectiveNoteManager.mark_clue_seen("ch0_demo", "person_kelly"),
		"mark_clue_seen dismisses New")
	assert_true(not DetectiveNoteManager.is_clue_new("ch0_demo", "person_kelly"),
		"seen clue is no longer New")
	assert_true(not DetectiveNoteManager.mark_clue_seen("ch0_demo", "person_kelly"),
		"second mark_clue_seen is no-op")
	DetectiveNoteManager.add_clue("ch0_demo", "object_library_photo")
	DetectiveNoteManager.add_clue("ch0_demo", "info_blackout_schedule")
	DetectiveNoteManager.mark_all_clues_seen("ch0_demo")
	assert_true(not DetectiveNoteManager.is_clue_new("ch0_demo", "object_library_photo"),
		"mark_all_clues_seen clears all New badges")
	assert_true(not DetectiveNoteManager.is_clue_new("ch0_demo", "info_blackout_schedule"),
		"mark_all_clues_seen clears leftover New badges")
	# Legacy progress without seen_clues treats existing discoveries as already seen.
	DetectiveNoteManager.reset_all()
	DetectiveNoteManager.load_from_save({
		"detective_notes": {
			"ch0_demo": {"clues": ["person_kelly"], "topics": {}},
		},
	})
	assert_true(not DetectiveNoteManager.is_clue_new("ch0_demo", "person_kelly"),
		"legacy saves without seen_clues do not flood New badges")

func test_topic_progress() -> void:
	assert_true(not DetectiveNoteManager.is_topic_unlocked("ch0_demo", "library_lights"),
		"topic locked initially")
	assert_eq(DetectiveNoteManager.get_topic_level("ch0_demo", "library_lights"), 0,
		"locked topic level is 0")
	assert_true(DetectiveNoteManager.unlock_topic("ch0_demo", "library_lights"),
		"unlock_topic succeeds")
	assert_true(not DetectiveNoteManager.unlock_topic("ch0_demo", "library_lights"),
		"double unlock returns false")
	assert_eq(DetectiveNoteManager.get_topic_level("ch0_demo", "library_lights"), 1,
		"unlocked topic starts at level 1")
	assert_true(DetectiveNoteManager.upgrade_topic("ch0_demo", "library_lights", 2),
		"upgrade to level 2 succeeds")
	assert_true(not DetectiveNoteManager.upgrade_topic("ch0_demo", "library_lights", 2),
		"same-level upgrade returns false")
	assert_true(not DetectiveNoteManager.upgrade_topic("ch0_demo", "library_lights", 1),
		"downgrade rejected")
	assert_eq(DetectiveNoteManager.get_topic_level("ch0_demo", "library_lights"), 2,
		"level clamps at authored max (2)")
	assert_true(not DetectiveNoteManager.upgrade_topic("ch0_demo", "no_such_topic", 2),
		"unknown topic rejected")
	assert_eq(DetectiveNoteManager.get_unlocked_topics("ch0_demo"), ["library_lights"],
		"unlocked topic list correct")

func test_preferred_topic() -> void:
	DetectiveNoteManager.reset_all()
	assert_eq(DetectiveNoteManager.get_preferred_topic("ch0_prologue"), "",
		"no unlocked topics returns empty")
	DetectiveNoteManager.unlock_topic("ch0_prologue", "topic_name_of_book_nex_copied_from")
	DetectiveNoteManager.unlock_topic("ch0_prologue", "topic_where_have_mayu_notebook_gone")
	assert_eq(DetectiveNoteManager.get_preferred_topic("ch0_prologue"),
		"topic_where_have_mayu_notebook_gone",
		"latest active topic preferred when multiple unlocked")
	DetectiveNoteManager.apply_stamp("ch0_prologue", "topic_where_have_mayu_notebook_gone", "stamp_mayu")
	assert_eq(DetectiveNoteManager.get_preferred_topic("ch0_prologue"),
		"topic_name_of_book_nex_copied_from",
		"stamped topics skipped when an active topic remains")
	DetectiveNoteManager.apply_stamp("ch0_prologue", "topic_name_of_book_nex_copied_from", "stamp_mayu")
	assert_eq(DetectiveNoteManager.get_preferred_topic("ch0_prologue"),
		"topic_where_have_mayu_notebook_gone",
		"when all stamped, latest unlocked overall is used")

func test_hidden_chapter_and_topic() -> void:
	DetectiveNoteVault.reload()
	assert_true(not DetectiveNoteVault._chapters.is_empty(), "vault has chapters for hidden test")
	var ch0: Dictionary = DetectiveNoteVault._chapters[0] as Dictionary
	var ch_id: String = str(ch0.get("id", ""))
	var orig_ch_hidden: Variant = ch0.get("hidden", false)
	ch0["hidden"] = true
	assert_true(DetectiveNoteVault.is_chapter_hidden(ch_id),
		"chapter marked hidden is reported hidden")
	assert_true(not DetectiveNoteVault.get_visible_chapter_ids().has(ch_id),
		"hidden chapter omitted from visible chapter ids")
	ch0["hidden"] = orig_ch_hidden

	DetectiveNoteManager.reset_all()
	DetectiveNoteManager.unlock_topic("ch0_prologue", "topic_name_of_book_nex_copied_from")
	DetectiveNoteManager.unlock_topic("ch0_prologue", "topic_where_have_mayu_notebook_gone")
	var prologue: Dictionary = {}
	for ch_v: Variant in DetectiveNoteVault._chapters:
		if ch_v is Dictionary and str((ch_v as Dictionary).get("id", "")) == "ch0_prologue":
			prologue = ch_v as Dictionary
			break
	assert_true(not prologue.is_empty(), "ch0_prologue exists for hidden topic test")
	var topics: Array = prologue.get("topics", []) as Array
	assert_true(topics.size() >= 2, "ch0_prologue has topics for hidden test")
	var t_hidden: Dictionary = topics[0] as Dictionary
	var tid: String = str(t_hidden.get("id", ""))
	var orig_t_hidden: Variant = t_hidden.get("hidden", false)
	t_hidden["hidden"] = true
	assert_true(DetectiveNoteVault.is_topic_hidden("ch0_prologue", tid),
		"topic marked hidden is reported hidden")
	assert_eq(DetectiveNoteManager.get_unlocked_topics("ch0_prologue"),
		["topic_where_have_mayu_notebook_gone"],
		"hidden topic filtered from unlocked list")
	assert_eq(DetectiveNoteManager.get_preferred_topic("ch0_prologue"),
		"topic_where_have_mayu_notebook_gone",
		"preferred topic skips hidden")
	t_hidden["hidden"] = orig_t_hidden
	DetectiveNoteVault.reload()
	DetectiveNoteManager.reset_all()

func test_chapter_unlock_for_inventory() -> void:
	DetectiveNoteManager.reset_all()
	assert_false(DetectiveNoteManager.is_chapter_unlocked("ch0_prologue"),
		"chapter locked with no progress")
	assert_eq(DetectiveNoteManager.get_unlocked_chapter_ids(), [],
		"inventory chapter list empty with no progress")
	DetectiveNoteManager.add_clue("ch0_prologue", "person_nex", true)
	assert_true(DetectiveNoteManager.is_chapter_unlocked("ch0_prologue"),
		"chapter unlocks after first discovered clue")
	assert_true(DetectiveNoteManager.get_unlocked_chapter_ids().has("ch0_prologue"),
		"inventory chapter list includes progressed chapter")
	DetectiveNoteManager.reset_all()
	DetectiveNoteManager.unlock_topic("ch0_prologue", "topic_name_of_book_nex_copied_from")
	assert_true(DetectiveNoteManager.is_chapter_unlocked("ch0_prologue"),
		"chapter unlocks after topic unlock")
	assert_false(DetectiveNoteManager.get_unlocked_chapter_ids().has("ch1_s1"),
		"future chapter stays hidden until progress")

func test_placements() -> void:
	SaveManager.exploration_flags.clear()
	assert_true(DetectiveNoteManager.set_placement(
		"ch0_demo", "library_lights", "culprit", "person_kelly"),
		"individual placed on individual node")
	assert_eq(DetectiveNoteManager.get_placement("ch0_demo", "library_lights", "culprit"),
		"person_kelly", "placement readable")
	assert_eq(str(SaveManager.exploration_flags.get("note_library_lights_culprit", "")),
		"person_kelly", "placement writes persistent flag with clue id")
	assert_true(not DetectiveNoteManager.set_placement(
		"ch0_demo", "library_lights", "culprit", "object_library_photo"),
		"object rejected on individual-only node")
	assert_true(not DetectiveNoteManager.set_placement(
		"ch0_demo", "library_lights", "evidence", "person_mayu"),
		"undiscovered clue cannot be placed")
	assert_true(DetectiveNoteManager.set_placement(
		"ch0_demo", "library_lights", "evidence", "object_library_photo"),
		"object placed on object node")
	assert_true(DetectiveNoteManager.clear_placement("ch0_demo", "library_lights", "culprit"),
		"placement cleared")
	assert_eq(DetectiveNoteManager.get_placement("ch0_demo", "library_lights", "culprit"),
		"", "cleared node reads empty")
	assert_eq(str(SaveManager.exploration_flags.get("note_library_lights_culprit", "x")),
		"", "cleared placement writes empty flag")

func test_stamps() -> void:
	assert_eq(DetectiveNoteVault.get_stamp_ids(), ["stamp_kelly", "stamp_mayu", "stamp_nex"],
		"vault loads 3 stamps")
	var stamp: Dictionary = DetectiveNoteVault.get_stamp("stamp_kelly")
	assert_eq(DetectiveNoteVault.loc_text(stamp.get("name", "")), "Kelly Lastochkina",
		"stamp_kelly has approver name")
	assert_true(ResourceLoader.exists(str(stamp.get("image", ""))),
		"stamp_kelly image file exists")
	assert_true(not DetectiveNoteManager.is_topic_stamped("ch0_demo", "library_lights"),
		"topic not stamped initially")
	assert_true(not DetectiveNoteManager.apply_stamp("ch0_demo", "library_lights", "no_such_stamp"),
		"unknown stamp rejected")
	assert_true(not DetectiveNoteManager.apply_stamp("ch0_demo", "no_such_topic", "stamp_kelly"),
		"unknown topic rejected")
	assert_true(DetectiveNoteManager.apply_stamp("ch0_demo", "library_lights", "stamp_kelly"),
		"apply_stamp succeeds")
	assert_true(not DetectiveNoteManager.apply_stamp("ch0_demo", "library_lights", "stamp_mayu"),
		"second stamp on same topic rejected")
	assert_eq(DetectiveNoteManager.get_topic_stamp("ch0_demo", "library_lights"),
		"stamp_kelly", "stamp id readable")
	var stamp_angle: float = DetectiveNoteManager.get_topic_stamp_angle(
		"ch0_demo", "library_lights")
	assert_true(stamp_angle >= DetectiveNoteManager.STAMP_TILT_MIN_DEG
		and stamp_angle <= DetectiveNoteManager.STAMP_TILT_MAX_DEG,
		"apply_stamp saves random tilt angle")
	var angle_again: float = DetectiveNoteManager.get_topic_stamp_angle(
		"ch0_demo", "library_lights")
	assert_eq(stamp_angle, angle_again, "stamp tilt angle is stable after apply")
	assert_true(not DetectiveNoteManager.set_placement(
		"ch0_demo", "library_lights", "culprit", "person_kelly"),
		"stamped topic is read-only (placement rejected)")
	assert_eq(DetectiveNoteManager.get_placement("ch0_demo", "library_lights", "evidence"),
		"object_library_photo", "existing placements retained after stamp")

func test_save_roundtrip() -> void:
	var snapshot: Dictionary = DetectiveNoteManager.to_save_dict()
	var expected_stamp_angle: float = DetectiveNoteManager.get_topic_stamp_angle(
		"ch0_demo", "library_lights")
	assert_true(snapshot.has("detective_notes"), "save dict has detective_notes key")
	DetectiveNoteManager.reset_all()
	assert_true(not DetectiveNoteManager.has_clue("ch0_demo", "person_kelly"),
		"reset clears progress")
	DetectiveNoteManager.load_from_save(snapshot)
	assert_true(DetectiveNoteManager.has_clue("ch0_demo", "person_kelly"),
		"load_from_save restores clues")
	assert_eq(DetectiveNoteManager.get_topic_level("ch0_demo", "library_lights"), 2,
		"load_from_save restores topic level")
	assert_eq(DetectiveNoteManager.get_placement("ch0_demo", "library_lights", "evidence"),
		"object_library_photo", "load_from_save restores placements")
	assert_eq(DetectiveNoteManager.get_topic_stamp("ch0_demo", "library_lights"),
		"stamp_kelly", "load_from_save restores stamp")
	assert_eq(DetectiveNoteManager.get_topic_stamp_angle("ch0_demo", "library_lights"),
		expected_stamp_angle, "load_from_save restores stamp tilt angle")

func test_vault_manager_overlay() -> void:
	var host := Control.new()
	add_child(host)
	DetectiveNoteVaultManager.open(host)
	await get_tree().process_frame
	var overlay: DetectiveNoteVaultManager = \
		host.get_node_or_null("DetectiveNoteVaultManagerOverlay") as DetectiveNoteVaultManager
	assert_true(overlay != null, "vault manager overlay opens")
	if overlay == null:
		host.queue_free()
		return
	assert_eq(overlay._ch_list.item_count, 3, "chapters list shows 3 chapters")
	assert_eq(overlay._topic_list.item_count, 1, "topic list shows 1 topic")
	assert_eq(overlay._node_rows.size(), 3, "topic editor shows 3 node rows")
	assert_eq(overlay._edge_rows.size(), 2, "topic editor shows 2 edge rows")
	overlay._switch_tab("clues")
	assert_eq(overlay._clues.size(), DetectiveNoteVault.get_clues().size(),
		"clues tab loads all vault clues")
	assert_true(overlay._clue_tree != null and is_instance_valid(overlay._clue_tree),
		"clues tab uses a folder Tree")
	assert_true(overlay._clue_group != null, "clue form has Group field")
	assert_true(overlay._clue_tree.get_root() != null
		and overlay._clue_tree.get_root().get_child_count() >= 1,
		"clue Tree has at least one folder group")
	overlay._switch_tab("stamps")
	assert_eq(overlay._stamp_list.item_count, 3, "stamps list shows 3 stamps")

	# Editor round-trip: flush without edits must not change the data.
	overlay._switch_tab("chapters")
	overlay._flush_all()
	var flushed_topic: Dictionary = ((overlay._chapters[0] as Dictionary)
		.get("topics", []) as Array)[0] as Dictionary
	var original_topic: Dictionary = DetectiveNoteVault.get_topic("ch0_demo", "library_lights")
	assert_eq(str(flushed_topic.get("id", "")), str(original_topic.get("id", "")),
		"flush keeps topic id")
	assert_eq((flushed_topic.get("nodes", []) as Array).size(),
		(original_topic.get("nodes", []) as Array).size(), "flush keeps node count")
	assert_eq((flushed_topic.get("edges", []) as Array).size(),
		(original_topic.get("edges", []) as Array).size(), "flush keeps edge count")
	var flushed_node: Dictionary = (flushed_topic.get("nodes", []) as Array)[0] as Dictionary
	var original_node: Dictionary = (original_topic.get("nodes", []) as Array)[0] as Dictionary
	var flushed_pos: Array = flushed_node.get("pos", []) as Array
	var original_pos: Array = original_node.get("pos", []) as Array
	assert_true(flushed_pos.size() == 2 and original_pos.size() == 2
		and is_equal_approx(float(flushed_pos[0]), float(original_pos[0]))
		and is_equal_approx(float(flushed_pos[1]), float(original_pos[1])),
		"flush keeps node position")
	assert_eq(str(flushed_node.get("kind", "")), str(original_node.get("kind", "")),
		"flush keeps node kind")
	assert_eq(DetectiveNoteVault.loc_text(flushed_node.get("label", ""), "th"),
		DetectiveNoteVault.loc_text(original_node.get("label", ""), "th"),
		"flush keeps localized node label")
	assert_eq(DetectiveNoteVault.node_label_side(flushed_node),
		DetectiveNoteVault.node_label_side(original_node),
		"flush keeps node label side")

	assert_true(overlay._validate().is_empty(), "sample data passes validation")

	# Start clues round-trip through chapter flush.
	var flushed_ch: Dictionary = overlay._chapters[0] as Dictionary
	assert_eq((flushed_ch.get("start_clues", []) as Array), ["info_blackout_schedule"],
		"flush keeps chapter start_clues")

	overlay._edge_rows.clear()  # simulate broken edit state without UI
	host.queue_free()
	await get_tree().process_frame

func test_admin_command_registered() -> void:
	assert_true(MailboxManager.admin_command("help").contains("detective_note_vault"),
		"admin help lists detective_note_vault")

func test_verdict_map_renderer() -> void:
	var host := Control.new()
	host.size = Vector2(1200, 800)
	add_child(host)
	var topic: Dictionary = DetectiveNoteVault.get_topic("ch0_demo", "library_lights")

	var map := DetectiveNoteVerdictMap.new()
	host.add_child(map)
	map.setup(topic, 1, DetectiveNoteVerdictMap.Mode.PLAYER,
		{"culprit": "person_kelly"})
	await get_tree().process_frame
	assert_eq(map._hit_areas.size(), 2, "level 1 map builds 2 node hit areas")
	assert_eq(map.effective_clue("culprit"), "person_kelly",
		"placement resolves on node")
	map.setup(topic, 2, DetectiveNoteVerdictMap.Mode.PLAYER, {})
	await get_tree().process_frame
	assert_eq(map._hit_areas.size(), 3, "level 2 map builds 3 node hit areas")
	var extent: Vector2 = map.content_extent()
	assert_true(extent.x >= 560.0 and extent.y >= 520.0,
		"content extent covers all frames plus margin")

	# Drop validation: object clue rejected on individual node, accepted on object node.
	assert_true(not map._node_can_drop("culprit", {"detective_clue": "object_library_photo"}),
		"renderer rejects object on individual frame")
	assert_true(map._node_can_drop("evidence", {"detective_clue": "object_library_photo"}),
		"renderer accepts object on object frame")
	assert_true(not map._node_can_drop("culprit", {"foo": 1}),
		"renderer rejects foreign drag data")
	var culprit_rect: Rect2 = map._node_rect(
		DetectiveNoteVault.get_topic_node(topic, "culprit"))
	var drop_pos: Vector2 = culprit_rect.get_center()
	assert_true(map._can_drop_data(drop_pos, {"detective_clue": "person_kelly"}),
		"map accepts clue drop at node frame")
	var dropped: Array = []
	map.clue_drop_requested.connect(func(nid: String, cid: String, _from: String) -> void:
		dropped.append([nid, cid]))
	map._drop_data(drop_pos, {"detective_clue": "person_kelly", "from_node": ""})
	assert_eq(dropped.size(), 1, "map drop_data emits placement signal")
	assert_eq(dropped[0], ["culprit", "person_kelly"], "map drop_data targets culprit node")

	var prefill_topic: Dictionary = DetectiveNoteVault.get_topic(
		"ch0_prologue", "topic_where_have_mayu_notebook_gone")
	map.setup(prefill_topic, 1, DetectiveNoteVerdictMap.Mode.PLAYER, {})
	await get_tree().process_frame
	assert_true(map.is_node_prefilled("node_individual_1"),
		"prefilled node is flagged")
	assert_eq(map.effective_clue("node_individual_1"), "person_mayu",
		"prefill clue resolves on node")
	assert_true(not map._node_can_drop("node_individual_1", {"detective_clue": "person_kelly"}),
		"prefilled node rejects clue drops")

	# Stamp display (static, no animation await needed).
	map.show_stamp("stamp_kelly", false, 9.5)
	assert_true(map.has_stamp_visible(), "stamp renders on map")
	assert_true(map._stamp_cluster != null, "stamp cluster exists")
	assert_true(is_equal_approx(map._stamp_cluster.rotation, deg_to_rad(9.5)),
		"stamp renders at saved tilt angle")
	map.clear_stamp()
	assert_true(not map.has_stamp_visible(), "stamp clears")

	host.queue_free()
	await get_tree().process_frame

func test_note_overlay() -> void:
	# Prepare progress: discovered clues + unlocked topic (unstamped fresh state).
	DetectiveNoteManager.reset_all()
	DetectiveNoteManager.add_clue("ch0_demo", "person_kelly")
	DetectiveNoteManager.add_clue("ch0_demo", "object_library_photo")
	DetectiveNoteManager.add_clue("ch0_demo", "info_blackout_schedule")
	DetectiveNoteManager.unlock_topic("ch0_demo", "library_lights")

	var host := Control.new()
	host.size = Vector2(1600, 900)
	add_child(host)
	var overlay: DetectiveNoteOverlay = DetectiveNoteOverlay.open_for_chapter(host, "ch0_demo")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(is_instance_valid(overlay), "note overlay opens for chapter")
	assert_true(overlay.size.x > 400.0, "overlay fills viewport width")
	assert_true(overlay._notebook_area.size.x > 200.0, "notebook column has usable width")
	assert_true(overlay._root_panel.size.x > 500.0, "root panel expands across overlay")
	assert_eq(overlay._selected_chapter, "ch0_demo", "active chapter selected")
	assert_eq(overlay._selected_topic, "library_lights", "preferred unlocked topic selected")
	assert_false(overlay._chapter_scroll.visible, "VN/exploration overlay hides chapter section")
	assert_true(overlay._topic_header.visible, "topic section stays visible")
	assert_eq(overlay._map.mode, DetectiveNoteVerdictMap.Mode.PLAYER,
		"unstamped topic map is in player mode")

	overlay._switch_clue_tab("individual")
	assert_eq(overlay._clue_grid.get_child_count(), 1, "PEOPLE tab shows 1 discovered individual")
	overlay._switch_clue_tab("information")
	assert_eq(overlay._clue_grid.get_child_count(), 1, "INFO tab shows 1 discovered information")

	# Simulate a drop through the map signal path.
	overlay._on_map_drop_requested("culprit", "person_kelly", "")
	assert_eq(DetectiveNoteManager.get_placement("ch0_demo", "library_lights", "culprit"),
		"person_kelly", "drop through overlay writes placement")
	overlay._on_map_drop_requested("culprit", "", "")
	assert_eq(DetectiveNoteManager.get_placement("ch0_demo", "library_lights", "culprit"),
		"", "right-click clear through overlay removes placement")

	overlay._on_map_drop_requested("culprit", "person_kelly", "")
	assert_eq(DetectiveNoteManager.get_placement("ch0_demo", "library_lights", "culprit"),
		"person_kelly", "re-place clue for removal tests")
	assert_true(overlay._clue_panel_can_accept_drag(
		{"detective_clue": "person_kelly", "from_node": "culprit"}),
		"clue panel accepts drag-back from map frame")
	assert_false(overlay._clue_panel_can_accept_drag(
		{"detective_clue": "person_kelly", "from_node": ""}),
		"clue panel rejects new clue drags from panel")
	overlay._clue_panel_accept_drag({"detective_clue": "person_kelly", "from_node": "culprit"})
	assert_eq(DetectiveNoteManager.get_placement("ch0_demo", "library_lights", "culprit"),
		"", "drag-back to clue panel removes placement")

	var map: DetectiveNoteVerdictMap = overlay._map
	map.set_placements({"culprit": "person_kelly"})
	var hit: Control = map._hit_areas["culprit"] as Control
	var dbl := InputEventMouseButton.new()
	dbl.button_index = MOUSE_BUTTON_LEFT
	dbl.pressed = true
	dbl.double_click = true
	var cleared: Array = []
	map.clue_drop_requested.connect(func(nid: String, cid: String, _from: String) -> void:
		cleared.append([nid, cid]), CONNECT_ONE_SHOT)
	map._node_gui_input("culprit", hit, dbl)
	assert_eq(cleared, [["culprit", ""]], "double-click frame requests clue removal")

	var closed_seen: Array = [false]
	overlay.closed.connect(func() -> void: closed_seen[0] = true)
	overlay._close()
	await get_tree().process_frame
	assert_true(closed_seen[0], "closed signal emitted")

	# Stamped topic renders read-only with stamp visible.
	DetectiveNoteManager.apply_stamp("ch0_demo", "library_lights", "stamp_mayu")
	var overlay2: DetectiveNoteOverlay = DetectiveNoteOverlay.open_for_chapter(host, "ch0_demo")
	await get_tree().process_frame
	assert_eq(overlay2._map.mode, DetectiveNoteVerdictMap.Mode.READONLY,
		"stamped topic map is read-only")
	assert_true(overlay2._map.has_stamp_visible(), "stamped topic shows stamp permanently")
	overlay2._close()

	# Stamp view mode: hidden side panels; click or any key dismisses.
	var stamp_view: DetectiveNoteOverlay = DetectiveNoteOverlay.open_stamp_view(
		host, "ch0_demo", "library_lights")
	await get_tree().process_frame
	assert_true(stamp_view._stamp_view_dismissable,
		"stamp view is dismissable with click or key")
	stamp_view._close()
	host.queue_free()
	await get_tree().process_frame
	DetectiveNoteManager.reset_all()

func test_layout_editor_writeback() -> void:
	var host := Control.new()
	add_child(host)
	DetectiveNoteVaultManager.open(host)
	await get_tree().process_frame
	var mgr: DetectiveNoteVaultManager = \
		host.get_node_or_null("DetectiveNoteVaultManagerOverlay") as DetectiveNoteVaultManager
	assert_true(mgr != null, "vault manager opens for layout test")
	if mgr == null:
		host.queue_free()
		return
	mgr._on_open_layout_editor()
	await get_tree().process_frame
	assert_true(mgr._layout_map != null and is_instance_valid(mgr._layout_map),
		"layout editor opens with WYSIWYG map")
	assert_eq(mgr._layout_map.mode, DetectiveNoteVerdictMap.Mode.EDIT,
		"layout map is in edit mode")

	# Node move writes back into the form spinboxes.
	mgr._layout_map.emit_signal("edit_node_moved", "culprit", Vector2(300, 200))
	var moved: bool = false
	for r: Dictionary in mgr._node_rows:
		if (r["id"] as LineEdit).text.strip_edges() == "culprit":
			moved = int((r["px"] as SpinBox).value) == 300 \
				and int((r["py"] as SpinBox).value) == 200
	assert_true(moved, "WYSIWYG node drag writes position into form row")
	assert_true(mgr._dirty, "layout edit marks vault dirty")

	# Edge creation adds a form row; duplicates rejected.
	var edge_rows_before: int = mgr._edge_rows.size()
	mgr._layout_map.emit_signal("edit_edge_created", "culprit", "motive")
	assert_eq(mgr._edge_rows.size(), edge_rows_before + 1,
		"WYSIWYG edge drag adds edge row")
	mgr._layout_map.emit_signal("edit_edge_created", "culprit", "motive")
	assert_eq(mgr._edge_rows.size(), edge_rows_before + 1,
		"duplicate edge rejected")

	mgr._close_layout_editor()
	assert_true(mgr._layout_overlay == null, "layout editor closes")
	host.queue_free()
	await get_tree().process_frame

# ── Phase 4: entry points, beats, actions, toasts ────────────

func test_exploration_note_actions() -> void:
	DetectiveNoteManager.reset_all()
	# Explicit chapter in value — no exploration session needed.
	ExplorationManager.process_events([
		{"action": "note_add_clue", "key": "person_kelly", "value": "ch0_demo"}])
	assert_true(DetectiveNoteManager.has_clue("ch0_demo", "person_kelly"),
		"note_add_clue event adds clue (explicit chapter)")
	ExplorationManager.process_events([
		{"action": "note_unlock_topic", "key": "library_lights", "value": "ch0_demo"}])
	assert_true(DetectiveNoteManager.is_topic_unlocked("ch0_demo", "library_lights"),
		"note_unlock_topic event unlocks topic (explicit chapter)")
	# No session + no explicit chapter → warning only, nothing granted.
	DetectiveNoteManager.reset_all()
	ExplorationManager.process_events([
		{"action": "note_add_clue", "key": "person_kelly", "value": ""}])
	assert_true(not DetectiveNoteManager.has_clue("ch0_demo", "person_kelly"),
		"note_add_clue without resolvable chapter is a safe no-op")
	DetectiveNoteManager.reset_all()

func test_note_toaster() -> void:
	assert_true(DetectiveNoteToaster._toast_host != null, "toaster host built")
	# Earlier tests may have left a toast playing (each grant fires a toast and
	# holds the queue for ~3.7s), so assert on queue/active deltas, not idle state.
	DetectiveNoteManager.reset_all()
	var q_before: int = DetectiveNoteToaster._queue.size()
	DetectiveNoteManager.add_clue("ch0_demo", "person_kelly")
	await get_tree().process_frame
	var queued: bool = DetectiveNoteToaster._queue.size() == q_before + 1
	var shown: bool = DetectiveNoteToaster._active \
		and DetectiveNoteToaster._toast_host.get_child_count() > 0
	assert_true(queued or shown, "new clue queues or shows a detective note toast")
	# Unknown notification kinds are ignored.
	var q_mid: int = DetectiveNoteToaster._queue.size()
	DetectiveNoteToaster._on_note_notification("bogus_kind", "ch0_demo", "x")
	assert_eq(DetectiveNoteToaster._queue.size(), q_mid,
		"unknown notification kind not queued")
	DetectiveNoteManager.reset_all()

func test_vn_note_beats() -> void:
	var vn: Control = (load("res://scripts/VNPlayer.gd") as GDScript).new()
	assert_true(vn._beat_has_deferred_actions(
		{"show_note_stamp": {"topic": "library_lights", "stamp": "stamp_kelly"}}),
		"show_note_stamp beat counts as deferred action")
	assert_true(not vn._beat_has_deferred_actions({"detective_note": []}),
		"detective_note grants are not deferred")

	DetectiveNoteManager.reset_all()
	vn._apply_detective_note_actions([
		{"action": "add_clue", "id": "person_kelly", "chapter": "ch0_demo"},
		{"action": "unlock_topic", "id": "library_lights", "chapter": "ch0_demo"},
		{"action": "upgrade_topic", "id": "library_lights", "chapter": "ch0_demo"},
	])
	assert_true(DetectiveNoteManager.has_clue("ch0_demo", "person_kelly"),
		"VN detective_note add_clue applies")
	assert_eq(DetectiveNoteManager.get_topic_level("ch0_demo", "library_lights"), 2,
		"VN upgrade_topic without level bumps +1")

	DetectiveNoteManager.reset_all()
	var q_before: int = DetectiveNoteToaster._queue.size()
	vn._apply_detective_note_actions([
		{"action": "add_clue", "id": "object_library_photo", "chapter": "ch0_demo", "silent": true},
	])
	assert_true(DetectiveNoteManager.has_clue("ch0_demo", "object_library_photo"),
		"VN silent add_clue grants clue")
	assert_eq(DetectiveNoteToaster._queue.size(), q_before,
		"VN silent add_clue does not queue toast")

	# Scene → chapter resolution drives the note icon chapter.
	vn._scene_path = "res://campaign/scenes/ch0_s1_pre_DEMO_PART1.json"
	vn._refresh_note_icon()
	assert_eq(vn._note_chapter_id, "ch0_demo", "mapped VN scene resolves note chapter")
	vn._scene_path = "res://campaign/scenes/unmapped.json"
	vn._refresh_note_icon()
	assert_eq(vn._note_chapter_id, "", "unmapped VN scene leaves note icon hidden")
	vn.free()
	DetectiveNoteManager.reset_all()

	# With the full UI built, the icon control follows chapter resolution.
	var vn_ui: Control = (load("res://scripts/VNPlayer.gd") as GDScript).new()
	add_child(vn_ui)
	assert_true(vn_ui._note_icon != null, "dialog panel builds detective note icon")
	assert_true(not vn_ui._note_icon.visible, "note icon hidden before a scene resolves")
	vn_ui._scene_path = "res://campaign/scenes/ch0_s1_pre_DEMO_PART1.json"
	vn_ui._refresh_note_icon()
	assert_true(vn_ui._note_icon.visible, "note icon visible for mapped scene")
	vn_ui._scene_path = "res://campaign/scenes/unmapped.json"
	vn_ui._refresh_note_icon()
	assert_true(not vn_ui._note_icon.visible, "note icon hides for unmapped scene")
	remove_child(vn_ui)
	vn_ui.free()

func test_inventory_note_tab() -> void:
	DetectiveNoteManager.reset_all()
	var inv: Control = (load("res://scripts/InventoryMenu.gd") as GDScript).new()
	add_child(inv)
	await get_tree().process_frame
	assert_true(inv._tab_note_btn != null, "inventory has NOTE tab")
	inv._on_note_tab()
	await get_tree().process_frame
	var overlay: DetectiveNoteOverlay = inv._note_overlay
	assert_true(overlay != null and is_instance_valid(overlay),
		"NOTE tab opens all-chapters detective note overlay")
	if overlay != null and is_instance_valid(overlay):
		assert_true(overlay._all_chapters_mode, "inventory note overlay shows all chapters")
		assert_true(overlay._chapter_scroll.visible, "inventory note overlay shows chapter section")
		assert_eq(overlay._chapter_vbox.get_child_count(), 0,
			"inventory hides chapters until story progress")
		overlay._close()
		await get_tree().process_frame
	DetectiveNoteManager.add_clue("ch0_prologue", "person_nex", true)
	inv._on_note_tab()
	await get_tree().process_frame
	overlay = inv._note_overlay
	if overlay != null and is_instance_valid(overlay):
		assert_true(overlay._chapter_vbox.get_child_count() >= 1,
			"inventory shows unlocked chapter after progress")
		overlay._close()
		await get_tree().process_frame
		assert_true(inv._note_overlay == null, "closing note overlay clears inventory ref")
	inv.queue_free()
	await get_tree().process_frame

func test_note_test_scene_json() -> void:
	var path := "res://campaign/scenes/vn_detective_note_test.json"
	var f := FileAccess.open(path, FileAccess.READ)
	assert_true(f != null, "vn_detective_note_test.json exists")
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	assert_true(parsed is Array, "note test scene is a beat array")
	assert_eq(DetectiveNoteVault.resolve_chapter_for_context(path, ""), "ch0_demo",
		"note test scene registered to ch0_demo in the vault")
	var stamp_found: Dictionary = {}
	var granted_ids: Array = []
	for beat: Variant in (parsed as Array):
		if not beat is Dictionary:
			continue
		var bd: Dictionary = beat as Dictionary
		if bd.get("show_note_stamp", null) is Dictionary:
			stamp_found = bd["show_note_stamp"]
		for act: Variant in (bd.get("detective_note", []) as Array):
			if act is Dictionary:
				granted_ids.append(str((act as Dictionary).get("id", "")))
	assert_true(granted_ids.has("person_kelly") and granted_ids.has("info_blackout_schedule"),
		"test scene grants known clues")
	assert_true(DetectiveNoteVault.has_stamp(str(stamp_found.get("stamp", ""))),
		"test scene stamp exists in vault")
	assert_true(not DetectiveNoteVault.get_topic(
		"ch0_demo", str(stamp_found.get("topic", ""))).is_empty(),
		"test scene stamp topic exists in vault")
