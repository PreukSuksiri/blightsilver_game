extends Control
# ModifierEditorOverlay — admin overlay for editing the dungeon modifier catalog.
# Open via Admin Console: modifier_editor
#
# Displays all modifiers in a scrollable list. Each row lets you edit:
#   • Label (display name)
#   • Description
#   • Positive / Negative toggle (affects colour coding in UI)
#   • Enabled checkbox (disabled modifiers are excluded from the dungeon pool)
#
# Changes are saved to data/dungeon_modifiers.json via DailyDungeonManager.

const _BG_COLOR     := Color(0.05, 0.05, 0.10, 0.97)
const _HEADER_COLOR := Color(0.10, 0.12, 0.22, 1.0)
const _ROW_A        := Color(0.09, 0.09, 0.15, 1.0)
const _ROW_B        := Color(0.12, 0.12, 0.20, 1.0)
const _BTN_SAVE     := Color(0.12, 0.55, 0.28, 1.0)
const _BTN_CLOSE    := Color(0.55, 0.12, 0.12, 1.0)
const _BTN_RESET    := Color(0.30, 0.22, 0.10, 1.0)

# Widget references per modifier row: key → { label_edit, desc_edit, pos_check, enabled_check }
var _rows: Dictionary = {}

var _status_lbl: Label = null

# ─────────────────────────────────────────────────────────────
# Build UI
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 90

	# Dark backdrop
	var bg := ColorRect.new()
	bg.color = _BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Header
	var header := _make_panel(_HEADER_COLOR)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.custom_minimum_size = Vector2(0, 52)
	add_child(header)

	var title := Label.new()
	title.text = "Modifier Editor"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.75, 1.0, 0.85))
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)

	var close_btn := _make_button("X", _BTN_CLOSE)
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -48; close_btn.offset_top = 4
	close_btn.offset_right = -4; close_btn.offset_bottom = 48
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	# Column headers (fixed strip below header)
	var col_header := _make_panel(Color(0.08, 0.10, 0.18, 1.0))
	col_header.set_anchor(SIDE_LEFT,   0.0); col_header.set_anchor(SIDE_RIGHT,  1.0)
	col_header.set_anchor(SIDE_TOP,    0.0); col_header.set_anchor(SIDE_BOTTOM, 0.0)
	col_header.offset_top = 52; col_header.offset_bottom = 84
	add_child(col_header)

	var ch_hbox := HBoxContainer.new()
	ch_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ch_hbox.offset_left = 8; ch_hbox.offset_right = -8
	col_header.add_child(ch_hbox)
	_add_col_header(ch_hbox, "Key",          90)
	_add_col_header(ch_hbox, "Label",       160)
	_add_col_header(ch_hbox, "Description", 0, true)
	_add_col_header(ch_hbox, "Positive",     70)
	_add_col_header(ch_hbox, "Enabled",      70)

	# Scrollable modifier list
	var scroll := ScrollContainer.new()
	scroll.set_anchor(SIDE_LEFT,   0.0); scroll.set_anchor(SIDE_RIGHT,  1.0)
	scroll.set_anchor(SIDE_TOP,    0.0); scroll.set_anchor(SIDE_BOTTOM, 1.0)
	scroll.offset_top = 84; scroll.offset_bottom = -52
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 1)
	scroll.add_child(list_vbox)

	var catalog: Array = DailyDungeonManager.get_modifier_catalog()
	for i: int in range(catalog.size()):
		var entry: Dictionary = catalog[i]
		_build_row(list_vbox, entry, i % 2 == 0)

	# Bottom bar: Save, Reset, status
	var bot := _make_panel(Color(0.08, 0.08, 0.14, 1.0))
	bot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot.custom_minimum_size = Vector2(0, 52)
	add_child(bot)

	var bot_hbox := HBoxContainer.new()
	bot_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bot_hbox.offset_left = 12; bot_hbox.offset_right = -12
	bot_hbox.add_theme_constant_override("separation", 10)
	bot.add_child(bot_hbox)

	var save_btn := _make_button("SAVE ALL", _BTN_SAVE)
	save_btn.custom_minimum_size = Vector2(130, 38)
	save_btn.pressed.connect(_on_save)
	bot_hbox.add_child(save_btn)

	var reset_btn := _make_button("ENABLE ALL", _BTN_RESET)
	reset_btn.custom_minimum_size = Vector2(130, 38)
	reset_btn.pressed.connect(_on_enable_all)
	bot_hbox.add_child(reset_btn)

	var disable_btn := _make_button("DISABLE ALL", _BTN_RESET)
	disable_btn.custom_minimum_size = Vector2(130, 38)
	disable_btn.pressed.connect(_on_disable_all)
	bot_hbox.add_child(disable_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_hbox.add_child(spacer)

	_status_lbl = Label.new()
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	_status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bot_hbox.add_child(_status_lbl)

# ─────────────────────────────────────────────────────────────
# Row builder
# ─────────────────────────────────────────────────────────────

func _build_row(parent: VBoxContainer, entry: Dictionary, alt: bool) -> void:
	var key: String     = str(entry.get("key", ""))
	var label: String   = str(entry.get("label", key))
	var desc: String    = str(entry.get("description", ""))
	var is_pos: bool    = bool(entry.get("positive", true))
	var enabled: bool   = bool(entry.get("enabled", true))

	var row_bg := _make_panel(_ROW_B if alt else _ROW_A)
	row_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_bg.custom_minimum_size = Vector2(0, 38)
	parent.add_child(row_bg)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 8; hbox.offset_right = -8
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	row_bg.add_child(hbox)

	# Key (read-only label)
	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.custom_minimum_size = Vector2(90, 0)
	key_lbl.add_theme_font_size_override("font_size", 11)
	key_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.80))
	key_lbl.clip_contents = true
	hbox.add_child(key_lbl)

	# Label edit
	var label_edit := LineEdit.new()
	label_edit.text = label
	label_edit.custom_minimum_size = Vector2(160, 28)
	label_edit.add_theme_font_size_override("font_size", 12)
	hbox.add_child(label_edit)

	# Description edit (expands)
	var desc_edit := LineEdit.new()
	desc_edit.text = desc
	desc_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_edit.add_theme_font_size_override("font_size", 11)
	hbox.add_child(desc_edit)

	# Positive checkbox
	var pos_check := CheckBox.new()
	pos_check.button_pressed = is_pos
	pos_check.text = ""
	pos_check.custom_minimum_size = Vector2(70, 0)
	pos_check.add_theme_color_override("font_color",
		Color(0.30, 1.0, 0.45) if is_pos else Color(1.0, 0.38, 0.28))
	pos_check.toggled.connect(func(pressed: bool) -> void:
		pos_check.add_theme_color_override("font_color",
			Color(0.30, 1.0, 0.45) if pressed else Color(1.0, 0.38, 0.28)))
	hbox.add_child(pos_check)

	# Enabled checkbox
	var enabled_check := CheckBox.new()
	enabled_check.button_pressed = enabled
	enabled_check.text = ""
	enabled_check.custom_minimum_size = Vector2(70, 0)
	_update_enabled_color(enabled_check, enabled)
	enabled_check.toggled.connect(func(pressed: bool) -> void:
		_update_enabled_color(enabled_check, pressed))
	hbox.add_child(enabled_check)

	_rows[key] = {
		"label_edit":   label_edit,
		"desc_edit":    desc_edit,
		"pos_check":    pos_check,
		"enabled_check": enabled_check,
	}

