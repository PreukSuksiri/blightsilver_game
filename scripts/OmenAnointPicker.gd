extends Control
class_name OmenAnointPicker
## Binds an Anoint omen to one deck card. Two-step by design: highlight a card to
## preview it (or open the full card), then confirm — an anoint lasts the whole
## chapter, so a stray tap must never decide it.

signal picked(card_name: String)

const FULL_CARDS_DIR: String = "res://assets/textures/cards/full_cards/"

const CAPSULE_D: float = 116.0
const TILE: Vector2 = Vector2(142.0, 195.0)
const PREVIEW_W: float = 316.0
const CARD_ASPECT: float = 819.0 / 1126.0

var _omen: Dictionary = {}
var _eligible: Array = []
var _selected: int = -1
var _input_enabled: bool = false

var _dim: ColorRect = null
var _panel: PanelContainer = null
var _tiles: Array[Control] = []
var _preview_host: VBoxContainer = null
var _confirm_btn: Button = null
var _detail: CardDetailOverlay = null


static func await_selection(parent: Node, omen: Dictionary, eligible_cards: Array) -> String:
	if parent == null or eligible_cards.is_empty():
		return ""
	var overlay := OmenAnointPicker.new()
	overlay.name = "OmenAnointPicker"
	overlay._omen = omen.duplicate(true)
	overlay._eligible = eligible_cards.duplicate(true)
	parent.add_child(overlay)
	var result: Variant = await overlay.picked
	if is_instance_valid(overlay):
		overlay.queue_free()
	if result is String:
		return result as String
	return ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = _viewport_size()
	z_index = 220
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_unhandled_input(true)

	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.02, 0.05, 0.0)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_build_panel()
	_relayout()
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.size_changed.connect(_relayout)

	if not _eligible.is_empty():
		_select(0)
	_play_intro()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	accept_event()
	# CardDetailOverlay closes itself on Escape without consuming the event.
	if _detail != null and is_instance_valid(_detail):
		return


func _viewport_size() -> Vector2:
	var vp: Vector2 = get_viewport_rect().size
	if vp.x < 2.0 or vp.y < 2.0:
		vp = Vector2(1280.0, 720.0)
	return vp


## Autowrapped labels report an inflated minimum height until they know their final
## width, and Control.set_size() clamps upward to that minimum. Re-apply the layout
## over a few frames so the panel settles at its intended size (hidden by the fade-in).
func _settle_layout() -> void:
	for _i: int in range(3):
		await get_tree().process_frame
		if not is_inside_tree():
			return
		_relayout()


func _relayout() -> void:
	position = Vector2.ZERO
	size = _viewport_size()
	if _dim != null:
		_dim.position = Vector2.ZERO
		_dim.size = size
	if _panel != null:
		var w: float = clampf(size.x - 96.0, 640.0, 1240.0)
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
	col.add_theme_constant_override("separation", 14)
	pad.add_child(col)

	col.add_child(_build_header())
	col.add_child(_make_rule())
	col.add_child(_build_body())
	col.add_child(_make_rule())
	col.add_child(_build_footer())


func _build_header() -> Control:
	var ring: Color = OmenVisuals.ring_color(_omen)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var box: float = CAPSULE_D + OmenVisuals.GLOW_PAD * 2.0
	var capsule_host := Control.new()
	capsule_host.custom_minimum_size = Vector2(box, box)
	capsule_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	capsule_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Art-only — name, effect, and rarity stars live in the text column beside it.
	capsule_host.add_child(OmenVisuals.build_capsule(_omen, CAPSULE_D, OmenVisuals.GLOW_PAD, false))
	row.add_child(capsule_host)

	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 4)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(titles)

	var kicker := Label.new()
	kicker.text = "ANOINT A CARD"
	kicker.add_theme_font_override("font", FontManager.make_font("primary", 600))
	kicker.add_theme_font_size_override("font_size", 13)
	kicker.add_theme_color_override("font_color", Color(ring.r, ring.g, ring.b, 0.9))
	titles.add_child(kicker)

	var title := Label.new()
	title.text = str(_omen.get("label", _omen.get("id", "Omen")))
	title.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", ring.lightened(0.45))
	titles.add_child(title)

	var desc := Label.new()
	desc.text = str(_omen.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_override("font", FontManager.make_font("primary", 400))
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0, 0.96))
	titles.add_child(desc)

	var stars: Control = OmenVisuals.build_rarity_stars(_omen, 15)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	titles.add_child(stars)

	var req: String = _requirement_text()
	if not req.is_empty():
		var req_lbl := Label.new()
		req_lbl.text = "Eligible: %s  (%d)" % [req, _eligible.size()]
		req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		req_lbl.add_theme_font_override("font", FontManager.make_font("primary", 400))
		req_lbl.add_theme_font_size_override("font_size", 14)
		req_lbl.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0, 0.9))
		titles.add_child(req_lbl)
	return row


