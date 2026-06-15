extends Control
# Admin overlay for managing the starting deck template.
# Opened via admin command: manage_starting_deck
# Saves to / loads from data/starting_deck.json

const DeckData = preload("res://resources/DeckData.gd")
const SAVE_PATH := "res://data/starting_deck.json"
const CHIVO_FONT := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")

const GRID_ROWS    := 5
const GRID_COLS    := 5
const CELL_SIZE    := 48
const MAX_FORMATIONS := 5

var _deck: DeckData = null

# UI refs
var _char_list:   ItemList = null
var _trap_list:   ItemList = null
var _tech_list:   ItemList = null
var _status_lbl:  Label    = null
var _confirm_panel: Control = null

# Formation editor refs
var _fe_overlay:    Control  = null
var _fe_list:       ItemList = null
var _fe_name_edit:  LineEdit = null
var _fe_grid_cells: Array    = []   # flattened Button array, row-major
var _fe_pick_list:  ItemList = null
var _fe_selected:   int      = -1   # currently selected formation index
var _fe_card_pick:  String   = ""   # card name chosen to place

# ── Lifecycle ────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 200
	mouse_filter = Control.MOUSE_FILTER_STOP
	_deck = _load_deck()
	_build_ui()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()

# ── Load / Save ──────────────────────────────────────────────
func _load_deck() -> DeckData:
	var d := DeckData.new()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		d.deck_name = "Starter Deck"
		return d
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		d.load_from_dict(data as Dictionary)
	return d

func _save_deck() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		_set_status("ERROR: cannot write to " + SAVE_PATH)
		return
	f.store_string(JSON.stringify(_deck.to_dict(), "\t"))
	f.close()
	_set_status("Starter deck saved.")

