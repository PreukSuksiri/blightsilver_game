extends Control

const DeckData = preload("res://resources/DeckData.gd")
const CHIVO_FONT := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")
const InventoryMenuScene = preload("res://scenes/inventory_menu.tscn")
const AdminConsoleScene = preload("res://scenes/admin_console.tscn")
const ShopMenuScene     = preload("res://scenes/shop_menu.tscn")
const CardGalleryScene  = preload("res://scenes/card_gallery.tscn")
const DeckBuilderScene  = preload("res://scenes/deck_builder.tscn")
const SettingsMenuScene  = preload("res://scenes/settings_menu.tscn")
const CampaignMapScene   = preload("res://scenes/campaign_map.tscn")

@onready var local_2p_btn:      Button = $NewGameBtn
@onready var deck_build_btn:    Button = $DeckBuilderBtn
@onready var shop_btn:          Button = $ShopBtn
@onready var gallery_btn:       Button = $GalleryBtn
@onready var mailbox_btn:       Button = $MailboxBtn
@onready var credits_btn:       Button = $CreditsBtn
@onready var campaign_btn:      Button = $SettingsBtn
@onready var version_label:     Label  = $VersionLabel
@onready var bgm:               AudioStreamPlayer = $BGM
@onready var fade_overlay:      ColorRect         = $FadeOverlay
@onready var deck_status_label: Label  = $DeckStatusBg/DeckStatusLabel
@onready var settings_icon_btn: Button = $SettingsIconBtn
@onready var exit_icon_btn:     Button = $ExitIconBtn

func _ready() -> void:
	local_2p_btn.pressed.connect(_on_local_2p)
	deck_build_btn.pressed.connect(_on_deck_builder)
	shop_btn.pressed.connect(_on_shop)
	gallery_btn.pressed.connect(_on_gallery)
	mailbox_btn.pressed.connect(_on_inventory)
	credits_btn.pressed.connect(_on_credits)
	campaign_btn.pressed.connect(_on_campaign)
	settings_icon_btn.pressed.connect(_on_settings)
	exit_icon_btn.pressed.connect(func() -> void: get_tree().quit())
	version_label.text = "v0.1 Prototype"
	(bgm.stream as AudioStreamMP3).loop = true
	bgm.play()
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_refresh_deck_status()
	_refresh_inventory_badge()
	MailboxManager.mailbox_changed.connect(_refresh_inventory_badge)

func _refresh_deck_status() -> void:
	var deck: DeckData = SaveManager.get_active_deck()
	if deck == null:
		deck_status_label.text = "No deck saved."
		local_2p_btn.disabled = true
		return
	deck_status_label.text = 'Active deck: "%s"  (%d chars / %d traps / %d tech / %d blanks)' % [
		deck.deck_name,
		deck.characters.size(),
		deck.traps.size(),
		deck.techs.size(),
		deck.blank_count()
	]
	var valid: bool = deck.is_valid()
	local_2p_btn.disabled = not valid
	deck_status_label.add_theme_color_override("font_color",
		Color(0.4, 0.9, 1.0) if valid else Color(1.0, 0.5, 0.3))

func _refresh_inventory_badge() -> void:
	var count := MailboxManager.get_unclaimed_count()
	if count > 0:
		mailbox_btn.text = "INVENTORY  [%d]" % count
		mailbox_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.65, 1.0))
	else:
		mailbox_btn.text = "INVENTORY"
		mailbox_btn.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3, 0.85))

func _on_local_2p() -> void:
	if get_node_or_null("ModeChoicePanel") != null:
		get_node("ModeChoicePanel").queue_free()
		return

	var picker := Panel.new()
	picker.name = "ModeChoicePanel"
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
	picker.add_theme_stylebox_override("panel", sb)
	picker.set_anchors_preset(Control.PRESET_TOP_LEFT)
	picker.position = Vector2(local_2p_btn.position.x, local_2p_btn.position.y + local_2p_btn.size.y + 4)
	picker.size = Vector2(local_2p_btn.size.x, 186)
	add_child(picker)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 6
	vbox.offset_top = 6
	vbox.offset_right = -6
	vbox.offset_bottom = -6
	vbox.add_theme_constant_override("separation", 6)
	picker.add_child(vbox)

	var _add_btn := func(label: String, cb: Callable) -> void:
		var btn := Button.new()
		btn.text = label
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_override("font", CHIVO_FONT)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(cb)
		vbox.add_child(btn)

	_add_btn.call("MATCHMAKING", func() -> void:
		picker.queue_free()
		bgm.stop()
		GameState.game_mode = GameState.GameMode.LOCAL_2P
		CheckerTransition.fade_out_to_battle(func() -> void:
			get_tree().change_scene_to_file("res://scenes/game_board.tscn")))

	_add_btn.call("PRIVATE", func() -> void:
		picker.queue_free()
		bgm.stop()
		GameState.game_mode = GameState.GameMode.LOCAL_2P
		CheckerTransition.fade_out_to_battle(func() -> void:
			get_tree().change_scene_to_file("res://scenes/game_board.tscn")))

	_add_btn.call("HOT SEAT", func() -> void:
		picker.queue_free()
		bgm.stop()
		GameState.game_mode = GameState.GameMode.HOT_SEAT
		CheckerTransition.fade_out_to_battle(func() -> void:
			get_tree().change_scene_to_file("res://scenes/game_board.tscn")))

func _on_deck_builder() -> void:
	if get_node_or_null("DeckBuilderOverlay") != null:
		return
	var overlay := DeckBuilderScene.instantiate()
	overlay.name = "DeckBuilderOverlay"
	overlay.closed.connect(_refresh_deck_status)
	add_child(overlay)

func _on_shop() -> void:
	if get_node_or_null("ShopMenuOverlay") != null:
		return
	var overlay := ShopMenuScene.instantiate()
	overlay.name = "ShopMenuOverlay"
	add_child(overlay)

func _on_gallery() -> void:
	if get_node_or_null("CardGalleryOverlay") != null:
		return
	var overlay := CardGalleryScene.instantiate()
	overlay.name = "CardGalleryOverlay"
	add_child(overlay)

func _on_inventory() -> void:
	if get_node_or_null("InventoryMenuOverlay") != null:
		return
	var overlay := InventoryMenuScene.instantiate()
	overlay.name = "InventoryMenuOverlay"
	overlay.closed.connect(func() -> void: pass)
	add_child(overlay)

func _on_credits() -> void:
	get_tree().change_scene_to_file("res://scenes/credits.tscn")

func _on_campaign() -> void:
	if get_node_or_null("CampaignMapOverlay") != null:
		return
	var overlay := CampaignMapScene.instantiate()
	overlay.name = "CampaignMapOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 10
	add_child(overlay)

func _on_settings() -> void:
	if get_node_or_null("SettingsMenuOverlay") != null:
		return
	var overlay := SettingsMenuScene.instantiate()
	overlay.name = "SettingsMenuOverlay"
	add_child(overlay)

func _open_admin_console() -> void:
	if get_node_or_null("AdminConsoleOverlay") != null:
		# Toggle: close if already open
		get_node("AdminConsoleOverlay").queue_free()
		return
	var overlay := AdminConsoleScene.instantiate()
	overlay.name = "AdminConsoleOverlay"
	add_child(overlay)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Ctrl + Shift + A  →  Admin Console
		if event.keycode == KEY_A and event.ctrl_pressed and event.shift_pressed:
			_open_admin_console()
			get_viewport().set_input_as_handled()
