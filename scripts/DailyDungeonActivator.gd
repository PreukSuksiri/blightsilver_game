extends Control
# Daily Dungeon Activator — admin overlay for managing the dungeon playlist.
# Each playlist slot defines which dungeon runs on a given day and which modifiers are active.
# Open via Admin Console: dungeon_activator

const _BG_COLOR      := Color(0.05, 0.05, 0.10, 0.96)
const _PANEL_COLOR   := Color(0.10, 0.10, 0.16, 1.0)
const _HEADER_COLOR  := Color(0.12, 0.12, 0.20, 1.0)
const _ACTIVE_COLOR  := Color(0.10, 0.40, 0.20, 1.0)
const _SELECT_COLOR  := Color(0.20, 0.25, 0.45, 1.0)
const _BTN_COLOR     := Color(0.18, 0.18, 0.28, 1.0)
const _BTN_ACTIVE    := Color(0.15, 0.55, 0.30, 1.0)

var _selected_slot: int = -1   # index into DailyDungeonManager.playlist

# Right-panel widgets (rebuilt on slot selection)
var _dungeon_option:     OptionButton
var _mod_checks:         Dictionary = {}  # modifier_key → CheckBox
var _apply_btn:          Button
var _slot_label:         Label

# Left-panel list container
var _list_vbox:          VBoxContainer
var _status_label:       Label

# ─────────────────────────────────────────────────────────────
# Build UI
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP

	# Dark background
	var bg := ColorRect.new()
	bg.color = _BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Header bar
	var header := _make_panel(_HEADER_COLOR)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.custom_minimum_size = Vector2(0, 52)
	add_child(header)

	var title := Label.new()
	title.text = "Daily Dungeon Activator"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.7, 1.0, 0.85))
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)

	var close_btn := _make_button("X", Color(0.8, 0.2, 0.2))
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -48; close_btn.offset_top = 4
	close_btn.offset_right = -4; close_btn.offset_bottom = 48
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	# Main area below header
	var main := HBoxContainer.new()
	main.set_anchor(SIDE_LEFT,   0.0); main.set_anchor(SIDE_RIGHT,  1.0)
	main.set_anchor(SIDE_TOP,    0.0); main.set_anchor(SIDE_BOTTOM, 1.0)
	main.offset_top = 52; main.offset_bottom = -48
	main.add_theme_constant_override("separation", 4)
	add_child(main)

	_build_left_panel(main)
	_build_right_panel(main)

	# Status bar at bottom
	var status_bar := _make_panel(Color(0.08, 0.08, 0.12, 1.0))
	status_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status_bar.custom_minimum_size = Vector2(0, 48)
	add_child(status_bar)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
	_status_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	status_bar.add_child(_status_label)

	_refresh_list()
	_refresh_status()

# ─────────────────────────────────────────────────────────────
# Left panel — playlist list
# ─────────────────────────────────────────────────────────────

func _build_left_panel(parent: Control) -> void:
	var panel := _make_panel(_PANEL_COLOR)
	panel.custom_minimum_size = Vector2(420, 0)
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	vbox.offset_left = 6; vbox.offset_right = -6
	vbox.offset_top  = 6; vbox.offset_bottom = -6
	panel.add_child(vbox)

	# Section title
	var hdr := Label.new()
	hdr.text = "Playlist  (today = slot index shown in brackets)"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	vbox.add_child(hdr)

	# Scroll + list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 3)
	scroll.add_child(_list_vbox)

	# Bottom controls
	var sep := HSeparator.new()
	vbox.add_child(sep)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 4)
	vbox.add_child(row1)

	var add_btn := _make_button("+ Add Slot", Color(0.15, 0.45, 0.25))
	add_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	add_btn.pressed.connect(_on_add_slot)
	row1.add_child(add_btn)

	var rem_btn := _make_button("Remove", Color(0.50, 0.15, 0.15))
	rem_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	rem_btn.pressed.connect(_on_remove_slot)
	row1.add_child(rem_btn)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 4)
	vbox.add_child(row2)

	var up_btn := _make_button("Move Up", _BTN_COLOR)
	up_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	up_btn.pressed.connect(_on_move_up)
	row2.add_child(up_btn)

	var down_btn := _make_button("Move Down", _BTN_COLOR)
	down_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	down_btn.pressed.connect(_on_move_down)
	row2.add_child(down_btn)

	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 4)
	vbox.add_child(row3)

	var set_active_btn := _make_button("Set As Today's Slot", _BTN_ACTIVE)
	set_active_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	set_active_btn.pressed.connect(_on_set_active)
	row3.add_child(set_active_btn)

	var force_btn := _make_button("Force Refresh", Color(0.45, 0.30, 0.10))
	force_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	force_btn.tooltip_text = "Re-apply the current slot's modifiers to GameState immediately."
	force_btn.pressed.connect(_on_force_refresh)
	row3.add_child(force_btn)

# ─────────────────────────────────────────────────────────────
# Right panel — slot editor
# ─────────────────────────────────────────────────────────────

