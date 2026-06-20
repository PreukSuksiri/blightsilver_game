extends Control

signal closed()

var _tab_items_btn:   Button
var _tab_mail_btn:    Button
var _items_panel:     Control
var _mail_panel:      Control
var _mail_list:       VBoxContainer
var _unclaimed_lbl:   Label
var _claim_all_btn:   Button
var _claim_credits_btn: Button
var _delete_btn:      Button
var _credit_count_lbl: Label
var _scroll_count_lbl: Label
var _scroll_use_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP

	MailboxManager.mailbox_changed.connect(_refresh_mail)
	Collection.collection_changed.connect(_refresh_items)
	Collection.credits_changed.connect(_refresh_items)

	_build_ui()

# ─────────────────────────────────────────────────────────────
# UI construction
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Dimmer
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.80)
	dimmer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(dimmer)

	# Main panel (centred)
	var panel := PanelContainer.new()
	panel.layout_mode = 1
	panel.anchor_left = 0.5; panel.anchor_right  = 0.5
	panel.anchor_top  = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -360.0; panel.offset_right  =  360.0
	panel.offset_top  = -300.0; panel.offset_bottom =  300.0
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.025, 0.04, 0.09, 1.0)
	panel_sb.border_color = Color(0.35, 0.62, 1.0, 0.45)
	panel_sb.set_border_width_all(1)
	panel_sb.set_corner_radius_all(10)
	panel_sb.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", panel_sb)
	add_child(panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 0)
	panel.add_child(root_vbox)

	# ── Header ───────────────────────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 0)
	header.custom_minimum_size = Vector2(0, 48)
	root_vbox.add_child(header)

	var title := Label.new()
	title.text = "INVENTORY"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.82, 0.93, 1.0))
	title.add_theme_font_override("font", FontManager.make_font("primary", 400))
	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_left", 18)
	title_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_margin.add_child(title)
	header.add_child(title_margin)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(48, 48)
	close_btn.flat = true
	close_btn.add_theme_font_override("font", FontManager.make_font("primary", 400))
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	root_vbox.add_child(_make_separator())

	# ── Tab bar ──────────────────────────────────
	var tab_bar := HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 0)
	tab_bar.custom_minimum_size = Vector2(0, 40)
	root_vbox.add_child(tab_bar)

	_tab_items_btn = _make_tab_button("ITEMS")
	_tab_mail_btn  = _make_tab_button("MAILBOX")
	_tab_items_btn.pressed.connect(func() -> void: _switch_tab(true))
	_tab_mail_btn.pressed.connect(func()  -> void: _switch_tab(false))
	tab_bar.add_child(_tab_items_btn)
	tab_bar.add_child(_tab_mail_btn)

	root_vbox.add_child(_make_separator())

	# ── Content area ─────────────────────────────
	var content := Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size = Vector2(0, 440)
	root_vbox.add_child(content)

	_items_panel = _build_items_panel()
	_items_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(_items_panel)

	_mail_panel = _build_mail_panel()
	_mail_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(_mail_panel)

	_switch_tab(true)


func show_mailbox_tab() -> void:
	_switch_tab(false)
	_refresh_mail()

func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	var sep_sb := StyleBoxFlat.new()
	sep_sb.bg_color = Color(0.25, 0.38, 0.55, 0.3)
	sep_sb.set_content_margin_all(0)
	sep.add_theme_stylebox_override("separator", sep_sb)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep

func _make_tab_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 40)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_font_override("font", FontManager.make_font("primary", 400))
	return btn

func _set_tab_active(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))
	else:
		btn.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))

func _switch_tab(items_active: bool) -> void:
	_items_panel.visible = items_active
	_mail_panel.visible  = not items_active
	_set_tab_active(_tab_items_btn, items_active)
	_set_tab_active(_tab_mail_btn,  not items_active)

