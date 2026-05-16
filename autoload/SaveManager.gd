extends Node
# Persists player decks and settings to user://save_data.json

const DeckData = preload("res://resources/DeckData.gd")

const SAVE_PATH: String = "user://save_data.json"

signal nsfw_changed(enabled: bool)

var decks: Array = []          # Array of DeckData
var active_deck_index: int = 0
var nsfw_enabled: bool = false
var unlocked_unions: Array = []  # union card names the player has ever summoned

func _ready() -> void:
	load_data()
	# Ensure there is always at least one deck
	if decks.is_empty():
		var starter := DeckData.new()
		starter.deck_name = "Starter Deck"
		decks.append(starter)

# ── Active deck ───────────────────────────────────────────────
func get_active_deck() -> DeckData:
	if decks.is_empty():
		return null
	return decks[clampi(active_deck_index, 0, decks.size() - 1)]

func set_active_deck_index(index: int) -> void:
	active_deck_index = clampi(index, 0, decks.size() - 1)
	save_data()

func unlock_union(union_name: String) -> void:
	if union_name not in unlocked_unions:
		unlocked_unions.append(union_name)
		save_data()

func is_union_unlocked(union_name: String) -> bool:
	return union_name in unlocked_unions

# ── CRUD ─────────────────────────────────────────────────────
func save_deck(deck: DeckData) -> void:
	# Replace existing deck by name, or append new
	for i in range(decks.size()):
		if decks[i].deck_name == deck.deck_name:
			decks[i] = deck
			active_deck_index = i
			save_data()
			return
	decks.append(deck)
	active_deck_index = decks.size() - 1
	save_data()

func delete_deck(index: int) -> void:
	if index < 0 or index >= decks.size():
		return
	decks.remove_at(index)
	if decks.is_empty():
		var blank := DeckData.new()
		blank.deck_name = "My Deck"
		decks.append(blank)
	active_deck_index = clampi(active_deck_index, 0, decks.size() - 1)
	save_data()

func duplicate_deck(index: int) -> void:
	if index < 0 or index >= decks.size():
		return
	var copy: DeckData = decks[index].duplicate_deck()
	copy.deck_name = decks[index].deck_name + " (Copy)"
	decks.append(copy)
	active_deck_index = decks.size() - 1
	save_data()

# ── Persistence ───────────────────────────────────────────────
func save_data() -> void:
	var data: Dictionary = {
		"active_deck_index": active_deck_index,
		"decks": decks.map(func(d: DeckData) -> Dictionary: return d.to_dict()),
		"mailbox": MailboxManager.to_dict(),
		"collection": Collection.to_dict(),
		"campaign": CampaignManager.to_dict(),
		"nsfw_enabled": nsfw_enabled,
		"unlocked_unions": unlocked_unions,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		return

	active_deck_index = parsed.get("active_deck_index", 0)
	decks.clear()
	for d in parsed.get("decks", []):
		if d is Dictionary:
			var deck: DeckData = DeckData.new()
			deck.load_from_dict(d)
			decks.append(deck)

	var mailbox_data = parsed.get("mailbox", null)
	if mailbox_data is Dictionary:
		MailboxManager.load_from_dict(mailbox_data)

	var collection_data = parsed.get("collection", null)
	if collection_data is Dictionary:
		Collection.load_from_dict(collection_data)

	var campaign_data = parsed.get("campaign", null)
	if campaign_data is Dictionary:
		CampaignManager.load_from_dict(campaign_data)

	nsfw_enabled = bool(parsed.get("nsfw_enabled", false))

	var ul: Variant = parsed.get("unlocked_unions", [])
	if ul is Array:
		unlocked_unions = ul
