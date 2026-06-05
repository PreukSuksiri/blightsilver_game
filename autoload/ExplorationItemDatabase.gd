extends Node
## ExplorationItemDatabase — global catalog of exploration items.
##
## Stored in data/exploration_items.json.
## Item Dict fields:
##   id          String  — unique key (e.g. "rusty_key")
##   name        String  — display name
##   description String  — shown in preview overlay
##   icon        String  — res:// path to small icon (radial menu)
##   big_image   String  — res:// path to large preview image
##   effects       Array   — ordered effect Dicts (see below)
##   use_condition String  — optional boolean expression (ExplorationConditions)
##   key_item      bool    — pulses inventory HUD when item is eligible to use
##
## Effect Dict: { "type", "key", "value" }
##   play_vn      — play VN beat JSON at value path
##   set_var      — set_var(key, value)
##   show_message — show toast with value text
##   play_sfx     — play audio at value path
##   remove_self  — remove THIS item from inventory
##   remove_item  — remove item whose id == key
##   navigate_to  — navigate_to(value)
##
## Booster packs are granted via exploration events (give_booster_pack), not item effects.

const DATA_PATH: String = "res://data/exploration_items.json"

var _items: Array = []

func _ready() -> void:
	_load()

# ── Persistence ─────────────────────────────────────────────

func _load() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		_items = []
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		_items = []
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	_items = parsed if parsed is Array else []

func _save() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.WRITE)
	if file == null:
		push_error("ExplorationItemDatabase: cannot write to '%s'" % DATA_PATH)
		return
	file.store_string(JSON.stringify(_items, "\t"))
	file.close()

# ── Public API ───────────────────────────────────────────────

func all_items() -> Array:
	return _items.duplicate(true)

func get_item(id: String) -> Dictionary:
	for entry: Variant in _items:
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == id:
			return (entry as Dictionary).duplicate(true)
	return {}

func upsert_item(data: Dictionary) -> void:
	var id: String = str(data.get("id", ""))
	if id.is_empty():
		push_error("ExplorationItemDatabase.upsert_item: item has no id")
		return
	for i: int in range(_items.size()):
		if _items[i] is Dictionary and str((_items[i] as Dictionary).get("id", "")) == id:
			_items[i] = data.duplicate(true)
			_save()
			return
	_items.append(data.duplicate(true))
	_save()

func delete_item(id: String) -> void:
	for i: int in range(_items.size() - 1, -1, -1):
		if _items[i] is Dictionary and str((_items[i] as Dictionary).get("id", "")) == id:
			_items.remove_at(i)
			_save()
			return

func generate_id() -> String:
	var existing: Dictionary = {}
	for entry: Variant in _items:
		if entry is Dictionary:
			existing[str((entry as Dictionary).get("id", ""))] = true
	var i: int = 1
	while existing.has("item_%d" % i):
		i += 1
	return "item_%d" % i

func reload() -> void:
	_load()
