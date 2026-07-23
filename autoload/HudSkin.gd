extends Node

## Controls which set of battle HUD assets is displayed.
##
## Default skin at startup — change this one line for a persistent default:
##   "v1" = original assets (decorations/)
##   "v2" = Magitech cyan/chrome (battle/v2_magitech/)
##   "v3" = Magitech v3 Holy Tech / Witchhunter (battle/v3_magitech/)
##
## Runtime (admin console):
##   hud_skin v3    (Magitech v3)
##   hud_skin v2    (Magitech v2 — easy revert)
##   hud_skin v1    (original)
##
## Resolution order for v3: v3 file → v2 file → v1 file (missing v3 pieces keep looking like v2).
var version := "v3"

signal skin_changed(new_version: String)

const _V1_BASE := "res://assets/textures/ui/decorations/"
const _V2_BASE := "res://assets/textures/ui/battle/v2_magitech/"
const _V3_BASE := "res://assets/textures/ui/battle/v3_magitech/"

## v1 filename → magitech filename (same name under v2_magitech/ and v3_magitech/).
## Add an entry whenever a new Magitech asset is approved.
const _SKIN_MAP: Dictionary = {
	"ui_playmat_default.png":     "ui_magitech_playmat.png",
	"ui_end_turn.png":            "ui_magitech_end_turn.png",
	"ui_battle_options.png":      "ui_magitech_options.png",
	"ui_turn_number_panel.png":   "ui_magitech_turn_number.png",
	"ui_context_menu_attack.png": "ui_magitech_attack.png",
	"ui_context_menu_info.png":   "ui_magitech_info.png",
	"ui_context_menu_bluff.png":  "ui_magitech_bluff.png",
	## Card context-menu only (small). Big `ui_magitech_attack/union` stay for other HUD.
	"ui_context_menu_attack_sm.png": "ui_magitech_context_attack.png",
	"ui_context_menu_union.png":     "ui_magitech_context_union.png",
	"ui_icon_union.png":          "ui_magitech_union.png",
	"ui_crystal_indicator.png":   "ui_magitech_crystal.png",
	"ui_icon_attack_count.png":   "ui_magitech_attack_count.png",
	"ui_tech_stack_chip.png":     "ui_magitech_tech.png",
	"ui_void_stack_chip.png":     "ui_magitech_void.png",
	"ui_icon_defend.png":         "ui_magitech_defend.png",
	"ui_icon_trap.png":           "ui_magitech_trap.png",
	"ui_icon_blank_found.png":    "ui_magitech_blank_found.png",
	"ui_icon_wait_2.png":         "ui_magitech_wait.png",
	"ui_icon_exposed.png":        "ui_magitech_exposed.png",
	"ui_coin_front.png":          "ui_magitech_coin_front.png",
	"ui_coin_back.png":           "ui_magitech_coin_back.png",
	"ui_view_eye_open.png":       "ui_magitech_eye_open.png",
	"ui_view_eye_closed.png":     "ui_magitech_eye_closed.png",
	"ui_panel_frame_9slice.png":  "ui_magitech_panel_9slice.png",
	"ui_options_menu_row.png":    "ui_magitech_options_row.png",
	"ui_context_menu_panel.png":  "ui_magitech_context_panel.png",
	"bg_game_over.png":           "ui_magitech_game_over.png",
	"ui_top_dashboard.png":       "ui_magitech_top_dashboard.png",
	"ui_bottom_vault.png":        "ui_magitech_bottom_vault.png",
	## Setup / coin-toss full-bleed backdrop (v3 only).
	"ui_bg_setup_phase.png":      "ui_bg_setup_phase.png",
	"ui_bg_setup_phase_front_frame.png": "ui_bg_setup_phase_front_frame.png",
	"ui_setup_bottom_strip.png":  "ui_setup_bottom_strip.png",
}

## On hud_skin v3, skip these and fall through to v2 → v1 (temporary).
## eye_closed: no v3 asset yet (board currently uses open eye for both toggles).
const _V3_DEFER_TO_V2: Dictionary = {
	"ui_view_eye_closed.png": true,
}


func set_version(v: String) -> void:
	if v not in ["v1", "v2", "v3"]:
		push_warning("HudSkin: unknown version '%s' (use v1|v2|v3)" % v)
		return
	if version == v:
		return
	version = v
	skin_changed.emit(version)


