extends Node
## Phase B player-facing chrome icons (flat silhouettes).
## Source PNGs are normalized to white+alpha so Button icon_*_color / modulate can recolor them.
## Dark UI (original white glyphs) → white; light plates → dark charcoal.

const DIR := "res://assets/textures/ui/silhouettes/"

## Dark glyph on light / silver plate buttons.
const COLOR_ON_LIGHT := Color(0.10, 0.11, 0.14, 1.0)
## White glyph on dark navy buttons (matches original white unicode icons).
const COLOR_ON_DARK := Color(1.0, 1.0, 1.0, 1.0)
## Gold accent (featured star).
const COLOR_FEATURED := Color(1.0, 0.88, 0.22, 1.0)
## Soft red (remove / close on dark).
const COLOR_DANGER := Color(1.0, 0.55, 0.55, 1.0)

const _FILES := {
	"duplicate": "b1.png",
	"delete": "b2.png",
	"close": "b3.png",
	"featured": "b4.png",
	"remove": "b5.png",
	"add": "b6.png",
	"scrap": "b7.png",
	"locked": "b8.png",
	"setting": "b9.png",
	"back": "b21.png",
	"list": "b24.png",
	"grid": "b25.png",
	"formations": "27.png",
	"copy": "b28.png",
	"magnifier": "18.png",
	"chevron_up": "triangle_up.png",
	"chevron_down": "triangle_down.png",
	"chevron_left": "triangle_left.png",
	"chevron_right": "triangle_right.png",
	"expand": "triangle_right.png",
	"collapse": "triangle_down.png",
}

var _cache: Dictionary = {}  # id -> Texture2D (white+alpha)


func tex(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id] as Texture2D
	var file: String = str(_FILES.get(id, ""))
	if file.is_empty():
		push_warning("ChromeIcon: unknown id '%s'" % id)
		return null
	var path: String = DIR + file
	if not ResourceLoader.exists(path):
		push_warning("ChromeIcon: missing %s" % path)
		return null
	var src: Texture2D = load(path) as Texture2D
	if src == null:
		return null
	var white_tex: Texture2D = _to_white_alpha(src)
	_cache[id] = white_tex
	return white_tex


## Flatten any silhouette (black or gray) to white RGB, keep alpha — required for multiply tint.
func _to_white_alpha(src: Texture2D) -> Texture2D:
	var img: Image = src.get_image()
	if img == null:
		return src
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	for y: int in range(h):
		for x: int in range(w):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.004:
				continue
			# Keep coverage in alpha; force RGB white so icon_color/modulate recolors cleanly.
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, c.a))
	return ImageTexture.create_from_image(img)


## Apply a silhouette icon to a Button. `keep_text` is shown beside the icon.
## Pass a light/white `icon_color` (or leave default on dark plates) to match original white glyphs.
func apply_button(
		btn: Button,
		id: String,
		on_light_plate: bool = false,
		keep_text: String = "",
		icon_color: Color = Color(0, 0, 0, 0),
		icon_max_width: int = 22
) -> void:
	if btn == null:
		return
	var t: Texture2D = tex(id)
	if t == null:
		return
	btn.icon = t
	btn.expand_icon = true
	btn.text = keep_text
	btn.add_theme_constant_override("icon_max_width", icon_max_width)
	var col: Color = icon_color
	if col.a <= 0.0:
		col = COLOR_ON_LIGHT if on_light_plate else COLOR_ON_DARK
	elif _is_near_white(col):
		# Original white (or near-white) unicode → pure white silhouette.
		col = COLOR_ON_DARK
	btn.add_theme_color_override("icon_normal_color", col)
	btn.add_theme_color_override("icon_hover_color", col.lightened(0.08) if not _is_near_white(col) else Color(1, 1, 1, 1))
	btn.add_theme_color_override("icon_pressed_color", col.darkened(0.08) if not _is_near_white(col) else Color(0.88, 0.88, 0.88, 1))
	btn.add_theme_color_override("icon_disabled_color", Color(col.r, col.g, col.b, 0.35))


func _is_near_white(c: Color) -> bool:
	return c.r > 0.85 and c.g > 0.85 and c.b > 0.85


## TextureRect glyph (for badges / overlays that are not Buttons).
func make_rect(id: String, size: Vector2, color: Color = COLOR_ON_DARK) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex(id)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = size
	tr.size = size
	tr.modulate = COLOR_ON_DARK if _is_near_white(color) else color
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr
