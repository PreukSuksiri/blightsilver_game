extends Control
class_name CampaignGallery

const GALLERY_DATA_PATH := "res://campaign/gallery_data.json"
const PLACEHOLDER_IMG   := "res://assets/textures/campagin/placeholder_campagin.png"
const VN_PLAYER_SCENE   := "res://scenes/vn_player.tscn"


const CARD_IMG_W: float = 180.0
const CARD_IMG_H: float = 260.0
const CARD_GAP:   float = 20.0
const ROW_GAP:    float = 36.0
const CARD_DIM_OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.62)
const CARD_DIM_LABEL_COLOR   := Color(0.65, 0.65, 0.68)
const CARD_DIM_LABEL_SIZE    := 13
const GALLERY_SAVED_PROGRESS_DIALOG_MIN_W := 840.0
const DUNGEON_MAP_SCENE := DailyDungeonManager.DUNGEON_MAP_SCENE
const _SFX_MECH_HOVER: AudioStream = preload("res://assets/audio/sfx/scifi_ui_4B.mp3")
const _METAL_SHEEN_SHADER: Shader = preload("res://assets/shaders/magitech_metal_reflect.gdshader")
const _HOVER_SCALE: float = 1.08
const _HOVER_SCALE_SEC: float = 0.14
const _SHEEN_IDLE: float = 2.0
const _SHEEN_DURATION: float = 0.42

## Battle-matching drifting smoke (behind cards / text / header).
const _FOG_PATH := "res://assets/textures/effect/fog/Noise 3.png"
const _FOG_TILE_REPEAT: float = 8.0
const _FOG_TILE_REPEAT_DIAG: float = 3.0
const _FOG_IMAGE_SCALE: float = 3.0
const _FOG_ALPHA: float = 0.2
const _SPOTLIGHT_SHADER := preload("res://assets/shaders/shop_spotlight_cone.gdshader")
const _SPOTLIGHT_COUNT := 5
const _FOG_Z := 0
const _CONTENT_Z := 2
const _SPOTLIGHT_Z := 3
const _HEADER_Z := 4

var _data: Array = []
var _sheen_tweens: Dictionary = {}  # card instance_id -> Tween
var _fog_material: ShaderMaterial = null
var _fog_material_diag: ShaderMaterial = null
var _fog_scroll: Vector2 = Vector2.ZERO
var _fog_scroll_diag: Vector2 = Vector2(0.37, 0.61)
var _fog_scroll_x: float = 14.0
var _fog_scroll_y: float = 0.0
var _fog_diag_scroll_x: float = 11.0
var _fog_diag_scroll_y: float = -11.0
var _fog_dir_timer: float = 0.0
var _spotlight_pivots: Array[Control] = []


func _ready() -> void:
	_load_data()
	_build_ui()


func _process(delta: float) -> void:
	_update_fog(delta)


func _load_data() -> void:
	if not FileAccess.file_exists(GALLERY_DATA_PATH):
		return
	var f := FileAccess.open(GALLERY_DATA_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Array:
		_data = parsed as Array


func _build_ui() -> void:
	# ── Middle panel: pitch black ──────────────────────────────
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Drifting smoke (battle playmat fog) — behind capsules / labels / header.
	_build_fog()
	# Soft spotlights swaying L/R (same as shop) — above smoke, below cards.
	_build_spotlight_beams()

	var header: Dictionary = MenuScreenHeader.build_top_bar(self, "CAMPAIGN", queue_free)
	_style_gallery_header(header)
	_raise_header_z(header)

	# ── Scroll container (above smoke) ─────────────────────────
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = MenuScreenHeader.HEADER_HEIGHT + 8.0
	scroll.offset_left   = 32.0
	scroll.offset_right  = -32.0
	scroll.offset_bottom = -24.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.z_index = _CONTENT_Z
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(ROW_GAP))
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# ── Cards ─────────────────────────────────────────────────
	var current_row: HBoxContainer = null
	for raw: Variant in _data:
		var d: Dictionary = raw as Dictionary
		if current_row == null or bool(d.get("new_line_before", false)):
			current_row = HBoxContainer.new()
			current_row.add_theme_constant_override("separation", int(CARD_GAP))
			vbox.add_child(current_row)
		current_row.add_child(_build_card(d))


