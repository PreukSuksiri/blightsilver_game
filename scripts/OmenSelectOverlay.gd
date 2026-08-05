extends Control
class_name OmenSelectOverlay
## Full-bleed pick-1-of-N omen overlay — circular capsules, reverse-dissolve intro,
## shake / shatter / fly-to-Info selection cinematic.
##
## Host (ExplorationPlayer) is a bare Control with no anchors, so this overlay
## sizes itself from the viewport instead of using a full-rect preset.

signal selected(omen: Dictionary)

const _SHADER_CAPSULE: Shader = preload("res://assets/shaders/omen_capsule.gdshader")
const _SHADER_CIRCLE_ART: Shader = preload("res://assets/shaders/omen_circle_art.gdshader")
const _SHADER_FOG_PUFF: Shader = preload("res://assets/shaders/omen_fog_puff.gdshader")
const _SHADER_SHADOW_FOG: Shader = preload("res://assets/shaders/omen_shadow_fog.gdshader")
const _SFX_SHATTER: AudioStream = preload("res://assets/audio/sfx/ceramic.mp3")
## Same noise stack the campaign gallery capsules use.
const _FOG_NOISE_PATH: String = "res://assets/textures/effect/fog/Noise 3.png"
const _FOG_SCROLL_SPEED: Vector2 = Vector2(0.075, 0.038)
const _SHADOW_SCROLL_A: Vector2 = Vector2(0.021, -0.034)
const _SHADOW_SCROLL_B: Vector2 = Vector2(-0.028, -0.017)
## Shadow pool diameter, as a multiple of the capsule box.
const SHADOW_FOG_SPAN: float = 2.0

const CIRCLE_D_MAX: float = 300.0
const CIRCLE_D_MIN: float = 170.0
const GLOW_PAD: float = 26.0
const CAPSULE_GAP: float = 26.0
const SIDE_MARGIN: float = 44.0
const TITLE_TOP: float = 34.0
const TITLE_H: float = 46.0
const WARNING_H: float = 60.0
const WARNING_BOTTOM: float = 26.0

const HOVER_SCALE: float = 1.09
const HOVER_SCALE_DUR: float = 0.13
const PICK_SCALE: float = 1.14
const CONDENSE_DUR: float = 0.95
const REVEAL_STAGGER: float = 0.30
const SHEEN_IDLE: float = 2.0
const SHAKE_DUR: float = 0.75
const SHAKE_AMP: float = 7.0
const FLY_DUR: float = 0.55
const FLY_SCALE: float = 0.34
const DOCK_SCALE: float = 0.12

const WARNING_TEXT: String = (
	"Omens remain in effect until the chapter ends. Multiple Omens can be accumulated."
)

var _omens: Array = []
var _input_unlocked: bool = false
var _picked: bool = false

var _dim: ColorRect = null
var _title: Label = null
var _warning: Label = null
var _row: HBoxContainer = null
var _row_host: Control = null
var _card_wrappers: Array = []

var _hover_tweens: Dictionary = {}
var _sheen_tweens: Dictionary = {}
var _host_chrome_locked: bool = false
var _shake_active: bool = false
var _fog_noise: Texture2D = null
var _fog_scroll: Vector2 = Vector2.ZERO
var _fog_mats: Array[ShaderMaterial] = []
var _shadow_layer: Control = null
var _shadow_fogs: Array[Control] = []
var _shadow_mats: Array[ShaderMaterial] = []
var _shadow_scroll_a: Vector2 = Vector2.ZERO
var _shadow_scroll_b: Vector2 = Vector2.ZERO
var _wrapper_home_pos: Dictionary = {}
var _info_hit_prev_filter: int = int(Control.MOUSE_FILTER_STOP)
var _info_hit_prev_disabled: bool = false

var _circle_d: float = CIRCLE_D_MAX
var _box: float = CIRCLE_D_MAX + GLOW_PAD * 2.0