## Plain-language version of anoint_card_type + anoint_filter, so the player can
## see why the grid holds these cards and not others.
func _requirement_text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	var card_type: String = str(_omen.get("anoint_card_type", "")).strip_edges().to_lower()
	match card_type:
		"unit":
			parts.append("Units")
		"trap":
			parts.append("Traps")
		"tech":
			parts.append("Tech Cards")
		_:
			parts.append("Cards")

	var filt: Variant = _omen.get("anoint_filter", {})
	if filt is Dictionary:
		var f: Dictionary = filt as Dictionary
		if f.has("affinity"):
			parts.append("of %s affinity" % str(f.get("affinity", "")).capitalize())
		if bool(f.get("ability_none", false)):
			parts.append("with no ability")
		if f.has("cost_max"):
			parts.append("costing %d or less" % int(f.get("cost_max", 0)))
		if f.has("cost_min"):
			parts.append("costing %d or more" % int(f.get("cost_min", 0)))
		if f.has("stat_sum_max"):
			parts.append("with ATK + DEF of %d or less" % int(f.get("stat_sum_max", 0)))
		if f.has("name_contains"):
			parts.append("named like \"%s\"" % str(f.get("name_contains", "")))
		if f.has("name_contains_any"):
			var any_list: Variant = f.get("name_contains_any", [])
			if any_list is Array and not (any_list as Array).is_empty():
				var quoted: PackedStringArray = PackedStringArray()
				for fragment: Variant in any_list as Array:
					quoted.append("\"%s\"" % str(fragment))
				parts.append("named like %s" % " or ".join(quoted))
	return " ".join(parts) + " in your deck"


func _build_body() -> Control:
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)

	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	scroll.add_child(flow)

	for i: int in range(_eligible.size()):
		if not _eligible[i] is Dictionary:
			continue
		flow.add_child(_make_tile(i))

	body.add_child(_build_preview_pane())
	return body


func _build_preview_pane() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PREVIEW_W, 0.0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.035, 0.085, 0.95)
	sb.border_color = Color(0.35, 0.62, 1.0, 0.28)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(14.0)
	panel.add_theme_stylebox_override("panel", sb)

	_preview_host = VBoxContainer.new()
	_preview_host.add_theme_constant_override("separation", 10)
	_preview_host.clip_contents = true
	panel.add_child(_preview_host)
	return panel


func _build_footer() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var hint := Label.new()
	hint.text = "Tap a card to preview it, or open the full card to read it in detail. The Omen stays bound to your choice for the whole chapter."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hint.add_theme_font_override("font", FontManager.make_font("primary", 400))
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.72, 0.80, 0.92, 0.9))
	row.add_child(hint)

	_confirm_btn = Button.new()
	_confirm_btn.text = "ANOINT THIS CARD"
	_confirm_btn.disabled = true
	GameDialog.style_button(_confirm_btn)
	# style_button imposes its own sizing; restate ours after it.
	_confirm_btn.custom_minimum_size = Vector2(224.0, 46.0)
	_confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_confirm_btn.pressed.connect(_on_confirm)
	row.add_child(_confirm_btn)
	return row


