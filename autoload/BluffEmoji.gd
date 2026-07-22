extends Node
## Custom bluff reaction art for Magitech v3 battle.
## GameState still stores unicode keys; this maps them to PNGs when HudSkin is v3.

const DIR := "res://assets/textures/ui/emoji/"

## Unicode key → filename (same set as BLUFF_EMOJIS_BOARD).
const _FILES := {
	"😃": "emoji_smile.png",
	"🥺": "emoji_puppyeye.png",
	"🤣": "emoji_laugh.png",
	"😎": "emoji_sunglass.png",
	"❤️": "emoji_heart.png",
	"☠️": "emoji_skull.png",
	"🧨": "emoji_bomb.png",
	"👍": "emoji_thumbup.png",
	"🤝": "emoji_handshake.png",
	"🖕": "emoji_middlefinger.png",
	# Steam NSFW unicode swap — same art as middle finger on v3.
	"💩": "emoji_middlefinger.png",
}

var _cache: Dictionary = {}  # emoji -> Texture2D


func uses_custom() -> bool:
	return HudSkin.version == "v3"


func has_tex(emoji: String) -> bool:
	return emoji != "" and _FILES.has(emoji) and tex(emoji) != null


func tex(emoji: String) -> Texture2D:
	if emoji.is_empty() or not _FILES.has(emoji):
		return null
	if _cache.has(emoji):
		return _cache[emoji] as Texture2D
	var path: String = DIR + str(_FILES[emoji])
	if not ResourceLoader.exists(path):
		push_warning("BluffEmoji: missing %s" % path)
		return null
	var t: Texture2D = load(path) as Texture2D
	_cache[emoji] = t
	return t


func apply_button(btn: Button, emoji: String, icon_size: float = 36.0) -> void:
	if btn == null:
		return
	var t: Texture2D = tex(emoji)
	if t == null:
		btn.text = emoji
		btn.icon = null
		return
	btn.text = ""
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
