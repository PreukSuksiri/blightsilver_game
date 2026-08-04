extends Control
class_name OmenDetailOverlay
## Codex of the Omens the player currently holds — capsule grid on the left,
## full dossier on the right. Opened from the exploration Info radial.

signal closed()

const FULL_CARDS_DIR: String = "res://assets/textures/cards/full_cards/"

const CAPSULE_D: float = 190.0
const DETAIL_W: float = 372.0
const BANNER_H: float = 152.0
const CARD_THUMB: Vector2 = Vector2(94.0, 128.0)

const FOOTER_TEXT: String = (
	"Omens remain in effect until the chapter ends. Multiple Omens can be accumulated."
)

var _rows: Array = []
var _selected: int = -1
var _z: int = 210

var _dim: ColorRect = null
var _panel: PanelContainer = null
var _grid: HFlowContainer = null
var _detail_host: VBoxContainer = null
var _subtitle: Label = null
var _capsule_hosts: Array[Control] = []


static func open(parent: Node, z_index_override: int = 210) -> OmenDetailOverlay:
	if parent == null:
		return null
	var existing: Node = parent.get_node_or_null("OmenDetailOverlay")
	if existing != null and is_instance_valid(existing):
		return existing as OmenDetailOverlay
	var overlay := OmenDetailOverlay.new()
	overlay.name = "OmenDetailOverlay"
	overlay._z = z_index_override
	parent.add_child(overlay)
	return overlay


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = _viewport_size()
	z_index = _z
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rows = OmenVisuals.held_rows()

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

	if not _rows.is_empty():
		_select(0)
	_play_intro()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		accept_event()
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
		var w: float = clampf(size.x - 96.0, 640.0, 1240.0)
		var h: float = clampf(size.y - 76.0, 420.0, 820.0)
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

	if _rows.is_empty():
		col.add_child(_build_empty_state())
	else:
		col.add_child(_build_body())

	var footer := Label.new()
	footer.text = FOOTER_TEXT
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_theme_font_override("font", FontManager.make_font("primary", 400))
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(0.72, 0.80, 0.92, 0.88))
	col.add_child(footer)


func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(titles)

	var title := Label.new()
	title.text = "Omens"
	title.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0))
	titles.add_child(title)

	_subtitle = Label.new()
	_subtitle.text = _summary_text()
	_subtitle.add_theme_font_override("font", FontManager.make_font("primary", 400))
	_subtitle.add_theme_font_size_override("font_size", 15)
	_subtitle.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0, 0.92))
	titles.add_child(_subtitle)

	var close_btn := Button.new()
	close_btn.custom_minimum_size = Vector2(38.0, 38.0)
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	MenuScreenHeader.style_close_button(close_btn)
	close_btn.pressed.connect(_close)
	row.add_child(close_btn)
	return row


func _summary_text() -> String:
	if _rows.is_empty():
		return "No Omens held this chapter."
	var anointed: int = 0
	for row: Variant in _rows:
		var entry: Dictionary = (row as Dictionary).get("entry", {}) as Dictionary
		if not str(entry.get("anointed_card", "")).strip_edges().is_empty():
			anointed += 1
	if anointed <= 0:
		return "%d held this chapter." % _rows.size()
	return "%d held this chapter — %d bound to a card." % [_rows.size(), anointed]


func _make_rule() -> Control:
	var rule := ColorRect.new()
	rule.color = Color(0.45, 0.70, 1.0, 0.22)
	rule.custom_minimum_size = Vector2(0.0, 1.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


func _build_empty_state() -> Control:
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)

	var head := Label.new()
	head.text = "No Omens yet"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	head.add_theme_font_size_override("font_size", 24)
	head.add_theme_color_override("font_color", Color(0.78, 0.84, 0.94))
	box.add_child(head)

	var hint := Label.new()
	hint.text = "Investigate this chapter's locations — some will reveal an Omen to claim."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_override("font", FontManager.make_font("primary", 400))
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.66, 0.74, 0.88, 0.9))
	box.add_child(hint)
	return box


