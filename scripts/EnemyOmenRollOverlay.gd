extends Control
class_name EnemyOmenRollOverlay
## Hostile Omen Seal: sequential reveal after AI setup.
## Seal drops, stamps, then waits for click-to-continue so the player can
## review which Hostile Omen landed. Looping siren fades in/out with the page.

signal finished

const CIRCLE_D: float = 260.0
const SLIDE_DUR: float = 0.48
const STAMP_HOLD: float = 0.18
const BETWEEN_GAP: float = 0.22
const ARRIVAL_SHAKE_DUR: float = 0.28
const ARRIVAL_SHAKE_AMP: float = 10.0

const SFX_SIREN: AudioStream = preload("res://assets/audio/sfx/sfx_siren_1.mp3")
const SIREN_VOLUME: float = 0.60  # 60% linear peak while looping
const SIREN_SILENT_DB: float = -80.0
const SIREN_FADE_IN: float = 0.45
const SIREN_FADE_OUT: float = 0.40

## Full-screen siren washes (modulate.a pulse while siren loops).
## Use opaque ColorRect + modulate — tweening ColorRect.color.a is unreliable.
const RED_PULSE_LO: float = 0.10
const RED_PULSE_HI: float = 0.42
const BLACK_BLIND_LO: float = 0.05
const BLACK_BLIND_HI: float = 0.48

## Match coin-toss portrait / letterbox constants (GameBoard._show_coin_flip_and_start).
const REF_H: float = 720.0
const PORTRAIT_W: float = 260.0
const CONTENT_DOWN_SHIFT: float = 56.0
const COIN_FOG_BAND_H: float = 160.0
const COIN_FOG_NOISE_PATH: String = "res://assets/textures/effect/fog/Noise 3.png"
const FRAME_SAFE_MARGIN: float = 48.0
const TEXT_DISSOLVE_SHADER: Shader = preload("res://assets/shaders/text_dissolve_fade.gdshader")
const TEXT_DISSOLVE_DUR: float = 0.55

var _entries: Array = []  # [{omen, anointed_card, fly_to}]
var _enemy_portrait: Texture2D = null
var _shake_cb: Callable = Callable()
var _dim: ColorRect = null
var _red_pulse: ColorRect = null
var _black_blind: ColorRect = null
var _title: Label = null
var _anoint_lbl: Label = null
var _desc_lbl: Label = null
var _continue_lbl: Label = null
var _portrait: TextureRect = null
var _portrait_host: Control = null      # full-rect; absorbs arrival shake
var _portrait_layout: Control = null    # right-edge anchors/offsets; owns the slide
var _seal_host: Control = null
var _siren: AudioStreamPlayer = null
var _siren_fade_tw: Tween = null
var _red_pulse_tw: Tween = null
var _black_blind_tw: Tween = null
var _waiting_click: bool = false
var _click_received: bool = false
var _continue_pulse_tw: Tween = null
var _letterbox_h: float = FRAME_SAFE_MARGIN
var _portrait_target_left: float = 0.0
var _portrait_target_right: float = 0.0
var _portrait_slid_in: bool = false
var _title_shown: bool = false


static func await_roll(
		parent: Node,
		entries: Array,
		enemy_portrait: Texture2D = null,
		shake_cb: Callable = Callable()) -> void:
	if parent == null or entries.is_empty():
		return
	var overlay := EnemyOmenRollOverlay.new()
	overlay.name = "EnemyOmenRollOverlay"
	overlay._entries = entries.duplicate(true)
	overlay._enemy_portrait = enemy_portrait
	overlay._shake_cb = shake_cb
	parent.add_child(overlay)
	await overlay.finished
	if is_instance_valid(overlay):
		overlay.queue_free()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 230
	_build_chrome()
	_run_sequence()


func _gui_input(event: InputEvent) -> void:
	if not _waiting_click:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_click_received = true
			accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting_click:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_click_received = true
		accept_event()


func _viewport_size() -> Vector2:
	var vp := get_viewport()
	if vp != null:
		return vp.get_visible_rect().size
	return Vector2(1280, 720)