static func await_selection(parent: Node, omens: Array) -> Dictionary:
	if parent == null or omens.is_empty():
		return {}
	var overlay := OmenSelectOverlay.new()
	overlay.name = "OmenSelectOverlay"
	overlay._omens = omens.duplicate(true)
	parent.add_child(overlay)
	var chosen: Variant = await overlay.selected
	if is_instance_valid(overlay):
		overlay.queue_free()
	if chosen is Dictionary:
		return chosen as Dictionary
	return {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = _viewport_size()
	z_index = 220
	mouse_filter = Control.MOUSE_FILTER_STOP
	_lock_host_chrome(true)
	SFXManager.play(SFXManager.SFX_EXPLORATION_ITEM)

	if ResourceLoader.exists(_FOG_NOISE_PATH):
		_fog_noise = load(_FOG_NOISE_PATH) as Texture2D
	_compute_metrics()

	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.02, 0.05, 0.0)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_title = Label.new()
	_title.text = "An Omen Reveals Itself" if _omens.size() == 1 else "Choose an Omen"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0, 1.0))
	_title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_title.add_theme_constant_override("shadow_offset_x", 0)
	_title.add_theme_constant_override("shadow_offset_y", 2)
	_title.add_theme_constant_override("shadow_outline_size", 6)
	_title.modulate.a = 0.0
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)

	# Shadow pools share one layer beneath the row; per-capsule children would
	# let a neighbour's fog draw over the previous capsule.
	_shadow_layer = Control.new()
	_shadow_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shadow_layer)

	_row_host = Control.new()
	_row_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row_host)

	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", int(CAPSULE_GAP))
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row_host.add_child(_row)

	for omen: Variant in _omens:
		if not omen is Dictionary:
			continue
		_row.add_child(_build_capsule(omen as Dictionary))

	_warning = Label.new()
	_warning.text = WARNING_TEXT
	_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warning.add_theme_font_override("font", FontManager.make_font("primary", 400))
	_warning.add_theme_font_size_override("font_size", 16)
	_warning.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	_warning.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_warning.add_theme_constant_override("shadow_offset_x", 0)
	_warning.add_theme_constant_override("shadow_offset_y", 2)
	_warning.add_theme_constant_override("shadow_outline_size", 5)
	_warning.modulate.a = 0.0
	_warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_warning)

	_relayout()
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.size_changed.connect(_relayout)

	call_deferred("_play_intro")


func _exit_tree() -> void:
	_lock_host_chrome(false)


func _process(delta: float) -> void:
	if not _fog_mats.is_empty():
		_fog_scroll += _FOG_SCROLL_SPEED * delta
		for mat: ShaderMaterial in _fog_mats:
			if mat != null:
				mat.set_shader_parameter("fog_scroll", _fog_scroll)
	if not _shadow_mats.is_empty():
		_shadow_scroll_a += _SHADOW_SCROLL_A * delta
		_shadow_scroll_b += _SHADOW_SCROLL_B * delta
		for mat: ShaderMaterial in _shadow_mats:
			if mat != null:
				mat.set_shader_parameter("scroll_a", _shadow_scroll_a)
				mat.set_shader_parameter("scroll_b", _shadow_scroll_b)


func _viewport_size() -> Vector2:
	var vp: Vector2 = get_viewport_rect().size
	if vp.x < 2.0 or vp.y < 2.0:
		vp = Vector2(1280.0, 720.0)
	return vp


## Capsule diameter adapts to viewport so three circles always fit and stay centred.
func _compute_metrics() -> void:
	var vp: Vector2 = _viewport_size()
	var count: int = maxi(1, _omens.size())
	var avail_w: float = vp.x - SIDE_MARGIN * 2.0 - CAPSULE_GAP * float(count - 1)
	var per_box: float = avail_w / float(count)
	var by_width: float = per_box - GLOW_PAD * 2.0
	var by_height: float = vp.y - (TITLE_TOP + TITLE_H) - (WARNING_H + WARNING_BOTTOM) \
			- GLOW_PAD * 2.0 - 24.0
	_circle_d = clampf(minf(by_width, by_height), CIRCLE_D_MIN, CIRCLE_D_MAX)
	_box = _circle_d + GLOW_PAD * 2.0


func _relayout() -> void:
	position = Vector2.ZERO
	size = _viewport_size()
	var vp: Vector2 = size
	if _dim != null:
		_dim.position = Vector2.ZERO
		_dim.size = vp
	if _title != null:
		_title.position = Vector2(0.0, TITLE_TOP)
		_title.size = Vector2(vp.x, TITLE_H)
	if _warning != null:
		_warning.position = Vector2(SIDE_MARGIN, vp.y - WARNING_BOTTOM - WARNING_H)
		_warning.size = Vector2(maxf(vp.x - SIDE_MARGIN * 2.0, 80.0), WARNING_H)
	if _row_host != null and _row != null:
		var band_top: float = TITLE_TOP + TITLE_H
		var band_h: float = maxf(vp.y - band_top - (WARNING_H + WARNING_BOTTOM), _box)
		_row_host.position = Vector2(0.0, band_top)
		_row_host.size = Vector2(vp.x, band_h)
		var row_w: float = float(_card_wrappers.size()) * _box \
				+ CAPSULE_GAP * float(maxi(_card_wrappers.size() - 1, 0))
		_row.position = Vector2((vp.x - row_w) * 0.5, (band_h - _box) * 0.5)
		_row.size = Vector2(row_w, _box)
	for w: Control in _card_wrappers:
		if w != null and is_instance_valid(w):
			w.pivot_offset = w.size * 0.5
	if _shadow_layer != null:
		_shadow_layer.position = Vector2.ZERO
		_shadow_layer.size = vp
		_sync_shadow_fog_positions()


