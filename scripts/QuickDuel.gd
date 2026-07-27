extends Control
## Quick Duel — main-menu overlay (instantiated by MainMenu, not a standalone scene).

signal closed

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const DeckData = preload("res://resources/DeckData.gd")
const CAPSULE_W := 280.0
const CAPSULE_H := 440.0
const CAPSULE_GAP := 40.0
const CAPSULE_SIDE_MARGIN := 96.0
const CAPSULE_REWARD_ROW_H := 36.0
const TIER_FONT_SIZE := 34
const HEADER_HEIGHT := 56.0
const TITLE_FONT_SIZE := 26
const TITLE_COLOR := Color(0.40, 0.85, 1.0, 1.0)
const REWARD_SHADOW_COLOR := Color(0, 0, 0, 1)
const REWARD_SHADOW_OFFSET := Vector2(2, 2)
const HOVER_OVERLAY_COLOR := Color(1.0, 1.0, 1.0, 0.22)
const DEFAULT_PORTRAIT_P1 := "res://assets/textures/ui/portraits/profile_player_1_default.png"
const DEFAULT_PORTRAIT_P2 := "res://assets/textures/ui/portraits/profile_player_2_default.png"
const PORTRAIT_REF_H := 720.0
const PORTRAIT_PEEK := 0.4
const SettingsMenuScene := preload("res://scenes/settings_menu.tscn")
const ProtagonistOverlayScene := preload("res://scripts/ProtagonistOverlay.gd")
const _ROUNDED_RECT_CLIP: Shader = preload("res://assets/shaders/rounded_rect_clip.gdshader")
const CAPSULE_FRAME_RADIUS := 12.0
const CAPSULE_FRAME_BORDER := 2.0
const CAPSULE_IMAGE_RADIUS := CAPSULE_FRAME_RADIUS - CAPSULE_FRAME_BORDER
const OVERLAY_Z_INDEX := 80
const BG_PATH := "res://assets/textures/ui/battle/v3_magitech/ui_bg_quick_duel.png"
## Grow backdrop past viewport edges so no seam / letterbox shows.
const BG_OVERSCAN := 0.18
## Thin streak traces — warm-tinted for molten fire sparks (not electric arcs).
const _FIRE_SPARK_STREAK_PATHS: Array[String] = [
	"res://assets/textures/ui/battle/v3_magitech/vfx/ui_magitech_vfx_bolt_c.png",
	"res://assets/textures/ui/battle/v3_magitech/vfx/ui_magitech_vfx_bolt_f.png",
	"res://assets/textures/ui/battle/v3_magitech/vfx/ui_magitech_vfx_bolt_g.png",
]
const _SFX_JOLT: AudioStream = preload(
	"res://assets/audio/sfx/sfx_electric_short_circuit.mp3")
const _SPARK_INTERVAL_MIN := 3.0
const _SPARK_INTERVAL_MAX := 5.0
const _SPARK_GRAVITY := 1200.0
const _SPARK_FLICKER_SEC := 0.05
const _SPARK_FLASH_ALPHA := 0.1
const _SPARK_FX_Z := 3
const _SPARK_FLASH_Z := 45
const _SPARK_BURST_COUNT_MIN := 18
const _SPARK_BURST_COUNT_MAX := 32
const _SPARK_SPEED_MIN := 220.0
const _SPARK_SPEED_MAX := 620.0
## Idle cinema: hide HUD / capsules / header after no mouse movement.
const _IDLE_HIDE_SEC := 5.0
const _HUD_FADE_OUT_SEC := 0.7
const _HUD_FADE_IN_SEC := 0.45

var _picker_panel: Control = null
var _status_lbl: Label = null
var _casual_btn: Button = null
var _reroll_btn: Button = null
var _tier_capsules: Dictionary = {}
var _player_portrait: TextureRect = null
var _switch_char_btn: Button = null
var _exit_anim_running: bool = false
var _exit_anim_done: bool = false
var _bg_rect: TextureRect = null
var _spark_textures: Array[Texture2D] = []
var _fx_layer: Control = null
var _flash_rect: ColorRect = null
var _active_sparks: Array = []
var _spark_fx_running: bool = false
var _spark_add_mat: CanvasItemMaterial = null
var _hud_layer: Control = null
var _idle_timer: float = 0.0
var _hud_cinema: bool = false
var _hud_fade_tween: Tween = null
var _last_mouse_pos: Vector2 = Vector2.INF


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	set_process(true)
	set_process_input(true)
	VNPlayer.dismiss_overlay_if_present(get_tree())
	BGMManager.play_context(BGMManager.CONTEXT_MAIN_MENU, 0.6, 0.6)
	_build_shell()
	_start_ambient_spark_loop()
	await OnboardingManager.wait_until_settled()
	if not is_inside_tree():
		return
	_open_initial_view()


func _open_initial_view() -> void:
	if SaveManager.is_attack_tutorial_complete():
		_show_picker()
	else:
		_show_tutorial_prompt()


func _build_shell() -> void:
	# Black underlay so any overscan gap never shows through.
	var underlay := ColorRect.new()
	underlay.color = Color(0, 0, 0, 1)
	underlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	underlay.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(underlay)

	_bg_rect = TextureRect.new()
	_bg_rect.texture = load(BG_PATH) as Texture2D
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Rect is sized to image aspect; SCALE fills that rect with no distortion.
	_bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_bg_rect.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_bg_rect)
	_layout_bg_cover()
	resized.connect(_layout_bg_cover)
	call_deferred("_layout_bg_cover")

	_build_ambient_fx_layer()

	# HUD layer (header / capsules / portrait) — fades out on idle for cinema.
	_hud_layer = Control.new()
	_hud_layer.name = "QuickDuelHud"
	_hud_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.z_index = 5
	add_child(_hud_layer)

	_build_header()

	_picker_panel = Control.new()
	_picker_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_picker_panel.offset_top = HEADER_HEIGHT
	_picker_panel.visible = false
	_picker_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_add_panel(_picker_panel)

	_build_picker_ui()
	_build_player_portrait_zone()


