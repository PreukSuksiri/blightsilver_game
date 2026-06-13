extends Node
## Central font registry — swap game-wide fonts from the admin Font Manager.
## Shipped defaults: res://data/fonts.json (saved from admin tools in the editor).

signal fonts_changed

const SHIPPED_CONFIG_PATH := "res://data/fonts.json"
const FONTS_DIR := "res://assets/fonts/"
const SYMBOL_FALLBACK_PATHS: Array[String] = [
	"res://assets/fonts/MPLUS1p-Regular.ttf",
	"res://assets/fonts/NotoSansSymbols2-Regular.ttf",
]
const PATCH_FONT_PATHS: Array[String] = [
	"res://assets/fonts/Chivo-VariableFont_wght.ttf",
	"res://assets/fonts/Chivo-Italic-VariableFont_wght.ttf",
]
const META_SLOT := "fm_slot"
const META_PROP := "fm_prop"
const META_WEIGHT := "fm_weight"

var _slots: Dictionary = {}
var _defaults: Dictionary = {}
var _symbol_fallbacks: Array[Font] = []
var _default_theme: Theme = null


func _ready() -> void:
	load_config()
	_init_symbol_fallbacks()
	_patch_bundled_font_fallbacks()
	_apply_default_theme()
	get_tree().node_added.connect(_on_node_added)


func load_config() -> void:
	_defaults = _load_json_file(SHIPPED_CONFIG_PATH)
	_slots = _deep_copy_slots(_defaults)


