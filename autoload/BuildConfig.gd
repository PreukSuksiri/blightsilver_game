extends Node
## Build-time feature flags for dev vs release exports.
##
## Release export preset: leave Custom features empty (no "admin").
## Dev / internal export preset: add custom feature "admin".
## Editor Play (F5): enabled via OS feature tag "editor".
## Dev export: add custom feature "admin". Release export: omit "admin".

func admin_tools_enabled() -> bool:
	if OS.has_feature("admin"):
		return true
	# Engine.is_editor_hint() is false during F5 play; use the editor feature tag instead.
	return OS.has_feature("editor")


func can_write_shipped_data() -> bool:
	# res://data/* is writable when Play is launched from the Godot editor (F5).
	# Exported builds cannot write res://; admin tools should not persist there anyway.
	return OS.has_feature("editor")


func admin_shortcut_pressed(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return false
	if key.keycode != KEY_A or not key.shift_pressed:
		return false
	# Accept Ctrl+Shift+A (and Meta+Shift+A on platforms that map it).
	return key.ctrl_pressed or key.meta_pressed


const _ADMIN_CONSOLE_SCENE: PackedScene = preload("res://scenes/admin_console.tscn")


func toggle_admin_console_on(host: Node) -> void:
	if not admin_tools_enabled() or host == null:
		return
	var existing: Node = host.get_node_or_null("AdminConsoleOverlay")
	if existing != null:
		existing.queue_free()
		return
	var overlay: Control = _ADMIN_CONSOLE_SCENE.instantiate()
	overlay.name = "AdminConsoleOverlay"
	overlay.z_index = 300
	host.add_child(overlay)
