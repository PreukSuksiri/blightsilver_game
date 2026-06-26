extends Control

const DeckData = preload("res://resources/DeckData.gd")
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
@onready var mailbox_icon_btn: Button = $MailboxIconBtn
@onready var mailbox_icon_shadow: Control = $MailboxIconShadow
@onready var mailbox_icon_badge: Panel = $MailboxIconBadge
@onready var mailbox_icon_badge_lbl: Label = $MailboxIconBadge/BadgeLabel
@onready var exit_icon_btn:     Button = $ExitIconBtn
@onready var exit_icon_shadow:  Control = $ExitIconShadow
@onready var deck_status_bg:    Panel  = $DeckStatusBg

const MENU_BTN_Z := 1
const TITLE_CHEAT_Z := -10
const MENU_OVERLAY_Z := 25
const MENU_LOADING_Z := 35
const MENU_DROPDOWN_BACKDROP_Z := 40
const MENU_DROPDOWN_Z := 41
const MENU_STACK_GAP := 14.0

const TITLE_BG_TEX_SIZE := Vector2(1216.0, 832.0)
const TITLE_CHEAT_TAPS_REQUIRED := 20
const TITLE_CHEAT_APARTMENT_CREDITS := 10000
const TITLE_CHEAT_MOON_CREDITS := 2500
const CREDIT_DEMO_SCENE := "res://scenes/credit_demo.tscn"
# Normalized hit rects on bg_title_1.png — see requirement/Screenshot 2569-06-12 at 12.23.11.png
const TITLE_CHEAT_APARTMENT_NORM := Rect2(0.020, 0.520, 0.095, 0.135)
const TITLE_CHEAT_MOON_NORM := Rect2(0.300, 0.020, 0.400, 0.480)
const TITLE_CHEAT_CREDIT_DEMO_NORM := Rect2(0.885, 0.020, 0.095, 0.135)

var _overlay_obscure_depth: int = 0
var _title_cheat_apartment_taps: int = 0
var _title_cheat_moon_taps: int = 0
var _title_cheat_credit_demo_taps: int = 0
var _title_cheat_apartment_zone: Control = null
var _title_cheat_moon_zone: Control = null
var _title_cheat_credit_demo_zone: Control = null

func _ready() -> void:
	if OS.has_feature("web"):
		gui_input.connect(_on_web_audio_gate)
	local_2p_btn.pressed.connect(_on_stack_primary_pressed)
	deck_build_btn.pressed.connect(_on_deck_builder)
	shop_btn.pressed.connect(_on_shop)
	gallery_btn.pressed.connect(_on_gallery)
	mailbox_btn.pressed.connect(_on_inventory)
	credits_btn.pressed.connect(_on_credits)
	exit_game_btn.pressed.connect(_on_exit_game)
	campaign_btn.pressed.connect(_on_stack_secondary_pressed)
	settings_icon_btn.pressed.connect(_on_settings)
	settings_icon_btn.tooltip_text = "Settings"
	mailbox_icon_btn.pressed.connect(_on_mailbox_icon_pressed)
	mailbox_icon_btn.tooltip_text = "Inventory / Mailbox"
	exit_icon_btn.pressed.connect(func() -> void:
		SFXManager.play(SFXManager.SFX_BTN)
		get_tree().quit())
	exit_icon_btn.tooltip_text = "Exit Game"
	version_label.text = "v0.1 Prototype"
	if has_node("BGM"):
		$BGM.stop()
	BGMManager.play_context(BGMManager.CONTEXT_MAIN_MENU, 0.0, 0.0)
	if deck_status_bg != null:
		deck_status_bg.visible = false
	var tween := create_tween()	
	tween.tween_property(fade_overlay, "color:a", 0.0, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_setup_mailbox_icon_badge()
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
	elif GameState.open_campaign_gallery_on_menu:
		GameState.open_campaign_gallery_on_menu = false
		call_deferred("_on_campaign")
	_apply_menu_fonts()
	if not FontManager.fonts_changed.is_connected(_on_fonts_changed):
		FontManager.fonts_changed.connect(_on_fonts_changed)
	_reset_title_cheat_tap_counts()
	_setup_title_cheat_hitboxes()
	if has_node("TitleLogo"):
		$TitleLogo.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_web_audio_gate(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		AudioManager.ensure_web_audio_from_ui()
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		AudioManager.ensure_web_audio_from_ui()


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
	FontManager.tag_font(lbl, "font", "primary", 400)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.35, 1.0))
	vbox.add_child(lbl)

	var ok_btn := Button.new()
	ok_btn.text = "OK"
	FontManager.tag_font(ok_btn, "font", "primary", 400)
	ok_btn.add_theme_font_size_override("font_size", 17)
	_apply_menu_btn_style(ok_btn, false)
	ok_btn.pressed.connect(func() -> void: panel.queue_free())
	vbox.add_child(ok_btn)

