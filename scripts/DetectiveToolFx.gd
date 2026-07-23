extends Control
## Active-state FX for exploration detective tools (HUD, looping SFX, polaroid).
## Owned by ExplorationPlayer; does not manage tool activate/deactivate itself.

signal polaroid_overlay_dismissed
signal polaroid_shot_finished  ## Mode 2 photo shown — leave tool active mode (overlay may remain)
signal photo_vn_requested(path: String)

const CROSSHAIR_SIZE := 240.0
const CROSSHAIR_RADIUS := 108.0
const PRINT_SFX_DELAY := 0.5

const TOOL_POLAROID := "tool_polaroid_camera"
const TOOL_EMF := "tool_etf_meter"
const TOOL_THERMOMETER := "tool_thermometer"
const TOOL_TRANSLATOR := "tool_translator"

## Distance bands vs sense radius (max(reveal_radius, MIN_SENSE_RADIUS)):
##   close  ≤ 1.0×  — whole reveal/hot zone
##   medium ≤ 3.0×  — approach ring (much wider than before)
##   far    > 3.0×
const BAND_CLOSE := 1.0
const BAND_MEDIUM := 3.0
const MIN_SENSE_RADIUS := 140.0
const DEFAULT_ROOM_TEMP := 25.0
const THERMO_LERP_SPEED := 6.0
const EMF_MAX := 20.0
const MUMBLING_DIR := "res://assets/audio/sfx/mumbling"

const SFX_SHUTTER := preload("res://assets/audio/sfx/sfx_camera_shutter.mp3")
const SFX_PRINT := preload("res://assets/audio/sfx/sfx_camera_print.mp3")
const SFX_THERMO_BEEP := preload("res://assets/audio/sfx/sfx_thermometer_beep.mp3")
const SFX_EMF_SLOW := preload("res://assets/audio/sfx/sfx_emf_beeping_slow.mp3")
const SFX_EMF_MED := preload("res://assets/audio/sfx/sfx_emf_beeping_medium.mp3")
const SFX_EMF_CLOSE := preload("res://assets/audio/sfx/sfx_emf_beeping_fast.mp3")
const SFX_RADIO_LOW := preload("res://assets/audio/sfx/sfx_radio_static_low.mp3")
const SFX_RADIO_HIGH := preload("res://assets/audio/sfx/sfx_radio_static_high.mp3")
const FILM_GRAIN_SHADER := preload("res://assets/shaders/translator_film_grain.gdshader")
const THERMO_DIGIT_COLOR := Color(1.0, 1.0, 1.0, 1.0)  # numbers + C
const THERMO_PUNCT_COLOR := Color(0.62, 0.66, 0.70, 1.0)  # greyish . and °
const THERMO_GLITCH_COLOR := Color(1.0, 1.0, 1.0, 1.0)

const SMOKE_PATHS: PackedStringArray = [
	"res://assets/textures/ui/battle/v3_magitech/vfx/ui_magitech_vfx_smoke_a.png",
	"res://assets/textures/ui/battle/v3_magitech/vfx/ui_magitech_vfx_smoke_b.png",
	"res://assets/textures/ui/battle/v3_magitech/vfx/ui_magitech_vfx_smoke_c.png",
	"res://assets/textures/ui/battle/v3_magitech/vfx/ui_magitech_vfx_smoke_d.png",
	"res://assets/textures/ui/battle/v3_magitech/vfx/ui_magitech_vfx_smoke_e.png",
	"res://assets/textures/ui/battle/v3_magitech/vfx/ui_magitech_vfx_smoke_f.png",
	"res://assets/textures/ui/battle/v3_magitech/vfx/ui_magitech_vfx_smoke_g.png",
	"res://assets/textures/ui/battle/v3_magitech/vfx/ui_magitech_vfx_smoke_h.png",
]

var _tool_id: String = ""
var _spots: Array = []  # {center, radius, temperature?, mumbling_sound?}
var _room_temp: float = DEFAULT_ROOM_TEMP
var _photo_alt_bg: String = ""
var _photo_vn: String = ""
var _bg_tex: Texture2D = null
var _photo_smoke_spots: Array = []  # all tool-gated spots in the room (any tool)

var _ui_layer: CanvasLayer = null
var _ui_root: Control = null
var _hud_panel: PanelContainer = null
var _thermo_row: HBoxContainer = null
var _thermo_int_lbl: Label = null
var _thermo_dot_lbl: Label = null
var _thermo_frac_lbl: Label = null
var _thermo_deg_lbl: Label = null
var _thermo_c_lbl: Label = null
var _thermo_glitch_lbl: Label = null
var _emf_gauge: Control = null
var _emf_needle: Control = null
var _wave_draw: Control = null
var _crosshair: Control = null
var _flash: ColorRect = null
var _film_grain: ColorRect = null
var _film_grain_mat: ShaderMaterial = null
var _film_grain_cd: float = 0.0     # seconds until next grain burst
var _film_grain_left: float = 0.0   # remaining burst duration
var _film_grain_dur: float = 0.0    # total length of current burst
var _film_grain_peak: float = 0.1   # peak opacity this burst (5%–15%)
var _polaroid_layer: Control = null
var _polaroid_busy: bool = false
var _polaroid_can_dismiss: bool = false
var _awaiting_photo_vn: bool = false
var _music_ducked: bool = false

