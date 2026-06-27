extends Control
class_name ProtagonistOverlay
## Protagonist picker — hero capsules with arrow / wheel pose cycling.

signal closed

const CAPSULE_W := 180.0
const CAPSULE_H := 300.0
const ARROW_H := 30.0
const SELECT_CYAN := Color(0.20, 0.95, 1.0, 1.0)
const SELECT_GLOW := Color(0.20, 0.95, 1.0, 0.65)
const CAPSULE_BG := Color(0.96, 0.97, 0.98, 1.0)
const CAPSULE_BORDER_IDLE := Color(0.82, 0.84, 0.88, 1.0)
const ARROW_BOUNCE_OFFSET := 7.0
const ARROW_BOUNCE_HALF := 0.28

var _selected_id: String = ""
var _selected_portrait: String = ""
var _capsules: Dictionary = {}
var _arrow_bounce_tween: Tween = null
var _scroll_accum: float = 0.0


static func open(parent: Node) -> void:
	var overlay: ProtagonistOverlay = ProtagonistOverlay.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 80
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)


func _ready() -> void:
	_selected_id = SaveManager.quick_duel_protagonist_id
	_selected_portrait = SaveManager.get_protagonist_portrait_path()
	_build_ui()
	_refresh_capsules()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
		return
	var delta: int = _consume_wheel_delta(event)
	if delta == 0:
		return
	if not _can_cycle_pose() or not _is_mouse_over_selected_column():
		return
	_cycle_pose(delta)
	get_viewport().set_input_as_handled()


func _consume_wheel_delta(event: InputEvent) -> int:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				return -1
			MOUSE_BUTTON_WHEEL_DOWN:
				return 1
	elif event is InputEventPanGesture:
		_scroll_accum += event.delta.y
		if _scroll_accum >= 48.0:
			_scroll_accum = 0.0
			return 1
		if _scroll_accum <= -48.0:
			_scroll_accum = 0.0
			return -1
	return 0


func _handle_pose_scroll(event: InputEvent, protagonist_id: String, control: Control) -> void:
	if protagonist_id != _selected_id or not _can_cycle_pose():
		return
	var delta: int = _consume_wheel_delta(event)
	if delta == 0:
		return
	_cycle_pose(delta)
	control.accept_event()


func _bind_pose_scroll(protagonist_id: String, controls: Array) -> void:
	for ctrl: Variant in controls:
		var node: Control = ctrl as Control
		if node == null:
			continue
		node.gui_input.connect(
			func(event: InputEvent) -> void: _handle_pose_scroll(event, protagonist_id, node))


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.10, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_build_top_actions()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	root.offset_left = -520.0
	root.offset_right = 520.0
	root.offset_top = -300.0
	root.offset_bottom = 300.0
	root.add_theme_constant_override("separation", 20)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)

	var title := Label.new()
	title.text = "Select your character..."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	root.add_child(title)

	var hero_row := HBoxContainer.new()
	hero_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_row.add_theme_constant_override("separation", 20)
	root.add_child(hero_row)

	for protagonist_id: String in ProtagonistVault.get_protagonist_ids():
		var capsule := _build_protagonist_capsule(protagonist_id)
		hero_row.add_child(capsule["root"])
		_capsules[protagonist_id] = capsule

	var hint := Label.new()
	hint.text = "Use ▲ ▼ or mouse wheel to change pose"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.55, 0.68, 0.82))
	root.add_child(hint)


