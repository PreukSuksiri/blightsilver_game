extends Control
# VN Beat Editor — full-screen overlay for editing VN JSON scene files.
# Open via Admin Console: vn_editor [optional filename or path]
# Saves back to the same JSON file (Array of beat dicts).

signal closed

const SCENES_DIR     := "res://campaign/scenes/"
const LANG_CFG_PATH  := "res://campaign/scenes/languages.json"
const BUG_TAGS_PATH  := "user://vn_bug_tags.json"
const SLOT_OPTIONS: Array = ["far_left", "left", "center", "right", "far_right"]
const ANIMATION_REGISTRY: Array = [
	{"label": "(none)",                                "key": ""},
	{"label": "Vellum Card Commence — flip",           "key": "animation_vellum_card_commence_flip"},
	{"label": "Vellum Card Commence — facedown",       "key": "animation_vellum_card_commence_facedown"},
]
const COLOR_PRESETS: Array = [
	["R", "#FF4444"],
	["G", "#44FF88"],
	["B", "#4488FF"],
	["Y", "#FFEE44"],
	["P", "#CC44FF"],
	["O", "#FF8844"],
	["W", "#FFFFFF"],
	["Gr", "#AAAAAA"],
]

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var _beats: Array = []
var _file_path: String = ""
var _selected_idx: int = -1
var _loading: bool = false
var _dirty: bool = false
var _char_rows: Array = []
var _file_dialog: FileDialog = null
var _browse_target: LineEdit = null
var _clipboard: Array = []       # Array[Dictionary] — supports multi-beat copy
var _has_clipboard: bool = false
var _char_clipboard: Array = []  # Array[Dictionary] — characters copy/paste
var _has_char_clipboard: bool = false
var _drag_from_idx: int = -1
var _beat_modified: Dictionary = {}   # index → bool; cleared on save/load/structural ops
var _anchor_idx: int = -1             # for Shift+click range selection
var _file_cache: Dictionary = {}      # path → {beats, modified}; in-memory unsaved state per file
var _bug_tags: Dictionary = {}        # path → Array[int] raw beat indices; loaded from BUG_TAGS_PATH

# Preview
var _preview_player: AudioStreamPlayer = null
var _img_popup: PopupPanel = null
var _img_popup_tex: TextureRect = null

# Language system
var _languages: Array = ["en"]       # ordered list of language codes
var _speaker_locale_idx: int = 0
var _text_locale_idx: int = 0
var _speaker_fields: Array = []      # LineEdit per language
var _text_fields: Array = []         # TextEdit per language
var _text_tag_rows: Array = []       # HBoxContainer per language (color tag buttons)
var _speaker_tabs: Array = []        # Button per language
var _text_tabs: Array = []           # Button per language
var _speaker_area: VBoxContainer = null
var _text_area: VBoxContainer = null
var _lang_chips_hbox: HBoxContainer = null   # chip row in left panel
var _lang_input: LineEdit = null

# ─────────────────────────────────────────────────────────────
# UI refs — left panel
# ─────────────────────────────────────────────────────────────
var _file_list: ItemList = null
var _beat_list: ItemList = null
var _status_lbl: Label = null
var _bug_note_lbl: Label = null

# ─────────────────────────────────────────────────────────────
# UI refs — right panel (non-locale)
# ─────────────────────────────────────────────────────────────
var _no_beat_lbl: Label = null
var _fields_scroll: ScrollContainer = null
var _fields_vbox: VBoxContainer = null
var _f_comment: LineEdit = null
var _f_hidden: CheckBox = null
var _f_background: LineEdit = null
var _f_video: LineEdit = null
var _chars_vbox: VBoxContainer = null
var _f_linger_chars: CheckBox = null
var _f_dim_others: CheckBox = null
var _f_kb_zoom: SpinBox = null
var _f_kb_pan_x: SpinBox = null
var _f_kb_pan_y: SpinBox = null
var _f_kb_duration: SpinBox = null
var _f_music: LineEdit = null
var _f_music_fade_in: SpinBox = null
var _f_music_fade_out: SpinBox = null
var _f_sfx: LineEdit = null
var _f_sfx_volume: SpinBox = null
var _f_wait: SpinBox = null
var _f_fade_in: SpinBox = null
var _f_fade_out: SpinBox = null
var _f_fade_color: LineEdit = null
var _f_flash_color: LineEdit = null
var _f_flash_count: SpinBox = null
var _f_flash_duration: SpinBox = null
var _f_flash_delay: SpinBox = null
var _f_flash_target: LineEdit = null
var _f_shake: LineEdit = null
var _f_shake_magnitude: SpinBox = null
var _f_shake_screen: SpinBox = null
var _f_player1_name: LineEdit = null
var _f_player2_name: LineEdit = null
var _f_portrait_p1: LineEdit = null
var _f_portrait_p2: LineEdit = null
var _f_portrait_p1_offset_x: SpinBox = null
var _f_portrait_p1_offset_y: SpinBox = null
var _f_portrait_p1_size:     SpinBox = null
var _f_portrait_p2_offset_x: SpinBox = null
var _f_portrait_p2_offset_y: SpinBox = null
var _f_portrait_p2_size:     SpinBox = null
var _f_battle_bgm: LineEdit = null
var _f_battle_bgm_vol: SpinBox = null
var _f_start_battle:  CheckBox = null
var _f_go_to_credits:    CheckBox     = null
var _f_credits_target:   OptionButton = null
var _f_hide_dialog:      CheckBox     = null
var _f_bg_color:       LineEdit = null
var _f_center_text:          LineEdit = null
var _f_center_text_size:     SpinBox  = null
var _f_center_text_fade_in:  SpinBox  = null
var _f_center_text_hold:     SpinBox  = null
var _f_center_text_fade_out: SpinBox  = null
var _f_on_win: LineEdit = null
var _f_on_lose: LineEdit = null
var _f_nsfw: OptionButton = null
var _f_animation: OptionButton = null
var _f_ai_union_enabled: CheckBox = null
var _f_player_union_enabled: CheckBox = null
var _f_ai_pers_def: OptionButton = null
var _f_ai_pers_off: OptionButton = null
var _f_ai_pers_soc: OptionButton = null
var _f_call_scene:  OptionButton = null

# Enemy deck builder (for start_battle beats)
var _enemy_deck_chars: Array = []
var _enemy_deck_traps: Array = []
var _enemy_deck_tech: Array = []
var _enemy_chars_chips: HBoxContainer = null
var _enemy_traps_chips: HBoxContainer = null
var _enemy_tech_chips: HBoxContainer = null

# Forced cell placements — grid-based UI
var _player_forced_grid: Dictionary = {}   # key="r,c"  value=card_name String
var _ai_forced_grid:     Dictionary = {}
var _player_forced_gc:   GridContainer = null
var _ai_forced_gc:       GridContainer = null

# Union zone highlight (for union card reference gallery)
var _union_highlighted_name: String = ""
var _union_highlight_cells: Array = []     # Array[Vector2i]

# Union gallery UI
var _union_gallery_search: LineEdit = null
var _union_gallery_vbox:   VBoxContainer = null

# Battle reward rows
var _battle_reward_rows: Array = []
var _reward_rows_vbox: VBoxContainer = null

# Dungeon call fields
var _f_call_dungeon:        CheckBox     = null
var _f_dungeon_mode_filter: OptionButton = null   # editor UX only, not saved to JSON
var _f_dungeon_opt:         OptionButton = null
var _f_dungeon_on_win:      LineEdit     = null
var _f_dungeon_on_lose:     LineEdit     = null
var _dungeon_filtered_ids:  Array        = []

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 60
	# Stop main menu BGM while editor is open
	var scene_bgm: Variant = get_tree().current_scene.get_node_or_null("BGM")
	if scene_bgm is AudioStreamPlayer:
		(scene_bgm as AudioStreamPlayer).stop()
	_load_languages()
	_build_ui()
	_bug_tags = _load_vn_bug_tags()
	_scan_files()
	# Audio preview player
	_preview_player = AudioStreamPlayer.new()
	add_child(_preview_player)
	# Image preview popup
	_img_popup = PopupPanel.new()
	add_child(_img_popup)
	_img_popup_tex = TextureRect.new()
	_img_popup_tex.custom_minimum_size = Vector2(700, 500)
	_img_popup_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_img_popup.add_child(_img_popup_tex)
	if has_meta("_pending_path"):
		open_file(str(get_meta("_pending_path")))

# ─────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────
func open_file(path: String) -> void:
	var full_path: String
	if path.begins_with("res://") or path.begins_with("user://") or path.begins_with("/"):
		full_path = path
	else:
		full_path = SCENES_DIR + path
	_load_file(full_path)
	var fname: String = full_path.get_file()
	for i: int in range(_file_list.item_count):
		if _file_list.get_item_text(i) == fname:
			_file_list.select(i)
			break

# ─────────────────────────────────────────────────────────────
# Language persistence
# ─────────────────────────────────────────────────────────────
func _load_languages() -> void:
	if not FileAccess.file_exists(LANG_CFG_PATH):
		_languages = ["en"]
		return
	var f := FileAccess.open(LANG_CFG_PATH, FileAccess.READ)
	if f == null:
		_languages = ["en"]
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Array or (parsed as Array).is_empty():
		_languages = ["en"]
		return
	_languages = parsed as Array
	# Guarantee "en" is always first
	if not _languages.has("en"):
		_languages.insert(0, "en")

func _save_languages() -> void:
	var f := FileAccess.open(LANG_CFG_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_languages, "\t"))
	f.close()

func _add_language(code: String) -> void:
	code = code.strip_edges().to_lower()
	if code.is_empty() or _languages.has(code):
		return
	_languages.append(code)
	_save_languages()
	_rebuild_lang_chips()
	_rebuild_locale_ui()

func _remove_language(code: String) -> void:
	if code == "en" or not _languages.has(code):
		return
	# Clamp locale indices
	_languages.erase(code)
	_speaker_locale_idx = clampi(_speaker_locale_idx, 0, _languages.size() - 1)
	_text_locale_idx    = clampi(_text_locale_idx,    0, _languages.size() - 1)
	_save_languages()
	_rebuild_lang_chips()
	_rebuild_locale_ui()

# ─────────────────────────────────────────────────────────────
# Build UI
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.88)
	dimmer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(dimmer)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 20.0; panel.offset_right  = -20.0
	panel.offset_top  = 20.0; panel.offset_bottom = -20.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.025, 0.055, 0.125, 0.98)
	sb.border_color = Color(0.3, 0.6, 1.0, 0.5)
	sb.border_width_left = 1; sb.border_width_right  = 1
	sb.border_width_top  = 1; sb.border_width_bottom = 1
	sb.corner_radius_top_left    = 8; sb.corner_radius_top_right    = 8
	sb.corner_radius_bottom_left = 8; sb.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left   = 10.0; main_vbox.offset_right  = -10.0
	main_vbox.offset_top    = 8.0;  main_vbox.offset_bottom = -8.0
	panel.add_child(main_vbox)

	_build_header(main_vbox)

	_file_dialog = FileDialog.new()
	_file_dialog.access    = FileDialog.ACCESS_RESOURCES
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.file_selected.connect(_on_file_dialog_selected)
	add_child(_file_dialog)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 300
	main_vbox.add_child(split)

	_build_left_panel(split)
	_build_right_panel(split)

func _build_header(parent: Control) -> void:
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size.y = 44.0
	hbox.add_theme_constant_override("separation", 10)
	parent.add_child(hbox)

	var title := Label.new()
	title.text = "VN BEAT EDITOR"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(title)

	_status_lbl = Label.new()
	_status_lbl.text = "Select a file to begin"
	_status_lbl.add_theme_font_size_override("font_size", 15)
	_status_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	_status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_status_lbl)

	var resolve_btn := Button.new()
	resolve_btn.text = "Resolve Bug"
	resolve_btn.custom_minimum_size = Vector2(110, 34)
	resolve_btn.pressed.connect(_resolve_bug_tag)
	hbox.add_child(resolve_btn)
	_bug_note_lbl = Label.new()
	_bug_note_lbl.add_theme_font_size_override("font_size", 14)
	_bug_note_lbl.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	_bug_note_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bug_note_lbl.clip_text = true
	_bug_note_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_bug_note_lbl)
	var save_btn := Button.new()
	save_btn.text = "SAVE"
	save_btn.custom_minimum_size = Vector2(100, 34)
	save_btn.pressed.connect(_save)
	hbox.add_child(save_btn)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(90, 34)
	close_btn.pressed.connect(func() -> void: closed.emit(); queue_free())
	hbox.add_child(close_btn)

	parent.add_child(HSeparator.new())

