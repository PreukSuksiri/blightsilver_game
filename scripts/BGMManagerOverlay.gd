extends Control
# BGMManagerOverlay — admin UI to edit default BGM per game context and preview tracks.
# Open via Admin Console: manage_bgm
# Saves to data/bgm_contexts.json

const _BG_COLOR     := Color(0.05, 0.05, 0.10, 0.97)
const _HEADER_COLOR := Color(0.10, 0.12, 0.22, 1.0)
const _PANEL_COLOR  := Color(0.09, 0.10, 0.16, 1.0)
const _BOT_COLOR    := Color(0.08, 0.08, 0.14, 1.0)
const _ROW_A        := Color(0.09, 0.09, 0.15, 1.0)
const _ROW_B        := Color(0.12, 0.12, 0.20, 1.0)
const _BTN_PLAY     := Color(0.12, 0.42, 0.62, 1.0)
const _BTN_SAVE     := Color(0.12, 0.55, 0.28, 1.0)
const _BTN_STOP     := Color(0.55, 0.12, 0.12, 1.0)
const _BTN_CLOSE    := Color(0.55, 0.12, 0.12, 1.0)
const _BTN_BROWSE   := Color(0.22, 0.22, 0.32, 1.0)
const _BTN_RESET    := Color(0.30, 0.22, 0.10, 1.0)

const _AUDIO_DIR := "res://assets/audio/"

var _status_lbl: Label = null
var _now_playing_lbl: Label = null
var _path_edit: LineEdit = null
var _fade_spin: SpinBox = null
var _file_dialog: FileDialog = null
var _browse_target: String = ""
var _context_edits: Dictionary = {}  # context → LineEdit


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 90

	var bg := ColorRect.new()
	bg.color = _BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_build_header()
	_build_body()
	_build_bottom_bar()
	_build_file_dialog()

	if not BGMManager.track_changed.is_connected(_refresh_status):
		BGMManager.track_changed.connect(_refresh_status)
	_refresh_status()


func _build_header() -> void:
	var header := _make_panel(_HEADER_COLOR)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.custom_minimum_size = Vector2(0, 52)
	add_child(header)

	var title := Label.new()
	title.text = "BGM Manager"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)

	var close_btn := _make_button("X", _BTN_CLOSE)
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -48
	close_btn.offset_top = 4
	close_btn.offset_right = -4
	close_btn.offset_bottom = 48
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)


func _build_body() -> void:
	var root := VBoxContainer.new()
	root.set_anchor(SIDE_LEFT, 0.0)
	root.set_anchor(SIDE_RIGHT, 1.0)
	root.set_anchor(SIDE_TOP, 0.0)
	root.set_anchor(SIDE_BOTTOM, 1.0)
	root.offset_left = 24.0
	root.offset_right = -24.0
	root.offset_top = 64.0
	root.offset_bottom = -68.0
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var now_panel := _make_panel(_PANEL_COLOR)
	now_panel.custom_minimum_size = Vector2(0, 60)
	root.add_child(now_panel)

	var now_vbox := VBoxContainer.new()
	now_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	now_vbox.offset_left = 14.0
	now_vbox.offset_right = -14.0
	now_vbox.offset_top = 8.0
	now_vbox.offset_bottom = -8.0
	now_panel.add_child(now_vbox)

	var now_title := Label.new()
	now_title.text = "NOW PLAYING (preview)"
	now_title.add_theme_font_size_override("font_size", 11)
	now_title.add_theme_color_override("font_color", Color(0.55, 0.68, 0.82))
	now_vbox.add_child(now_title)

	_now_playing_lbl = Label.new()
	_now_playing_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_now_playing_lbl.add_theme_font_size_override("font_size", 14)
	_now_playing_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	now_vbox.add_child(_now_playing_lbl)

	var ctrl_row := HBoxContainer.new()
	ctrl_row.add_theme_constant_override("separation", 10)
	root.add_child(ctrl_row)

	var fade_lbl := Label.new()
	fade_lbl.text = "Preview fade (sec)"
	fade_lbl.add_theme_font_size_override("font_size", 12)
	ctrl_row.add_child(fade_lbl)

	_fade_spin = SpinBox.new()
	_fade_spin.min_value = 0.0
	_fade_spin.max_value = 5.0
	_fade_spin.step = 0.1
	_fade_spin.value = BGMManager.DEFAULT_FADE
	_fade_spin.custom_minimum_size = Vector2(80, 0)
	ctrl_row.add_child(_fade_spin)

	var stop_btn := _make_button("STOP", _BTN_STOP)
	stop_btn.custom_minimum_size = Vector2(80, 32)
	stop_btn.pressed.connect(_on_stop_pressed)
	ctrl_row.add_child(stop_btn)

	root.add_child(_section_label(
		"Default track per context — edit paths, SAVE ALL, then PLAY to preview"))

	var ctx_scroll := _make_scroll(280)
	root.add_child(ctx_scroll)
	_build_context_rows(ctx_scroll.get_child(0) as VBoxContainer)

	root.add_child(_section_label("Audio library — PLAY to preview any file"))
	var lib_scroll := _make_scroll(140)
	root.add_child(lib_scroll)
	_build_library_rows(lib_scroll.get_child(0) as VBoxContainer)

	root.add_child(_section_label("One-off preview (does not change defaults)"))
	var path_row := HBoxContainer.new()
	path_row.add_theme_constant_override("separation", 8)
	root.add_child(path_row)

	_path_edit = LineEdit.new()
	_path_edit.placeholder_text = "res://assets/audio/..."
	_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_row.add_child(_path_edit)

	var browse_btn := _make_button("...", _BTN_BROWSE)
	browse_btn.custom_minimum_size = Vector2(40, 32)
	browse_btn.pressed.connect(_open_custom_file_dialog)
	path_row.add_child(browse_btn)

	var play_path_btn := _make_button("PLAY", _BTN_PLAY)
	play_path_btn.custom_minimum_size = Vector2(72, 32)
	play_path_btn.pressed.connect(_on_play_path_pressed)
	path_row.add_child(play_path_btn)


