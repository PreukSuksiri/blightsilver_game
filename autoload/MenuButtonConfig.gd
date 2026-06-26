extends Node
## Main-menu button visibility and enabled state.
## Shipped defaults: res://data/menu_buttons.json (saved from admin tools in the editor).

signal visibility_changed

const SHIPPED_CONFIG_PATH := "res://data/menu_buttons.json"

## Vertical stack slots on the main menu (slot 1 = Single Player position, up to 6).
const SLOT_COUNT := 6
const SLOT_TOP_Y: Array = [0, 360, 434, 508, 582, 656, 730]
const SLOT_BTN_LEFT := -190.0
const SLOT_BTN_RIGHT := 190.0
const SLOT_BTN_HEIGHT := 60.0

const DEFAULT_CONFIG: Dictionary = {
	"quick_duel": {"label": "Quick Duel", "visible": true, "enabled": true, "slot": 1},
	"campaign": {"label": "Campaign", "visible": true, "enabled": true, "slot": 2},
	"single_player": {
		"label": "Single Player",
		"visible": true,
		"enabled": true,
		"slot": 2,
		"subs": {
			"campaign": {"label": "Campaign", "visible": true, "enabled": true},
			"daily_dungeon": {"label": "Daily Dungeon", "visible": false, "enabled": true},
			"vs_ai": {"label": "VS AI", "visible": true, "enabled": true},
		},
	},
	"multiplayer": {
		"label": "Multiplayer",
		"visible": false,
		"enabled": true,
		"slot": 1,
		"subs": {
			"matchmaking": {"label": "Matchmaking", "visible": true, "enabled": true},
			"private": {"label": "Private", "visible": true, "enabled": true},
			"hot_seat": {"label": "Hot Seat", "visible": true, "enabled": true},
		},
	},
	"deck_builder": {"label": "Deck Builder", "visible": true, "enabled": true, "slot": 3},
	"inventory": {"label": "Inventory", "visible": true, "enabled": true, "slot": 4},
	"shop": {"label": "Shop", "visible": true, "enabled": true, "slot": 5},
	"gallery": {"label": "Gallery", "visible": true, "enabled": true, "slot": 6},
	"credits": {"label": "Credits", "visible": false, "enabled": true, "slot": 0},
	"settings": {"label": "Settings", "visible": true, "enabled": true, "slot": 0},
	"exit_icon": {"label": "Exit Icon", "visible": false, "enabled": true, "slot": 0},
	"exit": {"label": "Exit", "visible": true, "enabled": true, "slot": 0},
}

var _config: Dictionary = {}


func _ready() -> void:
	load_config()


func load_config() -> void:
	if FileAccess.file_exists(SHIPPED_CONFIG_PATH):
		_load_config_file(SHIPPED_CONFIG_PATH)
	else:
		_config = _merge_with_defaults(DEFAULT_CONFIG)


func get_save_path() -> String:
	return SHIPPED_CONFIG_PATH


