extends Control
# Full-screen spinning wheel overlay for daily dungeon wheel nodes.
# Visual: parchment slices + burnt dividers + tucked hub + leather frame (horror/mystery tone).
# Spins through weighted outcomes, then emits finished(outcome_key).

signal finished(outcome_key: String)

const SPIN_DURATION: float = 8.5
const SPIN_PAUSE: float = 1.5
const FULL_ROTATIONS: float = 8.0
const WHEEL_FONT := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")
const PAPER_TEX: Texture2D = preload("res://assets/textures/daily_dungeon/wheel/parchment_paper.png")
const LEATHER_FRAME_TEX: Texture2D = preload("res://assets/textures/daily_dungeon/wheel/leather_mirror_frame.png")
const SPIN_HAND_TEX: Texture2D = preload("res://assets/textures/daily_dungeon/wheel/spin_hand.png")
const SFX_SPIN_WHEEL: AudioStream = preload("res://assets/audio/sfx/spin_wheel.mp3")

# Measured from spin_hand.png (413×604) — center of the bottom mounting hole ("donut").
const SPIN_HAND_TEX_SIZE := Vector2(413.0, 604.0)
const SPIN_HAND_PIVOT_TEX := Vector2(206.5, 521.0)

# Measured from leather_mirror_frame.png (1536×1024).
const FRAME_TEX_SIZE := Vector2(1536.0, 1024.0)
const FRAME_INNER_RADIUS_TEX: float = 404.0
const FRAME_OUTER_RADIUS_TEX: float = 489.0

# Muted horror palette — no per-modifier color coding on slices.
const COLOR_DIM := Color(0.01, 0.02, 0.05, 0.84)
const COLOR_TITLE := Color(0.78, 0.74, 0.68, 1.0)
const COLOR_PAPER_TINT := Color(0.86, 0.82, 0.74, 1.0)

var _outcomes: Array = []
var _win_idx: int = 0
var _wheel_pivot: Control = null
var _spinning: bool = false
var _wheel_font: Font = null
var _wheel_radius: float = 210.0
var _tick_seg: float = 0.0
var _prev_rot: float = 0.0


func setup(outcomes: Array) -> void:
	_outcomes = outcomes.duplicate()
	if _outcomes.is_empty():
		_outcomes = ["no_effect"]
	_win_idx = randi() % _outcomes.size()


func _make_bold_font() -> Font:
	var fv := FontVariation.new()
	fv.base_font = WHEEL_FONT
	fv.variation_opentype = {"wght": 800}
	return fv


func _compute_layout() -> Dictionary:
	var vp: Vector2 = get_viewport_rect().size
	var margin: float = 28.0
	var title_space: float = 52.0
	var avail: float = minf(vp.x - margin * 2.0, vp.y - margin * 2.0 - title_space)
	avail = maxf(avail, 320.0)
	# Scale frame texture so its outer leather ring fills the viewport.
	var outer_diameter: float = avail * 0.94
	var tex_scale: float = outer_diameter / (FRAME_OUTER_RADIUS_TEX * 2.0)
	var wheel_radius: float = FRAME_INNER_RADIUS_TEX * tex_scale
	var frame_size: Vector2 = FRAME_TEX_SIZE * tex_scale
	return {
		"wheel_radius": wheel_radius,
		"frame_size": frame_size,
		"title_font": maxi(20, int(avail * 0.030)),
	}


