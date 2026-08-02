extends Node
## Smoke test for the Omen UI surfaces.
##   godot --headless --path . res://tools/omen_ui_smoke.tscn      # assertions only
##   godot --path . res://tools/omen_ui_smoke.tscn -- shots        # also writes PNGs

const SHOT_DIR: String = "user://omen_ui_shots"

var _failures: Array[String] = []
var _shots: bool = false
var _host: Control = null


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok   ", what)
	else:
		_failures.append(what)
		print("  FAIL ", what)


func _ready() -> void:
	_shots = OS.get_cmdline_user_args().has("shots")
	if _shots:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))

	_host = Control.new()
	_host.size = Vector2(1280, 720)
	add_child(_host)

	_test_data_layer()
	# SaveManager finishes loading decks a few frames after boot.
	await _settle()
	_seed_state()
	await _test_overlays()

	print("")
	if _failures.is_empty():
		print("SMOKE OK")
	else:
		print("SMOKE FAILED: ", _failures)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _test_data_layer() -> void:
	var omen: Dictionary = OmenDatabase.get_omen("keen_edge")
	_check(not omen.is_empty(), "OmenDatabase has keen_edge")

	var capsule: Control = OmenVisuals.build_capsule(omen, 156.0)
	_host.add_child(capsule)
	_check(capsule != null and capsule.get_child_count() >= 4, "OmenVisuals.build_capsule")
	capsule.queue_free()

	_check(OmenVisuals.rows_for_card("Tiny Pixie").is_empty(), "no omen rows before grant")


## Deck + held omens so every surface has something to draw.
func _seed_state() -> void:
	var deck: DeckData = SaveManager.get_battle_deck()
	if deck == null or deck.characters.size() < 6:
		deck = DeckData.new()
		deck.deck_name = "Smoke Test Deck"
		deck.characters = _sample(CardDatabase.characters.keys(), 10)
		deck.traps = _sample(CardDatabase.traps.keys(), 5)
		deck.techs = _sample(CardDatabase.tech_cards.keys(), 3)
		SaveManager.decks = [deck]
		SaveManager.active_deck_index = 0
	var anointed: String = str(deck.characters[0]) if not deck.characters.is_empty() else ""
	GameState.active_omens = [
		{"id": "keen_edge", "anointed_card": anointed},
		{"id": "third_eye", "anointed_card": ""},
		{"id": "rune_mannaz", "anointed_card": ""},
	]
	var rows: Array = OmenVisuals.rows_for_card(anointed)
	_check(rows.size() == 1, "rows_for_card finds the anointed card only")
	_check(OmenVisuals.held_rows().size() == 3, "held_rows returns every held omen")
	_check(OmenVisuals.has_any_omen(), "has_any_omen")

	var tile := Control.new()
	tile.size = Vector2(90, 124)
	_host.add_child(tile)
	_check(OmenBadge.attach_to_tile(tile, anointed, 20.0) != null, "badge on anointed card")
	_check(OmenBadge.attach_to_tile(tile, "Nobody At All", 20.0) == null, "no badge on plain card")
	tile.queue_free()


func _sample(names: Array, count: int) -> Array:
	var out: Array = []
	for n: Variant in names:
		if out.size() >= count:
			break
		out.append(str(n))
	return out


func _test_overlays() -> void:
	var omen_overlay: OmenDetailOverlay = OmenDetailOverlay.open(_host, 210)
	_check(omen_overlay != null, "OmenDetailOverlay.open")
	await _settle()
	await _shot("omens")
	if omen_overlay != null:
		omen_overlay.free()

	var deck_overlay: DeckViewOverlay = DeckViewOverlay.open(_host, 210)
	_check(deck_overlay != null, "DeckViewOverlay.open")
	await _settle()
	await _shot("view_deck")
	if deck_overlay != null:
		await _test_deck_view_tap(deck_overlay)
		deck_overlay.free()

	var anointed: String = str(GameState.active_omens[0].get("anointed_card", ""))
	CardDetailOverlay.open(_host, anointed, "character")
	await _settle()
	_check(CardDetailOverlay.find_first_in_tree(get_tree().root) != null,
			"CardDetailOverlay with omen dossier")
	await _shot("card_detail")
	var detail: CardDetailOverlay = CardDetailOverlay.find_first_in_tree(get_tree().root)
	if detail != null:
		detail.free()

	# Live battle instance: left Waiting/Exposed + right Once ATK + Omen.
	var inst := GameState.CardInstance.new()
	inst.card_name = anointed
	inst.card_type = "character"
	inst.face_up = true
	inst.attacked_this_turn = true
	inst.one_use_atk_boost_used = true
	inst.ability_type = CharacterData.AbilityType.ONE_USE_ATK_BOOST
	CardDetailOverlay.open_and_return(_host, anointed, "character", inst)
	await _settle()
	await _settle()
	_check(CardDetailOverlay.find_first_in_tree(get_tree().root) != null,
			"CardDetailOverlay with status tags")
	await _shot("card_detail_status")
	var detail2: CardDetailOverlay = CardDetailOverlay.find_first_in_tree(get_tree().root)
	if detail2 != null:
		detail2.free()

	var offer: Array = []
	for id: String in ["keen_edge", "free_snare", "third_eye"]:
		var o: Dictionary = OmenDatabase.get_omen(id)
		if not o.is_empty():
			offer.append(o)
	var choose := OmenSelectOverlay.new()
	choose._omens = offer
	_host.add_child(choose)
	# Capsules fog-condense for ~1s before text appears.
	await get_tree().create_timer(1.4).timeout
	_check(choose.is_inside_tree(), "OmenSelectOverlay builds")
	await _shot("choose_omen")
	choose.free()

	await _test_anoint_picker()