func save_config() -> bool:
	if not BuildConfig.can_write_shipped_data():
		push_warning("FontManager: shipped font config can only be saved when running from the Godot editor.")
		return false
	var out: Dictionary = _defaults.duplicate(true)
	if not out.has("slots"):
		out["slots"] = {}
	var out_slots: Dictionary = out["slots"]
	for slot_id: String in _slots:
		if not out_slots.has(slot_id):
			continue
		(out_slots[slot_id] as Dictionary)["path"] = get_slot_path(slot_id)
	var file := FileAccess.open(SHIPPED_CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("FontManager: could not write %s" % SHIPPED_CONFIG_PATH)
		return false
	file.store_string(JSON.stringify(out, "\t"))
	file.close()
	_defaults = _load_json_file(SHIPPED_CONFIG_PATH)
	return true


func get_shipped_config_path() -> String:
	return SHIPPED_CONFIG_PATH


func get_all_slots() -> Dictionary:
	return _slots.duplicate(true)


func get_slot_ids() -> Array:
	var ids: Array = _slots.keys()
	ids.sort()
	return ids


func get_slot_label(slot_id: String) -> String:
	var slot: Dictionary = _slots.get(slot_id, {})
	return str(slot.get("label", slot_id))


func get_slot_description(slot_id: String) -> String:
	var slot: Dictionary = _slots.get(slot_id, {})
	return str(slot.get("description", ""))


func get_default_path(slot_id: String) -> String:
	var slot: Dictionary = _defaults.get("slots", {}).get(slot_id, {})
	return str(slot.get("path", ""))


func get_slot_path(slot_id: String) -> String:
	var slot: Dictionary = _slots.get(slot_id, {})
	return str(slot.get("path", ""))


func set_slot_path(slot_id: String, path: String) -> void:
	if not _slots.has(slot_id):
		push_warning("FontManager: unknown slot '%s'" % slot_id)
		return
	_slots[slot_id]["path"] = path.strip_edges()


func is_variable(slot_id: String) -> bool:
	var slot: Dictionary = _slots.get(slot_id, {})
	return bool(slot.get("variable", false))


func reset_slot(slot_id: String) -> void:
	var def_slot: Variant = _defaults.get("slots", {}).get(slot_id, null)
	if def_slot is Dictionary:
		_slots[slot_id] = (def_slot as Dictionary).duplicate(true)


func reset_all() -> void:
	_slots = _deep_copy_slots(_defaults)


func list_font_files() -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(FONTS_DIR)
	if dir == null:
		return result
	dir.list_dir_begin()
	while true:
		var fname: String = dir.get_next()
		if fname.is_empty():
			break
		if dir.current_is_dir():
			continue
		if fname.ends_with(".ttf") or fname.ends_with(".otf"):
			result.append(FONTS_DIR + fname)
	dir.list_dir_end()
	result.sort()
	return result


func make_font(slot_id: String, weight: int = 400) -> Font:
	var path: String = get_slot_path(slot_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return _fallback_font()
	var loaded: Variant = load(path)
	if loaded == null:
		return _fallback_font()
	var font: Font = null
	if is_variable(slot_id) and loaded is FontFile:
		var fv := FontVariation.new()
		fv.base_font = loaded as FontFile
		fv.variation_opentype = {"wght": weight}
		font = fv
	elif loaded is FontFile:
		var wrapped := FontVariation.new()
		wrapped.base_font = loaded as FontFile
		font = wrapped
	elif loaded is Font:
		font = loaded as Font
	if font == null:
		return _fallback_font()
	return _with_symbol_fallback(font)


func get_font(slot_id: String) -> Font:
	return make_font(slot_id, 400)


## Primary UI font with symbol fallback (✕, ←, →, etc.). Prefer over raw Chivo preloads.
func ui_font(weight: int = 400) -> Font:
	return make_font("primary", weight)


## Tag a control so live font swaps refresh it automatically.
func tag_font(node: Control, property: String, slot_id: String, weight: int = 400) -> void:
	if node == null:
		return
	node.set_meta(META_SLOT, slot_id)
	node.set_meta(META_PROP, property)
	node.set_meta(META_WEIGHT, weight)
	_apply_tagged(node)


func apply_and_notify() -> void:
	save_config()
	refresh_tree()
	emit_signal("fonts_changed")


func refresh_tree(root: Node = null) -> void:
	var start: Node = root if root != null else get_tree().root
	_walk_refresh(start)


func _walk_refresh(node: Node) -> void:
	if node is Control and node.has_meta(META_SLOT):
		_apply_tagged(node as Control)
	for child: Node in node.get_children():
		_walk_refresh(child)


func _apply_tagged(node: Control) -> void:
	var slot_id: String = str(node.get_meta(META_SLOT, ""))
	var prop: String = str(node.get_meta(META_PROP, "font"))
	var weight: int = int(node.get_meta(META_WEIGHT, 400))
	if slot_id.is_empty():
		return
	node.add_theme_font_override(prop, make_font(slot_id, weight))


func _on_node_added(node: Node) -> void:
	if node is Control and (node as Control).has_meta(META_SLOT):
		_apply_tagged(node as Control)


func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}


func _deep_copy_slots(source: Dictionary) -> Dictionary:
	var out: Dictionary = {"slots": {}}
	var src_slots: Variant = source.get("slots", {})
	if not src_slots is Dictionary:
		return out
	for slot_id: Variant in (src_slots as Dictionary):
		var slot: Variant = (src_slots as Dictionary)[slot_id]
		if slot is Dictionary:
			out["slots"][str(slot_id)] = (slot as Dictionary).duplicate(true)
	return out["slots"]


func _with_symbol_fallback(font: Font) -> Font:
	var fallbacks: Array = font.get_fallbacks().duplicate()
	for fb: Font in _symbol_fallbacks:
		if fb not in fallbacks:
			fallbacks.append(fb)
	if fallbacks != font.get_fallbacks():
		font.set_fallbacks(fallbacks)
	return font


func _init_symbol_fallbacks() -> void:
	if not _symbol_fallbacks.is_empty():
		return
	for path: String in SYMBOL_FALLBACK_PATHS:
		if not ResourceLoader.exists(path):
			push_warning("FontManager: symbol fallback font missing at %s" % path)
			continue
		var loaded: Variant = load(path)
		if loaded is Font:
			_symbol_fallbacks.append(loaded as Font)


func _patch_bundled_font_fallbacks() -> void:
	for path: String in PATCH_FONT_PATHS:
		if not ResourceLoader.exists(path):
			continue
		var ff: Variant = load(path)
		if ff is FontFile:
			_with_symbol_fallback(ff as FontFile)


func _apply_default_theme() -> void:
	if _default_theme != null:
		return
	var ui := ui_font(400)
	_default_theme = Theme.new()
	_default_theme.default_font = ui
	_default_theme.default_font_size = 16
	for type_name: String in [
			"Button", "Label", "LineEdit", "RichTextLabel",
			"OptionButton", "CheckBox", "TabBar", "TextEdit"]:
		_default_theme.set_font(type_name, "font", ui)
		_default_theme.set_font_size(type_name, "font_size", 16)
	get_tree().root.theme = _default_theme


func _symbol_fallback_font() -> Font:
	if _symbol_fallbacks.is_empty():
		_init_symbol_fallbacks()
	if _symbol_fallbacks.is_empty():
		return null
	return _symbol_fallbacks[0]


func _fallback_font() -> Font:
	if _symbol_fallbacks.is_empty():
		_init_symbol_fallbacks()
	if _symbol_fallbacks.is_empty():
		return null
	return _symbol_fallbacks[0]
