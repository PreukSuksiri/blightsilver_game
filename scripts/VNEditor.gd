extends Control
# VN Beat Editor — full-screen overlay for editing VN JSON scene files.
# Open via Admin Console: vn_editor [optional filename or path]
# Saves back to the same JSON file (Array of beat dicts).

signal closed

var _scenes_dir: String = "res://campaign/scenes/"
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
const ASK_PLAYER_NAME_KEYS: Array = ["player1", "player2", "both"]
const CHOICE_COND_TYPES: Array[String] = [
	"has_item", "not_has_item", "var_equals", "var_not_equals",
	"var_greater", "var_less", "at_node",
	"flag_equals", "flag_not_equals"]
const CHOICE_ACTION_TYPES: Array[String] = [
	"set_var", "give_item", "remove_item", "set_flag", "show_message"]

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
var _kb_preview_popup: PopupPanel = null
var _kb_preview_bg: TextureRect = null
var _kb_preview_clip: Control = null
var _kb_preview_frame: ReferenceRect = null
var _kb_preview_tween: Tween = null
const _KB_PREVIEW_VIEW_W := 800.0
const _KB_PREVIEW_VIEW_H := 450.0
const _KB_BG_W := 1600.0
const _KB_BG_H := 900.0

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
var _choices_vbox: VBoxContainer = null
var _go_to_vbox: VBoxContainer = null
var _play_group_vbox: VBoxContainer = null
var _exploration_actions_vbox: VBoxContainer = null
var _f_choices_layout: OptionButton = null
var _branch_bar: HBoxContainer = null
var _lang_chips_hbox: HBoxContainer = null   # chip row in left panel
var _lang_input: LineEdit = null

# ─────────────────────────────────────────────────────────────
# UI refs — left panel
# ─────────────────────────────────────────────────────────────
var _file_list: ItemList = null
var _folder_lbl: Label = null
var _folder_dialog: FileDialog = null
var _beat_list: ItemList = null
var _go_to_beat_input: LineEdit = null
var _status_lbl: Label = null
var _bug_note_lbl: Label = null

# ─────────────────────────────────────────────────────────────
# UI refs — right panel (non-locale)
# ─────────────────────────────────────────────────────────────
var _no_beat_lbl: Label = null
var _fields_scroll: ScrollContainer = null
var _fields_vbox: VBoxContainer = null
var _f_beat_name: LineEdit = null
var _f_comment: LineEdit = null
var _f_hidden: CheckBox = null
var _f_group: SpinBox = null
var _f_group_name: LineEdit = null
var _f_background: LineEdit = null
var _f_video: LineEdit = null
var _chars_vbox: VBoxContainer = null
var _f_linger_chars: CheckBox = null
var _f_dim_others: CheckBox = null
var _f_kb_zoom: SpinBox = null
var _f_kb_pan_x: SpinBox = null
var _f_kb_pan_y: SpinBox = null
var _f_kb_duration: SpinBox = null
var _f_kb_delay: SpinBox = null
var _f_kb_start_velocity_cb: CheckBox = null
var _f_kb_start_velocity: SpinBox = null
var _f_kb_stop_velocity_cb: CheckBox = null
var _f_kb_stop_velocity: SpinBox = null
var _f_kb_start_zoom_cb: CheckBox = null
var _f_kb_start_zoom: SpinBox = null
var _f_kb_start_pan_x_cb: CheckBox = null
var _f_kb_start_pan_x: SpinBox = null
var _f_kb_start_pan_y_cb: CheckBox = null
var _f_kb_start_pan_y: SpinBox = null
var _f_music: LineEdit = null
var _f_music_fade_in: SpinBox = null
var _f_music_fade_out: SpinBox = null
var _f_music_force: CheckBox = null
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
var _f_ask_player_name_cb: CheckBox = null
var _f_ask_player_name_opt: OptionButton = null
var _f_start_crystals_p1: SpinBox = null
var _f_start_crystals_p2: SpinBox = null
var _f_portrait_p1: LineEdit = null
var _f_portrait_p2: LineEdit = null
var _f_portrait_p1_offset_x: SpinBox = null
var _f_portrait_p1_offset_y: SpinBox = null
var _f_portrait_p1_size:     SpinBox = null
var _f_portrait_p2_offset_x: SpinBox = null
var _f_portrait_p2_offset_y: SpinBox = null
var _f_portrait_p2_size:     SpinBox = null
var _f_battle_bgm: LineEdit = null
var _f_setup_bgm: LineEdit = null
var _f_almost_win_bgm: LineEdit = null
var _f_battle_bgm_start: SpinBox = null
var _f_almost_win_enabled: CheckBox = null
var _f_battle_bgm_vol: SpinBox = null
var _f_start_battle:  CheckBox = null
var _f_call_tutorial: CheckBox = null
var _f_tutorial_opt:  OptionButton = null
var _f_tutorial_on_win:  LineEdit = null
var _f_tutorial_on_lose: LineEdit = null
var _tutorial_config_paths: PackedStringArray = PackedStringArray()
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
var _f_call_scene_keep_bgm: CheckBox = null
var _f_show_messenger: OptionButton = null
var _detective_note_rows: Array = []
var _detective_note_rows_vbox: VBoxContainer = null
var _f_detective_note_icon: OptionButton = null
var _f_show_detective_note: CheckBox = null
var _f_open_note_chapter: OptionButton = null
var _f_open_note_topic: OptionButton = null
var _f_show_note_stamp: CheckBox = null
var _f_note_stamp_chapter: OptionButton = null
var _f_note_stamp_topic: OptionButton = null
var _f_note_stamp_stamp: OptionButton = null
var _f_go_to_campaign_gallery: CheckBox     = null
var _f_go_to_quick_duel:       CheckBox     = null
var _f_mark_chapter_end:       CheckBox     = null
var _f_unlock_gallery_opt:    OptionButton = null
var _gallery_unlock_paths:    PackedStringArray = PackedStringArray()
# Multi-protagonist
var _f_unlock_protagonist: OptionButton = null
var _f_unlock_protagonist_vault: OptionButton = null
var _f_silent_switch_protagonist: OptionButton = null
var _f_show_protagonist_select: CheckBox = null
var _f_clear_limited_protagonist: OptionButton = null
var _f_set_limited_caps_id: OptionButton = null
var _f_set_limited_units: SpinBox = null
var _f_set_limited_traps: SpinBox = null
var _f_set_limited_techs: SpinBox = null

# Battle deck builder (for start_battle beats)
var _enemy_deck_chars: Array = []
var _enemy_deck_traps: Array = []
var _enemy_deck_tech: Array = []
var _enemy_chars_chips: HBoxContainer = null
var _enemy_traps_chips: HBoxContainer = null
var _enemy_tech_chips: HBoxContainer = null
var _player_deck_chars: Array = []
var _player_deck_traps: Array = []
var _player_deck_tech: Array = []
var _player_chars_chips: HBoxContainer = null
var _player_traps_chips: HBoxContainer = null
var _player_tech_chips: HBoxContainer = null
var _clone_target_opt: OptionButton = null
var _clone_deck_opt: OptionButton = null
var _clone_form_opt: OptionButton = null
var _f_ai_vault_opt: OptionButton = null
var _f_ai_vault_form_opt: OptionButton = null

# Forced cell placements — grid-based UI
var _player_forced_grid: Dictionary = {}   # key="r,c"  value=card_name String
var _ai_forced_grid:     Dictionary = {}
var _player_forced_gc:   GridContainer = null
var _ai_forced_gc:       GridContainer = null
const ENEMY_TECH_SLOTS: int = 3
var _ai_forced_tech: Array = ["", "", ""]
var _ai_forced_tech_btns: Array[Button] = []

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

# Exploration call fields
var _f_call_exploration:         CheckBox      = null
var _f_exploration_graph:        LineEdit      = null
var _f_exploration_force_fresh:  CheckBox      = null
var _f_exploration_keep_vn_bgm:  CheckBox      = null
var _f_exploration_on_return:    LineEdit      = null
var _f_exploration_params_vbox:  VBoxContainer = null
var _f_exploration_inv_vbox:     VBoxContainer = null

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
	_build_kb_preview_popup()
	if has_meta("_pending_path"):
		open_file(str(get_meta("_pending_path")))

# ─────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────
func open_file(path: String) -> void:
	var full_path: String
	if path.begins_with("res://") or path.begins_with("user://") or path.begins_with("/"):
		full_path = path
		# Auto-switch folder to match the file's directory
		var file_dir: String = full_path.get_base_dir()
		if not file_dir.ends_with("/"):
			file_dir += "/"
		if file_dir != _scenes_dir:
			_scenes_dir = file_dir
			if _folder_lbl != null:
				_folder_lbl.text = _scenes_dir
			_scan_files()
	else:
		full_path = _scenes_dir + path
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

	_folder_dialog = FileDialog.new()
	_folder_dialog.access    = FileDialog.ACCESS_FILESYSTEM
	_folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_folder_dialog.current_dir = ProjectSettings.globalize_path(_scenes_dir)
	_folder_dialog.dir_selected.connect(_on_folder_selected)
	add_child(_folder_dialog)

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
	var copy_ref_btn := Button.new()
	copy_ref_btn.text = "Copy Ref"
	copy_ref_btn.tooltip_text = "Copy file name + beat # + beat name (for bug reports)"
	copy_ref_btn.custom_minimum_size = Vector2(100, 34)
	copy_ref_btn.pressed.connect(_copy_bug_ref_to_clipboard)
	hbox.add_child(copy_ref_btn)
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
	var files_hdr := HBoxContainer.new()
	files_hdr.add_theme_constant_override("separation", 4)
	left.add_child(files_hdr)
	_folder_lbl = Label.new()
	_folder_lbl.text = _scenes_dir
	_folder_lbl.add_theme_font_size_override("font_size", 12)
	_folder_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
	_folder_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_folder_lbl.clip_text = true
	files_hdr.add_child(_folder_lbl)
	var chg_folder_btn := Button.new()
	chg_folder_btn.text = "📁"
	chg_folder_btn.custom_minimum_size = Vector2(32, 26)
	chg_folder_btn.add_theme_font_size_override("font_size", 14)
	chg_folder_btn.pressed.connect(_on_change_folder_pressed)
	files_hdr.add_child(chg_folder_btn)
	var copy_file_btn := Button.new()
	copy_file_btn.text = "Copy"
	copy_file_btn.tooltip_text = "Copy current file name to clipboard"
	copy_file_btn.custom_minimum_size = Vector2(52, 26)
	copy_file_btn.add_theme_font_size_override("font_size", 12)
	copy_file_btn.pressed.connect(_copy_file_name_to_clipboard)
	files_hdr.add_child(copy_file_btn)
	var new_file_btn := Button.new()
	new_file_btn.text = "+"
	new_file_btn.custom_minimum_size = Vector2(28, 26)
	new_file_btn.add_theme_font_size_override("font_size", 18)
	new_file_btn.tooltip_text = "New file"
	new_file_btn.pressed.connect(_on_new_file_pressed)
	files_hdr.add_child(new_file_btn)
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
	var go_row := HBoxContainer.new()
	go_row.add_theme_constant_override("separation", 4)
	left.add_child(go_row)
	_go_to_beat_input = LineEdit.new()
	_go_to_beat_input.placeholder_text = "Go to beat name…"
	_go_to_beat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_go_to_beat_input.add_theme_font_size_override("font_size", 13)
	_go_to_beat_input.text_submitted.connect(_go_to_beat_by_name)
	go_row.add_child(_go_to_beat_input)
	var go_btn := Button.new()
	go_btn.text = "Go"
	go_btn.custom_minimum_size = Vector2(40, 26)
	go_btn.add_theme_font_size_override("font_size", 13)
	go_btn.pressed.connect(func() -> void: _go_to_beat_by_name(_go_to_beat_input.text))
	go_row.add_child(go_btn)
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

	_branch_bar = HBoxContainer.new()
	_branch_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_branch_bar.offset_bottom = 28.0
	_branch_bar.add_theme_constant_override("separation", 6)
	_branch_bar.visible = false
	right.add_child(_branch_bar)

	_fields_scroll.offset_top = 32.0

	_fields_vbox = VBoxContainer.new()
	_fields_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fields_vbox.add_theme_constant_override("separation", 3)
	_fields_scroll.add_child(_fields_vbox)

	_build_fields()

