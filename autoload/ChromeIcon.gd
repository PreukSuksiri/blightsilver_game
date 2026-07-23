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
	# Triangle source files are identical (point UP) — rotate per id below.
	"chevron_up": "triangle_up.png",
	"chevron_down": "triangle_down.png",
	"chevron_left": "triangle_left.png",
	"chevron_right": "triangle_right.png",
	"expand": "triangle_right.png",
	"collapse": "triangle_down.png",
}

## Clockwise 90° steps from the shared up-pointing triangle asset.
const _TRI_ROT_CW: Dictionary = {
	"chevron_up": 0,
	"expand": 1,
	"chevron_right": 1,
	"collapse": 2,
	"chevron_down": 2,
	"chevron_left": 3,
}

var _cache: Dictionary = {}  # id -> Texture2D (white+alpha)
var _bold_cache: Dictionary = {}  # "id@dilate" -> Texture2D

const _SILVER_GRADIENT: Shader = preload("res://assets/shaders/silver_gradient.gdshader")


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
	var rot_cw: int = int(_TRI_ROT_CW.get(id, 0))
	var white_tex: Texture2D = _to_white_alpha(src, rot_cw)
	_cache[id] = white_tex
	return white_tex


## Same as tex(), but dilates alpha so thin silhouettes read bolder at small sizes.
func tex_bold(id: String, dilate_px: int = 1) -> Texture2D:
	var key: String = "%s@%d" % [id, dilate_px]
	if _bold_cache.has(key):
		return _bold_cache[key] as Texture2D
	var base: Texture2D = tex(id)
	if base == null:
		return null
	if dilate_px <= 0:
		_bold_cache[key] = base
		return base
	var img: Image = base.get_image()
	if img == null:
		return base
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var bold_img: Image = _dilate_alpha(img, dilate_px)
	var out: Texture2D = ImageTexture.create_from_image(bold_img)
	_bold_cache[key] = out
	return out


func _dilate_alpha(src: Image, radius: int) -> Image:
	var w: int = src.get_width()
	var h: int = src.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var r: int = maxi(1, radius)
	for y: int in range(h):
		for x: int in range(w):
			var best_a: float = 0.0
			for dy: int in range(-r, r + 1):
				for dx: int in range(-r, r + 1):
					if dx * dx + dy * dy > r * r + 1:
						continue
					var sx: int = x + dx
					var sy: int = y + dy
					if sx < 0 or sy < 0 or sx >= w or sy >= h:
						continue
					best_a = maxf(best_a, src.get_pixel(sx, sy).a)
			if best_a > 0.004:
				out.set_pixel(x, y, Color(1.0, 1.0, 1.0, best_a))
	return out


## Icon-only button: bold silhouette with grey→white silver gradient (not a flat tint).
func apply_silver_icon_button(btn: Button, id: String, icon_px: int = 20, dilate_px: int = 1) -> void:
	if btn == null:
		return
	var t: Texture2D = tex_bold(id, dilate_px)
	if t == null:
		return
	btn.icon = null
	btn.text = ""
	btn.expand_icon = false
	var old: Node = btn.get_node_or_null("SilverIconHost")
	if old != null:
		old.queue_free()
	var host := CenterContainer.new()
	host.name = "SilverIconHost"
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr := TextureRect.new()
	tr.texture = t
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(icon_px, icon_px)
	tr.size = Vector2(icon_px, icon_px)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = _SILVER_GRADIENT
	tr.material = mat
	host.add_child(tr)
	btn.add_child(host)
	btn.move_child(host, 0)


## Flatten any silhouette (black or gray) to white RGB, keep alpha — required for multiply tint.
## Also crops to the opaque glyph and recenters it in a square so button icons sit on-center.
## `rotate_cw_90` = number of clockwise 90° turns (used for chevron / expand / collapse).
func _to_white_alpha(src: Texture2D, rotate_cw_90: int = 0) -> Texture2D:
	var img: Image = src.get_image()
	if img == null:
		return src
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var turns: int = posmod(rotate_cw_90, 4)
	for _i: int in range(turns):
		img.rotate_90(CLOCKWISE)
	var w: int = img.get_width()
	var h: int = img.get_height()
	var min_x: int = w
	var min_y: int = h
	var max_x: int = -1
	var max_y: int = -1
	for y: int in range(h):
		for x: int in range(w):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.004:
				continue
			# Keep coverage in alpha; force RGB white so icon_color/modulate recolors cleanly.
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, c.a))
			if x < min_x:
				min_x = x
			if y < min_y:
				min_y = y
			if x > max_x:
				max_x = x
			if y > max_y:
				max_y = y
	if max_x < min_x:
		return ImageTexture.create_from_image(img)
	var cw: int = max_x - min_x + 1
	var ch: int = max_y - min_y + 1
	# Small padding so AA edges aren't clipped at the square border.
	var pad: int = maxi(2, int(ceili(float(maxi(cw, ch)) * 0.04)))
	var side: int = maxi(cw, ch) + pad * 2
	var out := Image.create(side, side, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var dst_x: int = (side - cw) / 2
	var dst_y: int = (side - ch) / 2
	out.blit_rect(img, Rect2i(min_x, min_y, cw, ch), Vector2i(dst_x, dst_y))
	return ImageTexture.create_from_image(out)


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
	# Icon-only: center in the button. With label: icon left of text, vertically centered.
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if keep_text.strip_edges().is_empty():
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
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
