extends Control

signal closed

const DeckData = preload("res://resources/DeckData.gd")

# ── Scene node refs ───────────────────────────────────────────
@onready var deck_name_field:   LineEdit    = $MainLayout/RightPanel/Inner/TopBar/DeckNameField
@onready var deck_select:       OptionButton = $MainLayout/RightPanel/Inner/TopBar/DeckSelect
@onready var new_deck_btn:      Button      = $MainLayout/RightPanel/Inner/TopBar/NewDeckBtn
@onready var delete_deck_btn:   Button      = $MainLayout/RightPanel/Inner/TopBar/DeleteDeckBtn
@onready var duplicate_btn:     Button      = $MainLayout/RightPanel/Inner/TopBar/DuplicateBtn

@onready var filter_all:        Button      = $MainLayout/LeftPanel/Inner/FilterBar/FilterAll
@onready var filter_char:       Button      = $MainLayout/LeftPanel/Inner/FilterBar/FilterChar
@onready var filter_trap:       Button      = $MainLayout/LeftPanel/Inner/FilterBar/FilterTrap
@onready var filter_tech:       Button      = $MainLayout/LeftPanel/Inner/FilterBar/FilterTech
@onready var search_field:      LineEdit    = $MainLayout/LeftPanel/Inner/SearchField
@onready var trunk_list:        ItemList    = $MainLayout/LeftPanel/Inner/TrunkList
@onready var trunk_add_btn:     Button      = $MainLayout/LeftPanel/Inner/AddBtn
@onready var preview_card_area:  Control     = $MainLayout/LeftPanel/Inner/PreviewBox/PreviewCardArea
@onready var preview_bg:         ColorRect   = $MainLayout/LeftPanel/Inner/PreviewBox/PreviewCardArea/PreviewBG
@onready var preview_art:        TextureRect = $MainLayout/LeftPanel/Inner/PreviewBox/PreviewCardArea/PreviewArt
@onready var preview_info_strip: ColorRect   = $MainLayout/LeftPanel/Inner/PreviewBox/PreviewCardArea/PreviewInfoStrip
@onready var preview_frame:      TextureRect = $MainLayout/LeftPanel/Inner/PreviewBox/PreviewCardArea/PreviewFrame
@onready var preview_name:       Label       = $MainLayout/LeftPanel/Inner/PreviewBox/TextBox/PreviewName
@onready var preview_stats:      Label       = $MainLayout/LeftPanel/Inner/PreviewBox/TextBox/PreviewStats
@onready var preview_desc:       Label       = $MainLayout/LeftPanel/Inner/PreviewBox/TextBox/PreviewDesc
@onready var view_full_card_btn: Button      = $MainLayout/LeftPanel/Inner/PreviewBox/TextBox/ViewFullCardBtn


@onready var left_inner:        VBoxContainer = $MainLayout/LeftPanel/Inner
@onready var filter_bar:        HBoxContainer = $MainLayout/LeftPanel/Inner/FilterBar

@onready var char_list:         ItemList    = $MainLayout/RightPanel/Inner/CharSection/CharList
@onready var trap_list:         ItemList    = $MainLayout/RightPanel/Inner/TrapSection/TrapList
@onready var tech_list:         ItemList    = $MainLayout/RightPanel/Inner/TechSection/TechList
@onready var char_count_label:  Label       = $MainLayout/RightPanel/Inner/CharSection/CharHeaderRow/CharCountLabel
@onready var trap_count_label:  Label       = $MainLayout/RightPanel/Inner/TrapSection/TrapHeaderRow/TrapCountLabel
@onready var tech_count_label:  Label       = $MainLayout/RightPanel/Inner/TechSection/TechHeaderRow/TechCountLabel
@onready var blank_count_label: Label       = $MainLayout/RightPanel/Inner/DeadEndRow/DeadEndLabel
@onready var status_label:      Label       = $MainLayout/RightPanel/Inner/StatusLabel
@onready var save_btn:          Button      = $MainLayout/RightPanel/Inner/BottomBar/SaveBtn
@onready var back_btn:          Button      = $MainLayout/RightPanel/Inner/BottomBar/BackBtn
@onready var remove_char_btn:   Button      = $MainLayout/RightPanel/Inner/CharSection/RemoveBtn
@onready var remove_trap_btn:   Button      = $MainLayout/RightPanel/Inner/TrapSection/RemoveBtn
@onready var remove_tech_btn:   Button      = $MainLayout/RightPanel/Inner/TechSection/RemoveBtn

