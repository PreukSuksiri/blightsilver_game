extends Control
# DailyDungeonMap — full-screen overlay for the current daily dungeon.
# Shows dungeon background, connection lines, node icons, and a detail panel.
# Opened as a child of MainMenu; closed by queue_free().

# ─────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────

const CANVAS_W: float = 1400.0
const CANVAS_H: float = 820.0

const COLOR_NORMAL_AVAIL := Color(1.00, 0.72, 0.22, 1.0)
const COLOR_BOSS_AVAIL   := Color(1.00, 0.35, 0.35, 1.0)
const COLOR_CLEARED      := Color(0.30, 0.90, 0.55, 1.0)
const COLOR_LOCKED       := Color(0.28, 0.28, 0.38, 1.0)

const ICON_NORMAL_PATH := "res://assets/textures/daily_dungeon/nodes/ui_campaign_platform_normal.png"
const ICON_BOSS_PATH   := "res://assets/textures/daily_dungeon/nodes/ui_campaign_platform_boss.png"

# ── Player sprite ─────────────────────────────────────────────
# Swap in a real sprite sheet by placing it at PLAYER_SHEET_PATH.
# Sheet layout: rows = directions (Down/Left/Right/Up), columns = frames.
const PLAYER_SHEET_PATH: String    = "res://assets/textures/daily_dungeon/sprites/sprite_nex_walking.png"
const SPRITE_FRAME_W: int          = 68   # px per frame in sheet
const SPRITE_FRAME_H: int          = 68
const SPRITE_FRAMES_PER_DIR: int   = 8
const SPRITE_WALK_FPS: float        = 8.0
const PLAYER_WALK_PX_PER_SEC: float = 190.0
const DOUBT_LOOK_SEC: float         = 1.3   # seconds to hold each direction when undecided

# ─────────────────────────────────────────────────────────────
# UI refs
# ─────────────────────────────────────────────────────────────

var _map_canvas: Control = null
var _node_btns: Dictionary = {}  # node_id → Control wrapper

var _detail_title_lbl:  Label  = null
var _detail_type_lbl:   Label  = null
var _detail_body_lbl:   Label  = null
var _detail_reward_lbl: Label  = null
var _battle_btn:        Button = null

var _selected_node_id: String = ""
var _layout: Dictionary = {}

# ── Walk / sprite state ───────────────────────────────────────
var _player_node_id:   String          = ""
var _player_sprite:    AnimatedSprite2D = null
var _player_shadow:    ColorRect        = null
var _sprite_foot_y:    float           = 18.0  # placeholder; updated by setup fn
var _is_walking:       bool            = false
var _pending_walk_from: String         = ""
var _pending_walk_to:   String         = ""
var _highlight_tweens: Array           = []
var _highlighted_nodes: Array          = []
var _walk_is_post_win: bool            = false   # set before begin_walk after a battle win

# ── Doubt-look state (multiple available branches) ────────────
var _doubt_targets: Array = []   # node_ids to glance between
var _doubt_index:   int   = 0
var _doubt_tween:   Tween = null

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_layout = DailyDungeonManager.get_current_layout()
	_build_ui()
	_create_player_sprite()
	var start_node: String = _find_player_start_node()
	_place_player_on_node(start_node)
	# Fade the overlay in, then check battle result
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.35)
	tw.tween_callback(_check_pending_result)

# ─────────────────────────────────────────────────────────────
# Build UI
# ─────────────────────────────────────────────────────────────

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Semi-opaque dark overlay so main menu is dimmed behind
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 0.88)
	backdrop.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_build_header()

	var body := HBoxContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_top = 56.0
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
	header.offset_bottom = 56.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.025, 0.042, 0.10, 1.0)
	sb.border_width_bottom = 1
	sb.border_color = Color(1.0, 0.72, 0.22, 0.30)
	header.add_theme_stylebox_override("panel", sb)
	add_child(header)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left  = 18.0
	hbox.offset_right = -18.0
	hbox.add_theme_constant_override("separation", 14)
	header.add_child(hbox)

	var title_lbl := Label.new()
	title_lbl.text = "DAILY DUNGEON"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.30, 1.0))
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(title_lbl)

	var dungeon_name: String = _layout.get("name", "")
	if dungeon_name != "":
		var name_lbl := Label.new()
		name_lbl.text = "—  " + dungeon_name
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55, 0.75))
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(name_lbl)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Active modifier badges
	for mod_key: String in DailyDungeonManager.active_modifiers:
		var is_pos: bool = DailyDungeonManager.MODIFIER_POSITIVE.get(mod_key, true)
		var badge := Label.new()
		badge.text = "  " + DailyDungeonManager.MODIFIER_LABEL.get(mod_key, mod_key) + "  "
		badge.add_theme_font_size_override("font_size", 11)
		badge.add_theme_color_override("font_color",
			Color(0.25, 1.0, 0.50, 1.0) if is_pos else Color(1.0, 0.40, 0.30, 1.0))
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(badge)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(110, 36)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.pressed.connect(func() -> void: queue_free())
	hbox.add_child(close_btn)

