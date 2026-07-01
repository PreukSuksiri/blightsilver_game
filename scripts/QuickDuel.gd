extends Control
## Quick Duel — tutorial prompt, tier picker, and vault duel launcher.

const DeckData = preload("res://resources/DeckData.gd")
const CAPSULE_W := 280.0
const CAPSULE_H := 440.0
const CAPSULE_GAP := 40.0
const CAPSULE_SIDE_MARGIN := 96.0
const CAPSULE_REWARD_ROW_H := 36.0
const TIER_FONT_SIZE := 34
const HEADER_HEIGHT := 44.0
const TITLE_FONT_SIZE := 26
const TITLE_COLOR := Color(0.40, 0.85, 1.0, 1.0)
const REWARD_SHADOW_COLOR := Color(0, 0, 0, 1)
const REWARD_SHADOW_OFFSET := Vector2(2, 2)
const HOVER_OVERLAY_COLOR := Color(1.0, 1.0, 1.0, 0.22)
const DEFAULT_PORTRAIT_P1 := "res://assets/textures/ui/portraits/profile_player_1_default.png"
const DEFAULT_PORTRAIT_P2 := "res://assets/textures/ui/portraits/profile_player_2_default.png"
const PORTRAIT_REF_H := 720.0
const PORTRAIT_PEEK := 0.4
const SettingsMenuScene := preload("res://scenes/settings_menu.tscn")
const ProtagonistOverlayScene := preload("res://scripts/ProtagonistOverlay.gd")
const _ROUNDED_RECT_CLIP: Shader = preload("res://assets/shaders/rounded_rect_clip.gdshader")
const CAPSULE_FRAME_RADIUS := 12.0
const CAPSULE_FRAME_BORDER := 2.0
const CAPSULE_IMAGE_RADIUS := CAPSULE_FRAME_RADIUS - CAPSULE_FRAME_BORDER
const OVERLAY_Z_INDEX := 80

var _picker_panel: Control = null
var _status_lbl: Label = null
var _casual_btn: Button = null
var _reroll_btn: Button = null
var _tier_capsules: Dictionary = {}
var _player_portrait: TextureRect = null
var _switch_char_btn: Button = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	VNPlayer.dismiss_overlay_if_present(get_tree())
	BGMManager.play_context(BGMManager.CONTEXT_MAIN_MENU, 0.6, 0.6)
	_build_shell()
	CheckerTransition.fade_in()
	if SaveManager.is_attack_tutorial_complete():
		_show_picker()
	else:
		_show_tutorial_prompt()


func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.10, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_header()

	_picker_panel = Control.new()
	_picker_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_picker_panel.offset_top = HEADER_HEIGHT
	_picker_panel.visible = false
	_picker_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_add_panel(_picker_panel)

	_build_picker_ui()
	_build_player_portrait_zone()


func _root_add_panel(panel: Control) -> void:
	add_child(panel)


func _build_header() -> void:
	var top_bg := Panel.new()
	top_bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bg.custom_minimum_size.y = HEADER_HEIGHT
	var top_sb := StyleBoxFlat.new()
	top_sb.bg_color = Color(0.031, 0.051, 0.122, 1.0)
	top_sb.border_width_bottom = 1
	top_sb.border_color = Color(0.18, 0.549, 1.0, 0.2)
	top_bg.add_theme_stylebox_override("panel", top_sb)
	add_child(top_bg)

	var title := Label.new()
	MenuScreenHeader.style_title(title, "QUICK DUEL")
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -240.0
	title.offset_top = 8.0
	title.offset_right = 240.0
	title.offset_bottom = 36.0
	add_child(title)

	var close_btn := Button.new()
	MenuScreenHeader.style_close_button(close_btn)
	MenuScreenHeader.anchor_close_top_right(close_btn)
	close_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	add_child(close_btn)

	var ach_btn := Button.new()
	ach_btn.text = "Achievements"
	ach_btn.custom_minimum_size = Vector2(120, 32)
	ach_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	ach_btn.offset_left = -178.0
	ach_btn.offset_top = 6.0
	ach_btn.offset_right = -58.0
	ach_btn.offset_bottom = 38.0
	ach_btn.pressed.connect(func() -> void:
		AchievementListOverlay.open(self))
	add_child(ach_btn)