# ── State ─────────────────────────────────────────────────────
var current_deck: DeckData = null
var _filter: String = "all"   # "all" | "character" | "trap" | "tech"
var _preview_card_type: String = ""
var _preview_card_name: String = ""

# Advanced filter state
var _filter_affinity: int  = -1   # -1 = any
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

const _ROUNDED_CLIP: Shader = preload("res://assets/shaders/rounded_clip.gdshader")
const FULL_CARDS_DIR := "res://assets/textures/cards/full_cards/"

# Gallery view state
var _gallery_mode: bool = true
var _trunk_gallery_scroll: ScrollContainer = null
var _trunk_gallery_flow:   HFlowContainer  = null
var _deck_chars_scroll_gal: ScrollContainer = null
var _deck_traps_scroll_gal: ScrollContainer = null
var _deck_tech_scroll_gal:  ScrollContainer = null
var _deck_chars_flow: HFlowContainer = null
var _deck_traps_flow: HFlowContainer = null
var _deck_tech_flow:  HFlowContainer = null
var _view_toggle_btn: Button = null
var _gallery_selected_name: String = ""
var _gallery_selected_type: String = ""

func _ready() -> void:
	_connect_buttons()
	_refresh_deck_select()
	_load_deck(SaveManager.active_deck_index)

	var rc_mat := ShaderMaterial.new()
	rc_mat.shader = _ROUNDED_CLIP
	rc_mat.set_shader_parameter("corner_radius", 8.0)
	preview_card_area.material = rc_mat
	preview_card_area.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW

	_build_advanced_filters()
	_update_filter_colors()
	_setup_gallery_containers()

# ── Button wiring ─────────────────────────────────────────────
func _connect_buttons() -> void:
	filter_all.pressed.connect(func(): _set_filter("all"))
	filter_char.pressed.connect(func(): _set_filter("character"))
	filter_trap.pressed.connect(func(): _set_filter("trap"))
	filter_tech.pressed.connect(func(): _set_filter("tech"))
	search_field.text_changed.connect(func(_t): _rebuild_trunk_list())
	trunk_list.item_activated.connect(_on_trunk_double_click)
	trunk_list.item_selected.connect(_on_trunk_selected)
	trunk_add_btn.pressed.connect(_on_add_btn)
	char_list.item_selected.connect(_on_char_list_selected)
	trap_list.item_selected.connect(_on_trap_list_selected)
	tech_list.item_selected.connect(_on_tech_list_selected)
	remove_char_btn.pressed.connect(_on_remove_char)
	remove_trap_btn.pressed.connect(_on_remove_trap)
	remove_tech_btn.pressed.connect(_on_remove_tech)
	deck_select.item_selected.connect(_on_deck_selected)
	new_deck_btn.pressed.connect(_on_new_deck)
	delete_deck_btn.pressed.connect(_on_delete_deck)
	duplicate_btn.pressed.connect(_on_duplicate_deck)
	deck_name_field.text_changed.connect(_on_deck_name_changed)
	save_btn.pressed.connect(_on_save)
	back_btn.pressed.connect(_on_back)
	remove_char_btn.disabled = true
	remove_trap_btn.disabled = true
	remove_tech_btn.disabled = true
	preview_card_area.gui_input.connect(_on_preview_area_input)
	for child: Node in preview_card_area.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	view_full_card_btn.pressed.connect(func() -> void:
		if _preview_card_name != "":
			CardDetailOverlay.open(self, _preview_card_name, _preview_card_type))

# ── Deck selector ─────────────────────────────────────────────
func _refresh_deck_select() -> void:
	deck_select.clear()
	for deck: DeckData in SaveManager.decks:
		deck_select.add_item(deck.deck_name)
	deck_select.select(SaveManager.active_deck_index)

func _on_deck_selected(index: int) -> void:
	_load_deck(index)

