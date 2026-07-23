extends Node
## Shared VN-style blue dialog skin for custom overlay prompts.

const OVERLAY_NAME := &"GameDialogOverlay"
const BTN_MIN_SIZE := Vector2(140, 40)
const TITLE_FONT_SIZE := 22
const BODY_FONT_SIZE := 18
const BTN_FONT_SIZE := 17
const DEFAULT_MIN_WIDTH := 480.0
const DEFAULT_Z_INDEX := 400

const PANEL_BG := Color(0.04, 0.06, 0.13, 0.97)
const PANEL_BORDER := Color(0.60, 0.82, 1.0, 0.65)
const TITLE_COLOR := Color(0.72, 0.92, 1.0, 1.0)
const BODY_COLOR := Color(0.90, 0.95, 1.0, 0.97)
const BTN_NORMAL := Color(0.08, 0.16, 0.38, 0.97)
const BTN_HOVER := Color(0.12, 0.24, 0.52, 1.0)
const BTN_PRESSED := Color(0.06, 0.12, 0.30, 1.0)
const BTN_BORDER := Color(0.38, 0.65, 1.0, 0.6)
const BTN_TEXT := Color(0.88, 0.95, 1.0, 1.0)

const _SHADER_DIALOG_PANEL: Shader = preload("res://assets/shaders/magitech_dialog_panel.gdshader")
const _SHADER_DIALOG_BUTTON: Shader = preload("res://assets/shaders/magitech_dialog_button.gdshader")
const _BTN_FX_META := &"magitech_btn_fx_mat"
const _BTN_FX_NODE := &"MagitechBtnFx"
const _BTN_FX_WIRED := &"magitech_btn_fx_wired"
const _BTN_FX_SIZE_WIRED := &"magitech_btn_fx_size_wired"
const _PANEL_FX_SIZE_WIRED := &"magitech_panel_fx_size_wired"

const OVERLAY_LAYER_NAME := &"GameDialogLayer"
const OVERLAY_HOST_NAME := &"GameDialogHost"
const REQUESTER_META := &"game_dialog_requester_id"
const OVERLAY_CANVAS_LAYER := 500

var _overlay_layer: CanvasLayer = null
var _overlay_host: Control = null


func _ready() -> void:
	var tree_root: Window = get_tree().root
	if not tree_root.size_changed.is_connected(_on_viewport_resized):
		tree_root.size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	_sync_overlay_host_size()


func has_any_open_overlay(overlay_name: StringName = OVERLAY_NAME) -> bool:
	return has_open_overlay(null, overlay_name)


func has_open_overlay(parent: Node = null, overlay_name: StringName = OVERLAY_NAME) -> bool:
	return _find_overlay(parent, overlay_name) != null


func make_panel_stylebox(content_margin: float = 18.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	# Transparent chrome — fill/border drawn by magitech_dialog_panel shader.
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(0)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(content_margin)
	return sb


func attach_panel_fx(panel: Control) -> void:
	if panel == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = _SHADER_DIALOG_PANEL
	mat.set_shader_parameter("fill_top", Color(0.07, 0.10, 0.18, 0.97))
	mat.set_shader_parameter("fill_bottom", Color(0.025, 0.035, 0.07, 0.97))
	mat.set_shader_parameter("border_a", Color(0.55, 0.92, 1.0, 0.88))
	mat.set_shader_parameter("border_b", Color(0.78, 0.84, 0.94, 0.72))
	mat.set_shader_parameter("border_px", 2.0)
	mat.set_shader_parameter("corner_radius_px", float(MagitechTheme.CORNER_RADIUS))
	mat.set_shader_parameter("rim_speed", 0.20)
	mat.set_shader_parameter("rim_pulse", 0.30)
	panel.material = mat
	_sync_panel_fx_size(panel)
	if not panel.get_meta(_PANEL_FX_SIZE_WIRED, false):
		panel.set_meta(_PANEL_FX_SIZE_WIRED, true)
		panel.resized.connect(_sync_panel_fx_size.bind(panel))
	call_deferred("_sync_panel_fx_size", panel)


func _sync_panel_fx_size(panel: Control) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	var mat: ShaderMaterial = panel.material as ShaderMaterial
	if mat == null or mat.shader != _SHADER_DIALOG_PANEL:
		return
	var sz: Vector2 = panel.size
	if sz.x < 1.0 or sz.y < 1.0:
		sz = panel.get_combined_minimum_size()
	if sz.x < 1.0 or sz.y < 1.0:
		sz = Vector2(DEFAULT_MIN_WIDTH, 200.0)
	mat.set_shader_parameter("rect_size", sz)


func style_button(btn: Button) -> void:
	btn.custom_minimum_size = BTN_MIN_SIZE
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	FontManager.tag_font(btn, "font", "primary", 400)
	btn.add_theme_font_size_override("font_size", BTN_FONT_SIZE)
	btn.add_theme_color_override("font_color", BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.82, 0.92, 1.0, 1.0))
	apply_button_chrome(btn, true)


