extends Node
## OnboardingManager — first-run player setup.
##
## Runs once when no save file exists: grants the starter deck template,
## collection copies, initial credits, and unlocks the union mechanism.

signal onboarding_applied()
signal onboarding_settled

const DeckData = preload("res://resources/DeckData.gd")
const STARTING_DECK_PATH: String = "res://data/starting_deck.json"
const STARTER_SOURCE: String = "Starter Deck"

var _settled := false


func is_settled() -> bool:
	return _settled


func wait_until_settled() -> void:
	if _settled:
		return
	await onboarding_settled


func _mark_settled() -> void:
	if _settled:
		return
	_settled = true
	onboarding_settled.emit()

func _ready() -> void:
	call_deferred("_run_onboarding_check")

func _run_onboarding_check() -> void:
	# Must load save data before checking decks — otherwise empty in-memory defaults
	# look like a first-run and overwrite save_data.json (including tutorial skip).
	await SaveManager.bootstrap_async()
	if not is_inside_tree():
		return
	if SaveManager.decks.is_empty():
		if SaveManager.onboarding_complete:
			_recover_missing_decks()
		else:
			_apply_first_run_onboarding()
		_mark_settled()
		return
	if SaveManager.onboarding_complete:
		_mark_settled()
		return
	# Existing save with decks but no onboarding flag — legacy migration.
	SaveManager.onboarding_complete = true
	SaveManager.save_data()
	print("[OnboardingManager] Existing save marked onboarded (no reset).")
	_mark_settled()

func _recover_missing_decks() -> void:
	if not install_starter_deck(false, true):
		push_error("OnboardingManager: failed to recover missing starter deck.")
		return
	SaveManager.save_data()
	Collection.emit_signal("collection_changed")
	print("[OnboardingManager] Recovered missing starter deck.")

## Load the project starter deck template from data/starting_deck.json.
func load_starter_template() -> DeckData:
	var deck := DeckData.new()
	deck.deck_name = "Starter Deck"
	if not FileAccess.file_exists(STARTING_DECK_PATH):
		push_warning("OnboardingManager: missing starter deck at %s" % STARTING_DECK_PATH)
		return deck
	var file := FileAccess.open(STARTING_DECK_PATH, FileAccess.READ)
	if file == null:
		push_warning("OnboardingManager: could not read %s" % STARTING_DECK_PATH)
		return deck
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		deck.load_from_dict(parsed as Dictionary)
	return deck

## Install starter deck + matching collection copies into the live save state.
## Returns false if the template could not be loaded or is invalid.
func install_starter_deck(clear_collection: bool = false, replace_decks: bool = true) -> bool:
	var starter: DeckData = load_starter_template()
	if starter.characters.is_empty() and starter.traps.is_empty() and starter.techs.is_empty():
		push_error("OnboardingManager: starter deck template is empty.")
		return false
	if not starter.is_valid():
		push_warning(
			"OnboardingManager: starter deck template is not valid: %s"
			% starter.validation_message()
		)

	if clear_collection:
		Collection.owned.clear()

	Collection.grant_cards_from_deck(starter, STARTER_SOURCE)

	if replace_decks:
		SaveManager.decks.clear()
	var new_deck: DeckData = starter.duplicate_deck() as DeckData
	new_deck.ensure_identity()
	new_deck.limited = false
	new_deck.reserved_slot = 0
	SaveManager.allocate_gallery_slot(new_deck)
	SaveManager.decks.append(new_deck)
	SaveManager.active_deck_index = 0
	if "nex" not in SaveManager.unlocked_protagonists:
		SaveManager.unlocked_protagonists = ["nex"]
	SaveManager.equipped_deck_id_by_protagonist["nex"] = new_deck.deck_id
	SaveManager.current_protagonist_id = "nex"
	return true

func _apply_first_run_onboarding() -> void:
	if not install_starter_deck(false, true):
		push_error("OnboardingManager: first-run onboarding failed.")
		return

	# Persist Collection.STARTING_CREDITS (2000) and other first-run defaults.
	Collection.credits = Collection.STARTING_CREDITS
	SaveManager.union_mechanism_unlocked = true
	SaveManager.onboarding_complete = true
	SaveManager.save_data()
	Collection.emit_signal("collection_changed")
	SaveManager.emit_signal("union_mechanism_changed", true)
	emit_signal("onboarding_applied")
	print(
		"[OnboardingManager] First-run onboarding applied "
		+ "(starter deck, %d credits, union mechanism unlocked)." % Collection.credits
	)
