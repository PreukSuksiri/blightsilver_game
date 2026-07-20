extends Control
## One long rounded-rectangle sheet with three diagonal protagonist segments.
## Emits equip_requested(protagonist_id) when an unlocked, non-Limited segment is pressed.

signal equip_requested(protagonist_id: String)

const PROTAGONIST_IDS: Array[String] = ["nex", "mayu", "kelly"]
const EYES_PATH := "res://assets/textures/profile/eyes/eyes_%s.png"
const _SHEET_SHADER := preload("res://assets/shaders/diagonal_capsule_segment.gdshader")

const BAR_H := 56.0
const OVERLAP := 20.0  # horizontal overlap so diagonal cuts meet cleanly
const FRAME_CYAN := Color(0.15, 0.92, 0.95, 1.0)
const FRAME_CYAN_EQUIPPED := Color(0.35, 1.0, 1.0, 1.0)
const FRAME_WIDTH := 2.0

var _row: HBoxContainer = null
var _buttons: Dictionary = {}  # id -> Button
var _art: Dictionary = {}  # id -> TextureRect
var _mats: Dictionary = {}  # id -> ShaderMaterial
var _equipped_lbl: Dictionary = {}  # id -> Label
var _open_deck_id: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(0, BAR_H)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false

	_row = HBoxContainer.new()
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row.add_theme_constant_override("separation", -int(OVERLAP))
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)

	for i in range(PROTAGONIST_IDS.size()):
		_row.add_child(_make_segment(PROTAGONIST_IDS[i], i))

	resized.connect(_sync_shader_sizes)
	call_deferred("_sync_shader_sizes")
	refresh(_open_deck_id)


func _make_segment(pid: String, role: int) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, BAR_H)
	btn.clip_contents = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_transparent_button(btn)

	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var eyes: String = EYES_PATH % pid
	if ResourceLoader.exists(eyes):
		art.texture = load(eyes) as Texture2D
	else:
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		art.texture = ImageTexture.create_from_image(img)

	var mat := ShaderMaterial.new()
	mat.shader = _SHEET_SHADER
	mat.set_shader_parameter("role", role)
	mat.set_shader_parameter("diagonal_degrees", 70.0)
	mat.set_shader_parameter("gap", 0.10)
	mat.set_shader_parameter("corner_radius", 8.0)
	mat.set_shader_parameter("fill_color", Color.WHITE)
	mat.set_shader_parameter("tint", Color.WHITE)
	mat.set_shader_parameter("frame_color", FRAME_CYAN)
	mat.set_shader_parameter("frame_width", FRAME_WIDTH)
	mat.set_shader_parameter("edge_glow", 0.0)
	art.material = mat
	btn.add_child(art)

	var eq := Label.new()
	eq.text = "Equipped"
	eq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eq.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	eq.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	FontManager.tag_font(eq, "font", "primary", 700)
	eq.add_theme_font_size_override("font_size", 13)
	eq.add_theme_color_override("font_color", Color(0.12, 0.14, 0.2, 1.0))
	eq.add_theme_color_override("font_outline_color", Color(1, 1, 1, 1))
	eq.add_theme_constant_override("outline_size", 3)
	eq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eq.visible = false
	btn.add_child(eq)

	var name_chip := Label.new()
	name_chip.text = ProtagonistVault.get_display_name(pid)
	name_chip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_chip.offset_top = -20.0
	name_chip.offset_bottom = -2.0
	name_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.tag_font(name_chip, "font", "primary", 600)
	name_chip.add_theme_font_size_override("font_size", 11)
	name_chip.add_theme_color_override("font_color", Color(0.15, 0.18, 0.25, 1.0))
	name_chip.add_theme_color_override("font_outline_color", Color(1, 1, 1, 1))
	name_chip.add_theme_constant_override("outline_size", 3)
	name_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_chip)

	var captured: String = pid
	btn.pressed.connect(func() -> void: _on_pressed(captured))
	_buttons[pid] = btn
	_art[pid] = art
	_mats[pid] = mat
	_equipped_lbl[pid] = eq
	btn.set_meta("name_chip", name_chip)
	btn.set_meta("role", role)
	return btn


func _apply_transparent_button(btn: Button) -> void:
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_stylebox_override("disabled", empty)


