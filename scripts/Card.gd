extends Control

signal card_clicked()
signal card_detail_requested(card_name: String, card_type: String, owner_player: int, row: int, col: int)

# ─────────────────────────────────────────────────────────────
# Style constants
# ─────────────────────────────────────────────────────────────
const AFFINITY_COLORS: Dictionary = {
	CharacterData.Affinity.DIVINE:  Color(1.0,  0.90, 0.30, 1),  # Gold
	CharacterData.Affinity.CHAOS:   Color(0.55, 0.05, 0.75, 1),  # Purple
	CharacterData.Affinity.NATURE:  Color(0.20, 0.80, 0.20, 1),  # Green
	CharacterData.Affinity.ARCANE:  Color(0.15, 0.50, 1.00, 1),  # Blue
	CharacterData.Affinity.COSMIC:  Color(0.00, 0.90, 0.90, 1),  # Cyan
	CharacterData.Affinity.BIO:     Color(0.55, 0.95, 0.10, 1),  # Lime
	CharacterData.Affinity.ANIMA:   Color(0.95, 0.40, 0.10, 1),  # Orange
}

const AFFINITY_SYMBOLS: Dictionary = {
	CharacterData.Affinity.DIVINE:  "✦",
	CharacterData.Affinity.CHAOS:   "☠",
	CharacterData.Affinity.NATURE:  "⚘",
	CharacterData.Affinity.ARCANE:  "✦",
	CharacterData.Affinity.COSMIC:  "★",
	CharacterData.Affinity.BIO:     "⚗",
	CharacterData.Affinity.ANIMA:   "⚡",
}

# Artwork folder roots (checked in order)
const ART_ROOTS: Array = [
	"res://assets/textures/cards/characters/",
	"res://assets/textures/cards/traps/",
	"res://assets/textures/cards/tech/",
]

# Rarity icons (top-right of info area)
const RARITY_ICONS: Dictionary = {
	CharacterData.Rarity.COMMON:    "★",
	CharacterData.Rarity.UNCOMMON:  "★★",
	CharacterData.Rarity.RARE:      "★★★",
	CharacterData.Rarity.LEGENDARY: "★★★★",
	CharacterData.Rarity.EXOTIC:    "★★★★★",
}

const RARITY_COLORS: Dictionary = {
	CharacterData.Rarity.COMMON:    Color(0.65, 0.65, 0.65, 1.0),  # Gray
	CharacterData.Rarity.UNCOMMON:  Color(0.30, 0.90, 0.40, 1.0),  # Green
	CharacterData.Rarity.RARE:      Color(0.30, 0.65, 1.00, 1.0),  # Blue
	CharacterData.Rarity.LEGENDARY: Color(0.78, 0.35, 1.00, 1.0),  # Purple
	CharacterData.Rarity.EXOTIC:    Color(1.00, 0.80, 0.10, 1.0),  # Gold
}

# Outer glow size per rarity (StyleBoxFlat shadow_size)
const RARITY_SHADOW: Dictionary = {
	CharacterData.Rarity.COMMON:    0,
	CharacterData.Rarity.UNCOMMON:  4,
	CharacterData.Rarity.RARE:      10,
	CharacterData.Rarity.LEGENDARY: 20,
	CharacterData.Rarity.EXOTIC:    25,
}

# ─────────────────────────────────────────────────────────────
# Flag badge definitions  (flag_name → {emoji, color})
# Add new entries here to support future flags.
# ─────────────────────────────────────────────────────────────
const FLAG_DEFS: Dictionary = {
	"mutagen": {"emoji": "🧬", "color": Color(0.55, 0.95, 0.55, 0.92)},
	"venom":   {"emoji": "☠", "color": Color(0.55, 0.85, 0.30, 0.92)},
	"berserk": {"emoji": "💢", "color": Color(0.95, 0.30, 0.25, 0.92)},
}

const ART_PLACEHOLDER: Texture2D    = preload("res://assets/textures/cards/placeholder.png")
const VELLUM_FRAME: Texture2D       = preload("res://assets/textures/cards/frames/vellum_card_frame_transparent.png")
const FACEDOWN_TEX: Texture2D       = preload("res://assets/textures/cards/frames/facedown_frame.png")
const BLANK_FRAME_TEX: Texture2D    = preload("res://assets/textures/cards/frames/vellum_card_frame_full.png")
var ICON_BLANK_FOUND: Texture2D
var ICON_TRAP: Texture2D