# ─────────────────────────────────────────────────────────────
# Items panel
# ─────────────────────────────────────────────────────────────
func _build_items_panel() -> Control:
	var root := MarginContainer.new()
	root.add_theme_constant_override("margin_left",   18)
	root.add_theme_constant_override("margin_right",  18)
	root.add_theme_constant_override("margin_top",    18)
	root.add_theme_constant_override("margin_bottom", 18)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	root.add_child(vbox)

	var section_lbl := Label.new()
	section_lbl.text = "Your Items"
	section_lbl.add_theme_font_size_override("font_size", 14)
	section_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75, 0.8))
	section_lbl.add_theme_font_override("font", FontManager.make_font("primary", 400))
	vbox.add_child(section_lbl)

	# Credits row
	var credit_row := PanelContainer.new()
	credit_row.custom_minimum_size = Vector2(0, 68)
	var credit_sb := StyleBoxFlat.new()
	credit_sb.bg_color = Color(0.06, 0.05, 0.02, 1.0)
	credit_sb.border_color = Color(1.0, 0.8, 0.2, 0.45)
	credit_sb.set_border_width_all(1)
	credit_sb.set_corner_radius_all(6)
	credit_sb.content_margin_left = 14; credit_sb.content_margin_right = 14
	credit_sb.content_margin_top  = 10; credit_sb.content_margin_bottom = 10
	credit_row.add_theme_stylebox_override("panel", credit_sb)
	vbox.add_child(credit_row)

	var credit_hbox := HBoxContainer.new()
	credit_hbox.add_theme_constant_override("separation", 12)
	credit_row.add_child(credit_hbox)

	var credit_icon := TextureRect.new()
	credit_icon.texture = load("res://assets/textures/ui/decorations/ui_icon_credit.png") as Texture2D
	credit_icon.custom_minimum_size = Vector2(36, 36)
	credit_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	credit_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	credit_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	credit_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	credit_hbox.add_child(credit_icon)

	var credit_text_vbox := VBoxContainer.new()
	credit_text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credit_text_vbox.add_theme_constant_override("separation", 2)
	credit_hbox.add_child(credit_text_vbox)

	var credit_name := Label.new()
	credit_name.text = "Credits"
	credit_name.add_theme_font_size_override("font_size", 15)
	credit_name.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	credit_name.add_theme_font_override("font", FontManager.make_font("primary", 400))
	credit_text_vbox.add_child(credit_name)

	var credit_desc := Label.new()
	credit_desc.text = "Currency used to purchase card packs in the Shop"
	credit_desc.add_theme_font_size_override("font_size", 11)
	credit_desc.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7, 0.8))
	credit_text_vbox.add_child(credit_desc)

	_credit_count_lbl = Label.new()
	_credit_count_lbl.add_theme_font_size_override("font_size", 20)
	_credit_count_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_credit_count_lbl.add_theme_font_override("font", FontManager.make_font("primary", 700))
	_credit_count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	credit_hbox.add_child(_credit_count_lbl)

	# Union Scroll row
	var scroll_row := PanelContainer.new()
	scroll_row.custom_minimum_size = Vector2(0, 68)
	var scroll_sb := StyleBoxFlat.new()
	scroll_sb.bg_color = Color(0.04, 0.05, 0.10, 1.0)
	scroll_sb.border_color = Color(0.85, 0.88, 1.0, 0.45)
	scroll_sb.set_border_width_all(1)
	scroll_sb.set_corner_radius_all(6)
	scroll_sb.content_margin_left = 14; scroll_sb.content_margin_right = 14
	scroll_sb.content_margin_top  = 10; scroll_sb.content_margin_bottom = 10
	scroll_row.add_theme_stylebox_override("panel", scroll_sb)
	vbox.add_child(scroll_row)

	var scroll_hbox := HBoxContainer.new()
	scroll_hbox.add_theme_constant_override("separation", 12)
	scroll_row.add_child(scroll_hbox)

	var scroll_icon := TextureRect.new()
	scroll_icon.texture = load(UnionScrollManager.SCROLL_IMAGE) as Texture2D
	scroll_icon.custom_minimum_size = Vector2(36, 36)
	scroll_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scroll_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	scroll_hbox.add_child(scroll_icon)

	var scroll_text_vbox := VBoxContainer.new()
	scroll_text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_text_vbox.add_theme_constant_override("separation", 2)
	scroll_hbox.add_child(scroll_text_vbox)

	var scroll_name := Label.new()
	scroll_name.text = "Union Scroll"
	scroll_name.add_theme_font_size_override("font_size", 15)
	scroll_name.add_theme_color_override("font_color", Color(0.88, 0.90, 1.0))
	scroll_name.add_theme_font_override("font", FontManager.make_font("primary", 400))
	scroll_text_vbox.add_child(scroll_name)

	var scroll_desc := Label.new()
	scroll_desc.text = "Reveals one undiscovered Union card from the demo pool"
	scroll_desc.add_theme_font_size_override("font_size", 11)
	scroll_desc.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7, 0.8))
	scroll_text_vbox.add_child(scroll_desc)

	_scroll_use_btn = Button.new()
	_scroll_use_btn.text = "Use"
	_scroll_use_btn.add_theme_font_size_override("font_size", 13)
	_scroll_use_btn.pressed.connect(_on_use_union_scroll)
	scroll_hbox.add_child(_scroll_use_btn)

	_scroll_count_lbl = Label.new()
	_scroll_count_lbl.add_theme_font_size_override("font_size", 20)
	_scroll_count_lbl.add_theme_color_override("font_color", Color(0.88, 0.90, 1.0))
	_scroll_count_lbl.add_theme_font_override("font", FontManager.make_font("primary", 700))
	_scroll_count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scroll_hbox.add_child(_scroll_count_lbl)

	_refresh_items()
	return root

