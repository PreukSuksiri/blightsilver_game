extends Control
## ExplorationItemManager — editor UI for the global item catalog.
## Opened from ExplorationEditor toolbar via the "Items" button.
## Allows add / edit / delete of items in ExplorationItemDatabase.
##
## Item fields: id, name, description, icon, big_image, effects[]
## Effect fields: type (enum), key, value

const EFFECT_TYPES: Array = [
	"play_vn",
	"set_var",
	"show_message",
	"play_sfx",
	"remove_self",
	"remove_item",
	"navigate_to",
	"end_exploration",
	"end_exploration_vn",
]

# ── UI refs ────────────────────────────────────────────────────────────────
var _list_vbox:     VBoxContainer   = null
var _edit_panel:    Panel           = null

# edit form fields
var _ef_id:         LineEdit        = null
var _ef_name:       LineEdit        = null
var _ef_desc:       TextEdit        = null
var _ef_icon:       LineEdit        = null
var _ef_big_image:  LineEdit        = null
var _ef_use_condition: LineEdit     = null
var _ef_key_item_chk: CheckBox      = null
var _ef_effects_vbox: VBoxContainer = null

var _editing_id:    String          = ""   # empty = new item

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 50
	_build_ui()
	_refresh_list()
	if not FontManager.fonts_changed.is_connected(_on_fonts_changed):
		FontManager.fonts_changed.connect(_on_fonts_changed)
	# Re-apply full-rect after the layout pass so the parent's rect is fully resolved
	set_anchors_and_offsets_preset.call_deferred(Control.PRESET_FULL_RECT)

func _on_fonts_changed() -> void:
	FontManager.refresh_tree(self)

func _tag_ui(node: Control, property: String, weight: int = 400) -> void:
	FontManager.tag_font(node, property, "primary", weight)

# ─────────────────────────────────────────────────────────────
# UI Construction
# ─────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Dark background
	var bg := ColorRect.new()
	bg.color        = Color(0.04, 0.05, 0.10, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Root VBox fills the whole overlay
	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ── Toolbar ─────────────────────────────────────────────────────
	var toolbar_bg := PanelContainer.new()
	toolbar_bg.custom_minimum_size = Vector2(0, 44)
	var tb_sb := StyleBoxFlat.new()
	tb_sb.bg_color = Color(0.06, 0.08, 0.18, 1.0)
	toolbar_bg.add_theme_stylebox_override("panel", tb_sb)
	root_vbox.add_child(toolbar_bg)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	toolbar_bg.add_child(toolbar)

	var title_lbl := Label.new()
	title_lbl.text = "  Exploration Items"
	_tag_ui(title_lbl, "font", 700)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(title_lbl)

	var add_btn := _make_btn("+ New Item", func() -> void: _start_edit_new())
	toolbar.add_child(add_btn)

	var back_btn := _make_btn("← Back", func() -> void: queue_free())
	toolbar.add_child(back_btn)

	# ── Two-column body ─────────────────────────────────────────────
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 0)
	root_vbox.add_child(cols)

	# Left: item list
	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var list_sb := StyleBoxFlat.new()
	list_sb.bg_color = Color(0.05, 0.07, 0.14, 1.0)
	list_scroll.add_theme_stylebox_override("panel", list_sb)
	cols.add_child(list_scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 2)
	list_scroll.add_child(_list_vbox)

	# Right: edit panel (initially hidden)
	_edit_panel = Panel.new()
	_edit_panel.custom_minimum_size  = Vector2(540.0, 0.0)
	_edit_panel.size_flags_vertical  = Control.SIZE_EXPAND_FILL
	_edit_panel.visible              = false
	var ep_sb := StyleBoxFlat.new()
	ep_sb.bg_color         = Color(0.06, 0.08, 0.18, 1.0)
	ep_sb.border_width_left = 2
	ep_sb.border_color      = Color(0.35, 0.60, 1.0, 0.30)
	_edit_panel.add_theme_stylebox_override("panel", ep_sb)
	cols.add_child(_edit_panel)

	_build_edit_panel()