func _build_fields() -> void:
	var v: VBoxContainer = _fields_vbox

	# ── Dialogue ──────────────────────────────────────────────
	_section(v, "DIALOGUE")
	_f_beat_name = _row_le(v, "Beat name", "Unique ID within this file (e.g. intro_kelly_meet)")
	var copy_beat_name_btn := Button.new()
	copy_beat_name_btn.text = "Copy"
	copy_beat_name_btn.tooltip_text = "Copy beat name to clipboard"
	copy_beat_name_btn.custom_minimum_size = Vector2(52, 0)
	copy_beat_name_btn.add_theme_font_size_override("font_size", 12)
	copy_beat_name_btn.pressed.connect(_copy_beat_name_to_clipboard)
	_f_beat_name.get_parent().add_child(copy_beat_name_btn)
	_f_comment = _row_le(v, "Comment", "Dev note (not shown in-game)")
	_f_hidden  = _row_cb(v, "Hidden", "Skip during linear playback (keeps it in the file; Go To can still jump here)")
	_f_group = _row_sb(v, "Group", 0.0, 999.0, 1.0,
		"0 = mainline; N = choice branch (may be separated — same N resumes later)")
	_f_group.value_changed.connect(func(_v: float) -> void:
		_refresh_group_name_field()
		_on_field_changed())
	_f_group_name = _row_le(v, "Group name", "Optional label for this group (editor display)")
	_f_group_name.text_changed.connect(func(_s: String) -> void: _on_field_changed())
	_refresh_group_name_field()

	# Speaker area (dynamic — rebuilt by _rebuild_locale_ui)
	_speaker_area = VBoxContainer.new()
	_speaker_area.add_theme_constant_override("separation", 2)
	v.add_child(_speaker_area)

	# Text area (dynamic — rebuilt by _rebuild_locale_ui)
	_text_area = VBoxContainer.new()
	_text_area.add_theme_constant_override("separation", 2)
	v.add_child(_text_area)

	_rebuild_locale_ui()

	var var_hint := Label.new()
	var_hint.text = "Dialogue vars: #name# | #name%clue_name=true# (ID→clue Name) | #name%translate?Nex=I# | #name%firstcapitalize=true# | #name%allcapitalize=true# | #name%decapitalize=true# (chain left→right)."
	var_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var_hint.add_theme_font_size_override("font_size", 12)
	var_hint.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	v.add_child(var_hint)

	# ── Go To (conditional beat jump) ─────────────────────────
	_section(v, "GO TO  (auto-jump after this beat)")
	var go_to_hint := Label.new()
	go_to_hint.text = "Evaluated top-to-bottom when the player advances; first matching entry wins. Each entry can require all conditions (AND) or any condition (OR). Empty conditions = always. Uses exploration vars/items when in exploration."
	go_to_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	go_to_hint.add_theme_font_size_override("font_size", 12)
	go_to_hint.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	v.add_child(go_to_hint)
	_go_to_vbox = VBoxContainer.new()
	_go_to_vbox.add_theme_constant_override("separation", 6)
	v.add_child(_go_to_vbox)
	var add_go_to_btn := Button.new()
	add_go_to_btn.text = "+ Add Go To"
	add_go_to_btn.custom_minimum_size = Vector2(120, 28)
	add_go_to_btn.add_theme_font_size_override("font_size", 14)
	add_go_to_btn.pressed.connect(_add_go_to_row)
	v.add_child(add_go_to_btn)

	# ── Play Group (conditional branch) ───────────────────────
	_section(v, "PLAY GROUP  (auto-branch after this beat)")
	var play_group_hint := Label.new()
	play_group_hint.text = "Evaluated top-to-bottom when the player advances; first matching entry plays that group (like a choice goto_group). No match = continue mainline. Each entry supports AND/OR conditions. Uses exploration vars/items when in exploration."
	play_group_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	play_group_hint.add_theme_font_size_override("font_size", 12)
	play_group_hint.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	v.add_child(play_group_hint)
	_play_group_vbox = VBoxContainer.new()
	_play_group_vbox.add_theme_constant_override("separation", 6)
	v.add_child(_play_group_vbox)
	var add_play_group_btn := Button.new()
	add_play_group_btn.text = "+ Add Play Group"
	add_play_group_btn.custom_minimum_size = Vector2(140, 28)
	add_play_group_btn.add_theme_font_size_override("font_size", 14)
	add_play_group_btn.pressed.connect(_add_play_group_row)
	v.add_child(add_play_group_btn)

	# ── Choices ─────────────────────────────────────────────
	_section(v, "CHOICES")
	_f_choices_layout = _row_opt(v, "Layout", ["Above dialog", "Inside dialog"],
		"where choice buttons appear during playback")
	_f_choices_layout.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	_choices_vbox = VBoxContainer.new()
	_choices_vbox.add_theme_constant_override("separation", 6)
	v.add_child(_choices_vbox)
	var add_choice_btn := Button.new()
	add_choice_btn.text = "+ Add Choice"
	add_choice_btn.custom_minimum_size = Vector2(120, 28)
	add_choice_btn.add_theme_font_size_override("font_size", 14)
	add_choice_btn.pressed.connect(_add_choice_row)
	v.add_child(add_choice_btn)

	# ── Exploration actions (during active session) ───────────
	_section(v, "EXPLORATION ACTIONS")
	var expl_act_hint := Label.new()
	expl_act_hint.text = "Runs when this beat is shown during an active exploration session (set_flag → SaveManager.exploration_flags)."
	expl_act_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	expl_act_hint.add_theme_font_size_override("font_size", 12)
	expl_act_hint.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	v.add_child(expl_act_hint)
	_exploration_actions_vbox = VBoxContainer.new()
	_exploration_actions_vbox.add_theme_constant_override("separation", 4)
	v.add_child(_exploration_actions_vbox)
	var add_expl_act_btn := Button.new()
	add_expl_act_btn.text = "+ Add Action"
	add_expl_act_btn.custom_minimum_size = Vector2(120, 28)
	add_expl_act_btn.add_theme_font_size_override("font_size", 14)
	add_expl_act_btn.pressed.connect(func() -> void:
		_add_action_row(_exploration_actions_vbox)
		_on_field_changed())
	v.add_child(add_expl_act_btn)

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
	_f_music_force = _row_cb(v, "Force music change",
			"Override Keep Exploration BGM for this beat: play a new track, OR fade-out/stop (leave Music blank or set to null + Music Fade Out)")
	_f_music_force.toggled.connect(func(_b: bool) -> void: _on_field_changed())
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
	_f_kb_pan_x    = _row_sb(v, "Pan X",  -1600.0, 1600.0,  1.0,   "pixels offset from centered fit")
	_f_kb_pan_y    = _row_sb(v, "Pan Y",  -1600.0, 1600.0,  1.0,   "pixels offset from centered fit")
	_f_kb_duration = _row_sb(v, "Duration",  0.0,  60.0,  0.001, "seconds")
	_f_kb_zoom.value = 1.0
	_f_kb_delay = _row_sb(v, "Delay", 0.0, 60.0, 0.1, "seconds before motion starts (optional)")
	var kb_timing_hint := Label.new()
	kb_timing_hint.text = "Optional velocity ramps — seconds to ease in to / out from normal speed within Duration. Unchecked = legacy sine ease on the full move."
	kb_timing_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kb_timing_hint.add_theme_font_size_override("font_size", 12)
	kb_timing_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	v.add_child(kb_timing_hint)
	_f_kb_start_velocity_cb = _row_optional_sb(
		v, "Start velocity", 0.0, 60.0, 0.1, "ramp-in time (s)")
	_f_kb_start_velocity = _f_kb_start_velocity_cb.get_meta("spinbox") as SpinBox
	_f_kb_start_velocity.value = 1.0
	_f_kb_stop_velocity_cb = _row_optional_sb(
		v, "Stop velocity", 0.0, 60.0, 0.1, "ramp-out time (s)")
	_f_kb_stop_velocity = _f_kb_stop_velocity_cb.get_meta("spinbox") as SpinBox
	_f_kb_stop_velocity.value = 1.0
	var kb_start_hint := Label.new()
	kb_start_hint.text = "Optional start transform — check a field to snap there before animating to the end values above. Unchecked = current behavior (animate from present position)."
	kb_start_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kb_start_hint.add_theme_font_size_override("font_size", 12)
	kb_start_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	v.add_child(kb_start_hint)
	_f_kb_start_zoom_cb = _row_optional_sb(
		v, "Start zoom", 0.5, 5.0, 0.01, "initial scale")
	_f_kb_start_zoom = _f_kb_start_zoom_cb.get_meta("spinbox") as SpinBox
	_f_kb_start_zoom.value = 1.0
	_f_kb_start_pan_x_cb = _row_optional_sb(
		v, "Start pan X", -1600.0, 1600.0, 1.0, "initial X offset")
	_f_kb_start_pan_x = _f_kb_start_pan_x_cb.get_meta("spinbox") as SpinBox
	_f_kb_start_pan_y_cb = _row_optional_sb(
		v, "Start pan Y", -1600.0, 1600.0, 1.0, "initial Y offset")
	_f_kb_start_pan_y = _f_kb_start_pan_y_cb.get_meta("spinbox") as SpinBox
	var kb_preview_row := HBoxContainer.new()
	kb_preview_row.add_theme_constant_override("separation", 6)
	v.add_child(kb_preview_row)
	var kb_preview_btn := Button.new()
	kb_preview_btn.text = "Preview ▶"
	kb_preview_btn.add_theme_font_size_override("font_size", 13)
	kb_preview_btn.pressed.connect(_preview_ken_burns)
	kb_preview_row.add_child(kb_preview_btn)
	var kb_replay_btn := Button.new()
	kb_replay_btn.text = "Replay ↻"
	kb_replay_btn.add_theme_font_size_override("font_size", 13)
	kb_replay_btn.pressed.connect(_replay_ken_burns_preview)
	kb_preview_row.add_child(kb_replay_btn)
	var kb_preview_hint := Label.new()
	kb_preview_hint.text = "Uses Background path above. Close popup or Replay to try new values."
	kb_preview_hint.add_theme_font_size_override("font_size", 11)
	kb_preview_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	kb_preview_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kb_preview_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kb_preview_row.add_child(kb_preview_hint)

	# ── Battle ────────────────────────────────────────────────
	_section(v, "BATTLE")
	_f_start_battle = _row_cb(v, "Start Battle", "Launch battle (VS AI) immediately after this beat's effects")
	_f_player1_name = _row_le(v, "Player 1 Name", "e.g. Nex  (blank = keep default)")
	_f_player2_name = _row_le(v, "Player 2 Name", "e.g. Midnight Shadow  (blank = keep default)")
	_f_ask_player_name_cb = _row_cb(v, "Ask Player Name",
		"Popup before placement — asks the player to enter name(s) at battle start")
	_f_ask_player_name_opt = _row_opt(v, "Ask for", ["Player 1", "Player 2", "Both"],
		"Which name fields appear in the popup")
	_sync_ask_player_name_fields()
	_f_start_crystals_p1 = _row_sb(v, "P1 Starting Crystals", 0.0, 99999.0, 100.0,
		"default %d — only saved when changed" % GameState.STARTING_CRYSTALS)
	_f_start_crystals_p1.value = GameState.STARTING_CRYSTALS
	_f_start_crystals_p2 = _row_sb(v, "P2 Starting Crystals", 0.0, 99999.0, 100.0,
		"default %d — only saved when changed" % GameState.STARTING_CRYSTALS)
	_f_start_crystals_p2.value = GameState.STARTING_CRYSTALS
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
	_f_battle_bgm = _row_le(v, "Battle BGM", "blank = manage_bgm battle default")
	_add_browse(_f_battle_bgm, PackedStringArray(["*.mp3,*.ogg,*.wav;Audio"]), "res://assets/audio/")
	_f_setup_bgm = _row_le(v, "Setup BGM", "placement phase — blank = manage_bgm placement default")
	_add_browse(_f_setup_bgm, PackedStringArray(["*.mp3,*.ogg,*.wav;Audio"]), "res://assets/audio/")
	_f_almost_win_bgm = _row_le(v, "Almost-win BGM", "endgame threshold — blank = manage_bgm almost_win default")
	_add_browse(_f_almost_win_bgm, PackedStringArray(["*.mp3,*.ogg,*.wav;Audio"]), "res://assets/audio/")
	_f_battle_bgm_start = _row_sb(v, "Start Battle Music At (sec)", 0.0, 600.0, 0.1,
		"seconds from 00:00 — default 14 skips intro; use 0 to start at beginning")
	_f_battle_bgm_start.value = 14.0
	_f_almost_win_enabled = _row_cb(v, "Enable Almost-win BGM",
		"when off, battle music continues — no mid-battle or win-reveal switch")
	_f_battle_bgm_vol = _row_sb(v, "BGM Volume", 0.0, 200.0, 1.0, "100 = normal  |  50 = half")
	_f_battle_bgm_vol.value = 100.0
	_f_on_win  = _row_le(v, "On Win",  "path to VN JSON — played if player wins")
	_add_browse(_f_on_win,  PackedStringArray(["*.json;JSON"]), "res://campaign/scenes/")
	_f_on_lose = _row_le(v, "On Lose", "path to VN JSON — played if player loses  |  'game_over' = show game-over screen")
	_add_browse(_f_on_lose, PackedStringArray(["*.json;JSON"]), "res://campaign/scenes/")

	# ── Tutorial Battle ───────────────────────────────────────
	_section(v, "TUTORIAL BATTLE  (config JSON — no builder UI)")
	var tut_hint := Label.new()
	tut_hint.text = "Launches a tutorial duel from data/tutorial_battles/. Decks and missions come from the JSON. Optional P1/P2 names and battle illustrations can be set in the BATTLE section above (override tutorial JSON) or in the tutorial config itself (player1_name, player2_name, portrait_p1, portrait_p2)."
	tut_hint.add_theme_font_size_override("font_size", 12)
	tut_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	tut_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(tut_hint)
	_f_call_tutorial = _row_cb(v, "Call Tutorial Battle",
		"Start a tutorial duel after this beat using the selected config")
	_f_tutorial_opt = _row_opt(v, "Tutorial config", ["(none)"],
		"JSON files in res://data/tutorial_battles/")
	_populate_tutorial_battle_picker()
	_f_tutorial_on_win = _row_le(v, "On Win", "path to VN JSON — played if player wins the tutorial battle")
	_add_browse(_f_tutorial_on_win, PackedStringArray(["*.json;JSON"]), "res://campaign/scenes/")
	_f_tutorial_on_lose = _row_le(v, "On Lose", "path to VN JSON — played if player loses  |  'game_over' = show game-over screen")
	_add_browse(_f_tutorial_on_lose, PackedStringArray(["*.json;JSON"]), "res://campaign/scenes/")

	# ── Clone from Deckbuilder ────────────────────────────────
	_section(v, "CLONE FROM DECKBUILDER  (optional)")
	var clone_hint := Label.new()
	clone_hint.text = "Copy a saved deckbuilder deck (and formation) into Player 1 or Player 2 battle config below."
	clone_hint.add_theme_font_size_override("font_size", 12)
	clone_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	clone_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(clone_hint)
	var clone_target_row := HBoxContainer.new()
	clone_target_row.add_theme_constant_override("separation", 8)
	v.add_child(clone_target_row)
	var clone_target_lbl := Label.new()
	clone_target_lbl.text = "Target"
	clone_target_lbl.custom_minimum_size.x = 100.0
	clone_target_lbl.add_theme_font_size_override("font_size", 13)
	clone_target_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clone_target_row.add_child(clone_target_lbl)
	_clone_target_opt = OptionButton.new()
	_clone_target_opt.add_theme_font_size_override("font_size", 13)
	_clone_target_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clone_target_opt.add_item("Player 1")
	_clone_target_opt.add_item("Player 2 (AI)")
	clone_target_row.add_child(_clone_target_opt)
	var clone_deck_row := HBoxContainer.new()
	clone_deck_row.add_theme_constant_override("separation", 8)
	v.add_child(clone_deck_row)
	var clone_deck_lbl := Label.new()
	clone_deck_lbl.text = "Deck"
	clone_deck_lbl.custom_minimum_size.x = 100.0
	clone_deck_lbl.add_theme_font_size_override("font_size", 13)
	clone_deck_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clone_deck_row.add_child(clone_deck_lbl)
	_clone_deck_opt = OptionButton.new()
	_clone_deck_opt.add_theme_font_size_override("font_size", 13)
	_clone_deck_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clone_deck_opt.item_selected.connect(func(_i: int) -> void: _refresh_clone_form_opt())
	clone_deck_row.add_child(_clone_deck_opt)
	var clone_form_row := HBoxContainer.new()
	clone_form_row.add_theme_constant_override("separation", 8)
	v.add_child(clone_form_row)
	var clone_form_lbl := Label.new()
	clone_form_lbl.text = "Formation"
	clone_form_lbl.custom_minimum_size.x = 100.0
	clone_form_lbl.add_theme_font_size_override("font_size", 13)
	clone_form_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clone_form_row.add_child(clone_form_lbl)
	_clone_form_opt = OptionButton.new()
	_clone_form_opt.add_theme_font_size_override("font_size", 13)
	_clone_form_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clone_form_row.add_child(_clone_form_opt)
	var clone_apply_btn := Button.new()
	clone_apply_btn.text = "Apply Clone"
	clone_apply_btn.add_theme_font_size_override("font_size", 13)
	clone_apply_btn.pressed.connect(_apply_deckbuilder_clone)
	v.add_child(clone_apply_btn)
	_populate_clone_deck_opt()

	# ── Player Deck ───────────────────────────────────────────
	_section(v, "PLAYER DECK  (optional — leave empty to use player's active save deck)")
	var player_hint_lbl := Label.new()
	player_hint_lbl.text = "Override the human player's deck for this battle. Empty = active deckbuilder deck at runtime."
	player_hint_lbl.add_theme_font_size_override("font_size", 12)
	player_hint_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	player_hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(player_hint_lbl)
	_player_chars_chips = _build_battle_deck_row(v, "Characters", "character", "player")
	_player_traps_chips = _build_battle_deck_row(v, "Traps", "trap", "player")
	_player_tech_chips  = _build_battle_deck_row(v, "Tech", "tech", "player")

	# ── AI Deck Vault (overrides enemy deck + AI forced cells when set) ──
	_section(v, "AI DECK VAULT  (optional — highest priority over enemy deck below)")
	var vault_hint := Label.new()
	vault_hint.text = "Pick a vault entry to use its deck and formation. Inline enemy deck and AI forced cells are ignored when set."
	vault_hint.add_theme_font_size_override("font_size", 12)
	vault_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	vault_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(vault_hint)
	_f_ai_vault_opt = OptionButton.new()
	_f_ai_vault_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	AIDeckVault.populate_vault_option(_f_ai_vault_opt)
	_f_ai_vault_opt.item_selected.connect(func(_i: int) -> void: _on_ai_vault_selected())
	var vault_row := HBoxContainer.new()
	vault_row.add_theme_constant_override("separation", 8)
	v.add_child(vault_row)
	var vault_lbl := Label.new()
	vault_lbl.text = "Vault entry:"
	vault_lbl.add_theme_font_size_override("font_size", 14)
	vault_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vault_row.add_child(vault_lbl)
	vault_row.add_child(_f_ai_vault_opt)
	var form_row := HBoxContainer.new()
	form_row.add_theme_constant_override("separation", 8)
	v.add_child(form_row)
	var form_lbl := Label.new()
	form_lbl.text = "Formation:"
	form_lbl.add_theme_font_size_override("font_size", 14)
	form_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	form_row.add_child(form_lbl)
	_f_ai_vault_form_opt = OptionButton.new()
	_f_ai_vault_form_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_f_ai_vault_form_opt.item_selected.connect(func(_i: int) -> void: _on_ai_vault_selected())
	form_row.add_child(_f_ai_vault_form_opt)

	# ── Enemy Deck ────────────────────────────────────────────
	_section(v, "ENEMY DECK  (optional — leave empty to use random pool)")
	var hint_lbl := Label.new()
	hint_lbl.text = "Specify exactly which cards the enemy places. Empty = random from full pool."
	hint_lbl.add_theme_font_size_override("font_size", 12)
	hint_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(hint_lbl)
	_enemy_chars_chips = _build_battle_deck_row(v, "Characters", "character", "enemy")
	_enemy_traps_chips = _build_battle_deck_row(v, "Traps", "trap", "enemy")
	_enemy_tech_chips  = _build_battle_deck_row(v, "Tech", "tech", "enemy")

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

	_section(v, "AI FORCED TECH HAND  (tap slot — empty = random)")
	var ai_tech_row := HBoxContainer.new()
	ai_tech_row.add_theme_constant_override("separation", 6)
	v.add_child(ai_tech_row)
	_ai_forced_tech_btns.clear()
	for slot: int in range(ENEMY_TECH_SLOTS):
		var tbtn := Button.new()
		tbtn.custom_minimum_size = Vector2(0, 36)
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtn.clip_text = true
		tbtn.add_theme_font_size_override("font_size", 11)
		var slot_cap := slot
		tbtn.pressed.connect(func() -> void: _open_ai_forced_tech_picker(slot_cap))
		ai_tech_row.add_child(tbtn)
		_ai_forced_tech_btns.append(tbtn)
	_refresh_ai_forced_tech_row()

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

	# ── Menu navigation ───────────────────────────────────────
	_section(v, "MENU NAVIGATION")
	_f_go_to_campaign_gallery = _row_cb(v, "Go to Campaign Gallery",
			"Fade out and open the campaign gallery on the main menu")
	_f_go_to_quick_duel = _row_cb(v, "Go to Quick Duel",
			"Fade out and open the Quick Duel scene")
	_f_mark_chapter_end = _row_cb(v, "Mark chapter end",
			"Mark a gallery chapter as finished (sets is_gallery_chapter_completed; hides Continue Saved Progress; unlocks prerequisites)")
	_f_unlock_gallery_opt = _row_opt(v, "Complete chapter", [],
			"Which gallery chapter to mark complete when this beat finishes")
	_rebuild_gallery_unlock_options()
	_sync_chapter_end_fields()

	# ── Multi-protagonist ─────────────────────────────────────
	_section(v, "MULTI-PROTAGONIST")
	_f_unlock_protagonist = _row_opt(v, "Unlock protagonist",
			["(none)", "mayu", "kelly"], "Unlock hero + Limited starter from vault")
	_f_unlock_protagonist_vault = OptionButton.new()
	StarterDeckVault.populate_vault_option(_f_unlock_protagonist_vault, "(default vault)")
	_f_unlock_protagonist_vault.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	var unlock_vault_row := HBoxContainer.new()
	var unlock_vault_lbl := Label.new()
	unlock_vault_lbl.text = "Starter vault"
	unlock_vault_lbl.custom_minimum_size = Vector2(160, 0)
	unlock_vault_row.add_child(unlock_vault_lbl)
	unlock_vault_row.add_child(_f_unlock_protagonist_vault)
	v.add_child(unlock_vault_row)
	_f_silent_switch_protagonist = _row_opt(v, "Silent switch protagonist",
			["(none)", "nex", "mayu", "kelly"], "Set global current hero with no UI")
	_f_show_protagonist_select = _row_cb(v, "Show protagonist select",
			"Open exploration-style protagonist selection overlay")
	_f_clear_limited_protagonist = _row_opt(v, "Clear Limited",
			["(none)", "mayu", "kelly"], "Remove Limited status from reserved deck")
	_f_set_limited_caps_id = _row_opt(v, "Set Limited caps for",
			["(none)", "mayu", "kelly"], "Absolute usable slot counts")
	_f_set_limited_units = _row_sb(v, "Limited units", 0, 12, 1, "Absolute unit cap")
	_f_set_limited_traps = _row_sb(v, "Limited traps", 0, 6, 1, "Absolute trap cap")
	_f_set_limited_techs = _row_sb(v, "Limited techs", 0, 3, 1, "Absolute tech cap")

	# ── Special Command ───────────────────────────────────────
	_section(v, "SPECIAL COMMAND")
	_f_call_scene = _row_opt(v, "Call scene",
			["(none)", "Credits", "Credits Demo", "Photo Scatter"],
			"Change to this scene after the beat completes")
	_f_call_scene_keep_bgm = _row_cb(v, "Keep current BGM",
			"Photo Scatter / Credit Demo: leave the current track playing instead of starting that scene's own BGM. Avoid a music_fade_out on prior beats if you want it continuous.")
	_f_call_scene_keep_bgm.toggled.connect(func(_b: bool) -> void: _on_field_changed())

	# ── Messenger (read-only chat evidence overlay) ───────────
	_section(v, "MESSENGER  (show a chat conversation from the Messenger Vault)")
	var msgr_hint := Label.new()
	msgr_hint.text = "Opens a read-only chat overlay after the beat's text is shown; playback resumes when the player closes it. Author conversations via admin command: messenger_vault."
	msgr_hint.add_theme_font_size_override("font_size", 12)
	msgr_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	msgr_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(msgr_hint)
	_f_show_messenger = _row_opt(v, "Conversation", [],
			"Messenger Vault conversation shown by this beat")
	MessengerVault.populate_conversation_option(_f_show_messenger)

	# ── Detective Note ────────────────────────────────────────
	_section(v, "DETECTIVE NOTE  (grant clues / topics when this beat is shown)")
	var note_hint := Label.new()
	note_hint.text = "Actions run as the beat appears (toasts for new clues/topics unless add_clue is marked Silent). Chapter defaults to this scene's mapped note chapter unless overridden. Author content via admin command: detective_note_vault."
	note_hint.add_theme_font_size_override("font_size", 12)
	note_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	note_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note_hint)
	var note_hdr := HBoxContainer.new()
	note_hdr.add_theme_constant_override("separation", 6)
	v.add_child(note_hdr)
	var note_hdr_lbl := Label.new()
	note_hdr_lbl.text = "Actions"
	note_hdr_lbl.add_theme_font_size_override("font_size", 13)
	note_hdr_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	note_hdr_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note_hdr_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note_hdr.add_child(note_hdr_lbl)
	var note_add_btn := Button.new()
	note_add_btn.text = "+ Add Action"
	note_add_btn.custom_minimum_size = Vector2(110, 26)
	note_add_btn.add_theme_font_size_override("font_size", 13)
	note_add_btn.pressed.connect(func() -> void:
		if _selected_idx < 0:
			return
		_add_detective_note_row_from({})
		_on_field_changed())
	note_hdr.add_child(note_add_btn)
	_detective_note_rows_vbox = VBoxContainer.new()
	_detective_note_rows_vbox.add_theme_constant_override("separation", 3)
	v.add_child(_detective_note_rows_vbox)

	_section(v, "DETECTIVE NOTE ICON  (dialog bottom-right; starts hidden)")
	var note_icon_hint := Label.new()
	note_icon_hint.text = "The notebook icon is hidden at scene start. Use Show/Hide on a beat to toggle it. Show only works when this VN scene maps to a detective note chapter."
	note_icon_hint.add_theme_font_size_override("font_size", 12)
	note_icon_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	note_icon_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note_icon_hint)
	_f_detective_note_icon = _row_opt(v, "Icon", ["(no change)", "Show", "Hide"],
			"show or hide the detective note icon on the dialog box")

	_section(v, "OPEN DETECTIVE NOTE  (force-open notebook; blocks until closed)")
	var open_note_hint := Label.new()
	open_note_hint.text = "Opens the interactive detective notebook on this beat (same as tapping the note icon). Optional chapter/topic override; topic blank uses the preferred unlocked topic. Player dismisses with Escape or by clicking outside."
	open_note_hint.add_theme_font_size_override("font_size", 12)
	open_note_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	open_note_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(open_note_hint)
	_f_show_detective_note = _row_cb(v, "Open detective note", "Force-open the notebook on this beat")
	_f_open_note_chapter = _row_opt(v, "Chapter", [], "note chapter (blank = scene default)")
	_populate_detective_chapter_option(_f_open_note_chapter, "", true)
	_f_open_note_topic = _row_opt(v, "Topic", [], "topic to focus (blank = preferred)")
	_populate_open_note_topic_option("", "")
	_sync_open_detective_note_fields()

	_section(v, "DETECTIVE NOTE STAMP  (APPROVED stamp animation; blocks until dismissed)")
	var stamp_hint := Label.new()
	stamp_hint.text = "Applies the stamp, then opens a read-only notebook view with the stamp animation. Click or press any key to dismiss."
	stamp_hint.add_theme_font_size_override("font_size", 12)
	stamp_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	stamp_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(stamp_hint)
	_f_show_note_stamp = _row_cb(v, "Show APPROVED stamp", "Play the case-closed stamp on this beat")
	_f_note_stamp_chapter = _row_opt(v, "Chapter", [], "note chapter containing the topic")
	_populate_detective_chapter_option(_f_note_stamp_chapter, "", true)
	_f_note_stamp_topic = _row_opt(v, "Topic", [], "stamped verdict topic")
	_f_note_stamp_stamp = _row_opt(v, "Stamp", [], "stamp id from the vault")
	_populate_detective_stamp_option(_f_note_stamp_stamp, "")
	_sync_note_stamp_fields()

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

	# ── Exploration Call ───────────────────────────────────────
	_section(v, "EXPLORATION CALL")
	_f_call_exploration = _row_cb(v, "Call Exploration", "launch exploration graph from this beat")
	_f_call_exploration.toggled.connect(func(on: bool) -> void:
		if not on:
			_f_exploration_graph.text = ""
		_on_field_changed())
	_f_exploration_graph = _row_le(v, "Graph", "res://exploration/graphs/my_graph.json")
	_add_browse(_f_exploration_graph, PackedStringArray(["*.json;JSON"]), "res://exploration/graphs/")
	_f_exploration_graph.text_changed.connect(func(txt: String) -> void:
		_f_call_exploration.button_pressed = not txt.strip_edges().is_empty()
		_on_field_changed())
	_f_exploration_force_fresh = _row_cb(v, "Force Fresh", "skip saved session resume — start a new run")
	_f_exploration_force_fresh.button_pressed = true
	_f_exploration_force_fresh.toggled.connect(func(_b: bool) -> void: _on_field_changed())
	_f_exploration_keep_vn_bgm = _row_cb(v, "Keep VN Music",
		"VN track continues through the scene transition only; node music applies once the map loads")
	_f_exploration_keep_vn_bgm.toggled.connect(func(_b: bool) -> void: _on_field_changed())

	var expl_vars_hdr := HBoxContainer.new()
	expl_vars_hdr.add_theme_constant_override("separation", 4)
	v.add_child(expl_vars_hdr)
	var expl_vars_lbl := Label.new()
	expl_vars_lbl.text = "Initial Variables"
	expl_vars_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	expl_vars_lbl.add_theme_font_size_override("font_size", 13)
	expl_vars_hdr.add_child(expl_vars_lbl)
	var expl_add_var_btn := Button.new()
	expl_add_var_btn.text = "+ Add"
	expl_add_var_btn.custom_minimum_size = Vector2(60, 26)
	expl_add_var_btn.add_theme_font_size_override("font_size", 12)
	expl_add_var_btn.pressed.connect(func() -> void:
		_add_exploration_param_row("", null)
		_on_field_changed())
	expl_vars_hdr.add_child(expl_add_var_btn)
	_f_exploration_params_vbox = VBoxContainer.new()
	_f_exploration_params_vbox.add_theme_constant_override("separation", 3)
	v.add_child(_f_exploration_params_vbox)

	var expl_inv_hdr := HBoxContainer.new()
	expl_inv_hdr.add_theme_constant_override("separation", 4)
	v.add_child(expl_inv_hdr)
	var expl_inv_lbl := Label.new()
	expl_inv_lbl.text = "Initial Inventory"
	expl_inv_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	expl_inv_lbl.add_theme_font_size_override("font_size", 13)
	expl_inv_hdr.add_child(expl_inv_lbl)
	var expl_add_inv_btn := Button.new()
	expl_add_inv_btn.text = "+ Add"
	expl_add_inv_btn.custom_minimum_size = Vector2(60, 26)
	expl_add_inv_btn.add_theme_font_size_override("font_size", 12)
	expl_add_inv_btn.pressed.connect(func() -> void:
		_add_exploration_inv_row("")
		_on_field_changed())
	expl_inv_hdr.add_child(expl_add_inv_btn)
	_f_exploration_inv_vbox = VBoxContainer.new()
	_f_exploration_inv_vbox.add_theme_constant_override("separation", 3)
	v.add_child(_f_exploration_inv_vbox)

	_f_exploration_on_return = _row_le(v, "On Return", "VN JSON played after exploration ends (optional)")
	_add_browse(_f_exploration_on_return, PackedStringArray(["*.json;JSON"]), "res://campaign/scenes/")
	_f_exploration_on_return.text_changed.connect(func(_s: String) -> void: _on_field_changed())

	_connect_static_signals()