func _refresh_items() -> void:
	if _credit_count_lbl != null:
		_credit_count_lbl.text = "%d" % Collection.credits
	if _scroll_count_lbl != null:
		_scroll_count_lbl.text = "×%d" % Collection.union_scrolls
	if _scroll_use_btn != null:
		_scroll_use_btn.disabled = Collection.union_scrolls <= 0

func _on_use_union_scroll() -> void:
	var res: Dictionary = UnionScrollManager.use_scroll(get_tree().root, true)
	if not res["success"]:
		var dlg := GameDialog.accept(
			get_tree().root,
			"Union Scroll",
			str(res.get("error", "Could not use Union Scroll.")))
		dlg.confirmed.connect(dlg.queue_free)
		dlg.popup_centered()
	_refresh_items()

# ─────────────────────────────────────────────────────────────
# Mail panel
# ─────────────────────────────────────────────────────────────
func _build_mail_panel() -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)

	# Sub-header
	var mail_header := HBoxContainer.new()
	mail_header.custom_minimum_size = Vector2(0, 36)
	mail_header.add_theme_constant_override("separation", 8)
	var mh_margin := MarginContainer.new()
	mh_margin.add_theme_constant_override("margin_left",  12)
	mh_margin.add_theme_constant_override("margin_right", 12)
	mh_margin.add_theme_constant_override("margin_top",    4)
	mh_margin.add_theme_constant_override("margin_bottom", 4)
	mh_margin.add_child(mail_header)
	root.add_child(mh_margin)

	_unclaimed_lbl = Label.new()
	_unclaimed_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_unclaimed_lbl.add_theme_font_size_override("font_size", 12)
	_unclaimed_lbl.add_theme_font_override("font", FontManager.make_font("primary", 400))
	_unclaimed_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mail_header.add_child(_unclaimed_lbl)

	_claim_all_btn = Button.new()
	_claim_all_btn.text = "Claim All"
	_claim_all_btn.add_theme_font_size_override("font_size", 12)
	_claim_all_btn.pressed.connect(_on_claim_all)
	_claim_all_btn.visible = false
	mail_header.add_child(_claim_all_btn)

	_claim_credits_btn = Button.new()
	_claim_credits_btn.text = "Claim Credits"
	_claim_credits_btn.add_theme_font_size_override("font_size", 12)
	_claim_credits_btn.pressed.connect(_on_claim_all_credits)
	mail_header.add_child(_claim_credits_btn)

	_delete_btn = Button.new()
	_delete_btn.text = "Delete Claimed"
	_delete_btn.add_theme_font_size_override("font_size", 12)
	_delete_btn.pressed.connect(func() -> void: MailboxManager.delete_claimed())
	mail_header.add_child(_delete_btn)

	root.add_child(_make_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_mail_list = VBoxContainer.new()
	_mail_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mail_list.add_theme_constant_override("separation", 4)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_bottom",  8)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_mail_list)
	scroll.add_child(margin)

	_refresh_mail()
	return root

func _refresh_mail() -> void:
	if _mail_list == null:
		return
	for child in _mail_list.get_children():
		child.queue_free()

	var items: Array = MailboxManager.mail_items
	var credit_summary: Dictionary = MailboxManager.get_unclaimed_credit_summary()
	var credit_unclaimed: int = int(credit_summary.get("count", 0))
	if items.is_empty() and credit_unclaimed == 0:
		var lbl := Label.new()
		lbl.text = "Your mailbox is empty."
		lbl.add_theme_color_override("font_color", Color(0.4, 0.55, 0.65, 0.7))
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(0, 80)
		_mail_list.add_child(lbl)
	else:
		if credit_unclaimed > 0:
			_mail_list.add_child(_make_credit_bundle_row(credit_summary))
		var sorted: Array = items.duplicate()
		sorted.reverse()
		for item: Dictionary in sorted:
			var reward: Dictionary = item.get("reward", {})
			if not item.get("claimed", false) and MailboxManager.is_credit_reward(reward):
				continue
			_mail_list.add_child(_make_mail_row(item))

	var unclaimed := MailboxManager.get_unclaimed_count()
	_unclaimed_lbl.text = "%d unclaimed" % unclaimed if unclaimed > 0 else "All claimed"
	_unclaimed_lbl.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.7) if unclaimed > 0 else Color(0.4, 0.5, 0.55, 0.8))
	_claim_credits_btn.visible = credit_unclaimed > 0
	_claim_credits_btn.disabled = credit_unclaimed == 0
	_claim_credits_btn.text = "Claim Credits (+%d)" % int(credit_summary.get("total", 0)) if credit_unclaimed > 0 else "Claim Credits"
	_claim_all_btn.disabled = unclaimed == 0
	_delete_btn.disabled = (items.size() - unclaimed) == 0