func _build_left_panel(parent: Control) -> void:
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 300.0
	left.add_theme_constant_override("separation", 4)
	parent.add_child(left)

	# File browser
	_left_hdr(left, "FILES  (campaign/scenes/)")
	_file_list = ItemList.new()
	_file_list.custom_minimum_size.y = 130.0
	_file_list.add_theme_font_size_override("font_size", 15)
	_file_list.item_selected.connect(_on_file_selected)
	left.add_child(_file_list)

	left.add_child(HSeparator.new())

	# Language manager
	_left_hdr(left, "LANGUAGES")
	_lang_chips_hbox = HBoxContainer.new()
	_lang_chips_hbox.add_theme_constant_override("separation", 4)
	left.add_child(_lang_chips_hbox)
	_rebuild_lang_chips()

	var lang_add_row := HBoxContainer.new()
	lang_add_row.add_theme_constant_override("separation", 4)
	left.add_child(lang_add_row)
	_lang_input = LineEdit.new()
	_lang_input.placeholder_text = "code (e.g. jp)"
	_lang_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lang_input.add_theme_font_size_override("font_size", 13)
	_lang_input.text_submitted.connect(func(t: String) -> void: _add_language(t); _lang_input.clear())
	lang_add_row.add_child(_lang_input)
	var lang_add_btn := Button.new()
	lang_add_btn.text = "+ Add"
	lang_add_btn.custom_minimum_size = Vector2(60, 26)
	lang_add_btn.add_theme_font_size_override("font_size", 13)
	lang_add_btn.pressed.connect(func() -> void: _add_language(_lang_input.text); _lang_input.clear())
	lang_add_row.add_child(lang_add_btn)

	left.add_child(HSeparator.new())

	# Beat list
	_left_hdr(left, "BEATS")
	_beat_list = ItemList.new()
	_beat_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_beat_list.add_theme_font_size_override("font_size", 15)
	_beat_list.select_mode = ItemList.SELECT_MULTI
	_beat_list.item_selected.connect(_on_beat_selected)
	_beat_list.gui_input.connect(_on_beat_list_input)
	left.add_child(_beat_list)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 3)
	left.add_child(btn_row)
	_small_btn(btn_row, "+ Add", _add_beat)
	_small_btn(btn_row, "Dup",   _duplicate_beat)
	_small_btn(btn_row, "Copy",  _copy_beat)
	_small_btn(btn_row, "Paste", _paste_beat)
	_small_btn(btn_row, "Del",   _delete_beat)
	_small_btn(btn_row, "↑",     _move_beat_up)
	_small_btn(btn_row, "↓",     _move_beat_down)

func _left_hdr(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
	parent.add_child(lbl)

# ─────────────────────────────────────────────────────────────
# Language chip strip (left panel)
# ─────────────────────────────────────────────────────────────
func _rebuild_lang_chips() -> void:
	for child in _lang_chips_hbox.get_children():
		child.queue_free()
	for lang: String in _languages:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 0)
		_lang_chips_hbox.add_child(chip)

		var lbl := Button.new()
		lbl.text = lang.to_upper()
		lbl.flat = true
		lbl.mouse_filter = MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
		chip.add_child(lbl)

		if lang != "en":
			var rm := Button.new()
			rm.text = "×"
			rm.flat = true
			rm.custom_minimum_size = Vector2(20, 0)
			rm.add_theme_font_size_override("font_size", 13)
			rm.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 0.85))
			var lang_copy: String = lang
			rm.pressed.connect(func() -> void: _remove_language(lang_copy))
			chip.add_child(rm)

		# Small gap between chips
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(4, 0)
		_lang_chips_hbox.add_child(spacer)

# ─────────────────────────────────────────────────────────────
# Right panel + field build
# ─────────────────────────────────────────────────────────────
func _build_right_panel(parent: Control) -> void:
	var right := Control.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(right)

	_no_beat_lbl = Label.new()
	_no_beat_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_no_beat_lbl.text = "Select a beat from the list"
	_no_beat_lbl.add_theme_font_size_override("font_size", 20)
	_no_beat_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	right.add_child(_no_beat_lbl)

	_fields_scroll = ScrollContainer.new()
	_fields_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fields_scroll.visible = false
	right.add_child(_fields_scroll)

	_fields_vbox = VBoxContainer.new()
	_fields_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fields_vbox.add_theme_constant_override("separation", 3)
	_fields_scroll.add_child(_fields_vbox)

	_build_fields()

func _build_fields() -> void:
	var v: VBoxContainer = _fields_vbox

	# ── Dialogue ──────────────────────────────────────────────
	_section(v, "DIALOGUE")
	_f_comment = _row_le(v, "Comment", "Dev note (not shown in-game)")
	_f_hidden  = _row_cb(v, "Hidden", "Skip this beat during playback (keeps it in the file)")

	# Speaker area (dynamic — rebuilt by _rebuild_locale_ui)
	_speaker_area = VBoxContainer.new()
	_speaker_area.add_theme_constant_override("separation", 2)
	v.add_child(_speaker_area)

	# Text area (dynamic — rebuilt by _rebuild_locale_ui)
	_text_area = VBoxContainer.new()
	_text_area.add_theme_constant_override("separation", 2)
	v.add_child(_text_area)

	_rebuild_locale_ui()

	# ── Visuals ───────────────────────────────────────────────
	_section(v, "VISUALS")
	_f_background = _row_le(v, "Background", "res://path  |  'null' to clear  |  empty = keep")
	_add_browse(_f_background,
		PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Image Files"]),
		"res://assets/textures/vn/backgrounds/")
	_add_image_preview(_f_background)

	var bgc_row := HBoxContainer.new()
	bgc_row.add_theme_constant_override("separation", 6)
	v.add_child(bgc_row)
	var bgc_lbl := Label.new()
	bgc_lbl.text = "BG Colour"
	bgc_lbl.custom_minimum_size.x = 140.0
	bgc_lbl.add_theme_font_size_override("font_size", 14)
	bgc_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	bgc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bgc_row.add_child(bgc_lbl)
	_f_bg_color = LineEdit.new()
	_f_bg_color.placeholder_text = "#000000  (hex — applied when background is cleared)"
	_f_bg_color.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_f_bg_color.add_theme_font_size_override("font_size", 14)
	bgc_row.add_child(_f_bg_color)
	var bgc_black_btn := Button.new()
	bgc_black_btn.text = "⬛ Black"
	bgc_black_btn.custom_minimum_size = Vector2(80, 0)
	bgc_black_btn.pressed.connect(func() -> void:
		_f_bg_color.text = "#000000"
		_on_field_changed())
	bgc_row.add_child(bgc_black_btn)

	_f_video = _row_le(v, "Video", "res://path/to/clip.mp4  |  empty = none")
	_add_browse(_f_video,
		PackedStringArray(["*.mp4 ; Video Files"]),
		"res://assets/video/")

	var char_row := HBoxContainer.new()
	char_row.add_theme_constant_override("separation", 6)
	v.add_child(char_row)
	var char_lbl := Label.new()
	char_lbl.text = "Characters"
	char_lbl.add_theme_font_size_override("font_size", 14)
	char_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	char_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	char_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	char_row.add_child(char_lbl)
	_f_linger_chars = CheckBox.new()
	_f_linger_chars.text = "Use previous characters"
	_f_linger_chars.add_theme_font_size_override("font_size", 13)
	_f_linger_chars.toggled.connect(func(_b: bool) -> void:
		_chars_vbox.modulate.a = 0.3 if _f_linger_chars.button_pressed else 1.0
		_on_field_changed())
	char_row.add_child(_f_linger_chars)
	var copy_chars_btn := Button.new()
	copy_chars_btn.text = "Copy"
	copy_chars_btn.custom_minimum_size = Vector2(56, 26)
	copy_chars_btn.add_theme_font_size_override("font_size", 13)
	copy_chars_btn.pressed.connect(_copy_chars)
	char_row.add_child(copy_chars_btn)
	var paste_chars_btn := Button.new()
	paste_chars_btn.text = "Paste"
	paste_chars_btn.custom_minimum_size = Vector2(56, 26)
	paste_chars_btn.add_theme_font_size_override("font_size", 13)
	paste_chars_btn.pressed.connect(_paste_chars)
	char_row.add_child(paste_chars_btn)
	var add_char_btn := Button.new()
	add_char_btn.text = "+ Add Slot"
	add_char_btn.custom_minimum_size = Vector2(90, 26)
	add_char_btn.add_theme_font_size_override("font_size", 14)
	add_char_btn.pressed.connect(_add_character_row)
	char_row.add_child(add_char_btn)
	_chars_vbox = VBoxContainer.new()
	_chars_vbox.add_theme_constant_override("separation", 3)
	v.add_child(_chars_vbox)

	_f_dim_others   = _row_cb(v, "Dim others",   "Dim characters not listed in this beat")
	_f_hide_dialog  = _row_cb(v, "Hide dialog",  "Hide the message box panel for this beat (player still clicks to advance)")

	# ── NSFW flag ─────────────────────────────────────────────
	var nsfw_hbox := HBoxContainer.new()
	nsfw_hbox.add_theme_constant_override("separation", 6)
	v.add_child(nsfw_hbox)
	var nsfw_lbl := Label.new()
	nsfw_lbl.text = "NSFW"
	nsfw_lbl.custom_minimum_size.x = 140.0
	nsfw_lbl.add_theme_font_size_override("font_size", 14)
	nsfw_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	nsfw_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nsfw_hbox.add_child(nsfw_lbl)
	_f_nsfw = OptionButton.new()
	_f_nsfw.add_item("Both")
	_f_nsfw.add_item("Safe")
	_f_nsfw.add_item("NSFW")
	_f_nsfw.selected = 0
	_f_nsfw.add_theme_font_size_override("font_size", 14)
	_f_nsfw.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	nsfw_hbox.add_child(_f_nsfw)
	var nsfw_hint := Label.new()
	nsfw_hint.text = "Filter: show this beat only for matching NSFW setting"
	nsfw_hint.add_theme_font_size_override("font_size", 13)
	nsfw_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	nsfw_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nsfw_hbox.add_child(nsfw_hint)

	# ── Animation ─────────────────────────────────────────────
	_section(v, "ANIMATION")
	var anim_hbox := HBoxContainer.new()
	anim_hbox.add_theme_constant_override("separation", 8)
	v.add_child(anim_hbox)
	var anim_lbl := Label.new()
	anim_lbl.text = "Play Animation"
	anim_lbl.custom_minimum_size.x = 140.0
	anim_lbl.add_theme_font_size_override("font_size", 14)
	anim_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	anim_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	anim_hbox.add_child(anim_lbl)
	_f_animation = OptionButton.new()
	_f_animation.add_theme_font_size_override("font_size", 14)
	for entry: Dictionary in ANIMATION_REGISTRY:
		_f_animation.add_item(entry["label"] as String)
	_f_animation.selected = 0
	_f_animation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_f_animation.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	anim_hbox.add_child(_f_animation)
	var anim_hint := Label.new()
	anim_hint.text = "Fires and continues; add Wait to hold on this beat"
	anim_hint.add_theme_font_size_override("font_size", 13)
	anim_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	anim_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	anim_hbox.add_child(anim_hint)

	# ── Audio ─────────────────────────────────────────────────
	_section(v, "AUDIO")
	_f_music = _row_le(v, "Music", "res://path  |  'null' to stop")
	_add_browse(_f_music,
		PackedStringArray(["*.mp3,*.ogg,*.wav ; Audio Files"]),
		"res://assets/audio/")
	_add_audio_preview(_f_music)
	_f_music_fade_in  = _row_sb(v, "Music Fade In",  0.0, 30.0, 0.001, "seconds  (0 = instant)")
	_f_music_fade_out = _row_sb(v, "Music Fade Out", 0.0, 30.0, 0.001, "seconds  (0 = instant)")
	_f_sfx = _row_le(v, "SFX", "res://path")
	_add_browse(_f_sfx,
		PackedStringArray(["*.mp3,*.ogg,*.wav ; Audio Files"]),
		"res://assets/audio/")
	_add_audio_preview(_f_sfx)
	_f_sfx_volume = _row_sb(v, "SFX Volume", 0.0, 200.0, 1.0, "% (100 = normal)")
	_f_sfx_volume.value = 100.0

	# ── Timing ────────────────────────────────────────────────
	_section(v, "TIMING")
	_f_wait           = _row_sb(v, "Wait",           0.0,  60.0,  0.001, "seconds  (0 = click to advance)")

	# ── Fade ──────────────────────────────────────────────────
	_section(v, "FADE")
	_f_fade_out       = _row_sb(v, "Fade Out",       0.0,  10.0,  0.001, "seconds")
	_f_fade_in        = _row_sb(v, "Fade In",        0.0,  10.0,  0.001, "seconds")
	_f_fade_color     = _row_le(v, "Fade Color",     "#000000")

	# ── Flash ─────────────────────────────────────────────────
	_section(v, "FLASH")
	_f_flash_color    = _row_le(v, "Flash Color",    "#ffffff")
	_f_flash_count    = _row_sb(v, "Flash Count",    0.0,  20.0,  1.0, "times")
	_f_flash_duration = _row_sb(v, "Flash Duration", 0.0,   5.0,  0.001, "seconds each")
	_f_flash_delay    = _row_sb(v, "Flash Delay",    0.0,   5.0,  0.001, "seconds between")
	_f_flash_target   = _row_le(v, "Flash Target",   "screen | all | far_left,left,center,right,far_right")

	# ── Shake ─────────────────────────────────────────────────
	_section(v, "SHAKE")
	_f_shake          = _row_le(v, "Char Shake",     "all | far_left,left,center,right,far_right")
	_f_shake_magnitude = _row_sb(v, "Shake Magnitude", 0.0, 80.0, 1.0, "pixels")
	_f_shake_magnitude.value = 8.0
	_f_shake_screen   = _row_sb(v, "Screen Shake",   0.0, 100.0, 1.0, "0 = off  |  >0 = magnitude")

	# ── Ken Burns ─────────────────────────────────────────────
	_section(v, "KEN BURNS  (zoom/pan on background)")
	_f_kb_zoom     = _row_sb(v, "Zoom",     0.5,   5.0,   0.01,  "1.0 = no zoom")
	_f_kb_pan_x    = _row_sb(v, "Pan X",  -800.0, 800.0,  1.0,   "pixels")
	_f_kb_pan_y    = _row_sb(v, "Pan Y",  -800.0, 800.0,  1.0,   "pixels")
	_f_kb_duration = _row_sb(v, "Duration",  0.0,  60.0,  0.001, "seconds")
	_f_kb_zoom.value = 1.0

	# ── Battle ────────────────────────────────────────────────
	_section(v, "BATTLE")
	_f_start_battle = _row_cb(v, "Start Battle", "Launch battle (VS AI) immediately after this beat's effects")
	_f_player1_name = _row_le(v, "Player 1 Name", "e.g. Nex  (blank = keep default)")
	_f_player2_name = _row_le(v, "Player 2 Name", "e.g. Midnight Shadow  (blank = keep default)")
	_f_portrait_p1 = _row_le(v, "Portrait P1", "res://assets/textures/ui/portraits/...")
	_add_browse(_f_portrait_p1, PackedStringArray(["*.png,*.jpg,*.webp;Image"]), "res://assets/textures/ui/portraits/")
	_f_portrait_p1_offset_x = _row_sb(v, "P1 Portrait Offset X", -800.0, 800.0, 1.0, "pixels — positive = move right (toward center)")
	_f_portrait_p1_offset_y = _row_sb(v, "P1 Portrait Offset Y", -720.0, 720.0, 1.0, "pixels — positive = move down")
	_f_portrait_p1_size     = _row_sb(v, "P1 Portrait Size",       0.3,   3.0,  0.05, "multiplier  (1.0 = default height)")
	_f_portrait_p1_size.value = 1.0
	_f_portrait_p2 = _row_le(v, "Portrait P2", "res://assets/textures/ui/portraits/...")
	_add_browse(_f_portrait_p2, PackedStringArray(["*.png,*.jpg,*.webp;Image"]), "res://assets/textures/ui/portraits/")
	_f_portrait_p2_offset_x = _row_sb(v, "P2 Portrait Offset X", -800.0, 800.0, 1.0, "pixels — positive = move left (more visible)")
	_f_portrait_p2_offset_y = _row_sb(v, "P2 Portrait Offset Y", -720.0, 720.0, 1.0, "pixels — positive = move up")
	_f_portrait_p2_size     = _row_sb(v, "P2 Portrait Size",       0.3,   3.0,  0.05, "multiplier  (1.0 = default height)")
	_f_portrait_p2_size.value = 1.0
	_f_battle_bgm = _row_le(v, "Battle BGM", "res://assets/audio/bgm_boss_1.mp3  (blank = use default)")
	_add_browse(_f_battle_bgm, PackedStringArray(["*.mp3,*.ogg,*.wav;Audio"]), "res://assets/audio/")
	_f_battle_bgm_vol = _row_sb(v, "BGM Volume", 0.0, 200.0, 1.0, "100 = normal  |  50 = half")
	_f_battle_bgm_vol.value = 100.0
	_f_on_win  = _row_le(v, "On Win",  "path to VN JSON — played if player wins")
	_add_browse(_f_on_win,  PackedStringArray(["*.json;JSON"]), "res://campaign/scenes/")
	_f_on_lose = _row_le(v, "On Lose", "path to VN JSON — played if player loses  |  'game_over' = show game-over screen")
	_add_browse(_f_on_lose, PackedStringArray(["*.json;JSON"]), "res://campaign/scenes/")

	# ── Enemy Deck ────────────────────────────────────────────
	_section(v, "ENEMY DECK  (optional — leave empty to use random pool)")
	var hint_lbl := Label.new()
	hint_lbl.text = "Specify exactly which cards the enemy places. Empty = random from full pool."
	hint_lbl.add_theme_font_size_override("font_size", 12)
	hint_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(hint_lbl)
	_enemy_chars_chips = _build_enemy_deck_row(v, "Characters", "character")
	_enemy_traps_chips = _build_enemy_deck_row(v, "Traps", "trap")
	_enemy_tech_chips  = _build_enemy_deck_row(v, "Tech", "tech")

	# ── Union Summon Flags ────────────────────────────────────
	_section(v, "UNION SUMMON")
	_f_ai_union_enabled = _row_cb(v, "AI Can Union Summon",
		"Uncheck to prevent AI from union summoning this battle")
	_f_ai_union_enabled.button_pressed = true
	_f_player_union_enabled = _row_cb(v, "Player Can Union Summon",
		"Uncheck to prevent the player from union summoning this battle")
	_f_player_union_enabled.button_pressed = true

	# ── AI Personality ────────────────────────────────────────
	_section(v, "AI PERSONALITY")
	var _def_names: Array = ["Random","Frontline","Fortress","Watch Tower","Mine Field",
		"Tomb Trap","Bait Trap","Diagonal Shield","Cluster Defender","Checker",
		"Straightforward","Midwit","Symmetric Defender","Random Defender","Religious",
		"Zoro","Helios","Helios 2","Zoro 2","Tomb Trap (Hard)","Frontline (Hard)"]
	var _off_names: Array = ["Random","Center Hoarder","Border Guard","Corner Assassin",
		"Melee Fighter","Sniper","Leftist","Rightist","X Sabre","Crusader",
		"Column Crusher","Row Ripper","Revealed Hunter","Explorer","Tinkerer",
		"Berserker","Shadow Lurker","Sleeping Dragon","Rambo","Spy",
		"X Alien","Technophobia","Witchhunter"]
	var _soc_names: Array = ["Random","Degen","Talkative","Fiddly","Flirty","Bully",
		"Fun Guy","Daredevil","Vengeful","Paranoid","Skeptical","Ungrateful",
		"Monk","Eager","Introvert"]
	_f_ai_pers_def = _row_opt(v, "Defensive", _def_names,
		"Formation style — Random lets AI pick each match")
	_f_ai_pers_off = _row_opt(v, "Offensive", _off_names,
		"Attack target preference — Random lets AI pick each match")
	_f_ai_pers_soc = _row_opt(v, "Social", _soc_names,
		"Bluff & emoji reaction style — Random lets AI pick each match")

	# ── Forced Cell Placements ────────────────────────────────
	_section(v, "PLAYER FORCED CELLS  (tap a cell to assign / remove a card)")
	_player_forced_gc = _build_forced_grid(_player_forced_grid)
	v.add_child(_player_forced_gc)

	_section(v, "AI FORCED CELLS  (tap a cell to assign / remove a card)")
	_ai_forced_gc = _build_forced_grid(_ai_forced_grid)
	v.add_child(_ai_forced_gc)

	# ── Union Card Reference ───────────────────────────────────
	_section(v, "UNION CARD REFERENCE  (tap to highlight zone on grids above)")
	_build_union_gallery_section(v)

	# ── Center Text ───────────────────────────────────────────
	_section(v, "CENTER TEXT  (auto-advances after fade; hides dialog)")
	_f_center_text = _row_le(v, "Center text", "White text centered on screen; auto fade-in → hold → fade-out → next beat")
	_f_center_text.text_changed.connect(func(_s: String) -> void: _on_field_changed())
	_f_center_text_size     = _row_sb(v, "Font size",    8.0, 200.0, 1.0, "")
	_f_center_text_size.value = 48.0
	_f_center_text_fade_in  = _row_sb(v, "Fade in (s)",  0.0,  10.0, 0.1, "")
	_f_center_text_fade_in.value = 0.8
	_f_center_text_hold     = _row_sb(v, "Hold (s)",     0.0,  30.0, 0.1, "")
	_f_center_text_hold.value = 1.5
	_f_center_text_fade_out = _row_sb(v, "Fade out (s)", 0.0,  10.0, 0.1, "")
	_f_center_text_fade_out.value = 0.8

	# ── Credits ───────────────────────────────────────────────
	_section(v, "CREDITS")
	_f_go_to_credits  = _row_cb(v, "Go to Credits", "Transition to the credits scene after this beat")
	_f_credits_target = _row_opt(v, "Credits scene", ["Normal", "Demo"], "which credits scene to play")

	# ── Special Command ───────────────────────────────────────
	_section(v, "SPECIAL COMMAND")
	_f_call_scene = _row_opt(v, "Call scene",
			["(none)", "Credits", "Credits Demo", "Photo Scatter"],
			"Change to this scene after the beat completes")

	# ── Battle Reward ─────────────────────────────────────────
	_section(v, "BATTLE REWARD  (on win)")
	var rwd_hint := Label.new()
	rwd_hint.text = "Items granted to the player when they win this battle."
	rwd_hint.add_theme_font_size_override("font_size", 12)
	rwd_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	rwd_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(rwd_hint)

	var rwd_hdr := HBoxContainer.new()
	rwd_hdr.add_theme_constant_override("separation", 6)
	v.add_child(rwd_hdr)
	var rwd_hdr_lbl := Label.new()
	rwd_hdr_lbl.text = "Rewards"
	rwd_hdr_lbl.add_theme_font_size_override("font_size", 13)
	rwd_hdr_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	rwd_hdr_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rwd_hdr_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rwd_hdr.add_child(rwd_hdr_lbl)
	var rwd_add_btn := Button.new()
	rwd_add_btn.text = "+ Add Reward"
	rwd_add_btn.custom_minimum_size = Vector2(110, 26)
	rwd_add_btn.add_theme_font_size_override("font_size", 13)
	rwd_add_btn.pressed.connect(func() -> void:
		if _selected_idx < 0: return
		_add_reward_row_from({})
		_on_field_changed())
	rwd_hdr.add_child(rwd_add_btn)

	_reward_rows_vbox = VBoxContainer.new()
	_reward_rows_vbox.add_theme_constant_override("separation", 3)
	v.add_child(_reward_rows_vbox)

	# ── Dungeon Call ───────────────────────────────────────────
	_section(v, "DUNGEON CALL")
	_f_call_dungeon = _row_cb(v, "Call Dungeon", "launch dungeon map from this beat")
	_f_call_dungeon.toggled.connect(func(_b: bool) -> void: _on_field_changed())
	_f_dungeon_mode_filter = _row_opt(v, "Mode filter",
		["All", "Daily Dungeon", "Story Mode"],
		"editor UX only — not saved")
	_f_dungeon_mode_filter.item_selected.connect(func(_i: int) -> void:
		_populate_dungeon_call_picker())
	_f_dungeon_opt = _row_opt(v, "Dungeon", [], "")
	_f_dungeon_opt.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	_f_dungeon_on_win  = _row_le(v, "On Win",  "VN JSON path played when dungeon is cleared")
	_add_browse(_f_dungeon_on_win,  PackedStringArray(["*.json;JSON"]), "res://campaign/scenes/")
	_f_dungeon_on_win.text_changed.connect(func(_s: String) -> void: _on_field_changed())
	_f_dungeon_on_lose = _row_le(v, "On Lose", "VN JSON path played on any battle loss")
	_add_browse(_f_dungeon_on_lose, PackedStringArray(["*.json;JSON"]), "res://campaign/scenes/")
	_f_dungeon_on_lose.text_changed.connect(func(_s: String) -> void: _on_field_changed())

	_connect_static_signals()

