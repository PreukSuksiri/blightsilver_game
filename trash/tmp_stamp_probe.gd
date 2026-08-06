extends Node
func _ready() -> void:
	print("probe: start")
	var host := Control.new()
	host.size = Vector2(1600, 900)
	add_child(host)
	DetectiveNoteManager.reset_all()
	DetectiveNoteManager.unlock_topic("ch0_demo", "library_lights")
	DetectiveNoteManager.apply_stamp("ch0_demo", "library_lights", "stamp_mayu")
	var view: DetectiveNoteOverlay = DetectiveNoteOverlay.open_stamp_view(host, "ch0_demo", "library_lights")
	await get_tree().process_frame
	print("probe: opened, dismissable=", view._stamp_view_dismissable)
	var t0 := Time.get_ticks_msec()
	view._map.stamp_animation_finished.connect(func() -> void:
		print("probe: finished after ", Time.get_ticks_msec() - t0, "ms"))
	await get_tree().create_timer(4.0).timeout
	print("probe: after 4s, dismissable=", view._stamp_view_dismissable)
	DetectiveNoteManager.reset_all()
	get_tree().quit(0)
