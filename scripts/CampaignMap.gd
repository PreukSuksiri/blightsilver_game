extends Control
# Campaign map — FFT-style node map.

signal closed
# All UI is built programmatically in _ready().
#
# Canvas layout (1860 × 540):
#   Top row    (y ~100–150): Chapter 1 (x 80–800) → Chapter 2 (x 980–1700)
#   Vertical drop:           2-5 (1700,150) → 3-1 (1700,390)
#   Bottom row (y ~390–430): Chapter 3 (x 1700→980) → Chapter 4 (x 800→80)
#   Final node (center):     (920, 268)

# ─────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────
const COLOR_STORY  := Color(0.30, 0.65, 1.00)
const COLOR_BATTLE := Color(1.00, 0.42, 0.22)
const COLOR_REWARD := Color(0.95, 0.78, 0.10)
const COLOR_FINAL  := Color(0.80, 0.30, 1.00)
const COLOR_LOCKED := Color(0.28, 0.28, 0.38)

const CANVAS_W: float = 1860.0
const CANVAS_H: float = 540.0

const VN_PLAYER_SCENE := "res://scenes/vn_player.tscn"

# ─────────────────────────────────────────────────────────────
# UI refs
# ─────────────────────────────────────────────────────────────
var _map_canvas: Control = null
var _node_btns: Dictionary = {}

var _detail_chapter_lbl: Label  = null
var _detail_type_lbl: Label     = null
var _detail_title_lbl: Label    = null
var _detail_opponent_lbl: Label = null
var _detail_body_lbl: Label     = null
var _detail_reward_lbl: Label   = null
var _action_btn: Button         = null

var _selected_node_id: String = ""

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	BGMManager.play_context(BGMManager.CONTEXT_CAMPAIGN_MAP, 0.8, 0.8)
	_build_ui()
	_check_pending_result()
	CampaignManager.progress_changed.connect(_on_progress_changed)

# ─────────────────────────────────────────────────────────────
# Build UI
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture      = load("res://assets/textures/ui/backgrounds/bg_stage_map.png")
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_header()

	var body := HBoxContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_top = MenuScreenHeader.HEADER_HEIGHT + 4.0
	body.add_theme_constant_override("separation", 0)
	add_child(body)

	var map_scroll := ScrollContainer.new()
	map_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	map_scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	body.add_child(map_scroll)

	_map_canvas = Control.new()
	_map_canvas.custom_minimum_size = Vector2(CANVAS_W, CANVAS_H)
	map_scroll.add_child(_map_canvas)

	_populate_map_canvas()
	_build_detail_panel(body)

func _build_header() -> void:
	var header := Panel.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = MenuScreenHeader.HEADER_HEIGHT + 4.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.025, 0.042, 0.10, 1.0)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.38, 0.65, 1.0, 0.28)
	header.add_theme_stylebox_override("panel", sb)
	add_child(header)

	var shell := Control.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header.add_child(shell)

	var title_lbl := Label.new()
	MenuScreenHeader.style_title(title_lbl, "CAMPAIGN")
	var title_center := CenterContainer.new()
	title_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_child(title_center)
	title_center.add_child(title_lbl)

	var prog_lbl := Label.new()
	prog_lbl.text = "%d / %d completed" % [
		CampaignManager.count_completed(), CampaignManager.count_total()]
	prog_lbl.add_theme_font_size_override("font_size", 13)
	prog_lbl.add_theme_color_override("font_color", Color(0.38, 0.65, 1.0, 0.55))
	prog_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var trail := HBoxContainer.new()
	trail.add_theme_constant_override("separation", 10)
	trail.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	trail.offset_right = -(MenuScreenHeader.CLOSE_INSET + MenuScreenHeader.CLOSE_BTN_SIZE.x + 8.0)
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_child(trail)
	trail.add_child(prog_lbl)

	var close_btn := Button.new()
	MenuScreenHeader.style_close_button(close_btn)
	MenuScreenHeader.anchor_close_top_right(close_btn)
	close_btn.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	shell.add_child(close_btn)