func _connect_static_signals() -> void:
	var ch := _on_field_changed
	_f_comment.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_background.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_video.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_music.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_sfx.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_fade_color.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_flash_color.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_flash_target.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_shake.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_hidden.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_dim_others.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_hide_dialog.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_bg_color.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_nsfw.item_selected.connect(func(_i: int) -> void: ch.call())
	_f_animation.item_selected.connect(func(_i: int) -> void: ch.call())
	_f_start_battle.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_go_to_credits.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_credits_target.item_selected.connect(func(_i: int) -> void: ch.call())
	_f_call_scene.item_selected.connect(func(_i: int) -> void: ch.call())
	_f_ai_union_enabled.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_player_union_enabled.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_ai_pers_def.item_selected.connect(func(_i: int) -> void: ch.call())
	_f_ai_pers_off.item_selected.connect(func(_i: int) -> void: ch.call())
	_f_ai_pers_soc.item_selected.connect(func(_i: int) -> void: ch.call())
	_f_player1_name.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_player2_name.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_portrait_p1.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_portrait_p2.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_portrait_p1_offset_x.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_portrait_p1_offset_y.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_portrait_p1_size.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_portrait_p2_offset_x.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_portrait_p2_offset_y.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_portrait_p2_size.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_battle_bgm.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_battle_bgm_vol.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_on_win.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_on_lose.text_changed.connect(func(_s: String) -> void: ch.call())
	for sp: SpinBox in [
		_f_music_fade_in, _f_music_fade_out, _f_sfx_volume,
		_f_wait, _f_fade_in, _f_fade_out,
		_f_flash_count, _f_flash_duration, _f_flash_delay,
		_f_shake_magnitude, _f_shake_screen,
		_f_kb_zoom, _f_kb_pan_x, _f_kb_pan_y, _f_kb_duration,
		_f_center_text_size, _f_center_text_fade_in, _f_center_text_hold, _f_center_text_fade_out,
	]:
		sp.value_changed.connect(func(_v: float) -> void: ch.call())

# ─────────────────────────────────────────────────────────────
# Dungeon call picker
# ─────────────────────────────────────────────────────────────
func _populate_dungeon_call_picker() -> void:
	_f_dungeon_opt.clear()
	_dungeon_filtered_ids.clear()
	var filter_mode: String = ""
	if _f_dungeon_mode_filter != null:
		match _f_dungeon_mode_filter.selected:
			1: filter_mode = "daily_dungeon"
			2: filter_mode = "story_mode"
	var all_ids: Array = DailyDungeonManager.get_all_layout_ids()
	for did: String in all_ids:
		if filter_mode != "":
			var layout_data: Variant = DailyDungeonManager.get_layout(did)
			var lm: String = (layout_data as Dictionary).get("mode", "daily_dungeon")
			if lm != filter_mode:
				continue
		_dungeon_filtered_ids.append(did)
		_f_dungeon_opt.add_item(did)
	if _dungeon_filtered_ids.is_empty():
		_f_dungeon_opt.add_item("(no layouts)")

