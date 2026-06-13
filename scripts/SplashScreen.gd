extends Control

const MAIN_MENU := "res://scenes/main_menu.tscn"

const FADE_IN_DUR  := 1.4
const HOLD_DUR     := 2.2
const FADE_OUT_DUR := 0.9

@onready var logo:    Control      = $LogoRoot
@onready var overlay: ColorRect   = $FadeOverlay

var _done := false


func _ready() -> void:
	logo.modulate.a = 0.0
	overlay.color   = Color(0, 0, 0, 0)

	var tween := create_tween()
	tween.tween_property(logo, "modulate:a", 1.0, FADE_IN_DUR) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLD_DUR)
	tween.tween_property(logo, "modulate:a", 0.0, FADE_OUT_DUR) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1.0), FADE_OUT_DUR) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_go_to_menu)


func _go_to_menu() -> void:
	if _done:
		return
	_done = true
	get_tree().change_scene_to_file(MAIN_MENU)


func _input(event: InputEvent) -> void:
	if _done:
		return
	if not _is_skip_event(event):
		return
	if OS.has_feature("web"):
		AudioManager.request_web_audio_unlock()
	_go_to_menu()


func _is_skip_event(event: InputEvent) -> bool:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		return true
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		return true
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		return true
	return false
