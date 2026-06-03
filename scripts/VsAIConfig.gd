extends Control
## VS AI Config — pre-battle setup screen for Player vs AI mode.
## Launched from the main menu VS AI button.
## Lets the player configure the AI's deck, forced formation cells, and forced tech hand.

const DeckData = preload("res://resources/DeckData.gd")
const TECH_SLOT_COUNT: int = 3

# ── UI refs ────────────────────────────────────────────────────────────────────
var _deck_opt: OptionButton = null
var _formation_opt: OptionButton = null
var _forced_tech_btns: Array[Button] = []
var _forced_tech: Array = ["", "", ""]   # slot → tech name (empty = random on deal)
var _forced_grid: GridContainer = null
var _forced_dict: Dictionary = {}        # key="r,c" value=card_name
var _status_lbl: Label = null

# Union zone highlight
var _union_highlighted_name: String = ""
var _union_highlight_cells: Array = []

# AI illustration
var _ai_portrait_path: String = "res://assets/textures/ui/portraits/profile_player_2_default.png"
var _ai_portrait_preview: TextureRect = null

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	_build_ui()
	_populate_decks()
	CheckerTransition.fade_in()

# ─────────────────────────────────────────────────────────────────────────────
# UI Construction
# ─────────────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.10, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	root.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	add_child(root)

	# ── Title bar ─────────────────────────────────────────────────────────────
	var title_hb := HBoxContainer.new()
	title_hb.add_theme_constant_override("separation", 10)
	root.add_child(title_hb)

	var title_lbl := Label.new()
	title_lbl.text = "VS AI  —  Configure Opponent"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hb.add_child(title_lbl)

	var back_btn := Button.new()
	back_btn.text = "← Back to Main Menu"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	title_hb.add_child(back_btn)

	# ── AI config column ───────────────────────────────────────────────────────
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	cols.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(cols)

	_build_ai_column(cols)

	# ── Start + status row ─────────────────────────────────────────────────────
	var sep := HSeparator.new()
	root.add_child(sep)

	var action_hb := HBoxContainer.new()
	action_hb.add_theme_constant_override("separation", 12)
	root.add_child(action_hb)

	var start_btn := Button.new()
	start_btn.text = "  START BATTLE  "
	start_btn.add_theme_font_size_override("font_size", 18)
	start_btn.custom_minimum_size = Vector2(220, 44)
	start_btn.pressed.connect(_on_start_battle)
	action_hb.add_child(start_btn)

	_status_lbl = Label.new()
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
	_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_hb.add_child(_status_lbl)