func _sync_shader_sizes() -> void:
	if _row == null:
		return
	var bar_w: float = size.x
	var bar_h: float = maxf(size.y, BAR_H)
	if bar_w < 2.0:
		return
	var bar_size := Vector2(bar_w, bar_h)
	for pid: String in PROTAGONIST_IDS:
		var btn: Button = _buttons.get(pid) as Button
		var mat: ShaderMaterial = _mats.get(pid) as ShaderMaterial
		if btn == null or mat == null:
			continue
		var seg_w: float = btn.size.x
		if seg_w < 2.0:
			seg_w = bar_w / 3.0 + OVERLAP * 0.66
		mat.set_shader_parameter("rect_size", Vector2(seg_w, bar_h))
		mat.set_shader_parameter("bar_size", bar_size)
		mat.set_shader_parameter("corner_radius", 8.0)
		# Local X of this segment inside the full rounded-rect sheet.
		mat.set_shader_parameter("segment_x", btn.position.x)


func set_open_deck_id(deck_id: String) -> void:
	_open_deck_id = deck_id.strip_edges()
	refresh(_open_deck_id)


func refresh(open_deck_id: String = "") -> void:
	if not open_deck_id.is_empty():
		_open_deck_id = open_deck_id

	var any_equipped: bool = false
	for pid: String in PROTAGONIST_IDS:
		var equipped: DeckData = SaveManager.get_equipped_deck(pid)
		if equipped != null and equipped.deck_id == _open_deck_id and not _open_deck_id.is_empty():
			any_equipped = true
			break

	for pid: String in PROTAGONIST_IDS:
		var btn: Button = _buttons.get(pid) as Button
		var mat: ShaderMaterial = _mats.get(pid) as ShaderMaterial
		var eq: Label = _equipped_lbl.get(pid) as Label
		if btn == null or mat == null:
			continue
		var unlocked: bool = SaveManager.is_protagonist_unlocked(pid)
		var limited: bool = SaveManager.is_protagonist_limited(pid)
		var equipped_deck: DeckData = SaveManager.get_equipped_deck(pid)
		var is_on: bool = equipped_deck != null \
				and equipped_deck.deck_id == _open_deck_id \
				and not _open_deck_id.is_empty()
		btn.disabled = (not unlocked) or limited
		var name_chip: Label = btn.get_meta("name_chip") as Label

		mat.set_shader_parameter("fill_color", Color.WHITE)
		mat.set_shader_parameter(
			"frame_color",
			FRAME_CYAN_EQUIPPED if any_equipped else FRAME_CYAN)
		mat.set_shader_parameter("frame_width", FRAME_WIDTH)

		if not unlocked:
			# Pitch black — no recognizable face detail on locked heroes.
			mat.set_shader_parameter("tint", Color(0, 0, 0, 1.0))
			mat.set_shader_parameter("edge_glow", 0.0)
			eq.visible = false
			if name_chip:
				name_chip.text = "Locked"
				name_chip.visible = true
				name_chip.modulate = Color(0.45, 0.48, 0.55, 1)
			btn.tooltip_text = "Locked"
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		elif limited:
			mat.set_shader_parameter("tint", Color(0.7, 0.7, 0.72, 1.0) if is_on else Color(0.55, 0.55, 0.58, 1.0))
			mat.set_shader_parameter("edge_glow", 0.35 if is_on else 0.0)
			eq.visible = is_on
			if name_chip:
				name_chip.text = ProtagonistVault.get_display_name(pid)
				name_chip.visible = not is_on
				name_chip.modulate = Color(0.2, 0.22, 0.28, 1)
			btn.tooltip_text = "Limited deck — cannot reassign"
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		elif is_on:
			mat.set_shader_parameter("tint", Color.WHITE)
			mat.set_shader_parameter("edge_glow", 1.0)
			eq.visible = true
			if name_chip:
				name_chip.visible = false
			btn.tooltip_text = "Equipped"
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		else:
			mat.set_shader_parameter("tint", Color(0.72, 0.74, 0.78, 1.0))
			mat.set_shader_parameter("edge_glow", 0.0)
			eq.visible = false
			if name_chip:
				name_chip.text = ProtagonistVault.get_display_name(pid)
				name_chip.visible = true
				name_chip.modulate = Color(0.18, 0.2, 0.28, 1)
			btn.tooltip_text = "Tap to equip this deck"
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_sync_shader_sizes()


func _on_pressed(pid: String) -> void:
	if not SaveManager.is_protagonist_unlocked(pid):
		return
	if SaveManager.is_protagonist_limited(pid):
		return
	equip_requested.emit(pid)
