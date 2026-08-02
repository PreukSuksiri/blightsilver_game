extends Control
class_name OmenListPanel
## Shared helper for listing active omens in menus and info panels.

static func build_list(parent: Control, held_omens: Array) -> void:
	if parent == null:
		return
	for child: Node in parent.get_children():
		child.queue_free()
	if held_omens.is_empty():
		var empty := Label.new()
		empty.text = "No active omens."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88, 1.0))
		parent.add_child(empty)
		return
	for entry: Variant in held_omens:
		if not entry is Dictionary:
			continue
		var lbl := Label.new()
		lbl.text = OmenDatabase.format_omen_line(entry as Dictionary)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_color_override("font_color", Color(0.88, 0.93, 0.98, 1.0))
		parent.add_child(lbl)


static func show_dialog(host: Node, held_omens: Array) -> void:
	if host == null:
		return
	var lines: PackedStringArray = PackedStringArray()
	for entry: Variant in held_omens:
		if entry is Dictionary:
			lines.append(OmenDatabase.format_omen_line(entry as Dictionary))
	var body: String = "\n".join(lines) if lines.size() > 0 else "No active omens."
	if host.get_node_or_null("/root/GameDialog") != null:
		GameDialog.accept_overlay(host, "Active Omens", body, "Close")
		return
	_show_fallback_overlay(host, body)


static func _show_fallback_overlay(host: Node, body: String) -> void:
	var overlay := Control.new()
	overlay.name = "OmenListFallbackOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 400
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.85)
	overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -240.0
	panel.offset_right = 240.0
	panel.offset_top = -180.0
	panel.offset_bottom = 180.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.14, 0.98)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Active Omens"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var body_lbl := Label.new()
	body_lbl.text = body
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(body_lbl)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free())
	vbox.add_child(close_btn)