# ─────────────────────────────────────────────────────────────
# Map canvas
# ─────────────────────────────────────────────────────────────

func _populate_map_canvas() -> void:
	_node_btns.clear()
	for child in _map_canvas.get_children():
		if child == _player_sprite or child == _player_shadow:
			continue  # preserve across rebuilds
		child.queue_free()

	# Dungeon background
	var bg_path: String = _layout.get("background", "")
	if bg_path != "" and ResourceLoader.exists(bg_path):
		var bg := TextureRect.new()
		bg.texture     = load(bg_path)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.size = Vector2(CANVAS_W, CANVAS_H)
		bg.mouse_filter = MOUSE_FILTER_IGNORE
		_map_canvas.add_child(bg)
	else:
		var bg := ColorRect.new()
		bg.size  = Vector2(CANVAS_W, CANVAS_H)
		bg.color = Color(0.04, 0.06, 0.12, 1.0)
		bg.mouse_filter = MOUSE_FILTER_IGNORE
		_map_canvas.add_child(bg)

	# Build a lookup dict for connection drawing
	var node_map: Dictionary = {}
	for nd: Dictionary in _layout.get("nodes", []):
		node_map[nd.get("id", "")] = nd

	# Connection lines (drawn behind node icons)
	for conn: Array in _layout.get("connections", []):
		if conn.size() < 2:
			continue
		var from_nd: Dictionary = node_map.get(conn[0], {})
		var to_nd:   Dictionary = node_map.get(conn[1], {})
		if from_nd.is_empty() or to_nd.is_empty():
			continue
		var from_pos := Vector2(float(from_nd.get("x", 0)), float(from_nd.get("y", 0)))
		var to_pos   := Vector2(float(to_nd.get("x", 0)),   float(to_nd.get("y", 0)))
		var to_status: String = DailyDungeonManager.get_node_status(conn[1])
		var line_color: Color
		var locked_line: bool = (to_status == "locked")
		match to_status:
			"cleared":
				line_color = Color(0.30, 0.90, 0.55, 1.0)
			"available":
				line_color = Color(1.00, 0.72, 0.22, 1.0)
			_:
				line_color = Color(0.50, 0.50, 0.65, 0.9)
		# Shadow
		var shadow := Line2D.new()
		shadow.add_point(from_pos + Vector2(2.0, 3.0))
		shadow.add_point(to_pos   + Vector2(2.0, 3.0))
		shadow.width = 4.0
		shadow.default_color = Color(0.0, 0.0, 0.0, 0.9 if locked_line else 0.45)
		_map_canvas.add_child(shadow)
		# Main line
		var line := Line2D.new()
		line.add_point(from_pos)
		line.add_point(to_pos)
		line.width = 3.0
		line.default_color = line_color
		_map_canvas.add_child(line)

	# Node icons
	for nd: Dictionary in _layout.get("nodes", []):
		var node_id: String = nd.get("id", "")
		var icon := _make_node_icon(nd)
		var nx: float = float(nd.get("x", 0))
		var ny: float = float(nd.get("y", 0))
		icon.position = Vector2(nx - 30.0, ny - 30.0)
		_map_canvas.add_child(icon)
		_node_btns[node_id] = icon

	# Keep sprite and shadow on top of all node icons
	if _player_shadow != null and _player_shadow.is_inside_tree():
		_map_canvas.move_child(_player_shadow, _map_canvas.get_child_count() - 1)
	if _player_sprite != null and _player_sprite.is_inside_tree():
		_map_canvas.move_child(_player_sprite, _map_canvas.get_child_count() - 1)

func _node_color(nd: Dictionary) -> Color:
	var status: String = DailyDungeonManager.get_node_status(nd.get("id", ""))
	if status == "cleared":
		return COLOR_CLEARED
	if status == "locked":
		return COLOR_LOCKED
	return COLOR_BOSS_AVAIL if nd.get("type", "normal") == "boss" else COLOR_NORMAL_AVAIL

