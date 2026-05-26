extends Control

signal closed()

const FULL_CARDS_DIR := "res://assets/textures/cards/full_cards/"

# Credits earned per scrapped duplicate copy, by rarity
const SCRAP_VALUES: Dictionary = {
	CharacterData.Rarity.COMMON:    50,
	CharacterData.Rarity.UNCOMMON:  100,
	CharacterData.Rarity.RARE:      250,
	CharacterData.Rarity.LEGENDARY: 600,
	CharacterData.Rarity.EXOTIC:    1500,
}

# ── Affinity accent colours (mirrors Card.gd) ─────────────────
const AFFINITY_COLORS: Dictionary = {
	CharacterData.Affinity.DIVINE:  Color(1.00, 0.90, 0.30),
	CharacterData.Affinity.CHAOS:   Color(0.55, 0.05, 0.75),
	CharacterData.Affinity.NATURE:  Color(0.20, 0.80, 0.20),
	CharacterData.Affinity.ARCANE:  Color(0.15, 0.50, 1.00),
	CharacterData.Affinity.COSMIC:  Color(0.00, 0.90, 0.90),
	CharacterData.Affinity.BIO:     Color(0.55, 0.95, 0.10),
	CharacterData.Affinity.ANIMA:   Color(0.95, 0.40, 0.10),
}
const TECH_ACCENT := Color(0.38, 0.65, 1.0)
const TRAP_ACCENT := Color(1.0,  0.30, 0.30)

@onready var stats_label: Label              = $Panel/VBox/Header/StatsLabel
@onready var header_bar: HBoxContainer       = $Panel/VBox/Header
@onready var filter_bar: HBoxContainer       = $Panel/VBox/FilterBar
@onready var card_scroll: ScrollContainer    = $Panel/VBox/CardScroll
@onready var card_flow: HFlowContainer       = $Panel/VBox/CardScroll/CardFlow
@onready var gallery_vbox: VBoxContainer     = $Panel/VBox


# Per-tile metadata for filter/search
var _tiles: Array = []           # [{node, card_name, card_type, affinity, cost, atk, def, desc}, ...]
var _active_filter: String = "all"
var _search_text: String = ""
var _filter_btns: Dictionary = {}

# Advanced filter state
var _filter_affinity: int  = -1
var _filter_cost_min: int  = 0
var _filter_cost_max: int  = 9999
var _filter_atk_min:  int  = 0
var _filter_atk_max:  int  = 9999
var _filter_def_min:  int  = 0
var _filter_def_max:  int  = 9999
var _filter_ability:  String = ""

# Count filter state
var _filter_count: String = "all"   # "all" | "owned" | "unowned"
var _count_filter_btns: Dictionary = {}

# Advanced filter control refs
var _adv_affinity_btn: OptionButton
var _adv_cost_min:  SpinBox
var _adv_cost_max:  SpinBox
var _adv_atk_min:   SpinBox
var _adv_atk_max:   SpinBox
var _adv_def_min:   SpinBox
var _adv_def_max:   SpinBox
var _adv_ability:   LineEdit

func _ready() -> void:
	Collection.collection_changed.connect(_on_collection_changed)
	$Panel/VBox/Header/CloseBtn.pressed.connect(_on_close)
	_build_filter_bar()
	_build_count_filter_row()
	_build_adv_gallery_filters()
	_build_all_cards()
	_add_scrap_all_button()
	# Apply initial union mechanism visibility and subscribe to changes
	_on_union_mechanism_changed(SaveManager.union_mechanism_unlocked)
	SaveManager.union_mechanism_changed.connect(_on_union_mechanism_changed)

# ─────────────────────────────────────────────────────────────
# Filter bar
# ─────────────────────────────────────────────────────────────
func _build_filter_bar() -> void:
	var defs: Array = [
		["all",       "ALL"],
		["character", "CHARACTERS"],
		["trap",      "TRAPS"],
		["tech",      "TECH"],
		["union",     "UNION"],
	]
	for d: Array in defs:
		var btn := Button.new()
		btn.text = d[1]
		btn.toggle_mode = true
		btn.button_pressed = (d[0] == "all")
		btn.custom_minimum_size = Vector2(110, 32)
		btn.add_theme_font_size_override("font_size", 13)
		var fid: String = d[0]
		btn.pressed.connect(func() -> void: _set_filter(fid))
		filter_bar.add_child(btn)
		_filter_btns[d[0]] = btn

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_bar.add_child(spacer)

	var search := LineEdit.new()
	search.placeholder_text = "Search by name..."
	search.custom_minimum_size = Vector2(200, 32)
	search.add_theme_font_size_override("font_size", 13)
	search.text_changed.connect(func(t: String) -> void:
		_search_text = t
		_apply_filter())
	filter_bar.add_child(search)