func _make_rule() -> Control:
	var rule := ColorRect.new()
	rule.color = Color(0.45, 0.70, 1.0, 0.22)
	rule.custom_minimum_size = Vector2(0.0, 1.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


# ─────────────────────────────────────────────────────────────
# Card grid
# ─────────────────────────────────────────────────────────────

func _make_tile(index: int) -> Control:
	var card: Dictionary = _eligible[index] as Dictionary
	var card_name: String = str(card.get("name", ""))

	var tile := Control.new()
	tile.custom_minimum_size = TILE
	tile.size = TILE
	tile.pivot_offset = TILE * 0.5
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.clip_contents = true
	tile.modulate = Color(0.70, 0.74, 0.82, 1.0)

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
		tile.add_child(_make_art_fallback(card_name))

	var frame := Panel.new()
	frame.name = "SelectFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _tile_frame_style(false))
	tile.add_child(frame)

	tile.gui_input.connect(func(ev: InputEvent) -> void:
		if not (ev is InputEventMouseButton):
			return
		var mb := ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
			return
		if not _input_enabled:
			return
		if mb.double_click:
			_open_full_card(card_name)
		else:
			SFXManager.play(SFXManager.SFX_EXPLORATION)
			_select(index))
	tile.mouse_entered.connect(func() -> void: _hover_tile(tile, true))
	tile.mouse_exited.connect(func() -> void: _hover_tile(tile, false))

	_tiles.append(tile)
	return tile


func _tile_frame_style(selected: bool) -> StyleBoxFlat:
	var ring: Color = OmenVisuals.ring_color(_omen)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = ring if selected else Color(0.35, 0.62, 1.0, 0.28)
	sb.set_border_width_all(3 if selected else 1)
	sb.set_corner_radius_all(5)
	return sb


func _hover_tile(tile: Control, entering: bool) -> void:
	if tile == null or not is_instance_valid(tile):
		return
	var selected: bool = bool(tile.get_meta("selected", false))
	var target: float = 1.06 if entering else (1.0 if selected else 0.98)
	var tw: Tween = create_tween()
	tw.tween_property(tile, "scale", Vector2.ONE * target, 0.10) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _select(index: int) -> void:
	if index < 0 or index >= _eligible.size():
		return
	_selected = index
	for i: int in range(_tiles.size()):
		var tile: Control = _tiles[i]
		if tile == null or not is_instance_valid(tile):
			continue
		var on: bool = i == index
		tile.set_meta("selected", on)
		tile.modulate = Color(1, 1, 1, 1) if on else Color(0.70, 0.74, 0.82, 1.0)
		var frame := tile.get_node_or_null("SelectFrame") as Panel
		if frame != null:
			frame.add_theme_stylebox_override("panel", _tile_frame_style(on))
		var tw: Tween = create_tween()
		tw.tween_property(tile, "scale", Vector2.ONE * (1.0 if on else 0.98), 0.12) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _confirm_btn != null:
		_confirm_btn.disabled = false
		GameDialog.sync_button_chrome_disabled(_confirm_btn)
	_rebuild_preview()


# ─────────────────────────────────────────────────────────────
# Preview pane
# ─────────────────────────────────────────────────────────────

func _rebuild_preview() -> void:
	if _preview_host == null:
		return
	# Immediate free — queue_free leaves old art in the VBox for a frame and it
	# can paint outside the pane (the clipped full-card fragment on the left).
	for child: Node in _preview_host.get_children():
		_preview_host.remove_child(child)
		child.free()
	if _selected < 0 or _selected >= _eligible.size():
		return
	var card: Dictionary = _eligible[_selected] as Dictionary
	var card_name: String = str(card.get("name", ""))

	# Compact thumb only — the real card lives in CardDetailOverlay.
	var thumb_wrap := CenterContainer.new()
	thumb_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_host.add_child(thumb_wrap)

	var thumb := Control.new()
	thumb.custom_minimum_size = Vector2(168.0, 168.0 / CARD_ASPECT)
	thumb.size = thumb.custom_minimum_size
	thumb.clip_contents = true
	thumb.mouse_filter = Control.MOUSE_FILTER_STOP
	thumb_wrap.add_child(thumb)

	var tex: Texture2D = _load_card_tex(card_name)
	if tex != null:
		var art := TextureRect.new()
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.texture = tex
		thumb.add_child(art)
	else:
		thumb.add_child(_make_art_fallback(card_name))

	var thumb_frame := Panel.new()
	thumb_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	thumb_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_sb := StyleBoxFlat.new()
	frame_sb.bg_color = Color(0, 0, 0, 0)
	frame_sb.border_color = Color(0.45, 0.72, 1.0, 0.45)
	frame_sb.set_border_width_all(1)
	frame_sb.set_corner_radius_all(5)
	thumb_frame.add_theme_stylebox_override("panel", frame_sb)
	thumb.add_child(thumb_frame)

	thumb.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed \
				and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			_open_full_card(card_name))

	var name_lbl := Label.new()
	name_lbl.text = card_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	_preview_host.add_child(name_lbl)

	var chips := HFlowContainer.new()
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	for chip: Control in _stat_chips(card):
		chips.add_child(chip)
	_preview_host.add_child(chips)

	var view_btn := Button.new()
	view_btn.text = "VIEW FULL CARD"
	GameDialog.style_button(view_btn)
	view_btn.custom_minimum_size = Vector2(0.0, 40.0)
	view_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view_btn.pressed.connect(func() -> void: _open_full_card(card_name))
	_preview_host.add_child(view_btn)


