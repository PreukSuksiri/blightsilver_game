extends Control
# Admin UI to preview Win / Lose endgame background images.
# Open via Admin Console: simulate_win_lose_screen

const WIN_SCREEN_DIR := "res://assets/textures/profile/win_screen/"
const DEFAULT_WIN_PATH := WIN_SCREEN_DIR + "img_win_screen_nex_2.png"
const DEFAULT_LOSE_PATH := WIN_SCREEN_DIR + "img_lose_screen_default.png"

const _BG_COLOR := Color(0.05, 0.05, 0.10, 0.97)
const _HEADER_COLOR := Color(0.10, 0.12, 0.22, 1.0)
const _PANEL_COLOR := Color(0.09, 0.10, 0.16, 1.0)
const _BTN_PREVIEW := Color(0.12, 0.42, 0.62, 1.0)
const _BTN_BROWSE := Color(0.22, 0.22, 0.32, 1.0)
const _BTN_CLOSE := Color(0.55, 0.12, 0.12, 1.0)

var _path_edit: LineEdit = null
var _mode_opt: OptionButton = null
var _status_lbl: Label = null
var _file_dialog: FileDialog = null
var _preview_layer: Control = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 90

	var bg := ColorRect.new()
	bg.color = _BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_build_header()
	_build_body()
	_build_file_dialog()


func _build_header() -> void:
	var header := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = _HEADER_COLOR
	header.add_theme_stylebox_override("panel", sb)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.custom_minimum_size = Vector2(0, 52)
	add_child(header)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 12.0
	hbox.offset_right = -12.0
	hbox.offset_top = 6.0
	hbox.offset_bottom = -6.0
	hbox.add_theme_constant_override("separation", 10)
	header.add_child(hbox)

	var title := Label.new()
	title.text = "Win / Lose Screen Preview"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(title)

	var close_btn := _make_button("X", _BTN_CLOSE)
	close_btn.custom_minimum_size = Vector2(44, 38)
	close_btn.pressed.connect(queue_free)
	hbox.add_child(close_btn)


func _build_body() -> void:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = _PANEL_COLOR
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 14.0
	sb.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_top = 52.0
	panel.offset_bottom = -12.0
	panel.offset_left = 24.0
	panel.offset_right = -24.0
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var hint := Label.new()
	hint.text = (
		"Pick an image from the win_screen folder, choose Win or Lose layout, "
		+ "then Preview. Tap the fullscreen preview to close it."
	)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.72, 0.80, 0.92))
	vbox.add_child(hint)

	var path_row := HBoxContainer.new()
	path_row.add_theme_constant_override("separation", 8)
	vbox.add_child(path_row)

	_path_edit = LineEdit.new()
	_path_edit.text = DEFAULT_WIN_PATH
	_path_edit.placeholder_text = "res://assets/textures/profile/win_screen/..."
	_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_edit.add_theme_font_size_override("font_size", 13)
	path_row.add_child(_path_edit)

	var browse_btn := _make_button("Browse…", _BTN_BROWSE)
	browse_btn.custom_minimum_size = Vector2(110, 36)
	browse_btn.pressed.connect(func() -> void: _file_dialog.popup_centered())
	path_row.add_child(browse_btn)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 10)
	vbox.add_child(mode_row)

	var mode_lbl := Label.new()
	mode_lbl.text = "Simulate:"
	mode_lbl.add_theme_font_size_override("font_size", 14)
	mode_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	mode_row.add_child(mode_lbl)

	_mode_opt = OptionButton.new()
	_mode_opt.add_item("Win Screen", 0)
	_mode_opt.add_item("Lose Screen", 1)
	_mode_opt.custom_minimum_size = Vector2(180, 36)
	mode_row.add_child(_mode_opt)

	var preview_btn := _make_button("Preview", _BTN_PREVIEW)
	preview_btn.custom_minimum_size = Vector2(140, 40)
	preview_btn.pressed.connect(_on_preview_pressed)
	mode_row.add_child(preview_btn)

	_status_lbl = Label.new()
	_status_lbl.text = ""
	_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", Color(0.55, 0.90, 0.65))
	vbox.add_child(_status_lbl)