func uses_magitech_playmat_layout() -> bool:
	return version == "v2" or version == "v3"


## True when TECH/VOID should use chip PNGs instead of the v1 code-drawn piles.
func uses_stack_chip_art() -> bool:
	return version == "v2" or version == "v3"


## v3-only textures (no v1/v2 counterpart). Returns null on other skins.
func hud_tex_v3_only(v1_filename: String) -> Texture2D:
	if version != "v3":
		return null
	var mapped: String = str(_SKIN_MAP.get(v1_filename, ""))
	if mapped == "":
		return null
	var v3_path := _V3_BASE + mapped
	if ResourceLoader.exists(v3_path):
		var tex: Texture2D = load(v3_path) as Texture2D
		if tex != null:
			return tex
	# Broken/stale .import (valid=false) — load pixels directly so chrome still shows.
	if FileAccess.file_exists(v3_path):
		var img := Image.load_from_file(v3_path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


## Setup / coin-toss backdrop: crop letterbox/pillarbox baked into the plate,
## then callers STRETCH_SCALE it to the full viewport.
func setup_phase_bg_tex() -> Texture2D:
	return _setup_phase_plate_tex("ui_bg_setup_phase.png")


## Foreground frame plate (same crop/placement as backdrop; drawn above portraits/coin).
func setup_phase_front_frame_tex() -> Texture2D:
	return _setup_phase_plate_tex("ui_bg_setup_phase_front_frame.png")


func _setup_phase_plate_tex(v1_filename: String) -> Texture2D:
	var full: Texture2D = hud_tex_v3_only(v1_filename)
	if full == null:
		return null
	var tw: float = float(full.get_width())
	var th: float = float(full.get_height())
	if tw <= 1.0 or th <= 1.0:
		return full
	var atlas := AtlasTexture.new()
	atlas.atlas = full
	# Measured content bounds on 1672×941 plate (black canvas padding).
	atlas.region = Rect2(tw * 0.0807, th * 0.0457, tw * 0.8385, th * 0.9054)
	return atlas


## Returns the correct Texture2D for the given v1 filename.
## Resolution: active skin file → older Magitech → v1 decorations → any existing Magitech file.
func hud_tex(v1_filename: String) -> Texture2D:
	var mapped: String = str(_SKIN_MAP.get(v1_filename, ""))
	var skip_v3: bool = _V3_DEFER_TO_V2.has(v1_filename)
	if version == "v3" and mapped != "" and not skip_v3:
		var v3_path := _V3_BASE + mapped
		if ResourceLoader.exists(v3_path):
			return load(v3_path) as Texture2D
	if (version == "v2" or version == "v3") and mapped != "":
		var v2_path := _V2_BASE + mapped
		if ResourceLoader.exists(v2_path):
			return load(v2_path) as Texture2D
	var v1_path := _V1_BASE + v1_filename
	if ResourceLoader.exists(v1_path):
		return load(v1_path) as Texture2D
	# Icons that exist only as Magitech (e.g. eye) — never crash on missing v1.
	if mapped != "" and ResourceLoader.exists(_V2_BASE + mapped):
		return load(_V2_BASE + mapped) as Texture2D
	if mapped != "" and not skip_v3 and ResourceLoader.exists(_V3_BASE + mapped):
		return load(_V3_BASE + mapped) as Texture2D
	push_warning("HudSkin: missing texture for %s" % v1_filename)
	return null


## Card context-menu Attack — v3 small plaque; else full attack icon.
func context_menu_attack_tex() -> Texture2D:
	if version == "v3":
		var sm: Texture2D = _load_v3_file("ui_magitech_context_attack.png")
		if sm != null:
			return sm
	return hud_tex("ui_context_menu_attack.png")


## Card context-menu Union — v3 small plaque; else main union icon.
func context_menu_union_tex() -> Texture2D:
	if version == "v3":
		var sm: Texture2D = _load_v3_file("ui_magitech_context_union.png")
		if sm != null:
			return sm
	return hud_tex("ui_icon_union.png")


func _load_v3_file(filename: String) -> Texture2D:
	var path := _V3_BASE + filename
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null
