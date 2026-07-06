extends Node
## Desktop window display — borderless fullscreen toggle.


func desktop_window_supported() -> bool:
	return not OS.has_feature("web")


func apply_saved_setting() -> void:
	apply_borderless(SaveManager.is_borderless_display())


func apply_borderless(enabled: bool) -> void:
	if not desktop_window_supported():
		return
	if enabled:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
