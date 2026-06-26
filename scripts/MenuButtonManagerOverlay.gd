extends Control
# MenuButtonManagerOverlay — admin UI to show/hide/disable main-menu buttons and sub-modes.
# Open via Admin Console: manage_menu_buttons

const _BG_COLOR     := Color(0.05, 0.05, 0.10, 0.97)
const _HEADER_COLOR := Color(0.10, 0.12, 0.22, 1.0)
const _ROW_A        := Color(0.09, 0.09, 0.15, 1.0)
const _ROW_B        := Color(0.11, 0.11, 0.18, 1.0)
const _SUB_ROW      := Color(0.07, 0.08, 0.13, 1.0)
const _BTN_SAVE     := Color(0.12, 0.55, 0.28, 1.0)
const _BTN_CLOSE    := Color(0.55, 0.12, 0.12, 1.0)
const _BTN_RESET    := Color(0.30, 0.22, 0.10, 1.0)

var _rows: Dictionary = {}
var _status_lbl: Label = null
var _auto_save: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 100

	var bg := ColorRect.new()
	bg.color = _BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var header := _make_panel(_HEADER_COLOR)
	header.custom_minimum_size = Vector2(0, 56)
	root.add_child(header)

	var header_hbox := HBoxContainer.new()
	header_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header_hbox.offset_left = 12
	header_hbox.offset_right = -12
	header_hbox.add_theme_constant_override("separation", 8)
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(header_hbox)

	var title := Label.new()
	title.text = "Menu Button Manager"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.82, 0.88, 1.0))
	header_hbox.add_child(title)

	var save_btn := _make_button("SAVE", _BTN_SAVE)
	save_btn.custom_minimum_size = Vector2(72, 36)
	save_btn.pressed.connect(_on_save)
	header_hbox.add_child(save_btn)

	var close_btn := _make_button("X", _BTN_CLOSE)
	close_btn.custom_minimum_size = Vector2(40, 36)
	close_btn.pressed.connect(queue_free)
	header_hbox.add_child(close_btn)

	var hint := Label.new()
	hint.text = "Slot 1 = top of the menu stack, 6 = bottom. Fixed = corner icons or trailing buttons. Changes auto-save to res://data/menu_buttons.json."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
	hint.custom_minimum_size = Vector2(0, 32)
	root.add_child(hint)

	var bulk_row := HBoxContainer.new()
	bulk_row.add_theme_constant_override("separation", 8)
	bulk_row.custom_minimum_size = Vector2(0, 40)
	root.add_child(bulk_row)

	for spec: Dictionary in [
		{"text": "SHOW ALL", "cb": _on_show_all},
		{"text": "HIDE ALL", "cb": _on_hide_all},
		{"text": "ENABLE ALL", "cb": _on_enable_all},
		{"text": "DISABLE ALL", "cb": _on_disable_all},
	]:
		var bulk_btn := _make_button(spec["text"], _BTN_RESET)
		bulk_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bulk_btn.custom_minimum_size = Vector2(0, 34)
		bulk_btn.pressed.connect(spec["cb"])
		bulk_row.add_child(bulk_btn)

	var col_header := _make_panel(Color(0.08, 0.10, 0.18, 1.0))
	col_header.custom_minimum_size = Vector2(0, 28)
	root.add_child(col_header)

	var col_hbox := HBoxContainer.new()
	col_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col_hbox.offset_left = 12
	col_hbox.offset_right = -12
	col_hbox.add_theme_constant_override("separation", 8)
	col_header.add_child(col_hbox)
	_add_col_label(col_hbox, "Button", 0, true)
	_add_col_label(col_hbox, "Show", 64)
	_add_col_label(col_hbox, "Enabled", 72)
	_add_col_label(col_hbox, "Slot", 56)
	_add_col_label(col_hbox, "Color", 88)
	_add_col_label(col_hbox, "Key", 140)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(list_vbox)

	var row_index := 0
	for main_key: String in MenuButtonConfig.get_main_keys():
		_build_main_row(list_vbox, main_key, row_index % 2 == 0)
		row_index += 1
		for sub_key: String in MenuButtonConfig.get_sub_keys(main_key):
			_build_sub_row(list_vbox, main_key, sub_key)
			row_index += 1

	var footer := _make_panel(Color(0.08, 0.08, 0.14, 1.0))
	footer.custom_minimum_size = Vector2(0, 36)
	root.add_child(footer)

	_status_lbl = Label.new()
	_status_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status_lbl.offset_left = 14
	_status_lbl.offset_right = -14
	_status_lbl.add_theme_font_size_override("font_size", 12)
	_status_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	_status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_lbl.text = "Ready — toggle Show or Enabled to update the main menu."
	footer.add_child(_status_lbl)

	_auto_save = true