func _connect_static_signals() -> void:
	var ch := _on_field_changed
	_f_beat_name.text_changed.connect(func(_s: String) -> void: ch.call())
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
	_f_start_battle.toggled.connect(func(on: bool) -> void:
		if on and _f_call_tutorial != null:
			_f_call_tutorial.button_pressed = false
		ch.call())
	if _f_call_tutorial != null:
		_f_call_tutorial.toggled.connect(func(on: bool) -> void:
			if on:
				_f_start_battle.button_pressed = false
			ch.call())
	if _f_tutorial_opt != null:
		_f_tutorial_opt.item_selected.connect(func(_i: int) -> void:
			if _f_call_tutorial != null and _f_tutorial_opt.selected > 0:
				_f_call_tutorial.button_pressed = true
			ch.call())
	_f_go_to_credits.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_credits_target.item_selected.connect(func(_i: int) -> void: ch.call())
	if _f_go_to_campaign_gallery != null:
		_f_go_to_campaign_gallery.toggled.connect(func(_b: bool) -> void: ch.call())
	if _f_go_to_quick_duel != null:
		_f_go_to_quick_duel.toggled.connect(func(_b: bool) -> void: ch.call())
	if _f_mark_chapter_end != null:
		_f_mark_chapter_end.toggled.connect(func(on: bool) -> void:
			_sync_chapter_end_fields()
			if on and _f_unlock_gallery_opt != null and _f_unlock_gallery_opt.selected <= 0:
				_f_unlock_gallery_opt.selected = 1
			ch.call())
	if _f_unlock_gallery_opt != null:
		_f_unlock_gallery_opt.item_selected.connect(func(_i: int) -> void:
			if _f_mark_chapter_end != null and _i > 0:
				_f_mark_chapter_end.button_pressed = true
			ch.call())
	_f_call_scene.item_selected.connect(func(_i: int) -> void: ch.call())
	if _f_show_messenger != null:
		_f_show_messenger.item_selected.connect(func(_i: int) -> void: ch.call())
	if _f_detective_note_icon != null:
		_f_detective_note_icon.item_selected.connect(func(_i: int) -> void: ch.call())
	if _f_show_detective_note != null:
		_f_show_detective_note.toggled.connect(func(_on: bool) -> void:
			_sync_open_detective_note_fields()
			ch.call())
	if _f_open_note_chapter != null:
		_f_open_note_chapter.item_selected.connect(func(_i: int) -> void:
			_populate_open_note_topic_option(
				_detective_chapter_from_option(_f_open_note_chapter),
				"")
			ch.call())
	if _f_open_note_topic != null:
		_f_open_note_topic.item_selected.connect(func(_i: int) -> void: ch.call())
	if _f_show_note_stamp != null:
		_f_show_note_stamp.toggled.connect(func(_on: bool) -> void:
			_sync_note_stamp_fields()
			ch.call())
	if _f_note_stamp_chapter != null:
		_f_note_stamp_chapter.item_selected.connect(func(_i: int) -> void:
			_populate_detective_topic_option(
				_f_note_stamp_topic,
				_detective_chapter_from_option(_f_note_stamp_chapter),
				"")
			ch.call())
	if _f_note_stamp_topic != null:
		_f_note_stamp_topic.item_selected.connect(func(_i: int) -> void: ch.call())
	if _f_note_stamp_stamp != null:
		_f_note_stamp_stamp.item_selected.connect(func(_i: int) -> void: ch.call())
	_f_ai_union_enabled.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_player_union_enabled.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_ai_pers_def.item_selected.connect(func(_i: int) -> void: ch.call())
	_f_ai_pers_off.item_selected.connect(func(_i: int) -> void: ch.call())
	_f_ai_pers_soc.item_selected.connect(func(_i: int) -> void: ch.call())
	_f_player1_name.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_player2_name.text_changed.connect(func(_s: String) -> void: ch.call())
	if _f_ask_player_name_cb != null:
		_f_ask_player_name_cb.toggled.connect(func(_on: bool) -> void:
			_sync_ask_player_name_fields()
			ch.call())
	if _f_ask_player_name_opt != null:
		_f_ask_player_name_opt.item_selected.connect(func(_i: int) -> void: ch.call())
	_f_start_crystals_p1.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_start_crystals_p2.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_portrait_p1.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_portrait_p2.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_portrait_p1_offset_x.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_portrait_p1_offset_y.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_portrait_p1_size.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_portrait_p2_offset_x.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_portrait_p2_offset_y.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_portrait_p2_size.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_battle_bgm.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_setup_bgm.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_almost_win_bgm.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_battle_bgm_start.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_almost_win_enabled.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_battle_bgm_vol.value_changed.connect(func(_v: float) -> void: ch.call())
	_f_on_win.text_changed.connect(func(_s: String) -> void: ch.call())
	_f_on_lose.text_changed.connect(func(_s: String) -> void: ch.call())
	for sp: SpinBox in [
		_f_music_fade_in, _f_music_fade_out, _f_sfx_volume,
		_f_wait, _f_fade_in, _f_fade_out,
		_f_flash_count, _f_flash_duration, _f_flash_delay,
		_f_shake_magnitude, _f_shake_screen,
		_f_kb_zoom, _f_kb_pan_x, _f_kb_pan_y, _f_kb_duration, _f_kb_delay,
		_f_kb_start_velocity, _f_kb_stop_velocity,
		_f_kb_start_zoom, _f_kb_start_pan_x, _f_kb_start_pan_y,
		_f_center_text_size, _f_center_text_fade_in, _f_center_text_hold, _f_center_text_fade_out,
	]:
		sp.value_changed.connect(func(_v: float) -> void: ch.call())

	_f_kb_start_zoom_cb.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_kb_start_pan_x_cb.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_kb_start_pan_y_cb.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_kb_start_velocity_cb.toggled.connect(func(_b: bool) -> void: ch.call())
	_f_kb_stop_velocity_cb.toggled.connect(func(_b: bool) -> void: ch.call())

func _populate_optional_kb_spin(
		kb: Dictionary, key: String, cb: CheckBox, sb: SpinBox, default_val: float) -> void:
	if cb == null or sb == null:
		return
	cb.button_pressed = kb.has(key)
	sb.editable = kb.has(key)
	sb.value = float(kb[key]) if kb.has(key) else default_val

func _reset_optional_kb_spin(cb: CheckBox, sb: SpinBox, default_val: float) -> void:
	if cb == null or sb == null:
		return
	cb.button_pressed = false
	sb.editable = false
	sb.value = default_val

func _ken_burns_dict_from_fields() -> Dictionary:
	var dur: float = _f_kb_duration.value
	if dur <= 0.0:
		dur = 4.0
	var kb: Dictionary = {
		"zoom": _f_kb_zoom.value,
		"pan_x": _f_kb_pan_x.value,
		"pan_y": _f_kb_pan_y.value,
		"duration": maxf(dur, 0.1),
	}
	if _f_kb_start_zoom_cb != null and _f_kb_start_zoom_cb.button_pressed:
		kb["start_zoom"] = _f_kb_start_zoom.value
	if _f_kb_start_pan_x_cb != null and _f_kb_start_pan_x_cb.button_pressed:
		kb["start_pan_x"] = _f_kb_start_pan_x.value
	if _f_kb_start_pan_y_cb != null and _f_kb_start_pan_y_cb.button_pressed:
		kb["start_pan_y"] = _f_kb_start_pan_y.value
	if _f_kb_delay != null and _f_kb_delay.value > 0.0:
		kb["delay"] = _f_kb_delay.value
	if _f_kb_start_velocity_cb != null and _f_kb_start_velocity_cb.button_pressed:
		kb["start_velocity"] = maxf(_f_kb_start_velocity.value, 0.0)
	if _f_kb_stop_velocity_cb != null and _f_kb_stop_velocity_cb.button_pressed:
		kb["stop_velocity"] = maxf(_f_kb_stop_velocity.value, 0.0)
	return kb

func _run_ken_burns_tween_on(target: TextureRect, kb: Dictionary, tween_ref: Array) -> void:
	if target == null or target.texture == null:
		return
	var viewport := Vector2(_KB_BG_W, _KB_BG_H)
	var layout: Dictionary = KenBurnsUtil.apply_expanded_layout(target, target.texture, viewport)
	var base_pos: Vector2 = layout.get("base_position", Vector2.ZERO)
	_apply_ken_burns_start_transform(target, kb, base_pos)
	var from_scale: float = target.scale.x
	var from_pos: Vector2 = target.position
	var to_scale: float = float(kb.get("zoom", 1.0))
	var to_pos: Vector2 = KenBurnsUtil.effective_position(base_pos, kb, false)
	var total: float = KenBurnsUtil.total_time(kb)
	if tween_ref.size() > 0 and tween_ref[0] is Tween:
		(tween_ref[0] as Tween).kill()
	var tw: Tween = create_tween()
	tween_ref.clear()
	tween_ref.append(tw)
	tw.tween_method(
		func(elapsed: float) -> void:
			var p: float = KenBurnsUtil.sample_progress(elapsed, kb)
			KenBurnsUtil.apply_transform(target, p, from_scale, to_scale, from_pos, to_pos),
		0.0, total, total)

func _apply_ken_burns_start_transform(target: TextureRect, kb: Dictionary, base_pos: Vector2) -> void:
	var from_scale: float = 1.0
	if kb.has("start_zoom"):
		from_scale = float(kb["start_zoom"])
	var from_pos: Vector2 = KenBurnsUtil.effective_position(base_pos, kb, true)
	if not (kb.has("start_pan_x") or kb.has("start_pan_y") or kb.has("start_zoom")):
		from_pos = base_pos
		from_scale = 1.0
	target.scale = Vector2(from_scale, from_scale)
	target.position = from_pos

# ─────────────────────────────────────────────────────────────
# Dungeon call picker
# ─────────────────────────────────────────────────────────────
func _populate_tutorial_battle_picker() -> void:
	if _f_tutorial_opt == null:
		return
	var prev_path: String = ""
	if _f_tutorial_opt.selected > 0 and _f_tutorial_opt.selected < _tutorial_config_paths.size():
		prev_path = _tutorial_config_paths[_f_tutorial_opt.selected]
	_f_tutorial_opt.clear()
	_tutorial_config_paths.clear()
	_tutorial_config_paths.append("")
	_f_tutorial_opt.add_item("(none)")
	var dir := DirAccess.open(TutorialBattleManager.CONFIG_DIR)
	if dir != null:
		dir.list_dir_begin()
		var fname := dir.get_next()
		var names: Array[String] = []
		while fname != "":
			if fname.ends_with(".json"):
				names.append(fname)
			fname = dir.get_next()
		dir.list_dir_end()
		names.sort()
		for json_name: String in names:
			var full_path: String = TutorialBattleManager.CONFIG_DIR + json_name
			_tutorial_config_paths.append(full_path)
			_f_tutorial_opt.add_item(json_name.trim_suffix(".json"))
	if _tutorial_config_paths.size() <= 1:
		_f_tutorial_opt.add_item("(no configs found)")
	if not prev_path.is_empty():
		for i: int in range(_tutorial_config_paths.size()):
			if _tutorial_config_paths[i] == prev_path:
				_f_tutorial_opt.selected = i
				break

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

func _clear_vbox(vbox: VBoxContainer) -> void:
	if vbox == null:
		return
	for child: Node in vbox.get_children():
		child.queue_free()

func _add_exploration_param_row(key: String, value: Variant) -> void:
	if _f_exploration_params_vbox == null:
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_f_exploration_params_vbox.add_child(row)

	var k_edit := LineEdit.new()
	k_edit.placeholder_text = "key"
	k_edit.text = key
	k_edit.custom_minimum_size.x = 100.0
	k_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k_edit.add_theme_font_size_override("font_size", 13)
	k_edit.text_changed.connect(func(_s: String) -> void: _on_field_changed())
	row.add_child(k_edit)

	var mode_opt := OptionButton.new()
	mode_opt.add_item("Fixed", 0)
	mode_opt.add_item("Random", 1)
	mode_opt.custom_minimum_size.x = 88.0
	mode_opt.add_theme_font_size_override("font_size", 12)
	row.add_child(mode_opt)

	var eq_lbl := Label.new()
	eq_lbl.text = "="
	row.add_child(eq_lbl)

	var v_edit := LineEdit.new()
	v_edit.placeholder_text = "value"
	v_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_edit.add_theme_font_size_override("font_size", 13)
	v_edit.text_changed.connect(func(_s: String) -> void: _on_field_changed())
	row.add_child(v_edit)

	var min_edit := LineEdit.new()
	min_edit.placeholder_text = "min"
	min_edit.custom_minimum_size.x = 52.0
	min_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	min_edit.add_theme_font_size_override("font_size", 13)
	min_edit.text_changed.connect(func(_s: String) -> void: _on_field_changed())
	row.add_child(min_edit)

	var dash_lbl := Label.new()
	dash_lbl.text = "–"
	row.add_child(dash_lbl)

	var max_edit := LineEdit.new()
	max_edit.placeholder_text = "max"
	max_edit.custom_minimum_size.x = 52.0
	max_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	max_edit.add_theme_font_size_override("font_size", 13)
	max_edit.text_changed.connect(func(_s: String) -> void: _on_field_changed())
	row.add_child(max_edit)

	var is_random := false
	var fixed_str := ""
	var min_str := ""
	var max_str := ""
	if value is Dictionary and (value as Dictionary).has("random"):
		var range_spec: Variant = (value as Dictionary)["random"]
		if range_spec is Array and (range_spec as Array).size() >= 2:
			is_random = true
			min_str = str((range_spec as Array)[0])
			max_str = str((range_spec as Array)[1])
		elif range_spec is Dictionary:
			is_random = true
			min_str = str((range_spec as Dictionary).get("min", 0))
			max_str = str((range_spec as Dictionary).get("max", 0))
	if not is_random and value != null:
		fixed_str = str(value)
	v_edit.text = fixed_str
	min_edit.text = min_str
	max_edit.text = max_str
	mode_opt.select(1 if is_random else 0)

	row.set_meta("key_edit", k_edit)
	row.set_meta("mode_opt", mode_opt)
	row.set_meta("eq_lbl", eq_lbl)
	row.set_meta("value_edit", v_edit)
	row.set_meta("min_edit", min_edit)
	row.set_meta("dash_lbl", dash_lbl)
	row.set_meta("max_edit", max_edit)

	var sync_mode_ui := func() -> void:
		var random_mode: bool = mode_opt.selected == 1
		eq_lbl.visible = not random_mode
		v_edit.visible = not random_mode
		min_edit.visible = random_mode
		dash_lbl.visible = random_mode
		max_edit.visible = random_mode
	mode_opt.item_selected.connect(func(_i: int) -> void:
		sync_mode_ui.call()
		_on_field_changed())
	sync_mode_ui.call()

	var rem := Button.new()
	rem.text = "✕"
	rem.custom_minimum_size = Vector2(26, 0)
	rem.add_theme_font_override("font", FontManager.make_font("primary", 400))
	rem.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	rem.pressed.connect(func() -> void:
		row.queue_free()
		_on_field_changed())
	row.add_child(rem)

func _add_exploration_inv_row(item_id: String) -> void:
	if _f_exploration_inv_vbox == null:
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_f_exploration_inv_vbox.add_child(row)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.add_theme_font_size_override("font_size", 13)
	opt.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	var all: Array = ExplorationItemDatabase.all_items()
	var sel_idx := 0
	for i: int in all.size():
		var it: Dictionary = all[i] as Dictionary
		var id: String = str(it.get("id", ""))
		var name_str: String = str(it.get("name", id))
		opt.add_item("%s  (%s)" % [name_str, id], i)
		opt.set_item_metadata(i, id)
		if id == item_id:
			sel_idx = i
	if all.is_empty():
		opt.add_item("(no items)")
	else:
		opt.select(sel_idx)
	row.add_child(opt)
	var rem := Button.new()
	rem.text = "✕"
	rem.custom_minimum_size = Vector2(26, 0)
	rem.add_theme_font_override("font", FontManager.make_font("primary", 400))
	rem.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	rem.pressed.connect(func() -> void:
		row.queue_free()
		_on_field_changed())
	row.add_child(rem)

func _rebuild_exploration_param_rows(params: Dictionary) -> void:
	_clear_vbox(_f_exploration_params_vbox)
	for k: Variant in params:
		_add_exploration_param_row(str(k), params[k])

func _rebuild_exploration_inv_rows(items: Array) -> void:
	_clear_vbox(_f_exploration_inv_vbox)
	for item_var: Variant in items:
		_add_exploration_inv_row(str(item_var))

func _collect_exploration_params() -> Dictionary:
	var params: Dictionary = {}
	if _f_exploration_params_vbox == null:
		return params
	for row_node: Node in _f_exploration_params_vbox.get_children():
		if not row_node is HBoxContainer:
			continue
		var row: HBoxContainer = row_node as HBoxContainer
		if not row.has_meta("key_edit"):
			continue
		var k: String = (row.get_meta("key_edit") as LineEdit).text.strip_edges()
		if k.is_empty():
			continue
		var mode_opt: OptionButton = row.get_meta("mode_opt") as OptionButton
		if mode_opt.selected == 1:
			var min_edit: LineEdit = row.get_meta("min_edit") as LineEdit
			var max_edit: LineEdit = row.get_meta("max_edit") as LineEdit
			var lo_text: String = min_edit.text.strip_edges()
			var hi_text: String = max_edit.text.strip_edges()
			if lo_text.is_valid_int() and hi_text.is_valid_int():
				params[k] = {"random": [int(lo_text), int(hi_text)]}
			else:
				params[k] = {"random": [0, 0]}
		else:
			params[k] = (row.get_meta("value_edit") as LineEdit).text.strip_edges()
	return params

func _collect_exploration_inventory() -> Array:
	var items: Array = []
	if _f_exploration_inv_vbox == null:
		return items
	for row_node: Node in _f_exploration_inv_vbox.get_children():
		if not row_node is HBoxContainer:
			continue
		var children: Array = (row_node as HBoxContainer).get_children()
		if children.is_empty():
			continue
		var opt := children[0] as OptionButton
		if opt.item_count > 0 and opt.get_item_text(0) != "(no items)":
			var id: Variant = opt.get_item_metadata(opt.selected)
			if id != null and str(id) != "":
				items.append(str(id))
	return items

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

