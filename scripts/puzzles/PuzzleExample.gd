extends ExplorationPuzzleBase
## Minimal example puzzle — replace with real puzzle logic.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420.0, 220.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.16, 0.96)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.35, 0.75, 1.0, 0.75)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 20.0
	sb.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Example Puzzle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	vbox.add_child(title)

	var hint := Label.new()
	var param_hint: String = ""
	if not params.is_empty():
		param_hint = "\nParams: %s" % JSON.stringify(params)
	hint.text = "This is a placeholder puzzle scene.\nPress Solve to continue.%s" % param_hint
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.65, 0.75, 0.82))
	vbox.add_child(hint)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var solve_btn := Button.new()
	solve_btn.text = "Solve"
	solve_btn.pressed.connect(func() -> void: complete_puzzle(true))
	row.add_child(solve_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(func() -> void: complete_puzzle(false))
	row.add_child(cancel_btn)