func _build_count_filter_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = "QTY:"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.80))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var defs: Array = [["all", "ALL"], ["owned", "OWNED"], ["unowned", "NOT OWNED"]]
	for d: Array in defs:
		var btn := Button.new()
		btn.text = d[1]
		btn.toggle_mode = true
		btn.button_pressed = (d[0] == "all")
		btn.add_theme_font_size_override("font_size", 12)
		btn.custom_minimum_size = Vector2(80, 26)
		var cid: String = d[0]
		btn.pressed.connect(func() -> void:
			_filter_count = cid
			for k: String in _count_filter_btns:
				_count_filter_btns[k].button_pressed = (k == cid)
			_apply_filter())
		_count_filter_btns[d[0]] = btn
		row.add_child(btn)

	gallery_vbox.add_child(row)
	gallery_vbox.move_child(row, filter_bar.get_index() + 1)

func _set_filter(fid: String) -> void:
	_active_filter = fid
	for k: String in _filter_btns:
		_filter_btns[k].button_pressed = (k == fid)
	_apply_filter()

func _apply_filter() -> void:
	var use_aff: bool = _filter_affinity >= 0
	var use_atk: bool = _filter_atk_min > 0 or _filter_atk_max < 9999
	var use_def: bool = _filter_def_min > 0 or _filter_def_max < 9999
	var abil_q:  String = _filter_ability.to_lower()

	for entry: Dictionary in _tiles:
		if not is_instance_valid(entry["node"]):
			continue
		# Hide union tiles entirely when mechanism is locked
		if entry["card_type"] == "union" and not SaveManager.union_mechanism_unlocked:
			entry["node"].visible = false
			continue
		# In demo mode, hide cards not flagged for demo
		if SaveManager.demo_mode and not entry.get("include_in_demo", false):
			entry["node"].visible = false
			continue
		var show: bool = _active_filter == "all" or entry["card_type"] == _active_filter
		if show and _search_text != "":
			show = entry["card_name"].to_lower().find(_search_text.to_lower()) >= 0
		if show and use_aff:
			show = entry["affinity"] == _filter_affinity
		if show and (entry["cost"] < _filter_cost_min or entry["cost"] > _filter_cost_max):
			show = false
		if show and use_atk:
			show = entry["atk"] >= 0 and entry["atk"] >= _filter_atk_min and entry["atk"] <= _filter_atk_max
		if show and use_def:
			show = entry["def"] >= 0 and entry["def"] >= _filter_def_min and entry["def"] <= _filter_def_max
		if show and abil_q != "":
			show = entry["desc"].to_lower().find(abil_q) >= 0
		if show and _filter_count != "all":
			var cnt: int = Collection.get_card_count(entry["card_name"])
			if _filter_count == "owned":
				show = cnt > 0
			elif _filter_count == "unowned":
				show = cnt == 0
		entry["node"].visible = show
	_update_stats()

func _update_stats() -> void:
	var total := 0
	var owned := 0
	for entry: Dictionary in _tiles:
		if not is_instance_valid(entry["node"]) or not entry["node"].visible:
			continue
		total += 1
		if Collection.has_card(entry["card_name"]):
			owned += 1
	stats_label.text = "%d / %d collected" % [owned, total]

