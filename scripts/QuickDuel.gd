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
const SettingsMenuScene := preload("res://scenes/settings_menu.tscn")

var _picker_panel: Control = null
var _prompt_panel: Control = null
var _status_lbl: Label = null
var _casual_btn: Button = null
var _reroll_btn: Button = null
var _tier_capsules: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
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

	_prompt_panel = Control.new()
	_prompt_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_panel.offset_top = HEADER_HEIGHT
	_root_add_panel(_prompt_panel)

	_picker_panel = Control.new()
	_picker_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_picker_panel.offset_top = HEADER_HEIGHT
	_picker_panel.visible = false
	_root_add_panel(_picker_panel)

	_build_picker_ui()


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
	title.text = "QUICK DUEL"
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -240.0
	title.offset_top = 8.0
	title.offset_right = 240.0
	title.offset_bottom = 36.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(38, 32)
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -52.0
	close_btn.offset_top = 6.0
	close_btn.offset_right = -12.0
	close_btn.offset_bottom = 38.0
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(0.55, 0.72, 1.0, 0.85))
	close_btn.add_theme_stylebox_override("normal", _make_close_stylebox())
	close_btn.add_theme_stylebox_override("hover", _make_close_stylebox())
	close_btn.add_theme_stylebox_override("pressed", _make_close_stylebox())
	close_btn.add_theme_stylebox_override("focus", _make_close_stylebox())
	close_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	add_child(close_btn)


func _make_close_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.04, 0.04, 1.0)
	sb.set_border_width_all(1)
	sb.border_color = Color(1.0, 0.30, 0.30, 0.7)
	sb.set_corner_radius_all(4)
	return sb


func _show_tutorial_prompt() -> void:
	_prompt_panel.visible = true
	_picker_panel.visible = false
	for c: Node in _prompt_panel.get_children():
		c.queue_free()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_panel.add_child(center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.14, 0.97)
	sb.border_color = Color(0.38, 0.65, 1.0, 0.5)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.custom_minimum_size = Vector2(420, 0)
	panel.add_child(vbox)

	var lbl := Label.new()
	lbl.text = "Do you need the attack tutorial?"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	vbox.add_child(lbl)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	vbox.add_child(row)

	var yes_btn := Button.new()
	yes_btn.text = "Yes — Teach Me"
	yes_btn.custom_minimum_size = Vector2(160, 44)
	yes_btn.pressed.connect(func() -> void: launch_tutorial())
	row.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "No — Skip"
	no_btn.custom_minimum_size = Vector2(160, 44)
	no_btn.pressed.connect(func() -> void:
		SaveManager.mark_attack_tutorial_complete()
		_show_picker())
	row.add_child(no_btn)


func _build_picker_ui() -> void:
	var body := Control.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_picker_panel.add_child(body)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -56.0
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
	_prompt_panel.visible = false
	_picker_panel.visible = true
	_sanitize_saved_offers_if_needed()
	if GameState.quick_duel_reroll_previews or not SaveManager.has_quick_duel_offers():
		_roll_all_tier_offers()
		GameState.quick_duel_reroll_previews = false
	_refresh_picker_capsules()
	_refresh_casual_button()
	_refresh_reroll_button()


func _roll_all_tier_offers() -> void:
	var previews: Dictionary = {}
	var rewards: Dictionary = {}
	var demo_only: bool = SaveManager.demo_mode
	for tier: String in ["easy", "normal", "hard"]:
		var tags: Array = QuickDuelRewards.get_tier_tags(tier)
		var entry: Dictionary = AIDeckVault.pick_random_entry_for_tags(tags, demo_only)
		previews[tier] = str(entry.get("id", "")).strip_edges() if not entry.is_empty() else ""
		rewards[tier] = QuickDuelRewards.pick_random_rewards(tier)
	SaveManager.set_quick_duel_tier_offers(previews, rewards)


