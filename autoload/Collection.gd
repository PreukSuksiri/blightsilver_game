extends Node
# Tracks everything the player owns: credits and card copies.
# Each owned card copy records which booster pack it came from.
# Registered as autoload "Collection" in project.godot.

signal credits_changed(new_amount: int)
signal collection_changed()

const STARTING_CREDITS: int = 2000

var credits:      int = STARTING_CREDITS
var music_discs:  int = 0

# owned[card_name] = {
#   "type": "character" | "trap" | "tech",
#   "copies": Array[String]   # one element per copy; value = source pack name
# }
# Example:
#   owned["Pyromancer"] = {"type": "character", "copies": ["Starter Pack", "Fighters Pack"]}
var owned: Dictionary = {}

# ─────────────────────────────────────────────────────────────
# Credits
# ─────────────────────────────────────────────────────────────
func add_credits(amount: int) -> void:
	credits += amount
	emit_signal("credits_changed", credits)
	SaveManager.save_data()

## Returns false and does nothing if the player cannot afford it.
func spend_credits(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	emit_signal("credits_changed", credits)
	SaveManager.save_data()
	return true

# ─────────────────────────────────────────────────────────────
# Cards
# ─────────────────────────────────────────────────────────────

## Add one copy of a card to the collection, tagged with the pack it came from.
func add_card(card_name: String, card_type: String, from_pack: String) -> void:
	if not owned.has(card_name):
		owned[card_name] = {"type": card_type, "copies": []}
	owned[card_name]["copies"].append(from_pack)
	emit_signal("collection_changed")
	SaveManager.save_data()

func add_music_disc(count: int = 1) -> void:
	music_discs += count
	emit_signal("collection_changed")
	SaveManager.save_data()

## Returns false if the player has no discs.
func spend_music_disc() -> bool:
	if music_discs <= 0:
		return false
	music_discs -= 1
	emit_signal("collection_changed")
	SaveManager.save_data()
	return true

func get_card_count(card_name: String) -> int:
	if not owned.has(card_name):
		return 0
	return owned[card_name]["copies"].size()

func has_card(card_name: String) -> bool:
	return get_card_count(card_name) > 0

## Returns the list of pack names this card was obtained from (one per copy).
func get_copy_sources(card_name: String) -> Array:
	if owned.has(card_name):
		return owned[card_name].get("copies", [])
	return []

func get_card_type(card_name: String) -> String:
	if owned.has(card_name):
		return owned[card_name].get("type", "")
	return ""

## All owned card names.
func get_owned_names() -> Array:
	return owned.keys()

# ─────────────────────────────────────────────────────────────
# Serialisation — called by SaveManager
# ─────────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"credits":      credits,
		"owned":        owned.duplicate(true),
		"music_discs":  music_discs,
	}

func load_from_dict(d: Dictionary) -> void:
	credits     = d.get("credits",     STARTING_CREDITS)
	owned       = d.get("owned",       {})
	music_discs = d.get("music_discs", 0)