func _sync_shadow_fog_positions() -> void:
	for i: int in range(mini(_shadow_fogs.size(), _card_wrappers.size())):
		var fog: Control = _shadow_fogs[i]
		var wrapper: Control = _card_wrappers[i]
		if fog == null or not is_instance_valid(fog):
			continue
		if wrapper == null or not is_instance_valid(wrapper):
			continue
		fog.global_position = wrapper.get_global_rect().get_center() - fog.size * 0.5


func _lock_host_chrome(lock: bool) -> void:
	if lock == _host_chrome_locked:
		return
	_host_chrome_locked = lock
	var host: Node = get_parent()
	if host == null:
		return
	if host.has_method("_compass_set_visible"):
		host.call("_compass_set_visible", not lock)
	for prop_name: String in [
		"_inv_icon", "_inv_hit", "_setting_icon", "_setting_hit",
		"_info_icon", "_info_hit", "_chat_icon", "_chat_hit",
	]:
		var node: Variant = host.get(prop_name)
		if node is CanvasItem:
			(node as CanvasItem).visible = not lock
	if host.has_method("_set_spots_layer_visible"):
		host.call("_set_spots_layer_visible", not lock)
	if lock:
		if host.has_method("_close_compass_menu"):
			host.call("_close_compass_menu", false)
		if host.has_method("_close_setting_menu"):
			host.call("_close_setting_menu", false)
		if host.has_method("_close_inventory_menu"):
			host.call("_close_inventory_menu", false)
		if host.has_method("_close_chat_menu"):
			host.call("_close_chat_menu", false)
		if host.has_method("_close_info_panel"):
			host.call("_close_info_panel")
	else:
		_restore_info_hit_interaction()


## Reveal the Info HUD only — visible, but not yet interactive.
func _reveal_info_hud_locked() -> void:
	var host: Node = get_parent()
	if host == null:
		return
	var info_icon: CanvasItem = host.get("_info_icon") as CanvasItem
	var info_hit: BaseButton = host.get("_info_hit") as BaseButton
	if info_icon != null:
		info_icon.visible = true
		info_icon.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(info_icon, "modulate:a", 1.0, 0.22) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if info_hit != null:
		_info_hit_prev_filter = int(info_hit.mouse_filter)
		_info_hit_prev_disabled = info_hit.disabled
		info_hit.visible = true
		info_hit.disabled = true
		info_hit.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _restore_info_hit_interaction() -> void:
	var host: Node = get_parent()
	if host == null:
		return
	var info_hit: BaseButton = host.get("_info_hit") as BaseButton
	if info_hit == null:
		return
	info_hit.disabled = _info_hit_prev_disabled
	info_hit.mouse_filter = _info_hit_prev_filter as Control.MouseFilter


func _get_info_hud_global_center() -> Vector2:
	var host: Node = get_parent()
	if host != null:
		var info_icon: Control = host.get("_info_icon") as Control
		if info_icon != null and is_instance_valid(info_icon) and info_icon.visible:
			return info_icon.get_global_rect().get_center()
	var vp: Vector2 = _viewport_size()
	return Vector2(vp.x * 0.5 + 120.0, vp.y - 88.0)


# ─────────────────────────────────────────────────────────────
# Capsule construction
# ─────────────────────────────────────────────────────────────