func _make_credit_bundle_row(summary: Dictionary) -> Control:
	var count: int = int(summary.get("count", 0))
	var total: int = int(summary.get("total", 0))
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 72)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.015, 1.0)
	sb.border_width_left = 3
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(1.0, 0.82, 0.22, 0.75)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	row.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)

	var dot := Label.new()
	dot.text = "●"
	dot.add_theme_font_size_override("font_size", 14)
	dot.add_theme_color_override("font_color", Color(1.0, 0.82, 0.22))
	dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot.custom_minimum_size = Vector2(18, 0)
	hbox.add_child(dot)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var title := Label.new()
	title.text = "Credit rewards (%d)" % count
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	title.add_theme_font_override("font", FontManager.make_font("primary", 400))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "+%d credits total — claim all at once" % total
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.75, 0.65, 0.35, 0.85))
	vbox.add_child(sub)

	var btn := Button.new()
	btn.text = "Claim"
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	btn.pressed.connect(_on_claim_all_credits)
	hbox.add_child(btn)

	return row

func _make_mail_row(item: Dictionary) -> Control:
	var claimed: bool = item.get("claimed", false)
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 68)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.025, 0.055, 0.11, 1.0) if not claimed else Color(0.015, 0.025, 0.05, 0.75)
	sb.border_width_left = 3 if not claimed else 1
	sb.border_width_top = 1; sb.border_width_right = 1; sb.border_width_bottom = 1
	sb.border_color = Color(0.18, 0.75, 1.0, 0.75) if not claimed else Color(0.18, 0.28, 0.38, 0.3)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10; sb.content_margin_right = 10
	sb.content_margin_top = 8;   sb.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)

	var dot := Label.new()
	dot.text = "●" if not claimed else "○"
	dot.add_theme_font_size_override("font_size", 14)
	dot.add_theme_color_override("font_color",
		Color(0.2, 0.9, 1.0) if not claimed else Color(0.25, 0.35, 0.45, 0.6))
	dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot.custom_minimum_size = Vector2(18, 0)
	hbox.add_child(dot)

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

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(80, 34)
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

	return row

