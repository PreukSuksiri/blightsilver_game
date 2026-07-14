extends Control
class_name DetectiveNoteVerdictMap
## Shared verdict map renderer — the single source of truth for how a topic's
## mind map looks. Used by:
##   • DetectiveNoteOverlay (player: drag clues onto frames / read-only when stamped)
##   • DetectiveNoteVaultManager layout editor (admin: WYSIWYG node drag + edge draw)
##
## Frames, connecting lines, arrowheads and labels are drawn procedurally in a
## thick "whiteboard marker" style with deterministic hand-drawn jitter.
## Node/edge visibility honors min_level (verdict map upgrades).
##
## Modes:
##   PLAYER   — node frames accept clue drops, placed clues can be dragged off/moved
##   READONLY — display only (stamped topics, VN stamp view, admin preview)
##   EDIT     — left-drag moves nodes, right-drag from node to node creates an edge

signal clue_drop_requested(node_id: String, clue_id: String, from_node: String)
signal node_hover_started(node_id: String, clue_id: String, hit: Control)
signal node_hover_ended
signal edit_node_moved(node_id: String, new_pos: Vector2)
signal edit_edge_created(from_id: String, to_id: String)
signal stamp_animation_finished

enum Mode { PLAYER, READONLY, EDIT }

const MARKER_COLOR := Color(0.14, 0.12, 0.11)
const MARKER_WIDTH := 5.0
const JITTER_PX := 2.0
const SEGMENT_LEN := 16.0
const ARROW_LEN := 18.0
const ARROW_SPREAD := 0.5
const EDGE_GAP := 8.0
const CONTENT_MARGIN := 90.0
const NODE_LABEL_SIZE := 23
const NODE_LABEL_PAD_TOP := 4.0
const NODE_LABEL_PAD_BOTTOM := 14.0
const NODE_LABEL_PAD_SIDE := 8.0
const EDGE_LABEL_SIZE := 21
const CLUE_NAME_SIZE := 14
const POSTIT_COLOR := Color(0.99, 0.90, 0.45)
const POSTIT_TEXT := Color(0.16, 0.13, 0.05)
const APPROVED_COLOR := Color(0.72, 0.07, 0.07)
const STAMP_SIZE := 150.0
const STAMP_MARGIN := Vector2(46.0, 26.0)
const STAMP_POP_SCALE := 1.35
const STAMP_LOGO_FADE_SEC := 0.28
const STAMP_POP_GROW_SEC := 0.38
const STAMP_POP_SHRINK_SEC := 0.48
const STAMP_APPROVED_POP_GROW_SEC := 0.34
const STAMP_APPROVED_POP_SHRINK_SEC := 0.44
const STAMP_BETWEEN_SEC := 0.28
const STAMP_NAME_DELAY_SEC := 0.28
const NAME_TYPE_SEC := 0.05
const PREFILL_LOCK_SIZE := 22.0
const PREFILL_LOCK_INSET := 5.0
const DRAG_PREVIEW_SIZE := Vector2(120.0, 120.0)
const DRAG_PREVIEW_ALPHA := 0.82

var mode: int = Mode.PLAYER
var locale: String = "en"
var drag_ghost_show: Callable = Callable()
var drag_ghost_hide: Callable = Callable()

var _topic: Dictionary = {}
var _level: int = 1
var _placements: Dictionary = {}
var _nodes: Array = []
var _edges: Array = []
var _hit_areas: Dictionary = {}
var _hand_font: Font = null
var _texture_cache: Dictionary = {}

# EDIT-mode interaction state
var _drag_node_id: String = ""
var _drag_offset: Vector2 = Vector2.ZERO
var _edge_drag_from: String = ""
var _edge_drag_pos: Vector2 = Vector2.ZERO

# Stamp display
var _stamp_root: Control = null
var _stamp_cluster: Control = null
var _stamp_tex: TextureRect = null
var _approved_lbl: Label = null
var _stamp_name_lbl: Label = null