# ─────────────────────────────────────────────────────────────
# Map canvas
# ─────────────────────────────────────────────────────────────
func _populate_map_canvas() -> void:
	_node_btns.clear()

	# Chapter band backgrounds
	_add_chapter_band("Prologue — Flickering Midnight",  0.0,     200.0, 220.0, 320.0)
	_add_chapter_band("Chapter 1 — The First Veil",     0.0,     875.0, 60.0,  250.0)
	_add_chapter_band("Chapter 2 — Under the Blight",   875.0,   1860.0, 60.0,  250.0)
	_add_chapter_band("Chapter 3 — Enterprise Life",    875.0,   1860.0, 300.0, 490.0)
	_add_chapter_band("Chapter 4 — Unforgettable Vacation", 0.0, 875.0, 300.0, 490.0)

	# Final chapter area hint (center, between rows)
	var final_hint := ColorRect.new()
	final_hint.position = Vector2(720.0, 228.0)
	final_hint.size     = Vector2(400.0, 80.0)
	final_hint.color    = Color(0.4, 0.1, 0.7, 0.06)
	_map_canvas.add_child(final_hint)
	var final_lbl := Label.new()
	final_lbl.text     = "Final Chapter"
	final_lbl.position = Vector2(820.0, 232.0)
	final_lbl.add_theme_font_size_override("font_size", 11)
	final_lbl.add_theme_color_override("font_color", Color(0.7, 0.3, 1.0, 0.35))
	_map_canvas.add_child(final_lbl)

	# Connection lines (behind nodes)
	for node in CampaignManager.all_nodes:
		for conn_id in node.connections:
			var target := CampaignManager.get_node_data(conn_id)
			if target:
				_draw_connection(node, target)

	# Node icons
	for node in CampaignManager.all_nodes:
		var icon := _make_node_icon(node)
		icon.position = node.map_position - Vector2(28.0, 28.0)
		_map_canvas.add_child(icon)
		_node_btns[node.id] = icon

func _add_chapter_band(label: String, x_left: float, x_right: float,
					   y_top: float, y_bot: float) -> void:
	var band := ColorRect.new()
	band.position = Vector2(x_left, y_top)
	band.size     = Vector2(x_right - x_left, y_bot - y_top)
	band.color    = Color(1.0, 1.0, 1.0, 0.016)
	_map_canvas.add_child(band)

	# Chapter label centered within band
	var lbl := Label.new()
	lbl.text     = label
	lbl.position = Vector2(x_left + 10.0, y_top + 5.0)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.38, 0.65, 1.0, 0.36))
	_map_canvas.add_child(lbl)

func _draw_connection(from_nd: CampaignManager.CampaignNode,
					  to_nd:   CampaignManager.CampaignNode) -> void:
	var line := Line2D.new()
	line.add_point(from_nd.map_position)
	line.add_point(to_nd.map_position)
	line.width = 2.0
	var unlocked := CampaignManager.is_unlocked(to_nd.id)
	var c := _node_color(to_nd)
	line.default_color = Color(c.r, c.g, c.b, 0.50 if unlocked else 0.18)
	_map_canvas.add_child(line)

func _make_node_icon(node: CampaignManager.CampaignNode) -> Control:
	var locked := not CampaignManager.is_unlocked(node.id)
	var done   := CampaignManager.is_completed(node.id)
	var tc     := _node_color(node)

	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(56.0, 72.0)

	var panel := Panel.new()
	panel.size = Vector2(56.0, 56.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 1.0)
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left    = 10
	sb.corner_radius_top_right   = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left  = 10
	if locked:
		sb.border_color = Color(COLOR_LOCKED.r, COLOR_LOCKED.g, COLOR_LOCKED.b, 0.35)
		panel.modulate  = Color(0.38, 0.38, 0.45, 1.0)
	elif done:
		sb.border_color = Color(tc.r, tc.g, tc.b, 0.40)
		panel.modulate  = Color(0.55, 0.6, 0.65, 1.0)
	else:
		sb.border_color = tc
	panel.add_theme_stylebox_override("panel", sb)
	wrapper.add_child(panel)

	# Icon character
	var icon_lbl := Label.new()
	icon_lbl.size     = Vector2(56.0, 40.0)
	icon_lbl.position = Vector2(0.0, 6.0)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 20)
	match node.node_type:
		CampaignManager.NodeType.BATTLE: icon_lbl.text = "X"
		CampaignManager.NodeType.STORY:  icon_lbl.text = "S"
		CampaignManager.NodeType.REWARD: icon_lbl.text = "$"
	icon_lbl.add_theme_color_override("font_color",
		Color(COLOR_LOCKED.r, COLOR_LOCKED.g, COLOR_LOCKED.b, 0.6) if locked else tc)
	panel.add_child(icon_lbl)

	# Completion checkmark
	if done:
		var check := Label.new()
		check.text     = "v"
		check.size     = Vector2(22.0, 22.0)
		check.position = Vector2(34.0, -2.0)
		check.add_theme_font_size_override("font_size", 13)
		check.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 0.95))
		panel.add_child(check)

	# Stage name label
	var name_lbl := Label.new()
	name_lbl.text     = node.title
	name_lbl.size     = Vector2(90.0, 18.0)
	name_lbl.position = Vector2(-17.0, 58.0)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color",
		Color(0.5, 0.5, 0.6, 0.55) if locked else Color(0.72, 0.82, 0.95, 0.85))
	wrapper.add_child(name_lbl)

	if not locked:
		var btn := Button.new()
		btn.size = Vector2(56.0, 56.0)
		var empty := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal",  empty)
		btn.add_theme_stylebox_override("hover",   empty)
		btn.add_theme_stylebox_override("pressed", empty)
		btn.add_theme_stylebox_override("focus",   empty)
		btn.pressed.connect(_on_node_clicked.bind(node.id))
		wrapper.add_child(btn)

	return wrapper

