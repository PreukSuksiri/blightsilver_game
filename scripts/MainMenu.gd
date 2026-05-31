extends Control

const DeckData = preload("res://resources/DeckData.gd")
const CHIVO_FONT := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")
const InventoryMenuScene = preload("res://scenes/inventory_menu.tscn")
const AdminConsoleScene = preload("res://scenes/admin_console.tscn")
const ShopMenuScene     = preload("res://scenes/shop_menu.tscn")
const CardGalleryScene  = preload("res://scenes/card_gallery.tscn")
const DeckBuilderScene  = preload("res://scenes/deck_builder.tscn")
const SettingsMenuScene  = preload("res://scenes/settings_menu.tscn")
const CampaignMapScene      = preload("res://scenes/campaign_map.tscn")
const CampaignGalleryScene  = preload("res://scenes/campaign_gallery.tscn")
const DailyDungeonMapScene  = preload("res://scenes/daily_dungeon_map.tscn")

@onready var local_2p_btn:      Button = $NewGameBtn
@onready var deck_build_btn:    Button = $DeckBuilderBtn
@onready var shop_btn:          Button = $ShopBtn
@onready var gallery_btn:       Button = $GalleryBtn
@onready var mailbox_btn:       Button = $MailboxBtn
@onready var credits_btn:       Button = $CreditsBtn
@onready var exit_game_btn:     Button = $ExitGameBtn
@onready var campaign_btn:      Button = $SettingsBtn
@onready var version_label:     Label  = $VersionLabel
@onready var fade_overlay:      ColorRect         = $FadeOverlay
@onready var deck_status_label: Label  = $DeckStatusBg/DeckStatusLabel
@onready var settings_icon_btn: Button = $SettingsIconBtn
@onready var settings_icon_shadow: Control = $SettingsIconShadow
@onready var exit_icon_btn:     Button = $ExitIconBtn
@onready var exit_icon_shadow:  Control = $ExitIconShadow
@onready var deck_status_bg:    Panel  = $DeckStatusBg

const MENU_BTN_Z := 1
const MENU_OVERLAY_Z := 25
const MENU_DROPDOWN_BACKDROP_Z := 40
const MENU_DROPDOWN_Z := 41
const MENU_STACK_GAP := 14.0

var _overlay_obscure_depth: int = 0

func _ready() -> void:
	local_2p_btn.pressed.connect(_on_campaign)
	deck_build_btn.pressed.connect(_on_deck_builder)
	shop_btn.pressed.connect(_on_shop)
	gallery_btn.pressed.connect(_on_gallery)
	mailbox_btn.pressed.connect(_on_inventory)
	credits_btn.pressed.connect(_on_credits)
	exit_game_btn.pressed.connect(_on_exit_game)
	campaign_btn.pressed.connect(_on_multiplayer)
	settings_icon_btn.pressed.connect(_on_settings)
	settings_icon_btn.tooltip_text = "Settings"
	exit_icon_btn.pressed.connect(func() -> void:
		SFXManager.play(SFXManager.SFX_BTN)
		get_tree().quit())
	exit_icon_btn.tooltip_text = "Exit Game"
	version_label.text = "v0.1 Prototype"
	if has_node("BGM"):
		$BGM.stop()
	BGMManager.play_context(BGMManager.CONTEXT_MAIN_MENU, 0.0, 0.0)
	var tween := create_tween()	
	tween.tween_property(fade_overlay, "color:a", 0.0, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_refresh_deck_status()
	_refresh_inventory_badge()
	MailboxManager.mailbox_changed.connect(_refresh_inventory_badge)
	MenuButtonConfig.load_config()
	MenuButtonConfig.visibility_changed.connect(_apply_menu_button_state)
	_apply_menu_button_state()
	# Re-open daily dungeon overlay when returning from a daily dungeon battle.
	if DailyDungeonManager.return_to_dungeon_map:
		DailyDungeonManager.return_to_dungeon_map = false
		if DailyDungeonManager.is_daily_session():
			_on_daily_dungeon()
	elif DailyDungeonManager.vn_dungeon_id != "" \
			and not DailyDungeonManager.is_story_session():
		# Orphaned story save from an abandoned session — don't auto-open anything.
		DailyDungeonManager.end_story_session()

func _refresh_deck_status() -> void:
	var deck: DeckData = SaveManager.get_active_deck()
	if deck == null:
		deck_status_label.text = "No deck saved."
		deck_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
		return
	deck_status_label.text = 'Active deck: "%s"  (%d chars / %d traps / %d tech / %d dead ends)' % [
		deck.deck_name,
		deck.characters.size(),
		deck.traps.size(),
		deck.techs.size(),
		deck.dead_end_count()
	]
	var valid: bool = deck.is_valid()
	deck_status_label.add_theme_color_override("font_color",
		Color(0.4, 0.9, 1.0) if valid else Color(1.0, 0.5, 0.3))

func _deck_warning_message() -> String:
	var deck: DeckData = SaveManager.get_active_deck()
	if deck == null:
		return "No deck saved. Please build a deck first."
	return deck.validation_message()

func _is_deck_ready() -> bool:
	var deck: DeckData = SaveManager.get_active_deck()
	return deck != null and deck.is_valid()

func _show_deck_warning() -> void:
	if get_node_or_null("DeckWarningPanel") != null:
		return
	var panel := Panel.new()
	panel.name = "DeckWarningPanel"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.059, 0.078, 0.145, 0.98)
	sb.border_width_left = 2; sb.border_width_top = 2
	sb.border_width_right = 2; sb.border_width_bottom = 2
	sb.border_color = Color(1.0, 0.5, 0.3, 0.85)
	sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8; sb.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(380, 140)
	panel.position -= panel.size * 0.5
	panel.z_index = 20
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 16; vbox.offset_top = 16
	vbox.offset_right = -16; vbox.offset_bottom = -16
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var lbl := Label.new()
	lbl.text = "Deck not ready\n" + _deck_warning_message()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_override("font", CHIVO_FONT)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.35, 1.0))
	vbox.add_child(lbl)

	var ok_btn := Button.new()
	ok_btn.text = "OK"
	ok_btn.add_theme_font_override("font", CHIVO_FONT)
	ok_btn.add_theme_font_size_override("font_size", 17)
	_apply_menu_btn_style(ok_btn, false)
	ok_btn.pressed.connect(func() -> void: panel.queue_free())
	vbox.add_child(ok_btn)