func _build_capsule(omen: Dictionary) -> Control:
	var d: float = _circle_d
	var ring: Color = OmenVisuals.ring_color(omen)

	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(_box, _box)
	wrapper.size = Vector2(_box, _box)
	wrapper.pivot_offset = Vector2(_box * 0.5, _box * 0.5)
	wrapper.mouse_filter = Control.MOUSE_FILTER_STOP
	wrapper.scale = Vector2(0.94, 0.94)
	wrapper.set_meta("omen", omen)
	wrapper.set_meta("sheen_armed", true)
	wrapper.set_meta("ring_color", ring)
	_card_wrappers.append(wrapper)
	_shadow_fogs.append(_build_shadow_fog())

	# Disc chrome (fill gradient + ring + patrol + sheen + halo).
	var chrome := ColorRect.new()
	chrome.color = Color(1, 1, 1, 1)
	chrome.position = Vector2.ZERO
	chrome.size = Vector2(_box, _box)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chrome_mat := ShaderMaterial.new()
	chrome_mat.shader = _SHADER_CAPSULE
	chrome_mat.set_shader_parameter("rect_size", Vector2(_box, _box))
	chrome_mat.set_shader_parameter("radius_px", d * 0.5)
	chrome_mat.set_shader_parameter("ring_a", ring)
	chrome_mat.set_shader_parameter("ring_b", ring.lightened(0.55))
	chrome_mat.set_shader_parameter("ring_px", maxf(3.0, d * 0.013))
	chrome_mat.set_shader_parameter("inner_bezel_gap", maxf(7.0, d * 0.032))
	chrome_mat.set_shader_parameter("glow_px", GLOW_PAD * 0.9)
	chrome_mat.set_shader_parameter("glow_strength", 0.40)
	chrome_mat.set_shader_parameter("sheen_progress", SHEEN_IDLE)
	var positive: Variant = omen.get("positive", null)
	var inner := Color(0.11, 0.14, 0.22, 0.98)
	var outer := Color(0.02, 0.03, 0.06, 0.98)
	if positive != null:
		if bool(positive):
			inner = Color(0.09, 0.19, 0.17, 0.98)
			outer = Color(0.02, 0.05, 0.06, 0.98)
		else:
			inner = Color(0.20, 0.10, 0.13, 0.98)
			outer = Color(0.06, 0.02, 0.04, 0.98)
	chrome_mat.set_shader_parameter("fill_inner", inner)
	chrome_mat.set_shader_parameter("fill_outer", outer)
	wrapper.set_meta("fill_inner", inner)
	wrapper.set_meta("fill_outer", outer)
	_arm_fog(chrome_mat)
	chrome.material = chrome_mat
	wrapper.add_child(chrome)
	wrapper.set_meta("chrome_mat", chrome_mat)

	# Top-half illustration, masked to the semicircle and faded at the equator.
	var art := TextureRect.new()
	art.position = Vector2(GLOW_PAD, GLOW_PAD)
	art.size = Vector2(d, d * 0.5)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_mat := ShaderMaterial.new()
	art_mat.shader = _SHADER_CIRCLE_ART
	art_mat.set_shader_parameter("art_size", Vector2(d, d * 0.5))
	art_mat.set_shader_parameter("edge_inset_px", maxf(5.0, d * 0.026))
	art_mat.set_shader_parameter("bottom_fade_px", d * 0.14)
	art_mat.set_shader_parameter("placeholder_color", ring.darkened(0.55))
	art_mat.set_shader_parameter("tint_color", ring)
	var illus_path: String = str(omen.get("illustration", "")).strip_edges()
	if not illus_path.is_empty() and ResourceLoader.exists(illus_path):
		art.texture = load(illus_path) as Texture2D
		art_mat.set_shader_parameter("use_texture", 1.0)
	else:
		art.texture = OmenVisuals.make_placeholder_art_tex(ring)
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art_mat.set_shader_parameter("use_texture", 1.0)
		art_mat.set_shader_parameter("tint_strength", 0.10)
	_arm_fog(art_mat)
	art.material = art_mat
	wrapper.add_child(art)
	wrapper.set_meta("art_mat", art_mat)

	# Text condenses in after the disc, so it lives on its own fade layer.
	# Rarity is a subtle ★ row under the effect — never a chip on the disc.
	var text_host := Control.new()
	text_host.position = Vector2.ZERO
	text_host.size = Vector2(_box, _box)
	text_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_host.modulate = Color(1.0, 1.0, 1.0, 0.0)
	wrapper.add_child(text_host)
	wrapper.set_meta("text_host", text_host)

	var label := Label.new()
	label.text = str(omen.get("label", omen.get("id", "Omen")))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.position = Vector2(GLOW_PAD + d * 0.14, GLOW_PAD + d * 0.52)
	label.size = Vector2(d * 0.72, d * 0.11)
	label.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	label.add_theme_font_size_override("font_size", maxi(int(d * 0.070), 14))
	label.add_theme_color_override("font_color", ring.lightened(0.42))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_host.add_child(label)

	var desc := Label.new()
	desc.text = str(omen.get("description", ""))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(GLOW_PAD + d * 0.16, GLOW_PAD + d * 0.635)
	desc.size = Vector2(d * 0.68, d * 0.20)
	desc.add_theme_font_override("font", FontManager.make_font("primary", 400))
	desc.add_theme_font_size_override("font_size", maxi(int(d * 0.046), 11))
	desc.add_theme_color_override("font_color", Color(0.84, 0.89, 0.96, 0.95))
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_host.add_child(desc)

	var stars: Control = OmenVisuals.build_rarity_stars(omen, maxi(int(d * 0.055), 12))
	stars.position = Vector2(GLOW_PAD + d * 0.20, GLOW_PAD + d * 0.855)
	stars.size = Vector2(d * 0.60, d * 0.08)
	text_host.add_child(stars)

	var hit := Button.new()
	hit.position = Vector2.ZERO
	hit.size = Vector2(_box, _box)
	hit.focus_mode = Control.FOCUS_NONE
	hit.flat = true
	var empty := StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		hit.add_theme_stylebox_override(state, empty)
	hit.pressed.connect(func() -> void:
		_on_card_pressed(wrapper, omen))
	hit.mouse_entered.connect(func() -> void:
		_on_card_hover_enter(wrapper))
	hit.mouse_exited.connect(func() -> void:
		_on_card_hover_exit(wrapper))
	wrapper.add_child(hit)

	return wrapper