func _build_right_panel(parent: Control) -> void:
	var panel := _make_panel(_PANEL_COLOR)
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.size_flags_vertical   = SIZE_EXPAND_FILL
	parent.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.offset_left = 6; scroll.offset_right = -6
	scroll.offset_top  = 6; scroll.offset_bottom = -6
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	# Slot label
	_slot_label = Label.new()
	_slot_label.text = "Select a slot to edit"
	_slot_label.add_theme_font_size_override("font_size", 15)
	_slot_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	vbox.add_child(_slot_label)

	var sep0 := HSeparator.new()
	vbox.add_child(sep0)

	# Dungeon picker
	var dg_lbl := Label.new()
	dg_lbl.text = "Dungeon Layout:"
	dg_lbl.add_theme_font_size_override("font_size", 13)
	dg_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.75))
	vbox.add_child(dg_lbl)

	_dungeon_option = OptionButton.new()
	_dungeon_option.custom_minimum_size = Vector2(240, 32)
	_populate_dungeon_options()
	vbox.add_child(_dungeon_option)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	# Modifier toggles
	var mod_lbl := Label.new()
	mod_lbl.text = "Modifiers for this slot:"
	mod_lbl.add_theme_font_size_override("font_size", 13)
	mod_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.75))
	vbox.add_child(mod_lbl)

	for key: String in DailyDungeonManager.ALL_MODIFIER_KEYS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var cb := CheckBox.new()
		cb.text = DailyDungeonManager.MODIFIER_LABEL[key]
		cb.add_theme_font_size_override("font_size", 13)
		var is_positive: bool = DailyDungeonManager.MODIFIER_POSITIVE.get(key, true)
		cb.add_theme_color_override("font_color",
			Color(0.55, 1.0, 0.65) if is_positive else Color(1.0, 0.55, 0.45))
		cb.custom_minimum_size = Vector2(200, 0)
		_mod_checks[key] = cb
		row.add_child(cb)

		var desc := Label.new()
		desc.text = DailyDungeonManager.MODIFIER_DESC.get(key, "")
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(desc)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Apply button
	_apply_btn = _make_button("Apply to Selected Slot", _BTN_ACTIVE)
	_apply_btn.custom_minimum_size = Vector2(0, 36)
	_apply_btn.pressed.connect(_on_apply_to_slot)
	vbox.add_child(_apply_btn)

# ─────────────────────────────────────────────────────────────
# List refresh
# ─────────────────────────────────────────────────────────────

func _refresh_list() -> void:
	for child in _list_vbox.get_children():
		child.queue_free()

	var playlist: Array = DailyDungeonManager.playlist
	var active_idx: int = DailyDungeonManager.playlist_index

	for i: int in range(playlist.size()):
		var slot: Dictionary = playlist[i]
		var dungeon_id: String = slot.get("dungeon_id", "???")
		var mods: Array = slot.get("modifiers", [])
		var is_active: bool = (i == active_idx)
		var is_selected: bool = (i == _selected_slot)

		var row_panel := _make_panel(
			_ACTIVE_COLOR if is_active else (_SELECT_COLOR if is_selected else Color(0.13, 0.13, 0.20, 1.0)))
		row_panel.custom_minimum_size = Vector2(0, 52)
		_list_vbox.add_child(row_panel)

		var row := VBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 6; row.offset_right = -6
		row.offset_top  = 4; row.offset_bottom = -4
		row.add_theme_constant_override("separation", 2)
		row_panel.add_child(row)

		# Top line: index + dungeon id
		var top_lbl := Label.new()
		var prefix: String = "[TODAY] " if is_active else ("[%d]     " % i)
		top_lbl.text = "%s%s" % [prefix, dungeon_id]
		top_lbl.add_theme_font_size_override("font_size", 14)
		top_lbl.add_theme_color_override("font_color",
			Color(0.5, 1.0, 0.7) if is_active else Color(0.9, 0.9, 0.95))
		row.add_child(top_lbl)

		# Bottom line: modifiers summary
		var mod_text: String = "No modifiers" if mods.is_empty() else \
			", ".join(PackedStringArray(mods.map(
				func(k: String) -> String: return DailyDungeonManager.MODIFIER_LABEL.get(k, k))))
		var mod_lbl := Label.new()
		mod_lbl.text = mod_text
		mod_lbl.add_theme_font_size_override("font_size", 11)
		mod_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.6))
		row.add_child(mod_lbl)

		# Click to select
		var btn := Button.new()
		btn.flat = true
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		var captured_i: int = i
		btn.pressed.connect(func() -> void: _select_slot(captured_i))
		row_panel.add_child(btn)

func _refresh_status() -> void:
	var current_id: String = DailyDungeonManager.get_current_dungeon_id()
	var mods: Array = DailyDungeonManager.active_modifiers
	var mod_str: String = "none" if mods.is_empty() else \
		", ".join(PackedStringArray(mods.map(
			func(k: String) -> String: return DailyDungeonManager.MODIFIER_LABEL.get(k, k))))
	_status_label.text = "Today: %s  |  Modifiers: %s  |  Playlist size: %d" % [
		current_id, mod_str, DailyDungeonManager.playlist.size()]

