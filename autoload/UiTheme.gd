extends Node
## Global UI theme overrides — light scrollbars and cyan checkboxes on dark screens.

const SCROLL_THUMB := Color("#f5f5f5")
const SCROLL_THUMB_HOVER := Color("#ffffff")
const SCROLL_THUMB_PRESSED := Color("#e0e0e0")
const SCROLL_TRACK := Color(0.960784, 0.960784, 0.960784, 0.14)
const SCROLL_MIN_GRABBER := 24
const SCROLL_RADIUS := 4

const CHECKBOX_BORDER := Color(0.40, 0.85, 1.0, 1.0)
const CHECKBOX_FILL := Color(0.04, 0.06, 0.12, 0.95)
const CHECKBOX_CHECKED_FILL := Color(0.10, 0.22, 0.38, 1.0)
const CHECKBOX_MARK := Color(0.55, 0.92, 1.0, 1.0)
const CHECKBOX_FONT := Color(0.88, 0.95, 1.0, 1.0)
const CHECKBOX_FONT_HOVER := Color(1.0, 1.0, 1.0, 1.0)
const CHECKBOX_FONT_DISABLED := Color(0.55, 0.62, 0.72, 0.75)
const CHECKBOX_ICON_SIZE := 20
const CHECKBOX_BORDER_WIDTH := 2


func apply_to_control(control: Control) -> void:
	var root: Window = get_tree().root
	if root != null and root.theme != null:
		control.theme = root.theme
		return
	var theme := Theme.new()
	_apply_scrollbar_theme(theme)
	_apply_checkbox_theme(theme)
	control.theme = theme


func _ready() -> void:
	call_deferred("_apply_root_theme")


func _apply_root_theme() -> void:
	var root := get_tree().root
	if root == null:
		return
	var theme := root.theme if root.theme != null else Theme.new()
	_apply_scrollbar_theme(theme)
	_apply_checkbox_theme(theme)
	root.theme = theme


func _apply_scrollbar_theme(theme: Theme) -> void:
	var empty := StyleBoxEmpty.new()
	for bar_type: StringName in [&"ScrollBar", &"HScrollBar", &"VScrollBar"]:
		theme.set_stylebox("scroll", bar_type, _track_style())
		theme.set_stylebox("grabber", bar_type, _grabber_style(SCROLL_THUMB))
		theme.set_stylebox("grabber_highlight", bar_type, _grabber_style(SCROLL_THUMB_HOVER))
		theme.set_stylebox("grabber_pressed", bar_type, _grabber_style(SCROLL_THUMB_PRESSED))
		theme.set_constant("min_grabber_length", bar_type, SCROLL_MIN_GRABBER)
		for arrow: String in [
			"increment", "increment_highlight", "increment_pressed",
			"decrement", "decrement_highlight", "decrement_pressed"]:
			theme.set_stylebox(arrow, bar_type, empty)


func _track_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = SCROLL_TRACK
	sb.set_corner_radius_all(SCROLL_RADIUS)
	sb.set_content_margin_all(2)
	return sb


func _grabber_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(SCROLL_RADIUS)
	sb.set_content_margin_all(2)
	return sb


func _apply_checkbox_theme(theme: Theme) -> void:
	const BOX_TYPES: Array[StringName] = [&"CheckBox", &"CheckButton"]
	for box_type: StringName in BOX_TYPES:
		theme.set_icon("unchecked", box_type, _checkbox_icon(false, false, CHECKBOX_BORDER))
		theme.set_icon("checked", box_type, _checkbox_icon(true, false, CHECKBOX_BORDER))
		theme.set_icon("unchecked_disabled", box_type, _checkbox_icon(false, true, CHECKBOX_BORDER))
		theme.set_icon("checked_disabled", box_type, _checkbox_icon(true, true, CHECKBOX_BORDER))
		theme.set_color("font_color", box_type, CHECKBOX_FONT)
		theme.set_color("font_hover_color", box_type, CHECKBOX_FONT_HOVER)
		theme.set_color("font_pressed_color", box_type, CHECKBOX_FONT_HOVER)
		theme.set_color("font_hover_pressed_color", box_type, CHECKBOX_FONT_HOVER)
		theme.set_color("font_focus_color", box_type, CHECKBOX_FONT_HOVER)
		theme.set_color("font_disabled_color", box_type, CHECKBOX_FONT_DISABLED)
		theme.set_constant("h_separation", box_type, 8)
		theme.set_constant("check_v_offset", box_type, 0)


func _checkbox_icon(checked: bool, disabled: bool, border: Color) -> ImageTexture:
	var size := CHECKBOX_ICON_SIZE
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var border_color := border
	var fill := CHECKBOX_FILL if not checked else CHECKBOX_CHECKED_FILL
	if disabled:
		border_color = Color(border.r, border.g, border.b, border.a * 0.45)
		fill = Color(fill.r, fill.g, fill.b, fill.a * 0.45)
	var inset := CHECKBOX_BORDER_WIDTH
	var inner := size - inset * 2
	for y in inner:
		for x in inner:
			img.set_pixel(inset + x, inset + y, fill)
	for y in size:
		for x in size:
			var on_border := x < inset or x >= size - inset or y < inset or y >= size - inset
			if on_border:
				img.set_pixel(x, y, border_color)
	if checked and not disabled:
		_draw_check_mark(img, CHECKBOX_MARK)
	elif checked and disabled:
		_draw_check_mark(img, Color(CHECKBOX_MARK.r, CHECKBOX_MARK.g, CHECKBOX_MARK.b, 0.45))
	return ImageTexture.create_from_image(img)


func _draw_check_mark(img: Image, color: Color) -> void:
	# Simple 2px-thick check drawn in the 20x20 icon.
	var points: Array[Vector2i] = [
		Vector2i(5, 10), Vector2i(6, 11), Vector2i(7, 12),
		Vector2i(8, 13), Vector2i(9, 12), Vector2i(10, 11),
		Vector2i(11, 10), Vector2i(12, 9), Vector2i(13, 8), Vector2i(14, 7),
	]
	for p: Vector2i in points:
		img.set_pixel(p.x, p.y, color)
		img.set_pixel(p.x, p.y + 1, color)
