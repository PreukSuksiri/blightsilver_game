extends Control
## Admin overlay for AI opponent identities (name + illustration + difficulty + personality).
## Opened via admin command: ai_identity_vault

const DIFFICULTIES: Array[String] = ["easy", "normal", "hard"]
const PREVIEW_WIDTH := 180.0
const PREVIEW_HEIGHT := 220.0

var _entries: Array = []
var _selected_idx: int = -1

var _list: ItemList = null
var _id_edit: LineEdit = null
var _name_edit: LineEdit = null
var _birth_name_edit: LineEdit = null
var _illus_edit: LineEdit = null
var _illus_preview: TextureRect = null
var _illus_preview_hint: Label = null
var _diff_opt: OptionButton = null
var _pers_def_opt: OptionButton = null
var _pers_off_opt: OptionButton = null
var _pers_soc_opt: OptionButton = null
var _exclude_checks: Dictionary = {}
## emoji -> {"attack": LineEdit, "avoid": LineEdit}
var _bluff_chat_edits: Dictionary = {}
var _status_lbl: Label = null
var _file_dialog: FileDialog = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 200
	mouse_filter = Control.MOUSE_FILTER_STOP
	AIIdentityVault.reload()
	_entries = AIIdentityVault.get_entries()
	if _entries.is_empty():
		_entries.append(_make_blank_entry("new_identity", "New AI"))
	_build_ui()
	_select_entry(0)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()