func _row_optional_sb(parent: Control, label: String, mn: float, mx: float, step: float,
		hint: String) -> CheckBox:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)
	var cb := CheckBox.new()
	cb.text = label
	cb.custom_minimum_size.x = 140.0
	cb.add_theme_font_size_override("font_size", 14)
	cb.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	hbox.add_child(cb)
	var sb := SpinBox.new()
	sb.min_value = mn
	sb.max_value = mx
	sb.step = step
	sb.custom_minimum_size.x = 110.0
	sb.editable = false
	hbox.add_child(sb)
	if not hint.is_empty():
		var hl := Label.new()
		hl.text = hint
		hl.add_theme_font_size_override("font_size", 13)
		hl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
		hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(hl)
	cb.toggled.connect(func(on: bool) -> void:
		sb.editable = on
		_on_field_changed())
	sb.value_changed.connect(func(_v: float) -> void: _on_field_changed())
	hbox.set_meta("spinbox", sb)
	cb.set_meta("spinbox", sb)
	return cb

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
	hint.add_theme_font_override("font", FontManager.make_font("primary", 400))
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
func _rebuild_gallery_unlock_options() -> void:
	if _f_unlock_gallery_opt == null:
		return
	var prev_sel: int = _f_unlock_gallery_opt.selected
	_f_unlock_gallery_opt.clear()
	_gallery_unlock_paths = PackedStringArray()
	_f_unlock_gallery_opt.add_item("(none)")
	_gallery_unlock_paths.append("")
	_f_unlock_gallery_opt.add_item("(current VN file)")
	_gallery_unlock_paths.append("@current")
	const GALLERY_PATH: String = "res://campaign/gallery_data.json"
	if FileAccess.file_exists(GALLERY_PATH):
		var f := FileAccess.open(GALLERY_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			f.close()
			if parsed is Array:
				for raw: Variant in (parsed as Array):
					if not raw is Dictionary:
						continue
					var entry: Dictionary = raw as Dictionary
					var vn_path: String = str(entry.get("vn_scene", "")).strip_edges()
					if vn_path.is_empty():
						continue
					var line1: String = str(entry.get("line1", "")).strip_edges()
					var line2: String = str(entry.get("line2", "")).strip_edges()
					var label: String = line2 if not line2.is_empty() else vn_path.get_file()
					if not line1.is_empty() and not line2.is_empty():
						label = "%s — %s" % [line1, line2]
					_f_unlock_gallery_opt.add_item(label)
					_gallery_unlock_paths.append(vn_path)
	if _f_unlock_gallery_opt.item_count > 0:
		_f_unlock_gallery_opt.selected = clampi(prev_sel, 0, _f_unlock_gallery_opt.item_count - 1)
	_sync_chapter_end_fields()

func _beat_has_chapter_end(b: Dictionary) -> bool:
	if b.get("complete_current_gallery_chapter", false) \
			or b.get("unlock_current_gallery_chapter", false):
		return true
	var complete_vn: String = str(b.get("complete_gallery_chapter", "")).strip_edges()
	if complete_vn.is_empty():
		complete_vn = str(b.get("unlock_gallery_chapter", "")).strip_edges()
	return not complete_vn.is_empty()

func _sync_chapter_end_fields() -> void:
	if _f_unlock_gallery_opt == null or _f_mark_chapter_end == null:
		return
	_f_unlock_gallery_opt.disabled = not _f_mark_chapter_end.button_pressed

func _sync_ask_player_name_fields() -> void:
	if _f_ask_player_name_opt == null or _f_ask_player_name_cb == null:
		return
	_f_ask_player_name_opt.disabled = not _f_ask_player_name_cb.button_pressed

func _browse(target: LineEdit, filters: PackedStringArray, start_dir: String) -> void:
	_browse_target = target
	_file_dialog.filters = filters
	_file_dialog.current_dir = start_dir
	_file_dialog.popup_centered(Vector2(960, 620))

func _on_file_dialog_selected(path: String) -> void:
	if _browse_target != null:
		_browse_target.text = path
		if _browse_target == _f_exploration_graph:
			_f_call_exploration.button_pressed = true
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

func _build_kb_preview_popup() -> void:
	_kb_preview_popup = PopupPanel.new()
	add_child(_kb_preview_popup)
	_kb_preview_popup.popup_hide.connect(_stop_ken_burns_preview)

	var root := MarginContainer.new()
	root.add_theme_constant_override("margin_left", 12)
	root.add_theme_constant_override("margin_right", 12)
	root.add_theme_constant_override("margin_top", 12)
	root.add_theme_constant_override("margin_bottom", 12)
	_kb_preview_popup.add_child(root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	root.add_child(vbox)

	var title := Label.new()
	title.text = "Ken Burns Preview"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var clip := Control.new()
	clip.clip_contents = false
	_kb_preview_clip = clip
	vbox.add_child(clip)

	var stage := Control.new()
	stage.scale = Vector2(0.5, 0.5)
	stage.custom_minimum_size = Vector2(_KB_BG_W, _KB_BG_H)
	clip.add_child(stage)

	var bg_base := ColorRect.new()
	bg_base.color = Color(0.05, 0.05, 0.08)
	bg_base.size = Vector2(_KB_BG_W, _KB_BG_H)
	stage.add_child(bg_base)

	_kb_preview_bg = TextureRect.new()
	_kb_preview_bg.position = Vector2.ZERO
	_kb_preview_bg.size = Vector2(_KB_BG_W, _KB_BG_H)
	_kb_preview_bg.pivot_offset = Vector2(_KB_BG_W * 0.5, _KB_BG_H * 0.5)
	_kb_preview_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_kb_preview_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage.add_child(_kb_preview_bg)

	var frame := ReferenceRect.new()
	frame.position = Vector2.ZERO
	frame.size = Vector2(_KB_BG_W, _KB_BG_H)
	frame.border_color = Color(1.0, 0.92, 0.35, 0.65)
	frame.border_width = 3.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kb_preview_frame = frame
	stage.add_child(frame)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)
	var replay_btn := Button.new()
	replay_btn.text = "Replay ↻"
	replay_btn.pressed.connect(_replay_ken_burns_preview)
	btn_row.add_child(replay_btn)
	var stop_btn := Button.new()
	stop_btn.text = "Reset"
	stop_btn.pressed.connect(_stop_ken_burns_preview)
	btn_row.add_child(stop_btn)

func _ken_burns_preview_values() -> Dictionary:
	return _ken_burns_dict_from_fields()

func _stop_ken_burns_preview() -> void:
	if _kb_preview_tween != null:
		_kb_preview_tween.kill()
		_kb_preview_tween = null
	if _kb_preview_bg != null:
		KenBurnsUtil.restore_static_layout(_kb_preview_bg, Vector2(_KB_BG_W, _KB_BG_H))
	if _kb_preview_clip != null:
		_kb_preview_clip.custom_minimum_size = Vector2(_KB_PREVIEW_VIEW_W, _KB_PREVIEW_VIEW_H)

func _sync_kb_preview_clip_size(tex: Texture2D) -> void:
	if _kb_preview_clip == null:
		return
	var layout: Dictionary = KenBurnsUtil.fit_width_layout(tex, Vector2(_KB_BG_W, _KB_BG_H))
	var layout_size: Vector2 = layout.get("layout_size", Vector2(_KB_BG_W, _KB_BG_H))
	var view_size: Vector2 = layout_size * 0.5
	_kb_preview_clip.custom_minimum_size = Vector2(
		maxf(view_size.x, _KB_PREVIEW_VIEW_W),
		maxf(view_size.y, _KB_PREVIEW_VIEW_H))

func _run_ken_burns_preview_tween() -> void:
	if _kb_preview_bg == null:
		return
	_stop_ken_burns_preview()
	var kb: Dictionary = _ken_burns_preview_values()
	var tween_ref: Array = [_kb_preview_tween]
	_run_ken_burns_tween_on(_kb_preview_bg, kb, tween_ref)
	_kb_preview_tween = tween_ref[0] as Tween

func _preview_ken_burns() -> void:
	if _kb_preview_popup == null or _kb_preview_bg == null:
		return
	var bg_path: String = _f_background.text.strip_edges()
	if bg_path.is_empty() or bg_path == "null":
		_status_lbl.text = "Set a Background image path first."
		return
	if not ResourceLoader.exists(bg_path):
		_status_lbl.text = "Background not found: " + bg_path.get_file()
		return
	var tex: Variant = load(bg_path)
	if not tex is Texture2D:
		_status_lbl.text = "Background is not an image: " + bg_path.get_file()
		return
	_kb_preview_bg.texture = tex as Texture2D
	_sync_kb_preview_clip_size(tex as Texture2D)
	_stop_ken_burns_preview()
	var clip_size: Vector2 = _kb_preview_clip.custom_minimum_size if _kb_preview_clip != null \
		else Vector2(_KB_PREVIEW_VIEW_W, _KB_PREVIEW_VIEW_H)
	_kb_preview_popup.popup_centered(Vector2(clip_size.x + 48, clip_size.y + 120))
	_run_ken_burns_preview_tween()
	var kb: Dictionary = _ken_burns_preview_values()
	_status_lbl.text = "Ken Burns preview: zoom %.2f  pan (%.0f, %.0f)  %.1fs" % [
		kb["zoom"], kb["pan_x"], kb["pan_y"], kb["duration"]]

func _replay_ken_burns_preview() -> void:
	if _kb_preview_popup == null or not _kb_preview_popup.visible:
		_preview_ken_burns()
		return
	if _kb_preview_bg == null or _kb_preview_bg.texture == null:
		_preview_ken_burns()
		return
	_run_ken_burns_preview_tween()
	var kb: Dictionary = _ken_burns_preview_values()
	_status_lbl.text = "Replay: zoom %.2f  pan (%.0f, %.0f)  %.1fs" % [
		kb["zoom"], kb["pan_x"], kb["pan_y"], kb["duration"]]

# ─────────────────────────────────────────────────────────────
# Folder picker
# ─────────────────────────────────────────────────────────────
func _on_new_file_pressed() -> void:
	GameDialog.prompt_overlay(
		self,
		"New VN File",
		"Enter a filename (without .json):",
		"filename (without .json)",
		"Create",
		"Cancel",
		_try_create_new_file)

func _try_create_new_file(raw: String) -> bool:
	raw = raw.strip_edges()
	if raw.is_empty():
		_status_lbl.text = "New file: name cannot be empty."
		return false
	# Sanitise: strip any trailing .json the user may have typed
	if raw.to_lower().ends_with(".json"):
		raw = raw.left(raw.length() - 5)
	var fname: String = raw + ".json"
	var full_path: String = _scenes_dir + fname
	if FileAccess.file_exists(full_path):
		_status_lbl.text = "File already exists: " + fname
		return false
	var f := FileAccess.open(full_path, FileAccess.WRITE)
	if f == null:
		_status_lbl.text = "ERROR: could not create " + fname
		return false
	f.store_string("[]")
	f.close()
	_scan_files()
	# Select the new file in the list and open it
	for i: int in range(_file_list.item_count):
		if _file_list.get_item_text(i) == fname:
			_file_list.select(i)
			_on_file_selected(i)
			break
	_status_lbl.text = "Created  →  " + fname
	return true

func _on_change_folder_pressed() -> void:
	_folder_dialog.current_dir = ProjectSettings.globalize_path(_scenes_dir)
	_folder_dialog.popup_centered(Vector2(900, 600))

func _on_folder_selected(abs_path: String) -> void:
	# Convert absolute filesystem path back to res:// if possible
	var res_base: String = ProjectSettings.globalize_path("res://")
	var result_dir: String
	if abs_path.begins_with(res_base):
		result_dir = "res://" + abs_path.substr(res_base.length())
	else:
		result_dir = abs_path
	# Ensure trailing slash
	if not result_dir.ends_with("/"):
		result_dir += "/"
	_scenes_dir = result_dir
	if _folder_lbl != null:
		_folder_lbl.text = _scenes_dir
	_scan_files()

# ─────────────────────────────────────────────────────────────
# File scanning / loading
# ─────────────────────────────────────────────────────────────
func _scan_files() -> void:
	_file_list.clear()
	var dir := DirAccess.open(_scenes_dir)
	if dir == null:
		_status_lbl.text = "ERROR: cannot open " + _scenes_dir
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

func _copy_file_name_to_clipboard() -> void:
	if _file_path.is_empty():
		_status_lbl.text = "No file open."
		return
	var fname: String = _file_path.get_file()
	DisplayServer.clipboard_set(fname)
	_status_lbl.text = "Copied file name → %s" % fname

func _copy_beat_name_to_clipboard() -> void:
	if _selected_idx < 0:
		_status_lbl.text = "Select a beat first."
		return
	var beat_name: String = ""
	if _f_beat_name != null:
		beat_name = _f_beat_name.text.strip_edges()
	if beat_name.is_empty() and _selected_idx < _beats.size():
		beat_name = str((_beats[_selected_idx] as Dictionary).get("beat_name", "")).strip_edges()
	if beat_name.is_empty():
		_status_lbl.text = "Beat has no name to copy."
		return
	DisplayServer.clipboard_set(beat_name)
	_status_lbl.text = "Copied beat name → %s" % beat_name

func _copy_bug_ref_to_clipboard() -> void:
	if _file_path.is_empty():
		_status_lbl.text = "No file open."
		return
	if _selected_idx < 0:
		_status_lbl.text = "Select a beat first."
		return
	var fname: String = _file_path.get_file()
	var beat_name: String = ""
	if _f_beat_name != null:
		beat_name = _f_beat_name.text.strip_edges()
	if beat_name.is_empty() and _selected_idx < _beats.size():
		beat_name = str((_beats[_selected_idx] as Dictionary).get("beat_name", "")).strip_edges()
	var parts: PackedStringArray = PackedStringArray([
		fname,
		"beat #%d" % (_selected_idx + 1),
	])
	if beat_name.is_empty():
		parts.append("(no beat_name)")
	else:
		parts.append("name=%s" % beat_name)
	var text: String = " | ".join(parts)
	DisplayServer.clipboard_set(text)
	_status_lbl.text = "Copied bug ref → %s" % text

func _refresh_file_list_colors() -> void:
	for i: int in range(_file_list.item_count):
		var fpath: String = _scenes_dir + _file_list.get_item_text(i)
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
	_load_file(_scenes_dir + _file_list.get_item_text(idx))

func _load_file(path: String) -> void:
	_flush_current_beat()
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
		var b_i: Dictionary = _beats[i] as Dictionary
		var beat_group: int = int(b_i.get("group", 0))
		if b_i.get("choices", []) is Array and not (b_i.get("choices", []) as Array).is_empty():
			_beat_list.set_item_custom_fg_color(i, Color(0.55, 0.88, 1.0))
			var tip_lines: PackedStringArray = PackedStringArray()
			for ch: Variant in (b_i.get("choices", []) as Array):
				if ch is Dictionary:
					var cd: Dictionary = ch as Dictionary
					var goto_group: int = int(cd.get("goto_group", 0))
					if goto_group > 0:
						tip_lines.append("%s → %s" % [
							_choice_label_preview(cd),
							_group_display_label(goto_group)])
					else:
						tip_lines.append("%s → #%d (legacy)" % [
							_choice_label_preview(cd),
							int(cd.get("goto_beat", -1)) + 1])
			if not tip_lines.is_empty():
				_beat_list.set_item_tooltip(i, "\n".join(tip_lines))
		elif beat_group > 0:
			_beat_list.set_item_custom_fg_color(i, Color(0.82, 0.78, 0.55))
			var inc: Array = _incoming_branch_refs(i)
			if not inc.is_empty():
				var tip := "Activated by "
				for ref: Dictionary in inc:
					tip += "%s from #%d (%s)  " % [
						_group_display_label(beat_group),
						int(ref.get("from", 0)) + 1,
						str(ref.get("label", ""))]
				_beat_list.set_item_tooltip(i, tip.strip_edges())
		elif _incoming_branch_refs(i).size() > 0:
			var inc: Array = _incoming_branch_refs(i)
			var tip := "Jumped to from "
			for ref: Dictionary in inc:
				if int(ref.get("group", 0)) > 0:
					tip += "%s via #%d (%s)  " % [
						_group_display_label(int(ref.get("group", 0))),
						int(ref.get("from", 0)) + 1,
						str(ref.get("label", ""))]
				else:
					tip += "#%d (%s)  " % [int(ref.get("from", 0)) + 1, str(ref.get("label", ""))]
			_beat_list.set_item_tooltip(i, tip.strip_edges())
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
	var group_id: int = int(beat.get("group", 0))
	var group_name: String = _group_name_for_id(group_id) if group_id > 0 else ""
	var group_tag: String = ""
	if group_id > 0:
		group_tag = "[GROUP %d: %s] " % [group_id, group_name] if not group_name.is_empty() \
			else "[GROUP %d] " % group_id
	var beat_name: String = str(beat.get("beat_name", "")).strip_edges()
	var name_tag: String = ("[%s] " % beat_name) if not beat_name.is_empty() else ""
	var prefix: String = "#%d %s%s%s%s" % [idx + 1, name_tag, group_tag, hidden_tag, nsfw_tag]
	if beat.has("comment"):
		return prefix + "// " + str(beat["comment"]).left(42)
	var tx: Variant = beat.get("text", "")
	var tx_str: String = ""
	if tx is Dictionary:
		tx_str = str(tx.get("en", tx.get(_languages[0], "")))
	elif tx != null:
		tx_str = str(tx)
	if not tx_str.is_empty():
		var choice_tag: String = _beat_choice_tag(beat)
		if not choice_tag.is_empty():
			return prefix + tx_str.left(36) + "  " + choice_tag
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
	var tut_path: String = str(beat.get("tutorial_battle", "")).strip_edges()
	if tut_path != "":
		var tut_extra := ""
		var tut_win: String = str(beat.get("on_win", "")).strip_edges()
		var tut_lose: String = str(beat.get("on_lose", "")).strip_edges()
		if tut_win != "":
			tut_extra += " →win"
		if tut_lose != "":
			tut_extra += " →lose"
		return prefix + "[tutorial: %s%s]" % [tut_path.get_file().trim_suffix(".json"), tut_extra]
	var expl_call: String = str(beat.get("exploration_call", "")).strip_edges()
	if expl_call != "":
		var expl_extra := ""
		if beat.get("exploration_keep_vn_bgm", false):
			expl_extra = " (vn bgm)"
		return prefix + "[exploration: %s%s]" % [expl_call.get_file(), expl_extra]
	var note_actions: Variant = beat.get("detective_note", null)
	if note_actions is Array and not (note_actions as Array).is_empty():
		return prefix + "[detective note: %d action(s)]" % (note_actions as Array).size()
	var note_icon_mode: String = str(beat.get("detective_note_icon", "")).strip_edges().to_lower()
	if note_icon_mode == "show" or note_icon_mode == "hide":
		return prefix + "[note icon: %s]" % note_icon_mode
	var open_note: Variant = beat.get("show_detective_note", null)
	if open_note is Dictionary or open_note == true:
		var open_label: String = "open note"
		if open_note is Dictionary:
			var od: Dictionary = open_note as Dictionary
			var ot: String = str(od.get("topic", "")).strip_edges()
			var oc: String = str(od.get("chapter", "")).strip_edges()
			if not ot.is_empty():
				open_label = "open note: %s" % ot
			elif not oc.is_empty():
				open_label = "open note: %s" % oc
		return prefix + "[%s]" % open_label
	if beat.get("show_note_stamp", null) is Dictionary:
		var stamp_spec: Dictionary = beat["show_note_stamp"] as Dictionary
		return prefix + "[note stamp: %s]" % str(stamp_spec.get("stamp", "?"))

	var choices: Variant = beat.get("choices", null)
	if choices is Array and not (choices as Array).is_empty():
		var choice_tag: String = _beat_choice_tag(beat)
		return prefix + choice_tag if choice_tag.begins_with("[") else prefix + "[choices]"

	var incoming: Array = _incoming_branch_refs(idx)
	if not incoming.is_empty():
		var from_str := ""
		for ref: Dictionary in incoming:
			if int(ref.get("group", 0)) > 0:
				from_str += ", %s←#%d" % [
					_group_display_label(int(ref.get("group", 0))),
					int(ref.get("from", 0)) + 1]
			else:
				from_str += ", #%d" % (int(ref.get("from", 0)) + 1)
		var tx_in: String = _beat_dialogue_preview(beat)
		if not tx_in.is_empty():
			return prefix + "[←%s] " % from_str + tx_in.left(40)
		return prefix + "[←%s] (branch target)" % from_str.strip_edges().trim_prefix(",")

	if beat.get("go_to_campaign_gallery", false):
		return prefix + "[campaign gallery]"
	if beat.get("go_to_quick_duel", false):
		return prefix + "[quick duel]"
	var go_to: Variant = beat.get("go_to", [])
	if go_to is Array and not (go_to as Array).is_empty():
		var names: PackedStringArray = PackedStringArray()
		for entry: Variant in (go_to as Array):
			if not entry is Dictionary:
				continue
			var target: String = str((entry as Dictionary).get("beat_name", "")).strip_edges()
			if not target.is_empty():
				names.append(target)
		if not names.is_empty():
			return prefix + "[go→%s]" % ", ".join(names)
	var play_group: Variant = beat.get("play_group", [])
	if play_group is Array and not (play_group as Array).is_empty():
		var groups: PackedStringArray = PackedStringArray()
		for entry: Variant in (play_group as Array):
			if not entry is Dictionary:
				continue
			var gid: int = int((entry as Dictionary).get("group", 0))
			if gid > 0:
				groups.append(_group_display_label(gid))
		if not groups.is_empty():
			return prefix + "[play→%s]" % ", ".join(groups)
	if beat.get("complete_current_gallery_chapter", false) \
			or beat.get("unlock_current_gallery_chapter", false):
		return prefix + "[chapter end: current]"
	var complete_vn: String = str(beat.get("complete_gallery_chapter", "")).strip_edges()
	if complete_vn.is_empty():
		complete_vn = str(beat.get("unlock_gallery_chapter", "")).strip_edges()
	if not complete_vn.is_empty():
		return prefix + "[chapter end: %s]" % complete_vn.get_file()
	return prefix + "(empty)"

func _beat_dialogue_preview(beat: Dictionary) -> String:
	var tx: Variant = beat.get("text", "")
	if tx is Dictionary:
		return str(tx.get("en", tx.get(_languages[0], "")))
	elif tx != null:
		return str(tx)
	return ""

func _beat_choice_tag(beat: Dictionary) -> String:
	var choices: Variant = beat.get("choices", null)
	if not choices is Array or (choices as Array).is_empty():
		return ""
	var targets: Array[int] = []
	for ch: Variant in (choices as Array):
		if ch is Dictionary:
			var cd: Dictionary = ch as Dictionary
			var goto_group: int = int(cd.get("goto_group", 0))
			if goto_group > 0 and goto_group not in targets:
				targets.append(goto_group)
	targets.sort()
	var tgt_str := ""
	for t: int in targets:
		tgt_str += ", %s" % _group_display_label(t)
	return "[♦%d →%s]" % [(choices as Array).size(), tgt_str]

func _group_name_for_id(group_id: int) -> String:
	if group_id <= 0:
		return ""
	for i: int in range(_beats.size()):
		if int((_beats[i] as Dictionary).get("group", 0)) != group_id:
			continue
		var name: String = str((_beats[i] as Dictionary).get("group_name", "")).strip_edges()
		if not name.is_empty():
			return name
	return ""

func _group_display_label(group_id: int) -> String:
	if group_id <= 0:
		return ""
	var name: String = _group_name_for_id(group_id)
	if name.is_empty():
		return "G%d" % group_id
	return "G%d: %s" % [group_id, name]

func _refresh_group_name_field() -> void:
	if _f_group_name == null or _f_group == null:
		return
	var show: bool = int(_f_group.value) > 0
	var row: Node = _f_group_name.get_parent()
	if row is CanvasItem:
		(row as CanvasItem).visible = show
	_f_group_name.editable = show

func _sync_group_name_to_beats(group_id: int, group_name: String) -> void:
	if group_id <= 0:
		return
	for i: int in range(_beats.size()):
		var beat: Dictionary = _beats[i] as Dictionary
		if int(beat.get("group", 0)) != group_id:
			continue
		if group_name.is_empty():
			beat.erase("group_name")
		else:
			beat["group_name"] = group_name
		if _beat_list.item_count > i:
			_beat_list.set_item_text(i, _beat_summary(beat, i))

func _populate_goto_group_option(opt: OptionButton, selected_group: int) -> void:
	opt.clear()
	var ids: Array[int] = _known_group_ids()
	if selected_group > 0 and selected_group not in ids:
		ids.append(selected_group)
		ids.sort()
	if ids.is_empty():
		ids = [maxi(1, selected_group)]
	for gid: int in ids:
		opt.add_item(_group_display_label(gid))
		opt.set_item_metadata(opt.item_count - 1, gid)
	for i: int in range(opt.item_count):
		if int(opt.get_item_metadata(i)) == selected_group:
			opt.select(i)
			return
	if opt.item_count > 0:
		opt.select(0)

func _selected_goto_group(opt: OptionButton) -> int:
	if opt == null or opt.item_count <= 0:
		return 1
	return int(opt.get_item_metadata(opt.selected))

func _group_first_beat_index(group_id: int) -> int:
	if group_id <= 0:
		return -1
	for i: int in range(_beats.size()):
		if int((_beats[i] as Dictionary).get("group", 0)) == group_id:
			return i
	return -1

func _known_group_ids() -> Array[int]:
	var ids: Array[int] = []
	for i: int in range(_beats.size()):
		var gid: int = int((_beats[i] as Dictionary).get("group", 0))
		if gid > 0 and gid not in ids:
			ids.append(gid)
	ids.sort()
	return ids

func _incoming_branch_refs(target_idx: int) -> Array:
	var refs: Array = []
	var target_group: int = int((_beats[target_idx] as Dictionary).get("group", 0))
	for bi: int in range(_beats.size()):
		var b: Dictionary = _beats[bi] as Dictionary
		var choices: Variant = b.get("choices", null)
		if not choices is Array:
			continue
		for ch: Variant in (choices as Array):
			if not ch is Dictionary:
				continue
			var cd: Dictionary = ch as Dictionary
			var goto_group: int = int(cd.get("goto_group", 0))
			if goto_group > 0 and target_group > 0 and goto_group == target_group:
				refs.append({
					"from": bi,
					"label": _choice_label_preview(cd),
					"group": goto_group,
				})
			elif int(cd.get("goto_beat", -1)) == target_idx:
				refs.append({
					"from": bi,
					"label": _choice_label_preview(cd),
				})
	return refs

func _outgoing_branch_refs(beat: Dictionary) -> Array:
	var refs: Array = []
	var choices: Variant = beat.get("choices", null)
	if not choices is Array:
		return refs
	for ch: Variant in (choices as Array):
		if not ch is Dictionary:
			continue
		var cd: Dictionary = ch as Dictionary
		var goto_group: int = int(cd.get("goto_group", 0))
		refs.append({
			"label": _choice_label_preview(cd),
			"goto": int(cd.get("goto_beat", -1)),
			"goto_group": goto_group,
		})
	return refs

func _choice_label_preview(choice: Dictionary) -> String:
	var label: Variant = choice.get("label", "")
	if label is Dictionary:
		return str(label.get("en", label.get(_languages[0], "")))
	return str(label)

func _add_choice_condition_row(parent: VBoxContainer, ctype: String = "has_item",
		key: String = "", val: String = "") -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var type_btn := OptionButton.new()
	for t: String in CHOICE_COND_TYPES:
		type_btn.add_item(t)
	var type_idx: int = CHOICE_COND_TYPES.find(ctype)
	type_btn.select(type_idx if type_idx >= 0 else 0)
	type_btn.custom_minimum_size = Vector2(118.0, 0.0)
	type_btn.add_theme_font_size_override("font_size", 12)
	row.add_child(type_btn)
	var key_le := LineEdit.new()
	key_le.text = key
	key_le.placeholder_text = "key"
	key_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_le.add_theme_font_size_override("font_size", 12)
	key_le.text_changed.connect(func(_t: String) -> void: _on_field_changed())
	row.add_child(key_le)
	var val_le := LineEdit.new()
	val_le.text = val
	val_le.placeholder_text = "value"
	val_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_le.add_theme_font_size_override("font_size", 12)
	val_le.text_changed.connect(func(_t: String) -> void: _on_field_changed())
	row.add_child(val_le)
	type_btn.item_selected.connect(func(_i: int) -> void:
		_update_choice_condition_placeholders(type_btn, key_le, val_le)
		_on_field_changed())
	var del := Button.new()
	del.text = "x"
	del.pressed.connect(func() -> void:
		row.queue_free()
		_on_field_changed())
	row.add_child(del)
	row.set_meta("type_btn", type_btn)
	row.set_meta("key_le", key_le)
	row.set_meta("val_le", val_le)
	_update_choice_condition_placeholders(type_btn, key_le, val_le)

func _update_choice_condition_placeholders(
		type_btn: OptionButton, key_le: LineEdit, val_le: LineEdit) -> void:
	if type_btn == null or key_le == null or val_le == null:
		return
	var ctype: String = type_btn.get_item_text(type_btn.selected)
	if ctype.begins_with("flag_"):
		key_le.placeholder_text = "flag key"
		val_le.placeholder_text = "expected value (e.g. 1)"
	elif ctype == "at_node":
		key_le.placeholder_text = "node id"
		val_le.placeholder_text = "value (optional)"
	elif ctype.begins_with("var_"):
		key_le.placeholder_text = "var key"
		val_le.placeholder_text = "value"
	else:
		key_le.placeholder_text = "key"
		val_le.placeholder_text = "value"

func _add_choice_action_row(parent: VBoxContainer, action: String = "set_var",
		key: String = "", val: String = "") -> void:
	_add_action_row(parent, action, key, val)

func _add_action_row(parent: VBoxContainer, action: String = "set_var",
		key: String = "", val: String = "") -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var act_btn := OptionButton.new()
	for a: String in CHOICE_ACTION_TYPES:
		act_btn.add_item(a)
	var act_idx: int = CHOICE_ACTION_TYPES.find(action)
	act_btn.select(act_idx if act_idx >= 0 else 0)
	act_btn.custom_minimum_size = Vector2(110.0, 0.0)
	act_btn.add_theme_font_size_override("font_size", 12)
	row.add_child(act_btn)
	var key_le := LineEdit.new()
	key_le.text = key
	key_le.placeholder_text = "key"
	key_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_le.add_theme_font_size_override("font_size", 12)
	key_le.text_changed.connect(func(_t: String) -> void: _on_field_changed())
	row.add_child(key_le)
	var val_le := LineEdit.new()
	val_le.text = val
	val_le.placeholder_text = "value"
	val_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_le.add_theme_font_size_override("font_size", 12)
	val_le.text_changed.connect(func(_t: String) -> void: _on_field_changed())
	row.add_child(val_le)
	act_btn.item_selected.connect(func(_i: int) -> void:
		_update_action_row_placeholders(act_btn, key_le, val_le)
		_on_field_changed())
	var del := Button.new()
	del.text = "x"
	del.pressed.connect(func() -> void:
		row.queue_free()
		_on_field_changed())
	row.add_child(del)
	row.set_meta("act_btn", act_btn)
	row.set_meta("key_le", key_le)
	row.set_meta("val_le", val_le)
	_update_action_row_placeholders(act_btn, key_le, val_le)

func _update_action_row_placeholders(
		act_btn: OptionButton, key_le: LineEdit, val_le: LineEdit) -> void:
	if act_btn == null or key_le == null or val_le == null:
		return
	var action: String = act_btn.get_item_text(act_btn.selected)
	match action:
		"set_flag":
			key_le.placeholder_text = "flag key"
			val_le.placeholder_text = "flag value (e.g. 1)"
		"set_var":
			key_le.placeholder_text = "var key"
			val_le.placeholder_text = "value"
		"give_item", "remove_item":
			key_le.placeholder_text = "item id"
			val_le.placeholder_text = "unused"
		"show_message":
			key_le.placeholder_text = "unused"
			val_le.placeholder_text = "message text"
		_:
			key_le.placeholder_text = "key"
			val_le.placeholder_text = "value"

func _rebuild_exploration_action_rows(actions: Array) -> void:
	_clear_vbox(_exploration_actions_vbox)
	for a: Variant in actions:
		if not a is Dictionary:
			continue
		var ad: Dictionary = a as Dictionary
		_add_action_row(
			_exploration_actions_vbox,
			str(ad.get("action", "set_var")),
			str(ad.get("key", "")),
			str(ad.get("value", "")))

func _add_go_to_row_from(data: Dictionary = {}) -> void:
	if _go_to_vbox == null:
		return
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.14, 0.10, 0.95)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.45, 0.85, 0.55, 0.45)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	frame.add_theme_stylebox_override("panel", sb)
	_go_to_vbox.add_child(frame)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	frame.add_child(vb)

	var hdr := HBoxContainer.new()
	vb.add_child(hdr)
	var hdr_lbl := Label.new()
	hdr_lbl.text = "Go To"
	hdr_lbl.add_theme_font_size_override("font_size", 13)
	hdr_lbl.add_theme_color_override("font_color", Color(0.65, 1.0, 0.75))
	hdr.add_child(hdr_lbl)
	var hdr_spacer := Control.new()
	hdr_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(hdr_spacer)
	var rem_btn := Button.new()
	rem_btn.text = "Remove"
	rem_btn.add_theme_font_size_override("font_size", 12)
	rem_btn.pressed.connect(func() -> void:
		frame.queue_free()
		_on_field_changed())
	hdr.add_child(rem_btn)

	var name_row := HBoxContainer.new()
	vb.add_child(name_row)
	var name_lbl := Label.new()
	name_lbl.text = "Beat name"
	name_lbl.custom_minimum_size.x = 80.0
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_row.add_child(name_lbl)
	var name_le := LineEdit.new()
	name_le.placeholder_text = "target beat_name"
	name_le.text = str(data.get("beat_name", ""))
	name_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_le.add_theme_font_size_override("font_size", 13)
	name_le.text_changed.connect(func(_t: String) -> void: _on_field_changed())
	name_row.add_child(name_le)

	var cond_hdr := HBoxContainer.new()
	cond_hdr.add_theme_constant_override("separation", 6)
	vb.add_child(cond_hdr)
	var cond_lbl := Label.new()
	cond_lbl.text = "Conditions"
	cond_lbl.add_theme_font_size_override("font_size", 12)
	cond_hdr.add_child(cond_lbl)
	var cond_mode_opt := OptionButton.new()
	cond_mode_opt.add_item("AND")
	cond_mode_opt.add_item("OR")
	var cond_mode: String = str(data.get("conditions_mode", "and")).strip_edges().to_lower()
	cond_mode_opt.selected = 1 if cond_mode == "or" else 0
	cond_mode_opt.custom_minimum_size = Vector2(72.0, 0.0)
	cond_mode_opt.add_theme_font_size_override("font_size", 12)
	cond_mode_opt.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	cond_hdr.add_child(cond_mode_opt)
	var cond_hint := Label.new()
	cond_hint.text = "— empty = always"
	cond_hint.add_theme_font_size_override("font_size", 12)
	cond_hint.add_theme_color_override("font_color", Color(0.65, 0.72, 0.82))
	cond_hdr.add_child(cond_hint)
	var cond_vbox := VBoxContainer.new()
	cond_vbox.add_theme_constant_override("separation", 2)
	vb.add_child(cond_vbox)
	var add_cond := Button.new()
	add_cond.text = "+ Condition"
	add_cond.add_theme_font_size_override("font_size", 12)
	add_cond.pressed.connect(func() -> void:
		_add_choice_condition_row(cond_vbox)
		_on_field_changed())
	vb.add_child(add_cond)
	var conds: Variant = data.get("conditions", [])
	if conds is Array:
		for c: Variant in (conds as Array):
			if c is Dictionary:
				var cd: Dictionary = c as Dictionary
				_add_choice_condition_row(cond_vbox,
					str(cd.get("type", "var_equals")),
					str(cd.get("key", "")),
					str(cd.get("value", "")))

	frame.set_meta("name_le", name_le)
	frame.set_meta("cond_vbox", cond_vbox)
	frame.set_meta("cond_mode_opt", cond_mode_opt)

