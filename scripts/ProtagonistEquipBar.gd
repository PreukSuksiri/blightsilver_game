extends Control
## One rounded capsule with three diagonal protagonist segments (single-pass shader).
## Emits equip_requested(protagonist_id) when an unlocked, non-Limited segment is pressed.

signal equip_requested(protagonist_id: String)

const PROTAGONIST_IDS: Array[String] = ["nex", "mayu", "kelly"]
const EYES_PATH := "res://assets/textures/profile/eyes/eyes_%s.png"
const EYES_LOCKED_PATH := "res://assets/textures/profile/eyes/eyes_%s_locked.png"
const _BAR_SHADER := preload("res://assets/shaders/diagonal_capsule_bar.gdshader")

const BAR_H := 56.0
const HINT_GAP := 4.0
const DIAGONAL_DEGREES := 60.0
const FRAME_WHITE := Color(1.0, 1.0, 1.0, 1.0)
const FRAME_WHITE_EQUIPPED := Color(1.0, 1.0, 1.0, 1.0)
const FRAME_WIDTH := 2.5
const DIVIDER_PX := 3.5
const CORNER_RADIUS := 8.0
## Nudge labels toward each diagonal slice's visual center (left / middle / right).
const LABEL_X_BIAS := [-8.0, 0.0, 8.0]

const SHEEN_IDLE := 2.0
const SHEEN_DURATION := 0.42
const UNEQUIPPED_DESATURATE := 0.45
const UNEQUIPPED_SEPIA_MIX := 0.55
const UNEQUIPPED_SEPIA := Color(0.78, 0.64, 0.42, 1.0)
const UNEQUIPPED_FILL := Color(0.58, 0.50, 0.38, 1.0)

## When false, only the character sheet is shown (e.g. save-equip dialog).
var show_hint: bool = true

var _bar_host: Control = null
var _surface: ColorRect = null
var _mat: ShaderMaterial = null
var _equipped_lbl: Dictionary = {}  # id -> Label
var _name_chip: Dictionary = {}  # id -> Label
var _hover_ok: Dictionary = {}  # id -> bool
var _interactive: Dictionary = {}  # id -> bool (unlocked and not limited)
var _sheen_tweens: Dictionary = {}  # pid -> Tween
var _hover_seg: int = -1
var _open_deck_id: String = ""
var _fallback_tex: Texture2D = null


func _ready() -> void:
	custom_minimum_size = Vector2(0, BAR_H + (20.0 + HINT_GAP if show_hint else 0.0))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", int(HINT_GAP) if show_hint else 0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	if show_hint:
		var hint := Label.new()
		hint.text = "Tap on character below to equip this deck"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		FontManager.tag_font(hint, "font", "primary", 500)
		hint.add_theme_font_size_override("font_size", 13)
		hint.add_theme_color_override("font_color", Color(0.72, 0.80, 0.95, 0.92))
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(hint)

	_bar_host = Control.new()
	_bar_host.custom_minimum_size = Vector2(0, BAR_H)
	_bar_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bar_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_bar_host.clip_contents = false
	_bar_host.gui_input.connect(_on_bar_gui_input)
	_bar_host.mouse_exited.connect(_on_bar_mouse_exited)
	root.add_child(_bar_host)

	_surface = ColorRect.new()
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.color = Color.WHITE
	_mat = ShaderMaterial.new()
	_mat.shader = _BAR_SHADER
	_mat.set_shader_parameter("corner_radius", CORNER_RADIUS)
	_mat.set_shader_parameter("frame_width", FRAME_WIDTH)
	_mat.set_shader_parameter("divider_px", DIVIDER_PX)
	_mat.set_shader_parameter("diagonal_degrees", DIAGONAL_DEGREES)
	_mat.set_shader_parameter("frame_color", FRAME_WHITE)
	_mat.set_shader_parameter("rim_speed", 0.40)
	_mat.set_shader_parameter("rim_pulse", 0.68)
	_mat.set_shader_parameter("circuit_patrol", 1.0)
	_mat.set_shader_parameter("sepia_color", UNEQUIPPED_SEPIA)
	_mat.set_shader_parameter("sheen_band", 0.22)
	_mat.set_shader_parameter("sheen_intensity", 1.25)
	_mat.set_shader_parameter("sheen_color", Color(1.0, 0.96, 0.82, 1.0))
	_mat.set_shader_parameter("bevel_strength", 0.55)
	_surface.material = _mat
	_bar_host.add_child(_surface)

	for i in range(PROTAGONIST_IDS.size()):
		var pid: String = PROTAGONIST_IDS[i]
		var eq := Label.new()
		eq.text = "Equipped"
		_layout_segment_label(eq, i)
		_style_segment_label(eq, 16, 700)
		eq.visible = false
		_bar_host.add_child(eq)
		_equipped_lbl[pid] = eq

		var name_chip := Label.new()
		name_chip.text = "Unequipped"
		_layout_segment_label(name_chip, i)
		_style_segment_label(name_chip, 14, 600)
		_bar_host.add_child(name_chip)
		_name_chip[pid] = name_chip

		_hover_ok[pid] = false
		_interactive[pid] = false
		_set_segment_art(pid, false)
		_clear_look(i)

	_bar_host.resized.connect(_sync_shader_sizes)
	resized.connect(_sync_shader_sizes)
	call_deferred("_sync_shader_sizes")
	refresh(_open_deck_id)


