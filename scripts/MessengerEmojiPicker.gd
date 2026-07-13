extends RefCounted
class_name MessengerEmojiPicker
## Small popup grid for inserting unicode emoticons into LineEdit fields.
## Used by MessengerVaultManager for participant names and message text.

const PICKER_NAME := "MessengerEmojiPickerPopup"

const CATEGORIES: Dictionary = {
	"Smileys": [
		"😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "🙂", "😊",
		"😇", "🥰", "😍", "🤩", "😘", "😗", "☺️", "😚", "😙", "🥲",
		"😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔",
		"🤐", "🤨", "😐", "😑", "😶", "😏", "😒", "🙄", "😬", "😌",
		"😔", "😪", "🤤", "😴", "😷", "🤒", "🤕", "🤢", "🤮", "🥴",
		"😵", "🤯", "🤠", "🥳", "😎", "🤓", "🧐",
	],
	"Reactions": [
		"😨", "😰", "😥", "😢", "😭", "😱", "😖", "😣", "😞", "😓",
		"😩", "😫", "🥺", "😤", "😠", "😡", "🤬", "😈", "👿", "💀",
		"☠️", "💩", "🤡", "👻", "👽", "🤖",
	],
	"Gestures": [
		"👍", "👎", "👊", "✊", "🤛", "🤜", "🤞", "✌️", "🤟", "🤘",
		"👌", "🤌", "🤏", "👈", "👉", "👆", "👇", "☝️", "✋", "🤚",
		"🖐️", "👋", "🤙", "💪", "🖕", "✍️", "🙏", "🤝", "👏", "🙌",
	],
	"Hearts": [
		"❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔",
		"❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝",
	],
	"Chat": [
		"💬", "📱", "📷", "📸", "🎥", "🔔", "🔕", "⭐", "✨", "💯",
		"✅", "❌", "❗", "❓", "‼️", "🔥", "💥", "🎉", "🎊", "🏃",
		"🏃‍♀️", "🏃‍♂️", "🚪", "🏫", "🏠", "🌙", "☀️", "🌧️", "⚡", "🔒",
	],
}


static func make_button(line_edit: LineEdit, popup_host: Node) -> Button:
	var btn := Button.new()
	btn.text = "😀"
	btn.tooltip_text = "Insert emoticon"
	btn.custom_minimum_size = Vector2(36, 0)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(func() -> void: open(popup_host, line_edit))
	return btn


static func open(popup_host: Node, line_edit: LineEdit) -> void:
	if popup_host == null or line_edit == null:
		return
	_close_existing(popup_host)

	var backdrop := Control.new()
	backdrop.name = PICKER_NAME
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.z_index = 400
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_host.add_child(backdrop)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(dim)

	backdrop.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			backdrop.queue_free())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = Vector2(520, 0)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.06, 0.08, 0.14, 0.98)
	psb.set_corner_radius_all(10)
	psb.border_color = Color(0.35, 0.55, 0.85, 0.6)
	psb.set_border_width_all(1)
	psb.content_margin_left = 12.0
	psb.content_margin_right = 12.0
	psb.content_margin_top = 10.0
	psb.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", psb)
	center.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)

	var hdr := HBoxContainer.new()
	root.add_child(hdr)
	var title := Label.new()
	title.text = "Insert emoticon"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	hdr.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.pressed.connect(backdrop.queue_free)
	hdr.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)

	var emoji_font := _make_emoji_font()

	for cat_name: String in CATEGORIES.keys():
		var cat_lbl := Label.new()
		cat_lbl.text = cat_name
		cat_lbl.add_theme_font_size_override("font_size", 13)
		cat_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
		body.add_child(cat_lbl)

		var grid := GridContainer.new()
		grid.columns = 10
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		body.add_child(grid)

		for emoji: String in (CATEGORIES[cat_name] as Array):
			var eb := Button.new()
			eb.text = emoji
			eb.custom_minimum_size = Vector2(44, 40)
			eb.add_theme_font_size_override("font_size", 22)
			if emoji_font != null:
				eb.add_theme_font_override("font", emoji_font)
			var snap_emoji := emoji
			eb.pressed.connect(func() -> void:
				_insert_at_caret(line_edit, snap_emoji)
				backdrop.queue_free())
			grid.add_child(eb)


static func _close_existing(popup_host: Node) -> void:
	var existing: Node = popup_host.get_node_or_null(PICKER_NAME)
	if existing != null:
		existing.queue_free()


static func _insert_at_caret(line_edit: LineEdit, insert: String) -> void:
	var pos: int = line_edit.caret_column
	var t: String = line_edit.text
	line_edit.text = t.substr(0, pos) + insert + t.substr(pos)
	line_edit.caret_column = pos + insert.length()
	line_edit.text_changed.emit(line_edit.text)
	line_edit.grab_focus()


static func _make_emoji_font() -> FontVariation:
	var fv := FontVariation.new()
	var emoji := SystemFont.new()
	emoji.font_names = PackedStringArray(
		["Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji"])
	fv.base_font = emoji
	return fv
