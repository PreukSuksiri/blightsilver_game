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
const FONT_PATH: String        = "res://assets/fonts/Chivo-VariableFont_wght.ttf"
const COMPASS_ICON: String     = "res://assets/textures/ui/decorations/ui_icon_compass.png"
const SETTING_ICON: String     = "res://assets/textures/ui/decorations/ui_icon_exploration_setting.png"
const INVENTORY_ICON: String   = "res://assets/textures/ui/decorations/ui_exploration_inventory.png"
const CHAT_ICON: String        = "res://assets/textures/ui/decorations/ui_icon_exploration_chat.png"
const INFO_ICON: String        = "res://assets/textures/ui/decorations/ui_icon_exploration_info.png"
const DEFAULT_CURSOR: String   = "res://assets/textures/ui/decorations/ui_cursor.png"
const MAGNIFIER_CURSOR: String = "res://assets/textures/ui/decorations/ui_icon_magnifier.png"
const FINGER_CURSOR: String    = "res://assets/textures/ui/decorations/ui_cursor_finger.png"
const COMPASS_SIZE: float  = 110.0  # icon width/height in pixels
const RADIAL_RADIUS: float = 210.0  # distance from center to item midpoint
const RADIAL_ITEM_W: float = 180.0  # radial button width
const RADIAL_ITEM_H: float = 54.0   # radial button height
const BG_AREA_FRACTION: float = 0.80  # fraction of viewport width used by the background area
const ICON_SPACING: float  = 180.0  # horizontal gap between compass center and side icon centers
const ITEMS_PER_PAGE: int  = 7      # max items shown per inventory radial page

# ── UI references (all built in _build_ui) ────────────────────────────────
var _bg_rect: TextureRect          = null   # background image
var _bg_base: ColorRect            = null   # solid-colour fallback behind bg
var _title_lbl: Label              = null   # node title
var _type_badge_lbl: Label         = null   # coloured node-type label
var _desc_lbl: RichTextLabel       = null   # node description
var _choices_vbox: VBoxContainer   = null   # navigation choice buttons
var _back_btn: Button              = null   # go-back button
var _toast_lbl: Label              = null   # temporary message overlay
var _toast_tween: Tween            = null
var _debug_panel: PanelContainer   = null   # F3 debug overlay
var _debug_lbl: RichTextLabel      = null
var _content_panel: Panel          = null   # right-side content area (layout_mode=0, sized by _reflow_layout)
var _who_section: VBoxContainer    = null   # "Who is here" section inside the info panel
var _who_grid: GridContainer       = null   # 2-column grid of character thumbnails + names
var _nav_fade_rect: ColorRect      = null   # full-screen black rect for node-transition fade
var _nav_fade_tween: Tween         = null

# ── Compass radial menu ───────────────────────────────────────────────────
var _compass_root: Control        = null   # full-screen layer holding all 3 icons
var _compass_icon: TextureRect    = null   # the compass texture
var _compass_hit: Button          = null   # invisible click area over the icon
var _radial_overlay: Control      = null   # full-screen click-catcher (outside dismiss)
var _radial_items: Array          = []     # currently shown radial PanelContainers (compass)
var _compass_open: bool           = false
var _compass_animating: bool      = false
var _compass_idle_pos: Vector2    = Vector2.ZERO
var _compass_center_pos: Vector2  = Vector2.ZERO

# ── Setting icon ─────────────────────────────────────────────────────────
var _setting_icon: TextureRect    = null
var _setting_hit: Button          = null
var _setting_idle_pos: Vector2    = Vector2.ZERO
var _setting_open: bool           = false
var _setting_animating: bool      = false
var _setting_radial_items: Array  = []

# ── Inventory icon ────────────────────────────────────────────────────────
var _inv_icon: TextureRect        = null
var _inv_hit: Button              = null
var _inv_idle_pos: Vector2        = Vector2.ZERO
var _inv_open: bool               = false
var _inv_animating: bool          = false
var _inv_radial_items: Array      = []
var _inv_page: int                = 0
var _inv_empty_tween: Tween       = null
var _inv_empty_lbl: Label         = null

# ── Chat icon ────────────────────────────────────────────────────────────────
var _chat_icon: TextureRect   = null
var _chat_hit: Button         = null
var _chat_idle_pos: Vector2   = Vector2.ZERO
var _chat_open: bool          = false
var _chat_animating: bool     = false
var _chat_radial_items: Array = []
var _chat_empty_tween: Tween  = null
var _chat_empty_lbl: Label    = null

# ── Info icon ────────────────────────────────────────────────────────────────
var _info_icon: TextureRect                  = null
var _info_hit: Button                        = null
var _info_idle_pos: Vector2                  = Vector2.ZERO
var _info_open: bool                         = false
var _info_panel_tween: Tween                 = null
var _info_auto_dismiss_timer: SceneTreeTimer = null
var _info_on_close_cb: Callable              = Callable()
var _info_panel_hovered: bool                = false   # polled each frame; guards auto-dismiss

# ── Item preview overlay ──────────────────────────────────────────────────
var _item_preview: Control        = null

# ── Cursors ───────────────────────────────────────────────────────────────
var _default_tex: Texture2D       = null
var _finger_tex: Texture2D        = null

# ── Internal state ────────────────────────────────────────────────────────
var _current_bg_path: String = ""
var _vn_playing: bool        = false
var _battle_pending: bool    = false
var _exit_pending: bool      = false

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
	_bg_rect.layout_mode  = 0
	_bg_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
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
	content.visible = false
	content.mouse_entered.connect(_on_info_panel_mouse_entered)
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

	# Type badge (hidden — kept for signal/logic references)
	_type_badge_lbl = Label.new()
	_type_badge_lbl.add_theme_font_size_override("font_size", 14)
	_type_badge_lbl.visible = false
	vbox.add_child(_type_badge_lbl)

	# Title (hidden)
	_title_lbl = Label.new()
	_title_lbl.add_theme_font_override("font", _make_font(700))
	_title_lbl.add_theme_font_size_override("font_size", 32)
	_title_lbl.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 1.0))
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_lbl.visible = false
	vbox.add_child(_title_lbl)

	# Description (hidden)
	_desc_lbl = RichTextLabel.new()
	_desc_lbl.bbcode_enabled = true
	_desc_lbl.scroll_active  = false
	_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desc_lbl.add_theme_font_override("normal_font", _make_font(400))
	_desc_lbl.add_theme_font_size_override("normal_font_size", 22)
	_desc_lbl.add_theme_color_override("default_color", Color(0.82, 0.90, 1.0, 0.95))
	_desc_lbl.visible = false
	vbox.add_child(_desc_lbl)

	# Choices vbox — only used by BATTLE and EXIT nodes (special action buttons).
	# Navigation choices are handled by the radial compass menu instead.
	_choices_vbox = VBoxContainer.new()
	_choices_vbox.add_theme_constant_override("separation", 10)
	_choices_vbox.visible = false
	vbox.add_child(_choices_vbox)

	# "Who is here" section (hidden until populated)
	_who_section = VBoxContainer.new()
	_who_section.add_theme_constant_override("separation", 8)
	_who_section.visible = false
	vbox.add_child(_who_section)
	var who_hdr := Label.new()
	who_hdr.text = "Who is Here"
	who_hdr.add_theme_font_override("font", _make_font(700))
	who_hdr.add_theme_font_size_override("font_size", 32)
	who_hdr.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 1.0))
	_who_section.add_child(who_hdr)
	var who_hdr_spacer := Control.new()
	who_hdr_spacer.custom_minimum_size = Vector2(0, 8)
	_who_section.add_child(who_hdr_spacer)
	_who_grid = GridContainer.new()
	_who_grid.columns = 2
	_who_grid.add_theme_constant_override("h_separation", 10)
	_who_grid.add_theme_constant_override("v_separation", 10)
	_who_section.add_child(_who_grid)

	# Back button
	_back_btn = Button.new()
	_back_btn.text = "← Go Back"
	_back_btn.add_theme_font_size_override("font_size", 16)
	_back_btn.add_theme_color_override("font_color", Color(0.55, 0.78, 0.95))
	_back_btn.pressed.connect(_on_back_pressed)
	_back_btn.mouse_entered.connect(func() -> void: _set_finger_cursor(true))
	_back_btn.mouse_exited.connect(func() -> void: _set_finger_cursor(false))
	vbox.add_child(_back_btn)

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

	# ── Navigation fade overlay ────────────────────────────────
	# Sits above all other UI; alpha starts at 0 (invisible).
	_nav_fade_rect = ColorRect.new()
	_nav_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nav_fade_rect.color        = Color(0.0, 0.0, 0.0, 1.0)
	_nav_fade_rect.modulate.a   = 0.0
	_nav_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nav_fade_rect.z_index      = 90   # below VNPlayer (100) but above everything else
	add_child(_nav_fade_rect)

	# Apply content panel layout now (deferred so viewport size is settled)
	_reflow_layout.call_deferred()

