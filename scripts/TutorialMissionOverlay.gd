extends Node
# Tutorial mission overlay: spotlight ring, bouncing arrow, cursor tooltip,
# and input blocking outside the spotlight circle.
# Added as a child of GameBoard at the very end of _ready(), so its _input fires first.

var _active: bool = false
var _center: Vector2 = Vector2.ZERO
var _radius: float = 64.0

# Visual nodes
var _canvas: CanvasLayer = null
var _ring_draw: Control = null      # draws the highlight ring
var _arrow_lbl: Label = null
var _tooltip_lbl: Label = null
var _arrow_tween: Tween = null
var _tooltip_pos: Vector2 = Vector2.ZERO
var _message_layer: Control = null
var _wait_active: bool = false
var _wait_layer: Control = null

func _ready() -> void:
	_build_canvas()

func _build_canvas() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 200
	add_child(_canvas)

	# Ring highlight drawn on top
	_ring_draw = Control.new()
	_ring_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ring_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring_draw.visible = false
	_ring_draw.draw.connect(_on_ring_draw)
	_canvas.add_child(_ring_draw)

	# Bouncing arrow (▼)
	_arrow_lbl = Label.new()
	_arrow_lbl.text = "▼"
	_arrow_lbl.add_theme_font_size_override("font_size", 32)
	_arrow_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	_arrow_lbl.visible = false
	_arrow_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_arrow_lbl)

	# Cursor tooltip label
	_tooltip_lbl = Label.new()
	_tooltip_lbl.add_theme_font_size_override("font_size", 14)
	_tooltip_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_tooltip_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	_tooltip_lbl.add_theme_constant_override("shadow_offset_x", 1)
	_tooltip_lbl.add_theme_constant_override("shadow_offset_y", 1)
	_tooltip_lbl.custom_minimum_size = Vector2(200, 0)
	_tooltip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_lbl.visible = false
	_tooltip_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_tooltip_lbl)

func _on_ring_draw() -> void:
	if not _active or _center == Vector2.ZERO:
		return
	# Bright outer glow ring
	_ring_draw.draw_arc(_center, _radius + 4.0, 0.0, TAU, 64, Color(1.0, 0.9, 0.2, 0.85), 3.0)
	_ring_draw.draw_arc(_center, _radius + 8.0, 0.0, TAU, 64, Color(1.0, 0.9, 0.2, 0.35), 2.0)

# ─────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────

## Hide mission visuals while checking impossibility / loading sub-menus.
func show_checking() -> void:
	_active = false
	_ring_draw.visible = false
	_arrow_lbl.visible = false
	_tooltip_lbl.visible = false
	_hide_message_dialog()
	_hide_wait()

## Show the mission spotlight at a given screen position.
func show_mission(center: Vector2, radius: float, instruction: String) -> void:
	_active = true
	_center = center
	_radius = radius

	_ring_draw.visible = true
	_ring_draw.queue_redraw()

	_start_arrow(center, radius)
	_tooltip_lbl.text = instruction
	_tooltip_lbl.visible = not instruction.is_empty()

## Centered message dialog with OK — satisfies show_message missions.
func show_message(text: String) -> void:
	_active = false
	_center = Vector2.ZERO
	_ring_draw.visible = false
	_arrow_lbl.visible = false
	_tooltip_lbl.visible = false
	if _arrow_tween != null and _arrow_tween.is_valid():
		_arrow_tween.kill()
	_hide_message_dialog()

	_message_layer = Control.new()
	_message_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_message_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.add_child(_message_layer)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_message_layer.add_child(dim)

	var center_wrap := CenterContainer.new()
	center_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_layer.add_child(center_wrap)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440.0, 0.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_message_stylebox())
	center_wrap.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "MESSAGE"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0, 0.95))
	vbox.add_child(title_lbl)

	var msg_lbl := Label.new()
	msg_lbl.text = text
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_lbl.custom_minimum_size = Vector2(360.0, 0.0)
	msg_lbl.add_theme_font_size_override("font_size", 18)
	msg_lbl.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	vbox.add_child(msg_lbl)

	var ok_btn := Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(120.0, 42.0)
	ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok_btn.add_theme_font_size_override("font_size", 16)
	var ok_sb := StyleBoxFlat.new()
	ok_sb.bg_color = Color(0.10, 0.18, 0.38, 1.0)
	ok_sb.corner_radius_top_left = 6; ok_sb.corner_radius_top_right = 6
	ok_sb.corner_radius_bottom_right = 6; ok_sb.corner_radius_bottom_left = 6
	ok_btn.add_theme_stylebox_override("normal", ok_sb)
	var ok_hover := ok_sb.duplicate() as StyleBoxFlat
	ok_hover.bg_color = Color(0.16, 0.28, 0.55, 1.0)
	ok_btn.add_theme_stylebox_override("hover", ok_hover)
	ok_btn.pressed.connect(func() -> void:
		_hide_message_dialog()
		TutorialBattleManager.report_action("message_ok", {}))
	vbox.add_child(ok_btn)