func _build_chrome() -> void:
	var sz: Vector2 = _viewport_size()
	size = sz
	var use_expl_bg: bool = GameState.has_exploration_battle_backdrop()
	_letterbox_h = COIN_FOG_BAND_H if use_expl_bg else FRAME_SAFE_MARGIN

	_dim = ColorRect.new()
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.08, 0.02, 0.03, 0.0)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	# Enemy illustration — same anchors / size math as coin-toss P2 portrait.
	_build_enemy_portrait_coin_toss_style()

	# Siren bulb red wash — opaque fill, visibility via modulate.a (tween-safe).
	_red_pulse = ColorRect.new()
	_red_pulse.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_red_pulse.color = Color(0.92, 0.04, 0.06, 1.0)
	_red_pulse.modulate.a = 0.0
	_red_pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_red_pulse.z_index = 14
	add_child(_red_pulse)

	# Rotating-bulb blind spot — black shadow wash across the whole stage.
	_black_blind = ColorRect.new()
	_black_blind.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black_blind.color = Color(0.0, 0.0, 0.0, 1.0)
	_black_blind.modulate.a = 0.0
	_black_blind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black_blind.z_index = 15
	add_child(_black_blind)

	# Top/bottom shadow strips — same treatment as coin-toss phase.
	_build_coin_toss_letterbox(use_expl_bg)

	var safe_top: float = _letterbox_h + 12.0
	var safe_bottom: float = sz.y - _letterbox_h
	var title_y: float = safe_top
	var continue_y: float = safe_bottom - 36.0
	var copy_y: float = clampf(sz.y * 0.62, safe_top + 220.0, continue_y - 100.0)

	_title = Label.new()
	_title.text = "A Hostile Omen Descends"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.position = Vector2(0.0, title_y)
	_title.size = Vector2(sz.x, 48.0)
	_title.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color(0.95, 0.72, 0.55, 1.0))
	_title.modulate.a = 0.0
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.z_index = 10
	add_child(_title)

	_anoint_lbl = Label.new()
	_anoint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anoint_lbl.position = Vector2(40.0, copy_y)
	_anoint_lbl.size = Vector2(sz.x - 80.0, 36.0)
	_anoint_lbl.add_theme_font_override("font", FontManager.make_font("primary", 700))
	_anoint_lbl.add_theme_font_size_override("font_size", 22)
	_anoint_lbl.add_theme_color_override("font_color", Color(0.95, 0.62, 0.42, 1.0))
	_anoint_lbl.modulate.a = 0.0
	_anoint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anoint_lbl.z_index = 10
	add_child(_anoint_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_lbl.position = Vector2(80.0, copy_y + 34.0)
	_desc_lbl.size = Vector2(sz.x - 160.0, 52.0)
	_desc_lbl.add_theme_font_override("font", FontManager.make_font("primary", 500))
	_desc_lbl.add_theme_font_size_override("font_size", 16)
	_desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.68, 0.58, 1.0))
	_desc_lbl.modulate.a = 0.0
	_desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_lbl.z_index = 10
	add_child(_desc_lbl)

	_continue_lbl = Label.new()
	_continue_lbl.text = "Click to continue"
	_continue_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_lbl.position = Vector2(0.0, continue_y)
	_continue_lbl.size = Vector2(sz.x, 28.0)
	_continue_lbl.add_theme_font_override("font", FontManager.make_font("primary", 600))
	_continue_lbl.add_theme_font_size_override("font_size", 16)
	_continue_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.68, 1.0))
	_continue_lbl.modulate.a = 0.0
	_continue_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_continue_lbl.z_index = 10
	add_child(_continue_lbl)

	_seal_host = Control.new()
	_seal_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seal_host.z_index = 2
	add_child(_seal_host)


func _build_enemy_portrait_coin_toss_style() -> void:
	var tex: Texture2D = _enemy_portrait
	if tex == null:
		tex = GameState.load_portrait_texture(GameState.player_portraits[1])
	if tex == null:
		return
	var sz: Vector2 = tex.get_size()
	var port_h: float = REF_H * maxf(0.1, GameState.portrait_p2_size)
	var pw: float = port_h * sz.x / sz.y if sz.y > 0.0 else PORTRAIT_W
	var p2ox: float = GameState.portrait_p2_offset.x
	_portrait_target_left = -pw - p2ox
	_portrait_target_right = -p2ox
	# Outer host: arrival shake via position (anchors stay intact).
	_portrait_host = Control.new()
	_portrait_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_host.z_index = 1
	add_child(_portrait_host)
	# Layout host owns the coin-toss right-edge offsets. Fog wrap must NOT steal
	# these — it reparents the TextureRect and zeros its offsets.
	_portrait_layout = Control.new()
	_portrait_layout.anchor_left = 1.0
	_portrait_layout.anchor_top = 0.0
	_portrait_layout.anchor_right = 1.0
	_portrait_layout.anchor_bottom = 1.0
	# Park fully past the right edge; slide-in restores target offsets.
	_portrait_layout.offset_left = 40.0
	_portrait_layout.offset_top = CONTENT_DOWN_SHIFT
	_portrait_layout.offset_right = pw + 40.0
	_portrait_layout.offset_bottom = CONTENT_DOWN_SHIFT
	_portrait_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_host.add_child(_portrait_layout)
	_portrait = TextureRect.new()
	_portrait.texture = tex
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.modulate = Color(1.0, 0.88, 0.84, 1.0)
	_portrait_layout.add_child(_portrait)
	var parent_n: Node = get_parent()
	if parent_n != null and parent_n.has_method("_attach_portrait_fog"):
		parent_n.call_deferred("_attach_portrait_fog", _portrait)


