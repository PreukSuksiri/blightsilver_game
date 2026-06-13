extends Control
# In-game Tutorial Battle Builder overlay.
# Launched via admin command "tutorial_battle".
# Lets you create/edit tutorial config JSON and launch a tutorial battle.

const SAVE_DIR := "res://data/tutorial_battles/"
const STARTING_DECK_PATH := "res://data/starting_deck.json"
const GRID_SIZE := 5

# ── UI refs ────────────────────────────────────────────────────
var _file_list: ItemList
var _file_name_edit: LineEdit
var _title_edit: LineEdit
var _on_complete_btn: OptionButton
var _portrait_p1_edit: LineEdit = null
var _portrait_p2_edit: LineEdit = null
var _player_deck_section: VBoxContainer
var _ai_deck_section: VBoxContainer
var _player_grid_btns: Array = []   # Array[Array[Button]] [row][col]
var _ai_grid_btns: Array = []
var _deck_lists: Dictionary = {}    # "player:characters" → ItemList
var _missions_vbox: VBoxContainer
var _status_lbl: Label

# ── Working config ─────────────────────────────────────────────
var _cfg: Dictionary = {}   # full config being edited
var _current_file: String = ""

# For card picker popup
var _picker_callback: Callable = Callable()
var _picker_popup: Window = null

# For cell picker popup
var _cell_popup: Window = null
var _cell_callback: Callable = Callable()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 200
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_dir()
	_build_ui()
	_refresh_file_list()
	_new_config()
	call_deferred("_apply_fullscreen_layout")

func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SAVE_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))

# ─────────────────────────────────────────────────────────────
# UI Build
# ─────────────────────────────────────────────────────────────

func _apply_fullscreen_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp: Vector2 = get_viewport_rect().size
	size = vp
	position = Vector2.ZERO

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.12, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	var root_hbox := HBoxContainer.new()
	root_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_hbox.add_theme_constant_override("separation", 0)
	add_child(root_hbox)

	# ── Left panel: file list ──────────────────────────────────
	var left_wrap := PanelContainer.new()
	left_wrap.custom_minimum_size = Vector2(240, 0)
	left_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left_sb := StyleBoxFlat.new()
	left_sb.bg_color = Color(0.07, 0.07, 0.09, 1.0)
	left_wrap.add_theme_stylebox_override("panel", left_sb)
	root_hbox.add_child(left_wrap)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	left_wrap.add_child(left)

	var lhdr := Label.new(); lhdr.text = "Tutorial Files"
	lhdr.add_theme_font_size_override("font_size", 14)
	lhdr.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	var lhdr_margin := MarginContainer.new()
	lhdr_margin.add_theme_constant_override("margin_top", 8)
	lhdr_margin.add_theme_constant_override("margin_left", 8)
	lhdr_margin.add_child(lhdr)
	left.add_child(lhdr_margin)

	_file_list = ItemList.new()
	_file_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_file_list.item_selected.connect(_on_file_selected)
	left.add_child(_file_list)

	var file_btns := HBoxContainer.new()
	file_btns.add_theme_constant_override("separation", 4)
	left.add_child(file_btns)
	_add_margin(file_btns)

	var new_btn := _small_btn("New")
	new_btn.pressed.connect(_new_config)
	file_btns.add_child(new_btn)

	var del_btn := _small_btn("Del")
	del_btn.pressed.connect(_delete_file)
	file_btns.add_child(del_btn)

	var save_btn := _small_btn("Save")
	save_btn.pressed.connect(_save_file)
	file_btns.add_child(save_btn)

	_file_name_edit = LineEdit.new()
	_file_name_edit.placeholder_text = "filename (no .json)"
	_file_name_edit.custom_minimum_size = Vector2(0, 30)
	var fn_margin := MarginContainer.new()
	fn_margin.add_theme_constant_override("margin_left", 6)
	fn_margin.add_theme_constant_override("margin_right", 6)
	fn_margin.add_child(_file_name_edit)
	left.add_child(fn_margin)

	var play_btn := Button.new()
	play_btn.text = "▶ START BATTLE"
	play_btn.add_theme_font_size_override("font_size", 14)
	play_btn.pressed.connect(_start_battle)
	var play_margin := MarginContainer.new()
	play_margin.add_theme_constant_override("margin_left", 6)
	play_margin.add_theme_constant_override("margin_right", 6)
	play_margin.add_theme_constant_override("margin_bottom", 8)
	play_margin.add_child(play_btn)
	left.add_child(play_margin)

	var close_btn := Button.new()
	close_btn.text = "✕ Close"
	close_btn.add_theme_font_override("font", FontManager.ui_font(400))
	close_btn.pressed.connect(queue_free)
	var close_margin := MarginContainer.new()
	close_margin.add_theme_constant_override("margin_left", 6)
	close_margin.add_theme_constant_override("margin_right", 6)
	close_margin.add_theme_constant_override("margin_bottom", 6)
	close_margin.add_child(close_btn)
	left.add_child(close_margin)

	_status_lbl = Label.new()
	_status_lbl.add_theme_font_size_override("font_size", 12)
	_status_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var st_margin := MarginContainer.new()
	st_margin.add_theme_constant_override("margin_left", 6)
	st_margin.add_child(_status_lbl)
	left.add_child(st_margin)

	# ── Divider ────────────────────────────────────────────────
	var div := VSeparator.new()
	root_hbox.add_child(div)

	# ── Right panel: editor ────────────────────────────────────
	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_hbox.add_child(right_scroll)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	var right_margin := MarginContainer.new()
	right_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_margin.add_theme_constant_override("margin_left", 12)
	right_margin.add_theme_constant_override("margin_right", 12)
	right_margin.add_theme_constant_override("margin_top", 10)
	right_margin.add_theme_constant_override("margin_bottom", 10)
	right_margin.add_child(right)
	right_scroll.add_child(right_margin)

	_build_settings_section(right)
	_build_deck_section(right, "PLAYER DECK & FORMATION", true)
	_build_deck_section(right, "AI DECK & FORMATION", false)
	_build_missions_section(right)

