extends Control

# ─────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────
const RARITY_NAMES: Array    = ["COMMON", "UNCOMMON", "RARE", "LEGENDARY", "EXOTIC"]
const AFFINITY_NAMES: Array  = ["DIVINE", "CHAOS", "NATURE", "ARCANE", "COSMIC", "BIO", "ANIMA"]
const PANEL_W: float         = 1200.0
const PANEL_H: float         = 780.0
const LEFT_W: float          = 270.0
const HEADER_H: float        = 54.0
const PAD: float             = 14.0

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var _current_tab: String  = "characters"
var _selected_name: String = ""
var _selected_btn: Button  = null
var _orig: Dictionary      = {}   # field_name -> original value

# ─────────────────────────────────────────────────────────────
# UI node references
# ─────────────────────────────────────────────────────────────
var _search_edit:    LineEdit
var _list_vbox:      VBoxContainer
var _tab_btns:       Dictionary = {}   # tab_key -> Button

var _name_lbl:       Label
var _badge_lbl:      Label
var _desc_lbl:       Label
var _fields_vbox:    VBoxContainer
var _status_lbl:     Label
var _apply_btn:      Button
var _reset_btn:      Button

# Input nodes (nullable – only present when a card is selected)
var _spin_atk:       SpinBox      = null
var _spin_def:       SpinBox      = null
var _spin_cost:      SpinBox      = null
var _opt_rarity:     OptionButton = null
var _opt_affinity:   OptionButton = null

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 50
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_populate_list()

