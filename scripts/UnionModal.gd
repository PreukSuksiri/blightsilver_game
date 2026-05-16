class_name UnionModal
extends Control
## UnionModal — overlay for selecting and confirming a Union summon.
## Open via:   UnionModal.open(parent, player, available_unions, highlight_fn, clear_fn)
##   available_unions = Array of { union: UnionData, zone_cells: Array[Vector2i], tapped_pos: Vector2i }
##   highlight_fn = func(zone_cells: Array) — highlights those cells on the game grid
##   clear_fn     = func()                  — clears all grid highlights
##
## Emits union_confirmed(player, union_name, tapped_pos, zone_cells) or
##       union_cancelled when dismissed.

signal union_confirmed(player: int, union_name: String, tapped_pos: Vector2i, zone_cells: Array)
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
const CELL_ZONE: Color = Color(0.25, 0.90, 1.00, 0.55)
const CELL_EMPTY: Color = Color(0.12, 0.18, 0.28, 0.80)

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────="────────────────────────────────────
var _player: int = 0
var _available: Array = []          # [{union, zone_cells, tapped_pos}]
var _highlight_fn: Callable
var _clear_fn: Callable
var _selected_idx: int = -1

# UI references
var _list_btns: Array = []          # Array[Button]
var _lbl_name: Label
var _lbl_affinity: Label
var _lbl_atk: Label
var _lbl_def: Label
var _lbl_cost: Label
var _lbl_ability: Label
var _zone_cells: Array              # 5x5 grid of ColorRect
var _summon_btn: Button
var _cost_warning: Label

# ─────────────────────────────────────────────────────────────
# Factory
# ─────────────────────────────────────────────────────────────
static func open(
		parent: Node,
		player: int,
		available_unions: Array,
		highlight_fn: Callable,
		clear_fn: Callable
) -> UnionModal:
	var modal := UnionModal.new()
	modal._player = player
	modal._available = available_unions
	modal._highlight_fn = highlight_fn
	modal._clear_fn = clear_fn
	modal.z_index = 50
	parent.add_child(modal)
	modal._build_ui()
	if available_unions.size() > 0:
		modal._select(0)
	return modal