func _style_gallery_header(header: Dictionary) -> void:
	var bar: Panel = header.get("bar") as Panel
	if bar != null:
		# Keep layout slot; hide panel fill + border. Title/close stay visible.
		bar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title: Label = header.get("title") as Label
	if title != null:
		title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))


func _raise_header_z(header: Dictionary) -> void:
	for key: String in ["bar", "title", "close_btn"]:
		var node: Variant = header.get(key)
		if node is CanvasItem:
			(node as CanvasItem).z_index = _HEADER_Z


func _build_fog() -> void:
	var fog_tex := load(_FOG_PATH) as Texture2D
	if fog_tex == null:
		return

	var smoke_shader := Shader.new()
	smoke_shader.code = """
shader_type canvas_item;
uniform vec2 scroll = vec2(0.0, 0.0);
uniform float tile_repeat = 1.0;
uniform float image_scale = 3.0;
uniform float fog_alpha = 0.2;
void fragment() {
	vec2 uv = fract(UV * tile_repeat / image_scale + scroll);
	vec4 tex = texture(TEXTURE, uv);
	float smoke = 1.0 - tex.r;
	COLOR = vec4(vec3(smoke), smoke * fog_alpha);
}
"""

	var fog_clip := Control.new()
	fog_clip.name = "GalleryFog"
	fog_clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fog_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_clip.z_index = _FOG_Z
	add_child(fog_clip)

	_fog_material = _make_fog_material(smoke_shader, _FOG_TILE_REPEAT)
	_fog_material_diag = _make_fog_material(smoke_shader, _FOG_TILE_REPEAT_DIAG)
	fog_clip.add_child(_make_fog_layer(fog_tex, _fog_material))
	fog_clip.add_child(_make_fog_layer(fog_tex, _fog_material_diag))

	_fog_dir_timer = randf_range(3.0, 6.0)
	_pick_new_fog_vertical_dir()


