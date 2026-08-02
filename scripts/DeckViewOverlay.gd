extends Control
class_name DeckViewOverlay
## Read-only look at the deck equipped to the current protagonist, laid out like
## the deck builder's right panel. Cards bound to an Omen carry a pulsing sigil;
## tapping any card opens the full card overlay with its Omen dossier.

signal closed()

const FULL_CARDS_DIR: String = "res://assets/textures/cards/full_cards/"
const ZOOM_ICON: Texture2D = preload("res://assets/textures/ui/decorations/ui_icon_magnifier.png")

const TILE: Vector2 = Vector2(112.0, 154.0)
const BADGE: float = 24.0
const ZOOM_CHIP: float = 24.0

var _deck: DeckData = null
var _z: int = 210

var _dim: ColorRect = null
var _panel: PanelContainer = null
var _detail: CardDetailOverlay = null


static func open(parent: Node, z_index_override: int = 210) -> DeckViewOverlay:
	if parent == null:
		return null
	var existing: Node = parent.get_node_or_null("DeckViewOverlay")
	if existing != null and is_instance_valid(existing):
		return existing as DeckViewOverlay
	var overlay := DeckViewOverlay.new()
	overlay.name = "DeckViewOverlay"
	overlay._z = z_index_override
	parent.add_child(overlay)
	return overlay


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = _viewport_size()
	z_index = _z
	mouse_filter = Control.MOUSE_FILTER_STOP
	_deck = SaveManager.get_battle_deck()

	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.02, 0.05, 0.0)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_close())
	add_child(_dim)

	_build_panel()
	_relayout()
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.size_changed.connect(_relayout)
	_play_intro()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	accept_event()
	# The card detail closes itself on Escape but does not consume the event, so
	# swallow it here or the deck would vanish out from under the card.
	if _detail != null and is_instance_valid(_detail):
		return
	_close()


func _viewport_size() -> Vector2:
	var vp: Vector2 = get_viewport_rect().size
	if vp.x < 2.0 or vp.y < 2.0:
		vp = Vector2(1280.0, 720.0)
	return vp


func _relayout() -> void:
	position = Vector2.ZERO
	size = _viewport_size()
	if _dim != null:
		_dim.position = Vector2.ZERO
		_dim.size = size
	if _panel != null:
		var w: float = clampf(size.x - 96.0, 620.0, 1120.0)
		var h: float = clampf(size.y - 72.0, 420.0, 840.0)
		_panel.size = Vector2(w, h)
		_panel.position = (size - Vector2(w, h)) * 0.5
		_panel.pivot_offset = Vector2(w, h) * 0.5


# ─────────────────────────────────────────────────────────────
# Shell
# ─────────────────────────────────────────────────────────────

func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", GameDialog.make_panel_stylebox(0.0))
	GameDialog.attach_panel_fx(_panel)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.modulate.a = 0.0
	add_child(_panel)

	var pad := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 22)
	_panel.add_child(pad)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	pad.add_child(col)

	col.add_child(_build_header())
	col.add_child(_make_rule())

	if _deck == null:
		col.add_child(_build_empty_state())
		return

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	var sections := VBoxContainer.new()
	sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sections.add_theme_constant_override("separation", 16)
	scroll.add_child(sections)

	sections.add_child(_build_section(
		"Units", _deck.characters, "character",
		"%d / %d" % [_deck.characters.size(), DeckData.MAX_CHARACTERS],
		_deck.characters.size() >= DeckData.MIN_CHARACTERS
			and _deck.characters.size() <= DeckData.MAX_CHARACTERS))
	sections.add_child(_build_section(
		"Traps", _deck.traps, "trap",
		"%d / %d" % [_deck.traps.size(), DeckData.MAX_TRAPS],
		_deck.traps.size() >= DeckData.MIN_TRAPS
			and _deck.traps.size() <= DeckData.MAX_TRAPS))
	sections.add_child(_build_section(
		"Tech Cards", _deck.techs, "tech",
		"%d / %d" % [_deck.techs.size(), DeckData.TECH_COUNT],
		_deck.techs.size() == DeckData.TECH_COUNT))

	var unions: Array = _achievable_unions()
	if not unions.is_empty():
		sections.add_child(_build_section(
			"Unions", unions, "union", "%d achievable" % unions.size(), true))

	col.add_child(_make_rule())
	col.add_child(_build_footer())