## Node frame hit area: forwards drag/drop and input to the owning map.
class NodeHit extends Control:
	var map: DetectiveNoteVerdictMap = null
	var node_id: String = ""

	func _get_drag_data(_at: Vector2) -> Variant:
		return map._node_get_drag_data(node_id, self)

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return map._node_can_drop(node_id, data)

	func _drop_data(_at: Vector2, data: Variant) -> void:
		map._node_drop(node_id, data)

	func _gui_input(event: InputEvent) -> void:
		map._node_gui_input(node_id, self, event)


func _ready() -> void:
	_hand_font = FontManager.make_font("handwritten", 700)
	mouse_filter = Control.MOUSE_FILTER_STOP


## (Re)build the map from topic data. placements: node_id → clue_id (player
## progress; prefilled nodes resolve from node data automatically).
func setup(topic: Dictionary, level: int, p_mode: int, placements: Dictionary = {}) -> void:
	_topic = topic.duplicate(true)
	_level = maxi(level, 1)
	mode = p_mode
	_placements = placements.duplicate()
	_rebuild()


func set_placements(placements: Dictionary) -> void:
	_placements = placements.duplicate()
	queue_redraw()


func get_topic() -> Dictionary:
	return _topic.duplicate(true)


func _rebuild() -> void:
	_nodes = DetectiveNoteVault.nodes_for_level(_topic, _level)
	_edges = DetectiveNoteVault.edges_for_level(_topic, _level)
	for hit: Variant in _hit_areas.values():
		(hit as Control).queue_free()
	_hit_areas.clear()
	for node: Dictionary in _nodes:
		var nid: String = str(node.get("id", ""))
		var hit := NodeHit.new()
		hit.map = self
		hit.node_id = nid
		hit.position = _node_rect(node).position
		hit.size = _node_rect(node).size
		hit.mouse_filter = Control.MOUSE_FILTER_STOP
		hit.mouse_entered.connect(func() -> void:
			emit_signal("node_hover_started", nid, effective_clue(nid), hit))
		hit.mouse_exited.connect(func() -> void:
			emit_signal("node_hover_ended"))
		add_child(hit)
		_hit_areas[nid] = hit
	var extent := content_extent()
	custom_minimum_size = extent
	size = extent
	queue_redraw()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var node_id: String = _pick_drop_node(at_position)
	return not node_id.is_empty() and _node_can_drop(node_id, data)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var node_id: String = _pick_drop_node(at_position)
	if not node_id.is_empty():
		_node_drop(node_id, data)


func _pick_drop_node(local_pos: Vector2) -> String:
	if mode != Mode.PLAYER:
		return ""
	for node: Dictionary in _nodes:
		var nid: String = str(node.get("id", ""))
		if _node_rect(node).has_point(local_pos):
			return nid
	return ""


func content_extent() -> Vector2:
	var extent := Vector2(320.0, 240.0)
	for node: Dictionary in _nodes:
		var r := _node_rect(node)
		extent.x = maxf(extent.x, r.end.x + CONTENT_MARGIN)
		extent.y = maxf(extent.y, r.end.y + CONTENT_MARGIN)
	return extent


func _node_rect(node: Dictionary) -> Rect2:
	var pos: Array = node.get("pos", [0, 0]) as Array if node.get("pos", null) is Array else [0, 0]
	var sz: Array = node.get("size", []) as Array if node.get("size", null) is Array else []
	var w: float = float(sz[0]) if sz.size() > 0 else DetectiveNoteVault.DEFAULT_NODE_SIZE.x
	var h: float = float(sz[1]) if sz.size() > 1 else DetectiveNoteVault.DEFAULT_NODE_SIZE.y
	return Rect2(float(pos[0]) if pos.size() > 0 else 0.0,
		float(pos[1]) if pos.size() > 1 else 0.0, w, h)


func _find_node(node_id: String) -> Dictionary:
	for node: Dictionary in _nodes:
		if str(node.get("id", "")) == node_id:
			return node
	return {}


## Clue displayed on the node: authored prefill wins, then player placement.
func effective_clue(node_id: String) -> String:
	var node: Dictionary = _find_node(node_id)
	var prefill: String = str(node.get("prefill", "")).strip_edges()
	if not prefill.is_empty():
		return prefill
	return str(_placements.get(node_id, ""))