func _make_blank_entry(entry_id: String, display_name: String) -> Dictionary:
	return {
		"id": entry_id,
		"name": display_name,
		"birth_name": display_name,
		"illustration": "",
		"difficulty": "easy",
		"exclude_protagonists": [],
		"personality_defensive": "",
		"personality_offensive": "",
		"personality_social": "",
		"bluff_reaction_chats": {},
	}


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.10, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := Label.new()
	header.text = "AI Bot Identity Vault"
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 8.0
	header.offset_bottom = 40.0
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	add_child(header)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(44, 36)
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -52.0
	close_btn.offset_top = 6.0
	close_btn.offset_right = -8.0
	close_btn.pressed.connect(queue_free)
	add_child(close_btn)

	var body := HBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_top = 44.0
	body.offset_bottom = -52.0
	body.offset_left = 12.0
	body.offset_right = -12.0
	body.add_theme_constant_override("separation", 12)
	add_child(body)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(260, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(left)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_list_selected)
	left.add_child(_list)

	var left_btns := HBoxContainer.new()
	left_btns.add_theme_constant_override("separation", 8)
	left.add_child(left_btns)
	var new_btn := Button.new()
	new_btn.text = "New"
	new_btn.pressed.connect(_on_new)
	left_btns.add_child(new_btn)
	var del_btn := Button.new()
	del_btn.text = "Delete"
	del_btn.pressed.connect(_on_delete)
	left_btns.add_child(del_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	scroll.add_child(right)

	_id_edit = LineEdit.new()
	right.add_child(_labeled_row("ID", _id_edit))
	_name_edit = LineEdit.new()
	right.add_child(_labeled_row("Name", _name_edit))
	_birth_name_edit = LineEdit.new()
	right.add_child(_labeled_row("Birth name", _birth_name_edit))

	var illus_row := HBoxContainer.new()
	illus_row.add_theme_constant_override("separation", 8)
	var illus_lbl := Label.new()
	illus_lbl.text = "Illustration"
	illus_lbl.custom_minimum_size.x = 110.0
	illus_row.add_child(illus_lbl)
	_illus_edit = LineEdit.new()
	_illus_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_illus_edit.text_changed.connect(_on_illustration_path_changed)
	illus_row.add_child(_illus_edit)
	var browse_btn := Button.new()
	browse_btn.text = "Browse..."
	browse_btn.pressed.connect(_browse_illustration)
	illus_row.add_child(browse_btn)
	right.add_child(illus_row)
	right.add_child(_make_illustration_preview_row())

	_diff_opt = OptionButton.new()
	for d: String in DIFFICULTIES:
		_diff_opt.add_item(d.capitalize())
		_diff_opt.set_item_metadata(_diff_opt.item_count - 1, d)
	right.add_child(_labeled_row("Difficulty", _diff_opt))

	right.add_child(_section_label("Personality"))
	_pers_def_opt = _make_personality_opt(AIIdentityVault.DEF_PERSONALITY_OPTIONS)
	right.add_child(_labeled_row("Defense", _pers_def_opt))
	_pers_off_opt = _make_personality_opt(AIIdentityVault.OFF_PERSONALITY_OPTIONS)
	right.add_child(_labeled_row("Attack", _pers_off_opt))
	_pers_soc_opt = _make_personality_opt(AIIdentityVault.SOC_PERSONALITY_OPTIONS)
	right.add_child(_labeled_row("Social", _pers_soc_opt))

	var exclude_lbl := Label.new()
	exclude_lbl.text = "Exclude for protagonist"
	exclude_lbl.add_theme_font_size_override("font_size", 13)
	right.add_child(exclude_lbl)

	var exclude_row := HBoxContainer.new()
	exclude_row.add_theme_constant_override("separation", 16)
	right.add_child(exclude_row)
	for protagonist_id: String in ProtagonistVault.get_protagonist_ids():
		var chk := CheckBox.new()
		chk.text = ProtagonistVault.get_display_name(protagonist_id)
		_exclude_checks[protagonist_id] = chk
		exclude_row.add_child(chk)

	right.add_child(_section_label("Bluff reaction chat"))
	var bluff_hint := Label.new()
	bluff_hint.text = "Rolled at AI turn start from visible opponent bluffs (Attack = Interested, Avoid = Avoid)."
	bluff_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bluff_hint.add_theme_font_size_override("font_size", 11)
	bluff_hint.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	right.add_child(bluff_hint)

	_bluff_chat_edits.clear()
	for emoji: String in AIIdentityVault.BLUFF_REACTION_EMOJIS:
		right.add_child(_make_bluff_reaction_row(emoji))

	var bot := HBoxContainer.new()
	bot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_top = -48.0
	bot.offset_left = 12.0
	bot.offset_right = -12.0
	bot.add_theme_constant_override("separation", 12)
	add_child(bot)

	var save_btn := Button.new()
	save_btn.text = "Save Vault"
	save_btn.pressed.connect(_on_save)
	bot.add_child(save_btn)

	_status_lbl = Label.new()
	_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bot.add_child(_status_lbl)

	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_file_dialog.filters = PackedStringArray(["*.png ; PNG Images"])
	_file_dialog.file_selected.connect(func(path: String) -> void:
		_illus_edit.text = path
		_refresh_illustration_preview())
	add_child(_file_dialog)

	_refresh_list()


func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	return lbl


func _make_personality_opt(options: Array[String]) -> OptionButton:
	var opt := OptionButton.new()
	opt.add_item("Random")
	opt.set_item_metadata(0, "")
	for name: String in options:
		opt.add_item(name)
		opt.set_item_metadata(opt.item_count - 1, name)
	return opt


func _make_bluff_reaction_row(emoji: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.text = "%s  reaction chat" % emoji
	title.add_theme_font_size_override("font_size", 12)
	box.add_child(title)

	var attack_edit := LineEdit.new()
	attack_edit.placeholder_text = "Attack (Interested) chat…"
	box.add_child(_labeled_row("Attack", attack_edit))

	var avoid_edit := LineEdit.new()
	avoid_edit.placeholder_text = "Avoid chat…"
	box.add_child(_labeled_row("Avoid", avoid_edit))

	_bluff_chat_edits[emoji] = {"attack": attack_edit, "avoid": avoid_edit}
	return box


func _make_illustration_preview_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var spacer := Control.new()
	spacer.custom_minimum_size.x = 110.0
	row.add_child(spacer)

	var preview_col := VBoxContainer.new()
	preview_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_col.add_theme_constant_override("separation", 6)
	row.add_child(preview_col)

	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(PREVIEW_WIDTH, PREVIEW_HEIGHT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.12, 0.95)
	sb.border_color = Color(0.35, 0.4, 0.48, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 8.0
	preview_panel.add_theme_stylebox_override("panel", sb)
	preview_col.add_child(preview_panel)

	_illus_preview = TextureRect.new()
	_illus_preview.custom_minimum_size = Vector2(PREVIEW_WIDTH - 16.0, PREVIEW_HEIGHT - 16.0)
	_illus_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_illus_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_illus_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.add_child(_illus_preview)

	_illus_preview_hint = Label.new()
	_illus_preview_hint.text = "No illustration selected"
	_illus_preview_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_illus_preview_hint.add_theme_font_size_override("font_size", 12)
	_illus_preview_hint.add_theme_color_override("font_color", Color(0.55, 0.6, 0.68))
	preview_col.add_child(_illus_preview_hint)

	return row


func _on_illustration_path_changed(_new_text: String) -> void:
	_refresh_illustration_preview()


func _refresh_illustration_preview() -> void:
	if _illus_preview == null:
		return
	var path: String = _illus_edit.text.strip_edges() if _illus_edit else ""
	var tex: Texture2D = null
	if path != "" and ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_illus_preview.texture = tex
	if _illus_preview_hint != null:
		if tex != null:
			_illus_preview_hint.text = path.get_file()
		elif path.is_empty():
			_illus_preview_hint.text = "No illustration selected"
		else:
			_illus_preview_hint.text = "Image not found: %s" % path.get_file()


func _labeled_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 110.0
	row.add_child(lbl)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _sync_current_entry() -> void:
	if _selected_idx < 0 or _selected_idx >= _entries.size():
		return
	var entry: Dictionary = _entries[_selected_idx] as Dictionary
	entry["id"] = _id_edit.text.strip_edges() if _id_edit else str(entry.get("id", ""))
	entry["name"] = _name_edit.text.strip_edges() if _name_edit else str(entry.get("name", ""))
	entry["birth_name"] = _birth_name_edit.text.strip_edges() if _birth_name_edit else ""
	entry["illustration"] = _illus_edit.text.strip_edges() if _illus_edit else ""
	if _diff_opt != null and _diff_opt.selected >= 0:
		entry["difficulty"] = str(_diff_opt.get_item_metadata(_diff_opt.selected))
	entry["personality_defensive"] = _personality_value(_pers_def_opt)
	entry["personality_offensive"] = _personality_value(_pers_off_opt)
	entry["personality_social"] = _personality_value(_pers_soc_opt)
	var exclude: Array = []
	for protagonist_id: String in _exclude_checks.keys():
		var chk: CheckBox = _exclude_checks[protagonist_id]
		if chk != null and chk.button_pressed:
			exclude.append(protagonist_id)
	entry["exclude_protagonists"] = exclude
	entry["bluff_reaction_chats"] = _collect_bluff_reaction_chats()
	_entries[_selected_idx] = entry


func _personality_value(opt: OptionButton) -> String:
	if opt == null or opt.selected < 0:
		return ""
	return str(opt.get_item_metadata(opt.selected)).strip_edges()


func _collect_bluff_reaction_chats() -> Dictionary:
	var out: Dictionary = {}
	for emoji: Variant in _bluff_chat_edits.keys():
		var edits: Dictionary = _bluff_chat_edits[emoji] as Dictionary
		var attack_edit: LineEdit = edits.get("attack") as LineEdit
		var avoid_edit: LineEdit = edits.get("avoid") as LineEdit
		var attack := attack_edit.text.strip_edges() if attack_edit else ""
		var avoid := avoid_edit.text.strip_edges() if avoid_edit else ""
		if attack.is_empty() and avoid.is_empty():
			continue
		out[str(emoji)] = {"attack": attack, "avoid": avoid}
	return out


func _select_personality_opt(opt: OptionButton, value: String) -> void:
	if opt == null:
		return
	var needle := value.strip_edges()
	for i: int in range(opt.item_count):
		if str(opt.get_item_metadata(i)) == needle:
			opt.select(i)
			return
	opt.select(0)


func _load_bluff_reaction_chats(entry: Dictionary) -> void:
	var chats_raw: Variant = entry.get("bluff_reaction_chats", {})
	var chats: Dictionary = chats_raw as Dictionary if chats_raw is Dictionary else {}
	for emoji: Variant in _bluff_chat_edits.keys():
		var edits: Dictionary = _bluff_chat_edits[emoji] as Dictionary
		var attack_edit: LineEdit = edits.get("attack") as LineEdit
		var avoid_edit: LineEdit = edits.get("avoid") as LineEdit
		var row_raw: Variant = chats.get(str(emoji), {})
		var row: Dictionary = row_raw as Dictionary if row_raw is Dictionary else {}
		if attack_edit:
			attack_edit.text = str(row.get("attack", ""))
		if avoid_edit:
			avoid_edit.text = str(row.get("avoid", ""))


func _select_entry(idx: int) -> void:
	if idx < 0 or idx >= _entries.size():
		return
	if _selected_idx >= 0:
		_sync_current_entry()
	_selected_idx = idx
	var entry: Dictionary = _entries[idx] as Dictionary
	if _id_edit:
		_id_edit.text = str(entry.get("id", ""))
	if _name_edit:
		_name_edit.text = str(entry.get("name", ""))
	if _birth_name_edit:
		var birth: String = str(entry.get("birth_name", "")).strip_edges()
		_birth_name_edit.text = birth if not birth.is_empty() else AIIdentityVault.default_birth_name_for_entry(entry)
	if _illus_edit:
		_illus_edit.text = str(entry.get("illustration", ""))
	_refresh_illustration_preview()
	var diff: String = str(entry.get("difficulty", "easy")).strip_edges().to_lower()
	if _diff_opt:
		for i: int in range(_diff_opt.item_count):
			if str(_diff_opt.get_item_metadata(i)) == diff:
				_diff_opt.select(i)
				break
	_select_personality_opt(_pers_def_opt, str(entry.get("personality_defensive", "")))
	_select_personality_opt(_pers_off_opt, str(entry.get("personality_offensive", "")))
	_select_personality_opt(_pers_soc_opt, str(entry.get("personality_social", "")))
	var exclude_raw: Variant = entry.get("exclude_protagonists", [])
	var exclude_set: Dictionary = {}
	if exclude_raw is Array:
		for ex: Variant in (exclude_raw as Array):
			exclude_set[ProtagonistVault.normalize_id(str(ex))] = true
	for protagonist_id: String in _exclude_checks.keys():
		var chk: CheckBox = _exclude_checks[protagonist_id]
		if chk != null:
			chk.button_pressed = exclude_set.has(protagonist_id)
	_load_bluff_reaction_chats(entry)
	if _list:
		_list.select(idx)


func _refresh_list() -> void:
	if _list == null:
		return
	var keep := _selected_idx
	_list.clear()
	for e: Variant in _entries:
		if e is Dictionary:
			var ed: Dictionary = e as Dictionary
			_list.add_item("%s  [%s]" % [
				str(ed.get("name", "?")),
				str(ed.get("difficulty", "?")),
			])
	if keep >= 0 and keep < _list.item_count:
		_list.select(keep)


func _on_list_selected(idx: int) -> void:
	_select_entry(idx)


func _on_new() -> void:
	_sync_current_entry()
	var n := _entries.size() + 1
	_entries.append(_make_blank_entry("identity_%d" % n, "AI %d" % n))
	_select_entry(_entries.size() - 1)
	_refresh_list()


func _on_delete() -> void:
	if _selected_idx < 0 or _entries.size() <= 1:
		return
	_entries.remove_at(_selected_idx)
	_selected_idx = mini(_selected_idx, _entries.size() - 1)
	_refresh_list()
	_select_entry(_selected_idx)


func _browse_illustration() -> void:
	if _file_dialog:
		_file_dialog.popup_centered(Vector2i(900, 600))


func _on_save() -> void:
	_sync_current_entry()
	if not AIIdentityVault.save_entries(_entries):
		_set_status("ERROR: cannot write ai_identity_vault.json")
		return
	_refresh_list()
	_set_status("Saved %d identities." % _entries.size())


func _set_status(msg: String) -> void:
	if _status_lbl:
		_status_lbl.text = msg