# ── UI ───────────────────────────────────────────────────────
func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.12, 0.97)
	add_child(bg)

	# ── Top bar ───────────────────────────────────────────────
	var top := Panel.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 48.0
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.10, 0.10, 0.15)
	top.add_theme_stylebox_override("panel", tsb)
	add_child(top)

	var title := Label.new()
	title.text = "Starting Deck Manager"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_top = 10.0; title.offset_bottom = 42.0
	title.offset_left = -200.0; title.offset_right = 200.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CHIVO_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	top.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕ CLOSE"
	close_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	close_btn.offset_left = 10.0; close_btn.offset_top    = 8.0
	close_btn.offset_right = 120.0; close_btn.offset_bottom = 40.0
	close_btn.add_theme_font_override("font", FontManager.make_font("primary", 400))
	close_btn.pressed.connect(func() -> void: queue_free())
	top.add_child(close_btn)

	var save_btn := Button.new()
	save_btn.text = "💾 SAVE"
	save_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	save_btn.offset_left = -130.0; save_btn.offset_top    = 8.0
	save_btn.offset_right = -10.0;  save_btn.offset_bottom = 40.0
	save_btn.add_theme_font_override("font", CHIVO_FONT)
	save_btn.pressed.connect(_save_deck)
	top.add_child(save_btn)

	# ── Status bar ────────────────────────────────────────────
	_status_lbl = Label.new()
	_status_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_status_lbl.offset_top = -26.0; _status_lbl.offset_bottom = 0.0
	_status_lbl.offset_left = 8.0
	_status_lbl.add_theme_font_override("font", CHIVO_FONT)
	_status_lbl.add_theme_font_size_override("font_size", 12)
	_status_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	add_child(_status_lbl)

	# ── Reset to starter button ───────────────────────────────
	var reset_btn := Button.new()
	reset_btn.text = "⚠  RESET PLAYER TO STARTER DECK"
	reset_btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	reset_btn.offset_top    = -55.0; reset_btn.offset_bottom = -28.0
	reset_btn.offset_left   =  10.0; reset_btn.offset_right  = -10.0
	reset_btn.add_theme_font_override("font", CHIVO_FONT)
	reset_btn.add_theme_font_size_override("font_size", 14)
	reset_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	reset_btn.pressed.connect(_show_reset_confirm)
	add_child(reset_btn)

	# ── Main body: 3-column layout (chars | traps | techs) + formation ──
	var main := VBoxContainer.new()
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.offset_top    = 52.0
	main.offset_bottom = -60.0
	main.offset_left   = 8.0
	main.offset_right  = -8.0
	main.add_theme_constant_override("separation", 6)
	add_child(main)

	# deck name row
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	main.add_child(name_row)
	var name_lbl := Label.new()
	name_lbl.text = "Deck Name:"
	name_lbl.add_theme_font_override("font", CHIVO_FONT)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	name_row.add_child(name_lbl)
	var name_edit := LineEdit.new()
	name_edit.text = _deck.deck_name
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.add_theme_font_override("font", CHIVO_FONT)
	name_edit.text_changed.connect(func(t: String) -> void: _deck.deck_name = t)
	name_row.add_child(name_edit)

	# 3-column for characters / traps / techs
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 8)
	main.add_child(cols)

	_char_list = _build_card_column(cols, "Characters  [%d–%d]" % [DeckData.MIN_CHARACTERS, DeckData.MAX_CHARACTERS],
		_deck.characters, "character")
	_trap_list = _build_card_column(cols, "Traps  [%d–%d]" % [DeckData.MIN_TRAPS, DeckData.MAX_TRAPS],
		_deck.traps, "trap")
	_tech_list = _build_card_column(cols, "Techs  [exactly %d]" % DeckData.TECH_COUNT,
		_deck.techs, "tech")

	# Formation section
	var form_row := HBoxContainer.new()
	form_row.add_theme_constant_override("separation", 8)
	main.add_child(form_row)

	var form_lbl := Label.new()
	form_lbl.text = "Formations: %d / %d" % [_deck.formations.size(), MAX_FORMATIONS]
	form_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_lbl.add_theme_font_override("font", CHIVO_FONT)
	form_lbl.add_theme_font_size_override("font_size", 12)
	form_lbl.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	form_row.add_child(form_lbl)

	var fe_btn := Button.new()
	fe_btn.text = "📋 Edit Formations"
	fe_btn.add_theme_font_override("font", CHIVO_FONT)
	fe_btn.add_theme_font_size_override("font_size", 12)
	fe_btn.pressed.connect(_open_formation_editor.bind(form_lbl))
	form_row.add_child(fe_btn)

func _build_card_column(parent: Control, header: String, card_array: Array, card_type: String) -> ItemList:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	parent.add_child(col)

	var hdr := Label.new()
	hdr.text = header
	hdr.add_theme_font_override("font", CHIVO_FONT)
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	col.add_child(hdr)

	var list := ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_override("font", CHIVO_FONT)
	list.add_theme_font_size_override("font_size", 12)
	for n: String in card_array:
		list.add_item(n)
	col.add_child(list)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 4)
	col.add_child(btns)

	var add_btn := Button.new()
	add_btn.text = "+ Add"
	add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_btn.add_theme_font_override("font", CHIVO_FONT)
	add_btn.add_theme_font_size_override("font_size", 12)
	add_btn.pressed.connect(func() -> void: _show_add_dialog(list, card_array, card_type))
	btns.add_child(add_btn)

	var rem_btn := Button.new()
	rem_btn.text = "− Remove"
	rem_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rem_btn.add_theme_font_override("font", CHIVO_FONT)
	rem_btn.add_theme_font_size_override("font_size", 12)
	rem_btn.pressed.connect(func() -> void: _remove_selected(list, card_array))
	btns.add_child(rem_btn)

	return list