func _build_edit_panel() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edit_panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.offset_left = 20.0
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	# Spacer at top
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 12); vbox.add_child(sp)

	# ── Heading ────────────────────────────────────────────
	var heading := Label.new()
	heading.text = "Edit Item"
	_tag_ui(heading, "font", 700)
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
	vbox.add_child(heading)

	# ── Fields ─────────────────────────────────────────────
	_ef_id   = _make_field_row(vbox, "ID",          "item_id (no spaces)")
	_ef_name = _make_field_row(vbox, "Name",        "Display name")
	_ef_icon = _make_image_field_row(vbox, "Icon",      "res:// path to small icon")
	_ef_big_image = _make_image_field_row(vbox, "Big Image", "res:// path to large preview")

	# Description (multi-line)
	vbox.add_child(_make_label("Description"))
	_ef_desc = TextEdit.new()
	_ef_desc.custom_minimum_size = Vector2(0.0, 80.0)
	_ef_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ef_desc.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_ef_desc)

	vbox.add_child(_make_label("Use Condition (optional)"))
	_ef_use_condition = LineEdit.new()
	_ef_use_condition.placeholder_text = "e.g. has_item(\"key\") and var(\"flag\") == \"1\""
	_ef_use_condition.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ef_use_condition.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_ef_use_condition)

	# ── Condition reference panel ────────────────────────────
	var ref_panel := PanelContainer.new()
	ref_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ref_sb := StyleBoxFlat.new()
	ref_sb.bg_color = Color(0.04, 0.07, 0.14, 1.0)
	ref_sb.set_border_width_all(1)
	ref_sb.border_color = Color(0.25, 0.45, 0.70, 0.40)
	ref_sb.set_corner_radius_all(4)
	ref_sb.content_margin_left   = 10.0
	ref_sb.content_margin_right  = 10.0
	ref_sb.content_margin_top    = 8.0
	ref_sb.content_margin_bottom = 8.0
	ref_panel.add_theme_stylebox_override("panel", ref_sb)
	vbox.add_child(ref_panel)

	var ref_vbox := VBoxContainer.new()
	ref_vbox.add_theme_constant_override("separation", 4)
	ref_panel.add_child(ref_vbox)

	const REF_HEADER_COL := Color(0.50, 0.78, 1.0)
	const REF_FN_COL     := Color(0.65, 1.00, 0.75)
	const REF_OP_COL     := Color(1.00, 0.85, 0.50)
	const REF_EX_COL     := Color(0.60, 0.65, 0.72)
	const REF_FS         := 12

	var _ref_lbl := func(text: String, color: Color, bold: bool = false) -> void:
		var l := Label.new()
		l.text = text
		l.add_theme_font_size_override("font_size", REF_FS)
		l.add_theme_color_override("font_color", color)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if bold:
			FontManager.tag_font(l, "font", "primary", 700)
		ref_vbox.add_child(l)

	_ref_lbl.call("Functions", REF_HEADER_COL, true)
	_ref_lbl.call("  has_item(\"item_id\")   — true if player holds that item", REF_FN_COL)
	_ref_lbl.call("  at_node(\"node_id\")    — true if player is at that node", REF_FN_COL)
	_ref_lbl.call("  var(\"key\")            — reads an exploration variable", REF_FN_COL)

	var sep1 := HSeparator.new()
	sep1.add_theme_constant_override("separation", 2)
	ref_vbox.add_child(sep1)

	_ref_lbl.call("Comparisons  (for var())", REF_HEADER_COL, true)
	_ref_lbl.call("  ==   !=   >   <   >=   <=", REF_OP_COL)

	var sep2 := HSeparator.new()
	sep2.add_theme_constant_override("separation", 2)
	ref_vbox.add_child(sep2)

	_ref_lbl.call("Combinators", REF_HEADER_COL, true)
	_ref_lbl.call("  and   or   not   ( … )", REF_OP_COL)

	var sep3 := HSeparator.new()
	sep3.add_theme_constant_override("separation", 2)
	ref_vbox.add_child(sep3)

	_ref_lbl.call("Examples", REF_HEADER_COL, true)
	_ref_lbl.call("  has_item(\"library_card\")", REF_EX_COL)
	_ref_lbl.call("  has_item(\"key\") and at_node(\"locked_door\")", REF_EX_COL)
	_ref_lbl.call("  var(\"chapter\") == \"2\" and not has_item(\"used_map\")", REF_EX_COL)
	_ref_lbl.call("  (has_item(\"coin\") or var(\"gold\") > 10) and at_node(\"shop\")", REF_EX_COL)

	_ef_key_item_chk = CheckBox.new()
	_ef_key_item_chk.text = "Key Item"
	_ef_key_item_chk.tooltip_text = "Pulses the inventory HUD icon when this item can be used"
	_ef_key_item_chk.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_ef_key_item_chk)

	# ── Effects ────────────────────────────────────────────
	var eff_hdr_row := HBoxContainer.new()
	eff_hdr_row.add_theme_constant_override("separation", 8)
	vbox.add_child(eff_hdr_row)

	var eff_lbl := _make_label("Effects (in order)")
	eff_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eff_hdr_row.add_child(eff_lbl)

	var add_eff_btn := _make_btn("+ Add Effect", func() -> void: _add_effect_row({}))
	eff_hdr_row.add_child(add_eff_btn)

	_ef_effects_vbox = VBoxContainer.new()
	_ef_effects_vbox.add_theme_constant_override("separation", 6)
	vbox.add_child(_ef_effects_vbox)

	# ── Action buttons ─────────────────────────────────────
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var save_btn := _make_btn("Save Item", func() -> void: _commit_edit())
	save_btn.add_theme_color_override("font_color", Color(0.65, 1.0, 0.70))
	btn_row.add_child(save_btn)

	var del_btn := _make_btn("Delete Item", func() -> void: _delete_editing_item())
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.50, 0.45))
	btn_row.add_child(del_btn)

	var cancel_btn := _make_btn("Cancel", func() -> void: _edit_panel.visible = false)
	btn_row.add_child(cancel_btn)