func _build_player_portrait_zone() -> void:
	var portrait_path: String = SaveManager.get_protagonist_portrait_path()
	var tex: Texture2D = GameState.load_portrait_texture(portrait_path)

	_player_portrait = TextureRect.new()
	_player_portrait.texture = tex
	_player_portrait.layout_mode = 1
	_player_portrait.anchor_left = 0.0
	_player_portrait.anchor_top = 1.0
	_player_portrait.anchor_right = 0.0
	_player_portrait.anchor_bottom = 1.0
	_player_portrait.offset_bottom = 0.0
	_apply_player_portrait_layout(tex)
	_player_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_player_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_player_portrait.flip_h = true
	_player_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_portrait.z_index = 2
	add_child(_player_portrait)

	_switch_char_btn = Button.new()
	_switch_char_btn.text = "Switch Character"
	_switch_char_btn.custom_minimum_size = Vector2(168, 34)
	_switch_char_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_switch_char_btn.offset_left = 12.0
	_switch_char_btn.offset_top = -52.0
	_switch_char_btn.offset_right = 180.0
	_switch_char_btn.offset_bottom = -16.0
	_switch_char_btn.z_index = 10
	_switch_char_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_switch_char_btn.pressed.connect(_open_protagonist_overlay)
	add_child(_switch_char_btn)


func _refresh_player_portrait() -> void:
	if _player_portrait == null:
		return
	var portrait_path: String = SaveManager.get_protagonist_portrait_path()
	var tex: Texture2D = GameState.load_portrait_texture(portrait_path)
	_player_portrait.texture = tex
	_apply_player_portrait_layout(tex)


func _apply_player_portrait_layout(tex: Texture2D) -> void:
	if _player_portrait == null:
		return
	var portrait_w: float = PORTRAIT_REF_H * 0.55
	if tex != null:
		var sz := tex.get_size()
		if sz.y > 0.0:
			portrait_w = PORTRAIT_REF_H * sz.x / sz.y
	_player_portrait.offset_left = -portrait_w * PORTRAIT_PEEK
	_player_portrait.offset_top = -PORTRAIT_REF_H
	_player_portrait.offset_right = portrait_w * (1.0 - PORTRAIT_PEEK)


func _open_protagonist_overlay() -> void:
	var overlay: ProtagonistOverlay = ProtagonistOverlayScene.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = OVERLAY_Z_INDEX
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if overlay.has_signal("closed"):
		overlay.closed.connect(func() -> void:
			_refresh_player_portrait())
	add_child(overlay)


func _set_protagonist_zone_visible(visible: bool) -> void:
	if _player_portrait != null:
		_player_portrait.visible = visible
	if _switch_char_btn != null:
		_switch_char_btn.visible = visible


func _show_tutorial_prompt() -> void:
	_picker_panel.visible = false
	_set_protagonist_zone_visible(false)
	if GameDialog.has_open_overlay(self):
		return
	GameDialog.confirmation_overlay(
		self,
		"Quick Duel Tutorial",
		"Do you need a tutorial on card battle?",
		"Yes — Teach Me",
		"No — Skip",
		func() -> void: launch_tutorial(),
		func() -> void:
			SaveManager.mark_attack_tutorial_complete()
			_show_picker())


