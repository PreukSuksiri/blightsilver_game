class_name CardHoverHoldHint
extends Node
## Cursor-following hover-hold hint: bold dots every 0.5s, CardDetailOverlay at 2.5s.

const STEP_SEC := 0.5
const OPEN_SEC := 2.5
const MOVE_THRESHOLD_PX := 16.0
const DOT_CHAR := "•"
const CURSOR_OFFSET := Vector2(22.0, 52.0)  # below-right of finger cursor hotspot

var _canvas: CanvasLayer = null
var _tooltip_lbl: Label = null

var _host: Node = null
var _hover_control: WeakRef = null
var _card_name: String = ""
var _card_type: String = ""
var _anchor_mouse: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _active: bool = false
var _pause_reasons: Dictionary = {}
var _hold_overlay: CardDetailOverlay = null
var _overlay_pause_active: bool = false
var _opening_detail: bool = false
var _pin_overlay_to_host: bool = false


func _ready() -> void:
	_build_canvas()
	set_process(false)


func _build_canvas() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 150
	add_child(_canvas)

	_tooltip_lbl = Label.new()
	_tooltip_lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	_tooltip_lbl.add_theme_font_size_override("font_size", 24)
	_tooltip_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_tooltip_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	_tooltip_lbl.add_theme_constant_override("shadow_offset_x", 1)
	_tooltip_lbl.add_theme_constant_override("shadow_offset_y", 1)
	_tooltip_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_lbl.visible = false
	_canvas.add_child(_tooltip_lbl)


func is_active() -> bool:
	return _active


func begin(host: Node, hover_control: Control, card_name: String, card_type: String,
		pin_overlay_to_host: bool = false) -> void:
	if card_name.is_empty() or hover_control == null:
		return
	end()
	_host = host
	_pin_overlay_to_host = pin_overlay_to_host
	_hover_control = weakref(hover_control)
	_card_name = card_name
	_card_type = card_type
	_anchor_mouse = _mouse_pos()
	_elapsed = 0.0
	_active = true
	_tooltip_lbl.visible = false
	set_process(true)


func end() -> void:
	if _hold_overlay != null and is_instance_valid(_hold_overlay):
		_close_hold_overlay()
	_clear_session()


func on_hover_exited() -> void:
	# Full-screen detail overlay steals hover from the card; keep overlay until move/close.
	if _hold_overlay != null and is_instance_valid(_hold_overlay):
		return
	end()


func _clear_session() -> void:
	_active = false
	set_process(false)
	_hide_dots()
	_hover_control = null
	_host = null
	_overlay_pause_active = false
	_pause_reasons.clear()
	_card_name = ""
	_card_type = ""
	_elapsed = 0.0
	_hold_overlay = null


func set_pause(reason: StringName, paused: bool) -> void:
	var was_paused := _is_paused()
	if paused:
		_pause_reasons[reason] = int(_pause_reasons.get(reason, 0)) + 1
	else:
		var count: int = int(_pause_reasons.get(reason, 0)) - 1
		if count <= 0:
			_pause_reasons.erase(reason)
		else:
			_pause_reasons[reason] = count
	if was_paused and not _is_paused() and _active:
		_reset_progress()
	elif _is_paused():
		_hide_dots()


func _is_paused() -> bool:
	return not _pause_reasons.is_empty()


func _get_hover_control() -> Control:
	if _hover_control == null:
		return null
	return _hover_control.get_ref() as Control


func _process(delta: float) -> void:
	if not _active and _hold_overlay == null:
		return

	if _hold_overlay != null:
		_process_while_overlay_open()
		return

	_update_overlay_pause()

	var hover: Control = _get_hover_control()
	if hover == null or not is_instance_valid(hover):
		end()
		return

	var mouse := _mouse_pos()
	if not hover.get_global_rect().has_point(mouse):
		end()
		return

	if _is_paused():
		_hide_dots()
		return

	if mouse.distance_to(_anchor_mouse) > MOVE_THRESHOLD_PX:
		_reset_progress()
		return

	_elapsed += delta
	var dot_count: int = mini(int(floor(_elapsed / STEP_SEC)), 4)
	if dot_count > 0:
		_show_dots(dot_count)
	if _elapsed >= OPEN_SEC:
		_open_detail()

	_update_tooltip_position()


func _process_while_overlay_open() -> void:
	if _hold_overlay == null or not is_instance_valid(_hold_overlay):
		_hold_overlay = null
		_clear_session()
		return
	var mouse := _mouse_pos()
	if mouse.distance_to(_anchor_mouse) > MOVE_THRESHOLD_PX:
		_close_hold_overlay()
		_clear_session()


func _reset_progress() -> void:
	_elapsed = 0.0
	_anchor_mouse = _mouse_pos()
	_hide_dots()
	_close_hold_overlay()


func _show_dots(count: int) -> void:
	var parts: PackedStringArray = PackedStringArray()
	for _i in range(count):
		parts.append(DOT_CHAR)
	_tooltip_lbl.text = " ".join(parts)
	_tooltip_lbl.visible = true
	_update_tooltip_position()


func _hide_dots() -> void:
	_tooltip_lbl.visible = false
	_tooltip_lbl.text = ""


func _open_detail() -> void:
	if _host == null or _card_name.is_empty():
		return
	if _hold_overlay != null and is_instance_valid(_hold_overlay):
		return
	_hide_dots()
	_opening_detail = true
	var overlay: CardDetailOverlay = CardDetailOverlay.open_and_return(
		_host, _card_name, _card_type, null, false, _pin_overlay_to_host)
	_opening_detail = false
	if overlay == null:
		return
	_hold_overlay = overlay
	_active = false
	_anchor_mouse = _mouse_pos()
	set_process(true)
	overlay.tree_exiting.connect(_on_hold_overlay_exiting, CONNECT_ONE_SHOT)


func _on_hold_overlay_exiting() -> void:
	_hold_overlay = null
	_clear_session()


func _close_hold_overlay() -> void:
	if _hold_overlay != null and is_instance_valid(_hold_overlay):
		_hold_overlay.queue_free()
	_hold_overlay = null


func _update_overlay_pause() -> void:
	var blocked := _has_blocking_overlay()
	if blocked == _overlay_pause_active:
		return
	_overlay_pause_active = blocked
	set_pause(&"overlay", blocked)


func _has_blocking_overlay() -> bool:
	if _host == null:
		return false
	if _hold_overlay != null and is_instance_valid(_hold_overlay):
		return false
	if GameDialog.has_any_open_overlay():
		return true
	if GameDialog.has_any_open_overlay(&"GameDialogContentOverlay"):
		return true
	return CardDetailOverlay.find_first_in_tree(_host) != null


func _mouse_pos() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2.ZERO
	return vp.get_mouse_position()


func _update_tooltip_position() -> void:
	if not _tooltip_lbl.visible:
		return
	var mp := _mouse_pos()
	_tooltip_lbl.position = mp + CURSOR_OFFSET
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	_tooltip_lbl.position.x = clampf(
		_tooltip_lbl.position.x, 0.0, vp_size.x - _tooltip_lbl.size.x - 4.0)
	_tooltip_lbl.position.y = clampf(
		_tooltip_lbl.position.y, 0.0, vp_size.y - _tooltip_lbl.size.y - 4.0)