var _loop_a: AudioStreamPlayer = null
var _loop_b: AudioStreamPlayer = null  # mumbling bed
var _loop_key: String = ""
var _mumble_key: String = ""
var _mumble_pool: Array[String] = []

var _display_temp: float = DEFAULT_ROOM_TEMP
var _last_temp_band: int = 2  # 25 → band 2
var _thermo_flicker_cd: float = 0.0       # seconds until next glitch burst
var _thermo_flicker_left: float = 0.0     # remaining burst duration
var _thermo_flicker_glyph_cd: float = 0.0 # seconds until next glyph swap in burst
const THERMO_FLICKER_CHARS := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ#@$%?!*/\\~&^<>|"
var _emf_value: float = 0.0
var _emf_spike_cd: float = 0.0    # seconds until next high-zone spike roll
var _emf_spike_left: float = 0.0  # remaining slam-to-max duration
var _wave_amp: float = 0.0
var _rng := RandomNumberGenerator.new()
var _time: float = 0.0


func _ready() -> void:
	name = "DetectiveToolFx"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 88
	_rng.randomize()
	_build_ui_layer()
	_build_loop_players()
	_build_film_grain()
	_build_hud()
	_build_crosshair()
	_build_flash()
	_scan_mumble_pool()
	visible = true  # layer children toggle their own visibility
	set_process(false)


func is_active() -> bool:
	return not _tool_id.is_empty()


func is_polaroid() -> bool:
	return _tool_id == TOOL_POLAROID


func is_polaroid_overlay_open() -> bool:
	return _polaroid_layer != null and is_instance_valid(_polaroid_layer) and _polaroid_layer.visible


func blocks_tool_dismiss() -> bool:
	return _polaroid_busy or is_polaroid_overlay_open()


func start_tool(tool_id: String, spots: Array, opts: Dictionary = {}) -> void:
	stop_tool()
	_tool_id = tool_id
	_spots = spots.duplicate(true)
	_room_temp = float(opts.get("room_temperature", DEFAULT_ROOM_TEMP))
	_photo_alt_bg = str(opts.get("photo_alt_background", "")).strip_edges()
	_photo_vn = str(opts.get("photo_vn_scene", "")).strip_edges()
	_bg_tex = opts.get("background_texture", null) as Texture2D
	var smoke_var: Variant = opts.get("photo_smoke_spots", [])
	_photo_smoke_spots = (smoke_var as Array).duplicate(true) if smoke_var is Array else []
	_display_temp = _room_temp
	_last_temp_band = int(floor(_display_temp / 10.0))
	_thermo_flicker_cd = _rng.randf_range(5.0, 20.0)
	_thermo_flicker_left = 0.0
	_thermo_flicker_glyph_cd = 0.0
	_emf_value = 0.0
	_emf_spike_cd = _rng.randf_range(3.0, 5.0)
	_emf_spike_left = 0.0
	_wave_amp = 0.0
	set_process(true)
	_show_hud_for_tool()
	if is_polaroid() and _crosshair != null:
		_crosshair.visible = true
	if _tool_id == TOOL_TRANSLATOR:
		_duck_music()
		_film_grain_cd = _rng.randf_range(1.0, 3.0)
		_film_grain_left = 0.0
		_film_grain_dur = 0.0
		_set_film_grain_opacity(0.0)
	_update_proximity_audio(Vector2.ZERO, true)


func stop_tool() -> void:
	_restore_music_if_ducked()
	_tool_id = ""
	_spots.clear()
	_photo_smoke_spots.clear()
	_stop_loops()
	_hide_all_hud()
	_set_film_grain_opacity(0.0)
	_film_grain_cd = 0.0
	_film_grain_left = 0.0
	_film_grain_dur = 0.0
	if _crosshair != null:
		_crosshair.visible = false
	_dismiss_polaroid_overlay(false)
	_polaroid_busy = false
	_polaroid_can_dismiss = false
	_awaiting_photo_vn = false
	set_process(false)


## Clear active-tool FX but keep the Mode 2 polaroid overlay on screen.
func exit_active_keep_overlay() -> void:
	_restore_music_if_ducked()
	_tool_id = ""
	_spots.clear()
	_stop_loops()
	_hide_all_hud()
	_set_film_grain_opacity(0.0)
	_film_grain_cd = 0.0
	_film_grain_left = 0.0
	_film_grain_dur = 0.0
	if _crosshair != null:
		_crosshair.visible = false
	_polaroid_busy = false
	set_process(false)


func set_spots(spots: Array) -> void:
	_spots = spots.duplicate(true)


func notify_photo_vn_finished() -> void:
	_awaiting_photo_vn = false
	_polaroid_can_dismiss = true


## Returns true if the press was consumed (polaroid shutter / overlay dismiss).
func handle_press(global_pos: Vector2, over_tool_spot: bool) -> bool:
	if is_polaroid_overlay_open():
		if _polaroid_can_dismiss and not _awaiting_photo_vn:
			_dismiss_polaroid_overlay(true)
			return true
		return true  # swallow clicks while locked
	if not is_active():
		return false
	if not is_polaroid():
		return false
	if _polaroid_busy:
		return true
	if over_tool_spot:
		_play_shutter_flash()
		return false  # let spot gui_input fire Mode 1
	_run_polaroid_mode2(global_pos)
	return true


