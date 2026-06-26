extends Node
## Quick Duel protagonist definitions — display names, portrait folders, win screens.

const PROTAGONISTS: Dictionary = {
	"nex": {
		"display_name": "Nex Crowmont",
		"portrait_dir": "res://assets/textures/profile/battle_illustrations/demo_vs_ai/players/nex",
		"win_screen": "res://assets/textures/profile/win_screen/img_win_screen_nex.png",
	},
	"mayu": {
		"display_name": "Mayu Kokawa",
		"portrait_dir": "res://assets/textures/profile/battle_illustrations/demo_vs_ai/players/mayu",
		"win_screen": "res://assets/textures/profile/win_screen/img_win_screen_mayu.png",
	},
	"kelly": {
		"display_name": "Kelly Lastochkina",
		"portrait_dir": "res://assets/textures/profile/battle_illustrations/demo_vs_ai/players/kelly",
		"win_screen": "res://assets/textures/profile/win_screen/img_win_screen_kelly.png",
	},
}

const LOSE_SCREEN_PATH := "res://assets/textures/profile/win_screen/img_lose_screen_default.png"
const DEFAULT_ID := "nex"


func get_protagonist_ids() -> Array[String]:
	var out: Array[String] = []
	for key: Variant in PROTAGONISTS.keys():
		out.append(str(key))
	out.sort()
	return out


func is_valid_id(protagonist_id: String) -> bool:
	return PROTAGONISTS.has(protagonist_id.strip_edges().to_lower())


func normalize_id(protagonist_id: String) -> String:
	var id := protagonist_id.strip_edges().to_lower()
	return id if is_valid_id(id) else DEFAULT_ID


func get_display_name(protagonist_id: String) -> String:
	var id := normalize_id(protagonist_id)
	return str((PROTAGONISTS[id] as Dictionary).get("display_name", id.capitalize()))


func get_portrait_dir(protagonist_id: String) -> String:
	var id := normalize_id(protagonist_id)
	return str((PROTAGONISTS[id] as Dictionary).get("portrait_dir", "")).strip_edges()


func get_win_screen_path(protagonist_id: String) -> String:
	var id := normalize_id(protagonist_id)
	var path: String = str((PROTAGONISTS[id] as Dictionary).get("win_screen", "")).strip_edges()
	if path != "" and ResourceLoader.exists(path):
		return path
	return str((PROTAGONISTS[DEFAULT_ID] as Dictionary).get("win_screen", ""))


func get_lose_screen_path(_protagonist_id: String = "") -> String:
	if ResourceLoader.exists(LOSE_SCREEN_PATH):
		return LOSE_SCREEN_PATH
	return ""


func list_portraits(protagonist_id: String) -> Array[String]:
	var dir_path: String = get_portrait_dir(protagonist_id)
	if dir_path.is_empty():
		return []
	var paths: Array[String] = []
	_collect_pngs(dir_path, paths)
	paths.sort()
	return paths


func get_default_portrait(protagonist_id: String) -> String:
	var portraits: Array[String] = list_portraits(protagonist_id)
	if portraits.is_empty():
		return ""
	return portraits[0]


func get_portrait_or_default(protagonist_id: String, portrait_path: String) -> String:
	var chosen: String = portrait_path.strip_edges()
	if chosen != "" and (ResourceLoader.exists(chosen) or FileAccess.file_exists(chosen)):
		return chosen
	return get_default_portrait(protagonist_id)


func _collect_pngs(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if name.begins_with("."):
			continue
		var full: String = "%s/%s" % [dir_path.rstrip("/"), name]
		if dir.current_is_dir():
			_collect_pngs(full, out)
		elif name.to_lower().ends_with(".png"):
			out.append(full)
	dir.list_dir_end()