func _build_main_row(parent: VBoxContainer, main_key: String, alt: bool) -> void:
	var entry: Dictionary = MenuButtonConfig.get_config().get(main_key, {})
	var row_bg := _make_panel(_ROW_B if alt else _ROW_A)
	row_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_bg.custom_minimum_size = Vector2(0, 40)
	parent.add_child(row_bg)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 12
	hbox.offset_right = -12
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	row_bg.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = MenuButtonConfig.get_label(main_key)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_lbl)

	var visible_check := _make_toggle_check(bool(entry.get("visible", true)))
	hbox.add_child(visible_check)

	var enabled_check := _make_toggle_check(bool(entry.get("enabled", true)))
	hbox.add_child(enabled_check)

	var slot_control: Control
	if MenuButtonConfig.uses_stack_slot(main_key) or int(entry.get("slot", 0)) > 0:
		var slot_spin := SpinBox.new()
		slot_spin.custom_minimum_size = Vector2(56, 28)
		slot_spin.min_value = 1
		slot_spin.max_value = MenuButtonConfig.SLOT_COUNT
		slot_spin.step = 1
		slot_spin.value = MenuButtonConfig.get_main_slot(main_key)
		slot_spin.value_changed.connect(func(_v: float) -> void: _on_checkbox_changed())
		slot_control = slot_spin
	else:
		var fixed_lbl := Label.new()
		fixed_lbl.text = "Fixed"
		fixed_lbl.custom_minimum_size = Vector2(56, 0)
		fixed_lbl.add_theme_font_size_override("font_size", 11)
		fixed_lbl.add_theme_color_override("font_color", Color(0.45, 0.52, 0.64))
		fixed_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_control = fixed_lbl
	hbox.add_child(slot_control)

	var color_opt := _make_font_color_option(MenuButtonConfig.get_main_font_color_id(main_key))
	hbox.add_child(color_opt)

	var key_lbl := Label.new()
	key_lbl.text = main_key
	key_lbl.custom_minimum_size = Vector2(140, 0)
	key_lbl.add_theme_font_size_override("font_size", 11)
	key_lbl.add_theme_color_override("font_color", Color(0.50, 0.58, 0.72))
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(key_lbl)

	_rows[main_key] = {
		"visible_check": visible_check,
		"enabled_check": enabled_check,
		"slot_spin": slot_control if slot_control is SpinBox else null,
		"color_opt": color_opt,
		"subs": {},
	}


func _build_sub_row(parent: VBoxContainer, main_key: String, sub_key: String) -> void:
	var subs: Dictionary = MenuButtonConfig.get_config().get(main_key, {}).get("subs", {})
	var sub_entry: Dictionary = (subs as Dictionary).get(sub_key, {})

	var row_bg := _make_panel(_SUB_ROW)
	row_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_bg.custom_minimum_size = Vector2(0, 34)
	parent.add_child(row_bg)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 28
	hbox.offset_right = -12
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	row_bg.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = "↳ %s" % MenuButtonConfig.get_label(main_key, sub_key)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.82, 0.86, 0.94))
	hbox.add_child(name_lbl)

	var visible_check := _make_toggle_check(bool(sub_entry.get("visible", true)))
	hbox.add_child(visible_check)

	var enabled_check := _make_toggle_check(bool(sub_entry.get("enabled", true)))
	hbox.add_child(enabled_check)

	var slot_spacer := Label.new()
	slot_spacer.text = "—"
	slot_spacer.custom_minimum_size = Vector2(56, 0)
	slot_spacer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_spacer.add_theme_color_override("font_color", Color(0.35, 0.40, 0.48))
	hbox.add_child(slot_spacer)

	var color_spacer := Label.new()
	color_spacer.text = "—"
	color_spacer.custom_minimum_size = Vector2(88, 0)
	color_spacer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	color_spacer.add_theme_color_override("font_color", Color(0.35, 0.40, 0.48))
	hbox.add_child(color_spacer)

	var key_lbl := Label.new()
	key_lbl.text = "%s.%s" % [main_key, sub_key]
	key_lbl.custom_minimum_size = Vector2(140, 0)
	key_lbl.add_theme_font_size_override("font_size", 10)
	key_lbl.add_theme_color_override("font_color", Color(0.45, 0.52, 0.64))
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(key_lbl)

	if not _rows.has(main_key):
		_rows[main_key] = {"visible_check": null, "enabled_check": null, "subs": {}}
	_rows[main_key]["subs"][sub_key] = {
		"visible_check": visible_check,
		"enabled_check": enabled_check,
	}


