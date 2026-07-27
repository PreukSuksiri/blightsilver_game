extends RefCounted
class_name PackShatterFx
## Triangle shatter + light screen shake for pack / union-scroll opening.
## Matches Reckoning / BattleCalculationOverlay fragmentation (textured Polygon2D).

const SHAKE_AMP := 12.0
const SHAKE_DUR := 0.38
## 4 levels → 2 / 8 / 32 / 128 triangles (same as Reckoning card shatter).
const SHATTER_LEVELS := 4


## Fire-and-forget screen shake via offsets (works with full-rect anchors).
static func shake_screen(host: Control, amp: float = SHAKE_AMP, dur: float = SHAKE_DUR) -> void:
	if host == null or not is_instance_valid(host):
		return
	var o_l: float = host.offset_left
	var o_t: float = host.offset_top
	var o_r: float = host.offset_right
	var o_b: float = host.offset_bottom
	var tw := host.create_tween()
	var steps: int = maxi(4, int(dur / 0.04))
	for i: int in range(steps):
		var t: float = float(i) / float(steps)
		var falloff: float = 1.0 - t
		var ox: float = randf_range(-amp, amp) * falloff
		var oy: float = randf_range(-amp, amp) * falloff
		tw.tween_callback(_apply_offsets.bind(host, o_l + ox, o_t + oy, o_r + ox, o_b + oy))
		tw.tween_interval(dur / float(steps))
	tw.tween_callback(_apply_offsets.bind(host, o_l, o_t, o_r, o_b))


static func _apply_offsets(host: Control, left: float, top: float, right: float, bottom: float) -> void:
	if host == null or not is_instance_valid(host):
		return
	host.offset_left = left
	host.offset_top = top
	host.offset_right = right
	host.offset_bottom = bottom