# ─────────────────────────────────────────────────────────────
# Node references (match card.tscn)
# ─────────────────────────────────────────────────────────────
@onready var bg: ColorRect             = $BG
@onready var face_down_overlay: TextureRect = $FaceDownOverlay
@onready var frame_rect:       TextureRect = $FrameRect
@onready var question_mark: Label      = $FaceDownOverlay/QuestionMark
@onready var card_type_label: Label    = $Header/CardTypeLabel
@onready var affinity_label: Label     = $Header/AffinityLabel
@onready var name_label: Label         = $NameLabel
@onready var artwork_rect: TextureRect = $ArtworkRect
@onready var artwork_placeholder: ColorRect = $ArtworkRect/ArtworkPlaceholder
@onready var atk_label: Label           = $StatsRow/ATKLabel
@onready var def_label: Label           = $StatsRow/DEFLabel
@onready var affinity_stat_label: Label = $StatsRow/AffinityStatLabel
@onready var ability_label: Label      = $AbilityLabel
@onready var cost_label: Label         = $CostLabel
@onready var selection_border: Panel   = $SelectionBorder
@onready var highlight_border: Panel   = $HighlightBorder
@onready var destroyed_overlay: ColorRect = $DestroyedOverlay
@onready var mutagen_indicator: Label  = $MutagenIndicator
@onready var attacked_indicator: ColorRect = $AttackedIndicator
@onready var shield_indicator: Label   = $ShieldIndicator
@onready var rarity_border: Panel      = $RarityBorder
@onready var rarity_icon: Label        = $RarityIcon
@onready var rarity_shimmer: ColorRect = $RarityShimmer
@onready var wait_glow_panel: Panel          = $WaitGlowPanel
@onready var attacked_icon_rect: TextureRect = $AttackedIconRect
@onready var active_glow_panel: Panel        = $ActiveGlowPanel
@onready var exposed_icon_rect: TextureRect   = $ExposedIconRect
@onready var exposed_icon_shadow: TextureRect = $ExposedIconShadow

var card_data: GameState.CardInstance = null
var player_owner: int = -1
var rarity_fx_enabled: bool = true   # set false on game board cards to hide rarity visuals
var _rarity_tween: Tween = null
var _flip_tween: Tween = null
var _attacked_icon_tween: Tween = null
var _wait_glow_tween: Tween = null
var _active_glow_tween: Tween = null
var _target_hover_tween: Tween = null
var _attack_hover_tween: Tween = null
var _union_flash_tween: Tween = null
var _ability_target_flash_tween: Tween = null
var _ability_target_flash_active: bool = false
var _is_peeking: bool = false
var _is_enemy_view: bool = false
var _is_destroying: bool = false
var grid_pos: Vector2i = Vector2i(-1, -1)
var is_selected: bool = false
var is_highlighted: bool = false
var is_locked: bool = false

const INVERT_ART_SHADER: Shader = preload("res://assets/shaders/invert_color.gdshader")
const OUTLINE_SHADER: Shader    = preload("res://assets/shaders/logo_outline.gdshader")

# Cache so we don't reload the texture every frame
var _last_loaded_art: String = ""
var _last_rendered_key: String = ""
static var _invert_art_material: ShaderMaterial

var _blank_found_icon: TextureRect
var _trap_icon: TextureRect
var _crystal_cost_icon: TextureRect = null
var _flag_bar: HBoxContainer = null

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	# BG is purely visual — let clicks pass through to the Card Control directly.
	# Without this, Godot 4 skips the transparent BG (alpha=0 in empty-slot state)
	# which breaks _gui_input propagation to the Card for blank/empty cells.
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	ICON_BLANK_FOUND  = HudSkin.hud_tex("ui_icon_blank_found.png")
	ICON_TRAP         = HudSkin.hud_tex("ui_icon_trap.png")
	_blank_found_icon = _make_card_icon(ICON_BLANK_FOUND)
	_trap_icon        = _make_card_icon(ICON_TRAP)
	HudSkin.skin_changed.connect(_reload_hud_skin)
	_setup_overlay_styles()
	_build_flag_bar()

	# Crystal icon left of the cost number — fits inside the CostLabel area
	_crystal_cost_icon = TextureRect.new()
	_crystal_cost_icon.layout_mode    = 1
	_crystal_cost_icon.anchor_left    = 1.0
	_crystal_cost_icon.anchor_right   = 1.0
	_crystal_cost_icon.anchor_top     = 0.0
	_crystal_cost_icon.anchor_bottom  = 0.0
	_crystal_cost_icon.offset_left    = -30
	_crystal_cost_icon.offset_top     = 2
	_crystal_cost_icon.offset_right   = -21
	_crystal_cost_icon.offset_bottom  = 11
	_crystal_cost_icon.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	_crystal_cost_icon.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_crystal_cost_icon.mouse_filter   = MOUSE_FILTER_IGNORE
	_crystal_cost_icon.texture        = HudSkin.hud_tex("ui_crystal_indicator.png")
	_crystal_cost_icon.visible        = false
	add_child(_crystal_cost_icon)
	# Narrow CostLabel to leave room for the icon
	cost_label.offset_left  = -20
	cost_label.offset_right = -12

	var _wait_outline := ShaderMaterial.new()
	_wait_outline.shader = OUTLINE_SHADER
	_wait_outline.set_shader_parameter("outline_color", Color(0, 0, 0, 1))
	_wait_outline.set_shader_parameter("outline_width", 4.0)
	attacked_icon_rect.material = _wait_outline

	_refresh_display()

func _exit_tree() -> void:
	if HudSkin.skin_changed.is_connected(_reload_hud_skin):
		HudSkin.skin_changed.disconnect(_reload_hud_skin)

func _reload_hud_skin(_new_version: String = "") -> void:
	ICON_BLANK_FOUND = HudSkin.hud_tex("ui_icon_blank_found.png")
	ICON_TRAP        = HudSkin.hud_tex("ui_icon_trap.png")
	if is_instance_valid(_blank_found_icon):
		_blank_found_icon.texture = ICON_BLANK_FOUND
	if is_instance_valid(_trap_icon):
		_trap_icon.texture = ICON_TRAP