# ─────────────────────────────────────────────────────────────
# Dynamic locale UI (speaker + text tabs)
# ─────────────────────────────────────────────────────────────
func _rebuild_locale_ui() -> void:
	# Clear old controls
	for child in _speaker_area.get_children():
		child.queue_free()
	for child in _text_area.get_children():
		child.queue_free()
	_speaker_fields.clear()
	_speaker_tabs.clear()
	_text_fields.clear()
	_text_tabs.clear()
	_text_tag_rows.clear()

	# ── Speaker strip ──────────────────────────────
	var sp_strip := HBoxContainer.new()
	sp_strip.add_theme_constant_override("separation", 4)
	_speaker_area.add_child(sp_strip)

	var sp_lbl := Label.new()
	sp_lbl.text = "Speaker"
	sp_lbl.custom_minimum_size.x = 100.0
	sp_lbl.add_theme_font_size_override("font_size", 14)
	sp_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	sp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sp_strip.add_child(sp_lbl)

	for i: int in range(_languages.size()):
		var lang: String = _languages[i]
		var tab := _make_tab_btn(lang.to_upper(), i, true)
		_speaker_tabs.append(tab)
		sp_strip.add_child(tab)

	for i: int in range(_languages.size()):
		var le := LineEdit.new()
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.add_theme_font_size_override("font_size", 15)
		le.visible = (i == _speaker_locale_idx)
		_speaker_fields.append(le)
		_speaker_area.add_child(le)
		le.text_changed.connect(func(_s: String) -> void: _on_field_changed(); _update_tab_colors())

	# ── Text strip ────────────────────────────────
	var tx_strip := HBoxContainer.new()
	tx_strip.add_theme_constant_override("separation", 4)
	_text_area.add_child(tx_strip)

	var tx_lbl := Label.new()
	tx_lbl.text = "Text"
	tx_lbl.custom_minimum_size.x = 100.0
	tx_lbl.add_theme_font_size_override("font_size", 14)
	tx_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	tx_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tx_strip.add_child(tx_lbl)

	for i: int in range(_languages.size()):
		var lang: String = _languages[i]
		var tab := _make_tab_btn(lang.to_upper(), i, false)
		_text_tabs.append(tab)
		tx_strip.add_child(tab)

	for i: int in range(_languages.size()):
		var te := _make_textedit(_text_area)
		te.visible = (i == _text_locale_idx)
		_text_fields.append(te)
		var tags: HBoxContainer = _color_tags(_text_area, te)
		tags.visible = (i == _text_locale_idx)
		_text_tag_rows.append(tags)
		te.text_changed.connect(func() -> void: _on_field_changed(); _update_tab_colors())

	_update_tab_colors()
	# Re-populate if a beat is selected
	if _selected_idx >= 0 and _selected_idx < _beats.size():
		_populate_locale_fields(_beats[_selected_idx])

func _make_tab_btn(label: String, idx: int, is_speaker: bool) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.flat = true
	btn.custom_minimum_size = Vector2(52, 30)
	btn.add_theme_font_size_override("font_size", 14)
	if is_speaker:
		btn.pressed.connect(func() -> void: _set_speaker_locale(idx))
	else:
		btn.pressed.connect(func() -> void: _set_text_locale(idx))
	return btn

func _set_speaker_locale(idx: int) -> void:
	_speaker_locale_idx = idx
	for i: int in range(_speaker_fields.size()):
		(_speaker_fields[i] as LineEdit).visible = (i == idx)
	_update_tab_colors()

func _set_text_locale(idx: int) -> void:
	_text_locale_idx = idx
	for i: int in range(_text_fields.size()):
		(_text_fields[i] as TextEdit).visible    = (i == idx)
		(_text_tag_rows[i] as HBoxContainer).visible = (i == idx)
	_update_tab_colors()

func _update_tab_colors() -> void:
	for i: int in range(_speaker_tabs.size()):
		var btn: Button = _speaker_tabs[i]
		var le: LineEdit = _speaker_fields[i]
		_style_tab(btn, i == _speaker_locale_idx, not le.text.is_empty())
	for i: int in range(_text_tabs.size()):
		var btn: Button = _text_tabs[i]
		var te: TextEdit = _text_fields[i]
		_style_tab(btn, i == _text_locale_idx, not te.text.is_empty())

func _style_tab(btn: Button, is_active: bool, has_content: bool) -> void:
	if is_active:
		btn.add_theme_color_override("font_color",         Color(1.0, 1.0, 1.0, 1.0))
		btn.add_theme_color_override("font_hover_color",   Color(1.0, 1.0, 1.0, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_width_bottom = 2
		sb.border_color = Color(0.4, 0.8, 1.0, 1.0)
		sb.content_margin_bottom = 4.0
		btn.add_theme_stylebox_override("normal",  sb)
		btn.add_theme_stylebox_override("hover",   sb)
		btn.add_theme_stylebox_override("pressed", sb)
	elif has_content:
		btn.add_theme_color_override("font_color",         Color(0.7, 0.7, 0.7, 0.85))
		btn.add_theme_color_override("font_hover_color",   Color(0.9, 0.9, 0.9, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7, 0.85))
		btn.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	else:
		btn.add_theme_color_override("font_color",         Color(0.38, 0.38, 0.38, 0.9))
		btn.add_theme_color_override("font_hover_color",   Color(0.6, 0.6, 0.6, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.38, 0.38, 0.38, 0.9))
		btn.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())

# ─────────────────────────────────────────────────────────────
# UI builder helpers
# ─────────────────────────────────────────────────────────────
func _section(parent: Control, title: String) -> void:
	parent.add_child(HSeparator.new())
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.65))
	parent.add_child(lbl)

func _field_lbl(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	parent.add_child(lbl)

func _row_le(parent: Control, label: String, placeholder: String) -> LineEdit:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size.x = 140.0
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)
	var le := LineEdit.new()
	le.placeholder_text = placeholder
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.add_theme_font_size_override("font_size", 15)
	hbox.add_child(le)
	return le

func _row_sb(parent: Control, label: String, mn: float, mx: float, step: float, hint: String) -> SpinBox:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size.x = 140.0
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)
	var sb := SpinBox.new()
	sb.min_value = mn; sb.max_value = mx; sb.step = step
	sb.custom_minimum_size.x = 110.0
	hbox.add_child(sb)
	if not hint.is_empty():
		var hl := Label.new()
		hl.text = hint
		hl.add_theme_font_size_override("font_size", 13)
		hl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
		hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(hl)
	return sb

func _row_cb(parent: Control, label: String, hint: String) -> CheckBox:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size.x = 140.0
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)
	var cb := CheckBox.new()
	hbox.add_child(cb)
	if not hint.is_empty():
		var hl := Label.new()
		hl.text = hint
		hl.add_theme_font_size_override("font_size", 13)
		hl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
		hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(hl)
	return cb

func _row_opt(parent: Control, label: String, items: Array, hint: String = "") -> OptionButton:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size.x = 140.0
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.add_theme_font_size_override("font_size", 13)
	for item: Variant in items:
		opt.add_item(item as String)
	opt.selected = 0
	hbox.add_child(opt)
	if not hint.is_empty():
		var hl := Label.new()
		hl.text = hint
		hl.add_theme_font_size_override("font_size", 12)
		hl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.45))
		hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(hl)
	return opt

func _select_opt(opt: OptionButton, value: String) -> void:
	if value == "":
		opt.selected = 0
		return
	for i in range(opt.item_count):
		if opt.get_item_text(i) == value:
			opt.selected = i
			return
	opt.selected = 0

func _make_textedit(parent: Control) -> TextEdit:
	var te := TextEdit.new()
	te.custom_minimum_size = Vector2(0, 72)
	te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	te.add_theme_font_size_override("font_size", 16)
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	parent.add_child(te)
	return te

func _color_tags(parent: Control, target: TextEdit) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 2)
	parent.add_child(hbox)
	for cp: Array in COLOR_PRESETS:
		var btn := Button.new()
		btn.text = cp[0] as String
		btn.custom_minimum_size = Vector2(24, 20)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color.html(cp[1] as String))
		var hex: String = cp[1] as String
		btn.pressed.connect(func() -> void: _insert_color_tag(target, hex))
		hbox.add_child(btn)
	var hint := Label.new()
	hint.text = "← color tags"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(hint)
	return hbox

func _small_btn(parent: Control, label: String, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size.y = 28
	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(cb)
	parent.add_child(btn)

# ─────────────────────────────────────────────────────────────
# Color tag insertion
# ─────────────────────────────────────────────────────────────
func _insert_color_tag(te: TextEdit, hex: String) -> void:
	te.grab_focus()
	var sel: String = te.get_selected_text()
	if not sel.is_empty():
		te.delete_selection()
		te.insert_text_at_caret("[color=%s]%s[/color]" % [hex, sel])
	else:
		te.insert_text_at_caret("[color=%s][/color]" % hex)
		te.set_caret_column(te.get_caret_column() - 8)

# ─────────────────────────────────────────────────────────────
# File browser helpers
# ─────────────────────────────────────────────────────────────
func _browse(target: LineEdit, filters: PackedStringArray, start_dir: String) -> void:
	_browse_target = target
	_file_dialog.filters = filters
	_file_dialog.current_dir = start_dir
	_file_dialog.popup_centered(Vector2(960, 620))

func _on_file_dialog_selected(path: String) -> void:
	if _browse_target != null:
		_browse_target.text = path
		_browse_target = null
		_on_field_changed()

func _add_browse(le: LineEdit, filters: PackedStringArray, start_dir: String) -> void:
	var btn := Button.new()
	btn.text = "..."
	btn.custom_minimum_size = Vector2(34, 0)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(func() -> void: _browse(le, filters, start_dir))
	le.get_parent().add_child(btn)

func _add_audio_preview(le: LineEdit) -> void:
	var play_btn := Button.new()
	play_btn.text = "▶"
	play_btn.custom_minimum_size = Vector2(30, 0)
	play_btn.add_theme_font_size_override("font_size", 13)
	play_btn.pressed.connect(func() -> void: _preview_audio(le.text.strip_edges()))
	le.get_parent().add_child(play_btn)
	var stop_btn := Button.new()
	stop_btn.text = "■"
	stop_btn.custom_minimum_size = Vector2(30, 0)
	stop_btn.add_theme_font_size_override("font_size", 13)
	stop_btn.pressed.connect(func() -> void: if _preview_player != null: _preview_player.stop())
	le.get_parent().add_child(stop_btn)

func _add_image_preview(le: LineEdit) -> void:
	var btn := Button.new()
	btn.text = "Img"
	btn.custom_minimum_size = Vector2(36, 0)
	btn.add_theme_font_size_override("font_size", 13)
	btn.pressed.connect(func() -> void: _preview_image(le.text.strip_edges()))
	le.get_parent().add_child(btn)

func _preview_audio(path: String) -> void:
	if _preview_player == null:
		return
	if path.is_empty() or path == "null":
		_status_lbl.text = "No audio path set."
		return
	if not ResourceLoader.exists(path):
		_status_lbl.text = "Audio not found: " + path.get_file()
		return
	var stream: Variant = load(path)
	if not stream is AudioStream:
		_status_lbl.text = "Not an audio file: " + path.get_file()
		return
	_preview_player.stream = stream as AudioStream
	_preview_player.stop()
	_preview_player.play()
	_status_lbl.text = "Playing: " + path.get_file()

func _preview_image(path: String) -> void:
	if _img_popup == null:
		return
	if path.is_empty() or path == "null":
		_status_lbl.text = "No image path set."
		return
	if not ResourceLoader.exists(path):
		_status_lbl.text = "Image not found: " + path.get_file()
		return
	var tex: Variant = load(path)
	if not tex is Texture2D:
		_status_lbl.text = "Not an image: " + path.get_file()
		return
	_img_popup_tex.texture = tex as Texture2D
	_img_popup.popup_centered(Vector2(820, 620))

# ─────────────────────────────────────────────────────────────
# File scanning / loading
# ─────────────────────────────────────────────────────────────
func _scan_files() -> void:
	_file_list.clear()
	var dir := DirAccess.open(SCENES_DIR)
	if dir == null:
		_status_lbl.text = "ERROR: cannot open " + SCENES_DIR
		return
	dir.list_dir_begin()
	var files: Array = []
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json") and fname != "languages.json":
			files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	files.sort()
	for f: String in files:
		_file_list.add_item(f)
	_refresh_file_list_colors()

func _load_vn_bug_tags() -> Dictionary:
	if not FileAccess.file_exists(BUG_TAGS_PATH):
		return {}
	var f := FileAccess.open(BUG_TAGS_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}

func _save_vn_bug_tags() -> void:
	var f := FileAccess.open(BUG_TAGS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_bug_tags, "\t"))
	f.close()

func _resolve_bug_tag() -> void:
	if _file_path.is_empty() or _selected_idx < 0:
		_status_lbl.text = "Select a beat to resolve."
		return
	var file_tags: Dictionary = _bug_tags.get(_file_path, {}) as Dictionary
	if not file_tags.has(str(_selected_idx)):
		_status_lbl.text = "No bug tag on beat #%d." % (_selected_idx + 1)
		return
	file_tags.erase(str(_selected_idx))
	if file_tags.is_empty():
		_bug_tags.erase(_file_path)
	else:
		_bug_tags[_file_path] = file_tags
	_save_vn_bug_tags()
	_refresh_beat_list()
	_refresh_file_list_colors()
	_bug_note_lbl.text = ""
	_status_lbl.text = "Bug resolved  —  beat #%d" % (_selected_idx + 1)

func _refresh_file_list_colors() -> void:
	for i: int in range(_file_list.item_count):
		var fpath: String = SCENES_DIR + _file_list.get_item_text(i)
		var is_dirty: bool = _file_cache.has(fpath) or (fpath == _file_path and _dirty)
		if is_dirty:
			_file_list.set_item_custom_bg_color(i, Color(0.5, 0.45, 0.0, 0.35))
		else:
			_file_list.set_item_custom_bg_color(i, Color(0.0, 0.0, 0.0, 0.0))
		var file_tags: Dictionary = _bug_tags.get(fpath, {}) as Dictionary
		if not file_tags.is_empty():
			_file_list.set_item_custom_fg_color(i, Color(1.0, 0.25, 0.25))
		else:
			_file_list.set_item_custom_fg_color(i, Color(1.0, 1.0, 1.0))

func _on_file_selected(idx: int) -> void:
	_load_file(SCENES_DIR + _file_list.get_item_text(idx))

