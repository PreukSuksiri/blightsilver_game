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
const DEFAULT_CURSOR: String   = "res://assets/textures/ui/decorations/ui_cursor_finger_64.png"
const MAGNIFIER_CURSOR: String = "res://assets/textures/ui/decorations/ui_icon_magnifier.png"
const FINGER_CURSOR: String    = "res://assets/textures/ui/decorations/ui_cursor_finger_64.png"
const COMPASS_SIZE: float  = 110.0  # icon width/height in pixels
const COMPASS_IDLE_GLOW_PAD: float = 40.0   # soft halo extends this far beyond compass icon
const COMPASS_IDLE_HINT_DELAY: float = 10.0 # seconds of no interaction before compass hint
const RADIAL_RADIUS: float = 210.0  # distance from center to item midpoint
const RADIAL_ITEM_W: float = 180.0  # radial button width (settings / inventory / chat)
const RADIAL_ITEM_H: float = 54.0   # radial button height (settings / inventory / chat)
const NAV_RADIAL_ITEM_W_MIN: float = 180.0
const NAV_RADIAL_ITEM_W_MAX: float = 220.0
const NAV_RADIAL_ITEM_H_MIN: float = 54.0
const NAV_RADIAL_ITEM_H_MAX: float = 72.0
const NAV_RADIAL_FONT_SIZE: int    = 17
const NAV_RADIAL_PAD_H: float      = 24.0   # total horizontal inset inside nav chip
const NAV_RADIAL_PAD_V: float      = 16.0   # total vertical inset inside nav chip
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
var _transition_active: bool       = false   # true while fade-out/in is running

# ── Compass radial menu ───────────────────────────────────────────────────
var _compass_root: Control        = null   # full-screen layer holding all 3 icons
var _compass_icon: TextureRect    = null   # the compass texture
var _compass_hit: Button          = null   # invisible click area over the icon
var _radial_overlay: Control      = null   # full-screen click-catcher (outside dismiss)
var _radial_menu_layer: Control   = null   # top z-layer for open radial submenu panels
var _radial_items: Array          = []     # currently shown radial PanelContainers (compass)
var _compass_open: bool           = false
var _compass_animating: bool      = false
var _compass_idle_pos: Vector2    = Vector2.ZERO
var _compass_center_pos: Vector2  = Vector2.ZERO
# Cyan HUD glows — priority: chat > inventory > compass (idle timer)
var _hud_glow_nodes: Dictionary  = {}   # "compass"|"inventory"|"chat" → Control
var _hud_glow_tweens: Dictionary = {}
var _hud_glow_active: Dictionary = {}
var _hud_glow_icons: Dictionary  = {}   # key → TextureRect (position sync)
var _idle_elapsed: float         = 0.0

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
var _info_wait_for_mouse: bool               = false   # true after auto-open: dismiss blocked until mouse moves
var _info_mouse_wait_timer: SceneTreeTimer   = null    # 5s fallback: forces dismiss mode even without mouse move

# ── Item preview overlay (inventory tap-to-inspect) ──────────────────────
var _item_preview: Control        = null
var _settings_menu: Node          = null
var _confirm_overlay: Control     = null

# ── Item-obtained overlay (awarded item cinematic) ────────────────────────
# Queue entries are either a String (item_id) or a Dictionary ({_mailbox_type, image_path, display_name}).
var _obtained_overlay: Control              = null
var _obtained_queue: Array                  = []
var _obtained_dismiss_timer: SceneTreeTimer = null
var _obtained_dismissing: bool              = false

# ── Cursors ───────────────────────────────────────────────────────────────
var _default_tex: Texture2D       = null
var _finger_tex: Texture2D        = null

# ── Internal state ────────────────────────────────────────────────────────
var _current_bg_path: String = ""
var _vn_playing: bool        = false
var _exit_vn_defer_enter: bool = false   # hold new-node visuals until on_exit VN finishes
var _pending_enter_node: ExplorationNode = null
var _puzzle_playing: bool    = false
var _puzzle_layer: Control   = null
var _battle_pending: bool    = false
var _exit_pending: bool      = false

# ── Point-and-click hotspots ──────────────────────────────────────────────
var _spots_layer: Control          = null   # holds spot hit-controls + icons
var _tooltip_panel: PanelContainer = null   # spot tooltip (anchored to spot, not cursor)
var _tooltip_lbl: Label            = null
var _hovering_spot: bool           = false
var _hovered_spot_hit: Control     = null   # the hit Control currently being hovered
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
	call_deferred("_refresh_contextual_hud_glows")

func _connect_signals() -> void:
	ExplorationManager.node_entered.connect(_on_node_entered)
	ExplorationManager.node_exited.connect(_on_node_exited)
	ExplorationManager.message_posted.connect(_show_toast)
	ExplorationManager.item_obtained.connect(_on_item_obtained)
	ExplorationManager.mailbox_reward_granted.connect(_on_mailbox_reward_granted)
	ExplorationManager.inventory_changed.connect(_on_exploration_state_changed)
	ExplorationManager.var_changed.connect(_on_var_changed)

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
	_title_lbl.add_theme_font_size_override("font_size", 30)
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
	who_hdr.add_theme_font_size_override("font_size", 30)
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
	_magnifier_tex = _load_cursor_tex(MAGNIFIER_CURSOR)

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
	if _radial_overlay != null:
		_radial_overlay.size = vp_size
	if _radial_menu_layer != null:
		_radial_menu_layer.size = vp_size

# ─────────────────────────────────────────────────────────────
# Compass Radial Menu
# ─────────────────────────────────────────────────────────────

func _build_compass_system() -> void:
	# Root layer — always visible, holds all three bottom icons.
	_compass_root = Control.new()
	_compass_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compass_root.z_index      = 30
	_compass_root.visible      = true
	add_child(_compass_root)
	_compass_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Viewport size for positioning.
	var vp: Vector2 = get_viewport_rect().size
	if vp == Vector2.ZERO:
		vp = Vector2(1600.0, 900.0)
	var bottom_y: float = vp.y - COMPASS_SIZE - 24.0
	var center_y: float = vp.y * 0.5 - COMPASS_SIZE * 0.5

	# ── Compass (center) ─────────────────────────────────────
	_compass_idle_pos   = Vector2(vp.x * 0.5 - COMPASS_SIZE * 0.5, bottom_y)
	_compass_center_pos = Vector2(vp.x * 0.5 - COMPASS_SIZE * 0.5, center_y)

	# Full-screen click-catcher — sibling below icons (z=30) and radial items (z=40).
	# Dismisses open menus when the player taps outside interactive HUD elements.
	_radial_overlay = Control.new()
	_radial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_radial_overlay.z_index      = 25
	_radial_overlay.visible      = false
	_radial_overlay.position     = Vector2.ZERO
	_radial_overlay.size         = vp
	_radial_overlay.gui_input.connect(_on_radial_overlay_gui_input)
	add_child(_radial_overlay)

	# Radial submenu panels live here (not under MOUSE_FILTER_IGNORE compass_root) so
	# taps reliably reach them above the dismiss overlay and below nothing else.
	_radial_menu_layer = Control.new()
	_radial_menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radial_menu_layer.z_index      = 40
	_radial_menu_layer.visible      = true
	_radial_menu_layer.position     = Vector2.ZERO
	_radial_menu_layer.size         = vp
	add_child(_radial_menu_layer)

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

	_setup_hud_glow("compass", _compass_icon, _compass_idle_pos)
	_setup_hud_glow("inventory", _inv_icon, _inv_idle_pos)
	_setup_hud_glow("chat", _chat_icon, _chat_idle_pos)

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
	if not show:
		_dismiss_hud_glow("compass", false)
		_dismiss_hud_glow("inventory", false)
		_dismiss_hud_glow("chat", false)

func _setup_hud_glow(key: String, icon: TextureRect, idle_pos: Vector2) -> void:
	var glow_size: float = COMPASS_SIZE + COMPASS_IDLE_GLOW_PAD * 2.0
	var glow := CompassIdleGlow.new()
	glow.position     = idle_pos - Vector2(COMPASS_IDLE_GLOW_PAD, COMPASS_IDLE_GLOW_PAD)
	glow.size         = Vector2(glow_size, glow_size)
	glow.visible      = false
	glow.modulate.a   = 0.0
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compass_root.add_child(glow)
	_compass_root.move_child(glow, icon.get_index())
	_hud_glow_nodes[key]  = glow
	_hud_glow_icons[key]  = icon
	_hud_glow_active[key] = false

func _on_exploration_state_changed(_arg1: Variant = null, _arg2: Variant = null) -> void:
	_refresh_contextual_hud_glows()

func _on_var_changed(key: String, value: String) -> void:
	_refresh_contextual_hud_glows()
	var node: ExplorationNode = ExplorationManager.current_node
	if node == null or _vn_playing or _puzzle_playing:
		return
	if not node.vn_var_change_matches(key, value):
		return
	_try_play_node_vn(node, node.node_type == ExplorationNode.NodeType.STORY)