func _refresh_inventory_badge() -> void:
	var count := MailboxManager.get_unclaimed_count()
	var label := MenuButtonConfig.get_label("inventory").to_upper()
	if count > 0:
		mailbox_btn.text = "%s  [%d]" % [label, count]
		mailbox_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.65, 1.0))
	else:
		mailbox_btn.text = label
		mailbox_btn.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3, 0.85))

func _stack_button_for_key(key: String) -> Button:
	match key:
		"campaign": return local_2p_btn
		"single_player": return local_2p_btn
		"multiplayer": return campaign_btn
		"deck_builder": return deck_build_btn
		"inventory": return mailbox_btn
		"shop": return shop_btn
		"gallery": return gallery_btn
		"credits": return credits_btn
		"exit": return exit_game_btn
	return null


func _apply_menu_button_state() -> void:
	_set_main_menu_btn(local_2p_btn, "campaign")
	_set_main_menu_btn(deck_build_btn, "deck_builder")
	_set_main_menu_btn(shop_btn, "shop")
	_set_main_menu_btn(gallery_btn, "gallery")
	_set_main_menu_btn(mailbox_btn, "inventory")
	_set_main_menu_btn(credits_btn, "credits")
	_set_main_menu_btn(exit_game_btn, "exit")
	_set_main_menu_btn(campaign_btn, "multiplayer")
	_sync_corner_icon(settings_icon_btn, settings_icon_shadow, "settings")
	_sync_corner_icon(exit_icon_btn, exit_icon_shadow, "exit_icon")
	_apply_menu_button_labels()
	_apply_menu_button_positions()


func _set_main_menu_btn(btn: BaseButton, key: String) -> void:
	btn.visible = MenuButtonConfig.is_main_visible(key)
	btn.disabled = not MenuButtonConfig.is_main_enabled(key)


func _sync_corner_icon(btn: BaseButton, shadow: Control, key: String,
		obscured: bool = false) -> void:
	var visible := not obscured and MenuButtonConfig.is_main_visible(key)
	btn.visible = visible
	btn.disabled = not MenuButtonConfig.is_main_enabled(key)
	if shadow != null:
		shadow.visible = visible


