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
var deckbuilding_unlocked: bool = false      # admin unlock — bypasses prologue-clear gate
var deckbuilding_admin_locked: bool = false  # hard admin lock — overrides even natural completion
var exploration_flags: Dictionary = {}       # flags written by ExplorationManager.end_session()
var exploration_session: Dictionary = {}    # mid-session snapshot; cleared on end_session()
var exploration_auto_save: bool = true      # when false, only Save and Exit writes exploration_session
var campaign_vn_checkpoints: Dictionary = {}  # vn_scene path → filtered beat index to resume
var onboarding_complete: bool = false        # true after first-run setup (or legacy save migration)
var title_cheat_apartment_claimed: bool = false  # main-menu apartment-window cheat (once per save)
var title_cheat_moon_claimed: bool = false       # main-menu moon cheat (once per save)
var attack_tutorial_complete: bool = false
var casual_mode: bool = false
var quick_duel_tier_previews: Dictionary = {}   # tier -> vault entry_id
var quick_duel_tier_rewards: Dictionary = {}  # tier -> Array of reward dicts
var quick_duel_loss_streak: int = 0
var wishlist_cta_shown: bool = false

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

func reset_title_cheats() -> void:
	title_cheat_apartment_claimed = false
	title_cheat_moon_claimed = false
	save_data()

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

# ── Deck import / export ──────────────────────────────────────
const DECK_EXPORT_FORMAT: String = "blightsilver_deck_export"
const DECK_EXPORT_VERSION: int = 1

func export_decks_payload() -> Dictionary:
	return {
		"format": DECK_EXPORT_FORMAT,
		"version": DECK_EXPORT_VERSION,
		"exported_at": Time.get_datetime_string_from_system(),
		"active_deck_index": active_deck_index,
		"decks": decks.map(func(d: DeckData) -> Dictionary: return d.to_dict()),
	}

func import_decks_from_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not read file.", "imported": 0}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		return {"ok": false, "error": "Invalid JSON.", "imported": 0}
	if parsed is Array:
		return import_decks_from_payload({"decks": parsed})
	if parsed is Dictionary:
		return import_decks_from_payload(parsed as Dictionary)
	return {"ok": false, "error": "Unsupported file format.", "imported": 0}

func import_decks_from_payload(payload: Dictionary) -> Dictionary:
	var decks_raw: Variant = payload.get("decks", null)
	if not decks_raw is Array:
		return {"ok": false, "error": "Missing or invalid 'decks' array.", "imported": 0}
	var fmt: String = str(payload.get("format", "")).strip_edges()
	if not fmt.is_empty() and fmt != DECK_EXPORT_FORMAT:
		return {"ok": false, "error": "Unrecognized deck export format.", "imported": 0}
	var imported_count: int = 0
	for item: Variant in (decks_raw as Array):
		if not item is Dictionary:
			continue
		var deck: DeckData = DeckData.new()
		deck.load_from_dict(item as Dictionary)
		deck.deck_name = make_unique_deck_name(deck.deck_name)
		decks.append(deck)
		imported_count += 1
	if imported_count == 0:
		return {"ok": false, "error": "No valid decks found in file.", "imported": 0}
	active_deck_index = decks.size() - imported_count
	save_data()
	return {"ok": true, "error": "", "imported": imported_count}

func make_unique_deck_name(base: String) -> String:
	var name: String = base.strip_edges()
	if name.is_empty():
		name = "Imported Deck"
	if not deck_name_exists(name):
		return name
	var suffix: int = 2
	while deck_name_exists("%s (%d)" % [name, suffix]):
		suffix += 1
	return "%s (%d)" % [name, suffix]