func _add_margin(node: Node) -> void:
	if node is Control:
		(node as Control).add_theme_constant_override("margin_left", 6) if node is MarginContainer else null

func _build_settings_section(parent: VBoxContainer) -> void:
	_section_header(parent, "BATTLE SETTINGS")
	var grid := GridContainer.new(); grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(grid)

	_row_label(grid, "Title:")
	_title_edit = LineEdit.new()
	_title_edit.placeholder_text = "My Tutorial Battle"
	_title_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_edit.text_changed.connect(func(v: String) -> void: _cfg["title"] = v)
	grid.add_child(_title_edit)

	_row_label(grid, "After missions:")
	_on_complete_btn = OptionButton.new()
	_on_complete_btn.add_item("End Immediately", 0)
	_on_complete_btn.add_item("Continue Normal Battle", 1)
	_on_complete_btn.item_selected.connect(func(idx: int) -> void:
		_cfg["on_complete"] = "end_immediately" if idx == 0 else "continue_normal")
	grid.add_child(_on_complete_btn)

	_section_header(parent, "BATTLE PORTRAITS")
	_portrait_p1_edit = _add_portrait_row(parent, "Player 1 illustration", "portrait_p1")
	_portrait_p2_edit = _add_portrait_row(parent, "Player 2 illustration", "portrait_p2")

func _add_portrait_row(parent: VBoxContainer, label_text: String, cfg_key: String) -> LineEdit:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	parent.add_child(lbl)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	var edit := LineEdit.new()
	edit.placeholder_text = "res://assets/textures/ui/portraits/..."
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(func(v: String) -> void:
		var trimmed: String = v.strip_edges()
		if trimmed.is_empty():
			_cfg.erase(cfg_key)
		else:
			_cfg[cfg_key] = trimmed)
	row.add_child(edit)

	var browse_btn := _small_btn("...")
	browse_btn.custom_minimum_size = Vector2(36, 0)
	browse_btn.pressed.connect(func() -> void:
		_open_portrait_dialog(func(path: String) -> void: edit.text = path))
	row.add_child(browse_btn)
	return edit

func _open_portrait_dialog(on_selected: Callable) -> void:
	var fd := FileDialog.new()
	fd.access = FileDialog.ACCESS_RESOURCES
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Image Files"])
	fd.min_size = Vector2i(820, 520)
	fd.title = "Select Portrait"
	add_child(fd)
	fd.file_selected.connect(func(path: String) -> void:
		on_selected.call(path)
		fd.queue_free())
	fd.canceled.connect(fd.queue_free)
	fd.popup_centered_ratio(0.6)