## Evil shadow pool that churns behind a capsule for the life of the overlay.
func _build_shadow_fog() -> Control:
	var span: float = _box * SHADOW_FOG_SPAN
	var fog := TextureRect.new()
	fog.texture = _fog_noise
	fog.stretch_mode = TextureRect.STRETCH_SCALE
	fog.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog.size = Vector2(span, span)
	fog.pivot_offset = Vector2(span, span) * 0.5
	fog.modulate.a = 0.0
	var mat := ShaderMaterial.new()
	mat.shader = _SHADER_SHADOW_FOG
	if _fog_noise != null:
		mat.set_shader_parameter("fog_noise", _fog_noise)
	mat.set_shader_parameter("scale_a", randf_range(1.0, 1.35))
	mat.set_shader_parameter("scale_b", randf_range(0.55, 0.80))
	mat.set_shader_parameter("density", randf_range(1.05, 1.35))
	fog.material = mat
	_shadow_mats.append(mat)
	if _shadow_layer != null:
		_shadow_layer.add_child(fog)
	return fog


# ─────────────────────────────────────────────────────────────
# Intro
# ─────────────────────────────────────────────────────────────

func _play_intro() -> void:
	await get_tree().process_frame
	_relayout()

	var fade: Tween = create_tween()
	fade.set_parallel(true)
	fade.tween_property(_dim, "color:a", 0.80, 0.30) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	fade.tween_property(_title, "modulate:a", 1.0, 0.35) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	fade.tween_property(_warning, "modulate:a", 1.0, 0.45).set_delay(0.15) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await fade.finished

	for i: int in range(_card_wrappers.size()):
		_play_fog_condense_in(_card_wrappers[i] as Control)
		if i < _card_wrappers.size() - 1:
			await get_tree().create_timer(REVEAL_STAGGER).timeout
	await get_tree().create_timer(CONDENSE_DUR + 0.2).timeout

	# Capsules are solid now; the noise scroll no longer affects anything.
	_fog_mats.clear()
	_input_unlocked = true


## Arms a capsule material for the fog condensation and registers it for scrolling.
func _arm_fog(mat: ShaderMaterial) -> void:
	if mat == null:
		return
	if _fog_noise != null:
		mat.set_shader_parameter("fog_noise", _fog_noise)
	mat.set_shader_parameter("fog_scroll", _fog_scroll)
	mat.set_shader_parameter("materialize", 0.0)
	_fog_mats.append(mat)


