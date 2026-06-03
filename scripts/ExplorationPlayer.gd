extends Control
## ExplorationPlayer — standalone runtime scene for Exploration sessions.
##
## Load via:
##   get_tree().change_scene_to_file("res://scenes/exploration_player.tscn")
##   OR
##   ExplorationManager.launch("res://exploration/graphs/my_graph.json")
##
## Requires an active ExplorationManager session BEFORE this scene loads.
## The scene connects to ExplorationManager signals and renders the current node.
##
## Debug:
##   Press F3 to toggle the debug overlay (shows inventory, vars, history).
##   Click the [DBG] button in the top-right corner for the same effect.

const VN_PLAYER_SCENE: PackedScene = preload("res://scenes/vn_player.tscn")
const FONT_PATH: String    = "res://assets/fonts/Chivo-VariableFont_wght.ttf"
const COMPASS_ICON: String    = "res://assets/textures/ui/decorations/ui_icon_compass.png"
const MAGNIFIER_CURSOR: String = "res://assets/textures/ui/decorations/ui_icon_magnifier.png"
const COMPASS_SIZE: float  = 110.0  # icon width/height in pixels
const RADIAL_RADIUS: float = 210.0  # distance from center to item midpoint
const RADIAL_ITEM_W: float = 180.0  # radial button width
const RADIAL_ITEM_H: float = 54.0   # radial button height
const BG_AREA_FRACTION: float = 0.52  # fraction of viewport width used by the background area

# ── UI references (all built in _build_ui) ────────────────────────────────
var _bg_rect: TextureRect          = null   # background image
var _bg_base: ColorRect            = null   # solid-colour fallback behind bg
var _title_lbl: Label              = null   # node title
var _type_badge_lbl: Label         = null   # coloured node-type label
var _desc_lbl: RichTextLabel       = null   # node description
var _choices_vbox: VBoxContainer   = null   # navigation choice buttons
var _back_btn: Button              = null   # go-back button
var _inventory_panel: PanelContainer = null
var _inventory_hbox: HBoxContainer = null   # per-item slot buttons
var _toast_lbl: Label              = null   # temporary message overlay
var _toast_tween: Tween            = null
var _debug_panel: PanelContainer   = null   # F3 debug overlay
var _debug_lbl: RichTextLabel      = null
var _content_panel: Panel          = null   # right-side content area (layout_mode=0, sized by _reflow_layout)

# ── Compass radial menu ───────────────────────────────────────────────────
var _compass_root: Control        = null   # full-screen layer holding compass + radial
var _compass_icon: TextureRect    = null   # the compass texture
var _compass_hit: Button          = null   # invisible click area over the icon
var _radial_overlay: Control      = null   # full-screen click-catcher (outside dismiss)
var _radial_items: Array          = []     # currently shown radial PanelContainers
var _compass_open: bool           = false
var _compass_animating: bool      = false
# Positions computed in _build_compass_system() after scene is sized
var _compass_idle_pos: Vector2    = Vector2.ZERO
var _compass_center_pos: Vector2  = Vector2.ZERO

# ── Internal state ────────────────────────────────────────────────────────
var _current_bg_path: String = ""
var _vn_playing: bool        = false
var _battle_pending: bool    = false
var _exit_pending: bool      = false
var _item_use_panel: PanelContainer = null  # floating use-item confirmation panel

# ── Point-and-click hotspots ──────────────────────────────────────────────
var _spots_layer: Control          = null   # holds spot hit-controls + icons
var _tooltip_panel: PanelContainer = null   # cursor-following tooltip
var _tooltip_lbl: Label            = null
var _hovering_spot: bool           = false
var _magnifier_tex: Texture2D      = null

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_ui()
	_connect_signals()

	# Returning from a battle? Show result then refresh.
	if not ExplorationManager.pending_battle_result.is_empty():
		_handle_post_battle_result()
	elif ExplorationManager.is_session_active and ExplorationManager.current_node != null:
		_refresh_node(ExplorationManager.current_node)
	elif ExplorationManager.restore_saved_session():
		# Resumed from a save-file snapshot (e.g. after game restart mid-exploration)
		var resumed_node: ExplorationNode = ExplorationManager.current_node
		if resumed_node != null:
			_show_toast("Session resumed.")
			_refresh_node(resumed_node)
		else:
			_show_no_session_error()
	else:
		_show_no_session_error()

	CheckerTransition.fade_in()

func _connect_signals() -> void:
	ExplorationManager.node_entered.connect(_on_node_entered)
	ExplorationManager.message_posted.connect(_show_toast)
	ExplorationManager.inventory_changed.connect(_on_inventory_changed)

# ─────────────────────────────────────────────────────────────
# UI Construction
# ─────────────────────────────────────────────────────────────

func _make_font(weight: int) -> FontVariation:
	var base := load(FONT_PATH) as FontFile
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {"wght": weight}
	return fv