func _build_picker_ui() -> void:
	var body := Control.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picker_panel.add_child(body)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -56.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(center)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(CAPSULE_SIDE_MARGIN))
	margin.add_theme_constant_override("margin_right", int(CAPSULE_SIDE_MARGIN))
	center.add_child(margin)

	var tier_row := HBoxContainer.new()
	tier_row.add_theme_constant_override("separation", CAPSULE_GAP)
	tier_row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(tier_row)

	for tier: String in ["easy", "normal", "hard"]:
		var capsule := _build_tier_capsule(tier)
		tier_row.add_child(capsule["root"])
		_tier_capsules[tier] = capsule

	var bottom_bar := HBoxContainer.new()
	bottom_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	bottom_bar.offset_left = -560.0
	bottom_bar.offset_top = -52.0
	bottom_bar.offset_right = -24.0
	bottom_bar.offset_bottom = -16.0
	bottom_bar.add_theme_constant_override("separation", 12)
	bottom_bar.alignment = BoxContainer.ALIGNMENT_END
	body.add_child(bottom_bar)

	_casual_btn = Button.new()
	_casual_btn.custom_minimum_size = Vector2(220, 36)
	_casual_btn.pressed.connect(_open_settings)
	bottom_bar.add_child(_casual_btn)

	_reroll_btn = Button.new()
	_reroll_btn.custom_minimum_size = Vector2(220, 36)
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	bottom_bar.add_child(_reroll_btn)

	_status_lbl = Label.new()
	_status_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status_lbl.offset_top = -28.0
	_status_lbl.offset_bottom = -8.0
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 12)
	_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.45))
	body.add_child(_status_lbl)


func _show_picker() -> void:
	GameDialog.close_overlay(self)
	_picker_panel.visible = true
	_set_protagonist_zone_visible(true)
	if SaveManager.reconcile_protagonist_selection():
		SaveManager.save_data()
	_sanitize_saved_offers_if_needed()
	if GameState.quick_duel_reroll_previews or not SaveManager.has_quick_duel_offers():
		_roll_all_tier_offers()
		GameState.quick_duel_reroll_previews = false
	_refresh_picker_capsules()
	_refresh_casual_button()
	_refresh_reroll_button()
	_refresh_player_portrait()


func _roll_all_tier_offers() -> void:
	var previews: Dictionary = {}
	var rewards: Dictionary = {}
	var identities: Dictionary = {}
	var demo_only: bool = SaveManager.demo_mode
	var protagonist_id: String = SaveManager.quick_duel_protagonist_id
	for tier: String in ["easy", "normal", "hard"]:
		var tags: Array = QuickDuelRewards.get_tier_tags(tier)
		var entry: Dictionary = AIDeckVault.pick_random_entry_for_tags(tags, demo_only)
		previews[tier] = str(entry.get("id", "")).strip_edges() if not entry.is_empty() else ""
		rewards[tier] = QuickDuelRewards.pick_random_rewards(tier)
		var identity: Dictionary = AIIdentityVault.pick_random_for_tier(tier, protagonist_id)
		identities[tier] = str(identity.get("id", "")).strip_edges() if not identity.is_empty() else ""
	SaveManager.set_quick_duel_tier_offers(previews, rewards, identities)


func _sanitize_saved_offers_if_needed() -> void:
	if not SaveManager.has_quick_duel_offers():
		return
	var previews: Dictionary = SaveManager.quick_duel_tier_previews.duplicate(true)
	var rewards: Dictionary = {}
	var changed: bool = false
	for tier: String in ["easy", "normal", "hard"]:
		var raw: Array = SaveManager.get_quick_duel_rewards(tier)
		var fixed: Array = QuickDuelRewards.repair_tier_rewards(tier, raw)
		fixed = QuickDuelRewards.dedupe_rewards(fixed)
		rewards[tier] = fixed
		if JSON.stringify(fixed) != JSON.stringify(raw):
			changed = true
	if changed:
		SaveManager.set_quick_duel_tier_offers(previews, rewards, SaveManager.quick_duel_tier_identities)


func _refresh_picker_capsules() -> void:
	var all_empty: bool = true
	for tier: String in ["easy", "normal", "hard"]:
		var entry_id: String = SaveManager.get_quick_duel_preview(tier)
		var entry: Dictionary = AIDeckVault.get_entry(entry_id) if not entry_id.is_empty() else {}
		_update_tier_capsule(tier, entry)
		if not entry.is_empty():
			all_empty = false
	if all_empty:
		_status_lbl.text = "No duels available — check vault tags"
	else:
		_status_lbl.text = ""


