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
##   Ctrl/Cmd+Shift+A toggles the admin console (dev builds / editor only).
##   Click the [DBG] button in the top-right corner for the same effect.

const VN_PLAYER_SCENE: PackedScene = preload("res://scenes/vn_player.tscn")
const COMPASS_ICON: String     = "res://assets/textures/ui/decorations/ui_icon_compass.png"
const SETTING_ICON: String     = "res://assets/textures/ui/decorations/ui_icon_exploration_setting.png"
const INVENTORY_ICON: String   = "res://assets/textures/ui/decorations/ui_exploration_inventory.png"
const CHAT_ICON: String        = "res://assets/textures/ui/decorations/ui_icon_exploration_chat.png"
const INFO_ICON: String        = "res://assets/textures/ui/decorations/ui_icon_exploration_info.png"
const DISSOLVE_FONT: Font      = preload("res://assets/fonts/digit-tech.7.ttf")
const COMPASS_SIZE: float  = 110.0  # icon width/height in pixels
const INFO_ICON_SIZE: float = 140.0  # info HUD icon — slightly larger than COMPASS_SIZE
const CHAT_ICON_SIZE: float = 128.0  # chat HUD icon — slightly larger than COMPASS_SIZE
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
const INV_RADIAL_ITEM_W_MIN: float = 180.0
const INV_RADIAL_ITEM_W_MAX: float = 340.0
const INV_RADIAL_ITEM_H_MIN: float = 54.0
const INV_RADIAL_ITEM_H_MAX: float = 80.0
const INV_RADIAL_FONT_SIZE: int    = 16
const INV_RADIAL_PAD_H: float      = 24.0   # total horizontal inset inside inventory chip
const INV_RADIAL_PAD_V: float      = 16.0   # total vertical inset inside inventory chip
const INV_RADIAL_ICON_SLOT: float  = 42.0   # 36px icon + 6px gap
const BG_AREA_FRACTION: float = 0.80  # fraction of viewport width used by the background area
const FLASHLIGHT_SHADER := preload("res://assets/shaders/exploration_flashlight.gdshader")
const FLASHLIGHT_HAND_NORM := Vector2(0.80, 0.94)   # 80% across left bg band, near bottom
const FLASHLIGHT_HALF_ANGLE := 0.42                 # radians (~24°)
const FLASHLIGHT_DIM_ALPHA := 0.93
const FLASHLIGHT_USE_CONE := false
const FLASHLIGHT_CIRCLE_RADIUS := 220.0
const FLASHLIGHT_CIRCLE_SOFT := 72.0
const FLASHLIGHT_ANGULAR_SOFT := 0.16
const FLASHLIGHT_LENGTH_SOFT := 96.0
const FLASHLIGHT_LENGTH_PAD := 1.12                 # beam reach past top-left corner
const FLASHLIGHT_ORIGIN_GLOW_RADIUS := 52.0
const FLASHLIGHT_ORIGIN_GLOW_SOFT := 34.0
const FLASHLIGHT_DUST_COUNT := 52
const FLASHLIGHT_DUST_MIN_SPEED := 6.0
const FLASHLIGHT_DUST_MAX_SPEED := 18.0
const ICON_SPACING: float  = 180.0  # horizontal gap between compass center and side icon centers
const ITEMS_PER_PAGE: int  = 7      # max items shown per inventory radial page

# ── UI references (all built in _build_ui) ────────────────────────────────
var _bg_rect: TextureRect          = null   # background image
var _bg_base: ColorRect            = null   # solid-colour fallback behind bg
var _vignette: ColorRect           = null   # static edge darken (hidden when flashlight on)
var _flashlight_overlay: ColorRect = null
var _flashlight_mat: ShaderMaterial = null
var _flashlight_time: float        = 0.0
var _flashlight_dust_layer: Control = null
var _flashlight_dust_motes: Array = []   # [{node, pos, vel, base_alpha, phase}]
var _title_lbl: Label              = null   # node title
var _type_badge_lbl: Label         = null   # coloured node-type label
var _desc_lbl: RichTextLabel       = null   # node description
var _choices_vbox: VBoxContainer   = null   # navigation choice buttons
var _back_btn: Button              = null   # go-back button
var _toast_lbl: Label              = null   # temporary message overlay
var _toast_tween: Tween            = null
var _save_toast_lbl: Label         = null   # bottom-left auto-save indicator
var _save_toast_tween: Tween       = null
const SAVE_TOAST_HOLD_SEC := 1.5
const SAVE_TOAST_FADE_SEC := 0.4
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
var _pending_info_panel_close_cb: Callable   = Callable()
var _pending_enter_vn_after_info: ExplorationNode = null
var _pending_enter_vn_is_story: bool       = false
var _enter_vn_after_info_scheduled: bool   = false
var _enter_vn_hud_blocked: bool            = false   # blocks HUD until enter-VN finishes
var _info_panel_hovered: bool                = false   # polled each frame; guards auto-dismiss
var _info_wait_for_mouse: bool               = false   # true after auto-open: dismiss blocked until mouse moves
var _info_mouse_wait_timer: SceneTreeTimer   = null    # 5s fallback: forces dismiss mode even without mouse move

# ── Item preview overlay (inventory tap-to-inspect) ──────────────────────
var _item_preview: Control        = null
var _settings_menu: Node          = null
var _exploration_options_overlay: Control = null
var _confirm_overlay: Control     = null

# ── Item-obtained overlay (awarded item cinematic) ────────────────────────
# Queue entries are either a String (item_id) or a Dictionary ({_mailbox_type, image_path, display_name}).
var _obtained_overlay: Control              = null
var _obtained_queue: Array                  = []
var _obtained_dismiss_timer: SceneTreeTimer = null
var _obtained_dismissing: bool              = false

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
var _hovered_nav_panel: Control    = null   # nav-choice panel currently being hovered

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	set_process_unhandled_input(true)

	_build_ui()
	_connect_signals()

	# VN handoff complete — exploration nodes own BGM from here on.
	ExplorationManager.keep_vn_bgm = false

	# Returning from a battle? Show result then refresh.
	if not ExplorationManager.pending_battle_result.is_empty():
		_handle_post_battle_result()
	elif ExplorationManager.is_session_active and ExplorationManager.current_node != null:
		_refresh_node(ExplorationManager.current_node)
	elif ExplorationManager.restore_saved_session():
		# restore_saved_session emits node_entered → _refresh_node (applies saved BGM too).
		if ExplorationManager.current_node != null:
			_show_toast("Session resumed.")
		else:
			_show_no_session_error()
	else:
		_show_no_session_error()

	CheckerTransition.fade_in()
	call_deferred("_refresh_contextual_hud_glows")
	_refresh_flashlight_state()

func _connect_signals() -> void:
	ExplorationManager.node_entered.connect(_on_node_entered)
	ExplorationManager.node_exited.connect(_on_node_exited)
	ExplorationManager.message_posted.connect(_show_toast)
	ExplorationManager.session_saved.connect(_show_save_toast)
	ExplorationManager.item_obtained.connect(_on_item_obtained)
	ExplorationManager.mailbox_reward_granted.connect(_on_mailbox_reward_granted)
	ExplorationManager.inventory_changed.connect(_on_exploration_state_changed)
	ExplorationManager.var_changed.connect(_on_var_changed)
	ExplorationManager.end_exploration_requested.connect(_do_end_exploration)
	ExplorationManager.end_exploration_vn_requested.connect(_do_end_exploration_with_vn)
	if not FontManager.fonts_changed.is_connected(_on_fonts_changed):
		FontManager.fonts_changed.connect(_on_fonts_changed)

func _on_fonts_changed() -> void:
	FontManager.refresh_tree(self)

# ─────────────────────────────────────────────────────────────
# UI Construction
# ─────────────────────────────────────────────────────────────

func _make_font(weight: int) -> Font:
	return FontManager.make_font("primary", weight)

func _tag_ui(node: Control, property: String, weight: int = 400) -> void:
	FontManager.tag_font(node, property, "primary", weight)

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
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.color        = Color(0.0, 0.0, 0.0, 0.55)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)

	# ── Flashlight dim overlay (full screen incl. info panel; session var flashlight=1) ──
	_flashlight_mat = ShaderMaterial.new()
	_flashlight_mat.shader = FLASHLIGHT_SHADER
	_flashlight_mat.set_shader_parameter("beam_half_angle", FLASHLIGHT_HALF_ANGLE)
	_flashlight_mat.set_shader_parameter("angular_softness", FLASHLIGHT_ANGULAR_SOFT)
	_flashlight_mat.set_shader_parameter("length_softness", FLASHLIGHT_LENGTH_SOFT)
	_flashlight_mat.set_shader_parameter("dim_alpha", FLASHLIGHT_DIM_ALPHA)
	_flashlight_mat.set_shader_parameter("use_cone", FLASHLIGHT_USE_CONE)
	_flashlight_mat.set_shader_parameter("circle_radius", FLASHLIGHT_CIRCLE_RADIUS)
	_flashlight_mat.set_shader_parameter("circle_softness", FLASHLIGHT_CIRCLE_SOFT)
	_flashlight_mat.set_shader_parameter("origin_glow_radius", FLASHLIGHT_ORIGIN_GLOW_RADIUS)
	_flashlight_mat.set_shader_parameter("origin_glow_soft", FLASHLIGHT_ORIGIN_GLOW_SOFT)
	_flashlight_overlay = ColorRect.new()
	_flashlight_overlay.material = _flashlight_mat
	_flashlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flashlight_overlay.z_index = 22
	_flashlight_overlay.visible = false
	add_child(_flashlight_overlay)
	_flashlight_dust_layer = Control.new()
	_flashlight_dust_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flashlight_dust_layer.z_index = 23
	_flashlight_dust_layer.visible = false
	add_child(_flashlight_dust_layer)
	_build_flashlight_dust_motes()

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
	content.z_index = 24   # keep info panel above flashlight dim overlay (z=22)
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
	_tag_ui(_title_lbl, "font", 700)
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
	_tag_ui(_desc_lbl, "normal_font", 400)
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
	_tag_ui(who_hdr, "font", 700)
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
	GameDialog.style_menu_button(_back_btn)
	_back_btn.pressed.connect(_on_back_pressed)
	vbox.add_child(_back_btn)

	if BuildConfig.admin_tools_enabled():
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

	# ── Compass radial navigation ─────────────────────────────
	_build_compass_system()

	# ── Toast label ───────────────────────────────────────────
	_toast_lbl = Label.new()
	_toast_lbl.layout_mode  = 1
	_toast_lbl.anchor_left  = 0.0;  _toast_lbl.anchor_right  = 1.0
	_toast_lbl.anchor_top   = 0.0;  _toast_lbl.anchor_bottom = 0.0
	_toast_lbl.offset_left  = 16.0; _toast_lbl.offset_right  = -16.0
	_toast_lbl.offset_top   = 16.0; _toast_lbl.offset_bottom = 80.0
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tag_ui(_toast_lbl, "font", 700)
	_toast_lbl.add_theme_font_size_override("font_size", 28)
	_toast_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
	_toast_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_toast_lbl.add_theme_constant_override("shadow_offset_x", 2)
	_toast_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_toast_lbl.modulate.a    = 0.0
	_toast_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_lbl)

	_save_toast_lbl = Label.new()
	_save_toast_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_save_toast_lbl.offset_left = 16.0
	_save_toast_lbl.offset_bottom = -12.0
	_save_toast_lbl.offset_top = -32.0
	_tag_ui(_save_toast_lbl, "font", 400)
	_save_toast_lbl.add_theme_font_size_override("font_size", 13)
	_save_toast_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.72))
	_save_toast_lbl.text = "Game saved."
	_save_toast_lbl.modulate.a = 0.0
	_save_toast_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_save_toast_lbl.z_index = 50
	add_child(_save_toast_lbl)

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
	if _flashlight_overlay != null and _flashlight_overlay.visible:
		_layout_flashlight_overlay()
	if _flashlight_dust_layer != null and _flashlight_dust_layer.visible:
		_layout_flashlight_dust_layer()
	_content_panel.position = Vector2(sw * BG_AREA_FRACTION, 0.0)
	_content_panel.size     = Vector2(sw * (1.0 - BG_AREA_FRACTION), sh)
	if _radial_overlay != null:
		_radial_overlay.size = vp_size
	if _radial_menu_layer != null:
		_radial_menu_layer.size = vp_size
	if _compass_root != null:
		_layout_compass_hud(vp_size, true)

