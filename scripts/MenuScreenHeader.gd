class_name MenuScreenHeader
extends RefCounted
## Shared centered serif titles and top-right ✕ close buttons for menu screens.

const HEADER_HEIGHT := 48.0
const TITLE_FONT_SIZE := 26
const TITLE_COLOR := Color(0.40, 0.85, 1.0, 1.0)
const CLOSE_BTN_SIZE := Vector2(38.0, 38.0)
const CLOSE_INSET := 12.0
const CLOSE_BG_NORMAL := Color(0.18, 0.04, 0.04, 1.0)
const CLOSE_BG_HOVER := Color(0.28, 0.06, 0.06, 1.0)
const CLOSE_BG_PRESSED := Color(0.12, 0.02, 0.02, 1.0)
const CLOSE_BORDER := Color(1.0, 0.30, 0.30, 0.75)
const CLOSE_BORDER_HOVER := Color(1.0, 0.45, 0.45, 0.9)
const CLOSE_FONT := Color(1.0, 0.62, 0.62, 0.95)
const CLOSE_FONT_HOVER := Color(1.0, 0.78, 0.78, 1.0)


static func _make_close_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	return sb


static func style_close_button(btn: Button) -> void:
	if btn == null:
		return
	btn.custom_minimum_size = CLOSE_BTN_SIZE
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _make_close_stylebox(CLOSE_BG_NORMAL, CLOSE_BORDER))
	btn.add_theme_stylebox_override("hover", _make_close_stylebox(CLOSE_BG_HOVER, CLOSE_BORDER_HOVER))
	btn.add_theme_stylebox_override("pressed", _make_close_stylebox(CLOSE_BG_PRESSED, CLOSE_BORDER))
	btn.add_theme_stylebox_override("focus", _make_close_stylebox(CLOSE_BG_NORMAL, CLOSE_BORDER))
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", CLOSE_FONT)
	btn.add_theme_color_override("font_hover_color", CLOSE_FONT_HOVER)
	btn.add_theme_color_override("font_pressed_color", CLOSE_FONT)
	ChromeIcon.apply_button(btn, "close", false, "", CLOSE_FONT, 18)


static func style_title(label: Label, text: String = "") -> void:
	if label == null:
		return
	if not text.is_empty():
		label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FontManager.make_font("display_serif", 600))
	label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	label.add_theme_color_override("font_color", TITLE_COLOR)


static func anchor_close_top_right(btn: Button, inset: float = CLOSE_INSET) -> void:
	if btn == null:
		return
	btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left = -(inset + CLOSE_BTN_SIZE.x)
	btn.offset_top = 6.0
	btn.offset_right = -inset
	btn.offset_bottom = 6.0 + CLOSE_BTN_SIZE.y


## Replaces an HBox header with a layered bar: centered title, optional trailing row, ✕ close.
static func rebuild_panel_header(
		header: Control,
		title: Label,
		close_btn: Button,
		trailing: Array = []
) -> Dictionary:
	if header == null or title == null or close_btn == null:
		return {}
	style_title(title)
	style_close_button(close_btn)

	var parent: Node = header.get_parent()
	if parent == null:
		return {}
	var header_idx: int = header.get_index()
	var header_name: String = header.name
	var min_h: float = header.custom_minimum_size.y
	if min_h <= 0.0:
		min_h = HEADER_HEIGHT

	var detached: Array[Node] = []
	for child: Node in header.get_children():
		detached.append(child)
	for child: Node in detached:
		header.remove_child(child)
	header.name = "_MenuHeaderOld"
	header.queue_free()

	var slot := Control.new()
	slot.name = header_name
	slot.custom_minimum_size = Vector2(0.0, min_h)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(slot)
	parent.move_child(slot, header_idx)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(center)
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(title)

	var trail: HBoxContainer = null
	var trail_nodes: Array[Control] = []
	for node: Variant in trailing:
		if node is Control and is_instance_valid(node as Control):
			trail_nodes.append(node as Control)
	if not trail_nodes.is_empty():
		trail = HBoxContainer.new()
		trail.add_theme_constant_override("separation", 10)
		trail.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		trail.offset_right = -(CLOSE_INSET + CLOSE_BTN_SIZE.x + 8.0)
		trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(trail)
		for node: Control in trail_nodes:
			trail.add_child(node)

	anchor_close_top_right(close_btn)
	slot.add_child(close_btn)

	return {"root": slot, "trailing_row": trail, "close_btn": close_btn}


static func build_top_bar(parent: Control, title_text: String, on_close: Callable) -> Dictionary:
	var top_bg := Panel.new()
	top_bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bg.custom_minimum_size.y = HEADER_HEIGHT
	var top_sb := StyleBoxFlat.new()
	top_sb.bg_color = Color(0.031, 0.051, 0.122, 1.0)
	top_sb.border_width_bottom = 1
	top_sb.border_color = Color(0.18, 0.549, 1.0, 0.2)
	top_bg.add_theme_stylebox_override("panel", top_sb)
	parent.add_child(top_bg)

	var title := Label.new()
	style_title(title, title_text)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -280.0
	title.offset_top = 8.0
	title.offset_right = 280.0
	title.offset_bottom = 40.0
	parent.add_child(title)

	var close_btn := Button.new()
	style_close_button(close_btn)
	anchor_close_top_right(close_btn)
	if on_close.is_valid():
		close_btn.pressed.connect(on_close)
	parent.add_child(close_btn)

	return {"bar": top_bg, "title": title, "close_btn": close_btn}