func _build_ui() -> void:
	# ── Background ────────────────────────────────────────────
	_bg_base = ColorRect.new()
	_bg_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_base.color        = Color(0.04, 0.06, 0.14, 1.0)
	_bg_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_base)

	_bg_rect = TextureRect.new()
	_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.modulate.a   = 0.0
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	# ── Vignette ──────────────────────────────────────────────
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color        = Color(0.0, 0.0, 0.0, 0.55)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	# ── Right-side content panel ──────────────────────────────
	# layout_mode=0: position/size are set explicitly by _reflow_layout() to avoid
	# anchor-offset compensation bugs when anchors are resolved before viewport size is known.
	var content := Panel.new()
	var sb_panel := StyleBoxFlat.new()
	sb_panel.bg_color          = Color(0.03, 0.05, 0.13, 0.90)
	sb_panel.border_width_left = 2
	sb_panel.border_color      = Color(0.35, 0.60, 1.0, 0.30)
	content.add_theme_stylebox_override("panel", sb_panel)
	add_child(content)
	_content_panel = content

	var vbox := VBoxContainer.new()
	vbox.set_anchor(SIDE_LEFT,   0.0, false, false)
	vbox.set_anchor(SIDE_RIGHT,  1.0, false, false)
	vbox.set_anchor(SIDE_TOP,    0.0, false, false)
	vbox.set_anchor(SIDE_BOTTOM, 1.0, false, false)
	vbox.offset_left   = 28.0; vbox.offset_right  = -28.0
	vbox.offset_top    = 28.0; vbox.offset_bottom = -28.0
	vbox.add_theme_constant_override("separation", 14)
	content.add_child(vbox)

	# Type badge
	_type_badge_lbl = Label.new()
	_type_badge_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_type_badge_lbl)

	# Title
	_title_lbl = Label.new()
	_title_lbl.add_theme_font_override("font", _make_font(700))
	_title_lbl.add_theme_font_size_override("font_size", 32)
	_title_lbl.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 1.0))
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_title_lbl)

	var sep1 := HSeparator.new()
	var sb_sep := StyleBoxFlat.new()
	sb_sep.bg_color = Color(0.35, 0.60, 1.0, 0.25)
	sb_sep.content_margin_top = 3.0; sb_sep.content_margin_bottom = 3.0
	sep1.add_theme_stylebox_override("separator", sb_sep)
	vbox.add_child(sep1)

	# Description
	_desc_lbl = RichTextLabel.new()
	_desc_lbl.bbcode_enabled = true
	_desc_lbl.scroll_active  = false
	_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desc_lbl.add_theme_font_override("normal_font", _make_font(400))
	_desc_lbl.add_theme_font_size_override("normal_font_size", 22)
	_desc_lbl.add_theme_color_override("default_color", Color(0.82, 0.90, 1.0, 0.95))
	vbox.add_child(_desc_lbl)

	var sep2 := sep1.duplicate() as Control
	vbox.add_child(sep2)

	# Choices vbox — only used by BATTLE and EXIT nodes (special action buttons).
	# Navigation choices are handled by the radial compass menu instead.
	_choices_vbox = VBoxContainer.new()
	_choices_vbox.add_theme_constant_override("separation", 10)
	_choices_vbox.visible = false
	vbox.add_child(_choices_vbox)

	# Bottom row: back button + inventory
	var bot_row := HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 10)
	vbox.add_child(bot_row)

	_back_btn = Button.new()
	_back_btn.text = "← Go Back"
	_back_btn.add_theme_font_size_override("font_size", 16)
	_back_btn.add_theme_color_override("font_color", Color(0.55, 0.78, 0.95))
	_back_btn.pressed.connect(_on_back_pressed)
	bot_row.add_child(_back_btn)

	# Inventory slots container (right-aligned, expands to fill)
	_inventory_panel = PanelContainer.new()
	_inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb_inv := StyleBoxFlat.new()
	sb_inv.bg_color       = Color(0.05, 0.12, 0.08, 0.85)
	sb_inv.border_color   = Color(0.35, 0.75, 0.45, 0.50)
	sb_inv.set_border_width_all(1)
	sb_inv.set_corner_radius_all(6)
	sb_inv.content_margin_left = 8.0; sb_inv.content_margin_right  = 8.0
	sb_inv.content_margin_top  = 4.0; sb_inv.content_margin_bottom = 4.0
	_inventory_panel.add_theme_stylebox_override("panel", sb_inv)
	_inventory_hbox = HBoxContainer.new()
	_inventory_hbox.add_theme_constant_override("separation", 6)
	_inventory_panel.add_child(_inventory_hbox)
	bot_row.add_child(_inventory_panel)

	# ── Debug button (top-right corner) ───────────────────────
	var dbg_btn := Button.new()
	dbg_btn.text         = "DBG"
	dbg_btn.layout_mode  = 1
	dbg_btn.anchor_left  = 1.0; dbg_btn.anchor_right  = 1.0
	dbg_btn.anchor_top   = 0.0; dbg_btn.anchor_bottom = 0.0
	dbg_btn.offset_left  = -58.0; dbg_btn.offset_right  = -6.0
	dbg_btn.offset_top   = 6.0;   dbg_btn.offset_bottom = 34.0
	dbg_btn.add_theme_font_size_override("font_size", 11)
	dbg_btn.pressed.connect(_toggle_debug)
	add_child(dbg_btn)

	# ── Debug panel ───────────────────────────────────────────
	_debug_panel = PanelContainer.new()
	_debug_panel.visible    = false
	_debug_panel.z_index    = 200
	_debug_panel.layout_mode = 1
	_debug_panel.anchor_left   = 0.0; _debug_panel.anchor_right  = 0.52
	_debug_panel.anchor_top    = 0.0; _debug_panel.anchor_bottom = 1.0
	_debug_panel.offset_left   = 8.0; _debug_panel.offset_top    = 8.0
	_debug_panel.offset_bottom = -8.0
	var sb_dbg := StyleBoxFlat.new()
	sb_dbg.bg_color = Color(0.0, 0.04, 0.0, 0.90)
	sb_dbg.set_border_width_all(1)
	sb_dbg.border_color = Color(0.3, 0.9, 0.3, 0.6)
	sb_dbg.set_corner_radius_all(6)
	sb_dbg.content_margin_left = 12.0; sb_dbg.content_margin_top = 12.0
	_debug_panel.add_theme_stylebox_override("panel", sb_dbg)
	_debug_lbl = RichTextLabel.new()
	_debug_lbl.bbcode_enabled = true
	_debug_lbl.scroll_active  = true
	_debug_lbl.add_theme_font_size_override("normal_font_size", 13)
	_debug_lbl.add_theme_color_override("default_color", Color(0.55, 1.0, 0.55))
	_debug_panel.add_child(_debug_lbl)
	add_child(_debug_panel)

	# ── Point-and-click spot layer ────────────────────────────
	_build_spots_layer()
	_build_tooltip()
	if ResourceLoader.exists(MAGNIFIER_CURSOR):
		_magnifier_tex = load(MAGNIFIER_CURSOR) as Texture2D

	# ── Compass radial navigation ─────────────────────────────
	_build_compass_system()

	# ── Toast label ───────────────────────────────────────────
	_toast_lbl = Label.new()
	_toast_lbl.layout_mode  = 1
	_toast_lbl.anchor_left  = 0.0;  _toast_lbl.anchor_right  = 0.52
	_toast_lbl.anchor_top   = 0.5;  _toast_lbl.anchor_bottom = 0.5
	_toast_lbl.offset_left  = 40.0; _toast_lbl.offset_right  = -40.0
	_toast_lbl.offset_top   = -60.0; _toast_lbl.offset_bottom = 60.0
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.add_theme_font_override("font", _make_font(700))
	_toast_lbl.add_theme_font_size_override("font_size", 28)
	_toast_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
	_toast_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_toast_lbl.add_theme_constant_override("shadow_offset_x", 2)
	_toast_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_toast_lbl.modulate.a    = 0.0
	_toast_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_lbl)

	# Apply content panel layout now (deferred so viewport size is settled)
	_reflow_layout.call_deferred()