func _add_go_to_row() -> void:
	if _selected_idx < 0:
		return
	_add_go_to_row_from({})
	_on_field_changed()

func _rebuild_go_to_rows(entries: Array) -> void:
	if _go_to_vbox == null:
		return
	_clear_vbox(_go_to_vbox)
	for entry: Variant in entries:
		if entry is Dictionary:
			_add_go_to_row_from(entry as Dictionary)

func _collect_go_to() -> Array:
	var out: Array = []
	if _go_to_vbox == null:
		return out
	for frame: Node in _go_to_vbox.get_children():
		if not frame is PanelContainer:
			continue
		var name_le: LineEdit = frame.get_meta("name_le") as LineEdit
		var cond_vbox: VBoxContainer = frame.get_meta("cond_vbox") as VBoxContainer
		var cond_mode_opt: OptionButton = frame.get_meta("cond_mode_opt") as OptionButton
		if name_le == null:
			continue
		var beat_name: String = name_le.text.strip_edges()
		if beat_name.is_empty():
			continue
		var entry: Dictionary = {"beat_name": beat_name}
		var conds: Array = _collect_conditions_from_vbox(cond_vbox)
		if not conds.is_empty():
			entry["conditions"] = conds
			if cond_mode_opt != null and cond_mode_opt.selected == 1:
				entry["conditions_mode"] = "or"
		out.append(entry)
	return out

func _add_play_group_row_from(data: Dictionary = {}) -> void:
	if _play_group_vbox == null:
		return
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, 0.95)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.55, 0.65, 1.0, 0.45)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	frame.add_theme_stylebox_override("panel", sb)
	_play_group_vbox.add_child(frame)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	frame.add_child(vb)

	var hdr := HBoxContainer.new()
	vb.add_child(hdr)
	var hdr_lbl := Label.new()
	hdr_lbl.text = "Play Group"
	hdr_lbl.add_theme_font_size_override("font_size", 13)
	hdr_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	hdr.add_child(hdr_lbl)
	var hdr_spacer := Control.new()
	hdr_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(hdr_spacer)
	var rem_btn := Button.new()
	rem_btn.text = "Remove"
	rem_btn.add_theme_font_size_override("font_size", 12)
	rem_btn.pressed.connect(func() -> void:
		frame.queue_free()
		_on_field_changed())
	hdr.add_child(rem_btn)

	var group_row := HBoxContainer.new()
	vb.add_child(group_row)
	var group_lbl := Label.new()
	group_lbl.text = "Group"
	group_lbl.custom_minimum_size.x = 80.0
	group_lbl.add_theme_font_size_override("font_size", 13)
	group_row.add_child(group_lbl)
	var group_opt := OptionButton.new()
	group_opt.add_theme_font_size_override("font_size", 13)
	var target_group: int = int(data.get("group", 0))
	_populate_goto_group_option(group_opt, maxi(1, target_group))
	group_opt.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	group_row.add_child(group_opt)

	var cond_hdr := HBoxContainer.new()
	cond_hdr.add_theme_constant_override("separation", 6)
	vb.add_child(cond_hdr)
	var cond_lbl := Label.new()
	cond_lbl.text = "Conditions"
	cond_lbl.add_theme_font_size_override("font_size", 12)
	cond_hdr.add_child(cond_lbl)
	var cond_mode_opt := OptionButton.new()
	cond_mode_opt.add_item("AND")
	cond_mode_opt.add_item("OR")
	var cond_mode: String = str(data.get("conditions_mode", "and")).strip_edges().to_lower()
	cond_mode_opt.selected = 1 if cond_mode == "or" else 0
	cond_mode_opt.custom_minimum_size = Vector2(72.0, 0.0)
	cond_mode_opt.add_theme_font_size_override("font_size", 12)
	cond_mode_opt.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	cond_hdr.add_child(cond_mode_opt)
	var cond_hint := Label.new()
	cond_hint.text = "— empty = always"
	cond_hint.add_theme_font_size_override("font_size", 12)
	cond_hint.add_theme_color_override("font_color", Color(0.65, 0.72, 0.82))
	cond_hdr.add_child(cond_hint)
	var cond_vbox := VBoxContainer.new()
	cond_vbox.add_theme_constant_override("separation", 2)
	vb.add_child(cond_vbox)
	var add_cond := Button.new()
	add_cond.text = "+ Condition"
	add_cond.add_theme_font_size_override("font_size", 12)
	add_cond.pressed.connect(func() -> void:
		_add_choice_condition_row(cond_vbox)
		_on_field_changed())
	vb.add_child(add_cond)
	var conds: Variant = data.get("conditions", [])
	if conds is Array:
		for c: Variant in (conds as Array):
			if c is Dictionary:
				var cd: Dictionary = c as Dictionary
				_add_choice_condition_row(cond_vbox,
					str(cd.get("type", "var_equals")),
					str(cd.get("key", "")),
					str(cd.get("value", "")))

	frame.set_meta("group_opt", group_opt)
	frame.set_meta("cond_vbox", cond_vbox)
	frame.set_meta("cond_mode_opt", cond_mode_opt)

func _add_play_group_row() -> void:
	if _selected_idx < 0:
		return
	_add_play_group_row_from({})
	_on_field_changed()

func _rebuild_play_group_rows(entries: Array) -> void:
	if _play_group_vbox == null:
		return
	_clear_vbox(_play_group_vbox)
	for entry: Variant in entries:
		if entry is Dictionary:
			_add_play_group_row_from(entry as Dictionary)

func _collect_play_group() -> Array:
	var out: Array = []
	if _play_group_vbox == null:
		return out
	for frame: Node in _play_group_vbox.get_children():
		if not frame is PanelContainer:
			continue
		var group_opt: OptionButton = frame.get_meta("group_opt") as OptionButton
		var cond_vbox: VBoxContainer = frame.get_meta("cond_vbox") as VBoxContainer
		var cond_mode_opt: OptionButton = frame.get_meta("cond_mode_opt") as OptionButton
		if group_opt == null:
			continue
		var group_id: int = _selected_goto_group(group_opt)
		if group_id <= 0:
			continue
		var entry: Dictionary = {"group": group_id}
		var conds: Array = _collect_conditions_from_vbox(cond_vbox)
		if not conds.is_empty():
			entry["conditions"] = conds
			if cond_mode_opt != null and cond_mode_opt.selected == 1:
				entry["conditions_mode"] = "or"
		out.append(entry)
	return out

func _add_choice_row_from(data: Dictionary = {}) -> void:
	if _choices_vbox == null:
		return
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.22, 0.95)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.35, 0.62, 1.0, 0.45)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	frame.add_theme_stylebox_override("panel", sb)
	_choices_vbox.add_child(frame)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	frame.add_child(vb)

	var hdr := HBoxContainer.new()
	vb.add_child(hdr)
	var hdr_lbl := Label.new()
	hdr_lbl.text = "Choice"
	hdr_lbl.add_theme_font_size_override("font_size", 13)
	hdr_lbl.add_theme_color_override("font_color", Color(0.65, 0.88, 1.0))
	hdr.add_child(hdr_lbl)
	var hdr_spacer := Control.new()
	hdr_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(hdr_spacer)
	var rem_btn := Button.new()
	rem_btn.text = "Remove"
	rem_btn.add_theme_font_size_override("font_size", 12)
	rem_btn.pressed.connect(func() -> void:
		frame.queue_free()
		_on_field_changed())
	hdr.add_child(rem_btn)

	var label_le := LineEdit.new()
	label_le.placeholder_text = "Choice label (en)"
	label_le.text = _choice_label_preview(data)
	label_le.add_theme_font_size_override("font_size", 13)
	label_le.text_changed.connect(func(_t: String) -> void: _on_field_changed())
	vb.add_child(label_le)

	var goto_row := HBoxContainer.new()
	vb.add_child(goto_row)
	var goto_lbl := Label.new()
	goto_lbl.text = "Goto group"
	goto_lbl.add_theme_font_size_override("font_size", 13)
	goto_row.add_child(goto_lbl)
	var goto_opt := OptionButton.new()
	goto_opt.add_theme_font_size_override("font_size", 13)
	var goto_group: int = int(data.get("goto_group", 0))
	if goto_group <= 0 and int(data.get("goto_beat", -1)) >= 0:
		var legacy_beat: int = int(data.get("goto_beat", -1))
		for bi: int in range(_beats.size()):
			if int((_beats[bi] as Dictionary).get("group", 0)) > 0 and bi == legacy_beat:
				goto_group = int((_beats[bi] as Dictionary).get("group", 0))
				break
	_populate_goto_group_option(goto_opt, maxi(1, goto_group))
	goto_opt.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	goto_row.add_child(goto_opt)

	var lock_row := HBoxContainer.new()
	vb.add_child(lock_row)
	var lock_lbl := Label.new()
	lock_lbl.text = "Locked"
	lock_lbl.add_theme_font_size_override("font_size", 13)
	lock_row.add_child(lock_lbl)
	var lock_opt := OptionButton.new()
	lock_opt.add_item("Hide")
	lock_opt.add_item("Disable")
	var lm: String = str(data.get("locked_mode", "hide")).to_lower()
	lock_opt.selected = 1 if lm == "disable" else 0
	lock_opt.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	lock_row.add_child(lock_opt)

	var dis_le := LineEdit.new()
	dis_le.placeholder_text = "Disabled reason (optional — tooltip on hover when locked)"
	var reason_src: Variant = data.get("disabled_reason", data.get("disabled_label", ""))
	dis_le.text = _choice_label_preview({"label": reason_src})
	dis_le.add_theme_font_size_override("font_size", 12)
	dis_le.text_changed.connect(func(_t: String) -> void: _on_field_changed())
	vb.add_child(dis_le)

	var cond_lbl := Label.new()
	cond_lbl.text = "Conditions (AND)"
	cond_lbl.add_theme_font_size_override("font_size", 12)
	vb.add_child(cond_lbl)
	var cond_vbox := VBoxContainer.new()
	cond_vbox.add_theme_constant_override("separation", 2)
	vb.add_child(cond_vbox)
	var add_cond := Button.new()
	add_cond.text = "+ Condition"
	add_cond.add_theme_font_size_override("font_size", 12)
	add_cond.pressed.connect(func() -> void:
		_add_choice_condition_row(cond_vbox)
		_on_field_changed())
	vb.add_child(add_cond)
	var conds: Variant = data.get("conditions", [])
	if conds is Array:
		for c: Variant in (conds as Array):
			if c is Dictionary:
				var cd: Dictionary = c as Dictionary
				_add_choice_condition_row(cond_vbox,
					str(cd.get("type", "has_item")),
					str(cd.get("key", "")),
					str(cd.get("value", "")))

	var act_lbl := Label.new()
	act_lbl.text = "Actions on pick"
	act_lbl.add_theme_font_size_override("font_size", 12)
	vb.add_child(act_lbl)
	var act_vbox := VBoxContainer.new()
	act_vbox.add_theme_constant_override("separation", 2)
	vb.add_child(act_vbox)
	var add_act := Button.new()
	add_act.text = "+ Action"
	add_act.add_theme_font_size_override("font_size", 12)
	add_act.pressed.connect(func() -> void:
		_add_choice_action_row(act_vbox)
		_on_field_changed())
	vb.add_child(add_act)
	var actions: Variant = data.get("actions", [])
	if actions is Array:
		for a: Variant in (actions as Array):
			if a is Dictionary:
				var ad: Dictionary = a as Dictionary
				_add_choice_action_row(act_vbox,
					str(ad.get("action", "set_var")),
					str(ad.get("key", "")),
					str(ad.get("value", "")))

	frame.set_meta("label_le", label_le)
	frame.set_meta("goto_opt", goto_opt)
	frame.set_meta("lock_opt", lock_opt)
	frame.set_meta("dis_le", dis_le)
	frame.set_meta("cond_vbox", cond_vbox)
	frame.set_meta("act_vbox", act_vbox)

func _add_choice_row() -> void:
	if _selected_idx < 0:
		return
	_add_choice_row_from({})
	_on_field_changed()

func _rebuild_choice_rows(choices: Array) -> void:
	_clear_vbox(_choices_vbox)
	for ch: Variant in choices:
		if ch is Dictionary:
			_add_choice_row_from(ch as Dictionary)

