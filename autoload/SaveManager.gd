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
var chapter_arc_progress: Dictionary = {}   # gallery chapter vn_scene → active arc segment
const GALLERY_DATA_PATH: String = "res://campaign/gallery_data.json"
var _gallery_entries_cache: Array = []
var onboarding_complete: bool = false        # true after first-run setup (or legacy save migration)
var title_cheat_apartment_claimed: bool = false  # main-menu apartment-window cheat (once per save)
var title_cheat_moon_claimed: bool = false       # main-menu moon cheat (once per save)
var attack_tutorial_complete: bool = false
var casual_mode: bool = true
var casual_mode_tip_shown: bool = false
var borderless_display: bool = false
var quick_duel_tier_previews: Dictionary = {}   # tier -> vault entry_id
var quick_duel_tier_rewards: Dictionary = {}  # tier -> Array of reward dicts
var quick_duel_loss_streak: int = 0
var wishlist_cta_shown: bool = false
var quick_duel_protagonist_id: String = "nex"
var quick_duel_protagonist_portrait: String = ""
var quick_duel_tier_identities: Dictionary = {}

var _bootstrapped := false
var _save_enabled := false

func _ready() -> void:
	_load_demo_config()


func is_bootstrapped() -> bool:
	return _bootstrapped


func bootstrap() -> void:
	if _bootstrapped:
		return
	UnionDatabase.bootstrap()
	load_data()
	_bootstrapped = true


func bootstrap_step() -> bool:
	if _bootstrapped:
		return true
	if not UnionDatabase.is_bootstrapped():
		if UnionDatabase.bootstrap_step():
			StartupLoadDebug.log("SaveManager.bootstrap_step: Union ready — loading save data")
			load_data()
			_bootstrapped = true
			StartupLoadDebug.log("SaveManager.bootstrap_step: complete")
			return true
		return false
	StartupLoadDebug.log("SaveManager.bootstrap_step: loading save data (Union already ready)")
	load_data()
	_bootstrapped = true
	StartupLoadDebug.log("SaveManager.bootstrap_step: complete")
	return true


func bootstrap_async() -> void:
	if _bootstrapped:
		return
	while not bootstrap_step():
		await get_tree().process_frame

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

func is_active_deck_ready() -> bool:
	var deck := get_active_deck()
	return deck != null and deck.is_valid()

func get_active_deck_warning_message() -> String:
	var deck := get_active_deck()
	if deck == null:
		return "No deck saved. Please build a deck first."
	return deck.validation_message()

func show_deck_not_ready_overlay(parent: Node) -> void:
	if GameDialog.has_open_overlay(parent):
		return
	GameDialog.accept_overlay(
		parent,
		"Deck Not Ready",
		get_active_deck_warning_message(),
		"OK")

func get_setup_abort_return_scene() -> String:
	if GameState.quick_duel_active or GameState.quick_duel_overlay_active:
		GameState.open_quick_duel_overlay_on_menu = true
		return "res://scenes/main_menu.tscn"
	if GameState.game_mode == GameState.GameMode.CAMPAIGN:
		return "res://scenes/campaign_map.tscn"
	if GameState.game_mode == GameState.GameMode.EXPLORATION \
			or GameState.vn_launched_from_exploration:
		return ExplorationManager.EXPLORATION_PLAYER_SCENE
	if DailyDungeonManager.is_story_session():
		return DailyDungeonManager.DUNGEON_MAP_SCENE
	return "res://scenes/main_menu.tscn"

