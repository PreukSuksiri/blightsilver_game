class_name CardExporter
extends Node
## Dev tool — renders each card using the CardDetailOverlay visual layout
## and saves PNG files to res://assets/textures/cards/full_cards/.
## Usage: instantiate, add_child to any persistent node, then call:
##   export_one_card(card_name, card_type)   — single card
##   export_all_cards()                       — all cards (fire-and-forget coroutine)

# ── Preloads & constants (mirrored exactly from CardDetailOverlay) ─────────────
const VELLUM_FRAME    := preload("res://assets/textures/cards/frames/vellum_card_frame_transparent.png")
const ART_PLACEHOLDER := preload("res://assets/textures/cards/placeholder.png")
const CHIVO_FONT      := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")
const CRYSTAL_ICON    := preload("res://assets/textures/ui/decorations/ui_crystal_indicator.png")

const EXPORT_W     := 819.0
const EXPORT_H     := 1126.0
const FRAME_ASPECT := 819.0 / 1126.0

const ART_L_PCT    := 0.051
const ART_R_PCT    := 0.949
const ART_T_PCT    := 0.096
const ART_B_PCT    := 1.000
const INFO_TOP_PCT := 0.520

const TYPE_COLOR_CHARACTER := Color(1.0,   0.71,  0.2,   1.0)
const TYPE_COLOR_TRAP      := Color(1.0, 0.263, 0.345, 1.0)
const TYPE_COLOR_TECH      := Color(0.18,  0.764, 0.341, 1.0)

const AFFINITY_COLORS: Dictionary = {
	CharacterData.Affinity.DIVINE: Color(1.00, 0.90, 0.30),
	CharacterData.Affinity.CHAOS:  Color(0.55, 0.05, 0.75),
	CharacterData.Affinity.NATURE: Color(0.20, 0.80, 0.20),
	CharacterData.Affinity.ARCANE: Color(0.15, 0.50, 1.00),
	CharacterData.Affinity.COSMIC: Color(0.00, 0.90, 0.90),
	CharacterData.Affinity.BIO:    Color(0.55, 0.95, 0.10),
	CharacterData.Affinity.ANIMA:  Color(0.95, 0.40, 0.10),
}

const OUTPUT_DIR := "res://assets/textures/cards/full_cards/"

# ── Per-card label refs (reassigned each render) ──────────────────────────────
var _art:          TextureRect
var _art_base_pos: Vector2
var _frame:        TextureRect
var _type:         Label
var _cost:         Control
var _cost_num:     Label
var _name:         Label
var _atk:          Label
var _def:          Label
var _aff:          Label
var _desc:         Label
var _rarity:       Label

var _union_info_panel: ColorRect    # single combined panel (zone + formula)
var _zone_cells:       Array        # Array[ColorRect], row-major (row*5+col)
var _mat_formula_lbl:  Label

var _info_y: float
var _info_h: float
var _pad_x:  float

# ─────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────

func export_one_card(card_name: String, card_type: String) -> void:
	await _render_and_save(card_name, card_type)
	if card_type == "union":
		await _render_and_save_union_locked(card_name)
	MailboxManager._exporter_active = false
	queue_free()

func export_dead_end_card() -> void:
	await _render_and_save("dead_end", "dead_end")
	MailboxManager._exporter_active = false
	queue_free()

func export_all_cards() -> void:
	var pairs := _collect_all_pairs()
	var done  := 0
	for pair: Array in pairs:
		await _render_and_save(pair[0], pair[1])
		done += 1
		print("[CardExporter] %d/%d — %s (%s)" % [done, pairs.size(), pair[0], pair[1]])
		if pair[1] == "union":
			await _render_and_save_union_locked(pair[0])
			print("[CardExporter] %d/%d — %s (union locked)" % [done, pairs.size(), pair[0]])
		await get_tree().process_frame
	print("[CardExporter] Complete. Exported %d cards (+locked union variants) to %s" % [done, OUTPUT_DIR])
	MailboxManager._exporter_active = false
	queue_free()

func export_one_nsfw_card(card_name: String, card_type: String) -> void:
	await _render_and_save_nsfw(card_name, card_type)
	MailboxManager._exporter_active = false
	queue_free()

