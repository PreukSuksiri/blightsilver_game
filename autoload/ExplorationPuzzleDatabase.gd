extends Node
## ExplorationPuzzleDatabase — registry of exploration puzzle metadata + scene mapping.
##
## Metadata lives in data/exploration_puzzles.json (managed via ExplorationPuzzleManager).
## Scene paths are registered in SCENE_REGISTRY when a puzzle is manually implemented.

const DATA_PATH: String = "res://data/exploration_puzzles.json"

## puzzle_id → res:// scene path. Add an entry when a puzzle scene is coded.
const SCENE_REGISTRY: Dictionary = {
	"puzzle_example":      "res://scenes/puzzles/puzzle_example.tscn",
	"puzzle_number_lock":  "res://scenes/puzzles/puzzle_number_lock.tscn",
	"puzzle_symbol_lock":  "res://scenes/puzzles/puzzle_symbol_lock.tscn",
	"puzzle_safe_dial":    "res://scenes/puzzles/puzzle_safe_dial.tscn",
	"puzzle_memory_flip":  "res://scenes/puzzles/puzzle_memory_flip.tscn",
	"puzzle_lights_out":   "res://scenes/puzzles/puzzle_lights_out.tscn",
	"puzzle_wire_connect": "res://scenes/puzzles/puzzle_wire_connect.tscn",
	"puzzle_simon_says":   "res://scenes/puzzles/puzzle_simon_says.tscn",
}

var _puzzles: Array = []

func _ready() -> void:
	_load()

func _load() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		_puzzles = []
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		_puzzles = []
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	_puzzles = parsed if parsed is Array else []

func _save() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.WRITE)
	if file == null:
		push_error("ExplorationPuzzleDatabase: cannot write to '%s'" % DATA_PATH)
		return
	file.store_string(JSON.stringify(_puzzles, "\t"))
	file.close()

func all_puzzles() -> Array:
	return _puzzles.duplicate(true)

func get_puzzle(id: String) -> Dictionary:
	for entry: Variant in _puzzles:
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == id:
			return (entry as Dictionary).duplicate(true)
	return {}

func get_scene_path(puzzle_id: String) -> String:
	return str(SCENE_REGISTRY.get(puzzle_id, ""))

func is_implemented(puzzle_id: String) -> bool:
	var path: String = get_scene_path(puzzle_id)
	return not path.is_empty() and ResourceLoader.exists(path)

func get_status_label(puzzle_id: String) -> String:
	return "Implemented" if is_implemented(puzzle_id) else "Not implemented"

func upsert_puzzle(data: Dictionary) -> void:
	var id: String = str(data.get("id", ""))
	if id.is_empty():
		push_error("ExplorationPuzzleDatabase.upsert_puzzle: missing id")
		return
	for i: int in range(_puzzles.size()):
		if _puzzles[i] is Dictionary and str((_puzzles[i] as Dictionary).get("id", "")) == id:
			_puzzles[i] = data.duplicate(true)
			_save()
			return
	_puzzles.append(data.duplicate(true))
	_save()

func delete_puzzle(id: String) -> void:
	for i: int in range(_puzzles.size() - 1, -1, -1):
		if _puzzles[i] is Dictionary and str((_puzzles[i] as Dictionary).get("id", "")) == id:
			_puzzles.remove_at(i)
			_save()
			return

func generate_id() -> String:
	var existing: Dictionary = {}
	for entry: Variant in _puzzles:
		if entry is Dictionary:
			existing[str((entry as Dictionary).get("id", ""))] = true
	var i: int = 1
	while existing.has("puzzle_%03d" % i):
		i += 1
	return "puzzle_%03d" % i
