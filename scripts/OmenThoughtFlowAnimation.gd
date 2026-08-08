extends CanvasLayer
## OmenThoughtFlowAnimation
## VN / admin: animation_omen_thought_flow
##
## 20 random omen illustrations each appear full-screen (very translucent),
## then shrink and flow into the protagonist's thought-locus. Hold time
## shortens across the sequence so the shuffle accelerates.

const OMENS_DIR := "res://assets/textures/omens/"
const IMAGE_COUNT := 20
const REVEAL_ALPHA := 0.15
const FLOW_ALPHA := 0.15
const FADE_IN_SEC := 0.2
## First omen lingers; later ones flash faster (shuffle speed increments).
const HOLD_START := 0.4
const HOLD_MIN := 0.12
const HOLD_DECAY := 0.88  # multiply hold per successive image
const STAGGER_START := 0.62
const STAGGER_MIN := 0.14
const STAGGER_DECAY := 0.90
const FLOW_SPEED_START := 380.0
const FLOW_SPEED_END := 720.0
const ABSORB_DUR := 0.28


class _Shard:
	var sprite: Sprite2D
	var tex: Texture2D
	var pos: Vector2
	var rot: float = 0.0
	var rot_vel: float = 0.0
	var base_speed: float = 380.0
	var elapsed: float = 0.0
	var delay: float = 0.0
	var hold: float = HOLD_START
	var flight_t: float = 0.0
	var phase: String = "wait"  # wait | reveal | flow | absorb | done
	var absorb_t: float = 0.0
	var scale_full: Vector2 = Vector2.ONE
	var scale_tiny: Vector2 = Vector2.ONE
	var sway_amp: float = 0.0
	var sway_freq: float = 0.0
	var sway_ph: float = 0.0


var _shards: Array[_Shard] = []
var _n_done: int = 0
var _n_total: int = 0
var _thought: Vector2 = Vector2.ZERO
var _vp: Vector2 = Vector2.ZERO
var _center: Vector2 = Vector2.ZERO
var _global_t: float = 0.0
var _done: bool = false
var _thought_glow: Sprite2D = null
var _thought_pulse: float = 0.0


func _ready() -> void:
	layer = 100
	set_process(false)


func launch(thought_pos: Vector2 = Vector2.ZERO) -> void:
	_vp = get_viewport().get_visible_rect().size
	_center = _vp * 0.5
	_thought = thought_pos
	if _thought == Vector2.ZERO:
		_thought = _vp * Vector2(0.5, 0.34)

	# Collect paths first, then load only IMAGE_COUNT textures (not the whole folder).
	var paths: Array[String] = _list_omen_image_paths()
	if paths.is_empty():
		push_warning("OmenThoughtFlowAnimation: no omen illustrations in %s" % OMENS_DIR)
		queue_free()
		return

	paths.shuffle()
	var pick: Array[Texture2D] = []
	var path_i: int = 0
	while pick.size() < IMAGE_COUNT and path_i < paths.size():
		var tex: Texture2D = load(paths[path_i]) as Texture2D
		path_i += 1
		if tex != null:
			pick.append(tex)
	# If some loads failed, reuse already-loaded textures to fill the count.
	while pick.size() < IMAGE_COUNT and not pick.is_empty():
		pick.append(pick[randi() % pick.size()])
	if pick.is_empty():
		push_warning("OmenThoughtFlowAnimation: failed to load omen textures from %s" % OMENS_DIR)
		queue_free()
		return

	_n_total = pick.size()
	_spawn_thought_glow()

	var delay_acc: float = 0.0
	var hold: float = HOLD_START
	var stagger: float = STAGGER_START
	var n: int = pick.size()
	for i in range(n):
		var tex: Texture2D = pick[i]
		var s := _Shard.new()
		s.tex = tex
		s.delay = delay_acc
		s.hold = hold
		s.base_speed = lerpf(FLOW_SPEED_START, FLOW_SPEED_END,
				float(i) / float(maxi(1, n - 1)))
		s.pos = _center
		s.rot = 0.0
		s.rot_vel = randf_range(-0.8, 0.8)
		s.sway_amp = randf_range(18.0, 42.0)
		s.sway_freq = randf_range(0.8, 1.8)
		s.sway_ph = randf_range(0.0, TAU)
		s.scale_full = _fullscreen_scale(tex)
		s.scale_tiny = s.scale_full * 0.08

		var spr := Sprite2D.new()
		spr.texture = tex
		spr.scale = s.scale_full
		spr.position = s.pos
		spr.rotation = 0.0
		spr.modulate = Color(1.0, 1.0, 1.0, 0.0)
		spr.visible = false
		spr.z_index = n - i  # newest on top during overlap
		add_child(spr)
		s.sprite = spr
		_shards.append(s)

		delay_acc += stagger
		hold = maxf(HOLD_MIN, hold * HOLD_DECAY)
		stagger = maxf(STAGGER_MIN, stagger * STAGGER_DECAY)

	set_process(true)


func _fullscreen_scale(tex: Texture2D) -> Vector2:
	var tw: float = maxf(1.0, float(tex.get_width()))
	var th: float = maxf(1.0, float(tex.get_height()))
	# Cover: fill the entire viewport (may crop edges).
	var scl: float = maxf(_vp.x / tw, _vp.y / th)
	return Vector2(scl, scl)