func export_all_nsfw_cards() -> void:
	var pairs := _collect_all_pairs()
	var done  := 0
	var skipped := 0
	for pair: Array in pairs:
		var subfolder: String = _type_to_subfolder(pair[1])
		var nsfw_path: String = CardDatabase.find_artwork(pair[0], subfolder, true)
		# Only export if an actual _nsfw variant exists
		if nsfw_path == "" or not ("_nsfw" in nsfw_path.get_basename()):
			skipped += 1
			continue
		await _render_and_save_nsfw(pair[0], pair[1])
		done += 1
		print("[CardExporter] NSFW %d — %s (%s)" % [done, pair[0], pair[1]])
		await get_tree().process_frame
	print("[CardExporter] NSFW export complete. Exported %d, skipped %d (no _nsfw art)." % [done, skipped])
	MailboxManager._exporter_active = false
	queue_free()

# ─────────────────────────────────────────────────────────────
# Core render-and-save coroutine
# ─────────────────────────────────────────────────────────────

func _render_and_save(card_name: String, card_type: String) -> void:
	# 1. Create off-screen SubViewport
	var svp := SubViewport.new()
	svp.size = Vector2i(int(EXPORT_W), int(EXPORT_H))
	svp.transparent_bg = true
	svp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(svp)

	# 2. Build and populate the card visual tree
	var card := _build_card_node()
	svp.add_child(card)
	_populate_card_node(card_name, card_type)

	# 3. Two-frame wait: first settles layout, second completes GPU render
	await get_tree().process_frame
	svp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame

	# 4. Capture and save
	var img: Image = svp.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("[CardExporter] Failed to capture image for: " + card_name)
		svp.queue_free()
		return

	var fs_path := _output_path(card_name, card_type)
	var err := img.save_png(fs_path)
	if err != OK:
		push_error("[CardExporter] save_png failed for '%s': error %d" % [card_name, err])

	svp.queue_free()

# ─────────────────────────────────────────────────────────────
# Card UI builder — mirrors CardDetailOverlay._build_ui
# (no dimmer, no close button, no interactive elements)
# ─────────────────────────────────────────────────────────────