# ─────────────────────────────────────────────────────────────
# Layout
# ─────────────────────────────────────────────────────────────

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_reflow_layout()

## Explicitly position and size the content panel from the viewport rect.
## Called deferred after _build_ui() and whenever the window is resized.
func _reflow_layout() -> void:
	if _content_panel == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var sw: float = vp_size.x
	var sh: float = vp_size.y
	if sw == 0.0 or sh == 0.0:
		return
	_bg_rect.position = Vector2.ZERO
	_bg_rect.size      = Vector2(sw, sh)
	_content_panel.position = Vector2(sw * BG_AREA_FRACTION, 0.0)
	_content_panel.size     = Vector2(sw * (1.0 - BG_AREA_FRACTION), sh)

# ─────────────────────────────────────────────────────────────
# Compass Radial Menu
# ─────────────────────────────────────────────────────────────

func _build_compass_system() -> void:
	# Root layer — always visible, holds all three bottom icons.
	_compass_root = Control.new()
	_compass_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_compass_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compass_root.z_index      = 30
	_compass_root.visible      = true
	add_child(_compass_root)

	# Viewport size for positioning.
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp == Vector2.ZERO:
		vp = Vector2(1600.0, 900.0)
	var bottom_y: float = vp.y - COMPASS_SIZE - 24.0
	var center_y: float = vp.y * 0.5 - COMPASS_SIZE * 0.5

	# ── Compass (center) ─────────────────────────────────────
	_compass_idle_pos   = Vector2(vp.x * 0.5 - COMPASS_SIZE * 0.5, bottom_y)
	_compass_center_pos = Vector2(vp.x * 0.5 - COMPASS_SIZE * 0.5, center_y)

	# Full-screen click-catcher — direct child of ExplorationPlayer so it is NOT inside
	# the MOUSE_FILTER_IGNORE compass_root. z_index=25 puts it above scene (0) but below
	# the icons layer (30), so radial items and icon hits are still reachable.
	_radial_overlay = Control.new()
	_radial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_radial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_radial_overlay.z_index      = 25
	_radial_overlay.visible      = false
	add_child(_radial_overlay)   # ← parent is ExplorationPlayer, not compass_root

	_compass_icon          = TextureRect.new()
	_compass_icon.position = _compass_idle_pos
	_compass_icon.size     = Vector2(COMPASS_SIZE, COMPASS_SIZE)
	_compass_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_compass_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(COMPASS_ICON):
		_compass_icon.texture = load(COMPASS_ICON) as Texture2D
	_compass_root.add_child(_compass_icon)

	_compass_hit          = _make_icon_hit_button(_compass_idle_pos)
	_compass_hit.pressed.connect(_on_compass_clicked)
	_compass_hit.mouse_entered.connect(func() -> void: _set_finger_cursor(true))
	_compass_hit.mouse_exited.connect(func() -> void: _set_finger_cursor(false))
	_compass_root.add_child(_compass_hit)

	# ── Setting icon (far right, +2×spacing) ────────────────
	_setting_idle_pos = Vector2(vp.x * 0.5 + 2.0 * ICON_SPACING - COMPASS_SIZE * 0.5, bottom_y)

	_setting_icon          = TextureRect.new()
	_setting_icon.position = _setting_idle_pos
	_setting_icon.size     = Vector2(COMPASS_SIZE, COMPASS_SIZE)
	_setting_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_setting_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(SETTING_ICON):
		_setting_icon.texture = load(SETTING_ICON) as Texture2D
	_compass_root.add_child(_setting_icon)

	_setting_hit = _make_icon_hit_button(_setting_idle_pos)
	_setting_hit.pressed.connect(_on_setting_clicked)
	_setting_hit.mouse_entered.connect(func() -> void: _set_finger_cursor(true))
	_setting_hit.mouse_exited.connect(func() -> void: _set_finger_cursor(false))
	_compass_root.add_child(_setting_hit)

	# ── Info icon (+1×spacing) ────────────────────────────────
	_info_idle_pos = Vector2(vp.x * 0.5 + ICON_SPACING - COMPASS_SIZE * 0.5, bottom_y)

	_info_icon          = TextureRect.new()
	_info_icon.position = _info_idle_pos
	_info_icon.size     = Vector2(COMPASS_SIZE, COMPASS_SIZE)
	_info_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_info_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(INFO_ICON):
		_info_icon.texture = load(INFO_ICON) as Texture2D
	_compass_root.add_child(_info_icon)

	_info_hit = _make_icon_hit_button(_info_idle_pos)
	_info_hit.pressed.connect(_on_info_clicked)
	_info_hit.mouse_entered.connect(func() -> void: _set_finger_cursor(true))
	_info_hit.mouse_exited.connect(func() -> void: _set_finger_cursor(false))
	_compass_root.add_child(_info_hit)

	# ── Inventory icon (far left, −2×spacing) ────────────────
	_inv_idle_pos = Vector2(vp.x * 0.5 - 2.0 * ICON_SPACING - COMPASS_SIZE * 0.5, bottom_y)

	_inv_icon          = TextureRect.new()
	_inv_icon.position = _inv_idle_pos
	_inv_icon.size     = Vector2(COMPASS_SIZE, COMPASS_SIZE)
	_inv_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_inv_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(INVENTORY_ICON):
		_inv_icon.texture = load(INVENTORY_ICON) as Texture2D
	_compass_root.add_child(_inv_icon)

	_inv_hit = _make_icon_hit_button(_inv_idle_pos)
	_inv_hit.pressed.connect(_on_inventory_clicked)
	_inv_hit.mouse_entered.connect(func() -> void: _set_finger_cursor(true))
	_inv_hit.mouse_exited.connect(func() -> void: _set_finger_cursor(false))
	_compass_root.add_child(_inv_hit)

	# ── Chat icon (−1×spacing) ────────────────────────────────
	_chat_idle_pos = Vector2(vp.x * 0.5 - ICON_SPACING - COMPASS_SIZE * 0.5, bottom_y)

	_chat_icon          = TextureRect.new()
	_chat_icon.position = _chat_idle_pos
	_chat_icon.size     = Vector2(COMPASS_SIZE, COMPASS_SIZE)
	_chat_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_chat_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(CHAT_ICON):
		_chat_icon.texture = load(CHAT_ICON) as Texture2D
	_compass_root.add_child(_chat_icon)

	_chat_hit = _make_icon_hit_button(_chat_idle_pos)
	_chat_hit.pressed.connect(_on_chat_clicked)
	_chat_hit.mouse_entered.connect(func() -> void: _set_finger_cursor(true))
	_chat_hit.mouse_exited.connect(func() -> void: _set_finger_cursor(false))
	_compass_root.add_child(_chat_hit)

	# Empty-chat overlay label
	_chat_empty_lbl = Label.new()
	_chat_empty_lbl.layout_mode = 0
	var chat_lbl_w: float = COMPASS_SIZE + 120.0
	_chat_empty_lbl.position = Vector2(
		_chat_idle_pos.x + COMPASS_SIZE * 0.5 - chat_lbl_w * 0.5,
		_chat_idle_pos.y - 36.0)
	_chat_empty_lbl.size = Vector2(chat_lbl_w, 30.0)
	_chat_empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chat_empty_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_chat_empty_lbl.add_theme_font_size_override("font_size", 16)
	_chat_empty_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_chat_empty_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_chat_empty_lbl.add_theme_constant_override("shadow_offset_x", 2)
	_chat_empty_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_chat_empty_lbl.modulate.a  = 0.0
	_chat_empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compass_root.add_child(_chat_empty_lbl)

	# Empty-inventory overlay label — positioned directly over the inventory icon
	_inv_empty_lbl = Label.new()
	_inv_empty_lbl.layout_mode = 0   # manual position
	var lbl_w: float = COMPASS_SIZE + 120.0
	_inv_empty_lbl.position = Vector2(
		_inv_idle_pos.x + COMPASS_SIZE * 0.5 - lbl_w * 0.5,
		_inv_idle_pos.y - 36.0)
	_inv_empty_lbl.size = Vector2(lbl_w, 30.0)
	_inv_empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inv_empty_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_inv_empty_lbl.add_theme_font_size_override("font_size", 16)
	_inv_empty_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_inv_empty_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_inv_empty_lbl.add_theme_constant_override("shadow_offset_x", 2)
	_inv_empty_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_inv_empty_lbl.modulate.a  = 0.0
	_inv_empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compass_root.add_child(_inv_empty_lbl)

	# Load cursors — resize to 64×64 at runtime so no separate import file is needed.
	_default_tex = _load_cursor_tex(DEFAULT_CURSOR)
	_finger_tex  = _load_cursor_tex(FINGER_CURSOR)
	# Apply default cursor immediately for the exploration scene
	Input.set_custom_mouse_cursor(_default_tex, Input.CURSOR_ARROW, Vector2(4.0, 4.0))

