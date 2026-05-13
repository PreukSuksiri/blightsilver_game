extends Control

signal closed()

@onready var credits_label: Label         = $Panel/VBox/Header/CreditsLabel
@onready var pack_row: HBoxContainer      = $Panel/VBox/PackScroll/PackRow
@onready var result_overlay: Control      = $ResultOverlay
@onready var result_title: Label          = $ResultOverlay/ResultPanel/VBox/TitleLabel
@onready var result_card_list: VBoxContainer = $ResultOverlay/ResultPanel/VBox/CardList
@onready var result_ok_btn: Button        = $ResultOverlay/ResultPanel/VBox/OkBtn

func _ready() -> void:
	Collection.credits_changed.connect(_on_credits_changed)
	$Panel/VBox/Header/CloseBtn.pressed.connect(_on_close)
	result_ok_btn.pressed.connect(func() -> void: result_overlay.hide())
	result_overlay.hide()
	_refresh_credits()
	_build_pack_cards()

# ─────────────────────────────────────────────────────────────
# Credits display
# ─────────────────────────────────────────────────────────────
func _refresh_credits() -> void:
	credits_label.text = "%d Credits" % Collection.credits

func _on_credits_changed(_new_amount: int) -> void:
	_refresh_credits()
	_build_pack_cards()  # refresh buy-button disabled states

# ─────────────────────────────────────────────────────────────
# Pack card building
# ─────────────────────────────────────────────────────────────
func _build_pack_cards() -> void:
	for child in pack_row.get_children():
		child.queue_free()
	for pack: Dictionary in ShopManager.get_all_packs():
		pack_row.add_child(_make_pack_card(pack))
	pack_row.add_child(_make_disc_card())

func _make_pack_card(pack: Dictionary) -> Control:
	var accent: Color = pack.get("accent", Color(0.18, 0.55, 1.0))
	var can_afford: bool = Collection.credits >= pack["price"]

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(268, 370)

	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Color(0.02, 0.038, 0.082, 1.0)
	card_sb.border_width_left   = 3
	card_sb.border_width_top    = 1
	card_sb.border_width_right  = 1
	card_sb.border_width_bottom = 1
	card_sb.border_color = Color(accent.r, accent.g, accent.b, 0.65)
	card_sb.corner_radius_top_left     = 7
	card_sb.corner_radius_top_right    = 7
	card_sb.corner_radius_bottom_right = 7
	card_sb.corner_radius_bottom_left  = 7
	card_sb.content_margin_left   = 16
	card_sb.content_margin_right  = 16
	card_sb.content_margin_top    = 18
	card_sb.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", card_sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	# — Pack name ——————————————————————————
	var name_lbl := Label.new()
	name_lbl.text = pack["name"]
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 1.0))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_lbl)

	# — Accent line ——————————————————————————
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(accent.r, accent.g, accent.b, 0.3)
	vbox.add_child(sep)

	# — Description ——————————————————————————
	var desc := Label.new()
	desc.text = pack.get("description", "")
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.58, 0.7, 0.8, 0.82))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)

	# — Contents tag ——————————————————————————
	var contents := Label.new()
	contents.text = _contents_text(pack)
	contents.add_theme_font_size_override("font_size", 11)
	contents.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.55))
	contents.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(contents)

	# — Price ——————————————————————————————
	var price_lbl := Label.new()
	price_lbl.text = "%d Credits" % pack["price"]
	price_lbl.add_theme_font_size_override("font_size", 22)
	price_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.82, 0.22, 1.0) if can_afford else Color(0.75, 0.28, 0.28, 0.8))
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(price_lbl)

	# — Buy button ——————————————————————————
	var btn := Button.new()
	btn.text = "BUY PACK"
	btn.disabled = not can_afford
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 1.0))

	var btn_n := StyleBoxFlat.new()
	btn_n.bg_color = Color(accent.r * 0.12, accent.g * 0.12, accent.b * 0.12, 1.0)
	btn_n.border_width_left = 2; btn_n.border_width_top = 1
	btn_n.border_width_right = 1; btn_n.border_width_bottom = 1
	btn_n.border_color = Color(accent.r, accent.g, accent.b, 0.65)
	btn_n.corner_radius_top_left = 4; btn_n.corner_radius_top_right = 4
	btn_n.corner_radius_bottom_right = 4; btn_n.corner_radius_bottom_left = 4
	var btn_h := btn_n.duplicate() as StyleBoxFlat
	btn_h.bg_color = Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.22, 1.0)
	btn_h.border_color = Color(accent.r, accent.g, accent.b, 1.0)
	btn.add_theme_stylebox_override("normal",   btn_n)
	btn.add_theme_stylebox_override("hover",    btn_h)
	btn.add_theme_stylebox_override("pressed",  btn_n)
	btn.add_theme_stylebox_override("focus",    btn_n)
	btn.add_theme_stylebox_override("disabled", btn_n)

	var pack_id: String = pack["id"]
	btn.pressed.connect(func() -> void: _on_buy(pack_id))
	vbox.add_child(btn)

	return card

