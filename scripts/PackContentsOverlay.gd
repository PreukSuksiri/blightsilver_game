extends Control
# Full-screen overlay showing all cards in a pack's card_pool with drop chances.
# Boosted cards are highlighted in green bold.
# Usage: PackContentsOverlay.open(parent, pack_id)

static func open(parent: Node, pack_id: String) -> void:
	var inst: Control = load("res://scripts/PackContentsOverlay.gd").new()
	inst.set("_pack_id", pack_id)
	parent.add_child(inst)

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var _pack_id: String = ""

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 80
	_build_ui()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed:
		var ke := event as InputEventKey
		if ke.keycode == KEY_ESCAPE:
			queue_free()

# ─────────────────────────────────────────────────────────────
# Build UI
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Dimmer
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.88)
	dimmer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(dimmer)

	# Centre panel
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(640.0, 520.0)
	panel.offset_left  = -320.0
	panel.offset_top   = -260.0
	panel.offset_right =  320.0
	panel.offset_bottom = 260.0
	var sb := StyleBoxFlat.new()
	sb.bg_color         = Color(0.04, 0.06, 0.14, 1.0)
	sb.border_color     = Color(0.25, 0.55, 1.0, 1.0)
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_width_top    = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left     = 8
	sb.corner_radius_top_right    = 8
	sb.corner_radius_bottom_left  = 8
	sb.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	# Title
	var pack: Dictionary = ShopManager.get_pack(_pack_id)
	var pack_name: String = str(pack.get("name", _pack_id)) if not pack.is_empty() else _pack_id
	var draw_count: int  = int(pack.get("card_count", 3)) if not pack.is_empty() else 3

	var title := Label.new()
	title.text = "%s — Contents" % pack_name
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top  = 14.0
	title.offset_bottom = 44.0
	title.offset_left  = 16.0
	title.offset_right = -60.0
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var sub := Label.new()
	sub.text = "Draws %d card(s) per open" % draw_count
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.offset_top    = 38.0
	sub.offset_bottom = 56.0
	sub.offset_left   = 16.0
	sub.offset_right  = -16.0
	panel.add_child(sub)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left   = -48.0
	close_btn.offset_top    = 8.0
	close_btn.offset_right  = -8.0
	close_btn.offset_bottom = 44.0
	close_btn.add_theme_font_override("font", FontManager.ui_font(400))
	close_btn.add_theme_font_size_override("font_size", 16)
	_style_close_btn(close_btn)
	close_btn.pressed.connect(queue_free)
	panel.add_child(close_btn)

	# Column headers
	_add_row_header(panel)

	# Scrollable list
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = 100.0
	scroll.offset_bottom = -16.0
	scroll.offset_left   = 8.0
	scroll.offset_right  = -8.0
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(vbox)

	var rates: Array = ShopManager.get_pack_drop_rates(_pack_id)
	if rates.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No card pool defined for this pack."
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty_lbl)
	else:
		for i: int in range(rates.size()):
			var entry: Dictionary = rates[i]
			_add_card_row(vbox, entry, i % 2 == 1)

func _add_row_header(panel: Panel) -> void:
	var hdr := HBoxContainer.new()
	hdr.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hdr.offset_top    = 60.0
	hdr.offset_bottom = 92.0
	hdr.offset_left   = 8.0
	hdr.offset_right  = -8.0
	hdr.add_theme_constant_override("separation", 0)

	for pair: Array in [["Card Name", 0.5], ["Type", 0.2], ["Drop Chance", 0.3]]:
		var lbl := Label.new()
		lbl.text = str(pair[0])
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_stretch_ratio = float(pair[1])
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9))
		hdr.add_child(lbl)

	panel.add_child(hdr)

func _add_card_row(parent: VBoxContainer, entry: Dictionary, alt_bg: bool) -> void:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row_sb := StyleBoxFlat.new()
	row_sb.bg_color = Color(0.08, 0.1, 0.18, 1.0) if alt_bg else Color(0.05, 0.07, 0.14, 1.0)
	row_sb.corner_radius_top_left     = 4
	row_sb.corner_radius_top_right    = 4
	row_sb.corner_radius_bottom_left  = 4
	row_sb.corner_radius_bottom_right = 4
	row.add_theme_stylebox_override("panel", row_sb)
	parent.add_child(row)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	row.add_child(hbox)

	var card_name: String = str(entry.get("card_name", ""))
	var card_type: String = str(entry.get("card_type", ""))
	var drop_pct:  float  = float(entry.get("drop_chance", 0.0))
	var is_boosted: bool  = bool(entry.get("is_boosted", false))

	var name_lbl := Label.new()
	name_lbl.text = card_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.size_flags_stretch_ratio = 0.5
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	name_lbl.add_theme_constant_override("outline_size", 0)
	hbox.add_child(name_lbl)

	var type_lbl := Label.new()
	type_lbl.text = "Unit" if card_type == "character" else card_type.capitalize()
	type_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_lbl.size_flags_stretch_ratio = 0.2
	type_lbl.add_theme_font_size_override("font_size", 13)
	type_lbl.add_theme_color_override("font_color", _type_color(card_type))
	hbox.add_child(type_lbl)

	var pct_lbl := Label.new()
	pct_lbl.text = "%.2f%%" % drop_pct
	if is_boosted:
		pct_lbl.text += "  +"
	pct_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pct_lbl.size_flags_stretch_ratio = 0.3
	pct_lbl.add_theme_font_size_override("font_size", 14)
	if is_boosted:
		pct_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.35))
	else:
		pct_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	hbox.add_child(pct_lbl)

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _type_color(t: String) -> Color:
	match t:
		"character": return Color(0.4, 0.7, 1.0)
		"trap":      return Color(1.0, 0.45, 0.35)
		"tech":      return Color(0.5, 1.0, 0.6)
	return Color(0.7, 0.7, 0.7)

func _style_close_btn(btn: Button) -> void:
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus"]:
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color(0.55, 0.1, 0.1, 1.0) if state != &"normal" else Color(0.3, 0.05, 0.05, 1.0)
		bsb.corner_radius_top_left     = 4
		bsb.corner_radius_top_right    = 4
		bsb.corner_radius_bottom_left  = 4
		bsb.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override(state, bsb)
	btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