func _make_card_icon(tex: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture      = tex
	icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size         = Vector2(36, 36)
	icon.position     = Vector2(37.0, -40.0)  # centered on ~110px card width
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	icon.visible      = false
	add_child(icon)
	return icon

func _build_flag_bar() -> void:
	_flag_bar = HBoxContainer.new()
	# Anchor to the full bottom edge of the card; badges will be centred inside
	_flag_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_flag_bar.offset_top    = -18.0   # badge height
	_flag_bar.offset_bottom = 0.0
	_flag_bar.offset_left   = 0.0
	_flag_bar.offset_right  = 0.0
	_flag_bar.alignment     = BoxContainer.ALIGNMENT_CENTER
	_flag_bar.add_theme_constant_override("separation", 3)
	_flag_bar.mouse_filter  = MOUSE_FILTER_IGNORE
	_flag_bar.visible       = false
	add_child(_flag_bar)

## Rebuild flag badge children from card_data.flags (+ legacy has_mutagen_flag).
## Call from _show_character_face_up() only; all other states hide the bar.
func _refresh_flag_badges() -> void:
	for child in _flag_bar.get_children():
		child.queue_free()

	if card_data == null or _is_enemy_view:
		_flag_bar.visible = false
		return

	# Collect active flags — new generic system + legacy bool bridge
	var active_flags: Array[String] = []
	for f: String in card_data.flags:
		if f not in active_flags:
			active_flags.append(f)
	if card_data.has_mutagen_flag and "mutagen" not in active_flags:
		active_flags.append("mutagen")

	if active_flags.is_empty():
		_flag_bar.visible = false
		return

	for flag_name: String in active_flags:
		if flag_name not in FLAG_DEFS:
			continue
		var def: Dictionary = FLAG_DEFS[flag_name]
		var badge_color: Color = def["color"]
		var emoji: String      = def["emoji"]

		var panel := Panel.new()
		panel.mouse_filter = MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.bg_color = badge_color
		# Rounded top corners → flag-tab look; flat bottom sits on card edge
		sb.corner_radius_top_left     = 5
		sb.corner_radius_top_right    = 5
		sb.corner_radius_bottom_left  = 0
		sb.corner_radius_bottom_right = 0
		sb.shadow_color  = Color(badge_color.r * 0.5, badge_color.g * 0.5, badge_color.b * 0.5, 0.6)
		sb.shadow_offset = Vector2(0.0, 1.0)
		sb.shadow_size   = 3
		sb.border_color        = Color(0, 0, 0, 0.85)
		sb.border_width_left   = 2
		sb.border_width_right  = 2
		sb.border_width_top    = 2
		sb.border_width_bottom = 2
		panel.add_theme_stylebox_override("panel", sb)
		panel.custom_minimum_size = Vector2(24.0, 17.0)

		var lbl := Label.new()
		lbl.text = emoji
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.mouse_filter = MOUSE_FILTER_IGNORE
		panel.add_child(lbl)
		_flag_bar.add_child(panel)

	_flag_bar.visible = true

func _setup_overlay_styles() -> void:
	# Highlight border: border-only cyan outline (used for tech target selection)
	var hb_style := StyleBoxFlat.new()
	hb_style.draw_center = false
	hb_style.border_width_left   = 2
	hb_style.border_width_top    = 2
	hb_style.border_width_right  = 2
	hb_style.border_width_bottom = 2
	hb_style.border_color = Color(0.3, 0.9, 1.0, 0.9)
	hb_style.shadow_color = Color(0.3, 0.9, 1.0, 0.5)
	hb_style.shadow_offset = Vector2.ZERO
	hb_style.shadow_size  = 6
	highlight_border.add_theme_stylebox_override("panel", hb_style)
	# Wait glow: warm amber lantern glow behind the hourglass icon
	var wg_style := StyleBoxFlat.new()
	wg_style.draw_center = true
	wg_style.bg_color = Color(1.0, 1.0, 1.0, 0.07)
	wg_style.corner_radius_top_left     = 47
	wg_style.corner_radius_top_right    = 47
	wg_style.corner_radius_bottom_left  = 47
	wg_style.corner_radius_bottom_right = 47
	wg_style.shadow_color  = Color(1.0, 1.0, 1.0, 0.38)
	wg_style.shadow_offset = Vector2.ZERO
	wg_style.shadow_size   = 18
	wait_glow_panel.add_theme_stylebox_override("panel", wg_style)

func _set_active_glow(show: bool) -> void:
	exposed_icon_rect.visible = show
	exposed_icon_shadow.visible = show

func _should_show_exposed_icon() -> bool:
	if card_data == null:
		return false
	# Exposed badge: opponent can see this card's identity (revealed on the board).
	if not card_data.face_up:
		return false
	return card_data.card_type in ["character", "trap", "tech"]

func _set_attacked_icon(show: bool) -> void:
	if _attacked_icon_tween:
		_attacked_icon_tween.kill()
		_attacked_icon_tween = null
	if _wait_glow_tween:
		_wait_glow_tween.kill()
		_wait_glow_tween = null
	if show:
		attacked_icon_rect.visible = true
		wait_glow_panel.visible = true
		_attacked_icon_tween = create_tween().set_loops()
		_attacked_icon_tween.tween_property(attacked_icon_rect, "modulate:a", 0.15, 1.1) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_attacked_icon_tween.tween_property(attacked_icon_rect, "modulate:a", 0.75, 1.1) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_wait_glow_tween = create_tween().set_loops()
		_wait_glow_tween.tween_property(wait_glow_panel, "modulate:a", 0.2, 1.1) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_wait_glow_tween.tween_property(wait_glow_panel, "modulate:a", 0.7, 1.1) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		attacked_icon_rect.visible = false
		wait_glow_panel.visible = false

func set_card_data(data: GameState.CardInstance, owner_player: int, pos: Vector2i) -> void:
	var render_key := "" if data == null else "%s|%s|%s|%s" % [
		data.card_type, data.card_name, data.is_union, data.is_revived]
	if render_key != _last_rendered_key:
		_last_loaded_art = ""
		_last_rendered_key = render_key
	card_data = data
	player_owner = owner_player
	grid_pos = pos
	# Cleared slots update GameState before destroy animation ends; refresh immediately
	# so stale card art isn't resurrected by hover/selection modulate resets.
	var cleared_slot := data != null and data.was_destroyed
	if is_inside_tree() and (not _is_destroying or cleared_slot):
		_refresh_display()

func set_preview_revealed(value: bool) -> void:
	_is_peeking = value
	if is_inside_tree() and not _is_destroying:
		_refresh_display()

func set_enemy_view(value: bool) -> void:
	_is_enemy_view = value
	if is_inside_tree() and not _is_destroying:
		_refresh_display()

# ─────────────────────────────────────────────────────────────
# Display routing
# ─────────────────────────────────────────────────────────────
func _refresh_display() -> void:
	if card_data == null:
		_show_empty_slot()
		return
	match card_data.card_type:
		"dead_end":
			# Show face-down when the card is unrevealed AND either:
			#   - it belongs to the opponent (always hidden from current player), or
			#   - it's own card but peek is OFF (enemy-view simulation).
			# Revealed (destroyed) blanks are completely invisible.
			if not card_data.face_up and (player_owner != GameState.current_player or not _is_peeking):
				_show_face_down()
			else:
				_show_empty_slot()
		"character":
			if card_data.face_up or _is_peeking: _show_character_face_up()
			else:                                 _show_face_down()
		"trap":
			if card_data.face_up or _is_peeking: _show_trap_face_up()
			else:                                 _show_face_down()
		"tech":
			if card_data.face_up: _show_tech_face_up()
			else:                 _show_face_down()

# ─────────────────────────────────────────────────────────────
# Blank
# ─────────────────────────────────────────────────────────────
func _show_blank() -> void:
	face_down_overlay.visible = false
	_clear_labels()
	_clear_art()
	_clear_rarity()
	mutagen_indicator.visible = false
	attacked_indicator.visible = false
	shield_indicator.visible = false
	_set_active_glow(false)
	_set_attacked_icon(false)
	_flag_bar.visible = false
	frame_rect.texture = BLANK_FRAME_TEX
	bg.color = Color(0.02, 0.02, 0.04, 1.0)
	card_type_label.text = ""
	artwork_rect.visible = false
	_blank_found_icon.visible = false
	_trap_icon.visible        = false

# ─────────────────────────────────────────────────────────────
# Empty slot (blank card while peeking — completely invisible)
# ─────────────────────────────────────────────────────────────
func _show_empty_slot() -> void:
	face_down_overlay.visible = false
	frame_rect.texture = null
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	artwork_rect.visible = false
	_clear_labels()
	_clear_rarity()
	card_type_label.text = ""
	mutagen_indicator.visible = false
	attacked_indicator.visible = false
	shield_indicator.visible = false
	_set_active_glow(false)
	_set_attacked_icon(false)
	_flag_bar.visible = false
	_last_loaded_art = ""
	var is_revealed_blank := card_data != null and card_data.face_up and not card_data.was_destroyed
	_blank_found_icon.visible = is_revealed_blank
	_trap_icon.visible        = false

# ─────────────────────────────────────────────────────────────
# Face-down
# ─────────────────────────────────────────────────────────────
func _show_face_down() -> void:
	face_down_overlay.visible = false
	frame_rect.texture = FACEDOWN_TEX
	bg.color = Color(0.05, 0.04, 0.08)
	_clear_labels()
	_clear_art()
	_clear_rarity()
	mutagen_indicator.visible = false
	attacked_indicator.visible = false
	shield_indicator.visible = false
	_set_active_glow(false)
	_set_attacked_icon(false)
	_flag_bar.visible = false
	_blank_found_icon.visible = false
	_trap_icon.visible        = false

# ─────────────────────────────────────────────────────────────
# Character face-up
# ─────────────────────────────────────────────────────────────
func _show_character_face_up() -> void:
	face_down_overlay.visible = false
	frame_rect.texture = VELLUM_FRAME

	# ── Union card rendering ──────────────────────────────────
	if card_data.is_union:
		_show_union_face_up()
		return

	var aff_color: Color = AFFINITY_COLORS.get(card_data.affinity, Color.WHITE)
	bg.color = Color(0.05, 0.04, 0.08)

	card_type_label.text = CharacterData.Affinity.keys()[card_data.affinity].to_upper()
	card_type_label.add_theme_color_override("font_color", aff_color)
	affinity_label.text = AFFINITY_SYMBOLS.get(card_data.affinity, "?")
	affinity_label.add_theme_color_override("font_color", aff_color)

	name_label.text = card_data.display_name if not card_data.display_name.is_empty() else card_data.card_name

	var char_data: CharacterData = CardDatabase.get_character(card_data.card_name)

	var eff_atk: int = card_data.get_effective_atk()
	var eff_def: int = card_data.get_effective_def()
	atk_label.text = "ATK %d" % eff_atk
	def_label.text = "DEF %d" % eff_def
	if char_data and eff_atk != char_data.base_atk:
		atk_label.add_theme_color_override("font_color", Color(1.0, 0.68, 0.60))
	else:
		atk_label.add_theme_color_override("font_color", Color(1.0, 0.40, 0.30))
	if char_data and eff_def != char_data.base_def:
		def_label.add_theme_color_override("font_color", Color(0.62, 0.88, 1.0))
	else:
		def_label.add_theme_color_override("font_color", Color(0.30, 0.70, 1.0))

	affinity_stat_label.text = CharacterData.Affinity.keys()[card_data.affinity].capitalize()
	affinity_stat_label.add_theme_color_override("font_color", Color(aff_color.r, aff_color.g, aff_color.b, 0.7))

	if char_data and card_data.crystal_cost != char_data.crystal_cost:
		cost_label.text = "%d" % card_data.crystal_cost
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.65))
	else:
		cost_label.text = "%d" % card_data.crystal_cost
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.30))
	if _crystal_cost_icon:
		_crystal_cost_icon.visible = true

	if char_data:
		ability_label.text = char_data.get_ability_description()
		_load_artwork(char_data.artwork_path, card_data.card_name, "characters")
	else:
		ability_label.text = ""
		_clear_art()

	attacked_indicator.visible = false  # replaced by attacked_icon_rect
	_blank_found_icon.visible  = false
	_trap_icon.visible         = false
	mutagen_indicator.visible = false  # replaced by _flag_bar
	if _is_enemy_view:
		shield_indicator.visible = false
		_set_active_glow(false)
		_set_attacked_icon(false)
		_clear_rarity()
		_flag_bar.visible = false
	else:
		shield_indicator.visible = card_data.force_shielded
		shield_indicator.text = "🛡"
		var is_own_turn := player_owner == GameState.current_player
		_set_active_glow(_should_show_exposed_icon())
		_set_attacked_icon(is_own_turn and card_data.attacked_this_turn)
		_apply_rarity(aff_color)
		_refresh_flag_badges()

