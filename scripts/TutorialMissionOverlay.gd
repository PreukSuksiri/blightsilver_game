extends Node
# Full-screen tutorial overlay: dim + undimmed spotlight, bouncing arrow, cursor tooltip,
# and input blocking outside the undimmed circle.
# Added as a child of GameBoard at the very end of _ready(), so its _input fires first.

const SHADER_PATH := "res://assets/shaders/tutorial_dim.gdshader"

var _active: bool = false
var _center: Vector2 = Vector2.ZERO
var _radius: float = 64.0

# Visual nodes
var _canvas: CanvasLayer = null
var _dim_rect: ColorRect = null
var _ring_draw: Control = null      # draws the highlight ring
var _arrow_lbl: Label = null
var _tooltip_lbl: Label = null
var _arrow_tween: Tween = null
var _tooltip_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	_build_canvas()

func _build_canvas() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 200
	add_child(_canvas)

	# Full-screen dim with shader hole
	_dim_rect = ColorRect.new()
	_dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim_rect.visible = false
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	_dim_rect.material = mat
	_canvas.add_child(_dim_rect)

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

## Show full-screen dim with no interaction area (while checking impossibility).
func show_checking() -> void:
	_active = false
	_dim_rect.visible = true
	var mat := _dim_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("circle_radius", 0.0)
	_ring_draw.visible = false
	_arrow_lbl.visible = false
	_tooltip_lbl.visible = false

## Show the mission spotlight at a given screen position.
func show_mission(center: Vector2, radius: float, instruction: String) -> void:
	_active = true
	_center = center
	_radius = radius

	_dim_rect.visible = true
	var mat := _dim_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("circle_center", center)
		mat.set_shader_parameter("circle_radius", radius)

	_ring_draw.visible = true
	_ring_draw.queue_redraw()

	_start_arrow(center, radius)
	_tooltip_lbl.text = instruction
	_tooltip_lbl.visible = not instruction.is_empty()

## Hide the overlay entirely.
func hide_overlay() -> void:
	_active = false
	_center = Vector2.ZERO
	_dim_rect.visible = false
	_ring_draw.visible = false
	_arrow_lbl.visible = false
	_tooltip_lbl.visible = false
	if _arrow_tween != null and _arrow_tween.is_valid():
		_arrow_tween.kill()

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
