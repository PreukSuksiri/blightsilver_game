extends Node
## Quick Duel protagonist definitions — display names, portrait folders, win screens, poses.

const DATA_PATH := "res://data/protagonists.json"
const LOSE_SCREEN_PATH := "res://assets/textures/profile/win_screen/img_lose_screen_default.png"
const DEFAULT_ID := "nex"

var _protagonists: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	_protagonists.clear()
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		_seed_fallback()
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		_protagonists = (parsed as Dictionary).duplicate(true)
	if _protagonists.is_empty():
		_seed_fallback()


func save() -> bool:
	var f := FileAccess.open(DATA_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(_protagonists, "\t"))
	f.close()
	reload()
	return true


func get_data() -> Dictionary:
	return _protagonists.duplicate(true)


func set_data(data: Dictionary) -> void:
	_protagonists = data.duplicate(true)


func get_protagonist_ids() -> Array[String]:
	var out: Array[String] = []
	for key: Variant in _protagonists.keys():
		out.append(str(key))
	out.sort()
	return out


func is_valid_id(protagonist_id: String) -> bool:
	return _protagonists.has(protagonist_id.strip_edges().to_lower())


func normalize_id(protagonist_id: String) -> String:
	var id := protagonist_id.strip_edges().to_lower()
	return id if is_valid_id(id) else DEFAULT_ID


func get_display_name(protagonist_id: String) -> String:
	var id := normalize_id(protagonist_id)
	var entry: Variant = _protagonists.get(id, {})
	if entry is Dictionary:
		return str((entry as Dictionary).get("display_name", id.capitalize()))
	return id.capitalize()


func get_portrait_dir(protagonist_id: String) -> String:
	var id := normalize_id(protagonist_id)
	var entry: Variant = _protagonists.get(id, {})
	if entry is Dictionary:
		return str((entry as Dictionary).get("portrait_dir", "")).strip_edges()
	return ""


func get_win_screen_path(protagonist_id: String) -> String:
	var id := normalize_id(protagonist_id)
	var entry: Variant = _protagonists.get(id, {})
	if entry is Dictionary:
		var path: String = str((entry as Dictionary).get("win_screen", "")).strip_edges()
		if path != "" and ResourceLoader.exists(path):
			return path
	return ""


func get_lose_screen_path(_protagonist_id: String = "") -> String:
	if ResourceLoader.exists(LOSE_SCREEN_PATH):
		return LOSE_SCREEN_PATH
	return ""


func get_poses(protagonist_id: String) -> Array:
	var id := normalize_id(protagonist_id)
	var entry: Variant = _protagonists.get(id, {})
	if not entry is Dictionary:
		return []
	var raw: Variant = (entry as Dictionary).get("poses", [])
	return (raw as Array).duplicate(true) if raw is Array else []


func resolve_pose_portrait_path(protagonist_id: String, pose_entry: Dictionary) -> String:
	var dir: String = get_portrait_dir(protagonist_id)
	var file: String = str(pose_entry.get("portrait", "")).strip_edges()
	if file.is_empty():
		return ""
	if file.begins_with("res://"):
		return file
	if dir.is_empty():
		return ""
	return "%s/%s" % [dir.rstrip("/"), file]


func is_pose_unlocked(protagonist_id: String, pose_index: int) -> bool:
	for pose: Variant in get_poses(protagonist_id):
		if not pose is Dictionary:
			continue
		var p: Dictionary = pose as Dictionary
		if int(p.get("index", 0)) != pose_index:
			continue
		if not bool(p.get("locked", false)):
			return true
		var ach: String = str(p.get("unlock_achievement_id", "")).strip_edges()
		if ach.is_empty():
			return true
		return AchievementManager.is_unlocked(ach) \
				and MailboxManager.is_achievement_reward_claimed(ach)
	return false


func is_pose_portrait_unlocked(protagonist_id: String, portrait_path: String) -> bool:
	var path: String = portrait_path.strip_edges()
	if path.is_empty():
		return true
	var owner: String = get_protagonist_for_portrait(path)
	if not owner.is_empty() and owner != normalize_id(protagonist_id):
		return false
	for pose: Variant in get_poses(protagonist_id):
		if not pose is Dictionary:
			continue
		var resolved: String = resolve_pose_portrait_path(protagonist_id, pose as Dictionary)
		if resolved != path:
			continue
		return is_pose_unlocked(protagonist_id, int((pose as Dictionary).get("index", 0)))
	return true