# ─────────────────────────────────────────────────────────────
# Build all card tiles
# ─────────────────────────────────────────────────────────────
func _build_all_cards() -> void:
	for child in card_flow.get_children():
		child.queue_free()
	_tiles.clear()

	var char_names: Array = CardDatabase.get_all_character_names()
	char_names.sort()
	for cname: String in char_names:
		var data: CharacterData = CardDatabase.get_character(cname)
		var tile := _make_char_tile(data)
		card_flow.add_child(tile)
		_tiles.append({"node": tile, "card_name": cname, "card_type": "character",
			"affinity": data.affinity, "cost": data.crystal_cost,
			"atk": data.base_atk, "def": data.base_def,
			"desc": data.get_ability_description(),
			"include_in_demo": data.include_in_demo})

	var trap_names: Array = CardDatabase.get_all_trap_names()
	trap_names.sort()
	for tname: String in trap_names:
		var data: TrapData = CardDatabase.get_trap(tname)
		var tile := _make_trap_tile(data)
		card_flow.add_child(tile)
		_tiles.append({"node": tile, "card_name": tname, "card_type": "trap",
			"affinity": -1, "cost": data.crystal_cost,
			"atk": -1, "def": -1,
			"desc": data.get_effect_description(),
			"include_in_demo": data.include_in_demo})

	var tech_names: Array = CardDatabase.get_all_tech_names()
	tech_names.sort()
	for ename: String in tech_names:
		var data: TechCardData = CardDatabase.get_tech(ename)
		var tile := _make_tech_tile(data)
		card_flow.add_child(tile)
		_tiles.append({"node": tile, "card_name": ename, "card_type": "tech",
			"affinity": -1, "cost": data.crystal_cost,
			"atk": -1, "def": -1,
			"desc": data.get_effect_description(),
			"include_in_demo": data.include_in_demo})

	var union_list: Array = UnionDatabase.get_all_unions()
	union_list.sort_custom(func(a: UnionData, b: UnionData) -> bool: return a.card_name < b.card_name)
	for u: UnionData in union_list:
		var tile := _make_union_tile(u)
		card_flow.add_child(tile)
		var is_unlocked: bool = SaveManager.is_union_unlocked(u.card_name)
		_tiles.append({"node": tile, "card_name": u.card_name, "card_type": "union",
			"affinity": int(u.affinity), "cost": u.summon_cost,
			"atk": u.base_atk, "def": u.base_def,
			"desc": u.ability_description if is_unlocked else u.partial_ability_description})

	_apply_filter()

# ─────────────────────────────────────────────────────────────
# Tile constructors
# ─────────────────────────────────────────────────────────────
func _wrap_card_tile(card_node: Control, card_name: String, card_type: String) -> Control:
	# Wrapper so our grey modulate doesn't get overridden by Card.gd's _apply_rarity
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(110, 150)
	card_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(card_node)

	var count: int = Collection.get_card_count(card_name)

	if count == 0:
		wrapper.modulate = Color(0.60, 0.60, 0.68, 1.0)

	var badge := Label.new()
	badge.text = "×%d" % count
	var _badge_font := FontVariation.new()
	_badge_font.base_font = preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")
	_badge_font.variation_opentype = {"wght": 1200}
	badge.add_theme_font_override("font", _badge_font)
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color",
		Color(1.0, 1.0, 1.0, 1.0) if count > 0 else Color(1.0, 1.0, 1.0, 1.0))
	badge.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	badge.add_theme_constant_override("shadow_offset_x", 1)
	badge.add_theme_constant_override("shadow_offset_y", 1)
	badge.layout_mode = 1
	badge.anchor_left   = 0.0; badge.anchor_right  = 1.0
	badge.anchor_top    = 0.0; badge.anchor_bottom = 0.0
	badge.offset_left   = 0.0;  badge.offset_right  = 0.0
	badge.offset_top    = 2.0; badge.offset_bottom = 18.0
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment   = VERTICAL_ALIGNMENT_TOP
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(badge)

	# Scrap-one button: shown only for non-union cards with >1 copy
	if card_type != "union" and count > 1:
		var scrap_btn := Button.new()
		scrap_btn.text = "✂"
		scrap_btn.tooltip_text = "Scrap duplicates (keep 1)"
		scrap_btn.add_theme_font_size_override("font_size", 10)
		scrap_btn.layout_mode = 1
		scrap_btn.anchor_left   = 0.0; scrap_btn.anchor_right  = 0.0
		scrap_btn.anchor_top    = 1.0; scrap_btn.anchor_bottom = 1.0
		scrap_btn.offset_left   = 2.0;  scrap_btn.offset_right  = 22.0
		scrap_btn.offset_top    = -18.0; scrap_btn.offset_bottom = -2.0
		var cap_name: String = card_name
		var cap_type: String = card_type
		scrap_btn.pressed.connect(func() -> void: _confirm_scrap_one(cap_name, cap_type))
		wrapper.add_child(scrap_btn)

	# Tooltip hint
	wrapper.tooltip_text = card_name

	# Click: forward card_clicked signal from card.tscn, or connect to card_node
	# (wrapper.gui_input is never reached because card_node has MOUSE_FILTER_STOP)
	if card_node.has_signal("card_clicked"):
		card_node.card_clicked.connect(
			func(_n: Control) -> void:
				SFXManager.play(SFXManager.SFX_CARD_INFO)
				CardDetailOverlay.open(self, card_name, card_type, null, true))
	else:
		card_node.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed \
					and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				SFXManager.play(SFXManager.SFX_CARD_INFO)
				CardDetailOverlay.open(self, card_name, card_type)
			elif ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed:
				SFXManager.play(SFXManager.SFX_CARD_INFO)
				CardDetailOverlay.open(self, card_name, card_type, null, true))

	return wrapper

