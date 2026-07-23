class_name CardDetailOverlay
extends Control
## Shared full-card detail overlay.
## Usage: CardDetailOverlay.open(parent_node, card_name, card_type)
## parent_node is used only to locate the scene; the overlay is parented to the scene root.

const VELLUM_FRAME    := preload("res://assets/textures/cards/frames/vellum_card_frame_transparent.png")
const ART_PLACEHOLDER := preload("res://assets/textures/cards/placeholder.png")
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
var _force_unlocked: bool = false  # true when viewing a union placed on the board
var _show_quantity: bool = false  # true when opened from gallery
var _card_name_for_bug: String = ""  # stored for TAG BUG button

var _info_y: float
var _info_h: float
var _pad_x:  float
var _card_w: float
var _art_base_pos: Vector2
var _card_root: Control = null

# ─────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────

## Attach overlays to the scene root so PRESET_FULL_RECT / PRESET_CENTER use the viewport,
## not a small card tile (e.g. formation grid cells in DeckBuilder).
static func _find_overlay_host(from: Node) -> Node:
	var tree := from.get_tree()
	if tree == null:
		return from
	var node: Node = from
	while node.get_parent() != null and node.get_parent() != tree.root:
		node = node.get_parent()
	return node

static func open(parent: Node, card_name: String, card_type: String,
		card_inst: Variant = null, show_quantity: bool = false,
		pin_to_parent: bool = false, z_index_override: int = -1) -> void:
	open_and_return(parent, card_name, card_type, card_inst, show_quantity,
		pin_to_parent, z_index_override)


static func open_and_return(parent: Node, card_name: String, card_type: String,
		card_inst: Variant = null, show_quantity: bool = false,
		pin_to_parent: bool = false, z_index_override: int = -1) -> CardDetailOverlay:
	var overlay := CardDetailOverlay.new()
	overlay._card_inst          = card_inst
	overlay._show_quantity      = show_quantity
	overlay._card_name_for_bug  = card_name
	var viewport_host := parent if pin_to_parent else _find_overlay_host(parent)
	var use_gamedialog_host := z_index_override >= GameDialog.DEFAULT_Z_INDEX
	if z_index_override >= 0:
		overlay.z_index = z_index_override
	elif pin_to_parent and viewport_host is Control:
		overlay.z_index = (viewport_host as Control).z_index + 50
	else:
		overlay.z_index = 101
	if use_gamedialog_host:
		GameDialog.attach_viewport_overlay(overlay, parent)
		overlay.move_to_front()
	else:
		viewport_host.add_child(overlay)

	# Size card to 94 % of viewport height (almost full screen)
	var vp    := viewport_host.get_viewport().get_visible_rect().size
	var card_h := minf(vp.y * 0.94, vp.x * 0.94 / FRAME_ASPECT)
	var card_w := card_h * FRAME_ASPECT

	# Try to load a pre-rendered full card image from full_cards/
	var snake: String = card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
	var full_card_path: String = ""
	var _is_union: bool = card_type == "union" or (card_inst != null and card_inst.is_union)
	if _is_union:
		var _force_unlocked_check: bool = card_inst != null and card_inst.is_union
		var _is_unlocked: bool = _force_unlocked_check or SaveManager.is_union_unlocked(card_name)
		if _is_unlocked:
			for _p: String in [
				"res://assets/textures/cards/full_cards/" + snake + ".png",
				"res://assets/textures/cards/full_cards/" + snake + ".jpg",
			]:
				if ResourceLoader.exists(_p):
					full_card_path = _p
					break
		else:
			for _p: String in [
				"res://assets/textures/cards/full_cards/" + snake + "_locked.png",
				"res://assets/textures/cards/full_cards/" + snake + "_locked.jpg",
			]:
				if ResourceLoader.exists(_p):
					full_card_path = _p
					break
	else:
		for _p: String in [
			"res://assets/textures/cards/full_cards/" + snake + ".png",
			"res://assets/textures/cards/full_cards/" + snake + ".jpg",
		]:
			if ResourceLoader.exists(_p):
				full_card_path = _p
				break

	if not full_card_path.is_empty():
		overlay._build_static_ui(card_w, card_h, full_card_path)
	else:
		overlay._build_ui(card_w, card_h)
		overlay._populate(card_name, card_type)

	if show_quantity:
		overlay._add_quantity_label(card_name, card_w, card_h)
		if card_type in ["character", "trap", "tech"]:
			overlay._add_gallery_buttons(card_name, card_type, card_w, card_h)

	overlay._attach_card_status_overlay(card_w, card_h)
	return overlay