## True when every visible (level-unlocked) frame has a clue — prefill or placement.
func is_map_fully_filled() -> bool:
	if _nodes.is_empty():
		return false
	for node_v: Variant in _nodes:
		if not node_v is Dictionary:
			continue
		var nid: String = str((node_v as Dictionary).get("id", "")).strip_edges()
		if nid.is_empty():
			continue
		if effective_clue(nid).is_empty():
			return false
	return true


func is_node_prefilled(node_id: String) -> bool:
	return not str(_find_node(node_id).get("prefill", "")).strip_edges().is_empty()


func can_remove_placement(node_id: String) -> bool:
	if mode != Mode.PLAYER:
		return false
	if is_node_prefilled(node_id):
		return false
	return not str(_placements.get(node_id, "")).is_empty()


# ─────────────────────────────────────────────────────────────
# Drawing
# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	for edge: Dictionary in _edges:
		_draw_edge(edge)
	for node: Dictionary in _nodes:
		_draw_node(node)
	if mode == Mode.EDIT and not _edge_drag_from.is_empty():
		var from_node: Dictionary = _find_node(_edge_drag_from)
		if not from_node.is_empty():
			draw_line(_node_rect(from_node).get_center(), _edge_drag_pos,
				Color(MARKER_COLOR, 0.5), MARKER_WIDTH * 0.7, true)


func _draw_node(node: Dictionary) -> void:
	var nid: String = str(node.get("id", ""))
	var rect := _node_rect(node)
	_draw_marker_rect(rect, nid)

	var label: String = DetectiveNoteVault.loc_text(node.get("label", ""), locale)
	if not label.is_empty():
		_draw_node_label(rect, label, DetectiveNoteVault.node_label_side(node))

	var clue_id: String = effective_clue(nid)
	if not clue_id.is_empty():
		var clue: Dictionary = DetectiveNoteVault.get_clue(clue_id)
		if not clue.is_empty():
			var inner := rect.grow(-10.0)
			var name_text: String = DetectiveNoteVault.clue_display_name(clue, locale)
			if DetectiveNoteVault.clue_is_messenger(clue):
				var icon_tex: Texture2D = _get_texture(DetectiveNoteVault.MESSENGER_CLUE_ICON)
				if icon_tex != null:
					var icon_area := Rect2(inner.position, Vector2(inner.size.x, inner.size.y - 22.0))
					draw_texture_rect(icon_tex, _fit_rect(icon_tex.get_size(), icon_area), false)
				if _hand_font != null and not name_text.is_empty():
					draw_string(_hand_font,
						Vector2(inner.position.x, inner.end.y - 4.0),
						name_text, HORIZONTAL_ALIGNMENT_CENTER, inner.size.x,
						CLUE_NAME_SIZE, MARKER_COLOR)
			elif DetectiveNoteVault.clue_is_postit(clue):
				draw_rect(Rect2(inner.position, inner.size), POSTIT_COLOR)
				if _hand_font != null:
					draw_multiline_string(_hand_font,
						Vector2(inner.position.x + 6.0, inner.position.y + 24.0),
						name_text, HORIZONTAL_ALIGNMENT_CENTER, inner.size.x - 12.0,
						CLUE_NAME_SIZE + 2, -1, POSTIT_TEXT)
			else:
				var img_path: String = str(clue.get("image", "")).strip_edges()
				var tex: Texture2D = _get_texture(img_path)
				if tex != null:
					var img_area := Rect2(inner.position, Vector2(inner.size.x, inner.size.y - 22.0))
					draw_texture_rect(tex, _fit_rect(tex.get_size(), img_area), false)
				if _hand_font != null and not name_text.is_empty():
					draw_string(_hand_font,
						Vector2(inner.position.x, inner.end.y - 4.0),
						name_text, HORIZONTAL_ALIGNMENT_CENTER, inner.size.x,
						CLUE_NAME_SIZE, MARKER_COLOR)

	if is_node_prefilled(nid):
		_draw_prefill_lock(rect)


