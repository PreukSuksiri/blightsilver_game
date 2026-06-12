extends Node
# Tracks everything the player owns: credits and card copies.
# Each owned card copy records which booster pack it came from.
# Registered as autoload "Collection" in project.godot.

signal credits_changed(new_amount: int)
signal collection_changed()

const STARTING_CREDITS: int = 2000

var credits:          int        = STARTING_CREDITS
var music_discs:      int        = 0        # legacy — kept for save-file compat
var winding_keys:     int        = 0
var owned_discs:      Dictionary = {}       # disc_id -> count
var incenses:         int        = 0
var union_scrolls:    int        = 0
var card_drop_boosts: Dictionary = {}       # card_name -> float (cumulative bonus, e.g. 0.35 = +35%)

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

## Admin: set balance directly (clamped to 0+).
func set_credits(amount: int) -> void:
	credits = maxi(0, amount)
	emit_signal("credits_changed", credits)
	SaveManager.save_data()

## Admin: subtract credits, clamping balance at 0.
func remove_credits(amount: int) -> void:
	credits = maxi(0, credits - amount)
	emit_signal("credits_changed", credits)
	SaveManager.save_data()

# ─────────────────────────────────────────────────────────────
# Cards
# ─────────────────────────────────────────────────────────────

## Add one copy of a card to the collection, tagged with the pack it came from.
func add_card(card_name: String, card_type: String, from_pack: String) -> void:
	_append_card_copy(card_name, card_type, from_pack)
	emit_signal("collection_changed")
	SaveManager.save_data()

## Batch-add one copy of every card in [deck] without writing save (caller saves once).
func grant_cards_from_deck(deck: DeckData, source: String = "Starter Deck") -> void:
	if deck == null:
		return
	for card_name: Variant in deck.characters:
		_append_card_copy(str(card_name), "character", source)
	for card_name: Variant in deck.traps:
		_append_card_copy(str(card_name), "trap", source)
	for card_name: Variant in deck.techs:
		_append_card_copy(str(card_name), "tech", source)

func _append_card_copy(card_name: String, card_type: String, from_pack: String) -> void:
	if card_name.is_empty():
		return
	if not owned.has(card_name):
		owned[card_name] = {"type": card_type, "copies": []}
	owned[card_name]["copies"].append(from_pack)

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

# ─────────────────────────────────────────────────────────────
# Winding Keys (re-roll consumable)
# ─────────────────────────────────────────────────────────────
func add_winding_keys(count: int = 1) -> void:
	winding_keys += count
	emit_signal("collection_changed")
	SaveManager.save_data()

## Returns false if the player has no winding keys.
func spend_winding_key() -> bool:
	if winding_keys <= 0:
		return false
	winding_keys -= 1
	emit_signal("collection_changed")
	SaveManager.save_data()
	return true

# ─────────────────────────────────────────────────────────────
# Individual music discs (disc product catalog)
# ─────────────────────────────────────────────────────────────
func add_disc(disc_id: String, count: int = 1) -> void:
	owned_discs[disc_id] = owned_discs.get(disc_id, 0) + count
	emit_signal("collection_changed")
	SaveManager.save_data()

func get_disc_count(disc_id: String) -> int:
	return owned_discs.get(disc_id, 0)

# ─────────────────────────────────────────────────────────────
# Incense (drop-rate booster)
# ─────────────────────────────────────────────────────────────
func add_incenses(count: int = 1) -> void:
	incenses += count
	emit_signal("collection_changed")
	SaveManager.save_data()

## Returns false if the player has no incense.
func spend_incense() -> bool:
	if incenses <= 0:
		return false
	incenses -= 1
	emit_signal("collection_changed")
	SaveManager.save_data()
	return true

## Apply a random +10%–+35% multiplicative boost to a card's pool weight.
## Returns the boost fraction applied (e.g. 0.25 for +25%), or 0.0 if no incense.
func pray_for_card(card_name: String) -> float:
	if not spend_incense():
		return 0.0
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var boost: float = rng.randf_range(0.10, 0.35)
	var current: float = float(card_drop_boosts.get(card_name, 0.0))
	card_drop_boosts[card_name] = current + boost
	emit_signal("collection_changed")
	SaveManager.save_data()
	return boost

# ─────────────────────────────────────────────────────────────
# Union Scrolls (discover undiscovered unions)
# ─────────────────────────────────────────────────────────────
func add_union_scrolls(count: int = 1) -> void:
	if count <= 0:
		return
	union_scrolls += count
	emit_signal("collection_changed")
	SaveManager.save_data()