func _refresh_inventory_badge() -> void:
	var count := MailboxManager.get_unclaimed_count()
	var label := MenuButtonConfig.get_label("inventory").to_upper()
	mailbox_btn.text = label
	mailbox_btn.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.65, 1.0) if count > 0 else Color(0.95, 0.8, 0.3, 0.85))
	_refresh_mailbox_icon_badge()


func _setup_mailbox_icon_badge() -> void:
	if mailbox_icon_badge == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.92, 0.18, 0.22, 1.0)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.set_content_margin_all(0)
	mailbox_icon_badge.add_theme_stylebox_override("panel", sb)
	if mailbox_icon_badge_lbl != null:
		mailbox_icon_badge_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		FontManager.tag_font(mailbox_icon_badge_lbl, "font", "primary", 700)


func _refresh_mailbox_icon_badge() -> void:
	if mailbox_icon_badge == null or mailbox_icon_badge_lbl == null:
		return
	var count := MailboxManager.get_unclaimed_count()
	var show_icon: bool = mailbox_icon_btn != null and mailbox_icon_btn.visible
	mailbox_icon_badge.visible = show_icon and count > 0
	if count > 0:
		mailbox_icon_badge_lbl.text = "9+" if count > 9 else str(count)

func _stack_button_for_key(key: String) -> Button:
	match key:
		"quick_duel": return local_2p_btn
		"campaign": return campaign_btn
		"single_player": return local_2p_btn
		"multiplayer": return campaign_btn
		"deck_builder": return deck_build_btn
		"inventory": return mailbox_btn
		"shop": return shop_btn
		"gallery": return gallery_btn
		"credits": return credits_btn
		"exit": return exit_game_btn
	return null


func _stack_menu_keys() -> Array[String]:
	var keys: Array[String] = []
	for key: Variant in MenuButtonConfig.get_main_keys():
		var k: String = str(key)
		if MenuButtonConfig.uses_stack_slot(k) and MenuButtonConfig.is_main_visible(k):
			keys.append(k)
	keys.sort_custom(func(a: String, b: String) -> bool:
		return MenuButtonConfig.get_sort_slot(a) < MenuButtonConfig.get_sort_slot(b))
	return keys


func _key_for_stack_button(btn: Button) -> String:
	for key: String in _stack_menu_keys():
		if _stack_button_for_key(key) == btn:
			return key
	return ""