# ─────────────────────────────────────────────────────────────
# Detail panel
# ─────────────────────────────────────────────────────────────
func _build_detail_panel(parent: Control) -> void:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(460.0, 0.0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.018, 0.032, 0.072, 0.99)
	sb.border_width_left = 1
	sb.border_color = Color(0.38, 0.65, 1.0, 0.18)
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   =  26.0
	vbox.offset_top    =  26.0
	vbox.offset_right  = -26.0
	vbox.offset_bottom = -26.0
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	_detail_chapter_lbl = Label.new()
	_detail_chapter_lbl.add_theme_font_size_override("font_size", 12)
	_detail_chapter_lbl.add_theme_color_override("font_color", Color(0.38, 0.65, 1.0, 0.55))
	vbox.add_child(_detail_chapter_lbl)

	_detail_type_lbl = Label.new()
	_detail_type_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_detail_type_lbl)

	_detail_title_lbl = Label.new()
	_detail_title_lbl.text = "Select a stage"
	_detail_title_lbl.add_theme_font_size_override("font_size", 26)
	_detail_title_lbl.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0, 1.0))
	_detail_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_detail_title_lbl)

	_detail_opponent_lbl = Label.new()
	_detail_opponent_lbl.add_theme_font_size_override("font_size", 13)
	_detail_opponent_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.4, 0.9))
	vbox.add_child(_detail_opponent_lbl)

	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0.0, 1.0)
	div.color = Color(0.38, 0.65, 1.0, 0.22)
	vbox.add_child(div)

	_detail_body_lbl = Label.new()
	_detail_body_lbl.add_theme_font_size_override("font_size", 13)
	_detail_body_lbl.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95, 0.88))
	_detail_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_detail_body_lbl)

	_detail_reward_lbl = Label.new()
	_detail_reward_lbl.add_theme_font_size_override("font_size", 14)
	_detail_reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3, 0.9))
	vbox.add_child(_detail_reward_lbl)

	_action_btn = Button.new()
	_action_btn.custom_minimum_size = Vector2(0.0, 46.0)
	_action_btn.add_theme_font_size_override("font_size", 16)
	_action_btn.visible = false
	_action_btn.pressed.connect(_on_action_pressed)
	vbox.add_child(_action_btn)

# ─────────────────────────────────────────────────────────────
# Node selection + detail
# ─────────────────────────────────────────────────────────────
func _on_node_clicked(node_id: String) -> void:
	_selected_node_id = node_id
	_update_detail()

func _update_detail() -> void:
	var node := CampaignManager.get_node_data(_selected_node_id)
	if node == null or _detail_title_lbl == null:
		return

	var done   := CampaignManager.is_completed(node.id)
	var locked := not CampaignManager.is_unlocked(node.id)

	_detail_chapter_lbl.text = "Chapter %d  ·  %s" % [node.chapter, node.chapter_name]
	_detail_title_lbl.text   = node.title
	_detail_opponent_lbl.text = ""

	match node.node_type:
		CampaignManager.NodeType.BATTLE:
			_detail_type_lbl.text = "BATTLE"
			_detail_type_lbl.add_theme_color_override("font_color", COLOR_BATTLE)
			var diff: int = node.data.get("difficulty", 1)
			var stars := "*".repeat(diff) + "-".repeat(3 - diff)
			_detail_opponent_lbl.text = "Opponent:  %s" % node.data.get("opponent", "?")
			_detail_body_lbl.text = "Difficulty:  %s\n\nClick BRIEFING + DEPLOY to read the mission story." % stars
			_detail_reward_lbl.text = "Reward: %s" % node.data.get("reward_description", "")

		CampaignManager.NodeType.STORY:
			_detail_type_lbl.text = "STORY EVENT"
			_detail_type_lbl.add_theme_color_override("font_color",
				COLOR_FINAL if node.chapter == 5 else COLOR_STORY)
			_detail_body_lbl.text = "Click READ to experience the story."
			_detail_reward_lbl.text = ""

		CampaignManager.NodeType.REWARD:
			_detail_type_lbl.text = "REWARD"
			_detail_type_lbl.add_theme_color_override("font_color", COLOR_REWARD)
			_detail_body_lbl.text = node.data.get("description", "")
			var cr: int = node.data.get("credits", 0)
			_detail_reward_lbl.text = "+%d credits" % cr if cr > 0 else ""

	if done:
		_action_btn.text     = "COMPLETED"
		_action_btn.disabled = true
		_action_btn.visible  = true
	elif locked:
		_action_btn.visible = false
	else:
		_action_btn.disabled = false
		_action_btn.visible  = true
		match node.node_type:
			CampaignManager.NodeType.BATTLE: _action_btn.text = "BRIEFING + DEPLOY"
			CampaignManager.NodeType.STORY:  _action_btn.text = "READ"
			CampaignManager.NodeType.REWARD: _action_btn.text = "CLAIM"

