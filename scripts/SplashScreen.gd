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
	# Fade logo in
	tween.tween_property(logo, "modulate:a", 1.0, FADE_IN_DUR) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Hold
	tween.tween_interval(HOLD_DUR)
	# Fade logo (and shadow) out first
	tween.tween_property(logo, "modulate:a", 0.0, FADE_OUT_DUR) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Then fade screen to black
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1.0), FADE_OUT_DUR) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_go_to_menu)


func _go_to_menu() -> void:
	if _done:
		return
	_done = true
	get_tree().change_scene_to_file(MAIN_MENU)


func _input(event: InputEvent) -> void:
	# Any click or key press skips the splash
	var skip := false
	if event is InputEventKey and event.pressed and not event.echo:
		skip = true
	if event is InputEventMouseButton and event.pressed:
		skip = true
	if skip and not _done:
		_done = true
		get_tree().change_scene_to_file(MAIN_MENU)