## Recompute and apply bottom HUD icon positions from the current viewport size.
func _layout_compass_hud(vp: Vector2, close_open_menus: bool = false) -> void:
	if _compass_root == null or vp.x <= 0.0 or vp.y <= 0.0:
		return
	if close_open_menus:
		if _compass_open:
			_close_compass_menu(false)
		if _setting_open:
			_close_setting_menu(false)
		if _inv_open:
			_close_inventory_menu(false)
		if _chat_open:
			_close_chat_menu(false)

	var bottom_y: float = vp.y - COMPASS_SIZE - 24.0

	_compass_idle_pos = Vector2(vp.x * 0.5 - COMPASS_SIZE * 0.5, bottom_y)
	_compass_center_pos = Vector2(vp.x * 0.5 - COMPASS_SIZE * 0.5, vp.y * 0.5 - COMPASS_SIZE * 0.5)
	_setting_idle_pos = Vector2(vp.x * 0.5 + 2.0 * ICON_SPACING - COMPASS_SIZE * 0.5, bottom_y)
	_info_idle_pos = Vector2(
		vp.x * 0.5 + ICON_SPACING - INFO_ICON_SIZE * 0.5,
		bottom_y + COMPASS_SIZE * 0.5 - INFO_ICON_SIZE * 0.5)
	_inv_idle_pos = Vector2(vp.x * 0.5 - 2.0 * ICON_SPACING - COMPASS_SIZE * 0.5, bottom_y)
	_chat_idle_pos = Vector2(
		vp.x * 0.5 - ICON_SPACING - CHAT_ICON_SIZE * 0.5,
		bottom_y + COMPASS_SIZE * 0.5 - CHAT_ICON_SIZE * 0.5)

	if _compass_icon != null and not _compass_open:
		_compass_icon.position = _compass_idle_pos
	if _compass_hit != null and not _compass_open:
		_compass_hit.position = _compass_idle_pos
	if _setting_icon != null:
		_setting_icon.position = _setting_idle_pos
	if _setting_hit != null:
		_setting_hit.position = _setting_idle_pos
	if _info_icon != null:
		_info_icon.position = _info_idle_pos
	if _info_hit != null:
		_info_hit.position = _info_idle_pos
	if _inv_icon != null:
		_inv_icon.position = _inv_idle_pos
	if _inv_hit != null:
		_inv_hit.position = _inv_idle_pos
	if _chat_icon != null:
		_chat_icon.position = _chat_idle_pos
	if _chat_hit != null:
		_chat_hit.position = _chat_idle_pos
	if _chat_empty_lbl != null:
		var chat_lbl_w: float = CHAT_ICON_SIZE + 120.0
		_chat_empty_lbl.position = Vector2(
			_chat_idle_pos.x + CHAT_ICON_SIZE * 0.5 - chat_lbl_w * 0.5,
			_chat_idle_pos.y - 36.0)
	if _inv_empty_lbl != null:
		var inv_lbl_w: float = COMPASS_SIZE + 120.0
		_inv_empty_lbl.position = Vector2(
			_inv_idle_pos.x + COMPASS_SIZE * 0.5 - inv_lbl_w * 0.5,
			_inv_idle_pos.y - 36.0)
	for glow_key: String in ["compass", "inventory", "chat"]:
		_sync_hud_glow_position(glow_key)

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

	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp == Vector2.ZERO:
		vp = Vector2(1600.0, 900.0)

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

	# Radial submenu panels and HUD hit buttons live here (not under MOUSE_FILTER_IGNORE
	# compass_root) so taps reliably reach them above the dismiss overlay.
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
	_compass_hit.z_index  = 10
	_compass_hit.pressed.connect(_on_compass_clicked)
	_radial_menu_layer.add_child(_compass_hit)

	# ── Setting icon (far right, +2×spacing) ────────────────
	_setting_icon          = TextureRect.new()
	_setting_icon.position = _setting_idle_pos
	_setting_icon.size     = Vector2(COMPASS_SIZE, COMPASS_SIZE)
	_setting_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_setting_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(SETTING_ICON):
		_setting_icon.texture = load(SETTING_ICON) as Texture2D
	_compass_root.add_child(_setting_icon)

	_setting_hit = _make_icon_hit_button(_setting_idle_pos)
	_setting_hit.z_index = 10
	_setting_hit.pressed.connect(_on_setting_clicked)
	_radial_menu_layer.add_child(_setting_hit)

	# ── Info icon (+1×spacing) ────────────────────────────────
	_info_icon          = TextureRect.new()
	_info_icon.position = _info_idle_pos
	_info_icon.size     = Vector2(INFO_ICON_SIZE, INFO_ICON_SIZE)
	_info_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_info_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(INFO_ICON):
		_info_icon.texture = load(INFO_ICON) as Texture2D
	_compass_root.add_child(_info_icon)

	_info_hit = _make_icon_hit_button(_info_idle_pos, INFO_ICON_SIZE)
	_info_hit.z_index = 10
	_info_hit.pressed.connect(_on_info_clicked)
	_radial_menu_layer.add_child(_info_hit)

	# ── Inventory icon (far left, −2×spacing) ────────────────
	_inv_icon          = TextureRect.new()
	_inv_icon.position = _inv_idle_pos
	_inv_icon.size     = Vector2(COMPASS_SIZE, COMPASS_SIZE)
	_inv_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_inv_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(INVENTORY_ICON):
		_inv_icon.texture = load(INVENTORY_ICON) as Texture2D
	_compass_root.add_child(_inv_icon)

	_inv_hit = _make_icon_hit_button(_inv_idle_pos)
	_inv_hit.z_index = 10
	_inv_hit.pressed.connect(_on_inventory_clicked)
	_radial_menu_layer.add_child(_inv_hit)

	# ── Chat icon (−1×spacing) ────────────────────────────────
	_chat_icon          = TextureRect.new()
	_chat_icon.position = _chat_idle_pos
	_chat_icon.size     = Vector2(CHAT_ICON_SIZE, CHAT_ICON_SIZE)
	_chat_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_chat_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(CHAT_ICON):
		_chat_icon.texture = load(CHAT_ICON) as Texture2D
	_compass_root.add_child(_chat_icon)

	_chat_hit = _make_icon_hit_button(_chat_idle_pos, CHAT_ICON_SIZE)
	_chat_hit.z_index = 10
	_chat_hit.pressed.connect(_on_chat_clicked)
	_radial_menu_layer.add_child(_chat_hit)

	# Empty-chat overlay label
	_chat_empty_lbl = Label.new()
	_chat_empty_lbl.layout_mode = 0
	var chat_lbl_w: float = CHAT_ICON_SIZE + 120.0
	_chat_empty_lbl.position = Vector2(
		_chat_idle_pos.x + CHAT_ICON_SIZE * 0.5 - chat_lbl_w * 0.5,
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

	_layout_compass_hud(vp)

## Build an invisible full-size hit button for an icon at given position.
func _make_icon_hit_button(pos: Vector2, size: float = COMPASS_SIZE) -> Button:
	var btn := Button.new()
	btn.position     = pos
	btn.size         = Vector2(size, size)
	btn.flat         = true
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxEmpty.new()
	for state: String in ["normal","hover","pressed","focus","disabled"]:
		btn.add_theme_stylebox_override(state, sb)
	return btn

## No-op kept for call-site compatibility.
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
	_refresh_spots_for_state()

func _on_var_changed(key: String, value: String) -> void:
	_refresh_contextual_hud_glows()
	_refresh_spots_for_state()
	if key == "flashlight":
		_refresh_flashlight_state()
	var node: ExplorationNode = ExplorationManager.current_node
	if node == null or _vn_playing or _puzzle_playing:
		return
	_apply_node_music(node)
	if not node.vn_var_change_matches(key, value):
		return
	_try_play_node_vn(node, node.node_type == ExplorationNode.NodeType.STORY)

## Re-evaluate clickable spot conditions after inventory or variable changes.
func _refresh_spots_for_state() -> void:
	if _vn_playing or _puzzle_playing or _transition_active:
		return
	var node: ExplorationNode = ExplorationManager.current_node
	if node != null:
		_rebuild_spots(node)

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

func _is_char_removed_from_room(char_data: Dictionary, char_index: int) -> bool:
	if not bool(char_data.get("remove_after_talk", false)):
		return false
	return ExplorationManager.is_char_talked(ExplorationManager.current_node_id, char_index)

func _char_index_for_data(char_data: Dictionary) -> int:
	var node: ExplorationNode = ExplorationManager.current_node
	if node == null:
		return -1
	var target_name: String = str(char_data.get("name", ""))
	var target_vn: String = str(char_data.get("vn_scene", ""))
	for i: int in node.characters.size():
		var entry: Variant = node.characters[i]
		if not entry is Dictionary:
			continue
		var cd: Dictionary = entry as Dictionary
		if str(cd.get("name", "")) == target_name and str(cd.get("vn_scene", "")) == target_vn:
			return i
	return -1

func _has_canon_story_chat() -> bool:
	var node: ExplorationNode = ExplorationManager.current_node
	if node == null:
		return false
	for i: int in node.characters.size():
		var char_data: Variant = node.characters[i]
		if not char_data is Dictionary:
			continue
		var cd: Dictionary = char_data as Dictionary
		if not bool(cd.get("canon_story", false)):
			continue
		if not ExplorationManager.is_connection_unlocked(cd):
			continue
		if _is_char_removed_from_room(cd, i):
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

func _is_info_panel_showing() -> bool:
	if _info_open:
		return true
	if _content_panel == null or not _content_panel.visible:
		return false
	return _title_lbl.visible or _desc_lbl.visible

func _dismiss_info_panel_for_hud() -> void:
	if _is_info_panel_showing():
		_close_info_panel(true, false)

## Keep the dismiss overlay in sync: STOP only while a radial menu is open; IGNORE while info-only.
func _sync_radial_overlay_state() -> void:
	if _radial_overlay == null:
		return
	var any_radial_menu: bool = _compass_open or _setting_open or _inv_open or _chat_open
	if any_radial_menu:
		_radial_overlay.visible = true
		_radial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	elif _is_info_panel_showing():
		_radial_overlay.visible = true
		_radial_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		_radial_overlay.visible = false
		_radial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

func _hud_icon_at_point(global_pos: Vector2) -> String:
	if _compass_hit != null and _compass_hit.visible and _compass_hit.get_global_rect().has_point(global_pos):
		return "compass"
	if _setting_hit != null and _setting_hit.visible and _setting_hit.get_global_rect().has_point(global_pos):
		return "setting"
	if _inv_hit != null and _inv_hit.visible and _inv_hit.get_global_rect().has_point(global_pos):
		return "inventory"
	if _chat_hit != null and _chat_hit.visible and _chat_hit.get_global_rect().has_point(global_pos):
		return "chat"
	if _info_hit != null and _info_hit.visible and _info_hit.get_global_rect().has_point(global_pos):
		return "info"
	return ""

func _dispatch_hud_click(which: String) -> void:
	if _enter_vn_hud_blocked:
		return
	match which:
		"compass":
			_on_compass_clicked()
		"setting":
			_on_setting_clicked()
		"inventory":
			_on_inventory_clicked()
		"chat":
			_on_chat_clicked()
		"info":
			_on_info_clicked()

## Close every HUD menu except [param except_id], then continue the tapped icon's action.
func _close_other_hud_menus(except_id: String) -> void:
	if except_id != "compass" and _compass_open:
		_close_compass_menu(false)
	if except_id != "setting" and _setting_open:
		_close_setting_menu(false)
	if except_id != "inventory" and _inv_open:
		_close_inventory_menu(false)
	if except_id != "chat" and _chat_open:
		_close_chat_menu(false)
	if except_id != "info" and _is_info_panel_showing():
		_close_info_panel(true, false)

func _on_compass_clicked() -> void:
	if _enter_vn_hud_blocked:
		return
	_register_exploration_activity()
	_dismiss_info_panel_for_hud()
	if _compass_animating:
		return
	if _compass_open:
		_close_compass_menu()
		return
	_close_other_hud_menus("compass")
	_open_compass_menu()

func _is_hud_menu_active(which: String) -> bool:
	match which:
		"compass":   return _compass_open
		"setting":   return _setting_open
		"inventory": return _inv_open
		"chat":      return _chat_open
		"info":      return _is_info_panel_showing()
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
	_close_info_panel(true, false)

func _close_settings_menu_popup() -> void:
	if _settings_menu != null and is_instance_valid(_settings_menu):
		_settings_menu.queue_free()
	_settings_menu = null

func _close_confirm_dialog() -> void:
	GameDialog.close_overlay(self)
	_confirm_overlay = null

func _show_confirm_dialog(title_text: String, body_text: String, on_confirm: Callable) -> void:
	_close_confirm_dialog()
	_confirm_overlay = GameDialog.confirmation_overlay(
		self,
		title_text,
		body_text,
		"Yes",
		"Cancel",
		func() -> void:
			_confirm_overlay = null
			on_confirm.call(),
		func() -> void: _confirm_overlay = null,
		GameDialog.DEFAULT_MIN_WIDTH,
		60)

func _close_exploration_options_popup() -> void:
	if _exploration_options_overlay != null and is_instance_valid(_exploration_options_overlay):
		_exploration_options_overlay.queue_free()
	_exploration_options_overlay = null

func _dismiss_all_popups() -> void:
	_dismiss_all_hud_menus(false)
	_hide_tooltip()
	_close_item_preview()
	_close_settings_menu_popup()
	_close_exploration_options_popup()
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
	if _enter_vn_hud_blocked:
		return
	if _compass_animating or _compass_open:
		return
	var node: ExplorationNode = ExplorationManager.current_node
	if node == null:
		return
	# Close other menus before opening compass
	_close_setting_menu(false)
	_close_inventory_menu(false)
	_close_chat_menu(false)
	_close_info_panel(true, false)
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

	# Build and animate radial items
	_spawn_radial_items(menu_connections)
	_sync_radial_overlay_state()

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
	_sync_radial_overlay_state()

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
	_sync_radial_overlay_state()

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

## Apply navigation state, save, then fade — save completes before the visual transition.
func _navigate_with_fade(apply_navigation: Callable) -> void:
	if not apply_navigation.is_valid():
		return
	if _nav_fade_tween and _nav_fade_tween.is_valid():
		_nav_fade_tween.kill()
	# Block spot rebuilds while state applies — on_enter set_var would otherwise
	# spawn the destination node's icons over the previous room's background.
	_transition_active = true
	_clear_spots()
	_set_spots_layer_visible(false)
	if not apply_navigation.call():
		_transition_active = false
		_set_spots_layer_visible(true)
		_refresh_spots_for_state()
		return
	ExplorationManager.save_navigation_checkpoint()
	_nav_fade_rect.modulate.a = 0.0
	_nav_fade_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_nav_fade_tween.tween_property(_nav_fade_rect, "modulate:a", 1.0, 0.5)
	_nav_fade_tween.tween_callback(func() -> void:
		ExplorationManager.commit_navigation_visuals()
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_nav_fade_rect, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func() -> void:
			_transition_active = false
			_set_spots_layer_visible(true)))