func _layout_bg_cover() -> void:
	if _bg_rect == null or not is_instance_valid(_bg_rect):
		return
	# Prefer fresh disk texture in case editor still holds a padded import.
	var tex: Texture2D = ResourceLoader.load(
		BG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if tex != null:
		_bg_rect.texture = tex
	else:
		tex = _bg_rect.texture
	if tex == null:
		return
	var area: Vector2 = get_viewport().get_visible_rect().size
	if area.x < 8.0 or area.y < 8.0:
		area = size
	if area.x < 8.0 or area.y < 8.0:
		return
	var tex_sz: Vector2 = tex.get_size()
	if tex_sz.x < 1.0 or tex_sz.y < 1.0:
		return
	var tex_aspect: float = tex_sz.x / tex_sz.y
	var view_aspect: float = area.x / area.y
	# Cover viewport (plus overscan), keep image ratio — crop the overflow side.
	var cover_w: float
	var cover_h: float
	if view_aspect > tex_aspect:
		cover_w = area.x * (1.0 + BG_OVERSCAN * 2.0)
		cover_h = cover_w / tex_aspect
	else:
		cover_h = area.y * (1.0 + BG_OVERSCAN * 2.0)
		cover_w = cover_h * tex_aspect
	_bg_rect.set_anchors_preset(Control.PRESET_CENTER)
	_bg_rect.anchor_left = 0.5
	_bg_rect.anchor_top = 0.5
	_bg_rect.anchor_right = 0.5
	_bg_rect.anchor_bottom = 0.5
	_bg_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bg_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	_bg_rect.offset_left = -cover_w * 0.5
	_bg_rect.offset_top = -cover_h * 0.5
	_bg_rect.offset_right = cover_w * 0.5
	_bg_rect.offset_bottom = cover_h * 0.5
	_bg_rect.custom_minimum_size = Vector2(cover_w, cover_h)
	_bg_rect.size = Vector2(cover_w, cover_h)


func _build_ambient_fx_layer() -> void:
	_spark_textures.clear()
	for path: String in _FIRE_SPARK_STREAK_PATHS:
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			_spark_textures.append(tex)
	_spark_add_mat = CanvasItemMaterial.new()
	_spark_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_fx_layer = Control.new()
	_fx_layer.name = "AmbientSparkFx"
	_fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.z_index = _SPARK_FX_Z
	_fx_layer.clip_contents = false
	add_child(_fx_layer)

	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.z_index = _SPARK_FLASH_Z
	add_child(_flash_rect)


func _start_ambient_spark_loop() -> void:
	if _spark_textures.is_empty() or _spark_fx_running:
		return
	_spark_fx_running = true
	set_process(true)
	_ambient_spark_loop()


func _stop_ambient_spark_fx() -> void:
	_spark_fx_running = false
	for entry: Variant in _active_sparks:
		if entry is Dictionary:
			var node: Variant = (entry as Dictionary).get("node")
			if node is Node and is_instance_valid(node as Node):
				(node as Node).queue_free()
	_active_sparks.clear()
	if _flash_rect != null and is_instance_valid(_flash_rect):
		_flash_rect.color.a = 0.0


func _ambient_spark_loop() -> void:
	while _spark_fx_running and is_inside_tree():
		var wait_sec: float = randf_range(_SPARK_INTERVAL_MIN, _SPARK_INTERVAL_MAX)
		await get_tree().create_timer(wait_sec).timeout
		if not _spark_fx_running or not is_inside_tree():
			return
		_play_fire_spark_burst()


func _play_fire_spark_burst() -> void:
	if _fx_layer == null or _spark_textures.is_empty():
		return
	SFXManager.play(_SFX_JOLT, 0.55)
	_flash_white()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var area: Vector2 = size
	if area.x < 8.0 or area.y < 8.0:
		area = get_viewport().get_visible_rect().size
	# One origin per burst (random location); all sparks fan out from it.
	var origin := Vector2(
		rng.randf_range(area.x * 0.12, area.x * 0.88),
		rng.randf_range(area.y * 0.12, area.y * 0.62))
	# Cone aims mostly sideways / down-right or down-left.
	var aim_right: bool = rng.randf() < 0.5
	var cone_center: float = (-0.35 if aim_right else PI + 0.35) \
			+ rng.randf_range(-0.25, 0.25)
	var cone_half: float = rng.randf_range(0.70, 1.05)  # ~80–120° spread
	var count: int = rng.randi_range(_SPARK_BURST_COUNT_MIN, _SPARK_BURST_COUNT_MAX)
	for _i: int in range(count):
		_spawn_falling_spark(rng, origin, cone_center, cone_half)


func _flash_white() -> void:
	if _flash_rect == null or not is_instance_valid(_flash_rect):
		return
	_flash_rect.color = Color(1, 1, 1, _SPARK_FLASH_ALPHA)
	var tw := create_tween()
	tw.tween_property(_flash_rect, "color:a", 0.0, 0.22) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _fire_spark_ember_color(rng: RandomNumberGenerator, peak_a: float) -> Color:
	# Hot metal: white-yellow core → orange as heat cools.
	var heat: float = rng.randf()
	return Color(
		1.0,
		lerpf(0.35, 0.98, heat),
		lerpf(0.08, 0.55, heat * heat),
		peak_a)


func _spawn_falling_spark(
		rng: RandomNumberGenerator,
		origin: Vector2,
		cone_center: float,
		cone_half: float) -> void:
	if _fx_layer == null or _spark_textures.is_empty():
		return
	var tr := TextureRect.new()
	tr.texture = _spark_textures[rng.randi_range(0, _spark_textures.size() - 1)]
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.material = _spark_add_mat
	# Thin elongated streak.
	var len: float = rng.randf_range(16.0, 52.0)
	if rng.randf() < 0.22:
		len *= rng.randf_range(0.40, 0.70)
	elif rng.randf() < 0.14:
		len *= rng.randf_range(1.20, 1.70)
	var tex_sz: Vector2 = tr.texture.get_size() if tr.texture != null else Vector2(1, 1)
	var aspect: float = tex_sz.x / maxf(tex_sz.y, 1.0)
	if aspect >= 1.0:
		tr.size = Vector2(len, len / aspect)
	else:
		tr.size = Vector2(len * aspect, len)
	tr.pivot_offset = tr.size * 0.5
	tr.flip_h = rng.randf() < 0.5
	tr.flip_v = rng.randf() < 0.5
	var uni: float = rng.randf_range(0.70, 1.20)
	tr.scale = Vector2(uni, uni)
	var peak_a: float = rng.randf_range(0.75, 1.0)
	tr.modulate = _fire_spark_ember_color(rng, peak_a)
	# Fan velocity from the shared origin.
	var ang: float = cone_center + rng.randf_range(-cone_half, cone_half)
	var speed: float = rng.randf_range(_SPARK_SPEED_MIN, _SPARK_SPEED_MAX)
	var vel := Vector2(cos(ang), sin(ang)) * speed
	tr.position = origin - tr.size * 0.5
	tr.rotation = ang - PI * 0.5
	_fx_layer.add_child(tr)
	_active_sparks.append({
		"node": tr,
		"vel": vel,
		"peak_a": peak_a,
		"flicker_t": 0.0,
	})


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _last_mouse_pos == Vector2.INF or mm.position.distance_squared_to(_last_mouse_pos) > 0.25:
			_last_mouse_pos = mm.position
			_on_quick_duel_mouse_activity()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_on_quick_duel_mouse_activity()


func _process(delta: float) -> void:
	_tick_idle_cinema(delta)
	if _active_sparks.is_empty():
		return
	var area_h: float = size.y
	if area_h < 8.0:
		area_h = get_viewport().get_visible_rect().size.y
	var area_w: float = size.x
	if area_w < 8.0:
		area_w = get_viewport().get_visible_rect().size.x
	var keep: Array = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for entry: Variant in _active_sparks:
		if not (entry is Dictionary):
			continue
		var d: Dictionary = entry
		var node: Variant = d.get("node")
		if not (node is TextureRect) or not is_instance_valid(node as TextureRect):
			continue
		var tr: TextureRect = node as TextureRect
		var vel: Vector2 = d.get("vel", Vector2.ZERO) as Vector2
		vel.y += _SPARK_GRAVITY * delta
		d["vel"] = vel
		tr.position += vel * delta
		# Keep streak aligned with travel as gravity arcs it down.
		tr.rotation = lerp_angle(tr.rotation, atan2(vel.y, vel.x) - PI * 0.5, 0.35)
		var flicker_t: float = float(d.get("flicker_t", 0.0)) + delta
		if flicker_t >= _SPARK_FLICKER_SEC:
			flicker_t = 0.0
			var peak_a: float = float(d.get("peak_a", 1.0))
			tr.modulate = _fire_spark_ember_color(rng, peak_a * rng.randf_range(0.50, 1.0))
		d["flicker_t"] = flicker_t
		var center: Vector2 = tr.position + tr.size * 0.5
		if center.y > area_h + 80.0 or center.x < -140.0 or center.x > area_w + 140.0:
			tr.queue_free()
		else:
			keep.append(d)
	_active_sparks = keep


func _root_add_panel(panel: Control) -> void:
	if _hud_layer != null and is_instance_valid(_hud_layer):
		_hud_layer.add_child(panel)
	else:
		add_child(panel)


func _build_header() -> void:
	var top_bg := Panel.new()
	top_bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bg.offset_bottom = HEADER_HEIGHT
	top_bg.custom_minimum_size.y = HEADER_HEIGHT
	# Layout slot only — no fill/border; title + buttons stay visible.
	top_bg.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	top_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_add_panel(top_bg)

	# Children of the bar so CENTER_* anchors vertically middle the header.
	var title := Label.new()
	MenuScreenHeader.style_title(title, "QUICK DUEL")
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 4)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title.offset_left = -240.0
	title.offset_top = -18.0
	title.offset_right = 240.0
	title.offset_bottom = 18.0
	top_bg.add_child(title)

	var close_btn := Button.new()
	MenuScreenHeader.style_close_button(close_btn)
	var close_inset: float = MenuScreenHeader.CLOSE_INSET
	var close_sz: Vector2 = MenuScreenHeader.CLOSE_BTN_SIZE
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	close_btn.offset_left = -(close_inset + close_sz.x)
	close_btn.offset_right = -close_inset
	close_btn.offset_top = -close_sz.y * 0.5
	close_btn.offset_bottom = close_sz.y * 0.5
	close_btn.pressed.connect(_dismiss_overlay)
	top_bg.add_child(close_btn)

	var ach_btn := Button.new()
	ach_btn.text = "Achievements"
	var ach_h: float = close_sz.y
	var ach_w: float = 120.0
	ach_btn.custom_minimum_size = Vector2(ach_w, ach_h)
	ach_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	ach_btn.offset_left = -(close_inset + close_sz.x + 8.0 + ach_w)
	ach_btn.offset_right = -(close_inset + close_sz.x + 8.0)
	ach_btn.offset_top = -ach_h * 0.5
	ach_btn.offset_bottom = ach_h * 0.5
	_skin_quick_duel_button(ach_btn)
	ach_btn.pressed.connect(func() -> void:
		AchievementListOverlay.open(self))
	top_bg.add_child(ach_btn)