func _make_toggle_check(pressed: bool) -> CheckBox:
	var check := CheckBox.new()
	check.custom_minimum_size = Vector2(72, 0)
	check.button_pressed = pressed
	check.toggled.connect(func(_on: bool) -> void: _on_checkbox_changed())
	return check


func _make_font_color_option(selected_id: String) -> OptionButton:
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(88, 28)
	for color_id: String in MenuButtonConfig.FONT_COLOR_IDS:
		opt.add_item(color_id.capitalize())
		opt.set_item_metadata(opt.item_count - 1, color_id)
	for i: int in range(opt.item_count):
		if str(opt.get_item_metadata(i)) == selected_id:
			opt.select(i)
			break
	opt.item_selected.connect(func(_idx: int) -> void: _on_checkbox_changed())
	return opt


func _sync_config_from_ui() -> void:
	for main_key: String in _rows.keys():
		var row: Dictionary = _rows[main_key]
		var visible_check: CheckBox = row.get("visible_check")
		var enabled_check: CheckBox = row.get("enabled_check")
		if visible_check != null:
			MenuButtonConfig.set_main_visible(main_key, visible_check.button_pressed)
		if enabled_check != null:
			MenuButtonConfig.set_main_enabled(main_key, enabled_check.button_pressed)
		var slot_spin: SpinBox = row.get("slot_spin")
		if slot_spin != null:
			MenuButtonConfig.set_main_slot(main_key, int(slot_spin.value))
		var color_opt: OptionButton = row.get("color_opt")
		if color_opt != null and color_opt.selected >= 0:
			MenuButtonConfig.set_main_font_color(
				main_key, str(color_opt.get_item_metadata(color_opt.selected)))
		var subs: Dictionary = row.get("subs", {})
		for sub_key: String in subs.keys():
			var sub_row: Dictionary = subs[sub_key]
			MenuButtonConfig.set_sub_visible(
				main_key, sub_key, sub_row["visible_check"].button_pressed)
			MenuButtonConfig.set_sub_enabled(
				main_key, sub_key, sub_row["enabled_check"].button_pressed)


func _on_checkbox_changed() -> void:
	if not _auto_save:
		return
	_on_save()


func _on_save() -> void:
	_sync_config_from_ui()
	if MenuButtonConfig.save_config():
		_set_status("Saved to %s" % MenuButtonConfig.get_save_path())
	else:
		_set_status("ERROR: could not save to %s" % MenuButtonConfig.get_save_path())


func _set_all_visible(visible: bool) -> void:
	_auto_save = false
	for main_key: String in _rows.keys():
		var row: Dictionary = _rows[main_key]
		if row.get("visible_check") != null:
			row["visible_check"].button_pressed = visible
		for sub_row: Dictionary in row.get("subs", {}).values():
			sub_row["visible_check"].button_pressed = visible
	_auto_save = true
	_on_save()


func _set_all_enabled(enabled: bool) -> void:
	_auto_save = false
	for main_key: String in _rows.keys():
		var row: Dictionary = _rows[main_key]
		if row.get("enabled_check") != null:
			row["enabled_check"].button_pressed = enabled
		for sub_row: Dictionary in row.get("subs", {}).values():
			sub_row["enabled_check"].button_pressed = enabled
	_auto_save = true
	_on_save()


func _on_show_all() -> void:
	_set_all_visible(true)


func _on_hide_all() -> void:
	_set_all_visible(false)


func _on_enable_all() -> void:
	_set_all_enabled(true)


func _on_disable_all() -> void:
	_set_all_enabled(false)


func _set_status(msg: String) -> void:
	if _status_lbl:
		_status_lbl.text = msg


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()


func _add_col_label(parent: HBoxContainer, text: String, min_w: int, expand: bool = false) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.60, 0.70, 0.80))
	if min_w > 0:
		lbl.custom_minimum_size = Vector2(min_w, 0)
	if expand:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(lbl)


func _make_panel(color: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	pc.add_theme_stylebox_override("panel", style)
	return pc


func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	var style_hover := style.duplicate() as StyleBoxFlat
	style_hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", style_hover)
	var style_pressed := style.duplicate() as StyleBoxFlat
	style_pressed.bg_color = color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style)
	return btn