## Load an image from res:// and resize it to 64×64 for use as a custom cursor.
## Works on unimported files too (reads raw bytes via Image.load_from_file).
func _load_cursor_tex(path: String) -> ImageTexture:
	var img := Image.new()
	var global: String = ProjectSettings.globalize_path(path)
	var err: int = img.load(global)
	if err != OK:
		push_warning("ExplorationPlayer: could not load cursor '%s' (err %d)" % [path, err])
		return null
	img.resize(64, 64, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)

## Build an invisible full-size hit button for an icon at given position.
func _make_icon_hit_button(pos: Vector2) -> Button:
	var btn := Button.new()
	btn.position     = pos
	btn.size         = Vector2(COMPASS_SIZE, COMPASS_SIZE)
	btn.flat         = true
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxEmpty.new()
	for state: String in ["normal","hover","pressed","focus","disabled"]:
		btn.add_theme_stylebox_override(state, sb)
	return btn

func _set_finger_cursor(on: bool) -> void:
	if on and _finger_tex != null:
		Input.set_custom_mouse_cursor(_finger_tex, Input.CURSOR_ARROW, Vector2(12.0, 4.0))
	elif not on and not _hovering_spot:
		Input.set_custom_mouse_cursor(_default_tex, Input.CURSOR_ARROW, Vector2(4.0, 4.0))

## Returns true if the mouse is currently over any interactive element that warrants a finger cursor.
func _mouse_over_interactive() -> bool:
	if _hovering_spot:
		return false  # hotspot handles its own cursor
	var mp: Vector2 = get_global_mouse_position()
	# Icon hit buttons (always relevant)
	var hits: Array = [_compass_hit, _setting_hit, _inv_hit, _chat_hit, _info_hit]
	for h: Variant in hits:
		if h is Control and (h as Control).visible:
			var c: Control = h as Control
			if Rect2(c.global_position, c.size).has_point(mp):
				return true
	# Back / Dismiss button
	if _back_btn != null and _back_btn.visible:
		if Rect2(_back_btn.global_position, _back_btn.size).has_point(mp):
			return true
	# Radial panels
	var all_panels: Array = []
	all_panels.append_array(_radial_items)
	all_panels.append_array(_setting_radial_items)
	all_panels.append_array(_inv_radial_items)
	all_panels.append_array(_chat_radial_items)
	for p: Variant in all_panels:
		if p is Control and (p as Control).visible:
			var c: Control = p as Control
			if Rect2(c.global_position, c.size).has_point(mp):
				return true
	return false

## No-op kept for call-site compatibility (cursor is now managed by _process).
func _hook_cursor(_ctrl: Control) -> void:
	pass

func _compass_set_visible(show: bool) -> void:
	if _compass_icon != null:
		_compass_icon.visible = show
	if _compass_hit != null:
		_compass_hit.visible = show
	if _chat_icon != null:
		_chat_icon.visible = show
	if _chat_hit != null:
		_chat_hit.visible = show
	if _info_icon != null:
		_info_icon.visible = show
	if _info_hit != null:
		_info_hit.visible = show

func _on_compass_clicked() -> void:
	if _compass_animating:
		return
	if _compass_open:
		_close_compass_menu()
	else:
		_open_compass_menu()

func _close_all_menus(animated: bool = true) -> void:
	_close_compass_menu(animated)
	_close_setting_menu(animated)
	_close_inventory_menu(animated)
	_close_chat_menu(animated)
	_close_info_panel()

func _open_compass_menu() -> void:
	if _compass_animating or _compass_open:
		return
	var node: ExplorationNode = ExplorationManager.current_node
	if node == null:
		return
	# Close other menus before opening compass
	_close_setting_menu(false)
	_close_inventory_menu(false)
	_close_chat_menu(false)
	_close_info_panel()
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
	SFXManager.play(SFXManager.SFX_EXPLORATION)

	# Animate compass icon + hit area to center
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(true)
	tw.tween_property(_compass_icon, "position", _compass_center_pos, 0.28)
	tw.tween_property(_compass_hit,  "position", _compass_center_pos, 0.28)
	await tw.finished
	_compass_animating = false

	# Show overlay to catch outside clicks, raise it below the compass
	_radial_overlay.visible = true

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
		_hook_cursor(panel)

		# Fade in with slight stagger
		var fade_tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fade_tw.tween_interval(float(i) * 0.04)
		fade_tw.tween_property(panel, "modulate:a", 1.0, 0.18)