func _make_node_icon(nd: Dictionary) -> Control:
	var node_id: String = nd.get("id", "")
	var is_boss: bool   = nd.get("type", "normal") == "boss"
	var status: String  = DailyDungeonManager.get_node_status(node_id)
	var locked:  bool   = status == "locked"
	var cleared: bool   = status == "cleared"
	var tc := _node_color(nd)
	var icon_size := Vector2(62.0, 62.0) if is_boss else Vector2(50.0, 50.0)

	var wrapper := Control.new()
	wrapper.custom_minimum_size = icon_size + Vector2(0.0, 22.0)
	wrapper.size = icon_size + Vector2(0.0, 22.0)

	# Custom node image (set in builder) takes priority over platform icon
	var custom_img_path: String = nd.get("image", "")
	var icon_path: String = ICON_BOSS_PATH if is_boss else ICON_NORMAL_PATH
	var use_path: String = custom_img_path if (custom_img_path != "" and ResourceLoader.exists(custom_img_path)) \
		else (icon_path if ResourceLoader.exists(icon_path) else "")

	if use_path != "":
		# Clip container guarantees icon_size rendering regardless of texture dimensions
		var clip_box := Control.new()
		clip_box.size          = icon_size
		clip_box.clip_contents = true
		var tex_rect := TextureRect.new()
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture      = load(use_path) as Texture2D
		if cleared:
			tex_rect.modulate = Color(0.60, 1.0, 0.70, 1.0)
		clip_box.add_child(tex_rect)
		wrapper.add_child(clip_box)
	else:
		# Fallback: styled panel
		var panel := Panel.new()
		panel.size = icon_size
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.07, 0.16, 1.0)
		sb.border_width_left   = 2; sb.border_width_top    = 2
		sb.border_width_right  = 2; sb.border_width_bottom = 2
		var r: float = 14.0 if is_boss else 10.0
		sb.corner_radius_top_left     = r; sb.corner_radius_top_right    = r
		sb.corner_radius_bottom_right = r; sb.corner_radius_bottom_left  = r
		sb.border_color = COLOR_CLEARED if cleared else tc
		panel.add_theme_stylebox_override("panel", sb)
		wrapper.add_child(panel)

		var icon_lbl := Label.new()
		icon_lbl.size     = icon_size
		icon_lbl.position = Vector2(0.0, 4.0)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 20 if is_boss else 16)
		icon_lbl.text = "B" if is_boss else "N"
		icon_lbl.add_theme_color_override("font_color", COLOR_CLEARED if cleared else tc)
		panel.add_child(icon_lbl)

	# Overall alpha: locked = 0.9, everything else = 1.0
	if locked:
		wrapper.modulate = Color(1.0, 1.0, 1.0, 0.9)

	# Checkmark for cleared nodes
	if cleared:
		var check := Label.new()
		check.text     = "✓"
		check.size     = Vector2(20.0, 20.0)
		check.position = Vector2(icon_size.x - 4.0, -4.0)
		check.add_theme_font_size_override("font_size", 14)
		check.add_theme_color_override("font_color", Color(0.30, 1.00, 0.50, 1.0))
		wrapper.add_child(check)

	# Label below icon
	var name_lbl := Label.new()
	name_lbl.text     = nd.get("label", node_id)
	name_lbl.size     = Vector2(100.0, 18.0)
	name_lbl.position = Vector2(-25.0, icon_size.y + 3.0)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.84, 0.68, 1.0))
	wrapper.add_child(name_lbl)

	# Invisible click button for unlocked nodes
	if not locked:
		var btn := Button.new()
		btn.size = icon_size
		var empty := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal",  empty)
		btn.add_theme_stylebox_override("hover",   empty)
		btn.add_theme_stylebox_override("pressed", empty)
		btn.add_theme_stylebox_override("focus",   empty)
		btn.pressed.connect(_on_node_clicked.bind(node_id))
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
	sb.bg_color = Color(0.018, 0.032, 0.072, 0.5)
	sb.border_width_left = 1
	sb.border_color      = Color(1.0, 0.72, 0.22, 0.18)
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   =  26.0;  vbox.offset_top    =  26.0
	vbox.offset_right  = -26.0;  vbox.offset_bottom = -26.0
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	_detail_type_lbl = Label.new()
	_detail_type_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_detail_type_lbl)

	_detail_title_lbl = Label.new()
	_detail_title_lbl.text = "Select a node"
	_detail_title_lbl.add_theme_font_size_override("font_size", 24)
	_detail_title_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.75, 1.0))
	_detail_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_detail_title_lbl)

	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0.0, 1.0)
	div.color = Color(1.0, 0.72, 0.22, 0.22)
	vbox.add_child(div)

	_detail_body_lbl = Label.new()
	_detail_body_lbl.add_theme_font_size_override("font_size", 13)
	_detail_body_lbl.add_theme_color_override("font_color", Color(0.82, 0.78, 0.68, 0.88))
	_detail_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_detail_body_lbl)

	_detail_reward_lbl = Label.new()
	_detail_reward_lbl.add_theme_font_size_override("font_size", 14)
	_detail_reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.30, 0.90))
	vbox.add_child(_detail_reward_lbl)

	# Active modifier list
	if not DailyDungeonManager.active_modifiers.is_empty():
		var mod_div := ColorRect.new()
		mod_div.custom_minimum_size = Vector2(0.0, 1.0)
		mod_div.color = Color(1.0, 0.72, 0.22, 0.12)
		vbox.add_child(mod_div)

		var mod_title := Label.new()
		mod_title.text = "TODAY'S MODIFIERS"
		mod_title.add_theme_font_size_override("font_size", 11)
		mod_title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.30, 0.50))
		vbox.add_child(mod_title)

		for mod_key: String in DailyDungeonManager.active_modifiers:
			var is_pos: bool = DailyDungeonManager.MODIFIER_POSITIVE.get(mod_key, true)
			var label: String = DailyDungeonManager.MODIFIER_LABEL.get(mod_key, mod_key)
			var desc:  String = DailyDungeonManager.MODIFIER_DESC.get(mod_key, "")
			var mod_lbl := Label.new()
			mod_lbl.text = "• %s: %s" % [label, desc]
			mod_lbl.add_theme_font_size_override("font_size", 11)
			mod_lbl.add_theme_color_override("font_color",
				Color(0.35, 1.0, 0.55, 0.85) if is_pos else Color(1.0, 0.45, 0.35, 0.85))
			mod_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			vbox.add_child(mod_lbl)

	_battle_btn = Button.new()
	_battle_btn.custom_minimum_size = Vector2(0.0, 46.0)
	_battle_btn.add_theme_font_size_override("font_size", 16)
	_battle_btn.visible = false
	_battle_btn.pressed.connect(_on_battle_pressed)
	vbox.add_child(_battle_btn)

