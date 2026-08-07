extends Control
class_name OmenDetailOverlay
## Codex of active Omens — capsule grid on the left, full dossier on the right.
## Opened from exploration Info radial and battle Options → Omens.

signal closed()

const FULL_CARDS_DIR: String = "res://assets/textures/cards/full_cards/"

const CAPSULE_D: float = 190.0
const DETAIL_W: float = 372.0
const BANNER_H: float = 152.0
const CARD_THUMB: Vector2 = Vector2(94.0, 128.0)

const FOOTER_TEXT: String = (
	"Omens remain in effect until the chapter ends. Multiple Omens can be accumulated."
)

const _RARITY_LABEL: Dictionary = {
	"common": "Common",
	"uncommon": "Uncommon",
	"rare": "Rare",
	"epic": "Epic",
}

var _rows: Array = []
var _selected: int = -1
var _z: int = 210
## When true, only show player-owned omens (e.g. exploration contexts).
var _player_only: bool = false

var _dim: ColorRect = null
var _panel: PanelContainer = null
var _detail_host: VBoxContainer = null
var _subtitle: Label = null
var _capsule_hosts: Array = []


static func open(
		parent: Node,
		z_index_override: int = 210,
		player_only: bool = false) -> OmenDetailOverlay:
	if parent == null:
		return null
	var existing: Node = parent.get_node_or_null("OmenDetailOverlay")
	if existing != null and is_instance_valid(existing):
		return existing as OmenDetailOverlay
	var overlay := OmenDetailOverlay.new()
	overlay.name = "OmenDetailOverlay"
	overlay._z = z_index_override
	overlay._player_only = player_only
	parent.add_child(overlay)
	return overlay


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = _viewport_size()
	z_index = _z
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rows = _load_rows()

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


func _load_rows() -> Array:
	var rows: Array = OmenVisuals.held_rows()
	var mine: Array = []
	var hostile: Array = []
	for row: Variant in rows:
		var entry: Dictionary = (row as Dictionary).get("entry", {}) as Dictionary
		var owner: int = int(entry.get("owner", 0))
		if _player_only and owner != 0:
			continue
		if owner == 1:
			hostile.append(row)
		else:
			mine.append(row)
	# Player omens first; enemy omens follow (divider drawn between sections in the grid).
	var ordered: Array = []
	ordered.append_array(mine)
	ordered.append_array(hostile)
	return ordered


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
		if str(entry.get("anointed_card", "")).strip_edges().is_empty():
			continue
		# Enemy binds only count once the target is public knowledge.
		if not OmenVisuals.anoint_target_is_public(entry):
			continue
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

	var list_col := VBoxContainer.new()
	list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_col.add_theme_constant_override("separation", 12)
	scroll.add_child(list_col)

	_capsule_hosts.clear()

	var mine_indices: Array[int] = []
	var hostile_indices: Array[int] = []
	for i: int in range(_rows.size()):
		var entry: Dictionary = (_rows[i] as Dictionary).get("entry", {}) as Dictionary
		if int(entry.get("owner", 0)) == 1:
			hostile_indices.append(i)
		else:
			mine_indices.append(i)

	if not mine_indices.is_empty():
		list_col.add_child(_build_capsule_flow(mine_indices))

	if not hostile_indices.is_empty():
		if not mine_indices.is_empty():
			list_col.add_child(_build_enemy_divider())
		list_col.add_child(_build_capsule_flow(hostile_indices))

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


func _build_capsule_flow(indices: Array[int]) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for i: int in indices:
		flow.add_child(_build_capsule_host(i))
	return flow


func _build_enemy_divider() -> Control:
	var wrap := VBoxContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_theme_constant_override("separation", 8)

	var rule := ColorRect.new()
	rule.color = Color(1.0, 0.42, 0.38, 0.45)
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(rule)

	var lbl := Label.new()
	lbl.text = "ENEMY OMENS"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", FontManager.make_font("primary", 600))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.48, 0.92))
	wrap.add_child(lbl)
	return wrap


# ─────────────────────────────────────────────────────────────
# Capsule grid
# ─────────────────────────────────────────────────────────────