func _build_player_portrait_zone() -> void:
	var portrait_path: String = SaveManager.get_protagonist_portrait_path()
	var tex: Texture2D = GameState.load_portrait_texture(portrait_path)

	_player_portrait = TextureRect.new()
	_player_portrait.texture = tex
	_player_portrait.anchor_left = 0.0
	_player_portrait.anchor_top = 1.0
	_player_portrait.anchor_right = 0.0
	_player_portrait.anchor_bottom = 1.0
	_player_portrait.offset_bottom = 0.0
	_apply_player_portrait_layout(tex)
	_player_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_player_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_player_portrait.flip_h = true
	_player_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_portrait.z_index = 2
	_root_add_panel(_player_portrait)

	_switch_char_btn = Button.new()
	_switch_char_btn.text = "Switch Character"
	_switch_char_btn.custom_minimum_size = Vector2(168, 34)
	_switch_char_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_switch_char_btn.offset_left = 12.0
	_switch_char_btn.offset_top = -52.0
	_switch_char_btn.offset_right = 180.0
	_switch_char_btn.offset_bottom = -16.0
	_switch_char_btn.z_index = 10
	_switch_char_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_skin_quick_duel_button(_switch_char_btn)
	_switch_char_btn.pressed.connect(_open_protagonist_overlay)
	_root_add_panel(_switch_char_btn)


func _refresh_player_portrait() -> void:
	if _player_portrait == null:
		return
	var portrait_path: String = SaveManager.get_protagonist_portrait_path()
	var tex: Texture2D = GameState.load_portrait_texture(portrait_path)
	_player_portrait.texture = tex
	_apply_player_portrait_layout(tex)


