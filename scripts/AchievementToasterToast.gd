extends Control
class_name AchievementToasterToast

signal finished

const PANEL_MIN_HEIGHT := 52.0
const TOP_MARGIN := 18.0
const ICON_SIZE := 44.0
const ROW_GAP := 12.0
const FONT_SIZE := 16
const VIEWPORT_SIDE_MARGIN := 32.0
const FADE_IN_SECONDS := 0.35
const HOLD_SECONDS := 3.5
const FADE_OUT_SECONDS := 0.35

const BG_COLOR := Color(0.02, 0.04, 0.10, 0.92)
const BORDER_COLOR := Color(0.55, 0.78, 0.95, 0.9)
const LABEL_COLOR := Color(0.88, 0.94, 0.98, 1.0)

var _panel: PanelContainer = null
var _sequence_tw: Tween = null
var _achievement_id: String = ""


static func show_toast(parent: Node, achievement_id: String) -> AchievementToasterToast:
	var toast := AchievementToasterToast.new()
	toast._achievement_id = achievement_id
	parent.add_child(toast)
	return toast


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	call_deferred("_play_sequence")


func _build_ui() -> void:
	var def: Dictionary = AchievementManager.get_definition(_achievement_id)
	var title: String = str(def.get("title", _achievement_id))
	var message: String = "New Achievement: %s" % title
	var font: Font = FontManager.make_font("primary", 500)

	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_COLOR
	sb.border_color = BORDER_COLOR
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 14.0
	sb.content_margin_bottom = 10.0

	var h_pad: float = sb.get_content_margin(SIDE_LEFT) + sb.get_content_margin(SIDE_RIGHT)
	var v_pad: float = sb.get_content_margin(SIDE_TOP) + sb.get_content_margin(SIDE_BOTTOM)
	var border_pad: float = float(sb.get_border_width(SIDE_LEFT) + sb.get_border_width(SIDE_RIGHT))

	var max_panel_w: float = get_viewport().get_visible_rect().size.x - VIEWPORT_SIDE_MARGIN * 2.0
	var max_text_w: float = maxf(64.0, max_panel_w - h_pad - border_pad - ICON_SIZE - ROW_GAP)

	var text_sz: Vector2 = font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var label_w: float = minf(ceilf(text_sz.x), max_text_w)
	var row_h: float = maxf(ICON_SIZE, ceilf(text_sz.y))
	var panel_w: float = minf(label_w + ICON_SIZE + ROW_GAP + h_pad + border_pad, max_panel_w)
	var panel_h: float = maxf(PANEL_MIN_HEIGHT, row_h + v_pad + float(sb.get_border_width(SIDE_TOP) + sb.get_border_width(SIDE_BOTTOM)))

	var top_band := CenterContainer.new()
	top_band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_band.offset_top = TOP_MARGIN
	top_band.offset_bottom = TOP_MARGIN + panel_h + 8.0
	top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_band)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", sb)
	top_band.add_child(_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ROW_GAP)
	row.custom_minimum_size = Vector2(label_w + ICON_SIZE + ROW_GAP, row_h)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_path: String = AchievementManager.get_icon_path(def)
	if not icon_path.is_empty():
		icon.texture = load(icon_path) as Texture2D
	row.add_child(icon)

	var label := Label.new()
	label.text = message
	label.custom_minimum_size = Vector2(label_w, row_h)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", LABEL_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)


func _play_sequence() -> void:
	if _panel == null:
		_finish()
		return
	modulate.a = 0.0
	_sequence_tw = create_tween()
	_sequence_tw.tween_property(self, "modulate:a", 1.0, FADE_IN_SECONDS) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_sequence_tw.tween_interval(HOLD_SECONDS)
	_sequence_tw.tween_property(self, "modulate:a", 0.0, FADE_OUT_SECONDS) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_sequence_tw.tween_callback(_finish)


func _finish() -> void:
	finished.emit()
	queue_free()