func sanitize_deck_for_collection(deck: DeckData) -> Dictionary:
	var report: Dictionary = _empty_sanitize_report()
	if deck == null:
		return report

	var deduped_chars: Array = []
	var deduped_traps: Array = []
	var deduped_techs: Array = []
	var new_chars: Array = _dedupe_card_names(deck.characters, deduped_chars)
	var new_traps: Array = _dedupe_card_names(deck.traps, deduped_traps)
	var new_techs: Array = _dedupe_card_names(deck.techs, deduped_techs)
	if new_chars.size() != deck.characters.size():
		report["changed"] = true
		deck.characters = new_chars
	if new_traps.size() != deck.traps.size():
		report["changed"] = true
		deck.traps = new_traps
	if new_techs.size() != deck.techs.size():
		report["changed"] = true
		deck.techs = new_techs
	report["deduped_characters"] = deduped_chars
	report["deduped_traps"] = deduped_traps
	report["deduped_techs"] = deduped_techs

	var removed_chars: Array = []
	var removed_traps: Array = []
	var removed_techs: Array = []
	deck.characters = _filter_owned_cards(deck.characters, "character", removed_chars)
	deck.traps = _filter_owned_cards(deck.traps, "trap", removed_traps)
	deck.techs = _filter_owned_cards(deck.techs, "tech", removed_techs)
	if not removed_chars.is_empty() or not removed_traps.is_empty() or not removed_techs.is_empty():
		report["changed"] = true
	report["removed_characters"] = removed_chars
	report["removed_traps"] = removed_traps
	report["removed_techs"] = removed_techs

	var placements_removed: int = deck.purge_stale_formation_placements()
	if placements_removed > 0:
		report["changed"] = true
		report["removed_placements"] = placements_removed
	return report

func _empty_sanitize_report() -> Dictionary:
	return {
		"removed_characters": [],
		"removed_traps": [],
		"removed_techs": [],
		"deduped_characters": [],
		"deduped_traps": [],
		"deduped_techs": [],
		"removed_placements": 0,
		"changed": false,
	}

func _dedupe_card_names(cards: Array, deduped_out: Array) -> Array:
	var seen: Dictionary = {}
	var result: Array = []
	for card_name: Variant in cards:
		var n: String = str(card_name).strip_edges()
		if n.is_empty():
			continue
		if seen.has(n):
			if n not in deduped_out:
				deduped_out.append(n)
			continue
		seen[n] = true
		result.append(n)
	return result

func _filter_owned_cards(cards: Array, slot: String, removed_out: Array) -> Array:
	var result: Array = []
	for card_name: Variant in cards:
		var n: String = str(card_name).strip_edges()
		if _card_allowed_in_collection(n, slot):
			result.append(n)
		elif not n.is_empty() and n not in removed_out:
			removed_out.append(n)
	return result

func _card_allowed_in_collection(card_name: String, slot: String) -> bool:
	var n: String = card_name.strip_edges()
	if n.is_empty():
		return false
	if Collection.get_card_count(n) <= 0:
		return false
	match slot:
		"character":
			var data: CharacterData = CardDatabase.get_character(n)
			if data == null:
				return false
			if demo_mode and not data.include_in_demo:
				return false
			return true
		"trap":
			var trap_data: TrapData = CardDatabase.get_trap(n)
			if trap_data == null:
				return false
			if demo_mode and not trap_data.include_in_demo:
				return false
			return true
		"tech":
			var tech_data: TechCardData = CardDatabase.get_tech(n)
			if tech_data == null:
				return false
			if demo_mode and not tech_data.include_in_demo:
				return false
			return true
	return false

func _merge_sanitize_reports(into: Dictionary, report: Dictionary) -> void:
	for key: String in [
		"removed_characters", "removed_traps", "removed_techs",
		"deduped_characters", "deduped_traps", "deduped_techs",
	]:
		var bucket: Array = into.get(key, []) as Array
		for name: Variant in report.get(key, []):
			var n: String = str(name)
			if n not in bucket:
				bucket.append(n)
		into[key] = bucket
	into["removed_placements"] = int(into.get("removed_placements", 0)) \
		+ int(report.get("removed_placements", 0))
	if bool(report.get("changed", false)):
		into["changed"] = true

func sanitize_report_has_changes(report: Dictionary) -> bool:
	for key: String in [
		"removed_characters", "removed_traps", "removed_techs",
		"deduped_characters", "deduped_traps", "deduped_techs",
	]:
		if not (report.get(key, []) as Array).is_empty():
			return true
	return int(report.get("removed_placements", 0)) > 0