# ─────────────────────────────────────────────────────────────
# UI construction
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# ── Dim backdrop ──────────────────────────────────────────
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.80)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# ── Main panel ────────────────────────────────────────────
	var panel := Panel.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color             = Color(0.047, 0.067, 0.133, 0.99)
	psb.border_color         = Color(0.40, 0.70, 1.00, 0.60)
	psb.border_width_left    = 2; psb.border_width_top    = 2
	psb.border_width_right   = 2; psb.border_width_bottom = 2
	psb.corner_radius_top_left     = 8; psb.corner_radius_top_right    = 8
	psb.corner_radius_bottom_right = 8; psb.corner_radius_bottom_left  = 8
	panel.add_theme_stylebox_override("panel", psb)
	panel.position = Vector2(
		(1600.0 - PANEL_W) * 0.5,
		(900.0  - PANEL_H) * 0.5)
	panel.size = Vector2(PANEL_W, PANEL_H)
	add_child(panel)

	# ── Header bar ────────────────────────────────────────────
	var title := Label.new()
	title.text = "CARD EDITOR"
	title.position = Vector2(PAD, 13.0)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.45, 0.82, 1.0))
	panel.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.position = Vector2(PANEL_W - 46.0, 9.0)
	close_btn.size = Vector2(34.0, 34.0)
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	close_btn.pressed.connect(queue_free)
	panel.add_child(close_btn)

	var hdiv := ColorRect.new()
	hdiv.position = Vector2(0.0, HEADER_H - 1.0)
	hdiv.size     = Vector2(PANEL_W, 1.0)
	hdiv.color    = Color(0.40, 0.70, 1.00, 0.30)
	panel.add_child(hdiv)

	# ── Left panel ────────────────────────────────────────────
	const LX: float  = PAD
	const TOP: float = HEADER_H + 8.0

	# Search
	_search_edit = LineEdit.new()
	_search_edit.position         = Vector2(LX, TOP)
	_search_edit.size             = Vector2(LEFT_W, 34.0)
	_search_edit.placeholder_text = "Search cards..."
	_search_edit.text_changed.connect(_on_search_changed)
	panel.add_child(_search_edit)

	# Tab buttons
	const TAB_Y: float  = TOP + 42.0
	const TAB_H: float  = 32.0
	var tab_labels: Array = ["CHARS", "TRAPS", "TECH"]
	var tab_keys:   Array = ["characters", "traps", "tech"]
	var tab_w: float = LEFT_W / 3.0
	for i: int in range(3):
		var tb := Button.new()
		tb.text     = tab_labels[i]
		tb.position = Vector2(LX + i * tab_w, TAB_Y)
		tb.size     = Vector2(tab_w, TAB_H)
		tb.add_theme_font_size_override("font_size", 12)
		var key: String = tab_keys[i]
		tb.pressed.connect(func() -> void: _switch_tab(key))
		panel.add_child(tb)
		_tab_btns[key] = tb

	# Card list scroll
	const LIST_Y: float = TAB_Y + TAB_H + 6.0
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(LX, LIST_Y)
	scroll.size     = Vector2(LEFT_W, PANEL_H - LIST_Y - 10.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(_list_vbox)

	# Vertical divider
	var vdiv := ColorRect.new()
	vdiv.position = Vector2(LX + LEFT_W + 8.0, HEADER_H)
	vdiv.size     = Vector2(1.0, PANEL_H - HEADER_H - 8.0)
	vdiv.color    = Color(0.40, 0.70, 1.00, 0.25)
	panel.add_child(vdiv)

	# ── Right panel ───────────────────────────────────────────
	const RX: float  = LX + LEFT_W + 20.0
	const RW: float  = PANEL_W - RX - PAD

	_name_lbl = Label.new()
	_name_lbl.position = Vector2(RX, TOP)
	_name_lbl.size     = Vector2(RW, 38.0)
	_name_lbl.text     = "Select a card from the list"
	_name_lbl.add_theme_font_size_override("font_size", 22)
	_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.60))
	panel.add_child(_name_lbl)

	_badge_lbl = Label.new()
	_badge_lbl.position = Vector2(RX, TOP + 42.0)
	_badge_lbl.size     = Vector2(RW, 22.0)
	_badge_lbl.add_theme_font_size_override("font_size", 12)
	_badge_lbl.add_theme_color_override("font_color", Color(0.50, 0.80, 1.0))
	panel.add_child(_badge_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.position    = Vector2(RX, TOP + 68.0)
	_desc_lbl.size        = Vector2(RW, 72.0)
	_desc_lbl.add_theme_font_size_override("font_size", 13)
	_desc_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_desc_lbl)

	# Divider under description
	var fdiv := ColorRect.new()
	fdiv.position = Vector2(RX, TOP + 146.0)
	fdiv.size     = Vector2(RW, 1.0)
	fdiv.color    = Color(0.40, 0.70, 1.00, 0.20)
	panel.add_child(fdiv)

	_fields_vbox = VBoxContainer.new()
	_fields_vbox.position = Vector2(RX, TOP + 154.0)
	_fields_vbox.size     = Vector2(RW, 440.0)
	_fields_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(_fields_vbox)

	# Status + buttons at bottom
	_status_lbl = Label.new()
	_status_lbl.position = Vector2(RX, PANEL_H - 86.0)
	_status_lbl.size     = Vector2(RW, 24.0)
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
	panel.add_child(_status_lbl)

	_apply_btn = Button.new()
	_apply_btn.text     = "APPLY CHANGES"
	_apply_btn.position = Vector2(RX, PANEL_H - 58.0)
	_apply_btn.size     = Vector2(210.0, 42.0)
	_apply_btn.add_theme_font_size_override("font_size", 14)
	_apply_btn.disabled = true
	_apply_btn.pressed.connect(_on_apply)
	panel.add_child(_apply_btn)

	_reset_btn = Button.new()
	_reset_btn.text     = "RESET"
	_reset_btn.position = Vector2(RX + 220.0, PANEL_H - 58.0)
	_reset_btn.size     = Vector2(110.0, 42.0)
	_reset_btn.add_theme_font_size_override("font_size", 14)
	_reset_btn.disabled = true
	_reset_btn.pressed.connect(_on_reset)
	panel.add_child(_reset_btn)

	_update_tab_styles()

# ─────────────────────────────────────────────────────────────
# List population
# ─────────────────────────────────────────────────────────────
func _populate_list(filter: String = "") -> void:
	for child in _list_vbox.get_children():
		child.queue_free()
	_selected_btn = null

	var names: Array = []
	match _current_tab:
		"characters": names = CardDatabase.get_all_character_names()
		"traps":      names = CardDatabase.get_all_trap_names()
		"tech":       names = CardDatabase.get_all_tech_names()
	names.sort()

	var q: String = filter.strip_edges().to_lower()
	for n: String in names:
		if q != "" and not n.to_lower().contains(q):
			continue
		var btn := Button.new()
		btn.text                       = n
		btn.size_flags_horizontal      = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size        = Vector2(0.0, 32.0)
		btn.add_theme_font_size_override("font_size", 13)
		btn.alignment                  = HORIZONTAL_ALIGNMENT_LEFT
		var snap_name: String = n
		btn.pressed.connect(func() -> void: _select_card(snap_name, btn))
		_list_vbox.add_child(btn)

		# Re-highlight if this card is still selected
		if n == _selected_name:
			_selected_btn = btn
			_set_btn_selected(btn, true)