func _draw_node_label(rect: Rect2, text: String, side: String) -> void:
	if text.is_empty() or _hand_font == null:
		return
	var text_size: Vector2 = _hand_font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, NODE_LABEL_SIZE)
	var descent: float = absf(_hand_font.get_descent(NODE_LABEL_SIZE))
	var ascent: float = _hand_font.get_ascent(NODE_LABEL_SIZE)
	var center_x: float = rect.position.x + rect.size.x * 0.5 - text_size.x * 0.5
	match side:
		"bottom":
			var pos := Vector2(center_x, rect.end.y + NODE_LABEL_PAD_BOTTOM + ascent)
			draw_string(_hand_font, pos, text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, NODE_LABEL_SIZE, MARKER_COLOR)
		"left":
			var mid := Vector2(rect.position.x - NODE_LABEL_PAD_SIDE, rect.position.y + rect.size.y * 0.5)
			var label_pos := Vector2(-text_size.x * 0.5, -text_size.y * 0.5)
			draw_set_transform(mid, -PI * 0.5, Vector2.ONE)
			draw_string(_hand_font, label_pos, text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, NODE_LABEL_SIZE, MARKER_COLOR)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"right":
			var mid_r := Vector2(rect.end.x + NODE_LABEL_PAD_SIDE, rect.position.y + rect.size.y * 0.5)
			var label_pos_r := Vector2(-text_size.x * 0.5, -text_size.y * 0.5)
			draw_set_transform(mid_r, PI * 0.5, Vector2.ONE)
			draw_string(_hand_font, label_pos_r, text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, NODE_LABEL_SIZE, MARKER_COLOR)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_:
			var pos_top := Vector2(center_x, rect.position.y - NODE_LABEL_PAD_TOP - descent)
			draw_string(_hand_font, pos_top, text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, NODE_LABEL_SIZE, MARKER_COLOR)


func _draw_prefill_lock(rect: Rect2) -> void:
	var origin := rect.position + Vector2(PREFILL_LOCK_INSET, PREFILL_LOCK_INSET)
	var s := PREFILL_LOCK_SIZE
	var lock_tex: Texture2D = null
	if not DetectiveNoteVault.PREFILL_LOCK_ICON.is_empty():
		lock_tex = _get_texture(DetectiveNoteVault.PREFILL_LOCK_ICON)
	if lock_tex != null:
		draw_texture_rect(lock_tex, Rect2(origin, Vector2(s, s)), false)
		return
	var badge := Rect2(origin - Vector2(1.0, 1.0), Vector2(s + 2.0, s + 2.0))
	draw_rect(badge, Color(0.97, 0.94, 0.86, 0.95), true)
	draw_rect(badge, MARKER_COLOR, false, 2.0)
	var cx := origin.x + s * 0.5
	var shackle_y := origin.y + s * 0.36
	draw_arc(Vector2(cx, shackle_y), s * 0.2, PI, TAU, 10, MARKER_COLOR, 2.2, true)
	var body := Rect2(origin.x + s * 0.3, origin.y + s * 0.44, s * 0.4, s * 0.46)
	draw_rect(body, Color(0.5, 0.47, 0.42), true)
	draw_rect(body, MARKER_COLOR, false, 2.0)
	draw_circle(body.get_center() + Vector2(0.0, body.size.y * 0.12), 1.8, MARKER_COLOR)


func _draw_edge(edge: Dictionary) -> void:
	var from_node: Dictionary = _find_node(str(edge.get("from", "")))
	var to_node: Dictionary = _find_node(str(edge.get("to", "")))
	if from_node.is_empty() or to_node.is_empty():
		return
	var from_rect := _node_rect(from_node)
	var to_rect := _node_rect(to_node)
	var a := from_rect.get_center()
	var b := to_rect.get_center()
	if a.distance_to(b) < 1.0:
		return
	var p1 := _rect_boundary_point(from_rect, b) + (b - a).normalized() * EDGE_GAP
	var p2 := _rect_boundary_point(to_rect, a) + (a - b).normalized() * EDGE_GAP
	var seed_key: String = "%s>%s" % [str(edge.get("from", "")), str(edge.get("to", ""))]
	_draw_marker_line(p1, p2, seed_key)

	var arrow: String = str(edge.get("arrow", "none"))
	if arrow == "end" or arrow == "both":
		_draw_arrowhead(p2, (p2 - p1).normalized())
	if arrow == "start" or arrow == "both":
		_draw_arrowhead(p1, (p1 - p2).normalized())

	var label: String = DetectiveNoteVault.loc_text(edge.get("label", ""), locale)
	if not label.is_empty():
		_draw_edge_label(p1, p2, label)