func _process(delta: float) -> void:
	if not is_active():
		return
	_time += delta
	var mouse: Vector2 = get_viewport().get_mouse_position()
	if is_polaroid():
		_crosshair.position = mouse - _crosshair.size * 0.5
	if is_polaroid_overlay_open() or _polaroid_busy:
		_stop_loops()
		return
	var nearest := _nearest_spot(mouse)
	var spot: Dictionary = nearest
	var dist_ratio: float = _dist_ratio_for_spot(spot)
	_update_proximity_audio(mouse, false, spot, dist_ratio)
	match _tool_id:
		TOOL_EMF:
			_update_emf(dist_ratio, delta)
		TOOL_THERMOMETER:
			_update_thermometer(spot, dist_ratio, delta)
		TOOL_TRANSLATOR:
			_update_translator(dist_ratio, delta)
		_:
			_set_film_grain_opacity(0.0)


# ── Build ─────────────────────────────────────────────────────

func _build_ui_layer() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "DetectiveToolUiLayer"
	_ui_layer.layer = 70  # above exploration HUD / fades; below VN (~100)
	add_child(_ui_layer)
	_ui_root = Control.new()
	_ui_root.name = "DetectiveToolUiRoot"
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_ui_root)
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_loop_players() -> void:
	_loop_a = AudioStreamPlayer.new()
	_loop_a.bus = "SFX"
	add_child(_loop_a)
	_loop_b = AudioStreamPlayer.new()
	_loop_b.bus = "SFX"
	add_child(_loop_b)


func _build_hud() -> void:
	_hud_panel = PanelContainer.new()
	_hud_panel.name = "ToolHud"
	_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	sb.set_border_width_all(0)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_hud_panel.add_theme_stylebox_override("panel", sb)
	_ui_root.add_child(_hud_panel)
	_hud_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_hud_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hud_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hud_panel.offset_left = -300.0
	_hud_panel.offset_top = -210.0
	_hud_panel.offset_right = -20.0
	_hud_panel.offset_bottom = -20.0

	var host := Control.new()
	host.custom_minimum_size = Vector2(260, 160)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_panel.add_child(host)

	# Digits = digital font; "." and "°C" = primary UI font (digital lacks those glyphs).
	_thermo_row = HBoxContainer.new()
	_thermo_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_thermo_row.add_theme_constant_override("separation", 0)
	_thermo_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_thermo_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thermo_row.visible = false
	host.add_child(_thermo_row)

	_thermo_int_lbl = _make_thermo_digit_label()
	_thermo_dot_lbl = _make_thermo_punct_label(".")
	_thermo_frac_lbl = _make_thermo_digit_label()
	_thermo_deg_lbl = _make_thermo_punct_label("°")
	_thermo_c_lbl = _make_thermo_digit_label()
	_thermo_c_lbl.text = "C"
	_thermo_row.add_child(_thermo_int_lbl)
	_thermo_row.add_child(_thermo_dot_lbl)
	_thermo_row.add_child(_thermo_frac_lbl)
	_thermo_row.add_child(_thermo_deg_lbl)
	_thermo_row.add_child(_thermo_c_lbl)

	_thermo_glitch_lbl = Label.new()
	_thermo_glitch_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thermo_glitch_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_thermo_glitch_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_thermo_glitch_lbl.add_theme_font_size_override("font_size", 48)
	_thermo_glitch_lbl.add_theme_color_override("font_color", THERMO_GLITCH_COLOR)
	FontManager.tag_font(_thermo_glitch_lbl, "font", "digital", 400)
	_thermo_glitch_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thermo_glitch_lbl.visible = false
	host.add_child(_thermo_glitch_lbl)

	_emf_gauge = Control.new()
	_emf_gauge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_emf_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_emf_gauge.visible = false
	_emf_gauge.draw.connect(_draw_emf_gauge)
	host.add_child(_emf_gauge)

	_wave_draw = Control.new()
	_wave_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wave_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_draw.visible = false
	_wave_draw.draw.connect(_draw_waveform)
	host.add_child(_wave_draw)


func _build_crosshair() -> void:
	_crosshair = Control.new()
	_crosshair.name = "PolaroidCrosshair"
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.visible = false
	_crosshair.z_index = 95
	var sz := Vector2(CROSSHAIR_SIZE, CROSSHAIR_SIZE)
	_crosshair.custom_minimum_size = sz
	_crosshair.size = sz
	_crosshair.pivot_offset = sz * 0.5
	_crosshair.draw.connect(func() -> void:
		var c := Color(0.28, 0.72, 0.40, 0.45)
		var r := CROSSHAIR_RADIUS
		var mid := _crosshair.size * 0.5
		_crosshair.draw_arc(mid, r, 0.0, TAU, 64, c, 2.5, true)
		_crosshair.draw_line(Vector2(mid.x - r - 10.0, mid.y), Vector2(mid.x + r + 10.0, mid.y), c, 2.0, true)
	)
	_ui_root.add_child(_crosshair)