func _load_deck(index: int) -> void:
	SaveManager.active_deck_index = index
	var deck: DeckData = SaveManager.get_active_deck()
	if deck == null:
		return
	current_deck = deck.duplicate_deck()
	deck_name_field.text = current_deck.deck_name
	_rebuild_trunk_list()
	_rebuild_deck_lists()

func _on_new_deck() -> void:
	var deck := DeckData.new()
	deck.deck_name = "New Deck %d" % (SaveManager.decks.size() + 1)
	SaveManager.save_deck(deck)
	_refresh_deck_select()
	_load_deck(SaveManager.active_deck_index)

func _on_delete_deck() -> void:
	if SaveManager.decks.size() <= 1:
		status_label.text = "Cannot delete the last deck."
		return
	SaveManager.delete_deck(SaveManager.active_deck_index)
	_refresh_deck_select()
	_load_deck(SaveManager.active_deck_index)

func _on_duplicate_deck() -> void:
	SaveManager.duplicate_deck(SaveManager.active_deck_index)
	_refresh_deck_select()
	_load_deck(SaveManager.active_deck_index)

func _on_deck_name_changed(new_name: String) -> void:
	if current_deck:
		current_deck.deck_name = new_name

# ── Trunk list ────────────────────────────────────────────────
func _set_filter(f: String) -> void:
	_filter = f
	filter_all.button_pressed  = (f == "all")
	filter_char.button_pressed = (f == "character")
	filter_trap.button_pressed = (f == "trap")
	filter_tech.button_pressed = (f == "tech")
	_update_filter_colors()
	_rebuild_trunk_list()

func _update_filter_colors() -> void:
	var active_col   := Color(0.18, 0.749, 1.0, 1)
	var inactive_col := Color(0.549, 0.651, 0.80, 1)
	filter_all.add_theme_color_override("font_color",  active_col if _filter == "all"       else inactive_col)
	filter_char.add_theme_color_override("font_color", active_col if _filter == "character" else inactive_col)
	filter_trap.add_theme_color_override("font_color", active_col if _filter == "trap"      else inactive_col)
	filter_tech.add_theme_color_override("font_color", active_col if _filter == "tech"      else inactive_col)

func _rebuild_trunk_list() -> void:
	trunk_list.clear()
	var name_q:  String = search_field.text.to_lower()
	var abil_q:  String = _filter_ability.to_lower()
	var use_aff: bool   = _filter_affinity >= 0
	var use_atk: bool   = _filter_atk_min > 0 or _filter_atk_max < 9999
	var use_def: bool   = _filter_def_min > 0 or _filter_def_max < 9999

	if _filter in ["all", "character"]:
		for char_name: String in CardDatabase.get_all_character_names():
			if name_q != "" and name_q not in char_name.to_lower():
				continue
			var data: CharacterData = CardDatabase.get_character(char_name)
			if use_aff and data.affinity != _filter_affinity:
				continue
			if data.crystal_cost < _filter_cost_min or data.crystal_cost > _filter_cost_max:
				continue
			if data.base_atk < _filter_atk_min or data.base_atk > _filter_atk_max:
				continue
			if data.base_def < _filter_def_min or data.base_def > _filter_def_max:
				continue
			if abil_q != "" and abil_q not in data.get_ability_description().to_lower():
				continue
			var label: String = "[%s] %s  ATK:%d DEF:%d  %d◆" % [
				data.get_affinity_name(), char_name,
				data.base_atk, data.base_def, data.crystal_cost
			]
			trunk_list.add_item(label)
			trunk_list.set_item_metadata(trunk_list.item_count - 1,
				{"type": "character", "name": char_name})

	# Traps and Tech have no affinity/ATK/DEF — hide them when those filters are active
	if not use_aff and not use_atk and not use_def:
		if _filter in ["all", "trap"]:
			for trap_name: String in CardDatabase.get_all_trap_names():
				if name_q != "" and name_q not in trap_name.to_lower():
					continue
				var data: TrapData = CardDatabase.get_trap(trap_name)
				if data.crystal_cost < _filter_cost_min or data.crystal_cost > _filter_cost_max:
					continue
				if abil_q != "" and abil_q not in data.get_effect_description().to_lower():
					continue
				var label: String = "TRAP: %s  (%d◆)" % [trap_name, data.crystal_cost]
				trunk_list.add_item(label)
				trunk_list.set_item_metadata(trunk_list.item_count - 1,
					{"type": "trap", "name": trap_name})

		if _filter in ["all", "tech"]:
			for tech_name: String in CardDatabase.get_all_tech_names():
				if name_q != "" and name_q not in tech_name.to_lower():
					continue
				var data: TechCardData = CardDatabase.get_tech(tech_name)
				if data.crystal_cost < _filter_cost_min or data.crystal_cost > _filter_cost_max:
					continue
				if abil_q != "" and abil_q not in data.get_effect_description().to_lower():
					continue
				var label: String = "TECH: %s  (%d◆)" % [tech_name, data.crystal_cost]
				trunk_list.add_item(label)
				trunk_list.set_item_metadata(trunk_list.item_count - 1,
					{"type": "tech", "name": tech_name})

	if _gallery_mode and _trunk_gallery_flow != null:
		_rebuild_trunk_gallery()