func _apply_player_portrait_layout(tex: Texture2D) -> void:
	if _player_portrait == null:
		return
	var portrait_w: float = PORTRAIT_REF_H * 0.55
	if tex != null:
		var sz := tex.get_size()
		if sz.y > 0.0:
			portrait_w = PORTRAIT_REF_H * sz.x / sz.y
	_player_portrait.offset_left = -portrait_w * PORTRAIT_PEEK
	_player_portrait.offset_top = -PORTRAIT_REF_H
	_player_portrait.offset_right = portrait_w * (1.0 - PORTRAIT_PEEK)


func _open_protagonist_overlay() -> void:
	var overlay: ProtagonistOverlay = ProtagonistOverlayScene.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = OVERLAY_Z_INDEX
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if overlay.has_signal("closed"):
		overlay.closed.connect(func() -> void:
			_refresh_player_portrait())
	add_child(overlay)


func _should_show_switch_character() -> bool:
	if SaveManager.demo_mode:
		return true
	return SaveManager.get_unlocked_protagonists().size() >= 2


func _set_protagonist_zone_visible(visible: bool) -> void:
	if _player_portrait != null:
		_player_portrait.visible = visible
	if _switch_char_btn != null:
		_switch_char_btn.visible = visible and _should_show_switch_character()


func _show_tutorial_prompt() -> void:
	_picker_panel.visible = false
	_set_protagonist_zone_visible(false)
	if GameDialog.has_open_overlay(self):
		return
	GameDialog.confirmation_overlay(
		self,
		"Quick Duel Tutorial",
		"Do you need a tutorial on card battle?",
		"Yes — Teach Me",
		"No — Skip",
		func() -> void: launch_tutorial(),
		func() -> void:
			SaveManager.mark_attack_tutorial_complete()
			_show_picker())


func _build_picker_ui() -> void:
	var body := Control.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picker_panel.add_child(body)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -56.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(center)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(CAPSULE_SIDE_MARGIN))
	margin.add_theme_constant_override("margin_right", int(CAPSULE_SIDE_MARGIN))
	center.add_child(margin)

	var tier_row := HBoxContainer.new()
	tier_row.add_theme_constant_override("separation", CAPSULE_GAP)
	tier_row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(tier_row)

	for tier: String in ["easy", "normal", "hard"]:
		var capsule := _build_tier_capsule(tier)
		tier_row.add_child(capsule["root"])
		_tier_capsules[tier] = capsule

	var bottom_bar := HBoxContainer.new()
	bottom_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	bottom_bar.offset_left = -560.0
	bottom_bar.offset_top = -52.0
	bottom_bar.offset_right = -24.0
	bottom_bar.offset_bottom = -16.0
	bottom_bar.add_theme_constant_override("separation", 12)
	bottom_bar.alignment = BoxContainer.ALIGNMENT_END
	body.add_child(bottom_bar)

	_casual_btn = Button.new()
	_casual_btn.custom_minimum_size = Vector2(220, 36)
	_skin_quick_duel_button(_casual_btn)
	_casual_btn.pressed.connect(_open_settings)
	bottom_bar.add_child(_casual_btn)

	_reroll_btn = Button.new()
	_reroll_btn.custom_minimum_size = Vector2(220, 36)
	_skin_quick_duel_button(_reroll_btn)
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	bottom_bar.add_child(_reroll_btn)

	_status_lbl = Label.new()
	_status_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status_lbl.offset_top = -28.0
	_status_lbl.offset_bottom = -8.0
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 12)
	_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.45))
	body.add_child(_status_lbl)


func _show_picker() -> void:
	GameDialog.close_overlay(self)
	_picker_panel.visible = true
	_set_protagonist_zone_visible(true)
	if SaveManager.reconcile_protagonist_selection():
		SaveManager.save_data()
	_sanitize_saved_offers_if_needed()
	if GameState.quick_duel_reroll_previews or not SaveManager.has_quick_duel_offers():
		_roll_all_tier_offers()
		GameState.quick_duel_reroll_previews = false
	_refresh_picker_capsules()
	_refresh_casual_button()
	_refresh_reroll_button()
	_refresh_player_portrait()


func _roll_all_tier_offers() -> void:
	var previews: Dictionary = {}
	var rewards: Dictionary = {}
	var identities: Dictionary = {}
	var demo_only: bool = SaveManager.demo_mode
	var protagonist_id: String = SaveManager.quick_duel_protagonist_id
	for tier: String in ["easy", "normal", "hard"]:
		var tags: Array = QuickDuelRewards.get_tier_tags(tier)
		var entry: Dictionary = AIDeckVault.pick_random_entry_for_tags(tags, demo_only)
		previews[tier] = str(entry.get("id", "")).strip_edges() if not entry.is_empty() else ""
		rewards[tier] = QuickDuelRewards.pick_random_rewards(tier)
		var identity: Dictionary = AIIdentityVault.pick_random_for_tier(tier, protagonist_id)
		identities[tier] = str(identity.get("id", "")).strip_edges() if not identity.is_empty() else ""
	SaveManager.set_quick_duel_tier_offers(previews, rewards, identities)


func _sanitize_saved_offers_if_needed() -> void:
	if not SaveManager.has_quick_duel_offers():
		return
	var previews: Dictionary = SaveManager.quick_duel_tier_previews.duplicate(true)
	var rewards: Dictionary = {}
	var changed: bool = false
	for tier: String in ["easy", "normal", "hard"]:
		var raw: Array = SaveManager.get_quick_duel_rewards(tier)
		var fixed: Array = QuickDuelRewards.repair_tier_rewards(tier, raw)
		fixed = QuickDuelRewards.dedupe_rewards(fixed)
		rewards[tier] = fixed
		if JSON.stringify(fixed) != JSON.stringify(raw):
			changed = true
	if changed:
		SaveManager.set_quick_duel_tier_offers(previews, rewards, SaveManager.quick_duel_tier_identities)


func _refresh_picker_capsules() -> void:
	var all_empty: bool = true
	for tier: String in ["easy", "normal", "hard"]:
		var entry_id: String = SaveManager.get_quick_duel_preview(tier)
		var entry: Dictionary = AIDeckVault.get_entry(entry_id) if not entry_id.is_empty() else {}
		_update_tier_capsule(tier, entry)
		if not entry.is_empty():
			all_empty = false
	if all_empty:
		_status_lbl.text = "No duels available — check vault tags"
	else:
		_status_lbl.text = ""