func _build_flash() -> void:
	_flash = ColorRect.new()
	_flash.name = "PolaroidFlash"
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.z_index = 120
	_flash.visible = false
	_ui_root.add_child(_flash)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_film_grain() -> void:
	_film_grain = ColorRect.new()
	_film_grain.name = "TranslatorFilmGrain"
	_film_grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_film_grain.z_index = 5  # under tool HUD / crosshair; over exploration
	_film_grain.visible = false
	_film_grain.color = Color(1, 1, 1, 1)
	_film_grain_mat = ShaderMaterial.new()
	_film_grain_mat.shader = FILM_GRAIN_SHADER
	_film_grain_mat.set_shader_parameter("intensity", 0.0)
	_film_grain.material = _film_grain_mat
	_ui_root.add_child(_film_grain)
	_film_grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _set_film_grain_opacity(alpha: float) -> void:
	if _film_grain == null or not is_instance_valid(_film_grain):
		return
	var a: float = clampf(alpha, 0.0, 1.0)
	if _film_grain_mat != null:
		_film_grain_mat.set_shader_parameter("intensity", a)
	_film_grain.visible = a > 0.001


func _scan_mumble_pool() -> void:
	_mumble_pool.clear()
	var dir := DirAccess.open(MUMBLING_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var fn := dir.get_next()
	while not fn.is_empty():
		if not dir.current_is_dir() and fn.ends_with(".mp3"):
			_mumble_pool.append("%s/%s" % [MUMBLING_DIR, fn])
		fn = dir.get_next()
	dir.list_dir_end()


func _show_hud_for_tool() -> void:
	_hide_all_hud()
	match _tool_id:
		TOOL_EMF:
			_hud_panel.visible = true
			_emf_gauge.visible = true
			_emf_gauge.queue_redraw()
		TOOL_THERMOMETER:
			_hud_panel.visible = true
			_show_thermo_normal()
		TOOL_TRANSLATOR:
			_hud_panel.visible = true
			_wave_draw.visible = true
			_wave_draw.queue_redraw()
		_:
			pass


func _hide_all_hud() -> void:
	if _hud_panel != null:
		_hud_panel.visible = false
	if _thermo_row != null:
		_thermo_row.visible = false
	if _thermo_glitch_lbl != null:
		_thermo_glitch_lbl.visible = false
	if _emf_gauge != null:
		_emf_gauge.visible = false
	if _wave_draw != null:
		_wave_draw.visible = false


# ── Proximity / bands ─────────────────────────────────────────

func _nearest_spot(mouse: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = INF
	for entry_var: Variant in _spots:
		if not entry_var is Dictionary:
			continue
		var e: Dictionary = entry_var as Dictionary
		var center: Vector2 = e.get("center", Vector2.ZERO)
		var d: float = mouse.distance_to(center)
		if d < best_d:
			best_d = d
			best = e.duplicate()
			best["distance"] = d
	return best


func _sense_radius(spot: Dictionary) -> float:
	return maxf(MIN_SENSE_RADIUS, float(spot.get("radius", MIN_SENSE_RADIUS)))


func _dist_ratio_for_spot(spot: Dictionary) -> float:
	if spot.is_empty():
		return INF
	var radius: float = _sense_radius(spot)
	return float(spot.get("distance", INF)) / maxf(1.0, radius)


func _band_for_ratio(dist_ratio: float) -> String:
	if dist_ratio == INF or dist_ratio > BAND_MEDIUM:
		return "far"
	if dist_ratio <= BAND_CLOSE:
		return "close"
	return "medium"


func _proximity_01(dist_ratio: float) -> float:
	if dist_ratio == INF:
		return 0.0
	return clampf(1.0 - dist_ratio / BAND_MEDIUM, 0.0, 1.0)


func _duck_music() -> void:
	if _music_ducked:
		return
	AudioManager.duck_music_half()
	_music_ducked = true


func _restore_music_if_ducked() -> void:
	if not _music_ducked:
		return
	AudioManager.restore_music()
	_music_ducked = false


# ── EMF ───────────────────────────────────────────────────────

func _update_emf(dist_ratio: float, delta: float) -> void:
	var target: float = _proximity_01(dist_ratio) * EMF_MAX
	# Five equal arcs: orange = 4th (12–16), red = 5th (16–20).
	var t01: float = target / EMF_MAX
	var spike_chance: float = 0.0
	if t01 >= 0.8:
		spike_chance = 0.40  # red
	elif t01 >= 0.6:
		spike_chance = 0.20  # orange
	if spike_chance > 0.0:
		# Every 3–5s, roll chance to slam pin to max briefly.
		if _emf_spike_left > 0.0:
			_emf_spike_left -= delta
			_emf_value = EMF_MAX
			if _emf_spike_left <= 0.0:
				_emf_spike_left = 0.0
				_emf_spike_cd = _rng.randf_range(3.0, 5.0)
		else:
			_emf_spike_cd -= delta
			if _emf_spike_cd <= 0.0:
				_emf_spike_cd = _rng.randf_range(3.0, 5.0)
				if _rng.randf() < spike_chance:
					_emf_spike_left = _rng.randf_range(0.22, 0.40)
					_emf_value = EMF_MAX
			if _emf_spike_left <= 0.0:
				# Snap back toward live reading after a spike (faster than idle lerp).
				_emf_value = lerpf(_emf_value, target, 0.45)
	else:
		_emf_spike_left = 0.0
		if _emf_spike_cd <= 0.0:
			_emf_spike_cd = _rng.randf_range(3.0, 5.0)
		_emf_value = lerpf(_emf_value, target, 0.25)
	if _emf_gauge != null:
		_emf_gauge.queue_redraw()


func _draw_emf_gauge() -> void:
	var sz: Vector2 = _emf_gauge.size
	if sz.x < 8.0 or sz.y < 8.0:
		return
	var center := Vector2(sz.x * 0.5, sz.y * 0.78)
	var radius: float = minf(sz.x, sz.y) * 0.42
	var colors: Array[Color] = [
		Color(0.05, 0.45, 0.12),
		Color(0.35, 0.75, 0.20),
		Color(0.90, 0.85, 0.15),
		Color(0.95, 0.50, 0.10),
		Color(0.90, 0.12, 0.10),
	]
	# Upper semicircle: left (PI) → top (PI/2) → right (0). Positive sweep drew the
	# bottom half (upside-down rainbow).
	var start_a: float = PI
	var sweep: float = -PI
	var seg: float = sweep / float(colors.size())
	for i: int in colors.size():
		var a0: float = start_a + seg * float(i)
		var a1: float = a0 + seg
		_draw_arc_segment(_emf_gauge, center, radius - 10.0, radius, a0, a1, colors[i])
	var dig := FontManager.get_font("digital")
	if dig != null:
		_emf_gauge.draw_string(dig, center + Vector2(-radius - 2.0, 18.0), "0",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.45, 1.0, 0.55))
		_emf_gauge.draw_string(dig, center + Vector2(radius - 28.0, 18.0), "20",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.35, 0.30))
	# Needle: 0 at left (PI), 20 at right (0); shake harder during max spike.
	var t: float = clampf(_emf_value / EMF_MAX, 0.0, 1.0)
	var shake: float = sin(_time * 37.0) * 0.035 + sin(_time * 53.0) * 0.02
	if _emf_spike_left > 0.0:
		shake += sin(_time * 90.0) * 0.08 + sin(_time * 140.0) * 0.05
	var ang: float = PI - t * PI + shake
	var tip: Vector2 = center + Vector2(cos(ang), -sin(ang)) * (radius - 4.0)
	_emf_gauge.draw_line(center, tip, Color(1, 1, 1, 0.95), 2.0, true)
	_emf_gauge.draw_circle(center, 3.5, Color(1, 1, 1, 0.9))