# ── Add card from trunk ───────────────────────────────────────
func _on_trunk_double_click(_index: int) -> void:
	_add_selected_trunk_card()

func _on_add_btn() -> void:
	_add_selected_trunk_card()

func _add_selected_trunk_card() -> void:
	if _gallery_mode:
		if _gallery_selected_name != "":
			_add_card_to_deck(_gallery_selected_type, _gallery_selected_name)
		return
	var selected: PackedInt32Array = trunk_list.get_selected_items()
	if selected.is_empty():
		return
	var meta: Dictionary = trunk_list.get_item_metadata(selected[0])
	_add_card_to_deck(meta["type"], meta["name"])

func _add_card_to_deck(card_type: String, card_name: String) -> void:
	if current_deck == null:
		return
	var grid_cards: int = current_deck.characters.size() + current_deck.traps.size()
	match card_type:
		"character":
			if card_name in current_deck.characters:
				status_label.text = "Duplicate: %s is already in the deck." % card_name
				return
			if current_deck.characters.size() >= DeckData.MAX_CHARACTERS:
				status_label.text = "Character limit reached (%d max)." % DeckData.MAX_CHARACTERS
				return
			if grid_cards >= DeckData.TOTAL_SLOTS:
				status_label.text = "Grid deck is full (25 cards max)."
				return
			current_deck.characters.append(card_name)
		"trap":
			if card_name in current_deck.traps:
				status_label.text = "Duplicate: %s is already in the deck." % card_name
				return
			if current_deck.traps.size() >= DeckData.MAX_TRAPS:
				status_label.text = "Trap limit reached (%d max)." % DeckData.MAX_TRAPS
				return
			if grid_cards >= DeckData.TOTAL_SLOTS:
				status_label.text = "Grid deck is full (25 cards max)."
				return
			current_deck.traps.append(card_name)
		"tech":
			if card_name in current_deck.techs:
				status_label.text = "Duplicate: %s is already in the deck." % card_name
				return
			if current_deck.techs.size() >= DeckData.TECH_COUNT:
				status_label.text = "Tech limit reached (exactly %d required)." % DeckData.TECH_COUNT
				return
			current_deck.techs.append(card_name)
	_rebuild_deck_lists()

# ── Remove card from deck ─────────────────────────────────────
func _on_remove_char() -> void:
	var selected: PackedInt32Array = char_list.get_selected_items()
	if selected.is_empty():
		return
	current_deck.characters.remove_at(selected[0])
	remove_char_btn.disabled = true
	_rebuild_deck_lists()

func _on_remove_trap() -> void:
	var selected: PackedInt32Array = trap_list.get_selected_items()
	if selected.is_empty():
		return
	current_deck.traps.remove_at(selected[0])
	remove_trap_btn.disabled = true
	_rebuild_deck_lists()

func _on_remove_tech() -> void:
	var selected: PackedInt32Array = tech_list.get_selected_items()
	if selected.is_empty():
		return
	current_deck.techs.remove_at(selected[0])
	remove_tech_btn.disabled = true
	_rebuild_deck_lists()

