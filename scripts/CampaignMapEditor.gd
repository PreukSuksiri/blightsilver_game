extends Control
# Campaign Map Node Editor — drag-and-drop stage positioning tool.
# Open via Admin Console: map_editor
# Saves positions to user://campaign_node_positions.json
# CampaignManager loads that file on startup to apply saved positions.

signal closed

# ─────────────────────────────────────────────────────────────
# Inner class — efficient line rendering via _draw()
# ─────────────────────────────────────────────────────────────
class LineCanvas extends Control:
	var _lines: Array = []

	func set_lines(new_lines: Array) -> void:
		_lines = new_lines
		queue_redraw()

	func _draw() -> void:
		for ln: Dictionary in _lines:
			draw_line(ln["from"], ln["to"], ln["color"], 1.5, true)

# ─────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────
const CANVAS_W  := 1860.0
const CANVAS_H  := 540.0
const NODE_W    := 80.0
const NODE_H    := 60.0
const SAVE_PATH := "user://campaign_node_positions.json"

const COLOR_BATTLE := Color(1.00, 0.42, 0.22)
const COLOR_STORY  := Color(0.30, 0.65, 1.00)
const COLOR_REWARD := Color(0.95, 0.78, 0.10)

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var _positions:      Dictionary = {}  # id → Vector2 (center)
var _node_controls:  Dictionary = {}  # id → Control

var _drag_node_id:       String  = ""
var _drag_start_mouse:   Vector2
var _drag_start_node_pos: Vector2

var _canvas:      Control    = null
var _line_canvas: LineCanvas = null
var _pos_label:   Label      = null

# ─────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 50
	_load_positions()
	_build_ui()

# ─────────────────────────────────────────────────────────────
# Position persistence
# ─────────────────────────────────────────────────────────────
func _load_positions() -> void:
	# Seed from CampaignManager defaults
	for node in CampaignManager.all_nodes:
		_positions[node.id] = node.map_position
	# Override with saved file if present
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary:
		return
	for id: String in data:
		var arr = data[id]
		_positions[id] = Vector2(float(arr[0]), float(arr[1]))

func _save_positions() -> void:
	var data: Dictionary = {}
	for id: String in _positions:
		data[id] = [_positions[id].x, _positions[id].y]
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		_pos_label.text = "ERROR: could not write to user://"
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	_pos_label.text = "Saved  (%d nodes)  →  user://campaign_node_positions.json" % data.size()

func _export_to_log() -> void:
	print("[CampaignMapEditor] ── Exported positions ──")
	for node in CampaignManager.all_nodes:
		var pos: Vector2 = _positions.get(node.id, node.map_position)
		print('\t"%s": Vector2(%.0f, %.0f),  # %s' % [node.id, pos.x, pos.y, node.title])
	_pos_label.text = "Exported to Godot Output log"

func _reset_positions() -> void:
	for node in CampaignManager.all_nodes:
		_positions[node.id] = node.map_position
		var ctrl := _node_controls.get(node.id) as Control
		if ctrl:
			ctrl.position = node.map_position - Vector2(NODE_W * 0.5, NODE_H * 0.5)
	_rebuild_lines()
	_pos_label.text = "Reset to CampaignManager code defaults"

# ─────────────────────────────────────────────────────────────
# Build UI
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Dim overlay
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.93)
	dimmer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(dimmer)

	_build_header()

	# Scrollable canvas
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = 56.0
	scroll.offset_bottom = -8.0
	scroll.offset_left   = 8.0
	scroll.offset_right  = -8.0
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(scroll)

	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(CANVAS_W, CANVAS_H)
	_canvas.mouse_filter = MOUSE_FILTER_PASS
	scroll.add_child(_canvas)

	# World map background
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture     = load("res://assets/textures/ui/backgrounds/bg_stage_map.png")
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	_canvas.add_child(bg)

	# Canvas size label
	var size_lbl := Label.new()
	size_lbl.text = "Canvas  1860 × 540"
	size_lbl.position = Vector2(8.0, 8.0)
	size_lbl.add_theme_font_size_override("font_size", 10)
	size_lbl.add_theme_color_override("font_color", Color(0.35, 0.5, 0.7, 0.5))
	size_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	_canvas.add_child(size_lbl)

	# Line canvas (behind nodes)
	_line_canvas = LineCanvas.new()
	_line_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_line_canvas.mouse_filter = MOUSE_FILTER_IGNORE
	_canvas.add_child(_line_canvas)

	# Node controls (in front of lines)
	for node in CampaignManager.all_nodes:
		_build_node_control(node)

	_rebuild_lines()

func _build_header() -> void:
	var header := Panel.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 52.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.05, 0.12, 1.0)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.3, 0.6, 1.0, 0.4)
	header.add_theme_stylebox_override("panel", sb)
	add_child(header)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left  = 16.0
	hbox.offset_right = -16.0
	hbox.add_theme_constant_override("separation", 10)
	header.add_child(hbox)

	var title := Label.new()
	title.text = "CAMPAIGN MAP EDITOR"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.5, 0.82, 1.0))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(title)

	var legend := Label.new()
	legend.text = "  X battle   S story   $ reward"
	legend.add_theme_font_size_override("font_size", 11)
	legend.add_theme_color_override("font_color", Color(0.5, 0.6, 0.75, 0.65))
	legend.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(legend)

	_pos_label = Label.new()
	_pos_label.text = "Drag a node to reposition it"
	_pos_label.add_theme_font_size_override("font_size", 12)
	_pos_label.add_theme_color_override("font_color", Color(0.65, 0.8, 1.0, 0.8))
	_pos_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pos_label.custom_minimum_size = Vector2(380, 0)
	hbox.add_child(_pos_label)

	var btns: Array = [
		["SAVE",          _save_positions,  120],
		["EXPORT TO LOG", _export_to_log,   140],
		["RESET",         _reset_positions,  90],
		["CLOSE",         func() -> void: closed.emit(); queue_free(), 90],
	]
	for b: Array in btns:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(b[2], 34)
		btn.pressed.connect(b[1] as Callable)
		hbox.add_child(btn)