func _draw_arc_segment(c: Control, center: Vector2, r_in: float, r_out: float,
		a0: float, a1: float, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var steps: int = 10
	for i: int in range(steps + 1):
		var a: float = lerpf(a0, a1, float(i) / float(steps))
		pts.append(center + Vector2(cos(a), -sin(a)) * r_out)
	for i: int in range(steps, -1, -1):
		var a2: float = lerpf(a0, a1, float(i) / float(steps))
		pts.append(center + Vector2(cos(a2), -sin(a2)) * r_in)
	c.draw_colored_polygon(pts, col)


# ── Thermometer ───────────────────────────────────────────────

func _update_thermometer(spot: Dictionary, dist_ratio: float, delta: float) -> void:
	var target: float = _room_temp
	if not spot.is_empty() and spot.has("temperature") and dist_ratio < INF:
		var spot_t: float = float(spot.get("temperature", _room_temp))
		var blend: float = _proximity_01(dist_ratio)
		target = lerpf(_room_temp, spot_t, blend)
	_display_temp = lerpf(_display_temp, target, clampf(THERMO_LERP_SPEED * delta, 0.0, 1.0))
	var band: int = int(floor(_display_temp / 10.0))
	if band != _last_temp_band:
		_last_temp_band = band
		SFXManager.play(SFX_THERMO_BEEP)
	_update_thermo_flicker(delta)


func _make_thermo_digit_label() -> Label:
	var lbl := Label.new()
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 48)
	lbl.add_theme_color_override("font_color", THERMO_DIGIT_COLOR)
	FontManager.tag_font(lbl, "font", "digital", 400)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _make_thermo_punct_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", THERMO_PUNCT_COLOR)
	FontManager.tag_font(lbl, "font", "primary", 600)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _show_thermo_normal() -> void:
	if _thermo_row == null:
		return
	var whole: int = int(floor(_display_temp))
	var frac: int = int(floor((_display_temp - float(whole)) * 100.0 + 0.5)) % 100
	if _thermo_int_lbl != null:
		_thermo_int_lbl.text = str(whole)
	if _thermo_frac_lbl != null:
		_thermo_frac_lbl.text = "%02d" % frac
	_thermo_row.visible = true
	if _thermo_glitch_lbl != null:
		_thermo_glitch_lbl.visible = false
		_thermo_glitch_lbl.modulate = Color.WHITE