func _layout_segment_label(lbl: Label, role: int) -> void:
	var bias: float = LABEL_X_BIAS[clampi(role, 0, LABEL_X_BIAS.size() - 1)]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.anchor_left = float(role) / 3.0
	lbl.anchor_right = float(role + 1) / 3.0
	lbl.offset_left = bias
	lbl.offset_right = -bias
	lbl.offset_top = 0.0
	lbl.offset_bottom = 0.0


func _style_segment_label(lbl: Label, font_size: int, weight: int) -> void:
	FontManager.tag_font(lbl, "font", "primary", weight)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.modulate = Color(1, 1, 1, 1)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _fallback_texture() -> Texture2D:
	if _fallback_tex != null:
		return _fallback_tex
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_fallback_tex = ImageTexture.create_from_image(img)
	return _fallback_tex


func _load_eyes_texture(pid: String, locked: bool) -> Texture2D:
	var path: String = (EYES_LOCKED_PATH if locked else EYES_PATH) % pid
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if locked:
		var normal: String = EYES_PATH % pid
		if ResourceLoader.exists(normal):
			return load(normal) as Texture2D
	return _fallback_texture()


func _role_of(pid: String) -> int:
	return PROTAGONIST_IDS.find(pid)


func _suffix(role: int) -> String:
	return str(role)


func _set_segment_art(pid: String, locked: bool) -> void:
	if _mat == null:
		return
	var role: int = _role_of(pid)
	if role < 0:
		return
	var tex: Texture2D = _load_eyes_texture(pid, locked)
	var s: String = _suffix(role)
	_mat.set_shader_parameter("tex" + s, tex)
	var sz: Vector2 = tex.get_size() if tex != null else Vector2(4, 4)
	_mat.set_shader_parameter("tex_size" + s, sz)


func _clear_look(role: int) -> void:
	if _mat == null:
		return
	var s: String = _suffix(role)
	_mat.set_shader_parameter("desaturate" + s, 0.0)
	_mat.set_shader_parameter("sepia_mix" + s, 0.0)
	_mat.set_shader_parameter("sheen_progress" + s, SHEEN_IDLE)
	_mat.set_shader_parameter("fill_color" + s, Color.WHITE)
	_mat.set_shader_parameter("tint" + s, Color.WHITE)
	_mat.set_shader_parameter("edge_glow" + s, 0.0)


func _apply_unequipped_look(role: int) -> void:
	if _mat == null:
		return
	var s: String = _suffix(role)
	_mat.set_shader_parameter("tint" + s, Color(0.92, 0.88, 0.78, 1.0))
	_mat.set_shader_parameter("fill_color" + s, UNEQUIPPED_FILL)
	_mat.set_shader_parameter("desaturate" + s, UNEQUIPPED_DESATURATE)
	_mat.set_shader_parameter("sepia_mix" + s, UNEQUIPPED_SEPIA_MIX)
	_mat.set_shader_parameter("edge_glow" + s, 0.0)
	_mat.set_shader_parameter("sheen_progress" + s, SHEEN_IDLE)


func _sync_shader_sizes() -> void:
	if _bar_host == null or _mat == null:
		return
	var bar_w: float = _bar_host.size.x
	var bar_h: float = maxf(_bar_host.size.y, BAR_H)
	if bar_w < 2.0:
		return
	_mat.set_shader_parameter("bar_size", Vector2(bar_w, bar_h))
	_mat.set_shader_parameter("corner_radius", CORNER_RADIUS)
	_mat.set_shader_parameter("frame_width", FRAME_WIDTH)
	_mat.set_shader_parameter("divider_px", DIVIDER_PX)
	_mat.set_shader_parameter("diagonal_degrees", DIAGONAL_DEGREES)