func _build_tier_capsule(tier: String) -> Dictionary:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.alignment = BoxContainer.ALIGNMENT_CENTER

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(CAPSULE_W, CAPSULE_H)
	btn.toggle_mode = false
	_apply_transparent_button_style(btn)
	btn.pressed.connect(func() -> void: launch_vault_duel(tier))
	root.add_child(btn)

	return {
		"root": root,
		"btn": btn,
		"tier": tier,
	}


## Magitech blue gradient fill + border (same chrome as dialog / menu buttons).
func _skin_quick_duel_button(btn: Button, wire_sfx: bool = true) -> void:
	if btn == null:
		return
	btn.add_theme_color_override("font_color", Color(0.88, 0.95, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.82, 0.92, 1.0, 1.0))
	GameDialog.apply_button_chrome(btn, wire_sfx)


## Capsule chrome: magitech fill + always-on circuit patrol along the border.
func _skin_capsule_frame(frame: PanelContainer) -> void:
	if frame == null:
		return
	GameDialog.attach_panel_fx(frame)
	var mat: ShaderMaterial = frame.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("fill_top", Color(0.0, 0.0, 0.0, 1.0))
	mat.set_shader_parameter("fill_bottom", Color(0.0, 0.0, 0.0, 1.0))
	mat.set_shader_parameter("border_a", Color(1.0, 1.0, 1.0, 0.95))
	mat.set_shader_parameter("border_b", Color(1.0, 1.0, 1.0, 0.85))
	mat.set_shader_parameter("border_px", 2.5)
	mat.set_shader_parameter("corner_radius_px", CAPSULE_FRAME_RADIUS)
	mat.set_shader_parameter("rim_speed", 0.40)
	mat.set_shader_parameter("rim_pulse", 0.68)
	mat.set_shader_parameter("circuit_patrol", 1.0)


func _apply_transparent_button_style(btn: Button) -> void:
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_stylebox_override("disabled", empty)


func _update_tier_capsule(tier: String, entry: Dictionary) -> void:
	var cap: Dictionary = _tier_capsules.get(tier, {})
	if cap.is_empty():
		return
	var btn: Button = cap["btn"]
	if btn == null:
		return

	for c: Node in btn.get_children():
		c.queue_free()

	var rewards: Array = SaveManager.get_quick_duel_rewards(tier)
	var reward_rows: int = maxi(1, rewards.size())
	var reward_h: float = CAPSULE_REWARD_ROW_H * reward_rows

	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Transparent StyleBox — fill/border + circuit patrol from magitech panel shader.
	var sb := GameDialog.make_panel_stylebox(CAPSULE_FRAME_BORDER)
	sb.set_corner_radius_all(int(CAPSULE_FRAME_RADIUS))
	frame.add_theme_stylebox_override("panel", sb)
	btn.add_child(frame)
	_skin_capsule_frame(frame)

	var inner := Control.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(inner)
	# Stamp on plain Control (not PanelContainer) so cluster tilt is preserved.
	btn.set_meta("_exit_stamp_host", inner)

	var image_clip := Control.new()
	image_clip.name = "ImageClip"
	image_clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(image_clip)

	if entry.is_empty():
		btn.disabled = true
		image_clip.add_child(_make_capsule_fill_panel(Color(0.0, 0.0, 0.0, 1.0), CAPSULE_IMAGE_RADIUS))
	else:
		btn.disabled = false
		var tex: Texture2D = AIDeckVault.resolve_preview_texture(entry)
		if tex != null:
			var img := TextureRect.new()
			img.texture = tex
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# PanelContainer insets inner by border_width on every side, so
			# img is (CAPSULE_W - 2*border) × (CAPSULE_H - 2*border).  Pass
			# that actual size so all four arc centres land on the frame's
			# inner-border arc, not just the top-left one.
			_apply_rounded_rect_clip(img, CAPSULE_IMAGE_RADIUS,
					Vector2(CAPSULE_W - 2.0 * CAPSULE_FRAME_BORDER,
							CAPSULE_H - 2.0 * CAPSULE_FRAME_BORDER))
			image_clip.add_child(img)
		else:
			image_clip.add_child(_make_capsule_fill_panel(Color(0.0, 0.0, 0.0, 1.0), CAPSULE_IMAGE_RADIUS))

	var tier_center := CenterContainer.new()
	tier_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tier_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tier_center.z_index = 2
	inner.add_child(tier_center)

	var tier_lbl := Label.new()
	tier_lbl.text = tier.capitalize()
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier_lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 600))
	tier_lbl.add_theme_font_size_override("font_size", TIER_FONT_SIZE)
	tier_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	tier_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	tier_lbl.add_theme_constant_override("shadow_offset_x", 2)
	tier_lbl.add_theme_constant_override("shadow_offset_y", 2)
	tier_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tier_center.add_child(tier_lbl)

	var reward_back := Panel.new()
	reward_back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	reward_back.offset_top = -reward_h
	reward_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_back.z_index = 3
	var reward_sb := StyleBoxFlat.new()
	reward_sb.bg_color = Color(0.0, 0.0, 0.0, 0.42)
	reward_sb.set_content_margin_all(0)
	reward_sb.corner_radius_bottom_left = int(CAPSULE_IMAGE_RADIUS)
	reward_sb.corner_radius_bottom_right = int(CAPSULE_IMAGE_RADIUS)
	reward_back.add_theme_stylebox_override("panel", reward_sb)
	inner.add_child(reward_back)

	var reward_vbox := VBoxContainer.new()
	reward_vbox.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	reward_vbox.offset_top = -reward_h + 4.0
	reward_vbox.offset_bottom = -4.0
	reward_vbox.offset_left = 8.0
	reward_vbox.offset_right = -8.0
	reward_vbox.add_theme_constant_override("separation", 2)
	reward_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_vbox.z_index = 4
	inner.add_child(reward_vbox)

	var multi: bool = rewards.size() > 1
	for rw: Variant in rewards:
		if rw is Dictionary:
			reward_vbox.add_child(_build_reward_hint_row(rw as Dictionary, multi))

	var hover := Panel.new()
	hover.visible = false
	hover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover.z_index = 10
	var hover_sb := StyleBoxFlat.new()
	hover_sb.bg_color = HOVER_OVERLAY_COLOR
	hover_sb.set_corner_radius_all(int(CAPSULE_FRAME_RADIUS))
	hover_sb.set_content_margin_all(0)
	hover.add_theme_stylebox_override("panel", hover_sb)
	inner.add_child(hover)
	btn.set_meta("_capsule_hover", hover)

	_clear_button_hover_connections(btn)
	btn.mouse_entered.connect(_on_capsule_mouse_entered.bind(hover))
	btn.mouse_exited.connect(_on_capsule_mouse_exited.bind(hover))


