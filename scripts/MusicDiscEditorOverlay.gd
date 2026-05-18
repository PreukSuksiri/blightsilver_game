extends Control
# Music Disc Editor — visual admin tool for creating and editing music disc products.
# Each product: {id, name, price, description, music_path}
# Persisted to res://shop/music_discs.json via ShopManager.

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var _products: Array  = []
var _selected_idx: int = -1

# Left panel
var _list_vbox:   VBoxContainer = null
var _status_lbl:  Label         = null

# Right panel fields
var _prop_id_edit:    LineEdit = null
var _prop_name_edit:  LineEdit = null
var _prop_price_spin: SpinBox  = null
var _prop_desc_edit:  TextEdit = null
var _prop_music_edit: LineEdit = null   # res:// path to music file

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 50
	_products = ShopManager._music_disc_products.duplicate(true)
	_build_ui()
	_refresh_list()

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
	sb.border_color = Color(0.78, 0.35, 1.0, 0.35)
	header.add_theme_stylebox_override("panel", sb)
	add_child(header)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left  = 16.0; hbox.offset_right = -16.0
	hbox.add_theme_constant_override("separation", 12)
	header.add_child(hbox)

	var title := Label.new()
	title.text = "MUSIC DISC EDITOR"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.78, 0.55, 1.0))
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
	sb.bg_color = Color(0.03, 0.04, 0.14, 0.98)
	sb.border_width_right = 1
	sb.border_color = Color(0.78, 0.35, 1.0, 0.18)
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12; vbox.offset_right = -12
	vbox.offset_top  = 12; vbox.offset_bottom = -12
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "DISC PRODUCTS"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(0.78, 0.55, 1.0, 0.7))
	vbox.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	vbox.add_child(scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(_list_vbox)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(0.78, 0.35, 1.0, 0.15)
	vbox.add_child(sep)

	var new_btn := Button.new()
	new_btn.text = "+ New Disc Product"
	new_btn.pressed.connect(_on_new_product)
	vbox.add_child(new_btn)

	var del_btn := Button.new()
	del_btn.text = "Delete Selected"
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	del_btn.pressed.connect(_on_delete_product)
	vbox.add_child(del_btn)

func _build_right_panel(parent: Control) -> void:
	var panel := Panel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.16, 0.98)
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.add_child(scroll)

	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left",   20)
	pad.add_theme_constant_override("margin_right",  20)
	pad.add_theme_constant_override("margin_top",    16)
	pad.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(pad)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	pad.add_child(inner)

	var hdr := Label.new()
	hdr.text = "DISC PROPERTIES"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(0.78, 0.55, 1.0, 0.7))
	inner.add_child(hdr)

	inner.add_child(_lbl("Disc ID (unique, no spaces)"))
	_prop_id_edit = LineEdit.new()
	_prop_id_edit.placeholder_text = "e.g. disc_battle_theme"
	inner.add_child(_prop_id_edit)

	inner.add_child(_lbl("Display Name"))
	_prop_name_edit = LineEdit.new()
	_prop_name_edit.placeholder_text = "e.g. Battle Theme"
	inner.add_child(_prop_name_edit)

	inner.add_child(_lbl("Price (credits)"))
	_prop_price_spin = SpinBox.new()
	_prop_price_spin.min_value = 0; _prop_price_spin.max_value = 99999
	_prop_price_spin.step = 50; _prop_price_spin.value = 300
	inner.add_child(_prop_price_spin)

	inner.add_child(_lbl("Description"))
	_prop_desc_edit = TextEdit.new()
	_prop_desc_edit.custom_minimum_size = Vector2(0, 56)
	_prop_desc_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	inner.add_child(_prop_desc_edit)

	inner.add_child(_lbl("Music File (res:// path to .mp3 / .ogg)"))
	var music_row := HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 6)
	inner.add_child(music_row)
	_prop_music_edit = LineEdit.new()
	_prop_music_edit.placeholder_text = "res://assets/audio/bgm_battle_1.mp3"
	_prop_music_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_row.add_child(_prop_music_edit)
	var browse_btn := Button.new()
	browse_btn.text = "Browse"
	browse_btn.custom_minimum_size = Vector2(64, 0)
	browse_btn.pressed.connect(_open_music_dialog)
	music_row.add_child(browse_btn)

	inner.add_child(_sep())

	var apply_btn := Button.new()
	apply_btn.text = "Apply Properties"
	apply_btn.pressed.connect(_apply_props)
	inner.add_child(apply_btn)