func _build_top_actions() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	row.offset_left = -196.0
	row.offset_top = 12.0
	row.offset_right = -12.0
	row.offset_bottom = 48.0
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	row.z_index = 2
	add_child(row)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.custom_minimum_size = Vector2(88, 36)
	save_btn.add_theme_font_size_override("font_size", 15)
	save_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	var save_sb := StyleBoxFlat.new()
	save_sb.bg_color = Color(0.12, 0.55, 0.28, 1.0)
	save_sb.set_corner_radius_all(6)
	save_sb.border_color = Color(0.35, 0.85, 0.45, 1.0)
	save_sb.set_border_width_all(1)
	save_btn.add_theme_stylebox_override("normal", save_sb)
	var save_hover := save_sb.duplicate() as StyleBoxFlat
	save_hover.bg_color = Color(0.16, 0.65, 0.34, 1.0)
	save_btn.add_theme_stylebox_override("hover", save_hover)
	var save_pressed := save_sb.duplicate() as StyleBoxFlat
	save_pressed.bg_color = Color(0.10, 0.45, 0.22, 1.0)
	save_btn.add_theme_stylebox_override("pressed", save_pressed)
	save_btn.add_theme_stylebox_override("focus", save_sb)
	save_btn.pressed.connect(_on_done)
	row.add_child(save_btn)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(38, 36)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(0.55, 0.72, 1.0, 0.85))
	var close_sb := _make_close_stylebox()
	close_btn.add_theme_stylebox_override("normal", close_sb)
	close_btn.add_theme_stylebox_override("hover", close_sb)
	close_btn.add_theme_stylebox_override("pressed", close_sb)
	close_btn.add_theme_stylebox_override("focus", close_sb)
	close_btn.pressed.connect(_close)
	row.add_child(close_btn)


func _make_close_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.04, 0.04, 1.0)
	sb.set_border_width_all(1)
	sb.border_color = Color(1.0, 0.30, 0.30, 0.7)
	sb.set_corner_radius_all(4)
	return sb


func _make_arrow_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.20, 0.85)
	sb.border_color = Color(0.35, 0.75, 0.95, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	return sb


func _make_arrow_wrap(is_up: bool) -> Dictionary:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(CAPSULE_W, ARROW_H)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var btn := _make_pose_arrow(is_up)
	btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	btn.size = Vector2(CAPSULE_W, ARROW_H)
	wrap.add_child(btn)
	return {"wrap": wrap, "btn": btn}


func _make_pose_arrow(is_up: bool) -> Button:
	var btn := Button.new()
	btn.text = "▲" if is_up else "▼"
	btn.custom_minimum_size = Vector2(CAPSULE_W, ARROW_H)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", SELECT_CYAN)
	var sb := _make_arrow_stylebox()
	btn.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.20, 0.30, 0.95)
	hover.border_color = SELECT_CYAN
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", sb)
	btn.visible = false
	btn.pressed.connect(func() -> void: _cycle_pose(-1 if is_up else 1))
	return btn


func _make_capsule_stylebox(selected: bool, radius: int, border_w: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CAPSULE_BG
	sb.set_corner_radius_all(radius)
	if selected:
		sb.border_color = SELECT_CYAN
		sb.set_border_width_all(border_w)
		sb.shadow_color = SELECT_GLOW
		sb.shadow_size = 12
		sb.shadow_offset = Vector2.ZERO
	else:
		sb.border_color = CAPSULE_BORDER_IDLE
		sb.set_border_width_all(2)
		sb.shadow_size = 0
	return sb


func _build_protagonist_capsule(protagonist_id: String) -> Dictionary:
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(CAPSULE_W, CAPSULE_H + 36.0)
	root.add_theme_constant_override("separation", 6)
	root.alignment = BoxContainer.ALIGNMENT_CENTER

	var up_pair := _make_arrow_wrap(true)
	var up_wrap: Control = up_pair["wrap"]
	var up_btn: Button = up_pair["btn"]
	root.add_child(up_wrap)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(CAPSULE_W, CAPSULE_H)
	btn.toggle_mode = true
	_apply_capsule_button_style(btn)
	btn.pressed.connect(func() -> void: _select_protagonist(protagonist_id))
	btn.mouse_entered.connect(_on_capsule_hover_enter.bind(protagonist_id))
	btn.mouse_exited.connect(_on_capsule_hover_exit.bind(protagonist_id))
	root.add_child(btn)

	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _make_capsule_stylebox(false, 10, 4))
	btn.add_child(frame)

	var inner := Control.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.clip_contents = true
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(inner)

	var tex_rect := TextureRect.new()
	tex_rect.name = "Portrait"
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(tex_rect)

	var down_pair := _make_arrow_wrap(false)
	var down_wrap: Control = down_pair["wrap"]
	var down_btn: Button = down_pair["btn"]
	root.add_child(down_wrap)

	var name_lbl := Label.new()
	name_lbl.text = ProtagonistVault.get_display_name(protagonist_id)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))
	root.add_child(name_lbl)

	var pose_lbl := Label.new()
	pose_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pose_lbl.add_theme_font_size_override("font_size", 11)
	pose_lbl.add_theme_color_override("font_color", Color(0.55, 0.72, 0.88))
	pose_lbl.visible = false
	root.add_child(pose_lbl)

	_bind_pose_scroll(protagonist_id, [
		root, btn, up_wrap, down_wrap, up_btn, down_btn, name_lbl, pose_lbl,
	])

	return {
		"root": root,
		"up_wrap": up_wrap,
		"down_wrap": down_wrap,
		"up_btn": up_btn,
		"down_btn": down_btn,
		"btn": btn,
		"frame": frame,
		"portrait": tex_rect,
		"label": name_lbl,
		"pose_lbl": pose_lbl,
	}