func _collect_conditions_from_vbox(cond_vbox: VBoxContainer) -> Array:
	var out: Array = []
	if cond_vbox == null:
		return out
	for row: Node in cond_vbox.get_children():
		if not row is HBoxContainer:
			continue
		var type_btn: OptionButton = row.get_meta("type_btn") as OptionButton
		var key_le: LineEdit = row.get_meta("key_le") as LineEdit
		var val_le: LineEdit = row.get_meta("val_le") as LineEdit
		if type_btn == null or key_le == null:
			continue
		var ctype: String = type_btn.get_item_text(type_btn.selected)
		var key: String = key_le.text.strip_edges()
		if key.is_empty() and ctype != "at_node":
			continue
		out.append({
			"type": ctype,
			"key": key,
			"value": val_le.text.strip_edges() if val_le != null else "",
		})
	return out

func _collect_actions_from_vbox(act_vbox: VBoxContainer) -> Array:
	var out: Array = []
	if act_vbox == null:
		return out
	for row: Node in act_vbox.get_children():
		if not row is HBoxContainer:
			continue
		var act_btn: OptionButton = row.get_meta("act_btn") as OptionButton
		var key_le: LineEdit = row.get_meta("key_le") as LineEdit
		var val_le: LineEdit = row.get_meta("val_le") as LineEdit
		if act_btn == null:
			continue
		out.append({
			"action": act_btn.get_item_text(act_btn.selected),
			"key": key_le.text.strip_edges() if key_le != null else "",
			"value": val_le.text.strip_edges() if val_le != null else "",
		})
	return out

func _collect_choices() -> Array:
	var choices: Array = []
	if _choices_vbox == null:
		return choices
	for frame: Node in _choices_vbox.get_children():
		if not frame is PanelContainer:
			continue
		var label_le: LineEdit = frame.get_meta("label_le") as LineEdit
		var goto_opt: OptionButton = frame.get_meta("goto_opt") as OptionButton
		var lock_opt: OptionButton = frame.get_meta("lock_opt") as OptionButton
		var dis_le: LineEdit = frame.get_meta("dis_le") as LineEdit
		var cond_vbox: VBoxContainer = frame.get_meta("cond_vbox") as VBoxContainer
		var act_vbox: VBoxContainer = frame.get_meta("act_vbox") as VBoxContainer
		if label_le == null or goto_opt == null:
			continue
		var label: String = label_le.text.strip_edges()
		if label.is_empty():
			continue
		var cd: Dictionary = {
			"label": label,
			"goto_group": _selected_goto_group(goto_opt),
		}
		if lock_opt != null and lock_opt.selected == 1:
			cd["locked_mode"] = "disable"
			var reason: String = dis_le.text.strip_edges() if dis_le != null else ""
			if not reason.is_empty():
				cd["disabled_reason"] = reason
		var conds: Array = _collect_conditions_from_vbox(cond_vbox)
		if not conds.is_empty():
			cd["conditions"] = conds
		var acts: Array = _collect_actions_from_vbox(act_vbox)
		if not acts.is_empty():
			cd["actions"] = acts
		choices.append(cd)
	return choices

func _update_branch_bar(idx: int) -> void:
	if _branch_bar == null:
		return
	for child: Node in _branch_bar.get_children():
		child.queue_free()
	if idx < 0 or idx >= _beats.size():
		_branch_bar.visible = false
		return
	var beat: Dictionary = _beats[idx] as Dictionary
	var incoming: Array = _incoming_branch_refs(idx)
	var outgoing: Array = _outgoing_branch_refs(beat)
	if incoming.is_empty() and outgoing.is_empty():
		_branch_bar.visible = false
		return
	_branch_bar.visible = true
	var title := Label.new()
	title.text = "Branches:"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	_branch_bar.add_child(title)
	for ref: Dictionary in incoming:
		var from_i: int = int(ref.get("from", 0))
		var from_name: String = str((_beats[from_i] as Dictionary).get("beat_name", "")).strip_edges()
		var btn := Button.new()
		btn.text = "← #%d%s" % [from_i + 1, (" [%s]" % from_name) if not from_name.is_empty() else ""]
		btn.tooltip_text = str(ref.get("label", ""))
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func() -> void: _jump_to_beat(from_i))
		_branch_bar.add_child(btn)
	if not incoming.is_empty() and not outgoing.is_empty():
		var sep := Label.new()
		sep.text = "|"
		_branch_bar.add_child(sep)
	for ref: Dictionary in outgoing:
		var goto_group: int = int(ref.get("goto_group", 0))
		if goto_group > 0:
			var goto_i: int = _group_first_beat_index(goto_group)
			if goto_i < 0:
				continue
			var goto_name: String = str((_beats[goto_i] as Dictionary).get("beat_name", "")).strip_edges()
			var btn := Button.new()
			var label: String = _group_display_label(goto_group)
			if not goto_name.is_empty():
				label += " [%s]" % goto_name
			btn.text = "→ %s" % label
			btn.tooltip_text = str(ref.get("label", ""))
			btn.add_theme_font_size_override("font_size", 12)
			btn.pressed.connect(func() -> void: _jump_to_beat(goto_i))
			_branch_bar.add_child(btn)
			continue
		var goto_i: int = int(ref.get("goto", -1))
		if goto_i < 0:
			continue
		var goto_name: String = str((_beats[goto_i] as Dictionary).get("beat_name", "")).strip_edges()
		var btn := Button.new()
		btn.text = "→ #%d%s" % [goto_i + 1, (" [%s]" % goto_name) if not goto_name.is_empty() else ""]
		btn.tooltip_text = str(ref.get("label", ""))
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func() -> void: _jump_to_beat(goto_i))
		_branch_bar.add_child(btn)

func _jump_to_beat(idx: int) -> void:
	if idx < 0 or idx >= _beats.size():
		return
	_flush_current_beat()
	_selected_idx = idx
	_anchor_idx = idx
	_beat_list.deselect_all()
	_beat_list.select(idx)
	_show_fields(true)
	_populate_fields()
	_update_branch_bar(idx)

func _beat_index_for_name(beat_name: String) -> int:
	var needle: String = beat_name.strip_edges()
	if needle.is_empty():
		return -1
	for i: int in range(_beats.size()):
		if str((_beats[i] as Dictionary).get("beat_name", "")).strip_edges() == needle:
			return i
	return -1

func _go_to_beat_by_name(name: String) -> void:
	var idx: int = _beat_index_for_name(name)
	if idx < 0:
		_status_lbl.text = "Beat name not found: %s" % name.strip_edges()
		return
	_jump_to_beat(idx)
	var beat_name: String = str((_beats[idx] as Dictionary).get("beat_name", "")).strip_edges()
	_status_lbl.text = "Jumped to #%d [%s]" % [idx + 1, beat_name]

func _validate_beat_names() -> Array[String]:
	var warnings: Array[String] = []
	var seen: Dictionary = {}
	for i: int in range(_beats.size()):
		var name: String = str((_beats[i] as Dictionary).get("beat_name", "")).strip_edges()
		if name.is_empty():
			continue
		if seen.has(name):
			warnings.append("duplicate beat_name '%s' at #%d and #%d" % [
				name, int(seen[name]) + 1, i + 1])
		else:
			seen[name] = i
	return warnings

func _validate_choice_beat(beat: Dictionary, idx: int) -> void:
	if _status_lbl == null:
		return
	var warnings: Array[String] = []
	var choices: Variant = beat.get("choices", null)
	if not choices is Array or (choices as Array).is_empty():
		return
	if beat.get("start_battle", false) or str(beat.get("exploration_call", "")).strip_edges() != "":
		warnings.append("choices conflict with battle/exploration handoff")
	if (choices as Array).size() >= 8:
		warnings.append("%d choices — consider splitting beat" % (choices as Array).size())
	if int(beat.get("group", 0)) > 0:
		warnings.append("choice beat should not belong to a group")
	for ch: Variant in (choices as Array):
		if not ch is Dictionary:
			continue
		var goto_group: int = int((ch as Dictionary).get("goto_group", 0))
		if goto_group <= 0:
			warnings.append("choice missing goto_group")
		elif _group_first_beat_index(goto_group) < 0:
			warnings.append("goto_group %s not defined" % _group_display_label(goto_group))
		elif goto_group == int(beat.get("group", 0)) and int(beat.get("group", 0)) > 0:
			warnings.append("choice loops to same group (%s)" % _group_display_label(goto_group))
	var beat_group: int = int(beat.get("group", 0))
	if beat_group > 0 and _incoming_branch_refs(idx).is_empty():
		warnings.append("group %s has no incoming choice" % _group_display_label(beat_group))
	var go_to: Variant = beat.get("go_to", [])
	var play_group: Variant = beat.get("play_group", [])
	var has_choices: bool = beat.get("choices", []) is Array \
			and not (beat.get("choices", []) as Array).is_empty()
	if go_to is Array and not (go_to as Array).is_empty():
		if has_choices:
			warnings.append("go_to ignored when choices are present")
		for entry: Variant in (go_to as Array):
			if not entry is Dictionary:
				continue
			var target: String = str((entry as Dictionary).get("beat_name", "")).strip_edges()
			if target.is_empty():
				warnings.append("go_to entry missing beat_name")
			elif _beat_index_for_name(target) < 0:
				warnings.append("go_to target '%s' not found" % target)
	if play_group is Array and not (play_group as Array).is_empty():
		if has_choices:
			warnings.append("play_group ignored when choices are present")
		if go_to is Array and not (go_to as Array).is_empty():
			warnings.append("play_group and go_to on same beat — play_group takes priority")
		for entry: Variant in (play_group as Array):
			if not entry is Dictionary:
				continue
			var pg_group: int = int((entry as Dictionary).get("group", 0))
			if pg_group <= 0:
				warnings.append("play_group entry missing group")
			elif _group_first_beat_index(pg_group) < 0:
				warnings.append("play_group %s not defined" % _group_display_label(pg_group))
			elif pg_group == int(beat.get("group", 0)) and int(beat.get("group", 0)) > 0:
				warnings.append("play_group loops to same group (%s)" % _group_display_label(pg_group))
	if not warnings.is_empty():
		_status_lbl.text = "Warning: " + ", ".join(warnings)

