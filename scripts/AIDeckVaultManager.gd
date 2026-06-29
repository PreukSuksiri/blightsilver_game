extends Control
# Admin overlay for managing named AI deck templates.
# Opened via admin command: ai_deck_vault
# Saves to / loads from data/ai_deck_vault.json

const DeckData = preload("res://resources/DeckData.gd")
const CHIVO_FONT := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")

const GRID_ROWS := 5
const GRID_COLS := 5
const CELL_SIZE := 48
const MAX_FORMATIONS := 5
const MAX_TAGS := 5

var _entries: Array = []
var _selected_idx: int = -1
var _deck: DeckData = null
var _tags: Array = []
var _featured_union: String = ""
var _featured_unit: String = ""

var _vault_list: ItemList = null
var _entry_id_edit: LineEdit = null
var _entry_label_edit: LineEdit = null
var _tags_list: ItemList = null
var _tag_input: LineEdit = null
var _featured_union_option: OptionButton = null
var _featured_union_block_sync: bool = false
var _featured_unit_option: OptionButton = null
var _featured_unit_block_sync: bool = false
var _deck_name_edit: LineEdit = null
var _char_list: ItemList = null
var _trap_list: ItemList = null
var _tech_list: ItemList = null
var _union_list: ItemList = null
var _union_hdr: Label = null
var _form_lbl: Label = null
var _status_lbl: Label = null

var _fe_overlay: Control = null
var _fe_list: ItemList = null
var _fe_name_edit: LineEdit = null
var _fe_grid_cells: Array = []
var _fe_pick_list: ItemList = null
var _fe_possible_union_list: ItemList = null
var _fe_possible_unions: Array = []
var _fe_flash_state: Dictionary = {}
var _fe_selected: int = -1
var _fe_card_pick: String = ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 200
	mouse_filter = Control.MOUSE_FILTER_STOP
	AIDeckVault.reload()
	_entries = AIDeckVault.get_entries()
	if _entries.is_empty():
		_entries.append(_make_blank_entry("new_ai_deck", "New AI Deck"))
	_deck = DeckData.new()
	_build_ui()
	_select_entry(0)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _fe_overlay != null and is_instance_valid(_fe_overlay):
			AdminDeckEditorSupport.stop_zone_flash(_fe_flash_state)
			_fe_overlay.queue_free()
			_fe_overlay = null
			return
		queue_free()


func _make_blank_entry(entry_id: String, label: String) -> Dictionary:
	return {
		"id": entry_id,
		"label": label,
		"tags": [],
		"featured_union": "",
		"featured_unit": "",
		"deck": {
			"deck_name": label,
			"characters": [],
			"traps": [],
			"techs": [],
			"formations": [{"name": "Default Formation", "placements": []}],
		},
	}


func _sync_current_entry() -> void:
	if _selected_idx < 0 or _selected_idx >= _entries.size():
		return
	var entry: Dictionary = _entries[_selected_idx] as Dictionary
	entry["id"] = _entry_id_edit.text.strip_edges() if _entry_id_edit else str(entry.get("id", ""))
	entry["label"] = _entry_label_edit.text.strip_edges() if _entry_label_edit else str(entry.get("label", ""))
	entry["tags"] = _tags.duplicate()
	entry["featured_union"] = _featured_union.strip_edges()
	entry["featured_unit"] = _featured_unit.strip_edges()
	entry["deck"] = _deck.to_dict()
	_entries[_selected_idx] = entry


func _save_vault() -> void:
	_sync_current_entry()
	if not AIDeckVault.save_entries(_entries):
		_set_status("ERROR: cannot write ai_deck_vault.json")
		return
	_refresh_vault_list()
	_set_status("AI Deck Vault saved (%d entries)." % _entries.size())


func _select_entry(idx: int) -> void:
	if idx < 0 or idx >= _entries.size():
		return
	if _selected_idx >= 0:
		_sync_current_entry()
	_selected_idx = idx
	var entry: Dictionary = _entries[idx] as Dictionary
	if _entry_id_edit:
		_entry_id_edit.text = str(entry.get("id", ""))
	if _entry_label_edit:
		_entry_label_edit.text = str(entry.get("label", ""))
	var raw_tags: Variant = entry.get("tags", [])
	_tags = (raw_tags as Array).duplicate() if raw_tags is Array else []
	_refresh_tags_list()
	_featured_union = str(entry.get("featured_union", "")).strip_edges()
	_featured_unit = str(entry.get("featured_unit", "")).strip_edges()
	_refresh_featured_union_options()
	_refresh_featured_unit_options()
	var deck_raw: Variant = entry.get("deck", {})
	if deck_raw is Dictionary:
		_deck.load_from_dict(deck_raw as Dictionary)
	else:
		_deck = DeckData.new()
	_refresh_deck_ui()
	if _vault_list:
		_vault_list.select(idx)