# ── Formation editor ─────────────────────────────────────────
func _open_formation_editor(summary_lbl: Label) -> void:
	if _fe_overlay != null and is_instance_valid(_fe_overlay):
		return

	_fe_overlay = Control.new()
	_fe_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fe_overlay.z_index = 50
	_fe_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.10, 0.98)
	_fe_overlay.add_child(bg)

	# Top bar
	var top := Panel.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 44.0
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.10, 0.10, 0.18)
	top.add_theme_stylebox_override("panel", tsb)
	_fe_overlay.add_child(top)

	var ttl := Label.new()
	ttl.text = "Formation Editor"
	ttl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ttl.offset_top = 8.0; ttl.offset_bottom = 40.0
	ttl.offset_left = -180.0; ttl.offset_right = 180.0
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", CHIVO_FONT)
	ttl.add_theme_font_size_override("font_size", 18)
	ttl.add_theme_color_override("font_color", Color(1, 1, 1))
	top.add_child(ttl)

	var close_fe := Button.new()
	close_fe.text = "✕ DONE"
	close_fe.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_fe.offset_left = -130.0; close_fe.offset_top    = 6.0
	close_fe.offset_right = -10.0;  close_fe.offset_bottom = 38.0
	close_fe.add_theme_font_override("font", FontManager.make_font("primary", 400))
	close_fe.pressed.connect(func() -> void:
		_save_deck()
		summary_lbl.text = "Formations: %d / %d" % [_deck.formations.size(), MAX_FORMATIONS]
		_fe_overlay.queue_free()
		_fe_overlay = null)
	top.add_child(close_fe)

	# Body: 3 panels — left list | centre grid | right card picker
	var body := HBoxContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_top    = 48.0
	body.offset_bottom = 0.0
	body.offset_left   = 4.0
	body.offset_right  = -4.0
	body.add_theme_constant_override("separation", 6)
	_fe_overlay.add_child(body)

	# ── Left: formation list ───────────────────────────────
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(180, 0)
	left.add_theme_constant_override("separation", 4)
	body.add_child(left)

	var ll := Label.new()
	ll.text = "Formations  (max %d)" % MAX_FORMATIONS
	ll.add_theme_font_override("font", CHIVO_FONT)
	ll.add_theme_font_size_override("font_size", 12)
	ll.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	left.add_child(ll)

	_fe_list = ItemList.new()
	_fe_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fe_list.add_theme_font_override("font", CHIVO_FONT)
	_fe_list.add_theme_font_size_override("font_size", 12)
	left.add_child(_fe_list)

	for f: Variant in _deck.formations:
		var fd: Dictionary = f as Dictionary
		_fe_list.add_item(str(fd.get("name", "Formation")))

	_fe_list.item_selected.connect(_fe_on_select)

	var lbtns := HBoxContainer.new()
	lbtns.add_theme_constant_override("separation", 4)
	left.add_child(lbtns)

	var add_f := Button.new()
	add_f.text = "+ New"
	add_f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_f.add_theme_font_override("font", CHIVO_FONT)
	add_f.add_theme_font_size_override("font_size", 12)
	add_f.pressed.connect(_fe_add_formation)
	lbtns.add_child(add_f)

	var del_f := Button.new()
	del_f.text = "− Del"
	del_f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	del_f.add_theme_font_override("font", CHIVO_FONT)
	del_f.add_theme_font_size_override("font_size", 12)
	del_f.pressed.connect(_fe_delete_formation)
	lbtns.add_child(del_f)

	# ── Centre: name + 5×5 grid ──────────────────────────
	var centre := VBoxContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.add_theme_constant_override("separation", 6)
	body.add_child(centre)

	# Spacer to push grid toward centre vertically
	var top_space := Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centre.add_child(top_space)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	centre.add_child(name_row)

	var nl := Label.new()
	nl.text = "Name:"
	nl.add_theme_font_override("font", CHIVO_FONT)
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	name_row.add_child(nl)

	_fe_name_edit = LineEdit.new()
	_fe_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fe_name_edit.placeholder_text = "Formation name"
	_fe_name_edit.editable = false
	_fe_name_edit.add_theme_font_override("font", CHIVO_FONT)
	_fe_name_edit.text_changed.connect(_fe_on_name_changed)
	name_row.add_child(_fe_name_edit)

	var save_f := Button.new()
	save_f.text = "💾 Save"
	save_f.add_theme_font_override("font", CHIVO_FONT)
	save_f.add_theme_font_size_override("font_size", 12)
	save_f.pressed.connect(_fe_save_formation)
	name_row.add_child(save_f)

	# 5×5 grid
	var grid := GridContainer.new()
	grid.columns = GRID_COLS
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	centre.add_child(grid)
	grid.set_anchors_preset(Control.PRESET_CENTER)

	_fe_grid_cells.clear()
	for r: int in range(GRID_ROWS):
		for c: int in range(GRID_COLS):
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			cell.clip_text = true
			cell.add_theme_font_override("font", CHIVO_FONT)
			cell.add_theme_font_size_override("font_size", 9)
			var ri: int = r
			var ci: int = c
			cell.pressed.connect(func() -> void: _fe_place_card(ri, ci))
			cell.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton:
					var mb: InputEventMouseButton = ev as InputEventMouseButton
					if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
						_fe_clear_cell(ri, ci))
			_fe_grid_cells.append(cell)
			grid.add_child(cell)

	var bottom_space := Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centre.add_child(bottom_space)

	var hint_lbl := Label.new()
	hint_lbl.text = "Left-click: place selected card    Right-click: clear cell"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_override("font", CHIVO_FONT)
	hint_lbl.add_theme_font_size_override("font_size", 10)
	hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	centre.add_child(hint_lbl)

	# ── Right: card picker ────────────────────────────────
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(180, 0)
	right.add_theme_constant_override("separation", 4)
	body.add_child(right)

	var rl := Label.new()
	rl.text = "Cards (deck)"
	rl.add_theme_font_override("font", CHIVO_FONT)
	rl.add_theme_font_size_override("font_size", 12)
	rl.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	right.add_child(rl)

	_fe_pick_list = ItemList.new()
	_fe_pick_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fe_pick_list.add_theme_font_override("font", CHIVO_FONT)
	_fe_pick_list.add_theme_font_size_override("font_size", 11)
	right.add_child(_fe_pick_list)

	_fe_refresh_pick_list()
	_fe_pick_list.item_selected.connect(func(idx: int) -> void:
		_fe_card_pick = _fe_pick_list.get_item_text(idx))

	var clear_pick := Button.new()
	clear_pick.text = "✕ Deselect"
	clear_pick.add_theme_font_override("font", FontManager.make_font("primary", 400))
	clear_pick.add_theme_font_size_override("font_size", 11)
	clear_pick.pressed.connect(func() -> void:
		_fe_card_pick = ""
		_fe_pick_list.deselect_all())
	right.add_child(clear_pick)

	add_child(_fe_overlay)
	_fe_selected = -1
	_fe_refresh_grid()