func _apply_rounded_rect_clip(
		host: Control,
		corner_radius: float,
		rect_size: Vector2 = Vector2.ZERO
) -> void:
	var rc_mat := ShaderMaterial.new()
	rc_mat.shader = _ROUNDED_RECT_CLIP
	rc_mat.set_shader_parameter("corner_radius", corner_radius)
	# rect_size is used for the SDF centre calculation. The shader reads local
	# pixel position from VERTEX (not UV), so no dynamic sync is needed —
	# UV-space crop from STRETCH_KEEP_ASPECT_COVERED no longer affects clipping.
	if rect_size != Vector2.ZERO:
		rc_mat.set_shader_parameter("rect_size", rect_size)
	host.material = rc_mat


func _make_capsule_fill_panel(color: Color, corner_radius: float) -> Panel:
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = color
	fill_sb.set_corner_radius_all(int(corner_radius))
	fill_sb.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", fill_sb)
	return panel


func _clear_button_hover_connections(btn: Button) -> void:
	for conn: Dictionary in btn.mouse_entered.get_connections():
		btn.mouse_entered.disconnect(conn["callable"])
	for conn: Dictionary in btn.mouse_exited.get_connections():
		btn.mouse_exited.disconnect(conn["callable"])


func _on_capsule_mouse_entered(hover: Panel) -> void:
	if _exit_anim_running or _exit_anim_done:
		return
	if hover != null and is_instance_valid(hover):
		hover.visible = true


func _on_capsule_mouse_exited(hover: Panel) -> void:
	if hover != null and is_instance_valid(hover):
		hover.visible = false


func _build_reward_hint_row(reward: Dictionary, compact: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_size := Vector2(24, 24) if compact else Vector2(28, 28)
	var icon_path: String = QuickDuelRewards.get_reward_icon_path(reward)
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var tex: Texture2D = load(icon_path) as Texture2D
		row.add_child(_make_reward_icon_with_shadow(tex, icon_size))

	var lbl := Label.new()
	lbl.text = QuickDuelRewards.get_reward_label(reward)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.max_lines_visible = 2
	lbl.add_theme_font_size_override("font_size", 10 if compact else 11)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 1.0))
	lbl.add_theme_color_override("font_shadow_color", REWARD_SHADOW_COLOR)
	lbl.add_theme_constant_override("shadow_offset_x", int(REWARD_SHADOW_OFFSET.x))
	lbl.add_theme_constant_override("shadow_offset_y", int(REWARD_SHADOW_OFFSET.y))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lbl)
	return row


func _make_reward_icon_with_shadow(tex: Texture2D, size: Vector2) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = size
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow := TextureRect.new()
	shadow.custom_minimum_size = size
	shadow.position = REWARD_SHADOW_OFFSET
	shadow.texture = tex
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shadow.modulate = REWARD_SHADOW_COLOR
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(shadow)
	var icon := TextureRect.new()
	icon.custom_minimum_size = size
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(icon)
	return wrap


func _refresh_casual_button() -> void:
	if _casual_btn == null:
		return
	var enabled: bool = SaveManager.is_casual_mode()
	_casual_btn.text = "Casual Mode : Enabled" if enabled else "Casual Mode : Disabled"


func _refresh_reroll_button() -> void:
	if _reroll_btn == null:
		return
	var cost: int = QuickDuelRewards.get_reroll_cost()
	_reroll_btn.disabled = Collection.credits < cost
	_reroll_btn.text = "Re-roll (%d Credits)" % cost
	GameDialog.sync_button_chrome_disabled(_reroll_btn)


func _on_reroll_pressed() -> void:
	if not GameDialog.try_press(&"qd_reroll"):
		return
	var cost: int = QuickDuelRewards.get_reroll_cost()
	if Collection.credits < cost:
		_status_lbl.text = "Not enough credits (%d needed)." % cost
		return
	Collection.spend_credits(cost)
	GlobalStatManager.on_quick_duel_reroll()
	_roll_all_tier_offers()
	_refresh_picker_capsules()
	_refresh_reroll_button()
	_status_lbl.text = ""


func _open_settings() -> void:
	if get_node_or_null("SettingsMenuOverlay") != null:
		return
	var settings: Control = SettingsMenuScene.instantiate()
	settings.name = "SettingsMenuOverlay"
	settings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings.z_index = OVERLAY_Z_INDEX
	settings.mouse_filter = Control.MOUSE_FILTER_STOP
	if settings.has_signal("closed"):
		settings.closed.connect(func() -> void:
			_refresh_casual_button()
			_refresh_reroll_button())
	add_child(settings)
	settings.move_to_front()


func _apply_protagonist_to_battle() -> void:
	GameState.quick_duel_protagonist_id = SaveManager.quick_duel_protagonist_id
	while GameState.player_portraits.size() < 2:
		GameState.player_portraits.append(DEFAULT_PORTRAIT_P2)
	GameState.player_portraits[0] = SaveManager.get_protagonist_portrait_path()
	var names: Array[String] = GameState.campaign_player_names.duplicate()
	while names.size() < 2:
		names.append("")
	if names[0].strip_edges().is_empty():
		names[0] = SaveManager.get_protagonist_display_name()
	if names[1].strip_edges().is_empty():
		names[1] = "Opponent"
	GameState.campaign_player_names = names


func _apply_ai_identity_to_battle(tier: String) -> void:
	while GameState.player_portraits.size() < 2:
		GameState.player_portraits.append(DEFAULT_PORTRAIT_P2)
	# Capsule may still show an identity excluded for the current hero (e.g. after
	# switching protagonist). Re-roll for this battle only — do not rewrite offers.
	var preferred_id: String = SaveManager.get_quick_duel_identity(tier)
	var hero_id: String = SaveManager.quick_duel_protagonist_id
	var identity_id: String = AIIdentityVault.resolve_identity_for_battle(
		tier, hero_id, preferred_id)
	GameState.battle_ai_identity_id = identity_id
	var identity: Dictionary = AIIdentityVault.get_entry(identity_id)
	if identity.is_empty():
		GameState.battle_ai_identity_id = ""
		return
	var illus: String = str(identity.get("illustration", "")).strip_edges()
	if illus != "":
		GameState.player_portraits[1] = illus
	var ai_name: String = str(identity.get("name", "")).strip_edges()
	if not ai_name.is_empty():
		var names: Array[String] = GameState.campaign_player_names.duplicate()
		if names.size() < 2:
			names = [SaveManager.get_protagonist_display_name(), "Opponent"]
		names[1] = ai_name
		GameState.campaign_player_names = names