func _refresh_vault_list() -> void:
	if _vault_list == null:
		return
	var keep_idx := _selected_idx
	_vault_list.clear()
	for e: Variant in _entries:
		if e is Dictionary:
			var ed: Dictionary = e as Dictionary
			var line := "%s\n  %s" % [str(ed.get("label", "?")), str(ed.get("id", ""))]
			var raw_tags: Variant = ed.get("tags", [])
			if raw_tags is Array and not (raw_tags as Array).is_empty():
				var tag_bits: PackedStringArray = []
				for t: Variant in (raw_tags as Array):
					var ts := str(t).strip_edges()
					if not ts.is_empty():
						tag_bits.append(ts)
				if not tag_bits.is_empty():
					line += "\n  [%s]" % ", ".join(tag_bits)
			var fu := str(ed.get("featured_union", "")).strip_edges()
			if not fu.is_empty():
				line += "\n  ★ %s" % fu
			var fcu := str(ed.get("featured_unit", "")).strip_edges()
			if not fcu.is_empty():
				line += "\n  ◆ %s" % fcu
			_vault_list.add_item(line)
	if keep_idx >= 0 and keep_idx < _vault_list.item_count:
		_vault_list.select(keep_idx)


func _refresh_deck_ui() -> void:
	if _deck_name_edit:
		_deck_name_edit.text = _deck.deck_name
	_refresh_card_list(_char_list, _deck.characters)
	_refresh_card_list(_trap_list, _deck.traps)
	_refresh_card_list(_tech_list, _deck.techs)
	_refresh_union_list()
	_refresh_featured_union_options()
	_refresh_featured_unit_options()
	if _form_lbl:
		_form_lbl.text = "Formations: %d / %d" % [_deck.formations.size(), MAX_FORMATIONS]


func _refresh_card_list(list: ItemList, card_array: Array) -> void:
	if list == null:
		return
	list.clear()
	for n: String in card_array:
		list.add_item(n)


func _refresh_tags_list() -> void:
	if _tags_list == null:
		return
	_tags_list.clear()
	for t: Variant in _tags:
		var tag := str(t).strip_edges()
		if not tag.is_empty():
			_tags_list.add_item(tag)


func _add_tag() -> void:
	if _tag_input == null:
		return
	var tag := _tag_input.text.strip_edges()
	_tag_input.clear()
	if tag.is_empty():
		return
	if _tags.size() >= MAX_TAGS:
		_set_status("Max %d tags per deck." % MAX_TAGS)
		return
	for existing: Variant in _tags:
		if str(existing).strip_edges().to_lower() == tag.to_lower():
			_set_status("Tag already exists: %s" % tag)
			return
	_tags.append(tag)
	_refresh_tags_list()
	_sync_current_entry()
	_refresh_vault_list()
	_set_status("Added tag: %s" % tag)


func _remove_tag() -> void:
	if _tags_list == null:
		return
	var sel: PackedInt32Array = _tags_list.get_selected_items()
	if sel.is_empty():
		_set_status("Select a tag to remove.")
		return
	var idx: int = sel[0]
	if idx < 0 or idx >= _tags.size():
		return
	var removed: String = str(_tags[idx])
	_tags.remove_at(idx)
	_refresh_tags_list()
	_sync_current_entry()
	_refresh_vault_list()
	_set_status("Removed tag: %s" % removed)


func _refresh_featured_union_options() -> void:
	if _featured_union_option == null:
		return
	_featured_union_block_sync = true
	_featured_union_option.clear()
	_featured_union_option.add_item("(none)")
	var achievable: Array = AdminDeckEditorSupport.achievable_demo_unions(
		_deck.characters if _deck != null else [])
	var achievable_names: Dictionary = {}
	for u: Variant in achievable:
		if u is UnionData:
			var ud: UnionData = u as UnionData
			achievable_names[ud.card_name] = true
			_featured_union_option.add_item(ud.card_name)
	var select_idx := 0
	if not _featured_union.is_empty():
		if achievable_names.has(_featured_union):
			for i: int in range(_featured_union_option.item_count):
				if _featured_union_option.get_item_text(i) == _featured_union:
					select_idx = i
					break
		else:
			_featured_union_option.add_item("%s (not achievable)" % _featured_union)
			select_idx = _featured_union_option.item_count - 1
	_featured_union_option.select(select_idx)
	_featured_union_block_sync = false


func _on_featured_union_selected(idx: int) -> void:
	if _featured_union_block_sync or _featured_union_option == null:
		return
	if idx <= 0:
		_featured_union = ""
	else:
		var label := _featured_union_option.get_item_text(idx)
		if label.ends_with(" (not achievable)"):
			_featured_union = label.trim_suffix(" (not achievable)")
		else:
			_featured_union = label
	_sync_current_entry()
	_refresh_vault_list()
	if _featured_union.is_empty():
		_set_status("Featured union cleared.")
	else:
		_set_status("Featured union: %s" % _featured_union)