# ─────────────────────────────────────────────────────────────
# List
# ─────────────────────────────────────────────────────────────
func _refresh_list() -> void:
	for ch in _list_vbox.get_children():
		ch.queue_free()
	for i: int in range(_products.size()):
		var p: Dictionary = _products[i]
		var btn := Button.new()
		btn.text = p.get("name", p.get("id", "?"))
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == _selected_idx:
			btn.add_theme_color_override("font_color", Color(0.78, 0.55, 1.0))
		var idx_cap := i
		btn.pressed.connect(func() -> void: _select(idx_cap))
		_list_vbox.add_child(btn)

func _select(idx: int) -> void:
	_selected_idx = idx
	_refresh_list()
	_populate_props()

func _populate_props() -> void:
	if _selected_idx < 0 or _selected_idx >= _products.size():
		return
	var p: Dictionary = _products[_selected_idx]
	_prop_id_edit.text    = str(p.get("id", ""))
	_prop_name_edit.text  = str(p.get("name", ""))
	_prop_price_spin.value = float(p.get("price", 300))
	_prop_desc_edit.text  = str(p.get("description", ""))
	_prop_music_edit.text = str(p.get("music_path", ""))

# ─────────────────────────────────────────────────────────────
# Applying
# ─────────────────────────────────────────────────────────────
func _apply_props() -> void:
	if _selected_idx < 0 or _selected_idx >= _products.size():
		_set_status("No product selected.")
		return
	var new_id: String = _prop_id_edit.text.strip_edges().replace(" ", "_")
	if new_id.is_empty():
		_set_status("ID cannot be empty.")
		return
	for i: int in range(_products.size()):
		if i != _selected_idx and _products[i].get("id","") == new_id:
			_set_status("ID '%s' already in use." % new_id)
			return
	var p: Dictionary = _products[_selected_idx]
	p["id"]          = new_id
	p["name"]        = _prop_name_edit.text.strip_edges()
	p["price"]       = int(_prop_price_spin.value)
	p["description"] = _prop_desc_edit.text.strip_edges()
	p["music_path"]  = _prop_music_edit.text.strip_edges()
	_products[_selected_idx] = p
	_refresh_list()
	_set_status("Applied: %s" % p.get("name",""))

# ─────────────────────────────────────────────────────────────
# New / Delete
# ─────────────────────────────────────────────────────────────
func _on_new_product() -> void:
	var idx: int = _products.size()
	_products.append({
		"id":          "disc_%d" % (idx + 1),
		"name":        "Disc %d" % (idx + 1),
		"price":       300,
		"description": "",
		"music_path":  "",
	})
	_select(idx)
	_set_status("New disc product created. Edit and save.")

func _on_delete_product() -> void:
	if _selected_idx < 0 or _selected_idx >= _products.size():
		_set_status("No product selected.")
		return
	var name: String = _products[_selected_idx].get("name","?")
	_products.remove_at(_selected_idx)
	_selected_idx = mini(_selected_idx, _products.size() - 1)
	_refresh_list()
	if _selected_idx >= 0:
		_populate_props()
	_set_status("Deleted: %s" % name)

# ─────────────────────────────────────────────────────────────
# Music file dialog
# ─────────────────────────────────────────────────────────────
func _open_music_dialog() -> void:
	var dlg := FileDialog.new()
	dlg.file_mode   = FileDialog.FILE_MODE_OPEN_FILE
	dlg.access      = FileDialog.ACCESS_RESOURCES
	dlg.filters     = PackedStringArray(["*.mp3,*.ogg,*.wav ; Audio Files"])
	dlg.current_dir = "res://assets/audio"
	dlg.size        = Vector2i(780, 520)
	add_child(dlg)
	dlg.popup_centered()
	dlg.file_selected.connect(func(path: String) -> void:
		_prop_music_edit.text = path
		dlg.queue_free())
	dlg.canceled.connect(func() -> void: dlg.queue_free())

# ─────────────────────────────────────────────────────────────
# Save
# ─────────────────────────────────────────────────────────────
func _save_all() -> void:
	ShopManager._music_disc_products = _products.duplicate(true)
	ShopManager.save_music_disc_products()
	_set_status("Saved %d disc product(s)." % _products.size())

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
	s.color = Color(0.78, 0.35, 1.0, 0.15)
	return s

func _set_status(text: String) -> void:
	if _status_lbl:
		_status_lbl.text = text