## Fade screen to black (0.5 s), run callback (navigate/go_back), then fade back in (0.3 s).
func _navigate_with_fade(callback: Callable) -> void:
	if _nav_fade_tween and _nav_fade_tween.is_valid():
		_nav_fade_tween.kill()
	_nav_fade_rect.modulate.a = 0.0
	_nav_fade_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_nav_fade_tween.tween_property(_nav_fade_rect, "modulate:a", 1.0, 0.5)
	_nav_fade_tween.tween_callback(func() -> void:
		callback.call()
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_nav_fade_rect, "modulate:a", 0.0, 0.3))

func _on_radial_item_selected(target_id: String) -> void:
	if target_id.is_empty():
		return
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_close_compass_menu()
	_navigate_with_fade(func() -> void: ExplorationManager.navigate_to(target_id))

# ─────────────────────────────────────────────────────────────
# Setting Radial Menu
# ─────────────────────────────────────────────────────────────

func _on_setting_clicked() -> void:
	if _setting_animating:
		return
	if _setting_open:
		_close_setting_menu()
	else:
		_close_compass_menu(false)
		_close_inventory_menu(false)
		_close_chat_menu(false)
		_close_info_panel()
		_open_setting_menu()

func _open_setting_menu() -> void:
	if _setting_animating or _setting_open:
		return
	_setting_open      = true
	_setting_animating = true
	SFXManager.play(SFXManager.SFX_EXPLORATION)

	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp == Vector2.ZERO:
		vp = Vector2(1600.0, 900.0)
	var center_pos := Vector2(vp.x * 0.5 - COMPASS_SIZE * 0.5, vp.y * 0.5 - COMPASS_SIZE * 0.5)

	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(true)
	tw.tween_property(_setting_icon, "position", center_pos, 0.28)
	tw.tween_property(_setting_hit,  "position", center_pos, 0.28)
	await tw.finished
	_setting_animating = false

	_radial_overlay.visible = true
	_spawn_setting_radial_items(center_pos)

func _close_setting_menu(animated: bool = true) -> void:
	if _setting_animating and not _setting_open:
		return
	_setting_open = false
	for item: Variant in _setting_radial_items:
		if is_instance_valid(item as Node):
			(item as Node).queue_free()
	_setting_radial_items.clear()
	if not _compass_open and not _inv_open and not _chat_open and not _info_open:
		_radial_overlay.visible = false
	if not animated:
		_setting_icon.position = _setting_idle_pos
		_setting_hit.position  = _setting_idle_pos
		return
	_setting_animating = true
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(true)
	tw.tween_property(_setting_icon, "position", _setting_idle_pos, 0.22)
	tw.tween_property(_setting_hit,  "position", _setting_idle_pos, 0.22)
	await tw.finished
	_setting_animating = false

func _spawn_setting_radial_items(center: Vector2) -> void:
	var cx: float = center.x + COMPASS_SIZE * 0.5
	var cy: float = center.y + COMPASS_SIZE * 0.5
	var choices: Array = [
		{"label": "Save and Exit",  "action": "save_exit"},
		{"label": "Restart Stage",  "action": "restart"},
		{"label": "Options",        "action": "options"},
	]
	var n: int = choices.size()
	for i: int in range(n):
		var angle: float = (-PI * 0.5) + float(i) * (TAU / float(n))
		var item_cx: float = cx + cos(angle) * RADIAL_RADIUS
		var item_cy: float = cy + sin(angle) * RADIAL_RADIUS
		var panel: PanelContainer = _make_radial_panel(
			Vector2(item_cx - RADIAL_ITEM_W * 0.5, item_cy - RADIAL_ITEM_H * 0.5),
			Color(0.20, 0.04, 0.04, 0.94), Color(1.0, 0.55, 0.45, 0.85))
		var lbl := Label.new()
		lbl.text = str(choices[i].get("label", ""))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.85))
		lbl.add_theme_font_override("font", _make_font(500))
		panel.add_child(lbl)
		var action: String = str(choices[i].get("action", ""))
		panel.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton:
				var mb := ev as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					_on_setting_action(action))
		_compass_root.add_child(panel)
		_setting_radial_items.append(panel)
		_hook_cursor(panel)
		var fade_tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fade_tw.tween_interval(float(i) * 0.04)
		fade_tw.tween_property(panel, "modulate:a", 1.0, 0.18)