# ─────────────────────────────────────────────────────────────
# Item List
# ─────────────────────────────────────────────────────────────

func _refresh_list() -> void:
	for c: Node in _list_vbox.get_children():
		c.queue_free()

	var items: Array = ExplorationItemDatabase.all_items()
	if items.is_empty():
		var lbl := Label.new()
		lbl.text = "  No items yet. Click '+ New Item'."
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.65))
		_list_vbox.add_child(lbl)
		return

	for entry: Variant in items:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		var item_id: String = str(d.get("id", "?"))
		var item_name: String = str(d.get("name", item_id))

		var row := Button.new()
		row.text = "%s  [%s]" % [item_name, item_id]
		row.flat = true
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_theme_font_size_override("font_size", 15)
		row.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0))
		var captured_id: String = item_id
		row.pressed.connect(func() -> void: _start_edit_existing(captured_id))
		_list_vbox.add_child(row)

# ─────────────────────────────────────────────────────────────
# Edit Panel Population
# ─────────────────────────────────────────────────────────────

func _start_edit_new() -> void:
	_editing_id = ""
	_ef_id.text          = ExplorationItemDatabase.generate_id()
	_ef_id.editable      = true
	_ef_name.text        = ""
	_ef_desc.text        = ""
	_ef_icon.text        = ""
	_ef_big_image.text   = ""
	_ef_use_condition.text = ""
	_ef_key_item_chk.button_pressed = false
	_clear_effects()
	_edit_panel.visible  = true

func _start_edit_existing(item_id: String) -> void:
	var d: Dictionary = ExplorationItemDatabase.get_item(item_id)
	if d.is_empty():
		return
	_editing_id          = item_id
	_ef_id.text          = item_id
	_ef_id.editable      = false   # id is immutable once created
	_ef_name.text        = str(d.get("name",        ""))
	_ef_desc.text        = str(d.get("description", ""))
	_ef_icon.text        = str(d.get("icon",        ""))
	_ef_big_image.text   = str(d.get("big_image",   ""))
	_ef_use_condition.text = str(d.get("use_condition", ""))
	_ef_key_item_chk.button_pressed = bool(d.get("key_item", false))
	_clear_effects()
	var effs: Variant = d.get("effects", [])
	if effs is Array:
		for eff: Variant in (effs as Array):
			if eff is Dictionary:
				_add_effect_row(eff as Dictionary)
	_edit_panel.visible  = true