func launch_tutorial() -> void:
	if not GameDialog.try_press(&"qd_tutorial"):
		return
	var intro: String = QuickDuelRewards.get_tutorial_intro_vn()
	if intro.is_empty():
		_status_lbl.text = "Tutorial intro VN not configured."
		return
	var battle_path: String = QuickDuelRewards.find_tutorial_battle_in_vn(intro)
	if battle_path.is_empty():
		_status_lbl.text = "Tutorial intro VN has no tutorial_battle beat."
		return
	_prepare_quick_duel_tutorial_context()
	GameDialog.close_overlay(self)
	VNPlayer.launch_overlay(intro, _on_tutorial_intro_overlay_finished)


func _prepare_quick_duel_tutorial_context() -> void:
	_set_overlay_battle_return()
	GameState.quick_duel_launch = true
	GameState.quick_duel_active = false
	_apply_protagonist_to_battle()


func _set_overlay_battle_return() -> void:
	GameState.post_battle_return_scene = MAIN_MENU_SCENE
	GameState.open_quick_duel_overlay_on_menu = true
	GameState.quick_duel_overlay_active = true


func _dismiss_overlay() -> void:
	_stop_ambient_spark_fx()
	GameDialog.close_overlay(self)
	GameState.quick_duel_overlay_active = false
	closed.emit()
	queue_free()


func _exit_tree() -> void:
	_kill_hud_fade_tween()
	GameState.set_cursor_cinema_hidden(false)
	_stop_ambient_spark_fx()
	GameDialog.close_overlay(self)
	GameState.quick_duel_overlay_active = false


func _on_tutorial_intro_overlay_finished() -> void:
	# Beat with tutorial_battle starts the duel inside VNPlayer — overlay ends without _finish.
	if TutorialBattleManager.is_prepared or TutorialBattleManager.is_active:
		return
	var intro: String = QuickDuelRewards.get_tutorial_intro_vn()
	var battle_path: String = QuickDuelRewards.find_tutorial_battle_in_vn(intro)
	if battle_path.is_empty():
		return
	_begin_guided_tutorial_battle(battle_path)


func _apply_tutorial_intro_battle_display() -> void:
	var intro: String = QuickDuelRewards.get_tutorial_intro_vn()
	var beat: Dictionary = QuickDuelRewards.find_tutorial_battle_beat_in_vn(intro)
	if beat.is_empty():
		return
	var p1n: String = str(beat.get("player1_name", "")).strip_edges()
	var p2n: String = str(beat.get("player2_name", "")).strip_edges()
	if not p1n.is_empty() or not p2n.is_empty():
		var names: Array[String] = GameState.campaign_player_names.duplicate()
		while names.size() < 2:
			names.append("")
		if not p1n.is_empty():
			names[0] = p1n
		if not p2n.is_empty():
			names[1] = p2n
		GameState.campaign_player_names = names
	var p1_port: String = str(beat.get("portrait_p1", "")).strip_edges()
	if not p1_port.is_empty():
		while GameState.player_portraits.size() < 2:
			GameState.player_portraits.append(DEFAULT_PORTRAIT_P2)
		GameState.player_portraits[0] = p1_port
	var p2_port: String = str(beat.get("portrait_p2", "")).strip_edges()
	if not p2_port.is_empty():
		while GameState.player_portraits.size() < 2:
			GameState.player_portraits.append(DEFAULT_PORTRAIT_P2)
		GameState.player_portraits[1] = p2_port


func _begin_guided_tutorial_battle(battle_path: String) -> void:
	if not GameDialog.try_press(&"launch_battle"):
		return
	_prepare_quick_duel_tutorial_context()
	_apply_tutorial_intro_battle_display()
	GameState.new_game(GameState.GameMode.VS_AI)
	var err: String = TutorialBattleManager.configure_battle_from_path(battle_path, true)
	if not err.is_empty():
		push_error(err)
		return
	GameState.apply_tutorial_opponent_crystals()
	BGMManager.stop(0.0)
	CheckerTransition.fade_out_to_battle(func() -> void:
		VNPlayer.dismiss_overlay_if_present(get_tree())
		get_tree().change_scene_to_file("res://scenes/game_board.tscn"))


func launch_vault_duel(tier: String) -> void:
	_launch_vault_duel_async(tier)


func _launch_vault_duel_async(tier: String) -> void:
	if _exit_anim_running or _exit_anim_done:
		return
	if not GameDialog.try_press(&"launch_battle"):
		return
	if not SaveManager.is_active_deck_ready():
		SaveManager.show_deck_not_ready_overlay(self)
		return
	GlobalStatManager.on_first_touch("quick_duel_battle")
	var entry_id: String = SaveManager.get_quick_duel_preview(tier)
	if entry_id.is_empty():
		return
	var cfg: Dictionary = AIDeckVault.build_ai_battle_config(entry_id, 0)
	if not bool(cfg.get("ok", false)):
		_status_lbl.text = "Invalid opponent deck."
		return

	if not await _ensure_quick_duel_exit_animation(tier):
		return

	_set_overlay_battle_return()
	GameState.quick_duel_launch = false
	GameState.quick_duel_active = true
	GameState.quick_duel_battle_tier = tier

	# Abandoned tutorial battles can leave tutorial flags set and block setup formations.
	if TutorialBattleManager.is_active or TutorialBattleManager.is_prepared:
		TutorialBattleManager.stop()

	GameState.new_game(GameState.GameMode.VS_AI)
	GameState.battle_player_deck = null
	GameState.battle_player_forced_cells.clear()

	_apply_protagonist_to_battle()
	_apply_ai_identity_to_battle(tier)
	GlobalStatManager.on_duel_started({"is_quick_duel": true, "is_tutorial": false})
	if str(GameState.player_portraits[1]).strip_edges().is_empty():
		GameState.player_portraits[1] = DEFAULT_PORTRAIT_P2
	if GameState.campaign_player_names.size() < 2 \
			or str(GameState.campaign_player_names[1]).strip_edges().is_empty():
		var names: Array[String] = GameState.campaign_player_names.duplicate()
		if names.size() < 2:
			names = [SaveManager.get_protagonist_display_name(), "Opponent"]
		names[1] = str(AIDeckVault.get_entry(entry_id).get("label", "Opponent"))
		GameState.campaign_player_names = names

	AIDeckVault.apply_enemy_battle_config(cfg)
	# Identity personality must apply after deck config (which resets campaign_enemy_config).
	AIIdentityVault.apply_personality_to_battle(GameState.battle_ai_identity_id)
	GameState.battle_ai_deck = cfg.get("deck")
	GameState.battle_ai_forced_cells = (cfg.get("forced_cells", []) as Array).duplicate(true)
	GameState.battle_ai_forced_tech = (cfg.get("forced_tech", []) as Array).duplicate(true)
	GameState.battle_ai_featured_union = str(cfg.get("featured_union", "")).strip_edges()
	GameState.battle_featured_unions = ["", GameState.battle_ai_featured_union]

	BGMManager.stop(0.0)
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game_board.tscn"))