# ─────────────────────────────────────────────────────────────
# Layout
# ─────────────────────────────────────────────────────────────

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_reflow_layout()

## Explicitly position and size the content panel from the node's own rect.
## Called deferred after _build_ui() and whenever the window is resized.
func _reflow_layout() -> void:
	if _content_panel == null:
		return
	var sw: float = size.x
	var sh: float = size.y
	if sw == 0.0 or sh == 0.0:
		# Viewport size not yet available; try next frame
		_reflow_layout.call_deferred()
		return
	_content_panel.position = Vector2(sw * BG_AREA_FRACTION, 0.0)
	_content_panel.size     = Vector2(sw * (1.0 - BG_AREA_FRACTION), sh)

# ─────────────────────────────────────────────────────────────
# Compass Radial Menu
# ─────────────────────────────────────────────────────────────

func _build_compass_system() -> void:
	# Full-screen transparent root layer — sits above the content panel.
	_compass_root = Control.new()
	_compass_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_compass_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compass_root.z_index      = 30
	_compass_root.visible      = false
	add_child(_compass_root)

	# Idle / center positions — use actual viewport size so they work at any resolution.
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp == Vector2.ZERO:
		vp = Vector2(1600.0, 900.0)  # fallback for when viewport isn't sized yet
	_compass_idle_pos   = Vector2(vp.x * 0.5 - COMPASS_SIZE * 0.5, vp.y - COMPASS_SIZE - 24.0)
	_compass_center_pos = Vector2(vp.x * 0.5 - COMPASS_SIZE * 0.5, vp.y * 0.5 - COMPASS_SIZE * 0.5)

	# Click-catcher overlay (shown when menu is open; catches outside taps)
	_radial_overlay = Control.new()
	_radial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_radial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_radial_overlay.visible      = false
	_radial_overlay.gui_input.connect(_on_radial_overlay_input)
	_compass_root.add_child(_radial_overlay)

	# Compass icon
	_compass_icon          = TextureRect.new()
	_compass_icon.position = _compass_idle_pos
	_compass_icon.size     = Vector2(COMPASS_SIZE, COMPASS_SIZE)
	_compass_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_compass_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(COMPASS_ICON):
		_compass_icon.texture = load(COMPASS_ICON) as Texture2D
	_compass_root.add_child(_compass_icon)

	# Invisible button covering the compass (for clean click detection)
	_compass_hit              = Button.new()
	_compass_hit.position     = _compass_idle_pos
	_compass_hit.size         = Vector2(COMPASS_SIZE, COMPASS_SIZE)
	_compass_hit.flat         = true
	_compass_hit.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb_empty := StyleBoxEmpty.new()
	for state: String in ["normal","hover","pressed","focus","disabled"]:
		_compass_hit.add_theme_stylebox_override(state, sb_empty)
	_compass_hit.pressed.connect(_on_compass_clicked)
	_compass_root.add_child(_compass_hit)

