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
var _filter: String = "all"   # "all" | "character" | "trap" | "tech" | "union"
var _filter_union_btn: Button = null
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

# Union right-panel section
var _union_section: VBoxContainer = null
var _union_list: ItemList = null
var _union_header_label: Label = null
var _import_dialog: FileDialog = null
var _export_dialog: FileDialog = null

# ── Formation Editor — draggable gallery card ─────────────────
class FEDraggableCard extends TextureRect:
	var card_name:    String = ""
	var card_type:    String = ""
	var _want_detail: bool   = false

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton): return
		var mbe := event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT:
			if mbe.pressed:
				_want_detail = true
				get_tree().create_timer(0.5).timeout.connect(func() -> void:
					if _want_detail:
						_want_detail = false
						CardDetailOverlay.open(self, card_name, card_type))
			else:
				_want_detail = false

	func _get_drag_data(_pos: Vector2) -> Variant:
		_want_detail = false   # cancel long-press when drag starts
		const PW: float = 100.0
		const PH: float = 137.0
		# Card-shaped preview (matches occupied cell appearance)
		var prev := Panel.new()
		prev.custom_minimum_size = Vector2(PW, PH)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.12, 0.28, 0.95) if card_type == "character" \
				else Color(0.22, 0.07, 0.10, 0.95)
		sb.set_border_width_all(1)
		sb.border_color = Color(0.45, 0.70, 1.0, 0.75)
		sb.set_corner_radius_all(4)
		prev.add_theme_stylebox_override("panel", sb)
		var art := TextureRect.new()
		art.position     = Vector2.ZERO
		art.size         = Vector2(PW, PH)
		art.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture      = texture
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prev.add_child(art)
		var lbl := Label.new()
		lbl.position = Vector2(0.0, PH - 22.0)
		lbl.size     = Vector2(PW, 22.0)
		lbl.text     = card_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.clip_text    = true
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 9)
		var lbl_sb := StyleBoxFlat.new()
		lbl_sb.bg_color = Color(0.0, 0.0, 0.0, 0.72)
		lbl.add_theme_stylebox_override("normal", lbl_sb)
		prev.add_child(lbl)
		set_drag_preview(prev)
		return {"card_name": card_name, "card_type": card_type,
				"from_grid": false, "grid_row": -1, "grid_col": -1}

# ── Formation Editor — grid cell (drop target + drag source) ──
class FEGridCell extends Panel:
	var grid_row:         int      = 0
	var grid_col:         int      = 0
	var occupied_name:    String   = ""
	var occupied_type:    String   = ""
	var on_drop_cb:       Callable = Callable()
	var on_unplace_cb:    Callable = Callable()
	var on_drag_start_cb: Callable = Callable()
	var _card_tex:    TextureRect = null
	var _name_lbl:    Label       = null
	var _want_detail: bool        = false

	func occupy(p_name: String, p_type: String, tex: Texture2D) -> void:
		occupied_name = p_name
		occupied_type = p_type
		if _card_tex != null:
			_card_tex.texture = tex
		if _name_lbl != null:
			_name_lbl.text = p_name
		self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		if tex == null and not p_name.is_empty():
			self_modulate = Color(0.55, 0.85, 1.0) if p_type == "character" \
				else Color(1.0, 0.55, 0.55)

	func vacate() -> void:
		occupied_name = ""
		occupied_type = ""
		if _card_tex != null:
			_card_tex.texture = null
		if _name_lbl != null:
			_name_lbl.text = ""
		self_modulate = Color(1.0, 1.0, 1.0, 1.0)

	func _get_drag_data(_pos: Vector2) -> Variant:
		if occupied_name.is_empty():
			return null
		_want_detail = false   # cancel long-press when drag starts
		# Capture values BEFORE the callback vacates this cell (vacate() clears occupied_name/tex)
		var captured_name: String   = occupied_name
		var captured_type: String   = occupied_type
		var captured_tex:  Texture2D = _card_tex.texture if _card_tex != null else null
		if on_drag_start_cb.is_valid():
			on_drag_start_cb.call(grid_row, grid_col)
		const PW: float = 100.0
		const PH: float = 137.0
		# Card-shaped preview (matches occupied cell appearance)
		var prev := Panel.new()
		prev.custom_minimum_size = Vector2(PW, PH)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.12, 0.28, 0.95) if captured_type == "character" \
				else Color(0.22, 0.07, 0.10, 0.95)
		sb.set_border_width_all(1)
		sb.border_color = Color(0.45, 0.70, 1.0, 0.75)
		sb.set_corner_radius_all(4)
		prev.add_theme_stylebox_override("panel", sb)
		var art := TextureRect.new()
		art.position     = Vector2.ZERO
		art.size         = Vector2(PW, PH)
		art.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture      = captured_tex
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prev.add_child(art)
		var lbl := Label.new()
		lbl.position = Vector2(0.0, PH - 22.0)
		lbl.size     = Vector2(PW, 22.0)
		lbl.text     = captured_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.clip_text    = true
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 9)
		var lbl_sb := StyleBoxFlat.new()
		lbl_sb.bg_color = Color(0.0, 0.0, 0.0, 0.72)
		lbl.add_theme_stylebox_override("normal", lbl_sb)
		prev.add_child(lbl)
		set_drag_preview(prev)
		return {"card_name": captured_name, "card_type": captured_type,
				"from_grid": true, "grid_row": grid_row, "grid_col": grid_col}

	func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
		return data is Dictionary and (data as Dictionary).has("card_name")

	func _drop_data(_pos: Vector2, data: Variant) -> void:
		if on_drop_cb.is_valid():
			on_drop_cb.call(grid_row, grid_col, data as Dictionary)

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton): return
		var mbe := event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT:
			if mbe.pressed and not occupied_name.is_empty():
				_want_detail = true
				var snap_name: String = occupied_name
				var snap_type: String = occupied_type
				get_tree().create_timer(0.5).timeout.connect(func() -> void:
					if _want_detail:
						_want_detail = false
						CardDetailOverlay.open(self, snap_name, snap_type))
			else:
				_want_detail = false
		elif mbe.button_index == MOUSE_BUTTON_RIGHT and mbe.pressed:
			_want_detail = false
			if not occupied_name.is_empty() and on_unplace_cb.is_valid():
				on_unplace_cb.call(grid_row, grid_col)

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
	_add_union_filter_button()
	_update_filter_colors()
	_setup_gallery_containers()
	_setup_union_section()
	# Apply initial union mechanism visibility
	_on_union_mechanism_changed(SaveManager.union_mechanism_unlocked)
	SaveManager.union_mechanism_changed.connect(_on_union_mechanism_changed)
	# Hide the dead end row — it auto-fills and needs no user action
	blank_count_label.get_parent().visible = false

	# Pin BottomBar (Save + Back) to the bottom of the right panel
	var bottom_bar: Node = save_btn.get_parent()
	var right_inner: Node = bottom_bar.get_parent()
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_inner.add_child(spacer)
	right_inner.move_child(spacer, bottom_bar.get_index())

	# Add "FORMATIONS" button above the bottom bar
	var formations_btn := Button.new()
	formations_btn.text = "📋  FORMATIONS"
	formations_btn.add_theme_font_size_override("font_size", 13)
	formations_btn.pressed.connect(_open_formation_editor)
	right_inner.add_child(formations_btn)
	right_inner.move_child(formations_btn, bottom_bar.get_index())

	_setup_deck_io_buttons(bottom_bar)
	_setup_deck_file_dialogs()

	# Prologue lock check — show overlay if deckbuilding not yet unlocked
	if not SaveManager.is_deckbuilding_unlocked():
		_show_deckbuilding_lock_overlay()

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
	# Double-tap deck lists to remove
	char_list.item_activated.connect(func(_i: int) -> void: _on_remove_char())
	trap_list.item_activated.connect(func(_i: int) -> void: _on_remove_trap())
	tech_list.item_activated.connect(func(_i: int) -> void: _on_remove_tech())
	remove_char_btn.pressed.connect(_on_remove_char)
	remove_trap_btn.pressed.connect(_on_remove_trap)
	remove_tech_btn.pressed.connect(_on_remove_tech)
	# Long-press on ItemLists → CardDetailOverlay
	_setup_list_long_press(trunk_list)
	_setup_list_long_press(char_list)
	_setup_list_long_press(trap_list)
	_setup_list_long_press(tech_list)
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

