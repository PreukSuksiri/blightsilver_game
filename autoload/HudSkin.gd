extends Node

## Controls which set of battle HUD assets is displayed.
##
## Default skin at startup — change this one line for a persistent default:
##   "v1" = original assets (decorations/)
##   "v2" = Magitech assets (battle/v2_magitech/)
##
## To switch at runtime, open the admin console and type:
##   hud_skin v2    (switch to Magitech)
##   hud_skin v1    (revert to original)
var version := "v2"

signal skin_changed(new_version: String)

const _V1_BASE := "res://assets/textures/ui/decorations/"
const _V2_BASE := "res://assets/textures/ui/battle/v2_magitech/"

## v1 filename → v2 filename mapping.
## Add an entry here whenever a new v2 asset is approved.
const _V2_MAP: Dictionary = {
	"ui_end_turn.png":            "ui_magitech_end_turn.png",
	"ui_battle_options.png":      "ui_magitech_options.png",
	"ui_turn_number_panel.png":   "ui_magitech_turn_number.png",
	"ui_context_menu_attack.png": "ui_magitech_attack.png",
	"ui_context_menu_info.png":   "ui_magitech_info.png",
	"ui_context_menu_bluff.png":  "ui_magitech_bluff.png",
	"ui_icon_union.png":          "ui_magitech_union.png",
}

## Switch the active skin and notify all subscribers immediately.
func set_version(v: String) -> void:
	version = v
	skin_changed.emit(version)

## Returns the correct Texture2D for the given v1 filename.
## Falls back silently to v1 when no v2 mapping exists yet.
func hud_tex(v1_filename: String) -> Texture2D:
	if version == "v2" and _V2_MAP.has(v1_filename):
		return load(_V2_BASE + _V2_MAP[v1_filename]) as Texture2D
	return load(_V1_BASE + v1_filename) as Texture2D
