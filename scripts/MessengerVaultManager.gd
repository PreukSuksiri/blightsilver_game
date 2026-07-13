extends Control
class_name MessengerVaultManager
## Admin editor for messenger conversations (data/messenger_vault.json).
## Opened via admin command: messenger_vault
##
## The author crafts read-only chat conversations (shown in VN via the
## "show_messenger" beat key): participants (max 5) with name + avatar,
## and messages with sender, time, text (unicode emoji supported) and/or image.
## Built-in emoticon picker (😀 button) on participant names and message text.

const MAX_PARTICIPANTS := 5
const REVEAL_MODES := ["all", "tap"]

var _conversations: Array = []
var _selected_idx: int = -1
var _dirty: bool = false
var _loading: bool = false

var _list: ItemList = null
var _id_edit: LineEdit = null
var _title_edit: LineEdit = null
var _reveal_opt: OptionButton = null
var _right_side_opt: OptionButton = null
var _participants_vbox: VBoxContainer = null
var _add_participant_btn: Button = null
var _messages_vbox: VBoxContainer = null
var _status_lbl: Label = null
var _fields_root: VBoxContainer = null
var _avatar_dialog: FileDialog = null
var _image_dialog: FileDialog = null
var _avatar_target: LineEdit = null
var _image_target: LineEdit = null

# Row bookkeeping: arrays of dictionaries holding each row's controls.
var _participant_rows: Array = []
var _message_rows: Array = []


static func open(parent: Node) -> void:
	var overlay: Control = load("res://scripts/MessengerVaultManager.gd").new()
	overlay.name = "MessengerVaultManagerOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)


func _ready() -> void:
	MessengerVault.reload()
	_conversations = MessengerVault.get_conversations()
	_build_ui()
	_refresh_list()
	if not _conversations.is_empty():
		_select_conversation(0)


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
		"Close the Messenger Vault without saving?",
		"Discard & Close", "Keep Editing",
		func() -> void: queue_free())


# ─────────────────────────────────────────────────────────────
# UI construction
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.10, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := Label.new()
	header.text = "Messenger Vault  —  read-only chat conversations for VN (show_messenger)"
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 8.0
	header.offset_bottom = 40.0
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	add_child(header)

	var top_btns := HBoxContainer.new()
	top_btns.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top_btns.offset_left = -420.0
	top_btns.offset_top = 6.0
	top_btns.offset_right = -8.0
	top_btns.add_theme_constant_override("separation", 8)
	add_child(top_btns)

	var reload_btn := Button.new()
	reload_btn.text = "Reload"
	reload_btn.pressed.connect(_on_reload)
	top_btns.add_child(reload_btn)

	var preview_btn := Button.new()
	preview_btn.text = "Preview"
	preview_btn.pressed.connect(_on_preview)
	top_btns.add_child(preview_btn)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save)
	top_btns.add_child(save_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(_request_close)
	top_btns.add_child(close_btn)

	var body := HBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_top = 44.0
	body.offset_bottom = -40.0
	body.offset_left = 12.0
	body.offset_right = -12.0
	body.add_theme_constant_override("separation", 12)
	add_child(body)

	# ── Left: conversation list + actions ──
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(260, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_list_selected)
	left.add_child(_list)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	left.add_child(row1)
	_add_action_btn(row1, "New", _on_new)
	_add_action_btn(row1, "Duplicate", _on_duplicate)
	_add_action_btn(row1, "Delete", _on_delete)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	left.add_child(row2)
	_add_action_btn(row2, "Copy JSON", _on_copy_json)
	_add_action_btn(row2, "Paste JSON", _on_paste_json)

	# ── Right: conversation editor ──
	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right_scroll)

	_fields_root = VBoxContainer.new()
	_fields_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fields_root.add_theme_constant_override("separation", 10)
	right_scroll.add_child(_fields_root)

	_id_edit = _labeled_line_edit(_fields_root, "ID (used by show_messenger)")
	_id_edit.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	_title_edit = _labeled_line_edit(_fields_root, "Title (chat header)", true)
	_title_edit.text_changed.connect(func(_t: String) -> void: _mark_dirty())

	var reveal_row := HBoxContainer.new()
	reveal_row.add_theme_constant_override("separation", 8)
	_fields_root.add_child(reveal_row)
	var reveal_lbl := Label.new()
	reveal_lbl.text = "Reveal mode:"
	reveal_row.add_child(reveal_lbl)
	_reveal_opt = OptionButton.new()
	_reveal_opt.add_item("All at once (scroll freely)")
	_reveal_opt.add_item("Tap to reveal (one by one)")
	_reveal_opt.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	reveal_row.add_child(_reveal_opt)

	var rs_row := HBoxContainer.new()
	rs_row.add_theme_constant_override("separation", 8)
	_fields_root.add_child(rs_row)
	var rs_lbl := Label.new()
	rs_lbl.text = "Right side (phone owner):"
	rs_row.add_child(rs_lbl)
	_right_side_opt = OptionButton.new()
	_right_side_opt.custom_minimum_size = Vector2(200, 0)
	_right_side_opt.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	rs_row.add_child(_right_side_opt)

	_section_label(_fields_root, "PARTICIPANTS  (max %d — name + profile picture; 😀 = emoticon)" % MAX_PARTICIPANTS)
	_participants_vbox = VBoxContainer.new()
	_participants_vbox.add_theme_constant_override("separation", 6)
	_fields_root.add_child(_participants_vbox)
	_add_participant_btn = Button.new()
	_add_participant_btn.text = "+ Add Participant"
	_add_participant_btn.pressed.connect(func() -> void:
		_add_participant_row("", "")
		_mark_dirty()
		_refresh_participant_dependent_ui())
	_fields_root.add_child(_add_participant_btn)

	_section_label(_fields_root, "MESSAGES  (text with emoji, image, or both — use 😀 to insert)")
	_messages_vbox = VBoxContainer.new()
	_messages_vbox.add_theme_constant_override("separation", 6)
	_fields_root.add_child(_messages_vbox)
	var add_msg_btn := Button.new()
	add_msg_btn.text = "+ Add Message"
	add_msg_btn.pressed.connect(func() -> void:
		_add_message_row({})
		_mark_dirty())
	_fields_root.add_child(add_msg_btn)

	_status_lbl = Label.new()
	_status_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status_lbl.offset_top = -32.0
	_status_lbl.offset_left = 12.0
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	add_child(_status_lbl)

	_avatar_dialog = _make_texture_dialog(func(path: String) -> void:
		if _avatar_target != null:
			_avatar_target.text = path
			_avatar_target.text_changed.emit(path))
	_image_dialog = _make_texture_dialog(func(path: String) -> void:
		if _image_target != null:
			_image_target.text = path
			_image_target.text_changed.emit(path))


