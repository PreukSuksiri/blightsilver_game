class_name AdminDeckEditorSupport
extends RefCounted

const FULL_CARDS_DIR := "res://assets/textures/cards/full_cards/"
const PREVIEW_W := 350.0
const PREVIEW_H := 485.0


static func affinity_name_for(card_type: String, card_name: String) -> String:
	match card_type:
		"character":
			var data: CharacterData = CardDatabase.get_character(card_name)
			if data != null:
				return data.get_affinity_name()
		"union":
			var u: UnionData = UnionDatabase.get_union(card_name)
			if u != null:
				return CharacterData.Affinity.keys()[int(u.affinity)]
	return ""


static func card_matches_search(card_name: String, card_type: String, query: String) -> bool:
	if query.is_empty():
		return true
	var q: String = query.to_lower().strip_edges()
	if q in card_name.to_lower():
		return true
	var aff: String = affinity_name_for(card_type, card_name).to_lower()
	return not aff.is_empty() and q in aff


static func card_include_in_demo(card_name: String, card_type: String) -> bool:
	match card_type:
		"character":
			var data: CharacterData = CardDatabase.get_character(card_name)
			return data != null and data.include_in_demo
		"trap":
			var trap_data: TrapData = CardDatabase.get_trap(card_name)
			return trap_data != null and trap_data.include_in_demo
		"tech":
			var tech_data: TechCardData = CardDatabase.get_tech(card_name)
			return tech_data != null and tech_data.include_in_demo
	return false


static func card_texture(card_name: String, card_type: String = "") -> Texture2D:
	var snake: String = card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
	var paths: PackedStringArray = []
	match card_type:
		"tech":
			paths.append(FULL_CARDS_DIR + "tech_" + snake + ".png")
		_:
			pass
	paths.append(FULL_CARDS_DIR + snake + ".png")
	for path: String in paths:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


static func demo_unions() -> Array:
	var result: Array = []
	for u: Variant in UnionDatabase.get_all_unions():
		if u is UnionData and (u as UnionData).include_in_demo:
			result.append(u)
	result.sort_custom(func(a: UnionData, b: UnionData) -> bool: return a.card_name < b.card_name)
	return result


static func achievable_demo_unions(characters: Array) -> Array:
	var result: Array = []
	for u: Variant in demo_unions():
		if UnionDatabase.deck_can_form_union(characters, u):
			result.append(u)
	return result


static func describe_union_condition(cond: Dictionary) -> String:
	if cond.is_empty():
		return "Any unit card"
	if cond.has("card_name"):
		return str(cond["card_name"])
	var parts: Array = []
	if cond.has("name_contains"):
		parts.append('name contains "%s"' % str(cond["name_contains"]))
	if cond.has("affinity") and int(cond["affinity"]) >= 0:
		parts.append("%s affinity" % CharacterData.Affinity.keys()[int(cond["affinity"])].capitalize())
	if cond.has("min_cost"):
		parts.append("%d◆+" % int(cond["min_cost"]))
	if cond.has("min_atk"):
		parts.append("ATK %d+" % int(cond["min_atk"]))
	if cond.has("min_def"):
		parts.append("DEF %d+" % int(cond["min_def"]))
	return ", ".join(parts) if parts.size() > 0 else "Any unit card"