func _compass_set_visible(show: bool) -> void:
	if _compass_root != null:
		_compass_root.visible = show

func _on_compass_clicked() -> void:
	if _compass_animating:
		return
	if _compass_open:
		_close_compass_menu()
	else:
		_open_compass_menu()

func _on_radial_overlay_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_close_compass_menu()

func _open_compass_menu() -> void:
	if _compass_animating or _compass_open:
		return
	var node: ExplorationNode = ExplorationManager.current_node
	if node == null:
		return
	# Gather only unlocked connections (locked hidden per spec)
	var unlocked: Array = []
	for conn: Variant in node.connections:
		if conn is Dictionary and ExplorationManager.is_connection_unlocked(conn as Dictionary):
			unlocked.append(conn)
	if unlocked.is_empty():
		_show_toast("No paths available.")
		return

	_compass_open      = true
	_compass_animating = true
	SFXManager.play(SFXManager.SFX_MENU)

	# Animate compass icon + hit area to center
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(true)
	tw.tween_property(_compass_icon, "position", _compass_center_pos, 0.28)
	tw.tween_property(_compass_hit,  "position", _compass_center_pos, 0.28)
	await tw.finished
	_compass_animating = false

	# Show overlay to catch outside clicks, raise it below the compass
	_radial_overlay.visible = true
	_radial_overlay.z_index = -1  # behind compass icon but above scene

	# Build and animate radial items
	_spawn_radial_items(unlocked)

func _close_compass_menu(animated: bool = true) -> void:
	if _compass_animating and _compass_open == false:
		return
	_compass_open = false

	# Remove radial items immediately
	for item: Variant in _radial_items:
		if is_instance_valid(item as Node):
			(item as Node).queue_free()
	_radial_items.clear()
	_radial_overlay.visible = false

	if not animated:
		_compass_icon.position = _compass_idle_pos
		_compass_hit.position  = _compass_idle_pos
		return

	_compass_animating = true
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(true)
	tw.tween_property(_compass_icon, "position", _compass_idle_pos, 0.22)
	tw.tween_property(_compass_hit,  "position", _compass_idle_pos, 0.22)
	await tw.finished
	_compass_animating = false

func _spawn_radial_items(unlocked: Array) -> void:
	var n: int      = unlocked.size()
	var screen_cx: float = 800.0
	var screen_cy: float = 450.0

	for i: int in range(n):
		var conn: Dictionary = unlocked[i] as Dictionary
		var label_text: String = str(conn.get("label", "Continue"))

		# Angle: start at top (−90°), spread clockwise
		var angle: float = (-PI * 0.5) + float(i) * (TAU / float(n))
		var item_cx: float = screen_cx + cos(angle) * RADIAL_RADIUS
		var item_cy: float = screen_cy + sin(angle) * RADIAL_RADIUS
		var item_x: float  = item_cx - RADIAL_ITEM_W * 0.5
		var item_y: float  = item_cy - RADIAL_ITEM_H * 0.5

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(RADIAL_ITEM_W, RADIAL_ITEM_H)
		panel.position  = Vector2(item_x, item_y)
		panel.modulate.a = 0.0
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.08, 0.20, 0.94)
		sb.set_border_width_all(1)
		sb.border_color = Color(0.45, 0.70, 1.0, 0.85)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 12.0; sb.content_margin_right  = 12.0
		sb.content_margin_top  = 8.0;  sb.content_margin_bottom = 8.0
		panel.add_theme_stylebox_override("panel", sb)

		var lbl := Label.new()
		lbl.text = label_text
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
		lbl.add_theme_font_override("font", _make_font(500))
		panel.add_child(lbl)

		# Make the whole panel clickable
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		var target_id: String = str(conn.get("target", ""))
		panel.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton:
				var mb: InputEventMouseButton = ev as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					_on_radial_item_selected(target_id))

		# Hover highlight
		panel.mouse_entered.connect(func() -> void:
			sb.bg_color = Color(0.10, 0.22, 0.48, 0.97)
			sb.border_color = Color(0.65, 0.88, 1.0, 1.0))
		panel.mouse_exited.connect(func() -> void:
			sb.bg_color = Color(0.04, 0.08, 0.20, 0.94)
			sb.border_color = Color(0.45, 0.70, 1.0, 0.85))

		_compass_root.add_child(panel)
		_radial_items.append(panel)

		# Fade in with slight stagger
		var fade_tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fade_tw.tween_interval(float(i) * 0.04)
		fade_tw.tween_property(panel, "modulate:a", 1.0, 0.18)