func _stat_chips(card: Dictionary) -> Array[Control]:
	var chips: Array[Control] = []
	var card_type: String = str(card.get("type", "unit")).to_lower()
	match card_type:
		"trap":
			chips.append(_make_chip("TRAP", Color(1.0, 0.62, 0.42)))
		"tech":
			chips.append(_make_chip("TECH", Color(0.55, 0.85, 1.0)))
		_:
			chips.append(_make_chip("UNIT", Color(0.55, 0.78, 1.0)))
	var affinity: String = str(card.get("affinity", "")).strip_edges()
	if not affinity.is_empty():
		chips.append(_make_chip(affinity.to_upper(), Color(0.78, 0.62, 1.0)))
	if card.has("cost"):
		chips.append(_make_chip("COST %d" % int(card.get("cost", 0)), Color(1.0, 0.88, 0.42)))
	if card_type == "unit":
		chips.append(_make_chip("ATK %d" % int(card.get("atk", 0)), Color(1.0, 0.52, 0.45)))
		chips.append(_make_chip("DEF %d" % int(card.get("def", 0)), Color(0.45, 0.80, 1.0)))
	return chips


func _make_chip(text: String, tint: Color) -> Control:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(0.0, 24.0)
	lbl.add_theme_font_override("font", FontManager.make_font("primary", 600))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", tint.lightened(0.3))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(tint.r, tint.g, tint.b, 0.12)
	sb.border_color = Color(tint.r, tint.g, tint.b, 0.6)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(11)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	lbl.add_theme_stylebox_override("normal", sb)
	return lbl


func _make_art_fallback(card_name: String) -> Control:
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.07, 0.14, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(bg)
	var lbl := Label.new()
	lbl.text = card_name
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(lbl)
	return host


func _open_full_card(card_name: String) -> void:
	if card_name.is_empty():
		return
	if _detail != null and is_instance_valid(_detail):
		return
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	# Same Full Card Info Overlay used by View Deck / Deck Builder. Pin to this
	# full-screen picker so layout/z-order stay correct above the anoint chrome.
	_detail = CardDetailOverlay.open_and_return(
			self, card_name, _detail_card_type(card_name),
			null, false, true, z_index + 40)
	if _detail != null:
		_detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_detail.position = Vector2.ZERO
		_detail.size = size
		_detail.tree_exiting.connect(func() -> void: _detail = null, CONNECT_ONE_SHOT)


## Eligible entries use the omen vocabulary ("unit"); CardDetailOverlay uses the
## card database vocabulary ("character").
func _detail_card_type(card_name: String) -> String:
	if CardDatabase.get_trap(card_name) != null:
		return "trap"
	if CardDatabase.get_tech(card_name) != null:
		return "tech"
	return "character"


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
	await _settle_layout()
	if _panel == null or not is_instance_valid(_panel):
		return
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_dim, "color:a", 0.84, 0.22) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.26) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	_input_enabled = true


func _on_confirm() -> void:
	if not _input_enabled or _selected < 0 or _selected >= _eligible.size():
		return
	var card_name: String = str((_eligible[_selected] as Dictionary).get("name", ""))
	if card_name.is_empty():
		return
	_input_enabled = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	SFXManager.play(SFXManager.SFX_EXPLORATION_ITEM)

	var tile: Control = _tiles[_selected] if _selected < _tiles.size() else null
	if tile != null and is_instance_valid(tile):
		var pulse: Tween = create_tween()
		pulse.tween_property(tile, "scale", Vector2(1.12, 1.12), 0.10) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pulse.tween_property(tile, "scale", Vector2.ONE, 0.10) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await pulse.finished

	var fade: Tween = create_tween()
	fade.set_parallel(true)
	fade.tween_property(_dim, "color:a", 0.0, 0.18)
	fade.tween_property(_panel, "modulate:a", 0.0, 0.18)
	await fade.finished

	picked.emit(card_name)
	queue_free()
