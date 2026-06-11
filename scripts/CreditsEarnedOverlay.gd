extends Control
class_name CreditsEarnedOverlay

## Full-screen "Earned xxx credits" toast with tick animation.

signal dismissed

const CHIVO_FONT := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")

var _amount: int = 0
var _dismissed: bool = false
var _tick_lbl: Label
var _text_lbl: Label

static func show_earned(parent: Node, amount: int) -> void:
	if amount <= 0:
		return
	var overlay := CreditsEarnedOverlay.new()
	overlay._amount = amount
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 120
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)


func _ready() -> void:
	SFXManager.play(SFXManager.SFX_CREDIT_CLINK)
	_build_ui()
	modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_play_tick_animation()
	get_tree().create_timer(2.4).timeout.connect(_dismiss)


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	_tick_lbl = Label.new()
	_tick_lbl.text = "✓"
	_tick_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tick_lbl.add_theme_font_size_override("font_size", 72)
	_tick_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
	_tick_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.25, 0.12, 0.9))
	_tick_lbl.add_theme_constant_override("shadow_offset_x", 0)
	_tick_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_tick_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tick_lbl.pivot_offset = Vector2(18.0, 36.0)
	_tick_lbl.scale = Vector2.ZERO
	vbox.add_child(_tick_lbl)

	_text_lbl = Label.new()
	_text_lbl.text = "Earned %d credits" % _amount
	_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_lbl.add_theme_font_size_override("font_size", 40)
	_text_lbl.add_theme_font_override("font", CHIVO_FONT)
	_text_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28))
	_text_lbl.add_theme_color_override("font_shadow_color", Color(0.35, 0.22, 0.0, 0.95))
	_text_lbl.add_theme_constant_override("shadow_offset_x", 0)
	_text_lbl.add_theme_constant_override("shadow_offset_y", 3)
	_text_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_lbl.modulate.a = 0.0
	vbox.add_child(_text_lbl)


func _play_tick_animation() -> void:
	await get_tree().process_frame
	_tick_lbl.pivot_offset = _tick_lbl.size * 0.5
	var tw := create_tween()
	tw.tween_property(_tick_lbl, "scale", Vector2(1.25, 1.25), 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_tick_lbl, "scale", Vector2.ONE, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_text_lbl, "modulate:a", 1.0, 0.35) \
		.set_delay(0.12).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)


func _input(event: InputEvent) -> void:
	if _dismissed:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_dismiss()
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		_dismiss()


func _dismiss() -> void:
	if _dismissed:
		return
	_dismissed = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		dismissed.emit()
		queue_free())