func _setup_list_long_press(list: ItemList) -> void:
	var pressed_idx: Array[int] = [-1]
	var lp_timer := Timer.new()
	lp_timer.one_shot = true
	lp_timer.wait_time = 0.5
	add_child(lp_timer)
	lp_timer.timeout.connect(func() -> void:
		var idx: int = pressed_idx[0]
		if idx >= 0 and idx < list.item_count:
			var meta: Variant = list.get_item_metadata(idx)
			if meta is Dictionary:
				CardDetailOverlay.open(self, (meta as Dictionary).get("name", ""), (meta as Dictionary).get("type", "")))
	list.gui_input.connect(func(ev: InputEvent) -> void:
		if not (ev is InputEventMouseButton):
			return
		var mb := ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed and not mb.double_click:
			var idx: int = list.get_item_at_position(mb.position)
			pressed_idx[0] = idx
			if idx >= 0:
				lp_timer.start()
			else:
				lp_timer.stop()
		else:
			lp_timer.stop()
			pressed_idx[0] = -1)

# ── Trunk list ────────────────────────────────────────────────
func _set_filter(f: String) -> void:
	_filter = f
	filter_all.button_pressed  = (f == "all")
	filter_char.button_pressed = (f == "character")
	filter_trap.button_pressed = (f == "trap")
	filter_tech.button_pressed = (f == "tech")
	if _filter_union_btn != null:
		_filter_union_btn.button_pressed = (f == "union")
	_update_filter_colors()
	_rebuild_trunk_list()

func _update_filter_colors() -> void:
	var active_col   := Color(0.18, 0.749, 1.0, 1)
	var inactive_col := Color(0.549, 0.651, 0.80, 1)
	filter_all.add_theme_color_override("font_color",  active_col if _filter == "all"       else inactive_col)
	filter_char.add_theme_color_override("font_color", active_col if _filter == "character" else inactive_col)
	filter_trap.add_theme_color_override("font_color", active_col if _filter == "trap"      else inactive_col)
	filter_tech.add_theme_color_override("font_color", active_col if _filter == "tech"      else inactive_col)
	if _filter_union_btn != null:
		_filter_union_btn.add_theme_color_override("font_color",
			Color(0.25, 0.90, 1.0) if _filter == "union" else inactive_col)

func _rebuild_trunk_list() -> void:
	trunk_list.clear()
	var name_q:  String = search_field.text.to_lower()
	var abil_q:  String = _filter_ability.to_lower()
	var use_aff: bool   = _filter_affinity >= 0
	var use_atk: bool   = _filter_atk_min > 0 or _filter_atk_max < 9999
	var use_def: bool   = _filter_def_min > 0 or _filter_def_max < 9999

	if _filter in ["all", "character"]:
		for char_name: String in CardDatabase.get_all_character_names():
			if Collection.get_card_count(char_name) == 0:
				continue
			if name_q != "" and name_q not in char_name.to_lower():
				continue
			var data: CharacterData = CardDatabase.get_character(char_name)
			if SaveManager.demo_mode and not data.include_in_demo:
				continue
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

	if _filter in ["all", "union"] and SaveManager.union_mechanism_unlocked:
		var union_list: Array = UnionDatabase.get_all_unions()
		union_list.sort_custom(func(a: UnionData, b: UnionData) -> bool: return a.card_name < b.card_name)
		for u: UnionData in union_list:
			if not SaveManager.is_union_unlocked(u.card_name):
				continue
			if SaveManager.demo_mode and not UnionDatabase.is_playable_in_demo(u):
				continue
			if name_q != "" and name_q not in u.card_name.to_lower():
				continue
			if use_aff and int(u.affinity) != _filter_affinity:
				continue
			if u.summon_cost < _filter_cost_min or u.summon_cost > _filter_cost_max:
				continue
			if use_atk and (u.base_atk < _filter_atk_min or u.base_atk > _filter_atk_max):
				continue
			if use_def and (u.base_def < _filter_def_min or u.base_def > _filter_def_max):
				continue
			if abil_q != "" and abil_q not in u.ability_description.to_lower():
				continue
			var label: String = "UNION: %s  ATK:%d DEF:%d  %d◆" % [
				u.card_name, u.base_atk, u.base_def, u.summon_cost]
			trunk_list.add_item(label)
			trunk_list.set_item_custom_fg_color(trunk_list.item_count - 1, Color(0.25, 0.90, 1.0))
			trunk_list.set_item_metadata(trunk_list.item_count - 1,
				{"type": "union", "name": u.card_name})

	# Traps and tech ignore affinity/ATK/DEF/cost/ability filters — only tab + name search apply.
	if _filter in ["all", "trap"]:
		for trap_name: String in CardDatabase.get_all_trap_names():
			if Collection.get_card_count(trap_name) == 0:
				continue
			if name_q != "" and name_q not in trap_name.to_lower():
				continue
			var data: TrapData = CardDatabase.get_trap(trap_name)
			if SaveManager.demo_mode and not data.include_in_demo:
				continue
			var label: String = "TRAP: %s  (%d◆)" % [trap_name, data.crystal_cost]
			trunk_list.add_item(label)
			trunk_list.set_item_metadata(trunk_list.item_count - 1,
				{"type": "trap", "name": trap_name})

	if _filter in ["all", "tech"]:
		for tech_name: String in CardDatabase.get_all_tech_names():
			if Collection.get_card_count(tech_name) == 0:
				continue
			if name_q != "" and name_q not in tech_name.to_lower():
				continue
			var data: TechCardData = CardDatabase.get_tech(tech_name)
			if SaveManager.demo_mode and not data.include_in_demo:
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
				status_label.text = "Unit limit reached (%d max)." % DeckData.MAX_CHARACTERS
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
		"union":
			_add_union_materials_to_deck(card_name)
			return
	_rebuild_deck_lists()

# ── Remove card from deck ─────────────────────────────────────
func _on_remove_char() -> void:
	var selected: PackedInt32Array = char_list.get_selected_items()
	if selected.is_empty():
		return
	var removed_name: String = current_deck.characters[selected[0]]
	current_deck.characters.remove_at(selected[0])
	remove_char_btn.disabled = true
	_fe_purge_card_from_formations(removed_name)
	SaveManager.save_deck(current_deck)  # persist formation purge immediately
	_rebuild_deck_lists()
	_fe_refresh_if_open()