func _refresh_featured_unit_options() -> void:
	if _featured_unit_option == null:
		return
	_featured_unit_block_sync = true
	_featured_unit_option.clear()
	_featured_unit_option.add_item("(none)")
	var deck_chars: Array = _deck.characters if _deck != null else []
	var in_deck: Dictionary = {}
	for cname: Variant in deck_chars:
		var name: String = str(cname).strip_edges()
		if name.is_empty():
			continue
		in_deck[name] = true
		_featured_unit_option.add_item(name)
	var select_idx := 0
	if not _featured_unit.is_empty():
		if in_deck.has(_featured_unit):
			for i: int in range(_featured_unit_option.item_count):
				if _featured_unit_option.get_item_text(i) == _featured_unit:
					select_idx = i
					break
		else:
			_featured_unit_option.add_item("%s (not in deck)" % _featured_unit)
			select_idx = _featured_unit_option.item_count - 1
	_featured_unit_option.select(select_idx)
	_featured_unit_block_sync = false


func _on_featured_unit_selected(idx: int) -> void:
	if _featured_unit_block_sync or _featured_unit_option == null:
		return
	if idx <= 0:
		_featured_unit = ""
	else:
		var label := _featured_unit_option.get_item_text(idx)
		if label.ends_with(" (not in deck)"):
			_featured_unit = label.trim_suffix(" (not in deck)")
		else:
			_featured_unit = label
	_sync_current_entry()
	_refresh_vault_list()
	if _featured_unit.is_empty():
		_set_status("Featured unit cleared.")
	else:
		_set_status("Featured unit: %s" % _featured_unit)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.12, 0.97)
	add_child(bg)

	var top := Panel.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 48.0
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.10, 0.10, 0.15)
	top.add_theme_stylebox_override("panel", tsb)
	add_child(top)

	var title := Label.new()
	title.text = "AI Deck Vault"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_top = 10.0
	title.offset_bottom = 42.0
	title.offset_left = -160.0
	title.offset_right = 160.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CHIVO_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	top.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕ CLOSE"
	close_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	close_btn.offset_left = 10.0
	close_btn.offset_top = 8.0
	close_btn.offset_right = 120.0
	close_btn.offset_bottom = 40.0
	close_btn.add_theme_font_override("font", FontManager.make_font("primary", 400))
	close_btn.pressed.connect(func() -> void: queue_free())
	top.add_child(close_btn)

	var save_btn := Button.new()
	save_btn.text = "💾 SAVE"
	save_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	save_btn.offset_left = -130.0
	save_btn.offset_top = 8.0
	save_btn.offset_right = -10.0
	save_btn.offset_bottom = 40.0
	save_btn.add_theme_font_override("font", CHIVO_FONT)
	save_btn.pressed.connect(_save_vault)
	top.add_child(save_btn)

	_status_lbl = Label.new()
	_status_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_status_lbl.offset_top = -26.0
	_status_lbl.offset_bottom = 0.0
	_status_lbl.offset_left = 8.0
	_status_lbl.add_theme_font_override("font", CHIVO_FONT)
	_status_lbl.add_theme_font_size_override("font_size", 12)
	_status_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	add_child(_status_lbl)

	var body := HBoxContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_top = 52.0
	body.offset_bottom = -30.0
	body.offset_left = 8.0
	body.offset_right = -8.0
	body.add_theme_constant_override("separation", 8)
	add_child(body)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(220, 0)
	left.add_theme_constant_override("separation", 4)
	body.add_child(left)

	var vault_hdr := Label.new()
	vault_hdr.text = "Vault Entries"
	vault_hdr.add_theme_font_override("font", CHIVO_FONT)
	vault_hdr.add_theme_font_size_override("font_size", 13)
	vault_hdr.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	left.add_child(vault_hdr)

	_vault_list = ItemList.new()
	_vault_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vault_list.add_theme_font_override("font", CHIVO_FONT)
	_vault_list.add_theme_font_size_override("font_size", 11)
	_vault_list.item_selected.connect(func(idx: int) -> void: _select_entry(idx))
	left.add_child(_vault_list)

	var vault_btns := HBoxContainer.new()
	vault_btns.add_theme_constant_override("separation", 4)
	left.add_child(vault_btns)

	var new_btn := Button.new()
	new_btn.text = "+ New"
	new_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_btn.add_theme_font_override("font", CHIVO_FONT)
	new_btn.pressed.connect(_add_entry)
	vault_btns.add_child(new_btn)

	var dup_btn := Button.new()
	dup_btn.text = "Dup"
	dup_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dup_btn.add_theme_font_override("font", CHIVO_FONT)
	dup_btn.pressed.connect(_duplicate_entry)
	vault_btns.add_child(dup_btn)

	var del_btn := Button.new()
	del_btn.text = "− Del"
	del_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	del_btn.add_theme_font_override("font", CHIVO_FONT)
	del_btn.pressed.connect(_delete_entry)
	vault_btns.add_child(del_btn)

	var id_row := HBoxContainer.new()
	id_row.add_theme_constant_override("separation", 6)
	left.add_child(id_row)
	var id_lbl := Label.new()
	id_lbl.text = "ID:"
	id_lbl.add_theme_font_override("font", CHIVO_FONT)
	id_lbl.add_theme_font_size_override("font_size", 12)
	id_row.add_child(id_lbl)
	_entry_id_edit = LineEdit.new()
	_entry_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_id_edit.add_theme_font_override("font", CHIVO_FONT)
	_entry_id_edit.text_changed.connect(func(_t: String) -> void: _sync_current_entry())
	id_row.add_child(_entry_id_edit)

	var label_row := HBoxContainer.new()
	label_row.add_theme_constant_override("separation", 6)
	left.add_child(label_row)
	var label_lbl := Label.new()
	label_lbl.text = "Label:"
	label_lbl.add_theme_font_override("font", CHIVO_FONT)
	label_lbl.add_theme_font_size_override("font_size", 12)
	label_row.add_child(label_lbl)
	_entry_label_edit = LineEdit.new()
	_entry_label_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_label_edit.add_theme_font_override("font", CHIVO_FONT)
	_entry_label_edit.text_changed.connect(func(t: String) -> void:
		_sync_current_entry()
		if _deck_name_edit and _deck_name_edit.text == _deck.deck_name:
			_deck.deck_name = t
			_deck_name_edit.text = t)
	label_row.add_child(_entry_label_edit)

	var tags_hdr := Label.new()
	tags_hdr.text = "Tags  (max %d)" % MAX_TAGS
	tags_hdr.add_theme_font_override("font", CHIVO_FONT)
	tags_hdr.add_theme_font_size_override("font_size", 12)
	tags_hdr.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	left.add_child(tags_hdr)

	_tags_list = ItemList.new()
	_tags_list.custom_minimum_size = Vector2(0, 72)
	_tags_list.add_theme_font_override("font", CHIVO_FONT)
	_tags_list.add_theme_font_size_override("font_size", 11)
	left.add_child(_tags_list)

	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 4)
	left.add_child(tag_row)

	_tag_input = LineEdit.new()
	_tag_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tag_input.placeholder_text = "New tag…"
	_tag_input.add_theme_font_override("font", CHIVO_FONT)
	_tag_input.text_submitted.connect(func(_t: String) -> void: _add_tag())
	tag_row.add_child(_tag_input)

	var tag_add_btn := Button.new()
	tag_add_btn.text = "+"
	tag_add_btn.custom_minimum_size = Vector2(32, 0)
	tag_add_btn.add_theme_font_override("font", CHIVO_FONT)
	tag_add_btn.pressed.connect(_add_tag)
	tag_row.add_child(tag_add_btn)

	var tag_rem_btn := Button.new()
	tag_rem_btn.text = "− Remove tag"
	tag_rem_btn.add_theme_font_override("font", CHIVO_FONT)
	tag_rem_btn.add_theme_font_size_override("font_size", 11)
	tag_rem_btn.pressed.connect(_remove_tag)
	left.add_child(tag_rem_btn)

	var featured_hdr := Label.new()
	featured_hdr.text = "Featured Union"
	featured_hdr.add_theme_font_override("font", CHIVO_FONT)
	featured_hdr.add_theme_font_size_override("font_size", 12)
	featured_hdr.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0))
	left.add_child(featured_hdr)

	var featured_hint := Label.new()
	featured_hint.text = "AI strongly prefers this union when summoning."
	featured_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	featured_hint.add_theme_font_override("font", CHIVO_FONT)
	featured_hint.add_theme_font_size_override("font_size", 10)
	featured_hint.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	left.add_child(featured_hint)

	_featured_union_option = OptionButton.new()
	_featured_union_option.add_theme_font_override("font", CHIVO_FONT)
	_featured_union_option.add_theme_font_size_override("font_size", 11)
	_featured_union_option.item_selected.connect(_on_featured_union_selected)
	left.add_child(_featured_union_option)

	var featured_unit_hdr := Label.new()
	featured_unit_hdr.text = "Featured Unit"
	featured_unit_hdr.add_theme_font_override("font", CHIVO_FONT)
	featured_unit_hdr.add_theme_font_size_override("font_size", 12)
	featured_unit_hdr.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0))
	left.add_child(featured_unit_hdr)

	var featured_unit_hint := Label.new()
	featured_unit_hint.text = "Quick Duel capsule portrait (when no featured union art)."
	featured_unit_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	featured_unit_hint.add_theme_font_override("font", CHIVO_FONT)
	featured_unit_hint.add_theme_font_size_override("font_size", 10)
	featured_unit_hint.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	left.add_child(featured_unit_hint)

	_featured_unit_option = OptionButton.new()
	_featured_unit_option.add_theme_font_override("font", CHIVO_FONT)
	_featured_unit_option.add_theme_font_size_override("font_size", 11)
	_featured_unit_option.item_selected.connect(_on_featured_unit_selected)
	left.add_child(_featured_unit_option)

	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 6)
	body.add_child(main)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	main.add_child(name_row)
	var name_lbl := Label.new()
	name_lbl.text = "Deck Name:"
	name_lbl.add_theme_font_override("font", CHIVO_FONT)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	name_row.add_child(name_lbl)
	_deck_name_edit = LineEdit.new()
	_deck_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_name_edit.add_theme_font_override("font", CHIVO_FONT)
	_deck_name_edit.text_changed.connect(func(t: String) -> void: _deck.deck_name = t)
	name_row.add_child(_deck_name_edit)

	var valid_lbl := Label.new()
	valid_lbl.add_theme_font_override("font", CHIVO_FONT)
	valid_lbl.add_theme_font_size_override("font_size", 11)
	valid_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	valid_lbl.text = "Valid AI deck: %d–%d chars, %d–%d traps, %d tech" % [
		DeckData.MIN_CHARACTERS, DeckData.MAX_CHARACTERS,
		DeckData.MIN_TRAPS, DeckData.MAX_TRAPS, DeckData.TECH_COUNT]
	main.add_child(valid_lbl)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 8)
	main.add_child(cols)

	_char_list = _build_card_column(cols,
		"Characters  [%d–%d]" % [DeckData.MIN_CHARACTERS, DeckData.MAX_CHARACTERS],
		"character")
	_trap_list = _build_card_column(cols,
		"Traps  [%d–%d]" % [DeckData.MIN_TRAPS, DeckData.MAX_TRAPS],
		"trap")
	_tech_list = _build_card_column(cols,
		"Techs  [exactly %d]" % DeckData.TECH_COUNT,
		"tech")
	_build_union_column(cols)

	var form_row := HBoxContainer.new()
	form_row.add_theme_constant_override("separation", 8)
	main.add_child(form_row)

	_form_lbl = Label.new()
	_form_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_form_lbl.add_theme_font_override("font", CHIVO_FONT)
	_form_lbl.add_theme_font_size_override("font_size", 12)
	_form_lbl.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	form_row.add_child(_form_lbl)

	var fe_btn := Button.new()
	fe_btn.text = "📋 Edit Formations"
	fe_btn.add_theme_font_override("font", CHIVO_FONT)
	fe_btn.add_theme_font_size_override("font_size", 12)
	fe_btn.pressed.connect(_open_formation_editor)
	form_row.add_child(fe_btn)

	_refresh_vault_list()