# ─────────────────────────────────────────────────────────────
# UI construction
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Full-screen layout
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Dim backdrop
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.72)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var vp: Vector2 = get_viewport().get_visible_rect().size

	# Outer panel — centered, 860 × 540
	var pw: float = minf(vp.x * 0.88, 860.0)
	var ph: float = minf(vp.y * 0.84, 540.0)
	var px: float = (vp.x - pw) * 0.5
	var py: float = (vp.y - ph) * 0.5

	var panel := Panel.new()
	panel.position = Vector2(px, py)
	panel.size     = Vector2(pw, ph)
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_DARK
	sb.border_width_left   = 2; sb.border_width_top    = 2
	sb.border_width_right  = 2; sb.border_width_bottom = 2
	sb.border_color = BORDER
	sb.corner_radius_top_left     = 10; sb.corner_radius_top_right    = 10
	sb.corner_radius_bottom_right = 10; sb.corner_radius_bottom_left  = 10
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	# Title
	var title := Label.new()
	title.text = "UNION SUMMON"
	title.add_theme_color_override("font_color", UNION_CYAN)
	title.add_theme_font_size_override("font_size", 18)
	title.position = Vector2(18.0, 10.0)
	title.size     = Vector2(pw - 36.0, 28.0)
	panel.add_child(title)

	# Separator
	var sep := ColorRect.new()
	sep.position = Vector2(18.0, 40.0)
	sep.size     = Vector2(pw - 36.0, 1.0)
	sep.color    = BORDER
	panel.add_child(sep)

	# ── Left column: union list ──────────────────────────────
	var list_w: float = pw * 0.36
	var list_h: float = ph - 56.0
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(18.0, 48.0)
	scroll.size     = Vector2(list_w, list_h - 8.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	_list_btns.clear()
	for i: int in range(_available.size()):
		var entry: Dictionary = _available[i]
		var u: UnionData = entry["union"]
		var btn := Button.new()
		btn.text = u.card_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(list_w - 16.0, 36.0)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_list_btn(btn, false)
		var idx: int = i
		btn.pressed.connect(func() -> void: _select(idx))
		vbox.add_child(btn)
		_list_btns.append(btn)

	# ── Right column: details + zone ────────────────────────
	var right_x: float = 18.0 + list_w + 16.0
	var right_w: float = pw - right_x - 18.0

	# Card name
	_lbl_name = _make_label("", right_x, 48.0, right_w, 28.0, 17, UNION_CYAN)
	panel.add_child(_lbl_name)

	# Affinity
	_lbl_affinity = _make_label("", right_x, 78.0, right_w * 0.5, 22.0, 13, Color.WHITE)
	panel.add_child(_lbl_affinity)

	# ATK / DEF row
	_lbl_atk = _make_label("", right_x, 102.0, 110.0, 22.0, 13, Color(1.0, 0.40, 0.30))
	panel.add_child(_lbl_atk)
	_lbl_def = _make_label("", right_x + 120.0, 102.0, 110.0, 22.0, 13, Color(0.30, 0.70, 1.0))
	panel.add_child(_lbl_def)

	# Cost
	_lbl_cost = _make_label("", right_x, 126.0, right_w, 22.0, 13, Color(1.0, 0.88, 0.35))
	panel.add_child(_lbl_cost)

	# Ability
	_lbl_ability = _make_label("", right_x, 150.0, right_w, 52.0, 12, Color(0.85, 0.85, 0.85))
	_lbl_ability.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_lbl_ability)

	# Zone preview header
	var zone_hdr := _make_label("Zone Shape:", right_x, 208.0, right_w, 18.0, 12, Color(0.60, 0.80, 1.0))
	panel.add_child(zone_hdr)

	# Zone preview mini-grid (5×5 cells of 22px each)
	const CELL_SZ: float = 22.0
	const CELL_GAP: float = 2.0
	_zone_cells = []
	for r: int in range(5):
		for c: int in range(5):
			var cr := ColorRect.new()
			cr.position = Vector2(right_x + c * (CELL_SZ + CELL_GAP), 228.0 + r * (CELL_SZ + CELL_GAP))
			cr.size     = Vector2(CELL_SZ, CELL_SZ)
			cr.color    = CELL_EMPTY
			panel.add_child(cr)
			_zone_cells.append(cr)

	# Cost warning (shows when player can't afford)
	_cost_warning = _make_label("", right_x, 364.0, right_w, 22.0, 12, Color(1.0, 0.38, 0.38))
	panel.add_child(_cost_warning)

	# ── Bottom buttons ───────────────────────────────────────
	var btn_y: float = ph - 52.0

	var cancel_btn := Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.position = Vector2(18.0, btn_y)
	cancel_btn.size     = Vector2(100.0, 38.0)
	cancel_btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	cancel_btn.pressed.connect(_on_cancel)
	panel.add_child(cancel_btn)

	_summon_btn = Button.new()
	_summon_btn.text = "SUMMON"
	_summon_btn.position = Vector2(pw - 148.0, btn_y)
	_summon_btn.size     = Vector2(130.0, 38.0)
	_summon_btn.add_theme_color_override("font_color", UNION_CYAN)
	_summon_btn.pressed.connect(_on_summon)
	panel.add_child(_summon_btn)

func _make_label(
		text: String,
		x: float, y: float,
		w: float, h: float,
		fsz: int,
		col: Color
) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(x, y)
	lbl.size     = Vector2(w, h)
	lbl.add_theme_font_size_override("font_size", fsz)
	lbl.add_theme_color_override("font_color", col)
	return lbl