# ─────────────────────────────────────────────────────────────
# Node selection + detail update
# ─────────────────────────────────────────────────────────────

func _on_node_clicked(node_id: String) -> void:
	if _is_walking:
		return
	_stop_branch_highlight()
	_selected_node_id = node_id
	_update_detail()

func _update_detail() -> void:
	if _detail_title_lbl == null:
		return
	var nd: Dictionary = _find_node(_selected_node_id)
	if nd.is_empty():
		return

	var is_boss: bool  = nd.get("type", "normal") == "boss"
	var status: String = DailyDungeonManager.get_node_status(_selected_node_id)
	var is_first: bool = DailyDungeonManager.is_first_clear(_selected_node_id)

	_detail_title_lbl.text = nd.get("label", _selected_node_id)

	if is_boss:
		_detail_type_lbl.text = "BOSS NODE"
		_detail_type_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
	else:
		_detail_type_lbl.text = "BATTLE NODE"
		_detail_type_lbl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.22, 1.0))

	match status:
		"cleared":
			_detail_body_lbl.text = "You have cleared this node today.\nChallenge it again for a smaller reward."
		"available":
			if is_boss:
				_detail_body_lbl.text = "The dungeon's final challenge.\nFirst clear earns a booster pack sent to your Inventory."
			else:
				_detail_body_lbl.text = "Challenge this node to earn credits and conquer the dungeon."
		_:
			_detail_body_lbl.text = "Complete an adjacent node to unlock this one."

	# Reward line
	var mult: float = DailyDungeonManager.credit_multiplier()
	if is_boss:
		var base_cr: int = DailyDungeonManager.REWARD_BOSS_FIRST if is_first \
			else DailyDungeonManager.REWARD_BOSS_REVISIT
		var cr: int = int(base_cr * mult)
		var pack_name: String = nd.get("pack_reward", "Starter Pack")
		if pack_name.is_empty():
			pack_name = "Starter Pack"
		if is_first:
			_detail_reward_lbl.text = "First clear: +%d credits + %s" % [cr, pack_name]
		else:
			_detail_reward_lbl.text = "Revisit: +%d credits" % cr
	else:
		var base_cr: int = DailyDungeonManager.REWARD_NORMAL_FIRST if is_first \
			else DailyDungeonManager.REWARD_NORMAL_REVISIT
		var cr: int = int(base_cr * mult)
		if is_first:
			_detail_reward_lbl.text = "First clear: +%d credits" % cr
		else:
			_detail_reward_lbl.text = "Revisit: +%d credits" % cr

	_battle_btn.visible  = (status != "locked")
	_battle_btn.disabled = false
	_battle_btn.text     = "BATTLE"

