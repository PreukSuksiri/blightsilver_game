extends Control
## AI vs AI Config — pre-battle setup screen for the AI vs AI debug mode.
## Launched via admin command: ai_vs_ai
## After a match, AIvsAIManager changes scene back here to show the log.

const DeckData = preload("res://resources/DeckData.gd")

# ── UI refs ───────────────────────────────────────────────────────────────────
var _deck_opt_0: OptionButton = null
var _deck_opt_1: OptionButton = null
var _forced_grid_0: GridContainer = null
var _forced_grid_1: GridContainer = null
var _forced_dict_0: Dictionary = {}   # key="r,c" value=card_name
var _forced_dict_1: Dictionary = {}
var _log_label: RichTextLabel = null
var _start_btn: Button = null
var _status_lbl: Label = null

# Union zone highlight (shared pattern from VNEditor)
var _union_highlighted_name: String = ""
var _union_highlight_cells: Array = []

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	_build_ui()
	_populate_decks()
	# Show previous match log if any
	var prev_log: String = AIvsAIManager.get_log_text()
	if not prev_log.is_empty():
		_log_label.text = prev_log
		await get_tree().process_frame
		_log_label.scroll_to_line(_log_label.get_line_count())

# ─────────────────────────────────────────────────────────────────────────────
# UI Construction
# ─────────────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Dark background
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.10, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	# Root VBox
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	root.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	add_child(root)

	# ── Title bar ────────────────────────────────────────────────────────────
	var title_hb := HBoxContainer.new()
	title_hb.add_theme_constant_override("separation", 10)
	root.add_child(title_hb)

	var title_lbl := Label.new()
	title_lbl.text = "AI vs AI  —  Debug Mode"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hb.add_child(title_lbl)

	var back_btn := Button.new()
	back_btn.text = "← Back to Main Menu"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	title_hb.add_child(back_btn)

	# ── Two-column config area ────────────────────────────────────────────────
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	cols.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(cols)

	_build_ai_column(cols, 0)

	var divider := VSeparator.new()
	cols.add_child(divider)

	_build_ai_column(cols, 1)

	# ── Start + status row ───────────────────────────────────────────────────
	var action_hb := HBoxContainer.new()
	action_hb.add_theme_constant_override("separation", 12)
	root.add_child(action_hb)

	_start_btn = Button.new()
	_start_btn.text = "  START BATTLE  "
	_start_btn.add_theme_font_size_override("font_size", 18)
	_start_btn.custom_minimum_size = Vector2(220, 40)
	_start_btn.pressed.connect(_on_start_battle)
	action_hb.add_child(_start_btn)

	var save_log_btn := Button.new()
	save_log_btn.text = "Open Log Folder"
	save_log_btn.add_theme_font_size_override("font_size", 14)
	save_log_btn.pressed.connect(func() -> void:
		var path: String = ProjectSettings.globalize_path("res://logs/")
		OS.shell_open(path))
	action_hb.add_child(save_log_btn)

	_status_lbl = Label.new()
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
	_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_hb.add_child(_status_lbl)

	# ── Log panel ────────────────────────────────────────────────────────────
	var sep := HSeparator.new()
	root.add_child(sep)

	var log_hdr := HBoxContainer.new()
	root.add_child(log_hdr)
	var log_hdr_lbl := Label.new()
	log_hdr_lbl.text = "Battle Log"
	log_hdr_lbl.add_theme_font_size_override("font_size", 14)
	log_hdr_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	log_hdr.add_child(log_hdr_lbl)

	var log_scroll := ScrollContainer.new()
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(log_scroll)

	_log_label = RichTextLabel.new()
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_label.fit_content = true
	_log_label.add_theme_font_size_override("normal_font_size", 12)
	_log_label.scroll_following = true
	log_scroll.add_child(_log_label)

	# Live log feed from AIvsAIManager during match
	AIvsAIManager.log_written.connect(_on_log_written)