func _build_deck_section(parent: VBoxContainer, header: String, is_player: bool) -> void:
	_section_header(parent, header)

	if is_player:
		var starter_row := HBoxContainer.new()
		starter_row.add_theme_constant_override("separation", 6)
		parent.add_child(starter_row)
		var starter_btn := _small_btn("Load Starter Deck")
		starter_btn.pressed.connect(_apply_starter_deck_to_player)
		starter_row.add_child(starter_btn)
		var starter_hint := Label.new()
		starter_hint.text = "Clone cards + formation from manage_starting_deck"
		starter_hint.add_theme_font_size_override("font_size", 11)
		starter_hint.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55))
		starter_row.add_child(starter_hint)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	parent.add_child(outer)

	if is_player:
		_player_deck_section = outer
	else:
		_ai_deck_section = outer

	# Characters
	_build_card_list_row(outer, "Characters", is_player, "characters")
	# Traps
	_build_card_list_row(outer, "Traps", is_player, "traps")
	# Tech (exactly 3)
	_build_card_list_row(outer, "Tech (3)", is_player, "techs")

	# Formation grid
	var form_lbl := Label.new()
	form_lbl.text = "Formation (5×5):"
	form_lbl.add_theme_font_size_override("font_size", 13)
	outer.add_child(form_lbl)

	var grid_vbox := VBoxContainer.new()
	grid_vbox.add_theme_constant_override("separation", 2)
	outer.add_child(grid_vbox)

	var grid_btns: Array = []
	for r in range(GRID_SIZE):
		var row_hbox := HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 2)
		grid_vbox.add_child(row_hbox)
		var row_arr: Array = []
		for c in range(GRID_SIZE):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(110, 36)
			btn.clip_text = true
			btn.add_theme_font_size_override("font_size", 11)
			var snap_r := r; var snap_c := c; var snap_is_p := is_player
			btn.pressed.connect(func() -> void: _open_cell_picker(snap_is_p, snap_r, snap_c))
			row_hbox.add_child(btn)
			row_arr.append(btn)
		grid_btns.append(row_arr)

	if is_player:
		_player_grid_btns = grid_btns
	else:
		_ai_grid_btns = grid_btns

func _deck_list_key(is_player: bool, deck_key: String) -> String:
	return ("%s:%s" % ["player" if is_player else "ai", deck_key])

func _build_card_list_row(parent: VBoxContainer, label: String, is_player: bool, deck_key: String) -> void:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 4)
	parent.add_child(block)

	var hbox := HBoxContainer.new()
	block.add_child(hbox)
	var lbl := Label.new(); lbl.text = label + ":"
	lbl.custom_minimum_size = Vector2(100, 0)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	hbox.add_child(lbl)
	var add_btn := _small_btn("+ Add")
	var snap_ip := is_player; var snap_dk := deck_key
	add_btn.pressed.connect(func() -> void: _open_card_picker(snap_ip, snap_dk))
	hbox.add_child(add_btn)
	var remove_btn := _small_btn("− Remove")
	remove_btn.pressed.connect(func() -> void: _remove_selected_card(snap_ip, snap_dk))
	hbox.add_child(remove_btn)
	var clear_btn := _small_btn("Clear All")
	clear_btn.pressed.connect(func() -> void:
		var dk: Dictionary = _get_side_deck(snap_ip)
		dk[snap_dk] = []
		_refresh_ui_from_cfg())
	hbox.add_child(clear_btn)

	var card_list := ItemList.new()
	card_list.custom_minimum_size = Vector2(0, 88)
	card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_list.add_theme_font_size_override("font_size", 12)
	_deck_lists[_deck_list_key(is_player, deck_key)] = card_list
	block.add_child(card_list)

func _build_missions_section(parent: VBoxContainer) -> void:
	_section_header(parent, "MISSIONS (by player turn)")

	var add_turn_btn := Button.new()
	add_turn_btn.text = "+ Add Turn"
	add_turn_btn.pressed.connect(_add_turn)
	parent.add_child(add_turn_btn)

	_missions_vbox = VBoxContainer.new()
	_missions_vbox.add_theme_constant_override("separation", 8)
	parent.add_child(_missions_vbox)

# ─────────────────────────────────────────────────────────────
# Config Helpers
# ─────────────────────────────────────────────────────────────

func _get_side_deck(is_player: bool) -> Dictionary:
	if is_player:
		if not _cfg.has("player_deck"):
			_cfg["player_deck"] = {"characters": [], "traps": [], "techs": []}
		return _cfg["player_deck"]
	else:
		if not _cfg.has("ai_deck"):
			_cfg["ai_deck"] = {"characters": [], "traps": [], "techs": []}
		return _cfg["ai_deck"]

func _get_side_formation(is_player: bool) -> Array:
	var key := "player_formation" if is_player else "ai_formation"
	if not _cfg.has(key):
		_cfg[key] = []
	return _cfg[key]

func _get_cell_placement(is_player: bool, row: int, col: int) -> String:
	for entry in _get_side_formation(is_player):
		if entry.get("row", -1) == row and entry.get("col", -1) == col:
			return str(entry.get("card_name", ""))
	return ""

