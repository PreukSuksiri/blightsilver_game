extends Control
## ExplorationItemManager — editor UI for the global item catalog.
## Opened from ExplorationEditor toolbar via the "Items" button.
## Allows add / edit / delete of items in ExplorationItemDatabase.
##
## Item fields: id, name, description, icon, big_image, effects[]
## Effect fields: type (enum), key, value

const FONT_PATH: String = "res://assets/fonts/Chivo-VariableFont_wght.ttf"

const EFFECT_TYPES: Array = [
	"play_vn",
	"set_var",
	"show_message",
	"play_sfx",
	"remove_self",
	"remove_item",
	"navigate_to",
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
var _ef_effects_vbox: VBoxContainer = null

var _editing_id:    String          = ""   # empty = new item

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 50
	_build_ui()
	_refresh_list()

func _make_font(weight: int) -> FontVariation:
	var base := load(FONT_PATH) as FontFile
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {"wght": weight}
	return fv

# ─────────────────────────────────────────────────────────────
# UI Construction
# ─────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Dark background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color        = Color(0.04, 0.05, 0.10, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Toolbar
	var toolbar := HBoxContainer.new()
	toolbar.layout_mode = 1
	toolbar.anchor_left = 0.0; toolbar.anchor_right  = 1.0
	toolbar.anchor_top  = 0.0; toolbar.anchor_bottom = 0.0
	toolbar.offset_bottom = 44.0
	toolbar.add_theme_constant_override("separation", 8)
	var tb_bg := StyleBoxFlat.new()
	tb_bg.bg_color = Color(0.06, 0.08, 0.18, 1.0)
	toolbar.add_theme_stylebox_override("panel", tb_bg)
	add_child(toolbar)

	var title_lbl := Label.new()
	title_lbl.text = "  Exploration Items"
	title_lbl.add_theme_font_override("font", _make_font(700))
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(title_lbl)

	var add_btn := _make_btn("+ New Item", func() -> void: _start_edit_new())
	toolbar.add_child(add_btn)

	var back_btn := _make_btn("← Back", func() -> void: queue_free())
	toolbar.add_child(back_btn)

	# Two-column layout: list (left) + edit panel (right)
	var cols := HBoxContainer.new()
	cols.layout_mode = 1
	cols.anchor_left = 0.0; cols.anchor_right  = 1.0
	cols.anchor_top  = 0.0; cols.anchor_bottom = 1.0
	cols.offset_top  = 44.0
	cols.add_theme_constant_override("separation", 0)
	add_child(cols)

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
	_edit_panel.custom_minimum_size = Vector2(540.0, 0.0)
	_edit_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_edit_panel.visible             = false
	var ep_sb := StyleBoxFlat.new()
	ep_sb.bg_color = Color(0.06, 0.08, 0.18, 1.0)
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
	heading.add_theme_font_override("font", _make_font(700))
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
	vbox.add_child(heading)

	# ── Fields ─────────────────────────────────────────────
	_ef_id   = _make_field_row(vbox, "ID",          "item_id (no spaces)")
	_ef_name = _make_field_row(vbox, "Name",        "Display name")
	_ef_icon = _make_field_row(vbox, "Icon",        "res:// path to small icon")
	_ef_big_image = _make_field_row(vbox, "Big Image", "res:// path to large preview")

	# Description (multi-line)
	vbox.add_child(_make_label("Description"))
	_ef_desc = TextEdit.new()
	_ef_desc.custom_minimum_size = Vector2(0.0, 80.0)
	_ef_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ef_desc.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_ef_desc)

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
		var children: Array = row.get_children()
		if children.size() < 3:
			continue
		var t_btn: Variant = children[0]
		var k_ed:  Variant = children[1]
		var v_ed:  Variant = children[2]
		if t_btn is OptionButton and k_ed is LineEdit and v_ed is LineEdit:
			effects.append({
				"type":  EFFECT_TYPES[(t_btn as OptionButton).selected],
				"key":   (k_ed as LineEdit).text.strip_edges(),
				"value": (v_ed as LineEdit).text.strip_edges(),
			})

	var data: Dictionary = {
		"id":          new_id,
		"name":        _ef_name.text.strip_edges(),
		"description": _ef_desc.text.strip_edges(),
		"icon":        _ef_icon.text.strip_edges(),
		"big_image":   _ef_big_image.text.strip_edges(),
		"effects":     effects,
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

func _make_btn(text: String, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(cb)
	return btn
