extends Control
class_name OmenAnointPicker
## Dim overlay to pick a deck card to anoint for an omen.

signal picked(card_name: String)

var _omen: Dictionary = {}
var _eligible: Array = []
var _content: Control = null
var _input_enabled: bool = false


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
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 220
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_content = VBoxContainer.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.offset_left = 48.0
	_content.offset_right = -48.0
	_content.offset_top = 48.0
	_content.offset_bottom = -48.0
	_content.add_theme_constant_override("separation", 12)
	_content.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_content.position.y += 24.0
	add_child(_content)

	var header := Label.new()
	var omen_label: String = str(_omen.get("label", _omen.get("id", "Omen")))
	header.text = "%s — Choose a card" % omen_label
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1.0))
	_content.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	for entry: Variant in _eligible:
		if not entry is Dictionary:
			continue
		grid.add_child(_make_card_button(entry as Dictionary))

	_play_intro()


func _make_card_button(card: Dictionary) -> Button:
	var card_name: String = str(card.get("name", ""))
	var card_type: String = str(card.get("type", "unit")).capitalize()
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(220.0, 56.0)
	btn.text = "%s\n(%s)" % [card_name, card_type]
	btn.add_theme_font_size_override("font_size", 14)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func() -> void:
		_on_card_chosen(btn, card_name))
	return btn


func _play_intro() -> void:
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(_content, "modulate:a", 1.0, 0.2) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_content, "position:y", _content.position.y - 24.0, 0.2) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	_input_enabled = true


func _on_card_chosen(btn: Button, card_name: String) -> void:
	if not _input_enabled or card_name.is_empty():
		return
	_input_enabled = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pulse: Tween = create_tween()
	pulse.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.08) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(btn, "scale", Vector2.ONE, 0.08) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await pulse.finished

	picked.emit(card_name)
	queue_free()