func _on_setting_action(action: String) -> void:
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_close_setting_menu()
	match action:
		"save_exit":
			# Session is auto-saved on each navigation; just go to main menu.
			CheckerTransition.fade_out_to_battle(func() -> void:
				get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
		"restart":
			_show_confirm_dialog(
				"Restart Stage?",
				"All progress will be lost.",
				func() -> void:
					_navigate_with_fade(func() -> void: ExplorationManager.restart_stage()))
		"options":
			var sm: Node = load("res://scenes/settings_menu.tscn").instantiate()
			add_child(sm)
			sm.closed.connect(func() -> void: sm.queue_free())

# ─────────────────────────────────────────────────────────────
# Inventory Radial Menu
# ─────────────────────────────────────────────────────────────

func _on_inventory_clicked() -> void:
	if _inv_animating:
		return
	if _inv_open:
		_close_inventory_menu()
	else:
		var inv: Array = ExplorationManager.get_inventory()
		if inv.is_empty():
			_flash_empty_inventory()
			return
		_close_compass_menu(false)
		_close_setting_menu(false)
		_close_chat_menu(false)
		_close_info_panel()
		_open_inventory_menu(0)

func _open_inventory_menu(page: int) -> void:
	if _inv_animating:
		return
	# Clear previous page items
	for item: Variant in _inv_radial_items:
		if is_instance_valid(item as Node):
			(item as Node).queue_free()
	_inv_radial_items.clear()

	_inv_open      = true
	_inv_page      = page
	_inv_animating = true
	SFXManager.play(SFXManager.SFX_EXPLORATION)

	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp == Vector2.ZERO:
		vp = Vector2(1600.0, 900.0)
	var center_pos := Vector2(vp.x * 0.5 - COMPASS_SIZE * 0.5, vp.y * 0.5 - COMPASS_SIZE * 0.5)

	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(true)
	tw.tween_property(_inv_icon, "position", center_pos, 0.28)
	tw.tween_property(_inv_hit,  "position", center_pos, 0.28)
	await tw.finished
	_inv_animating = false

	_radial_overlay.visible = true
	_spawn_inventory_radial_items(center_pos, page)

func _close_inventory_menu(animated: bool = true) -> void:
	if _inv_animating and not _inv_open:
		return
	_inv_open = false
	for item: Variant in _inv_radial_items:
		if is_instance_valid(item as Node):
			(item as Node).queue_free()
	_inv_radial_items.clear()
	if not _compass_open and not _setting_open and not _chat_open and not _info_open:
		_radial_overlay.visible = false
	if not animated:
		_inv_icon.position = _inv_idle_pos
		_inv_hit.position  = _inv_idle_pos
		return
	_inv_animating = true
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(true)
	tw.tween_property(_inv_icon, "position", _inv_idle_pos, 0.22)
	tw.tween_property(_inv_hit,  "position", _inv_idle_pos, 0.22)
	await tw.finished
	_inv_animating = false

func _spawn_inventory_radial_items(center: Vector2, page: int) -> void:
	var inv: Array = ExplorationManager.get_inventory()
	# Deduplicate to unique item IDs
	var seen: Dictionary = {}
	var unique_ids: Array = []
	for raw: Variant in inv:
		var id: String = str(raw)
		if not seen.has(id):
			seen[id] = 0
		seen[id] = int(seen[id]) + 1
		if not unique_ids.has(id):
			unique_ids.append(id)

	var start_idx: int  = page * ITEMS_PER_PAGE
	var end_idx: int    = min(start_idx + ITEMS_PER_PAGE, unique_ids.size())
	var has_more: bool  = end_idx < unique_ids.size()
	var has_prev: bool  = page > 0
	var page_ids: Array = unique_ids.slice(start_idx, end_idx)

	# Build choices: item entries + navigation (More / Back)
	var choices: Array = []
	for id: Variant in page_ids:
		choices.append({"type": "item", "id": str(id), "count": int(seen[id])})
	if has_prev:
		choices.append({"type": "prev"})
	if has_more:
		choices.append({"type": "more"})

	var n: int     = choices.size()
	var cx: float  = center.x + COMPASS_SIZE * 0.5
	var cy: float  = center.y + COMPASS_SIZE * 0.5

	for i: int in range(n):
		var choice: Dictionary = choices[i] as Dictionary
		var angle: float = (-PI * 0.5) + float(i) * (TAU / float(n))
		var item_cx: float = cx + cos(angle) * RADIAL_RADIUS
		var item_cy: float = cy + sin(angle) * RADIAL_RADIUS
		var panel: PanelContainer = _make_radial_panel(
			Vector2(item_cx - RADIAL_ITEM_W * 0.5, item_cy - RADIAL_ITEM_H * 0.5),
			Color(0.04, 0.14, 0.08, 0.94), Color(0.35, 0.80, 0.45, 0.85))

		var choice_type: String = str(choice.get("type", ""))
		if choice_type == "item":
			var item_id: String = str(choice.get("id", ""))
			var count: int = int(choice.get("count", 1))
			var item_data: Dictionary = ExplorationItemDatabase.get_item(item_id)
			var item_name: String = str(item_data.get("name", item_id))
			var icon_path: String = str(item_data.get("icon", ""))

			var inner := HBoxContainer.new()
			inner.add_theme_constant_override("separation", 6)
			inner.alignment = BoxContainer.ALIGNMENT_CENTER
			panel.add_child(inner)

			if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
				var icon_tr := TextureRect.new()
				icon_tr.texture      = load(icon_path) as Texture2D
				icon_tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
				icon_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_tr.custom_minimum_size = Vector2(36.0, 36.0)
				icon_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				inner.add_child(icon_tr)

			var lbl := Label.new()
			lbl.text = item_name if count == 1 else "%s ×%d" % [item_name, count]
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.autowrap_mode      = TextServer.AUTOWRAP_WORD_SMART
			lbl.add_theme_font_size_override("font_size", 16)
			lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.88))
			lbl.add_theme_font_override("font", _make_font(500))
			inner.add_child(lbl)

			var captured_id: String = item_id
			panel.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton:
					var mb := ev as InputEventMouseButton
					if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
						_on_inventory_item_selected(captured_id))
		else:
			var nav_lbl := Label.new()
			nav_lbl.text = "▶ More" if choice_type == "more" else "◀ Back"
			nav_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nav_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			nav_lbl.add_theme_font_size_override("font_size", 16)
			nav_lbl.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
			nav_lbl.add_theme_font_override("font", _make_font(500))
			panel.add_child(nav_lbl)
			var target_page: int = page + 1 if choice_type == "more" else page - 1
			panel.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton:
					var mb := ev as InputEventMouseButton
					if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
						_open_inventory_menu(target_page))

		_compass_root.add_child(panel)
		_inv_radial_items.append(panel)
		_hook_cursor(panel)
		var fade_tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fade_tw.tween_interval(float(i) * 0.04)
		fade_tw.tween_property(panel, "modulate:a", 1.0, 0.18)

func _on_inventory_item_selected(item_id: String) -> void:
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_close_inventory_menu()
	_show_item_preview(item_id)

# ─────────────────────────────────────────────────────────────
# Chat Radial Menu
# ─────────────────────────────────────────────────────────────

func _on_chat_clicked() -> void:
	if _chat_animating:
		return
	if _chat_open:
		_close_chat_menu()
	else:
		var node: ExplorationNode = ExplorationManager.current_node
		if node == null:
			return
		# Filter characters whose conditions are met and haven't been played (if play_once)
		var available: Array = []
		for char_data: Variant in node.characters:
			if available.size() >= 8:
				break
			if not char_data is Dictionary:
				continue
			var cd: Dictionary = char_data as Dictionary
			if not ExplorationManager.is_connection_unlocked(cd):
				continue
			var play_once: bool   = bool(cd.get("play_once", true))
			var vn_path: String   = str(cd.get("vn_scene", ""))
			if play_once and not vn_path.is_empty() and ExplorationManager.is_vn_played(vn_path):
				continue
			available.append(cd)
		if available.is_empty():
			_flash_empty_chat()
			return
		_close_compass_menu(false)
		_close_setting_menu(false)
		_close_inventory_menu(false)
		_close_info_panel()
		_open_chat_menu(available)

func _open_chat_menu(available: Array) -> void:
	if _chat_animating:
		return
	for item: Variant in _chat_radial_items:
		if is_instance_valid(item as Node):
			(item as Node).queue_free()
	_chat_radial_items.clear()

	_chat_open      = true
	_chat_animating = true
	SFXManager.play(SFXManager.SFX_EXPLORATION)

	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp == Vector2.ZERO:
		vp = Vector2(1600.0, 900.0)
	var center_pos := Vector2(vp.x * 0.5 - COMPASS_SIZE * 0.5, vp.y * 0.5 - COMPASS_SIZE * 0.5)

	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(true)
	tw.tween_property(_chat_icon, "position", center_pos, 0.28)
	tw.tween_property(_chat_hit,  "position", center_pos, 0.28)
	await tw.finished
	_chat_animating = false

	_radial_overlay.visible = true
	_spawn_chat_radial_items(center_pos, available)

func _close_chat_menu(animated: bool = true) -> void:
	if _chat_animating and not _chat_open:
		return
	_chat_open = false
	for item: Variant in _chat_radial_items:
		if is_instance_valid(item as Node):
			(item as Node).queue_free()
	_chat_radial_items.clear()
	if not _compass_open and not _setting_open and not _inv_open and not _info_open:
		_radial_overlay.visible = false
	if not animated:
		_chat_icon.position = _chat_idle_pos
		_chat_hit.position  = _chat_idle_pos
		return
	_chat_animating = true
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(true)
	tw.tween_property(_chat_icon, "position", _chat_idle_pos, 0.22)
	tw.tween_property(_chat_hit,  "position", _chat_idle_pos, 0.22)
	await tw.finished
	_chat_animating = false