# ─────────────────────────────────────────────────────────────
# Battle
# ─────────────────────────────────────────────────────────────

func _on_battle_pressed() -> void:
	if _selected_node_id.is_empty():
		return
	var nd: Dictionary = _find_node(_selected_node_id)
	if nd.is_empty():
		return
	var deck := SaveManager.get_active_deck()
	if deck == null or not deck.is_valid():
		_show_deck_warning()
		return
	DailyDungeonManager.player_map_node_id = _player_node_id  # remember where we were
	DailyDungeonManager.start_node_battle(nd, self)

func _show_deck_warning() -> void:
	if get_node_or_null("DeckWarning") != null:
		return
	var lbl := Label.new()
	lbl.name = "DeckWarning"
	lbl.text = "Deck not ready — please build a valid deck first."
	lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl.offset_top    = 70.0
	lbl.offset_bottom = 100.0
	lbl.offset_left   = -320.0
	lbl.offset_right  =  320.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35, 1.0))
	lbl.z_index = 20
	add_child(lbl)
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tween.tween_callback(lbl.queue_free)

# ─────────────────────────────────────────────────────────────
# Return from battle — check result and refresh
# ─────────────────────────────────────────────────────────────

func _check_pending_result() -> void:
	var result: Dictionary = DailyDungeonManager.pending_battle_result
	if result.is_empty():
		return
	DailyDungeonManager.pending_battle_result = {}

	var node_id: String = result.get("node_id", "")
	var won: bool       = result.get("won", false)

	# The sprite should walk FROM where the player was BEFORE the battle
	_pending_walk_from = DailyDungeonManager.player_map_node_id
	_pending_walk_to   = node_id if won else ""

	_populate_map_canvas()
	if node_id != "":
		_selected_node_id = node_id
		_update_detail()

	_show_result_banner(won, node_id)

func _show_result_banner(won: bool, node_id: String) -> void:
	if get_node_or_null("ResultBanner") != null:
		return

	var accent: Color = Color(0.30, 1.00, 0.55, 1.0) if won else Color(1.00, 0.38, 0.28, 1.0)

	var panel := Panel.new()
	panel.name = "ResultBanner"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -190.0;  panel.offset_right  = 190.0
	panel.offset_top  = -100.0;  panel.offset_bottom = 100.0
	panel.z_index = 60
	var sb := StyleBoxFlat.new()
	sb.bg_color    = Color(0.04, 0.07, 0.14, 0.97)
	sb.border_width_left   = 2; sb.border_width_top    = 2
	sb.border_width_right  = 2; sb.border_width_bottom = 2
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.85)
	sb.corner_radius_top_left     = 10; sb.corner_radius_top_right    = 10
	sb.corner_radius_bottom_left  = 10; sb.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 24.0; vbox.offset_right  = -24.0
	vbox.offset_top  = 20.0; vbox.offset_bottom = -20.0
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "VICTORY!" if won else "DEFEATED"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", accent)
	vbox.add_child(title_lbl)

	if not node_id.is_empty():
		var nd: Dictionary = _find_node(node_id)
		var sub_lbl := Label.new()
		sub_lbl.text = nd.get("label", node_id) if won else "Better luck next time."
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_lbl.add_theme_font_size_override("font_size", 14)
		sub_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.70, 0.85))
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(sub_lbl)

	var cont_btn := Button.new()
	cont_btn.text = "Continue"
	cont_btn.custom_minimum_size = Vector2(0.0, 40.0)
	cont_btn.add_theme_font_size_override("font_size", 15)
	cont_btn.pressed.connect(func() -> void:
		panel.queue_free()
		if won and not _pending_walk_to.is_empty():
			_walk_is_post_win = true
			_begin_walk(_pending_walk_from, _pending_walk_to))
	vbox.add_child(cont_btn)

	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.28)

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────