# ── Deck panel refresh ────────────────────────────────────────
func _rebuild_deck_lists() -> void:
	if current_deck == null:
		return

	# Characters
	char_list.clear()
	for card_name: String in current_deck.characters:
		var data: CharacterData = CardDatabase.get_character(card_name)
		if data:
			char_list.add_item("[%s] %s  ATK:%d DEF:%d" % [
				data.get_affinity_name(), card_name, data.base_atk, data.base_def
			])
		else:
			char_list.add_item(card_name)
		char_list.set_item_metadata(char_list.item_count - 1, {"type": "character", "name": card_name})

	# Traps
	trap_list.clear()
	for card_name: String in current_deck.traps:
		var data: TrapData = CardDatabase.get_trap(card_name)
		if data:
			trap_list.add_item("%s  (%d◆)" % [card_name, data.crystal_cost])
		else:
			trap_list.add_item(card_name)
		trap_list.set_item_metadata(trap_list.item_count - 1, {"type": "trap", "name": card_name})

	# Tech cards
	tech_list.clear()
	for card_name: String in current_deck.techs:
		var data: TechCardData = CardDatabase.get_tech(card_name)
		if data:
			tech_list.add_item("%s  (%d◆)" % [card_name, data.crystal_cost])
		else:
			tech_list.add_item(card_name)
		tech_list.set_item_metadata(tech_list.item_count - 1, {"type": "tech", "name": card_name})

	# Counters
	var nc: int = current_deck.characters.size()
	var nt: int = current_deck.traps.size()
	var ntech: int = current_deck.techs.size()
	var nb: int = current_deck.dead_end_count()

	char_count_label.text  = "Characters: %d / %d  (min %d)" % [nc, DeckData.MAX_CHARACTERS, DeckData.MIN_CHARACTERS]
	trap_count_label.text  = "Traps: %d / %d  (min %d)" % [nt, DeckData.MAX_TRAPS, DeckData.MIN_TRAPS]
	tech_count_label.text  = "Tech Cards: %d / %d" % [ntech, DeckData.TECH_COUNT]
	blank_count_label.text = "Dead End Areas (auto-fill): %d" % nb

	# Colour-code counters
	var char_ok: bool = nc >= DeckData.MIN_CHARACTERS and nc <= DeckData.MAX_CHARACTERS
	var trap_ok: bool = nt >= DeckData.MIN_TRAPS and nt <= DeckData.MAX_TRAPS
	var tech_ok: bool = ntech == DeckData.TECH_COUNT
	char_count_label.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.4) if char_ok else Color(1.0, 0.4, 0.3))
	trap_count_label.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.4) if trap_ok else Color(1.0, 0.4, 0.3))
	tech_count_label.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.4) if tech_ok else Color(1.0, 0.4, 0.3))
	blank_count_label.add_theme_color_override("font_color",
		Color(0.6, 0.6, 0.6) if nb >= 0 else Color(1.0, 0.3, 0.3))

	# Status & save button
	status_label.text = current_deck.validation_message()
	save_btn.disabled = not current_deck.is_valid()

	remove_char_btn.disabled = true
	remove_trap_btn.disabled = true
	remove_tech_btn.disabled = true

	if _gallery_mode and _deck_chars_flow != null:
		_rebuild_deck_galleries()

# ── Card list selection → preview ─────────────────────────────
func _on_trunk_selected(idx: int) -> void:
	var meta: Dictionary = trunk_list.get_item_metadata(idx)
	_show_preview(meta["type"], meta["name"])

func _on_char_list_selected(idx: int) -> void:
	remove_char_btn.disabled = false
	var meta: Dictionary = char_list.get_item_metadata(idx)
	_show_preview(meta["type"], meta["name"])

func _on_trap_list_selected(idx: int) -> void:
	remove_trap_btn.disabled = false
	var meta: Dictionary = trap_list.get_item_metadata(idx)
	_show_preview(meta["type"], meta["name"])

func _on_tech_list_selected(idx: int) -> void:
	remove_tech_btn.disabled = false
	var meta: Dictionary = tech_list.get_item_metadata(idx)
	_show_preview(meta["type"], meta["name"])

# ── Card preview ──────────────────────────────────────────────
const _ART_PLACEHOLDER: Texture2D = preload("res://assets/textures/cards/placeholder.png")