func _on_radial_item_selected(target_id: String) -> void:
	if target_id.is_empty():
		return
	SFXManager.play(SFXManager.SFX_MENU)
	_close_compass_menu()
	ExplorationManager.navigate_to(target_id)

# ─────────────────────────────────────────────────────────────
# Node Rendering
# ─────────────────────────────────────────────────────────────

func _on_node_entered(node: ExplorationNode) -> void:
	_close_compass_menu(false)
	_refresh_node(node)

func _refresh_node(node: ExplorationNode) -> void:
	_exit_pending   = false
	_battle_pending = false
	_close_item_use_panel()

	# Background
	if not node.background.is_empty() and node.background != _current_bg_path:
		_current_bg_path = node.background
		if ResourceLoader.exists(node.background):
			_bg_rect.texture  = load(node.background) as Texture2D
			_bg_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			push_warning("ExplorationPlayer: bg '%s' not found." % node.background)

	# Music
	if not node.music.is_empty() and ResourceLoader.exists(node.music):
		BGMManager.play_path(node.music, 1.0, 0.5, 100.0, BGMManager.CONTEXT_VN)

	# Type badge
	match node.node_type:
		ExplorationNode.NodeType.STORY:
			_type_badge_lbl.text = "[ STORY ]"
			_type_badge_lbl.add_theme_color_override("font_color", Color(0.55, 0.80, 1.0))
		ExplorationNode.NodeType.BATTLE:
			_type_badge_lbl.text = "[ BATTLE ]"
			_type_badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.50, 0.45))
		ExplorationNode.NodeType.REWARD:
			_type_badge_lbl.text = "[ REWARD ]"
			_type_badge_lbl.add_theme_color_override("font_color", Color(0.60, 1.0, 0.55))
		ExplorationNode.NodeType.EXIT:
			_type_badge_lbl.text = "[ EXIT ]"
			_type_badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
		ExplorationNode.NodeType.HUB:
			_type_badge_lbl.text = "[ HUB ]"
			_type_badge_lbl.add_theme_color_override("font_color", Color(0.75, 0.60, 1.0))
		_:
			_type_badge_lbl.text = ""

	# Title + description
	_title_lbl.text = node.title
	_desc_lbl.text  = ""
	_desc_lbl.append_text(node.description)

	# Back button
	_back_btn.visible = ExplorationManager.can_go_back()

	# Inventory
	_rebuild_inventory_slots()

	# Point-and-click hotspots for this node
	_rebuild_spots(node)

	# Node-type routing: BATTLE/EXIT get inline action buttons; all others use compass.
	_close_compass_menu(false)
	match node.node_type:
		ExplorationNode.NodeType.BATTLE:
			_choices_vbox.visible = true
			_compass_set_visible(false)
			_show_battle_prompt(node)
		ExplorationNode.NodeType.EXIT:
			_choices_vbox.visible = true
			_compass_set_visible(false)
			_show_exit_prompt()
		ExplorationNode.NodeType.STORY:
			_choices_vbox.visible = false
			_compass_set_visible(false)   # hidden while VN plays; restored in _on_vn_finished
			if not node.vn_scene.is_empty():
				_play_vn(node.vn_scene, func() -> void: _on_vn_finished(node))
			else:
				_compass_set_visible(true)
		_:
			_choices_vbox.visible = false
			_compass_set_visible(true)


# ─────────────────────────────────────────────────────────────
# Visual Novel Integration
# ─────────────────────────────────────────────────────────────

