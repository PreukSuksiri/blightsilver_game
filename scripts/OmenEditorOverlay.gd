extends Control
class_name OmenEditorOverlay
## Admin overlay for editing data/omens.json. Open via admin command: omen_editor

const _BG_COLOR := Color(0.05, 0.05, 0.10, 0.97)
const _HEADER_COLOR := Color(0.10, 0.12, 0.22, 1.0)
const _PANEL_A := Color(0.09, 0.09, 0.15, 1.0)
const _PANEL_B := Color(0.12, 0.12, 0.20, 1.0)
const _BTN_SAVE := Color(0.12, 0.55, 0.28, 1.0)
const _BTN_CLOSE := Color(0.55, 0.12, 0.12, 1.0)
const _BTN_ACTION := Color(0.18, 0.22, 0.38, 1.0)
const _RARITIES: Array = ["common", "uncommon", "rare", "epic"]
const _ANOINT_TYPES: Array = ["", "unit", "trap", "tech"]
const _ANOINT_LABELS: Array = ["(none)", "Unit", "Trap", "Tech"]
const _POSITIVE_LABELS: Array = ["true", "false", "null"]

var _omens: Array = []
var _selected_group: String = "All"
var _selected_id: String = ""
var _dirty: bool = false

var _group_vbox: VBoxContainer = null
var _omen_list: ItemList = null
var _status_lbl: Label = null
var _fields_root: VBoxContainer = null

var _id_edit: LineEdit = null
var _label_edit: LineEdit = null
var _groups_edit: LineEdit = null
var _desc_edit: TextEdit = null
var _rarity_opt: OptionButton = null
var _illus_edit: LineEdit = null
var _weight_edit: LineEdit = null
var _positive_opt: OptionButton = null
var _implemented_check: CheckBox = null
var _demo_check: CheckBox = null
var _stackable_check: CheckBox = null
var _anoint_type_opt: OptionButton = null
var _anoint_filter_edit: LineEdit = null
var _effects_edit: TextEdit = null

var _new_group_edit: LineEdit = null
var _rename_group_edit: LineEdit = null
## Groups created in-editor that may not yet have member omens.
var _extra_groups: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	OmenDatabase.reload()
	_omens = OmenDatabase.get_all_omens()
	_build_ui()
	_refresh_groups()
	_refresh_omen_list()
	if not _filtered_omens().is_empty():
		_select_omen_by_index(0)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_request_close()
		get_viewport().set_input_as_handled()