func _show_preview(card_type: String, card_name: String) -> void:
	_preview_card_type = card_type
	_preview_card_name = card_name
	view_full_card_btn.disabled = false

	var accent: Color
	var info_bg: Color

	match card_type:
		"character":
			accent  = Color(1.0,  0.80, 0.20)
			info_bg = Color(0.067, 0.051, 0.0)
			var data: CharacterData = CardDatabase.get_character(card_name)
			if data:
				preview_name.text  = card_name
				preview_stats.text = "[%s]  ATK %d  DEF %d  %d◆" % [
					data.get_affinity_name(), data.base_atk, data.base_def, data.crystal_cost]
				preview_desc.text  = data.ability_description
			preview_frame.texture = null
			_load_preview_art(card_name, "characters")
		"trap":
			accent  = Color(1.0,  0.27, 0.27)
			info_bg = Color(0.067, 0.0, 0.028)
			var data: TrapData = CardDatabase.get_trap(card_name)
			if data:
				preview_name.text  = card_name
				preview_stats.text = "Trap  %d◆" % data.crystal_cost
				preview_desc.text  = data.effect_description
			preview_frame.texture = null
			_load_preview_art(card_name, "traps")
		"tech":
			accent  = Color(0.18, 0.90, 0.60)
			info_bg = Color(0.024, 0.059, 0.035)
			var data: TechCardData = CardDatabase.get_tech(card_name)
			if data:
				preview_name.text  = card_name
				preview_stats.text = "Tech  %d◆" % data.crystal_cost
				preview_desc.text  = data.get_effect_description()
			preview_frame.texture = null
			_load_preview_art(card_name, "tech")

	preview_stats.add_theme_color_override("font_color", accent)
	preview_bg.color         = info_bg
	preview_info_strip.color = info_bg

func _load_preview_art(card_name: String, subfolder: String) -> void:
	var path: String = CardDatabase.find_artwork(card_name, subfolder, SaveManager.nsfw_enabled)
	if path != "":
		preview_art.texture = load(path)
	else:
		preview_art.texture = _ART_PLACEHOLDER

# ── Save / Back ───────────────────────────────────────────────
func _on_save() -> void:
	if current_deck == null or not current_deck.is_valid():
		return
	current_deck.deck_name = deck_name_field.text.strip_edges()
	if current_deck.deck_name == "":
		current_deck.deck_name = "My Deck"
		deck_name_field.text = current_deck.deck_name
	SaveManager.save_deck(current_deck)
	_refresh_deck_select()
	status_label.text = "Deck saved!"

func _on_back() -> void:
	closed.emit()
	queue_free()

# ── Advanced filters ──────────────────────────────────────────
func _build_advanced_filters() -> void:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 3)

	# Toggle header
	var toggle_btn := Button.new()
	toggle_btn.text = "▶  Advanced Filters"
	toggle_btn.toggle_mode = true
	toggle_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle_btn.add_theme_font_size_override("font_size", 13)
	toggle_btn.add_theme_color_override("font_color", Color(0.45, 0.72, 1.0))
	outer.add_child(toggle_btn)

	# Collapsible body
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
	# no auto-apply — user presses Apply
	aff_row.add_child(_adv_affinity_btn)
	body.add_child(aff_row)

	# Cost / ATK / DEF range rows
	var cost_range := _make_range_row(body, "Cost",  0,  9999,   9999,  9999)
	_adv_cost_min = cost_range[0];  _adv_cost_max = cost_range[1]
	var atk_range  := _make_range_row(body, "ATK",   0, 9999,  9999,  9999)
	_adv_atk_min  = atk_range[0];  _adv_atk_max  = atk_range[1]
	var def_range  := _make_range_row(body, "DEF",   0, 9999,  9999,  9999)
	_adv_def_min  = def_range[0];  _adv_def_max  = def_range[1]

	# Ability text
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

	# Apply / Clear buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	var apply_btn := Button.new()
	apply_btn.text = "Apply Filter"
	apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_btn.add_theme_font_size_override("font_size", 13)
	apply_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	apply_btn.pressed.connect(_on_adv_changed)
	btn_row.add_child(apply_btn)
	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.add_theme_font_size_override("font_size", 13)
	clear_btn.pressed.connect(_clear_adv_filters)
	btn_row.add_child(clear_btn)
	body.add_child(btn_row)

	outer.add_child(body)
	left_inner.add_child(outer)
	left_inner.move_child(outer, search_field.get_index() + 1)

