extends Control
class_name CampaignGallery

const GALLERY_DATA_PATH := "res://campaign/gallery_data.json"
const PLACEHOLDER_IMG   := "res://assets/textures/campagin/placeholder_campagin.png"
const VN_PLAYER_SCENE   := "res://scenes/vn_player.tscn"

const CHIVO_FONT := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")

const CARD_IMG_W: float = 180.0
const CARD_IMG_H: float = 260.0
const CARD_GAP:   float = 20.0
const ROW_GAP:    float = 36.0

var _data: Array = []


func _ready() -> void:
	_load_data()
	_build_ui()


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
	# ── Background ────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.07, 0.09)
	add_child(bg)

	# ── Back button ───────────────────────────────────────────
	var back_btn := Button.new()
	back_btn.text = "← BACK"
	back_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_btn.offset_left   = 20.0
	back_btn.offset_top    = 20.0
	back_btn.offset_right  = 140.0
	back_btn.offset_bottom = 52.0
	back_btn.add_theme_font_override("font", CHIVO_FONT)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(queue_free)
	add_child(back_btn)

	# ── Title ─────────────────────────────────────────────────
	var title := Label.new()
	title.text = "CAMPAIGN"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top    = 20.0
	title.offset_bottom = 62.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CHIVO_FONT)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	add_child(title)

	# ── Scroll container ──────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = 76.0
	scroll.offset_left   = 32.0
	scroll.offset_right  = -32.0
	scroll.offset_bottom = -24.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
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


func _build_card(d: Dictionary) -> Control:
	var vn_path:    String = str(d.get("vn_scene", "")).strip_edges()
	var has_vn:    bool   = vn_path != ""
	var req_node:  String = str(d.get("unlock_requires", "")).strip_edges()
	var is_locked: bool   = req_node != "" and not CampaignManager.completed.has(req_node)

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
	if not is_locked and img_path != "" and ResourceLoader.exists(img_path):
		tex = load(img_path)
	if tex == null:
		tex = load(PLACEHOLDER_IMG)

	var img := TextureRect.new()
	img.texture      = tex
	img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Desaturate locked cards at the modulate level
	if is_locked:
		img.modulate = Color(0.35, 0.35, 0.38, 1.0)
	frame.add_child(img)

	# ── Locked overlay ────────────────────────────────────────
	if is_locked:
		var dim := ColorRect.new()
		dim.color = Color(0.0, 0.0, 0.0, 0.70)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(dim)

		var lbl_lock := Label.new()
		lbl_lock.text = "🔒\nLOCKED"
		lbl_lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_lock.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl_lock.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_lock.add_theme_font_override("font", CHIVO_FONT)
		lbl_lock.add_theme_font_size_override("font_size", 14)
		lbl_lock.add_theme_color_override("font_color", Color(0.55, 0.55, 0.58))
		lbl_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(lbl_lock)

	# ── Coming soon overlay (unlocked but no VN yet) ──────────
	elif not has_vn:
		var dim := ColorRect.new()
		dim.color = Color(0.0, 0.0, 0.0, 0.62)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(dim)

		var lbl_cs := Label.new()
		var _ct: String = str(d.get("custom_text", "")).strip_edges()
		lbl_cs.text = _ct if _ct != "" else "COMING\nSOON"
		lbl_cs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_cs.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl_cs.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_cs.add_theme_font_override("font", CHIVO_FONT)
		lbl_cs.add_theme_font_size_override("font_size", 13)
		lbl_cs.add_theme_color_override("font_color", Color(0.65, 0.65, 0.68))
		lbl_cs.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(lbl_cs)

	# ── Playable ──────────────────────────────────────────────
	else:
		frame.mouse_entered.connect(func() -> void:
			sb.border_color = Color(0.75, 0.75, 0.85)
			sb.bg_color     = Color(0.18, 0.18, 0.24)
			frame.add_theme_stylebox_override("panel", sb))
		frame.mouse_exited.connect(func() -> void:
			sb.border_color = Color(0.28, 0.28, 0.35)
			sb.bg_color     = Color(0.12, 0.12, 0.15)
			frame.add_theme_stylebox_override("panel", sb))
		frame.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton \
					and (ev as InputEventMouseButton).pressed \
					and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				_play_vn(vn_path))

	# ── Line 1 (chapter) ──────────────────────────────────────
	var l1 := Label.new()
	l1.text = str(d.get("line1", ""))
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_font_override("font", CHIVO_FONT)
	l1.add_theme_font_size_override("font_size", 14)
	l1.add_theme_color_override("font_color",
		Color(0.40, 0.40, 0.43, 0.7) if is_locked else Color(1.0, 1.0, 1.0, 0.95))
	card.add_child(l1)

	# ── Line 2 (stage) ────────────────────────────────────────
	var l2 := Label.new()
	l2.text = str(d.get("line2", ""))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.add_theme_font_override("font", CHIVO_FONT)
	l2.add_theme_font_size_override("font_size", 12)
	l2.add_theme_color_override("font_color",
		Color(0.35, 0.35, 0.38, 0.6) if is_locked else Color(0.60, 0.62, 0.68, 0.85))
	card.add_child(l2)

	return card


func _play_vn(json_path: String) -> void:
	var vn_scene: Variant = load(VN_PLAYER_SCENE)
	var vn := (vn_scene as PackedScene).instantiate()
	add_child(vn)
	vn.play_scene(json_path, func() -> void: pass)