func _apply_menu_button_labels() -> void:
	local_2p_btn.text = MenuButtonConfig.get_label("campaign").to_upper()
	campaign_btn.text = MenuButtonConfig.get_label("multiplayer").to_upper()
	deck_build_btn.text = MenuButtonConfig.get_label("deck_builder").to_upper()
	mailbox_btn.text = MenuButtonConfig.get_label("inventory").to_upper()
	shop_btn.text = MenuButtonConfig.get_label("shop").to_upper()
	gallery_btn.text = MenuButtonConfig.get_label("gallery").to_upper()
	credits_btn.text = MenuButtonConfig.get_label("credits").to_upper()
	exit_game_btn.text = MenuButtonConfig.get_label("exit").to_upper()


func _trailing_stack_button_y(visual_slot: int) -> float:
	if visual_slot <= MenuButtonConfig.SLOT_COUNT:
		return float(MenuButtonConfig.SLOT_TOP_Y[visual_slot])
	var overflow: int = visual_slot - MenuButtonConfig.SLOT_COUNT
	return float(MenuButtonConfig.SLOT_TOP_Y[MenuButtonConfig.SLOT_COUNT]) \
		+ overflow * (MenuButtonConfig.SLOT_BTN_HEIGHT + MENU_STACK_GAP)


func _apply_trailing_stack_button(btn: Button, key: String, visual_slot: int) -> int:
	if not MenuButtonConfig.is_main_visible(key):
		return visual_slot
	var top_y: float = _trailing_stack_button_y(visual_slot)
	_apply_stack_button_rect(btn, Vector4(
		MenuButtonConfig.SLOT_BTN_LEFT, top_y,
		MenuButtonConfig.SLOT_BTN_RIGHT,
		top_y + MenuButtonConfig.SLOT_BTN_HEIGHT))
	btn.z_index = MENU_BTN_Z
	return visual_slot + 1


func _apply_menu_button_positions() -> void:
	if _overlay_obscure_depth > 0:
		return
	var entries: Array = []
	for key: String in [
			"campaign", "multiplayer", "deck_builder",
			"inventory", "shop", "gallery"]:
		if not MenuButtonConfig.is_main_visible(key):
			continue
		if not MenuButtonConfig.uses_stack_slot(key):
			continue
		var btn: Button = _stack_button_for_key(key)
		if btn == null:
			continue
		entries.append({
			"sort_slot": MenuButtonConfig.get_sort_slot(key),
			"btn": btn,
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["sort_slot"]) < int(b["sort_slot"]))
	var visual_slot: int = 1
	for entry: Dictionary in entries:
		_apply_stack_button_rect(
			entry["btn"], MenuButtonConfig.get_slot_offsets(visual_slot))
		entry["btn"].z_index = MENU_BTN_Z
		visual_slot += 1
	visual_slot = _apply_trailing_stack_button(credits_btn, "credits", visual_slot)
	_apply_trailing_stack_button(exit_game_btn, "exit", visual_slot)


func _apply_stack_button_rect(btn: Control, rect: Vector4) -> void:
	btn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	btn.offset_left = rect.x
	btn.offset_top = rect.y
	btn.offset_right = rect.z
	btn.offset_bottom = rect.w
	btn.grow_horizontal = Control.GROW_DIRECTION_BOTH


func _position_dropdown_panel(panel: Panel, anchor: Control, panel_height: float) -> void:
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var anchor_rect := anchor.get_global_rect()
	panel.global_position = anchor_rect.position + Vector2(0.0, anchor_rect.size.y + 4.0)
	panel.size = Vector2(anchor_rect.size.x, panel_height)
	panel.z_index = MENU_DROPDOWN_Z
	panel.move_to_front()


func _close_menu_dropdowns() -> void:
	for node_name: String in [
			"ModeChoicePanel", "MultiplayerChoicePanel",
			"ModeChoiceBackdrop", "MultiplayerChoiceBackdrop"]:
		var node: Node = get_node_or_null(node_name)
		if node != null:
			node.queue_free()


func _push_main_menu_obscured() -> void:
	_overlay_obscure_depth += 1
	if _overlay_obscure_depth == 1:
		_set_main_menu_obscured(true)


func _pop_main_menu_obscured() -> void:
	_overlay_obscure_depth = maxi(0, _overlay_obscure_depth - 1)
	if _overlay_obscure_depth == 0:
		_set_main_menu_obscured(false)
		_apply_menu_button_state()


