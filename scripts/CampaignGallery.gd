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
const CARD_DIM_OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.62)
const CARD_DIM_LABEL_COLOR   := Color(0.65, 0.65, 0.68)
const CARD_DIM_LABEL_SIZE    := 13
const DUNGEON_MAP_SCENE := DailyDungeonManager.DUNGEON_MAP_SCENE

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

	MenuScreenHeader.build_top_bar(self, "CAMPAIGN", queue_free)

	# ── Scroll container ──────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = MenuScreenHeader.HEADER_HEIGHT + 8.0
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
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_child(img)

	# ── Locked overlay ────────────────────────────────────────
	if is_locked:
		_add_card_dim_overlay(frame)

		var lbl_lock := Label.new()
		var prereq_label: String = _prerequisite_display_name(prereq_vn)
		if prereq_label != "":
			lbl_lock.text = "🔒\nFinish\n%s" % prereq_label
		else:
			lbl_lock.text = "🔒\nLOCKED"
		lbl_lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_lock.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl_lock.set_anchors_preset(Control.PRESET_FULL_RECT)
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
		lbl_cs.add_theme_font_override("font", CHIVO_FONT)
		lbl_cs.add_theme_font_size_override("font_size", CARD_DIM_LABEL_SIZE)
		lbl_cs.add_theme_color_override("font_color", CARD_DIM_LABEL_COLOR)
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
				_on_chapter_pressed(d))

		var save_kind: String = _get_chapter_save_kind(d, vn_path)
		if save_kind != "":
			_add_saved_progress_badge(frame, save_kind)

	# ── Line 1 (chapter) ──────────────────────────────────────
	var l1 := Label.new()
	l1.text = str(d.get("line1", ""))
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_font_override("font", CHIVO_FONT)
	l1.add_theme_font_size_override("font_size", 14)
	l1.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	card.add_child(l1)

	# ── Line 2 (stage) ────────────────────────────────────────
	var l2 := Label.new()
	l2.text = str(d.get("line2", ""))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.add_theme_font_override("font", CHIVO_FONT)
	l2.add_theme_font_size_override("font_size", 12)
	l2.add_theme_color_override("font_color", Color(0.60, 0.62, 0.68, 0.85))
	card.add_child(l2)

	return card


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
	if SaveManager.has_vn_checkpoint(vn_path):
		return "vn"
	var expl: Dictionary = ExplorationManager.find_exploration_call_in_vn(vn_path)
	var on_return: String = str(expl.get("exploration_on_return", "")).strip_edges()
	if not on_return.is_empty() and SaveManager.has_vn_checkpoint(on_return):
		return "vn"
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
	lbl.add_theme_font_override("font", CHIVO_FONT)
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
	GameDialog.choices_overlay(
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
		520.0,
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
			var entry_vn: String = str(card.get("vn_scene", chapter_key)).strip_edges()
			if SaveManager.has_vn_checkpoint(entry_vn):
				_play_vn(entry_vn, false, card, chapter_key)
			else:
				var expl: Dictionary = ExplorationManager.find_exploration_call_in_vn(chapter_key)
				var on_return: String = str(expl.get("exploration_on_return", "")).strip_edges()
				if not on_return.is_empty() and SaveManager.has_vn_checkpoint(on_return):
					_play_vn(on_return, false, card, chapter_key)
				else:
					var expl_info: Dictionary = _resolve_chapter_exploration(card, chapter_key)
					var graph_path: String = str(expl_info.get("graph_path", "")).strip_edges()
					if not graph_path.is_empty():
						_resume_exploration(graph_path)


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
	GameDialog.choices_overlay(
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
		520.0,
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