func _show_thermo_glitch(text: String) -> void:
	if _thermo_row != null:
		_thermo_row.visible = false
	if _thermo_glitch_lbl == null:
		return
	_thermo_glitch_lbl.text = text
	_thermo_glitch_lbl.add_theme_color_override("font_color", THERMO_GLITCH_COLOR)
	# White-only flicker (alpha pulse), no color gradient.
	var flick: float = 0.55 + 0.45 * abs(sin(_time * 28.0))
	_thermo_glitch_lbl.modulate = Color(1.0, 1.0, 1.0, flick)
	_thermo_glitch_lbl.visible = true


func _update_thermo_flicker(delta: float) -> void:
	if _thermo_row == null and _thermo_glitch_lbl == null:
		return
	if _thermo_flicker_left > 0.0:
		_thermo_flicker_left -= delta
		_thermo_flicker_glyph_cd -= delta
		if _thermo_flicker_left <= 0.0:
			_thermo_flicker_left = 0.0
			_thermo_flicker_cd = _rng.randf_range(5.0, 20.0)
			_show_thermo_normal()
			return
		if _thermo_flicker_glyph_cd <= 0.0:
			_thermo_flicker_glyph_cd = _rng.randf_range(0.02, 0.06)
			_show_thermo_glitch(_random_thermo_glitch_text())
		else:
			# Keep white alpha pulse even between glyph swaps.
			_show_thermo_glitch(_thermo_glitch_lbl.text if _thermo_glitch_lbl != null else _random_thermo_glitch_text())
		return
	_thermo_flicker_cd -= delta
	if _thermo_flicker_cd <= 0.0:
		_thermo_flicker_left = _rng.randf_range(0.12, 0.38)
		_thermo_flicker_glyph_cd = 0.0
		_show_thermo_glitch(_random_thermo_glitch_text())
	else:
		_show_thermo_normal()


func _random_thermo_glitch_text() -> String:
	var n: int = _rng.randi_range(4, 5)
	var out := ""
	for _i: int in n:
		out += THERMO_FLICKER_CHARS[_rng.randi_range(0, THERMO_FLICKER_CHARS.length() - 1)]
	return out


# ── Translator ────────────────────────────────────────────────

func _update_translator(dist_ratio: float, delta: float) -> void:
	_wave_amp = lerpf(_wave_amp, _proximity_01(dist_ratio), 0.2)
	if _wave_draw != null:
		_wave_draw.queue_redraw()
	# Film grain only in close / mumbling zone (same band as mumbling bed).
	_update_film_grain_burst(delta, _band_for_ratio(dist_ratio) == "close")


## Intermittent movie film grain (close zone only): every 1–3s, 0.2–0.4s burst.
func _update_film_grain_burst(delta: float, in_close_zone: bool) -> void:
	if not in_close_zone:
		_film_grain_left = 0.0
		_film_grain_dur = 0.0
		if _film_grain_cd <= 0.0:
			_film_grain_cd = _rng.randf_range(1.0, 3.0)
		_set_film_grain_opacity(0.0)
		return
	if _film_grain_left > 0.0:
		_film_grain_left -= delta
		if _film_grain_left <= 0.0:
			_film_grain_left = 0.0
			_film_grain_dur = 0.0
			_film_grain_cd = _rng.randf_range(1.0, 3.0)
			_set_film_grain_opacity(0.0)
			return
		# Quick fade-in / fade-out envelope (~35% of burst each side, min 0.03s).
		var fade_t: float = maxf(0.03, _film_grain_dur * 0.35)
		var elapsed: float = _film_grain_dur - _film_grain_left
		var fade_in: float = clampf(elapsed / fade_t, 0.0, 1.0)
		var fade_out: float = clampf(_film_grain_left / fade_t, 0.0, 1.0)
		_set_film_grain_opacity(_film_grain_peak * fade_in * fade_out)
		return
	_film_grain_cd -= delta
	if _film_grain_cd <= 0.0:
		_film_grain_dur = _rng.randf_range(0.2, 0.4)
		_film_grain_left = _film_grain_dur
		_film_grain_peak = _rng.randf_range(0.05, 0.15)  # 5%–15% transparent peak
		_set_film_grain_opacity(0.0)
	else:
		_set_film_grain_opacity(0.0)


func _draw_waveform() -> void:
	var sz: Vector2 = _wave_draw.size
	if sz.x < 8.0 or sz.y < 8.0:
		return
	var mid_y: float = sz.y * 0.5
	var amp: float = 8.0 + _wave_amp * (sz.y * 0.38)
	var pts: PackedVector2Array = PackedVector2Array()
	var n: int = 48
	for i: int in n:
		var x: float = sz.x * float(i) / float(n - 1)
		var phase: float = _time * (6.0 + _wave_amp * 10.0) + float(i) * 0.45
		var y: float = mid_y + sin(phase) * amp * (0.35 + 0.65 * _rng.randf())
		# deterministic-ish wobble without reshuffling every pixel each frame
		y = mid_y + sin(phase) * amp + sin(phase * 2.3) * amp * 0.25 * _wave_amp
		pts.append(Vector2(x, y))
	for i: int in range(pts.size() - 1):
		_wave_draw.draw_line(pts[i], pts[i + 1], Color(0.45, 0.95, 1.0, 0.85), 2.0, true)


# ── Looping SFX ───────────────────────────────────────────────

