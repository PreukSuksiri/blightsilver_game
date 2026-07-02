extends Control
class_name ProtagonistManagerOverlay
## Admin overlay for protagonist definitions (data/protagonists.json).
## Opened via admin command: protagonist_manager

var _data: Dictionary = {}
var _protagonist_ids: Array[String] = []
var _selected_id: String = ""

var _list: ItemList = null
var _display_name_edit: LineEdit = null
var _birth_name_edit: LineEdit = null
var _portrait_dir_edit: LineEdit = null
var _win_screen_edit: LineEdit = null
var _poses_box: VBoxContainer = null
var _status_lbl: Label = null
var _win_file_dialog: FileDialog = null
var _portrait_dir_dialog: FileDialog = null
var _portrait_file_dialog: FileDialog = null
var _pose_portrait_target: LineEdit = null


static func open(parent: Node) -> void:
	var overlay: Control = load("res://scripts/ProtagonistManagerOverlay.gd").new()
	overlay.name = "ProtagonistManagerOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)


func _ready() -> void:
	_reload_data()
	_build_ui()
	if not _protagonist_ids.is_empty():
		_select_protagonist(_protagonist_ids[0])


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()


func _reload_data() -> void:
	ProtagonistVault.reload()
	_data = ProtagonistVault.get_data()
	_protagonist_ids = []
	for key: Variant in _data.keys():
		_protagonist_ids.append(str(key))
	_protagonist_ids.sort()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.10, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := Label.new()
	header.text = "Protagonist Manager"
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 8.0
	header.offset_bottom = 40.0
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	add_child(header)

	var top_btns := HBoxContainer.new()
	top_btns.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top_btns.offset_left = -320.0
	top_btns.offset_top = 6.0
	top_btns.offset_right = -8.0
	top_btns.add_theme_constant_override("separation", 8)
	add_child(top_btns)

	var reload_btn := Button.new()
	reload_btn.text = "Reload"
	reload_btn.pressed.connect(_on_reload)
	top_btns.add_child(reload_btn)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save)
	top_btns.add_child(save_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(queue_free)
	top_btns.add_child(close_btn)

	var body := HBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_top = 44.0
	body.offset_bottom = -52.0
	body.offset_left = 12.0
	body.offset_right = -12.0
	body.add_theme_constant_override("separation", 12)
	add_child(body)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(220, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(left)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_list_selected)
	left.add_child(_list)

	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right_scroll)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	right_scroll.add_child(right)

	_display_name_edit = LineEdit.new()
	right.add_child(_labeled_row("Display name", _display_name_edit))
	_birth_name_edit = LineEdit.new()
	right.add_child(_labeled_row("Birth name", _birth_name_edit))

	var portrait_row := HBoxContainer.new()
	portrait_row.add_theme_constant_override("separation", 8)
	var portrait_lbl := Label.new()
	portrait_lbl.text = "Portrait dir"
	portrait_lbl.custom_minimum_size.x = 110.0
	portrait_row.add_child(portrait_lbl)
	_portrait_dir_edit = LineEdit.new()
	_portrait_dir_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_row.add_child(_portrait_dir_edit)
	var portrait_browse := Button.new()
	portrait_browse.text = "Browse..."
	portrait_browse.pressed.connect(_browse_portrait_dir)
	portrait_row.add_child(portrait_browse)
	right.add_child(portrait_row)

	var win_row := HBoxContainer.new()
	win_row.add_theme_constant_override("separation", 8)
	var win_lbl := Label.new()
	win_lbl.text = "Win screen"
	win_lbl.custom_minimum_size.x = 110.0
	win_row.add_child(win_lbl)
	_win_screen_edit = LineEdit.new()
	_win_screen_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	win_row.add_child(_win_screen_edit)
	var win_browse := Button.new()
	win_browse.text = "Browse..."
	win_browse.pressed.connect(_browse_win_screen)
	win_row.add_child(win_browse)
	right.add_child(win_row)

	var poses_hdr := Label.new()
	poses_hdr.text = "Poses"
	poses_hdr.add_theme_font_size_override("font_size", 14)
	right.add_child(poses_hdr)

	var poses_header := HBoxContainer.new()
	poses_header.add_theme_constant_override("separation", 8)
	for col: String in ["Index", "Portrait", "Locked", "Unlock achievement"]:
		var lbl := Label.new()
		lbl.text = col
		lbl.custom_minimum_size.x = 120.0 if col != "Portrait" else 280.0
		poses_header.add_child(lbl)
	right.add_child(poses_header)

	_poses_box = VBoxContainer.new()
	_poses_box.add_theme_constant_override("separation", 6)
	right.add_child(_poses_box)

	var pose_btns := HBoxContainer.new()
	pose_btns.add_theme_constant_override("separation", 8)
	var add_pose_btn := Button.new()
	add_pose_btn.text = "Add pose"
	add_pose_btn.pressed.connect(_on_add_pose)
	pose_btns.add_child(add_pose_btn)
	var del_pose_btn := Button.new()
	del_pose_btn.text = "Remove last"
	del_pose_btn.pressed.connect(_on_remove_last_pose)
	pose_btns.add_child(del_pose_btn)
	right.add_child(pose_btns)

	var footer := HBoxContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -48.0
	footer.offset_left = 12.0
	footer.offset_right = -12.0
	add_child(footer)

	_status_lbl = Label.new()
	_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(_status_lbl)

	_win_file_dialog = FileDialog.new()
	_win_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_win_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_win_file_dialog.filters = PackedStringArray(["*.png ; PNG Images"])
	_win_file_dialog.file_selected.connect(func(path: String) -> void:
		if _win_screen_edit:
			_win_screen_edit.text = path)
	add_child(_win_file_dialog)

	_portrait_dir_dialog = FileDialog.new()
	_portrait_dir_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_portrait_dir_dialog.access = FileDialog.ACCESS_RESOURCES
	_portrait_dir_dialog.dir_selected.connect(func(path: String) -> void:
		if _portrait_dir_edit:
			_portrait_dir_edit.text = path)
	add_child(_portrait_dir_dialog)

	_portrait_file_dialog = FileDialog.new()
	_portrait_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_portrait_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_portrait_file_dialog.filters = PackedStringArray(["*.png ; PNG Images"])
	_portrait_file_dialog.file_selected.connect(func(path: String) -> void:
		if _pose_portrait_target:
			_pose_portrait_target.text = path.get_file())
	add_child(_portrait_file_dialog)

	_refresh_list()


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