# ─────────────────────────────────────────────────────────────
# Beat selection / field display
# ─────────────────────────────────────────────────────────────
func _on_beat_selected(idx: int) -> void:
	_flush_current_beat()
	_selected_idx = idx
	_anchor_idx = idx
	_populate_fields()
	_show_fields(true)
	_update_branch_bar(idx)

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

	_f_beat_name.text = str(b.get("beat_name", ""))
	_f_comment.text = str(b.get("comment", ""))
	_f_hidden.button_pressed = b.get("hidden", false)
	if _f_group != null:
		_f_group.value = float(int(b.get("group", 0)))
	if _f_group_name != null:
		var pop_group: int = int(b.get("group", 0))
		_f_group_name.text = _group_name_for_id(pop_group) if pop_group > 0 else ""
	_refresh_group_name_field()
	_populate_locale_fields(b)

	var layout: String = str(b.get("choices_layout", "above_dialog")).strip_edges()
	if _f_choices_layout != null:
		_f_choices_layout.selected = 1 if layout == "inside_dialog" else 0
	var choices: Variant = b.get("choices", [])
	_rebuild_choice_rows(choices if choices is Array else [])
	var go_to: Variant = b.get("go_to", [])
	_rebuild_go_to_rows(go_to if go_to is Array else [])
	var play_group: Variant = b.get("play_group", [])
	_rebuild_play_group_rows(play_group if play_group is Array else [])
	var expl_actions: Variant = b.get("exploration_actions", [])
	_rebuild_exploration_action_rows(expl_actions if expl_actions is Array else [])

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
		if _f_kb_delay != null:
			_f_kb_delay.value = float(kb.get("delay", 0.0))
		_populate_optional_kb_spin(kb, "start_velocity", _f_kb_start_velocity_cb, _f_kb_start_velocity, 1.0)
		_populate_optional_kb_spin(kb, "stop_velocity", _f_kb_stop_velocity_cb, _f_kb_stop_velocity, 1.0)
		if _f_kb_start_zoom_cb != null:
			_f_kb_start_zoom_cb.button_pressed = kb.has("start_zoom")
			_f_kb_start_zoom.editable = kb.has("start_zoom")
			if kb.has("start_zoom"):
				_f_kb_start_zoom.value = float(kb["start_zoom"])
			else:
				_f_kb_start_zoom.value = 1.0
		if _f_kb_start_pan_x_cb != null:
			_f_kb_start_pan_x_cb.button_pressed = kb.has("start_pan_x")
			_f_kb_start_pan_x.editable = kb.has("start_pan_x")
			if kb.has("start_pan_x"):
				_f_kb_start_pan_x.value = float(kb["start_pan_x"])
			else:
				_f_kb_start_pan_x.value = 0.0
		if _f_kb_start_pan_y_cb != null:
			_f_kb_start_pan_y_cb.button_pressed = kb.has("start_pan_y")
			_f_kb_start_pan_y.editable = kb.has("start_pan_y")
			if kb.has("start_pan_y"):
				_f_kb_start_pan_y.value = float(kb["start_pan_y"])
			else:
				_f_kb_start_pan_y.value = 0.0
	else:
		_f_kb_zoom.value = 1.0; _f_kb_pan_x.value = 0.0
		_f_kb_pan_y.value = 0.0; _f_kb_duration.value = 0.0
		if _f_kb_delay != null:
			_f_kb_delay.value = 0.0
		_reset_optional_kb_spin(_f_kb_start_velocity_cb, _f_kb_start_velocity, 1.0)
		_reset_optional_kb_spin(_f_kb_stop_velocity_cb, _f_kb_stop_velocity, 1.0)
		if _f_kb_start_zoom_cb != null:
			_f_kb_start_zoom_cb.button_pressed = false
			_f_kb_start_zoom.editable = false
			_f_kb_start_zoom.value = 1.0
		if _f_kb_start_pan_x_cb != null:
			_f_kb_start_pan_x_cb.button_pressed = false
			_f_kb_start_pan_x.editable = false
			_f_kb_start_pan_x.value = 0.0
		if _f_kb_start_pan_y_cb != null:
			_f_kb_start_pan_y_cb.button_pressed = false
			_f_kb_start_pan_y.editable = false
			_f_kb_start_pan_y.value = 0.0

	var music: Variant = b.get("music", "")
	_f_music.text = "null" if music == null else (str(music) if music != "" else "")
	_f_music_fade_in.value  = float(b.get("music_fade_in",  0.0))
	_f_music_fade_out.value = float(b.get("music_fade_out", 0.0))
	if _f_music_force != null:
		_f_music_force.button_pressed = bool(b.get("music_force", false))

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

	# Do NOT use bool(ss) on numbers — bool(8.0) is true in GDScript and was
	# forcing every non-zero magnitude to display as the legacy default 10.
	var ss: Variant = b.get("shake_screen", null)
	if ss == null:
		_f_shake_screen.value = 0.0
	elif typeof(ss) == TYPE_BOOL:
		_f_shake_screen.value = 10.0 if bool(ss) else 0.0
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
	_f_go_to_campaign_gallery.button_pressed = b.get("go_to_campaign_gallery", false)
	_f_go_to_quick_duel.button_pressed = b.get("go_to_quick_duel", false)
	_select_opt(_f_unlock_protagonist, str(b.get("unlock_protagonist", "")))
	_select_opt(_f_unlock_protagonist_vault, str(b.get("unlock_protagonist_vault", "")))
	_select_opt(_f_silent_switch_protagonist, str(b.get("silent_switch_protagonist", "")))
	_f_show_protagonist_select.button_pressed = bool(b.get("show_protagonist_select", false))
	_select_opt(_f_clear_limited_protagonist, str(b.get("clear_limited_protagonist", "")))
	_select_opt(_f_set_limited_caps_id, str(b.get("set_limited_caps_protagonist", "")))
	if _f_set_limited_units != null:
		var caps: Variant = b.get("set_limited_caps", {})
		if caps is Dictionary:
			_f_set_limited_units.value = int((caps as Dictionary).get("characters", 0))
			_f_set_limited_traps.value = int((caps as Dictionary).get("traps", 0))
			_f_set_limited_techs.value = int((caps as Dictionary).get("techs", 0))
		else:
			_f_set_limited_units.value = 0
			_f_set_limited_traps.value = 0
			_f_set_limited_techs.value = 0
	_f_mark_chapter_end.button_pressed = _beat_has_chapter_end(b)
	_f_unlock_gallery_opt.selected = 0
	if b.get("complete_current_gallery_chapter", false) \
			or b.get("unlock_current_gallery_chapter", false):
		_f_unlock_gallery_opt.selected = 1
	else:
		var complete_vn: String = str(b.get("complete_gallery_chapter", "")).strip_edges()
		if complete_vn.is_empty():
			complete_vn = str(b.get("unlock_gallery_chapter", "")).strip_edges()
		if not complete_vn.is_empty():
			for i: int in range(_gallery_unlock_paths.size()):
				if _gallery_unlock_paths[i] == complete_vn:
					_f_unlock_gallery_opt.selected = i
					break
	_sync_chapter_end_fields()
	var _cs_map: Array = ["", "credit", "credit_demo", "photo_scatter"]
	var _cs_val: String = str(b.get("call_scene", ""))
	_f_call_scene.selected = max(0, _cs_map.find(_cs_val))
	if _f_call_scene_keep_bgm != null:
		_f_call_scene_keep_bgm.button_pressed = bool(b.get("call_scene_keep_bgm", false))
	if _f_show_messenger != null:
		MessengerVault.populate_conversation_option(_f_show_messenger)
		MessengerVault.select_conversation_option(
			_f_show_messenger, str(b.get("show_messenger", "")).strip_edges())

	var note_raw: Variant = b.get("detective_note", [])
	_rebuild_detective_note_rows(note_raw if note_raw is Array else [])
	if _f_detective_note_icon != null:
		var icon_mode: String = str(b.get("detective_note_icon", "")).strip_edges().to_lower()
		match icon_mode:
			"show":
				_f_detective_note_icon.selected = 1
			"hide":
				_f_detective_note_icon.selected = 2
			_:
				_f_detective_note_icon.selected = 0
	var open_note_spec: Variant = b.get("show_detective_note", null)
	if open_note_spec is Dictionary or open_note_spec == true:
		if _f_show_detective_note != null:
			_f_show_detective_note.button_pressed = true
		var open_ch: String = ""
		var open_topic: String = ""
		if open_note_spec is Dictionary:
			var od: Dictionary = open_note_spec as Dictionary
			open_ch = str(od.get("chapter", "")).strip_edges()
			open_topic = str(od.get("topic", "")).strip_edges()
			if open_ch.is_empty() and not open_topic.is_empty():
				open_ch = _find_chapter_for_topic(open_topic)
		if _f_open_note_chapter != null:
			_populate_detective_chapter_option(_f_open_note_chapter, open_ch, true)
		_populate_open_note_topic_option(open_ch, open_topic)
	else:
		if _f_show_detective_note != null:
			_f_show_detective_note.button_pressed = false
		if _f_open_note_chapter != null:
			_populate_detective_chapter_option(_f_open_note_chapter, "", true)
		_populate_open_note_topic_option("", "")
	_sync_open_detective_note_fields()
	var stamp_spec: Variant = b.get("show_note_stamp", null)
	if stamp_spec is Dictionary:
		var sd: Dictionary = stamp_spec as Dictionary
		if _f_show_note_stamp != null:
			_f_show_note_stamp.button_pressed = true
		var stamp_ch: String = str(sd.get("chapter", "")).strip_edges()
		var stamp_topic: String = str(sd.get("topic", "")).strip_edges()
		if stamp_ch.is_empty() and not stamp_topic.is_empty():
			stamp_ch = _find_chapter_for_topic(stamp_topic)
		if _f_note_stamp_chapter != null:
			_populate_detective_chapter_option(_f_note_stamp_chapter, stamp_ch, true)
		if _f_note_stamp_topic != null:
			_populate_detective_topic_option(_f_note_stamp_topic, stamp_ch, stamp_topic)
		if _f_note_stamp_stamp != null:
			_populate_detective_stamp_option(_f_note_stamp_stamp, str(sd.get("stamp", "")))
	else:
		if _f_show_note_stamp != null:
			_f_show_note_stamp.button_pressed = false
		if _f_note_stamp_chapter != null:
			_populate_detective_chapter_option(_f_note_stamp_chapter, "", true)
		if _f_note_stamp_topic != null:
			_populate_detective_topic_option(_f_note_stamp_topic, "", "")
		if _f_note_stamp_stamp != null:
			_populate_detective_stamp_option(_f_note_stamp_stamp, "")
	_sync_note_stamp_fields()
	_f_player1_name.text = str(b.get("player1_name", ""))
	_f_player2_name.text = str(b.get("player2_name", ""))
	var ask_key: String = str(b.get("ask_player_name", "")).strip_edges().to_lower()
	if _f_ask_player_name_cb != null:
		_f_ask_player_name_cb.button_pressed = ask_key in ASK_PLAYER_NAME_KEYS
	if _f_ask_player_name_opt != null:
		var ask_idx: int = ASK_PLAYER_NAME_KEYS.find(ask_key)
		_f_ask_player_name_opt.selected = ask_idx if ask_idx >= 0 else 0
	_sync_ask_player_name_fields()
	_f_start_crystals_p1.value = float(b.get("starting_crystals_p1", GameState.STARTING_CRYSTALS))
	_f_start_crystals_p2.value = float(b.get("starting_crystals_p2", GameState.STARTING_CRYSTALS))
	_f_portrait_p1.text = str(b.get("portrait_p1", ""))
	_f_portrait_p1_offset_x.value = float(b.get("portrait_p1_offset_x", 0.0))
	_f_portrait_p1_offset_y.value = float(b.get("portrait_p1_offset_y", 0.0))
	_f_portrait_p1_size.value     = float(b.get("portrait_p1_size", 1.0))
	_f_portrait_p2.text = str(b.get("portrait_p2", ""))
	_f_portrait_p2_offset_x.value = float(b.get("portrait_p2_offset_x", 0.0))
	_f_portrait_p2_offset_y.value = float(b.get("portrait_p2_offset_y", 0.0))
	_f_portrait_p2_size.value     = float(b.get("portrait_p2_size", 1.0))
	_f_battle_bgm.text = str(b.get("battle_bgm", ""))
	_f_setup_bgm.text = str(b.get("setup_bgm", ""))
	_f_almost_win_bgm.text = str(b.get("almost_win_bgm", ""))
	_f_battle_bgm_start.value = float(b.get("battle_bgm_start_sec", 14.0))
	_f_almost_win_enabled.button_pressed = bool(b.get("almost_win_bgm_enabled", true))
	_f_battle_bgm_vol.value = float(b.get("battle_bgm_volume", 100.0))
	var beat_on_win: String = str(b.get("on_win", ""))
	var beat_on_lose: String = str(b.get("on_lose", ""))
	_f_on_win.text  = beat_on_win
	_f_on_lose.text = beat_on_lose
	if _f_tutorial_on_win != null:
		_f_tutorial_on_win.text = beat_on_win
	if _f_tutorial_on_lose != null:
		_f_tutorial_on_lose.text = beat_on_lose

	# Tutorial battle
	var tut_path: String = str(b.get("tutorial_battle", "")).strip_edges()
	_populate_tutorial_battle_picker()
	if _f_call_tutorial != null:
		_f_call_tutorial.button_pressed = tut_path != ""
	if _f_tutorial_opt != null:
		_f_tutorial_opt.selected = 0
		if tut_path != "":
			for i: int in range(_tutorial_config_paths.size()):
				if _tutorial_config_paths[i] == tut_path:
					_f_tutorial_opt.selected = i
					break

	# AI deck vault
	if _f_ai_vault_opt != null:
		AIDeckVault.populate_vault_option(_f_ai_vault_opt)
		AIDeckVault.select_vault_option(_f_ai_vault_opt, str(b.get("ai_deck_vault", "")).strip_edges())
		_on_ai_vault_selected(false)
		if _f_ai_vault_form_opt != null:
			AIDeckVault.select_formation_option(_f_ai_vault_form_opt, int(b.get("ai_deck_vault_formation", 0)))

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
	_rebuild_deck_chips("enemy", "character", _enemy_chars_chips)
	_rebuild_deck_chips("enemy", "trap", _enemy_traps_chips)
	_rebuild_deck_chips("enemy", "tech", _enemy_tech_chips)

	# Player deck
	_player_deck_chars.clear()
	_player_deck_traps.clear()
	_player_deck_tech.clear()
	var pd: Variant = b.get("player_deck", null)
	if pd is Dictionary:
		for v2: Variant in (pd as Dictionary).get("characters", []):
			_player_deck_chars.append(str(v2))
		for v2: Variant in (pd as Dictionary).get("traps", []):
			_player_deck_traps.append(str(v2))
		for v2: Variant in (pd as Dictionary).get("tech", []):
			_player_deck_tech.append(str(v2))
	_rebuild_deck_chips("player", "character", _player_chars_chips)
	_rebuild_deck_chips("player", "trap", _player_traps_chips)
	_rebuild_deck_chips("player", "tech", _player_tech_chips)
	_populate_clone_deck_opt()
	_load_ai_forced_tech_from_beat(b)

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

	# Exploration call
	var ecall: String = str(b.get("exploration_call", "")).strip_edges()
	_f_call_exploration.button_pressed = ecall != ""
	_f_exploration_graph.text = ecall
	_f_exploration_force_fresh.button_pressed = bool(b.get("exploration_force_fresh", true))
	if _f_exploration_keep_vn_bgm != null:
		_f_exploration_keep_vn_bgm.button_pressed = bool(b.get("exploration_keep_vn_bgm", false))
	_f_exploration_on_return.text = str(b.get("exploration_on_return", ""))
	var eparams: Variant = b.get("exploration_params", {})
	_rebuild_exploration_param_rows(eparams if eparams is Dictionary else {})
	var einv: Variant = b.get("exploration_inventory", [])
	_rebuild_exploration_inv_rows(einv if einv is Array else [])

	_loading = false
	_update_tab_colors()
	_update_bug_note_label()
	_update_branch_bar(_selected_idx)
	_validate_choice_beat(b, _selected_idx)

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

	var beat_name: String = _f_beat_name.text.strip_edges()
	if not beat_name.is_empty():
		b["beat_name"] = beat_name
	var comment: String = _f_comment.text.strip_edges()
	if not comment.is_empty():
		b["comment"] = comment
	if _f_hidden.button_pressed:
		b["hidden"] = true
	var group_id: int = int(_f_group.value) if _f_group != null else 0
	if group_id > 0:
		b["group"] = group_id
		var group_name: String = _f_group_name.text.strip_edges() if _f_group_name != null else ""
		if not group_name.is_empty():
			b["group_name"] = group_name

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

	var choices: Array = _collect_choices()
	if not choices.is_empty():
		b["choices"] = choices
		if _f_choices_layout != null and _f_choices_layout.selected == 1:
			b["choices_layout"] = "inside_dialog"

	var go_to: Array = _collect_go_to()
	if not go_to.is_empty():
		b["go_to"] = go_to

	var play_group: Array = _collect_play_group()
	if not play_group.is_empty():
		b["play_group"] = play_group

	var beat_expl_actions: Array = _collect_actions_from_vbox(_exploration_actions_vbox)
	if not beat_expl_actions.is_empty():
		b["exploration_actions"] = beat_expl_actions

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
	var kb_has_start: bool = (_f_kb_start_zoom_cb != null and _f_kb_start_zoom_cb.button_pressed) \
		or (_f_kb_start_pan_x_cb != null and _f_kb_start_pan_x_cb.button_pressed) \
		or (_f_kb_start_pan_y_cb != null and _f_kb_start_pan_y_cb.button_pressed) \
		or (_f_kb_start_velocity_cb != null and _f_kb_start_velocity_cb.button_pressed) \
		or (_f_kb_stop_velocity_cb != null and _f_kb_stop_velocity_cb.button_pressed)
	if kb_z != 1.0 or kb_px != 0.0 or kb_py != 0.0 or kb_d > 0.0 or kb_has_start \
			or (_f_kb_delay != null and _f_kb_delay.value > 0.0):
		b["bg_ken_burns"] = _ken_burns_dict_from_fields()

	var music: String = _f_music.text.strip_edges()
	if music == "null":
		b["music"] = null
	elif not music.is_empty():
		b["music"] = music
	if _f_music_fade_in.value > 0.0:
		b["music_fade_in"] = _f_music_fade_in.value
	if _f_music_fade_out.value > 0.0:
		b["music_fade_out"] = _f_music_fade_out.value
	if _f_music_force != null and _f_music_force.button_pressed:
		b["music_force"] = true

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
	# Persist magnitude independently (was only saved when Char Shake text was set,
	# so the field always snapped back to the default 8 on reload).
	if absf(_f_shake_magnitude.value - 8.0) > 0.001:
		b["shake_magnitude"] = _f_shake_magnitude.value

	if _f_shake_screen.value > 0.0:
		b["shake_screen"] = _f_shake_screen.value

	var anim_idx: int = _f_animation.selected
	if anim_idx > 0:
		b["animation"] = (ANIMATION_REGISTRY[anim_idx] as Dictionary)["key"]

	if _f_start_battle.button_pressed:
		b["start_battle"] = true
		var sc1: int = int(_f_start_crystals_p1.value)
		if sc1 != GameState.STARTING_CRYSTALS:
			b["starting_crystals_p1"] = sc1
		var sc2: int = int(_f_start_crystals_p2.value)
		if sc2 != GameState.STARTING_CRYSTALS:
			b["starting_crystals_p2"] = sc2
	if _f_call_tutorial != null and _f_call_tutorial.button_pressed \
			and _f_tutorial_opt != null and _f_tutorial_opt.selected > 0:
		var tut_sel: int = _f_tutorial_opt.selected
		if tut_sel < _tutorial_config_paths.size():
			var tut_cfg: String = _tutorial_config_paths[tut_sel]
			if not tut_cfg.is_empty():
				b["tutorial_battle"] = tut_cfg
	if _f_go_to_credits.button_pressed:
		b["go_to_credits"] = true
		if _f_credits_target.selected == 1:
			b["credits_target"] = "demo"
	if _f_go_to_campaign_gallery.button_pressed:
		b["go_to_campaign_gallery"] = true
	if _f_go_to_quick_duel.button_pressed:
		b["go_to_quick_duel"] = true
	var upid: String = _f_unlock_protagonist.get_item_text(_f_unlock_protagonist.selected) \
			if _f_unlock_protagonist != null else "(none)"
	if not upid.is_empty() and upid != "(none)":
		b["unlock_protagonist"] = upid
		var uvid: String = ""
		if _f_unlock_protagonist_vault != null and _f_unlock_protagonist_vault.selected >= 0:
			uvid = str(_f_unlock_protagonist_vault.get_item_metadata(_f_unlock_protagonist_vault.selected))
		if not uvid.is_empty():
			b["unlock_protagonist_vault"] = uvid
	var ssp: String = _f_silent_switch_protagonist.get_item_text(_f_silent_switch_protagonist.selected) \
			if _f_silent_switch_protagonist != null else "(none)"
	if not ssp.is_empty() and ssp != "(none)":
		b["silent_switch_protagonist"] = ssp
	if _f_show_protagonist_select.button_pressed:
		b["show_protagonist_select"] = true
	var clp: String = _f_clear_limited_protagonist.get_item_text(_f_clear_limited_protagonist.selected) \
			if _f_clear_limited_protagonist != null else "(none)"
	if not clp.is_empty() and clp != "(none)":
		b["clear_limited_protagonist"] = clp
	var caps_id: String = _f_set_limited_caps_id.get_item_text(_f_set_limited_caps_id.selected) \
			if _f_set_limited_caps_id != null else "(none)"
	if not caps_id.is_empty() and caps_id != "(none)":
		b["set_limited_caps_protagonist"] = caps_id
		b["set_limited_caps"] = {
			"characters": int(_f_set_limited_units.value),
			"traps": int(_f_set_limited_traps.value),
			"techs": int(_f_set_limited_techs.value),
		}
	if _f_mark_chapter_end != null and _f_mark_chapter_end.button_pressed \
			and _f_unlock_gallery_opt != null \
			and _f_unlock_gallery_opt.selected > 0 \
			and _f_unlock_gallery_opt.selected < _gallery_unlock_paths.size():
		var end_path: String = _gallery_unlock_paths[_f_unlock_gallery_opt.selected]
		if end_path == "@current":
			b["complete_current_gallery_chapter"] = true
		elif not end_path.is_empty():
			b["complete_gallery_chapter"] = end_path
	var _cs_save_map: Array = ["", "credit", "credit_demo", "photo_scatter"]
	var _cs_idx: int = _f_call_scene.selected
	if _cs_idx > 0:
		b["call_scene"] = _cs_save_map[_cs_idx]
	if _f_call_scene_keep_bgm != null and _f_call_scene_keep_bgm.button_pressed:
		b["call_scene_keep_bgm"] = true
	if _f_show_messenger != null:
		var msgr_id: String = MessengerVault.option_conversation_id(_f_show_messenger)
		if not msgr_id.is_empty():
			b["show_messenger"] = msgr_id

	var note_actions: Array = _collect_detective_note_actions()
	if not note_actions.is_empty():
		b["detective_note"] = note_actions
	if _f_detective_note_icon != null:
		match _f_detective_note_icon.selected:
			1:
				b["detective_note_icon"] = "show"
			2:
				b["detective_note_icon"] = "hide"
	if _f_show_detective_note != null and _f_show_detective_note.button_pressed:
		var open_entry: Dictionary = {}
		var open_ch: String = _detective_chapter_from_option(_f_open_note_chapter)
		var open_topic: String = _detective_topic_from_option(_f_open_note_topic)
		if not open_ch.is_empty():
			open_entry["chapter"] = open_ch
		if not open_topic.is_empty():
			open_entry["topic"] = open_topic
		b["show_detective_note"] = open_entry
	if _f_show_note_stamp != null and _f_show_note_stamp.button_pressed:
		var stamp_id: String = _detective_stamp_from_option(_f_note_stamp_stamp)
		var topic_id: String = _detective_topic_from_option(_f_note_stamp_topic)
		if not stamp_id.is_empty() and not topic_id.is_empty():
			var stamp_entry: Dictionary = {"topic": topic_id, "stamp": stamp_id}
			var stamp_ch: String = _detective_chapter_from_option(_f_note_stamp_chapter)
			if not stamp_ch.is_empty():
				stamp_entry["chapter"] = stamp_ch
			b["show_note_stamp"] = stamp_entry

	var p1n: String = _f_player1_name.text.strip_edges()
	if not p1n.is_empty():
		b["player1_name"] = p1n
	var p2n: String = _f_player2_name.text.strip_edges()
	if not p2n.is_empty():
		b["player2_name"] = p2n
	if _f_ask_player_name_cb != null and _f_ask_player_name_cb.button_pressed:
		var ask_sel: int = _f_ask_player_name_opt.selected if _f_ask_player_name_opt != null else 0
		ask_sel = clampi(ask_sel, 0, ASK_PLAYER_NAME_KEYS.size() - 1)
		b["ask_player_name"] = ASK_PLAYER_NAME_KEYS[ask_sel]
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
	var setup_bgm: String = _f_setup_bgm.text.strip_edges()
	if not setup_bgm.is_empty():
		b["setup_bgm"] = setup_bgm
	var almost_win_bgm: String = _f_almost_win_bgm.text.strip_edges()
	if not almost_win_bgm.is_empty():
		b["almost_win_bgm"] = almost_win_bgm
	if _f_battle_bgm_start.value != 14.0:
		b["battle_bgm_start_sec"] = _f_battle_bgm_start.value
	if not _f_almost_win_enabled.button_pressed:
		b["almost_win_bgm_enabled"] = false
	if _f_battle_bgm_vol.value != 100.0:
		b["battle_bgm_volume"] = _f_battle_bgm_vol.value
	var on_win: String = ""
	var on_lose: String = ""
	if _f_call_tutorial != null and _f_call_tutorial.button_pressed:
		if _f_tutorial_on_win != null:
			on_win = _f_tutorial_on_win.text.strip_edges()
		if _f_tutorial_on_lose != null:
			on_lose = _f_tutorial_on_lose.text.strip_edges()
	elif _f_start_battle.button_pressed:
		on_win = _f_on_win.text.strip_edges()
		on_lose = _f_on_lose.text.strip_edges()
	if not on_win.is_empty():
		b["on_win"] = on_win
	if not on_lose.is_empty():
		b["on_lose"] = on_lose

	# AI deck vault (overrides inline enemy deck at runtime)
	if _f_ai_vault_opt != null:
		var vault_id: String = AIDeckVault.option_entry_id(_f_ai_vault_opt)
		if not vault_id.is_empty():
			b["ai_deck_vault"] = vault_id
			var form_idx: int = AIDeckVault.option_formation_index(_f_ai_vault_form_opt)
			if form_idx != 0:
				b["ai_deck_vault_formation"] = form_idx

	# Enemy deck
	if not _enemy_deck_chars.is_empty() or not _enemy_deck_traps.is_empty() or not _enemy_deck_tech.is_empty():
		b["enemy_deck"] = {
			"characters": _enemy_deck_chars.duplicate(),
			"traps":      _enemy_deck_traps.duplicate(),
			"tech":       _enemy_deck_tech.duplicate(),
		}

	# Player deck
	if not _player_deck_chars.is_empty() or not _player_deck_traps.is_empty() or not _player_deck_tech.is_empty():
		b["player_deck"] = {
			"characters": _player_deck_chars.duplicate(),
			"traps":      _player_deck_traps.duplicate(),
			"tech":       _player_deck_tech.duplicate(),
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

	var aft: Array = _collect_ai_forced_tech()
	if _ai_forced_tech_has_any(aft):
		b["ai_forced_tech"] = aft

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
			3: # Union Scroll
				var scroll_count: int = int((rr["credits_sb"] as SpinBox).value)
				if scroll_count > 0:
					rewards.append({"type": "union_scroll", "count": scroll_count})
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

	# Exploration call — graph path is authoritative (checkbox mirrors non-empty graph)
	var expl_graph: String = _f_exploration_graph.text.strip_edges()
	if not expl_graph.is_empty():
		b["exploration_call"] = expl_graph
		b["exploration_force_fresh"] = _f_exploration_force_fresh.button_pressed
		if _f_exploration_keep_vn_bgm != null and _f_exploration_keep_vn_bgm.button_pressed:
			b["exploration_keep_vn_bgm"] = true
		var expl_params: Dictionary = _collect_exploration_params()
		if not expl_params.is_empty():
			b["exploration_params"] = expl_params
		var expl_inv: Array = _collect_exploration_inventory()
		if not expl_inv.is_empty():
			b["exploration_inventory"] = expl_inv
		var expl_return: String = _f_exploration_on_return.text.strip_edges()
		if not expl_return.is_empty():
			b["exploration_on_return"] = expl_return

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
func _flush_current_beat() -> void:
	if _loading or _selected_idx < 0 or _selected_idx >= _beats.size():
		return
	_beats[_selected_idx] = _collect_beat()
	if _beat_list.item_count > _selected_idx:
		_beat_list.set_item_text(_selected_idx, _beat_summary(_beats[_selected_idx], _selected_idx))

func _on_field_changed() -> void:
	if _loading or _selected_idx < 0:
		return
	_beats[_selected_idx] = _collect_beat()
	var beat: Dictionary = _beats[_selected_idx] as Dictionary
	var sync_group: int = int(beat.get("group", 0))
	if sync_group > 0:
		_sync_group_name_to_beats(sync_group, str(beat.get("group_name", "")).strip_edges())
	_beat_list.set_item_text(_selected_idx, _beat_summary(_beats[_selected_idx], _selected_idx))
	var was_dirty: bool = _dirty
	_dirty = true
	_beat_modified[_selected_idx] = true
	_beat_list.set_item_custom_bg_color(_selected_idx, Color(0.5, 0.45, 0.0, 0.4))
	if beat.get("choices", []) is Array and not (beat.get("choices", []) as Array).is_empty():
		_beat_list.set_item_custom_fg_color(_selected_idx, Color(0.55, 0.88, 1.0))
	_validate_choice_beat(beat, _selected_idx)
	var all_warnings: Array[String] = []
	var choice_status: String = _status_lbl.text
	if choice_status.begins_with("Warning: "):
		all_warnings.append_array(choice_status.substr(9).split(", "))
	all_warnings.append_array(_validate_beat_names())
	if not all_warnings.is_empty():
		_status_lbl.text = "Warning: " + ", ".join(all_warnings)
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
	var _pos_default: String = "right" if ci.is_empty() else "center"
	pos_btn.select(maxi(SLOT_OPTIONS.find(str(ci.get("position", _pos_default))), 0))
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
	crop_sb.value = float(ci.get("crop_bottom", 30.0 if ci.is_empty() else 0.0))
	crop_sb.suffix = "%crop"
	crop_sb.custom_minimum_size.x = 100
	crop_sb.add_theme_font_size_override("font_size", 11)
	crop_sb.value_changed.connect(func(_v: float) -> void: _on_field_changed())
	hbox.add_child(crop_sb)

	var scale_sb := SpinBox.new()
	scale_sb.min_value = 10.0; scale_sb.max_value = 500.0; scale_sb.step = 5.0
	scale_sb.value = float(ci.get("scale", 175.0 if ci.is_empty() else 100.0))
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
	_flush_current_beat()
	var name_warnings: Array[String] = _validate_beat_names()
	if not name_warnings.is_empty():
		_status_lbl.text = "Cannot save — " + ", ".join(name_warnings)
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
# Battle deck builder helpers
# ─────────────────────────────────────────────────────────────

func _on_ai_vault_selected(preview_grid: bool = true) -> void:
	if _f_ai_vault_opt == null or _f_ai_vault_form_opt == null:
		return
	var entry_id: String = AIDeckVault.option_entry_id(_f_ai_vault_opt)
	AIDeckVault.populate_formation_option(_f_ai_vault_form_opt, entry_id)
	if not preview_grid or entry_id.is_empty():
		return
	var cfg: Dictionary = AIDeckVault.build_ai_battle_config(
		entry_id, AIDeckVault.option_formation_index(_f_ai_vault_form_opt))
	if not bool(cfg.get("ok", false)):
		return
	_rebuild_forced_grid(_ai_forced_grid, _ai_forced_gc, cfg.get("forced_cells", []))


func _populate_clone_deck_opt() -> void:
	if _clone_deck_opt == null:
		return
	_clone_deck_opt.clear()
	_clone_deck_opt.add_item("(select deck)")
	for i: int in range(SaveManager.decks.size()):
		var d: DeckData = SaveManager.decks[i]
		var suffix: String = "" if d.is_valid() else "  [invalid]"
		_clone_deck_opt.add_item("%s%s" % [d.deck_name, suffix])
	_refresh_clone_form_opt()

func _refresh_clone_form_opt() -> void:
	if _clone_form_opt == null:
		return
	_clone_form_opt.clear()
	_clone_form_opt.add_item("(deck only — no formation change)")
	if _clone_deck_opt == null or _clone_deck_opt.selected <= 0:
		return
	var deck_idx: int = _clone_deck_opt.selected - 1
	if deck_idx < 0 or deck_idx >= SaveManager.decks.size():
		return
	var deck: DeckData = SaveManager.decks[deck_idx]
	for f: Variant in deck.formations:
		if f is Dictionary:
			_clone_form_opt.add_item(str((f as Dictionary).get("name", "Formation")))

func _apply_deckbuilder_clone() -> void:
	if _clone_deck_opt == null or _clone_deck_opt.selected <= 0:
		_status_lbl.text = "Select a deckbuilder deck to clone."
		return
	var deck_idx: int = _clone_deck_opt.selected - 1
	if deck_idx < 0 or deck_idx >= SaveManager.decks.size():
		_status_lbl.text = "Invalid deck selection."
		return
	var deck: DeckData = SaveManager.decks[deck_idx]
	var to_player: bool = _clone_target_opt != null and _clone_target_opt.selected == 0
	var side: String = "player" if to_player else "enemy"
	var char_arr: Array = _get_battle_deck_array(side, "character")
	var trap_arr: Array = _get_battle_deck_array(side, "trap")
	var tech_arr: Array = _get_battle_deck_array(side, "tech")
	char_arr.clear()
	trap_arr.clear()
	tech_arr.clear()
	for cname: Variant in deck.characters:
		char_arr.append(str(cname))
	for tname: Variant in deck.traps:
		trap_arr.append(str(tname))
	for tname: Variant in deck.techs:
		tech_arr.append(str(tname))
	if to_player:
		_rebuild_deck_chips("player", "character", _player_chars_chips)
		_rebuild_deck_chips("player", "trap", _player_traps_chips)
		_rebuild_deck_chips("player", "tech", _player_tech_chips)
	else:
		_rebuild_deck_chips("enemy", "character", _enemy_chars_chips)
		_rebuild_deck_chips("enemy", "trap", _enemy_traps_chips)
		_rebuild_deck_chips("enemy", "tech", _enemy_tech_chips)
		for i: int in range(ENEMY_TECH_SLOTS):
			_ai_forced_tech[i] = str(tech_arr[i] if i < tech_arr.size() else "").strip_edges()
		_refresh_ai_forced_tech_row()
	if _clone_form_opt != null and _clone_form_opt.selected > 0:
		var form_idx: int = _clone_form_opt.selected - 1
		var forced: Array = deck.get_formation_forced_cells(form_idx)
		if to_player:
			_rebuild_forced_grid(_player_forced_grid, _player_forced_gc, forced)
		else:
			_rebuild_forced_grid(_ai_forced_grid, _ai_forced_gc, forced)
	_on_field_changed()
	var target_name: String = "Player 1" if to_player else "Player 2 (AI)"
	var form_note: String = ""
	if _clone_form_opt != null and _clone_form_opt.selected > 0:
		form_note = " + formation"
	_status_lbl.text = "Cloned '%s' into %s battle config%s." % [deck.deck_name, target_name, form_note]

func _build_battle_deck_row(parent: Control, label_text: String, card_type: String, side: String) -> HBoxContainer:
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
		_add_battle_deck_card(side, card_type, opt.get_item_text(opt.selected), chips)
	)
	clr_btn.pressed.connect(func() -> void:
		_get_battle_deck_array(side, card_type).clear()
		_rebuild_deck_chips(side, card_type, chips)
		_on_field_changed()
	)

	return chips

