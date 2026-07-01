extends Node
## Global top-center achievement unlock toaster. Toggle ENABLED to disable the system.

const ENABLED := true
const CANVAS_LAYER := 130

var _layer: CanvasLayer = null
var _toast_host: Control = null
var _queue: Array[String] = []
var _active_toast: AchievementToasterToast = null
var _runtime_enabled: bool = ENABLED


func _ready() -> void:
	if not ENABLED:
		return
	_runtime_enabled = true
	_layer = CanvasLayer.new()
	_layer.layer = CANVAS_LAYER
	add_child(_layer)
	_toast_host = Control.new()
	_toast_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_toast_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_toast_host)
	if not get_viewport().size_changed.is_connected(_sync_toast_host_size):
		get_viewport().size_changed.connect(_sync_toast_host_size)
	call_deferred("_sync_toast_host_size")
	if not AchievementManager.achievement_unlocked.is_connected(_on_achievement_unlocked):
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)


func _sync_toast_host_size() -> void:
	if _toast_host == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	_toast_host.set_size(vp_size)
	_toast_host.position = Vector2.ZERO


func is_enabled() -> bool:
	return ENABLED and _runtime_enabled


func set_enabled(enabled: bool) -> void:
	_runtime_enabled = enabled
	if not is_enabled():
		_queue.clear()
		_clear_active_toast()


func _on_achievement_unlocked(achievement_id: String) -> void:
	if not is_enabled() or achievement_id.is_empty():
		return
	_queue.append(achievement_id)
	_pump_queue()


func _pump_queue() -> void:
	if not is_enabled() or _active_toast != null or _queue.is_empty() or _toast_host == null:
		return
	var achievement_id: String = _queue.pop_front()
	var toast := AchievementToasterToast.show_toast(_toast_host, achievement_id)
	_active_toast = toast
	toast.finished.connect(_on_toast_finished, CONNECT_ONE_SHOT)


func _on_toast_finished() -> void:
	_active_toast = null
	_pump_queue()


func _clear_active_toast() -> void:
	if _active_toast != null and is_instance_valid(_active_toast):
		_active_toast.queue_free()
	_active_toast = null