func _spawn_chat_radial_items(center: Vector2, available: Array) -> void:
	var cx: float = center.x + COMPASS_SIZE * 0.5
	var cy: float = center.y + COMPASS_SIZE * 0.5
	var n: int    = available.size()
	for i: int in range(n):
		var char_data: Dictionary = available[i] as Dictionary
		var char_name: String = str(char_data.get("name", "???"))
		var angle: float = (-PI * 0.5) + float(i) * (TAU / float(n))
		var item_cx: float = cx + cos(angle) * RADIAL_RADIUS
		var item_cy: float = cy + sin(angle) * RADIAL_RADIUS
		var panel: PanelContainer = _make_radial_panel(
			Vector2(item_cx - RADIAL_ITEM_W * 0.5, item_cy - RADIAL_ITEM_H * 0.5),
			Color(0.04, 0.10, 0.20, 0.94), Color(0.45, 0.70, 1.0, 0.85))
		var lbl := Label.new()
		lbl.text = char_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
		lbl.add_theme_font_override("font", _make_font(500))
		panel.add_child(lbl)
		var vn_path: String   = str(char_data.get("vn_scene", ""))
		var play_once_c: bool = bool(char_data.get("play_once", true))
		panel.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton:
				var mb := ev as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					_on_chat_character_selected(vn_path, play_once_c))
		_compass_root.add_child(panel)
		_chat_radial_items.append(panel)
		_hook_cursor(panel)
		var fade_tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fade_tw.tween_interval(float(i) * 0.04)
		fade_tw.tween_property(panel, "modulate:a", 1.0, 0.18)

func _on_chat_character_selected(vn_path: String, play_once: bool = true) -> void:
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_close_chat_menu()
	if vn_path.is_empty():
		return
	var done_cb := func() -> void:
		var node: ExplorationNode = ExplorationManager.current_node
		if node != null:
			_compass_set_visible(true)
	_play_vn(vn_path, done_cb, play_once)

func _flash_empty_chat() -> void:
	if _chat_empty_tween and _chat_empty_tween.is_valid():
		_chat_empty_tween.kill()
	_chat_icon.modulate = Color(0.4, 0.4, 0.4)
	_chat_empty_lbl.text = "No one is here"
	_chat_empty_lbl.modulate.a = 1.0
	_chat_empty_tween = create_tween()
	_chat_empty_tween.tween_interval(1.4)
	_chat_empty_tween.tween_property(_chat_empty_lbl, "modulate:a", 0.0, 0.5)
	_chat_empty_tween.parallel().tween_property(_chat_icon, "modulate", Color(1.0, 1.0, 1.0), 0.5)

func _flash_empty_inventory() -> void:
	if _inv_empty_tween and _inv_empty_tween.is_valid():
		_inv_empty_tween.kill()
	_inv_icon.modulate = Color(0.4, 0.4, 0.4)
	_inv_empty_lbl.text = "Inventory is empty"
	_inv_empty_lbl.modulate.a = 1.0
	_inv_empty_tween = create_tween()
	_inv_empty_tween.tween_interval(1.4)
	_inv_empty_tween.tween_property(_inv_empty_lbl, "modulate:a", 0.0, 0.5)
	_inv_empty_tween.parallel().tween_property(_inv_icon, "modulate", Color(1.0, 1.0, 1.0), 0.5)

# ─────────────────────────────────────────────────────────────
# Info Panel
# ─────────────────────────────────────────────────────────────

## Rebuild the "Who is here" grid from the node's character list.
## Shows up to 8 characters; hides the section if none are present or feature is off.
func _rebuild_who_is_here(node: ExplorationNode) -> void:
	for child: Node in _who_grid.get_children():
		child.queue_free()
	if not node.show_who_is_here or node.characters.is_empty():
		_who_section.visible = false
		return
	var count: int = 0
	for char_data: Variant in node.characters:
		if count >= 8:
			break
		if not char_data is Dictionary:
			continue
		var cd: Dictionary = char_data as Dictionary
		var char_name: String = str(cd.get("name", "")).strip_edges()
		if char_name.is_empty():
			continue
		var thumb_path: String = str(cd.get("thumbnail", "")).strip_edges()
		# Cell container
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 4)
		_who_grid.add_child(cell)
		# Thumbnail
		var thumb := TextureRect.new()
		thumb.custom_minimum_size = Vector2(120.0, 120.0)
		thumb.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not thumb_path.is_empty() and ResourceLoader.exists(thumb_path):
			thumb.texture = load(thumb_path) as Texture2D
		else:
			# Fallback: grey placeholder
			thumb.modulate = Color(0.3, 0.3, 0.4, 0.6)
		cell.add_child(thumb)
		# Name label
		var name_lbl := Label.new()
		name_lbl.text = char_name
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cell.add_child(name_lbl)
		count += 1
	_who_section.visible = count > 0

func _on_info_clicked() -> void:
	if _info_open:
		_close_info_panel()
	else:
		_close_compass_menu(false)
		_close_setting_menu(false)
		_close_inventory_menu(false)
		_close_chat_menu(false)
		_open_info_panel()

## Open the info panel with an optional callback fired after it closes.
## Auto-dismiss timer always starts after slide-in (cancelled if mouse enters the panel).
func _open_info_panel(on_close: Callable = Callable(), _unused: bool = false) -> void:
	_info_auto_dismiss_timer = null
	_info_on_close_cb = on_close
	_info_open = true
	_title_lbl.visible = true
	_desc_lbl.visible  = true
	_back_btn.text     = "Dismiss"
	_back_btn.visible  = false
	_radial_overlay.visible = true
	# Slide in from right
	var vp_w: float = get_viewport().get_visible_rect().size.x
	_content_panel.position.x = vp_w
	_content_panel.visible = true
	if _info_panel_tween and _info_panel_tween.is_valid():
		_info_panel_tween.kill()
	_info_panel_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	_info_panel_tween.tween_property(_content_panel, "position:x", vp_w * BG_AREA_FRACTION, 0.35)
	# Start dismiss timer after slide-in only if mouse is not already over panel or info icon
	_info_panel_tween.tween_callback(func() -> void:
		if _info_open and not _is_over_info_panel_or_icon():
			_on_info_panel_mouse_exited())

func _is_over_info_panel_or_icon() -> bool:
	var mp: Vector2 = get_global_mouse_position()
	if _content_panel != null and _content_panel.visible:
		if Rect2(_content_panel.global_position, _content_panel.size).has_point(mp):
			return true
	if _info_hit != null and _info_hit.visible:
		if Rect2(_info_hit.global_position, _info_hit.size).has_point(mp):
			return true
	return false

func _on_info_panel_mouse_entered() -> void:
	# Cancel pending auto-dismiss while hovering
	_info_auto_dismiss_timer = null

func _on_info_panel_mouse_exited() -> void:
	if not _info_open:
		return
	_info_auto_dismiss_timer = get_tree().create_timer(1.0)
	_info_auto_dismiss_timer.timeout.connect(func() -> void:
		if _info_open and _info_auto_dismiss_timer != null:
			_close_info_panel())

func _close_info_panel() -> void:
	if not _info_open:
		return
	_info_auto_dismiss_timer = null
	_info_open = false
	var cb: Callable = _info_on_close_cb
	_info_on_close_cb = Callable()
	var can_back: bool = ExplorationManager.can_go_back()
	if not _compass_open and not _setting_open and not _inv_open and not _chat_open:
		_radial_overlay.visible = false
	# Slide out to right — hide labels and reset state only after panel is off-screen
	var vp_w: float = get_viewport().get_visible_rect().size.x
	if _info_panel_tween and _info_panel_tween.is_valid():
		_info_panel_tween.kill()
	_info_panel_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	_info_panel_tween.tween_property(_content_panel, "position:x", vp_w, 0.28)
	_info_panel_tween.tween_callback(func() -> void:
		_title_lbl.visible = false
		_desc_lbl.visible  = false
		_back_btn.text     = "← Go Back"
		_back_btn.visible  = can_back
		_content_panel.visible = false
		_content_panel.position.x = vp_w * BG_AREA_FRACTION
		if cb.is_valid():
			cb.call())