func _play_vn(path: String, on_done: Callable) -> void:
	if _vn_playing:
		return
	if not ResourceLoader.exists(path):
		push_warning("ExplorationPlayer: VN scene '%s' not found — skipping." % path)
		on_done.call()
		return
	_vn_playing = true
	_compass_set_visible(false)   # disable compass while VN is active
	var vn: Node = VN_PLAYER_SCENE.instantiate()
	add_child(vn)
	vn.play_scene(path, func() -> void:
		_vn_playing = false
		on_done.call())

func _on_vn_finished(node: ExplorationNode) -> void:
	# VN done — restore compass so player can navigate
	_compass_set_visible(true)

# ─────────────────────────────────────────────────────────────
# Battle Integration
# ─────────────────────────────────────────────────────────────

func _show_battle_prompt(node: ExplorationNode) -> void:
	if _battle_pending:
		return
	_battle_pending = true
	for child: Node in _choices_vbox.get_children():
		child.queue_free()

	var btn := Button.new()
	btn.text = "  Begin Battle"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	var captured_node: ExplorationNode = node
	btn.pressed.connect(func() -> void:
		SFXManager.play(SFXManager.SFX_MENU)
		ExplorationManager.start_battle_for_node(captured_node))
	_choices_vbox.add_child(btn)

func _handle_post_battle_result() -> void:
	var result: Dictionary = ExplorationManager.pending_battle_result
	ExplorationManager.pending_battle_result = {}
	var won: bool    = bool(result.get("won", false))
	var node_id: String = str(result.get("node_id", ""))
	# Set a session variable so graph conditions can gate progress on battle outcome.
	# Pattern: "battle_<node_id>_won" = "true" | "false"
	if not node_id.is_empty():
		ExplorationManager.set_var("battle_%s_won" % node_id, "true" if won else "false")
	var msg: String = "Victory!" if won else "Defeated..."
	_show_toast(msg)
	var node: ExplorationNode = ExplorationManager.current_node
	if node != null:
		_refresh_node(node)
	else:
		_show_no_session_error()

# ─────────────────────────────────────────────────────────────
# Exit Integration
# ─────────────────────────────────────────────────────────────

func _show_exit_prompt() -> void:
	if _exit_pending:
		return
	_exit_pending = true
	for child: Node in _choices_vbox.get_children():
		child.queue_free()

	var btn := Button.new()
	btn.text = "  Leave This Place"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
	btn.pressed.connect(_on_exit_confirmed)
	_choices_vbox.add_child(btn)

func _on_exit_confirmed() -> void:
	SFXManager.play(SFXManager.SFX_MENU)
	ExplorationManager.end_session(true)
	var dest: String = ExplorationManager.return_scene
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file(dest))

# ─────────────────────────────────────────────────────────────
# UI helpers
# ─────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	SFXManager.play(SFXManager.SFX_CANCEL)
	ExplorationManager.go_back()

func _on_inventory_changed(_items: Array) -> void:
	_rebuild_inventory_slots()

func _rebuild_inventory_slots() -> void:
	if _inventory_hbox == null:
		return
	# Clear old slots and the floating use-panel if open
	for child: Node in _inventory_hbox.get_children():
		child.queue_free()
	_close_item_use_panel()

	var inv: Array = ExplorationManager.get_inventory()
	_inventory_panel.visible = not inv.is_empty()
	if inv.is_empty():
		return

	# Header label
	var hdr := Label.new()
	hdr.text = "Items:"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(0.50, 0.78, 0.55))
	_inventory_hbox.add_child(hdr)

	# One button per unique item name (shows count if >1)
	var seen: Dictionary = {}
	for raw_item: Variant in inv:
		var item: String = str(raw_item)
		seen[item] = int(seen.get(item, 0)) + 1
	for item_name: Variant in seen.keys():
		var count: int = int(seen[item_name])
		var label_text: String = str(item_name) + (" ×%d" % count if count > 1 else "")
		var slot_btn := Button.new()
		slot_btn.text = label_text
		slot_btn.add_theme_font_size_override("font_size", 14)
		slot_btn.add_theme_color_override("font_color", Color(0.70, 0.95, 0.72))
		var sb_slot := StyleBoxFlat.new()
		sb_slot.bg_color = Color(0.07, 0.18, 0.10, 0.90)
		sb_slot.set_border_width_all(1)
		sb_slot.border_color = Color(0.35, 0.75, 0.45, 0.60)
		sb_slot.set_corner_radius_all(4)
		sb_slot.content_margin_left = 8.0;  sb_slot.content_margin_right  = 8.0
		sb_slot.content_margin_top  = 3.0;  sb_slot.content_margin_bottom = 3.0
		slot_btn.add_theme_stylebox_override("normal", sb_slot)
		var sb_h := sb_slot.duplicate() as StyleBoxFlat
		sb_h.bg_color = Color(0.10, 0.28, 0.16, 0.95)
		slot_btn.add_theme_stylebox_override("hover", sb_h)
		var captured_item: String = str(item_name)
		slot_btn.pressed.connect(func() -> void: _on_item_slot_pressed(captured_item, slot_btn))
		_inventory_hbox.add_child(slot_btn)