func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(titles)

	var title := Label.new()
	title.text = _deck.deck_name if _deck != null else "No Deck Equipped"
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0))
	titles.add_child(title)

	var sub := Label.new()
	sub.text = _subtitle_text()
	sub.add_theme_font_override("font", FontManager.make_font("primary", 400))
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0, 0.92))
	titles.add_child(sub)

	if _deck != null:
		var status := Label.new()
		status.text = _deck.validation_message()
		status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		status.add_theme_font_override("font", FontManager.make_font("primary", 600))
		status.add_theme_font_size_override("font_size", 15)
		status.add_theme_color_override("font_color",
				Color(0.35, 1.0, 0.5) if _deck.is_valid() else Color(1.0, 0.5, 0.42))
		row.add_child(status)

	var close_btn := Button.new()
	close_btn.custom_minimum_size = Vector2(38.0, 38.0)
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	MenuScreenHeader.style_close_button(close_btn)
	close_btn.pressed.connect(_close)
	row.add_child(close_btn)
	return row


func _subtitle_text() -> String:
	var who: String = ProtagonistVault.get_display_name(SaveManager.current_protagonist_id)
	if _deck == null:
		return "Equip a deck from the main menu before your next battle."
	var costs: Array = _cost_summary()
	return "Equipped to %s   •   Total Cost %d   •   Average Cost %d" % [who, costs[0], costs[1]]


## [total, average] crystal cost over units and traps — same basis the deck
## builder's footer reports, so the two screens never disagree.
func _cost_summary() -> Array:
	var total: int = 0
	var count: int = 0
	for card_name: Variant in _deck.characters:
		var cd: CharacterData = CardDatabase.get_character(str(card_name))
		if cd != null:
			total += cd.crystal_cost
			count += 1
	for card_name: Variant in _deck.traps:
		var td: TrapData = CardDatabase.get_trap(str(card_name))
		if td != null:
			total += td.crystal_cost
			count += 1
	var average: int = 0
	if count > 0:
		average = int(round(float(total) / float(count)))
	return [total, average]


func _achievable_unions() -> Array:
	var names: Array = []
	if _deck == null:
		return names
	var all_unions: Array = UnionDatabase.get_all_unions()
	all_unions.sort_custom(func(a: UnionData, b: UnionData) -> bool:
		return a.card_name < b.card_name)
	for u: UnionData in all_unions:
		if u == null:
			continue
		if not SaveManager.is_union_unlocked(u.card_name):
			continue
		if SaveManager.demo_mode and not UnionDatabase.is_playable_in_demo(u):
			continue
		if UnionDatabase.deck_can_form_union(_deck.characters, u):
			names.append(u.card_name)
	return names


func _build_empty_state() -> Control:
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	var lbl := Label.new()
	lbl.text = "No deck is equipped to this protagonist."
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_override("font", FontManager.make_font("primary", 400))
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", Color(0.72, 0.80, 0.92))
	box.add_child(lbl)
	return box


func _build_footer() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	if OmenVisuals.has_any_omen():
		var swatch := Control.new()
		swatch.custom_minimum_size = Vector2(BADGE, BADGE)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(swatch)
		var legend := OmenBadge.new()
		legend.size = Vector2(BADGE, BADGE)
		legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swatch.add_child(legend)

		var legend_lbl := Label.new()
		legend_lbl.text = "Omen-bound card"
		legend_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		legend_lbl.add_theme_font_override("font", FontManager.make_font("primary", 400))
		legend_lbl.add_theme_font_size_override("font_size", 14)
		legend_lbl.add_theme_color_override("font_color", Color(0.78, 0.86, 0.98, 0.92))
		row.add_child(legend_lbl)

	var hint := Label.new()
	hint.text = "Tap any card to view it full size   •   Reach a Safe Zone to edit this deck."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hint.add_theme_font_override("font", FontManager.make_font("primary", 400))
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.66, 0.74, 0.88, 0.85))
	row.add_child(hint)
	return row


func _make_rule() -> Control:
	var rule := ColorRect.new()
	rule.color = Color(0.45, 0.70, 1.0, 0.22)
	rule.custom_minimum_size = Vector2(0.0, 1.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


# ─────────────────────────────────────────────────────────────
# Sections and tiles
# ─────────────────────────────────────────────────────────────

func _build_section(
		title: String,
		card_names: Array,
		card_type: String,
		count_text: String,
		count_ok: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	box.add_child(hdr)

	var name_lbl := Label.new()
	name_lbl.text = title
	name_lbl.add_theme_font_override("font", FontManager.make_font("primary", 600))
	name_lbl.add_theme_font_size_override("font_size", 19)
	name_lbl.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0))
	hdr.add_child(name_lbl)

	var count_lbl := Label.new()
	count_lbl.text = count_text
	count_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_override("font", FontManager.make_font("primary", 400))
	count_lbl.add_theme_font_size_override("font_size", 15)
	count_lbl.add_theme_color_override("font_color",
			Color(0.30, 1.0, 0.40) if count_ok else Color(1.0, 0.40, 0.30))
	hdr.add_child(count_lbl)

	if card_names.is_empty():
		var none := Label.new()
		none.text = "— none —"
		none.add_theme_font_override("font", FontManager.make_font("primary", 400))
		none.add_theme_font_size_override("font_size", 14)
		none.add_theme_color_override("font_color", Color(0.55, 0.62, 0.74, 0.85))
		box.add_child(none)
		return box

	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	box.add_child(flow)
	for card_name: Variant in card_names:
		flow.add_child(_make_tile(str(card_name), card_type))
	return box