func _set_cell_placement(is_player: bool, row: int, col: int, card_name: String) -> void:
	var formation := _get_side_formation(is_player)
	for i in range(formation.size()):
		if formation[i].get("row", -1) == row and formation[i].get("col", -1) == col:
			if card_name.is_empty():
				formation.remove_at(i)
			else:
				formation[i]["card_name"] = card_name
			return
	if not card_name.is_empty():
		formation.append({"card_name": card_name, "row": row, "col": col})

# ─────────────────────────────────────────────────────────────
# File Management
# ─────────────────────────────────────────────────────────────

func _refresh_file_list() -> void:
	_file_list.clear()
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			_file_list.add_item(fname.trim_suffix(".json"))
		fname = dir.get_next()
	dir.list_dir_end()

func _on_file_selected(idx: int) -> void:
	var fname: String = _file_list.get_item_text(idx)
	_file_name_edit.text = fname
	_current_file = fname
	_load_file(fname)

func _load_file(fname: String) -> void:
	var path := SAVE_DIR + fname + ".json"
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		_set_status("Could not open: " + fname)
		return
	var parsed: Variant = JSON.parse_string(fa.get_as_text())
	fa.close()
	if not (parsed is Dictionary):
		_set_status("Invalid JSON in: " + fname)
		return
	_cfg = parsed as Dictionary
	_refresh_ui_from_cfg()
	_set_status("Loaded: " + fname)

func _save_file() -> void:
	_collect_config_from_ui()
	var fname := _file_name_edit.text.strip_edges()
	if fname.is_empty():
		_set_status("Enter a filename first.")
		return
	fname = fname.replace("/", "_").replace("\\", "_")
	var path := SAVE_DIR + fname + ".json"
	var fa := FileAccess.open(path, FileAccess.WRITE)
	if fa == null:
		_set_status("Cannot write to: " + path)
		return
	fa.store_string(JSON.stringify(_cfg, "\t"))
	fa.close()
	_current_file = fname
	_refresh_file_list()
	_set_status("Saved: " + fname)

func _delete_file() -> void:
	var fname := _file_name_edit.text.strip_edges()
	if fname.is_empty():
		return
	var path := SAVE_DIR + fname + ".json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_new_config()
	_refresh_file_list()
	_set_status("Deleted: " + fname)

func _new_config() -> void:
	_current_file = ""
	_file_name_edit.text = ""
	var starter: Dictionary = _load_starter_deck_for_tutorial()
	_cfg = {
		"title": "",
		"on_complete": "end_immediately",
		"player_deck": starter.get("player_deck", {"characters": [], "traps": [], "techs": []}),
		"player_formation": starter.get("player_formation", []),
		"ai_deck": {"characters": [], "traps": [], "techs": []},
		"ai_formation": [],
		"turns": {}
	}
	_refresh_ui_from_cfg()

func _apply_starter_deck_to_player() -> void:
	var starter: Dictionary = _load_starter_deck_for_tutorial()
	_cfg["player_deck"] = starter.get("player_deck", {"characters": [], "traps": [], "techs": []})
	_cfg["player_formation"] = starter.get("player_formation", [])
	_refresh_ui_from_cfg()
	_set_status("Player deck cloned from starter deck.")

func _load_starter_deck_for_tutorial() -> Dictionary:
	var empty_deck: Dictionary = {"characters": [], "traps": [], "techs": []}
	if not FileAccess.file_exists(STARTING_DECK_PATH):
		return {"player_deck": empty_deck.duplicate(true), "player_formation": []}
	var f := FileAccess.open(STARTING_DECK_PATH, FileAccess.READ)
	if f == null:
		return {"player_deck": empty_deck.duplicate(true), "player_formation": []}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Dictionary:
		return {"player_deck": empty_deck.duplicate(true), "player_formation": []}
	var d: Dictionary = parsed as Dictionary
	var player_deck: Dictionary = {
		"characters": (d.get("characters", []) as Array).duplicate(),
		"traps": (d.get("traps", []) as Array).duplicate(),
		"techs": (d.get("techs", []) as Array).duplicate(),
	}
	var formation: Array = []
	var formations: Variant = d.get("formations", [])
	if formations is Array and not (formations as Array).is_empty():
		var first: Variant = (formations as Array)[0]
		if first is Dictionary:
			for placement: Variant in (first as Dictionary).get("placements", []):
				if not placement is Dictionary:
					continue
				var pd: Dictionary = placement as Dictionary
				var card_name: String = str(pd.get("name", "")).strip_edges()
				if card_name.is_empty():
					continue
				formation.append({
					"card_name": card_name,
					"row": int(pd.get("r", 0)),
					"col": int(pd.get("c", 0)),
				})
	return {"player_deck": player_deck, "player_formation": formation}

