extends Control
# Quick test runner for VN scenes.
# Change TEST_PATH to point at any JSON file, then run scenes/vn_test.tscn with F6.

#const TEST_PATH := "res://campaign/scenes/ch1_s1_post_DEMO.json"
const TEST_PATH := "res://campaign/scenes/asdasd.json"
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var vn := preload("res://scenes/vn_player.tscn").instantiate()
	add_child(vn)
	vn.play_scene(TEST_PATH, _on_finished)

func _on_finished() -> void:
	var lbl := Label.new()
	lbl.text = "Scene finished.\nPress Escape to close."
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	add_child(lbl)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