func _clear_effects() -> void:
	for c: Node in _ef_effects_vbox.get_children():
		c.queue_free()

func _add_effect_row(eff: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_ef_effects_vbox.add_child(row)

	# Type dropdown
	var type_btn := OptionButton.new()
	type_btn.custom_minimum_size = Vector2(140.0, 0.0)
	for t: String in EFFECT_TYPES:
		type_btn.add_item(t)
	var current_type: String = str(eff.get("type", "show_message"))
	var type_idx: int = EFFECT_TYPES.find(current_type)
	if type_idx >= 0:
		type_btn.select(type_idx)
	row.add_child(type_btn)

	# Key field
	var key_edit := LineEdit.new()
	key_edit.placeholder_text  = "key"
	key_edit.text              = str(eff.get("key", ""))
	key_edit.custom_minimum_size = Vector2(110.0, 0.0)
	key_edit.add_theme_font_size_override("font_size", 13)
	row.add_child(key_edit)

	# Value field
	var val_edit := LineEdit.new()
	val_edit.placeholder_text = "value"
	val_edit.text             = str(eff.get("value", ""))
	val_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_edit.add_theme_font_size_override("font_size", 13)
	row.add_child(val_edit)

	# VN browse button (shown for play_vn and end_exploration_vn)
	var vn_browse_btn := Button.new()
	vn_browse_btn.text = "…"
	vn_browse_btn.tooltip_text = "Browse VN JSON (fills value field)"
	vn_browse_btn.custom_minimum_size = Vector2(28.0, 0.0)
	vn_browse_btn.pressed.connect(func() -> void:
		var dialog := FileDialog.new()
		dialog.file_mode   = FileDialog.FILE_MODE_OPEN_FILE
		dialog.filters     = PackedStringArray(["*.json ; JSON Files"])
		dialog.access      = FileDialog.ACCESS_RESOURCES
		dialog.current_dir = "res://exploration"
		dialog.file_selected.connect(func(path: String) -> void: val_edit.text = path)
		add_child(dialog)
		dialog.popup_centered(Vector2(900, 600)))
	row.add_child(vn_browse_btn)

	# Edit Beat button (opens VNEditor overlay; shown for play_vn and end_exploration_vn)
	var edit_beat_btn := Button.new()
	edit_beat_btn.text = "Edit"
	edit_beat_btn.tooltip_text = "Open VN Beat Editor for this file"
	edit_beat_btn.custom_minimum_size = Vector2(44.0, 0.0)
	edit_beat_btn.add_theme_font_size_override("font_size", 12)
	edit_beat_btn.pressed.connect(func() -> void:
		var path: String = val_edit.text.strip_edges()
		if path.is_empty():
			return
		var vned: Control = load("res://scripts/VNEditor.gd").new()
		vned.name = "VNEditorOverlay"
		get_tree().current_scene.add_child(vned)
		vned.call_deferred("open_file", path))
	row.add_child(edit_beat_btn)

	# Play Once checkbox (shown only for play_vn)
	var play_once_chk := CheckBox.new()
	play_once_chk.text = "once"
	play_once_chk.tooltip_text = "Play this VN only once per session"
	play_once_chk.button_pressed = bool(eff.get("play_once", false))
	play_once_chk.add_theme_font_size_override("font_size", 12)
	row.add_child(play_once_chk)

	# Tag controls on the row for reliable collection in _commit_edit
	row.set_meta("type_btn",       type_btn)
	row.set_meta("key_edit",       key_edit)
	row.set_meta("val_edit",       val_edit)
	row.set_meta("play_once_chk",  play_once_chk)

	# Toggle VN-only controls based on selected type
	var _vn_types := ["play_vn", "end_exploration_vn"]
	var _refresh_vn_controls := func(idx: int) -> void:
		var t: String = EFFECT_TYPES[idx]
		vn_browse_btn.visible  = t in _vn_types
		edit_beat_btn.visible  = t in _vn_types
		play_once_chk.visible  = t == "play_vn"
	type_btn.item_selected.connect(_refresh_vn_controls)
	_refresh_vn_controls.call(type_btn.selected)

	# Remove button
	var rem_btn := _make_btn("✕", func() -> void: row.queue_free())
	rem_btn.custom_minimum_size = Vector2(28.0, 0.0)
	rem_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	row.add_child(rem_btn)

# ─────────────────────────────────────────────────────────────
# Commit / Delete
# ─────────────────────────────────────────────────────────────

func _commit_edit() -> void:
	var new_id: String = _ef_id.text.strip_edges()
	if new_id.is_empty():
		return

	var effects: Array = []
	for row_node: Node in _ef_effects_vbox.get_children():
		if not row_node is HBoxContainer:
			continue
		var row: HBoxContainer = row_node as HBoxContainer
		if not row.has_meta("type_btn"):
			continue
		var t_btn := row.get_meta("type_btn") as OptionButton
		var k_ed  := row.get_meta("key_edit")  as LineEdit
		var v_ed  := row.get_meta("val_edit")   as LineEdit
		var once_chk := row.get_meta("play_once_chk") as CheckBox
		var eff_type: String = EFFECT_TYPES[t_btn.selected]
		var entry: Dictionary = {
			"type":  eff_type,
			"key":   k_ed.text.strip_edges(),
			"value": v_ed.text.strip_edges(),
		}
		if eff_type == "play_vn" and once_chk.button_pressed:
			entry["play_once"] = true
		effects.append(entry)

	var data: Dictionary = {
		"id":          new_id,
		"name":        _ef_name.text.strip_edges(),
		"description": _ef_desc.text.strip_edges(),
		"icon":        _ef_icon.text.strip_edges(),
		"big_image":      _ef_big_image.text.strip_edges(),
		"use_condition":  _ef_use_condition.text.strip_edges(),
		"key_item":      _ef_key_item_chk.button_pressed,
		"effects":        effects,
	}
	ExplorationItemDatabase.upsert_item(data)
	_editing_id = new_id
	_ef_id.editable = false
	_refresh_list()

func _delete_editing_item() -> void:
	if _editing_id.is_empty():
		_edit_panel.visible = false
		return
	ExplorationItemDatabase.delete_item(_editing_id)
	_editing_id = ""
	_edit_panel.visible = false
	_refresh_list()

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────

func _make_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.90))
	return lbl

