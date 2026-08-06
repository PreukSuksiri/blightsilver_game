extends Node
# Temporary visual probe: captures screenshots of the detective note overlay
# (player mode + stamp) and the WYSIWYG layout editor, then quits.

func _ready() -> void:
	await get_tree().process_frame
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)

	DetectiveNoteManager.reset_all()
	DetectiveNoteManager.add_clue("ch0_demo", "person_kelly")
	DetectiveNoteManager.add_clue("ch0_demo", "person_mayu")
	DetectiveNoteManager.add_clue("ch0_demo", "object_library_photo")
	DetectiveNoteManager.add_clue("ch0_demo", "info_blackout_schedule")
	DetectiveNoteManager.unlock_topic("ch0_demo", "library_lights")
	DetectiveNoteManager.upgrade_topic("ch0_demo", "library_lights", 2)
	DetectiveNoteManager.set_placement("ch0_demo", "library_lights", "culprit", "person_kelly")
	DetectiveNoteManager.set_placement("ch0_demo", "library_lights", "motive", "info_blackout_schedule")

	var overlay: DetectiveNoteOverlay = DetectiveNoteOverlay.open_for_chapter(host, "ch0_demo")
	await _snap("/tmp/dnote_player.png")

	overlay._map.show_stamp("stamp_mayu")
	await _snap("/tmp/dnote_stamped.png")
	overlay._close()
	await get_tree().process_frame

	DetectiveNoteVaultManager.open(host)
	await get_tree().process_frame
	var mgr: DetectiveNoteVaultManager = \
		host.get_node("DetectiveNoteVaultManagerOverlay") as DetectiveNoteVaultManager
	await _snap("/tmp/dnote_admin.png")
	mgr._on_open_layout_editor()
	await _snap("/tmp/dnote_layout_editor.png")

	DetectiveNoteManager.reset_all()
	get_tree().quit(0)

func _snap(path: String) -> void:
	for _i in range(8):
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("saved ", path)