# ─────────────────────────────────────────────────────────────
# Item Preview Overlay
# ─────────────────────────────────────────────────────────────

func _show_item_preview(item_id: String) -> void:
	_close_item_preview()
	var item: Dictionary = ExplorationItemDatabase.get_item(item_id)
	if item.is_empty():
		_show_toast("Unknown item.")
		return

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 50
	_item_preview = overlay
	add_child(overlay)

	# Dim background
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color        = Color(0.0, 0.0, 0.0, 0.70)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_close_item_preview())
	overlay.add_child(dimmer)

	# Center panel
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.07, 0.04, 0.97)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.35, 0.85, 0.45, 0.70)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size     = Vector2(480.0, 520.0)
	panel.position = -panel.size * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 24.0; vbox.offset_right  = -24.0
	vbox.offset_top  = 24.0; vbox.offset_bottom = -24.0
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Big image
	var big_path: String = str(item.get("big_image", ""))
	var img_tr := TextureRect.new()
	img_tr.expand_mode        = TextureRect.EXPAND_IGNORE_SIZE
	img_tr.stretch_mode       = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_tr.custom_minimum_size = Vector2(0.0, 200.0)
	img_tr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	img_tr.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	if not big_path.is_empty() and ResourceLoader.exists(big_path):
		img_tr.texture = load(big_path) as Texture2D
	vbox.add_child(img_tr)

	# Item name
	var name_lbl := Label.new()
	name_lbl.text = str(item.get("name", item_id))
	name_lbl.add_theme_font_override("font", _make_font(700))
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.88))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Description
	var desc_lbl := RichTextLabel.new()
	desc_lbl.bbcode_enabled        = true
	desc_lbl.scroll_active         = false
	desc_lbl.custom_minimum_size   = Vector2(0.0, 60.0)
	desc_lbl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("normal_font_size", 18)
	desc_lbl.add_theme_color_override("default_color", Color(0.78, 0.92, 0.82, 0.95))
	desc_lbl.append_text(str(item.get("description", "")))
	vbox.add_child(desc_lbl)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var use_btn := Button.new()
	use_btn.text = "  Use  "
	use_btn.add_theme_font_size_override("font_size", 20)
	use_btn.add_theme_color_override("font_color", Color(0.85, 1.0, 0.88))
	use_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var captured_id: String = item_id
	use_btn.pressed.connect(func() -> void:
		_close_item_preview()
		_execute_item_effects(captured_id))
	btn_row.add_child(use_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.add_theme_color_override("font_color", Color(0.60, 0.65, 0.65))
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_close_item_preview)
	btn_row.add_child(cancel_btn)

func _close_item_preview() -> void:
	if _item_preview != null and is_instance_valid(_item_preview):
		_item_preview.queue_free()
	_item_preview = null

func _execute_item_effects(item_id: String) -> void:
	var item: Dictionary = ExplorationItemDatabase.get_item(item_id)
	var effects: Variant = item.get("effects", [])
	if not effects is Array:
		return
	for eff_var: Variant in (effects as Array):
		if not eff_var is Dictionary:
			continue
		var eff: Dictionary    = eff_var as Dictionary
		var eff_type: String   = str(eff.get("type",  ""))
		var eff_key: String    = str(eff.get("key",   ""))
		var eff_value: String  = str(eff.get("value", ""))
		match eff_type:
			"remove_self":
				ExplorationManager.remove_item(item_id)
			"remove_item":
				var target: String = eff_key if not eff_key.is_empty() else eff_value
				if not target.is_empty():
					ExplorationManager.remove_item(target)
			"set_var":
				ExplorationManager.set_var(eff_key, eff_value)
			"show_message":
				_show_toast(eff_value)
			"play_sfx":
				if not eff_value.is_empty() and ResourceLoader.exists(eff_value):
					var sfx := AudioStreamPlayer.new()
					sfx.stream = load(eff_value) as AudioStream
					sfx.bus    = "SFX"
					add_child(sfx)
					sfx.play()
					await sfx.finished
					sfx.queue_free()
			"play_vn":
				if not eff_value.is_empty():
					var done := false
					_play_vn(eff_value, func() -> void: done = true)
					while not done:
						await get_tree().process_frame
			"navigate_to":
				if not eff_value.is_empty():
					ExplorationManager.navigate_to(eff_value)

# ─────────────────────────────────────────────────────────────
# Shared Radial Helpers
# ─────────────────────────────────────────────────────────────

func _make_radial_panel(pos: Vector2, bg_color: Color, border_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(RADIAL_ITEM_W, RADIAL_ITEM_H)
	panel.position  = pos
	panel.modulate.a = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_border_width_all(1)
	sb.border_color = border_color
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12.0; sb.content_margin_right  = 12.0
	sb.content_margin_top  =  8.0; sb.content_margin_bottom =  8.0
	panel.add_theme_stylebox_override("panel", sb)
	var hover_bg: Color    = bg_color.lightened(0.15)
	var hover_bord: Color  = border_color.lightened(0.20)
	panel.mouse_entered.connect(func() -> void:
		sb.bg_color = hover_bg; sb.border_color = hover_bord)
	panel.mouse_exited.connect(func() -> void:
		sb.bg_color = bg_color; sb.border_color = border_color)
	return panel

# ─────────────────────────────────────────────────────────────
# Confirmation Dialog Helper
# ─────────────────────────────────────────────────────────────

func _show_confirm_dialog(title_text: String, body_text: String, on_confirm: Callable) -> void:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 60
	add_child(overlay)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color        = Color(0.0, 0.0, 0.0, 0.60)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dimmer)

	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.14, 0.97)
	sb.set_border_width_all(2)
	sb.border_color = Color(1.0, 0.55, 0.45, 0.70)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	panel.layout_mode = 0
	var dlg_size := Vector2(380.0, 200.0)
	var vp_sz: Vector2 = get_viewport().get_visible_rect().size
	panel.size     = dlg_size
	panel.position = (vp_sz - dlg_size) * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 24.0; vbox.offset_right  = -24.0
	vbox.offset_top  = 20.0; vbox.offset_bottom = -20.0
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = title_text
	title_lbl.add_theme_font_override("font", _make_font(700))
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.70))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var body_lbl := Label.new()
	body_lbl.text = body_text
	body_lbl.add_theme_font_size_override("font_size", 16)
	body_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.85))
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(body_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var confirm_btn := Button.new()
	confirm_btn.text = "Yes"
	confirm_btn.add_theme_font_size_override("font_size", 18)
	confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.60, 0.50))
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_btn.pressed.connect(func() -> void:
		overlay.queue_free()
		on_confirm.call())
	btn_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.add_theme_color_override("font_color", Color(0.60, 0.65, 0.65))
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(func() -> void: overlay.queue_free())
	btn_row.add_child(cancel_btn)

# ─────────────────────────────────────────────────────────────
# Node Rendering
# ─────────────────────────────────────────────────────────────

func _on_node_entered(node: ExplorationNode) -> void:
	_close_all_menus(false)
	_close_item_preview()
	_refresh_node(node)