func _on_remove_trap() -> void:
	var selected: PackedInt32Array = trap_list.get_selected_items()
	if selected.is_empty():
		return
	var removed_name: String = current_deck.traps[selected[0]]
	current_deck.traps.remove_at(selected[0])
	remove_trap_btn.disabled = true
	_fe_purge_card_from_formations(removed_name)
	SaveManager.save_deck(current_deck)  # persist formation purge immediately
	_rebuild_deck_lists()
	_fe_refresh_if_open()

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

	char_count_label.text  = "Units: %d / %d  (min %d)" % [nc, DeckData.MAX_CHARACTERS, DeckData.MIN_CHARACTERS]
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
	_rebuild_union_section()

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
				preview_name.text  = data.display_name if not data.display_name.is_empty() else card_name
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
				preview_name.text  = data.display_name if not data.display_name.is_empty() else card_name
				preview_stats.text = "Trap  %d◆" % data.crystal_cost
				preview_desc.text  = data.effect_description
			preview_frame.texture = null
			_load_preview_art(card_name, "traps")
		"tech":
			accent  = Color(0.18, 0.90, 0.60)
			info_bg = Color(0.024, 0.059, 0.035)
			var data: TechCardData = CardDatabase.get_tech(card_name)
			if data:
				preview_name.text  = data.display_name if not data.display_name.is_empty() else card_name
				preview_stats.text = "Tech  %d◆" % data.crystal_cost
				preview_desc.text  = data.get_effect_description()
			preview_frame.texture = null
			_load_preview_art(card_name, "tech")

		"union":
			accent  = Color(0.25, 0.90, 1.0)
			info_bg = Color(0.02, 0.07, 0.10)
			var data: UnionData = UnionDatabase.get_union(card_name)
			if data:
				preview_name.text  = data.display_name if not data.display_name.is_empty() else card_name
				preview_stats.text = "[%s]  ATK %d  DEF %d  %d◆" % [
					CharacterData.Affinity.keys()[int(data.affinity)].capitalize(),
					data.base_atk, data.base_def, data.summon_cost]
				var is_unlocked: bool = SaveManager.is_union_unlocked(card_name)
				preview_desc.text = data.ability_description if is_unlocked else data.partial_ability_description
			preview_frame.texture = null
			_load_preview_art(card_name, "union")
	preview_stats.add_theme_color_override("font_color", accent)
	preview_bg.color         = info_bg
	preview_info_strip.color = info_bg

func _load_preview_art(card_name: String, subfolder: String) -> void:
	var path: String = CardDatabase.find_artwork(card_name, subfolder, SaveManager.nsfw_enabled)
	var tex: Texture2D = null
	if path != "":
		tex = load(path) as Texture2D
	preview_art.texture = tex if tex != null else _ART_PLACEHOLDER

# ── Union mechanism visibility ────────────────────────────────
func _on_union_mechanism_changed(unlocked: bool) -> void:
	if _filter_union_btn != null:
		_filter_union_btn.visible = unlocked
	if _union_section != null:
		_union_section.visible = unlocked
	if not unlocked and _filter == "union":
		_set_filter("all")
	_rebuild_trunk_list()

# ── Union filter button ───────────────────────────────────────
func _add_union_filter_button() -> void:
	_filter_union_btn = Button.new()
	_filter_union_btn.text = "Union"
	_filter_union_btn.toggle_mode = true
	_filter_union_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_union_btn.add_theme_font_size_override("font_size", 18)
	# Copy StyleBoxes from filter_all so it looks identical
	for style_name: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: StyleBox = filter_all.get_theme_stylebox(style_name)
		if sb != null:
			_filter_union_btn.add_theme_stylebox_override(style_name, sb)
	_filter_union_btn.pressed.connect(func() -> void: _set_filter("union"))
	filter_bar.add_child(_filter_union_btn)
	filter_bar.move_child(_filter_union_btn, filter_tech.get_index() + 1)

# ── Union material auto-add ───────────────────────────────────

func _describe_cond(cond: Dictionary) -> String:
	if cond.is_empty():
		return "Any character card"
	if cond.has("card_name"):
		return str(cond["card_name"])
	var parts: Array = []
	if cond.has("name_contains"):
		parts.append('name contains "%s"' % str(cond["name_contains"]))
	if cond.has("affinity") and int(cond["affinity"]) >= 0:
		parts.append("%s affinity" % CharacterData.Affinity.keys()[int(cond["affinity"])].capitalize())
	if cond.has("min_cost"):
		parts.append("%d◆+" % int(cond["min_cost"]))
	if cond.has("min_atk"):
		parts.append("ATK %d+" % int(cond["min_atk"]))
	if cond.has("min_def"):
		parts.append("DEF %d+" % int(cond["min_def"]))
	return ", ".join(parts) if parts.size() > 0 else "Any character card"

func _add_union_materials_to_deck(union_name: String) -> void:
	if current_deck == null:
		return
	var u: UnionData = UnionDatabase.get_union(union_name)
	if u == null:
		return

	var assigned: Array = []
	var missing_conds: Array = []
	var used_in_assign: Array = []

	for cond: Dictionary in u.material_conditions:
		var candidates: Array = []
		for cname: String in CardDatabase.get_all_character_names():
			if Collection.get_card_count(cname) == 0:
				continue
			var char_data: CharacterData = CardDatabase.get_character(cname)
			if SaveManager.demo_mode and not char_data.include_in_demo:
				continue
			if cname in current_deck.characters:
				continue
			if cname in used_in_assign:
				continue
			if UnionDatabase.deck_char_satisfies(cname, cond):
				var data: CharacterData = CardDatabase.get_character(cname)
				candidates.append({"name": cname, "cost": data.crystal_cost})
		if candidates.is_empty():
			missing_conds.append(cond)
		else:
			candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return a["cost"] < b["cost"] if a["cost"] != b["cost"] else a["name"] < b["name"])
			var chosen: String = candidates[0]["name"]
			assigned.append(chosen)
			used_in_assign.append(chosen)

	if missing_conds.size() > 0:
		var found_str: String = ", ".join(assigned) if assigned.size() > 0 else "none"
		var missing_str: String = ""
		for cond: Dictionary in missing_conds:
			missing_str += "\n  • " + _describe_cond(cond)
		var popup := AcceptDialog.new()
		popup.title = "Not Enough Union Material"
		popup.dialog_text = (
			"Not enough union material.\n\nFormula: %s\n\nFound: %s\nMissing:%s"
			% [u.formula_description, found_str, missing_str])
		add_child(popup)
		popup.popup_centered()
		popup.confirmed.connect(func() -> void: popup.queue_free())
		popup.canceled.connect(func() -> void: popup.queue_free())
		return

	for cname: String in assigned:
		if cname in current_deck.characters:
			continue
		if current_deck.characters.size() >= DeckData.MAX_CHARACTERS:
			status_label.text = "Unit limit reached; some union materials could not be added."
			break
		var grid_cards: int = current_deck.characters.size() + current_deck.traps.size()
		if grid_cards >= DeckData.TOTAL_SLOTS:
			status_label.text = "Grid deck is full; some union materials could not be added."
			break
		current_deck.characters.append(cname)

	_rebuild_deck_lists()

# ── Union right-panel section ─────────────────────────────────
func _setup_union_section() -> void:
	var tech_section: Control = tech_list.get_parent()
	var right_inner: Control = tech_section.get_parent()

	# Set all three deck sections to SHRINK_BEGIN so none of them
	# stretches with an empty gap — unused space falls to the bottom of the panel.
	var char_section: Control = char_list.get_parent()
	var trap_section: Control = trap_list.get_parent()
	char_section.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	trap_section.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tech_section.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# Guarantee a visible minimum height for the ItemLists in list mode.
	if char_list.custom_minimum_size.y < 211:
		char_list.custom_minimum_size = Vector2(char_list.custom_minimum_size.x, 211)
	if trap_list.custom_minimum_size.y < 104:
		trap_list.custom_minimum_size = Vector2(trap_list.custom_minimum_size.x, 104)
	if tech_list.custom_minimum_size.y < 104:
		tech_list.custom_minimum_size = Vector2(tech_list.custom_minimum_size.x, 104)

	_union_section = VBoxContainer.new()
	_union_section.add_theme_constant_override("separation", 2)
	_union_section.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var header_row := HBoxContainer.new()
	_union_header_label = Label.new()
	_union_header_label.text = "Union (0 achievable)"
	_union_header_label.add_theme_font_size_override("font_size", 18)
	_union_header_label.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0))
	_union_header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(_union_header_label)
	_union_section.add_child(header_row)

	var union_scroll := ScrollContainer.new()
	union_scroll.custom_minimum_size = Vector2(0, 110)
	union_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	union_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	union_scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	_union_section.add_child(union_scroll)

	_union_list = null  # no longer used
	var union_flow := HBoxContainer.new()
	union_flow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	union_flow.add_theme_constant_override("separation", 3)
	union_scroll.add_child(union_flow)

	# Store the flow reference in _union_list's place (reuse var with different type note)
	# We use _union_header_label's parent as the scroll, flow is accessed via it
	_union_section.set_meta("_union_flow", union_flow)

	right_inner.add_child(_union_section)
	right_inner.move_child(_union_section, tech_section.get_index() + 1)
	_rebuild_union_section()