# ─────────────────────────────────────────────────────────────
# Union face-up (character subtype, cyan frame)
# ─────────────────────────────────────────────────────────────
const UNION_CYAN: Color = Color(0.25, 0.90, 1.00)

func _show_union_face_up() -> void:
	face_down_overlay.visible = false
	frame_rect.texture = VELLUM_FRAME
	bg.color = Color(0.02, 0.08, 0.14)

	card_type_label.text = "UNION"
	card_type_label.add_theme_color_override("font_color", UNION_CYAN)
	affinity_label.text = "⊕"
	affinity_label.add_theme_color_override("font_color", UNION_CYAN)

	name_label.text = card_data.display_name if not card_data.display_name.is_empty() else card_data.card_name

	var eff_atk: int = card_data.get_effective_atk()
	var eff_def: int = card_data.get_effective_def()
	atk_label.text = "ATK %d" % eff_atk
	def_label.text = "DEF %d" % eff_def
	atk_label.add_theme_color_override("font_color", Color(1.0, 0.40, 0.30))
	def_label.add_theme_color_override("font_color", Color(0.30, 0.70, 1.0))

	var aff_idx: int = card_data.affinity
	var aff_keys: Array = CharacterData.Affinity.keys()
	affinity_stat_label.text = aff_keys[aff_idx].capitalize() if aff_idx < aff_keys.size() else ""
	affinity_stat_label.add_theme_color_override("font_color", Color(UNION_CYAN.r, UNION_CYAN.g, UNION_CYAN.b, 0.7))

	cost_label.text = "0"
	cost_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.30))
	if _crystal_cost_icon:
		_crystal_cost_icon.visible = true

	var u: UnionData = UnionDatabase.get_union(card_data.card_name)
	if u:
		ability_label.text = u.ability_description
		var _found_path: String = CardDatabase.find_artwork(card_data.card_name, "union")
		_load_artwork(_found_path if _found_path != "" else u.artwork_path, card_data.card_name, "unions")
	else:
		ability_label.text = ""
		_clear_art()

	attacked_indicator.visible = false
	_blank_found_icon.visible  = false
	_trap_icon.visible         = false
	mutagen_indicator.visible  = false
	if _is_enemy_view:
		shield_indicator.visible = false
		_set_active_glow(false)
		_set_attacked_icon(false)
		_clear_rarity()
		_flag_bar.visible = false
	else:
		shield_indicator.visible = card_data.force_shielded
		shield_indicator.text = "🛡"
		var is_own_turn := player_owner == GameState.current_player
		_set_active_glow(_should_show_exposed_icon())
		_set_attacked_icon(is_own_turn and card_data.attacked_this_turn)
		_apply_rarity(UNION_CYAN)
		_refresh_flag_badges()