func _load_file(path: String) -> void:
	# Stash unsaved state for the current file before switching away
	if not _file_path.is_empty() and _dirty:
		_file_cache[_file_path] = {
			"beats":    _beats.duplicate(true),
			"modified": _beat_modified.duplicate()
		}
	# Try restoring from in-memory cache first; fall back to disk
	if _file_cache.has(path):
		var cached: Dictionary = _file_cache[path]
		_file_path = path
		_beats = (cached["beats"] as Array).duplicate(true)
		_beat_modified = (cached["modified"] as Dictionary).duplicate()
		_dirty = true
	else:
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			_status_lbl.text = "ERROR: cannot open " + path.get_file()
			return
		var raw: String = f.get_as_text()
		f.close()
		var parsed: Variant = JSON.parse_string(raw)
		if not parsed is Array:
			_status_lbl.text = "ERROR: invalid JSON in " + path.get_file()
			return
		_file_path = path
		_beats = parsed
		_beat_modified.clear()
		_dirty = false
	_selected_idx = -1
	_anchor_idx = -1
	_char_rows.clear()
	_refresh_beat_list()
	_refresh_file_list_colors()
	_show_fields(false)
	if _bug_note_lbl != null:
		_bug_note_lbl.text = ""
	_status_lbl.text = "%s  (%d beats)%s" % [path.get_file(), _beats.size(), "  *" if _dirty else ""]

# ─────────────────────────────────────────────────────────────
# Beat list
# ─────────────────────────────────────────────────────────────
func _refresh_beat_list() -> void:
	_beat_list.clear()
	var tagged_beats: Dictionary = _bug_tags.get(_file_path, {}) as Dictionary
	for i: int in range(_beats.size()):
		_beat_list.add_item(_beat_summary(_beats[i], i))
		if _beat_modified.get(i, false):
			_beat_list.set_item_custom_bg_color(i, Color(0.5, 0.45, 0.0, 0.4))
		if tagged_beats.has(str(i)):
			_beat_list.set_item_custom_fg_color(i, Color(1.0, 0.25, 0.25))
			var note: String = str(tagged_beats[str(i)])
			_beat_list.set_item_tooltip(i, "[BUG]" if note.is_empty() else "[BUG] " + note)

func _beat_summary(beat: Dictionary, idx: int) -> String:
	var nsfw_tag: String = ""
	var nsfw_v: String = str(beat.get("nsfw", "both")).to_lower()
	if nsfw_v == "safe":
		nsfw_tag = "[S] "
	elif nsfw_v == "nsfw":
		nsfw_tag = "[N] "
	var hidden_tag: String = "[H] " if beat.get("hidden", false) else ""
	var prefix: String = "#%d %s%s" % [idx + 1, hidden_tag, nsfw_tag]
	if beat.has("comment"):
		return prefix + "// " + str(beat["comment"]).left(42)
	var tx: Variant = beat.get("text", "")
	var tx_str: String = ""
	if tx is Dictionary:
		tx_str = str(tx.get("en", tx.get(_languages[0], "")))
	elif tx != null:
		tx_str = str(tx)
	if not tx_str.is_empty():
		return prefix + tx_str.left(48)
	if beat.has("video"):
		return prefix + "[video: %s]" % str(beat["video"]).get_file()
	if beat.has("background"):
		var bg: Variant = beat["background"]
		return prefix + ("[bg: null]" if bg == null else "[bg: %s]" % str(bg).get_file())
	if beat.has("music"):
		var m: Variant = beat["music"]
		return prefix + "[music: %s]" % (str(m).get_file() if m != null else "stop")
	if beat.has("fade_out"):
		return prefix + "[fade out %.1fs]" % float(beat["fade_out"])
	if beat.has("fade_in"):
		return prefix + "[fade in %.1fs]" % float(beat["fade_in"])
	if beat.has("wait"):
		return prefix + "[wait %.1fs]" % float(beat["wait"])
	if beat.has("characters"):
		return prefix + "[characters]"
	if beat.get("start_battle", false):
		return prefix + "[start battle]"
	return prefix + "(empty)"

# ─────────────────────────────────────────────────────────────
# Beat selection / field display
# ─────────────────────────────────────────────────────────────
func _on_beat_selected(idx: int) -> void:
	_selected_idx = idx
	_anchor_idx = idx
	_populate_fields()
	_show_fields(true)

func _update_bug_note_label() -> void:
	if _bug_note_lbl == null:
		return
	if _selected_idx < 0 or _file_path.is_empty():
		_bug_note_lbl.text = ""
		return
	var file_tags: Dictionary = _bug_tags.get(_file_path, {}) as Dictionary
	if file_tags.has(str(_selected_idx)):
		var note: String = str(file_tags[str(_selected_idx)])
		_bug_note_lbl.text = note if not note.is_empty() else "[no note]"
	else:
		_bug_note_lbl.text = ""

func _show_fields(show: bool) -> void:
	_no_beat_lbl.visible = not show
	_fields_scroll.visible = show

# ─────────────────────────────────────────────────────────────
# Populate fields from beat dict
# ─────────────────────────────────────────────────────────────
func _populate_fields() -> void:
	if _selected_idx < 0 or _selected_idx >= _beats.size():
		return
	_loading = true
	var b: Dictionary = _beats[_selected_idx]

	_f_comment.text = str(b.get("comment", ""))
	_f_hidden.button_pressed = b.get("hidden", false)
	_populate_locale_fields(b)

	var bg: Variant = b.get("background", "")
	_f_background.text = "null" if bg == null else (str(bg) if bg != "" else "")
	_f_video.text = str(b.get("video", ""))

	_f_linger_chars.button_pressed = b.get("linger_characters", false)
	_chars_vbox.modulate.a = 0.3 if _f_linger_chars.button_pressed else 1.0
	_rebuild_char_rows(b.get("characters", []) as Array)
	_f_dim_others.button_pressed = b.get("dim_others", false)
	var nsfw_val: String = str(b.get("nsfw", "both")).to_lower()
	match nsfw_val:
		"safe":  _f_nsfw.selected = 1
		"nsfw":  _f_nsfw.selected = 2
		_:       _f_nsfw.selected = 0

	var kb: Variant = b.get("bg_ken_burns", null)
	if kb is Dictionary:
		_f_kb_zoom.value     = float(kb.get("zoom",     1.0))
		_f_kb_pan_x.value    = float(kb.get("pan_x",    0.0))
		_f_kb_pan_y.value    = float(kb.get("pan_y",    0.0))
		_f_kb_duration.value = float(kb.get("duration", 4.0))
	else:
		_f_kb_zoom.value = 1.0; _f_kb_pan_x.value = 0.0
		_f_kb_pan_y.value = 0.0; _f_kb_duration.value = 0.0

	var music: Variant = b.get("music", "")
	_f_music.text = "null" if music == null else (str(music) if music != "" else "")
	_f_music_fade_in.value  = float(b.get("music_fade_in",  0.0))
	_f_music_fade_out.value = float(b.get("music_fade_out", 0.0))

	var sfx_val: Variant = b.get("sfx", b.get("sound", ""))
	_f_sfx.text = str(sfx_val) if sfx_val != null and sfx_val != "" else ""
	_f_sfx_volume.value = float(b.get("sfx_volume", b.get("sound_volume", 100.0)))

	_f_wait.value      = float(b.get("wait",     0.0))
	_f_fade_out.value  = float(b.get("fade_out", 0.0))
	_f_fade_in.value   = float(b.get("fade_in",  0.0))
	_f_fade_color.text = str(b.get("fade_color", ""))

	_f_flash_color.text     = str(b.get("flash_color",    ""))
	_f_flash_count.value    = float(b.get("flash_count",   0))
	_f_flash_duration.value = float(b.get("flash_duration", 0.2))
	_f_flash_delay.value    = float(b.get("flash_delay",   0.05))
	var ft: Variant = b.get("flash_target", "screen")
	_f_flash_target.text = ",".join(ft as Array) if ft is Array else (str(ft) if ft != null else "screen")

	var shk: Variant = b.get("shake", null)
	_f_shake.text = ",".join(shk as Array) if shk is Array else (str(shk) if shk != null and shk != "" else "")
	_f_shake_magnitude.value = float(b.get("shake_magnitude", 8.0))

	var ss: Variant = b.get("shake_screen", null)
	if ss == null or bool(ss) == false:
		_f_shake_screen.value = 0.0
	elif bool(ss) == true:
		_f_shake_screen.value = 10.0
	else:
		_f_shake_screen.value = float(ss)

	var anim_key: String = str(b.get("animation", ""))
	_f_animation.selected = 0
	for ai: int in range(ANIMATION_REGISTRY.size()):
		if (ANIMATION_REGISTRY[ai] as Dictionary)["key"] == anim_key:
			_f_animation.selected = ai
			break

	_f_hide_dialog.button_pressed   = bool(b.get("hide_dialog",  false))
	_f_bg_color.text                = str(b.get("bg_color",     ""))
	_f_center_text.text             = str(b.get("center_text",  ""))
	_f_center_text_size.value       = float(b.get("center_text_size",     48.0))
	_f_center_text_fade_in.value    = float(b.get("center_text_fade_in",  0.8))
	_f_center_text_hold.value       = float(b.get("center_text_hold",     1.5))
	_f_center_text_fade_out.value   = float(b.get("center_text_fade_out", 0.8))
	_f_start_battle.button_pressed  = b.get("start_battle",  false)
	_f_go_to_credits.button_pressed = b.get("go_to_credits", false)
	_f_credits_target.selected = 1 if str(b.get("credits_target", "")) == "demo" else 0
	var _cs_map: Array = ["", "credit", "credit_demo", "photo_scatter"]
	var _cs_val: String = str(b.get("call_scene", ""))
	_f_call_scene.selected = max(0, _cs_map.find(_cs_val))
	_f_player1_name.text = str(b.get("player1_name", ""))
	_f_player2_name.text = str(b.get("player2_name", ""))
	_f_portrait_p1.text = str(b.get("portrait_p1", ""))
	_f_portrait_p1_offset_x.value = float(b.get("portrait_p1_offset_x", 0.0))
	_f_portrait_p1_offset_y.value = float(b.get("portrait_p1_offset_y", 0.0))
	_f_portrait_p1_size.value     = float(b.get("portrait_p1_size", 1.0))
	_f_portrait_p2.text = str(b.get("portrait_p2", ""))
	_f_portrait_p2_offset_x.value = float(b.get("portrait_p2_offset_x", 0.0))
	_f_portrait_p2_offset_y.value = float(b.get("portrait_p2_offset_y", 0.0))
	_f_portrait_p2_size.value     = float(b.get("portrait_p2_size", 1.0))
	_f_battle_bgm.text = str(b.get("battle_bgm", ""))
	_f_battle_bgm_vol.value = float(b.get("battle_bgm_volume", 100.0))
	_f_on_win.text  = str(b.get("on_win",  ""))
	_f_on_lose.text = str(b.get("on_lose", ""))

	# Enemy deck
	_enemy_deck_chars.clear()
	_enemy_deck_traps.clear()
	_enemy_deck_tech.clear()
	var ed: Variant = b.get("enemy_deck", null)
	if ed is Dictionary:
		for v2: Variant in (ed as Dictionary).get("characters", []):
			_enemy_deck_chars.append(str(v2))
		for v2: Variant in (ed as Dictionary).get("traps", []):
			_enemy_deck_traps.append(str(v2))
		for v2: Variant in (ed as Dictionary).get("tech", []):
			_enemy_deck_tech.append(str(v2))
	_rebuild_enemy_chips("character", _enemy_chars_chips)
	_rebuild_enemy_chips("trap", _enemy_traps_chips)
	_rebuild_enemy_chips("tech", _enemy_tech_chips)

	# Union flags
	_f_ai_union_enabled.button_pressed     = bool(b.get("ai_union_enabled",     true))
	_f_player_union_enabled.button_pressed = bool(b.get("player_union_enabled", true))

	# AI personality (index 0 = Random)
	_select_opt(_f_ai_pers_def, str(b.get("ai_personality_defensive", "")))
	_select_opt(_f_ai_pers_off, str(b.get("ai_personality_offensive", "")))
	_select_opt(_f_ai_pers_soc, str(b.get("ai_personality_social",    "")))

	# Forced cells
	var pfc_raw: Variant = b.get("player_forced_cells", [])
	_rebuild_forced_grid(_player_forced_grid, _player_forced_gc,
		pfc_raw if pfc_raw is Array else [])
	var afc_raw: Variant = b.get("ai_forced_cells", [])
	_rebuild_forced_grid(_ai_forced_grid, _ai_forced_gc,
		afc_raw if afc_raw is Array else [])

	# Battle reward
	var rwd_raw: Variant = b.get("battle_reward", [])
	_rebuild_reward_rows(rwd_raw if rwd_raw is Array else [])

	# Dungeon call
	var dcall: String = str(b.get("dungeon_call", ""))
	_f_call_dungeon.button_pressed = dcall != ""
	_populate_dungeon_call_picker()
	if dcall != "":
		for i: int in range(_dungeon_filtered_ids.size()):
			if _dungeon_filtered_ids[i] == dcall:
				_f_dungeon_opt.selected = i
				break
	_f_dungeon_on_win.text  = str(b.get("dungeon_on_win",  ""))
	_f_dungeon_on_lose.text = str(b.get("dungeon_on_lose", ""))

	_loading = false
	_update_tab_colors()
	_update_bug_note_label()

func _populate_locale_fields(b: Dictionary) -> void:
	# Speaker
	var sp: Variant = b.get("speaker", null)
	for i: int in range(_speaker_fields.size()):
		var le: LineEdit = _speaker_fields[i]
		var lang: String = _languages[i]
		if sp is Dictionary:
			le.text = str(sp.get(lang, ""))
		elif i == 0:
			le.text = str(sp) if sp != null else ""
		else:
			le.text = ""

	# Text
	var tx: Variant = b.get("text", null)
	for i: int in range(_text_fields.size()):
		var te: TextEdit = _text_fields[i]
		var lang: String = _languages[i]
		if tx is Dictionary:
			te.text = str(tx.get(lang, ""))
		elif i == 0:
			te.text = str(tx) if tx != null else ""
		else:
			te.text = ""

