extends Control

signal closed()

@onready var list_container: VBoxContainer = $Panel/VBox/ScrollContainer/ItemList
@onready var unclaimed_label: Label        = $Panel/VBox/Header/UnclaimedLabel
@onready var claim_all_btn: Button         = $Panel/VBox/Footer/ClaimAllBtn
@onready var delete_btn: Button            = $Panel/VBox/Footer/DeleteBtn

func _ready() -> void:
	MailboxManager.mailbox_changed.connect(_refresh)
	$Panel/VBox/Header/CloseBtn.pressed.connect(_on_close)
	claim_all_btn.pressed.connect(_on_claim_all)
	delete_btn.pressed.connect(_on_delete_claimed)
	_refresh()

# ─────────────────────────────────────────────────────────────
# List rendering
# ─────────────────────────────────────────────────────────────
func _refresh() -> void:
	for child in list_container.get_children():
		child.queue_free()

	var items: Array = MailboxManager.mail_items

	if items.is_empty():
		var lbl := Label.new()
		lbl.text = "Your mailbox is empty."
		lbl.add_theme_color_override("font_color", Color(0.4, 0.55, 0.65, 0.7))
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(0, 80)
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		list_container.add_child(lbl)
	else:
		# Show newest first
		var sorted: Array = items.duplicate()
		sorted.reverse()
		for item: Dictionary in sorted:
			_add_mail_row(item)

	var unclaimed := MailboxManager.get_unclaimed_count()
	unclaimed_label.text = "%d unclaimed" % unclaimed if unclaimed > 0 else "All claimed"
	unclaimed_label.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.7, 1.0) if unclaimed > 0 else Color(0.4, 0.5, 0.55, 0.8))

	claim_all_btn.disabled = unclaimed == 0
	delete_btn.disabled = (items.size() - unclaimed) == 0  # nothing claimed to delete

func _add_mail_row(item: Dictionary) -> void:
	var claimed: bool = item.get("claimed", false)

	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _row_style(claimed))
	row.custom_minimum_size = Vector2(0, 74)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)

	# Status dot
	var dot := Label.new()
	dot.text = "●" if not claimed else "○"
	dot.add_theme_font_size_override("font_size", 14)
	dot.add_theme_color_override("font_color",
		Color(0.2, 0.9, 1.0) if not claimed else Color(0.25, 0.35, 0.45, 0.6))
	dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot.custom_minimum_size = Vector2(18, 0)
	hbox.add_child(dot)

	# Text column
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)

	var header_lbl := Label.new()
	header_lbl.text = "[%s]  %s" % [item.get("sender", "?"), item.get("subject", "")]
	header_lbl.add_theme_font_size_override("font_size", 13)
	header_lbl.add_theme_color_override("font_color",
		Color(0.82, 0.93, 1.0) if not claimed else Color(0.38, 0.48, 0.58))
	header_lbl.clip_text = true
	vbox.add_child(header_lbl)

	var body_lbl := Label.new()
	body_lbl.text = item.get("body", "")
	body_lbl.add_theme_font_size_override("font_size", 11)
	body_lbl.add_theme_color_override("font_color", Color(0.52, 0.63, 0.73, 0.85))
	body_lbl.clip_text = true
	vbox.add_child(body_lbl)

	var reward: Dictionary = item.get("reward", {})
	if not reward.is_empty():
		var reward_lbl := Label.new()
		reward_lbl.text = _reward_label(reward)
		reward_lbl.add_theme_font_size_override("font_size", 11)
		reward_lbl.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.25, 0.9) if not claimed else Color(0.5, 0.45, 0.2, 0.5))
		vbox.add_child(reward_lbl)

	# Claim button
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(88, 34)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if claimed:
		btn.text = "Claimed"
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.3, 0.4, 0.45, 0.5))
	else:
		btn.text = "CLAIM"
		btn.add_theme_color_override("font_color", Color(0.25, 1.0, 0.65))
		var mail_id: String = item["id"]
		btn.pressed.connect(func() -> void: _on_claim(mail_id))
	hbox.add_child(btn)

	list_container.add_child(row)

func _reward_label(r: Dictionary) -> String:
	match r.get("type", ""):
		"coins":           return ">> %d Crystals" % r.get("amount", 0)
		"card":            return ">> Card: %s" % r.get("card_name", "?")
		"booster_pack":    return ">> Booster Pack: %s" % r.get("pack_name", "?")
		"stage_bonus_card":return ">> Stage Bonus Card: %s" % r.get("card_name", "?")
	return ""

func _row_style(claimed: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.025, 0.055, 0.11, 1.0) if not claimed \
		else Color(0.015, 0.025, 0.05, 0.75)
	sb.border_width_left   = 3 if not claimed else 1
	sb.border_width_top    = 1
	sb.border_width_right  = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.18, 0.75, 1.0, 0.75) if not claimed \
		else Color(0.18, 0.28, 0.38, 0.3)
	sb.corner_radius_top_left     = 4
	sb.corner_radius_top_right    = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left  = 4
	sb.content_margin_left   = 10
	sb.content_margin_right  = 10
	sb.content_margin_top    = 8
	sb.content_margin_bottom = 8
	return sb

# ─────────────────────────────────────────────────────────────
# Actions
# ─────────────────────────────────────────────────────────────
func _on_claim(mail_id: String) -> void:
	var reward := MailboxManager.claim_mail(mail_id)
	_apply_reward(reward)

func _on_claim_all() -> void:
	for reward: Dictionary in MailboxManager.claim_all():
		_apply_reward(reward)

func _apply_reward(reward: Dictionary) -> void:
	if reward.is_empty():
		return
	match reward.get("type", ""):
		"coins":
			Collection.add_credits(reward.get("amount", 0))
		"card":
			var card_name: String = reward.get("card_name", "")
			if card_name != "":
				Collection.add_card(card_name, _detect_card_type(card_name), "Mailbox Reward")
		"stage_bonus_card":
			var card_name: String = reward.get("card_name", "")
			if card_name != "":
				Collection.add_card(card_name, _detect_card_type(card_name), "Stage Bonus")
		"booster_pack":
			# Open the named pack for free (cards added to collection inside draw_pack_free)
			ShopManager.draw_pack_free(reward.get("pack_name", ""))

func _detect_card_type(card_name: String) -> String:
	if CardDatabase.get_character(card_name) != null:
		return "character"
	if CardDatabase.get_trap(card_name) != null:
		return "trap"
	if CardDatabase.get_tech(card_name) != null:
		return "tech"
	return "unknown"

func _on_delete_claimed() -> void:
	MailboxManager.delete_claimed()

func _on_close() -> void:
	emit_signal("closed")
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_close()