func _get_battle_deck_array(side: String, card_type: String) -> Array:
	if side == "player":
		match card_type:
			"character": return _player_deck_chars
			"trap":      return _player_deck_traps
			"tech":      return _player_deck_tech
	else:
		match card_type:
			"character": return _enemy_deck_chars
			"trap":      return _enemy_deck_traps
			"tech":      return _enemy_deck_tech
	return []

func _add_battle_deck_card(side: String, card_type: String, card_name: String, chips: HBoxContainer) -> void:
	var arr := _get_battle_deck_array(side, card_type)
	if arr.has(card_name):
		return
	arr.append(card_name)
	_rebuild_deck_chips(side, card_type, chips)
	_on_field_changed()

func _rebuild_deck_chips(side: String, card_type: String, chips: HBoxContainer) -> void:
	if chips == null:
		return
	for child in chips.get_children():
		child.queue_free()
	var arr := _get_battle_deck_array(side, card_type)
	for cname: String in arr:
		var chip := Button.new()
		chip.text = cname + "  ×"
		chip.custom_minimum_size = Vector2(0, 24)
		chip.add_theme_font_size_override("font_size", 11)
		var name_copy: String = cname
		chip.pressed.connect(func() -> void:
			arr.erase(name_copy)
			_rebuild_deck_chips(side, card_type, chips)
			_on_field_changed()
		)
		chips.add_child(chip)

func _get_enemy_array(card_type: String) -> Array:
	return _get_battle_deck_array("enemy", card_type)

func _add_enemy_card(card_type: String, card_name: String, chips: HBoxContainer) -> void:
	_add_battle_deck_card("enemy", card_type, card_name, chips)

func _rebuild_enemy_chips(card_type: String, chips: HBoxContainer) -> void:
	_rebuild_deck_chips("enemy", card_type, chips)

func _collect_ai_forced_tech() -> Array:
	var result: Array = []
	for i: int in range(ENEMY_TECH_SLOTS):
		result.append(str(_ai_forced_tech[i] if i < _ai_forced_tech.size() else "").strip_edges())
	return result

func _ai_forced_tech_has_any(slots: Array) -> bool:
	for t: Variant in slots:
		if str(t).strip_edges() != "":
			return true
	return false

func _load_ai_forced_tech_from_beat(b: Dictionary) -> void:
	for i: int in range(ENEMY_TECH_SLOTS):
		_ai_forced_tech[i] = ""
	var saved: Variant = b.get("ai_forced_tech", [])
	var has_saved: bool = false
	if saved is Array:
		for i: int in range(mini(ENEMY_TECH_SLOTS, (saved as Array).size())):
			var n: String = str((saved as Array)[i]).strip_edges()
			_ai_forced_tech[i] = n
			if not n.is_empty():
				has_saved = true
	if not has_saved:
		for i: int in range(mini(ENEMY_TECH_SLOTS, _enemy_deck_tech.size())):
			_ai_forced_tech[i] = str(_enemy_deck_tech[i]).strip_edges()
	_refresh_ai_forced_tech_row()

func _refresh_ai_forced_tech_row() -> void:
	for i: int in range(_ai_forced_tech_btns.size()):
		var btn: Button = _ai_forced_tech_btns[i] as Button
		var n: String = str(_ai_forced_tech[i] if i < _ai_forced_tech.size() else "").strip_edges()
		if n.is_empty():
			btn.text = "Tech %d\n(random)" % (i + 1)
			btn.modulate = Color(1.0, 1.0, 1.0, 0.45)
		else:
			btn.text = n
			btn.modulate = Color(0.55, 0.85, 1.0)

func _open_ai_forced_tech_picker(slot: int) -> void:
	var current: String = str(_ai_forced_tech[slot] if slot < _ai_forced_tech.size() else "")

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
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "AI Tech slot %d" % (slot + 1)
	title.add_theme_font_size_override("font_size", 15)
	vb.add_child(title)

	var le := LineEdit.new()
	le.placeholder_text = "Tech card name..."
	le.text = current
	le.add_theme_font_size_override("font_size", 14)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(le)

	var sug_scroll := ScrollContainer.new()
	sug_scroll.custom_minimum_size = Vector2(0, 160)
	sug_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(sug_scroll)
	var sug_vb := VBoxContainer.new()
	sug_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sug_scroll.add_child(sug_vb)

	var refresh_sug := func(query: String) -> void:
		for child: Node in sug_vb.get_children():
			child.queue_free()
		var q: String = query.strip_edges().to_lower()
		var names: Array = CardDatabase.get_all_tech_names()
		names.sort()
		var shown: int = 0
		for n: String in names:
			if SaveManager.demo_mode:
				var tc: TechCardData = CardDatabase.get_tech(n)
				if tc == null or not tc.include_in_demo:
					continue
			if not q.is_empty() and not n.to_lower().contains(q):
				continue
			if shown >= 30:
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
		_ai_forced_tech[slot] = le.text.strip_edges()
		_refresh_ai_forced_tech_row()
		_on_field_changed()
		overlay.queue_free())

	clear_btn.pressed.connect(func() -> void:
		_ai_forced_tech[slot] = ""
		_refresh_ai_forced_tech_row()
		_on_field_changed()
		overlay.queue_free())

	cancel_btn.pressed.connect(func() -> void: overlay.queue_free())

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if not panel.get_global_rect().has_point(
					(event as InputEventMouseButton).global_position):
				overlay.queue_free())

	le.grab_focus()
	le.select_all()

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
	clear_btn.add_theme_font_override("font", FontManager.make_font("primary", 400))
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
const _REWARD_TYPES: Array = ["Credits", "Card", "Booster Pack", "Union Scroll"]

func _get_battle_reward_pack_names(include_name: String = "") -> Array[String]:
	var names: Array[String] = []
	for entry: Variant in ShopManager.get_all_packs_unfiltered():
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		var pname: String = str(d.get("name", "")).strip_edges()
		if pname.is_empty():
			pname = str(d.get("id", "")).strip_edges()
		if pname.is_empty() or names.has(pname):
			continue
		names.append(pname)
	names.sort()
	var extra: String = include_name.strip_edges()
	if not extra.is_empty() and not names.has(extra):
		names.append(extra)
	return names

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
	credits_sb.value = float(rd.get("amount", rd.get("count", 50)))
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

	# Pack dropdown (from shop/custom_packs.json via ShopManager)
	var wanted_pack: String = str(rd.get("pack_name", ""))
	var pack_names: Array[String] = _get_battle_reward_pack_names(wanted_pack)
	var pack_opt := OptionButton.new()
	pack_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_opt.custom_minimum_size.x = 180
	pack_opt.add_theme_font_size_override("font_size", 13)
	for pn: String in pack_names:
		pack_opt.add_item(pn)
	var pack_idx: int = pack_names.find(wanted_pack)
	if pack_idx >= 0:
		pack_opt.select(pack_idx)
	elif not pack_names.is_empty():
		pack_opt.select(0)
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
		"union_scroll": type_opt.select(3)
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
	(row["credits_sb"] as SpinBox).visible   = (sel == 0 or sel == 3)
	(row["card_opt"]   as OptionButton).visible = (sel == 1)
	(row["pack_opt"]   as OptionButton).visible = (sel == 2)

# ─────────────────────────────────────────────────────────────
# Detective note beat fields
# ─────────────────────────────────────────────────────────────
const _DETECTIVE_NOTE_ACTIONS: Array = ["add_clue", "unlock_topic", "upgrade_topic"]

func _sync_open_detective_note_fields() -> void:
	var on: bool = _f_show_detective_note != null and _f_show_detective_note.button_pressed
	for f: OptionButton in [_f_open_note_chapter, _f_open_note_topic]:
		if f != null:
			f.visible = on
			f.get_parent().visible = on

func _sync_note_stamp_fields() -> void:
	var on: bool = _f_show_note_stamp != null and _f_show_note_stamp.button_pressed
	for f: OptionButton in [_f_note_stamp_chapter, _f_note_stamp_topic, _f_note_stamp_stamp]:
		if f != null:
			f.visible = on
			f.get_parent().visible = on

func _populate_open_note_topic_option(chapter_id: String, selected_topic: String) -> void:
	if _f_open_note_topic == null:
		return
	_f_open_note_topic.clear()
	_f_open_note_topic.add_item("(preferred)")
	_f_open_note_topic.set_item_metadata(0, {"chapter": "", "topic": ""})
	var wanted: String = selected_topic.strip_edges()
	var select_idx: int = 0
	var ch_filter: String = chapter_id.strip_edges()
	if ch_filter.is_empty():
		for cid_v: Variant in DetectiveNoteVault.get_chapter_ids():
			select_idx = _append_detective_topic_items(
				_f_open_note_topic, str(cid_v), wanted, select_idx)
	else:
		select_idx = _append_detective_topic_items(
			_f_open_note_topic, ch_filter, wanted, 0)
	if wanted.is_empty():
		select_idx = 0
	_f_open_note_topic.select(clampi(select_idx, 0, maxi(_f_open_note_topic.item_count - 1, 0)))

func _find_chapter_for_topic(topic_id: String) -> String:
	var tid: String = topic_id.strip_edges()
	if tid.is_empty():
		return ""
	for cid_v: Variant in DetectiveNoteVault.get_chapter_ids():
		var ch_id: String = str(cid_v)
		if DetectiveNoteVault.get_topic_ids(ch_id).has(tid):
			return ch_id
	return ""

func _populate_detective_chapter_option(
		opt: OptionButton, selected: String, include_default: bool) -> void:
	if opt == null:
		return
	opt.clear()
	var select_idx: int = 0
	if include_default:
		opt.add_item("(scene default)")
		opt.set_item_metadata(0, "")
		select_idx = 1
	for cid_v: Variant in DetectiveNoteVault.get_chapter_ids():
		var ch_id: String = str(cid_v)
		var chapter: Dictionary = DetectiveNoteVault.get_chapter(ch_id)
		var title: String = DetectiveNoteVault.loc_text(chapter.get("title", ""))
		var label: String = "%s — %s" % [ch_id, title] if not title.is_empty() else ch_id
		var idx: int = opt.item_count
		opt.add_item(label)
		opt.set_item_metadata(idx, ch_id)
		if ch_id == selected.strip_edges():
			select_idx = idx
	opt.select(clampi(select_idx, 0, maxi(opt.item_count - 1, 0)))

func _detective_chapter_from_option(opt: OptionButton) -> String:
	if opt == null or opt.selected < 0:
		return ""
	return str(opt.get_item_metadata(opt.selected)).strip_edges()

func _populate_detective_topic_option(
		opt: OptionButton, chapter_id: String, selected_topic: String) -> void:
	if opt == null:
		return
	opt.clear()
	var wanted: String = selected_topic.strip_edges()
	var select_idx: int = 0
	var ch_filter: String = chapter_id.strip_edges()
	if ch_filter.is_empty():
		for cid_v: Variant in DetectiveNoteVault.get_chapter_ids():
			select_idx = _append_detective_topic_items(opt, str(cid_v), wanted, select_idx)
	else:
		select_idx = _append_detective_topic_items(opt, ch_filter, wanted, 0)
	opt.select(clampi(select_idx, 0, maxi(opt.item_count - 1, 0)))

func _append_detective_topic_items(
		opt: OptionButton, chapter_id: String, wanted_topic: String, select_idx: int) -> int:
	for tid_v: Variant in DetectiveNoteVault.get_topic_ids(chapter_id):
		var tid: String = str(tid_v)
		var topic: Dictionary = DetectiveNoteVault.get_topic(chapter_id, tid)
		var title: String = DetectiveNoteVault.loc_text(topic.get("title", ""))
		var label: String = "%s / %s" % [chapter_id, tid]
		if not title.is_empty():
			label += " — " + title
		var idx: int = opt.item_count
		opt.add_item(label)
		opt.set_item_metadata(idx, {"chapter": chapter_id, "topic": tid})
		if tid == wanted_topic.strip_edges():
			select_idx = idx
	return select_idx

func _detective_topic_from_option(opt: OptionButton) -> String:
	if opt == null or opt.selected < 0:
		return ""
	var meta: Variant = opt.get_item_metadata(opt.selected)
	if meta is Dictionary:
		return str((meta as Dictionary).get("topic", "")).strip_edges()
	return ""

func _populate_detective_stamp_option(opt: OptionButton, selected_stamp: String) -> void:
	if opt == null:
		return
	opt.clear()
	var wanted: String = selected_stamp.strip_edges()
	var select_idx: int = 0
	for sid_v: Variant in DetectiveNoteVault.get_stamp_ids():
		var sid: String = str(sid_v)
		var stamp: Dictionary = DetectiveNoteVault.get_stamp(sid)
		var approver: String = DetectiveNoteVault.loc_text(stamp.get("approver", ""))
		var label: String = "%s — %s" % [sid, approver] if not approver.is_empty() else sid
		var idx: int = opt.item_count
		opt.add_item(label)
		opt.set_item_metadata(idx, sid)
		if sid == wanted:
			select_idx = idx
	opt.select(clampi(select_idx, 0, maxi(opt.item_count - 1, 0)))

func _detective_stamp_from_option(opt: OptionButton) -> String:
	if opt == null or opt.selected < 0:
		return ""
	return str(opt.get_item_metadata(opt.selected)).strip_edges()

func _populate_detective_target_option(
		opt: OptionButton, action: String, selected_chapter: String, selected_id: String) -> void:
	if opt == null:
		return
	opt.clear()
	var wanted_id: String = selected_id.strip_edges()
	var wanted_ch: String = selected_chapter.strip_edges()
	var select_idx: int = 0
	if action == "add_clue":
		for cid_v: Variant in DetectiveNoteVault.get_clue_ids():
			var clue_id: String = str(cid_v)
			var clue: Dictionary = DetectiveNoteVault.get_clue(clue_id)
			var name: String = DetectiveNoteVault.clue_display_name(clue)
			var kind: String = str(clue.get("kind", ""))
			var label: String = clue_id
			if not name.is_empty():
				label += " — " + name
			if not kind.is_empty():
				label += " [%s]" % kind
			var idx: int = opt.item_count
			opt.add_item(label)
			opt.set_item_metadata(idx, {"id": clue_id})
			if clue_id == wanted_id:
				select_idx = idx
	else:
		for cid_v: Variant in DetectiveNoteVault.get_chapter_ids():
			var ch_id: String = str(cid_v)
			for tid_v: Variant in DetectiveNoteVault.get_topic_ids(ch_id):
				var tid: String = str(tid_v)
				var topic: Dictionary = DetectiveNoteVault.get_topic(ch_id, tid)
				var title: String = DetectiveNoteVault.loc_text(topic.get("title", ""))
				var label: String = "%s / %s" % [ch_id, tid]
				if not title.is_empty():
					label += " — " + title
				var idx: int = opt.item_count
				opt.add_item(label)
				opt.set_item_metadata(idx, {"id": tid, "chapter": ch_id})
				if tid == wanted_id and (wanted_ch.is_empty() or ch_id == wanted_ch):
					select_idx = idx
	opt.select(clampi(select_idx, 0, maxi(opt.item_count - 1, 0)))

func _rebuild_detective_note_rows(actions: Array) -> void:
	if _detective_note_rows_vbox == null:
		return
	for child: Node in _detective_note_rows_vbox.get_children():
		child.queue_free()
	_detective_note_rows.clear()
	for ad_v: Variant in actions:
		if ad_v is Dictionary:
			_add_detective_note_row_from(ad_v as Dictionary)

func _add_detective_note_row_from(ad: Dictionary) -> void:
	if _detective_note_rows_vbox == null:
		return
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	_detective_note_rows_vbox.add_child(hbox)

	var action_opt := OptionButton.new()
	action_opt.custom_minimum_size = Vector2(120, 26)
	action_opt.add_theme_font_size_override("font_size", 13)
	for act: String in _DETECTIVE_NOTE_ACTIONS:
		action_opt.add_item(act)
	var action: String = str(ad.get("action", "add_clue")).strip_edges()
	var action_idx: int = _DETECTIVE_NOTE_ACTIONS.find(action)
	action_opt.select(action_idx if action_idx >= 0 else 0)
	hbox.add_child(action_opt)

	var target_opt := OptionButton.new()
	target_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_opt.add_theme_font_size_override("font_size", 13)
	hbox.add_child(target_opt)

	var chapter_opt := OptionButton.new()
	chapter_opt.custom_minimum_size = Vector2(150, 26)
	chapter_opt.add_theme_font_size_override("font_size", 13)
	hbox.add_child(chapter_opt)

	var level_sb := SpinBox.new()
	level_sb.min_value = 0
	level_sb.max_value = 9
	level_sb.step = 1
	level_sb.value = float(ad.get("level", 0))
	level_sb.custom_minimum_size = Vector2(56, 26)
	level_sb.tooltip_text = "upgrade_topic only: 0 = +1 level"
	level_sb.add_theme_font_size_override("font_size", 13)
	hbox.add_child(level_sb)

	var silent_cb := CheckBox.new()
	silent_cb.text = "Silent"
	silent_cb.tooltip_text = "add_clue only — grant without discovery toast"
	silent_cb.button_pressed = bool(ad.get("silent", false))
	silent_cb.add_theme_font_size_override("font_size", 13)
	hbox.add_child(silent_cb)

	var rm := Button.new()
	rm.text = "×"
	rm.custom_minimum_size = Vector2(26, 26)
	hbox.add_child(rm)

	var row: Dictionary = {
		"hbox": hbox,
		"action_opt": action_opt,
		"target_opt": target_opt,
		"chapter_opt": chapter_opt,
		"level_sb": level_sb,
		"silent_cb": silent_cb,
	}
	var ref_ch: String = str(ad.get("chapter", "")).strip_edges()
	var ref_id: String = str(ad.get("id", "")).strip_edges()
	_populate_detective_chapter_option(chapter_opt, ref_ch, true)
	_populate_detective_target_option(target_opt, action, ref_ch, ref_id)
	_update_detective_note_row_visibility(row)

	_detective_note_rows.append(row)

	action_opt.item_selected.connect(func(_i: int) -> void:
		var act: String = _DETECTIVE_NOTE_ACTIONS[action_opt.selected]
		_populate_detective_target_option(target_opt, act, "", "")
		_update_detective_note_row_visibility(row)
		_on_field_changed())
	target_opt.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	chapter_opt.item_selected.connect(func(_i: int) -> void: _on_field_changed())
	level_sb.value_changed.connect(func(_v: float) -> void: _on_field_changed())
	silent_cb.toggled.connect(func(_on: bool) -> void: _on_field_changed())
	rm.pressed.connect(func() -> void:
		hbox.queue_free()
		_detective_note_rows.erase(row)
		_on_field_changed())

func _update_detective_note_row_visibility(row: Dictionary) -> void:
	var action: String = _DETECTIVE_NOTE_ACTIONS[(row["action_opt"] as OptionButton).selected]
	(row["level_sb"] as SpinBox).visible = action == "upgrade_topic"
	var silent_cb: CheckBox = row.get("silent_cb") as CheckBox
	if silent_cb != null:
		silent_cb.visible = action == "add_clue"

func _collect_detective_note_actions() -> Array:
	var out: Array = []
	for row_v: Variant in _detective_note_rows:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v as Dictionary
		var action_opt: OptionButton = row["action_opt"] as OptionButton
		var target_opt: OptionButton = row["target_opt"] as OptionButton
		if target_opt.item_count <= 0 or target_opt.selected < 0:
			continue
		var action: String = _DETECTIVE_NOTE_ACTIONS[action_opt.selected]
		var meta: Variant = target_opt.get_item_metadata(target_opt.selected)
		if not meta is Dictionary:
			continue
		var ref_id: String = str((meta as Dictionary).get("id", "")).strip_edges()
		if ref_id.is_empty():
			continue
		var entry: Dictionary = {"action": action, "id": ref_id}
		var chapter_opt: OptionButton = row["chapter_opt"] as OptionButton
		var ch_override: String = _detective_chapter_from_option(chapter_opt)
		if not ch_override.is_empty():
			entry["chapter"] = ch_override
		elif action != "add_clue":
			var topic_ch: String = str((meta as Dictionary).get("chapter", "")).strip_edges()
			if not topic_ch.is_empty():
				entry["chapter"] = topic_ch
		if action == "upgrade_topic":
			var lvl: int = int((row["level_sb"] as SpinBox).value)
			if lvl > 0:
				entry["level"] = lvl
		if action == "add_clue":
			var silent_cb: CheckBox = row.get("silent_cb") as CheckBox
			if silent_cb != null and silent_cb.button_pressed:
				entry["silent"] = true
		out.append(entry)
	return out
