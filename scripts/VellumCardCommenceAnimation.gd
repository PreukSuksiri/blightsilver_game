extends CanvasLayer
## VellumCardCommenceAnimation
## Admin command: animation_vellum_card_commence
##
## Each card uses DriftingCards.gd's physics model (gust-modulated speed,
## 3-incommensurate-sine perpendicular turbulence, angular-velocity rotation)
## with the travel direction reoriented toward the screen center.

const _FACEDOWN:   Texture2D = preload("res://assets/textures/cards/frames/facedown_frame.png")
const _FACE_BLANK: Texture2D = preload("res://assets/textures/cards/frames/vellum_card_frame_full.png")
const _FULL_CARDS_DIR := "res://assets/textures/cards/full_cards/"

const _CARD_W  := 160.0
const _CARD_H  := 220.0
const _STAGGER := 0.09   # seconds between launching successive cards

# ─────────────────────────────────────────────────────────────
# Per-card state  (mirrors DriftingCards dict fields)
# ─────────────────────────────────────────────────────────────
class _Card:
	var sprite:    Sprite2D
	var particles: CPUParticles2D
	var pos:       Vector2   # world position (screen coords)
	var rest:      Vector2   # tiny random offset from center for stack depth
	var rot:       float = 0.0
	var rot_vel:   float = 0.0
	# ── rotation model (same as DriftingCards) ──
	var rot_drag:    float
	var torque_amp:  float
	var torque_freq: float
	var torque_ph:   float
	# ── gust model ──
	var base_speed: float
	var gust_freq:  float
	var gust_phase: float
	# ── 3-sine perpendicular turbulence ──
	var vy1_amp: float; var vy1_freq: float; var vy1_ph: float
	var vy2_amp: float; var vy2_freq: float; var vy2_ph: float
	var vy3_amp: float; var vy3_freq: float; var vy3_ph: float
	# ── flip (DriftingCards z-axis model) ──
	var tex_front:  Texture2D = null
	var flip_angle: float = 0.0
	var flip_speed: float = 0.0
	# ── lifecycle ──
	var elapsed:  float = 0.0
	var delay:    float = 0.0
	var flight_t: float = 0.0   # time since card was launched (for oscillators)
	var arrived:  bool  = false

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var _cards:        Array[_Card] = []
var _n_arrived:    int          = 0
var _n_total:      int          = 0
var _center:       Vector2
var _scale_base:   Vector2      # base sprite scale (shared by all cards)
var _flip_enabled: bool         = true
var _shake:        bool         = false
var _shake_t:      float        = 0.0
var _done:         bool         = false

# ─────────────────────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = 100
	set_process(false)

