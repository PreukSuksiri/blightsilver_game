extends Control
class_name MessengerOverlay
## Read-only messenger/chat viewer styled like a modern phone chat app (unbranded).
## Displays a conversation authored in MessengerVault (admin command: messenger_vault).
## Shown from VN scripts via the "show_messenger" beat key (value = conversation id).
##
## Reveal modes ("reveal_mode" on the conversation):
##   "all" — every message visible immediately, player scrolls freely.
##   "tap" — messages appear one by one on each click/tap.

signal closed

const PHONE_W := 480.0
const PHONE_H := 800.0
const BUBBLE_MAX_W := 280.0
const IMAGE_MAX_W := 240.0
const AVATAR_SIZE := 38.0

const COLOR_DIM_BG := Color(0.0, 0.0, 0.0, 0.55)
const COLOR_CHAT_BG := Color(0.545, 0.635, 0.760)
const COLOR_HEADER := Color(0.18, 0.22, 0.30)
const COLOR_BUBBLE_LEFT := Color(0.98, 0.98, 0.98)
const COLOR_BUBBLE_RIGHT := Color(0.55, 0.85, 0.36)
const COLOR_TEXT_DARK := Color(0.10, 0.10, 0.12)
const COLOR_TIME := Color(0.30, 0.35, 0.45, 0.85)
const COLOR_NAME := Color(0.22, 0.26, 0.34)
const COLOR_INPUT_BAR := Color(0.92, 0.93, 0.95)

var _conversation: Dictionary = {}
var _avatars: Dictionary = {}      # participant name → avatar path
var _right_side: String = ""
var _tap_mode: bool = false
var _next_msg_idx: int = 0

var _scroll: ScrollContainer = null
var _msg_vbox: VBoxContainer = null
var _tap_hint: Label = null
var _text_font: FontVariation = null


static func open(parent: Node, conversation_id: String) -> MessengerOverlay:
	var overlay := MessengerOverlay.new()
	overlay.name = "MessengerOverlay"
	overlay.conversation_id_to_load = conversation_id
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 250
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)
	return overlay


## Open with inline data instead of a vault id (used by the vault editor preview).
static func open_with_data(parent: Node, conversation: Dictionary) -> MessengerOverlay:
	var overlay := MessengerOverlay.new()
	overlay.name = "MessengerOverlay"
	overlay._conversation = conversation.duplicate(true)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 250
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)
	return overlay


var conversation_id_to_load: String = ""


func _ready() -> void:
	if _conversation.is_empty() and not conversation_id_to_load.is_empty():
		_conversation = MessengerVault.get_conversation(conversation_id_to_load)
	if _conversation.is_empty():
		push_warning("MessengerOverlay: conversation '%s' not found" % conversation_id_to_load)
		# Deferred so callers awaiting the closed signal (VNPlayer) still receive it.
		_close.call_deferred()
		return
	_right_side = str(_conversation.get("right_side", "")).strip_edges()
	_tap_mode = str(_conversation.get("reveal_mode", "all")).strip_edges().to_lower() == "tap"
	var parts: Variant = _conversation.get("participants", [])
	if parts is Array:
		for p: Variant in (parts as Array):
			if p is Dictionary:
				var pd: Dictionary = p as Dictionary
				_avatars[str(pd.get("name", ""))] = str(pd.get("avatar", ""))
	_build_font()
	_build_ui()
	if _tap_mode:
		_reveal_next_message()
	else:
		for i: int in range(_message_count()):
			_append_message_row(i)
		_scroll_to_bottom.call_deferred()


## Emoji fallback so unicode emoticons render even if the game font lacks them.
func _build_font() -> void:
	_text_font = FontVariation.new()
	var base: Font = get_theme_default_font()
	if base != null:
		_text_font.base_font = base
	var emoji := SystemFont.new()
	emoji.font_names = PackedStringArray(
		["Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji"])
	_text_font.fallbacks = [emoji]


func _messages() -> Array:
	var raw: Variant = _conversation.get("messages", [])
	return raw as Array if raw is Array else []


func _message_count() -> int:
	return _messages().size()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if _tap_mode and _next_msg_idx < _message_count():
			_reveal_next_message()
			accept_event()


