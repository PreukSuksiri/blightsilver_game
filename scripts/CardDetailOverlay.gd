class_name CardDetailOverlay
extends Control
## Shared full-card detail overlay.
## Usage: CardDetailOverlay.open(parent_node, card_name, card_type)

const VELLUM_FRAME    := preload("res://assets/textures/cards/frames/vellum_card_frame_transparent.png")
const ART_PLACEHOLDER := preload("res://assets/textures/cards/placeholder.png")
const CHIVO_FONT      := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")
const CRYSTAL_ICON    := preload("res://assets/textures/ui/decorations/ui_crystal_indicator.png")

const AFFINITY_COLORS: Dictionary = {
	CharacterData.Affinity.DIVINE:  Color(1.00, 0.90, 0.30),
	CharacterData.Affinity.CHAOS:   Color(0.55, 0.05, 0.75),
	CharacterData.Affinity.NATURE:  Color(0.20, 0.80, 0.20),
	CharacterData.Affinity.ARCANE:  Color(0.15, 0.50, 1.00),
	CharacterData.Affinity.COSMIC:  Color(0.00, 0.90, 0.90),
	CharacterData.Affinity.BIO:     Color(0.55, 0.95, 0.10),
	CharacterData.Affinity.ANIMA:   Color(0.95, 0.40, 0.10),
}

# Proportions measured from vellum_card_frame_transparent.png (819×1126 px)
const FRAME_ASPECT := 819.0 / 1126.0  # ≈ 0.7277
const ART_L_PCT    := 0.051   # art window left edge   (% of card width)
const ART_R_PCT    := 0.949   # art window right edge
const ART_T_PCT    := 0.096   # art window top edge    (% of card height)
const ART_B_PCT    := 1.000   # art window bottom edge (bleeds slightly behind frame's info strip)
const INFO_TOP_PCT := 0.520   # info section top

var _art:      TextureRect
var _frame:    TextureRect
var _type:     Label
var _cost:     Control
var _cost_num: Label
var _name:     Label
var _atk:      Label
var _def:      Label
var _aff:      Label
var _desc:     Label
var _rarity:   Label

var _mod_label:      Label = null   # ATK/DEF modifier indicator
var _cost_mod_label: Label = null   # Cost modifier indicator

var _union_info_panel: ColorRect   # combined zone+formula strip (union only)
var _zone_cells:       Array       # Array[ColorRect], row-major (row*5+col)
var _mat_formula_lbl:  Label
var _card_inst: Variant = null  # GameState.CardInstance or null

var _info_y: float
var _info_h: float
var _pad_x:  float
var _card_w: float
var _art_base_pos: Vector2

# ─────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────
static func open(parent: Node, card_name: String, card_type: String,
		card_inst: Variant = null) -> void:
	var overlay := CardDetailOverlay.new()
	overlay._card_inst = card_inst
	overlay.z_index = 100
	parent.add_child(overlay)

	# Size card to 94 % of viewport height (almost full screen)
	var vp    := parent.get_viewport().get_visible_rect().size
	var card_h := minf(vp.y * 0.94, vp.x * 0.94 / FRAME_ASPECT)
	var card_w := card_h * FRAME_ASPECT

	overlay._build_ui(card_w, card_h)
	overlay._populate(card_name, card_type)