func _readable_line_angle(dir: Vector2) -> float:
	var angle := dir.angle()
	if angle > PI * 0.5:
		angle -= PI
	elif angle < -PI * 0.5:
		angle += PI
	return angle


func _draw_edge_label(p1: Vector2, p2: Vector2, text: String) -> void:
	if text.is_empty() or _hand_font == null:
		return
	var dir := p2 - p1
	var length := dir.length()
	if length < 1.0:
		return
	dir /= length
	var mid := (p1 + p2) * 0.5
	var angle := _readable_line_angle(dir)
	var text_size: Vector2 = _hand_font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, EDGE_LABEL_SIZE)
	# Local -Y nudges the label slightly off the ink while staying parallel to the line.
	var label_pos := Vector2(-text_size.x * 0.5, -text_size.y * 0.5 - 6.0)
	draw_set_transform(mid, angle, Vector2.ONE)
	draw_string(_hand_font, label_pos, text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, EDGE_LABEL_SIZE, MARKER_COLOR)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_arrowhead(tip: Vector2, dir: Vector2) -> void:
	var back := -dir * ARROW_LEN
	draw_line(tip, tip + back.rotated(ARROW_SPREAD), MARKER_COLOR, MARKER_WIDTH, true)
	draw_line(tip, tip + back.rotated(-ARROW_SPREAD), MARKER_COLOR, MARKER_WIDTH, true)


## Point where the segment (rect center → toward) crosses the rect boundary.
func _rect_boundary_point(rect: Rect2, toward: Vector2) -> Vector2:
	var center := rect.get_center()
	var d := toward - center
	if absf(d.x) < 0.001 and absf(d.y) < 0.001:
		return center
	var half := rect.size * 0.5
	var tx: float = half.x / absf(d.x) if absf(d.x) > 0.001 else INF
	var ty: float = half.y / absf(d.y) if absf(d.y) > 0.001 else INF
	return center + d * minf(tx, ty)


## Thick marker line with deterministic hand-drawn wobble.
func _draw_marker_line(p1: Vector2, p2: Vector2, seed_key: String) -> void:
	var points := _jittered_points(p1, p2, seed_key)
	draw_polyline(points, MARKER_COLOR, MARKER_WIDTH, true)


func _draw_marker_rect(rect: Rect2, seed_key: String) -> void:
	var corners: Array[Vector2] = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]
	var points := PackedVector2Array()
	for i: int in range(4):
		var side := _jittered_points(corners[i], corners[(i + 1) % 4], "%s#%d" % [seed_key, i])
		side.remove_at(side.size() - 1)  # avoid duplicating corners
		points.append_array(side)
	points.append(points[0])
	draw_polyline(points, MARKER_COLOR, MARKER_WIDTH, true)


func _jittered_points(p1: Vector2, p2: Vector2, seed_key: String) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_key)
	var length := p1.distance_to(p2)
	var segments: int = maxi(int(length / SEGMENT_LEN), 1)
	var perp := (p2 - p1).normalized().orthogonal()
	var points := PackedVector2Array()
	for i: int in range(segments + 1):
		var t := float(i) / float(segments)
		var pt := p1.lerp(p2, t)
		if i > 0 and i < segments:
			pt += perp * rng.randf_range(-JITTER_PX, JITTER_PX)
		points.append(pt)
	return points


func _fit_rect(tex_size: Vector2, area: Rect2) -> Rect2:
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return area
	var scale_f := minf(area.size.x / tex_size.x, area.size.y / tex_size.y)
	var fitted := tex_size * scale_f
	return Rect2(area.position + (area.size - fitted) * 0.5, fitted)


func _get_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_texture_cache[path] = tex
	return tex


# ─────────────────────────────────────────────────────────────
# PLAYER mode — drag & drop
# ─────────────────────────────────────────────────────────────
func _node_get_drag_data(node_id: String, hit: Control) -> Variant:
	if mode != Mode.PLAYER:
		return null
	if is_node_prefilled(node_id):
		return null
	var clue_id: String = str(_placements.get(node_id, ""))
	if clue_id.is_empty():
		return null
	hit.set_drag_preview(make_drag_preview_stub())
	if drag_ghost_show.is_valid():
		drag_ghost_show.call(clue_id)
	return {"detective_clue": clue_id, "from_node": node_id}