func _cut_x(third: float, y: float, full: Vector2) -> float:
	var rad: float = deg_to_rad(DIAGONAL_DEGREES)
	var dx_per_dy: float = cos(rad) / maxf(sin(rad), 0.001)
	var slant: float = dx_per_dy * (full.y * 0.5 - y)
	return full.x * third + slant


func _segment_at(local_pos: Vector2) -> int:
	if _bar_host == null:
		return -1
	var full := Vector2(_bar_host.size.x, maxf(_bar_host.size.y, BAR_H))
	if full.x < 2.0 or full.y < 2.0:
		return -1
	if local_pos.x < 0.0 or local_pos.y < 0.0 or local_pos.x > full.x or local_pos.y > full.y:
		return -1
	# Reject outside rounded rect (same half extents as shader).
	var half := full * 0.5 - Vector2(0.5, 0.5)
	var r: float = minf(CORNER_RADIUS, minf(half.x, half.y))
	var p := local_pos - full * 0.5
	var q := Vector2(absf(p.x), absf(p.y)) - half + Vector2(r, r)
	var box_d: float = Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() \
			+ minf(maxf(q.x, q.y), 0.0) - r
	if box_d > 0.5:
		return -1
	var cut1: float = _cut_x(1.0 / 3.0, local_pos.y, full)
	var cut2: float = _cut_x(2.0 / 3.0, local_pos.y, full)
	if local_pos.x < cut1:
		return 0
	if local_pos.x < cut2:
		return 1
	return 2


func set_open_deck_id(deck_id: String) -> void:
	_open_deck_id = deck_id.strip_edges()
	refresh(_open_deck_id)


func refresh(open_deck_id: String = "") -> void:
	if not open_deck_id.is_empty():
		_open_deck_id = open_deck_id
	if _mat == null:
		return

	var any_equipped: bool = false
	for pid: String in PROTAGONIST_IDS:
		var equipped: DeckData = SaveManager.get_equipped_deck(pid)
		if equipped != null and equipped.deck_id == _open_deck_id and not _open_deck_id.is_empty():
			any_equipped = true
			break

	_mat.set_shader_parameter(
		"frame_color",
		FRAME_WHITE_EQUIPPED if any_equipped else FRAME_WHITE)

	for pid: String in PROTAGONIST_IDS:
		var role: int = _role_of(pid)
		var eq: Label = _equipped_lbl.get(pid) as Label
		var name_chip: Label = _name_chip.get(pid) as Label
		if role < 0:
			continue
		var unlocked: bool = SaveManager.is_protagonist_unlocked(pid)
		var limited: bool = SaveManager.is_protagonist_limited(pid)
		var equipped_deck: DeckData = SaveManager.get_equipped_deck(pid)
		var is_on: bool = equipped_deck != null \
				and equipped_deck.deck_id == _open_deck_id \
				and not _open_deck_id.is_empty()
		var hover_ok: bool = false
		var interactive: bool = false

		if not unlocked:
			_kill_sheen(pid)
			_clear_look(role)
			_set_segment_art(pid, true)
			if eq:
				eq.visible = false
			if name_chip:
				name_chip.text = "Locked"
				name_chip.visible = true
				_layout_segment_label(name_chip, role)
		elif limited:
			_kill_sheen(pid)
			_clear_look(role)
			_set_segment_art(pid, false)
			var s: String = _suffix(role)
			_mat.set_shader_parameter(
				"tint" + s,
				Color(0.7, 0.7, 0.72, 1.0) if is_on else Color(0.55, 0.55, 0.58, 1.0))
			_mat.set_shader_parameter("edge_glow" + s, 0.35 if is_on else 0.0)
			if eq:
				eq.visible = is_on
				if is_on:
					_layout_segment_label(eq, role)
			if name_chip:
				name_chip.text = "Unequipped" if not is_on else ProtagonistVault.get_display_name(pid)
				name_chip.visible = not is_on
				if not is_on:
					_layout_segment_label(name_chip, role)
		elif is_on:
			_kill_sheen(pid)
			_clear_look(role)
			_set_segment_art(pid, false)
			_mat.set_shader_parameter("tint" + _suffix(role), Color.WHITE)
			_mat.set_shader_parameter("edge_glow" + _suffix(role), 1.0)
			if eq:
				eq.visible = true
				_layout_segment_label(eq, role)
			if name_chip:
				name_chip.visible = false
		else:
			_set_segment_art(pid, false)
			_apply_unequipped_look(role)
			if eq:
				eq.visible = false
			if name_chip:
				name_chip.text = "Unequipped"
				name_chip.visible = true
				_layout_segment_label(name_chip, role)
			hover_ok = true
			interactive = true

		_hover_ok[pid] = hover_ok
		_interactive[pid] = interactive

	_sync_shader_sizes()
	_update_cursor_for_seg(_hover_seg)