# ─────────────────────────────────────────────────────────────
# UI construction
# ─────────────────────────────────────────────────────────────
func _build_ui(card_w: float, card_h: float) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP

	# Dimmer – click anywhere outside card to close
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.82)
	dimmer.mouse_filter = MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close())
	add_child(dimmer)

	# Card container – centred in the overlay
	var card := Control.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left   = -card_w * 0.5
	card.offset_top    = -card_h * 0.5
	card.offset_right  =  card_w * 0.5
	card.offset_bottom =  card_h * 0.5
	card.mouse_filter  = MOUSE_FILTER_STOP
	# Click on blank areas within the card bounding rect (transparent corners,
	# frame edges) also dismisses the overlay.
	card.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_close())
	add_child(card)

	# Derived layout helpers
	var al      := ART_L_PCT   * card_w
	var ar      := ART_R_PCT   * card_w
	var at      := ART_T_PCT   * card_h
	var ab      := ART_B_PCT   * card_h
	var aw      := ar - al
	var ah      := ab - at
	var info_y  := INFO_TOP_PCT * card_h
	var info_h  := card_h - info_y
	var pad_x   := al + 15                       # horizontal padding mirrors art inset
	_info_y = info_y
	_info_h = info_h
	_pad_x  = pad_x
	_card_w = card_w

	# ── Art layer ──────────────────────────────────────────────
	var art_bg := ColorRect.new()
	art_bg.position    = Vector2(al, at)
	art_bg.size        = Vector2(aw, ah)
	art_bg.color       = Color(0.04, 0.04, 0.06)
	art_bg.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(art_bg)

	_art = TextureRect.new()
	_art_base_pos     = Vector2(al, at)
	_art.position     = _art_base_pos
	_art.size         = Vector2(aw, ah)
	_art.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE   # must be set or texture overrides size
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(_art)

	# Gradient fade at the bottom of the art window into the info section
	var fade := ColorRect.new()
	fade.position    = Vector2(al, ab - ah * 0.20)
	fade.size        = Vector2(aw, ah * 0.20)
	fade.color       = Color(0.04, 0.04, 0.06, 0.68)
	fade.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(fade)

	# ── Vellum frame – must be drawn ABOVE art, covers full card ──
	_frame = TextureRect.new()
	var frame := _frame
	frame.position     = Vector2.ZERO
	frame.size         = Vector2(card_w, card_h)
	frame.texture      = VELLUM_FRAME
	frame.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE  # critical – prevents native-size blowout
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(frame)

	# ── Header (0 → ART_T_PCT * card_h) ───────────────────────
	var hdr_h    := at                          # header height in px
	var fsz_hdr  := maxi(int(card_w * 0.044), 10)

	# Type label – top left
	_type = Label.new()
	_type.position          = Vector2(pad_x, hdr_h * 0.25)
	_type.size              = Vector2(card_w * 0.55, hdr_h * 0.64)
	_type.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_type.add_theme_font_size_override("font_size", fsz_hdr)
	_type.add_theme_font_override("font", CHIVO_FONT)
	card.add_child(_type)

	# Cost badge – top right (crystal icon + number in rounded pill)
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
	cost_pc.mouse_filter = MOUSE_FILTER_IGNORE
	cost_pc.add_theme_stylebox_override("panel", cost_sb)
	var cost_hbox := HBoxContainer.new()
	cost_hbox.alignment    = BoxContainer.ALIGNMENT_CENTER
	cost_hbox.mouse_filter = MOUSE_FILTER_IGNORE
	cost_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cost_pc.add_child(cost_hbox)
	var cost_icon := TextureRect.new()
	cost_icon.texture              = CRYSTAL_ICON
	cost_icon.expand_mode          = TextureRect.EXPAND_IGNORE_SIZE
	cost_icon.stretch_mode         = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cost_icon.custom_minimum_size  = Vector2(fsz_hdr, fsz_hdr)
	cost_icon.mouse_filter         = MOUSE_FILTER_IGNORE
	cost_hbox.add_child(cost_icon)
	_cost_num = Label.new()
	_cost_num.add_theme_font_size_override("font_size", fsz_hdr)
	_cost_num.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	_cost_num.add_theme_font_override("font", CHIVO_FONT)
	_cost_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_num.mouse_filter       = MOUSE_FILTER_IGNORE
	cost_hbox.add_child(_cost_num)
	_cost = cost_pc
	card.add_child(_cost)

	# ── Cost modifier indicator (below cost badge) ──
	_cost_mod_label = Label.new()
	_cost_mod_label.position             = Vector2(card_w * 0.68, hdr_h * 0.88)
	_cost_mod_label.size                 = Vector2(card_w * 0.27, hdr_h * 0.5)
	_cost_mod_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_mod_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_cost_mod_label.add_theme_font_size_override("font_size", maxi(int(card_w * 0.032), 8))
	_cost_mod_label.add_theme_font_override("font", CHIVO_FONT)
	_cost_mod_label.mouse_filter = MOUSE_FILTER_IGNORE
	_cost_mod_label.visible = false
	card.add_child(_cost_mod_label)

	# Close button – outside the card frame, anchored to card's top-right corner
	var close_btn := Button.new()
	var cb_size   := 38.0
	close_btn.text = "✕"
	close_btn.set_anchors_preset(Control.PRESET_CENTER)
	close_btn.offset_left   = card_w * 0.5 + 8.0
	close_btn.offset_top    = -card_h * 0.5
	close_btn.offset_right  = card_w * 0.5 + 8.0 + cb_size
	close_btn.offset_bottom = -card_h * 0.5 + cb_size
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(_close)
	add_child(close_btn)

	# ── Info section (INFO_TOP_PCT → 1.0) ──────────────────────
	var fsz_name := maxi(int(card_w * 0.04), 5)   # large card name
	var fsz_stat := maxi(int(card_w * 0.035), 3)   # ATK / DEF / affinity
	var fsz_desc := maxi(int(card_w * 0.035), 3)    # description

	# Card name
	_name = Label.new()
	_name.position          = Vector2(pad_x, info_y + info_h * 0.45)
	_name.size              = Vector2(card_w - pad_x * 2.0, info_h * 0.34)
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name.add_theme_font_size_override("font_size", fsz_name)
	_name.add_theme_font_override("font", CHIVO_FONT)
	_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82))
	card.add_child(_name)

	# Stats row – ATK pill | DEF pill | Affinity (right-aligned)
	var stats_y   := info_y + info_h * 0.67
	var stats_h   := info_h * 0.07
	var pill_w    := card_w * 0.16
	var pill_gap  := card_w * 0.01

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
	_def.position             = Vector2(pad_x + pill_w + pill_gap+4, stats_y)
	_def.size                 = Vector2(pill_w, stats_h)
	_def.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_def.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_def.add_theme_font_size_override("font_size", fsz_stat)
	_def.add_theme_color_override("font_color", Color(0.38, 0.68, 1.0))
	_def.add_theme_font_override("font", CHIVO_FONT)
	card.add_child(_def)

	# ── ATK/DEF modifier indicator (to the right of DEF pill) ──
	var def_right_x := pad_x + 2.0 * pill_w + pill_gap + 4.0 + 8.0
	var mod_w := card_w - def_right_x - pad_x * 0.5
	_mod_label = Label.new()
	_mod_label.position           = Vector2(def_right_x, stats_y)
	_mod_label.size               = Vector2(mod_w, stats_h)
	_mod_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mod_label.add_theme_font_size_override("font_size", fsz_stat)
	_mod_label.add_theme_font_override("font", CHIVO_FONT)
	_mod_label.mouse_filter = MOUSE_FILTER_IGNORE
	_mod_label.visible = false
	card.add_child(_mod_label)

	# Affinity – right-aligned, same row
	_aff = Label.new()
	_aff.position             = Vector2(pad_x, stats_y-40)
	_aff.size                 = Vector2(card_w - pad_x * 2.0, stats_h)
	_aff.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_aff.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_aff.add_theme_font_size_override("font_size", fsz_stat+10)
	_aff.add_theme_font_override("font", CHIVO_FONT)
	card.add_child(_aff)

	# Description
	_desc = Label.new()
	_desc.position          = Vector2(pad_x, info_y + info_h * 0.76)
	_desc.size              = Vector2(card_w - pad_x * 2.0, info_h * 0.23)
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
	_rarity.mouse_filter         = MOUSE_FILTER_IGNORE
	card.add_child(_rarity)

	# Union info panel — single wide strip at bottom of art area (hidden for non-union cards)
	const ZONE_C: int = 20
	const ZONE_G: int = 2
	const ZONE_P: int = 5
	const ZONE_S: int = 5 * ZONE_C + 4 * ZONE_G + ZONE_P * 2  # 118px
	var zone_bot:  float = 0.76 * card_h - 10.0
	var pan_left:  float = ART_L_PCT * card_w + 12.0
	var pan_right: float = ART_R_PCT * card_w - 12.0
	var pan_w:     float = pan_right - pan_left

	_union_info_panel = ColorRect.new()
	_union_info_panel.position     = Vector2(pan_left, zone_bot - ZONE_S)
	_union_info_panel.size         = Vector2(pan_w, ZONE_S)
	_union_info_panel.color        = Color(0.0, 0.0, 0.0, 0.72)
	_union_info_panel.visible      = false
	_union_info_panel.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(_union_info_panel)

	var grid_x_off: float = pan_w - float(ZONE_S)
	_zone_cells = []
	for _zr: int in range(5):
		for _zc: int in range(5):
			var _zcr := ColorRect.new()
			_zcr.size         = Vector2(ZONE_C, ZONE_C)
			_zcr.position     = Vector2(grid_x_off + ZONE_P + _zc * (ZONE_C + ZONE_G),
									   ZONE_P + _zr * (ZONE_C + ZONE_G))
			_zcr.color        = Color(0.12, 0.12, 0.22, 0.75)
			_zcr.mouse_filter = MOUSE_FILTER_IGNORE
			_union_info_panel.add_child(_zcr)
			_zone_cells.append(_zcr)

	_mat_formula_lbl = Label.new()
	_mat_formula_lbl.position              = Vector2(8.0, 6.0)
	_mat_formula_lbl.size                  = Vector2(grid_x_off - 16.0, float(ZONE_S) - 12.0)
	_mat_formula_lbl.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	_mat_formula_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_mat_formula_lbl.add_theme_font_size_override("font_size", 24)
	_mat_formula_lbl.add_theme_color_override("font_color", Color.WHITE)
	_mat_formula_lbl.add_theme_font_override("font", CHIVO_FONT)
	_mat_formula_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	_union_info_panel.add_child(_mat_formula_lbl)