func _build_ai_column(parent: HBoxContainer, player_idx: int) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(col)

	var hdr := Label.new()
	hdr.text = "AI Player %d" % player_idx
	hdr.add_theme_font_size_override("font_size", 17)
	hdr.add_theme_color_override("font_color",
		Color(0.5, 0.85, 1.0) if player_idx == 0 else Color(1.0, 0.6, 0.6))
	col.add_child(hdr)

	# Deck selector
	var deck_row := HBoxContainer.new()
	deck_row.add_theme_constant_override("separation", 8)
	col.add_child(deck_row)
	var deck_lbl := Label.new()
	deck_lbl.text = "Deck:"
	deck_lbl.add_theme_font_size_override("font_size", 14)
	deck_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_row.add_child(deck_lbl)

	var opt := OptionButton.new()
	opt.add_theme_font_size_override("font_size", 13)
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_row.add_child(opt)

	if player_idx == 0:
		_deck_opt_0 = opt
	else:
		_deck_opt_1 = opt

	# Forced cells grid
	var fc_lbl := Label.new()
	fc_lbl.text = "Forced Cells  (tap to assign)"
	fc_lbl.add_theme_font_size_override("font_size", 13)
	fc_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	col.add_child(fc_lbl)

	var grid_dict: Dictionary = _forced_dict_0 if player_idx == 0 else _forced_dict_1
	var gc: GridContainer = _build_forced_grid(grid_dict)
	col.add_child(gc)

	if player_idx == 0:
		_forced_grid_0 = gc
	else:
		_forced_grid_1 = gc

func _populate_decks() -> void:
	for opt: OptionButton in [_deck_opt_0, _deck_opt_1]:
		opt.clear()
		if SaveManager.decks.is_empty():
			opt.add_item("(no saved decks)")
			opt.disabled = true
		else:
			for i: int in range(SaveManager.decks.size()):
				var d: DeckData = SaveManager.decks[i]
				opt.add_item(d.deck_name)
			opt.disabled = false

# ─────────────────────────────────────────────────────────────────────────────
# Start Battle
# ─────────────────────────────────────────────────────────────────────────────
func _on_start_battle() -> void:
	if SaveManager.decks.is_empty():
		_status_lbl.text = "No saved decks found. Build a deck first."
		return

	var d0: DeckData = SaveManager.decks[_deck_opt_0.selected] if _deck_opt_0.selected >= 0 else null
	var d1: DeckData = SaveManager.decks[_deck_opt_1.selected] if _deck_opt_1.selected >= 0 else null

	if d0 == null or not d0.is_valid():
		_status_lbl.text = "AI Player 0 deck is invalid."
		return
	if d1 == null or not d1.is_valid():
		_status_lbl.text = "AI Player 1 deck is invalid."
		return

	var fc0: Array = _collect_forced_cells_from_grid(_forced_dict_0)
	var fc1: Array = _collect_forced_cells_from_grid(_forced_dict_1)

	AIvsAIManager.configure(d0, fc0, d1, fc1)

	# Store config in GameState for GameBoard to read
	GameState.game_mode                = GameState.GameMode.AI_VS_AI
	GameState.battle_player_forced_cells = fc0
	GameState.battle_ai_forced_cells     = fc1
	GameState.battle_player_deck         = d0
	GameState.battle_ai_deck             = d1

	_log_label.text = ""
	get_tree().change_scene_to_file("res://scenes/game_board.tscn")

# ─────────────────────────────────────────────────────────────────────────────
# Forced cell grid helpers (identical pattern to VNEditor)
# ─────────────────────────────────────────────────────────────────────────────
func _build_forced_grid(grid_dict: Dictionary) -> GridContainer:
	var gc := GridContainer.new()
	gc.columns = 5
	gc.add_theme_constant_override("h_separation", 4)
	gc.add_theme_constant_override("v_separation", 4)
	for r: int in range(5):
		for c: int in range(5):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(64, 44)
			btn.clip_text = true
			btn.add_theme_font_size_override("font_size", 10)
			var r_cap := r
			var c_cap := c
			btn.pressed.connect(func() -> void:
				_open_forced_cell_picker(grid_dict, gc, r_cap, c_cap))
			gc.add_child(btn)
	_refresh_forced_grid(grid_dict, gc)
	return gc

