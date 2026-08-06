extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var overlay = load("res://scripts/OmenEditorOverlay.gd").new()
	root.add_child(overlay)
	# Force a viewport size
	root.get_viewport().size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	var bot: Control = null
	var header: Control = null
	for c in overlay.get_children():
		if c is PanelContainer:
			var pc := c as PanelContainer
			# header near top, bot near bottom
			if pc.anchor_top < 0.5 and pc.offset_bottom > 0:
				header = pc
			if pc.anchor_top >= 0.5:
				bot = pc
	print("header size=", header.size if header else null, " offsets t/b=", header.offset_top if header else null, "/", header.offset_bottom if header else null)
	print("bot size=", bot.size if bot else null, " offsets t/b=", bot.offset_top if bot else null, "/", bot.offset_bottom if bot else null)
	# Find New and Rename and check global rect
	var stack: Array = [overlay]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button:
			var b := n as Button
			if b.text in ["New", "Rename"]:
				print(b.text, " size=", b.size, " global=", b.get_global_rect(), " filter=", b.mouse_filter)
		for ch in n.get_children():
			stack.append(ch)
	# Simulate New while on fortunes
	overlay.set("_selected_group", "fortunes")
	overlay.call("_on_new")
	print("new id=", overlay.get("_selected_id"), " groups=", overlay.call("_find_omen_by_id", overlay.get("_selected_id")).get("groups"))
	quit(0)