# ─────────────────────────────────────────────────────────────
# Data population
# ─────────────────────────────────────────────────────────────
const TYPE_COLOR_CHARACTER := Color(1.0, 0.71, 0.2, 1.0)  # yellow
const TYPE_COLOR_TRAP      := Color(1.0, 0.263, 0.345, 1.0)  # red
const TYPE_COLOR_TECH      := Color(0.18, 0.764, 0.341, 1.0)  # green
const TYPE_COLOR_UNION     := Color(0.25, 0.90, 1.00, 1.0)   # cyan

func _populate(card_name: String, card_type: String) -> void:
	match card_type:
		"character":
			var data: CharacterData = CardDatabase.get_character(card_name)
			if not data:
				return
			var aff_name: String = CharacterData.Affinity.keys()[data.affinity].capitalize()
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
			# Modifier overlay — only shown when a live CardInstance is available
			_mod_label.visible      = false
			_cost_mod_label.visible = false
			if _card_inst != null and _card_inst.card_type == "character":
				var eff_atk: int = _card_inst.get_effective_atk()
				var eff_def: int = _card_inst.get_effective_def()
				var atk_changed: bool = eff_atk != data.base_atk
				var def_changed: bool = eff_def != data.base_def
				if atk_changed or def_changed:
					_mod_label.text = "▶  ATK=%d / DEF=%d" % [eff_atk, eff_def]
					var atk_up: bool = eff_atk > data.base_atk
					var def_up: bool = eff_def > data.base_def
					var mod_col: Color
					if atk_up and def_up:
						mod_col = Color(0.35, 1.0, 0.45)
					elif not atk_up and not def_up:
						mod_col = Color(1.0, 0.38, 0.38)
					else:
						mod_col = Color(1.0, 0.88, 0.35)
					_mod_label.add_theme_color_override("font_color", mod_col)
					_mod_label.visible = true
				if _card_inst.crystal_cost != data.crystal_cost:
					_cost_mod_label.text = "▼  %d◆" % _card_inst.crystal_cost
					var cost_col: Color = Color(0.35, 1.0, 0.45) \
						if _card_inst.crystal_cost < data.crystal_cost \
						else Color(1.0, 0.38, 0.38)
					_cost_mod_label.add_theme_color_override("font_color", cost_col)
					_cost_mod_label.visible = true
			_art.position = _art_base_pos + data.artwork_offset
			_load_art(CardDatabase.find_artwork(card_name, "characters", SaveManager.nsfw_enabled))
			_set_rarity(data.rarity)
			AudioManager.speak("%s...... Ability: %s... Cost: %d... ATK: %d... DEF: %d... Affinity: %s." % [
				card_name, data.get_ability_description(),
				data.crystal_cost, data.base_atk, data.base_def, aff_name])
		"trap":
			var data: TrapData = CardDatabase.get_trap(card_name)
			if not data:
				return
			_type.text = "TRAP"
			_type.add_theme_color_override("font_color", TYPE_COLOR_TRAP)
			_frame.modulate = Color(1.0, 0.65, 0.65)
			_cost_num.text = str(data.crystal_cost)
			_name.text = card_name
			_atk.text  = ""
			_def.text  = ""
			_aff.text  = ""
			#_aff.text  = "Trap"
			_aff.add_theme_color_override("font_color", TYPE_COLOR_TRAP)
			_desc.text     = data.get_effect_description()
			_desc.position = Vector2(_pad_x, _info_y + _info_h * 0.67)
			_desc.size     = Vector2(_card_w - _pad_x * 2.0, _info_h * 0.32)
			_art.position = _art_base_pos + data.artwork_offset
			_load_art(CardDatabase.find_artwork(card_name, "traps", SaveManager.nsfw_enabled))
			_set_rarity(data.rarity)
			AudioManager.speak("Trap... %s...... %s... Cost: %d." % [
				card_name, data.get_effect_description(), data.crystal_cost])
		"tech":
			var data: TechCardData = CardDatabase.get_tech(card_name)
			if not data:
				return
			_type.text = "TECH"
			_type.add_theme_color_override("font_color", TYPE_COLOR_TECH)
			_frame.modulate = Color(0.65, 1.0, 0.65)
			_cost_num.text = str(data.crystal_cost)
			_name.text = card_name
			_atk.text  = ""
			_def.text  = ""
			_aff.text  = ""
			#_aff.text  = "Tech"
			_aff.add_theme_color_override("font_color", TYPE_COLOR_TECH)
			_desc.text     = data.get_effect_description()
			_desc.position = Vector2(_pad_x, _info_y + _info_h * 0.67)
			_desc.size     = Vector2(_card_w - _pad_x * 2.0, _info_h * 0.32)
			_art.position = _art_base_pos + data.artwork_offset
			_load_art(CardDatabase.find_artwork(card_name, "tech", SaveManager.nsfw_enabled))
			_set_rarity(data.rarity)
			AudioManager.speak("Tech card... %s...... %s... Cost: %d." % [
				card_name, data.get_effect_description(), data.crystal_cost])
		"union":
			var u: UnionData = UnionDatabase.get_union(card_name)
			if not u:
				return
			var is_unlocked: bool = SaveManager.is_union_unlocked(card_name)
			var aff_name: String = CharacterData.Affinity.keys()[int(u.affinity)].capitalize()
			var shown_desc: String = u.ability_description if is_unlocked else u.partial_ability_description
			_type.text = "UNION" + ("" if is_unlocked else "  🔒")
			_type.add_theme_color_override("font_color", TYPE_COLOR_UNION)
			_frame.modulate = Color(0.55, 0.95, 1.0)
			_cost_num.text = str(u.summon_cost)
			_name.text = card_name
			_atk.text  = "ATK %d" % u.base_atk
			_def.text  = "DEF %d" % u.base_def
			_aff.text  = aff_name
			_aff.add_theme_color_override("font_color", TYPE_COLOR_UNION)
			_desc.text = shown_desc
			_style_pill(_atk, Color(0.75, 0.28, 0.05), Color(1.0, 0.55, 0.28))
			_style_pill(_def, Color(0.08, 0.28, 0.70), Color(0.35, 0.62, 1.0))
			_mod_label.visible      = false
			_cost_mod_label.visible = false
			_load_art(CardDatabase.find_artwork(card_name, "unions", SaveManager.nsfw_enabled))
			_set_rarity(int(u.rarity))
			# Union zone + formula panel
			var uz_set: Dictionary = {}
			for uzv: Vector2i in u.union_zone:
				uz_set[uzv] = true
			_union_info_panel.visible = true
			for _idx: int in range(_zone_cells.size()):
				var _uzr: int = _idx / 5
				var _uzc: int = _idx % 5
				(_zone_cells[_idx] as ColorRect).color = Color(0.25, 0.90, 1.00, 0.95) \
					if uz_set.has(Vector2i(_uzr, _uzc)) else Color(0.12, 0.12, 0.22, 0.75)
			var _mat_text: String = u.formula_description.replace(
				str(u.summon_cost) + " crystals", "◆" + str(u.summon_cost))
			_mat_formula_lbl.text = _mat_text
			AudioManager.speak("Union... %s...... %s... Cost: %d... ATK: %d... DEF: %d... Affinity: %s." % [
				card_name, shown_desc, u.summon_cost, u.base_atk, u.base_def, aff_name])
		"dead_end":
			# Show the pre-rendered dead end card PNG as the full card image
			var card_h := _info_y / INFO_TOP_PCT
			_art.position     = Vector2.ZERO
			_art.size         = Vector2(_card_w, card_h)
			_art.stretch_mode = TextureRect.STRETCH_SCALE
			_art.texture      = load("res://assets/textures/cards/full_cards/blank.png")
			_frame.visible  = false
			_cost.visible   = false
			_rarity.visible = false
			_type.text = ""
			_name.text = ""
			_atk.text  = ""
			_def.text  = ""
			_aff.text  = ""
			_desc.text = ""

# ─────────────────────────────────────────────────────────────
# Helpers
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
	sb.bg_color               = Color(bg_col.r, bg_col.g, bg_col.b, 0.28)
	sb.border_color           = border_col
	sb.border_width_left      = 2
	sb.border_width_right     = 2
	sb.border_width_top       = 2
	sb.border_width_bottom    = 2
	sb.corner_radius_top_left     = 5
	sb.corner_radius_top_right    = 5
	sb.corner_radius_bottom_left  = 5
	sb.corner_radius_bottom_right = 5
	sb.content_margin_left    = 6
	sb.content_margin_right   = 6
	sb.content_margin_top     = 2
	sb.content_margin_bottom  = 2
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
# Close
# ─────────────────────────────────────────────────────────────
func _close() -> void:
	AudioManager.tts_stop()
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