# ─────────────────────────────────────────────────────────────
# Trap face-up
# ─────────────────────────────────────────────────────────────
func _show_trap_face_up() -> void:
	face_down_overlay.visible = false
	frame_rect.texture = VELLUM_FRAME
	bg.color = Color(0.05, 0.04, 0.08)

	card_type_label.text = "TRAP"
	card_type_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	affinity_label.text = "⚠"
	affinity_label.add_theme_color_override("font_color", Color(1, 0.5, 0))

	name_label.text = card_data.display_name if not card_data.display_name.is_empty() else card_data.card_name
	atk_label.text = ""
	def_label.text = ""
	affinity_stat_label.text = ""
	cost_label.text = "%d" % card_data.crystal_cost
	if _crystal_cost_icon:
		_crystal_cost_icon.visible = true

	var trap_data: TrapData = CardDatabase.get_trap(card_data.card_name)
	if trap_data:
		ability_label.text = trap_data.get_effect_description()
		_load_artwork(trap_data.artwork_path, card_data.card_name, "traps")
	else:
		ability_label.text = ""
		_clear_art()

	mutagen_indicator.visible = false
	attacked_indicator.visible = false
	shield_indicator.visible = false
	_set_attacked_icon(false)
	_set_active_glow(_should_show_exposed_icon())
	_clear_rarity()
	_flag_bar.visible = false
	_blank_found_icon.visible = false
	_trap_icon.visible        = true