func _on_radial_item_selected(target_id: String) -> void:
	_register_exploration_activity()
	if target_id.is_empty():
		return
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_close_compass_menu()
	_navigate_with_fade(func() -> bool: return ExplorationManager.apply_navigate_to(target_id))

# ─────────────────────────────────────────────────────────────
# Setting Radial Menu
# ─────────────────────────────────────────────────────────────

func _on_setting_clicked() -> void:
	if _enter_vn_hud_blocked:
		return
	_register_exploration_activity()
	_dismiss_info_panel_for_hud()
	if _setting_animating:
		return
	if _setting_open:
		_close_setting_menu()
		return
	_close_other_hud_menus("setting")
	_open_setting_menu()

func _open_setting_menu() -> void:
	if _enter_vn_hud_blocked:
		return
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

	_spawn_setting_radial_items(center_pos)
	_sync_radial_overlay_state()

func _close_setting_menu(animated: bool = true) -> void:
	if _setting_animating and not _setting_open:
		return
	_setting_open = false
	for item: Variant in _setting_radial_items:
		if is_instance_valid(item as Node):
			(item as Node).queue_free()
	_setting_radial_items.clear()
	_sync_radial_overlay_state()
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
	_sync_radial_overlay_state()

func _spawn_setting_radial_items(center: Vector2) -> void:
	var cx: float  = center.x + COMPASS_SIZE * 0.5
	var cy: float  = center.y + COMPASS_SIZE * 0.5
	var vp: Vector2 = get_viewport_rect().size
	var pad: float  = 8.0
	var choices: Array = [
		{"label": "Save and Exit",  "action": "save_exit"},
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
		_tag_ui(lbl, "font", 500)
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
			ExplorationManager.save_session_now()
			CheckerTransition.fade_out_to_battle(func() -> void:
				get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
				CheckerTransition.fade_in())
		"options":
			_open_exploration_options_popup()

# ─────────────────────────────────────────────────────────────
# Inventory Radial Menu
# ─────────────────────────────────────────────────────────────

func _on_inventory_clicked() -> void:
	if _enter_vn_hud_blocked:
		return
	_register_exploration_activity()
	_dismiss_info_panel_for_hud()
	if _inv_animating:
		return
	if _inv_open:
		_close_inventory_menu()
		return
	_close_other_hud_menus("inventory")
	var inv: Array = ExplorationManager.get_inventory()
	if inv.is_empty():
		_flash_empty_inventory()
		return
	_open_inventory_menu(0)

func _open_inventory_menu(page: int) -> void:
	if _enter_vn_hud_blocked:
		return
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

	_spawn_inventory_radial_items(center_pos, page)
	_sync_radial_overlay_state()

func _close_inventory_menu(animated: bool = true) -> void:
	if _inv_animating and not _inv_open:
		return
	_inv_open = false
	for item: Variant in _inv_radial_items:
		if is_instance_valid(item as Node):
			(item as Node).queue_free()
	_inv_radial_items.clear()
	_sync_radial_overlay_state()
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
	_sync_radial_overlay_state()

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

		var choice_type: String = str(choice.get("type", ""))
		var panel_size: Vector2 = Vector2(RADIAL_ITEM_W, RADIAL_ITEM_H)
		var item_id: String = ""
		var item_name: String = ""
		var icon_path: String = ""
		var display_text: String = ""
		var count: int = 1
		if choice_type == "item":
			item_id = str(choice.get("id", ""))
			count = int(choice.get("count", 1))
			var item_data: Dictionary = ExplorationItemDatabase.get_item(item_id)
			item_name = str(item_data.get("name", item_id))
			icon_path = str(item_data.get("icon", ""))
			display_text = item_name if count == 1 else "%s ×%d" % [item_name, count]
			var has_icon: bool = not icon_path.is_empty() and ResourceLoader.exists(icon_path)
			panel_size = _measure_inventory_radial_chip(display_text, has_icon)

		var panel: PanelContainer = _make_radial_panel(
			Vector2(
				clampf(item_cx - panel_size.x * 0.5, pad, vp.x - panel_size.x - pad),
				clampf(item_cy - panel_size.y * 0.5, pad, vp.y - panel_size.y - pad)),
			Color(0.04, 0.08, 0.20, 0.94), Color(0.45, 0.70, 1.0, 0.85), panel_size)

		if choice_type == "item":
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
			lbl.text = display_text
			lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
			lbl.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
			lbl.max_lines_visible     = 2
			lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.add_theme_font_size_override("font_size", INV_RADIAL_FONT_SIZE)
			lbl.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
			_tag_ui(lbl, "font", 500)
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
			_tag_ui(nav_lbl, "font", 500)
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
	if _enter_vn_hud_blocked:
		return
	_register_exploration_activity()
	_dismiss_info_panel_for_hud()
	if _chat_animating:
		return
	if _chat_open:
		_close_chat_menu()
		return
	_close_other_hud_menus("chat")
	var node: ExplorationNode = ExplorationManager.current_node
	if node == null:
		return
	# Filter characters whose conditions are met and haven't been played (if play_once)
	var available: Array = []
	for i: int in node.characters.size():
		if available.size() >= 8:
			break
		var char_data: Variant = node.characters[i]
		if not char_data is Dictionary:
			continue
		var cd: Dictionary = char_data as Dictionary
		if not ExplorationManager.is_connection_unlocked(cd):
			continue
		if _is_char_removed_from_room(cd, i):
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
	if _enter_vn_hud_blocked:
		return
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

	_spawn_chat_radial_items(center_pos, available)
	_sync_radial_overlay_state()

func _close_chat_menu(animated: bool = true) -> void:
	if _chat_animating and not _chat_open:
		return
	_chat_open = false
	for item: Variant in _chat_radial_items:
		if is_instance_valid(item as Node):
			(item as Node).queue_free()
	_chat_radial_items.clear()
	_sync_radial_overlay_state()
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
	_sync_radial_overlay_state()

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
		_tag_ui(lbl, "font", 500)
		panel.add_child(lbl)
		var captured_char: Dictionary = char_data.duplicate(true)
		panel.gui_input.connect(func(ev: InputEvent) -> void:
			if _is_press_event(ev):
				_on_chat_character_selected(captured_char))
		_add_radial_menu_panel(panel, _chat_radial_items)
		var fade_tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fade_tw.tween_interval(float(i) * 0.04)
		fade_tw.tween_property(panel, "modulate:a", 1.0, 0.18)

func _on_chat_character_selected(char_data: Dictionary) -> void:
	_register_exploration_activity()
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_close_chat_menu()
	var vn_path: String = str(char_data.get("vn_scene", "")).strip_edges()
	var play_once: bool = bool(char_data.get("play_once", true))
	var remove_after: bool = bool(char_data.get("remove_after_talk", false))
	var char_index: int = _char_index_for_data(char_data)
	var node_id: String = ExplorationManager.current_node_id
	var raw_acts: Variant = char_data.get("actions", [])
	var actions: Array = raw_acts if raw_acts is Array else []
	var done_cb := func() -> void:
		var node: ExplorationNode = ExplorationManager.current_node
		if node != null:
			_compass_set_visible(true)
		if play_once and not vn_path.is_empty():
			ExplorationManager.mark_vn_played(vn_path)
		if remove_after and char_index >= 0:
			ExplorationManager.mark_char_talked(node_id, char_index)
			if node != null:
				_rebuild_who_is_here(node)
		_refresh_contextual_hud_glows()
	if actions.is_empty():
		if vn_path.is_empty():
			return
		_play_vn(vn_path, done_cb)
		return
	if vn_path.is_empty():
		_execute_spot_actions(actions, done_cb)
		return
	ExplorationManager.stage_spot_action_resume(
		node_id, actions, 0, "char_talk_after", {
			"play_once": play_once,
			"vn_path": vn_path,
			"remove_after": remove_after,
			"char_index": char_index,
		})
	var after_vn := func() -> void:
		ExplorationManager.clear_spot_action_resume()
		_execute_spot_actions(actions, done_cb)
	_play_vn(vn_path, after_vn)

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
	for i: int in node.characters.size():
		if count >= 8:
			break
		var char_data: Variant = node.characters[i]
		if not char_data is Dictionary:
			continue
		var cd: Dictionary = char_data as Dictionary
		if not ExplorationManager.is_connection_unlocked(cd):
			continue
		if _is_char_removed_from_room(cd, i):
			continue
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
	if _enter_vn_hud_blocked:
		return
	_register_exploration_activity()
	if _is_info_panel_showing():
		_close_info_panel(true)
		return
	_close_other_hud_menus("info")
	_open_info_panel()

func _open_enter_info_then_vn(node: ExplorationNode, is_story: bool) -> void:
	if _would_play_node_vn(node):
		_set_enter_vn_hud_blocked(true)
	else:
		_set_enter_vn_hud_blocked(false)
	_pending_enter_vn_after_info = node
	_pending_enter_vn_is_story = is_story
	_open_info_panel(Callable(), true, false)


func _set_enter_vn_hud_blocked(blocked: bool) -> void:
	if _enter_vn_hud_blocked == blocked:
		return
	_enter_vn_hud_blocked = blocked
	if blocked:
		_close_compass_menu(false)
		_close_setting_menu(false)
		_close_inventory_menu(false)
		_close_chat_menu(false)
		_close_settings_menu_popup()
		_close_exploration_options_popup()
	_sync_enter_vn_hud_hits()


func _sync_enter_vn_hud_hits() -> void:
	var mf: Control.MouseFilter = (
		Control.MOUSE_FILTER_IGNORE if _enter_vn_hud_blocked else Control.MOUSE_FILTER_STOP)
	for hit: Button in [_compass_hit, _setting_hit, _inv_hit, _chat_hit, _info_hit]:
		if hit != null:
			hit.mouse_filter = mf


func _schedule_pending_enter_vn_after_info() -> void:
	if _pending_enter_vn_after_info == null or _enter_vn_after_info_scheduled:
		return
	_enter_vn_after_info_scheduled = true
	call_deferred("_on_enter_info_panel_closed")


func _on_enter_info_panel_closed() -> void:
	_enter_vn_after_info_scheduled = false
	var node: ExplorationNode = _pending_enter_vn_after_info
	var is_story: bool = _pending_enter_vn_is_story
	_pending_enter_vn_after_info = null
	if node == null:
		return
	if ExplorationManager.current_node_id != node.id:
		return
	_try_play_node_vn(node, is_story)


func _finish_info_panel_close(run_on_close: bool, cb: Callable) -> void:
	if run_on_close and cb.is_valid():
		_queue_info_panel_close_cb(cb)
	# Enter-VN is independent of run_on_close — HUD dismiss must not skip it.
	_schedule_pending_enter_vn_after_info()


func _queue_info_panel_close_cb(cb: Callable) -> void:
	if not cb.is_valid():
		return
	_pending_info_panel_close_cb = cb
	call_deferred("_execute_info_panel_close_cb")


func _execute_info_panel_close_cb() -> void:
	var cb: Callable = _pending_info_panel_close_cb
	_pending_info_panel_close_cb = Callable()
	if cb.is_valid():
		cb.call()


## Open the info panel with an optional callback fired after it closes.
## Open the info panel. If wait_for_mouse_move=true (auto-open on node entry), the
## auto-dismiss countdown is suppressed until the player moves the mouse.
func _open_info_panel(
		on_close: Callable = Callable(),
		wait_for_mouse_move: bool = false,
		clear_enter_vn_pending: bool = true) -> void:
	if clear_enter_vn_pending and not on_close.is_valid():
		_pending_enter_vn_after_info = null
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
	_back_btn.visible  = true
	_sync_radial_overlay_state()
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

func _close_info_panel(immediate: bool = false, run_on_close: bool = true) -> void:
	if not _is_info_panel_showing():
		return
	_info_auto_dismiss_timer = null
	_info_mouse_wait_timer   = null
	_info_wait_for_mouse     = false
	_info_panel_hovered      = false
	_info_open = false
	var cb: Callable = _info_on_close_cb
	_info_on_close_cb = Callable()
	var can_back: bool = ExplorationManager.can_go_back()
	_sync_radial_overlay_state()
	var vp_w: float = get_viewport().get_visible_rect().size.x
	if _info_panel_tween and _info_panel_tween.is_valid():
		_info_panel_tween.kill()
	if immediate:
		_title_lbl.visible = false
		_desc_lbl.visible  = false
		_back_btn.text     = "← Go Back"
		_back_btn.visible  = can_back
		_content_panel.visible = false
		_content_panel.position.x = vp_w * BG_AREA_FRACTION
		_sync_radial_overlay_state()
		_finish_info_panel_close(run_on_close, cb)
		return
	# Slide out to right — hide labels and reset state only after panel is off-screen
	_info_panel_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	_info_panel_tween.tween_property(_content_panel, "position:x", vp_w, 0.28)
	_info_panel_tween.tween_callback(func() -> void:
		_title_lbl.visible = false
		_desc_lbl.visible  = false
		_back_btn.text     = "← Go Back"
		_back_btn.visible  = can_back
		_content_panel.visible = false
		_content_panel.position.x = vp_w * BG_AREA_FRACTION
		_sync_radial_overlay_state()
		_finish_info_panel_close(run_on_close, cb))

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
	_tag_ui(name_lbl, "font", 700)
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
		use_btn.text = "Use"
		GameDialog.style_button(use_btn)
		var captured_id: String = item_id
		use_btn.pressed.connect(func() -> void:
			_close_item_preview()
			await _execute_item_effects(captured_id))
		btn_row.add_child(use_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	GameDialog.style_button(close_btn)
	close_btn.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88, 1.0))
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

	SFXManager.play(SFXManager.SFX_EXPLORATION_ITEM)

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
	_tag_ui(name_lbl, "font", 700)
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
	_arm_obtained_auto_dismiss(5.0, _dismiss_obtained_overlay)