func _spawn_thought_glow() -> void:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d: float = Vector2(x - 31.5, y - 31.5).length() / 32.0
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(0.55, 0.78, 1.0, a * 0.55))
	var tex := ImageTexture.create_from_image(img)
	_thought_glow = Sprite2D.new()
	_thought_glow.texture = tex
	_thought_glow.position = _thought
	_thought_glow.scale = Vector2(2.4, 2.4)
	_thought_glow.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_thought_glow.z_index = IMAGE_COUNT + 2
	add_child(_thought_glow)
	var tw := create_tween()
	tw.tween_property(_thought_glow, "modulate:a", 0.85, 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if _done:
		return

	_global_t += delta
	_thought_pulse += delta
	if _thought_glow != null:
		var pulse: float = 1.0 + 0.08 * sin(_thought_pulse * 5.5)
		_thought_glow.scale = Vector2(2.4, 2.4) * pulse
		_thought_glow.position = _thought

	for s: _Shard in _shards:
		if s.phase == "done":
			continue

		s.elapsed += delta
		if s.elapsed < s.delay:
			continue

		match s.phase:
			"wait":
				s.phase = "reveal"
				s.flight_t = 0.0
				s.pos = _center
				s.sprite.visible = true
				s.sprite.position = s.pos
				s.sprite.scale = s.scale_full
				s.sprite.rotation = 0.0
				s.sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
				var fade := create_tween()
				fade.tween_property(s.sprite, "modulate:a", REVEAL_ALPHA, FADE_IN_SEC) \
						.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			"reveal":
				s.flight_t += delta
				s.pos = _center
				s.sprite.position = s.pos
				s.sprite.scale = s.scale_full
				s.sprite.rotation = 0.0
				# Hold includes fade-in so the image is fully visible before flow.
				if s.flight_t >= FADE_IN_SEC + s.hold:
					s.phase = "flow"
					s.flight_t = 0.0
					s.rot = 0.0
					s.sprite.modulate.a = REVEAL_ALPHA
			"flow":
				_tick_flow(s, delta)
			"absorb":
				_tick_absorb(s, delta)

	if _n_done >= _n_total and not _done:
		_done = true
		_finale()


func _tick_flow(s: _Shard, delta: float) -> void:
	s.flight_t += delta
	var to_thought: Vector2 = _thought - s.pos
	var dist: float = to_thought.length()
	if dist < 28.0:
		s.phase = "absorb"
		s.absorb_t = 0.0
		return

	var dir: Vector2 = to_thought / dist
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var speed_boost: float = 1.0 + s.flight_t * 0.85
	s.pos += dir * s.base_speed * speed_boost * delta
	s.pos += perp * s.sway_amp * sin(s.sway_freq * s.flight_t + s.sway_ph) * delta
	s.pos -= (s.pos - _thought) * (2.2 + s.flight_t * 0.6) * delta

	s.rot_vel *= pow(0.45, delta)
	s.rot += s.rot_vel * delta

	# Shrink from full-screen down toward the thought.
	var start_dist: float = _center.distance_to(_thought)
	var max_d: float = maxf(220.0, start_dist)
	var approach: float = clampf(1.0 - dist / max_d, 0.0, 1.0)
	# Ease-in shrink so the picture stays large/readable early in the flow.
	var shrink_u: float = approach * approach
	s.sprite.scale = s.scale_full.lerp(s.scale_tiny * 1.6, shrink_u)
	s.sprite.position = s.pos
	s.sprite.rotation = s.rot
	s.sprite.modulate.a = lerpf(REVEAL_ALPHA, FLOW_ALPHA, shrink_u)


func _tick_absorb(s: _Shard, delta: float) -> void:
	s.absorb_t += delta
	var u: float = clampf(s.absorb_t / ABSORB_DUR, 0.0, 1.0)
	s.pos = s.pos.lerp(_thought, 0.4)
	s.sprite.position = s.pos
	s.sprite.scale = s.scale_tiny.lerp(s.scale_tiny * 0.15, u)
	s.sprite.modulate.a = lerpf(FLOW_ALPHA, 0.0, u)
	s.sprite.rotation = s.rot + u * 1.2
	if u >= 1.0:
		s.phase = "done"
		s.sprite.visible = false
		_n_done += 1
		if _thought_glow != null:
			var kick := create_tween()
			kick.tween_property(_thought_glow, "scale", Vector2(3.1, 3.1), 0.06)
			kick.tween_property(_thought_glow, "scale", Vector2(2.4, 2.4), 0.14)


func _finale() -> void:
	if _thought_glow != null:
		var tw := create_tween()
		tw.tween_property(_thought_glow, "modulate:a", 0.0, 0.55) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(_thought_glow, "scale", Vector2(0.4, 0.4), 0.55)
		await tw.finished
	queue_free()


func _list_omen_image_paths() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(OMENS_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir():
			var lower: String = fname.to_lower()
			if lower.ends_with(".jpg") or lower.ends_with(".jpeg") \
					or lower.ends_with(".png") or lower.ends_with(".webp"):
				out.append(OMENS_DIR.path_join(fname))
		fname = dir.get_next()
	dir.list_dir_end()
	return out
