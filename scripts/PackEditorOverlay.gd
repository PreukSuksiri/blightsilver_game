extends Control
# Pack Editor — visual admin tool for creating and editing custom booster packs.
# Each pack stores a card_pool: Array of {card_name, card_type, weight}
# and is persisted to res://shop/custom_packs.json via ShopManager.

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var _packs: Array = []           # working copy of ShopManager._custom_packs
var _selected_idx: int = -1      # index into _packs

# Left panel
var _pack_list_vbox: VBoxContainer = null
var _status_lbl:     Label         = null

# Right panel fields
var _prop_id_edit:    LineEdit = null
var _prop_name_edit:  LineEdit = null
var _prop_price_spin: SpinBox  = null
var _prop_count_spin: SpinBox  = null
var _prop_desc_edit:  TextEdit = null
var _prop_accent_edit: LineEdit = null   # hex colour string
var _prop_image_edit:  LineEdit  = null   # res:// path to booster pack image
var _prop_shop_check:  CheckBox  = null   # available in shop toggle
var _prop_unlock_chapter: OptionButton = null
var _unlock_chapter_values: Array = []

# Card pool
var _pool_vbox:      VBoxContainer = null
var _pool_rows:      Array         = []  # [{card_le, type_lbl, weight_sb, hbox}]
var _add_card_le:    LineEdit       = null
var _add_weight_sb:  SpinBox        = null

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 50
	_packs = ShopManager._custom_packs.duplicate(true)
	_build_ui()
	_refresh_pack_list()

# ─────────────────────────────────────────────────────────────
# Build UI
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.94)
	dimmer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(dimmer)

	_build_header()

	var body := HBoxContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_top = 56.0
	body.add_theme_constant_override("separation", 0)
	add_child(body)

	_build_left_panel(body)
	_build_right_panel(body)

func _build_header() -> void:
	var header := Panel.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 56.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.05, 0.12, 1.0)
	sb.border_width_bottom = 1
	sb.border_color = Color(1.0, 0.72, 0.22, 0.35)
	header.add_theme_stylebox_override("panel", sb)
	add_child(header)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left  = 16.0; hbox.offset_right = -16.0
	hbox.add_theme_constant_override("separation", 12)
	header.add_child(hbox)

	var title := Label.new()
	title.text = "PACK EDITOR"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.30))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	_status_lbl = Label.new()
	_status_lbl.text = ""
	_status_lbl.add_theme_font_size_override("font_size", 12)
	_status_lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0, 0.85))
	_status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_lbl.custom_minimum_size = Vector2(280, 0)
	hbox.add_child(_status_lbl)

	for data: Array in [
		["SAVE ALL", _save_all, 100],
		["CLOSE",    func() -> void: queue_free(), 80],
	]:
		var btn := Button.new()
		btn.text = data[0]
		btn.custom_minimum_size = Vector2(data[2], 34)
		btn.pressed.connect(data[1] as Callable)
		hbox.add_child(btn)

func _build_left_panel(parent: Control) -> void:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(260, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.06, 0.14, 0.98)
	sb.border_width_right = 1
	sb.border_color = Color(1.0, 0.72, 0.22, 0.18)
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12; vbox.offset_right = -12
	vbox.offset_top  = 12; vbox.offset_bottom = -12
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "CUSTOM PACKS"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(1.0, 0.78, 0.30, 0.7))
	vbox.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	vbox.add_child(scroll)

	_pack_list_vbox = VBoxContainer.new()
	_pack_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pack_list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(_pack_list_vbox)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(1.0, 0.72, 0.22, 0.15)
	vbox.add_child(sep)

	var new_btn := Button.new()
	new_btn.text = "+ New Custom Pack"
	new_btn.pressed.connect(_on_new_pack)
	vbox.add_child(new_btn)

	var del_btn := Button.new()
	del_btn.text = "Delete Selected"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	del_btn.pressed.connect(_on_delete_pack)
	vbox.add_child(del_btn)

	var note := Label.new()
	note.text = "Built-in packs are read-only.\nOnly custom packs are editable."
	note.add_theme_font_size_override("font_size", 10)
	note.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68, 0.7))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(note)