func _find_node(node_id: String) -> Dictionary:
	for nd: Dictionary in _layout.get("nodes", []):
		if nd.get("id", "") == node_id:
			return nd
	return {}

# ─────────────────────────────────────────────────────────────
# Player sprite — creation
# ─────────────────────────────────────────────────────────────

func _create_player_sprite() -> void:
	# Shadow — flat dark rect under the sprite's feet
	_player_shadow = ColorRect.new()
	_player_shadow.name        = "PlayerShadow"
	_player_shadow.color       = Color(0.0, 0.0, 0.0, 0.32)
	_player_shadow.size        = Vector2(36.0, 10.0)
	_player_shadow.mouse_filter = MOUSE_FILTER_IGNORE
	_player_shadow.z_index     = 4
	_map_canvas.add_child(_player_shadow)

	_player_sprite = AnimatedSprite2D.new()
	_player_sprite.name    = "PlayerSprite"
	_player_sprite.z_index = 5

	if ResourceLoader.exists(PLAYER_SHEET_PATH):
		_setup_real_sprite_frames()
	else:
		_setup_placeholder_sprite_frames()

	_player_sprite.animation = "walk_south"
	_player_sprite.play()
	_map_canvas.add_child(_player_sprite)

func _setup_real_sprite_frames() -> void:
	var tex: Texture2D = load(PLAYER_SHEET_PATH)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	# Row order in sprite_nex_walking.png:
	# 0=south 1=south_west 2=west 3=north_west 4=north 5=north_east 6=east 7=south_east
	var dir_names: Array = [
		"walk_south", "walk_south_west", "walk_west", "walk_north_west",
		"walk_north", "walk_north_east", "walk_east", "walk_south_east"
	]
	for di: int in range(8):
		frames.add_animation(dir_names[di])
		frames.set_animation_loop(dir_names[di], true)
		frames.set_animation_speed(dir_names[di], SPRITE_WALK_FPS)
		for fi: int in range(SPRITE_FRAMES_PER_DIR):
			var atlas := AtlasTexture.new()
			atlas.atlas  = tex
			atlas.region = Rect2(fi * SPRITE_FRAME_W, di * SPRITE_FRAME_H,
								 SPRITE_FRAME_W, SPRITE_FRAME_H)
			frames.add_frame(dir_names[di], atlas)
	_player_sprite.sprite_frames = frames
	_sprite_foot_y = float(SPRITE_FRAME_H) * 0.5  # center-to-feet

func _setup_placeholder_sprite_frames() -> void:
	# 20×36 pixel character. 4 frames per direction showing leg alternation.
	# All directions share the same frame set (no direction-specific art in placeholder).
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var dir_names: Array = ["walk_down", "walk_left", "walk_right", "walk_up"]
	# Left-leg x, right-leg x per frame
	var leg_cfgs: Array = [[7, 12], [5, 14], [7, 12], [9, 10]]
	for di: int in range(4):
		frames.add_animation(dir_names[di])
		frames.set_animation_loop(dir_names[di], true)
		frames.set_animation_speed(dir_names[di], SPRITE_WALK_FPS)
		for fi: int in range(4):
			var img: Image = Image.create(20, 36, false, Image.FORMAT_RGBA8)
			# Hair
			for px: int in range(4, 16):
				for py: int in range(0, 3):
					img.set_pixel(px, py, Color(0.18, 0.13, 0.09, 1.0))
			# Head (skin)
			for px: int in range(5, 15):
				for py: int in range(2, 10):
					img.set_pixel(px, py, Color(0.82, 0.67, 0.52, 1.0))
			# Body / jacket
			for px: int in range(3, 17):
				for py: int in range(10, 23):
					img.set_pixel(px, py, Color(0.22, 0.35, 0.78, 1.0))
			# Legs (alternating per frame)
			var ll: int = leg_cfgs[fi][0]
			var rl: int = leg_cfgs[fi][1]
			for py: int in range(23, 35):
				if ll + 1 < 20:
					img.set_pixel(ll,     py, Color(0.14, 0.12, 0.20, 1.0))
					img.set_pixel(ll + 1, py, Color(0.14, 0.12, 0.20, 1.0))
				if rl + 1 < 20:
					img.set_pixel(rl,     py, Color(0.14, 0.12, 0.20, 1.0))
					img.set_pixel(rl + 1, py, Color(0.14, 0.12, 0.20, 1.0))
			frames.add_frame(dir_names[di], ImageTexture.create_from_image(img))
	_player_sprite.sprite_frames = frames
	_sprite_foot_y = 18.0  # 36px tall, center-to-feet

