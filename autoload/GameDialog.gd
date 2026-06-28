extends Node
## Shared VN-style blue dialog skin for custom overlay prompts.

const OVERLAY_NAME := &"GameDialogOverlay"
const BTN_MIN_SIZE := Vector2(140, 40)
const TITLE_FONT_SIZE := 22
const BODY_FONT_SIZE := 18
const BTN_FONT_SIZE := 17
const DEFAULT_MIN_WIDTH := 480.0
const DEFAULT_Z_INDEX := 400

const PANEL_BG := Color(0.04, 0.06, 0.13, 0.97)
const PANEL_BORDER := Color(0.60, 0.82, 1.0, 0.65)
const TITLE_COLOR := Color(0.72, 0.92, 1.0, 1.0)
const BODY_COLOR := Color(0.90, 0.95, 1.0, 0.97)
const BTN_NORMAL := Color(0.08, 0.16, 0.38, 0.97)
const BTN_HOVER := Color(0.12, 0.24, 0.52, 1.0)
const BTN_PRESSED := Color(0.06, 0.12, 0.30, 1.0)
const BTN_BORDER := Color(0.38, 0.65, 1.0, 0.6)
const BTN_TEXT := Color(0.88, 0.95, 1.0, 1.0)


func has_open_overlay(parent: Node, overlay_name: StringName = OVERLAY_NAME) -> bool:
	return parent.get_node_or_null(NodePath(str(overlay_name))) != null


func make_panel_stylebox(content_margin: float = 18.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.border_color = PANEL_BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(content_margin)
	return sb


func style_button(btn: Button) -> void:
	btn.custom_minimum_size = BTN_MIN_SIZE
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	FontManager.tag_font(btn, "font", "primary", 400)
	btn.add_theme_font_size_override("font_size", BTN_FONT_SIZE)
	btn.add_theme_color_override("font_color", BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.82, 0.92, 1.0, 1.0))
	btn.add_theme_stylebox_override("normal", _make_button_style(BTN_NORMAL))
	btn.add_theme_stylebox_override("hover", _make_button_style(BTN_HOVER))
	btn.add_theme_stylebox_override("pressed", _make_button_style(BTN_PRESSED))
	btn.add_theme_stylebox_override("focus", _make_button_style(BTN_HOVER))
	SFXManager.wire_prompt_button(btn)


func style_title_label(lbl: Label) -> void:
	FontManager.tag_font(lbl, "font", "primary", 700)
	lbl.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	lbl.add_theme_color_override("font_color", TITLE_COLOR)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func style_body_label(lbl: Label) -> void:
	FontManager.tag_font(lbl, "font", "primary", 400)
	lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	lbl.add_theme_color_override("font_color", BODY_COLOR)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func accept_overlay(
		parent: Node,
		title: String,
		body: String,
		ok_text: String = "OK",
		on_ok: Callable = Callable(),
		min_width: float = DEFAULT_MIN_WIDTH,
		z_index: int = DEFAULT_Z_INDEX,
		overlay_name: StringName = OVERLAY_NAME) -> Control:
	var shell: Dictionary = _make_overlay_shell(parent, min_width, z_index, overlay_name)
	var vbox: VBoxContainer = shell["vbox"]
	var root: Control = shell["root"]
	_add_title_body(vbox, title, body)
	_add_button_row(vbox, [_make_button_def(ok_text, func() -> void:
		if on_ok.is_valid():
			on_ok.call()
		root.queue_free())])
	return root


func confirmation_overlay(
		parent: Node,
		title: String,
		body: String,
		ok_text: String = "OK",
		cancel_text: String = "Cancel",
		on_confirm: Callable = Callable(),
		on_cancel: Callable = Callable(),
		min_width: float = DEFAULT_MIN_WIDTH,
		z_index: int = DEFAULT_Z_INDEX,
		overlay_name: StringName = OVERLAY_NAME) -> Control:
	var shell: Dictionary = _make_overlay_shell(parent, min_width, z_index, overlay_name)
	var vbox: VBoxContainer = shell["vbox"]
	_add_title_body(vbox, title, body)
	var root: Control = shell["root"]
	_add_button_row(vbox, [
		_make_button_def(cancel_text, func() -> void:
			if on_cancel.is_valid():
				on_cancel.call()
			root.queue_free()),
		_make_button_def(ok_text, func() -> void:
			if on_confirm.is_valid():
				on_confirm.call()
			root.queue_free()),
	])
	return root