func _on_node_exited(node: ExplorationNode) -> void:
	if node == null or not node.vn_trigger_on_exit():
		return
	if _vn_playing or _puzzle_playing:
		return
	if _would_play_node_vn(node):
		_exit_vn_defer_enter = true
	_try_play_node_vn(node, node.node_type == ExplorationNode.NodeType.STORY)

func _register_exploration_activity() -> void:
	_idle_elapsed = 0.0
	if _hud_glow_active.get("compass", false):
		_dismiss_hud_glow("compass")

func _can_track_compass_idle() -> bool:
	if not ExplorationManager.is_session_active:
		return false
	if _vn_playing or _puzzle_playing or _transition_active:
		return false
	if _compass_icon == null or not _compass_icon.visible:
		return false
	if _compass_open or _compass_animating:
		return false
	if _obtained_overlay != null and is_instance_valid(_obtained_overlay):
		return false
	return true

func _can_start_compass_idle_timer() -> bool:
	# Chat and inventory contextual glows block the compass idle timer.
	return not _hud_glow_active.get("chat", false) \
		and not _hud_glow_active.get("inventory", false)

func _start_hud_glow(key: String) -> void:
	if _hud_glow_active.get(key, false):
		return
	var glow: Variant = _hud_glow_nodes.get(key, null)
	var icon: Variant = _hud_glow_icons.get(key, null)
	if glow == null or not (glow is Control) or icon == null or not (icon is TextureRect):
		return
	if not (icon as TextureRect).visible:
		return
	if key == "compass" and not _can_track_compass_idle():
		return
	_hud_glow_active[key] = true
	_sync_hud_glow_position(key)
	(glow as Control).visible = true
	(glow as Control).modulate.a = 0.30
	var tw: Variant = _hud_glow_tweens.get(key, null)
	if tw is Tween and (tw as Tween).is_valid():
		(tw as Tween).kill()
	var pulse := create_tween().set_loops()
	pulse.tween_property(glow, "modulate:a", 0.85, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(glow, "modulate:a", 0.30, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hud_glow_tweens[key] = pulse

func _dismiss_hud_glow(key: String, fade: bool = true) -> void:
	if not _hud_glow_active.get(key, false):
		return
	_hud_glow_active[key] = false
	var tw: Variant = _hud_glow_tweens.get(key, null)
	if tw is Tween and (tw as Tween).is_valid():
		(tw as Tween).kill()
	_hud_glow_tweens[key] = null
	var glow: Variant = _hud_glow_nodes.get(key, null)
	if glow == null or not is_instance_valid(glow as Node):
		return
	if fade:
		var fade_tw := create_tween()
		fade_tw.tween_property(glow, "modulate:a", 0.0, 0.35) \
			.set_trans(Tween.TRANS_SINE)
		fade_tw.tween_callback(func() -> void:
			if is_instance_valid(glow as Node):
				(glow as Control).visible = false)
	else:
		(glow as Control).modulate.a = 0.0
		(glow as Control).visible    = false

func _sync_hud_glow_position(key: String) -> void:
	var glow: Variant = _hud_glow_nodes.get(key, null)
	var icon: Variant = _hud_glow_icons.get(key, null)
	if glow == null or icon == null or not (icon is TextureRect):
		return
	(glow as Control).position = (icon as TextureRect).position \
		- Vector2(COMPASS_IDLE_GLOW_PAD, COMPASS_IDLE_GLOW_PAD)

func _has_eligible_inventory_item() -> bool:
	for item_id: Variant in ExplorationManager.get_inventory():
		var id: String = str(item_id)
		var item: Dictionary = ExplorationItemDatabase.get_item(id)
		if not bool(item.get("key_item", false)):
			continue
		if _item_can_be_used(id):
			return true
	return false

func _has_canon_story_chat() -> bool:
	var node: ExplorationNode = ExplorationManager.current_node
	if node == null:
		return false
	for char_data: Variant in node.characters:
		if not char_data is Dictionary:
			continue
		var cd: Dictionary = char_data as Dictionary
		if not bool(cd.get("canon_story", false)):
			continue
		if not ExplorationManager.is_connection_unlocked(cd):
			continue
		var vn_path: String = str(cd.get("vn_scene", ""))
		if vn_path.is_empty():
			continue
		if bool(cd.get("play_once", true)) and ExplorationManager.is_vn_played(vn_path):
			continue
		return true
	return false

func _refresh_contextual_hud_glows() -> void:
	var chat_on: bool = _has_canon_story_chat()
	var inv_on: bool  = _has_eligible_inventory_item()
	if chat_on:
		_start_hud_glow("chat")
	else:
		_dismiss_hud_glow("chat")
	if inv_on:
		_start_hud_glow("inventory")
	else:
		_dismiss_hud_glow("inventory")
	# Higher-priority glows preempt the compass idle hint.
	if chat_on or inv_on:
		_idle_elapsed = 0.0
		if _hud_glow_active.get("compass", false):
			_dismiss_hud_glow("compass")

func _on_compass_clicked() -> void:
	_register_exploration_activity()
	if _compass_animating:
		return
	if _compass_open:
		_close_compass_menu()
		return
	if _is_any_other_hud_menu_active("compass"):
		_dismiss_all_hud_menus(false)
		return
	_open_compass_menu()

func _is_hud_menu_active(which: String) -> bool:
	match which:
		"compass":   return _compass_open
		"setting":   return _setting_open
		"inventory": return _inv_open
		"chat":      return _chat_open
		"info":      return _info_open
	return false

func _is_any_other_hud_menu_active(which: String) -> bool:
	for id: String in ["compass", "setting", "inventory", "chat", "info"]:
		if id == which:
			continue
		if _is_hud_menu_active(id):
			return true
	return false

func _dismiss_all_hud_menus(animated: bool = true) -> void:
	_close_compass_menu(animated)
	_close_setting_menu(animated)
	_close_inventory_menu(animated)
	_close_chat_menu(animated)
	_close_info_panel()

func _close_settings_menu_popup() -> void:
	if _settings_menu != null and is_instance_valid(_settings_menu):
		_settings_menu.queue_free()
	_settings_menu = null

func _close_confirm_dialog() -> void:
	if _confirm_overlay != null and is_instance_valid(_confirm_overlay):
		_confirm_overlay.queue_free()
	_confirm_overlay = null

func _dismiss_all_popups() -> void:
	_dismiss_all_hud_menus(false)
	_hide_tooltip()
	_close_item_preview()
	_close_settings_menu_popup()
	_close_confirm_dialog()
	_obtained_queue.clear()
	_obtained_dismiss_timer = null
	_obtained_dismissing    = false
	if _obtained_overlay != null and is_instance_valid(_obtained_overlay):
		_obtained_overlay.queue_free()
	_obtained_overlay = null

func _close_all_menus(animated: bool = true) -> void:
	_dismiss_all_hud_menus(animated)

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
	# Gather connections visible in the compass (unlocked, or locked+disable mode)
	var menu_connections: Array = []
	for conn: Variant in node.connections:
		if conn is Dictionary and ExplorationManager.connection_should_show(conn as Dictionary):
			menu_connections.append(conn)
	if menu_connections.is_empty():
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
	_spawn_radial_items(menu_connections)

func _close_compass_menu(animated: bool = true) -> void:
	if _compass_animating and _compass_open == false:
		return
	_compass_open = false
	_hide_tooltip()

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

func _spawn_radial_items(connections: Array) -> void:
	var n: int      = connections.size()
	var vp: Vector2 = get_viewport_rect().size
	var screen_cx: float = vp.x * 0.5
	var screen_cy: float = vp.y * 0.5
	var pad: float  = 8.0   # minimum inset from screen edge

	for i: int in range(n):
		var conn: Dictionary = connections[i] as Dictionary
		var label_text: String = str(conn.get("label", "Continue"))
		var target_id: String  = str(conn.get("target", ""))
		var is_locked: bool = not ExplorationManager.is_connection_unlocked(conn)
		var lock_hint: String = ExplorationManager.get_connection_lock_hint(conn)

		# Angle: start at top (−90°), spread clockwise
		var angle: float = (-PI * 0.5) + float(i) * (TAU / float(n))
		var item_cx: float = screen_cx + cos(angle) * RADIAL_RADIUS
		var item_cy: float = screen_cy + sin(angle) * RADIAL_RADIUS
		var panel: PanelContainer = _make_nav_radial_panel(
			label_text, target_id, item_cx, item_cy, vp, pad, is_locked, lock_hint)
		_add_radial_menu_panel(panel, _radial_items)

		# Fade in with slight stagger
		var fade_tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fade_tw.tween_interval(float(i) * 0.04)
		fade_tw.tween_property(panel, "modulate:a", 1.0, 0.18)

## Fade screen to black (0.5 s), run callback (navigate/go_back), then fade back in (0.3 s).
func _navigate_with_fade(callback: Callable) -> void:
	if _nav_fade_tween and _nav_fade_tween.is_valid():
		_nav_fade_tween.kill()
	_transition_active    = true
	_nav_fade_rect.modulate.a = 0.0
	_nav_fade_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_nav_fade_tween.tween_property(_nav_fade_rect, "modulate:a", 1.0, 0.5)
	_nav_fade_tween.tween_callback(func() -> void:
		callback.call()
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_nav_fade_rect, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func() -> void: _transition_active = false))

func _on_radial_item_selected(target_id: String) -> void:
	_register_exploration_activity()
	if target_id.is_empty():
		return
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_close_compass_menu()
	_navigate_with_fade(func() -> void: ExplorationManager.navigate_to(target_id))

# ─────────────────────────────────────────────────────────────
# Setting Radial Menu
# ─────────────────────────────────────────────────────────────

func _on_setting_clicked() -> void:
	_register_exploration_activity()
	if _setting_animating:
		return
	if _setting_open:
		_close_setting_menu()
		return
	if _is_any_other_hud_menu_active("setting"):
		_dismiss_all_hud_menus(false)
		return
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
	var cx: float  = center.x + COMPASS_SIZE * 0.5
	var cy: float  = center.y + COMPASS_SIZE * 0.5
	var vp: Vector2 = get_viewport_rect().size
	var pad: float  = 8.0
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
			Vector2(clampf(item_cx - RADIAL_ITEM_W * 0.5, pad, vp.x - RADIAL_ITEM_W - pad),
					clampf(item_cy - RADIAL_ITEM_H * 0.5, pad, vp.y - RADIAL_ITEM_H - pad)),
			Color(0.04, 0.08, 0.20, 0.94), Color(0.45, 0.70, 1.0, 0.85))
		var lbl := Label.new()
		lbl.text = str(choices[i].get("label", ""))
		lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.mouse_filter          = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
		lbl.add_theme_font_override("font", _make_font(500))
		panel.add_child(lbl)
		var action: String = str(choices[i].get("action", ""))
		panel.gui_input.connect(func(ev: InputEvent) -> void:
			if _is_press_event(ev):
				_on_setting_action(action))
		_add_radial_menu_panel(panel, _setting_radial_items)
		var fade_tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fade_tw.tween_interval(float(i) * 0.04)
		fade_tw.tween_property(panel, "modulate:a", 1.0, 0.18)

