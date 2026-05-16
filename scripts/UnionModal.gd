class_name UnionModal
extends Control
## UnionModal — overlay for selecting a Union summon.
## Open via:   UnionModal.open(parent, player, available_unions)
##   available_unions = Array of { union: UnionData, zone_cells: Array[Vector2i] }
##
## Tapping a union card image emits union_selected(player, union_name, zone_cells)
## and immediately closes the modal. GameBoard then handles material selection.
##
## Emits union_cancelled when dismissed without a selection.

signal union_selected(player: int, union_name: String, zone_cells: Array)
signal union_cancelled

# ─────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────
const AFFINITY_COLORS: Dictionary = {
	0: Color(1.00, 0.92, 0.40),  # DIVINE    — gold
	1: Color(0.65, 0.20, 1.00),  # CHAOS     — purple
	2: Color(0.30, 0.90, 0.40),  # NATURE    — green
	3: Color(0.55, 0.30, 1.00),  # ARCANE    — violet
	4: Color(0.30, 0.85, 1.00),  # COSMIC    — sky blue
	5: Color(0.00, 1.00, 0.60),  # BIO       — teal
	6: Color(1.00, 0.55, 0.20),  # ANIMA     — orange
}
const AFFINITY_NAMES: Array = ["Divine", "Chaos", "Nature", "Arcane", "Cosmic", "Bio", "Anima"]
const UNION_CYAN: Color = Color(0.25, 0.90, 1.00)
const BG_DARK:   Color = Color(0.03, 0.06, 0.14, 0.97)
const BORDER:    Color = Color(0.25, 0.90, 1.00, 0.80)

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var _player: int = 0
var _available: Array = []   # [{union: UnionData, zone_cells: Array}]
var _scroll_c: ScrollContainer = null

# ─────────────────────────────────────────────────────────────
# Factory
# ─────────────────────────────────────────────────────────────
static func open(parent: Node, player: int, available_unions: Array) -> UnionModal:
	var modal := UnionModal.new()
	modal._player = player
	modal._available = available_unions
	modal.z_index = 50
	parent.add_child(modal)
	modal._build_ui()
	return modal

# ─────────────────────────────────────────────────────────────
# UI construction
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Dim backdrop — clicking it cancels
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.72)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_on_cancel())
	add_child(bg)

	const PAD: int = 20
	const GAP: int = 12

	var panel_c := PanelContainer.new()
	panel_c.layout_mode = 1
	panel_c.anchor_left   = 0.0; panel_c.anchor_top    = 0.0
	panel_c.anchor_right  = 1.0; panel_c.anchor_bottom = 1.0
	panel_c.offset_left   = PAD; panel_c.offset_top    = PAD
	panel_c.offset_right  = -PAD; panel_c.offset_bottom = -PAD
	var psb := StyleBoxFlat.new()
	psb.bg_color = BG_DARK
	psb.border_width_left   = 2; psb.border_width_top    = 2
	psb.border_width_right  = 2; psb.border_width_bottom = 2
	psb.border_color = BORDER
	psb.corner_radius_top_left     = 8; psb.corner_radius_top_right    = 8
	psb.corner_radius_bottom_left  = 8; psb.corner_radius_bottom_right = 8
	psb.content_margin_left   = PAD; psb.content_margin_right  = PAD
	psb.content_margin_top    = 12;  psb.content_margin_bottom = PAD
	panel_c.add_theme_stylebox_override("panel", psb)
	add_child(panel_c)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", GAP)
	panel_c.add_child(vbox)

	# ── Title row ────────────────────────────────────────────
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "UNION SUMMON  —  Tap a card to select materials"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", UNION_CYAN)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(100.0, 36.0)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.pressed.connect(_on_cancel)
	title_row.add_child(close_btn)

	# ── Card scroll area ──────────────────────────────────────
	var n: int = _available.size()
	var show_arrows: bool = n > 3

	var scroll_row := HBoxContainer.new()
	scroll_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_row.add_theme_constant_override("separation", 4)
	vbox.add_child(scroll_row)

	if show_arrows:
		var left_btn := _make_arrow_btn("<")
		left_btn.pressed.connect(func() -> void:
			if _scroll_c:
				_scroll_c.scroll_horizontal = maxi(_scroll_c.scroll_horizontal - 220, 0))
		scroll_row.add_child(left_btn)

	_scroll_c = ScrollContainer.new()
	_scroll_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_c.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_scroll_c.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll_c.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_row.add_child(_scroll_c)

	if show_arrows:
		var right_btn := _make_arrow_btn(">")
		right_btn.pressed.connect(func() -> void:
			if _scroll_c:
				_scroll_c.scroll_horizontal += 220)
		scroll_row.add_child(right_btn)

	var card_hbox := HBoxContainer.new()
	card_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_hbox.add_theme_constant_override("separation", GAP)
	_scroll_c.add_child(card_hbox)

	# ── One column per union ──────────────────────────────────
	for i: int in range(n):
		var entry: Dictionary = _available[i]
		var u: UnionData = entry["union"]
		var zone_cells: Array = entry["zone_cells"]
		var can_afford: bool = GameState.crystals[_player] >= u.summon_cost

		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		card_hbox.add_child(col)

		# Card image button (full-height, tappable)
		var img_btn := Button.new()
		img_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		img_btn.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		img_btn.flat = true
		var empty_sb := StyleBoxEmpty.new()
		img_btn.add_theme_stylebox_override("normal",   empty_sb)
		img_btn.add_theme_stylebox_override("hover",    empty_sb)
		img_btn.add_theme_stylebox_override("pressed",  empty_sb)
		img_btn.add_theme_stylebox_override("disabled", empty_sb)
		img_btn.disabled = not can_afford

		var img := TextureRect.new()
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
		img_btn.add_child(img)

		var captured_name: String = u.card_name
		var captured_zone: Array  = zone_cells
		img_btn.pressed.connect(func() -> void:
			union_selected.emit(_player, captured_name, captured_zone)
			queue_free())
		col.add_child(img_btn)

		# ── Info labels ──────────────────────────────────────
		var name_lbl := Label.new()
		name_lbl.text = u.card_name
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", UNION_CYAN)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(name_lbl)

		var aff_idx: int = int(u.affinity)
		var aff_lbl := Label.new()
		aff_lbl.text = AFFINITY_NAMES[aff_idx] if aff_idx < AFFINITY_NAMES.size() else "?"
		aff_lbl.add_theme_font_size_override("font_size", 11)
		aff_lbl.add_theme_color_override("font_color",
			AFFINITY_COLORS.get(aff_idx, Color.WHITE) as Color)
		aff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		aff_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(aff_lbl)

		var stats_lbl := Label.new()
		stats_lbl.text = "ATK %d  DEF %d" % [u.base_atk, u.base_def]
		stats_lbl.add_theme_font_size_override("font_size", 11)
		stats_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(stats_lbl)

		var cost_lbl := Label.new()
		cost_lbl.text = "%d ◆" % u.summon_cost
		cost_lbl.add_theme_font_size_override("font_size", 11)
		cost_lbl.add_theme_color_override("font_color",
			Color(1.0, 0.38, 0.38) if not can_afford else Color(1.0, 0.88, 0.35))
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(cost_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = u.ability_description
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(desc_lbl)

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _make_arrow_btn(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(40.0, 0.0)
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 22)
	return btn

# ─────────────────────────────────────────────────────────────
# Interaction
# ─────────────────────────────────────────────────────────────
func _on_cancel() -> void:
	union_cancelled.emit()
	queue_free()