func _apply_menu_button_state() -> void:
	var btn_keys: Dictionary = {}
	for key: String in _stack_menu_keys():
		var btn: Button = _stack_button_for_key(key)
		if btn != null:
			btn_keys[btn] = key
	for btn: Button in [local_2p_btn, campaign_btn, deck_build_btn, mailbox_btn,
			shop_btn, gallery_btn, credits_btn, exit_game_btn]:
		if btn_keys.has(btn):
			_set_main_menu_btn(btn, btn_keys[btn])
		elif btn != credits_btn and btn != exit_game_btn:
			btn.visible = false
	_set_main_menu_btn(credits_btn, "credits")
	_set_main_menu_btn(exit_game_btn, "exit")
	_sync_corner_icon(settings_icon_btn, settings_icon_shadow, "settings")
	_sync_corner_icon(mailbox_icon_btn, mailbox_icon_shadow, "inventory")
	_sync_corner_icon(exit_icon_btn, exit_icon_shadow, "exit_icon")
	_apply_menu_button_labels()
	_apply_menu_button_positions()
	_refresh_mailbox_icon_badge()


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
	var btn_keys: Dictionary = {}
	for key: String in _stack_menu_keys():
		var btn: Button = _stack_button_for_key(key)
		if btn != null:
			btn_keys[btn] = key
	for btn: Button in btn_keys.keys():
		btn.text = MenuButtonConfig.get_label(str(btn_keys[btn])).to_upper()
	if credits_btn.visible:
		credits_btn.text = MenuButtonConfig.get_label("credits").to_upper()
	if exit_game_btn.visible:
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
	for key: String in _stack_menu_keys():
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
		_set_title_cheat_zones_active(false)


func _pop_main_menu_obscured() -> void:
	_overlay_obscure_depth = maxi(0, _overlay_obscure_depth - 1)
	if _overlay_obscure_depth == 0:
		_set_main_menu_obscured(false)
		_apply_menu_button_state()
		_set_title_cheat_zones_active(true)


func _set_main_menu_obscured(obscured: bool) -> void:
	for key: String in _stack_menu_keys() + ["credits", "exit"]:
		var btn: Button = _stack_button_for_key(key)
		if btn == null:
			continue
		btn.visible = false if obscured else MenuButtonConfig.is_main_visible(key)
	_sync_corner_icon(settings_icon_btn, settings_icon_shadow, "settings", obscured)
	_sync_corner_icon(mailbox_icon_btn, mailbox_icon_shadow, "inventory", obscured)
	_sync_corner_icon(exit_icon_btn, exit_icon_shadow, "exit_icon", obscured)
	_refresh_mailbox_icon_badge()


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
		FontManager.tag_font(btn, "font", "primary", 400)
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
			get_tree().change_scene_to_file("res://scenes/vs_ai_config.tscn"), MenuButtonConfig.is_sub_enabled("single_player", "vs_ai"))

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
		FontManager.tag_font(btn, "font", "primary", 400)
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
	if get_node_or_null("DeckBuilderOverlay") != null:
		return
	var loading := MenuLoadingOverlay.new()
	loading.name = "DeckBuilderLoadingOverlay"
	loading.z_index = MENU_LOADING_Z
	loading.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(loading)
	loading.move_to_front()
	await get_tree().process_frame
	await get_tree().process_frame
	var deck_builder: Control = DeckBuilderScene.instantiate()
	var dismiss_loading := func() -> void:
		if is_instance_valid(loading):
			loading.queue_free()
	if deck_builder.has_signal("initial_gallery_load_finished"):
		deck_builder.initial_gallery_load_finished.connect(dismiss_loading, CONNECT_ONE_SHOT)
	deck_builder.tree_exiting.connect(dismiss_loading, CONNECT_ONE_SHOT)
	_open_menu_overlay(deck_builder, "DeckBuilderOverlay", _refresh_deck_status)
	if is_instance_valid(loading):
		loading.move_to_front()

func _on_shop() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	_open_menu_overlay(ShopMenuScene.instantiate(), "ShopMenuOverlay")

func _on_gallery() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	_open_menu_overlay(CardGalleryScene.instantiate(), "CardGalleryOverlay")

func _on_inventory() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	_open_menu_overlay(InventoryMenuScene.instantiate(), "InventoryMenuOverlay")