## Routes a real click through the viewport so hit-testing is exercised, not just
## the callback.
func _test_deck_view_tap(overlay: DeckViewOverlay) -> void:
	var tile: Control = _find_tile(overlay, DeckViewOverlay.TILE)
	_check(tile != null, "deck view has a card tile")
	if tile == null:
		return
	_click(tile.get_global_rect().get_center())
	await _settle()
	var full: CardDetailOverlay = CardDetailOverlay.find_first_in_tree(overlay)
	if full == null:
		full = CardDetailOverlay.find_first_in_tree(get_tree().root)
	_check(full != null, "tapping a deck view card opens the full card")
	_check(full != null and full.get_parent() == overlay,
			"full card is pinned to the deck view")
	await _shot("view_deck_full_card")
	if full == null:
		return

	# Outside the card (top-left dimmer) must dismiss the overlay.
	_click(Vector2(24.0, 24.0))
	await _settle()
	_check(CardDetailOverlay.find_first_in_tree(get_tree().root) == null,
			"tap outside the card dismisses the full card")
	_check(is_instance_valid(overlay) and overlay.is_inside_tree()
			and overlay.mouse_filter == Control.MOUSE_FILTER_STOP,
			"outside tap leaves the deck view open")

	# Re-open for the Escape path.
	overlay._open_full_card(str((overlay._deck.characters[0] if overlay._deck != null \
			and not overlay._deck.characters.is_empty() else "")), "character")
	await _settle()
	_press_escape()
	await _settle()
	_check(CardDetailOverlay.find_first_in_tree(get_tree().root) == null,
			"escape closes the full card")
	_check(is_instance_valid(overlay) and overlay.is_inside_tree()
			and overlay.mouse_filter == Control.MOUSE_FILTER_STOP,
			"escape leaves the deck view open")


func _find_tile(node: Node, tile_size: Vector2) -> Control:
	var ctrl := node as Control
	if ctrl != null and ctrl.custom_minimum_size == tile_size \
			and ctrl.mouse_filter == Control.MOUSE_FILTER_STOP:
		return ctrl
	for child: Node in node.get_children():
		var found: Control = _find_tile(child, tile_size)
		if found != null:
			return found
	return null


func _press_escape() -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = KEY_ESCAPE
		ev.physical_keycode = KEY_ESCAPE
		ev.pressed = pressed
		get_viewport().push_input(ev)


func _click(at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = at
		ev.global_position = at
		get_viewport().push_input(ev)


func _test_anoint_picker() -> void:
	var entries: Array = ExplorationManager.build_deck_card_meta_for_omens()
	var picker: OmenAnointPicker = await _open_picker("keen_edge", entries, "anoint_picker")
	if picker == null:
		return

	picker._open_full_card(str((picker._eligible[0] as Dictionary).get("name", "")))
	await _settle()
	var full: CardDetailOverlay = CardDetailOverlay.find_first_in_tree(picker)
	if full == null:
		full = CardDetailOverlay.find_first_in_tree(get_tree().root)
	_check(full != null, "full card opens from the picker")
	_check(full != null and full.get_parent() == picker,
			"full card is the existing CardDetailOverlay pinned to the picker")
	await _shot("anoint_picker_full_card")
	if full != null:
		full.free()
	picker.free()

	# Filtered, non-unit omen: exercises the requirement copy and trap chips.
	var trap_picker: OmenAnointPicker = await _open_picker("free_snare", entries,
			"anoint_picker_trap")
	if trap_picker != null:
		trap_picker.free()


func _open_picker(omen_id: String, entries: Array, shot_name: String) -> OmenAnointPicker:
	var omen: Dictionary = OmenDatabase.get_omen(omen_id)
	var eligible: Array = OmenDatabase.get_eligible_deck_cards(omen, entries)
	_check(not eligible.is_empty(), "eligible cards for %s" % omen_id)
	if eligible.is_empty():
		return null

	var picker := OmenAnointPicker.new()
	picker._omen = omen
	picker._eligible = eligible
	_host.add_child(picker)
	await _settle()
	await _settle()
	_check(picker.is_inside_tree(), "OmenAnointPicker builds for %s" % omen_id)
	_check(picker._panel.size.y <= picker.size.y, "picker panel fits viewport (%s)" % omen_id)
	await _shot(shot_name)
	return picker


func _settle() -> void:
	for _i: int in range(6):
		await get_tree().process_frame


func _shot(tag: String) -> void:
	if not _shots:
		return
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "%s/%s.png" % [SHOT_DIR, tag]
	img.save_png(path)
	print("  shot ", ProjectSettings.globalize_path(path))