## Magitech gradient face only — keeps caller font size / layout / labels.
## Used by dialogs (via style_button) and main-menu stack buttons.
func apply_button_chrome(btn: Button, wire_sfx: bool = false) -> void:
	if btn == null:
		return
	var empty := _make_button_style(Color(0, 0, 0, 0))
	empty.border_color = Color(0, 0, 0, 0)
	empty.set_border_width_all(0)
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty.duplicate())
	btn.add_theme_stylebox_override("pressed", empty.duplicate())
	btn.add_theme_stylebox_override("focus", empty.duplicate())
	_attach_button_fx(btn, btn.disabled)
	_apply_disabled_button_style(btn)
	if wire_sfx:
		SFXManager.wire_prompt_button(btn)


func sync_button_chrome_disabled(btn: Button) -> void:
	_sync_button_fx_disabled(btn)


func style_menu_button(btn: Button) -> void:
	style_button(btn)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0.0, BTN_MIN_SIZE.y)


func style_title_label(lbl: Label) -> void:
	FontManager.tag_font(lbl, "font", "primary", 700)
	lbl.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	lbl.add_theme_color_override("font_color", TITLE_COLOR)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func style_body_label(lbl: Label) -> void:
	FontManager.tag_font(lbl, "font", "primary", 400)
	lbl.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	lbl.add_theme_color_override("font_color", BODY_COLOR)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func style_line_edit(line: LineEdit) -> void:
	if line == null:
		return
	FontManager.tag_font(line, "font", "primary", 400)
	line.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	line.add_theme_color_override("font_color", BODY_COLOR)
	line.add_theme_color_override("font_uneditable_color", Color(0.62, 0.68, 0.78, 0.9))
	line.add_theme_color_override("font_placeholder_color", Color(0.55, 0.62, 0.72, 0.85))
	line.add_theme_color_override("caret_color", TITLE_COLOR)
	line.add_theme_color_override("selection_color", Color(0.25, 0.45, 0.75, 0.55))
	var normal := _make_line_edit_style(
		Color(0.08, 0.10, 0.18, 1.0), Color(0.35, 0.55, 0.85, 0.55))
	var focus := _make_line_edit_style(
		Color(0.10, 0.14, 0.24, 1.0), Color(0.55, 0.78, 1.0, 0.8))
	var read_only := _make_line_edit_style(
		Color(0.06, 0.08, 0.14, 0.95), Color(0.28, 0.38, 0.55, 0.45))
	line.add_theme_stylebox_override("normal", normal)
	line.add_theme_stylebox_override("focus", focus)
	line.add_theme_stylebox_override("read_only", read_only)


func style_spin_box(spin: SpinBox) -> void:
	if spin == null:
		return
	var line: LineEdit = spin.get_line_edit()
	if line != null:
		style_line_edit(line)


