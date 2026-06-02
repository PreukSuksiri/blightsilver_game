extends Control
## ExplorationPlayer — standalone runtime scene for Exploration sessions.
##
## Load via:
##   get_tree().change_scene_to_file("res://scenes/exploration_player.tscn")
##   OR
##   ExplorationManager.launch("res://exploration/graphs/my_graph.json")
##
## Requires an active ExplorationManager session BEFORE this scene loads.
## The scene connects to ExplorationManager signals and renders the current node.
##
## Debug:
##   Press F3 to toggle the debug overlay (shows inventory, vars, history).
##   Click the [DBG] button in the top-right corner for the same effect.

const VN_PLAYER_SCENE: PackedScene = preload("res://scenes/vn_player.tscn")
const FONT_PATH: String = "res://assets/fonts/Chivo-VariableFont_wght.ttf"

# ── UI references (all built in _build_ui) ────────────────────────────────
var _bg_rect: TextureRect          = null   # background image
var _bg_base: ColorRect            = null   # solid-colour fallback behind bg
var _title_lbl: Label              = null   # node title
var _type_badge_lbl: Label         = null   # coloured node-type label
var _desc_lbl: RichTextLabel       = null   # node description
var _choices_vbox: VBoxContainer   = null   # navigation choice buttons
var _back_btn: Button              = null   # go-back button
var _inventory_panel: PanelContainer = null
var _inventory_hbox: HBoxContainer = null   # per-item slot buttons
var _toast_lbl: Label              = null   # temporary message overlay
var _toast_tween: Tween            = null
var _debug_panel: PanelContainer   = null   # F3 debug overlay
var _debug_lbl: RichTextLabel      = null

# ── Internal state ────────────────────────────────────────────────────────
var _current_bg_path: String = ""
var _vn_playing: bool        = false
var _battle_pending: bool    = false
var _exit_pending: bool      = false
var _item_use_panel: PanelContainer = null  # floating use-item confirmation panel

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_ui()
	_connect_signals()

	# Returning from a battle? Show result then refresh.
	if not ExplorationManager.pending_battle_result.is_empty():
		_handle_post_battle_result()
	elif ExplorationManager.is_session_active and ExplorationManager.current_node != null:
		_refresh_node(ExplorationManager.current_node)
	elif ExplorationManager.restore_saved_session():
		# Resumed from a save-file snapshot (e.g. after game restart mid-exploration)
		var resumed_node: ExplorationNode = ExplorationManager.current_node
		if resumed_node != null:
			_show_toast("Session resumed.")
			_refresh_node(resumed_node)
		else:
			_show_no_session_error()
	else:
		_show_no_session_error()

	CheckerTransition.fade_in()

func _connect_signals() -> void:
	ExplorationManager.node_entered.connect(_on_node_entered)
	ExplorationManager.message_posted.connect(_show_toast)
	ExplorationManager.inventory_changed.connect(_on_inventory_changed)

# ─────────────────────────────────────────────────────────────
# UI Construction
# ─────────────────────────────────────────────────────────────

func _make_font(weight: int) -> FontVariation:
	var base := load(FONT_PATH) as FontFile
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {"wght": weight}
	return fv