func _make_fog_material(smoke_shader: Shader, tile_repeat: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = smoke_shader
	mat.set_shader_parameter("tile_repeat", tile_repeat)
	mat.set_shader_parameter("image_scale", _FOG_IMAGE_SCALE)
	mat.set_shader_parameter("fog_alpha", _FOG_ALPHA)
	return mat


func _make_fog_layer(fog_tex: Texture2D, mat: ShaderMaterial) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = fog_tex
	tr.material = mat
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _pick_new_fog_vertical_dir() -> void:
	_fog_scroll_y = randf_range(-5.0, 5.0)
	if absf(_fog_scroll_y) < 1.5:
		_fog_scroll_y = 2.0 if randf() > 0.5 else -2.0


func _update_fog(delta: float) -> void:
	if _fog_material == null:
		return
	_fog_dir_timer -= delta
	if _fog_dir_timer <= 0.0:
		_fog_dir_timer = randf_range(3.0, 7.0)
		_pick_new_fog_vertical_dir()
	var step := delta * 0.002
	_fog_scroll.x += _fog_scroll_x * step
	_fog_scroll.y += _fog_scroll_y * step
	_fog_material.set_shader_parameter("scroll", _fog_scroll)
	if _fog_material_diag != null:
		_fog_scroll_diag.x += _fog_diag_scroll_x * step
		_fog_scroll_diag.y += _fog_diag_scroll_y * step
		_fog_material_diag.set_shader_parameter("scroll", _fog_scroll_diag)


## Soft white spotlight cones rising from below, swaying left/right (shop match).
func _build_spotlight_beams() -> void:
	var existing := get_node_or_null("SpotlightLayer") as Control
	if existing != null:
		existing.queue_free()
	_spotlight_pivots.clear()

	var layer := Control.new()
	layer.name = "SpotlightLayer"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = _SPOTLIGHT_Z
	add_child(layer)

	for i in _SPOTLIGHT_COUNT:
		var pivot := Control.new()
		pivot.name = "SpotlightPivot_%d" % i
		pivot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var x_frac: float = lerpf(0.10, 0.90, float(i) / float(_SPOTLIGHT_COUNT - 1))
		x_frac = clampf(x_frac + randf_range(-0.05, 0.05), 0.04, 0.96)
		pivot.anchor_left = x_frac
		pivot.anchor_right = x_frac
		pivot.anchor_top = 1.0
		pivot.anchor_bottom = 1.0
		pivot.offset_left = 0.0
		pivot.offset_right = 0.0
		pivot.offset_top = 0.0
		pivot.offset_bottom = 0.0
		pivot.grow_horizontal = Control.GROW_DIRECTION_BOTH
		pivot.grow_vertical = Control.GROW_DIRECTION_BEGIN
		layer.add_child(pivot)

		var cone_w: float = randf_range(220.0, 360.0)
		var cone_h: float = randf_range(720.0, 980.0)
		var cone := ColorRect.new()
		cone.name = "Cone"
		cone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cone.size = Vector2(cone_w, cone_h)
		cone.position = Vector2(-cone_w * 0.5, -cone_h)
		cone.color = Color(1, 1, 1, 1)

		var mat := ShaderMaterial.new()
		mat.shader = _SPOTLIGHT_SHADER
		mat.set_shader_parameter("intensity", randf_range(0.22, 0.40))
		mat.set_shader_parameter("core_width", randf_range(0.05, 0.11))
		mat.set_shader_parameter("tip_width", randf_range(0.42, 0.78))
		mat.set_shader_parameter("beam_color", Color(1.0, 0.99, 0.96, 1.0))
		cone.material = mat
		pivot.add_child(cone)

		pivot.rotation = deg_to_rad(randf_range(-22.0, 22.0))
		_spotlight_pivots.append(pivot)
		_start_spotlight_sway(pivot)


func _start_spotlight_sway(pivot: Control) -> void:
	if pivot == null or not is_instance_valid(pivot):
		return
	var target_deg: float = randf_range(-30.0, 30.0)
	var dur: float = randf_range(2.2, 4.6)
	var tw := create_tween()
	tw.tween_property(pivot, "rotation", deg_to_rad(target_deg), dur) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_start_spotlight_sway.bind(pivot))


