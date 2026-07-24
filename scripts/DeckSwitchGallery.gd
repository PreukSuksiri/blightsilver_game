extends Node
class_name DeckSwitchGallery
## Switch Deck gallery — GameDialog-skinned content overlay.

signal deck_selected(index: int)
signal request_new()
signal decks_changed()

const DeckData = preload("res://resources/DeckData.gd")
const FACEDOWN := preload("res://assets/textures/cards/frames/facedown_frame_medium.png")
const OVERLAY_NAME := &"DeckSwitchGallery"
const EYES_PATH := "res://assets/textures/profile/eyes/eyes_%s.png"
## Check order only — display whoever equips this deck (Nex need not be first).
const EQUIP_EYE_IDS: Array[String] = ["nex", "mayu", "kelly"]
const EYE_STRIP_SIZE := Vector2(72, 28)
const _METAL_SHEEN_SHADER: Shader = preload("res://assets/shaders/magitech_metal_reflect.gdshader")
const _SHEEN_IDLE := 2.0
const _SHEEN_DURATION := 0.42

static var _locked_hatch_tex: Texture2D = null

var _root: Control = null
var _grid: GridContainer = null
var _dialog_parent: Node = null
var _drag_ghost: Control = null
var _drag_ghost_active: bool = false
var _tile_sheen_tweens: Dictionary = {}  # wrap instance_id -> Tween


static func open(parent: Node) -> Node:
	if parent == null:
		return null
	if GameDialog.has_open_overlay(parent, OVERLAY_NAME):
		return null
	var host := DeckSwitchGallery.new()
	parent.add_child(host)
	host._build(parent)
	return host