func set_active_deck_index(index: int) -> void:
	active_deck_index = clampi(index, 0, decks.size() - 1)
	save_data()

func unlock_union(union_name: String) -> void:
	if union_name not in unlocked_unions:
		unlocked_unions.append(union_name)
		GlobalStatManager.on_union_discovered()
		AchievementManager.on_union_discovered()
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
	sanitize_deck_for_collection(deck)
	for i in range(decks.size()):
		if decks[i].deck_name == deck.deck_name:
			decks[i] = deck
			active_deck_index = i
			save_data()
			return
	decks.append(deck)
	active_deck_index = decks.size() - 1
	save_data()
	AchievementManager.on_deck_count_changed()

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
	sanitize_deck_for_collection(copy)
	copy.deck_name = decks[index].deck_name + " (Copy)"
	decks.append(copy)
	active_deck_index = decks.size() - 1
	save_data()
	AchievementManager.on_deck_count_changed()

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
	var stripped_report: Dictionary = _empty_sanitize_report()
	for item: Variant in (decks_raw as Array):
		if not item is Dictionary:
			continue
		var deck: DeckData = DeckData.new()
		deck.load_from_dict(item as Dictionary)
		var report: Dictionary = sanitize_deck_for_collection(deck)
		_merge_sanitize_reports(stripped_report, report)
		deck.deck_name = make_unique_deck_name(deck.deck_name)
		decks.append(deck)
		imported_count += 1
	if imported_count == 0:
		return {"ok": false, "error": "No valid decks found in file.", "imported": 0}
	active_deck_index = decks.size() - imported_count
	save_data()
	return {"ok": true, "error": "", "imported": imported_count, "stripped": stripped_report}

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
	if not _save_enabled:
		StartupLoadDebug.log("SaveManager.save_data: ignored (save not loaded yet)")
		return
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
		"chapter_arc_progress":    chapter_arc_progress,
		"onboarding_complete":     onboarding_complete,
		"title_cheat_apartment_claimed": title_cheat_apartment_claimed,
		"title_cheat_moon_claimed":      title_cheat_moon_claimed,
		"attack_tutorial_complete":      attack_tutorial_complete,
		"casual_mode":                   casual_mode,
		"casual_mode_tip_shown":         casual_mode_tip_shown,
		"borderless_display":            borderless_display,
		"quick_duel_tier_previews":      quick_duel_tier_previews.duplicate(true),
		"quick_duel_tier_rewards":       quick_duel_tier_rewards.duplicate(true),
		"quick_duel_loss_streak":        quick_duel_loss_streak,
		"wishlist_cta_shown":            wishlist_cta_shown,
		"quick_duel_protagonist_id":     quick_duel_protagonist_id,
		"quick_duel_protagonist_portrait": quick_duel_protagonist_portrait,
		"quick_duel_tier_identities":    quick_duel_tier_identities.duplicate(true),
	}
	var progress: Dictionary = GlobalStatManager.to_save_dict()
	data.merge(progress)
	data.merge(AchievementManager.to_save_dict())
	# Re-apply after merges so tutorial flag cannot be overwritten by stat payloads.
	data["attack_tutorial_complete"] = attack_tutorial_complete
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_data() -> void:
	_save_enabled = true
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

	var collection_data = parsed.get("collection", null)
	if collection_data is Dictionary:
		Collection.load_from_dict(collection_data)

	var decks_sanitized: bool = false
	for deck: DeckData in decks:
		var report: Dictionary = sanitize_deck_for_collection(deck)
		if bool(report.get("changed", false)):
			decks_sanitized = true

	var mailbox_data = parsed.get("mailbox", null)
	if mailbox_data is Dictionary:
		MailboxManager.load_from_dict(mailbox_data)

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

	var cap: Variant = parsed.get("chapter_arc_progress", {})
	if cap is Dictionary:
		chapter_arc_progress = cap as Dictionary

	onboarding_complete = bool(parsed.get("onboarding_complete", false))
	title_cheat_apartment_claimed = bool(parsed.get("title_cheat_apartment_claimed", false))
	title_cheat_moon_claimed = bool(parsed.get("title_cheat_moon_claimed", false))
	attack_tutorial_complete = bool(parsed.get("attack_tutorial_complete", false)) \
		or bool(parsed.get("quick_duel_tutorial_dismissed", false))
	casual_mode = bool(parsed.get("casual_mode", true))
	casual_mode_tip_shown = bool(parsed.get("casual_mode_tip_shown", false))
	borderless_display = bool(parsed.get("borderless_display", false))
	quick_duel_loss_streak = int(parsed.get("quick_duel_loss_streak", 0))
	wishlist_cta_shown = bool(parsed.get("wishlist_cta_shown", false))
	quick_duel_protagonist_id = ProtagonistVault.normalize_id(
		str(parsed.get("quick_duel_protagonist_id", "nex")))
	quick_duel_protagonist_portrait = str(
		parsed.get("quick_duel_protagonist_portrait", "")).strip_edges()

	var qdi: Variant = parsed.get("quick_duel_tier_identities", {})
	quick_duel_tier_identities = qdi as Dictionary if qdi is Dictionary else {}

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
	if decks_sanitized or reconcile_protagonist_selection():
		save_data()
	GlobalStatManager.load_from_save(parsed as Dictionary)
	AchievementManager.load_from_save(parsed as Dictionary)
	if RewardGranter.reconcile_claimed_union_formula_rewards():
		save_data()
	_migrate_chapter_arc_from_legacy()
	DisplayManager.apply_saved_setting()
	DailyDungeonManager.apply_daily_reset_after_load()

