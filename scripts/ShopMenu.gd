extends Control

signal closed()

const DEFAULT_PACK_IMAGE: String = "res://assets/textures/cards/booster_pack/booster_pack_basic.png"
const BOOSTER_PACK_DIR: String = "res://assets/textures/cards/booster_pack/"
const PACK_CARD_ART_ASPECT: float = 832.0 / 1216.0  # booster pack illustration width / height
const PACK_CARD_WIDTH_SCALE: float = 1.14           # panel padding + footer controls
const PACK_ROW_GAP: int = 28
const PANEL_VIEWPORT_MARGIN: Vector2 = Vector2(32.0, 40.0)
const PANEL_MAX_SIZE: Vector2 = Vector2(1680.0, 900.0)

@onready var panel: Panel                  = $Panel
@onready var shop_vbox: VBoxContainer      = $Panel/VBox
@onready var credits_label: Label         = $Panel/VBox/Header/CreditsLabel
@onready var subtitle_label: Label        = $Panel/VBox/Header/SubtitleLabel
@onready var pack_scroll: ScrollContainer = $Panel/VBox/PackScroll
@onready var pack_row: HBoxContainer      = $Panel/VBox/PackScroll/PackRow
@onready var result_overlay: Control      = $ResultOverlay
@onready var result_title: Label          = $ResultOverlay/ResultPanel/VBox/TitleLabel
@onready var result_card_list: VBoxContainer = $ResultOverlay/ResultPanel/VBox/CardList
@onready var result_ok_btn: Button        = $ResultOverlay/ResultPanel/VBox/OkBtn

var _card_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	Collection.credits_changed.connect(_on_credits_changed)
	var header_rebuild: Dictionary = MenuScreenHeader.rebuild_panel_header(
		$Panel/VBox/Header,
		$Panel/VBox/Header/TitleLabel,
		$Panel/VBox/Header/CloseBtn)
	var close_btn: Button = header_rebuild.get("close_btn", null) as Button
	if close_btn != null:
		close_btn.pressed.connect(_on_close)
	_relocate_shop_header_extras()
	result_ok_btn.pressed.connect(func() -> void: result_overlay.hide())
	result_overlay.hide()
	_apply_panel_to_viewport()
	_refresh_credits()
	call_deferred("_init_pack_cards")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		call_deferred("_on_viewport_resized")

func _relocate_shop_header_extras() -> void:
	if is_instance_valid(subtitle_label):
		subtitle_label.queue_free()
	if is_instance_valid(credits_label):
		if credits_label.get_parent():
			credits_label.get_parent().remove_child(credits_label)
		credits_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		shop_vbox.add_child(credits_label)
		shop_vbox.move_child(credits_label, pack_scroll.get_index())

func _apply_panel_to_viewport() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var panel_w: float = minf(vp.x - PANEL_VIEWPORT_MARGIN.x * 2.0, PANEL_MAX_SIZE.x)
	var panel_h: float = minf(vp.y - PANEL_VIEWPORT_MARGIN.y * 2.0, PANEL_MAX_SIZE.y)
	panel_w = maxf(panel_w, 480.0)
	panel_h = maxf(panel_h, 420.0)
	panel.offset_left = -panel_w * 0.5
	panel.offset_top = -panel_h * 0.5
	panel.offset_right = panel_w * 0.5
	panel.offset_bottom = panel_h * 0.5

func _on_viewport_resized() -> void:
	_apply_panel_to_viewport()
	if _card_size == Vector2.ZERO:
		return
	await get_tree().process_frame
	var new_size := _compute_card_size()
	if new_size.is_equal_approx(_card_size) and pack_row.get_child_count() > 0:
		return
	_card_size = new_size
	_build_pack_cards()

func _init_pack_cards() -> void:
	await get_tree().process_frame
	_apply_panel_to_viewport()
	await get_tree().process_frame
	_card_size = _compute_card_size()
	_build_pack_cards()