func _build_tier_capsule(tier: String) -> Dictionary:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.alignment = BoxContainer.ALIGNMENT_CENTER

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(CAPSULE_W, CAPSULE_H)
	btn.toggle_mode = false
	_apply_transparent_button_style(btn)
	btn.pressed.connect(func() -> void: launch_vault_duel(tier))
	root.add_child(btn)

	return {
		"root": root,
		"btn": btn,
	}


func _apply_transparent_button_style(btn: Button) -> void:
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_stylebox_override("disabled", empty)


func _update_tier_capsule(tier: String, entry: Dictionary) -> void:
	var cap: Dictionary = _tier_capsules.get(tier, {})
	if cap.is_empty():
		return
	var btn: Button = cap["btn"]
	if btn == null:
		return

	for c: Node in btn.get_children():
		c.queue_free()

	var rewards: Array = SaveManager.get_quick_duel_rewards(tier)
	var reward_rows: int = maxi(1, rewards.size())
	var reward_h: float = CAPSULE_REWARD_ROW_H * reward_rows

	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.18, 0.95)
	sb.border_color = Color(0.35, 0.55, 0.9, 0.6)
	sb.set_border_width_all(int(CAPSULE_FRAME_BORDER))
	sb.set_corner_radius_all(int(CAPSULE_FRAME_RADIUS))
	frame.add_theme_stylebox_override("panel", sb)
	btn.add_child(frame)

	var inner := Control.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(inner)

	var image_clip := Control.new()
	image_clip.name = "ImageClip"
	image_clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(image_clip)

	if entry.is_empty():
		btn.disabled = true
		image_clip.add_child(_make_capsule_fill_panel(Color(0.12, 0.12, 0.16, 1.0), CAPSULE_IMAGE_RADIUS))
	else:
		btn.disabled = false
		var tex: Texture2D = AIDeckVault.resolve_preview_texture(entry)
		if tex != null:
			var img := TextureRect.new()
			img.texture = tex
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# PanelContainer insets inner by border_width on every side, so
			# img is (CAPSULE_W - 2*border) × (CAPSULE_H - 2*border).  Pass
			# that actual size so all four arc centres land on the frame's
			# inner-border arc, not just the top-left one.
			_apply_rounded_rect_clip(img, CAPSULE_IMAGE_RADIUS,
					Vector2(CAPSULE_W - 2.0 * CAPSULE_FRAME_BORDER,
							CAPSULE_H - 2.0 * CAPSULE_FRAME_BORDER))
			image_clip.add_child(img)
		else:
			image_clip.add_child(_make_capsule_fill_panel(Color(0.12, 0.12, 0.16, 1.0), CAPSULE_IMAGE_RADIUS))

	var tier_center := CenterContainer.new()
	tier_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tier_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tier_center.z_index = 2
	inner.add_child(tier_center)

	var tier_lbl := Label.new()
	tier_lbl.text = tier.capitalize()
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier_lbl.add_theme_font_override("font", FontManager.make_font("display_serif", 600))
	tier_lbl.add_theme_font_size_override("font_size", TIER_FONT_SIZE)
	tier_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	tier_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	tier_lbl.add_theme_constant_override("shadow_offset_x", 2)
	tier_lbl.add_theme_constant_override("shadow_offset_y", 2)
	tier_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tier_center.add_child(tier_lbl)

	var reward_back := Panel.new()
	reward_back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	reward_back.offset_top = -reward_h
	reward_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_back.z_index = 3
	var reward_sb := StyleBoxFlat.new()
	reward_sb.bg_color = Color(0.0, 0.0, 0.0, 0.42)
	reward_sb.set_content_margin_all(0)
	reward_sb.corner_radius_bottom_left = int(CAPSULE_IMAGE_RADIUS)
	reward_sb.corner_radius_bottom_right = int(CAPSULE_IMAGE_RADIUS)
	reward_back.add_theme_stylebox_override("panel", reward_sb)
	inner.add_child(reward_back)

	var reward_vbox := VBoxContainer.new()
	reward_vbox.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	reward_vbox.offset_top = -reward_h + 4.0
	reward_vbox.offset_bottom = -4.0
	reward_vbox.offset_left = 8.0
	reward_vbox.offset_right = -8.0
	reward_vbox.add_theme_constant_override("separation", 2)
	reward_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_vbox.z_index = 4
	inner.add_child(reward_vbox)

	var multi: bool = rewards.size() > 1
	for rw: Variant in rewards:
		if rw is Dictionary:
			reward_vbox.add_child(_build_reward_hint_row(rw as Dictionary, multi))

	var hover := Panel.new()
	hover.visible = false
	hover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover.z_index = 10
	var hover_sb := StyleBoxFlat.new()
	hover_sb.bg_color = HOVER_OVERLAY_COLOR
	hover_sb.set_corner_radius_all(int(CAPSULE_FRAME_RADIUS))
	hover_sb.set_content_margin_all(0)
	hover.add_theme_stylebox_override("panel", hover_sb)
	inner.add_child(hover)

	_clear_button_hover_connections(btn)
	btn.mouse_entered.connect(_on_capsule_mouse_entered.bind(hover))
	btn.mouse_exited.connect(_on_capsule_mouse_exited.bind(hover))