func _add_entry() -> void:
	_sync_current_entry()
	var n := _entries.size() + 1
	var entry := _make_blank_entry("new_ai_deck_%d" % n, "New AI Deck %d" % n)
	_entries.append(entry)
	_refresh_vault_list()
	_select_entry(_entries.size() - 1)
	_set_status("Added entry: %s" % entry["id"])


func _duplicate_entry() -> void:
	if _selected_idx < 0:
		return
	_sync_current_entry()
	var src: Dictionary = (_entries[_selected_idx] as Dictionary).duplicate(true)
	var base_id: String = str(src.get("id", "deck"))
	src["id"] = base_id + "_copy"
	src["label"] = str(src.get("label", "Deck")) + " (copy)"
	src["featured_union"] = str(src.get("featured_union", ""))
	src["featured_unit"] = str(src.get("featured_unit", ""))
	_entries.append(src)
	_refresh_vault_list()
	_select_entry(_entries.size() - 1)
	_set_status("Duplicated entry.")


func _delete_entry() -> void:
	if _entries.size() <= 1:
		_set_status("Cannot delete the last vault entry.")
		return
	if _selected_idx < 0:
		return
	_entries.remove_at(_selected_idx)
	_selected_idx = mini(_selected_idx, _entries.size() - 1)
	_refresh_vault_list()
	_select_entry(_selected_idx)
	_set_status("Entry deleted.")