func _make_union_tile(u: UnionData) -> Control:
	return _make_simple_tile(u.card_name, "union")

func _make_char_tile(data: CharacterData) -> Control:
	return _make_simple_tile(data.card_name, "character")

func _make_trap_tile(data: TrapData) -> Control:
	return _make_simple_tile(data.card_name, "trap")

func _make_tech_tile(data: TechCardData) -> Control:
	return _make_simple_tile(data.card_name, "tech")

func _make_simple_tile(card_name: String, card_type: String) -> Control:
	var tile := Control.new()
	tile.custom_minimum_size = Vector2(110, 150)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP

	var tex: Texture2D = _load_full_card_tex(card_name, card_type)
	if tex != null:
		var art := TextureRect.new()
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.texture = tex
		tile.add_child(art)
	else:
		var is_union: bool = card_type == "union"
		var bg := ColorRect.new()
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0.04, 0.14, 0.20, 1.0) if is_union else Color(0.05, 0.06, 0.14, 1.0)
		tile.add_child(bg)
		if is_union:
			var icon_lbl := Label.new()
			icon_lbl.text = "⊕"
			icon_lbl.layout_mode = 1
			icon_lbl.anchor_left = 0.0; icon_lbl.anchor_right  = 1.0
			icon_lbl.anchor_top  = 0.1; icon_lbl.anchor_bottom = 0.55
			icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			icon_lbl.add_theme_font_size_override("font_size", 36)
			icon_lbl.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0, 0.45))
			icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.add_child(icon_lbl)
		var lbl := Label.new()
		lbl.text = card_name
		lbl.layout_mode = 1
		lbl.anchor_left = 0.0; lbl.anchor_right  = 1.0
		lbl.anchor_top  = 0.55; lbl.anchor_bottom = 1.0
		lbl.offset_left = 4.0; lbl.offset_right = -4.0; lbl.offset_bottom = -4.0
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color",
			Color(0.25, 0.90, 1.0) if is_union else Color(0.55, 0.65, 0.75, 0.8))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(lbl)

	return _wrap_card_tile(tile, card_name, card_type)

func _load_full_card_tex(card_name: String, card_type: String) -> Texture2D:
	var snake: String = card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
	if SaveManager.nsfw_enabled:
		var nsfw_path: String = FULL_CARDS_DIR + snake + "_nsfw.png"
		if ResourceLoader.exists(nsfw_path):
			return load(nsfw_path) as Texture2D
	var path: String = FULL_CARDS_DIR + snake + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


# ─────────────────────────────────────────────────────────────
# Collection refresh
# ─────────────────────────────────────────────────────────────
func _on_collection_changed() -> void:
	_build_all_cards()
	_on_union_mechanism_changed(SaveManager.union_mechanism_unlocked)

func _on_union_mechanism_changed(unlocked: bool) -> void:
	if _filter_btns.has("union"):
		_filter_btns["union"].visible = unlocked
	if not unlocked and _active_filter == "union":
		_set_filter("all")
		return
	_apply_filter()

# ─────────────────────────────────────────────────────────────
# Close
# ─────────────────────────────────────────────────────────────
func _on_close() -> void:
	emit_signal("closed")
	queue_free()