func _build_body() -> Control:
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)

	_grid = HFlowContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.alignment = FlowContainer.ALIGNMENT_CENTER
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)

	for i: int in range(_rows.size()):
		_grid.add_child(_build_capsule_host(i))

	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(DETAIL_W, 0.0)
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.035, 0.085, 0.95)
	sb.border_color = Color(0.35, 0.62, 1.0, 0.28)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(16.0)
	detail_panel.add_theme_stylebox_override("panel", sb)
	body.add_child(detail_panel)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_panel.add_child(detail_scroll)

	_detail_host = VBoxContainer.new()
	_detail_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_host.add_theme_constant_override("separation", 10)
	detail_scroll.add_child(_detail_host)
	return body


# ─────────────────────────────────────────────────────────────
# Capsule grid
# ─────────────────────────────────────────────────────────────

func _build_capsule_host(index: int) -> Control:
	var omen: Dictionary = (_rows[index] as Dictionary).get("omen", {}) as Dictionary
	var box: float = CAPSULE_D + OmenVisuals.GLOW_PAD * 2.0

	var host := Control.new()
	host.custom_minimum_size = Vector2(box, box)
	host.size = Vector2(box, box)
	host.pivot_offset = Vector2(box, box) * 0.5
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	host.modulate = Color(0.74, 0.78, 0.86, 1.0)
	host.add_child(OmenVisuals.build_capsule(omen, CAPSULE_D))

	var hit := Button.new()
	hit.size = Vector2(box, box)
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		hit.add_theme_stylebox_override(state, empty)
	hit.pressed.connect(func() -> void:
		SFXManager.play(SFXManager.SFX_EXPLORATION)
		_select(index))
	hit.mouse_entered.connect(func() -> void: _hover(host, true))
	hit.mouse_exited.connect(func() -> void: _hover(host, false))
	host.add_child(hit)

	_capsule_hosts.append(host)
	return host


func _hover(host: Control, entering: bool) -> void:
	if host == null or not is_instance_valid(host):
		return
	var target: float = 1.05 if entering else (1.0 if host.get_meta("selected", false) else 0.97)
	var tw: Tween = create_tween()
	tw.tween_property(host, "scale", Vector2.ONE * target, 0.12) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _select(index: int) -> void:
	if index < 0 or index >= _rows.size():
		return
	_selected = index
	for i: int in range(_capsule_hosts.size()):
		var host: Control = _capsule_hosts[i]
		if host == null or not is_instance_valid(host):
			continue
		var on: bool = i == index
		host.set_meta("selected", on)
		host.modulate = Color(1, 1, 1, 1) if on else Color(0.74, 0.78, 0.86, 1.0)
		var tw: Tween = create_tween()
		tw.tween_property(host, "scale", Vector2.ONE * (1.0 if on else 0.97), 0.14) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_rebuild_detail()


# ─────────────────────────────────────────────────────────────
# Detail pane
# ─────────────────────────────────────────────────────────────

func _rebuild_detail() -> void:
	if _detail_host == null:
		return
	for child: Node in _detail_host.get_children():
		child.queue_free()
	if _selected < 0 or _selected >= _rows.size():
		return
	var row: Dictionary = _rows[_selected] as Dictionary
	var omen: Dictionary = row.get("omen", {}) as Dictionary
	var entry: Dictionary = row.get("entry", {}) as Dictionary
	var ring: Color = OmenVisuals.ring_color(omen)

	_detail_host.add_child(_build_banner(omen, ring))

	var name_lbl := Label.new()
	name_lbl.text = str(omen.get("label", omen.get("id", "Omen")))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", ring.lightened(0.45))
	_detail_host.add_child(name_lbl)

	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	var positive: Variant = omen.get("positive", null)
	if positive != null:
		if bool(positive):
			chips.add_child(_make_chip("BOON", Color(0.36, 0.88, 0.52)))
		else:
			chips.add_child(_make_chip("BANE", Color(1.0, 0.42, 0.42)))
	# groups[] (rites, chapter_1, …) are author-only offer filters — not shown to players.
	if chips.get_child_count() > 0:
		_detail_host.add_child(chips)

	var desc := Label.new()
	desc.text = str(omen.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_override("font", FontManager.make_font("primary", 400))
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0, 0.96))
	_detail_host.add_child(desc)

	var stars: Control = OmenVisuals.build_rarity_stars(omen, 15)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_detail_host.add_child(stars)

	var anointed: String = str(entry.get("anointed_card", "")).strip_edges()
	if not anointed.is_empty():
		_detail_host.add_child(_make_rule())
		_detail_host.add_child(_build_anointed_block(anointed, ring))