func _on_search_changed(text: String) -> void:
	_populate_list(text)

# ─────────────────────────────────────────────────────────────
# Tab switching
# ─────────────────────────────────────────────────────────────
func _switch_tab(key: String) -> void:
	_current_tab  = key
	_selected_name = ""
	_selected_btn  = null
	_search_edit.text = ""
	_populate_list()
	_clear_detail()
	_update_tab_styles()

func _update_tab_styles() -> void:
	for key: String in _tab_btns:
		var b: Button = _tab_btns[key]
		if key == _current_tab:
			b.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
		else:
			b.remove_theme_color_override("font_color")

func _set_btn_selected(btn: Button, selected: bool) -> void:
	if selected:
		btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	else:
		btn.remove_theme_color_override("font_color")

# ─────────────────────────────────────────────────────────────
# Card selection & detail view
# ─────────────────────────────────────────────────────────────
func _select_card(card_name: String, btn: Button) -> void:
	if is_instance_valid(_selected_btn) and _selected_btn != btn:
		_set_btn_selected(_selected_btn, false)
	_selected_btn  = btn
	_selected_name = card_name
	_set_btn_selected(btn, true)
	_status_lbl.text = ""
	_build_detail(card_name)

func _clear_detail() -> void:
	_name_lbl.text   = "Select a card from the list"
	_badge_lbl.text  = ""
	_desc_lbl.text   = ""
	for child in _fields_vbox.get_children():
		child.queue_free()
	_spin_atk = null; _spin_def = null; _spin_cost = null
	_opt_rarity = null; _opt_affinity = null
	_apply_btn.disabled = true
	_reset_btn.disabled = true
	_status_lbl.text = ""

func _build_detail(card_name: String) -> void:
	for child in _fields_vbox.get_children():
		child.queue_free()
	_spin_atk = null; _spin_def = null; _spin_cost = null
	_opt_rarity = null; _opt_affinity = null
	_orig.clear()

	match _current_tab:
		"characters":
			var d: CharacterData = CardDatabase.get_character(card_name)
			if d == null: return
			_name_lbl.text  = d.card_name
			_badge_lbl.text = "CHARACTER  ·  %s  ·  %s" % [
				AFFINITY_NAMES[d.affinity],
				RARITY_NAMES[d.rarity]]
			_desc_lbl.text  = d.ability_description

			_orig = {
				"base_atk":     d.base_atk,
				"base_def":     d.base_def,
				"crystal_cost": d.crystal_cost,
				"rarity":       d.rarity,
				"affinity":     d.affinity,
			}
			_spin_atk      = _add_spin_field("ATK",      d.base_atk,     0, 9999)
			_spin_def      = _add_spin_field("DEF",      d.base_def,     0, 9999)
			_spin_cost     = _add_spin_field("Cost",     d.crystal_cost, 0, 99999)
			_opt_rarity    = _add_option_field("Rarity",   RARITY_NAMES,   d.rarity)
			_opt_affinity  = _add_option_field("Affinity", AFFINITY_NAMES, d.affinity)

		"traps":
			var d: TrapData = CardDatabase.get_trap(card_name)
			if d == null: return
			_name_lbl.text  = d.card_name
			_badge_lbl.text = "TRAP  ·  %s" % RARITY_NAMES[d.rarity]
			_desc_lbl.text  = d.effect_description

			_orig = {
				"crystal_cost": d.crystal_cost,
				"rarity":       d.rarity,
			}
			_spin_cost  = _add_spin_field("Cost",   d.crystal_cost, 0, 99999)
			_opt_rarity = _add_option_field("Rarity", RARITY_NAMES,   d.rarity)

		"tech":
			var d: TechCardData = CardDatabase.get_tech(card_name)
			if d == null: return
			_name_lbl.text  = d.card_name
			var chain: String = ("Chain: requires '%s'" % d.required_prior_card) \
				if d.required_prior_card != "" else ""
			_badge_lbl.text = "TECH  ·  %s  %s" % [RARITY_NAMES[d.rarity], chain]
			_desc_lbl.text  = d.effect_description

			_orig = {
				"crystal_cost": d.crystal_cost,
				"rarity":       d.rarity,
			}
			_spin_cost  = _add_spin_field("Cost",   d.crystal_cost, 0, 99999)
			_opt_rarity = _add_option_field("Rarity", RARITY_NAMES,   d.rarity)

	_apply_btn.disabled = false
	_reset_btn.disabled = false