func _arm_obtained_auto_dismiss(seconds: float, dismiss_fn: Callable) -> void:
	var expected_overlay: Control = _obtained_overlay
	_obtained_dismiss_timer = get_tree().create_timer(seconds)
	_obtained_dismiss_timer.timeout.connect(func() -> void:
		_obtained_dismiss_timer = null
		if expected_overlay == null or not is_instance_valid(expected_overlay):
			return
		if _obtained_overlay != expected_overlay:
			return
		if _obtained_dismissing:
			return
		dismiss_fn.call())

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


func _show_mailbox_reward_overlay(info: Dictionary) -> void:
	SFXManager.play(SFXManager.SFX_EXPLORATION_REWARD)
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
	dim.position     = Vector2.ZERO
	dim.size         = vp
	overlay.add_child(dim)

	# Centred content column
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.position     = Vector2.ZERO
	center.size         = vp
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
	_tag_ui(name_lbl, "font", 700)
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

	overlay.set_meta("mailbox_img", img_tr)
	overlay.set_meta("mailbox_hint", hint_lbl)
	overlay.set_meta("mailbox_name", name_lbl)

	# Full-screen tap catcher on top so taps always register (disabled once dissolve begins)
	var tapper := ColorRect.new()
	tapper.color        = Color(0.0, 0.0, 0.0, 0.0)
	tapper.mouse_filter = Control.MOUSE_FILTER_STOP
	tapper.position     = Vector2.ZERO
	tapper.size         = vp
	tapper.z_index      = 50
	tapper.gui_input.connect(func(ev: InputEvent) -> void:
		if _is_press_event(ev):
			_dismiss_mailbox_reward_overlay())
	overlay.add_child(tapper)

	# Fade-in
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# 8-second auto-dismiss (gives player time to read, then dissolve plays automatically)
	_arm_obtained_auto_dismiss(8.0, _dismiss_mailbox_reward_overlay)

func _dismiss_mailbox_reward_overlay() -> void:
	if _obtained_dismissing:
		return
	var overlay: Control = _obtained_overlay
	if overlay == null or not is_instance_valid(overlay):
		_obtained_overlay     = null
		_obtained_dismissing  = false
		_show_next_obtained()
		return
	if not overlay.has_meta("mailbox_img"):
		if _obtained_overlay == overlay:
			_dismiss_obtained_overlay()
		return

	var img_tr: TextureRect = overlay.get_meta("mailbox_img") as TextureRect
	var hint_lbl: Label = overlay.get_meta("mailbox_hint") as Label
	var name_lbl: Label = overlay.get_meta("mailbox_name") as Label

	_obtained_dismissing    = true
	_obtained_dismiss_timer = null
	_obtained_overlay       = null

	# Disable tap catcher so accidental taps during animation are ignored
	for child: Node in overlay.get_children():
		if child is ColorRect and (child as ColorRect).z_index >= 50:
			(child as ColorRect).mouse_filter = Control.MOUSE_FILTER_IGNORE
			break

	# Hide hint and title — only image stays visible for dissolve
	if hint_lbl != null and is_instance_valid(hint_lbl):
		hint_lbl.visible = false
	if name_lbl != null and is_instance_valid(name_lbl):
		name_lbl.visible = false

	if img_tr == null or not is_instance_valid(img_tr):
		var tw := create_tween()
		tw.tween_property(overlay, "modulate:a", 0.0, 0.30).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		tw.tween_callback(overlay.queue_free)
		tw.tween_callback(func() -> void:
			_obtained_dismissing = false
			_show_next_obtained())
		return

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

	var digit_font: Font = DISSOLVE_FONT

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
	var overlay_id: int = overlay.get_instance_id()
	var seq := create_tween()
	seq.tween_interval(DISSOLVE_DUR + 0.10)
	seq.tween_callback(func() -> void:
		var ov: Control = instance_from_id(overlay_id) as Control
		if ov == null or not is_instance_valid(ov):
			on_done.call()
			return
		_show_mailbox_sent_text(ov, on_done))