func _refresh_node(node: ExplorationNode) -> void:
	_exit_pending   = false
	_battle_pending = false

	# Background
	if not node.background.is_empty() and node.background != _current_bg_path:
		_current_bg_path = node.background
		var tex: Texture2D = load(node.background) as Texture2D
		if tex != null:
			_bg_rect.texture = tex
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


	# Point-and-click hotspots for this node
	_rebuild_spots(node)

	# "Who is here" section in info panel
	_rebuild_who_is_here(node)

	# Node-type routing: BATTLE/EXIT get inline action buttons; all others use compass.
	_close_all_menus(false)
	match node.node_type:
		ExplorationNode.NodeType.BATTLE:
			_content_panel.visible = true
			_choices_vbox.visible = true
			_compass_set_visible(false)
			_show_battle_prompt(node)
		ExplorationNode.NodeType.EXIT:
			_content_panel.visible = true
			_choices_vbox.visible = true
			_compass_set_visible(false)
			_show_exit_prompt()
		ExplorationNode.NodeType.STORY:
			_content_panel.visible = false
			_choices_vbox.visible = false
			_compass_set_visible(false)   # hidden while VN plays; restored in _on_vn_finished
			if node.show_info_on_enter:
				_open_info_panel(func() -> void: _play_story_vn(node), true)
			else:
				_play_story_vn(node)
		_:
			_content_panel.visible = false
			_choices_vbox.visible = false
			if node.show_info_on_enter:
				_compass_set_visible(true)
				_open_info_panel(func() -> void: _play_other_vn(node), true)
			else:
				_play_other_vn(node)


# ─────────────────────────────────────────────────────────────
# Visual Novel Integration
# ─────────────────────────────────────────────────────────────

## Play the VN for a STORY node (compass hidden during playback).
func _play_story_vn(node: ExplorationNode) -> void:
	if not node.vn_scene.is_empty():
		var already_played: bool = node.vn_play_once and ExplorationManager.is_vn_played(node.vn_scene)
		if already_played:
			_compass_set_visible(true)
		else:
			_play_vn(node.vn_scene, func() -> void: _on_vn_finished(node), node.vn_play_once)
	else:
		_compass_set_visible(true)

## Play the VN for non-STORY nodes (compass restored after VN).
func _play_other_vn(node: ExplorationNode) -> void:
	if not node.vn_scene.is_empty():
		var already_played: bool = node.vn_play_once and ExplorationManager.is_vn_played(node.vn_scene)
		if already_played:
			_compass_set_visible(true)
		else:
			_compass_set_visible(false)
			_play_vn(node.vn_scene, func() -> void: _on_vn_finished(node), node.vn_play_once)
	else:
		_compass_set_visible(true)

func _play_vn(path: String, on_done: Callable, play_once: bool = true) -> void:
	if _vn_playing:
		return
	if not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		push_warning("ExplorationPlayer: VN scene '%s' not found — skipping." % path)
		on_done.call()
		return
	_vn_playing = true
	_compass_set_visible(false)   # disable compass while VN is active
	var vn: Node = VN_PLAYER_SCENE.instantiate()
	vn.set("transparent_bg", true)   # show exploration scene behind VN dialog
	vn.set("keep_bgm", true)         # don't interrupt exploration ambient track
	add_child(vn)
	var captured_path: String = path
	var captured_once: bool   = play_once
	vn.play_scene(path, func() -> void:
		if captured_once:
			ExplorationManager.mark_vn_played(captured_path)
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
		SFXManager.play(SFXManager.SFX_EXPLORATION)
		ExplorationManager.start_battle_for_node(captured_node))
	_hook_cursor(btn)
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
	_hook_cursor(btn)
	_choices_vbox.add_child(btn)

func _on_exit_confirmed() -> void:
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	ExplorationManager.end_session(true)
	var dest: String = ExplorationManager.return_scene
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file(dest))

# ─────────────────────────────────────────────────────────────
# UI helpers
# ─────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	if _info_open:
		_close_info_panel()
		return
	SFXManager.play(SFXManager.SFX_CANCEL)
	_navigate_with_fade(func() -> void: ExplorationManager.go_back())

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
	_content_panel.visible = true
	_choices_vbox.visible = true
	_compass_set_visible(false)

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
	Input.set_custom_mouse_cursor(_default_tex, Input.CURSOR_ARROW, Vector2(4.0, 4.0))
	_hide_tooltip()

func _hide_tooltip() -> void:
	if _tooltip_panel != null:
		_tooltip_panel.visible = false

func _on_spot_clicked(vn_path: String) -> void:
	if _vn_playing or vn_path.is_empty():
		return
	_on_spot_hover_exit()   # restore cursor before VN takes over
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_play_vn(vn_path, func() -> void:
		var node: ExplorationNode = ExplorationManager.current_node
		if node != null:
			_compass_set_visible(true))

func _process(_delta: float) -> void:
	# Auto-dismiss: cancel timer while hovering panel or info icon; start it on unhover
	if _info_open:
		var over: bool = _is_over_info_panel_or_icon()
		if over and not _info_panel_hovered:
			# mouse just entered — cancel pending timer
			_info_auto_dismiss_timer = null
		elif not over and _info_panel_hovered:
			# mouse just left — start dismiss timer
			_on_info_panel_mouse_exited()
		_info_panel_hovered = over
	# Tooltip follow
	if _tooltip_panel != null and _tooltip_panel.visible:
		var mp: Vector2 = get_local_mouse_position()
		var vp: Vector2 = get_viewport_rect().size
		var tp: Vector2 = _tooltip_panel.size
		_tooltip_panel.position = Vector2(
			minf(mp.x + 16.0, vp.x - tp.x - 4.0),
			minf(mp.y + 16.0, vp.y - tp.y - 4.0))
	# Cursor: finger over interactive elements, default otherwise
	if not _hovering_spot:
		if _mouse_over_interactive():
			if _finger_tex != null:
				Input.set_custom_mouse_cursor(_finger_tex, Input.CURSOR_ARROW, Vector2(12.0, 4.0))
		else:
			Input.set_custom_mouse_cursor(_default_tex, Input.CURSOR_ARROW, Vector2(4.0, 4.0))

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

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not (mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT):
		return
	if _item_preview != null:
		return  # item preview handles its own dismissal
	if not (_compass_open or _setting_open or _inv_open or _chat_open or _info_open):
		return
	# If click lands on an icon button or a radial item, let that element handle it
	var interactive: Array = [_compass_hit, _setting_hit, _inv_hit, _chat_hit, _info_hit]
	interactive.append_array(_radial_items)
	interactive.append_array(_setting_radial_items)
	interactive.append_array(_inv_radial_items)
	interactive.append_array(_chat_radial_items)
	# Also protect the content panel when info is open
	if _info_open and _content_panel != null:
		interactive.append(_content_panel)
	for node: Variant in interactive:
		if is_instance_valid(node as Node):
			var ctrl: Control = node as Control
			if ctrl.get_global_rect().has_point(mb.global_position):
				return  # let the element handle it
	# Click is outside all menu elements — dismiss and consume
	_close_all_menus()
	get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var ke := event as InputEventKey
		if ke.keycode == KEY_F3:
			_toggle_debug()
			get_viewport().set_input_as_handled()
		elif ke.keycode == KEY_ESCAPE:
			if _item_preview != null:
				_close_item_preview()
			elif _compass_open or _setting_open or _inv_open:
				_close_all_menus()
			elif ExplorationManager.can_go_back():
				SFXManager.play(SFXManager.SFX_CANCEL)
				ExplorationManager.go_back()
			# Always consume so CheckerTransition's quit handler never fires here
			get_viewport().set_input_as_handled()