func _make_tile(card_name: String, card_type: String) -> Control:
	var tile := Control.new()
	tile.custom_minimum_size = TILE
	tile.size = TILE
	tile.pivot_offset = TILE * 0.5
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.clip_contents = true

	var tex: Texture2D = _load_card_tex(card_name)
	if tex != null:
		var art := TextureRect.new()
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.texture = tex
		tile.add_child(art)
	else:
		var bg := ColorRect.new()
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0.05, 0.07, 0.14, 1.0)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(bg)
		var lbl := Label.new()
		lbl.text = card_name
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(lbl)

	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(0.35, 0.62, 1.0, 0.30)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	frame.add_theme_stylebox_override("panel", sb)
	tile.add_child(frame)

	OmenBadge.attach_to_tile(tile, card_name, BADGE)
	var zoom: Control = _make_zoom_chip()
	tile.add_child(zoom)

	tile.gui_input.connect(func(ev: InputEvent) -> void:
		if not _is_tap(ev):
			return
		tile.accept_event()
		_open_full_card(card_name, card_type))
	tile.mouse_entered.connect(func() -> void: _hover_tile(tile, zoom, true))
	tile.mouse_exited.connect(func() -> void: _hover_tile(tile, zoom, false))
	return tile


func _open_full_card(card_name: String, card_type: String) -> void:
	if _detail != null and is_instance_valid(_detail):
		return
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	# Pin to this full-screen viewer so the dimmer inherits a real size and
	# outside taps dismiss the card instead of falling through to dead chrome.
	_detail = CardDetailOverlay.open_and_return(self, card_name, card_type,
			null, false, true, z_index + 40)
	if _detail != null:
		_detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_detail.position = Vector2.ZERO
		_detail.size = size
		_detail.move_to_front()
		_detail.tree_exiting.connect(func() -> void: _detail = null, CONNECT_ONE_SHOT)


## Touch delivers screen events when mouse emulation is off, so accept both.
func _is_tap(ev: InputEvent) -> bool:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		return mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed
	if ev is InputEventScreenTouch:
		return (ev as InputEventScreenTouch).pressed
	return false


## Persistent affordance rather than hover-only: on touch there is no hover, so the
## tile has to advertise that it opens the full card.
func _make_zoom_chip() -> Control:
	var chip := PanelContainer.new()
	chip.name = "ZoomChip"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size = Vector2(ZOOM_CHIP, ZOOM_CHIP)
	chip.position = TILE - Vector2(ZOOM_CHIP + 3.0, ZOOM_CHIP + 3.0)
	chip.modulate.a = 0.72
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.04, 0.09, 0.72)
	sb.border_color = Color(0.45, 0.72, 1.0, 0.45)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(2.0)
	chip.add_theme_stylebox_override("panel", sb)

	var icon := TextureRect.new()
	icon.texture = ZOOM_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(icon)
	return chip


func _hover_tile(tile: Control, zoom: Control, entering: bool) -> void:
	if tile == null or not is_instance_valid(tile):
		return
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(tile, "scale", Vector2.ONE * (1.06 if entering else 1.0), 0.10) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if zoom != null and is_instance_valid(zoom):
		tw.tween_property(zoom, "modulate:a", 1.0 if entering else 0.72, 0.10)


func _load_card_tex(card_name: String) -> Texture2D:
	var snake: String = card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
	if SaveManager.nsfw_enabled:
		var nsfw: String = FULL_CARDS_DIR + snake + "_nsfw.png"
		if ResourceLoader.exists(nsfw):
			return load(nsfw) as Texture2D
	for candidate: String in [FULL_CARDS_DIR + snake + ".png", FULL_CARDS_DIR + snake + ".jpg"]:
		if ResourceLoader.exists(candidate):
			return load(candidate) as Texture2D
	return null


# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────

func _play_intro() -> void:
	if _panel == null:
		return
	_panel.scale = Vector2(0.965, 0.965)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_dim, "color:a", 0.78, 0.22) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.26) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close() -> void:
	if not is_inside_tree():
		return
	set_process_unhandled_input(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_dim, "color:a", 0.0, 0.16)
	if _panel != null:
		tw.tween_property(_panel, "modulate:a", 0.0, 0.16)
	await tw.finished
	closed.emit()
	queue_free()