func _update_enabled_color(cb: CheckBox, enabled: bool) -> void:
	cb.add_theme_color_override("font_color",
		Color(0.30, 1.0, 0.45) if enabled else Color(0.45, 0.45, 0.55))

# ─────────────────────────────────────────────────────────────
# Button handlers
# ─────────────────────────────────────────────────────────────

func _on_save() -> void:
	var catalog: Array = DailyDungeonManager.get_modifier_catalog()
	for entry: Variant in catalog:
		if not entry is Dictionary:
			continue
		var key: String = str(entry.get("key", ""))
		if not _rows.has(key):
			continue
		var row: Dictionary = _rows[key]
		entry["label"]       = (row["label_edit"]   as LineEdit).text.strip_edges()
		entry["description"] = (row["desc_edit"]    as LineEdit).text.strip_edges()
		entry["positive"]    = (row["pos_check"]    as CheckBox).button_pressed
		entry["enabled"]     = (row["enabled_check"] as CheckBox).button_pressed

	# Write back to DailyDungeonManager and persist to JSON
	_save_catalog_to_file(catalog)
	# Reload into DailyDungeonManager so runtime reflects changes
	DailyDungeonManager._modifier_catalog = catalog.duplicate(true)
	DailyDungeonManager._modifier_by_key.clear()
	for entry: Variant in catalog:
		if entry is Dictionary:
			var k: String = str(entry.get("key", ""))
			if k != "":
				DailyDungeonManager._modifier_by_key[k] = entry

	_set_status("Saved %d modifiers." % _rows.size())

func _save_catalog_to_file(catalog: Array) -> void:
	var file := FileAccess.open(DailyDungeonManager.MODIFIER_CATALOG_PATH, FileAccess.WRITE)
	if file == null:
		_set_status("ERROR: could not write to %s" % DailyDungeonManager.MODIFIER_CATALOG_PATH)
		return
	file.store_string(JSON.stringify(catalog, "\t"))
	file.close()

func _on_enable_all() -> void:
	for key: String in _rows:
		var cb: CheckBox = _rows[key]["enabled_check"]
		cb.button_pressed = true
		_update_enabled_color(cb, true)
	_set_status("All modifiers enabled.")

func _on_disable_all() -> void:
	for key: String in _rows:
		var cb: CheckBox = _rows[key]["enabled_check"]
		cb.button_pressed = false
		_update_enabled_color(cb, false)
	_set_status("All modifiers disabled.")

func _set_status(msg: String) -> void:
	if _status_lbl:
		_status_lbl.text = msg

# ─────────────────────────────────────────────────────────────
# Input
# ─────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────

func _add_col_header(parent: HBoxContainer, text: String, min_w: int, expand: bool = false) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.60, 0.70, 0.80))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if min_w > 0:
		lbl.custom_minimum_size = Vector2(min_w, 0)
	if expand:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(lbl)

func _make_panel(color: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	pc.add_theme_stylebox_override("panel", style)
	return pc

func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	var style_hover := style.duplicate() as StyleBoxFlat
	style_hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", style_hover)
	return btn