func _build_ai_column(parent: HBoxContainer) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(col)

	var hdr := Label.new()
	hdr.text = "AI Opponent"
	hdr.add_theme_font_size_override("font_size", 17)
	hdr.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	col.add_child(hdr)

	# ── Illustration picker ────────────────────────────────────────────────────
	var illus_row := HBoxContainer.new()
	illus_row.add_theme_constant_override("separation", 10)
	col.add_child(illus_row)

	_ai_portrait_preview = TextureRect.new()
	_ai_portrait_preview.custom_minimum_size = Vector2(60, 88)
	_ai_portrait_preview.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_ai_portrait_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ai_portrait_preview.clip_contents = true
	var init_tex: Texture2D = load(_ai_portrait_path)
	if init_tex:
		_ai_portrait_preview.texture = init_tex
	illus_row.add_child(_ai_portrait_preview)

	var illus_vb := VBoxContainer.new()
	illus_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	illus_vb.add_theme_constant_override("separation", 4)
	illus_row.add_child(illus_vb)

	var illus_lbl := Label.new()
	illus_lbl.text = "AI Illustration"
	illus_lbl.add_theme_font_size_override("font_size", 13)
	illus_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	illus_vb.add_child(illus_lbl)

	var change_btn := Button.new()
	change_btn.text = "Change..."
	change_btn.add_theme_font_size_override("font_size", 12)
	change_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	change_btn.pressed.connect(_open_portrait_picker)
	illus_vb.add_child(change_btn)

	# ── Deck selector ──────────────────────────────────────────────────────────
	var deck_row := HBoxContainer.new()
	deck_row.add_theme_constant_override("separation", 8)
	col.add_child(deck_row)

	var deck_lbl := Label.new()
	deck_lbl.text = "Deck:"
	deck_lbl.add_theme_font_size_override("font_size", 14)
	deck_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_row.add_child(deck_lbl)

	_deck_opt = OptionButton.new()
	_deck_opt.add_theme_font_size_override("font_size", 13)
	_deck_opt.custom_minimum_size = Vector2(300, 0)
	_deck_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_opt.item_selected.connect(func(_i: int) -> void: _on_deck_selected())
	deck_row.add_child(_deck_opt)

	# ── Formation preset selector ───────────────────────────────────────────────
	var form_row := HBoxContainer.new()
	form_row.add_theme_constant_override("separation", 8)
	col.add_child(form_row)

	var form_lbl := Label.new()
	form_lbl.text = "Formation:"
	form_lbl.add_theme_font_size_override("font_size", 14)
	form_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	form_row.add_child(form_lbl)

	_formation_opt = OptionButton.new()
	_formation_opt.add_theme_font_size_override("font_size", 13)
	_formation_opt.custom_minimum_size = Vector2(300, 0)
	_formation_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_formation_opt.item_selected.connect(func(_i: int) -> void: _on_formation_selected())
	form_row.add_child(_formation_opt)
	_refresh_formation_opt()

	# ── Forced tech hand ───────────────────────────────────────────────────────
	var ft_lbl := Label.new()
	ft_lbl.text = "Forced Tech Hand  (tap slot to assign)"
	ft_lbl.add_theme_font_size_override("font_size", 13)
	ft_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	col.add_child(ft_lbl)

	var ft_row := HBoxContainer.new()
	ft_row.add_theme_constant_override("separation", 6)
	col.add_child(ft_row)

	_forced_tech_btns = []
	for slot: int in range(TECH_SLOT_COUNT):
		var tbtn := Button.new()
		tbtn.custom_minimum_size = Vector2(0, 36)
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtn.clip_text = true
		tbtn.add_theme_font_size_override("font_size", 11)
		var slot_cap := slot
		tbtn.pressed.connect(func() -> void: _open_forced_tech_picker(slot_cap))
		ft_row.add_child(tbtn)
		_forced_tech_btns.append(tbtn)
	_refresh_forced_tech_row()

	# ── Forced cells grid ──────────────────────────────────────────────────────
	var fc_lbl := Label.new()
	fc_lbl.text = "Forced Formation  (tap cell to assign)"
	fc_lbl.add_theme_font_size_override("font_size", 13)
	fc_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	col.add_child(fc_lbl)

	_forced_grid = _build_forced_grid()
	col.add_child(_forced_grid)

	# ── Clear formation button ─────────────────────────────────────────────────
	var clear_btn := Button.new()
	clear_btn.text = "Clear All Cells"
	clear_btn.add_theme_font_size_override("font_size", 12)
	clear_btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	clear_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	clear_btn.pressed.connect(func() -> void:
		_forced_dict.clear()
		_refresh_forced_grid())
	col.add_child(clear_btn)

func _populate_decks() -> void:
	_deck_opt.clear()
	_deck_opt.add_item("Random (full card pool)")  # index 0 = null deck
	for i: int in range(SaveManager.decks.size()):
		var d: DeckData = SaveManager.decks[i]
		_deck_opt.add_item(d.deck_name)

func _on_deck_selected() -> void:
	# Pre-fill tech slots from the selected deck
	for i: int in range(TECH_SLOT_COUNT):
		_forced_tech[i] = ""
	if _deck_opt.selected > 0:
		var deck: DeckData = SaveManager.decks[_deck_opt.selected - 1]
		for i: int in range(mini(TECH_SLOT_COUNT, deck.techs.size())):
			_forced_tech[i] = str(deck.techs[i])
	_refresh_forced_tech_row()
	_refresh_formation_opt()