func _apply_rounded_rect_clip(
		host: Control,
		corner_radius: float,
		rect_size: Vector2 = Vector2.ZERO
) -> void:
	var rc_mat := ShaderMaterial.new()
	rc_mat.shader = _ROUNDED_RECT_CLIP
	rc_mat.set_shader_parameter("corner_radius", corner_radius)
	# rect_size is used for the SDF centre calculation. The shader reads local
	# pixel position from VERTEX (not UV), so no dynamic sync is needed —
	# UV-space crop from STRETCH_KEEP_ASPECT_COVERED no longer affects clipping.
	if rect_size != Vector2.ZERO:
		rc_mat.set_shader_parameter("rect_size", rect_size)
	host.material = rc_mat


func _make_capsule_fill_panel(color: Color, corner_radius: float) -> Panel:
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = color
	fill_sb.set_corner_radius_all(int(corner_radius))
	fill_sb.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", fill_sb)
	return panel


func _clear_button_hover_connections(btn: Button) -> void:
	for conn: Dictionary in btn.mouse_entered.get_connections():
		btn.mouse_entered.disconnect(conn["callable"])
	for conn: Dictionary in btn.mouse_exited.get_connections():
		btn.mouse_exited.disconnect(conn["callable"])


func _on_capsule_mouse_entered(hover: Panel) -> void:
	if hover != null and is_instance_valid(hover):
		hover.visible = true


func _on_capsule_mouse_exited(hover: Panel) -> void:
	if hover != null and is_instance_valid(hover):
		hover.visible = false


func _build_reward_hint_row(reward: Dictionary, compact: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_size := Vector2(24, 24) if compact else Vector2(28, 28)
	var icon_path: String = QuickDuelRewards.get_reward_icon_path(reward)
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var tex: Texture2D = load(icon_path) as Texture2D
		row.add_child(_make_reward_icon_with_shadow(tex, icon_size))

	var lbl := Label.new()
	lbl.text = QuickDuelRewards.get_reward_label(reward)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.max_lines_visible = 2
	lbl.add_theme_font_size_override("font_size", 10 if compact else 11)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 1.0))
	lbl.add_theme_color_override("font_shadow_color", REWARD_SHADOW_COLOR)
	lbl.add_theme_constant_override("shadow_offset_x", int(REWARD_SHADOW_OFFSET.x))
	lbl.add_theme_constant_override("shadow_offset_y", int(REWARD_SHADOW_OFFSET.y))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lbl)
	return row


