extends RefCounted
class_name CapsuleExitFx
## Shared Kelly-stamp → card-stack → slide-off transition (Campaign Gallery / Quick Duel).

const STAMP_ID := "stamp_kelly"
const STAMP_SIZE := 130.0
const STAMP_FADE_SEC := 0.28
const STAMP_POP_SCALE := 1.35
const STAMP_GROW_SEC := 0.38
const STAMP_SHRINK_SEC := 0.48
const STAMP_APPROVED_GROW_SEC := 0.34
const STAMP_APPROVED_SHRINK_SEC := 0.44
const STAMP_BETWEEN_SEC := 0.28
const STAMP_HOLD_SEC := 0.20
const STAMP_APPROVED_COLOR := Color(0.72, 0.07, 0.07)
const STAMP_APPROVED_FONT_SIZE := 28
const STAMP_OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 1.0)
## Screen-space silhouette outline (8-dir offsets) — reliable vs large stamp textures.
const STAMP_OUTLINE_SCREEN_PX := 2.0
const STAMP_APPROVED_OUTLINE_SIZE := 4
const STAMP_TILT_MIN_DEG := -28.0
const STAMP_TILT_MAX_DEG := 28.0
const CARD_FLY_SEC := 0.24
const CARD_STAGGER_SEC := 0.05
const STACK_SLIDE_SEC := 0.52
const CENTER_BAND_FRAC := 0.10


## Stamp selected capsule, stack all cards (selected on top), slide opposite X.
## `host` owns tweens / stack layer. Optional meta on each card:
##   `_exit_stamp_host` or `_gallery_frame` — Control to parent the stamp onto.
## `stamp_id`: detective vault stamp (default Kelly / compass).
static func play(
		host: Control,
		selected: Control,
		cards: Array,
		card_size: Vector2,
		stamp_id: String = STAMP_ID
) -> void:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return

	host.mouse_filter = Control.MOUSE_FILTER_STOP

	if selected == null or not is_instance_valid(selected):
		for c: Variant in cards:
			if c is Control and is_instance_valid(c as Control):
				selected = c as Control
				break

	var resolved_stamp: String = stamp_id.strip_edges()
	if resolved_stamp.is_empty() or not DetectiveNoteVault.has_stamp(resolved_stamp):
		resolved_stamp = STAMP_ID

	if selected != null and is_instance_valid(selected):
		await _play_logo_approved_stamp(host, selected, card_size, resolved_stamp)
	if not host.is_inside_tree():
		return
	await _stack_and_slide(host, selected, cards, card_size)


static func _stamp_host_for(card: Control) -> Control:
	if card == null or not is_instance_valid(card):
		return null
	for key: StringName in [&"_exit_stamp_host", &"_gallery_frame"]:
		if card.has_meta(key):
			var v: Variant = card.get_meta(key)
			if v is Control and is_instance_valid(v as Control):
				return v as Control
	return card