# ─────────────────────────────────────────────────────────────
# Player sprite — positioning
# ─────────────────────────────────────────────────────────────

func _node_canvas_pos(node_id: String) -> Vector2:
	var nd: Dictionary = _find_node(node_id)
	return Vector2(float(nd.get("x", 0.0)), float(nd.get("y", 0.0)))

func _place_player_on_node(node_id: String) -> void:
	if node_id.is_empty():
		return
	_player_node_id = node_id
	DailyDungeonManager.player_map_node_id = node_id
	var np: Vector2 = _node_canvas_pos(node_id)
	# Sprite anchor is centre; position sprite so feet touch the node centre
	_player_sprite.position = np + Vector2(0.0, -_sprite_foot_y)
	_update_shadow_pos(_player_sprite.position)
	_idle_face(node_id)

func _update_shadow_pos(sprite_pos: Vector2) -> void:
	if _player_shadow != null:
		# Centre the shadow horizontally; sit it at the sprite's feet
		_player_shadow.position = sprite_pos + Vector2(-13.0, _sprite_foot_y - 4.0)

# Determines where the player starts when the map first opens.
func _find_player_start_node() -> String:
	# Prefer the persisted position from the last session / battle launch
	var persisted: String = DailyDungeonManager.player_map_node_id
	if not persisted.is_empty() and not _find_node(persisted).is_empty():
		return persisted

	var nodes: Array = _layout.get("nodes", [])
	if nodes.is_empty():
		return ""

	# Find entry node
	var entry_id: String = ""
	for nd: Dictionary in nodes:
		if nd.get("is_entry", false):
			entry_id = nd.get("id", "")
			break
	if entry_id.is_empty():
		entry_id = nodes[0].get("id", "")

	# BFS from entry — find the deepest cleared node (player's progress frontier)
	var dungeon_id: String = DailyDungeonManager.get_current_dungeon_id()
	var progress: Dictionary = DailyDungeonManager.node_progress.get(dungeon_id, {})
	if progress.is_empty():
		return entry_id

	var visited: Dictionary = {}
	var queue: Array = [entry_id]
	var deepest: String = entry_id
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		if visited.has(cur):
			continue
		visited[cur] = true
		if progress.get(cur, {}).get("cleared", false):
			deepest = cur
		for conn: Array in _layout.get("connections", []):
			if conn.size() < 2:
				continue
			if conn[0] == cur and not visited.has(conn[1]):
				queue.append(conn[1])
			elif conn[1] == cur and not visited.has(conn[0]):
				queue.append(conn[0])
	return deepest

# ─────────────────────────────────────────────────────────────
# Walking
# ─────────────────────────────────────────────────────────────

func _begin_walk(from_id: String, to_id: String) -> void:
	if to_id.is_empty():
		return
	_stop_doubt_cycle()
	_is_walking = true
	if _battle_btn:
		_battle_btn.disabled = true

	var from_pos: Vector2 = _node_canvas_pos(from_id) if not from_id.is_empty() \
		else _player_sprite.position + Vector2(0.0, _sprite_foot_y)
	var to_pos: Vector2 = _node_canvas_pos(to_id)

	var dir: String = _direction_anim(from_pos, to_pos)
	_player_sprite.animation = dir
	_player_sprite.play()

	var distance: float = from_pos.distance_to(to_pos)
	var duration: float = maxf(0.3, distance / PLAYER_WALK_PX_PER_SEC)

	var start_spos: Vector2 = from_pos + Vector2(0.0, -_sprite_foot_y)
	var end_spos: Vector2   = to_pos   + Vector2(0.0, -_sprite_foot_y)

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(_move_player_to, start_spos, end_spos, duration)
	tw.tween_callback(func() -> void: _on_walk_arrived(to_id))

func _move_player_to(sprite_pos: Vector2) -> void:
	_player_sprite.position = sprite_pos
	_update_shadow_pos(sprite_pos)

func _on_walk_arrived(node_id: String) -> void:
	_player_node_id = node_id
	DailyDungeonManager.player_map_node_id = node_id
	_is_walking = false
	if _battle_btn:
		_battle_btn.disabled = false
	var post_win := _walk_is_post_win
	_walk_is_post_win = false
	_idle_face(node_id, post_win)

	# Highlight branching choices
	var next_nodes: Array = _get_connected_nodes(node_id)
	if next_nodes.size() > 1:
		_start_branch_highlight(next_nodes)