# ─────────────────────────────────────────────────────────────
# UI ↔ Config Sync
# ─────────────────────────────────────────────────────────────

func _refresh_ui_from_cfg() -> void:
	_title_edit.text = _cfg.get("title", "")
	var oc: String = _cfg.get("on_complete", "end_immediately")
	_on_complete_btn.select(0 if oc == "end_immediately" else 1)
	if _portrait_p1_edit != null:
		_portrait_p1_edit.text = str(_cfg.get("portrait_p1", ""))
	if _portrait_p2_edit != null:
		_portrait_p2_edit.text = str(_cfg.get("portrait_p2", ""))

	_refresh_deck_labels(true)
	_refresh_deck_labels(false)
	_refresh_formation_grid(true)
	_refresh_formation_grid(false)
	_rebuild_missions_ui()

func _refresh_deck_labels(is_player: bool) -> void:
	var deck: Dictionary = _get_side_deck(is_player)
	for deck_key: String in ["characters", "traps", "techs"]:
		var list: ItemList = _deck_lists.get(_deck_list_key(is_player, deck_key)) as ItemList
		if list == null:
			continue
		list.clear()
		var cards: Array = deck.get(deck_key, [])
		if cards.is_empty():
			list.add_item("(empty — click + Add)")
			list.set_item_custom_fg_color(0, Color(0.45, 0.48, 0.55))
		else:
			for card_name: Variant in cards:
				list.add_item(str(card_name))

func _refresh_formation_grid(is_player: bool) -> void:
	var grid_btns: Array = _player_grid_btns if is_player else _ai_grid_btns
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			var placed := _get_cell_placement(is_player, r, c)
			var btn: Button = grid_btns[r][c]
			if placed.is_empty():
				btn.text = "R%dC%d\n+" % [r, c]
				btn.modulate = Color(0.6, 0.6, 0.6)
			else:
				btn.text = placed
				btn.modulate = Color(1, 1, 1)

func _collect_config_from_ui() -> void:
	_cfg["title"] = _title_edit.text
	# on_complete is already updated via signal
	# Turns are already updated via inline editing
	if _portrait_p1_edit != null:
		var p1: String = _portrait_p1_edit.text.strip_edges()
		if p1.is_empty():
			_cfg.erase("portrait_p1")
		else:
			_cfg["portrait_p1"] = p1
	if _portrait_p2_edit != null:
		var p2: String = _portrait_p2_edit.text.strip_edges()
		if p2.is_empty():
			_cfg.erase("portrait_p2")
		else:
			_cfg["portrait_p2"] = p2

# ─────────────────────────────────────────────────────────────
# Card Picker Popup
# ─────────────────────────────────────────────────────────────

func _open_card_picker(is_player: bool, deck_key: String) -> void:
	if _picker_popup != null:
		_picker_popup.queue_free()

	var popup := Window.new()
	popup.title = "Pick Card — " + deck_key
	popup.size = Vector2i(420, 520)
	popup.wrap_controls = true
	add_child(popup)
	_picker_popup = popup

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	popup.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var search := LineEdit.new()
	search.placeholder_text = "Search cards..."
	vbox.add_child(search)

	var picker_list := ItemList.new()
	picker_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker_list.allow_reselect = true
	vbox.add_child(picker_list)

	var names: Array = []
	match deck_key:
		"characters":
			names = CardDatabase.get_all_character_names()
		"traps":
			names = CardDatabase.get_all_trap_names()
		"techs":
			names = CardDatabase.get_all_tech_names()
	names.sort()

	var all_names: Array[String] = []
	for entry: Variant in names:
		all_names.append(str(entry))

	var refill := func(filter: String) -> void:
		picker_list.clear()
		var q: String = filter.strip_edges().to_lower()
		for card_name: String in all_names:
			if q.is_empty() or q in card_name.to_lower():
				picker_list.add_item(card_name)

	refill.call("")
	search.text_changed.connect(func(q: String) -> void: refill.call(q))

	var snap_ip := is_player
	var snap_dk := deck_key
	picker_list.item_selected.connect(func(idx: int) -> void:
		if idx < 0:
			return
		_add_card_to_deck(snap_ip, snap_dk, picker_list.get_item_text(idx))
		popup.queue_free())

	popup.popup_centered()
	popup.close_requested.connect(popup.queue_free)