## Chemical dissolve, played backwards: the capsule condenses out of drifting
## vapour in random blotches instead of appearing all at once.
func _play_fog_condense_in(wrapper: Control) -> void:
	if wrapper == null or not is_instance_valid(wrapper):
		return
	var ring: Color = wrapper.get_meta("ring_color", Color(0.7, 0.8, 0.95)) as Color
	var chrome_mat: ShaderMaterial = wrapper.get_meta("chrome_mat", null) as ShaderMaterial
	var art_mat: ShaderMaterial = wrapper.get_meta("art_mat", null) as ShaderMaterial
	var text_host: Control = wrapper.get_meta("text_host", null) as Control

	_spawn_fog_puffs(wrapper.get_global_rect().get_center(), ring)

	var tw: Tween = create_tween()
	tw.set_parallel(true)
	var idx: int = _card_wrappers.find(wrapper)
	if idx >= 0 and idx < _shadow_fogs.size():
		var fog: Control = _shadow_fogs[idx]
		if fog != null and is_instance_valid(fog):
			tw.tween_property(fog, "modulate:a", 1.0, CONDENSE_DUR * 1.15) \
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if chrome_mat != null:
		_tween_materialize(tw, chrome_mat, CONDENSE_DUR)
	if art_mat != null:
		_tween_materialize(tw, art_mat, CONDENSE_DUR * 0.92)
	tw.tween_property(wrapper, "scale", Vector2.ONE, CONDENSE_DUR) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if text_host != null:
		tw.tween_property(text_host, "modulate:a", 1.0, CONDENSE_DUR * 0.45) \
				.set_delay(CONDENSE_DUR * 0.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	_play_metal_sheen(wrapper)


func _tween_materialize(tw: Tween, mat: ShaderMaterial, dur: float) -> void:
	var hold: Array = [mat]
	tw.tween_method(
		func(v: float) -> void:
			var m: Variant = hold[0]
			if m is ShaderMaterial:
				(m as ShaderMaterial).set_shader_parameter("materialize", v),
		0.0, 1.0, dur
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Soft smoke that rolls over the capsule while it condenses, then thins out.
func _spawn_fog_puffs(center: Vector2, ring: Color) -> void:
	if _fog_noise == null:
		return
	const PUFF_COUNT: int = 8
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = 4
	add_child(layer)

	for i: int in range(PUFF_COUNT):
		var span: float = _box * randf_range(0.42, 0.78)
		var puff := TextureRect.new()
		puff.texture = _fog_noise
		puff.stretch_mode = TextureRect.STRETCH_SCALE
		puff.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		puff.mouse_filter = Control.MOUSE_FILTER_IGNORE
		puff.size = Vector2(span, span)
		puff.pivot_offset = Vector2(span, span) * 0.5
		puff.rotation = randf_range(-PI, PI)
		puff.modulate.a = 0.0
		var mat := ShaderMaterial.new()
		mat.shader = _SHADER_FOG_PUFF
		mat.set_shader_parameter("fog_noise", _fog_noise)
		mat.set_shader_parameter("noise_offset",
			Vector2(randf_range(0.0, 4.0), randf_range(0.0, 4.0)))
		mat.set_shader_parameter("noise_scale", randf_range(0.6, 1.4))
		mat.set_shader_parameter("tint", ring.lightened(0.35).lerp(
			Color(0.82, 0.86, 0.94, 1.0), 0.55))
		mat.set_shader_parameter("density", randf_range(0.7, 1.15))
		puff.material = mat
		layer.add_child(puff)

		var from_off := Vector2(randf_range(-0.20, 0.20), randf_range(-0.16, 0.16)) * _box
		var drift := Vector2(randf_range(-0.20, 0.20), randf_range(-0.26, -0.02)) * _box
		puff.global_position = center - puff.size * 0.5 + from_off

		var delay: float = randf_range(0.0, 0.16)
		var life: float = CONDENSE_DUR * randf_range(0.85, 1.15)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(puff, "modulate:a", randf_range(0.26, 0.46), life * 0.30) \
				.set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(puff, "modulate:a", 0.0, life * 0.55) \
				.set_delay(delay + life * 0.38) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(puff, "global_position",
				puff.global_position + drift, life + delay) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(puff, "scale", Vector2.ONE * randf_range(1.12, 1.38),
				life + delay) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(puff, "rotation",
				puff.rotation + randf_range(-0.7, 0.7), life + delay) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(CONDENSE_DUR * 1.6).timeout
	if is_instance_valid(layer):
		layer.queue_free()


# ─────────────────────────────────────────────────────────────
# Hover
# ─────────────────────────────────────────────────────────────

func _on_card_hover_enter(wrapper: Control) -> void:
	if not _input_unlocked or _picked:
		return
	_kill_hover_tween(wrapper)
	wrapper.pivot_offset = wrapper.size * 0.5
	var tw: Tween = create_tween()
	_hover_tweens[wrapper.get_instance_id()] = tw
	tw.tween_property(wrapper, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), HOVER_SCALE_DUR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if bool(wrapper.get_meta("sheen_armed", true)):
		wrapper.set_meta("sheen_armed", false)
		_play_metal_sheen(wrapper)


func _on_card_hover_exit(wrapper: Control) -> void:
	if not _input_unlocked or _picked:
		return
	_kill_hover_tween(wrapper)
	wrapper.set_meta("sheen_armed", true)
	var tw: Tween = create_tween()
	_hover_tweens[wrapper.get_instance_id()] = tw
	tw.tween_property(wrapper, "scale", Vector2.ONE, HOVER_SCALE_DUR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _play_metal_sheen(wrapper: Control) -> void:
	if wrapper == null or not is_instance_valid(wrapper):
		return
	var mat: ShaderMaterial = wrapper.get_meta("chrome_mat", null) as ShaderMaterial
	if mat == null:
		return
	var id: int = wrapper.get_instance_id()
	if _sheen_tweens.has(id):
		var old: Tween = _sheen_tweens[id] as Tween
		if old != null and old.is_valid():
			old.kill()
	mat.set_shader_parameter("sheen_progress", -0.2)
	var tw := create_tween()
	_sheen_tweens[id] = tw
	tw.tween_method(
		func(v: float) -> void:
			if is_instance_valid(mat):
				mat.set_shader_parameter("sheen_progress", v),
		-0.2, 1.25, 0.42) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		if is_instance_valid(mat):
			mat.set_shader_parameter("sheen_progress", SHEEN_IDLE))


func _kill_hover_tween(wrapper: Control) -> void:
	var id: int = wrapper.get_instance_id()
	if _hover_tweens.has(id):
		var old: Tween = _hover_tweens[id] as Tween
		if old != null and old.is_valid():
			old.kill()
		_hover_tweens.erase(id)


# ─────────────────────────────────────────────────────────────
# Selection cinematic
# ─────────────────────────────────────────────────────────────

func _on_card_pressed(wrapper: Control, omen: Dictionary) -> void:
	if not _input_unlocked or _picked:
		return
	_picked = true
	_input_unlocked = false

	for w: Control in _card_wrappers:
		_kill_hover_tween(w)
		w.pivot_offset = w.size * 0.5
		w.scale = Vector2.ONE

	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_fade_out_shadow_fog()

	var pick_tw := create_tween()
	pick_tw.tween_property(wrapper, "scale", Vector2(PICK_SCALE, PICK_SCALE), 0.10) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pick_tw.tween_property(wrapper, "scale", Vector2.ONE, 0.08) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await pick_tw.finished

	_begin_shake_all()
	await get_tree().create_timer(SHAKE_DUR * 0.45).timeout
	await _shatter_unselected(wrapper)
	_stop_shake_all()

	_reveal_info_hud_locked()
	await get_tree().create_timer(0.18).timeout

	await _fly_selected_to_info(wrapper)

	var outro := create_tween()
	outro.set_parallel(true)
	if _title != null:
		outro.tween_property(_title, "modulate:a", 0.0, 0.20)
	if _warning != null:
		outro.tween_property(_warning, "modulate:a", 0.0, 0.20)
	if _dim != null:
		outro.tween_property(_dim, "color:a", 0.0, 0.28)
	await outro.finished

	_lock_host_chrome(false)
	selected.emit(omen.duplicate(true))
	queue_free()


func _fade_out_shadow_fog() -> void:
	if _shadow_fogs.is_empty():
		return
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	for fog: Control in _shadow_fogs:
		if fog != null and is_instance_valid(fog):
			tw.tween_property(fog, "modulate:a", 0.0, 0.55) \
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.finished.connect(func() -> void:
		_shadow_mats.clear())


func _begin_shake_all() -> void:
	_shake_active = true
	_wrapper_home_pos.clear()
	for w: Control in _card_wrappers:
		if w != null and is_instance_valid(w):
			_wrapper_home_pos[w.get_instance_id()] = w.position
	_run_shake_loop()


func _run_shake_loop() -> void:
	while _shake_active and is_inside_tree():
		for w: Control in _card_wrappers:
			if w == null or not is_instance_valid(w) or not w.visible:
				continue
			var home: Vector2 = _wrapper_home_pos.get(
				w.get_instance_id(), w.position) as Vector2
			w.position = home + Vector2(
				randf_range(-SHAKE_AMP, SHAKE_AMP),
				randf_range(-SHAKE_AMP, SHAKE_AMP))
		await get_tree().create_timer(0.035).timeout


func _stop_shake_all() -> void:
	_shake_active = false
	for w: Control in _card_wrappers:
		if w == null or not is_instance_valid(w):
			continue
		var id: int = w.get_instance_id()
		if _wrapper_home_pos.has(id):
			w.position = _wrapper_home_pos[id] as Vector2


func _shatter_unselected(keep: Control) -> void:
	var targets: Array = []
	for w: Control in _card_wrappers:
		if w != null and is_instance_valid(w) and w != keep and w.visible:
			targets.append(w)
	if targets.is_empty():
		await get_tree().process_frame
		return

	SFXManager.play(_SFX_SHATTER)
	var remaining: Array = [targets.size()]
	for w: Control in targets:
		_shatter_one(w, remaining)
	while int(remaining[0]) > 0:
		await get_tree().process_frame


func _shatter_one(wrapper: Control, remaining: Array) -> void:
	if wrapper == null or not is_instance_valid(wrapper):
		remaining[0] = int(remaining[0]) - 1
		return
	var ring: Color = wrapper.get_meta("ring_color", Color(0.6, 0.65, 0.75)) as Color
	var tex: Texture2D = _make_shatter_tex(
		ring,
		wrapper.get_meta("fill_inner", Color(0.11, 0.14, 0.22)) as Color,
		wrapper.get_meta("fill_outer", Color(0.02, 0.03, 0.06)) as Color)
	var gr: Rect2 = wrapper.get_global_rect()
	var local_rect := Rect2(gr.position - global_position, gr.size)
	_wrapper_home_pos[wrapper.get_instance_id()] = wrapper.position
	await PackShatterFx.shatter_texture(self, tex, local_rect, 3, wrapper)
	if is_instance_valid(wrapper):
		wrapper.visible = false
		wrapper.modulate.a = 0.0
	remaining[0] = int(remaining[0]) - 1


## Disc-shaped shard source: art gradient over the dark body, bright rim on the
## rarity ring, so fragments read as pieces of the capsule they came from.
func _make_shatter_tex(ring: Color, fill_inner: Color, fill_outer: Color) -> Texture2D:
	const N: int = 160
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(N * 0.5, N * 0.5)
	var radius: float = N * 0.5 - 1.0
	var art_top: Color = ring.lightened(0.18).darkened(0.34)
	var art_bottom: Color = ring.darkened(0.74)
	for y: int in range(N):
		var v: float = float(y) / float(N - 1)
		var row_col: Color
		if v < 0.5:
			row_col = art_top.lerp(art_bottom, pow(v * 2.0, 0.75))
		else:
			row_col = fill_inner.lerp(fill_outer, (v - 0.5) * 2.0)
		for x: int in range(N):
			var offset := Vector2(float(x) + 0.5, float(y) + 0.5) - center
			var dist: float = offset.length()
			if dist > radius:
				continue
			var c: Color = row_col
			c = c.darkened(smoothstep(radius * 0.70, radius, dist) * 0.35)
			if dist > radius - 3.5:
				c = ring.lightened(0.40)
			c.a = clampf((radius - dist) / 2.5, 0.0, 1.0)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _fly_selected_to_info(wrapper: Control) -> void:
	if wrapper == null or not is_instance_valid(wrapper):
		return

	# Flyer keeps the capsule centred on its own origin so scale + move stay aligned.
	var start_center: Vector2 = wrapper.get_global_rect().get_center()
	var flyer := Control.new()
	flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flyer.z_index = 20
	add_child(flyer)
	flyer.global_position = start_center

	var parent_node: Node = wrapper.get_parent()
	if parent_node != null:
		parent_node.remove_child(wrapper)
	flyer.add_child(wrapper)
	wrapper.pivot_offset = wrapper.size * 0.5
	wrapper.position = -wrapper.size * 0.5
	wrapper.scale = Vector2.ONE
	wrapper.modulate.a = 1.0

	var target_center: Vector2 = _get_info_hud_global_center()

	var fly := create_tween()
	fly.set_parallel(true)
	fly.tween_property(flyer, "global_position", target_center, FLY_DUR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	fly.tween_property(wrapper, "scale", Vector2(FLY_SCALE, FLY_SCALE), FLY_DUR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await fly.finished

	var dock := create_tween()
	dock.set_parallel(true)
	dock.tween_property(wrapper, "scale", Vector2(DOCK_SCALE, DOCK_SCALE), 0.18) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	dock.tween_property(wrapper, "modulate:a", 0.0, 0.20)
	await dock.finished

	if is_instance_valid(flyer):
		flyer.queue_free()
	elif is_instance_valid(wrapper):
		wrapper.queue_free()
