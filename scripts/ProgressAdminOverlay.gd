extends Control
class_name ProgressAdminOverlay
## Admin overlay for achievement definitions and global stat definitions.
## Opened via admin command: progress_admin

const REWARD_TYPES: Array[String] = [
	"", "credits", "card", "booster_pack", "union_scroll", "music_disc", "stage_bonus_card",
]
const PROGRESS_KINDS: Array[String] = [
	"none", "unique_cards", "unions_discovered", "duel_wins", "credit_balance", "deck_count",
	"union_summon_divine_count", "union_summon_chaos_count", "union_summon_nature_count",
	"union_summon_arcane_count", "union_summon_cosmic_count", "union_summon_bio_count",
	"union_summon_anima_count",
]

var _initial_tab: String = "achievements"
var _active_tab: String = "achievements"

var _achievements: Array = []
var _ach_selected_idx: int = -1

var _stat_defs: Array = []
var _stat_selected_idx: int = -1
var _stat_values: Dictionary = {}

var _ach_panel: Control = null
var _stats_panel: Control = null
var _tab_ach_btn: Button = null
var _tab_stats_btn: Button = null
var _status_lbl: Label = null

var _ach_list: ItemList = null
var _ach_id_edit: LineEdit = null
var _ach_title_edit: LineEdit = null
var _ach_condition_edit: LineEdit = null
var _ach_hidden_hint_edit: LineEdit = null
var _ach_icon_edit: LineEdit = null
var _ach_hidden_chk: CheckBox = null
var _ach_progress_kind_opt: OptionButton = null
var _ach_progress_target_spin: SpinBox = null
var _ach_implemented_chk: CheckBox = null
var _ach_dev_unlock_chk: CheckBox = null
var _reward_type_opt: OptionButton = null
var _reward_fields_box: VBoxContainer = null
var _reward_amount_spin: SpinBox = null
var _reward_card_edit: LineEdit = null
var _reward_pack_edit: LineEdit = null
var _reward_count_spin: SpinBox = null
var _icon_file_dialog: FileDialog = null

var _stat_list: ItemList = null
var _stat_id_lbl: Label = null
var _stat_title_lbl: Label = null
var _stat_value_spin: SpinBox = null
var _stat_implemented_chk: CheckBox = null


static func open(parent: Node, initial_tab: String = "achievements") -> void:
	var overlay: Control = load("res://scripts/ProgressAdminOverlay.gd").new()
	overlay.name = "ProgressAdminOverlay"
	overlay._initial_tab = initial_tab.strip_edges().to_lower()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)


func _ready() -> void:
	_active_tab = "stats" if _initial_tab == "stats" else "achievements"
	_reload_all_data()
	_build_ui()
	_switch_tab(_active_tab)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()


