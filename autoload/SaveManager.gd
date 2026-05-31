extends Node
# Persists player decks and settings to user://save_data.json

const DeckData = preload("res://resources/DeckData.gd")

const SAVE_PATH: String = "user://save_data.json"

signal nsfw_changed(enabled: bool)
signal demo_mode_changed(enabled: bool)

signal union_mechanism_changed(unlocked: bool)

const DEMO_CONFIG_PATH: String = "res://data/demo_config.json"

var decks: Array = []          # Array of DeckData
var active_deck_index: int = 0
var nsfw_enabled: bool = false
var unlocked_unions: Array = []  # union card names the player has ever summoned
var union_mechanism_unlocked: bool = false  # true = union system visible to player
var demo_mode: bool = false
var ai_exclude_placeholder: bool = false  # exclude placeholder_art cards from AI random deck pool
var bugged_cards: Dictionary = {}  # card_name → bug message string
var gallery_chapters_completed: Dictionary = {}  # vn_scene path → true

func _ready() -> void:
	_load_demo_config()
	load_data()

func _load_demo_config() -> void:
	if not FileAccess.file_exists(DEMO_CONFIG_PATH):
		return
	var file := FileAccess.open(DEMO_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		demo_mode = bool(parsed.get("demo_mode", false))

func set_demo_mode(enabled: bool) -> void:
	demo_mode = enabled
	emit_signal("demo_mode_changed", enabled)
	var file := FileAccess.open(DEMO_CONFIG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"demo_mode": enabled}, "\t"))
		file.close()
	# Ensure there is always at least one deck
	if decks.is_empty():
		var starter := DeckData.new()
		starter.deck_name = "Starter Deck"
		decks.append(starter)

# ── Active deck ───────────────────────────────────────────────
func get_active_deck() -> DeckData:
	if decks.is_empty():
		return null
	return decks[clampi(active_deck_index, 0, decks.size() - 1)] as DeckData

func set_active_deck_index(index: int) -> void:
	active_deck_index = clampi(index, 0, decks.size() - 1)
	save_data()

func unlock_union(union_name: String) -> void:
	if union_name not in unlocked_unions:
		unlocked_unions.append(union_name)
		save_data()

func is_union_unlocked(union_name: String) -> bool:
	return union_name in unlocked_unions

func set_union_mechanism_unlocked(val: bool) -> void:
	if union_mechanism_unlocked == val:
		return
	union_mechanism_unlocked = val
	save_data()
	emit_signal("union_mechanism_changed", val)

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
		"daily_dungeon": DailyDungeonManager.to_dict(),
		"nsfw_enabled": nsfw_enabled,
		"unlocked_unions": unlocked_unions,
		"union_mechanism_unlocked": union_mechanism_unlocked,
		"bugged_cards": bugged_cards,
		"gallery_chapters_completed": gallery_chapters_completed,
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

	var dungeon_data = parsed.get("daily_dungeon", null)
	if dungeon_data is Dictionary:
		DailyDungeonManager.load_from_dict(dungeon_data)

	nsfw_enabled = bool(parsed.get("nsfw_enabled", false))

	var ul: Variant = parsed.get("unlocked_unions", [])
	if ul is Array:
		unlocked_unions = ul
	union_mechanism_unlocked = bool(parsed.get("union_mechanism_unlocked", false))

	var bc: Variant = parsed.get("bugged_cards", {})
	if bc is Dictionary:
		bugged_cards = bc
	elif bc is Array:
		# Migrate old Array format (no messages) to Dictionary
		for item: Variant in bc:
			if item is String:
				bugged_cards[item] = ""

	var gcc: Variant = parsed.get("gallery_chapters_completed", {})
	if gcc is Dictionary:
		gallery_chapters_completed = gcc as Dictionary
	elif gcc is Array:
		for vn_key: Variant in gcc:
			if vn_key is String and (vn_key as String) != "":
				gallery_chapters_completed[vn_key] = true

# ─────────────────────────────────────────────────────────────
# Campaign gallery chapter progress
# ─────────────────────────────────────────────────────────────
func mark_gallery_chapter_completed(vn_scene: String) -> void:
	var key: String = vn_scene.strip_edges()
	if key.is_empty():
		return
	if gallery_chapters_completed.get(key, false):
		return
	gallery_chapters_completed[key] = true
	save_data()

func is_gallery_chapter_completed(vn_scene: String) -> bool:
	var key: String = vn_scene.strip_edges()
	if key.is_empty():
		return false
	if gallery_chapters_completed.get(key, false):
		return true
	return CampaignManager.is_vn_scene_completed(key)

# ─────────────────────────────────────────────────────────────
# Bug tagging
# ─────────────────────────────────────────────────────────────
func tag_bug(card_name: String, message: String = "") -> void:
	bugged_cards[card_name] = message
	save_data()

func resolve_bug(card_name: String) -> void:
	if bugged_cards.has(card_name):
		bugged_cards.erase(card_name)
		save_data()

func is_bugged(card_name: String) -> bool:
	return bugged_cards.has(card_name)

func get_bug_message(card_name: String) -> String:
	return bugged_cards.get(card_name, "") as String