func _build_coin_toss_letterbox(use_expl_bg: bool) -> void:
	if use_expl_bg:
		var fog_noise: Texture2D = load(COIN_FOG_NOISE_PATH) as Texture2D
		var make_fog_band := func(is_top: bool) -> ColorRect:
			var band := ColorRect.new()
			band.anchor_left = 0.0
			band.anchor_right = 1.0
			band.offset_left = 0.0
			band.offset_right = 0.0
			if is_top:
				band.anchor_top = 0.0
				band.anchor_bottom = 0.0
				band.offset_top = 0.0
				band.offset_bottom = COIN_FOG_BAND_H
			else:
				band.anchor_top = 1.0
				band.anchor_bottom = 1.0
				band.offset_top = -COIN_FOG_BAND_H
				band.offset_bottom = 0.0
			band.color = Color(0.0, 0.0, 0.0, 0.96)
			band.mouse_filter = Control.MOUSE_FILTER_IGNORE
			band.z_index = 20
			add_child(band)
			return band

		var top_fog_band: ColorRect = make_fog_band.call(true)
		var bottom_fog_band: ColorRect = make_fog_band.call(false)
		var fog_bands: Array[ColorRect] = [top_fog_band, bottom_fog_band]
		for i: int in range(fog_bands.size()):
			var fog_band: ColorRect = fog_bands[i]
			if fog_noise == null:
				continue
			var is_top_band: bool = (i == 0)
			var fog_mat := ShaderMaterial.new()
			fog_mat.shader = preload("res://assets/shaders/capsule_fog_edge.gdshader")
			fog_mat.set_shader_parameter("rect_size", Vector2(1920.0, COIN_FOG_BAND_H))
			fog_mat.set_shader_parameter("corner_radius", 0.0)
			fog_mat.set_shader_parameter("fog_width", 72.0)
			fog_mat.set_shader_parameter("fog_strength", 1.4)
			fog_mat.set_shader_parameter("scroll", Vector2(0.42 * float(i), 0.19 * float(i)))
			fog_mat.set_shader_parameter("relief", 0.0)
			fog_mat.set_shader_parameter("use_vertex_color", 1.0)
			fog_mat.set_shader_parameter("progress", 2.0)
			fog_mat.set_shader_parameter("intensity", 0.0)
			fog_mat.set_shader_parameter("band_width", 0.20)
			fog_mat.set_shader_parameter("fog_noise", fog_noise)
			fog_mat.set_shader_parameter(
				"fog_edges",
				Color(0.0, 0.0, 0.0, 1.0) if is_top_band else Color(0.0, 0.0, 1.0, 0.0))
			fog_band.material = fog_mat
			fog_band.resized.connect(func() -> void:
				if fog_mat != null and fog_band.size.x > 1.0 and fog_band.size.y > 1.0:
					fog_mat.set_shader_parameter("rect_size", fog_band.size))
			var fog_tw := create_tween().set_loops()
			fog_tw.tween_property(
				fog_mat, "shader_parameter/scroll", Vector2(1.35, 0.62), 10.0
			).as_relative().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	else:
		var front_frame_tex: Texture2D = HudSkin.setup_phase_front_frame_tex()
		if front_frame_tex != null:
			var front_frame := TextureRect.new()
			front_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			front_frame.texture = front_frame_tex
			front_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			front_frame.stretch_mode = TextureRect.STRETCH_SCALE
			front_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			front_frame.z_index = 20
			add_child(front_frame)
		else:
			# Fallback plain strips if front frame asset missing.
			_letterbox_h = COIN_FOG_BAND_H
			for is_top: bool in [true, false]:
				var band := ColorRect.new()
				band.anchor_left = 0.0
				band.anchor_right = 1.0
				band.offset_left = 0.0
				band.offset_right = 0.0
				if is_top:
					band.anchor_top = 0.0
					band.anchor_bottom = 0.0
					band.offset_top = 0.0
					band.offset_bottom = COIN_FOG_BAND_H
				else:
					band.anchor_top = 1.0
					band.anchor_bottom = 1.0
					band.offset_top = -COIN_FOG_BAND_H
					band.offset_bottom = 0.0
				band.color = Color(0.0, 0.0, 0.0, 0.96)
				band.mouse_filter = Control.MOUSE_FILTER_IGNORE
				band.z_index = 20
				add_child(band)