func _make_disc_card() -> Control:
	var accent := Color(0.85, 0.55, 1.0)
	var can_afford: bool = Collection.credits >= ShopManager.MUSIC_DISC_PRICE

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(268, 370)

	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Color(0.02, 0.018, 0.05, 1.0)
	card_sb.border_width_left   = 3
	card_sb.border_width_top    = 1
	card_sb.border_width_right  = 1
	card_sb.border_width_bottom = 1
	card_sb.border_color = Color(accent.r, accent.g, accent.b, 0.65)
	card_sb.corner_radius_top_left     = 7
	card_sb.corner_radius_top_right    = 7
	card_sb.corner_radius_bottom_right = 7
	card_sb.corner_radius_bottom_left  = 7
	card_sb.content_margin_left   = 16
	card_sb.content_margin_right  = 16
	card_sb.content_margin_top    = 18
	card_sb.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", card_sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	var icon_lbl := Label.new()
	icon_lbl.text = "💿"
	icon_lbl.add_theme_font_size_override("font_size", 48)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = "Music Disc"
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 1.0))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(accent.r, accent.g, accent.b, 0.3)
	vbox.add_child(sep)

	var desc := Label.new()
	desc.text = "Change battle music once per turn during a match.\nUse from the Options menu."
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.58, 0.7, 0.8, 0.82))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)

	var owned_lbl := Label.new()
	owned_lbl.text = "Owned: %d" % Collection.music_discs
	owned_lbl.add_theme_font_size_override("font_size", 11)
	owned_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.6))
	owned_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(owned_lbl)

	var price_lbl := Label.new()
	price_lbl.text = "%d Credits" % ShopManager.MUSIC_DISC_PRICE
	price_lbl.add_theme_font_size_override("font_size", 22)
	price_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.82, 0.22, 1.0) if can_afford else Color(0.75, 0.28, 0.28, 0.8))
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(price_lbl)

	var btn := Button.new()
	btn.text = "BUY DISC"
	btn.disabled = not can_afford
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 1.0))
	var btn_n := StyleBoxFlat.new()
	btn_n.bg_color = Color(accent.r * 0.12, accent.g * 0.12, accent.b * 0.12, 1.0)
	btn_n.border_width_left = 2; btn_n.border_width_top = 1
	btn_n.border_width_right = 1; btn_n.border_width_bottom = 1
	btn_n.border_color = Color(accent.r, accent.g, accent.b, 0.65)
	btn_n.corner_radius_top_left = 4; btn_n.corner_radius_top_right = 4
	btn_n.corner_radius_bottom_right = 4; btn_n.corner_radius_bottom_left = 4
	var btn_h := btn_n.duplicate() as StyleBoxFlat
	btn_h.bg_color = Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.22, 1.0)
	btn_h.border_color = Color(accent.r, accent.g, accent.b, 1.0)
	btn.add_theme_stylebox_override("normal",   btn_n)
	btn.add_theme_stylebox_override("hover",    btn_h)
	btn.add_theme_stylebox_override("pressed",  btn_n)
	btn.add_theme_stylebox_override("focus",    btn_n)
	btn.add_theme_stylebox_override("disabled", btn_n)
	btn.pressed.connect(func() -> void:
		if ShopManager.purchase_music_disc():
			_show_result("Music Disc", [], "")
			result_title.text = "Purchased: Music Disc  💿"
			result_title.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))
		else:
			_show_result("", [], "Not enough credits.")
		_build_pack_cards())
	vbox.add_child(btn)

	return card