func _build_ui() -> void:
	# ── Background ────────────────────────────────────────────
	_bg_base = ColorRect.new()
	_bg_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_base.color        = Color(0.04, 0.06, 0.14, 1.0)
	_bg_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_base)

	_bg_rect = TextureRect.new()
	_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.modulate.a   = 0.0
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	# ── Vignette ──────────────────────────────────────────────
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color        = Color(0.0, 0.0, 0.0, 0.55)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	# ── Right-side content panel ──────────────────────────────
	var content := Panel.new()
	content.layout_mode    = 1
	content.anchor_left    = 0.52
	content.anchor_right   = 1.0
	content.anchor_top     = 0.0
	content.anchor_bottom  = 1.0
	var sb_panel := StyleBoxFlat.new()
	sb_panel.bg_color          = Color(0.03, 0.05, 0.13, 0.90)
	sb_panel.border_width_left = 2
	sb_panel.border_color      = Color(0.35, 0.60, 1.0, 0.30)
	content.add_theme_stylebox_override("panel", sb_panel)
	add_child(content)

	var vbox := VBoxContainer.new()
	vbox.layout_mode   = 1
	vbox.anchor_left   = 0.0;  vbox.anchor_right  = 1.0
	vbox.anchor_top    = 0.0;  vbox.anchor_bottom = 1.0
	vbox.offset_left   = 28.0; vbox.offset_right  = -28.0
	vbox.offset_top    = 28.0; vbox.offset_bottom = -28.0
	vbox.add_theme_constant_override("separation", 14)
	content.add_child(vbox)

	# Type badge
	_type_badge_lbl = Label.new()
	_type_badge_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_type_badge_lbl)

	# Title
	_title_lbl = Label.new()
	_title_lbl.add_theme_font_override("font", _make_font(700))
	_title_lbl.add_theme_font_size_override("font_size", 32)
	_title_lbl.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 1.0))
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_title_lbl)

	var sep1 := HSeparator.new()
	var sb_sep := StyleBoxFlat.new()
	sb_sep.bg_color = Color(0.35, 0.60, 1.0, 0.25)
	sb_sep.content_margin_top = 3.0; sb_sep.content_margin_bottom = 3.0
	sep1.add_theme_stylebox_override("separator", sb_sep)
	vbox.add_child(sep1)

	# Description
	_desc_lbl = RichTextLabel.new()
	_desc_lbl.bbcode_enabled = true
	_desc_lbl.scroll_active  = false
	_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desc_lbl.add_theme_font_override("normal_font", _make_font(400))
	_desc_lbl.add_theme_font_size_override("normal_font_size", 22)
	_desc_lbl.add_theme_color_override("default_color", Color(0.82, 0.90, 1.0, 0.95))
	vbox.add_child(_desc_lbl)

	var sep2 := sep1.duplicate() as Control
	vbox.add_child(sep2)

	# Choices
	_choices_vbox = VBoxContainer.new()
	_choices_vbox.add_theme_constant_override("separation", 10)
	vbox.add_child(_choices_vbox)

	# Bottom row: back button + inventory
	var bot_row := HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 10)
	vbox.add_child(bot_row)

	_back_btn = Button.new()
	_back_btn.text = "← Go Back"
	_back_btn.add_theme_font_size_override("font_size", 16)
	_back_btn.add_theme_color_override("font_color", Color(0.55, 0.78, 0.95))
	_back_btn.pressed.connect(_on_back_pressed)
	bot_row.add_child(_back_btn)

	# Inventory slots container (right-aligned, expands to fill)
	_inventory_panel = PanelContainer.new()
	_inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb_inv := StyleBoxFlat.new()
	sb_inv.bg_color       = Color(0.05, 0.12, 0.08, 0.85)
	sb_inv.border_color   = Color(0.35, 0.75, 0.45, 0.50)
	sb_inv.set_border_width_all(1)
	sb_inv.set_corner_radius_all(6)
	sb_inv.content_margin_left = 8.0; sb_inv.content_margin_right  = 8.0
	sb_inv.content_margin_top  = 4.0; sb_inv.content_margin_bottom = 4.0
	_inventory_panel.add_theme_stylebox_override("panel", sb_inv)
	_inventory_hbox = HBoxContainer.new()
	_inventory_hbox.add_theme_constant_override("separation", 6)
	_inventory_panel.add_child(_inventory_hbox)
	bot_row.add_child(_inventory_panel)

	# ── Debug button (top-right corner) ───────────────────────
	var dbg_btn := Button.new()
	dbg_btn.text         = "DBG"
	dbg_btn.layout_mode  = 1
	dbg_btn.anchor_left  = 1.0; dbg_btn.anchor_right  = 1.0
	dbg_btn.anchor_top   = 0.0; dbg_btn.anchor_bottom = 0.0
	dbg_btn.offset_left  = -58.0; dbg_btn.offset_right  = -6.0
	dbg_btn.offset_top   = 6.0;   dbg_btn.offset_bottom = 34.0
	dbg_btn.add_theme_font_size_override("font_size", 11)
	dbg_btn.pressed.connect(_toggle_debug)
	add_child(dbg_btn)

	# ── Debug panel ───────────────────────────────────────────
	_debug_panel = PanelContainer.new()
	_debug_panel.visible    = false
	_debug_panel.z_index    = 200
	_debug_panel.layout_mode = 1
	_debug_panel.anchor_left   = 0.0; _debug_panel.anchor_right  = 0.52
	_debug_panel.anchor_top    = 0.0; _debug_panel.anchor_bottom = 1.0
	_debug_panel.offset_left   = 8.0; _debug_panel.offset_top    = 8.0
	_debug_panel.offset_bottom = -8.0
	var sb_dbg := StyleBoxFlat.new()
	sb_dbg.bg_color = Color(0.0, 0.04, 0.0, 0.90)
	sb_dbg.set_border_width_all(1)
	sb_dbg.border_color = Color(0.3, 0.9, 0.3, 0.6)
	sb_dbg.set_corner_radius_all(6)
	sb_dbg.content_margin_left = 12.0; sb_dbg.content_margin_top = 12.0
	_debug_panel.add_theme_stylebox_override("panel", sb_dbg)
	_debug_lbl = RichTextLabel.new()
	_debug_lbl.bbcode_enabled = true
	_debug_lbl.scroll_active  = true
	_debug_lbl.add_theme_font_size_override("normal_font_size", 13)
	_debug_lbl.add_theme_color_override("default_color", Color(0.55, 1.0, 0.55))
	_debug_panel.add_child(_debug_lbl)
	add_child(_debug_panel)

	# ── Toast label ───────────────────────────────────────────
	_toast_lbl = Label.new()
	_toast_lbl.layout_mode  = 1
	_toast_lbl.anchor_left  = 0.0;  _toast_lbl.anchor_right  = 0.52
	_toast_lbl.anchor_top   = 0.5;  _toast_lbl.anchor_bottom = 0.5
	_toast_lbl.offset_left  = 40.0; _toast_lbl.offset_right  = -40.0
	_toast_lbl.offset_top   = -60.0; _toast_lbl.offset_bottom = 60.0
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.add_theme_font_override("font", _make_font(700))
	_toast_lbl.add_theme_font_size_override("font_size", 28)
	_toast_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
	_toast_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_toast_lbl.add_theme_constant_override("shadow_offset_x", 2)
	_toast_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_toast_lbl.modulate.a    = 0.0
	_toast_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_lbl)

