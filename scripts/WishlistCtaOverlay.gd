extends Control
class_name WishlistCtaOverlay

## One-time Steam wishlist CTA — fade in, brief hold, fade out.
## Click "Wishlist Now" or the Steam logo to open the store page.

signal dismissed

const STEAM_STORE_URL := "https://store.steampowered.com/app/4786130/Blightsilver/"
const WISHLIST_TEX_PATH := "res://assets/textures/ui/backgrounds/wishlist_now.png"
const TEX_SIZE := Vector2(1216.0, 832.0)
const HOLD_SECONDS := 4.5
const FADE_SECONDS := 0.7

# Normalized click regions on wishlist_now.png (x, y, w, h).
const REGION_WISHLIST_TEXT := Rect2(0.02, 0.03, 0.37, 0.10)
const REGION_STEAM_LOGO := Rect2(0.02, 0.13, 0.33, 0.10)

var _dismissed: bool = false
var _sequence_tw: Tween = null
var _fade_out_tw: Tween = null


static func present(parent: Node) -> void:
	var overlay := WishlistCtaOverlay.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 30
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)
	await overlay.dismissed


func _ready() -> void:
	_build_ui()
	modulate.a = 0.0
	_sequence_tw = create_tween()
	_sequence_tw.tween_property(self, "modulate:a", 1.0, FADE_SECONDS) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_sequence_tw.tween_interval(HOLD_SECONDS)
	_sequence_tw.tween_callback(_auto_dismiss)


func _input(event: InputEvent) -> void:
	if _dismissed:
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo:
			_dismiss()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var vp: Vector2 = get_viewport_rect().size
	var max_w: float = vp.x * 0.78
	var max_h: float = vp.y * 0.72
	var scale: float = minf(max_w / TEX_SIZE.x, max_h / TEX_SIZE.y)
	var disp_size: Vector2 = TEX_SIZE * scale

	var wrap := Control.new()
	wrap.custom_minimum_size = disp_size
	wrap.size = disp_size
	wrap.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	wrap.offset_left = -disp_size.x * 0.5
	wrap.offset_right = disp_size.x * 0.5
	wrap.offset_top = -disp_size.y * 0.5
	wrap.offset_bottom = disp_size.y * 0.5
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrap)

	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture = load(WISHLIST_TEX_PATH) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(art)

	_add_click_region(wrap, disp_size, REGION_WISHLIST_TEXT)
	_add_click_region(wrap, disp_size, REGION_STEAM_LOGO)


func _add_click_region(parent: Control, img_size: Vector2, region: Rect2) -> void:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.position = Vector2(region.position.x * img_size.x, region.position.y * img_size.y)
	btn.size = Vector2(region.size.x * img_size.x, region.size.y * img_size.y)
	btn.pressed.connect(_open_steam)
	parent.add_child(btn)


func _open_steam() -> void:
	OS.shell_open(STEAM_STORE_URL)


func _auto_dismiss() -> void:
	_dismiss()


func _dismiss() -> void:
	if _dismissed:
		return
	_dismissed = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _sequence_tw != null and _sequence_tw.is_valid():
		_sequence_tw.kill()
	if _fade_out_tw != null and _fade_out_tw.is_valid():
		_fade_out_tw.kill()
	_fade_out_tw = create_tween()
	_fade_out_tw.tween_property(self, "modulate:a", 0.0, FADE_SECONDS) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_fade_out_tw.tween_callback(func() -> void:
		dismissed.emit()
		queue_free())