func _contents_text(pack: Dictionary) -> String:
	var parts: Array = []
	for slot: Dictionary in pack.get("slots", []):
		var n: int = slot.get("count", 1)
		var t: String = slot["type"].capitalize()
		parts.append("%d %s%s" % [n, t, "s" if n > 1 else ""])
	return " + ".join(parts)

# ─────────────────────────────────────────────────────────────
# Purchase flow
# ─────────────────────────────────────────────────────────────
func _on_buy(pack_id: String) -> void:
	var res := ShopManager.purchase_pack(pack_id)
	if not res["success"]:
		_show_result("Purchase Failed", [], res["error"])
		return
	var pack_name: String = ShopManager.get_pack(pack_id).get("name", "Pack")
	_show_result(pack_name, res["cards"], "")

func _show_result(pack_name: String, cards: Array, error: String) -> void:
	for child in result_card_list.get_children():
		child.queue_free()

	if error != "":
		result_title.text = "Error"
		result_title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		var err_lbl := Label.new()
		err_lbl.text = error
		err_lbl.add_theme_color_override("font_color", Color(0.9, 0.6, 0.6))
		err_lbl.add_theme_font_size_override("font_size", 14)
		err_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_card_list.add_child(err_lbl)
	else:
		result_title.text = "Opened: %s" % pack_name
		result_title.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
		for card: Dictionary in cards:
			result_card_list.add_child(_make_result_row(card))

	result_overlay.show()

func _make_result_row(card: Dictionary) -> Control:
	var c_type: String = card.get("type", "?")
	var type_color: Color
	match c_type:
		"character": type_color = Color(0.28, 0.82, 1.0)
		"trap":      type_color = Color(0.78, 0.28, 1.0)
		"tech":      type_color = Color(0.28, 1.0, 0.62)
		_:           type_color = Color(0.6, 0.6, 0.6)

	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 46)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.025, 0.05, 0.10, 1.0)
	sb.border_width_left = 3; sb.border_color = type_color
	sb.corner_radius_top_left = 4; sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4; sb.corner_radius_bottom_left = 4
	sb.content_margin_left = 12; sb.content_margin_right = 12
	sb.content_margin_top = 6; sb.content_margin_bottom = 6
	row.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)

	# Type tag
	var type_lbl := Label.new()
	type_lbl.text = c_type.to_upper()
	type_lbl.custom_minimum_size = Vector2(88, 0)
	type_lbl.add_theme_font_size_override("font_size", 10)
	type_lbl.add_theme_color_override("font_color", Color(type_color.r, type_color.g, type_color.b, 0.75))
	type_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(type_lbl)

	# Card name
	var name_lbl := Label.new()
	name_lbl.text = card.get("name", "?")
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_lbl)

	# Source pack
	var src_lbl := Label.new()
	src_lbl.text = card.get("from_pack", "")
	src_lbl.add_theme_font_size_override("font_size", 10)
	src_lbl.add_theme_color_override("font_color", Color(0.42, 0.52, 0.62, 0.65))
	src_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(src_lbl)

	return row

# ─────────────────────────────────────────────────────────────
# Close
# ─────────────────────────────────────────────────────────────
func _on_close() -> void:
	emit_signal("closed")
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if result_overlay.visible:
			result_overlay.hide()
		else:
			_on_close()