func _sanitize_saved_offers_if_needed() -> void:
	if not SaveManager.has_quick_duel_offers():
		return
	var previews: Dictionary = SaveManager.quick_duel_tier_previews.duplicate(true)
	var rewards: Dictionary = {}
	var changed: bool = false
	for tier: String in ["easy", "normal", "hard"]:
		var raw: Array = SaveManager.get_quick_duel_rewards(tier)
		var fixed: Array = QuickDuelRewards.repair_tier_rewards(tier, raw)
		rewards[tier] = fixed
		if JSON.stringify(fixed) != JSON.stringify(raw):
			changed = true
	if changed:
		SaveManager.set_quick_duel_tier_offers(previews, rewards)


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
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	frame.add_theme_stylebox_override("panel", sb)
	btn.add_child(frame)

	var inner := Control.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.clip_contents = true
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(inner)

	if entry.is_empty():
		btn.disabled = true
		var ph := ColorRect.new()
		ph.color = Color(0.12, 0.12, 0.16, 1.0)
		ph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(ph)
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
			inner.add_child(img)
		else:
			var ph2 := ColorRect.new()
			ph2.color = Color(0.12, 0.12, 0.16, 1.0)
			ph2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			ph2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner.add_child(ph2)

	var tier_lbl := Label.new()
	tier_lbl.text = tier.capitalize()
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tier_lbl.offset_bottom = reward_h * 0.35
	tier_lbl.add_theme_font_size_override("font_size", TIER_FONT_SIZE)
	tier_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	tier_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	tier_lbl.add_theme_constant_override("shadow_offset_x", 2)
	tier_lbl.add_theme_constant_override("shadow_offset_y", 2)
	tier_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tier_lbl.z_index = 2
	inner.add_child(tier_lbl)

	var reward_back := ColorRect.new()
	reward_back.color = Color(0.0, 0.0, 0.0, 0.42)
	reward_back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	reward_back.offset_top = -reward_h
	reward_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_back.z_index = 3
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

	var hover := ColorRect.new()
	hover.color = HOVER_OVERLAY_COLOR
	hover.visible = false
	hover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover.z_index = 10
	inner.add_child(hover)

	_clear_button_hover_connections(btn)
	btn.mouse_entered.connect(_on_capsule_mouse_entered.bind(hover))
	btn.mouse_exited.connect(_on_capsule_mouse_exited.bind(hover))


func _clear_button_hover_connections(btn: Button) -> void:
	for conn: Dictionary in btn.mouse_entered.get_connections():
		btn.mouse_entered.disconnect(conn["callable"])
	for conn: Dictionary in btn.mouse_exited.get_connections():
		btn.mouse_exited.disconnect(conn["callable"])


func _on_capsule_mouse_entered(hover: ColorRect) -> void:
	if hover != null and is_instance_valid(hover):
		hover.visible = true


func _on_capsule_mouse_exited(hover: ColorRect) -> void:
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
	_roll_all_tier_offers()
	_refresh_picker_capsules()
	_refresh_reroll_button()
	_status_lbl.text = ""


func _open_settings() -> void:
	var settings: Control = SettingsMenuScene.instantiate()
	if settings.has_signal("closed"):
		settings.closed.connect(func() -> void:
			_refresh_casual_button()
			_refresh_reroll_button())
	add_child(settings)


func launch_tutorial() -> void:
	var intro: String = QuickDuelRewards.get_tutorial_intro_vn()
	var battle_path: String = QuickDuelRewards.get_tutorial_battle_path()
	if battle_path.is_empty():
		_status_lbl.text = "Tutorial battle not configured."
		return
	if intro.is_empty():
		_begin_guided_tutorial_battle(battle_path)
	else:
		VNPlayer.launch_overlay(intro, func() -> void: _begin_guided_tutorial_battle(battle_path))


func _begin_guided_tutorial_battle(battle_path: String) -> void:
	GameState.post_battle_return_scene = "res://scenes/quick_duel.tscn"
	GameState.quick_duel_launch = true
	GameState.quick_duel_active = false
	var err: String = TutorialBattleManager.configure_battle_from_path(battle_path, true)
	if not err.is_empty():
		push_error(err)
		return
	GameState.apply_tutorial_opponent_crystals()
	BGMManager.stop(0.0)
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game_board.tscn"))


func launch_vault_duel(tier: String) -> void:
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

	GameState.new_game(GameState.GameMode.VS_AI)
	GameState.battle_player_deck = null
	GameState.battle_player_forced_cells.clear()
	var active: DeckData = SaveManager.get_active_deck()
	if active != null:
		GameState.battle_player_forced_cells = active.get_formation_forced_cells(0)

	GameState.player_portraits[0] = DEFAULT_PORTRAIT_P1
	GameState.player_portraits[1] = DEFAULT_PORTRAIT_P2
	var opp_label: String = str(AIDeckVault.get_entry(entry_id).get("label", "Opponent"))
	GameState.campaign_player_names = ["Player", opp_label]

	AIDeckVault.apply_enemy_battle_config(cfg)
	GameState.battle_ai_deck = cfg.get("deck")
	GameState.battle_ai_forced_cells = (cfg.get("forced_cells", []) as Array).duplicate(true)
	GameState.battle_ai_forced_tech = (cfg.get("forced_tech", []) as Array).duplicate(true)
	GameState.battle_ai_featured_union = str(cfg.get("featured_union", "")).strip_edges()
	GameState.battle_featured_unions = ["", GameState.battle_ai_featured_union]

	BGMManager.stop(0.0)
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game_board.tscn"))