func _ready() -> void:
	_wheel_font = _make_bold_font()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 85

	var layout: Dictionary = _compute_layout()
	_wheel_radius = float(layout["wheel_radius"])
	var frame_size: Vector2 = layout["frame_size"]
	var title_font: int = int(layout["title_font"])
	var frame_half := frame_size * 0.5

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = COLOR_DIM
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := Control.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -(frame_half.x + 8.0)
	center.offset_right = frame_half.x + 8.0
	center.offset_top = -(frame_half.y + title_space_for_center(title_font))
	center.offset_bottom = frame_half.y + 12.0
	add_child(center)

	var title := Label.new()
	title.text = "WHEEL OF FORTUNE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = -title_font - 18.0
	title.offset_bottom = -6.0
	title.add_theme_font_override("font", _wheel_font)
	title.add_theme_font_size_override("font_size", title_font)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.add_theme_constant_override("shadow_outline_size", 4)
	center.add_child(title)

	_wheel_pivot = Control.new()
	_wheel_pivot.set_anchors_preset(Control.PRESET_CENTER)
	_wheel_pivot.offset_left = -_wheel_radius
	_wheel_pivot.offset_right = _wheel_radius
	_wheel_pivot.offset_top = -_wheel_radius
	_wheel_pivot.offset_bottom = _wheel_radius
	_wheel_pivot.pivot_offset = Vector2(_wheel_radius, _wheel_radius)
	center.add_child(_wheel_pivot)

	var wheel_visual := _HorrorWheelVisual.new()
	wheel_visual.custom_minimum_size = Vector2(_wheel_radius * 2.0, _wheel_radius * 2.0)
	wheel_visual.size = wheel_visual.custom_minimum_size
	wheel_visual.outcomes = _outcomes
	wheel_visual.wheel_radius = _wheel_radius
	wheel_visual.paper_texture = PAPER_TEX
	_wheel_pivot.add_child(wheel_visual)
	wheel_visual.queue_redraw()

	var leather_frame := TextureRect.new()
	leather_frame.texture = LEATHER_FRAME_TEX
	leather_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	leather_frame.stretch_mode = TextureRect.STRETCH_SCALE
	leather_frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	leather_frame.custom_minimum_size = frame_size
	leather_frame.size = frame_size
	leather_frame.set_anchors_preset(Control.PRESET_CENTER)
	leather_frame.offset_left = -frame_half.x
	leather_frame.offset_right = frame_half.x
	leather_frame.offset_top = -frame_half.y
	leather_frame.offset_bottom = frame_half.y
	leather_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(leather_frame)

	# Fixed clock hand — donut pivot aligned to wheel hub, tip points upward (12 o'clock).
	var hand_h: float = _wheel_radius * 0.96
	var hand_w: float = hand_h * (SPIN_HAND_TEX_SIZE.x / SPIN_HAND_TEX_SIZE.y)
	var pivot: Vector2 = SPIN_HAND_PIVOT_TEX / SPIN_HAND_TEX_SIZE * Vector2(hand_w, hand_h)
	var hand := TextureRect.new()
	hand.name = "SpinHand"
	hand.texture = SPIN_HAND_TEX
	hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hand.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hand.custom_minimum_size = Vector2(hand_w, hand_h)
	hand.set_anchors_preset(Control.PRESET_CENTER)
	hand.offset_left = -pivot.x
	hand.offset_right = hand_w - pivot.x
	hand.offset_top = -pivot.y
	hand.offset_bottom = hand_h - pivot.y
	hand.z_index = 11
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(hand)
	center.move_child(hand, -1)
	_tick_seg = TAU / float(_outcomes.size())

	call_deferred("_on_spin_pressed")


func title_space_for_center(title_font: int) -> float:
	return float(title_font) + 24.0


func _process(_delta: float) -> void:
	if not _spinning or _wheel_pivot == null:
		return
	_update_spin_ticks(_wheel_pivot.rotation)


func _update_spin_ticks(rot: float) -> void:
	if _tick_seg <= 0.0:
		return
	var prev_idx: int = int(floor(_prev_rot / _tick_seg))
	var curr_idx: int = int(floor(rot / _tick_seg))
	if curr_idx > prev_idx:
		for _i: int in range(curr_idx - prev_idx):
			SFXManager.play(SFX_SPIN_WHEEL)
	_prev_rot = rot