func _on_setting_action(action: String) -> void:
	_register_exploration_activity()
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_close_setting_menu()
	match action:
		"save_exit":
			# Session is auto-saved on each navigation; just go to main menu.
			CheckerTransition.fade_out_to_battle(func() -> void:
				get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
				CheckerTransition.fade_in())
		"restart":
			_show_confirm_dialog(
				"Restart Stage?",
				"All progress will be lost.",
				func() -> void:
					_dismiss_all_popups()
					CheckerTransition.fade_out_to_battle(func() -> void:
						ExplorationManager.restart_stage()
						CheckerTransition.fade_in()))
		"options":
			_open_settings_menu_popup()

# ─────────────────────────────────────────────────────────────
# Inventory Radial Menu
# ─────────────────────────────────────────────────────────────

func _on_inventory_clicked() -> void:
	_register_exploration_activity()
	if _inv_animating:
		return
	if _inv_open:
		_close_inventory_menu()
		return
	if _is_any_other_hud_menu_active("inventory"):
		_dismiss_all_hud_menus(false)
		return
	var inv: Array = ExplorationManager.get_inventory()
	if inv.is_empty():
		_flash_empty_inventory()
		return
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

	var n: int      = choices.size()
	var cx: float   = center.x + COMPASS_SIZE * 0.5
	var cy: float   = center.y + COMPASS_SIZE * 0.5
	var vp: Vector2 = get_viewport_rect().size
	var pad: float  = 8.0

	for i: int in range(n):
		var choice: Dictionary = choices[i] as Dictionary
		var angle: float = (-PI * 0.5) + float(i) * (TAU / float(n))
		var item_cx: float = cx + cos(angle) * RADIAL_RADIUS
		var item_cy: float = cy + sin(angle) * RADIAL_RADIUS
		var panel: PanelContainer = _make_radial_panel(
			Vector2(clampf(item_cx - RADIAL_ITEM_W * 0.5, pad, vp.x - RADIAL_ITEM_W - pad),
					clampf(item_cy - RADIAL_ITEM_H * 0.5, pad, vp.y - RADIAL_ITEM_H - pad)),
			Color(0.04, 0.08, 0.20, 0.94), Color(0.45, 0.70, 1.0, 0.85))

		var choice_type: String = str(choice.get("type", ""))
		if choice_type == "item":
			var item_id: String = str(choice.get("id", ""))
			var count: int = int(choice.get("count", 1))
			var item_data: Dictionary = ExplorationItemDatabase.get_item(item_id)
			var item_name: String = str(item_data.get("name", item_id))
			var icon_path: String = str(item_data.get("icon", ""))

			var inner := HBoxContainer.new()
			inner.add_theme_constant_override("separation", 6)
			inner.alignment   = BoxContainer.ALIGNMENT_CENTER
			inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
			lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
			lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.add_theme_font_size_override("font_size", 16)
			lbl.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
			lbl.add_theme_font_override("font", _make_font(500))
			inner.add_child(lbl)

			var captured_id: String = item_id
			panel.gui_input.connect(func(ev: InputEvent) -> void:
				if _is_press_event(ev):
					_on_inventory_item_selected(captured_id))
		else:
			var nav_lbl := Label.new()
			nav_lbl.text = "▶ More" if choice_type == "more" else "◀ Back"
			nav_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nav_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			nav_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
			nav_lbl.add_theme_font_size_override("font_size", 16)
			nav_lbl.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
			nav_lbl.add_theme_font_override("font", _make_font(500))
			panel.add_child(nav_lbl)
			var target_page: int = page + 1 if choice_type == "more" else page - 1
			panel.gui_input.connect(func(ev: InputEvent) -> void:
				if _is_press_event(ev):
					_open_inventory_menu(target_page))

		_add_radial_menu_panel(panel, _inv_radial_items)
		var fade_tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fade_tw.tween_interval(float(i) * 0.04)
		fade_tw.tween_property(panel, "modulate:a", 1.0, 0.18)

func _on_inventory_item_selected(item_id: String) -> void:
	_register_exploration_activity()
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_close_inventory_menu()
	_show_item_preview(item_id)

# ─────────────────────────────────────────────────────────────
# Chat Radial Menu
# ─────────────────────────────────────────────────────────────

func _on_chat_clicked() -> void:
	_register_exploration_activity()
	if _chat_animating:
		return
	if _chat_open:
		_close_chat_menu()
		return
	if _is_any_other_hud_menu_active("chat"):
		_dismiss_all_hud_menus(false)
		return
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
	var cx: float   = center.x + COMPASS_SIZE * 0.5
	var cy: float   = center.y + COMPASS_SIZE * 0.5
	var vp: Vector2 = get_viewport_rect().size
	var pad: float  = 8.0
	var n: int      = available.size()
	for i: int in range(n):
		var char_data: Dictionary = available[i] as Dictionary
		var char_name: String = str(char_data.get("name", "???"))
		var angle: float = (-PI * 0.5) + float(i) * (TAU / float(n))
		var item_cx: float = cx + cos(angle) * RADIAL_RADIUS
		var item_cy: float = cy + sin(angle) * RADIAL_RADIUS
		var panel: PanelContainer = _make_radial_panel(
			Vector2(clampf(item_cx - RADIAL_ITEM_W * 0.5, pad, vp.x - RADIAL_ITEM_W - pad),
					clampf(item_cy - RADIAL_ITEM_H * 0.5, pad, vp.y - RADIAL_ITEM_H - pad)),
			Color(0.04, 0.08, 0.20, 0.94), Color(0.45, 0.70, 1.0, 0.85))
		var lbl := Label.new()
		lbl.text = char_name
		lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.mouse_filter          = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
		lbl.add_theme_font_override("font", _make_font(500))
		panel.add_child(lbl)
		var vn_path: String   = str(char_data.get("vn_scene", ""))
		var play_once_c: bool = bool(char_data.get("play_once", true))
		panel.gui_input.connect(func(ev: InputEvent) -> void:
			if _is_press_event(ev):
				_on_chat_character_selected(vn_path, play_once_c))
		_add_radial_menu_panel(panel, _chat_radial_items)
		var fade_tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fade_tw.tween_interval(float(i) * 0.04)
		fade_tw.tween_property(panel, "modulate:a", 1.0, 0.18)

func _on_chat_character_selected(vn_path: String, play_once: bool = true) -> void:
	_register_exploration_activity()
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_close_chat_menu()
	if vn_path.is_empty():
		return
	var done_cb := func() -> void:
		var node: ExplorationNode = ExplorationManager.current_node
		if node != null:
			_compass_set_visible(true)
		_refresh_contextual_hud_glows()
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
	_register_exploration_activity()
	if _info_open:
		_close_info_panel()
		return
	if _is_any_other_hud_menu_active("info"):
		_dismiss_all_hud_menus(false)
		return
	_open_info_panel()