func _build_right_panel(parent: Control) -> void:
	var panel := Panel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 0.98)
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.add_child(scroll)

	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 20)
	pad.add_theme_constant_override("margin_right", 20)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(pad)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	pad.add_child(inner)

	var hdr := Label.new()
	hdr.text = "PACK PROPERTIES"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(1.0, 0.78, 0.30, 0.7))
	inner.add_child(hdr)

	inner.add_child(_lbl("Pack ID (unique, no spaces)"))
	_prop_id_edit = LineEdit.new()
	_prop_id_edit.placeholder_text = "e.g. my_special_pack"
	inner.add_child(_prop_id_edit)

	inner.add_child(_lbl("Display Name"))
	_prop_name_edit = LineEdit.new()
	_prop_name_edit.placeholder_text = "e.g. Special Pack"
	inner.add_child(_prop_name_edit)

	inner.add_child(_lbl("Price (credits)"))
	_prop_price_spin = SpinBox.new()
	_prop_price_spin.min_value = 0; _prop_price_spin.max_value = 99999
	_prop_price_spin.step = 50; _prop_price_spin.value = 500
	inner.add_child(_prop_price_spin)

	inner.add_child(_lbl("Cards per pack (draw count)"))
	_prop_count_spin = SpinBox.new()
	_prop_count_spin.min_value = 1; _prop_count_spin.max_value = 10
	_prop_count_spin.step = 1; _prop_count_spin.value = 3
	inner.add_child(_prop_count_spin)

	inner.add_child(_lbl("Description"))
	_prop_desc_edit = TextEdit.new()
	_prop_desc_edit.custom_minimum_size = Vector2(0, 56)
	_prop_desc_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	inner.add_child(_prop_desc_edit)

	inner.add_child(_lbl("Accent Colour (hex, e.g. ff8822)"))
	_prop_accent_edit = LineEdit.new()
	_prop_accent_edit.placeholder_text = "ff8822"
	_prop_accent_edit.max_length = 8
	inner.add_child(_prop_accent_edit)

	inner.add_child(_lbl("Pack Image (res:// path to .png)"))
	var img_row := HBoxContainer.new()
	img_row.add_theme_constant_override("separation", 6)
	inner.add_child(img_row)
	_prop_image_edit = LineEdit.new()
	_prop_image_edit.placeholder_text = "res://assets/textures/cards/booster_pack/my_pack.png"
	_prop_image_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	img_row.add_child(_prop_image_edit)
	var browse_btn := Button.new()
	browse_btn.text = "Browse"
	browse_btn.custom_minimum_size = Vector2(64, 0)
	browse_btn.pressed.connect(_open_image_dialog)
	img_row.add_child(browse_btn)

	_prop_shop_check = CheckBox.new()
	_prop_shop_check.text = "Available in Shop"
	_prop_shop_check.button_pressed = true
	inner.add_child(_prop_shop_check)

	inner.add_child(_lbl("Unlock requires chapter"))
	var unlock_note := Label.new()
	unlock_note.text = "Pack stays visible in the Shop but locked until the player completes this gallery chapter. Configure chapter list in Campaign Gallery Editor."
	unlock_note.add_theme_font_size_override("font_size", 11)
	unlock_note.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80, 0.65))
	unlock_note.autowrap_mode = TextServer.AUTOWRAP_WORD
	inner.add_child(unlock_note)
	_prop_unlock_chapter = OptionButton.new()
	_prop_unlock_chapter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(_prop_unlock_chapter)
	_rebuild_unlock_chapter_options("")

	var apply_btn := Button.new()
	apply_btn.text = "Apply Pack Properties"
	apply_btn.pressed.connect(_apply_pack_props)
	inner.add_child(apply_btn)

	inner.add_child(_sep())

	# ── Card Pool ──
	var pool_hdr := Label.new()
	pool_hdr.text = "CARD POOL"
	pool_hdr.add_theme_font_size_override("font_size", 13)
	pool_hdr.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0, 0.8))
	inner.add_child(pool_hdr)

	var pool_note := Label.new()
	pool_note.text = "Weight is relative — e.g. weight 10 is twice as likely as weight 5."
	pool_note.add_theme_font_size_override("font_size", 11)
	pool_note.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80, 0.65))
	pool_note.autowrap_mode = TextServer.AUTOWRAP_WORD
	inner.add_child(pool_note)

	# Column headers
	var col_hdr := HBoxContainer.new()
	col_hdr.add_theme_constant_override("separation", 4)
	inner.add_child(col_hdr)
	for txt: String in ["Card Name", "Type", "Weight", ""]:
		var l := Label.new()
		l.text = txt
		l.add_theme_font_size_override("font_size", 11)
		l.add_theme_color_override("font_color", Color(0.75, 0.78, 0.88, 0.55))
		match txt:
			"Card Name": l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			"Type":      l.custom_minimum_size = Vector2(78, 0)
			"Weight":    l.custom_minimum_size = Vector2(68, 0)
			"":          l.custom_minimum_size = Vector2(28, 0)
		col_hdr.add_child(l)

	_pool_vbox = VBoxContainer.new()
	_pool_vbox.add_theme_constant_override("separation", 4)
	inner.add_child(_pool_vbox)

	# Add-card row
	inner.add_child(_lbl("Add card to pool:"))
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	inner.add_child(add_row)

	_add_card_le = LineEdit.new()
	_add_card_le.placeholder_text = "Card name"
	_add_card_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(_add_card_le)

	var wgt_lbl := Label.new()
	wgt_lbl.text = "W"
	wgt_lbl.add_theme_font_size_override("font_size", 11)
	add_row.add_child(wgt_lbl)

	_add_weight_sb = SpinBox.new()
	_add_weight_sb.min_value = 1; _add_weight_sb.max_value = 1000
	_add_weight_sb.step = 1; _add_weight_sb.value = 10
	_add_weight_sb.custom_minimum_size = Vector2(72, 0)
	add_row.add_child(_add_weight_sb)

	var add_btn := Button.new()
	add_btn.text = "Add"
	add_btn.custom_minimum_size = Vector2(52, 0)
	add_btn.pressed.connect(_on_add_card_pressed)
	add_row.add_child(add_btn)

	inner.add_child(_sep())

	var apply_pool_btn := Button.new()
	apply_pool_btn.text = "Apply Pool Changes"
	apply_pool_btn.pressed.connect(_apply_pool)
	inner.add_child(apply_pool_btn)