func _make_texture_dialog(on_pick: Callable) -> FileDialog:
	var dlg := FileDialog.new()
	dlg.access = FileDialog.ACCESS_RESOURCES
	dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dlg.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Images"])
	dlg.current_dir = "res://assets/textures"
	dlg.size = Vector2(900, 600)
	dlg.file_selected.connect(on_pick)
	add_child(dlg)
	return dlg


func _add_action_btn(parent: Control, text: String, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(cb)
	parent.add_child(btn)


func _labeled_line_edit(parent: Control, label: String, with_emoji: bool = false) -> LineEdit:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label + ":"
	lbl.custom_minimum_size = Vector2(220, 0)
	row.add_child(lbl)
	var le := LineEdit.new()
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(le)
	if with_emoji:
		row.add_child(MessengerEmojiPicker.make_button(le, self))
	return le


func _section_label(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
	parent.add_child(lbl)


# ─────────────────────────────────────────────────────────────
# Participant rows
# ─────────────────────────────────────────────────────────────
func _add_participant_row(pname: String, avatar: String) -> void:
	if _participant_rows.size() >= MAX_PARTICIPANTS:
		_set_status("Max %d participants." % MAX_PARTICIPANTS)
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_participants_vbox.add_child(row)

	var name_le := LineEdit.new()
	name_le.placeholder_text = "Name"
	name_le.text = pname
	name_le.custom_minimum_size = Vector2(160, 0)
	name_le.text_changed.connect(func(_t: String) -> void:
		_mark_dirty()
		_refresh_participant_dependent_ui())
	row.add_child(name_le)
	row.add_child(MessengerEmojiPicker.make_button(name_le, self))

	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(32, 32)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	row.add_child(thumb)

	var avatar_le := LineEdit.new()
	avatar_le.placeholder_text = "res://…/avatar.png"
	avatar_le.text = avatar
	avatar_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avatar_le.text_changed.connect(func(t: String) -> void:
		_mark_dirty()
		_update_thumb(thumb, t))
	row.add_child(avatar_le)
	_update_thumb(thumb, avatar)

	var browse := Button.new()
	browse.text = "Browse…"
	browse.pressed.connect(func() -> void:
		_avatar_target = avatar_le
		_avatar_dialog.popup_centered())
	row.add_child(browse)

	var remove := Button.new()
	remove.text = "✕"
	remove.pressed.connect(func() -> void:
		_remove_participant_row(row)
		_mark_dirty()
		_refresh_participant_dependent_ui())
	row.add_child(remove)

	_participant_rows.append({"row": row, "name": name_le, "avatar": avatar_le})
	_add_participant_btn.disabled = _participant_rows.size() >= MAX_PARTICIPANTS


func _remove_participant_row(row: Control) -> void:
	for i: int in range(_participant_rows.size()):
		if (_participant_rows[i] as Dictionary).get("row") == row:
			_participant_rows.remove_at(i)
			break
	row.queue_free()
	_add_participant_btn.disabled = _participant_rows.size() >= MAX_PARTICIPANTS


func _update_thumb(thumb: TextureRect, path: String) -> void:
	var p := path.strip_edges()
	if not p.is_empty() and ResourceLoader.exists(p):
		thumb.texture = load(p) as Texture2D
	else:
		thumb.texture = null


func _participant_names() -> Array:
	var out: Array = []
	for r: Dictionary in _participant_rows:
		var n: String = (r["name"] as LineEdit).text.strip_edges()
		if not n.is_empty():
			out.append(n)
	return out


## Keep the right-side picker and every message "from" dropdown in sync
## with the current participant names.
func _refresh_participant_dependent_ui() -> void:
	var names: Array = _participant_names()
	_populate_name_option(_right_side_opt, names)
	for r: Dictionary in _message_rows:
		_populate_name_option(r["from"] as OptionButton, names)


func _populate_name_option(opt: OptionButton, names: Array) -> void:
	if opt == null:
		return
	var prev: String = ""
	if opt.selected >= 0 and opt.selected < opt.item_count:
		prev = opt.get_item_text(opt.selected)
	opt.clear()
	for n: Variant in names:
		opt.add_item(str(n))
	for i: int in range(opt.item_count):
		if opt.get_item_text(i) == prev:
			opt.select(i)
			return
	if opt.item_count > 0:
		opt.select(0)


# ─────────────────────────────────────────────────────────────
# Message rows
# ─────────────────────────────────────────────────────────────
func _add_message_row(md: Dictionary) -> void:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8.0)
	panel.add_theme_stylebox_override("panel", sb)
	_messages_vbox.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	col.add_child(top)

	var from_opt := OptionButton.new()
	from_opt.custom_minimum_size = Vector2(150, 0)
	_populate_name_option(from_opt, _participant_names())
	var want_from: String = str(md.get("from", "")).strip_edges()
	for i: int in range(from_opt.item_count):
		if from_opt.get_item_text(i) == want_from:
			from_opt.select(i)
			break
	from_opt.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	top.add_child(from_opt)

	var time_le := LineEdit.new()
	time_le.placeholder_text = "Time (e.g. 21:03)"
	time_le.text = str(md.get("time", ""))
	time_le.custom_minimum_size = Vector2(140, 0)
	time_le.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	top.add_child(time_le)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	var up := Button.new()
	up.text = "▲"
	up.pressed.connect(func() -> void: _move_message_row(panel, -1))
	top.add_child(up)
	var down := Button.new()
	down.text = "▼"
	down.pressed.connect(func() -> void: _move_message_row(panel, 1))
	top.add_child(down)
	var remove := Button.new()
	remove.text = "✕"
	remove.pressed.connect(func() -> void:
		_remove_message_row(panel)
		_mark_dirty())
	top.add_child(remove)

	var text_row := HBoxContainer.new()
	text_row.add_theme_constant_override("separation", 4)
	col.add_child(text_row)
	var text_le := LineEdit.new()
	text_le.placeholder_text = "Text (use 😀 button or paste emoji). Empty = image-only."
	text_le.text = str(md.get("text", ""))
	text_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_le.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	text_row.add_child(text_le)
	text_row.add_child(MessengerEmojiPicker.make_button(text_le, self))

	var img_row := HBoxContainer.new()
	img_row.add_theme_constant_override("separation", 6)
	col.add_child(img_row)
	var img_le := LineEdit.new()
	img_le.placeholder_text = "Image attachment (optional): res://…/photo.png"
	img_le.text = str(md.get("image", ""))
	img_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	img_le.text_changed.connect(func(_t: String) -> void: _mark_dirty())
	img_row.add_child(img_le)
	var browse := Button.new()
	browse.text = "Browse…"
	browse.pressed.connect(func() -> void:
		_image_target = img_le
		_image_dialog.popup_centered())
	img_row.add_child(browse)

	_message_rows.append({
		"panel": panel, "from": from_opt, "time": time_le,
		"text": text_le, "image": img_le,
	})


func _remove_message_row(panel: Control) -> void:
	for i: int in range(_message_rows.size()):
		if (_message_rows[i] as Dictionary).get("panel") == panel:
			_message_rows.remove_at(i)
			break
	panel.queue_free()


func _move_message_row(panel: Control, dir: int) -> void:
	var idx: int = -1
	for i: int in range(_message_rows.size()):
		if (_message_rows[i] as Dictionary).get("panel") == panel:
			idx = i
			break
	var target: int = idx + dir
	if idx < 0 or target < 0 or target >= _message_rows.size():
		return
	var tmp: Dictionary = _message_rows[idx]
	_message_rows[idx] = _message_rows[target]
	_message_rows[target] = tmp
	_messages_vbox.move_child(panel, target)
	_mark_dirty()


# ─────────────────────────────────────────────────────────────
# List / selection
# ─────────────────────────────────────────────────────────────
func _refresh_list() -> void:
	_list.clear()
	for c: Variant in _conversations:
		var cd: Dictionary = c as Dictionary if c is Dictionary else {}
		var cid: String = str(cd.get("id", "?"))
		var title: String = str(cd.get("title", ""))
		_list.add_item("%s  —  %s" % [cid, title] if not title.is_empty() else cid)


func _on_list_selected(idx: int) -> void:
	_flush_selected()
	_select_conversation(idx)


func _select_conversation(idx: int) -> void:
	if idx < 0 or idx >= _conversations.size():
		return
	_selected_idx = idx
	_list.select(idx)
	_populate_fields(_conversations[idx] as Dictionary)


func _populate_fields(conv: Dictionary) -> void:
	_loading = true
	_id_edit.text = str(conv.get("id", ""))
	_title_edit.text = str(conv.get("title", ""))
	var mode: String = str(conv.get("reveal_mode", "all")).strip_edges().to_lower()
	_reveal_opt.select(maxi(REVEAL_MODES.find(mode), 0))

	for r: Dictionary in _participant_rows:
		(r["row"] as Control).queue_free()
	_participant_rows.clear()
	var parts: Variant = conv.get("participants", [])
	if parts is Array:
		for p: Variant in (parts as Array):
			if p is Dictionary:
				var pd: Dictionary = p as Dictionary
				_add_participant_row(str(pd.get("name", "")), str(pd.get("avatar", "")))
	_add_participant_btn.disabled = _participant_rows.size() >= MAX_PARTICIPANTS

	for r: Dictionary in _message_rows:
		(r["panel"] as Control).queue_free()
	_message_rows.clear()
	var msgs: Variant = conv.get("messages", [])
	if msgs is Array:
		for m: Variant in (msgs as Array):
			if m is Dictionary:
				_add_message_row(m as Dictionary)

	_refresh_participant_dependent_ui()
	var rs: String = str(conv.get("right_side", "")).strip_edges()
	for i: int in range(_right_side_opt.item_count):
		if _right_side_opt.get_item_text(i) == rs:
			_right_side_opt.select(i)
			break
	_loading = false


## Write the current editor fields back into _conversations[_selected_idx].
func _flush_selected() -> void:
	if _selected_idx < 0 or _selected_idx >= _conversations.size():
		return
	_conversations[_selected_idx] = _collect_conversation()
	_refresh_list()
	_list.select(_selected_idx)


func _collect_conversation() -> Dictionary:
	var parts: Array = []
	for r: Dictionary in _participant_rows:
		var n: String = (r["name"] as LineEdit).text.strip_edges()
		if n.is_empty():
			continue
		parts.append({
			"name": n,
			"avatar": (r["avatar"] as LineEdit).text.strip_edges(),
		})
	var msgs: Array = []
	for r: Dictionary in _message_rows:
		var from_opt: OptionButton = r["from"] as OptionButton
		var md: Dictionary = {
			"from": from_opt.get_item_text(from_opt.selected) if from_opt.selected >= 0 else "",
			"time": (r["time"] as LineEdit).text.strip_edges(),
		}
		var text: String = (r["text"] as LineEdit).text
		if not text.is_empty():
			md["text"] = text
		var image: String = (r["image"] as LineEdit).text.strip_edges()
		if not image.is_empty():
			md["image"] = image
		msgs.append(md)
	var rs: String = ""
	if _right_side_opt.selected >= 0 and _right_side_opt.item_count > 0:
		rs = _right_side_opt.get_item_text(_right_side_opt.selected)
	return {
		"id": _id_edit.text.strip_edges(),
		"title": _title_edit.text.strip_edges(),
		"reveal_mode": REVEAL_MODES[maxi(_reveal_opt.selected, 0)],
		"right_side": rs,
		"participants": parts,
		"messages": msgs,
	}


# ─────────────────────────────────────────────────────────────
# Actions
# ─────────────────────────────────────────────────────────────
func _mark_dirty() -> void:
	if not _loading:
		_dirty = true


func _set_status(text: String) -> void:
	_status_lbl.text = text


func _unique_id(base: String) -> String:
	var ids: Dictionary = {}
	for c: Variant in _conversations:
		if c is Dictionary:
			ids[str((c as Dictionary).get("id", ""))] = true
	if not ids.has(base):
		return base
	var n := 2
	while ids.has("%s_%d" % [base, n]):
		n += 1
	return "%s_%d" % [base, n]


func _on_new() -> void:
	_flush_selected()
	_conversations.append({
		"id": _unique_id("new_chat"),
		"title": "New Chat",
		"reveal_mode": "all",
		"right_side": "",
		"participants": [],
		"messages": [],
	})
	_dirty = true
	_refresh_list()
	_select_conversation(_conversations.size() - 1)


func _on_duplicate() -> void:
	if _selected_idx < 0:
		_set_status("Select a conversation to duplicate.")
		return
	_flush_selected()
	var copy: Dictionary = (_conversations[_selected_idx] as Dictionary).duplicate(true)
	copy["id"] = _unique_id(str(copy.get("id", "chat")) + "_copy")
	_conversations.append(copy)
	_dirty = true
	_refresh_list()
	_select_conversation(_conversations.size() - 1)


func _on_delete() -> void:
	if _selected_idx < 0:
		_set_status("Select a conversation to delete.")
		return
	var cid: String = str((_conversations[_selected_idx] as Dictionary).get("id", "?"))
	GameDialog.confirmation_overlay(
		self, "Delete Conversation",
		"Remove '%s' from the vault? (Takes effect on Save.)" % cid,
		"Delete", "Cancel",
		func() -> void:
			_conversations.remove_at(_selected_idx)
			_selected_idx = -1
			_dirty = true
			_refresh_list()
			if not _conversations.is_empty():
				_select_conversation(0)
			_set_status("Deleted '%s' — remember to Save." % cid))


func _on_copy_json() -> void:
	if _selected_idx < 0:
		_set_status("Select a conversation to copy.")
		return
	_flush_selected()
	DisplayServer.clipboard_set(
		JSON.stringify(_conversations[_selected_idx], "\t"))
	_set_status("Conversation JSON copied to clipboard.")


func _on_paste_json() -> void:
	var raw: String = DisplayServer.clipboard_get()
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary or not (parsed as Dictionary).has("messages"):
		_set_status("Clipboard does not contain valid conversation JSON.")
		return
	_flush_selected()
	var conv: Dictionary = parsed as Dictionary
	conv["id"] = _unique_id(str(conv.get("id", "pasted_chat")))
	var parts: Variant = conv.get("participants", [])
	if parts is Array and (parts as Array).size() > MAX_PARTICIPANTS:
		conv["participants"] = (parts as Array).slice(0, MAX_PARTICIPANTS)
		_set_status("Pasted — participants trimmed to %d." % MAX_PARTICIPANTS)
	else:
		_set_status("Conversation pasted from clipboard.")
	_conversations.append(conv)
	_dirty = true
	_refresh_list()
	_select_conversation(_conversations.size() - 1)


func _on_preview() -> void:
	_flush_selected()
	if _selected_idx < 0:
		_set_status("Select a conversation to preview.")
		return
	MessengerOverlay.open_with_data(self, _conversations[_selected_idx] as Dictionary)


func _on_reload() -> void:
	MessengerVault.reload()
	_conversations = MessengerVault.get_conversations()
	_selected_idx = -1
	_dirty = false
	_refresh_list()
	if not _conversations.is_empty():
		_select_conversation(0)
	_set_status("Reloaded from disk.")


func _on_save() -> void:
	_flush_selected()
	if not BuildConfig.can_write_shipped_data():
		_set_status("Cannot write res://data in exported builds — run from the editor.")
		return
	for c: Variant in _conversations:
		if c is Dictionary and str((c as Dictionary).get("id", "")).strip_edges().is_empty():
			_set_status("Every conversation needs a non-empty id.")
			return
	if MessengerVault.save_conversations(_conversations):
		_dirty = false
		_set_status("Saved to %s" % MessengerVault.SAVE_PATH)
	else:
		_set_status("Save FAILED — could not open %s for writing." % MessengerVault.SAVE_PATH)