func _reload_all_data() -> void:
	AchievementManager.reload_definitions()
	GlobalStatManager.reload_definitions()
	_achievements = AchievementManager.get_definitions()
	_stat_defs = GlobalStatManager.get_definitions()
	_stat_values.clear()
	for def: Variant in _stat_defs:
		if not def is Dictionary:
			continue
		var id: String = str((def as Dictionary).get("id", "")).strip_edges()
		if not id.is_empty():
			_stat_values[id] = GlobalStatManager.get_int(id)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.10, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := HBoxContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 8.0
	header.offset_bottom = 44.0
	header.offset_left = 12.0
	header.offset_right = -12.0
	header.add_theme_constant_override("separation", 10)
	add_child(header)

	var title := Label.new()
	title.text = "Progress Admin"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)

	var reload_btn := Button.new()
	reload_btn.text = "Reload"
	reload_btn.pressed.connect(_on_reload)
	header.add_child(reload_btn)

	var save_btn := Button.new()
	save_btn.text = "Save JSON"
	save_btn.pressed.connect(_on_save)
	header.add_child(save_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	var tab_row := HBoxContainer.new()
	tab_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tab_row.offset_top = 48.0
	tab_row.offset_bottom = 80.0
	tab_row.offset_left = 12.0
	tab_row.offset_right = -12.0
	tab_row.add_theme_constant_override("separation", 8)
	add_child(tab_row)

	_tab_ach_btn = Button.new()
	_tab_ach_btn.text = "Achievements"
	_tab_ach_btn.pressed.connect(func() -> void: _switch_tab("achievements"))
	tab_row.add_child(_tab_ach_btn)

	_tab_stats_btn = Button.new()
	_tab_stats_btn.text = "Global Stats"
	_tab_stats_btn.pressed.connect(func() -> void: _switch_tab("stats"))
	tab_row.add_child(_tab_stats_btn)

	var body := Control.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_top = 84.0
	body.offset_bottom = -52.0
	body.offset_left = 12.0
	body.offset_right = -12.0
	add_child(body)

	_ach_panel = _build_achievements_panel()
	_ach_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(_ach_panel)

	_stats_panel = _build_stats_panel()
	_stats_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stats_panel.visible = false
	body.add_child(_stats_panel)

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

	_icon_file_dialog = FileDialog.new()
	_icon_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_icon_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_icon_file_dialog.filters = PackedStringArray(["*.png ; PNG Images", "*.svg ; SVG Images"])
	_icon_file_dialog.file_selected.connect(func(path: String) -> void:
		if _ach_icon_edit:
			_ach_icon_edit.text = path)
	add_child(_icon_file_dialog)


func _build_achievements_panel() -> Control:
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 12)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(300, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(left)

	_ach_list = ItemList.new()
	_ach_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ach_list.item_selected.connect(_on_ach_list_selected)
	left.add_child(_ach_list)

	var right := ScrollContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(right)

	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 8)
	right.add_child(form)

	_ach_id_edit = LineEdit.new()
	form.add_child(_labeled_row("ID", _ach_id_edit))
	_ach_title_edit = LineEdit.new()
	form.add_child(_labeled_row("Title", _ach_title_edit))
	_ach_condition_edit = LineEdit.new()
	form.add_child(_labeled_row("Condition", _ach_condition_edit))
	_ach_hidden_hint_edit = LineEdit.new()
	form.add_child(_labeled_row("Hidden hint", _ach_hidden_hint_edit))

	var icon_row := HBoxContainer.new()
	icon_row.add_theme_constant_override("separation", 8)
	var icon_lbl := Label.new()
	icon_lbl.text = "Icon"
	icon_lbl.custom_minimum_size.x = 110.0
	icon_row.add_child(icon_lbl)
	_ach_icon_edit = LineEdit.new()
	_ach_icon_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_row.add_child(_ach_icon_edit)
	var browse_btn := Button.new()
	browse_btn.text = "Browse..."
	browse_btn.pressed.connect(_browse_icon)
	icon_row.add_child(browse_btn)
	form.add_child(icon_row)

	_reward_type_opt = OptionButton.new()
	for t: String in REWARD_TYPES:
		_reward_type_opt.add_item("(none)" if t.is_empty() else t)
		_reward_type_opt.set_item_metadata(_reward_type_opt.item_count - 1, t)
	_reward_type_opt.item_selected.connect(_on_reward_type_changed)
	form.add_child(_labeled_row("Reward type", _reward_type_opt))

	_reward_fields_box = VBoxContainer.new()
	_reward_fields_box.add_theme_constant_override("separation", 6)
	form.add_child(_reward_fields_box)

	_rebuild_reward_fields("")

	_ach_hidden_chk = CheckBox.new()
	_ach_hidden_chk.text = "Hidden"
	form.add_child(_ach_hidden_chk)

	_ach_progress_kind_opt = OptionButton.new()
	for kind: String in PROGRESS_KINDS:
		_ach_progress_kind_opt.add_item(kind)
		_ach_progress_kind_opt.set_item_metadata(_ach_progress_kind_opt.item_count - 1, kind)
	form.add_child(_labeled_row("Progress kind", _ach_progress_kind_opt))

	_ach_progress_target_spin = SpinBox.new()
	_ach_progress_target_spin.min_value = 0.0
	_ach_progress_target_spin.max_value = 999999.0
	form.add_child(_labeled_row("Progress target", _ach_progress_target_spin))

	_ach_implemented_chk = CheckBox.new()
	_ach_implemented_chk.text = "Implemented"
	form.add_child(_ach_implemented_chk)

	_ach_dev_unlock_chk = CheckBox.new()
	_ach_dev_unlock_chk.text = "Dev unlock (save state)"
	form.add_child(_ach_dev_unlock_chk)

	_refresh_ach_list()
	if not _achievements.is_empty():
		_select_achievement(0)
	return root


