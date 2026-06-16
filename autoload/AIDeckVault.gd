extends Node
# Named AI deck templates for battles (exploration, campaign, etc.).
# Edited via admin command: ai_deck_vault
#
# Entry schema: { id, label, tags, featured_union, deck, ... }
# featured_union — optional union name; AI (P1) strongly prefers it when summoning.

const SAVE_PATH := "res://data/ai_deck_vault.json"
const DeckData = preload("res://resources/DeckData.gd")

var _entries: Array = []


func _ready() -> void:
	reload()


func reload() -> void:
	_entries.clear()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var raw: Variant = (parsed as Dictionary).get("entries", [])
		if raw is Array:
			_entries = (raw as Array).duplicate(true)


func get_entries() -> Array:
	return _entries.duplicate(true)


func get_entry(entry_id: String) -> Dictionary:
	for e: Variant in _entries:
		if e is Dictionary and str((e as Dictionary).get("id", "")) == entry_id:
			return (e as Dictionary).duplicate(true)
	return {}


func get_deck(entry_id: String) -> DeckData:
	var entry := get_entry(entry_id)
	if entry.is_empty():
		return null
	var deck_raw: Variant = entry.get("deck", {})
	if not deck_raw is Dictionary:
		return null
	var deck := DeckData.new()
	deck.load_from_dict(deck_raw as Dictionary)
	return deck


func get_tags(entry_id: String) -> Array:
	var entry := get_entry(entry_id)
	if entry.is_empty():
		return []
	var raw: Variant = entry.get("tags", [])
	return (raw as Array).duplicate() if raw is Array else []


func get_featured_union(entry_id: String) -> String:
	var entry := get_entry(entry_id)
	if entry.is_empty():
		return ""
	return str(entry.get("featured_union", "")).strip_edges()


## Load vault entry deck + featured union into GameState battle AI slots.
func apply_entry_to_battle(entry_id: String) -> bool:
	var deck := get_deck(entry_id)
	if deck == null:
		return false
	GameState.battle_ai_deck = deck
	GameState.battle_ai_featured_union = get_featured_union(entry_id)
	return true


func get_entries_by_tag(tag: String) -> Array:
	var needle := tag.strip_edges().to_lower()
	if needle.is_empty():
		return []
	var out: Array = []
	for e: Variant in _entries:
		if not e is Dictionary:
			continue
		var ed: Dictionary = e as Dictionary
		var raw: Variant = ed.get("tags", [])
		if not raw is Array:
			continue
		for t: Variant in (raw as Array):
			if str(t).strip_edges().to_lower() == needle:
				out.append(ed.duplicate(true))
				break
	return out


func save_entries(entries: Array) -> bool:
	_entries = entries.duplicate(true)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"entries": _entries}, "\t"))
	f.close()
	return true