func _set_main_menu_obscured(obscured: bool) -> void:
	for key: String in [
			"campaign", "multiplayer", "deck_builder",
			"inventory", "shop", "gallery", "credits", "exit"]:
		var btn: Button = _stack_button_for_key(key)
		if btn == null:
			continue
		btn.visible = false if obscured else MenuButtonConfig.is_main_visible(key)
	_sync_corner_icon(settings_icon_btn, settings_icon_shadow, "settings", obscured)
	_sync_corner_icon(exit_icon_btn, exit_icon_shadow, "exit_icon", obscured)
	if deck_status_bg != null:
		deck_status_bg.visible = not obscured


func _on_menu_overlay_closed() -> void:
	_pop_main_menu_obscured()


func _open_menu_overlay(overlay: Control, overlay_name: String,
		on_closed: Callable = Callable()) -> Control:
	if get_node_or_null(overlay_name) != null:
		return null
	_close_menu_dropdowns()
	overlay.name = overlay_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = MENU_OVERLAY_Z
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if overlay.has_signal("closed"):
		overlay.closed.connect(_on_menu_overlay_closed)
		if on_closed.is_valid():
			overlay.closed.connect(on_closed)
	else:
		overlay.tree_exiting.connect(_on_menu_overlay_closed)
		if on_closed.is_valid():
			overlay.tree_exiting.connect(on_closed)
	_push_main_menu_obscured()
	add_child(overlay)
	overlay.move_to_front()
	return overlay


func _apply_menu_button_visibility() -> void:
	_apply_menu_button_state()

func _on_single_player() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	if not MenuButtonConfig.is_main_visible("single_player") \
			or not MenuButtonConfig.is_main_enabled("single_player"):
		return
	if get_node_or_null("ModeChoicePanel") != null:
		get_node("ModeChoicePanel").queue_free()
		return

	var visible_sub_count := 0
	if MenuButtonConfig.is_sub_visible("single_player", "campaign"):
		visible_sub_count += 1
	if MenuButtonConfig.is_sub_visible("single_player", "daily_dungeon"):
		visible_sub_count += 1
	if MenuButtonConfig.is_sub_visible("single_player", "vs_ai"):
		visible_sub_count += 1
	if visible_sub_count == 0:
		return

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.059, 0.078, 0.145, 0.98)
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.608, 0.765, 1.0, 0.5)
	sb.corner_radius_top_left     = 6
	sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left  = 6

	var backdrop := Control.new()
	backdrop.name = "ModeChoiceBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.z_index = MENU_DROPDOWN_BACKDROP_Z
	add_child(backdrop)
	backdrop.move_to_front()

	var picker := Panel.new()
	picker.name = "ModeChoicePanel"
	picker.add_theme_stylebox_override("panel", sb)
	add_child(picker)
	_position_dropdown_panel(picker, local_2p_btn, visible_sub_count * 52 + 12)

	backdrop.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed
				and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
				or (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed):
			picker.queue_free()
			backdrop.queue_free())
	picker.tree_exiting.connect(func() -> void:
		if is_instance_valid(backdrop):
			backdrop.queue_free())

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 6
	vbox.offset_top = 6
	vbox.offset_right = -6
	vbox.offset_bottom = -6
	vbox.add_theme_constant_override("separation", 6)
	picker.add_child(vbox)

	var _add_btn := func(label: String, cb: Callable, enabled: bool = true) -> void:
		var btn := Button.new()
		btn.text = label
		btn.disabled = not enabled
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_override("font", CHIVO_FONT)
		btn.add_theme_font_size_override("font_size", 18)
		if enabled:
			btn.pressed.connect(cb)
		_apply_menu_btn_style(btn, false)
		vbox.add_child(btn)

	if MenuButtonConfig.is_sub_visible("single_player", "campaign"):
		_add_btn.call("CAMPAIGN", func() -> void:
			picker.queue_free()
			if not _is_deck_ready():
				_show_deck_warning()
				return
			_on_campaign(), MenuButtonConfig.is_sub_enabled("single_player", "campaign"))

	if MenuButtonConfig.is_sub_visible("single_player", "daily_dungeon"):
		_add_btn.call("DAILY DUNGEON", func() -> void:
			picker.queue_free()
			if not _is_deck_ready():
				_show_deck_warning()
				return
			_on_daily_dungeon(), MenuButtonConfig.is_sub_enabled("single_player", "daily_dungeon"))

	if MenuButtonConfig.is_sub_visible("single_player", "vs_ai"):
		_add_btn.call("VS AI", func() -> void:
			picker.queue_free()
			if not _is_deck_ready():
				_show_deck_warning()
				return
			BGMManager.stop(0.0)
			GameState.game_mode = GameState.GameMode.VS_AI
			CheckerTransition.fade_out_to_battle(func() -> void:
				get_tree().change_scene_to_file("res://scenes/game_board.tscn")),
			MenuButtonConfig.is_sub_enabled("single_player", "vs_ai"))

