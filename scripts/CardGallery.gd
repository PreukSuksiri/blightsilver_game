extends Control

signal closed()

const FULL_CARDS_DIR := "res://assets/textures/cards/full_cards/"

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
	_build_adv_gallery_filters()
	_build_all_cards()

# ─────────────────────────────────────────────────────────────
# Filter bar
# ─────────────────────────────────────────────────────────────
func _build_filter_bar() -> void:
	var defs: Array = [
		["all",       "ALL"],
		["character", "CHARACTERS"],
		["trap",      "TRAPS"],
		["tech",      "TECH"],
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
			"desc": data.get_ability_description()})

	var trap_names: Array = CardDatabase.get_all_trap_names()
	trap_names.sort()
	for tname: String in trap_names:
		var data: TrapData = CardDatabase.get_trap(tname)
		var tile := _make_trap_tile(data)
		card_flow.add_child(tile)
		_tiles.append({"node": tile, "card_name": tname, "card_type": "trap",
			"affinity": -1, "cost": data.crystal_cost,
			"atk": -1, "def": -1,
			"desc": data.get_effect_description()})

	var tech_names: Array = CardDatabase.get_all_tech_names()
	tech_names.sort()
	for ename: String in tech_names:
		var data: TechCardData = CardDatabase.get_tech(ename)
		var tile := _make_tech_tile(data)
		card_flow.add_child(tile)
		_tiles.append({"node": tile, "card_name": ename, "card_type": "tech",
			"affinity": -1, "cost": data.crystal_cost,
			"atk": -1, "def": -1,
			"desc": data.get_effect_description()})

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

	var badge := Label.new()
	badge.text = "×%d" % count
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color",
		Color(0.20, 1.0, 0.55, 1.0) if count > 0 else Color(0.5, 0.5, 0.55, 0.6))
	badge.layout_mode = 1
	badge.anchor_left   = 1.0; badge.anchor_right  = 1.0
	badge.anchor_top    = 1.0; badge.anchor_bottom = 1.0
	badge.offset_left   = -34.0; badge.offset_right  = -2.0
	badge.offset_top    = -16.0; badge.offset_bottom = -2.0
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(badge)

	# Tooltip hint
	wrapper.tooltip_text = card_name

	# Click: forward card_clicked signal from card.tscn, or connect to card_node
	# (wrapper.gui_input is never reached because card_node has MOUSE_FILTER_STOP)
	if card_node.has_signal("card_clicked"):
		card_node.card_clicked.connect(
			func(_n: Control) -> void: CardDetailOverlay.open(self, card_name, card_type))
	else:
		card_node.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed \
					and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				CardDetailOverlay.open(self, card_name, card_type)
			elif ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed:
				CardDetailOverlay.open(self, card_name, card_type))

	return wrapper

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
		var bg := ColorRect.new()
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0.05, 0.06, 0.14, 1.0)
		tile.add_child(bg)
		var lbl := Label.new()
		lbl.text = card_name
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75, 0.8))
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
		nsfw_path = FULL_CARDS_DIR + card_type + "_" + snake + "_nsfw.png"
		if ResourceLoader.exists(nsfw_path):
			return load(nsfw_path) as Texture2D
	var path: String = FULL_CARDS_DIR + snake + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	path = FULL_CARDS_DIR + card_type + "_" + snake + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


# ─────────────────────────────────────────────────────────────
# Collection refresh
# ─────────────────────────────────────────────────────────────
func _on_collection_changed() -> void:
	_build_all_cards()

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