func _make_range_row(parent: VBoxContainer, lbl_text: String,
		spin_min: int, spin_max: int,
		default_min: int, default_max: int) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var lbl := Label.new()
	lbl.text = lbl_text
	lbl.custom_minimum_size = Vector2(58, 0)
	lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(lbl)
	var s_min := SpinBox.new()
	s_min.min_value = spin_min
	s_min.max_value = spin_max
	s_min.value = spin_min
	s_min.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s_min.suffix = "min"
	row.add_child(s_min)
	var s_max := SpinBox.new()
	s_max.min_value = spin_min
	s_max.max_value = spin_max
	s_max.value = default_max
	s_max.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s_max.suffix = "max"
	row.add_child(s_max)
	parent.add_child(row)
	return [s_min, s_max]

func _on_adv_changed() -> void:
	_filter_affinity = _adv_affinity_btn.selected - 1
	_filter_cost_min = int(_adv_cost_min.value)
	_filter_cost_max = int(_adv_cost_max.value)
	_filter_atk_min  = int(_adv_atk_min.value)
	_filter_atk_max  = int(_adv_atk_max.value)
	_filter_def_min  = int(_adv_def_min.value)
	_filter_def_max  = int(_adv_def_max.value)
	_rebuild_trunk_list()

func _clear_adv_filters() -> void:
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
	_rebuild_trunk_list()

# ── Card preview modal ────────────────────────────────────────
func _on_preview_area_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and _preview_card_name != "":
		CardDetailOverlay.open(self, _preview_card_name, _preview_card_type)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		AudioManager.tts_stop()

# ── Gallery view ───────────────────────────────────────────────
func _setup_gallery_containers() -> void:
	# Toggle button in filter bar
	_view_toggle_btn = Button.new()
	_view_toggle_btn.custom_minimum_size = Vector2(80, 0)
	_view_toggle_btn.add_theme_font_size_override("font_size", 13)
	_view_toggle_btn.pressed.connect(_toggle_view_mode)
	_view_toggle_btn.visible = false
	filter_bar.add_child(_view_toggle_btn)

	# Pool gallery (left panel, sibling of trunk_list)
	_trunk_gallery_scroll = ScrollContainer.new()
	_trunk_gallery_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_trunk_gallery_flow = HFlowContainer.new()
	_trunk_gallery_flow.add_theme_constant_override("h_separation", 4)
	_trunk_gallery_flow.add_theme_constant_override("v_separation", 4)
	_trunk_gallery_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_trunk_gallery_scroll.add_child(_trunk_gallery_flow)
	left_inner.add_child(_trunk_gallery_scroll)
	left_inner.move_child(_trunk_gallery_scroll, trunk_list.get_index())

	# Deck section galleries (each replaces its ItemList sibling)
	var char_section: Control = char_list.get_parent()
	_deck_chars_scroll_gal = ScrollContainer.new()
	_deck_chars_scroll_gal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_deck_chars_flow = HFlowContainer.new()
	_deck_chars_flow.add_theme_constant_override("h_separation", 3)
	_deck_chars_flow.add_theme_constant_override("v_separation", 3)
	_deck_chars_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_chars_scroll_gal.add_child(_deck_chars_flow)
	char_section.add_child(_deck_chars_scroll_gal)
	char_section.move_child(_deck_chars_scroll_gal, char_list.get_index())

	var trap_section: Control = trap_list.get_parent()
	_deck_traps_scroll_gal = ScrollContainer.new()
	_deck_traps_scroll_gal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_deck_traps_flow = HFlowContainer.new()
	_deck_traps_flow.add_theme_constant_override("h_separation", 3)
	_deck_traps_flow.add_theme_constant_override("v_separation", 3)
	_deck_traps_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_traps_scroll_gal.add_child(_deck_traps_flow)
	trap_section.add_child(_deck_traps_scroll_gal)
	trap_section.move_child(_deck_traps_scroll_gal, trap_list.get_index())

	var tech_section: Control = tech_list.get_parent()
	_deck_tech_scroll_gal = ScrollContainer.new()
	_deck_tech_scroll_gal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_deck_tech_flow = HFlowContainer.new()
	_deck_tech_flow.add_theme_constant_override("h_separation", 3)
	_deck_tech_flow.add_theme_constant_override("v_separation", 3)
	_deck_tech_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_tech_scroll_gal.add_child(_deck_tech_flow)
	tech_section.add_child(_deck_tech_scroll_gal)
	tech_section.move_child(_deck_tech_scroll_gal, tech_list.get_index())

	_apply_view_mode()
	_rebuild_trunk_gallery()
	_rebuild_deck_galleries()