func deck_name_exists(name: String) -> bool:
	for deck: DeckData in decks:
		if deck.deck_name == name:
			return true
	return false

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
		"deckbuilding_unlocked": deckbuilding_unlocked,
		"deckbuilding_admin_locked": deckbuilding_admin_locked,
		"exploration_flags":       exploration_flags,
		"exploration_session":     exploration_session,
		"exploration_auto_save":   exploration_auto_save,
		"campaign_vn_checkpoints": campaign_vn_checkpoints,
		"onboarding_complete":     onboarding_complete,
		"title_cheat_apartment_claimed": title_cheat_apartment_claimed,
		"title_cheat_moon_claimed":      title_cheat_moon_claimed,
		"attack_tutorial_complete":      attack_tutorial_complete,
		"casual_mode":                   casual_mode,
		"quick_duel_tier_previews":      quick_duel_tier_previews.duplicate(true),
		"quick_duel_tier_rewards":       quick_duel_tier_rewards.duplicate(true),
		"quick_duel_loss_streak":        quick_duel_loss_streak,
		"wishlist_cta_shown":            wishlist_cta_shown,
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

	deckbuilding_unlocked      = bool(parsed.get("deckbuilding_unlocked", false))
	deckbuilding_admin_locked  = bool(parsed.get("deckbuilding_admin_locked", false))

	var ef: Variant = parsed.get("exploration_flags", {})
	if ef is Dictionary:
		exploration_flags = ef as Dictionary

	var es: Variant = parsed.get("exploration_session", {})
	if es is Dictionary:
		exploration_session = es as Dictionary

	exploration_auto_save = bool(parsed.get("exploration_auto_save", true))

	var vc: Variant = parsed.get("campaign_vn_checkpoints", {})
	if vc is Dictionary:
		campaign_vn_checkpoints = vc as Dictionary

	onboarding_complete = bool(parsed.get("onboarding_complete", false))
	title_cheat_apartment_claimed = bool(parsed.get("title_cheat_apartment_claimed", false))
	title_cheat_moon_claimed = bool(parsed.get("title_cheat_moon_claimed", false))
	attack_tutorial_complete = bool(parsed.get("attack_tutorial_complete", false))
	casual_mode = bool(parsed.get("casual_mode", false))
	quick_duel_loss_streak = int(parsed.get("quick_duel_loss_streak", 0))
	wishlist_cta_shown = bool(parsed.get("wishlist_cta_shown", false))

	var qdp: Variant = parsed.get("quick_duel_tier_previews", {})
	quick_duel_tier_previews = qdp as Dictionary if qdp is Dictionary else {}

	var qdr: Variant = parsed.get("quick_duel_tier_rewards", {})
	quick_duel_tier_rewards = {}
	if qdr is Dictionary:
		for tier_key: Variant in (qdr as Dictionary).keys():
			var tier: String = str(tier_key)
			var val: Variant = (qdr as Dictionary)[tier_key]
			if val is Array:
				quick_duel_tier_rewards[tier] = (val as Array).duplicate(true)
			elif val is Dictionary:
				quick_duel_tier_rewards[tier] = [((val as Dictionary).duplicate(true))]

	_migrate_quick_duel_offers()

# ─────────────────────────────────────────────────────────────
# Campaign gallery VN beat checkpoints (pre-exploration progress)
# ─────────────────────────────────────────────────────────────
func set_vn_checkpoint(vn_scene: String, beat_index: int) -> void:
	var key: String = vn_scene.strip_edges()
	if key.is_empty() or beat_index <= 0:
		return
	campaign_vn_checkpoints[key] = beat_index
	save_data()

func get_vn_checkpoint(vn_scene: String) -> int:
	var key: String = vn_scene.strip_edges()
	if key.is_empty():
		return -1
	return int(campaign_vn_checkpoints.get(key, -1))

func has_vn_checkpoint(vn_scene: String) -> bool:
	return get_vn_checkpoint(vn_scene) > 0

func clear_vn_checkpoint(vn_scene: String) -> void:
	var key: String = vn_scene.strip_edges()
	if key.is_empty() or not campaign_vn_checkpoints.has(key):
		return
	campaign_vn_checkpoints.erase(key)
	save_data()