func _build_file_dialog() -> void:
	_file_dialog = FileDialog.new()
	_file_dialog.title = "Select Win/Lose Screen Image"
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_file_dialog.filters = PackedStringArray([
		"*.png ; PNG",
		"*.jpg, *.jpeg ; JPEG",
		"*.webp ; WebP",
	])
	_file_dialog.current_dir = WIN_SCREEN_DIR
	_file_dialog.size = Vector2i(900, 600)
	_file_dialog.file_selected.connect(func(path: String) -> void:
		_path_edit.text = path
		_set_status("Selected: %s" % path.get_file()))
	add_child(_file_dialog)


func _on_preview_pressed() -> void:
	var path: String = _path_edit.text.strip_edges()
	if path.is_empty():
		path = DEFAULT_WIN_PATH if _mode_opt.selected == 0 else DEFAULT_LOSE_PATH
	if not ResourceLoader.exists(path):
		_set_status("Image not found: %s" % path)
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		_set_status("Could not load image: %s" % path)
		return
	_dismiss_preview()
	var is_win: bool = _mode_opt.selected == 0
	_preview_layer = _build_preview_overlay(tex, is_win)
	add_child(_preview_layer)
	_set_status("Previewing %s as %s — tap preview to close." % [
		path.get_file(), "Win" if is_win else "Lose"])


func _apply_endgame_serif_font(control: Control, weight: int = 400) -> void:
	control.add_theme_font_override("font", FontManager.make_font("display_serif", weight))

func _build_preview_overlay(tex: Texture2D, is_win: bool) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)

	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.0, 0.0, 0.0, 0.50)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(vignette)

	if is_win:
		var title_lbl := Label.new()
		title_lbl.text = "You've Won the Duel."
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		title_lbl.offset_left = -500.0
		title_lbl.offset_right = 500.0
		title_lbl.offset_top = -80.0
		title_lbl.offset_bottom = 40.0
		title_lbl.add_theme_font_size_override("font_size", 52)
		_apply_endgame_serif_font(title_lbl, 600)
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
		title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(title_lbl)
	else:
		var go_lbl := Label.new()
		go_lbl.text = "Game Over"
		go_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		go_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		go_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		go_lbl.offset_left = -600.0
		go_lbl.offset_right = 600.0
		go_lbl.offset_top = -160.0
		go_lbl.offset_bottom = 60.0
		go_lbl.add_theme_font_size_override("font_size", 96)
		_apply_endgame_serif_font(go_lbl, 700)
		go_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		go_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		go_lbl.add_theme_constant_override("shadow_offset_x", 4)
		go_lbl.add_theme_constant_override("shadow_offset_y", 4)
		go_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(go_lbl)

		var defeat_lbl := Label.new()
		defeat_lbl.text = "Defeat."
		defeat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		defeat_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		defeat_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		defeat_lbl.offset_left = -500.0
		defeat_lbl.offset_right = 500.0
		defeat_lbl.offset_top = 20.0
		defeat_lbl.offset_bottom = 80.0
		defeat_lbl.add_theme_font_size_override("font_size", 52)
		_apply_endgame_serif_font(defeat_lbl, 600)
		defeat_lbl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.60, 0.85))
		defeat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(defeat_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = "tap anywhere to close preview"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hint_lbl.offset_left = -300.0
	hint_lbl.offset_right = 300.0
	hint_lbl.offset_top = 220.0
	hint_lbl.offset_bottom = 270.0
	hint_lbl.add_theme_font_size_override("font_size", 24)
	_apply_endgame_serif_font(hint_lbl, 400)
	hint_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint_lbl)

	var blink_tw := overlay.create_tween().set_loops()
	blink_tw.tween_property(hint_lbl, "modulate:a", 0.2, 0.9).set_trans(Tween.TRANS_SINE)
	blink_tw.tween_property(hint_lbl, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

	overlay.gui_input.connect(func(ev: InputEvent) -> void:
		if not _is_press_event(ev):
			return
		blink_tw.kill()
		_dismiss_preview())

	var fade_tw := overlay.create_tween()
	overlay.modulate.a = 0.0
	fade_tw.tween_property(overlay, "modulate:a", 1.0, 0.35)

	return overlay


func _dismiss_preview() -> void:
	if _preview_layer != null and is_instance_valid(_preview_layer):
		_preview_layer.queue_free()
	_preview_layer = null


func _set_status(msg: String) -> void:
	if _status_lbl != null:
		_status_lbl.text = msg


func _is_press_event(ev: InputEvent) -> bool:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if ev is InputEventScreenTouch:
		return (ev as InputEventScreenTouch).pressed
	return false


func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	return btn


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_dismiss_preview()