# ─────────────────────────────────────────────────────────────
# Actions
# ─────────────────────────────────────────────────────────────
func _on_action_pressed() -> void:
	var node := CampaignManager.get_node_data(_selected_node_id)
	if node == null:
		return
	match node.node_type:
		CampaignManager.NodeType.BATTLE:
			if not SaveManager.is_active_deck_ready():
				SaveManager.show_deck_not_ready_overlay(self)
				return
			_show_prebattle_vn(node)
		CampaignManager.NodeType.STORY:  _show_story_vn(node)
		CampaignManager.NodeType.REWARD: _claim_reward(node)

func _launch_battle(node: CampaignManager.CampaignNode) -> void:
	var diff: int = node.data.get("difficulty", 1)
	CampaignManager.active_node_id     = node.id
	GameState.game_mode                = GameState.GameMode.CAMPAIGN
	GameState.campaign_node_id         = node.id
	GameState.campaign_enemy_config    = CampaignManager.get_enemy_config(diff)
	BGMManager.stop(0.0)
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game_board.tscn"))

func _claim_reward(node: CampaignManager.CampaignNode) -> void:
	CampaignManager.complete_node(node.id)
	_update_detail()

# ─────────────────────────────────────────────────────────────
# Visual Novel scenes
# ─────────────────────────────────────────────────────────────
func _show_vn_scene(json_path: String, on_complete: Callable) -> void:
	BGMManager.stop(0.0)
	if json_path == "":
		on_complete.call()
		return
	var vn := preload("res://scenes/vn_player.tscn").instantiate()
	add_child(vn)
	vn.play_scene(json_path, on_complete)

func _show_prebattle_vn(node: CampaignManager.CampaignNode) -> void:
	var path: String = node.data.get("vn_scene", "")
	_show_vn_scene(path, func() -> void: _launch_battle(node))

func _show_story_vn(node: CampaignManager.CampaignNode) -> void:
	var path: String = node.data.get("vn_scene", "")
	var cb := func() -> void:
		CampaignManager.complete_node(node.id)
		_update_detail()
	_show_vn_scene(path, cb)

# ─────────────────────────────────────────────────────────────
# Pending result (returned from game_board)
# ─────────────────────────────────────────────────────────────
func _check_pending_result() -> void:
	var result := CampaignManager.pending_result
	if result.is_empty():
		return
	CampaignManager.pending_result = {}

	var node_id: String = result.get("node_id", "")
	var won: bool       = result.get("won", false)

	if node_id != "":
		_selected_node_id = node_id
		_update_detail()

	if won:
		var node := CampaignManager.get_node_data(node_id)
		var post_path: String = node.data.get("vn_scene_post", "") if node else ""
		_show_vn_scene(post_path, func() -> void:
			if not CampaignManager.is_completed(node_id):
				CampaignManager.complete_node(node_id)
			_update_detail()
			_show_result_banner(true))
	else:
		_show_result_banner(false)

func _show_result_banner(won: bool) -> void:
	var banner := Label.new()
	banner.text = "VICTORY!" if won else "DEFEATED"
	banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banner.offset_top    = 62.0
	banner.offset_bottom = 110.0
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 30)
	banner.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.55, 1.0) if won else Color(1.0, 0.38, 0.28, 1.0))
	add_child(banner)
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(banner, "modulate:a", 0.0, 0.9)
	tween.tween_callback(banner.queue_free)

# ─────────────────────────────────────────────────────────────
# Progress change — rebuild map icons
# ─────────────────────────────────────────────────────────────
func _on_progress_changed() -> void:
	if _map_canvas == null:
		return
	for child in _map_canvas.get_children():
		child.queue_free()
	await get_tree().process_frame
	if not is_instance_valid(_map_canvas):
		return
	_populate_map_canvas()
	if _selected_node_id != "":
		_update_detail()

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _node_color(node: CampaignManager.CampaignNode) -> Color:
	if node.chapter == 5:
		return COLOR_FINAL
	match node.node_type:
		CampaignManager.NodeType.BATTLE: return COLOR_BATTLE
		CampaignManager.NodeType.STORY:  return COLOR_STORY
		CampaignManager.NodeType.REWARD: return COLOR_REWARD
	return Color.WHITE