# ─────────────────────────────────────────────────────────────
# Tech face-up
# ─────────────────────────────────────────────────────────────
func _show_tech_face_up() -> void:
	face_down_overlay.visible = false
	frame_rect.texture = VELLUM_FRAME
	bg.color = Color(0.03, 0.06, 0.12)

	const TECH_COLOR := Color(0.30, 0.85, 1.0)
	card_type_label.text = "TECH"
	card_type_label.add_theme_color_override("font_color", TECH_COLOR)
	affinity_label.text = "⚙"
	affinity_label.add_theme_color_override("font_color", TECH_COLOR)

	name_label.text = card_data.display_name if not card_data.display_name.is_empty() else card_data.card_name
	atk_label.text = ""
	def_label.text = ""
	affinity_stat_label.text = ""
	cost_label.text = "%d" % card_data.crystal_cost
	if _crystal_cost_icon:
		_crystal_cost_icon.visible = true

	var tech_data: TechCardData = CardDatabase.get_tech(card_data.card_name)
	if tech_data:
		ability_label.text = tech_data.get_effect_description()
		_load_artwork(tech_data.artwork_path, card_data.card_name, "tech")
	else:
		ability_label.text = ""
		_clear_art()

	mutagen_indicator.visible = false
	attacked_indicator.visible = false
	shield_indicator.visible = false
	_set_active_glow(false)
	_set_attacked_icon(false)
	_apply_rarity(TECH_COLOR)
	_flag_bar.visible = false
	_blank_found_icon.visible = false
	_trap_icon.visible        = false

# ─────────────────────────────────────────────────────────────
# Rarity
# ─────────────────────────────────────────────────────────────
func _clear_rarity() -> void:
	if _rarity_tween:
		_rarity_tween.kill()
		_rarity_tween = null
	rarity_border.visible = false
	rarity_icon.text = ""
	rarity_shimmer.visible = false
	rarity_shimmer.position.x = -30.0
	modulate = Color(1, 1, 1, 1)