# ─────────────────────────────────────────────────────────────
# Pack list
# ─────────────────────────────────────────────────────────────
func _refresh_pack_list() -> void:
	for ch in _pack_list_vbox.get_children():
		ch.queue_free()

	for i: int in range(_packs.size()):
		var p: Dictionary = _packs[i]
		var listed: bool = bool(p.get("shop_available", true))
		var req: String = str(p.get("unlock_requires_chapter", "")).strip_edges()
		var icon: String = "○"
		if listed:
			if req.is_empty() or SaveManager.is_gallery_chapter_completed(req):
				icon = "●"
			else:
				icon = "◆"
		var btn := Button.new()
		btn.text = ("%s  %s" % [icon, p.get("name", p.get("id", "?"))])
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == _selected_idx:
			btn.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
		elif not listed:
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.6))
		elif req != "" and not SaveManager.is_gallery_chapter_completed(req):
			btn.add_theme_color_override("font_color", Color(0.95, 0.72, 0.35, 0.75))
		var idx_cap := i
		btn.pressed.connect(func() -> void: _select_pack(idx_cap))
		_pack_list_vbox.add_child(btn)

func _select_pack(idx: int) -> void:
	_selected_idx = idx
	_refresh_pack_list()
	_populate_props()

func _populate_props() -> void:
	if _selected_idx < 0 or _selected_idx >= _packs.size():
		return
	var p: Dictionary = _packs[_selected_idx]
	_prop_id_edit.text    = str(p.get("id", ""))
	_prop_name_edit.text  = str(p.get("name", ""))
	_prop_price_spin.value = float(p.get("price", 500))
	_prop_count_spin.value = float(p.get("card_count", 3))
	_prop_desc_edit.text  = str(p.get("description", ""))
	var accent_raw: Variant = p.get("accent", [])
	if accent_raw is Array and (accent_raw as Array).size() >= 3:
		var arr: Array = accent_raw as Array
		var col := Color(float(arr[0]), float(arr[1]), float(arr[2]))
		_prop_accent_edit.text = col.to_html(false)
	else:
		_prop_accent_edit.text = ""
	_prop_image_edit.text = str(p.get("pack_image", ""))
	_prop_shop_check.button_pressed = bool(p.get("shop_available", true))
	_rebuild_unlock_chapter_options(str(p.get("unlock_requires_chapter", "")).strip_edges())
	var raw_pool: Variant = p.get("card_pool", [])
	var pool: Array = raw_pool if raw_pool is Array else []
	_rebuild_pool_rows(pool)