# ─────────────────────────────────────────────────────────────
# Node Rendering
# ─────────────────────────────────────────────────────────────

func _on_node_entered(node: ExplorationNode) -> void:
	_refresh_node(node)

func _refresh_node(node: ExplorationNode) -> void:
	_exit_pending   = false
	_battle_pending = false
	_close_item_use_panel()

	# Background
	if not node.background.is_empty() and node.background != _current_bg_path:
		_current_bg_path = node.background
		if ResourceLoader.exists(node.background):
			_bg_rect.texture  = load(node.background) as Texture2D
			_bg_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			push_warning("ExplorationPlayer: bg '%s' not found." % node.background)

	# Music
	if not node.music.is_empty() and ResourceLoader.exists(node.music):
		BGMManager.play_path(node.music, 1.0, 0.5, 100.0, BGMManager.CONTEXT_VN)

	# Type badge
	match node.node_type:
		ExplorationNode.NodeType.STORY:
			_type_badge_lbl.text = "[ STORY ]"
			_type_badge_lbl.add_theme_color_override("font_color", Color(0.55, 0.80, 1.0))
		ExplorationNode.NodeType.BATTLE:
			_type_badge_lbl.text = "[ BATTLE ]"
			_type_badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.50, 0.45))
		ExplorationNode.NodeType.REWARD:
			_type_badge_lbl.text = "[ REWARD ]"
			_type_badge_lbl.add_theme_color_override("font_color", Color(0.60, 1.0, 0.55))
		ExplorationNode.NodeType.EXIT:
			_type_badge_lbl.text = "[ EXIT ]"
			_type_badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
		ExplorationNode.NodeType.HUB:
			_type_badge_lbl.text = "[ HUB ]"
			_type_badge_lbl.add_theme_color_override("font_color", Color(0.75, 0.60, 1.0))
		_:
			_type_badge_lbl.text = ""

	# Title + description
	_title_lbl.text = node.title
	_desc_lbl.text  = ""
	_desc_lbl.append_text(node.description)

	# Back button
	_back_btn.visible = ExplorationManager.can_go_back()

	# Inventory
	_rebuild_inventory_slots()

	# Build choice buttons first (may be replaced for STORY/BATTLE/EXIT)
	_build_choices(node)

	# Node-type special behaviour
	match node.node_type:
		ExplorationNode.NodeType.STORY:
			if not node.vn_scene.is_empty():
				_play_vn(node.vn_scene, func() -> void: _on_vn_finished(node))
		ExplorationNode.NodeType.BATTLE:
			_show_battle_prompt(node)
		ExplorationNode.NodeType.EXIT:
			_show_exit_prompt()