func _build_card_node() -> Control:
	var card_w := EXPORT_W
	var card_h := EXPORT_H

	var al      := ART_L_PCT   * card_w
	var ar      := ART_R_PCT   * card_w
	var at      := ART_T_PCT   * card_h
	var ab      := ART_B_PCT   * card_h
	var aw      := ar - al
	var ah      := ab - at
	var info_y  := INFO_TOP_PCT * card_h
	var info_h  := card_h - info_y
	var pad_x   := al + 15.0
	_info_y = info_y
	_info_h = info_h
	_pad_x  = pad_x

	var card := Control.new()
	card.position     = Vector2.ZERO
	card.size         = Vector2(card_w, card_h)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Art background
	var art_bg := ColorRect.new()
	art_bg.position     = Vector2(al, at)
	art_bg.size         = Vector2(aw, ah)
	art_bg.color        = Color(0.04, 0.04, 0.06)
	art_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(art_bg)

	# Art texture
	_art = TextureRect.new()
	_art_base_pos     = Vector2(al, at)
	_art.position     = _art_base_pos
	_art.size         = Vector2(aw, ah)
	_art.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(_art)

	# Gradient fade at bottom of art into info section
	var fade := ColorRect.new()
	fade.position     = Vector2(al, ab - ah * 0.20)
	fade.size         = Vector2(aw, ah * 0.20)
	fade.color        = Color(0.04, 0.04, 0.06, 0.68)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(fade)

	# Vellum frame — drawn above art
	_frame = TextureRect.new()
	var frame := _frame
	frame.position     = Vector2.ZERO
	frame.size         = Vector2(card_w, card_h)
	frame.texture      = VELLUM_FRAME
	frame.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(frame)

	# Header
	var hdr_h   := at
	var fsz_hdr := maxi(int(card_w * 0.044), 10)

	_type = Label.new()
	_type.position           = Vector2(pad_x, hdr_h * 0.25)
	_type.size               = Vector2(card_w * 0.55, hdr_h * 0.64)
	_type.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_type.add_theme_font_size_override("font_size", fsz_hdr)
	_type.add_theme_font_override("font", CHIVO_FONT)
	card.add_child(_type)

	# Cost badge – crystal icon + number in rounded pill
	var cost_sb := StyleBoxFlat.new()
	cost_sb.bg_color                   = Color(0.04, 0.04, 0.04, 0.88)
	cost_sb.border_color               = Color(0.85, 0.68, 0.18)
	cost_sb.border_width_left          = 2
	cost_sb.border_width_right         = 2
	cost_sb.border_width_top           = 2
	cost_sb.border_width_bottom        = 2
	cost_sb.corner_radius_top_left     = 7
	cost_sb.corner_radius_top_right    = 7
	cost_sb.corner_radius_bottom_left  = 7
	cost_sb.corner_radius_bottom_right = 7
	cost_sb.content_margin_left        = 6
	cost_sb.content_margin_right       = 6
	cost_sb.content_margin_top         = 4
	cost_sb.content_margin_bottom      = 4
	var cost_pc := PanelContainer.new()
	cost_pc.position     = Vector2(card_w * 0.68, hdr_h * 0.22)
	cost_pc.size         = Vector2(card_w * 0.27, hdr_h * 0.66)
	cost_pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_pc.add_theme_stylebox_override("panel", cost_sb)
	var cost_hbox := HBoxContainer.new()
	cost_hbox.alignment    = BoxContainer.ALIGNMENT_CENTER
	cost_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cost_pc.add_child(cost_hbox)
	var cost_icon := TextureRect.new()
	cost_icon.texture              = CRYSTAL_ICON
	cost_icon.expand_mode          = TextureRect.EXPAND_IGNORE_SIZE
	cost_icon.stretch_mode         = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cost_icon.custom_minimum_size  = Vector2(fsz_hdr, fsz_hdr)
	cost_icon.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	cost_hbox.add_child(cost_icon)
	_cost_num = Label.new()
	_cost_num.add_theme_font_size_override("font_size", fsz_hdr)
	_cost_num.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	_cost_num.add_theme_font_override("font", CHIVO_FONT)
	_cost_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_num.mouse_filter       = Control.MOUSE_FILTER_IGNORE
	cost_hbox.add_child(_cost_num)
	_cost = cost_pc
	card.add_child(_cost)

	# Info section
	var fsz_name := maxi(int(card_w * 0.04),  5)
	var fsz_stat := maxi(int(card_w * 0.035), 3)
	var fsz_desc := maxi(int(card_w * 0.035), 3)

	_name = Label.new()
	_name.position           = Vector2(pad_x, info_y + info_h * 0.45)
	_name.size               = Vector2(card_w - pad_x * 2.0, info_h * 0.34)
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name.add_theme_font_size_override("font_size", fsz_name)
	_name.add_theme_font_override("font", CHIVO_FONT)
	_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82))
	card.add_child(_name)

	var stats_y  := info_y + info_h * 0.67
	var stats_h  := info_h * 0.07
	var pill_w   := card_w * 0.16
	var pill_gap := card_w * 0.01

	_atk = Label.new()
	_atk.position             = Vector2(pad_x, stats_y)
	_atk.size                 = Vector2(pill_w, stats_h)
	_atk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_atk.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_atk.add_theme_font_size_override("font_size", fsz_stat)
	_atk.add_theme_color_override("font_color", Color(1.0, 0.62, 0.30))
	_atk.add_theme_font_override("font", CHIVO_FONT)
	card.add_child(_atk)

	_def = Label.new()
	_def.position             = Vector2(pad_x + pill_w + pill_gap + 4.0, stats_y)
	_def.size                 = Vector2(pill_w, stats_h)
	_def.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_def.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_def.add_theme_font_size_override("font_size", fsz_stat)
	_def.add_theme_color_override("font_color", Color(0.38, 0.68, 1.0))
	_def.add_theme_font_override("font", CHIVO_FONT)
	card.add_child(_def)

	_aff = Label.new()
	_aff.position             = Vector2(pad_x, stats_y - 40.0)
	_aff.size                 = Vector2(card_w - pad_x * 2.0, stats_h)
	_aff.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_aff.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_aff.add_theme_font_size_override("font_size", fsz_stat + 10)
	_aff.add_theme_font_override("font", CHIVO_FONT)
	card.add_child(_aff)

	_desc = Label.new()
	_desc.position              = Vector2(pad_x, info_y + info_h * 0.76)
	_desc.size                  = Vector2(card_w - pad_x * 2.0, info_h * 0.23)
	_desc.add_theme_font_size_override("font_size", fsz_desc)
	_desc.add_theme_color_override("font_color", Color(0.82, 0.88, 0.98))
	_desc.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	_desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_desc.add_theme_font_override("font", CHIVO_FONT)
	card.add_child(_desc)

	# Rarity stars – lower-right corner
	var fsz_rarity := maxi(int(card_w * 0.04), 10)
	_rarity = Label.new()
	_rarity.position             = Vector2(pad_x, card_h - float(fsz_rarity) - 14.0)
	_rarity.size                 = Vector2(card_w - pad_x * 2.0, float(fsz_rarity) + 8.0)
	_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rarity.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_rarity.add_theme_font_size_override("font_size", fsz_rarity)
	_rarity.add_theme_font_override("font", CHIVO_FONT)
	_rarity.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	card.add_child(_rarity)

	# Union info — single wide panel at the bottom of the art area.
	# Left side: material formula text.  Right side: 5×5 zone grid.
	const ZONE_C: int = 20   # cell size px
	const ZONE_G: int = 2    # gap between cells px
	const ZONE_P: int = 5    # padding inside panel px
	const ZONE_S: int = 5 * ZONE_C + 4 * ZONE_G + ZONE_P * 2  # 118px (grid block)
	# 0.76 = vellum frame art-area bottom (artwork area 8-76%)
	var zone_bot: float = 0.76 * card_h - 10.0
	var pan_left: float = ART_L_PCT * card_w + 12.0
	var pan_right: float = ART_R_PCT * card_w - 12.0
	var pan_w: float = pan_right - pan_left

	_union_info_panel = ColorRect.new()
	_union_info_panel.position     = Vector2(pan_left, zone_bot - ZONE_S)
	_union_info_panel.size         = Vector2(pan_w, ZONE_S)
	_union_info_panel.color        = Color(0.0, 0.0, 0.0, 0.72)
	_union_info_panel.visible      = false
	_union_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(_union_info_panel)

	# Zone grid — right side of the panel
	var grid_x_off: float = pan_w - float(ZONE_S)
	_zone_cells = []
	for _zr: int in range(5):
		for _zc: int in range(5):
			var _zcr := ColorRect.new()
			_zcr.size         = Vector2(ZONE_C, ZONE_C)
			_zcr.position     = Vector2(grid_x_off + ZONE_P + _zc * (ZONE_C + ZONE_G),
									   ZONE_P + _zr * (ZONE_C + ZONE_G))
			_zcr.color        = Color(0.12, 0.12, 0.22, 0.75)
			_zcr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_union_info_panel.add_child(_zcr)
			_zone_cells.append(_zcr)

	# Material formula label — left side of the panel
	_mat_formula_lbl = Label.new()
	_mat_formula_lbl.position              = Vector2(8.0, 6.0)
	_mat_formula_lbl.size                  = Vector2(grid_x_off - 16.0, float(ZONE_S) - 12.0)
	_mat_formula_lbl.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	_mat_formula_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_mat_formula_lbl.add_theme_font_size_override("font_size", 24)
	_mat_formula_lbl.add_theme_color_override("font_color", Color.WHITE)
	_mat_formula_lbl.add_theme_font_override("font", CHIVO_FONT)
	_mat_formula_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_union_info_panel.add_child(_mat_formula_lbl)

	return card

