extends CanvasLayer
## Full-screen coin loading while returning to the main menu from battle, VN, exploration, etc.

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const FADE_IN_DUR := 1.0
const MIN_VISIBLE_SEC := 0.35
const LOADER_LAYER := 500

var _root: Control = null
var _coin: SplashCoinFlip = null
var _visible_since_msec: int = -1


func _ready() -> void:
	layer = LOADER_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_active() -> bool:
	return _root != null and is_instance_valid(_root) and _root.visible


static func is_main_menu_path(path: String) -> bool:
	return path.strip_edges() == MAIN_MENU_PATH


func show_loading() -> void:
	if _root != null and is_instance_valid(_root):
		_root.visible = true
		_root.modulate = Color.WHITE
		_visible_since_msec = Time.get_ticks_msec()
		return
	_build_ui()
	_visible_since_msec = Time.get_ticks_msec()
	StartupLoadDebug.log("MainMenuReturnLoader: coin loading shown")


func go_to_scene(path: String) -> void:
	if is_main_menu_path(path):
		return_to_main_menu()
	else:
		get_tree().change_scene_to_file(path)


func return_to_main_menu() -> void:
	GameState.returning_to_main_menu = true
	show_loading()
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func fade_out_to_main_menu() -> void:
	GameState.returning_to_main_menu = true
	CheckerTransition.fade_out_to_battle(func() -> void:
		show_loading()
		get_tree().change_scene_to_file(MAIN_MENU_PATH))


func finish_and_hide(fade_sec: float = FADE_IN_DUR) -> void:
	if _visible_since_msec >= 0:
		var elapsed: float = float(Time.get_ticks_msec() - _visible_since_msec) / 1000.0
		if elapsed < MIN_VISIBLE_SEC:
			await get_tree().create_timer(MIN_VISIBLE_SEC - elapsed).timeout
	await hide_loading(fade_sec)


func hide_loading(fade_sec: float = FADE_IN_DUR) -> void:
	if _coin != null and is_instance_valid(_coin):
		_coin.stop()
	if _root == null or not is_instance_valid(_root):
		_teardown()
		return
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, fade_sec) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	_teardown()
	StartupLoadDebug.log("MainMenuReturnLoader: coin loading hidden")


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "ReturnLoaderRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var veil := ColorRect.new()
	veil.color = Color(0.0, 0.0, 0.0, 1.0)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(veil)

	var indicator := HBoxContainer.new()
	indicator.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	indicator.anchor_left = 1.0
	indicator.anchor_top = 1.0
	indicator.anchor_right = 1.0
	indicator.anchor_bottom = 1.0
	indicator.offset_left = -280.0
	indicator.offset_top = -72.0
	indicator.offset_right = -28.0
	indicator.offset_bottom = -28.0
	indicator.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	indicator.grow_vertical = Control.GROW_DIRECTION_BEGIN
	indicator.add_theme_constant_override("separation", 12)
	indicator.alignment = BoxContainer.ALIGNMENT_CENTER
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(indicator)

	_coin = SplashCoinFlip.new()
	indicator.add_child(_coin)

	var lbl := Label.new()
	lbl.text = "Now Loading"
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 600))
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	lbl.add_theme_constant_override("shadow_offset_x", 3)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	indicator.add_child(lbl)


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.queue_free()
	_root = null
	_coin = null
	_visible_since_msec = -1