func _build_card(d: Dictionary) -> Control:
	var vn_path:    String = str(d.get("vn_scene", "")).strip_edges()
	var has_vn:    bool   = vn_path != ""
	var is_locked: bool   = _is_chapter_locked(d)
	var prereq_vn: String = _get_prerequisite_vn(d)

	# ── Card root ─────────────────────────────────────────────
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)
	card.custom_minimum_size = Vector2(CARD_IMG_W, 0.0)

	# ── Image frame ───────────────────────────────────────────
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(CARD_IMG_W, CARD_IMG_H)
	var sb := StyleBoxFlat.new()
	sb.bg_color         = Color(0.12, 0.12, 0.15)
	sb.border_width_left   = 1
	sb.border_width_right  = 1
	sb.border_width_top    = 1
	sb.border_width_bottom = 1
	sb.border_color     = Color(0.28, 0.28, 0.35)
	frame.add_theme_stylebox_override("panel", sb)
	card.add_child(frame)

	# Image texture
	var img_path: String = str(d.get("image", ""))
	var tex: Variant = null
	if img_path != "" and ResourceLoader.exists(img_path):
		tex = load(img_path)
	if tex == null:
		tex = load(PLACEHOLDER_IMG)

	var img := TextureRect.new()
	img.texture      = tex
	img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_child(img)

	# ── Locked overlay ────────────────────────────────────────
	if is_locked:
		_add_card_dim_overlay(frame)

		var lock_icon: TextureRect = ChromeIcon.make_rect("locked", Vector2(22, 22), Color(0.9, 0.92, 0.95, 0.95))
		lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_icon.set_anchors_preset(Control.PRESET_CENTER)
		lock_icon.offset_left = -11.0
		lock_icon.offset_top = -34.0
		lock_icon.offset_right = 11.0
		lock_icon.offset_bottom = -12.0
		frame.add_child(lock_icon)
		var lbl_lock := Label.new()
		var prereq_label: String = _prerequisite_display_name(prereq_vn)
		if prereq_label != "":
			lbl_lock.text = "Finish\n%s" % prereq_label
		else:
			lbl_lock.text = "LOCKED"
		lbl_lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_lock.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl_lock.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_lock.offset_top = 28.0
		lbl_lock.add_theme_font_override("font", FontManager.make_font("primary", 400))
		lbl_lock.add_theme_font_size_override("font_size", CARD_DIM_LABEL_SIZE)
		lbl_lock.add_theme_color_override("font_color", CARD_DIM_LABEL_COLOR)
		lbl_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(lbl_lock)

	# ── Coming soon overlay (unlocked but no VN yet) ──────────
	elif not has_vn:
		_add_card_dim_overlay(frame)

		var lbl_cs := Label.new()
		var _ct: String = str(d.get("custom_text", "")).strip_edges()
		lbl_cs.text = _ct if _ct != "" else "COMING\nSOON"
		lbl_cs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_cs.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl_cs.set_anchors_preset(Control.PRESET_FULL_RECT)
		FontManager.tag_primary(lbl_cs)
		lbl_cs.add_theme_font_size_override("font_size", CARD_DIM_LABEL_SIZE)
		lbl_cs.add_theme_color_override("font_color", CARD_DIM_LABEL_COLOR)
		lbl_cs.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(lbl_cs)

	# ── Playable ──────────────────────────────────────────────
	else:
		frame.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton \
					and (ev as InputEventMouseButton).pressed \
					and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				_on_chapter_pressed(d))

		var save_kind: String = _get_chapter_save_kind(d, vn_path)
		if save_kind != "":
			_add_saved_progress_badge(frame, save_kind)

		# Hover: tech/void-chip style scale + mechanism SFX + metal sheen (unlocked only).
		_wire_card_hover(card, frame, img, sb)

	# ── Line 1 (chapter) ──────────────────────────────────────
	var l1 := Label.new()
	l1.text = str(d.get("line1", ""))
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.tag_primary(l1)
	l1.add_theme_font_size_override("font_size", 14)
	l1.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	card.add_child(l1)

	# ── Line 2 (stage) ────────────────────────────────────────
	var l2 := Label.new()
	l2.text = str(d.get("line2", ""))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.tag_primary(l2)
	l2.add_theme_font_size_override("font_size", 12)
	l2.add_theme_color_override("font_color", Color(0.60, 0.62, 0.68, 0.85))
	card.add_child(l2)

	return card


func _wire_card_hover(card: Control, frame: Panel, img: TextureRect, sb: StyleBoxFlat) -> void:
	var sheen_mat := ShaderMaterial.new()
	sheen_mat.shader = _METAL_SHEEN_SHADER
	sheen_mat.set_shader_parameter("progress", _SHEEN_IDLE)
	sheen_mat.set_shader_parameter("intensity", 1.2)
	sheen_mat.set_shader_parameter("band_width", 0.20)
	img.material = sheen_mat
	# Keep refs on the card so hover tweens/signals don't capture freed locals.
	card.set_meta("_gallery_sheen_mat", sheen_mat)
	card.set_meta("_gallery_hover_sb", sb)
	card.set_meta("_gallery_hover_frame", frame)

	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	frame.mouse_entered.connect(_on_gallery_card_hover_entered.bind(card))
	frame.mouse_exited.connect(_on_gallery_card_hover_exited.bind(card))