func _rebuild_union_section() -> void:
	if _union_section == null or current_deck == null:
		return
	var union_flow: HBoxContainer = _union_section.get_meta("_union_flow") as HBoxContainer
	if union_flow == null:
		return
	for ch: Node in union_flow.get_children():
		ch.queue_free()
	var count: int = 0
	var all_unions: Array = UnionDatabase.get_all_unions()
	all_unions.sort_custom(func(a: UnionData, b: UnionData) -> bool: return a.card_name < b.card_name)
	for u: UnionData in all_unions:
		if not SaveManager.is_union_unlocked(u.card_name):
			continue
		if SaveManager.demo_mode and not UnionDatabase.is_playable_in_demo(u):
			continue
		if UnionDatabase.deck_can_form_union(current_deck.characters, u):
			union_flow.add_child(_make_union_right_tile(u))
			count += 1
	_union_header_label.text = "Union (%d achievable)" % count

func _make_union_right_tile(u: UnionData) -> Control:
	var tile := Control.new()
	tile.custom_minimum_size = Vector2(76, 104)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	var tex: Texture2D = _load_full_card_tex(u.card_name, "union")
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
		bg.color = Color(0.04, 0.14, 0.20, 1.0)
		tile.add_child(bg)
		var lbl := Label.new()
		lbl.text = u.card_name
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 7)
		lbl.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(lbl)
	tile.tooltip_text = "%s  ATK %d / DEF %d  %d◆" % [u.card_name, u.base_atk, u.base_def, u.summon_cost]
	var lp_union := Timer.new()
	lp_union.one_shot = true
	lp_union.wait_time = 0.5
	tile.add_child(lp_union)
	lp_union.timeout.connect(func() -> void:
		CardDetailOverlay.open(self, u.card_name, "union"))
	tile.gui_input.connect(func(ev: InputEvent) -> void:
		if not (ev is InputEventMouseButton):
			return
		var mb := ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			lp_union.start()
			_show_preview("union", u.card_name)
		else:
			lp_union.stop())
	return tile

# ── Prologue lock overlay ────────────────────────────────────
func _show_deckbuilding_lock_overlay() -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# dim covers the full screen and is the primary click target
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var lbl := Label.new()
	lbl.text = "Play prologue in Campaign Mode to unlock deckbuilding"
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	lbl.offset_left = -500.0; lbl.offset_right  = 500.0
	lbl.offset_top  =  -30.0; lbl.offset_bottom =  30.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(lbl)

	var sub := Label.new()
	sub.text = "Tap or press any key to return to main menu"
	sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	sub.offset_left = -300.0; sub.offset_right  = 300.0
	sub.offset_top  =   70.0; sub.offset_bottom = 100.0
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(sub)

	# Subtle blink on the sub label
	var tween := overlay.create_tween()
	tween.set_loops()
	tween.tween_property(sub, "modulate:a", 0.25, 1.2).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sub, "modulate:a", 1.0,  1.2).set_ease(Tween.EASE_IN_OUT)

	# Clicks land on dim; keyboard handled via overlay focus
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_on_back())
	overlay.focus_mode = Control.FOCUS_ALL
	overlay.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventKey and (ev as InputEventKey).pressed:
			_on_back())
	add_child(overlay)
	overlay.grab_focus()

# ── Formation Editor overlay ─────────────────────────────────
# Formation data: {"name": str, "placements": [{"r": int, "c": int, "name": str, "type": str}]}
var _fe_overlay:          Control        = null
var _fe_selected:         int            = -1
var _fe_grid_cells:       Array          = []   # [r][c] = FEGridCell
var _fe_name_edit:        LineEdit       = null
var _fe_list:             ItemList       = null
var _fe_gallery_flow:     HFlowContainer = null
var _fe_union_panel_node: Panel          = null
var _fe_union_flow:       HFlowContainer = null
var _fe_chars_remaining:  Array          = []
var _fe_traps_remaining:  Array          = []
var _fe_flash_cells:      Array          = []
var _fe_flash_tween:      Tween          = null

const _FE_CELL_W:   float = 100.0
const _FE_CELL_H:   float = 137.0
const _FE_CELL_GAP: int   = 5
const _FE_GAL_W:    float = 88.0
const _FE_GAL_H:    float = 121.0
const _FE_GAL_GAP:  int   = 6