func _refresh_list() -> void:
	if _list == null:
		return
	var keep := _selected_id
	_list.clear()
	for pid: String in _protagonist_ids:
		var entry: Variant = _data.get(pid, {})
		var name: String = pid
		if entry is Dictionary:
			name = str((entry as Dictionary).get("display_name", pid))
		_list.add_item("%s  [%s]" % [name, pid])
		if pid == keep:
			_list.select(_list.item_count - 1)


func _on_list_selected(idx: int) -> void:
	if idx < 0 or idx >= _protagonist_ids.size():
		return
	_select_protagonist(_protagonist_ids[idx])


func _select_protagonist(protagonist_id: String) -> void:
	if not protagonist_id.is_empty() and _selected_id != "":
		_sync_current_protagonist()
	_selected_id = protagonist_id
	var entry: Variant = _data.get(protagonist_id, {})
	if not entry is Dictionary:
		entry = {}
		_data[protagonist_id] = entry
	var d: Dictionary = entry as Dictionary
	if _display_name_edit:
		_display_name_edit.text = str(d.get("display_name", protagonist_id.capitalize()))
	if _birth_name_edit:
		_birth_name_edit.text = str(d.get("birth_name", ""))
	if _portrait_dir_edit:
		_portrait_dir_edit.text = str(d.get("portrait_dir", ""))
	if _win_screen_edit:
		_win_screen_edit.text = str(d.get("win_screen", ""))
	_rebuild_pose_rows(d.get("poses", []) as Array)
	_refresh_list()


func _rebuild_pose_rows(poses: Array) -> void:
	if _poses_box == null:
		return
	for child: Node in _poses_box.get_children():
		child.queue_free()
	if not poses is Array:
		poses = []
	for pose: Variant in poses:
		if not pose is Dictionary:
			continue
		_poses_box.add_child(_make_pose_row(pose as Dictionary))