func _deck_cards_for(card_type: String) -> Array:
	match card_type:
		"character":
			return _deck.characters
		"trap":
			return _deck.traps
		"tech":
			return _deck.techs
	return []


func _build_card_column(parent: Control, header: String, card_type: String) -> ItemList:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	parent.add_child(col)

	var hdr := Label.new()
	hdr.text = header
	hdr.add_theme_font_override("font", CHIVO_FONT)
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	col.add_child(hdr)

	var list := ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_override("font", CHIVO_FONT)
	list.add_theme_font_size_override("font_size", 12)
	col.add_child(list)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 4)
	col.add_child(btns)

	var add_btn := Button.new()
	add_btn.text = "+ Add"
	add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_btn.add_theme_font_override("font", CHIVO_FONT)
	add_btn.add_theme_font_size_override("font_size", 12)
	add_btn.pressed.connect(func() -> void: _show_add_dialog(list, card_type))
	btns.add_child(add_btn)

	var rem_btn := Button.new()
	rem_btn.text = "− Remove"
	rem_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rem_btn.add_theme_font_override("font", CHIVO_FONT)
	rem_btn.add_theme_font_size_override("font_size", 12)
	rem_btn.pressed.connect(func() -> void: _remove_selected(list, card_type))
	btns.add_child(rem_btn)

	return list


func _build_union_column(parent: Control) -> void:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	parent.add_child(col)

	_union_hdr = Label.new()
	_union_hdr.text = "Unions  [demo, achievable]"
	_union_hdr.add_theme_font_override("font", CHIVO_FONT)
	_union_hdr.add_theme_font_size_override("font_size", 13)
	_union_hdr.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0))
	col.add_child(_union_hdr)

	_union_list = ItemList.new()
	_union_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_union_list.add_theme_font_override("font", CHIVO_FONT)
	_union_list.add_theme_font_size_override("font_size", 12)
	col.add_child(_union_list)

	var add_btn := Button.new()
	add_btn.text = "+ Add"
	add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_btn.add_theme_font_override("font", CHIVO_FONT)
	add_btn.add_theme_font_size_override("font_size", 12)
	add_btn.pressed.connect(_show_union_add_dialog)
	col.add_child(add_btn)


