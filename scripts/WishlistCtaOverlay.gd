extends Control
class_name WishlistCtaOverlay

## One-time Steam wishlist CTA — fade in, brief hold, fade out.
## Click "Wishlist Now" or the Steam logo to open the store page.

signal dismissed

const STEAM_STORE_URL := "https://store.steampowered.com/app/4786130/Blightsilver/"
const WISHLIST_TEX_PATH := "res://assets/textures/ui/backgrounds/wishlist_now.png"
const FADE_SECONDS := 0.7
const MIN_VISIBLE_SECONDS := 1.0  # after fade-in before tap/click dismiss is allowed
const AUTO_DISMISS_SECONDS := 4.5  # after dismiss unlocks, before auto fade-out

# Normalized click regions on wishlist_now.png (x, y, w, h).
const REGION_WISHLIST_TEXT := Rect2(0.02, 0.03, 0.37, 0.10)
const REGION_STEAM_LOGO := Rect2(0.02, 0.13, 0.33, 0.10)

var _dismissed: bool = false
var _dismiss_allowed: bool = false
var _sequence_tw: Tween = null
var _fade_out_tw: Tween = null


static func present(parent: Node) -> void:
	var overlay := WishlistCtaOverlay.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 120
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)
	await overlay.dismissed


func _ready() -> void:
	_build_ui()
	modulate.a = 0.0
	_sequence_tw = create_tween()
	_sequence_tw.tween_property(self, "modulate:a", 1.0, FADE_SECONDS) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_sequence_tw.tween_interval(MIN_VISIBLE_SECONDS)
	_sequence_tw.tween_callback(func() -> void: _dismiss_allowed = true)
	_sequence_tw.tween_interval(AUTO_DISMISS_SECONDS)
	_sequence_tw.tween_callback(_auto_dismiss)


func _gui_input(event: InputEvent) -> void:
	if _dismissed or not _dismiss_allowed:
		return
	if _is_continue_press(event):
		_dismiss()


func _input(event: InputEvent) -> void:
	if _dismissed or not _dismiss_allowed:
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo:
			_dismiss()


func _is_continue_press(event: InputEvent) -> bool:
	return (event is InputEventMouseButton \
			and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)


func _build_ui() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var tex: Texture2D = load(WISHLIST_TEX_PATH) as Texture2D
	var tex_size: Vector2 = Vector2(
		float(tex.get_width()) if tex != null else 1216.0,
		float(tex.get_height()) if tex != null else 832.0)
	var cover_rect: Rect2 = _cover_image_rect(vp, tex_size)

	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture = tex
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	var wrap := Control.new()
	wrap.position = cover_rect.position
	wrap.size = cover_rect.size
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrap)

	_add_click_region(wrap, cover_rect.size, REGION_WISHLIST_TEXT)
	_add_click_region(wrap, cover_rect.size, REGION_STEAM_LOGO)


## Visible image rect when scaling with aspect-cover to fill the viewport.
func _cover_image_rect(vp: Vector2, tex_size: Vector2) -> Rect2:
	if tex_size.x < 1.0 or tex_size.y < 1.0:
		return Rect2(Vector2.ZERO, vp)
	var scale: float = maxf(vp.x / tex_size.x, vp.y / tex_size.y)
	var disp_size: Vector2 = tex_size * scale
	var origin: Vector2 = (vp - disp_size) * 0.5
	return Rect2(origin, disp_size)


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
	_dismiss(true)


func _dismiss(force: bool = false) -> void:
	if _dismissed:
		return
	if not force and not _dismiss_allowed:
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