## Magitech OptionButton + popup menu (replaces default grey OS-like dropdown).
func style_option_button(opt: OptionButton) -> void:
	if opt == null:
		return
	FontManager.tag_primary(opt)
	opt.add_theme_color_override("font_color", BODY_COLOR)
	opt.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	opt.add_theme_color_override("font_pressed_color", Color(0.82, 0.92, 1.0, 1.0))
	opt.add_theme_color_override("font_disabled_color", Color(0.55, 0.62, 0.72, 0.85))
	opt.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	opt.add_theme_color_override("icon_normal_color", Color(0.55, 0.88, 1.0, 1.0))
	opt.add_theme_color_override("icon_hover_color", Color(0.75, 0.95, 1.0, 1.0))
	opt.add_theme_color_override("icon_pressed_color", Color(0.45, 0.78, 0.95, 1.0))
	opt.add_theme_color_override("icon_disabled_color", Color(0.45, 0.55, 0.65, 0.45))

	var normal := _make_line_edit_style(
		Color(0.08, 0.10, 0.18, 1.0), Color(0.35, 0.55, 0.85, 0.55))
	var hover := _make_line_edit_style(
		Color(0.10, 0.14, 0.24, 1.0), Color(0.55, 0.78, 1.0, 0.80))
	var pressed := _make_line_edit_style(
		Color(0.06, 0.09, 0.16, 1.0), Color(0.40, 0.65, 0.95, 0.70))
	var disabled := _make_line_edit_style(
		Color(0.06, 0.08, 0.12, 0.90), Color(0.28, 0.38, 0.55, 0.40))
	opt.add_theme_stylebox_override("normal", normal)
	opt.add_theme_stylebox_override("hover", hover)
	opt.add_theme_stylebox_override("pressed", pressed)
	opt.add_theme_stylebox_override("disabled", disabled)
	opt.add_theme_stylebox_override("focus", hover.duplicate())

	var popup: PopupMenu = opt.get_popup()
	if popup == null:
		return
	popup.add_theme_font_override("font", FontManager.primary_font())
	popup.add_theme_font_size_override("font_size", opt.get_theme_font_size("font_size"))
	popup.add_theme_color_override("font_color", BODY_COLOR)
	popup.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	popup.add_theme_color_override("font_separator_color", Color(0.35, 0.50, 0.70, 0.55))
	popup.add_theme_color_override("font_accelerator_color", Color(0.55, 0.65, 0.78, 0.85))
	popup.add_theme_color_override("font_disabled_color", Color(0.55, 0.62, 0.72, 0.55))

	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.05, 0.07, 0.14, 0.98)
	panel_sb.border_color = Color(0.45, 0.78, 1.0, 0.70)
	panel_sb.set_border_width_all(1)
	panel_sb.set_corner_radius_all(6)
	panel_sb.set_content_margin_all(6)
	popup.add_theme_stylebox_override("panel", panel_sb)

	var item_hover := StyleBoxFlat.new()
	item_hover.bg_color = Color(0.12, 0.22, 0.40, 0.95)
	item_hover.border_color = Color(0.40, 0.75, 1.0, 0.35)
	item_hover.set_border_width_all(1)
	item_hover.set_corner_radius_all(4)
	item_hover.set_content_margin_all(6)
	popup.add_theme_stylebox_override("hover", item_hover)

	var item_sep := StyleBoxFlat.new()
	item_sep.bg_color = Color(0.35, 0.50, 0.70, 0.35)
	item_sep.set_content_margin_all(0)
	popup.add_theme_stylebox_override("separator", item_sep)


func _make_line_edit_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	return sb


func accept_overlay(
		parent: Node,
		title: String,
		body: String,
		ok_text: String = "OK",
		on_ok: Callable = Callable(),
		min_width: float = DEFAULT_MIN_WIDTH,
		z_index: int = DEFAULT_Z_INDEX,
		overlay_name: StringName = OVERLAY_NAME) -> Control:
	var shell: Dictionary = _make_overlay_shell(parent, min_width, z_index, overlay_name)
	var vbox: VBoxContainer = shell["vbox"]
	var root: Control = shell["root"]
	_add_title_body(vbox, title, body)
	_add_button_row(vbox, [_make_button_def(ok_text, func() -> void:
		if on_ok.is_valid():
			on_ok.call()
		root.queue_free())])
	return root