func _on_spin_pressed() -> void:
	if _spinning:
		return
	_prev_rot = 0.0
	await get_tree().create_timer(SPIN_PAUSE).timeout
	_spinning = true
	set_process(true)
	var seg: float = TAU / float(_outcomes.size())
	var target: float = FULL_ROTATIONS * TAU + float(_win_idx) * seg + seg * 0.5
	var tw := create_tween()
	# Slow ramp-up from standstill, then long gradual crawl to a full stop.
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_wheel_pivot, "rotation", target, SPIN_DURATION)
	await tw.finished
	_update_spin_ticks(target)
	set_process(false)
	_spinning = false
	await get_tree().create_timer(0.35).timeout
	finished.emit(str(_outcomes[_win_idx]))
	queue_free()


## Canonical horror/mystery wheel renderer (parchment + burnt seams + tucked hub).
class _HorrorWheelVisual extends Control:
	const JESTER_HAPPY_TEX: Texture2D = preload("res://assets/textures/daily_dungeon/wheel/jester_happy.png")
	const JESTER_SAD_TEX: Texture2D = preload("res://assets/textures/daily_dungeon/wheel/jester_sad.png")

	var outcomes: Array = []
	var wheel_radius: float = 210.0
	var paper_texture: Texture2D = null

	func _is_no_effect_key(key: String) -> bool:
		return key.strip_edges() == "no_effect"

	func _jester_tex_for_key(key: String) -> Texture2D:
		if _is_no_effect_key(key):
			return JESTER_HAPPY_TEX
		if DailyDungeonManager.is_modifier_positive(key.strip_edges()):
			return JESTER_HAPPY_TEX
		return JESTER_SAD_TEX

	func _draw_jester_face(pos: Vector2, angle: float, tex: Texture2D, icon_size: float) -> void:
		var half: float = icon_size * 0.5
		draw_set_transform(pos, angle, Vector2.ONE)
		draw_texture_rect(tex, Rect2(-half, -half, icon_size, icon_size), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _point_uv(p: Vector2) -> Vector2:
		return Vector2(p.x / size.x, p.y / size.y)

	func _draw() -> void:
		if outcomes.is_empty():
			return
		var n: int = outcomes.size()
		var seg: float = TAU / float(n)
		var center := size * 0.5
		var inner_r: float = wheel_radius * 0.12
		var start: float = -PI * 0.5

		# ── Parchment slices (uniform tone — no modifier color overlay) ──
		for i: int in range(n):
			var a0: float = start + float(i) * seg
			var a1: float = a0 + seg
			var pts: PackedVector2Array = PackedVector2Array()
			var uvs: PackedVector2Array = PackedVector2Array()
			var colors: PackedColorArray = PackedColorArray()
			pts.append(center + Vector2(cos(a0), sin(a0)) * inner_r)
			uvs.append(_point_uv(pts[pts.size() - 1]))
			colors.append(COLOR_PAPER_TINT)
			pts.append(center + Vector2(cos(a1), sin(a1)) * inner_r)
			uvs.append(_point_uv(pts[pts.size() - 1]))
			colors.append(COLOR_PAPER_TINT)
			var steps: int = maxi(3, int(seg / 0.12))
			for s: int in range(steps + 1):
				var a: float = lerpf(a1, a0, float(s) / float(steps))
				var p: Vector2 = center + Vector2(cos(a), sin(a)) * wheel_radius
				pts.append(p)
				uvs.append(_point_uv(p))
				colors.append(COLOR_PAPER_TINT)
			if paper_texture != null:
				draw_polygon(pts, colors, uvs, paper_texture)
			else:
				draw_colored_polygon(pts, COLOR_PAPER_TINT)

		# ── Burnt radial seams between slices ──
		for i: int in range(n):
			var seam_a: float = start + float(i) * seg
			_draw_burnt_seam(center, inner_r, wheel_radius, seam_a)

		# ── Jester faces (happy / sad by modifier feeling) ──
		var icon_size: float = minf(wheel_radius * 0.42, wheel_radius * seg * 0.95)
		for i: int in range(n):
			var key: String = str(outcomes[i])
			var a0: float = start + float(i) * seg
			var mid: float = a0 + seg * 0.5
			var face_pos: Vector2 = center + Vector2(cos(mid), sin(mid)) * (wheel_radius * 0.64)
			var face_tex: Texture2D = _jester_tex_for_key(key)
			_draw_jester_face(face_pos, mid + PI * 0.5, face_tex, icon_size)

		_draw_tucked_center_wrinkles(center, inner_r)

		draw_circle(center, inner_r + 2.0, Color(0.18, 0.08, 0.06, 1.0))
		draw_circle(center, inner_r, Color(0.30, 0.14, 0.10, 1.0))
		draw_arc(center, inner_r, 0.0, TAU, 24, Color(0.10, 0.04, 0.03, 1.0), 2.0, true)

	func _draw_burnt_seam(center: Vector2, inner_r: float, outer_r: float, angle: float) -> void:
		var seam := PackedVector2Array()
		var steps: int = 14
		for s: int in range(steps + 1):
			var t: float = float(s) / float(steps)
			var r: float = lerpf(inner_r, outer_r, t)
			var jitter: float = sin(t * PI * 5.5 + angle * 4.0) * 1.4
			var a: float = angle + jitter * 0.006
			seam.append(center + Vector2(cos(a), sin(a)) * r)
		# Charred core
		draw_polyline(seam, Color(0.06, 0.03, 0.02, 0.98), 3.0, false)
		# Dying ember edge
		draw_polyline(seam, Color(0.32, 0.10, 0.04, 0.42), 1.4, false)
		# Ash whisper
		draw_polyline(seam, Color(0.14, 0.08, 0.06, 0.55), 5.0, false)

	func _draw_tucked_center_wrinkles(center: Vector2, inner_r: float) -> void:
		var tuck_outer: float = inner_r * 1.85
		var fold_count: int = maxi(10, outcomes.size() * 2)
		var crease_dark := Color(0.20, 0.10, 0.06, 0.50)
		var crease_light := Color(0.48, 0.40, 0.32, 0.18)

		for ring_i: int in range(3):
			var ring_r: float = inner_r * (1.08 + float(ring_i) * 0.11)
			draw_arc(
				center, ring_r, 0.0, TAU, 40,
				Color(0.22, 0.12, 0.08, 0.20 - float(ring_i) * 0.04),
				1.0, false)

		for i: int in range(fold_count):
			var base_a: float = (float(i) / float(fold_count)) * TAU + 0.11 * sin(float(i) * 1.7)
			var crease := PackedVector2Array()
			var highlight := PackedVector2Array()
			var steps: int = 9
			for s: int in range(steps + 1):
				var t: float = float(s) / float(steps)
				var r: float = lerpf(inner_r * 0.08, tuck_outer, t)
				var wave: float = sin(t * PI * 3.2 + float(i) * 0.85) * 0.07
				var a: float = base_a + wave * (1.0 - t * 0.35)
				var p: Vector2 = center + Vector2(cos(a), sin(a)) * r
				crease.append(p)
				highlight.append(center + Vector2(cos(a + 0.035), sin(a + 0.035)) * r)
			draw_polyline(crease, crease_dark, 1.6, false)
			draw_polyline(highlight, crease_light, 0.9, false)

		for j: int in range(fold_count):
			var a_mid: float = ((float(j) + 0.5) / float(fold_count)) * TAU
			var r0: float = inner_r * 1.22
			var span: float = 0.18
			var p0: Vector2 = center + Vector2(cos(a_mid - span), sin(a_mid - span)) * r0
			var p1: Vector2 = center + Vector2(cos(a_mid + span), sin(a_mid + span)) * r0
			var p_mid: Vector2 = center + Vector2(cos(a_mid), sin(a_mid)) * (r0 * 0.92)
			draw_polyline(PackedVector2Array([p0, p_mid, p1]), crease_dark, 1.0, false)