func _refresh_formation_opt() -> void:
	if _formation_opt == null:
		return
	_formation_opt.clear()
	_formation_opt.add_item("— no preset —")
	if _deck_opt != null and _deck_opt.selected > 0:
		var deck: DeckData = SaveManager.decks[_deck_opt.selected - 1]
		for f: Variant in deck.formations:
			var fd: Dictionary = f as Dictionary
			_formation_opt.add_item(str(fd.get("name", "Formation")))

func _on_formation_selected() -> void:
	if _formation_opt == null or _formation_opt.selected <= 0:
		return
	if _deck_opt == null or _deck_opt.selected <= 0:
		return
	var deck: DeckData = SaveManager.decks[_deck_opt.selected - 1]
	var form_idx: int = _formation_opt.selected - 1
	if form_idx < 0 or form_idx >= deck.formations.size():
		return
	var fd: Dictionary = deck.formations[form_idx] as Dictionary
	var pls: Variant = fd.get("placements", [])
	if not pls is Array:
		return
	_forced_dict.clear()
	for pl: Variant in (pls as Array):
		if not pl is Dictionary:
			continue
		var p: Dictionary = pl as Dictionary
		var r: int = int(p.get("r", -1))
		var c: int = int(p.get("c", -1))
		var card_name: String = str(p.get("name", ""))
		if r < 0 or r > 4 or c < 0 or c > 4 or card_name.is_empty():
			continue
		_forced_dict[str(r) + "," + str(c)] = card_name
	_refresh_forced_grid()

# ─────────────────────────────────────────────────────────────────────────────
# Start Battle
# ─────────────────────────────────────────────────────────────────────────────
func _on_start_battle() -> void:
	var d: Variant = null
	if _deck_opt.selected > 0:
		d = SaveManager.decks[_deck_opt.selected - 1]
		if not (d as DeckData).is_valid():
			_status_lbl.text = "Selected AI deck is invalid."
			return

	var fc: Array = _collect_forced_cells()
	var ft: Array = _collect_forced_tech()

	for msg: String in _validate_forced_tech(ft):
		_status_lbl.text = msg
		return

	GameState.game_mode               = GameState.GameMode.VS_AI
	GameState.battle_ai_deck          = d
	GameState.battle_ai_forced_cells  = fc
	GameState.battle_ai_forced_tech   = ft
	GameState.player_portraits[1]     = _ai_portrait_path

	BGMManager.stop(0.0)
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game_board.tscn"))

# ─────────────────────────────────────────────────────────────────────────────
# Forced cell grid helpers
# ─────────────────────────────────────────────────────────────────────────────
func _build_forced_grid() -> GridContainer:
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
				_open_forced_cell_picker(r_cap, c_cap))
			gc.add_child(btn)
	_refresh_forced_grid()
	return gc

func _refresh_forced_grid() -> void:
	if _forced_grid == null:
		return
	var children: Array = _forced_grid.get_children()
	for r: int in range(5):
		for c: int in range(5):
			var btn: Button = children[r * 5 + c] as Button
			var key: String = str(r) + "," + str(c)
			var is_hl: bool = Vector2i(r, c) in _union_highlight_cells
			if _forced_dict.has(key):
				btn.text = _forced_dict[key] as String
				btn.modulate = Color(0.0, 1.0, 1.0) if is_hl else Color(0.55, 1.0, 0.55)
			else:
				btn.text = "%d,%d" % [r, c]
				btn.modulate = Color(0.0, 0.85, 0.85, 0.75) if is_hl else Color(1.0, 1.0, 1.0, 0.45)