static func add_union_materials_to_deck(
		deck: DeckData,
		union_name: String,
		host: Node,
		require_collection: bool = false,
		demo_only: bool = false
) -> Dictionary:
	var result := {"ok": false, "added": [], "message": ""}
	if deck == null:
		result["message"] = "No deck loaded."
		return result
	var u: UnionData = UnionDatabase.get_union(union_name)
	if u == null:
		result["message"] = "Unknown union: %s" % union_name
		return result
	if not u.include_in_demo:
		result["message"] = "%s is not flagged for demo." % union_name
		return result

	if UnionDatabase.deck_can_form_union(deck.characters, u):
		_show_info_dialog(host, "Union Already Available",
			"This Union card is already available in your deck.")
		result["message"] = "Union already achievable."
		return result

	var assigned: Array = []
	var missing_conds: Array = []
	var used_in_assign: Array = []

	for cond: Dictionary in u.material_conditions:
		var candidates: Array = []
		for cname: String in CardDatabase.get_all_character_names():
			if demo_only and not card_include_in_demo(cname, "character"):
				continue
			if require_collection and Collection.get_card_count(cname) == 0:
				continue
			if cname in deck.characters:
				continue
			if cname in used_in_assign:
				continue
			if UnionDatabase.deck_char_satisfies(cname, cond):
				var data: CharacterData = CardDatabase.get_character(cname)
				candidates.append({"name": cname, "cost": data.crystal_cost})
		if candidates.is_empty():
			missing_conds.append(cond)
		else:
			candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return a["cost"] < b["cost"] if a["cost"] != b["cost"] else a["name"] < b["name"])
			var chosen: String = candidates[0]["name"]
			assigned.append(chosen)
			used_in_assign.append(chosen)

	if missing_conds.size() > 0:
		var found_str: String = ", ".join(assigned) if assigned.size() > 0 else "none"
		var missing_str: String = ""
		for cond: Dictionary in missing_conds:
			missing_str += "\n  • " + describe_union_condition(cond)
		_show_info_dialog(host, "Not Enough Union Material",
			"Not enough union material.\n\nFormula: %s\n\nFound: %s\nMissing:%s"
			% [u.formula_description, found_str, missing_str])
		result["message"] = "Missing union materials."
		return result

	var added: Array = []
	for cname: String in assigned:
		if cname in deck.characters:
			continue
		if deck.characters.size() >= DeckData.MAX_CHARACTERS:
			result["message"] = "Unit limit reached; some union materials could not be added."
			break
		var grid_cards: int = deck.characters.size() + deck.traps.size()
		if grid_cards >= DeckData.TOTAL_SLOTS:
			result["message"] = "Grid deck is full; some union materials could not be added."
			break
		deck.characters.append(cname)
		added.append(cname)

	result["ok"] = not added.is_empty()
	result["added"] = added
	if added.is_empty() and result["message"].is_empty():
		result["message"] = "No cards added."
	elif added.size() > 0:
		result["message"] = "Added union materials: %s" % ", ".join(added)
	return result