func _build_choices(node: ExplorationNode) -> void:
	for child: Node in _choices_vbox.get_children():
		child.queue_free()

	if node.connections.is_empty():
		var lbl := Label.new()
		lbl.text = "(No exits from this location.)"
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_choices_vbox.add_child(lbl)
		return

	for conn: Variant in node.connections:
		if not conn is Dictionary:
			continue
		var cd: Dictionary    = conn as Dictionary
		var label_text: String = str(cd.get("label", "Continue"))
		var target_id: String  = str(cd.get("target", ""))
		var unlocked: bool     = ExplorationManager.is_connection_unlocked(cd)
		var hint: String       = ExplorationManager.get_connection_lock_hint(cd)

		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 20)

		if unlocked:
			btn.text = "▶   " + label_text
			btn.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
			var captured_id: String = target_id
			btn.pressed.connect(func() -> void:
				SFXManager.play(SFXManager.SFX_MENU)
				ExplorationManager.navigate_to(captured_id))
		else:
			btn.text = "  " + label_text
			if not hint.is_empty():
				btn.text += "   [color=#888888](%s)[/color]" % hint
			btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
			btn.disabled = true

		_choices_vbox.add_child(btn)

# ─────────────────────────────────────────────────────────────
# Visual Novel Integration
# ─────────────────────────────────────────────────────────────

func _play_vn(path: String, on_done: Callable) -> void:
	if _vn_playing:
		return
	if not ResourceLoader.exists(path):
		push_warning("ExplorationPlayer: VN scene '%s' not found — skipping." % path)
		on_done.call()
		return
	_vn_playing = true
	var vn: Node = VN_PLAYER_SCENE.instantiate()
	add_child(vn)
	vn.play_scene(path, func() -> void:
		_vn_playing = false
		on_done.call())

func _on_vn_finished(node: ExplorationNode) -> void:
	# Rebuild choices after the VN plays so the player can navigate
	_build_choices(node)

# ─────────────────────────────────────────────────────────────
# Battle Integration
# ─────────────────────────────────────────────────────────────

func _show_battle_prompt(node: ExplorationNode) -> void:
	if _battle_pending:
		return
	_battle_pending = true
	for child: Node in _choices_vbox.get_children():
		child.queue_free()

	var btn := Button.new()
	btn.text = "  Begin Battle"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	var captured_node: ExplorationNode = node
	btn.pressed.connect(func() -> void:
		SFXManager.play(SFXManager.SFX_MENU)
		ExplorationManager.start_battle_for_node(captured_node))
	_choices_vbox.add_child(btn)

func _handle_post_battle_result() -> void:
	var result: Dictionary = ExplorationManager.pending_battle_result
	ExplorationManager.pending_battle_result = {}
	var won: bool    = bool(result.get("won", false))
	var node_id: String = str(result.get("node_id", ""))
	# Set a session variable so graph conditions can gate progress on battle outcome.
	# Pattern: "battle_<node_id>_won" = "true" | "false"
	if not node_id.is_empty():
		ExplorationManager.set_var("battle_%s_won" % node_id, "true" if won else "false")
	var msg: String = "Victory!" if won else "Defeated..."
	_show_toast(msg)
	var node: ExplorationNode = ExplorationManager.current_node
	if node != null:
		_refresh_node(node)
	else:
		_show_no_session_error()

