extends Control
# QuickDuelRewardEditor — admin overlay for editing quick_duel_rewards.json.

const _BG_COLOR := Color(0.05, 0.05, 0.10, 0.97)
const _HEADER_COLOR := Color(0.10, 0.12, 0.22, 1.0)
const _BTN_SAVE := Color(0.12, 0.55, 0.28, 1.0)
const _BTN_CLOSE := Color(0.55, 0.12, 0.12, 1.0)

var _json_edit: TextEdit = null
var _status_lbl: Label = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 90

	var bg := ColorRect.new()
	bg.color = _BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := Panel.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.custom_minimum_size = Vector2(0, 52)
	add_child(header)

	var title := Label.new()
	title.text = "Quick Duel Reward Editor"
	title.add_theme_font_size_override("font_size", 20)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -48
	close_btn.offset_top = 4
	close_btn.offset_right = -4
	close_btn.offset_bottom = 48
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	_json_edit = TextEdit.new()
	_json_edit.set_anchor(SIDE_LEFT, 0.0)
	_json_edit.set_anchor(SIDE_RIGHT, 1.0)
	_json_edit.set_anchor(SIDE_TOP, 0.0)
	_json_edit.set_anchor(SIDE_BOTTOM, 1.0)
	_json_edit.offset_top = 52
	_json_edit.offset_bottom = -52
	_json_edit.syntax_highlighter = CodeHighlighter.new()
	add_child(_json_edit)
	_json_edit.text = JSON.stringify(QuickDuelRewards.get_data(), "\t")

	var bot := Panel.new()
	bot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot.custom_minimum_size = Vector2(0, 52)
	add_child(bot)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.add_theme_constant_override("separation", 12)
	bot.add_child(row)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save)
	row.add_child(save_btn)

	var reload_btn := Button.new()
	reload_btn.text = "Reload"
	reload_btn.pressed.connect(func() -> void:
		QuickDuelRewards.reload()
		_json_edit.text = JSON.stringify(QuickDuelRewards.get_data(), "\t")
		_status_lbl.text = "Reloaded from disk.")
	row.add_child(reload_btn)

	_status_lbl = Label.new()
	_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_status_lbl)


func _on_save() -> void:
	var parsed: Variant = JSON.parse_string(_json_edit.text)
	if not parsed is Dictionary:
		_status_lbl.text = "Invalid JSON."
		return
	if QuickDuelRewards.save_data(parsed as Dictionary):
		_status_lbl.text = "Saved."
	else:
		_status_lbl.text = "Save failed."
