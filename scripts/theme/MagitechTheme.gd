class_name MagitechTheme
extends RefCounted
## Locked Magitech UI tokens — single source of truth for colors / radii.
## Spec: res://context/MAGITECH_UI_THEME.md
## Theme resource: res://resources/themes/magitech_ui.tres
##
## Preload only — not an autoload. Does not change runtime UI until screens opt in.

# ── Palette ───────────────────────────────────────────────────
const VOID := Color("#060810")
const VOID_PANEL := Color(0.0235294, 0.0313726, 0.0627451, 0.97)  # #060810 @ 97%
const CHARCOAL := Color("#141820")
const SLATE_PLAYMAT := Color("#12141a")  # playmat floor only — never dialog fill
const CHROME := Color("#c0c8d8")
const CHROME_BRIGHT := Color("#e8eef5")
const CYAN := Color("#00e5ff")
const CYAN_SOFT := Color("#2ebfff")
const ICE_TEXT := Color("#e8f4ff")
const WARN_AMBER := Color("#f0c040")  # economy / cost warn / featured
const DESTRUCTIVE := Color("#c45a4a")
const DISABLED_FACE := Color(0.06, 0.08, 0.12, 0.9)
const DISABLED_TEXT := Color(0.55, 0.62, 0.72, 0.85)

# ── Chrome geometry ───────────────────────────────────────────
const CORNER_RADIUS := 8
const BORDER_WIDTH := 2
const BORDER_WIDTH_THIN := 1

# ── Type sizes (match GameDialog intent) ──────────────────────
const TITLE_FONT_SIZE := 22
const BODY_FONT_SIZE := 18
const BTN_FONT_SIZE := 17
const BTN_MIN_SIZE := Vector2(140, 40)

# ── Button faces ──────────────────────────────────────────────
const BTN_NORMAL := Color(0.04, 0.06, 0.10, 0.97)
const BTN_HOVER := Color(0.06, 0.10, 0.16, 1.0)
const BTN_PRESSED := Color(0.03, 0.05, 0.08, 1.0)


static func make_panel_stylebox(content_margin: float = 18.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = VOID_PANEL
	sb.border_color = CHROME
	sb.set_border_width_all(BORDER_WIDTH)
	sb.set_corner_radius_all(CORNER_RADIUS)
	sb.set_content_margin_all(content_margin)
	return sb


static func make_button_style(bg: Color, border: Color = CHROME) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(BORDER_WIDTH_THIN)
	sb.set_corner_radius_all(CORNER_RADIUS)
	sb.set_content_margin_all(8)
	return sb


static func make_line_edit_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(BORDER_WIDTH_THIN)
	sb.set_corner_radius_all(CORNER_RADIUS)
	sb.set_content_margin_all(8)
	return sb
