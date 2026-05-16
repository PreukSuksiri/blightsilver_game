class_name UnionModal
extends Control
## UnionModal — full-screen overlay for selecting a Union summon.
## Mirrors _refresh_tech_hand layout exactly.
## Open via:   UnionModal.open(parent, player, available_unions)
##   available_unions = Array of { union: UnionData, zone_cells: Array[Vector2i] }
##
## Pressing the UNION button emits union_selected(player, union_name, zone_cells).
## Emits union_cancelled when dismissed without a selection.

signal union_selected(player: int, union_name: String, zone_cells: Array)
signal union_cancelled

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var _player: int    = 0
var _available: Array = []   # [{union: UnionData, zone_cells: Array}]

# ─────────────────────────────────────────────────────────────
# Factory
# ─────────────────────────────────────────────────────────────
static func open(parent: Node, player: int, available_unions: Array) -> UnionModal:
	var modal := UnionModal.new()
	modal._player    = player
	modal._available = available_unions
	modal.z_index    = 50
	parent.add_child(modal)
	modal._build_ui()
	return modal

# ─────────────────────────────────────────────────────────────
# UI — mirrors _refresh_tech_hand exactly
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	const PAD: int = 20
	const GAP: int = 12

	# Dim backdrop — clicking cancels
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_on_cancel())
	add_child(dimmer)

	# Panel filling screen (with small margin)
	var panel_c := PanelContainer.new()
	panel_c.layout_mode = 1
	panel_c.anchor_left   = 0.0; panel_c.anchor_top    = 0.0
	panel_c.anchor_right  = 1.0; panel_c.anchor_bottom = 1.0
	panel_c.offset_left   = PAD; panel_c.offset_top    = PAD
	panel_c.offset_right  = -PAD; panel_c.offset_bottom = -PAD
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.05, 0.07, 0.17, 0.98)
	psb.border_width_left   = 2; psb.border_width_top    = 2
	psb.border_width_right  = 2; psb.border_width_bottom = 2
	psb.border_color = Color(0.30, 0.85, 1.0, 0.50)
	psb.corner_radius_top_left     = 8; psb.corner_radius_top_right    = 8
	psb.corner_radius_bottom_left  = 8; psb.corner_radius_bottom_right = 8
	psb.content_margin_left   = PAD; psb.content_margin_right  = PAD
	psb.content_margin_top    = 12;  psb.content_margin_bottom = PAD
	panel_c.add_theme_stylebox_override("panel", psb)
	add_child(panel_c)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", GAP)
	panel_c.add_child(vbox)

	# ── Title row ─────────────────────────────────────────
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "UNION SUMMON  —  Choose a union to summon"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.30, 0.85, 1.0))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(100.0, 36.0)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.pressed.connect(_on_cancel)
	title_row.add_child(close_btn)

	# ── Card row (with scroll when > 3 unions) ────────────
	var n: int = _available.size()
	var show_scroll: bool = n > 3
	var scroll_c: ScrollContainer = null

	if show_scroll:
		var scroll_row := HBoxContainer.new()
		scroll_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_row.add_theme_constant_override("separation", 4)
		vbox.add_child(scroll_row)

		var left_arr := Button.new()
		left_arr.text = "<"
		left_arr.custom_minimum_size = Vector2(40.0, 0.0)
		left_arr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		left_arr.add_theme_font_size_override("font_size", 22)
		scroll_row.add_child(left_arr)

		scroll_c = ScrollContainer.new()
		scroll_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_c.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		scroll_c.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll_c.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
		scroll_row.add_child(scroll_c)

		var right_arr := Button.new()
		right_arr.text = ">"
		right_arr.custom_minimum_size = Vector2(40.0, 0.0)
		right_arr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right_arr.add_theme_font_size_override("font_size", 22)
		scroll_row.add_child(right_arr)

		left_arr.pressed.connect(func() -> void:
			scroll_c.scroll_horizontal = maxi(scroll_c.scroll_horizontal - 220, 0))
		right_arr.pressed.connect(func() -> void:
			scroll_c.scroll_horizontal += 220)

	var card_hbox := HBoxContainer.new()
	card_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_hbox.add_theme_constant_override("separation", GAP)
	if show_scroll and scroll_c != null:
		scroll_c.add_child(card_hbox)
	else:
		vbox.add_child(card_hbox)

	# ── One column per union ──────────────────────────────
	for i: int in range(n):
		var entry: Dictionary = _available[i]
		var u: UnionData      = entry["union"]
		var zone_cells: Array = entry["zone_cells"]
		var can_afford: bool  = GameState.crystals[_player] >= u.summon_cost

		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		col.custom_minimum_size   = Vector2(200.0, 0.0)
		col.add_theme_constant_override("separation", 8)
		card_hbox.add_child(col)

		# Full card image — expands to fill available height
		var img := TextureRect.new()
		img.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		img.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not can_afford:
			img.modulate = Color(0.5, 0.5, 0.5, 0.8)
		var snake: String = u.card_name.to_lower() \
			.replace(" ", "_").replace("'", "").replace("-", "_")
		var path: String = "res://assets/textures/cards/full_cards/union_" + snake + ".png"
		if not ResourceLoader.exists(path):
			path = "res://assets/textures/cards/full_cards/" + snake + ".png"
		if ResourceLoader.exists(path):
			img.texture = load(path)
		col.add_child(img)

		# UNION button with cost
		var captured_name: String = u.card_name
		var captured_zone: Array  = zone_cells
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 52.0)
		btn.text = "UNION  (%d◆)" % u.summon_cost
		btn.disabled = not can_afford
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(func() -> void:
			union_selected.emit(_player, captured_name, captured_zone)
			queue_free())
		col.add_child(btn)

# ─────────────────────────────────────────────────────────────
# Interaction
# ─────────────────────────────────────────────────────────────
func _on_cancel() -> void:
	union_cancelled.emit()
	queue_free()