# ─────────────────────────────────────────────────────────────
# Data population — mirrors CardDetailOverlay._populate
# (no AudioManager.speak calls)
# ─────────────────────────────────────────────────────────────

func _populate_card_node(card_name: String, card_type: String) -> void:
	match card_type:
		"character":
			var data: CharacterData = CardDatabase.get_character(card_name)
			if not data:
				push_warning("[CardExporter] Unknown character: " + card_name)
				return
			var aff_name : String = CharacterData.Affinity.keys()[data.affinity].capitalize()
			_type.text = "CHARACTER"
			_type.add_theme_color_override("font_color", TYPE_COLOR_CHARACTER)
			_frame.modulate = Color(1.0, 1.0, 1.0)
			_cost_num.text = str(data.crystal_cost)
			_name.text = card_name
			_atk.text  = "ATK %d" % data.base_atk
			_def.text  = "DEF %d" % data.base_def
			_aff.text  = aff_name
			_aff.add_theme_color_override("font_color", TYPE_COLOR_CHARACTER)
			_desc.text = data.get_ability_description()
			_style_pill(_atk, Color(0.75, 0.28, 0.05), Color(1.0, 0.55, 0.28))
			_style_pill(_def, Color(0.08, 0.28, 0.70), Color(0.35, 0.62, 1.0))
			_art.position = _art_base_pos + data.artwork_offset
			_load_art(CardDatabase.find_artwork(card_name, "characters"))
			_set_rarity(data.rarity)
		"trap":
			var data: TrapData = CardDatabase.get_trap(card_name)
			if not data:
				push_warning("[CardExporter] Unknown trap: " + card_name)
				return
			_type.text = "TRAP"
			_type.add_theme_color_override("font_color", TYPE_COLOR_TRAP)
			_frame.modulate = Color(1.0, 0.65, 0.65)
			_cost_num.text = str(data.crystal_cost)
			_name.text = card_name
			_atk.text  = ""
			_def.text  = ""
			#_aff.text  = "Trap"
			_aff.add_theme_color_override("font_color", TYPE_COLOR_TRAP)
			_desc.text     = data.get_effect_description()
			_desc.position = Vector2(_pad_x, _info_y + _info_h * 0.67)
			_desc.size     = Vector2(EXPORT_W - _pad_x * 2.0, _info_h * 0.32)
			_art.position = _art_base_pos + data.artwork_offset
			_load_art(CardDatabase.find_artwork(card_name, "traps"))
			_set_rarity(data.rarity)
		"tech":
			var data: TechCardData = CardDatabase.get_tech(card_name)
			if not data:
				push_warning("[CardExporter] Unknown tech: " + card_name)
				return
			_type.text = "TECH"
			_type.add_theme_color_override("font_color", TYPE_COLOR_TECH)
			_frame.modulate = Color(0.65, 1.0, 0.65)
			_cost_num.text = str(data.crystal_cost)
			_name.text = card_name
			_atk.text  = ""
			_def.text  = ""
			#_aff.text  = "Tech"
			_aff.add_theme_color_override("font_color", TYPE_COLOR_TECH)
			_desc.text     = data.get_effect_description()
			_desc.position = Vector2(_pad_x, _info_y + _info_h * 0.67)
			_desc.size     = Vector2(EXPORT_W - _pad_x * 2.0, _info_h * 0.32)
			_art.position = _art_base_pos + data.artwork_offset
			_load_art(CardDatabase.find_artwork(card_name, "tech"))
			_set_rarity(data.rarity)
		"union":
			var u: UnionData = UnionDatabase.get_union(card_name)
			if not u:
				push_warning("[CardExporter] Unknown union: " + card_name)
				return
			const UNION_CYAN: Color = Color(0.25, 0.90, 1.00)
			var aff_keys: Array = CharacterData.Affinity.keys()
			var aff_idx: int = int(u.affinity)
			var aff_name: String = aff_keys[aff_idx].capitalize() if aff_idx < aff_keys.size() else ""
			_type.text = "UNION"
			_type.add_theme_color_override("font_color", UNION_CYAN)
			_frame.modulate = Color(1.0, 1.0, 1.0)
			_cost_num.text = str(u.summon_cost)
			_name.text = card_name
			_atk.text  = "ATK %d" % u.base_atk
			_def.text  = "DEF %d" % u.base_def
			_aff.text  = aff_name
			_aff.add_theme_color_override("font_color", UNION_CYAN)
			_desc.text = u.ability_description
			_style_pill(_atk, Color(0.75, 0.28, 0.05), Color(1.0, 0.55, 0.28))
			_style_pill(_def, Color(0.08, 0.28, 0.70), Color(0.35, 0.62, 1.0))
			_art.position = _art_base_pos
			var _snake_u: String = _card_name_to_snake(card_name)
			var _art_u: String = "res://assets/textures/cards/union/" + _snake_u + ".png"
			if not ResourceLoader.exists(_art_u):
				_art_u = u.artwork_path
			_load_art(_art_u)
			_set_rarity(u.rarity)
			# Zone grid
			var uz_set: Dictionary = {}
			for uzv: Vector2i in u.union_zone:
				uz_set[uzv] = true
			_union_info_panel.visible = true
			for _idx: int in range(_zone_cells.size()):
				var _zr: int = _idx / 5
				var _zc: int = _idx % 5
				(_zone_cells[_idx] as ColorRect).color = Color(0.25, 0.90, 1.00, 0.95) \
					if uz_set.has(Vector2i(_zr, _zc)) else Color(0.12, 0.12, 0.22, 0.75)
			# Material formula (unlocked)
			var _mat_text: String = u.formula_description.replace(
				str(u.summon_cost) + " crystals", "◆" + str(u.summon_cost))
			_mat_formula_lbl.text = _mat_text
		"dead_end":
			# Pure frame — black art area, no text, no pills
			_frame.modulate  = Color(1.0, 1.0, 1.0)
			_art.texture     = null   # art_bg ColorRect stays black
			_type.text = ""
			_cost.visible   = false
			_rarity.visible = false
			_name.text = ""
			_atk.text  = ""
			_def.text  = ""
			_aff.text  = ""
			_desc.text = ""
		_:
			push_warning("[CardExporter] Unknown card_type: " + card_type)