# ─────────────────────────────────────────────────────────────
# Slot selection + right-panel population
# ─────────────────────────────────────────────────────────────

func _select_slot(idx: int) -> void:
	_selected_slot = idx
	_refresh_list()

	var playlist: Array = DailyDungeonManager.playlist
	if idx < 0 or idx >= playlist.size():
		_slot_label.text = "Select a slot to edit"
		_clear_right_panel()
		return

	var slot: Dictionary = playlist[idx]
	var is_active: bool  = (idx == DailyDungeonManager.playlist_index)
	_slot_label.text = "Editing slot %d — %s%s" % [
		idx, slot.get("dungeon_id", "???"),
		"  [TODAY]" if is_active else ""]

	# Set dungeon option
	var dungeon_id: String = slot.get("dungeon_id", "")
	for i: int in range(_dungeon_option.item_count):
		if _dungeon_option.get_item_text(i) == dungeon_id:
			_dungeon_option.selected = i
			break

	# Set modifier checkboxes
	var mods: Array = slot.get("modifiers", [])
	for key: String in _mod_checks:
		_mod_checks[key].button_pressed = key in mods

func _clear_right_panel() -> void:
	for key: String in _mod_checks:
		_mod_checks[key].button_pressed = false

func _populate_dungeon_options() -> void:
	_dungeon_option.clear()
	var ids: Array = DailyDungeonManager.get_all_layout_ids()
	ids.sort()
	for id: String in ids:
		_dungeon_option.add_item(id)
	if _dungeon_option.item_count == 0:
		_dungeon_option.add_item("(no layouts found)")

# ─────────────────────────────────────────────────────────────
# Button handlers
# ─────────────────────────────────────────────────────────────

func _on_apply_to_slot() -> void:
	if _selected_slot < 0 or _selected_slot >= DailyDungeonManager.playlist.size():
		return
	# Collect selected dungeon
	var dungeon_id: String = ""
	if _dungeon_option.selected >= 0:
		dungeon_id = _dungeon_option.get_item_text(_dungeon_option.selected)
	# Collect modifiers
	var mods: Array = []
	for key: String in DailyDungeonManager.ALL_MODIFIER_KEYS:
		if _mod_checks[key].button_pressed:
			mods.append(key)
	# Write dungeon_id directly
	DailyDungeonManager.playlist[_selected_slot]["dungeon_id"] = dungeon_id
	DailyDungeonManager.set_slot_modifiers(_selected_slot, mods)
	_refresh_list()
	_refresh_status()

func _on_add_slot() -> void:
	var ids: Array = DailyDungeonManager.get_all_layout_ids()
	var default_id: String = ids[0] if not ids.is_empty() else "dungeon_grove"
	DailyDungeonManager.add_playlist_slot(default_id)
	_selected_slot = DailyDungeonManager.playlist.size() - 1
	_refresh_list()
	_select_slot(_selected_slot)
	_refresh_status()

func _on_remove_slot() -> void:
	if _selected_slot < 0 or DailyDungeonManager.playlist.size() <= 1:
		return
	DailyDungeonManager.remove_playlist_slot(_selected_slot)
	_selected_slot = clampi(_selected_slot, 0, DailyDungeonManager.playlist.size() - 1)
	_refresh_list()
	_select_slot(_selected_slot)
	_refresh_status()

func _on_move_up() -> void:
	if _selected_slot <= 0:
		return
	DailyDungeonManager.move_playlist_slot(_selected_slot, _selected_slot - 1)
	_selected_slot -= 1
	_refresh_list()
	_refresh_status()

func _on_move_down() -> void:
	if _selected_slot < 0 or _selected_slot >= DailyDungeonManager.playlist.size() - 1:
		return
	DailyDungeonManager.move_playlist_slot(_selected_slot, _selected_slot + 1)
	_selected_slot += 1
	_refresh_list()
	_refresh_status()

func _on_set_active() -> void:
	if _selected_slot < 0:
		return
	DailyDungeonManager.set_playlist_index(_selected_slot)
	_refresh_list()
	_refresh_status()

func _on_force_refresh() -> void:
	# Re-apply the current slot's modifiers to GameState immediately.
	var idx: int = DailyDungeonManager.playlist_index
	if idx < 0 or idx >= DailyDungeonManager.playlist.size():
		return
	var slot: Dictionary = DailyDungeonManager.playlist[idx]
	var mods: Array = slot.get("modifiers", [])
	DailyDungeonManager.set_slot_modifiers(idx, mods)
	GameState.active_dungeon_modifiers = DailyDungeonManager.active_modifiers.duplicate()
	GameState.dungeon_affinity_day_affinity = DailyDungeonManager.affinity_day_affinity
	GameState.dungeon_affinity_day_stat     = DailyDungeonManager.affinity_day_stat
	_refresh_status()

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────

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
