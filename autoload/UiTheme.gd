extends Node
## Global UI theme overrides — light scrollbars on dark screens.

const SCROLL_THUMB := Color("#f5f5f5")
const SCROLL_THUMB_HOVER := Color("#ffffff")
const SCROLL_THUMB_PRESSED := Color("#e0e0e0")
const SCROLL_TRACK := Color(0.960784, 0.960784, 0.960784, 0.14)
const SCROLL_MIN_GRABBER := 24
const SCROLL_RADIUS := 4


func _ready() -> void:
	call_deferred("_apply_root_theme")


func _apply_root_theme() -> void:
	var root := get_tree().root
	if root == null:
		return
	var theme := root.theme if root.theme != null else Theme.new()
	_apply_scrollbar_theme(theme)
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
