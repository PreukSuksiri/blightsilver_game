extends Node
func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.size = Vector2(1600, 900)
	add_child(host)
	GameState.active_omens = [{"id":"keen_edge","anointed_card":"Grand Fort Archer"}]
	var deck := SaveManager.get_battle_deck()
	if deck == null or deck.characters.is_empty():
		deck = DeckData.new()
		deck.deck_name = "T"
		deck.characters = ["Grand Fort Archer"]
		SaveManager.decks = [deck]
		SaveManager.active_deck_index = 0
	var ov := DeckViewOverlay.open(host, 210)
	await get_tree().process_frame
	await get_tree().process_frame
	var name := str(deck.characters[0])
	ov._open_full_card(name, "character")
	await get_tree().process_frame
	await get_tree().process_frame
	var detail := CardDetailOverlay.find_first_in_tree(get_tree().root)
	print("DETAIL before=", detail != null, " parent=", detail.get_parent().name if detail else null,
		" size=", detail.size if detail else null, " z=", detail.z_index if detail else null)
	# Click far left (should be dimmer)
	var at := Vector2(40, 450)
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = at
		ev.global_position = at
		get_viewport().push_input(ev)
	await get_tree().process_frame
	await get_tree().process_frame
	var after := CardDetailOverlay.find_first_in_tree(get_tree().root)
	print("DETAIL after click=", after != null)
	print("RESULT ", "OK" if after == null else "FAIL")
	get_tree().quit(0 if after == null else 1)