func _on_gallery_card_hover_entered(card: Control) -> void:
	if card == null or not is_instance_valid(card) or not card.is_inside_tree():
		return
	var frame: Variant = _card_meta(card, "_gallery_hover_frame")
	var sb: Variant = _card_meta(card, "_gallery_hover_sb")
	if frame is Panel and sb is StyleBoxFlat:
		(sb as StyleBoxFlat).border_color = Color(0.75, 0.75, 0.85)
		(sb as StyleBoxFlat).bg_color = Color(0.18, 0.18, 0.24)
		(frame as Panel).add_theme_stylebox_override("panel", sb as StyleBoxFlat)
	if card.size == Vector2.ZERO:
		card.pivot_offset = Vector2(CARD_IMG_W * 0.5, CARD_IMG_H * 0.5)
	else:
		card.pivot_offset = card.size * 0.5
	SFXManager.play(_SFX_MECH_HOVER)
	_kill_card_scale_tween(card)
	_play_card_metal_sheen(card)
	var tw := card.create_tween()
	card.set_meta("_gallery_hover_tween", tw)
	tw.tween_property(card, "scale", Vector2(_HOVER_SCALE, _HOVER_SCALE), _HOVER_SCALE_SEC) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_gallery_card_hover_exited(card: Control) -> void:
	if card == null or not is_instance_valid(card) or not card.is_inside_tree():
		return
	var frame: Variant = _card_meta(card, "_gallery_hover_frame")
	var sb: Variant = _card_meta(card, "_gallery_hover_sb")
	if frame is Panel and sb is StyleBoxFlat:
		(sb as StyleBoxFlat).border_color = Color(0.28, 0.28, 0.35)
		(sb as StyleBoxFlat).bg_color = Color(0.12, 0.12, 0.15)
		(frame as Panel).add_theme_stylebox_override("panel", sb as StyleBoxFlat)
	var mat: Variant = _card_meta(card, "_gallery_sheen_mat")
	if mat is ShaderMaterial:
		(mat as ShaderMaterial).set_shader_parameter("progress", _SHEEN_IDLE)
	_kill_card_scale_tween(card)
	_kill_card_sheen_tween(card)
	var tw := card.create_tween()
	card.set_meta("_gallery_hover_tween", tw)
	tw.tween_property(card, "scale", Vector2.ONE, _HOVER_SCALE_SEC) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _card_meta(card: Object, key: StringName) -> Variant:
	if card == null or not is_instance_valid(card) or not card.has_meta(key):
		return null
	return card.get_meta(key)


func _kill_card_scale_tween(card: Control) -> void:
	if card == null or not is_instance_valid(card):
		return
	var old: Variant = _card_meta(card, "_gallery_hover_tween")
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()


func _kill_card_sheen_tween(card: Control) -> void:
	if card == null or not is_instance_valid(card):
		return
	var id: int = card.get_instance_id()
	if not _sheen_tweens.has(id):
		return
	var sheen: Variant = _sheen_tweens[id]
	_sheen_tweens.erase(id)
	if sheen is Tween and (sheen as Tween).is_valid():
		(sheen as Tween).kill()


func _play_card_metal_sheen(card: Control) -> void:
	if card == null or not is_instance_valid(card) or not card.is_inside_tree():
		return
	var mat_v: Variant = _card_meta(card, "_gallery_sheen_mat")
	if mat_v == null or not (mat_v is ShaderMaterial):
		return
	var mat: ShaderMaterial = mat_v as ShaderMaterial
	mat.set_shader_parameter("progress", -0.15)
	_kill_card_sheen_tween(card)
	# Hold material in an Array so the lambda keeps a strong RefCounted ref
	# (direct Object captures become null when freed and break the sheen).
	var hold: Array = [mat]
	var id: int = card.get_instance_id()
	var tw := create_tween()
	_sheen_tweens[id] = tw
	tw.tween_method(
		func(v: float) -> void:
			var m: Variant = hold[0]
			if m is ShaderMaterial:
				(m as ShaderMaterial).set_shader_parameter("progress", v),
		-0.15, 1.15, _SHEEN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		var m: Variant = hold[0]
		if m is ShaderMaterial:
			(m as ShaderMaterial).set_shader_parameter("progress", _SHEEN_IDLE)
		_sheen_tweens.erase(id))


func _add_card_dim_overlay(frame: Panel) -> void:
	var dim := ColorRect.new()
	dim.color = CARD_DIM_OVERLAY_COLOR
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(dim)