func confirmation_overlay(
		parent: Node,
		title: String,
		body: String,
		ok_text: String = "OK",
		cancel_text: String = "Cancel",
		on_confirm: Callable = Callable(),
		on_cancel: Callable = Callable(),
		min_width: float = DEFAULT_MIN_WIDTH,
		z_index: int = DEFAULT_Z_INDEX,
		overlay_name: StringName = OVERLAY_NAME) -> Control:
	var shell: Dictionary = _make_overlay_shell(parent, min_width, z_index, overlay_name)
	var vbox: VBoxContainer = shell["vbox"]
	_add_title_body(vbox, title, body)
	var root: Control = shell["root"]
	_add_button_row(vbox, [
		_make_button_def(ok_text, func() -> void:
			root.queue_free()
			if on_confirm.is_valid():
				on_confirm.call()),
		_make_button_def(cancel_text, func() -> void:
			root.queue_free()
			if on_cancel.is_valid():
				on_cancel.call()),
	])
	return root


## Confirmation with a countdown before the primary button is enabled (destructive actions).
func confirmation_overlay_delayed(
		parent: Node,
		title: String,
		body: String,
		ok_text: String = "OK",
		cancel_text: String = "Cancel",
		on_confirm: Callable = Callable(),
		on_cancel: Callable = Callable(),
		confirm_delay_sec: float = 3.0,
		min_width: float = DEFAULT_MIN_WIDTH,
		z_index: int = DEFAULT_Z_INDEX,
		overlay_name: StringName = OVERLAY_NAME) -> Control:
	var shell: Dictionary = _make_overlay_shell(parent, min_width, z_index, overlay_name)
	var vbox: VBoxContainer = shell["vbox"]
	var root: Control = shell["root"]
	_add_title_body(vbox, title, body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var delay_secs: int = maxi(1, int(ceil(confirm_delay_sec)))
	var confirm_btn := Button.new()
	confirm_btn.text = "%s (%d)" % [ok_text, delay_secs]
	confirm_btn.disabled = true
	style_button(confirm_btn)
	_apply_disabled_button_style(confirm_btn)
	confirm_btn.pressed.connect(func() -> void:
		if on_confirm.is_valid():
			on_confirm.call()
		root.queue_free())
	btn_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = cancel_text
	style_button(cancel_btn)
	cancel_btn.pressed.connect(func() -> void:
		if on_cancel.is_valid():
			on_cancel.call()
		root.queue_free())
	btn_row.add_child(cancel_btn)

	var remaining: Array[int] = [delay_secs]
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(func() -> void:
		remaining[0] -= 1
		if remaining[0] > 0:
			confirm_btn.text = "%s (%d)" % [ok_text, remaining[0]]
		else:
			confirm_btn.text = ok_text
			confirm_btn.disabled = false
			_sync_button_fx_disabled(confirm_btn)
			timer.stop())
	root.add_child(timer)

	return root


## Multi-action dialog. Each action: { "text": String, "callback": Callable }.
## Optional cancel button closes without running an action callback.
func choices_overlay(
		parent: Node,
		title: String,
		body: String,
		actions: Array,
		cancel_text: String = "Cancel",
		on_cancel: Callable = Callable(),
		min_width: float = DEFAULT_MIN_WIDTH,
		z_index: int = DEFAULT_Z_INDEX,
		overlay_name: StringName = OVERLAY_NAME) -> Control:
	var shell: Dictionary = _make_overlay_shell(parent, min_width, z_index, overlay_name)
	var vbox: VBoxContainer = shell["vbox"]
	_add_title_body(vbox, title, body)
	var root: Control = shell["root"]
	var buttons: Array = []
	for action: Variant in actions:
		if not (action is Dictionary):
			continue
		var text: String = str(action.get("text", "OK"))
		var callback: Callable = action.get("callback", Callable()) as Callable
		buttons.append(_make_button_def(text, func() -> void:
			root.queue_free()
			if callback.is_valid():
				callback.call()))
	if not cancel_text.is_empty():
		buttons.append(_make_button_def(cancel_text, func() -> void:
			root.queue_free()
			if on_cancel.is_valid():
				on_cancel.call()))
	_add_button_row(vbox, buttons)
	return root


## Vertical action menu (battle options, etc.). Each action: { "text": String, "callback": Callable }.
func menu_overlay(
		parent: Node,
		title: String,
		body: String,
		actions: Array,
		cancel_text: String = "Close",
		on_cancel: Callable = Callable(),
		min_width: float = 360.0,
		z_index: int = DEFAULT_Z_INDEX,
		overlay_name: StringName = OVERLAY_NAME) -> Control:
	var shell: Dictionary = _make_overlay_shell(parent, min_width, z_index, overlay_name)
	var vbox: VBoxContainer = shell["vbox"]
	var root: Control = shell["root"]
	_add_title_body(vbox, title, body)

	var menu_col := VBoxContainer.new()
	menu_col.add_theme_constant_override("separation", 10)
	menu_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(menu_col)

	for action: Variant in actions:
		if not (action is Dictionary):
			continue
		var text: String = str(action.get("text", "")).strip_edges()
		if text.is_empty():
			continue
		var callback: Callable = action.get("callback", Callable()) as Callable
		var btn := Button.new()
		btn.text = text
		style_menu_button(btn)
		btn.pressed.connect(func() -> void:
			root.queue_free()
			if callback.is_valid():
				callback.call())
		menu_col.add_child(btn)

	if not cancel_text.is_empty():
		var cancel_btn := Button.new()
		cancel_btn.text = cancel_text
		style_menu_button(cancel_btn)
		cancel_btn.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88, 1.0))
		cancel_btn.pressed.connect(func() -> void:
			root.queue_free()
			if on_cancel.is_valid():
				on_cancel.call())
		menu_col.add_child(cancel_btn)

	return root