func _run_sequence() -> void:
	_start_siren()
	_start_siren_washes()

	# Dim + siren only — texts wait until slide-ins finish.
	var fade := create_tween()
	fade.tween_property(_dim, "color:a", 0.82, 0.28)
	_fade_siren_to(linear_to_db(SIREN_VOLUME), SIREN_FADE_IN)
	await fade.finished

	# Portrait slides in from the right once, then shakes on arrival.
	await _slide_in_portrait()

	for entry_v: Variant in _entries:
		if not entry_v is Dictionary:
			continue
		await _play_one_seal(entry_v as Dictionary)
		await get_tree().create_timer(BETWEEN_GAP).timeout

	# Fade page + siren + washes out together on leave.
	_stop_continue_pulse()
	_stop_siren_wash_loops()
	var out := create_tween()
	out.tween_property(_dim, "color:a", 0.0, 0.25)
	out.parallel().tween_property(_red_pulse, "modulate:a", 0.0, 0.30)
	out.parallel().tween_property(_black_blind, "modulate:a", 0.0, 0.30)
	out.parallel().tween_property(_title, "modulate:a", 0.0, 0.25)
	out.parallel().tween_property(_anoint_lbl, "modulate:a", 0.0, 0.20)
	out.parallel().tween_property(_desc_lbl, "modulate:a", 0.0, 0.20)
	out.parallel().tween_property(_continue_lbl, "modulate:a", 0.0, 0.15)
	if _portrait_host != null:
		out.parallel().tween_property(_portrait_host, "modulate:a", 0.0, 0.25)
	elif _portrait != null:
		out.parallel().tween_property(_portrait, "modulate:a", 0.0, 0.25)
	_fade_siren_to(SIREN_SILENT_DB, SIREN_FADE_OUT)
	await out.finished
	if _siren_fade_tw != null and is_instance_valid(_siren_fade_tw) and _siren_fade_tw.is_running():
		await _siren_fade_tw.finished
	_stop_siren()
	finished.emit()


func _slide_in_portrait() -> void:
	if _portrait_layout == null or _portrait_slid_in:
		return
	# Ensure layout is resolved before tweening offsets (fog wrap is deferred).
	await get_tree().process_frame
	if not is_instance_valid(_portrait_layout):
		return
	var slide := create_tween()
	slide.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide.tween_property(_portrait_layout, "offset_left", _portrait_target_left, SLIDE_DUR)
	slide.parallel().tween_property(
		_portrait_layout, "offset_right", _portrait_target_right, SLIDE_DUR)
	await slide.finished
	if SFXManager != null:
		SFXManager.play(SFXManager.SFX_EXPLORATION_ITEM)  # mystery
	await _shake_control(_portrait_host if _portrait_host != null else _portrait_layout, ARRIVAL_SHAKE_AMP)
	_portrait_slid_in = true


func _shake_control(node: Control, amp: float) -> void:
	if node == null or not is_instance_valid(node):
		return
	if _shake_cb.is_valid():
		_shake_cb.call()
	var origin: Vector2 = node.position
	var shake := create_tween()
	shake.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var steps: int = 6
	var step_dur: float = ARRIVAL_SHAKE_DUR / float(steps)
	for i: int in range(steps):
		var t: float = 1.0 - float(i) / float(steps)
		var ox: float = randf_range(-amp, amp) * t
		var oy: float = randf_range(-amp * 0.55, amp * 0.55) * t
		shake.tween_property(node, "position", origin + Vector2(ox, oy), step_dur)
	shake.tween_property(node, "position", origin, step_dur)
	await shake.finished