## Open the info panel with an optional callback fired after it closes.
## Open the info panel. If wait_for_mouse_move=true (auto-open on node entry), the
## auto-dismiss countdown is suppressed until the player moves the mouse.
func _open_info_panel(on_close: Callable = Callable(), wait_for_mouse_move: bool = false) -> void:
	_info_auto_dismiss_timer = null
	_info_mouse_wait_timer   = null
	_info_wait_for_mouse     = wait_for_mouse_move
	_info_on_close_cb = on_close
	_info_open = true
	# 5-second fallback: if player still hasn't moved the mouse, release the wait-lock anyway
	if wait_for_mouse_move:
		_info_mouse_wait_timer = get_tree().create_timer(5.0)
		_info_mouse_wait_timer.timeout.connect(func() -> void:
			if not _info_wait_for_mouse or not _info_open:
				return
			_info_mouse_wait_timer = null
			_info_wait_for_mouse   = false
			if not _transition_active and not _is_over_info_panel_or_icon():
				_on_info_panel_mouse_exited())
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
	# Start dismiss timer after slide-in only if transition settled, no mouse-move wait, and mouse not over panel/icon
	_info_panel_tween.tween_callback(func() -> void:
		if _info_open and not _transition_active and not _info_wait_for_mouse and not _is_over_info_panel_or_icon():
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
	if not _info_open or _transition_active or _info_wait_for_mouse:
		return
	_info_auto_dismiss_timer = get_tree().create_timer(1.0)
	_info_auto_dismiss_timer.timeout.connect(func() -> void:
		if _info_open and _info_auto_dismiss_timer != null and not _transition_active and not _info_wait_for_mouse:
			_close_info_panel())

func _close_info_panel() -> void:
	if not _info_open:
		return
	_info_auto_dismiss_timer = null
	_info_mouse_wait_timer   = null
	_info_wait_for_mouse     = false
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

	var vp_sz: Vector2 = get_viewport_rect().size

	var overlay := Control.new()
	overlay.z_index  = 50
	overlay.position = Vector2.ZERO
	overlay.size     = vp_sz
	_item_preview    = overlay
	add_child(overlay)

	# Dim background
	var dimmer := ColorRect.new()
	dimmer.color        = Color(0.0, 0.0, 0.0, 0.70)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.position     = Vector2.ZERO
	dimmer.size         = vp_sz
	dimmer.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_close_item_preview())
	overlay.add_child(dimmer)

	# Center panel
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.14, 0.97)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.45, 0.70, 1.0, 0.85)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	var dlg_size := Vector2(480.0, 520.0)
	panel.size         = dlg_size
	panel.position     = (vp_sz - dlg_size) * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 24.0; vbox.offset_right  = -24.0
	vbox.offset_top  = 24.0; vbox.offset_bottom = -24.0

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
	name_lbl.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Description
	var desc_lbl := RichTextLabel.new()
	desc_lbl.bbcode_enabled        = true
	desc_lbl.scroll_active         = false
	desc_lbl.custom_minimum_size   = Vector2(0.0, 60.0)
	desc_lbl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("normal_font_size", 18)
	desc_lbl.add_theme_color_override("default_color", Color(0.78, 0.88, 0.96, 0.95))
	desc_lbl.append_text(str(item.get("description", "")))
	vbox.add_child(desc_lbl)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var can_use: bool = _item_can_be_used(item_id)
	if can_use:
		var use_btn := Button.new()
		use_btn.text = "  Use  "
		use_btn.add_theme_font_size_override("font_size", 20)
		use_btn.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
		use_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured_id: String = item_id
		use_btn.pressed.connect(func() -> void:
			_close_item_preview()
			_execute_item_effects(captured_id))
		btn_row.add_child(use_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", Color(0.60, 0.65, 0.65))
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if can_use else Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(_close_item_preview)
	btn_row.add_child(close_btn)

func _item_can_be_used(item_id: String) -> bool:
	if not ExplorationManager.has_item(item_id):
		return false
	var item: Dictionary = ExplorationItemDatabase.get_item(item_id)
	if item.is_empty():
		return false
	var use_cond: String = str(item.get("use_condition", ""))
	if not use_cond.is_empty() and not ExplorationConditions.evaluate(use_cond):
		return false
	var effects: Variant = item.get("effects", [])
	var has_effects: bool = effects is Array and not (effects as Array).is_empty()
	if has_effects:
		return true
	var node: ExplorationNode = ExplorationManager.current_node
	if node == null:
		return false
	for entry: Variant in node.usable_items:
		if entry is Dictionary and str((entry as Dictionary).get("item", "")) == item_id:
			return true
	return false

func _close_item_preview() -> void:
	if _item_preview != null and is_instance_valid(_item_preview):
		_item_preview.queue_free()
	_item_preview = null

# ─────────────────────────────────────────────────────────────
# Item-Obtained Overlay
# ─────────────────────────────────────────────────────────────

func _on_item_obtained(item_id: String) -> void:
	_obtained_queue.append(item_id)
	if _obtained_overlay == null:
		_show_next_obtained()

func _on_mailbox_reward_granted(info: Dictionary) -> void:
	var entry := info.duplicate()
	entry["_mailbox_type"] = true
	_obtained_queue.append(entry)
	if _obtained_overlay == null:
		_show_next_obtained()

func _show_next_obtained() -> void:
	if _obtained_queue.is_empty():
		return
	var entry: Variant = _obtained_queue[0]
	_obtained_queue.remove_at(0)
	# Route mailbox rewards to the dedicated overlay
	if entry is Dictionary and (entry as Dictionary).has("_mailbox_type"):
		_show_mailbox_reward_overlay(entry as Dictionary)
		return
	var item_id: String = str(entry)
	var item: Dictionary = ExplorationItemDatabase.get_item(item_id)
	if item.is_empty():
		_show_next_obtained()
		return

	_obtained_dismissing = false
	var vp_size: Vector2 = get_viewport_rect().size

	var overlay := Control.new()
	overlay.z_index    = 95
	overlay.modulate.a = 0.0
	overlay.position   = Vector2.ZERO
	overlay.size       = vp_size
	_obtained_overlay  = overlay
	add_child(overlay)

	# Dim
	var dim := ColorRect.new()
	dim.color        = Color(0.0, 0.0, 0.0, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.position     = Vector2.ZERO
	dim.size         = vp_size
	overlay.add_child(dim)

	# Full-screen tap-to-dismiss catcher
	var tapper := ColorRect.new()
	tapper.color        = Color(0.0, 0.0, 0.0, 0.0)
	tapper.mouse_filter = Control.MOUSE_FILTER_STOP
	tapper.position     = Vector2.ZERO
	tapper.size         = vp_size
	tapper.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_dismiss_obtained_overlay())
	overlay.add_child(tapper)

	# Centred content
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.position     = Vector2.ZERO
	center.size         = vp_size
	overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment  = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	# Image — prefer big_image, fall back to icon
	var big_path: String  = str(item.get("big_image", ""))
	var icon_path: String = str(item.get("icon",      ""))
	var img_tr := TextureRect.new()
	img_tr.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	img_tr.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_tr.custom_minimum_size = Vector2(0.0, 340.0)
	img_tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	img_tr.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	if not big_path.is_empty() and ResourceLoader.exists(big_path):
		img_tr.texture = load(big_path) as Texture2D
	elif not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		img_tr.texture = load(icon_path) as Texture2D
	vbox.add_child(img_tr)

	# "Obtained  <Name>" label
	var name_str: String = str(item.get("name", item_id))
	var name_lbl := Label.new()
	name_lbl.text = "Obtained  " + name_str
	name_lbl.add_theme_font_override("font", _make_font(700))
	name_lbl.add_theme_font_size_override("font_size", 38)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# Hint
	var hint_lbl := Label.new()
	hint_lbl.text = "Tap to dismiss"
	hint_lbl.add_theme_font_size_override("font_size", 16)
	hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.65))
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hint_lbl)

	# Fade in
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# 5-second auto-dismiss
	_obtained_dismiss_timer = get_tree().create_timer(5.0)
	_obtained_dismiss_timer.timeout.connect(func() -> void:
		if _obtained_overlay == null or not is_instance_valid(_obtained_overlay):
			return
		_obtained_dismiss_timer = null
		_dismiss_obtained_overlay())

func _dismiss_obtained_overlay() -> void:
	if _obtained_dismissing:
		return
	if _obtained_overlay == null or not is_instance_valid(_obtained_overlay):
		_obtained_overlay = null
		_show_next_obtained()
		return
	_obtained_dismissing = true
	_obtained_dismiss_timer = null
	var ov: Control = _obtained_overlay
	_obtained_overlay = null
	var tw := create_tween()
	tw.tween_property(ov, "modulate:a", 0.0, 0.30).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tw.tween_callback(ov.queue_free)
	tw.tween_callback(func() -> void:
		_obtained_dismissing = false
		_show_next_obtained())

# ─────────────────────────────────────────────────────────────
# Mailbox Reward Overlay
# Full-image presentation for items/packs/credits sent to mailbox.
# Dismisses with a digital-dissolve particle animation, then shows
# a confirmation message before fading out.
# ─────────────────────────────────────────────────────────────

const _DIGIT_FONT_PATH: String = "res://assets/fonts/digital-7.ttf"