func _request_close() -> void:
	if not _dirty:
		queue_free()
		return
	GameDialog.confirmation_overlay(
		self, "Unsaved Changes",
		"Close the Omen Editor without saving?",
		"Discard & Close", "Keep Editing",
		func() -> void: queue_free())


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = _BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := _make_panel(_HEADER_COLOR)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 52.0
	add_child(header)

	var title := Label.new()
	title.text = "Omen Editor"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.75, 1.0, 0.85))
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)

	var close_btn := _make_button("X", _BTN_CLOSE)
	close_btn.custom_minimum_size = Vector2(44.0, 44.0)
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -48.0
	close_btn.offset_top = 4.0
	close_btn.offset_right = -4.0
	close_btn.offset_bottom = 48.0
	close_btn.pressed.connect(_request_close)
	header.add_child(close_btn)

	var body := HBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_top = 52.0
	body.offset_bottom = -52.0
	body.add_theme_constant_override("separation", 0)
	add_child(body)

	_build_group_panel(body)
	_build_list_panel(body)
	_build_edit_panel(body)

	var bot := _make_panel(Color(0.08, 0.08, 0.14, 1.0))
	bot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_top = -52.0
	bot.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bot)

	var bot_hbox := HBoxContainer.new()
	bot_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bot_hbox.offset_left = 12.0
	bot_hbox.offset_right = -12.0
	bot_hbox.add_theme_constant_override("separation", 8)
	bot_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bot.add_child(bot_hbox)

	var new_btn := _make_button("New", _BTN_ACTION)
	new_btn.custom_minimum_size = Vector2(90.0, 36.0)
	new_btn.pressed.connect(_on_new)
	bot_hbox.add_child(new_btn)
	var dup_btn := _make_button("Duplicate", _BTN_ACTION)
	dup_btn.custom_minimum_size = Vector2(90.0, 36.0)
	dup_btn.pressed.connect(_on_duplicate)
	bot_hbox.add_child(dup_btn)
	var del_btn := _make_button("Delete", _BTN_ACTION)
	del_btn.custom_minimum_size = Vector2(90.0, 36.0)
	del_btn.pressed.connect(_on_delete)
	bot_hbox.add_child(del_btn)
	var save_btn := _make_button("Save", _BTN_SAVE)
	save_btn.custom_minimum_size = Vector2(90.0, 36.0)
	save_btn.pressed.connect(_on_save)
	bot_hbox.add_child(save_btn)
	var close_bot_btn := _make_button("Close", _BTN_ACTION)
	close_bot_btn.custom_minimum_size = Vector2(90.0, 36.0)
	close_bot_btn.pressed.connect(_request_close)
	bot_hbox.add_child(close_bot_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_hbox.add_child(spacer)

	_status_lbl = Label.new()
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	_status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bot_hbox.add_child(_status_lbl)


func _build_group_panel(parent: HBoxContainer) -> void:
	var panel := _make_panel(_PANEL_A)
	panel.custom_minimum_size = Vector2(180.0, 0.0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8.0
	vbox.offset_right = -8.0
	vbox.offset_top = 8.0
	vbox.offset_bottom = -8.0
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "Groups"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(0.65, 0.78, 0.92))
	vbox.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_group_vbox = VBoxContainer.new()
	_group_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_group_vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(_group_vbox)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0.0, 1.0)
	sep.color = Color(0.35, 0.45, 0.65, 0.35)
	vbox.add_child(sep)

	var create_row := HBoxContainer.new()
	create_row.add_theme_constant_override("separation", 4)
	vbox.add_child(create_row)
	_new_group_edit = LineEdit.new()
	_new_group_edit.placeholder_text = "New group"
	_new_group_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_row.add_child(_new_group_edit)
	var create_btn := _make_button("+", _BTN_ACTION)
	create_btn.pressed.connect(_on_create_group)
	create_row.add_child(create_btn)

	var rename_row := HBoxContainer.new()
	rename_row.add_theme_constant_override("separation", 4)
	vbox.add_child(rename_row)
	_rename_group_edit = LineEdit.new()
	_rename_group_edit.placeholder_text = "Rename selected"
	_rename_group_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rename_row.add_child(_rename_group_edit)
	var rename_btn := _make_button("Rename", _BTN_ACTION)
	rename_btn.pressed.connect(_on_rename_group)
	rename_row.add_child(rename_btn)

	var del_grp_btn := _make_button("Delete Group", _BTN_CLOSE)
	del_grp_btn.pressed.connect(_on_delete_group)
	vbox.add_child(del_grp_btn)


func _build_list_panel(parent: HBoxContainer) -> void:
	var panel := _make_panel(_PANEL_B)
	panel.custom_minimum_size = Vector2(320.0, 0.0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8.0
	vbox.offset_right = -8.0
	vbox.offset_top = 8.0
	vbox.offset_bottom = -8.0
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "Omens"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(0.65, 0.78, 0.92))
	vbox.add_child(hdr)

	var col_hdr := Label.new()
	col_hdr.text = "id · label · rarity · impl · demo"
	col_hdr.add_theme_font_size_override("font_size", 10)
	col_hdr.add_theme_color_override("font_color", Color(0.50, 0.58, 0.68))
	vbox.add_child(col_hdr)

	_omen_list = ItemList.new()
	_omen_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_omen_list.item_selected.connect(_on_omen_list_selected)
	vbox.add_child(_omen_list)