func _open_forced_cell_picker(r: int, c: int) -> void:
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
	title.text = "AI Cell [row %d, col %d]" % [r, c]
	title.add_theme_font_size_override("font_size", 15)
	vb.add_child(title)

	var key: String = str(r) + "," + str(c)
	var current: String = str(_forced_dict.get(key, ""))

	var le := LineEdit.new()
	le.placeholder_text = "Character or trap name..."
	le.text = current
	le.add_theme_font_size_override("font_size", 14)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(le)

	var sug_scroll := ScrollContainer.new()
	sug_scroll.custom_minimum_size = Vector2(0, 140)
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
		for n: String in CardDatabase.traps:
			if q.is_empty() or n.to_lower().contains(q):
				names.append(n)
		names.sort()
		var shown: int = 0
		for n: String in names:
			if shown >= 30:
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
			_forced_dict[key] = cname
		else:
			_forced_dict.erase(key)
		_refresh_forced_grid()
		overlay.queue_free())

	clear_btn.pressed.connect(func() -> void:
		_forced_dict.erase(key)
		_refresh_forced_grid()
		overlay.queue_free())

	cancel_btn.pressed.connect(func() -> void: overlay.queue_free())

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if not panel.get_global_rect().has_point(
					(event as InputEventMouseButton).global_position):
				overlay.queue_free())

	le.grab_focus()
	le.select_all()

func _collect_forced_cells() -> Array:
	var result: Array = []
	for key: String in _forced_dict:
		var parts: PackedStringArray = key.split(",")
		if parts.size() == 2:
			result.append({
				"card_name": _forced_dict[key],
				"row": int(parts[0]),
				"col": int(parts[1]),
			})
	return result

# ─────────────────────────────────────────────────────────────────────────────
# Forced tech helpers
# ─────────────────────────────────────────────────────────────────────────────
func _refresh_forced_tech_row() -> void:
	for i: int in range(_forced_tech_btns.size()):
		var btn: Button = _forced_tech_btns[i]
		var n: String = str(_forced_tech[i] if i < _forced_tech.size() else "").strip_edges()
		if n.is_empty():
			btn.text = "Tech %d\n(random)" % (i + 1)
			btn.modulate = Color(1.0, 1.0, 1.0, 0.45)
		else:
			btn.text = n
			btn.modulate = Color(0.55, 0.85, 1.0)

func _open_forced_tech_picker(slot: int) -> void:
	var current: String = str(_forced_tech[slot] if slot < _forced_tech.size() else "")

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
	title.text = "AI Tech slot %d" % (slot + 1)
	title.add_theme_font_size_override("font_size", 15)
	vb.add_child(title)

	var le := LineEdit.new()
	le.placeholder_text = "Tech card name..."
	le.text = current
	le.add_theme_font_size_override("font_size", 14)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(le)

	var sug_scroll := ScrollContainer.new()
	sug_scroll.custom_minimum_size = Vector2(0, 160)
	sug_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(sug_scroll)
	var sug_vb := VBoxContainer.new()
	sug_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sug_scroll.add_child(sug_vb)

	var refresh_sug := func(query: String) -> void:
		for child: Node in sug_vb.get_children():
			child.queue_free()
		var q: String = query.strip_edges().to_lower()
		var names: Array = CardDatabase.get_all_tech_names()
		names.sort()
		var shown: int = 0
		for n: String in names:
			if SaveManager.demo_mode:
				var tc: TechCardData = CardDatabase.get_tech(n)
				if tc == null or not tc.include_in_demo:
					continue
			if not q.is_empty() and not n.to_lower().contains(q):
				continue
			if shown >= 30:
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
		var tname: String = le.text.strip_edges()
		_forced_tech[slot] = tname
		_refresh_forced_tech_row()
		overlay.queue_free())

	clear_btn.pressed.connect(func() -> void:
		_forced_tech[slot] = ""
		_refresh_forced_tech_row()
		overlay.queue_free())

	cancel_btn.pressed.connect(func() -> void: overlay.queue_free())

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if not panel.get_global_rect().has_point(
					(event as InputEventMouseButton).global_position):
				overlay.queue_free())

	le.grab_focus()
	le.select_all()