func _show_mailbox_reward_overlay(info: Dictionary) -> void:
	_obtained_dismissing = false
	var vp: Vector2 = get_viewport_rect().size

	var overlay := Control.new()
	overlay.z_index    = 96
	overlay.modulate.a = 0.0
	overlay.position   = Vector2.ZERO
	overlay.size       = vp
	_obtained_overlay  = overlay
	add_child(overlay)

	# Dim layer
	var dim := ColorRect.new()
	dim.color        = Color(0.0, 0.0, 0.0, 0.85)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	# Tap-to-dismiss catcher (disabled once dissolve begins)
	var tapper := ColorRect.new()
	tapper.color        = Color(0, 0, 0, 0)
	tapper.mouse_filter = Control.MOUSE_FILTER_STOP
	tapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(tapper)

	# Centred content column
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment    = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	# Image
	var img_path: String = str(info.get("image_path", ""))
	var img_tr := TextureRect.new()
	img_tr.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
	img_tr.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_tr.custom_minimum_size   = Vector2(0.0, 340.0)
	img_tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	img_tr.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	if not img_path.is_empty() and ResourceLoader.exists(img_path):
		img_tr.texture = load(img_path) as Texture2D
	vbox.add_child(img_tr)

	# Title
	var display_name: String = str(info.get("display_name", ""))
	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.add_theme_font_override("font", _make_font(700))
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# Hint
	var hint_lbl := Label.new()
	hint_lbl.text = "Tap to dismiss"
	hint_lbl.add_theme_font_size_override("font_size", 16)
	hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.65))
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hint_lbl)

	# Wire tapper — only triggers BEFORE dissolve begins
	tapper.gui_input.connect(func(ev: InputEvent) -> void:
		if _is_press_event(ev):
			_dismiss_mailbox_reward_overlay(overlay, tapper, img_tr, hint_lbl, name_lbl))

	# Fade-in
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# 8-second auto-dismiss (gives player time to read, then dissolve plays automatically)
	_obtained_dismiss_timer = get_tree().create_timer(8.0)
	_obtained_dismiss_timer.timeout.connect(func() -> void:
		if _obtained_overlay == null or not is_instance_valid(_obtained_overlay):
			return
		_obtained_dismiss_timer = null
		_dismiss_mailbox_reward_overlay(overlay, tapper, img_tr, hint_lbl, name_lbl))

func _dismiss_mailbox_reward_overlay(
		overlay: Control,
		tapper: ColorRect,
		img_tr: TextureRect,
		hint_lbl: Label,
		name_lbl: Label) -> void:
	if _obtained_dismissing:
		return
	if not is_instance_valid(overlay):
		_obtained_overlay     = null
		_obtained_dismissing  = false
		_show_next_obtained()
		return

	_obtained_dismissing    = true
	_obtained_dismiss_timer = null
	_obtained_overlay       = null

	# Disable tapper so accidental taps during animation are ignored
	tapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Hide hint and title — only image stays visible for dissolve
	hint_lbl.visible = false
	name_lbl.visible = false

	_play_digital_dissolve(overlay, img_tr, func() -> void:
		_obtained_dismissing = false
		_show_next_obtained())