func _build_edit_panel(parent: HBoxContainer) -> void:
	var panel := _make_panel(_PANEL_A)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(scroll)

	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	scroll.add_child(pad)

	_fields_root = VBoxContainer.new()
	_fields_root.add_theme_constant_override("separation", 6)
	pad.add_child(_fields_root)

	var edit_hdr := Label.new()
	edit_hdr.text = "Edit Selected"
	edit_hdr.add_theme_font_size_override("font_size", 14)
	edit_hdr.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0))
	_fields_root.add_child(edit_hdr)

	_id_edit = _add_line_field("ID", "")
	_label_edit = _add_line_field("Label", "")
	_groups_edit = _add_line_field("Groups (comma-separated)", "")
	_desc_edit = _add_text_field("Description", 3)
	_rarity_opt = _add_option_field("Rarity", _RARITIES, 0)
	_illus_edit = _add_line_field("Illustration path", "")
	_weight_edit = _add_line_field("Weight (optional)", "")
	_positive_opt = _add_option_field("Positive", _POSITIVE_LABELS, 0)
	_implemented_check = _add_check_field("Implemented", false)
	_demo_check = _add_check_field("Include in demo", true)
	_stackable_check = _add_check_field("Stackable", true)
	_anoint_type_opt = _add_option_field("Anoint card type", _ANOINT_LABELS, 0)
	_anoint_filter_edit = _add_line_field("Anoint filter (JSON)", "{}")
	_effects_edit = _add_text_field("Effects (JSON array)", 8)

	for ctrl: Control in [
		_id_edit, _label_edit, _groups_edit, _desc_edit, _rarity_opt,
		_illus_edit, _weight_edit, _positive_opt, _implemented_check,
		_demo_check, _stackable_check, _anoint_type_opt, _anoint_filter_edit,
		_effects_edit,
	]:
		_connect_dirty(ctrl)


func _connect_dirty(ctrl: Control) -> void:
	if ctrl is LineEdit:
		(ctrl as LineEdit).text_changed.connect(func(_t: String) -> void: _dirty = true)
	elif ctrl is TextEdit:
		(ctrl as TextEdit).text_changed.connect(func() -> void: _dirty = true)
	elif ctrl is OptionButton:
		(ctrl as OptionButton).item_selected.connect(func(_i: int) -> void: _dirty = true)
	elif ctrl is CheckBox:
		(ctrl as CheckBox).toggled.connect(func(_p: bool) -> void: _dirty = true)


func _group_counts() -> Dictionary:
	var counts: Dictionary = {"All": _omens.size()}
	for omen: Variant in _omens:
		if not omen is Dictionary:
			continue
		var groups: Array = (omen as Dictionary).get("groups", []) as Array
		if groups.is_empty():
			counts["ungrouped"] = int(counts.get("ungrouped", 0)) + 1
			continue
		for group_name: Variant in groups:
			var g: String = str(group_name).strip_edges()
			if g.is_empty():
				g = "ungrouped"
			counts[g] = int(counts.get(g, 0)) + 1
	for extra: Variant in _extra_groups:
		var eg: String = str(extra).strip_edges()
		if eg.is_empty() or eg == "All":
			continue
		if not counts.has(eg):
			counts[eg] = 0
	return counts


func _refresh_groups() -> void:
	if _group_vbox == null:
		return
	for child: Node in _group_vbox.get_children():
		child.queue_free()
	var counts: Dictionary = _group_counts()
	var names: Array = counts.keys()
	names.sort()
	for group_name: Variant in names:
		var g: String = str(group_name)
		var count: int = int(counts[g])
		var btn := Button.new()
		btn.text = "%s (%d)" % [g, count]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.flat = g != _selected_group
		if g == _selected_group:
			btn.add_theme_color_override("font_color", Color(0.75, 1.0, 0.85))
		var captured: String = g
		btn.pressed.connect(func() -> void:
			_commit_current_fields()
			_selected_group = captured
			_refresh_groups()
			_refresh_omen_list())
		_group_vbox.add_child(btn)


func _filtered_omens() -> Array:
	if _selected_group == "All":
		return _omens.duplicate()
	var out: Array = []
	for omen: Variant in _omens:
		if not omen is Dictionary:
			continue
		var o: Dictionary = omen as Dictionary
		var groups: Array = o.get("groups", []) as Array
		if groups.is_empty() and _selected_group == "ungrouped":
			out.append(o)
			continue
		for group_name: Variant in groups:
			var g: String = str(group_name).strip_edges()
			if g.is_empty():
				g = "ungrouped"
			if g == _selected_group:
				out.append(o)
				break
	return out


func _refresh_omen_list() -> void:
	if _omen_list == null:
		return
	_omen_list.clear()
	var filtered: Array = _filtered_omens()
	for omen: Variant in filtered:
		if not omen is Dictionary:
			continue
		var o: Dictionary = omen as Dictionary
		var id: String = str(o.get("id", ""))
		var label: String = str(o.get("label", id))
		var rarity: String = str(o.get("rarity", "common"))
		var impl: String = "Y" if bool(o.get("implemented", false)) else "N"
		var demo: String = "Y" if bool(o.get("include_in_demo", true)) else "N"
		var idx: int = _omen_list.add_item("%s · %s · %s · %s · %s" % [id, label, rarity, impl, demo])
		_omen_list.set_item_metadata(idx, id)

	if filtered.is_empty():
		_selected_id = ""
		return

	var select_idx: int = 0
	if not _selected_id.is_empty():
		for i: int in range(_omen_list.item_count):
			if str(_omen_list.get_item_metadata(i)) == _selected_id:
				select_idx = i
				break
	_omen_list.select(select_idx)
	_on_omen_list_selected(select_idx)


