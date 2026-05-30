extends Control
# Minimal dev entry scene — opens the admin console immediately.

const AdminConsoleScene: PackedScene = preload("res://scenes/admin_console.tscn")

@onready var _hint: Label = $HintLabel


func _ready() -> void:
	_open_console()


func _open_console() -> void:
	if get_node_or_null("AdminConsoleOverlay") != null:
		return
	if _hint:
		_hint.visible = false
	var overlay: Control = AdminConsoleScene.instantiate()
	overlay.name = "AdminConsoleOverlay"
	if overlay.has_signal("closed"):
		overlay.closed.connect(_on_console_closed)
	add_child(overlay)


func _close_console() -> void:
	var overlay: Node = get_node_or_null("AdminConsoleOverlay")
	if overlay == null:
		return
	if overlay.has_method("_on_close"):
		overlay._on_close()
	else:
		overlay.queue_free()
		_on_console_closed()


func _on_console_closed() -> void:
	if _hint:
		_hint.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	if key.keycode == KEY_A and key.ctrl_pressed and key.shift_pressed:
		if get_node_or_null("AdminConsoleOverlay") != null:
			_close_console()
		else:
			_open_console()
		get_viewport().set_input_as_handled()