func _build(parent: Node) -> void:
	_dialog_parent = parent
	# 4×3 tiles (200×180) + gaps — size panel to fit without scrolling.
	const TILE_W := 200.0
	const TILE_H := 180.0
	const GAP := 12.0
	var grid_w: float = TILE_W * 4.0 + GAP * 3.0
	var grid_h: float = TILE_H * 3.0 + GAP * 2.0
	var shell: Dictionary = GameDialog.content_overlay(
		parent, grid_w + 48.0, 0.0, GameDialog.DEFAULT_Z_INDEX, OVERLAY_NAME)
	_root = shell["root"] as Control
	var vbox: VBoxContainer = shell["vbox"] as VBoxContainer
	var panel: PanelContainer = shell["panel"] as PanelContainer
	# Header + gaps + grid; let content dictate height (no ScrollContainer).
	panel.custom_minimum_size = Vector2(grid_w + 48.0, grid_h + 90.0)
	_root.tree_exiting.connect(func() -> void:
		if is_instance_valid(self) and not is_queued_for_deletion():
			queue_free())

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "Switch Deck"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameDialog.style_title_label(title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_child(title)

	var new_btn := Button.new()
	new_btn.text = "New"
	GameDialog.style_button(new_btn)
	new_btn.custom_minimum_size = Vector2(100, GameDialog.BTN_MIN_SIZE.y)
	new_btn.pressed.connect(func() -> void:
		request_new.emit()
		_close())
	header.add_child(new_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	GameDialog.style_button(close_btn)
	close_btn.custom_minimum_size = Vector2(100, GameDialog.BTN_MIN_SIZE.y)
	close_btn.pressed.connect(_close)
	header.add_child(close_btn)

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", int(GAP))
	_grid.add_theme_constant_override("v_separation", int(GAP))
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.custom_minimum_size = Vector2(grid_w, grid_h)
	vbox.add_child(_grid)

	SaveManager.ensure_gallery_slots()
	rebuild()


func _close() -> void:
	_hide_drag_ghost()
	if _root != null and is_instance_valid(_root):
		_root.queue_free()
	elif is_instance_valid(self):
		queue_free()


func rebuild() -> void:
	if _grid == null:
		return
	_hide_drag_ghost()
	for id: Variant in _tile_sheen_tweens.keys():
		var old: Variant = _tile_sheen_tweens[id]
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	_tile_sheen_tweens.clear()
	for c in _grid.get_children():
		c.queue_free()
	for slot in range(SaveManager.MAX_FREE_DECK_SLOTS):
		var deck: DeckData = SaveManager.get_free_deck_at_gallery_slot(slot)
		var deck_index: int = SaveManager.find_deck_index_at_gallery_slot(slot)
		if deck != null and deck_index >= 0:
			_grid.add_child(_make_tile(deck, deck_index, slot))
		else:
			_grid.add_child(_make_empty_slot(slot))
	_grid.add_child(_make_locked_slot())
	_grid.add_child(_make_locked_slot())


func _make_locked_slot() -> Control:
	var locked := Control.new()
	locked.custom_minimum_size = Vector2(200, 180)
	locked.mouse_filter = Control.MOUSE_FILTER_STOP
	locked.clip_contents = true

	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", _slot_panel_style(Color(0.06, 0.08, 0.14, 0.9)))
	locked.add_child(bg)

	# Subtle diagonal hatch (tiled).
	var hatch := TextureRect.new()
	hatch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hatch.offset_left = 1.0
	hatch.offset_top = 1.0
	hatch.offset_right = -1.0
	hatch.offset_bottom = -1.0
	hatch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hatch.stretch_mode = TextureRect.STRETCH_TILE
	hatch.texture = _get_locked_hatch_texture()
	hatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	locked.add_child(hatch)

	var lbl := Label.new()
	lbl.text = "Locked"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameDialog.style_body_label(lbl)
	lbl.modulate = Color(0.65, 0.7, 0.78, 1)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	locked.add_child(lbl)
	return locked


func _get_locked_hatch_texture() -> Texture2D:
	if _locked_hatch_tex != null:
		return _locked_hatch_tex
	var size: int = 14
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var line := Color(0.72, 0.84, 1.0, 0.08)
	for y in size:
		for x in size:
			if (x + y) % 7 == 0:
				img.set_pixel(x, y, line)
	_locked_hatch_tex = ImageTexture.create_from_image(img)
	return _locked_hatch_tex


func _make_empty_slot(gallery_slot: int) -> Control:
	var empty := PanelContainer.new()
	empty.custom_minimum_size = Vector2(200, 180)
	empty.mouse_filter = Control.MOUSE_FILTER_STOP
	empty.add_theme_stylebox_override("panel", _slot_panel_style(Color(0.05, 0.07, 0.12, 0.85)))
	var lbl := Label.new()
	lbl.text = "Empty"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameDialog.style_body_label(lbl)
	lbl.modulate = Color(0.55, 0.62, 0.72, 1)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty.add_child(lbl)
	var to_slot: int = gallery_slot
	empty.set_drag_forwarding(
		Callable(),
		func(_p: Vector2, data: Variant) -> bool:
			return _is_deck_drag(data),
		func(_p: Vector2, data: Variant) -> void:
			_drop_deck(data, to_slot))
	return empty


func _slot_panel_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = GameDialog.PANEL_BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	return sb


func _make_tile(deck: DeckData, index: int, gallery_slot: int) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(200, 180)
	wrap.clip_contents = true
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP

	var is_selected: bool = index == SaveManager.active_deck_index
	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_selected:
		_skin_selected_deck_frame(frame)
	else:
		frame.add_theme_stylebox_override("panel", _slot_panel_style(Color(0.04, 0.06, 0.13, 0.97)))
	wrap.add_child(frame)

	# Equipped-character eyes (below delete); behind card art (lower z).
	var eyes_col := _make_equipped_eyes_column(deck)
	if eyes_col != null:
		wrap.add_child(eyes_col)

	var stack := Control.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.z_index = 1
	wrap.add_child(stack)
	var stack_cards: Array = []
	for i in range(3):
		var back := TextureRect.new()
		back.texture = FACEDOWN
		back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		back.position = Vector2(18 + i * 4, 28 + i * 3)
		back.size = Vector2(90, 124)
		back.rotation_degrees = -6.0 + i * 2.0
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_attach_card_metal_sheen(back)
		stack.add_child(back)
		stack_cards.append(back)
	var featured_name: String = deck.resolve_featured_preview_name()
	var face := TextureRect.new()
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.position = Vector2(70, 20)
	face.size = Vector2(100, 137)
	face.rotation_degrees = 8.0
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = _load_card_tex(featured_name)
	face.texture = tex if tex != null else FACEDOWN
	_attach_card_metal_sheen(face)
	stack.add_child(face)
	stack_cards.append(face)
	_wire_tile_stack_sheen(wrap, stack, stack_cards)

	var name_lbl := Label.new()
	name_lbl.text = deck.deck_name
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = -28
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", GameDialog.BODY_COLOR)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.z_index = 2
	wrap.add_child(name_lbl)

	# Top-right icon-only copy / delete, stacked (always confirm).
	var icon_col := VBoxContainer.new()
	icon_col.layout_mode = 1
	icon_col.anchor_left = 1.0
	icon_col.anchor_right = 1.0
	icon_col.anchor_top = 0.0
	icon_col.anchor_bottom = 0.0
	icon_col.offset_left = -40.0
	icon_col.offset_top = 4.0
	icon_col.offset_right = -4.0
	icon_col.offset_bottom = 80.0
	icon_col.add_theme_constant_override("separation", 4)
	icon_col.mouse_filter = Control.MOUSE_FILTER_STOP
	icon_col.z_index = 2
	wrap.add_child(icon_col)

	var captured_index: int = index
	var deck_name: String = deck.deck_name
	var copy_btn := _make_blue_icon_btn("duplicate", "Duplicate deck")
	copy_btn.pressed.connect(func() -> void:
		_confirm_duplicate(captured_index, deck_name))
	icon_col.add_child(copy_btn)
	var del_btn := _make_blue_icon_btn("delete", "Delete deck")
	del_btn.pressed.connect(func() -> void:
		_confirm_delete(captured_index, deck_name))
	icon_col.add_child(del_btn)

	var from_slot: int = gallery_slot
	var armed: Array = [false, Vector2.ZERO]  # [armed, press_pos]
	wrap.gui_input.connect(func(ev: InputEvent) -> void:
		if not (ev is InputEventMouseButton):
			return
		var mb := ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			armed[0] = true
			armed[1] = mb.position
			return
		if not bool(armed[0]):
			return
		armed[0] = false
		if mb.position.distance_to(armed[1] as Vector2) > 10.0:
			return
		deck_selected.emit(captured_index)
		_close())
	wrap.set_drag_forwarding(
		func(_pos: Vector2) -> Variant:
			armed[0] = false
			_show_drag_ghost(deck.deck_name, tex)
			# Invisible native preview — visible ghost follows the cursor via _process.
			var preview := Control.new()
			preview.custom_minimum_size = Vector2(1, 1)
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			wrap.set_drag_preview(preview)
			return {"kind": "deck_switch", "from_slot": from_slot},
		func(_p: Vector2, data: Variant) -> bool:
			return _is_deck_drag(data),
		func(_p: Vector2, data: Variant) -> void:
			_drop_deck(data, from_slot))
	return wrap


func _show_drag_ghost(deck_name: String, featured_tex: Texture2D) -> void:
	_hide_drag_ghost()
	var ghost := Control.new()
	ghost.name = "DeckSwitchDragGhost"
	ghost.custom_minimum_size = Vector2(140, 120)
	ghost.size = Vector2(140, 120)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 4096
	ghost.top_level = true
	ghost.modulate = Color(1, 1, 1, 0.88)

	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", _slot_panel_style(Color(0.04, 0.06, 0.13, 0.95)))
	ghost.add_child(bg)

	var face := TextureRect.new()
	face.position = Vector2(20, 8)
	face.size = Vector2(70, 96)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.texture = featured_tex if featured_tex != null else FACEDOWN
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.add_child(face)

	var name_lbl := Label.new()
	name_lbl.text = deck_name
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = -22
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", GameDialog.BODY_COLOR)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.add_child(name_lbl)

	if _root != null and is_instance_valid(_root):
		_root.add_child(ghost)
	else:
		add_child(ghost)
	_drag_ghost = ghost
	_drag_ghost_active = true
	set_process(true)
	_update_drag_ghost_pos()


func _update_drag_ghost_pos() -> void:
	if _drag_ghost == null or not is_instance_valid(_drag_ghost):
		return
	var mp: Vector2 = get_viewport().get_mouse_position()
	_drag_ghost.global_position = mp - _drag_ghost.size * 0.5


func _hide_drag_ghost() -> void:
	_drag_ghost_active = false
	set_process(false)
	if _drag_ghost != null and is_instance_valid(_drag_ghost):
		_drag_ghost.queue_free()
	_drag_ghost = null


func _process(_delta: float) -> void:
	if not _drag_ghost_active:
		return
	_update_drag_ghost_pos()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_hide_drag_ghost()


func _attach_card_metal_sheen(card: TextureRect) -> void:
	if card == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = _METAL_SHEEN_SHADER
	mat.set_shader_parameter("progress", _SHEEN_IDLE)
	mat.set_shader_parameter("intensity", 1.25)
	mat.set_shader_parameter("band_width", 0.22)
	card.material = mat


func _wire_tile_stack_sheen(wrap: Control, stack: Control, cards: Array) -> void:
	if wrap == null or stack == null or cards.is_empty():
		return
	wrap.set_meta("_stack_sheen_cards", cards)
	wrap.set_meta("_stack_sheen_host", stack)
	wrap.mouse_entered.connect(_on_tile_sheen_entered.bind(wrap))
	wrap.mouse_exited.connect(_on_tile_sheen_exited.bind(wrap))


func _on_tile_sheen_entered(wrap: Control) -> void:
	if wrap == null or not is_instance_valid(wrap):
		return
	_play_tile_stack_sheen(wrap)


func _on_tile_sheen_exited(wrap: Control) -> void:
	if wrap == null or not is_instance_valid(wrap):
		return
	# Icon buttons sit above the tile — don't kill sheen when moving onto them.
	await get_tree().process_frame
	if not is_instance_valid(wrap):
		return
	if wrap.get_global_rect().has_point(wrap.get_global_mouse_position()):
		return
	_reset_tile_stack_sheen(wrap)


func _kill_tile_sheen_tween(wrap: Control) -> void:
	if wrap == null or not is_instance_valid(wrap):
		return
	var id: int = wrap.get_instance_id()
	if not _tile_sheen_tweens.has(id):
		return
	var old: Variant = _tile_sheen_tweens[id]
	_tile_sheen_tweens.erase(id)
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()


func _reset_tile_stack_sheen(wrap: Control) -> void:
	_kill_tile_sheen_tween(wrap)
	var cards_v: Variant = wrap.get_meta("_stack_sheen_cards", [])
	if not (cards_v is Array):
		return
	for c: Variant in cards_v as Array:
		var card: TextureRect = c as TextureRect
		if card == null or not is_instance_valid(card):
			continue
		var mat: ShaderMaterial = card.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("progress", _SHEEN_IDLE)


## One shared left→right metal sweep across facedown stack + featured card.
func _play_tile_stack_sheen(wrap: Control) -> void:
	if wrap == null or not is_instance_valid(wrap):
		return
	var cards_v: Variant = wrap.get_meta("_stack_sheen_cards", [])
	var stack: Control = wrap.get_meta("_stack_sheen_host", null) as Control
	if not (cards_v is Array) or stack == null:
		return
	var cards: Array = cards_v as Array
	if cards.is_empty():
		return
	_kill_tile_sheen_tween(wrap)
	var stack_w: float = maxf(stack.size.x, wrap.custom_minimum_size.x)
	if stack_w < 2.0:
		stack_w = 200.0
	var hold: Array = [cards, stack_w]
	var id: int = wrap.get_instance_id()
	var tw := create_tween()
	_tile_sheen_tweens[id] = tw
	tw.tween_method(
		func(p: float) -> void:
			var list: Array = hold[0] as Array
			var w: float = float(hold[1])
			for c: Variant in list:
				var card: TextureRect = c as TextureRect
				if card == null or not is_instance_valid(card):
					continue
				var mat: ShaderMaterial = card.material as ShaderMaterial
				if mat == null:
					continue
				# Map shared stack-space progress into each card's local UV.
				var local_p: float = (p * w - card.position.x) / maxf(card.size.x, 1.0)
				mat.set_shader_parameter("progress", local_p),
		-0.25, 1.35, _SHEEN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		var list: Array = hold[0] as Array
		for c: Variant in list:
			var card: TextureRect = c as TextureRect
			if card == null or not is_instance_valid(card):
				continue
			var mat: ShaderMaterial = card.material as ShaderMaterial
			if mat != null:
				mat.set_shader_parameter("progress", _SHEEN_IDLE)
		_tile_sheen_tweens.erase(id))


## Protagonist ids that currently have `deck` equipped (any order; omit unequipped).
func _equipped_pids_for_deck(deck: DeckData) -> Array[String]:
	var out: Array[String] = []
	if deck == null:
		return out
	var deck_id: String = deck.deck_id.strip_edges()
	if deck_id.is_empty():
		return out
	for pid: String in EQUIP_EYE_IDS:
		var eq: DeckData = SaveManager.get_equipped_deck(pid)
		if eq != null and eq.deck_id == deck_id:
			out.append(pid)
	return out


## Eye strips under the delete button; z below card stack so the featured card overlaps.
func _make_equipped_eyes_column(deck: DeckData) -> VBoxContainer:
	var pids: Array[String] = _equipped_pids_for_deck(deck)
	if pids.is_empty():
		return null
	var eyes_col := VBoxContainer.new()
	eyes_col.layout_mode = 1
	eyes_col.anchor_left = 1.0
	eyes_col.anchor_right = 1.0
	eyes_col.anchor_top = 0.0
	eyes_col.anchor_bottom = 0.0
	# Sit under the two 32px icon buttons (+ separations).
	eyes_col.offset_left = -EYE_STRIP_SIZE.x - 4.0
	eyes_col.offset_top = 76.0
	eyes_col.offset_right = -4.0
	eyes_col.offset_bottom = 76.0 + float(pids.size()) * (EYE_STRIP_SIZE.y + 3.0)
	eyes_col.add_theme_constant_override("separation", 3)
	eyes_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eyes_col.z_index = 0
	for pid: String in pids:
		var eye := TextureRect.new()
		eye.custom_minimum_size = EYE_STRIP_SIZE
		eye.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		eye.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		eye.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var path: String = EYES_PATH % pid
		if ResourceLoader.exists(path):
			eye.texture = load(path) as Texture2D
		eyes_col.add_child(eye)
	return eyes_col


## Magitech blue chrome icon button (duplicate / delete).
func _make_blue_icon_btn(icon_id: String, tip: String) -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.tooltip_text = tip
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(32, 32)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	GameDialog.apply_button_chrome(btn, true)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: StyleBox = btn.get_theme_stylebox(state)
		if sb == null:
			continue
		var dup: StyleBox = sb.duplicate() as StyleBox
		dup.content_margin_left = 4.0
		dup.content_margin_right = 4.0
		dup.content_margin_top = 4.0
		dup.content_margin_bottom = 4.0
		btn.add_theme_stylebox_override(state, dup)
	ChromeIcon.apply_button(btn, icon_id, false, "", ChromeIcon.COLOR_ON_DARK, 18)
	return btn


## Selected deck tile: lighter Magitech fill + circuit patrol border.
func _skin_selected_deck_frame(frame: PanelContainer) -> void:
	if frame == null:
		return
	var sb := GameDialog.make_panel_stylebox(0.0)
	sb.set_corner_radius_all(8)
	frame.add_theme_stylebox_override("panel", sb)
	GameDialog.attach_panel_fx(frame)
	var mat: ShaderMaterial = frame.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("fill_top", Color(0.14, 0.20, 0.34, 0.97))
	mat.set_shader_parameter("fill_bottom", Color(0.07, 0.11, 0.20, 0.97))
	mat.set_shader_parameter("border_a", Color(0.92, 0.97, 1.0, 0.95))
	mat.set_shader_parameter("border_b", Color(0.78, 0.88, 1.0, 0.82))
	mat.set_shader_parameter("border_px", 2.5)
	mat.set_shader_parameter("rim_speed", 0.40)
	mat.set_shader_parameter("rim_pulse", 0.68)
	mat.set_shader_parameter("circuit_patrol", 1.0)


func _confirm_duplicate(index: int, deck_name: String) -> void:
	var parent: Node = _dialog_parent if _dialog_parent != null else self
	if GameDialog.has_open_overlay(parent):
		return
	if not SaveManager.can_create_free_deck():
		GameDialog.accept_overlay(
			parent,
			"Slots Full",
			"Free deck slots are full (max %d)." % SaveManager.MAX_FREE_DECK_SLOTS,
			"OK")
		return
	GameDialog.confirmation_overlay(
		parent,
		"Duplicate Deck",
		"Duplicate \"%s\"?" % deck_name,
		"Duplicate",
		"Cancel",
		func() -> void:
			SaveManager.duplicate_deck(index)
			decks_changed.emit()
			rebuild())


func _confirm_delete(index: int, deck_name: String) -> void:
	var parent: Node = _dialog_parent if _dialog_parent != null else self
	if GameDialog.has_open_overlay(parent):
		return
	if SaveManager.decks.size() <= 1:
		GameDialog.accept_overlay(
			parent,
			"Cannot Delete",
			"Cannot delete the last deck.",
			"OK")
		return
	if index < 0 or index >= SaveManager.decks.size():
		return
	var deck: DeckData = SaveManager.decks[index] as DeckData
	if deck != null and (deck.limited or deck.reserved_slot != 0):
		GameDialog.accept_overlay(
			parent,
			"Cannot Delete",
			"Cannot delete a Limited / reserved protagonist deck.",
			"OK")
		return
	GameDialog.confirmation_overlay(
		parent,
		"Delete Deck",
		"Delete \"%s\"?\n\nThis cannot be undone." % deck_name,
		"Delete",
		"Cancel",
		func() -> void:
			SaveManager.delete_deck(index)
			decks_changed.emit()
			rebuild())


func _is_deck_drag(data: Variant) -> bool:
	return data is Dictionary and str((data as Dictionary).get("kind", "")) == "deck_switch"


func _drop_deck(data: Variant, to_slot: int) -> void:
	_hide_drag_ghost()
	if not _is_deck_drag(data):
		return
	var from_slot: int = int((data as Dictionary).get("from_slot", -1))
	if SaveManager.move_free_deck_gallery_slot(from_slot, to_slot):
		rebuild()


func _load_card_tex(card_name: String) -> Texture2D:
	if card_name.is_empty():
		return null
	var snake: String = card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
	# Prefer full-card faces (same as deck builder tiles).
	for candidate: String in [
		"res://assets/textures/cards/full_cards/" + snake + ".png",
		"res://assets/textures/cards/full_cards/character_" + snake + ".png",
	]:
		if ResourceLoader.exists(candidate):
			return load(candidate) as Texture2D
	# Fallback: portrait art (jpg/png) via CardDatabase.
	var subfolder: String = "characters"
	if CardDatabase.get_trap(card_name) != null:
		subfolder = "traps"
	elif CardDatabase.get_tech(card_name) != null:
		subfolder = "tech"
	elif UnionDatabase.get_union(card_name) != null:
		subfolder = "union"
	var art_path: String = CardDatabase.find_artwork(
		card_name, subfolder, SaveManager.nsfw_enabled)
	if not art_path.is_empty() and ResourceLoader.exists(art_path):
		return load(art_path) as Texture2D
	return null