func _play_one_seal(entry: Dictionary) -> void:
	for child: Node in _seal_host.get_children():
		child.queue_free()
	_anoint_lbl.modulate.a = 0.0
	_desc_lbl.modulate.a = 0.0
	_continue_lbl.modulate.a = 0.0
	_stop_continue_pulse()

	var omen: Dictionary = entry.get("omen", {}) as Dictionary
	if omen.is_empty():
		return

	var omen_label: String = str(omen.get("label", omen.get("id", "Hostile Omen"))).strip_edges()
	var omen_desc: String = str(omen.get("description", "")).strip_edges()
	_anoint_lbl.text = omen_label
	_desc_lbl.text = omen_desc

	var box: float = CIRCLE_D + OmenVisuals.GLOW_PAD * 2.0
	var capsule: Control = OmenVisuals.build_capsule(omen, CIRCLE_D, OmenVisuals.GLOW_PAD, true)
	# Hostile ash-crimson tint over the cool capsule chrome.
	capsule.modulate = Color(1.15, 0.72, 0.58, 1.0)
	capsule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seal_host.add_child(capsule)

	var sz: Vector2 = _viewport_size()
	# Center seal in the letterboxed safe area (same top/bottom margins as coin toss).
	var safe_mid_y: float = lerpf(_letterbox_h, sz.y - _letterbox_h, 0.42)
	var center: Vector2 = Vector2(sz.x * 0.5 - box * 0.5, safe_mid_y - box * 0.5)
	capsule.pivot_offset = Vector2(box * 0.5, box * 0.5)
	capsule.scale = Vector2.ONE
	# Start fully past the left edge; slide in horizontally.
	capsule.position = Vector2(-box - 48.0, center.y)

	var slide := create_tween()
	slide.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide.tween_property(capsule, "position", center, SLIDE_DUR)
	await slide.finished
	if SFXManager != null:
		SFXManager.play(SFXManager.SFX_STAMP, SFXManager.SFX_STAMP_VOLUME)  # approval stamp
	await _shake_control(capsule, ARRIVAL_SHAKE_AMP)
	await get_tree().create_timer(STAMP_HOLD).timeout

	# Texts only after portrait + capsule slide/shake — noise dissolve fade-in.
	var copy_labels: Array[Control] = []
	if not _title_shown:
		copy_labels.append(_title)
		_title_shown = true
	copy_labels.append(_anoint_lbl)
	if not omen_desc.is_empty():
		copy_labels.append(_desc_lbl)
	await _dissolve_fade_in_labels(copy_labels, TEXT_DISSOLVE_DUR)

	await _await_click_to_continue()

	_clear_text_dissolve(_anoint_lbl)
	_clear_text_dissolve(_desc_lbl)
	var fade := create_tween()
	fade.tween_property(capsule, "modulate:a", 0.0, 0.28)
	fade.parallel().tween_property(_anoint_lbl, "modulate:a", 0.0, 0.20)
	fade.parallel().tween_property(_desc_lbl, "modulate:a", 0.0, 0.20)
	await fade.finished

	if is_instance_valid(capsule):
		capsule.queue_free()


func _await_click_to_continue() -> void:
	_click_received = false
	_waiting_click = true
	await _dissolve_fade_in_labels([_continue_lbl], TEXT_DISSOLVE_DUR * 0.85)
	_start_continue_pulse()
	while is_instance_valid(self) and not _click_received:
		await get_tree().process_frame
	_waiting_click = false
	_stop_continue_pulse()
	if SFXManager != null:
		SFXManager.play(SFXManager.SFX_BTN, 0.7)
	_clear_text_dissolve(_continue_lbl)
	var hide := create_tween()
	hide.tween_property(_continue_lbl, "modulate:a", 0.0, 0.12)
	await hide.finished


func _dissolve_fade_in_labels(labels: Array, dur: float) -> void:
	var fog_noise: Texture2D = load(COIN_FOG_NOISE_PATH) as Texture2D
	var mats: Array[ShaderMaterial] = []
	for item: Variant in labels:
		if item == null or not (item is CanvasItem):
			continue
		var node: CanvasItem = item as CanvasItem
		if not is_instance_valid(node):
			continue
		node.modulate.a = 1.0
		var mat := ShaderMaterial.new()
		mat.shader = TEXT_DISSOLVE_SHADER
		if fog_noise != null:
			mat.set_shader_parameter("fog_noise", fog_noise)
		mat.set_shader_parameter("progress", 0.0)
		mat.set_shader_parameter("softness", 0.24)
		mat.set_shader_parameter("noise_scale", randf_range(2.6, 4.2))
		mat.set_shader_parameter("noise_scroll", Vector2(randf_range(0.0, 3.0), randf_range(0.0, 3.0)))
		node.material = mat
		mats.append(mat)
	if mats.is_empty():
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for mat: ShaderMaterial in mats:
		var hold: Array = [mat]
		tw.tween_method(
			func(v: float) -> void:
				var m: Variant = hold[0]
				if m is ShaderMaterial:
					(m as ShaderMaterial).set_shader_parameter("progress", v),
			0.0, 1.0, dur
		)
	await tw.finished
	# Leave material at progress=1 so glyphs stay solid; pulse may still tween modulate.