# ─────────────────────────────────────────────────────────────
# Applying properties
# ─────────────────────────────────────────────────────────────
func _rebuild_unlock_chapter_options(selected_vn: String) -> void:
	if _prop_unlock_chapter == null:
		return
	ShopManager.reload_gallery_chapter_labels()
	_prop_unlock_chapter.clear()
	_unlock_chapter_values = [""]
	_prop_unlock_chapter.add_item("(none — no chapter requirement)")
	var sel_idx := 0
	if not FileAccess.file_exists("res://campaign/gallery_data.json"):
		_prop_unlock_chapter.select(sel_idx)
		return
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://campaign/gallery_data.json"))
	if not parsed is Array:
		_prop_unlock_chapter.select(sel_idx)
		return
	for entry: Variant in (parsed as Array):
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		var vn: String = str(d.get("vn_scene", "")).strip_edges()
		if vn.is_empty():
			continue
		var label: String = "%s / %s" % [str(d.get("line1", "")), str(d.get("line2", ""))]
		_prop_unlock_chapter.add_item(label.strip_edges().trim_suffix(" /").trim_prefix(" /"))
		_unlock_chapter_values.append(vn)
		if vn == selected_vn:
			sel_idx = _unlock_chapter_values.size() - 1
	_prop_unlock_chapter.select(sel_idx)

func _apply_pack_props() -> void:
	if _selected_idx < 0 or _selected_idx >= _packs.size():
		_set_status("No pack selected.")
		return
	var p: Dictionary = _packs[_selected_idx]
	var new_id: String = _prop_id_edit.text.strip_edges().replace(" ", "_")
	if new_id.is_empty():
		_set_status("Pack ID cannot be empty.")
		return
	# Check duplicate id
	for i: int in range(_packs.size()):
		if i != _selected_idx and _packs[i].get("id","") == new_id:
			_set_status("ID '%s' already in use." % new_id)
			return
	p["id"]          = new_id
	p["name"]        = _prop_name_edit.text.strip_edges()
	p["price"]       = int(_prop_price_spin.value)
	p["card_count"]  = int(_prop_count_spin.value)
	p["description"] = _prop_desc_edit.text.strip_edges()
	var hex: String  = _prop_accent_edit.text.strip_edges()
	if hex != "":
		var col := Color.html(hex) if hex.is_valid_html_color() else Color(1.0, 0.72, 0.22)
		p["accent"] = [col.r, col.g, col.b]
	p["pack_image"]     = _prop_image_edit.text.strip_edges()
	p["shop_available"] = _prop_shop_check.button_pressed
	var unlock_idx: int = _prop_unlock_chapter.selected
	var unlock_vn: String = ""
	if unlock_idx >= 0 and unlock_idx < _unlock_chapter_values.size():
		unlock_vn = str(_unlock_chapter_values[unlock_idx]).strip_edges()
	if unlock_vn != "":
		p["unlock_requires_chapter"] = unlock_vn
	else:
		p.erase("unlock_requires_chapter")
	_packs[_selected_idx] = p
	_refresh_pack_list()
	_set_status("Properties applied: %s" % p.get("name",""))