func _get_chapter_save_kind(card: Dictionary, vn_path: String) -> String:
	if vn_path.is_empty() or _is_chapter_locked(card):
		return ""
	if SaveManager.has_chapter_arc_progress(vn_path):
		var arc_kind: String = SaveManager.get_chapter_arc_segment_kind(vn_path)
		if not arc_kind.is_empty():
			return arc_kind
	var dungeon_info: Dictionary = _resolve_chapter_dungeon(card, vn_path)
	var dungeon_id: String = str(dungeon_info.get("dungeon_id", "")).strip_edges()
	if dungeon_id != "" and DailyDungeonManager.has_story_dungeon_save(dungeon_id):
		return "dungeon"
	var expl_info: Dictionary = _resolve_chapter_exploration(card, vn_path)
	var graph_path: String = str(expl_info.get("graph_path", "")).strip_edges()
	if graph_path != "" and ExplorationManager.has_saved_session_for_chapter(vn_path, graph_path, card):
		return "exploration"
	if SaveManager.is_gallery_chapter_completed(vn_path):
		return ""
	return ""


func _add_saved_progress_badge(frame: Panel, save_kind: String) -> void:
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	badge.offset_left = 8.0
	badge.offset_right = -8.0
	badge.offset_bottom = -8.0
	badge.offset_top = -34.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.18, 0.34, 0.92)
	sb.border_color = Color(0.45, 0.78, 1.0, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	badge.add_theme_stylebox_override("panel", sb)
	frame.add_child(badge)

	var lbl := Label.new()
	lbl.text = "Continue Saved Progress"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.tag_primary(lbl)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	badge.add_child(lbl)

	if save_kind == "exploration":
		lbl.tooltip_text = "Saved exploration progress is available for this chapter."
	elif save_kind == "dungeon":
		lbl.tooltip_text = "Saved dungeon progress is available for this chapter."
	elif save_kind == "vn":
		lbl.tooltip_text = "Saved story progress is available for this chapter."


func _on_chapter_pressed(card: Dictionary) -> void:
	if GameDialog.has_any_open_overlay():
		return
	if _is_chapter_locked(card):
		return
	if not _require_deck_ready_for_chapter():
		return
	var vn_path: String = str(card.get("vn_scene", "")).strip_edges()
	if vn_path.is_empty():
		return
	match _get_chapter_save_kind(card, vn_path):
		"dungeon":
			var dungeon_info: Dictionary = _resolve_chapter_dungeon(card, vn_path)
			var dungeon_id: String = str(dungeon_info.get("dungeon_id", "")).strip_edges()
			_show_continue_or_restart_dialog(card, vn_path, dungeon_id)
		"exploration", "vn":
			_show_continue_or_restart_chapter_dialog(card, vn_path)
		_:
			_play_vn(vn_path, true, card)


func _resolve_chapter_dungeon(card: Dictionary, vn_path: String) -> Dictionary:
	var dungeon_id: String = str(card.get("dungeon_id", "")).strip_edges()
	if dungeon_id != "":
		return {
			"dungeon_id": dungeon_id,
			"dungeon_on_win": str(card.get("dungeon_on_win", "")),
			"dungeon_on_lose": str(card.get("dungeon_on_lose", "")),
		}
	return DailyDungeonManager.find_dungeon_call_in_vn(vn_path)


func _resolve_chapter_exploration(card: Dictionary, vn_path: String) -> Dictionary:
	var graph_path: String = ExplorationManager.resolve_chapter_exploration_graph(card, vn_path)
	if graph_path.is_empty():
		return {}
	return {"graph_path": graph_path}


func _show_continue_or_restart_chapter_dialog(card: Dictionary, chapter_key: String) -> void:
	if GameDialog.has_open_overlay(self):
		return
	var chapter_label: String = str(card.get("line2", card.get("line1", "this chapter")))
	var save_kind: String = _get_chapter_save_kind(card, chapter_key)
	var body: String = "You have saved progress in %s.\n\nContinue from where you left off, or restart the chapter from the beginning." % chapter_label
	if save_kind == "exploration":
		body = "You have saved exploration progress in %s.\n\nContinue from where you left off, or restart the chapter from the beginning." % chapter_label
	elif save_kind == "vn":
		body = "You have saved story progress in %s.\n\nContinue from where you left off, or restart the chapter from the beginning." % chapter_label
	GameDialog.menu_overlay(
		self,
		"Saved Progress Found",
		body,
		[
			{"text": "Continue Saved Progress", "callback": func() -> void: _continue_chapter_arc(card, chapter_key)},
			{"text": "Restart Chapter", "callback": func() -> void:
				_show_restart_chapter_warning_dialog(card, chapter_key, chapter_label)},
		],
		"Cancel",
		Callable(),
		GALLERY_SAVED_PROGRESS_DIALOG_MIN_W,
		30)


func _show_restart_chapter_warning_dialog(
		card: Dictionary,
		chapter_key: String,
		chapter_label: String) -> void:
	if GameDialog.has_open_overlay(self):
		return
	GameDialog.confirmation_overlay(
		self,
		"Restart Chapter?",
		"Restarting %s will erase all saved story, exploration, and dungeon progress for this chapter." % chapter_label,
		"Restart Chapter",
		"Cancel",
		func() -> void:
			SaveManager.reset_chapter_arc_progress(chapter_key, card)
			var entry_vn: String = str(card.get("vn_scene", chapter_key)).strip_edges()
			_play_vn(entry_vn, true, card, chapter_key),
		Callable(),
		520.0,
		30)


func _continue_chapter_arc(card: Dictionary, chapter_key: String) -> void:
	if not _require_deck_ready_for_chapter():
		return
	var arc: Dictionary = SaveManager.get_chapter_arc(chapter_key)
	var segment: String = str(arc.get("segment", "")).strip_edges()
	if segment.is_empty():
		segment = _get_chapter_save_kind(card, chapter_key)
	match segment:
		"exploration":
			var graph_path: String = str(arc.get("exploration_graph", "")).strip_edges()
			if graph_path.is_empty():
				var expl_info: Dictionary = _resolve_chapter_exploration(card, chapter_key)
				graph_path = str(expl_info.get("graph_path", "")).strip_edges()
			if graph_path.is_empty():
				return
			var pending: String = str(arc.get("pending_return_vn", "")).strip_edges()
			if pending.is_empty():
				var expl: Dictionary = ExplorationManager.find_exploration_call_in_vn(chapter_key)
				pending = str(expl.get("exploration_on_return", "")).strip_edges()
			ExplorationManager.pending_return_vn = pending
			_resume_exploration(graph_path)
		"vn":
			var play_path: String = str(arc.get("vn_path", "")).strip_edges()
			if play_path.is_empty():
				play_path = chapter_key
			_play_vn(play_path, false, card, chapter_key)
		_:
			var expl_info: Dictionary = _resolve_chapter_exploration(card, chapter_key)
			var graph_path: String = str(expl_info.get("graph_path", "")).strip_edges()
			if not graph_path.is_empty() \
					and ExplorationManager.has_saved_session_for_chapter(
						chapter_key, graph_path, card):
				_resume_exploration(graph_path)
			else:
				var entry_vn: String = str(card.get("vn_scene", chapter_key)).strip_edges()
				_play_vn(entry_vn, true, card, chapter_key)


func _show_continue_or_restart_vn_dialog(card: Dictionary, vn_path: String) -> void:
	_show_continue_or_restart_chapter_dialog(card, vn_path)


func _show_continue_or_restart_exploration_dialog(
		card: Dictionary,
		vn_path: String,
		_graph_path: String) -> void:
	_show_continue_or_restart_chapter_dialog(card, vn_path)


func _resume_exploration(graph_path: String) -> void:
	if not _require_deck_ready_for_chapter():
		return
	ExplorationManager.resume_saved_exploration(
		graph_path,
		"res://scenes/main_menu.tscn")


func _show_continue_or_restart_dialog(card: Dictionary, vn_path: String, dungeon_id: String) -> void:
	if GameDialog.has_open_overlay(self):
		return
	var chapter_label: String = str(card.get("line2", card.get("line1", "this chapter")))
	GameDialog.menu_overlay(
		self,
		"Saved Progress Found",
		"You have saved progress in %s.\n\nContinue from where you left off, or restart the chapter from the beginning." % chapter_label,
		[
			{"text": "Continue Saved Progress", "callback": func() -> void: _resume_story_dungeon(dungeon_id)},
			{"text": "Restart Chapter", "callback": func() -> void:
				_show_restart_warning_dialog(card, vn_path, dungeon_id, chapter_label)},
		],
		"Cancel",
		Callable(),
		GALLERY_SAVED_PROGRESS_DIALOG_MIN_W,
		30)


func _show_restart_warning_dialog(
		card: Dictionary,
		vn_path: String,
		dungeon_id: String,
		chapter_label: String) -> void:
	if GameDialog.has_open_overlay(self):
		return
	GameDialog.confirmation_overlay(
		self,
		"Restart Chapter?",
		"Restarting %s will erase all saved dungeon progress, wheel modifiers, and map position for this chapter." % chapter_label,
		"Restart Chapter",
		"Cancel",
		func() -> void:
			DailyDungeonManager.reset_story_dungeon_chapter(dungeon_id)
			SaveManager.reset_chapter_arc_progress(vn_path, card)
			_play_vn(vn_path, true, card, vn_path),
		Callable(),
		520.0,
		30)


func _resume_story_dungeon(dungeon_id: String) -> void:
	if not _require_deck_ready_for_chapter():
		return
	DailyDungeonManager.resume_story_dungeon(dungeon_id)
	get_tree().change_scene_to_file(DUNGEON_MAP_SCENE)


func _play_vn(json_path: String, fresh_start: bool = true, card: Dictionary = {}, chapter_arc_key: String = "") -> void:
	_play_vn_async(json_path, fresh_start, card, chapter_arc_key)

func _play_vn_async(
		json_path: String,
		fresh_start: bool = true,
		card: Dictionary = {},
		chapter_arc_key: String = "") -> void:
	if not _require_deck_ready_for_chapter():
		return
	GlobalStatManager.on_first_touch("story_vn")
	if json_path.find("ch0_s1_pre_DEMO_PART1") >= 0:
		GlobalStatManager.on_first_touch("prologue_capsule")
	await BGMManager.fade_out_and_stop(BGMManager.DEFAULT_FADE)
	var arc_key: String = chapter_arc_key.strip_edges()
	if arc_key.is_empty():
		arc_key = str(card.get("vn_scene", json_path)).strip_edges()
	if fresh_start:
		SaveManager.reset_chapter_arc_progress(arc_key, card)
	var vn_scene: Variant = load(VN_PLAYER_SCENE)
	var vn := (vn_scene as PackedScene).instantiate()
	vn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vn)
	vn.play_scene(json_path, func() -> void:
		pass,
		true,
		arc_key)