func _update_proximity_audio(mouse: Vector2, force: bool,
		spot: Dictionary = {}, dist_ratio: float = INF) -> void:
	if _tool_id != TOOL_EMF and _tool_id != TOOL_TRANSLATOR:
		_stop_loops()
		return
	if spot.is_empty() and not force:
		spot = _nearest_spot(mouse)
		dist_ratio = _dist_ratio_for_spot(spot)
	var band: String = _band_for_ratio(dist_ratio)
	var stream: AudioStream = null
	var key: String = "%s:%s" % [_tool_id, band]
	if _tool_id == TOOL_EMF:
		match band:
			"close":
				stream = SFX_EMF_CLOSE
			"medium":
				stream = SFX_EMF_MED
			_:
				stream = SFX_EMF_SLOW
	else:
		match band:
			"far":
				stream = SFX_RADIO_LOW
			_:
				stream = SFX_RADIO_HIGH
	var loop_vol: float = 0.75 if _tool_id == TOOL_TRANSLATOR else 1.0
	if force or key != _loop_key:
		_loop_key = key
		_play_loop(_loop_a, stream, loop_vol)
	elif _loop_a != null:
		_loop_a.volume_db = linear_to_db(loop_vol)
	# Mumbling only on translator close
	if _tool_id == TOOL_TRANSLATOR and band == "close":
		var mpath: String = str(spot.get("mumbling_sound", "")).strip_edges()
		if mpath.is_empty() or not ResourceLoader.exists(mpath):
			mpath = _random_mumble()
		var mkey: String = "mumble:%s" % mpath
		if force or mkey != _mumble_key:
			_mumble_key = mkey
			if not mpath.is_empty() and ResourceLoader.exists(mpath):
				_play_loop(_loop_b, load(mpath) as AudioStream, 1.2)
			else:
				_stop_player(_loop_b)
				_mumble_key = ""
		elif _loop_b != null:
			_loop_b.volume_db = linear_to_db(1.2)
	else:
		if not _mumble_key.is_empty():
			_stop_player(_loop_b)
			_mumble_key = ""


func _random_mumble() -> String:
	if _mumble_pool.is_empty():
		_scan_mumble_pool()
	if _mumble_pool.is_empty():
		return ""
	return _mumble_pool[_rng.randi_range(0, _mumble_pool.size() - 1)]


func _play_loop(player: AudioStreamPlayer, stream: AudioStream, volume: float = 1.0) -> void:
	if player == null or stream == null:
		return
	var looped: AudioStream = stream.duplicate()
	if looped is AudioStreamMP3:
		(looped as AudioStreamMP3).loop = true
	elif looped is AudioStreamOggVorbis:
		(looped as AudioStreamOggVorbis).loop = true
	player.stop()
	player.stream = looped
	player.volume_db = linear_to_db(maxf(0.001, volume))
	player.play()


func _stop_player(player: AudioStreamPlayer) -> void:
	if player != null:
		player.stop()
		player.stream = null


func _stop_loops() -> void:
	_stop_player(_loop_a)
	_stop_player(_loop_b)
	_loop_key = ""
	_mumble_key = ""


# ── Polaroid ──────────────────────────────────────────────────

func _play_shutter_flash() -> void:
	SFXManager.play(SFX_SHUTTER)
	if _flash == null:
		return
	_flash.visible = true
	_flash.color = Color(1, 1, 1, 0.92)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.22)
	tw.finished.connect(func() -> void:
		if is_instance_valid(_flash):
			_flash.visible = false)


func _run_polaroid_mode2(_global_pos: Vector2) -> void:
	_polaroid_busy = true
	_play_shutter_flash()
	await get_tree().create_timer(0.12).timeout
	if not is_inside_tree() or _tool_id != TOOL_POLAROID:
		_polaroid_busy = false
		return
	var tex: Texture2D = _compose_photo_texture()
	_show_polaroid_overlay(tex)
	_polaroid_busy = false
	# Leave camera active mode as soon as the picture is taken; overlay stays.
	polaroid_shot_finished.emit()
	await get_tree().create_timer(PRINT_SFX_DELAY).timeout
	if not is_inside_tree() or not is_polaroid_overlay_open():
		return
	SFXManager.play(SFX_PRINT)
	if not _photo_vn.is_empty() and ResourceLoader.exists(_photo_vn):
		_polaroid_can_dismiss = false
		_awaiting_photo_vn = true
		photo_vn_requested.emit(_photo_vn)
	else:
		_polaroid_can_dismiss = true


func _compose_photo_texture() -> Texture2D:
	var base: Texture2D = null
	if not _photo_alt_bg.is_empty() and ResourceLoader.exists(_photo_alt_bg):
		base = load(_photo_alt_bg) as Texture2D
	if base == null:
		base = _bg_tex
	var w: int = 960
	var h: int = 720
	if base != null:
		w = maxi(64, base.get_width())
		h = maxi(64, base.get_height())
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.08, 0.1, 1.0))
	var bi: Image = _texture_to_rgba_image(base)
	if bi != null:
		if bi.get_width() != w or bi.get_height() != h:
			bi = bi.duplicate()
			bi.resize(w, h, Image.INTERPOLATE_BILINEAR)
		img.blit_rect(bi, Rect2i(0, 0, w, h), Vector2i.ZERO)
	# Smoke at EVERY tool-gated spot in the room (any detective tool).
	var smoke_spots: Array = _photo_smoke_spots
	if smoke_spots.is_empty():
		smoke_spots = _spots
	var mouse: Vector2 = get_viewport().get_mouse_position()
	for spot_var: Variant in smoke_spots:
		if not spot_var is Dictionary:
			continue
		_blit_smoke_for_spot(img, spot_var as Dictionary, mouse, w, h)
	return ImageTexture.create_from_image(img)


