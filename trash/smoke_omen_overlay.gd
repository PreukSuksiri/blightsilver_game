extends Node
## Temporary smoke check for OmenSelectOverlay geometry + intro animation.

func _ready() -> void:
	await get_tree().process_frame
	var bg := TextureRect.new()
	bg.texture = load("res://assets/textures/vn/backgrounds/vn_bg_mayu_home_day.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size = get_viewport().get_visible_rect().size
	get_tree().root.add_child(bg)

	var host := Control.new()
	host.name = "FakeExplorationHost"
	get_tree().root.add_child(host)

	var omens: Array = [
		{
			"id": "a", "label": "Iron Vigil", "rarity": "rare", "positive": true,
			"description": "Your units gain +1 max attack for the first turn.",
		},
		{
			"id": "b", "label": "Hollow Tithe", "rarity": "epic", "positive": false,
			"description": "Crystal losses increase by 25% this chapter.",
		},
		{
			"id": "c", "label": "Mannaz Rune", "rarity": "uncommon", "positive": true,
			"description": "Place 2 Mannaz runes on your grid at battle start.",
		},
	]

	var overlay: Control = load("res://scripts/OmenSelectOverlay.gd").new()
	overlay.name = "OmenSelectOverlay"
	overlay.set("_omens", omens)
	host.add_child(overlay)

	for _i: int in range(6):
		await get_tree().process_frame

	var vp: Vector2 = overlay.get_viewport_rect().size
	print("viewport=", vp)
	print("overlay pos=", overlay.position, " size=", overlay.size)
	var title: Label = overlay.get("_title") as Label
	var warn: Label = overlay.get("_warning") as Label
	print("title rect=", title.get_global_rect())
	print("warning rect=", warn.get_global_rect())
	var wrappers: Array = overlay.get("_card_wrappers") as Array
	var min_x: float = 1e9
	var max_x: float = -1e9
	for w: Control in wrappers:
		var r: Rect2 = w.get_global_rect()
		print("capsule ", w.get_meta("omen")["label"], " rect=", r, " center=", r.get_center())
		min_x = minf(min_x, r.position.x)
		max_x = maxf(max_x, r.end.x)
	print("row span=", min_x, "..", max_x, " row_center_x=", (min_x + max_x) * 0.5,
		" vp_center_x=", vp.x * 0.5)

	# Capture the condensation mid-flight.
	var stamps: Array[float] = [0.35, 0.30, 0.30, 0.35, 0.60]
	for i: int in range(stamps.size()):
		await get_tree().create_timer(stamps[i]).timeout
		await RenderingServer.frame_post_draw
		var frame: Image = get_viewport().get_texture().get_image()
		frame.save_png("user://omen_fog_%d.png" % i)
	print("frames saved to ", ProjectSettings.globalize_path("user://"))

	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	var shot: Image = get_viewport().get_texture().get_image()
	shot.save_png("user://omen_overlay_shot.png")
	print("shot saved to ", ProjectSettings.globalize_path("user://omen_overlay_shot.png"))
	print("input_unlocked=", overlay.get("_input_unlocked"))
	var pick: Control = wrappers[0] as Control
	print("pick centered scale=", pick.scale, " pivot=", pick.pivot_offset)
	overlay.call("_on_card_pressed", pick, omens[0])
	await get_tree().create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var mid: Image = get_viewport().get_texture().get_image()
	mid.save_png("user://omen_pick.png")
	await get_tree().create_timer(3.5).timeout
	print("overlay alive after pick=", is_instance_valid(overlay))
	print("SMOKE OK")
	get_tree().quit()
