extends Control
# In-game Tutorial Battle Builder overlay.
# Launched via admin command "tutorial_battle".
# Lets you create/edit tutorial config JSON and launch a tutorial battle.

const SAVE_DIR := "res://data/tutorial_battles/"
const GRID_SIZE := 5

# ── UI refs ────────────────────────────────────────────────────
var _file_list: ItemList
var _file_name_edit: LineEdit
var _title_edit: LineEdit
var _on_complete_btn: OptionButton
var _player_deck_section: VBoxContainer
var _ai_deck_section: VBoxContainer
var _player_grid_btns: Array = []   # Array[Array[Button]] [row][col]
var _ai_grid_btns: Array = []
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
	_ensure_dir()
	_build_ui()
	_refresh_file_list()
	_new_config()

func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SAVE_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))

# ─────────────────────────────────────────────────────────────
# UI Build
# ─────────────────────────────────────────────────────────────

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.12, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	var root_hbox := HBoxContainer.new()
	root_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_hbox.add_theme_constant_override("separation", 0)
	add_child(root_hbox)

	# ── Left panel: file list ──────────────────────────────────
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(220, 0)
	left.add_theme_constant_override("separation", 6)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_hbox.add_child(left)

	var left_bg := ColorRect.new()
	left_bg.color = Color(0.07, 0.07, 0.09, 1.0)
	left_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	left.add_child(left_bg)
	left.move_child(left_bg, 0)

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
	root_hbox.add_child(right_scroll)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	var right_margin := MarginContainer.new()
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

func _build_deck_section(parent: VBoxContainer, header: String, is_player: bool) -> void:
	_section_header(parent, header)

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

func _build_card_list_row(parent: VBoxContainer, label: String, is_player: bool, deck_key: String) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var lbl := Label.new(); lbl.text = label + ":"
	lbl.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(lbl)
	var add_btn := _small_btn("+ Add")
	var snap_ip := is_player; var snap_dk := deck_key
	add_btn.pressed.connect(func() -> void: _open_card_picker(snap_ip, snap_dk))
	hbox.add_child(add_btn)
	var clear_btn := _small_btn("Clear All")
	clear_btn.pressed.connect(func() -> void:
		var dk: Dictionary = _get_side_deck(snap_ip)
		dk[snap_dk] = []
		_refresh_ui_from_cfg())
	hbox.add_child(clear_btn)

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
	var parsed := JSON.parse_string(fa.get_as_text())
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
	_cfg = {
		"title": "",
		"on_complete": "end_immediately",
		"player_deck": {"characters": [], "traps": [], "techs": []},
		"player_formation": [],
		"ai_deck": {"characters": [], "traps": [], "techs": []},
		"ai_formation": [],
		"turns": {}
	}
	_refresh_ui_from_cfg()

# ─────────────────────────────────────────────────────────────
# UI ↔ Config Sync
# ─────────────────────────────────────────────────────────────

func _refresh_ui_from_cfg() -> void:
	_title_edit.text = _cfg.get("title", "")
	var oc: String = _cfg.get("on_complete", "end_immediately")
	_on_complete_btn.select(0 if oc == "end_immediately" else 1)

	_refresh_deck_labels(true)
	_refresh_deck_labels(false)
	_refresh_formation_grid(true)
	_refresh_formation_grid(false)
	_rebuild_missions_ui()

func _refresh_deck_labels(is_player: bool) -> void:
	var deck: Dictionary = _get_side_deck(is_player)
	var section: VBoxContainer = _player_deck_section if is_player else _ai_deck_section
	if section == null:
		return
	# Update the first Label in each card-list row (children 1, 3, 5 → hboxes)
	# Actually we just update via tooltip/text on the add button area.
	# Re-building would be complex; instead we show a summary label.
	_ensure_deck_summary(section, is_player)

func _ensure_deck_summary(section: VBoxContainer, is_player: bool) -> void:
	var deck: Dictionary = _get_side_deck(is_player)
	var tag := "_deck_summary_" + ("p" if is_player else "ai")
	var existing: Label = section.get_node_or_null(tag)
	if existing == null:
		existing = Label.new()
		existing.name = tag
		existing.add_theme_font_size_override("font_size", 11)
		existing.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
		existing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		section.add_child(existing)
	var chars: Array = deck.get("characters", [])
	var traps: Array = deck.get("traps", [])
	var techs: Array = deck.get("techs", [])
	existing.text = "Chars(%d): %s\nTraps(%d): %s\nTechs(%d): %s" % [
		chars.size(), ", ".join(chars),
		traps.size(), ", ".join(traps),
		techs.size(), ", ".join(techs)
	]

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

# ─────────────────────────────────────────────────────────────
# Card Picker Popup
# ─────────────────────────────────────────────────────────────