func _collect_forced_tech() -> Array:
	var result: Array = []
	for i: int in range(TECH_SLOT_COUNT):
		var n: String = str(_forced_tech[i] if i < _forced_tech.size() else "").strip_edges()
		result.append(n)
	return result

func _validate_forced_tech(slots: Array) -> Array[String]:
	var seen: Dictionary = {}
	for i: int in range(slots.size()):
		var n: String = str(slots[i]).strip_edges()
		if n.is_empty():
			continue
		if CardDatabase.get_tech(n) == null:
			return ["Tech slot %d: unknown tech \"%s\"." % [i + 1, n]]
		if seen.has(n):
			return ["Tech slot %d: duplicate \"%s\"." % [i + 1, n]]
		seen[n] = true
	return []

# ─────────────────────────────────────────────────────────────────────────────
# Portrait picker
# ─────────────────────────────────────────────────────────────────────────────
func _get_portrait_options() -> Array:
	# Returns Array of {label, path} for all available AI illustrations.
	var opts: Array = []
	opts.append({
		"label": "Default",
		"path":  "res://assets/textures/ui/portraits/profile_player_2_default.png"
	})
	var dir := DirAccess.open("res://assets/textures/vn/characters")
	if dir:
		dir.list_dir_begin()
		var fname: String = dir.get_next()
		var files: Array = []
		while fname != "":
			if not dir.current_is_dir() and fname.ends_with(".png") and not fname.ends_with(".import"):
				files.append(fname)
			fname = dir.get_next()
		dir.list_dir_end()
		files.sort()
		for f: String in files:
			var label: String = f.get_basename().trim_prefix("vn_char_").replace("_", " ")
			opts.append({
				"label": label,
				"path":  "res://assets/textures/vn/characters/" + f
			})
	return opts

func _open_portrait_picker() -> void:
	var options: Array = _get_portrait_options()

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.65)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 70
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 420)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title_hb := HBoxContainer.new()
	vb.add_child(title_hb)
	var title := Label.new()
	title.text = "Choose AI Illustration"
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hb.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(func() -> void: overlay.queue_free())
	title_hb.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(flow)

	const THUMB_W: float = 80.0
	const THUMB_H: float = 110.0

	for opt: Dictionary in options:
		var opt_path: String = str(opt["path"])
		var opt_label: String = str(opt["label"])

		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(THUMB_W, THUMB_H + 24)
		cell.add_theme_constant_override("separation", 2)
		flow.add_child(cell)

		var thumb := TextureRect.new()
		thumb.custom_minimum_size = Vector2(THUMB_W, THUMB_H)
		thumb.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tex: Texture2D = load(opt_path)
		if tex:
			thumb.texture = tex
		else:
			thumb.modulate = Color(0.3, 0.3, 0.3)
		if opt_path == _ai_portrait_path:
			thumb.modulate = Color(0.4, 1.0, 0.6)
		cell.add_child(thumb)

		var name_lbl := Label.new()
		name_lbl.text = opt_label
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.clip_text = true
		name_lbl.custom_minimum_size = Vector2(THUMB_W, 0)
		cell.add_child(name_lbl)

		var p_cap := opt_path
		thumb.mouse_filter = Control.MOUSE_FILTER_STOP
		thumb.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton:
				var mbe := event as InputEventMouseButton
				if mbe.pressed and mbe.button_index == MOUSE_BUTTON_LEFT:
					_ai_portrait_path = p_cap
					var new_tex: Texture2D = load(p_cap)
					if new_tex and _ai_portrait_preview != null:
						_ai_portrait_preview.texture = new_tex
					overlay.queue_free())

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if not panel.get_global_rect().has_point(
					(event as InputEventMouseButton).global_position):
				overlay.queue_free())