func _open_formation_editor() -> void:
	if _fe_overlay != null and is_instance_valid(_fe_overlay):
		_fe_overlay.queue_free()

	_fe_overlay = Control.new()
	_fe_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fe_overlay.z_index = 100
	_fe_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.12, 0.97)
	_fe_overlay.add_child(bg)

	# ── Header bar ────────────────────────────────────────────
	var hdr_panel := Panel.new()
	hdr_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hdr_panel.offset_bottom = 48.0
	var hdr_sb := StyleBoxFlat.new()
	hdr_sb.bg_color            = Color(0.05, 0.07, 0.16, 1.0)
	hdr_sb.border_width_bottom = 1
	hdr_sb.border_color        = Color(0.35, 0.6, 1.0, 0.45)
	hdr_panel.add_theme_stylebox_override("panel", hdr_sb)
	_fe_overlay.add_child(hdr_panel)

	var hdr_lbl := Label.new()
	hdr_lbl.text = "FORMATIONS  —  up to %d per deck" % DeckData.MAX_FORMATIONS
	hdr_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hdr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	hdr_lbl.add_theme_font_size_override("font_size", 18)
	hdr_lbl.add_theme_color_override("font_color", Color(0.5, 0.88, 1.0))
	hdr_panel.add_child(hdr_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕ CLOSE"
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -130.0; close_btn.offset_right  = -10.0
	close_btn.offset_top  =   8.0;  close_btn.offset_bottom =  40.0
	close_btn.pressed.connect(func() -> void: _fe_overlay.queue_free())
	_fe_overlay.add_child(close_btn)

	# ── Main 3-column layout ──────────────────────────────────
	var main := HBoxContainer.new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.offset_top = 52.0; main.offset_bottom = -8.0
	main.offset_left = 8.0; main.offset_right  = -8.0
	main.add_theme_constant_override("separation", 12)
	_fe_overlay.add_child(main)

	# ── Left: formation list ──────────────────────────────────
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(200.0, 0.0)
	left.add_theme_constant_override("separation", 5)
	main.add_child(left)

	var list_panel := Panel.new()
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lp_sb := StyleBoxFlat.new()
	lp_sb.bg_color = Color(0.05, 0.07, 0.16, 1.0)
	lp_sb.border_color = Color(0.35, 0.6, 1.0, 0.35)
	lp_sb.border_width_left = 1; lp_sb.border_width_right  = 1
	lp_sb.border_width_top  = 1; lp_sb.border_width_bottom = 1
	lp_sb.corner_radius_top_left = 8;    lp_sb.corner_radius_top_right    = 8
	lp_sb.corner_radius_bottom_left = 8; lp_sb.corner_radius_bottom_right = 8
	list_panel.add_theme_stylebox_override("panel", lp_sb)
	left.add_child(list_panel)

	var lp_vb := VBoxContainer.new()
	lp_vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lp_vb.offset_left = 8.0; lp_vb.offset_right  = -8.0
	lp_vb.offset_top  = 8.0; lp_vb.offset_bottom = -8.0
	lp_vb.add_theme_constant_override("separation", 5)
	list_panel.add_child(lp_vb)

	var list_hdr := Label.new()
	list_hdr.text = "Formations"
	list_hdr.add_theme_font_size_override("font_size", 14)
	list_hdr.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	lp_vb.add_child(list_hdr)

	_fe_list = ItemList.new()
	_fe_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fe_list.item_selected.connect(_fe_on_formation_selected)
	lp_vb.add_child(_fe_list)

	var list_btns := HBoxContainer.new()
	list_btns.add_theme_constant_override("separation", 4)
	lp_vb.add_child(list_btns)

	var add_btn := Button.new()
	add_btn.text = "+ Add"
	add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_btn.pressed.connect(_fe_add_formation)
	list_btns.add_child(add_btn)

	var del_btn := Button.new()
	del_btn.text = "− Del"
	del_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	del_btn.pressed.connect(_fe_delete_formation)
	list_btns.add_child(del_btn)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 4)
	lp_vb.add_child(name_row)
	var name_lbl := Label.new()
	name_lbl.text = "Name:"
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_row.add_child(name_lbl)
	_fe_name_edit = LineEdit.new()
	_fe_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fe_name_edit.placeholder_text = "Formation name"
	_fe_name_edit.text_changed.connect(_fe_on_name_changed)
	name_row.add_child(_fe_name_edit)

	var save_f_btn := Button.new()
	save_f_btn.text = "💾  Save"
	save_f_btn.add_theme_font_size_override("font_size", 13)
	save_f_btn.pressed.connect(_fe_save_formation)
	lp_vb.add_child(save_f_btn)

	# ── Center: styled 5×5 grid ───────────────────────────────
	var center_vb := VBoxContainer.new()
	center_vb.add_theme_constant_override("separation", 4)
	center_vb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_vb.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	main.add_child(center_vb)

	var grid_hdr := Label.new()
	grid_hdr.text = "Formation Grid  —  drag cards from the right"
	grid_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grid_hdr.add_theme_font_size_override("font_size", 13)
	grid_hdr.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	center_vb.add_child(grid_hdr)

	var grid_panel := Panel.new()
	var gp_w: float = _FE_CELL_W * 5.0 + float(_FE_CELL_GAP) * 4.0 + 24.0
	var gp_h: float = _FE_CELL_H * 5.0 + float(_FE_CELL_GAP) * 4.0 + 24.0
	grid_panel.custom_minimum_size = Vector2(gp_w, gp_h)
	var gp_sb := StyleBoxFlat.new()
	gp_sb.bg_color                   = Color(0.06, 0.08, 0.18, 1.0)
	gp_sb.border_color               = Color(0.35, 0.6, 1.0, 0.45)
	gp_sb.border_width_left          = 1; gp_sb.border_width_right  = 1
	gp_sb.border_width_top           = 1; gp_sb.border_width_bottom = 1
	gp_sb.corner_radius_top_left     = 8; gp_sb.corner_radius_top_right    = 8
	gp_sb.corner_radius_bottom_left  = 8; gp_sb.corner_radius_bottom_right = 8
	grid_panel.add_theme_stylebox_override("panel", gp_sb)
	center_vb.add_child(grid_panel)

	var grid_center := CenterContainer.new()
	grid_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid_panel.add_child(grid_center)

	var grid_cont := GridContainer.new()
	grid_cont.columns = 5
	grid_cont.add_theme_constant_override("h_separation", _FE_CELL_GAP)
	grid_cont.add_theme_constant_override("v_separation", _FE_CELL_GAP)
	grid_center.add_child(grid_cont)

	_fe_grid_cells = []
	for r in range(5):
		var row_arr: Array = []
		for c in range(5):
			var cell := FEGridCell.new()
			cell.grid_row         = r
			cell.grid_col         = c
			cell.on_drop_cb       = _fe_on_card_dropped
			cell.on_unplace_cb    = _fe_on_cell_unplace
			cell.on_drag_start_cb = _fe_on_cell_drag_start
			cell.custom_minimum_size = Vector2(_FE_CELL_W, _FE_CELL_H)
			var cell_sb := StyleBoxFlat.new()
			cell_sb.bg_color                   = Color(0.08, 0.10, 0.24, 1.0)
			cell_sb.border_color               = Color(0.28, 0.48, 0.9, 0.55)
			cell_sb.border_width_left          = 1; cell_sb.border_width_right  = 1
			cell_sb.border_width_top           = 1; cell_sb.border_width_bottom = 1
			cell_sb.corner_radius_top_left     = 4; cell_sb.corner_radius_top_right    = 4
			cell_sb.corner_radius_bottom_left  = 4; cell_sb.corner_radius_bottom_right = 4
			cell.add_theme_stylebox_override("panel", cell_sb)
			# Flash overlay (child 0)
			var flash_cr := ColorRect.new()
			flash_cr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			flash_cr.color        = Color(0.25, 0.90, 1.00, 0.0)
			flash_cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			flash_cr.z_index      = 5
			cell.add_child(flash_cr)
			# Card art TextureRect (child 1)
			var cell_tex := TextureRect.new()
			cell_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			cell_tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			cell_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			cell_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(cell_tex)
			cell._card_tex = cell_tex
			# Name label overlay at bottom (child 2)
			var cell_lbl := Label.new()
			cell_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			cell_lbl.offset_top    = -20.0; cell_lbl.offset_bottom = 0.0
			cell_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell_lbl.add_theme_font_size_override("font_size", 8)
			cell_lbl.clip_text    = true
			cell_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var lbl_bg := StyleBoxFlat.new()
			lbl_bg.bg_color = Color(0.0, 0.0, 0.0, 0.65)
			cell_lbl.add_theme_stylebox_override("normal", lbl_bg)
			cell.add_child(cell_lbl)
			cell._name_lbl = cell_lbl
			grid_cont.add_child(cell)
			row_arr.append(cell)
		_fe_grid_cells.append(row_arr)

	# ── Right: gallery + possible unions ─────────────────────
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	main.add_child(right)

	_fe_build_gallery_panel(right)
	_fe_build_union_panel(right)

	add_child(_fe_overlay)
	_fe_rebuild_list()
	if current_deck != null and current_deck.formations.size() > 0:
		_fe_select_formation(0)
		if _fe_list != null:
			_fe_list.select(0)