func _on_omen_list_selected(index: int) -> void:
	if _omen_list == null or index < 0 or index >= _omen_list.item_count:
		return
	var new_id: String = str(_omen_list.get_item_metadata(index))
	if not _selected_id.is_empty() and _selected_id != new_id:
		_commit_current_fields()
	_selected_id = new_id
	_load_omen_into_fields(_find_omen_by_id(_selected_id))


func _select_omen_by_index(index: int) -> void:
	if _omen_list == null:
		return
	if index < 0 or index >= _omen_list.item_count:
		return
	_omen_list.select(index)
	_on_omen_list_selected(index)


func _find_omen_by_id(id: String) -> Dictionary:
	for omen: Variant in _omens:
		if omen is Dictionary and str((omen as Dictionary).get("id", "")) == id:
			return omen as Dictionary
	return {}


func _load_omen_into_fields(omen: Dictionary) -> void:
	if omen.is_empty():
		return
	_id_edit.text = str(omen.get("id", ""))
	_label_edit.text = str(omen.get("label", ""))
	var groups: Array = omen.get("groups", []) as Array
	var group_parts: PackedStringArray = PackedStringArray()
	for g: Variant in groups:
		group_parts.append(str(g))
	_groups_edit.text = ", ".join(group_parts)
	_desc_edit.text = str(omen.get("description", ""))
	_set_option_by_value(_rarity_opt, _RARITIES, str(omen.get("rarity", "common")))
	_illus_edit.text = str(omen.get("illustration", ""))
	if omen.has("weight"):
		_weight_edit.text = str(omen.get("weight", ""))
	else:
		_weight_edit.text = ""
	var positive: Variant = omen.get("positive", true)
	if positive == null:
		_positive_opt.select(2)
	elif bool(positive):
		_positive_opt.select(0)
	else:
		_positive_opt.select(1)
	_implemented_check.button_pressed = bool(omen.get("implemented", false))
	_demo_check.button_pressed = bool(omen.get("include_in_demo", true))
	_stackable_check.button_pressed = bool(omen.get("stackable", true))
	for i: int in range(_ANOINT_TYPES.size()):
		if str(_ANOINT_TYPES[i]) == str(omen.get("anoint_card_type", "")):
			_anoint_type_opt.select(i)
			break
	_anoint_filter_edit.text = JSON.stringify(omen.get("anoint_filter", {}))
	_effects_edit.text = JSON.stringify(omen.get("effects", []), "\t")


func _apply_fields_to_omen(omen: Dictionary) -> Dictionary:
	var updated: Dictionary = omen.duplicate(true)
	var new_id: String = _id_edit.text.strip_edges()
	updated["id"] = new_id
	updated["label"] = _label_edit.text.strip_edges()
	updated["groups"] = _parse_groups_csv(_groups_edit.text)
	updated["description"] = _desc_edit.text.strip_edges()
	updated["rarity"] = _RARITIES[_rarity_opt.selected]
	updated["illustration"] = _illus_edit.text.strip_edges()
	var weight_text: String = _weight_edit.text.strip_edges()
	if weight_text.is_empty():
		updated.erase("weight")
	else:
		updated["weight"] = int(weight_text)
	match _positive_opt.selected:
		0:
			updated["positive"] = true
		1:
			updated["positive"] = false
		_:
			updated["positive"] = null
	updated["implemented"] = _implemented_check.button_pressed
	updated["include_in_demo"] = _demo_check.button_pressed
	updated["stackable"] = _stackable_check.button_pressed
	updated["anoint_card_type"] = _ANOINT_TYPES[_anoint_type_opt.selected]
	var filt_parsed: Variant = JSON.parse_string(_anoint_filter_edit.text.strip_edges())
	updated["anoint_filter"] = filt_parsed if filt_parsed is Dictionary else {}
	var effects_parsed: Variant = JSON.parse_string(_effects_edit.text.strip_edges())
	updated["effects"] = effects_parsed if effects_parsed is Array else []
	return updated