# ─────────────────────────────────────────────────────────────
# Exit Integration
# ─────────────────────────────────────────────────────────────

func _show_exit_prompt() -> void:
	if _exit_pending:
		return
	_exit_pending = true
	for child: Node in _choices_vbox.get_children():
		child.queue_free()

	var btn := Button.new()
	btn.text = "  Leave This Place"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
	btn.pressed.connect(_on_exit_confirmed)
	_choices_vbox.add_child(btn)

func _on_exit_confirmed() -> void:
	SFXManager.play(SFXManager.SFX_MENU)
	ExplorationManager.end_session(true)
	var dest: String = ExplorationManager.return_scene
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file(dest))

# ─────────────────────────────────────────────────────────────
# UI helpers
# ─────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	SFXManager.play(SFXManager.SFX_CANCEL)
	ExplorationManager.go_back()

func _on_inventory_changed(_items: Array) -> void:
	_rebuild_inventory_slots()

func _rebuild_inventory_slots() -> void:
	if _inventory_hbox == null:
		return
	# Clear old slots and the floating use-panel if open
	for child: Node in _inventory_hbox.get_children():
		child.queue_free()
	_close_item_use_panel()

	var inv: Array = ExplorationManager.get_inventory()
	_inventory_panel.visible = not inv.is_empty()
	if inv.is_empty():
		return

	# Header label
	var hdr := Label.new()
	hdr.text = "Items:"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(0.50, 0.78, 0.55))
	_inventory_hbox.add_child(hdr)

	# One button per unique item name (shows count if >1)
	var seen: Dictionary = {}
	for raw_item: Variant in inv:
		var item: String = str(raw_item)
		seen[item] = int(seen.get(item, 0)) + 1
	for item_name: Variant in seen.keys():
		var count: int = int(seen[item_name])
		var label_text: String = str(item_name) + (" ×%d" % count if count > 1 else "")
		var slot_btn := Button.new()
		slot_btn.text = label_text
		slot_btn.add_theme_font_size_override("font_size", 14)
		slot_btn.add_theme_color_override("font_color", Color(0.70, 0.95, 0.72))
		var sb_slot := StyleBoxFlat.new()
		sb_slot.bg_color = Color(0.07, 0.18, 0.10, 0.90)
		sb_slot.set_border_width_all(1)
		sb_slot.border_color = Color(0.35, 0.75, 0.45, 0.60)
		sb_slot.set_corner_radius_all(4)
		sb_slot.content_margin_left = 8.0;  sb_slot.content_margin_right  = 8.0
		sb_slot.content_margin_top  = 3.0;  sb_slot.content_margin_bottom = 3.0
		slot_btn.add_theme_stylebox_override("normal", sb_slot)
		var sb_h := sb_slot.duplicate() as StyleBoxFlat
		sb_h.bg_color = Color(0.10, 0.28, 0.16, 0.95)
		slot_btn.add_theme_stylebox_override("hover", sb_h)
		var captured_item: String = str(item_name)
		slot_btn.pressed.connect(func() -> void: _on_item_slot_pressed(captured_item, slot_btn))
		_inventory_hbox.add_child(slot_btn)