func _build_banner(omen: Dictionary, ring: Color) -> Control:
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(0.0, BANNER_H)
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var illus: String = str(omen.get("illustration", "")).strip_edges()
	if not illus.is_empty() and ResourceLoader.exists(illus):
		art.texture = load(illus) as Texture2D
	else:
		art.texture = OmenVisuals.make_placeholder_art_tex(ring)
		art.stretch_mode = TextureRect.STRETCH_SCALE
	frame.add_child(art)

	# Bottom scrim so the name below always reads against busy artwork.
	var scrim := ColorRect.new()
	scrim.color = Color(0.02, 0.03, 0.07, 0.55)
	scrim.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	scrim.offset_top = -34.0
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(scrim)

	var edge := Panel.new()
	edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(ring.r, ring.g, ring.b, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	edge.add_theme_stylebox_override("panel", sb)
	frame.add_child(edge)
	return frame


func _make_chip(text: String, tint: Color) -> Control:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(0.0, 24.0)
	lbl.add_theme_font_override("font", FontManager.make_font("primary", 600))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", tint.lightened(0.35))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(tint.r, tint.g, tint.b, 0.12)
	sb.border_color = Color(tint.r, tint.g, tint.b, 0.65)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(11)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	lbl.add_theme_stylebox_override("normal", sb)
	return lbl


func _build_anointed_block(card_name: String, ring: Color) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var hdr := Label.new()
	hdr.text = "Bound to"
	hdr.add_theme_font_override("font", FontManager.make_font("primary", 600))
	hdr.add_theme_font_size_override("font_size", 14)
	hdr.add_theme_color_override("font_color", ring.lightened(0.3))
	box.add_child(hdr)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)

	var thumb := Button.new()
	thumb.custom_minimum_size = CARD_THUMB
	thumb.flat = true
	thumb.focus_mode = Control.FOCUS_NONE
	thumb.clip_contents = true
	var empty := StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		thumb.add_theme_stylebox_override(state, empty)
	thumb.pressed.connect(func() -> void:
		SFXManager.play(SFXManager.SFX_EXPLORATION)
		CardDetailOverlay.open(self, card_name, _card_type_of(card_name),
				null, false, false, z_index + 40))
	row.add_child(thumb)

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
		var fallback := Label.new()
		fallback.text = card_name
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fallback.add_theme_font_size_override("font_size", 11)
		fallback.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumb.add_child(fallback)

	var meta := VBoxContainer.new()
	meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_theme_constant_override("separation", 4)
	row.add_child(meta)

	var name_lbl := Label.new()
	name_lbl.text = card_name
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_override("font", FontManager.make_font("primary", 600))
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	meta.add_child(name_lbl)

	var hint := Label.new()
	hint.text = "Tap the card to inspect it."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_override("font", FontManager.make_font("primary", 400))
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.66, 0.74, 0.88, 0.9))
	meta.add_child(hint)
	return box


func _card_type_of(card_name: String) -> String:
	if CardDatabase.get_trap(card_name) != null:
		return "trap"
	if CardDatabase.get_tech(card_name) != null:
		return "tech"
	if UnionDatabase.get_union(card_name) != null:
		return "union"
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