func _add_card_to_deck(is_player: bool, deck_key: String, card_name: String) -> void:
	var deck: Dictionary = _get_side_deck(is_player)
	var arr: Array = deck.get(deck_key, [])
	arr.append(card_name)
	deck[deck_key] = arr
	_refresh_deck_labels(is_player)
	_set_status("Added %s to %s" % [card_name, deck_key])

func _remove_selected_card(is_player: bool, deck_key: String) -> void:
	var list: ItemList = _deck_lists.get(_deck_list_key(is_player, deck_key)) as ItemList
	if list == null:
		return
	var selected: PackedInt32Array = list.get_selected_items()
	if selected.is_empty():
		_set_status("Select a card to remove.")
		return
	var idx: int = selected[0]
	if list.get_item_text(idx) == "(empty — click + Add)":
		_set_status("No cards to remove.")
		return
	var deck: Dictionary = _get_side_deck(is_player)
	var arr: Array = deck.get(deck_key, [])
	if idx < 0 or idx >= arr.size():
		_set_status("Could not remove card — list out of sync. Refreshing.")
		_refresh_ui_from_cfg()
		return
	var removed: String = str(arr[idx])
	arr.remove_at(idx)
	deck[deck_key] = arr
	if not _card_still_in_deck(is_player, removed):
		_purge_formation_card(is_player, removed)
	_refresh_ui_from_cfg()
	_set_status("Removed %s from %s." % [removed, deck_key])

func _card_still_in_deck(is_player: bool, card_name: String) -> bool:
	var deck: Dictionary = _get_side_deck(is_player)
	for key: String in ["characters", "traps", "techs"]:
		for entry: Variant in deck.get(key, []):
			if str(entry) == card_name:
				return true
	return false

func _purge_formation_card(is_player: bool, card_name: String) -> void:
	var formation: Array = _get_side_formation(is_player)
	for i: int in range(formation.size() - 1, -1, -1):
		if str((formation[i] as Dictionary).get("card_name", "")) == card_name:
			formation.remove_at(i)

# ─────────────────────────────────────────────────────────────
# Cell Picker Popup
# ─────────────────────────────────────────────────────────────

func _open_cell_picker(is_player: bool, row: int, col: int) -> void:
	if _cell_popup != null:
		_cell_popup.queue_free()

	var popup := Window.new()
	popup.title = "Cell R%dC%d — %s" % [row, col, "Player" if is_player else "AI"]
	popup.size = Vector2i(300, 420)
	popup.wrap_controls = true
	add_child(popup)
	_cell_popup = popup

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	popup.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var cur_lbl := Label.new()
	var cur := _get_cell_placement(is_player, row, col)
	cur_lbl.text = "Current: " + (cur if not cur.is_empty() else "(empty)")
	vbox.add_child(cur_lbl)

	var clear_btn := Button.new()
	clear_btn.text = "Clear Cell"
	var snap_ip := is_player; var snap_r := row; var snap_c := col
	clear_btn.pressed.connect(func() -> void:
		_set_cell_placement(snap_ip, snap_r, snap_c, "")
		_refresh_formation_grid(snap_ip)
		popup.queue_free())
	vbox.add_child(clear_btn)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var lbl := Label.new(); lbl.text = "Place card from deck:"
	vbox.add_child(lbl)

	var cell_list := ItemList.new()
	cell_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell_list.allow_reselect = true
	vbox.add_child(cell_list)

	var deck: Dictionary = _get_side_deck(is_player)
	var all_cards: Array = []
	all_cards.append_array(deck.get("characters", []))
	all_cards.append_array(deck.get("traps", []))
	all_cards.sort()
	all_cards = _dedup(all_cards)

	if all_cards.is_empty():
		cell_list.add_item("(deck empty — add cards first)")
		cell_list.set_item_custom_fg_color(0, Color(0.45, 0.48, 0.55))
	else:
		for n: Variant in all_cards:
			cell_list.add_item(str(n))

	cell_list.item_selected.connect(func(idx: int) -> void:
		if idx < 0:
			return
		if all_cards.is_empty():
			return
		_set_cell_placement(snap_ip, snap_r, snap_c, cell_list.get_item_text(idx))
		_refresh_formation_grid(snap_ip)
		popup.queue_free())

	popup.popup_centered()
	popup.close_requested.connect(popup.queue_free)

func _dedup(arr: Array) -> Array:
	var seen: Dictionary = {}
	var out: Array = []
	for v in arr:
		if not seen.has(v):
			seen[v] = true
			out.append(v)
	return out

# ─────────────────────────────────────────────────────────────
# Missions UI
# ─────────────────────────────────────────────────────────────