func _build_bottom_bar() -> void:
	var bot := _make_panel(_BOT_COLOR)
	bot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot.custom_minimum_size = Vector2(0, 56)
	add_child(bot)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 12.0
	hbox.offset_right = -12.0
	hbox.add_theme_constant_override("separation", 10)
	bot.add_child(hbox)

	var save_btn := _make_button("SAVE ALL", _BTN_SAVE)
	save_btn.custom_minimum_size = Vector2(120, 38)
	save_btn.pressed.connect(_on_save_all)
	hbox.add_child(save_btn)

	var reset_btn := _make_button("RESET DEFAULTS", _BTN_RESET)
	reset_btn.custom_minimum_size = Vector2(150, 38)
	reset_btn.pressed.connect(_on_reset_defaults)
	hbox.add_child(reset_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	_status_lbl = Label.new()
	_status_lbl.add_theme_font_size_override("font_size", 12)
	_status_lbl.add_theme_color_override("font_color", Color(0.55, 0.90, 0.60))
	_status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_status_lbl)


func _build_context_rows(parent: VBoxContainer) -> void:
	_context_edits.clear()
	var keys: Array = BGMManager.get_all_contexts()
	for i: int in range(keys.size()):
		var ctx: String = str(keys[i])
		var track_path: String = BGMManager.get_default_path(ctx)
		_add_context_row(parent, ctx, track_path, i % 2 == 0)


func _add_context_row(parent: VBoxContainer, ctx: String, track_path: String, alt: bool) -> void:
	var row_bg := _make_panel(_ROW_B if alt else _ROW_A)
	row_bg.custom_minimum_size = Vector2(0, 44)
	row_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row_bg)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10.0
	hbox.offset_right = -10.0
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	row_bg.add_child(hbox)

	var ctx_lbl := Label.new()
	ctx_lbl.text = ctx
	ctx_lbl.custom_minimum_size = Vector2(118, 0)
	ctx_lbl.add_theme_font_size_override("font_size", 12)
	ctx_lbl.add_theme_color_override("font_color", Color(0.70, 0.82, 0.95))
	hbox.add_child(ctx_lbl)

	var path_edit := LineEdit.new()
	path_edit.text = track_path
	path_edit.placeholder_text = "(empty — set per VN beat)" if ctx == BGMManager.CONTEXT_VN else ""
	path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_edit.add_theme_font_size_override("font_size", 11)
	hbox.add_child(path_edit)
	_context_edits[ctx] = path_edit

	var browse_btn := _make_button("...", _BTN_BROWSE)
	browse_btn.custom_minimum_size = Vector2(36, 30)
	browse_btn.pressed.connect(_open_context_file_dialog.bind(ctx))
	hbox.add_child(browse_btn)

	var play_btn := _make_button("PLAY", _BTN_PLAY)
	play_btn.custom_minimum_size = Vector2(64, 30)
	play_btn.pressed.connect(_play_context_row.bind(ctx))
	hbox.add_child(play_btn)


func _build_library_rows(parent: VBoxContainer) -> void:
	var files: Array = _list_audio_files()
	for i: int in range(files.size()):
		var track_path: String = str(files[i])
		_add_play_row(parent, track_path.get_file(), track_path, i % 2 == 0,
			_play_path.bind(track_path))