func _node_can_drop(node_id: String, data: Variant) -> bool:
	if mode != Mode.PLAYER:
		return false
	if not data is Dictionary or not (data as Dictionary).has("detective_clue"):
		return false
	if is_node_prefilled(node_id):
		return false
	var clue_id: String = str((data as Dictionary).get("detective_clue", ""))
	var node: Dictionary = _find_node(node_id)
	return DetectiveNoteVault.node_accepts_kind(node, DetectiveNoteVault.get_clue_kind(clue_id))


func _node_drop(node_id: String, data: Variant) -> void:
	var d: Dictionary = data as Dictionary
	emit_signal("clue_drop_requested", node_id,
		str(d.get("detective_clue", "")), str(d.get("from_node", "")))


## Invisible drag preview for Godot's drag API — the cursor ghost is drawn separately.
func make_drag_preview_stub() -> Control:
	var stub := Control.new()
	stub.custom_minimum_size = DRAG_PREVIEW_SIZE
	stub.size = DRAG_PREVIEW_SIZE
	stub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stub.modulate = Color(1.0, 1.0, 1.0, 0.0)
	return stub


## Cursor-following ghost (also used as the logical preview size for drag).
func build_drag_ghost(clue_id: String) -> Control:
	var ghost := Control.new()
	ghost.custom_minimum_size = DRAG_PREVIEW_SIZE
	ghost.size = DRAG_PREVIEW_SIZE
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var clue: Dictionary = DetectiveNoteVault.get_clue(clue_id)
	if DetectiveNoteVault.clue_is_postit(clue):
		_add_drag_ghost_child(ghost, _make_blank_postit_drag_preview())
		return ghost

	var tex: Texture2D = null
	if DetectiveNoteVault.clue_is_messenger(clue):
		tex = _get_texture(DetectiveNoteVault.MESSENGER_CLUE_ICON)
	else:
		var img_path: String = str(clue.get("image", "")).strip_edges()
		if not img_path.is_empty():
			tex = _get_texture(img_path)
	if tex != null:
		_add_drag_ghost_child(ghost, _make_image_drag_preview(tex))
	else:
		_add_drag_ghost_child(ghost, _make_blank_postit_drag_preview())
	return ghost


func _add_drag_ghost_child(ghost: Control, child: Control) -> void:
	child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.add_child(child)


func _make_image_drag_preview(tex: Texture2D) -> TextureRect:
	var art := TextureRect.new()
	art.texture = tex
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.modulate = Color(1.0, 1.0, 1.0, DRAG_PREVIEW_ALPHA)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


func _make_blank_postit_drag_preview() -> ColorRect:
	var postit := ColorRect.new()
	postit.color = Color(POSTIT_COLOR, DRAG_PREVIEW_ALPHA)
	postit.custom_minimum_size = DRAG_PREVIEW_SIZE
	postit.size = DRAG_PREVIEW_SIZE
	postit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return postit


# ─────────────────────────────────────────────────────────────
# EDIT mode — WYSIWYG node drag + edge creation
# ─────────────────────────────────────────────────────────────
func _node_gui_input(node_id: String, hit: Control, event: InputEvent) -> void:
	if mode == Mode.PLAYER:
		if event is InputEventMouseButton:
			var mbe := event as InputEventMouseButton
			if mbe.pressed and can_remove_placement(node_id):
				if mbe.button_index == MOUSE_BUTTON_RIGHT \
						or (mbe.button_index == MOUSE_BUTTON_LEFT and mbe.double_click):
					emit_signal("clue_drop_requested", node_id, "", "")
					hit.accept_event()
		return
	if mode != Mode.EDIT:
		return
	if event is InputEventMouseButton:
		var mbe := event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT:
			if mbe.pressed:
				_drag_node_id = node_id
				_drag_offset = mbe.position
			else:
				if _drag_node_id == node_id:
					_drag_node_id = ""
					emit_signal("edit_node_moved", node_id, hit.position)
			hit.accept_event()
		elif mbe.button_index == MOUSE_BUTTON_RIGHT:
			if mbe.pressed:
				_edge_drag_from = node_id
				_edge_drag_pos = hit.position + mbe.position
				queue_redraw()
			else:
				_finish_edge_drag(hit.position + mbe.position)
			hit.accept_event()
	elif event is InputEventMouseMotion:
		var mme := event as InputEventMouseMotion
		if _drag_node_id == node_id:
			var new_pos: Vector2 = hit.position + mme.position - _drag_offset
			new_pos.x = maxf(new_pos.x, 0.0)
			new_pos.y = maxf(new_pos.y, 40.0)  # keep room for the label above
			# The notebook scrolls vertically only — keep nodes reachable
			# within the fixed horizontal bounds.
			if size.x > hit.size.x:
				new_pos.x = minf(new_pos.x, size.x - hit.size.x)
			hit.position = new_pos
			_set_node_pos(node_id, new_pos)
			custom_minimum_size = content_extent()
			queue_redraw()
		elif _edge_drag_from == node_id:
			_edge_drag_pos = hit.position + mme.position
			queue_redraw()