# ─────────────────────────────────────────────────────────────
# Campaign gallery VN beat checkpoints (pre-exploration progress)
# ─────────────────────────────────────────────────────────────
func set_vn_checkpoint(vn_scene: String, beat_index: int) -> void:
	var key: String = vn_scene.strip_edges()
	if key.is_empty() or beat_index <= 0:
		return
	campaign_vn_checkpoints[key] = beat_index
	save_data()

func set_vn_checkpoint_for_chapter(
		chapter_key: String,
		vn_scene: String,
		beat_index: int) -> void:
	set_vn_checkpoint(vn_scene, beat_index)
	var ck: String = chapter_key.strip_edges()
	if ck.is_empty():
		return
	update_chapter_arc_vn(ck, vn_scene, beat_index)

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

func set_attack_tutorial_complete(enabled: bool) -> void:
	if attack_tutorial_complete == enabled:
		return
	attack_tutorial_complete = enabled
	save_data()

func mark_attack_tutorial_complete() -> void:
	set_attack_tutorial_complete(true)


## Quick Duel "No — Skip" — same flag + path as finishing the tutorial battle.
func skip_attack_tutorial_prompt() -> void:
	mark_attack_tutorial_complete()


func is_attack_tutorial_complete() -> bool:
	return attack_tutorial_complete

func is_wishlist_cta_shown() -> bool:
	return wishlist_cta_shown

func mark_wishlist_cta_shown() -> void:
	if wishlist_cta_shown:
		return
	wishlist_cta_shown = true
	save_data()

func reset_wishlist_cta_shown() -> void:
	if not wishlist_cta_shown:
		return
	wishlist_cta_shown = false
	save_data()

func is_casual_mode() -> bool:
	return casual_mode

func set_casual_mode(enabled: bool) -> void:
	if casual_mode == enabled:
		return
	casual_mode = enabled
	if enabled:
		GlobalStatManager.on_casual_mode_enabled()
	save_data()

func is_casual_mode_tip_shown() -> bool:
	return casual_mode_tip_shown

func mark_casual_mode_tip_shown() -> void:
	if casual_mode_tip_shown:
		return
	casual_mode_tip_shown = true
	save_data()

func is_borderless_display() -> bool:
	return borderless_display

func set_borderless_display(enabled: bool) -> void:
	if borderless_display == enabled:
		return
	borderless_display = enabled
	DisplayManager.apply_borderless(enabled)
	save_data()

func get_quick_duel_preview(tier: String) -> String:
	return str(quick_duel_tier_previews.get(tier, "")).strip_edges()