func _refresh_union_list() -> void:
	if _union_list == null or _deck == null:
		return
	var achievable: Array = AdminDeckEditorSupport.achievable_demo_unions(_deck.characters)
	_union_list.clear()
	for u: UnionData in achievable:
		_union_list.add_item(u.card_name)
	if _union_hdr:
		_union_hdr.text = "Unions  [demo, %d achievable]" % achievable.size()


func _show_union_add_dialog() -> void:
	AdminDeckEditorSupport.show_union_add_dialog(self, _deck, CHIVO_FONT, func(res: Dictionary) -> void:
		if bool(res.get("ok", false)):
			_refresh_deck_ui()
		var msg: String = str(res.get("message", ""))
		if not msg.is_empty():
			_set_status(msg), true)


func _open_formation_editor() -> void:
	if _fe_overlay != null and is_instance_valid(_fe_overlay):
		return
	_sync_current_entry()

	_fe_overlay = Control.new()
	_fe_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fe_overlay.z_index = 50
	_fe_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.10, 0.98)
	_fe_overlay.add_child(bg)

	var top := Panel.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 44.0
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.10, 0.10, 0.18)
	top.add_theme_stylebox_override("panel", tsb)
	_fe_overlay.add_child(top)

	var ttl := Label.new()
	ttl.text = "Formation Editor"
	ttl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ttl.offset_top = 8.0
	ttl.offset_bottom = 40.0
	ttl.offset_left = -180.0
	ttl.offset_right = 180.0
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", CHIVO_FONT)
	ttl.add_theme_font_size_override("font_size", 18)
	ttl.add_theme_color_override("font_color", Color(1, 1, 1))
	top.add_child(ttl)

	var close_fe := Button.new()
	close_fe.text = "✕ DONE"
	close_fe.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_fe.offset_left = -130.0
	close_fe.offset_top = 6.0
	close_fe.offset_right = -10.0
	close_fe.offset_bottom = 38.0
	close_fe.add_theme_font_override("font", FontManager.make_font("primary", 400))
	close_fe.pressed.connect(func() -> void:
		AdminDeckEditorSupport.stop_zone_flash(_fe_flash_state)
		_sync_current_entry()
		if _form_lbl:
			_form_lbl.text = "Formations: %d / %d" % [_deck.formations.size(), MAX_FORMATIONS]
		_fe_overlay.queue_free()
		_fe_overlay = null)
	top.add_child(close_fe)

	var fe_body := HBoxContainer.new()
	fe_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	fe_body.offset_top = 48.0
	fe_body.offset_left = 4.0
	fe_body.offset_right = -4.0
	fe_body.add_theme_constant_override("separation", 6)
	_fe_overlay.add_child(fe_body)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(180, 0)
	left.add_theme_constant_override("separation", 4)
	fe_body.add_child(left)

	var ll := Label.new()
	ll.text = "Formations  (max %d)" % MAX_FORMATIONS
	ll.add_theme_font_override("font", CHIVO_FONT)
	ll.add_theme_font_size_override("font_size", 12)
	ll.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	left.add_child(ll)

	_fe_list = ItemList.new()
	_fe_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fe_list.add_theme_font_override("font", CHIVO_FONT)
	_fe_list.add_theme_font_size_override("font_size", 12)
	left.add_child(_fe_list)
	for f: Variant in _deck.formations:
		var fd: Dictionary = f as Dictionary
		_fe_list.add_item(str(fd.get("name", "Formation")))
	_fe_list.item_selected.connect(_fe_on_select)

	var lbtns := HBoxContainer.new()
	lbtns.add_theme_constant_override("separation", 4)
	left.add_child(lbtns)

	var add_f := Button.new()
	add_f.text = "+ New"
	add_f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_f.add_theme_font_override("font", CHIVO_FONT)
	add_f.pressed.connect(_fe_add_formation)
	lbtns.add_child(add_f)

	var del_f := Button.new()
	del_f.text = "− Del"
	del_f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	del_f.add_theme_font_override("font", CHIVO_FONT)
	del_f.pressed.connect(_fe_delete_formation)
	lbtns.add_child(del_f)

	var centre := VBoxContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.add_theme_constant_override("separation", 6)
	fe_body.add_child(centre)

	var top_space := Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centre.add_child(top_space)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	centre.add_child(name_row)

	var nl := Label.new()
	nl.text = "Name:"
	nl.add_theme_font_override("font", CHIVO_FONT)
	nl.add_theme_font_size_override("font_size", 12)
	name_row.add_child(nl)

	_fe_name_edit = LineEdit.new()
	_fe_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fe_name_edit.placeholder_text = "Formation name"
	_fe_name_edit.editable = false
	_fe_name_edit.add_theme_font_override("font", CHIVO_FONT)
	_fe_name_edit.text_changed.connect(_fe_on_name_changed)
	name_row.add_child(_fe_name_edit)

	var save_f := Button.new()
	save_f.text = "💾 Save"
	save_f.add_theme_font_override("font", CHIVO_FONT)
	save_f.pressed.connect(func() -> void:
		_sync_current_entry()
		_set_status("Formation saved."))
	name_row.add_child(save_f)

	var grid := GridContainer.new()
	grid.columns = GRID_COLS
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	centre.add_child(grid)

	_fe_grid_cells.clear()
	for r: int in range(GRID_ROWS):
		for c: int in range(GRID_COLS):
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			cell.clip_text = true
			cell.add_theme_font_override("font", CHIVO_FONT)
			cell.add_theme_font_size_override("font_size", 9)
			var ri: int = r
			var ci: int = c
			cell.pressed.connect(func() -> void: _fe_place_card(ri, ci))
			cell.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton:
					var mb: InputEventMouseButton = ev as InputEventMouseButton
					if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
						_fe_clear_cell(ri, ci))
			_fe_grid_cells.append(cell)
			grid.add_child(cell)
	AdminDeckEditorSupport.ensure_grid_flash_overlays(_fe_grid_cells)

	var bottom_space := Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centre.add_child(bottom_space)

	var hint_lbl := Label.new()
	hint_lbl.text = "Left-click: place selected card    Right-click: clear cell"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_override("font", CHIVO_FONT)
	hint_lbl.add_theme_font_size_override("font_size", 10)
	hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	centre.add_child(hint_lbl)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(180, 0)
	right.add_theme_constant_override("separation", 4)
	fe_body.add_child(right)

	var rl := Label.new()
	rl.text = "Cards (deck)"
	rl.add_theme_font_override("font", CHIVO_FONT)
	rl.add_theme_font_size_override("font_size", 12)
	rl.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	right.add_child(rl)

	_fe_pick_list = ItemList.new()
	_fe_pick_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fe_pick_list.add_theme_font_override("font", CHIVO_FONT)
	_fe_pick_list.add_theme_font_size_override("font_size", 11)
	right.add_child(_fe_pick_list)
	_fe_refresh_pick_list()
	_fe_pick_list.item_selected.connect(func(idx: int) -> void:
		_fe_card_pick = _fe_pick_list.get_item_text(idx))

	var clear_pick := Button.new()
	clear_pick.text = "✕ Deselect"
	clear_pick.add_theme_font_override("font", FontManager.make_font("primary", 400))
	clear_pick.pressed.connect(func() -> void:
		_fe_card_pick = ""
		_fe_pick_list.deselect_all())
	right.add_child(clear_pick)

	var pu_hdr := Label.new()
	pu_hdr.text = "Possible Unions  [demo]  —  tap to highlight zone"
	pu_hdr.add_theme_font_override("font", CHIVO_FONT)
	pu_hdr.add_theme_font_size_override("font_size", 11)
	pu_hdr.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0))
	right.add_child(pu_hdr)

	_fe_possible_union_list = ItemList.new()
	_fe_possible_union_list.custom_minimum_size = Vector2(0, 120)
	_fe_possible_union_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fe_possible_union_list.add_theme_font_override("font", CHIVO_FONT)
	_fe_possible_union_list.add_theme_font_size_override("font_size", 11)
	_fe_possible_union_list.item_selected.connect(_fe_on_possible_union_selected)
	right.add_child(_fe_possible_union_list)

	add_child(_fe_overlay)
	_fe_selected = -1
	_fe_flash_state = {}
	_fe_refresh_possible_unions()
	_fe_refresh_grid()