func _on_item_slot_pressed(item_name: String, from_btn: Button) -> void:
	# If a use-panel is already open for this item, close it (toggle)
	if _item_use_panel != null and _item_use_panel.get_meta("item", "") == item_name:
		_close_item_use_panel()
		return
	_close_item_use_panel()

	var node: ExplorationNode = ExplorationManager.current_node
	if node == null:
		return

	# Find usable interactions for this item at the current node
	var interactions: Array = []
	for ui: Variant in node.usable_items:
		if ui is Dictionary:
			var uid: Dictionary = ui as Dictionary
			if str(uid.get("item", "")) == item_name:
				interactions.append(uid)

	if interactions.is_empty():
		_show_toast("Can't use %s here." % item_name)
		return

	# Build a small floating panel anchored near the from_btn
	_item_use_panel = PanelContainer.new()
	_item_use_panel.set_meta("item", item_name)
	_item_use_panel.z_index = 50
	var sb_up := StyleBoxFlat.new()
	sb_up.bg_color = Color(0.05, 0.12, 0.08, 0.96)
	sb_up.set_border_width_all(1)
	sb_up.border_color = Color(0.35, 0.85, 0.50, 0.80)
	sb_up.set_corner_radius_all(6)
	sb_up.content_margin_left = 10.0; sb_up.content_margin_right  = 10.0
	sb_up.content_margin_top  = 8.0;  sb_up.content_margin_bottom = 8.0
	_item_use_panel.add_theme_stylebox_override("panel", sb_up)

	var up_vbox := VBoxContainer.new()
	up_vbox.add_theme_constant_override("separation", 6)
	_item_use_panel.add_child(up_vbox)

	var up_title := Label.new()
	up_title.text = item_name.capitalize()
	up_title.add_theme_font_size_override("font_size", 15)
	up_title.add_theme_color_override("font_color", Color(0.70, 0.95, 0.72))
	up_vbox.add_child(up_title)

	for interaction: Variant in interactions:
		var idict: Dictionary = interaction as Dictionary
		var btn_label: String = str(idict.get("label", "Use"))
		var use_btn := Button.new()
		use_btn.text = "▶  " + btn_label
		use_btn.add_theme_font_size_override("font_size", 16)
		use_btn.add_theme_color_override("font_color", Color(0.88, 1.0, 0.90))
		var captured_idict: Dictionary = idict
		var captured_item: String = item_name
		use_btn.pressed.connect(func() -> void:
			_close_item_use_panel()
			_execute_item_use(captured_item, captured_idict))
		up_vbox.add_child(use_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_size_override("font_size", 14)
	cancel_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
	cancel_btn.pressed.connect(_close_item_use_panel)
	up_vbox.add_child(cancel_btn)

	# Position: just above the inventory panel (bottom-right area)
	_item_use_panel.layout_mode = 1
	_item_use_panel.anchor_right  = 1.0; _item_use_panel.anchor_left   = 1.0
	_item_use_panel.anchor_bottom = 1.0; _item_use_panel.anchor_top    = 1.0
	_item_use_panel.offset_right  = -12.0
	_item_use_panel.offset_bottom = -60.0
	add_child(_item_use_panel)

func _close_item_use_panel() -> void:
	if _item_use_panel != null:
		_item_use_panel.queue_free()
		_item_use_panel = null

func _execute_item_use(item_name: String, idict: Dictionary) -> void:
	SFXManager.play(SFXManager.SFX_MENU)
	var consume: bool    = bool(idict.get("consume", false))
	var vn_path: String  = str(idict.get("vn_scene", ""))
	if consume:
		ExplorationManager.remove_item(item_name)
	if not vn_path.is_empty():
		_play_vn(vn_path, func() -> void:
			var node: ExplorationNode = ExplorationManager.current_node
			if node != null:
				_compass_set_visible(true)
				_refresh_node(node))
	else:
		var node: ExplorationNode = ExplorationManager.current_node
		if node != null:
			_refresh_node(node)

func _show_toast(text: String) -> void:
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_lbl.text      = text
	_toast_lbl.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(_toast_lbl, "modulate:a", 0.0, 0.8)

func _show_no_session_error() -> void:
	_title_lbl.text = "No Exploration Active"
	_desc_lbl.text  = "ExplorationManager has no active session.\nReturn to the main menu."
	for child: Node in _choices_vbox.get_children():
		child.queue_free()
	var btn := Button.new()
	btn.text = "Return to Main Menu"
	btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	_choices_vbox.add_child(btn)

# ─────────────────────────────────────────────────────────────
# Point-and-click hotspots
# ─────────────────────────────────────────────────────────────

func _build_spots_layer() -> void:
	_spots_layer = Control.new()
	_spots_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_spots_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spots_layer.z_index      = 5  # above bg, below compass (30)
	add_child(_spots_layer)

func _build_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible      = false
	_tooltip_panel.z_index      = 80
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.12, 0.20, 0.92)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.35, 0.90, 1.0, 0.85)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 12.0; sb.content_margin_right  = 12.0
	sb.content_margin_top  =  6.0; sb.content_margin_bottom =  6.0
	_tooltip_panel.add_theme_stylebox_override("panel", sb)
	_tooltip_lbl = Label.new()
	_tooltip_lbl.add_theme_font_size_override("font_size", 16)
	_tooltip_lbl.add_theme_color_override("font_color", Color(0.80, 0.90, 0.95))
	_tooltip_panel.add_child(_tooltip_lbl)
	add_child(_tooltip_panel)