## Shatter a texture into flying triangles in `local_rect` (host-local space).
## `hide_when_shown`: optional node (pack/scroll art) hidden when the first shards appear.
static func shatter_texture(
		host: Control,
		tex: Texture2D,
		local_rect: Rect2,
		levels_count: int = SHATTER_LEVELS,
		hide_when_shown: CanvasItem = null
) -> void:
	if host == null or not is_instance_valid(host):
		return
	if tex == null:
		if hide_when_shown != null and is_instance_valid(hide_when_shown):
			hide_when_shown.visible = false
		return
	var aw: float = local_rect.size.x
	var ah: float = local_rect.size.y
	if aw < 2.0 or ah < 2.0:
		if hide_when_shown != null and is_instance_valid(hide_when_shown):
			hide_when_shown.visible = false
		return
	var ax: float = local_rect.position.x
	var ay: float = local_rect.position.y
	var tex_w: float = float(tex.get_width())
	var tex_h: float = float(tex.get_height())
	if tex_w < 1.0 or tex_h < 1.0:
		if hide_when_shown != null and is_instance_valid(hide_when_shown):
			hide_when_shown.visible = false
		return

	var tl := Vector2(ax, ay)
	var tr := Vector2(ax + aw, ay)
	var br := Vector2(ax + aw, ay + ah)
	var bl := Vector2(ax, ay + ah)
	var uv_tl := Vector2(0.0, 0.0)
	var uv_tr := Vector2(tex_w, 0.0)
	var uv_br := Vector2(tex_w, tex_h)
	var uv_bl := Vector2(0.0, tex_h)

	var triangles: Array = [
		[PackedVector2Array([tl, tr, br]), PackedVector2Array([uv_tl, uv_tr, uv_br])],
		[PackedVector2Array([tl, br, bl]), PackedVector2Array([uv_tl, uv_br, uv_bl])],
	]

	var level_n: int = maxi(2, levels_count)
	var levels: Array = []
	for _level: int in range(level_n):
		var level_polys: Array = []
		for tri: Variant in triangles:
			var arr: Array = tri as Array
			var verts: PackedVector2Array = arr[0] as PackedVector2Array
			var uvs: PackedVector2Array = arr[1] as PackedVector2Array
			var cx: float = (verts[0].x + verts[1].x + verts[2].x) / 3.0
			var cy: float = (verts[0].y + verts[1].y + verts[2].y) / 3.0
			var centroid := Vector2(cx, cy)
			var local_verts := PackedVector2Array()
			for v: Vector2 in verts:
				local_verts.append(v.lerp(centroid, 0.03) - centroid)
			var poly := Polygon2D.new()
			poly.texture = tex
			poly.polygon = local_verts
			poly.uv = uvs
			poly.position = centroid
			# Relative z so shards draw above the overlay dim/bg (parent z + this).
			poly.z_index = 60
			poly.z_as_relative = true
			poly.visible = false
			host.add_child(poly)
			level_polys.append(poly)
		levels.append(level_polys)
		if _level < level_n - 1:
			var next_tris: Array = []
			for tri2: Variant in triangles:
				var arr2: Array = tri2 as Array
				for sub: Variant in _subdivide(
						arr2[0] as PackedVector2Array,
						arr2[1] as PackedVector2Array):
					next_tris.append(sub)
			triangles = next_tris

	# Hide the intact art only once shards are ready to show.
	if hide_when_shown != null and is_instance_valid(hide_when_shown):
		hide_when_shown.visible = false

	for level_idx: int in range(levels.size()):
		var cur: Array = levels[level_idx] as Array
		for p: Variant in cur:
			var poly: Polygon2D = p as Polygon2D
			if is_instance_valid(poly):
				poly.visible = true
		if level_idx > 0:
			var prev: Array = levels[level_idx - 1] as Array
			for p2: Variant in prev:
				var poly2: Polygon2D = p2 as Polygon2D
				if is_instance_valid(poly2):
					poly2.visible = false
		if level_idx < levels.size() - 1:
			await host.get_tree().create_timer(0.05).timeout

	var final_polys: Array = levels[levels.size() - 1] as Array
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var card_cx: float = ax + aw * 0.5
	var card_cy: float = ay + ah * 0.5
	for p3: Variant in final_polys:
		var poly3: Polygon2D = p3 as Polygon2D
		if not is_instance_valid(poly3):
			continue
		var dir := Vector2(poly3.position.x - card_cx, poly3.position.y - card_cy)
		if dir.length() < 1.0:
			dir = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		dir = (dir.normalized() + Vector2(0.0, -0.4)).normalized()
		var speed: float = rng.randf_range(100.0, 360.0)
		var duration: float = rng.randf_range(0.42, 0.75)
		var rot_delta: float = rng.randf_range(-TAU, TAU)
		var tw := host.create_tween()
		tw.tween_property(poly3, "position", poly3.position + dir * speed, duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(poly3, "modulate:a", 0.0, duration) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw.parallel().tween_property(poly3, "rotation", poly3.rotation + rot_delta, duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
		var poly_id: int = poly3.get_instance_id()
		tw.finished.connect(func() -> void:
			var n: Node = instance_from_id(poly_id) as Node
			if n != null and is_instance_valid(n):
				n.queue_free())

	# Cover most of the fly-apart so shards are clearly visible (Reckoning waits ~0.8s).
	await host.get_tree().create_timer(0.55).timeout


static func _subdivide(verts: PackedVector2Array, uvs: PackedVector2Array) -> Array:
	var a := verts[0]; var b := verts[1]; var c := verts[2]
	var ua := uvs[0]; var ub := uvs[1]; var uc := uvs[2]
	var mab := (a + b) * 0.5; var muab := (ua + ub) * 0.5
	var mbc := (b + c) * 0.5; var mubc := (ub + uc) * 0.5
	var mca := (c + a) * 0.5; var muca := (uc + ua) * 0.5
	return [
		[PackedVector2Array([a, mab, mca]), PackedVector2Array([ua, muab, muca])],
		[PackedVector2Array([mab, b, mbc]), PackedVector2Array([muab, ub, mubc])],
		[PackedVector2Array([mbc, c, mca]), PackedVector2Array([mubc, uc, muca])],
		[PackedVector2Array([mab, mbc, mca]), PackedVector2Array([muab, mubc, muca])],
	]