func _fe_build_gallery_panel(parent: Control) -> void:
	const TWO_ROW_H: float = (_FE_GAL_H + 22.0) * 2.0 + float(_FE_GAL_GAP) + 38.0
	var gal_panel := Panel.new()
	gal_panel.custom_minimum_size   = Vector2(0.0, TWO_ROW_H)
	gal_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var gal_sb := StyleBoxFlat.new()
	gal_sb.bg_color                   = Color(0.05, 0.07, 0.16, 1.0)
	gal_sb.border_color               = Color(0.35, 0.6, 1.0, 0.35)
	gal_sb.border_width_left          = 1; gal_sb.border_width_right  = 1
	gal_sb.border_width_top           = 1; gal_sb.border_width_bottom = 1
	gal_sb.corner_radius_top_left     = 8; gal_sb.corner_radius_top_right    = 8
	gal_sb.corner_radius_bottom_left  = 8; gal_sb.corner_radius_bottom_right = 8
	gal_panel.add_theme_stylebox_override("panel", gal_sb)
	parent.add_child(gal_panel)

	var gal_lbl := Label.new()
	gal_lbl.text = "DECK CARDS  —  drag onto grid  |  right-click placed card to retrieve"
	gal_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	gal_lbl.offset_top = 6.0; gal_lbl.offset_bottom = 28.0
	gal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gal_lbl.add_theme_font_size_override("font_size", 12)
	gal_lbl.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0, 0.85))
	gal_panel.add_child(gal_lbl)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = 30.0; scroll.offset_left   = 8.0
	scroll.offset_right  = -8.0; scroll.offset_bottom = -8.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gal_panel.add_child(scroll)

	_fe_gallery_flow = HFlowContainer.new()
	_fe_gallery_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fe_gallery_flow.add_theme_constant_override("h_separation", _FE_GAL_GAP)
	_fe_gallery_flow.add_theme_constant_override("v_separation", _FE_GAL_GAP)
	scroll.add_child(_fe_gallery_flow)

func _fe_build_union_panel(parent: Control) -> void:
	var panel := Panel.new()
	_fe_union_panel_node = panel
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = Color(0.04, 0.08, 0.16, 1.0)
	sb.border_color               = Color(0.25, 0.85, 1.0, 0.40)
	sb.border_width_left          = 1; sb.border_width_right  = 1
	sb.border_width_top           = 1; sb.border_width_bottom = 1
	sb.corner_radius_top_left     = 8; sb.corner_radius_top_right    = 8
	sb.corner_radius_bottom_left  = 8; sb.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	var hdr := Label.new()
	hdr.text = "POSSIBLE UNIONS  —  tap to highlight zone"
	hdr.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hdr.offset_top = 6.0; hdr.offset_bottom = 28.0
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 12)
	hdr.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0, 0.90))
	panel.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = 30.0; scroll.offset_left   = 8.0
	scroll.offset_right  = -8.0; scroll.offset_bottom = -8.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll)

	_fe_union_flow = HFlowContainer.new()
	_fe_union_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fe_union_flow.add_theme_constant_override("h_separation", _FE_GAL_GAP)
	_fe_union_flow.add_theme_constant_override("v_separation", _FE_GAL_GAP)
	scroll.add_child(_fe_union_flow)

func _fe_refresh_gallery() -> void:
	if _fe_gallery_flow == null: return
	for ch in _fe_gallery_flow.get_children():
		ch.queue_free()
	for card_name: String in _fe_chars_remaining:
		_fe_add_gallery_card(card_name, "character")
	for card_name: String in _fe_traps_remaining:
		_fe_add_gallery_card(card_name, "trap")

func _fe_add_gallery_card(card_name: String, card_type: String) -> void:
	var wrap := VBoxContainer.new()
	wrap.custom_minimum_size = Vector2(_FE_GAL_W, _FE_GAL_H + 22.0)
	wrap.add_theme_constant_override("separation", 2)
	_fe_gallery_flow.add_child(wrap)

	var dc := FEDraggableCard.new()
	dc.card_name             = card_name
	dc.card_type             = card_type
	dc.custom_minimum_size   = Vector2(_FE_GAL_W, _FE_GAL_H)
	dc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dc.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
	dc.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tex: Texture2D = _fe_load_card_tex(card_name)
	if tex != null:
		dc.texture = tex
	else:
		dc.modulate = Color(0.35, 0.55, 1.0) if card_type == "character" \
			else Color(1.0, 0.38, 0.38)
	wrap.add_child(dc)

	var lbl := Label.new()
	lbl.text                 = card_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	wrap.add_child(lbl)

func _fe_refresh_union_panel() -> void:
	if _fe_union_flow == null: return
	for ch in _fe_union_flow.get_children():
		ch.queue_free()
	if current_deck == null: return
	for u: UnionData in UnionDatabase.get_all_unions():
		if not UnionDatabase.is_playable_in_demo(u): continue
		if not SaveManager.is_union_unlocked(u.card_name): continue
		if not UnionDatabase.deck_can_form_union(current_deck.characters, u): continue
		_fe_union_flow.add_child(_fe_make_union_tile(u))


func _fe_make_union_tile(u: UnionData) -> Control:
	var wrap := VBoxContainer.new()
	wrap.custom_minimum_size = Vector2(_FE_GAL_W, _FE_GAL_H + 22.0)
	wrap.add_theme_constant_override("separation", 2)

	var img := TextureRect.new()
	img.custom_minimum_size   = Vector2(_FE_GAL_W, _FE_GAL_H)
	img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	img.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tex: Texture2D = _fe_load_card_tex(u.card_name)
	if tex != null:
		img.texture = tex
	else:
		img.modulate = Color(0.25, 0.90, 1.00)
	img.mouse_filter = Control.MOUSE_FILTER_STOP
	var captured_u: UnionData = u
	var want_detail_ref: Array = [false]   # mutable bool via array
	img.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mbe := ev as InputEventMouseButton
			if mbe.button_index == MOUSE_BUTTON_LEFT:
				if mbe.pressed:
					if mbe.double_click:
						want_detail_ref[0] = false
						CardDetailOverlay.open(_fe_overlay, captured_u.card_name, "union")
					else:
						want_detail_ref[0] = true
						img.get_tree().create_timer(0.5).timeout.connect(func() -> void:
							if want_detail_ref[0]:
								want_detail_ref[0] = false
								CardDetailOverlay.open(_fe_overlay, captured_u.card_name, "union"))
				else:
					if want_detail_ref[0]:
						want_detail_ref[0] = false
						_fe_start_zone_flash(captured_u))
	wrap.add_child(img)

	var lbl := Label.new()
	lbl.text                 = u.card_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.25, 0.90, 1.00))
	wrap.add_child(lbl)
	return wrap

func _fe_start_zone_flash(u: UnionData) -> void:
	_fe_stop_zone_flash()
	_fe_flash_cells = []
	for zv: Vector2i in u.union_zone:
		if zv.x >= 0 and zv.x < 5 and zv.y >= 0 and zv.y < 5:
			_fe_flash_cells.append(_fe_grid_cells[zv.x][zv.y] as FEGridCell)
	if _fe_flash_cells.is_empty():
		return
	_fe_flash_tween = _fe_overlay.create_tween().set_loops(3)
	var first: bool = true
	for cell: FEGridCell in _fe_flash_cells:
		var flash_cr: ColorRect = cell.get_child(0) as ColorRect
		if first:
			_fe_flash_tween.tween_property(flash_cr, "color:a", 0.45, 0.30)
			first = false
		else:
			_fe_flash_tween.parallel().tween_property(flash_cr, "color:a", 0.45, 0.30)
	first = true
	for cell: FEGridCell in _fe_flash_cells:
		var flash_cr: ColorRect = cell.get_child(0) as ColorRect
		if first:
			_fe_flash_tween.tween_property(flash_cr, "color:a", 0.0, 0.30)
			first = false
		else:
			_fe_flash_tween.parallel().tween_property(flash_cr, "color:a", 0.0, 0.30)
	_fe_flash_tween.finished.connect(_fe_stop_zone_flash)

func _fe_stop_zone_flash() -> void:
	if _fe_flash_tween != null and _fe_flash_tween.is_valid():
		_fe_flash_tween.kill()
	_fe_flash_tween = null
	for cell: FEGridCell in _fe_flash_cells:
		var flash_cr: ColorRect = cell.get_child(0) as ColorRect
		if flash_cr != null:
			flash_cr.color.a = 0.0
	_fe_flash_cells.clear()