func _on_chat_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if _tap_mode and _next_msg_idx < _message_count():
			_reveal_next_message()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	emit_signal("closed")
	queue_free()


# ─────────────────────────────────────────────────────────────
# UI construction
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = COLOR_DIM_BG
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var phone := PanelContainer.new()
	phone.custom_minimum_size = Vector2(PHONE_W, PHONE_H)
	phone.set_anchors_preset(Control.PRESET_CENTER)
	phone.position = Vector2(-PHONE_W / 2.0, -PHONE_H / 2.0)
	var phone_sb := StyleBoxFlat.new()
	phone_sb.bg_color = COLOR_CHAT_BG
	phone_sb.set_corner_radius_all(18)
	phone_sb.border_color = Color(0.08, 0.08, 0.10)
	phone_sb.set_border_width_all(6)
	phone.add_theme_stylebox_override("panel", phone_sb)
	add_child(phone)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	phone.add_child(col)

	col.add_child(_build_header())

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.gui_input.connect(_on_chat_gui_input)
	col.add_child(_scroll)

	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	_scroll.add_child(pad)

	_msg_vbox = VBoxContainer.new()
	_msg_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_msg_vbox.add_theme_constant_override("separation", 10)
	pad.add_child(_msg_vbox)

	if _tap_mode:
		_tap_hint = Label.new()
		_tap_hint.text = "Tap to continue…"
		_tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_tap_hint.add_theme_font_size_override("font_size", 13)
		_tap_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
		col.add_child(_tap_hint)

	col.add_child(_build_input_bar())


func _build_header() -> Control:
	var header := PanelContainer.new()
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = COLOR_HEADER
	hsb.corner_radius_top_left = 12
	hsb.corner_radius_top_right = 12
	hsb.content_margin_left = 12.0
	hsb.content_margin_right = 8.0
	hsb.content_margin_top = 8.0
	hsb.content_margin_bottom = 8.0
	header.add_theme_stylebox_override("panel", hsb)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 8)
	header.add_child(hrow)

	var back := Label.new()
	back.text = "‹"
	back.add_theme_font_size_override("font_size", 26)
	back.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	hrow.add_child(back)

	var title := Label.new()
	title.text = str(_conversation.get("title", "Chat"))
	var others: int = maxi(_avatars.size() - 1, 0)
	if others > 1:
		title.text += "  (%d)" % _avatars.size()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	if _text_font != null:
		title.add_theme_font_override("font", _text_font)
	title.clip_text = true
	hrow.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	close_btn.pressed.connect(_close)
	hrow.add_child(close_btn)
	return header


## Decorative disabled input bar — this viewer is read-only evidence.
func _build_input_bar() -> Control:
	var bar := PanelContainer.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = COLOR_INPUT_BAR
	bsb.corner_radius_bottom_left = 12
	bsb.corner_radius_bottom_right = 12
	bsb.content_margin_left = 12.0
	bsb.content_margin_right = 12.0
	bsb.content_margin_top = 8.0
	bsb.content_margin_bottom = 8.0
	bar.add_theme_stylebox_override("panel", bsb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)

	var input_pill := PanelContainer.new()
	input_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color.WHITE
	psb.set_corner_radius_all(14)
	psb.content_margin_left = 12.0
	psb.content_margin_right = 12.0
	psb.content_margin_top = 6.0
	psb.content_margin_bottom = 6.0
	input_pill.add_theme_stylebox_override("panel", psb)
	var ph := Label.new()
	ph.text = "Message"
	ph.add_theme_font_size_override("font_size", 14)
	ph.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	input_pill.add_child(ph)
	row.add_child(input_pill)

	var send := Label.new()
	send.text = "➤"
	send.add_theme_font_size_override("font_size", 20)
	send.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	send.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(send)
	return bar


# ─────────────────────────────────────────────────────────────
# Message rows
# ─────────────────────────────────────────────────────────────
func _reveal_next_message() -> void:
	if _next_msg_idx >= _message_count():
		return
	_append_message_row(_next_msg_idx)
	_next_msg_idx += 1
	if _tap_hint != null and _next_msg_idx >= _message_count():
		_tap_hint.text = "— End of conversation —"
	_scroll_to_bottom.call_deferred()