func _on_mailbox_icon_pressed() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	var overlay: Control = _open_menu_overlay(
		InventoryMenuScene.instantiate(), "InventoryMenuOverlay")
	if overlay != null:
		overlay.call_deferred("show_mailbox_tab")

func _on_credits() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	get_tree().change_scene_to_file("res://scenes/credits.tscn")

func _apply_menu_fonts() -> void:
	var btns: Array[Button] = [
		local_2p_btn, deck_build_btn, shop_btn, gallery_btn, mailbox_btn,
		credits_btn, exit_game_btn, campaign_btn,
		settings_icon_btn, mailbox_icon_btn, exit_icon_btn,
	]
	for btn: Button in btns:
		if btn != null:
			FontManager.tag_font(btn, "font", "primary", 400)
	if version_label != null:
		FontManager.tag_font(version_label, "font", "primary", 400)
	if deck_status_label != null:
		FontManager.tag_font(deck_status_label, "font", "primary", 400)


func _on_fonts_changed() -> void:
	_apply_menu_fonts()
	FontManager.refresh_tree(self)


func _on_exit_game() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	get_tree().quit()

func _on_stack_primary_pressed() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	match _key_for_stack_button(local_2p_btn):
		"quick_duel":
			_on_quick_duel()
		"single_player":
			_on_single_player()
		"campaign":
			_on_campaign()
		_:
			_on_campaign()


func _on_stack_secondary_pressed() -> void:
	SFXManager.play(SFXManager.SFX_BTN)
	match _key_for_stack_button(campaign_btn):
		"campaign":
			_on_campaign()
		"multiplayer":
			_on_multiplayer()
		_:
			_on_multiplayer()


func _on_quick_duel() -> void:
	get_tree().change_scene_to_file("res://scenes/quick_duel.tscn")


func _on_local_play_pressed() -> void:
	_on_stack_primary_pressed()


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
	BuildConfig.toggle_admin_console_on(self)

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
	if BuildConfig.admin_shortcut_pressed(event):
		_open_admin_console()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_title_cheat_hitboxes()


func _reset_title_cheat_tap_counts() -> void:
	_title_cheat_apartment_taps = 0
	_title_cheat_moon_taps = 0
	_title_cheat_credit_demo_taps = 0


func refresh_title_cheats_from_save() -> void:
	_reset_title_cheat_tap_counts()
	_refresh_title_cheat_zone_visibility()


func _setup_title_cheat_hitboxes() -> void:
	if get_node_or_null("TitleCheatHitZones") != null:
		return
	var layer := Control.new()
	layer.name = "TitleCheatHitZones"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = TITLE_CHEAT_Z
	add_child(layer)
	move_child(layer, get_node("Background").get_index() + 1)

	_title_cheat_apartment_zone = _make_title_cheat_zone(
		"ApartmentCheatZone", _on_title_cheat_apartment_tapped)
	_title_cheat_moon_zone = _make_title_cheat_zone(
		"MoonCheatZone", _on_title_cheat_moon_tapped)
	_title_cheat_credit_demo_zone = _make_title_cheat_zone(
		"CreditDemoCheatZone", _on_title_cheat_credit_demo_tapped)
	layer.add_child(_title_cheat_apartment_zone)
	layer.add_child(_title_cheat_moon_zone)
	layer.add_child(_title_cheat_credit_demo_zone)
	_refresh_title_cheat_zone_visibility()
	_layout_title_cheat_hitboxes()


func _make_title_cheat_zone(zone_name: String, on_tap: Callable) -> Control:
	var zone := Control.new()
	zone.name = zone_name
	zone.mouse_filter = Control.MOUSE_FILTER_STOP
	zone.gui_input.connect(func(ev: InputEvent) -> void:
		if not _title_cheat_zone_pressed(ev):
			return
		on_tap.call())
	return zone


