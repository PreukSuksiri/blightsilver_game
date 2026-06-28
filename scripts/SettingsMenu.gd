extends Control

signal closed

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ── Full-screen dimmer (click outside to close) ──────────────
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.0)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close())
	add_child(dimmer)

	# ── Centered panel ───────────────────────────────────────────
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", GameDialog.make_panel_stylebox())
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -210
	panel.offset_top    = -110
	panel.offset_right  = 210
	panel.offset_bottom = 110
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20; vbox.offset_top    = 16
	vbox.offset_right = -20; vbox.offset_bottom = -16
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "SETTINGS"
	GameDialog.style_title_label(title)
	vbox.add_child(title)

	# Music volume
	vbox.add_child(_make_slider_row(
		"Music Volume",
		AudioManager.music_volume,
		func(v: float) -> void: AudioManager.set_music_volume(v)
	))

	# SFX volume
	vbox.add_child(_make_slider_row(
		"SFX Volume",
		AudioManager.sfx_volume,
		func(v: float) -> void: AudioManager.set_sfx_volume(v)
	))

	var casual_row := HBoxContainer.new()
	casual_row.add_theme_constant_override("separation", 10)
	var casual_lbl := Label.new()
	casual_lbl.text = "Casual Mode"
	casual_lbl.custom_minimum_size.x = 110
	casual_lbl.add_theme_font_size_override("font_size", 12)
	casual_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	casual_row.add_child(casual_lbl)
	var casual_chk := CheckBox.new()
	casual_chk.button_pressed = SaveManager.is_casual_mode()
	casual_chk.text = "Enemy starts with 3000 crystals"
	casual_chk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	casual_chk.toggled.connect(func(on: bool) -> void: SaveManager.set_casual_mode(on))
	casual_row.add_child(casual_chk)
	vbox.add_child(casual_row)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close"
	GameDialog.style_button(close_btn)
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)


func _make_slider_row(label_text: String, initial: float, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 110
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size.x = 36
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	val_lbl.text = "%d%%" % roundi(initial * 100)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)

	slider.value_changed.connect(func(v: float) -> void:
		val_lbl.text = "%d%%" % roundi(v * 100)
		on_change.call(v))

	return row


func _close() -> void:
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