func _fe_on_card_dropped(r: int, c: int, data: Dictionary) -> void:
	if _fe_selected < 0: return
	var card_name: String = str(data["card_name"])
	var card_type: String = str(data["card_type"])
	# At this point the card is always in the pool (gallery drags were always there;
	# grid drags call on_drag_start_cb first which returns the card to the pool).
	if card_type == "character":
		_fe_chars_remaining.erase(card_name)
	else:
		_fe_traps_remaining.erase(card_name)

	var fd: Dictionary = current_deck.formations[_fe_selected] as Dictionary
	var pls: Array = fd.get("placements", []) as Array
	# Evict any card already in this cell back to pool
	for i in range(pls.size() - 1, -1, -1):
		var p: Dictionary = pls[i] as Dictionary
		if int(p.get("r", -1)) == r and int(p.get("c", -1)) == c:
			var evicted_name: String = str(p.get("name", ""))
			var evicted_type: String = str(p.get("type", ""))
			if not evicted_name.is_empty():
				if evicted_type == "character":
					_fe_chars_remaining.append(evicted_name)
				else:
					_fe_traps_remaining.append(evicted_name)
			pls.remove_at(i)
	pls.append({"r": r, "c": c, "name": card_name, "type": card_type})
	fd["placements"] = pls

	(_fe_grid_cells[r][c] as FEGridCell).occupy(card_name, card_type, _fe_load_card_tex(card_name))
	SFXManager.play(SFXManager.SFX_PLACE)
	_fe_refresh_gallery()
	_fe_refresh_union_panel()

func _fe_on_cell_drag_start(r: int, c: int) -> void:
	# Called the moment the user starts dragging from a filled cell.
	# Vacate and return card to pool immediately so the gallery shows it.
	if _fe_selected < 0: return
	var cell: FEGridCell = _fe_grid_cells[r][c] as FEGridCell
	if cell.occupied_name.is_empty(): return
	var card_name: String = cell.occupied_name
	var card_type: String = cell.occupied_type
	var fd: Dictionary = current_deck.formations[_fe_selected] as Dictionary
	var pls: Array = fd.get("placements", []) as Array
	for i in range(pls.size() - 1, -1, -1):
		var p: Dictionary = pls[i] as Dictionary
		if int(p.get("r", -1)) == r and int(p.get("c", -1)) == c:
			pls.remove_at(i)
	fd["placements"] = pls
	cell.vacate()
	if card_type == "character":
		_fe_chars_remaining.append(card_name)
	else:
		_fe_traps_remaining.append(card_name)
	_fe_refresh_gallery()
	_fe_refresh_union_panel()

func _fe_on_cell_unplace(r: int, c: int) -> void:
	_fe_on_cell_drag_start(r, c)
	SFXManager.play(SFXManager.SFX_REMOVE)

func _fe_rebuild_list() -> void:
	if _fe_list == null: return
	_fe_list.clear()
	if current_deck == null: return
	for f: Variant in current_deck.formations:
		var fd: Dictionary = f as Dictionary
		_fe_list.add_item(str(fd.get("name", "Formation")))
	_fe_selected = -1

func _fe_on_formation_selected(idx: int) -> void:
	_fe_select_formation(idx)

func _fe_select_formation(idx: int) -> void:
	_fe_selected = idx
	_fe_stop_zone_flash()
	if current_deck == null or idx < 0 or idx >= current_deck.formations.size():
		return
	var fd: Dictionary = current_deck.formations[idx] as Dictionary
	if _fe_name_edit != null:
		_fe_name_edit.text = str(fd.get("name", "Formation"))
	# Rebuild the remaining pool (deck minus already-placed cards)
	_fe_chars_remaining = current_deck.characters.duplicate()
	_fe_traps_remaining = current_deck.traps.duplicate()
	var pls: Variant = fd.get("placements", [])
	if pls is Array:
		for pl: Variant in (pls as Array):
			if not pl is Dictionary: continue
			var p: Dictionary = pl as Dictionary
			var n: String = str(p.get("name", ""))
			var t: String = str(p.get("type", ""))
			if t == "character":
				_fe_chars_remaining.erase(n)
			else:
				_fe_traps_remaining.erase(n)
	_fe_refresh_grid(fd)
	_fe_refresh_gallery()
	_fe_refresh_union_panel()

func _fe_refresh_grid(fd: Dictionary) -> void:
	if _fe_grid_cells.is_empty(): return
	for r in range(5):
		for c in range(5):
			(_fe_grid_cells[r][c] as FEGridCell).vacate()
	var pls: Variant = fd.get("placements", [])
	if not pls is Array: return
	for pl: Variant in (pls as Array):
		if not pl is Dictionary: continue
		var p: Dictionary = pl as Dictionary
		var r: int = int(p.get("r", -1))
		var c: int = int(p.get("c", -1))
		if r < 0 or r > 4 or c < 0 or c > 4: continue
		var n: String = str(p.get("name", ""))
		var t: String = str(p.get("type", ""))
		(_fe_grid_cells[r][c] as FEGridCell).occupy(n, t, _fe_load_card_tex(n))

func _fe_on_name_changed(new_name: String) -> void:
	if _fe_selected < 0 or current_deck == null: return
	(current_deck.formations[_fe_selected] as Dictionary)["name"] = new_name
	if _fe_list != null and _fe_selected < _fe_list.item_count:
		_fe_list.set_item_text(_fe_selected, new_name)

func _fe_add_formation() -> void:
	if current_deck == null: return
	if current_deck.formations.size() >= DeckData.MAX_FORMATIONS:
		return
	current_deck.formations.append({"name": "Formation %d" % (current_deck.formations.size() + 1), "placements": []})
	_fe_rebuild_list()
	_fe_select_formation(current_deck.formations.size() - 1)
	if _fe_list != null:
		_fe_list.select(_fe_selected)

func _fe_delete_formation() -> void:
	if current_deck == null or _fe_selected < 0: return
	current_deck.formations.remove_at(_fe_selected)
	_fe_rebuild_list()
	_fe_selected = -1
	if _fe_name_edit != null:
		_fe_name_edit.text = ""
	if not _fe_grid_cells.is_empty():
		for r in range(5):
			for c in range(5):
				(_fe_grid_cells[r][c] as FEGridCell).vacate()
	_fe_chars_remaining.clear()
	_fe_traps_remaining.clear()
	_fe_refresh_gallery()
	_fe_refresh_union_panel()

func _fe_load_card_tex(card_name: String) -> Texture2D:
	var snake: String = card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
	var path: String = "res://assets/textures/cards/full_cards/" + snake + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

## Remove a card from every formation's placements (called when a card is deleted from the deck).
func _fe_purge_card_from_formations(card_name: String) -> void:
	if current_deck == null: return
	for f: Variant in current_deck.formations:
		var fd: Dictionary = f as Dictionary
		var pls: Array = fd.get("placements", []) as Array
		for i in range(pls.size() - 1, -1, -1):
			if str((pls[i] as Dictionary).get("name", "")) == card_name:
				pls.remove_at(i)
		fd["placements"] = pls

## Re-select the current formation in the overlay so gallery + grid stay in sync.
func _fe_refresh_if_open() -> void:
	if _fe_overlay == null or not is_instance_valid(_fe_overlay): return
	if _fe_selected >= 0:
		_fe_select_formation(_fe_selected)
	else:
		_fe_refresh_gallery()
		_fe_refresh_union_panel()

func _fe_save_formation() -> void:
	if current_deck == null: return
	SaveManager.save_deck(current_deck)
	_refresh_deck_select()
	status_label.text = "Formation saved!"