func _fe_refresh_pick_list() -> void:
	if _fe_pick_list == null:
		return
	_fe_pick_list.clear()
	var seen: Dictionary = {}
	for n: String in _deck.characters:
		if not seen.has(n):
			seen[n] = true
			_fe_pick_list.add_item(n)
	for n: String in _deck.traps:
		if not seen.has(n):
			seen[n] = true
			_fe_pick_list.add_item(n)


func _fe_on_select(idx: int) -> void:
	AdminDeckEditorSupport.stop_zone_flash(_fe_flash_state)
	_fe_selected = idx
	if idx < 0 or idx >= _deck.formations.size():
		return
	var fd: Dictionary = _deck.formations[idx] as Dictionary
	if _fe_name_edit:
		_fe_name_edit.editable = true
		_fe_name_edit.text = str(fd.get("name", "Formation"))
	_fe_refresh_grid()
	_fe_refresh_possible_unions()


func _fe_refresh_possible_unions() -> void:
	if _fe_possible_union_list == null:
		return
	AdminDeckEditorSupport.refresh_possible_union_list(
		_fe_possible_union_list, _deck, _fe_possible_unions)


func _fe_on_possible_union_selected(idx: int) -> void:
	if idx < 0 or idx >= _fe_possible_unions.size():
		return
	var u: UnionData = _fe_possible_unions[idx] as UnionData
	AdminDeckEditorSupport.start_zone_flash(
		_fe_flash_state, _fe_grid_cells, GRID_COLS, u, _fe_overlay)