func _clear_text_dissolve(node: CanvasItem) -> void:
	if node != null and is_instance_valid(node):
		node.material = null


func _start_continue_pulse() -> void:
	_stop_continue_pulse()
	if _continue_lbl == null:
		return
	# Drop dissolve material so alpha pulse isn't fighting the shader mask.
	_clear_text_dissolve(_continue_lbl)
	_continue_lbl.modulate.a = 0.95
	_continue_pulse_tw = create_tween()
	_continue_pulse_tw.set_loops()
	_continue_pulse_tw.tween_property(_continue_lbl, "modulate:a", 0.45, 0.55)
	_continue_pulse_tw.tween_property(_continue_lbl, "modulate:a", 0.95, 0.55)


func _stop_continue_pulse() -> void:
	if _continue_pulse_tw != null and is_instance_valid(_continue_pulse_tw):
		_continue_pulse_tw.kill()
	_continue_pulse_tw = null


func _start_siren() -> void:
	_stop_siren()
	if SFX_SIREN == null:
		return
	_siren = AudioStreamPlayer.new()
	_siren.name = "HostileOmenSiren"
	var looped: AudioStream = SFX_SIREN.duplicate()
	if looped is AudioStreamMP3:
		(looped as AudioStreamMP3).loop = true
	elif looped is AudioStreamOggVorbis:
		(looped as AudioStreamOggVorbis).loop = true
	_siren.stream = looped
	_siren.bus = "SFX"
	_siren.volume_db = SIREN_SILENT_DB
	add_child(_siren)
	_siren.play()


func _start_siren_washes() -> void:
	_stop_siren_wash_loops()
	if _red_pulse == null or _black_blind == null:
		return
	_red_pulse.modulate.a = 0.0
	_black_blind.modulate.a = 0.0

	# Alarm red pulse — slow siren wash (full cycle ~2.6s).
	_red_pulse_tw = create_tween()
	_red_pulse_tw.set_loops()
	_red_pulse_tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_red_pulse_tw.tween_property(_red_pulse, "modulate:a", RED_PULSE_HI, 1.30)
	_red_pulse_tw.tween_property(_red_pulse, "modulate:a", RED_PULSE_LO, 1.30)

	# Blind-spot black — slower, offset so it reads as a separate bulb shadow.
	_black_blind_tw = create_tween()
	_black_blind_tw.set_loops()
	_black_blind_tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_black_blind_tw.tween_interval(0.35)
	_black_blind_tw.tween_property(_black_blind, "modulate:a", BLACK_BLIND_HI, 0.85)
	_black_blind_tw.tween_property(_black_blind, "modulate:a", BLACK_BLIND_LO, 1.05)


func _stop_siren_wash_loops() -> void:
	if _red_pulse_tw != null and is_instance_valid(_red_pulse_tw):
		_red_pulse_tw.kill()
	_red_pulse_tw = null
	if _black_blind_tw != null and is_instance_valid(_black_blind_tw):
		_black_blind_tw.kill()
	_black_blind_tw = null


func _fade_siren_to(target_db: float, dur: float) -> void:
	if _siren == null or not is_instance_valid(_siren):
		return
	if _siren_fade_tw != null and is_instance_valid(_siren_fade_tw):
		_siren_fade_tw.kill()
	_siren_fade_tw = create_tween()
	_siren_fade_tw.tween_property(_siren, "volume_db", target_db, dur)


func _stop_siren() -> void:
	_stop_siren_wash_loops()
	if _siren_fade_tw != null and is_instance_valid(_siren_fade_tw):
		_siren_fade_tw.kill()
	_siren_fade_tw = null
	if _siren != null and is_instance_valid(_siren):
		_siren.stop()
		_siren.queue_free()
	_siren = null


func _exit_tree() -> void:
	_waiting_click = false
	_stop_continue_pulse()
	_stop_siren_wash_loops()
	_stop_siren()