# ── Import / Export ───────────────────────────────────────────
func _setup_deck_io_buttons(bottom_bar: Node) -> void:
	var export_btn := Button.new()
	export_btn.text = "Export"
	export_btn.custom_minimum_size = Vector2(100, 46)
	export_btn.add_theme_font_size_override("font_size", 17)
	export_btn.pressed.connect(_on_export_decks)
	bottom_bar.add_child(export_btn)
	bottom_bar.move_child(export_btn, 0)

	var import_btn := Button.new()
	import_btn.text = "Import"
	import_btn.custom_minimum_size = Vector2(100, 46)
	import_btn.add_theme_font_size_override("font_size", 17)
	import_btn.pressed.connect(_on_import_decks)
	bottom_bar.add_child(import_btn)
	bottom_bar.move_child(import_btn, 0)

func _setup_deck_file_dialogs() -> void:
	var default_dir := _default_deck_io_dir()
	_import_dialog = FileDialog.new()
	_import_dialog.title = "Import Decks"
	_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_import_dialog.filters = PackedStringArray(["*.json ; Deck JSON"])
	_import_dialog.current_dir = default_dir
	_import_dialog.file_selected.connect(_on_import_file_selected)
	add_child(_import_dialog)

	_export_dialog = FileDialog.new()
	_export_dialog.title = "Export Decks"
	_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_export_dialog.filters = PackedStringArray(["*.json ; Deck JSON"])
	_export_dialog.current_dir = default_dir
	_export_dialog.current_file = "blightsilver_decks.json"
	_export_dialog.file_selected.connect(_on_export_file_selected)
	add_child(_export_dialog)

func _default_deck_io_dir() -> String:
	var docs: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if not docs.is_empty():
		return docs
	var desktop: String = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	if not desktop.is_empty():
		return desktop
	return ProjectSettings.globalize_path("user://")

func _flush_current_deck_to_manager() -> void:
	if current_deck == null:
		return
	current_deck.deck_name = deck_name_field.text.strip_edges()
	if current_deck.deck_name.is_empty():
		current_deck.deck_name = "My Deck"
		deck_name_field.text = current_deck.deck_name
	var idx: int = SaveManager.active_deck_index
	if idx >= 0 and idx < SaveManager.decks.size():
		SaveManager.decks[idx] = current_deck

func _on_import_decks() -> void:
	_import_dialog.popup_centered(Vector2i(900, 600))

func _on_export_decks() -> void:
	_export_dialog.popup_centered(Vector2i(900, 600))

func _on_import_file_selected(path: String) -> void:
	var result: Dictionary = SaveManager.import_decks_from_file(path)
	if not bool(result.get("ok", false)):
		status_label.text = "Import failed: %s" % str(result.get("error", "Unknown error"))
		return
	var count: int = int(result.get("imported", 0))
	_refresh_deck_select()
	_load_deck(SaveManager.active_deck_index)
	status_label.text = "Imported %d deck(s)." % count

func _on_export_file_selected(path: String) -> void:
	_flush_current_deck_to_manager()
	var payload: Dictionary = SaveManager.export_decks_payload()
	var export_path: String = path
	if not export_path.to_lower().ends_with(".json"):
		export_path += ".json"
	var file := FileAccess.open(export_path, FileAccess.WRITE)
	if file == null:
		status_label.text = "Export failed: could not write file."
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	status_label.text = "Exported %d deck(s) to %s" % [SaveManager.decks.size(), export_path.get_file()]

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

	# Deck section galleries (each replaces its ItemList sibling).
	# Tile size: 76×104 px, gap 3 px.
	# Characters: 2 rows visible (2×104 + 3 = 211 px), no vertical scroll.
	# Traps / Tech: 1 row visible (104 px), no vertical scroll.
	var char_section: Control = char_list.get_parent()
	_deck_chars_scroll_gal = ScrollContainer.new()
	_deck_chars_scroll_gal.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_deck_chars_scroll_gal.custom_minimum_size = Vector2(0, 211)
	_deck_chars_scroll_gal.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_deck_chars_flow = HFlowContainer.new()
	_deck_chars_flow.add_theme_constant_override("h_separation", 3)
	_deck_chars_flow.add_theme_constant_override("v_separation", 3)
	_deck_chars_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_chars_scroll_gal.add_child(_deck_chars_flow)
	char_section.add_child(_deck_chars_scroll_gal)
	char_section.move_child(_deck_chars_scroll_gal, char_list.get_index())

	var trap_section: Control = trap_list.get_parent()
	_deck_traps_scroll_gal = ScrollContainer.new()
	_deck_traps_scroll_gal.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_deck_traps_scroll_gal.custom_minimum_size = Vector2(0, 104)
	_deck_traps_scroll_gal.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_deck_traps_flow = HFlowContainer.new()
	_deck_traps_flow.add_theme_constant_override("h_separation", 3)
	_deck_traps_flow.add_theme_constant_override("v_separation", 3)
	_deck_traps_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_traps_scroll_gal.add_child(_deck_traps_flow)
	trap_section.add_child(_deck_traps_scroll_gal)
	trap_section.move_child(_deck_traps_scroll_gal, trap_list.get_index())

	var tech_section: Control = tech_list.get_parent()
	_deck_tech_scroll_gal = ScrollContainer.new()
	_deck_tech_scroll_gal.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_deck_tech_scroll_gal.custom_minimum_size = Vector2(0, 104)
	_deck_tech_scroll_gal.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
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
			icon_lbl.add_theme_font_size_override("font_size", 28)
			icon_lbl.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0, 0.55))
			icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.add_child(icon_lbl)
		var lbl := Label.new()
		lbl.text = card_name
		lbl.layout_mode = 1
		lbl.anchor_left = 0.0; lbl.anchor_right  = 1.0
		lbl.anchor_top  = 0.55; lbl.anchor_bottom = 1.0
		lbl.offset_left = 2.0; lbl.offset_right = -2.0; lbl.offset_bottom = -2.0
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.add_theme_color_override("font_color",
			Color(0.25, 0.90, 1.0) if is_union else Color(0.55, 0.65, 0.75, 0.8))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(lbl)
	tile.tooltip_text = card_name
	var lp_pool := Timer.new()
	lp_pool.one_shot = true
	lp_pool.wait_time = 0.5
	tile.add_child(lp_pool)
	lp_pool.timeout.connect(func() -> void:
		CardDetailOverlay.open(self, card_name, card_type))
	tile.gui_input.connect(func(ev: InputEvent) -> void:
		if not (ev is InputEventMouseButton):
			return
		var mb := ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_gallery_selected_name = card_name
			_gallery_selected_type = card_type
			if mb.double_click:
				lp_pool.stop()
				_add_card_to_deck(card_type, card_name)
			else:
				lp_pool.start()
				_show_preview(card_type, card_name)
		else:
			lp_pool.stop())
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
	tile.tooltip_text = card_name + "  (double-tap to remove)"
	var lp_deck := Timer.new()
	lp_deck.one_shot = true
	lp_deck.wait_time = 0.5
	tile.add_child(lp_deck)
	lp_deck.timeout.connect(func() -> void:
		CardDetailOverlay.open(self, card_name, card_type))
	tile.gui_input.connect(func(ev: InputEvent) -> void:
		if not (ev is InputEventMouseButton):
			return
		var mb := ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			if mb.double_click:
				lp_deck.stop()
				_remove_card_gallery(card_name, card_type)
			else:
				lp_deck.start()
				_show_preview(card_type, card_name)
		else:
			lp_deck.stop())
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
	var path: String = FULL_CARDS_DIR + snake + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