# ─────────────────────────────────────────────────────────────
# Collect beat dict from fields
# ─────────────────────────────────────────────────────────────
func _collect_beat() -> Dictionary:
	var b: Dictionary = {}

	var comment: String = _f_comment.text.strip_edges()
	if not comment.is_empty():
		b["comment"] = comment
	if _f_hidden.button_pressed:
		b["hidden"] = true

	# Speaker — build from UI + preserve removed-language data
	var sp_dict: Dictionary = {}
	# Preserve data for languages not currently in _languages
	if _selected_idx >= 0 and _selected_idx < _beats.size():
		var old_sp: Variant = _beats[_selected_idx].get("speaker", null)
		if old_sp is Dictionary:
			for lang_key: String in (old_sp as Dictionary):
				if not _languages.has(lang_key):
					sp_dict[lang_key] = old_sp[lang_key]
	# Collect from UI
	for i: int in range(_speaker_fields.size()):
		var val: String = (_speaker_fields[i] as LineEdit).text
		if not val.is_empty():
			sp_dict[_languages[i]] = val
	# Emit
	if not sp_dict.is_empty():
		b["speaker"] = sp_dict["en"] if (sp_dict.size() == 1 and sp_dict.has("en")) else sp_dict

	# Text — same pattern
	var tx_dict: Dictionary = {}
	if _selected_idx >= 0 and _selected_idx < _beats.size():
		var old_tx: Variant = _beats[_selected_idx].get("text", null)
		if old_tx is Dictionary:
			for lang_key: String in (old_tx as Dictionary):
				if not _languages.has(lang_key):
					tx_dict[lang_key] = old_tx[lang_key]
	for i: int in range(_text_fields.size()):
		var val: String = (_text_fields[i] as TextEdit).text
		if not val.is_empty():
			tx_dict[_languages[i]] = val
	if not tx_dict.is_empty():
		b["text"] = tx_dict["en"] if (tx_dict.size() == 1 and tx_dict.has("en")) else tx_dict

	# Background
	var bg: String = _f_background.text.strip_edges()
	if bg == "null":
		b["background"] = null
	elif not bg.is_empty():
		b["background"] = bg

	# Video
	var video: String = _f_video.text.strip_edges()
	if not video.is_empty():
		b["video"] = video

	# Characters
	if _f_linger_chars.button_pressed:
		b["linger_characters"] = true
		# No "characters" key → VNPlayer keeps previous beat's characters unchanged
	else:
		var chars: Array = []
		for row: Dictionary in _char_rows:
			var spr: String = (row["sprite"] as LineEdit).text.strip_edges()
			if spr.is_empty():
				continue
			var cd: Dictionary = {
				"sprite":   spr,
				"position": SLOT_OPTIONS[(row["position"] as OptionButton).selected],
			}
			if (row["flip"] as CheckBox).button_pressed:
				cd["flip"] = true
			if (row["crop"] as SpinBox).value > 0.0:
				cd["crop_bottom"] = (row["crop"] as SpinBox).value
			if (row["scale"] as SpinBox).value != 100.0:
				cd["scale"] = (row["scale"] as SpinBox).value
			chars.append(cd)
		if not _char_rows.is_empty():
			b["characters"] = chars

	if _f_dim_others.button_pressed:
		b["dim_others"] = true
	if _f_hide_dialog.button_pressed:
		b["hide_dialog"] = true
	var bgc: String = _f_bg_color.text.strip_edges()
	if not bgc.is_empty():
		b["bg_color"] = bgc
	var ct: String = _f_center_text.text.strip_edges()
	if not ct.is_empty():
		b["center_text"] = ct
		if _f_center_text_size.value != 48.0:
			b["center_text_size"] = _f_center_text_size.value
		if _f_center_text_fade_in.value != 0.8:
			b["center_text_fade_in"] = _f_center_text_fade_in.value
		if _f_center_text_hold.value != 1.5:
			b["center_text_hold"] = _f_center_text_hold.value
		if _f_center_text_fade_out.value != 0.8:
			b["center_text_fade_out"] = _f_center_text_fade_out.value
	match _f_nsfw.selected:
		1: b["nsfw"] = "safe"
		2: b["nsfw"] = "nsfw"

	var kb_z: float = _f_kb_zoom.value
	var kb_px: float = _f_kb_pan_x.value
	var kb_py: float = _f_kb_pan_y.value
	var kb_d: float  = _f_kb_duration.value
	if kb_z != 1.0 or kb_px != 0.0 or kb_py != 0.0 or kb_d > 0.0:
		b["bg_ken_burns"] = {"zoom": kb_z, "pan_x": kb_px, "pan_y": kb_py, "duration": kb_d}

	var music: String = _f_music.text.strip_edges()
	if music == "null":
		b["music"] = null
	elif not music.is_empty():
		b["music"] = music
	if _f_music_fade_in.value > 0.0:
		b["music_fade_in"] = _f_music_fade_in.value
	if _f_music_fade_out.value > 0.0:
		b["music_fade_out"] = _f_music_fade_out.value

	var sfx: String = _f_sfx.text.strip_edges()
	if not sfx.is_empty():
		b["sfx"] = sfx
		if _f_sfx_volume.value != 100.0:
			b["sfx_volume"] = _f_sfx_volume.value

	if _f_wait.value > 0.0:
		b["wait"] = _f_wait.value
	if _f_fade_out.value > 0.0:
		b["fade_out"] = _f_fade_out.value
	if _f_fade_in.value > 0.0:
		b["fade_in"] = _f_fade_in.value
	var fade_color: String = _f_fade_color.text.strip_edges()
	if not fade_color.is_empty():
		b["fade_color"] = fade_color

	var flash_color: String = _f_flash_color.text.strip_edges()
	var flash_count: int = int(_f_flash_count.value)
	if not flash_color.is_empty() or flash_count > 0:
		if not flash_color.is_empty():
			b["flash_color"] = flash_color
		if flash_count > 0:
			b["flash_count"] = flash_count
		if _f_flash_duration.value > 0.0:
			b["flash_duration"] = _f_flash_duration.value
		if _f_flash_delay.value > 0.0:
			b["flash_delay"] = _f_flash_delay.value
		var ftgt: String = _f_flash_target.text.strip_edges()
		if not ftgt.is_empty() and ftgt != "screen":
			b["flash_target"] = _parse_multi(ftgt)

	var shake: String = _f_shake.text.strip_edges()
	if not shake.is_empty():
		b["shake"] = _parse_multi(shake)
		if _f_shake_magnitude.value != 8.0:
			b["shake_magnitude"] = _f_shake_magnitude.value

	if _f_shake_screen.value > 0.0:
		b["shake_screen"] = _f_shake_screen.value

	var anim_idx: int = _f_animation.selected
	if anim_idx > 0:
		b["animation"] = (ANIMATION_REGISTRY[anim_idx] as Dictionary)["key"]

	if _f_start_battle.button_pressed:
		b["start_battle"] = true
	if _f_go_to_credits.button_pressed:
		b["go_to_credits"] = true
		if _f_credits_target.selected == 1:
			b["credits_target"] = "demo"
	var _cs_save_map: Array = ["", "credit", "credit_demo", "photo_scatter"]
	var _cs_idx: int = _f_call_scene.selected
	if _cs_idx > 0:
		b["call_scene"] = _cs_save_map[_cs_idx]
	var p1n: String = _f_player1_name.text.strip_edges()
	if not p1n.is_empty():
		b["player1_name"] = p1n
	var p2n: String = _f_player2_name.text.strip_edges()
	if not p2n.is_empty():
		b["player2_name"] = p2n
	var pp1: String = _f_portrait_p1.text.strip_edges()
	if not pp1.is_empty():
		b["portrait_p1"] = pp1
	var p1ox: float = _f_portrait_p1_offset_x.value
	if p1ox != 0.0:
		b["portrait_p1_offset_x"] = p1ox
	var p1oy: float = _f_portrait_p1_offset_y.value
	if p1oy != 0.0:
		b["portrait_p1_offset_y"] = p1oy
	var p1sz: float = _f_portrait_p1_size.value
	if p1sz != 1.0:
		b["portrait_p1_size"] = p1sz
	var pp2: String = _f_portrait_p2.text.strip_edges()
	if not pp2.is_empty():
		b["portrait_p2"] = pp2
	var p2ox: float = _f_portrait_p2_offset_x.value
	if p2ox != 0.0:
		b["portrait_p2_offset_x"] = p2ox
	var p2oy: float = _f_portrait_p2_offset_y.value
	if p2oy != 0.0:
		b["portrait_p2_offset_y"] = p2oy
	var p2sz: float = _f_portrait_p2_size.value
	if p2sz != 1.0:
		b["portrait_p2_size"] = p2sz
	var battle_bgm: String = _f_battle_bgm.text.strip_edges()
	if not battle_bgm.is_empty():
		b["battle_bgm"] = battle_bgm
	if _f_battle_bgm_vol.value != 100.0:
		b["battle_bgm_volume"] = _f_battle_bgm_vol.value
	var on_win: String = _f_on_win.text.strip_edges()
	if not on_win.is_empty():
		b["on_win"] = on_win
	var on_lose: String = _f_on_lose.text.strip_edges()
	if not on_lose.is_empty():
		b["on_lose"] = on_lose

	# Enemy deck
	if not _enemy_deck_chars.is_empty() or not _enemy_deck_traps.is_empty() or not _enemy_deck_tech.is_empty():
		b["enemy_deck"] = {
			"characters": _enemy_deck_chars.duplicate(),
			"traps":      _enemy_deck_traps.duplicate(),
			"tech":       _enemy_deck_tech.duplicate(),
		}

	# Union flags (only write if non-default to keep JSON clean)
	if not _f_ai_union_enabled.button_pressed:
		b["ai_union_enabled"] = false
	if not _f_player_union_enabled.button_pressed:
		b["player_union_enabled"] = false

	# AI personality (only write if not Random / index 0)
	if _f_ai_pers_def.selected > 0:
		b["ai_personality_defensive"] = _f_ai_pers_def.get_item_text(_f_ai_pers_def.selected)
	if _f_ai_pers_off.selected > 0:
		b["ai_personality_offensive"] = _f_ai_pers_off.get_item_text(_f_ai_pers_off.selected)
	if _f_ai_pers_soc.selected > 0:
		b["ai_personality_social"] = _f_ai_pers_soc.get_item_text(_f_ai_pers_soc.selected)

	# Forced cells
	var pfc: Array = _collect_forced_cells_from_grid(_player_forced_grid)
	if not pfc.is_empty():
		b["player_forced_cells"] = pfc
	var afc: Array = _collect_forced_cells_from_grid(_ai_forced_grid)
	if not afc.is_empty():
		b["ai_forced_cells"] = afc

	# Battle reward
	var rewards: Array = []
	for rr: Dictionary in _battle_reward_rows:
		var type_opt: OptionButton = rr["type_opt"]
		match type_opt.selected:
			0: # Credits
				var amt: int = int((rr["credits_sb"] as SpinBox).value)
				if amt > 0:
					rewards.append({"type": "credits", "amount": amt})
			1: # Card
				var cname: String = (rr["card_opt"] as OptionButton).get_item_text(
					(rr["card_opt"] as OptionButton).selected)
				if not cname.is_empty():
					rewards.append({"type": "card", "card_name": cname})
			2: # Booster Pack
				var pname: String = (rr["pack_opt"] as OptionButton).get_item_text(
					(rr["pack_opt"] as OptionButton).selected)
				if not pname.is_empty():
					rewards.append({"type": "booster_pack", "pack_name": pname})
	if not rewards.is_empty():
		b["battle_reward"] = rewards

	# Dungeon call
	if _f_call_dungeon.button_pressed and _f_dungeon_opt.selected >= 0:
		var sel: int = _f_dungeon_opt.selected
		var did: String = _dungeon_filtered_ids[sel] if sel < _dungeon_filtered_ids.size() else ""
		if did != "" and did != "(no layouts)":
			b["dungeon_call"] = did
	var dw: String = _f_dungeon_on_win.text.strip_edges()
	if not dw.is_empty():
		b["dungeon_on_win"] = dw
	var dl: String = _f_dungeon_on_lose.text.strip_edges()
	if not dl.is_empty():
		b["dungeon_on_lose"] = dl

	return b

func _parse_multi(s: String) -> Variant:
	if s == "all" or s == "screen":
		return s
	var parts: Array = s.split(",")
	if parts.size() == 1:
		return parts[0].strip_edges()
	var arr: Array = []
	for p: String in parts:
		arr.append(p.strip_edges())
	return arr

# ─────────────────────────────────────────────────────────────
# Field change handler
# ─────────────────────────────────────────────────────────────
func _on_field_changed() -> void:
	if _loading or _selected_idx < 0:
		return
	_beats[_selected_idx] = _collect_beat()
	_beat_list.set_item_text(_selected_idx, _beat_summary(_beats[_selected_idx], _selected_idx))
	var was_dirty: bool = _dirty
	_dirty = true
	_beat_modified[_selected_idx] = true
	_beat_list.set_item_custom_bg_color(_selected_idx, Color(0.5, 0.45, 0.0, 0.4))
	if not was_dirty:
		_refresh_file_list_colors()

# ─────────────────────────────────────────────────────────────
# Character rows
# ─────────────────────────────────────────────────────────────
func _rebuild_char_rows(chars: Array) -> void:
	for child in _chars_vbox.get_children():
		child.queue_free()
	_char_rows.clear()
	for ci: Dictionary in chars:
		_add_char_row_from(ci)

func _add_character_row() -> void:
	if _selected_idx < 0:
		return
	_add_char_row_from({})
	_on_field_changed()