# ── Field builder helpers ──────────────────────────────────────
func _add_spin_field(label_text: String, value: int, min_v: int, max_v: int) -> SpinBox:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_fields_vbox.add_child(row)

	var lbl := Label.new()
	lbl.text                    = label_text
	lbl.custom_minimum_size     = Vector2(120.0, 0.0)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	lbl.vertical_alignment      = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var spin := SpinBox.new()
	spin.min_value              = min_v
	spin.max_value              = max_v
	spin.step                   = 1
	spin.value                  = value
	spin.custom_minimum_size    = Vector2(180.0, 34.0)
	spin.add_theme_font_size_override("font_size", 14)
	row.add_child(spin)

	return spin

func _add_option_field(label_text: String, options: Array, selected_idx: int) -> OptionButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_fields_vbox.add_child(row)

	var lbl := Label.new()
	lbl.text                = label_text
	lbl.custom_minimum_size = Vector2(120.0, 0.0)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(180.0, 34.0)
	opt.add_theme_font_size_override("font_size", 14)
	for o: String in options:
		opt.add_item(o)
	opt.select(selected_idx)
	row.add_child(opt)

	return opt

# ─────────────────────────────────────────────────────────────
# Apply / Reset
# ─────────────────────────────────────────────────────────────
func _on_apply() -> void:
	if _selected_name == "":
		return

	match _current_tab:
		"characters":
			var d: CharacterData = CardDatabase.get_character(_selected_name)
			if d == null: return
			if _spin_atk:     d.base_atk      = int(_spin_atk.value)
			if _spin_def:     d.base_def      = int(_spin_def.value)
			if _spin_cost:    d.crystal_cost  = int(_spin_cost.value)
			if _opt_rarity:   d.rarity        = _opt_rarity.selected
			if _opt_affinity: d.affinity      = _opt_affinity.selected
			_badge_lbl.text = "CHARACTER  ·  %s  ·  %s" % [
				AFFINITY_NAMES[d.affinity], RARITY_NAMES[d.rarity]]

		"traps":
			var d: TrapData = CardDatabase.get_trap(_selected_name)
			if d == null: return
			if _spin_cost:  d.crystal_cost = int(_spin_cost.value)
			if _opt_rarity: d.rarity       = _opt_rarity.selected
			_badge_lbl.text = "TRAP  ·  %s" % RARITY_NAMES[d.rarity]

		"tech":
			var d: TechCardData = CardDatabase.get_tech(_selected_name)
			if d == null: return
			if _spin_cost:  d.crystal_cost = int(_spin_cost.value)
			if _opt_rarity: d.rarity       = _opt_rarity.selected
			var chain: String = ("Chain: requires '%s'" % d.required_prior_card) \
				if d.required_prior_card != "" else ""
			_badge_lbl.text = "TECH  ·  %s  %s" % [RARITY_NAMES[d.rarity], chain]

	_status_lbl.text = "✓ Changes applied to %s" % _selected_name

	# Update orig so a subsequent reset goes back to newly applied values
	_sync_orig_from_inputs()

func _on_reset() -> void:
	if _orig.is_empty():
		return
	if _spin_atk and    _orig.has("base_atk"):     _spin_atk.value    = _orig["base_atk"]
	if _spin_def and    _orig.has("base_def"):     _spin_def.value    = _orig["base_def"]
	if _spin_cost and   _orig.has("crystal_cost"): _spin_cost.value   = _orig["crystal_cost"]
	if _opt_rarity and  _orig.has("rarity"):       _opt_rarity.select(_orig["rarity"])
	if _opt_affinity and _orig.has("affinity"):    _opt_affinity.select(_orig["affinity"])
	_status_lbl.text = "Reset to original values."

func _sync_orig_from_inputs() -> void:
	if _spin_atk:     _orig["base_atk"]     = int(_spin_atk.value)
	if _spin_def:     _orig["base_def"]     = int(_spin_def.value)
	if _spin_cost:    _orig["crystal_cost"] = int(_spin_cost.value)
	if _opt_rarity:   _orig["rarity"]       = _opt_rarity.selected
	if _opt_affinity: _orig["affinity"]     = _opt_affinity.selected

# ─────────────────────────────────────────────────────────────
# Close on Escape
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed \
			and (event as InputEventKey).keycode == KEY_ESCAPE:
		queue_free()
		get_viewport().set_input_as_handled()