func _reward_label(r: Dictionary) -> String:
	match r.get("type", ""):
		"coins":            return ">> %d Crystals" % r.get("amount", 0)
		"card":             return ">> Card: %s" % r.get("card_name", "?")
		"booster_pack":     return ">> Booster Pack: %s" % r.get("pack_name", "?")
		"stage_bonus_card": return ">> Stage Bonus Card: %s" % r.get("card_name", "?")
		"music_disc":       return ">> Music Disc 💿 ×%d" % r.get("count", 1)
		"union_scroll":     return ">> Union Scroll ×%d" % r.get("count", 1)
		"credits":          return ">> Credits ×%d" % r.get("amount", 0)
	return ""

# ─────────────────────────────────────────────────────────────
# Actions
# ─────────────────────────────────────────────────────────────
func _on_claim(mail_id: String) -> void:
	var reward := MailboxManager.claim_mail(mail_id)
	_apply_reward(reward)

func _on_claim_all() -> void:
	pass  # Hidden — credit mail uses Claim Credits; packs stay per-mail.

func _on_claim_all_credits() -> void:
	var summary := MailboxManager.claim_all_credit_rewards()
	var total: int = int(summary.get("total", 0))
	if total <= 0:
		return
	Collection.add_credits(total)
	CreditsEarnedOverlay.show_earned(get_tree().root, total)
	_refresh_mail()

func _apply_reward(reward: Dictionary) -> void:
	if reward.is_empty():
		return
	match reward.get("type", ""):
		"coins", "credits":
			Collection.add_credits(reward.get("amount", 0))
		"card":
			var card_name: String = reward.get("card_name", "")
			if card_name != "":
				Collection.add_card(card_name, _detect_card_type(card_name), "Mailbox Reward")
				_open_pack_anim([card_name])
		"stage_bonus_card":
			var card_name: String = reward.get("card_name", "")
			if card_name != "":
				Collection.add_card(card_name, _detect_card_type(card_name), "Stage Bonus")
				_open_pack_anim([card_name])
		"booster_pack":
			var pack_nm: String = reward.get("pack_name", "")
			var drawn: Array = ShopManager.draw_pack_free(pack_nm)
			_open_pack_anim(drawn, pack_nm)
		"music_disc":
			Collection.add_music_disc(reward.get("count", 1))
		"union_scroll":
			Collection.add_union_scrolls(int(reward.get("count", 1)))
			_refresh_items()

func _open_pack_anim(cards: Array, pack_name: String = "") -> void:
	var overlay_script: GDScript = load("res://scripts/PackOpeningOverlay.gd")
	var get_name := func(i: int) -> String:
		if i >= cards.size():
			return ""
		var entry: Variant = cards[i]
		if entry is Dictionary:
			return (entry as Dictionary).get("name", "")
		return str(entry)
	var pack_img: String = ""
	if pack_name != "":
		var pack_dict: Dictionary = ShopManager.get_pack_by_name(pack_name)
		pack_img = str(pack_dict.get("pack_image", ""))
	overlay_script.open(get_tree().root, pack_img, get_name.call(0), get_name.call(1), get_name.call(2))

func _detect_card_type(card_name: String) -> String:
	if CardDatabase.get_character(card_name) != null: return "character"
	if CardDatabase.get_trap(card_name)      != null: return "trap"
	if CardDatabase.get_tech(card_name)      != null: return "tech"
	return "unknown"

func _on_close() -> void:
	emit_signal("closed")
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_close()