func _scroll_to_bottom() -> void:
	if _scroll == null:
		return
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _append_message_row(idx: int) -> void:
	var msgs: Array = _messages()
	if idx < 0 or idx >= msgs.size():
		return
	var m: Variant = msgs[idx]
	if not m is Dictionary:
		return
	var md: Dictionary = m as Dictionary
	var sender: String = str(md.get("from", "")).strip_edges()
	var is_right: bool = sender == _right_side
	var prev_sender: String = ""
	if idx > 0 and msgs[idx - 1] is Dictionary:
		prev_sender = str((msgs[idx - 1] as Dictionary).get("from", "")).strip_edges()
	var show_identity: bool = not is_right and sender != prev_sender

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	_msg_vbox.add_child(row)

	if is_right:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		row.add_child(_make_time_label(str(md.get("time", "")), true))
		row.add_child(_make_bubble(md, true))
	else:
		row.add_child(_make_avatar(sender, show_identity))
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", 2)
		if show_identity:
			var name_lbl := Label.new()
			name_lbl.text = sender
			name_lbl.add_theme_font_size_override("font_size", 12)
			name_lbl.add_theme_color_override("font_color", COLOR_NAME)
			if _text_font != null:
				name_lbl.add_theme_font_override("font", _text_font)
			stack.add_child(name_lbl)
		var bubble_row := HBoxContainer.new()
		bubble_row.add_theme_constant_override("separation", 6)
		bubble_row.add_child(_make_bubble(md, false))
		bubble_row.add_child(_make_time_label(str(md.get("time", "")), false))
		stack.add_child(bubble_row)
		row.add_child(stack)
		var end_spacer := Control.new()
		end_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(end_spacer)


func _make_avatar(sender: String, visible_avatar: bool) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(AVATAR_SIZE, AVATAR_SIZE)
	holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if not visible_avatar:
		return holder
	var path: String = str(_avatars.get(sender, "")).strip_edges()
	if path.is_empty() or not ResourceLoader.exists(path):
		var ph := ColorRect.new()
		ph.color = Color(0.35, 0.40, 0.50)
		ph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(ph)
		return holder
	var tex := load(path) as Texture2D
	if tex == null:
		return holder
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.clip_contents = true
	holder.add_child(rect)
	return holder


func _make_time_label(time_text: String, _right: bool) -> Label:
	var lbl := Label.new()
	lbl.text = time_text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", COLOR_TIME)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_END
	return lbl


func _make_bubble(md: Dictionary, is_right: bool) -> Control:
	var bubble := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_BUBBLE_RIGHT if is_right else COLOR_BUBBLE_LEFT
	sb.set_corner_radius_all(14)
	if is_right:
		sb.corner_radius_top_right = 4
	else:
		sb.corner_radius_top_left = 4
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	bubble.add_theme_stylebox_override("panel", sb)
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	bubble.add_child(content)

	var image_path: String = str(md.get("image", "")).strip_edges()
	if not image_path.is_empty():
		if ResourceLoader.exists(image_path):
			var tex := load(image_path) as Texture2D
			if tex != null:
				var img := TextureRect.new()
				img.texture = tex
				img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
				var ratio: float = float(tex.get_height()) / maxf(float(tex.get_width()), 1.0)
				img.custom_minimum_size = Vector2(IMAGE_MAX_W, IMAGE_MAX_W * ratio)
				content.add_child(img)
		else:
			push_warning("MessengerOverlay: image '%s' not found" % image_path)

	var text: String = str(md.get("text", ""))
	if not text.is_empty():
		var lbl := Label.new()
		lbl.text = text
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(0, 0)
		lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if _text_font != null:
			lbl.add_theme_font_override("font", _text_font)
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		# Natural width for short messages, capped so long ones wrap.
		# Without an explicit minimum, autowrap labels collapse in HBox layouts.
		var base_font: Font = _text_font if _text_font != null else get_theme_default_font()
		if base_font != null:
			var w: float = base_font.get_string_size(
				text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15).x
			lbl.custom_minimum_size.x = minf(w + 4.0, BUBBLE_MAX_W)
		content.add_child(lbl)

	return bubble