# ─────────────────────────────────────────────────────────────
# Credits display
# ─────────────────────────────────────────────────────────────
func _refresh_credits() -> void:
	credits_label.text = "%d Credits" % Collection.credits

func _on_credits_changed(_new_amount: int) -> void:
	_refresh_credits()
	_refresh_pack_buy_states()

# ─────────────────────────────────────────────────────────────
# Pack card building
# ─────────────────────────────────────────────────────────────
func _compute_card_size() -> Vector2:
	var scroll_w: float = maxf(pack_scroll.size.x, 320.0)
	var scroll_h: float = maxf(pack_scroll.size.y, 240.0)
	# Size cards so up to three fit across the visible shop row.
	var fit_count: int = 3
	var gap_total: float = PACK_ROW_GAP * maxi(0, fit_count - 1)
	var max_card_w: float = (scroll_w - gap_total) / float(fit_count)
	var card_w: float = max_card_w
	var card_h: float = card_w / (PACK_CARD_ART_ASPECT * PACK_CARD_WIDTH_SCALE)
	if card_h > scroll_h:
		card_h = scroll_h
		card_w = card_h * PACK_CARD_ART_ASPECT * PACK_CARD_WIDTH_SCALE
	return Vector2(card_w, card_h)

func _update_pack_scroll_mode(catalog_count: int) -> void:
	if catalog_count <= 3:
		pack_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		pack_row.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		pack_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		pack_row.alignment = BoxContainer.ALIGNMENT_BEGIN

func _build_pack_cards() -> void:
	for child in pack_row.get_children():
		child.queue_free()
	var catalog: Array = ShopManager.get_shop_catalog()
	var count: int = catalog.size()
	_card_size = _compute_card_size()
	var total_w: float = _card_size.x * count + PACK_ROW_GAP * maxi(0, count - 1)
	pack_row.custom_minimum_size = Vector2(total_w, _card_size.y)
	_update_pack_scroll_mode(count)
	for pack: Dictionary in catalog:
		pack_row.add_child(_make_pack_card(pack, _card_size))

func _refresh_pack_buy_states() -> void:
	var catalog: Array = ShopManager.get_shop_catalog()
	var cards := pack_row.get_children()
	for i: int in range(mini(cards.size(), catalog.size())):
		_update_pack_card_buy_state(cards[i], catalog[i] as Dictionary)

func _update_pack_card_buy_state(card_root: Node, pack: Dictionary) -> void:
	var can_afford: bool = Collection.credits >= int(pack.get("price", 0))
	var shop_unlocked: bool = bool(pack.get("shop_unlocked", true))
	var can_buy: bool = shop_unlocked and can_afford
	var vbox: Node = card_root.get_child(0) if card_root.get_child_count() > 0 else null
	if vbox == null:
		return
	for child in vbox.get_children():
		if child is Label and str((child as Label).text).ends_with(" Credits"):
			(child as Label).add_theme_color_override("font_color",
				Color(0.95, 0.82, 0.22, 1.0) if can_buy else Color(0.75, 0.28, 0.28, 0.8))
		elif child is Button and (child as Button).text in ["BUY PACK", "BUY SCROLL", "LOCKED"]:
			var is_scroll: bool = str(pack.get("product_type", "")) == "union_scroll"
			(child as Button).text = ("BUY SCROLL" if is_scroll else "BUY PACK") if shop_unlocked else "LOCKED"
			(child as Button).disabled = not can_buy

