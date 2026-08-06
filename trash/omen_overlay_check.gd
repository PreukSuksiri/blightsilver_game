extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	await process_frame
	var s = load("res://scripts/OmenSelectOverlay.gd")
	print("loaded=", s != null)
	var overlay = s.new()
	overlay._omens = [
		{"id":"a","label":"A","description":"d","rarity":"common","illustration":"","positive":true},
		{"id":"b","label":"B","description":"d","rarity":"uncommon","illustration":"","positive":true},
	]
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# fake info hud
	var info := TextureRect.new()
	info.name = "FakeInfo"
	info.position = Vector2(900, 700)
	info.size = Vector2(140, 140)
	host.set("_info_icon", info) # won't work on plain Control
	root.add_child(host)
	host.add_child(info)
	host.add_child(overlay)
	await process_frame
	print("wrappers=", overlay._card_wrappers.size())
	print("has_fly=", overlay.has_method("_fly_selected_to_info"))
	print("has_shatter=", overlay.has_method("_shatter_unselected"))
	print("OK")
	quit(0)