func _blit_smoke_for_spot(img: Image, spot: Dictionary, mouse: Vector2, w: int, h: int) -> void:
	var center: Vector2 = spot.get("center", Vector2.ZERO)
	var radius: float = maxf(MIN_SENSE_RADIUS, float(spot.get("radius", 90.0)))
	# Closest smoke caps at 40% opacity; farther spots fade lower.
	var prox: float = clampf(1.0 - mouse.distance_to(center) / (radius * 3.0), 0.08, 0.40)
	var spath: String = str(spot.get("smoke_image", "")).strip_edges()
	if spath.is_empty() or not ResourceLoader.exists(spath):
		if SMOKE_PATHS.is_empty():
			return
		spath = SMOKE_PATHS[_rng.randi_range(0, SMOKE_PATHS.size() - 1)]
	var si: Image = _load_rgba_image(spath)
	if si == null:
		return
	var sw: int = clampi(int(float(w) * 0.28), 96, 320)
	var sh: int = clampi(int(float(h) * 0.28), 96, 320)
	si = si.duplicate()
	si.resize(sw, sh, Image.INTERPOLATE_BILINEAR)
	var xn: float = float(spot.get("x_norm", -1.0))
	var yn: float = float(spot.get("y_norm", -1.0))
	if xn < 0.0 or yn < 0.0:
		var vp: Vector2 = get_viewport_rect().size
		xn = clampf(center.x / maxf(1.0, vp.x), 0.0, 1.0)
		yn = clampf(center.y / maxf(1.0, vp.y), 0.0, 1.0)
	var px: int = int(xn * float(w)) - sw / 2
	var py: int = int(yn * float(h)) - sh / 2
	_blit_alpha(img, si, Vector2i(px, py), prox)


func _texture_to_rgba_image(tex: Texture2D) -> Image:
	if tex == null:
		return null
	var path: String = tex.resource_path
	if not path.is_empty():
		var from_file: Image = _load_rgba_image(path)
		if from_file != null:
			return from_file
	var img: Image = tex.get_image()
	if img == null:
		return null
	img = img.duplicate()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


func _load_rgba_image(path: String) -> Image:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var abs_path: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var file_img := Image.new()
		if file_img.load(abs_path) == OK:
			if file_img.get_format() != Image.FORMAT_RGBA8:
				file_img.convert(Image.FORMAT_RGBA8)
			return file_img
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null:
		return null
	img = img.duplicate()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


func _blit_alpha(dst: Image, src: Image, pos: Vector2i, alpha_scale: float) -> void:
	var dw: int = dst.get_width()
	var dh: int = dst.get_height()
	var sw: int = src.get_width()
	var sh: int = src.get_height()
	for y: int in sh:
		var dy: int = pos.y + y
		if dy < 0 or dy >= dh:
			continue
		for x: int in sw:
			var dx: int = pos.x + x
			if dx < 0 or dx >= dw:
				continue
			var sc: Color = src.get_pixel(x, y)
			if sc.a <= 0.01:
				continue
			var dc: Color = dst.get_pixel(dx, dy)
			var a: float = sc.a * alpha_scale
			dst.set_pixel(dx, dy, Color(
				lerpf(dc.r, sc.r, a),
				lerpf(dc.g, sc.g, a),
				lerpf(dc.b, sc.b, a),
				1.0))


func _show_polaroid_overlay(tex: Texture2D) -> void:
	_dismiss_polaroid_overlay(false)
	_polaroid_layer = Control.new()
	_polaroid_layer.name = "PolaroidOverlay"
	_polaroid_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_polaroid_layer.z_index = 110
	_ui_root.add_child(_polaroid_layer)
	_polaroid_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_polaroid_layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_polaroid_layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Reuse Photo Scatter polaroid frame, enlarged for the Mode 2 overlay.
	var card: Control = PhotoScatter.make_polaroid_card(tex, 1.85)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(card)

	var hint := Label.new()
	hint.text = "Click to dismiss"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	hint.add_theme_font_size_override("font_size", 16)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_polaroid_layer.add_child(hint)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.offset_left = -160.0
	hint.offset_right = 160.0
	hint.offset_top = -56.0
	hint.offset_bottom = -28.0


func _dismiss_polaroid_overlay(emit_signal_flag: bool) -> void:
	if _polaroid_layer != null and is_instance_valid(_polaroid_layer):
		_polaroid_layer.queue_free()
	_polaroid_layer = null
	_polaroid_can_dismiss = false
	_awaiting_photo_vn = false
	if emit_signal_flag:
		polaroid_overlay_dismissed.emit()