func _move_mission(turn_key: String, from_idx: int, to_idx: int) -> void:
	if not _cfg.has("turns"):
		return
	var missions: Array = _cfg["turns"].get(turn_key, [])
	if from_idx < 0 or from_idx >= missions.size():
		return
	if to_idx < 0 or to_idx >= missions.size() or from_idx == to_idx:
		return
	var item: Variant = missions[from_idx]
	missions.remove_at(from_idx)
	missions.insert(to_idx, item)
	_rebuild_missions_ui()

func _add_turn() -> void:
	if not _cfg.has("turns"):
		_cfg["turns"] = {}
	var turns: Dictionary = _cfg["turns"]
	var max_t := 0
	for k in turns.keys():
		max_t = maxi(max_t, int(k))
	var new_key := str(max_t + 1)
	turns[new_key] = []
	_rebuild_missions_ui()

func _rebuild_missions_ui() -> void:
	for c in _missions_vbox.get_children():
		c.queue_free()

	if not _cfg.has("turns"):
		_cfg["turns"] = {}
	var turns: Dictionary = _cfg["turns"]

	var sorted_keys: Array = turns.keys().map(func(k): return int(k))
	sorted_keys.sort()

	for tk in sorted_keys:
		var key := str(tk)
		var mission_arr: Array = turns.get(key, [])
		_build_turn_row(_missions_vbox, key, mission_arr)

func _build_turn_row(parent: VBoxContainer, turn_key: String, missions: Array) -> void:
	var turn_vbox := VBoxContainer.new()
	turn_vbox.add_theme_constant_override("separation", 4)
	parent.add_child(turn_vbox)

	var hdr_hbox := HBoxContainer.new()
	turn_vbox.add_child(hdr_hbox)

	var hdr_lbl := Label.new()
	hdr_lbl.text = "Player Turn %s" % turn_key
	hdr_lbl.add_theme_font_size_override("font_size", 14)
	hdr_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	hdr_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_hbox.add_child(hdr_lbl)

	var del_turn_btn := _small_btn("Del Turn")
	var snap_key := turn_key
	del_turn_btn.pressed.connect(func() -> void:
		_cfg["turns"].erase(snap_key)
		_rebuild_missions_ui())
	hdr_hbox.add_child(del_turn_btn)

	var add_m_btn := _small_btn("+ Mission")
	add_m_btn.pressed.connect(func() -> void:
		_cfg["turns"][snap_key].append({"type": "end_turn", "instruction": ""})
		_rebuild_missions_ui())
	hdr_hbox.add_child(add_m_btn)

	var sep := HSeparator.new()
	turn_vbox.add_child(sep)

	for i in range(missions.size()):
		_build_mission_row(turn_vbox, snap_key, i)

func _build_mission_row(parent: VBoxContainer, turn_key: String, idx: int) -> void:
	var missions: Array = _cfg["turns"].get(turn_key, [])
	if idx >= missions.size():
		return
	var m: Dictionary = missions[idx]

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	# Type dropdown
	var type_btn := OptionButton.new()
	type_btn.custom_minimum_size = Vector2(130, 0)
	for mt in _mission_types():
		type_btn.add_item(mt)
	var cur_type: String = m.get("type", "end_turn")
	type_btn.select(_mission_types().find(cur_type))
	var snap_key := turn_key; var snap_idx := idx
	type_btn.item_selected.connect(func(sel: int) -> void:
		_cfg["turns"][snap_key][snap_idx]["type"] = _mission_types()[sel]
		_rebuild_missions_ui())
	row.add_child(type_btn)

	# Param field
	_add_mission_param_fields(row, turn_key, idx, m)

	# Instruction field
	var instr_edit := LineEdit.new()
	instr_edit.placeholder_text = "Instruction text..."
	instr_edit.custom_minimum_size = Vector2(200, 0)
	instr_edit.text = m.get("instruction", "")
	instr_edit.text_changed.connect(func(v: String) -> void:
		_cfg["turns"][snap_key][snap_idx]["instruction"] = v)
	row.add_child(instr_edit)

	var up_btn := _small_btn("Up")
	up_btn.disabled = idx == 0
	up_btn.pressed.connect(func() -> void:
		_move_mission(snap_key, snap_idx, snap_idx - 1))
	row.add_child(up_btn)

	var down_btn := _small_btn("Down")
	down_btn.disabled = idx >= missions.size() - 1
	down_btn.pressed.connect(func() -> void:
		_move_mission(snap_key, snap_idx, snap_idx + 1))
	row.add_child(down_btn)

	# Remove button
	var del_btn := _small_btn("✕")
	del_btn.add_theme_font_override("font", FontManager.ui_font(400))
	del_btn.pressed.connect(func() -> void:
		_cfg["turns"][snap_key].remove_at(snap_idx)
		_rebuild_missions_ui())
	row.add_child(del_btn)