func _show_mailbox_sent_text(overlay: Control, on_done: Callable) -> void:
	if not is_instance_valid(overlay):
		on_done.call()
		return

	# Hide remaining overlay children before showing confirmation
	for child: Node in overlay.get_children():
		if child is Control:
			(child as Control).visible = false

	var vp: Vector2 = get_viewport_rect().size
	var dismissed := false
	var hold_tween: Tween = null
	var overlay_id: int = overlay.get_instance_id()

	var finish := func() -> void:
		var ov: Control = instance_from_id(overlay_id) as Control
		if ov == null or not is_instance_valid(ov):
			on_done.call()
			return
		if hold_tween != null and hold_tween.is_valid():
			hold_tween.kill()
		var tw := create_tween()
		tw.tween_property(ov, "modulate:a", 0.0, 0.45) \
			.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		tw.tween_callback(ov.queue_free)
		tw.tween_callback(on_done)

	var dismiss := func() -> void:
		if dismissed:
			return
		dismissed = true
		finish.call()

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.position     = Vector2.ZERO
	center.size         = vp
	center.modulate.a   = 0.0
	center.z_index      = 10
	overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment    = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	# Envelope icon
	var icon_lbl := Label.new()
	icon_lbl.text = "[ ✉ ]"
	_tag_ui(icon_lbl, "font", 300)
	icon_lbl.add_theme_font_size_override("font_size", 52)
	icon_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_lbl)

	# Primary text
	var sent_lbl := Label.new()
	sent_lbl.text = "Sent to mailbox"
	_tag_ui(sent_lbl, "font", 700)
	sent_lbl.add_theme_font_size_override("font_size", 34)
	sent_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	sent_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sent_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sent_lbl)

	# Sub-text — how to claim from the main menu mailbox icon
	var sub_lbl := Label.new()
	sub_lbl.text = (
		"You can visit your mailbox via Save and Exit, "
		+ "then tap the mailbox icon at the bottom-left of the main menu.")
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_lbl.custom_minimum_size = Vector2(520, 0)
	_tag_ui(sub_lbl, "font", 400)
	sub_lbl.add_theme_font_size_override("font_size", 16)
	sub_lbl.add_theme_color_override("font_color", Color(0.42, 0.68, 0.76))
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = "Tap to dismiss"
	hint_lbl.add_theme_font_size_override("font_size", 16)
	hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.65))
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hint_lbl)

	var tapper := ColorRect.new()
	tapper.color        = Color(0.0, 0.0, 0.0, 0.0)
	tapper.mouse_filter = Control.MOUSE_FILTER_STOP
	tapper.position     = Vector2.ZERO
	tapper.size         = vp
	tapper.z_index      = 50
	tapper.gui_input.connect(func(ev: InputEvent) -> void:
		if _is_press_event(ev):
			dismiss.call())
	overlay.add_child(tapper)

	# Fade in confirmation text
	var tw_in := create_tween()
	tw_in.tween_property(center, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

	# Auto-dismiss after hold if player does not tap
	hold_tween = create_tween()
	hold_tween.tween_interval(2.5)
	hold_tween.tween_callback(dismiss)

func _effect_path(eff: Dictionary) -> String:
	var value: String = str(eff.get("value", "")).strip_edges()
	if not value.is_empty():
		return value
	return str(eff.get("key", "")).strip_edges()

func _execute_item_effects(item_id: String) -> void:
	_dismiss_all_hud_menus(false)
	_close_item_preview()
	var item: Dictionary = ExplorationItemDatabase.get_item(item_id)
	var effects: Variant = item.get("effects", [])
	if not effects is Array:
		return
	for eff_var: Variant in (effects as Array):
		if not is_inside_tree():
			return
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
				var sfx_path: String = _effect_path(eff)
				if not sfx_path.is_empty() and ResourceLoader.exists(sfx_path):
					var sfx := AudioStreamPlayer.new()
					sfx.stream = load(sfx_path) as AudioStream
					sfx.bus    = "SFX"
					add_child(sfx)
					sfx.play()
					await sfx.finished
					sfx.queue_free()
			"play_vn":
				var vn_path: String = _effect_path(eff)
				if vn_path.is_empty():
					continue
				var play_once_flag: bool = bool(eff.get("play_once", false))
				if play_once_flag and ExplorationManager.is_vn_played(vn_path):
					continue
				var done := false
				_play_vn(vn_path, func() -> void:
					if play_once_flag:
						ExplorationManager.mark_vn_played(vn_path)
					done = true)
				while not done:
					if not is_inside_tree():
						return
					await get_tree().process_frame
			"navigate_to":
				var nav_target: String = _effect_path(eff)
				if not nav_target.is_empty():
					ExplorationManager.navigate_to(nav_target)
			"end_exploration":
				_do_end_exploration()
				return
			"end_exploration_vn":
				var end_vn_path: String = _effect_path(eff)
				if not end_vn_path.is_empty():
					_do_end_exploration_with_vn(end_vn_path)
					return
	if is_inside_tree():
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


func _measure_inventory_radial_chip(label_text: String, has_icon: bool) -> Vector2:
	var font := _make_font(500)
	var icon_extra: float = INV_RADIAL_ICON_SLOT if has_icon else 0.0
	var inner_w_max: float = INV_RADIAL_ITEM_W_MAX - INV_RADIAL_PAD_H - icon_extra
	var single_w: float = font.get_string_size(
		label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, INV_RADIAL_FONT_SIZE).x
	var chip_w: float = INV_RADIAL_ITEM_W_MAX
	if single_w <= inner_w_max:
		chip_w = clampf(
			single_w + INV_RADIAL_PAD_H + icon_extra,
			INV_RADIAL_ITEM_W_MIN,
			INV_RADIAL_ITEM_W_MAX)
	var text_inner_w: float = chip_w - INV_RADIAL_PAD_H - icon_extra
	var ml_size: Vector2 = font.get_multiline_string_size(
		label_text, HORIZONTAL_ALIGNMENT_LEFT, text_inner_w, INV_RADIAL_FONT_SIZE, 2)
	var chip_h: float = clampf(
		ml_size.y + INV_RADIAL_PAD_V, INV_RADIAL_ITEM_H_MIN, INV_RADIAL_ITEM_H_MAX)
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
	_tag_ui(lbl, "font", 500)
	panel.add_child(lbl)

	if not disabled:
		panel.gui_input.connect(func(ev: InputEvent) -> void:
			if _is_press_event(ev):
				_on_radial_item_selected(target_id))

	var cap_tip: String = locked_hint if disabled and not locked_hint.is_empty() \
		else (label_text if needs_tooltip else "")
	var cap_panel := panel
	if not disabled:
		panel.mouse_entered.connect(func() -> void:
			sb.bg_color = Color(0.10, 0.22, 0.48, 0.97)
			sb.border_color = Color(0.65, 0.88, 1.0, 1.0)
			if not cap_tip.is_empty():
				_tooltip_lbl.text = cap_tip
				_tooltip_panel.reset_size()
				_tooltip_panel.visible = true
				_hovered_nav_panel = cap_panel)
		panel.mouse_exited.connect(func() -> void:
			sb.bg_color = Color(0.04, 0.08, 0.20, 0.94)
			sb.border_color = Color(0.45, 0.70, 1.0, 0.85)
			if not cap_tip.is_empty():
				_hide_tooltip()
			_hovered_nav_panel = null)
	elif not cap_tip.is_empty():
		panel.mouse_entered.connect(func() -> void:
			_tooltip_lbl.text = cap_tip
			_tooltip_panel.reset_size()
			_tooltip_panel.visible = true
			_hovered_nav_panel = cap_panel)
		panel.mouse_exited.connect(func() -> void:
			_hide_tooltip()
			_hovered_nav_panel = null)
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
		var touch := event as InputEventScreenTouch
		return get_viewport().get_canvas_transform().affine_inverse() * touch.position
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
	if _is_info_panel_showing() and _content_panel != null and _content_panel.visible:
		if _content_panel.get_global_rect().has_point(global_pos):
			return true
	return false

func _on_radial_overlay_gui_input(event: InputEvent) -> void:
	if not _is_press_event(event):
		return
	var gp: Vector2 = _get_press_global_position(event)
	var hud_id: String = _hud_icon_at_point(gp)
	if hud_id != "":
		if _enter_vn_hud_blocked:
			if _radial_overlay != null:
				_radial_overlay.accept_event()
			return
		_dispatch_hud_click(hud_id)
		if _radial_overlay != null:
			_radial_overlay.accept_event()
		return
	if _is_point_on_open_menu_ui(gp):
		return
	_close_all_menus()
	if _radial_overlay != null:
		_radial_overlay.accept_event()

func _make_radial_panel(
		pos: Vector2,
		bg_color: Color,
		border_color: Color,
		panel_size: Vector2 = Vector2(RADIAL_ITEM_W, RADIAL_ITEM_H)) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = panel_size
	panel.size       = panel_size
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

func _open_exploration_options_popup() -> void:
	if _exploration_options_overlay != null and is_instance_valid(_exploration_options_overlay):
		return
	var vp_sz: Vector2 = get_viewport_rect().size

	var overlay := Control.new()
	overlay.z_index = 100
	overlay.position = Vector2.ZERO
	overlay.size = vp_sz
	_exploration_options_overlay = overlay
	add_child(overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.0, 0.0, 0.0, 0.65)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dimmer)

	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.14, 0.97)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.38, 0.65, 1.0, 0.5)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	var dlg_size := Vector2(420.0, 260.0)
	panel.size = dlg_size
	panel.position = (vp_sz - dlg_size) * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 16
	vbox.offset_right = -20
	vbox.offset_bottom = -16
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "EXPLORATION OPTIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	_tag_ui(title, "font", 500)
	vbox.add_child(title)

	var auto_row := HBoxContainer.new()
	auto_row.add_theme_constant_override("separation", 10)
	var auto_lbl := Label.new()
	auto_lbl.text = "Auto-save"
	auto_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_lbl.add_theme_font_size_override("font_size", 12)
	auto_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	_tag_ui(auto_lbl, "font", 500)
	auto_row.add_child(auto_lbl)
	var auto_chk := CheckButton.new()
	auto_chk.button_pressed = SaveManager.exploration_auto_save
	auto_row.add_child(auto_chk)
	vbox.add_child(auto_row)

	var auto_hint := Label.new()
	auto_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	auto_hint.add_theme_font_size_override("font_size", 11)
	auto_hint.add_theme_color_override("font_color", Color(0.62, 0.66, 0.74))
	_tag_ui(auto_hint, "font", 500)
	vbox.add_child(auto_hint)

	var sync_auto_hint := func() -> void:
		if SaveManager.exploration_auto_save:
			auto_hint.text = "Progress is saved automatically as you explore, including after battles and puzzles."
		else:
			auto_hint.text = "Auto-save is off. Use Save and Exit to keep your progress."
	auto_chk.toggled.connect(func(on: bool) -> void:
		SaveManager.exploration_auto_save = on
		SaveManager.save_data()
		if on and ExplorationManager.is_session_active:
			ExplorationManager.save_session_now()
		sync_auto_hint.call())
	sync_auto_hint.call()

	var game_settings_btn := Button.new()
	game_settings_btn.text = "Game Settings..."
	GameDialog.style_menu_button(game_settings_btn)
	game_settings_btn.pressed.connect(func() -> void:
		_open_settings_menu_popup())
	vbox.add_child(game_settings_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	GameDialog.style_menu_button(close_btn)
	close_btn.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88, 1.0))
	close_btn.pressed.connect(func() -> void:
		if _exploration_options_overlay != null and is_instance_valid(_exploration_options_overlay):
			_exploration_options_overlay.queue_free()
		_exploration_options_overlay = null)
	vbox.add_child(close_btn)

	overlay.tree_exiting.connect(func() -> void: _exploration_options_overlay = null)

func _open_settings_menu_popup() -> void:
	if _settings_menu != null and is_instance_valid(_settings_menu):
		return
	var sm: Node = load("res://scenes/settings_menu.tscn").instantiate()
	sm.z_index = 100
	_settings_menu = sm
	GameDialog.attach_viewport_overlay(sm as Control, self)
	sm.closed.connect(func() -> void:
		_settings_menu = null
		sm.queue_free())
	sm.tree_exiting.connect(func() -> void: _settings_menu = null)

# ─────────────────────────────────────────────────────────────
# Node Rendering
# ─────────────────────────────────────────────────────────────

func _apply_node_music(node: ExplorationNode) -> void:
	if node == null:
		return
	var effective_music: String = node.resolve_music(ExplorationManager.get_all_vars())
	if effective_music.is_empty():
		return
	if not ResourceLoader.exists(effective_music):
		push_warning("ExplorationPlayer: music '%s' not found." % effective_music)
		return
	BGMManager.play_path(effective_music, 1.0, 0.5, 100.0, BGMManager.CONTEXT_VN)


func _try_apply_restored_bgm() -> bool:
	return _try_apply_bgm_snapshot(ExplorationManager.take_pending_restored_bgm(), "saved")


func _try_apply_vn_resume_bgm() -> bool:
	return _try_apply_bgm_snapshot(ExplorationManager.take_vn_resume_bgm(), "VN resume")


