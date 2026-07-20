extends Node
# Named starter deck templates for multi-protagonist unlocks.
# Edited via admin command: manage_starter_deck_vault
#
# Entry schema: { id, label, protagonist_hint, deck }

const SAVE_PATH := "res://data/starter_deck_vault.json"
const DeckData = preload("res://resources/DeckData.gd")

var _entries: Array = []


func _ready() -> void:
	reload()


func reload() -> void:
	_entries.clear()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_warning("StarterDeckVault: missing %s" % SAVE_PATH)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var raw: Variant = (parsed as Dictionary).get("entries", [])
		if raw is Array:
			_entries = (raw as Array).duplicate(true)


func save_entries(entries: Array) -> void:
	_entries = entries.duplicate(true)
	var payload: Dictionary = {"entries": _entries}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("StarterDeckVault: could not write %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()


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
	deck.ensure_identity()
	return deck


func populate_vault_option(opt: OptionButton, none_label: String = "(select starter)") -> void:
	if opt == null:
		return
	opt.clear()
	opt.add_item(none_label)
	opt.set_item_metadata(0, "")
	reload()
	var idx := 1
	for e: Variant in _entries:
		if not e is Dictionary:
			continue
		var d: Dictionary = e as Dictionary
		var eid: String = str(d.get("id", ""))
		var label: String = str(d.get("label", eid))
		opt.add_item("%s (%s)" % [label, eid])
		opt.set_item_metadata(idx, eid)
		idx += 1


func default_vault_id_for_protagonist(protagonist_id: String) -> String:
	var pid: String = ProtagonistVault.normalize_id(protagonist_id)
	match pid:
		"mayu":
			return "mayu_arcane"
		"kelly":
			return "kelly_nature"
		"nex":
			return "nex_starter"
		_:
			return ""