func _finish_edge_drag(release_pos: Vector2) -> void:
	var from_id := _edge_drag_from
	_edge_drag_from = ""
	queue_redraw()
	if from_id.is_empty():
		return
	for node: Dictionary in _nodes:
		var nid: String = str(node.get("id", ""))
		if nid == from_id:
			continue
		if _node_rect(node).has_point(release_pos):
			emit_signal("edit_edge_created", from_id, nid)
			return


func _set_node_pos(node_id: String, pos: Vector2) -> void:
	for arr: Array in [_nodes, _topic.get("nodes", []) as Array]:
		for node: Variant in arr:
			if node is Dictionary and str((node as Dictionary).get("id", "")) == node_id:
				(node as Dictionary)["pos"] = [int(round(pos.x)), int(round(pos.y))]


## Apply an externally created edge (layout editor keeps the map in sync).
func add_edge(edge: Dictionary) -> void:
	if not _topic.get("edges", null) is Array:
		_topic["edges"] = []
	(_topic["edges"] as Array).append(edge.duplicate(true))
	_edges = DetectiveNoteVault.edges_for_level(_topic, _level)
	queue_redraw()


# ─────────────────────────────────────────────────────────────
# Stamp (APPROVED) — permanent display + one-shot animation
# ─────────────────────────────────────────────────────────────
func show_stamp(stamp_id: String, animate: bool = false, angle_deg: float = 0.0) -> void:
	clear_stamp()
	var stamp: Dictionary = DetectiveNoteVault.get_stamp(stamp_id)
	if stamp.is_empty():
		return
	_stamp_root = Control.new()
	_stamp_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Anchored to the top-right of the note content.
	_stamp_root.anchor_left = 1.0
	_stamp_root.anchor_right = 1.0
	_stamp_root.offset_left = -(STAMP_SIZE + STAMP_MARGIN.x)
	_stamp_root.offset_right = -STAMP_MARGIN.x
	_stamp_root.offset_top = STAMP_MARGIN.y
	_stamp_root.offset_bottom = STAMP_MARGIN.y + STAMP_SIZE + 96.0
	add_child(_stamp_root)

	_stamp_cluster = Control.new()
	_stamp_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamp_cluster.size = Vector2(STAMP_SIZE + 80.0, STAMP_SIZE + 96.0)
	_stamp_cluster.pivot_offset = Vector2(STAMP_SIZE * 0.5, STAMP_SIZE * 0.5)
	_stamp_cluster.rotation = deg_to_rad(angle_deg)
	_stamp_root.add_child(_stamp_cluster)

	_stamp_tex = TextureRect.new()
	_stamp_tex.texture = _get_texture(str(stamp.get("image", "")))
	_stamp_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stamp_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stamp_tex.size = Vector2(STAMP_SIZE, STAMP_SIZE)
	_stamp_tex.pivot_offset = _stamp_tex.size * 0.5
	_stamp_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamp_cluster.add_child(_stamp_tex)

	_approved_lbl = Label.new()
	_approved_lbl.text = "APPROVED"
	_approved_lbl.add_theme_font_override("font", _hand_font)
	_approved_lbl.add_theme_font_size_override("font_size", 30)
	_approved_lbl.add_theme_color_override("font_color", APPROVED_COLOR)
	_approved_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_approved_lbl.position = Vector2(-40.0, STAMP_SIZE - 26.0)  # overlaps stamp bottom
	_approved_lbl.size = Vector2(STAMP_SIZE + 80.0, 36.0)
	_approved_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamp_cluster.add_child(_approved_lbl)

	_stamp_name_lbl = Label.new()
	_stamp_name_lbl.text = DetectiveNoteVault.loc_text(stamp.get("name", ""), locale)
	_stamp_name_lbl.add_theme_font_override("font", _hand_font)
	_stamp_name_lbl.add_theme_font_size_override("font_size", 20)
	_stamp_name_lbl.add_theme_color_override("font_color", MARKER_COLOR)
	_stamp_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stamp_name_lbl.position = Vector2(-40.0, STAMP_SIZE + 10.0)
	_stamp_name_lbl.size = Vector2(STAMP_SIZE + 80.0, 28.0)
	_stamp_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamp_cluster.add_child(_stamp_name_lbl)

	if animate:
		_play_stamp_animation()