func _add_char_row_from(ci: Dictionary) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 3)
	_chars_vbox.add_child(hbox)

	var pos_btn := OptionButton.new()
	pos_btn.custom_minimum_size = Vector2(88, 26)
	pos_btn.add_theme_font_size_override("font_size", 14)
	for slot: String in SLOT_OPTIONS:
		pos_btn.add_item(slot)
	pos_btn.select(maxi(SLOT_OPTIONS.find(str(ci.get("position", "right"))), 0))
	pos_btn.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	hbox.add_child(pos_btn)

	var spr_le := LineEdit.new()
	spr_le.text = str(ci.get("sprite", ""))
	spr_le.placeholder_text = "res://assets/textures/vn/characters/..."
	spr_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spr_le.add_theme_font_size_override("font_size", 14)
	spr_le.text_changed.connect(func(_s: String) -> void: _on_field_changed())
	hbox.add_child(spr_le)

	var spr_browse := Button.new()
	spr_browse.text = "..."
	spr_browse.custom_minimum_size = Vector2(34, 0)
	spr_browse.add_theme_font_size_override("font_size", 14)
	spr_browse.pressed.connect(func() -> void:
		_browse(spr_le,
			PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Image Files"]),
			"res://assets/textures/vn/characters/"))
	hbox.add_child(spr_browse)
	var spr_prev := Button.new()
	spr_prev.text = "Img"
	spr_prev.custom_minimum_size = Vector2(36, 0)
	spr_prev.add_theme_font_size_override("font_size", 13)
	spr_prev.pressed.connect(func() -> void: _preview_image(spr_le.text.strip_edges()))
	hbox.add_child(spr_prev)

	var flip_cb := CheckBox.new()
	flip_cb.text = "flip"
	flip_cb.button_pressed = ci.get("flip", false)
	flip_cb.add_theme_font_size_override("font_size", 14)
	flip_cb.toggled.connect(func(_b: bool) -> void: _on_field_changed())
	hbox.add_child(flip_cb)

	var crop_sb := SpinBox.new()
	crop_sb.min_value = 0.0; crop_sb.max_value = 99.0; crop_sb.step = 1.0
	crop_sb.value = float(ci.get("crop_bottom", 30.0))
	crop_sb.suffix = "%crop"
	crop_sb.custom_minimum_size.x = 100
	crop_sb.add_theme_font_size_override("font_size", 11)
	crop_sb.value_changed.connect(func(_v: float) -> void: _on_field_changed())
	hbox.add_child(crop_sb)

	var scale_sb := SpinBox.new()
	scale_sb.min_value = 10.0; scale_sb.max_value = 500.0; scale_sb.step = 5.0
	scale_sb.value = float(ci.get("scale", 175.0))
	scale_sb.suffix = "%sc"
	scale_sb.custom_minimum_size.x = 100
	scale_sb.add_theme_font_size_override("font_size", 11)
	scale_sb.value_changed.connect(func(_v: float) -> void: _on_field_changed())
	hbox.add_child(scale_sb)

	var rm_btn := Button.new()
	rm_btn.text = "×"
	rm_btn.custom_minimum_size = Vector2(26, 26)
	hbox.add_child(rm_btn)

	var row: Dictionary = {
		"hbox": hbox, "position": pos_btn, "sprite": spr_le,
		"flip": flip_cb, "crop": crop_sb, "scale": scale_sb,
	}
	_char_rows.append(row)
	rm_btn.pressed.connect(func() -> void: _remove_char_row(row))

func _remove_char_row(row: Dictionary) -> void:
	(row["hbox"] as HBoxContainer).queue_free()
	_char_rows.erase(row)
	_on_field_changed()

func _copy_chars() -> void:
	if _selected_idx < 0:
		return
	# Collect current characters from the live UI rows
	var chars: Array = []
	for row: Dictionary in _char_rows:
		var spr: String = (row["sprite"] as LineEdit).text.strip_edges()
		if spr.is_empty():
			continue
		var cd: Dictionary = {"sprite": spr, "position": SLOT_OPTIONS[(row["position"] as OptionButton).selected]}
		if (row["flip"] as CheckBox).button_pressed:
			cd["flip"] = true
		if (row["crop"] as SpinBox).value > 0.0:
			cd["crop_bottom"] = (row["crop"] as SpinBox).value
		if (row["scale"] as SpinBox).value != 100.0:
			cd["scale"] = (row["scale"] as SpinBox).value
		chars.append(cd)
	_char_clipboard = chars.duplicate(true)
	_has_char_clipboard = true
	_status_lbl.text = "Characters copied (%d slot(s))" % _char_clipboard.size()

func _paste_chars() -> void:
	if not _has_char_clipboard or _selected_idx < 0:
		return
	_rebuild_char_rows(_char_clipboard.duplicate(true))
	_on_field_changed()
	_status_lbl.text = "Characters pasted (%d slot(s))" % _char_clipboard.size()

# ─────────────────────────────────────────────────────────────
# Beat operations (copy / paste / reorder / drag)
# ─────────────────────────────────────────────────────────────
func _copy_beat() -> void:
	var selected: PackedInt32Array = _beat_list.get_selected_items()
	if selected.is_empty():
		return
	_clipboard.clear()
	for idx: int in selected:
		_clipboard.append((_beats[idx] as Dictionary).duplicate(true))
	_has_clipboard = true
	_status_lbl.text = "Copied %d beat(s)" % _clipboard.size()

func _paste_beat() -> void:
	if not _has_clipboard or _file_path.is_empty():
		return
	var insert_at: int = _selected_idx if _selected_idx >= 0 else _beats.size() - 1
	var first_new: int = insert_at + 1
	for i: int in range(_clipboard.size()):
		_beats.insert(first_new + i, (_clipboard[i] as Dictionary).duplicate(true))
	# Mark pasted beats as modified (yellow) and clear stale index tracking
	_beat_modified.clear()
	for i: int in range(_clipboard.size()):
		_beat_modified[first_new + i] = true
	_selected_idx = first_new + _clipboard.size() - 1
	_anchor_idx = first_new
	_refresh_beat_list()
	_beat_list.deselect_all()
	for i: int in range(_clipboard.size()):
		_beat_list.select(first_new + i, false)
	_populate_fields()
	_show_fields(true)
	_dirty = true

func _move_beat_to(from: int, to: int) -> void:
	if from == to:
		return
	var beat: Dictionary = _beats[from]
	_beats.remove_at(from)
	_beats.insert(to, beat)
	_selected_idx = to
	_anchor_idx = to
	_beat_modified.clear()
	_refresh_beat_list()
	_beat_list.select(to)
	_dirty = true

func _on_beat_list_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mbe := event as InputEventMouseButton
	if mbe.button_index != MOUSE_BUTTON_LEFT:
		return
	var clicked_idx: int = _beat_list.get_item_at_position(mbe.position, false)
	if mbe.pressed:
		if clicked_idx < 0:
			return
		if mbe.shift_pressed and _anchor_idx >= 0:
			# Range select from anchor to clicked (Google Sheets style)
			_beat_list.deselect_all()
			var lo: int = mini(_anchor_idx, clicked_idx)
			var hi: int = maxi(_anchor_idx, clicked_idx)
			for i: int in range(lo, hi + 1):
				_beat_list.select(i, false)
			_selected_idx = clicked_idx
			_populate_fields()
			_show_fields(true)
			get_viewport().set_input_as_handled()
		elif mbe.ctrl_pressed or mbe.meta_pressed:
			# Ctrl/Cmd — toggle individual item
			if _beat_list.is_selected(clicked_idx):
				_beat_list.deselect(clicked_idx)
				var sel: PackedInt32Array = _beat_list.get_selected_items()
				_selected_idx = sel[sel.size() - 1] if sel.size() > 0 else -1
				if _selected_idx >= 0:
					_populate_fields()
					_show_fields(true)
				else:
					_show_fields(false)
			else:
				_beat_list.select(clicked_idx, false)
				_selected_idx = clicked_idx
				_populate_fields()
				_show_fields(true)
			_anchor_idx = clicked_idx
			get_viewport().set_input_as_handled()
		else:
			# Plain click — handle selection explicitly (SELECT_MULTI doesn't fire item_selected)
			_beat_list.deselect_all()
			_beat_list.select(clicked_idx, true)
			_selected_idx = clicked_idx
			_anchor_idx = clicked_idx
			_populate_fields()
			_show_fields(true)
			_drag_from_idx = clicked_idx
			get_viewport().set_input_as_handled()
	else:
		# Mouse released — complete drag-reorder for plain clicks only
		if not mbe.shift_pressed and not mbe.ctrl_pressed and not mbe.meta_pressed:
			if _drag_from_idx >= 0:
				var drop_idx: int = _beat_list.get_item_at_position(mbe.position, false)
				if drop_idx >= 0 and drop_idx != _drag_from_idx:
					_move_beat_to(_drag_from_idx, drop_idx)
			_drag_from_idx = -1

func _add_beat() -> void:
	if _file_path.is_empty():
		return
	var new_beat: Dictionary = {"linger_characters": true}
	if _selected_idx >= 0:
		_beats.insert(_selected_idx + 1, new_beat)
		_selected_idx += 1
	else:
		_beats.append(new_beat)
		_selected_idx = _beats.size() - 1
	_beat_modified.clear()
	_anchor_idx = _selected_idx
	_refresh_beat_list()
	_beat_list.select(_selected_idx)
	_populate_fields()
	_show_fields(true)
	_dirty = true

func _duplicate_beat() -> void:
	if _selected_idx < 0:
		return
	var copy: Dictionary = _beats[_selected_idx].duplicate(true)
	_beats.insert(_selected_idx + 1, copy)
	_selected_idx += 1
	_beat_modified.clear()
	_anchor_idx = _selected_idx
	_refresh_beat_list()
	_beat_list.select(_selected_idx)
	_populate_fields()
	_dirty = true

func _delete_beat() -> void:
	var selected: PackedInt32Array = _beat_list.get_selected_items()
	if selected.is_empty():
		return
	# Delete from highest index to lowest so earlier indices stay valid
	var sorted: Array[int] = []
	for idx: int in selected:
		sorted.append(idx)
	sorted.sort()
	sorted.reverse()
	for idx: int in sorted:
		_beats.remove_at(idx)
	_beat_modified.clear()
	_selected_idx = mini(int(selected[0]), _beats.size() - 1)
	_anchor_idx = _selected_idx
	_refresh_beat_list()
	if _selected_idx >= 0:
		_beat_list.select(_selected_idx)
		_populate_fields()
		_show_fields(true)
	else:
		_show_fields(false)
	_dirty = true

func _move_beat_up() -> void:
	if _selected_idx <= 0:
		return
	var tmp: Dictionary = _beats[_selected_idx - 1]
	_beats[_selected_idx - 1] = _beats[_selected_idx]
	_beats[_selected_idx] = tmp
	_selected_idx -= 1
	_anchor_idx = _selected_idx
	_beat_modified.clear()
	_refresh_beat_list()
	_beat_list.select(_selected_idx)
	_dirty = true

func _move_beat_down() -> void:
	if _selected_idx < 0 or _selected_idx >= _beats.size() - 1:
		return
	var tmp: Dictionary = _beats[_selected_idx + 1]
	_beats[_selected_idx + 1] = _beats[_selected_idx]
	_beats[_selected_idx] = tmp
	_selected_idx += 1
	_anchor_idx = _selected_idx
	_beat_modified.clear()
	_refresh_beat_list()
	_beat_list.select(_selected_idx)
	_dirty = true

# ─────────────────────────────────────────────────────────────
# Keyboard shortcuts
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var ke := event as InputEventKey
	if not ke.pressed or ke.echo:
		return
	if ke.ctrl_pressed:
		match ke.keycode:
			KEY_C:     _copy_beat();        get_viewport().set_input_as_handled()
			KEY_V:     _paste_beat();       get_viewport().set_input_as_handled()
			KEY_D:     _duplicate_beat();   get_viewport().set_input_as_handled()
			KEY_S:     _save();             get_viewport().set_input_as_handled()
			KEY_UP:    _move_beat_up();     get_viewport().set_input_as_handled()
			KEY_DOWN:  _move_beat_down();   get_viewport().set_input_as_handled()

# ─────────────────────────────────────────────────────────────
# Save
# ─────────────────────────────────────────────────────────────
func _save() -> void:
	if _file_path.is_empty():
		_status_lbl.text = "No file open — select a file first."
		return
	var f := FileAccess.open(_file_path, FileAccess.WRITE)
	if f == null:
		_status_lbl.text = "ERROR: could not write to " + _file_path.get_file()
		return
	f.store_string(JSON.stringify(_beats, "\t"))
	f.close()
	_dirty = false
	_beat_modified.clear()
	_file_cache.erase(_file_path)
	_refresh_beat_list()
	_refresh_file_list_colors()
	_status_lbl.text = "Saved  (%d beats)  →  %s" % [_beats.size(), _file_path.get_file()]

# ─────────────────────────────────────────────────────────────
# Enemy deck builder helpers
# ─────────────────────────────────────────────────────────────

func _build_enemy_deck_row(parent: Control, label_text: String, card_type: String) -> HBoxContainer:
	# Label + scrollable chip strip
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 6)
	parent.add_child(hdr)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 100.0
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hdr.add_child(lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 30
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hdr.add_child(scroll)

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 3)
	scroll.add_child(chips)

	# Add row: dropdown + buttons
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 4)
	parent.add_child(add_row)

	var indent := Control.new()
	indent.custom_minimum_size.x = 106.0
	add_row.add_child(indent)

	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.add_theme_font_size_override("font_size", 13)
	add_row.add_child(opt)

	var names: Array = []
	match card_type:
		"character": names = CardDatabase.get_all_character_names()
		"trap":      names = CardDatabase.get_all_trap_names()
		"tech":      names = CardDatabase.get_all_tech_names()
	names.sort()
	for n: String in names:
		opt.add_item(n)

	var add_btn := Button.new()
	add_btn.text = "+ Add"
	add_btn.custom_minimum_size = Vector2(60, 24)
	add_btn.add_theme_font_size_override("font_size", 13)
	add_row.add_child(add_btn)

	var clr_btn := Button.new()
	clr_btn.text = "Clear"
	clr_btn.custom_minimum_size = Vector2(50, 24)
	clr_btn.add_theme_font_size_override("font_size", 13)
	add_row.add_child(clr_btn)

	add_btn.pressed.connect(func() -> void:
		if opt.item_count == 0:
			return
		_add_enemy_card(card_type, opt.get_item_text(opt.selected), chips)
	)
	clr_btn.pressed.connect(func() -> void:
		_get_enemy_array(card_type).clear()
		_rebuild_enemy_chips(card_type, chips)
		_on_field_changed()
	)

	return chips

