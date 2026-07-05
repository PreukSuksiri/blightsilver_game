extends Control

const MAIN_MENU := "res://scenes/main_menu.tscn"
const DriftingCardsScript = preload("res://scripts/DriftingCards.gd")
const FADE_OUT_DUR := 1.0

@onready var logo: Control = $LogoRoot
@onready var overlay: ColorRect = $FadeOverlay
@onready var loading_indicator: Control = $LoadingIndicator
@onready var coin_flip: TextureRect = $LoadingIndicator/CoinFlip
@onready var now_loading_label: Label = $LoadingIndicator/NowLoadingLabel

var _done := false
var _loading_complete := false
var _packed_menu: PackedScene = null
var _load_errors: Array[String] = []


func _ready() -> void:
	StartupLoadDebug.log("SplashScreen._ready: scene entered")
	logo.visible = false
	overlay.color = Color(0, 0, 0, 0)
	loading_indicator.z_index = 10
	_style_loading_label()
	StartupLoadDebug.log("SplashScreen: loading UI visible (coin + Now Loading)")
	_run_loading_sequence()


func _style_loading_label() -> void:
	now_loading_label.text = "Now Loading"
	now_loading_label.add_theme_font_override("font", FontManager.make_font("display_serif", 600))
	now_loading_label.add_theme_font_size_override("font_size", 22)
	now_loading_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	now_loading_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	now_loading_label.add_theme_constant_override("shadow_offset_x", 3)
	now_loading_label.add_theme_constant_override("shadow_offset_y", 3)


func _run_loading_sequence() -> void:
	var screen_size: Vector2 = get_viewport_rect().size
	_load_errors.clear()

	await get_tree().process_frame
	StartupLoadDebug.log("SplashScreen: first frame rendered — starting parallel loads")

	if ResourceLoader.load_threaded_request(MAIN_MENU) != OK:
		_load_errors.append("Could not start loading the main menu.")
		StartupLoadDebug.log("SplashScreen: threaded main_menu request FAILED")
	else:
		StartupLoadDebug.log("SplashScreen: threaded main_menu request started")

	var load_state: Dictionary = {
		"bootstrap_done": false,
		"menu_done": false,
		"prewarm_done": false,
		"prewarm_ok": false,
		"packed_menu": null,
	}
	_bootstrap_parallel(load_state)
	_load_menu_parallel(load_state)
	_prewarm_parallel(load_state, screen_size)

	var wait_frames := 0
	while not bool(load_state["bootstrap_done"]) \
			or not bool(load_state["menu_done"]) \
			or not bool(load_state["prewarm_done"]):
		wait_frames += 1
		if wait_frames % 60 == 0:
			StartupLoadDebug.log(
				"SplashScreen: waiting — bootstrap=%s menu=%s prewarm=%s (frame %d)"
				% [load_state["bootstrap_done"], load_state["menu_done"], load_state["prewarm_done"], wait_frames]
			)
		await get_tree().process_frame

	StartupLoadDebug.log("SplashScreen: all parallel gates passed")

	_packed_menu = load_state.get("packed_menu") as PackedScene
	if _packed_menu == null and _load_errors.is_empty():
		_load_errors.append("Main menu scene could not be read.")

	if not bool(load_state["prewarm_ok"]):
		_load_errors.append("Background card art could not be prepared.")

	if not _load_errors.is_empty():
		StartupLoadDebug.log("SplashScreen: load errors (%d) — showing dialog" % _load_errors.size())
		await _handle_load_errors()

	_loading_complete = true
	StartupLoadDebug.log("SplashScreen: transitioning to main menu")
	await _go_to_menu()


func _bootstrap_parallel(state: Dictionary) -> void:
	StartupLoadDebug.log("SplashScreen.bootstrap: begin")
	var steps := 0
	while not SaveManager.is_bootstrapped():
		SaveManager.bootstrap_step()
		steps += 1
		await get_tree().process_frame
	state["bootstrap_done"] = true
	StartupLoadDebug.log("SplashScreen.bootstrap: complete (%d steps)" % steps)


func _load_menu_parallel(state: Dictionary) -> void:
	StartupLoadDebug.log("SplashScreen.menu_load: polling threaded status…")
	var polls := 0
	while _load_errors.is_empty():
		var status: int = ResourceLoader.load_threaded_get_status(MAIN_MENU)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			state["packed_menu"] = ResourceLoader.load_threaded_get(MAIN_MENU) as PackedScene
			state["menu_done"] = true
			StartupLoadDebug.log("SplashScreen.menu_load: complete (%d polls)" % polls)
			return
		if status == ResourceLoader.THREAD_LOAD_FAILED:
			_load_errors.append("Main menu failed to load.")
			state["menu_done"] = true
			StartupLoadDebug.log("SplashScreen.menu_load: FAILED")
			return
		polls += 1
		if polls % 120 == 0:
			StartupLoadDebug.log("SplashScreen.menu_load: still loading (poll %d, status=%d)" % [polls, status])
		await get_tree().process_frame
	state["menu_done"] = true


func _prewarm_parallel(state: Dictionary, screen_size: Vector2) -> void:
	StartupLoadDebug.log("SplashScreen.prewarm: creating hidden prewarm host")
	var helper = DriftingCardsScript.new()
	helper._prewarm_only = true
	helper.visible = false
	helper.z_index = -100
	add_child(helper)
	state["prewarm_ok"] = await helper.run_prewarm_async(screen_size)
	helper.queue_free()
	state["prewarm_done"] = true
	StartupLoadDebug.log("SplashScreen.prewarm: host freed (ok=%s)" % str(state["prewarm_ok"]))


func _handle_load_errors() -> void:
	for msg: String in _load_errors:
		push_warning("SplashScreen: %s" % msg)

	if not SaveManager.is_bootstrapped():
		while not SaveManager.bootstrap_step():
			await get_tree().process_frame

	DriftingCardsScript.clear_prewarm()

	if _packed_menu == null:
		_packed_menu = load(MAIN_MENU) as PackedScene

	if not GameDialog.has_open_overlay(self):
		var body: String = _load_errors[0] \
			+ "\n\nThe game will continue loading."
		var dlg: Control = GameDialog.accept_overlay(
			self,
			"Loading issue",
			body,
			"Continue"
		)
		if dlg != null:
			await dlg.tree_exited


func _go_to_menu() -> void:
	if _done:
		return
	_done = true
	if coin_flip != null and coin_flip.has_method("stop"):
		coin_flip.stop()
	overlay.z_index = 20
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	StartupLoadDebug.log("SplashScreen: fade out (%.1fs)" % FADE_OUT_DUR)
	var fade_out := create_tween()
	fade_out.tween_property(overlay, "color:a", 1.0, FADE_OUT_DUR) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_out.finished
	GameState.entered_main_menu_from_splash = true
	if _packed_menu != null:
		StartupLoadDebug.log("SplashScreen: change_scene_to_packed(main_menu)")
		get_tree().change_scene_to_packed(_packed_menu)
	else:
		StartupLoadDebug.log("SplashScreen: change_scene_to_file(main_menu) fallback")
		get_tree().change_scene_to_file(MAIN_MENU)


func _input(event: InputEvent) -> void:
	if not _loading_complete or _done:
		return
	if not _is_skip_event(event):
		return
	if OS.has_feature("web"):
		AudioManager.request_web_audio_unlock()


func _is_skip_event(event: InputEvent) -> bool:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		return true
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		return true
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		return true
	return false