func _make_reward_icon_with_shadow(tex: Texture2D, size: Vector2) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = size
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow := TextureRect.new()
	shadow.custom_minimum_size = size
	shadow.position = REWARD_SHADOW_OFFSET
	shadow.texture = tex
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shadow.modulate = REWARD_SHADOW_COLOR
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(shadow)
	var icon := TextureRect.new()
	icon.custom_minimum_size = size
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(icon)
	return wrap


func _refresh_casual_button() -> void:
	if _casual_btn == null:
		return
	var enabled: bool = SaveManager.is_casual_mode()
	_casual_btn.text = "Casual Mode : Enabled" if enabled else "Casual Mode : Disabled"


func _refresh_reroll_button() -> void:
	if _reroll_btn == null:
		return
	var cost: int = QuickDuelRewards.get_reroll_cost()
	_reroll_btn.disabled = Collection.credits < cost
	_reroll_btn.text = "Re-roll (%d Credits)" % cost


func _on_reroll_pressed() -> void:
	var cost: int = QuickDuelRewards.get_reroll_cost()
	if Collection.credits < cost:
		_status_lbl.text = "Not enough credits (%d needed)." % cost
		return
	Collection.spend_credits(cost)
	GlobalStatManager.on_quick_duel_reroll()
	_roll_all_tier_offers()
	_refresh_picker_capsules()
	_refresh_reroll_button()
	_status_lbl.text = ""


func _open_settings() -> void:
	if get_node_or_null("SettingsMenuOverlay") != null:
		return
	var settings: Control = SettingsMenuScene.instantiate()
	settings.name = "SettingsMenuOverlay"
	settings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings.z_index = OVERLAY_Z_INDEX
	settings.mouse_filter = Control.MOUSE_FILTER_STOP
	if settings.has_signal("closed"):
		settings.closed.connect(func() -> void:
			_refresh_casual_button()
			_refresh_reroll_button())
	add_child(settings)
	settings.move_to_front()


func _apply_protagonist_to_battle() -> void:
	GameState.quick_duel_protagonist_id = SaveManager.quick_duel_protagonist_id
	while GameState.player_portraits.size() < 2:
		GameState.player_portraits.append(DEFAULT_PORTRAIT_P2)
	GameState.player_portraits[0] = SaveManager.get_protagonist_portrait_path()
	var names: Array[String] = GameState.campaign_player_names.duplicate()
	if names.size() < 2:
		names = [SaveManager.get_protagonist_display_name(), "Opponent"]
	names[0] = SaveManager.get_protagonist_display_name()
	GameState.campaign_player_names = names


func _apply_ai_identity_to_battle(tier: String) -> void:
	while GameState.player_portraits.size() < 2:
		GameState.player_portraits.append(DEFAULT_PORTRAIT_P2)
	var identity_id: String = SaveManager.get_quick_duel_identity(tier)
	var identity: Dictionary = AIIdentityVault.get_entry(identity_id)
	if identity.is_empty():
		return
	var illus: String = str(identity.get("illustration", "")).strip_edges()
	if illus != "":
		GameState.player_portraits[1] = illus
	var ai_name: String = str(identity.get("name", "")).strip_edges()
	if not ai_name.is_empty():
		var names: Array[String] = GameState.campaign_player_names.duplicate()
		if names.size() < 2:
			names = [SaveManager.get_protagonist_display_name(), "Opponent"]
		names[1] = ai_name
		GameState.campaign_player_names = names


func launch_tutorial() -> void:
	var intro: String = QuickDuelRewards.get_tutorial_intro_vn()
	if intro.is_empty():
		_status_lbl.text = "Tutorial intro VN not configured."
		return
	var battle_path: String = QuickDuelRewards.find_tutorial_battle_in_vn(intro)
	if battle_path.is_empty():
		_status_lbl.text = "Tutorial intro VN has no tutorial_battle beat."
		return
	_prepare_quick_duel_tutorial_context()
	GameDialog.close_overlay(self)
	VNPlayer.launch_overlay(intro, _on_tutorial_intro_overlay_finished)