## Multi-action dialog. Each action: { "text": String, "callback": Callable }.
## Optional cancel button closes without running an action callback.
func choices_overlay(
		parent: Node,
		title: String,
		body: String,
		actions: Array,
		cancel_text: String = "Cancel",
		on_cancel: Callable = Callable(),
		min_width: float = DEFAULT_MIN_WIDTH,
		z_index: int = DEFAULT_Z_INDEX,
		overlay_name: StringName = OVERLAY_NAME) -> Control:
	var shell: Dictionary = _make_overlay_shell(parent, min_width, z_index, overlay_name)
	var vbox: VBoxContainer = shell["vbox"]
	_add_title_body(vbox, title, body)
	var root: Control = shell["root"]
	var buttons: Array = []
	for action: Variant in actions:
		if not (action is Dictionary):
			continue
		var text: String = str(action.get("text", "OK"))
		var callback: Callable = action.get("callback", Callable()) as Callable
		buttons.append(_make_button_def(text, func() -> void:
			if callback.is_valid():
				callback.call()
			root.queue_free()))
	if not cancel_text.is_empty():
		buttons.append(_make_button_def(cancel_text, func() -> void:
			if on_cancel.is_valid():
				on_cancel.call()
			root.queue_free()))
	_add_button_row(vbox, buttons)
	return root


## Text prompt with OK / Cancel. on_confirm receives entered text and returns true to close.
func prompt_overlay(
		parent: Node,
		title: String,
		body: String,
		placeholder: String = "",
		ok_text: String = "OK",
		cancel_text: String = "Cancel",
		on_confirm: Callable = Callable(),
		on_cancel: Callable = Callable(),
		min_width: float = DEFAULT_MIN_WIDTH,
		z_index: int = DEFAULT_Z_INDEX,
		overlay_name: StringName = OVERLAY_NAME) -> Control:
	var shell: Dictionary = _make_overlay_shell(parent, min_width, z_index, overlay_name)
	var vbox: VBoxContainer = shell["vbox"]
	_add_title_body(vbox, title, body)
	var root: Control = shell["root"]

	var line := LineEdit.new()
	line.placeholder_text = placeholder
	line.custom_minimum_size = Vector2(360.0, 36.0)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	FontManager.tag_font(line, "font", "primary", 400)
	line.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	line.add_theme_color_override("font_color", BODY_COLOR)
	line.add_theme_color_override("font_placeholder_color", Color(0.55, 0.62, 0.72, 0.85))
	var line_sb := StyleBoxFlat.new()
	line_sb.bg_color = Color(0.08, 0.10, 0.18, 1.0)
	line_sb.border_color = Color(0.35, 0.55, 0.85, 0.55)
	line_sb.set_border_width_all(1)
	line_sb.set_corner_radius_all(4)
	line_sb.set_content_margin_all(8)
	line.add_theme_stylebox_override("normal", line_sb)
	line.add_theme_stylebox_override("focus", line_sb)
	vbox.add_child(line)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var cancel_btn := Button.new()
	cancel_btn.text = cancel_text
	style_button(cancel_btn)
	cancel_btn.pressed.connect(func() -> void:
		if on_cancel.is_valid():
			on_cancel.call()
		root.queue_free())
	btn_row.add_child(cancel_btn)

	var ok_btn := Button.new()
	ok_btn.text = ok_text
	style_button(ok_btn)
	ok_btn.pressed.connect(func() -> void:
		if on_confirm.is_valid():
			if not on_confirm.call(line.text.strip_edges()):
				return
		root.queue_free())
	btn_row.add_child(ok_btn)

	line.text_submitted.connect(func(_text: String) -> void: ok_btn.pressed.emit())
	line.call_deferred("grab_focus")
	return root


func close_overlay(parent: Node, overlay_name: StringName = OVERLAY_NAME) -> void:
	var overlay := parent.get_node_or_null(NodePath(str(overlay_name)))
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()


func _make_overlay_shell(
		parent: Node,
		min_width: float,
		z_index: int,
		overlay_name: StringName) -> Dictionary:
	var root := Control.new()
	root.name = String(overlay_name)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.z_index = z_index

	var blocker := ColorRect.new()
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0.0, 0.0, 0.0, 0.0)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(blocker)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(min_width, 0.0)
	panel.add_theme_stylebox_override("panel", make_panel_stylebox())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	parent.add_child(root)
	root.move_to_front()
	return {"root": root, "vbox": vbox}


func _add_title_body(vbox: VBoxContainer, title: String, body: String) -> void:
	if not title.is_empty():
		var title_lbl := Label.new()
		title_lbl.text = title
		style_title_label(title_lbl)
		vbox.add_child(title_lbl)

	if not body.is_empty():
		var body_lbl := Label.new()
		body_lbl.text = body
		style_body_label(body_lbl)
		vbox.add_child(body_lbl)


func _add_button_row(vbox: VBoxContainer, button_defs: Array) -> void:
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)
	for def: Variant in button_defs:
		if not (def is Dictionary):
			continue
		var btn: Button = def.get("button") as Button
		if btn == null:
			btn = Button.new()
			btn.text = str(def.get("text", "OK"))
			style_button(btn)
			var on_press: Callable = def.get("on_press", Callable()) as Callable
			if on_press.is_valid():
				btn.pressed.connect(on_press)
		btn_row.add_child(btn)


func _make_button_def(text: String, on_press: Callable) -> Dictionary:
	return {"text": text, "on_press": on_press}


func _make_button_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = BTN_BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	return sb
