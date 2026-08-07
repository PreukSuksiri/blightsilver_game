extends Node
## Custom bluff reaction art.
## GameState still stores unicode keys; UI maps them to PNGs under assets/textures/ui/emoji/.

const DIR := "res://assets/textures/ui/emoji/"

## Unicode key → filename (same set as BLUFF_EMOJIS_BOARD).
const _FILES := {
	"😃": "emoji_smile.png",
	"🥺": "emoji_puppyeye.png",
	"🤣": "emoji_laugh.png",
	"😎": "emoji_sunglass.png",
	"❤️": "emoji_heart.png",
	"❤": "emoji_heart.png",
	"☠️": "emoji_skull.png",
	"☠": "emoji_skull.png",
	"🧨": "emoji_bomb.png",
	"👍": "emoji_thumbup.png",
	"🤝": "emoji_handshake.png",
	"🖕": "emoji_middlefinger.png",
	# Steam NSFW unicode swap — same art as middle finger.
	"💩": "emoji_middlefinger.png",
}

var _cache: Dictionary = {}  # emoji -> Texture2D


func uses_custom() -> bool:
	## Magitech v3 battle chrome historically gated emoji art; PNGs are always preferred in UI helpers.
	return HudSkin.version == "v3"


## Canonical lookup key (strip variation selectors, NSFW swap).
func canonical(emoji: String) -> String:
	var face := emoji.strip_edges()
	if face.is_empty():
		return ""
	# U+FE0F emoji presentation selector — heart/skull often stored with or without it.
	face = face.replace("\uFE0F", "")
	if face == "💩":
		return "🖕"
	return face


func has_tex(emoji: String) -> bool:
	return tex(emoji) != null


## Absolute res:// path for a bluff emoji PNG, or "" if unknown / missing.
func path_for(emoji: String) -> String:
	var key: String = _lookup_key(emoji)
	if key.is_empty():
		return ""
	var path: String = DIR + str(_FILES[key])
	if not ResourceLoader.exists(path):
		return ""
	return path


## BBCode [img] for bluff art. Never returns unicode — "" if no PNG.
func img_bbcode(emoji: String, icon_px: int = 18) -> String:
	var path: String = path_for(emoji)
	if path.is_empty():
		return ""
	return "[img=%dx%d]%s[/img]" % [icon_px, icon_px, path]


## Reverse-lookup unicode key from a res:// emoji PNG path (best-effort).
func emoji_for_path(path: String) -> String:
	var p := path.strip_edges()
	if p.is_empty():
		return ""
	for emoji: Variant in _FILES.keys():
		if DIR + str(_FILES[emoji]) == p:
			return str(emoji)
	return ""


func tex(emoji: String) -> Texture2D:
	var key: String = _lookup_key(emoji)
	if key.is_empty():
		return null
	if _cache.has(key):
		return _cache[key] as Texture2D
	var path: String = path_for(key)
	if path.is_empty():
		push_warning("BluffEmoji: missing %s" % (DIR + str(_FILES[key])))
		return null
	var t: Texture2D = load(path) as Texture2D
	_cache[key] = t
	return t


## Prefer PNG icon; never put unicode in button text.
func apply_button(btn: Button, emoji: String, icon_size: float = 36.0) -> void:
	if btn == null:
		return
	var t: Texture2D = tex(emoji)
	btn.text = ""
	if t == null:
		btn.icon = null
		return
	btn.icon = t
	btn.expand_icon = true
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	btn.add_theme_constant_override("icon_max_width", int(icon_size))
	btn.add_theme_constant_override("h_separation", 0)
	# Full-color art — keep white icon tint so PNG colors show through.
	btn.add_theme_color_override("icon_normal_color", Color.WHITE)
	btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	btn.add_theme_color_override("icon_pressed_color", Color(0.92, 0.92, 0.92, 1.0))


func _lookup_key(emoji: String) -> String:
	var face := emoji.strip_edges()
	if face.is_empty():
		return ""
	if _FILES.has(face):
		return face
	var canon: String = canonical(face)
	if _FILES.has(canon):
		return canon
	# Retry with FE0F for keys stored only as VS16 forms.
	var with_vs: String = canon + "\uFE0F"
	if _FILES.has(with_vs):
		return with_vs
	return ""