func _refresh_forced_grid(grid_dict: Dictionary, gc: GridContainer) -> void:
	if gc == null:
		return
	var children: Array = gc.get_children()
	for r: int in range(5):
		for c: int in range(5):
			var btn: Button = children[r * 5 + c] as Button
			var key: String = str(r) + "," + str(c)
			var is_hl: bool = Vector2i(r, c) in _union_highlight_cells
			if grid_dict.has(key):
				btn.text = grid_dict[key] as String
				btn.modulate = Color(0.0, 1.0, 1.0) if is_hl else Color(0.55, 1.0, 0.55)
			else:
				btn.text = "%d,%d" % [r, c]
				btn.modulate = Color(0.0, 0.85, 0.85, 0.75) if is_hl else Color(1.0, 1.0, 1.0, 0.45)

func _open_forced_cell_picker(grid_dict: Dictionary, gc: GridContainer, r: int, c: int) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 70
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "Cell [row %d, col %d]" % [r, c]
	title.add_theme_font_size_override("font_size", 15)
	vb.add_child(title)

	var key: String = str(r) + "," + str(c)
	var current: String = str(grid_dict.get(key, ""))

	var le := LineEdit.new()
	le.placeholder_text = "Character card name..."
	le.text = current
	le.add_theme_font_size_override("font_size", 14)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(le)

	var sug_scroll := ScrollContainer.new()
	sug_scroll.custom_minimum_size = Vector2(0, 120)
	sug_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(sug_scroll)
	var sug_vb := VBoxContainer.new()
	sug_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sug_scroll.add_child(sug_vb)

	var refresh_sug := func(query: String) -> void:
		for child: Node in sug_vb.get_children():
			child.queue_free()
		var q: String = query.strip_edges().to_lower()
		var names: Array = []
		for n: String in CardDatabase.characters:
			if q.is_empty() or n.to_lower().contains(q):
				names.append(n)
		names.sort()
		var shown: int = 0
		for n: String in names:
			if shown >= 25:
				break
			var sb := Button.new()
			sb.text = n
			sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			sb.add_theme_font_size_override("font_size", 12)
			sb.pressed.connect(func() -> void: le.text = n)
			sug_vb.add_child(sb)
			shown += 1

	le.text_changed.connect(refresh_sug)
	refresh_sug.call(current)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 6)
	vb.add_child(btn_hb)

	var set_btn := Button.new()
	set_btn.text = "Set"
	set_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(set_btn)
	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(clear_btn)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(cancel_btn)

	set_btn.pressed.connect(func() -> void:
		var cname: String = le.text.strip_edges()
		if not cname.is_empty():
			grid_dict[key] = cname
		else:
			grid_dict.erase(key)
		_refresh_forced_grid(grid_dict, gc)
		overlay.queue_free())

	clear_btn.pressed.connect(func() -> void:
		grid_dict.erase(key)
		_refresh_forced_grid(grid_dict, gc)
		overlay.queue_free())

	cancel_btn.pressed.connect(func() -> void: overlay.queue_free())

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if not panel.get_global_rect().has_point(
					(event as InputEventMouseButton).global_position):
				overlay.queue_free())

	le.grab_focus()
	le.select_all()

func _collect_forced_cells_from_grid(grid_dict: Dictionary) -> Array:
	var result: Array = []
	for key: String in grid_dict:
		var parts: PackedStringArray = key.split(",")
		if parts.size() == 2:
			result.append({
				"card_name": grid_dict[key],
				"row": int(parts[0]),
				"col": int(parts[1]),
			})
	return result

# ─────────────────────────────────────────────────────────────────────────────
# Live log feed
# ─────────────────────────────────────────────────────────────────────────────
func _on_log_written(line: String) -> void:
	if _log_label == null:
		return
	_log_label.text += "\n" + line