func _make_field_row(parent: Control, label_text: String, placeholder: String) -> LineEdit:
	parent.add_child(_make_label(label_text))
	var le := LineEdit.new()
	le.placeholder_text        = placeholder
	le.size_flags_horizontal   = Control.SIZE_EXPAND_FILL
	le.add_theme_font_size_override("font_size", 14)
	parent.add_child(le)
	return le

func _make_image_field_row(parent: Control, label_text: String, placeholder: String) -> LineEdit:
	parent.add_child(_make_label(label_text))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var le := LineEdit.new()
	le.placeholder_text      = placeholder
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.add_theme_font_size_override("font_size", 14)
	row.add_child(le)
	var browse_btn := Button.new()
	browse_btn.text = "…"
	browse_btn.custom_minimum_size = Vector2(32.0, 0.0)
	browse_btn.add_theme_font_size_override("font_size", 14)
	browse_btn.pressed.connect(func() -> void: _browse_for_image(le))
	row.add_child(browse_btn)
	return le

func _browse_for_image(target: LineEdit) -> void:
	var dialog := FileDialog.new()
	dialog.file_mode   = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters     = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Image Files"])
	dialog.access      = FileDialog.ACCESS_RESOURCES
	dialog.current_dir = "res://assets/textures"
	dialog.file_selected.connect(func(path: String) -> void: target.text = path)
	add_child(dialog)
	dialog.popup_centered(Vector2(900, 600))

func _make_btn(text: String, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	_tag_ui(btn, "font", 400)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(cb)
	return btn