func _build_adv_gallery_filters() -> void:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 3)

	var toggle_btn := Button.new()
	toggle_btn.text = "▶  Advanced Filters"
	toggle_btn.toggle_mode = true
	toggle_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle_btn.add_theme_font_size_override("font_size", 13)
	toggle_btn.add_theme_color_override("font_color", Color(0.45, 0.72, 1.0))
	outer.add_child(toggle_btn)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	body.visible = false
	toggle_btn.toggled.connect(func(on: bool) -> void:
		body.visible = on
		toggle_btn.text = ("▼  Advanced Filters" if on else "▶  Advanced Filters"))

	# Affinity
	var aff_row := HBoxContainer.new()
	aff_row.add_theme_constant_override("separation", 6)
	var aff_lbl := Label.new()
	aff_lbl.text = "Affinity"
	aff_lbl.custom_minimum_size = Vector2(58, 0)
	aff_lbl.add_theme_font_size_override("font_size", 13)
	aff_row.add_child(aff_lbl)
	_adv_affinity_btn = OptionButton.new()
	_adv_affinity_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_adv_affinity_btn.add_theme_font_size_override("font_size", 13)
	_adv_affinity_btn.add_item("Any")
	for aff: String in ["Divine", "Chaos", "Nature", "Arcane", "Cosmic", "Bio", "Anima"]:
		_adv_affinity_btn.add_item(aff)
	aff_row.add_child(_adv_affinity_btn)
	body.add_child(aff_row)

	var cost_range := _gallery_range_row(body, "Cost", 0, 9999, 9999)
	_adv_cost_min = cost_range[0];  _adv_cost_max = cost_range[1]
	var atk_range  := _gallery_range_row(body, "ATK",  0, 9999, 9999)
	_adv_atk_min  = atk_range[0];  _adv_atk_max  = atk_range[1]
	var def_range  := _gallery_range_row(body, "DEF",  0, 9999, 9999)
	_adv_def_min  = def_range[0];  _adv_def_max  = def_range[1]

	var abil_row := HBoxContainer.new()
	abil_row.add_theme_constant_override("separation", 6)
	var abil_lbl := Label.new()
	abil_lbl.text = "Ability"
	abil_lbl.custom_minimum_size = Vector2(58, 0)
	abil_lbl.add_theme_font_size_override("font_size", 13)
	abil_row.add_child(abil_lbl)
	_adv_ability = LineEdit.new()
	_adv_ability.placeholder_text = "contains..."
	_adv_ability.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_adv_ability.add_theme_font_size_override("font_size", 13)
	_adv_ability.text_changed.connect(func(t: String) -> void: _filter_ability = t)
	abil_row.add_child(_adv_ability)
	body.add_child(abil_row)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	var apply_btn := Button.new()
	apply_btn.text = "Apply Filter"
	apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_btn.add_theme_font_size_override("font_size", 13)
	apply_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	apply_btn.pressed.connect(_apply_adv_gallery)
	btn_row.add_child(apply_btn)
	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.add_theme_font_size_override("font_size", 13)
	clear_btn.pressed.connect(_clear_adv_gallery)
	btn_row.add_child(clear_btn)
	body.add_child(btn_row)

	outer.add_child(body)
	gallery_vbox.add_child(outer)
	gallery_vbox.move_child(outer, filter_bar.get_index() + 1)

func _gallery_range_row(parent: VBoxContainer, lbl_text: String,
		spin_min: int, spin_max: int, default_max: int) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var lbl := Label.new()
	lbl.text = lbl_text
	lbl.custom_minimum_size = Vector2(58, 0)
	lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(lbl)
	var s_min := SpinBox.new()
	s_min.min_value = spin_min;  s_min.max_value = spin_max;  s_min.value = spin_min
	s_min.size_flags_horizontal = Control.SIZE_EXPAND_FILL;  s_min.suffix = "min"
	row.add_child(s_min)
	var s_max := SpinBox.new()
	s_max.min_value = spin_min;  s_max.max_value = spin_max;  s_max.value = default_max
	s_max.size_flags_horizontal = Control.SIZE_EXPAND_FILL;  s_max.suffix = "max"
	row.add_child(s_max)
	parent.add_child(row)
	return [s_min, s_max]

func _apply_adv_gallery() -> void:
	_filter_affinity = _adv_affinity_btn.selected - 1
	_filter_cost_min = int(_adv_cost_min.value)
	_filter_cost_max = int(_adv_cost_max.value)
	_filter_atk_min  = int(_adv_atk_min.value)
	_filter_atk_max  = int(_adv_atk_max.value)
	_filter_def_min  = int(_adv_def_min.value)
	_filter_def_max  = int(_adv_def_max.value)
	_apply_filter()