func _play_digital_dissolve(overlay: Control, img_tr: TextureRect, on_done: Callable) -> void:
	var vp: Vector2       = get_viewport_rect().size
	const DISSOLVE_DUR:   float = 1.5   # total time before confirmation text appears
	const PARTICLE_COUNT: int   = 28    # subtle, not overwhelming
	const DRIFT_MAX:      float = 110.0

	# Invisible layer so particles are clipped with the overlay — NOT queue_freed;
	# _show_mailbox_sent_text hides all overlay children instead.
	var particle_layer := Control.new()
	particle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particle_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	particle_layer.z_index = 3
	overlay.add_child(particle_layer)

	var digit_font: FontFile = null
	if ResourceLoader.exists(_DIGIT_FONT_PATH):
		digit_font = load(_DIGIT_FONT_PATH) as FontFile

	# Spawn area — read from image rect once layout is settled
	var spawn_cx: float = vp.x * 0.5
	var spawn_cy: float = vp.y * 0.42
	var spawn_w:  float = 340.0
	var spawn_h:  float = 320.0
	if is_instance_valid(img_tr) and img_tr.size.x > 10.0:
		var ir: Rect2 = img_tr.get_global_rect()
		spawn_cx = ir.position.x + ir.size.x * 0.5
		spawn_cy = ir.position.y + ir.size.y * 0.5
		spawn_w  = ir.size.x
		spawn_h  = ir.size.y

	# Fade the image out
	if is_instance_valid(img_tr):
		var img_tw := create_tween()
		img_tw.tween_property(img_tr, "modulate:a", 0.0, DISSOLVE_DUR * 0.75) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Each particle gets THREE independent tweens (appear / drift / fade-out)
	# so their timing is fully decoupled — no particle vanishes at the same time.
	for _i: int in range(PARTICLE_COUNT):
		var lbl := Label.new()
		lbl.text = "0" if randf() > 0.5 else "1"
		if digit_font != null:
			lbl.add_theme_font_override("font", digit_font)
		lbl.add_theme_font_size_override("font_size", randi_range(14, 34))
		lbl.add_theme_color_override("font_color",
			Color(0.0, 0.85 + randf() * 0.15, 0.80 + randf() * 0.20))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.modulate.a   = 0.0

		# Tighter spawn cluster — particles start close to the image centre
		var px: float = spawn_cx + randf_range(-spawn_w * 0.22, spawn_w * 0.22)
		var py: float = spawn_cy + randf_range(-spawn_h * 0.22, spawn_h * 0.22)
		lbl.position  = Vector2(px, py)
		particle_layer.add_child(lbl)

		# Individual random timings for every phase
		var start:      float = randf_range(0.00, 0.35)
		var appear_dur: float = randf_range(0.08, 0.20)
		var drift_dur:  float = randf_range(0.40, DISSOLVE_DUR)
		var fade_delay: float = start + randf_range(0.15, 0.50)
		var fade_dur:   float = randf_range(0.25, 0.65)
		# Movement: always upward, with a subtle left-or-right lean per particle
		var side_bias:  float = randf_range(-1.0, 1.0)           # −1 left … +1 right
		var drift_x:    float = side_bias * randf_range(4.0, 22.0)
		var drift_y:    float = -randf_range(DRIFT_MAX * 0.35, DRIFT_MAX * 0.75)

		# Tween 1: appear — each particle has its own random peak opacity
		var peak_alpha: float = randf_range(0.30, 0.85)
		var tw_appear := create_tween()
		tw_appear.tween_interval(start)
		tw_appear.tween_property(lbl, "modulate:a", peak_alpha, appear_dur) \
			.set_trans(Tween.TRANS_SINE)

		# Tween 2: drift (starts at same time as appear, independent duration)
		var tw_drift := create_tween()
		tw_drift.tween_interval(start)
		tw_drift.tween_property(lbl, "position",
			Vector2(px + drift_x, py + drift_y), drift_dur) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		# Tween 3: fade-out (independent delay and duration — this is the key)
		var tw_fade := create_tween()
		tw_fade.tween_interval(fade_delay)
		tw_fade.tween_property(lbl, "modulate:a", 0.0, fade_dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# After dissolve window, transition to confirmation text.
	# particle_layer is NOT queue_freed — _show_mailbox_sent_text hides all children.
	var seq := create_tween()
	seq.tween_interval(DISSOLVE_DUR + 0.10)
	seq.tween_callback(func() -> void:
		if not is_instance_valid(overlay):
			on_done.call()
			return
		_show_mailbox_sent_text(overlay, on_done))

func _show_mailbox_sent_text(overlay: Control, on_done: Callable) -> void:
	if not is_instance_valid(overlay):
		on_done.call()
		return

	# Hide remaining overlay children before showing confirmation
	for child: Node in overlay.get_children():
		if child is Control:
			(child as Control).visible = false

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.modulate.a = 0.0
	overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment    = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	# Envelope icon
	var icon_lbl := Label.new()
	icon_lbl.text = "[ ✉ ]"
	icon_lbl.add_theme_font_override("font", _make_font(300))
	icon_lbl.add_theme_font_size_override("font_size", 52)
	icon_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_lbl)

	# Primary text
	var sent_lbl := Label.new()
	sent_lbl.text = "Sent to mailbox"
	sent_lbl.add_theme_font_override("font", _make_font(700))
	sent_lbl.add_theme_font_size_override("font_size", 34)
	sent_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	sent_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sent_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sent_lbl)

	# Sub-text
	var sub_lbl := Label.new()
	sub_lbl.text = "(accessible via title screen)"
	sub_lbl.add_theme_font_size_override("font_size", 18)
	sub_lbl.add_theme_color_override("font_color", Color(0.45, 0.72, 0.80))
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub_lbl)

	# Fade in confirmation text
	var tw_in := create_tween()
	tw_in.tween_property(center, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

	# Hold for 2.5s then fade out entire overlay
	var seq := create_tween()
	seq.tween_interval(2.5)
	seq.tween_property(overlay, "modulate:a", 0.0, 0.45) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	seq.tween_callback(overlay.queue_free)
	seq.tween_callback(on_done)

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
	_refresh_contextual_hud_glows()

# ─────────────────────────────────────────────────────────────
# Shared Radial Helpers
# ─────────────────────────────────────────────────────────────

func _measure_nav_radial_chip(label_text: String) -> Vector2:
	var font := _make_font(500)
	var inner_w_max: float = NAV_RADIAL_ITEM_W_MAX - NAV_RADIAL_PAD_H
	var single_w: float = font.get_string_size(
		label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, NAV_RADIAL_FONT_SIZE).x
	var chip_w: float = NAV_RADIAL_ITEM_W_MAX
	if single_w <= inner_w_max:
		chip_w = clampf(single_w + NAV_RADIAL_PAD_H, NAV_RADIAL_ITEM_W_MIN, NAV_RADIAL_ITEM_W_MAX)
	var inner_w: float = chip_w - NAV_RADIAL_PAD_H
	var ml_size: Vector2 = font.get_multiline_string_size(
		label_text, HORIZONTAL_ALIGNMENT_CENTER, inner_w, NAV_RADIAL_FONT_SIZE, 2)
	var chip_h: float = clampf(ml_size.y + NAV_RADIAL_PAD_V, NAV_RADIAL_ITEM_H_MIN, NAV_RADIAL_ITEM_H_MAX)
	return Vector2(chip_w, chip_h)

func _nav_label_needs_tooltip(label_text: String, chip_w: float, chip_h: float) -> bool:
	var font := _make_font(500)
	var inner_w: float = chip_w - NAV_RADIAL_PAD_H
	var inner_h: float = chip_h - NAV_RADIAL_PAD_V
	var full_size: Vector2 = font.get_multiline_string_size(
		label_text, HORIZONTAL_ALIGNMENT_CENTER, inner_w, NAV_RADIAL_FONT_SIZE, -1)
	return full_size.y > inner_h + 0.5 or full_size.x > inner_w + 0.5

func _make_nav_radial_panel(
		label_text: String,
		target_id: String,
		item_cx: float,
		item_cy: float,
		vp: Vector2,
		pad: float,
		disabled: bool = false,
		locked_hint: String = "") -> PanelContainer:
	var chip_size: Vector2 = _measure_nav_radial_chip(label_text)
	var item_w: float = chip_size.x
	var item_h: float = chip_size.y
	var item_x: float = clampf(item_cx - item_w * 0.5, pad, vp.x - item_w - pad)
	var item_y: float = clampf(item_cy - item_h * 0.5, pad, vp.y - item_h - pad)
	var needs_tooltip: bool = _nav_label_needs_tooltip(label_text, item_w, item_h)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(item_w, item_h)
	panel.size       = Vector2(item_w, item_h)
	panel.position   = Vector2(item_x, item_y)
	panel.modulate.a = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	if disabled:
		sb.bg_color = Color(0.08, 0.08, 0.10, 0.72)
		sb.border_color = Color(0.35, 0.38, 0.42, 0.55)
	else:
		sb.bg_color = Color(0.04, 0.08, 0.20, 0.94)
		sb.border_color = Color(0.45, 0.70, 1.0, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12.0; sb.content_margin_right  = 12.0
	sb.content_margin_top  = 8.0;  sb.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	lbl.max_lines_visible     = 2
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	lbl.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", NAV_RADIAL_FONT_SIZE)
	lbl.add_theme_color_override("font_color",
		Color(0.48, 0.50, 0.54) if disabled else Color(0.88, 0.96, 1.0))
	lbl.add_theme_font_override("font", _make_font(500))
	panel.add_child(lbl)

	if disabled:
		panel.gui_input.connect(func(ev: InputEvent) -> void:
			if _is_press_event(ev):
				_show_toast(locked_hint if not locked_hint.is_empty() else "Locked"))
	else:
		panel.gui_input.connect(func(ev: InputEvent) -> void:
			if _is_press_event(ev):
				_on_radial_item_selected(target_id))

	var cap_tip: String = locked_hint if disabled and not locked_hint.is_empty() \
		else (label_text if needs_tooltip else "")
	if not disabled:
		panel.mouse_entered.connect(func() -> void:
			sb.bg_color = Color(0.10, 0.22, 0.48, 0.97)
			sb.border_color = Color(0.65, 0.88, 1.0, 1.0)
			if not cap_tip.is_empty():
				_tooltip_lbl.text = cap_tip
				_tooltip_panel.visible = true)
		panel.mouse_exited.connect(func() -> void:
			sb.bg_color = Color(0.04, 0.08, 0.20, 0.94)
			sb.border_color = Color(0.45, 0.70, 1.0, 0.85)
			if not cap_tip.is_empty():
				_hide_tooltip())
	elif not cap_tip.is_empty():
		panel.mouse_entered.connect(func() -> void:
			_tooltip_lbl.text = cap_tip
			_tooltip_panel.visible = true)
		panel.mouse_exited.connect(func() -> void: _hide_tooltip())
	return panel

func _add_radial_menu_panel(panel: Control, bucket: Array) -> void:
	if _radial_menu_layer != null:
		_radial_menu_layer.add_child(panel)
	else:
		_compass_root.add_child(panel)
	bucket.append(panel)
	_hook_cursor(panel)

func _is_press_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false

func _get_press_global_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).global_position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	return Vector2(-1.0, -1.0)

func _is_point_on_open_menu_ui(global_pos: Vector2) -> bool:
	var hits: Array = [_compass_hit, _setting_hit, _inv_hit, _chat_hit, _info_hit]
	for h: Variant in hits:
		if h is Control and (h as Control).visible:
			var c: Control = h as Control
			if c.get_global_rect().has_point(global_pos):
				return true
	if _back_btn != null and _back_btn.visible:
		if _back_btn.get_global_rect().has_point(global_pos):
			return true
	var all_panels: Array = []
	all_panels.append_array(_radial_items)
	all_panels.append_array(_setting_radial_items)
	all_panels.append_array(_inv_radial_items)
	all_panels.append_array(_chat_radial_items)
	for p: Variant in all_panels:
		if p is Control and (p as Control).visible:
			var c: Control = p as Control
			if c.get_global_rect().has_point(global_pos):
				return true
	if _info_open and _content_panel != null and _content_panel.visible:
		if _content_panel.get_global_rect().has_point(global_pos):
			return true
	return false

func _on_radial_overlay_gui_input(event: InputEvent) -> void:
	if not _is_press_event(event):
		return
	if _is_point_on_open_menu_ui(_get_press_global_position(event)):
		return
	_close_all_menus()
	if _radial_overlay != null:
		_radial_overlay.accept_event()

func _make_radial_panel(pos: Vector2, bg_color: Color, border_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(RADIAL_ITEM_W, RADIAL_ITEM_H)
	panel.size       = Vector2(RADIAL_ITEM_W, RADIAL_ITEM_H)
	panel.position   = pos
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

func _open_settings_menu_popup() -> void:
	if _settings_menu != null and is_instance_valid(_settings_menu):
		return
	var sm: Node = load("res://scenes/settings_menu.tscn").instantiate()
	sm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sm.z_index = 100
	_settings_menu = sm
	add_child(sm)
	sm.closed.connect(func() -> void:
		_settings_menu = null
		sm.queue_free())
	sm.tree_exiting.connect(func() -> void: _settings_menu = null)

func _show_confirm_dialog(title_text: String, body_text: String, on_confirm: Callable) -> void:
	_close_confirm_dialog()
	var vp_sz: Vector2 = get_viewport_rect().size

	var overlay := Control.new()
	overlay.z_index  = 60
	overlay.position = Vector2.ZERO
	overlay.size     = vp_sz
	_confirm_overlay = overlay
	add_child(overlay)

	var dimmer := ColorRect.new()
	dimmer.color        = Color(0.0, 0.0, 0.0, 0.60)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.position     = Vector2.ZERO
	dimmer.size         = vp_sz
	overlay.add_child(dimmer)

	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.14, 0.97)
	sb.set_border_width_all(2)
	sb.border_color = Color(1.0, 0.55, 0.45, 0.70)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	var dlg_size := Vector2(380.0, 200.0)
	panel.size         = dlg_size
	panel.position     = (vp_sz - dlg_size) * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 24.0; vbox.offset_right  = -24.0
	vbox.offset_top  = 20.0; vbox.offset_bottom = -20.0

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
		_close_confirm_dialog()
		on_confirm.call())
	btn_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.add_theme_color_override("font_color", Color(0.60, 0.65, 0.65))
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_close_confirm_dialog)
	btn_row.add_child(cancel_btn)

# ─────────────────────────────────────────────────────────────
# Node Rendering
# ─────────────────────────────────────────────────────────────

func _on_node_entered(node: ExplorationNode) -> void:
	_dismiss_all_popups()
	if _exit_vn_defer_enter:
		_pending_enter_node = node
		return
	_refresh_node(node)
	_refresh_contextual_hud_glows()