## Shell for custom dialog content (scroll areas, lists). Returns { root, vbox, panel }.
func content_overlay(
		parent: Node,
		min_width: float,
		min_height: float = 0.0,
		z_index: int = DEFAULT_Z_INDEX,
		overlay_name: StringName = OVERLAY_NAME) -> Dictionary:
	var shell: Dictionary = _make_overlay_shell(parent, min_width, z_index, overlay_name)
	if min_height > 0.0:
		var panel: PanelContainer = shell["panel"] as PanelContainer
		panel.custom_minimum_size.y = min_height
	return shell


## Text prompt with OK / Cancel. on_confirm receives entered text and returns true to close.
func prompt_overlay(
		parent: Node,
		title: String,
		body: String,
		placeholder: String = "",
		ok_text: String = "OK",
		cancel_text: String = "Cancel",
		on_confirm: Callable = Callable(),
		on_cancel: Callable = Callable(),
		min_width: float = DEFAULT_MIN_WIDTH,
		z_index: int = DEFAULT_Z_INDEX,
		overlay_name: StringName = OVERLAY_NAME) -> Control:
	var shell: Dictionary = _make_overlay_shell(parent, min_width, z_index, overlay_name)
	var vbox: VBoxContainer = shell["vbox"]
	_add_title_body(vbox, title, body)
	var root: Control = shell["root"]

	var line := LineEdit.new()
	line.placeholder_text = placeholder
	line.custom_minimum_size = Vector2(360.0, 36.0)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_line_edit(line)
	vbox.add_child(line)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var ok_btn := Button.new()
	ok_btn.text = ok_text
	style_button(ok_btn)
	ok_btn.pressed.connect(func() -> void:
		if on_confirm.is_valid():
			if not on_confirm.call(line.text.strip_edges()):
				return
		root.queue_free())
	btn_row.add_child(ok_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = cancel_text
	style_button(cancel_btn)
	cancel_btn.pressed.connect(func() -> void:
		if on_cancel.is_valid():
			on_cancel.call()
		root.queue_free())
	btn_row.add_child(cancel_btn)

	line.text_submitted.connect(func(_text: String) -> void: ok_btn.pressed.emit())
	line.call_deferred("grab_focus")
	return root


func close_overlay(parent: Node, overlay_name: StringName = OVERLAY_NAME) -> void:
	var overlay: Control = _find_overlay(parent, overlay_name)
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()


## Full-screen overlay on the viewport host (SettingsMenu, etc.).
func attach_viewport_overlay(control: Control, requester: Node = null) -> void:
	var host: Control = _ensure_overlay_host()
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if requester != null:
		control.set_meta(REQUESTER_META, requester.get_instance_id())
	host.add_child(control)
	control.move_to_front()
	_sync_overlay_host_input_block()
	if not control.tree_exited.is_connected(_on_overlay_child_tree_exited):
		control.tree_exited.connect(_on_overlay_child_tree_exited)


func _find_overlay(parent: Node, overlay_name: StringName) -> Control:
	var host: Control = _get_overlay_host_if_exists()
	if host != null:
		for child: Node in host.get_children():
			if not is_instance_valid(child) or child.is_queued_for_deletion():
				continue
			if child.name != str(overlay_name):
				continue
			if parent == null:
				return child as Control
			if child.has_meta(REQUESTER_META) \
					and int(child.get_meta(REQUESTER_META)) == parent.get_instance_id():
				return child as Control
		return null
	if parent != null:
		return parent.get_node_or_null(NodePath(str(overlay_name))) as Control
	return null


func _ensure_overlay_host() -> Control:
	var tree_root: Window = get_tree().root
	if _overlay_layer == null or not is_instance_valid(_overlay_layer):
		_overlay_layer = tree_root.get_node_or_null(NodePath(str(OVERLAY_LAYER_NAME))) as CanvasLayer
	if _overlay_layer == null:
		_overlay_layer = CanvasLayer.new()
		_overlay_layer.name = String(OVERLAY_LAYER_NAME)
		_overlay_layer.layer = OVERLAY_CANVAS_LAYER
		tree_root.add_child(_overlay_layer)
	if _overlay_host == null or not is_instance_valid(_overlay_host):
		_overlay_host = _overlay_layer.get_node_or_null(NodePath(str(OVERLAY_HOST_NAME))) as Control
	if _overlay_host == null:
		_overlay_host = Control.new()
		_overlay_host.name = String(OVERLAY_HOST_NAME)
		_overlay_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay_layer.add_child(_overlay_host)
		if not tree_root.size_changed.is_connected(_on_viewport_resized):
			tree_root.size_changed.connect(_on_viewport_resized)
	_sync_overlay_host_size()
	return _overlay_host


func _get_overlay_host_if_exists() -> Control:
	if _overlay_host != null and is_instance_valid(_overlay_host):
		return _overlay_host
	var tree_root: Window = get_tree().root
	var layer: CanvasLayer = tree_root.get_node_or_null(NodePath(str(OVERLAY_LAYER_NAME))) as CanvasLayer
	if layer == null:
		return null
	return layer.get_node_or_null(NodePath(str(OVERLAY_HOST_NAME))) as Control


func _sync_overlay_host_size() -> void:
	if _overlay_host == null or not is_instance_valid(_overlay_host):
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	_overlay_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_host.position = Vector2.ZERO
	_overlay_host.size = vp_size
	for child: Node in _overlay_host.get_children():
		if child is Control and is_instance_valid(child):
			var c: Control = child as Control
			c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			c.position = Vector2.ZERO
			c.size = vp_size


func _sync_overlay_host_input_block() -> void:
	if _overlay_host == null or not is_instance_valid(_overlay_host):
		return
	var has_modal := false
	for child: Node in _overlay_host.get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			has_modal = true
			break
	# Host itself must catch clicks when any modal is up, so IGNORE never leaks
	# through a zero-size / mis-anchored child to the screen underneath.
	_overlay_host.mouse_filter = (
			Control.MOUSE_FILTER_STOP if has_modal else Control.MOUSE_FILTER_IGNORE)


func _on_overlay_child_tree_exited() -> void:
	# Defer so queue_free siblings are gone before we re-evaluate.
	call_deferred("_sync_overlay_host_input_block")


func _make_overlay_shell(
		parent: Node,
		min_width: float,
		z_index: int,
		overlay_name: StringName) -> Dictionary:
	var root := Control.new()
	root.name = String(overlay_name)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.z_index = z_index

	var blocker := ColorRect.new()
	blocker.name = "DimBlocker"
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.color = Color(0.02, 0.03, 0.06, 0.62)
	root.add_child(blocker)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(min_width, 0.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", make_panel_stylebox())
	attach_panel_fx(panel)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var host: Control = _ensure_overlay_host()
	if parent != null:
		root.set_meta(REQUESTER_META, parent.get_instance_id())
	host.add_child(root)
	root.move_to_front()
	# Force full-viewport coverage after parenting (anchors alone can leave size 0).
	var cover: Vector2 = host.size
	if cover.x < 1.0 or cover.y < 1.0:
		cover = get_viewport().get_visible_rect().size
	for node: Control in [root, blocker, center]:
		node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		node.position = Vector2.ZERO
		node.size = cover
	_sync_overlay_host_input_block()
	if not root.tree_exited.is_connected(_on_overlay_child_tree_exited):
		root.tree_exited.connect(_on_overlay_child_tree_exited)
	return {"root": root, "vbox": vbox, "panel": panel}


func _add_title_body(vbox: VBoxContainer, title: String, body: String) -> void:
	if not title.is_empty():
		var title_lbl := Label.new()
		title_lbl.text = title
		style_title_label(title_lbl)
		vbox.add_child(title_lbl)

	if not body.is_empty():
		var body_lbl := Label.new()
		body_lbl.text = body
		style_body_label(body_lbl)
		vbox.add_child(body_lbl)


func _add_button_row(vbox: VBoxContainer, button_defs: Array) -> void:
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)
	for def: Variant in button_defs:
		if not (def is Dictionary):
			continue
		var btn: Button = def.get("button") as Button
		if btn == null:
			btn = Button.new()
			btn.text = str(def.get("text", "OK"))
			style_button(btn)
			var on_press: Callable = def.get("on_press", Callable()) as Callable
			if on_press.is_valid():
				btn.pressed.connect(on_press)
		btn_row.add_child(btn)


func _make_button_def(text: String, on_press: Callable) -> Dictionary:
	return {"text": text, "on_press": on_press}


func _make_button_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = BTN_BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	return sb


func _attach_button_fx(btn: Button, disabled_look: bool) -> void:
	if btn == null:
		return
	var fx: ColorRect = btn.get_node_or_null(NodePath(str(_BTN_FX_NODE))) as ColorRect
	if fx == null:
		fx = ColorRect.new()
		fx.name = String(_BTN_FX_NODE)
		fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx.show_behind_parent = true
		fx.color = Color.WHITE
		btn.add_child(fx)
		btn.move_child(fx, 0)
	var mat := ShaderMaterial.new()
	mat.shader = _SHADER_DIALOG_BUTTON
	mat.set_shader_parameter("border_px", 1.5)
	mat.set_shader_parameter("corner_radius_px", float(MagitechTheme.CORNER_RADIUS))
	fx.material = mat
	btn.set_meta(_BTN_FX_META, mat)
	_apply_button_fx_colors(mat, disabled_look)
	_sync_button_fx_size(btn)
	if not btn.get_meta(_BTN_FX_SIZE_WIRED, false):
		btn.set_meta(_BTN_FX_SIZE_WIRED, true)
		fx.resized.connect(_sync_button_fx_size.bind(btn))
	call_deferred("_sync_button_fx_size", btn)
	if btn.get_meta(_BTN_FX_WIRED, false):
		return
	btn.set_meta(_BTN_FX_WIRED, true)
	btn.mouse_entered.connect(_on_fx_button_hover_entered.bind(btn))
	btn.mouse_exited.connect(_on_fx_button_hover_exited.bind(btn))
	btn.button_down.connect(_on_fx_button_down.bind(btn))
	btn.button_up.connect(_on_fx_button_up.bind(btn))


func _sync_button_fx_size(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	var fx: ColorRect = btn.get_node_or_null(NodePath(str(_BTN_FX_NODE))) as ColorRect
	var mat: ShaderMaterial = _btn_fx_mat(btn)
	if fx == null or mat == null:
		return
	var sz: Vector2 = fx.size
	if sz.x < 1.0 or sz.y < 1.0:
		sz = btn.size
	if sz.x < 1.0 or sz.y < 1.0:
		sz = BTN_MIN_SIZE
	mat.set_shader_parameter("rect_size", sz)


func _apply_button_fx_colors(mat: ShaderMaterial, disabled_look: bool) -> void:
	if mat == null:
		return
	if disabled_look:
		mat.set_shader_parameter("fill_top", Color(0.08, 0.10, 0.18, 0.85))
		mat.set_shader_parameter("fill_bottom", Color(0.05, 0.07, 0.12, 0.85))
		mat.set_shader_parameter("border_a", Color(0.35, 0.45, 0.55, 0.45))
		mat.set_shader_parameter("border_b", Color(0.40, 0.48, 0.58, 0.40))
		mat.set_shader_parameter("brightness", 0.75)
	else:
		mat.set_shader_parameter("fill_top", Color(0.11, 0.20, 0.40, 0.97))
		mat.set_shader_parameter("fill_bottom", Color(0.05, 0.10, 0.22, 0.97))
		mat.set_shader_parameter("border_a", Color(0.45, 0.88, 1.0, 0.82))
		mat.set_shader_parameter("border_b", Color(0.72, 0.80, 0.92, 0.70))
		mat.set_shader_parameter("brightness", 1.0)


func _btn_fx_mat(btn: Button) -> ShaderMaterial:
	if btn == null or not btn.has_meta(_BTN_FX_META):
		return null
	return btn.get_meta(_BTN_FX_META) as ShaderMaterial


func _on_fx_button_hover_entered(btn: Button) -> void:
	var mat: ShaderMaterial = _btn_fx_mat(btn)
	if mat != null and not btn.disabled:
		mat.set_shader_parameter("brightness", 1.14)


func _on_fx_button_hover_exited(btn: Button) -> void:
	var mat: ShaderMaterial = _btn_fx_mat(btn)
	if mat != null and not btn.disabled:
		mat.set_shader_parameter("brightness", 1.0)


func _on_fx_button_down(btn: Button) -> void:
	var mat: ShaderMaterial = _btn_fx_mat(btn)
	if mat != null and not btn.disabled:
		mat.set_shader_parameter("brightness", 0.88)


func _on_fx_button_up(btn: Button) -> void:
	var mat: ShaderMaterial = _btn_fx_mat(btn)
	if mat == null or btn.disabled:
		return
	var hovered: bool = btn.get_global_rect().has_point(btn.get_global_mouse_position())
	mat.set_shader_parameter("brightness", 1.14 if hovered else 1.0)


func _apply_disabled_button_style(btn: Button) -> void:
	var disabled_sb := _make_button_style(Color(0, 0, 0, 0))
	disabled_sb.border_color = Color(0, 0, 0, 0)
	disabled_sb.set_border_width_all(0)
	btn.add_theme_stylebox_override("disabled", disabled_sb)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.62, 0.72, 0.85))
	_sync_button_fx_disabled(btn)


func _sync_button_fx_disabled(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	var mat: ShaderMaterial = _btn_fx_mat(btn)
	if mat == null:
		_attach_button_fx(btn, btn.disabled)
		return
	_apply_button_fx_colors(mat, btn.disabled)
