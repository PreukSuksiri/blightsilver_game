extends TextureRect
class_name SplashCoinFlip

## GPU-driven coin flip — TIME uniform keeps animation smooth during heavy loading.

const COIN_SZ := 36.0
const FLIP_SPEED := 2.2
const COIN_SHADER := preload("res://assets/shaders/splash_coin_flip.gdshader")

var _coin_mat: ShaderMaterial
var _running := false


func _ready() -> void:
	var coin_front: Texture2D = _load_loading_coin_tex("ui_coin_front_small.png")
	var coin_back: Texture2D = _load_loading_coin_tex("ui_coin_back_small.png")
	_coin_mat = ShaderMaterial.new()
	_coin_mat.shader = COIN_SHADER
	_coin_mat.set_shader_parameter("coin_front", coin_front)
	_coin_mat.set_shader_parameter("coin_back", coin_back)
	_coin_mat.set_shader_parameter("flip_speed", FLIP_SPEED)
	_coin_mat.set_shader_parameter("running", 1.0)
	material = _coin_mat
	texture = coin_front
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	custom_minimum_size = Vector2(COIN_SZ, COIN_SZ)
	size = Vector2(COIN_SZ, COIN_SZ)
	pivot_offset = Vector2(COIN_SZ * 0.5, COIN_SZ * 0.5)
	scale = Vector2.ONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_running = true
	call_deferred("_sync_shader_pivot")
	StartupLoadDebug.log("SplashCoinFlip: shader animation started")


func _sync_shader_pivot() -> void:
	if _coin_mat == null:
		return
	var half_sz: Vector2 = size * 0.5
	if half_sz.x <= 0.0:
		half_sz = Vector2(COIN_SZ, COIN_SZ) * 0.5
	_coin_mat.set_shader_parameter("quad_half_size", half_sz)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_shader_pivot()


func stop() -> void:
	_running = false
	if _coin_mat != null:
		_coin_mat.set_shader_parameter("running", 0.0)


## Loading spinner uses dedicated small coin art in decorations/ (not HudSkin remap).
func _load_loading_coin_tex(filename: String) -> Texture2D:
	var path := "res://assets/textures/ui/decorations/%s" % filename
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			return tex
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	push_warning("SplashCoinFlip: missing %s" % path)
	return null