# ─────────────────────────────────────────────────────────────
# Helpers (mirrored from CardDetailOverlay)
# ─────────────────────────────────────────────────────────────

func _set_rarity(rarity: CharacterData.Rarity) -> void:
	_rarity.text = "★".repeat(rarity + 1)
	var col: Color
	match rarity:
		CharacterData.Rarity.COMMON:    col = Color(0.70, 0.70, 0.70)
		CharacterData.Rarity.UNCOMMON:  col = Color(0.75, 0.95, 0.75)
		CharacterData.Rarity.RARE:      col = Color(0.40, 0.70, 1.00)
		CharacterData.Rarity.LEGENDARY: col = Color(1.00, 0.80, 0.20)
		CharacterData.Rarity.EXOTIC:    col = Color(0.90, 0.40, 1.00)
		_:                              col = Color(1.0, 1.0, 1.0)
	_rarity.add_theme_color_override("font_color", col)

func _style_pill(lbl: Label, bg_col: Color, border_col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color                    = Color(bg_col.r, bg_col.g, bg_col.b, 0.28)
	sb.border_color                = border_col
	sb.border_width_left           = 2
	sb.border_width_right          = 2
	sb.border_width_top            = 2
	sb.border_width_bottom         = 2
	sb.corner_radius_top_left      = 5
	sb.corner_radius_top_right     = 5
	sb.corner_radius_bottom_left   = 5
	sb.corner_radius_bottom_right  = 5
	sb.content_margin_left         = 6
	sb.content_margin_right        = 6
	sb.content_margin_top          = 2
	sb.content_margin_bottom       = 2
	lbl.add_theme_stylebox_override("normal", sb)

func _load_art(path: String) -> void:
	var tex: Texture2D = null
	if path != "" and ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null and path.ends_with(".png"):
		var jpg_path := path.left(path.length() - 4) + ".jpg"
		if ResourceLoader.exists(jpg_path):
			tex = load(jpg_path) as Texture2D
	_art.texture = tex if tex != null else ART_PLACEHOLDER

# ─────────────────────────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────────────────────────

func _card_name_to_snake(card_name: String) -> String:
	return card_name.to_lower() \
		.replace(" ", "_") \
		.replace("'", "") \
		.replace("-", "_")

func _render_and_save_nsfw(card_name: String, card_type: String) -> void:
	var svp := SubViewport.new()
	svp.size = Vector2i(int(EXPORT_W), int(EXPORT_H))
	svp.transparent_bg = true
	svp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(svp)

	var card := _build_card_node()
	svp.add_child(card)
	_populate_card_node_nsfw(card_name, card_type)

	await get_tree().process_frame
	svp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame

	var img: Image = svp.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("[CardExporter] Failed to capture NSFW image for: " + card_name)
		svp.queue_free()
		return

	var fs_path := _output_path_nsfw(card_name)
	var err := img.save_png(fs_path)
	if err != OK:
		push_error("[CardExporter] save_png failed for NSFW '%s': error %d" % [card_name, err])

	svp.queue_free()

func _populate_card_node_nsfw(card_name: String, card_type: String) -> void:
	# Same as _populate_card_node but forces NSFW artwork
	_populate_card_node(card_name, card_type)
	var subfolder: String = _type_to_subfolder(card_type)
	if subfolder != "":
		_load_art(CardDatabase.find_artwork(card_name, subfolder, true))

func _type_to_subfolder(card_type: String) -> String:
	match card_type:
		"character": return "characters"
		"trap":      return "traps"
		"tech":      return "tech"
		"union":     return "unions"
	return ""

func _output_path_nsfw(card_name: String) -> String:
	var snake    := _card_name_to_snake(card_name)
	var res_path := OUTPUT_DIR + snake + "_nsfw.png"
	return ProjectSettings.globalize_path(res_path)

func _output_path(card_name: String, _card_type: String) -> String:
	var snake    := _card_name_to_snake(card_name)
	var res_path := OUTPUT_DIR + snake + ".png"
	return ProjectSettings.globalize_path(res_path)

func _output_path_union_locked(card_name: String) -> String:
	var res_path := OUTPUT_DIR + _card_name_to_snake(card_name) + "_locked.png"
	return ProjectSettings.globalize_path(res_path)

func _render_and_save_union_locked(card_name: String) -> void:
	var u: UnionData = UnionDatabase.get_union(card_name)
	if not u:
		return
	var svp := SubViewport.new()
	svp.size = Vector2i(int(EXPORT_W), int(EXPORT_H))
	svp.transparent_bg = true
	svp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(svp)
	var card := _build_card_node()
	svp.add_child(card)
	# Populate with locked content
	const UNION_CYAN: Color = Color(0.25, 0.90, 1.00)
	var aff_keys: Array = CharacterData.Affinity.keys()
	var aff_idx: int = int(u.affinity)
	var aff_name: String = aff_keys[aff_idx].capitalize() if aff_idx < aff_keys.size() else ""
	_type.text = "UNION  🔒"
	_type.add_theme_color_override("font_color", UNION_CYAN)
	_frame.modulate = Color(1.0, 1.0, 1.0)
	_cost_num.text = str(u.summon_cost)
	_name.text = card_name
	_atk.text  = "ATK %d" % u.base_atk
	_def.text  = "DEF %d" % u.base_def
	_aff.text  = aff_name
	_aff.add_theme_color_override("font_color", UNION_CYAN)
	_desc.text = u.partial_ability_description
	_style_pill(_atk, Color(0.75, 0.28, 0.05), Color(1.0, 0.55, 0.28))
	_style_pill(_def, Color(0.08, 0.28, 0.70), Color(0.35, 0.62, 1.0))
	_art.position = _art_base_pos
	var _snake_l: String = _card_name_to_snake(card_name)
	var _art_l: String = "res://assets/textures/cards/union/" + _snake_l + ".png"
	if not ResourceLoader.exists(_art_l):
		_art_l = u.artwork_path
	_load_art(_art_l)
	_set_rarity(u.rarity)
	var uz_set: Dictionary = {}
	for uzv: Vector2i in u.union_zone:
		uz_set[uzv] = true
	_union_info_panel.visible = true
	for _idx: int in range(_zone_cells.size()):
		var _zr: int = _idx / 5
		var _zc: int = _idx % 5
		(_zone_cells[_idx] as ColorRect).color = Color(0.25, 0.90, 1.00, 0.95) \
			if uz_set.has(Vector2i(_zr, _zc)) else Color(0.12, 0.12, 0.22, 0.75)
	var _partial_formula: String = u.partial_formula_description.replace(
		str(u.summon_cost) + " crystals", "◆" + str(u.summon_cost))
	_mat_formula_lbl.text = _partial_formula

	await get_tree().process_frame
	svp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame

	var img: Image = svp.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("[CardExporter] Failed to capture locked image for: " + card_name)
		svp.queue_free()
		return
	var err := img.save_png(_output_path_union_locked(card_name))
	if err != OK:
		push_error("[CardExporter] save_png (locked) failed for '%s': error %d" % [card_name, err])
	svp.queue_free()

func _collect_all_pairs() -> Array:
	var pairs: Array = []
	for name: String in CardDatabase.get_all_character_names():
		pairs.append([name, "character"])
	for name: String in CardDatabase.get_all_trap_names():
		pairs.append([name, "trap"])
	for name: String in CardDatabase.get_all_tech_names():
		pairs.append([name, "tech"])
	for u: UnionData in UnionDatabase.get_all_unions():
		pairs.append([u.card_name, "union"])
	return pairs