func _rebuild_spots(node: ExplorationNode) -> void:
	if _spots_layer == null:
		return
	for child: Node in _spots_layer.get_children():
		child.queue_free()
	_on_spot_hover_exit()   # ensure cursor + tooltip reset when node changes
	if node.clickable_spots.is_empty():
		return
	var vp: Vector2 = get_viewport_rect().size
	var bg_w: float = vp.x * BG_AREA_FRACTION
	var bg_h: float = vp.y
	for spot_var: Variant in node.clickable_spots:
		if spot_var is Dictionary:
			_spawn_spot(spot_var as Dictionary, bg_w, bg_h)

func _spawn_spot(spot: Dictionary, bg_w: float, bg_h: float) -> void:
	var xn: float         = float(spot.get("x_norm",  0.5))
	var yn: float         = float(spot.get("y_norm",  0.5))
	var wn: float         = float(spot.get("w_norm",  0.08))
	var hn: float         = float(spot.get("h_norm",  0.08))
	var icon_path: String = str(spot.get("icon",     ""))
	var vn_path: String   = str(spot.get("vn_scene", ""))
	var tip: String       = str(spot.get("tooltip",  ""))

	var pw: float = wn * bg_w
	var ph: float = hn * bg_h
	var hit := Control.new()
	hit.position     = Vector2(xn * bg_w - pw * 0.5, yn * bg_h - ph * 0.5)
	hit.size         = Vector2(pw, ph)
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	_spots_layer.add_child(hit)

	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var icon_tr := TextureRect.new()
		icon_tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		icon_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_tr.texture      = load(icon_path) as Texture2D
		icon_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hit.add_child(icon_tr)

	var cap_tip: String = tip
	var cap_vn: String  = vn_path
	hit.mouse_entered.connect(func() -> void: _on_spot_hover_enter(cap_tip))
	hit.mouse_exited.connect(func() -> void:  _on_spot_hover_exit())
	hit.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_on_spot_clicked(cap_vn))

func _on_spot_hover_enter(tooltip_text: String) -> void:
	_hovering_spot = true
	if _magnifier_tex != null:
		Input.set_custom_mouse_cursor(_magnifier_tex, Input.CURSOR_ARROW, Vector2(8.0, 8.0))
	if not tooltip_text.is_empty() and _tooltip_panel != null:
		_tooltip_lbl.text      = tooltip_text
		_tooltip_panel.visible = true

func _on_spot_hover_exit() -> void:
	_hovering_spot = false
	Input.set_custom_mouse_cursor(null)
	_hide_tooltip()

func _hide_tooltip() -> void:
	if _tooltip_panel != null:
		_tooltip_panel.visible = false

func _on_spot_clicked(vn_path: String) -> void:
	if _vn_playing or vn_path.is_empty():
		return
	_on_spot_hover_exit()   # restore cursor before VN takes over
	SFXManager.play(SFXManager.SFX_MENU)
	_play_vn(vn_path, func() -> void:
		var node: ExplorationNode = ExplorationManager.current_node
		if node != null:
			_compass_set_visible(true))

func _process(_delta: float) -> void:
	if _tooltip_panel != null and _tooltip_panel.visible:
		var mp: Vector2 = get_local_mouse_position()
		var vp: Vector2 = get_viewport_rect().size
		var tp: Vector2 = _tooltip_panel.size
		_tooltip_panel.position = Vector2(
			minf(mp.x + 16.0, vp.x - tp.x - 4.0),
			minf(mp.y + 16.0, vp.y - tp.y - 4.0))

func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null)

# ─────────────────────────────────────────────────────────────
# Debug overlay
# ─────────────────────────────────────────────────────────────

func _toggle_debug() -> void:
	_debug_panel.visible = not _debug_panel.visible
	if _debug_panel.visible:
		_debug_lbl.text = ""
		_debug_lbl.append_text("[color=#44ff44]" + ExplorationManager.debug_dump() + "[/color]")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		if (event as InputEventKey).keycode == KEY_F3:
			_toggle_debug()
			get_viewport().set_input_as_handled()