func get_quick_duel_rewards(tier: String) -> Array:
	var raw: Variant = quick_duel_tier_rewards.get(tier, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []

func set_quick_duel_tier_offers(
		previews: Dictionary,
		rewards: Dictionary,
		identities: Dictionary = {}
) -> void:
	quick_duel_tier_previews = previews.duplicate(true)
	quick_duel_tier_rewards = rewards.duplicate(true)
	quick_duel_tier_identities = identities.duplicate(true)
	save_data()

func has_quick_duel_offers() -> bool:
	for tier: String in ["easy", "normal", "hard"]:
		if get_quick_duel_preview(tier).is_empty():
			return false
		if get_quick_duel_identity(tier).is_empty():
			return false
		var rw: Array = get_quick_duel_rewards(tier)
		if rw.is_empty():
			return false
	return true

func get_quick_duel_identity(tier: String) -> String:
	return str(quick_duel_tier_identities.get(tier, "")).strip_edges()

func get_protagonist_display_name() -> String:
	return ProtagonistVault.get_display_name(quick_duel_protagonist_id)

func get_protagonist_portrait_path() -> String:
	reconcile_protagonist_selection()
	return ProtagonistVault.get_portrait_or_default(
		quick_duel_protagonist_id, quick_duel_protagonist_portrait)

func set_protagonist(protagonist_id: String, portrait_path: String) -> void:
	var prev_id: String = quick_duel_protagonist_id
	var new_id: String = ProtagonistVault.normalize_id(protagonist_id)
	var resolved_portrait: String = portrait_path.strip_edges()
	var portrait_owner: String = ProtagonistVault.get_protagonist_for_portrait(resolved_portrait)
	if not portrait_owner.is_empty():
		new_id = portrait_owner
	if not ProtagonistVault.is_pose_portrait_unlocked(new_id, resolved_portrait):
		resolved_portrait = ProtagonistVault.get_first_unlocked_portrait(new_id)
	quick_duel_protagonist_id = new_id
	quick_duel_protagonist_portrait = resolved_portrait
	if quick_duel_protagonist_portrait.is_empty():
		quick_duel_protagonist_portrait = ProtagonistVault.get_default_portrait(
			quick_duel_protagonist_id)
	if prev_id != new_id and ProtagonistVault.is_valid_id(prev_id):
		GlobalStatManager.on_protagonist_switched()
	save_data()

func reconcile_protagonist_selection() -> bool:
	var before_id: String = quick_duel_protagonist_id
	var before_portrait: String = quick_duel_protagonist_portrait
	_ensure_protagonist_defaults()
	var owner: String = ProtagonistVault.get_protagonist_for_portrait(
		quick_duel_protagonist_portrait)
	if not owner.is_empty():
		quick_duel_protagonist_id = owner
		if not ProtagonistVault.is_pose_portrait_unlocked(
				owner, quick_duel_protagonist_portrait):
			quick_duel_protagonist_portrait = ProtagonistVault.get_first_unlocked_portrait(
				owner)
	elif not ProtagonistVault.portrait_belongs_to(
			quick_duel_protagonist_id, quick_duel_protagonist_portrait):
		quick_duel_protagonist_portrait = ProtagonistVault.get_first_unlocked_portrait(
			quick_duel_protagonist_id)
	return before_id != quick_duel_protagonist_id \
		or before_portrait != quick_duel_protagonist_portrait

func _ensure_protagonist_defaults() -> void:
	if not ProtagonistVault.is_valid_id(quick_duel_protagonist_id):
		quick_duel_protagonist_id = ProtagonistVault.DEFAULT_ID
	if quick_duel_protagonist_portrait.is_empty():
		quick_duel_protagonist_portrait = ProtagonistVault.get_default_portrait(
			quick_duel_protagonist_id)

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
			quick_duel_tier_identities.clear()
			return
	if not quick_duel_tier_previews.is_empty():
		for tier: String in ["easy", "normal", "hard"]:
			if get_quick_duel_identity(tier).is_empty():
				quick_duel_tier_previews.clear()
				quick_duel_tier_rewards.clear()
				quick_duel_tier_identities.clear()
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
	GlobalStatManager.on_gallery_chapter_completed(key)
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
# Chapter arc progress (multi-segment VN → exploration → VN queues)
# ─────────────────────────────────────────────────────────────

func _load_gallery_entries() -> Array:
	if not _gallery_entries_cache.is_empty():
		return _gallery_entries_cache
	if not FileAccess.file_exists(GALLERY_DATA_PATH):
		return []
	var f := FileAccess.open(GALLERY_DATA_PATH, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Array:
		_gallery_entries_cache = parsed as Array
	return _gallery_entries_cache


func get_gallery_card_for_chapter(chapter_key: String) -> Dictionary:
	var key: String = chapter_key.strip_edges()
	if key.is_empty():
		return {}
	for raw: Variant in _load_gallery_entries():
		if not raw is Dictionary:
			continue
		var card: Dictionary = raw as Dictionary
		if str(card.get("vn_scene", "")).strip_edges() == key:
			return card.duplicate(true)
	return {}


func resolve_chapter_key_for_vn(vn_path: String) -> String:
	var path: String = vn_path.strip_edges()
	if path.is_empty():
		return ""
	for raw: Variant in _load_gallery_entries():
		if not raw is Dictionary:
			continue
		var card: Dictionary = raw as Dictionary
		var chapter_vn: String = str(card.get("vn_scene", "")).strip_edges()
		if chapter_vn.is_empty():
			continue
		if chapter_vn == path:
			return chapter_vn
		var expl: Dictionary = ExplorationManager.find_exploration_call_in_vn(chapter_vn)
		var on_return: String = str(expl.get("exploration_on_return", "")).strip_edges()
		if on_return == path:
			return chapter_vn
	return ""


func has_chapter_arc_progress(chapter_key: String) -> bool:
	var key: String = chapter_key.strip_edges()
	return not key.is_empty() and chapter_arc_progress.has(key)


func get_chapter_arc(chapter_key: String) -> Dictionary:
	var key: String = chapter_key.strip_edges()
	if key.is_empty():
		return {}
	var arc: Variant = chapter_arc_progress.get(key, {})
	return arc.duplicate(true) if arc is Dictionary else {}


func get_chapter_arc_segment_kind(chapter_key: String) -> String:
	if not has_chapter_arc_progress(chapter_key):
		return ""
	return str(get_chapter_arc(chapter_key).get("segment", "")).strip_edges()


func _write_chapter_arc(chapter_key: String, arc: Dictionary) -> void:
	var key: String = chapter_key.strip_edges()
	if key.is_empty():
		return
	chapter_arc_progress[key] = arc.duplicate(true)
	save_data()


func update_chapter_arc_vn(chapter_key: String, vn_path: String, beat_index: int) -> void:
	var key: String = chapter_key.strip_edges()
	var vp: String = vn_path.strip_edges()
	if key.is_empty() or vp.is_empty():
		return
	var arc: Dictionary = get_chapter_arc(key)
	arc["segment"] = "vn"
	arc["vn_path"] = vp
	arc["vn_beat_index"] = beat_index
	_write_chapter_arc(key, arc)


func update_chapter_arc_exploration(
		chapter_key: String,
		graph_path: String,
		pending_return_vn: String,
		source_vn: String,
		source_beat_index: int) -> void:
	var key: String = chapter_key.strip_edges()
	var graph: String = graph_path.strip_edges()
	if key.is_empty() or graph.is_empty():
		return
	var arc: Dictionary = {
		"segment":           "exploration",
		"exploration_graph": graph,
		"pending_return_vn": pending_return_vn.strip_edges(),
		"source_vn":         source_vn.strip_edges(),
		"source_beat_index": source_beat_index,
	}
	_write_chapter_arc(key, arc)


func update_chapter_arc_dungeon(chapter_key: String, dungeon_id: String) -> void:
	var key: String = chapter_key.strip_edges()
	var did: String = dungeon_id.strip_edges()
	if key.is_empty() or did.is_empty():
		return
	var arc: Dictionary = {
		"segment":    "dungeon",
		"dungeon_id": did,
	}
	_write_chapter_arc(key, arc)


func clear_chapter_arc_progress(chapter_key: String) -> void:
	var key: String = chapter_key.strip_edges()
	if key.is_empty() or not chapter_arc_progress.has(key):
		return
	chapter_arc_progress.erase(key)
	save_data()


func clear_chapter_arc_vn_checkpoints(chapter_key: String) -> void:
	var key: String = chapter_key.strip_edges()
	if key.is_empty():
		return
	clear_vn_checkpoint(key)
	var expl: Dictionary = ExplorationManager.find_exploration_call_in_vn(key)
	var on_return: String = str(expl.get("exploration_on_return", "")).strip_edges()
	if not on_return.is_empty():
		clear_vn_checkpoint(on_return)
	var arc: Dictionary = get_chapter_arc(key)
	var arc_vn: String = str(arc.get("vn_path", "")).strip_edges()
	if not arc_vn.is_empty() and arc_vn != key and arc_vn != on_return:
		clear_vn_checkpoint(arc_vn)


## Wipe all in-progress data for a gallery chapter (Restart Chapter).
func reset_chapter_arc_progress(chapter_key: String, card: Dictionary = {}) -> void:
	var key: String = chapter_key.strip_edges()
	if key.is_empty():
		return
	clear_chapter_arc_vn_checkpoints(key)
	clear_chapter_arc_progress(key)
	ExplorationManager.clear_saved_session_for_chapter(key, card)
	var dungeon_info: Dictionary = DailyDungeonManager.find_dungeon_call_in_vn(key)
	var dungeon_id: String = str(dungeon_info.get("dungeon_id", "")).strip_edges()
	if not dungeon_id.is_empty():
		DailyDungeonManager.reset_story_dungeon_chapter(dungeon_id)


## Mark chapter complete and remove all arc / mid-progress saves.
func finalize_chapter_arc(chapter_key: String, card: Dictionary = {}) -> void:
	var key: String = chapter_key.strip_edges()
	if key.is_empty():
		return
	mark_gallery_chapter_completed(key)
	reset_chapter_arc_progress(key, card)


func _migrate_chapter_arc_from_legacy() -> void:
	var migrated: bool = false
	for raw: Variant in _load_gallery_entries():
		if not raw is Dictionary:
			continue
		var card: Dictionary = raw as Dictionary
		var chapter_key: String = str(card.get("vn_scene", "")).strip_edges()
		if chapter_key.is_empty() or is_gallery_chapter_completed(chapter_key):
			continue
		if has_chapter_arc_progress(chapter_key):
			continue

		var expl_info: Dictionary = ExplorationManager.find_exploration_call_in_vn(chapter_key)
		var graph_path: String = ExplorationManager.resolve_chapter_exploration_graph(card, chapter_key)
		var on_return: String = str(expl_info.get("exploration_on_return", "")).strip_edges()

		# Prefer active exploration save tied to this chapter.
		if not graph_path.is_empty() \
				and exploration_session.get("active", false) \
				and str(exploration_session.get("source_vn_scene", "")).strip_edges() == chapter_key:
			update_chapter_arc_exploration(
				chapter_key,
				graph_path,
				on_return,
				chapter_key,
				get_vn_checkpoint(chapter_key))
			migrated = true
			continue

		# Return VN checkpoint (e.g. PART2 mid-play).
		if not on_return.is_empty() and has_vn_checkpoint(on_return):
			var beat: int = get_vn_checkpoint(on_return)
			update_chapter_arc_vn(chapter_key, on_return, beat)
			migrated = true
			continue

		# Entry VN checkpoint (e.g. PART1 mid-play).
		if has_vn_checkpoint(chapter_key):
			var beat: int = get_vn_checkpoint(chapter_key)
			update_chapter_arc_vn(chapter_key, chapter_key, beat)
			migrated = true

	if migrated:
		save_data()

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
