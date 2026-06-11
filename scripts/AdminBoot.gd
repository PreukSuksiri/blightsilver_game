extends Control
# Minimal dev entry scene — opens the admin console immediately.

@onready var _hint: Label = $HintLabel


func _ready() -> void:
	if BuildConfig.admin_tools_enabled():
		_open_console()


func _open_console() -> void:
	if not BuildConfig.admin_tools_enabled():
		return
	if get_node_or_null("AdminConsoleOverlay") != null:
		return
	if _hint:
		_hint.visible = false
	BuildConfig.toggle_admin_console_on(self)
	var overlay: Node = get_node_or_null("AdminConsoleOverlay")
	if overlay != null and overlay.has_signal("closed"):
		if not overlay.closed.is_connected(_on_console_closed):
			overlay.closed.connect(_on_console_closed)


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


func _input(event: InputEvent) -> void:
	if BuildConfig.admin_shortcut_pressed(event):
		if BuildConfig.admin_tools_enabled():
			if get_node_or_null("AdminConsoleOverlay") != null:
				_close_console()
			else:
				_open_console()
		get_viewport().set_input_as_handled()