func _prepare_quick_duel_tutorial_context() -> void:
	GameState.post_battle_return_scene = "res://scenes/quick_duel.tscn"
	GameState.quick_duel_launch = true
	GameState.quick_duel_active = false
	_apply_protagonist_to_battle()


func _on_tutorial_intro_overlay_finished() -> void:
	# Beat with tutorial_battle starts the duel inside VNPlayer — overlay ends without _finish.
	if TutorialBattleManager.is_prepared or TutorialBattleManager.is_active:
		return
	var intro: String = QuickDuelRewards.get_tutorial_intro_vn()
	var battle_path: String = QuickDuelRewards.find_tutorial_battle_in_vn(intro)
	if battle_path.is_empty():
		return
	_begin_guided_tutorial_battle(battle_path)


func _begin_guided_tutorial_battle(battle_path: String) -> void:
	_prepare_quick_duel_tutorial_context()
	GameState.new_game(GameState.GameMode.VS_AI)
	var err: String = TutorialBattleManager.configure_battle_from_path(battle_path, true)
	if not err.is_empty():
		push_error(err)
		return
	GameState.apply_tutorial_opponent_crystals()
	BGMManager.stop(0.0)
	CheckerTransition.fade_out_to_battle(func() -> void:
		VNPlayer.dismiss_overlay_if_present(get_tree())
		get_tree().change_scene_to_file("res://scenes/game_board.tscn"))


func launch_vault_duel(tier: String) -> void:
	GlobalStatManager.on_first_touch("quick_duel_battle")
	var entry_id: String = SaveManager.get_quick_duel_preview(tier)
	if entry_id.is_empty():
		return
	var cfg: Dictionary = AIDeckVault.build_ai_battle_config(entry_id, 0)
	if not bool(cfg.get("ok", false)):
		_status_lbl.text = "Invalid opponent deck."
		return

	GameState.post_battle_return_scene = "res://scenes/quick_duel.tscn"
	GameState.quick_duel_launch = false
	GameState.quick_duel_active = true
	GameState.quick_duel_battle_tier = tier

	# Abandoned tutorial battles can leave tutorial flags set and block setup formations.
	if TutorialBattleManager.is_active or TutorialBattleManager.is_prepared:
		TutorialBattleManager.stop()

	GameState.new_game(GameState.GameMode.VS_AI)
	GameState.battle_player_deck = null
	GameState.battle_player_forced_cells.clear()

	_apply_protagonist_to_battle()
	_apply_ai_identity_to_battle(tier)
	GlobalStatManager.on_duel_started({"is_quick_duel": true, "is_tutorial": false})
	if str(GameState.player_portraits[1]).strip_edges().is_empty():
		GameState.player_portraits[1] = DEFAULT_PORTRAIT_P2
	if GameState.campaign_player_names.size() < 2 \
			or str(GameState.campaign_player_names[1]).strip_edges().is_empty():
		var names: Array[String] = GameState.campaign_player_names.duplicate()
		if names.size() < 2:
			names = [SaveManager.get_protagonist_display_name(), "Opponent"]
		names[1] = str(AIDeckVault.get_entry(entry_id).get("label", "Opponent"))
		GameState.campaign_player_names = names

	AIDeckVault.apply_enemy_battle_config(cfg)
	GameState.battle_ai_deck = cfg.get("deck")
	GameState.battle_ai_forced_cells = (cfg.get("forced_cells", []) as Array).duplicate(true)
	GameState.battle_ai_forced_tech = (cfg.get("forced_tech", []) as Array).duplicate(true)
	GameState.battle_ai_featured_union = str(cfg.get("featured_union", "")).strip_edges()
	GameState.battle_featured_unions = ["", GameState.battle_ai_featured_union]

	BGMManager.stop(0.0)
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game_board.tscn"))