func _apply_capsule_button_style(btn: Button) -> void:
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)


func _portraits_for_selected() -> Array[String]:
	return ProtagonistVault.list_portraits(_selected_id)


func _current_pose_index(portraits: Array[String]) -> int:
	if portraits.is_empty():
		return 0
	var idx: int = portraits.find(_selected_portrait)
	return idx if idx >= 0 else 0


func _portrait_path_for_capsule(protagonist_id: String) -> String:
	if protagonist_id == _selected_id and not _selected_portrait.is_empty():
		return _selected_portrait
	return ProtagonistVault.get_default_portrait(protagonist_id)


func _on_capsule_hover_enter(protagonist_id: String) -> void:
	if protagonist_id != _selected_id or not _can_cycle_pose():
		return
	_start_arrow_bounce()


func _on_capsule_hover_exit(protagonist_id: String) -> void:
	if protagonist_id != _selected_id:
		return
	_stop_arrow_bounce()


func _start_arrow_bounce() -> void:
	_stop_arrow_bounce()
	if not _can_cycle_pose():
		return
	var cap: Dictionary = _capsules.get(_selected_id, {})
	var up_btn: Button = cap.get("up_btn") as Button
	var down_btn: Button = cap.get("down_btn") as Button
	if up_btn == null or down_btn == null:
		return
	up_btn.position.y = 0.0
	down_btn.position.y = 0.0
	_arrow_bounce_tween = create_tween().set_loops()
	_arrow_bounce_tween.set_parallel(true)
	_arrow_bounce_tween.tween_property(
		up_btn, "position:y", -ARROW_BOUNCE_OFFSET, ARROW_BOUNCE_HALF
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_arrow_bounce_tween.tween_property(
		down_btn, "position:y", ARROW_BOUNCE_OFFSET, ARROW_BOUNCE_HALF
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_arrow_bounce_tween.chain().set_parallel(true)
	_arrow_bounce_tween.tween_property(
		up_btn, "position:y", 0.0, ARROW_BOUNCE_HALF
	).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_arrow_bounce_tween.tween_property(
		down_btn, "position:y", 0.0, ARROW_BOUNCE_HALF
	).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _stop_arrow_bounce() -> void:
	if _arrow_bounce_tween != null and _arrow_bounce_tween.is_valid():
		_arrow_bounce_tween.kill()
	_arrow_bounce_tween = null
	if _selected_id.is_empty():
		return
	var cap: Dictionary = _capsules.get(_selected_id, {})
	for key: String in ["up_btn", "down_btn"]:
		var btn: Button = cap.get(key) as Button
		if btn != null:
			btn.position.y = 0.0


func _is_mouse_over_selected_capsule() -> bool:
	var cap: Dictionary = _capsules.get(_selected_id, {})
	var btn: Button = cap.get("btn") as Button
	if btn == null:
		return false
	return btn.get_global_rect().has_point(get_global_mouse_position())


func _can_cycle_pose() -> bool:
	if _selected_id.is_empty():
		return false
	return _portraits_for_selected().size() > 1


func _is_mouse_over_selected_column() -> bool:
	var cap: Dictionary = _capsules.get(_selected_id, {})
	var pos: Vector2 = get_global_mouse_position()
	for key: String in ["root", "btn", "up_wrap", "down_wrap"]:
		var ctrl: Control = cap.get(key) as Control
		if ctrl != null and ctrl.get_global_rect().has_point(pos):
			return true
	return false


func _cycle_pose(delta: int) -> void:
	if not _can_cycle_pose():
		return
	var portraits: Array[String] = _portraits_for_selected()
	var idx: int = _current_pose_index(portraits)
	idx = (idx + delta) % portraits.size()
	if idx < 0:
		idx += portraits.size()
	_selected_portrait = portraits[idx]
	_refresh_capsules()


func _select_protagonist(protagonist_id: String) -> void:
	_selected_id = protagonist_id
	_selected_portrait = ProtagonistVault.get_first_unlocked_portrait(protagonist_id)
	_refresh_capsules()


func _refresh_capsules() -> void:
	_stop_arrow_bounce()
	var selected_portraits: Array[String] = _portraits_for_selected()
	var selected_pose_idx: int = _current_pose_index(selected_portraits)
	for protagonist_id: String in _capsules.keys():
		var cap: Dictionary = _capsules[protagonist_id]
		var btn: Button = cap.get("btn")
		var frame: PanelContainer = cap.get("frame")
		var tex_rect: TextureRect = cap.get("portrait")
		var up_btn: Button = cap.get("up_btn")
		var down_btn: Button = cap.get("down_btn")
		var up_wrap: Control = cap.get("up_wrap")
		var down_wrap: Control = cap.get("down_wrap")
		var pose_lbl: Label = cap.get("pose_lbl")
		var selected: bool = protagonist_id == _selected_id
		var portraits: Array[String] = ProtagonistVault.list_portraits(protagonist_id)
		var show_pose_ui: bool = selected and portraits.size() > 1
		if btn != null:
			btn.button_pressed = selected
		if frame != null:
			frame.add_theme_stylebox_override(
				"panel", _make_capsule_stylebox(selected, 10, 4))
		if tex_rect != null:
			var path: String = _portrait_path_for_capsule(protagonist_id)
			tex_rect.texture = GameState.load_portrait_texture(path)
			var locked_pose: bool = selected \
					and not ProtagonistVault.is_pose_portrait_unlocked(protagonist_id, path)
			tex_rect.modulate = Color(0.06, 0.06, 0.06, 1.0) if locked_pose else Color.WHITE
		if up_btn != null:
			up_btn.visible = show_pose_ui
			up_btn.custom_minimum_size.y = ARROW_H if show_pose_ui else 0.0
			up_btn.mouse_filter = Control.MOUSE_FILTER_STOP if show_pose_ui else Control.MOUSE_FILTER_IGNORE
		if down_btn != null:
			down_btn.visible = show_pose_ui
			down_btn.custom_minimum_size.y = ARROW_H if show_pose_ui else 0.0
			down_btn.mouse_filter = Control.MOUSE_FILTER_STOP if show_pose_ui else Control.MOUSE_FILTER_IGNORE
		if up_wrap != null:
			up_wrap.visible = show_pose_ui
			up_wrap.custom_minimum_size.y = ARROW_H if show_pose_ui else 0.0
		if down_wrap != null:
			down_wrap.visible = show_pose_ui
			down_wrap.custom_minimum_size.y = ARROW_H if show_pose_ui else 0.0
		if pose_lbl != null:
			pose_lbl.visible = show_pose_ui
			if show_pose_ui:
				var locked_sel: bool = not ProtagonistVault.is_pose_portrait_unlocked(
					_selected_id, _selected_portrait)
				var suffix: String = " · Locked" if locked_sel else ""
				pose_lbl.text = "Pose %d / %d%s" % [
					selected_pose_idx + 1, portraits.size(), suffix]
		var col_root: VBoxContainer = cap.get("root") as VBoxContainer
		if col_root != null:
			var name_h := 36.0
			var pose_h := 18.0 if show_pose_ui else 0.0
			var arrow_h := ARROW_H * 2.0 if show_pose_ui else 0.0
			col_root.custom_minimum_size = Vector2(CAPSULE_W, CAPSULE_H + arrow_h + name_h + pose_h)
	if _can_cycle_pose() and _is_mouse_over_selected_capsule():
		_start_arrow_bounce()


func _on_done() -> void:
	if not ProtagonistVault.is_pose_portrait_unlocked(_selected_id, _selected_portrait):
		_selected_portrait = ProtagonistVault.get_first_unlocked_portrait(_selected_id)
	if _selected_portrait.is_empty():
		_selected_portrait = ProtagonistVault.get_default_portrait(_selected_id)
	SaveManager.set_protagonist(_selected_id, _selected_portrait)
	_close()


func _close() -> void:
	_stop_arrow_bounce()
	closed.emit()
	queue_free()