func launch(flip: bool = true) -> void:
	_flip_enabled = flip
	_center = get_viewport().get_visible_rect().size * 0.5
	var vp: Vector2 = get_viewport().get_visible_rect().size

	var deck: DeckData = SaveManager.get_active_deck()
	if deck == null:
		deck = DeckData.new()
	var card_entries: Array = []
	for name: String in deck.characters:
		card_entries.append({"name": name, "type": "character"})
	for name: String in deck.traps:
		card_entries.append({"name": name, "type": "trap"})
	for name: String in deck.techs:
		card_entries.append({"name": name, "type": "tech"})
	for _i in range(deck.dead_end_count()):
		card_entries.append({"name": "", "type": "dead_end"})
	card_entries.shuffle()

	_n_total = card_entries.size()

	var tw: float = float(_FACEDOWN.get_width())
	var th: float = float(_FACEDOWN.get_height())
	_scale_base = Vector2(_CARD_W / tw, _CARD_H / th)

	for i in range(_n_total):
		var entry: Dictionary = card_entries[i]
		var c := _Card.new()
		c.delay     = float(i) * _STAGGER
		c.pos       = _edge(vp)
		c.rest      = Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		c.tex_front = _resolve_face_tex(entry["name"], entry["type"])

		# ── Rotation (DriftingCards angular-velocity model) ──
		c.rot       = randf_range(-PI, PI)
		c.rot_vel   = randf_range(-1.2, 1.2)
		c.rot_drag  = randf_range(0.20, 0.40)
		c.torque_amp  = randf_range(0.4, 1.2)
		c.torque_freq = randf_range(0.25, 0.70)
		c.torque_ph   = randf_range(0.0, TAU)

		# ── Gust (DriftingCards horizontal-gust model) ──
		c.base_speed = randf_range(220.0, 340.0)
		c.gust_freq  = randf_range(0.12, 0.35)
		c.gust_phase = randf_range(0.0, TAU)

		# ── Flip (DriftingCards z-axis model) ──
		c.flip_angle = randf_range(0.0, TAU)
		c.flip_speed = randf_range(0.25, 0.55)   # rad/s — same range as DriftingCards

		# ── 3-sine perpendicular turbulence (DriftingCards vy model) ──
		c.vy1_amp  = randf_range(28.0, 55.0); c.vy1_freq = randf_range(0.18, 0.42); c.vy1_ph = randf_range(0.0, TAU)
		c.vy2_amp  = randf_range(14.0, 28.0); c.vy2_freq = randf_range(0.53, 0.97); c.vy2_ph = randf_range(0.0, TAU)
		c.vy3_amp  = randf_range(6.0,  14.0); c.vy3_freq = randf_range(1.31, 2.70); c.vy3_ph = randf_range(0.0, TAU)

		# ── Sprite ──
		var spr := Sprite2D.new()
		spr.texture  = _FACEDOWN
		spr.scale    = Vector2(_CARD_W / tw, _CARD_H / th)
		spr.position = c.pos
		spr.rotation = c.rot
		spr.visible  = false
		add_child(spr)
		c.sprite = spr

		# ── Aura particles (sibling of sprite, position synced in _process) ──
		var pts := _make_aura()
		pts.position = c.pos
		add_child(pts)
		c.particles = pts

		_cards.append(c)

	set_process(true)

# ─────────────────────────────────────────────────────────────
# Per-frame physics  (DriftingCards model, target = _center)
# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _done:
		return

	var all_in := true

	for c: _Card in _cards:
		if c.arrived:
			continue

		c.elapsed += delta
		if c.elapsed < c.delay:
			all_in = false
			continue

		c.flight_t += delta

		if not c.sprite.visible:
			c.sprite.visible    = true
			c.particles.emitting = true

		var to_center: Vector2 = _center - c.pos
		var dist: float = to_center.length()

		if dist < 14.0:
			_arrive(c)
			continue

		all_in = false
		var dir:  Vector2 = to_center / dist
		var perp: Vector2 = Vector2(-dir.y, dir.x)

		# ── Gust modulation (DriftingCards formula) ──
		var gust: float = 0.25 + 0.75 * (0.5 + 0.5 * sin(
				c.gust_freq * c.flight_t + c.gust_phase))

		# ── Move toward center (adapted from DriftingCards rightward motion) ──
		c.pos += dir * c.base_speed * gust * delta

		# ── Perpendicular turbulence (DriftingCards 3-sine vy model) ──
		var vy: float = (
				c.vy1_amp * sin(c.vy1_freq * c.flight_t + c.vy1_ph) +
				c.vy2_amp * sin(c.vy2_freq * c.flight_t + c.vy2_ph) +
				c.vy3_amp * sin(c.vy3_freq * c.flight_t + c.vy3_ph))
		c.pos += perp * vy * delta

		# ── Soft pull toward center (DriftingCards target_y pull, both axes) ──
		var offset: Vector2 = c.pos - _center
		c.pos -= offset * 1.2 * delta

		# ── Rotation (DriftingCards angular-velocity model) ──
		var torque: float = c.torque_amp * sin(c.torque_freq * c.flight_t + c.torque_ph)
		c.rot_vel += torque * delta
		c.rot_vel *= pow(c.rot_drag, delta)
		c.rot     += c.rot_vel * delta

		# ── Flip / z-axis (DriftingCards model) ──
		if _flip_enabled:
			c.flip_angle = fmod(c.flip_angle + c.flip_speed * delta, TAU)
			var flip_cos: float = cos(c.flip_angle)
			c.sprite.texture = _FACEDOWN if flip_cos >= 0.0 else c.tex_front
			c.sprite.scale   = Vector2(_scale_base.x * absf(flip_cos), _scale_base.y)

		c.sprite.position    = c.pos
		c.sprite.rotation    = c.rot
		c.particles.position = c.pos

	# ── Stack shake ──
	if _shake:
		_shake_t += delta
		var ox: float = sin(_shake_t * 17.0) * 3.2
		var oy: float = cos(_shake_t * 23.5) * 1.6
		for c: _Card in _cards:
			if c.arrived:
				c.sprite.position = _center + c.rest + Vector2(ox, oy)

	if all_in and _n_arrived == _n_total and not _done:
		_done  = true
		_shake = false
		for c: _Card in _cards:
			c.sprite.position = _center + c.rest
			c.sprite.rotation = 0.0
		_finale()