func _refresh_node(node: ExplorationNode) -> void:
	_exit_pending   = false
	_battle_pending = false
	var vars: Dictionary = ExplorationManager.get_all_vars()

	# Background — check conditional overrides first, fall back to base field
	var effective_bg: String = node.resolve_background(vars)
	if not effective_bg.is_empty() and effective_bg != _current_bg_path:
		_current_bg_path = effective_bg
		var tex: Texture2D = load(effective_bg) as Texture2D
		if tex != null:
			_bg_rect.texture = tex
		else:
			push_warning("ExplorationPlayer: bg '%s' not found." % effective_bg)

	# Music — check conditional overrides first, fall back to base field
	var effective_music: String = node.resolve_music(vars)
	if not effective_music.is_empty() and ResourceLoader.exists(effective_music):
		BGMManager.play_path(effective_music, 1.0, 0.5, 100.0, BGMManager.CONTEXT_VN)

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
	_title_lbl.text = node.resolve_title(vars)
	_desc_lbl.text  = ""
	_desc_lbl.append_text(node.resolve_description(vars))

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
			if node.vn_trigger_on_enter():
				if node.show_info_on_enter:
					_open_info_panel(func() -> void: _try_play_node_vn(node, true), true)
				else:
					_try_play_node_vn(node, true)
			else:
				_compass_set_visible(true)
		_:
			_content_panel.visible = false
			_choices_vbox.visible = false
			if node.vn_trigger_on_enter():
				if node.show_info_on_enter:
					_compass_set_visible(true)
					_open_info_panel(func() -> void: _try_play_node_vn(node, false), true)
				else:
					_try_play_node_vn(node, false)


# ─────────────────────────────────────────────────────────────
# Visual Novel Integration
# ─────────────────────────────────────────────────────────────

func _would_play_node_vn(node: ExplorationNode) -> bool:
	var vars: Dictionary = ExplorationManager.get_all_vars()
	var vn_path: String = node.resolve_vn_scene(vars)
	if vn_path.is_empty():
		return false
	if not FileAccess.file_exists(ProjectSettings.globalize_path(vn_path)):
		return false
	var play_once: bool = node.resolve_vn_play_once(vars)
	if play_once and ExplorationManager.is_vn_played(vn_path):
		return false
	return true

func _apply_pending_enter_node() -> void:
	if _pending_enter_node == null:
		_exit_vn_defer_enter = false
		return
	var pending: ExplorationNode = _pending_enter_node
	_pending_enter_node = null
	_exit_vn_defer_enter = false
	_refresh_node(pending)
	_refresh_contextual_hud_glows()

## Play the node's resolved VN scene when trigger conditions are met.
func _try_play_node_vn(node: ExplorationNode, is_story: bool = false) -> void:
	if not _would_play_node_vn(node):
		_compass_set_visible(true)
		_apply_pending_enter_node()
		return
	var vars: Dictionary = ExplorationManager.get_all_vars()
	var vn_path: String = node.resolve_vn_scene(vars)
	var play_once: bool = node.resolve_vn_play_once(vars)
	if not is_story:
		_compass_set_visible(false)
	_play_vn(vn_path, func() -> void: _on_vn_finished(node), play_once)

func _play_puzzle(puzzle_id: String, on_done: Callable, puzzle_params: Dictionary = {}) -> void:
	if _puzzle_playing or _vn_playing:
		return
	var pid: String = puzzle_id.strip_edges()
	if pid.is_empty():
		on_done.call(false)
		return
	if not ExplorationPuzzleDatabase.is_implemented(pid):
		var meta: Dictionary = ExplorationPuzzleDatabase.get_puzzle(pid)
		var label: String = str(meta.get("name", pid))
		_show_toast("Puzzle not implemented: %s" % label)
		on_done.call(false)
		return
	var scene_path: String = ExplorationPuzzleDatabase.get_scene_path(pid)
	var packed: Variant = load(scene_path)
	if packed == null or not packed is PackedScene:
		_show_toast("Failed to load puzzle scene.")
		on_done.call(false)
		return

	_puzzle_playing = true
	_dismiss_all_popups()
	_compass_set_visible(false)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = 94
	add_child(dim)

	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.z_index = 95
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	_puzzle_layer = layer

	var puzzle_node: Node = (packed as PackedScene).instantiate()
	if not puzzle_node is ExplorationPuzzleBase:
		push_warning("ExplorationPlayer: puzzle '%s' must extend ExplorationPuzzleBase." % pid)
		dim.queue_free()
		layer.queue_free()
		_puzzle_layer = null
		_puzzle_playing = false
		_compass_set_visible(true)
		on_done.call(false)
		return
	var puzzle: ExplorationPuzzleBase = puzzle_node as ExplorationPuzzleBase
	puzzle.setup(pid, puzzle_params)
	layer.add_child(puzzle_node)

	var cleanup := func() -> void:
		if is_instance_valid(dim):
			dim.queue_free()
		if is_instance_valid(layer):
			layer.queue_free()
		_puzzle_layer = null
		_puzzle_playing = false
		_compass_set_visible(true)

	puzzle.puzzle_completed.connect(func(success: bool) -> void:
		cleanup.call()
		on_done.call(success))

func _play_vn(path: String, on_done: Callable, play_once: bool = true) -> void:
	if _vn_playing or _puzzle_playing:
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

func _on_vn_finished(_node: ExplorationNode) -> void:
	# VN done — restore compass so player can navigate
	_compass_set_visible(true)
	_apply_pending_enter_node()

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
		get_tree().change_scene_to_file(dest)
		CheckerTransition.fade_in())

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
	_spots_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spots_layer.z_index      = 5  # above bg, below compass (30)
	add_child(_spots_layer)
	_spots_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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
	# Use full viewport width so x_norm 0-1 maps to the full background image width,
	# matching the coordinate picker in the editor.
	var bg_w: float = vp.x
	var bg_h: float = vp.y
	for i: int in node.clickable_spots.size():
		var spot_var: Variant = node.clickable_spots[i]
		if spot_var is Dictionary:
			_spawn_spot(spot_var as Dictionary, bg_w, bg_h, i)

func _spawn_spot(spot: Dictionary, bg_w: float, bg_h: float, spot_index: int = 0) -> void:
	# Check conditions — reuse ExplorationManager's connection-unlock logic (reads "conditions" key)
	if not ExplorationManager.is_connection_unlocked(spot):
		return
	# Skip one-time spots already interacted with this session
	if bool(spot.get("hide_after_interact", false)) and ExplorationManager.is_spot_interacted(ExplorationManager.current_node_id, spot_index):
		return

	var xn: float         = float(spot.get("x_norm",    0.5))
	var yn: float         = float(spot.get("y_norm",    0.5))
	var icon_path: String = str(spot.get("icon",        ""))
	var icon_scale: float = float(spot.get("icon_scale", 100.0))
	var tip: String       = str(spot.get("tooltip",     ""))

	# Build actions list; backward-compat: bare vn_scene field → play_vn action
	var actions: Array = []
	var raw_acts: Variant = spot.get("actions", [])
	if raw_acts is Array:
		actions = (raw_acts as Array).duplicate()
	var vn_legacy: String = str(spot.get("vn_scene", ""))
	if actions.is_empty() and not vn_legacy.is_empty():
		actions = [{"action": "play_vn", "key": "", "value": vn_legacy}]

	# Compute hit size: image (scaled) or 24×24 invisible fallback
	var hit_w: float = 24.0
	var hit_h: float = 24.0
	var has_icon: bool = not icon_path.is_empty() and ResourceLoader.exists(icon_path)
	if has_icon:
		var tex: Texture2D = load(icon_path) as Texture2D
		if tex != null:
			var nat: Vector2 = tex.get_size()
			hit_w = nat.x * icon_scale / 100.0
			hit_h = nat.y * icon_scale / 100.0

	var hit := Control.new()
	hit.position     = Vector2(xn * bg_w - hit_w * 0.5, yn * bg_h - hit_h * 0.5)
	hit.size         = Vector2(hit_w, hit_h)
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	_spots_layer.add_child(hit)

	if has_icon:
		var icon_tr := TextureRect.new()
		icon_tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		icon_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_tr.texture      = load(icon_path) as Texture2D
		icon_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hit.add_child(icon_tr)

	var cap_tip:   String = tip
	var cap_acts:  Array  = actions
	var cap_hide:  bool   = bool(spot.get("hide_after_interact", false))
	var cap_node:  String = ExplorationManager.current_node_id
	var cap_index: int    = spot_index
	var puzzle_gated: bool = _spot_actions_have_puzzle_gate(cap_acts)
	var apply_hide := func() -> void:
		hit.visible = false
		ExplorationManager.mark_spot_interacted(cap_node, cap_index)
	hit.mouse_entered.connect(func() -> void: _on_spot_hover_enter(cap_tip, hit))
	hit.mouse_exited.connect(func() -> void:  _on_spot_hover_exit())
	hit.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				var hide_cb: Callable = Callable()
				if cap_hide:
					if puzzle_gated:
						hide_cb = apply_hide
					else:
						apply_hide.call()
				_on_spot_triggered(cap_acts, hide_cb))

