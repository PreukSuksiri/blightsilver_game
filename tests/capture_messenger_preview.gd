extends Node
# Dev helper: opens MessengerOverlay and saves a screenshot, then quits.
# Run: godot --path . res://tests/capture_messenger_preview.tscn

func _ready() -> void:
	await get_tree().process_frame
	MessengerVault.reload()
	var conv: Dictionary = MessengerVault.get_conversation("sample_chat")
	var overlay: MessengerOverlay = MessengerOverlay.open_with_data(self, conv)
	for i: int in range(10):
		await get_tree().process_frame
	overlay._scroll.scroll_vertical = 0
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("user://messenger_preview_top.png")
	overlay._scroll.scroll_vertical = int(overlay._scroll.get_v_scroll_bar().max_value)
	await get_tree().process_frame
	var img2: Image = get_viewport().get_texture().get_image()
	img2.save_png("user://messenger_preview_bottom.png")
	print("Saved screenshots to: %s" % ProjectSettings.globalize_path("user://"))
	get_tree().quit()