func _get_prerequisite_vn(d: Dictionary) -> String:
	var prereq: String = str(d.get("prerequisite_chapter", "")).strip_edges()
	if prereq != "":
		return prereq
	# Legacy: campaign map node id (e.g. ch0_s1)
	var legacy_id: String = str(d.get("unlock_requires", "")).strip_edges()
	if legacy_id == "":
		return ""
	return CampaignManager.get_vn_scene_for_node(legacy_id)


func _is_chapter_locked(d: Dictionary) -> bool:
	var prereq_vn: String = _get_prerequisite_vn(d)
	if prereq_vn == "":
		return false
	return not SaveManager.is_gallery_chapter_completed(prereq_vn)


func _require_deck_ready_for_chapter() -> bool:
	if SaveManager.is_active_deck_ready():
		return true
	SaveManager.show_deck_not_ready_overlay(self)
	return false


func _prerequisite_display_name(prereq_vn: String) -> String:
	if prereq_vn.is_empty():
		return ""
	for raw: Variant in _data:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw as Dictionary
		if str(entry.get("vn_scene", "")).strip_edges() == prereq_vn:
			var line2: String = str(entry.get("line2", "")).strip_edges()
			if line2 != "":
				return line2
			return str(entry.get("line1", "prior chapter")).strip_edges()
	if ResourceLoader.exists(prereq_vn):
		return prereq_vn.get_file().get_basename()
	return prereq_vn