func _on_spot_hover_enter(tooltip_text: String, spot_hit: Control) -> void:
	_hovering_spot    = true
	_hovered_spot_hit = spot_hit
	if _magnifier_tex != null:
		Input.set_custom_mouse_cursor(_magnifier_tex, Input.CURSOR_ARROW, Vector2(8.0, 8.0))
	if not tooltip_text.is_empty() and _tooltip_panel != null:
		_tooltip_lbl.text      = tooltip_text
		_tooltip_panel.visible = true

func _on_spot_hover_exit() -> void:
	_hovering_spot    = false
	_hovered_spot_hit = null
	Input.set_custom_mouse_cursor(_default_tex, Input.CURSOR_ARROW, Vector2(4.0, 4.0))
	_hide_tooltip()

func _hide_tooltip() -> void:
	if _tooltip_panel != null:
		_tooltip_panel.visible = false

func _spot_actions_have_puzzle_gate(actions: Array) -> bool:
	for act_var: Variant in actions:
		if act_var is Dictionary and str((act_var as Dictionary).get("action", "")) == "play_puzzle":
			return true
	return false

func _on_spot_triggered(actions: Array, hide_on_success: Callable = Callable()) -> void:
	_register_exploration_activity()
	if _vn_playing or _puzzle_playing or actions.is_empty():
		return
	_on_spot_hover_exit()   # restore cursor before any action takes over
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	var puzzle_id: String = ""
	var puzzle_params: Dictionary = {}
	var remaining: Array = []
	for act_var: Variant in actions:
		if not act_var is Dictionary:
			continue
		var act: Dictionary = act_var as Dictionary
		if str(act.get("action", "")) == "play_puzzle":
			if puzzle_id.is_empty():
				var val: String = str(act.get("value", "")).strip_edges()
				var key: String = str(act.get("key", "")).strip_edges()
				puzzle_id = val if not val.is_empty() else key
				if not val.is_empty() and not key.is_empty():
					puzzle_params = ExplorationPuzzleBase.parse_params(key)
			continue
		remaining.append(act)
	if not puzzle_id.is_empty():
		_play_puzzle(puzzle_id, func(success: bool) -> void:
			if success:
				if hide_on_success.is_valid():
					hide_on_success.call()
				_execute_spot_actions(remaining), puzzle_params)
			# cancel/fail: close puzzle overlay only — spot stays active for retry
	else:
		if hide_on_success.is_valid():
			hide_on_success.call()
		_execute_spot_actions(actions)

func _execute_spot_actions(actions: Array) -> void:
	# Collect non-sequenced actions and the optional VN + navigate targets
	var vn_path:       String = ""
	var vn_play_once:  bool  = true
	var nav_target:    String = ""
	var instant_events: Array = []
	for act_var: Variant in actions:
		if not act_var is Dictionary:
			continue
		var act: Dictionary = act_var as Dictionary
		var action: String  = str(act.get("action", ""))
		var key: String     = str(act.get("key",    ""))
		var value: String   = str(act.get("value",  ""))
		match action:
			"give_item":
				ExplorationManager.add_item(key if not key.is_empty() else value)
			"remove_item":
				ExplorationManager.remove_item(key if not key.is_empty() else value)
			"set_var":
				ExplorationManager.set_var(key, value)
			"give_credits", "set_flag", "give_booster_pack":
				ExplorationManager.process_events([act])
			"show_message":
				_show_toast(value)
			"play_sfx":
				if not value.is_empty() and ResourceLoader.exists(value):
					var sfx := AudioStreamPlayer.new()
					sfx.stream = load(value) as AudioStream
					sfx.bus    = "SFX"
					add_child(sfx)
					sfx.play()
					sfx.finished.connect(sfx.queue_free)
			"play_vn":
				if not value.is_empty():
					vn_path = value
					vn_play_once = bool(act.get("play_once", true))
			"navigate_to":
				if not value.is_empty():
					nav_target = value
	# VN plays first; navigate fires in its completion callback
	if not vn_path.is_empty():
		if vn_play_once and ExplorationManager.is_vn_played(vn_path):
			_compass_set_visible(true)
			if not nav_target.is_empty():
				_navigate_with_fade(func() -> void: ExplorationManager.navigate_to(nav_target))
		else:
			_play_vn(vn_path, func() -> void:
				_compass_set_visible(true)
				if not nav_target.is_empty():
					_navigate_with_fade(func() -> void: ExplorationManager.navigate_to(nav_target)),
				vn_play_once)
	elif not nav_target.is_empty():
		_navigate_with_fade(func() -> void: ExplorationManager.navigate_to(nav_target))

func _process(delta: float) -> void:
	# Compass idle hint — lowest priority; blocked while chat/inventory glow active.
	if _can_track_compass_idle() and _can_start_compass_idle_timer():
		if not _hud_glow_active.get("compass", false):
			_idle_elapsed += delta
			if _idle_elapsed >= COMPASS_IDLE_HINT_DELAY:
				_start_hud_glow("compass")
	elif _hud_glow_active.get("compass", false):
		_dismiss_hud_glow("compass", false)
	for glow_key: String in ["compass", "inventory", "chat"]:
		if _hud_glow_active.get(glow_key, false):
			_sync_hud_glow_position(glow_key)

	# Auto-dismiss: cancel timer while hovering panel or info icon; start it on unhover
	if _info_open:
		var over: bool = _is_over_info_panel_or_icon()
		if over and not _info_panel_hovered:
			# mouse just entered — cancel pending timer
			_info_auto_dismiss_timer = null
		elif not over and _info_panel_hovered and not _transition_active and not _info_wait_for_mouse:
			# mouse just left (transition settled, mouse-move wait cleared) — start dismiss timer
			_on_info_panel_mouse_exited()
		_info_panel_hovered = over
	# Tooltip: anchor to top-right of the hovered spot (not the cursor).
	if _tooltip_panel != null and _tooltip_panel.visible \
			and _hovered_spot_hit != null and is_instance_valid(_hovered_spot_hit):
		var vp: Vector2 = get_viewport_rect().size
		var tp: Vector2 = _tooltip_panel.size
		var sr: Rect2   = _hovered_spot_hit.get_global_rect()
		const GAP: float = 3.0
		var tx: float = sr.position.x + sr.size.x + GAP
		var ty: float = sr.position.y - tp.y - GAP
		# Clamp so tooltip stays on-screen
		tx = clampf(tx, 4.0, vp.x - tp.x - 4.0)
		ty = clampf(ty, 4.0, vp.y - tp.y - 4.0)
		_tooltip_panel.position = Vector2(tx, ty)
	# Cursor: finger over interactive elements, default otherwise
	if not _hovering_spot:
		if _mouse_over_interactive():
			if _finger_tex != null:
				Input.set_custom_mouse_cursor(_finger_tex, Input.CURSOR_ARROW, Vector2(12.0, 4.0))
		else:
			Input.set_custom_mouse_cursor(_default_tex, Input.CURSOR_ARROW, Vector2(4.0, 4.0))

func _exit_tree() -> void:
	for tw: Variant in _hud_glow_tweens.values():
		if tw is Tween and (tw as Tween).is_valid():
			(tw as Tween).kill()
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
	# When the panel is waiting for mouse movement before allowing auto-dismiss,
	# clear the flag on first motion and immediately start dismiss logic if needed.
	if event is InputEventMouseMotion and _info_wait_for_mouse and _info_open:
		_info_wait_for_mouse   = false
		_info_mouse_wait_timer = null   # cancel 5s fallback
		if not _transition_active and not _is_over_info_panel_or_icon():
			_on_info_panel_mouse_exited()

func _is_modified_key(key: InputEventKey) -> bool:
	return key.meta_pressed or key.ctrl_pressed or key.alt_pressed or key.shift_pressed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var ke := event as InputEventKey
		if ke.keycode == KEY_F3:
			_toggle_debug()
			get_viewport().set_input_as_handled()
		elif ke.keycode == KEY_ESCAPE and not _is_modified_key(ke):
			if _item_preview != null:
				_close_item_preview()
			elif _compass_open or _setting_open or _inv_open:
				_close_all_menus()
			elif ExplorationManager.can_go_back():
				SFXManager.play(SFXManager.SFX_CANCEL)
				ExplorationManager.go_back()
			get_viewport().set_input_as_handled()

# Soft radial cyan halo for the compass idle hint (fade-to-transparent edges).
class CompassIdleGlow extends Control:
	const LAYERS: int = 20
	const GLOW_COLOR: Color = Color(0.0, 0.95, 0.90)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		var outer_r: float = minf(size.x, size.y) * 0.5
		# Paint outer→inner rings; centre stacks brighter, edge fades to nothing.
		for i: int in range(LAYERS, 0, -1):
			var t: float = float(i) / float(LAYERS)
			var radius: float = outer_r * t
			if radius <= 0.5:
				continue
			var alpha: float = pow(1.0 - t, 2.4) * 0.50
			if alpha <= 0.001:
				continue
			draw_circle(center, radius, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, alpha))