func clear_stamp() -> void:
	if _stamp_root != null and is_instance_valid(_stamp_root):
		_stamp_root.queue_free()
	_stamp_root = null
	_stamp_cluster = null
	_stamp_tex = null
	_approved_lbl = null
	_stamp_name_lbl = null


func has_stamp_visible() -> bool:
	return _stamp_root != null and is_instance_valid(_stamp_root)


func _play_stamp_animation() -> void:
	_approved_lbl.visible = false
	var full_name: String = _stamp_name_lbl.text
	_stamp_name_lbl.text = ""

	# 1) Logo appears at normal size.
	_stamp_tex.scale = Vector2.ONE
	_stamp_tex.modulate.a = 0.0
	var logo_intro := create_tween()
	logo_intro.tween_property(_stamp_tex, "modulate:a", 1.0, STAMP_LOGO_FADE_SEC)
	await logo_intro.finished
	if _stamp_tex == null or not is_instance_valid(_stamp_tex):
		return

	# 2) Logo stamp impact — slam + enlarge, then settle.
	SFXManager.play(SFXManager.SFX_STAMP, SFXManager.SFX_STAMP_VOLUME)
	await _pulse_control_scale(_stamp_tex, STAMP_POP_SCALE, STAMP_POP_GROW_SEC, STAMP_POP_SHRINK_SEC)

	await get_tree().create_timer(STAMP_BETWEEN_SEC).timeout
	if _approved_lbl == null or not is_instance_valid(_approved_lbl):
		return

	# 3) APPROVED stamp impact — same slam + pulse.
	_approved_lbl.pivot_offset = _approved_lbl.size * 0.5
	_approved_lbl.scale = Vector2.ONE
	_approved_lbl.modulate.a = 1.0
	_approved_lbl.visible = true
	SFXManager.play(SFXManager.SFX_STAMP, SFXManager.SFX_STAMP_VOLUME)
	await _pulse_control_scale(
		_approved_lbl, STAMP_POP_SCALE, STAMP_APPROVED_POP_GROW_SEC, STAMP_APPROVED_POP_SHRINK_SEC)

	# 4) Approver name types in.
	await get_tree().create_timer(STAMP_NAME_DELAY_SEC).timeout
	for i: int in range(full_name.length()):
		if _stamp_name_lbl == null or not is_instance_valid(_stamp_name_lbl):
			return
		_stamp_name_lbl.text = full_name.substr(0, i + 1)
		var ch: String = full_name.substr(i, 1)
		if not ch.strip_edges().is_empty():
			SFXManager.play(SFXManager.SFX_TYPEWRITER, SFXManager.SFX_TYPEWRITER_VOLUME)
		await get_tree().create_timer(NAME_TYPE_SEC).timeout
	emit_signal("stamp_animation_finished")


func _pulse_control_scale(ctrl: Control, peak_scale: float, grow_sec: float, shrink_sec: float) -> void:
	if ctrl == null or not is_instance_valid(ctrl):
		return
	ctrl.scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(ctrl, "scale", Vector2.ONE * peak_scale, grow_sec) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ctrl, "scale", Vector2.ONE, shrink_sec) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