func _fe_refresh_pick_list() -> void:
	if _fe_pick_list == null:
		return
	_fe_pick_list.clear()
	var seen: Dictionary = {}
	for n: String in _deck.characters:
		if not seen.has(n):
			seen[n] = true
			_fe_pick_list.add_item(n)
	for n: String in _deck.traps:
		if not seen.has(n):
			seen[n] = true
			_fe_pick_list.add_item(n)

func _fe_on_select(idx: int) -> void:
	_fe_selected = idx
	if idx < 0 or idx >= _deck.formations.size():
		return
	var fd: Dictionary = _deck.formations[idx] as Dictionary
	if _fe_name_edit:
		_fe_name_edit.editable = true
		_fe_name_edit.text = str(fd.get("name", "Formation"))
	_fe_refresh_grid()

func _fe_refresh_grid() -> void:
	# Build lookup: "r,c" → card name
	var placed: Dictionary = {}
	if _fe_selected >= 0 and _fe_selected < _deck.formations.size():
		var fd: Dictionary = _deck.formations[_fe_selected] as Dictionary
		var pl: Variant = fd.get("placements", [])
		if pl is Array:
			for p: Variant in (pl as Array):
				if p is Dictionary:
					var pd: Dictionary = p as Dictionary
					var key: String = "%d,%d" % [int(pd.get("r", -1)), int(pd.get("c", -1))]
					placed[key] = str(pd.get("name", ""))

	for r: int in range(GRID_ROWS):
		for c: int in range(GRID_COLS):
			var cell: Button = _fe_grid_cells[r * GRID_COLS + c] as Button
			var key: String = "%d,%d" % [r, c]
			if placed.has(key):
				cell.text = placed[key]
				cell.modulate = Color(0.7, 1.0, 0.7)
			else:
				cell.text = ""
				cell.modulate = Color(1, 1, 1)