static func find_first_in_tree(root: Node) -> CardDetailOverlay:
	if root is CardDetailOverlay:
		return root as CardDetailOverlay
	for child: Node in root.get_children():
		var found: CardDetailOverlay = find_first_in_tree(child)
		if found != null:
			return found
	return null

# ─────────────────────────────────────────────────────────────
# UI construction — static image path (full_cards/ PNG/JPG)
# ─────────────────────────────────────────────────────────────
func _build_static_ui(card_w: float, card_h: float, full_card_path: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP

	# Dimmer – click outside card to close
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.82)
	dimmer.mouse_filter = MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close())
	add_child(dimmer)

	# Card container – centred
	var card := Control.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left   = -card_w * 0.5
	card.offset_top    = -card_h * 0.5
	card.offset_right  =  card_w * 0.5
	card.offset_bottom =  card_h * 0.5
	card.mouse_filter  = MOUSE_FILTER_STOP
	card.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_close())
	add_child(card)
	_card_root = card
	var img := TextureRect.new()
	img.position     = Vector2.ZERO
	img.size         = Vector2(card_w, card_h)
	img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.texture      = load(full_card_path) as Texture2D
	img.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(img)

	# Close button – top-right, outside card frame
	var close_btn := Button.new()
	var cb_size   := 38.0
	close_btn.set_anchors_preset(Control.PRESET_CENTER)
	close_btn.offset_left   = card_w * 0.5 + 8.0
	close_btn.offset_top    = -card_h * 0.5
	close_btn.offset_right  = card_w * 0.5 + 8.0 + cb_size
	close_btn.offset_bottom = -card_h * 0.5 + cb_size
	MenuScreenHeader.style_close_button(close_btn)
	close_btn.pressed.connect(_close)
	add_child(close_btn)

	# Store layout helpers (used by _add_quantity_label / _add_gallery_buttons)
	_card_w = card_w
	_info_y = INFO_TOP_PCT * card_h
	_info_h = card_h - _info_y
	_pad_x  = ART_L_PCT * card_w + 15.0

	# ATK/DEF modifier overlay for live battle stats
	if _card_inst != null and _card_inst.card_type == "character":
		var fsz_stat: int = maxi(int(card_w * 0.035), 3)
		var stats_y: float   = _info_y + _info_h * 0.67
		var stats_h: float   = _info_h * 0.07
		var pill_w: float    = card_w * 0.16
		var pill_gap: float  = card_w * 0.01
		var def_right_x: float = _pad_x + 2.0 * pill_w + pill_gap + 4.0 + 8.0
		var mod_w: float = card_w - def_right_x - _pad_x * 0.5
		_mod_label = Label.new()
		_mod_label.position           = Vector2(def_right_x, stats_y)
		_mod_label.size               = Vector2(mod_w, stats_h)
		_mod_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_mod_label.add_theme_font_size_override("font_size", fsz_stat)
		FontManager.tag_primary(_mod_label)
		_mod_label.mouse_filter = MOUSE_FILTER_IGNORE
		_mod_label.visible = false
		card.add_child(_mod_label)
		var base_atk: int = -1
		var base_def: int = -1
		if _card_inst.is_union:
			var u: UnionData = UnionDatabase.get_union(_card_inst.card_name)
			if u:
				base_atk = u.base_atk
				base_def = u.base_def
		else:
			var data: CharacterData = CardDatabase.get_character(_card_inst.card_name)
			if data:
				base_atk = data.base_atk
				base_def = data.base_def
		if base_atk >= 0 and base_def >= 0:
			_apply_live_stat_mod_label(base_atk, base_def)