func _apply_pool() -> void:
	if _selected_idx < 0 or _selected_idx >= _packs.size():
		_set_status("No pack selected.")
		return
	var pool: Array = _collect_pool_rows()
	_packs[_selected_idx]["card_pool"] = pool
	_set_status("Pool saved: %d cards" % pool.size())

# ─────────────────────────────────────────────────────────────
# Card pool rows
# ─────────────────────────────────────────────────────────────
func _rebuild_pool_rows(pool: Array) -> void:
	for row_ref: Dictionary in _pool_rows:
		var hbox: HBoxContainer = row_ref.get("hbox") as HBoxContainer
		if hbox and is_instance_valid(hbox):
			hbox.queue_free()
	_pool_rows.clear()
	for entry: Dictionary in pool:
		_add_pool_row(
			str(entry.get("card_name", "")),
			str(entry.get("card_type", "")),
			float(entry.get("weight", 10)))

func _add_pool_row(card_name: String = "", card_type: String = "", weight: float = 10.0) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)

	var card_le := LineEdit.new()
	card_le.text = card_name
	card_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_le.text_changed.connect(func(v: String) -> void: _auto_type(card_le, v, hbox))
	hbox.add_child(card_le)

	var type_lbl := Label.new()
	type_lbl.custom_minimum_size = Vector2(78, 0)
	type_lbl.add_theme_font_size_override("font_size", 11)
	type_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if card_type != "":
		type_lbl.text = "unit" if card_type == "character" else card_type
		type_lbl.add_theme_color_override("font_color", _type_color(card_type))
	else:
		_auto_type(card_le, card_name, hbox)
	hbox.add_child(type_lbl)

	var weight_sb := SpinBox.new()
	weight_sb.min_value = 1; weight_sb.max_value = 1000
	weight_sb.step = 1; weight_sb.value = weight
	weight_sb.custom_minimum_size = Vector2(68, 0)
	hbox.add_child(weight_sb)

	var del_btn := Button.new()
	del_btn.text = "X"
	del_btn.custom_minimum_size = Vector2(28, 0)
	var row_ref: Dictionary = {"card_le": card_le, "type_lbl": type_lbl, "weight_sb": weight_sb, "hbox": hbox}
	del_btn.pressed.connect(func() -> void:
		_pool_rows.erase(row_ref)
		hbox.queue_free())
	hbox.add_child(del_btn)

	_pool_rows.append(row_ref)
	_pool_vbox.add_child(hbox)

func _auto_type(card_le: LineEdit, name: String, hbox: HBoxContainer) -> void:
	# Find the type_lbl in the same hbox
	var type_lbl: Label = null
	for ch in hbox.get_children():
		if ch is Label:
			type_lbl = ch as Label
			break
	if type_lbl == null:
		return
	var detected: String = ""
	if CardDatabase.get_character(name) != null:
		detected = "character"
	elif CardDatabase.get_trap(name) != null:
		detected = "trap"
	elif CardDatabase.get_tech(name) != null:
		detected = "tech"
	if detected != "":
		type_lbl.text = "unit" if detected == "character" else detected
		type_lbl.add_theme_color_override("font_color", _type_color(detected))
	else:
		type_lbl.text = "" if name.is_empty() else "?"
		type_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 0.6))