func _fe_refresh_grid() -> void:
	var placed: Dictionary = {}
	if _fe_selected >= 0 and _fe_selected < _deck.formations.size():
		var fd: Dictionary = _deck.formations[_fe_selected] as Dictionary
		var pl: Variant = fd.get("placements", [])
		if pl is Array:
			for p: Variant in (pl as Array):
				if p is Dictionary:
					var pd: Dictionary = p as Dictionary
					var key: String = "%d,%d" % [int(pd.get("r", -1)), int(pd.get("c", -1))]
					placed[key] = str(pd.get("name", ""))

	for r: int in range(GRID_ROWS):
		for c: int in range(GRID_COLS):
			var cell: Button = _fe_grid_cells[r * GRID_COLS + c] as Button
			var key: String = "%d,%d" % [r, c]
			if placed.has(key):
				cell.text = placed[key]
				cell.modulate = Color(0.7, 1.0, 0.7)
			else:
				cell.text = ""
				cell.modulate = Color(1, 1, 1)


func _fe_place_card(r: int, c: int) -> void:
	if _fe_selected < 0 or _fe_card_pick == "":
		return
	var fd: Dictionary = _deck.formations[_fe_selected] as Dictionary
	var pl: Variant = fd.get("placements", [])
	var placements: Array = pl as Array if pl is Array else []
	for i: int in range(placements.size() - 1, -1, -1):
		var p: Variant = placements[i]
		if p is Dictionary:
			var pd: Dictionary = p as Dictionary
			if int(pd.get("r", -1)) == r and int(pd.get("c", -1)) == c:
				placements.remove_at(i)
	var ctype: String = "character"
	if _fe_card_pick in _deck.traps:
		ctype = "trap"
	placements.append({"r": r, "c": c, "name": _fe_card_pick, "type": ctype})
	fd["placements"] = placements
	_deck.formations[_fe_selected] = fd
	_fe_refresh_grid()
	_fe_refresh_possible_unions()


func _fe_clear_cell(r: int, c: int) -> void:
	if _fe_selected < 0:
		return
	var fd: Dictionary = _deck.formations[_fe_selected] as Dictionary
	var pl: Variant = fd.get("placements", [])
	if not pl is Array:
		return
	var placements: Array = pl as Array
	for i: int in range(placements.size() - 1, -1, -1):
		var p: Variant = placements[i]
		if p is Dictionary:
			var pd: Dictionary = p as Dictionary
			if int(pd.get("r", -1)) == r and int(pd.get("c", -1)) == c:
				placements.remove_at(i)
	fd["placements"] = placements
	_deck.formations[_fe_selected] = fd
	_fe_refresh_grid()
	_fe_refresh_possible_unions()


func _fe_on_name_changed(new_name: String) -> void:
	if _fe_selected < 0 or _fe_selected >= _deck.formations.size():
		return
	var fd: Dictionary = _deck.formations[_fe_selected] as Dictionary
	fd["name"] = new_name
	_deck.formations[_fe_selected] = fd
	if _fe_list:
		_fe_list.set_item_text(_fe_selected, new_name)


func _fe_add_formation() -> void:
	if _deck.formations.size() >= MAX_FORMATIONS:
		_set_status("Max %d formations reached." % MAX_FORMATIONS)
		return
	var idx: int = _deck.formations.size()
	_deck.formations.append({"name": "Formation %d" % (idx + 1), "placements": []})
	if _fe_list:
		_fe_list.add_item("Formation %d" % (idx + 1))
		_fe_list.select(idx)
		_fe_on_select(idx)


func _fe_delete_formation() -> void:
	if _fe_selected < 0 or _fe_selected >= _deck.formations.size():
		return
	_deck.formations.remove_at(_fe_selected)
	if _fe_list:
		_fe_list.remove_item(_fe_selected)
	_fe_selected = -1
	if _fe_name_edit:
		_fe_name_edit.text = ""
		_fe_name_edit.editable = false
	_fe_refresh_grid()


func _show_add_dialog(_target_list: ItemList, card_type: String) -> void:
	AdminDeckEditorSupport.show_add_card_dialog(self, card_type, CHIVO_FONT, func(chosen: String) -> void:
		_deck_cards_for(card_type).append(chosen)
		_sync_current_entry()
		_refresh_deck_ui()
		_set_status("Added: %s" % chosen), true)


func _remove_selected(list: ItemList, card_type: String) -> void:
	var card_array := _deck_cards_for(card_type)
	var sel: PackedInt32Array = list.get_selected_items()
	if sel.is_empty():
		return
	var idx: int = sel[0]
	if idx < 0 or idx >= card_array.size():
		return
	var removed: String = list.get_item_text(idx)
	card_array.remove_at(idx)
	list.remove_item(idx)
	_sync_current_entry()
	_refresh_deck_ui()
	_set_status("Removed: %s" % removed)


func _set_status(msg: String) -> void:
	if _status_lbl:
		_status_lbl.text = msg