func _on_item_slot_pressed(item_name: String, from_btn: Button) -> void:
	# If a use-panel is already open for this item, close it (toggle)
	if _item_use_panel != null and _item_use_panel.get_meta("item", "") == item_name:
		_close_item_use_panel()
		return
	_close_item_use_panel()

	var node: ExplorationNode = ExplorationManager.current_node
	if node == null:
		return

	# Find usable interactions for this item at the current node
	var interactions: Array = []
	for ui: Variant in node.usable_items:
		if ui is Dictionary:
			var uid: Dictionary = ui as Dictionary
			if str(uid.get("item", "")) == item_name:
				interactions.append(uid)

	if interactions.is_empty():
		_show_toast("Can't use %s here." % item_name)
		return

	# Build a small floating panel anchored near the from_btn
	_item_use_panel = PanelContainer.new()
	_item_use_panel.set_meta("item", item_name)
	_item_use_panel.z_index = 50
	var sb_up := StyleBoxFlat.new()
	sb_up.bg_color = Color(0.05, 0.12, 0.08, 0.96)
	sb_up.set_border_width_all(1)
	sb_up.border_color = Color(0.35, 0.85, 0.50, 0.80)
	sb_up.set_corner_radius_all(6)
	sb_up.content_margin_left = 10.0; sb_up.content_margin_right  = 10.0
	sb_up.content_margin_top  = 8.0;  sb_up.content_margin_bottom = 8.0
	_item_use_panel.add_theme_stylebox_override("panel", sb_up)

	var up_vbox := VBoxContainer.new()
	up_vbox.add_theme_constant_override("separation", 6)
	_item_use_panel.add_child(up_vbox)

	var up_title := Label.new()
	up_title.text = item_name.capitalize()
	up_title.add_theme_font_size_override("font_size", 15)
	up_title.add_theme_color_override("font_color", Color(0.70, 0.95, 0.72))
	up_vbox.add_child(up_title)

	for interaction: Variant in interactions:
		var idict: Dictionary = interaction as Dictionary
		var btn_label: String = str(idict.get("label", "Use"))
		var use_btn := Button.new()
		use_btn.text = "▶  " + btn_label
		use_btn.add_theme_font_size_override("font_size", 16)
		use_btn.add_theme_color_override("font_color", Color(0.88, 1.0, 0.90))
		var captured_idict: Dictionary = idict
		var captured_item: String = item_name
		use_btn.pressed.connect(func() -> void:
			_close_item_use_panel()
			_execute_item_use(captured_item, captured_idict))
		up_vbox.add_child(use_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_size_override("font_size", 14)
	cancel_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
	cancel_btn.pressed.connect(_close_item_use_panel)
	up_vbox.add_child(cancel_btn)

	# Position: just above the inventory panel (bottom-right area)
	_item_use_panel.layout_mode = 1
	_item_use_panel.anchor_right  = 1.0; _item_use_panel.anchor_left   = 1.0
	_item_use_panel.anchor_bottom = 1.0; _item_use_panel.anchor_top    = 1.0
	_item_use_panel.offset_right  = -12.0
	_item_use_panel.offset_bottom = -60.0
	add_child(_item_use_panel)

func _close_item_use_panel() -> void:
	if _item_use_panel != null:
		_item_use_panel.queue_free()
		_item_use_panel = null

func _execute_item_use(item_name: String, idict: Dictionary) -> void:
	SFXManager.play(SFXManager.SFX_MENU)
	var consume: bool    = bool(idict.get("consume", false))
	var vn_path: String  = str(idict.get("vn_scene", ""))
	if consume:
		ExplorationManager.remove_item(item_name)
	if not vn_path.is_empty():
		_play_vn(vn_path, func() -> void:
			var node: ExplorationNode = ExplorationManager.current_node
			if node != null:
				_refresh_node(node))
	else:
		var node: ExplorationNode = ExplorationManager.current_node
		if node != null:
			_refresh_node(node)

func _show_toast(text: String) -> void:
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_lbl.text      = text
	_toast_lbl.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(_toast_lbl, "modulate:a", 0.0, 0.8)

func _show_no_session_error() -> void:
	_title_lbl.text = "No Exploration Active"
	_desc_lbl.text  = "ExplorationManager has no active session.\nReturn to the main menu."
	for child: Node in _choices_vbox.get_children():
		child.queue_free()
	var btn := Button.new()
	btn.text = "Return to Main Menu"
	btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	_choices_vbox.add_child(btn)

# ─────────────────────────────────────────────────────────────
# Debug overlay
# ─────────────────────────────────────────────────────────────

func _toggle_debug() -> void:
	_debug_panel.visible = not _debug_panel.visible
	if _debug_panel.visible:
		_debug_lbl.text = ""
		_debug_lbl.append_text("[color=#44ff44]" + ExplorationManager.debug_dump() + "[/color]")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		if (event as InputEventKey).keycode == KEY_F3:
			_toggle_debug()
			get_viewport().set_input_as_handled()
