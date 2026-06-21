extends Node
## Shared VN-style blue dialog skin for AcceptDialog / ConfirmationDialog.

const BTN_MIN_SIZE := Vector2(140, 40)
const TITLE_FONT_SIZE := 22
const BODY_FONT_SIZE := 18
const BTN_FONT_SIZE := 17

const PANEL_BG := Color(0.04, 0.06, 0.13, 0.97)
const PANEL_BORDER := Color(0.60, 0.82, 1.0, 0.65)
const TITLE_COLOR := Color(0.72, 0.92, 1.0, 1.0)
const BODY_COLOR := Color(0.90, 0.95, 1.0, 0.97)
const BTN_NORMAL := Color(0.08, 0.16, 0.38, 0.97)
const BTN_HOVER := Color(0.12, 0.24, 0.52, 1.0)
const BTN_PRESSED := Color(0.06, 0.12, 0.30, 1.0)
const BTN_BORDER := Color(0.38, 0.65, 1.0, 0.6)
const BTN_TEXT := Color(0.88, 0.95, 1.0, 1.0)


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


func style(dlg: AcceptDialog) -> void:
	dlg.add_theme_stylebox_override("panel", make_panel_stylebox())
	dlg.add_theme_font_override("title_font", FontManager.make_font("primary", 700))
	dlg.add_theme_font_size_override("title_font_size", TITLE_FONT_SIZE)
	dlg.add_theme_color_override("title_color", TITLE_COLOR)
	dlg.add_theme_font_override("font", FontManager.make_font("primary", 400))
	dlg.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	dlg.min_size = Vector2i(maxi(dlg.min_size.x, 420), maxi(dlg.min_size.y, 140))
	if dlg.is_inside_tree():
		_style_dialog_buttons(dlg)
	else:
		dlg.tree_entered.connect(func() -> void: _style_dialog_buttons(dlg), CONNECT_ONE_SHOT)


func accept(parent: Node, title: String, body: String, ok_text: String = "OK") -> AcceptDialog:
	var dlg := AcceptDialog.new()
	dlg.title = title
	dlg.dialog_text = body
	dlg.ok_button_text = ok_text
	parent.add_child(dlg)
	style(dlg)
	return dlg


func confirmation(
		parent: Node,
		title: String,
		body: String,
		ok_text: String = "OK",
		cancel_text: String = "Cancel") -> ConfirmationDialog:
	var dlg := ConfirmationDialog.new()
	dlg.title = title
	dlg.dialog_text = body
	dlg.ok_button_text = ok_text
	dlg.cancel_button_text = cancel_text
	parent.add_child(dlg)
	style(dlg)
	return dlg


func _style_dialog_buttons(dlg: AcceptDialog) -> void:
	var ok_btn: Button = dlg.get_ok_button()
	if ok_btn:
		style_button(ok_btn)
	if dlg is ConfirmationDialog:
		var cancel_btn: Button = (dlg as ConfirmationDialog).get_cancel_button()
		if cancel_btn:
			style_button(cancel_btn)
	_style_body_label(dlg)


func _style_body_label(dlg: AcceptDialog) -> void:
	for child in dlg.get_children():
		if child is Label:
			var lbl := child as Label
			FontManager.tag_font(lbl, "font", "primary", 400)
			lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
			lbl.add_theme_color_override("font_color", BODY_COLOR)


func _make_button_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = BTN_BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	return sb
