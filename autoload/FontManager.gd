extends Node
## Central font registry — swap game-wide fonts from the admin Font Manager.
## Shipped defaults: res://data/fonts.json (saved from admin tools in the editor).
##
## Primary slot is also applied as the root Theme default font so any Control
## that would otherwise use Godot’s built-in theme font inherits the main UI font.

signal fonts_changed

const SHIPPED_CONFIG_PATH := "res://data/fonts.json"
const FONTS_DIR := "res://assets/fonts/"
const META_SLOT := "fm_slot"
const META_PROP := "fm_prop"
const META_WEIGHT := "fm_weight"
const SLOT_PRIMARY := "primary"
const SLOT_VN := "vn"

## Control types that use a single `font` theme item.
const _THEME_FONT_TYPES: Array[StringName] = [
	&"Label", &"Button", &"CheckBox", &"CheckButton", &"OptionButton",
	&"LinkButton", &"MenuButton", &"LineEdit", &"TextEdit", &"CodeEdit",
	&"ItemList", &"Tree", &"TabBar", &"TabContainer", &"PopupMenu",
	&"TooltipLabel", &"GraphNode", &"Window", &"AcceptDialog",
	&"FileDialog", &"SpinBox",
]

var _slots: Dictionary = {}
var _defaults: Dictionary = {}


func _ready() -> void:
	load_config()
	get_tree().node_added.connect(_on_node_added)
	# After UiTheme (and other autoloads) have created/merged root.theme.
	call_deferred("apply_to_root_theme")


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
	if is_variable(slot_id) and loaded is FontFile:
		var fv := FontVariation.new()
		fv.base_font = loaded as FontFile
		fv.variation_opentype = {"wght": weight}
		return fv
	if loaded is Font:
		return loaded as Font
	return _fallback_font()


func get_font(slot_id: String) -> Font:
	return make_font(slot_id, 400)


func primary_font(weight: int = 400) -> Font:
	return make_font(SLOT_PRIMARY, weight)


func vn_font(weight: int = 400) -> Font:
	return make_font(SLOT_VN, weight)


## Apply primary (and bold primary) onto a Theme so untagged Controls inherit it.
func apply_primary_theme_fonts(theme: Theme) -> void:
	if theme == null:
		return
	var regular: Font = primary_font(400)
	var bold: Font = primary_font(700)
	theme.set_default_font(regular)
	for type_name: StringName in _THEME_FONT_TYPES:
		theme.set_font("font", type_name, regular)
	# RichTextLabel uses separate font roles.
	theme.set_font("normal_font", &"RichTextLabel", regular)
	theme.set_font("bold_font", &"RichTextLabel", bold)
	theme.set_font("italics_font", &"RichTextLabel", regular)
	theme.set_font("bold_italics_font", &"RichTextLabel", bold)
	theme.set_font("mono_font", &"RichTextLabel", regular)


## Push primary fonts into the viewport root Theme (live-swappable).
func apply_to_root_theme() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var root: Window = tree.root
	if root == null:
		return
	var theme: Theme = root.theme if root.theme != null else Theme.new()
	apply_primary_theme_fonts(theme)
	root.theme = theme


## Tag a control so live font swaps refresh it automatically.
func tag_font(node: Control, property: String, slot_id: String, weight: int = 400) -> void:
	if node == null:
		return
	node.set_meta(META_SLOT, slot_id)
	node.set_meta(META_PROP, property)
	node.set_meta(META_WEIGHT, weight)
	_apply_tagged(node)


func tag_primary(node: Control, property: String = "font", weight: int = 400) -> void:
	tag_font(node, property, SLOT_PRIMARY, weight)


func apply_and_notify() -> void:
	save_config()
	apply_to_root_theme()
	refresh_tree()
	emit_signal("fonts_changed")


func refresh_tree(root: Node = null) -> void:
	apply_to_root_theme()
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


func _fallback_font() -> Font:
	var fallback := SystemFont.new()
	fallback.font_names = PackedStringArray(["Sans-Serif"])
	return fallback