static func _play_logo_approved_stamp(
		host: Control,
		card: Control,
		fallback_size: Vector2,
		stamp_id: String
) -> void:
	var stamp_info: Dictionary = DetectiveNoteVault.get_stamp(stamp_id)
	if stamp_info.is_empty():
		return
	var img_path: String = str(stamp_info.get("image", "")).strip_edges()
	var tex: Texture2D = null
	if img_path != "" and ResourceLoader.exists(img_path):
		tex = load(img_path) as Texture2D
	if tex == null:
		return

	var stamp_parent: Control = _stamp_host_for(card)
	if stamp_parent == null:
		return

	var host_size: Vector2 = stamp_parent.size
	if host_size.x < 1.0 or host_size.y < 1.0:
		host_size = fallback_size

	# Cluster: logo + APPROVED (no approver name), shared random tilt.
	var cluster_w: float = STAMP_SIZE + 40.0
	var cluster_h: float = STAMP_SIZE + 28.0
	var cluster := Control.new()
	cluster.name = "ExitStampCluster"
	cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cluster.size = Vector2(cluster_w, cluster_h)
	cluster.pivot_offset = cluster.size * 0.5
	cluster.position = (host_size - cluster.size) * 0.5
	# Logo + APPROVED share one cluster tilt (stronger than notebook stamps).
	cluster.rotation = deg_to_rad(randf_range(STAMP_TILT_MIN_DEG, STAMP_TILT_MAX_DEG))
	cluster.z_index = 40
	stamp_parent.add_child(cluster)

	# Logo wrap: black 8-dir silhouette outline behind the colored stamp.
	var logo_wrap := Control.new()
	logo_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_wrap.size = Vector2(STAMP_SIZE, STAMP_SIZE)
	logo_wrap.position = Vector2((cluster_w - STAMP_SIZE) * 0.5, 0.0)
	logo_wrap.pivot_offset = logo_wrap.size * 0.5
	logo_wrap.modulate = Color(1, 1, 1, 0)
	cluster.add_child(logo_wrap)
	_add_stamp_logo_with_outline(logo_wrap, tex)

	var approved := Label.new()
	approved.text = "APPROVED"
	approved.add_theme_font_override("font", FontManager.make_font("handwritten", 700))
	approved.add_theme_font_size_override("font_size", STAMP_APPROVED_FONT_SIZE)
	approved.add_theme_color_override("font_color", STAMP_APPROVED_COLOR)
	approved.add_theme_color_override("font_outline_color", STAMP_OUTLINE_COLOR)
	approved.add_theme_constant_override("outline_size", STAMP_APPROVED_OUTLINE_SIZE)
	approved.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	approved.position = Vector2(0.0, STAMP_SIZE - 22.0)
	approved.size = Vector2(cluster_w, 36.0)
	approved.pivot_offset = approved.size * 0.5
	approved.mouse_filter = Control.MOUSE_FILTER_IGNORE
	approved.visible = false
	cluster.add_child(approved)

	# 1) Logo fade + slam (outline included in wrap).
	var fade := host.create_tween()
	fade.tween_property(logo_wrap, "modulate:a", 1.0, STAMP_FADE_SEC) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade.finished
	if logo_wrap == null or not is_instance_valid(logo_wrap):
		return
	SFXManager.play(SFXManager.SFX_STAMP, SFXManager.SFX_STAMP_VOLUME)
	await _pulse_stamp_scale(host, logo_wrap, STAMP_GROW_SEC, STAMP_SHRINK_SEC)
	if not host.is_inside_tree():
		return
	await host.get_tree().create_timer(STAMP_BETWEEN_SEC).timeout
	if approved == null or not is_instance_valid(approved):
		return

	# 2) APPROVED slam (no person name; black font outline).
	approved.visible = true
	approved.scale = Vector2.ONE
	SFXManager.play(SFXManager.SFX_STAMP, SFXManager.SFX_STAMP_VOLUME)
	await _pulse_stamp_scale(
			host, approved, STAMP_APPROVED_GROW_SEC, STAMP_APPROVED_SHRINK_SEC)
	if not host.is_inside_tree():
		return
	await host.get_tree().create_timer(STAMP_HOLD_SEC).timeout


static func _make_stamp_tex_rect(tex: Texture2D, modulate: Color, pos: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.size = Vector2(STAMP_SIZE, STAMP_SIZE)
	tr.position = pos
	tr.modulate = modulate
	return tr


static func _add_stamp_logo_with_outline(logo_wrap: Control, tex: Texture2D) -> void:
	var o: float = STAMP_OUTLINE_SCREEN_PX
	var dirs: Array[Vector2] = [
		Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
		Vector2(-1, 0), Vector2(1, 0),
		Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1),
	]
	for d: Vector2 in dirs:
		logo_wrap.add_child(_make_stamp_tex_rect(
				tex, STAMP_OUTLINE_COLOR, d * o))
	# Face on top of outline ring.
	logo_wrap.add_child(_make_stamp_tex_rect(tex, Color(1, 1, 1, 1), Vector2.ZERO))


static func _pulse_stamp_scale(
		host: Control,
		ctrl: Control,
		grow_sec: float,
		shrink_sec: float
) -> void:
	if ctrl == null or not is_instance_valid(ctrl):
		return
	ctrl.scale = Vector2.ONE
	var tween := host.create_tween()
	tween.tween_property(ctrl, "scale", Vector2.ONE * STAMP_POP_SCALE, grow_sec) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ctrl, "scale", Vector2.ONE, shrink_sec) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