func get_protagonist_for_portrait(portrait_path: String) -> String:
	var path: String = portrait_path.strip_edges()
	if path.is_empty():
		return ""
	for pid: String in get_protagonist_ids():
		for pose: Variant in get_poses(pid):
			if not pose is Dictionary:
				continue
			if resolve_pose_portrait_path(pid, pose as Dictionary) == path:
				return pid
	return ""


func portrait_belongs_to(protagonist_id: String, portrait_path: String) -> bool:
	var path: String = portrait_path.strip_edges()
	if path.is_empty():
		return true
	var owner: String = get_protagonist_for_portrait(path)
	if owner.is_empty():
		return true
	return owner == normalize_id(protagonist_id)


func get_first_unlocked_portrait(protagonist_id: String) -> String:
	var id := normalize_id(protagonist_id)
	for pose: Variant in get_poses(id):
		if not pose is Dictionary:
			continue
		var idx: int = int((pose as Dictionary).get("index", 0))
		if is_pose_unlocked(id, idx):
			return resolve_pose_portrait_path(id, pose as Dictionary)
	return get_default_portrait(id)


func list_portraits(protagonist_id: String) -> Array[String]:
	var paths: Array[String] = []
	for pose: Variant in get_poses(protagonist_id):
		if not pose is Dictionary:
			continue
		var resolved: String = resolve_pose_portrait_path(protagonist_id, pose as Dictionary)
		if resolved != "":
			paths.append(resolved)
	if paths.is_empty():
		_collect_pngs(get_portrait_dir(protagonist_id), paths)
		paths.sort()
	return paths


func list_pose_entries(protagonist_id: String) -> Array:
	return get_poses(protagonist_id)


func get_pose_reward_for_achievement(achievement_id: String) -> Dictionary:
	if achievement_id.is_empty():
		return {}
	for pid: Variant in _protagonists.keys():
		for pose: Variant in get_poses(str(pid)):
			if not pose is Dictionary:
				continue
			var p: Dictionary = pose as Dictionary
			if str(p.get("unlock_achievement_id", "")).strip_edges() != achievement_id:
				continue
			var protagonist_id: String = str(pid)
			var pose_index: int = int(p.get("index", 0))
			return {
				"protagonist_id": protagonist_id,
				"display_name": get_display_name(protagonist_id),
				"pose_index": pose_index,
				"portrait_path": resolve_pose_portrait_path(protagonist_id, p),
				"label": "%s Pose %d" % [get_display_name(protagonist_id), pose_index],
			}
	return {}


func get_pose_reward_label_for_achievement(achievement_id: String) -> String:
	return str(get_pose_reward_for_achievement(achievement_id).get("label", ""))


func get_default_portrait(protagonist_id: String) -> String:
	var id := normalize_id(protagonist_id)
	for pose: Variant in get_poses(id):
		if not pose is Dictionary:
			continue
		var resolved: String = resolve_pose_portrait_path(id, pose as Dictionary)
		if resolved != "":
			return resolved
	var paths: Array[String] = []
	_collect_pngs(get_portrait_dir(id), paths)
	paths.sort()
	return paths[0] if not paths.is_empty() else ""


func get_portrait_or_default(protagonist_id: String, portrait_path: String) -> String:
	var id: String = normalize_id(protagonist_id)
	var chosen: String = portrait_path.strip_edges()
	if chosen != "" and (ResourceLoader.exists(chosen) or FileAccess.file_exists(chosen)):
		if portrait_belongs_to(id, chosen) and is_pose_portrait_unlocked(id, chosen):
			return chosen
	return get_first_unlocked_portrait(id)


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


func _seed_fallback() -> void:
	_protagonists = {
		"nex": {
			"display_name": "Nex Crowmont",
			"portrait_dir": "res://assets/textures/profile/battle_illustrations/demo_vs_ai/players/nex",
			"win_screen": "res://assets/textures/profile/win_screen/img_win_screen_nex.png",
			"poses": [],
		},
	}