func save_config() -> bool:
	if not BuildConfig.can_write_shipped_data():
		push_warning("MenuButtonConfig: shipped menu config can only be saved when running from the Godot editor.")
		return false
	var file := FileAccess.open(SHIPPED_CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("MenuButtonConfig: could not write %s" % SHIPPED_CONFIG_PATH)
		return false
	file.store_string(JSON.stringify(_config, "\t"))
	file.close()
	emit_signal("visibility_changed")
	_apply_to_main_menu_if_present()
	return true


func _load_config_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("MenuButtonConfig: could not read %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_warning("MenuButtonConfig: invalid JSON in %s" % path)
		return
	_config = _merge_with_defaults(parsed)


func _apply_to_main_menu_if_present() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var scene: Node = tree.current_scene
	if scene == null or scene.name != "MainMenu":
		return
	if scene.has_method("_apply_menu_button_state"):
		scene.call("_apply_menu_button_state")
	elif scene.has_method("_apply_menu_button_visibility"):
		scene.call("_apply_menu_button_visibility")


func get_config() -> Dictionary:
	return _config.duplicate(true)


func get_main_keys() -> Array:
	var keys: Array = _config.keys()
	keys.sort()
	return keys


func get_sub_keys(main_key: String) -> Array:
	var entry: Dictionary = _config.get(main_key, {})
	var subs: Variant = entry.get("subs", {})
	if not subs is Dictionary:
		return []
	var keys: Array = (subs as Dictionary).keys()
	keys.sort()
	return keys


func has_subs(main_key: String) -> bool:
	return not get_sub_keys(main_key).is_empty()


func get_label(main_key: String, sub_key: String = "") -> String:
	if not sub_key.is_empty():
		var subs: Dictionary = _config.get(main_key, {}).get("subs", {})
		if subs is Dictionary and (subs as Dictionary).has(sub_key):
			return str((subs as Dictionary)[sub_key].get("label", sub_key))
		return sub_key
	return str(_config.get(main_key, {}).get("label", main_key))


func is_main_visible(main_key: String) -> bool:
	if not bool(_config.get(main_key, {}).get("visible", true)):
		return false
	if has_subs(main_key):
		return any_sub_visible(main_key)
	return true


func is_sub_visible(main_key: String, sub_key: String) -> bool:
	if not bool(_config.get(main_key, {}).get("visible", true)):
		return false
	var subs: Dictionary = _config.get(main_key, {}).get("subs", {})
	if not subs is Dictionary:
		return false
	return bool((subs as Dictionary).get(sub_key, {}).get("visible", true))


func any_sub_visible(main_key: String) -> bool:
	for sub_key: String in get_sub_keys(main_key):
		if is_sub_visible(main_key, sub_key):
			return true
	return false


func uses_stack_slot(main_key: String) -> bool:
	return get_main_slot(main_key) > 0


func get_main_slot(main_key: String) -> int:
	return int(_config.get(main_key, {}).get("slot", _default_slot_for(main_key)))


func set_main_slot(main_key: String, slot: int) -> void:
	if not _config.has(main_key):
		return
	_config[main_key]["slot"] = clampi(slot, 0, SLOT_COUNT)


func get_sort_slot(main_key: String) -> int:
	var slot: int = get_main_slot(main_key)
	if slot <= 0:
		return SLOT_COUNT + 1
	return slot


func get_slot_offsets(slot: int) -> Vector4:
	var idx: int = clampi(slot, 1, SLOT_COUNT)
	var top_y: float = float(SLOT_TOP_Y[idx])
	return Vector4(SLOT_BTN_LEFT, top_y, SLOT_BTN_RIGHT, top_y + SLOT_BTN_HEIGHT)


func is_main_enabled(main_key: String) -> bool:
	return bool(_config.get(main_key, {}).get("enabled", true))


func is_sub_enabled(main_key: String, sub_key: String) -> bool:
	var subs: Dictionary = _config.get(main_key, {}).get("subs", {})
	if not subs is Dictionary:
		return true
	return bool((subs as Dictionary).get(sub_key, {}).get("enabled", true))


func set_main_enabled(main_key: String, enabled: bool) -> void:
	if not _config.has(main_key):
		return
	_config[main_key]["enabled"] = enabled


func set_sub_enabled(main_key: String, sub_key: String, enabled: bool) -> void:
	if not _config.has(main_key):
		return
	var subs: Variant = _config[main_key].get("subs", {})
	if not subs is Dictionary or not (subs as Dictionary).has(sub_key):
		return
	_config[main_key]["subs"][sub_key]["enabled"] = enabled


func set_main_visible(main_key: String, visible: bool) -> void:
	if not _config.has(main_key):
		return
	_config[main_key]["visible"] = visible


func set_sub_visible(main_key: String, sub_key: String, visible: bool) -> void:
	if not _config.has(main_key):
		return
	var subs: Variant = _config[main_key].get("subs", {})
	if not subs is Dictionary or not (subs as Dictionary).has(sub_key):
		return
	_config[main_key]["subs"][sub_key]["visible"] = visible


func set_all_visible(visible: bool) -> void:
	for main_key: String in _config.keys():
		_config[main_key]["visible"] = visible
		var subs: Variant = _config[main_key].get("subs", {})
		if subs is Dictionary:
			for sub_key: String in (subs as Dictionary).keys():
				(subs as Dictionary)[sub_key]["visible"] = visible


func set_all_enabled(enabled: bool) -> void:
	for main_key: String in _config.keys():
		_config[main_key]["enabled"] = enabled
		var subs: Variant = _config[main_key].get("subs", {})
		if subs is Dictionary:
			for sub_key: String in (subs as Dictionary).keys():
				(subs as Dictionary)[sub_key]["enabled"] = enabled


func reset_to_defaults() -> void:
	_config = _merge_with_defaults(DEFAULT_CONFIG)
	emit_signal("visibility_changed")


func _merge_with_defaults(source: Dictionary) -> Dictionary:
	var merged: Dictionary = DEFAULT_CONFIG.duplicate(true)
	for main_key: String in source.keys():
		var src_entry: Variant = source[main_key]
		if not src_entry is Dictionary:
			continue
		var dst_entry: Dictionary = merged.get(main_key, {}).duplicate(true)
		dst_entry["label"] = str((src_entry as Dictionary).get("label", dst_entry.get("label", main_key)))
		dst_entry["visible"] = bool((src_entry as Dictionary).get("visible", dst_entry.get("visible", true)))
		dst_entry["enabled"] = bool((src_entry as Dictionary).get("enabled", dst_entry.get("enabled", true)))
		dst_entry["slot"] = int((src_entry as Dictionary).get("slot", dst_entry.get("slot", _default_slot_for(main_key))))
		var src_subs: Variant = (src_entry as Dictionary).get("subs", {})
		if src_subs is Dictionary:
			var dst_subs: Dictionary = dst_entry.get("subs", {}).duplicate(true)
			for sub_key: String in (src_subs as Dictionary).keys():
				var src_sub: Variant = (src_subs as Dictionary)[sub_key]
				if not src_sub is Dictionary:
					continue
				var dst_sub: Dictionary = dst_subs.get(sub_key, {}).duplicate(true)
				dst_sub["label"] = str((src_sub as Dictionary).get("label", dst_sub.get("label", sub_key)))
				dst_sub["visible"] = bool((src_sub as Dictionary).get("visible", dst_sub.get("visible", true)))
				dst_sub["enabled"] = bool((src_sub as Dictionary).get("enabled", dst_sub.get("enabled", true)))
				dst_subs[sub_key] = dst_sub
			dst_entry["subs"] = dst_subs
		merged[main_key] = dst_entry
	return merged


func _default_slot_for(main_key: String) -> int:
	match main_key:
		"quick_duel": return 1
		"campaign": return 2
		"single_player": return 1
		"multiplayer": return 2
		"deck_builder": return 3
		"inventory": return 4
		"shop": return 5
		"gallery": return 6
		"credits": return 0
		_: return 0