func remove_union_scrolls(count: int = 1) -> void:
	if count <= 0:
		return
	union_scrolls = maxi(0, union_scrolls - count)
	emit_signal("collection_changed")
	SaveManager.save_data()

func spend_union_scroll() -> bool:
	if union_scrolls <= 0:
		return false
	union_scrolls -= 1
	emit_signal("collection_changed")
	SaveManager.save_data()
	return true

func get_card_boost(card_name: String) -> float:
	return float(card_drop_boosts.get(card_name, 0.0))

## Reset boost after the card is found in a pack.
func reset_card_boost(card_name: String) -> void:
	if card_drop_boosts.has(card_name):
		card_drop_boosts.erase(card_name)
		emit_signal("collection_changed")
		SaveManager.save_data()

## Returns false if the player has none of this disc.
func spend_disc(disc_id: String) -> bool:
	if get_disc_count(disc_id) <= 0:
		return false
	owned_discs[disc_id] = (owned_discs[disc_id] as int) - 1
	if (owned_discs[disc_id] as int) <= 0:
		owned_discs.erase(disc_id)
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

## Remove all but one copy of a named card. Returns number of copies removed.
func scrap_duplicates(card_name: String) -> int:
	if not owned.has(card_name):
		return 0
	var copies: Array = owned[card_name]["copies"]
	var extras: int = copies.size() - 1
	if extras <= 0:
		return 0
	owned[card_name]["copies"] = [copies[0]]
	emit_signal("collection_changed")
	SaveManager.save_data()
	return extras

## Set owned copies of a card to exactly qty (0 removes it entirely).
func set_card_quantity(card_name: String, qty: int) -> void:
	qty = maxi(0, qty)
	if qty == 0:
		owned.erase(card_name)
		emit_signal("collection_changed")
		SaveManager.save_data()
		return
	if not owned.has(card_name):
		var card_type: String = ""
		if CardDatabase.get_character(card_name):   card_type = "character"
		elif CardDatabase.get_trap(card_name):       card_type = "trap"
		elif CardDatabase.get_tech(card_name):       card_type = "tech"
		owned[card_name] = {"type": card_type, "copies": []}
	var copies: Array = owned[card_name]["copies"]
	while copies.size() < qty:
		copies.append("Admin")
	while copies.size() > qty:
		copies.pop_back()
	emit_signal("collection_changed")
	SaveManager.save_data()

## Remove all copies of cards NOT in the protected list. Returns count of cards wiped.
func confiscate_except(protected: Array) -> int:
	var wiped: int = 0
	for cname: String in owned.keys():
		if not protected.has(cname):
			owned.erase(cname)
			wiped += 1
	if wiped > 0:
		emit_signal("collection_changed")
		SaveManager.save_data()
	return wiped

## Scrap duplicates for every owned card in one batch. Returns total copies removed.
func scrap_all_duplicates() -> int:
	var total: int = 0
	for cname: String in owned.keys():
		var copies: Array = owned[cname]["copies"]
		var extras: int = copies.size() - 1
		if extras > 0:
			owned[cname]["copies"] = [copies[0]]
			total += extras
	if total > 0:
		emit_signal("collection_changed")
		SaveManager.save_data()
	return total

# ─────────────────────────────────────────────────────────────
# Serialisation — called by SaveManager
# ─────────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"credits":      credits,
		"owned":        owned.duplicate(true),
		"music_discs":  music_discs,
		"winding_keys":     winding_keys,
		"owned_discs":      owned_discs.duplicate(),
		"incenses":         incenses,
		"union_scrolls":  union_scrolls,
		"card_drop_boosts": card_drop_boosts.duplicate(),
	}

func load_from_dict(d: Dictionary) -> void:
	credits      = d.get("credits",      STARTING_CREDITS)
	owned        = d.get("owned",        {})
	music_discs  = d.get("music_discs",  0)
	winding_keys = d.get("winding_keys", 0)
	var raw_discs: Variant = d.get("owned_discs", null)
	if raw_discs is Dictionary:
		owned_discs = raw_discs as Dictionary
	else:
		owned_discs = {}
		if music_discs > 0:
			owned_discs["generic"] = music_discs
	incenses = d.get("incenses", 0)
	union_scrolls = d.get("union_scrolls", 0)
	var raw_boosts: Variant = d.get("card_drop_boosts", null)
	card_drop_boosts = raw_boosts if raw_boosts is Dictionary else {}