func _open_card_picker(is_player: bool, deck_key: String) -> void:
	if _picker_popup != null:
		_picker_popup.queue_free()

	var popup := Window.new()
	popup.title = "Pick Card — " + deck_key
	popup.size = Vector2i(380, 500)
	popup.wrap_controls = true
	add_child(popup)
	_picker_popup = popup

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(vbox)
	popup.add_child(margin)

	var search := LineEdit.new()
	search.placeholder_text = "Search..."
	vbox.add_child(search)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_vbox)

	# Build list of candidate card names
	var names: Array = []
	match deck_key:
		"characters":
			names = CardDatabase.get_all_character_names()
		"traps":
			names = CardDatabase.get_all_trap_names()
		"techs":
			names = CardDatabase.get_all_tech_names()
	names.sort()

	for n in names:
		var btn := Button.new()
		btn.text = n
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var snap_n: String = n; var snap_ip := is_player; var snap_dk := deck_key
		btn.pressed.connect(func() -> void:
			_add_card_to_deck(snap_ip, snap_dk, snap_n)
			popup.queue_free())
		list_vbox.add_child(btn)

	search.text_changed.connect(func(q: String) -> void:
		for child in list_vbox.get_children():
			if child is Button:
				child.visible = q.is_empty() or q.to_lower() in child.text.to_lower())

	popup.popup_centered()
	popup.close_requested.connect(popup.queue_free)

func _add_card_to_deck(is_player: bool, deck_key: String, card_name: String) -> void:
	var deck: Dictionary = _get_side_deck(is_player)
	var arr: Array = deck.get(deck_key, [])
	arr.append(card_name)
	deck[deck_key] = arr
	_refresh_deck_labels(is_player)
	_set_status("Added %s to %s" % [card_name, deck_key])

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

	var vbox := VBoxContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(vbox)
	popup.add_child(margin)

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

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	scroll.add_child(list)

	var deck: Dictionary = _get_side_deck(is_player)
	var all_cards: Array = []
	all_cards.append_array(deck.get("characters", []))
	all_cards.append_array(deck.get("traps", []))
	all_cards.sort()
	all_cards = _dedup(all_cards)

	for n in all_cards:
		var btn := Button.new()
		btn.text = n
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var snap_n: String = n
		btn.pressed.connect(func() -> void:
			_set_cell_placement(snap_ip, snap_r, snap_c, snap_n)
			_refresh_formation_grid(snap_ip)
			popup.queue_free())
		list.add_child(btn)

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

	# Remove button
	var del_btn := _small_btn("✕")
	del_btn.pressed.connect(func() -> void:
		_cfg["turns"][snap_key].remove_at(snap_idx)
		_rebuild_missions_ui())
	row.add_child(del_btn)

func _add_mission_param_fields(row: HBoxContainer, turn_key: String, idx: int, m: Dictionary) -> void:
	var mtype: String = m.get("type", "")
	var snap_key := turn_key; var snap_idx := idx

	match mtype:
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
		"attack", "bluff", "union_summon", "use_tech",
		"end_turn", "options", "tap_void_stack", "tap_tech",
		"tap_card", "tap_cell"
	]

# ─────────────────────────────────────────────────────────────
# Launch Battle
# ─────────────────────────────────────────────────────────────

func _start_battle() -> void:
	_collect_config_from_ui()

	var player_deck_dict: Dictionary = _cfg.get("player_deck", {})
	var ai_deck_dict: Dictionary = _cfg.get("ai_deck", {})

	# Build DeckData for player
	var p_deck := DeckData.new()
	p_deck.deck_name = "Tutorial Player"
	p_deck.characters = player_deck_dict.get("characters", []).duplicate()
	p_deck.traps = player_deck_dict.get("traps", []).duplicate()
	p_deck.techs = player_deck_dict.get("techs", []).duplicate()

	# Build DeckData for AI
	var ai_deck := DeckData.new()
	ai_deck.deck_name = "Tutorial AI"
	ai_deck.characters = ai_deck_dict.get("characters", []).duplicate()
	ai_deck.traps = ai_deck_dict.get("traps", []).duplicate()
	ai_deck.techs = ai_deck_dict.get("techs", []).duplicate()

	# Validate deck composition
	if not p_deck.is_valid():
		_set_status("Player deck invalid:\n" + p_deck.validation_message())
		return
	if not ai_deck.is_valid():
		_set_status("AI deck invalid:\n" + ai_deck.validation_message())
		return

	# Set GameState
	GameState.game_mode = GameState.GameMode.VS_AI
	GameState._vn_battle_pending = true
	GameState.battle_player_deck = p_deck
	GameState.battle_player_forced_cells = _cfg.get("player_formation", []).duplicate(true)
	GameState.battle_ai_deck = ai_deck
	GameState.battle_ai_forced_cells = _cfg.get("ai_formation", []).duplicate(true)
	GameState.battle_ai_forced_tech = ai_deck.techs.duplicate()

	# Prepare tutorial manager
	TutorialBattleManager.prepare(_cfg)

	queue_free()
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game_board.tscn"))

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