func _tick_idle_cinema(delta: float) -> void:
	if not _can_run_idle_cinema():
		_idle_timer = 0.0
		return
	if _hud_cinema:
		return
	_idle_timer += delta
	if _idle_timer >= _IDLE_HIDE_SEC:
		_set_quick_duel_hud_cinema(true)


func _can_run_idle_cinema() -> bool:
	if _exit_anim_running or _exit_anim_done:
		return false
	if _hud_layer == null or not is_instance_valid(_hud_layer):
		return false
	if _picker_panel == null or not _picker_panel.visible:
		return false
	if GameDialog.has_any_open_overlay() or GameDialog.has_open_overlay(self):
		return false
	for child: Node in get_children():
		if child == _hud_layer or child == _bg_rect or child == _fx_layer \
				or child == _flash_rect:
			continue
		if child is ProtagonistOverlay:
			return false
		# Settings / achievement overlays parented on this screen.
		if child is Control and (child as Control).visible \
				and (child as Control).mouse_filter == Control.MOUSE_FILTER_STOP \
				and (child as Control).z_index >= OVERLAY_Z_INDEX:
			return false
	return true


func _on_quick_duel_mouse_activity() -> void:
	_idle_timer = 0.0
	if _hud_cinema:
		_set_quick_duel_hud_cinema(false)


func _kill_hud_fade_tween() -> void:
	if _hud_fade_tween != null and _hud_fade_tween.is_valid():
		_hud_fade_tween.kill()
	_hud_fade_tween = null


func _force_show_quick_duel_hud() -> void:
	_idle_timer = 0.0
	_kill_hud_fade_tween()
	_hud_cinema = false
	GameState.set_cursor_cinema_hidden(false)
	if _hud_layer == null or not is_instance_valid(_hud_layer):
		return
	_hud_layer.visible = true
	_hud_layer.modulate = Color(1, 1, 1, 1)


func _set_quick_duel_hud_cinema(hide_hud: bool) -> void:
	if _hud_layer == null or not is_instance_valid(_hud_layer):
		return
	if hide_hud == _hud_cinema and _hud_fade_tween == null:
		return
	_kill_hud_fade_tween()
	_hud_cinema = hide_hud
	GameState.set_cursor_cinema_hidden(hide_hud)
	if hide_hud:
		_hud_layer.visible = true
		_hud_fade_tween = create_tween()
		_hud_fade_tween.tween_property(_hud_layer, "modulate:a", 0.0, _HUD_FADE_OUT_SEC) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_hud_fade_tween.finished.connect(func() -> void:
			_hud_fade_tween = null
			if _hud_cinema and _hud_layer != null and is_instance_valid(_hud_layer):
				_hud_layer.visible = false)
	else:
		_hud_layer.visible = true
		_hud_fade_tween = create_tween()
		_hud_fade_tween.tween_property(_hud_layer, "modulate:a", 1.0, _HUD_FADE_IN_SEC) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_hud_fade_tween.finished.connect(func() -> void:
			_hud_fade_tween = null)


func _ensure_quick_duel_exit_animation(tier: String) -> bool:
	if _exit_anim_done:
		return true
	if _exit_anim_running:
		return false
	_exit_anim_running = true
	_force_show_quick_duel_hud()
	_stop_ambient_spark_fx()

	var selected: Control = null
	var cards: Array[Control] = []
	for t: String in ["easy", "normal", "hard"]:
		var cap: Dictionary = _tier_capsules.get(t, {})
		var btn: Variant = cap.get("btn", null)
		if btn is Control and is_instance_valid(btn as Control):
			var ctrl: Control = btn as Control
			cards.append(ctrl)
			if t == tier:
				selected = ctrl

	_freeze_quick_duel_capsules_for_exit(cards)

	if _reroll_btn != null:
		_reroll_btn.disabled = true
	if _casual_btn != null:
		_casual_btn.disabled = true

	await CapsuleExitFx.play(
			self,
			selected,
			cards,
			Vector2(CAPSULE_W, CAPSULE_H),
			_stamp_id_for_quick_duel_protagonist())
	_exit_anim_done = true
	_exit_anim_running = false
	return is_inside_tree()


## Disable capsule presses/hover and keep rest size for the exit stamp sequence.
func _freeze_quick_duel_capsules_for_exit(cards: Array[Control]) -> void:
	for ctrl: Control in cards:
		if ctrl == null or not is_instance_valid(ctrl):
			continue
		ctrl.scale = Vector2.ONE
		ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ctrl is BaseButton:
			var btn: BaseButton = ctrl as BaseButton
			btn.disabled = true
			_clear_button_hover_connections(btn)
		if ctrl.has_meta("_capsule_hover"):
			var hover_v: Variant = ctrl.get_meta("_capsule_hover")
			if hover_v is Panel and is_instance_valid(hover_v as Panel):
				(hover_v as Panel).visible = false


func _stamp_id_for_quick_duel_protagonist() -> String:
	var pid: String = ProtagonistVault.normalize_id(SaveManager.quick_duel_protagonist_id)
	match pid:
		"kelly":
			return "stamp_kelly"
		"mayu":
			return "stamp_mayu"
		"nex":
			return "stamp_nex"
		_:
			return "stamp_kelly"