func _fe_place_card(r: int, c: int) -> void:
	if _fe_selected < 0 or _fe_card_pick == "":
		return
	var fd: Dictionary = _deck.formations[_fe_selected] as Dictionary
	var pl: Variant = fd.get("placements", [])
	var placements: Array = pl as Array if pl is Array else []
	# Remove existing entry at same cell
	for i: int in range(placements.size() - 1, -1, -1):
		var p: Variant = placements[i]
		if p is Dictionary:
			var pd: Dictionary = p as Dictionary
			if int(pd.get("r", -1)) == r and int(pd.get("c", -1)) == c:
				placements.remove_at(i)
	# Determine type
	var ctype: String = "character"
	if _fe_card_pick in _deck.traps:
		ctype = "trap"
	placements.append({"r": r, "c": c, "name": _fe_card_pick, "type": ctype})
	fd["placements"] = placements
	_deck.formations[_fe_selected] = fd
	_fe_refresh_grid()

func _fe_clear_cell(r: int, c: int) -> void:
	if _fe_selected < 0:
		return
	var fd: Dictionary = _deck.formations[_fe_selected] as Dictionary
	var pl: Variant = fd.get("placements", [])
	if not pl is Array:
		return
	var placements: Array = pl as Array
	for i: int in range(placements.size() - 1, -1, -1):
		var p: Variant = placements[i]
		if p is Dictionary:
			var pd: Dictionary = p as Dictionary
			if int(pd.get("r", -1)) == r and int(pd.get("c", -1)) == c:
				placements.remove_at(i)
	fd["placements"] = placements
	_deck.formations[_fe_selected] = fd
	_fe_refresh_grid()

func _fe_on_name_changed(new_name: String) -> void:
	if _fe_selected < 0 or _fe_selected >= _deck.formations.size():
		return
	var fd: Dictionary = _deck.formations[_fe_selected] as Dictionary
	fd["name"] = new_name
	_deck.formations[_fe_selected] = fd
	if _fe_list:
		_fe_list.set_item_text(_fe_selected, new_name)

func _fe_add_formation() -> void:
	if _deck.formations.size() >= MAX_FORMATIONS:
		_set_status("Max %d formations reached." % MAX_FORMATIONS)
		return
	var idx: int = _deck.formations.size()
	_deck.formations.append({"name": "Formation %d" % (idx + 1), "placements": []})
	if _fe_list:
		_fe_list.add_item("Formation %d" % (idx + 1))
		_fe_list.select(idx)
		_fe_on_select(idx)

func _fe_delete_formation() -> void:
	if _fe_selected < 0 or _fe_selected >= _deck.formations.size():
		return
	_deck.formations.remove_at(_fe_selected)
	if _fe_list:
		_fe_list.remove_item(_fe_selected)
	_fe_selected = -1
	if _fe_name_edit:
		_fe_name_edit.text = ""
		_fe_name_edit.editable = false
	_fe_refresh_grid()

func _fe_save_formation() -> void:
	_save_deck()
	_set_status("Formation saved.")

