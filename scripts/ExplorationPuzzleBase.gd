extends Control
class_name ExplorationPuzzleBase
## Base class for manually-coded exploration puzzles.
## Emit puzzle_completed(true) when solved.
## Emit puzzle_completed(false) on cancel/fail — exploration resumes with no rewards; the spot can be retried.
##
## Spot action play_puzzle: value = puzzle id, key = optional params (JSON object or plain text).
## Call setup() before the node enters the tree (ExplorationPlayer does this automatically).

signal puzzle_completed(success: bool)

var puzzle_id: String = ""
var params: Dictionary = {}

func setup(id: String, puzzle_params: Dictionary = {}) -> void:
	puzzle_id = id
	params = puzzle_params.duplicate(true)

static func parse_params(raw: String) -> Dictionary:
	var text: String = raw.strip_edges()
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	if parsed != null:
		return {"value": parsed}
	return {"value": text}

func get_param(key: String, default: Variant = null) -> Variant:
	return params.get(key, default)

func complete_puzzle(success: bool = true) -> void:
	puzzle_completed.emit(success)