func _get_enemy_array(card_type: String) -> Array:
	match card_type:
		"character": return _enemy_deck_chars
		"trap":      return _enemy_deck_traps
		"tech":      return _enemy_deck_tech
	return []

func _add_enemy_card(card_type: String, card_name: String, chips: HBoxContainer) -> void:
	var arr := _get_enemy_array(card_type)
	if arr.has(card_name):
		return  # no duplicates
	arr.append(card_name)
	_rebuild_enemy_chips(card_type, chips)
	_on_field_changed()

func _rebuild_enemy_chips(card_type: String, chips: HBoxContainer) -> void:
	if chips == null:
		return
	for child in chips.get_children():
		child.queue_free()
	var arr := _get_enemy_array(card_type)
	for cname: String in arr:
		var btn := Button.new()
		btn.text = cname + "  ×"
		btn.add_theme_font_size_override("font_size", 12)
		var name_copy: String = cname
		btn.pressed.connect(func() -> void:
			_get_enemy_array(card_type).erase(name_copy)
			_rebuild_enemy_chips(card_type, chips)
			_on_field_changed()
		)
		chips.add_child(btn)

# ─────────────────────────────────────────────────────────────
# Forced cell grid helpers
# ─────────────────────────────────────────────────────────────
func _build_forced_grid(grid_dict: Dictionary) -> GridContainer:
	var gc := GridContainer.new()
	gc.columns = 5
	gc.add_theme_constant_override("h_separation", 4)
	gc.add_theme_constant_override("v_separation", 4)
	for r: int in range(5):
		for c: int in range(5):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(72, 48)
			btn.clip_text = true
			btn.add_theme_font_size_override("font_size", 10)
			var r_cap := r
			var c_cap := c
			btn.pressed.connect(func() -> void:
				if _selected_idx < 0:
					return
				_open_forced_cell_picker(grid_dict, gc, r_cap, c_cap))
			gc.add_child(btn)
	_refresh_forced_grid(grid_dict, gc)
	return gc

func _refresh_forced_grid(grid_dict: Dictionary, gc: GridContainer) -> void:
	if gc == null:
		return
	var children: Array = gc.get_children()
	for r: int in range(5):
		for c: int in range(5):
			var btn: Button = children[r * 5 + c] as Button
			var key: String = str(r) + "," + str(c)
			var is_hl: bool = Vector2i(r, c) in _union_highlight_cells
			if grid_dict.has(key):
				btn.text = grid_dict[key] as String
				btn.modulate = Color(0.0, 1.0, 1.0) if is_hl else Color(0.55, 1.0, 0.55)
			else:
				btn.text = "%d,%d" % [r, c]
				btn.modulate = Color(0.0, 0.85, 0.85, 0.75) if is_hl else Color(1.0, 1.0, 1.0, 0.45)

func _open_forced_cell_picker(grid_dict: Dictionary, gc: GridContainer, r: int, c: int) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 70
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "Cell [row %d, col %d]" % [r, c]
	title.add_theme_font_size_override("font_size", 15)
	vb.add_child(title)

	var key: String = str(r) + "," + str(c)
	var current: String = str(grid_dict.get(key, ""))

	var le := LineEdit.new()
	le.placeholder_text = "Character card name..."
	le.text = current
	le.add_theme_font_size_override("font_size", 14)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(le)

	# Suggestion list
	var sug_scroll := ScrollContainer.new()
	sug_scroll.custom_minimum_size = Vector2(0, 130)
	sug_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(sug_scroll)
	var sug_vb := VBoxContainer.new()
	sug_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sug_scroll.add_child(sug_vb)

	var refresh_sug := func(query: String) -> void:
		for child: Node in sug_vb.get_children():
			child.queue_free()
		var q: String = query.strip_edges().to_lower()
		var names: Array = []
		for n: String in CardDatabase.characters:
			if q.is_empty() or n.to_lower().contains(q):
				names.append(n)
		names.sort()
		var shown: int = 0
		for n: String in names:
			if shown >= 25:
				break
			var sb := Button.new()
			sb.text = n
			sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			sb.add_theme_font_size_override("font_size", 12)
			sb.pressed.connect(func() -> void: le.text = n)
			sug_vb.add_child(sb)
			shown += 1

	le.text_changed.connect(refresh_sug)
	refresh_sug.call(current)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 6)
	vb.add_child(btn_hb)

	var set_btn := Button.new()
	set_btn.text = "Set"
	set_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(set_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(clear_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(cancel_btn)

	set_btn.pressed.connect(func() -> void:
		var cname: String = le.text.strip_edges()
		if not cname.is_empty():
			grid_dict[key] = cname
		else:
			grid_dict.erase(key)
		_refresh_forced_grid(grid_dict, gc)
		_on_field_changed()
		overlay.queue_free())

	clear_btn.pressed.connect(func() -> void:
		grid_dict.erase(key)
		_refresh_forced_grid(grid_dict, gc)
		_on_field_changed()
		overlay.queue_free())

	cancel_btn.pressed.connect(func() -> void:
		overlay.queue_free())

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if not panel.get_global_rect().has_point((event as InputEventMouseButton).global_position):
				overlay.queue_free())

	le.grab_focus()
	le.select_all()

func _collect_forced_cells_from_grid(grid_dict: Dictionary) -> Array:
	var result: Array = []
	for key: String in grid_dict:
		var parts: PackedStringArray = key.split(",")
		if parts.size() == 2:
			result.append({
				"card_name": grid_dict[key],
				"row": int(parts[0]),
				"col": int(parts[1]),
			})
	return result

func _rebuild_forced_grid(grid_dict: Dictionary, gc: GridContainer, data: Array) -> void:
	grid_dict.clear()
	for fc: Variant in data:
		if fc is Dictionary:
			var r: int = int((fc as Dictionary).get("row", 0))
			var c: int = int((fc as Dictionary).get("col", 0))
			var cname: Variant = (fc as Dictionary).get("card_name", "")
			if cname is String and not (cname as String).is_empty():
				grid_dict[str(r) + "," + str(c)] = cname as String
	_refresh_forced_grid(grid_dict, gc)

# ─────────────────────────────────────────────────────────────
# Union card reference gallery
# ─────────────────────────────────────────────────────────────
func _build_union_gallery_section(parent: VBoxContainer) -> void:
	var search_hb := HBoxContainer.new()
	search_hb.add_theme_constant_override("separation", 6)
	parent.add_child(search_hb)

	var search_lbl := Label.new()
	search_lbl.text = "Search:"
	search_lbl.add_theme_font_size_override("font_size", 13)
	search_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	search_hb.add_child(search_lbl)

	_union_gallery_search = LineEdit.new()
	_union_gallery_search.placeholder_text = "Union card name..."
	_union_gallery_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_union_gallery_search.add_theme_font_size_override("font_size", 13)
	search_hb.add_child(_union_gallery_search)

	var clear_btn := Button.new()
	clear_btn.text = "✕"
	clear_btn.add_theme_font_size_override("font_size", 13)
	clear_btn.pressed.connect(func() -> void:
		_union_gallery_search.text = ""
		_refresh_union_gallery(""))
	search_hb.add_child(clear_btn)

	_union_gallery_vbox = VBoxContainer.new()
	_union_gallery_vbox.add_theme_constant_override("separation", 3)
	parent.add_child(_union_gallery_vbox)

	_union_gallery_search.text_changed.connect(_refresh_union_gallery)
	# No initial population — list only appears after user types a query

func _refresh_union_gallery(query: String) -> void:
	if _union_gallery_vbox == null:
		return
	for child: Node in _union_gallery_vbox.get_children():
		child.queue_free()
	var q: String = query.strip_edges().to_lower()
	if q.is_empty():
		return
	var all_unions: Array = UnionDatabase.get_all_unions()
	all_unions.sort_custom(func(a: UnionData, b: UnionData) -> bool: return a.card_name < b.card_name)
	for u: UnionData in all_unions:
		if SaveManager.demo_mode and not u.include_in_demo:
			continue
		if not q.is_empty() and not u.card_name.to_lower().contains(q):
			continue
		var btn := Button.new()
		var is_active: bool = _union_highlighted_name == u.card_name
		btn.text = ("► " if is_active else "  ") + u.card_name + "  [%d cells]" % u.union_zone.size()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 13)
		btn.tooltip_text = u.formula_description
		if is_active:
			btn.modulate = Color(0.0, 1.0, 1.0)
		var u_ref: UnionData = u
		btn.pressed.connect(func() -> void: _toggle_union_highlight(u_ref))
		_union_gallery_vbox.add_child(btn)

func _toggle_union_highlight(u: UnionData) -> void:
	if _union_highlighted_name == u.card_name:
		_union_highlighted_name = ""
		_union_highlight_cells.clear()
	else:
		_union_highlighted_name = u.card_name
		_union_highlight_cells = u.union_zone.duplicate()
	_refresh_forced_grid(_player_forced_grid, _player_forced_gc)
	_refresh_forced_grid(_ai_forced_grid, _ai_forced_gc)
	# Refresh gallery buttons to update active indicator
	if _union_gallery_search != null:
		_refresh_union_gallery(_union_gallery_search.text)

# ─────────────────────────────────────────────────────────────
# Battle reward row helpers
# ─────────────────────────────────────────────────────────────
const _REWARD_TYPES: Array = ["Credits", "Card", "Booster Pack"]
const _PACK_NAMES: Array   = ["Starter Pack", "Fighters Pack", "Trapmaster Pack", "Premium Pack"]

func _rebuild_reward_rows(rewards: Array) -> void:
	for child in _reward_rows_vbox.get_children():
		child.queue_free()
	_battle_reward_rows.clear()
	for rd: Variant in rewards:
		if rd is Dictionary:
			_add_reward_row_from(rd as Dictionary)

func _add_reward_row_from(rd: Dictionary) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	_reward_rows_vbox.add_child(hbox)

	# Type dropdown
	var type_opt := OptionButton.new()
	type_opt.custom_minimum_size = Vector2(110, 26)
	type_opt.add_theme_font_size_override("font_size", 13)
	for t: String in _REWARD_TYPES:
		type_opt.add_item(t)
	hbox.add_child(type_opt)

	# Credits spinbox
	var credits_sb := SpinBox.new()
	credits_sb.min_value = 1; credits_sb.max_value = 99999; credits_sb.step = 1
	credits_sb.value = float(rd.get("amount", 50))
	credits_sb.custom_minimum_size.x = 100
	credits_sb.add_theme_font_size_override("font_size", 13)
	credits_sb.value_changed.connect(func(_v: float) -> void: _on_field_changed())
	hbox.add_child(credits_sb)

	# Card dropdown
	var card_opt := OptionButton.new()
	card_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_opt.add_theme_font_size_override("font_size", 13)
	var all_cards: Array = []
	for cn: String in CardDatabase.get_all_character_names(): all_cards.append(cn)
	for cn: String in CardDatabase.get_all_trap_names():      all_cards.append(cn)
	for cn: String in CardDatabase.get_all_tech_names():      all_cards.append(cn)
	all_cards.sort()
	for cn: String in all_cards:
		card_opt.add_item(cn)
	var wanted_card: String = str(rd.get("card_name", ""))
	var card_idx: int = all_cards.find(wanted_card)
	if card_idx >= 0:
		card_opt.select(card_idx)
	card_opt.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	hbox.add_child(card_opt)

	# Pack dropdown
	var pack_opt := OptionButton.new()
	pack_opt.custom_minimum_size.x = 140
	pack_opt.add_theme_font_size_override("font_size", 13)
	for pn: String in _PACK_NAMES:
		pack_opt.add_item(pn)
	var wanted_pack: String = str(rd.get("pack_name", ""))
	var pack_idx: int = _PACK_NAMES.find(wanted_pack)
	if pack_idx >= 0:
		pack_opt.select(pack_idx)
	pack_opt.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	hbox.add_child(pack_opt)

	# Remove button
	var rm := Button.new()
	rm.text = "×"
	rm.custom_minimum_size = Vector2(26, 26)
	hbox.add_child(rm)

	# Determine initial type
	var rtype: String = str(rd.get("type", "credits")).to_lower()
	var row: Dictionary = {
		"hbox": hbox, "type_opt": type_opt,
		"credits_sb": credits_sb, "card_opt": card_opt, "pack_opt": pack_opt,
	}
	match rtype:
		"card":         type_opt.select(1)
		"booster_pack": type_opt.select(2)
		_:              type_opt.select(0)
	_update_reward_row_visibility(row)

	_battle_reward_rows.append(row)

	type_opt.item_selected.connect(func(_i: int) -> void:
		_update_reward_row_visibility(row)
		_on_field_changed())
	rm.pressed.connect(func() -> void:
		hbox.queue_free()
		_battle_reward_rows.erase(row)
		_on_field_changed())

func _update_reward_row_visibility(row: Dictionary) -> void:
	var sel: int = (row["type_opt"] as OptionButton).selected
	(row["credits_sb"] as SpinBox).visible   = (sel == 0)
	(row["card_opt"]   as OptionButton).visible = (sel == 1)
	(row["pack_opt"]   as OptionButton).visible = (sel == 2)