func _make_pose_row(pose: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var index_spin := SpinBox.new()
	index_spin.min_value = 0.0
	index_spin.max_value = 99.0
	index_spin.value = float(int(pose.get("index", 0)))
	index_spin.custom_minimum_size.x = 80.0
	row.add_child(index_spin)

	var portrait_edit := LineEdit.new()
	portrait_edit.text = str(pose.get("portrait", ""))
	portrait_edit.custom_minimum_size.x = 280.0
	portrait_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(portrait_edit)

	var portrait_browse := Button.new()
	portrait_browse.text = "..."
	portrait_browse.pressed.connect(func() -> void:
		_pose_portrait_target = portrait_edit
		if _portrait_file_dialog:
			_portrait_file_dialog.popup_centered(Vector2i(800, 500)))
	row.add_child(portrait_browse)

	var locked_chk := CheckBox.new()
	locked_chk.text = ""
	locked_chk.button_pressed = bool(pose.get("locked", false))
	locked_chk.custom_minimum_size.x = 80.0
	row.add_child(locked_chk)

	var unlock_edit := LineEdit.new()
	unlock_edit.text = str(pose.get("unlock_achievement_id", ""))
	unlock_edit.custom_minimum_size.x = 180.0
	unlock_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(unlock_edit)

	row.set_meta("index_spin", index_spin)
	row.set_meta("portrait_edit", portrait_edit)
	row.set_meta("locked_chk", locked_chk)
	row.set_meta("unlock_edit", unlock_edit)
	return row


func _collect_poses_from_ui() -> Array:
	var poses: Array = []
	if _poses_box == null:
		return poses
	for row: Node in _poses_box.get_children():
		if not row is HBoxContainer:
			continue
		var index_spin: SpinBox = row.get_meta("index_spin") as SpinBox
		var portrait_edit: LineEdit = row.get_meta("portrait_edit") as LineEdit
		var locked_chk: CheckBox = row.get_meta("locked_chk") as CheckBox
		var unlock_edit: LineEdit = row.get_meta("unlock_edit") as LineEdit
		var pose: Dictionary = {
			"index": int(index_spin.value) if index_spin else 0,
			"portrait": portrait_edit.text.strip_edges() if portrait_edit else "",
			"locked": locked_chk.button_pressed if locked_chk else false,
		}
		var unlock_id: String = unlock_edit.text.strip_edges() if unlock_edit else ""
		if not unlock_id.is_empty():
			pose["unlock_achievement_id"] = unlock_id
		poses.append(pose)
	return poses


func _sync_current_protagonist() -> void:
	if _selected_id.is_empty():
		return
	var entry: Dictionary = (_data.get(_selected_id, {}) as Dictionary).duplicate(true)
	entry["display_name"] = _display_name_edit.text.strip_edges() if _display_name_edit else _selected_id
	entry["birth_name"] = _birth_name_edit.text.strip_edges() if _birth_name_edit else ""
	entry["portrait_dir"] = _portrait_dir_edit.text.strip_edges() if _portrait_dir_edit else ""
	entry["win_screen"] = _win_screen_edit.text.strip_edges() if _win_screen_edit else ""
	entry["poses"] = _collect_poses_from_ui()
	_data[_selected_id] = entry


func _on_add_pose() -> void:
	_sync_current_protagonist()
	var entry: Dictionary = _data.get(_selected_id, {}) as Dictionary
	var poses: Array = entry.get("poses", []) as Array
	var next_index := 1
	for pose: Variant in poses:
		if pose is Dictionary:
			next_index = maxi(next_index, int((pose as Dictionary).get("index", 0)) + 1)
	poses.append({
		"index": next_index,
		"portrait": "",
		"locked": false,
	})
	entry["poses"] = poses
	_data[_selected_id] = entry
	_rebuild_pose_rows(poses)


func _on_remove_last_pose() -> void:
	_sync_current_protagonist()
	var entry: Dictionary = _data.get(_selected_id, {}) as Dictionary
	var poses: Array = entry.get("poses", []) as Array
	if poses.is_empty():
		return
	poses.pop_back()
	entry["poses"] = poses
	_data[_selected_id] = entry
	_rebuild_pose_rows(poses)


func _browse_portrait_dir() -> void:
	if _portrait_dir_dialog:
		_portrait_dir_dialog.popup_centered(Vector2i(900, 600))


func _browse_win_screen() -> void:
	if _win_file_dialog:
		_win_file_dialog.popup_centered(Vector2i(900, 600))


func _on_reload() -> void:
	_sync_current_protagonist()
	_reload_data()
	_selected_id = ""
	if not _protagonist_ids.is_empty():
		_select_protagonist(_protagonist_ids[0])
	else:
		_refresh_list()
	_set_status("Reloaded protagonists.json")


func _on_save() -> void:
	_sync_current_protagonist()
	ProtagonistVault.set_data(_data)
	if not ProtagonistVault.save():
		_set_status("ERROR: cannot write protagonists.json")
		return
	_data = ProtagonistVault.get_data()
	_refresh_list()
	_set_status("Saved %d protagonists." % _protagonist_ids.size())


func _set_status(msg: String) -> void:
	if _status_lbl:
		_status_lbl.text = msg
