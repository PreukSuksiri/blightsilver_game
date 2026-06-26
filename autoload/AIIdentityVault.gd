extends Node
## Named AI opponent identities for Quick Duel — display name + battle illustration.
## Edited via admin command: ai_identity_vault

const SAVE_PATH := "res://data/ai_identity_vault.json"
const DIFFICULTIES: Array[String] = ["easy", "normal", "hard"]

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
	var needle := entry_id.strip_edges()
	if needle.is_empty():
		return {}
	for e: Variant in _entries:
		if e is Dictionary and str((e as Dictionary).get("id", "")).strip_edges() == needle:
			return (e as Dictionary).duplicate(true)
	return {}


func pick_random_for_tier(tier: String, protagonist_id: String) -> Dictionary:
	var needle_tier := tier.strip_edges().to_lower()
	var hero_id := ProtagonistVault.normalize_id(protagonist_id)
	var candidates: Array = []
	for e: Variant in _entries:
		if not e is Dictionary:
			continue
		var entry: Dictionary = e as Dictionary
		if str(entry.get("difficulty", "")).strip_edges().to_lower() != needle_tier:
			continue
		if _is_excluded_for_protagonist(entry, hero_id):
			continue
		candidates.append(entry.duplicate(true))
	if candidates.is_empty():
		return {}
	return (candidates[randi() % candidates.size()] as Dictionary).duplicate(true)


func _is_excluded_for_protagonist(entry: Dictionary, protagonist_id: String) -> bool:
	var exclude_raw: Variant = entry.get("exclude_protagonists", [])
	if not exclude_raw is Array:
		return false
	for ex: Variant in (exclude_raw as Array):
		if ProtagonistVault.normalize_id(str(ex)) == protagonist_id:
			return true
	return false


func save_entries(entries: Array) -> bool:
	_entries = entries.duplicate(true)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"entries": _entries}, "\t"))
	f.close()
	return true
