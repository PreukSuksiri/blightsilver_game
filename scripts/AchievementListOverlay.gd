extends Control
class_name AchievementListOverlay

enum Filter { ALL, COMPLETED, IN_PROGRESS }

const FILTER_LABELS := ["All", "Completed", "In progress"]

var _filter: Filter = Filter.ALL
var _list: VBoxContainer = null
var _counter_lbl: Label = null
var _chip_row: HBoxContainer = null


static func open(parent: Node) -> void:
	var overlay := AchievementListOverlay.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 80
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)


func _ready() -> void:
	_build_ui()
	_refresh_list()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.04, 0.09, 0.94)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := HBoxContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 16.0
	header.offset_top = 10.0
	header.offset_right = -16.0
	header.offset_bottom = 48.0
	add_child(header)

	var title := Label.new()
	title.text = "Achievements"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)

	_counter_lbl = Label.new()
	_counter_lbl.add_theme_font_size_override("font_size", 14)
	_counter_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 0.95))
	header.add_child(_counter_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(38, 32)
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	_chip_row = HBoxContainer.new()
	_chip_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_chip_row.offset_left = 16.0
	_chip_row.offset_top = 52.0
	_chip_row.offset_right = -16.0
	_chip_row.offset_bottom = 88.0
	_chip_row.add_theme_constant_override("separation", 8)
	add_child(_chip_row)
	for i: int in range(FILTER_LABELS.size()):
		var chip := Button.new()
		chip.text = FILTER_LABELS[i]
		chip.toggle_mode = true
		chip.button_pressed = i == int(_filter)
		var idx: int = i
		chip.pressed.connect(func() -> void: _set_filter(idx))
		_chip_row.add_child(chip)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 96.0
	scroll.offset_bottom = -12.0
	scroll.offset_left = 12.0
	scroll.offset_right = -12.0
	add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)


func _set_filter(idx: int) -> void:
	_filter = idx as Filter
	for i: int in range(_chip_row.get_child_count()):
		var chip: Button = _chip_row.get_child(i) as Button
		if chip != null:
			chip.button_pressed = i == idx
	_refresh_list()


func _refresh_list() -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	var unlocked: int = AchievementManager.get_unlocked_count()
	var total: int = AchievementManager.get_total_count()
	_counter_lbl.text = "%d / %d unlocked" % [unlocked, total]

	for def: Variant in AchievementManager.get_definitions():
		if not def is Dictionary:
			continue
		var d: Dictionary = def as Dictionary
		var id: String = str(d.get("id", ""))
		if id.is_empty():
			continue
		if not _passes_filter(id, d):
			continue
		_list.add_child(_make_row(id, d))


func _passes_filter(id: String, def: Dictionary) -> bool:
	var is_unlocked: bool = AchievementManager.is_unlocked(id)
	match _filter:
		Filter.COMPLETED:
			return is_unlocked
		Filter.IN_PROGRESS:
			if is_unlocked:
				return false
			var kind: String = str(def.get("progress_kind", "none"))
			return kind != "none" and int(def.get("progress_target", 0)) > 0
		_:
			return true


func _make_row(id: String, def: Dictionary) -> PanelContainer:
	var unlocked: bool = AchievementManager.is_unlocked(id)
	var hidden: bool = bool(def.get("hidden", false)) and not unlocked
	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.14, 0.92)
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(2)
	if unlocked:
		sb.border_color = Color(0.2, 0.85, 1.0, 0.75)
	else:
		sb.border_color = Color(0.35, 0.38, 0.42, 0.6)
	row.add_theme_stylebox_override("panel", sb)
	row.modulate.a = 1.0 if unlocked else 0.62

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.custom_minimum_size.y = 72.0
	row.add_child(h)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_path: String = AchievementManager.get_icon_path(def)
	if not icon_path.is_empty():
		icon.texture = load(icon_path)
	h.add_child(icon)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 2)
	h.add_child(body)

	var title := Label.new()
	if hidden:
		title.text = "???"
	else:
		title.text = str(def.get("title", id))
	title.add_theme_font_size_override("font_size", 15)
	body.add_child(title)

	var cond := Label.new()
	if hidden:
		var hint: String = str(def.get("hidden_hint", "")).strip_edges()
		cond.text = hint if not hint.is_empty() else "Complete a secret challenge."
	else:
		cond.text = str(def.get("condition", ""))
	cond.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cond.add_theme_font_size_override("font_size", 12)
	cond.add_theme_color_override("font_color", Color(0.65, 0.72, 0.8))
	body.add_child(cond)

	var reward_lbl := Label.new()
	reward_lbl.text = AchievementManager.format_row_reward_preview(
		id, def.get("reward", {}) as Dictionary)
	reward_lbl.add_theme_font_size_override("font_size", 11)
	reward_lbl.add_theme_color_override("font_color", Color(0.55, 0.78, 0.55))
	body.add_child(reward_lbl)

	var kind: String = str(def.get("progress_kind", "none"))
	if kind != "none" and int(def.get("progress_target", 0)) > 0:
		var prog: Dictionary = AchievementManager.get_progress(id)
		var prog_lbl := Label.new()
		if unlocked:
			prog_lbl.text = "✓"
		else:
			prog_lbl.text = "%d / %d" % [int(prog.get("current", 0)), int(prog.get("target", 0))]
		prog_lbl.custom_minimum_size.x = 72.0
		prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(prog_lbl)

	return row