# ─────────────────────────────────────────────────────────────
# Arrival
# ─────────────────────────────────────────────────────────────
func _arrive(c: _Card) -> void:
	c.arrived            = true
	c.particles.emitting = false
	c.sprite.position    = _center + c.rest
	c.sprite.rotation    = 0.0
	c.sprite.texture     = _FACEDOWN
	c.sprite.scale       = _scale_base
	_n_arrived           += 1
	_shake               = true

# ─────────────────────────────────────────────────────────────
# Finale sequence
# ─────────────────────────────────────────────────────────────
func _finale() -> void:
	await get_tree().create_timer(0.45).timeout

	var burst := _make_burst()
	burst.position = _center
	add_child(burst)
	burst.emitting = true

	await get_tree().create_timer(0.35).timeout

	var vp: Vector2 = get_viewport().get_visible_rect().size
	var flash := ColorRect.new()
	flash.position     = Vector2.ZERO
	flash.size         = vp
	flash.color        = Color(1.0, 1.0, 1.0, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var tw := create_tween()
	tw.tween_property(flash, "color:a", 1.0, 1.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

	queue_free()

# ─────────────────────────────────────────────────────────────
# Particle factories
# ─────────────────────────────────────────────────────────────
func _make_aura() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount                = 14
	p.lifetime              = 0.55
	p.explosiveness         = 0.0
	p.randomness            = 0.5
	p.emission_shape        = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(_CARD_W * 0.4, _CARD_H * 0.4)
	p.direction             = Vector2(0.0, -1.0)
	p.spread                = 65.0
	p.gravity               = Vector2.ZERO
	p.initial_velocity_min  = 14.0
	p.initial_velocity_max  = 32.0
	p.scale_amount_min      = 2.0
	p.scale_amount_max      = 4.0
	p.emitting              = false
	var g := Gradient.new()
	g.set_color(0, Color(0.5,  1.0, 1.0, 0.85))
	g.set_color(1, Color(0.85, 0.95, 1.0, 0.0))
	p.color_ramp = g
	return p

func _make_burst() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount               = 110
	p.lifetime             = 1.5
	p.one_shot             = true
	p.explosiveness        = 0.9
	p.randomness           = 0.3
	p.emission_shape       = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 8.0
	p.direction            = Vector2(0.0, -1.0)
	p.spread               = 180.0
	p.gravity              = Vector2.ZERO
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 260.0
	p.scale_amount_min     = 3.0
	p.scale_amount_max     = 10.0
	p.emitting             = false
	var g := Gradient.new()
	g.set_color(0, Color(1.0,  1.0, 1.0, 1.0))
	g.set_color(1, Color(0.55, 1.0, 1.0, 0.0))
	p.color_ramp = g
	return p

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
func _resolve_face_tex(card_name: String, card_type: String) -> Texture2D:
	if card_type == "dead_end":
		return _FACE_BLANK
	var snake: String = card_name.to_lower().replace(" ", "_")
	var nsfw: bool = SaveManager.nsfw_enabled
	var candidates: Array[String] = []
	if nsfw:
		candidates.append(_FULL_CARDS_DIR + snake + "_nsfw.png")
	candidates.append(_FULL_CARDS_DIR + snake + ".png")
	for path: String in candidates:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return _FACE_BLANK

func _edge(vp: Vector2) -> Vector2:
	match randi() % 4:
		0: return Vector2(randf_range(0.0, vp.x), randf_range(-80.0, -30.0))
		1: return Vector2(randf_range(0.0, vp.x), vp.y + randf_range(30.0, 80.0))
		2: return Vector2(randf_range(-80.0, -30.0), randf_range(0.0, vp.y))
		_: return Vector2(vp.x + randf_range(30.0, 80.0), randf_range(0.0, vp.y))