func _build_capsule_host(index: int) -> Control:
	var row: Dictionary = _rows[index] as Dictionary
	var omen: Dictionary = row.get("omen", {}) as Dictionary
	var entry: Dictionary = row.get("entry", {}) as Dictionary
	var hostile: bool = int(entry.get("owner", 0)) == 1
	var box: float = CAPSULE_D + OmenVisuals.GLOW_PAD * 2.0

	var host := Control.new()
	host.custom_minimum_size = Vector2(box, box)
	host.size = Vector2(box, box)
	host.pivot_offset = Vector2(box, box) * 0.5
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	host.modulate = Color(0.74, 0.78, 0.86, 1.0)
	var ring_override: Color = OmenVisuals.hostile_ring_color(omen) if hostile \
			else Color(0, 0, 0, 0)
	host.add_child(OmenVisuals.build_capsule(omen, CAPSULE_D, OmenVisuals.GLOW_PAD, true, ring_override))

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

	# Rows are ordered player-then-enemy; sections build in that same index order.
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
	var hostile: bool = int(entry.get("owner", 0)) == 1
	var ring: Color = OmenVisuals.hostile_ring_color(omen) if hostile \
			else OmenVisuals.ring_color(omen)
	var is_anoint: bool = OmenDatabase.is_anoint(omen)
	var anointed: String = str(entry.get("anointed_card", "")).strip_edges()

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
	if hostile:
		chips.add_child(_make_chip("HOSTILE", Color(1.0, 0.42, 0.38)))
	elif _has_hostile_rows():
		chips.add_child(_make_chip("YOURS", Color(0.45, 0.78, 1.0)))
	var positive: Variant = omen.get("positive", null)
	if positive != null:
		if bool(positive):
			chips.add_child(_make_chip("BOON", Color(0.36, 0.88, 0.52)))
		else:
			chips.add_child(_make_chip("BANE", Color(1.0, 0.42, 0.42)))
	if is_anoint:
		chips.add_child(_make_chip("ANOINT", Color(0.92, 0.72, 0.38)))
	var rarity_key: String = str(omen.get("rarity", "common")).to_lower()
	var rarity_lbl: String = str(_RARITY_LABEL.get(rarity_key, rarity_key.capitalize()))
	chips.add_child(_make_chip(rarity_lbl.to_upper(), ring))
	# groups[] (rites, chapter_1, …) are author-only offer filters — not shown to players.
	_detail_host.add_child(chips)

	_detail_host.add_child(_make_section_label("EFFECT", ring))
	var desc := Label.new()
	desc.text = str(omen.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_override("font", FontManager.make_font("primary", 400))
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0, 0.96))
	_detail_host.add_child(desc)

	var stars: Control = OmenVisuals.build_rarity_stars(omen, 15)
	if stars is Label:
		(stars as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if hostile:
			(stars as Label).add_theme_color_override("font_color",
					Color(ring.r, ring.g, ring.b, 0.72))
	_detail_host.add_child(stars)

	if is_anoint:
		_detail_host.add_child(_make_rule())
		_detail_host.add_child(_make_section_label("BOUND CARD", ring))
		if anointed.is_empty():
			_detail_host.add_child(_build_bind_status(
					"No card bound yet.",
					"This Anoint has not been attached to a card.",
					ring))
		elif OmenVisuals.anoint_target_is_public(entry):
			_detail_host.add_child(_build_anointed_block(anointed, ring))
		else:
			# Keep enemy face-down binds sealed — show status, never the name.
			_detail_host.add_child(_build_concealed_bind_block(ring))

	var intel_rows: Array = OmenBattleApplier.intel_for_omen(
			str(omen.get("id", entry.get("id", ""))))
	if not intel_rows.is_empty():
		_detail_host.add_child(_make_rule())
		_detail_host.add_child(_make_section_label("REVEALED INTEL", ring))
		for intel_v: Variant in intel_rows:
			if not intel_v is Dictionary:
				continue
			_detail_host.add_child(_build_intel_block(intel_v as Dictionary, ring))


func _build_intel_block(intel: Dictionary, ring: Color) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var kind: String = str(intel.get("kind", "")).strip_edges().to_lower()
	var etype: String = str(intel.get("type", ""))
	var emoji: String = str(intel.get("emoji", "")).strip_edges()
	if etype == "reveal_enemy_bluff_preference" and not emoji.is_empty():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		box.add_child(row)
		var badge := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		var interested: bool = kind != "avoid"
		var tint: Color = Color(0.28, 0.92, 0.55) if interested else Color(1.0, 0.42, 0.38)
		sb.bg_color = Color(tint.r, tint.g, tint.b, 0.18)
		sb.border_color = Color(tint.r, tint.g, tint.b, 0.8)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(10.0)
		badge.add_theme_stylebox_override("panel", sb)
		row.add_child(badge)
		var icon_tex: Texture2D = BluffEmoji.tex(emoji)
		if icon_tex != null:
			var art := TextureRect.new()
			art.custom_minimum_size = Vector2(36.0, 36.0)
			art.texture = icon_tex
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.add_child(art)
		else:
			# Texture missing — leave badge empty rather than showing unicode.
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(36.0, 36.0)
			badge.add_child(spacer)
		var meta := VBoxContainer.new()
		meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		meta.add_theme_constant_override("separation", 3)
		row.add_child(meta)
		var tag := Label.new()
		tag.text = "INTERESTED BY ENEMY" if interested else "AVOIDED BY ENEMY"
		tag.add_theme_font_override("font", FontManager.make_font("primary", 600))
		tag.add_theme_font_size_override("font_size", 12)
		tag.add_theme_color_override("font_color", tint.lightened(0.2))
		meta.add_child(tag)
		var body := Label.new()
		body.text = str(intel.get("text", ""))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_override("font", FontManager.make_font("primary", 400))
		body.add_theme_font_size_override("font_size", 14)
		body.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0, 0.96))
		meta.add_child(body)
		var tw: Tween = badge.create_tween().set_loops()
		tw.tween_property(badge, "modulate", Color(1.12, 1.12, 1.12, 1.0), 0.55) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(badge, "modulate", Color(1, 1, 1, 1), 0.55) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		return box
	var body2 := Label.new()
	body2.text = str(intel.get("text", ""))
	body2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body2.add_theme_font_override("font", FontManager.make_font("primary", 400))
	body2.add_theme_font_size_override("font_size", 15)
	body2.add_theme_color_override("font_color", ring.lightened(0.35))
	box.add_child(body2)
	return box