func _clear_adv_gallery() -> void:
	_adv_affinity_btn.selected = 0
	_adv_cost_min.value = 0;  _adv_cost_max.value = 9999
	_adv_atk_min.value  = 0;  _adv_atk_max.value  = 9999
	_adv_def_min.value  = 0;  _adv_def_max.value  = 9999
	_adv_ability.text   = ""
	_filter_affinity = -1
	_filter_cost_min = 0;  _filter_cost_max = 9999
	_filter_atk_min  = 0;  _filter_atk_max  = 9999
	_filter_def_min  = 0;  _filter_def_max  = 9999
	_filter_ability  = ""
	_apply_filter()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		AudioManager.tts_stop()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_close()

# ─────────────────────────────────────────────────────────────
# Scrap duplicates
# ─────────────────────────────────────────────────────────────

func _add_scrap_all_button() -> void:
	var btn := Button.new()
	btn.text = "✂ SCRAP ALL DUPES"
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.20))
	btn.tooltip_text = "Scrap all duplicate copies, keeping 1 of each card"
	btn.pressed.connect(_confirm_scrap_all)
	# Insert before the CloseBtn
	var close_btn: Node = $Panel/VBox/Header/CloseBtn
	header_bar.add_child(btn)
	header_bar.move_child(btn, close_btn.get_index())

func _get_scrap_value(card_name: String, card_type: String) -> int:
	var rarity: CharacterData.Rarity = CharacterData.Rarity.COMMON
	if card_type == "character":
		var cd: CharacterData = CardDatabase.get_character(card_name)
		if cd != null:
			rarity = cd.rarity
	elif card_type == "trap":
		var td: TrapData = CardDatabase.get_trap(card_name)
		if td != null:
			rarity = td.rarity
	elif card_type == "tech":
		var ed: TechCardData = CardDatabase.get_tech(card_name)
		if ed != null:
			rarity = ed.rarity
	return SCRAP_VALUES.get(rarity, 50)

func _calc_scrap_one_credits(card_name: String, card_type: String) -> int:
	var extras: int = Collection.get_card_count(card_name) - 1
	if extras <= 0:
		return 0
	return extras * _get_scrap_value(card_name, card_type)

func _calc_scrap_all_credits() -> int:
	var total: int = 0
	for entry: Dictionary in _tiles:
		var cname: String = entry["card_name"]
		var ctype: String = entry["card_type"]
		if ctype == "union":
			continue
		var extras: int = Collection.get_card_count(cname) - 1
		if extras > 0:
			total += extras * _get_scrap_value(cname, ctype)
	return total

func _confirm_scrap_one(card_name: String, card_type: String) -> void:
	var extras: int = Collection.get_card_count(card_name) - 1
	if extras <= 0:
		return
	var credits_gained: int = extras * _get_scrap_value(card_name, card_type)
	var dlg := ConfirmationDialog.new()
	dlg.title = "Scrap Duplicates"
	dlg.dialog_text = "Scrap %d extra cop%s of \"%s\"?\nYou will receive %d credits." % [
		extras, ("ies" if extras > 1 else "y"), card_name, credits_gained]
	dlg.confirmed.connect(func() -> void:
		Collection.scrap_duplicates(card_name)
		Collection.add_credits(credits_gained)
		dlg.queue_free())
	dlg.canceled.connect(func() -> void: dlg.queue_free())
	add_child(dlg)
	dlg.popup_centered()

func _confirm_scrap_all() -> void:
	var credits_gained: int = _calc_scrap_all_credits()
	if credits_gained == 0:
		var dlg := AcceptDialog.new()
		dlg.title = "Nothing to Scrap"
		dlg.dialog_text = "You have no duplicate cards."
		dlg.confirmed.connect(func() -> void: dlg.queue_free())
		add_child(dlg)
		dlg.popup_centered()
		return
	var dlg := ConfirmationDialog.new()
	dlg.title = "Scrap All Duplicates"
	dlg.dialog_text = "Scrap all duplicate copies across your entire collection?\nYou will receive %d credits." % credits_gained
	dlg.confirmed.connect(func() -> void:
		Collection.scrap_all_duplicates()
		Collection.add_credits(credits_gained)
		dlg.queue_free())
	dlg.canceled.connect(func() -> void: dlg.queue_free())
	add_child(dlg)
	dlg.popup_centered()