func _parse_groups_csv(csv: String) -> Array:
	var groups: Array = []
	for part: String in csv.split(","):
		var g: String = part.strip_edges()
		if not g.is_empty():
			groups.append(g)
	if groups.is_empty():
		groups.append("ungrouped")
	return groups


func _commit_current_fields() -> void:
	if _selected_id.is_empty():
		return
	for i: int in range(_omens.size()):
		if not _omens[i] is Dictionary:
			continue
		if str((_omens[i] as Dictionary).get("id", "")) != _selected_id:
			continue
		var updated: Dictionary = _apply_fields_to_omen(_omens[i] as Dictionary)
		_omens[i] = updated
		var new_id: String = str(updated.get("id", ""))
		if new_id != _selected_id:
			_selected_id = new_id
		return


func _on_new() -> void:
	_commit_current_fields()
	var base_id: String = "new_omen"
	var id: String = base_id
	var suffix: int = 1
	while not _find_omen_by_id(id).is_empty():
		id = "%s_%d" % [base_id, suffix]
		suffix += 1
	var group_for_new: String = "ungrouped"
	if _selected_group != "All" and not _selected_group.is_empty():
		group_for_new = _selected_group
	var entry: Dictionary = {
		"id": id,
		"label": "New Omen",
		"groups": [group_for_new],
		"description": "",
		"rarity": "common",
		"illustration": "",
		"effects": [],
		"positive": true,
		"implemented": false,
		"include_in_demo": true,
		"stackable": true,
		"anoint_card_type": "",
		"anoint_filter": {},
	}
	_omens.append(entry)
	_selected_id = id
	_dirty = true
	_refresh_groups()
	_refresh_omen_list()
	_set_status("Created %s in group '%s'" % [id, group_for_new])


func _on_duplicate() -> void:
	if _selected_id.is_empty():
		return
	_commit_current_fields()
	var source: Dictionary = _find_omen_by_id(_selected_id)
	if source.is_empty():
		return
	var copy: Dictionary = source.duplicate(true)
	var base_id: String = "%s_copy" % str(source.get("id", "omen"))
	var id: String = base_id
	var suffix: int = 2
	while _find_omen_by_id(id) != {}:
		id = "%s%d" % [base_id, suffix]
		suffix += 1
	copy["id"] = id
	copy["label"] = "%s (Copy)" % str(source.get("label", id))
	_omens.append(copy)
	_selected_id = id
	_dirty = true
	_refresh_groups()
	_refresh_omen_list()
	_set_status("Duplicated as %s" % id)


func _on_delete() -> void:
	if _selected_id.is_empty():
		return
	var id: String = _selected_id
	GameDialog.confirmation_overlay(
		self, "Delete Omen",
		"Delete omen '%s'?" % id,
		"Delete", "Cancel",
		func() -> void:
			_commit_current_fields()
			for i: int in range(_omens.size() - 1, -1, -1):
				if _omens[i] is Dictionary \
						and str((_omens[i] as Dictionary).get("id", "")) == id:
					_omens.remove_at(i)
					break
			_selected_id = ""
			_dirty = true
			_refresh_groups()
			_refresh_omen_list()
			_set_status("Deleted %s" % id))


func _on_save() -> void:
	if not _selected_id.is_empty():
		_commit_current_fields()
	if not BuildConfig.can_write_shipped_data():
		_set_status("ERROR: cannot write res:// in exported builds")
		return
	var file := FileAccess.open(OmenDatabase.OMENS_PATH, FileAccess.WRITE)
	if file == null:
		_set_status("ERROR: could not write %s" % OmenDatabase.OMENS_PATH)
		return
	file.store_string(JSON.stringify({"omens": _omens}, "\t"))
	file.close()
	OmenDatabase.reload()
	_dirty = false
	_set_status("Saved %d omens." % _omens.size())


func _on_create_group() -> void:
	var group_name: String = _new_group_edit.text.strip_edges()
	if group_name.is_empty() or group_name == "All":
		_set_status("Enter a group name first.")
		return
	if group_name not in _extra_groups:
		_extra_groups.append(group_name)
	_new_group_edit.text = ""
	_selected_group = group_name
	_refresh_groups()
	_refresh_omen_list()
	_set_status("Group '%s' ready — assign omens via Groups field or New." % group_name)