func _apply_rarity(accent_color: Color) -> void:
	_clear_rarity()
	var rarity: int = card_data.rarity

	# Small star badge — always shown on revealed cards (battle phase included)
	rarity_icon.text = RARITY_ICONS.get(rarity, "")
	rarity_icon.add_theme_color_override("font_color",
		RARITY_COLORS.get(rarity, Color.WHITE))

	if not rarity_fx_enabled:
		return

	# StyleBoxFlat border + glow (draw_center=false = border only)
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.75)
	sb.corner_radius_top_left     = 4
	sb.corner_radius_top_right    = 4
	sb.corner_radius_bottom_left  = 4
	sb.corner_radius_bottom_right = 4
	sb.shadow_color  = Color(accent_color.r, accent_color.g, accent_color.b, 0.5)
	sb.shadow_offset = Vector2.ZERO
	sb.shadow_size   = RARITY_SHADOW.get(rarity, 0)
	rarity_border.add_theme_stylebox_override("panel", sb)
	rarity_border.visible = true

	match rarity:
		CharacterData.Rarity.UNCOMMON:
			# Slow breathing glow
			_rarity_tween = create_tween().set_loops()
			_rarity_tween.tween_property(rarity_border, "modulate:a", 0.4, 1.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_rarity_tween.tween_property(rarity_border, "modulate:a", 1.0, 1.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		CharacterData.Rarity.LEGENDARY:
			# Shimmer strip sweeps left → right every ~10s
			rarity_shimmer.size = Vector2(26, 150)
			rarity_shimmer.color = Color(1.0, 1.0, 1.0, 0.14)
			rarity_shimmer.visible = true
			_rarity_tween = create_tween().set_loops()
			_rarity_tween.tween_interval(1.5)
			_rarity_tween.tween_property(rarity_shimmer, "position:x", 140.0, 8.4) \
				.set_trans(Tween.TRANS_SINE)
			_rarity_tween.tween_callback(func() -> void: rarity_shimmer.position.x = -30.0)
		CharacterData.Rarity.EXOTIC:
			# Full-card brightness pulse
			rarity_shimmer.position = Vector2(0, 0)
			rarity_shimmer.size = Vector2(110, 150)
			rarity_shimmer.color = Color(1.0, 1.0, 1.0, 0.0)
			rarity_shimmer.visible = true
			_rarity_tween = create_tween().set_loops()
			_rarity_tween.tween_property(rarity_shimmer, "color:a", 0.18, 1.0) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_rarity_tween.tween_property(rarity_shimmer, "color:a", 0.0, 1.0) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ─────────────────────────────────────────────────────────────
# Artwork Loading
# ─────────────────────────────────────────────────────────────
func _load_artwork(explicit_path: String, card_name: String, subfolder: String) -> void:
	# 1. Try the explicit path set on the resource
	if explicit_path != "":
		if _can_reuse_loaded_art(explicit_path):
			_apply_artwork_color_fx()
			return
		if ResourceLoader.exists(explicit_path):
			_set_texture(explicit_path)
			return

	# 2. Look up via CardDatabase cache (directory scanned at most once per name)
	var path: String = CardDatabase.find_artwork(card_name, subfolder, SaveManager.nsfw_enabled)
	if _can_reuse_loaded_art(path):
		_apply_artwork_color_fx()
		return
	if path != "":
		_set_texture(path)
		return

	# 3. No artwork found — show placeholder
	_clear_art()

func _can_reuse_loaded_art(path: String) -> bool:
	return path != "" \
		and path == _last_loaded_art \
		and artwork_rect.visible \
		and artwork_rect.texture != null \
		and artwork_rect.texture != ART_PLACEHOLDER

func _set_texture(path: String) -> void:
	var tex: Texture2D = load(path)
	if tex:
		artwork_rect.texture = tex
		artwork_rect.visible = true
		artwork_placeholder.visible = false
		_last_loaded_art = path
		_apply_artwork_color_fx()
	else:
		_clear_art()

func _clear_art() -> void:
	artwork_rect.visible = true
	artwork_rect.texture = ART_PLACEHOLDER
	artwork_rect.material = null
	artwork_placeholder.visible = false
	_last_loaded_art = ""

func _should_invert_grid_artwork() -> bool:
	return card_data != null and card_data.is_revived

func _apply_artwork_color_fx() -> void:
	if _should_invert_grid_artwork():
		if _invert_art_material == null:
			_invert_art_material = ShaderMaterial.new()
			_invert_art_material.shader = INVERT_ART_SHADER
		artwork_rect.material = _invert_art_material
	else:
		artwork_rect.material = null

# Converts "Angel Gatekeeper" → "angel_gatekeeper"
func _to_snake_case(s: String) -> String:
	return s.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _clear_labels() -> void:
	card_type_label.text = ""
	affinity_label.text = ""
	name_label.text = ""
	atk_label.text = ""
	def_label.text = ""
	affinity_stat_label.text = ""
	ability_label.text = ""
	cost_label.text = ""
	if _crystal_cost_icon:
		_crystal_cost_icon.visible = false

# ─────────────────────────────────────────────────────────────
# Selection / Highlight
# ─────────────────────────────────────────────────────────────
func set_selected(selected: bool) -> void:
	is_selected = selected
	selection_border.visible = selected

func set_highlighted(highlighted: bool) -> void:
	var changed: bool = is_highlighted != highlighted
	is_highlighted = highlighted
	highlight_border.visible = highlighted and not _is_enemy_view
	if not highlighted:
		set_ability_target_flash(false)
	if changed and _is_peeking:
		_refresh_display()

func _reset_target_highlight_border() -> void:
	var sb := highlight_border.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null:
		return
	sb.border_color = Color(0.3, 0.9, 1.0, 0.9)
	sb.shadow_color  = Color(0.3, 0.9, 1.0, 0.5)
	sb.shadow_size = 6
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2

func set_target_hover(hovered: bool) -> void:
	if not is_highlighted:
		return
	var sb := highlight_border.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null:
		return
	if _target_hover_tween and _target_hover_tween.is_valid():
		_target_hover_tween.kill()
		_target_hover_tween = null
	if hovered:
		if _ability_target_flash_tween and _ability_target_flash_tween.is_valid():
			_ability_target_flash_tween.kill()
			_ability_target_flash_tween = null
		highlight_border.visible = true
		sb.border_color = Color(1.0, 0.85, 0.2, 1.0)
		sb.shadow_color  = Color(1.0, 0.85, 0.2, 0.7)
		sb.shadow_size = 8
		sb.border_width_left   = 3
		sb.border_width_top    = 3
		sb.border_width_right  = 3
		sb.border_width_bottom = 3
		modulate = Color.WHITE
		_target_hover_tween = create_tween().set_loops()
		_target_hover_tween.tween_property(self, "modulate",
			Color(1.4, 1.2, 0.6, 1.0), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_target_hover_tween.tween_property(self, "modulate",
			Color.WHITE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		if _ability_target_flash_active:
			set_ability_target_flash(true)
		else:
			modulate = Color.WHITE
			highlight_border.visible = is_highlighted and not _is_enemy_view
			_reset_target_highlight_border()

func set_attack_hover(hovered: bool) -> void:
	# Destroyed slots are empty — modulate tweens would flash stale pre-destroy art.
	if card_data != null and card_data.was_destroyed:
		return
	if _attack_hover_tween and _attack_hover_tween.is_valid():
		_attack_hover_tween.kill()
		_attack_hover_tween = null
	if hovered:
		_attack_hover_tween = create_tween().set_loops()
		_attack_hover_tween.tween_property(self, "modulate",
			Color(1.5, 0.5, 0.5, 1.0), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_attack_hover_tween.tween_property(self, "modulate",
			Color.WHITE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		modulate = Color.WHITE

func set_locked(locked: bool) -> void:
	is_locked = locked
	if not _is_enemy_view:
		modulate = Color(0.45, 0.45, 0.45, 1.0) if locked else Color(1, 1, 1, 1)

func set_union_flash(flashing: bool) -> void:
	if _union_flash_tween and _union_flash_tween.is_valid():
		_union_flash_tween.kill()
		_union_flash_tween = null
	if flashing:
		modulate = Color.WHITE
		_union_flash_tween = create_tween().set_loops()
		_union_flash_tween.tween_property(self, "modulate",
			Color(0.4, 1.2, 1.4, 1.0), 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_union_flash_tween.tween_property(self, "modulate",
			Color.WHITE, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		modulate = Color.WHITE

## Subtle yellow pulse on valid ability/tech targets (works on enemy-view face-down cards).
func set_ability_target_flash(flashing: bool) -> void:
	_ability_target_flash_active = flashing
	if _ability_target_flash_tween and _ability_target_flash_tween.is_valid():
		_ability_target_flash_tween.kill()
		_ability_target_flash_tween = null
	if flashing:
		highlight_border.visible = true
		var sb := highlight_border.get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			sb.border_color = Color(1.0, 0.88, 0.15, 0.85)
			sb.shadow_color = Color(1.0, 0.88, 0.15, 0.35)
			sb.shadow_size = 8
			sb.border_width_left   = 3
			sb.border_width_top    = 3
			sb.border_width_right  = 3
			sb.border_width_bottom = 3
		modulate = Color.WHITE
		_ability_target_flash_tween = create_tween().set_loops()
		_ability_target_flash_tween.tween_property(self, "modulate",
			Color(1.22, 1.12, 0.58, 1.0), 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_ability_target_flash_tween.tween_property(self, "modulate",
			Color.WHITE, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		modulate = Color.WHITE
		highlight_border.visible = is_highlighted and not _is_enemy_view
		_reset_target_highlight_border()

# ─────────────────────────────────────────────────────────────
# Animations
# ─────────────────────────────────────────────────────────────
func play_reveal_animation() -> void:
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.05, 1.0), 0.12).set_trans(Tween.TRANS_CUBIC)
	if card_data != null and card_data.card_type == "dead_end":
		tween.tween_callback(_show_blank)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_CUBIC)
		tween.tween_interval(0.5)
		tween.tween_callback(_show_empty_slot)
	else:
		tween.tween_callback(_refresh_display)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_CUBIC)

func play_destroy_animation() -> void:
	_is_destroying = true
	pivot_offset = size * 0.5
	destroyed_overlay.visible = true
	destroyed_overlay.color = Color(1, 0.45, 0.1, 0)

	var saved_pos := position
	var tween := create_tween()

	# Flash in
	tween.tween_property(destroyed_overlay, "color", Color(1, 0.45, 0.1, 0.9), 0.06)

	# Shake — rapid horizontal jitter
	tween.tween_property(self, "position", saved_pos + Vector2(7, 0), 0.04)
	tween.tween_property(self, "position", saved_pos + Vector2(-7, 0), 0.04)
	tween.tween_property(self, "position", saved_pos + Vector2(5, -2), 0.04)
	tween.tween_property(self, "position", saved_pos + Vector2(-4, 2), 0.04)
	tween.tween_property(self, "position", saved_pos, 0.03)

	# Fade out with flash
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.28)

	tween.tween_callback(func():
		_is_destroying = false
		position = saved_pos
		scale = Vector2(1.0, 1.0)
		destroyed_overlay.visible = false
		# _on_card_destroyed() calls _refresh_card_node() 0.55s after the signal,
		# which updates card_data and resets modulate via _clear_rarity().
	)

func play_attack_animation(direction: Vector2) -> void:
	var start_pos := position
	var tween := create_tween()
	tween.tween_property(self, "position", position + direction * 10, 0.08)
	tween.tween_property(self, "position", start_pos, 0.08)

# ─────────────────────────────────────────────────────────────
# Input
# ─────────────────────────────────────────────────────────────
func _play_peek_flip(show_face_up: bool) -> void:
	if _flip_tween != null:
		_flip_tween.kill()
		scale = Vector2(1.0, 1.0)
	pivot_offset = size * 0.5
	_flip_tween = create_tween()
	_flip_tween.tween_property(self, "scale", Vector2(0.05, 1.0), 0.14) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var show_fn := func() -> void:
		if show_face_up:
			match card_data.card_type:
				"character": _show_character_face_up()
				"trap":      _show_trap_face_up()
				"tech":      _show_tech_face_up()
		else:
			_show_face_down()
		if is_selected:
			selection_border.visible = true
	_flip_tween.tween_callback(show_fn)
	_flip_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.14) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if event.double_click:
				if card_data != null and card_data.card_type != "dead_end":
					# Block detail view on opponent's face-down cards
					if card_data.face_up or player_owner == GameState.current_player:
						card_detail_requested.emit(card_data.card_name, card_data.card_type, player_owner, grid_pos.x, grid_pos.y)
						accept_event()
			else:
				card_clicked.emit()
				accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		card_clicked.emit()
		accept_event()

func _on_mouse_entered() -> void:
	if is_locked:
		return
	# Hover flip disabled — peeking is now global (PEEK button / auto-on each turn)
	bg.color = bg.color.lightened(0.08)

func _on_mouse_exited() -> void:
	_refresh_display()
	if is_selected:
		selection_border.visible = true