func _add_play_row(
		parent: VBoxContainer,
		title: String,
		subtitle: String,
		alt: bool,
		on_play: Callable) -> void:
	var row_bg := _make_panel(_ROW_B if alt else _ROW_A)
	row_bg.custom_minimum_size = Vector2(0, 36)
	row_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row_bg)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10.0
	hbox.offset_right = -10.0
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	row_bg.add_child(hbox)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.clip_text = true
	hbox.add_child(title_lbl)

	var play_btn := _make_button("PLAY", _BTN_PLAY)
	play_btn.custom_minimum_size = Vector2(64, 28)
	play_btn.pressed.connect(on_play)
	hbox.add_child(play_btn)


func _make_scroll(min_height: float) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, min_height)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 1)
	scroll.add_child(list)
	return scroll


func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.58, 0.70, 0.82))
	return lbl


func _build_file_dialog() -> void:
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_file_dialog.filters = PackedStringArray(["*.mp3 ; MP3", "*.ogg ; OGG", "*.wav ; WAV"])
	_file_dialog.current_dir = "res://assets/audio/"
	_file_dialog.title = "Select BGM file"
	_file_dialog.size = Vector2i(900, 600)
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)


func _open_custom_file_dialog() -> void:
	_browse_target = ""
	_file_dialog.popup_centered()


func _open_context_file_dialog(ctx: String) -> void:
	_browse_target = ctx
	_file_dialog.popup_centered()


func _on_file_selected(path: String) -> void:
	if _browse_target.is_empty():
		_path_edit.text = path
	else:
		var edit: LineEdit = _context_edits.get(_browse_target) as LineEdit
		if edit:
			edit.text = path
	_browse_target = ""


func _apply_edits_to_manager() -> void:
	for ctx: String in _context_edits.keys():
		var edit: LineEdit = _context_edits[ctx] as LineEdit
		BGMManager.set_default_path(ctx, edit.text)


func _on_save_all() -> void:
	_apply_edits_to_manager()
	var err: String = BGMManager.save_default_paths()
	if err != "":
		_set_status(err)
		return
	_set_status("Saved to data/bgm_contexts.json")


func _on_reset_defaults() -> void:
	BGMManager.reset_default_paths()
	for ctx: String in _context_edits.keys():
		var edit: LineEdit = _context_edits[ctx] as LineEdit
		edit.text = BGMManager.get_default_path(ctx)
	_set_status("Reset to built-in defaults and saved.")


func _play_context_row(ctx: String) -> void:
	_apply_edits_to_manager()
	var path: String = BGMManager.get_default_path(ctx)
	if path.is_empty():
		_set_status("'%s' has no track — browse to set one, or leave empty for VN." % ctx)
		return
	if not ResourceLoader.exists(path):
		_set_status("File not found: %s" % path)
		return
	var fade: float = float(_fade_spin.value)
	BGMManager.play_path(path, fade, fade, 100.0, ctx)
	_set_status("Preview: %s" % ctx)
	_refresh_status()


func _play_path(path: String) -> void:
	path = path.strip_edges()
	if path.is_empty():
		_set_status("Path is empty.")
		return
	if not ResourceLoader.exists(path):
		_set_status("File not found: %s" % path)
		return
	if load(path) == null:
		_set_status("Failed to load: %s" % path)
		return
	var fade: float = float(_fade_spin.value)
	BGMManager.play_path(path, fade, fade, 100.0, "preview")
	_set_status("Preview: %s" % path.get_file())
	_refresh_status()


func _on_play_path_pressed() -> void:
	_play_path(_path_edit.text)


func _on_stop_pressed() -> void:
	BGMManager.stop(float(_fade_spin.value))
	_set_status("Stopped.")
	_refresh_status()


func _refresh_status(_ctx: String = "", _path: String = "") -> void:
	if BGMManager.is_playing():
		var ctx: String = BGMManager.get_current_context()
		if ctx.is_empty():
			ctx = "preview"
		_now_playing_lbl.text = "[%s]  %s" % [ctx, BGMManager.get_current_path().get_file()]
	else:
		_now_playing_lbl.text = "Stopped"


func _set_status(text: String) -> void:
	if _status_lbl:
		_status_lbl.text = text


func _list_audio_files() -> Array:
	var files: Array = []
	var dir := DirAccess.open(_AUDIO_DIR)
	if dir == null:
		return files
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and (
				fname.ends_with(".mp3") or fname.ends_with(".ogg") or fname.ends_with(".wav")):
			files.append(_AUDIO_DIR + fname)
		fname = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files


func _make_panel(color: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	pc.add_theme_stylebox_override("panel", style)
	return pc


func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	var style_hover := style.duplicate() as StyleBoxFlat
	style_hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", style_hover)
	return btn