func _collect_pool_rows() -> Array:
	var result: Array = []
	for row_ref: Dictionary in _pool_rows:
		var card_le: LineEdit = row_ref.get("card_le") as LineEdit
		var type_lbl: Label   = row_ref.get("type_lbl") as Label
		var weight_sb: SpinBox = row_ref.get("weight_sb") as SpinBox
		if card_le == null or not is_instance_valid(card_le):
			continue
		var cname: String = card_le.text.strip_edges()
		if cname.is_empty():
			continue
		var ctype: String = type_lbl.text if type_lbl != null else "character"
		if ctype == "?":
			ctype = "character"
		result.append({
			"card_name": cname,
			"card_type": ctype,
			"weight":    int(weight_sb.value),
		})
	return result

func _on_add_card_pressed() -> void:
	if _selected_idx < 0:
		_set_status("Select a pack first.")
		return
	var name: String = _add_card_le.text.strip_edges()
	if name.is_empty():
		return
	_add_pool_row(name, "", _add_weight_sb.value)
	_add_card_le.text = ""
	_add_weight_sb.value = 10.0

func _type_color(t: String) -> Color:
	match t:
		"character": return Color(1.0, 0.71, 0.2, 1.0)
		"trap":      return Color(1.0, 0.40, 0.45, 1.0)
		"tech":      return Color(0.30, 0.90, 0.45, 1.0)
	return Color(0.7, 0.7, 0.75)

# ─────────────────────────────────────────────────────────────
# New / Delete pack
# ─────────────────────────────────────────────────────────────
func _on_new_pack() -> void:
	var idx: int = _packs.size()
	_packs.append({
		"id":          "custom_pack_%d" % (idx + 1),
		"name":        "Custom Pack %d" % (idx + 1),
		"price":       500,
		"card_count":  3,
		"description": "",
		"accent":      [1.0, 0.72, 0.22],
		"pack_image":     "",
		"card_pool":      [],
		"shop_available": true,
	})
	_select_pack(idx)
	_set_status("New pack created. Edit properties and save.")

func _on_delete_pack() -> void:
	if _selected_idx < 0 or _selected_idx >= _packs.size():
		_set_status("No pack selected.")
		return
	var name: String = _packs[_selected_idx].get("name","?")
	_packs.remove_at(_selected_idx)
	_selected_idx = mini(_selected_idx, _packs.size() - 1)
	_rebuild_pool_rows([])
	_refresh_pack_list()
	_set_status("Deleted: %s" % name)

# ─────────────────────────────────────────────────────────────
# Save
# ─────────────────────────────────────────────────────────────
func _save_all() -> void:
	# Apply any pending pool changes for the selected pack
	if _selected_idx >= 0 and _selected_idx < _packs.size():
		_packs[_selected_idx]["card_pool"] = _collect_pool_rows()
	ShopManager._custom_packs = _packs.duplicate(true)
	ShopManager.save_custom_packs()
	ShopManager.reload_gallery_chapter_labels()
	_set_status("Saved %d custom pack(s)." % _packs.size())

# ─────────────────────────────────────────────────────────────
# Image file dialog
# ─────────────────────────────────────────────────────────────
func _open_image_dialog() -> void:
	var dlg := FileDialog.new()
	dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dlg.access    = FileDialog.ACCESS_RESOURCES
	dlg.filters   = PackedStringArray(["*.png ; PNG Images"])
	dlg.current_dir = "res://assets/textures/cards/booster_pack"
	dlg.size = Vector2i(780, 520)
	add_child(dlg)
	dlg.popup_centered()
	dlg.file_selected.connect(func(path: String) -> void:
		_prop_image_edit.text = path
		dlg.queue_free())
	dlg.canceled.connect(func() -> void: dlg.queue_free())

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _lbl(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.75, 0.78, 0.88, 0.7))
	return l

func _sep() -> ColorRect:
	var s := ColorRect.new()
	s.custom_minimum_size = Vector2(0, 1)
	s.color = Color(1.0, 0.72, 0.22, 0.15)
	return s

func _set_status(text: String) -> void:
	if _status_lbl:
		_status_lbl.text = text