func _on_rename_group() -> void:
	if _selected_group == "All" or _selected_group.is_empty():
		_set_status("Select a specific group to rename.")
		return
	var new_name: String = _rename_group_edit.text.strip_edges()
	if new_name.is_empty():
		_set_status("Enter a new group name in the Rename field.")
		return
	if new_name == "All":
		_set_status("Cannot rename to 'All'.")
		return
	if new_name == _selected_group:
		_set_status("Name is unchanged.")
		return
	var old_name: String = _selected_group
	var renamed_count: int = 0
	for omen: Variant in _omens:
		if not omen is Dictionary:
			continue
		var o: Dictionary = omen as Dictionary
		var groups: Array = []
		var raw_groups: Variant = o.get("groups", [])
		if raw_groups is Array:
			groups = (raw_groups as Array).duplicate()
		var changed: bool = false
		for i: int in range(groups.size()):
			if str(groups[i]).strip_edges() == old_name:
				groups[i] = new_name
				changed = true
		if groups.is_empty():
			groups = [new_name]
			changed = true
		if changed:
			o["groups"] = groups
			renamed_count += 1
	var extra_idx: int = _extra_groups.find(old_name)
	if extra_idx >= 0:
		_extra_groups[extra_idx] = new_name
	elif new_name not in _extra_groups and renamed_count == 0:
		_extra_groups.append(new_name)
	_selected_group = new_name
	_rename_group_edit.text = ""
	_dirty = true
	_refresh_groups()
	_refresh_omen_list()
	_set_status("Renamed '%s' → '%s' (%d omens)." % [old_name, new_name, renamed_count])


func _on_delete_group() -> void:
	if _selected_group == "All":
		_set_status("Select a specific group to delete.")
		return
	var group_name: String = _selected_group
	GameDialog.confirmation_overlay(
		self, "Delete Group",
		"Remove group '%s' from all omens?" % group_name,
		"Delete", "Cancel",
		func() -> void:
			for omen: Variant in _omens:
				if not omen is Dictionary:
					continue
				var o: Dictionary = omen as Dictionary
				var groups: Array = o.get("groups", []) as Array
				var kept: Array = []
				for g: Variant in groups:
					if str(g).strip_edges() != group_name:
						kept.append(g)
				if kept.is_empty():
					kept = ["ungrouped"]
				o["groups"] = kept
			var extra_idx: int = _extra_groups.find(group_name)
			if extra_idx >= 0:
				_extra_groups.remove_at(extra_idx)
			_selected_group = "All"
			_dirty = true
			_refresh_groups()
			_refresh_omen_list()
			_set_status("Deleted group '%s'." % group_name))


func _set_status(msg: String) -> void:
	if _status_lbl:
		_status_lbl.text = msg


func _add_line_field(label_text: String, default_text: String) -> LineEdit:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_fields_root.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(160.0, 0.0)
	lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(lbl)
	var edit := LineEdit.new()
	edit.text = default_text
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.add_theme_font_size_override("font_size", 12)
	row.add_child(edit)
	return edit


func _add_text_field(label_text: String, lines: int) -> TextEdit:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 12)
	_fields_root.add_child(lbl)
	var edit := TextEdit.new()
	edit.custom_minimum_size = Vector2(0.0, float(lines) * 22.0)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.add_theme_font_size_override("font_size", 11)
	_fields_root.add_child(edit)
	return edit


func _add_option_field(label_text: String, options: Array, selected: int) -> OptionButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_fields_root.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(160.0, 0.0)
	lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(lbl)
	var opt := OptionButton.new()
	for item: Variant in options:
		opt.add_item(str(item))
	opt.select(clampi(selected, 0, maxi(0, opt.item_count - 1)))
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(opt)
	return opt


func _add_check_field(label_text: String, pressed: bool) -> CheckBox:
	var cb := CheckBox.new()
	cb.text = label_text
	cb.button_pressed = pressed
	cb.add_theme_font_size_override("font_size", 12)
	_fields_root.add_child(cb)
	return cb


func _set_option_by_value(opt: OptionButton, values: Array, value: String) -> void:
	for i: int in range(values.size()):
		if str(values[i]) == value:
			opt.select(i)
			return
	opt.select(0)


func _add_col_header(parent: HBoxContainer, text: String, min_w: int, expand: bool = false) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.60, 0.70, 0.80))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if min_w > 0:
		lbl.custom_minimum_size = Vector2(float(min_w), 0.0)
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
	btn.add_theme_font_size_override("font_size", 13)
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
	return btn