# ─────────────────────────────────────────────────────────────
# Campaign gallery chapter progress
# ─────────────────────────────────────────────────────────────
## Returns true if deckbuilding is accessible.
## Checks admin override first, then gallery entries with unlock_deckbuilding=true.
func is_deckbuilding_unlocked() -> bool:
	if deckbuilding_admin_locked:
		return false
	return true

func mark_attack_tutorial_complete() -> void:
	if attack_tutorial_complete:
		return
	attack_tutorial_complete = true
	save_data()

func is_attack_tutorial_complete() -> bool:
	return attack_tutorial_complete

func is_wishlist_cta_shown() -> bool:
	return wishlist_cta_shown

func mark_wishlist_cta_shown() -> void:
	if wishlist_cta_shown:
		return
	wishlist_cta_shown = true
	save_data()

func is_casual_mode() -> bool:
	return casual_mode

func set_casual_mode(enabled: bool) -> void:
	if casual_mode == enabled:
		return
	casual_mode = enabled
	save_data()

func get_quick_duel_preview(tier: String) -> String:
	return str(quick_duel_tier_previews.get(tier, "")).strip_edges()

func get_quick_duel_rewards(tier: String) -> Array:
	var raw: Variant = quick_duel_tier_rewards.get(tier, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []

func set_quick_duel_tier_offers(previews: Dictionary, rewards: Dictionary) -> void:
	quick_duel_tier_previews = previews.duplicate(true)
	quick_duel_tier_rewards = rewards.duplicate(true)
	save_data()

func has_quick_duel_offers() -> bool:
	for tier: String in ["easy", "normal", "hard"]:
		if get_quick_duel_preview(tier).is_empty():
			return false
		var rw: Array = get_quick_duel_rewards(tier)
		if rw.is_empty():
			return false
	return true

func get_quick_duel_loss_streak() -> int:
	return quick_duel_loss_streak

func increment_quick_duel_loss_streak() -> void:
	quick_duel_loss_streak += 1
	save_data()

func reset_quick_duel_loss_streak() -> void:
	if quick_duel_loss_streak == 0:
		return
	quick_duel_loss_streak = 0
	save_data()

func _migrate_quick_duel_offers() -> void:
	if quick_duel_tier_previews.is_empty() and quick_duel_tier_rewards.is_empty():
		return
	if not quick_duel_tier_previews.is_empty() and quick_duel_tier_rewards.is_empty():
		quick_duel_tier_previews.clear()
		return
	for tier: String in ["easy", "normal", "hard"]:
		var rw: Variant = quick_duel_tier_rewards.get(tier, null)
		if rw is Array and (rw as Array).is_empty():
			quick_duel_tier_previews.clear()
			quick_duel_tier_rewards.clear()
			return

func _gallery_unlocks_deckbuilding() -> bool:
	const GALLERY_PATH := "res://campaign/gallery_data.json"
	var f := FileAccess.open(GALLERY_PATH, FileAccess.READ)
	if f == null:
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Array:
		return false
	for entry: Variant in (data as Array):
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		if not bool(d.get("unlock_deckbuilding", false)):
			continue
		var vn: String = str(d.get("vn_scene", "")).strip_edges()
		if vn != "" and is_gallery_chapter_completed(vn):
			return true
	return false

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

## Wipe campaign gallery unlock state (gallery flags + campaign map nodes).
func clear_gallery_progress() -> Dictionary:
	var gallery_count: int = gallery_chapters_completed.size()
	gallery_chapters_completed.clear()
	var campaign_count: int = CampaignManager.completed.size()
	CampaignManager.completed.clear()
	CampaignManager.active_node_id = ""
	CampaignManager.pending_result = {}
	CampaignManager.emit_signal("progress_changed")
	save_data()
	return {"gallery_chapters": gallery_count, "campaign_nodes": campaign_count}

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