func _try_apply_bgm_snapshot(bgm: Dictionary, label: String) -> bool:
	var path: String = str(bgm.get("path", "")).strip_edges()
	var context: String = str(bgm.get("context", BGMManager.CONTEXT_VN)).strip_edges()
	if path.is_empty() or ExplorationManager.is_battle_bgm_snapshot(path, context):
		return false
	if not ResourceLoader.exists(path):
		push_warning("ExplorationPlayer: %s BGM '%s' not found." % [label, path])
		return false
	if context.is_empty():
		context = BGMManager.CONTEXT_VN
	var pos: float = maxf(0.0, float(bgm.get("position", 0.0)))
	var loop_from: float = float(bgm.get("loop_from_sec", -1.0))
	BGMManager.play_path(path, 1.0, 0.5, 100.0, context, loop_from, pos)
	return true


func _is_active_battle_bgm() -> bool:
	if not BGMManager.is_playing():
		return false
	var ctx: String = BGMManager.get_current_context()
	if ctx in [
		BGMManager.CONTEXT_BATTLE,
		BGMManager.CONTEXT_PLACEMENT,
		BGMManager.CONTEXT_BOSS,
		BGMManager.CONTEXT_ALMOST_WIN,
	]:
		return true
	var path: String = BGMManager.get_current_path().strip_edges()
	if path.is_empty():
		return false
	if path == GameState.get_almost_win_bgm_path():
		return true
	var battle_path: String = GameState.battle_bgm_path.strip_edges()
	if not battle_path.is_empty() and path == battle_path:
		return true
	var setup_path: String = GameState.battle_setup_bgm_path.strip_edges()
	if not setup_path.is_empty():
		return path == setup_path
	return path == BGMManager.get_default_path(BGMManager.CONTEXT_PLACEMENT)


func _restore_node_bgm(node: ExplorationNode, after_battle: bool = false) -> void:
	if after_battle or _is_active_battle_bgm():
		BGMManager.stop(0.8)
	if not _try_apply_restored_bgm() and not _try_apply_vn_resume_bgm():
		_apply_node_music(node)

func _on_node_entered(node: ExplorationNode) -> void:
	_dismiss_all_popups()
	if _exit_vn_defer_enter:
		_pending_enter_node = node
		return
	_refresh_node(node)
	_refresh_contextual_hud_glows()

func _refresh_node(node: ExplorationNode, after_battle: bool = false) -> void:
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

	# Music — drop battle/endgame tracks, then save restore, VN resume, or node track
	_restore_node_bgm(node, after_battle)

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

	var will_enter_vn: bool = node.vn_trigger_on_enter() and _would_play_node_vn(node)
	if not will_enter_vn:
		_set_enter_vn_hud_blocked(false)

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
					_open_enter_info_then_vn(node, true)
				else:
					_set_enter_vn_hud_blocked(true)
					_try_play_node_vn(node, true)
			elif node.show_info_on_enter:
				_compass_set_visible(true)
				_open_info_panel(Callable(), true)
			else:
				_compass_set_visible(true)
		_:
			_content_panel.visible = false
			_choices_vbox.visible = false
			if node.vn_trigger_on_enter():
				if node.show_info_on_enter:
					_compass_set_visible(true)
					_open_enter_info_then_vn(node, false)
				else:
					_set_enter_vn_hud_blocked(true)
					_try_play_node_vn(node, false)
			elif node.show_info_on_enter:
				_compass_set_visible(true)
				_open_info_panel(Callable(), true)
			else:
				_compass_set_visible(true)

	_refresh_flashlight_state()


# ─────────────────────────────────────────────────────────────
# Flashlight (session var flashlight = 1)
# ─────────────────────────────────────────────────────────────

func _refresh_flashlight_state() -> void:
	var want: bool = ExplorationManager.is_flashlight_enabled() \
		and not _vn_playing and not _puzzle_playing
	if _flashlight_overlay != null:
		_flashlight_overlay.visible = want
	if _flashlight_dust_layer != null:
		_flashlight_dust_layer.visible = want
	if _vignette != null:
		_vignette.visible = not want
	if want:
		_layout_flashlight_overlay()
		_layout_flashlight_dust_layer()
		_update_flashlight_shader()


func _get_flashlight_hand_local(area_size: Vector2) -> Vector2:
	return Vector2(
		area_size.x * BG_AREA_FRACTION * FLASHLIGHT_HAND_NORM.x,
		area_size.y * FLASHLIGHT_HAND_NORM.y)


func _layout_flashlight_overlay() -> void:
	if _flashlight_overlay == null:
		return
	var area_size: Vector2 = get_viewport().get_visible_rect().size
	_flashlight_overlay.position = Vector2.ZERO
	_flashlight_overlay.size = area_size
	if _flashlight_mat == null or area_size.y <= 0.0:
		return
	var hand: Vector2 = _get_flashlight_hand_local(area_size)
	_flashlight_mat.set_shader_parameter("overlay_size", area_size)
	_flashlight_mat.set_shader_parameter(
		"beam_length", hand.length() * FLASHLIGHT_LENGTH_PAD)


func _build_flashlight_dust_motes() -> void:
	if _flashlight_dust_layer == null:
		return
	_flashlight_dust_motes.clear()
	for i: int in range(FLASHLIGHT_DUST_COUNT):
		var mote := ColorRect.new()
		var size_px: float = randf_range(1.0, 2.6)
		mote.color = Color(1.0, 1.0, 1.0, 1.0)
		mote.size = Vector2(size_px, size_px)
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flashlight_dust_layer.add_child(mote)
		var ang: float = randf() * TAU
		var spd: float = randf_range(FLASHLIGHT_DUST_MIN_SPEED, FLASHLIGHT_DUST_MAX_SPEED)
		_flashlight_dust_motes.append({
			"node": mote,
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"base_alpha": randf_range(0.08, 0.22),
			"phase": randf() * TAU,
		})
	_reset_flashlight_dust_positions()


func _layout_flashlight_dust_layer() -> void:
	if _flashlight_dust_layer == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	_flashlight_dust_layer.position = Vector2.ZERO
	_flashlight_dust_layer.size = vp_size
	if _flashlight_dust_motes.is_empty():
		return
	for m: Dictionary in _flashlight_dust_motes:
		var pos: Vector2 = m.get("pos", Vector2.ZERO)
		pos.x = clampf(pos.x, 0.0, vp_size.x)
		pos.y = clampf(pos.y, 0.0, vp_size.y)
		m["pos"] = pos


func _reset_flashlight_dust_positions() -> void:
	if _flashlight_dust_layer == null:
		return
	var sz: Vector2 = _flashlight_dust_layer.size
	if sz.x <= 0.0 or sz.y <= 0.0:
		sz = get_viewport().get_visible_rect().size
	for m: Dictionary in _flashlight_dust_motes:
		m["pos"] = Vector2(randf() * sz.x, randf() * sz.y)


func _flashlight_shake(t: float, freq: float, phase: float) -> float:
	return sin(t * TAU * freq + phase)


func _update_flashlight_shader() -> void:
	if _flashlight_mat == null or _flashlight_overlay == null:
		return
	var area_size: Vector2 = _flashlight_overlay.size
	if area_size.x <= 0.0 or area_size.y <= 0.0:
		return
	var overlay_origin: Vector2 = _flashlight_overlay.global_position
	var mouse_local: Vector2 = get_global_mouse_position() - overlay_origin
	_flashlight_mat.set_shader_parameter("beam_origin", mouse_local)
	if not FLASHLIGHT_USE_CONE:
		return
	var hand: Vector2 = _get_flashlight_hand_local(area_size)
	var t: float = _flashlight_time
	hand += Vector2(
		_flashlight_shake(t, 0.39, 0.0) * 4.0 + _flashlight_shake(t, 0.98, 1.2) * 1.9,
		_flashlight_shake(t, 0.34, 0.7) * 3.3 + _flashlight_shake(t, 0.88, 2.1) * 1.6)
	var aim: Vector2 = mouse_local - hand
	if aim.length_squared() < 4.0:
		aim = Vector2(0.0, -1.0)
	else:
		aim = aim.normalized()
	var shake_angle: float = _flashlight_shake(t, 0.49, 0.4) * 0.035 \
		+ _flashlight_shake(t, 1.14, 1.8) * 0.015
	aim = aim.rotated(shake_angle)
	var spread: float = 1.0 + _flashlight_shake(t, 0.43, 2.5) * 0.06
	var beam_length: float = hand.length() * FLASHLIGHT_LENGTH_PAD
	_flashlight_mat.set_shader_parameter("overlay_size", area_size)
	_flashlight_mat.set_shader_parameter("beam_length", beam_length)
	_flashlight_mat.set_shader_parameter("beam_origin", hand)
	_flashlight_mat.set_shader_parameter("beam_direction", aim)
	_flashlight_mat.set_shader_parameter("beam_spread", spread)


func _flashlight_lit_factor(local_pos: Vector2, mouse_local: Vector2) -> float:
	if not FLASHLIGHT_USE_CONE:
		var dist: float = local_pos.distance_to(mouse_local)
		var t: float = smoothstep(FLASHLIGHT_CIRCLE_RADIUS, FLASHLIGHT_CIRCLE_RADIUS + FLASHLIGHT_CIRCLE_SOFT, dist)
		var lit: float = 1.0 - t
		return lit * lit
	# Fallback when cone mode is enabled later: keep at least origin glow lit.
	var hand: Vector2 = _get_flashlight_hand_local(_flashlight_overlay.size)
	var d_hand: float = local_pos.distance_to(hand)
	var ht: float = smoothstep(
		FLASHLIGHT_ORIGIN_GLOW_RADIUS,
		FLASHLIGHT_ORIGIN_GLOW_RADIUS + FLASHLIGHT_ORIGIN_GLOW_SOFT,
		d_hand)
	var h_lit: float = 1.0 - ht
	return h_lit * h_lit


func _update_flashlight_dust_motes(delta: float) -> void:
	if _flashlight_dust_layer == null or not _flashlight_dust_layer.visible:
		return
	var area: Vector2 = _flashlight_dust_layer.size
	if area.x <= 0.0 or area.y <= 0.0:
		return
	var mouse_local: Vector2 = get_global_mouse_position() - _flashlight_dust_layer.global_position
	for m: Dictionary in _flashlight_dust_motes:
		var pos: Vector2 = m.get("pos", Vector2.ZERO)
		var vel: Vector2 = m.get("vel", Vector2.ZERO)
		var phase: float = float(m.get("phase", 0.0))
		phase += delta
		var drift := Vector2(
			sin(_flashlight_time * 0.7 + phase) * 3.2,
			cos(_flashlight_time * 0.9 + phase * 1.3) * 2.4)
		pos += (vel + drift) * delta
		if pos.x < -4.0:
			pos.x = area.x + 4.0
		elif pos.x > area.x + 4.0:
			pos.x = -4.0
		if pos.y < -4.0:
			pos.y = area.y + 4.0
		elif pos.y > area.y + 4.0:
			pos.y = -4.0
		var lit: float = _flashlight_lit_factor(pos, mouse_local)
		var pulse: float = 0.75 + 0.25 * sin(_flashlight_time * 2.1 + phase * 0.8)
		var base_alpha: float = float(m.get("base_alpha", 0.12))
		var mote: ColorRect = m.get("node") as ColorRect
		if mote != null:
			mote.position = pos
			mote.modulate.a = base_alpha * lit * pulse
		m["pos"] = pos
		m["phase"] = phase


# ─────────────────────────────────────────────────────────────
# Visual Novel Integration
# ─────────────────────────────────────────────────────────────