func _on_multiplayer() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	if not MenuButtonConfig.is_main_visible("multiplayer") \
			or not MenuButtonConfig.is_main_enabled("multiplayer"):
		return
	if get_node_or_null("MultiplayerChoicePanel") != null:
		get_node("MultiplayerChoicePanel").queue_free()
		return

	var visible_sub_count := 0
	if MenuButtonConfig.is_sub_visible("multiplayer", "matchmaking"):
		visible_sub_count += 1
	if MenuButtonConfig.is_sub_visible("multiplayer", "private"):
		visible_sub_count += 1
	if MenuButtonConfig.is_sub_visible("multiplayer", "hot_seat"):
		visible_sub_count += 1
	if visible_sub_count == 0:
		return

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.059, 0.078, 0.145, 0.98)
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.608, 0.765, 1.0, 0.5)
	sb.corner_radius_top_left     = 6
	sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left  = 6

	var backdrop := Control.new()
	backdrop.name = "MultiplayerChoiceBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.z_index = MENU_DROPDOWN_BACKDROP_Z
	add_child(backdrop)
	backdrop.move_to_front()

	var picker := Panel.new()
	picker.name = "MultiplayerChoicePanel"
	picker.add_theme_stylebox_override("panel", sb)
	add_child(picker)
	_position_dropdown_panel(picker, campaign_btn, visible_sub_count * 52 + 12)

	backdrop.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed
				and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
				or (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed):
			picker.queue_free()
			backdrop.queue_free())
	picker.tree_exiting.connect(func() -> void:
		if is_instance_valid(backdrop):
			backdrop.queue_free())

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 6
	vbox.offset_top = 6
	vbox.offset_right = -6
	vbox.offset_bottom = -6
	vbox.add_theme_constant_override("separation", 6)
	picker.add_child(vbox)

	var _add_btn := func(label: String, cb: Callable, enabled: bool = true) -> void:
		var btn := Button.new()
		btn.text = label
		btn.disabled = not enabled
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_override("font", CHIVO_FONT)
		btn.add_theme_font_size_override("font_size", 18)
		if enabled:
			btn.pressed.connect(cb)
		_apply_menu_btn_style(btn, false)
		vbox.add_child(btn)

	if MenuButtonConfig.is_sub_visible("multiplayer", "matchmaking"):
		_add_btn.call("MATCHMAKING", func() -> void:
			picker.queue_free()
			BGMManager.stop(0.0)
			GameState.game_mode = GameState.GameMode.LOCAL_2P
			CheckerTransition.fade_out_to_battle(func() -> void:
				get_tree().change_scene_to_file("res://scenes/game_board.tscn")),
			MenuButtonConfig.is_sub_enabled("multiplayer", "matchmaking"))

	if MenuButtonConfig.is_sub_visible("multiplayer", "private"):
		_add_btn.call("PRIVATE", func() -> void:
			picker.queue_free()
			BGMManager.stop(0.0)
			GameState.game_mode = GameState.GameMode.LOCAL_2P
			CheckerTransition.fade_out_to_battle(func() -> void:
				get_tree().change_scene_to_file("res://scenes/game_board.tscn")),
			MenuButtonConfig.is_sub_enabled("multiplayer", "private"))

	if MenuButtonConfig.is_sub_visible("multiplayer", "hot_seat"):
		_add_btn.call("HOT SEAT", func() -> void:
			picker.queue_free()
			if not _is_deck_ready():
				_show_deck_warning()
				return
			BGMManager.stop(0.0)
			GameState.game_mode = GameState.GameMode.HOT_SEAT
			CheckerTransition.fade_out_to_battle(func() -> void:
				get_tree().change_scene_to_file("res://scenes/game_board.tscn")),
			MenuButtonConfig.is_sub_enabled("multiplayer", "hot_seat"))

func _on_deck_builder() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	_open_menu_overlay(DeckBuilderScene.instantiate(), "DeckBuilderOverlay",
		_refresh_deck_status)