func _make_pack_card(pack: Dictionary, card_size: Vector2) -> Control:
	var accent_raw: Variant = pack.get("accent", null)
	var accent: Color
	if accent_raw is Array and accent_raw.size() >= 3:
		accent = Color(accent_raw[0], accent_raw[1], accent_raw[2], accent_raw[3] if accent_raw.size() >= 4 else 1.0)
	elif accent_raw is Color:
		accent = accent_raw
	else:
		accent = Color(0.18, 0.55, 1.0)
	var can_afford: bool = Collection.credits >= pack["price"]
	var shop_unlocked: bool = bool(pack.get("shop_unlocked", true))
	var can_buy: bool = shop_unlocked and can_afford

	var card := PanelContainer.new()
	card.custom_minimum_size = card_size

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
	vbox.add_theme_constant_override("separation", 10)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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

	var pack_tex: Texture2D = _load_pack_texture(pack)
	if pack_tex != null:
		var img := TextureRect.new()
		img.texture = pack_tex
		img.custom_minimum_size = Vector2(0, maxf(80.0, card_size.y * 0.48))
		img.size_flags_vertical = Control.SIZE_EXPAND_FILL
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(img)

	# — Description ——————————————————————————
	var desc := Label.new()
	desc.text = pack.get("description", "")
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.58, 0.7, 0.8, 0.82))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.clip_text = true
	if str(pack.get("product_type", "")) == "union_scroll":
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	desc.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(desc)

	# — Contents tag ——————————————————————————
	var contents := Label.new()
	contents.text = _contents_text(pack)
	contents.add_theme_font_size_override("font_size", 11)
	contents.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.55))
	contents.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(contents)

	# — View Contents button (pool packs only) ——————————
	var card_pool: Variant = pack.get("card_pool", null)
	if card_pool is Array and not (card_pool as Array).is_empty():
		var vc_btn := Button.new()
		vc_btn.text = "View Contents"
		vc_btn.add_theme_font_size_override("font_size", 12)
		vc_btn.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.85))
		var vc_sb := StyleBoxFlat.new()
		vc_sb.bg_color   = Color(accent.r * 0.08, accent.g * 0.08, accent.b * 0.08, 1.0)
		vc_sb.border_width_left = 1; vc_sb.border_width_top    = 1
		vc_sb.border_width_right = 1; vc_sb.border_width_bottom = 1
		vc_sb.border_color = Color(accent.r, accent.g, accent.b, 0.4)
		vc_sb.corner_radius_top_left     = 4; vc_sb.corner_radius_top_right    = 4
		vc_sb.corner_radius_bottom_left  = 4; vc_sb.corner_radius_bottom_right = 4
		var vc_sb_h := vc_sb.duplicate() as StyleBoxFlat
		vc_sb_h.border_color = Color(accent.r, accent.g, accent.b, 0.9)
		vc_btn.add_theme_stylebox_override("normal",  vc_sb)
		vc_btn.add_theme_stylebox_override("hover",   vc_sb_h)
		vc_btn.add_theme_stylebox_override("pressed", vc_sb)
		vc_btn.add_theme_stylebox_override("focus",   vc_sb)
		var pid: String = str(pack.get("id", ""))
		vc_btn.pressed.connect(func() -> void:
			load("res://scripts/PackContentsOverlay.gd").open(get_tree().root, pid))
		vbox.add_child(vc_btn)

	var req_chapter: String = str(pack.get("unlock_requires_chapter", "")).strip_edges()
	var needs_tutorial: bool = bool(pack.get("unlock_requires_tutorial", false))
	if not shop_unlocked and (needs_tutorial or not req_chapter.is_empty()):
		var lock_lbl := Label.new()
		lock_lbl.text = ShopManager.get_pack_unlock_hint(pack)
		lock_lbl.add_theme_font_size_override("font_size", 11)
		lock_lbl.add_theme_color_override("font_color", Color(0.95, 0.72, 0.35, 0.9))
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(lock_lbl)

	# — Price ——————————————————————————————
	var price_lbl := Label.new()
	price_lbl.text = "%d Credits" % pack["price"]
	price_lbl.add_theme_font_size_override("font_size", 22)
	price_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.82, 0.22, 1.0) if can_buy else Color(0.75, 0.28, 0.28, 0.8))
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(price_lbl)

	# — Buy button ——————————————————————————
	var btn := Button.new()
	var is_scroll: bool = str(pack.get("product_type", "")) == "union_scroll"
	btn.text = ("BUY SCROLL" if is_scroll else "BUY PACK") if shop_unlocked else "LOCKED"
	btn.disabled = not can_buy
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