func _pid_at_seg(seg: int) -> String:
	if seg < 0 or seg >= PROTAGONIST_IDS.size():
		return ""
	return PROTAGONIST_IDS[seg]


func _tooltip_for(pid: String) -> String:
	if pid.is_empty():
		return ""
	if not SaveManager.is_protagonist_unlocked(pid):
		return "Locked"
	if SaveManager.is_protagonist_limited(pid):
		return "Limited deck — cannot reassign"
	var equipped_deck: DeckData = SaveManager.get_equipped_deck(pid)
	if equipped_deck != null and equipped_deck.deck_id == _open_deck_id and not _open_deck_id.is_empty():
		return "Equipped"
	return "Tap to equip this deck"


func _update_cursor_for_seg(seg: int) -> void:
	if _bar_host == null:
		return
	var pid: String = _pid_at_seg(seg)
	if pid.is_empty():
		_bar_host.mouse_default_cursor_shape = Control.CURSOR_ARROW
		_bar_host.tooltip_text = ""
		return
	_bar_host.tooltip_text = _tooltip_for(pid)
	if bool(_interactive.get(pid, false)):
		_bar_host.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		_bar_host.mouse_default_cursor_shape = Control.CURSOR_ARROW


func _set_hover_seg(seg: int) -> void:
	if seg == _hover_seg:
		return
	var prev_pid: String = _pid_at_seg(_hover_seg)
	if not prev_pid.is_empty():
		_on_segment_hover_exited(prev_pid)
	_hover_seg = seg
	_update_cursor_for_seg(seg)
	var pid: String = _pid_at_seg(seg)
	if not pid.is_empty():
		_on_segment_hover_entered(pid)


func _on_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		_set_hover_seg(_segment_at(motion.position))
	elif event is InputEventMouseButton:
		var btn := event as InputEventMouseButton
		if btn.pressed and btn.button_index == MOUSE_BUTTON_LEFT:
			var seg: int = _segment_at(btn.position)
			var pid: String = _pid_at_seg(seg)
			if not pid.is_empty():
				_on_pressed(pid)
			_bar_host.accept_event()


func _on_bar_mouse_exited() -> void:
	_set_hover_seg(-1)


func _on_segment_hover_entered(pid: String) -> void:
	if not bool(_hover_ok.get(pid, false)):
		return
	_play_metal_sheen(pid)


func _on_segment_hover_exited(pid: String) -> void:
	_kill_sheen(pid)
	var role: int = _role_of(pid)
	if role >= 0 and _mat != null:
		_mat.set_shader_parameter("sheen_progress" + _suffix(role), SHEEN_IDLE)


func _kill_sheen(pid: String) -> void:
	if not _sheen_tweens.has(pid):
		return
	var old: Variant = _sheen_tweens[pid]
	_sheen_tweens.erase(pid)
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()


func _play_metal_sheen(pid: String) -> void:
	if _mat == null:
		return
	var role: int = _role_of(pid)
	if role < 0:
		return
	_kill_sheen(pid)
	var key: String = "sheen_progress" + _suffix(role)
	_mat.set_shader_parameter(key, -0.15)
	var hold_mat: ShaderMaterial = _mat
	var hold_key: String = key
	var hold_pid: String = pid
	var tw := create_tween()
	_sheen_tweens[pid] = tw
	tw.tween_method(
		func(v: float) -> void:
			if hold_mat != null:
				hold_mat.set_shader_parameter(hold_key, v),
		-0.15, 1.15, SHEEN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		if hold_mat != null:
			hold_mat.set_shader_parameter(hold_key, SHEEN_IDLE)
		_sheen_tweens.erase(hold_pid))


func _on_pressed(pid: String) -> void:
	if not SaveManager.is_protagonist_unlocked(pid):
		return
	if SaveManager.is_protagonist_limited(pid):
		return
	equip_requested.emit(pid)


func _exit_tree() -> void:
	for pid: String in PROTAGONIST_IDS:
		_kill_sheen(pid)