# ─────────────────────────────────────────────────────────────
# Node controls
# ─────────────────────────────────────────────────────────────
func _build_node_control(node: CampaignManager.CampaignNode) -> void:
	var ctrl := Panel.new()
	ctrl.size = Vector2(NODE_W, NODE_H)
	ctrl.position = _positions.get(node.id, node.map_position) - Vector2(NODE_W * 0.5, NODE_H * 0.5)
	ctrl.mouse_filter = MOUSE_FILTER_STOP

	var border_col: Color
	match node.node_type:
		CampaignManager.NodeType.BATTLE: border_col = COLOR_BATTLE
		CampaignManager.NodeType.STORY:  border_col = COLOR_STORY
		CampaignManager.NodeType.REWARD: border_col = COLOR_REWARD
		_:                               border_col = Color(0.5, 0.5, 0.6)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.10, 0.22, 0.96)
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.border_color = border_col
	sb.corner_radius_top_left    = 6
	sb.corner_radius_top_right   = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left  = 6
	ctrl.add_theme_stylebox_override("panel", sb)

	# Node ID
	var id_lbl := Label.new()
	id_lbl.text = node.id
	id_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	id_lbl.offset_top    = 4.0
	id_lbl.offset_bottom = 24.0
	id_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	id_lbl.add_theme_font_size_override("font_size", 10)
	id_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	id_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	ctrl.add_child(id_lbl)

	# Type icon
	var type_icon := Label.new()
	match node.node_type:
		CampaignManager.NodeType.BATTLE: type_icon.text = "X"
		CampaignManager.NodeType.STORY:  type_icon.text = "S"
		CampaignManager.NodeType.REWARD: type_icon.text = "$"
	type_icon.set_anchors_preset(Control.PRESET_CENTER)
	type_icon.offset_left   = -12.0
	type_icon.offset_top    = -8.0
	type_icon.offset_right  =  12.0
	type_icon.offset_bottom =  8.0
	type_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_icon.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	type_icon.add_theme_font_size_override("font_size", 14)
	type_icon.add_theme_color_override("font_color", border_col)
	type_icon.mouse_filter = MOUSE_FILTER_IGNORE
	ctrl.add_child(type_icon)

	# Title
	var title_lbl := Label.new()
	title_lbl.text = node.title
	title_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	title_lbl.offset_top    = -22.0
	title_lbl.offset_bottom = -3.0
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 8)
	title_lbl.add_theme_color_override("font_color", Color(0.62, 0.74, 0.9, 0.85))
	title_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	ctrl.add_child(title_lbl)

	# Drag handler
	var node_id := node.id
	ctrl.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton \
				and event.button_index == MOUSE_BUTTON_LEFT \
				and event.pressed:
			_drag_node_id        = node_id
			_drag_start_mouse    = _canvas.get_local_mouse_position()
			_drag_start_node_pos = ctrl.position
			ctrl.move_to_front()
			get_viewport().set_input_as_handled()
	)

	_canvas.add_child(ctrl)
	_node_controls[node.id] = ctrl

# ─────────────────────────────────────────────────────────────
# Drag tracking
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _drag_node_id == "":
		return

	if event is InputEventMouseMotion:
		var ctrl := _node_controls.get(_drag_node_id) as Control
		if ctrl and _canvas:
			var delta   := _canvas.get_local_mouse_position() - _drag_start_mouse
			var new_pos := _drag_start_node_pos + delta
			new_pos.x = clampf(new_pos.x, 0.0, CANVAS_W - NODE_W)
			new_pos.y = clampf(new_pos.y, 0.0, CANVAS_H - NODE_H)
			ctrl.position = new_pos
			var center := new_pos + Vector2(NODE_W * 0.5, NODE_H * 0.5)
			_positions[_drag_node_id] = center
			_pos_label.text = "%s  →  x: %.0f  y: %.0f" % [_drag_node_id, center.x, center.y]
			_rebuild_lines()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		_drag_node_id = ""

# ─────────────────────────────────────────────────────────────
# Line rendering
# ─────────────────────────────────────────────────────────────
func _rebuild_lines() -> void:
	var line_data: Array = []
	for node in CampaignManager.all_nodes:
		for conn_id: String in node.connections:
			if conn_id == node.id:
				continue  # skip self-loops (placeholder data)
			var target := CampaignManager.get_node_data(conn_id)
			if target == null:
				continue
			line_data.append({
				"from":  _positions.get(node.id, node.map_position),
				"to":    _positions.get(conn_id, target.map_position),
				"color": Color(0.35, 0.62, 1.0, 0.45),
			})
	_line_canvas.set_lines(line_data)