func _has_hostile_rows() -> bool:
	for row: Variant in _rows:
		var entry: Dictionary = (row as Dictionary).get("entry", {}) as Dictionary
		if int(entry.get("owner", 0)) == 1:
			return true
	return false


func _make_section_label(text: String, tint: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", FontManager.make_font("primary", 600))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color",
			Color(tint.r, tint.g, tint.b, 0.85).lightened(0.15))
	return lbl


func _build_bind_status(title: String, body: String, ring: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var accent := ColorRect.new()
	accent.custom_minimum_size = Vector2(3.0, 0.0)
	accent.size_flags_vertical = Control.SIZE_EXPAND_FILL
	accent.color = Color(ring.r, ring.g, ring.b, 0.75)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(accent)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	row.add_child(box)
	var head := Label.new()
	head.text = title
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_theme_font_override("font", FontManager.make_font("primary", 600))
	head.add_theme_font_size_override("font_size", 15)
	head.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))
	box.add_child(head)
	var hint := Label.new()
	hint.text = body
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_override("font", FontManager.make_font("primary", 400))
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.66, 0.74, 0.88, 0.9))
	box.add_child(hint)
	return row


func _build_concealed_bind_block(ring: Color) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)

	var silhouette := Panel.new()
	silhouette.custom_minimum_size = CARD_THUMB
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.12, 0.95)
	sb.border_color = Color(ring.r, ring.g, ring.b, 0.45)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	silhouette.add_theme_stylebox_override("panel", sb)
	row.add_child(silhouette)

	var mark := Label.new()
	mark.text = "?"
	mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	mark.add_theme_font_size_override("font_size", 36)
	mark.add_theme_color_override("font_color", Color(ring.r, ring.g, ring.b, 0.55))
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	silhouette.add_child(mark)

	var meta := VBoxContainer.new()
	meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_theme_constant_override("separation", 4)
	row.add_child(meta)

	var name_lbl := Label.new()
	name_lbl.text = "Concealed card"
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_override("font", FontManager.make_font("primary", 600))
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	meta.add_child(name_lbl)

	var hint := Label.new()
	hint.text = "Bound to an opposing card that has not been revealed."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_override("font", FontManager.make_font("primary", 400))
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.66, 0.74, 0.88, 0.9))
	meta.add_child(hint)
	return box


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

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)

	var thumb := Button.new()
	thumb.custom_minimum_size = CARD_THUMB
	thumb.flat = true
	thumb.focus_mode = Control.FOCUS_NONE
	thumb.clip_contents = true
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.04, 0.05, 0.10, 0.9)
	frame.border_color = Color(ring.r, ring.g, ring.b, 0.55)
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(4)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		thumb.add_theme_stylebox_override(state, frame)
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
	meta.alignment = BoxContainer.ALIGNMENT_CENTER
	meta.add_theme_constant_override("separation", 4)
	row.add_child(meta)

	var name_lbl := Label.new()
	name_lbl.text = card_name
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_override("font", FontManager.make_font("primary", 600))
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	meta.add_child(name_lbl)

	var type_lbl := Label.new()
	type_lbl.text = _card_type_label(card_name)
	type_lbl.add_theme_font_override("font", FontManager.make_font("primary", 600))
	type_lbl.add_theme_font_size_override("font_size", 12)
	type_lbl.add_theme_color_override("font_color", ring.lightened(0.25))
	meta.add_child(type_lbl)

	var hint := Label.new()
	hint.text = "Tap to inspect this card."
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


func _card_type_label(card_name: String) -> String:
	match _card_type_of(card_name):
		"trap":
			return "Trap"
		"tech":
			return "Tech"
		"union":
			return "Union"
		_:
			return "Character"


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