func _on_shop() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	_open_menu_overlay(ShopMenuScene.instantiate(), "ShopMenuOverlay")

func _on_gallery() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	_open_menu_overlay(CardGalleryScene.instantiate(), "CardGalleryOverlay")

func _on_inventory() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	_open_menu_overlay(InventoryMenuScene.instantiate(), "InventoryMenuOverlay")

func _on_credits() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	get_tree().change_scene_to_file("res://scenes/credits.tscn")

func _on_exit_game() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	get_tree().quit()

func _on_campaign() -> void:
	_open_menu_overlay(CampaignGalleryScene.instantiate(), "CampaignGalleryOverlay")

func _on_daily_dungeon() -> void:
	if get_node_or_null("DailyDungeonMapOverlay") != null:
		return
	DailyDungeonManager.begin_daily_session()
	_open_menu_overlay(DailyDungeonMapScene.instantiate(), "DailyDungeonMapOverlay")

func _on_settings() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	_open_menu_overlay(SettingsMenuScene.instantiate(), "SettingsMenuOverlay")

func _open_admin_console() -> void:
	if get_node_or_null("AdminConsoleOverlay") != null:
		# Toggle: close if already open
		get_node("AdminConsoleOverlay").queue_free()
		return
	var overlay := AdminConsoleScene.instantiate()
	overlay.name = "AdminConsoleOverlay"
	add_child(overlay)

func _apply_menu_btn_style(btn: Button, bordered: bool = true) -> void:
	var bw: int = 4 if bordered else 0

	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = Color(0.047, 0.094, 0.157, 1)
	sb_n.border_width_left = bw; sb_n.border_width_top = bw
	sb_n.border_width_right = bw; sb_n.border_width_bottom = bw
	sb_n.border_color = Color(0.494, 0.839, 1.0, 1.0) if bordered else sb_n.bg_color
	sb_n.corner_radius_top_left = 12; sb_n.corner_radius_top_right = 12
	sb_n.corner_radius_bottom_right = 12; sb_n.corner_radius_bottom_left = 12
	sb_n.shadow_color = Color(0.494, 0.839, 1.0, 0.25) if bordered else Color(0, 0, 0, 0)
	sb_n.shadow_offset = Vector2(0.0, 2.0)
	sb_n.shadow_size = 6 if bordered else 0
	sb_n.anti_aliasing = bordered

	var sb_h := StyleBoxFlat.new()
	sb_h.bg_color = Color(0.118, 0.184, 0.271, 1)
	sb_h.border_width_left = bw; sb_h.border_width_top = bw
	sb_h.border_width_right = bw; sb_h.border_width_bottom = bw
	sb_h.border_color = Color(0.608, 0.902, 1.0, 1.0) if bordered else sb_h.bg_color
	sb_h.corner_radius_top_left = 12; sb_h.corner_radius_top_right = 12
	sb_h.corner_radius_bottom_right = 12; sb_h.corner_radius_bottom_left = 12
	sb_h.shadow_color = Color(0.608, 0.902, 1.0, 0.5) if bordered else Color(0, 0, 0, 0)
	sb_h.shadow_size = 12 if bordered else 0
	sb_h.anti_aliasing = bordered

	var sb_p := StyleBoxFlat.new()
	sb_p.bg_color = Color(0.039, 0.075, 0.133, 1)
	sb_p.border_width_left = bw; sb_p.border_width_top = bw
	sb_p.border_width_right = bw; sb_p.border_width_bottom = bw
	sb_p.border_color = Color(0.494, 0.839, 1.0, 1.0) if bordered else sb_p.bg_color
	sb_p.corner_radius_top_left = 12; sb_p.corner_radius_top_right = 12
	sb_p.corner_radius_bottom_right = 12; sb_p.corner_radius_bottom_left = 12
	sb_p.shadow_color = Color(0.494, 0.839, 1.0, 0.15) if bordered else Color(0, 0, 0, 0)
	sb_p.shadow_offset = Vector2(0.0, 1.0)
	sb_p.shadow_size = 3 if bordered else 0
	sb_p.anti_aliasing = bordered

	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover",  sb_h)
	btn.add_theme_stylebox_override("pressed", sb_p)
	btn.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color(0.910, 0.957, 1.0, 1.0))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Ctrl + Shift + A  →  Admin Console
		if event.keycode == KEY_A and event.ctrl_pressed and event.shift_pressed:
			_open_admin_console()
			get_viewport().set_input_as_handled()