func _toggle_view_mode() -> void:
	_gallery_mode = not _gallery_mode
	_apply_view_mode()
	if _gallery_mode:
		_rebuild_trunk_gallery()
		_rebuild_deck_galleries()

func _apply_view_mode() -> void:
	trunk_list.visible              = not _gallery_mode
	_trunk_gallery_scroll.visible   = _gallery_mode
	char_list.visible               = not _gallery_mode
	trap_list.visible               = not _gallery_mode
	tech_list.visible               = not _gallery_mode
	_deck_chars_scroll_gal.visible  = _gallery_mode
	_deck_traps_scroll_gal.visible  = _gallery_mode
	_deck_tech_scroll_gal.visible   = _gallery_mode
	remove_char_btn.visible         = not _gallery_mode
	remove_trap_btn.visible         = not _gallery_mode
	remove_tech_btn.visible         = not _gallery_mode
	_view_toggle_btn.text = "≡ List" if _gallery_mode else "⊞ Gallery"

func _rebuild_trunk_gallery() -> void:
	for child in _trunk_gallery_flow.get_children():
		child.queue_free()
	for i: int in range(trunk_list.item_count):
		var meta: Dictionary = trunk_list.get_item_metadata(i)
		_trunk_gallery_flow.add_child(_make_pool_tile(meta["name"], meta["type"]))

func _rebuild_deck_galleries() -> void:
	if current_deck == null:
		return
	for child in _deck_chars_flow.get_children():
		child.queue_free()
	for child in _deck_traps_flow.get_children():
		child.queue_free()
	for child in _deck_tech_flow.get_children():
		child.queue_free()
	for card_name: String in current_deck.characters:
		_deck_chars_flow.add_child(_make_deck_tile(card_name, "character"))
	for card_name: String in current_deck.traps:
		_deck_traps_flow.add_child(_make_deck_tile(card_name, "trap"))
	for card_name: String in current_deck.techs:
		_deck_tech_flow.add_child(_make_deck_tile(card_name, "tech"))

func _make_pool_tile(card_name: String, card_type: String) -> Control:
	var tile := Control.new()
	tile.custom_minimum_size = Vector2(90, 124)
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
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75, 0.8))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(lbl)
	tile.tooltip_text = card_name
	tile.gui_input.connect(func(ev: InputEvent) -> void:
		if not (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed \
				and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
			return
		_gallery_selected_name = card_name
		_gallery_selected_type = card_type
		_show_preview(card_type, card_name)
		if (ev as InputEventMouseButton).double_click:
			_add_card_to_deck(card_type, card_name))
	return tile

func _make_deck_tile(card_name: String, card_type: String) -> Control:
	var tile := Control.new()
	tile.custom_minimum_size = Vector2(76, 104)
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
		lbl.add_theme_font_size_override("font_size", 7)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75, 0.8))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(lbl)
	# × remove badge top-right
	var rm := Label.new()
	rm.text = "×"
	rm.layout_mode = 1
	rm.anchor_left = 1.0; rm.anchor_right  = 1.0
	rm.anchor_top  = 0.0; rm.anchor_bottom = 0.0
	rm.offset_left = -16.0; rm.offset_right  = -2.0
	rm.offset_top  =  2.0;  rm.offset_bottom = 16.0
	rm.add_theme_font_size_override("font_size", 13)
	rm.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 0.9))
	rm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(rm)
	tile.tooltip_text = card_name + "  (click to remove)"
	tile.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed \
				and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			_remove_card_gallery(card_name, card_type))
	return tile

func _remove_card_gallery(card_name: String, card_type: String) -> void:
	if current_deck == null:
		return
	match card_type:
		"character": current_deck.characters.erase(card_name)
		"trap":      current_deck.traps.erase(card_name)
		"tech":      current_deck.techs.erase(card_name)
	_rebuild_deck_lists()

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