func _would_play_node_vn(node: ExplorationNode) -> bool:
	var vars: Dictionary = ExplorationManager.get_all_vars()
	var vn_path: String = node.resolve_vn_scene(vars)
	if vn_path.is_empty():
		return false
	if not ResourceLoader.exists(vn_path):
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
		_set_enter_vn_hud_blocked(false)
		_compass_set_visible(true)
		_apply_pending_enter_node()
		return
	_set_enter_vn_hud_blocked(true)
	var vars: Dictionary = ExplorationManager.get_all_vars()
	var vn_path: String = node.resolve_vn_scene(vars)
	var play_once: bool = node.resolve_vn_play_once(vars)
	if not is_story:
		_compass_set_visible(false)
	var after_actions: Array = node.resolve_vn_after_actions(vars)
	var done_cb := func() -> void:
		if play_once:
			ExplorationManager.mark_vn_played(vn_path)
		_on_vn_finished(node)
	ExplorationManager.mark_exploration_checkpoint_pending()
	if after_actions.is_empty():
		_play_vn(vn_path, done_cb, node.vn_keep_bgm)
		return
	ExplorationManager.stage_spot_action_resume(node.id, after_actions, 0, "node_vn_after", {
		"play_once": play_once,
		"vn_path":   vn_path,
	})
	var after_vn := func() -> void:
		ExplorationManager.clear_spot_action_resume()
		_execute_spot_actions(after_actions, done_cb)
	_play_vn(vn_path, after_vn, node.vn_keep_bgm)

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
		_refresh_flashlight_state()

	puzzle.puzzle_completed.connect(func(success: bool) -> void:
		cleanup.call()
		on_done.call(success))

func _play_vn(path: String, on_done: Callable, keep_bgm: bool = true) -> void:
	if _vn_playing or _puzzle_playing:
		on_done.call()
		return
	if not ResourceLoader.exists(path):
		push_warning("ExplorationPlayer: VN scene '%s' not found — skipping." % path)
		on_done.call()
		return
	ExplorationManager.snapshot_bgm_before_vn()
	_vn_playing = true
	_refresh_flashlight_state()
	_close_compass_menu(false)
	_close_setting_menu(false)
	_close_inventory_menu(false)
	_close_chat_menu(false)
	_compass_set_visible(false)   # disable compass while VN is active
	var vn: Control = VN_PLAYER_SCENE.instantiate() as Control
	vn.set("transparent_bg", true)   # hide stage colour base; black backdrop only when beat sets background
	vn.set("keep_bgm", keep_bgm)
	vn.set("exploration_overlay", true)
	add_child(vn)
	vn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vn.move_to_front()
	vn.play_scene(path, func() -> void:
		ExplorationManager.clear_vn_resume_bgm()
		_vn_playing = false
		_refresh_flashlight_state()
		on_done.call())

func _on_vn_finished(_node: ExplorationNode) -> void:
	ExplorationManager.finalize_exploration_checkpoint_if_pending()
	_set_enter_vn_hud_blocked(false)
	# VN done — restore compass so player can navigate
	_compass_set_visible(true)
	_apply_pending_enter_node()
	_refresh_spots_for_state()

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
	btn.text = "Begin Battle"
	GameDialog.style_menu_button(btn)
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
	if not won:
		_abort_pending_spot_interaction()
		ExplorationManager.take_spot_action_resume_for_battle(false, node_id)
		if not node_id.is_empty():
			ExplorationManager.set_var("battle_%s_won" % node_id, "false")
		var node_loss: ExplorationNode = ExplorationManager.current_node
		if node_loss != null:
			_refresh_node(node_loss, true)
		else:
			_show_no_session_error()
		return
	if not node_id.is_empty():
		ExplorationManager.set_var("battle_%s_won" % node_id, "true")
	var resume: Dictionary = ExplorationManager.take_spot_action_resume_for_battle(true, node_id)
	# Outcome was already shown on GameBoard's win/lose screen — no duplicate toast here.
	var node: ExplorationNode = ExplorationManager.current_node
	if node != null:
		_refresh_node(node, true)
	else:
		_show_no_session_error()
	if not resume.is_empty():
		var resume_actions: Array = resume.get("actions", []) as Array
		var from_index: int = int(resume.get("from_index", 0))
		var resume_tag: String = str(resume.get("resume_tag", ""))
		if from_index < resume_actions.size():
			ExplorationManager.mark_exploration_checkpoint_pending()
			if resume_tag == "node_vn_after" and node != null:
				var meta: Dictionary = resume.get("meta", {}) as Dictionary
				call_deferred("_resume_node_vn_after_battle", resume_actions, from_index, node, meta)
			elif resume_tag == "char_talk_after":
				var meta: Dictionary = resume.get("meta", {}) as Dictionary
				call_deferred("_resume_char_talk_after_battle", resume_actions, from_index, meta)
			else:
				call_deferred("_resume_spot_actions_after_battle", resume_actions, from_index)
		else:
			ExplorationManager.finalize_exploration_checkpoint()
	else:
		ExplorationManager.finalize_exploration_checkpoint()

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
	btn.text = "Leave This Place"
	GameDialog.style_menu_button(btn)
	btn.pressed.connect(_on_exit_confirmed)
	_hook_cursor(btn)
	_choices_vbox.add_child(btn)

func _on_exit_confirmed() -> void:
	_do_end_exploration()

func _do_end_exploration() -> void:
	if not ExplorationManager.is_session_active:
		return
	var ret_vn: String = ExplorationManager.pending_return_vn.strip_edges()
	if not ret_vn.is_empty():
		ExplorationManager.pending_return_vn = ""
		_do_end_exploration_with_vn(ret_vn)
		return
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	ExplorationManager.end_session(true)
	var dest: String = ExplorationManager.return_scene
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file(dest)
		CheckerTransition.fade_in())

func _do_end_exploration_with_vn(vn_path: String) -> void:
	if not ExplorationManager.is_session_active:
		return
	var vn_target: String = vn_path.strip_edges()
	if vn_target.is_empty():
		return
	ExplorationManager.pending_return_vn = ""
	var chapter_key: String = str(SaveManager.exploration_session.get("source_vn_scene", "")).strip_edges()
	if chapter_key.is_empty():
		chapter_key = SaveManager.resolve_chapter_key_for_vn(vn_target)
	ExplorationManager.detach_session_keep_save(true)
	var resume_beat: int = SaveManager.get_vn_checkpoint(vn_target)
	if resume_beat < 0:
		resume_beat = 0
	SaveManager.update_chapter_arc_vn(chapter_key, vn_target, resume_beat)
	var dest: String = ExplorationManager.return_scene
	var vn: Control = VN_PLAYER_SCENE.instantiate() as Control
	vn.keep_bgm = false
	add_child(vn)
	vn.play_scene(vn_target, func() -> void:
		CheckerTransition.fade_out_to_battle(func() -> void:
			get_tree().change_scene_to_file(dest)
			CheckerTransition.fade_in()),
		true,
		chapter_key)

# ─────────────────────────────────────────────────────────────
# UI helpers
# ─────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	if _info_open:
		_close_info_panel(true)
		return
	SFXManager.play(SFXManager.SFX_CANCEL)
	_navigate_with_fade(func() -> bool: return ExplorationManager.apply_go_back())

func _show_toast(text: String) -> void:
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_lbl.text      = text
	_toast_lbl.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(_toast_lbl, "modulate:a", 0.0, 0.8)


func _show_save_toast() -> void:
	if _save_toast_lbl == null:
		return
	if _save_toast_tween and _save_toast_tween.is_valid():
		_save_toast_tween.kill()
	_save_toast_lbl.modulate.a = 1.0
	_save_toast_tween = create_tween()
	_save_toast_tween.tween_interval(SAVE_TOAST_HOLD_SEC)
	_save_toast_tween.tween_property(_save_toast_lbl, "modulate:a", 0.0, SAVE_TOAST_FADE_SEC)


func _show_no_session_error() -> void:
	_title_lbl.text = "No Exploration Active"
	_desc_lbl.text  = "ExplorationManager has no active session.\nReturn to the main menu."
	for child: Node in _choices_vbox.get_children():
		child.queue_free()
	var btn := Button.new()
	btn.text = "Return to Main Menu"
	GameDialog.style_menu_button(btn)
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
	_tooltip_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_tooltip_panel.add_child(_tooltip_lbl)
	add_child(_tooltip_panel)

func _log_skipped_spot(spot: Dictionary, spot_index: int) -> void:
	var conditions: Variant = spot.get("conditions", [])
	if not conditions is Array or (conditions as Array).is_empty():
		return
	var parts: PackedStringArray = []
	for cond_var: Variant in (conditions as Array):
		if not cond_var is Dictionary:
			continue
		var cd: Dictionary = cond_var as Dictionary
		var ctype: String  = str(cd.get("type", ""))
		var key: String    = str(cd.get("key", ""))
		var val: String    = str(cd.get("value", ""))
		var ok: bool       = ExplorationConditions.evaluate_condition(cd)
		var detail: String = ""
		match ctype:
			"var_equals", "var_not_equals", "var_greater", "var_less", "var_gte", "var_lte":
				detail = " actual=\"%s\"" % ExplorationManager.get_var(key)
			"has_item", "not_has_item":
				detail = " has=%s" % str(ExplorationManager.has_item(key))
			"at_node":
				detail = " current=%s" % ExplorationManager.current_node_id
		parts.append("%s(%s,%s)%s→%s" % [ctype, key, val, detail, ok])
	print("[Exploration] spot #%d hidden on %s: %s" % [
		spot_index, ExplorationManager.current_node_id, ", ".join(parts)])

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

func _clear_spots() -> void:
	if _spots_layer == null:
		return
	for child: Node in _spots_layer.get_children():
		child.free()
	_on_spot_hover_exit()

func _set_spots_layer_visible(show: bool) -> void:
	if _spots_layer != null:
		_spots_layer.visible = show

func _spawn_spot(spot: Dictionary, bg_w: float, bg_h: float, spot_index: int = 0) -> void:
	# Check conditions — reuse ExplorationManager's connection-unlock logic (reads "conditions" key)
	if not ExplorationManager.is_connection_unlocked(spot):
		_log_skipped_spot(spot, spot_index)
		return
	# Skip one-time spots already used or currently running an action queue
	var spot_key_node: String = ExplorationManager.current_node_id
	if bool(spot.get("hide_after_interact", false)) \
			and (ExplorationManager.is_spot_interacted(spot_key_node, spot_index) \
			or ExplorationManager.is_spot_in_progress(spot_key_node, spot_index)):
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

	# Compute hit size: optional override, else image (scaled), else 24×24 invisible fallback
	var hit_w: float = 24.0
	var hit_h: float = 24.0
	var custom_w: float = float(spot.get("hitbox_w", 0.0))
	var custom_h: float = float(spot.get("hitbox_h", 0.0))
	var has_icon: bool = not icon_path.is_empty() and ResourceLoader.exists(icon_path)
	if custom_w > 0.0 and custom_h > 0.0:
		hit_w = custom_w
		hit_h = custom_h
	elif has_icon:
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
	var apply_hide := func() -> void:
		# Spot may already be freed if var/inventory change triggered _rebuild_spots mid-action.
		if is_instance_valid(hit):
			hit.visible = false
	hit.mouse_entered.connect(func() -> void: _on_spot_hover_enter(cap_tip, hit))
	hit.mouse_exited.connect(func() -> void:  _on_spot_hover_exit())
	hit.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				ExplorationManager.set_pending_spot_interaction(cap_node, cap_index, cap_hide)
				if cap_hide:
					ExplorationManager.begin_spot_interaction(cap_node, cap_index)
					apply_hide.call()
				var complete_cb: Callable = Callable()
				if cap_hide:
					complete_cb = func() -> void:
						ExplorationManager.mark_spot_interacted(cap_node, cap_index)
						ExplorationManager.end_spot_interaction(cap_node, cap_index)
						apply_hide.call()
				_handle_spot_click(cap_acts, complete_cb, spot))