func _make_message_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 0.98)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.55, 0.78, 1.0, 0.7)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	sb.shadow_size = 8
	return sb

func _hide_message_dialog() -> void:
	if _message_layer != null and is_instance_valid(_message_layer):
		_message_layer.queue_free()
	_message_layer = null

## Invisible full-screen wait lock — blocks input, no on-screen visuals.
func show_wait() -> void:
	_active = false
	_center = Vector2.ZERO
	_ring_draw.visible = false
	_arrow_lbl.visible = false
	_tooltip_lbl.visible = false
	if _arrow_tween != null and _arrow_tween.is_valid():
		_arrow_tween.kill()
	_hide_message_dialog()
	_hide_wait()

	_wait_active = true
	_wait_layer = Control.new()
	_wait_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wait_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.add_child(_wait_layer)

func hide_wait() -> void:
	_hide_wait()

func _hide_wait() -> void:
	_wait_active = false
	if _wait_layer != null and is_instance_valid(_wait_layer):
		_wait_layer.queue_free()
	_wait_layer = null

## Hide the overlay entirely.
func hide_overlay() -> void:
	_active = false
	_center = Vector2.ZERO
	_ring_draw.visible = false
	_arrow_lbl.visible = false
	_tooltip_lbl.visible = false
	if _arrow_tween != null and _arrow_tween.is_valid():
		_arrow_tween.kill()
	_hide_message_dialog()
	_hide_wait()

func is_shown() -> bool:
	return _active

# ─────────────────────────────────────────────────────────────
# Arrow Animation
# ─────────────────────────────────────────────────────────────

func _start_arrow(center: Vector2, radius: float) -> void:
	if _arrow_tween != null and _arrow_tween.is_valid():
		_arrow_tween.kill()

	var base_y := center.y - radius - 48.0
	_arrow_lbl.position = Vector2(center.x - 16.0, base_y)
	_arrow_lbl.visible = true

	_arrow_tween = create_tween().set_loops()
	_arrow_tween.tween_property(_arrow_lbl, "position:y", base_y - 12.0, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_arrow_tween.tween_property(_arrow_lbl, "position:y", base_y, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ─────────────────────────────────────────────────────────────
# Tooltip follows cursor
# ─────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not _tooltip_lbl.visible:
		return
	var mp := get_viewport().get_mouse_position()
	_tooltip_lbl.position = mp + Vector2(18.0, -40.0)
	# Keep within viewport
	var vp := get_viewport().get_visible_rect().size
	_tooltip_lbl.position.x = clampf(_tooltip_lbl.position.x, 0.0, vp.x - _tooltip_lbl.size.x - 4.0)
	_tooltip_lbl.position.y = clampf(_tooltip_lbl.position.y, 0.0, vp.y - _tooltip_lbl.size.y - 4.0)

# ─────────────────────────────────────────────────────────────
# Input Blocking
# ─────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if _wait_active:
		get_viewport().set_input_as_handled()
		return

	if not _active:
		return

	var pos := Vector2.ZERO
	var is_press := false

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		is_press = mb.pressed
		pos = mb.global_position
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		is_press = st.pressed
		pos = st.position
	else:
		return

	if not is_press:
		return

	if _center != Vector2.ZERO and pos.distance_to(_center) <= _radius:
		return  # Within spotlight — let the event through

	# Outside spotlight — block
	get_viewport().set_input_as_handled()
