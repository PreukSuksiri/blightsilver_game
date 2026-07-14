extends Node
# Tests exploration #var_name# substitution in VN-facing text.
# Run: godot --headless --path . res://tests/test_vn_var_substitution.tscn

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
	print("\n=== VN Var Substitution Tests ===\n")
	run_all_tests()
	print("\n=== VN Var Substitution: %d passed, %d failed ===\n" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func run_all_tests() -> void:
	test_substitutes_named_vars()
	test_missing_var_becomes_empty()
	test_leaves_non_identifier_hashes()
	test_multiple_placeholders()
	test_loc_display_on_vn_player()
	test_translate_maps_value()
	test_translate_fallback_raw()
	test_translate_star_default()
	test_translate_multiple_pairs()
	test_translate_multiple_pairs_thai()
	test_allcapitalize()
	test_firstcapitalize()
	test_decapitalize()
	test_chain_translate_then_capitalize()
	test_clue_name_resolves_display_name()
	test_clue_name_unknown_keeps_id()

func test_substitutes_named_vars() -> void:
	ExplorationManager.set_var("var_investigation_object", "the ledger")
	var out: String = ExplorationManager.substitute_text_vars(
		"Look at #var_investigation_object#.")
	assert_eq(out, "Look at the ledger.", "substitutes exploration var in dialog text")
	ExplorationManager.set_var("var_investigation_object", "")

func test_missing_var_becomes_empty() -> void:
	var out: String = ExplorationManager.substitute_text_vars(
		"Missing [#unknown_thing#] end")
	assert_eq(out, "Missing [] end", "missing key becomes empty string")

func test_leaves_non_identifier_hashes() -> void:
	var out: String = ExplorationManager.substitute_text_vars("Keep # not a var # intact")
	assert_eq(out, "Keep # not a var # intact", "non-identifier hashes left alone")

func test_multiple_placeholders() -> void:
	ExplorationManager.set_var("aaa", "A")
	ExplorationManager.set_var("bbb", "B")
	var out: String = ExplorationManager.substitute_text_vars("#aaa# and #bbb#")
	assert_eq(out, "A and B", "multiple placeholders substituted")
	ExplorationManager.set_var("aaa", "")
	ExplorationManager.set_var("bbb", "")

func test_loc_display_on_vn_player() -> void:
	ExplorationManager.set_var("var_investigation_object", "keycard")
	var vn: VNPlayer = load("res://scripts/VNPlayer.gd").new()
	vn.locale = "en"
	var out: String = vn._loc_display({
		"en": "Found: #var_investigation_object#",
		"th": "พบ: #var_investigation_object#",
	})
	assert_eq(out, "Found: keycard", "VNPlayer _loc_display localises then substitutes")
	vn.locale = "th"
	out = vn._loc_display({
		"en": "Found: #var_investigation_object#",
		"th": "พบ: #var_investigation_object#",
	})
	assert_eq(out, "พบ: keycard", "VNPlayer _loc_display uses locale then substitutes")
	ExplorationManager.set_var("var_investigation_object", "")
	vn.free()

func test_translate_maps_value() -> void:
	ExplorationManager.set_var("var_person_name", "Nex")
	var out: String = ExplorationManager.substitute_text_vars(
		"#var_person_name%translate?Nex=I# think this is wrong.")
	assert_eq(out, "I think this is wrong.", "translate remaps matched value")
	ExplorationManager.set_var("var_person_name", "")

func test_translate_fallback_raw() -> void:
	ExplorationManager.set_var("var_person_name", "Kelly")
	var out: String = ExplorationManager.substitute_text_vars(
		"#var_person_name%translate?Nex=I#")
	assert_eq(out, "Kelly", "unmapped value keeps raw var")
	ExplorationManager.set_var("var_person_name", "")

func test_translate_star_default() -> void:
	ExplorationManager.set_var("var_person_name", "Kelly")
	var out: String = ExplorationManager.substitute_text_vars(
		"#var_person_name%translate?Nex=I&*=they#")
	assert_eq(out, "they", "star provides unmatched fallback")
	ExplorationManager.set_var("var_person_name", "")

func test_translate_multiple_pairs() -> void:
	ExplorationManager.set_var("var_person_name", "Mayu")
	var out: String = ExplorationManager.substitute_text_vars(
		"#var_person_name%translate?Nex=I&Mayu=she#")
	assert_eq(out, "she", "supports multiple From=To pairs")
	ExplorationManager.set_var("var_person_name", "")

func test_translate_multiple_pairs_thai() -> void:
	ExplorationManager.set_var("var_person_name", "Nex")
	var out_nex: String = ExplorationManager.substitute_text_vars(
		"#var_person_name%translate?Nex=ฉัน&Alice=นังตัวแสบ#")
	assert_eq(out_nex, "ฉัน", "Thai multi-map: Nex")
	ExplorationManager.set_var("var_person_name", "Alice")
	var out_alice: String = ExplorationManager.substitute_text_vars(
		"#var_person_name%translate?Nex=ฉัน&Alice=นังตัวแสบ#")
	assert_eq(out_alice, "นังตัวแสบ", "Thai multi-map: Alice via &")
	ExplorationManager.set_var("var_person_name", "")

func test_allcapitalize() -> void:
	ExplorationManager.set_var("var_person_name", "nex")
	var out: String = ExplorationManager.substitute_text_vars(
		"#var_person_name%allcapitalize=true#")
	assert_eq(out, "NEX", "allcapitalize uppercases all letters")
	ExplorationManager.set_var("var_person_name", "")

func test_firstcapitalize() -> void:
	ExplorationManager.set_var("var_person_name", "nex")
	var out: String = ExplorationManager.substitute_text_vars(
		"#var_person_name%firstcapitalize=true#")
	assert_eq(out, "Nex", "firstcapitalize capitalizes first letter only")
	ExplorationManager.set_var("var_person_name", "")

func test_decapitalize() -> void:
	ExplorationManager.set_var("var_person_name", "NEX")
	var out: String = ExplorationManager.substitute_text_vars(
		"#var_person_name%decapitalize=true#")
	assert_eq(out, "nex", "decapitalize lowercases all letters")
	ExplorationManager.set_var("var_person_name", "")

func test_chain_translate_then_capitalize() -> void:
	ExplorationManager.set_var("var_person_name", "Nex")
	var out: String = ExplorationManager.substitute_text_vars(
		"#var_person_name%translate?Nex=i%firstcapitalize=true#")
	assert_eq(out, "I", "translate then firstcapitalize applies left to right")
	ExplorationManager.set_var("var_person_name", "")

func test_clue_name_resolves_display_name() -> void:
	ExplorationManager.set_var("var_who", "person_nex")
	var out: String = ExplorationManager.substitute_text_vars(
		"Suspect is #var_who%clue_name=true#.", "en")
	assert_eq(out, "Suspect is Nex.", "clue_name resolves person_nex → Nex")
	ExplorationManager.set_var("var_who", "")

func test_clue_name_unknown_keeps_id() -> void:
	ExplorationManager.set_var("var_who", "not_a_real_clue")
	var out: String = ExplorationManager.substitute_text_vars(
		"#var_who%clue_name=true#", "en")
	assert_eq(out, "not_a_real_clue", "unknown clue id kept as-is")
	ExplorationManager.set_var("var_who", "")