func _contents_text(pack: Dictionary) -> String:
	if str(pack.get("product_type", "")) == "union_scroll":
		var tag: String = str(pack.get("contents_tag", "")).strip_edges()
		return tag if not tag.is_empty() else UnionScrollManager.SHOP_CONTENTS
	var card_pool: Variant = pack.get("card_pool", null)
	if card_pool is Array and not (card_pool as Array).is_empty():
		var count: int = int(pack.get("card_count", 3))
		var pool_size: int = (card_pool as Array).size()
		return "Draws %d · %d cards in pool" % [count, pool_size]
	var parts: Array = []
	for slot: Dictionary in pack.get("slots", []):
		var n: int = slot.get("count", 1)
		var t: String = slot["type"].capitalize()
		parts.append("%d %s%s" % [n, t, "s" if n > 1 else ""])
	return " + ".join(parts)

func _resolve_pack_image_path(pack: Dictionary) -> String:
	if str(pack.get("product_type", "")) == "union_scroll":
		var item_path: String = str(pack.get("item_image", "")).strip_edges()
		if not item_path.is_empty():
			return item_path
	var path: String = str(pack.get("pack_image", "")).strip_edges()
	if path.is_empty():
		return DEFAULT_PACK_IMAGE
	if not path.begins_with("res://"):
		path = BOOSTER_PACK_DIR + path
	return path

func _load_pack_texture(pack: Dictionary) -> Texture2D:
	var path: String = _resolve_pack_image_path(pack)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if path != DEFAULT_PACK_IMAGE and ResourceLoader.exists(DEFAULT_PACK_IMAGE):
		return load(DEFAULT_PACK_IMAGE) as Texture2D
	return null

# ─────────────────────────────────────────────────────────────
# Purchase flow
# ─────────────────────────────────────────────────────────────
func _on_buy(pack_id: String) -> void:
	if pack_id == UnionScrollManager.PRODUCT_ID:
		var scroll_res: Dictionary = ShopManager.purchase_shop_item(pack_id, get_tree().root)
		if not scroll_res["success"]:
			_show_result("Purchase Failed", [], scroll_res["error"])
			return
		var union_name: String = str(scroll_res.get("union_name", ""))
		if union_name.is_empty():
			_show_result("Union Scroll", [], "")
		else:
			_show_result("Union Scroll", [{"name": union_name, "type": "union"}], "")
		return
	var res: Variant = ShopManager.purchase_pack(pack_id)
	if not res["success"]:
		_show_result("Purchase Failed", [], res["error"])
		return
	var cards: Array = res["cards"]
	# Show pack-opening animation when exactly 3 cards are received
	if cards.size() == 3:
		var n0: String = (cards[0] as Dictionary).get("name", "")
		var n1: String = (cards[1] as Dictionary).get("name", "")
		var n2: String = (cards[2] as Dictionary).get("name", "")
		var pack_dict: Dictionary = ShopManager.get_pack(pack_id)
		var pack_img: String  = str(pack_dict.get("pack_image", ""))
		var pack_nm: String   = str(pack_dict.get("name", ""))
		var overlay_script: GDScript = load("res://scripts/PackOpeningOverlay.gd")
		overlay_script.open(get_tree().root, pack_img, n0, n1, n2, true, pack_nm)
	var pack_name: String = ShopManager.get_pack(pack_id).get("name", "Pack")
	_show_result(pack_name, cards, "")

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
		"union":     type_color = Color(0.25, 0.90, 1.0)
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
	type_lbl.text = "UNION" if c_type == "union" else ("UNIT" if c_type == "character" else c_type.to_upper())
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