static func show_add_card_dialog(
		host: Control,
		card_type: String,
		font: Font,
		on_chosen: Callable,
		demo_only: bool = false
) -> void:
	var pop := PanelContainer.new()
	pop.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pop.offset_left = -520.0
	pop.offset_right = 520.0
	pop.offset_top = -340.0
	pop.offset_bottom = 340.0
	pop.z_index = 10
	host.add_child(pop)

	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	pop.add_child(outer)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size = Vector2(280.0, 0.0)
	left.add_theme_constant_override("separation", 6)
	outer.add_child(left)

	var hdr := Label.new()
	hdr.text = "Add %s card%s" % [card_type.capitalize(), " (demo)" if demo_only else ""]
	hdr.add_theme_font_override("font", font)
	hdr.add_theme_font_size_override("font_size", 15)
	hdr.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	left.add_child(hdr)

	var search := LineEdit.new()
	search.placeholder_text = "Search name or affinity…"
	search.add_theme_font_override("font", font)
	left.add_child(search)

	var db_list := ItemList.new()
	db_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	db_list.custom_minimum_size = Vector2(0.0, 320.0)
	db_list.add_theme_font_override("font", font)
	db_list.add_theme_font_size_override("font_size", 12)
	left.add_child(db_list)

	var preview_col := VBoxContainer.new()
	preview_col.custom_minimum_size = Vector2(PREVIEW_W + 8.0, 0.0)
	preview_col.add_theme_constant_override("separation", 4)
	outer.add_child(preview_col)

	var preview_hdr := Label.new()
	preview_hdr.text = "Preview"
	preview_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_hdr.add_theme_font_override("font", font)
	preview_hdr.add_theme_font_size_override("font_size", 12)
	preview_hdr.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	preview_col.add_child(preview_hdr)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(PREVIEW_W, PREVIEW_H)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_col.add_child(preview)

	var preview_name := Label.new()
	preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_name.add_theme_font_override("font", font)
	preview_name.add_theme_font_size_override("font_size", 11)
	preview_name.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	preview_col.add_child(preview_name)

	var all_names: Array = []
	var raw_names: Array = []
	match card_type:
		"character":
			raw_names = CardDatabase.characters.keys()
		"trap":
			raw_names = CardDatabase.traps.keys()
		"tech":
			raw_names = CardDatabase.tech_cards.keys()
	for n: Variant in raw_names:
		var name: String = str(n)
		if demo_only and not card_include_in_demo(name, card_type):
			continue
		all_names.append(name)
	all_names.sort()

	var update_preview := func(card_name: String) -> void:
		preview_name.text = card_name
		var tex: Texture2D = card_texture(card_name, card_type)
		preview.texture = tex
		if tex == null:
			preview.modulate = Color(0.45, 0.45, 0.55)
		else:
			preview.modulate = Color(1, 1, 1)

	var rebuild_db_list := func(query: String) -> void:
		db_list.clear()
		for n: String in all_names:
			if card_matches_search(n, card_type, query):
				if card_type == "character":
					var data: CharacterData = CardDatabase.get_character(n)
					var aff: String = data.get_affinity_name() if data != null else "?"
					db_list.add_item("[%s] %s" % [aff, n])
				else:
					db_list.add_item(n)
	rebuild_db_list.call("")
	search.text_changed.connect(rebuild_db_list)

	var card_name_from_list_label := func(label: String) -> String:
		return label.split("] ", false, 1)[-1] if label.begins_with("[") else label

	var resolve_chosen_card := func() -> String:
		var sel: PackedInt32Array = db_list.get_selected_items()
		if not sel.is_empty():
			return card_name_from_list_label.call(db_list.get_item_text(sel[0]))
		if db_list.item_count == 1:
			return card_name_from_list_label.call(db_list.get_item_text(0))
		var q := search.text.strip_edges()
		if q.is_empty():
			return ""
		var q_lower := q.to_lower()
		for n: String in all_names:
			if n.to_lower() == q_lower:
				return n
		for i: int in range(db_list.item_count):
			var candidate: String = card_name_from_list_label.call(db_list.get_item_text(i))
			if candidate.to_lower() == q_lower:
				return candidate
		return ""

	var confirm_add := func() -> void:
		var chosen: String = resolve_chosen_card.call()
		if chosen.is_empty():
			return
		on_chosen.call(chosen)
		pop.queue_free()

	db_list.item_selected.connect(func(idx: int) -> void:
		update_preview.call(card_name_from_list_label.call(db_list.get_item_text(idx))))
	db_list.item_activated.connect(func(_idx: int) -> void: confirm_add.call())
	search.text_submitted.connect(func(_t: String) -> void: confirm_add.call())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	left.add_child(row)

	var ok_btn := Button.new()
	ok_btn.text = "Add"
	ok_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok_btn.add_theme_font_override("font", font)
	ok_btn.pressed.connect(func() -> void: confirm_add.call())
	row.add_child(ok_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_override("font", font)
	cancel_btn.pressed.connect(func() -> void: pop.queue_free())
	row.add_child(cancel_btn)


static func show_union_add_dialog(
		host: Control,
		deck: DeckData,
		font: Font,
		on_done: Callable,
		demo_only: bool = false
) -> void:
	var pop := PanelContainer.new()
	pop.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pop.offset_left = -520.0
	pop.offset_right = 520.0
	pop.offset_top = -340.0
	pop.offset_bottom = 340.0
	pop.z_index = 10
	host.add_child(pop)

	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	pop.add_child(outer)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size = Vector2(280.0, 0.0)
	left.add_theme_constant_override("separation", 6)
	outer.add_child(left)

	var hdr := Label.new()
	hdr.text = "Add Union materials (demo)"
	hdr.add_theme_font_override("font", font)
	hdr.add_theme_font_size_override("font_size", 15)
	hdr.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0))
	left.add_child(hdr)

	var search := LineEdit.new()
	search.placeholder_text = "Search name or affinity…"
	search.add_theme_font_override("font", font)
	left.add_child(search)

	var union_list := ItemList.new()
	union_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	union_list.custom_minimum_size = Vector2(0.0, 320.0)
	union_list.add_theme_font_override("font", font)
	union_list.add_theme_font_size_override("font_size", 12)
	left.add_child(union_list)

	var preview_col := VBoxContainer.new()
	preview_col.custom_minimum_size = Vector2(PREVIEW_W + 8.0, 0.0)
	preview_col.add_theme_constant_override("separation", 4)
	outer.add_child(preview_col)

	var preview_hdr := Label.new()
	preview_hdr.text = "Preview"
	preview_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_hdr.add_theme_font_override("font", font)
	preview_hdr.add_theme_font_size_override("font_size", 12)
	preview_hdr.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0))
	preview_col.add_child(preview_hdr)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(PREVIEW_W, PREVIEW_H)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_col.add_child(preview)

	var preview_name := Label.new()
	preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_name.add_theme_font_override("font", font)
	preview_name.add_theme_font_size_override("font_size", 11)
	preview_name.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0))
	preview_col.add_child(preview_name)

	var preview_formula := Label.new()
	preview_formula.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_formula.add_theme_font_override("font", font)
	preview_formula.add_theme_font_size_override("font_size", 10)
	preview_formula.add_theme_color_override("font_color", Color(0.65, 0.8, 0.9))
	preview_col.add_child(preview_formula)

	var unions: Array = demo_unions()
	var union_names: Array = []
	for u: UnionData in unions:
		union_names.append(u.card_name)

	var update_preview := func(idx: int) -> void:
		if idx < 0 or idx >= unions.size():
			return
		var u: UnionData = unions[idx] as UnionData
		preview_name.text = u.card_name
		preview_formula.text = u.formula_description
		var tex: Texture2D = card_texture(u.card_name, "union")
		preview.texture = tex
		if tex == null:
			preview.modulate = Color(0.25, 0.90, 1.0)
		else:
			preview.modulate = Color(1, 1, 1)

	var rebuild_list := func(query: String) -> void:
		union_list.clear()
		unions.clear()
		union_names.clear()
		for u: Variant in demo_unions():
			var ud: UnionData = u as UnionData
			if not card_matches_search(ud.card_name, "union", query):
				continue
			unions.append(ud)
			union_names.append(ud.card_name)
			var aff: String = CharacterData.Affinity.keys()[int(ud.affinity)]
			union_list.add_item("[%s] %s" % [aff, ud.card_name])
	rebuild_list.call("")
	search.text_changed.connect(rebuild_list)

	union_list.item_selected.connect(update_preview)
	union_list.item_activated.connect(func(idx: int) -> void:
		if idx < 0 or idx >= unions.size():
			return
		var u: UnionData = unions[idx] as UnionData
		var res: Dictionary = add_union_materials_to_deck(
			deck, u.card_name, host, false, demo_only)
		on_done.call(res)
		pop.queue_free())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	left.add_child(row)

	var ok_btn := Button.new()
	ok_btn.text = "Add Materials"
	ok_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok_btn.add_theme_font_override("font", font)
	ok_btn.pressed.connect(func() -> void:
		var sel: PackedInt32Array = union_list.get_selected_items()
		if sel.is_empty():
			return
		var u: UnionData = unions[sel[0]] as UnionData
		var res: Dictionary = add_union_materials_to_deck(
			deck, u.card_name, host, false, demo_only)
		on_done.call(res)
		pop.queue_free())
	row.add_child(ok_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_override("font", font)
	cancel_btn.pressed.connect(func() -> void: pop.queue_free())
	row.add_child(cancel_btn)


static func ensure_grid_flash_overlays(cells: Array) -> void:
	for cell: Variant in cells:
		if not cell is Button:
			continue
		var btn: Button = cell as Button
		if btn.get_child_count() > 0 and btn.get_child(0) is ColorRect:
			continue
		var flash_cr := ColorRect.new()
		flash_cr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		flash_cr.color = Color(0.25, 0.90, 1.00, 0.0)
		flash_cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(flash_cr)
		btn.clip_contents = true


static func stop_zone_flash(state: Dictionary) -> void:
	var tween: Tween = state.get("tween", null) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	state["tween"] = null
	for cell: Variant in state.get("cells", []):
		if cell is Button:
			var btn: Button = cell as Button
			if btn.get_child_count() > 0:
				var flash_cr: ColorRect = btn.get_child(0) as ColorRect
				if flash_cr != null:
					flash_cr.color.a = 0.0
	state["cells"] = []


static func start_zone_flash(
		state: Dictionary,
		grid_cells: Array,
		grid_cols: int,
		u: UnionData,
		host: Control
) -> void:
	stop_zone_flash(state)
	var flash_cells: Array = []
	for zv: Vector2i in u.union_zone:
		var idx: int = zv.x * grid_cols + zv.y
		if idx < 0 or idx >= grid_cells.size():
			continue
		var cell: Button = grid_cells[idx] as Button
		if cell == null:
			continue
		ensure_grid_flash_overlays([cell])
		flash_cells.append(cell)
	state["cells"] = flash_cells
	if flash_cells.is_empty():
		return
	var tween: Tween = host.create_tween().set_loops(3)
	state["tween"] = tween
	var first: bool = true
	for cell: Button in flash_cells:
		var flash_cr: ColorRect = cell.get_child(0) as ColorRect
		if first:
			tween.tween_property(flash_cr, "color:a", 0.45, 0.30)
			first = false
		else:
			tween.parallel().tween_property(flash_cr, "color:a", 0.45, 0.30)
	first = true
	for cell: Button in flash_cells:
		var flash_cr: ColorRect = cell.get_child(0) as ColorRect
		if first:
			tween.tween_property(flash_cr, "color:a", 0.0, 0.30)
			first = false
		else:
			tween.parallel().tween_property(flash_cr, "color:a", 0.0, 0.30)
	tween.finished.connect(func() -> void: stop_zone_flash(state))


static func refresh_possible_union_list(
		list: ItemList,
		deck: DeckData,
		unions_ref: Array
) -> void:
	unions_ref.clear()
	list.clear()
	if deck == null:
		return
	for u: Variant in achievable_demo_unions(deck.characters):
		unions_ref.append(u)
		list.add_item((u as UnionData).card_name)


static func _show_info_dialog(host: Node, title: String, text: String) -> void:
	var popup := AcceptDialog.new()
	popup.title = title
	popup.dialog_text = text
	host.add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func() -> void: popup.queue_free())
	popup.canceled.connect(func() -> void: popup.queue_free())