# ── Add dialog (simple popup) ────────────────────────────────
func _show_add_dialog(target_list: ItemList, card_array: Array, card_type: String) -> void:
	var pop := PanelContainer.new()
	pop.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pop.offset_left = -260.0; pop.offset_right  = 260.0
	pop.offset_top  = -220.0; pop.offset_bottom = 220.0
	pop.z_index = 10
	add_child(pop)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	pop.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "Add %s card" % card_type.capitalize()
	hdr.add_theme_font_override("font", CHIVO_FONT)
	hdr.add_theme_font_size_override("font_size", 15)
	hdr.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	vbox.add_child(hdr)

	var search := LineEdit.new()
	search.placeholder_text = "Search…"
	search.add_theme_font_override("font", CHIVO_FONT)
	vbox.add_child(search)

	var db_list := ItemList.new()
	db_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	db_list.custom_minimum_size = Vector2(0.0, 280.0)
	db_list.add_theme_font_override("font", CHIVO_FONT)
	db_list.add_theme_font_size_override("font_size", 12)
	vbox.add_child(db_list)

	var all_names: Array = []
	match card_type:
		"character": all_names = CardDatabase.characters.keys()
		"trap":      all_names = CardDatabase.traps.keys()
		"tech":      all_names = CardDatabase.tech_cards.keys()
	all_names.sort()

	var _rebuild_db_list := func(query: String) -> void:
		db_list.clear()
		for n: String in all_names:
			if query == "" or query.to_lower() in n.to_lower():
				db_list.add_item(n)
	_rebuild_db_list.call("")
	search.text_changed.connect(_rebuild_db_list)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vbox.add_child(row)

	var ok_btn := Button.new()
	ok_btn.text = "Add"
	ok_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok_btn.add_theme_font_override("font", CHIVO_FONT)
	ok_btn.pressed.connect(func() -> void:
		var sel: PackedInt32Array = db_list.get_selected_items()
		if sel.is_empty():
			return
		var chosen: String = db_list.get_item_text(sel[0])
		card_array.append(chosen)
		target_list.add_item(chosen)
		pop.queue_free()
		_set_status("Added: %s" % chosen))
	row.add_child(ok_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_override("font", CHIVO_FONT)
	cancel_btn.pressed.connect(func() -> void: pop.queue_free())
	row.add_child(cancel_btn)

func _remove_selected(list: ItemList, card_array: Array) -> void:
	var sel: PackedInt32Array = list.get_selected_items()
	if sel.is_empty():
		return
	var idx: int = sel[0]
	if idx < 0 or idx >= card_array.size():
		return
	var removed: String = list.get_item_text(idx)
	card_array.remove_at(idx)
	list.remove_item(idx)
	_set_status("Removed: %s" % removed)

# ── Reset confirm ────────────────────────────────────────────
func _show_reset_confirm() -> void:
	if _confirm_panel != null and is_instance_valid(_confirm_panel):
		return
	var pop := PanelContainer.new()
	_confirm_panel = pop
	pop.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pop.offset_left = -250.0; pop.offset_right  = 250.0
	pop.offset_top  = -100.0; pop.offset_bottom = 100.0
	pop.z_index = 20
	add_child(pop)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	pop.add_child(vbox)

	var lbl := Label.new()
	lbl.text = "Reset player to starter deck?\n\nAll cards in collection and decks\nwill be removed and replaced."
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", CHIVO_FONT)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.85))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row)

	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm Reset"
	confirm_btn.add_theme_font_override("font", CHIVO_FONT)
	confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	confirm_btn.pressed.connect(_do_reset)
	row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_override("font", CHIVO_FONT)
	cancel_btn.pressed.connect(func() -> void: pop.queue_free())
	row.add_child(cancel_btn)

func _do_reset() -> void:
	if _confirm_panel != null and is_instance_valid(_confirm_panel):
		_confirm_panel.queue_free()

	Collection.owned.clear()
	Collection.emit_signal("collection_changed")

	if not OnboardingManager.install_starter_deck(false, true):
		_set_status("ERROR: could not load starter deck template.")
		return

	SaveManager.active_deck_index = 0
	SaveManager.save_data()

	_set_status("Player reset to starter deck. Collection and decks replaced.")

func _set_status(msg: String) -> void:
	if _status_lbl:
		_status_lbl.text = msg
