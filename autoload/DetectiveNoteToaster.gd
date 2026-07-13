extends Node
## Top-center toast for detective note events ("Detective Note : New Individual",
## "Detective Note : New Topic", "Detective Note : Topic Expanded" …).
## Mirrors AchievementToaster: queued, non-blocking, CanvasLayer 130.

const CANVAS_LAYER := 130
const NOTE_ICON := "res://assets/textures/detective/ui_detective_note_icon.png"

const KIND_MESSAGES := {
	"individual": "Detective Note : New Individual",
	"object": "Detective Note : New Object",
	"information": "Detective Note : New Information",
	"topic": "Detective Note : New Topic",
	"topic_expanded": "Detective Note : Topic Expanded",
}

const PANEL_MIN_HEIGHT := 52.0
const TOP_MARGIN := 18.0
const ICON_SIZE := 44.0
const ROW_GAP := 12.0
const FONT_SIZE := 16
const FADE_IN_SECONDS := 0.35
const HOLD_SECONDS := 3.0
const FADE_OUT_SECONDS := 0.35

const BG_COLOR := Color(0.10, 0.07, 0.03, 0.93)
const BORDER_COLOR := Color(0.85, 0.68, 0.35, 0.9)
const LABEL_COLOR := Color(0.96, 0.90, 0.78, 1.0)

var _layer: CanvasLayer = null
var _toast_host: Control = null
var _queue: Array[String] = []
var _active: bool = false


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = CANVAS_LAYER
	add_child(_layer)
	_toast_host = Control.new()
	_toast_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_toast_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_toast_host)
	if not get_viewport().size_changed.is_connected(_sync_host_size):
		get_viewport().size_changed.connect(_sync_host_size)
	call_deferred("_sync_host_size")
	DetectiveNoteManager.note_notification.connect(_on_note_notification)


func _sync_host_size() -> void:
	if _toast_host == null:
		return
	_toast_host.set_size(get_viewport().get_visible_rect().size)
	_toast_host.position = Vector2.ZERO


func _on_note_notification(kind: String, _chapter_id: String, _ref_id: String) -> void:
	var message: String = str(KIND_MESSAGES.get(kind, ""))
	if message.is_empty():
		return
	_queue.append(message)
	_pump_queue()


func _pump_queue() -> void:
	if _active or _queue.is_empty() or _toast_host == null:
		return
	_active = true
	_show_toast(_queue.pop_front())


func _show_toast(message: String) -> void:
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

	var text_sz: Vector2 = font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var row_h: float = maxf(ICON_SIZE, ceilf(text_sz.y))
	var panel_h: float = maxf(PANEL_MIN_HEIGHT, row_h + 24.0)

	var toast := Control.new()
	toast.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_host.add_child(toast)

	var top_band := CenterContainer.new()
	top_band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_band.offset_top = TOP_MARGIN
	top_band.offset_bottom = TOP_MARGIN + panel_h + 8.0
	top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_child(top_band)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(
		ceilf(text_sz.x) + ICON_SIZE + ROW_GAP + 30.0, panel_h)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", sb)
	top_band.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ROW_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(NOTE_ICON):
		icon.texture = load(NOTE_ICON) as Texture2D
	row.add_child(icon)

	var label := Label.new()
	label.text = message
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", LABEL_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	toast.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, FADE_IN_SECONDS) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(HOLD_SECONDS)
	tw.tween_property(toast, "modulate:a", 0.0, FADE_OUT_SECONDS) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		toast.queue_free()
		_active = false
		_pump_queue())