static func _stack_and_slide(
		host: Control,
		selected: Control,
		cards: Array,
		card_size: Vector2
) -> void:
	if not host.is_inside_tree():
		return

	var layer := Control.new()
	layer.name = "CapsuleExitStack"
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.z_index = 60
	layer.size = host.size
	host.add_child(layer)

	var origin_center_x: float = host.size.x * 0.5
	if selected != null and is_instance_valid(selected):
		origin_center_x = selected.global_position.x + selected.size.x * 0.5

	var live_cards: Array[Control] = []
	for c: Variant in cards:
		if c is Control:
			var ctrl: Control = c as Control
			if is_instance_valid(ctrl) and ctrl.is_inside_tree():
				live_cards.append(ctrl)
	if live_cards.is_empty():
		layer.queue_free()
		return

	for card: Control in live_cards:
		card.scale = Vector2.ONE
		var gp: Vector2 = card.global_position
		var sz: Vector2 = card.size
		if sz.x < 1.0 or sz.y < 1.0:
			sz = card.get_combined_minimum_size()
		var parent_n: Node = card.get_parent()
		if parent_n != null:
			parent_n.remove_child(card)
		layer.add_child(card)
		card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		card.size = sz
		card.global_position = gp
		card.pivot_offset = card.size * 0.5
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.z_index = 0

	# Stamped / selected capsule flies last and stays draw-top of the stack.
	var fly_order: Array[Control] = []
	for card: Control in live_cards:
		if card != selected:
			fly_order.append(card)
	if selected != null and is_instance_valid(selected) and selected.get_parent() == layer:
		fly_order.append(selected)
	elif fly_order.is_empty():
		layer.queue_free()
		return

	var stack_w: float = card_size.x
	var stack_h: float = card_size.y
	if selected != null and is_instance_valid(selected) and selected.size.x > 1.0:
		stack_w = selected.size.x
		stack_h = selected.size.y
	var stack_anchor := Vector2(
			host.size.x * 0.5 - stack_w * 0.5,
			host.size.y * 0.5 - stack_h * 0.5)

	var total: int = fly_order.size()
	var top_z: int = total + 1
	for i: int in total:
		var card: Control = fly_order[i]
		if card == null or not is_instance_valid(card):
			continue
		# Stamped capsule is always last in fly_order → top of stack.
		var is_top: bool = card == selected or i == total - 1
		var stack_index: int = (total - 1) if is_top else i
		var stack_pos: Vector2 = stack_anchor + Vector2(
				float(stack_index) * 2.0, float(stack_index) * -2.0)
		var rot: float = deg_to_rad(randf_range(-5.0, 5.0))
		var tw := host.create_tween()
		tw.tween_interval(float(i) * CARD_STAGGER_SEC)
		tw.tween_callback(func() -> void:
			if card != null and is_instance_valid(card) and card.get_parent() == layer:
				layer.move_child(card, -1)
				card.z_index = top_z if is_top else i + 1)
		tw.set_parallel(true)
		tw.tween_property(card, "position", stack_pos, CARD_FLY_SEC) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(card, "rotation", rot, CARD_FLY_SEC) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.set_parallel(false)
		tw.tween_callback(func() -> void:
			SFXManager.play_flip()
			if is_top and card != null and is_instance_valid(card) \
					and card.get_parent() == layer:
				layer.move_child(card, -1)
				card.z_index = top_z)

	var fly_total: float = float(maxi(0, total - 1)) * CARD_STAGGER_SEC + CARD_FLY_SEC + 0.04
	await host.get_tree().create_timer(fly_total).timeout
	if not host.is_inside_tree() or not is_instance_valid(layer):
		return

	# Final guarantee: stamped capsule on top of the stack.
	if selected != null and is_instance_valid(selected) and selected.get_parent() == layer:
		layer.move_child(selected, -1)
		selected.z_index = top_z

	var slide_right: bool = _resolve_slide_right(host.size.x, origin_center_x)
	var pad: float = maxf(card_size.x, stack_w) + 80.0
	var target_x: float = host.size.x + pad if slide_right else -(host.size.x + pad)
	var slide := host.create_tween()
	slide.tween_property(layer, "position:x", target_x, STACK_SLIDE_SEC) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await slide.finished


static func _resolve_slide_right(host_w: float, origin_center_x: float) -> bool:
	var mid: float = host_w * 0.5
	var band: float = host_w * CENTER_BAND_FRAC
	if origin_center_x < mid - band:
		return true
	if origin_center_x > mid + band:
		return false
	return randf() >= 0.5