# ─────────────────────────────────────────────────────────────
# UI construction — programmatic card (fallback when no full_cards/ image)
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
	_card_root = card

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
	FontManager.tag_primary(_type)
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
	cost_icon.texture              = HudSkin.hud_tex("ui_crystal_indicator.png")
	cost_icon.expand_mode          = TextureRect.EXPAND_IGNORE_SIZE
	cost_icon.stretch_mode         = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cost_icon.custom_minimum_size  = Vector2(fsz_hdr, fsz_hdr)
	cost_icon.mouse_filter         = MOUSE_FILTER_IGNORE
	cost_hbox.add_child(cost_icon)
	_cost_num = Label.new()
	_cost_num.add_theme_font_size_override("font_size", fsz_hdr)
	_cost_num.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	FontManager.tag_primary(_cost_num)
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
	FontManager.tag_primary(_cost_mod_label)
	_cost_mod_label.mouse_filter = MOUSE_FILTER_IGNORE
	_cost_mod_label.visible = false
	card.add_child(_cost_mod_label)

	# Close button – outside the card frame, anchored to card's top-right corner
	var close_btn := Button.new()
	var cb_size   := 38.0
	close_btn.set_anchors_preset(Control.PRESET_CENTER)
	close_btn.offset_left   = card_w * 0.5 + 8.0
	close_btn.offset_top    = -card_h * 0.5
	close_btn.offset_right  = card_w * 0.5 + 8.0 + cb_size
	close_btn.offset_bottom = -card_h * 0.5 + cb_size
	MenuScreenHeader.style_close_button(close_btn)
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
	FontManager.tag_primary(_name)
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
	FontManager.tag_primary(_atk)
	card.add_child(_atk)

	_def = Label.new()
	_def.position             = Vector2(pad_x + pill_w + pill_gap+4, stats_y)
	_def.size                 = Vector2(pill_w, stats_h)
	_def.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_def.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_def.add_theme_font_size_override("font_size", fsz_stat)
	_def.add_theme_color_override("font_color", Color(0.38, 0.68, 1.0))
	FontManager.tag_primary(_def)
	card.add_child(_def)

	# ── ATK/DEF modifier indicator (to the right of DEF pill) ──
	var def_right_x := pad_x + 2.0 * pill_w + pill_gap + 4.0 + 8.0
	var mod_w := card_w - def_right_x - pad_x * 0.5
	_mod_label = Label.new()
	_mod_label.position           = Vector2(def_right_x, stats_y)
	_mod_label.size               = Vector2(mod_w, stats_h)
	_mod_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mod_label.add_theme_font_size_override("font_size", fsz_stat)
	FontManager.tag_primary(_mod_label)
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
	FontManager.tag_primary(_aff)
	card.add_child(_aff)

	# Description
	_desc = Label.new()
	_desc.position          = Vector2(pad_x, info_y + info_h * 0.76)
	_desc.size              = Vector2(card_w - pad_x * 2.0, info_h * 0.23)
	_desc.add_theme_font_size_override("font_size", fsz_desc)
	_desc.add_theme_color_override("font_color", Color(0.82, 0.88, 0.98))
	_desc.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	_desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	FontManager.tag_primary(_desc)
	card.add_child(_desc)

	# Rarity stars – lower-right corner
	var fsz_rarity := maxi(int(card_w * 0.04), 10)
	_rarity = Label.new()
	_rarity.position             = Vector2(pad_x, card_h - float(fsz_rarity) - 14.0)
	_rarity.size                 = Vector2(card_w - pad_x * 2.0, float(fsz_rarity) + 8.0)
	_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rarity.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_rarity.add_theme_font_size_override("font_size", fsz_rarity)
	FontManager.tag_primary(_rarity)
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
	FontManager.tag_primary(_mat_formula_lbl)
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
			# A union card placed on the board has card_type="character" with is_union=true.
			# Redirect to union rendering and treat it as unlocked for both players.
			if _card_inst != null and _card_inst.is_union:
				_force_unlocked = true
				_populate(card_name, "union")
				return
			var data: CharacterData = CardDatabase.get_character(card_name)
			if not data:
				return
			var aff_name: String = CharacterData.Affinity.keys()[data.affinity].capitalize()
			_type.text = "UNIT"
			_type.add_theme_color_override("font_color", TYPE_COLOR_CHARACTER)
			_frame.modulate = Color(1.0, 1.0, 1.0)
			_cost_num.text = str(data.crystal_cost)
			_name.text = data.display_name if not data.display_name.is_empty() else card_name
			_atk.text  = "ATK %d" % data.base_atk
			_def.text  = "DEF %d" % data.base_def
			_aff.text  = aff_name
			_aff.add_theme_color_override("font_color", TYPE_COLOR_CHARACTER)
			_desc.text = data.get_ability_description()
			_style_pill(_atk, Color(0.75, 0.28, 0.05), Color(1.0, 0.55, 0.28))
			_style_pill(_def, Color(0.08, 0.28, 0.70), Color(0.35, 0.62, 1.0))
			_mod_label.visible      = false
			_cost_mod_label.visible = false
			if _card_inst != null and _card_inst.card_type == "character":
				_apply_live_stat_mod_label(data.base_atk, data.base_def)
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
			_name.text = data.display_name if not data.display_name.is_empty() else card_name
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
			_name.text = data.display_name if not data.display_name.is_empty() else card_name
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
			var is_unlocked: bool = _force_unlocked or SaveManager.is_union_unlocked(card_name)
			var aff_name: String = CharacterData.Affinity.keys()[int(u.affinity)].capitalize()
			var shown_desc: String = u.ability_description if is_unlocked else u.partial_ability_description
			_type.text = "UNION" + ("" if is_unlocked else "  🔒")
			_type.add_theme_color_override("font_color", TYPE_COLOR_UNION)
			_frame.modulate = Color(0.55, 0.95, 1.0)
			_cost_num.text = "0"
			_name.text = u.display_name if not u.display_name.is_empty() else card_name
			_atk.text  = "ATK %d" % u.base_atk
			_def.text  = "DEF %d" % u.base_def
			_aff.text  = aff_name
			_aff.add_theme_color_override("font_color", TYPE_COLOR_UNION)
			_desc.text = shown_desc
			_style_pill(_atk, Color(0.75, 0.28, 0.05), Color(1.0, 0.55, 0.28))
			_style_pill(_def, Color(0.08, 0.28, 0.70), Color(0.35, 0.62, 1.0))
			_mod_label.visible      = false
			_cost_mod_label.visible = false
			if _card_inst != null and _card_inst.card_type == "character":
				_apply_live_stat_mod_label(u.base_atk, u.base_def)
			# Art: locked vs unlocked version
			var _snake: String = card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
			var _art_path: String = ""
			if is_unlocked:
				for _p: String in [
					"res://assets/textures/cards/union/" + _snake + ".png",
				]:
					if ResourceLoader.exists(_p):
						_art_path = _p
						break
			else:
				for _p: String in [
					"res://assets/textures/cards/full_cards/" + _snake + "_locked.png",
				]:
					if ResourceLoader.exists(_p):
						_art_path = _p
						break
			if _art_path.is_empty():
				_art_path = CardDatabase.find_artwork(card_name, "unions", SaveManager.nsfw_enabled)
			_load_art(_art_path)
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
			var _formula_src: String = u.formula_description if is_unlocked else u.partial_formula_description
			var _mat_text: String = _formula_src.replace(
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
# Live card status (battle overlay — right side of art)
# ─────────────────────────────────────────────────────────────
func _resolve_card_owner() -> Dictionary:
	if _card_inst == null:
		return {"owner": -1, "pos": Vector2i(-1, -1)}
	for player: int in [0, 1]:
		var pos: Vector2i = GameState.find_card_position(player, _card_inst)
		if pos != Vector2i(-1, -1):
			return {"owner": player, "pos": pos}
	return {"owner": -1, "pos": Vector2i(-1, -1)}


func _attach_card_status_overlay(card_w: float, card_h: float) -> void:
	if _card_root == null or _card_inst == null:
		return

	var owner_info: Dictionary = _resolve_card_owner()
	var lines: PackedStringArray = BattleLogFormat.format_overlay_status_lines(
		_card_inst,
		int(owner_info.get("owner", -1)),
		owner_info.get("pos", Vector2i(-1, -1)) as Vector2i
	)
	if lines.is_empty():
		return

	var art_l: float = ART_L_PCT * card_w
	var art_r: float = ART_R_PCT * card_w
	var art_t: float = ART_T_PCT * card_h
	var art_b: float = INFO_TOP_PCT * card_h
	var art_w_px: float = art_r - art_l
	var art_h_px: float = art_b - art_t
	var margin: float = 6.0
	var panel_w: float = art_w_px * 0.44

	var panel := VBoxContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(art_r - panel_w - margin, art_t + margin)
	panel.size = Vector2(panel_w, maxf(art_h_px - margin * 2.0, 0.0))
	panel.add_theme_constant_override("separation", 3)
	_card_root.add_child(panel)

	var fsz: int = maxi(int(card_w * 0.028), 10)
	for line: String in lines:
		var lbl := Label.new()
		lbl.text = line
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.add_theme_font_size_override("font_size", fsz)
		lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		FontManager.tag_primary(lbl)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(lbl)


# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _apply_live_stat_mod_label(base_atk: int, base_def: int) -> void:
	if _mod_label == null or _card_inst == null:
		return
	_mod_label.visible = false
	var eff_atk: int = _card_inst.get_effective_atk()
	var eff_def: int = _card_inst.get_effective_def()
	if eff_atk == base_atk and eff_def == base_def:
		return
	_mod_label.text = "▶  ATK=%d / DEF=%d" % [eff_atk, eff_def]
	var atk_up: bool = eff_atk > base_atk
	var def_up: bool = eff_def > base_def
	var mod_col: Color
	if atk_up and def_up:
		mod_col = Color(0.35, 1.0, 0.45)
	elif not atk_up and not def_up:
		mod_col = Color(1.0, 0.38, 0.38)
	else:
		mod_col = Color(1.0, 0.88, 0.35)
	_mod_label.add_theme_color_override("font_color", mod_col)
	_mod_label.visible = true


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
func _add_quantity_label(card_name: String, card_w: float, card_h: float) -> void:
	var count: int = Collection.get_card_count(card_name)
	var lbl := Label.new()
	lbl.text = "Owned: %d cop%s" % [count, ("ies" if count != 1 else "y")]
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.layout_mode = 1
	lbl.anchor_left   = 0.5;  lbl.anchor_right  = 0.5
	lbl.anchor_top    = 0.5;  lbl.anchor_bottom  = 0.5
	lbl.offset_left   = -card_w * 0.5
	lbl.offset_right  =  card_w * 0.5
	lbl.offset_top    = -card_h * 0.5 - 36.0
	lbl.offset_bottom = -card_h * 0.5 - 8.0
	lbl.mouse_filter  = MOUSE_FILTER_IGNORE
	add_child(lbl)

# ─────────────────────────────────────────────────────────────
# Gallery-only buttons (Sourcing + Pray) — right of card frame
# ─────────────────────────────────────────────────────────────
func _add_gallery_buttons(card_name: String, _card_type: String, card_w: float, card_h: float) -> void:
	var btn_w: float  = 160.0
	var btn_h: float  = 44.0
	var btn_x: float  = card_w * 0.5 + 12.0   # right of card
	var btn_y0: float = -card_h * 0.5 + 54.0  # below close button

	# ── Sourcing button ─────────────────────────────────────
	var src_btn := Button.new()
	src_btn.text = "Sourcing"
	src_btn.layout_mode = 1
	src_btn.anchor_left = 0.5; src_btn.anchor_right  = 0.5
	src_btn.anchor_top  = 0.5; src_btn.anchor_bottom = 0.5
	src_btn.offset_left   = btn_x
	src_btn.offset_top    = btn_y0
	src_btn.offset_right  = btn_x + btn_w
	src_btn.offset_bottom = btn_y0 + btn_h
	_style_gallery_btn(src_btn, Color(0.2, 0.5, 0.9))
	src_btn.pressed.connect(func() -> void: _show_sourcing_panel(card_name, src_btn))
	add_child(src_btn)

	# ── Pray button ─────────────────────────────────────────
	var pray_lbl := Label.new()  # result message, shown after praying
	pray_lbl.layout_mode = 1
	pray_lbl.anchor_left = 0.5; pray_lbl.anchor_right  = 0.5
	pray_lbl.anchor_top  = 0.5; pray_lbl.anchor_bottom = 0.5
	pray_lbl.offset_left   = btn_x
	pray_lbl.offset_top    = btn_y0 + btn_h + 8.0 + btn_h + 8.0
	pray_lbl.offset_right  = btn_x + btn_w
	pray_lbl.offset_bottom = btn_y0 + btn_h + 8.0 + btn_h + 8.0 + 40.0
	pray_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pray_lbl.add_theme_font_size_override("font_size", 13)
	pray_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	pray_lbl.visible = false
	pray_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(pray_lbl)

	var pray_btn := Button.new()
	pray_btn.layout_mode = 1
	pray_btn.anchor_left = 0.5; pray_btn.anchor_right  = 0.5
	pray_btn.anchor_top  = 0.5; pray_btn.anchor_bottom = 0.5
	pray_btn.offset_left   = btn_x
	pray_btn.offset_top    = btn_y0 + btn_h + 8.0
	pray_btn.offset_right  = btn_x + btn_w
	pray_btn.offset_bottom = btn_y0 + btn_h + 8.0 + btn_h
	_style_gallery_btn(pray_btn, Color(0.6, 0.25, 0.9))

	var incense_tex_path := "res://assets/textures/ui/decorations/ui_icon_incense.png"
	if ResourceLoader.exists(incense_tex_path):
		pray_btn.icon = load(incense_tex_path) as Texture2D

	var _update_pray_btn := func() -> void:
		var cnt: int = Collection.incenses
		pray_btn.visible = cnt > 0
		pray_btn.text = "Pray (%d)" % cnt
	_update_pray_btn.call()
	Collection.collection_changed.connect(_update_pray_btn)
	tree_exiting.connect(func() -> void:
		if Collection.collection_changed.is_connected(_update_pray_btn):
			Collection.collection_changed.disconnect(_update_pray_btn))

	pray_btn.pressed.connect(func() -> void:
		var boost: float = Collection.pray_for_card(card_name)
		if boost > 0.0:
			pray_lbl.text = "+%.0f%% boost applied!" % (boost * 100.0)
			pray_lbl.visible = true
		else:
			pray_lbl.text = "No incense."
			pray_lbl.visible = true)
	add_child(pray_btn)

func _show_sourcing_panel(card_name: String, anchor_btn: Button) -> void:
	# Remove existing sourcing panel if open
	for ch: Node in get_children():
		if ch.name == "SourcingPanel":
			ch.queue_free()
			return

	var packs: Array = ShopManager.get_packs_containing_card(card_name)

	var panel := PanelContainer.new()
	panel.name = "SourcingPanel"
	panel.z_index = 110
	panel.mouse_filter = MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color         = Color(0.05, 0.08, 0.18, 0.98)
	sb.border_color     = Color(0.3, 0.6, 1.0, 1.0)
	sb.border_width_left   = 2; sb.border_width_right  = 2
	sb.border_width_top    = 2; sb.border_width_bottom = 2
	sb.corner_radius_top_left     = 6; sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_left  = 6; sb.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Found in packs:"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
	vbox.add_child(title)

	if packs.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "Not in any pack pool."
		none_lbl.add_theme_font_size_override("font_size", 13)
		none_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
		vbox.add_child(none_lbl)
	else:
		var boost: float = Collection.get_card_boost(card_name)
		for entry: Dictionary in packs:
			var row_lbl := Label.new()
			var pct: float = float(entry.get("drop_chance", 0.0))
			var pname: String = str(entry.get("pack_name", ""))
			row_lbl.text = "%s  —  %.2f%%" % [pname, pct]
			row_lbl.add_theme_font_size_override("font_size", 13)
			if boost > 0.0:
				row_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
			else:
				row_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
			vbox.add_child(row_lbl)
		if boost > 0.0:
			var boost_lbl := Label.new()
			boost_lbl.text = "Incense boost: +%.0f%%" % (boost * 100.0)
			boost_lbl.add_theme_font_size_override("font_size", 12)
			boost_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			vbox.add_child(boost_lbl)

	# Position panel using viewport coordinates from the button's global position
	add_child(panel)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	# We need one frame for the panel to get its size, so use a deferred position
	var gpos: Vector2 = anchor_btn.global_position
	panel.position = gpos - global_position + Vector2(anchor_btn.size.x + 8.0, 0.0)

func _style_gallery_btn(btn: Button, accent: Color) -> void:
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus"]:
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = accent.darkened(0.45) if state == &"normal" else accent.darkened(0.2)
		bsb.border_color = accent
		bsb.border_width_left   = 2; bsb.border_width_right  = 2
		bsb.border_width_top    = 2; bsb.border_width_bottom = 2
		bsb.corner_radius_top_left     = 6; bsb.corner_radius_top_right    = 6
		bsb.corner_radius_bottom_left  = 6; bsb.corner_radius_bottom_right = 6
		bsb.content_margin_left = 8; bsb.content_margin_right = 8
		bsb.content_margin_top  = 4; bsb.content_margin_bottom = 4
		btn.add_theme_stylebox_override(state, bsb)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	btn.add_theme_font_size_override("font_size", 15)

func _add_bug_button(card_name: String, card_w: float, card_h: float) -> void:
	var bug_btn := Button.new()
	bug_btn.set_anchors_preset(Control.PRESET_CENTER)
	var cb_size := 38.0
	var btn_w   := 150.0
	var btn_h   := 34.0
	bug_btn.offset_left   = card_w * 0.5 + 8.0
	bug_btn.offset_top    = -card_h * 0.5 + cb_size + 10.0
	bug_btn.offset_right  = card_w * 0.5 + 8.0 + btn_w
	bug_btn.offset_bottom = -card_h * 0.5 + cb_size + 10.0 + btn_h
	bug_btn.add_theme_font_size_override("font_size", 14)
	_refresh_bug_btn(bug_btn, card_name)
	bug_btn.pressed.connect(func() -> void:
		_open_bug_input(card_name, bug_btn))
	add_child(bug_btn)

func _refresh_bug_btn(btn: Button, card_name: String) -> void:
	if SaveManager.is_bugged(card_name):
		btn.text = "🐛 EDIT BUG"
		btn.add_theme_color_override("font_color", Color(1.0, 0.70, 0.20))
	else:
		btn.text = "🐛 TAG BUG"
		btn.add_theme_color_override("font_color", Color(1.0, 0.50, 0.20))

func _open_bug_input(card_name: String, bug_btn: Button) -> void:
	# Remove any existing input panel
	var existing: Node = get_node_or_null("BugInputPanel")
	if existing:
		existing.queue_free()
		return

	var is_already_bugged: bool = SaveManager.is_bugged(card_name)
	var existing_msg: String    = SaveManager.get_bug_message(card_name)

	# Panel background
	var panel := PanelContainer.new()
	panel.name = "BugInputPanel"
	var psb := StyleBoxFlat.new()
	psb.bg_color          = Color(0.06, 0.06, 0.12, 0.97)
	psb.border_color      = Color(1.0, 0.55, 0.15, 0.85)
	psb.border_width_left = 2; psb.border_width_top    = 2
	psb.border_width_right= 2; psb.border_width_bottom = 2
	psb.corner_radius_top_left = 6; psb.corner_radius_top_right    = 6
	psb.corner_radius_bottom_right = 6; psb.corner_radius_bottom_left  = 6
	panel.add_theme_stylebox_override("panel", psb)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var pw: float = 360.0
	var ph: float = 130.0
	panel.offset_left   = -pw * 0.5
	panel.offset_top    = -ph * 0.5
	panel.offset_right  =  pw * 0.5
	panel.offset_bottom =  ph * 0.5
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top",   10)
	margin.add_theme_constant_override("margin_bottom",10)
	vbox.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	margin.add_child(inner)

	var title_lbl := Label.new()
	title_lbl.text = ("Edit bug note — %s" % card_name) if is_already_bugged \
		else ("Tag bug — %s" % card_name)
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.40))
	inner.add_child(title_lbl)

	var msg_edit := LineEdit.new()
	msg_edit.placeholder_text = "Short bug note…"
	msg_edit.text             = existing_msg
	msg_edit.custom_minimum_size = Vector2(0.0, 34.0)
	msg_edit.add_theme_font_size_override("font_size", 14)
	inner.add_child(msg_edit)
	msg_edit.grab_focus()

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	inner.add_child(btn_row)

	var submit_btn := Button.new()
	submit_btn.text = "✓ SUBMIT" if not is_already_bugged else "✓ UPDATE"
	submit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit_btn.add_theme_font_size_override("font_size", 13)
	submit_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
	btn_row.add_child(submit_btn)

	var resolve_row_btn: Button = null
	if is_already_bugged:
		resolve_row_btn = Button.new()
		resolve_row_btn.text = "✗ RESOLVE"
		resolve_row_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		resolve_row_btn.add_theme_font_size_override("font_size", 13)
		resolve_row_btn.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
		btn_row.add_child(resolve_row_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_size_override("font_size", 13)
	btn_row.add_child(cancel_btn)

	# Callbacks
	var do_submit := func() -> void:
		SaveManager.tag_bug(card_name, msg_edit.text.strip_edges())
		_refresh_bug_btn(bug_btn, card_name)
		panel.queue_free()

	var do_resolve := func() -> void:
		SaveManager.resolve_bug(card_name)
		_refresh_bug_btn(bug_btn, card_name)
		panel.queue_free()

	submit_btn.pressed.connect(do_submit)
	msg_edit.text_submitted.connect(func(_t: String) -> void: do_submit.call())
	cancel_btn.pressed.connect(panel.queue_free)
	if resolve_row_btn:
		resolve_row_btn.pressed.connect(do_resolve)

func _close() -> void:
	AudioManager.tts_stop()
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