func _build_stats_panel() -> Control:
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 12)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(300, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(left)

	_stat_list = ItemList.new()
	_stat_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stat_list.item_selected.connect(_on_stat_list_selected)
	left.add_child(_stat_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	root.add_child(right)

	_stat_id_lbl = Label.new()
	right.add_child(_stat_id_lbl)

	_stat_title_lbl = Label.new()
	right.add_child(_stat_title_lbl)

	_stat_value_spin = SpinBox.new()
	_stat_value_spin.min_value = 0.0
	_stat_value_spin.max_value = 999999999.0
	right.add_child(_labeled_row("Value", _stat_value_spin))

	_stat_implemented_chk = CheckBox.new()
	_stat_implemented_chk.text = "Implemented"
	right.add_child(_stat_implemented_chk)

	_refresh_stat_list()
	if not _stat_defs.is_empty():
		_select_stat(0)
	return root


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


func _switch_tab(tab_key: String) -> void:
	if _active_tab == "achievements":
		_sync_current_achievement()
	elif _active_tab == "stats":
		_sync_current_stat()
	_active_tab = tab_key
	var is_ach := tab_key == "achievements"
	if _ach_panel:
		_ach_panel.visible = is_ach
	if _stats_panel:
		_stats_panel.visible = not is_ach
	if _tab_ach_btn:
		_tab_ach_btn.disabled = is_ach
	if _tab_stats_btn:
		_tab_stats_btn.disabled = not is_ach


func _refresh_ach_list() -> void:
	if _ach_list == null:
		return
	var keep := _ach_selected_idx
	_ach_list.clear()
	for entry: Variant in _achievements:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		var impl_mark := "✓" if bool(d.get("implemented", false)) else "·"
		_ach_list.add_item("%s  %s" % [impl_mark, str(d.get("title", d.get("id", "?")))])
	if keep >= 0 and keep < _ach_list.item_count:
		_ach_list.select(keep)


func _refresh_stat_list() -> void:
	if _stat_list == null:
		return
	var keep := _stat_selected_idx
	_stat_list.clear()
	for entry: Variant in _stat_defs:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		var id: String = str(d.get("id", ""))
		var val: int = int(_stat_values.get(id, 0))
		var impl_mark := "✓" if bool(d.get("implemented", false)) else "·"
		_stat_list.add_item("%s  %s  (%d)" % [impl_mark, str(d.get("title", id)), val])
	if keep >= 0 and keep < _stat_list.item_count:
		_stat_list.select(keep)


func _on_ach_list_selected(idx: int) -> void:
	_select_achievement(idx)


func _on_stat_list_selected(idx: int) -> void:
	_select_stat(idx)


func _select_achievement(idx: int) -> void:
	if idx < 0 or idx >= _achievements.size():
		return
	if _ach_selected_idx >= 0:
		_sync_current_achievement()
	_ach_selected_idx = idx
	var entry: Dictionary = _achievements[idx] as Dictionary
	if _ach_id_edit:
		_ach_id_edit.text = str(entry.get("id", ""))
	if _ach_title_edit:
		_ach_title_edit.text = str(entry.get("title", ""))
	if _ach_condition_edit:
		_ach_condition_edit.text = str(entry.get("condition", ""))
	if _ach_hidden_hint_edit:
		_ach_hidden_hint_edit.text = str(entry.get("hidden_hint", ""))
	if _ach_icon_edit:
		_ach_icon_edit.text = str(entry.get("icon", ""))
	if _ach_hidden_chk:
		_ach_hidden_chk.button_pressed = bool(entry.get("hidden", false))
	if _ach_implemented_chk:
		_ach_implemented_chk.button_pressed = bool(entry.get("implemented", false))
	if _ach_progress_target_spin:
		_ach_progress_target_spin.value = float(int(entry.get("progress_target", 0)))
	var kind: String = str(entry.get("progress_kind", "none")).strip_edges()
	if _ach_progress_kind_opt:
		for i: int in range(_ach_progress_kind_opt.item_count):
			if str(_ach_progress_kind_opt.get_item_metadata(i)) == kind:
				_ach_progress_kind_opt.select(i)
				break
	var ach_id: String = str(entry.get("id", "")).strip_edges()
	if _ach_dev_unlock_chk:
		_ach_dev_unlock_chk.button_pressed = AchievementManager.is_unlocked(ach_id)
	var reward: Dictionary = entry.get("reward", {}) as Dictionary
	_load_reward_fields(reward if reward is Dictionary else {})
	if _ach_list:
		_ach_list.select(idx)


func _select_stat(idx: int) -> void:
	if idx < 0 or idx >= _stat_defs.size():
		return
	if _stat_selected_idx >= 0:
		_sync_current_stat()
	_stat_selected_idx = idx
	var entry: Dictionary = _stat_defs[idx] as Dictionary
	var id: String = str(entry.get("id", "")).strip_edges()
	if _stat_id_lbl:
		_stat_id_lbl.text = "ID: %s" % id
	if _stat_title_lbl:
		_stat_title_lbl.text = "Title: %s" % str(entry.get("title", ""))
	if _stat_value_spin:
		_stat_value_spin.value = float(int(_stat_values.get(id, GlobalStatManager.get_int(id))))
	if _stat_implemented_chk:
		_stat_implemented_chk.button_pressed = bool(entry.get("implemented", false))
	if _stat_list:
		_stat_list.select(idx)


func _sync_current_achievement() -> void:
	if _ach_selected_idx < 0 or _ach_selected_idx >= _achievements.size():
		return
	var entry: Dictionary = (_achievements[_ach_selected_idx] as Dictionary).duplicate(true)
	entry["id"] = _ach_id_edit.text.strip_edges() if _ach_id_edit else str(entry.get("id", ""))
	entry["title"] = _ach_title_edit.text.strip_edges() if _ach_title_edit else str(entry.get("title", ""))
	entry["condition"] = _ach_condition_edit.text.strip_edges() if _ach_condition_edit else ""
	entry["hidden_hint"] = _ach_hidden_hint_edit.text.strip_edges() if _ach_hidden_hint_edit else ""
	entry["icon"] = _ach_icon_edit.text.strip_edges() if _ach_icon_edit else ""
	entry["hidden"] = _ach_hidden_chk.button_pressed if _ach_hidden_chk else false
	entry["implemented"] = _ach_implemented_chk.button_pressed if _ach_implemented_chk else false
	if _ach_progress_kind_opt and _ach_progress_kind_opt.selected >= 0:
		entry["progress_kind"] = str(_ach_progress_kind_opt.get_item_metadata(_ach_progress_kind_opt.selected))
	if _ach_progress_target_spin:
		entry["progress_target"] = int(_ach_progress_target_spin.value)
	entry["reward"] = _read_reward_fields()
	_achievements[_ach_selected_idx] = entry


func _sync_current_stat() -> void:
	if _stat_selected_idx < 0 or _stat_selected_idx >= _stat_defs.size():
		return
	var entry: Dictionary = (_stat_defs[_stat_selected_idx] as Dictionary).duplicate(true)
	var id: String = str(entry.get("id", "")).strip_edges()
	entry["implemented"] = _stat_implemented_chk.button_pressed if _stat_implemented_chk else false
	_stat_defs[_stat_selected_idx] = entry
	if not id.is_empty() and _stat_value_spin:
		_stat_values[id] = int(_stat_value_spin.value)


func _load_reward_fields(reward: Dictionary) -> void:
	var t: String = str(reward.get("type", "")).strip_edges()
	if _reward_type_opt:
		for i: int in range(_reward_type_opt.item_count):
			if str(_reward_type_opt.get_item_metadata(i)) == t:
				_reward_type_opt.select(i)
				break
	_rebuild_reward_fields(t)
	if t in ["credits", "coins"] and _reward_amount_spin:
		_reward_amount_spin.value = float(int(reward.get("amount", 0)))
	elif t == "card" or t == "stage_bonus_card":
		if _reward_card_edit:
			_reward_card_edit.text = str(reward.get("card_name", ""))
	elif t == "booster_pack":
		if _reward_pack_edit:
			_reward_pack_edit.text = str(reward.get("pack_name", ""))
	elif t in ["union_scroll", "music_disc"] and _reward_count_spin:
		_reward_count_spin.value = float(int(reward.get("count", 1)))


func _read_reward_fields() -> Dictionary:
	if _reward_type_opt == null or _reward_type_opt.selected < 0:
		return {}
	var t: String = str(_reward_type_opt.get_item_metadata(_reward_type_opt.selected)).strip_edges()
	if t.is_empty():
		return {}
	match t:
		"credits", "coins":
			return {"type": t, "amount": int(_reward_amount_spin.value) if _reward_amount_spin else 0}
		"card", "stage_bonus_card":
			return {"type": t, "card_name": _reward_card_edit.text.strip_edges() if _reward_card_edit else ""}
		"booster_pack":
			return {"type": t, "pack_name": _reward_pack_edit.text.strip_edges() if _reward_pack_edit else ""}
		"union_scroll", "music_disc":
			return {"type": t, "count": int(_reward_count_spin.value) if _reward_count_spin else 1}
		_:
			return {"type": t}


func _on_reward_type_changed(_idx: int) -> void:
	if _reward_type_opt == null or _reward_type_opt.selected < 0:
		return
	var t: String = str(_reward_type_opt.get_item_metadata(_reward_type_opt.selected))
	_rebuild_reward_fields(t)


func _rebuild_reward_fields(reward_type: String) -> void:
	if _reward_fields_box == null:
		return
	for child: Node in _reward_fields_box.get_children():
		_reward_fields_box.remove_child(child)
		child.queue_free()
	_reward_amount_spin = null
	_reward_card_edit = null
	_reward_pack_edit = null
	_reward_count_spin = null
	match reward_type:
		"credits", "coins":
			_reward_amount_spin = SpinBox.new()
			_reward_amount_spin.min_value = 0.0
			_reward_amount_spin.max_value = 999999.0
			_reward_fields_box.add_child(_labeled_row("Amount", _reward_amount_spin))
		"card", "stage_bonus_card":
			_reward_card_edit = LineEdit.new()
			_reward_fields_box.add_child(_labeled_row("Card name", _reward_card_edit))
		"booster_pack":
			_reward_pack_edit = LineEdit.new()
			_reward_fields_box.add_child(_labeled_row("Pack name", _reward_pack_edit))
		"union_scroll", "music_disc":
			_reward_count_spin = SpinBox.new()
			_reward_count_spin.min_value = 0.0
			_reward_count_spin.max_value = 999.0
			_reward_count_spin.value = 1.0
			_reward_fields_box.add_child(_labeled_row("Count", _reward_count_spin))
		_:
			pass


func _browse_icon() -> void:
	if _icon_file_dialog:
		_icon_file_dialog.popup_centered(Vector2i(900, 600))


func _on_reload() -> void:
	if _active_tab == "achievements":
		_sync_current_achievement()
	elif _active_tab == "stats":
		_sync_current_stat()
	_reload_all_data()
	_ach_selected_idx = -1
	_stat_selected_idx = -1
	_refresh_ach_list()
	_refresh_stat_list()
	if not _achievements.is_empty():
		_select_achievement(0)
	if not _stat_defs.is_empty():
		_select_stat(0)
	_set_status("Reloaded from disk.")


func _on_save() -> void:
	_sync_current_achievement()
	_sync_current_stat()
	var ach_ok := _save_achievements(false)
	var stats_ok := _save_global_stats(false)
	if ach_ok and stats_ok:
		_set_status("Saved achievements and global stats.")
	elif ach_ok:
		_set_status("Saved achievements. ERROR writing global_stats.json")
	elif stats_ok:
		_set_status("Saved global stats. ERROR writing achievements.json")
	else:
		_set_status("ERROR: failed to save both files.")


func _save_achievements(update_status: bool = true) -> bool:
	_sync_current_achievement()
	AchievementManager._definitions = _achievements.duplicate(true)
	if not AchievementManager.save_definitions():
		if update_status:
			_set_status("ERROR: cannot write achievements.json")
		return false
	if _ach_dev_unlock_chk:
		var ach_id: String = ""
		if _ach_selected_idx >= 0 and _achievements[_ach_selected_idx] is Dictionary:
			ach_id = str((_achievements[_ach_selected_idx] as Dictionary).get("id", "")).strip_edges()
		if not ach_id.is_empty():
			if _ach_dev_unlock_chk.button_pressed and not AchievementManager.is_unlocked(ach_id):
				AchievementManager.unlock(ach_id, true)
			elif not _ach_dev_unlock_chk.button_pressed and AchievementManager.is_unlocked(ach_id):
				AchievementManager.revoke(ach_id)
	_refresh_ach_list()
	if update_status:
		_set_status("Saved %d achievements." % _achievements.size())
	return true


func _save_global_stats(update_status: bool = true) -> bool:
	var f := FileAccess.open(GlobalStatManager.DATA_PATH, FileAccess.WRITE)
	if f == null:
		if update_status:
			_set_status("ERROR: cannot write global_stats.json")
		return false
	f.store_string(JSON.stringify({"stats": _stat_defs}, "\t"))
	f.close()
	GlobalStatManager.reload_definitions()
	for id: Variant in _stat_values.keys():
		GlobalStatManager.set_int(str(id), int(_stat_values[id]), false)
	SaveManager.save_data()
	_refresh_stat_list()
	if update_status:
		_set_status("Saved %d stat definitions." % _stat_defs.size())
	return true


func _set_status(msg: String) -> void:
	if _status_lbl:
		_status_lbl.text = msg