func _handle_spot_click(actions: Array, hide_on_success: Callable, spot: Dictionary = {}) -> void:
	if _is_hidden_spot(spot):
		GlobalStatManager.on_hidden_spot_clicked()
	_on_spot_triggered(actions, hide_on_success)


func _is_hidden_spot(spot: Dictionary) -> bool:
	if spot.is_empty():
		return false
	var cond: Variant = spot.get("conditions", [])
	if cond is Array and not (cond as Array).is_empty():
		return true
	var icon: String = str(spot.get("icon", "")).strip_edges()
	var tip: String = str(spot.get("tooltip", "")).strip_edges()
	return icon.is_empty() and tip == "???"

func _on_spot_hover_enter(tooltip_text: String, spot_hit: Control) -> void:
	_hovering_spot    = true
	_hovered_spot_hit = spot_hit
	if not tooltip_text.is_empty() and _tooltip_panel != null:
		_tooltip_lbl.text      = tooltip_text
		_tooltip_panel.reset_size()
		_tooltip_panel.visible = true

func _on_spot_hover_exit() -> void:
	_hovering_spot    = false
	_hovered_spot_hit = null
	_hide_tooltip()

func _hide_tooltip() -> void:
	if _tooltip_panel != null:
		_tooltip_panel.visible = false
	_hovered_nav_panel = null

func _on_spot_triggered(actions: Array, hide_on_success: Callable = Callable()) -> void:
	_register_exploration_activity()
	if _vn_playing or _puzzle_playing or actions.is_empty():
		return
	_on_spot_hover_exit()   # restore cursor before any action takes over
	SFXManager.play(SFXManager.SFX_EXPLORATION)
	_execute_spot_actions(actions, hide_on_success)

func _execute_spot_actions(actions: Array, on_complete: Callable = Callable()) -> void:
	ExplorationManager.clear_spot_action_resume()
	ExplorationManager.reset_pending_play_once_paths()
	ExplorationManager.set_pending_spot_on_complete(on_complete)
	_run_spot_actions_from_index(actions, 0, _spot_actions_queue_complete)

func _spot_actions_queue_complete() -> void:
	ExplorationManager.commit_pending_play_once_paths()
	var on_complete: Callable = ExplorationManager.take_pending_spot_on_complete()
	ExplorationManager.clear_pending_spot_interaction()
	if on_complete.is_valid():
		on_complete.call()
	ExplorationManager.finalize_exploration_checkpoint_if_pending()

func _resume_spot_actions_after_battle(actions: Array, from_index: int) -> void:
	_run_spot_actions_from_index(actions, from_index, _spot_actions_queue_complete)

func _resume_node_vn_after_battle(
		actions: Array,
		from_index: int,
		node: ExplorationNode,
		meta: Dictionary = {}) -> void:
	var done_cb := func() -> void:
		if bool(meta.get("play_once", false)):
			ExplorationManager.mark_vn_played(str(meta.get("vn_path", "")))
		_on_vn_finished(node)
	if from_index <= 0:
		ExplorationManager.reset_pending_play_once_paths()
	ExplorationManager.set_pending_spot_on_complete(done_cb)
	_run_spot_actions_from_index(actions, from_index, _spot_actions_queue_complete)

func _resume_char_talk_after_battle(
		actions: Array,
		from_index: int,
		meta: Dictionary = {}) -> void:
	var done_cb := func() -> void:
		var node: ExplorationNode = ExplorationManager.current_node
		if node != null:
			_compass_set_visible(true)
		if bool(meta.get("play_once", false)):
			var vp: String = str(meta.get("vn_path", "")).strip_edges()
			if not vp.is_empty():
				ExplorationManager.mark_vn_played(vp)
		if bool(meta.get("remove_after", false)):
			var ci: int = int(meta.get("char_index", -1))
			var nid: String = ExplorationManager.current_node_id
			if ci >= 0:
				ExplorationManager.mark_char_talked(nid, ci)
				if node != null:
					_rebuild_who_is_here(node)
		_refresh_contextual_hud_glows()
	if from_index <= 0:
		ExplorationManager.reset_pending_play_once_paths()
	ExplorationManager.set_pending_spot_on_complete(done_cb)
	_run_spot_actions_from_index(actions, from_index, _spot_actions_queue_complete)

func _abort_pending_spot_interaction() -> void:
	var ctx: Dictionary = ExplorationManager.take_pending_spot_interaction()
	if ctx.is_empty():
		return
	var node_id: String = str(ctx.get("node_id", ""))
	var spot_index: int = int(ctx.get("spot_index", -1))
	ExplorationManager.end_spot_interaction(node_id, spot_index)
	ExplorationManager.clear_pending_spot_on_complete()
	ExplorationManager.reset_pending_play_once_paths()
	if bool(ctx.get("hide_after", false)):
		_refresh_spots_for_state()

func _run_spot_actions_from_index(actions: Array, index: int, on_complete: Callable) -> void:
	if index >= actions.size():
		_compass_set_visible(true)
		if on_complete.is_valid():
			on_complete.call()
		return
	var act_var: Variant = actions[index]
	if not act_var is Dictionary:
		_run_spot_actions_from_index(actions, index + 1, on_complete)
		return
	var act: Dictionary = act_var as Dictionary
	var action: String  = str(act.get("action", ""))
	var key: String     = str(act.get("key",    ""))
	var value: String   = str(act.get("value",  ""))
	var next := func() -> void:
		_run_spot_actions_from_index(actions, index + 1, on_complete)
	match action:
		"give_item":
			var item_id: String = key if not key.is_empty() else value
			if not item_id.is_empty():
				ExplorationManager.add_item(item_id)
			next.call()
		"remove_item":
			var rem_id: String = key if not key.is_empty() else value
			if not rem_id.is_empty():
				ExplorationManager.remove_item(rem_id)
			next.call()
		"set_var":
			ExplorationManager.set_var(key, value)
			next.call()
		"give_credits", "set_flag", "give_booster_pack", "give_union_scroll":
			ExplorationManager.process_events([act])
			next.call()
		"show_message":
			_show_toast(value)
			next.call()
		"play_sfx":
			if value.is_empty() or not ResourceLoader.exists(value):
				next.call()
				return
			var sfx := AudioStreamPlayer.new()
			sfx.stream = load(value) as AudioStream
			sfx.bus    = "SFX"
			add_child(sfx)
			sfx.finished.connect(func() -> void:
				sfx.queue_free()
				next.call()
			, CONNECT_ONE_SHOT)
			sfx.play()
		"play_vn":
			if value.is_empty():
				next.call()
				return
			var play_once: bool = bool(act.get("play_once", true))
			if play_once and ExplorationManager.is_vn_played(value):
				next.call()
				return
			if play_once:
				ExplorationManager.append_pending_play_once_path(value)
			ExplorationManager.stage_spot_action_resume(
				ExplorationManager.current_node_id, actions, index + 1)
			var vn_done := func() -> void:
				ExplorationManager.clear_spot_action_resume()
				next.call()
			_play_vn(value, vn_done)
		"play_puzzle":
			var val: String = value.strip_edges()
			var key_str: String = key.strip_edges()
			var pid: String = val if not val.is_empty() else key_str
			var params: Dictionary = {}
			if not val.is_empty() and not key_str.is_empty():
				params = ExplorationPuzzleBase.parse_params(key_str)
			if pid.is_empty():
				next.call()
				return
			_play_puzzle(pid, func(success: bool) -> void:
				if success:
					ExplorationManager.mark_exploration_checkpoint_pending()
					next.call()
				else:
					_abort_pending_spot_interaction()
			, params)
		"navigate_to":
			_abort_pending_spot_interaction()
			if not value.is_empty():
				_compass_set_visible(true)
				_navigate_with_fade(func() -> bool: return ExplorationManager.apply_navigate_to(value))
			return
		"end_exploration":
			_abort_pending_spot_interaction()
			_do_end_exploration()
		"end_exploration_vn":
			_abort_pending_spot_interaction()
			if not value.is_empty():
				_do_end_exploration_with_vn(value)
		_:
			next.call()

func _process(delta: float) -> void:
	if _flashlight_overlay != null and _flashlight_overlay.visible:
		_flashlight_time += delta
		_update_flashlight_shader()
		_update_flashlight_dust_motes(delta)

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
	# Tooltip positioning — anchors above the hovered element.
	if _tooltip_panel != null and _tooltip_panel.visible:
		var vp: Vector2  = get_viewport_rect().size
		var tp: Vector2  = _tooltip_panel.get_minimum_size()
		const GAP: float = 6.0
		var tx: float
		var ty: float
		if _hovered_nav_panel != null and is_instance_valid(_hovered_nav_panel):
			# Nav choice: centre the tooltip horizontally above the panel chip.
			var nr: Rect2 = _hovered_nav_panel.get_global_rect()
			tx = nr.position.x + nr.size.x * 0.5 - tp.x * 0.5
			ty = nr.position.y - tp.y - GAP
		elif _hovered_spot_hit != null and is_instance_valid(_hovered_spot_hit):
			# Investigable spot: X centered on hitbox; Y 48 px above hitbox center.
			const SPOT_TTIP_CENTER_GAP: float = 48.0
			var sr: Rect2 = _hovered_spot_hit.get_global_rect()
			var hc: Vector2 = sr.position + sr.size * 0.5
			tx = hc.x - tp.x * 0.5
			ty = hc.y - SPOT_TTIP_CENTER_GAP - tp.y * 0.5
		else:
			tx = _tooltip_panel.position.x
			ty = _tooltip_panel.position.y
		_tooltip_panel.position = Vector2(
			clampf(tx, 4.0, vp.x - tp.x - 4.0),
			clampf(ty, 4.0, vp.y - tp.y - 4.0))

func _exit_tree() -> void:
	for tw: Variant in _hud_glow_tweens.values():
		if tw is Tween and (tw as Tween).is_valid():
			(tw as Tween).kill()

# ─────────────────────────────────────────────────────────────
# Debug overlay
# ─────────────────────────────────────────────────────────────

func _toggle_debug() -> void:
	if _debug_panel == null:
		return
	_debug_panel.visible = not _debug_panel.visible
	if _debug_panel.visible:
		_debug_lbl.text = ""
		_debug_lbl.append_text("[color=#44ff44]" + ExplorationManager.debug_dump() + "[/color]")


func _toggle_admin_console() -> void:
	BuildConfig.toggle_admin_console_on(self)

func _input(event: InputEvent) -> void:
	# HUD icons can sit under the info-only overlay; route taps explicitly while info is open.
	if _is_press_event(event) and _is_info_panel_showing():
		var hud_id: String = _hud_icon_at_point(_get_press_global_position(event))
		if hud_id != "":
			if _enter_vn_hud_blocked:
				get_viewport().set_input_as_handled()
				return
			_dispatch_hud_click(hud_id)
			get_viewport().set_input_as_handled()
			return
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
	# Dismiss info panel when tapping outside HUD / panel (overlay is IGNORE while info-only).
	if _is_press_event(event) and _is_info_panel_showing():
		var gp: Vector2 = _get_press_global_position(event)
		if _hud_icon_at_point(gp) == "" and not _is_point_on_open_menu_ui(gp):
			_close_info_panel(true)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var ke := event as InputEventKey
		if BuildConfig.admin_shortcut_pressed(ke):
			if BuildConfig.admin_tools_enabled():
				_toggle_admin_console()
			get_viewport().set_input_as_handled()
			return
		if ke.keycode == KEY_F3 and BuildConfig.admin_tools_enabled():
			_toggle_debug()
			get_viewport().set_input_as_handled()
		elif ke.keycode == KEY_ESCAPE and not _is_modified_key(ke):
			if _item_preview != null:
				_close_item_preview()
			elif _compass_open or _setting_open or _inv_open:
				_close_all_menus()
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