func _idle_face(node_id: String, allow_doubt: bool = false) -> void:
	_stop_doubt_cycle()
	# Doubt only after a battle win when 2+ available paths exist
	if allow_doubt:
		var available: Array = []
		for conn_id: String in _get_connected_nodes(node_id):
			if DailyDungeonManager.get_node_status(conn_id) == "available":
				available.append(conn_id)
		if available.size() >= 2:
			_start_doubt_cycle(available)
			return
	# Default: face south and keep stepping
	_player_sprite.animation = "walk_south"
	_player_sprite.play()

# ─── Doubt-look helpers ───────────────────────────────────────

func _start_doubt_cycle(targets: Array) -> void:
	_doubt_targets = targets.duplicate()
	_doubt_index   = 0
	_face_doubt_target()
	_schedule_next_doubt()

func _schedule_next_doubt() -> void:
	_doubt_tween = create_tween()
	_doubt_tween.tween_interval(DOUBT_LOOK_SEC)
	_doubt_tween.tween_callback(_advance_doubt)

func _advance_doubt() -> void:
	if _doubt_targets.is_empty():
		return
	_doubt_index = (_doubt_index + 1) % _doubt_targets.size()
	_face_doubt_target()
	_schedule_next_doubt()

func _face_doubt_target() -> void:
	if _doubt_targets.is_empty() or _player_node_id.is_empty():
		return
	var my_pos: Vector2     = _node_canvas_pos(_player_node_id)
	var target_id: String   = _doubt_targets[_doubt_index]
	var target_pos: Vector2 = _node_canvas_pos(target_id)
	_player_sprite.animation = _direction_anim(my_pos, target_pos)
	_player_sprite.play()

func _stop_doubt_cycle() -> void:
	if _doubt_tween != null and _doubt_tween.is_valid():
		_doubt_tween.kill()
	_doubt_tween   = null
	_doubt_targets = []
	_doubt_index   = 0

func _direction_anim(from_pos: Vector2, to_pos: Vector2) -> String:
	var d: Vector2 = to_pos - from_pos
	var angle_deg: float = rad_to_deg(atan2(d.y, d.x))
	# atan2: 0=east, 90=south, ±180=west, -90=north (Godot Y-down)
	if angle_deg < -157.5 or angle_deg >= 157.5:
		return "walk_west"
	elif angle_deg < -112.5:
		return "walk_north_west"
	elif angle_deg < -67.5:
		return "walk_north"
	elif angle_deg < -22.5:
		return "walk_north_east"
	elif angle_deg < 22.5:
		return "walk_east"
	elif angle_deg < 67.5:
		return "walk_south_east"
	elif angle_deg < 112.5:
		return "walk_south"
	else:
		return "walk_south_west"

func _get_connected_nodes(node_id: String) -> Array:
	var result: Array = []
	for conn: Array in _layout.get("connections", []):
		if conn.size() < 2:
			continue
		if conn[0] == node_id and conn[1] not in result:
			result.append(conn[1])
		elif conn[1] == node_id and conn[0] not in result:
			result.append(conn[0])
	return result

# ─────────────────────────────────────────────────────────────
# Branch highlighting
# ─────────────────────────────────────────────────────────────

func _start_branch_highlight(node_ids: Array) -> void:
	_stop_branch_highlight()
	_highlighted_nodes = node_ids.duplicate()
	for nid: String in _highlighted_nodes:
		var wrapper: Variant = _node_btns.get(nid)
		if wrapper == null:
			continue
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(wrapper, "modulate",
			Color(1.6, 1.4, 0.4, 1.0), 0.45).set_trans(Tween.TRANS_SINE)
		tw.tween_property(wrapper, "modulate",
			Color(1.0, 1.0, 1.0, 1.0), 0.45).set_trans(Tween.TRANS_SINE)
		_highlight_tweens.append(tw)

func _stop_branch_highlight() -> void:
	for tw: Variant in _highlight_tweens:
		if tw is Tween:
			tw.kill()
	_highlight_tweens.clear()
	for nid: String in _highlighted_nodes:
		var wrapper: Variant = _node_btns.get(nid)
		if wrapper != null:
			(wrapper as Control).modulate = Color(1.0, 1.0, 1.0, 1.0)
	_highlighted_nodes.clear()