func _title_cheat_zone_pressed(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		return mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false


func _title_cheat_norm_to_screen_rect(norm: Rect2) -> Rect2:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var scale: float = maxf(vp_size.x / TITLE_BG_TEX_SIZE.x, vp_size.y / TITLE_BG_TEX_SIZE.y)
	var drawn_size: Vector2 = TITLE_BG_TEX_SIZE * scale
	var offset: Vector2 = (vp_size - drawn_size) * 0.5
	return Rect2(
		offset + Vector2(norm.position.x, norm.position.y) * drawn_size,
		Vector2(norm.size.x, norm.size.y) * drawn_size)


func _layout_title_cheat_hitboxes() -> void:
	if _title_cheat_apartment_zone == null or _title_cheat_moon_zone == null \
			or _title_cheat_credit_demo_zone == null:
		return
	_apply_title_cheat_zone_rect(_title_cheat_apartment_zone, TITLE_CHEAT_APARTMENT_NORM)
	_apply_title_cheat_zone_rect(_title_cheat_moon_zone, TITLE_CHEAT_MOON_NORM)
	_apply_title_cheat_zone_rect(_title_cheat_credit_demo_zone, TITLE_CHEAT_CREDIT_DEMO_NORM)


func _apply_title_cheat_zone_rect(zone: Control, norm: Rect2) -> void:
	var rect: Rect2 = _title_cheat_norm_to_screen_rect(norm)
	zone.set_anchors_preset(Control.PRESET_TOP_LEFT)
	zone.position = rect.position
	zone.size = rect.size


func _refresh_title_cheat_zone_visibility() -> void:
	if _title_cheat_apartment_zone != null:
		_title_cheat_apartment_zone.visible = not SaveManager.title_cheat_apartment_claimed
	if _title_cheat_moon_zone != null:
		_title_cheat_moon_zone.visible = not SaveManager.title_cheat_moon_claimed


func _set_title_cheat_zones_active(active: bool) -> void:
	var layer: Node = get_node_or_null("TitleCheatHitZones")
	if layer != null:
		layer.visible = active


func _on_title_cheat_apartment_tapped() -> void:
	if SaveManager.title_cheat_apartment_claimed:
		return
	_title_cheat_apartment_taps += 1
	if _title_cheat_apartment_taps >= TITLE_CHEAT_TAPS_REQUIRED:
		_grant_title_cheat_apartment()


func _on_title_cheat_moon_tapped() -> void:
	if SaveManager.title_cheat_moon_claimed:
		return
	_title_cheat_moon_taps += 1
	if _title_cheat_moon_taps >= TITLE_CHEAT_TAPS_REQUIRED:
		_grant_title_cheat_moon()


func _grant_title_cheat_apartment() -> void:
	if SaveManager.title_cheat_apartment_claimed:
		return
	SaveManager.title_cheat_apartment_claimed = true
	Collection.add_credits(TITLE_CHEAT_APARTMENT_CREDITS)
	CreditsEarnedOverlay.show_earned(get_tree().root, TITLE_CHEAT_APARTMENT_CREDITS)
	_refresh_title_cheat_zone_visibility()


func _grant_title_cheat_moon() -> void:
	if SaveManager.title_cheat_moon_claimed:
		return
	SaveManager.title_cheat_moon_claimed = true
	Collection.add_credits(TITLE_CHEAT_MOON_CREDITS)
	CreditsEarnedOverlay.show_earned(get_tree().root, TITLE_CHEAT_MOON_CREDITS)
	_refresh_title_cheat_zone_visibility()


func _on_title_cheat_credit_demo_tapped() -> void:
	_title_cheat_credit_demo_taps += 1
	if _title_cheat_credit_demo_taps >= TITLE_CHEAT_TAPS_REQUIRED:
		_launch_title_cheat_credit_demo()


func _launch_title_cheat_credit_demo() -> void:
	_title_cheat_credit_demo_taps = 0
	_set_title_cheat_zones_active(false)
	BGMManager.stop(0.0)
	get_tree().change_scene_to_file(CREDIT_DEMO_SCENE)
