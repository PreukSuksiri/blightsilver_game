extends Control
class_name ExplorationProtagonistSelect
## Full-bleed horizontal protagonist picker (2 = 50/50, 3 = 33/33/33).

signal selected(protagonist_id: String)

var _playable: Array = []
var _done: bool = false
var _result: String = ""


static func await_selection(parent: Node, playable_ids: Array) -> String:
	if parent == null:
		return SaveManager.current_protagonist_id
	var overlay := ExplorationProtagonistSelect.new()
	overlay.name = "ExplorationProtagonistSelect"
	overlay._playable = playable_ids.duplicate() if not playable_ids.is_empty() \
			else ["nex", "mayu", "kelly"]
	parent.add_child(overlay)
	var picked: String = await overlay.selected
	if is_instance_valid(overlay):
		overlay.queue_free()
	return picked


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 220
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.92)
	add_child(dim)
	var title := Label.new()
	title.text = "Choose Protagonist"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 24
	title.offset_bottom = 64
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)

	var ids: Array = []
	for pid: Variant in _playable:
		var s: String = ProtagonistVault.normalize_id(str(pid))
		if ProtagonistVault.is_valid_id(s) and s not in ids:
			ids.append(s)
	if ids.is_empty():
		ids = ["nex"]
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_top = 80
	row.offset_bottom = -24
	row.offset_left = 24
	row.offset_right = -24
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	for pid: Variant in ids:
		row.add_child(_make_column(str(pid), ids.size()))


func _make_column(pid: String, count: int) -> Control:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.clip_contents = true
	btn.focus_mode = Control.FOCUS_NONE
	var unlocked: bool = SaveManager.is_protagonist_unlocked(pid)
	btn.disabled = not unlocked
	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path: String = ProtagonistVault.get_first_unlocked_portrait(pid)
	if not path.is_empty() and ResourceLoader.exists(path):
		art.texture = load(path) as Texture2D
	elif ResourceLoader.exists("res://assets/textures/profile/eyes/eyes_%s.png" % pid):
		art.texture = load("res://assets/textures/profile/eyes/eyes_%s.png" % pid) as Texture2D
	art.modulate = Color.WHITE if unlocked else Color(0.06, 0.06, 0.06, 1.0)
	btn.add_child(art)
	var name_lbl := Label.new()
	name_lbl.text = ProtagonistVault.get_display_name(pid)
	name_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = -48
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_lbl.add_theme_constant_override("outline_size", 4)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_lbl)
	if not unlocked:
		name_lbl.text += " (Locked)"
	var captured: String = pid
	btn.pressed.connect(func() -> void:
		if not SaveManager.is_protagonist_unlocked(captured):
			return
		SaveManager.set_current_protagonist(captured, true)
		_result = captured
		_done = true
		selected.emit(captured))
	return btn