func _add_mission_param_fields(row: HBoxContainer, turn_key: String, idx: int, m: Dictionary) -> void:
	var mtype: String = m.get("type", "")
	var snap_key := turn_key; var snap_idx := idx

	match mtype:
		"show_message":
			var edit := _param_edit(m, "message", "Message text")
			edit.custom_minimum_size = Vector2(220, 0)
			edit.text_changed.connect(func(v: String) -> void:
				_cfg["turns"][snap_key][snap_idx]["message"] = v)
			row.add_child(edit)

		"wait":
			var edit := _param_edit(m, "seconds", "Seconds")
			edit.custom_minimum_size = Vector2(56, 0)
			if not str(m.get("seconds", "")).is_valid_float():
				edit.text = "1"
			edit.text_changed.connect(func(v: String) -> void:
				_cfg["turns"][snap_key][snap_idx]["seconds"] = float(v) if v.is_valid_float() else 1.0)
			row.add_child(edit)

		"attack", "bluff", "tap_card":
			var edit := _param_edit(m, "card_name", "Card name")
			edit.text_changed.connect(func(v: String) -> void:
				_cfg["turns"][snap_key][snap_idx]["card_name"] = v)
			row.add_child(edit)
			if mtype == "tap_card":
				_add_side_picker(row, snap_key, snap_idx, m)

		"union_summon":
			var edit := _param_edit(m, "union_name", "Union name")
			edit.text_changed.connect(func(v: String) -> void:
				_cfg["turns"][snap_key][snap_idx]["union_name"] = v)
			row.add_child(edit)

		"use_tech", "tap_tech":
			var edit := _param_edit(m, "tech_name", "Tech name")
			edit.text_changed.connect(func(v: String) -> void:
				_cfg["turns"][snap_key][snap_idx]["tech_name"] = v)
			row.add_child(edit)

		"tap_void_stack":
			_add_side_picker(row, snap_key, snap_idx, m)

		"tap_cell":
			var r_edit := _param_edit(m, "row", "Row")
			r_edit.custom_minimum_size = Vector2(40, 0)
			r_edit.text_changed.connect(func(v: String) -> void:
				_cfg["turns"][snap_key][snap_idx]["row"] = int(v) if v.is_valid_int() else 0)
			row.add_child(r_edit)

			var c_edit := _param_edit(m, "col", "Col")
			c_edit.custom_minimum_size = Vector2(40, 0)
			c_edit.text_changed.connect(func(v: String) -> void:
				_cfg["turns"][snap_key][snap_idx]["col"] = int(v) if v.is_valid_int() else 0)
			row.add_child(c_edit)

			_add_side_picker(row, snap_key, snap_idx, m)

func _add_side_picker(row: HBoxContainer, turn_key: String, idx: int, m: Dictionary) -> void:
	var side_btn := OptionButton.new()
	side_btn.add_item("Player")
	side_btn.add_item("Opponent")
	side_btn.select(0 if m.get("side", "player") == "player" else 1)
	var snap_key := turn_key; var snap_idx := idx
	side_btn.item_selected.connect(func(sel: int) -> void:
		_cfg["turns"][snap_key][snap_idx]["side"] = "player" if sel == 0 else "opponent")
	row.add_child(side_btn)

func _param_edit(m: Dictionary, key: String, placeholder: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.custom_minimum_size = Vector2(120, 0)
	var v: Variant = m.get(key, "")
	edit.text = str(v) if v != null else ""
	return edit

func _mission_types() -> Array:
	return [
		"show_message", "wait", "attack", "bluff", "union_summon", "use_tech",
		"end_turn", "options", "tap_void_stack", "tap_tech",
		"tap_card", "tap_cell"
	]

# ─────────────────────────────────────────────────────────────
# Launch Battle
# ─────────────────────────────────────────────────────────────

func _start_battle() -> void:
	_collect_config_from_ui()
	var err: String = TutorialBattleManager.configure_battle_from_config(_cfg)
	if not err.is_empty():
		_set_status(err)
		return
	CheckerTransition.fade_out_to_scene("res://scenes/game_board.tscn")
	queue_free()

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────

func _section_header(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	parent.add_child(HSeparator.new())
	parent.add_child(lbl)

func _row_label(grid: GridContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
	grid.add_child(lbl)

func _small_btn(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 12)
	btn.custom_minimum_size = Vector2(0, 28)
	return btn

func _set_status(msg: String) -> void:
	if _status_lbl:
		_status_lbl.text = msg
