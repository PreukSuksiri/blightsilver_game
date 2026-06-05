extends Control

signal closed

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ── Full-screen dimmer (click outside to close) ──────────────
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.65)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close())
	add_child(dimmer)

	# ── Centered panel ───────────────────────────────────────────
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color            = Color(0.04, 0.06, 0.14, 0.97)
	sb.border_width_left   = 2; sb.border_width_top    = 2
	sb.border_width_right  = 2; sb.border_width_bottom = 2
	sb.border_color        = Color(0.38, 0.65, 1.0, 0.5)
	sb.corner_radius_top_left     = 8; sb.corner_radius_top_right    = 8
	sb.corner_radius_bottom_right = 8; sb.corner_radius_bottom_left  = 8
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -210
	panel.offset_top    = -165
	panel.offset_right  = 210
	panel.offset_bottom = 165
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
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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

	# Narrator toggle
	vbox.add_child(_make_toggle_row(
		"Card Narrator",
		AudioManager.tts_enabled,
		func(v: bool) -> void: AudioManager.set_tts_enabled(v)
	))

	# NSFW toggle + warning
	var nsfw_warning := Label.new()
	nsfw_warning.text = "Turning this on may cause age-restriction on streaming and affect monetization. Please keep this setting turned off if you or your audience are below 18."
	nsfw_warning.add_theme_font_size_override("font_size", 10)
	nsfw_warning.add_theme_color_override("font_color", Color(1.0, 0.65, 0.1, 0.9))
	nsfw_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nsfw_warning.visible = SaveManager.nsfw_enabled
	vbox.add_child(_make_toggle_row(
		"NSFW Content",
		SaveManager.nsfw_enabled,
		func(v: bool) -> void:
			SaveManager.nsfw_enabled = v
			SaveManager.save_data()
			SaveManager.nsfw_changed.emit(v)
			nsfw_warning.visible = v
	))
	vbox.add_child(nsfw_warning)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_color_override("font_color", Color(0.6, 0.75, 1.0))
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


func _make_toggle_row(label_text: String, initial: bool, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	row.add_child(lbl)

	var toggle := CheckButton.new()
	toggle.button_pressed = initial
	toggle.toggled.connect(func(v: bool) -> void: on_change.call(v))
	row.add_child(toggle)

	return row


func _close() -> void:
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