func _style_list_btn(btn: Button, selected: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.12, 0.22, 0.38, 0.90) if selected else Color(0.06, 0.10, 0.20, 0.80)
	sb.border_width_left   = 2 if selected else 0
	sb.border_width_top    = 0
	sb.border_width_right  = 0
	sb.border_width_bottom = 0
	sb.border_color = UNION_CYAN
	sb.corner_radius_top_left     = 4; sb.corner_radius_top_right    = 4
	sb.corner_radius_bottom_right = 4; sb.corner_radius_bottom_left  = 4
	btn.add_theme_stylebox_override("normal",   sb)
	btn.add_theme_stylebox_override("hover",    sb)
	btn.add_theme_stylebox_override("pressed",  sb)
	btn.add_theme_color_override("font_color", UNION_CYAN if selected else Color(0.80, 0.85, 0.90))

# ─────────────────────────────────────────────────────────────
# Interaction
# ─────────────────────────────────────────────────────────────
func _select(idx: int) -> void:
	if idx < 0 or idx >= _available.size():
		return
	_selected_idx = idx

	# Restyle list buttons
	for i: int in range(_list_btns.size()):
		_style_list_btn(_list_btns[i], i == idx)

	var entry: Dictionary = _available[idx]
	var u: UnionData = entry["union"]
	var zone_cells: Array = entry["zone_cells"]

	# Update detail labels
	_lbl_name.text = u.card_name
	var aff_idx: int = int(u.affinity)
	_lbl_affinity.text = "Affinity: %s" % (AFFINITY_NAMES[aff_idx] if aff_idx < AFFINITY_NAMES.size() else "?")
	_lbl_affinity.add_theme_color_override("font_color", AFFINITY_COLORS.get(aff_idx, Color.WHITE))
	_lbl_atk.text = "ATK  %d" % u.base_atk
	_lbl_def.text = "DEF  %d" % u.base_def
	_lbl_cost.text = "Summon cost: %d ◆" % u.summon_cost
	_lbl_ability.text = u.ability_description

	# Zone preview mini-grid
	var zone_set: Dictionary = {}
	for cell: Vector2i in zone_cells:
		zone_set[cell] = true
	# Find the bounding box of zone_cells to center the preview
	var min_r: int = 99; var max_r: int = -1
	var min_c: int = 99; var max_c: int = -1
	for cell: Vector2i in zone_cells:
		if cell.x < min_r: min_r = cell.x
		if cell.x > max_r: max_r = cell.x
		if cell.y < min_c: min_c = cell.y
		if cell.y > max_c: max_c = cell.y
	# Draw relative zone on 5×5 preview
	for r: int in range(5):
		for c: int in range(5):
			var cr: ColorRect = _zone_cells[r * 5 + c]
			# Convert absolute zone to relative for preview (anchor at top-left)
			var abs_r: int = r + min_r
			var abs_c: int = c + min_c
			var in_zone: bool = zone_set.has(Vector2i(abs_r, abs_c))
			cr.color = CELL_ZONE if in_zone else CELL_EMPTY

	# Crystal affordability check
	var can_afford: bool = GameState.crystals[_player] >= u.summon_cost
	_summon_btn.disabled = not can_afford
	_cost_warning.text = "" if can_afford else "Not enough crystals (need %d, have %d)" % [u.summon_cost, GameState.crystals[_player]]

	# Highlight zone on actual game grid
	_highlight_fn.call(zone_cells)

func _on_summon() -> void:
	if _selected_idx < 0:
		return
	var entry: Dictionary = _available[_selected_idx]
	var u: UnionData = entry["union"]
	if GameState.crystals[_player] < u.summon_cost:
		return
	var zone_cells: Array = entry["zone_cells"]
	var tapped: Vector2i = entry["tapped_pos"]
	_clear_fn.call()
	union_confirmed.emit(_player, u.card_name, tapped, zone_cells)
	queue_free()

func _on_cancel() -> void:
	_clear_fn.call()
	union_cancelled.emit()
	queue_free()

func _exit_tree() -> void:
	if _clear_fn.is_valid():
		_clear_fn.call()
